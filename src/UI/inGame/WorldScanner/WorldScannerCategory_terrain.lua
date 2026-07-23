include("Civ6Common")

local Utils = CAIWorldScannerUtils
local ZoneUtils = CAIWorldScannerZoneUtils

local LAKE_KEY = "LOC_TOOLTIP_LAKE"
local COAST_KEY = "LOC_TOOLTIP_COAST"
local MOUNTAIN_CLASS = GameInfo.TerrainClasses["TERRAIN_CLASS_MOUNTAIN"]

local m_unexploredPlotIndices = {}
local m_mountainBuckets = {}

local subCategoryLabels = {
    base = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_BASE",
    features = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_FEATURES",
    elevation = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_ELEVATION",
    freshwater = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_FRESH_WATER",
}

CAIWorldScannerCategory_Terrain = {
    Id = "terrain",
    LabelKey = "LOC_CAI_WORLD_SCANNER_CATEGORY_TERRAIN",
    SubCategoryOrder = { "base", "features", "elevation", "freshwater" },
    SubCategoryLabels = subCategoryLabels,
    ExtractHiddenPlots = true,
    GroupLabelResolver = function(_, firstItem)
        return firstItem ~= nil and firstItem.GroupLabelKey or "LOC_CAI_WORLD_SCANNER_UNKNOWN"
    end,
}

local function GetNamedMountainTerritory(plotIndex)
    if not IsExpansion2Active()
        or Territories == nil
        or Territories.GetTerritoryAt == nil
        or MOUNTAIN_CLASS == nil then
        return nil, nil
    end

    local territory = Territories.GetTerritoryAt(plotIndex)
    if territory == nil or territory:GetTerrainClass() ~= MOUNTAIN_CLASS.Index then
        return nil, nil
    end

    local name = territory:GetName()
    if name == nil or name == "" then
        return nil, nil
    end
    return territory:GetID(), name
end

local function AddMountainPlot(plotIndex)
    local territoryId, territoryName = GetNamedMountainTerritory(plotIndex)
    local key = territoryId ~= nil and "territory:" .. tostring(territoryId) or "generic"
    local bucket = m_mountainBuckets[key]
    if bucket == nil then
        bucket = {
            PlotIndices = {},
            TerritoryId = territoryId,
            LabelKey = territoryName or "LOC_CAI_WORLD_SCANNER_MOUNTAIN_RANGE",
        }
        m_mountainBuckets[key] = bucket
    end
    bucket.PlotIndices[#bucket.PlotIndices + 1] = plotIndex
end

function CAIWorldScannerCategory_Terrain.BeginExtract()
    m_unexploredPlotIndices = {}
    m_mountainBuckets = {}
end

function CAIWorldScannerCategory_Terrain.PlotExtract(plotIndex, plot, context, collect, isRevealed)
    if not isRevealed then
        m_unexploredPlotIndices[#m_unexploredPlotIndices + 1] = plotIndex
        return
    end

    local terrainType = plot:GetTerrainType()
    local terrainInfo = GameInfo.Terrains[terrainType]
    if plot:IsFreshWater() then
        collect({
            Id = "terrain:freshwater:" .. tostring(plotIndex),
            PlotIndex = plotIndex,
            LabelKey = "LOC_SETTLEMENT_RECOMMENDATION_FRESH_WATER",
            SubCategoryId = "freshwater",
            GroupId = "freshwater",
            GroupLabelKey = "LOC_SETTLEMENT_RECOMMENDATION_FRESH_WATER",
            Validate = function(item, validateContext)
                local validatePlot = Map.GetPlotByIndex(item.PlotIndex)
                return validatePlot ~= nil
                    and Utils.IsPlotRevealed(validateContext, validatePlot)
                    and validatePlot:IsFreshWater()
            end,
        })
    end

    if plot:IsMountain() then
        AddMountainPlot(plotIndex)
        return
    end

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

    if plot:IsHills() then
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

function CAIWorldScannerCategory_Terrain.EndExtract(_, collect)
    for _, zone in ipairs(ZoneUtils.PartitionPlotIndices(m_unexploredPlotIndices)) do
        collect({
            Id = "terrain:unexplored:zone:" .. tostring(zone.MinPlotIndex),
            PlotIndex = zone.MinPlotIndex,
            ZonePlotIndices = zone.PlotIndices,
            ZoneValidatePlot = function(_, plot, validateContext)
                return not Utils.IsPlotRevealed(validateContext, plot)
            end,
            ZoneUpdateLabel = function(item)
                item.LabelKey = Locale.Lookup(
                    "LOC_CAI_WORLD_SCANNER_UNEXPLORED_REGION_TILES",
                    #item.ZonePlotIndices
                )
            end,
            LabelKey = Locale.Lookup(
                "LOC_CAI_WORLD_SCANNER_UNEXPLORED_REGION_TILES",
                #zone.PlotIndices
            ),
            SubCategoryId = "base",
            GroupId = "unexplored",
            GroupLabelKey = "LOC_CAI_WORLD_SCANNER_UNEXPLORED_REGION",
        })
    end

    for bucketKey, bucket in pairs(m_mountainBuckets) do
        for _, zone in ipairs(ZoneUtils.PartitionPlotIndices(bucket.PlotIndices)) do
            local territoryId = bucket.TerritoryId
            collect({
                Id = "terrain:elevation:mountain:" .. bucketKey .. ":" .. tostring(zone.MinPlotIndex),
                PlotIndex = zone.MinPlotIndex,
                ZonePlotIndices = zone.PlotIndices,
                ZoneValidatePlot = function(_, plot, validateContext)
                    if not Utils.IsPlotRevealed(validateContext, plot) or not plot:IsMountain() then
                        return false
                    end
                    local validateTerritoryId = GetNamedMountainTerritory(plot:GetIndex())
                    return territoryId ~= nil and validateTerritoryId == territoryId
                        or territoryId == nil and validateTerritoryId == nil
                end,
                LabelKey = bucket.LabelKey,
                SubCategoryId = "elevation",
                GroupId = "mountain",
                GroupLabelKey = "LOC_CAI_SURVEYOR_MOUNTAINS",
            })
        end
    end
end

CAIWorldScanner:RegisterCategoryDefinition(CAIWorldScannerCategory_Terrain)
