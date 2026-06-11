-- CAIWidget_Dropdown.lua
-- A dropdown whose options live in a child List of MenuItems. Closed by
-- default: arrow keys bubble; only Enter is consumed and it opens the
-- dropdown. Opening unhides the inner list and focuses the menu item that
-- matches the committed selection. The list's label mirrors the dropdown
-- label so re-entry announces context; its position-in-parent is suppressed
-- (it is the dropdown's only meaningful child). Activating a menu item
-- commits the value, fires value_changed, and closes. Escape closes without
-- changing the value. Losing focus closes silently.
--
-- Screens that mirror a vanilla PullDown listen for "opened" / "closed"
-- to call PullDown:SetOpen(true/false) on the matching vanilla control.
-- Note: DO NOT ACTUALLY DO THIS. The vanilla pulldown traps input, blocking anything aside from escape

---@class DropdownOption
---@field label string
---@field value any

---@class DropdownWidget : ContainerWidget
---@field _options DropdownOption[]
---@field _selectedIndex integer
---@field _value any
---@field _valueSetter? fun(w:DropdownWidget, value:any)
---@field _isOpen boolean
---@field _list ListWidget
DropdownWidget = setmetatable({}, { __index = ContainerWidget })
DropdownWidget.__index = DropdownWidget

local function ClampIndex(self, idx)
    local n = #self._options
    if n == 0 then return 0 end
    if idx < 1 then idx = 1 end
    if idx > n then idx = n end
    return idx
end

local function RebuildList(self)
    self._list:ClearChildren()
    local mgr = self.Manager
    for i, opt in ipairs(self._options) do
        local props = { Label = function() return opt.label end }
        if opt.tooltip then
            props.Tooltip = function() return opt.tooltip end
        end
        local item = mgr:CreateWidget(self.Id .. "_Item" .. i, "MenuItem", props)
        item._dropdownIndex = i
        item:On("activate", function(menuItem)
            self:Commit(menuItem._dropdownIndex)
        end)
        self._list:AddChild(item)
    end
end

---@param mgr UIScreenManager
---@param id string
---@param props? table
---@return DropdownWidget
function DropdownWidget.Create(mgr, id, props)
    local w = ContainerWidget.New(DropdownWidget)
    w.Id = id
    w.Type = "Dropdown"
    w.Role = "Dropdown"
    w.Manager = mgr
    w._options = {}
    w._selectedIndex = 0
    w._value = nil
    w._isOpen = false

    -- Focus speech on the dropdown itself reads the committed option.
    w:SetValueGetter(function(self)
        local opt = self._options[self._selectedIndex]
        return opt and opt.label or ""
    end)

    -- Inner list. Mirrors the dropdown's label so opening announces context
    -- ("Difficulty, list, Easy, 1 of 3"). Position is suppressed: as the
    -- dropdown's only navigable child its "1 of 1" carries no information.
    w._list = mgr:CreateWidget(id .. "_List", "List", {
        Label = function() return w:GetLabel() end,
    })
    w._list.SpeechSettings = { Position = false }
    w._list:SetHiddenPredicate(function() return not w._isOpen end)
    UIWidget.AddChild(w, w._list)

    w:AddInputBindings({
        {
            Key = Keys.VK_RETURN,
            Action = function(self)
                if self._isOpen then return false end
                self:Open()
                return true
            end,
        },
        {
            Key = Keys.VK_ESCAPE,
            Action = function(self)
                if not self._isOpen then return false end
                self:Close()
                return true
            end,
        },
    })

    -- focus_leave on the dropdown itself fires when focus exits the entire
    -- subtree (descent into _list keeps the dropdown in the path). Close
    -- silently so vanilla teardown is the caller's responsibility on that
    -- path; an explicit Close() from screen code still emits "closed".
    w:On("focus_leave", function(self)
        if self._isOpen then self:Close(true) end
    end)

    CAIWidgetRegistry.ApplyProps(w, props)
    return w
end

---Open the list. Unhides _list (via the hidden predicate flipping), focuses
---the menu item that matches the committed selection, and emits "opened".
function DropdownWidget:Open()
    if self._isOpen then return end
    if #self._options == 0 then return end
    self._isOpen = true
    self:Emit("opened")
    local target = self._list.Children[self._selectedIndex] or self._list.Children[1]
    if target then self.Manager:SetFocus(target) end
end

---Close the list. Re-hides it, returns focus to the dropdown, and emits
---"closed" unless silent. Silent is used by focus_leave so the dropdown
---doesn't yank focus back when the user has already navigated elsewhere.
---@param silent? boolean
function DropdownWidget:Close(silent)
    if not self._isOpen then return end
    self._isOpen = false
    if not silent then
        self.Manager:SetFocus(self)
        self:Emit("closed")
    end
end

---@return boolean
function DropdownWidget:IsOpen() return self._isOpen end

--#region Value surface (mirrors ValueWidget without inheriting from it)

---@param fn fun(w:DropdownWidget, value:any)
function DropdownWidget:SetValueSetter(fn) self._valueSetter = fn end

---@param value any
---@param silent? boolean
function DropdownWidget:SetValue(value, silent)
    self._value = value
    if silent then return end
    if self._valueSetter then self._valueSetter(self, value) end
    self:Emit("value_changed", value)
    self:Announce({ "value" })
end

---@return any
function DropdownWidget:GetRawValue() return self._value end

--#endregion

---@param options DropdownOption[]
function DropdownWidget:SetOptions(options)
    self._options = options or {}
    if self._selectedIndex > #self._options then
        self._selectedIndex = 0
        self._value = nil
    else
        local opt = self._options[self._selectedIndex]
        self._value = opt and opt.value or nil
    end
    RebuildList(self)
end

---Commit a selection by index (called from MenuItem activate or programmatically).
---Fires value_changed and closes the dropdown so the user lands back on it
---with the new value.
---@param index integer
---@param silent? boolean
function DropdownWidget:Commit(index, silent)
    index = ClampIndex(self, index)
    if index == 0 then return end
    self._selectedIndex = index
    self:SetValue(self._options[index].value, silent)
    self:Close()
end

---@param index integer
---@param silent? boolean
function DropdownWidget:SetSelectedIndex(index, silent)
    index = ClampIndex(self, index)
    if index == 0 then return end
    self._selectedIndex = index
    self:SetValue(self._options[index].value, silent)
end

---@return integer
function DropdownWidget:GetSelectedIndex() return self._selectedIndex end

CAIWidgetRegistry.Register("Dropdown", DropdownWidget.Create)
