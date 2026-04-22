include("caiUtils")
include("InputSupport")
include("AdvisorPopup")
local mgr = ExposedMembers.CAI_UIManager

local m_tutorialPanel = nil ---@type UIWidget|nil

OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
    -- We need to let input pass through if either of the popup base controls are not visible, otherwise input is doubled in world
    local isAdvisorVisible = not Controls.AdvisorBase:IsHidden() or not Controls.MetaBase:IsHidden();
    if not isAdvisorVisible then return false end
    if mgr then
        mgr:HandleInput(pInputStruct)
    end
    return orig(pInputStruct)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)

ShowAdvisorPopup = WrapFunc(ShowAdvisorPopup, function(orig, advisorData)
    orig(advisorData)
    if not advisorData or not mgr then return end

    if Controls.AdvisorBase:IsHidden() and Controls.MetaBase:IsHidden() then return end

    local isPortrait = advisorData.ShowPortrait

    m_tutorialPanel = mgr:CreateUIWidget("Dialog", {
        GetLabel = function()
            if isPortrait then
                return Controls.TitleText:GetText()
            end
            return Controls.MetaTitleText:GetText()
        end
    })

    local bodyWidget = mgr:CreateUIWidget("StaticText", {
        GetLabel = function()
            if isPortrait then
                return Controls.InfoString:GetText()
            end
            return Controls.MetaInfoString:GetText()
        end
    })
    m_tutorialPanel:AddChild(bodyWidget)


    local buttons = {
        { text = advisorData.Button1Text, func = advisorData.Button1Func },
        { text = advisorData.Button2Text, func = advisorData.Button2Func }
    }

    for _, btn in ipairs(buttons) do
        if btn.text then
            local capturedFunc = btn.func
            local btnWidget = mgr:CreateUIWidget("Button", {
                GetLabel = function() return Locale.Lookup(btn.text) end,
                OnClick = function()
                    OnHideAdvisorDialog()
                    if capturedFunc then capturedFunc(advisorData) end
                end
            })
            m_tutorialPanel:AddChild(btnWidget)
        end
    end

    mgr:Push(m_tutorialPanel)
end)


OnHideAdvisorDialog = WrapFunc(OnHideAdvisorDialog, function(orig)
    orig()
    mgr:Pop()
    -- Tutorials tend to set input context to 'Tutorial' which does not allow world input to execute, Meaning no keyboard input. Yeah, screw that
    Input.SetActiveContext(InputContext.World)
end)
