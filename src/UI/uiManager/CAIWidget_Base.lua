-- CAIWidget_Base.lua
-- UIWidget: identity, tree, predicates, events, input, speech.
-- Concrete widget classes inherit from this via metatable chains.

include("InputSupport")

local SPEECH_ORDER = { "label", "role", "state", "value", "tooltip", "position" }

---@class UIWidget
---@field Id? string
---@field Type? string
---@field Role? string
---@field Parent? UIWidget
---@field Children UIWidget[]
---@field Manager? UIScreenManager
---@field InputMap InputBinding[]
---@field SpeechSettings table<string, boolean>
UIWidget = {}
UIWidget.__index = UIWidget

---@class InputBinding
---@field Key Keys
---@field Action fun(w:UIWidget):boolean
---@field IsShift? boolean
---@field IsControl? boolean
---@field IsAlt? boolean
---@field MSG? KeyEvents
local baseInputBinding = { IsShift = false, IsControl = false, IsAlt = false, MSG = KeyEvents.KeyUp }

---Constructs a new widget instance bound to its class metatable.
---Concrete classes call this and chain their own __index.
---@param class table
---@return UIWidget
function UIWidget.New(class)
    local w = setmetatable({}, class)
    w.Children = {}
    w.InputMap = {}
    w.SpeechSettings = {}
    w._listeners = {}
    return w
end

--#region Identity

function UIWidget:GetId() return self.Id end

--#endregion

--#region Tree ops

---@param child UIWidget
---@param focus? boolean
function UIWidget:AddChild(child, focus)
    if not child then return end
    child.Parent = self
    table.insert(self.Children, child)
    if focus and self.Manager then self.Manager:SetFocus(child) end
end

---@param children UIWidget[]
---@param focusIndex? integer
function UIWidget:AddChildren(children, focusIndex)
    if not children then return end
    for i, child in ipairs(children) do
        self:AddChild(child, i == focusIndex)
    end
end

---@param index integer
---@param child UIWidget
function UIWidget:InsertChild(index, child)
    if not child then return end
    child.Parent = self
    table.insert(self.Children, index, child)
end

---@param index integer
function UIWidget:RemoveChild(index)
    local removed = table.remove(self.Children, index)
    if removed then removed.Parent = nil end
end

function UIWidget:RemoveFromParent()
    if not self.Parent then return end
    local idx = self:GetIndexInParent()
    if idx > 0 then self.Parent:RemoveChild(idx) end
end

function UIWidget:ClearChildren()
    while #self.Children > 0 do
        local child = self.Children[#self.Children]
        child:Destroy()
    end
    self.Children = {}
end

function UIWidget:Destroy()
    self:Emit("destroy")
    if self.Manager and self.Manager.NotifyDestroy then
        self.Manager:NotifyDestroy(self)
    end
    self:RemoveFromParent()
    while self.Children and #self.Children > 0 do
        local child = self.Children[#self.Children]
        if not child then break end
        child:Destroy()
    end
    self._listeners = {}
    self.Children = nil
    self.Manager = nil
    self.Parent = nil
end

---@return integer
function UIWidget:GetIndexInParent()
    if not self.Parent then return 0 end
    for i, c in ipairs(self.Parent.Children) do
        if c == self then return i end
    end
    return 0
end

---@param child UIWidget
---@return integer
function UIWidget:GetChildIndex(child)
    if not self.Children then return 0 end
    for i, c in ipairs(self.Children) do
        if c == child then return i end
    end
    return 0
end

---@param id string
---@param recurse? boolean
---@return UIWidget|nil
function UIWidget:GetChildById(id, recurse)
    if not id or not self.Children then return nil end
    for _, child in ipairs(self.Children) do
        if child.Id == id then return child end
        if recurse and child.GetChildById then
            local found = child:GetChildById(id, true)
            if found then return found end
        end
    end
    return nil
end

---@return UIWidget[]
function UIWidget:GetVisibleChildren()
    local out = {}
    if not self.Children then return out end
    for _, c in ipairs(self.Children) do
        if not c:IsHidden() then table.insert(out, c) end
    end
    return out
end

---@return integer|nil visibleIndex, integer visibleTotal
function UIWidget:GetVisiblePosition()
    local parent = self.Parent
    if not parent or not parent.Children then return nil, 0 end
    local idx, total = 0, 0
    for _, c in ipairs(parent.Children) do
        if not c:IsHidden() then
            total = total + 1
            if c == self then idx = total end
        end
    end
    return idx > 0 and idx or nil, total
end

--#endregion

--#region Focus access (manager is authoritative)

---@return UIWidget|nil
function UIWidget:GetFocusedChild()
    local mgr = self.Manager
    if not mgr or not mgr.CurrentPath then return self._lastFocusedChild end
    local path = mgr.CurrentPath
    for i = 1, #path - 1 do
        if path[i] == self then return path[i + 1] end
    end
    return self._lastFocusedChild
end

---@return boolean
function UIWidget:IsFocused()
    return self.Manager and self.Manager:GetFocusedWidget() == self or false
end

---@param idx integer
function UIWidget:SetDefaultIndex(idx)
    self.DefaultIndex = idx
end

--#endregion

--#region Predicate + metadata setters
-- Each setter accepts either a literal value or a function(w) -> value.
-- The resolved closure is cached so speech building doesn't re-branch per call.

local function asGetter(arg, defaultLiteralReturn)
    if type(arg) == "function" then return arg end
    if arg == nil then return nil end
    return function() return arg end
end

function UIWidget:SetLabel(arg) self._labelFn = asGetter(arg) end

function UIWidget:SetTooltip(arg) self._tooltipFn = asGetter(arg) end

function UIWidget:SetValueGetter(fn) self._valueGetterFn = fn end

function UIWidget:SetStateGetter(fn) self._stateGetterFn = fn end

function UIWidget:SetHiddenPredicate(fn) self._hiddenFn = fn end

function UIWidget:SetDisabledPredicate(fn) self._disabledFn = fn end

function UIWidget:SetRole(role) self.Role = role end

---Stable identifier that survives child-list rebuilds. When the parent of a
---focused widget remembers focus, it caches by FocusKey first; this means
---rebuilding the children with matching FocusKeys preserves focus.
---@param key string|nil
function UIWidget:SetFocusKey(key) self.FocusKey = key end

---When true, this widget contributes nothing to focus-change announcements.
---Use for layout-only containers (button rows, scroll wrappers).
---@param b boolean
function UIWidget:SetTransparent(b) self.Transparent = b and true or false end

---Sound to play on focus_enter (looked up via UI.PlaySound). Set to nil for none.
---@param soundName string|nil
function UIWidget:SetFocusSound(soundName) self._focusSound = soundName end

function UIWidget:GetLabel() return self._labelFn and self._labelFn(self) or "" end

function UIWidget:GetTooltip() return self._tooltipFn and self._tooltipFn(self) or "" end

function UIWidget:GetValue() return self._valueGetterFn and self._valueGetterFn(self) or "" end

function UIWidget:GetState() return self._stateGetterFn and self._stateGetterFn(self) or "" end

---A widget is hidden if its own predicate says so OR any ancestor is hidden.
---Mirrors how the rendered UI treats parent visibility, so navigation, focus
---path descent, and announcements all skip the entire subtree of a hidden parent.
function UIWidget:IsHidden()
    if self._hiddenFn and self._hiddenFn(self) then return true end
    local p = self.Parent
    if p and p.IsHidden and p:IsHidden() then return true end
    return false
end

function UIWidget:IsDisabled() return self._disabledFn and self._disabledFn(self) or false end

--#endregion

--#region Events
-- self._listeners[event] = { [token] = fn }
-- token is a unique table returned by On() and consumed by Off().

---@param event string
---@param fn function
---@return table token
function UIWidget:On(event, fn)
    local bucket = self._listeners[event]
    if not bucket then
        bucket = {}
        self._listeners[event] = bucket
    end
    local token = {}
    bucket[token] = fn
    return token
end

---@param event string
---@param token table
function UIWidget:Off(event, token)
    local bucket = self._listeners[event]
    if bucket then bucket[token] = nil end
end

---@param event string
function UIWidget:Emit(event, ...)
    local bucket = self._listeners and self._listeners[event]
    if not bucket then return end
    -- Snapshot so handlers can add/remove listeners during dispatch.
    local snapshot = {}
    for _, fn in pairs(bucket) do snapshot[#snapshot + 1] = fn end
    for _, fn in ipairs(snapshot) do fn(self, ...) end
end

--#endregion

--#region Input

---@param binding InputBinding
function UIWidget:AddInputBinding(binding)
    setmetatable(binding, { __index = baseInputBinding })
    table.insert(self.InputMap, binding)
end

---@param bindings InputBinding[]
function UIWidget:AddInputBindings(bindings)
    for _, b in ipairs(bindings) do
        if b.Action then self:AddInputBinding(b) end
    end
end

---@param input InputStruct
---@return boolean
function UIWidget:OnHandleInput(input)
    local key = input:GetKey()
    local msg = input:GetMessageType()
    local isShift = input:IsShiftDown()
    local isControl = input:IsControlDown()
    local isAlt = input:IsAltDown()
    for _, b in ipairs(self.InputMap) do
        if b.Action and b.Key == key and b.MSG == msg
            and isShift == b.IsShift and isControl == b.IsControl and isAlt == b.IsAlt then
            local result = b.Action(self)
            if result ~= nil then return result == true end
        end
    end
    return false
end

--#endregion

--#region Priority (root widgets only)

---@param priority PopupPriority
function UIWidget:SetPriority(priority)
    if type(priority) == "number" then self.__priority = priority end
end

--#endregion

--#region Speech

---@param elements? string[] Optional subset of canonical speech keys
---@return string|nil
function UIWidget:BuildSpeech(elements)
    local info = self:GetInfoStrings()
    local settings = self.SpeechSettings or {}
    local globals = self.Manager and self.Manager.CAISettings or {}
    local keys = (elements and #elements > 0) and elements or SPEECH_ORDER

    local parts = {}
    for _, key in ipairs(keys) do
        local settingKey = key:sub(1, 1):upper() .. key:sub(2)
        local widgetAllows = settings[settingKey] ~= false
        local globalKey = "speak" .. settingKey
        local globalAllows = globals[globalKey] == nil or globals[globalKey] == true
        if widgetAllows and globalAllows and info[key] then
            parts[#parts + 1] = info[key]
        end
    end
    if #parts == 0 then return nil end
    return table.concat(parts, ", ")
end

---Speak this widget's info on demand. Used by screens after a value changes
---outside the focus path, and as a free-standing way to read out a widget.
---@param elements? string[]
function UIWidget:Announce(elements)
    local speech = self:BuildSpeech(elements)
    if speech then Speak(ProcessIcons(speech)) end
end

---Legacy alias for Announce. Prefer Announce in new code.
---@param elements? string[]
function UIWidget:SpeakElements(elements) self:Announce(elements) end

---@return table
function UIWidget:GetInfoStrings()
    local label = self:GetLabel()
    local roleName = self.Role or self.Type or ""
    local role = ""
    if roleName ~= "" then
        local tag = "LOC_UIWidget_Role_" .. roleName
        local lookup = Locale.Lookup(tag)
        -- Civ VI Locale.Lookup returns the tag itself on miss; skip in that case
        -- so we don't speak the raw LOC tag.
        if lookup ~= tag then role = lookup end
    end
    local visIdx, visTotal = self:GetVisiblePosition()
    local position = (visIdx and visTotal > 0) and Locale.Lookup("LOC_UIWidget_Element_Pos", visIdx, visTotal) or ""
    local value = self:GetValue()
    local state = ""
    if self:IsDisabled() then state = Locale.Lookup("LOC_CAI_STATE_DISABLED") end
    local explicitState = self:GetState()
    if explicitState ~= "" then
        state = state ~= "" and (state .. "  " .. explicitState) or explicitState
    end
    local tooltip = self:GetTooltip()
    return {
        label    = label ~= "" and label or nil,
        role     = role ~= "" and role or nil,
        position = position ~= "" and position or nil,
        value    = value ~= "" and value or nil,
        state    = state ~= "" and state or nil,
        tooltip  = tooltip ~= "" and tooltip or nil,
    }
end

--#endregion
