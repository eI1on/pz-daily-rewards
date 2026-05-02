if not pcall(require, "ElyonLib/Core/Globals") then
    print("[DailyRewards] ERROR: ElyonLib is required but not loaded. DailyRewards will not function.")
    return {}
end

local Globals = require("ElyonLib/Core/Globals")
local AccessLevelUtils = require("ElyonLib/PlayerUtils/AccessLevelUtils")
local PlayerUtils = require("ElyonLib/PlayerUtils/PlayerUtils")
local NetUtils = require("ElyonLib/Net/NetUtils")
local FileUtils = require("ElyonLib/FileUtils/FileUtils")
local ItemUtils = require("ElyonLib/ItemUtils/ItemUtils")
local JSON = require("ElyonLib/FileUtils/JSON")
local DateTimeUtility = require("ElyonLib/DateTime/DateTimeUtility")
local MathUtils = require("ElyonLib/MathUtils/MathUtils")
local TableUtils = require("ElyonLib/TableUtils/TableUtils")
local TextUtils = require("ElyonLib/TextUtils/TextUtils")

local DailyRewards = {}

DailyRewards.Shared = {}
DailyRewards.MODULE = "DailyRewards"
DailyRewards.VERSION = "0.0.1"
DailyRewards.DATA_SCHEMA_VERSION = 1
DailyRewards.CONFIG_FILE = "DailyRewardsConfig.json"
DailyRewards.FILE_MOD_ID = "Daily Rewards"
DailyRewards.ClientSnapshot = nil

DailyRewards.Custom = DailyRewards.Custom or {
    handlers = {},
    definitions = {},
}
DailyRewards.Custom.handlers = DailyRewards.Custom.handlers or {}
DailyRewards.Custom.definitions = DailyRewards.Custom.definitions or {}
DailyRewards.TraitCache = DailyRewards.TraitCache or nil

DailyRewards.Config = {
    enabled = true,
    startDate = nil,       -- internal date key; nil means each player starts on first seen date.
    allowMissedClaims = true,
    maxClaimableDays = 30, -- 0 means unlimited history.
    previewDays = 7,
    repeatRewards = true,
    resetStreakAfterMissedDays = 1,
    dailyRewards = {
        {
            id = "day_1",
            title = "Survivor Starter",
            description = "A clean first step: water, food, and a little confidence.",
            rewards = {
                items = {
                    { type = "Base.WaterBottleFull", count = 1 },
                    { type = "Base.TinnedSoup",      count = 1 },
                },
            },
        },
        {
            id = "day_2",
            title = "Patch Up",
            description = "Basic supplies for bad corners and worse timing.",
            rewards = {
                items = {
                    { type = "Base.Bandage",      count = 3 },
                    { type = "Base.AlcoholWipes", count = 2 },
                },
            },
        },
        {
            id = "day_3",
            title = "Cook's Nudge",
            description = "A small food drop and a little Cooking XP.",
            rewards = {
                items = {
                    { type = "Base.CannedChili", count = 1 },
                },
                xp = {
                    { perk = "Cooking", amount = 25 },
                },
            },
        },
        {
            id = "day_4",
            title = "Tool Check",
            description = "Tape fixes everything until it doesn't.",
            rewards = {
                items = {
                    { type = "Base.DuctTape", count = 1 },
                    { type = "Base.Nails",    count = 20 },
                },
                xp = {
                    { perk = "Woodwork", amount = 15 },
                },
            },
        },
        {
            id = "day_5",
            title = "Road Snack",
            description = "Something light for a longer run.",
            rewards = {
                items = {
                    { type = "Base.Crisps", count = 1 },
                    { type = "Base.Pop",    count = 1 },
                },
            },
        },
        {
            id = "day_6",
            title = "Quiet Hands",
            description = "Small practice for work that needs patience.",
            rewards = {
                items = {
                    { type = "Base.Thread", count = 1 },
                    { type = "Base.Needle", count = 1 },
                },
                xp = {
                    { perk = "Tailoring", amount = 20 },
                },
            },
        },
        {
            id = "day_7",
            title = "Week One Cache",
            description = "A bigger weekly drop for anyone still standing.",
            rewards = {
                items = {
                    { type = "Base.FirstAidKit", count = 1 },
                    { type = "Base.Torch",       count = 1 },
                    { type = "Base.Battery",     count = 2 },
                },
            },
        },
    },
    streakRewards = {
        {
            id = "streak_3",
            days = 3,
            title = "3 Day Streak",
            description = "Three claims in a row.",
            repeatable = false,
            rewards = {
                items = {
                    { type = "Base.Chocolate", count = 1 },
                },
            },
        },
        {
            id = "streak_7",
            days = 7,
            title = "7 Day Streak",
            description = "A full week of claims.",
            repeatable = true,
            rewards = {
                items = {
                    { type = "Base.HuntingKnife", count = 1 },
                },
                xp = {
                    { perk = "Maintenance", amount = 50 },
                },
            },
        },
    },
}

local Shared = DailyRewards.Shared
local trim = TextUtils.trim
local copyValue = TableUtils.deepCopy
local normalizeNumber = MathUtils.parseNumber

function Shared.GetPlayerUsername(player)
    if player and player.getUsername then
        local username = player:getUsername()
        if username and username ~= "" then
            return username
        end
    end
    return nil
end

function Shared.GetPlayerKey(player)
    return PlayerUtils.getPlayerKey(player)
end

function Shared.GetOnlinePlayers()
    return PlayerUtils.getOnlinePlayers()
end

function Shared.PlayerHasAdminAccess(player)
    return AccessLevelUtils.hasAdminAccess(player)
end

function Shared.NormalizeDateKey(value)
    return DateTimeUtility.normalizeDateKey(value)
end

function Shared.GetServerTimestamp(timestamp)
    return math.floor(tonumber(timestamp) or os.time())
end

function Shared.EpochToDateKey(epoch)
    return DateTimeUtility.timestampToDateKey(epoch)
end

function Shared.GetTodayKey()
    return Shared.EpochToDateKey(Shared.GetServerTimestamp())
end

function Shared.DateKeyToTimestamp(dateKey)
    return DateTimeUtility.dateKeyToTimestamp(dateKey)
end

function Shared.AddDays(dateKey, days)
    return DateTimeUtility.addDaysToDateKey(dateKey, days)
end

function Shared.DaysBetween(startDateKey, endDateKey)
    return DateTimeUtility.daysBetweenDateKeys(startDateKey, endDateKey)
end

function Shared.DateKeyCompare(a, b)
    return DateTimeUtility.compareDateKeys(a, b)
end

function Shared.GetTraitInfo(traitType)
    traitType = trim(traitType)
    if traitType == "" or not TraitFactory or not TraitFactory.getTrait then
        return nil
    end

    local trait = TraitFactory.getTrait(traitType)
    if not trait then
        return nil
    end

    local cost = trait.getCost and (trait:getCost() or 0) or 0
    return {
        type = tostring(trait:getType() or traitType),
        label = trait:getLabel(),
        description = trait:getDescription(),
        cost = cost,
        positive = cost >= 0,
    }
end

function Shared.GetTraitConflictTypes(traitType)
    local trait = TraitFactory and TraitFactory.getTrait and TraitFactory.getTrait(trim(traitType)) or nil
    local result = {}
    if not trait or not trait.getMutuallyExclusiveTraits then
        return result
    end

    local conflicts = trait:getMutuallyExclusiveTraits()
    if not conflicts then
        return result
    end

    for index = 0, conflicts:size() - 1 do
        local conflictType = trim(conflicts:get(index))
        if conflictType ~= "" then
            result[#result + 1] = conflictType
        end
    end

    table.sort(result)
    return result
end

function Shared.GetTraitList()
    if DailyRewards.TraitCache then
        return DailyRewards.TraitCache
    end

    local result = {}
    local traitList = TraitFactory and TraitFactory.getTraits and TraitFactory.getTraits() or nil
    if not traitList then
        return result
    end

    for index = 0, traitList:size() - 1 do
        local trait = traitList:get(index)
        local traitType = trait and trim(trait:getType()) or ""
        if trait and traitType ~= "" and ((trait:isRemoveInMP() and not Globals.isClient) or not trait:isRemoveInMP()) then
            local cost = trait:getCost() or 0
            result[#result + 1] = {
                type = traitType,
                label = trait:getLabel(),
                description = trait:getDescription(),
                cost = cost,
                positive = cost >= 0,
            }
        end
    end

    table.sort(result, function(a, b)
        if a.positive ~= b.positive then
            return a.positive and not b.positive
        end
        return tostring(a.label):lower() < tostring(b.label):lower()
    end)

    DailyRewards.TraitCache = result
    return result
end

function Shared.NormalizeRewards(rewards)
    rewards = type(rewards) == "table" and rewards or {}
    local out = {
        items = {},
        xp = {},
        traits = {},
        custom = {},
    }

    local items = type(rewards.items) == "table" and rewards.items or {}
    for i = 1, #items do
        local entry = items[i]
        if type(entry) == "string" then
            out.items[#out.items + 1] = { type = trim(entry), count = 1 }
        elseif type(entry) == "table" then
            local itemType = trim(entry.type or entry.item or entry.fullType)
            if itemType ~= "" then
                out.items[#out.items + 1] = {
                    type = itemType,
                    count = math.floor(normalizeNumber(entry.count or entry.amount or 1, 1, 1, 999)),
                }
            end
        end
    end

    local xpRewards = type(rewards.xp) == "table" and rewards.xp or {}
    for i = 1, #xpRewards do
        local entry = xpRewards[i]
        if type(entry) == "table" then
            local perk = trim(entry.perk or entry.type or entry.skill)
            local amount = normalizeNumber(entry.amount or entry.xp, 0, -100000, 100000)
            if perk ~= "" and amount ~= 0 then
                out.xp[#out.xp + 1] = {
                    perk = perk,
                    amount = amount,
                }
            end
        end
    end

    local traitRewards = type(rewards.traits) == "table" and rewards.traits or {}
    for i = 1, #traitRewards do
        local entry = traitRewards[i]
        local traitType = ""
        if type(entry) == "string" then
            traitType = trim(entry)
        elseif type(entry) == "table" then
            traitType = trim(entry.type or entry.trait or entry.id or entry.name)
        end

        local traitInfo = Shared.GetTraitInfo(traitType)
        if traitInfo then
            out.traits[#out.traits + 1] = {
                type = traitInfo.type,
            }
        end
    end

    local customRewards = type(rewards.custom) == "table" and rewards.custom or {}
    for i = 1, #customRewards do
        local entry = customRewards[i]
        if type(entry) == "string" then
            out.custom[#out.custom + 1] = { handler = trim(entry) }
        elseif type(entry) == "table" then
            local handler = trim(entry.handler or entry.id or entry.name)
            if handler ~= "" then
                -- Keep arbitrary handler-specific parameters intact while normalizing the
                -- optional UI metadata that can come either from the config or the registry.
                local customEntry = copyValue(entry)
                customEntry.handler = handler
                customEntry.displayName = trim(customEntry.displayName)
                if customEntry.displayName == "" then
                    customEntry.displayName = nil
                end
                customEntry.icon = trim(customEntry.icon)
                if customEntry.icon == "" then
                    customEntry.icon = nil
                end
                customEntry.iconText = trim(customEntry.iconText)
                if customEntry.iconText == "" then
                    customEntry.iconText = nil
                end
                out.custom[#out.custom + 1] = customEntry
            end
        end
    end

    return out
end

function Shared.NormalizeRewardEntry(entry, index)
    entry = type(entry) == "table" and entry or {}
    local day = math.floor(normalizeNumber(entry.day or index, index, 1, 3650))
    return {
        id = trim(entry.id) ~= "" and trim(entry.id) or ("day_" .. tostring(day)),
        day = day,
        title = trim(entry.title) ~= "" and trim(entry.title) or ("Day " .. tostring(day)),
        description = trim(entry.description),
        rewards = Shared.NormalizeRewards(entry.rewards),
    }
end

function Shared.NormalizeStreakEntry(entry, index)
    entry = type(entry) == "table" and entry or {}
    local days = math.floor(normalizeNumber(entry.days or entry.streak or index, index, 1, 3650))
    return {
        id = trim(entry.id) ~= "" and trim(entry.id) or ("streak_" .. tostring(days)),
        days = days,
        title = trim(entry.title) ~= "" and trim(entry.title) or (tostring(days) .. " Day Streak"),
        description = trim(entry.description),
        repeatable = entry.repeatable == true,
        rewards = Shared.NormalizeRewards(entry.rewards),
    }
end

function Shared.NormalizeConfig(config)
    config = type(config) == "table" and config or {}
    local defaults = DailyRewards.Config
    local out = {
        enabled = config.enabled ~= false,
        startDate = Shared.NormalizeDateKey(config.startDate),
        allowMissedClaims = config.allowMissedClaims ~= false,
        maxClaimableDays = math.floor(normalizeNumber(config.maxClaimableDays, defaults.maxClaimableDays, 0, 3650)),
        previewDays = math.floor(normalizeNumber(config.previewDays, defaults.previewDays, 0, 3650)),
        repeatRewards = config.repeatRewards ~= false,
        resetStreakAfterMissedDays = math.floor(normalizeNumber(config.resetStreakAfterMissedDays,
            defaults.resetStreakAfterMissedDays, 0, 3650)),
        dailyRewards = {},
        streakRewards = {},
    }

    local dailyRewards = type(config.dailyRewards) == "table" and #config.dailyRewards > 0 and config.dailyRewards or
        defaults.dailyRewards
    for i = 1, #dailyRewards do
        out.dailyRewards[#out.dailyRewards + 1] = Shared.NormalizeRewardEntry(dailyRewards[i], i)
    end
    table.sort(out.dailyRewards, function(a, b)
        if a.day ~= b.day then
            return a.day < b.day
        end
        return tostring(a.id) < tostring(b.id)
    end)
    for i = 1, #out.dailyRewards do
        out.dailyRewards[i].day = i
    end

    local streakRewards = config.streakRewards
    if type(streakRewards) ~= "table" then
        streakRewards = defaults.streakRewards
    end
    for i = 1, #streakRewards do
        out.streakRewards[#out.streakRewards + 1] = Shared.NormalizeStreakEntry(streakRewards[i], i)
    end
    table.sort(out.streakRewards, function(a, b)
        if a.days ~= b.days then
            return a.days < b.days
        end
        return tostring(a.id) < tostring(b.id)
    end)

    return out
end

function Shared.GetDefaultConfig()
    return Shared.NormalizeConfig(copyValue(DailyRewards.Config))
end

function Shared.LoadConfigFromFile()
    local content = FileUtils.readFile(DailyRewards.CONFIG_FILE, DailyRewards.FILE_MOD_ID, { createIfNull = true })
    if content and trim(content) ~= "" then
        local config = JSON.parse(content)
        if type(config) == "table" then
            return Shared.NormalizeConfig(config), true
        end
        return Shared.GetDefaultConfig(), true
    end

    return Shared.GetDefaultConfig(), false
end

function Shared.SaveConfigToFile(config)
    local normalized = Shared.NormalizeConfig(config)
    local success = FileUtils.writeJson(DailyRewards.CONFIG_FILE, normalized, DailyRewards.FILE_MOD_ID,
        { createIfNull = true })
    if success then
        DailyRewards.ActiveConfig = normalized
    end
    return success, normalized
end

function Shared.GetActiveConfig(forceReload)
    if forceReload or not DailyRewards.ActiveConfig then
        local config, loaded = Shared.LoadConfigFromFile()
        DailyRewards.ActiveConfig = config
        if not loaded then
            Shared.SaveConfigToFile(config)
        end
    end

    return DailyRewards.ActiveConfig
end

function Shared.SetActiveConfig(config)
    return Shared.SaveConfigToFile(config)
end

function Shared.ResetModData(data)
    data = data or {}
    local keys = {}
    for key, _ in pairs(data) do
        keys[#keys + 1] = key
    end
    for i = 1, #keys do
        data[keys[i]] = nil
    end
    data.version = DailyRewards.VERSION
    data.schemaVersion = DailyRewards.DATA_SCHEMA_VERSION
    data.players = {}
    return data
end

function Shared.GetModData()
    local data = ModData.getOrCreate(DailyRewards.MODULE)
    if data.schemaVersion ~= DailyRewards.DATA_SCHEMA_VERSION then
        return Shared.ResetModData(data)
    end

    data.version = DailyRewards.VERSION
    data.schemaVersion = DailyRewards.DATA_SCHEMA_VERSION
    data.players = data.players or {}
    return data
end

function Shared.NormalizeStreakState(value)
    value = type(value) == "table" and value or {}
    local active = math.floor(normalizeNumber(value.active, 0, 0, 3650))
    local longest = math.floor(normalizeNumber(value.longest, 0, 0, 3650))
    local lastRewardDate = Shared.NormalizeDateKey(value.lastRewardDate)
    local lastClaimAt = tonumber(value.lastClaimAt)
    if not lastRewardDate then
        active = 0
    end
    if longest < active then
        longest = active
    end

    return {
        active = active,
        longest = longest,
        runId = math.floor(normalizeNumber(value.runId, 1, 1, 999999)),
        lastRewardDate = lastRewardDate,
        lastClaimAt = lastClaimAt,
    }
end

function Shared.GetPlayerState(data, player, todayKey)
    data.players = data.players or {}
    local playerId = Shared.GetPlayerKey(player)
    if not playerId then
        return nil, nil
    end

    data.players[playerId] = data.players[playerId] or {}
    local state = data.players[playerId]
    state.firstSeenAt = tonumber(state.firstSeenAt) or Shared.DateKeyToTimestamp(todayKey) or Shared.GetServerTimestamp()
    state.claimedDaily = type(state.claimedDaily) == "table" and state.claimedDaily or {}
    state.claimedStreaks = type(state.claimedStreaks) == "table" and state.claimedStreaks or {}
    state.streak = Shared.NormalizeStreakState(state.streak)
    return state, playerId
end

function Shared.GetCampaignStartDate(config, state)
    return Shared.NormalizeDateKey(config and config.startDate) or Shared.EpochToDateKey(state and state.firstSeenAt) or
        Shared.GetTodayKey()
end

function Shared.GetRewardForDay(config, dayNumber)
    dayNumber = math.floor(tonumber(dayNumber) or 0)
    local dailyRewards = config.dailyRewards
    if dayNumber <= 0 or #dailyRewards == 0 then
        return nil
    end

    local rewardIndex = dayNumber
    if rewardIndex > #dailyRewards then
        if not config.repeatRewards then
            return nil
        end
        rewardIndex = ((dayNumber - 1) % #dailyRewards) + 1
    end

    local reward = copyValue(dailyRewards[rewardIndex])
    reward.rewardIndex = rewardIndex
    reward.dayNumber = dayNumber
    return reward
end

function Shared.IsDateClaimed(state, dateKey)
    return state and state.claimedDaily and state.claimedDaily[dateKey] ~= nil
end

function Shared.BuildDailyRows(config, state, todayKey)
    todayKey = Shared.NormalizeDateKey(todayKey) or Shared.GetTodayKey()
    local startDate = Shared.GetCampaignStartDate(config, state)
    local daysSinceStart = Shared.DaysBetween(startDate, todayKey)
    local rows = {}

    if daysSinceStart < 0 then
        daysSinceStart = 0
    end

    local firstOffset = 0
    if not config.allowMissedClaims then
        firstOffset = daysSinceStart
    elseif config.maxClaimableDays > 0 then
        firstOffset = math.max(0, daysSinceStart - config.maxClaimableDays + 1)
    end

    local lastOffset = daysSinceStart + math.max(0, config.previewDays or 0)

    for offset = firstOffset, lastOffset do
        local dateKey = Shared.AddDays(startDate, offset)
        local dayNumber = offset + 1
        local reward = Shared.GetRewardForDay(config, dayNumber)
        if dateKey and reward then
            local isFuture = Shared.DateKeyCompare(dateKey, todayKey) > 0
            local claimed = Shared.IsDateClaimed(state, dateKey)
            local claimable = config.enabled and not claimed and not isFuture
            if not config.allowMissedClaims and dateKey ~= todayKey then
                claimable = false
            end

            rows[#rows + 1] = {
                dateKey = dateKey,
                dayNumber = dayNumber,
                rewardIndex = reward.rewardIndex,
                reward = reward,
                claimed = claimed,
                future = isFuture,
                claimable = claimable,
            }
        end
    end

    return rows
end

function Shared.GetClaimedDateKeys(state)
    local keys = {}
    local seen = {}
    if not state or type(state.claimedDaily) ~= "table" then
        return keys
    end

    for dateKey, _ in pairs(state.claimedDaily) do
        local normalized = Shared.NormalizeDateKey(dateKey)
        if normalized and not seen[normalized] then
            seen[normalized] = true
            keys[#keys + 1] = normalized
        end
    end

    table.sort(keys)
    return keys
end

function Shared.GetClaimStats(state, todayKey)
    todayKey = Shared.NormalizeDateKey(todayKey) or Shared.GetTodayKey()
    local keys = Shared.GetClaimedDateKeys(state)
    local total = #keys
    local streak = Shared.NormalizeStreakState(state and state.streak)
    local latest = streak.lastRewardDate or keys[#keys]

    return {
        totalClaims = total,
        longestStreak = streak.longest,
        activeStreak = streak.active,
        latestClaimDate = latest,
        claimedToday = Shared.IsDateClaimed(state, todayKey),
    }
end

function Shared.RebuildStreakState(state, todayKey, resetStreakAfterMissedDays)
    if not state then
        return Shared.NormalizeStreakState(nil)
    end

    todayKey = Shared.NormalizeDateKey(todayKey) or Shared.GetTodayKey()
    resetStreakAfterMissedDays = math.floor(normalizeNumber(resetStreakAfterMissedDays, 0, 0, 3650))
    local keys = Shared.GetClaimedDateKeys(state)
    local streak = {
        active = 0,
        longest = 0,
        runId = 1,
        lastRewardDate = nil,
        lastClaimAt = nil,
    }
    local previousRewardDate = nil
    local previousClaimDate = nil
    local currentRunLastClaimAt = nil
    local currentActive = 0
    local runId = 0

    for i = 1, #keys do
        local rewardDateKey = keys[i]
        local claimValue = state.claimedDaily[rewardDateKey]
        local claimEpoch = tonumber(claimValue) or Shared.DateKeyToTimestamp(claimValue) or
            Shared.DateKeyToTimestamp(rewardDateKey) or Shared.GetServerTimestamp()
        local claimDateKey = Shared.EpochToDateKey(claimEpoch) or rewardDateKey
        local extendsRun = false

        if previousRewardDate and previousClaimDate then
            local rewardGap = Shared.DaysBetween(previousRewardDate, rewardDateKey)
            local claimGap = math.abs(Shared.DaysBetween(previousClaimDate, claimDateKey))
            local missedClaimDays = math.max(0, claimGap - 1)
            extendsRun = rewardGap == 1 and missedClaimDays <= resetStreakAfterMissedDays
        end

        if extendsRun then
            currentActive = currentActive + 1
        else
            runId = runId + 1
            currentActive = 1
            currentRunLastClaimAt = nil
        end

        if not currentRunLastClaimAt or claimEpoch > currentRunLastClaimAt then
            currentRunLastClaimAt = claimEpoch
        end

        if currentActive > streak.longest then
            streak.longest = currentActive
        end

        previousRewardDate = rewardDateKey
        previousClaimDate = claimDateKey
        streak.active = currentActive
        streak.runId = runId
        streak.lastRewardDate = rewardDateKey
        streak.lastClaimAt = currentRunLastClaimAt
    end

    if streak.active > 0 then
        local lastClaimDate = Shared.EpochToDateKey(streak.lastClaimAt)
        local claimGap = lastClaimDate and Shared.DaysBetween(lastClaimDate, todayKey) or 3651
        if claimGap < 0 or claimGap > resetStreakAfterMissedDays + 1 then
            streak.active = 0
        end
    end

    state.streak = Shared.NormalizeStreakState(streak)
    return state.streak
end

function Shared.ApplyDailyClaimToStreak(state, rewardDateKey, claimDateKey, resetStreakAfterMissedDays)
    if state then
        rewardDateKey = Shared.NormalizeDateKey(rewardDateKey)
        if rewardDateKey then
            state.claimedDaily = type(state.claimedDaily) == "table" and state.claimedDaily or {}
            local claimEpoch = tonumber(claimDateKey) or Shared.DateKeyToTimestamp(claimDateKey) or
                Shared.GetServerTimestamp()
            state.claimedDaily[rewardDateKey] = claimEpoch
            claimDateKey = claimEpoch
        end
    end
    return Shared.RebuildStreakState(state, Shared.EpochToDateKey(claimDateKey), resetStreakAfterMissedDays), true
end

function Shared.GetClaimedStreakCount(state, streakId, runId)
    local count = 0
    if not state or type(state.claimedStreaks) ~= "table" then
        return count
    end

    for key, _ in pairs(state.claimedStreaks) do
        local keyText = tostring(key)
        local prefix = tostring(streakId) .. ":"
        if runId ~= nil then
            local runPrefix = prefix .. tostring(runId) .. ":"
            if keyText:sub(1, #runPrefix) == runPrefix then
                count = count + 1
            end
        elseif keyText == streakId or keyText:sub(1, #prefix) == prefix then
            count = count + 1
        end
    end
    return count
end

function Shared.BuildStreakRows(config, state, todayKey)
    local stats = Shared.GetClaimStats(state, todayKey)
    local streakState = Shared.NormalizeStreakState(state and state.streak)
    local rows = {}

    for i = 1, #config.streakRewards do
        local streak = copyValue(config.streakRewards[i])
        local claimedKey = streak.id
        local claimed = false
        local claimable = false
        local requiredDays = streak.days
        local repeatIndex = 1
        local runId = streakState.runId

        if streak.repeatable then
            local claimedCount = Shared.GetClaimedStreakCount(state, streak.id, runId)
            repeatIndex = claimedCount + 1
            requiredDays = streak.days * repeatIndex
            claimedKey = streak.id .. ":" .. tostring(runId) .. ":" .. tostring(repeatIndex)
            claimed = state and state.claimedStreaks and state.claimedStreaks[claimedKey] ~= nil
            claimable = config.enabled and stats.activeStreak >= requiredDays and not claimed
        else
            claimed = state and state.claimedStreaks and state.claimedStreaks[claimedKey] ~= nil
            claimable = config.enabled and stats.activeStreak >= requiredDays and not claimed
        end

        rows[#rows + 1] = {
            streak = streak,
            streakId = streak.id,
            claimKey = claimedKey,
            repeatIndex = repeatIndex,
            runId = runId,
            requiredDays = requiredDays,
            claimed = claimed,
            claimable = claimable,
            progress = math.min(stats.activeStreak, requiredDays),
            longestStreak = stats.longestStreak,
            activeStreak = stats.activeStreak,
        }
    end

    table.sort(rows, function(a, b)
        if a.requiredDays ~= b.requiredDays then
            return a.requiredDays < b.requiredDays
        end
        return tostring(a.streakId) < tostring(b.streakId)
    end)

    return rows
end

function Shared.GetRewardSummary(rewards)
    rewards = Shared.NormalizeRewards(rewards)
    local parts = {}

    for i = 1, #rewards.items do
        local item = rewards.items[i]
        parts[#parts + 1] = string.format("%dx %s", item.count or 1, ItemUtils.getDisplayName(item.type or "?"))
    end

    for i = 1, #rewards.xp do
        local xp = rewards.xp[i]
        parts[#parts + 1] = string.format("%s XP +%s", xp.perk or "Skill", tostring(xp.amount or 0))
    end

    for i = 1, #rewards.traits do
        local traitInfo = Shared.GetTraitInfo(rewards.traits[i].type)
        parts[#parts + 1] = string.format("Trait: %s",
        traitInfo and traitInfo.label or tostring(rewards.traits[i].type or "Trait"))
    end

    for i = 1, #rewards.custom do
        local custom = rewards.custom[i]
        parts[#parts + 1] = string.format("Custom: %s", Shared.GetCustomRewardDisplayName(custom))
    end

    if #parts == 0 then
        return "No rewards"
    end

    return table.concat(parts, ", ")
end

function Shared.RegisterCustomReward(handlerId, fn, definition)
    handlerId = trim(handlerId)
    if handlerId == "" or type(fn) ~= "function" then
        return false
    end
    definition = type(definition) == "table" and definition or {}
    DailyRewards.Custom.handlers[handlerId] = fn
    DailyRewards.Custom.definitions[handlerId] = {
        handler = handlerId,
        displayName = trim(definition.displayName),
        icon = trim(definition.icon),
        iconText = trim(definition.iconText),
    }
    if DailyRewards.Custom.definitions[handlerId].displayName == "" then
        DailyRewards.Custom.definitions[handlerId].displayName = nil
    end
    if DailyRewards.Custom.definitions[handlerId].icon == "" then
        DailyRewards.Custom.definitions[handlerId].icon = nil
    end
    if DailyRewards.Custom.definitions[handlerId].iconText == "" then
        DailyRewards.Custom.definitions[handlerId].iconText = nil
    end
    return true
end

function Shared.GetCustomRewardHandler(handlerId)
    return DailyRewards.Custom.handlers[tostring(handlerId or "")]
end

function Shared.GetCustomRewardDefinition(handlerId)
    handlerId = trim(handlerId)
    if handlerId == "" then
        return nil
    end
    return DailyRewards.Custom.definitions[handlerId]
end

function Shared.GetCustomRewardDisplayName(reward)
    reward = type(reward) == "table" and reward or {}
    local displayName = trim(reward.displayName)
    if displayName ~= "" then
        return displayName
    end

    local definition = Shared.GetCustomRewardDefinition(reward.handler)
    if definition and definition.displayName then
        return definition.displayName
    end

    local handlerId = trim(reward.handler)
    if handlerId ~= "" then
        return handlerId
    end

    return "Custom Reward"
end

function Shared.GetCustomRewardIcon(reward)
    reward = type(reward) == "table" and reward or {}
    local definition = Shared.GetCustomRewardDefinition(reward.handler)
    local icon = trim(reward.icon)
    if icon == "" and definition then
        icon = trim(definition.icon)
    end
    if icon == "" then
        icon = nil
    end

    local iconText = trim(reward.iconText)
    if iconText == "" and definition then
        iconText = trim(definition.iconText)
    end
    if iconText == "" then
        iconText = nil
    end

    return icon, iconText
end

function Shared.ExecuteCommand(command, args)
    return NetUtils.executeCommand(DailyRewards.MODULE, "DailyRewards/Server", command, args)
end

--[[
Shared.RegisterCustomReward("DailyRewards.Custom.Halo", function(player, reward, context)
    if player and player.setHaloNote then
        local message = trim(reward.message)
        if message == "" then
            message = "Reward claimed."
        end
        player:setHaloNote(message, 255, 255, 255, 500)
    end
    return true, reward.message or "Halo note"
end, {
    displayName = "Halo Note",
    iconText = "FX",
})

Shared.RegisterCustomReward("DailyRewards.Custom.AddTrait", function(player, reward, context)
    local trait = trim(reward.trait)
    if trait == "" or not player or not player.getTraits then
        return false, "Missing trait"
    end
    if not player:getTraits():contains(trait) then
        player:getTraits():add(trait)
        SyncXp(player)
    end
    return true, "Trait " .. trait
end, {
    displayName = "Trait Reward",
    iconText = "TR",
})

Shared.RegisterCustomReward("MyMod.Custom.GiveToken", function(player, reward, context)
    local amount = math.floor(tonumber(reward.amount) or 1)

    for i = 1, amount do
        player:getInventory():AddItem("Base.Ring_Right_RingFinger_Gold")
    end

    return true, tostring(amount) .. " token(s)"
end, {
    displayName = "Token Reward",
    icon = "Base.Ring_Right_RingFinger_Gold",
})
--]]
return DailyRewards
