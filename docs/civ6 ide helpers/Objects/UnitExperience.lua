---@meta


---**Contexts:** Gameplay, UI
---@class UnitExperience
local UnitExperience = {}
---@type table<userdata, table>
UnitExperience.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
UnitExperience.TypeName = "UnitExperience"
---**Contexts:** Gameplay
---
---*Action*
---@param amount number 
function UnitExperience:ChangeExperience(amount) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number nextLevelXP 
function UnitExperience:GetExperienceForNextLevel() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number currentXP 
function UnitExperience:GetExperiencePoints() end
---**Contexts:** UI
---
---*Query*
---@return number level 
function UnitExperience:GetLevel() end
---**Contexts:** UI
---
---*Query*
---@return table promotionList 
function UnitExperience:GetPromotions() end
---**Contexts:** UI
---
---*Query*
---@return Unit Unit 
function UnitExperience:GetUnit() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return string name 
function UnitExperience:GetVeteranName() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param promotionID number 
---@return boolean  
function UnitExperience:HasPromotion(promotionID) end
---**Contexts:** Gameplay
---
---*Action*
---@param promotionID number 
---@param active boolean 
function UnitExperience:SetPromotion(promotionID, active) end
---**Contexts:** Gameplay
---
---*Action*
function UnitExperience:ChangeStoredPromotions() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function UnitExperience:CanPromote() end
---**Contexts:** Gameplay
---
---*Action*
function UnitExperience:SetVeteranName() end
---**Contexts:** Gameplay
---
---*Action*
function UnitExperience:SetExperienceLocked() end

z_dontRef_types.UnitExperience = UnitExperience