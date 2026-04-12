---@meta


---**Contexts:** Gameplay, UI
---@class GameGreatPeople
local GameGreatPeople = {}
---@type table<userdata, table>
GameGreatPeople.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
GameGreatPeople.TypeName = "GameGreatPeople"
---**Contexts:** Gameplay
---
---*Action*
---@param greatPersonIndividual_Hash number 
---@param greatPersonClass_Hash number 
---@param era_Hash number 
---@param cost number 
---@param playerID number 
---@param unknown boolean 
function GameGreatPeople:GrantPerson(greatPersonIndividual_Hash, greatPersonClass_Hash, era_Hash, cost, playerID, unknown) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return table timeline 
function GameGreatPeople:GetTimeline() end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@param greatPersonIndividualType string 
---@return string earnCondText 
function GameGreatPeople:GetEarnConditionsText(playerID, greatPersonIndividualType) end
---**Contexts:** UI
---
---*Query*
---@param classIndex number 
---@param playerID number 
function GameGreatPeople:CountPeopleReceivedByPlayer(classIndex, playerID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param playerID number 
---@param greatPersonIndividualType string 
---@return boolean  
function GameGreatPeople:CanRejectPerson(playerID, greatPersonIndividualType) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param playerID number 
---@param greatPersonIndividualType string 
---@return number GPPCost 
function GameGreatPeople:GetRecruitCost(playerID, greatPersonIndividualType) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param playerID number 
---@param greatPersonIndividualType string 
---@return number GPPCost 
function GameGreatPeople:GetRejectCost(playerID, greatPersonIndividualType) end
---**Contexts:** UI
---
---*Query*
---@return table timeline 
function GameGreatPeople:GetPastTimeline() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param playerID number 
---@param greatPersonIndividualType string 
---@param yieldType YieldTypes 
---@return number cost 
function GameGreatPeople:GetPatronizeCost(playerID, greatPersonIndividualType, yieldType) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param playerID number 
---@param greatPersonIndividualType string 
---@return boolean  
function GameGreatPeople:CanRecruitPerson(playerID, greatPersonIndividualType) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param playerID number 
---@param greatPersonIndividualType string 
---@param yieldType YieldTypes 
---@return boolean  
function GameGreatPeople:CanPatronizePerson(playerID, greatPersonIndividualType, yieldType) end
---**Contexts:** Gameplay
---
---*Action*
---@param playerID number 
---@param greatPersonIndividualType string 
function GameGreatPeople:RecruitPerson(playerID, greatPersonIndividualType) end
---**Contexts:** Gameplay
---
---*Action*
---@param playerID number 
---@param greatPersonIndividualType string 
---@param mapX number 
---@param mapY number 
function GameGreatPeople:CreatePerson(playerID, greatPersonIndividualType, mapX, mapY) end
---**Contexts:** Gameplay
---
---*Query*
---@param greatPersonClassIndex number 
---@return boolean  
function GameGreatPeople:IsClassAvailable(greatPersonClassIndex) end

z_dontRef_types.GameGreatPeople = GameGreatPeople