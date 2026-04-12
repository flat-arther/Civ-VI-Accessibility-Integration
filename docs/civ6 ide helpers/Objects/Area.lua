---@meta


---**Contexts:** Gameplay, UI
---@class Area
local Area = {}
---@type table<userdata, table>
Area.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
Area.TypeName = "Area"
---**Contexts:** UI
---
---*Query*
---@return number areaID 
function Area:GetID() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Area:GetImprovementCount() end
---**Contexts:** UI
---
---*Query*
---@return number amount 
function Area:GetPlotCount() end
---**Contexts:** UI
---
---*Query*
function Area:GetResourceCount() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Area:GetRiverEdgeCount() end
---**Contexts:** Gameplay
---
---*Query*
function Area:GetTotalImprovements() end
---**Contexts:** UI
---
---*Query*
function Area:GetTotalNaturalWonders() end
---**Contexts:** UI
---
---*Query*
function Area:GetTotalResources() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function Area:HasNoFlatCoast() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Area:IsCanyons() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Area:IsMountains() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Area:IsNone() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Area:IsWater() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return {NorthEdge: integer, WestEdge: integer, SouthEdge: integer, EastEdge: integer} boundaries 
function Area:GetBoundaries() end

z_dontRef_types.Area = Area