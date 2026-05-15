local Utils = CAIWorldScannerUtils

CAIWorldScannerCategory_BarbarianCamps = {
    Id = "barbarianCamps",
    LabelKey = "LOC_CAI_WORLD_SCANNER_CATEGORY_BARBARIAN_CAMPS",
    SubCategoryOrder = { "camps" },
    SubCategoryLabels = {
        camps = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_CAMPS",
    },
}

function CAIWorldScannerCategory_BarbarianCamps.Scan(context)
    local out = {}

    Utils.ForEachRevealedPlot(context, function(plotIndex, plot)
        local improvementIndex = plot:GetImprovementType()
        local improvementInfo = improvementIndex ~= nil and GameInfo.Improvements[improvementIndex] or nil
        if improvementInfo == nil or improvementInfo.ImprovementType ~= "IMPROVEMENT_BARBARIAN_CAMP" then
            return
        end

        out[#out + 1] = {
            Id = "barbarianCamp:" .. tostring(plotIndex),
            PlotIndex = plotIndex,
            LabelKey = improvementInfo.Name,
            SubCategoryId = "camps",
            GroupId = improvementInfo.ImprovementType,
            Validate = function(item, validateContext)
                local validatePlot = Map.GetPlotByIndex(item.PlotIndex)
                if validatePlot == nil or not Utils.IsPlotRevealed(validateContext, validatePlot) then
                    return false
                end

                local validateImprovement = validatePlot:GetImprovementType()
                local validateInfo = validateImprovement ~= nil and GameInfo.Improvements[validateImprovement] or nil
                return validateInfo ~= nil and validateInfo.ImprovementType == "IMPROVEMENT_BARBARIAN_CAMP"
            end,
        }
    end)

    return out
end

CAIWorldScanner:RegisterCategoryDefinition(CAIWorldScannerCategory_BarbarianCamps)
