-- Tooltip icons: resources and yields are replaced with * (interactive indicator).
-- Other icons whose word immediately follows are removed (word stays).
-- Remaining standalone icons are replaced by a localized word or plain string.
-- After icon processing, remaining Civ VI markup ([NEWLINE], [COLOR:...], etc.) is stripped.

local TOOLTIP_ICON_PREFIXES = { "^RESOURCE_", "^YIELD_" }
local TOOLTIP_ICON_EXACT = {
    Food=true,       Production=true, Gold=true,
    Science=true,    Culture=true,    Faith=true,
    Amenities=true,  Housing=true,    Power=true,   Tourism=true,
}

-- Word expected to follow each short-form tooltip icon in vanilla text.
-- LOC_ entries are resolved at call time; plain strings are returned directly.
local TOOLTIP_ICON_WORDS = {
    Food       = "LOC_YIELD_FOOD_NAME",
    Production = "LOC_YIELD_PRODUCTION_NAME",
    Gold       = "LOC_YIELD_GOLD_NAME",
    Science    = "LOC_YIELD_SCIENCE_NAME",
    Culture    = "LOC_YIELD_CULTURE_NAME",
    Faith      = "LOC_YIELD_FAITH_NAME",
    Amenities  = "LOC_HUD_CITY_AMENITIES",
    Housing    = "LOC_HUD_CITY_HOUSING",
    Power      = "Power",
    Tourism    = "Tourism",
}

-- Values are either:
--   "LOC_*" string → looked up via Locale.Lookup at call time
--   any other string → returned directly as the replacement word
--   "" → icon is silently removed
local ICON_LOOKUP = {
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
}

local function DynamicLookup(iconName)
    if not GameInfo then return nil end
    local yieldKey = iconName:match("^YIELD_(.+)")
    if yieldKey and GameInfo.Yields then
        local row = GameInfo.Yields["YIELD_" .. yieldKey]
        if row then return Locale.Lookup(row.Name) end
    end
    local resKey = iconName:match("^RESOURCE_(.+)")
    if resKey and GameInfo.Resources then
        local row = GameInfo.Resources["RESOURCE_" .. resKey]
        if row then return Locale.Lookup(row.Name) end
    end
    return nil
end

local function GetTooltipIconWord(iconName)
    local entry = TOOLTIP_ICON_WORDS[iconName]
    if entry ~= nil then
        if entry:sub(1, 4) == "LOC_" then
            local looked = Locale.Lookup(entry)
            if looked and looked ~= entry then return looked end
        else
            return entry
        end
    end
    return DynamicLookup(iconName)
end

local function IsTooltipIcon(iconName)
    if TOOLTIP_ICON_EXACT[iconName] then return true end
    for _, pat in ipairs(TOOLTIP_ICON_PREFIXES) do
        if iconName:match(pat) then return true end
    end
    return false
end

local function GetIconWord(iconName)
    local entry = ICON_LOOKUP[iconName]
    if entry ~= nil then
        if entry == "" then return "" end
        if entry:sub(1, 4) == "LOC_" then
            local looked = Locale.Lookup(entry)
            if looked and looked ~= entry then return looked end
            -- LOC key not found; fall through to dynamic lookup
        else
            return entry   -- plain string, return directly
        end
    end
    return DynamicLookup(iconName)
end

-- Strips leading separator chars (whitespace, comma, semicolon, colon) and any
-- leading non-icon Civ VI markup tokens ([ENDCOLOR], [COLOR:...], etc.).
-- Returns the cleaned string and the total number of source chars consumed.
local function StripLeadingMarkup(s)
    local skip = 0
    local sep = s:match("^([%s,;:]+)")
    if sep then skip = skip + #sep; s = s:sub(#sep + 1) end
    local changed = true
    while changed do
        changed = false
        local tag = s:match("^(%[[^%]]*%])")
        if tag and not tag:match("^%[ICON_") then
            skip = skip + #tag; s = s:sub(#tag + 1); changed = true
        end
    end
    local ws = s:match("^(%s+)")
    if ws then skip = skip + #ws; s = s:sub(#ws + 1) end
    return s, skip
end

-- Returns true if lw (lowercase icon word) semantically overlaps with the start
-- of rest (raw text after separator/markup stripping).  Three tiers:
--   1. Exact prefix: lw is a prefix of rest (e.g. "ranged strength" / "Ranged Strength vs.")
--   2. Word match: any 4+ char word in lw appears verbatim among the first 3 words of rest
--      (e.g. "melee strength" / "Combat Strength" – shared word "strength")
--   3. Stem match: 4-char stem of a lw word matches 4-char stem of a rest word
--      (e.g. "ranged strength" / "Attack Range" – "rang" stem shared)
local function WordFollows(lw, rest)
    local rl = rest:lower()
    if rl:sub(1, #lw) == lw then return true end
    local lwWords = {}
    for w in lw:gmatch("%a+") do
        if #w >= 4 then lwWords[w] = true end
    end
    if not next(lwWords) then return false end
    local count = 0
    for rw in rl:gmatch("%a+") do
        count = count + 1
        if lwWords[rw] then return true end
        local stem = rw:sub(1, 4)
        for lw_word in pairs(lwWords) do
            if lw_word:sub(1, 4) == stem then return true end
        end
        if count >= 3 then break end
    end
    return false
end

---Replaces [ICON_X] tokens in text with accessible equivalents for TTS output.
---Tooltip icons (resources, yields, amenities, housing, power, tourism): if their
---word immediately follows the icon the icon becomes "*" and the word stays;
---when the icon is standalone the word itself is emitted instead.
---Non-tooltip icons whose word immediately follows are removed (word stays).
---All other icons are replaced by their localized word, or removed if unknown.
---After icon substitution, remaining Civ VI markup ([NEWLINE], [COLOR:...],
---[ENDCOLOR], [SIZE:...]) is stripped; red color markup becomes "warning: ".
---@param text string
---@return string
function ProcessIcons(text)
    if not text or text == "" then return text end
    local out = {}
    local pos = 1
    while pos <= #text do
        local s, e, iconName = text:find("%[ICON_([^%]]-)%]", pos)
        if not s then
            out[#out + 1] = text:sub(pos)
            break
        end
        out[#out + 1] = text:sub(pos, s - 1)
        pos = e + 1

        if IsTooltipIcon(iconName) then
            local word = GetTooltipIconWord(iconName)
            if word then
                local lw = word:lower()
                local rest, skip = StripLeadingMarkup(text:sub(pos))
                if rest:lower():sub(1, #lw) == lw then
                    -- Word follows (possibly after markup/separator): emit * and skip past it
                    out[#out + 1] = "* "
                    pos = pos + skip
                else
                    -- Check if the word was just emitted before the icon (e.g. "Culture, [ICON_Culture]+value")
                    local prevSeg = (out[#out] or ""):lower():gsub("[%s,;:]+$", "")
                    if prevSeg:sub(-#lw) == lw then
                        -- Word precedes icon: drop icon silently
                    else
                        -- Standalone: emit the yield/resource name
                        out[#out + 1] = word .. " "
                    end
                end
            else
                -- No word known for this tooltip icon: fall back to *
                out[#out + 1] = "* "
            end
        else
            local word = GetIconWord(iconName)
            if word == "" then
                -- Explicitly decorative icon — remove silently
            elseif word then
                local lw = word:lower()
                local rest, skip = StripLeadingMarkup(text:sub(pos))
                if WordFollows(lw, rest) then
                    -- Stat word follows (possibly after markup/separator): drop icon and skip past it
                    pos = pos + skip
                elseif lw:find(" ", 1, true) and rest:match("^%a") then
                    -- Multi-word stat icon before descriptive text with no vocabulary match
                    -- (e.g. "Melee Strength" before "Combat Bonus"): drop as decorative
                    pos = pos + skip
                else
                    -- Check if the word was just emitted before the icon (e.g. "Ranged Strength[ICON_Ranged]")
                    local prevSeg = (out[#out] or ""):lower():gsub("[%s,;:]+$", "")
                    if prevSeg:sub(-#lw) == lw then
                        -- Word precedes icon: drop icon silently
                    else
                        -- Standalone: substitute the word
                        out[#out + 1] = word .. " "
                    end
                end
            end
            -- Unknown icon: remove silently
        end
    end

    local result = table.concat(out)

    -- Red/warning color markup → "warning: "
    result = result:gsub("%[CIV6_COLOR_RED%]", "warning: ")
    result = result:gsub("%[COLOR_RED%]", "warning: ")
    result = result:gsub("%[COLOR:Civ6Red%]", "warning: ")
    result = result:gsub("%[COLOR:Red%]", "warning: ")
    result = result:gsub("%[COLOR:RED%]", "warning: ")
    -- All other color and size markup → remove
    result = result:gsub("%[COLOR:[^%]]*%]", "")
    result = result:gsub("%[ENDCOLOR%]", "")
    result = result:gsub("%[SIZE:%d+%]", "")
    -- Newline markup → real newline
    result = result:gsub("%[NEWLINE%]", "\n")

    return result
end
