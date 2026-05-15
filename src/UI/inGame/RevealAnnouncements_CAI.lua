include("caiUtils")
include("inGameHelpers_CAI")

RevealAnnouncements_CAI = RevealAnnouncements_CAI or {}

local ANNOUNCE_DELAY_SECONDS = 0.5

local CATEGORY_ORDER = {
    "plot",
    "unit",
    "resource",
    "city",
    "district",
    "improvement",
}

local QUEUE_REVEAL = "reveal"
local QUEUE_HIDDEN = "hidden"
local QUEUE_GONE = "gone"

local EVENT_HIDDEN_ALLOWED = {
    resource = true,
}

local SPECIAL_IMPROVEMENT_KIND_BARBARIAN_OUTPOST = "barbarianOutpost"
local SPECIAL_IMPROVEMENT_KIND_TRIBAL_VILLAGE = "tribalVillage"

local EVENT_BINDINGS = {}
local m_isInitialized = false
local m_lastEventTime = nil
local m_queues = {}
local m_previousVisibleUnits = {}
local m_specialImprovementKinds = {}
local m_recentlyVisiblePlots = {}

local function LogVisibilityError(message)
    print("RevealAnnouncements_CAI: " .. tostring(message))
end

local function CreateQueue()
    local queue = {}
    for _, categoryName in ipairs(CATEGORY_ORDER) do
        queue[categoryName] = {}
    end
    return queue
end

local function EnsureQueues()
    m_queues[QUEUE_REVEAL] = m_queues[QUEUE_REVEAL] or CreateQueue()
    m_queues[QUEUE_HIDDEN] = m_queues[QUEUE_HIDDEN] or CreateQueue()
    m_queues[QUEUE_GONE] = m_queues[QUEUE_GONE] or CreateQueue()
end

local function GetQueue(queueName)
    EnsureQueues()
    return m_queues[queueName]
end

local function ClearQueue(queue)
    for _, categoryName in ipairs(CATEGORY_ORDER) do
        queue[categoryName] = {}
    end
end

local function TouchTimer()
    m_lastEventTime = Automation.GetTime()
end

local function PushQueueLabel(queueName, categoryName, label)
    if queueName == nil or categoryName == nil or label == nil or label == "" then
        return
    end

    table.insert(GetQueue(queueName)[categoryName], label)
end

local function Enqueue(queueName, categoryName, label)
    PushQueueLabel(queueName, categoryName, label)
    TouchTimer()
end

local function LookupInfoRow(infoTable, index, infoLabel)
    if index == nil or index < 0 then
        return nil
    end

    local row = infoTable[index]
    if row == nil then
        LogVisibilityError("Missing " .. tostring(infoLabel) .. " row for index " .. tostring(index))
        return nil
    end

    return row
end

local function LookupInfoName(infoTable, index, infoLabel)
    local row = LookupInfoRow(infoTable, index, infoLabel)
    if row == nil then
        return nil
    end

    if row.Name == nil or row.Name == "" then
        LogVisibilityError("Missing " .. tostring(infoLabel) .. " name for index " .. tostring(index))
        return nil
    end

    return Locale.Lookup(row.Name)
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
    return localPlayer and localPlayer.GetTeam and localPlayer:GetTeam() or -1
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

local function MarkPlotVisibleByCoords(x, y)
    if x == nil or y == nil then
        return
    end

    local plotIndex = Map.GetPlotIndex(x, y)
    if plotIndex == nil or plotIndex < 0 then
        return
    end

    m_recentlyVisiblePlots[plotIndex] = true
end

local function CanAnnounceForeignPlayer(playerID)
    local localPlayerID = Game.GetLocalPlayer()
    if playerID == nil or playerID == -1 or localPlayerID == nil or localPlayerID == -1 then
        return false
    end

    if playerID == localPlayerID then
        return false
    end

    local player = Players[playerID]
    if player == nil or not player:IsAlive() then
        return false
    end

    if player:IsBarbarian() then
        return true
    end

    local localTeamID = GetLocalTeamID()
    local playerTeamID = player.GetTeam and player:GetTeam() or -1
    if localTeamID ~= -1 and playerTeamID == localTeamID then
        return false
    end

    local localPlayer = GetLocalPlayer()
    local diplomacy = localPlayer and localPlayer.GetDiplomacy and localPlayer:GetDiplomacy() or nil
    return diplomacy ~= nil and diplomacy:HasMet(playerID)
end

local function GetCityName(playerID, cityID)
    local player = playerID ~= nil and Players[playerID] or nil
    if player == nil then
        LogVisibilityError("Missing player for city visibility event: " .. tostring(playerID))
        return nil
    end

    local city = player:GetCities():FindID(cityID)
    if city == nil then
        LogVisibilityError("Missing city for visibility event: " .. tostring(playerID) .. ":" .. tostring(cityID))
        return nil
    end

    return Locale.Lookup(city:GetName())
end

local function GetDistrictName(playerID, districtID)
    local player = playerID ~= nil and Players[playerID] or nil
    if player == nil then
        LogVisibilityError("Missing player for district visibility event: " .. tostring(playerID))
        return nil
    end

    local district = player:GetDistricts():FindID(districtID)
    if district == nil then
        LogVisibilityError("Missing district for visibility event: " .. tostring(playerID) .. ":" .. tostring(districtID))
        return nil
    end

    return LookupInfoName(GameInfo.Districts, district:GetType(), "district")
end

local function GetSpecialImprovementKind(improvementType)
    local row = LookupInfoRow(GameInfo.Improvements, improvementType, "improvement")
    if row == nil then
        return nil
    end

    if row.BarbarianCamp == true or row.BarbarianCamp == 1 or row.ImprovementType == "IMPROVEMENT_BARBARIAN_CAMP" then
        return SPECIAL_IMPROVEMENT_KIND_BARBARIAN_OUTPOST
    end

    if row.Goody == true or row.Goody == 1 or row.ImprovementType == "IMPROVEMENT_GOODY_HUT" then
        return SPECIAL_IMPROVEMENT_KIND_TRIBAL_VILLAGE
    end

    return nil
end

local function GetSpecialImprovementLabel(kind)
    if kind == SPECIAL_IMPROVEMENT_KIND_BARBARIAN_OUTPOST then
        return Locale.Lookup("LOC_IMPROVEMENT_BARBARIAN_CAMP_NAME")
    end
    if kind == SPECIAL_IMPROVEMENT_KIND_TRIBAL_VILLAGE then
        return Locale.Lookup("LOC_IMPROVEMENT_GOODY_HUT_NAME")
    end

    return nil
end

local function QueueEventDrivenVisibility(categoryName, label, visibilityType)
    if label == nil or label == "" then
        return
    end

    if visibilityType == RevealedState.VISIBLE then
        Enqueue(QUEUE_REVEAL, categoryName, label)
        return
    end

    if visibilityType == RevealedState.HIDDEN and EVENT_HIDDEN_ALLOWED[categoryName] then
        Enqueue(QUEUE_HIDDEN, categoryName, label)
    end
end

local function BuildVisibleForeignUnitSnapshot()
    local visibility = GetObserverVisibility()
    local current = {}
    local scanPlayers = {}
    local seenPlayers = {}

    local function AddScanPlayer(player)
        if player == nil or not player:IsAlive() then
            return
        end

        local playerID = player:GetID()
        if playerID == nil or seenPlayers[playerID] then
            return
        end

        seenPlayers[playerID] = true
        scanPlayers[#scanPlayers + 1] = player
    end

    for _, player in ipairs(PlayerManager.GetAlive() or {}) do
        AddScanPlayer(player)
    end

    for _, player in ipairs(Players) do
        if player ~= nil and player:IsBarbarian() then
            AddScanPlayer(player)
        end
    end

    for _, player in ipairs(scanPlayers) do
        local playerID = player:GetID()
        if CanAnnounceForeignPlayer(playerID) then
            local units = player:GetUnits()
            if units ~= nil then
                for _, unit in units:Members() do
                    if unit ~= nil and (visibility == nil or visibility:IsUnitVisible(unit)) then
                        local plotIndex = unit:GetPlotId()
                        local plot = plotIndex ~= nil and plotIndex >= 0 and Map.GetPlotByIndex(plotIndex) or nil
                        if plot ~= nil and IsPlotCurrentlyVisible(plot) then
                            current[tostring(playerID) .. ":" .. tostring(unit:GetID())] = {
                                Label = FormatOwnedUnitDisplayName(unit),
                            }
                        end
                    end
                end
            end
        end
    end

    return current
end

local function BootstrapVisibleUnitSnapshot()
    m_previousVisibleUnits = BuildVisibleForeignUnitSnapshot()
end

local function BootstrapSpecialImprovementSnapshot()
    m_specialImprovementKinds = {}

    local plotCount = Map.GetPlotCount and Map.GetPlotCount() or 0
    for plotIndex = 0, plotCount - 1 do
        local plot = Map.GetPlotByIndex(plotIndex)
        if plot ~= nil and IsPlotCurrentlyVisible(plot) then
            m_specialImprovementKinds[plotIndex] = GetSpecialImprovementKind(plot:GetImprovementType())
        end
    end
end

local function BuildCategoryText(categoryName, labels)
    if labels == nil or #labels == 0 then
        return nil
    end

    if categoryName == "plot" then
        return Locale.Lookup("LOC_CAI_REVEAL_TILES", #labels)
    end

    local counts = {}
    local order = {}
    for _, label in ipairs(labels) do
        if counts[label] == nil then
            counts[label] = 0
            table.insert(order, label)
        end
        counts[label] = counts[label] + 1
    end

    local parts = {}
    for _, label in ipairs(order) do
        if counts[label] > 1 then
            table.insert(parts, tostring(counts[label]) .. " " .. tostring(label))
        else
            table.insert(parts, tostring(label))
        end
    end

    return table.concat(parts, ", ")
end

local function BuildQueueText(queueName)
    local queue = GetQueue(queueName)
    local parts = {}
    for _, categoryName in ipairs(CATEGORY_ORDER) do
        local text = BuildCategoryText(categoryName, queue[categoryName])
        if text ~= nil and text ~= "" then
            table.insert(parts, text)
        end
    end

    if #parts == 0 then
        return nil
    end

    return table.concat(parts, ", ")
end

local function ApplyUnitSnapshotDiff()
    local currentVisibleUnits = BuildVisibleForeignUnitSnapshot()

    for key, current in pairs(currentVisibleUnits) do
        if m_previousVisibleUnits[key] == nil and current.Label ~= nil and current.Label ~= "" then
            PushQueueLabel(QUEUE_REVEAL, "unit", current.Label)
        end
    end

    for key, previous in pairs(m_previousVisibleUnits) do
        if currentVisibleUnits[key] == nil and previous.Label ~= nil and previous.Label ~= "" then
            PushQueueLabel(QUEUE_HIDDEN, "unit", previous.Label)
        end
    end

    m_previousVisibleUnits = currentVisibleUnits
end

local function ApplyGoneSnapshotDiff()
    for plotIndex in pairs(m_recentlyVisiblePlots) do
        local plot = Map.GetPlotByIndex(plotIndex)
        if plot ~= nil and IsPlotCurrentlyVisible(plot) then
            local nowKind = GetSpecialImprovementKind(plot:GetImprovementType())
            local previousKind = m_specialImprovementKinds[plotIndex]
            if previousKind ~= nil and previousKind ~= nowKind then
                local label = GetSpecialImprovementLabel(previousKind)
                if label ~= nil and label ~= "" then
                    PushQueueLabel(QUEUE_GONE, "improvement", label)
                end
            end
            m_specialImprovementKinds[plotIndex] = nowKind
        end
    end

    m_recentlyVisiblePlots = {}
end

local function ApplySnapshotDiffs()
    ApplyUnitSnapshotDiff()
    ApplyGoneSnapshotDiff()
end

local function FlushAllQueues()
    ApplySnapshotDiffs()

    local revealText = BuildQueueText(QUEUE_REVEAL)
    local hiddenText = BuildQueueText(QUEUE_HIDDEN)
    local goneText = BuildQueueText(QUEUE_GONE)
    local lines = {}

    if revealText ~= nil and revealText ~= "" then
        table.insert(lines, Locale.Lookup("LOC_CAI_REVEAL_QUEUE_REVEALED", revealText))
    end
    if hiddenText ~= nil and hiddenText ~= "" then
        table.insert(lines, Locale.Lookup("LOC_CAI_REVEAL_QUEUE_HIDDEN", hiddenText))
    end
    if goneText ~= nil and goneText ~= "" then
        table.insert(lines, Locale.Lookup("LOC_CAI_REVEAL_QUEUE_GONE", goneText))
    end

    ClearQueue(GetQueue(QUEUE_REVEAL))
    ClearQueue(GetQueue(QUEUE_HIDDEN))
    ClearQueue(GetQueue(QUEUE_GONE))
    m_lastEventTime = nil

    if #lines > 0 then
        Speak(table.concat(lines, "[NEWLINE]"))
    end
end

local function OnPlotVisibilityChanged(x, y, visibilityType)
    TouchTimer()

    if visibilityType == RevealedState.VISIBLE then
        MarkPlotVisibleByCoords(x, y)
        Enqueue(QUEUE_REVEAL, "plot", Locale.Lookup("LOC_CAI_REVEAL_PLOT"))
    end
end

local function OnUnitVisibilityChanged(playerID, unitID, visibilityType)
    TouchTimer()
end

local function OnImprovementVisibilityChanged(x, y, improvementType, visibilityType)
    TouchTimer()

    if visibilityType == RevealedState.VISIBLE then
        MarkPlotVisibleByCoords(x, y)
    end

    local label = LookupInfoName(GameInfo.Improvements, improvementType, "improvement")
    if label == nil then
        return
    end

    QueueEventDrivenVisibility("improvement", label, visibilityType)
end

local function OnResourceVisibilityChanged(x, y, resourceType, visibilityType)
    TouchTimer()

    if visibilityType == RevealedState.VISIBLE then
        MarkPlotVisibleByCoords(x, y)
    end

    local label = LookupInfoName(GameInfo.Resources, resourceType, "resource")
    if label == nil then
        return
    end

    QueueEventDrivenVisibility("resource", label, visibilityType)
end

local function OnCityVisibilityChanged(playerID, cityID, visibilityType)
    TouchTimer()

    local label = GetCityName(playerID, cityID)
    if label == nil then
        return
    end

    QueueEventDrivenVisibility("city", label, visibilityType)
end

local function OnDistrictVisibilityChanged(playerID, districtID, visibilityType)
    TouchTimer()

    local label = GetDistrictName(playerID, districtID)
    if label == nil then
        return
    end

    QueueEventDrivenVisibility("district", label, visibilityType)
end

EVENT_BINDINGS = {
    { Event = Events.PlotVisibilityChanged,        Handler = OnPlotVisibilityChanged },
    { Event = Events.UnitVisibilityChanged,        Handler = OnUnitVisibilityChanged },
    { Event = Events.ImprovementVisibilityChanged, Handler = OnImprovementVisibilityChanged },
    { Event = Events.ResourceVisibilityChanged,    Handler = OnResourceVisibilityChanged },
    { Event = Events.CityVisibilityChanged,        Handler = OnCityVisibilityChanged },
    { Event = Events.DistrictVisibilityChanged,    Handler = OnDistrictVisibilityChanged },
}

function RevealAnnouncements_CAI.Initialize()
    if m_isInitialized then
        return
    end

    EnsureQueues()
    BootstrapVisibleUnitSnapshot()
    BootstrapSpecialImprovementSnapshot()

    for _, binding in ipairs(EVENT_BINDINGS) do
        binding.Event.Add(binding.Handler)
    end

    m_isInitialized = true
end

function RevealAnnouncements_CAI.Clear()
    EnsureQueues()
    ClearQueue(GetQueue(QUEUE_REVEAL))
    ClearQueue(GetQueue(QUEUE_HIDDEN))
    ClearQueue(GetQueue(QUEUE_GONE))
    m_previousVisibleUnits = {}
    m_specialImprovementKinds = {}
    m_recentlyVisiblePlots = {}
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
        FlushAllQueues()
    end
end
