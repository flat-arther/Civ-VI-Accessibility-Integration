include("caiUtils")
include("ActionPanel")

local mgr = ExposedMembers.CAI_UIManager

local ACTION_PANEL_LIST_ID = "CAIActionPanelTurnBlockerList"
local END_TURN_ACTION = Input.GetActionId("EndTurn")
local CAI_END_TURN_ACTION = Input.GetActionId("SharedEndTurn")
local CAI_OPEN_TURN_BLOCKERS_ACTION = Input.GetActionId("ActionPanelOpenTurnBlockers")
local m_caiTutorialActionPanelAllowed = false
local m_caiLastSpokenActionTooltip = nil
local IsTutorialActionPanelAllowed = nil

local function ControlIsHidden(control)
    return control and control.IsHidden and control:IsHidden() or false
end

local function ControlIsDisabled(control)
    return control and control.IsDisabled and control:IsDisabled() or false
end

local function ControlText(control)
    if control and control.GetText then
        local text = control:GetText()
        if text and text ~= "" then return text end
    end
    return ""
end

local function ControlTooltip(control)
    if control and control.GetToolTipString then
        local text = control:GetToolTipString()
        if text and text ~= "" then return text end
    end
    return ""
end

local function CanSpeakCurrentAction()
    if ContextPtr:IsHidden() then return end
    if IsTutorialActionPanelAllowed ~= nil and not IsTutorialActionPanelAllowed() then return false end

    local playerID = Game.GetLocalPlayer()
    local player = playerID and playerID >= 0 and Players[playerID] or nil
    if player == nil or not player:IsTurnActive() then return false end

    return true
end

local function SpeakCurrentActionTooltipIfChanged(force)
    if not CanSpeakCurrentAction() then return end

    local tooltip = ControlTooltip(Controls.EndTurnButton)
    if tooltip == "" then return end
    if not force and tooltip == m_caiLastSpokenActionTooltip then return end

    m_caiLastSpokenActionTooltip = tooltip
    Speak(tooltip)
end

IsTutorialActionPanelAllowed = function()
    if type(IsTutorialRunning) == "function" and IsTutorialRunning() then
        return m_caiTutorialActionPanelAllowed
    end
    return true
end

local function IsActionPanelInputEnabled()
    return IsTutorialActionPanelAllowed()
        and ControlIsHidden(Controls.TutorialSlowTurnEnableAnim)
end

local function IsEndTurnActionEnabled()
    return not ContextPtr:IsHidden()
        and IsActionPanelInputEnabled()
        and not ControlIsDisabled(Controls.EndTurnButton)
        and not ControlIsDisabled(Controls.EndTurnButtonLabel)
end

local function GetLocalPlayerID()
    local playerID = Game.GetLocalPlayer()
    if playerID == nil or playerID < 0 then return nil end
    return playerID
end

local function CloseTurnBlockerList()
    if mgr then
        mgr:RemoveFromStack(ACTION_PANEL_LIST_ID)
    end
end

local function CountBlockerType(blockerType)
    local playerID = GetLocalPlayerID()
    if playerID == nil then return 0 end

    local count = 0
    local blockers = NotificationManager.GetAllEndTurnBlocking(playerID)
    if blockers == nil then return count end

    for _, currentType in ipairs(blockers) do
        if currentType == blockerType then
            count = count + 1
        end
    end
    return count
end

local function MakeActionButton(data)
    return mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIActionPanelButton"), "Button", {
        GetLabel = data.GetLabel,
        GetTooltip = data.GetTooltip,
        GetValue = data.GetValue,
        IsHidden = data.IsHidden,
        IsDisabled = data.IsDisabled,
        OnFocusEnter = function()
            UI.PlaySound("Main_Menu_Mouse_Over")
        end,
        OnClick = function()
            if data.IsHidden and data.IsHidden() then return end
            if data.IsDisabled and data.IsDisabled() then return end
            CloseTurnBlockerList()
            data.OnClick()
        end,
    })
end

local function AddPrimaryAction(list, activeBlocker)
    list:AddChild(MakeActionButton({
        GetLabel = function()
            local text = ControlText(Controls.EndTurnText)
            if text ~= "" then return text end

            local info = activeBlocker and g_kMessageInfo and g_kMessageInfo[activeBlocker] or nil
            if info and info.Message then return info.Message end

            return Locale.Lookup("LOC_ACTION_PANEL_END_TURN")
        end,
        GetTooltip = function()
            return ControlTooltip(Controls.EndTurnButton)
        end,
        GetValue = function()
            if activeBlocker == nil then return "" end

            local count = CountBlockerType(activeBlocker)
            if count >= 2 then
                return Locale.Lookup("LOC_CAI_ACTION_PANEL_BLOCKER_COUNT", count)
            end
            return ""
        end,
        IsHidden = function()
            return ContextPtr:IsHidden()
                or not IsActionPanelInputEnabled()
        end,
        IsDisabled = function()
            return ControlIsDisabled(Controls.EndTurnButton)
                or ControlIsDisabled(Controls.EndTurnButtonLabel)
        end,
        OnClick = function()
            DoEndTurn()
        end,
    }))
end

local function AddBlockerAction(list, blockerType, backingControl)
    local capturedType = blockerType
    local capturedControl = backingControl

    list:AddChild(MakeActionButton({
        GetLabel = function()
            local info = g_kMessageInfo and g_kMessageInfo[capturedType] or nil
            if info and info.Message then return info.Message end
            return tostring(capturedType)
        end,
        GetTooltip = function()
            local tooltip = ControlTooltip(capturedControl)
            if tooltip ~= "" then return tooltip end

            local info = g_kMessageInfo and g_kMessageInfo[capturedType] or nil
            if info and info.ToolTip then return info.ToolTip end
            return ""
        end,
        GetValue = function()
            local count = CountBlockerType(capturedType)
            if count >= 2 then
                return Locale.Lookup("LOC_CAI_ACTION_PANEL_BLOCKER_COUNT", count)
            end
            return ""
        end,
        IsHidden = function()
            return ContextPtr:IsHidden()
                or not IsActionPanelInputEnabled()
        end,
        IsDisabled = function()
            return capturedControl ~= nil and ControlIsDisabled(capturedControl)
        end,
        OnClick = function()
            DoEndTurn(capturedType)
        end,
    }))
end

local function BuildTurnBlockerList()
    if not mgr then return nil end

    local playerID = GetLocalPlayerID()
    if playerID == nil then return nil end

    local list = mgr:CreateUIWidget(ACTION_PANEL_LIST_ID, "List", {
        GetLabel = function()
            return Locale.Lookup("LOC_CAI_ACTION_PANEL_TURN_BLOCKERS")
        end,
    })
    list:AddInputBinding({
        Key = Keys.VK_ESCAPE,
        Action = function()
            CloseTurnBlockerList()
            return true
        end,
    })

    local activeBlocker = NotificationManager.GetFirstEndTurnBlocking(playerID)
    local blockers = NotificationManager.GetAllEndTurnBlocking(playerID) or {}
    local visibleTypes = {}
    local secondaryControlIndex = 2

    AddPrimaryAction(list, activeBlocker)
    if activeBlocker ~= nil then
        visibleTypes[activeBlocker] = true
    end

    for _, blockerType in ipairs(blockers) do
        if blockerType ~= activeBlocker and not visibleTypes[blockerType] then
            local backingControl = nil
            if secondaryControlIndex <= 4 then
                backingControl = Controls["TurnBlockerButton" .. tostring(secondaryControlIndex)]
                secondaryControlIndex = secondaryControlIndex + 1
            end

            AddBlockerAction(list, blockerType, backingControl)
            visibleTypes[blockerType] = true
        end
    end

    if list.Children == nil or #list.Children == 0 then
        list:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIActionPanelStaticText"), "StaticText", {
            GetLabel = function()
                return Locale.Lookup("LOC_CAI_ACTION_PANEL_NO_TURN_BLOCKERS")
            end,
        }))
    end

    return list
end

local function OpenTurnBlockerList()
    if ContextPtr:IsHidden() then return end
    if not IsActionPanelInputEnabled() then return end
    CloseTurnBlockerList()

    local list = BuildTurnBlockerList()
    if list ~= nil and #list:GetVisibleChildren() > 0 then
        mgr:Push(list, PopupPriority.Low)
    else
        Speak(Locale.Lookup("LOC_CAI_ACTION_PANEL_NO_TURN_BLOCKERS"))
    end
end

OnInputActionTriggered = WrapFunc(OnInputActionTriggered, function(orig, actionId)
    if ContextPtr:IsHidden() then return end

    if actionId == CAI_OPEN_TURN_BLOCKERS_ACTION then
        OpenTurnBlockerList()
        return
    end

    if actionId == CAI_END_TURN_ACTION or actionId == END_TURN_ACTION then
        if not IsEndTurnActionEnabled() then return end
        orig(END_TURN_ACTION)
        return
    end

    return orig(actionId)
end)

OnRefresh = WrapFunc(OnRefresh, function(orig, ...)
    local result = orig(...)
    SpeakCurrentActionTooltipIfChanged()
    return result
end)

function OnCAIActionPanelInputHandler(inputStruct)
    if mgr then
        local handled = mgr:HandleInput(inputStruct)
        if handled then return true end
    end
    return false
end

LuaEvents.CAI_TutorialActionPanelAllowed.Add(function(isAllowed)
    m_caiTutorialActionPanelAllowed = isAllowed == true
    if m_caiTutorialActionPanelAllowed then
        SpeakCurrentActionTooltipIfChanged(true)
    end
end)

ContextPtr:SetRefreshHandler(OnRefresh)
ContextPtr:SetInputHandler(OnCAIActionPanelInputHandler, true)
