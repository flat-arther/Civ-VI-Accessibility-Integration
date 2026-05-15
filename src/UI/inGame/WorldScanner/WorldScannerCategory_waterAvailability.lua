local Utils = CAIWorldScannerUtils

local WATER_LAYER = UILens.CreateLensLayerHash("Hex_Coloring_Water_Availablity")
local SUBCATEGORY_VALID = "LOC_HUD_UNIT_PANEL_TOOLTIP_VALID_LOCATION"
local SUBCATEGORY_FRESH = "LOC_HUD_UNIT_PANEL_TOOLTIP_FRESH_WATER"
local SUBCATEGORY_COASTAL = "LOC_HUD_UNIT_PANEL_TOOLTIP_COASTAL_WATER"
local SUBCATEGORY_NO_WATER = "LOC_HUD_UNIT_PANEL_TOOLTIP_NO_WATER"
local SUBCATEGORY_BLOCKED = "LOC_HUD_UNIT_PANEL_TOOLTIP_TOO_CLOSE_TO_CITY"
local MAYA_CIVILIZATION_TYPE = "CIVILIZATION_MAYA"

local subCategoryLabels = {
    [SUBCATEGORY_VALID] = SUBCATEGORY_VALID,
    [SUBCATEGORY_FRESH] = SUBCATEGORY_FRESH,
    [SUBCATEGORY_COASTAL] = SUBCATEGORY_COASTAL,
    [SUBCATEGORY_NO_WATER] = SUBCATEGORY_NO_WATER,
    [SUBCATEGORY_BLOCKED] = SUBCATEGORY_BLOCKED,
}

CAIWorldScannerCategory_WaterAvailability = {
    Id = "waterAvailability",
    LabelKey = "LOC_CAI_WORLD_SCANNER_CATEGORY_WATER_AVAILABILITY",
    SubCategoryOrder = {
        SUBCATEGORY_VALID,
        SUBCATEGORY_FRESH,
        SUBCATEGORY_COASTAL,
        SUBCATEGORY_NO_WATER,
        SUBCATEGORY_BLOCKED,
    },
    SubCategoryLabels = subCategoryLabels,
    GroupLabelResolver = function(_, firstItem)
        return firstItem ~= nil and firstItem.GroupLabelKey or "LOC_CAI_WORLD_SCANNER_UNKNOWN"
    end,
}

local function IsWaterLensVisible()
    return UILens.IsLayerOn ~= nil and UILens.IsLayerOn(WATER_LAYER)
end

local function IsLocalPlayerMaya(context)
    local playerID = Utils.GetLocalPlayerID(context)
    if playerID == nil or playerID < 0 then
        return false
    end

    local config = PlayerConfigurations[playerID]
    return config ~= nil and config:GetCivilizationTypeName() == MAYA_CIVILIZATION_TYPE
end

local function AddPlotList(out, context, plotList, subCategoryId)
    if plotList == nil then
        return
    end

    for _, plotIndex in ipairs(plotList) do
        local plot = Map.GetPlotByIndex(plotIndex)
        if plot ~= nil and Utils.IsPlotRevealed(context, plot) then
            out[#out + 1] = {
                Id = "waterAvailability:" .. tostring(subCategoryId) .. ":" .. tostring(plotIndex),
                PlotIndex = plotIndex,
                LabelKey = subCategoryId,
                SubCategoryId = subCategoryId,
                GroupId = subCategoryId,
                GroupLabelKey = subCategoryId,
            }
        end
    end
end

function CAIWorldScannerCategory_WaterAvailability.Scan(context)
    if not IsWaterLensVisible() then
        return {}
    end

    local out = {}
    local fullWaterPlots, coastalWaterPlots, noWaterPlots, noSettlePlots = Map.GetContinentPlotsWaterAvailability()

    if IsLocalPlayerMaya(context) then
        AddPlotList(out, context, fullWaterPlots, SUBCATEGORY_VALID)
        AddPlotList(out, context, coastalWaterPlots, SUBCATEGORY_VALID)
        AddPlotList(out, context, noWaterPlots, SUBCATEGORY_VALID)
    else
        AddPlotList(out, context, fullWaterPlots, SUBCATEGORY_FRESH)
        AddPlotList(out, context, coastalWaterPlots, SUBCATEGORY_COASTAL)
        AddPlotList(out, context, noWaterPlots, SUBCATEGORY_NO_WATER)
    end

    AddPlotList(out, context, noSettlePlots, SUBCATEGORY_BLOCKED)
    return out
end

CAIWorldScanner:RegisterCategoryDefinition(CAIWorldScannerCategory_WaterAvailability)
