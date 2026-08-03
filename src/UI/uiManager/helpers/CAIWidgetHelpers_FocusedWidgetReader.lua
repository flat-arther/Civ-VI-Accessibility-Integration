-- ===========================================================================
--  CAIWidgetHelpers_FocusedWidgetReader
--
--  Provides section-by-section reading of the focused widget's content.
--
--  When a widget receives focus, the widget caches its eligible speech content
--  in the same canonical order used by BuildSpeech(). Role, state, and position
--  are intentionally excluded. The combined content is split into
--  natural spoken sections using SplitTextIntoLines(). The helper then exposes
--  navigation functions for moving to the previous, next, first and last
--  section. Navigation clamps to the beginning/end, causing the current edge
--  section to be reread if the user attempts to move past it.
--
--  Widgets with no readable content announce that focused-widget information
--  is unavailable.
-- ===========================================================================

CAIWidgetHelpers_FocusedWidgetReader = {}
local R = CAIWidgetHelpers_FocusedWidgetReader

local CONTENT_UNAVAILABLE = "LOC_CAI_FOCUSED_WIDGET_READER_UNAVAILABLE"
local EXCLUDED_SPEECH_ELEMENTS = { role = true, state = true, position = true }

--#region Helpers

---@param widget UIWidget
---@return string[]
local function GetReaderSpeechElements(widget)
    local elements = {}
    for _, key in ipairs(widget:GetSpeechOrder()) do
        if not EXCLUDED_SPEECH_ELEMENTS[key] then
            elements[#elements + 1] = key
        end
    end
    return elements
end

---@param widget UIWidget
---@return string|nil
local function BuildReaderContent(widget)
    local info = widget:GetInfoStrings()
    local parts = {}
    for _, key in ipairs(GetReaderSpeechElements(widget)) do
        if info[key] then parts[#parts + 1] = info[key] end
    end
    if #parts == 0 then return nil end
    return table.concat(parts, "[NEWLINE]")
end

local function SpeakCurrentSection(widget)
    if not widget._focusedWidgetReaderSections or #widget._focusedWidgetReaderSections == 0 then
        Speak(Locale.Lookup(CONTENT_UNAVAILABLE))
        return true
    end

    Speak(widget._focusedWidgetReaderSections[widget._focusedWidgetReaderSection])
    return true
end

--#endregion

--#region Cache Management

---Builds and caches the focused widget's readable content as individual sections.
---@param widget UIWidget
function R.CacheSections(widget)
    local content = BuildReaderContent(widget)
    widget._focusedWidgetReaderSections = SplitTextIntoLines(content)
    widget._focusedWidgetReaderSection = 1
end

---Clears any cached focused-widget information.
---@param widget UIWidget
function R.ClearSections(widget)
    widget._focusedWidgetReaderSections = nil
    widget._focusedWidgetReaderSection = nil
end

--#endregion

--#region Navigation

---Reads the next focused-widget section, clamping at the final section.
---@param widget UIWidget
---@return boolean
function R.ReadNextSection(widget)
    if widget._focusedWidgetReaderSections then
        widget._focusedWidgetReaderSection = math.min(
            widget._focusedWidgetReaderSection + 1,
            #widget._focusedWidgetReaderSections
        )
    end

    return SpeakCurrentSection(widget)
end

---Reads the previous focused-widget section, clamping at the first section.
---@param widget UIWidget
---@return boolean
function R.ReadPreviousSection(widget)
    if widget._focusedWidgetReaderSections then
        widget._focusedWidgetReaderSection = math.max(widget._focusedWidgetReaderSection - 1, 1)
    end

    return SpeakCurrentSection(widget)
end

---Reads the first focused-widget section.
---@param widget UIWidget
---@return boolean
function R.ReadFirstSection(widget)
    if widget._focusedWidgetReaderSections then
        widget._focusedWidgetReaderSection = 1
    end

    return SpeakCurrentSection(widget)
end

---Reads the last focused-widget section.
---@param widget UIWidget
---@return boolean
function R.ReadLastSection(widget)
    if widget._focusedWidgetReaderSections then
        widget._focusedWidgetReaderSection = #widget._focusedWidgetReaderSections
    end

    return SpeakCurrentSection(widget)
end

--#endregion
