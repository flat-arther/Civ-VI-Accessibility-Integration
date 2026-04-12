---@meta

---@alias PlotInfoType
---|"plotName"
---| "Owner"
---| "Feature"
---| "NationalPark"
---| "Resources"
---| "Geography"
---| "Movement"
---| "Defense"
---| "Appeal"
---| "Continent"
---| "TileType"
---| "NaturalWonder"
---| "Buildings"
---| "Status"



---@class CAICursor
---@field curX integer The current X coordinate of the cursor.
---@field curY integer The current Y coordinate of the cursor.
---@field settings table<string, boolean> Configuration flags for cursor behavior.
CAICursor = {}

---Sets cursor coordinates to a given x and y.
---Triggers LuaEvents.CAICursorMoved.
---@param x integer
---@param y integer
function CAICursor:SetCoords(x, y) end

---Moves to the next plot in the specified hex direction.
---@param dir DirectionTypes The direction index (0-5).
function CAICursor:MoveToNextPlot(dir) end

---Snaps the cursor coordinates to a specific unit's location.
---@param unit Unit The unit object to snap to.
function CAICursor:SnapToUnit(unit) end

---Returns the unique Index of the plot currently under the cursor.
---@return integer # The plot index, or -1 if the plot is invalid.
function CAICursor:GetPlotId() end


--- This is here so that the ide doesn't drive me crazy
---@class ExposedMembers
---@field CAICursor CAICursor Access to the Accessibility Cursor system.
ExposedMembers = ExposedMembers or {}