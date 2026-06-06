-- CAIWidget_Tab.lua
-- A tab header inside a TabControl's tab strip. When focused, it tells the
-- parent TabControl to activate its paired page.

---@class TabWidget : UIWidget
---@field _tabIndex integer
---@field _control TabControlWidget
TabWidget = setmetatable({}, { __index = UIWidget })
TabWidget.__index = TabWidget

---@param mgr UIScreenManager
---@param id string
---@param props? table
---@return TabWidget
function TabWidget.Create(mgr, id, props)
    local w = UIWidget.New(TabWidget)
    w.Id = id
    w.Type = "Tab"
    w.Role = "Tab"
    w.Manager = mgr

    w:On("focus_enter", function(self)
        if self._control and self._tabIndex then
            self._control:_OnTabFocused(self._tabIndex)
        end
    end)

    CAIWidgetRegistry.ApplyProps(w, props)
    return w
end

CAIWidgetRegistry.Register("Tab", TabWidget.Create)
