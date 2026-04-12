---@meta


---**Contexts:** Gameplay
---@class WorldBuilderPlayerManager
local WorldBuilderPlayerManager = {}
---@type table<userdata, table>
WorldBuilderPlayerManager.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
WorldBuilderPlayerManager.TypeName = "WorldBuilderPlayerManager"
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderPlayerManager:SetRandomMajorStartingPosition() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function WorldBuilderPlayerManager:IsPlayerInitialized() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function WorldBuilderPlayerManager:PlayerHasTech() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderPlayerManager:SetPlayerSlotStatus() end
---**Contexts:** Gameplay
---
---*Query*
function WorldBuilderPlayerManager:GetStartPositionInfo() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderPlayerManager:AddPlayer() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderPlayerManager:SetCivilizationStartingPosition() end
---**Contexts:** Gameplay
---
---*Action*
---
---Cannot be used to change player leader or civilization mid-game
---@param playerID number 
---@param leaderIndex number 
---@param civilizationIndex number 
---@param civilizationLevelType CivilizationLevelTypes 
function WorldBuilderPlayerManager:SetPlayerLeader(playerID, leaderIndex, civilizationIndex, civilizationLevelType) end
---**Contexts:** Gameplay
---
---*Query*
function WorldBuilderPlayerManager:GetPlayerConfig() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderPlayerManager:SetLeaderStartingPosition() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderPlayerManager:ClearStartingPosition() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderPlayerManager:InitializePlayer() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderPlayerManager:ClearPlayerStartingPosition() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderPlayerManager:SetPlayerFaith() end
---**Contexts:** Gameplay
---
---*Query*
function WorldBuilderPlayerManager:GetSlotStatus() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function WorldBuilderPlayerManager:PlayerHasCivic() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderPlayerManager:SetPlayerHasTech() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderPlayerManager:SetPlayerEra() end
---**Contexts:** Gameplay
---
---*Query*
function WorldBuilderPlayerManager:GetStartPositionPlayer() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderPlayerManager:SetRandomMinorStartingPosition() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderPlayerManager:SetPlayerGold() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderPlayerManager:SetPlayerStartingPosition() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderPlayerManager:UninitializePlayer() end
---**Contexts:** Gameplay
---
---*Query*
---@return number maxPlayers 
function WorldBuilderPlayerManager:GetMaxPlayers() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderPlayerManager:SetPlayerHasCivic() end

z_dontRef_types.WorldBuilderPlayerManager = WorldBuilderPlayerManager