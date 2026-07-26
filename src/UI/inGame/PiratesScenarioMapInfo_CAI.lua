include("PiratesScenario_PropKeys")

CAIPiratesMapInfo = {}
local M = CAIPiratesMapInfo

local BURIED_TREASURE = GameInfo.Improvements["IMPROVEMENT_BURIED_TREASURE"].Index
local FLOATING_TREASURE = GameInfo.Improvements["IMPROVEMENT_FLOATING_TREASURE"].Index
local DOWSING_ROD = GameInfo.Policies["POLICY_RELIC_DOWSING_ROD"].Index
local ENGLISH_POINTER = GameInfo.Policies["POLICY_RELIC_ENGLISH_POINTER"].Index

function M.IsActive()
    return GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_PIRATES"
end

function M.IsTreasureSearchPlot(plot, playerID)
    local player = Players[playerID]
    if player == nil then return false end
    for _, treasureMap in ipairs(player:GetProperty(g_playerPropertyKeys.TreasureMaps) or {}) do
        local zoneSize = treasureMap.ZoneSize or PIRATE_TREASURE_SEARCH_ZONE_SIZE
        local center = Map.GetPlotByIndex(treasureMap.SearchCenterIndex)
        if center ~= nil and Map.GetPlotDistance(
            plot:GetX(), plot:GetY(), center:GetX(), center:GetY()) <= zoneSize then
            return true
        end
    end
    return false
end

function M.IsInfamousSearchPlot(plot)
    for _, searchZone in ipairs(Game:GetProperty(g_gamePropertyKeys.InfamousPirateSearchZones) or {}) do
        local center = Map.GetPlotByIndex(searchZone.CenterPlotIndex)
        if center ~= nil and Map.GetPlotDistance(
            plot:GetX(), plot:GetY(), center:GetX(), center:GetY()) <= INFAMOUS_PIRATE_SEARCH_ZONE_SIZE then
            return true
        end
    end
    return false
end

function M.IsTreasureFleetRoutePlot(plot)
    local routeValue = plot:GetProperty(g_plotPropertyKeys.TreasureFleetPath)
    return routeValue ~= nil and routeValue > 0
end

function M.IsTreasurePlot(plot)
    local improvementType = plot:GetImprovementType()
    return (improvementType == BURIED_TREASURE or improvementType == FLOATING_TREASURE)
        and not plot:IsImprovementPillaged()
end

function M.GetTreasureOwnerSpeech(plot)
    if not M.IsTreasurePlot(plot) then return nil end

    local ownerID = plot:GetImprovementOwner()
    local ownerName
    if ownerID == -1 then
        ownerName = plot:GetProperty(g_plotPropertyKeys.TreasureOwnerName)
    else
        local config = PlayerConfigurations[ownerID]
        ownerName = config and config:GetPlayerName() or nil
    end
    if ownerName == nil then return nil end
    return Locale.Lookup("LOC_PIRATES_PLOT_TOOLTIP_TREASURE_OWNER", ownerName)
end

function M.FindClosestUnseenEnemyUnitPlot(unit)
    local visibility = PlayersVisibility[unit:GetOwner()]
    local closestUnit = nil
    local closestDistance = RELIC_ENGLISH_POINTER_RANGE
    for _, player in ipairs(PlayerManager.GetAlive()) do
        if player:GetID() ~= unit:GetOwner() then
            for _, candidate in player:GetUnits():Members() do
                if not visibility:IsUnitVisible(candidate) then
                    local distance = Map.GetPlotDistance(
                        unit:GetX(), unit:GetY(), candidate:GetX(), candidate:GetY())
                    if distance < closestDistance then
                        closestUnit = candidate
                        closestDistance = distance
                    end
                end
            end
        end
    end
    if closestUnit == nil then return nil end
    return Map.GetPlotIndex(closestUnit:GetX(), closestUnit:GetY()), closestDistance
end

function M.FindClosestTreasurePlot(unit)
    local closestPlotIndex = nil
    local closestDistance = RELIC_DOWSING_ROD_RANGE
    for dx = -RELIC_DOWSING_ROD_RANGE, RELIC_DOWSING_ROD_RANGE do
        for dy = -RELIC_DOWSING_ROD_RANGE, RELIC_DOWSING_ROD_RANGE do
            local plot = Map.GetPlotXYWithRangeCheck(
                unit:GetX(), unit:GetY(), dx, dy, RELIC_DOWSING_ROD_RANGE)
            if plot ~= nil and M.IsTreasurePlot(plot)
                and plot:GetImprovementOwner() ~= unit:GetOwner() then
                local distance = Map.GetPlotDistance(
                    unit:GetX(), unit:GetY(), plot:GetX(), plot:GetY())
                if closestPlotIndex == nil or distance < closestDistance then
                    closestPlotIndex = plot:GetIndex()
                    closestDistance = distance
                end
            end
        end
    end
    return closestPlotIndex, closestDistance
end

function M.GetSensorTargets(playerID)
    local player = Players[playerID]
    if player == nil then return {} end

    local culture = player:GetCulture()
    local hasPointer = culture:IsPolicyActive(ENGLISH_POINTER)
    local hasDowsingRod = culture:IsPolicyActive(DOWSING_ROD)
    if not hasPointer and not hasDowsingRod then return {} end

    local targets = {}
    for _, unit in player:GetUnits():Members() do
        local unitInfo = GameInfo.Units[unit:GetType()]
        if unitInfo ~= nil and unitInfo.Domain == "DOMAIN_SEA" then
            if hasPointer then
                local plotIndex, distance = M.FindClosestUnseenEnemyUnitPlot(unit)
                if plotIndex ~= nil then
                    targets[#targets + 1] = {
                        Kind = "enemy",
                        SourceUnitID = unit:GetID(),
                        SourceUnitName = Locale.Lookup(unit:GetName()),
                        PlotIndex = plotIndex,
                        Distance = distance,
                    }
                end
            end
            if hasDowsingRod then
                local plotIndex, distance = M.FindClosestTreasurePlot(unit)
                if plotIndex ~= nil then
                    targets[#targets + 1] = {
                        Kind = "treasure",
                        SourceUnitID = unit:GetID(),
                        SourceUnitName = Locale.Lookup(unit:GetName()),
                        PlotIndex = plotIndex,
                        Distance = distance,
                    }
                end
            end
        end
    end
    return targets
end
