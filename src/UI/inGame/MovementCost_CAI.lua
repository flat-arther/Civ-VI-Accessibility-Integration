include("inGameHelpers_CAI")

MovementCost_CAI = MovementCost_CAI or {}

local RIVER_CROSSING_COST = 2
local NORMAL_TILE_COST = 1
local TUNNEL_COST = 3
local EPSILON = 0.0001
local m_movementModifiersByOwner = nil
local m_turnStartPlots = {}

local function UnitKey(unit)
    return tostring(unit:GetOwner()) .. ":" .. tostring(unit:GetID())
end

local function CapturePlayerTurnStarts(playerId)
    local player = playerId ~= nil and playerId ~= -1 and Players[playerId] or nil
    local units = player ~= nil and player:GetUnits() or nil
    if units == nil then return end
    for _, unit in units:Members() do
        m_turnStartPlots[UnitKey(unit)] = unit:GetPlotId()
    end
end

local function GetTurnStartPlot(unit)
    local plotId = m_turnStartPlots[UnitKey(unit)]
    if plotId == nil then
        plotId = unit:GetPlotId()
        m_turnStartPlots[UnitKey(unit)] = plotId
    end
    return Map.GetPlotByIndex(plotId)
end

local function GetActiveTypes(unit)
    local result = {}
    local ability = unit:GetAbility()
    for _, index in ipairs(ability:GetAbilities() or {}) do
        local row = GameInfo.UnitAbilities[index]
        if row ~= nil then result[row.UnitAbilityType] = true end
    end
    local experience = unit:GetExperience()
    for _, index in ipairs(experience:GetPromotions() or {}) do
        local row = GameInfo.UnitPromotions[index]
        if row ~= nil then result[row.UnitPromotionType] = true end
    end
    return result
end

local function BuildMovementModifierIndex()
    if m_movementModifiersByOwner ~= nil then return end
    local arguments = {}
    for row in GameInfo.ModifierArguments() do
        arguments[row.ModifierId] = arguments[row.ModifierId] or {}
        arguments[row.ModifierId][row.Name] = row.Value
    end
    m_movementModifiersByOwner = {}
    local function Add(ownerType, modifierId)
        local modifier = GameInfo.Modifiers[modifierId]
        local modifierType = modifier ~= nil and modifier.ModifierType or nil
        if modifierType == "MODIFIER_PLAYER_UNIT_ADJUST_IGNORE_TERRAIN_COST"
            or modifierType == "MODIFIER_PLAYER_UNIT_ADJUST_IGNORE_RIVERS"
            or modifierType == "MODIFIER_PLAYER_UNIT_ADJUST_IGNORE_SHORES"
            or modifierType == "MODIFIER_PLAYER_UNIT_ADJUST_CLEAR_TERRAIN_START_MOVEMENT"
            or modifierId == "TRIEU_FRIENDLY_MOVEMENT"
            or modifierId == "TRIEU_UNFRIENDLY_MOVEMENT" then
            m_movementModifiersByOwner[ownerType] = m_movementModifiersByOwner[ownerType] or {}
            table.insert(m_movementModifiersByOwner[ownerType], {
                modifierId = modifierId,
                modifierType = modifierType,
                arguments = arguments[modifierId] or {},
            })
        end
    end
    for row in GameInfo.UnitAbilityModifiers() do Add(row.UnitAbilityType, row.ModifierId) end
    for row in GameInfo.UnitPromotionModifiers() do Add(row.UnitPromotionType, row.ModifierId) end
end

local function ReadMovementRules(unit)
    BuildMovementModifierIndex()
    local active = GetActiveTypes(unit)
    local rules = { ignoreTerrain = {}, ignoreRivers = false, ignoreShores = false, startBonuses = {} }

    for ownerType in pairs(active) do
      for _, modifier in ipairs(m_movementModifiersByOwner[ownerType] or {}) do
        local args = modifier.arguments
        if modifier.modifierType == "MODIFIER_PLAYER_UNIT_ADJUST_IGNORE_TERRAIN_COST"
            and tostring(args.Ignore) ~= "false" then
            rules.ignoreTerrain[tostring(args.Type or "ALL")] = true
        elseif modifier.modifierType == "MODIFIER_PLAYER_UNIT_ADJUST_IGNORE_RIVERS"
            and tostring(args.Ignore) ~= "false" then
            rules.ignoreRivers = true
        elseif modifier.modifierType == "MODIFIER_PLAYER_UNIT_ADJUST_IGNORE_SHORES"
            and tostring(args.Ignore) ~= "false" then
            rules.ignoreShores = true
        elseif modifier.modifierType == "MODIFIER_PLAYER_UNIT_ADJUST_CLEAR_TERRAIN_START_MOVEMENT"
            or modifier.modifierId == "TRIEU_FRIENDLY_MOVEMENT"
            or modifier.modifierId == "TRIEU_UNFRIENDLY_MOVEMENT" then
            rules.startBonuses[#rules.startBonuses + 1] = modifier
        end
      end
    end
    return rules
end

local function IsOpenTerrain(plot)
    if plot == nil or plot:GetFeatureType() ~= -1 then return false end
    local terrain = GameInfo.Terrains[plot:GetTerrainType()]
    return terrain ~= nil and not terrain.Hills
end

local function IsTrieuFeature(plot)
    if plot == nil or plot:GetFeatureType() == -1 then return false end
    local feature = GameInfo.Features[plot:GetFeatureType()]
    if feature == nil then return false end
    return feature.FeatureType == "FEATURE_FOREST"
        or feature.FeatureType == "FEATURE_JUNGLE"
        or feature.FeatureType == "FEATURE_MARSH"
end

local function GetConditionalStartBonus(unit, rules, plot)
    local bonus = 0
    for _, modifier in ipairs(rules.startBonuses) do
        local amount = tonumber(modifier.arguments.Amount) or 0
        if modifier.modifierType == "MODIFIER_PLAYER_UNIT_ADJUST_CLEAR_TERRAIN_START_MOVEMENT" then
            if IsOpenTerrain(plot) then bonus = bonus + amount end
        elseif modifier.modifierId == "TRIEU_FRIENDLY_MOVEMENT" then
            if IsTrieuFeature(plot) and plot:GetOwner() == unit:GetOwner() then bonus = bonus + amount end
        elseif modifier.modifierId == "TRIEU_UNFRIENDLY_MOVEMENT" then
            if IsTrieuFeature(plot) and plot:GetOwner() ~= unit:GetOwner() then bonus = bonus + amount end
        end
    end
    return bonus
end

local function GetFormationMembers(unit)
    local members = GetFormationUnitsOnPlot(unit)
    return #members > 0 and members or { unit }
end

local function GetFutureMaxMoves(unit, waypointPlot)
    local futureMax = nil
    for _, member in ipairs(GetFormationMembers(unit)) do
        local memberRules = ReadMovementRules(member)
        local unconditional = member:GetMaxMoves()
            - GetConditionalStartBonus(member, memberRules, GetTurnStartPlot(member))
        local memberFuture = unconditional + GetConditionalStartBonus(member, memberRules, waypointPlot)
        futureMax = futureMax == nil and memberFuture or math.min(futureMax, memberFuture)
    end
    return futureMax or unit:GetMaxMoves()
end

local function HasRiverCrossing(fromPlot, toPlot)
    return fromPlot:IsRiverCrossingToPlot(toPlot) == true
end

local function GetRoute(plot)
    if not plot:IsRoute() or plot:IsRoutePillaged() then return nil end
    return GameInfo.Routes[plot:GetRouteType()]
end

local function GetRoadCost(fromPlot, toPlot, crossesRiver)
    local fromRoute = GetRoute(fromPlot)
    local toRoute = GetRoute(toPlot)
    if fromRoute == nil or toRoute == nil then return nil end
    if crossesRiver and not (fromRoute.SupportsBridges and toRoute.SupportsBridges) then return nil end
    return math.max(tonumber(fromRoute.MovementCost) or NORMAL_TILE_COST,
        tonumber(toRoute.MovementCost) or NORMAL_TILE_COST)
end

local function GetPlotCost(rules, plot)
    if rules.ignoreTerrain.ALL then return NORMAL_TILE_COST end
    local cost = tonumber(plot:GetMovementCost()) or NORMAL_TILE_COST
    local terrain = GameInfo.Terrains[plot:GetTerrainType()]
    local feature = plot:GetFeatureType() ~= -1 and GameInfo.Features[plot:GetFeatureType()] or nil
    if terrain ~= nil and terrain.Hills and rules.ignoreTerrain.HILLS then
        cost = cost - math.max(0, (tonumber(terrain.MovementCost) or NORMAL_TILE_COST) - NORMAL_TILE_COST)
    end
    if feature ~= nil then
        local typeName = feature.FeatureType:gsub("^FEATURE_", "")
        if rules.ignoreTerrain[typeName] or (typeName == "FOREST" and rules.ignoreTerrain.WOODS) then
            cost = cost - math.max(0, tonumber(feature.MovementChange) or 0)
        end
    end
    return math.max(NORMAL_TILE_COST, cost)
end

local function IsEasyShoreTransition(plot)
    if plot:IsCity() then return true end
    local districtType = plot:GetDistrictType()
    local district = districtType ~= nil and districtType ~= -1 and GameInfo.Districts[districtType] or nil
    return district ~= nil and district.DistrictType == "DISTRICT_HARBOR"
end

local function IsPortalEdge(pathInfo, fromId, toId)
    for i, entranceId in ipairs(pathInfo.entrancePortals or {}) do
        if entranceId == fromId and pathInfo.exitPortals[i] == toId then return true end
    end
    return false
end

local function GetEdgeCost(pathInfo, rules, fromPlot, toPlot)
    if IsPortalEdge(pathInfo, fromPlot:GetIndex(), toPlot:GetIndex()) then return TUNNEL_COST end

    local changesDomain = fromPlot:IsWater() ~= toPlot:IsWater()
    if changesDomain and not rules.ignoreShores then
        if IsEasyShoreTransition(fromPlot) or IsEasyShoreTransition(toPlot) then return NORMAL_TILE_COST end
        return nil -- The engine consumes the current turn; the path turn labels provide the exact boundary.
    end

    local crossesRiver = HasRiverCrossing(fromPlot, toPlot)
    local roadCost = GetRoadCost(fromPlot, toPlot, crossesRiver)
    if roadCost ~= nil then return roadCost end

    local cost = GetPlotCost(rules, toPlot)
    if crossesRiver and not rules.ignoreRivers then cost = cost + RIVER_CROSSING_COST end
    return cost
end

function MovementCost_CAI.Calculate(unit, pathInfo)
    if unit == nil or pathInfo == nil or not pathInfo.hasPath or #pathInfo.plots < 2 then return nil end
    local rules = ReadMovementRules(unit)
    local total = 0
    local formationUnitCount = unit:GetFormationUnitCount()
    local isFormation = formationUnitCount ~= nil and formationUnitCount > 1
    local remaining = isFormation and unit:GetFormationMovesRemaining()
        or unit:GetMovementMovesRemaining()
    local maxMoves = isFormation and unit:GetFormationMaxMoves() or unit:GetMaxMoves()
    local activeTurn = 1

    for i = 2, #pathInfo.plots do
        local turn = tonumber(pathInfo.turns[i]) or activeTurn
        if turn > activeTurn then
            activeTurn = turn
            local waypointPlot = Map.GetPlotByIndex(pathInfo.plots[i - 1])
            maxMoves = GetFutureMaxMoves(unit, waypointPlot)
            remaining = maxMoves
        end
        local fromPlot = Map.GetPlotByIndex(pathInfo.plots[i - 1])
        local toPlot = Map.GetPlotByIndex(pathInfo.plots[i])
        local edgeCost = GetEdgeCost(pathInfo, rules, fromPlot, toPlot)
        if edgeCost == nil then
            edgeCost = remaining
        elseif edgeCost > remaining + EPSILON and remaining >= maxMoves - EPSILON then
            edgeCost = remaining -- Full-movement units may always enter one adjacent passable tile.
        end
        total = total + edgeCost
        remaining = math.max(0, remaining - edgeCost)
    end

    local unitInfo = GameInfo.Units[unit:GetType()]
    local losesMovesInZOC = unitInfo ~= nil
        and (unitInfo.FormationClass == "FORMATION_CLASS_CIVILIAN"
            or unitInfo.FormationClass == "FORMATION_CLASS_SUPPORT")
        and unitInfo.PromotionClass ~= "PROMOTION_CLASS_RELIGIOUS"
    if pathInfo.endsInZOC and not unit:IgnoresZOC() and losesMovesInZOC then remaining = 0 end

    return { total = total, remaining = remaining }
end

Events.LocalPlayerTurnBegin.Add(CapturePlayerTurnStarts)
CapturePlayerTurnStarts(Game.GetLocalPlayer())
