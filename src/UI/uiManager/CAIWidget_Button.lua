-- CAIWidget_Button.lua

---@class ButtonWidget : UIWidget
ButtonWidget = setmetatable({}, { __index = UIWidget })
ButtonWidget.__index = ButtonWidget

---@param mgr UIScreenManager
---@param id string
---@param props? table
---@return ButtonWidget
function ButtonWidget.Create(mgr, id, props)
    local w = UIWidget.New(ButtonWidget)
    w.Id = id
    w.Type = "Button"
    w.Role = "Button"
    w.Manager = mgr
    w:AddInputBindings({
        { Key = Keys.VK_RETURN, MSG = KeyEvents.KeyUp, Description = "LOC_CAI_KB_ACTIVATE", Action = function(self) return self:Activate() end },
        { Key = Keys.VK_SPACE,                         Description = "LOC_CAI_KB_ACTIVATE", Action = function(self) return self:Activate() end },
    })
    CAIWidgetRegistry.ApplyProps(w, props)
    return w
end

---@return boolean
function ButtonWidget:Activate()
    if self:IsDisabled() then return true end
    self:Emit("activate")
    return true
end

CAIWidgetRegistry.Register("Button", ButtonWidget.Create)
