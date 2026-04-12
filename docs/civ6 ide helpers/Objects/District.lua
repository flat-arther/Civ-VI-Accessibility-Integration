---@meta


---**Contexts:** UI
---@class District
local District = {}
---@type table<userdata, table>
District.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
District.TypeName = "District"
---**Contexts:** UI
---
---*Query*
---@return number slots 
function District:GetAirSlots() end
---**Contexts:** UI
---
---*Query*
---@return table airUnits 
function District:GetAirUnits() end
---**Contexts:** UI
---
---*Query*
---@return number strength 
function District:GetAttackStrength() end
---**Contexts:** UI
---
---*Query*
---@return number strength 
function District:GetBaseDefenseStrength() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return City City 
function District:GetCity() end
---**Contexts:** UI
---
---*Query*
function District:GetComponentID() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param defenseType DefenseTypes 
---@return number damage 
function District:GetDamage(defenseType) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number strength 
function District:GetDefenseStrength() end
---**Contexts:** UI
---
---*Query*
---@return number entertainment 
function District:GetExtraRegionalEntertainment() end
---**Contexts:** UI
---
---*Query*
---@return number range 
function District:GetExtraRegionalRange() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number districtID 
function District:GetID() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param defenseType DefenseTypes 
---@return number damage 
function District:GetMaxDamage(defenseType) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return Player Player 
function District:GetOwner() end
---**Contexts:** UI
---
---*Query*
---@return number rate 
function District:GetReligionHealRate() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return string type 
function District:GetType() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number x 
function District:GetX() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number y 
function District:GetY() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param yieldType YieldTypes 
---@return number yield 
function District:GetYield(yieldType) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function District:IsComplete() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function District:IsUnderSiege() end
---**Contexts:** Gameplay, UI
---
---*Query*
function District:GetLocation() end
---**Contexts:** UI
---
---*Query*
function District:GetAdjacencyYield() end
---**Contexts:** UI
---
---*Query*
function District:CanAttack() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function District:IsPillaged() end
---**Contexts:** UI
---
---*Query*
function District:GetAirUnitCount() end
---**Contexts:** Gameplay
---
---*Action*
---@param defenseType DefenseTypes 
---@param damage number 
function District:SetDamage(defenseType, damage) end
---**Contexts:** Gameplay
---
---*Action*
function District:ChangeDamage() end
---**Contexts:** Gameplay
---
---*Action*
function District:SetProperty() end
---**Contexts:** Gameplay
---
---*Query*
function District:GetProperty() end
---**Contexts:** Gameplay
---
---*Action*
---@param isPillaged boolean 
function District:SetPillaged(isPillaged) end

z_dontRef_types.District = District