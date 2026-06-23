-- Icon-to-speech registry and adjacency deduplication.
--
-- Each registered icon has a spoken form (resolved from a LOC_ key or a
-- literal string) and an optional list of adjacency aliases. ProcessIcons
-- resolves bracket tokens and deduplicates in two ways:
--
-- 1. Spoken-form match: when the icon's spoken form already appears adjacent
--    to the bracket in the source text, the icon collapses (the adjacent text
--    is the correct label, so the icon is redundant).
--    Example: "+2 [ICON_Production] Production" -> "+2 Production"
--
-- 2. Alias match: when a less-specific alias appears adjacent but the icon's
--    spoken form is more precise, the alias text is stripped and the icon's
--    spoken form is kept.
--    Example: "+5 [ICON_Strength] Combat Strength" -> "+5 Melee Strength"
--    ("Combat Strength" is the generic label; "Melee Strength" is specific.)

-- Values are either:
--   "LOC_*" string -> looked up via Locale.Lookup at call time
--   any other string -> returned directly as the replacement text
--   "" -> token is silently removed (decorative, no dedup needed)
--   false -> token bypasses dedup and produces fixed output (see DIRECT_OUTPUT)
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
    -- Bullet list marker (no dedup)
    ["Bullet"]               = false,
    -- Decorative formation/unit badges: appear after the word they label
    ["Army"]                 = "",
    ["Corps"]                = "",
    -- Decorative diplomatic/UI badges
    ["Bolt"]                 = "",
    ["ThemeBonus"]           = "",
    ["ThemeBonus_Active"]    = "",
    ["VisLimited"]           = "",
    ["VisSecret"]            = "",
    -- Civ VI text markup (no dedup)
    ["NEWLINE"]              = false,
}

local DIRECT_OUTPUT = {
    ["Bullet"]  = "•",
    ["NEWLINE"] = "\n",
}

-- Collapse aliases keyed by REPLACEMENTS key (after ICON_ strip). Each
-- entry is a list of LOC_ keys. When the resolved alias text appears adjacent
-- to the bracket token, the icon collapses and the adjacent label stays.
-- Used when the icon is a generic catch-all but the adjacent text is the
-- specific label (e.g. [ICON_Strength] is used for melee, combat, and
-- defense strength — the adjacent text carries the real meaning).
local COLLAPSE_ALIAS_KEYS = {
    ["Strength"]             = { "LOC_CAI_ICON_STRENGTH_ALIAS_COMBAT", "LOC_CAI_ICON_STRENGTH_ALIAS_DEFENSE" },
    ["Strength_Large"]       = { "LOC_CAI_ICON_STRENGTH_ALIAS_COMBAT", "LOC_CAI_ICON_STRENGTH_ALIAS_DEFENSE" },
    ["STRENGTH"]             = { "LOC_CAI_ICON_STRENGTH_ALIAS_COMBAT", "LOC_CAI_ICON_STRENGTH_ALIAS_DEFENSE" },
    ["Range"]                = { "LOC_CAI_ICON_RANGE_ALIAS" },
    ["Range_Large"]          = { "LOC_CAI_ICON_RANGE_ALIAS" },
    ["RANGE"]                = { "LOC_CAI_ICON_RANGE_ALIAS" },
}

local function ResolveCollapseAliases(lookupKey)
    local keys = COLLAPSE_ALIAS_KEYS[lookupKey]
    if not keys then return nil end
    local resolved = {}
    for _, locKey in ipairs(keys) do
        local text = Locale.Lookup(locKey)
        if text and text ~= locKey then
            resolved[#resolved + 1] = text
        end
    end
    if #resolved == 0 then return nil end
    return resolved
end

local function DynamicLookup(tokenName)
    if not GameInfo then return nil end

    local iconName = tokenName:match("^ICON_(.+)")
    if not iconName then
        return nil
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

    return nil
end

local function ResolveEntry(tokenName)
    local iconName = tokenName:match("^ICON_(.+)")
    local lookupKey = iconName or tokenName
    local entry = REPLACEMENTS[lookupKey]

    if entry == false then
        return DIRECT_OUTPUT[lookupKey] or "", lookupKey, true
    end

    if entry ~= nil then
        if entry == "" then
            return "", lookupKey, false
        end
        if entry:sub(1, 4) == "LOC_" then
            local looked = Locale.Lookup(entry)
            if looked and looked ~= entry then
                return looked, lookupKey, false
            end
            return "", lookupKey, false
        end
        return entry, lookupKey, false
    end

    local dynamic = DynamicLookup(tokenName)
    if dynamic then
        return dynamic, lookupKey, false
    end
    return "", lookupKey, false
end

local function IsWordChar(byte)
    if not byte then return false end
    return (byte >= 65 and byte <= 90)
        or (byte >= 97 and byte <= 122)
        or (byte >= 48 and byte <= 57)
        or byte == 95
end

-- Check whether `phrase` appears as a whole-word match adjacent to the
-- bracket token at [bracketStart..bracketEnd] in `text`. Adjacent means
-- the phrase starts/ends within a small window on either side, separated
-- from the bracket by only non-word characters (whitespace, punctuation).
local function FindAdjacentPhrase(text, bracketStart, bracketEnd, phrase)
    if not phrase or phrase == "" then return false end
    local phraseLower = phrase:lower()
    local textLen = #text
    local windowSize = #phrase + 10

    -- Check AFTER the bracket token
    local afterStart = bracketEnd + 1
    local afterEnd = math.min(textLen, bracketEnd + windowSize)
    if afterStart <= textLen then
        local after = text:sub(afterStart, afterEnd):lower()
        local matchStart = after:find(phraseLower, 1, true)
        if matchStart then
            local gap = after:sub(1, matchStart - 1)
            if not gap:find("[%a%d_]") then
                local absMatchEnd = afterStart + matchStart - 2 + #phraseLower
                if not IsWordChar(text:byte(absMatchEnd + 1)) then
                    return true
                end
            end
        end
    end

    -- Check BEFORE the bracket token
    local beforeEnd = bracketStart - 1
    local beforeStart = math.max(1, bracketStart - windowSize)
    if beforeEnd >= 1 then
        local before = text:sub(beforeStart, beforeEnd):lower()
        local searchFrom = 1
        local lastFound = nil
        while true do
            local p = before:find(phraseLower, searchFrom, true)
            if not p then break end
            lastFound = p
            searchFrom = p + 1
        end
        if lastFound then
            local matchEndInBefore = lastFound + #phraseLower - 1
            local gap = before:sub(matchEndInBefore + 1)
            if not gap:find("[%a%d_]") then
                local absStart = beforeStart + lastFound - 1
                if not IsWordChar(text:byte(absStart - 1)) then
                    return true
                end
            end
        end
    end

    return false
end

---Replaces any Civ VI bracket token ([text]) with a matching spoken form, or
---removes it when no replacement exists. When the spoken form or a collapse
---alias appears adjacent to the bracket, the icon collapses (adjacent label
---stays, icon is redundant).
---@param text string
---@return string
function ProcessIcons(text)
    if not text or text == "" then
        return text
    end

    local result = {}
    local pos = 1
    local len = #text

    while pos <= len do
        local bracketStart = text:find("[", pos, true)
        if not bracketStart then
            result[#result + 1] = text:sub(pos)
            break
        end

        if bracketStart > pos then
            result[#result + 1] = text:sub(pos, bracketStart - 1)
        end

        local bracketEnd = text:find("]", bracketStart + 1, true)
        if not bracketEnd then
            result[#result + 1] = text:sub(bracketStart)
            break
        end

        local tokenName = text:sub(bracketStart + 1, bracketEnd - 1)
        local spokenForm, lookupKey, skipDedup = ResolveEntry(tokenName)

        if skipDedup or spokenForm == "" then
            result[#result + 1] = spokenForm
        elseif FindAdjacentPhrase(text, bracketStart, bracketEnd, spokenForm) then
            -- Spoken form already in adjacent text; icon is redundant.
        else
            local collapsed = false
            local aliases = ResolveCollapseAliases(lookupKey)
            if aliases then
                for _, alias in ipairs(aliases) do
                    if FindAdjacentPhrase(text, bracketStart, bracketEnd, alias) then
                        collapsed = true
                        break
                    end
                end
            end
            if not collapsed then
                result[#result + 1] = spokenForm
            end
        end

        pos = bracketEnd + 1
    end

    return table.concat(result)
end
