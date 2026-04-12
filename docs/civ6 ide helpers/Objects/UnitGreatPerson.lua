---@meta


---**Contexts:** Gameplay, UI
---@class UnitGreatPerson
local UnitGreatPerson = {}
---@type table<userdata, table>
UnitGreatPerson.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
UnitGreatPerson.TypeName = "UnitGreatPerson"
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number charges 
function UnitGreatPerson:GetActionCharges() end
---**Contexts:** UI
---
---*Query*
---@return Plot[] plots 
function UnitGreatPerson:GetActivationHighlightPlots() end
---**Contexts:** UI
---
---*Query*
---@return Plot[] plots 
function UnitGreatPerson:GetAreaHighlightPlots() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return string greatPersonClass 
function UnitGreatPerson:GetClass() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number greatPersonID 
function UnitGreatPerson:GetIndividual() end
---**Contexts:** UI
---
---*Query*
---@return string greatPersonPassiveText 
function UnitGreatPerson:GetPassiveEffectText() end
---**Contexts:** UI
---
---*Query*
---@return string greatPersonPassiveName 
function UnitGreatPerson:GetPassiveNameText() end
---**Contexts:** UI
---
---*Query*
---@return Unit Unit 
function UnitGreatPerson:GetUnit() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UnitGreatPerson:HasPassiveEffect() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UnitGreatPerson:IsGreatPerson() end
---**Contexts:** Gameplay
---
---*Query*
function UnitGreatPerson:GetIndividualHash() end

z_dontRef_types.UnitGreatPerson = UnitGreatPerson