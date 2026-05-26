-- CAIWidget_Panel.lua

---@class PanelWidget : ContainerWidget
PanelWidget = setmetatable({}, { __index = ContainerWidget })
PanelWidget.__index = PanelWidget

---@param mgr UIScreenManager
---@param id string
---@param props? table
---@return PanelWidget
function PanelWidget.Create(mgr, id, props)
    local w = ContainerWidget.New(PanelWidget)
    w.Id = id
    w.Type = "Panel"
    w.Role = "Panel"
    w.Manager = mgr
    w:AddInputBindings({
        { Key = Keys.VK_TAB, MSG = KeyEvents.KeyDown,                Action = function(self) return self:NavigateNext() end },
        { Key = Keys.VK_TAB, MSG = KeyEvents.KeyDown, IsShift = true, Action = function(self) return self:NavigatePrev() end },
    })
    CAIWidgetRegistry.ApplyProps(w, props)
    return w
end

CAIWidgetRegistry.Register("Panel", PanelWidget.Create)
