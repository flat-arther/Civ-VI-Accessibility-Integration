-- ===========================================================================
-- Unit movement helpers (extracted from vanilla WorldInput so other contexts
-- can reuse path-info / movement-speech without depending on WorldInput state).
-- ===========================================================================
include("AdjacencyBonusSupport")

---@class MovementPathInfo
---@field kind string
---@field turns number[]
---@field plots number[]
---@field steps PathStep[]
---@field segments PathSegment[]
---@field obstacles number[]
---@field isRestricted boolean
---@field restrictedPlotId number|nil
---@field isPathInFog boolean
---@field enemyAtEnd boolean
---@field isQueued boolean
---@field destPlot integer
---@field isImplicitRangedAttack boolean
---@field isSamePlot boolean
---@field entrancePortals number[]
---@field exitPortals number[]

---@class PathStep
---@field fromPlotId number
---@field toPlotId number
---@field fromX number
---@field fromY number
---@field toX number
---@field toY number
---@field dir string|nil
---@field turn number
---@field isTurnBreak boolean
---@field crossesObstacle boolean
---@field isFog boolean
---@field isRestricted boolean
---@field isDestination boolean

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
-- PATH STEP ANALYSIS
-- ===========================================================================

local function GetSquareDirection(dx, dy)
    if dx == 0 and dy > 0 then return "north" end
    if dx == 0 and dy < 0 then return "south" end
    if dx > 0 and dy == 0 then return "east" end
    if dx < 0 and dy == 0 then return "west" end

    if dx > 0 and dy > 0 then return "northeast" end
    if dx < 0 and dy > 0 then return "northwest" end
    if dx > 0 and dy < 0 then return "southeast" end
    if dx < 0 and dy < 0 then return "southwest" end

    return nil
end

local function BuildAnnotatedSteps(pathInfo, unit)
    local steps = {}
    if not pathInfo or not pathInfo.plots or #pathInfo.plots < 2 then
        return steps
    end

    local vis = PlayersVisibility[Game.GetLocalPlayer()]
    local obstacleSet = {}
    for _, pid in ipairs(pathInfo.obstacles or {}) do
        obstacleSet[pid] = true
    end

    for i = 2, #pathInfo.plots do
        local fromId = pathInfo.plots[i - 1]
        local toId = pathInfo.plots[i]
        local a = Map.GetPlotByIndex(fromId)
        local b = Map.GetPlotByIndex(toId)

        local dx = b:GetX() - a:GetX()
        local dy = b:GetY() - a:GetY()

        steps[#steps + 1] = {
            fromPlotId      = fromId,
            toPlotId        = toId,
            fromX           = a:GetX(),
            fromY           = a:GetY(),
            toX             = b:GetX(),
            toY             = b:GetY(),
            dir             = GetSquareDirection(dx, dy),
            turn            = (pathInfo.turns and pathInfo.turns[i]) or 1,
            isTurnBreak     = (i > 2 and pathInfo.turns and pathInfo.turns[i] ~= pathInfo.turns[i - 1]) or false,
            crossesObstacle = obstacleSet[fromId] or obstacleSet[toId] or false,
            isFog           = vis and not vis:IsVisible(toId) or false,
            isRestricted    = pathInfo.restrictedPlotId == toId,
            isDestination   = (i == #pathInfo.plots),
        }
    end

    return steps
end

local function CompressPathSteps(steps)
    local segments = {}
    if not steps or #steps == 0 then
        return segments
    end

    local current = {
        dir            = steps[1].dir,
        count          = 1,
        startIndex     = 1,
        endIndex       = 1,
        hasTurnBreak   = steps[1].isTurnBreak,
        hasObstacle    = steps[1].crossesObstacle,
        hasFog         = steps[1].isFog,
        hasRestriction = steps[1].isRestricted,
    }

    local function sameBucket(a, b)
        return a.dir == b.dir
            and a.isTurnBreak == b.isTurnBreak
            and a.crossesObstacle == b.crossesObstacle
            and a.isFog == b.isFog
            and a.isRestricted == b.isRestricted
    end

    for i = 2, #steps do
        local s = steps[i]
        local bucket = {
            dir             = s.dir,
            isTurnBreak     = s.isTurnBreak,
            crossesObstacle = s.crossesObstacle,
            isFog           = s.isFog,
            isRestricted    = s.isRestricted,
        }

        local currentBucket = {
            dir             = current.dir,
            isTurnBreak     = current.hasTurnBreak,
            crossesObstacle = current.hasObstacle,
            isFog           = current.hasFog,
            isRestricted    = current.hasRestriction,
        }

        if sameBucket(bucket, currentBucket) then
            current.count = current.count + 1
            current.endIndex = i
        else
            segments[#segments + 1] = current
            current = {
                dir            = s.dir,
                count          = 1,
                startIndex     = i,
                endIndex       = i,
                hasTurnBreak   = s.isTurnBreak,
                hasObstacle    = s.crossesObstacle,
                hasFog         = s.isFog,
                hasRestriction = s.isRestricted,
            }
        end
    end

    segments[#segments + 1] = current
    return segments
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
        steps                  = nil,
        segments               = nil,
        obstacles              = {},
        isRestricted           = false,
        restrictedPlotId       = nil,
        isPathInFog            = false,
        enemyAtEnd             = false,
        isQueued               = false,
        destPlot               = -1,
        isImplicitRangedAttack = false,
        isSamePlot             = false,
        entrancePortals        = {},
        exitPortals            = {},
    }

    local eLocalPlayer = Game.GetLocalPlayer()
    local startPlotId = unit:GetPlotId()

    if showQueuedPath then
        local queued = UnitManager.GetQueuedDestination(unit)
        if queued then
            endPlotId = queued
            result.isQueued = true
        end
    end

    result.destPlot = endPlotId

    if startPlotId == endPlotId then
        result.kind = "same"
        result.isSamePlot = true
        return result
    end

    local plot = Map.GetPlotByIndex(endPlotId)
    if not plot then
        result.kind = "bad"
        return result
    end

    local tParams = {
        [UnitOperationTypes.PARAM_X] = plot:GetX(),
        [UnitOperationTypes.PARAM_Y] = plot:GetY(),
    }

    if UnitManager.CanStartOperation(unit, UnitOperationTypes.SWAP_UNITS, nil, tParams) then
        result.kind = "swap"
        result.turns = { 1 }
        result.plots = { startPlotId, endPlotId }
        return result
    end

    local pathInfo = UnitManager.GetMoveToPathEx(unit, endPlotId)
    if not pathInfo or not pathInfo.plots then
        result.kind = "bad"
        return result
    end

    result.plots = pathInfo.plots
    result.turns = pathInfo.turns
    result.obstacles = pathInfo.obstacles or {}
    result.entrancePortals = pathInfo.entrancePortals or {}
    result.exitPortals = pathInfo.exitPortals or {}

    if #result.plots <= 1 then
        result.kind = "bad"
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

    if unit:GetMovesRemaining() > 0 then
        local results = UnitManager.GetOperationTargets(unit, UnitOperationTypes.RANGE_ATTACK)
        if results and results[UnitOperationResults.PLOTS] then
            for i, modifier in ipairs(results[UnitOperationResults.MODIFIERS]) do
                if modifier == UnitOperationResults.MODIFIER_IS_TARGET then
                    if results[UnitOperationResults.PLOTS][i] == endPlotId then
                        result.kind = "attack"
                        result.isImplicitRangedAttack = true
                        return result
                    end
                end
            end
        end
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

    local endPlot = Map.GetPlotByIndex(endPlotId)
    if endPlot and vis then
        local units = Units.GetUnitsInPlotLayerID(endPlot:GetX(), endPlot:GetY(), MapLayers.ANY)
        for _, u in ipairs(units) do
            if u:GetOwner() ~= eLocalPlayer and vis:IsUnitVisible(u) then
                result.enemyAtEnd = true
                break
            end
        end
    end

    if showDetails and (result.plots and #result.plots > 1 and not result.isImplicitRangedAttack) then
        result.steps = BuildAnnotatedSteps(result, unit)
        result.segments = CompressPathSteps(result.steps)
    end

    return result
end

---@param pathInfo MovementPathInfo?
---@return string[]
function BuildMovementSpeech(pathInfo)
    local out = {}
    if not pathInfo then return out end

    if pathInfo.kind == "same" then
        return { "Current tile." }
    end
    if pathInfo.kind == "swap" then
        return { "Swap with unit. 1 turn." }
    end
    if pathInfo.kind == "attack" then
        return { "Ranged attack." }
    end

    if pathInfo.kind == "bad" then
        table.insert(out, "Cannot move there.")
    elseif pathInfo.kind == "fow" then
        table.insert(out, "Path enters fog of war.")
    elseif pathInfo.kind == "queue" then
        table.insert(out, "Queued path.")
    else
        table.insert(out, "Valid move.")
    end

    if pathInfo.obstacles and #pathInfo.obstacles > 0 then
        table.insert(out, "Crosses " .. #pathInfo.obstacles ..
            " " .. (#pathInfo.obstacles > 1 and "obstacles" or "obstacle"))
    end

    if pathInfo.turns and #pathInfo.turns > 0 then
        table.insert(out, #pathInfo.turns .. " turns.")
    end

    if pathInfo.enemyAtEnd then
        table.insert(out, "Enemy at destination.")
    end

    if pathInfo.isRestricted then
        table.insert(out, "Movement blocked.")
    end

    if pathInfo.segments and #pathInfo.segments > 0 then
        local parts = {}
        for _, seg in ipairs(pathInfo.segments) do
            local text = (seg.count == 1) and seg.dir or (seg.count .. " " .. seg.dir)
            if seg.hasTurnBreak then
                text = text .. ", turn break"
            end
            if seg.hasObstacle then
                text = text .. ", obstacle"
            end
            if seg.hasFog then
                text = text .. ", fog"
            end
            if seg.hasRestriction then
                text = text .. ", blocked"
            end
            parts[#parts + 1] = text
        end
        if #parts > 0 then
            table.insert(out, table.concat(parts, ", then "))
        end
    end

    return out
end

-- ===========================================================================
-- Interface-specific plot preview helpers
-- ===========================================================================

InterfaceInfoHelpers = InterfaceInfoHelpers or {}

local function BuildMoveToInterfaceInfo(plot)
    local unit = UI.GetHeadSelectedUnit()
    if not unit or not plot then return nil end
    return BuildMovementSpeech(BuildMovementPathInfo(unit, plot:GetIndex(), false, false))
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

InterfaceInfoHelpers[InterfaceModeTypes.MOVE_TO] = BuildMoveToInterfaceInfo
InterfaceInfoHelpers[InterfaceModeTypes.DISTRICT_PLACEMENT] = BuildDistrictPlacementInterfaceInfo
InterfaceInfoHelpers[InterfaceModeTypes.BUILDING_PLACEMENT] = BuildWonderPlacementInterfaceInfo

function GetActiveInterfacePlotInfo(plot)
    if plot == nil then return nil end

    local helper = InterfaceInfoHelpers[UI.GetInterfaceMode()]
    if helper == nil then return nil end
    return helper(plot)
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
