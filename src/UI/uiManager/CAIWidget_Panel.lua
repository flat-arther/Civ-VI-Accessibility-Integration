-- CAIWidget_Panel.lua

---@class PanelWidget : ContainerWidget
PanelWidget = setmetatable({}, { __index = ContainerWidget })
PanelWidget.__index = PanelWidget

local Nav = CAIWidgetHelpers_Navigation

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
        { Key = Keys.VK_TAB, MSG = KeyEvents.KeyDown,                Description = "LOC_CAI_KB_NEXT_CONTROL",     Action = function(self) return self:NavigateNext() end },
        { Key = Keys.VK_TAB, MSG = KeyEvents.KeyDown, IsShift = true, Description = "LOC_CAI_KB_PREVIOUS_CONTROL", Action = function(self) return self:NavigatePrev() end },
    })
    CAIWidgetRegistry.ApplyProps(w, props)
    return w
end

---@param direction 1|-1|0|nil
---@return UIWidget|nil
function PanelWidget:GetEntryChild(direction)
    if direction == 1 then return Nav.First(self) end
    if direction == -1 then return Nav.Last(self) end
    return Nav.DefaultChild(self)
end

CAIWidgetRegistry.Register("Panel", PanelWidget.Create)
