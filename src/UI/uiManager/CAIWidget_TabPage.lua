-- CAIWidget_TabPage.lua
-- A page inside a TabControl. Plain ContainerWidget with Tab/Shift+Tab nav
-- between its children, identical to Panel.

---@class TabPageWidget : ContainerWidget
TabPageWidget = setmetatable({}, { __index = ContainerWidget })
TabPageWidget.__index = TabPageWidget

local Nav = CAIWidgetHelpers_Navigation

---@param mgr UIScreenManager
---@param id string
---@param props? table
---@return TabPageWidget
function TabPageWidget.Create(mgr, id, props)
    local w = ContainerWidget.New(TabPageWidget)
    w.Id = id
    w.Type = "TabPage"
    w.Role = "TabPage"
    w.Manager = mgr
    -- Tab/Shift+Tab at page boundary must bubble to TabControl so the
    -- _EnterPageFromStrip / _ReturnToStripFromPage handlers can route focus
    -- between the page and the tab strip.
    w.WrapAround = false
    w:AddInputBindings({
        { Key = Keys.VK_TAB, MSG = KeyEvents.KeyDown,                 Action = function(self) return self:NavigateNext() end },
        { Key = Keys.VK_TAB, MSG = KeyEvents.KeyDown, IsShift = true, Action = function(self) return self:NavigatePrev() end },
    })
    CAIWidgetRegistry.ApplyProps(w, props)
    return w
end

---Direction-aware entry: Tab into the page lands on the first visible child,
---Shift+Tab lands on the last. Neutral entry (programmatic / re-entry) still
---uses the cached default. Default Container behavior reserves directional
---entry for Transparent layout shells; pages opt in explicitly because users
---traversing Tab/Shift+Tab through the screen expect a tab-stop-style entry
---rather than restored focus.
---@param direction 1|-1|0|nil
---@return UIWidget|nil
function TabPageWidget:GetEntryChild(direction)
    if direction == 1 then return Nav.First(self) end
    if direction == -1 then return Nav.Last(self) end
    return Nav.DefaultChild(self)
end

CAIWidgetRegistry.Register("TabPage", TabPageWidget.Create)
