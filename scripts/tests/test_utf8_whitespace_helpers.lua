include = function() end
ExposedMembers = {}

CAISettings = {
    GetNumber = function() return 75 end,
}

dofile("src/UI/shared/caiUtils.lua")

local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s: expected %q, got %q", message, expected, actual))
    end
end

local text = "张衡主张浑天说，他的成就奠定了基础。"
assertEqual(CAI_TrimAsciiWhitespace(" \t" .. text .. "\r\n"), text,
    "ASCII trimming must preserve UTF-8 bytes")
assertEqual(CAI_CollapseAsciiWhitespace("张衡  \t主张"), "张衡 主张",
    "ASCII whitespace collapse")

assertEqual(
    CAI_TrimAsciiWhitespace(" \t[COLOR:Red]张衡[ENDCOLOR]\r\n"),
    "[COLOR:Red]张衡[ENDCOLOR]",
    "color-marked tooltip trimming"
)
assertEqual(CAI_TrimAsciiWhitespace("\t  张衡主张浑天说"), "张衡主张浑天说",
    "report-line indentation trimming")
assertEqual(CAI_TrimAsciiWhitespace("  张衡观测点  "), "张衡观测点",
    "world-scanner custom name trimming")
assertEqual(CAI_CollapseAsciiWhitespace("南京  张衡"), "南京 张衡",
    "localized city and unit label collapse")

local words = CAI_SplitAsciiWords("张衡 --主张 浑天说")
assertEqual(#words, 3, "ASCII word count")
assertEqual(words[1], "张衡", "Chinese search word")
assertEqual(words[2], "--主张", "blacklist search word")
assertEqual(words[3], "浑天说", "following Chinese search word")

for _, word in ipairs(words) do
    assert(utf8.len(word) ~= nil, "split search word must remain valid UTF-8")
end

dofile("src/UI/uiManager/helpers/CAIWidgetHelpers_Search.lua")
local whitelist, blacklist = CAIWidgetHelpers_Search.ParseQuery("张衡 --主张 浑天说")
assertEqual(whitelist[1], "张衡", "search whitelist Chinese term")
assertEqual(whitelist[2], "浑天说", "search whitelist second term")
assertEqual(blacklist[1], "主张", "search blacklist Chinese term")

-- Model the Civ VI locale behavior that caused the original regression.
local originalGmatch = string.gmatch
string.gmatch = function(value, pattern)
    if pattern == "%S+" then
        return originalGmatch(value, "[^\160 \t\r\n]+")
    end
    return originalGmatch(value, pattern)
end
local lines = SplitTextIntoLines(text, 75)
string.gmatch = originalGmatch
assertEqual(lines[1], text, "line splitter must preserve Chinese text")

print("UTF-8 whitespace helper tests passed")
