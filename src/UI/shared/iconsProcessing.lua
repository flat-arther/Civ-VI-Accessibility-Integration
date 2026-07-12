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
    -- Capital city status marker
    ["Capital"]              = "LOC_CAI_CITY_STATUS_CAPITAL",
    -- Attention / alert icons
    ["Exclamation"]          = "LOC_CAI_ICON_EXCLAMATION",
    -- yield font icons
    Gold                     = "LOC_YIELD_GOLD_NAME",
    GoldLarge                = "LOC_YIELD_GOLD_NAME",
    Food                     = "LOC_YIELD_FOOD_NAME",
    FoodLarge                = "LOC_YIELD_FOOD_NAME",
    Production               = "LOC_YIELD_PRODUCTION_NAME",
    ProductionLarge          = "LOC_YIELD_PRODUCTION_NAME",
    Science                  = "LOC_YIELD_SCIENCE_NAME",
    ScienceLarge             = "LOC_YIELD_SCIENCE_NAME",
    Culture                  = "LOC_YIELD_CULTURE_NAME",
    CultureLarge             = "LOC_YIELD_CULTURE_NAME",
    Faith                    = "LOC_YIELD_FAITH_NAME",
    FaithLarge               = "LOC_YIELD_FAITH_NAME",

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
    ["NEWLINE"] = ", ",
}

-- English screen-reader voices may expose unsupported Latin characters as
-- question marks. Keep the displayed/localized text intact, but simplify the
-- processed speech string when Civ VI's display language is English.
local ENGLISH_TTS_TRANSLITERATIONS = {
    ["à"] = "a", ["á"] = "a", ["â"] = "a", ["ã"] = "a", ["ä"] = "a", ["å"] = "a",
    ["ā"] = "a", ["ă"] = "a", ["ą"] = "a", ["ǎ"] = "a", ["ǻ"] = "a", ["ạ"] = "a",
    ["ả"] = "a", ["ấ"] = "a", ["ầ"] = "a", ["ẩ"] = "a", ["ẫ"] = "a", ["ậ"] = "a",
    ["ắ"] = "a", ["ằ"] = "a", ["ẳ"] = "a", ["ẵ"] = "a", ["ặ"] = "a",
    ["ç"] = "c", ["ć"] = "c", ["ĉ"] = "c", ["ċ"] = "c", ["č"] = "c",
    ["ď"] = "d", ["đ"] = "d", ["ð"] = "d",
    ["è"] = "e", ["é"] = "e", ["ê"] = "e", ["ë"] = "e", ["ē"] = "e", ["ĕ"] = "e",
    ["ė"] = "e", ["ę"] = "e", ["ě"] = "e", ["ẹ"] = "e", ["ẻ"] = "e", ["ẽ"] = "e",
    ["ế"] = "e", ["ề"] = "e", ["ể"] = "e", ["ễ"] = "e", ["ệ"] = "e",
    ["ĝ"] = "g", ["ğ"] = "g", ["ġ"] = "g", ["ģ"] = "g",
    ["ĥ"] = "h", ["ħ"] = "h",
    ["ì"] = "i", ["í"] = "i", ["î"] = "i", ["ï"] = "i", ["ĩ"] = "i", ["ī"] = "i",
    ["ĭ"] = "i", ["į"] = "i", ["ı"] = "i", ["ǐ"] = "i", ["ị"] = "i", ["ỉ"] = "i",
    ["ĵ"] = "j", ["ķ"] = "k", ["ĺ"] = "l", ["ļ"] = "l", ["ľ"] = "l", ["ŀ"] = "l", ["ł"] = "l",
    ["ñ"] = "n", ["ń"] = "n", ["ņ"] = "n", ["ň"] = "n", ["ŋ"] = "n",
    ["ò"] = "o", ["ó"] = "o", ["ô"] = "o", ["õ"] = "o", ["ö"] = "o", ["ø"] = "o",
    ["ō"] = "o", ["ŏ"] = "o", ["ő"] = "o", ["ǒ"] = "o", ["ọ"] = "o", ["ỏ"] = "o",
    ["ố"] = "o", ["ồ"] = "o", ["ổ"] = "o", ["ỗ"] = "o", ["ộ"] = "o", ["ớ"] = "o",
    ["ờ"] = "o", ["ở"] = "o", ["ỡ"] = "o", ["ợ"] = "o", ["ơ"] = "o",
    ["ŕ"] = "r", ["ŗ"] = "r", ["ř"] = "r", ["ś"] = "s", ["ŝ"] = "s", ["ş"] = "s", ["š"] = "s",
    ["ţ"] = "t", ["ť"] = "t", ["ŧ"] = "t", ["þ"] = "th",
    ["ù"] = "u", ["ú"] = "u", ["û"] = "u", ["ü"] = "u", ["ũ"] = "u", ["ū"] = "u",
    ["ŭ"] = "u", ["ů"] = "u", ["ű"] = "u", ["ų"] = "u", ["ǔ"] = "u", ["ụ"] = "u",
    ["ủ"] = "u", ["ứ"] = "u", ["ừ"] = "u", ["ử"] = "u", ["ữ"] = "u", ["ự"] = "u", ["ư"] = "u",
    ["ŵ"] = "w", ["ý"] = "y", ["ÿ"] = "y", ["ŷ"] = "y", ["ỳ"] = "y", ["ỵ"] = "y",
    ["ỷ"] = "y", ["ỹ"] = "y", ["ź"] = "z", ["ż"] = "z", ["ž"] = "z",
    ["æ"] = "ae", ["œ"] = "oe", ["ß"] = "ss",

    ["À"] = "A", ["Á"] = "A", ["Â"] = "A", ["Ã"] = "A", ["Ä"] = "A", ["Å"] = "A",
    ["Ā"] = "A", ["Ă"] = "A", ["Ą"] = "A", ["Ǎ"] = "A", ["Ǻ"] = "A", ["Ạ"] = "A",
    ["Ả"] = "A", ["Ấ"] = "A", ["Ầ"] = "A", ["Ẩ"] = "A", ["Ẫ"] = "A", ["Ậ"] = "A",
    ["Ắ"] = "A", ["Ằ"] = "A", ["Ẳ"] = "A", ["Ẵ"] = "A", ["Ặ"] = "A",
    ["Ç"] = "C", ["Ć"] = "C", ["Ĉ"] = "C", ["Ċ"] = "C", ["Č"] = "C",
    ["Ď"] = "D", ["Đ"] = "D", ["Ð"] = "D",
    ["È"] = "E", ["É"] = "E", ["Ê"] = "E", ["Ë"] = "E", ["Ē"] = "E", ["Ĕ"] = "E",
    ["Ė"] = "E", ["Ę"] = "E", ["Ě"] = "E", ["Ẹ"] = "E", ["Ẻ"] = "E", ["Ẽ"] = "E",
    ["Ế"] = "E", ["Ề"] = "E", ["Ể"] = "E", ["Ễ"] = "E", ["Ệ"] = "E",
    ["Ĝ"] = "G", ["Ğ"] = "G", ["Ġ"] = "G", ["Ģ"] = "G", ["Ĥ"] = "H", ["Ħ"] = "H",
    ["Ì"] = "I", ["Í"] = "I", ["Î"] = "I", ["Ï"] = "I", ["Ĩ"] = "I", ["Ī"] = "I",
    ["Ĭ"] = "I", ["Į"] = "I", ["İ"] = "I", ["Ǐ"] = "I", ["Ị"] = "I", ["Ỉ"] = "I",
    ["Ĵ"] = "J", ["Ķ"] = "K", ["Ĺ"] = "L", ["Ļ"] = "L", ["Ľ"] = "L", ["Ŀ"] = "L", ["Ł"] = "L",
    ["Ñ"] = "N", ["Ń"] = "N", ["Ņ"] = "N", ["Ň"] = "N", ["Ŋ"] = "N",
    ["Ò"] = "O", ["Ó"] = "O", ["Ô"] = "O", ["Õ"] = "O", ["Ö"] = "O", ["Ø"] = "O",
    ["Ō"] = "O", ["Ŏ"] = "O", ["Ő"] = "O", ["Ǒ"] = "O", ["Ọ"] = "O", ["Ỏ"] = "O",
    ["Ố"] = "O", ["Ồ"] = "O", ["Ổ"] = "O", ["Ỗ"] = "O", ["Ộ"] = "O", ["Ớ"] = "O",
    ["Ờ"] = "O", ["Ở"] = "O", ["Ỡ"] = "O", ["Ợ"] = "O", ["Ơ"] = "O",
    ["Ŕ"] = "R", ["Ŗ"] = "R", ["Ř"] = "R", ["Ś"] = "S", ["Ŝ"] = "S", ["Ş"] = "S", ["Š"] = "S",
    ["Ţ"] = "T", ["Ť"] = "T", ["Ŧ"] = "T", ["Þ"] = "Th",
    ["Ù"] = "U", ["Ú"] = "U", ["Û"] = "U", ["Ü"] = "U", ["Ũ"] = "U", ["Ū"] = "U",
    ["Ŭ"] = "U", ["Ů"] = "U", ["Ű"] = "U", ["Ų"] = "U", ["Ǔ"] = "U", ["Ụ"] = "U",
    ["Ủ"] = "U", ["Ứ"] = "U", ["Ừ"] = "U", ["Ử"] = "U", ["Ữ"] = "U", ["Ự"] = "U", ["Ư"] = "U",
    ["Ŵ"] = "W", ["Ý"] = "Y", ["Ÿ"] = "Y", ["Ŷ"] = "Y", ["Ỳ"] = "Y", ["Ỵ"] = "Y",
    ["Ỷ"] = "Y", ["Ỹ"] = "Y", ["Ź"] = "Z", ["Ż"] = "Z", ["Ž"] = "Z",
    ["Æ"] = "AE", ["Œ"] = "OE",

    -- Strip common combining marks when text arrives in decomposed form.
    ["̀"] = "", ["́"] = "", ["̂"] = "", ["̃"] = "", ["̄"] = "", ["̆"] = "",
    ["̇"] = "", ["̈"] = "", ["̊"] = "", ["̋"] = "", ["̌"] = "", ["̧"] = "", ["̨"] = "",
}

local function IsEnglishDisplayLanguage()
    local language = Locale.GetCurrentLanguage()
    local languageType = language and language.Type
    return type(languageType) == "string" and languageType:lower():match("^en[_%-]") ~= nil
end

local function TransliterateForEnglishTTS(text)
    if not IsEnglishDisplayLanguage() then return text end
    for source, replacement in pairs(ENGLISH_TTS_TRANSLITERATIONS) do
        text = text:gsub(source, replacement)
    end
    return text
end

-- Collapse aliases keyed by REPLACEMENTS key (after ICON_ strip). Each
-- entry is a list of LOC_ keys. When the resolved alias text appears adjacent
-- to the bracket token, the icon collapses and the adjacent label stays.
-- Used when the icon is a generic catch-all but the adjacent text is the
-- specific label (e.g. [ICON_Strength] is used for melee, combat, and
-- defense strength — the adjacent text carries the real meaning).
local COLLAPSE_ALIAS_KEYS = {
    ["Strength"]       = { "LOC_CAI_ICON_STRENGTH_ALIAS_COMBAT", "LOC_CAI_ICON_STRENGTH_ALIAS_DEFENSE" },
    ["Strength_Large"] = { "LOC_CAI_ICON_STRENGTH_ALIAS_COMBAT", "LOC_CAI_ICON_STRENGTH_ALIAS_DEFENSE" },
    ["STRENGTH"]       = { "LOC_CAI_ICON_STRENGTH_ALIAS_COMBAT", "LOC_CAI_ICON_STRENGTH_ALIAS_DEFENSE" },
    ["Range"]          = { "LOC_CAI_ICON_RANGE_ALIAS" },
    ["Range_Large"]    = { "LOC_CAI_ICON_RANGE_ALIAS" },
    ["RANGE"]          = { "LOC_CAI_ICON_RANGE_ALIAS" },
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

local function SkipFormatting(text, pos)
    while true do
        local s, e = text:find("%b[]", pos)
        if s ~= pos then
            break
        end

        local tag = text:sub(s + 1, e - 1)
        if tag:match("^COLOR_") or tag == "ENDCOLOR" then
            pos = e + 1
        else
            break
        end
    end

    return pos
end

local function FindAdjacentPhrase(text, bracketStart, bracketEnd, phrase)
    if not phrase or phrase == "" then
        return false
    end

    local phraseLower = phrase:lower()

    ------------------------------------------------------------------------
    -- AFTER the icon
    ------------------------------------------------------------------------
    local pos = SkipFormatting(text, bracketEnd + 1)

    -- Skip ordinary whitespace too.
    while true do
        local c = text:sub(pos, pos)
        if c == " " or c == "\t" or c == "\r" or c == "\n" then
            pos = pos + 1
        else
            break
        end
    end

    if text:sub(pos, pos + #phrase - 1):lower() == phraseLower then
        return true
    end

    ------------------------------------------------------------------------
    -- BEFORE the icon
    ------------------------------------------------------------------------
    pos = bracketStart - 1

    -- Skip whitespace backwards.
    while pos > 0 do
        local c = text:sub(pos, pos)
        if c == " " or c == "\t" or c == "\r" or c == "\n" then
            pos = pos - 1
        else
            break
        end
    end

    local startPos = pos - #phrase + 1
    if startPos >= 1 then
        if text:sub(startPos, pos):lower() == phraseLower then
            return true
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

    return TransliterateForEnglishTTS(table.concat(result))
end
