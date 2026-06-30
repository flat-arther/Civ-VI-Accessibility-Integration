include("caiUtils")
include("EspionageEscape")

local mgr = ExposedMembers.CAI_UIManager

local m_dialog = nil ---@type UIWidget|nil

local function Visible(control)
    return control ~= nil and (not control.IsHidden or not control:IsHidden())
end

local function Text(control)
    if control and control.GetText then
        local value = control:GetText()
        if value and value ~= "" then
            return value
        end
    end
    return nil
end

local function Tooltip(control)
    if control and control.GetToolTipString then
        local value = control:GetToolTipString()
        if value and value ~= "" then
            return value
        end
    end
    return nil
end

local function JoinNonEmpty(parts)
    local out = {}
    for _, part in ipairs(parts or {}) do
        if part and part ~= "" then
            table.insert(out, part)
        end
    end
    return table.concat(out, "[NEWLINE]")
end

local function LabelValue(label, value)
    if label and label ~= "" and value and value ~= "" then
        return label .. " " .. value
    end
    return label or value
end

local function MakeTextRow(idPrefix, getText)
    return mgr:CreateWidget(mgr:GenerateWidgetId(idPrefix), "StaticText", {
        Label = getText,
    })
end

local function RemoveDialog()
    if not mgr or not m_dialog then return end
    mgr:RemoveFromStack(m_dialog:GetId())
    m_dialog = nil
end

local function MakeRouteButton(nativeButton, nativeLabel, idPrefix)
    local btn = mgr:CreateWidget(mgr:GenerateWidgetId(idPrefix), "Button", {
        Label = function() return Text(nativeButton) or "" end,
        Tooltip = function() return JoinNonEmpty({ Text(nativeLabel), Tooltip(nativeButton) }) end,
        HiddenPredicate = function() return nativeButton == nil or nativeButton:IsHidden() end,
        DisabledPredicate = function() return nativeButton ~= nil and nativeButton:IsDisabled() end,
    })
    btn:On("activate", function()
        if nativeButton and not nativeButton:IsHidden() and not nativeButton:IsDisabled() then
            nativeButton:DoLeftClick()
        end
    end)
    return btn
end

local function BuildDetailsRow()
    return JoinNonEmpty({
        LabelValue(Text(Controls.AgentLabel), Text(Controls.AgentDetails)),
        LabelValue(Text(Controls.LootLabel), Text(Controls.LootDetails)),
        LabelValue(Text(Controls.PursuitLabel), Text(Controls.PursuitDetails)),
    })
end

local function BuildContentRow()
    return MakeTextRow("CAIEspionageEscapeChoiceHeader", function()
        local choice = Text(Controls.ChoiceHeader) or ""
        local city = Text(Controls.CityHeader) or ""
        local details = BuildDetailsRow()
        return JoinNonEmpty({ choice, city, details })
    end)
end

local function BuildButtons()
    return {
        MakeRouteButton(Controls.Button1, Controls.Label1, "CAIEspionageEscapeRoute1"),
        MakeRouteButton(Controls.Button2, Controls.Label2, "CAIEspionageEscapeRoute2"),
        MakeRouteButton(Controls.Button3, Controls.Label3, "CAIEspionageEscapeRoute3"),
        MakeRouteButton(Controls.Button4, Controls.Label4, "CAIEspionageEscapeRoute4"),
    }
end

local function BuildDialog()
    RemoveDialog()
    if not mgr or ContextPtr:IsHidden() then return end
    m_dialog = mgr.WidgetHelpers.MakeGeneralDialog(
        function() return Text(Controls.PanelHeader) or "" end,
        BuildButtons(),
        { BuildContentRow() },
        1
    )
    if not m_dialog then return end
    mgr:Push(m_dialog, { priority = PopupPriority.Low })
end

local function IsDialogActive()
    return mgr ~= nil and m_dialog ~= nil and mgr:GetTop() == m_dialog
end

local NativeOnOpen = OnOpen
OnOpen = WrapFunc(OnOpen, function(orig, ...)
    orig(...)
    BuildDialog()
end)
LuaEvents.NotificationPanel_OpenEspionageEscape.Remove(NativeOnOpen)
LuaEvents.NotificationPanel_OpenEspionageEscape.Add(OnOpen)

OnClose = WrapFunc(OnClose, function(orig, ...)
    RemoveDialog()
    orig(...)
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
    if IsDialogActive() and not ContextPtr:IsHidden() then
        local handled = mgr:HandleInput(pInputStruct)
        if handled then return handled end
    end
    return orig(pInputStruct)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)

ContextPtr:SetHideHandler(function()
    RemoveDialog()
end)
