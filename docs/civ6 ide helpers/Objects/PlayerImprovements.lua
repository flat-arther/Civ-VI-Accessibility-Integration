---@meta


---**Contexts:** UI
---@class PlayerImprovements
local PlayerImprovements = {}
---@type table<userdata, table>
PlayerImprovements.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
PlayerImprovements.TypeName = "PlayerImprovements"
---**Contexts:** UI
---
---*Query*
function PlayerImprovements:GetImprovementPlots() end

z_dontRef_types.PlayerImprovements = PlayerImprovements