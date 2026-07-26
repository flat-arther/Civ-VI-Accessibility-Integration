if GameConfiguration.GetRuleSet() ~= "RULESET_SCENARIO_PIRATES" then return end
include("PiratesScenarioMapInfo_CAI")

local MapInfo = CAIPiratesMapInfo
local ZoneUtils = CAIWorldScannerZoneUtils
local Utils = CAIWorldScannerUtils

local SUB_TREASURE = "treasure"
local SUB_INFAMOUS = "infamousPirates"

local treasureSearchPlots = {}
local infamousSearchPlots = {}
local fleetRoutePlots = {}

local labels = {
    [SUB_TREASURE] = "LOC_CAI_WORLD_SCANNER_PIRATES_TREASURE",
    [SUB_INFAMOUS] = "LOC_CAI_WORLD_SCANNER_PIRATES_INFAMOUS",
}

CAIWorldScannerCategory_Pirates = {
    Id = "pirates",
    LabelKey = "LOC_CAI_WORLD_SCANNER_CATEGORY_PIRATES",
    SubCategoryOrder = {
        SUB_TREASURE,
        SUB_INFAMOUS,
    },
    SubCategoryLabels = labels,
    GroupOrderBySubCategory = {
        [SUB_TREASURE] = { "treasureSearch", "fleetRoutes", "treasure", "treasureLocations" },
        [SUB_INFAMOUS] = { "infamousSearch", "enemy" },
    },
    ExtractHiddenPlots = true,
    CanScan = function() return MapInfo.IsActive() end,
    GroupLabelResolver = function(_, firstItem)
        return firstItem ~= nil and firstItem.GroupLabelKey or "LOC_CAI_WORLD_SCANNER_UNKNOWN"
    end,
}

function CAIWorldScannerCategory_Pirates.BeginExtract()
    treasureSearchPlots = {}
    infamousSearchPlots = {}
    fleetRoutePlots = {}
end

function CAIWorldScannerCategory_Pirates.PlotExtract(plotIndex, plot, context, collect)
    if MapInfo.IsTreasureSearchPlot(plot, context.LocalPlayerID) then
        treasureSearchPlots[#treasureSearchPlots + 1] = plotIndex
    end
    if MapInfo.IsInfamousSearchPlot(plot) then
        infamousSearchPlots[#infamousSearchPlots + 1] = plotIndex
    end
    if MapInfo.IsTreasureFleetRoutePlot(plot) then
        fleetRoutePlots[#fleetRoutePlots + 1] = plotIndex
    end
    if Utils.IsPlotRevealed(context, plot) and MapInfo.IsTreasurePlot(plot) then
        collect({
            Id = "pirates:treasure:" .. tostring(plotIndex),
            PlotIndex = plotIndex,
            LabelKey = "LOC_CAI_WORLD_SCANNER_PIRATES_TREASURE_LOCATION",
            SubCategoryId = SUB_TREASURE,
            GroupId = "treasureLocations",
            GroupLabelKey = "LOC_CAI_WORLD_SCANNER_PIRATES_TREASURE_LOCATION",
            Validate = function(item)
                local currentPlot = Map.GetPlotByIndex(item.PlotIndex)
                return currentPlot ~= nil and MapInfo.IsTreasurePlot(currentPlot)
            end,
        })
    end
end

local function CollectZones(
    plotIndices, subCategoryId, context, collect, validator, groupId, labelKey)
    for _, zone in ipairs(ZoneUtils.PartitionPlotIndices(plotIndices)) do
        collect({
            Id = "pirates:" .. groupId .. ":" .. tostring(zone.MinPlotIndex),
            PlotIndex = ZoneUtils.FindNearestPlotIndex(
                zone.PlotIndices, context.SortOriginX, context.SortOriginY),
            ZonePlotIndices = zone.PlotIndices,
            ZoneValidatePlot = validator,
            LabelKey = labelKey,
            SubCategoryId = subCategoryId,
            GroupId = groupId,
            GroupLabelKey = labelKey,
        })
    end
end

function CAIWorldScannerCategory_Pirates.EndExtract(context, collect)
    CollectZones(treasureSearchPlots, SUB_TREASURE, context, collect,
        function(_, plot, validateContext)
            return MapInfo.IsTreasureSearchPlot(plot, validateContext.LocalPlayerID)
        end,
        "treasureSearch", "LOC_CAI_WORLD_SCANNER_PIRATES_TREASURE_SEARCH")
    CollectZones(infamousSearchPlots, SUB_INFAMOUS, context, collect,
        function(_, plot) return MapInfo.IsInfamousSearchPlot(plot) end,
        "infamousSearch", "LOC_CAI_WORLD_SCANNER_PIRATES_INFAMOUS_SEARCH")
    CollectZones(fleetRoutePlots, SUB_TREASURE, context, collect,
        function(_, plot) return MapInfo.IsTreasureFleetRoutePlot(plot) end,
        "fleetRoutes", "LOC_CAI_WORLD_SCANNER_PIRATES_FLEET_PATH")

    for _, target in ipairs(MapInfo.GetSensorTargets(context.LocalPlayerID)) do
        local labelKey = target.Kind == "enemy"
            and "LOC_CAI_WORLD_SCANNER_PIRATES_POINTER_SIGNAL"
            or "LOC_CAI_WORLD_SCANNER_PIRATES_DOWSING_SIGNAL"
        collect({
            Id = "pirates:sensor:" .. target.Kind .. ":" .. tostring(target.SourceUnitID),
            PlotIndex = target.PlotIndex,
            LabelKey = Locale.Lookup(labelKey, target.SourceUnitName, target.Distance),
            SubCategoryId = target.Kind == "enemy" and SUB_INFAMOUS or SUB_TREASURE,
            GroupId = target.Kind,
            GroupLabelKey = target.Kind == "enemy"
                and "LOC_CAI_WORLD_SCANNER_PIRATES_POINTER"
                or "LOC_CAI_WORLD_SCANNER_PIRATES_DOWSING",
        })
    end
end

CAIWorldScanner:RegisterCategoryDefinition(CAIWorldScannerCategory_Pirates)
