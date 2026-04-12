---@meta


---**Contexts:** Gameplay, UI
---@class MapImprovementBuilder
local MapImprovementBuilder = {}
---@type table<userdata, table>
MapImprovementBuilder.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
MapImprovementBuilder.TypeName = "MapImprovementBuilder"
---**Contexts:** Gameplay, UI
---
---*Query*
function MapImprovementBuilder.SetImprovementPillaged() end

z_dontRef_types.MapImprovementBuilder = MapImprovementBuilder