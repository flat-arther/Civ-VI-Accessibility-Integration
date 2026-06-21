local Utils = CAIWorldScannerUtils

local subCategoryLabels = {
    my = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_MY",
    myPillaged = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_MY_PILLAGED",
    neutral = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_NEUTRAL",
    enemy = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_ENEMY",
}

CAIWorldScannerCategory_Improvements = {
    Id = "improvements",
    LabelKey = "LOC_CAI_WORLD_SCANNER_CATEGORY_IMPROVEMENTS",
    SubCategoryOrder = { "my", "myPillaged", "neutral", "enemy" },
    SubCategoryLabels = subCategoryLabels,
    GroupLabelResolver = function(_, firstItem)
        return firstItem ~= nil and firstItem.GroupLabelKey or "LOC_CAI_WORLD_SCANNER_UNKNOWN"
    end,
}

local function GetPlotStanceKey(context, plot)
    local ownerID = plot:GetOwner()
    local stance = Utils.GetTeamStance(context, ownerID)
    if stance == "my" and (plot:IsImprovementPillaged() or plot:IsRoutePillaged()) then
        return "myPillaged"
    end

    return stance
end

function CAIWorldScannerCategory_Improvements.PlotExtract(plotIndex, plot, context, collect)
    local stanceKey = GetPlotStanceKey(context, plot)

    local improvementIndex = plot:GetImprovementType()
    local improvementInfo = improvementIndex ~= nil and GameInfo.Improvements[improvementIndex] or nil
    if improvementInfo ~= nil
        and not improvementInfo.BarbarianCamp
        and not improvementInfo.Goody then
        collect({
            Id = "improvement:" .. tostring(plotIndex),
            PlotIndex = plotIndex,
            LabelKey = improvementInfo.Name,
            SubCategoryId = stanceKey,
            GroupId = "improvement:" .. improvementInfo.ImprovementType,
            GroupLabelKey = improvementInfo.Name,
            Validate = function(item, validateContext)
                local validatePlot = Map.GetPlotByIndex(item.PlotIndex)
                if validatePlot == nil or not Utils.IsPlotRevealed(validateContext, validatePlot) then
                    return false
                end

                local validateIndex = validatePlot:GetImprovementType()
                local validateInfo = validateIndex ~= nil and GameInfo.Improvements[validateIndex] or nil
                return validateInfo ~= nil
                    and validateInfo.ImprovementType == improvementInfo.ImprovementType
                    and GetPlotStanceKey(validateContext, validatePlot) == item.SubCategoryId
            end,
        })
    end

    if plot:IsRoute() then
        local routeType = plot:GetRouteType()
        local routeInfo = routeType ~= nil and GameInfo.Routes[routeType] or nil
        if routeInfo ~= nil then
            collect({
                Id = "route:" .. tostring(plotIndex),
                PlotIndex = plotIndex,
                LabelKey = routeInfo.Name,
                SubCategoryId = stanceKey,
                GroupId = "route:" .. tostring(routeType),
                GroupLabelKey = routeInfo.Name,
                Validate = function(item, validateContext)
                    local validatePlot = Map.GetPlotByIndex(item.PlotIndex)
                    if validatePlot == nil or not Utils.IsPlotRevealed(validateContext, validatePlot) then
                        return false
                    end

                    return validatePlot:IsRoute()
                        and validatePlot:GetRouteType() == routeType
                        and GetPlotStanceKey(validateContext, validatePlot) == item.SubCategoryId
                end,
            })
        end
    end
end

CAIWorldScanner:RegisterCategoryDefinition(CAIWorldScannerCategory_Improvements)
