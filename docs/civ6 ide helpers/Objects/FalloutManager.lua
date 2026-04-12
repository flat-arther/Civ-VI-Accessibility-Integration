---@meta


---**Contexts:** Gameplay, UI
---@class FalloutManager
local FalloutManager = {}
---@type table<userdata, table>
FalloutManager.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
FalloutManager.TypeName = "FalloutManager"
---**Contexts:** Gameplay
---
---*Action*
---@param plotID number 
---@param turns number 
function FalloutManager:AddFallout(plotID, turns) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param plotID number 
---@return boolean  
function FalloutManager:HasFallout(plotID) end
---**Contexts:** Gameplay
---
---*Action*
---@param plotID number 
function FalloutManager:RemoveFallout(plotID) end
---**Contexts:** Gameplay
---
---*Action*
---@param plotID number 
---@param allow boolean 
---@return boolean  
function FalloutManager:SetFalloutPreventsWork(plotID, allow) end
---**Contexts:** Gameplay
---
---*Action*
---@param plotID number 
---@param turns number 
function FalloutManager:SetFalloutTurnsRemaining(plotID, turns) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param plotID number 
---@return number turns 
function FalloutManager:GetFalloutTurnsRemaining(plotID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number amount 
function FalloutManager:GetReactorCount() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param plotID number 
---@return boolean  
function FalloutManager:GetFalloutPreventsWork(plotID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number damage 
function FalloutManager:GetFalloutDamageOverride() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param reactorID number 
---@return table reactorInfo 
function FalloutManager:GetReactorByIndex(reactorID) end
---**Contexts:** Gameplay
---
---*Action*
---@param damage number 
function FalloutManager:SetFalloutDamageOverride(damage) end
---**Contexts:** UI
---
---*Query*
---@param City City 
---@return number age 
function FalloutManager:GetReactorAge(City) end
---**Contexts:** UI
---
---*Query*
---@param City City 
---@return number threshold 
function FalloutManager:GetReactorAccidentThreshold(City) end

z_dontRef_types.FalloutManager = FalloutManager