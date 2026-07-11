local Utils = CAIWorldScannerUtils

local LAKE_KEY = "LOC_TOOLTIP_LAKE"
local COAST_KEY = "LOC_TOOLTIP_COAST"

local subCategoryLabels = {
    base = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_BASE",
    features = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_FEATURES",
    elevation = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_ELEVATION",
}

CAIWorldScannerCategory_Terrain = {
    Id = "terrain",
    LabelKey = "LOC_CAI_WORLD_SCANNER_CATEGORY_TERRAIN",
    SubCategoryOrder = { "base", "features", "elevation" },
    SubCategoryLabels = subCategoryLabels,
    GroupLabelResolver = function(_, firstItem)
        return firstItem ~= nil and firstItem.GroupLabelKey or "LOC_CAI_WORLD_SCANNER_UNKNOWN"
    end,
}

function CAIWorldScannerCategory_Terrain.PlotExtract(plotIndex, plot, context, collect)
    local terrainType = plot:GetTerrainType()
    local terrainInfo = GameInfo.Terrains[terrainType]
    if terrainInfo ~= nil then
        local terrainLabelKey = terrainInfo.Name
        local groupId = tostring(terrainInfo.TerrainType)
        local groupLabelKey = terrainInfo.Name

        if terrainInfo.TerrainType == "TERRAIN_COAST" then
            if plot:IsLake() then
                terrainLabelKey = LAKE_KEY
                groupId = "lake"
                groupLabelKey = LAKE_KEY
            else
                terrainLabelKey = COAST_KEY
                groupId = "coast"
                groupLabelKey = COAST_KEY
            end
        end

        collect({
            Id = "terrain:base:" .. tostring(plotIndex),
            PlotIndex = plotIndex,
            LabelKey = terrainLabelKey,
            SubCategoryId = "base",
            GroupId = groupId,
            GroupLabelKey = groupLabelKey,
            Validate = function(item, validateContext)
                local validatePlot = Map.GetPlotByIndex(item.PlotIndex)
                if validatePlot == nil
                    or not Utils.IsPlotRevealed(validateContext, validatePlot)
                    or validatePlot:GetTerrainType() ~= terrainType then
                    return false
                end

                if terrainInfo.TerrainType == "TERRAIN_COAST" then
                    return item.GroupId == "lake" and validatePlot:IsLake()
                        or item.GroupId == "coast" and not validatePlot:IsLake()
                end

                return true
            end,
        })
    end

    local featureType = plot:GetFeatureType()
    local featureInfo = GameInfo.Features[featureType]
    if featureInfo ~= nil and not featureInfo.NaturalWonder then
        collect({
            Id = "terrain:feature:" .. tostring(plotIndex),
            PlotIndex = plotIndex,
            LabelKey = featureInfo.Name,
            SubCategoryId = "features",
            GroupId = tostring(featureInfo.FeatureType),
            GroupLabelKey = featureInfo.Name,
            Validate = function(item, validateContext)
                local validatePlot = Map.GetPlotByIndex(item.PlotIndex)
                return validatePlot ~= nil
                    and Utils.IsPlotRevealed(validateContext, validatePlot)
                    and validatePlot:GetFeatureType() == featureType
            end,
        })
    end

    if plot:IsMountain() then
        collect({
            Id = "terrain:elevation:mountain:" .. tostring(plotIndex),
            PlotIndex = plotIndex,
            LabelKey = terrainInfo ~= nil and terrainInfo.Name or "LOC_CAI_WORLD_SCANNER_UNKNOWN",
            SubCategoryId = "elevation",
            GroupId = "mountain",
            GroupLabelKey = terrainInfo ~= nil and terrainInfo.Name or "LOC_CAI_WORLD_SCANNER_UNKNOWN",
            Validate = function(item, validateContext)
                local validatePlot = Map.GetPlotByIndex(item.PlotIndex)
                return validatePlot ~= nil
                    and Utils.IsPlotRevealed(validateContext, validatePlot)
                    and validatePlot:IsMountain()
            end,
        })
    elseif plot:IsHills() then
        collect({
            Id = "terrain:elevation:hills:" .. tostring(plotIndex),
            PlotIndex = plotIndex,
            LabelKey = terrainInfo ~= nil and terrainInfo.Name or "LOC_CAI_WORLD_SCANNER_UNKNOWN",
            SubCategoryId = "elevation",
            GroupId = "hills",
            GroupLabelKey = terrainInfo ~= nil and terrainInfo.Name or "LOC_CAI_WORLD_SCANNER_UNKNOWN",
            Validate = function(item, validateContext)
                local validatePlot = Map.GetPlotByIndex(item.PlotIndex)
                return validatePlot ~= nil
                    and Utils.IsPlotRevealed(validateContext, validatePlot)
                    and validatePlot:IsHills()
                    and not validatePlot:IsMountain()
            end,
        })
    end
end

CAIWorldScanner:RegisterCategoryDefinition(CAIWorldScannerCategory_Terrain)
