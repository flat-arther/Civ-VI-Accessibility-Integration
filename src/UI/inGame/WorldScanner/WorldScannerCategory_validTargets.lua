include("interfaceTargetHelpers_CAI")

local SUBCATEGORY_TARGET_PLOTS = "targetPlots"
local GROUP_TARGET_PLOTS = "targetPlots"

CAIWorldScannerCategory_ValidTargets = {
    Id = "validTargets",
    LabelKey = "LOC_CAI_WORLD_SCANNER_CATEGORY_VALID_TARGETS",
    BuildOncePerDynamicState = true,
    SubCategoryOrder = { SUBCATEGORY_TARGET_PLOTS },
    SubCategoryLabels = {
        [SUBCATEGORY_TARGET_PLOTS] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_TARGET_PLOTS",
    },
    GroupLabelResolver = function()
        return "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_TARGET_PLOTS"
    end,
    CanScan = function()
        return CAIInterfaceTargets ~= nil
            and CAIInterfaceTargets.IsSupportedMode ~= nil
            and CAIInterfaceTargets.IsSupportedMode()
    end,
}

function CAIWorldScannerCategory_ValidTargets.Scan(context)
    local out = {}
    if CAIInterfaceTargets == nil or CAIInterfaceTargets.GetActiveTargetItems == nil then
        return out
    end

    local targets = CAIInterfaceTargets.GetActiveTargetItems()
    for _, target in ipairs(targets) do
        target.SubCategoryId = SUBCATEGORY_TARGET_PLOTS
        target.GroupId = GROUP_TARGET_PLOTS
        out[#out + 1] = target
    end

    return out
end

CAIWorldScanner:RegisterCategoryDefinition(CAIWorldScannerCategory_ValidTargets)
