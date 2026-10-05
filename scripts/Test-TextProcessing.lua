-- Exercise the real composition helpers, including distinct tooltip layouts.
dofile("src/UI/shared/textProcessing.lua")
local assertions = 0
local function check(actual, expected, label)
    assertions = assertions + 1
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function lines(actual, expected, label)
    check(#actual, #expected, label .. " count")
    for i, value in ipairs(expected) do check(actual[i], value, label .. " " .. i) end
end
check(CAIText.ToString(nil), "", "absent text")
check(CAIText.ToString(false), "", "false text")
check(CAIText.ToString(0), "0", "numeric text")
check(CAIText.ResolveLabel(function() return "live" end), "live", "dynamic label")
check(CAIText.ResolveLabel(nil), "", "missing label")
check(CAIText.SafeKey("custom:2-a"), "custom_2_a", "stored key format")
check(CAIText.ConcatLines({ "a", "", "b" }), "a[NEWLINE][NEWLINE]b", "intentional blank lines")
check(CAIText.AppendLine("a", "a"), "a[NEWLINE]a", "repeated explanation allowed")
check(CAIText.AppendDistinctLine("a", "a"), "a", "identical explanation omitted")
check(CAIText.TrimNonbreakingWhitespace("\194\160张\194\160"), "张", "credits nonbreaking spaces")
lines(CAIText.SplitTokenLines("a\nb[NEWLINE]c"), { "a\nb", "c" }, "token-only split")
check(CAIText.NormalizeMultiline("[COLOR_RED] a  b [ENDCOLOR][NEWLINE] c\r "), "a b\nc", "multiline comparison")
check(CAIText.AppendUniqueLine("[COLOR_RED]a[ENDCOLOR]", "a"), "[COLOR_RED]a[ENDCOLOR]", "normalized duplicate line")
lines(CAIText.SplitTextIntoLines("One. Two. Three.", 10), { "One. Two.", "Three." }, "sentence grouping")
lines(CAIText.SplitTextIntoLines("This sentence is longer than the limit.", 5), { "This sentence is longer than the limit." }, "long sentence stays intact")
lines(CAIText.SplitTextIntoLines(" 张\r\n b[NEWLINE]c ", 0), { "张", "b", "c" }, "paragraph boundaries")
lines(CAIText.SplitTextIntoLines(nil), {}, "missing speech text")
check(CAIText.LabelValue("a", "b"), "a: b", "label separator")
check(CAIText.LabelValue("a", "b", " "), "a b", "custom label separator")
check(CAIText.LabelValue(nil, "b"), "b", "missing label")
check(CAIText.TrimStart(" \v\f张 "), "张 ", "leading ASCII whitespace")
check(CAIText.JoinNonEmpty({ "a", "", "b" }), "ab", "concat default")
check(CAIText.JoinNonEmpty({ "a", "", 0 }, ", "), "a, 0", "separator")
check(CAIText.JoinLines(nil), "", "absent lines")
check(CAIText.JoinLines({ "a", "", "b" }), "a[NEWLINE]b", "markup preserved")
check(CAIText.JoinTextLines({ 0, false, "b" }), "0[NEWLINE]b", "converted lines")
local parts = {}
CAIText.AppendIfNonEmpty(parts, nil)
CAIText.AppendIfNonEmpty(parts, "")
CAIText.AppendIfNonEmpty(parts, 0)
CAIText.AppendText(parts, false)
lines(parts, { 0 }, "append")
check(CAIText.TrimAscii(" \t张\r\n"), "张", "UTF-8 safe trim")
check(CAIText.TrimHorizontal(nil), nil, "optional horizontal text")
check(CAIText.TrimHorizontal(" \t张\r\n "), "张\r\n", "preserve vertical whitespace")
check(CAIText.TrimOptional(" \r\n"), nil, "blank control text")
check(CAIText.TrimOptional(false), "false", "optional value conversion")
check(CAIText.NormalizeFormattedText("a[NEWLINE]  b"), "a, b", "inline formatting")
lines(CAIText.SplitLines("a\r\nb\rc[NEWLINE]  d\n\n"), { "a", "b", "c", "  d" }, "normalized lines")
lines(CAIText.SplitLines("a\r\nb\rc", { normalizeCarriageReturns = false }), { "a\r", "b\rc" }, "raw carriage returns")
lines(CAIText.SplitLines(" a\r b\n \n张 ", { trim = true }), { "a", "b", "张" }, "trimmed normalized lines")
lines(CAIText.SplitFormattedLines(" a\r b\n \n张 "), { "a\r b", "张" }, "formatted lines")
lines(CAIText.SplitNewlineToken("[NEWLINE]a[NEWLINE]"), { "", "a", "" }, "empty literal fields")
local sections = CAIText.SplitSections("a\n\n  b\r\nc\n\n")
check(#sections, 2, "section count")
lines(sections[1], { "a" }, "first section")
lines(sections[2], { "  b", "c" }, "second section")
check(CAIText.JoinTooltipLines(nil), nil, "absent tooltip")
check(CAIText.JoinTooltipLines("a\r\n\n b"), "a[NEWLINE] b", "tooltip layout")
Locale = { Lookup = function(tag) return tag end, GetCurrentLanguage = function() return { Type = "zh_Hans_CN" } end }
check(ProcessText("[COLOR_RED]张[ENDCOLOR]"), "张", "final speech filter")
check(ProcessText("1,000"), "1,000", "numeric comma")
check(ProcessText("a[NEWLINE]b", false), "a, b", "newline token speech")
check(ProcessText("a\nb", false), "a\nb", "edit box line breaks")

local fragments = {}
CAIText.AppendFragments(fragments, { "a", { "", "张", { 0, false } } })
lines(fragments, { "a", "张", 0, false }, "nested fragments")
local unique, seen = {}, {}
for _, value in ipairs({ " 张 ", "张", "", "  ", "é" }) do
    CAIText.AppendUnique(unique, seen, value)
end
lines(unique, { "张", "é" }, "unique trimmed fragments")
local section = {}
CAIText.AppendSection(section, "unused", {})
CAIText.AppendSection(section, "heading", { "", 0, false, "body" })
lines(section, { "heading", "0", "body" }, "section conversion")
check(CAIText.TrimWhitespace("\v 张 \f"), "张", "full ASCII trim")
check(CAIText.ToNewlineTokens("a\r\nb[NEWLINE]c"), "a\r[NEWLINE]b[NEWLINE]c", "token conversion preserves CR")
check(CAIText.CollapseNewlinePairs("[NEWLINE] [NEWLINE][NEWLINE]"), "[NEWLINE][NEWLINE]", "pairwise collapse")
check(CAIText.ComparisonText(" [COLOR_RED]张[ENDCOLOR]\n text "), "张 text", "comparison normalization")
check(CAIText.PlainInlineText("[COLOR:Red]张[ENDCOLOR][NEWLINE][ICON_Gold] 1,000"), "张,  1,000", "plain inline display")
lines(CAIText.SplitNonEmpty(",a,,b,", ","), { "a", "b" }, "stored list fields")
lines(CAIText.SplitNonEmpty("a.*b.*", ".*"), { "a", "b" }, "literal separator")
Locale.ToNumber = function(value, format) return tostring(value) .. (format or "") end
Locale.Lookup = function(tag, value) return tag .. (value and tostring(value) or "") end
check(CAIText.FormatBalance(12), "12#,###.#", "balance format")
check(CAIText.FormatSignedValue(0), "0", "unsigned zero")
check(CAIText.FormatSignedValue(-2), "{1: number +#,###.#;-#,###.#}-2", "signed format")
check(CAIText.FormatRatePerTurn(2), "LOC_HUD_REPORTS_PER_TURN2", "rate format")
local names = { "a", "b", "c" }
check(CAIText.JoinWithConjunction(names, "and"), "a[NEWLINE]b, and c", "conjunction format")
lines(names, { "a", "b" }, "conjunction consumes last name")

-- Compile migrated callers; erase only known Firaxis parameter annotations.
for _, path in ipairs(arg) do
    local file = assert(io.open(path, "rb"))
    local source = file:read("a"); file:close()
    -- Frontend replacements retain annotated Firaxis code. Check the authored
    -- accessibility block without pretending to transpile every vanilla dialect.
    if path:find("frontEnd", 1, true) then
        local integration = source:find("--#Accessibility integration", 1, true)
        if integration then source = source:sub(integration) end
    end
    for _, kind in ipairs({ "table", "number", "string", "boolean", "ifunction", "object" }) do
        source = source:gsub("([%w_]+)%s*:%s*" .. kind .. "(%s*[,)=;])", "%1%2")
        source = source:gsub("([%w_]+)%s*:%s*" .. kind .. "(%s+in%s+)", "%1%2")
    end
    local chunk, message = load(source, "@" .. path)
    check(chunk ~= nil, true, "syntax " .. path .. ": " .. tostring(message))
end
print("Text processing: " .. assertions .. " assertions passed")
