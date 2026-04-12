---@meta


---**Contexts:** Gameplay, UI
---@class CityReligion
local CityReligion = {}
---@type table<userdata, table>
CityReligion.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
CityReligion.TypeName = "CityReligion"
---**Contexts:** Gameplay
---
---*Action*
---@param unknown number 
---@param religionID number 
---@param pressure number 
---@param majorPlayerID number 
function CityReligion:AddReligiousPressure(unknown, religionID, pressure, majorPlayerID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number pantheonID 
function CityReligion:GetActivePantheon() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number religionID 
function CityReligion:GetMajorityReligion() end
---**Contexts:** Gameplay
---
---*Query*
---@return number followerCount 
function CityReligion:GetNumFollowers() end
---**Contexts:** UI
---
---*Query*
---@return number pressure 
function CityReligion:GetPressureFromCity() end
---**Contexts:** UI
---
---*Query*
---@return table religions 
function CityReligion:GetReligionsInCity() end
---**Contexts:** UI
---
---*Query*
---@param religionID number 
---@return number pressure 
function CityReligion:GetTotalPressureOnCity(religionID) end
---**Contexts:** Gameplay
---
---*Action*
---@param religionID number 
function CityReligion:SetAllCityToReligion(religionID) end
---**Contexts:** Gameplay
---
---*Action*
function CityReligion:AddOneFollower() end
---**Contexts:** Gameplay
---
---*Action*
function CityReligion:RemoveOtherReligions() end
---**Contexts:** Gameplay
---
---*Action*
function CityReligion:RemovePressureOneReligion() end
---**Contexts:** UI
---
---*Query*
function CityReligion:GetNextReligion() end
---**Contexts:** UI
---
---*Query*
function CityReligion:GetTurnsToNextReligion() end
---**Contexts:** UI
---
---*Query*
function CityReligion:GetReligiousPressureSources() end
---**Contexts:** UI
---
---*Query*
---@return City City 
function CityReligion:GetCity() end

z_dontRef_types.CityReligion = CityReligion