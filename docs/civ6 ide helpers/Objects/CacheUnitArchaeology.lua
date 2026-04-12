---@meta


---**Contexts:** UI
---@class CacheUnitArchaeology
local CacheUnitArchaeology = {}
---@type table<userdata, table>
CacheUnitArchaeology.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
CacheUnitArchaeology.TypeName = "CacheUnitArchaeology"
---**Contexts:** UI
---
---*Query*
---@return Unit Unit 
function CacheUnitArchaeology:GetUnit() end
---**Contexts:** UI
---
---*Query*
function CacheUnitArchaeology:GetActivationHighlightPlots() end
---**Contexts:** UI
---
---*Query*
function CacheUnitArchaeology:GetGreatWorkIndex() end
---**Contexts:** UI
---
---*Query*
function CacheUnitArchaeology:GetAreaHighlightPlots() end
---**Contexts:** UI
---
---*Query*
function CacheUnitArchaeology:GetHomeBuilding() end
---**Contexts:** UI
---
---*Query*
function CacheUnitArchaeology:GetHomeCityID() end
---**Contexts:** UI
---
---*Query*
function CacheUnitArchaeology:GetArtifactIndex() end

z_dontRef_types.CacheUnitArchaeology = CacheUnitArchaeology