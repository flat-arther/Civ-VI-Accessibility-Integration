local Utils = CAIWorldScannerUtils

local subCategoryLabels = {
    my = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_MY",
    neutral = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_NEUTRAL",
    enemy = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_ENEMY",
}

CAIWorldScannerCategory_Cities = {
    Id = "cities",
    LabelKey = "LOC_CAI_WORLD_SCANNER_CATEGORY_CITIES",
    SubCategoryOrder = { "my", "neutral", "enemy" },
    SubCategoryLabels = subCategoryLabels,
    GroupLabelResolver = function(_, firstItem)
        return firstItem ~= nil and Utils.GetPlayerLabel(firstItem.OwnerID) or "LOC_CAI_WORLD_SCANNER_UNKNOWN"
    end,
}

function CAIWorldScannerCategory_Cities.Scan(context)
    local out = {}
    local seen = {}

    Utils.ForEachRevealedPlot(context, function(plotIndex, plot)
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
        if seen[uniqueKey] then
            return
        end

        seen[uniqueKey] = true
        out[#out + 1] = {
            Id = "city:" .. uniqueKey,
            PlotIndex = plotIndex,
            LabelKey = Utils.GetCityLabel(city),
            SubCategoryId = Utils.GetTeamStance(context, ownerID),
            GroupId = "player:" .. tostring(ownerID),
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

                return Utils.CanKnowPlayer(validateContext, ownerID)
                    and Utils.GetTeamStance(validateContext, ownerID) == item.SubCategoryId
            end,
        }
    end)

    return out
end

CAIWorldScanner:RegisterCategoryDefinition(CAIWorldScannerCategory_Cities)
