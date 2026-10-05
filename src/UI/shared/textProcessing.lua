-- Central text processor for speech output.
--
-- This is the ONE place CAI filters text for the screen reader. Speak() (and the
-- edit-box SetText path) call ProcessText; individual screens must NOT strip
-- COLOR/NEWLINE/ICON tokens or normalize whitespace themselves -- ProcessText
-- already resolves every bracket token and tidies the result.
--
-- Locale note: never use the %s / %S pattern classes on localized text here or
-- anywhere downstream. The Civ VI Lua runtime resolves them against the game
-- locale, which under Simplified Chinese classifies byte 0xA0 as whitespace.
-- 0xA0 is also a UTF-8 continuation byte inside common characters (e.g. 张 =
-- E5 BC A0), so %s/%S trimming or splitting can slice a multibyte character and
-- corrupt it into the replacement character. All whitespace handling below uses
-- explicit ASCII byte sets instead.
--
-- Each registered icon has a spoken form (resolved from a LOC_ key or a
-- literal string) and an optional list of adjacency aliases. ProcessText
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

-- Generic composition helpers preserve markup; ProcessText remains the final
-- speech filter. Screen-specific choice of content stays with its owning screen.
CAIText = {}

function CAIText.ResolveLabel(value)
    return type(value) == "function" and value() or value or ""
end

function CAIText.SafeKey(value)
    return (tostring(value or ""):gsub("[^%w_]", "_"))
end

function CAIText.FormatNumberOrText(value)
    if type(value) == "number" then
        return Locale.ToNumber(value, "#,###.##")
    end
    return tostring(value)
end

function CAIText.FormatBalance(value)
    return Locale.ToNumber(value, "#,###.#")
end

function CAIText.FormatRatePerTurn(value)
    return Locale.Lookup("LOC_HUD_REPORTS_PER_TURN", value)
end

function CAIText.FormatSignedValue(value)
    if value == 0 then return Locale.ToNumber(value) end
    return Locale.Lookup("{1: number +#,###.#;-#,###.#}", value)
end

-- Consumes the final element, matching the existing promotion-list contract.
function CAIText.JoinWithConjunction(names, conjunctionTag)
    if #names <= 1 then return table.concat(names) end
    local finalName = table.remove(names)
    return table.concat(names, "[NEWLINE]") .. ", " .. Locale.Lookup(conjunctionTag) .. " " .. finalName
end

---@param value any
---@return string
function CAIText.ToString(value)
    if not value then return "" end
    return tostring(value)
end

---@param parts table
---@param value string|number|nil
function CAIText.AppendIfNonEmpty(parts, value)
    if value and value ~= "" then parts[#parts + 1] = value end
end

---@param parts table
---@param separator string|nil Defaults to an empty separator, matching table.concat.
---@return string
function CAIText.JoinNonEmpty(parts, separator)
    local filtered = {}
    for _, part in ipairs(parts) do
        CAIText.AppendIfNonEmpty(filtered, part)
    end
    return table.concat(filtered, separator)
end

---@param parts table|nil
---@param separator string|nil Defaults to Civ VI's newline token.
---@return string
function CAIText.JoinLines(parts, separator)
    return CAIText.JoinNonEmpty(parts or {}, separator or "[NEWLINE]")
end

-- Preserve intentional empty lines in already assembled text.
function CAIText.ConcatLines(parts)
    return table.concat(parts, "[NEWLINE]")
end

function CAIText.SplitTokenLines(text)
    return CAIText.SplitNonEmpty(text, "[NEWLINE]")
end

function CAIText.AppendLine(text, line)
    local base, extra = text or "", line or ""
    if extra == "" then return base end
    if base == "" then return extra end
    return base .. "[NEWLINE]" .. extra
end

function CAIText.AppendDistinctLine(text, line)
    if line == text then return text or "" end
    return CAIText.AppendLine(text, line)
end

function CAIText.TrimNonbreakingWhitespace(text)
    return CAIText.TrimAscii((tostring(text or ""):gsub("\194\160", " ")))
end

function CAIText.LabelValue(label, value, separator)
    if label and label ~= "" and value and value ~= "" then
        return label .. (separator or ": ") .. value
    end
    return label or value
end

function CAIText.AppendText(parts, value)
    CAIText.AppendIfNonEmpty(parts, CAIText.ToString(value))
end

-- Flatten nested readout fragments while preserving their order and values.
function CAIText.AppendFragments(parts, value)
    if type(value) == "table" then
        for _, innerValue in ipairs(value) do CAIText.AppendFragments(parts, innerValue) end
    elseif value ~= nil and value ~= "" then
        parts[#parts + 1] = value
    end
end

function CAIText.AppendUnique(parts, seen, value)
    local text = CAIText.TrimOptional(value)
    if text == nil or seen[text] then return end
    seen[text] = true
    parts[#parts + 1] = text
end

function CAIText.AppendSection(lines, title, entries)
    if not entries or #entries == 0 then return end
    CAIText.AppendIfNonEmpty(lines, title)
    for _, entry in ipairs(entries) do CAIText.AppendText(lines, entry) end
end

-- Accept values needing tostring conversion as well as preformatted strings.
function CAIText.JoinTextLines(parts)
    local converted = {}
    for _, part in ipairs(parts or {}) do CAIText.AppendText(converted, part) end
    return CAIText.JoinLines(converted)
end

---@param text string|nil
---@return string
function CAIText.NormalizeFormattedText(text)
    text = string.gsub(text or "", "%[NEWLINE%]", ", ")
    return (string.gsub(text, "[ \t\r\n]+", " "))
end

---@param text string|nil
---@return string
function CAIText.TrimAscii(text)
    return (string.gsub(text or "", "^[ \t\r\n]*(.-)[ \t\r\n]*$", "%1"))
end

function CAIText.TrimStart(text)
    return (string.gsub(text or "", "^[ \t\r\n\v\f]+", ""))
end

-- Includes vertical tab/form feed for callers previously using Lua's %s class.
function CAIText.TrimWhitespace(value)
    return (CAIText.ToString(value):gsub("^[ \t\r\n\v\f]*(.-)[ \t\r\n\v\f]*$", "%1"))
end

function CAIText.CollapseWhitespace(text)
    return (string.gsub(text or "", "[ \t\r\n]+", " "))
end

function CAIText.ToNewlineTokens(text)
    return (string.gsub(text or "", "\n", "[NEWLINE]"))
end

-- One pass intentionally collapses pairs, preserving the prior tooltip layout.
function CAIText.CollapseNewlinePairs(text)
    return (string.gsub(text or "", "%[NEWLINE%][ \t\r\n]*%[NEWLINE%]", "[NEWLINE]"))
end

-- Comparison form only: bracket tokens are separators, not spoken labels.
function CAIText.ComparisonText(text)
    text = string.gsub(text or "", "%[[^%]]*%]", " ")
    return CAIText.TrimAscii(CAIText.CollapseWhitespace(text))
end

-- Preserve the existing icon-free inline presentation used by crisis details.
function CAIText.PlainInlineText(value)
    local text = CAIText.ToString(value)
    text = text:gsub("%[ENDCOLOR%]", ""):gsub("%[COLOR_[^%]]+%]", "")
    text = text:gsub("%[COLOR:[ \t\r\n\v\f]*[^%]]+%]", "")
    text = text:gsub("%[NEWLINE%]", ", "):gsub("%[ICON_[^%]]+%]", "")
    text = text:gsub("[, \t\r\n\v\f]+,", ",")
    return (text:gsub("^[, \t\r\n\v\f]+", ""):gsub("[, \t\r\n\v\f]+$", ""))
end

-- Literal separator, omitting empty fields; suitable for stored delimited text.
function CAIText.SplitNonEmpty(value, separator)
    assert(separator ~= "", "Separator must not be empty")
    local text, parts, start = CAIText.ToString(value), {}, 1
    while true do
        local first, last = string.find(text, separator, start, true)
        if not first then
            CAIText.AppendIfNonEmpty(parts, string.sub(text, start))
            return parts
        end
        CAIText.AppendIfNonEmpty(parts, string.sub(text, start, first - 1))
        start = last + 1
    end
end

-- Horizontal trimming deliberately preserves line breaks and a nil input.
---@param text string|nil
---@return string|nil
function CAIText.TrimHorizontal(text)
    if text == nil then return nil end
    text = string.gsub(text, "^[ \t]+", "")
    return (string.gsub(text, "[ \t]+$", ""))
end

-- Optional control text: whitespace-only values represent absent content.
function CAIText.TrimOptional(value)
    if value == nil then return nil end
    local text = CAIText.TrimAscii(tostring(value))
    if text ~= "" then return text end
end

-- Split on LF and Civ VI newline tokens; trim each line and discard blanks.
-- Embedded CR is whitespace within a line, not a separate line boundary.
---@param text string|nil
---@return string[]
function CAIText.SplitFormattedLines(text)
    return CAIText.SplitLines(text, { trim = true, normalizeCarriageReturns = false })
end

---@param text string|nil
---@return string
function CAIText.NormalizeNewlines(text)
    text = string.gsub(text or "", "%[NEWLINE%]", "\n")
    text = string.gsub(text, "\r\n", "\n")
    return (string.gsub(text, "\r", "\n"))
end

-- Preserve indentation and whitespace-only lines; discard only empty lines.
---@param text string|nil
---@param options? { trim?: boolean, normalizeCarriageReturns?: boolean }
---@return string[]
function CAIText.SplitLines(text, options)
    local lines = {}
    local normalized
    if options and options.normalizeCarriageReturns == false then
        normalized = string.gsub(text or "", "%[NEWLINE%]", "\n")
    else
        normalized = CAIText.NormalizeNewlines(text)
    end
    for line in string.gmatch(normalized .. "\n", "(.-)\n") do
        if options and options.trim then line = CAIText.TrimAscii(line) end
        CAIText.AppendIfNonEmpty(lines, line)
    end
    return lines
end

function CAIText.JoinTooltipLines(text)
    if not text or text == "" then return text end
    return CAIText.JoinLines(CAIText.SplitLines(text))
end

-- Blank lines delimit sections; indentation remains part of each line.
function CAIText.SplitSections(text)
    local sections, current = {}, {}
    for line in string.gmatch(CAIText.NormalizeNewlines(text) .. "\n", "(.-)\n") do
        if line == "" then
            if #current > 0 then sections[#sections + 1] = current; current = {} end
        else
            current[#current + 1] = line
        end
    end
    if #current > 0 then sections[#sections + 1] = current end
    return sections
end

-- Literal-token splitting preserves empty fields and all native line endings.
---@param text string
---@return string[]
function CAIText.SplitNewlineToken(text)
    local lines = {}
    local pos = 1
    while true do
        local first, last = string.find(text, "[NEWLINE]", pos, true)
        if not first then
            lines[#lines + 1] = string.sub(text, pos)
            return lines
        end
        lines[#lines + 1] = string.sub(text, pos, first - 1)
        pos = last + 1
    end
end

-- Values are localized keys, literal replacements, empty decorative tokens,
-- or false for fixed output handled by DIRECT_OUTPUT.
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
    ["Culture"]        = { "LOC_CAI_ICON_CULTURE_ALIAS_CULTURAL" },
    ["Culture_Large"]  = { "LOC_CAI_ICON_CULTURE_ALIAS_CULTURAL" },
    ["CULTURE"]        = { "LOC_CAI_ICON_CULTURE_ALIAS_CULTURAL" },
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

    -- Bare yield tokens without the YIELD_ prefix. Vanilla text uses mixed-case
    -- yield icons (e.g. [ICON_Production]) that are covered by REPLACEMENTS, but
    -- other content can emit the ALLCAPS form ([ICON_PRODUCTION], [ICON_GOLD]).
    -- Resolve those against GameInfo.Yields so they speak instead of dropping.
    if GameInfo.Yields then
        local row = GameInfo.Yields["YIELD_" .. iconName]
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

-- ASCII-safe speech tidy-up. Applied as the final step for spoken output so
-- individual screens never have to collapse whitespace or commas themselves.
-- Uses explicit ASCII whitespace bytes only (see the locale note at the top);
-- lone commas (e.g. "1,000") and newlines are preserved.
local function NormalizeSpeechText(text)
    text = text:gsub("[ \t]+", " ")        -- collapse horizontal whitespace runs
    text = text:gsub(" *\n *", "\n")       -- trim spaces around newlines
    text = text:gsub("[, \t\r\n]+,", ",")  -- collapse comma/whitespace clusters
    text = text:gsub("^[, \t\r\n]+", "")   -- trim leading whitespace/commas
    text = text:gsub("[, \t\r\n]+$", "")   -- trim trailing whitespace/commas
    return text
end

---Replaces any Civ VI bracket token ([text]) with a matching spoken form, or
---removes it when no replacement exists. When the spoken form or a collapse
---alias appears adjacent to the bracket, the icon collapses (adjacent label
---stays, icon is redundant). This is the single text-filtering entry point for
---the screen reader -- do not replicate tag stripping or whitespace tidy in
---individual screens.
---@param text string
---@param tidy? boolean Apply ASCII-safe speech whitespace/comma tidy-up. Default
---true. Pass false to preserve layout (e.g. multi-line edit-box display).
---@return string
function ProcessText(text, tidy)
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

    local processed = TransliterateForEnglishTTS(table.concat(result))
    if tidy ~= false then
        processed = NormalizeSpeechText(processed)
    end
    return processed
end

local function IsSentenceEnd(word)
    return word:match("[%.%!%?][\"')%]]*$") ~= nil
end

function CAIText.SplitTextIntoLines(text, maxLength)
    local lines = {}
    if text == nil then return lines end

    maxLength = math.max(1, math.floor(tonumber(maxLength) or 75))
    local normalized = tostring(text):gsub("\r\n", "\n"):gsub("\r", "\n")
    normalized = normalized:gsub("%[NEWLINE%]", "\n")

    for paragraph in (normalized .. "\n"):gmatch("(.-)\n") do
        paragraph = CAIText.TrimAscii(paragraph)
        if paragraph ~= "" then
            local sentenceWords = {}
            local pendingLine = ""

            local function FlushSentence()
                if #sentenceWords == 0 then return end
                local sentence = table.concat(sentenceWords, " ")
                local combined = pendingLine == "" and sentence or pendingLine .. " " .. sentence
                if pendingLine == "" or #combined <= maxLength then
                    pendingLine = combined
                else
                    lines[#lines + 1] = pendingLine
                    pendingLine = sentence
                end
                sentenceWords = {}
            end

            -- Split on ASCII whitespace only; %S is locale-sensitive and would
            -- break on byte 0xA0 inside multibyte characters. Scripts without
            -- spaces (e.g. Chinese) stay whole, which is fine for speech.
            for word in paragraph:gmatch("[^ \t\r\n]+") do
                sentenceWords[#sentenceWords + 1] = word
                if IsSentenceEnd(word) then FlushSentence() end
            end
            FlushSentence()
            if pendingLine ~= "" then lines[#lines + 1] = pendingLine end
        end
    end

    return lines
end

function CAIText.AppendUniqueLine(text, line)
	if line == nil or line == "" then return text or "" end
	local existing = text or ""
	local normalizedLine = CAIText.NormalizeMultiline(line)
	if normalizedLine == "" then return existing end
	local normalizedExisting = CAIText.NormalizeMultiline(existing)
	if normalizedExisting == normalizedLine then return existing end
	for _, existingLine in ipairs(CAIText.SplitTokenLines(existing)) do
		if CAIText.NormalizeMultiline(existingLine) == normalizedLine then
			return existing
		end
	end
	if existing == "" then return line end
	return existing .. "[NEWLINE]" .. line
end

function CAIText.NormalizeMultiline(text)
	text = CAIText.StripColors(text)
	text = text:gsub("%[NEWLINE%]", "\n")
	text = text:gsub("\r", "")
	text = text:gsub("[ \t]+", " ")
	text = text:gsub(" *\n *", "\n")
	-- ASCII whitespace only; %s is locale-sensitive and corrupts UTF-8 (0xA0).
	text = text:gsub("^[ \t\r\n]+", "")
	text = text:gsub("[ \t\r\n]+$", "")
	return text
end

function CAIText.StripColors(text)
	if text == nil then return "" end
	text = tostring(text)
	text = text:gsub("%[COLOR[^%]]*%]", "")
	text = text:gsub("%[ENDCOLOR%]", "")
	return text
end
