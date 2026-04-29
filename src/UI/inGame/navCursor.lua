CAICursor = CAICursor or {
    curX = 0,
    curY = 0
}

local function WrapCoord(value, size)
    return ((value % size) + size) % size
end

local function NormalizeCoords(x, y, wrapCoords)
    local width, height = Map.GetGridSize()

    if width == nil or height == nil or width <= 0 or height <= 0 then
        print("CAI cursor unable to read map grid size")
        return nil, nil
    end

    if wrapCoords then
        return WrapCoord(x, width), WrapCoord(y, height)
    end

    if x < 0 or x >= width or y < 0 or y >= height then
        print("CAI cursor move requested outside map bounds: " .. tostring(x) .. ", " .. tostring(y))
        return nil, nil
    end

    return x, y
end

--# Methods
function CAICursor:SetCoords(x, y, wrapCoords)
    if x == nil or y == nil then
        print("CAI cursor move requested with nil coordinates")
        return
    end

    local normalizedX, normalizedY = NormalizeCoords(x, y, wrapCoords)
    if normalizedX == nil or normalizedY == nil then
        return
    end

    local plot = Map.GetPlot(normalizedX, normalizedY)
    if not plot then
        print("CAI cursor unable to resolve plot at coordinates: " .. tostring(normalizedX) .. ", " .. tostring(normalizedY))
        return
    end

    self.curX = normalizedX
    self.curY = normalizedY
    LuaEvents.CAICursorMoved(self.curX, self.curY, plot, self)
end

function CAICursor:MoveToNextPlot(dir)
    local nextPlot = Map.GetAdjacentPlot(self.curX, self.curY, dir)
    if nextPlot then
        self:SetCoords(nextPlot:GetX(), nextPlot:GetY())
    end
end

function CAICursor:SnapToUnit(unit)
    if not unit then return end
    local x = unit:GetX()
    local y = unit:GetY()
    self:SetCoords(x, y)
end

function CAICursor:SnapToStartPlot()
    local playerID = Game.GetLocalPlayer()
    if not playerID then
        print("CAI cursor unable to find local player")
        return
    end
    local location = PlayerConfigurations[playerID]:GetStartingPosition()
    if location then
        self:SetCoords(location.x, location.y)
    end
end

function CAICursor:SnapToPlot(plot)
    if not plot then
        print("CAI cursor attempting to snap to nil plot")
        return
    end
    self:SetCoords(plot:GetX(), plot:GetY())
end

function CAICursor:GetPlotId()
    local plot = Map.GetPlot(self.curX, self.curY)
    if not plot then return -1 end
    return plot:GetIndex()
end

LuaEvents.CAICursorMove.Add(function(x, y, wrapCoords)
    CAICursor:SetCoords(x, y, wrapCoords)
end)

LuaEvents.CAICursorMoveRelative.Add(function(dx, dy, wrapCoords)
    CAICursor:SetCoords(CAICursor.curX + dx, CAICursor.curY + dy, wrapCoords)
end)

LuaEvents.CAICursorMoveDirection.Add(function(direction)
    CAICursor:MoveToNextPlot(direction)
end)

LuaEvents.CAICursorSnapToUnit.Add(function(unit)
    CAICursor:SnapToUnit(unit)
end)

LuaEvents.CAICursorSnapToStartPlot.Add(function()
    CAICursor:SnapToStartPlot()
end)

LuaEvents.CAICursorSnapToPlot.Add(function(plot)
    CAICursor:SnapToPlot(plot)
end)
