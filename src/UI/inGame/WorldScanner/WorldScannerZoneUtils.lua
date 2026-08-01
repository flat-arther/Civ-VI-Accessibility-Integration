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

local TILE_COUNT_REVEALED = "revealed"
local TILE_COUNT_UNEXPLORED = "unexplored"
local TILE_COUNT_REVEALED_OF_TOTAL = "revealedOfTotal"

---@param plotIndices integer[]
---@param context WorldScannerContext|nil
---@return integer
local function CountRevealedPlots(plotIndices, context)
    local count = 0
    for _, plotIndex in ipairs(plotIndices) do
        local plot = Map.GetPlotByIndex(plotIndex)
        if CAIWorldScannerUtils.IsPlotRevealed(context, plot) then
            count = count + 1
        end
    end
    return count
end

---@param labelKey string
---@param plotIndices integer[]
---@param context WorldScannerContext|nil
---@param mode string|nil
---@return string
function ZoneUtils.MakeTileCountLabel(labelKey, plotIndices, context, mode)
    local resolvedLabel = CAIWorldScannerUtils.ResolveText(labelKey)
    if mode == TILE_COUNT_UNEXPLORED then
        return Locale.Lookup(
            "LOC_CAI_WORLD_SCANNER_ZONE_UNEXPLORED_TILES",
            resolvedLabel,
            #plotIndices
        )
    end

    local revealedCount = CountRevealedPlots(plotIndices, context)
    if mode == TILE_COUNT_REVEALED_OF_TOTAL then
        return Locale.Lookup(
            "LOC_CAI_WORLD_SCANNER_ZONE_REVEALED_OF_TOTAL_TILES",
            resolvedLabel,
            revealedCount,
            #plotIndices
        )
    end

    return Locale.Lookup(
        "LOC_CAI_WORLD_SCANNER_ZONE_REVEALED_TILES",
        resolvedLabel,
        revealedCount
    )
end

---@param item table
---@param context WorldScannerContext|nil
local function UpdateTileCountLabel(item, context)
    if item.ZoneTileCountEmbedded then
        return
    end

    item._CAIZoneTileCountBaseLabel = item._CAIZoneTileCountBaseLabel or item.LabelKey
    item.LabelKey = ZoneUtils.MakeTileCountLabel(
        item._CAIZoneTileCountBaseLabel,
        item.ZonePlotIndices,
        context,
        item.ZoneTileCountMode or TILE_COUNT_REVEALED
    )
end

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
    else
        UpdateTileCountLabel(item, context)
    end
    return nearestPlotIndex
end
