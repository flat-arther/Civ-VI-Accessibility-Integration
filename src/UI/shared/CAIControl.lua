-- Live access to optional controls, including controls without text/state methods.
CAIControl = {}

function CAIControl.IsHidden(control)
    return control and control.IsHidden and control:IsHidden() or false
end

function CAIControl.IsDisabled(control)
    return control and control.IsDisabled and control:IsDisabled() or false
end

-- Absence is not visibility; an existing control without IsHidden is visible.
function CAIControl.IsVisible(control)
    return control ~= nil and not CAIControl.IsHidden(control)
end

-- Empty text is absent. Do not trim, filter markup, or cache control values.
function CAIControl.ReadText(control)
    if control and control.GetText then
        local value = control:GetText()
        if value and value ~= "" then return value end
    end
    return nil
end

function CAIControl.ReadTooltip(control)
    if control and control.GetToolTipString then
        local value = control:GetToolTipString()
        if value and value ~= "" then return value end
    end
    return nil
end

function CAIControl.Text(control)
    return CAIControl.ReadText(control) or ""
end

function CAIControl.Tooltip(control)
    return CAIControl.ReadTooltip(control) or ""
end

-- Governor controls expose text methods whenever the control exists.
-- Missing required methods must still fail instead of silently hiding errors.
function CAIControl.TooltipWithValue(control, valueControl, fallbackLabel, requireControls)
    if requireControls then
        assert(control ~= nil and valueControl ~= nil, "Required text controls are missing")
    end
    local label = control and tostring(control:GetToolTipString() or "") or ""
    if label == "" and fallbackLabel then label = Locale.Lookup(fallbackLabel) end
    local value = valueControl and tostring(valueControl:GetText() or "") or ""
    if label ~= "" and value ~= "" then return label .. ": " .. value end
    if value ~= "" then return value end
    return label
end
