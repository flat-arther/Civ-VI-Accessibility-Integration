---@meta


---**Contexts:** Gameplay
---@class WorldBuilderModManager
local WorldBuilderModManager = {}
---@type table<userdata, table>
WorldBuilderModManager.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
WorldBuilderModManager.TypeName = "WorldBuilderModManager"
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderModManager:RemoveString() end
---**Contexts:** Gameplay
---
---*Query*
function WorldBuilderModManager:GetString() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderModManager:SetString() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilderModManager:SetKeyStringPairByIndex() end
---**Contexts:** Gameplay
---
---*Query*
function WorldBuilderModManager:GetLanguageByIndex() end
---**Contexts:** Gameplay
---
---*Query*
function WorldBuilderModManager:GetKeyStringPairByIndex() end

z_dontRef_types.WorldBuilderModManager = WorldBuilderModManager