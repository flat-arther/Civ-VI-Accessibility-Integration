-- CAIWidget_InterfaceMode.lua
-- Container representing a specific vanilla interface mode. Swaps input
-- context to World on focus enter (so vanilla mode input routes correctly)
-- and back to Shell on focus leave.

---@class InterfaceModeWidget : ContainerWidget
InterfaceModeWidget = setmetatable({}, { __index = ContainerWidget })
InterfaceModeWidget.__index = InterfaceModeWidget

---@param mgr UIScreenManager
---@param id string
---@param props? table
---@return InterfaceModeWidget
function InterfaceModeWidget.Create(mgr, id, props)
    local w = ContainerWidget.New(InterfaceModeWidget)
    w.Id = id
    w.Type = "InterfaceMode"
    w.Role = "InterfaceMode"
    w.Manager = mgr

    w:On("focus_enter", function() Input.SetActiveContext(InputContext.World) end)
    w:On("focus_leave", function() Input.SetActiveContext(InputContext.Shell) end)

    CAIWidgetRegistry.ApplyProps(w, props)
    return w
end

CAIWidgetRegistry.Register("InterfaceMode", InterfaceModeWidget.Create)
