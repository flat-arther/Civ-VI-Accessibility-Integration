---@meta


---**Contexts:** Gameplay, UI
---@class CityBuildings
local CityBuildings = {}
---@type table<userdata, table>
CityBuildings.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
CityBuildings.TypeName = "CityBuildings"
---**Contexts:** UI
---
---*Query*
---@param plotID number 
---@return table buildings 
function CityBuildings:GetBuildingsAtLocation(plotID) end
---**Contexts:** UI
---
---*Query*
---@param includingReligiousTourism boolean 
---@param buildingIndex number 
---@return number tourism 
function CityBuildings:GetBuildingTourismFromGreatWorks(includingReligiousTourism, buildingIndex) end
---**Contexts:** UI
---
---*Query*
---@param yieldID number 
---@param buildingIndex number 
---@return number amount 
function CityBuildings:GetBuildingYieldFromGreatWorks(yieldID, buildingIndex) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return City City 
function CityBuildings:GetCity() end
---**Contexts:** UI
---
---*Query*
---@param greatWorkID number 
---@return string creatorName 
function CityBuildings:GetCreatorNameFromIndex(greatWorkID) end
---**Contexts:** UI
---
---*Query*
---@param buildingIndex number 
---@param slotID number 
---@return number greatWorkID 
function CityBuildings:GetGreatWorkInSlot(buildingIndex, slotID) end
---**Contexts:** UI
---
---*Query*
---@param buildingIndex number 
---@param slotID number 
---@return number slotType 
function CityBuildings:GetGreatWorkSlotType(buildingIndex, slotID) end
---**Contexts:** UI
---
---*Query*
---@param greatWorkID number 
---@return number greatWorkType 
function CityBuildings:GetGreatWorkTypeFromIndex(greatWorkID) end
---**Contexts:** UI
---
---*Query*
---@param buildingIndex number 
---@return number amount 
function CityBuildings:GetNumGreatWorkSlots(buildingIndex) end
---**Contexts:** UI
---
---*Query*
---@param greatWorkID number 
---@return number turn 
function CityBuildings:GetTurnFromIndex(greatWorkID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param buildingIndex number 
---@return boolean  
function CityBuildings:HasBuilding(buildingIndex) end
---**Contexts:** UI
---
---*Query*
---@param buildingIndex number 
---@return boolean  
function CityBuildings:IsBuildingThemedCorrectly(buildingIndex) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param buildingIndex number 
---@return boolean  
function CityBuildings:IsPillaged(buildingIndex) end
---**Contexts:** Gameplay
---
---*Action*
---@param buildingIndex number 
function CityBuildings:RemoveBuilding(buildingIndex) end
---**Contexts:** Gameplay
---
---*Action*
---@param buildingIndex number 
---@param isPillaged boolean 
function CityBuildings:SetPillaged(buildingIndex, isPillaged) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param buildingIndex boolean 
---@return number maintenanceCost 
function CityBuildings:GetBuildingMaintenance(buildingIndex) end
---**Contexts:** Gameplay
---
---*Action*
---@param x number 
---@param y number 
function CityBuildings:SetBuildingLocation(x, y) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param buildingIndex number 
---@return string overrideName 
function CityBuildings:GetBuildingNameOverride(buildingIndex) end
---**Contexts:** Gameplay
---
---*Query*
---@return number x 
---@return number y 
function CityBuildings:GetBuildingLocation() end
---**Contexts:** UI
---
---*Query*
function CityBuildings:GetPlayerFromIndex() end

z_dontRef_types.CityBuildings = CityBuildings