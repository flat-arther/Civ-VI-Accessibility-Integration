-- CAIWidget_MenuItem.lua

---@class MenuItemWidget : UIWidget
MenuItemWidget = setmetatable({}, { __index = UIWidget })
MenuItemWidget.__index = MenuItemWidget

---@param mgr UIScreenManager
---@param id string
---@param props? table
---@return MenuItemWidget
function MenuItemWidget.Create(mgr, id, props)
    local w = UIWidget.New(MenuItemWidget)
    w.Id = id
    w.Type = "MenuItem"
    w.Role = "MenuItem"
    w.Manager = mgr
    w.SpeechSettings = { Role = false }
    w:AddInputBindings({
        { Key = Keys.VK_RETURN, Description = "LOC_CAI_KB_ACTIVATE", Action = function(self) return self:Activate() end },
    })
    CAIWidgetRegistry.ApplyProps(w, props)
    return w
end

---@return boolean
function MenuItemWidget:Activate()
    if self:IsDisabled() then return true end
    self:Emit("activate")
    return true
end

CAIWidgetRegistry.Register("MenuItem", MenuItemWidget.Create)
