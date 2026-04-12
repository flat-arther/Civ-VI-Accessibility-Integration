---@meta


---**Contexts:** UI
---@class CityPower
local CityPower = {}
---@type table<userdata, table>
CityPower.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
CityPower.TypeName = "CityPower"
---**Contexts:** UI
---
---*Query*
---@return number amount 
function CityPower:GetFreePower() end
---**Contexts:** UI
---
---*Query*
---@return table breakdown 
function CityPower:GetFreePowerSources() end
---**Contexts:** UI
---
---*Query*
---@return table breakdown 
function CityPower:GetGeneratedPowerSources() end
---**Contexts:** UI
---
---*Query*
---@return number amount 
function CityPower:GetMissingPower() end
---**Contexts:** UI
---
---*Query*
---@return Plot[] plots 
function CityPower:GetPlotsCoveredByRegionalPower() end
---**Contexts:** UI
---
---*Query*
---@return Plot[] plots 
function CityPower:GetPlotsProvidingPower() end
---**Contexts:** UI
---
---*Query*
---@return number amount 
function CityPower:GetRequiredPower() end
---**Contexts:** UI
---
---*Query*
---@return table breakdown 
function CityPower:GetRequiredPowerSources() end
---**Contexts:** UI
---
---*Query*
---@return number amount 
function CityPower:GetTemporaryPower() end
---**Contexts:** UI
---
---*Query*
---@return table breakdown 
function CityPower:GetTemporaryPowerSources() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function CityPower:IsFullyPowered() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function CityPower:IsFullyPoweredByActiveProject() end

z_dontRef_types.CityPower = CityPower