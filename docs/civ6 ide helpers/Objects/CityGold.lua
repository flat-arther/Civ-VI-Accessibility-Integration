---@meta


---**Contexts:** UI
---@class CityGold
local CityGold = {}
---@type table<userdata, table>
CityGold.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
CityGold.TypeName = "CityGold"
---**Contexts:** UI
---
---*Query*
---@param plotID number 
---@return number cost 
function CityGold:GetPlotPurchaseCost(plotID) end
---**Contexts:** UI
---
---*Query*
---@param yieldID number 
---@param any_DistrictUnitBuildingHash number 
---@param formationType MilitaryFormationTypes 
---@return number cost 
function CityGold:GetPurchaseCost(yieldID, any_DistrictUnitBuildingHash, formationType) end
---**Contexts:** UI
---
---*Query*
---@param buildingHash number 
---@return boolean  
function CityGold:IsBuildingFaithPurchaseEnabled(buildingHash) end
---**Contexts:** UI
---
---*Query*
---@param unitHash number 
---@return boolean  
function CityGold:IsUnitFaithPurchaseEnabled(unitHash) end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function CityGold:CanPlaceUnit() end

z_dontRef_types.CityGold = CityGold