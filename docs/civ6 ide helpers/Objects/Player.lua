---@meta


---**Contexts:** Gameplay, UI
---@class Player
local Player = {}
---@type table<userdata, table>
Player.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
Player.TypeName = "Player"
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Player:CanUnreadyTurn() end
---**Contexts:** Gameplay
---
---*Action*
function Player:ChangeScoringScenario1() end
---**Contexts:** Gameplay
---
---*Action*
function Player:ChangeScoringScenario2() end
---**Contexts:** Gameplay
---
---*Action*
function Player:ChangeScoringScenario3() end
---**Contexts:** UI
---
---*Query*
function Player:GetAgendaTypes() end
---**Contexts:** Gameplay
---
---*Action*
---@return AiDiplomacy AiDiplomacy 
function Player:GetAi_Diplomacy() end
---**Contexts:** Gameplay
---
---*Query*
---@return AiMilitary AiMilitary 
function Player:GetAi_Military() end
---**Contexts:** Gameplay
---
---*Query*
---@return AiReligious AiReligious 
function Player:GetAi_Religion() end
---**Contexts:** UI
---
---*Query*
function Player:GetCategoryScore() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return PlayerCities PlayerCities 
function Player:GetCities() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return PlayerCulture PlayerCulture 
function Player:GetCulture() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return PlayerDiplomacy PlayerDiplomacy 
function Player:GetDiplomacy() end
---**Contexts:** UI
---
---*Query*
---@return AiDiplomacy AiDiplomacy 
function Player:GetDiplomaticAI() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return PlayerDistricts PlayerDistricts 
function Player:GetDistricts() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Player:GetEra() end
---**Contexts:** Gameplay
---
---*Query*
---@return PlayerEras PlayerEras 
function Player:GetEras() end
---**Contexts:** UI
---
---*Query*
---@return number amount 
function Player:GetFavor() end
---**Contexts:** UI
---
---*Query*
---@return number amount 
function Player:GetFavorPerTurn() end
---**Contexts:** UI
---
---*Query*
---@return number amount 
function Player:GetFavorEnteringCongress() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return PlayerGovernors PlayerGovernors 
function Player:GetGovernors() end
---**Contexts:** UI
---
---*Query*
---@return AiGrandStrategic AiGrandStrategic 
function Player:GetGrandStrategicAI() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return PlayerGreatPeoplePoints PlayerGreatPeoplePoints 
function Player:GetGreatPeoplePoints() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number playerID 
function Player:GetID() end
---**Contexts:** UI
---
---*Query*
---@return PlayerImprovements PlayerImprovements 
function Player:GetImprovements() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return PlayerInfluence PlayerInfluence 
function Player:GetInfluence() end
---**Contexts:** UI
---
---*Query*
---@return InfluenceMap InfluenceMap 
function Player:GetInfluenceMap() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param propertyKey string 
---@return any value 
function Player:GetProperty(propertyKey) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return PlayerReligion PlayerReligion 
function Player:GetReligion() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return PlayerResources PlayerResources 
function Player:GetResources() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number amount 
function Player:GetScore() end
---**Contexts:** Gameplay
---
---*Query*
function Player:GetScoringScenario1() end
---**Contexts:** Gameplay
---
---*Query*
function Player:GetScoringScenario2() end
---**Contexts:** Gameplay
---
---*Query*
function Player:GetScoringScenario3() end
---**Contexts:** Gameplay
---
---*Query*
function Player:GetStartingPlot() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return PlayerStats PlayerStats 
function Player:GetStats() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number teamID 
function Player:GetTeam() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return PlayerTechs PlayerTechs 
function Player:GetTechs() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return PlayerTrade PlayerTrade 
function Player:GetTrade() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return PlayerTreasury PlayerTreasury 
function Player:GetTreasury() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return PlayerUnits PlayerUnits 
function Player:GetUnits() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return PlayerWMDs PlayerWMDs 
function Player:GetWMDs() end
---**Contexts:** Gameplay
---
---*Action*
---@param yieldIndex number 
---@param amount number 
function Player:GrantYield(yieldIndex, amount) end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Player:IsAI() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Player:IsAlive() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Player:IsBarbarian() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Player:IsFreeCities() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Player:IsHuman() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function Player:IsInitialized() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Player:IsMajor() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Player:IsTurnActive() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Player:IsTurnActiveComplete() end
---**Contexts:** Gameplay
---
---*Action*
---@param property string 
---@param value any 
function Player:SetProperty(property, value) end
---
---*Action*
function Player:SetScoringScenario() end
---**Contexts:** Gameplay
---
---*Action*
---@param followers number 
function Player:SetScoringScenario1(followers) end
---**Contexts:** Gameplay
---
---*Query*
---@param cities number 
function Player:SetScoringScenario2(cities) end
---**Contexts:** Gameplay
---
---*Query*
---@param faith number 
function Player:SetScoringScenario3(faith) end
---**Contexts:** Gameplay
---
---*Action*
---@param Plot Plot 
function Player:SetStartingPlot(Plot) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Player:WasEverAlive() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return table componentID 
function Player:GetComponentID() end
---**Contexts:** Gameplay
---
---*Action*
---@param modifier string 
function Player:AttachModifierByID(modifier) end
---**Contexts:** Gameplay
---
---*Action*
function Player:GrantWMDs() end
---**Contexts:** UI
---
---*Query*
---@return string details 
function Player:GetFavorPerTurnToolTip() end
---**Contexts:** UI
---
---*Query*
---@return table agendaTypes 
function Player:GetAgendasAndVisibilities() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Player:IsMinor() end
---**Contexts:** UI
---
---*Query*
---@return table properties 
function Player:GetProperties() end
---**Contexts:** UI
---
---*Query*
---@return number loyalty 
function Player:GetCivilianLoyalty() end

z_dontRef_types.Player = Player