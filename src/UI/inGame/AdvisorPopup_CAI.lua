include("AdvisorPopup")
include("caiUtils")
local mgr = ExposedMembers.CAI_UIManager

local m_tutorialPanel = nil ---@type UIWidget|nil

OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
    if mgr then
        mgr:HandleInput(pInputStruct)
    end
    return orig(pInputStruct)
end)

ShowAdvisorPopup = WrapFunc(ShowAdvisorPopup, function(orig, advisorData)
    orig(advisorData)
    ContextPtr:SetInputHandler(OnInputHandler, true)
    if not advisorData or not mgr then return end

    -- If the popup dismissed itself immediately (bHideAdvisor: no button funcs), nothing to show
    if Controls.AdvisorBase:IsHidden() and Controls.MetaBase:IsHidden() then return end

    local isPortrait = advisorData.ShowPortrait

    -- Clean up any lingering panel from a previous call
    if m_tutorialPanel and mgr:HasWidget(m_tutorialPanel) then
        mgr:Pop()
    end

    -- Portrait branch: CalloutHeader is the popup title; meta branch has no equivalent
    m_tutorialPanel = mgr:CreateUIWidget("Dialog", {
        GetLabel = function()
            if isPortrait and advisorData.CalloutHeader and advisorData.CalloutHeader ~= "" then
                return Locale.Lookup(advisorData.CalloutHeader)
            end
            return Locale.Lookup("LOC_CAI_ADVISOR_POPUP")
        end
    })

    -- Main message text — visible in both branches
    if advisorData.Message then
        local bodyWidget = mgr:CreateUIWidget("StaticText", {
            GetLabel = function() return Locale.Lookup(advisorData.Message) end
        })
        m_tutorialPanel:AddChild(bodyWidget)
    end

    -- CalloutBody lives inside AdvisorBase, so only include it in the portrait branch
    if isPortrait
            and advisorData.CalloutBody
            and advisorData.CalloutBody ~= ""
            and advisorData.CalloutBody ~= advisorData.Message then
        local calloutWidget = mgr:CreateUIWidget("StaticText", {
            GetLabel = function() return Locale.Lookup(advisorData.CalloutBody) end
        })
        m_tutorialPanel:AddChild(calloutWidget)
    end

    -- Action buttons — native order: hide dialog first, then run the callback
    -- After orig() runs, nil funcs have been replaced with ClearActive defaults
    local buttons = {
        {text = advisorData.Button1Text, func = advisorData.Button1Func},
        {text = advisorData.Button2Text, func = advisorData.Button2Func}
    }

    for _, btn in ipairs(buttons) do
        if btn.text then
            local capturedFunc = btn.func
            local btnWidget = mgr:CreateUIWidget("Button", {
                GetLabel = function() return Locale.Lookup(btn.text) end,
                OnClick = function()
                    OnHideAdvisorDialog()
                    if capturedFunc then capturedFunc(advisorData) end
                    -- Pop here for non-tutorial path where Close() is never called
                    if mgr and m_tutorialPanel and mgr:HasWidget(m_tutorialPanel) then
                        mgr:Pop()
                    end
                    m_tutorialPanel = nil
                end
            })
            m_tutorialPanel:AddChild(btnWidget)
        end
    end

    mgr:Push(m_tutorialPanel)
end)

-- Tutorial path: Close() is called from OnAdvisorLower when the tutorial system
-- dismisses the popup. HasWidget guard prevents double-pop if a button was clicked first.
Close = WrapFunc(Close, function(orig)
    orig()
    if mgr and m_tutorialPanel and mgr:HasWidget(m_tutorialPanel) then
        mgr:Pop()
    end
    m_tutorialPanel = nil
    UITutorialManager:SetActiveAlways(false)
end)
