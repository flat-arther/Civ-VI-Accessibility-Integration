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

CAIWidgetRegistry.Register("StaticText", StaticTextWidget.Create)
