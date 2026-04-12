---@meta


---**Contexts:** Gameplay
---@class WorldBuilderCityManager
local WorldBuilderCityManager = {}
---@type table<userdata, table>
WorldBuilderCityManager.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
WorldBuilderCityManager.TypeName = "WorldBuilderCityManager"
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderCityManager:CreateDistrict() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderCityManager:RemoveBuilding() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderCityManager:SetDistrictValue() end
---**Contexts:** Gameplay
---
---*Action*
---@param Plot Plot 
function WorldBuilderCityManager:RemoveAt(Plot) end
---**Contexts:** Gameplay
---
---*Query*
function WorldBuilderCityManager:GetDistrictValue() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderCityManager:Remove() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderCityManager:RemoveAll() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderCityManager:RemoveDistrict() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderCityManager:CreateBuilding() end
---**Contexts:** Gameplay
---
---*Query*
function WorldBuilderCityManager:GetPlotOwner() end
---**Contexts:** Gameplay
---
---*Query*
---@param City City 
---@param key string 
---@return number value 
function WorldBuilderCityManager:GetCityValue(City, key) end
---**Contexts:** Gameplay
---
---*Action*
---@param playerID number 
---@param Plot Plot 
function WorldBuilderCityManager:Create(playerID, Plot) end
---**Contexts:** Gameplay
---
---*Action*
---@param City City 
---@param key string 
---@param value number 
function WorldBuilderCityManager:SetCityValue(City, key, value) end
---**Contexts:** Gameplay
---
---*Action*
---@param Plot Plot 
---@param City City 
function WorldBuilderCityManager:SetPlotOwner(Plot, City) end
---**Contexts:** Gameplay
---
---*Query*
---@return City City 
function WorldBuilderCityManager:GetCity() end

z_dontRef_types.WorldBuilderCityManager = WorldBuilderCityManager