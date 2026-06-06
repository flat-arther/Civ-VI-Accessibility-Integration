include("caiUtils")
include("WorldCongressIntro")

local mgr = ExposedMembers.CAI_UIManager
local m_dialog = nil ---@type UIWidget|nil

local function RemoveDialog()
    if not mgr or not m_dialog then return end
    mgr:RemoveFromStack(m_dialog:GetId())
    m_dialog = nil
end

local function BuildDialog()
    RemoveDialog()
    if not mgr or ContextPtr:IsHidden() then return end

    local body1 = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWCIntroBody1"), "StaticText", {
        Label = function() return Controls.Body1:GetText() or "" end,
    })
    local body2 = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWCIntroBody2"), "StaticText", {
        Label = function() return Controls.Body2:GetText() or "" end,
    })

    local continueBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWCIntroContinue"), "Button", {
        Label = function() return Controls.AcceptButton:GetText() or "" end,
    })
    continueBtn:On("activate", function() OnClose() end)
    continueBtn:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)

    m_dialog = mgr.WidgetHelpers.MakeGeneralDialog(
        function() return Controls.Title:GetText() or "" end,
        { continueBtn },
        { body1, body2 },
        1
    )
    if not m_dialog then return end

    mgr:Push(m_dialog, { priority = PopupPriority.WorldCongressIntro })
end

OnOpen = WrapFunc(OnOpen, function(orig, stageNum)
    orig(stageNum)
    BuildDialog()
end)

OnClose = WrapFunc(OnClose, function(orig)
    RemoveDialog()
    orig()
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
    if mgr and m_dialog and mgr:GetTop() == m_dialog and not ContextPtr:IsHidden() then
        local handled = mgr:HandleInput(pInputStruct)
        if handled then return handled end
    end
    return orig(pInputStruct)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)
