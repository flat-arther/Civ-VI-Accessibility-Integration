local spoken = {}

Speak = function(text)
    spoken[#spoken + 1] = text
end

SpeakLines = function(lines)
    for _, line in ipairs(lines) do Speak(line) end
end

Locale = {
    Lookup = function(tag, value)
        if tag == "LOC_CAI_EDIT_BLANK" then return "blank" end
        return tostring(value or tag)
    end,
}

dofile("src/UI/uiManager/helpers/CAIWidgetHelpers_EditBox.lua")

ValueWidget = { __index = {} }
function ValueWidget.New(class)
    return setmetatable({}, { __index = class })
end
function ValueWidget.SetValue() end
CAIWidgetRegistry = { ApplyProps = function() end, Register = function() end }
ProcessIcons = function(text) return text end
KeyEvents = { KeyDown = 1 }
Keys = { VK_RETURN = 13, VK_ESCAPE = 27, VK_BACK = 8, VK_DELETE = 46, C = 67, V = 86, A = 65,
    VK_LEFT = 37, VK_RIGHT = 39, VK_UP = 38, VK_DOWN = 40, VK_HOME = 36, VK_END = 35 }
UIManager = { SetClipboardString = function(_, text) _G.clipboard = text end }
CAI = { GetClipboardText = function() return "" end }

dofile("src/UI/uiManager/CAIWidget_EditBox.lua")

local function resetSpeech()
    spoken = {}
end

local function newWidget(text)
    return {
        _buffer = text,
        _cursor = 0,
        _selStart = nil,
        _passwordMask = false,
    }
end

local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s: expected %q, got %q", message, expected, actual))
    end
end

local function testRightArrowSpeaksWholeChineseCharacter()
    local widget = newWidget("研究")
    resetSpeech()
    CAIWidgetHelpers_EditBox.MoveCursor(widget, 1, false, false)
    assertEqual(widget._cursor, #"研", "right arrow cursor boundary")
    assertEqual(spoken[1], "究", "right arrow speech")
end

local function testDeleteRemovesWholeChineseCharacter()
    local widget = newWidget("研究")
    resetSpeech()
    local deleted = CAIWidgetHelpers_EditBox.DeleteChar(widget)
    assertEqual(deleted, "研", "delete result")
    assertEqual(widget._buffer, "究", "delete buffer")
end

local function testLeftArrowReturnsToPreviousCharacterBoundary()
    local widget = newWidget("研究")
    widget._cursor = #"研"
    resetSpeech()
    CAIWidgetHelpers_EditBox.MoveCursor(widget, -1, false, false)
    assertEqual(widget._cursor, 0, "left arrow cursor boundary")
    assertEqual(spoken[1], "研", "left arrow speech")
end

local function testBackspaceRemovesWholeChineseCharacter()
    local widget = newWidget("研究")
    widget._cursor = #"研"
    local deleted = CAIWidgetHelpers_EditBox.BackspaceChar(widget)
    assertEqual(deleted, "研", "backspace result")
    assertEqual(widget._buffer, "究", "backspace buffer")
    assertEqual(widget._cursor, 0, "backspace cursor boundary")
end

local function testMaxCharactersCountsCodePoints()
    local widget = newWidget("")
    widget._maxChars = 2
    assert(CAIWidgetHelpers_EditBox.InsertText(widget, "研究生"), "insert within code-point limit")
    assertEqual(widget._buffer, "研究", "max character buffer")
end

local function testShiftSelectionContainsWholeCharacter()
    local widget = newWidget("研究")
    resetSpeech()
    CAIWidgetHelpers_EditBox.MoveCursor(widget, 1, true, false)
    assertEqual(widget._selStart, 0, "selection anchor")
    assertEqual(widget._cursor, #"研", "selection cursor boundary")
    assertEqual(CAIWidgetHelpers_EditBox.GetSelectedText(widget), "研", "selected text")
end

local function testAsciiNavigationIsUnchanged()
    local widget = newWidget("abc")
    resetSpeech()
    CAIWidgetHelpers_EditBox.MoveCursor(widget, 1, false, false)
    assertEqual(widget._cursor, 1, "ASCII cursor")
    assertEqual(spoken[1], "b", "ASCII speech")
end

local function testLineMovementNeverStopsInsideChineseCharacter()
    local text = "甲乙\nA研究"
    local target = CAIWidgetHelpers_EditBox.NextLinePos(text, #"甲")
    local prefix = string.sub(text, 1, target)
    assert(utf8.len(prefix) ~= nil, "line movement must end on a UTF-8 boundary")
end

local function testLineMovementUsesCodePointColumns()
    local text = "中文\nab中"
    local afterAb = #"中文\nab"
    assertEqual(CAIWidgetHelpers_EditBox.PrevLinePos(text, afterAb), #"中文",
        "vertical movement must preserve code-point column")
end

local function testPasswordMaskAndCharacterCountUseCodePoints()
    local widget = newWidget("研究")
    widget._passwordMask = true
    assertEqual(CAIWidgetHelpers_EditBox.GetCharacterCount(widget._buffer), 2,
        "Chinese character count")
    assertEqual(CAIWidgetHelpers_EditBox.MaskText(widget, widget._buffer), "**",
        "password mask character count")
end

local function testEditBoxCopyReadsWholeCharacter()
    local widget = newWidget("研究")
    widget._active = true
    widget._cursor = 0
    clipboard = nil
    spoken = {}
    local copyBinding
    for _, binding in ipairs(EditBoxWidget._BuildBindings()) do
        if binding.Key == Keys.C and binding.IsControl then
            copyBinding = binding
            break
        end
    end
    assert(copyBinding ~= nil, "copy binding must exist")
    copyBinding.Action(widget)
    assertEqual(clipboard, "研", "copy must preserve complete UTF-8 character")
end

testRightArrowSpeaksWholeChineseCharacter()
testDeleteRemovesWholeChineseCharacter()
testLeftArrowReturnsToPreviousCharacterBoundary()
testBackspaceRemovesWholeChineseCharacter()
testMaxCharactersCountsCodePoints()
testShiftSelectionContainsWholeCharacter()
testAsciiNavigationIsUnchanged()
testLineMovementNeverStopsInsideChineseCharacter()
testLineMovementUsesCodePointColumns()
testPasswordMaskAndCharacterCountUseCodePoints()
testEditBoxCopyReadsWholeCharacter()
print("editbox UTF-8 tests passed")
