local Utils = CAIWorldScannerUtils

CAIWorldScannerCategory_Resources = {
    Id = "resources",
    LabelKey = "LOC_CAI_WORLD_SCANNER_CATEGORY_RESOURCES",
    SubCategoryOrder = {
        "RESOURCECLASS_BONUS",
        "RESOURCECLASS_LUXURY",
        "RESOURCECLASS_STRATEGIC",
        "RESOURCECLASS_ARTIFACT",
    },
    SubCategoryLabels = {
        RESOURCECLASS_BONUS = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_BONUS",
        RESOURCECLASS_LUXURY = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_LUXURY",
        RESOURCECLASS_STRATEGIC = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_STRATEGIC",
        RESOURCECLASS_ARTIFACT = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_ARTIFACT",
    },
    GroupLabelResolver = function(_, firstItem)
        return firstItem ~= nil and firstItem.GroupLabelKey or "LOC_CAI_WORLD_SCANNER_UNKNOWN"
    end,
}

function CAIWorldScannerCategory_Resources.Scan(context)
    local out = {}
    local playerResources = Utils.GetPlayerResources(context)

    Utils.ForEachRevealedPlot(context, function(plotIndex, plot)
        local resourceIndex = plot:GetResourceType()
        local resourceInfo = resourceIndex ~= nil and GameInfo.Resources[resourceIndex] or nil
        if resourceInfo == nil or playerResources == nil or not playerResources:IsResourceVisible(resourceInfo.Hash) then
            return
        end

        out[#out + 1] = {
            Id = "resource:" .. tostring(plotIndex),
            PlotIndex = plotIndex,
            LabelKey = resourceInfo.Name,
            SubCategoryId = resourceInfo.ResourceClassType,
            GroupId = tostring(resourceInfo.ResourceType),
            GroupLabelKey = resourceInfo.Name,
            Validate = function(item, validateContext)
                local validatePlot = Map.GetPlotByIndex(item.PlotIndex)
                if validatePlot == nil or not Utils.IsPlotRevealed(validateContext, validatePlot) then
                    return false
                end

                local validateIndex = validatePlot:GetResourceType()
                local validateInfo = validateIndex ~= nil and GameInfo.Resources[validateIndex] or nil
                local validateResources = Utils.GetPlayerResources(validateContext)
                return validateInfo ~= nil
                    and validateInfo.ResourceType == resourceInfo.ResourceType
                    and validateResources ~= nil
                    and validateResources:IsResourceVisible(validateInfo.Hash)
            end,
        }
    end)

    return out
end

CAIWorldScanner:RegisterCategoryDefinition(CAIWorldScannerCategory_Resources)
