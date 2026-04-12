---@meta


---**Contexts:** Gameplay
---@class PlayerEras
local PlayerEras = {}
---@type table<userdata, table>
PlayerEras.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
PlayerEras.TypeName = "PlayerEras"
---**Contexts:** Gameplay
---
---*Query*
function PlayerEras:GetEra() end
---**Contexts:** Gameplay
---
---*Action*
function PlayerEras:SetEra() end
---**Contexts:** Gameplay
---
---*Action*
function PlayerEras:SetStartingEra() end

z_dontRef_types.PlayerEras = PlayerEras