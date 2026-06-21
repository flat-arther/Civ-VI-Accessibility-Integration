include("caiUtils")
include("SecretSocietyPopup")
local mgr = ExposedMembers.CAI_UIManager
local m_dialog = nil ---@type UIWidget|nil
Open = WrapFunc(Open, function(orig)
    orig()
    if not mgr then return end
    local govBtn = mgr:CreateWidget("CAIGovButton", "Button", {
        Label = function() return Controls.OpenGovernorsButton:GetText() or "" end,
    })
    govBtn:SetHiddenPredicate(Controls.OpenGovernorsButton:IsHidden())
    govBtn:On("activate", function(w)
        Controls.OpenGovernorsButton:DoLeftClick()
    end)
    local okBtn = mgr:CreateWidget("CAIContinueButton", "Button", {
        Label = function() return Controls.ContinueButton:GetText() or "" end,
    })
    okBtn:SetHiddenPredicate(Controls.OpenGovernorsButton:IsHidden())
    okBtn:On("activate", function(w)
        Controls.ContinueButton:DoLeftClick()
    end)

    local evDesc = mgr:CreateWidget(mgr:GenerateWidgetId("CAIEventDescription"), "StaticText", {
        Label = function() return Controls.EventDescription:GetText() or "" end
    })
    m_dialog = mgr.WidgetHelpers.MakeGeneralDialog(function() return Controls.EventTitle:GetText() or "" end,
        { govBtn, okBtn }, { evDesc })
    if m_dialog then
        mgr:Push(m_dialog)
    end
end)

Close = WrapFunc(Close, function(orig)
    if m_dialog then
        mgr:RemoveFromStack(m_dialog:GetId())
    end
    orig()
end)

Controls.OpenGovernorsButton:RegisterCallback(Mouse.eLClick, OnOpenGovernorsButton);
Controls.ContinueButton:RegisterCallback(Mouse.eLClick, OnContinueButton);
