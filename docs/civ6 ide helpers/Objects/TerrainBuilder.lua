---@meta


---**Contexts:** Gameplay
TerrainBuilder = {}
---**Contexts:** Gameplay
---
---*Query*
---@param Plot Plot 
---@param terrainIndex number 
function TerrainBuilder.CanHaveFeature(Plot, terrainIndex) end
---**Contexts:** Gameplay
---
---*Query*
function TerrainBuilder.GetAdjacentFeatureCount() end
---**Contexts:** Gameplay
---
---*Query*
---@param upperLimit number 
---@param logDescription string 
---@return number number 
function TerrainBuilder.GetRandomNumber(upperLimit, logDescription) end
---**Contexts:** Gameplay
---
---*Action*
---@param Plot Plot 
---@param featureID number 
function TerrainBuilder.SetFeatureType(Plot, featureID) end
---**Contexts:** Gameplay
---
---*Action*
---@param Plot Plot 
---@param terrainIndex number 
function TerrainBuilder.SetTerrainType(Plot, terrainIndex) end
---**Contexts:** Gameplay
---
---*Action*
function TerrainBuilder.SetMultiPlotFeatureType() end
---**Contexts:** Gameplay
---
---*Action*
function TerrainBuilder.SetNWOfRiver() end
---**Contexts:** Gameplay
---
---*Action*
function TerrainBuilder.SetNEOfCliff() end
---**Contexts:** Gameplay
---
---*Action*
function TerrainBuilder.SetContinentType() end
---**Contexts:** Gameplay
---
---*Query*
function TerrainBuilder.GetInlandCorner() end
---**Contexts:** Gameplay
---
---*Query*
function TerrainBuilder.AnalyzeChokepoints() end
---**Contexts:** Gameplay
---
---*Action*
function TerrainBuilder.SetNEOfRiver() end
---**Contexts:** Gameplay
---
---*Action*
---@param plotID number 
---@param elevation number 
function TerrainBuilder.AddCoastalLowland(plotID, elevation) end
---**Contexts:** Gameplay
---
---*Action*
function TerrainBuilder.SetWOfCliff() end
---**Contexts:** Gameplay
---
---*Action*
function TerrainBuilder.AddIce() end
---**Contexts:** Gameplay
---
---*Action*
function TerrainBuilder.SetWOfRiver() end
---**Contexts:** Gameplay
---
---*Query*
function TerrainBuilder.GetFractalFlags() end
---**Contexts:** Gameplay
---
---*Action*
function TerrainBuilder.GenerateFloodplains() end
---**Contexts:** Gameplay
---
---*Action*
function TerrainBuilder.SetNWOfCliff() end
---**Contexts:** Gameplay
---
---*Action*
function TerrainBuilder.StampContinents() end
---**Contexts:** Gameplay
---
---*Query*
function TerrainBuilder.GetFeaturePlacementPlotList() end
---**Contexts:** Gameplay
---
---*Action*
---@param Plot Plot 
---@param resourceIndex number 
---@param resourceAmount number 
function TerrainBuilder.SetResourceType(Plot, resourceIndex, resourceAmount) end
---**Contexts:** Gameplay
---
---*Query*
---@param Plot Plot 
---@param resourceIndex number 
---@return boolean  
function TerrainBuilder.CanHaveResource(Plot, resourceIndex) end