---@meta


---**Contexts:** UI
Matchmaking = {}
---**Contexts:** UI
---
---*Action*
---@param matchID number 
function Matchmaking.AcceptCloudGameInvite(matchID) end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Matchmaking.IsRefreshingGameList() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Matchmaking.IsGameListAtEnd() end
---**Contexts:** UI
---
---*Action*
---@param amount number 
function Matchmaking.SetBrowseOffset(amount) end
---**Contexts:** UI
---
---*Action*
---@param gamesListType 0 --[[Public games]] | 1 --[[Personal games]] | 2 --[[Completed games]] 
function Matchmaking.SetBrowseMode(gamesListType) end
---**Contexts:** UI
---
---*Action*
function Matchmaking.RefreshGameList() end
---**Contexts:** UI
---
---*Query*
---@return {serverName: string, serverID: number}[] servers 
function Matchmaking.GetGameList() end
---**Contexts:** UI
---
---*Query*
---@param lobbyID number 
---@return {serverName: string, serverID: number} server 
function Matchmaking.GetGameListEntry(lobbyID) end
---**Contexts:** UI
---
---*Action*
function Matchmaking.StopRefreshingGameList() end
---**Contexts:** UI
---
---*Action*
---@param lobbyType LobbyTypes 
function Matchmaking.InitLobby(lobbyType) end
---**Contexts:** UI
---
---*Action*
---@param gamesListType 0 --[[Public games]] | 1 --[[Personal games]] | 2 --[[Completed games]] 
---@param searchType 0 --[[Search internet]] | 1 --[[Search LAN]] | 2 --[[Search friends]] | 3 --[[Search favorites]] | 4 --[[Search history]] | 5 --[[Search crossplay]] 
function Matchmaking.SetGameListType(gamesListType, searchType) end