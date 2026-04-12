---@meta


---**Contexts:** Gameplay, UI
---@class PlayerConfiguration
local PlayerConfiguration = {}
---@type table<userdata, table>
PlayerConfiguration.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
PlayerConfiguration.TypeName = "PlayerConfiguration"
---**Contexts:** UI
---
---*Action*
---@param pinID number 
function PlayerConfiguration:DeleteMapPin(pinID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return string desc 
function PlayerConfiguration:GetCivilizationDescription() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return CivilizationLevelTypes levelType 
function PlayerConfiguration:GetCivilizationLevelTypeID() end
---**Contexts:** Gameplay
---
---*Query*
---@return string civilizationLevelTypeName 
function PlayerConfiguration:GetCivilizationLevelTypeName() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return string shortDesc 
function PlayerConfiguration:GetCivilizationShortDescription() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number civilizationIndex 
function PlayerConfiguration:GetCivilizationTypeID() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return string civilizationName 
function PlayerConfiguration:GetCivilizationTypeName() end
---**Contexts:** Gameplay
---
---*Query*
---@return number color 
function PlayerConfiguration:GetColor() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number difficultyHash 
function PlayerConfiguration:GetHandicapTypeID() end
---**Contexts:** UI
---
---*Query*
---@return string password 
function PlayerConfiguration:GetHotseatPassword() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return string name 
function PlayerConfiguration:GetLeaderName() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number leaderIndex 
function PlayerConfiguration:GetLeaderTypeID() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return string leaderTypeName 
function PlayerConfiguration:GetLeaderTypeName() end
---**Contexts:** UI
---
---*Action*
---@param x number 
---@param y number 
---@return MapPinConfiguration MapPinConfiguration 
function PlayerConfiguration:GetMapPin(x, y) end
---**Contexts:** UI
---
---*Query*
---@param pinID number 
---@return MapPinConfiguration MapPinConfiguration 
function PlayerConfiguration:GetMapPinID(pinID) end
---**Contexts:** UI
---
---*Query*
---@return MapPinConfiguration[] pins 
function PlayerConfiguration:GetMapPins() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function PlayerConfiguration:GetModReady() end
---**Contexts:** UI
---
---*Query*
---@return number steamID 
function PlayerConfiguration:GetNetworkIdentifer() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return string nickName 
function PlayerConfiguration:GetNickName() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return string civName 
function PlayerConfiguration:GetPlayerName() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function PlayerConfiguration:GetReady() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return string leaderName 
function PlayerConfiguration:GetSlotName() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return SlotStatus slotStatus 
function PlayerConfiguration:GetSlotStatus() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return {x: number, y: number} location 
function PlayerConfiguration:GetStartingPosition() end
---**Contexts:** UI
---
---*Query*
---@return number teamID 
function PlayerConfiguration:GetTeam() end
---**Contexts:** UI
---
---*Query*
---@return string teamName 
function PlayerConfiguration:GetTeamName() end
---**Contexts:** UI
---
---*Query*
---@param config string 
---@return any value 
function PlayerConfiguration:GetValue(config) end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function PlayerConfiguration:GetWantsPause() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function PlayerConfiguration:IsAI() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function PlayerConfiguration:IsAlive() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function PlayerConfiguration:IsAvailable() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function PlayerConfiguration:IsHidden() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function PlayerConfiguration:IsHuman() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function PlayerConfiguration:IsInUse() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function PlayerConfiguration:IsLocked() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function PlayerConfiguration:IsObserver() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function PlayerConfiguration:IsParticipant() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function PlayerConfiguration:IsPossibleParticipant() end
---**Contexts:** UI
---
---*Action*
---@param difficultyHash number 
function PlayerConfiguration:SetHandicapTypeID(difficultyHash) end
---**Contexts:** UI
---
---*Action*
---@param isHidden boolean 
function PlayerConfiguration:SetHidden(isHidden) end
---**Contexts:** UI
---
---*Action*
---@param hotseatPlayerName string 
function PlayerConfiguration:SetHotseatName(hotseatPlayerName) end
---**Contexts:** UI
---
---*Action*
---@param password string 
function PlayerConfiguration:SetHotseatPassword(password) end
---**Contexts:** UI
---
---*Action*
---@param name string 
function PlayerConfiguration:SetLeaderName(name) end
---**Contexts:** UI
---
---*Action*
---@param leaderTypeName string 
function PlayerConfiguration:SetLeaderTypeName(leaderTypeName) end
---**Contexts:** UI
---
---*Action*
---@param isLocked boolean 
function PlayerConfiguration:SetLocked(isLocked) end
---**Contexts:** UI
---
---*Action*
function PlayerConfiguration:SetMajorCiv() end
---**Contexts:** UI
---
---*Action*
---@param isReady boolean 
function PlayerConfiguration:SetReady(isReady) end
---**Contexts:** UI
---
---*Action*
---@param slotStatus SlotStatus 
function PlayerConfiguration:SetSlotStatus(slotStatus) end
---**Contexts:** UI
---
---*Action*
---@param teamID number 
function PlayerConfiguration:SetTeam(teamID) end
---**Contexts:** UI
---
---*Action*
---@param config string 
---@param value any 
function PlayerConfiguration:SetValue(config, value) end
---**Contexts:** UI
---
---*Action*
---@param wantsPause boolean 
function PlayerConfiguration:SetWantsPause(wantsPause) end
---**Contexts:** UI
---
---*Action*
---@param civilizationName string 
function PlayerConfiguration:SetCivilizationTypeName(civilizationName) end
---**Contexts:** UI
---
---*Action*
---@param randomPoolType LeaderRandomPoolTypes 
function PlayerConfiguration:SetLeaderRandomPoolID(randomPoolType) end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function PlayerConfiguration:IsHumanRequired() end
---**Contexts:** UI
---
---*Query*
---@return LeaderRandomPoolTypes randomPoolType 
function PlayerConfiguration:GetLeaderRandomPoolID() end

z_dontRef_types.PlayerConfiguration = PlayerConfiguration