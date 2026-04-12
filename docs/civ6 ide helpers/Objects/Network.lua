---@meta


---**Contexts:** UI
Network = {}
---**Contexts:** UI
---
---*Action*
function Network.DisplayUGCRestrictionsWarning() end
---**Contexts:** UI
---
---*Query*
function Network.CheckServerForUnseenComplete() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Network.UGCRestrictionsEnabled() end
---**Contexts:** UI
---
---*Query*
function Network.GetPingTime() end
---**Contexts:** UI
---
---*Action*
function Network.KickVote() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Network.IsNetworkAvailable() end
---**Contexts:** UI
---
---*Query*
---@return number playerID 
function Network.GetLocalPlayerID() end
---**Contexts:** UI
---
---*Query*
function Network.UserAccountChanged() end
---**Contexts:** UI
---
---*Query*
function Network.GetInternetTransportType() end
---**Contexts:** UI
---
---*Action*
function Network.RestartGame() end
---**Contexts:** UI
---
---*Action*
function Network.ResetPlayTogether() end
---**Contexts:** UI
---
---*Action*
function Network.JoinGame() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Network.IsInternetLobbyServiceAvailable() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Network.IsNetSessionHost() end
---**Contexts:** UI
---
---*Action*
function Network.LoadGame() end
---**Contexts:** UI
---
---*Action*
function Network.SetInPSPlusFeature() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Network.IsPlayerResyncing() end
---**Contexts:** UI
---
---*Query*
function Network.EnsureNetworkServiceAccountAvailable() end
---**Contexts:** UI
---
---*Query*
function Network.PresentNpDisconnectedError() end
---**Contexts:** UI
---
---*Action*
function Network.CloseConnection() end
---**Contexts:** UI
---
---*Query*
function Network.CanShowFriendChatWindow() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Network.IsUserLoggedIntoCrossPlayLobbyService() end
---**Contexts:** UI
---
---*Query*
function Network.HasSeparateCrossPlayLobbyService() end
---**Contexts:** UI
---
---*Action*
function Network.SaveGame() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Network.IsPlayerHotJoining() end
---**Contexts:** UI
---
---*Action*
function Network.RequestPlayerIDChange() end
---**Contexts:** UI
---
---*Action*
function Network.JoinGameByJoinCode() end
---**Contexts:** UI
---
---*Action*
function Network.CloudKillGame() end
---**Contexts:** UI
---
---*Action*
function Network.SetCompletedGameSeen() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Network.IsNetworkServiceAccountAvailable() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Network.IsSessionActive() end
---**Contexts:** UI
---
---*Query*
function Network.GetChangePlayerID() end
---**Contexts:** UI
---
---*Action*
function Network.LeaveGame() end
---**Contexts:** UI
---
---*Query*
function Network.GetElapsedSessionTime() end
---**Contexts:** UI
---
---*Action*
---@return boolean  
function Network.IsMatchMaking() end
---**Contexts:** UI
---
---*Action*
function Network.RequestInternetConnection() end
---**Contexts:** UI
---
---*Action*
function Network.SendChat() end
---**Contexts:** UI
---
---*Action*
function Network.KickPlayer() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Network.IsCloudLaunching() end
---**Contexts:** UI
---
---*Action*
function Network.MatchMake() end
---**Contexts:** UI
---
---*Action*
function Network.HostGame() end
---**Contexts:** UI
---
---*Action*
function Network.AttemptConnectionToCrossPlayLobbyService() end
---**Contexts:** UI
---
---*Query*
function Network.GetCapability() end
---**Contexts:** UI
---
---*Query*
function Network.ProfanityFilter() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Network.IsSessionInCloseState() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Network.HasKickVotedStarted() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Network.HasVotedToKick() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Network.HasCapability() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Network.CanViewFriendProfile() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Network.IsInSession() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Network.ResetHasShownNetworkDisconnectError() end
---**Contexts:** UI
---
---*Query*
function Network.GetGameHostPlayerID() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Network.HasSingleFriendInvite() end
---**Contexts:** UI
---
---*Action*
function Network.ForceResync() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Network.IsPlayerConnected() end
---**Contexts:** UI
---
---*Query*
---@return FriendsInstance FriendsInstance 
function Network.GetFriends() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Network.IsCloudMatchStarted() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Network.PSPlusAvailability() end
---**Contexts:** UI
---
---*Action*
function Network.BroadcastGameConfig() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Network.IsCloudJoinsBlocked() end
---**Contexts:** UI
---
---*Action*
function Network.CloudQuitGame() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Network.IsCrossPlayLobbyServiceAvailable() end
---**Contexts:** UI
---
---*Query*
function Network.CheckServerForCloudNotifications() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Network.IsCloudTurnPlayer() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Network.IsSessionClosing() end
---**Contexts:** UI
---
---*Action*
function Network.SetLocalNetworkMode() end
---**Contexts:** UI
---
---*Action*
function Network.DisplayPossibleNetworkError() end
---**Contexts:** UI
---
---*Action*
function Network.LogIntoCrossPlayLobbyService() end
---**Contexts:** UI
---
---*Action*
function Network.RequestSnapshot() end
---**Contexts:** UI
---
---*Query*
function Network.GetNetworkPlatform() end
---**Contexts:** UI
---
---*Query*
function Network.GetTransportType() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Network.IsEveryoneConnected() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Network.IsInGameStartedState() end
---**Contexts:** UI
---
---*Query*
function Network.GetGameConfigurationSaveType() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Network.IsGameHost() end
---**Contexts:** UI
---
---*Query*
function Network.GetServerHostName() end
---**Contexts:** UI
---
---*Query*
function Network.GetNetSessionHostPlayerID() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Network.IsPlayerKicked() end
---**Contexts:** UI
---
---*Action*
function Network.TriggerTestSync() end
---**Contexts:** UI
---
---*Query*
function Network.GetJoinCode() end
---**Contexts:** UI
---
---*Query*
function Network.GetSessionID() end
---**Contexts:** UI
---
---*Action*
function Network.InvitePlayTogetherUsers() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Network.IsInternetMultiplayerInitialized() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Network.IsMultiplayerRestrictionEnabled() end
---**Contexts:** UI
---
---*Query*
function Network.GetLastJoinedHostName() end
---**Contexts:** UI
---
---*Query*
function Network.CloudEndTurn() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Network.IsGameCoreActive() end
---**Contexts:** UI
---
---*Action*
function Network.LaunchGame() end
---**Contexts:** UI
---
---*Query*
function Network.PresentPSPlusCommerceDialog() end
---**Contexts:** UI
---
---*Action*
function Network.BroadcastPlayerInfo() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Network.IsUpdateRequired() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Network.IsNpReachable() end