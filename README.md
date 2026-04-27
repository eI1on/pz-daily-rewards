# Daily Rewards

Daily Rewards is a Project Zomboid Build 41 mod that gives players a server-authoritative daily reward calendar, claimable missed days when enabled, and configurable streak rewards.

It is built for both singleplayer and multiplayer, with an in-game admin editor so servers do not have to hand-edit JSON just to change rewards.

## Requirements

- Project Zomboid Build 41
- ElyonLib

## What The Mod Does

- Adds a player view where users can:
  - see reward days in a grid
  - inspect daily and streak rewards
  - claim available daily rewards
  - claim available streak rewards
- Adds an admin view where admins can:
  - enable or disable the system
  - configure campaign start date
  - allow or block missed claims
  - choose preview days
  - choose streak grace days
  - edit daily rewards
  - edit streak rewards
  - import and export config
- Supports reward types:
  - items
  - XP
  - custom Lua rewards registered by other mods

## How It Works

### Player Data

- In multiplayer, player claim data is stored only on the server in Global ModData.
- Clients receive only their own snapshot.
- Admins receive the active config in their snapshot so they can edit it in-game.

### Config Data

- The active config is stored in `DailyRewardsConfig.json`.
- Admins normally work through the UI, not by hand-editing JSON.
- Import and Export are there for backup, sharing, and migration.

### Time And Anti-Cheat

- Claim and streak logic uses server time.
- Daily availability is based on the server day key.
- Streak rebuilding is authoritative and recalculated from saved claim data.
- Catch-up claims can collect missed rewards, but they do not magically repair a streak that already broke on the server.

## Player Guide

### Player View

- Open the Daily Rewards window from the ElyonLib menu.
- Browse the reward day grid.
- Click a day tile to inspect it.
- Claim a daily reward when the selected day is available.
- Claim a streak reward when the selected streak milestone is available.

### Reward Day States

- `Claimed`: you already took it
- `Ready`: claimable now
- `Upcoming`: future reward day
- `Locked`: not available yet

### Streaks

Streak rewards are based on valid claim progression, not simply on how many total rewards a player has ever claimed.

The important settings are:

- `Allow missed claims`
- `Streak grace days`
- `Repeat daily reward list`

## Admin Guide

### Global Settings

- `Enabled`: turns the system on or off
- `Allow missed claims`: allows older reward days to stay claimable
- `Repeat daily reward list`: loops the daily reward table after the last configured day
- `Campaign start date`: fixed global start date; if empty, each player starts from first seen date
- `Claimable history`: how many past days remain claimable; `0` means unlimited
- `Preview days`: how many future days players can inspect
- `Streak grace days`: how many missed real server days are tolerated before the active streak breaks

### Editing Reward Rows

The admin editor has two modes:

- `Daily Days`
- `Streaks`

For each row you can edit:

- internal id
- day number or streak days required
- title
- description
- items
- XP
- custom Lua rewards

Use `Apply Row` to update the selected row locally in the editor.

Use `Save All` to validate and publish the full config.

Use `Import` and `Export` to move `DailyRewardsConfig.json` in and out of the local Lua folder.

### Reward Editor Syntax

Items:

```text
Base.WaterBottleFull = 1
Base.TinnedSoup = 1
```

XP:

```text
Cooking = 25
Woodwork = 15
```

Custom rewards:

```text
DailyRewards.Custom.Halo | message=Reward claimed.
MyMod.Custom.CrateDrop | displayName=Supply Drop; iconText=SD; crateType=food
MyMod.Custom.MarkPlayer | displayName=Marked; icon=media/ui/my_mark.png; duration=3
MyMod.Custom.GiveToken | displayName=Token; icon=Base.Ring_Right_RingFinger_Gold; amount=2
```

## Custom Rewards For Modders

Custom rewards let another mod attach arbitrary behavior to a Daily Rewards row.

The registration API lives in:

- `Contents/mods/DailyRewards/media/lua/shared/DailyRewards/Shared.lua`

### Registering A Handler

```lua
local DailyRewards = require("DailyRewards/Shared")
local Shared = DailyRewards.Shared

Shared.RegisterCustomReward("MyMod.Custom.GiveToken", function(player, reward, context)
    local amount = math.floor(tonumber(reward.amount) or 1)

    for i = 1, amount do
        player:getInventory():AddItem("Base.Ring_Right_RingFinger_Gold")
    end

    return true, tostring(amount) .. " token(s)"
end, {
    displayName = "Token Reward",
    icon = "Base.Ring_Right_RingFinger_Gold",
    iconText = "TK",
})
```

### Handler Signature

Your handler receives:

- `player`: the target player
- `reward`: the custom reward entry from config
- `context`: extra claim context

The context includes things like:

- claim type (`daily` or `streak`)
- player id
- date key
- day number
- streak id
- required days
- today key

### Return Values

Return:

- `true, "summary text"` on success
- `false, "error text"` on failure

The summary text is used in claim feedback.

### Optional Registry Metadata

The third argument to `RegisterCustomReward` is optional metadata:

- `displayName`: player-facing name for summaries and previews
- `icon`: texture path or item full type
- `iconText`: optional short fallback text for the preview tile

Example:

```lua
Shared.RegisterCustomReward("MyMod.Custom.MarkPlayer", function(player, reward, context)
    player:setHaloNote("Marked", 255, 200, 50, 300)
    return true, "Marked"
end, {
    displayName = "Mark Player",
    icon = "media/ui/my_mark.png",
    iconText = "MK",
})
```

### Per-Reward UI Overrides

A specific reward row can override the registered metadata:

```text
MyMod.Custom.MarkPlayer | displayName=Marked 3 Days; iconText=M3; duration=3
```

Supported override keys:

- `displayName`
- `icon`
- `iconText`

Everything else on the line is passed through to your handler unchanged.

### Choosing Icons

`icon` can be:

- a texture path, for example `media/ui/my_icon.png`
- a valid item full type, for example `Base.Ring_Right_RingFinger_Gold`
- an `Item_` texture name if you already know the texture id

If no texture resolves, the tile falls back to `iconText`.

If no `iconText` is provided, Daily Rewards does not generate one automatically.

## Code Map

### Shared.lua

Main shared model and normalization layer:

- default config
- reward normalization
- streak rebuilding
- custom reward registry
- config load/save

### Server.lua

Authoritative reward flow:

- builds per-player snapshots
- validates claims
- grants items, XP, and custom rewards
- keeps multiplayer state server-side

### Client.lua

Thin client transport layer:

- receives snapshots
- forwards UI messages
- requests initial data from the server

### DailyRewardsPanel.lua

Actual game UI:

- player calendar
- admin editor
- reward preview tiles
- import/export buttons

## Important Implementation Notes

- The mod treats multiplayer as server-authoritative.
- Config is file-backed, player progress is ModData-backed.
- Custom reward metadata is split into:
  - handler registration defaults
  - per-row overrides
- Item names and item icons are resolved through ElyonLib item utilities with caching.
