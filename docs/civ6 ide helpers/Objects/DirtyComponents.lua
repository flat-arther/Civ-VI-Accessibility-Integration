---@meta


---**Contexts:** UI
---@class DirtyComponents
local DirtyComponents = {}
---@type table<userdata, table>
DirtyComponents.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
DirtyComponents.TypeName = "DirtyComponents"
---**Contexts:** UI
---
---*Action*
function DirtyComponents:Clear() end
---**Contexts:** UI
---
---*Action*
---@param componentEvent string 
function DirtyComponents:AddEvent(componentEvent) end
---**Contexts:** UI
---
---*Action*
---@param playerID number 
---@param componentID number 
---@param componentType ComponentType 
function DirtyComponents:AddComponent(playerID, componentID, componentType) end
---**Contexts:** UI
---
---*Query*
function DirtyComponents:Members() end
---**Contexts:** UI
---
---*Query*
function DirtyComponents:GetCount() end
---**Contexts:** UI
---
---*Query*
function DirtyComponents:MembersAux() end

z_dontRef_types.DirtyComponents = DirtyComponents