include("CAIControl")
include("caiUtils")
include("EspionageEscape")

local mgr = CAI:GetUIManager()

local m_dialog = nil ---@type UIWidget|nil

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
        Label = function() return CAIControl.ReadText(nativeButton) or "" end,
        Tooltip = function() return CAIText.JoinLines({ CAIControl.ReadText(nativeLabel), CAIControl.ReadTooltip(nativeButton) }) end,
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
    return CAIText.JoinLines({
        CAIText.LabelValue(CAIControl.ReadText(Controls.AgentLabel), CAIControl.ReadText(Controls.AgentDetails), " "),
        CAIText.LabelValue(CAIControl.ReadText(Controls.LootLabel), CAIControl.ReadText(Controls.LootDetails), " "),
        CAIText.LabelValue(CAIControl.ReadText(Controls.PursuitLabel), CAIControl.ReadText(Controls.PursuitDetails), " "),
    })
end

local function BuildContentRow()
    return MakeTextRow("CAIEspionageEscapeChoiceHeader", function()
        local choice = CAIControl.ReadText(Controls.ChoiceHeader) or ""
        local city = CAIControl.ReadText(Controls.CityHeader) or ""
        local details = BuildDetailsRow()
        return CAIText.JoinLines({ choice, city, details })
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
        function() return CAIControl.ReadText(Controls.PanelHeader) or "" end,
        BuildButtons(),
        { BuildContentRow() },
        1
    )
    if not m_dialog then return end
    mgr:Push(m_dialog)
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
