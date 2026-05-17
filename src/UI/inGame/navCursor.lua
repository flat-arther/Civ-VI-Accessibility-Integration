CAICursor = CAICursor or {
    curX = 0,
    curY = 0
}

--# Methods
function CAICursor:SetCoords(x, y)
    if x == nil or y == nil then
        print("CAI cursor move requested with nil coordinates")
        return
    end

    local plot = Map.GetPlot(x, y)
    if not plot then
        print("CAI cursor unable to resolve plot at coordinates: " .. tostring(x) .. ", " .. tostring(y))
        return
    end

    self.curX = plot:GetX()
    self.curY = plot:GetY()
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

LuaEvents.CAICursorMove.Add(function(x, y)
    CAICursor:SetCoords(x, y)
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
ExposedMembers.CAICursor = CAICursor
