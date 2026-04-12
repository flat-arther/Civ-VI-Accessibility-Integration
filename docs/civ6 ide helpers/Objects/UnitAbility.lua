---@meta


---**Contexts:** Gameplay, UI
---@class UnitAbility
local UnitAbility = {}
---@type table<userdata, table>
UnitAbility.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
UnitAbility.TypeName = "UnitAbility"
---**Contexts:** Gameplay
---
---*Query*
---@param unitAbilityType string 
---@return boolean  
function UnitAbility:HasAbility(unitAbilityType) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return integer[] unitAbilityIndexes 
function UnitAbility:GetAbilities() end
---**Contexts:** Gameplay
---
---*Query*
function UnitAbility:RemoveAbilityCount() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function UnitAbility:CanHaveAbility() end
---**Contexts:** Gameplay
---
---*Action*
function UnitAbility:ChangeAbilityCount() end
---**Contexts:** Gameplay
---
---*Query*
function UnitAbility:GetAbilityCount() end
---**Contexts:** Gameplay
---
---*Action*
function UnitAbility:AddAbilityCount() end

z_dontRef_types.UnitAbility = UnitAbility