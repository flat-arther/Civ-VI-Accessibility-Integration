-- ===========================================================================
--  CAIWidgetHelpers_TooltipReader
--
--  Provides section-by-section reading of widget tooltips.
--
--  When a widget receives focus, the widget caches its tooltip split into
--  individual sections using the "[NEWLINE]" token. The helper then exposes
--  navigation functions for reading the previous, next, first and last
--  section. Navigation clamps to the beginning/end of the tooltip, causing
--  the current edge section to be reread if the user attempts to move past it.
--
--  Widgets with no tooltip simply announce that a tooltip is unavailable.
-- ===========================================================================

CAIWidgetHelpers_TooltipReader = {}
local T = CAIWidgetHelpers_TooltipReader

local TOOLTIP_UNAVAILABLE = "LOC_CAI_TOOLTIP_UNAVAILABLE"

--#region Helpers

local function Trim(text)
    return text:match("^%s*(.-)%s*$")
end

local function SplitTooltipIntoSections(text)
    local sections = {}

    if not text or text == "" then
        return sections
    end

    -- Add a trailing delimiter so the final section is captured naturally.
    text = text .. "[NEWLINE]"

    for section in text:gmatch("(.-)%[NEWLINE%]") do
        section = Trim(section)
        if section ~= "" then
            sections[#sections + 1] = section
        end
    end

    return sections
end

local function SpeakCurrentTooltipSection(widget)
    if not widget._ttSections or #widget._ttSections == 0 then
        Speak(Locale.Lookup(TOOLTIP_UNAVAILABLE))
        return true
    end

    Speak(widget._ttSections[widget._ttSection])
    return true
end

--#endregion

--#region Cache Management

---Builds and caches the tooltip for a widget as individual sections.
---@param widget UIWidget
function T.CacheTooltipSections(widget)
    local tooltip = nil
    if widget.Type == "StaticText" then
        tooltip = widget:BuildSpeech({ "label" })
    else
        tooltip = widget:GetInfoStrings()
        ["tooltip"]                                  -- Use this to still show tooltips in the readers even if speak tooltips is disabled
    end

    widget._ttSections = SplitTooltipIntoSections(tooltip)
    widget._ttSection = 1
end

---Clears any cached tooltip information.
---@param widget UIWidget
function T.ClearTooltipSections(widget)
    widget._ttSections = nil
    widget._ttSection = nil
end

--#endregion

--#region Navigation

---Reads the next tooltip section, clamping at the final section.
---@param widget UIWidget
---@return boolean
function T.ReadNextTooltipSection(widget)
    if widget._ttSections then
        widget._ttSection = math.min(widget._ttSection + 1, #widget._ttSections)
    end

    return SpeakCurrentTooltipSection(widget)
end

---Reads the previous tooltip section, clamping at the first section.
---@param widget UIWidget
---@return boolean
function T.ReadPreviousTooltipSection(widget)
    if widget._ttSections then
        widget._ttSection = math.max(widget._ttSection - 1, 1)
    end

    return SpeakCurrentTooltipSection(widget)
end

---Reads the first tooltip section.
---@param widget UIWidget
---@return boolean
function T.ReadFirstTooltipSection(widget)
    if widget._ttSections then
        widget._ttSection = 1
    end

    return SpeakCurrentTooltipSection(widget)
end

---Reads the last tooltip section.
---@param widget UIWidget
---@return boolean
function T.ReadLastTooltipSection(widget)
    if widget._ttSections then
        widget._ttSection = #widget._ttSections
    end

    return SpeakCurrentTooltipSection(widget)
end

--#endregion
