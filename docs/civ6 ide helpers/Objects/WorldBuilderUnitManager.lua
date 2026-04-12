---@meta


---**Contexts:** Gameplay
---@class WorldBuilderUnitManager
local WorldBuilderUnitManager = {}
---@type table<userdata, table>
WorldBuilderUnitManager.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
WorldBuilderUnitManager.TypeName = "WorldBuilderUnitManager"
---**Contexts:** Gameplay
---
---*Action*
---@param unitIndex number 
---@param playerID number 
---@param Plot Plot 
function WorldBuilderUnitManager:Create(unitIndex, playerID, Plot) end
---**Contexts:** Gameplay
---
---*Action*
---@param Unit Unit 
function WorldBuilderUnitManager:Remove(Unit) end
---**Contexts:** Gameplay
---
---*Action*
---@param playerID number 
function WorldBuilderUnitManager:RemoveAll(playerID) end
---**Contexts:** Gameplay
---
---*Action*
---@param Plot Plot 
function WorldBuilderUnitManager:RemoveAt(Plot) end

z_dontRef_types.WorldBuilderUnitManager = WorldBuilderUnitManager