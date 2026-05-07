---@alias UIWidgetCallbackTypes "OnFocusLeave"|"OnFocusEnter"|"OnFocus"|"OnClick"|"OnAltClick"|"OnToggleChecked"|"OnToggleExpand"|"OnValueChanged"
---@class UIWidget
---@field Id? string
---@field FocusedChild? UIWidget
---@field Children? UIWidget[]
---@field DefaultIndex? integer
---@field Type? string
---@field Role? string
---@field InputMap? InputBinding[]
---@field Manager? UIScreenManager
---@field Parent? UIWidget
---@field SpeechSettings? table<string, boolean>
---@field GetLabel? fun():string
---@field GetValue? fun():string
---@field GetState? fun():string
---@field GetTooltip? fun():string
---@field OnValueChanged? fun(w:UIWidget, value:string)
---@field IsDisabled? fun(w:UIWidget):boolean
---@---@field IsHidden? fun(w:UIWidget):boolean
---@field OnClick? fun(w:UIWidget)
---@field OnCreate? fun(w:UIWidget)
---@field OnDestroy? fun(w:UIWidget)
---@field OnFocusEnter? fun(w:UIWidget)
---@field OnFocusLeave? fun(w:UIWidget)
---@field Callbacks table<UIWidgetCallbackTypes, fun(w):boolean[]>
UIWidget = {
}

---@class InputBinding
---@field Key Keys
---@field Action fun(w:UIWidget):boolean
---@field IsShift? boolean
---@field IsControl? boolean
---@Field IsAlt? boolean
---@field MSG? KeyEvents
local baseInputBinding = { IsShift = false, IsControl = false, IsAlt = false, MSG = KeyEvents.KeyUp }

--#Base methods
---Returns the unique widget id.
---@return string|nil
function UIWidget:GetId()
    return self.Id
end

---Adds a widget to the list of children
---@param w UIWidget
function UIWidget:AddChild(w, focus)
    if not w then return end
    if self.Manager and self.Manager.CAISettings and self.Manager.CAISettings.ValidateWidgetIds then
        self.Manager:WarnIfDuplicateWidgetId(w, self)
    end
    focus = focus or false
    w.Parent = self
    table.insert(self.Children, w)
    if focus then
        self.Manager:SetFocus(w)
    end
end

function UIWidget:AddChildren(children, focusIndex)
    if not children or #children == 0 then return end
    for i, child in ipairs(children) do
        local focus = i == focusIndex or false
        self:AddChild(child, focus)
    end
end

---Inserts a child widget at a specific index
---@param index integer
---@param w UIWidget
function UIWidget:InsertChild(index, w)
    if not w then return end
    if self.Manager and self.Manager.CAISettings and self.Manager.CAISettings.ValidateWidgetIds then
        self.Manager:WarnIfDuplicateWidgetId(w, self)
    end
    w.Parent = self
    table.insert(self.Children, index, w)
end

---Returns the widget's index in it's parrent
---@return integer|nil
function UIWidget:GetIndexInParent()
    local parent = self.Parent
    if not parent then return end
    for i, child in ipairs(parent.Children) do
        if child == self then return i end
    end
    return
end

---Returns the current position of a widget among its siblings
---@param child UIWidget
---@return integer|nil
function UIWidget:GetChildIndex(child)
    if not self.Children then return nil end
    for i, c in ipairs(self.Children) do
        if c == child then return i end
    end
    return nil
end

---Returns the first child widget with a matching id.
---@param id string
---@param recurse? boolean
---@return UIWidget|nil
function UIWidget:GetChildById(id, recurse)
    if not id or not self.Children then return nil end
    for _, child in ipairs(self.Children) do
        local childId = child and child.GetId and child:GetId() or child and child.Id
        if childId == id then return child end
        if recurse and child and child.GetChildById then
            local found = child:GetChildById(id, true)
            if found then return found end
        end
    end
    return nil
end

---Returns the widget's sibling if any, given a direction
---@param direction 1|-1
---@return UIWidget|nil
function UIWidget:GetSibling(direction)
    local parent = self.Parent
    if not parent then return end
    local siblings = parent.Children
    if not siblings then return end
    local index = self:GetIndexInParent()
    if not index then return end
    local nextIndex = index + direction
    if nextIndex < 1 or nextIndex > #siblings then return end
    return siblings[nextIndex]
end

---Removes a child widget given its index
---@param index integer
function UIWidget:RemoveChild(index)
    local w = table.remove(self.Children, index)
    if self.FocusedChild == w then self.FocusedChild = nil end
end

---Removes the widget from its parent if it has any
function UIWidget:RemoveFromParent()
    if not self.Parent then return end
    local pos = self:GetIndexInParent()
    if pos then
        self.Parent:RemoveChild(pos)
    end
end

---Destroys a widget. Should be used when a control or UI no longer exists
function UIWidget:Destroy()
    if self.OnDestroy then self:OnDestroy() end
    self:RemoveFromParent()
    if self.Children and #self.Children > 0 then
        while #self.Children > 0 do
            local child = self.Children[#self.Children]
            if not child then break end
            child:Destroy()
        end
    end
    self.Children = nil
    self.Manager = nil
    self.Parent = nil
end

---Clears and destroys all children of a widget
function UIWidget:ClearChildren()
    if self.Children and #self.Children > 0 then
        while #self.Children > 0 do
            local child = self.Children[#self.Children]
            if not child then break end
            child:Destroy()
        end
    end
    self.FocusedChild = nil
    self.Children = {}
    if self.Collapse then self:Collapse() end
end

---Focuses a child of this widget given its index
---@param pos integer
function UIWidget:SetFocusedChild(pos)
    if not self.Children or #self.Children == 0 then return end
    if pos > #self.Children then pos = #self.Children end
    if pos < 1 then pos = 1 end
    self.FocusedChild = self.Children[pos]
end

---Checks if the widget is currently focused
---@return boolean
function UIWidget:IsFocused()
    return self.Manager:GetFocusedWidget() == self
end

---Adds an input binding to the widget's input map table. Best to use this as a base for new bindings to avoid issues with missing fields
---@param binding InputBinding -- This inherits from 'baseInputBinding', so 'IsShift', 'IsAlt', and 'IsControl' are false by default. 'MSG' is set to 'KeyEvents.KeyUp'
function UIWidget:AddInputBinding(binding)
    setmetatable(binding, { __index = baseInputBinding })
    table.insert(self.InputMap, binding)
end

---Adds a table of input bindings to the widget's input map
---@param bindings InputBinding[]
function UIWidget:AddInputBindings(bindings)
    for _, binding in ipairs(bindings) do
        if binding.Action then
            self:AddInputBinding(binding)
        end
    end
end

---Binds the given widget's 'OnClick' to the enter key for this widget. Acts as default action for panels and dialogs etc
---@param w UIWidget
function UIWidget:SetDefaultActionWidget(w)
    if not w then return end
    if not w.OnClick then return end
    self:AddInputBinding({
        Key = Keys.VK_RETURN,
        Action = function(widget)
            if w then w:OnClick() end
            return true
        end
    })
end

---Base input handler for widgets. Checks the widget's input map for matches
---@param input InputStruct
---@return boolean -- Returns true on success, there by consuming input. On false, input bubbles up until it finds a match
function UIWidget:OnHandleInput(input)
    local key = input:GetKey()

    for _, binding in ipairs(self.InputMap) do
        if binding.Action and binding.Key then
            local msg = input:GetMessageType()
            if msg == binding.MSG then
                local key = input:GetKey()
                if key == binding.Key then
                    local isShift = input:IsShiftDown()
                    local isControl = input:IsControlDown()
                    local isAlt = input:IsAltDown()
                    if isShift == binding.IsShift and isControl == binding.IsControl and isAlt == binding.IsAlt then
                        return binding.Action(self)
                    end
                end
            end
        end
    end
    return false
end

---Sets the priority for a widget for sorting purposes. Should only be used on root widgits
---@param priority PopupPriority
function UIWidget:SetPriority(priority)
    if not priority or type(priority) ~= "number" then return end
    self.__priority = priority
end

---Sets the widget's value and triggers OnValueChanged callback + speaks the new value
---@param value string
function UIWidget:SetValue(value)
    if self.OnValueChanged then
        self:OnValueChanged(value)
    end
    self:SpeakElements({ "value" })
end

---Builds the widget's speech string honoring per-widget and global SpeechSettings
---@param elements? string[] -- Optional list of element keys. Empty or nil = all canonical elements
---@return string|nil -- Comma-joined speech string, or nil if nothing to speak
function UIWidget:BuildSpeech(elements)
    local info = self:GetInfoStrings()
    local settings = self.SpeechSettings or {}
    local globalSettings = self.Manager and self.Manager.CAISettings or {}

    -- Canonical order of speech elements
    local allKeys = { "label", "role", "value", "position", "state", "tooltip" }
    local keysToSpeak = (elements and #elements > 0) and elements or allKeys

    local parts = {}
    for _, key in ipairs(keysToSpeak) do
        local settingKey = key:sub(1, 1):upper() .. key:sub(2)
        if settings[settingKey] == false then
            -- Widget-level override: skip
        else
            local globalKey = "speak" .. settingKey
            local globalAllowed = globalSettings[globalKey] == nil or globalSettings[globalKey] == true
            if globalAllowed and info[key] then
                table.insert(parts, info[key])
            end
        end
    end

    if #parts == 0 then return nil end
    return table.concat(parts, "  ")
end

---Speaks the widget's info
---@param elements? string[] -- Optional list of element keys to speak. Empty or nil = speak all available elements
function UIWidget:SpeakElements(elements)
    local speech = self:BuildSpeech(elements)
    if speech then Speak(speech) end
end

---Speaks the currently focused widget's info (legacy shortcut, speaks all elements)
function UIWidget:SpeakFocus()
    self:SpeakElements()
end

--#Helpers

---Returns this widget's non-hidden children.
---@return UIWidget[]
function UIWidget:GetVisibleChildren()
    local visible = {}
    if not self.Children then return visible end
    for _, child in ipairs(self.Children) do
        local hidden = child.IsHidden and child:IsHidden()
        if not hidden then
            table.insert(visible, child)
        end
    end
    return visible
end

---Returns the visible index and visible total among siblings, skipping hidden elements
---@return integer|nil, integer
function UIWidget:GetVisiblePosition()
    local parent = self.Parent
    if not parent or not parent.Children then return nil, 0 end

    local visibleIndex = 0
    local visibleTotal = 0
    for _, child in ipairs(parent.Children) do
        local isHidden = child.IsHidden and child:IsHidden()
        if not isHidden then
            visibleTotal = visibleTotal + 1
            if child == self then
                visibleIndex = visibleTotal
            end
        end
    end
    return (visibleIndex > 0) and visibleIndex or nil, visibleTotal
end

---Sets the default index from which focus starts
---@param idx integer
function UIWidget:SetDefaultIndex(idx)
    if not idx then return end
    self.DefaultIndex = idx
end

---Returns a table of descriptive strings for the widget
---@return table
function UIWidget:GetInfoStrings()
    local label = self.GetLabel and self:GetLabel() or ""
    local roleName = self.Role or self.Type or ""
    local role = roleName ~= "" and Locale.Lookup("LOC_UIWidget_Role_" .. roleName) or ""

    local visIdx, visTotal = self:GetVisiblePosition()
    local posText = (visIdx and visTotal > 0) and Locale.Lookup("LOC_UIWidget_Element_Pos", visIdx, visTotal) or ""

    local value = self.GetValue and self:GetValue() or ""
    local state = ""
    if self.IsDisabled and self:IsDisabled() then
        state = Locale.Lookup("LOC_CAI_STATE_DISABLED")
    end
    local tooltip = self.GetTooltip and self:GetTooltip() or ""

    return {
        label = label ~= "" and label or nil,
        role = role ~= "" and role or nil,
        state = state ~= "" and state or nil,
        value = value ~= "" and value or nil,
        position = posText ~= "" and posText or nil,
        tooltip = tooltip ~= "" and tooltip or nil
    }
end
