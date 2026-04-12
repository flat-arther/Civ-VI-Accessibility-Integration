---@meta


---**Contexts:** Gameplay
---@class AiReligious
local AiReligious = {}
---@type table<userdata, table>
AiReligious.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
AiReligious.TypeName = "AiReligious"
---**Contexts:** Gameplay
---
---*Action*
function AiReligious:SetFavoredReligion() end

z_dontRef_types.AiReligious = AiReligious