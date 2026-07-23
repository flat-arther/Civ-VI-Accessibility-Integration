---@class WorldScannerZone
---@field PlotIndices integer[]
---@field MinPlotIndex integer

---@class WorldScannerZoneUtils
---@type WorldScannerZoneUtils
CAIWorldScannerZoneUtils = CAIWorldScannerZoneUtils or {}

local ZoneUtils = CAIWorldScannerZoneUtils

local NEIGHBOR_DIRECTIONS = {
    DirectionTypes.DIRECTION_NORTHEAST,
    DirectionTypes.DIRECTION_EAST,
    DirectionTypes.DIRECTION_SOUTHEAST,
    DirectionTypes.DIRECTION_SOUTHWEST,
    DirectionTypes.DIRECTION_WEST,
    DirectionTypes.DIRECTION_NORTHWEST,
}

---@param plotIndices integer[]|nil
---@return WorldScannerZone[]
function ZoneUtils.PartitionPlotIndices(plotIndices)
    local memberSet = {}
    local ordered = {}
    for _, plotIndex in ipairs(plotIndices or {}) do
        if memberSet[plotIndex] == nil and Map.GetPlotByIndex(plotIndex) ~= nil then
            memberSet[plotIndex] = true
            ordered[#ordered + 1] = plotIndex
        end
    end
    table.sort(ordered)

    local visited = {}
    local zones = {}
    for _, firstPlotIndex in ipairs(ordered) do
        if not visited[firstPlotIndex] then
            local members = {}
            local queue = { firstPlotIndex }
            local readIndex = 1
            visited[firstPlotIndex] = true

            while readIndex <= #queue do
                local plotIndex = queue[readIndex]
                readIndex = readIndex + 1
                members[#members + 1] = plotIndex

                local plot = Map.GetPlotByIndex(plotIndex)
                for _, direction in ipairs(NEIGHBOR_DIRECTIONS) do
                    local neighbor = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), direction)
                    local neighborIndex = neighbor ~= nil and neighbor:GetIndex() or nil
                    if neighborIndex ~= nil and memberSet[neighborIndex] and not visited[neighborIndex] then
                        visited[neighborIndex] = true
                        queue[#queue + 1] = neighborIndex
                    end
                end
            end

            table.sort(members)
            zones[#zones + 1] = {
                PlotIndices = members,
                MinPlotIndex = members[1],
            }
        end
    end

    table.sort(zones, function(a, b)
        return a.MinPlotIndex < b.MinPlotIndex
    end)
    return zones
end

---@param plotIndices integer[]|nil
---@param originX integer|nil
---@param originY integer|nil
---@return integer|nil
function ZoneUtils.FindNearestPlotIndex(plotIndices, originX, originY)
    local nearestPlotIndex = nil
    local nearestDistance = math.huge
    for _, plotIndex in ipairs(plotIndices or {}) do
        local plot = Map.GetPlotByIndex(plotIndex)
        if plot ~= nil then
            local distance = originX ~= nil and originY ~= nil
                and Map.GetPlotDistance(originX, originY, plot:GetX(), plot:GetY())
                or 0
            if distance < nearestDistance
                or distance == nearestDistance and (nearestPlotIndex == nil or plotIndex < nearestPlotIndex) then
                nearestDistance = distance
                nearestPlotIndex = plotIndex
            end
        end
    end
    return nearestPlotIndex
end

---@param item table
---@param context WorldScannerContext|nil
---@param pruneInvalid boolean
---@return integer|nil
function ZoneUtils.ResolveItemTarget(item, context, pruneInvalid)
    local plotIndices = item and item.ZonePlotIndices or nil
    if plotIndices == nil then
        return item and item.PlotIndex or nil
    end

    local originX = context and context.SortOriginX or nil
    local originY = context and context.SortOriginY or nil
    local validator = item.ZoneValidatePlot
    local nearestPlotIndex = nil
    local nearestDistance = math.huge
    local writeIndex = 0

    for readIndex = 1, #plotIndices do
        local plotIndex = plotIndices[readIndex]
        local plot = Map.GetPlotByIndex(plotIndex)
        local valid = plot ~= nil and (validator == nil or validator(item, plot, context))
        if valid then
            if pruneInvalid then
                writeIndex = writeIndex + 1
                plotIndices[writeIndex] = plotIndex
            end

            local distance = originX ~= nil and originY ~= nil
                and Map.GetPlotDistance(originX, originY, plot:GetX(), plot:GetY())
                or 0
            if distance < nearestDistance
                or distance == nearestDistance and (nearestPlotIndex == nil or plotIndex < nearestPlotIndex) then
                nearestDistance = distance
                nearestPlotIndex = plotIndex
            end
        end
    end

    if pruneInvalid then
        for index = #plotIndices, writeIndex + 1, -1 do
            plotIndices[index] = nil
        end
    end

    item.PlotIndex = nearestPlotIndex
    if item.ZoneUpdateLabel ~= nil then
        item.ZoneUpdateLabel(item, context)
    end
    return nearestPlotIndex
end
