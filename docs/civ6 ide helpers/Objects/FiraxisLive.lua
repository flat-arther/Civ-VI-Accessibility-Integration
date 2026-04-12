---@meta


---**Contexts:** UI
FiraxisLive = {}
---**Contexts:** UI
---
---*Action*
function FiraxisLive.CheckForCloudNotifications() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function FiraxisLive.IsMy2KAccountLinked() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function FiraxisLive.IsMy2KConnected() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function FiraxisLive.IsMy2KLoggedIn() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function FiraxisLive.IsFiraxisLiveLoggedIn() end
---**Contexts:** UI
---
---*Action*
---@param email string 
function FiraxisLive.My2KNewUserResponse(email) end
---**Contexts:** UI
---
---*Action*
---@param agreeList table 
---@return boolean  
function FiraxisLive.My2KLegalResponse(agreeList) end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function FiraxisLive.IsPlatformOrFullAccount() end
---**Contexts:** UI
---
---*Action*
---@param dialogID number 
---@param unknown boolean 
function FiraxisLive.My2KMessageResponse(dialogID, unknown) end
---**Contexts:** UI
---
---*Action*
---@param gamesListType 0 --[[Public games]] | 1 --[[Personal games]] | 2 --[[Completed games]] 
function FiraxisLive.ClearCloudGames(gamesListType) end
---**Contexts:** UI
---
---*Action*
---@param autoCloudNotifCheck boolean 
function FiraxisLive.SetAutoCloudNotificationChecks(autoCloudNotifCheck) end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function FiraxisLive.My2KUnlinkAccount() end
---**Contexts:** UI
---
---*Action*
function FiraxisLive.My2KNewUserResponseCancel() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function FiraxisLive.IsFiraxisLiveConnected() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function FiraxisLive.My2KBeginLogin() end
---**Contexts:** UI
---
---*Action*
function FiraxisLive.SetUIReady() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function FiraxisLive.My2KCreateNewUser() end
---**Contexts:** UI
---
---*Action*
---@param email string 
---@param password string 
---@param unknown boolean 
function FiraxisLive.My2KLoginUser(email, password, unknown) end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function FiraxisLive.IsFullyLoggedIn() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function FiraxisLive.IsKandoConnected() end
---**Contexts:** UI
---
---*Action*
---@param email string 
---@param unknown boolean 
function FiraxisLive.My2KEmailResponse(email, unknown) end