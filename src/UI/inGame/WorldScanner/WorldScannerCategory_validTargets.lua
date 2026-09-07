include("interfaceTargetHelpers_CAI")

local SUBCATEGORY_TARGET_PLOTS = "targetPlots"

-- World Builder footprint groups: the plots a placement at the locked tile would
-- affect, split by whether the current tool can place there. Lets a player using
-- a large brush see exactly which covered tiles are invalid.
local GROUP_WB_VALID = "wbValid"
local GROUP_WB_INVALID = "wbInvalid"

local WB_GROUP_LABEL_KEYS = {
    [GROUP_WB_VALID] = "LOC_CAI_WORLD_SCANNER_WB_TARGET_VALID",
    [GROUP_WB_INVALID] = "LOC_CAI_WORLD_SCANNER_WB_TARGET_INVALID",
}

local function IsWorldBuilderActive()
    return WorldBuilder ~= nil
        and WorldBuilder.IsActive ~= nil
        and WorldBuilder.IsActive()
end

-- The locked World Builder placement plot, or nil when no tile is locked. The
-- source lives in the WorldInput context, the same context the scanner runs in,
-- so its global is read directly. Only a locked tile drives the footprint list.
local function WorldBuilderSourcePlot()
    if not IsWorldBuilderActive() then return nil end
    if CAIWorldBuilderScannerSourcePlot == nil then return nil end
    return CAIWorldBuilderScannerSourcePlot()
end

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
    -- Only the World Builder footprint path uses distinct groups; the valid tiles
    -- read before the invalid ones. Other modes leave GroupLabelKey unset and fall
    -- back to the single target-plots label below.
    GroupOrderBySubCategory = {
        [SUBCATEGORY_TARGET_PLOTS] = { GROUP_WB_VALID, GROUP_WB_INVALID },
    },
    GroupLabelResolver = function(_, firstItem)
        return firstItem ~= nil and firstItem.GroupLabelKey
            or "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_TARGET_PLOTS"
    end,
    CanScan = function()
        if WorldBuilderSourcePlot() ~= nil then return true end
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

-- Description of a footprint tile, using the shared plot-info bridge (the same
-- fields the action-plot targets use); falls back to bare coordinates.
local function ResolveFootprintLabel(plotIndex)
    if ExposedMembers.CAIInfo ~= nil and ExposedMembers.CAIInfo.RequestPlotInfo ~= nil then
        local requestedKeys = { "units", "cityName", "districtTitle", "improvement", "resource", "feature",
            "plotName" }
        local results = ExposedMembers.CAIInfo:RequestPlotInfo(plotIndex, requestedKeys)
        if results ~= nil and #results > 0 then
            return table.concat(results, ", ")
        end
    end

    local plot = Map.GetPlotByIndex(plotIndex)
    if plot ~= nil then
        return Locale.Lookup("LOC_CAI_VALID_TARGET_PLOT", plot:GetX(), plot:GetY())
    end
    return Locale.Lookup("LOC_CAI_WORLD_SCANNER_UNKNOWN")
end

-- Label for a footprint tile: its validity (and the locked-tile marker for the
-- locked center) prepended to the tile description, e.g. "Valid, Grassland" or
-- "Locked placement tile, Invalid, Ocean".
local function BuildFootprintLabel(target, sourcePlot)
    local parts = {}
    if target.PlotIndex == sourcePlot then
        parts[#parts + 1] = Locale.Lookup("LOC_CAI_WB_LOCKED_TILE")
    end
    parts[#parts + 1] = target.Valid
        and Locale.Lookup("LOC_CAI_PLOT_INTERFACE_VALID")
        or Locale.Lookup("LOC_CAI_PLOT_INTERFACE_INVALID")
    parts[#parts + 1] = ResolveFootprintLabel(target.PlotIndex)
    return table.concat(parts, ", ")
end

-- One item per plot the current tool's brush footprint covers at the locked tile,
-- grouped into valid and invalid tiles. The per-plot validity comes from the
-- placement context (which owns the brush and PlacementValid) via CAIInfo.
local function ScanWorldBuilderFootprint(sourcePlot)
    local out = {}
    local info = ExposedMembers.CAIInfo
    if info == nil or info.GetWorldBuilderBrushTargets == nil then return out end

    local targets = info.GetWorldBuilderBrushTargets(sourcePlot)
    if targets == nil then return out end

    for _, target in ipairs(targets) do
        local groupId = target.Valid and GROUP_WB_VALID or GROUP_WB_INVALID
        out[#out + 1] = {
            Id            = "validTarget:wb:" .. tostring(target.PlotIndex),
            Kind          = "plot",
            PlotIndex     = target.PlotIndex,
            LabelKey      = BuildFootprintLabel(target, sourcePlot),
            SubCategoryId = SUBCATEGORY_TARGET_PLOTS,
            GroupId       = groupId,
            GroupLabelKey = WB_GROUP_LABEL_KEYS[groupId],
        }
    end
    return out
end

function CAIWorldScannerCategory_ValidTargets.Scan(context)
    -- World Builder: when a tile is locked, list the placement footprint at that
    -- tile (valid and invalid) instead of the interface-mode targets below.
    local sourcePlot = WorldBuilderSourcePlot()
    if sourcePlot ~= nil then
        return ScanWorldBuilderFootprint(sourcePlot)
    end

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
