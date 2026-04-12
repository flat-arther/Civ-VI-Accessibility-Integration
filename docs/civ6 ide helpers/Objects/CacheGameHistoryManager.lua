---@meta


---**Contexts:** UI
---@class CacheGameHistoryManager
local CacheGameHistoryManager = {}
---@type table<userdata, table>
CacheGameHistoryManager.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
CacheGameHistoryManager.TypeName = "CacheGameHistoryManager"
---**Contexts:** UI
---
---*Query*
---@return boolean  
function CacheGameHistoryManager.HasPrideMoments() end
---**Contexts:** UI
---
---*Query*
---@return number amount 
function CacheGameHistoryManager.GetMomentCount() end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@param interestLevel number 
---@return table moments 
function CacheGameHistoryManager.GetAllMomentsData(playerID, interestLevel) end
---**Contexts:** UI
---
---*Query*
---@param momentID number 
---@return table momentData 
function CacheGameHistoryManager.GetMomentData(momentID) end
---**Contexts:** UI
---
---*Query*
---@param momentID number 
---@return string momentType 
function CacheGameHistoryManager.GetMomentType(momentID) end
---**Contexts:** UI
---
---*Query*
---@return string path 
---@return string fileName 
function CacheGameHistoryManager.WritePrideMomentInfo() end

z_dontRef_types.CacheGameHistoryManager = CacheGameHistoryManager