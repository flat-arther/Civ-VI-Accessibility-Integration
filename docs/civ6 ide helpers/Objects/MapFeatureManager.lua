---@meta


---**Contexts:** Gameplay, UI
MapFeatureManager = {}
---**Contexts:** Gameplay, UI
---
---*Query*
---@param Plot Plot 
---@return boolean  
function MapFeatureManager.CanSufferEruption(Plot) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return table volcanoes 
function MapFeatureManager.GetNamedVolcanoes() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number amount 
function MapFeatureManager.GetNumActiveVolcanoes() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number amount 
function MapFeatureManager.GetNumEruptions() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number amount 
function MapFeatureManager.GetNumNaturalWonderVolcanoes() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number amount 
function MapFeatureManager.GetNumNormalVolcanoes() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number percent 
function MapFeatureManager.GetPercentVolcanoesActive() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param Plot Plot 
---@return number name 
function MapFeatureManager.GetVolcanoName(Plot) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function MapFeatureManager.IsActiveVolcano() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function MapFeatureManager.IsVolcano() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function MapFeatureManager.IsVolcanoErupting() end