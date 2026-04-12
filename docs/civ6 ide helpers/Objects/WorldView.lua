---@meta


---**Contexts:** UI
WorldView = {}
---**Contexts:** UI
---
---*Query*
---@param featureIndex number 
---@return boolean  
function WorldView.HasAssetForFeature(featureIndex) end
---**Contexts:** UI
---
---*Action*
---@param effect string 
---@param x number 
---@param y number 
function WorldView.PlayEffectAtXY(effect, x, y) end
---**Contexts:** UI
---
---*Action*
---@param effect string 
---@param amount number 
function WorldView.SetVFXImport(effect, amount) end
---**Contexts:** UI
---
---*Query*
---@param districtIndex number 
---@return boolean  
function WorldView.HasAssetForDistrict(districtIndex) end
---**Contexts:** UI
---
---*Query*
---@param buildingIndex number 
---@return boolean  
function WorldView.HasAssetForWonder(buildingIndex) end
---**Contexts:** UI
---
---*Query*
---@param resourceIndex number 
---@return boolean  
function WorldView.HasAssetForResource(resourceIndex) end
---**Contexts:** UI
---
---*Query*
---@param unitIndex number 
---@return boolean  
function WorldView.HasAssetForUnit(unitIndex) end
---**Contexts:** UI
---
---*Query*
---@param buildingIndex number 
---@return boolean  
function WorldView.HasAssetForBuilding(buildingIndex) end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function WorldView.HasAssetFor() end