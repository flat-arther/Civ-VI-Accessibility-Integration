local Utils = CAIWorldScannerUtils

local subCategoryLabels = {
    my = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_MY",
    cityStates = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_CITY_STATES",
    neutral = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_NEUTRAL",
    enemy = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_ENEMY",
    barbarianCamps = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_BARBARIAN_OUTPOSTS",
}

local m_seenCities = {}

local function IsCityState(ownerID)
    local player = Players[ownerID]
    if player == nil then
        return false
    end

    local influence = player:GetInfluence()
    return influence ~= nil and influence.CanReceiveInfluence ~= nil and influence:CanReceiveInfluence()
end

CAIWorldScannerCategory_Cities = {
    Id = "cities",
    LabelKey = "LOC_CAI_WORLD_SCANNER_CATEGORY_CITIES",
    SubCategoryOrder = { "my", "cityStates", "neutral", "enemy", "barbarianCamps" },
    SubCategoryLabels = subCategoryLabels,
    GroupLabelResolver = function(groupId, firstItem)
        if groupId == "IMPROVEMENT_BARBARIAN_CAMP" then
            return "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_BARBARIAN_OUTPOSTS"
        end
        if firstItem == nil then
            return "LOC_CAI_WORLD_SCANNER_UNKNOWN"
        end
        if CAISettings.GetBool("ScannerGroupCitiesByCivilization") then
            return Utils.GetPlayerLabel(firstItem.OwnerID)
        end
        return firstItem.LabelKey
    end,
}

function CAIWorldScannerCategory_Cities.PlotExtract(plotIndex, plot, context, collect)
    local improvementIndex = plot:GetImprovementType()
    local improvementInfo = improvementIndex ~= nil and GameInfo.Improvements[improvementIndex] or nil
    if improvementInfo ~= nil and improvementInfo.ImprovementType == "IMPROVEMENT_BARBARIAN_CAMP" then
        collect({
            Id = "barbarianCamp:" .. tostring(plotIndex),
            PlotIndex = plotIndex,
            LabelKey = improvementInfo.Name,
            SubCategoryId = "barbarianCamps",
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
        })
        return
    end

    local city = Cities.GetCityInPlot(plot:GetX(), plot:GetY())
    if city == nil or city:GetX() ~= plot:GetX() or city:GetY() ~= plot:GetY() then
        return
    end

    local ownerID = city:GetOwner()
    if not Utils.CanKnowPlayer(context, ownerID) then
        return
    end

    local cityID = city:GetID()
    local uniqueKey = tostring(ownerID) .. ":" .. tostring(cityID)
    if m_seenCities[uniqueKey] then
        return
    end

    m_seenCities[uniqueKey] = true
    local subCategoryId
    if IsCityState(ownerID) then
        subCategoryId = "cityStates"
    else
        subCategoryId = Utils.GetTeamStance(context, ownerID)
    end

    collect({
        Id = "city:" .. uniqueKey,
        PlotIndex = plotIndex,
        LabelKey = Utils.GetCityLabel(city),
        SubCategoryId = subCategoryId,
        GroupId = CAISettings.GetBool("ScannerGroupCitiesByCivilization")
            and "player:" .. tostring(ownerID)
            or "city:" .. uniqueKey,
        OwnerID = ownerID,
        Validate = function(item, validateContext)
            local validatePlot = Map.GetPlotByIndex(item.PlotIndex)
            if validatePlot == nil or not Utils.IsPlotRevealed(validateContext, validatePlot) then
                return false
            end

            local validateCity = Cities.GetCityInPlot(validatePlot:GetX(), validatePlot:GetY())
            if validateCity == nil or validateCity:GetOwner() ~= ownerID or validateCity:GetID() ~= cityID then
                return false
            end

            if not Utils.CanKnowPlayer(validateContext, ownerID) then
                return false
            end

            local validateSubCategory
            if IsCityState(ownerID) then
                validateSubCategory = "cityStates"
            else
                validateSubCategory = Utils.GetTeamStance(validateContext, ownerID)
            end
            return validateSubCategory == item.SubCategoryId
        end,
    })
end

function CAIWorldScannerCategory_Cities.BeginExtract()
    m_seenCities = {}
end

CAIWorldScanner:RegisterCategoryDefinition(CAIWorldScannerCategory_Cities)
