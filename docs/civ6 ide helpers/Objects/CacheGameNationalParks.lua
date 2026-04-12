---@meta


---**Contexts:** UI
---@class CacheGameNationalParks
local CacheGameNationalParks = {}
---@type table<userdata, table>
CacheGameNationalParks.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
CacheGameNationalParks.TypeName = "CacheGameNationalParks"
---**Contexts:** UI
---
---*Query*
---@return boolean  
function CacheGameNationalParks.IsNationalPark() end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@return Plot[] plots 
function CacheGameNationalParks.GetPossibleParkTiles(playerID) end
---**Contexts:** UI
---
---*Query*
---@return string name 
function CacheGameNationalParks.GetNationalParkName() end
---**Contexts:** UI
---
---*Query*
---@return table nationalParks 
function CacheGameNationalParks.EnumerateNationalParks() end
---**Contexts:** UI
---
---*Query*
---@param x number 
---@param y number 
---@return table nationalParkInfo 
function CacheGameNationalParks.GetAtLocation(x, y) end
---**Contexts:** UI
---
---*Query*
---@param plotID number 
---@return table nationalParkInfo 
function CacheGameNationalParks.GetAtIndex(plotID) end
---**Contexts:** UI
---
---*Query*
---@return number amount 
function CacheGameNationalParks.GetCount() end

z_dontRef_types.CacheGameNationalParks = CacheGameNationalParks