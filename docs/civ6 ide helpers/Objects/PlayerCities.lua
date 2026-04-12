---@meta


---**Contexts:** Gameplay, UI
---@class PlayerCities
local PlayerCities = {}
---@type table<userdata, table>
PlayerCities.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
PlayerCities.TypeName = "PlayerCities"
---**Contexts:** Gameplay
---
---*Action*
---@param x number 
---@param y number 
function PlayerCities:Create(x, y) end
---**Contexts:** Gameplay
---
---*Action*
function PlayerCities:Destroy() end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerCities:FindID() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return City City 
function PlayerCities:GetCapitalCity() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number amount 
function PlayerCities:GetCount() end
---**Contexts:** UI
---
---*Query*
function PlayerCities:GetFirstRangedAttackCity() end
---**Contexts:** UI
---
---*Query*
function PlayerCities:GetNextCapturedCity() end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerCities:Members() end
---**Contexts:** UI
---
---*Query*
function PlayerCities:IsCityWithinRange() end
---**Contexts:** UI
---
---*Query*
function PlayerCities:GetNextRebelledCity() end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerCities:FindClosest() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function PlayerCities:IsValidFoundLocation() end
---**Contexts:** Gameplay
---
---*Query*
---@return City City 
function PlayerCities:GetOriginalCapitalCity() end

z_dontRef_types.PlayerCities = PlayerCities