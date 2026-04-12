---@meta


---**Contexts:** UI
---@class CacheGameEconomicManager
local CacheGameEconomicManager = {}
---@type table<userdata, table>
CacheGameEconomicManager.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
CacheGameEconomicManager.TypeName = "CacheGameEconomicManager"
---**Contexts:** UI
---
---*Query*
---@return boolean  
function CacheGameEconomicManager:IsResourceMonopoly() end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@return table corporations 
function CacheGameEconomicManager:GetPlayerCorporations(playerID) end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@param resourceIndex number 
---@return boolean  
function CacheGameEconomicManager:HasIndustry(playerID, resourceIndex) end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@param resourceIndex number 
---@return boolean  
function CacheGameEconomicManager:CanHaveIndustry(playerID, resourceIndex) end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@param resourceIndex number 
---@return string corpName 
function CacheGameEconomicManager:GetCorporationName(playerID, resourceIndex) end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@return table industries 
function CacheGameEconomicManager:GetPlayerIndustries(playerID) end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@param resourceIndex number 
---@return boolean  
function CacheGameEconomicManager:HasCorporation(playerID, resourceIndex) end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@param resourceIndex number 
---@return boolean  
function CacheGameEconomicManager:HasCorporationOf(playerID, resourceIndex) end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@param resourceIndex number 
---@return number amount 
function CacheGameEconomicManager:GetNumControlledResources(playerID, resourceIndex) end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@param resourceIndex number 
---@return boolean  
function CacheGameEconomicManager:HasIndustryOf(playerID, resourceIndex) end
---**Contexts:** UI
---
---*Query*
---@param resourceIndex number 
---@return number playerID 
function CacheGameEconomicManager:GetResourceMonopolyPlayer(resourceIndex) end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@param resourceIndex number 
function CacheGameEconomicManager:CanHaveCorporation(playerID, resourceIndex) end
---**Contexts:** UI
---
---*Query*
---@return table resources 
function CacheGameEconomicManager:GetMapResources() end

z_dontRef_types.CacheGameEconomicManager = CacheGameEconomicManager