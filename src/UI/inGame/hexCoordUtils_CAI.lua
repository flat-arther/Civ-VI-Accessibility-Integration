CAIHexCoordUtils = CAIHexCoordUtils or {}

local HexCoordUtils = CAIHexCoordUtils

local OUTPUT_ORDER = {
    { dir = "E",  key = "LOC_CAI_DIR_E" },
    { dir = "SE", key = "LOC_CAI_DIR_SE" },
    { dir = "SW", key = "LOC_CAI_DIR_SW" },
    { dir = "W",  key = "LOC_CAI_DIR_W" },
    { dir = "NW", key = "LOC_CAI_DIR_NW" },
    { dir = "NE", key = "LOC_CAI_DIR_NE" },
}

local DIRECTION_RANK = { E = 1, SE = 2, SW = 3, W = 4, NW = 5, NE = 6 }

local NEIGHBOR_DIRS = {
    DirectionTypes.DIRECTION_NORTHEAST,
    DirectionTypes.DIRECTION_EAST,
    DirectionTypes.DIRECTION_SOUTHEAST,
    DirectionTypes.DIRECTION_SOUTHWEST,
    DirectionTypes.DIRECTION_WEST,
    DirectionTypes.DIRECTION_NORTHWEST,
}

local MAX_PLAYER_INDEX_FOR_CAPITAL = 64
local PLOT_AUDIO_PAN_SATURATION_HEXES = 12
local PLOT_AUDIO_MAX_PITCH_SEMITONES = 12
local PLOT_AUDIO_DEFAULT_MAX_DISTANCE = 30

local function FormatDirectionStep(count, directionKey)
    return Locale.Lookup("LOC_CAI_DIRECTION_STEP", count, Locale.Lookup(directionKey))
end

local function OffsetToCube(col, row)
    local q = col - (row - (row % 2)) / 2
    local r = row
    return q, -q - r, r
end

local function CubeToOffset(x, _, z)
    local row = z
    local col = x + (row - (row % 2)) / 2
    return col, row
end

local function NearestWrappedTo(fromX, fromY, toX, toY)
    local dx = toX - fromX
    local dy = toY - fromY
    if Map.IsWrapX() then
        local width = Map.GetGridSize()
        local half = width / 2
        if dx > half then
            dx = dx - width
        elseif dx < -half then
            dx = dx + width
        end
    end
    if Map.IsWrapY() then
        local _, height = Map.GetGridSize()
        local half = height / 2
        if dy > half then
            dy = dy - height
        elseif dy < -half then
            dy = dy + height
        end
    end
    return fromX + dx, fromY + dy
end

---@param fromX integer
---@param fromY integer
---@param toX integer
---@param toY integer
---@return number dcol
---@return number drow
function HexCoordUtils.displacement(fromX, fromY, toX, toY)
    toX, toY = NearestWrappedTo(fromX, fromY, toX, toY)
    local dcol = (toX + 0.5 * (toY % 2)) - (fromX + 0.5 * (fromY % 2))
    local drow = toY - fromY
    return dcol, drow
end

---@param listenerX integer
---@param listenerY integer
---@param sourceX integer
---@param sourceY integer
---@param maxDistance? number
---@return number pan
---@return number pitch
---@return number volume
function HexCoordUtils.plotAudioParameters(listenerX, listenerY, sourceX, sourceY, maxDistance)
    local dcol, drow = HexCoordUtils.displacement(listenerX, listenerY, sourceX, sourceY)
    local pan = math.max(-1, math.min(1, dcol / PLOT_AUDIO_PAN_SATURATION_HEXES))
    local semitones = math.max(
        -PLOT_AUDIO_MAX_PITCH_SEMITONES,
        math.min(PLOT_AUDIO_MAX_PITCH_SEMITONES, drow)
    )
    local pitch = 2 ^ (semitones / 12)
    local distance = Map.GetPlotDistance(listenerX, listenerY, sourceX, sourceY)
    local audibleDistance = maxDistance or PLOT_AUDIO_DEFAULT_MAX_DISTANCE
    local volume = math.max(0, math.min(1, 1 - distance / audibleDistance))
    return pan, pitch, volume
end

local function DecomposeCube(dx, dy, dz)
    local counts = { E = 0, SE = 0, SW = 0, W = 0, NW = 0, NE = 0 }
    if dy <= 0 and dz <= 0 then
        counts.E, counts.SE = -dy, -dz
    elseif dx >= 0 and dy >= 0 then
        counts.SE, counts.SW = dx, dy
    elseif dz <= 0 and dx <= 0 then
        counts.SW, counts.W = -dz, -dx
    elseif dy >= 0 and dz >= 0 then
        counts.W, counts.NW = dy, dz
    elseif dx <= 0 and dy <= 0 then
        counts.NW, counts.NE = -dx, -dy
    else
        counts.NE, counts.E = dz, dx
    end
    return counts
end

local function DirKey(direction)
    if direction == DirectionTypes.DIRECTION_EAST then
        return "LOC_CAI_DIR_E"
    elseif direction == DirectionTypes.DIRECTION_SOUTHEAST then
        return "LOC_CAI_DIR_SE"
    elseif direction == DirectionTypes.DIRECTION_SOUTHWEST then
        return "LOC_CAI_DIR_SW"
    elseif direction == DirectionTypes.DIRECTION_WEST then
        return "LOC_CAI_DIR_W"
    elseif direction == DirectionTypes.DIRECTION_NORTHWEST then
        return "LOC_CAI_DIR_NW"
    elseif direction == DirectionTypes.DIRECTION_NORTHEAST then
        return "LOC_CAI_DIR_NE"
    end
    return nil
end

local function GetObserverVisibility()
    local observer = Game.GetLocalObserver()
    if observer == nil or observer == PlayerTypes.OBSERVER then
        return nil
    end
    return PlayersVisibility[observer]
end

local function ActiveOriginalCapital()
    local activePlayerID = Game.GetLocalPlayer()
    if activePlayerID == nil or activePlayerID == -1 then
        return nil, nil
    end

    for playerID = 0, MAX_PLAYER_INDEX_FOR_CAPITAL - 1 do
        local player = Players[playerID]
        if player ~= nil then
            local cities = player:GetCities()
            if cities ~= nil then
                for _, city in cities:Members() do
                    if city ~= nil
                        and city:GetOriginalOwner() == activePlayerID
                        and city:IsOriginalCapital() then
                        return city:GetX(), city:GetY()
                    end
                end
            end
        end
    end

    return nil, nil
end

function HexCoordUtils.directionString(fromX, fromY, toX, toY)
    if fromX == nil or fromY == nil or toX == nil or toY == nil then
        return ""
    end

    if fromX == toX and fromY == toY then
        return Locale.Lookup("LOC_CAI_HERE")
    end

    toX, toY = NearestWrappedTo(fromX, fromY, toX, toY)
    local fx, fy, fz = OffsetToCube(fromX, fromY)
    local tx, ty, tz = OffsetToCube(toX, toY)
    local counts = DecomposeCube(tx - fx, ty - fy, tz - fz)
    local parts = {}

    for _, direction in ipairs(OUTPUT_ORDER) do
        local count = counts[direction.dir]
        if count > 0 then
            parts[#parts + 1] = FormatDirectionStep(count, direction.key)
        end
    end

    return table.concat(parts, ", ")
end

function HexCoordUtils.stepListString(directions)
    if directions == nil or #directions == 0 then
        return ""
    end

    local parts = {}
    local runDir = directions[1]
    local runCount = 1

    local function Flush(direction, count)
        local key = DirKey(direction)
        if key ~= nil then
            parts[#parts + 1] = FormatDirectionStep(count, key)
        end
    end

    for i = 2, #directions do
        if directions[i] == runDir then
            runCount = runCount + 1
        else
            Flush(runDir, runCount)
            runDir = directions[i]
            runCount = 1
        end
    end

    Flush(runDir, runCount)
    return table.concat(parts, ", ")
end

function HexCoordUtils.stepDirection(fromX, fromY, toX, toY)
    if fromX == nil or fromY == nil or toX == nil or toY == nil then
        return nil
    end

    for _, direction in ipairs(NEIGHBOR_DIRS) do
        local neighbor = Map.GetAdjacentPlot(fromX, fromY, direction)
        if neighbor ~= nil and neighbor:GetX() == toX and neighbor:GetY() == toY then
            return direction
        end
    end

    return nil
end

function HexCoordUtils.stepListFromPath(path)
    if path == nil or #path < 2 then
        return ""
    end

    local directions = {}
    for i = 1, #path - 1 do
        local fromX = path[i].x
        local fromY = path[i].y
        local toX = path[i + 1].x
        local toY = path[i + 1].y

        local direction = HexCoordUtils.stepDirection(fromX, fromY, toX, toY)
        if direction ~= nil then
            directions[#directions + 1] = direction
        end
    end

    return HexCoordUtils.stepListString(directions)
end

function HexCoordUtils.joinStepSegments(segments)
    if segments == nil or #segments == 0 then
        return ""
    end

    local nonEmpty = {}
    for _, segment in ipairs(segments) do
        if segment ~= nil and segment ~= "" then
            nonEmpty[#nonEmpty + 1] = segment
        end
    end

    if #nonEmpty == 0 then
        return ""
    end

    return table.concat(nonEmpty, ", " .. Locale.Lookup("LOC_CAI_MOVEMENT_THEN") .. ", ")
end

function HexCoordUtils.coordinateString(x, y)
    local capitalX, capitalY = ActiveOriginalCapital()
    if capitalX == nil or capitalY == nil then
        return ""
    end

    local dy = y - capitalY
    local dx = (x + 0.5 * (y % 2)) - (capitalX + 0.5 * (capitalY % 2))
    if Map.IsWrapX() then
        local width = Map.GetGridSize()
        local half = width / 2
        if dx > half then
            dx = dx - width
        elseif dx < -half then
            dx = dx + width
        end
    end

    return tostring(dx) .. ", " .. tostring(dy)
end

function HexCoordUtils.unitVector(fromX, fromY, toX, toY)
    toX, toY = NearestWrappedTo(fromX, fromY, toX, toY)
    local cx = (toX + 0.5 * (toY % 2)) - (fromX + 0.5 * (fromY % 2))
    local cy = toY - fromY
    local px = cx * math.sqrt(3)
    local py = cy * 1.5
    local magnitude = math.sqrt(px * px + py * py)
    if magnitude == 0 then
        return 0, 0
    end

    return px / magnitude, py / magnitude
end

function HexCoordUtils.cubeDistance(x1, y1, x2, y2)
    x2, y2 = NearestWrappedTo(x1, y1, x2, y2)
    local ax, ay, az = OffsetToCube(x1, y1)
    local bx, by, bz = OffsetToCube(x2, y2)
    return (math.abs(ax - bx) + math.abs(ay - by) + math.abs(az - bz)) / 2
end

function HexCoordUtils.directionRank(centerX, centerY, targetX, targetY)
    if centerX == targetX and centerY == targetY then
        return 0
    end

    targetX, targetY = NearestWrappedTo(centerX, centerY, targetX, targetY)
    local fx, fy, fz = OffsetToCube(centerX, centerY)
    local tx, ty, tz = OffsetToCube(targetX, targetY)
    local counts = DecomposeCube(tx - fx, ty - fy, tz - fz)

    for _, direction in ipairs(OUTPUT_ORDER) do
        if counts[direction.dir] > 0 then
            return DIRECTION_RANK[direction.dir]
        end
    end

    return 0
end

function HexCoordUtils.plotsInRange(centerX, centerY, radius)
    local visibility = GetObserverVisibility()
    local ccx, _, ccz = OffsetToCube(centerX, centerY)
    local plots = {}
    local unexplored = 0

    for dx = -radius, radius do
        local dyMin = math.max(-radius, -dx - radius)
        local dyMax = math.min(radius, -dx + radius)
        for dy = dyMin, dyMax do
            local dz = -dx - dy
            local col, row = CubeToOffset(ccx + dx, nil, ccz + dz)
            local plot = Map.GetPlot(col, row)
            if plot ~= nil then
                local isRevealed = visibility == nil or visibility:IsRevealed(plot)
                if isRevealed then
                    plots[#plots + 1] = plot
                else
                    unexplored = unexplored + 1
                end
            end
        end
    end

    return {
        plots = plots,
        unexplored = unexplored,
    }
end
