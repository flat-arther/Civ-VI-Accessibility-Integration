---@meta


---**Contexts:** Gameplay, UI
PlayerManager = {}
---**Contexts:** Gameplay, UI
---
---*Query*
---@return Player[] players 
function PlayerManager.GetAlive() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return integer[] playerIDs 
function PlayerManager.GetAliveBarbarianIDs() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return Player[] players 
function PlayerManager.GetAliveBarbarians() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number barbarianPlayersAmount 
function PlayerManager.GetAliveBarbariansCount() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return integer[] playerIDs 
function PlayerManager.GetAliveIDs() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return integer[] playerIDs 
function PlayerManager.GetAliveMajorIDs() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return Player[] players 
function PlayerManager.GetAliveMajors() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number amount 
function PlayerManager.GetAliveMajorsCount() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return integer[] playerIDs 
function PlayerManager.GetAliveMinorIDs() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return Player[] players 
function PlayerManager.GetAliveMinors() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number amount 
function PlayerManager.GetAliveMinorsCount() end
---**Contexts:** Gameplay
---
---*Query*
---@return number playerID 
function PlayerManager.GetFreeCitiesPlayerID() end
---**Contexts:** Gameplay
---
---*Query*
---@param playerID number 
---@return Player Player 
function PlayerManager.GetPlayer(playerID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return Player[] players 
function PlayerManager.GetWasEverAlive() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number amount 
function PlayerManager.GetWasEverAliveCount() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return integer[] playerIDs 
function PlayerManager.GetWasEverAliveIDs() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return integer[] playerIDs 
function PlayerManager.GetWasEverAliveMajorIDs() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return Player[] players 
function PlayerManager.GetWasEverAliveMajors() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number amount 
function PlayerManager.GetWasEverAliveMajorsCount() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param playerID number 
---@return boolean  
function PlayerManager.IsAlive(playerID) end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@return boolean  
function PlayerManager.IsBarbarian(playerID) end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@return boolean  
function PlayerManager.IsMajor(playerID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param playerID number 
---@return boolean  
function PlayerManager.IsValid(playerID) end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function PlayerManager.IsValidID() end
---**Contexts:** Gameplay
---
---*Action*
---@param playerID PlayerTypes | integer 
function PlayerManager.SetLocalObserverTo(playerID) end
---**Contexts:** Gameplay
---
---*Action*
function PlayerManager.SetLocalPlayerAndObserver() end
---**Contexts:** Gameplay
---
---*Query*
---@param playerID number 
---@return boolean  
function PlayerManager.WasEverAlive(playerID) end
---**Contexts:** Gameplay
---
---*Query*
function PlayerManager.GetDefaultProperty() end
---**Contexts:** Gameplay
---
---*Query*
---@return Player Player 
function PlayerManager.GetFreeCitiesPlayer() end
---**Contexts:** Gameplay
---
---*Query*
---@return any value 
function PlayerManager.GetProperty() end
---**Contexts:** Gameplay
---
---*Action*
function PlayerManager.SetProperty() end
---**Contexts:** Gameplay
---
---*Action*
function PlayerManager.SetDefaultProperty() end