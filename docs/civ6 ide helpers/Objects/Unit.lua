---@meta


---**Contexts:** Gameplay, UI
---@class Unit
local Unit = {}
---@type table<userdata, table>
Unit.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
Unit.TypeName = "Unit"
---**Contexts:** Gameplay
---
---*Action*
---@param amount number 
function Unit:ChangeDamage(amount) end
---**Contexts:** Gameplay
---
---*Action*
---@param amount number 
function Unit:ChangeExtraMoves(amount) end
---**Contexts:** UI
---
---*Query*
---@return number amount 
function Unit:GetAirSlots() end
---**Contexts:** UI
---
---*Query*
---@return boolean hasAirUnits 
---@return number amount 
function Unit:GetAirUnits() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number amount 
function Unit:GetAntiAirCombat() end
---**Contexts:** UI
---
---*Query*
---@return number cityID 
function Unit:GetArchaeologyHomeCity() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number amount 
function Unit:GetAttacksRemaining() end
---**Contexts:** UI
---
---*Query*
---@return number tribeID 
function Unit:GetBarbarianTribeIndex() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number amount 
function Unit:GetBombardCombat() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number amount 
function Unit:GetBuildCharges() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number amount 
function Unit:GetCombat() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number amount 
function Unit:GetDamage() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return UnitExperience UnitExperience 
function Unit:GetExperience() end
---**Contexts:** Gameplay
---
---*Query*
---@return number moves 
function Unit:GetExtraMoves() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Unit:GetFormationClass() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Unit:GetFormationID() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number moves 
function Unit:GetFormationMaxMoves() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number moves 
function Unit:GetFormationMovesRemaining() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number amount 
function Unit:GetFormationUnitCount() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number turns 
function Unit:GetFortifyTurns() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return UnitGreatPerson UnitGreatPerson 
function Unit:GetGreatPerson() end
---**Contexts:** UI
---
---*Query*
---@return number greatWorkID 
function Unit:GetGreatWorkIndex() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number unitID 
function Unit:GetID() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number plotX 
---@return number plotY 
function Unit:GetLocation() end
---**Contexts:** UI
---
---*Query*
---@return string lootName 
function Unit:GetLootName() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number maxDamage 
function Unit:GetMaxDamage() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number maxMoves 
function Unit:GetMaxMoves() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return MilitaryFormationTypes formationType 
function Unit:GetMilitaryFormation() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number movementMoves 
function Unit:GetMovementMovesRemaining() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number moves 
function Unit:GetMovesRemaining() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return string unitName 
function Unit:GetName() end
---**Contexts:** Gameplay
---
---*Query*
function Unit:GetOperationParameter() end
---**Contexts:** Gameplay
---
---*Query*
---@return UnitOperationTypes operationType 
function Unit:GetOperationType() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number playerID 
function Unit:GetOriginalOwner() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number playerID 
function Unit:GetOwner() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param property string 
---@return any value 
function Unit:GetProperty(property) end
---**Contexts:** UI
---
---*Query*
---@return string pursuingSpyName 
function Unit:GetPursuingSpyName() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number range 
function Unit:GetRange() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number rangedCombatStrength 
function Unit:GetRangedCombat() end
---**Contexts:** Gameplay
---
---*Query*
---@return UnitReligion UnitReligion 
function Unit:GetReligion() end
---**Contexts:** UI
---
---*Query*
---@return number religionID 
function Unit:GetReligionType() end
---**Contexts:** UI
---
---*Query*
---@return number amount 
function Unit:GetReligiousStrength() end
---**Contexts:** UI
---
---*Query*
---@return number amount 
function Unit:GetSpreadCharges() end
---**Contexts:** UI
---
---*Query*
---@return UnitOperationTypes operationType 
function Unit:GetSpyOperation() end
---**Contexts:** UI
---
---*Query*
---@return number turnsRemaining 
function Unit:GetSpyOperationEndTurn() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number unitIndex 
function Unit:GetType() end
---**Contexts:** UI
---
---*Query*
---@return string unitType 
function Unit:GetUnitType() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number upgradeCost 
function Unit:GetUpgradeCost() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number x 
function Unit:GetX() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number y 
function Unit:GetY() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Unit:HasHiddenVisibility() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Unit:HasMovedIntoZOC() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Unit:HasPendingOperations() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Unit:IgnoresZOC() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Unit:IsAutomated() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Unit:IsCannotAttack() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Unit:IsDead() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Unit:IsDelayedDeath() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Unit:IsEmbarked() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Unit:IsHuman() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Unit:IsReadyToAutomate() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Unit:IsReadyToMove() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Unit:IsReadyToSelect() end
---**Contexts:** Gameplay
---
---*Action*
---@param amount number 
function Unit:SetDamage(amount) end
---**Contexts:** Gameplay
---
---*Action*
---@param amount number 
function Unit:SetFortifyTurns(amount) end
---**Contexts:** UI
---
---*Query*
---@return number plotID 
function Unit:GetPlotId() end
---**Contexts:** Gameplay
---
---*Action*
function Unit:ChangeMovesRemaining() end
---**Contexts:** Gameplay
---
---*Action*
function Unit:ChangeActionCharges() end
---**Contexts:** UI
---
---*Query*
function Unit:GetBarbarianTargetPlayer() end
---**Contexts:** Gameplay
---
---*Action*
function Unit:SetMilitaryFormation() end
---**Contexts:** UI
---
---*Query*
---@return CacheUnitRockBand CacheUnitRockBand 
function Unit:GetRockBand() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return UnitAbility UnitAbility 
function Unit:GetAbility() end
---**Contexts:** UI
---
---*Query*
---@return number resourceIndex 
---@return number cost 
function Unit:GetUpgradeResourceCost() end
---**Contexts:** Gameplay
---
---*Action*
---@param key string 
---@return any value 
function Unit:SetProperty(key) end
---**Contexts:** Gameplay, UI
---
---*Query*
function Unit:GetHeroClassType() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number amount 
function Unit:GetParkCharges() end
---**Contexts:** Gameplay
---
---*Query*
---@return DomainTypes domainType 
function Unit:GetDomain() end
---**Contexts:** Gameplay
---
---*Query*
function Unit:GetTypeHash() end
---**Contexts:** Gameplay
---
---*Action*
---@param amount number 
function Unit:SetActionCharges(amount) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return table<string, any> properties 
function Unit:GetProperties() end
---**Contexts:** Gameplay
---
---*Query*
---@return table IDs 
function Unit:GetParentID() end
---**Contexts:** Gameplay
---
---*Query*
---@return integer[] unitIDs 
function Unit:GetFormationUnitIDs() end
---**Contexts:** Gameplay
---
---*Query*
function Unit:GetFormationUnits() end
---**Contexts:** UI
---
---*Query*
---@return number amount 
function Unit:GetReligiousHealCharges() end
---**Contexts:** UI
---
---*Query*
---@return CacheUnitArchaeology CacheUnitArchaeology 
function Unit:GetArchaeology() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number amount 
function Unit:GetDisasterCharges() end
---**Contexts:** Gameplay
---
---*Query*
---@return table[] children 
function Unit:GetChildIDs() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function Unit:IsHero() end
---**Contexts:** UI
---
---*Query*
---@return CacheUnitTrade CacheUnitTrade 
function Unit:GetTrade() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number amount 
function Unit:GetActionCharges() end

z_dontRef_types.Unit = Unit