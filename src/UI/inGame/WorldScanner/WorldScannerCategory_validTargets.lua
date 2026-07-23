include("interfaceTargetHelpers_CAI")

local SUBCATEGORY_TARGET_PLOTS = "targetPlots"

CAIWorldScannerCategory_ValidTargets = {
    Id = "validTargets",
    LabelKey = "LOC_CAI_WORLD_SCANNER_CATEGORY_VALID_TARGETS",
    Contextual = true,
    ManagementSettings = { "ScannerAutoFocusValidTargets" },
    BuildOncePerDynamicState = true,
    AutoFocus = true,
    SubCategoryOrder = { SUBCATEGORY_TARGET_PLOTS },
    SubCategoryLabels = {
        [SUBCATEGORY_TARGET_PLOTS] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_TARGET_PLOTS",
    },
    GroupLabelResolver = function()
        return "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_TARGET_PLOTS"
    end,
    CanScan = function()
        if CAIInterfaceTargets == nil then return false end
        if CAIInterfaceTargets.IsSupportedMode ~= nil and CAIInterfaceTargets.IsSupportedMode() then
            return true
        end
        if CAIInterfaceTargets.GetSelectedUnitActionPlots ~= nil then
            return #CAIInterfaceTargets.GetSelectedUnitActionPlots() > 0
        end
        return false
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
        out[#out + 1] = target
    end

    if CAIInterfaceTargets.GetSelectedUnitActionPlots ~= nil then
        local actionPlots = CAIInterfaceTargets.GetSelectedUnitActionPlots()
        for _, action in ipairs(actionPlots) do
            local label = "LOC_CAI_WORLD_SCANNER_UNKNOWN"

            if ExposedMembers.CAIInfo ~= nil and ExposedMembers.CAIInfo.RequestPlotInfo ~= nil then
                local requestedKeys = { "units", "cityName", "districtTitle", "improvement", "resource", "feature",
                    "plotName" }
                local results = ExposedMembers.CAIInfo:RequestPlotInfo(action.PlotIndex, requestedKeys)
                if results ~= nil and #results > 0 then
                    label = table.concat(results, ", ")
                end
            end

            table.insert(out, {
                Id            = "validTarget:action:" .. action.Type .. ":" .. tostring(action.PlotIndex),
                Kind          = "plot",
                PlotIndex     = action.PlotIndex,
                LabelKey      = label,
                SubCategoryId = SUBCATEGORY_TARGET_PLOTS,
                GroupId       = action.Type
            })
        end
    end
    return out
end

CAIWorldScanner:RegisterCategoryDefinition(CAIWorldScannerCategory_ValidTargets)
