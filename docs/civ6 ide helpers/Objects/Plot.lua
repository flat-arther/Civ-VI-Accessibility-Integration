---@meta


---**Contexts:** UI
---@class Plot
local Plot = {}
---@type table<userdata, table>
Plot.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
Plot.TypeName = "Plot"
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Plot:CanHaveDistrict() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Plot:CanHaveWonder() end
---**Contexts:** UI
---
---*Query*
function Plot:GetAdjacencyBonusTooltip() end
---**Contexts:** UI
---
---*Query*
function Plot:GetAdjacencyBonusType() end
---**Contexts:** UI
---
---*Query*
function Plot:GetAdjacencyYield() end
---**Contexts:** UI
---
---*Query*
function Plot:GetAirUnits() end
---**Contexts:** UI
---
---*Query*
function Plot:GetAppeal() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return Area Area 
function Plot:GetArea() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number areaID 
function Plot:GetAreaID() end
---**Contexts:** UI
---
---*Query*
function Plot:GetContinentType() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Plot:GetDefenseModifier() end
---**Contexts:** UI
---
---*Query*
function Plot:GetDistrictID() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Plot:GetDistrictType() end
---**Contexts:** Gameplay
---
---*Query*
---@return MapFeature MapFeature 
function Plot:GetFeature() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Plot:GetFeatureType() end
---**Contexts:** Gameplay
---
---*Query*
function Plot:GetImprovementOwner() end
---**Contexts:** Gameplay
---
---*Query*
function Plot:GetImprovementType() end
---**Contexts:** Gameplay
---
---*Query*
---@return number plotID 
function Plot:GetIndex() end
---**Contexts:** Gameplay
---
---*Query*
function Plot:GetMovementCost() end
---**Contexts:** Gameplay
---
---*Query*
function Plot:GetNationalParkName() end
---**Contexts:** Gameplay
---
---*Query*
function Plot:GetNearestLandArea() end
---**Contexts:** Gameplay
---
---*Query*
function Plot:GetNearestLandPlot() end
---**Contexts:** Gameplay
---
---*Query*
function Plot:GetOwner() end
---**Contexts:** Gameplay
---
---*Query*
---@param property string 
---@return any value 
function Plot:GetProperty(property) end
---**Contexts:** Gameplay
---
---*Query*
function Plot:GetResourceCount() end
---**Contexts:** Gameplay
---
---*Query*
function Plot:GetResourceType() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Plot:GetResourceTypeHash() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Plot:GetRiverCrossingCount() end
---**Contexts:** UI
---
---*Query*
function Plot:GetRiverEFlowDirection() end
---**Contexts:** Gameplay
---
---*Query*
function Plot:GetRiverSEFlowDirection() end
---**Contexts:** UI
---
---*Query*
function Plot:GetRiverSWFlowDirection() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Plot:GetRouteType() end
---**Contexts:** UI
---
---*Query*
function Plot:GetTerrainType() end
---**Contexts:** UI
---
---*Query*
function Plot:GetUnitCount() end
---**Contexts:** UI
---
---*Query*
function Plot:GetWonderType() end
---**Contexts:** UI
---
---*Query*
function Plot:GetWorkerCount() end
---**Contexts:** UI
---
---*Query*
---@return number x 
function Plot:GetX() end
---**Contexts:** UI
---
---*Query*
---@return number y 
function Plot:GetY() end
---**Contexts:** UI
---
---*Query*
---@param yieldType YieldTypes 
---@return number yield 
function Plot:GetYield(yieldType) end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Plot:HasFeatureBeenAdded() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Plot:IsAdjacentOwned() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Plot:IsAdjacentPlayer() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function Plot:IsAdjacentToArea() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Plot:IsAdjacentToLand() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function Plot:IsAdjacentToShallowWater() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Plot:IsAt() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function Plot:IsCanyon() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function Plot:IsChokepoint() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Plot:IsCity() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function Plot:IsCoastalLand() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function Plot:IsFlatlands() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Plot:IsFreshWater() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function Plot:IsHills() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function Plot:IsImpassable() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function Plot:IsImprovementPillaged() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function Plot:IsInternalOnlyDistrict() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Plot:IsLake() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Plot:IsMountain() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Plot:IsNationalPark() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function Plot:IsNaturalWonder() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Plot:IsNEOfCliff() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Plot:IsNEOfRiver() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function Plot:IsNone() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Plot:IsNWOfCliff() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Plot:IsNWOfRiver() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Plot:IsOpenGround() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Plot:IsOwned() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Plot:IsRiver() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function Plot:IsRiverAdjacent() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Plot:IsRiverConnection() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function Plot:IsRiverCrossing() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Plot:IsRiverCrossingFlowClockwise() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function Plot:IsRiverCrossingToPlot() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Plot:IsRiverSide() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Plot:IsRoughGround() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Plot:IsRoute() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Plot:IsRoutePillaged() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Plot:IsStartingPlot() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Plot:IsUnit() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Plot:IsValidFoundLocation() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Plot:IsWater() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Plot:IsWOfCliff() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Plot:IsWOfRiver() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Plot:IsWonderComplete() end
---**Contexts:** UI
---
---*Action*
---@param playerID number 
function Plot:SetOwner(playerID) end
---**Contexts:** Gameplay
---
---*Action*
---@param key string 
---@param value any 
function Plot:SetProperty(key, value) end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function Plot:SharesAdjacentArea() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number terrainClassIndex 
function Plot:GetTerrainClassType() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return table componentIDs 
function Plot:GetComponentID() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Plot:IsShallowWater() end

z_dontRef_types.Plot = Plot