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

LuaEvents.CAICursorMoved.Add(OnCAICursorMove)
