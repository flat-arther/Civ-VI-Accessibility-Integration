local MapInfo = CAICivRoyaleMapInfo
local ZoneUtils = CAIWorldScannerZoneUtils

local SUB_SAFE_ZONE = "safeZone"
local SUB_RED_DEATH = "redDeath"
local SUB_MUTANT_FALLOUT = "mutantFallout"
local SUB_OBJECTS = "objects"

local safePlots = {}
local redDeathPlots = {}
local mutantPlots = {}

local subCategoryLabels = {
    [SUB_SAFE_ZONE] = "LOC_CAI_CIV_ROYALE_SAFE_ZONE",
    [SUB_RED_DEATH] = "LOC_CAI_WORLD_SCANNER_CIV_ROYALE_RED_DEATH",
    [SUB_MUTANT_FALLOUT] = "LOC_CAI_CIV_ROYALE_MUTANT_FALLOUT",
    [SUB_OBJECTS] = "LOC_CAI_WORLD_SCANNER_CIV_ROYALE_OBJECTS",
}

CAIWorldScannerCategory_CivRoyale = {
    Id = "civRoyale",
    LabelKey = "LOC_CAI_WORLD_SCANNER_CATEGORY_CIV_ROYALE",
    SubCategoryOrder = {
        SUB_SAFE_ZONE,
        SUB_RED_DEATH,
        SUB_MUTANT_FALLOUT,
        SUB_OBJECTS,
    },
    SubCategoryLabels = subCategoryLabels,
    ExtractHiddenPlots = true,
    CanScan = function()
        return MapInfo.IsActive()
    end,
    GroupLabelResolver = function(_, firstItem)
        return firstItem ~= nil and firstItem.GroupLabelKey or "LOC_CAI_WORLD_SCANNER_UNKNOWN"
    end,
}

function CAIWorldScannerCategory_CivRoyale.BeginExtract()
    safePlots = {}
    redDeathPlots = {}
    mutantPlots = {}
    MapInfo.RefreshHungerTargets(Game.GetLocalPlayer())
end

function CAIWorldScannerCategory_CivRoyale.PlotExtract(plotIndex, plot, context, collect)
    local state = MapInfo.GetZoneState(plot, context.LocalPlayerID)
    if state ~= nil then
        if state.SafeZone == "safe" then safePlots[#safePlots + 1] = plotIndex end
        if state.Fallout == "redDeath" then redDeathPlots[#redDeathPlots + 1] = plotIndex end
        if state.Fallout == "mutant" then mutantPlots[#mutantPlots + 1] = plotIndex end
    end

    local labels = MapInfo.GetObjectSpeech(plot, context.LocalPlayerID)
    for index, label in ipairs(labels or {}) do
        local expectedLabel = label
        collect({
            Id = "civRoyale:object:" .. tostring(plotIndex) .. ":" .. tostring(index),
            PlotIndex = plotIndex,
            LabelKey = expectedLabel,
            SubCategoryId = SUB_OBJECTS,
            GroupId = expectedLabel,
            GroupLabelKey = expectedLabel,
            Validate = function(item, validateContext)
                local validatePlot = Map.GetPlotByIndex(item.PlotIndex)
                local currentLabels = MapInfo.GetObjectSpeech(validatePlot, validateContext.LocalPlayerID, true)
                for _, currentLabel in ipairs(currentLabels or {}) do
                    if currentLabel == expectedLabel then return true end
                end
                return false
            end,
        })
    end
end

local function CollectZones(plotIndices, subCategoryId, labelKey, context, collect, validator)
    for _, zone in ipairs(ZoneUtils.PartitionPlotIndices(plotIndices)) do
        collect({
            Id = "civRoyale:" .. subCategoryId .. ":" .. tostring(zone.MinPlotIndex),
            PlotIndex = ZoneUtils.FindNearestPlotIndex(
                zone.PlotIndices, context.SortOriginX, context.SortOriginY),
            ZonePlotIndices = zone.PlotIndices,
            ZoneValidatePlot = validator,
            LabelKey = labelKey,
            SubCategoryId = subCategoryId,
            GroupId = subCategoryId,
            GroupLabelKey = labelKey,
        })
    end
end

function CAIWorldScannerCategory_CivRoyale.EndExtract(context, collect)
    local centerPlot = MapInfo.GetSafeZoneCenterPlot()
    if centerPlot ~= nil then
        local centerPlotIndex = centerPlot:GetIndex()
        collect({
            Id = "civRoyale:safeZoneCenter",
            PlotIndex = centerPlotIndex,
            LabelKey = "LOC_CAI_WORLD_SCANNER_CIV_ROYALE_SAFE_ZONE_CENTER",
            SubCategoryId = SUB_SAFE_ZONE,
            GroupId = "safeZoneCenter",
            GroupLabelKey = "LOC_CAI_WORLD_SCANNER_CIV_ROYALE_SAFE_ZONE_CENTER",
            Validate = function(item)
                local currentCenter = MapInfo.GetSafeZoneCenterPlot()
                return currentCenter ~= nil and currentCenter:GetIndex() == item.PlotIndex
            end,
        })
    end

    CollectZones(safePlots, SUB_SAFE_ZONE, "LOC_CAI_CIV_ROYALE_SAFE_ZONE", context, collect,
        function(_, plot, validateContext)
            local state = MapInfo.GetZoneState(plot, validateContext.LocalPlayerID)
            return state ~= nil and state.SafeZone == "safe"
        end)
    CollectZones(redDeathPlots, SUB_RED_DEATH, "LOC_CAI_WORLD_SCANNER_CIV_ROYALE_RED_DEATH", context, collect,
        function(_, plot, validateContext)
            local state = MapInfo.GetZoneState(plot, validateContext.LocalPlayerID)
            return state ~= nil and state.Fallout == "redDeath"
        end)
    CollectZones(mutantPlots, SUB_MUTANT_FALLOUT, "LOC_CAI_CIV_ROYALE_MUTANT_FALLOUT", context, collect,
        function(_, plot, validateContext)
            local state = MapInfo.GetZoneState(plot, validateContext.LocalPlayerID)
            return state ~= nil and state.Fallout == "mutant"
        end)
end

CAIWorldScanner:RegisterCategoryDefinition(CAIWorldScannerCategory_CivRoyale)
