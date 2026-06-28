include("caiUtils")
include("inGameHelpers_CAI")

RevealAnnouncements_CAI = RevealAnnouncements_CAI or {}

local ANNOUNCE_DELAY_SECONDS = 0.5

local EVENT_BINDINGS = {}
local m_isInitialized = false
local m_lastEventTime = nil
local m_firstRevealPlots = {}
local m_nowVisiblePlots = {}
local m_knownRevealedPlots = {}
local m_previousVisibleUnits = {}
local m_specialImprovementKinds = {}

-- ===========================================================================
--  Local player and visibility
-- ===========================================================================

local function LogVisibilityError(message)
    print("RevealAnnouncements_CAI: " .. tostring(message))
end

local function GetObserverVisibility()
    local observerID = Game.GetLocalObserver()
    if observerID == nil or observerID == PlayerTypes.OBSERVER then
        return nil
    end

    return PlayersVisibility[observerID]
end

local function GetLocalPlayer()
    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == nil or localPlayerID == -1 then
        return nil
    end

    return Players[localPlayerID]
end

local function GetLocalTeamID()
    local localPlayer = GetLocalPlayer()
    if localPlayer == nil then
        return -1
    end

    return localPlayer:GetTeam()
end

local function IsPlotCurrentlyVisible(plot)
    if plot == nil then
        return false
    end

    local visibility = GetObserverVisibility()
    if visibility == nil then
        return true
    end

    return visibility:IsVisible(plot:GetIndex())
end

local function IsPlotCurrentlyRevealed(plot)
    if plot == nil then
        return false
    end

    local visibility = GetObserverVisibility()
    if visibility == nil then
        return true
    end

    return visibility:IsRevealed(plot)
end

local function TouchTimer()
    m_lastEventTime = Automation.GetTime()
end

local function ResetBufferedPlots()
    m_firstRevealPlots = {}
    m_nowVisiblePlots = {}
end

-- ===========================================================================
--  Owner classification
-- ===========================================================================

local function ClassifyForeignOwner(playerID)
    local localPlayerID = Game.GetLocalPlayer()
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

    local localTeamID = GetLocalTeamID()
    local playerTeamID = player:GetTeam()
    if localTeamID ~= -1 and playerTeamID == localTeamID then
        return nil
    end

    if player:IsBarbarian() then
        return "enemy"
    end

    local localPlayer = GetLocalPlayer()
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

local function AppendLabel(list, label)
    if label ~= nil and label ~= "" then
        list[#list + 1] = label
    end
end

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

local function GetForeignCityLabel(plot)
    local city = Cities.GetCityInPlot(plot:GetX(), plot:GetY())
    if city == nil or ClassifyForeignOwner(city:GetOwner()) == nil then
        return nil
    end

    return Locale.Lookup(city:GetName())
end

local function GetVisibleResourceLabel(plot)
    local resourceType = plot:GetResourceType()
    local row = GetInfoRow(GameInfo.Resources, resourceType, "resource")
    if row == nil then
        return nil
    end

    local localPlayer = GetLocalPlayer()
    local resources = localPlayer ~= nil and localPlayer:GetResources() or nil
    if resources ~= nil and not resources:IsResourceVisible(row.Hash) then
        return nil
    end

    return Locale.Lookup(row.Name)
end

local function GetForeignDistrictLabel(plot)
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

    if ClassifyForeignOwner(ownerID) == nil then
        return nil
    end

    return Locale.Lookup(row.Name)
end

local function GetForeignImprovementLabel(plot)
    local improvementType = plot:GetImprovementType()
    local row = GetInfoRow(GameInfo.Improvements, improvementType, "improvement")
    if row == nil or IsSpecialImprovement(row) then
        return nil
    end

    if ClassifyForeignOwner(plot:GetImprovementOwner()) == nil then
        return nil
    end

    return Locale.Lookup(row.Name)
end

-- ===========================================================================
--  Snapshot builders
-- ===========================================================================

local function BuildVisibleForeignUnitSnapshot()
    local visibility = GetObserverVisibility()
    local current = {}

    for _, player in ipairs(PlayerManager.GetAlive()) do
        local playerID = player:GetID()
        local bucket = ClassifyForeignOwner(playerID)
        local units = bucket ~= nil and player:GetUnits() or nil
        if units ~= nil then
            for _, unit in units:Members() do
                if visibility == nil or visibility:IsUnitVisible(unit) then
                    local plot = Map.GetPlot(unit:GetX(), unit:GetY())
                    if plot ~= nil and IsPlotCurrentlyVisible(plot) then
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

local function BootstrapKnownRevealedPlots()
    m_knownRevealedPlots = {}

    local plotCount = Map.GetPlotCount()
    for plotIndex = 0, plotCount - 1 do
        local plot = Map.GetPlotByIndex(plotIndex)
        if plot ~= nil and IsPlotCurrentlyRevealed(plot) then
            m_knownRevealedPlots[plotIndex] = true
        end
    end
end

local function BootstrapSpecialImprovementSnapshot(visibleOnly)
    m_specialImprovementKinds = visibleOnly and m_specialImprovementKinds or {}

    local plotCount = Map.GetPlotCount()
    for plotIndex = 0, plotCount - 1 do
        local plot = Map.GetPlotByIndex(plotIndex)
        local shouldRead = plot ~= nil
            and ((visibleOnly and IsPlotCurrentlyVisible(plot)) or (not visibleOnly and IsPlotCurrentlyRevealed(plot)))

        if shouldRead then
            local improvementTypeName = GetImprovementTypeName(plot:GetImprovementType())
            m_specialImprovementKinds[plotIndex] =
                IsTrackedGoneImprovementType(improvementTypeName) and improvementTypeName or nil
        end
    end
end

-- ===========================================================================
--  Event state recording
-- ===========================================================================

local function RecordPlotState(plot, shouldTrackVisible)
    if plot == nil then
        return
    end

    local plotIndex = plot:GetIndex()
    if plotIndex == nil or plotIndex < 0 then
        return
    end

    if not m_knownRevealedPlots[plotIndex] and IsPlotCurrentlyRevealed(plot) then
        m_knownRevealedPlots[plotIndex] = true
        m_firstRevealPlots[plotIndex] = true
    end

    if shouldTrackVisible and IsPlotCurrentlyVisible(plot) then
        m_nowVisiblePlots[plotIndex] = true
    end
end

local function OnPlotVisibilityChanged(x, y, visibilityType)
    TouchTimer()

    if visibilityType == RevealedState.HIDDEN then
        return
    end

    RecordPlotState(Map.GetPlot(x, y), true)
end

local function OnUnitVisibilityChanged()
    TouchTimer()
end

local function OnImprovementVisibilityChanged()
    TouchTimer()
end

local function OnResourceVisibilityChanged()
    TouchTimer()
end

local function OnCityVisibilityChanged()
    TouchTimer()
end

local function OnDistrictVisibilityChanged()
    TouchTimer()
end

local function ResyncTurnStartSnapshots()
    local ok, err = pcall(function()
        BootstrapKnownRevealedPlots()
        m_previousVisibleUnits = BuildVisibleForeignUnitSnapshot()
        BootstrapSpecialImprovementSnapshot(true)
        ResetBufferedPlots()
        m_lastEventTime = nil
    end)
    if not ok then
        LogVisibilityError("Turn-start snapshot reset failed: " .. tostring(err))
    end
end

EVENT_BINDINGS = {
    { Event = Events.PlotVisibilityChanged,        Handler = OnPlotVisibilityChanged },
    { Event = Events.UnitVisibilityChanged,        Handler = OnUnitVisibilityChanged },
    { Event = Events.ImprovementVisibilityChanged, Handler = OnImprovementVisibilityChanged },
    { Event = Events.ResourceVisibilityChanged,    Handler = OnResourceVisibilityChanged },
    { Event = Events.CityVisibilityChanged,        Handler = OnCityVisibilityChanged },
    { Event = Events.DistrictVisibilityChanged,    Handler = OnDistrictVisibilityChanged },
    { Event = Events.LocalPlayerTurnBegin,         Handler = ResyncTurnStartSnapshots },
}

-- ===========================================================================
--  Flush and speech
-- ===========================================================================

local function CollectRevealPayload()
    local enemyUnits, otherUnits = {}, {}
    local enemyHidden, otherHidden = {}, {}
    local cities, resources, districts, improvements = {}, {}, {}, {}
    local goneOutposts, goneVillages = 0, 0
    local revealedCount = 0

    for plotIndex in pairs(m_firstRevealPlots) do
        local plot = Map.GetPlotByIndex(plotIndex)
        if plot ~= nil then
            revealedCount = revealedCount + 1

            if not ShouldSkipRevealPayload(plot) then
                AppendLabel(cities, GetForeignCityLabel(plot))
                AppendLabel(resources, GetVisibleResourceLabel(plot))
                AppendLabel(districts, GetForeignDistrictLabel(plot))
                AppendLabel(improvements, GetForeignImprovementLabel(plot))
            end
        end
    end

    local currentVisibleUnits = BuildVisibleForeignUnitSnapshot()
    for key, current in pairs(currentVisibleUnits) do
        if m_previousVisibleUnits[key] == nil and current.Label ~= nil and current.Label ~= "" then
            if current.Bucket == "enemy" then
                enemyUnits[#enemyUnits + 1] = current.Label
            else
                otherUnits[#otherUnits + 1] = current.Label
            end
        end
    end

    for key, previous in pairs(m_previousVisibleUnits) do
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
    m_previousVisibleUnits = currentVisibleUnits

    for plotIndex in pairs(m_nowVisiblePlots) do
        local plot = Map.GetPlotByIndex(plotIndex)
        if plot ~= nil and IsPlotCurrentlyVisible(plot) then
            local nowImprovementTypeName = GetImprovementTypeName(plot:GetImprovementType())
            if not IsTrackedGoneImprovementType(nowImprovementTypeName) then
                nowImprovementTypeName = nil
            end

            local previousImprovementTypeName = m_specialImprovementKinds[plotIndex]
            if not m_firstRevealPlots[plotIndex]
                and previousImprovementTypeName ~= nil
                and previousImprovementTypeName ~= nowImprovementTypeName then
                if previousImprovementTypeName == "IMPROVEMENT_BARBARIAN_CAMP" then
                    goneOutposts = goneOutposts + 1
                elseif previousImprovementTypeName == "IMPROVEMENT_GOODY_HUT" then
                    goneVillages = goneVillages + 1
                end
            end

            m_specialImprovementKinds[plotIndex] = nowImprovementTypeName
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

local function FlushAnnouncements()
    local payload = CollectRevealPayload()
    local lines = {}

    AppendLabel(lines, BuildRevealLine(payload))
    AppendLabel(lines, BuildHiddenLine(payload))
    AppendLabel(lines, BuildGoneLine(payload))

    ResetBufferedPlots()
    m_lastEventTime = nil

    for _, line in ipairs(lines) do
        LuaEvents.CAIAppendToMessageBuffer(line, "reveal")
    end
end

-- ===========================================================================
--  Public API
-- ===========================================================================

function RevealAnnouncements_CAI.Initialize()
    if m_isInitialized then
        return
    end

    BootstrapKnownRevealedPlots()
    m_previousVisibleUnits = BuildVisibleForeignUnitSnapshot()
    BootstrapSpecialImprovementSnapshot(false)
    ResetBufferedPlots()
    m_lastEventTime = nil

    for _, binding in ipairs(EVENT_BINDINGS) do
        binding.Event.Add(binding.Handler)
    end

    m_isInitialized = true
end

function RevealAnnouncements_CAI.Clear()
    ResetBufferedPlots()
    m_knownRevealedPlots = {}
    m_previousVisibleUnits = {}
    m_specialImprovementKinds = {}
    m_lastEventTime = nil
end

function RevealAnnouncements_CAI.Shutdown()
    if not m_isInitialized then
        RevealAnnouncements_CAI.Clear()
        return
    end

    for _, binding in ipairs(EVENT_BINDINGS) do
        binding.Event.Remove(binding.Handler)
    end

    RevealAnnouncements_CAI.Clear()
    m_isInitialized = false
end

function RevealAnnouncements_CAI.UpdateVisibility()
    if not m_isInitialized or m_lastEventTime == nil then
        return
    end

    local now = Automation.GetTime()
    if (now - m_lastEventTime) > ANNOUNCE_DELAY_SECONDS then
        FlushAnnouncements()
    end
end
