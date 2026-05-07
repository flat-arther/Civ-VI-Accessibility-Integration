include("caiUtils")
include("LeaderView")

local mgr = ExposedMembers.CAI_UIManager
local CAI_LeaderViewDialog = nil ---@type UIWidget|nil

local function IsLeaderViewVisible()
    return not ContextPtr:IsHidden()
end

local function RemoveLeaderViewDialog()
    if not mgr or not CAI_LeaderViewDialog then return end
    if mgr:HasWidget(CAI_LeaderViewDialog) and mgr:GetTop() == CAI_LeaderViewDialog then
        mgr:Pop()
    end

    CAI_LeaderViewDialog = nil
end

local function HasVisibleControlText(control)
    if not control or control.IsHidden and control:IsHidden() then return false end
    local text = control.GetText and control:GetText() or nil
    return text ~= nil and text ~= ""
end

local function BuildLeaderViewDialog()
    if not mgr or not IsLeaderViewVisible() then return end

    RemoveLeaderViewDialog()

    local content = {
        mgr:CreateUIWidget(mgr:GenerateWidgetId("CAILeaderViewStaticText"), "StaticText", {
            GetValue = function()
                return Controls.LeaderText:GetText()
            end,
        })
    }

    local buttons = {}
    local vanillaButtons = {
        { control = Controls.DeclareWarButton, action = function() OnDeclareWar() end },
        { control = Controls.GoodbyeButton,    action = function() OnContinue() end },
    }

    for _, entry in ipairs(vanillaButtons) do
        if HasVisibleControlText(entry.control) then
            local control = entry.control
            local action = entry.action
            table.insert(buttons, mgr:CreateUIWidget(mgr:GenerateWidgetId("CAILeaderViewButton"), "Button", {
                GetLabel = function()
                    return control:GetText()
                end,
                GetTooltip = function()
                    return control:GetToolTipString() or ""
                end,
                IsDisabled = function()
                    return control:IsDisabled()
                end,
                OnClick = function()
                    action()
                end,
                OnFocusEnter = function()
                    UI.PlaySound("Main_Menu_Mouse_Over")
                end,
            }))
        end
    end

    if #buttons == 0 then return end

    local function GetTitle()
        return Controls.LeaderText:GetText()
    end

    CAI_LeaderViewDialog = mgr.WidgetTemplateHelpers:MakeGeneralDialog(GetTitle, buttons, content)
    if not CAI_LeaderViewDialog then return end

    CAI_LeaderViewDialog.SpeechSettings = { Role = false }
    mgr:Push(CAI_LeaderViewDialog, PopupPriority.Current)
end

OnContinue = WrapFunc(OnContinue, function(orig)
    --RemoveLeaderViewDialog()
    orig()
end)

OnDeclareWar = WrapFunc(OnDeclareWar, function(orig)
    RemoveLeaderViewDialog()
    orig()
    BuildLeaderViewDialog()
end)

ShowFirstMeetingLeader = WrapFunc(ShowFirstMeetingLeader, function(orig, firstPlayer, secondPlayer)
    orig(firstPlayer, secondPlayer)
    BuildLeaderViewDialog()
end)

ShowWarLeader = WrapFunc(ShowWarLeader, function(orig, actingPlayer, reactingPlayer)
    orig(actingPlayer, reactingPlayer)
    BuildLeaderViewDialog()
end)

ShowRefusePeaceLeader = WrapFunc(ShowRefusePeaceLeader, function(orig, actingPlayer, reactingPlayer)
    orig(actingPlayer, reactingPlayer)
    BuildLeaderViewDialog()
end)

OnTalkToLeader = WrapFunc(OnTalkToLeader, function(orig, playerID)
    orig(playerID)
    BuildLeaderViewDialog()
end)

local function OnCAILeaderViewHide()
    RemoveLeaderViewDialog()
end

ContextPtr:SetHideHandler(OnCAILeaderViewHide)

local function OnCAILeaderViewInput(pInputStruct)
    if mgr:GetTop() ~= CAI_LeaderViewDialog then return false end

    return mgr:HandleInput(pInputStruct)
end

ContextPtr:SetInputHandler(OnCAILeaderViewInput, true)
