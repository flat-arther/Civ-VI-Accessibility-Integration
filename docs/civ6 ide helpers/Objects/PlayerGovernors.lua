---@meta


---**Contexts:** Gameplay, UI
---@class PlayerGovernors
local PlayerGovernors = {}
---@type table<userdata, table>
PlayerGovernors.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
PlayerGovernors.TypeName = "PlayerGovernors"
---**Contexts:** UI
---
---*Query*
---@return boolean  
function PlayerGovernors:CanAppoint() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function PlayerGovernors:CanPromote() end
---**Contexts:** Gameplay
---
---*Action*
function PlayerGovernors:ChangeGovernorPoints() end
---**Contexts:** UI
---
---*Query*
function PlayerGovernors:GetAssignedCity() end
---**Contexts:** UI
---
---*Query*
---@param City City 
function PlayerGovernors:GetAssignedGovernor(City) end
---**Contexts:** UI
---
---*Query*
function PlayerGovernors:GetGovernorList() end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerGovernors:GetGovernorPoints() end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerGovernors:GetGovernorPointsSpent() end
---**Contexts:** UI
---
---*Query*
function PlayerGovernors:GetTurnsToEstablish() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function PlayerGovernors:HasGovernor() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function PlayerGovernors:HasTitleBeenConsidered() end
---**Contexts:** UI
---
---*Action*
function PlayerGovernors:SetTitleConsidered() end
---**Contexts:** UI
---
---*Query*
function PlayerGovernors:CanAppointGovernor() end
---**Contexts:** UI
---
---*Query*
---@return number secretSocietyIndex 
function PlayerGovernors:GetSecretSociety() end
---**Contexts:** UI
---
---*Query*
function PlayerGovernors:CanEverAppointGovernor() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function PlayerGovernors:IsGovernorEstablished() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function PlayerGovernors:CanPromoteGovernor() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function PlayerGovernors:CanAssignGovernor() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function PlayerGovernors:IsAwareOfSecretSociety() end
---**Contexts:** UI
---
---*Query*
function PlayerGovernors:GetBaseTurnsUntilEstablished() end
---**Contexts:** UI
---
---*Query*
---@param governorHash number 
---@return CacheGovernor CacheGovernor 
function PlayerGovernors:GetGovernor(governorHash) end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function PlayerGovernors:CanEarnPromotion() end

z_dontRef_types.PlayerGovernors = PlayerGovernors