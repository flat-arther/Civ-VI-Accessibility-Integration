---@meta


---**Contexts:** UI
---@class CacheEmergencyManager
local CacheEmergencyManager = {}
---@type table<userdata, table>
CacheEmergencyManager.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
CacheEmergencyManager.TypeName = "CacheEmergencyManager"
---**Contexts:** UI
---
---*Query*
---@param targetPlayerID number 
---@param emergencyIndex number 
---@return table emergencyInfo 
function CacheEmergencyManager:GetSingleEmergency(targetPlayerID, emergencyIndex) end
---**Contexts:** UI
---
---*Query*
---@param targetPlayerID number 
---@return table emergencies 
function CacheEmergencyManager:GetEmergencyInfoTable(targetPlayerID) end
---**Contexts:** UI
---
---*Query*
---@param targetPlayerID number 
---@return table emergencyInfo 
function CacheEmergencyManager:GetNextBlockingEmergency(targetPlayerID) end

z_dontRef_types.CacheEmergencyManager = CacheEmergencyManager