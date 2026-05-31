include("caiUtils")
include("AdvisorPopup")
local mgr = ExposedMembers.CAI_UIManager

local m_tutorialPanel = nil ---@type UIWidget|nil


ShowAdvisorPopup = WrapFunc(ShowAdvisorPopup, function(orig, advisorData)
    orig(advisorData)
    if not advisorData or not mgr then return end

    if Controls.AdvisorBase:IsHidden() and Controls.MetaBase:IsHidden() then return end

    local isPortrait = advisorData.ShowPortrait

    local bodyWidget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvisorPopupStaticText"), "StaticText", {
        Label = function()
            if isPortrait then
                return Controls.InfoString:GetText() or ""
            end
            return Controls.MetaInfoString:GetText() or ""
        end,
    })

    -- Drive the live vanilla button controls. Each DialogButton instance in the
    -- (Meta)ButtonStack already registers a Mouse.eLClick callback that calls
    -- OnHideAdvisorDialog() + the advisor button func, so we just DoLeftClick it.
    local buttonStack = isPortrait and Controls.ButtonStack or Controls.MetaButtonStack
    local buttonRow = {}
    for _, native in ipairs(buttonStack:GetChildren() or {}) do
        local btnWidget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvisorPopupButton"), "Button", {
            Label = function() return native:GetText() or "" end,
            Tooltip = function() return native:GetToolTipString() or "" end,
            DisabledPredicate = function() return native:IsDisabled() end,
            HiddenPredicate = function() return native:IsHidden() end,
        })
        btnWidget:On("activate", function() native:DoLeftClick() end)
        table.insert(buttonRow, btnWidget)
    end

    local function GetTitle()
        if isPortrait then
            return Controls.TitleText:GetText() or ""
        end
        return Controls.MetaTitleText:GetText() or ""
    end
    m_tutorialPanel = mgr.WidgetHelpers.MakeGeneralDialog(GetTitle, buttonRow, { bodyWidget })
    if not m_tutorialPanel then return end
    mgr:Push(m_tutorialPanel, { priority = PopupPriority.Tutorial })
end)


OnHideAdvisorDialog = WrapFunc(OnHideAdvisorDialog, function(orig)
    orig()
    if mgr:GetTop() == m_tutorialPanel then
        mgr:Pop()
    end
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
    if mgr and mgr:GetTop() ~= m_tutorialPanel then return false end
    -- We need to let input pass through if either of the popup base controls are not visible, otherwise input is doubled in world
    local isAdvisorVisible = not ContextPtr:IsHidden() and
        (not Controls.AdvisorBase:IsHidden() or not Controls.MetaBase:IsHidden())
    if not isAdvisorVisible then return false end
    local handled = mgr:HandleInput(pInputStruct)
    if handled then return handled end
    return orig(pInputStruct)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)
