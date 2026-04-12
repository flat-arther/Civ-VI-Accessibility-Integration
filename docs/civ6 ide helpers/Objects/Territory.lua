---@meta


---**Contexts:** Gameplay, UI
---@class Territory
local Territory = {}
---@type table<userdata, table>
Territory.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
Territory.TypeName = "Territory"
---**Contexts:** Gameplay, UI
---
---*Query*
function Territory:GetName() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number centerX 
---@return number centerY 
function Territory:GetCentroid() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Territory:IsSea() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Territory:IsLake() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number terrainClassIndex 
function Territory:GetTerrainClass() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number territoryID 
function Territory:GetID() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Territory:GetTotalNaturalWonders() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Territory:GetRiverEdgeCount() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Territory:GetPlotCount() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Territory:GetBoundaries() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Territory:GetTotalFeatures() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Territory:IsNone() end
---**Contexts:** Gameplay
---
---*Action*
function Territory:SetName() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Territory:GetFeatureCount() end

z_dontRef_types.Territory = Territory