local Globals = require("ElyonLib/Core/Globals")
local Logger = require("DailyRewards/Logger")
local DailyRewards = require("DailyRewards/Shared")

DailyRewards.Server = DailyRewards.Server or {}
DailyRewards.Server.ServerCommands = DailyRewards.Server.ServerCommands or {}

local Server = DailyRewards.Server
local Shared = DailyRewards.Shared

local function callClientHandler(command, args)
    if DailyRewards.Client and DailyRewards.Client.ClientCommands and DailyRewards.Client.ClientCommands[command] then
        DailyRewards.Client.ClientCommands[command](args or {})
    end
end

local function sendToPlayer(player, command, args)
    if Globals.isServer then
        sendServerCommand(player, DailyRewards.MODULE, command, args or {})
    else
        callClientHandler(command, args or {})
    end
end

local function sendCommandResult(player, message, level)
    sendToPlayer(player, "CommandResult", {
        message = tostring(message or ""),
        level = level or "info",
    })
end

function Server.BuildSnapshot(player, message, level)
    local data = Shared.GetModData()
    local serverTimestamp = Shared.GetServerTimestamp()
    local todayKey = Shared.EpochToDateKey(serverTimestamp) or Shared.GetTodayKey()
    local config = Shared.GetActiveConfig()

    local state = nil
    local playerId = nil
    if player then
        state, playerId = Shared.GetPlayerState(data, player, todayKey)
        if state then
            Shared.RebuildStreakState(state, todayKey, config.resetStreakAfterMissedDays)
        end
    end

    local stats = Shared.GetClaimStats(state, todayKey)
    local snapshot = {
        version = DailyRewards.VERSION,
        schemaVersion = DailyRewards.DATA_SCHEMA_VERSION,
        module = DailyRewards.MODULE,
        todayKey = todayKey,
        serverTimestamp = serverTimestamp,
        playerId = playerId,
        isAdmin = Shared.PlayerHasAdminAccess(player),
        dailyRows = state and Shared.BuildDailyRows(config, state, todayKey) or {},
        streakRows = state and Shared.BuildStreakRows(config, state, todayKey) or {},
        stats = stats,
        message = message,
        level = level or "info",
    }

    if snapshot.isAdmin then
        snapshot.config = config
    end

    return snapshot
end

function Server.PushSnapshotToPlayer(player, message, level)
    if not player then
        return nil
    end

    local snapshot = Server.BuildSnapshot(player, message, level)
    sendToPlayer(player, "LoadSnapshot", snapshot)
    return snapshot
end

function Server.PushSnapshotToAll(message, level)
    local players = Shared.GetOnlinePlayers()
    for i = 1, #players do
        Server.PushSnapshotToPlayer(players[i], message, level)
    end
end

local function grantItemReward(player, reward, summaries, errors)
    if not player or not player.getInventory then
        errors[#errors + 1] = "Player inventory unavailable"
        return
    end

    local itemType = tostring(reward.type or "")
    local count = math.floor(tonumber(reward.count) or 1)
    if itemType == "" or count <= 0 then
        return
    end

    local scriptItem = ScriptManager.instance:getItem(itemType)
    if not scriptItem then
        errors[#errors + 1] = "Missing item " .. itemType
        Logger:warning("Daily reward references missing item %s", itemType)
        return
    end

    if Globals.isServer then
        player:sendObjectChange("addItemOfType", { type = itemType, count = count })
    else
        for i = 1, count do
            player:getInventory():AddItem(itemType)
        end
    end

    summaries[#summaries + 1] = string.format("%dx %s", count, scriptItem:getDisplayName())
end

local function findPerk(perkName)
    perkName = tostring(perkName or "")
    if perkName == "" then
        return nil
    end

    if Perks[perkName] then
        return Perks[perkName]
    end

    if Perks.FromString then
        local perk = Perks.FromString(perkName)
        if perk and PerkFactory.getPerk(perk) then
            return perk
        end
    end

    return nil
end

local function grantXpReward(player, reward, summaries, errors)
    if not player or not player.getXp then
        errors[#errors + 1] = "Player XP unavailable"
        return
    end

    local perk = findPerk(reward.perk)
    local amount = tonumber(reward.amount) or 0
    if not perk or amount == 0 then
        errors[#errors + 1] = "Invalid XP reward " .. tostring(reward.perk)
        return
    end

    player:getXp():AddXP(perk, amount)
    local perkInfo = PerkFactory.getPerk(perk)
    local perkName = perkInfo and perkInfo:getName() or tostring(reward.perk)
    summaries[#summaries + 1] = string.format("%s XP +%s", perkName, tostring(amount))
end

local function grantTraitReward(player, reward, summaries, errors)
    if not player or not player.getTraits then
        errors[#errors + 1] = "Player traits unavailable"
        return
    end

    local traitInfo = Shared.GetTraitInfo(reward.type or reward.trait)
    if not traitInfo then
        errors[#errors + 1] = "Invalid trait reward " .. tostring(reward.type or reward.trait)
        return
    end

    local traits = player:getTraits()
    local conflictTypes = Shared.GetTraitConflictTypes(traitInfo.type)
    for i = 1, #conflictTypes do
        local conflictType = conflictTypes[i]
        if traits:contains(conflictType) then
            local conflictInfo = Shared.GetTraitInfo(conflictType)
            errors[#errors + 1] = string.format("%s conflicts with %s", traitInfo.label,
                conflictInfo and conflictInfo.label or conflictType)
            return
        end
    end

    if traits:contains(traitInfo.type) then
        summaries[#summaries + 1] = string.format("Trait %s (already had it)", traitInfo.label)
        return
    end

    traits:add(traitInfo.type)
    summaries[#summaries + 1] = string.format("Trait %s", traitInfo.label)
end

local function grantCustomReward(player, reward, context, summaries, errors)
    local handlerId = tostring(reward.handler or "")
    local handler = Shared.GetCustomRewardHandler(handlerId)
    if type(handler) ~= "function" then
        errors[#errors + 1] = "Missing custom handler " .. handlerId
        Logger:warning("Daily reward references missing custom handler %s", handlerId)
        return
    end

    local success, summary = handler(player, reward, context)
    if success == false then
        errors[#errors + 1] = tostring(summary or ("Custom handler failed " .. handlerId))
        return
    end

    summaries[#summaries + 1] = tostring(summary or handlerId)
end

function Server.GrantRewards(player, rewards, context)
    rewards = Shared.NormalizeRewards(rewards)
    local summaries = {}
    local errors = {}

    -- reward execution always runs on the server-side logic path so claim validation,
    -- item delivery, streak progress, and custom handlers stay authoritative in MP.
    for i = 1, #rewards.items do
        grantItemReward(player, rewards.items[i], summaries, errors)
    end

    for i = 1, #rewards.xp do
        grantXpReward(player, rewards.xp[i], summaries, errors)
    end

    for i = 1, #rewards.traits do
        grantTraitReward(player, rewards.traits[i], summaries, errors)
    end

    for i = 1, #rewards.custom do
        grantCustomReward(player, rewards.custom[i], context, summaries, errors)
    end

    return {
        summaries = summaries,
        errors = errors,
        successCount = #summaries,
        errorCount = #errors,
    }
end

local function summarizeGrant(grant)
    if grant.successCount > 0 then
        return "Received: " .. table.concat(grant.summaries, ", "), "info"
    end

    if grant.errorCount > 0 then
        return "Reward claimed, but nothing was delivered: " .. table.concat(grant.errors, ", "), "warning"
    end

    return "Reward claimed.", "info"
end

local function findDailyRow(config, state, todayKey, dateKey)
    local rows = Shared.BuildDailyRows(config, state, todayKey)
    for i = 1, #rows do
        if rows[i].dateKey == dateKey then
            return rows[i]
        end
    end
    return nil
end

local function findStreakRow(config, state, todayKey, streakId, claimKey)
    local rows = Shared.BuildStreakRows(config, state, todayKey)
    for i = 1, #rows do
        local row = rows[i]
        if row.streakId == streakId or row.claimKey == claimKey then
            return row
        end
    end
    return nil
end

function Server.ServerCommands.RequestSnapshot(player, args)
    Server.PushSnapshotToPlayer(player)
end

function Server.ServerCommands.ClaimDaily(player, args)
    if not player then
        return
    end

    local data = Shared.GetModData()
    local config = Shared.GetActiveConfig()
    local claimedAt = Shared.GetServerTimestamp()
    local todayKey = Shared.EpochToDateKey(claimedAt) or Shared.GetTodayKey()
    local state, playerId = Shared.GetPlayerState(data, player, todayKey)
    local dateKey = Shared.NormalizeDateKey(args and args.dateKey)

    if not config.enabled then
        Server.PushSnapshotToPlayer(player, "Daily Rewards are disabled.", "warning")
        return
    end

    local row = dateKey and findDailyRow(config, state, todayKey, dateKey) or nil
    if not row then
        Server.PushSnapshotToPlayer(player, "That reward day is not available.", "error")
        return
    end

    if row.claimed then
        Server.PushSnapshotToPlayer(player, "You already claimed that day.", "warning")
        return
    end

    if not row.claimable then
        Server.PushSnapshotToPlayer(player, "That reward cannot be claimed yet.", "warning")
        return
    end

    local context = {
        type = "daily",
        playerId = playerId,
        dateKey = row.dateKey,
        dayNumber = row.dayNumber,
        reward = row.reward,
        todayKey = todayKey,
    }
    local grant = Server.GrantRewards(player, row.reward.rewards, context)
    Shared.ApplyDailyClaimToStreak(state, row.dateKey, claimedAt, config.resetStreakAfterMissedDays)

    local message, level = summarizeGrant(grant)
    Logger:info("%s claimed daily reward %s (%s)", tostring(playerId), tostring(row.reward.id), tostring(row.dateKey))
    Server.PushSnapshotToPlayer(player, message, level)
end

function Server.ServerCommands.ClaimStreak(player, args)
    if not player then
        return
    end

    local data = Shared.GetModData()
    local config = Shared.GetActiveConfig()
    local claimedAt = Shared.GetServerTimestamp()
    local todayKey = Shared.EpochToDateKey(claimedAt) or Shared.GetTodayKey()
    local state, playerId = Shared.GetPlayerState(data, player, todayKey)
    local streakId = tostring(args and args.streakId or "")
    local claimKey = tostring(args and args.claimKey or "")
    Shared.RebuildStreakState(state, todayKey, config.resetStreakAfterMissedDays)

    if not config.enabled then
        Server.PushSnapshotToPlayer(player, "Daily Rewards are disabled.", "warning")
        return
    end

    local row = findStreakRow(config, state, todayKey, streakId, claimKey)
    if not row then
        Server.PushSnapshotToPlayer(player, "That streak reward is not available.", "error")
        return
    end

    if row.claimed or (state.claimedStreaks and state.claimedStreaks[row.claimKey]) then
        Server.PushSnapshotToPlayer(player, "You already claimed that streak reward.", "warning")
        return
    end

    if not row.claimable then
        Server.PushSnapshotToPlayer(player, "Your streak is not high enough yet.", "warning")
        return
    end

    local context = {
        type = "streak",
        playerId = playerId,
        streakId = row.streakId,
        claimKey = row.claimKey,
        requiredDays = row.requiredDays,
        streak = row.streak,
        todayKey = todayKey,
    }
    local grant = Server.GrantRewards(player, row.streak.rewards, context)
    state.claimedStreaks[row.claimKey] = claimedAt

    local message, level = summarizeGrant(grant)
    Logger:info("%s claimed streak reward %s (%s)", tostring(playerId), tostring(row.streakId), tostring(row.claimKey))
    Server.PushSnapshotToPlayer(player, message, level)
end

function Server.ServerCommands.SaveConfigTable(player, args)
    if not Shared.PlayerHasAdminAccess(player) then
        sendCommandResult(player, "Daily Rewards config is admin-only.", "error")
        return
    end

    local config = args and args.config
    if type(config) ~= "table" then
        sendCommandResult(player, "Config was empty.", "error")
        return
    end

    local success = Shared.SetActiveConfig(config)
    if not success then
        sendCommandResult(player, "Daily Rewards config could not be written to " .. DailyRewards.CONFIG_FILE .. ".",
            "error")
        return
    end

    Logger:info("%s saved Daily Rewards config from the admin editor", tostring(Shared.GetPlayerKey(player)))
    Server.PushSnapshotToAll("Daily Rewards config saved to " .. DailyRewards.CONFIG_FILE .. ".", "info")
end

function Server.ServerCommands.ImportConfigTable(player, args)
    Server.ServerCommands.SaveConfigTable(player, args)
end

function Server.ServerCommands.ResetConfig(player, args)
    if not Shared.PlayerHasAdminAccess(player) then
        sendCommandResult(player, "Daily Rewards config is admin-only.", "error")
        return
    end

    local success = Shared.SetActiveConfig(Shared.GetDefaultConfig())
    if not success then
        sendCommandResult(player,
            "Daily Rewards default config could not be written to " .. DailyRewards.CONFIG_FILE .. ".", "error")
        return
    end

    Logger:info("%s reset Daily Rewards config", tostring(Shared.GetPlayerKey(player)))
    Server.PushSnapshotToAll("Daily Rewards config reset to defaults.", "info")
end

function Server.onClientCommand(module, command, player, args)
    if module ~= DailyRewards.MODULE then
        return
    end

    local handler = Server.ServerCommands[command]
    if type(handler) == "function" then
        handler(player, args or {})
    end
end

Events.OnClientCommand.Add(Server.onClientCommand)

Events.OnInitGlobalModData.Add(function()
    Shared.GetModData()
    Shared.GetActiveConfig()
end)

Server.LastDateKey = Server.LastDateKey or Shared.GetTodayKey()
Events.EveryOneMinute.Add(function()
    local todayKey = Shared.GetTodayKey()
    if todayKey ~= Server.LastDateKey then
        Server.LastDateKey = todayKey
        Server.PushSnapshotToAll("New Daily Rewards are available.", "info")
    end
end)

return DailyRewards
