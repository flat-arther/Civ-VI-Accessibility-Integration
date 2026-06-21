local Utils = CAIWorldScannerUtils

local subCategoryLabels = {
    naturalWonders = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_NATURAL_WONDERS",
    tribalVillages = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_TRIBAL_VILLAGES",
}

CAIWorldScannerCategory_SpecialMapObjects = {
    Id = "specialMapObjects",
    LabelKey = "LOC_CAI_WORLD_SCANNER_CATEGORY_SPECIAL_MAP_OBJECTS",
    SubCategoryOrder = { "naturalWonders", "tribalVillages" },
    SubCategoryLabels = subCategoryLabels,
    GroupLabelResolver = function(_, firstItem)
        return firstItem ~= nil and firstItem.GroupLabelKey or "LOC_CAI_WORLD_SCANNER_UNKNOWN"
    end,
}

function CAIWorldScannerCategory_SpecialMapObjects.PlotExtract(plotIndex, plot, context, collect)
    local featureType = plot:GetFeatureType()
    local featureInfo = GameInfo.Features[featureType]
    if featureInfo ~= nil and featureInfo.NaturalWonder then
        collect({
            Id = "special:naturalWonder:" .. tostring(plotIndex),
            PlotIndex = plotIndex,
            LabelKey = featureInfo.Name,
            SubCategoryId = "naturalWonders",
            GroupId = tostring(featureInfo.FeatureType),
            GroupLabelKey = featureInfo.Name,
            Validate = function(item, validateContext)
                local validatePlot = Map.GetPlotByIndex(item.PlotIndex)
                if validatePlot == nil or not Utils.IsPlotRevealed(validateContext, validatePlot) then
                    return false
                end

                local validateFeature = GameInfo.Features[validatePlot:GetFeatureType()]
                return validateFeature ~= nil
                    and validateFeature.FeatureType == featureType
                    and validateFeature.NaturalWonder
            end,
        })
    end

    local improvementIndex = plot:GetImprovementType()
    local improvementInfo = improvementIndex ~= nil and GameInfo.Improvements[improvementIndex] or nil
    if improvementInfo ~= nil and improvementInfo.Goody then
        local improvementType = improvementInfo.ImprovementType
        collect({
            Id = "special:goodyHut:" .. tostring(plotIndex),
            PlotIndex = plotIndex,
            LabelKey = improvementInfo.Name,
            SubCategoryId = "tribalVillages",
            GroupId = tostring(improvementType),
            GroupLabelKey = improvementInfo.Name,
            Validate = function(item, validateContext)
                local validatePlot = Map.GetPlotByIndex(item.PlotIndex)
                if validatePlot == nil or not Utils.IsPlotRevealed(validateContext, validatePlot) then
                    return false
                end

                local validateImprovement = validatePlot:GetImprovementType()
                local validateInfo = validateImprovement ~= nil and GameInfo.Improvements[validateImprovement] or nil
                return validateInfo ~= nil and validateInfo.Goody and validateInfo.ImprovementType == improvementType
            end,
        })
    end
end

CAIWorldScanner:RegisterCategoryDefinition(CAIWorldScannerCategory_SpecialMapObjects)
