include("caiUtils")
include("WorldTracker")

local ACTION_OPEN_RESEARCH_CHOOSER = Input.GetActionId("WorldTrackerOpenResearchChooser")
local ACTION_OPEN_CIVICS_CHOOSER = Input.GetActionId("WorldTrackerOpenCivicsChooser")
local ACTION_READ_SUMMARY = Input.GetActionId("WorldTrackerReadSummary")

local m_caiWorldTrackerActions = {}
local m_caiResearchTrackerControl = nil
local m_caiCivicsTrackerControl = nil

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

local function AppendIfText(lines, text)
    if text ~= nil and text ~= "" then
        table.insert(lines, text)
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

local function AppendResearchSummary(lines, playerID, player)
    local data = GetCurrentResearchData(playerID, player)
    if data == nil then
        AppendIfText(lines, Locale.Lookup("LOC_CAI_WORLDTRACKER_RESEARCH_LINE",
            Locale.Lookup("LOC_WORLD_TRACKER_CHOOSE_RESEARCH")))
        return
    end

    local parts = { data.Name }
    if data.TurnsLeft ~= nil and data.TurnsLeft >= 0 then
        table.insert(parts, Locale.Lookup("LOC_CAI_WORLDTRACKER_TURNS_REMAINING", data.TurnsLeft))
    end

    if data.Boostable then
        table.insert(parts, Locale.Lookup(data.BoostTriggered
            and "LOC_TECH_HAS_BEEN_BOOSTED"
            or "LOC_TECH_CAN_BE_BOOSTED"))
    end

    AppendIfText(lines, Locale.Lookup("LOC_CAI_WORLDTRACKER_RESEARCH_LINE", table.concat(parts, ", ")))
end

local function AppendCivicSummary(lines, playerID, player)
    local data = GetCurrentCivicData(playerID, player)
    if data == nil then
        AppendIfText(lines, Locale.Lookup("LOC_CAI_WORLDTRACKER_CIVIC_LINE",
            Locale.Lookup("LOC_WORLD_TRACKER_CHOOSE_CIVIC")))
        return
    end

    local parts = { data.Name }
    if data.TurnsLeft ~= nil and data.TurnsLeft >= 0 then
        table.insert(parts, Locale.Lookup("LOC_CAI_WORLDTRACKER_TURNS_REMAINING", data.TurnsLeft))
    end

    if data.Boostable then
        table.insert(parts, Locale.Lookup(data.BoostTriggered
            and "LOC_TECH_HAS_BEEN_BOOSTED"
            or "LOC_TECH_CAN_BE_BOOSTED"))
    end

    AppendIfText(lines, Locale.Lookup("LOC_CAI_WORLDTRACKER_CIVIC_LINE", table.concat(parts, ", ")))
end

local function AppendUnitCount(lines, player)
    local units = player:GetUnits()
    local count = 0
    if units ~= nil then
        count = units:GetCount()
    end
    AppendIfText(lines, Locale.Lookup("LOC_CAI_WORLDTRACKER_UNIT_COUNT", count))
end

local function SpeakWorldTrackerSummary()
    local playerID, player = GetLocalPlayer()
    if playerID == nil or player == nil then
        Speak(Locale.Lookup("LOC_CAI_WORLDTRACKER_SUMMARY_UNAVAILABLE"))
        return
    end

    local lines = {}
    AppendResearchSummary(lines, playerID, player)
    AppendCivicSummary(lines, playerID, player)
    AppendUnitCount(lines, player)

    Speak(table.concat(lines, "[NEWLINE]"))
end

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
        if not IsTrackerChooserControlEnabled(m_caiResearchTrackerControl) then return end
        LuaEvents.WorldTracker_OpenChooseResearch()
    end)
    RegisterWorldTrackerAction(ACTION_OPEN_CIVICS_CHOOSER, function()
        if not IsTrackerChooserControlEnabled(m_caiCivicsTrackerControl) then return end
        LuaEvents.WorldTracker_OpenChooseCivic()
    end)
    RegisterWorldTrackerAction(ACTION_READ_SUMMARY, SpeakWorldTrackerSummary)
end

local function OnWorldTrackerInputActionTriggered(actionId)
    if ContextPtr:IsHidden() then return end
    local action = m_caiWorldTrackerActions[actionId]
    if action == nil then return end

    action()
end

RealizeCurrentResearch = WrapFunc(RealizeCurrentResearch, function(orig, playerID, kData, kControl)
    if kControl and kControl.IconButton then
        m_caiResearchTrackerControl = kControl
    end
    return orig(playerID, kData, kControl)
end)

RealizeCurrentCivic = WrapFunc(RealizeCurrentCivic, function(orig, playerID, kData, kControl, cachedModifiers)
    if kControl and kControl.IconButton then
        m_caiCivicsTrackerControl = kControl
    end
    return orig(playerID, kData, kControl, cachedModifiers)
end)

OnShutdown = WrapFunc(OnShutdown, function(orig)
    Events.InputActionTriggered.Remove(OnWorldTrackerInputActionTriggered)
    orig()
end)
ContextPtr:SetShutdown(OnShutdown)

InitializeWorldTrackerActions()
Events.InputActionTriggered.Add(OnWorldTrackerInputActionTriggered)
