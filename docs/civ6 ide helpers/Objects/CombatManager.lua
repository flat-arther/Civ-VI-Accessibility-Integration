---@meta


---**Contexts:** Gameplay, UI
CombatManager = {}
---**Contexts:** Gameplay, UI
---
---*Query*
---@param atk_unitComponentID number 
---@param dfd_unitComponentID number 
---@param combatType CombatTypes 
---@return boolean  
function CombatManager.CanAttackTarget(atk_unitComponentID, dfd_unitComponentID, combatType) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param unitComponentID number 
---@param x number 
---@param y number 
---@return boolean  
function CombatManager.IsAttackChangeWarState(unitComponentID, x, y) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param atk_ComponentID number 
---@param combatType CombatTypes 
---@param x number 
---@param y number 
---@return table combatResults 
function CombatManager.SimulateAttackInto(atk_ComponentID, combatType, x, y) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param atk_componentID number 
---@param dfd_componentID number 
---@param combatType CombatTypes 
---@return table combatResults 
function CombatManager.SimulateAttackVersus(atk_componentID, dfd_componentID, combatType) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param atk_ComponentID number 
---@param combatType CombatTypes 
---@param x number 
---@param y number 
---@return table combatResults 
function CombatManager.SimulatePriorityAttackInto(atk_ComponentID, combatType, x, y) end
---**Contexts:** Gameplay, UI
---
---*Query*
function CombatManager.GetBestDefender() end
---**Contexts:** Gameplay, UI
---
---*Query*
function CombatManager.GetBestInterceptor() end
---**Contexts:** Gameplay, UI
---
---*Query*
function CombatManager.GenerateCombatResults() end