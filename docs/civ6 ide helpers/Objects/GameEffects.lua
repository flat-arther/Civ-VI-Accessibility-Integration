---@meta


---**Contexts:** Gameplay, UI
GameEffects = {}
---**Contexts:** Gameplay, UI
---
---*Query*
---@param modifierID number 
---@return boolean  
function GameEffects.GetModifierActive(modifierID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param modifierID number 
---@return string argStr 
function GameEffects.GetModifierArgumentString(modifierID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number amount 
function GameEffects.GetModifierCount() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param modifierID number 
---@return table modifierDef 
function GameEffects.GetModifierDefinition(modifierID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param modifierID number 
---@return number playerID 
function GameEffects.GetModifierOwner(modifierID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param modifierID number 
---@return table ownerRequirements 
function GameEffects.GetModifierOwnerRequirementSet(modifierID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param modifierID number 
---@return number amount 
function GameEffects.GetModifierReferenceCount(modifierID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return integer[] modifiers 
function GameEffects.GetModifiers() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param modifierID number 
---@return number amount 
function GameEffects.GetModifierSubjectCount(modifierID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param modifierID number 
---@return table subjects 
function GameEffects.GetModifierSubjects(modifierID) end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameEffects.GetModifierText() end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameEffects.GetModifierTextKey() end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameEffects.GetModifierTrackedObjectCount() end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameEffects.GetModifierTrackedObjects() end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameEffects.GetModifierTrackedOjectRequirementSet() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param playerID number 
---@return string objName 
function GameEffects.GetObjectName(playerID) end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameEffects.GetObjectReferenceCount() end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameEffects.GetObjectsPlayerId() end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameEffects.GetObjectString() end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameEffects.GetObjectType() end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameEffects.GetRequirementContext() end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameEffects.GetRequirementCount() end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameEffects.GetRequirementDefinition() end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameEffects.GetRequirementInnerRequirements() end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameEffects.GetRequirementInnerRequirementSets() end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameEffects.GetRequirementReferenceCount() end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameEffects.GetRequirements() end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameEffects.GetRequirementSetContext() end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameEffects.GetRequirementSetCount() end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameEffects.GetRequirementSetDefinition() end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameEffects.GetRequirementSetInnerRequirements() end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameEffects.GetRequirementSetReferenceCount() end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameEffects.GetRequirementSets() end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameEffects.GetRequirementSetState() end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameEffects.GetRequirementSetSubject() end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameEffects.GetRequirementState() end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameEffects.GetRequirementSubject() end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameEffects.GetRequirementText() end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameEffects.GetRequirementTextKey() end