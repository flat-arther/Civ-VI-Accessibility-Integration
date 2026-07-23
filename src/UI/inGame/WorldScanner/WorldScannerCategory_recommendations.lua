local Utils = CAIWorldScannerUtils

local SUBCATEGORY_BUILDER = "builder"
local SUBCATEGORY_SETTLER = "settler"

CAIWorldScannerCategory_Recommendations = {
    Id = "recommendations",
    LabelKey = "LOC_CAI_WORLD_SCANNER_CATEGORY_RECOMMENDATIONS",
    Contextual = true,
    ManagementSettings = { "ScannerAutoFocusRecommendations" },
    AutoFocus = true,
    SubCategoryOrder = { SUBCATEGORY_BUILDER, SUBCATEGORY_SETTLER },
    SubCategoryLabels = {
        [SUBCATEGORY_BUILDER] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_BUILDER_RECOMMENDATIONS",
        [SUBCATEGORY_SETTLER] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_SETTLER_RECOMMENDATIONS",
    },
    GroupLabelResolver = function(_, firstItem)
        return firstItem ~= nil and firstItem.GroupLabelKey or "LOC_CAI_WORLD_SCANNER_UNKNOWN"
    end,
    CanScan = function()
        return CAIRecommendationLogic.HasRecommendations()
    end,
}

function CAIWorldScannerCategory_Recommendations.Scan(context)
    local out = {}

    for plotIndex, rec in pairs(CAIRecommendationLogic.GetImprovementRecommendations()) do
        local plot = Map.GetPlotByIndex(plotIndex)
        if plot ~= nil and Utils.IsPlotRevealed(context, plot) then
            out[#out + 1] = {
                Id = "recommendation:builder:" .. tostring(plotIndex),
                PlotIndex = plotIndex,
                LabelKey = rec.Label,
                SubCategoryId = SUBCATEGORY_BUILDER,
                GroupId = rec.GroupId,
                GroupLabelKey = rec.GroupLabel,
            }
        end
    end

    for plotIndex, rec in pairs(CAIRecommendationLogic.GetSettlementRecommendations()) do
        local plot = Map.GetPlotByIndex(plotIndex)
        if plot ~= nil and Utils.IsPlotRevealed(context, plot) then
            out[#out + 1] = {
                Id = "recommendation:settler:" .. tostring(plotIndex),
                PlotIndex = plotIndex,
                LabelKey = "LOC_CAI_WORLD_SCANNER_RECOMMENDED_SETTLEMENT",
                SubCategoryId = SUBCATEGORY_SETTLER,
                GroupId = "settlement",
                GroupLabelKey = "LOC_CAI_WORLD_SCANNER_RECOMMENDED_SETTLEMENT",
            }
        end
    end

    return out
end

CAIWorldScanner:RegisterCategoryDefinition(CAIWorldScannerCategory_Recommendations)
