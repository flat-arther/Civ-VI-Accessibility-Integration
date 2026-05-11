include("caiUtils")
include("LeaderView")
Speak("Leader view shown")
local mgr = ExposedMembers.CAI_UIManager
local CAI_LeaderViewDialog = nil ---@type UIWidget|nil

local function IsLeaderViewVisible()
    return not ContextPtr:IsHidden()
end

local function RemoveLeaderViewDialog()
    if not mgr or not CAI_LeaderViewDialog then return end
    if mgr:HasWidget(CAI_LeaderViewDialog) then
        mgr:RemoveFromStack(CAI_LeaderViewDialog:GetId())
    end

    CAI_LeaderViewDialog = nil
end

local function GetLiveControlText(control)
    if not control or control.IsHidden and control:IsHidden() then return nil end
    local text = control.GetText and control:GetText() or nil
    if text and text ~= "" then
        return text
    end

    if control.GetChildren then
        for _, child in ipairs(control:GetChildren()) do
            local childText = GetLiveControlText(child)
            if childText and childText ~= "" then
                return childText
            end
        end
    end

    return nil
end

local function HasVisibleControlText(control)
    if not control or control.IsHidden and control:IsHidden() then return false end
    local text = GetLiveControlText(control)
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
                    return GetLiveControlText(control) or ""
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

local function OnCAILeaderViewShow()
    BuildLeaderViewDialog()
end

local function OnCAILeaderViewHide()
    RemoveLeaderViewDialog()
end

ContextPtr:SetShowHandler(OnCAILeaderViewShow)
ContextPtr:SetHideHandler(OnCAILeaderViewHide)

local function OnCAILeaderViewInput(pInputStruct)
    if not mgr then return false end
    if mgr:GetTop() ~= CAI_LeaderViewDialog then return false end

    return mgr:HandleInput(pInputStruct)
end

ContextPtr:SetInputHandler(OnCAILeaderViewInput, true)

OnContinue = WrapFunc(OnContinue, function(orig, ...)
    RemoveLeaderViewDialog()
    return orig(...)
end)

OnDeclareWar = WrapFunc(OnDeclareWar, function(orig, ...)
    RemoveLeaderViewDialog()
    local result = orig(...)
    if IsLeaderViewVisible() then
        BuildLeaderViewDialog()
    end
    return result
end)

Controls.GoodbyeButton:ClearCallback(Mouse.eLClick)
Controls.GoodbyeButton:RegisterCallback(Mouse.eLClick, OnContinue)
Controls.DeclareWarButton:ClearCallback(Mouse.eLClick)
Controls.DeclareWarButton:RegisterCallback(Mouse.eLClick, OnDeclareWar)
