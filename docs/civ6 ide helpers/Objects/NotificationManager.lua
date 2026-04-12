---@meta


---**Contexts:** Gameplay, UI
NotificationManager = {}
---**Contexts:** Gameplay, UI
---
---*Action*
---@param playerID number 
---@param notificationID number 
function NotificationManager.Dismiss(playerID, notificationID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param playerID number 
---@param notificationID number 
---@return Notification Notification 
function NotificationManager.Find(playerID, notificationID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param endTurnBlockingType EndTurnBlockingTypes 
---@param playerID number 
---@return Notification Notification 
function NotificationManager.FindEndTurnBlocking(endTurnBlockingType, playerID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param notificationType NotificationTypes 
---@param playerID number 
---@return Notification Notification 
function NotificationManager.FindType(notificationType, playerID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param playerID number 
---@return table allBlockingTypes 
function NotificationManager.GetAllEndTurnBlocking(playerID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param playerID number 
---@return EndTurnBlockingTypes endTurnBlockingType 
function NotificationManager.GetFirstEndTurnBlocking(playerID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param playerID number 
---@return table notificationIDs 
function NotificationManager.GetList(playerID) end
---**Contexts:** Gameplay, UI
---
---*Action*
---@param playerID number 
function NotificationManager.RestoreVisualState(playerID) end
---**Contexts:** Gameplay, UI
---
---*Action*
---@param playerID number 
---@param notificationType NotificationTypes 
---@param text string 
---@param desc string 
---@param mapX number 
---@param mapY number 
function NotificationManager.SendNotification(playerID, notificationType, text, desc, mapX, mapY) end