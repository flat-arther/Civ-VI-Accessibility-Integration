-- CAIWidget_Container.lua
-- ContainerWidget: navigable parent for child widgets.

---@class ContainerWidget : UIWidget
---@field WrapAround boolean
---@field DefaultIndex integer
---@field PageSize integer
ContainerWidget = setmetatable({}, { __index = UIWidget })
ContainerWidget.__index = ContainerWidget

local Nav = CAIWidgetHelpers_Navigation

---Subclass constructor entry point.
---@param class table
---@return ContainerWidget
function ContainerWidget.New(class)
    local w = UIWidget.New(class)
    w.WrapAround = true
    w.DefaultIndex = 1
    w.PageSize = 10
    return w
end

---@param b boolean
function ContainerWidget:SetWrapAround(b) self.WrapAround = b and true or false end

---@param n integer
function ContainerWidget:SetPageSize(n) self.PageSize = n end

---Resolve the child this container should focus when entered.
---@return UIWidget|nil
function ContainerWidget:GetDefaultChild()
    return Nav.DefaultChild(self)
end

---Direction-aware entry: forward (1) lands on the first visible child,
---backward (-1) on the last, neutral (nil/0) on the cached default.
---@param direction 1|-1|0|nil
---@return UIWidget|nil
function ContainerWidget:GetEntryChild(direction)
    return Nav.EntryChild(self, direction)
end

---@param direction 1|-1
---@return boolean
function ContainerWidget:Navigate(direction) return Nav.Navigate(self, direction) end

function ContainerWidget:NavigateNext() return Nav.Navigate(self, 1) end
function ContainerWidget:NavigatePrev() return Nav.Navigate(self, -1) end
function ContainerWidget:NavigateToFirst() return Nav.NavigateToFirst(self) end
function ContainerWidget:NavigateToLast() return Nav.NavigateToLast(self) end

---@param direction 1|-1
---@return boolean
function ContainerWidget:NavigatePage(direction) return Nav.NavigatePage(self, direction, self.PageSize) end
