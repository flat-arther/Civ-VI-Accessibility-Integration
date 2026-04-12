---@meta


---**Contexts:** Gameplay
---@class WorldBuilderMapManager
local WorldBuilderMapManager = {}
---@type table<userdata, table>
WorldBuilderMapManager.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
WorldBuilderMapManager.TypeName = "WorldBuilderMapManager"
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function WorldBuilderMapManager:CanPlaceResource() end
---**Contexts:** Gameplay
---
---*Query*
function WorldBuilderMapManager:GetPlotValue() end
---**Contexts:** Gameplay
---
---*Query*
function WorldBuilderMapManager:DoesPlotBorderRiver() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function WorldBuilderMapManager:IsImprovementPlaceable() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderMapManager:EditCliff() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function WorldBuilderMapManager:CanPlaceImprovement() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function WorldBuilderMapManager:CanPlaceFeature() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderMapManager:SetContinentType() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function WorldBuilderMapManager:IsWonderTooClose() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderMapManager:SetImprovementType() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderMapManager:SetImprovementPillaged() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderMapManager:SetRouteType() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderMapManager:LoadPlotsFromTiled() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderMapManager:SetPlotValue() end
---**Contexts:** Gameplay
---
---*Query*
function WorldBuilderMapManager:GetDimensionsFromTiled() end
---**Contexts:** Gameplay
---
---*Query*
function WorldBuilderMapManager:GetContinentPlots() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderMapManager:SetFeatureType() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderMapManager:SetAllRevealed() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderMapManager:SetCoastalLowland() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderMapManager:SetResourceType() end
---**Contexts:** Gameplay
---
---*Query*
function WorldBuilderMapManager:GetFeaturePlacementPlotList() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderMapManager:SetRevealed() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderMapManager:EditRiver() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderMapManager:SetTerrainType() end

z_dontRef_types.WorldBuilderMapManager = WorldBuilderMapManager