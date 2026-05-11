-- Values are either:
--   "LOC_*" string -> looked up via Locale.Lookup at call time
--   any other string -> returned directly as the replacement text
--   "" -> token is silently removed
local REPLACEMENTS = {
    -- Unit stat large icons (FontIcon names from CitySupport.lua)
    ["Strength_Large"]       = "LOC_HUD_UNIT_PANEL_STRENGTH",
    ["RangedStrength_Large"] = "LOC_HUD_UNIT_PANEL_RANGED_STRENGTH",
    ["Bombard_Large"]        = "LOC_HUD_UNIT_PANEL_BOMBARD_STRENGTH",
    ["Range_Large"]          = "LOC_HUD_UNIT_PANEL_ATTACK_RANGE",
    -- Plain stat icon variants used in vanilla text strings
    ["Strength"]             = "LOC_HUD_UNIT_PANEL_STRENGTH",
    ["Ranged"]               = "LOC_HUD_UNIT_PANEL_RANGED_STRENGTH",
    ["Bombard"]              = "LOC_HUD_UNIT_PANEL_BOMBARD_STRENGTH",
    ["Range"]                = "LOC_HUD_UNIT_PANEL_ATTACK_RANGE",
    ["AntiAir_Large"]        = "LOC_CAI_ICON_ANTI_AIR",
    -- ALLCAPS IconName variants (UnitPanel.lua)
    ["STRENGTH"]             = "LOC_HUD_UNIT_PANEL_STRENGTH",
    ["RANGED_STRENGTH"]      = "LOC_HUD_UNIT_PANEL_RANGED_STRENGTH",
    ["BOMBARD"]              = "LOC_HUD_UNIT_PANEL_BOMBARD_STRENGTH",
    ["RANGE"]                = "LOC_HUD_UNIT_PANEL_ATTACK_RANGE",
    -- Movement
    ["MOVEMENT_LARGE"]       = "LOC_HUD_UNIT_PANEL_MOVEMENT",
    ["Movement"]             = "LOC_HUD_UNIT_PANEL_MOVEMENT",
    -- Turns (appears as number..[ICON_Turn] or [ICON_Turn]..number)
    ["Turn"]                 = "LOC_HUD_UNIT_PANEL_TURNS_REMAINING",
    -- Unit ability stats
    ["Charges"]              = "LOC_CAI_ICON_CHARGES",
    ["Lifespan"]             = "LOC_CAI_ICON_LIFESPAN",
    ["Damaged"]              = "Damaged",
    -- Capital city status marker
    ["Capital"]              = "LOC_CITY_CAPITAL_LABEL",
    -- Attention / alert icons
    ["Exclamation"]          = "LOC_CAI_ICON_EXCLAMATION",
    -- Purchase button yield labels (appear standalone before "Purchase")
    ["FaithLarge"]           = "LOC_YIELD_FAITH_NAME",
    ["GoldLarge"]            = "LOC_YIELD_GOLD_NAME",
    ["ProductionLarge"]      = "LOC_YIELD_PRODUCTION_NAME",
    -- Bullet list marker: replace with actual bullet character
    ["Bullet"]               = "•",
    -- Decorative formation/unit badges: appear after the word they label
    ["Army"]                 = "",
    ["Corps"]                = "",
    -- Decorative diplomatic/UI badges
    ["Bolt"]                 = "",
    ["ThemeBonus"]           = "",
    ["ThemeBonus_Active"]    = "",
    ["VisLimited"]           = "",
    ["VisSecret"]            = "",
    -- Civ VI text markup
    ["NEWLINE"]              = "\n",
}

local function DynamicLookup(tokenName)
    if not GameInfo then return "" end

    local iconName = tokenName:match("^ICON_(.+)")
    if not iconName then
        return ""
    end

    local yieldKey = iconName:match("^YIELD_(.+)")
    if yieldKey and GameInfo.Yields then
        local row = GameInfo.Yields["YIELD_" .. yieldKey]
        if row then
            return Locale.Lookup(row.Name)
        end
    end

    local resKey = iconName:match("^RESOURCE_(.+)")
    if resKey and GameInfo.Resources then
        local row = GameInfo.Resources["RESOURCE_" .. resKey]
        if row then
            return Locale.Lookup(row.Name)
        end
    end

    return ""
end

local function GetReplacement(tokenName)
    local iconName = tokenName:match("^ICON_(.+)")
    local lookupKey = iconName or tokenName
    local entry = REPLACEMENTS[lookupKey]

    if entry ~= nil then
        if entry == "" then
            return ""
        end

        if entry:sub(1, 4) == "LOC_" then
            local looked = Locale.Lookup(entry)
            if looked and looked ~= entry then
                return looked
            end
            return ""
        end

        return entry
    end

    return DynamicLookup(tokenName)
end

---Replaces any Civ VI bracket token ([text]) with a matching replacement, or
---removes it when no replacement exists.
---@param text string
---@return string
function ProcessIcons(text)
    if not text or text == "" then
        return text
    end

    return (text:gsub("%[([^%]]-)%]", GetReplacement))
end
