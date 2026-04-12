---@meta


---**Contexts:** UI
---@class CacheCongressManager
local CacheCongressManager = {}
---@type table<userdata, table>
CacheCongressManager.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
CacheCongressManager.TypeName = "CacheCongressManager"
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@return table costData 
function CacheCongressManager:GetVotesandFavorCost(playerID) end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function CacheCongressManager:IsInSession() end
---**Contexts:** UI
---
---*Query*
---@return table congressMeetingData 
function CacheCongressManager:GetMeetingStatus() end
---**Contexts:** UI
---
---*Query*
---@return table resolutions 
function CacheCongressManager:GetResolutions() end
---**Contexts:** UI
---
---*Query*
function CacheCongressManager:GetEmergencies() end
---**Contexts:** UI
---
---*Query*
function CacheCongressManager:GetPreviousVotesOnResolution() end
---**Contexts:** UI
---
---*Query*
function CacheCongressManager:GetReview() end
---**Contexts:** UI
---
---*Query*
function CacheCongressManager:GetTurnsUntilSpecialSessionAllowed() end
---**Contexts:** UI
---
---*Query*
function CacheCongressManager:GetProposals() end

z_dontRef_types.CacheCongressManager = CacheCongressManager