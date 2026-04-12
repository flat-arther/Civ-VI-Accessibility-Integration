---@meta


---**Contexts:** Gameplay
---@class UnitReligion
local UnitReligion = {}
---@type table<userdata, table>
UnitReligion.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
UnitReligion.TypeName = "UnitReligion"
---**Contexts:** Gameplay
---
---*Action*
---@param amount number 
function UnitReligion:ChangeEvictPercent(amount) end
---**Contexts:** Gameplay
---
---*Action*
---@param amount number 
function UnitReligion:ChangeForeignSpreadModifier(amount) end
---**Contexts:** Gameplay
---
---*Action*
---@param amount number 
function UnitReligion:ChangeNWDeferredCharges(amount) end
---**Contexts:** Gameplay
---
---*Action*
---@param amount number 
function UnitReligion:ChangeReligiousHealCharges(amount) end
---**Contexts:** Gameplay
---
---*Action*
---@param amount number 
function UnitReligion:ChangeReligiousStrength(amount) end
---**Contexts:** Gameplay
---
---*Action*
---@param amount number 
function UnitReligion:ChangeSpreadCharges(amount) end
---**Contexts:** Gameplay
---
---*Query*
---@return number percent 
function UnitReligion:GetEvictPercent() end
---**Contexts:** Gameplay
---
---*Query*
---@return number amount 
function UnitReligion:GetForeignSpreadModifier() end
---**Contexts:** Gameplay
---
---*Query*
---@return number amount 
function UnitReligion:GetInitiationAmount() end
---**Contexts:** Gameplay
---
---*Query*
---@return number yield 
function UnitReligion:GetInitiationYield() end
---**Contexts:** Gameplay
---
---*Query*
---@return number amount 
function UnitReligion:GetNWDeferredCharges() end
---**Contexts:** Gameplay
---
---*Query*
---@return number religionID 
function UnitReligion:GetReligionType() end
---**Contexts:** Gameplay
---
---*Query*
---@return number amount 
function UnitReligion:GetReligiousHealCharges() end
---**Contexts:** Gameplay
---
---*Query*
---@return number strength 
function UnitReligion:GetReligiousStrength() end
---**Contexts:** Gameplay
---
---*Query*
---@return number amount 
function UnitReligion:GetSpreadCharges() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function UnitReligion:IsConvertsBarbarians() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function UnitReligion:IsNoForeignSpread() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function UnitReligion:IsRelicUponDeath() end
---**Contexts:** Gameplay
---
---*Action*
---@param isAble boolean 
function UnitReligion:SetConvertsBarbarians(isAble) end
---**Contexts:** Gameplay
---
---*Action*
---@param percent number 
function UnitReligion:SetEvictPercent(percent) end
---**Contexts:** Gameplay
---
---*Action*
---@param amount number 
function UnitReligion:SetForeignSpreadModifier(amount) end
---**Contexts:** Gameplay
---
---*Action*
---@param amount number 
function UnitReligion:SetInitiationAmount(amount) end
---**Contexts:** Gameplay
---
---*Action*
---@param yield number 
function UnitReligion:SetInitiationYield(yield) end
---**Contexts:** Gameplay
---
---*Action*
---@param isUnable boolean 
function UnitReligion:SetNoForeignSpread(isUnable) end
---**Contexts:** Gameplay
---
---*Action*
---@param isAble boolean 
function UnitReligion:SetRelicUponDeath(isAble) end
---**Contexts:** Gameplay
---
---*Action*
---@param religionID number 
function UnitReligion:SetReligionType(religionID) end

z_dontRef_types.UnitReligion = UnitReligion