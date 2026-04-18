include ("caiUtils")
include ("navCursor")

--# Event listeners
---Event listener for cursor move
---@param x integer
---@param y integer
---@param plot Plot
---@param cursor CAICursor
function OnCAICursorMove(x, y, plot, cursor)
	-- For now we just speak everything
	local pos = tostring(x)..", "..tostring(y)
	local pInfo = ExposedMembers.CAIInfo:RequestPlotInfo(plot)
	table.insert(pInfo, 1, pos)
	Speak(table.concat(pInfo, "\n"))
end

---Speak selected unit
---@param playerID number
---@param unitID number
---@param hexI number
---@param hexJ number
---@param hexK number
---@param bSelected boolean
---@param bEditable boolean
function OnSelectedUnit(playerID, unitID, hexI, hexJ, hexK, bSelected, bEditable)
	if bSelected then
    local unit = UnitManager.GetUnit(playerID, unitID)
    local x = unit:GetX()
    local y = unit:GetY()
    
    if bSelected then
        local uInfo = ExposedMembers.CAIInfo:RequestUnitInfo(unit)
        local str = "No info"
        if #uInfo > 0 then
            str = table.concat(uInfo, ", ")
        end
    Speak(str)
    end
end
end

Events.UnitSelectionChanged.Add(OnSelectedUnit)
LuaEvents.CAICursorMoved.Add(OnCAICursorMove)
