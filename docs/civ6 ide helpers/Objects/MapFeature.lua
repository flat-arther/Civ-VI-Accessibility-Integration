---@meta


---**Contexts:** Gameplay
---@class MapFeature
local MapFeature = {}
---@type table<userdata, table>
MapFeature.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
MapFeature.TypeName = "MapFeature"
---**Contexts:** UI
---
---*Query*
function MapFeature:GetDirection() end
---**Contexts:** UI
---
---*Query*
---@return Plot[] plots 
function MapFeature:GetPlots() end
---**Contexts:** Gameplay, UI
---
---*Query*
function MapFeature:GetType() end

z_dontRef_types.MapFeature = MapFeature