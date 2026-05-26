-- CAIWidget_Dialog.lua
-- ContainerWidget for modal popups. Tab/Shift+Tab and Up/Down cycle the
-- dialog's rows (content rows + the action button row, in that order).
-- SetButtons() auto-creates a Transparent horizontal button row appended as
-- the last child; Left/Right and Up/Down inside the row all cycle the buttons
-- (sticky — Tab/Shift+Tab is the way to escape the row).
-- Enter on the dialog fires the designated default action button's activate.

---@class DialogWidget : ContainerWidget
---@field _defaultActionChild? UIWidget
---@field _buttonRow? ContainerWidget
DialogWidget = setmetatable({}, { __index = ContainerWidget })
DialogWidget.__index = DialogWidget

---@param mgr UIScreenManager
---@param id string
---@param props? table
---@return DialogWidget
function DialogWidget.Create(mgr, id, props)
    local w = ContainerWidget.New(DialogWidget)
    w.Id = id
    w.Type = "Dialog"
    w.Role = "Dialog"
    w.Manager = mgr
    w:AddInputBindings({
        { Key = Keys.VK_TAB,  MSG = KeyEvents.KeyDown, Action = function(self) return self:NavigateNext() end },
        { Key = Keys.VK_TAB,  MSG = KeyEvents.KeyDown, IsShift = true,                                        Action = function(
            self) return self:NavigatePrev() end },
        { Key = Keys.VK_DOWN, MSG = KeyEvents.KeyDown, Action = function(self) return self:NavigateNext() end },
        { Key = Keys.VK_UP,   MSG = KeyEvents.KeyDown, Action = function(self) return self:NavigatePrev() end },
        {
            Key = Keys.VK_RETURN,
            Action = function(self)
                local target = self._defaultActionChild
                if target and not target:IsHidden() and not target:IsDisabled() then
                    target:Emit("activate")
                    return true
                end
                return false
            end,
        },
    })
    CAIWidgetRegistry.ApplyProps(w, props)
    return w
end

---@param child UIWidget
function DialogWidget:SetDefaultActionWidget(child)
    self._defaultActionChild = child
end

---Create (or replace) the action button row and append it as the dialog's
---last child. The row is Transparent so focus speech announces the button
---directly, not the row container.
---@param buttons ButtonWidget[]
---@param defaultIndex? integer 1-based; clamped to row size
---@return ContainerWidget rowWidget
function DialogWidget:SetButtons(buttons, defaultIndex)
    if self._buttonRow then
        self._buttonRow:Destroy()
        self._buttonRow = nil
    end
    local mgr = self.Manager
    local row = mgr:CreateWidget(mgr:GenerateWidgetId("CAIDlgButtons"), "Panel", {
        WrapAround = false,
        Transparent = true,
    })
    row:AddInputBindings({
        { Key = Keys.VK_LEFT,  MSG = KeyEvents.KeyDown, Action = function(self) return self:NavigatePrev() end },
        { Key = Keys.VK_RIGHT, MSG = KeyEvents.KeyDown, Action = function(self) return self:NavigateNext() end },
        { Key = Keys.VK_UP,    MSG = KeyEvents.KeyDown, Action = function(self) return self:NavigatePrev() end },
        { Key = Keys.VK_DOWN,  MSG = KeyEvents.KeyDown, Action = function(self) return self:NavigateNext() end },
    })
    if buttons then row:AddChildren(buttons) end
    self:AddChild(row)
    self._buttonRow = row

    if buttons and #buttons > 0 then
        local idx = defaultIndex or 1
        if idx < 1 then idx = 1 end
        if idx > #buttons then idx = #buttons end
        self:SetDefaultActionWidget(buttons[idx])
    end
    return row
end

---Returns the action buttons in the button row, or an empty array if none.
---@return UIWidget[]
function DialogWidget:GetActionButtons()
    if not self._buttonRow or not self._buttonRow.Children then return {} end
    local out = {}
    for i, c in ipairs(self._buttonRow.Children) do out[i] = c end
    return out
end

---Returns the dialog's content rows (all children except the button row).
---@return UIWidget[]
function DialogWidget:GetContent()
    local out = {}
    if not self.Children then return out end
    for _, c in ipairs(self.Children) do
        if c ~= self._buttonRow then out[#out + 1] = c end
    end
    return out
end

CAIWidgetRegistry.Register("Dialog", DialogWidget.Create)
