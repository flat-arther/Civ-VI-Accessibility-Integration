---@meta


---**Contexts:** Gameplay, UI
Map = {}
---**Contexts:** Gameplay, UI
---
---*Query*
---@param Plot Plot 
---@param range number 
---@param isFreshwater boolean 
---@return boolean  
function Map.FindWater(Plot, range, isFreshwater) end
---**Contexts:** Gameplay, UI
---
---*Query*
function Map.GetAdjacentPlot() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return CityPlots CityPlots 
function Map.GetCityPlots() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Map.GetContinentCoastalPlots() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Map.GetContinentPlots() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Map.GetContinentPlotsAppeal() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Map.GetContinentPlotsWaterAvailability() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Map.GetContinentsInUse() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Map.GetGridSize() end
---**Contexts:** Gameplay, UI
---
---*Action*
---@return MapImprovementBuilder MapImprovementBuilder 
function Map.GetImprovementBuilder() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Map.GetLandPlotCount() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Map.GetLandResourceCount() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number mapSizeIndex 
function Map.GetMapSize() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Map.GetMaxPlotDistance() end
---**Contexts:** Gameplay, UI
---
---*Action*
---@param x number 
---@param y number 
---@return Plot Plot 
function Map.GetPlot(x, y) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param plotID number 
---@return Plot Plot 
function Map.GetPlotByIndex(plotID) end
---**Contexts:** Gameplay, UI
---
---*Query*
function Map.GetPlotCount() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param plot1X number 
---@param plot1Y number 
---@param plot2X number 
---@param plot2Y number 
---@return number tileDistance 
function Map.GetPlotDistance(plot1X, plot1Y, plot2X, plot2Y) end
---**Contexts:** Gameplay, UI
---
---*Query*
function Map.GetPlotIndex() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Map.GetPlotLocation() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Map.GetPlotXY() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Map.GetPlotXYWithRangeCheck() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Map.GetResourceCount() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Map.GetVisibleContinentPlots() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Map.IsPlot() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Map.IsWrapX() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Map.IsWrapY() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param Plot Plot 
---@return Unit[] units 
function Map.GetUnitsAt(Plot) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param Plot Plot 
---@param unknown number 
---@return boolean  
function Map.FindSecondContinent(Plot, unknown) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return Plot[] plots 
function Map.GetContinentPlotsLoyalty() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param x number 
---@param y number 
---@return Plot[] plots 
function Map.GetAdjacentPlots(x, y) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param x number 
---@param y number 
---@param range number 
function Map.GetNeighborPlots(x, y, range) end
---**Contexts:** Gameplay, UI
---
---*Query*
function Map.GetWorldSize() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param featureIndex number 
---@return number amount 
function Map.GetFeatureCount(featureIndex) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param x number 
---@param y number 
---@param ringLevel number 
---@return Plot[] plots 
function Map.GetRingPlots(x, y, ringLevel) end