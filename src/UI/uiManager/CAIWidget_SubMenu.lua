-- CAIWidget_SubMenu.lua
-- Entered-child container: collapsed by default; Enter or Right expands and
-- focuses the first child; Left collapses and returns focus to the submenu node.
-- Up/Down navigates children only while expanded.

---@class SubMenuWidget : ContainerWidget
---@field IsExpanded boolean
SubMenuWidget = setmetatable({}, { __index = ContainerWidget })
SubMenuWidget.__index = SubMenuWidget

local Nav = CAIWidgetHelpers_Navigation

local function EnterFirstChild(self)
    local first = Nav.First(self)
    if not first then return false end
    self.IsExpanded = true
    self:Emit("expanded")
    self.Manager:SetFocus(first)
    return true
end

local function Collapse(self)
    if not self.IsExpanded then return false end
    self.IsExpanded = false
    self._lastFocusedChild = nil
    self:Emit("collapsed")
    self.Manager:SetFocus(self)
    return true
end

---@param mgr UIScreenManager
---@param id string
---@param props? table
---@return SubMenuWidget
function SubMenuWidget.Create(mgr, id, props)
    local w = ContainerWidget.New(SubMenuWidget)
    w.Id = id
    w.Type = "SubMenu"
    w.Role = "SubMenu"
    w.Manager = mgr
    w.IsExpanded = false

    w:AddInputBindings({
        { Key = Keys.VK_RETURN, Action = function(self) return EnterFirstChild(self) end },
        { Key = Keys.VK_RIGHT,  MSG = KeyEvents.KeyDown, Action = function(self) return EnterFirstChild(self) end },
        { Key = Keys.VK_LEFT,   MSG = KeyEvents.KeyDown, Action = function(self) return Collapse(self) end },
        { Key = Keys.VK_UP,     MSG = KeyEvents.KeyDown, Action = function(self) return self.IsExpanded and self:NavigatePrev() or false end },
        { Key = Keys.VK_DOWN,   MSG = KeyEvents.KeyDown, Action = function(self) return self.IsExpanded and self:NavigateNext() or false end },
        { Key = Keys.VK_HOME,   MSG = KeyEvents.KeyDown, Action = function(self) return self.IsExpanded and self:NavigateToFirst() or false end },
        { Key = Keys.VK_END,    MSG = KeyEvents.KeyDown, Action = function(self) return self.IsExpanded and self:NavigateToLast() or false end },
        { Key = Keys.VK_PRIOR,  MSG = KeyEvents.KeyDown, Action = function(self) return self.IsExpanded and self:NavigatePage(-1) or false end },
        { Key = Keys.VK_NEXT,   MSG = KeyEvents.KeyDown, Action = function(self) return self.IsExpanded and self:NavigatePage(1) or false end },
    })

    CAIWidgetRegistry.ApplyProps(w, props)
    return w
end

---Default-child resolution: only descend when expanded.
---@return UIWidget|nil
function SubMenuWidget:GetDefaultChild()
    if not self.IsExpanded then return nil end
    return ContainerWidget.GetDefaultChild(self)
end

---Direction-aware entry only applies when expanded; collapsed submenus are
---focus stops.
---@param direction 1|-1|0|nil
---@return UIWidget|nil
function SubMenuWidget:GetEntryChild(direction)
    if not self.IsExpanded then return nil end
    return ContainerWidget.GetEntryChild(self, direction)
end

CAIWidgetRegistry.Register("SubMenu", SubMenuWidget.Create)
