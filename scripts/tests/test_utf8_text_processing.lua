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
local originalGmatch = string.gmatch

-- Civ VI's locale-sensitive %S classifies byte 0xA0 as whitespace. Several
-- valid Chinese UTF-8 sequences contain that byte, so model the game runtime.
string.gmatch = function(value, pattern)
    if pattern == "%S+" then
        return originalGmatch(value, "[^\160 \t\r\n]+")
    end
    return originalGmatch(value, pattern)
end

local lines = SplitTextIntoLines(text, 75)
string.gmatch = originalGmatch

assertEqual(#lines, 1, "line count")
assertEqual(lines[1], text, "UTF-8 text must survive line splitting")
assert(utf8.len(lines[1]) ~= nil, "split text must remain valid UTF-8")
print("UTF-8 text processing tests passed")
