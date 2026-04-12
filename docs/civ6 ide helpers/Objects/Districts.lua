---@meta


---**Contexts:** Gameplay, UI
---@class Districts
local Districts = {}
---@type table<userdata, table>
Districts.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
Districts.TypeName = "Districts"
---**Contexts:** UI
---
---*Query*
---@param districtID number 
---@return District District 
function Districts:FindID(districtID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param districtIndex number 
---@return District District 
function Districts:GetDistrict(districtIndex) end
---**Contexts:** Gameplay
---
---*Query*
---@param districtID number 
---@return number x 
---@return number y 
function Districts:GetDistrictLocation(districtID) end
---**Contexts:** UI
---
---*Query*
---@return number amount 
function Districts:GetNumAllowedDistrictsRequiringPopulation() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number amount 
function Districts:GetNumDistricts() end
---**Contexts:** UI
---
---*Query*
---@return number amount 
function Districts:GetNumZonedDistrictsRequiringPopulation() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param districtID number 
---@return boolean  
function Districts:HasDistrict(districtID) end
---**Contexts:** UI
---
---*Query*
---@param districtID number 
---@return boolean  
function Districts:IsContaminated(districtID) end
---**Contexts:** UI
---
---*Query*
---@param districtID number 
---@param Plot Plot 
---@return boolean  
function Districts:IsPillaged(districtID, Plot) end
---**Contexts:** UI
---
---*Query*
---@return table members 
function Districts:Members() end
---**Contexts:** Gameplay
---
---*Query*
function Districts:GetDistrictByIndex() end
---**Contexts:** Gameplay
---
---*Action*
function Districts:RemoveDistrict() end
---**Contexts:** UI
---
---*Query*
function Districts:GetCount() end
---**Contexts:** Gameplay
---
---*Query*
function Districts:GetDistrictAtLocation() end
---**Contexts:** Gameplay
---
---*Action*
function Districts:SetDistrictPillaged() end
---**Contexts:** Gameplay
---
---*Query*
function Districts:GetDistrictByType() end
---**Contexts:** Gameplay
---
---*Query*
function Districts:GetDistrictByID() end
---**Contexts:** Gameplay
---
---*Query*
function Districts:GetNumDistrictsOfType() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Districts:IsComplete() end
---**Contexts:** Gameplay
---
---*Query*
---@return number plotID 
function Districts:GetPrereqDistrictPlotID() end

z_dontRef_types.Districts = Districts