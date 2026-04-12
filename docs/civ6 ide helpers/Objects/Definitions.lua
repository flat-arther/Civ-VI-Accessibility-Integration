---@meta


---**Contexts:** UI
Definitions = {}
---**Contexts:** UI
---
---*Query*
---@param definitionType DefinitionTypes 
---@param typeName string 
---@return number hash 
function Definitions.GetTypeHash(definitionType, typeName) end
---**Contexts:** UI
---
---*Query*
---@param definitionType DefinitionTypes 
---@param hash number 
---@return string typeName 
function Definitions.GetTypeName(definitionType, hash) end