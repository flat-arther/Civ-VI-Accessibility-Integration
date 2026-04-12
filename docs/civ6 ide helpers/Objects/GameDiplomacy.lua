---@meta


---**Contexts:** Gameplay, UI
---@class GameDiplomacy
local GameDiplomacy = {}
---@type table<userdata, table>
GameDiplomacy.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
GameDiplomacy.TypeName = "GameDiplomacy"
---**Contexts:** UI
---
---*Query*
---@param allianceID number 
---@param allianceLevel number 
---@param unknown boolean 
---@return string benefits 
function GameDiplomacy:GetAllianceBenefitsString(allianceID, allianceLevel, unknown) end
---**Contexts:** UI
---
---*Query*
---@return number turns 
function GameDiplomacy:GetDenounceTimeLimit() end
---**Contexts:** UI
---
---*Query*
---@return number turns 
function GameDiplomacy:GetMinPeaceDuration() end
---**Contexts:** Gameplay
---
---*Action*
---@param doesShare boolean 
function GameDiplomacy:SetAlliesShareVisFlag(doesShare) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param player1ID number 
---@param player2ID number 
---@return table[] logEntries 
function GameDiplomacy:GetGrievanceLogEntries(player1ID, player2ID) end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameDiplomacy:GetGrievanceChangeTooltip() end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameDiplomacy:GetGrievanceChangePerTurn() end

z_dontRef_types.GameDiplomacy = GameDiplomacy