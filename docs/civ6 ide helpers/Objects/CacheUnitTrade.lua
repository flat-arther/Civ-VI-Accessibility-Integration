---@meta


---**Contexts:** UI
---@class CacheUnitTrade
local CacheUnitTrade = {}
---@type table<userdata, table>
CacheUnitTrade.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
CacheUnitTrade.TypeName = "CacheUnitTrade"
---**Contexts:** UI
---
---*Query*
function CacheUnitTrade:GetLastDestinationTradeCityComponentID() end
---**Contexts:** UI
---
---*Query*
function CacheUnitTrade:GetLastOriginTradeCityComponentID() end

z_dontRef_types.CacheUnitTrade = CacheUnitTrade