local CAICursor = {
    curX = 0,
    curY = 0
}

--# Methods
function CAICursor:SetCoords(x, y)
    --local w, h = Map.GetGridSize()
    --if x > w or x > h then 
        --print("New cursor coordinates out of bounds")
        --return
    --end
    self.curX = x
    self.curY = y
    local plot = Map.GetPlot(x, y)
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

function CAICursor:GetPlotId()
    local plot = Map.GetPlot(self.curX, self.curY)
    if not plot then return -1 end
    return plot:GetIndex()
end

ExposedMembers.CAICursor = CAICursor