include("cityManagementInterfaceHelpers_CAI")

-- Scanner category: every workable tile of the head-selected city, grouped by
-- yield type and ranked within each type. It answers "what is my best food /
-- production / gold tile". Only active while citizen management is open (the
-- same context that drives the city management category), and it sits right
-- after that category by default.
--
-- Shape mirrors the Civ V access mod's yields backend: each tile fans out into
-- one row per non-zero yield, so a tile appears under every yield it produces,
-- and each yield group is sorted by that yield descending (SortValue). The
-- groups are the yield types (like the city management category groups by tile
-- status), so cycling groups walks Food, Production, Gold, and so on.

-- Yield reading order, plus the group/subcategory label shown for each.
local YIELD_SUBS = {
    { Sub = "food",       YieldType = "YIELD_FOOD",       Label = "LOC_YIELD_FOOD_NAME" },
    { Sub = "production", YieldType = "YIELD_PRODUCTION", Label = "LOC_YIELD_PRODUCTION_NAME" },
    { Sub = "gold",       YieldType = "YIELD_GOLD",       Label = "LOC_YIELD_GOLD_NAME" },
    { Sub = "science",    YieldType = "YIELD_SCIENCE",    Label = "LOC_YIELD_SCIENCE_NAME" },
    { Sub = "culture",    YieldType = "YIELD_CULTURE",    Label = "LOC_YIELD_CULTURE_NAME" },
    { Sub = "faith",      YieldType = "YIELD_FAITH",      Label = "LOC_YIELD_FAITH_NAME" },
}

local SUB_ORDER = {}
local SUB_LABELS = {}
local SUB_BY_YIELD = {}
for _, entry in ipairs(YIELD_SUBS) do
    SUB_ORDER[#SUB_ORDER + 1] = entry.Sub
    SUB_LABELS[entry.Sub] = entry.Label
    SUB_BY_YIELD[entry.YieldType] = entry.Sub
end

-- Keep the yield groups in reading order inside the aggregated "All"
-- subcategory (which groups by GroupId). "__all" is WorldScannerCore's
-- aggregated-subcategory id.
local ALL_SUBCATEGORY_ID = "__all"

CAIWorldScannerCategory_Yields = {
    Id = "yields",
    LabelKey = "LOC_CAI_WORLD_SCANNER_CATEGORY_YIELDS",
    Contextual = true,
    SubCategoryOrder = SUB_ORDER,
    SubCategoryLabels = SUB_LABELS,
    GroupOrderBySubCategory = {
        [ALL_SUBCATEGORY_ID] = SUB_ORDER,
    },
    GroupLabelResolver = function(groupId, firstItem)
        return SUB_LABELS[groupId]
            or (firstItem ~= nil and firstItem.LabelKey)
            or "LOC_CAI_WORLD_SCANNER_UNKNOWN"
    end,
    CanScan = function()
        return CAICityManagementInterface ~= nil
            and CAICityManagementInterface.IsCitizenManagementActive ~= nil
            and CAICityManagementInterface.IsCitizenManagementActive()
    end,
}

local function BuildValidator()
    return function(item)
        if CAICityManagementInterface == nil
            or CAICityManagementInterface.IsCitizenManagementActive == nil
            or not CAICityManagementInterface.IsCitizenManagementActive() then
            return false
        end

        local validateStateData = CAICityManagementInterface.GetStateData()
        return validateStateData ~= nil
            and validateStateData.CitizenPlots ~= nil
            and validateStateData.CitizenPlots[item.PlotIndex] ~= nil
    end
end

function CAIWorldScannerCategory_Yields.Scan(context)
    local out = {}
    if CAICityManagementInterface == nil
        or CAICityManagementInterface.GetStateData == nil
        or CAICityManagementInterface.GetPlotYields == nil
        or CAICityManagementInterface.BuildYieldSummary == nil then
        return out
    end

    local stateData = CAICityManagementInterface.GetStateData()
    if stateData == nil or stateData.CitizenPlots == nil then
        return out
    end

    for plotId in pairs(stateData.CitizenPlots) do
        local yields = CAICityManagementInterface.GetPlotYields(plotId)
        if yields ~= nil and #yields.Entries > 0 then
            -- One row per non-zero yield: the tile is filed under every yield it
            -- produces and each row is sorted within its yield group by that
            -- yield's amount (SortValue). The label leads with the group's yield,
            -- e.g. "3 production, 2 food".
            for _, entry in ipairs(yields.Entries) do
                local sub = SUB_BY_YIELD[entry.YieldType]
                if sub ~= nil then
                    out[#out + 1] = {
                        Id = "yields:" .. sub .. ":" .. tostring(plotId),
                        PlotIndex = plotId,
                        LabelKey = CAICityManagementInterface.BuildYieldSummary(plotId, entry.YieldType),
                        SubCategoryId = sub,
                        GroupId = sub,
                        SortValue = entry.Amount,
                        Validate = BuildValidator(),
                    }
                end
            end
        end
    end

    return out
end

CAIWorldScanner:RegisterCategoryDefinition(CAIWorldScannerCategory_Yields)
