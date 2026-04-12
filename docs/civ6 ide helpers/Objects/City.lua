---@meta


---**Contexts:** Gameplay, UI
---@class City
local City = {}
---@type table<userdata, table>
City.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
City.TypeName = "City"
---**Contexts:** UI
---
---*Query*
---@return boolean  
function City:CanRaze() end
---**Contexts:** Gameplay
---
---*Action*
---@param amount number 
function City:ChangeLoyalty(amount) end
---**Contexts:** Gameplay
---
---*Action*
---@param amount number 
function City:ChangePopulation(amount) end
---**Contexts:** UI
---
---*Query*
---@return string amenityAdvice 
function City:GetAmenityAdvice() end
---**Contexts:** UI
---
---*Query*
---@return CacheGovernor CacheGovernor 
function City:GetAssignedGovernor() end
---**Contexts:** UI
---
---*Query*
---@param buildingHash number 
---@param yieldType string 
---@param whenHasPower boolean 
---@return number amount 
function City:GetBuildingPotentialYield(buildingHash, yieldType, whenHasPower) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return CityBuildings CityBuildings 
function City:GetBuildings() end
---**Contexts:** UI
---
---*Query*
---@param buildingIndex number 
---@param yieldID number 
---@return number yield 
function City:GetBuildingYield(buildingIndex, yieldID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return BuildQueue BuildQueue 
function City:GetBuildQueue() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return Citizens Citizens 
function City:GetCitizens() end
---**Contexts:** UI
---
---*Query*
---@return CityAI CityAI 
function City:GetCityAI() end
---**Contexts:** UI
---
---*Query*
---@return table componentIDs 
function City:GetComponentID() end
---**Contexts:** UI
---
---*Query*
---@return CulturalIdentity CulturalIdentity 
function City:GetCulturalIdentity() end
---**Contexts:** UI
---
---*Query*
---@return Culture Culture 
function City:GetCulture() end
---**Contexts:** UI
---
---*Query*
---@return number districtID 
function City:GetDistrictID() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return Districts Districts 
function City:GetDistricts() end
---**Contexts:** UI
---
---*Query*
---@return CityGold CityGold 
function City:GetGold() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return CityGrowth CityGrowth 
function City:GetGrowth() end
---**Contexts:** UI
---
---*Query*
---@return string advice 
function City:GetHousingAdvice() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number cityID 
function City:GetID() end
---**Contexts:** UI
---
---*Query*
---@return Player Player 
function City:GetJustConqueredFrom() end
---**Contexts:** UI
---
---*Query*
---@return CityTransferTypes transerType 
function City:GetLastTransferType() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return string name 
function City:GetName() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return Player Player 
function City:GetOriginalOwner() end
---**Contexts:** Gameplay
---
---*Query*
---@return Plot[] plots 
function City:GetOwnedPlots() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return Player Player 
function City:GetOwner() end
---**Contexts:** UI
---
---*Query*
---@return Player Player 
function City:GetOwnerBeforeOccupation() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number amount 
function City:GetPopulation() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return CityReligion CityReligion 
function City:GetReligion() end
---**Contexts:** UI
---
---*Query*
---@return Trade Trade 
function City:GetTrade() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number x 
function City:GetX() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number y 
function City:GetY() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param yieldType YieldTypes 
---@return number amount 
function City:GetYield(yieldType) end
---**Contexts:** UI
---
---*Query*
---@param yieldType YieldTypes 
---@return string tooltip 
function City:GetYieldToolTip(yieldType) end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function City:IsCapital() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function City:IsOccupied() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function City:IsOriginalCapital() end
---**Contexts:** Gameplay
---
---*Action*
---@param buildingIndex number 
---@param isEnabled boolean 
function City:SetBuildingFaithPurchaseEnabled(buildingIndex, isEnabled) end
---**Contexts:** Gameplay
---
---*Action*
---@param unitID number 
---@param isEnabled boolean 
function City:SetUnitFaithPurchaseEnabled(unitID, isEnabled) end
---**Contexts:** Gameplay
---
---*Action*
function City:AttachModifierByID() end
---**Contexts:** UI
---
---*Query*
---@return CityPower CityPower 
function City:GetPower() end
---**Contexts:** Gameplay
---
---*Query*
function City:GetBuildingFaithPurchaseEnabled() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param key string 
---@return any value 
function City:GetProperty(key) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return table properties 
function City:GetProperties() end
---**Contexts:** UI
---
---*Query*
function City:GetPowerAdvice() end
---**Contexts:** Gameplay
---
---*Action*
---@param key string 
---@param value any 
function City:SetProperty(key, value) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number x 
---@return number y 
function City:GetLocation() end
---**Contexts:** Gameplay
---
---*Query*
---@return Plot Plot 
function City:GetPlot() end
---**Contexts:** Gameplay
---
---*Action*
---@param name string 
function City:SetName(name) end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function City:GetUnitFaithPurchaseEnabled() end
---**Contexts:** UI
---
---*Query*
---@return table governors 
function City:GetAllAssignedGovernors() end
---**Contexts:** UI
---
---*Query*
---@return string loyaltyAdvice 
function City:GetLoyaltyAdvice() end

z_dontRef_types.City = City