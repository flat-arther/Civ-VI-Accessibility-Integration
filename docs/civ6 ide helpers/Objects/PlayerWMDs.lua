---@meta


---**Contexts:** Gameplay, UI
---@class PlayerWMDs
local PlayerWMDs = {}
---@type table<userdata, table>
PlayerWMDs.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
PlayerWMDs.TypeName = "PlayerWMDs"
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function PlayerWMDs:CanDeployWMD() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number amount 
function PlayerWMDs:GetWeaponCount() end
---**Contexts:** Gameplay
---
---*Action*
---@param amount number 
function PlayerWMDs:ChangeWeaponCount(amount) end

z_dontRef_types.PlayerWMDs = PlayerWMDs