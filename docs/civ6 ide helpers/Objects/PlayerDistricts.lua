---@meta


---**Contexts:** Gameplay, UI
---@class PlayerDistricts
local PlayerDistricts = {}
---@type table<userdata, table>
PlayerDistricts.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
PlayerDistricts.TypeName = "PlayerDistricts"
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerDistricts:FindID() end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerDistricts:GetCount() end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerDistricts:Members() end

z_dontRef_types.PlayerDistricts = PlayerDistricts