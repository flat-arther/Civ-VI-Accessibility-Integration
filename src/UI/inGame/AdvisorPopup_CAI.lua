include("caiUtils")
include("InputSupport")
include("AdvisorPopup")
local mgr = ExposedMembers.CAI_UIManager

local m_tutorialPanel = nil ---@type UIWidget|nil

OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
    -- We need to let input pass through if either of the popup base controls are not visible, otherwise input is doubled in world
    local isAdvisorVisible = not ContextPtr:IsHidden() and
        (not Controls.AdvisorBase:IsHidden() or not Controls.MetaBase:IsHidden())
    if not isAdvisorVisible then return false end
    if mgr then
        local handled = mgr:GetTop() == m_tutorialPanel and mgr:HandleInput(pInputStruct)
        if handled then return handled end
    end
    return orig(pInputStruct)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)

ShowAdvisorPopup = WrapFunc(ShowAdvisorPopup, function(orig, advisorData)
    orig(advisorData)
    if not advisorData or not mgr then return end

    if Controls.AdvisorBase:IsHidden() and Controls.MetaBase:IsHidden() then return end

    local isPortrait = advisorData.ShowPortrait

    --m_tutorialPanel =
    local bodyWidget = mgr:CreateUIWidget("StaticText", {
        GetValue = function()
            if isPortrait then
                return Controls.InfoString:GetText()
            end
            return Controls.MetaInfoString:GetText()
        end
    })


    local buttons = {
        { text = advisorData.Button1Text, func = advisorData.Button1Func },
        { text = advisorData.Button2Text, func = advisorData.Button2Func }
    }
    local buttonRow = {}
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
            table.insert(buttonRow, btnWidget)
        end
    end
    local function GetTitle()
        if isPortrait then
            return Controls.TitleText:GetText()
        end
        return Controls.MetaTitleText:GetText()
    end
    m_tutorialPanel = mgr.WidgetTemplateHelpers:MakeGeneralDialog(GetTitle, buttonRow, { bodyWidget })
    if not m_tutorialPanel then return end
    m_tutorialPanel.SpeechSettings = { Role = false, Label = false }
    mgr:Push(m_tutorialPanel, PopupPriority.Tutorial)
end)


OnHideAdvisorDialog = WrapFunc(OnHideAdvisorDialog, function(orig)
    orig()
    if mgr:GetTop() == m_tutorialPanel then
        mgr:Pop()
    end
    Input.SetActiveContext(InputContext.World)
end)
