---@meta


---**Contexts:** UI
Steam = {}
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Steam.IsOverlayEnabled() end
---**Contexts:** UI
---
---*Action*
function Steam.ActivateGameOverlayToUrl() end
---**Contexts:** UI
---
---*Action*
function Steam.ActivateGameOverlayToWorkshop() end
---**Contexts:** UI
---
---*Query*
---@return number appID 
function Steam.GetAppID() end
---**Contexts:** UI
---
---*Action*
function Steam.ActivateInviteOverlay() end
---**Contexts:** UI
---
---*Action*
function Steam.ActivateGameOverlayToFriendRequest() end
---**Contexts:** UI
---
---*Action*
function Steam.ActivateGameOverlayToStore() end
---**Contexts:** UI
---
---*Action*
function Steam.InviteUserToGame() end
---**Contexts:** UI
---
---*Query*
function Steam.GetMySteamID() end
---**Contexts:** UI
---
---*Action*
function Steam.ActivateGameOverlay() end
---**Contexts:** UI
---
---*Action*
function Steam.ActivateGameOverlayToChat() end
---**Contexts:** UI
---
---*Action*
function Steam.ClearRichPresence() end
---**Contexts:** UI
---
---*Action*
function Steam.SetOverlayNotificationPosition() end
---**Contexts:** UI
---
---*Query*
function Steam.GetFriendCount() end
---**Contexts:** UI
---
---*Action*
function Steam.SetRichPresence() end
---**Contexts:** UI
---
---*Action*
function Steam.ActivateGameOverlayToUser() end
---**Contexts:** UI
---
---*Query*
---@param friendIndex number 
---@return table friendInfo 
function Steam.GetFriendByIndex(friendIndex) end
---**Contexts:** UI
---
---*Query*
function Steam.GetRichPresence() end