---@meta


---**Contexts:** UI
---@class AiGrandStrategic
local AiGrandStrategic = {}
---@type table<userdata, table>
AiGrandStrategic.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
AiGrandStrategic.TypeName = "AiGrandStrategic"
---**Contexts:** UI
---
---*Query*
function AiGrandStrategic:GetCivicsRecommendations() end
---**Contexts:** UI
---
---*Query*
function AiGrandStrategic:GetTechRecommendations() end
---**Contexts:** UI
---
---*Query*
function AiGrandStrategic:GetSettlementRecommendations() end

z_dontRef_types.AiGrandStrategic = AiGrandStrategic