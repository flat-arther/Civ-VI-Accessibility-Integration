---@meta


---**Contexts:** UI
---@class InfluenceMap
local InfluenceMap = {}
---@type table<userdata, table>
InfluenceMap.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
InfluenceMap.TypeName = "InfluenceMap"
---**Contexts:** UI
---
---*Query*
function InfluenceMap:Find() end

z_dontRef_types.InfluenceMap = InfluenceMap