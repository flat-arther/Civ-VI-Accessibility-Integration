---@meta


---**Contexts:** UI
---@class TypedDataVariant
local TypedDataVariant = {}
---@type table<userdata, table>
TypedDataVariant.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
TypedDataVariant.TypeName = "TypedDataVariant"
---**Contexts:** UI
---
---*Action*
function TypedDataVariant:SetValue() end
---**Contexts:** UI
---
---*Query*
function TypedDataVariant:GetValueAt() end
---**Contexts:** UI
---
---*Query*
function TypedDataVariant:GetCount() end
---**Contexts:** UI
---
---*Query*
function TypedDataVariant:Get() end
---**Contexts:** UI
---
---*Action*
function TypedDataVariant:RemoveAt() end
---**Contexts:** UI
---
---*Action*
function TypedDataVariant:AppendValue() end
---**Contexts:** UI
---
---*Query*
function TypedDataVariant:GetKeyAt() end
---**Contexts:** UI
---
---*Action*
function TypedDataVariant:SetValueAt() end
---**Contexts:** UI
---
---*Query*
function TypedDataVariant:GetAt() end
---**Contexts:** UI
---
---*Query*
function TypedDataVariant:GetValue() end
---**Contexts:** UI
---
---*Query*
function TypedDataVariant:GetValueIndex() end
---**Contexts:** UI
---
---*Query*
function TypedDataVariant:ContainsValue() end
---**Contexts:** UI
---
---*Action*
function TypedDataVariant:InsertValueAt() end
---**Contexts:** UI
---
---*Action*
function TypedDataVariant:Remove() end
---**Contexts:** UI
---
---*Action*
function TypedDataVariant:Add() end

z_dontRef_types.TypedDataVariant = TypedDataVariant