include("caiUtils")
include("Civ6Common")
if IsExpansion2Active() then
    include("WorldTracker_Expansion1")
elseif IsExpansion1Active() then
    include("WorldTracker_Expansion1")
else
    include("WorldTracker")
end

local mgr                          = ExposedMembers.CAI_UIManager

local info                         = ExposedMembers.CAIInfo or {}
ExposedMembers.CAIInfo             = info

local ACTION_OPEN_RESEARCH_CHOOSER = Input.GetActionId("UI_WorldTrackerOpenResearchChooser")
local ACTION_OPEN_CIVICS_CHOOSER   = Input.GetActionId("UI_WorldTrackerOpenCivicsChooser")
local ACTION_SPEAK_SCIENCE         = Input.GetActionId("UI_TopPanelSpeakScience")
local ACTION_SPEAK_CULTURE         = Input.GetActionId("UI_TopPanelSpeakCulture")

local m_caiWorldTrackerActions     = {}
local m_caiResearchTrackerControl  = nil
local m_caiCivicsTrackerControl    = nil

local CRISIS_LIST_ID               = "CAICrisisTracker_List"
local HOVER_SOUND                  = "Main_Menu_Mouse_Over"
local m_crisisList                 = nil

local function ControlIsHidden(control)
    return control and control.IsHidden and control:IsHidden() or false
end

local function ControlIsDisabled(control)
    return control and control.IsDisabled and control:IsDisabled() or false
end

local function GetLocalPlayer()
    local playerID = Game.GetLocalPlayer()
    if playerID == nil or playerID < 0 then return nil, nil end

    local player = Players[playerID]
    if player == nil then return nil, nil end

    return playerID, player
end

local function AppendIfText(parts, text)
    if text ~= nil and text ~= "" then
        table.insert(parts, text)
    end
end

local function GetCurrentResearchData(playerID, player)
    local techs = player:GetTechs()
    if techs == nil then return nil end

    local techID = techs:GetResearchingTech()
    if techID == nil or techID < 0 then return nil end

    local tech = GameInfo.Technologies[techID]
    if tech == nil then return nil end

    return GetResearchData(playerID, techs, tech)
end

local function GetCurrentCivicData(playerID, player)
    local culture = player:GetCulture()
    if culture == nil then return nil end

    local civicID = culture:GetProgressingCivic()
    if civicID == nil or civicID < 0 then return nil end

    local civic = GameInfo.Civics[civicID]
    if civic == nil then return nil end

    return GetCivicData(playerID, culture, civic)
end

local function GetAllianceResearchText(data)
    if not (IsExpansion1Active() or IsExpansion2Active()) then return nil end
    if data == nil or data.TechType == nil then return nil end
    local techInfo = GameInfo.Technologies[data.TechType]
    if techInfo == nil then return nil end
    if AllyHasOrIsResearchingTech and AllyHasOrIsResearchingTech(techInfo.Index) then
        if GetAllianceIconToolTip then
            return GetAllianceIconToolTip()
        end
    end
    return nil
end

local function GetBoostText(kData)
    if not kData or not kData.Boostable then return nil end
    local trigger = kData.TriggerDesc and Locale.Lookup(kData.TriggerDesc) or ""
    local prefix = Locale.Lookup(kData.BoostTriggered and "LOC_BOOST_BOOSTED" or "LOC_BOOST_TO_BOOST")
    if trigger == "" then return prefix end
    return prefix .. " " .. trigger
end

local function AppendResearchSummary(parts, playerID, player)
    local data = GetCurrentResearchData(playerID, player)
    if data == nil then
        AppendIfText(parts, Locale.Lookup("LOC_CAI_WORLDTRACKER_RESEARCH_LINE",
            Locale.Lookup("LOC_WORLD_TRACKER_CHOOSE_RESEARCH")))
        return
    end

    local inner = { data.Name }
    if data.TurnsLeft ~= nil and data.TurnsLeft >= 0 then
        table.insert(inner, Locale.Lookup("LOC_CAI_WORLDTRACKER_TURNS_REMAINING", data.TurnsLeft))
    end

    AppendIfText(inner, GetBoostText(data))

    local allianceText = GetAllianceResearchText(data)
    if allianceText then
        table.insert(inner, allianceText)
    end

    AppendIfText(parts, Locale.Lookup("LOC_CAI_WORLDTRACKER_RESEARCH_LINE", table.concat(inner, ", ")))
end

local function AppendCivicSummary(parts, playerID, player)
    local data = GetCurrentCivicData(playerID, player)
    if data == nil then
        AppendIfText(parts, Locale.Lookup("LOC_CAI_WORLDTRACKER_CIVIC_LINE",
            Locale.Lookup("LOC_WORLD_TRACKER_CHOOSE_CIVIC")))
        return
    end

    local inner = { data.Name }
    if data.TurnsLeft ~= nil and data.TurnsLeft >= 0 then
        table.insert(inner, Locale.Lookup("LOC_CAI_WORLDTRACKER_TURNS_REMAINING", data.TurnsLeft))
    end

    AppendIfText(inner, GetBoostText(data))

    AppendIfText(parts, Locale.Lookup("LOC_CAI_WORLDTRACKER_CIVIC_LINE", table.concat(inner, ", ")))
end

local function FormatYieldPerTurn(value)
    if value == 0 then
        return Locale.ToNumber(value)
    end
    return Locale.Lookup("{1: number +#,###.#;-#,###.#}", value)
end

local function SpeakScienceAndResearch()
    local playerID, player = GetLocalPlayer()
    if playerID == nil or player == nil then return end

    if IsExpansion1Active() or IsExpansion2Active() then
        if CalculateAllianceResearchBonus then
            CalculateAllianceResearchBonus()
        end
    end

    local parts = {}
    if GameCapabilities.HasCapability("CAPABILITY_SCIENCE")
        and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
        local techs = player:GetTechs()
        AppendIfText(parts, Locale.Lookup("LOC_TOP_PANEL_SCIENCE") .. ": "
            .. Locale.Lookup("LOC_HUD_REPORTS_PER_TURN", FormatYieldPerTurn(techs:GetScienceYield())))
    end
    AppendResearchSummary(parts, playerID, player)
    Speak(table.concat(parts, ", "))
end

local function SpeakCultureDetails()
    local playerID, player = GetLocalPlayer()
    if playerID == nil or player == nil then return end

    local parts = {}
    if GameCapabilities.HasCapability("CAPABILITY_CULTURE")
        and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
        local culture = player:GetCulture()
        AppendIfText(parts, Locale.Lookup("LOC_TOP_PANEL_CULTURE") .. ": "
            .. Locale.Lookup("LOC_HUD_REPORTS_PER_TURN", FormatYieldPerTurn(culture:GetCultureYield())))
    end
    AppendCivicSummary(parts, playerID, player)

    local govInfo = info.GetGovernmentInfo and info.GetGovernmentInfo()
    if govInfo then table.insert(parts, govInfo) end

    Speak(table.concat(parts, ", "))
end

-- =============================================
-- Crisis tracker (expansion only)
-- =============================================

local function GetPlayerName(playerID)
    if playerID < 0 then return "" end
    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID < 0 then return "" end
    local pConfig = PlayerConfigurations[playerID]
    if not pConfig then return "" end
    local isMP = GameConfiguration.IsAnyMultiplayer()
    local isMet = (playerID == localPlayerID)
    if not isMet then
        local pDip = Players[localPlayerID]:GetDiplomacy()
        isMet = pDip:HasMet(playerID)
    end
    if not isMet and not (isMP and pConfig:IsHuman()) then
        return Locale.Lookup("LOC_DIPLOPANEL_UNMET_PLAYER")
    end
    local name = Locale.Lookup(pConfig:GetLeaderName())
    if isMP and pConfig:IsHuman() then
        name = name .. " (" .. pConfig:GetPlayerName() .. ")"
    end
    return name
end

local function GetCrisisGoalCounts(crisis)
    local goalsCompleted = 0
    local goalsTotal = 0
    for _, goal in ipairs(crisis.GoalsTable) do
        goalsTotal = goalsTotal + 1
        if goal.Completed then goalsCompleted = goalsCompleted + 1 end
    end
    return goalsCompleted, goalsTotal
end

local function GetCrisisXP2Metadata(crisis)
    if not IsExpansion2Active() then return false, false end
    local kDef = GameInfo.EmergencyAlliances[crisis.EmergencyType]
    if not kDef then return false, false end
    local kMeta = GameInfo.Emergencies_XP2[kDef.EmergencyType]
    if not kMeta then return false, false end
    return kMeta.Hostile, kMeta.NoTarget
end

local function BuildCrisisLabel(crisis, localPlayerID)
    local parts = {}
    local goalsCompleted, goalsTotal = GetCrisisGoalCounts(crisis)
    local bIsHostile, bNoTarget = GetCrisisXP2Metadata(crisis)

    if crisis.TurnsLeft < 0 then
        local isWin = (goalsCompleted == goalsTotal and crisis.TargetID ~= localPlayerID)
            or (crisis.TargetID == localPlayerID and goalsCompleted ~= goalsTotal)
            or (crisis.TargetID == localPlayerID and not bIsHostile)
        table.insert(parts, Locale.Lookup(isWin and "LOC_CAI_CRISIS_STATUS_WON" or "LOC_CAI_CRISIS_STATUS_LOST"))
    elseif crisis.TargetID == localPlayerID then
        table.insert(parts, Locale.Lookup("LOC_CAI_CRISIS_STATUS_TARGETED"))
    elseif crisis.HasBegun then
        table.insert(parts, Locale.Lookup("LOC_CAI_CRISIS_STATUS_JOINED"))
    else
        table.insert(parts, Locale.Lookup("LOC_CAI_CRISIS_STATUS_PENDING"))
    end

    if IsExpansion2Active() then
        table.insert(parts, Locale.Lookup(bIsHostile and "LOC_CAI_CRISIS_HOSTILE" or "LOC_CAI_CRISIS_AID"))
    end

    table.insert(parts, Locale.Lookup(crisis.NameText))

    if crisis.TurnsLeft >= 0 then
        table.insert(parts, Locale.Lookup("LOC_EMERGENCY_TURNS_REMAINING", crisis.TurnsLeft))
    end

    return table.concat(parts, ", ")
end

local function BuildCrisisTooltip(crisis, localPlayerID)
    local parts = {}
    local goalsCompleted, goalsTotal = GetCrisisGoalCounts(crisis)
    local _, bNoTarget = GetCrisisXP2Metadata(crisis)

    if not bNoTarget then
        local targetName = GetPlayerName(crisis.TargetID)
        if targetName ~= "" then
            table.insert(parts, Locale.Lookup("LOC_CAI_CRISIS_TARGET") .. " " .. targetName)
        end
    end

    if crisis.HasBegun then
        local progressPrefix = ""
        local inverseProgressPrefix = ""
        if goalsTotal > 0 then
            progressPrefix = "(" .. goalsCompleted .. "/" .. goalsTotal .. ") "
            inverseProgressPrefix = "(" .. (goalsTotal - goalsCompleted) .. "/" .. goalsTotal .. ") "
        end
        if crisis.TargetID == localPlayerID then
            table.insert(parts, inverseProgressPrefix .. crisis.TargetShortGoalDescription)
        else
            table.insert(parts, progressPrefix .. crisis.ShortGoalDescription)
        end
    else
        table.insert(parts, Locale.Lookup("LOC_EMERGENCY_PENDING_SHORT_DESCRIPTION"))
    end

    if #parts == 0 then return nil end
    return table.concat(parts, ", ")
end

local function RemoveCrisisList()
    if not mgr or not m_crisisList then return end
    mgr:RemoveFromStack(CRISIS_LIST_ID)
    m_crisisList = nil
end

local function BuildAndPushCrisisList()
    RemoveCrisisList()
    if not mgr then return end

    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID < 0 then return end

    local localPlayer = Players[localPlayerID]
    if not localPlayer then return end

    local crisisData = Game.GetEmergencyManager():GetEmergencyInfoTable(localPlayerID)
    if not crisisData or next(crisisData) == nil then
        Speak(Locale.Lookup("LOC_CAI_CRISIS_TRACKER_NONE"))
        return
    end

    m_crisisList = mgr:CreateWidget(CRISIS_LIST_ID, "List", {
        Label = Locale.Lookup("LOC_CAI_CRISIS_TRACKER_TITLE"),
        _focusSound = HOVER_SOUND,
    })

    for i, crisis in ipairs(crisisData) do
        local label = BuildCrisisLabel(crisis, localPlayerID)
        local tooltip = BuildCrisisTooltip(crisis, localPlayerID)

        local boxedCrisis = crisis
        local btn = mgr:CreateWidget("crisis:" .. i, "Button", {
            Label = label,
            Tooltip = tooltip,
            FocusKey = "crisis:" .. i,
            _focusSound = HOVER_SOUND,
        })
        btn:On("activate", function()
            LuaEvents.WorldCrisisTracker_EmergencyClicked(boxedCrisis.TargetID, boxedCrisis.EmergencyType)
            RemoveCrisisList()
        end)
        m_crisisList:AddChild(btn)
    end

    m_crisisList:AddInputBinding({
        Key = Keys.VK_ESCAPE,
        Description = "LOC_CAI_KB_CLOSE",
        Action = function()
            RemoveCrisisList()
            return true
        end
    })

    mgr:Push(m_crisisList)
end

local function ToggleCrisisList()
    if m_crisisList then
        RemoveCrisisList()
    else
        BuildAndPushCrisisList()
    end
end

local function ForceShowChatPanel()
    if not UI.HasFeature("Chat") then return end
    if not (GameConfiguration.IsNetworkMultiplayer() or GameConfiguration.IsPlayByCloud()) then return end

    if m_hideAll then
        ToggleAll(false)
    end
    if m_hideChat then
        UpdateChatPanel(false)
    end

    StartUnitListSizeUpdate()
    CheckEnoughRoom()
end

-- =============================================
-- Input action dispatch
-- =============================================

local function RegisterWorldTrackerAction(actionId, callback)
    if actionId ~= nil then
        m_caiWorldTrackerActions[actionId] = callback
    end
end

local function IsTrackerChooserControlEnabled(control)
    if control == nil then return true end
    return not ControlIsHidden(control.MainPanel)
        and not ControlIsHidden(control.IconButton)
        and not ControlIsDisabled(control.MainPanel)
        and not ControlIsDisabled(control.IconButton)
        and not ControlIsDisabled(control.TitleButton)
end

local function InitializeWorldTrackerActions()
    RegisterWorldTrackerAction(ACTION_OPEN_RESEARCH_CHOOSER, function()
        if IsTutorialRunning() then
            Speak(Locale.Lookup("LOC_CAI_UI_CHOOSER_BLOCKED_BY_TUTORIAL"))
            return
        end
        if not IsTrackerChooserControlEnabled(m_caiResearchTrackerControl) then
            Speak(Locale.Lookup("LOC_CAI_UI_RESEARCH_CHOOSER_UNAVAILABLE"))
            return
        end
        LuaEvents.WorldTracker_OpenChooseResearch()
    end)
    RegisterWorldTrackerAction(ACTION_OPEN_CIVICS_CHOOSER, function()
        if IsTutorialRunning() then
            Speak(Locale.Lookup("LOC_CAI_UI_CHOOSER_BLOCKED_BY_TUTORIAL"))
            return
        end
        if not IsTrackerChooserControlEnabled(m_caiCivicsTrackerControl) then
            Speak(Locale.Lookup("LOC_CAI_UI_CIVICS_CHOOSER_UNAVAILABLE"))
            return
        end
        LuaEvents.WorldTracker_OpenChooseCivic()
    end)
    RegisterWorldTrackerAction(ACTION_SPEAK_SCIENCE, SpeakScienceAndResearch)
    RegisterWorldTrackerAction(ACTION_SPEAK_CULTURE, SpeakCultureDetails)

    if IsExpansion1Active() or IsExpansion2Active() then
        local ACTION_OPEN_TRACKER = Input.GetActionId("UI_OpenWorldCrisisTracker")
        RegisterWorldTrackerAction(ACTION_OPEN_TRACKER, ToggleCrisisList)
    end
end

local function OnWorldTrackerInputActionStarted(actionId)
    if ContextPtr:IsHidden() then return end
    local action = m_caiWorldTrackerActions[actionId]
    if action == nil then return end

    action()
end

RealizeCurrentResearch = WrapFunc(RealizeCurrentResearch, function(orig, playerID, kData, kControl)
    if kControl and kControl.IconButton then
        m_caiResearchTrackerControl = kControl
    end
    orig(playerID, kData, kControl)
end)

RealizeCurrentCivic = WrapFunc(RealizeCurrentCivic, function(orig, playerID, kData, kControl, cachedModifiers)
    if kControl and kControl.IconButton then
        m_caiCivicsTrackerControl = kControl
    end
    orig(playerID, kData, kControl, cachedModifiers)
end)

OnShutdown = WrapFunc(OnShutdown, function(orig)
    Events.InputActionStarted.Remove(OnWorldTrackerInputActionStarted)
    LuaEvents.CAIWorldTrackerShowChat.Remove(ForceShowChatPanel)
    RemoveCrisisList()
    orig()
end)
ContextPtr:SetShutdown(OnShutdown)

InitializeWorldTrackerActions()
Events.InputActionStarted.Add(OnWorldTrackerInputActionStarted)
LuaEvents.CAIWorldTrackerShowChat.Add(ForceShowChatPanel)
