-- CAIWidget_Value.lua
-- ValueWidget: holds a mutable value with a bound setter. Concrete widgets
-- with a buffer/commit phase (EditBox) override Commit themselves; the base
-- class has no Commit concept.

---@class ValueWidget : UIWidget
---@field _value any
---@field _valueSetter? fun(w:ValueWidget, value:any)
ValueWidget = setmetatable({}, { __index = UIWidget })
ValueWidget.__index = ValueWidget

---@param class table
---@return ValueWidget
function ValueWidget.New(class)
    local w = UIWidget.New(class)
    w._value = nil
    return w
end

---@param fn fun(w:ValueWidget, value:any)
function ValueWidget:SetValueSetter(fn) self._valueSetter = fn end

---Update internal value, invoke backing setter, emit value_changed.
---Pass silent=true for programmatic refresh (no setter, no event, no speech).
---@param value any
---@param silent? boolean
function ValueWidget:SetValue(value, silent)
    self._value = value
    if silent then return end
    if self._valueSetter then self._valueSetter(self, value) end
    self:Emit("value_changed", value)
    self:Announce({ "value" })
end

---Raw internal value (the actual bool/number/string). For the formatted
---speech string set via SetValueGetter, see UIWidget:GetValue.
---@return any
function ValueWidget:GetRawValue() return self._value end
