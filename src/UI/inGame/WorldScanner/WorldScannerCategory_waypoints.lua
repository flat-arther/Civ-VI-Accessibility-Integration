local SUBCATEGORY_FULL_PATH = "fullPath"
local SUBCATEGORY_WAYPOINTS = "waypoints"
local GROUP_FULL_PATH = "fullPath"
local GROUP_WAYPOINTS = "waypoints"

local function BuildQueuedPathScannerLabel(plotIndex)
    local info = ExposedMembers.CAIInfo
    if info == nil or info.RequestPlotInfo == nil then
        return "LOC_CAI_WORLD_SCANNER_UNKNOWN"
    end

    local parts = info:RequestPlotInfo(nil, {
        "waypoint",
        "plotName",
        "feature",
        "cityName",
        "districtTitle",
        "cityDistrictTitle",
    }, plotIndex)

    if parts == nil or #parts == 0 then
        return "LOC_CAI_WORLD_SCANNER_UNKNOWN"
    end

    return table.concat(parts, ", ")
end

local function BuildFullPathItem(entry, index)
    return {
        Id = "queuedPath:full:" .. tostring(index) .. ":" .. tostring(entry.PlotId),
        PlotIndex = entry.PlotId,
        LabelKey = BuildQueuedPathScannerLabel(entry.PlotId),
        SubCategoryId = SUBCATEGORY_FULL_PATH,
        GroupId = GROUP_FULL_PATH,
        Validate = function(item)
            local liveInfo = ExposedMembers.CAIInfo
            return liveInfo ~= nil
                and liveInfo.IsQueuedPathPlot ~= nil
                and liveInfo:IsQueuedPathPlot(item.PlotIndex)
        end,
    }
end

local function BuildWaypointItem(entry, index)
    return {
        Id = "queuedPath:waypoint:" .. tostring(index) .. ":" .. tostring(entry.PlotId),
        PlotIndex = entry.PlotId,
        LabelKey = BuildQueuedPathScannerLabel(entry.PlotId),
        SubCategoryId = SUBCATEGORY_WAYPOINTS,
        GroupId = GROUP_WAYPOINTS,
        Validate = function(item)
            local liveInfo = ExposedMembers.CAIInfo
            return liveInfo ~= nil
                and liveInfo.IsWaypointPlot ~= nil
                and liveInfo:IsWaypointPlot(item.PlotIndex)
        end,
    }
end

CAIWorldScannerCategory_Waypoints = {
    Id = "queuedPath",
    LabelKey = "LOC_CAI_WORLD_SCANNER_CATEGORY_QUEUED_PATH",
    BuildOncePerDynamicState = true,
    AutoFocus = false,
    SubCategoryOrder = { SUBCATEGORY_FULL_PATH, SUBCATEGORY_WAYPOINTS },
    SubCategoryLabels = {
        [SUBCATEGORY_FULL_PATH] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_FULL_PATH",
        [SUBCATEGORY_WAYPOINTS] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_WAYPOINTS",
    },
    GroupLabelResolver = function(groupId)
        if groupId == GROUP_WAYPOINTS then
            return "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_WAYPOINTS"
        end
        return "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_FULL_PATH"
    end,
    CanScan = function()
        local info = ExposedMembers.CAIInfo
        if info == nil or info.GetQueuedPath == nil then
            return false
        end

        local queuedPath = info:GetQueuedPath()
        return queuedPath ~= nil and #queuedPath > 1
    end,
}

function CAIWorldScannerCategory_Waypoints.Scan(context)
    local out = {}
    local info = ExposedMembers.CAIInfo
    if info == nil or info.GetQueuedPath == nil then
        return out
    end

    local queuedPath = info:GetQueuedPath()
    for index, entry in ipairs(queuedPath) do
        if index > 1 and entry ~= nil and entry.PlotId ~= nil and Map.IsPlot(entry.PlotId) then
            out[#out + 1] = BuildFullPathItem(entry, index)
            if entry.IsWaypoint or index == #queuedPath then
                out[#out + 1] = BuildWaypointItem(entry, index)
            end
        end
    end

    return out
end

CAIWorldScanner:RegisterCategoryDefinition(CAIWorldScannerCategory_Waypoints)
