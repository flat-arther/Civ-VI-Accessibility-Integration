---@meta


---**Contexts:** UI
---@class CacheGameCulture
local CacheGameCulture = {}
---@type table<userdata, table>
CacheGameCulture.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
CacheGameCulture.TypeName = "CacheGameCulture"
---**Contexts:** UI
---
---*Query*
---@return table civicNodes 
function CacheGameCulture.GetActiveCivicNodes() end

z_dontRef_types.CacheGameCulture = CacheGameCulture