local Utils = CAIWorldScannerUtils

local subCategoryLabels = {
    my = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_MY",
    neutral = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_NEUTRAL",
    enemy = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_ENEMY",
}

CAIWorldScannerCategory_Wonders = {
    Id = "wonders",
    LabelKey = "LOC_CAI_WORLD_SCANNER_CATEGORY_WONDERS",
    SubCategoryOrder = { "my", "neutral", "enemy" },
    SubCategoryLabels = subCategoryLabels,
    GroupLabelResolver = function(_, firstItem)
        return firstItem ~= nil and firstItem.GroupLabelKey or "LOC_CAI_WORLD_SCANNER_UNKNOWN"
    end,
}

function CAIWorldScannerCategory_Wonders.PlotExtract(plotIndex, plot, context, collect)
    local wonderType = plot:GetWonderType()
    if wonderType == nil or wonderType < 0 then
        return
    end

    local wonderInfo = GameInfo.Buildings[wonderType]
    if wonderInfo == nil then
        return
    end

    local ownerID = plot:GetOwner()
    local stanceKey = Utils.GetTeamStance(context, ownerID)

    collect({
        Id = "wonder:" .. tostring(plotIndex),
        PlotIndex = plotIndex,
        LabelKey = wonderInfo.Name,
        SubCategoryId = stanceKey,
        GroupId = "wonder:" .. wonderInfo.BuildingType,
        GroupLabelKey = wonderInfo.Name,
        Validate = function(item, validateContext)
            local validatePlot = Map.GetPlotByIndex(item.PlotIndex)
            if validatePlot == nil or not Utils.IsPlotRevealed(validateContext, validatePlot) then
                return false
            end

            local validateType = validatePlot:GetWonderType()
            local validateInfo = validateType ~= nil and validateType >= 0
                and GameInfo.Buildings[validateType] or nil
            return validateInfo ~= nil
                and validateInfo.BuildingType == wonderInfo.BuildingType
                and Utils.GetTeamStance(validateContext, validatePlot:GetOwner()) == item.SubCategoryId
        end,
    })
end

CAIWorldScanner:RegisterCategoryDefinition(CAIWorldScannerCategory_Wonders)
