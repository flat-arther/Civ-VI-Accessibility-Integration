---@meta


---**Contexts:** UI
---@class FriendsInstance
local FriendsInstance = {}
---@type table<userdata, table>
FriendsInstance.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
FriendsInstance.TypeName = "FriendsInstance"
---**Contexts:** UI
---
---*Query*
---@return boolean  
function FriendsInstance.IsOverlayEnabled() end
---**Contexts:** UI
---
---*Action*
function FriendsInstance.ActivateGameOverlayToUrl() end
---**Contexts:** UI
---
---*Query*
function FriendsInstance.GetFriendCount() end
---**Contexts:** UI
---
---*Action*
function FriendsInstance.ActivateGameOverlayToChat() end
---**Contexts:** UI
---
---*Action*
function FriendsInstance.ActivateGameOverlay() end
---**Contexts:** UI
---
---*Query*
---@param friendIndex number 
---@return {ID: number, IsOnline: boolean, IsHosting: boolean, PlayerName: string} friendInfo 
function FriendsInstance.GetFriendByIndex(friendIndex) end
---**Contexts:** UI
---
---*Action*
function FriendsInstance.ClearRichPresence() end
---**Contexts:** UI
---
---*Action*
function FriendsInstance.ActivateGameOverlayToFriendRequest() end
---**Contexts:** UI
---
---*Query*
function FriendsInstance.GetRichPresence() end
---**Contexts:** UI
---
---*Action*
function FriendsInstance.ActivateGameOverlayToUser() end
---**Contexts:** UI
---
---*Action*
function FriendsInstance.ActivateInviteOverlay() end
---**Contexts:** UI
---
---*Action*
function FriendsInstance.DeclineInvite() end
---**Contexts:** UI
---
---*Action*
function FriendsInstance.InviteUserToGame() end
---**Contexts:** UI
---
---*Action*
function FriendsInstance.AcceptInvite() end
---**Contexts:** UI
---
---*Action*
function FriendsInstance.ActivateGameOverlayToStore() end
---**Contexts:** UI
---
---*Action*
function FriendsInstance.SetRichPresence() end
---**Contexts:** UI
---
---*Action*
function FriendsInstance.ActivateOverlayToUserGeneratedContent() end

z_dontRef_types.FriendsInstance = FriendsInstance