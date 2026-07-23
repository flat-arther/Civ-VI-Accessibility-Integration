local Utils = CAIWorldScannerUtils

local subCategoryLabels = {
    my = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_MY",
    myPillaged = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_MY_PILLAGED",
    neutral = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_NEUTRAL",
    enemy = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_ENEMY",
}

CAIWorldScannerCategory_Districts = {
    Id = "districts",
    LabelKey = "LOC_CAI_WORLD_SCANNER_CATEGORY_DISTRICTS",
    SubCategoryOrder = { "my", "myPillaged", "neutral", "enemy" },
    SubCategoryLabels = subCategoryLabels,
    GroupLabelResolver = function(_, firstItem)
        return firstItem ~= nil and firstItem.GroupLabelKey or "LOC_CAI_WORLD_SCANNER_UNKNOWN"
    end,
}

local function GetPlotStanceKey(context, plot, isPillaged)
    local ownerID = plot:GetOwner()
    local stance = Utils.GetTeamStance(context, ownerID)
    if stance == "my" and isPillaged then
        return "myPillaged"
    end

    return stance
end

function CAIWorldScannerCategory_Districts.PlotExtract(plotIndex, plot, context, collect)
    CAIWorldScannerCategory_Wonders.PlotExtract(plotIndex, plot, context, collect)

    local districtType = plot:GetDistrictType()
    if districtType == nil or districtType < 0 then
        return
    end

    local districtInfo = GameInfo.Districts[districtType]
    if districtInfo == nil then
        return
    end

    if districtInfo.InternalOnly or districtInfo.DistrictType == "DISTRICT_CITY_CENTER" then
        return
    end

    local isPillaged = false
    local ownerCity = Cities.GetPlotPurchaseCity(plot)
    if ownerCity ~= nil then
        local cityDistricts = ownerCity:GetDistricts()
        if cityDistricts ~= nil then
            isPillaged = cityDistricts:IsPillaged(districtType, plotIndex)
        end
    end

    local stanceKey = GetPlotStanceKey(context, plot, isPillaged)

    collect({
        Id = "district:" .. tostring(plotIndex),
        PlotIndex = plotIndex,
        LabelKey = districtInfo.Name,
        SubCategoryId = stanceKey,
        GroupId = "district:" .. districtInfo.DistrictType,
        GroupLabelKey = districtInfo.Name,
        Validate = function(item, validateContext)
            local validatePlot = Map.GetPlotByIndex(item.PlotIndex)
            if validatePlot == nil or not Utils.IsPlotRevealed(validateContext, validatePlot) then
                return false
            end

            local validateType = validatePlot:GetDistrictType()
            local validateInfo = validateType ~= nil and validateType >= 0
                and GameInfo.Districts[validateType] or nil
            if validateInfo == nil then
                return false
            end

            local validatePillaged = false
            local validateCity = Cities.GetPlotPurchaseCity(validatePlot)
            if validateCity ~= nil then
                local validateCityDistricts = validateCity:GetDistricts()
                if validateCityDistricts ~= nil then
                    validatePillaged = validateCityDistricts:IsPillaged(validateType, item.PlotIndex)
                end
            end

            return validateInfo.DistrictType == districtInfo.DistrictType
                and GetPlotStanceKey(validateContext, validatePlot, validatePillaged) == item.SubCategoryId
        end,
    })
end

CAIWorldScanner:RegisterCategoryDefinition(CAIWorldScannerCategory_Districts)
