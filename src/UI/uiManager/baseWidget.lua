---@alias UIWidgetCallbackTypes "OnFocusLeave"|"OnFocusEnter"|"OnFocus"|"OnClick"|"OnAltClick|"OnToggleChecked"|"OnToggleExpand"
---@class UIWidget
---@field FocusedChild? UIWidget
---@field Children? UIWidget[]
---@field DefaultIndex? integer
---@field Type? string
---@field InputMap? InputBinding[]
---@field Manager? UIScreenManager
---@field Parent? UIWidget
---@field GetLabel? fun():string
---@field GetState? fun():string
---@field GetTooltip? fun():string
---@field 
---@field Callbacks table<UIWidgetCallbackTypes, fun(w):boolean[]>
UIWidget = {
    Callbacks = {}
}

---@class InputBinding
---@field Key Keys
---@field Action fun(w:UIWidget):boolean
---@field IsShift? boolean
---@field IsControl? boolean
---@field MSG? KeyEvents
local baseInputBinding = {IsShift = false, IsControl = false, MSG = KeyEvents.KeyDown}


--#Base methods
---Adds a widget to the list of children
---@param w UIWidget
function UIWidget:AddChild(w, focus)
    if not w then return end
    focus = focus or false
    w.Parent = self
    table.insert(self.Children, w)
    if focus then 
        self.Manager:SetFocus(w)
    end
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
    if w.Manager:GetFocusedWidget() == w then
        if #self.Children > 0 then
            -- todo: have this get next valid sibling when ever you get to separating the child search portion from navigate
            w.Manager:SetFocus(self.Children[1])
        else
    w.Manager:SetFocus(self)
    end
end
    if w.Parent then w.Parent.FocusedChild = nil end
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
        for _, child in ipairs(self.Children) do
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
        for _, child in ipairs(self.Children) do
            child:Destroy()
        end
    end
    self.Children = {}
end

---Focuses a child of this widget given its index
---@param pos integer
---@return boolean
function UIWidget:SetFocusedChild(pos)
    if not self.Children or not self.Children[pos] then return false end
    local child = self.Children[pos]
    self.Manager:SetFocus(child)
    return true
end

    ---Checks if the widget is currently focused
    ---@return boolean
    function UIWidget:IsFocused()
        return self.Manager:GetFocusedWidget() == self
    end

    ---Adds an input binding to the widget's input map table. Best to use this as a base for new bindings to avoid issues with missing fields
    ---@param binding InputBinding -- This inherits from 'baseInputBinding', so 'IsShift' and 'IsControl' are false by default. 'MSG' is set to 'KeyEvents.KeyDown'
    function UIWidget:AddInputBinding(binding)
        setmetatable(binding, {__index = baseInputBinding})
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
        if isShift == binding.IsShift and isControl == binding.IsControl then
        return binding.Action(self)
        end
    end
    end
        end
    end
        return false
    end

    ---Speaks the currently focused widget's info
    function UIWidget:SpeakFocus()
        SpeakWidget(self)
end

--#Helpers

---Returns a table of descriptive strings for the widget
---@return table
function UIWidget:GetInfoStrings()
    local label = self.GetLabel and self:GetLabel() or ""
    local role = Locale.Lookup("LOC_UIWidget_Role_"..self.Type) or ""
    
    local pos = self:GetIndexInParent()
    local children = (self.Parent and self.Parent.Children)
    local total = children and #children or 0
    local posText = (pos and total > 1) and Locale.Lookup("LOC_UIWidget_Element_Pos", pos, total) or ""
    
    local state = self.GetState and self:GetState() or ""
    local tooltip = self.GetTooltip and self:GetTooltip() or ""

    return {
        label = label ~= "" and label or nil,
        meta = role ~= "" and role or nil,
        position = posText ~= "" and posText or nil,
        state = state ~= "" and state or nil,
        tooltip = tooltip ~= "" and tooltip or nil
    }
end