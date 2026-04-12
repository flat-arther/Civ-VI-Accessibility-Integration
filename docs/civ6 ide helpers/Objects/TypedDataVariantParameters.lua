---@meta


---**Contexts:** UI
---@class TypedDataVariantParameters
local TypedDataVariantParameters = {}
---@type table<userdata, table>
TypedDataVariantParameters.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
TypedDataVariantParameters.TypeName = "TypedDataVariantParameters"
---**Contexts:** UI
---
---*Action*
function TypedDataVariantParameters:Remove() end
---**Contexts:** UI
---
---*Action*
function TypedDataVariantParameters:SetValue() end
---**Contexts:** UI
---
---*Query*
function TypedDataVariantParameters:GetValue() end
---**Contexts:** UI
---
---*Action*
---@param name string 
---@return TypedDataVariant TypedDataVariant 
function TypedDataVariantParameters:Add(name) end
---**Contexts:** UI
---
---*Query*
---@param name string 
---@return TypedDataVariant TypedDataVariant 
function TypedDataVariantParameters:Get(name) end

z_dontRef_types.TypedDataVariantParameters = TypedDataVariantParameters