require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "ISUI/ISComboBox"
require "ISUI/ISScrollingListBox"
require "ISUI/ISTextEntryBox"
require "ISUI/ISTickBox"

local DailyRewards = require("DailyRewards/Shared")
local ColorUtils = require("ElyonLib/ColorUtils/ColorUtils")
local Theme = require("ElyonLib/UI/Theme/Theme")
local DateTimeUtility = require("ElyonLib/DateTime/DateTimeUtility")
local DateTimeSelector = require("ElyonLib/UI/Calendar/DateTimeSelector")
local FileUtils = require("ElyonLib/FileUtils/FileUtils")
local ItemUtils = require("ElyonLib/ItemUtils/ItemUtils")
local MathUtils = require("ElyonLib/MathUtils/MathUtils")
local TableUtils = require("ElyonLib/TableUtils/TableUtils")
local TextUtils = require("ElyonLib/TextUtils/TextUtils")
local UIUtils = require("ElyonLib/UI/Utils/UIUtils")

local DailyRewardsPanel = ISCollapsableWindow:derive("DailyRewardsPanel")
DailyRewardsPanel.instance = nil

local Shared = DailyRewards.Shared
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

local C = {
    SIZE = {
        DEFAULT_W = 800,
        DEFAULT_H = 650,
        MIN_W = 750,
        MIN_H = 650,
    },
    LAYOUT = {
        PAD = 10,
        GAP = 8,
        GAP_S = 5,
        GAP_M = 10,
        GAP_L = 15,
        TOP = 34,
    },
    CTRL = {
        BUTTON_H = 24,
        FIELD_H = 24,
        TAB_W = 120,
        REFRESH_W = 100,
        CLAIM_DAILY_W = 170,
        CLAIM_STREAK_W = 180,
    },
    SETTINGS = {
        BOX_W = 300,
        BOX_NARROW_W = 240,
        BOX_H = 80,
        FIELD_X = 330,
        FIELD_X_NARROW = 260,
        LABEL_W = 150,
        LABEL_W_NARROW = 120,
        ROW_GAP = 30,
        ROW_GAP_NARROW = 25,
        DATE_W = 100,
        VALUE_W = 70,
        PICK_W = 50,
    },
    PLAYER = {
        SECTION_GAP    = 50,
        DETAIL_GAP     = 16,
        LIST_TITLE_GAP = 20,
        STATUS_BAR_GAP = 16,
    },
    ADMIN = {
        SECTION_GAP = 20,
        LIST_W = 270,
        LIST_W_COMPACT = 220,
        LIST_W_NARROW = 180,
        EDITOR_MIN_W = 390,
        EDITOR_MIN_W_NARROW = 380,
        SECTION_TITLE_GAP = 5,
        BODY_GAP = 16,
        BODY_GAP_NARROW = 20,
        REWARD_ROW = 42,
    },
    LABEL = {
        OFFSET_Y  = 3,
        ABOVE_GAP = 4,
    },
    LIST = {
        SCROLLBAR_CLIP_PAD = 3,
        TEXT_PAD = 8,
        TEXT_RIGHT_PAD = 10,
        ICON_PAD = 4,
        ICON_TEXT_GAP = 6,
        ICON_INSET = 8,
        ICON_SIZE = 18,
    },
    DETAIL = {
        TEXT_GAP    = 4,
        BLOCK_GAP   = 8,
        SECTION_GAP = 10,
    },
    ICON = {
        TEXTURE_PAD    = 2,
        LABEL_PAD      = 4,
        LABEL_TEXT_PAD = 2,
    },
    TILE = {
        TEXT_PAD = 6,
        TOP_PAD = 5,
        TITLE_Y = 25,
        ICON_Y = 48,
        TEXT_WIDTH_PAD = 12,
        ICON_GAP = 4,
        FOOTER_PAD = 6,
        FOOTER_STACK_GAP = 7,
    },
    GRID = {
        COLUMNS = 5,
        MIN_COLUMNS = 4,
        ROW = 112,
        TILE_GAP = 6,
        TILE_MIN_W = 104,
    },
    STREAK = {
        ROW = 36,
    },
    COLORS = Theme.standardColors(),
}

local ICON_CACHE = {
    custom = {},
    skills = {},
    traits = {}
}

local SKILL_TEXTURES = {
    Accuracy = "media/ui/ElyonLib/ui_skill_spiffo_accuracy.png",
    Agility = "media/ui/ElyonLib/ui_skill_spiffo_agility.png",
    Aiming = "media/ui/ElyonLib/ui_skill_spiffo_aiming.png",
    Axe = "media/ui/ElyonLib/ui_skill_spiffo_axe.png",
    Blunt = "media/ui/ElyonLib/ui_skill_spiffo_blunt.png",
    Carpentry = "media/ui/ElyonLib/ui_skill_spiffo_carpentry.png",
    Combat = "media/ui/ElyonLib/ui_skill_spiffo_combat.png",
    Cooking = "media/ui/ElyonLib/ui_skill_spiffo_cooking.png",
    Crafting = "media/ui/ElyonLib/ui_skill_spiffo_crafting.png",
    Doctor = "media/ui/ElyonLib/ui_skill_spiffo_first_aid.png",
    Electricity = "media/ui/ElyonLib/ui_skill_spiffo_electricity.png",
    Farming = "media/ui/ElyonLib/ui_skill_spiffo_farming.png",
    Firearm = "media/ui/ElyonLib/ui_skill_spiffo_firearm.png",
    Fishing = "media/ui/ElyonLib/ui_skill_spiffo_fishing.png",
    Fitness = "media/ui/ElyonLib/ui_skill_spiffo_fitness.png",
    Lightfoot = "media/ui/ElyonLib/ui_skill_spiffo_lightfooted.png",
    Lightfooted = "media/ui/ElyonLib/ui_skill_spiffo_lightfooted.png",
    LongBlade = "media/ui/ElyonLib/ui_skill_spiffo_long_blade.png",
    Maintenance = "media/ui/ElyonLib/ui_skill_spiffo_maintenance.png",
    Mechanics = "media/ui/ElyonLib/ui_skill_spiffo_mechanics.png",
    MetalWelding = "media/ui/ElyonLib/ui_skill_spiffo_metalworking.png",
    Nimble = "media/ui/ElyonLib/ui_skill_spiffo_nimble.png",
    None = nil,
    PlantScavenging = "media/ui/ElyonLib/ui_skill_spiffo_plant_scavenging.png",
    Reloading = "media/ui/ElyonLib/ui_skill_spiffo_reloading.png",
    SmallBlade = "media/ui/ElyonLib/ui_skill_spiffo_small_blade.png",
    SmallBlunt = "media/ui/ElyonLib/ui_skill_spiffo_small_blunt.png",
    Sneak = "media/ui/ElyonLib/ui_skill_spiffo_sneaking.png",
    Sneaking = "media/ui/ElyonLib/ui_skill_spiffo_sneaking.png",
    Spear = "media/ui/ElyonLib/ui_skill_spiffo_spear.png",
    Sprinting = "media/ui/ElyonLib/ui_skill_spiffo_sprinting.png",
    Strength = "media/ui/ElyonLib/ui_skill_spiffo_strength.png",
    Survivalist = "media/ui/ElyonLib/ui_skill_spiffo_survivalist.png",
    Tailoring = "media/ui/Traits/trait_tailor.png",
    Trapping = "media/ui/ElyonLib/ui_skill_spiffo_trapping.png",
    Woodwork = "media/ui/ElyonLib/ui_skill_spiffo_carpentry.png"
}

local SKILL_LABELS = {
    Accuracy = "ACC",
    Agility = "AGY",
    Aiming = "AIM",
    Axe = "BAA",
    Blunt = "BUA",
    Carpentry = "CRP",
    Combat = "CMB",
    Cooking = "COO",
    Crafting = "CFT",
    Doctor = "AID",
    Electricity = "ELC",
    Farming = "FRM",
    Firearm = "FIR",
    Fishing = "FIS",
    Fitness = "FIT",
    Lightfoot = "LFT",
    Lightfooted = "LFT",
    LongBlade = "LBA",
    Maintenance = "MNT",
    Mechanics = "MCH",
    MetalWelding = "MTL",
    Nimble = "NIM",
    None = "NON",
    PlantScavenging = "FOR",
    Reloading = "REL",
    SmallBlade = "SBA",
    SmallBlunt = "SBU",
    Sneak = "SNE",
    Sneaking = "SNE",
    Spear = "SPR",
    Sprinting = "SPT",
    Strength = "STR",
    Survivalist = "SUR",
    Tailoring = "TAL",
    Trapping = "TRA",
    Woodwork = "WW"
}

local parseNumber = MathUtils.parseNumber
local copyColor = ColorUtils.copy
local dateKeyToDateTable = DateTimeUtility.dateKeyToDateTable
local dateTableToDateKey = DateTimeUtility.dateTableToDateKey
local drawWrappedText = UIUtils.drawWrappedText
local formatDateKey = DateTimeUtility.formatDateKey
local getEntryText = UIUtils.getEntryText
local getItemDisplayName = ItemUtils.getDisplayName
local getItemScript = ItemUtils.getScriptItem
local getItemTexture = ItemUtils.getTexture
local getTextureFromReference = ItemUtils.getTextureFromReference
local getListContentWidth = UIUtils.getListContentWidth
local measure = TextUtils.measureWidth
local setBounds = UIUtils.setBounds
local setEntryText = UIUtils.setEntryText
local getListScrollBarWidth = UIUtils.getListScrollBarWidth
local setVisible = UIUtils.setVisible
local trim = TextUtils.trim
local trimTextToWidth = TextUtils.trimToWidth
local copyValue = TableUtils.deepCopy
local drawRewardIconTile

local function calculateDailyTileWidth(contentWidth, columns)
    return math.floor((contentWidth - C.GRID.TILE_GAP - (C.GRID.TILE_GAP * columns)) / columns)
end

local function getDailyGridColumnsForWidth(contentWidth)
    local columns = C.GRID.COLUMNS
    while columns > C.GRID.MIN_COLUMNS do
        if calculateDailyTileWidth(contentWidth, columns) >= C.GRID.TILE_MIN_W then
            break
        end
        columns = columns - 1
    end
    return columns
end

local function applyButtonStyle(button, variant)
    Theme.applyButtonStyle(button, variant)
end

local function addButton(panel, x, y, w, text, internal, variant)
    local button = ISButton:new(x, y, w, C.CTRL.BUTTON_H, text, panel, DailyRewardsPanel.onClick)
    button.internal = internal
    button:initialise()
    button:instantiate()
    applyButtonStyle(button, variant)
    panel:addChild(button)
    return button
end

local function applyListStyle(list)
    Theme.applyListStyle(list)
    list.drawBorder = true
end

local function applyComboStyle(combo)
    if not combo then return end
    local T                        = Theme.colors
    combo.backgroundColor          = Theme.copy(T.panel)
    combo.backgroundColorMouseOver = Theme.copy(T.primary)
    combo.borderColor              = Theme.copy(T.border)
    combo.textColor                = Theme.copy(T.text)
end

local function applyTickBoxStyle(tickBox)
    if not tickBox then return end
    tickBox.borderColor  = Theme.copy(Theme.colors.border)
    tickBox.choicesColor = Theme.copy(Theme.colors.text)
end

local function addEntry(panel, x, y, w, h, multiline, maxLines)
    local entry = ISTextEntryBox:new("", x, y, w, h)
    entry:initialise()
    entry:instantiate()
    if multiline then
        entry:setMultipleLine(true)
        entry:setMaxLines(maxLines or 1000)
    end
    Theme.applyFieldStyle(entry)
    panel:addChild(entry)
    return entry
end

local function addCombo(panel, x, y, w, onChange)
    local combo = ISComboBox:new(x, y, w, C.CTRL.FIELD_H, panel, onChange)
    combo:initialise()
    combo:instantiate()
    applyComboStyle(combo)
    panel:addChild(combo)
    return combo
end

local function addDataList(panel, x, y, w, h, itemHeight, drawFn, mouseFn, kind)
    local list = ISScrollingListBox:new(x, y, w, h)
    list:initialise()
    list:instantiate()
    list.itemheight = itemHeight or 24
    list.font = UIFont.Small
    list.parentPanel = panel
    list.listKind = kind
    list.doDrawItem = drawFn
    list.onMouseDown = mouseFn
    applyListStyle(list)
    panel:addChild(list)
    return list
end

local function getVisibleListScrollBarWidth(list)
    if list and list.vscroll and list.isVScrollBarVisible and list:isVScrollBarVisible() then
        return list.vscroll:getWidth()
    end
    return 0
end

local function getListContentRight(list, rightInset)
    return list:getWidth() - getVisibleListScrollBarWidth(list) - (rightInset or 0)
end

local function getListStencilBounds(list, y, height)
    local clipX = list.drawBorder and 1 or 0
    local clipY = math.max(0, y + list:getYScroll())
    local clipX2 =
        list:isVScrollBarVisible() and (list.vscroll.x + C.LIST.SCROLLBAR_CLIP_PAD) or
        (list:getWidth() - (list.drawBorder and 1 or 0))
    local clipY2 = math.min(list:getHeight() - (list.drawBorder and 1 or 0), y + height + list:getYScroll())

    if clipX2 <= clipX or clipY2 <= clipY then
        return nil
    end

    return clipX, clipY, clipX2 - clipX, clipY2 - clipY
end

local function drawClippedListRow(list, y, height, drawFn)
    local clipX, clipY, clipW, clipH = getListStencilBounds(list, y, height)
    if not clipX then
        return
    end

    list:setStencilRect(clipX, clipY, clipW, clipH)
    drawFn()
    list:clearStencilRect()
    list:repaintStencilRect(clipX, clipY, clipW, clipH)
end

local function getDailyStatus(row)
    if not row then
        return "", C.COLORS.LOCKED
    end
    if row.claimed then
        return getText("IGUI_DR_Claimed"), C.COLORS.CLAIMED
    end
    if row.claimable then
        return getText("IGUI_DR_Ready"), C.COLORS.READY
    end
    if row.future then
        return getText("IGUI_DR_Upcoming"), C.COLORS.MUTED
    end
    return getText("IGUI_DR_Locked"), C.COLORS.LOCKED
end

local function getSkillTexture(perkName)
    perkName = trim(perkName)
    if perkName == "" then
        return nil
    end
    if ICON_CACHE.skills[perkName] ~= nil then
        return ICON_CACHE.skills[perkName] or nil
    end

    local texturePath = SKILL_TEXTURES[perkName]
    local texture = texturePath and getTexture(texturePath) or nil
    ICON_CACHE.skills[perkName] = texture or false
    return texture
end

local function getSkillLabel(perkName)
    perkName = trim(perkName)
    return SKILL_LABELS[perkName] or perkName:sub(1, 3):upper()
end

local function getSkillDisplayName(perkName)
    perkName = trim(perkName)
    local perk = Perks[perkName]
    if not perk and Perks.FromString then
        perk = Perks.FromString(perkName)
    end
    if perk then
        local perkInfo = PerkFactory.getPerk(perk)
        if perkInfo and perkInfo.getName then
            return perkInfo:getName()
        end
    end
    return perkName
end

local function getTraitTexture(traitType)
    traitType = trim(traitType)
    if traitType == "" then
        return nil
    end
    if ICON_CACHE.traits[traitType] ~= nil then
        return ICON_CACHE.traits[traitType] or nil
    end

    local trait = TraitFactory.getTrait(traitType) or nil
    local texture = trait and trait.getTexture and trait:getTexture() or nil
    ICON_CACHE.traits[traitType] = texture or false
    return texture
end

local function getTraitLabel(traitType)
    local traitInfo = Shared.GetTraitInfo(traitType)
    return traitInfo and traitInfo.label or trim(tostring(traitType or "Trait"))
end

local function getTraitShortLabel(traitType)
    local compact = getTraitLabel(traitType):gsub("[%s%p_]+", ""):upper()
    if #compact >= 3 then
        return compact:sub(1, 3)
    end
    if compact ~= "" then
        return compact
    end
    return "TR"
end

local function getTraitTooltip(traitType)
    local traitInfo = Shared.GetTraitInfo(traitType)
    if not traitInfo then
        return tostring(traitType or "")
    end

    local polarity = traitInfo.positive and "+" or "-"
    local description = trim(traitInfo.description)
    if description ~= "" then
        return string.format("%s %s\n%s", polarity, traitInfo.label, description)
    end
    return string.format("%s %s", polarity, traitInfo.label)
end

local function getRewardSkillOptions()
    if DailyRewardsPanel.SkillRewardOptions then
        return DailyRewardsPanel.SkillRewardOptions
    end

    local result = {}
    for i = 1, Perks.getMaxIndex() do
        local perk = PerkFactory.getPerk(Perks.fromIndex(i - 1))
        if perk and perk:getParent() ~= Perks.None then
            local perkType = tostring(perk:getType())
            local parentName = PerkFactory.getPerkName(perk:getParent())
            local label = perk:getName()
            local text = label
            if parentName and parentName ~= "" then
                text = string.format("%s (%s)", label, parentName)
            end
            result[#result + 1] = {
                type = perkType,
                label = label,
                text = text
            }
        end
    end
    table.sort(
        result,
        function(a, b)
            return tostring(a.label):lower() < tostring(b.label):lower()
        end
    )
    DailyRewardsPanel.SkillRewardOptions = result
    return result
end

local function getRewardTraitOptions()
    if DailyRewardsPanel.TraitRewardOptions then
        return DailyRewardsPanel.TraitRewardOptions
    end

    local source = Shared.GetTraitList()
    local result = {}
    for i = 1, #source do
        local trait = source[i]
        result[#result + 1] = {
            type = trait.type,
            label = trait.label,
            description = trait.description,
            positive = trait.positive == true,
            text = string.format("%s %s", trait.positive and "[+]" or "[-]", trait.label)
        }
    end
    DailyRewardsPanel.TraitRewardOptions = result
    return result
end

local function getCustomRewardTexture(custom)
    local icon = Shared.GetCustomRewardIcon(custom)
    icon = trim(icon)
    if icon == "" then
        return nil
    end
    if ICON_CACHE.custom[icon] ~= nil then
        return ICON_CACHE.custom[icon] or nil
    end

    local texture = getTextureFromReference(icon)
    ICON_CACHE.custom[icon] = texture or false
    return texture
end

local function getCustomRewardIconText(custom)
    local _, iconText = Shared.GetCustomRewardIcon(custom)
    iconText = trim(iconText)
    if iconText ~= "" then
        return iconText
    end
    return nil
end

local function getCustomRewardTooltip(custom)
    local displayName = Shared.GetCustomRewardDisplayName(custom)
    local handlerId = tostring(custom and custom.handler or "?")
    if displayName ~= handlerId and trim(displayName) ~= "" then
        return getText("Tooltip_DR_Custom") ..
            ": " .. displayName .. "\n" .. getText("Tooltip_DR_Handler") .. ": " .. handlerId
    end
    return getText("Tooltip_DR_Custom") .. ": " .. handlerId
end

local function getRewardPreviewIcons(rewards, maxIcons)
    rewards = Shared.NormalizeRewards(rewards)
    maxIcons = maxIcons or 4
    local icons = {}

    for i = 1, #rewards.items do
        local item = rewards.items[i]
        icons[#icons + 1] = {
            type = "item",
            texture = getItemTexture(item.type),
            label = item.count and item.count > 1 and ("x" .. tostring(item.count)) or "",
            fallback = "IT",
            tooltip = tostring(item.count or 1) .. "x " .. getItemDisplayName(item.type)
        }
        if #icons >= maxIcons then
            return icons, (#rewards.items - i) + #rewards.xp + #rewards.traits + #rewards.custom
        end
    end

    for i = 1, #rewards.xp do
        local xp = rewards.xp[i]
        icons[#icons + 1] = {
            type = "xp",
            texture = getSkillTexture(xp.perk),
            label = getSkillLabel(xp.perk),
            fallback = getSkillLabel(xp.perk),
            tooltip = getSkillDisplayName(xp.perk) .. " XP +" .. tostring(xp.amount or 0)
        }
        if #icons >= maxIcons then
            return icons, (#rewards.xp - i) + #rewards.traits + #rewards.custom
        end
    end

    for i = 1, #rewards.traits do
        local traitType = rewards.traits[i].type
        local traitInfo = Shared.GetTraitInfo(traitType)
        icons[#icons + 1] = {
            type = "trait",
            positive = traitInfo and traitInfo.positive == true,
            texture = getTraitTexture(traitType),
            label = getTraitShortLabel(traitType),
            fallback = getTraitShortLabel(traitType),
            tooltip = getTraitTooltip(traitType)
        }
        if #icons >= maxIcons then
            return icons, (#rewards.traits - i) + #rewards.custom
        end
    end

    for i = 1, #rewards.custom do
        local custom = rewards.custom[i]
        local iconText = getCustomRewardIconText(custom)
        icons[#icons + 1] = {
            type = "custom",
            texture = getCustomRewardTexture(custom),
            label = iconText,
            fallback = iconText,
            tooltip = getCustomRewardTooltip(custom)
        }
        if #icons >= maxIcons then
            return icons, #rewards.custom - i
        end
    end

    return icons, 0
end

local function buildDailyTooltip(row)
    if not row then
        return nil
    end
    local statusText = getDailyStatus(row)
    local title =
        row.reward and row.reward.title or (getText("Tooltip_DR_Day") .. " " .. tostring(row.dayNumber or "?"))
    return string.format(
        "%s\n " .. getText("Tooltip_DR_Day") .. " %s | %s | %s\n%s",
        title,
        tostring(row.dayNumber or "?"),
        formatDateKey(row.dateKey, "DMY"),
        tostring(statusText or ""),
        Shared.GetRewardSummary(row.reward and row.reward.rewards or nil)
    )
end

local function eachDataLine(text)
    local lines = {}
    text = tostring(text or ""):gsub("\r\n", "\n"):gsub("\r", "\n")
    for rawLine in (text .. "\n"):gmatch("(.-)\n") do
        local line = trim(rawLine)
        if line ~= "" and line:sub(1, 1) ~= "#" and line:sub(1, 2) ~= "--" then
            lines[#lines + 1] = line
        end
    end
    return lines
end

local function parseCustomLines(text)
    local out = {}
    local lines = eachDataLine(text)
    for i = 1, #lines do
        local line = lines[i]
        local handler, params = line:match("^([^|]+)%s*|%s*(.*)$")
        handler = trim(handler or line)
        if handler ~= "" then
            local entry = { handler = handler }
            params = params or ""
            for token in (params .. ""):gmatch("(.-)") do
                local key, value = token:match("^%s*([^=]+)%s*=%s*(.-)%s*$")
                key = trim(key)
                if key ~= "" then
                    entry[key] = value
                end
            end
            out[#out + 1] = entry
        end
    end
    return out
end

local function formatCustom(rewards)
    local lines = {}
    rewards = Shared.NormalizeRewards(rewards)
    for i = 1, #rewards.custom do
        local custom = rewards.custom[i]
        local parts = {}
        local preferred = { "displayName", "icon", "iconText", "message", "trait" }
        local used = { handler = true }
        for j = 1, #preferred do
            local key = preferred[j]
            used[key] = true
            if custom[key] ~= nil then
                parts[#parts + 1] = key .. "=" .. tostring(custom[key])
            end
        end
        local extraKeys = {}
        for key, _ in pairs(custom) do
            if not used[key] then
                extraKeys[#extraKeys + 1] = key
            end
        end
        table.sort(
            extraKeys,
            function(a, b)
                return tostring(a) < tostring(b)
            end
        )
        for j = 1, #extraKeys do
            local key = extraKeys[j]
            parts[#parts + 1] = tostring(key) .. "=" .. tostring(custom[key])
        end
        if #parts > 0 then
            lines[#lines + 1] = tostring(custom.handler or "") .. " | " .. table.concat(parts, " ")
        else
            lines[#lines + 1] = tostring(custom.handler or "")
        end
    end
    return table.concat(lines, "\n")
end

local function buildRewardConfig(title, description, rewards)
    return {
        title = trim(title),
        description = trim(description),
        rewards = Shared.NormalizeRewards(
            {
                items = copyValue(rewards.items or {}),
                xp = copyValue(rewards.xp or {}),
                traits = copyValue(rewards.traits or {}),
                custom = parseCustomLines(rewards.custom)
            }
        )
    }
end

function DailyRewardsPanel:new(x, y, width, height, playerObj)
    local o = ISCollapsableWindow.new(self, x, y, width, height)
    setmetatable(o, self)
    self.__index               = self

    o.playerObj                = playerObj or getPlayer()
    o.snapshot                 = DailyRewards.ClientSnapshot or {}
    o.activeTab                = "player"
    o.statusMessage            = getText("IGUI_DR_StatusLoading")
    o.statusLevel              = "info"
    o.backgroundColor          = Theme.copy(Theme.colors.background)
    o.borderColor              = Theme.copy(Theme.colors.border)
    o.title                    = getText("IGUI_DR_DailyRewards")
    o.minimumWidth             = C.SIZE.MIN_W
    o.minimumHeight            = C.SIZE.MIN_H
    o.selectedDailyKey         = nil
    o.selectedStreakKey        = nil
    o.adminMode                = "daily"
    o.adminSelectedIndex       = 1
    o.adminDirty               = false
    o.adminConfig              = nil
    o.rewardItemsData          = {}
    o.rewardXpData             = {}
    o.rewardTraitsData         = {}
    o.selectedRewardItemIndex  = 0
    o.selectedRewardXpIndex    = 0
    o.selectedRewardTraitIndex = 0
    return o
end

function DailyRewardsPanel:initialise()
    ISCollapsableWindow.initialise(self)
end

function DailyRewardsPanel:createChildren()
    ISCollapsableWindow.createChildren(self)
    self:setResizable(true)

    local y = C.LAYOUT.TOP
    local x = C.LAYOUT.PAD

    self.playerTabBtn = addButton(self, x, y, C.CTRL.TAB_W, getText("IGUI_DR_PlayerView"), "TAB_PLAYER", "primary")
    x = x + C.CTRL.TAB_W + C.LAYOUT.GAP
    self.adminTabBtn = addButton(self, x, y, C.CTRL.TAB_W, getText("IGUI_DR_AdminView"), "TAB_ADMIN")
    x = x + C.CTRL.TAB_W + C.LAYOUT.GAP
    self.refreshBtn = addButton(self, x, y, C.CTRL.REFRESH_W, getText("IGUI_DR_Refresh"), "REFRESH")

    y = y + C.CTRL.BUTTON_H + C.LAYOUT.GAP

    local leftW = 620
    local dailyY = y + C.PLAYER.LIST_TITLE_GAP + C.LAYOUT.GAP_S
    self.dailyGrid = ISScrollingListBox:new(C.LAYOUT.PAD, dailyY, leftW, 330)
    self.dailyGrid:initialise()
    self.dailyGrid:instantiate()
    self.dailyGrid.itemheight = C.GRID.ROW
    self.dailyGrid.font = UIFont.Small
    self.dailyGrid.parentPanel = self
    self.dailyGrid.doDrawItem = DailyRewardsPanel.drawDailyGridRow
    self.dailyGrid.onMouseDown = DailyRewardsPanel.onDailyGridMouseDown
    self.dailyGrid.onMouseMove = DailyRewardsPanel.onDailyGridMouseMove
    applyListStyle(self.dailyGrid)
    self:addChild(self.dailyGrid)

    self.streakList = ISScrollingListBox:new(C.LAYOUT.PAD, self.dailyGrid:getBottom() + C.PLAYER.SECTION_GAP, leftW, 108)
    self.streakList:initialise()
    self.streakList:instantiate()
    self.streakList.itemheight = C.STREAK.ROW
    self.streakList.font = UIFont.Small
    self.streakList.parentPanel = self
    self.streakList.doDrawItem = DailyRewardsPanel.drawStreakItem
    self.streakList.onMouseDown = DailyRewardsPanel.onStreakListMouseDown
    applyListStyle(self.streakList)
    self:addChild(self.streakList)

    local actionY = self.streakList:getBottom() + C.LAYOUT.GAP
    self.claimDailyBtn =
        addButton(self, C.LAYOUT.PAD, actionY, C.CTRL.CLAIM_DAILY_W, getText("IGUI_DR_ClaimDay"), "CLAIM_DAILY",
            "primary")
    self.claimStreakBtn =
        addButton(
            self,
            self.claimDailyBtn:getRight() + C.LAYOUT.GAP,
            actionY,
            C.CTRL.CLAIM_STREAK_W,
            getText("IGUI_DR_ClaimStreak"),
            "CLAIM_STREAK",
            "primary"
        )

    self.detailRect = {
        x = self.dailyGrid:getRight() + C.PLAYER.DETAIL_GAP,
        y = self.dailyGrid:getY(),
        width = self.width - self.dailyGrid:getRight() - C.LAYOUT.PAD - C.PLAYER.DETAIL_GAP,
        height = self.streakList:getBottom() - self.dailyGrid:getY()
    }

    self.playerControls = {
        self.dailyGrid,
        self.streakList,
        self.claimDailyBtn,
        self.claimStreakBtn
    }

    self:createAdminChildren(y)
    self:applyTooltips()
    self:layoutChildren(true)
    self:populateFromSnapshot()
    self:updateModeVisibility()
end

function DailyRewardsPanel:createAdminChildren(contentY)
    local settingsY = contentY + C.PLAYER.LIST_TITLE_GAP + 2
    self.settingsTickBox =
        ISTickBox:new(
            C.LAYOUT.PAD,
            settingsY,
            C.SETTINGS.BOX_W,
            C.SETTINGS.BOX_H,
            "DailyRewardsSettings",
            self,
            DailyRewardsPanel.onSettingChanged
        )
    self.settingsTickBox:initialise()
    self.settingsTickBox:instantiate()
    self.settingsTickBox:addOption(getText("IGUI_DR_Enabled"))
    self.settingsTickBox:addOption(getText("IGUI_DR_AllowMissedClaims"))
    self.settingsTickBox:addOption(getText("IGUI_DR_RepeatDailyRewards"))
    applyTickBoxStyle(self.settingsTickBox)
    self:addChild(self.settingsTickBox)

    local fieldX = C.SETTINGS.FIELD_X
    local fieldY = settingsY
    self.startDateEntry = addEntry(self, fieldX + C.SETTINGS.LABEL_W, fieldY, C.SETTINGS.DATE_W, C.CTRL.FIELD_H)
    self.startDatePickBtn =
        addButton(
            self,
            self.startDateEntry:getRight() + C.LAYOUT.GAP,
            fieldY,
            C.SETTINGS.PICK_W,
            getText("IGUI_DR_PickDate"),
            "PICK_START_DATE"
        )
    local rightSettingsX = self.startDatePickBtn:getRight() + C.SETTINGS.LABEL_W + C.LAYOUT.GAP_L
    self.maxClaimableDaysEntry =
        addEntry(self, fieldX + C.SETTINGS.LABEL_W, fieldY + C.SETTINGS.ROW_GAP, C.SETTINGS.VALUE_W, C.CTRL.FIELD_H)
    self.previewDaysEntry = addEntry(self, rightSettingsX, fieldY, C.SETTINGS.VALUE_W, C.CTRL.FIELD_H)
    self.resetStreakEntry = addEntry(self, rightSettingsX, fieldY + C.SETTINGS.ROW_GAP, C.SETTINGS.VALUE_W,
        C.CTRL.FIELD_H)

    local bodyY = settingsY + C.SETTINGS.BOX_H + C.ADMIN.BODY_GAP
    self.adminDailyModeBtn =
        addButton(self, C.LAYOUT.PAD, bodyY, 115, getText("IGUI_DR_DailyDays"), "ADMIN_MODE_DAILY", "primary")
    self.adminStreakModeBtn =
        addButton(
            self,
            self.adminDailyModeBtn:getRight() + C.LAYOUT.GAP,
            bodyY,
            115,
            getText("IGUI_DR_AdminStreaks"),
            "ADMIN_MODE_STREAK"
        )

    self.adminRewardsList =
        ISScrollingListBox:new(C.LAYOUT.PAD, bodyY + C.CTRL.BUTTON_H + C.PLAYER.LIST_TITLE_GAP, C.ADMIN.LIST_W, 350)
    self.adminRewardsList:initialise()
    self.adminRewardsList:instantiate()
    self.adminRewardsList.itemheight = C.ADMIN.REWARD_ROW
    self.adminRewardsList.font = UIFont.Small
    self.adminRewardsList.parentPanel = self
    self.adminRewardsList.doDrawItem = DailyRewardsPanel.drawAdminRewardItem
    self.adminRewardsList.onMouseDown = DailyRewardsPanel.onAdminRewardsListMouseDown
    applyListStyle(self.adminRewardsList)
    self:addChild(self.adminRewardsList)

    self.addRewardBtn =
        addButton(
            self,
            C.LAYOUT.PAD,
            self.adminRewardsList:getBottom() + C.LAYOUT.GAP,
            85,
            getText("IGUI_DR_AddReward"),
            "ADMIN_ADD",
            "primary"
        )
    self.deleteRewardBtn =
        addButton(
            self,
            self.addRewardBtn:getRight() + C.LAYOUT.GAP,
            self.addRewardBtn:getY(),
            85,
            getText("IGUI_DR_DeleteReward"),
            "ADMIN_DELETE",
            "danger"
        )

    local editorX = self.adminRewardsList:getRight() + C.ADMIN.SECTION_GAP
    local editorY = bodyY
    local editorW = 420
    local editorRowY = editorY + C.CTRL.BUTTON_H
    self.rewardIdEntry = addEntry(self, editorX, editorRowY, 130, C.CTRL.FIELD_H)
    self.rewardDayEntry =
        addEntry(self, self.rewardIdEntry:getRight() + C.LAYOUT.GAP_M, editorRowY, C.SETTINGS.VALUE_W, C.CTRL.FIELD_H)
    self.rewardTitleEntry =
        addEntry(
            self,
            self.rewardDayEntry:getRight() + C.LAYOUT.GAP_M,
            editorRowY,
            editorW - (self.rewardDayEntry:getRight() - editorX) - C.LAYOUT.GAP_M,
            C.CTRL.FIELD_H
        )
    self.rewardRepeatTickBox =
        ISTickBox:new(
            self.rewardTitleEntry:getX(),
            self.rewardTitleEntry:getBottom() + C.LAYOUT.GAP_S,
            170,
            C.CTRL.FIELD_H,
            "DailyRewardsRepeat",
            self,
            DailyRewardsPanel.onSettingChanged
        )
    self.rewardRepeatTickBox:initialise()
    self.rewardRepeatTickBox:instantiate()
    self.rewardRepeatTickBox:addOption(getText("IGUI_DR_Repeatable"))
    applyTickBoxStyle(self.rewardRepeatTickBox)
    self:addChild(self.rewardRepeatTickBox)

    self.rewardDescriptionEntry =
        addEntry(self, editorX, self.rewardRepeatTickBox:getBottom() + C.LAYOUT.GAP_S, editorW, 50, true, 4)
    local itemRowY = self.rewardDescriptionEntry:getBottom() + C.ADMIN.SECTION_GAP + C.LAYOUT.GAP_S
    self.rewardItemTypeEntry = addEntry(self, editorX, itemRowY, 220, C.CTRL.FIELD_H)
    self.rewardItemCountEntry =
        addEntry(self, self.rewardItemTypeEntry:getRight() + C.LAYOUT.GAP_M, itemRowY, 50, C.CTRL.FIELD_H)
    self.rewardItemCountEntry:setOnlyNumbers(true)
    self.addRewardItemBtn =
        addButton(
            self,
            self.rewardItemCountEntry:getRight() + C.LAYOUT.GAP_M,
            itemRowY,
            50,
            getText("IGUI_DR_Add"),
            "ADD_REWARD_ITEM",
            "primary"
        )
    self.removeRewardItemBtn =
        addButton(
            self,
            self.addRewardItemBtn:getRight() + C.LAYOUT.GAP_M,
            itemRowY,
            60,
            getText("IGUI_DR_Remove"),
            "REMOVE_REWARD_ITEM",
            "danger"
        )
    self.rewardItemList =
        addDataList(
            self,
            editorX,
            self.rewardItemTypeEntry:getBottom() + C.LAYOUT.GAP_S,
            editorW,
            70,
            28,
            DailyRewardsPanel.drawRewardItemListItem,
            DailyRewardsPanel.onRewardDataListMouseDown,
            "item"
        )

    local xpRowY = self.rewardItemList:getBottom() + C.ADMIN.SECTION_GAP - C.LAYOUT.GAP_S
    self.rewardXpSkillCombo = addCombo(self, editorX, xpRowY, 220, DailyRewardsPanel.onRewardComboChanged)
    self.rewardXpAmountEntry = addEntry(self, self.rewardXpSkillCombo:getRight() + C.LAYOUT.GAP_M, xpRowY, 50,
        C.CTRL.FIELD_H)
    self.rewardXpAmountEntry:setOnlyNumbers(true)
    self.addRewardXpBtn =
        addButton(
            self,
            self.rewardXpAmountEntry:getRight() + C.LAYOUT.GAP_M,
            xpRowY,
            50,
            getText("IGUI_DR_Add"),
            "ADD_REWARD_XP",
            "primary"
        )
    self.removeRewardXpBtn =
        addButton(
            self,
            self.addRewardXpBtn:getRight() + C.LAYOUT.GAP_M,
            xpRowY,
            60,
            getText("IGUI_DR_Remove"),
            "REMOVE_REWARD_XP",
            "danger"
        )
    self.rewardXpList =
        addDataList(
            self,
            editorX,
            self.rewardXpSkillCombo:getBottom() + C.LAYOUT.GAP_S,
            editorW,
            60,
            28,
            DailyRewardsPanel.drawRewardXpListItem,
            DailyRewardsPanel.onRewardDataListMouseDown,
            "xp"
        )

    local traitRowY = self.rewardXpList:getBottom() + C.ADMIN.SECTION_GAP - C.LAYOUT.GAP_S
    self.rewardTraitCombo = addCombo(self, editorX, traitRowY, 280, DailyRewardsPanel.onRewardComboChanged)
    self.addRewardTraitBtn =
        addButton(
            self,
            self.rewardTraitCombo:getRight() + C.LAYOUT.GAP_M,
            traitRowY,
            50,
            getText("IGUI_DR_Add"),
            "ADD_REWARD_TRAIT",
            "primary"
        )
    self.removeRewardTraitBtn =
        addButton(
            self,
            self.addRewardTraitBtn:getRight() + C.LAYOUT.GAP_M,
            traitRowY,
            60,
            getText("IGUI_DR_Remove"),
            "REMOVE_REWARD_TRAIT",
            "danger"
        )
    self.rewardTraitList =
        addDataList(
            self,
            editorX,
            self.rewardTraitCombo:getBottom() + C.LAYOUT.GAP_S,
            editorW,
            60,
            28,
            DailyRewardsPanel.drawRewardTraitListItem,
            DailyRewardsPanel.onRewardDataListMouseDown,
            "trait"
        )

    self.rewardCustomEntry =
        addEntry(self, editorX, self.rewardTraitList:getBottom() + C.ADMIN.SECTION_GAP, editorW, 70, true, 20)

    self.applyRewardBtn =
        addButton(
            self,
            editorX,
            self.rewardCustomEntry:getBottom() + C.ADMIN.SECTION_GAP - C.LAYOUT.GAP_S,
            C.CTRL.TAB_W,
            getText("IGUI_DR_ApplyReward"),
            "ADMIN_APPLY",
            "primary"
        )
    self.saveConfigBtn =
        addButton(
            self,
            self.applyRewardBtn:getRight() + C.LAYOUT.GAP,
            self.applyRewardBtn:getY(),
            120,
            getText("IGUI_DR_SaveAllConfig"),
            "SAVE_CONFIG",
            "primary"
        )
    self.resetConfigBtn =
        addButton(
            self,
            self.saveConfigBtn:getRight() + C.LAYOUT.GAP,
            self.applyRewardBtn:getY(),
            120,
            getText("IGUI_DR_ResetConfig"),
            "RESET_CONFIG",
            "danger"
        )
    self.importConfigBtn =
        addButton(
            self,
            self.resetConfigBtn:getRight() + C.LAYOUT.GAP,
            self.applyRewardBtn:getY(),
            100,
            getText("IGUI_DR_ImportConfig"),
            "IMPORT_CONFIG"
        )
    self.exportConfigBtn =
        addButton(
            self,
            self.importConfigBtn:getRight() + C.LAYOUT.GAP,
            self.applyRewardBtn:getY(),
            100,
            getText("IGUI_DR_ExportConfig"),
            "EXPORT_CONFIG"
        )

    self.adminControls = {
        self.settingsTickBox,
        self.startDateEntry,
        self.startDatePickBtn,
        self.maxClaimableDaysEntry,
        self.previewDaysEntry,
        self.resetStreakEntry,
        self.adminDailyModeBtn,
        self.adminStreakModeBtn,
        self.adminRewardsList,
        self.addRewardBtn,
        self.deleteRewardBtn,
        self.rewardIdEntry,
        self.rewardDayEntry,
        self.rewardTitleEntry,
        self.rewardRepeatTickBox,
        self.rewardDescriptionEntry,
        self.rewardItemTypeEntry,
        self.rewardItemCountEntry,
        self.addRewardItemBtn,
        self.removeRewardItemBtn,
        self.rewardItemList,
        self.rewardXpSkillCombo,
        self.rewardXpAmountEntry,
        self.addRewardXpBtn,
        self.removeRewardXpBtn,
        self.rewardXpList,
        self.rewardTraitCombo,
        self.addRewardTraitBtn,
        self.removeRewardTraitBtn,
        self.rewardTraitList,
        self.rewardCustomEntry,
        self.applyRewardBtn,
        self.saveConfigBtn,
        self.resetConfigBtn,
        self.importConfigBtn,
        self.exportConfigBtn
    }

    setEntryText(self.rewardItemCountEntry, "1")
    setEntryText(self.rewardXpAmountEntry, "25")
    self.rewardXpSkillCombo.noSelectionText = getText("IGUI_DR_SelectSkill")
    self.rewardTraitCombo.noSelectionText = getText("IGUI_DR_SelectTrait")
    self:populateRewardSkillCombo()
    self:populateRewardTraitCombo()
end

function DailyRewardsPanel:applyTooltips()
    self.playerTabBtn.tooltip = getText("Tooltip_DR_PlayerTab")
    self.adminTabBtn.tooltip = getText("Tooltip_DR_AdminTab")
    self.refreshBtn.tooltip = getText("Tooltip_DR_Refresh")
    self.claimDailyBtn.tooltip = getText("Tooltip_DR_ClaimDay")
    self.claimStreakBtn.tooltip = getText("Tooltip_DR_ClaimStreak")
    self.dailyGrid.tooltip = getText("Tooltip_DR_DayGrid")
    self.streakList.tooltip = getText("Tooltip_DR_StreakList")

    self.settingsTickBox.tooltip = getText("Tooltip_DR_Settings")
    self.startDateEntry.tooltip = getText("Tooltip_DR_StartDate")
    self.startDatePickBtn.tooltip = getText("Tooltip_DR_StartDatePicker")
    self.maxClaimableDaysEntry.tooltip = getText("Tooltip_DR_MaxClaimableDays")
    self.previewDaysEntry.tooltip = getText("Tooltip_DR_PreviewDays")
    self.resetStreakEntry.tooltip = getText("Tooltip_DR_StreakGraceDays")
    self.adminDailyModeBtn.tooltip = getText("Tooltip_DR_DailyMode")
    self.adminStreakModeBtn.tooltip = getText("Tooltip_DR_StreakMode")
    self.adminRewardsList.tooltip = getText("Tooltip_DR_RewardRows")
    self.addRewardBtn.tooltip = getText("Tooltip_DR_AddReward")
    self.deleteRewardBtn.tooltip = getText("Tooltip_DR_DeleteReward")
    self.rewardIdEntry.tooltip = getText("Tooltip_DR_RewardId")
    self.rewardDayEntry.tooltip = getText("Tooltip_DR_RewardDay")
    self.rewardTitleEntry.tooltip = getText("Tooltip_DR_RewardTitle")
    self.rewardRepeatTickBox.tooltip = getText("Tooltip_DR_Repeatable")
    self.rewardDescriptionEntry.tooltip = getText("Tooltip_DR_RewardDescription")
    self.rewardItemTypeEntry.tooltip = getText("Tooltip_DR_RewardItemType")
    self.rewardItemCountEntry.tooltip = getText("Tooltip_DR_RewardItemCount")
    self.addRewardItemBtn.tooltip = getText("Tooltip_DR_AddRewardItem")
    self.removeRewardItemBtn.tooltip = getText("Tooltip_DR_RemoveRewardItem")
    self.rewardItemList.tooltip = getText("Tooltip_DR_RewardItemList")
    self.rewardXpSkillCombo.tooltip = getText("Tooltip_DR_RewardXpSkill")
    self.rewardXpAmountEntry.tooltip = getText("Tooltip_DR_RewardXpAmount")
    self.addRewardXpBtn.tooltip = getText("Tooltip_DR_AddRewardXp")
    self.removeRewardXpBtn.tooltip = getText("Tooltip_DR_RemoveRewardXp")
    self.rewardXpList.tooltip = getText("Tooltip_DR_RewardXpList")
    self.rewardTraitCombo.tooltip = getText("Tooltip_DR_RewardTraitSelect")
    self.addRewardTraitBtn.tooltip = getText("Tooltip_DR_AddRewardTrait")
    self.removeRewardTraitBtn.tooltip = getText("Tooltip_DR_RemoveRewardTrait")
    self.rewardTraitList.tooltip = getText("Tooltip_DR_RewardTraitList")
    self.rewardCustomEntry.tooltip = getText("Tooltip_DR_RewardCustom")
    self.applyRewardBtn.tooltip = getText("Tooltip_DR_ApplyReward")
    self.saveConfigBtn.tooltip = getText("Tooltip_DR_SaveAllConfig")
    self.resetConfigBtn.tooltip = getText("Tooltip_DR_ResetConfig")
    self.importConfigBtn.tooltip = getText("Tooltip_DR_ImportConfig")
    self.exportConfigBtn.tooltip = getText("Tooltip_DR_ExportConfig")
end

function DailyRewardsPanel:layoutChildren(force)
    if not self.dailyGrid then
        return
    end

    local width = math.max(math.floor(self:getWidth()), self.minimumWidth or C.SIZE.MIN_W)
    local height = math.max(math.floor(self:getHeight()), self.minimumHeight or C.SIZE.MIN_H)
    if self:getWidth() ~= width then
        self:setWidth(width)
    end
    if self:getHeight() ~= height then
        self:setHeight(height)
    end
    if not force and self._layoutWidth == width and self._layoutHeight == height then
        return
    end
    self._layoutWidth = width
    self._layoutHeight = height

    local rh = self:resizeWidgetHeight()
    setBounds(self.resizeWidget, width - rh, height - rh, rh, rh)
    setBounds(self.resizeWidget2, 0, height - rh, width - rh, rh)

    local x = C.LAYOUT.PAD
    local y = C.LAYOUT.TOP
    setBounds(self.playerTabBtn, x, y, C.CTRL.TAB_W, C.CTRL.BUTTON_H)
    x = x + C.CTRL.TAB_W + C.LAYOUT.GAP
    setBounds(self.adminTabBtn, x, y, C.CTRL.TAB_W, C.CTRL.BUTTON_H)
    x = x + C.CTRL.TAB_W + C.LAYOUT.GAP
    setBounds(self.refreshBtn, x, y, C.CTRL.REFRESH_W, C.CTRL.BUTTON_H)

    local contentY = y + C.CTRL.BUTTON_H + C.LAYOUT.GAP
    local statusTop = height - C.LAYOUT.PAD - FONT_HGT_SMALL - C.PLAYER.STATUS_BAR_GAP
    local playerGridY = contentY + C.PLAYER.LIST_TITLE_GAP + C.LAYOUT.GAP_S
    local detailW = math.max(220, math.floor(width * 0.28))
    local leftW = width - detailW - (C.LAYOUT.PAD * 2) - C.PLAYER.DETAIL_GAP
    if leftW < 500 then
        leftW = 500
        detailW = width - leftW - (C.LAYOUT.PAD * 2) - C.PLAYER.DETAIL_GAP
    end
    if detailW < 200 then
        detailW = 200
        leftW = width - detailW - (C.LAYOUT.PAD * 2) - C.PLAYER.DETAIL_GAP
    end

    local dailyContentW = leftW - getListScrollBarWidth(self.dailyGrid)
    local columns = getDailyGridColumnsForWidth(dailyContentW)
    local repopulateDailyGrid = self.dailyGridColumns ~= columns
    self.dailyGridColumns = columns
    self.dailyGrid.dailyRewardColumns = columns
    self.dailyGrid.reserveScrollBarSpace = true
    local tileW = calculateDailyTileWidth(dailyContentW, columns)
    self.dailyGrid.itemheight = math.max(112, math.min(140, tileW + 24))
    local actionY = statusTop - C.CTRL.BUTTON_H
    local streakH = math.max(104, math.min(132, math.floor(height * 0.16)))
    local streakY = actionY - C.LAYOUT.GAP - streakH
    local gridH =
        math.max(self.dailyGrid.itemheight + C.PLAYER.LIST_TITLE_GAP, streakY - playerGridY - C.PLAYER.SECTION_GAP)

    setBounds(self.dailyGrid, C.LAYOUT.PAD, playerGridY, leftW, gridH)
    setBounds(self.streakList, C.LAYOUT.PAD, self.dailyGrid:getBottom() + C.PLAYER.SECTION_GAP, leftW, streakH)
    setBounds(self.claimDailyBtn, C.LAYOUT.PAD, actionY, C.CTRL.CLAIM_DAILY_W, C.CTRL.BUTTON_H)
    setBounds(self.claimStreakBtn, self.claimDailyBtn:getRight() + C.LAYOUT.GAP, actionY, C.CTRL.CLAIM_STREAK_W, C.CTRL
        .BUTTON_H)

    self.detailRect = {
        x = self.dailyGrid:getRight() + C.PLAYER.DETAIL_GAP,
        y = self.dailyGrid:getY(),
        width = width - self.dailyGrid:getRight() - C.LAYOUT.PAD - C.PLAYER.DETAIL_GAP,
        height = self.streakList:getBottom() - self.dailyGrid:getY()
    }

    if repopulateDailyGrid then
        self:populateDailyGrid()
    end

    local compactAdmin = width < 1000
    local narrowAdmin = width < 920
    local compactEditor = height < 760 or narrowAdmin
    self._narrowAdminLayout = narrowAdmin

    local settingsY = contentY + C.PLAYER.LIST_TITLE_GAP + 2
    setBounds(
        self.settingsTickBox,
        C.LAYOUT.PAD,
        settingsY,
        narrowAdmin and C.SETTINGS.BOX_NARROW_W or C.SETTINGS.BOX_W,
        C.SETTINGS.BOX_H
    )
    local fieldX = narrowAdmin and C.SETTINGS.FIELD_X_NARROW or C.SETTINGS.FIELD_X
    local settingsLabelW = narrowAdmin and C.SETTINGS.LABEL_W_NARROW or C.SETTINGS.LABEL_W
    local settingsRowGap = narrowAdmin and C.SETTINGS.ROW_GAP_NARROW or C.SETTINGS.ROW_GAP
    local settingsEntryX = fieldX + settingsLabelW
    self._settingsLabelW = settingsLabelW
    setBounds(self.startDateEntry, settingsEntryX, settingsY, C.SETTINGS.DATE_W, C.CTRL.FIELD_H)
    setBounds(self.startDatePickBtn, self.startDateEntry:getRight() + C.LAYOUT.GAP, settingsY, C.SETTINGS.PICK_W,
        C.CTRL.BUTTON_H)
    setBounds(self.maxClaimableDaysEntry, settingsEntryX, settingsY + settingsRowGap, C.SETTINGS.VALUE_W, C.CTRL.FIELD_H)
    if narrowAdmin then
        setBounds(
            self.previewDaysEntry,
            settingsEntryX,
            settingsY + (settingsRowGap * 2),
            C.SETTINGS.VALUE_W,
            C.CTRL.FIELD_H
        )
        setBounds(
            self.resetStreakEntry,
            settingsEntryX,
            settingsY + (settingsRowGap * 3),
            C.SETTINGS.VALUE_W,
            C.CTRL.FIELD_H
        )
    else
        local settingsRightX = self.startDatePickBtn:getRight() + settingsLabelW + C.LAYOUT.GAP_L
        setBounds(self.previewDaysEntry, settingsRightX, settingsY, C.SETTINGS.VALUE_W, C.CTRL.FIELD_H)
        setBounds(self.resetStreakEntry, settingsRightX, settingsY + settingsRowGap, C.SETTINGS.VALUE_W, C.CTRL.FIELD_H)
    end

    local bodyY = settingsY + C.SETTINGS.BOX_H + (narrowAdmin and C.ADMIN.BODY_GAP_NARROW or C.ADMIN.BODY_GAP)
    local adminListW =
        narrowAdmin and C.ADMIN.LIST_W_NARROW or (compactAdmin and C.ADMIN.LIST_W_COMPACT or C.ADMIN.LIST_W)
    local adminGap = narrowAdmin and C.LAYOUT.GAP_M or (compactAdmin and C.LAYOUT.GAP_L or C.ADMIN.SECTION_GAP)
    local modeBtnW = math.floor((adminListW - C.LAYOUT.GAP) / 2)
    setBounds(self.adminDailyModeBtn, C.LAYOUT.PAD, bodyY, modeBtnW, C.CTRL.BUTTON_H)
    setBounds(self.adminStreakModeBtn, self.adminDailyModeBtn:getRight() + C.LAYOUT.GAP, bodyY, modeBtnW, C.CTRL
        .BUTTON_H)

    local editorX = C.LAYOUT.PAD + adminListW + adminGap
    local editorW = width - editorX - C.LAYOUT.PAD
    local minEditorW = narrowAdmin and C.ADMIN.EDITOR_MIN_W_NARROW or C.ADMIN.EDITOR_MIN_W
    if editorW < minEditorW then
        editorW = minEditorW
    end
    local listTop = bodyY + C.CTRL.BUTTON_H + C.PLAYER.LIST_TITLE_GAP + C.LAYOUT.GAP_S
    local buttonY = statusTop - C.CTRL.BUTTON_H
    local listH = math.max(120, buttonY - listTop - C.LAYOUT.GAP)
    self._adminSectionLabelY = listTop - FONT_HGT_SMALL - C.ADMIN.SECTION_TITLE_GAP

    setBounds(self.adminRewardsList, C.LAYOUT.PAD, listTop, adminListW, listH)
    local listButtonW = math.floor((adminListW - C.LAYOUT.GAP) / 2)
    setBounds(self.addRewardBtn, C.LAYOUT.PAD, buttonY, listButtonW, C.CTRL.BUTTON_H)
    setBounds(self.deleteRewardBtn, self.addRewardBtn:getRight() + C.LAYOUT.GAP, buttonY, listButtonW, C.CTRL.BUTTON_H)

    local topLabelSpace = FONT_HGT_SMALL + C.ADMIN.SECTION_TITLE_GAP
    local editorY = listTop + topLabelSpace
    local idW = narrowAdmin and 80 or (compactAdmin and 100 or 130)
    local dayW = narrowAdmin and 55 or (compactAdmin and 60 or 70)
    local dayX = editorX + idW + C.LAYOUT.GAP_M + C.ICON.TEXTURE_PAD
    local titleX = dayX + dayW + C.LAYOUT.GAP_M + C.ICON.TEXTURE_PAD
    local repeatW = self.adminMode == "streak" and (narrowAdmin and 100 or 115) or 0
    local titleW = editorX + editorW - titleX - (repeatW > 0 and (repeatW + C.LAYOUT.GAP) or 0)
    setBounds(self.rewardIdEntry, editorX, editorY, idW, C.CTRL.FIELD_H)
    setBounds(self.rewardDayEntry, dayX, editorY, dayW, C.CTRL.FIELD_H)
    setBounds(self.rewardTitleEntry, titleX, editorY, math.max(110, titleW), C.CTRL.FIELD_H)

    local editorGap = compactEditor and C.LAYOUT.GAP_S or C.LAYOUT.GAP_M
    local cursorY = editorY + C.CTRL.FIELD_H + editorGap
    if self.adminMode == "streak" then
        setBounds(self.rewardRepeatTickBox, self.rewardTitleEntry:getRight() + C.LAYOUT.GAP, editorY, repeatW,
            C.CTRL.FIELD_H)
    else
        setBounds(self.rewardRepeatTickBox, editorX, cursorY, math.min(115, editorW), C.CTRL.FIELD_H)
    end

    local descriptionH = compactEditor and 40 or 50
    local descriptionY = cursorY + topLabelSpace
    setBounds(self.rewardDescriptionEntry, editorX, descriptionY, editorW, descriptionH)

    local sectionGap = compactEditor and C.LAYOUT.GAP or C.LAYOUT.GAP_M
    local sectionTitleH = FONT_HGT_MEDIUM + C.LIST.ICON_TEXT_GAP
    local fieldLabelH = FONT_HGT_SMALL + C.LABEL.OFFSET_Y
    local controlGap = compactEditor and C.LAYOUT.GAP_S or 6
    local listGap = C.LIST.ICON_TEXT_GAP
    local rewardSectionsY = self.rewardDescriptionEntry:getBottom() + sectionGap
    local sectionGapX = C.ADMIN.SECTION_GAP - 2
    local sectionW = math.floor((editorW - sectionGapX) / 2)
    local topListMinH = compactEditor and 45 or 55
    local traitListMinH = compactEditor and 35 or 45
    local customMinH = compactEditor and 55 or 65
    local topListFloorH = compactEditor and 30 or 40
    local traitListFloorH = compactEditor and 25 or 35
    local customFloorH = compactEditor and 40 or 50
    local sharedListChromeH = sectionTitleH + fieldLabelH + C.CTRL.FIELD_H + listGap
    local topSectionMinH = sharedListChromeH + topListMinH
    local bottomSectionMinH = math.max(sharedListChromeH + traitListMinH, sectionTitleH + customMinH)
    local availableSectionH = math.max(sectionGap + 2, buttonY - rewardSectionsY - C.LAYOUT.GAP)
    local requiredSectionH = topSectionMinH + bottomSectionMinH + sectionGap
    local topSectionH
    local bottomSectionH
    if availableSectionH >= requiredSectionH then
        local extraSectionH = availableSectionH - requiredSectionH
        topSectionH = topSectionMinH + math.floor(extraSectionH * 0.52)
        bottomSectionH = availableSectionH - topSectionH - sectionGap
    else
        local availableContentH = math.max(2, availableSectionH - sectionGap)
        local requiredContentH = topSectionMinH + bottomSectionMinH
        topSectionH = math.floor(availableContentH * (topSectionMinH / requiredContentH))
        bottomSectionH = availableSectionH - topSectionH - sectionGap

        local topSectionFloorH = sharedListChromeH + topListFloorH
        local bottomSectionFloorH = math.max(sharedListChromeH + traitListFloorH, sectionTitleH + customFloorH)
        if topSectionH < topSectionFloorH then
            topSectionH = topSectionFloorH
            bottomSectionH = availableSectionH - topSectionH - sectionGap
        end
        if bottomSectionH < bottomSectionFloorH then
            bottomSectionH = bottomSectionFloorH
            topSectionH = availableSectionH - bottomSectionH - sectionGap
        end
    end
    local leftSectionX = editorX
    local rightSectionX = editorX + sectionW + sectionGapX
    local bottomSectionY = rewardSectionsY + topSectionH + sectionGap

    self._adminRewardSections = {
        items = { x = leftSectionX, y = rewardSectionsY, width = sectionW },
        xp = { x = rightSectionX, y = rewardSectionsY, width = sectionW },
        traits = { x = leftSectionX, y = bottomSectionY, width = sectionW },
        custom = { x = rightSectionX, y = bottomSectionY, width = sectionW }
    }

    local countW = compactEditor and 45 or 50
    local amountW = compactEditor and 55 or 60
    local addW = compactEditor and 45 or 50
    local removeW = compactEditor and 55 or 60

    local itemLabelY = rewardSectionsY + sectionTitleH
    local itemRowY = itemLabelY + fieldLabelH
    local itemListY = itemRowY + C.CTRL.FIELD_H + listGap
    local itemTypeW = math.max(90, sectionW - countW - addW - removeW - (controlGap * 3))
    setBounds(self.rewardItemTypeEntry, leftSectionX, itemRowY, itemTypeW, C.CTRL.FIELD_H)
    setBounds(self.rewardItemCountEntry, self.rewardItemTypeEntry:getRight() + controlGap, itemRowY, countW,
        C.CTRL.FIELD_H)
    setBounds(self.addRewardItemBtn, self.rewardItemCountEntry:getRight() + controlGap, itemRowY, addW, C.CTRL.BUTTON_H)
    setBounds(self.removeRewardItemBtn, self.addRewardItemBtn:getRight() + controlGap, itemRowY, removeW, C.CTRL
        .BUTTON_H)
    setBounds(
        self.rewardItemList,
        leftSectionX,
        itemListY,
        sectionW,
        math.max(topListFloorH, (rewardSectionsY + topSectionH) - itemListY)
    )

    local xpLabelY = rewardSectionsY + sectionTitleH
    local xpRowY = xpLabelY + fieldLabelH
    local xpListY = xpRowY + C.CTRL.FIELD_H + listGap
    local skillW = math.max(90, sectionW - amountW - addW - removeW - (controlGap * 3))
    setBounds(self.rewardXpSkillCombo, rightSectionX, xpRowY, skillW, C.CTRL.FIELD_H)
    setBounds(self.rewardXpAmountEntry, self.rewardXpSkillCombo:getRight() + controlGap, xpRowY, amountW, C.CTRL.FIELD_H)
    setBounds(self.addRewardXpBtn, self.rewardXpAmountEntry:getRight() + controlGap, xpRowY, addW, C.CTRL.BUTTON_H)
    setBounds(self.removeRewardXpBtn, self.addRewardXpBtn:getRight() + controlGap, xpRowY, removeW, C.CTRL.BUTTON_H)
    setBounds(
        self.rewardXpList,
        rightSectionX,
        xpListY,
        sectionW,
        math.max(topListFloorH, (rewardSectionsY + topSectionH) - xpListY)
    )

    local traitLabelY = bottomSectionY + sectionTitleH
    local traitRowY = traitLabelY + fieldLabelH
    local traitListY = traitRowY + C.CTRL.FIELD_H + listGap
    local traitComboW = math.max(120, sectionW - addW - removeW - (controlGap * 2))
    setBounds(self.rewardTraitCombo, leftSectionX, traitRowY, traitComboW, C.CTRL.FIELD_H)
    setBounds(self.addRewardTraitBtn, self.rewardTraitCombo:getRight() + controlGap, traitRowY, addW, C.CTRL.BUTTON_H)
    setBounds(self.removeRewardTraitBtn, self.addRewardTraitBtn:getRight() + controlGap, traitRowY, removeW,
        C.CTRL.BUTTON_H)
    setBounds(
        self.rewardTraitList,
        leftSectionX,
        traitListY,
        sectionW,
        math.max(traitListFloorH, (bottomSectionY + bottomSectionH) - traitListY)
    )

    local customEntryY = bottomSectionY + sectionTitleH
    setBounds(
        self.rewardCustomEntry,
        rightSectionX,
        customEntryY,
        sectionW,
        math.max(customFloorH, bottomSectionH - sectionTitleH)
    )

    local editorButtonW = math.floor((editorW - (C.LAYOUT.GAP * 4)) / 5)
    setBounds(self.applyRewardBtn, editorX, buttonY, editorButtonW, C.CTRL.BUTTON_H)
    setBounds(self.saveConfigBtn, self.applyRewardBtn:getRight() + C.LAYOUT.GAP, buttonY, editorButtonW, C.CTRL.BUTTON_H)
    setBounds(self.resetConfigBtn, self.saveConfigBtn:getRight() + C.LAYOUT.GAP, buttonY, editorButtonW, C.CTRL.BUTTON_H)
    setBounds(self.importConfigBtn, self.resetConfigBtn:getRight() + C.LAYOUT.GAP, buttonY, editorButtonW,
        C.CTRL.BUTTON_H)
    setBounds(self.exportConfigBtn, self.importConfigBtn:getRight() + C.LAYOUT.GAP, buttonY, editorButtonW,
        C.CTRL.BUTTON_H)
end

function DailyRewardsPanel:isAdmin()
    if self.snapshot and self.snapshot.isAdmin ~= nil then
        return self.snapshot.isAdmin == true
    end
    return Shared.PlayerHasAdminAccess(self.playerObj)
end

function DailyRewardsPanel:setStatus(message, level)
    self.statusMessage = tostring(message or "")
    self.statusLevel = level or "info"
end

function DailyRewardsPanel:onSnapshotReceived(snapshot)
    self.snapshot = snapshot or {}
    if self.snapshot.message and self.snapshot.message ~= "" then
        self:setStatus(self.snapshot.message, self.snapshot.level or "info")
    else
        self:setStatus(getText("IGUI_DR_StatusReady"), "info")
    end
    self:populateFromSnapshot()
    self:updateModeVisibility()
end

function DailyRewardsPanel:populateFromSnapshot()
    if not self.dailyGrid then
        return
    end

    self:populateDailyGrid()
    self:populateStreakList()
    self:populateAdminView()
    self:updateButtonStates()
end

function DailyRewardsPanel:populateDailyGrid()
    self.dailyGrid:clear()
    local rows = self.snapshot.dailyRows or {}
    local firstClaimableKey = nil
    local selectedKeyExists = false

    for i = 1, #rows do
        local row = rows[i]
        if row.dateKey == self.selectedDailyKey then
            selectedKeyExists = true
        end
        if not firstClaimableKey and row.claimable then
            firstClaimableKey = row.dateKey
        end
    end

    if not selectedKeyExists then
        self.selectedDailyKey = firstClaimableKey or (rows[#rows] and rows[#rows].dateKey) or nil
    end

    local selectedGridRow = 1
    local groupIndex = 1
    local columns = self.dailyGridColumns or C.GRID.COLUMNS
    self.dailyGrid.dailyRewardColumns = columns
    for i = 1, #rows, columns do
        local group = { rows = {} }
        for j = i, math.min(i + columns - 1, #rows) do
            local row = rows[j]
            group.rows[#group.rows + 1] = row
            if row.dateKey == self.selectedDailyKey then
                selectedGridRow = groupIndex
            end
        end
        self.dailyGrid:addItem(getText("Tooltip_DR_Week") .. " " .. tostring(groupIndex), group)
        groupIndex = groupIndex + 1
    end
    self.dailyGrid.selected = selectedGridRow
end

function DailyRewardsPanel:populateStreakList()
    self.streakList:clear()
    local rows = self.snapshot.streakRows or {}
    local selectedIndex = 0

    for i = 1, #rows do
        local row = rows[i]
        self.streakList:addItem(row.streak and row.streak.title or row.streakId, row)
        if row.claimKey == self.selectedStreakKey then
            selectedIndex = i
        end
    end

    if selectedIndex == 0 and #rows > 0 then
        selectedIndex = 1
    end
    self.streakList.selected = selectedIndex
    if selectedIndex > 0 and self.streakList.items[selectedIndex] then
        self.selectedStreakKey = self.streakList.items[selectedIndex].item.claimKey
    end
end

function DailyRewardsPanel:populateAdminView()
    if not self.adminRewardsList then
        return
    end

    if self:isAdmin() and (not self.adminDirty or not self.adminConfig) and self.snapshot.config then
        self:loadAdminConfig(self.snapshot.config)
    elseif self:isAdmin() then
        self:populateAdminRewardsList()
        self:loadSelectedRewardIntoEditor()
    end
end

function DailyRewardsPanel:loadAdminConfig(config)
    self.adminConfig = Shared.NormalizeConfig(config or Shared.GetDefaultConfig())
    self.adminDirty = false
    self:updateSettingsFields()
    self:populateAdminRewardsList()
    self:loadSelectedRewardIntoEditor()
end

function DailyRewardsPanel:ensureAdminConfig()
    if not self.adminConfig then
        self.adminConfig = Shared.NormalizeConfig(self.snapshot.config or Shared.GetDefaultConfig())
    end
    return self.adminConfig
end

function DailyRewardsPanel:updateSettingsFields()
    if not self.settingsTickBox then
        return
    end

    local config = self:ensureAdminConfig()
    self.settingsTickBox:setSelected(1, config.enabled ~= false)
    self.settingsTickBox:setSelected(2, config.allowMissedClaims ~= false)
    self.settingsTickBox:setSelected(3, config.repeatRewards ~= false)
    setEntryText(self.startDateEntry, formatDateKey(config.startDate, "DMY"))
    setEntryText(self.maxClaimableDaysEntry, config.maxClaimableDays or 0)
    setEntryText(self.previewDaysEntry, config.previewDays or 0)
    setEntryText(self.resetStreakEntry, config.resetStreakAfterMissedDays or 0)
end

function DailyRewardsPanel:getAdminRewards()
    local config = self:ensureAdminConfig()
    if self.adminMode == "streak" then
        return config.streakRewards
    end
    return config.dailyRewards
end

function DailyRewardsPanel:getAdminSelectedReward()
    local rewards = self:getAdminRewards()
    local index = math.floor(tonumber(self.adminSelectedIndex) or 0)
    if index > 0 and rewards[index] then
        return rewards[index]
    end
    return nil
end

function DailyRewardsPanel:populateRewardSkillCombo()
    if not self.rewardXpSkillCombo then
        return
    end

    local selectedType = self.rewardXpSkillCombo:getOptionData(self.rewardXpSkillCombo.selected)
    self.rewardXpSkillCombo:clear()
    local options = getRewardSkillOptions()
    for i = 1, #options do
        self.rewardXpSkillCombo:addOptionWithData(options[i].text, options[i].type)
    end
    self.rewardXpSkillCombo.selected = 0
    if selectedType then
        self.rewardXpSkillCombo:selectData(selectedType)
    end
end

function DailyRewardsPanel:populateRewardTraitCombo()
    if not self.rewardTraitCombo then
        return
    end

    local selectedType = self.rewardTraitCombo:getOptionData(self.rewardTraitCombo.selected)
    self.rewardTraitCombo:clear()
    local tooltipMap = {}
    local options = getRewardTraitOptions()
    for i = 1, #options do
        self.rewardTraitCombo:addOptionWithData(options[i].text, options[i].type)
        tooltipMap[options[i].text] = options[i].description
    end
    self.rewardTraitCombo:setToolTipMap(tooltipMap)
    self.rewardTraitCombo.selected = 0
    if selectedType then
        self.rewardTraitCombo:selectData(selectedType)
    end
end

function DailyRewardsPanel:clearRewardEditorData()
    self.rewardItemsData = {}
    self.rewardXpData = {}
    self.rewardTraitsData = {}
    self.selectedRewardItemIndex = 0
    self.selectedRewardXpIndex = 0
    self.selectedRewardTraitIndex = 0
    self:refreshRewardEditorLists()
end

function DailyRewardsPanel:refreshRewardItemList()
    if not self.rewardItemList then
        return
    end

    self.rewardItemList:clear()
    for i = 1, #self.rewardItemsData do
        local item = self.rewardItemsData[i]
        local row = self.rewardItemList:addItem(getItemDisplayName(item.type), item)
        row.tooltip =
            string.format("%dx %s\n%s", item.count or 1, getItemDisplayName(item.type), tostring(item.type or ""))
    end

    if #self.rewardItemsData == 0 then
        self.selectedRewardItemIndex = 0
    else
        self.selectedRewardItemIndex =
            math.max(
                1,
                math.min(self.selectedRewardItemIndex > 0 and self.selectedRewardItemIndex or 1, #self.rewardItemsData)
            )
    end
    self.rewardItemList.selected = self.selectedRewardItemIndex
end

function DailyRewardsPanel:refreshRewardXpList()
    if not self.rewardXpList then
        return
    end

    self.rewardXpList:clear()
    for i = 1, #self.rewardXpData do
        local xp = self.rewardXpData[i]
        local row = self.rewardXpList:addItem(getSkillDisplayName(xp.perk), xp)
        row.tooltip = string.format("%s XP +%s", getSkillDisplayName(xp.perk), tostring(xp.amount or 0))
    end

    if #self.rewardXpData == 0 then
        self.selectedRewardXpIndex = 0
    else
        self.selectedRewardXpIndex =
            math.max(
                1,
                math.min(self.selectedRewardXpIndex > 0 and self.selectedRewardXpIndex or 1, #self.rewardXpData)
            )
    end
    self.rewardXpList.selected = self.selectedRewardXpIndex
end

function DailyRewardsPanel:refreshRewardTraitList()
    if not self.rewardTraitList then
        return
    end

    self.rewardTraitList:clear()
    for i = 1, #self.rewardTraitsData do
        local trait = self.rewardTraitsData[i]
        local row = self.rewardTraitList:addItem(getTraitLabel(trait.type), trait)
        row.tooltip = getTraitTooltip(trait.type)
    end

    if #self.rewardTraitsData == 0 then
        self.selectedRewardTraitIndex = 0
    else
        self.selectedRewardTraitIndex =
            math.max(
                1,
                math.min(self.selectedRewardTraitIndex > 0 and self.selectedRewardTraitIndex or 1, #self
                    .rewardTraitsData)
            )
    end
    self.rewardTraitList.selected = self.selectedRewardTraitIndex
end

function DailyRewardsPanel:refreshRewardEditorLists()
    self:refreshRewardItemList()
    self:refreshRewardXpList()
    self:refreshRewardTraitList()
end

function DailyRewardsPanel:addRewardItem()
    local itemType = trim(getEntryText(self.rewardItemTypeEntry))
    if itemType == "" then
        self:setStatus(getText("IGUI_DR_StatusRewardItemRequired"), "warning")
        return
    end

    local scriptItem = getItemScript(itemType)
    if not scriptItem then
        self:setStatus(getText("IGUI_DR_StatusRewardItemInvalid") .. " " .. itemType, "error")
        return
    end

    local count = math.floor(parseNumber(getEntryText(self.rewardItemCountEntry), 1, 1, 999))
    for i = 1, #self.rewardItemsData do
        if self.rewardItemsData[i].type == itemType then
            self.rewardItemsData[i].count =
                math.min(999, math.floor(tonumber(self.rewardItemsData[i].count) or 1) + count)
            self.selectedRewardItemIndex = i
            self.adminDirty = true
            self:refreshRewardItemList()
            self:updateButtonStates()
            setEntryText(self.rewardItemTypeEntry, "")
            setEntryText(self.rewardItemCountEntry, "1")
            return
        end
    end

    self.rewardItemsData[#self.rewardItemsData + 1] = {
        type = itemType,
        count = count
    }
    self.selectedRewardItemIndex = #self.rewardItemsData
    self.adminDirty = true
    self:refreshRewardItemList()
    self:updateButtonStates()
    setEntryText(self.rewardItemTypeEntry, "")
    setEntryText(self.rewardItemCountEntry, "1")
end

function DailyRewardsPanel:removeSelectedRewardItem()
    if self.selectedRewardItemIndex < 1 or self.selectedRewardItemIndex > #self.rewardItemsData then
        return
    end
    table.remove(self.rewardItemsData, self.selectedRewardItemIndex)
    if self.selectedRewardItemIndex > #self.rewardItemsData then
        self.selectedRewardItemIndex = #self.rewardItemsData
    end
    self.adminDirty = true
    self:refreshRewardItemList()
    self:updateButtonStates()
end

function DailyRewardsPanel:addRewardXp()
    local perkType =
        self.rewardXpSkillCombo and self.rewardXpSkillCombo:getOptionData(self.rewardXpSkillCombo.selected) or nil
    if not perkType then
        self:setStatus(getText("IGUI_DR_StatusRewardSkillRequired"), "warning")
        return
    end

    local amount = math.floor(parseNumber(getEntryText(self.rewardXpAmountEntry), 25, 1, 100000))
    if amount <= 0 then
        self:setStatus(getText("IGUI_DR_StatusRewardAmountRequired"), "warning")
        return
    end

    for i = 1, #self.rewardXpData do
        if self.rewardXpData[i].perk == perkType then
            self.rewardXpData[i].amount = math.floor(tonumber(self.rewardXpData[i].amount) or 0) + amount
            self.selectedRewardXpIndex = i
            self.adminDirty = true
            self:refreshRewardXpList()
            self:updateButtonStates()
            setEntryText(self.rewardXpAmountEntry, "25")
            return
        end
    end

    self.rewardXpData[#self.rewardXpData + 1] = {
        perk = perkType,
        amount = amount
    }
    self.selectedRewardXpIndex = #self.rewardXpData
    self.adminDirty = true
    self:refreshRewardXpList()
    self:updateButtonStates()
    setEntryText(self.rewardXpAmountEntry, "25")
end

function DailyRewardsPanel:removeSelectedRewardXp()
    if self.selectedRewardXpIndex < 1 or self.selectedRewardXpIndex > #self.rewardXpData then
        return
    end
    table.remove(self.rewardXpData, self.selectedRewardXpIndex)
    if self.selectedRewardXpIndex > #self.rewardXpData then
        self.selectedRewardXpIndex = #self.rewardXpData
    end
    self.adminDirty = true
    self:refreshRewardXpList()
    self:updateButtonStates()
end

function DailyRewardsPanel:addRewardTrait()
    local traitType =
        self.rewardTraitCombo and self.rewardTraitCombo:getOptionData(self.rewardTraitCombo.selected) or nil
    if not traitType then
        self:setStatus(getText("IGUI_DR_StatusRewardTraitRequired"), "warning")
        return
    end

    local traitInfo = Shared.GetTraitInfo(traitType)
    if not traitInfo then
        self:setStatus(getText("IGUI_DR_StatusRewardTraitInvalid"), "error")
        return
    end

    local newTraitConflicts = Shared.GetTraitConflictTypes(traitType)
    for i = 1, #self.rewardTraitsData do
        local existingType = self.rewardTraitsData[i].type
        if existingType == traitType then
            self:setStatus(getText("IGUI_DR_StatusRewardTraitDuplicate"), "warning")
            return
        end

        for j = 1, #newTraitConflicts do
            if newTraitConflicts[j] == existingType then
                self:setStatus(
                    getText("IGUI_DR_StatusRewardTraitConflict") .. " " .. getTraitLabel(existingType),
                    "warning"
                )
                return
            end
        end

        local existingConflicts = Shared.GetTraitConflictTypes(existingType)
        for j = 1, #existingConflicts do
            if existingConflicts[j] == traitType then
                self:setStatus(
                    getText("IGUI_DR_StatusRewardTraitConflict") .. " " .. getTraitLabel(existingType),
                    "warning"
                )
                return
            end
        end
    end

    self.rewardTraitsData[#self.rewardTraitsData + 1] = {
        type = traitInfo.type
    }
    self.selectedRewardTraitIndex = #self.rewardTraitsData
    self.adminDirty = true
    self:refreshRewardTraitList()
    self:updateButtonStates()
end

function DailyRewardsPanel:removeSelectedRewardTrait()
    if self.selectedRewardTraitIndex < 1 or self.selectedRewardTraitIndex > #self.rewardTraitsData then
        return
    end
    table.remove(self.rewardTraitsData, self.selectedRewardTraitIndex)
    if self.selectedRewardTraitIndex > #self.rewardTraitsData then
        self.selectedRewardTraitIndex = #self.rewardTraitsData
    end
    self.adminDirty = true
    self:refreshRewardTraitList()
    self:updateButtonStates()
end

function DailyRewardsPanel:populateAdminRewardsList()
    if not self.adminRewardsList then
        return
    end

    local rewards = self:getAdminRewards()
    self.adminRewardsList:clear()
    for i = 1, #rewards do
        self.adminRewardsList:addItem(
            tostring(rewards[i].title or rewards[i].id or i),
            {
                index = i,
                mode = self.adminMode,
                entry = rewards[i]
            }
        )
    end

    if #rewards == 0 then
        self.adminSelectedIndex = 0
    elseif self.adminSelectedIndex < 1 then
        self.adminSelectedIndex = 1
    elseif self.adminSelectedIndex > #rewards then
        self.adminSelectedIndex = #rewards
    end

    self.adminRewardsList.selected = self.adminSelectedIndex
end

function DailyRewardsPanel:loadSelectedRewardIntoEditor()
    if not self.rewardIdEntry then
        return
    end

    local entry = self:getAdminSelectedReward()
    if not entry then
        setEntryText(self.rewardIdEntry, "")
        setEntryText(self.rewardDayEntry, "")
        setEntryText(self.rewardTitleEntry, "")
        setEntryText(self.rewardDescriptionEntry, "")
        self:clearRewardEditorData()
        setEntryText(self.rewardItemTypeEntry, "")
        setEntryText(self.rewardItemCountEntry, "1")
        if self.rewardXpSkillCombo then
            self.rewardXpSkillCombo.selected = 0
        end
        setEntryText(self.rewardXpAmountEntry, "25")
        if self.rewardTraitCombo then
            self.rewardTraitCombo.selected = 0
        end
        setEntryText(self.rewardCustomEntry, "")
        if self.rewardRepeatTickBox then
            self.rewardRepeatTickBox:setSelected(1, false)
        end
        return
    end

    setEntryText(self.rewardIdEntry, entry.id or "")
    if self.adminMode == "streak" then
        setEntryText(self.rewardDayEntry, entry.days or self.adminSelectedIndex)
        self.rewardRepeatTickBox:setSelected(1, entry.repeatable == true)
    else
        setEntryText(self.rewardDayEntry, entry.day or self.adminSelectedIndex)
        self.rewardRepeatTickBox:setSelected(1, false)
    end
    setEntryText(self.rewardTitleEntry, entry.title or "")
    setEntryText(self.rewardDescriptionEntry, entry.description or "")
    local rewards = Shared.NormalizeRewards(entry.rewards)
    self.rewardItemsData = copyValue(rewards.items)
    self.rewardXpData = copyValue(rewards.xp)
    self.rewardTraitsData = copyValue(rewards.traits)
    self.selectedRewardItemIndex = 0
    self.selectedRewardXpIndex = 0
    self.selectedRewardTraitIndex = 0
    self:refreshRewardEditorLists()
    setEntryText(self.rewardItemTypeEntry, "")
    setEntryText(self.rewardItemCountEntry, "1")
    if self.rewardXpSkillCombo then
        self.rewardXpSkillCombo.selected = 0
    end
    setEntryText(self.rewardXpAmountEntry, "25")
    if self.rewardTraitCombo then
        self.rewardTraitCombo.selected = 0
    end
    setEntryText(self.rewardCustomEntry, formatCustom(entry.rewards))
end

function DailyRewardsPanel:saveAdminEditorToSelected()
    if not self.rewardIdEntry then
        return
    end

    local entry = self:getAdminSelectedReward()
    if not entry then
        return
    end

    local data =
        buildRewardConfig(
            getEntryText(self.rewardTitleEntry),
            getEntryText(self.rewardDescriptionEntry),
            {
                items = self.rewardItemsData,
                xp = self.rewardXpData,
                traits = self.rewardTraitsData,
                custom = getEntryText(self.rewardCustomEntry)
            }
        )

    local id = trim(getEntryText(self.rewardIdEntry))
    local number = math.floor(parseNumber(getEntryText(self.rewardDayEntry), self.adminSelectedIndex, 1, 3650))
    entry.id = id
    entry.title = data.title
    entry.description = data.description
    entry.rewards = data.rewards

    if self.adminMode == "streak" then
        entry.days = number
        entry.repeatable = self.rewardRepeatTickBox and self.rewardRepeatTickBox:isSelected(1) == true
        if entry.id == "" then
            entry.id = "streak_" .. tostring(entry.days)
        end
        if entry.title == "" then
            entry.title = tostring(entry.days) .. " " .. getText("IGUI_DR_DayStreak")
        end
    else
        entry.day = number
        if entry.id == "" then
            entry.id = "day_" .. tostring(entry.day)
        end
        if entry.title == "" then
            entry.title = getText("Tooltip_DR_Day") .. " " .. tostring(entry.day)
        end
    end

    self.adminDirty = true
end

function DailyRewardsPanel:buildAdminConfigFromFields()
    local config = self:ensureAdminConfig()
    self:saveAdminEditorToSelected()
    config.enabled = self.settingsTickBox:isSelected(1) == true
    config.allowMissedClaims = self.settingsTickBox:isSelected(2) == true
    config.repeatRewards = self.settingsTickBox:isSelected(3) == true
    config.startDate = Shared.NormalizeDateKey(getEntryText(self.startDateEntry))
    config.maxClaimableDays = math.floor(parseNumber(getEntryText(self.maxClaimableDaysEntry), 0, 0, 3650))
    config.previewDays = math.floor(parseNumber(getEntryText(self.previewDaysEntry), 0, 0, 3650))
    config.resetStreakAfterMissedDays = math.floor(parseNumber(getEntryText(self.resetStreakEntry), 1, 0, 3650))
    return Shared.NormalizeConfig(config)
end

function DailyRewardsPanel:addAdminReward()
    self:saveAdminEditorToSelected()
    local rewards = self:getAdminRewards()
    if self.adminMode == "streak" then
        local maxDays = 0
        for i = 1, #rewards do
            maxDays = math.max(maxDays, tonumber(rewards[i].days) or 0)
        end
        local days = math.max(1, maxDays + 1)
        rewards[#rewards + 1] = {
            id = "streak_" .. tostring(days),
            days = days,
            title = tostring(days) .. " " .. getText("IGUI_DR_DayStreak"),
            description = "",
            repeatable = false,
            rewards = { items = {}, xp = {}, traits = {}, custom = {} }
        }
    else
        local day = #rewards + 1
        rewards[#rewards + 1] = {
            id = "day_" .. tostring(day),
            day = day,
            title = "Day " .. tostring(day),
            description = "",
            rewards = { items = {}, xp = {}, traits = {}, custom = {} }
        }
    end

    self.adminSelectedIndex = #rewards
    self.adminDirty = true
    self:populateAdminRewardsList()
    self:loadSelectedRewardIntoEditor()
    self:updateButtonStates()
end

function DailyRewardsPanel:deleteAdminReward()
    local rewards = self:getAdminRewards()
    if self.adminSelectedIndex < 1 or self.adminSelectedIndex > #rewards then
        return
    end
    table.remove(rewards, self.adminSelectedIndex)
    if self.adminMode == "daily" then
        for i = 1, #rewards do
            rewards[i].day = i
        end
    end
    self.adminSelectedIndex = math.min(self.adminSelectedIndex, #rewards)
    self.adminDirty = true
    self:populateAdminRewardsList()
    self:loadSelectedRewardIntoEditor()
    self:updateButtonStates()
end

function DailyRewardsPanel:setAdminMode(mode)
    if mode ~= "daily" and mode ~= "streak" then
        return
    end
    self:saveAdminEditorToSelected()
    self.adminMode = mode
    self.adminSelectedIndex = 1
    self:populateAdminRewardsList()
    self:loadSelectedRewardIntoEditor()
    self:updateModeVisibility()
    self:layoutChildren(true)
end

function DailyRewardsPanel:openStartDatePicker()
    if self.startDatePicker then
        self.startDatePicker:close()
        self.startDatePicker = nil
    end

    local initial =
        dateKeyToDateTable(getEntryText(self.startDateEntry)) or
        dateKeyToDateTable(self.snapshot and self.snapshot.todayKey) or
        dateKeyToDateTable(Shared.GetTodayKey())

    local picker =
        DateTimeSelector:new(
            0,
            0,
            0,
            0,
            false,
            initial,
            {
                showTime = false,
                showTimezoneInfo = false
            }
        )
    picker:setOnDateTimeSelected(self, DailyRewardsPanel.onStartDatePicked)
    picker:initialise()
    picker:centerOnScreen()
    picker:addToUIManager()
    picker:bringToTop()
    self.startDatePicker = picker
end

function DailyRewardsPanel:onStartDatePicked(date, cancelled)
    self.startDatePicker = nil
    if cancelled or not date then
        return
    end

    local dateKey = dateTableToDateKey(date)
    if dateKey then
        setEntryText(self.startDateEntry, formatDateKey(dateKey, "DMY"))
        self.adminDirty = true
    end
end

function DailyRewardsPanel:updateModeVisibility()
    local isAdmin = self:isAdmin()
    self.adminTabBtn:setVisible(isAdmin)

    if not isAdmin and self.activeTab == "admin" then
        self.activeTab = "player"
    end

    local showPlayer = self.activeTab == "player"
    local showAdmin = self.activeTab == "admin" and isAdmin

    for i = 1, #(self.playerControls or {}) do
        setVisible(self.playerControls[i], showPlayer)
    end
    for i = 1, #(self.adminControls or {}) do
        setVisible(self.adminControls[i], showAdmin)
    end

    setVisible(self.rewardRepeatTickBox, showAdmin and self.adminMode == "streak")

    applyButtonStyle(self.playerTabBtn, showPlayer and "primary" or nil)
    applyButtonStyle(self.adminTabBtn, showAdmin and "primary" or nil)
    applyButtonStyle(self.adminDailyModeBtn, showAdmin and self.adminMode == "daily" and "primary" or nil)
    applyButtonStyle(self.adminStreakModeBtn, showAdmin and self.adminMode == "streak" and "primary" or nil)
end

function DailyRewardsPanel:getSelectedDailyRow()
    local rows = self.snapshot.dailyRows or {}
    for i = 1, #rows do
        if rows[i].dateKey == self.selectedDailyKey then
            return rows[i]
        end
    end
    return nil
end

function DailyRewardsPanel:getSelectedStreakRow()
    local index = self.streakList and self.streakList.selected or 0
    if index > 0 and self.streakList.items[index] then
        return self.streakList.items[index].item
    end
    return nil
end

function DailyRewardsPanel:updateButtonStates()
    if self.claimDailyBtn then
        local row = self:getSelectedDailyRow()
        self.claimDailyBtn.enable = row and row.claimable == true
    end

    if self.claimStreakBtn then
        local row = self:getSelectedStreakRow()
        self.claimStreakBtn.enable = row and row.claimable == true
    end

    if self.saveConfigBtn then
        self.saveConfigBtn.enable = self:isAdmin()
    end
    if self.resetConfigBtn then
        self.resetConfigBtn.enable = self:isAdmin()
    end
    if self.applyRewardBtn then
        self.applyRewardBtn.enable = self:isAdmin() and self:getAdminSelectedReward() ~= nil
    end
    if self.deleteRewardBtn then
        self.deleteRewardBtn.enable = self:isAdmin() and self:getAdminSelectedReward() ~= nil
    end
    if self.importConfigBtn then
        self.importConfigBtn.enable = self:isAdmin()
    end
    if self.exportConfigBtn then
        self.exportConfigBtn.enable = self:isAdmin()
    end
    local canEditReward = self:isAdmin() and self:getAdminSelectedReward() ~= nil
    if self.addRewardItemBtn then
        self.addRewardItemBtn.enable = canEditReward
    end
    if self.removeRewardItemBtn then
        self.removeRewardItemBtn.enable = canEditReward and self.selectedRewardItemIndex > 0
    end
    if self.addRewardXpBtn then
        self.addRewardXpBtn.enable = canEditReward
    end
    if self.removeRewardXpBtn then
        self.removeRewardXpBtn.enable = canEditReward and self.selectedRewardXpIndex > 0
    end
    if self.addRewardTraitBtn then
        self.addRewardTraitBtn.enable = canEditReward
    end
    if self.removeRewardTraitBtn then
        self.removeRewardTraitBtn.enable = canEditReward and self.selectedRewardTraitIndex > 0
    end
end

function DailyRewardsPanel.drawRewardItemListItem(list, y, item, alt)
    local row = item.item or {}
    local selected = list.selected == item.index
    local background = selected and C.COLORS.SELECTED or (alt and C.COLORS.ALT or C.COLORS.FIELD)
    local iconSize = math.min(C.LIST.ICON_SIZE, list.itemheight - C.LIST.ICON_TEXT_GAP)
    local iconY = y + math.floor((list.itemheight - iconSize) / 2)
    local textY = y + math.floor((list.itemheight - FONT_HGT_SMALL) / 2)
    local textX = C.LIST.ICON_INSET + iconSize + C.LIST.ICON_TEXT_GAP
    local contentRight = getListContentRight(list, C.LIST.ICON_INSET)
    local summaryText = "x" .. tostring(row.count or 1)
    local summaryWidth = measure(UIFont.Small, summaryText)
    local labelWidth = math.max(20, contentRight - textX - summaryWidth - C.LIST.TEXT_RIGHT_PAD)

    drawClippedListRow(
        list,
        y,
        list.itemheight,
        function()
            list:drawRect(
                0,
                y,
                list:getWidth(),
                list.itemheight - 1,
                background.a,
                background.r,
                background.g,
                background.b
            )
            drawRewardIconTile(
                list,
                {
                    type = "item",
                    texture = getItemTexture(row.type),
                    fallback = "IT"
                },
                C.LIST.ICON_PAD,
                iconY,
                iconSize
            )
            list:drawText(
                trimTextToWidth(UIFont.Small, getItemDisplayName(row.type), labelWidth),
                textX,
                textY,
                C.COLORS.TEXT.r,
                C.COLORS.TEXT.g,
                C.COLORS.TEXT.b,
                1,
                UIFont.Small
            )
            list:drawTextRight(
                summaryText,
                contentRight,
                textY,
                C.COLORS.MUTED.r,
                C.COLORS.MUTED.g,
                C.COLORS.MUTED.b,
                1,
                UIFont.Small
            )
        end
    )
    return y + list.itemheight
end

function DailyRewardsPanel.drawRewardXpListItem(list, y, item, alt)
    local row = item.item or {}
    local selected = list.selected == item.index
    local background = selected and C.COLORS.SELECTED or (alt and C.COLORS.ALT or C.COLORS.FIELD)
    local iconSize = math.min(C.LIST.ICON_SIZE, list.itemheight - C.LIST.ICON_TEXT_GAP)
    local iconY = y + math.floor((list.itemheight - iconSize) / 2)
    local textY = y + math.floor((list.itemheight - FONT_HGT_SMALL) / 2)
    local textX = C.LIST.ICON_INSET + iconSize + C.LIST.ICON_TEXT_GAP
    local contentRight = getListContentRight(list, C.LIST.ICON_INSET)
    local summaryText = "+" .. tostring(row.amount or 0) .. " XP"
    local summaryWidth = measure(UIFont.Small, summaryText)
    local labelWidth = math.max(20, contentRight - textX - summaryWidth - C.LIST.TEXT_RIGHT_PAD)

    drawClippedListRow(
        list,
        y,
        list.itemheight,
        function()
            list:drawRect(
                0,
                y,
                list:getWidth(),
                list.itemheight - 1,
                background.a,
                background.r,
                background.g,
                background.b
            )
            drawRewardIconTile(
                list,
                {
                    type = "xp",
                    texture = getSkillTexture(row.perk),
                    fallback = getSkillLabel(row.perk or "")
                },
                C.LIST.ICON_PAD,
                iconY,
                iconSize
            )
            list:drawText(
                trimTextToWidth(UIFont.Small, getSkillDisplayName(row.perk), labelWidth),
                textX,
                textY,
                C.COLORS.TEXT.r,
                C.COLORS.TEXT.g,
                C.COLORS.TEXT.b,
                1,
                UIFont.Small
            )
            list:drawTextRight(
                summaryText,
                contentRight,
                textY,
                C.COLORS.MUTED.r,
                C.COLORS.MUTED.g,
                C.COLORS.MUTED.b,
                1,
                UIFont.Small
            )
        end
    )
    return y + list.itemheight
end

function DailyRewardsPanel.drawRewardTraitListItem(list, y, item, alt)
    local row = item.item or {}
    local traitInfo = Shared.GetTraitInfo(row.type)
    local selected = list.selected == item.index
    local background = selected and C.COLORS.SELECTED or (alt and C.COLORS.ALT or C.COLORS.FIELD)
    local iconSize = math.min(C.LIST.ICON_SIZE, list.itemheight - C.LIST.ICON_TEXT_GAP)
    local iconY = y + math.floor((list.itemheight - iconSize) / 2)
    local textY = y + math.floor((list.itemheight - FONT_HGT_SMALL) / 2)
    local textX = C.LIST.ICON_INSET + iconSize + C.LIST.ICON_TEXT_GAP
    local contentRight = getListContentRight(list, C.LIST.ICON_INSET)
    local textColor = traitInfo and traitInfo.positive and C.COLORS.READY or C.COLORS.LOCKED

    drawClippedListRow(
        list,
        y,
        list.itemheight,
        function()
            list:drawRect(
                0,
                y,
                list:getWidth(),
                list.itemheight - 1,
                background.a,
                background.r,
                background.g,
                background.b
            )
            drawRewardIconTile(
                list,
                {
                    type = "trait",
                    positive = traitInfo and traitInfo.positive == true,
                    texture = getTraitTexture(row.type),
                    fallback = getTraitShortLabel(row.type)
                },
                C.LIST.ICON_PAD,
                iconY,
                iconSize
            )
            list:drawText(
                trimTextToWidth(UIFont.Small, getTraitLabel(row.type), math.max(20, contentRight - textX)),
                textX,
                textY,
                textColor.r,
                textColor.g,
                textColor.b,
                1,
                UIFont.Small
            )
        end
    )
    return y + list.itemheight
end

function DailyRewardsPanel.onRewardDataListMouseDown(list, x, y)
    local row = list:rowAt(x, y)
    if row < 1 or row > #list.items then
        return true
    end

    local panel = list.parentPanel
    list.selected = row
    if list.listKind == "item" then
        panel.selectedRewardItemIndex = row
        local reward = panel.rewardItemsData[row]
        if reward then
            setEntryText(panel.rewardItemTypeEntry, reward.type or "")
            setEntryText(panel.rewardItemCountEntry, tostring(reward.count or 1))
        end
    elseif list.listKind == "xp" then
        panel.selectedRewardXpIndex = row
        local reward = panel.rewardXpData[row]
        if reward then
            panel.rewardXpSkillCombo:selectData(reward.perk)
            setEntryText(panel.rewardXpAmountEntry, tostring(reward.amount or 25))
        end
    elseif list.listKind == "trait" then
        panel.selectedRewardTraitIndex = row
        local reward = panel.rewardTraitsData[row]
        if reward then
            panel.rewardTraitCombo:selectData(reward.type)
        end
    end
    panel:updateButtonStates()
    getSoundManager():playUISound("UISelectListItem")
    return true
end

function DailyRewardsPanel.onRewardComboChanged(target, combo)
end

drawRewardIconTile = function(list, icon, x, y, size)
    local T = Theme.colors
    local fill
    if icon.type == "xp" then
        fill = T.iconXp
    elseif icon.type == "trait" then
        fill = icon.positive and T.iconTrait or T.iconTraitNeg
    elseif icon.type == "custom" then
        fill = T.iconCustom
    else
        fill = T.iconItem
    end

    list:drawRect(x, y, size, size, fill.a, fill.r, fill.g, fill.b)
    list:drawRectBorder(x, y, size, size, 0.75, T.border.r, T.border.g, T.border.b)

    if icon.texture then
        list:drawTextureScaledAspect(
            icon.texture,
            x + C.ICON.TEXTURE_PAD,
            y + C.ICON.TEXTURE_PAD,
            size - (C.ICON.TEXTURE_PAD * 2),
            size - (C.ICON.TEXTURE_PAD * 2),
            1,
            1,
            1,
            1
        )
    else
        local label = icon.fallback or icon.label
        if label and label ~= "" then
            list:drawTextCentre(
                trimTextToWidth(UIFont.Small, tostring(label), size - (C.ICON.LABEL_PAD * 2)),
                x + (size / 2),
                y + math.floor((size - FONT_HGT_SMALL) / 2),
                1,
                1,
                1,
                1,
                UIFont.Small
            )
        elseif icon.type ~= "custom" then
            list:drawTextCentre(
                "?",
                x + (size / 2),
                y + math.floor((size - FONT_HGT_SMALL) / 2),
                1,
                1,
                1,
                1,
                UIFont.Small
            )
        end
    end

    if icon.label and icon.label ~= "" and icon.texture then
        local label = tostring(icon.label)
        local labelW = math.min(size - C.ICON.TEXTURE_PAD, measure(UIFont.Small, label) + C.ICON.LABEL_PAD)
        local ov = Theme.colors.badgeOverlay
        list:drawRect(
            x + size - labelW,
            y + size - FONT_HGT_SMALL - C.ICON.LABEL_PAD,
            labelW,
            FONT_HGT_SMALL + C.ICON.LABEL_PAD,
            ov.a, ov.r, ov.g, ov.b
        )
        list:drawTextRight(
            label,
            x + size - C.ICON.TEXTURE_PAD,
            y + size - FONT_HGT_SMALL - C.ICON.LABEL_TEXT_PAD,
            1,
            1,
            1,
            1,
            UIFont.Small
        )
    end
end

local function getDailyTileMetrics(list)
    local columns =
        list.dailyRewardColumns or (list.parentPanel and list.parentPanel.dailyGridColumns) or C.GRID.COLUMNS
    local gap = C.GRID.TILE_GAP
    local contentW = getListContentWidth(list, list.reserveScrollBarSpace == true)
    local tileW = calculateDailyTileWidth(contentW, columns)
    local tileH = list.itemheight - (gap * 2)
    return columns, gap, tileW, tileH
end

local function getDailyRowAtGridPosition(list, x, y)
    local gridRow = list:rowAt(x, y)
    if gridRow < 1 or gridRow > #list.items then
        return nil, gridRow
    end

    local group = list.items[gridRow].item
    local columns, gap, tileW, tileH = getDailyTileMetrics(list)
    local localY = y - list:topOfItem(gridRow)
    if localY < gap or localY > gap + tileH then
        return nil, gridRow
    end

    for i = 1, #group.rows do
        local tileX = gap + ((i - 1) * (tileW + gap))
        if x >= tileX and x <= tileX + tileW then
            return group.rows[i], gridRow
        end
    end

    return nil, gridRow
end

function DailyRewardsPanel.drawDailyGridRow(list, y, item, alt)
    local group = item.item
    local panel = list.parentPanel
    local columns, gap, tileW, tileH = getDailyTileMetrics(list)
    local tileY = y + gap

    for i = 1, #group.rows do
        local row                     = group.rows[i]
        local x                       = gap + ((i - 1) * (tileW + gap))
        local statusText, statusColor = getDailyStatus(row)
        local selected                = row.dateKey == panel.selectedDailyKey
        local T                       = Theme.colors
        local fill
        if row.claimed then
            fill = T.tileClaimed
        elseif row.claimable then
            fill = T.tileReady
        elseif row.future then
            fill = T.tileFuture
        else
            fill = T.tileLocked
        end

        list:drawRect(x, tileY, tileW, tileH, fill.a, fill.r, fill.g, fill.b)
        if selected then
            list:drawRect(
                x,
                tileY,
                tileW,
                tileH,
                C.COLORS.SELECTED.a,
                C.COLORS.SELECTED.r,
                C.COLORS.SELECTED.g,
                C.COLORS.SELECTED.b
            )
        end
        list:drawRectBorder(
            x,
            tileY,
            tileW,
            tileH,
            C.COLORS.BORDER.a,
            C.COLORS.BORDER.r,
            C.COLORS.BORDER.g,
            C.COLORS.BORDER.b
        )

        list:drawText(
            trimTextToWidth(UIFont.Small, "Day " .. tostring(row.dayNumber or "?"), tileW - C.TILE.TEXT_WIDTH_PAD),
            x + C.TILE.TEXT_PAD,
            tileY + C.TILE.TOP_PAD,
            C.COLORS.TEXT.r,
            C.COLORS.TEXT.g,
            C.COLORS.TEXT.b,
            1,
            UIFont.Small
        )
        local title = row.reward and row.reward.title or ""
        list:drawText(
            trimTextToWidth(UIFont.Small, title, tileW - C.TILE.TEXT_WIDTH_PAD),
            x + C.TILE.TEXT_PAD,
            tileY + C.TILE.TITLE_Y,
            C.COLORS.TEXT.r,
            C.COLORS.TEXT.g,
            C.COLORS.TEXT.b,
            1,
            UIFont.Small
        )
        local iconSize = math.max(22, math.min(30, math.floor((tileW - 22) / 3)))
        local maxIcons =
            math.max(2, math.min(4, math.floor((tileW - C.TILE.TEXT_WIDTH_PAD) / (iconSize + C.TILE.ICON_GAP))))
        local icons, remaining = getRewardPreviewIcons(row.reward and row.reward.rewards or nil, maxIcons)
        local iconY = tileY + C.TILE.ICON_Y
        local iconX = x + C.TILE.TEXT_PAD
        for iconIndex = 1, #icons do
            drawRewardIconTile(list, icons[iconIndex], iconX, iconY, iconSize)
            iconX = iconX + iconSize + C.TILE.ICON_GAP
        end
        if remaining and remaining > 0 then
            list:drawText(
                "+" .. tostring(remaining),
                iconX,
                iconY + math.floor((iconSize - FONT_HGT_SMALL) / 2),
                C.COLORS.MUTED.r,
                C.COLORS.MUTED.g,
                C.COLORS.MUTED.b,
                1,
                UIFont.Small
            )
        end
        local shortDate = formatDateKey(row.dateKey, "DMY")
        local footerW = tileW - C.TILE.TEXT_WIDTH_PAD
        if measure(UIFont.Small, shortDate) + measure(UIFont.Small, statusText) + 22 > footerW then
            local dateY = tileY + tileH - (FONT_HGT_SMALL * 2) - C.TILE.FOOTER_STACK_GAP
            local statusY = dateY + FONT_HGT_SMALL + 1
            list:drawText(
                trimTextToWidth(UIFont.Small, shortDate, footerW),
                x + C.TILE.TEXT_PAD,
                dateY,
                C.COLORS.MUTED.r,
                C.COLORS.MUTED.g,
                C.COLORS.MUTED.b,
                1,
                UIFont.Small
            )
            list:drawText(
                trimTextToWidth(UIFont.Small, statusText, footerW),
                x + C.TILE.TEXT_PAD,
                statusY,
                statusColor.r,
                statusColor.g,
                statusColor.b,
                1,
                UIFont.Small
            )
        else
            local footerY = tileY + tileH - FONT_HGT_SMALL - C.TILE.FOOTER_PAD
            list:drawText(
                trimTextToWidth(UIFont.Small, shortDate, math.floor(footerW * 0.58)),
                x + C.TILE.TEXT_PAD,
                footerY,
                C.COLORS.MUTED.r,
                C.COLORS.MUTED.g,
                C.COLORS.MUTED.b,
                1,
                UIFont.Small
            )
            list:drawTextRight(
                trimTextToWidth(UIFont.Small, statusText, math.floor(footerW * 0.40)),
                x + tileW - C.TILE.TEXT_PAD,
                footerY,
                statusColor.r,
                statusColor.g,
                statusColor.b,
                1,
                UIFont.Small
            )
        end
    end

    return y + list.itemheight
end

function DailyRewardsPanel.onDailyGridMouseDown(list, x, y)
    local dailyRow, gridRow = getDailyRowAtGridPosition(list, x, y)
    if not dailyRow then
        return true
    end

    list.selected = gridRow
    local panel = list.parentPanel
    panel.selectedDailyKey = dailyRow.dateKey
    panel:updateButtonStates()
    getSoundManager():playUISound("UISelectListItem")
    return true
end

function DailyRewardsPanel.onDailyGridMouseMove(list, dx, dy)
    ISScrollingListBox.onMouseMove(list, dx, dy)
    local dailyRow, gridRow = getDailyRowAtGridPosition(list, list:getMouseX(), list:getMouseY())
    if gridRow and list.items[gridRow] then
        list.items[gridRow].tooltip = buildDailyTooltip(dailyRow)
    end
end

function DailyRewardsPanel.drawStreakItem(list, y, item, alt)
    local row = item.item
    local selected = list.selected == item.index
    local background = selected and C.COLORS.SELECTED or (alt and C.COLORS.ALT or C.COLORS.FIELD)
    local statusText =
        row.claimed and getText("IGUI_DR_Claimed") or
        (row.claimable and getText("IGUI_DR_Ready") or
            tostring(row.progress or 0) .. "/" .. tostring(row.requiredDays or 0))
    local statusColor = row.claimed and C.COLORS.CLAIMED or (row.claimable and C.COLORS.READY or C.COLORS.LOCKED)
    local repeatText = row.streak and row.streak.repeatable and (" #" .. tostring(row.repeatIndex or 1)) or ""
    local contentW = getListContentWidth(list, false)

    list:drawRect(0, y, list:getWidth(), list.itemheight - 1, background.a, background.r, background.g, background.b)
    list:drawText(
        trimTextToWidth(
            UIFont.Small,
            tostring(row.streak and row.streak.title or row.streakId) .. repeatText,
            contentW - 120
        ),
        C.LIST.TEXT_PAD,
        y + C.DETAIL.TEXT_GAP,
        1,
        1,
        1,
        1,
        UIFont.Small
    )
    list:drawText(
        tostring(row.requiredDays or 0) .. " " .. getText("IGUI_DR_Days"),
        C.LIST.TEXT_PAD,
        y + 20,
        C.COLORS.MUTED.r,
        C.COLORS.MUTED.g,
        C.COLORS.MUTED.b,
        1,
        UIFont.Small
    )
    list:drawTextRight(
        trimTextToWidth(UIFont.Small, statusText, 92),
        contentW - C.LIST.TEXT_RIGHT_PAD,
        y + C.LAYOUT.GAP_M,
        statusColor.r,
        statusColor.g,
        statusColor.b,
        1,
        UIFont.Small
    )
    return y + list.itemheight
end

function DailyRewardsPanel.onStreakListMouseDown(list, x, y)
    local row = list:rowAt(x, y)
    if row < 1 or row > #list.items then
        return true
    end
    list.selected = row
    local panel = list.parentPanel
    panel.selectedStreakKey = list.items[row].item.claimKey
    panel:updateButtonStates()
    return true
end

function DailyRewardsPanel.drawAdminRewardItem(list, y, item, alt)
    local row = item.item
    local entry = row.entry or {}
    local selected = list.selected == item.index
    local background = selected and C.COLORS.SELECTED or (alt and C.COLORS.ALT or C.COLORS.FIELD)
    local numberText =
        row.mode == "streak" and (tostring(entry.days or "?") .. " " .. getText("IGUI_DR_Days")) or
        ("Day " .. tostring(entry.day or row.index))
    local summary = Shared.GetRewardSummary(entry.rewards)
    local contentW = getListContentWidth(list, false)

    list:drawRect(0, y, list:getWidth(), list.itemheight - 1, background.a, background.r, background.g, background.b)
    list:drawText(
        trimTextToWidth(UIFont.Small, numberText .. " - " .. tostring(entry.title or entry.id or ""), contentW - 16),
        8,
        y + 4,
        1,
        1,
        1,
        1,
        UIFont.Small
    )
    list:drawText(
        trimTextToWidth(UIFont.Small, summary, contentW - 16),
        8,
        y + 21,
        C.COLORS.MUTED.r,
        C.COLORS.MUTED.g,
        C.COLORS.MUTED.b,
        1,
        UIFont.Small
    )
    return y + list.itemheight
end

function DailyRewardsPanel.onAdminRewardsListMouseDown(list, x, y)
    local row = list:rowAt(x, y)
    if row < 1 or row > #list.items then
        return true
    end
    local panel = list.parentPanel
    panel:saveAdminEditorToSelected()
    list.selected = row
    panel.adminSelectedIndex = row
    panel:loadSelectedRewardIntoEditor()
    panel:updateButtonStates()
    return true
end

function DailyRewardsPanel.onSettingChanged(target, index, selected, arg1, arg2, tickBox)
    if target then
        target.adminDirty = true
    end
end

local function getConfigFilePath()
    return Core.getMyDocumentFolder() .. getFileSeparator() .. "Lua" .. getFileSeparator() .. DailyRewards.CONFIG_FILE
end

function DailyRewardsPanel:exportAdminConfig()
    self:saveAdminEditorToSelected()
    local config = Shared.NormalizeConfig(self.adminConfig or self.snapshot.config or Shared.GetDefaultConfig())
    local success =
        FileUtils.writeJson(DailyRewards.CONFIG_FILE, config, DailyRewards.FILE_MOD_ID, { createIfNull = true })
    local path = getConfigFilePath()
    if success then
        self:setStatus(getText("IGUI_DR_StatusConfigExported") .. " " .. path, "info")
        if isDesktopOpenSupported and isDesktopOpenSupported() then
            showFolderInDesktop(path)
        elseif openUrl then
            openUrl(path)
        end
    else
        self:setStatus(getText("IGUI_DR_StatusConfigExportFailed"), "error")
    end
end

function DailyRewardsPanel:importAdminConfig()
    local config = FileUtils.readJson(DailyRewards.CONFIG_FILE, DailyRewards.FILE_MOD_ID, { isModFile = false })
    if type(config) ~= "table" then
        self:setStatus(getText("IGUI_DR_StatusConfigImportFailed"), "error")
        return
    end

    config = Shared.NormalizeConfig(config)
    self:loadAdminConfig(config)
    self:setStatus(getText("IGUI_DR_StatusConfigImporting"), "info")
    Shared.ExecuteCommand("ImportConfigTable", { config = config })
end

function DailyRewardsPanel:onClick(button)
    local action = button.internal
    if action == "TAB_PLAYER" then
        self.activeTab = "player"
        self:updateModeVisibility()
        self:layoutChildren(true)
    elseif action == "TAB_ADMIN" then
        if self:isAdmin() then
            self.activeTab = "admin"
            self:updateModeVisibility()
            self:layoutChildren(true)
        end
    elseif action == "REFRESH" then
        self:setStatus(getText("IGUI_DR_StatusRefreshing"), "info")
        Shared.ExecuteCommand("RequestSnapshot", { reason = "manual-refresh" })
    elseif action == "CLAIM_DAILY" then
        local row = self:getSelectedDailyRow()
        if row and row.claimable then
            self:setStatus(getText("IGUI_DR_StatusClaiming"), "info")
            Shared.ExecuteCommand("ClaimDaily", { dateKey = row.dateKey })
        end
    elseif action == "CLAIM_STREAK" then
        local row = self:getSelectedStreakRow()
        if row and row.claimable then
            self:setStatus(getText("IGUI_DR_StatusClaiming"), "info")
            Shared.ExecuteCommand("ClaimStreak", { streakId = row.streakId, claimKey = row.claimKey })
        end
    elseif action == "ADMIN_MODE_DAILY" then
        self:setAdminMode("daily")
    elseif action == "ADMIN_MODE_STREAK" then
        self:setAdminMode("streak")
    elseif action == "PICK_START_DATE" then
        self:openStartDatePicker()
    elseif action == "ADMIN_ADD" then
        self:addAdminReward()
    elseif action == "ADMIN_DELETE" then
        self:deleteAdminReward()
    elseif action == "ADD_REWARD_ITEM" then
        self:addRewardItem()
    elseif action == "REMOVE_REWARD_ITEM" then
        self:removeSelectedRewardItem()
    elseif action == "ADD_REWARD_XP" then
        self:addRewardXp()
    elseif action == "REMOVE_REWARD_XP" then
        self:removeSelectedRewardXp()
    elseif action == "ADD_REWARD_TRAIT" then
        self:addRewardTrait()
    elseif action == "REMOVE_REWARD_TRAIT" then
        self:removeSelectedRewardTrait()
    elseif action == "ADMIN_APPLY" then
        self:saveAdminEditorToSelected()
        self:populateAdminRewardsList()
        self:setStatus(getText("IGUI_DR_StatusRowApplied"), "info")
    elseif action == "SAVE_CONFIG" then
        self:setStatus(getText("IGUI_DR_StatusSaving"), "info")
        local config = self:buildAdminConfigFromFields()
        self.adminConfig = config
        self.adminDirty = false
        Shared.ExecuteCommand("SaveConfigTable", { config = config })
    elseif action == "RESET_CONFIG" then
        self.adminDirty = false
        self:setStatus(getText("IGUI_DR_StatusSaving"), "info")
        Shared.ExecuteCommand("ResetConfig", {})
    elseif action == "IMPORT_CONFIG" then
        self:importAdminConfig()
    elseif action == "EXPORT_CONFIG" then
        self:exportAdminConfig()
    end
end

function DailyRewardsPanel:drawSectionTitle(text, x, y, w)
    self:drawText(text, x, y, C.COLORS.TEXT.r, C.COLORS.TEXT.g, C.COLORS.TEXT.b, 1, UIFont.Medium)
    self:drawRect(
        x,
        y + FONT_HGT_MEDIUM + C.LABEL.OFFSET_Y,
        w,
        1,
        0.75,
        C.COLORS.BORDER.r,
        C.COLORS.BORDER.g,
        C.COLORS.BORDER.b
    )
end

local function drawFieldLabel(panel, text, control, width, color)
    panel:drawText(
        trimTextToWidth(UIFont.Small, text, width or control:getWidth()),
        control:getX(),
        control:getY() - FONT_HGT_SMALL - C.LABEL.ABOVE_GAP,
        color.r,
        color.g,
        color.b,
        1,
        UIFont.Small
    )
end

function DailyRewardsPanel:drawPlayerDetails()
    local rect = self.detailRect
    local stats = self.snapshot.stats or {}
    self:drawRect(
        rect.x,
        rect.y,
        rect.width,
        rect.height,
        C.COLORS.SECTION.a,
        C.COLORS.SECTION.r,
        C.COLORS.SECTION.g,
        C.COLORS.SECTION.b
    )
    self:drawRectBorder(
        rect.x,
        rect.y,
        rect.width,
        rect.height,
        C.COLORS.BORDER.a,
        C.COLORS.BORDER.r,
        C.COLORS.BORDER.g,
        C.COLORS.BORDER.b
    )

    local x = rect.x + C.LAYOUT.PAD
    local y = rect.y + C.LAYOUT.PAD
    local maxWidth = rect.width - (C.LAYOUT.PAD * 2)

    self:drawSectionTitle(getText("IGUI_DR_Details"), x, y, maxWidth)
    y = y + FONT_HGT_MEDIUM + C.LAYOUT.GAP_L - 1
    self:drawText(
        trimTextToWidth(
            UIFont.Small,
            string.format("%s: %s", getText("IGUI_DR_Today"), formatDateKey(self.snapshot.todayKey, "DMY")),
            maxWidth
        ),
        x,
        y,
        C.COLORS.MUTED.r,
        C.COLORS.MUTED.g,
        C.COLORS.MUTED.b,
        1,
        UIFont.Small
    )
    y = y + FONT_HGT_SMALL + C.DETAIL.TEXT_GAP
    self:drawText(
        trimTextToWidth(
            UIFont.Small,
            string.format("%s: %s", getText("IGUI_DR_ActiveStreak"), tostring(stats.activeStreak or 0)),
            maxWidth
        ),
        x,
        y,
        C.COLORS.READY.r,
        C.COLORS.READY.g,
        C.COLORS.READY.b,
        1,
        UIFont.Small
    )
    y = y + FONT_HGT_SMALL + C.DETAIL.TEXT_GAP
    self:drawText(
        trimTextToWidth(
            UIFont.Small,
            string.format("%s: %s", getText("IGUI_DR_LongestStreak"), tostring(stats.longestStreak or 0)),
            maxWidth
        ),
        x,
        y,
        C.COLORS.CLAIMED.r,
        C.COLORS.CLAIMED.g,
        C.COLORS.CLAIMED.b,
        1,
        UIFont.Small
    )
    y = y + FONT_HGT_SMALL + C.PLAYER.STATUS_BAR_GAP

    local row = self:getSelectedDailyRow()
    if row and row.reward then
        local statusText, statusColor = getDailyStatus(row)
        self:drawText(
            trimTextToWidth(UIFont.Medium, row.reward.title or ("Day " .. tostring(row.dayNumber)), maxWidth),
            x,
            y,
            C.COLORS.TEXT.r,
            C.COLORS.TEXT.g,
            C.COLORS.TEXT.b,
            1,
            UIFont.Medium
        )
        y = y + FONT_HGT_MEDIUM + C.LAYOUT.GAP_S
        self:drawText(
            trimTextToWidth(
                UIFont.Small,
                "Day " .. tostring(row.dayNumber) .. " | " .. formatDateKey(row.dateKey, "DMY") .. " | " .. statusText,
                maxWidth
            ),
            x,
            y,
            statusColor.r,
            statusColor.g,
            statusColor.b,
            1,
            UIFont.Small
        )
        y = y + FONT_HGT_SMALL + C.DETAIL.BLOCK_GAP
        y =
            drawWrappedText(
                self,
                row.reward.description or "",
                x,
                y,
                maxWidth,
                C.COLORS.MUTED,
                UIFont.Small,
                C.LAYOUT.GAP_S
            )
        y = y + C.DETAIL.BLOCK_GAP
        self:drawText(
            getText("IGUI_DR_Rewards"),
            x,
            y,
            C.COLORS.TEXT.r,
            C.COLORS.TEXT.g,
            C.COLORS.TEXT.b,
            1,
            UIFont.Small
        )
        y = y + FONT_HGT_SMALL + C.DETAIL.TEXT_GAP
        y =
            drawWrappedText(
                self,
                Shared.GetRewardSummary(row.reward.rewards),
                x,
                y,
                maxWidth,
                C.COLORS.READY,
                UIFont.Small,
                C.DETAIL.TEXT_GAP
            )
        y = y + C.DETAIL.SECTION_GAP
    end

    local streakRow = self:getSelectedStreakRow()
    if streakRow and streakRow.streak and y < rect.y + rect.height - 70 then
        local status =
            streakRow.claimed and getText("IGUI_DR_Claimed") or
            (streakRow.claimable and getText("IGUI_DR_Ready") or
                tostring(streakRow.progress or 0) .. "/" .. tostring(streakRow.requiredDays or 0))
        self:drawText(
            getText("IGUI_DR_StreakRewards"),
            x,
            y,
            C.COLORS.TEXT.r,
            C.COLORS.TEXT.g,
            C.COLORS.TEXT.b,
            1,
            UIFont.Small
        )
        y = y + FONT_HGT_SMALL + C.DETAIL.TEXT_GAP
        self:drawText(
            trimTextToWidth(
                UIFont.Small,
                tostring(streakRow.streak.title or streakRow.streakId) .. " | " .. status,
                maxWidth
            ),
            x,
            y,
            C.COLORS.LOCKED.r,
            C.COLORS.LOCKED.g,
            C.COLORS.LOCKED.b,
            1,
            UIFont.Small
        )
        y = y + FONT_HGT_SMALL + C.LIST.ICON_TEXT_GAP
        drawWrappedText(
            self,
            Shared.GetRewardSummary(streakRow.streak.rewards),
            x,
            y,
            maxWidth,
            C.COLORS.READY,
            UIFont.Small,
            C.LABEL.OFFSET_Y
        )
        return
    end

    if not row then
        drawWrappedText(
            self,
            getText("IGUI_DR_NoDailySelected"),
            x,
            y,
            maxWidth,
            C.COLORS.MUTED,
            UIFont.Small,
            C.DETAIL.TEXT_GAP
        )
    end
end

function DailyRewardsPanel:drawAdminHints()
    local muted = C.COLORS.MUTED
    local text = C.COLORS.TEXT

    self:drawText(
        getText("IGUI_DR_GlobalSettings"),
        self.settingsTickBox:getX(),
        self.settingsTickBox:getY() - FONT_HGT_SMALL - C.ADMIN.SECTION_TITLE_GAP,
        text.r,
        text.g,
        text.b,
        1,
        UIFont.Small
    )
    local settingsLabelW =
        self._settingsLabelW or (self._narrowAdminLayout and C.SETTINGS.LABEL_W_NARROW or C.SETTINGS.LABEL_W)
    local settingsTextW = settingsLabelW - C.LIST.ICON_TEXT_GAP
    self:drawText(
        trimTextToWidth(UIFont.Small, getText("IGUI_DR_CampaignStartDate"), settingsTextW),
        self.startDateEntry:getX() - settingsLabelW,
        self.startDateEntry:getY() + C.LABEL.OFFSET_Y,
        muted.r,
        muted.g,
        muted.b,
        1,
        UIFont.Small
    )
    self:drawText(
        trimTextToWidth(UIFont.Small, getText("IGUI_DR_MaxClaimableDays"), settingsTextW),
        self.maxClaimableDaysEntry:getX() - settingsLabelW,
        self.maxClaimableDaysEntry:getY() + C.LABEL.OFFSET_Y,
        muted.r,
        muted.g,
        muted.b,
        1,
        UIFont.Small
    )
    self:drawText(
        trimTextToWidth(UIFont.Small, getText("IGUI_DR_PreviewDays"), settingsTextW),
        self.previewDaysEntry:getX() - settingsLabelW,
        self.previewDaysEntry:getY() + C.LABEL.OFFSET_Y,
        muted.r,
        muted.g,
        muted.b,
        1,
        UIFont.Small
    )
    self:drawText(
        trimTextToWidth(UIFont.Small, getText("IGUI_DR_StreakGraceDays"), settingsTextW),
        self.resetStreakEntry:getX() - settingsLabelW,
        self.resetStreakEntry:getY() + C.LABEL.OFFSET_Y,
        muted.r,
        muted.g,
        muted.b,
        1,
        UIFont.Small
    )

    local sectionY =
        self._adminSectionLabelY or (self.adminRewardsList:getY() - FONT_HGT_SMALL - C.ADMIN.SECTION_TITLE_GAP)
    self:drawText(
        getText("IGUI_DR_RewardRows"),
        self.adminRewardsList:getX(),
        sectionY,
        text.r,
        text.g,
        text.b,
        1,
        UIFont.Small
    )
    self:drawText(
        getText("IGUI_DR_RewardEditor"),
        self.rewardIdEntry:getX(),
        sectionY,
        text.r,
        text.g,
        text.b,
        1,
        UIFont.Small
    )

    drawFieldLabel(self, getText("IGUI_DR_RewardId"), self.rewardIdEntry, self.rewardIdEntry:getWidth(), muted)
    local dayLabel = self.adminMode == "streak" and getText("IGUI_DR_RewardStreakDays") or getText("IGUI_DR_RewardDay")
    drawFieldLabel(self, dayLabel, self.rewardDayEntry, self.rewardDayEntry:getWidth(), muted)
    drawFieldLabel(self, getText("IGUI_DR_RewardTitle"), self.rewardTitleEntry, self.rewardTitleEntry:getWidth(), muted)
    drawFieldLabel(
        self,
        getText("IGUI_DR_RewardDescription"),
        self.rewardDescriptionEntry,
        self.rewardDescriptionEntry:getWidth(),
        muted
    )

    local sections = self._adminRewardSections or {}
    local itemsSection = sections.items
    local xpSection = sections.xp
    local traitsSection = sections.traits
    local customSection = sections.custom

    if itemsSection then
        self:drawSectionTitle(getText("IGUI_DR_ItemRewards"), itemsSection.x, itemsSection.y, itemsSection.width)
        drawFieldLabel(
            self,
            getText("IGUI_DR_ItemType"),
            self.rewardItemTypeEntry,
            self.rewardItemTypeEntry:getWidth(),
            muted
        )
        drawFieldLabel(
            self,
            getText("IGUI_DR_Count"),
            self.rewardItemCountEntry,
            self.rewardItemCountEntry:getWidth(),
            muted
        )
    end

    if xpSection then
        self:drawSectionTitle(getText("IGUI_DR_XpRewards"), xpSection.x, xpSection.y, xpSection.width)
        drawFieldLabel(
            self,
            getText("IGUI_DR_Skill"),
            self.rewardXpSkillCombo,
            self.rewardXpSkillCombo:getWidth(),
            muted
        )
        drawFieldLabel(
            self,
            getText("IGUI_DR_Amount"),
            self.rewardXpAmountEntry,
            self.rewardXpAmountEntry:getWidth(),
            muted
        )
    end

    if traitsSection then
        self:drawSectionTitle(getText("IGUI_DR_TraitRewards"), traitsSection.x, traitsSection.y, traitsSection.width)
        drawFieldLabel(self, getText("IGUI_DR_Trait"), self.rewardTraitCombo, self.rewardTraitCombo:getWidth(), muted)
    end

    if customSection then
        self:drawSectionTitle(getText("IGUI_DR_CustomLua"), customSection.x, customSection.y, customSection.width)
    end
end

function DailyRewardsPanel:prerender()
    self:layoutChildren()
    ISCollapsableWindow.prerender(self)
    self:updateButtonStates()

    if self.isCollapsed then
        return
    end

    if self.activeTab == "player" then
        self:drawText(
            getText("IGUI_DR_DayGrid"),
            C.LAYOUT.PAD,
            self.dailyGrid:getY() - FONT_HGT_SMALL - C.ADMIN.SECTION_TITLE_GAP,
            C.COLORS.TEXT.r,
            C.COLORS.TEXT.g,
            C.COLORS.TEXT.b,
            1,
            UIFont.Small
        )
        self:drawText(
            getText("IGUI_DR_StreakRewards"),
            C.LAYOUT.PAD,
            self.streakList:getY() - FONT_HGT_SMALL - C.ADMIN.SECTION_TITLE_GAP,
            C.COLORS.TEXT.r,
            C.COLORS.TEXT.g,
            C.COLORS.TEXT.b,
            1,
            UIFont.Small
        )
        self:drawPlayerDetails()
    elseif self.activeTab == "admin" then
        self:drawAdminHints()
    end
end

function DailyRewardsPanel:render()
    ISCollapsableWindow.render(self)
    if self.isCollapsed then
        return
    end

    local T     = Theme.colors
    local color = T.textMuted
    if self.statusLevel == "error" then
        color = T.danger
    elseif self.statusLevel == "warning" then
        color = T.warning
    elseif self.statusLevel == "info" then
        color = T.accent
    end

    local y = self.height - C.LAYOUT.PAD - FONT_HGT_SMALL
    self:drawText(
        trimTextToWidth(UIFont.Small, self.statusMessage or "", self.width - (C.LAYOUT.PAD * 2)),
        C.LAYOUT.PAD,
        y,
        color.r,
        color.g,
        color.b,
        1,
        UIFont.Small
    )
end

function DailyRewardsPanel:close()
    if self.startDatePicker then
        self.startDatePicker:close()
        self.startDatePicker = nil
    end
    self:setVisible(false)
    self:removeFromUIManager()
    DailyRewardsPanel.instance = nil
end

function DailyRewardsPanel.openPanel(playerObj)
    playerObj = playerObj or getPlayer()

    if DailyRewardsPanel.instance then
        DailyRewardsPanel.instance:bringToTop()
        Shared.ExecuteCommand("RequestSnapshot", { reason = "open-existing" })
        return DailyRewardsPanel.instance
    end

    local screenWidth = getCore():getScreenWidth()
    local screenHeight = getCore():getScreenHeight()
    local width = math.min(C.SIZE.DEFAULT_W, math.max(C.SIZE.MIN_W, screenWidth - 40))
    local height = math.min(C.SIZE.DEFAULT_H, math.max(C.SIZE.MIN_H, screenHeight - 40))
    local x = math.max(20, math.floor((screenWidth - width) / 2))
    local y = math.max(20, math.floor((screenHeight - height) / 2))
    local panel = DailyRewardsPanel:new(x, y, width, height, playerObj)
    panel:initialise()
    panel:addToUIManager()
    DailyRewardsPanel.instance = panel
    Shared.ExecuteCommand("RequestSnapshot", { reason = "open" })
    return panel
end

local MenuDock = require("ElyonLib/UI/MenuDock/MenuDock")

MenuDock.registerButton(
    {
        id = "daily_rewards",
        title = getText("IGUI_DR_DailyRewards"),
        icon = "media/ui/DailyRewards/ui_icon_daily_rewards.png",
        allowSinglePlayer = true,
        onClick = function(playerNum, entry)
            DailyRewardsPanel.openPanel(getSpecificPlayer(playerNum))
        end
    }
)

return DailyRewardsPanel
