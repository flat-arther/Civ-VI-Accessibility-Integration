local info = ExposedMembers.CAIInfo or {}
ExposedMembers.CAIInfo = info

---@class QueuedPathEntry
---@field PlotId integer
---@field IsWaypoint boolean

---@class UnitWaypoints
---@field _queuedPath QueuedPathEntry[]
---@field _queuedPathLookup table<integer, boolean>
---@field _waypointLookup table<integer, boolean>
---@field _arrivalTurn integer|nil
CAIUnitWaypoints = CAIUnitWaypoints or {}

local UnitWaypoints = CAIUnitWaypoints

local function CopyQueuedPath(entries)
    local out = {}
    for i, entry in ipairs(entries or {}) do
        out[i] = {
            PlotId = entry.PlotId,
            IsWaypoint = entry.IsWaypoint == true,
        }
    end
    return out
end

local function RebuildQueuedPathScannerCategory()
    if CAIWorldScanner ~= nil and CAIWorldScanner.RebuildCategory ~= nil then
        CAIWorldScanner:RebuildCategory("queuedPath")
    end
end

function UnitWaypoints:Clear()
    self._queuedPath = {}
    self._queuedPathLookup = {}
    self._waypointLookup = {}
    self._arrivalTurn = nil
end

local function GetSelectedUnit()
    return UI.GetHeadSelectedUnit()
end

function UnitWaypoints:EnsureSelectedUnitStillQueued()
    local unit = GetSelectedUnit()
    if unit == nil then
        self:Clear()
        return nil
    end

    local destinationPlotId = UnitManager.GetQueuedDestination(unit)
    if destinationPlotId == nil or destinationPlotId == false or not Map.IsPlot(destinationPlotId) then
        self:Clear()
        return nil
    end

    if #self._queuedPath == 0 then
        return unit
    end

    local firstEntry = self._queuedPath[1]
    if firstEntry == nil or firstEntry.PlotId ~= unit:GetPlotId() then
        self:Clear()
        return nil
    end

    return unit
end

function UnitWaypoints:RefreshForUnit(unit)
    self:Clear()

    if unit == nil then
        return false
    end

    local destinationPlotId = UnitManager.GetQueuedDestination(unit)
    if destinationPlotId == nil or destinationPlotId == false or not Map.IsPlot(destinationPlotId) then
        return false
    end

    local pathInfo = UnitManager.GetMoveToPathEx(unit, destinationPlotId)
    local plots = pathInfo ~= nil and pathInfo.plots or nil
    local turns = pathInfo ~= nil and pathInfo.turns or nil
    if plots == nil or turns == nil or #plots <= 1 or #turns <= 1 then
        return false
    end

    for _, plotId in ipairs(plots) do
        if plotId ~= nil and plotId ~= false and Map.IsPlot(plotId) then
            self._queuedPath[#self._queuedPath + 1] = {
                PlotId = plotId,
                IsWaypoint = false,
            }
            self._queuedPathLookup[plotId] = true
        end
    end

    local currentPlotId = unit:GetPlotId()
    local lastTurn = tonumber(turns[1]) or 1
    for i = 2, math.min(#self._queuedPath, #turns) do
        local turn = tonumber(turns[i])
        if turn ~= nil and turn > lastTurn then
            local previousEntry = self._queuedPath[i - 1]
            if previousEntry ~= nil
                and previousEntry.PlotId ~= nil
                and previousEntry.PlotId ~= currentPlotId then
                previousEntry.IsWaypoint = true
                self._waypointLookup[previousEntry.PlotId] = true
            end
            lastTurn = turn
        end
    end

    self._arrivalTurn = tonumber(turns[#turns]) or nil
    return #self._queuedPath > 1
end

function UnitWaypoints:RefreshSelectedUnit()
    return self:RefreshForUnit(GetSelectedUnit())
end

function UnitWaypoints:GetQueuedPath()
    if self:EnsureSelectedUnitStillQueued() == nil then
        return {}
    end
    return CopyQueuedPath(self._queuedPath)
end

function UnitWaypoints:GetQueuedPathArrivalTurn()
    if self:EnsureSelectedUnitStillQueued() == nil then
        return nil
    end
    return self._arrivalTurn
end

function UnitWaypoints:GetUnitWaypoints()
    if self:EnsureSelectedUnitStillQueued() == nil then
        return {}
    end

    local out = {}
    for _, entry in ipairs(self._queuedPath) do
        if entry.IsWaypoint then
            out[#out + 1] = entry.PlotId
        end
    end
    return out
end

function UnitWaypoints:GetNext()
    if self:EnsureSelectedUnitStillQueued() == nil then
        return nil
    end

    for _, entry in ipairs(self._queuedPath) do
        if entry.IsWaypoint then
            return entry.PlotId
        end
    end
    return nil
end

function UnitWaypoints:IsQueuedPathPlot(plotId)
    if self:EnsureSelectedUnitStillQueued() == nil then
        return false
    end
    return plotId ~= nil and self._queuedPathLookup[plotId] == true or false
end

function UnitWaypoints:IsWaypointPlot(plotId)
    if self:EnsureSelectedUnitStillQueued() == nil then
        return false
    end
    return plotId ~= nil and self._waypointLookup[plotId] == true or false
end

local function OnQueuedPathUnitSelectionChanged(playerID, unitID, hexI, hexJ, hexK, isSelected, isEditable)
    if playerID ~= Game.GetLocalPlayer() then
        return
    end

    UnitWaypoints:Clear()
    if isSelected then
        UnitWaypoints:RefreshSelectedUnit()
    end

    RebuildQueuedPathScannerCategory()
end

local function OnQueuedPathUnitMoveComplete(playerID, unitID, x, y)
    if playerID ~= Game.GetLocalPlayer() then
        return
    end

    local selectedUnit = GetSelectedUnit()
    if selectedUnit == nil or selectedUnit:GetOwner() ~= playerID or selectedUnit:GetID() ~= unitID then
        return
    end

    UnitWaypoints:RefreshSelectedUnit()
    RebuildQueuedPathScannerCategory()
end

function UnitWaypoints:Shutdown()
    Events.UnitSelectionChanged.Remove(OnQueuedPathUnitSelectionChanged)
    Events.UnitMoveComplete.Remove(OnQueuedPathUnitMoveComplete)
    self:Clear()
end

function info:GetQueuedPath()
    return UnitWaypoints:GetQueuedPath()
end

function info:GetQueuedPathArrivalTurn()
    return UnitWaypoints:GetQueuedPathArrivalTurn()
end

function info:GetUnitWaypoints()
    return UnitWaypoints:GetUnitWaypoints()
end

function info:GetNextUnitWaypoint()
    return UnitWaypoints:GetNext()
end

function info:IsQueuedPathPlot(plotId)
    return UnitWaypoints:IsQueuedPathPlot(plotId)
end

function info:IsWaypointPlot(plotId)
    return UnitWaypoints:IsWaypointPlot(plotId)
end

Events.UnitSelectionChanged.Add(OnQueuedPathUnitSelectionChanged)
Events.UnitMoveComplete.Add(OnQueuedPathUnitMoveComplete)
