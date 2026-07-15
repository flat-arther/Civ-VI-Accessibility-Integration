-- CAIWidget_Slider.lua
-- ValueWidget with clamped numeric value, step size, and page step.

---@class SliderWidget : ValueWidget
---@field _min number
---@field _max number
---@field _step number
---@field _pageStep number
SliderWidget = setmetatable({}, { __index = ValueWidget })
SliderWidget.__index = SliderWidget

local function Clamp(self, v)
    if v < self._min then v = self._min end
    if v > self._max then v = self._max end
    return v
end

---@param mgr UIScreenManager
---@param id string
---@param props? table
---@return SliderWidget
function SliderWidget.Create(mgr, id, props)
    local w = ValueWidget.New(SliderWidget)
    w.Id = id
    w.Type = "Slider"
    w.Role = "Slider"
    w.Manager = mgr
    w._min = 0
    w._max = 100
    w._step = 1
    w._pageStep = 10
    w._value = 0

    w:SetValueGetter(function(self) return tostring(self._value) end)

    w:AddInputBindings({
        { Key = Keys.VK_LEFT,  MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_DECREASE",      Action = function(self) self:Decrement(); return true end },
        { Key = Keys.VK_RIGHT, MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_INCREASE",      Action = function(self) self:Increment(); return true end },
        { Key = Keys.VK_PRIOR, MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_INCREASE_PAGE", Action = function(self) self:PageIncrement(); return true end },
        { Key = Keys.VK_NEXT,  MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_DECREASE_PAGE", Action = function(self) self:PageDecrement(); return true end },
        { Key = Keys.VK_HOME,  MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_SET_MINIMUM",   Action = function(self) self:SetValue(self._min); return true end },
        { Key = Keys.VK_END,   MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_SET_MAXIMUM",   Action = function(self) self:SetValue(self._max); return true end },
    })

    CAIWidgetRegistry.ApplyProps(w, props)
    return w
end

function SliderWidget:SetMin(n)
    self._min = n
    local clamped = Clamp(self, self._value)
    if clamped ~= self._value then self:SetValue(clamped, true) end
end
function SliderWidget:SetMax(n)
    self._max = n
    local clamped = Clamp(self, self._value)
    if clamped ~= self._value then self:SetValue(clamped, true) end
end
function SliderWidget:SetStepSize(n) self._step = n end
function SliderWidget:SetPageStep(n) self._pageStep = n end

---@param value number
---@param silent? boolean
function SliderWidget:SetValue(value, silent)
    ValueWidget.SetValue(self, Clamp(self, value), silent)
end

---@param n? integer multiplier; defaults to 1 step
---@return boolean
function SliderWidget:Increment(n)
    n = n or 1
    local newValue = Clamp(self, self._value + self._step * n)
    if newValue == self._value then return false end
    self:SetValue(newValue)
    return true
end

---@param n? integer
---@return boolean
function SliderWidget:Decrement(n)
    n = n or 1
    local newValue = Clamp(self, self._value - self._step * n)
    if newValue == self._value then return false end
    self:SetValue(newValue)
    return true
end

---@return boolean
function SliderWidget:PageIncrement()
    local newValue = Clamp(self, self._value + self._pageStep)
    if newValue == self._value then return false end
    self:SetValue(newValue); return true
end

---@return boolean
function SliderWidget:PageDecrement()
    local newValue = Clamp(self, self._value - self._pageStep)
    if newValue == self._value then return false end
    self:SetValue(newValue); return true
end

CAIWidgetRegistry.Register("Slider", SliderWidget.Create)
