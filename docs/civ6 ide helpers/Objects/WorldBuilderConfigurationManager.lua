---@meta


---**Contexts:** Gameplay
---@class WorldBuilderConfigurationManager
local WorldBuilderConfigurationManager = {}
---@type table<userdata, table>
WorldBuilderConfigurationManager.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
WorldBuilderConfigurationManager.TypeName = "WorldBuilderConfigurationManager"
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderConfigurationManager:SetMapValue() end
---**Contexts:** Gameplay
---
---*Query*
function WorldBuilderConfigurationManager:GetMapValue() end
---**Contexts:** Gameplay
---
---*Query*
function WorldBuilderConfigurationManager:GetMapValues() end

z_dontRef_types.WorldBuilderConfigurationManager = WorldBuilderConfigurationManager