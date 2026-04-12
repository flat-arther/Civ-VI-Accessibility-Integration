---@meta


---**Contexts:** Gameplay
---@class AiMilitary
local AiMilitary = {}
---@type table<userdata, table>
AiMilitary.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
AiMilitary.TypeName = "AiMilitary"
---**Contexts:** Gameplay
---
---*Action*
function AiMilitary:AddUnitToScriptedOperation() end
---**Contexts:** Gameplay
---
---*Action*
function AiMilitary:AllowUnitConstruction() end
---**Contexts:** Gameplay
---
---*Query*
function AiMilitary:CanConstructUnits() end
---**Contexts:** Gameplay
---
---*Query*
function AiMilitary:HasOperationAgainst() end
---**Contexts:** Gameplay
---
---*Action*
function AiMilitary:PrepareForWarWith() end
---**Contexts:** Gameplay
---
---*Action*
function AiMilitary:ScriptForceUpdateTargets() end
---**Contexts:** Gameplay
---
---*Action*
function AiMilitary:SetRival() end
---**Contexts:** Gameplay
---
---*Action*
function AiMilitary:SetScriptedOperationReady() end
---**Contexts:** Gameplay
---
---*Action*
function AiMilitary:SetScriptedTargetAndRally() end
---**Contexts:** Gameplay
---
---*Action*
function AiMilitary:StartScriptedOperation() end
---**Contexts:** Gameplay
---
---*Action*
function AiMilitary:StartScriptedOperationWithTargetAndRally() end

z_dontRef_types.AiMilitary = AiMilitary