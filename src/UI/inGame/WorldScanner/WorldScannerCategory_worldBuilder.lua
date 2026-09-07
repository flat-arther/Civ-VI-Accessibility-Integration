include("Civ6Common")

-- World Builder-only scanner category. It only surfaces while the World Builder
-- is active (CanScan), and exposes two World Builder concerns:
--   * Starting positions  - each placed start plot, grouped by assignment type.
--   * Ownership            - owned plots merged into per-owner zones, the same
--                            shape as the political / owner lens.
-- (Rivers and cliffs are general terrain and live in the Geography category.)
-- Everything reads live World Builder / plot state; nothing is cached beyond the
-- single scan pass.

local Utils = CAIWorldScannerUtils
local ZoneUtils = CAIWorldScannerZoneUtils

local SUBCATEGORY_STARTS = "startingPositions"
local SUBCATEGORY_OWNERSHIP = "ownership"

local GROUP_START_PLAYER = "start:player"
local GROUP_START_LEADER = "start:leader"
local GROUP_START_CIVILIZATION = "start:civilization"
local GROUP_START_RANDOM_MAJOR = "start:randomMajor"
local GROUP_START_RANDOM_MINOR = "start:randomMinor"

local START_GROUP_LABEL_KEYS = {
    [GROUP_START_PLAYER] = "LOC_CAI_WORLD_SCANNER_WB_START_GROUP_PLAYER",
    [GROUP_START_LEADER] = "LOC_CAI_WORLD_SCANNER_WB_START_GROUP_LEADER",
    [GROUP_START_CIVILIZATION] = "LOC_CAI_WORLD_SCANNER_WB_START_GROUP_CIVILIZATION",
    [GROUP_START_RANDOM_MAJOR] = "LOC_CAI_WORLD_SCANNER_WB_START_GROUP_RANDOM_MAJOR",
    [GROUP_START_RANDOM_MINOR] = "LOC_CAI_WORLD_SCANNER_WB_START_GROUP_RANDOM_MINOR",
}

-- Every assignable World Builder start-position type. "None" is not here:
-- GetStartPositionInfo returns nil for a plot with no start.
local START_TYPE_GROUP = {
    Player = GROUP_START_PLAYER,
    Leader = GROUP_START_LEADER,
    Civilization = GROUP_START_CIVILIZATION,
    RandomMajor = GROUP_START_RANDOM_MAJOR,
    RandomMinor = GROUP_START_RANDOM_MINOR,
}

-- Vanilla type label shown before the assignee (matches the Plot Editor's
-- start-position type dropdown).
local START_TYPE_TEXT_KEYS = {
    Player = "LOC_WORLDBUILDER_PLAYER",
    Leader = "LOC_WORLDBUILDER_LEADER",
    Civilization = "LOC_WORLDBUILDER_CIVILIZATION",
    RandomMajor = "LOC_WORLDBUILDER_RANDOM_PLAYER",
    RandomMinor = "LOC_WORLDBUILDER_RANDOM_CITY_STATE",
}

local subCategoryLabels = {
    [SUBCATEGORY_STARTS] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_STARTING_POSITIONS",
    [SUBCATEGORY_OWNERSHIP] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_OWNERSHIP",
}

local m_playerManager = nil
local m_ownerBuckets = {}

local function IsWorldBuilderActive()
    return WorldBuilder ~= nil
        and WorldBuilder.IsActive ~= nil
        and WorldBuilder.IsActive()
end

CAIWorldScannerCategory_WorldBuilder = {
    Id = "worldBuilder",
    LabelKey = "LOC_CAI_WORLD_SCANNER_CATEGORY_WORLD_BUILDER",
    Contextual = true,
    -- World Builder reveals the whole map; extract every plot regardless of the
    -- observer's fog so ownership is complete.
    ExtractHiddenPlots = true,
    SubCategoryOrder = { SUBCATEGORY_STARTS, SUBCATEGORY_OWNERSHIP },
    SubCategoryLabels = subCategoryLabels,
    GroupOrderBySubCategory = {
        [SUBCATEGORY_STARTS] = {
            GROUP_START_PLAYER,
            GROUP_START_LEADER,
            GROUP_START_CIVILIZATION,
            GROUP_START_RANDOM_MAJOR,
            GROUP_START_RANDOM_MINOR,
        },
    },
    GroupLabelResolver = function(_, firstItem)
        return firstItem ~= nil and firstItem.GroupLabelKey or "LOC_CAI_WORLD_SCANNER_UNKNOWN"
    end,
    CanScan = function()
        return IsWorldBuilderActive()
    end,
}

-- Resolve the group and spoken label for a single start-position record. The
-- label is prefixed with the assignment type, e.g. "Player: Rome",
-- "Leader: Trajan", "Civilization: Rome". Random Major / Random Minor carry no
-- assignee, so their type text is the whole label. Returns nil for an
-- unrecognized type.
local function ResolveStartPosition(info)
    local groupId = START_TYPE_GROUP[info.Type]
    if groupId == nil then
        return nil, nil
    end

    local typeText = Utils.ResolveText(START_TYPE_TEXT_KEYS[info.Type])

    local nameKey = nil
    if info.Type == "Player" then
        nameKey = Utils.GetPlayerLabel(info.Player)
    elseif info.Type == "Leader" then
        local leader = info.Leader ~= nil and GameInfo.Leaders[info.Leader] or nil
        nameKey = leader ~= nil and leader.Name or "LOC_CAI_WORLD_SCANNER_UNKNOWN"
    elseif info.Type == "Civilization" then
        local civilization = info.Civilization ~= nil and GameInfo.Civilizations[info.Civilization] or nil
        nameKey = civilization ~= nil and civilization.Name or "LOC_CAI_WORLD_SCANNER_UNKNOWN"
    end

    if nameKey == nil then
        return groupId, typeText
    end

    return groupId, Locale.Lookup(
        "LOC_CAI_WORLD_SCANNER_WB_START_LABEL",
        typeText,
        Utils.ResolveText(nameKey)
    )
end

function CAIWorldScannerCategory_WorldBuilder.BeginExtract()
    m_playerManager = IsWorldBuilderActive() and WorldBuilder.PlayerManager() or nil
    m_ownerBuckets = {}
end

function CAIWorldScannerCategory_WorldBuilder.PlotExtract(plotIndex, plot, _, collect, _)
    -- Starting positions: one item per placed start plot, labelled by assignment.
    if m_playerManager ~= nil and m_playerManager.GetStartPositionInfo ~= nil then
        local info = m_playerManager:GetStartPositionInfo(plotIndex)
        if info ~= nil then
            local groupId, labelKey = ResolveStartPosition(info)
            if groupId ~= nil then
                collect({
                    Id = "worldBuilder:start:" .. tostring(plotIndex),
                    PlotIndex = plotIndex,
                    LabelKey = labelKey,
                    SubCategoryId = SUBCATEGORY_STARTS,
                    GroupId = groupId,
                    GroupLabelKey = START_GROUP_LABEL_KEYS[groupId],
                })
            end
        end
    end

    -- Ownership: bucket owned plots per owner, zoned in EndExtract.
    local ownerID = plot:GetOwner()
    if ownerID ~= nil and ownerID >= 0 then
        local bucket = m_ownerBuckets[ownerID]
        if bucket == nil then
            bucket = {}
            m_ownerBuckets[ownerID] = bucket
        end
        bucket[#bucket + 1] = plotIndex
    end
end

function CAIWorldScannerCategory_WorldBuilder.EndExtract(_, collect)
    for ownerID, plotIndices in pairs(m_ownerBuckets) do
        local capturedOwnerID = ownerID
        local playerLabel = Utils.GetPlayerLabel(ownerID)
        for _, zone in ipairs(ZoneUtils.PartitionPlotIndices(plotIndices)) do
            collect({
                Id = "worldBuilder:owner:" .. tostring(ownerID) .. ":" .. tostring(zone.MinPlotIndex),
                PlotIndex = zone.MinPlotIndex,
                ZonePlotIndices = zone.PlotIndices,
                ZoneValidatePlot = function(_, plot)
                    return plot:GetOwner() == capturedOwnerID
                end,
                LabelKey = playerLabel,
                SubCategoryId = SUBCATEGORY_OWNERSHIP,
                GroupId = "owner:" .. tostring(ownerID),
                GroupLabelKey = playerLabel,
            })
        end
    end
end

CAIWorldScanner:RegisterCategoryDefinition(CAIWorldScannerCategory_WorldBuilder)
