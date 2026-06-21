include("cityManagementInterfaceHelpers_CAI")

local SUBCATEGORY_ORDER = {
    "locked",
    "specialists",
    "worked",
    "available",
    "swappable",
    "purchasable",
    "tooExpensive",
}

CAIWorldScannerCategory_CityManagement = {
    Id = "cityManagement",
    LabelKey = "LOC_CAI_WORLD_SCANNER_CATEGORY_CITY_MANAGEMENT",
    AutoFocus = true,
    SubCategoryOrder = SUBCATEGORY_ORDER,
    SubCategoryLabels = {
        locked = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_CITY_MANAGEMENT_LOCKED",
        specialists = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_CITY_MANAGEMENT_SPECIALISTS",
        worked = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_CITY_MANAGEMENT_WORKED",
        available = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_CITY_MANAGEMENT_AVAILABLE",
        swappable = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_CITY_MANAGEMENT_SWAPPABLE",
        purchasable = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_CITY_MANAGEMENT_PURCHASABLE",
        tooExpensive = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_CITY_MANAGEMENT_TOO_EXPENSIVE",
    },
    GroupLabelResolver = function(groupId)
        return CAIWorldScannerCategory_CityManagement.SubCategoryLabels[groupId]
            or "LOC_CAI_WORLD_SCANNER_UNKNOWN"
    end,
    CanScan = function()
        return CAICityManagementInterface ~= nil
            and CAICityManagementInterface.IsActive ~= nil
            and CAICityManagementInterface.IsActive()
    end,
}

function CAIWorldScannerCategory_CityManagement.Scan(context)
    local out = {}
    if CAICityManagementInterface == nil
        or CAICityManagementInterface.GetStateData == nil
        or CAICityManagementInterface.BuildSpeechText == nil
        or CAICityManagementInterface.GetScannerSubCategoryId == nil then
        return out
    end

    local stateData = CAICityManagementInterface.GetStateData()
    if stateData == nil then
        return out
    end

    for plotId in pairs(stateData.ActivePlots or {}) do
        local subCategoryId = CAICityManagementInterface.GetScannerSubCategoryId(plotId, stateData)
        local label = CAICityManagementInterface.BuildSpeechText(plotId, stateData)
        if subCategoryId ~= nil and label ~= nil and label ~= "" then
            out[#out + 1] = {
                Id = "cityManagement:" .. tostring(plotId),
                PlotIndex = plotId,
                LabelKey = label,
                SubCategoryId = subCategoryId,
                GroupId = subCategoryId,
                Validate = function(item)
                    if CAICityManagementInterface == nil
                        or CAICityManagementInterface.IsActive == nil
                        or not CAICityManagementInterface.IsActive() then
                        return false
                    end

                    local validateStateData = CAICityManagementInterface.GetStateData()
                    if validateStateData == nil then
                        return false
                    end

                    local validateSubCategoryId =
                        CAICityManagementInterface.GetScannerSubCategoryId(item.PlotIndex, validateStateData)
                    return validateSubCategoryId ~= nil and validateSubCategoryId == item.SubCategoryId
                end,
            }
        end
    end

    return out
end

CAIWorldScanner:RegisterCategoryDefinition(CAIWorldScannerCategory_CityManagement)
