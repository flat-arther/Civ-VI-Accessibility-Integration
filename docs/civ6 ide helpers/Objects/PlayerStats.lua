---@meta


---**Contexts:** Gameplay, UI
---@class PlayerStats
local PlayerStats = {}
---@type table<userdata, table>
PlayerStats.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
PlayerStats.TypeName = "PlayerStats"
---**Contexts:** UI
---
---*Query*
---@return number amount 
function PlayerStats:GetMilitaryStrength() end
---**Contexts:** Gameplay
---
---*Query*
---@return number amount 
function PlayerStats:GetNumBeliefsInReligion() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number amount 
function PlayerStats:GetNumCitiesFollowingReligion() end
---**Contexts:** Gameplay
---
---*Query*
---@return number amount 
function PlayerStats:GetNumDistrictsFollowingReligion() end
---**Contexts:** Gameplay
---
---*Query*
---@return number amount 
function PlayerStats:GetNumFollowers() end
---**Contexts:** Gameplay
---
---*Query*
---@return number amount 
function PlayerStats:GetNumForeignCitiesFollowingReligion() end
---**Contexts:** Gameplay
---
---*Query*
---@return number amount 
function PlayerStats:GetNumForeignFollowers() end
---**Contexts:** Gameplay
---
---*Query*
---@return number amount 
function PlayerStats:GetNumMyCitiesFollowingSpecificReligion() end
---**Contexts:** UI
---
---*Query*
---@return number amount 
function PlayerStats:GetNumProjectsAdvanced() end
---**Contexts:** UI
---
---*Query*
---@return number amount 
function PlayerStats:GetNumTechsResearched() end
---**Contexts:** UI
---
---*Query*
---@return number amount 
function PlayerStats:GetTourism() end
---**Contexts:** UI
---
---*Query*
function PlayerStats:GetTourismToolTip() end
---**Contexts:** Gameplay
---
---*Action*
function PlayerStats:UpdateMaxMeleeStrengthTrained() end
---**Contexts:** UI
---
---*Query*
function PlayerStats:GetScienceVictoryPointsTotalNeeded() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function PlayerStats:GetHasRevivedPlayer() end
---**Contexts:** UI
---
---*Query*
function PlayerStats:GetScienceVictoryPoints() end
---**Contexts:** UI
---
---*Query*
---@return number amount 
function PlayerStats:GetNumCivicsCompleted() end
---**Contexts:** UI
---
---*Query*
function PlayerStats:GetNumBuildingsOfType() end
---**Contexts:** UI
---
---*Query*
---@return number amount 
function PlayerStats:GetDiplomaticVictoryPointsTooltip() end
---**Contexts:** UI
---
---*Query*
---@return number amount 
function PlayerStats:GetDiplomaticVictoryPoints() end
---**Contexts:** UI
---
---*Query*
---@return number amount 
function PlayerStats:GetScienceVictoryPointsPerTurn() end
---**Contexts:** UI
---
---*Query*
---@return number amount 
function PlayerStats:GetMilitaryStrengthWithoutTreasury() end
---**Contexts:** Gameplay
---
---*Action*
function PlayerStats:UpdateMaxBombardStrengthTrained() end
---**Contexts:** Gameplay
---
---*Action*
function PlayerStats:UpdateMaxRangedStrengthTrained() end
---**Contexts:** Gameplay
---
---*Query*
function PlayerStats:GetNumCitiesFollowingReligionWithWonder() end
---**Contexts:** Gameplay
---
---*Action*
function PlayerStats:ChangeScienceVictoryPoints() end

z_dontRef_types.PlayerStats = PlayerStats