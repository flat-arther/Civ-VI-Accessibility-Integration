---@meta


---**Contexts:** Gameplay, UI
---@class BuildQueue
local BuildQueue = {}
---@type table<userdata, table>
BuildQueue.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
BuildQueue.TypeName = "BuildQueue"
---**Contexts:** Gameplay
---
---*Action*
---@param amount number 
function BuildQueue:AddProgress(amount) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param hash number 
---@param isAble boolean 
---@return boolean  
function BuildQueue:CanProduce(hash, isAble) end
---**Contexts:** Gameplay
---
---*Action*
---@param City City 
---@param buildingIndex number 
---@param progress number 
---@param plotID number 
function BuildQueue:CreateBuilding(City, buildingIndex, progress, plotID) end
---**Contexts:** Gameplay
---
---*Action*
---@param City City 
---@param districtID number 
---@param progress number 
---@param Plot Plot 
function BuildQueue:CreateDistrict(City, districtID, progress, Plot) end
---**Contexts:** Gameplay
---
---*Action*
---@param buildingIndex number 
---@param Plot Plot 
---@param progress number 
function BuildQueue:CreateIncompleteBuilding(buildingIndex, Plot, progress) end
---**Contexts:** Gameplay
---
---*Action*
---@param districtID number 
---@param Plot Plot 
---@param progress number 
function BuildQueue:CreateIncompleteDistrict(districtID, Plot, progress) end
---**Contexts:** Gameplay
---
---*Query*
---@return number buildingIndex 
function BuildQueue:CurrentlyBuilding() end
---**Contexts:** Gameplay
---
---*Action*
function BuildQueue:FinishProgress() end
---**Contexts:** UI
---
---*Query*
---@param buildingIndex number 
---@return number cost 
function BuildQueue:GetBuildingCost(buildingIndex) end
---**Contexts:** UI
---
---*Query*
---@param buildingIndex number 
---@return number progress 
function BuildQueue:GetBuildingProgress(buildingIndex) end
---**Contexts:** UI
---
---*Query*
---@return City City 
function BuildQueue:GetCity() end
---**Contexts:** UI
---
---*Query*
---@param hash number 
---@param type string 
---@param componentID number 
---@return Plot Plot 
function BuildQueue:GetConstructionPlot(hash, type, componentID) end
---**Contexts:** UI
---
---*Query*
---@param plotID number 
---@return table constructions 
function BuildQueue:GetConstructionsAtLocation(plotID) end
---**Contexts:** UI
---
---*Query*
---@return number hash 
function BuildQueue:GetCurrentProductionTypeHash() end
---**Contexts:** UI
---
---*Query*
---@return number modifier 
function BuildQueue:GetCurrentProductionTypeModifier() end
---**Contexts:** UI
---
---*Query*
---@param districtID number 
---@return number cost 
function BuildQueue:GetDistrictCost(districtID) end
---**Contexts:** UI
---
---*Query*
---@param districtID number 
---@return number progress 
function BuildQueue:GetDistrictProgress(districtID) end
---**Contexts:** UI
---
---*Query*
---@return number hash 
function BuildQueue:GetPreviousProductionTypeHash() end
---**Contexts:** UI
---
---*Query*
---@param projectID number 
---@return number cost 
function BuildQueue:GetProjectCost(projectID) end
---**Contexts:** UI
---
---*Query*
---@param projectID number 
---@return number progress 
function BuildQueue:GetProjectProgress(projectID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param componentID number 
---@return number turns 
function BuildQueue:GetTurnsLeft(componentID) end
---**Contexts:** UI
---
---*Query*
---@param unitIndex number 
---@return number cost 
function BuildQueue:GetUnitArmyCost(unitIndex) end
---**Contexts:** UI
---
---*Query*
---@param unitIndex number 
---@return number cost 
function BuildQueue:GetUnitCorpsCost(unitIndex) end
---**Contexts:** UI
---
---*Query*
---@param unitIndex number 
---@return number cost 
function BuildQueue:GetUnitCost(unitIndex) end
---**Contexts:** UI
---
---*Query*
---@param unitIndex number 
---@return number progress 
function BuildQueue:GetUnitProgress(unitIndex) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param any_districtBuildingHash number 
---@return boolean  
function BuildQueue:HasBeenPlaced(any_districtBuildingHash) end
---**Contexts:** UI
---
---*Query*
---@return number yield 
function BuildQueue:GetProductionYield() end
---**Contexts:** UI
---
---*Query*
---@return number length 
function BuildQueue:GetSize() end
---**Contexts:** UI
---
---*Query*
---@param position number 
---@return table entry 
function BuildQueue:GetAt(position) end
---**Contexts:** Gameplay
---
---*Action*
---@return number districtIndex 
function BuildQueue:RemoveDistrict() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function BuildQueue:HasProductionProgress() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function BuildQueue:HasBuildingProductionProgress() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function BuildQueue:HasBuildingBeenPlaced() end
---**Contexts:** Gameplay
---
---*Action*
---@return number buildingIndex 
function BuildQueue:RemoveBuilding() end
---**Contexts:** UI
---
---*Query*
---@return number cost 
function BuildQueue:GetUnitResourceCost() end
---**Contexts:** UI
---
---*Query*
---@return number numEntries 
function BuildQueue:GetNumEntriesOfProductionTypeHash() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function BuildQueue:HasDistrictProductionProgress() end
---**Contexts:** Gameplay
---
---*Query*
function BuildQueue:GetAvailableProductionTypes() end
---**Contexts:** Gameplay
---
---*Query*
function BuildQueue:CheckActiveProduction() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function BuildQueue:HasDistrictBeenPlaced() end

z_dontRef_types.BuildQueue = BuildQueue