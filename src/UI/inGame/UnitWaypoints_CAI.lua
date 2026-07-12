local info = ExposedMembers.CAIInfo or {}
ExposedMembers.CAIInfo = info

---@class QueuedPathEntry
---@field PlotId integer
---@field IsWaypoint boolean

---@class QueuedPathSnapshot
---@field Entries QueuedPathEntry[]
---@field ArrivalTurn integer
---@field TurnsUntilArrival integer
---@field DestinationPlotId integer
---@field NextWaypointPlotId integer|nil
---@field PathLookup table<integer, boolean>
---@field WaypointLookup table<integer, boolean>

CAIUnitWaypoints = CAIUnitWaypoints or {}
local UnitWaypoints = CAIUnitWaypoints

local function RebuildQueuedPathScannerCategory()
    if CAIWorldScanner ~= nil and CAIWorldScanner.RebuildCategory ~= nil then
        CAIWorldScanner:RebuildCategory("queuedPath")
    end
end

local function ResolveUnit(playerID, unitID)
    if playerID ~= nil and unitID ~= nil then
        return UnitManager.GetUnit(playerID, unitID)
    end
    return UI.GetHeadSelectedUnit()
end

local function GetQueuedDestinationPlotId(unit)
    local destinationPlotId = unit ~= nil and UnitManager.GetQueuedDestination(unit) or nil
    if destinationPlotId == nil or destinationPlotId == false or not Map.IsPlot(destinationPlotId) then
        return nil
    end
    return destinationPlotId
end

function UnitWaypoints:BuildSnapshot(unit)
    if unit == nil then
        return nil
    end

    local destinationPlotId = GetQueuedDestinationPlotId(unit)
    if destinationPlotId == nil then
        return nil
    end

    local pathInfo = UnitManager.GetMoveToPathEx(unit, destinationPlotId)
    local plots = pathInfo ~= nil and pathInfo.plots or nil
    local turns = pathInfo ~= nil and pathInfo.turns or nil
    if plots == nil or turns == nil or #plots <= 1 or #turns <= 1 then
        return nil
    end

    local snapshot = {
        Entries = {},
        ArrivalTurn = tonumber(turns[#turns]) or 1,
        DestinationPlotId = destinationPlotId,
        NextWaypointPlotId = nil,
        PathLookup = {},
        WaypointLookup = {},
    }
    snapshot.TurnsUntilArrival = math.max(0, snapshot.ArrivalTurn - 1)

    for _, plotId in ipairs(plots) do
        if plotId ~= nil and plotId ~= false and Map.IsPlot(plotId) then
            snapshot.Entries[#snapshot.Entries + 1] = {
                PlotId = plotId,
                IsWaypoint = false,
            }
            snapshot.PathLookup[plotId] = true
        end
    end

    local currentPlotId = unit:GetPlotId()
    local lastTurn = tonumber(turns[1]) or 1
    for i = 2, math.min(#snapshot.Entries, #turns) do
        local turn = tonumber(turns[i])
        if turn ~= nil and turn > lastTurn then
            local previousEntry = snapshot.Entries[i - 1]
            if previousEntry ~= nil and previousEntry.PlotId ~= currentPlotId then
                previousEntry.IsWaypoint = true
                snapshot.WaypointLookup[previousEntry.PlotId] = true
                snapshot.NextWaypointPlotId = snapshot.NextWaypointPlotId or previousEntry.PlotId
            end
            lastTurn = turn
        end
    end

    if snapshot.WaypointLookup[destinationPlotId] ~= true then
        snapshot.WaypointLookup[destinationPlotId] = true
    end
    snapshot.NextWaypointPlotId = snapshot.NextWaypointPlotId or destinationPlotId
    return snapshot
end

function UnitWaypoints:GetSnapshot(playerID, unitID)
    return self:BuildSnapshot(ResolveUnit(playerID, unitID))
end

local function OnQueuedPathUnitSelectionChanged(playerID)
    if playerID == Game.GetLocalPlayer() then
        RebuildQueuedPathScannerCategory()
    end
end

local function OnQueuedPathUnitMoveComplete(playerID, unitID)
    if playerID ~= Game.GetLocalPlayer() then
        return
    end

    local selectedUnit = UI.GetHeadSelectedUnit()
    if selectedUnit ~= nil and selectedUnit:GetOwner() == playerID and selectedUnit:GetID() == unitID then
        RebuildQueuedPathScannerCategory()
    end
end

function UnitWaypoints:Shutdown()
    Events.UnitSelectionChanged.Remove(OnQueuedPathUnitSelectionChanged)
    Events.UnitMoveComplete.Remove(OnQueuedPathUnitMoveComplete)
end

function info:GetQueuedPathSnapshot(playerID, unitID)
    return UnitWaypoints:GetSnapshot(playerID, unitID)
end

function info:GetQueuedPath(playerID, unitID)
    local snapshot = UnitWaypoints:GetSnapshot(playerID, unitID)
    return snapshot ~= nil and snapshot.Entries or {}
end

function info:GetQueuedPathArrivalTurn(playerID, unitID)
    local snapshot = UnitWaypoints:GetSnapshot(playerID, unitID)
    return snapshot ~= nil and snapshot.ArrivalTurn or nil
end

function info:GetUnitWaypoints(playerID, unitID)
    local snapshot = UnitWaypoints:GetSnapshot(playerID, unitID)
    local out = {}
    if snapshot == nil then
        return out
    end
    for _, entry in ipairs(snapshot.Entries) do
        if entry.IsWaypoint or entry.PlotId == snapshot.DestinationPlotId then
            out[#out + 1] = entry.PlotId
        end
    end
    return out
end

function info:GetNextUnitWaypoint(playerID, unitID)
    local snapshot = UnitWaypoints:GetSnapshot(playerID, unitID)
    return snapshot ~= nil and snapshot.NextWaypointPlotId or nil
end

function info:IsQueuedPathPlot(plotId)
    local snapshot = UnitWaypoints:GetSnapshot()
    return snapshot ~= nil and plotId ~= nil and snapshot.PathLookup[plotId] == true or false
end

function info:IsWaypointPlot(plotId)
    local snapshot = UnitWaypoints:GetSnapshot()
    return snapshot ~= nil and plotId ~= nil and snapshot.WaypointLookup[plotId] == true or false
end

Events.UnitSelectionChanged.Add(OnQueuedPathUnitSelectionChanged)
Events.UnitMoveComplete.Add(OnQueuedPathUnitMoveComplete)
