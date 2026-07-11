-- CAIWidget_StaticText.lua

---@class StaticTextWidget : UIWidget
StaticTextWidget = setmetatable({}, { __index = UIWidget })
StaticTextWidget.__index = StaticTextWidget

---@param mgr UIScreenManager
---@param id string
---@param props? table
---@return StaticTextWidget
function StaticTextWidget.Create(mgr, id, props)
    local w = UIWidget.New(StaticTextWidget)
    w.Id = id
    w.Type = "StaticText"
    w.Role = "StaticText"
    w.Manager = mgr
    w.SpeechSettings = { Role = false }
    CAIWidgetRegistry.ApplyProps(w, props)
    return w
end

---Static text has no secondary tooltip channel. Any tooltip supplied by a
---screen is part of the text itself and follows the primary label on a new
---line. Keeping this invariant here also covers generic screen helpers that
---forward property tables to CreateWidget.
---@return string
function StaticTextWidget:GetLabel()
    local label = UIWidget.GetLabel(self) or ""
    local tooltip = UIWidget.GetTooltip(self) or ""
    if tooltip == "" or tooltip == label then return label end
    if label == "" then return tooltip end
    return label .. "[NEWLINE]" .. tooltip
end

---@return string
function StaticTextWidget:GetTooltip()
    return ""
end

CAIWidgetRegistry.Register("StaticText", StaticTextWidget.Create)
