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
            fromPlotId = fromId,
            toPlotId = toId,
            fromX = a:GetX(),
            fromY = a:GetY(),
            toX = b:GetX(),
            toY = b:GetY(),
            dir = GetSquareDirection(dx, dy),
            turn = (pathInfo.turns and pathInfo.turns[i]) or 1,
            isTurnBreak = (i > 2 and pathInfo.turns and pathInfo.turns[i] ~= pathInfo.turns[i - 1]) or false,
            crossesObstacle = obstacleSet[fromId] or obstacleSet[toId] or false,
            isFog = vis and not vis:IsVisible(toId) or false,
            isRestricted = pathInfo.restrictedPlotId == toId,
            isDestination = (i == #pathInfo.plots),
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
        dir = steps[1].dir,
        count = 1,
        startIndex = 1,
        endIndex = 1,
        hasTurnBreak = steps[1].isTurnBreak,
        hasObstacle = steps[1].crossesObstacle,
        hasFog = steps[1].isFog,
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
            dir = s.dir,
            isTurnBreak = s.isTurnBreak,
            crossesObstacle = s.crossesObstacle,
            isFog = s.isFog,
            isRestricted = s.isRestricted,
        }

        local currentBucket = {
            dir = current.dir,
            isTurnBreak = current.hasTurnBreak,
            crossesObstacle = current.hasObstacle,
            isFog = current.hasFog,
            isRestricted = current.hasRestriction,
        }

        if sameBucket(bucket, currentBucket) then
            current.count = current.count + 1
            current.endIndex = i
        else
            segments[#segments + 1] = current
            current = {
                dir = s.dir,
                count = 1,
                startIndex = i,
                endIndex = i,
                hasTurnBreak = s.isTurnBreak,
                hasObstacle = s.crossesObstacle,
                hasFog = s.isFog,
                hasRestriction = s.isRestricted,
            }
        end
    end

    segments[#segments + 1] = current
    return segments
end

---@param unit table
---@param endPlotId number
---@param showQueuedPath boolean
---@param showDetails boolean
---@return MovementPathInfo|nil
function BuildMovementPathInfo(unit, endPlotId, showQueuedPath, showDetails)
    if not unit or not Map.IsPlot(endPlotId) then return nil end

    local result = {
        kind = "move",
        turns = {},
        plots = {},
        steps = nil,
        segments = nil,
        obstacles = {},
        isRestricted = false,
        restrictedPlotId = nil,
        isPathInFog = false,
        enemyAtEnd = false,
        isQueued = false,
        destPlot = -1,
        isImplicitRangedAttack = false,
        isSamePlot = false,
        entrancePortals = {},
        exitPortals = {}
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
        [UnitOperationTypes.PARAM_Y] = plot:GetY()
    }

    if UnitManager.CanStartOperation(unit, UnitOperationTypes.SWAP_UNITS, nil, tParams) then
        result.kind = "swap"
        result.turns = {1}
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
        table.insert(out, "Crosses "..#pathInfo.obstacles.." "..(#pathInfo.obstacles > 1 and "obstacles" or "obstacle"))
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
