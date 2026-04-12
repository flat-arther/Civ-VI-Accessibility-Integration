---@meta


---**Contexts:** UI
---@class CacheGameTechs
local CacheGameTechs = {}
---@type table<userdata, table>
CacheGameTechs.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
CacheGameTechs.TypeName = "CacheGameTechs"
---**Contexts:** UI
---
---*Query*
---@return table techNodes 
function CacheGameTechs:GetActiveTechNodes() end

z_dontRef_types.CacheGameTechs = CacheGameTechs