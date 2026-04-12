---@meta


---**Contexts:** UI
---@class CityAI
local CityAI = {}
---@type table<userdata, table>
CityAI.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
CityAI.TypeName = "CityAI"
---**Contexts:** UI
---
---*Query*
---@return table recommendations 
function CityAI:GetBuildRecommendations() end
---**Contexts:** UI
---
---*Query*
---@param Unit Unit 
---@return table recommendations 
function CityAI:GetImprovementRecommendationsForBuilder(Unit) end
---**Contexts:** UI
---
---*Query*
function CityAI:GetImprovementRecommendations() end

z_dontRef_types.CityAI = CityAI