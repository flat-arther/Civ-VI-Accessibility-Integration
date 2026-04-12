---@meta


---**Contexts:** UI
---@class CacheGovernor
local CacheGovernor = {}
---@type table<userdata, table>
CacheGovernor.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
CacheGovernor.TypeName = "CacheGovernor"
---**Contexts:** UI
---
---*Query*
function CacheGovernor:GetComponentID() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function CacheGovernor:HasPromotion() end
---**Contexts:** UI
---
---*Query*
function CacheGovernor:GetOwner() end
---**Contexts:** UI
---
---*Query*
function CacheGovernor:CanAssignToMajorCiv() end
---**Contexts:** UI
---
---*Query*
function CacheGovernor:GetNeutralizedTurns() end
---**Contexts:** UI
---
---*Query*
function CacheGovernor:GetIdentityPressure() end
---**Contexts:** UI
---
---*Query*
function CacheGovernor:GetType() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function CacheGovernor:IsGovernCityState() end
---**Contexts:** UI
---
---*Query*
function CacheGovernor:IsEstablished() end
---**Contexts:** UI
---
---*Query*
function CacheGovernor:GetAssignedCity() end
---**Contexts:** UI
---
---*Query*
function CacheGovernor:GetTurnsOnSite() end
---**Contexts:** UI
---
---*Query*
function CacheGovernor:GetID() end
---**Contexts:** UI
---
---*Query*
function CacheGovernor:GetName() end

z_dontRef_types.CacheGovernor = CacheGovernor