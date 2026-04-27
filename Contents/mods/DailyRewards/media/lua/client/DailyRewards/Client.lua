local Logger = require("DailyRewards/Logger")
local DailyRewards = require("DailyRewards/Shared")
local DailyRewardsPanel = require("DailyRewards/DailyRewardsPanel")

DailyRewards.Client = DailyRewards.Client or {}
DailyRewards.Client.ClientCommands = DailyRewards.Client.ClientCommands or {}

local Client = DailyRewards.Client
local Shared = DailyRewards.Shared

function Client.ClientCommands.LoadSnapshot(args)
    DailyRewards.ClientSnapshot = args or {}
    if DailyRewardsPanel.instance then
        DailyRewardsPanel.instance:onSnapshotReceived(DailyRewards.ClientSnapshot)
    end
end

function Client.ClientCommands.CommandResult(args)
    args = args or {}
    if DailyRewardsPanel.instance then
        DailyRewardsPanel.instance:setStatus(args.message or "", args.level or "info")
    end

    local player = getPlayer()
    if player and player.setHaloNote and args.message and args.message ~= "" then
        player:setHaloNote(args.message, 255, 255, 255, 500)
    end
end

function Client.onServerCommand(module, command, args)
    if module ~= DailyRewards.MODULE then
        return
    end

    local handler = Client.ClientCommands[command]
    if type(handler) == "function" then
        handler(args or {})
    end
end

Events.OnServerCommand.Add(Client.onServerCommand)

local requestReady = false
local function requestInitialSnapshot()
    if not requestReady then
        requestReady = true
        return
    end

    Events.OnTick.Remove(requestInitialSnapshot)
    if not Shared.ExecuteCommand("RequestSnapshot", { reason = "game-start" }) then
        Logger:warning("Failed to request Daily Rewards snapshot.")
    end
end

Events.OnTick.Add(requestInitialSnapshot)

return DailyRewards
