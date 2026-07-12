include("caiUtils")
include("AdjacencyBonusSupport")
include("hexCoordUtils_CAI")
-- ===========================================================================
-- Unit movement helpers (extracted from vanilla WorldInput so other contexts
-- can reuse path-info / movement-speech without depending on WorldInput state).
-- ===========================================================================


local HexCoordUtils = CAIHexCoordUtils

---@class MovementPathInfo
---@field kind string
---@field turns number[]
---@field plots number[]
---@field hasPath boolean
---@field steps PathStep[]
---@field segments PathSegment[]
---@field obstacles number[]
---@field intersectsZOC boolean
---@field endsInZOC boolean
---@field isRestricted boolean
---@field restrictedPlotId number|nil
---@field isPathInFog boolean
---@field enemyAtWarAtEnd boolean
---@field isQueued boolean
---@field destPlot integer
---@field isImplicitRangedAttack boolean
---@field isSamePlot boolean
---@field entrancePortals number[]
---@field exitPortals number[]
---@field arrivalTurn number
---@field failureKind string|nil
---@field visiblePathNodes table[]|nil
---@field visiblePathText string|nil
---@field entersFog boolean
---@field entersUnrevealed boolean
---@field usesPortal boolean
---@field combatAtEnd boolean
---@field enemyCityAtEnd boolean
---@field willDeclareWar boolean
---@field blockingUnit table|nil
---@field requiredTechType string|nil
---@field targetOwner number|nil

-- ===========================================================================
-- TUTORIAL RESTRICTION STATE (mirrors vanilla WorldInput)
-- ===========================================================================

local m_constrainToPlotID = 0
local m_kTutorialUnitMoveRestrictions = nil
local m_kTutorialUnitHexRestrictions = nil

-- ===========================================================================
-- TUTORIAL RESTRICTION EVENT HANDLERS
-- ===========================================================================

function OnTutorial_AddUnitMoveRestriction(unitType)
    if m_kTutorialUnitMoveRestrictions == nil then
        m_kTutorialUnitMoveRestrictions = {}
    end
    if m_kTutorialUnitMoveRestrictions[unitType] then
        UI.DataError("Setting tutorial WorldInput unit selection for '" ..
            unitType .. "' but it's already set to restricted!")
    end
    m_kTutorialUnitMoveRestrictions[unitType] = true
end

function OnTutorial_RemoveUnitMoveRestrictions(optionalUnitType)
    if optionalUnitType == nil then
        m_kTutorialUnitMoveRestrictions = nil
    else
        if m_kTutorialUnitMoveRestrictions[optionalUnitType] == nil then
            UI.DataError("Tutorial did not reset WorldInput selection for the unit type '" ..
                optionalUnitType .. "' since it's not in the restriction list.")
        end
        m_kTutorialUnitMoveRestrictions[optionalUnitType] = nil
    end
end

function OnTutorial_ConstrainMovement(plotID)
    m_constrainToPlotID = plotID
end

function OnTutorial_AddUnitHexRestriction(unitType, kPlotIds)
    if m_kTutorialUnitHexRestrictions == nil then
        m_kTutorialUnitHexRestrictions = {}
    end
    if m_kTutorialUnitHexRestrictions[unitType] == nil then
        m_kTutorialUnitHexRestrictions[unitType] = {}
    end
    for _, plotId in ipairs(kPlotIds) do
        table.insert(m_kTutorialUnitHexRestrictions[unitType], plotId)
    end
end

function OnTutorial_RemoveUnitHexRestriction(unitType, kPlotIds)
    if m_kTutorialUnitHexRestrictions == nil then
        UI.DataError("Cannot RemoveUnitHexRestriction( " .. unitType .. " ...) as no restrictions are set.")
        return
    end
    if m_kTutorialUnitHexRestrictions[unitType] == nil then
        UI.DataError("Cannot RemoveUnitHexRestriction( " ..
            unitType .. " ...) as a restriction for that unit type is not set.")
        return
    end

    for _, plotId in ipairs(kPlotIds) do
        local isRemoved = false
        for i = #m_kTutorialUnitHexRestrictions[unitType], 1, -1 do
            if m_kTutorialUnitHexRestrictions[unitType][i] == plotId then
                table.remove(m_kTutorialUnitHexRestrictions[unitType], i)
                isRemoved = true
                break
            end
        end
        if not isRemoved then
            UI.DataError("Cannot remove restriction for the plot " ..
                tostring(plotId) .. ", it wasn't found in the list for unit " .. unitType)
        end
    end
end

function OnTutorial_ClearAllUnitHexRestrictions()
    m_kTutorialUnitHexRestrictions = nil
end

-- ===========================================================================
-- RESTRICTION QUERIES
-- ===========================================================================

function IsUnitTypeAllowedToMoveToPlot(unitType, plotId)
    if m_kTutorialUnitHexRestrictions == nil then return true end
    if m_kTutorialUnitHexRestrictions[unitType] ~= nil then
        for _, restrictedPlotId in ipairs(m_kTutorialUnitHexRestrictions[unitType]) do
            if plotId == restrictedPlotId then
                return false
            end
        end
    end
    return true
end

local function IsPlotPathRestrictedForUnit(kPlotPath, kTurnsList, pUnit)
    local endPlotId = kPlotPath[table.count(kPlotPath)]
    if m_constrainToPlotID ~= 0 and endPlotId ~= m_constrainToPlotID then
        return true, m_constrainToPlotID
    end

    local unitType = GameInfo.Units[pUnit:GetUnitType()].UnitType

    if m_kTutorialUnitMoveRestrictions ~= nil and m_kTutorialUnitMoveRestrictions[unitType] ~= nil then
        return true, -1
    end

    if m_kTutorialUnitHexRestrictions ~= nil then
        if m_kTutorialUnitHexRestrictions[unitType] ~= nil then
            local lastTurn = 1
            local lastRestrictedPlot = -1
            for i, plotId in ipairs(kPlotPath) do
                if i > 1 then
                    if kTurnsList[i] == lastTurn then
                        lastRestrictedPlot = -1
                        if not IsUnitTypeAllowedToMoveToPlot(unitType, plotId) then
                            lastTurn = kTurnsList[i]
                            lastRestrictedPlot = plotId
                        end
                    else
                        if lastRestrictedPlot ~= -1 then
                            return true, lastRestrictedPlot
                        end
                        if not IsUnitTypeAllowedToMoveToPlot(unitType, plotId) then
                            lastTurn = kTurnsList[i]
                            lastRestrictedPlot = plotId
                        end
                    end
                end
            end
            if lastRestrictedPlot ~= -1 then
                return true, lastRestrictedPlot
            end
        end
    end

    return false
end

-- ===========================================================================
-- MOVEMENT PATH ANALYSIS
-- ===========================================================================

local function GetLocalDiplomacy()
    local localPlayerID = Game.GetLocalPlayer()
    local localPlayer = localPlayerID ~= nil and localPlayerID ~= -1 and Players[localPlayerID] or nil
    if localPlayer == nil or localPlayer.GetDiplomacy == nil then
        return nil
    end

    return localPlayer:GetDiplomacy()
end

local function IsAtWarWithLocalPlayer(playerID)
    local localPlayerID = Game.GetLocalPlayer()
    if playerID == nil or playerID == -1 or playerID == localPlayerID then
        return false
    end

    local diplomacy = GetLocalDiplomacy()
    return diplomacy ~= nil and diplomacy:IsAtWarWith(playerID)
end

local function HasVisibleForeignUnit(plot)
    if plot == nil then return false, nil, false end

    local localPlayerID = Game.GetLocalPlayer()
    local visibility = PlayersVisibility[localPlayerID]
    local units = Units.GetUnitsInPlotLayerID(plot:GetX(), plot:GetY(), MapLayers.ANY)
    for _, unit in ipairs(units) do
        local ownerID = unit:GetOwner()
        if ownerID ~= localPlayerID and visibility ~= nil and visibility:IsUnitVisible(unit) then
            return true, unit, IsAtWarWithLocalPlayer(ownerID)
        end
    end

    return false, nil, false
end

local function GetCityOrDistrictOwner(plot)
    if plot == nil then return nil end

    local plotOwner = plot.GetOwner and plot:GetOwner() or nil
    if plotOwner ~= nil and plotOwner ~= -1 then
        return plotOwner
    end

    local city = CityManager.GetCityAt(plot:GetX(), plot:GetY())
    if city ~= nil then
        return city:GetOwner()
    end

    local district = CityManager.GetDistrictAt(plot:GetX(), plot:GetY())
    if district ~= nil then
        local districtCity = district:GetCity()
        if districtCity ~= nil then
            return districtCity:GetOwner()
        end
    end

    return nil
end

local function IsAttackableCombatTarget(unit, targetPlot)
    local combatResults = CombatManager.SimulateAttackInto(unit:GetComponentID(), nil,
        targetPlot:GetX(), targetPlot:GetY())
    local defender = combatResults ~= nil and combatResults[CombatResultParameters.DEFENDER] or nil
    local defenderID = defender ~= nil and defender[CombatResultParameters.ID] or nil
    local combatType = combatResults ~= nil and combatResults[CombatResultParameters.COMBAT_TYPE] or nil
    if defenderID == nil or combatType == nil then
        return false
    end

    return CombatManager.CanAttackTarget(unit:GetComponentID(), defenderID, combatType)
end

local function GetTechNameKey(techType)
    local tech = techType ~= nil and GameInfo.Technologies[techType] or nil
    return tech ~= nil and tech.Name or nil
end

local function GetRequiresTechText(techType)
    local techNameKey = GetTechNameKey(techType)
    if techNameKey == nil then
        return nil
    end

    return Locale.Lookup("LOC_HUD_UNIT_ACTION_REQUIRES_TECH", Locale.Lookup(techNameKey))
end

local function PlayerHasTech(playerID, techType)
    if playerID == nil or playerID < 0 or techType == nil then
        return false
    end

    local player = Players[playerID]
    if player == nil or player.GetTechs == nil then
        return false
    end

    local playerTechs = player:GetTechs()
    local tech = GameInfo.Technologies[techType]
    if playerTechs == nil or tech == nil then
        return false
    end

    return playerTechs:HasTech(tech.Index)
end

local function GetEmbarkTechTypeForUnit(unit)
    if unit == nil then
        return "TECH_SHIPBUILDING"
    end

    local unitInfo = GameInfo.Units[unit:GetUnitType()]
    local unitType = unitInfo ~= nil and unitInfo.UnitType or unit:GetUnitType()
    if unitType == "UNIT_BUILDER" then
        return "TECH_SAILING"
    end
    if unitType == "UNIT_TRADER" then
        return "TECH_CELESTIAL_NAVIGATION"
    end

    return "TECH_SHIPBUILDING"
end

local function IsOceanPlot(plot)
    if plot == nil or not plot:IsWater() or plot:IsLake() then
        return false
    end

    local terrainTypeIndex = plot.GetTerrainType and plot:GetTerrainType() or nil
    local terrain = terrainTypeIndex ~= nil and GameInfo.Terrains[terrainTypeIndex] or nil
    return terrain ~= nil and terrain.TerrainType == "TERRAIN_OCEAN"
end

local function LogMovementFailure(pathInfo, startPlot, targetPlot, unit)
    if pathInfo == nil or startPlot == nil or targetPlot == nil or unit == nil then
        return
    end

    local plotList = pathInfo.plots ~= nil and table.concat(pathInfo.plots, ",") or ""
    local turnList = pathInfo.turns ~= nil and table.concat(pathInfo.turns, ",") or ""

    LogMessage(string.format(
        "CAI movement diag unit=%s start=(%s,%s) target=(%s,%s) startPlotId=%s targetPlotId=%s reason=%s tech=%s targetOwner=%s targetVisibleUnit=%s startWater=%s targetWater=%s startArea=%s targetArea=%s plots=[%s] turns=[%s]",
        tostring(unit:GetID()),
        tostring(startPlot:GetX()),
        tostring(startPlot:GetY()),
        tostring(targetPlot:GetX()),
        tostring(targetPlot:GetY()),
        tostring(startPlot:GetIndex()),
        tostring(targetPlot:GetIndex()),
        tostring(pathInfo.failureKind),
        tostring(pathInfo.requiredTechType),
        tostring(pathInfo.targetOwner),
        tostring(pathInfo.blockingUnit ~= nil),
        tostring(startPlot:IsWater()),
        tostring(targetPlot:IsWater()),
        tostring(startPlot:GetArea()),
        tostring(targetPlot:GetArea()),
        plotList,
        turnList
    ))
end

local function HasPortal(pathInfo)
    for _, portal in ipairs(pathInfo.entrancePortals or {}) do
        if portal ~= nil and portal >= 0 then return true end
    end
    for _, portal in ipairs(pathInfo.exitPortals or {}) do
        if portal ~= nil and portal >= 0 then return true end
    end
    return false
end

local PlotIdsToPathNodes

local function BuildTurnSegmentedPathText(plotIds, turns, endIndex)
    if plotIds == nil or turns == nil then
        return nil
    end

    endIndex = math.min(endIndex or #plotIds, #plotIds, #turns)
    if endIndex < 2 then
        return nil
    end

    local segments = {}
    local segmentStart = 1
    local lastTurn = tonumber(turns[1]) or 1

    for i = 2, endIndex do
        local turn = tonumber(turns[i])
        if turn ~= nil and turn > lastTurn then
            if segmentStart < i - 1 then
                local segmentNodes = PlotIdsToPathNodes(plotIds, segmentStart, i - 1)
                local segmentText = HexCoordUtils.stepListFromPath(segmentNodes)
                if segmentText ~= "" then
                    segments[#segments + 1] = segmentText
                end
            end
            segmentStart = i - 1
            lastTurn = turn
        end
    end

    local finalNodes = PlotIdsToPathNodes(plotIds, segmentStart, endIndex)
    local finalText = HexCoordUtils.stepListFromPath(finalNodes)
    if finalText ~= "" then
        segments[#segments + 1] = finalText
    end

    local text = HexCoordUtils.joinStepSegments(segments)
    if text == "" then
        return nil
    end

    return text
end

local function AnalyzePathFeatures(unit, targetPlot, pathInfo)
    if pathInfo.plots == nil or #pathInfo.plots < 2 then
        return
    end

    local unitInfo = GameInfo.Units[unit:GetUnitType()]
    local domain = unitInfo ~= nil and unitInfo.Domain or nil

    if targetPlot ~= nil and CombatManager ~= nil and CombatManager.IsAttackChangeWarState ~= nil then
        local visibility = PlayersVisibility[unit:GetOwner()]
        if visibility ~= nil and visibility:IsVisible(targetPlot:GetX(), targetPlot:GetY()) then
            local results = CombatManager.IsAttackChangeWarState(unit:GetComponentID(), targetPlot:GetX(),
                targetPlot:GetY())
            pathInfo.willDeclareWar = results ~= nil and #results > 0
        end
    end

    if not pathInfo.isQueued
        and unit.IgnoresZOC ~= nil and not unit:IgnoresZOC()
        and unit.HasMovedIntoZOC ~= nil and not unit:HasMovedIntoZOC() then
        local zocPlots = UnitManager.GetReachableZonesOfControl(unit, true)
        local zoc = {}
        for _, entry in ipairs(zocPlots or {}) do
            local plotId = nil
            if type(entry) == "number" then
                plotId = entry
            elseif entry ~= nil and entry.GetIndex ~= nil then
                plotId = entry:GetIndex()
            end
            if plotId ~= nil then
                zoc[plotId] = true
            end
        end
        local lastPlotIndex = #pathInfo.plots
        for i = 2, lastPlotIndex do
            if zoc[pathInfo.plots[i]] then
                if i < lastPlotIndex then
                    pathInfo.intersectsZOC = true
                else
                    pathInfo.endsInZOC = true
                end
            end
        end
    end
end

PlotIdsToPathNodes = function(plotIds, startIndex, endIndex)
    local nodes = {}
    if plotIds == nil then return nodes end

    startIndex = startIndex or 1
    endIndex = endIndex or #plotIds
    for i = startIndex, endIndex do
        local plot = Map.GetPlotByIndex(plotIds[i])
        if plot ~= nil then
            nodes[#nodes + 1] = { x = plot:GetX(), y = plot:GetY() }
        end
    end

    return nodes
end

local function AnalyzeVisiblePrefix(pathInfo)
    pathInfo.visiblePathNodes = {}
    pathInfo.visiblePathText = nil
    pathInfo.entersFog = false
    pathInfo.entersUnrevealed = false

    if pathInfo.plots == nil or #pathInfo.plots < 2 then
        return
    end

    local visibility = PlayersVisibility[Game.GetLocalPlayer()]
    local revealedEndIndex = #pathInfo.plots
    if visibility ~= nil then
        for i, plotId in ipairs(pathInfo.plots) do
            if not visibility:IsRevealed(plotId) then
                pathInfo.entersUnrevealed = true
                revealedEndIndex = math.max(1, i - 1)
                break
            elseif not visibility:IsVisible(plotId) then
                pathInfo.entersFog = true
            end
        end
    end

    if revealedEndIndex >= 2 then
        pathInfo.visiblePathNodes = PlotIdsToPathNodes(pathInfo.plots, 1, revealedEndIndex)
        pathInfo.visiblePathText = BuildTurnSegmentedPathText(pathInfo.plots, pathInfo.turns, revealedEndIndex)
    end
end

local function DiagnoseMoveTarget(unit, startPlot, targetPlot, pathInfo)
    pathInfo.requiredTechType = nil
    pathInfo.targetOwner = nil

    if pathInfo.isRestricted then
        return "tutorial"
    end

    if targetPlot == nil then
        return "invalidPlot"
    end

    local unitInfo = GameInfo.Units[unit:GetUnitType()]
    local domain = unitInfo ~= nil and unitInfo.Domain or nil
    local targetOwner = GetCityOrDistrictOwner(targetPlot)
    pathInfo.targetOwner = targetOwner

    local _, blockingUnit, unitIsAtWar = HasVisibleForeignUnit(targetPlot)
    if blockingUnit ~= nil then
        pathInfo.blockingUnit = blockingUnit
        if domain == "DOMAIN_LAND" and targetPlot:IsWater() and unitIsAtWar then
            return "cantAttackFromLand"
        end
        if domain == "DOMAIN_SEA" and not targetPlot:IsWater() and not targetPlot:IsCity() and unitIsAtWar then
            return "cantAttackFromWater"
        end
        return "blockedUnit"
    end

    if domain == "DOMAIN_SEA" and not targetPlot:IsWater() and not targetPlot:IsCity() then
        return "cantTravelToLand"
    end

    if targetPlot:IsMountain() or targetPlot:IsImpassable() then
        return "blockedMountain"
    end

    if targetOwner ~= nil and targetOwner ~= -1 and targetOwner ~= Game.GetLocalPlayer()
        and not IsAtWarWithLocalPlayer(targetOwner) then
        return "blockedBorders"
    end

    if domain == "DOMAIN_LAND" and startPlot ~= nil and not startPlot:IsWater() then
        local embarkTechType = GetEmbarkTechTypeForUnit(unit)
        local hasEmbarkTech = PlayerHasTech(unit:GetOwner(), embarkTechType)

        if targetPlot:IsWater() then
            if IsOceanPlot(targetPlot) and hasEmbarkTech then
                pathInfo.requiredTechType = "TECH_CARTOGRAPHY"
                return "requiresOceanTech"
            end

            pathInfo.requiredTechType = embarkTechType
            return "requiresEmbarkTech"
        end

        if not targetPlot:IsWater() and startPlot:GetArea() ~= targetPlot:GetArea() then
            if not hasEmbarkTech then
                pathInfo.requiredTechType = embarkTechType
                return "requiresEmbarkTech"
            end

            pathInfo.requiredTechType = "TECH_CARTOGRAPHY"
            return "requiresOceanTech"
        end
    end

    return "unknown"
end

local function FinalizeMovementAnalysis(unit, targetPlot, pathInfo)
    local turns = pathInfo.turns or {}
    local startPlot = Map.GetPlotByIndex(unit:GetPlotId())
    pathInfo.arrivalTurn = (#turns > 0 and turns[#turns]) or 1
    pathInfo.usesPortal = HasPortal(pathInfo)
    pathInfo.combatAtEnd = false
    pathInfo.enemyCityAtEnd = false
    pathInfo.enemyAtWarAtEnd = false
    pathInfo.failureKind = nil
    AnalyzeVisiblePrefix(pathInfo)

    if pathInfo.hasPath and targetPlot ~= nil then
        local _, _, unitIsAtWar = HasVisibleForeignUnit(targetPlot)
        pathInfo.enemyAtWarAtEnd = unitIsAtWar

        local visibility = PlayersVisibility[Game.GetLocalPlayer()]
        if visibility == nil or visibility:IsVisible(targetPlot:GetX(), targetPlot:GetY()) then
            local cityOwnerID = GetCityOrDistrictOwner(targetPlot)
            pathInfo.enemyCityAtEnd = IsAtWarWithLocalPlayer(cityOwnerID)
        end
        pathInfo.combatAtEnd = pathInfo.arrivalTurn <= 1 and IsAttackableCombatTarget(unit, targetPlot)
    end

    AnalyzePathFeatures(unit, targetPlot, pathInfo)

    if pathInfo.kind == "bad" then
        pathInfo.failureKind = DiagnoseMoveTarget(unit, startPlot, targetPlot, pathInfo)
        LogMovementFailure(pathInfo, startPlot, targetPlot, unit)
    end
end

local function AddLine(lines, value)
    if value ~= nil and value ~= "" then
        lines[#lines + 1] = value
    end
end

local function FormatArrivalTurn(turn)
    turn = turn or 1
    if turn <= 1 then
        return Locale.Lookup("LOC_CAI_MOVEMENT_THIS_TURN")
    end
    return Locale.Lookup("LOC_CAI_MOVEMENT_TURNS", turn)
end

local function FormatObstacleCount(count)
    if count == nil or count <= 0 then return nil end
    return Locale.Lookup("LOC_CAI_MOVEMENT_CROSSES_OBSTACLES", count)
end

local function IsImplicitRangedAttackTarget(unit, endPlotId)
    if unit == nil or endPlotId == nil or unit:GetMovesRemaining() <= 0 then
        return false
    end

    local results = UnitManager.GetOperationTargets(unit, UnitOperationTypes.RANGE_ATTACK)
    local plots = results and results[UnitOperationResults.PLOTS] or nil
    local modifiers = results and results[UnitOperationResults.MODIFIERS] or nil
    if plots == nil or modifiers == nil then
        return false
    end

    for i, modifier in ipairs(modifiers) do
        if modifier == UnitOperationResults.MODIFIER_IS_TARGET and plots[i] == endPlotId then
            return true
        end
    end

    return false
end

local function HasImmediateCombat(pathInfo)
    return pathInfo ~= nil and pathInfo.combatAtEnd and not pathInfo.isQueued
end

local function HasDelayedCombat(pathInfo)
    if pathInfo == nil then
        return false
    end

    return not pathInfo.combatAtEnd and (pathInfo.enemyAtWarAtEnd or pathInfo.enemyCityAtEnd)
end

local function FormatAttackAfterMove(pathInfo)
    if not HasDelayedCombat(pathInfo) then
        return nil
    end
    if pathInfo.arrivalTurn <= 1 then
        return Locale.Lookup("LOC_CAI_MOVEMENT_ATTACK_AFTER_MOVE_THIS_TURN")
    end
    return Locale.Lookup("LOC_CAI_MOVEMENT_ATTACK_AFTER_MOVE_TURNS", pathInfo.arrivalTurn)
end

local function FormatFailure(pathInfo)
    local failureKind = pathInfo.failureKind or "cannotMove"
    if failureKind == "tutorial" then
        return Locale.Lookup("LOC_CAI_MOVEMENT_TUTORIAL_RESTRICTED")
    elseif failureKind == "blockedUnit" then
        return Locale.Lookup("LOC_CAI_MOVEMENT_BLOCKED_UNIT")
    elseif failureKind == "blockedMountain" then
        return Locale.Lookup("LOC_CAI_MOVEMENT_BLOCKED_MOUNTAIN")
    elseif failureKind == "cantAttackFromLand" then
        return Locale.Lookup("LOC_CAI_MOVEMENT_CANNOT_ATTACK_FROM_LAND")
    elseif failureKind == "cantAttackFromWater" then
        return Locale.Lookup("LOC_CAI_MOVEMENT_CANNOT_ATTACK_FROM_WATER")
    elseif failureKind == "cantTravelToLand" then
        return Locale.Lookup("LOC_CAI_MOVEMENT_CANNOT_TRAVEL_TO_LAND")
    elseif failureKind == "blockedBorders" then
        return Locale.Lookup("LOC_CAI_MOVEMENT_BLOCKED_BORDERS")
    elseif failureKind == "requiresEmbarkTech" or failureKind == "requiresOceanTech" then
        return GetRequiresTechText(pathInfo.requiredTechType) or Locale.Lookup("LOC_CAI_MOVEMENT_CANNOT_MOVE")
    elseif failureKind == "invalidPlot" then
        return Locale.Lookup("LOC_CAI_MOVEMENT_INVALID_PLOT")
    end

    return Locale.Lookup("LOC_CAI_MOVEMENT_CANNOT_MOVE")
end

-- ===========================================================================
-- PUBLIC API
-- ===========================================================================

---@param unit table
---@param endPlotId number
---@param showQueuedPath boolean
---@param showDetails boolean
---@return MovementPathInfo|nil
function BuildMovementPathInfo(unit, endPlotId, showQueuedPath, showDetails)
    if not unit or not Map.IsPlot(endPlotId) then return nil end

    local result = {
        kind                   = "move",
        turns                  = {},
        plots                  = {},
        hasPath                = false,
        steps                  = nil,
        segments               = nil,
        obstacles              = {},
        isRestricted           = false,
        restrictedPlotId       = nil,
        isPathInFog            = false,
        enemyAtWarAtEnd        = false,
        isQueued               = false,
        destPlot               = -1,
        isImplicitRangedAttack = false,
        isSamePlot             = false,
        entrancePortals        = {},
        exitPortals            = {},
        arrivalTurn            = 1,
        failureKind            = nil,
        visiblePathNodes       = nil,
        visiblePathText        = nil,
        entersFog              = false,
        entersUnrevealed       = false,
        usesPortal             = false,
        combatAtEnd            = false,
        enemyCityAtEnd         = false,
        willDeclareWar         = false,
        intersectsZOC          = false,
        endsInZOC              = false,
        blockingUnit           = nil,
        requiredTechType       = nil,
        targetOwner            = nil,
    }

    local eLocalPlayer = Game.GetLocalPlayer()
    local startPlotId = unit:GetPlotId()
    local targetPlot = nil

    if showQueuedPath then
        local queued = UnitManager.GetQueuedDestination(unit)
        if queued then
            endPlotId = queued
            result.isQueued = true
        end
    end

    result.destPlot = endPlotId
    targetPlot = Map.GetPlotByIndex(endPlotId)

    if not targetPlot then
        result.kind = "bad"
        result.failureKind = "invalidPlot"
        return result
    end

    local tParams = {
        [UnitOperationTypes.PARAM_X] = targetPlot:GetX(),
        [UnitOperationTypes.PARAM_Y] = targetPlot:GetY(),
    }

    if UnitManager.CanStartOperation(unit, UnitOperationTypes.SWAP_UNITS, nil, tParams) then
        result.kind = "swap"
        result.hasPath = true
        result.turns = { 1 }
        result.plots = { startPlotId, endPlotId }
        FinalizeMovementAnalysis(unit, targetPlot, result)
        return result
    end

    local pathInfo = UnitManager.GetMoveToPathEx(unit, endPlotId)
    result.plots = (pathInfo and pathInfo.plots) or {}
    result.turns = (pathInfo and pathInfo.turns) or {}
    result.obstacles = (pathInfo and pathInfo.obstacles) or {}
    result.entrancePortals = (pathInfo and pathInfo.entrancePortals) or {}
    result.exitPortals = (pathInfo and pathInfo.exitPortals) or {}

    if #result.plots > 1 then
        result.hasPath = true

        if IsImplicitRangedAttackTarget(unit, endPlotId) then
            result.kind = "attack"
            result.isImplicitRangedAttack = true
            FinalizeMovementAnalysis(unit, targetPlot, result)
            return result
        end

        local vis = PlayersVisibility[eLocalPlayer]
        if vis then
            for _, pid in ipairs(result.plots) do
                if not vis:IsVisible(pid) then
                    result.isPathInFog = true
                    break
                end
            end
        end

        local restricted, restrictedId = IsPlotPathRestrictedForUnit(result.plots, result.turns, unit)
        if restricted then
            result.isRestricted = true
            result.restrictedPlotId = restrictedId
        end

        if result.isQueued then
            result.kind = "queue"
        elseif result.isRestricted then
            result.kind = "bad"
        elseif result.isPathInFog then
            result.kind = "fow"
        else
            result.kind = "move"
        end
    else
        result.turns = { 1 }
        result.plots = { endPlotId }
        if startPlotId ~= endPlotId then
            result.kind = "bad"
        else
            result.kind = "same"
            result.isSamePlot = true
        end
    end

    FinalizeMovementAnalysis(unit, targetPlot, result)

    return result
end

---@param pathInfo MovementPathInfo?
---@param isExplicitSpeech boolean|nil
---@return string[]
function BuildMovementSpeech(pathInfo, isExplicitSpeech)
    local out = {}
    if not pathInfo then return out end

    if pathInfo.kind == "same" then
        return { Locale.Lookup("LOC_CAI_MOVEMENT_CURRENT_TILE") }
    end
    if pathInfo.kind == "swap" then
        return {
            Locale.Lookup("LOC_CAI_MOVEMENT_SWAP"),
            Locale.Lookup("LOC_CAI_MOVEMENT_THIS_TURN"),
        }
    end
    if pathInfo.kind == "attack" then
        if isExplicitSpeech then
            LuaEvents.CAISpeakCombatPreview()
            return false
        end
        return { Locale.Lookup("LOC_CAI_MOVEMENT_RANGED_ATTACK") }
    end

    if HasImmediateCombat(pathInfo) then
        if isExplicitSpeech then
            LuaEvents.CAISpeakCombatPreview()
            return false
        end
    end

    if pathInfo.kind == "bad" then
        AddLine(out, FormatFailure(pathInfo))
        if not pathInfo.hasPath then
            return out
        end
    elseif pathInfo.kind == "queue" then
        AddLine(out, Locale.Lookup("LOC_CAI_MOVEMENT_QUEUED"))
    end

    if pathInfo.kind ~= "bad" then
        AddLine(out, FormatArrivalTurn(pathInfo.arrivalTurn))
    end

    AddLine(out, FormatObstacleCount(pathInfo.obstacles and #pathInfo.obstacles or 0))

    if pathInfo.usesPortal then
        AddLine(out, Locale.Lookup("LOC_CAI_MOVEMENT_USES_TUNNEL"))
    end

    if pathInfo.endsInZOC then
        AddLine(out, Locale.Lookup("LOC_CAI_MOVEMENT_ENDS_AT_ZOC"))
    elseif pathInfo.intersectsZOC then
        AddLine(out, Locale.Lookup("LOC_CAI_MOVEMENT_INTERSECTS_ZOC"))
    end

    if pathInfo.willDeclareWar then
        AddLine(out, Locale.Lookup("LOC_CAI_MOVEMENT_WILL_DECLARE_WAR"))
    end

    AddLine(out, FormatAttackAfterMove(pathInfo))

    if HasImmediateCombat(pathInfo) then
        AddLine(out, Locale.Lookup("LOC_CAI_MOVEMENT_ENEMY_AT_DESTINATION"))
    end

    if pathInfo.isRestricted then
        AddLine(out, Locale.Lookup("LOC_CAI_MOVEMENT_BLOCKED"))
    end

    if isExplicitSpeech
        and pathInfo.kind == "fow" then
        if pathInfo.entersUnrevealed then
            AddLine(out, Locale.Lookup("LOC_CAI_MOVEMENT_PATH_UNEXPLORED"))
        else
            AddLine(out, Locale.Lookup("LOC_CAI_MOVEMENT_PATH_FOG"))
        end
    end

    if isExplicitSpeech
        and (not HasImmediateCombat(pathInfo) and (not HasDelayedCombat(pathInfo) or pathInfo.isQueued))
        and pathInfo.visiblePathText ~= nil
        and pathInfo.visiblePathText ~= "" then
        AddLine(out, Locale.Lookup("LOC_CAI_MOVEMENT_PATH_STEPS", pathInfo.visiblePathText))
    end

    if isExplicitSpeech and pathInfo.entersUnrevealed then
        AddLine(out, Locale.Lookup("LOC_CAI_MOVEMENT_THEN_UNEXPLORED"))
    end

    return out
end

-- ===========================================================================
-- Interface-specific plot preview helpers
-- ===========================================================================

include("interfaceTargetHelpers_CAI")
include("cityManagementInterfaceHelpers_CAI")

InterfaceInfoHelpers = InterfaceInfoHelpers or {}
local function BuildCombatPreviewInterfaceInfo(plot, isExplicitSpeech)
    if isExplicitSpeech then
        LuaEvents.CAISpeakCombatPreview()
        return false
    end

    return nil
end

local function BuildMoveToInterfaceInfo(plot, isExplicitSpeech)
    local unit = UI.GetHeadSelectedUnit()
    if not unit or not plot then return nil end
    return BuildMovementSpeech(BuildMovementPathInfo(unit, plot:GetIndex(), false, true), isExplicitSpeech)
end

local function GetDistrictPlacementTargets(city, districtHash)
    if city == nil or districtHash == nil then return nil, nil, nil end

    local district = GameInfo.Districts[districtHash]
    if district == nil then return nil, nil, nil end

    local validOwned = {}
    local buildParams = {
        [CityOperationTypes.PARAM_DISTRICT_TYPE] = districtHash,
    }
    local buildResults = CityManager.GetOperationTargets(city, CityOperationTypes.BUILD, buildParams)
    local buildPlots = buildResults and buildResults[CityOperationResults.PLOTS]
    if buildPlots ~= nil then
        for _, plotId in ipairs(buildPlots) do
            validOwned[plotId] = true
        end
    end

    local validPurchasable = {}
    local purchaseParams = {
        [CityCommandTypes.PARAM_PLOT_PURCHASE] = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_PLOT_PURCHASE),
    }
    local purchaseResults = CityManager.GetCommandTargets(city, CityCommandTypes.PURCHASE, purchaseParams)
    local purchasePlots = purchaseResults and purchaseResults[CityCommandResults.PLOTS]
    if purchasePlots ~= nil then
        for _, plotId in ipairs(purchasePlots) do
            local plot = Map.GetPlotByIndex(plotId)
            if plot ~= nil and not validOwned[plotId] and
                plot:CanHaveDistrict(district.Index, city:GetOwner(), city:GetID()) then
                validPurchasable[plotId] = true
            end
        end
    end

    return district, validOwned, validPurchasable
end

local function GetWonderPlacementTargets(city, buildingHash)
    if city == nil or buildingHash == nil then return nil, nil, nil end

    local building = GameInfo.Buildings[buildingHash]
    if building == nil then return nil, nil, nil end

    local validOwned = {}
    local buildParams = {
        [CityOperationTypes.PARAM_BUILDING_TYPE] = buildingHash,
    }
    local buildResults = CityManager.GetOperationTargets(city, CityOperationTypes.BUILD, buildParams)
    local buildPlots = buildResults and buildResults[CityOperationResults.PLOTS]
    if buildPlots ~= nil then
        for _, plotId in ipairs(buildPlots) do
            validOwned[plotId] = true
        end
    end

    local validPurchasable = {}
    local purchaseParams = {
        [CityCommandTypes.PARAM_PLOT_PURCHASE] = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_PLOT_PURCHASE),
    }
    local purchaseResults = CityManager.GetCommandTargets(city, CityCommandTypes.PURCHASE, purchaseParams)
    local purchasePlots = purchaseResults and purchaseResults[CityCommandResults.PLOTS]
    if purchasePlots ~= nil then
        for _, plotId in ipairs(purchasePlots) do
            local plot = Map.GetPlotByIndex(plotId)
            if plot ~= nil and not validOwned[plotId] and
                plot:CanHaveWonder(building.Index, city:GetOwner(), city:GetID()) then
                validPurchasable[plotId] = true
            end
        end
    end

    return building, validOwned, validPurchasable
end

local function BuildDistrictPlacementInterfaceInfo(plot)
    if plot == nil then return nil end

    local city = UI.GetHeadSelectedCity()
    local districtHash = UI.GetInterfaceModeParameter(CityOperationTypes.PARAM_DISTRICT_TYPE)
    local district, validOwned, validPurchasable = GetDistrictPlacementTargets(city, districtHash)
    if district == nil or validOwned == nil or validPurchasable == nil then return nil end

    local plotId = plot:GetIndex()
    local isOwnedValid = validOwned[plotId] == true
    local isPurchasableValid = validPurchasable[plotId] == true

    local lines = {}
    if isOwnedValid or isPurchasableValid then
        table.insert(lines, Locale.Lookup("LOC_CAI_PLOT_INTERFACE_VALID"))
        table.insert(lines,
            Locale.Lookup(isOwnedValid and "LOC_CAI_PLOT_INTERFACE_OWNED" or "LOC_CAI_PLOT_INTERFACE_PURCHASABLE"))

        local _, bonusTooltip, requiredText = GetAdjacentYieldBonusString(district.Index, city, plot)
        if bonusTooltip ~= nil and bonusTooltip ~= "" then
            table.insert(lines, bonusTooltip)
        else
            table.insert(lines, Locale.Lookup("LOC_CAI_PLOT_NO_PLACEMENT_BONUS"))
        end
        if requiredText ~= nil and requiredText ~= "" then
            table.insert(lines, requiredText)
        end
    else
        table.insert(lines, Locale.Lookup("LOC_CAI_PLOT_INTERFACE_INVALID"))
    end

    return lines
end

local function BuildWonderPlacementInterfaceInfo(plot)
    if plot == nil then return nil end

    local city = UI.GetHeadSelectedCity()
    local buildingHash = UI.GetInterfaceModeParameter(CityOperationTypes.PARAM_BUILDING_TYPE)
    local building, validOwned, validPurchasable = GetWonderPlacementTargets(city, buildingHash)
    if building == nil or validOwned == nil or validPurchasable == nil then return nil end

    local plotId = plot:GetIndex()
    local isOwnedValid = validOwned[plotId] == true
    local isPurchasableValid = validPurchasable[plotId] == true

    local lines = {}
    if isOwnedValid or isPurchasableValid then
        table.insert(lines, Locale.Lookup("LOC_CAI_PLOT_INTERFACE_VALID"))
        table.insert(lines,
            Locale.Lookup(isOwnedValid and "LOC_CAI_PLOT_INTERFACE_OWNED" or "LOC_CAI_PLOT_INTERFACE_PURCHASABLE"))
    else
        table.insert(lines, Locale.Lookup("LOC_CAI_PLOT_INTERFACE_INVALID"))
    end

    return lines
end

local function BuildTargetValidityInterfaceInfo(plot)
    if plot == nil then return nil end

    local target = CAIInterfaceTargets.GetTargetAtPlot(plot)
    if target == nil then
        return { Locale.Lookup("LOC_CAI_PLOT_INTERFACE_INVALID_TARGET") }
    end

    local lines = { Locale.Lookup("LOC_CAI_PLOT_INTERFACE_VALID") }
    if target.LabelKey ~= nil and target.LabelKey ~= "" then
        table.insert(lines, target.LabelKey)
    end
    if target.Kind == CAIInterfaceTargets.KindUnit then
        table.insert(lines, Locale.Lookup("LOC_CAI_FORMATION_TARGET"))
    end

    return lines
end

local function BuildCityManagementInterfaceInfo(plot)
    if plot == nil or CAICityManagementInterface == nil or CAICityManagementInterface.BuildSpeechTextOrInvalid == nil then
        return nil
    end

    return { CAICityManagementInterface.BuildSpeechTextOrInvalid(plot) }
end

InterfaceInfoHelpers[InterfaceModeTypes.MOVE_TO] = BuildMoveToInterfaceInfo
InterfaceInfoHelpers[InterfaceModeTypes.CITY_MANAGEMENT] = BuildCityManagementInterfaceInfo
InterfaceInfoHelpers[InterfaceModeTypes.RANGE_ATTACK] = BuildCombatPreviewInterfaceInfo
InterfaceInfoHelpers[InterfaceModeTypes.CITY_RANGE_ATTACK] = BuildCombatPreviewInterfaceInfo
InterfaceInfoHelpers[InterfaceModeTypes.DISTRICT_RANGE_ATTACK] = BuildCombatPreviewInterfaceInfo
InterfaceInfoHelpers[InterfaceModeTypes.AIR_ATTACK] = BuildCombatPreviewInterfaceInfo
InterfaceInfoHelpers[InterfaceModeTypes.DISTRICT_PLACEMENT] = BuildDistrictPlacementInterfaceInfo
InterfaceInfoHelpers[InterfaceModeTypes.BUILDING_PLACEMENT] = BuildWonderPlacementInterfaceInfo
InterfaceInfoHelpers[InterfaceModeTypes.DEPLOY] = BuildTargetValidityInterfaceInfo
InterfaceInfoHelpers[InterfaceModeTypes.REBASE] = BuildTargetValidityInterfaceInfo
InterfaceInfoHelpers[InterfaceModeTypes.TELEPORT_TO_CITY] = BuildTargetValidityInterfaceInfo
InterfaceInfoHelpers[InterfaceModeTypes.BUILD_IMPROVEMENT_ADJACENT] = BuildTargetValidityInterfaceInfo
InterfaceInfoHelpers[InterfaceModeTypes.FORM_CORPS] = BuildTargetValidityInterfaceInfo
InterfaceInfoHelpers[InterfaceModeTypes.FORM_ARMY] = BuildTargetValidityInterfaceInfo
InterfaceInfoHelpers[InterfaceModeTypes.AIRLIFT] = BuildTargetValidityInterfaceInfo
InterfaceInfoHelpers[InterfaceModeTypes.PARADROP] = BuildTargetValidityInterfaceInfo
InterfaceInfoHelpers[InterfaceModeTypes.PRIORITY_TARGET] = BuildTargetValidityInterfaceInfo
InterfaceInfoHelpers[InterfaceModeTypes.MOVE_JUMP] = BuildTargetValidityInterfaceInfo
InterfaceInfoHelpers[InterfaceModeTypes.SACRIFICE_SELECTION] = BuildTargetValidityInterfaceInfo
InterfaceInfoHelpers[InterfaceModeTypes.KILL_WEAKER_UNIT] = BuildTargetValidityInterfaceInfo
InterfaceInfoHelpers[InterfaceModeTypes.TRANSFORM_UNIT] = BuildTargetValidityInterfaceInfo
InterfaceInfoHelpers[InterfaceModeTypes.RESTORE_UNIT_MOVES] = BuildTargetValidityInterfaceInfo
InterfaceInfoHelpers[InterfaceModeTypes.NAVAL_GOLD_RAID] = BuildTargetValidityInterfaceInfo

local function ResolveActiveInterfacePlot(plot)
    if plot ~= nil then return plot end

    local plotID = -1
    if CAICursor ~= nil and CAICursor.GetPlotId ~= nil then
        plotID = CAICursor:GetPlotId()
    end

    if not Map.IsPlot(plotID) then
        plotID = UI.GetCursorPlotID()
    end

    if Map.IsPlot(plotID) then
        return Map.GetPlotByIndex(plotID)
    end

    return nil
end

-- ===========================================================================
-- LENS INFO HELPERS
-- ===========================================================================

local LAYER_SETTLER = UILens.CreateLensLayerHash("Hex_Coloring_Water_Availablity")
local LAYER_APPEAL = UILens.CreateLensLayerHash("Hex_Coloring_Appeal_Level")
local LAYER_GOVERNMENT = UILens.CreateLensLayerHash("Hex_Coloring_Government")
local LAYER_POWER = UILens.CreateLensLayerHash("Power_Lens")
local LAYER_TOURISM = UILens.CreateLensLayerHash("Tourist_Tokens")
local LAYER_LOYALTY = UILens.CreateLensLayerHash("Cultural_Identity_Lens")
local LAYER_RELIGION = UILens.CreateLensLayerHash("Hex_Coloring_Religion")

local LensInfoHelpers = {}

local function BuildSettlerLensPlotInfo(plot)
    if plot:IsWater() then
        return nil
    end

    local lines = {}

    if plot:IsFreshWater() then
        lines[#lines + 1] = Locale.Lookup("LOC_HUD_UNIT_PANEL_TOOLTIP_FRESH_WATER")
    elseif plot:IsCoastalLand() then
        lines[#lines + 1] = Locale.Lookup("LOC_HUD_UNIT_PANEL_TOOLTIP_COASTAL_WATER")
    else
        lines[#lines + 1] = Locale.Lookup("LOC_HUD_UNIT_PANEL_TOOLTIP_NO_WATER")
    end

    if type(IsExpansion1Active) == "function" and IsExpansion1Active() then
        local loyaltyPlots = Map.GetContinentPlotsLoyalty()
        if loyaltyPlots ~= nil then
            local loyaltyValue = loyaltyPlots[plot:GetIndex()]
            if loyaltyValue ~= nil then
                local numeric = tonumber(loyaltyValue) or 0
                local sign = numeric > 0 and ("+" .. tostring(numeric)) or tostring(numeric)
                lines[#lines + 1] = Locale.Lookup("LOC_CAI_WORLD_SCANNER_SETTLER_LOYALTY_VALUE", sign)
            end
        end
    end

    if type(IsExpansion2Active) == "function" and IsExpansion2Active() then
        if RiverManager ~= nil and RiverManager.CanBeFlooded ~= nil and RiverManager.CanBeFlooded(plot) then
            lines[#lines + 1] = Locale.Lookup("LOC_CAI_WORLD_SCANNER_SETTLER_DISASTER_FLOOD")
        end

        if MapFeatureManager ~= nil and MapFeatureManager.CanSufferEruption ~= nil and MapFeatureManager.CanSufferEruption(plot) then
            lines[#lines + 1] = Locale.Lookup("LOC_CAI_WORLD_SCANNER_SETTLER_DISASTER_VOLCANO")
        end

        if TerrainManager ~= nil and TerrainManager.GetCoastalLowlandType ~= nil and TerrainManager.IsProtected ~= nil then
            if not TerrainManager.IsProtected(plot) then
                local coastalLowlandType = TerrainManager.GetCoastalLowlandType(plot)
                if coastalLowlandType == 0 then
                    lines[#lines + 1] = Locale.Lookup("LOC_COASTAL_LOWLAND_1M_NAME")
                elseif coastalLowlandType == 1 then
                    lines[#lines + 1] = Locale.Lookup("LOC_COASTAL_LOWLAND_2M_NAME")
                elseif coastalLowlandType == 2 then
                    lines[#lines + 1] = Locale.Lookup("LOC_COASTAL_LOWLAND_3M_NAME")
                end
            end
        end
    end

    return #lines > 0 and lines or nil
end

local function BuildGovernmentLensPlotInfo(plot)
    local ownerID = plot:GetOwner()
    if ownerID == nil or ownerID < 0 then
        return nil
    end

    local player = Players[ownerID]
    if player == nil then
        return nil
    end

    if player.IsFreeCities ~= nil and player:IsFreeCities() then
        return Locale.Lookup("LOC_CIVILIZATION_FREE_CITIES_NAME")
    end

    local culture = player.GetCulture ~= nil and player:GetCulture() or nil
    if culture == nil then
        return nil
    end

    if culture.IsInAnarchy ~= nil and culture:IsInAnarchy() then
        return Locale.Lookup("LOC_GOVERNMENT_ANARCHY_NAME")
    end

    local governmentId = culture.GetCurrentGovernment ~= nil and culture:GetCurrentGovernment() or -1
    if governmentId == nil or governmentId < 0 then
        return nil
    end

    local government = GameInfo.Governments[governmentId]
    if government == nil then
        return nil
    end

    return Locale.Lookup(government.Name)
end

local function BuildPowerLensPlotInfo(plot)
    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == nil or localPlayerID < 0 then
        return nil
    end

    local city = Cities.GetPlotPurchaseCity(plot)
    if city == nil then
        city = Cities.GetCityInPlot(plot:GetX(), plot:GetY())
    end
    if city == nil or city:GetOwner() ~= localPlayerID then
        return nil
    end

    local cityPower = city.GetPower ~= nil and city:GetPower() or nil
    if cityPower == nil then
        return nil
    end

    local lines = {}

    local plotsProvidingPower = cityPower.GetPlotsProvidingPower ~= nil and cityPower:GetPlotsProvidingPower() or nil
    if plotsProvidingPower ~= nil then
        local powerString = plotsProvidingPower[plot:GetIndex()]
        if powerString ~= nil then
            lines[#lines + 1] = Locale.Lookup("LOC_CAI_LENS_POWER_SOURCE", powerString)
        end
    end

    local isFullyPowered = cityPower.IsFullyPowered ~= nil and cityPower:IsFullyPowered() or false
    local requiredPower = cityPower.GetRequiredPower ~= nil and cityPower:GetRequiredPower() or 0
    if requiredPower > 0 then
        if isFullyPowered then
            lines[#lines + 1] = Locale.Lookup("LOC_CAI_LENS_POWER_CITY_POWERED")
        else
            lines[#lines + 1] = Locale.Lookup("LOC_CAI_LENS_POWER_CITY_UNPOWERED")
        end
    end

    return #lines > 0 and lines or nil
end

local function BuildTourismLensPlotInfo(plot)
    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == nil or localPlayerID < 0 then
        return nil
    end

    local localPlayer = Players[localPlayerID]
    if localPlayer == nil or localPlayer.GetCulture == nil then
        return nil
    end

    local culture = localPlayer:GetCulture()
    if culture == nil then
        return nil
    end

    local plotIndex = plot:GetIndex()
    local tourismValue = culture.GetTourismAt ~= nil and culture:GetTourismAt(plotIndex) or 0
    if tourismValue <= 0 then
        return nil
    end

    local touristCount = culture.GetTouristsAt ~= nil and culture:GetTouristsAt(plotIndex) or 0
    return Locale.Lookup("LOC_CAI_WORLD_SCANNER_TOURISM_ITEM", tostring(tourismValue), tostring(touristCount))
end

local function BuildAppealLensPlotInfo(plot)
    if plot:IsWater() then
        return nil
    end

    if not GameCapabilities.HasCapability("CAPABILITY_LENS_APPEAL") then
        return nil
    end

    local appeal = plot:GetAppeal()
    for row in GameInfo.AppealHousingChanges() do
        if appeal >= row.MinimumValue then
            return Locale.Lookup("LOC_CAI_LENS_APPEAL", Locale.Lookup(row.Description), appeal)
        end
    end

    return nil
end

local function BuildLoyaltyLensPlotInfo(plot)
    local ownerID = plot:GetOwner()
    if ownerID == nil or ownerID < 0 then
        return nil
    end

    local city = Cities.GetPlotPurchaseCity(plot)
    if city == nil then
        city = Cities.GetCityInPlot(plot:GetX(), plot:GetY())
    end
    if city == nil or city:GetOwner() ~= ownerID then
        return nil
    end

    local identity = city.GetCulturalIdentity ~= nil and city:GetCulturalIdentity() or nil
    if identity == nil then
        return nil
    end

    local lines = {}

    if identity.IsAlwaysFullyLoyal ~= nil and identity:IsAlwaysFullyLoyal() then
        lines[#lines + 1] = Locale.Lookup("LOC_CAI_LENS_LOYALTY_ALWAYS_LOYAL")
        return lines
    end

    local loyaltyLevel = identity.GetLoyaltyLevel ~= nil and identity:GetLoyaltyLevel() or nil
    local loyalty = identity.GetLoyalty ~= nil and identity:GetLoyalty() or 0
    local maxLoyalty = identity.GetMaxLoyalty ~= nil and identity:GetMaxLoyalty() or 0
    if loyaltyLevel ~= nil then
        local levelName = GameInfo.LoyaltyLevels and GameInfo.LoyaltyLevels[loyaltyLevel]
        local levelText = levelName ~= nil and levelName.Name ~= nil and Locale.Lookup(levelName.Name) or
            tostring(loyaltyLevel)
        lines[#lines + 1] = Locale.Lookup("LOC_CAI_LENS_LOYALTY_LEVEL", levelText, math.floor(loyalty),
            math.floor(maxLoyalty))
    end

    local perTurn = identity.GetLoyaltyPerTurn ~= nil and identity:GetLoyaltyPerTurn() or 0
    local sign = perTurn > 0 and ("+" .. tostring(math.floor(perTurn))) or tostring(math.floor(perTurn))
    lines[#lines + 1] = Locale.Lookup("LOC_CAI_LENS_LOYALTY_PER_TURN", sign)

    if IdentityConversionOutcome ~= nil then
        local outcome = identity.GetConversionOutcome ~= nil and identity:GetConversionOutcome() or nil
        if outcome == IdentityConversionOutcome.LOSING_LOYALTY then
            local transferPlayer = identity.GetPotentialTransferPlayer ~= nil and identity:GetPotentialTransferPlayer() or
                nil
            if transferPlayer ~= nil and transferPlayer >= 0 then
                local config = PlayerConfigurations[transferPlayer]
                local playerName = config ~= nil and config.GetCivilizationShortDescription ~= nil
                    and Locale.Lookup(config:GetCivilizationShortDescription()) or tostring(transferPlayer)
                lines[#lines + 1] = Locale.Lookup("LOC_CAI_LENS_LOYALTY_AT_RISK", playerName)
            end
        end
    end

    return #lines > 0 and lines or nil
end

local function GetReligionName(religionType)
    if religionType == nil or religionType < 0 then
        return nil
    end

    local gameReligion = Game.GetReligion ~= nil and Game.GetReligion() or nil
    if gameReligion ~= nil and gameReligion.GetName ~= nil then
        local name = gameReligion:GetName(religionType)
        if name ~= nil and name ~= "" then
            return Locale.Lookup(name)
        end
    end

    return nil
end

local function BuildReligionLensPlotInfo(plot)
    local city = Cities.GetPlotPurchaseCity(plot)
    if city == nil then
        city = Cities.GetCityInPlot(plot:GetX(), plot:GetY())
    end
    if city == nil then
        return nil
    end

    local cityReligion = city.GetReligion ~= nil and city:GetReligion() or nil
    if cityReligion == nil then
        return nil
    end

    local majorityType = cityReligion.GetMajorityReligion ~= nil and cityReligion:GetMajorityReligion() or -1

    local religionsInCity = cityReligion.GetReligionsInCity ~= nil and cityReligion:GetReligionsInCity() or nil
    if religionsInCity == nil then
        return Locale.Lookup("LOC_CAI_LENS_RELIGION_NO_MAJORITY")
    end

    local sorted = {}
    for _, entry in ipairs(religionsInCity) do
        local relType = entry.Religion
        local followers = entry.Followers or 0
        if relType ~= nil and relType >= 0 and followers > 0 then
            local relName = GetReligionName(relType)
            if relName ~= nil then
                sorted[#sorted + 1] = { type = relType, name = relName, followers = followers }
            end
        end
    end

    if #sorted == 0 then
        return Locale.Lookup("LOC_CAI_LENS_RELIGION_NO_MAJORITY")
    end

    table.sort(sorted, function(a, b) return a.followers > b.followers end)

    local lines = {}
    for _, rel in ipairs(sorted) do
        if rel.type == majorityType then
            lines[#lines + 1] = Locale.Lookup("LOC_CAI_LENS_RELIGION_MAJORITY_FOLLOWERS", rel.name, rel.followers)
        else
            lines[#lines + 1] = Locale.Lookup("LOC_CAI_LENS_RELIGION_FOLLOWERS", rel.name, rel.followers)
        end
    end

    return lines
end

LensInfoHelpers[LAYER_SETTLER] = BuildSettlerLensPlotInfo
LensInfoHelpers[LAYER_APPEAL] = BuildAppealLensPlotInfo
LensInfoHelpers[LAYER_GOVERNMENT] = BuildGovernmentLensPlotInfo
LensInfoHelpers[LAYER_POWER] = BuildPowerLensPlotInfo
LensInfoHelpers[LAYER_TOURISM] = BuildTourismLensPlotInfo
LensInfoHelpers[LAYER_RELIGION] = BuildReligionLensPlotInfo

if type(IsExpansion1Active) == "function" and IsExpansion1Active() then
    LensInfoHelpers[LAYER_LOYALTY] = BuildLoyaltyLensPlotInfo
end

local function GetActiveLensHelper()
    for layerHash, helper in pairs(LensInfoHelpers) do
        if UILens.IsLayerOn(layerHash) then
            return helper
        end
    end
    return nil
end

function GetActiveLensPlotInfo(plot)
    if plot == nil then return nil end
    local helper = GetActiveLensHelper()
    if helper == nil then return nil end
    return helper(plot)
end

local function SpeakActiveLensPlotInfo(plot)
    local resolvedPlot = ResolveActiveInterfacePlot(plot)
    if resolvedPlot == nil then
        return false
    end

    local lines = GetActiveLensPlotInfo(resolvedPlot)
    if lines == nil then
        return false
    end

    if type(lines) == "string" then
        if lines == "" then
            return false
        end
        Speak(lines)
        return true
    end

    if #lines > 0 then
        Speak(table.concat(lines, ", "))
        return true
    end

    return false
end

-- ===========================================================================
-- INTERFACE + LENS PUBLIC API
-- ===========================================================================

function GetActiveInterfacePlotInfo(plot)
    if plot == nil then return nil end
    local helper = InterfaceInfoHelpers[UI.GetInterfaceMode()]
    if helper == nil then return nil end
    local lines = helper(plot, false)
    if lines == false then return nil end
    return lines
end

function SpeakActiveInterfacePlotInfo(plot)
    local resolvedPlot = ResolveActiveInterfacePlot(plot)
    if resolvedPlot == nil then
        Speak(Locale.Lookup("LOC_CAI_NO_INTERFACE_INFO"))
        return false
    end

    local helper = InterfaceInfoHelpers[UI.GetInterfaceMode()]
    if helper == nil then
        if SpeakActiveLensPlotInfo(resolvedPlot) then
            return true
        end
        Speak(Locale.Lookup("LOC_CAI_NO_INTERFACE_INFO"))
        return false
    end

    local lines = helper(resolvedPlot, true)
    if lines == false then
        return true
    end

    if type(lines) == "string" then
        if lines == "" then
            Speak(Locale.Lookup("LOC_CAI_NO_INTERFACE_INFO"))
            return false
        end

        Speak(lines)
        return true
    end

    if lines ~= nil and #lines > 0 then
        Speak(table.concat(lines, ", "))
        return true
    end

    Speak(Locale.Lookup("LOC_CAI_NO_INTERFACE_INFO"))
    return false
end

-- ===========================================================================
-- EVENT WIRING
-- ===========================================================================

LuaEvents.Tutorial_AddUnitMoveRestriction.Add(OnTutorial_AddUnitMoveRestriction)
LuaEvents.Tutorial_RemoveUnitMoveRestrictions.Add(OnTutorial_RemoveUnitMoveRestrictions)
LuaEvents.Tutorial_ConstrainMovement.Add(OnTutorial_ConstrainMovement)
LuaEvents.Tutorial_AddUnitHexRestriction.Add(OnTutorial_AddUnitHexRestriction)
LuaEvents.Tutorial_RemoveUnitHexRestriction.Add(OnTutorial_RemoveUnitHexRestriction)
LuaEvents.Tutorial_ClearAllHexMoveRestrictions.Add(OnTutorial_ClearAllUnitHexRestrictions)
