# Daily Rewards - mod guide

**[B41] Daily Rewards** is a calendar-style gate: daily slots you can fill with loot plus optional **streak** bonuses. Players open it from the **ElyonLib menu dock**; the server decides what they may claim today and persists each account’s progress. Works in multiplayer (host authoritative) and singleplayer.

**Requires [ElyonLib](https://steamcommunity.com/sharedfiles/filedetails/?id=3384377738)** - list it above Daily Rewards.

---

## Using it in-game

- Open **Daily Rewards** from the ElyonLib floating menu.
- The **player** tab shows claimed days, what’s available now, streak progress, and what’s still locked.
- When the calendar date rolls forward, online players often get an automatic refresh so “today” updates.

Claims are checked on the server so clients can’t pull rewards early or twice.

---

## Admin / server settings

Admins get an **Admin** tab in the same window (plus import/export/reset for the config file). The important toggles and fields match what you edit in-game and what ends up in JSON:

| Field | Plain meaning |
|--------|----------------|
| `enabled` | Turn the whole system off without uninstalling. |
| `startDate` | Fixed first calendar day for everyone (`YYYY-MM-DD`). Leave unset to start each player from when they’re first seen. |
| `allowMissedClaims` | Off = only today; on = backlog within your history window. |
| `maxClaimableDays` | How many past days remain claimable (use `0` for “no hard cap” in math terms). |
| `previewDays` | How far ahead upcoming days appear in the list. |
| `repeatRewards` | After the last scripted day, loop the ladder from the top again or stop. |
| `resetStreakAfterMissedDays` | Grace: how sloppy real-life spacing can get before streak logic treats you as breaking the run. |
| `dailyRewards` | Ordered list of day presets (titles, fluff text, bundles of loot). |
| `streakRewards` | Milestones keyed on consecutive eligible days (`days`, repeatable tiers, bundles). |

**Save All** writes disk; backups are easiest with **Export** / **Import** of that file.

---

## Config file (`DailyRewardsConfig.json`)

Stores the ladder definitions only - not player inventory. ElyonLib stores it against the Workshop display id **`Daily Rewards`**; filename **`DailyRewardsConfig.json`**. First run may materialize sensible defaults via the normal mod-save path.

Example skeleton:

```json
{
  "enabled": true,
  "startDate": null,
  "allowMissedClaims": true,
  "maxClaimableDays": 30,
  "previewDays": 7,
  "repeatRewards": true,
  "resetStreakAfterMissedDays": 1,
  "dailyRewards": [ { "id": "day_1", "title": "Day 1", "rewards": { } } ],
  "streakRewards": [ { "id": "streak_7", "days": 7, "repeatable": false, "rewards": { } } ]
}
```

---

## What each reward bundle can contain

Under each calendar row / streak milestone, **`rewards`** bundles four parallel lists (`items`, `xp`, `traits`, `custom`). Omit empty ones.

### Items

Entries can be shorthand strings (`"Base.Apple"`) or objects with **`type`** (aliases `item`, `fullType`) and **`count`** (alias `amount`).

### XP

Objects with **`perk`** (aliases `skill`, `type`) and nonzero **`amount`** (alias `xp`).

### Traits

Trait id as a string **or** an object carrying **`trait`** / `type` / `id` / `name`. Invalid or conflicting picks are skipped or error per server rules.

### Custom Lua

Delegates one slice of the grant to **`RegisterCustomReward`** (**see below**). JSON carries at least **`handler`** (your registered id); you may stash any extra fields your Lua reads (`message`, `amount`, etc.).

---

## Custom Lua rewards (technical - other mods)

Run registration **once at load**, on whoever runs server logic in that session (**dedicated process, listen-server host, singleplayer host**):

```lua
local DailyRewards = require("DailyRewards/Shared")

DailyRewards.Shared.RegisterCustomReward(handlerId, function(player, reward, context)
	-- Grant something; return outcome for the payout summary / errors list.
	return true, "Shown in Received line"
end, optionalDefinitionUi)
```

Third argument **`optionalDefinitionUi`** is optional `{ displayName, icon, iconText }` defaults for tooling (mirrors thin metadata on **`DailyRewards.Custom.definitions`**; handlers live **`DailyRewards.Custom.handlers[handlerId]`**).

---

### Registration API

Signature in source: **`DailyRewards.Shared.RegisterCustomReward(handlerId, fn, definition)`**

- **`handlerId`**: literal string duplicated in **`rewards.custom[].handler`** inside **`DailyRewardsConfig.json`** / admin editor.
- **`fn`**: `function(player, reward, context) -> success, summary`

Return **`true, summaryString`** → summary is appended client-side (**`"Received: "`** concatenates successes).  

Return **`false, reason`** → adds to **`errors`** (**`"Reward claimed, but nothing was delivered: "`** paths if nothing else succeeded).

`reward` arrives after **`Shared.NormalizeRewards`**: cloned custom row **`rewards.custom[i]`**. Always has **`handler`**; **`TableUtils.deepCopy`** keeps every other JSON key (**`amount`**, **`message`**, **`displayName`**, **`icon`**, **`iconText`**, mod-specific payloads…).

`context` is built in **`Server.ServerCommands.ClaimDaily`** / **`ClaimStreak`** and passed into **`grantCustomReward`** alongside the same `player` / `reward` row.

**Daily claim context** (`Server.lua`):

```lua
{
	type = "daily",
	playerId = playerId,          -- Shared.GetPlayerKey(player)
	dateKey = row.dateKey,
	dayNumber = row.dayNumber,
	reward = row.reward,          -- full normalized daily row (includes nested .rewards)
	todayKey = todayKey,
}
```

Grant body for that slice: **`Server.GrantRewards(player, row.reward.rewards, context)`** - your **`reward`** argument to Lua is **only** the **`custom`** sub-entry, **`context.reward`** references the wrapping day row envelope.

**Streak claim context:**

```lua
{
	type = "streak",
	playerId = playerId,
	streakId = row.streakId,
	claimKey = row.claimKey,
	requiredDays = row.requiredDays,
	streak = row.streak,          -- streak milestone envelope (nested .rewards)
	todayKey = todayKey,
}
```

Grant path: **`Server.GrantRewards(player, row.streak.rewards, context)`**

---

### Copy-ready examples

**Halo toast** (`rewards.custom` extras: **`message`**)

```lua
local DailyRewards = require("DailyRewards/Shared")

DailyRewards.Shared.RegisterCustomReward("MyMod.Custom.Halo", function(player, reward, context)
	local TextUtils = require("ElyonLib/TextUtils/TextUtils")
	local message = TextUtils.trim(reward.message or "")
	if message == "" then message = "Reward claimed." end
	if player and player.setHaloNote then
		player:setHaloNote(message, 255, 255, 255, 500)
	end
	return true, message
end, { displayName = "Halo pop", iconText = "★" })
```

JSON:

```json
"custom": [ { "handler": "MyMod.Custom.Halo", "message": "Welcome back!" } ]
```

---

**Spawn item stacks** (`rewards.custom` extras: **`amount`**, **`itemType`** fallback)

```lua
DailyRewards.Shared.RegisterCustomReward("MyMod.Custom.Stack", function(player, reward, context)
	local TextUtils = require("ElyonLib/TextUtils/TextUtils")
	local amount = math.floor(tonumber(reward.amount) or 1)
	local itemType = TextUtils.trim(reward.itemType or "")
	if itemType == "" then itemType = "Base.Apple" end
	local inv = player and player:getInventory()
	if not inv then return false, "No inventory" end
	for _ = 1, amount do inv:AddItem(itemType) end
	return true, ("%d × %s"):format(amount, itemType)
end, { displayName = "Lua item stack", icon = "Base.Apple" })
```