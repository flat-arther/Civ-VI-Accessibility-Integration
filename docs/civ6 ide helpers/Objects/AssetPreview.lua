---@meta


---**Contexts:** UI
AssetPreview = {}
---**Contexts:** UI
---
---*Query*
---@param districtID number 
---@return table buildings 
function AssetPreview.GetDistrictBuildingList(districtID) end
---**Contexts:** UI
---
---*Action*
function AssetPreview.DestroyAll() end
---**Contexts:** UI
---
---*Action*
---@param x number 
---@param y number 
function AssetPreview.ClearLandmarkAt(x, y) end
---**Contexts:** UI
---
---*Query*
---@param instanceID number 
function AssetPreview.GetInstanceInfoByID(instanceID) end
---**Contexts:** UI
---
---*Action*
function AssetPreview.SetInstancePosition() end
---**Contexts:** UI
---
---*Action*
function AssetPreview.ClearLandmarkSystem() end
---**Contexts:** UI
---
---*Action*
function AssetPreview.SetInstanceAnimation() end
---**Contexts:** UI
---
---*Action*
function AssetPreview.CreateDistrictAt() end
---**Contexts:** UI
---
---*Query*
function AssetPreview.GetDistrictBaseList() end
---**Contexts:** UI
---
---*Query*
---@return number amount 
function AssetPreview.GetLandmarkCount() end
---**Contexts:** UI
---
---*Query*
---@return number amount Number of 3D asset XLP entries
function AssetPreview.GetAssetCount() end
---**Contexts:** UI
---
---*Action*
function AssetPreview.SpoofLandmarkAt() end
---**Contexts:** UI
---
---*Query*
function AssetPreview.GetLandmarkAssetList() end
---**Contexts:** UI
---
---*Query*
function AssetPreview.GetInstanceCount() end
---**Contexts:** UI
---
---*Action*
function AssetPreview.SpoofBuildingAt() end
---**Contexts:** UI
---
---*Query*
function AssetPreview.GetUnitList() end
---**Contexts:** UI
---
---*Action*
---@param text string 
---@return number hash 
function AssetPreview.MakeHash(text) end
---**Contexts:** UI
---
---*Query*
---@param civilizationHash number 
---@return string name 
function AssetPreview.GetCivName(civilizationHash) end
---**Contexts:** UI
---
---*Action*
function AssetPreview.SetInstanceScale() end
---**Contexts:** UI
---
---*Query*
function AssetPreview.GetAppealName() end
---**Contexts:** UI
---
---*Query*
function AssetPreview.GetInstanceInfoByIndex() end
---**Contexts:** UI
---
---*Action*
function AssetPreview.SetInstanceSequenceLock() end
---**Contexts:** UI
---
---*Action*
function AssetPreview.Destroy() end
---**Contexts:** UI
---
---*Action*
function AssetPreview.Create() end
---**Contexts:** UI
---
---*Action*
function AssetPreview.ClearUnitSystem() end
---**Contexts:** UI
---
---*Action*
function AssetPreview.SpoofCityCivAt() end
---**Contexts:** UI
---
---*Action*
function AssetPreview.CreateBuildingAt() end
---**Contexts:** UI
---
---*Action*
function AssetPreview.SpoofUnitAt() end
---**Contexts:** UI
---
---*Action*
function AssetPreview.SetInstanceAutoDestroy() end
---**Contexts:** UI
---
---*Action*
function AssetPreview.SetInstanceCulling() end
---**Contexts:** UI
---
---*Action*
function AssetPreview.SetInstanceOrientation() end
---**Contexts:** UI
---
---*Action*
function AssetPreview.SpoofCityAt() end
---**Contexts:** UI
---
---*Action*
function AssetPreview.SpoofDistrictBaseAt() end
---**Contexts:** UI
---
---*Query*
function AssetPreview.GetLandmarkName() end
---**Contexts:** UI
---
---*Query*
function AssetPreview.GetDistrictName() end
---**Contexts:** UI
---
---*Query*
function AssetPreview.GetAssetName() end
---**Contexts:** UI
---
---*Query*
function AssetPreview.GetEraName() end
---**Contexts:** UI
---
---*Action*
function AssetPreview.DestroyAt() end
---**Contexts:** UI
---
---*Action*
function AssetPreview.SetInstanceAssetState() end
---**Contexts:** UI
---
---*Query*
function AssetPreview.GetDistrictCount() end