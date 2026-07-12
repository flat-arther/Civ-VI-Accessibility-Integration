include("caiUtils")
include("Civ6Common")

if IsExpansion2Active() then
    include("ActionPanel_Expansion2")
elseif IsExpansion1Active() then
    include("ActionPanel_Expansion1")
else
    include("ActionPanel")
end

local mgr = ExposedMembers.CAI_UIManager

local ACTION_PANEL_LIST_ID = "CAIActionPanelTurnBlockerList"
local END_TURN_ACTION = Input.GetActionId("EndTurn")
local CAI_END_TURN_ACTION = Input.GetActionId("ReplaceEndTurn_CAI")
local CAI_OPEN_TURN_BLOCKERS_ACTION = Input.GetActionId("ActionPanelOpenTurnBlockers")
local CAI_SPEAK_ERA_AGE_ACTION = Input.GetActionId("ActionPanelSpeakEraAge")
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
    if ContextPtr:IsHidden() then return false end
    if IsTutorialActionPanelAllowed ~= nil and not IsTutorialActionPanelAllowed() then return false end

    local playerID = Game.GetLocalPlayer()
    if playerID == nil or playerID < 0 then return false end

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

local function MakeActionButton(list, data)
    local btn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIActionPanelButton"), "Button", {
        Label = data.Label,
        Tooltip = data.Tooltip,
        Value = data.Value,
        HiddenPredicate = data.HiddenPredicate,
        DisabledPredicate = data.DisabledPredicate,
    })
    btn:SetFocusSound("Main_Menu_Mouse_Over")
    btn:On("activate", function(w)
        if w:IsHidden() then return end
        if w:IsDisabled() then return end
        CloseTurnBlockerList()
        data.OnActivate()
    end)
    list:AddChild(btn)
    return btn
end

local function AddPrimaryAction(list, activeBlocker)
    MakeActionButton(list, {
        Label = function()
            local text = ControlText(Controls.EndTurnText)
            if text ~= "" then return text end

            local info = activeBlocker and g_kMessageInfo and g_kMessageInfo[activeBlocker] or nil
            if info and info.Message then return info.Message end

            return Locale.Lookup("LOC_ACTION_PANEL_END_TURN")
        end,
        Tooltip = function()
            return ControlTooltip(Controls.EndTurnButton)
        end,
        Value = function()
            if activeBlocker == nil then return "" end

            local count = CountBlockerType(activeBlocker)
            if count >= 2 then
                return Locale.Lookup("LOC_CAI_ACTION_PANEL_BLOCKER_COUNT", count)
            end
            return ""
        end,
        HiddenPredicate = function()
            return ContextPtr:IsHidden()
                or not IsActionPanelInputEnabled()
        end,
        DisabledPredicate = function()
            return ControlIsDisabled(Controls.EndTurnButton)
                or ControlIsDisabled(Controls.EndTurnButtonLabel)
        end,
        OnActivate = function()
            DoEndTurn()
        end,
    })
end

local function AddBlockerAction(list, blockerType, backingControl)
    local capturedType = blockerType
    local capturedControl = backingControl

    MakeActionButton(list, {
        Label = function()
            local info = g_kMessageInfo and g_kMessageInfo[capturedType] or nil
            if info and info.Message then return info.Message end
            return tostring(capturedType)
        end,
        Tooltip = function()
            local tooltip = ControlTooltip(capturedControl)
            if tooltip ~= "" then return tooltip end

            local info = g_kMessageInfo and g_kMessageInfo[capturedType] or nil
            if info and info.ToolTip then return info.ToolTip end
            return ""
        end,
        Value = function()
            local count = CountBlockerType(capturedType)
            if count >= 2 then
                return Locale.Lookup("LOC_CAI_ACTION_PANEL_BLOCKER_COUNT", count)
            end
            return ""
        end,
        HiddenPredicate = function()
            return ContextPtr:IsHidden()
                or not IsActionPanelInputEnabled()
        end,
        DisabledPredicate = function()
            return capturedControl ~= nil and ControlIsDisabled(capturedControl)
        end,
        OnActivate = function()
            DoEndTurn(capturedType)
        end,
    })
end

local function BuildTurnBlockerList()
    if not mgr then return nil end

    local playerID = GetLocalPlayerID()
    if playerID == nil then return nil end

    local list = mgr:CreateWidget(ACTION_PANEL_LIST_ID, "List", {
        Label = function() return Locale.Lookup("LOC_CAI_ACTION_PANEL_TURN_BLOCKERS") end,
    })
    list:AddInputBinding({
        Key = Keys.VK_ESCAPE,
        Description = "LOC_CAI_KB_CLOSE",
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
        list:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAIActionPanelStaticText"), "StaticText", {
            Label = function() return Locale.Lookup("LOC_CAI_ACTION_PANEL_NO_TURN_BLOCKERS") end,
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
        mgr:Push(list, { priority = PopupPriority.Low })
    else
        Speak(Locale.Lookup("LOC_CAI_ACTION_PANEL_NO_TURN_BLOCKERS"))
    end
end

-- ===========================================================================
-- Era age speech
-- ===========================================================================
local function GetEraName()
    if IsExpansion1Active() or IsExpansion2Active() then
        local currentEra = Game.GetEras():GetCurrentEra()
        local kEraData = GameInfo.Eras[currentEra]
        if kEraData then return Locale.Lookup(kEraData.Name) end
    else
        local playerID = GetLocalPlayerID()
        if playerID == nil then return nil end
        local player = Players[playerID]
        if player == nil then return nil end
        local eraIndex = player:GetEra() + 1
        for row in GameInfo.Eras() do
            if row.ChronologyIndex == eraIndex then
                return Locale.Lookup(row.Name)
            end
        end
    end
    return nil
end

local function SpeakEraAge()
    local playerID = GetLocalPlayerID()
    if playerID == nil then return end

    local parts = {}

    local eraName = GetEraName()
    if eraName then
        table.insert(parts, eraName)
    end

    if not (IsExpansion1Active() or IsExpansion2Active()) then
        Speak(table.concat(parts, ", "))
        return
    end

    local gameEras = Game.GetEras()
    if gameEras == nil then return end

    local isFinalEra = gameEras:GetCurrentEra() == gameEras:GetFinalEra()

    if not isFinalEra then
        local countdown = gameEras:GetNextEraCountdown() + 1
        if countdown > 0 then
            table.insert(parts, Locale.Lookup("LOC_GLORY_HUD_ERA_ENDS_IN", countdown))
        end
    end

    local score = gameEras:GetPlayerCurrentScore(playerID)
    table.insert(parts, Locale.Lookup("LOC_ERA_SCORE_HEADER") .. " " .. score)

    if gameEras:HasHeroicGoldenAge(playerID) then
        table.insert(parts, Locale.Lookup("LOC_ERA_PROGRESS_HEROIC_AGE"))
    elseif gameEras:HasGoldenAge(playerID) then
        table.insert(parts, Locale.Lookup("LOC_ERA_PROGRESS_GOLDEN_AGE"))
    elseif gameEras:HasDarkAge(playerID) then
        table.insert(parts, Locale.Lookup("LOC_ERA_PROGRESS_DARK_AGE"))
    else
        table.insert(parts, Locale.Lookup("LOC_ERA_PROGRESS_NORMAL_AGE"))
    end

    if not isFinalEra then
        local darkAgeThreshold = gameEras:GetPlayerDarkAgeThreshold(playerID)
        local goldenAgeThreshold = gameEras:GetPlayerGoldenAgeThreshold(playerID)
        table.insert(parts, Locale.Lookup("LOC_CAI_ACTION_PANEL_ERA_THRESHOLDS",
            darkAgeThreshold, goldenAgeThreshold))
    end

    local activeCommemorations = gameEras:GetPlayerActiveCommemorations(playerID)
    if activeCommemorations and #activeCommemorations > 0 then
        table.insert(parts, Locale.Lookup("LOC_CAI_ACTION_PANEL_DEDICATIONS"))
        for _, activeCommemoration in ipairs(activeCommemorations) do
            local commemorationInfo = GameInfo.CommemorationTypes[activeCommemoration]
            if commemorationInfo ~= nil then
                local dedicationName = commemorationInfo.CategoryDescription and
                    Locale.Lookup(commemorationInfo.CategoryDescription) or ""
                local bonusText = nil
                if gameEras:HasGoldenAge(playerID) then
                    bonusText = Locale.Lookup(commemorationInfo.GoldenAgeBonusDescription)
                    if gameEras:IsPlayerAlwaysAllowedCommemorationQuest(playerID) then
                        bonusText = bonusText .. ", " .. Locale.Lookup(commemorationInfo.NormalAgeBonusDescription)
                    end
                elseif gameEras:HasDarkAge(playerID) then
                    bonusText = Locale.Lookup(commemorationInfo.DarkAgeBonusDescription)
                else
                    bonusText = Locale.Lookup(commemorationInfo.NormalAgeBonusDescription)
                end
                if bonusText then
                    local afterNewline = string.match(bonusText, "%[NEWLINE%](.+)")
                    if afterNewline then
                        bonusText = afterNewline
                    end
                    table.insert(parts, dedicationName .. ": " .. bonusText)
                end
            end
        end
    end

    Speak(table.concat(parts, ", "))
end

-- ===========================================================================
-- Input
-- ===========================================================================
OnInputActionStarted = WrapFunc(OnInputActionTriggered, function(orig, actionId)
    if ContextPtr:IsHidden() then return end

    if actionId == CAI_OPEN_TURN_BLOCKERS_ACTION then
        OpenTurnBlockerList()
        return
    end

    if actionId == CAI_SPEAK_ERA_AGE_ACTION then
        SpeakEraAge()
        return
    end

    if actionId == CAI_END_TURN_ACTION or actionId == END_TURN_ACTION then
        if not IsEndTurnActionEnabled() then return end
        orig(END_TURN_ACTION)
        return
    end
end)

OnRefresh = WrapFunc(OnRefresh, function(orig, ...)
    orig(...)
    SpeakCurrentActionTooltipIfChanged()
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

LateInitialize = WrapFunc(LateInitialize, function(orig, ...)
    orig(...)
    Events.InputActionTriggered.Remove(OnInputActionTriggered)
end)

ContextPtr:SetRefreshHandler(OnRefresh)
ContextPtr:SetInputHandler(OnCAIActionPanelInputHandler, true)
Events.InputActionStarted.Add(OnInputActionStarted)
