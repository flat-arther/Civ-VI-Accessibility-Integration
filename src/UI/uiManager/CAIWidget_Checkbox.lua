-- CAIWidget_Checkbox.lua
-- ValueWidget where the value is a boolean.

---@class CheckboxWidget : ValueWidget
CheckboxWidget = setmetatable({}, { __index = ValueWidget })
CheckboxWidget.__index = CheckboxWidget

---@param mgr UIScreenManager
---@param id string
---@param props? table
---@return CheckboxWidget
function CheckboxWidget.Create(mgr, id, props)
    local w = ValueWidget.New(CheckboxWidget)
    w.Id = id
    w.Type = "Checkbox"
    w.Role = "Checkbox"
    w.Manager = mgr
    w._value = false

    w:SetValueGetter(function(self)
        return self._value
            and Locale.Lookup("LOC_UIWidget_Checked")
            or Locale.Lookup("LOC_UIWidget_Unchecked")
    end)

    w:AddInputBindings({
        { Key = Keys.VK_SPACE,  Description = "LOC_CAI_KB_TOGGLE", Action = function(self)
            self:Toggle(); return true
        end },
        { Key = Keys.VK_RETURN, MSG = KeyEvents.KeyUp,             Description = "LOC_CAI_KB_TOGGLE",                     Action = function(
            self)
            self:Toggle(); return true
        end },
    })

    CAIWidgetRegistry.ApplyProps(w, props)
    return w
end

---@param b boolean
---@param silent? boolean
function CheckboxWidget:SetChecked(b, silent) self:SetValue(b and true or false, silent) end

---@return boolean
function CheckboxWidget:IsChecked() return self._value and true or false end

function CheckboxWidget:Toggle() self:SetValue(not self._value) end

CAIWidgetRegistry.Register("Checkbox", CheckboxWidget.Create)
