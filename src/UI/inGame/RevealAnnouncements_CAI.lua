include("caiUtils")
include("inGameHelpers_CAI")
include("PlayerStateManager_CAI")

RevealAnnouncements_CAI = RevealAnnouncements_CAI or {}

local ANNOUNCE_DELAY_SECONDS = 0.5

local EVENT_BINDINGS = {}
local m_isInitialized = false
local REVEAL_FLUSH_TURN_START = "turn_start"
local REVEAL_FLUSH_TURN_END = "turn_end"
local REVEAL_FLUSH_ACTIVE_TURN = "active_turn"
local REVEAL_FLUSH_BETWEEN_TURNS = "between_turns"

local m_PlayerState = PlayerStateManager.Init(function(playerID)
    return {
        lastEventTime = nil,

        firstRevealPlots = {},
        nowVisiblePlots = {},
        knownRevealedPlots = {},
        previousVisibleUnits = {},
        specialImprovementKinds = {},

        turnActive = false,
        initialized = false,
    }
end)

-- ===========================================================================
--  Player state helpers
-- ===========================================================================

local function GetActivePlayerID()
    local playerID = Game.GetLocalPlayer()
    if playerID == nil or playerID == -1 then
        return nil
    end

    return playerID
end

local function GetState(playerID)
    if playerID == nil or playerID == -1 then
        return nil
    end

    return m_PlayerState:Get(playerID)
end

local function GetActiveState()
    return GetState(GetActivePlayerID())
end

local function ResetBufferedPlots(state)
    if state == nil then
        return
    end

    state.firstRevealPlots = {}
    state.nowVisiblePlots = {}
end

local function TouchTimer(state)
    if state ~= nil then
        state.lastEventTime = Automation.GetTime()
    end
end

-- ===========================================================================
--  Local player and visibility
-- ===========================================================================

local function LogVisibilityError(message)
    LogWarn("Reveal announcements: " .. tostring(message))
end

local function CountKeys(map)
    local count = 0
    for _ in pairs(map or {}) do
        count = count + 1
    end

    return count
end

local function GetVisibilityForPlayer(playerID)
    if playerID ~= nil and playerID ~= -1 and PlayersVisibility[playerID] ~= nil then
        return PlayersVisibility[playerID]
    end

    local observerID = Game.GetLocalObserver()
    if observerID == nil or observerID == PlayerTypes.OBSERVER then
        return nil
    end

    return PlayersVisibility[observerID]
end

local function GetPlayer(playerID)
    if playerID == nil or playerID == -1 then
        return nil
    end

    return Players[playerID]
end

local function IsLocalPlayerTurnActive(playerID)
    local player = GetPlayer(playerID)
    return player ~= nil and player.IsTurnActive ~= nil and player:IsTurnActive()
end

local function GetTeamID(playerID)
    local player = GetPlayer(playerID)
    if player == nil then
        return -1
    end

    return player:GetTeam()
end

local function IsPlotCurrentlyVisible(playerID, plot)
    if plot == nil then
        return false
    end

    local visibility = GetVisibilityForPlayer(playerID)
    if visibility == nil then
        return true
    end

    return visibility:IsVisible(plot:GetIndex())
end

local function IsPlotCurrentlyRevealed(playerID, plot)
    if plot == nil then
        return false
    end

    local visibility = GetVisibilityForPlayer(playerID)
    if visibility == nil then
        return true
    end

    return visibility:IsRevealed(plot)
end

-- ===========================================================================
--  Owner classification
-- ===========================================================================

local function ClassifyForeignOwner(localPlayerID, playerID)
    if playerID == nil or playerID == -1 or localPlayerID == nil or localPlayerID == -1 then
        return nil
    end

    if playerID == localPlayerID then
        return nil
    end

    local player = Players[playerID]
    if player == nil or not player:IsAlive() then
        return nil
    end

    local localTeamID = GetTeamID(localPlayerID)
    local playerTeamID = player:GetTeam()
    if localTeamID ~= -1 and playerTeamID == localTeamID then
        return nil
    end

    if player:IsBarbarian() then
        return "enemy"
    end

    local localPlayer = GetPlayer(localPlayerID)
    local diplomacy = localPlayer ~= nil and localPlayer:GetDiplomacy() or nil
    if diplomacy == nil or not diplomacy:HasMet(playerID) then
        return nil
    end

    if diplomacy:IsAtWarWith(playerID) then
        return "enemy"
    end

    return "other"
end

-- ===========================================================================
--  Labels and aggregate sections
-- ===========================================================================

local function GetInfoRow(infoTable, index, infoLabel)
    if index == nil or index < 0 then
        return nil
    end

    local row = infoTable[index]
    if row == nil then
        LogVisibilityError("Missing " .. tostring(infoLabel) .. " row for index " .. tostring(index))
    end

    return row
end

local function AggregateLabels(labels)
    local counts = {}
    local order = {}

    for _, label in ipairs(labels or {}) do
        if label ~= nil and label ~= "" then
            if counts[label] == nil then
                counts[label] = 0
                order[#order + 1] = label
            end
            counts[label] = counts[label] + 1
        end
    end

    local parts = {}
    for _, label in ipairs(order) do
        local count = counts[label]
        parts[#parts + 1] = count > 1 and tostring(count) .. " " .. tostring(label) or tostring(label)
    end

    return parts
end

local function BuildLabeledSection(labelKey, labels)
    local parts = AggregateLabels(labels)
    if #parts == 0 then
        return nil
    end

    return Locale.Lookup(labelKey, table.concat(parts, ", "))
end

-- ===========================================================================
--  Plot payload collectors
-- ===========================================================================

local function GetImprovementTypeName(improvementType)
    local row = GetInfoRow(GameInfo.Improvements, improvementType, "improvement")
    return row ~= nil and row.ImprovementType or nil
end

local function IsTrackedGoneImprovementType(improvementTypeName)
    return improvementTypeName == "IMPROVEMENT_BARBARIAN_CAMP"
        or improvementTypeName == "IMPROVEMENT_GOODY_HUT"
end

local function IsSpecialImprovement(row)
    return row.BarbarianCamp or row.Goody
end

local function ShouldSpeakRevealFlush(reason)
    if reason == REVEAL_FLUSH_TURN_START then
        return CAISettings.GetBool("AnnounceVisibilityChangesTurnStart")
    end

    if reason == REVEAL_FLUSH_ACTIVE_TURN then
        return CAISettings.GetBool("AnnounceVisibilityChangesWhileMoving")
    end

    if reason == REVEAL_FLUSH_BETWEEN_TURNS then
        return not GameConfiguration.IsHotseat() and CAISettings.GetBool("AnnounceVisibilityChangesOutsideTurn")
    end

    if reason == REVEAL_FLUSH_TURN_END then
        return false
    end

    return true
end

local function ShouldSkipRevealPayload(plot)
    if plot == nil then
        return true
    end

    if plot:IsNaturalWonder() then
        return true
    end

    local improvementTypeName = GetImprovementTypeName(plot:GetImprovementType())
    return IsTrackedGoneImprovementType(improvementTypeName)
end

local function GetForeignCityLabel(localPlayerID, plot)
    local city = Cities.GetCityInPlot(plot:GetX(), plot:GetY())
    if city == nil or ClassifyForeignOwner(localPlayerID, city:GetOwner()) == nil then
        return nil
    end

    return Locale.Lookup(city:GetName())
end

local function GetVisibleResourceLabel(localPlayerID, plot)
    local resourceType = plot:GetResourceType()
    local row = GetInfoRow(GameInfo.Resources, resourceType, "resource")
    if row == nil then
        return nil
    end

    local localPlayer = GetPlayer(localPlayerID)
    local resources = localPlayer ~= nil and localPlayer:GetResources() or nil
    if resources ~= nil and not resources:IsResourceVisible(row.Hash) then
        return nil
    end

    return Locale.Lookup(row.Name)
end

local function GetForeignDistrictLabel(localPlayerID, plot)
    if plot:IsCity() or plot:IsInternalOnlyDistrict() then
        return nil
    end

    local districtType = plot:GetDistrictType()
    local row = GetInfoRow(GameInfo.Districts, districtType, "district")
    if row == nil or row.DistrictType == "DISTRICT_CITY_CENTER" then
        return nil
    end

    local district = CityManager.GetDistrictAt(plot:GetX(), plot:GetY())
    local ownerID = district ~= nil and district:GetOwner() or nil
    if ownerID == nil or ownerID == -1 then
        ownerID = plot:GetOwner()
    end

    if ClassifyForeignOwner(localPlayerID, ownerID) == nil then
        return nil
    end

    return Locale.Lookup(row.Name)
end

local function GetForeignImprovementLabel(localPlayerID, plot)
    local improvementType = plot:GetImprovementType()
    local row = GetInfoRow(GameInfo.Improvements, improvementType, "improvement")
    if row == nil or IsSpecialImprovement(row) then
        return nil
    end

    if ClassifyForeignOwner(localPlayerID, plot:GetImprovementOwner()) == nil then
        return nil
    end

    return Locale.Lookup(row.Name)
end

-- ===========================================================================
--  Snapshot builders
-- ===========================================================================

local function BuildVisibleForeignUnitSnapshot(localPlayerID)
    if localPlayerID == nil or localPlayerID == -1 then
        LogWarn("Reveal announcements could not build visible foreign unit snapshot because local player is invalid")
        return {}
    end

    local visibility = GetVisibilityForPlayer(localPlayerID)
    local current = {}

    for _, player in ipairs(PlayerManager.GetAlive()) do
        local playerID = player:GetID()
        local bucket = ClassifyForeignOwner(localPlayerID, playerID)
        local units = bucket ~= nil and player:GetUnits() or nil

        if units ~= nil then
            for _, unit in units:Members() do
                if visibility == nil or visibility:IsUnitVisible(unit) then
                    local plot = Map.GetPlot(unit:GetX(), unit:GetY())
                    if plot ~= nil and IsPlotCurrentlyVisible(localPlayerID, plot) then
                        current[tostring(playerID) .. ":" .. tostring(unit:GetID())] = {
                            PlayerID = playerID,
                            UnitID = unit:GetID(),
                            Bucket = bucket,
                            Label = FormatOwnedUnitDisplayName(unit),
                        }
                    end
                end
            end
        end
    end

    return current
end

local function BootstrapKnownRevealedPlots(localPlayerID, state)
    if state == nil then
        LogWarn("Reveal announcements BootstrapKnownRevealedPlots called without state for player " .. tostring(localPlayerID))
        return
    end

    state.knownRevealedPlots = {}

    local plotCount = Map.GetPlotCount()
    for plotIndex = 0, plotCount - 1 do
        local plot = Map.GetPlotByIndex(plotIndex)
        if plot ~= nil and IsPlotCurrentlyRevealed(localPlayerID, plot) then
            state.knownRevealedPlots[plotIndex] = true
        end
    end

    LogMessage("Reveal announcements bootstrapped revealed plots for player "
        .. tostring(localPlayerID) .. ", count=" .. tostring(CountKeys(state.knownRevealedPlots)))
end

local function BootstrapSpecialImprovementSnapshot(localPlayerID, state, visibleOnly)
    if state == nil then
        LogWarn("Reveal announcements BootstrapSpecialImprovementSnapshot called without state for player " .. tostring(localPlayerID))
        return
    end

    if not visibleOnly then
        state.specialImprovementKinds = {}
    end

    local plotCount = Map.GetPlotCount()
    for plotIndex = 0, plotCount - 1 do
        local plot = Map.GetPlotByIndex(plotIndex)
        local shouldRead = plot ~= nil
            and (
                (visibleOnly and IsPlotCurrentlyVisible(localPlayerID, plot))
                or (not visibleOnly and IsPlotCurrentlyRevealed(localPlayerID, plot))
            )

        if shouldRead then
            local improvementTypeName = GetImprovementTypeName(plot:GetImprovementType())
            state.specialImprovementKinds[plotIndex] =
                IsTrackedGoneImprovementType(improvementTypeName) and improvementTypeName or nil
        end
    end

    LogMessage("Reveal announcements bootstrapped special improvements for player "
        .. tostring(localPlayerID) .. ", visibleOnly=" .. tostring(visibleOnly)
        .. ", trackedPlots=" .. tostring(CountKeys(state.specialImprovementKinds)))
end

-- ===========================================================================
--  Event state recording
-- ===========================================================================

local function EnsurePlayerInitialized(playerID, state)
    if state == nil then
        LogWarn("Reveal announcements initialization skipped because state is missing for player " .. tostring(playerID))
        return
    end

    if state.initialized then
        LogMessage("Reveal announcements player " .. tostring(playerID) .. " already initialized")
        return
    end

    BootstrapKnownRevealedPlots(playerID, state)
    state.previousVisibleUnits = BuildVisibleForeignUnitSnapshot(playerID)
    BootstrapSpecialImprovementSnapshot(playerID, state, false)
    ResetBufferedPlots(state)
    state.lastEventTime = nil
    state.initialized = true
    LogMessage("Reveal announcements initialized player " .. tostring(playerID)
        .. " revealedPlots=" .. tostring(CountKeys(state.knownRevealedPlots))
        .. " visibleForeignUnits=" .. tostring(CountKeys(state.previousVisibleUnits))
        .. " trackedSpecialImprovements=" .. tostring(CountKeys(state.specialImprovementKinds)))
end

local function ClearState(state)
    if state == nil then
        return
    end

    ResetBufferedPlots(state)
    state.knownRevealedPlots = {}
    state.previousVisibleUnits = {}
    state.specialImprovementKinds = {}
    state.lastEventTime = nil

    state.initialized = false
end

local function RecordPlotState(localPlayerID, state, plot, shouldTrackVisible)
    if state == nil or plot == nil then
        return
    end

    local plotIndex = plot:GetIndex()
    if plotIndex == nil or plotIndex < 0 then
        return
    end

    if not state.knownRevealedPlots[plotIndex] and IsPlotCurrentlyRevealed(localPlayerID, plot) then
        state.knownRevealedPlots[plotIndex] = true
        state.firstRevealPlots[plotIndex] = true
    end

    if shouldTrackVisible and IsPlotCurrentlyVisible(localPlayerID, plot) then
        state.nowVisiblePlots[plotIndex] = true
    end
end

local function OnPlotVisibilityChanged(x, y, visibilityType)
    local localPlayerID = GetActivePlayerID()
    local state = GetState(localPlayerID)
    if state == nil then
        return
    end

    TouchTimer(state)

    if visibilityType == RevealedState.HIDDEN then
        return
    end

    RecordPlotState(localPlayerID, state, Map.GetPlot(x, y), true)
end

local function OnUnitVisibilityChanged()
    local state = GetActiveState()
    TouchTimer(state)
end

local function OnImprovementVisibilityChanged()
    local state = GetActiveState()
    TouchTimer(state)
end

local function OnResourceVisibilityChanged()
    local state = GetActiveState()
    TouchTimer(state)
end

local function OnCityVisibilityChanged()
    local state = GetActiveState()
    TouchTimer(state)
end

local function OnDistrictVisibilityChanged()
    local state = GetActiveState()
    TouchTimer(state)
end

local function AppendLabel(list, label)
    if label ~= nil and label ~= "" then
        list[#list + 1] = label
    end
end

local function CollectRevealPayload(localPlayerID, state)
    local enemyUnits, otherUnits = {}, {}
    local enemyHidden, otherHidden = {}, {}
    local cities, resources, districts, improvements = {}, {}, {}, {}
    local goneOutposts, goneVillages = 0, 0
    local revealedCount = 0

    for plotIndex in pairs(state.firstRevealPlots) do
        local plot = Map.GetPlotByIndex(plotIndex)
        if plot ~= nil then
            revealedCount = revealedCount + 1

            if not ShouldSkipRevealPayload(plot) then
                AppendLabel(cities, GetForeignCityLabel(localPlayerID, plot))
                AppendLabel(resources, GetVisibleResourceLabel(localPlayerID, plot))
                AppendLabel(districts, GetForeignDistrictLabel(localPlayerID, plot))
                AppendLabel(improvements, GetForeignImprovementLabel(localPlayerID, plot))
            end
        end
    end

    local currentVisibleUnits = BuildVisibleForeignUnitSnapshot(localPlayerID)

    for key, current in pairs(currentVisibleUnits) do
        if state.previousVisibleUnits[key] == nil and current.Label ~= nil and current.Label ~= "" then
            if current.Bucket == "enemy" then
                enemyUnits[#enemyUnits + 1] = current.Label
            else
                otherUnits[#otherUnits + 1] = current.Label
            end
        end
    end

    for key, previous in pairs(state.previousVisibleUnits) do
        if currentVisibleUnits[key] == nil and previous.Label ~= nil and previous.Label ~= "" then
            local owner = Players[previous.PlayerID]
            local units = owner ~= nil and owner:GetUnits() or nil
            local unitStillExists = units ~= nil and units:FindID(previous.UnitID) ~= nil

            if unitStillExists then
                if previous.Bucket == "enemy" then
                    enemyHidden[#enemyHidden + 1] = previous.Label
                else
                    otherHidden[#otherHidden + 1] = previous.Label
                end
            end
        end
    end

    state.previousVisibleUnits = currentVisibleUnits

    for plotIndex in pairs(state.nowVisiblePlots) do
        local plot = Map.GetPlotByIndex(plotIndex)

        if plot ~= nil and IsPlotCurrentlyVisible(localPlayerID, plot) then
            local nowImprovementTypeName = GetImprovementTypeName(plot:GetImprovementType())
            if not IsTrackedGoneImprovementType(nowImprovementTypeName) then
                nowImprovementTypeName = nil
            end

            local previousImprovementTypeName = state.specialImprovementKinds[plotIndex]
            if not state.firstRevealPlots[plotIndex]
                and previousImprovementTypeName ~= nil
                and previousImprovementTypeName ~= nowImprovementTypeName then
                if previousImprovementTypeName == "IMPROVEMENT_BARBARIAN_CAMP" then
                    goneOutposts = goneOutposts + 1
                elseif previousImprovementTypeName == "IMPROVEMENT_GOODY_HUT" then
                    goneVillages = goneVillages + 1
                end
            end

            state.specialImprovementKinds[plotIndex] = nowImprovementTypeName
        end
    end

    local revealSections = {}
    AppendLabel(revealSections, BuildLabeledSection("LOC_CAI_REVEAL_ENEMY", enemyUnits))
    AppendLabel(revealSections, BuildLabeledSection("LOC_CAI_REVEAL_UNITS", otherUnits))
    AppendLabel(revealSections, BuildLabeledSection("LOC_CAI_REVEAL_CITIES", cities))
    AppendLabel(revealSections, BuildLabeledSection("LOC_CAI_REVEAL_RESOURCES", resources))
    AppendLabel(revealSections, BuildLabeledSection("LOC_CAI_REVEAL_DISTRICTS", districts))
    AppendLabel(revealSections, BuildLabeledSection("LOC_CAI_REVEAL_IMPROVEMENTS", improvements))

    local hiddenSections = {}
    AppendLabel(hiddenSections, BuildLabeledSection("LOC_CAI_REVEAL_ENEMY", enemyHidden))
    AppendLabel(hiddenSections, BuildLabeledSection("LOC_CAI_REVEAL_UNITS", otherHidden))

    local goneSections = {}
    if goneOutposts > 0 then
        AppendLabel(goneSections, Locale.Lookup("LOC_CAI_GONE_OUTPOST_PART", goneOutposts))
    end
    if goneVillages > 0 then
        AppendLabel(goneSections, Locale.Lookup("LOC_CAI_GONE_TRIBAL_VILLAGE_PART", goneVillages))
    end

    return {
        RevealedCount = revealedCount,
        RevealSections = revealSections,
        HiddenSections = hiddenSections,
        GoneSections = goneSections,
    }
end

local function BuildRevealLine(payload)
    if payload == nil then
        return nil
    end

    local revealSections = payload.RevealSections or {}
    if payload.RevealedCount > 0 then
        local header = Locale.Lookup("LOC_CAI_REVEAL_COUNT", payload.RevealedCount)
        return #revealSections > 0 and header .. ": " .. table.concat(revealSections, ", ") or header
    end

    if #revealSections > 0 then
        return Locale.Lookup("LOC_CAI_REVEAL_HEADER") .. ": " .. table.concat(revealSections, ", ")
    end

    return nil
end

local function BuildHiddenLine(payload)
    if payload == nil or payload.HiddenSections == nil or #payload.HiddenSections == 0 then
        return nil
    end

    return Locale.Lookup("LOC_CAI_HIDDEN_HEADER") .. ": " .. table.concat(payload.HiddenSections, ", ")
end

local function BuildGoneLine(payload)
    if payload == nil or payload.GoneSections == nil or #payload.GoneSections == 0 then
        return nil
    end

    return Locale.Lookup("LOC_CAI_GONE_HEADER")
        .. ": "
        .. table.concat(payload.GoneSections, Locale.Lookup("LOC_CAI_GONE_AND"))
end

local function FlushAnnouncementsForPlayer(localPlayerID, reason)
    local state = GetState(localPlayerID)
    if state == nil then
        LogWarn("Reveal announcements flush skipped because state is missing for player "
            .. tostring(localPlayerID) .. ", reason=" .. tostring(reason))
        return
    end

    local shouldSpeak = ShouldSpeakRevealFlush(reason)

    -- Between-turn announcements are the only case that can defer.
    -- If outside-turn speech is off, keep the queue for turn-start.
    if reason == REVEAL_FLUSH_BETWEEN_TURNS and not shouldSpeak then
        LogMessage("Reveal announcements deferred between-turn flush for player " .. tostring(localPlayerID))
        return
    end

    -- All other flushes consume the queue, even when speech is disabled.
    -- This is what prevents active-turn movement reveals from leaking into
    -- the next turn-start announcement.
    local payload = CollectRevealPayload(localPlayerID, state)

    ResetBufferedPlots(state)
    state.lastEventTime = nil

    LogMessage("Reveal announcements flushed player " .. tostring(localPlayerID)
        .. " reason=" .. tostring(reason)
        .. " speak=" .. tostring(shouldSpeak)
        .. " revealed=" .. tostring(payload ~= nil and payload.RevealedCount or 0)
        .. " revealSections=" .. tostring(payload ~= nil and #(payload.RevealSections or {}) or 0)
        .. " hiddenSections=" .. tostring(payload ~= nil and #(payload.HiddenSections or {}) or 0)
        .. " goneSections=" .. tostring(payload ~= nil and #(payload.GoneSections or {}) or 0))

    if not shouldSpeak then
        return
    end

    local lines = {}
    AppendLabel(lines, BuildRevealLine(payload))
    AppendLabel(lines, BuildHiddenLine(payload))
    AppendLabel(lines, BuildGoneLine(payload))

    for _, line in ipairs(lines) do
        LuaEvents.CAIAppendToMessageBuffer(line, "reveal")
    end
end

local function ResyncTurnStartSnapshots()
    local playerID = GetActivePlayerID()
    local state = GetState(playerID)
    if state == nil then
        LogWarn("Reveal announcements turn-start resync skipped because active state is missing")
        return
    end

    if not state.initialized then
        EnsurePlayerInitialized(playerID, state)
        return
    end

    LogMessage("Reveal announcements turn-start resync for player " .. tostring(playerID))

    -- Always flush/clear at turn start.
    FlushAnnouncementsForPlayer(playerID, REVEAL_FLUSH_TURN_START)
end

local function OnLocalPlayerTurnEnd()
    local playerID = GetActivePlayerID()
    local state = GetState(playerID)
    if state == nil then
        LogWarn("Reveal announcements turn-end flush skipped because active state is missing")
        return
    end
    LogMessage("Reveal announcements turn-end flush for player " .. tostring(playerID))
    FlushAnnouncementsForPlayer(playerID, REVEAL_FLUSH_TURN_END)
end

EVENT_BINDINGS = {
    { Event = Events.PlotVisibilityChanged,        Handler = OnPlotVisibilityChanged },
    { Event = Events.UnitVisibilityChanged,        Handler = OnUnitVisibilityChanged },
    { Event = Events.ImprovementVisibilityChanged, Handler = OnImprovementVisibilityChanged },
    { Event = Events.ResourceVisibilityChanged,    Handler = OnResourceVisibilityChanged },
    { Event = Events.CityVisibilityChanged,        Handler = OnCityVisibilityChanged },
    { Event = Events.DistrictVisibilityChanged,    Handler = OnDistrictVisibilityChanged },
    { Event = Events.LocalPlayerTurnBegin,         Handler = ResyncTurnStartSnapshots },
    { Event = Events.LocalPlayerTurnEnd,           Handler = OnLocalPlayerTurnEnd },
}

-- ===========================================================================
--  Public API
-- ===========================================================================

function RevealAnnouncements_CAI.Initialize()
    if m_isInitialized then
        return
    end

    for _, binding in ipairs(EVENT_BINDINGS) do
        binding.Event.Add(binding.Handler)
    end

    m_isInitialized = true

    local playerID = GetActivePlayerID()
    local state = GetState(playerID)
    EnsurePlayerInitialized(playerID, state)
    LogMessage("Reveal announcements initialized for active player " .. tostring(playerID))
end

function RevealAnnouncements_CAI.Clear()
    local playerID = GetActivePlayerID()
    LogMessage("Reveal announcements cleared active player state for player " .. tostring(playerID))
    ClearState(GetActiveState())
end

function RevealAnnouncements_CAI.ClearPlayer(playerID)
    local state = GetState(playerID)
    if state == nil then
        LogWarn("Reveal announcements ClearPlayer skipped because state is missing for player " .. tostring(playerID))
        return
    end

    ResetBufferedPlots(state)
    state.knownRevealedPlots = {}
    state.previousVisibleUnits = {}
    state.specialImprovementKinds = {}
    state.lastEventTime = nil
    state.initialized = false
    LogMessage("Reveal announcements cleared player state for player " .. tostring(playerID))
end

function RevealAnnouncements_CAI.ClearAll()
    LogMessage("Reveal announcements cleared all player state")
    m_PlayerState:ClearAll()
end

function RevealAnnouncements_CAI.Shutdown()
    if not m_isInitialized then
        RevealAnnouncements_CAI.Clear()
        return
    end

    for _, binding in ipairs(EVENT_BINDINGS) do
        binding.Event.Remove(binding.Handler)
    end

    RevealAnnouncements_CAI.ClearAll()
    m_isInitialized = false
    LogMessage("Reveal announcements shut down")
end

function RevealAnnouncements_CAI.UpdateVisibility()
    if not m_isInitialized then
        return
    end

    local localPlayerID = GetActivePlayerID()
    local state = GetState(localPlayerID)

    if state == nil or state.lastEventTime == nil then
        return
    end

    local now = Automation.GetTime()
    if (now - state.lastEventTime) > ANNOUNCE_DELAY_SECONDS then
        LogMessage("Reveal announcements debounce elapsed for player "
            .. tostring(localPlayerID) .. ", turnActive=" .. tostring(IsLocalPlayerTurnActive(localPlayerID)))
        if IsLocalPlayerTurnActive(localPlayerID) then
            FlushAnnouncementsForPlayer(localPlayerID, REVEAL_FLUSH_ACTIVE_TURN)
        else
            FlushAnnouncementsForPlayer(localPlayerID, REVEAL_FLUSH_BETWEEN_TURNS)
        end
    end
end

function RevealAnnouncements_CAI.GetActiveState()
    return GetActiveState()
end

function RevealAnnouncements_CAI.GetStateForPlayer(playerID)
    return GetState(playerID)
end
