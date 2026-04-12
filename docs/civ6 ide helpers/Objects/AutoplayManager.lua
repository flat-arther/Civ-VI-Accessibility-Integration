---@meta


---**Contexts:** Gameplay, UI
AutoplayManager = {}
---**Contexts:** Gameplay, UI
---
---*Action*
---@param playerID number 
function AutoplayManager.SetReturnAsPlayer(playerID) end
---**Contexts:** Gameplay, UI
---
---*Action*
---@param turnsActive number 
function AutoplayManager.SetTurns(turnsActive) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return PlayerTypes | integer playerID 
function AutoplayManager.GetObserveAsPlayer() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number turns 
function AutoplayManager.GetTurns() end
---**Contexts:** Gameplay, UI
---
---*Action*
---@param value number 
function AutoplayManager.SetDisableAssertsForAutoplay(value) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param playerID number 
function AutoplayManager.GetReturnAsPlayer(playerID) end
---**Contexts:** Gameplay, UI
---
---*Query*
function AutoplayManager.GetDisableAssertsForAutoplay() end
---**Contexts:** Gameplay, UI
---
---*Action*
---@param isActive boolean 
function AutoplayManager.SetActive(isActive) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function AutoplayManager.IsActive() end
---**Contexts:** Gameplay, UI
---
---*Action*
function AutoplayManager.SetObserveAsPlayer() end