---@meta


---**Contexts:** Gameplay, UI
---@class GameHeroesManager
local GameHeroesManager = {}
---@type table<userdata, table>
GameHeroesManager.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
GameHeroesManager.TypeName = "GameHeroesManager"
---**Contexts:** Gameplay
---
---*Action*
function GameHeroesManager:CreateHero() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param playerID number 
---@param heroClassIndex number 
---@return boolean  
function GameHeroesManager:IsHeroDiscovered(playerID, heroClassIndex) end
---**Contexts:** Gameplay
---
---*Action*
---@param playerID number 
---@param heroClassIndex number 
---@param isDiscovered boolean 
function GameHeroesManager:SetHeroDiscovered(playerID, heroClassIndex, isDiscovered) end
---**Contexts:** Gameplay
---
---*Action*
---@param playerID number 
function GameHeroesManager:PlayerDiscoverNextHero(playerID) end
---**Contexts:** UI
---
---*Query*
---@param heroClassIndex number 
---@return number cityID 
function GameHeroesManager:GetHeroOriginCityID(heroClassIndex) end
---**Contexts:** UI
---
---*Query*
---@param unitIndex number 
---@return number heroClassIndex 
function GameHeroesManager:GetUnitHeroClass(unitIndex) end
---**Contexts:** UI
---
---*Query*
---@param heroClassIndex number 
---@return number playerID 
function GameHeroesManager:GetHeroClaimPlayer(heroClassIndex) end
---**Contexts:** UI
---
---*Query*
---@param heroClassIndex number 
---@return number charges 
function GameHeroesManager:GetHeroClassBaseCharges(heroClassIndex) end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@return number buildingIndex 
function GameHeroesManager:GetPlayerHeroOriginBuildingType(playerID) end

z_dontRef_types.GameHeroesManager = GameHeroesManager