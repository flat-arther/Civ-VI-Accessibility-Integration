---@meta


---**Contexts:** Gameplay, UI
---@class GameEras
local GameEras = {}
---@type table<userdata, table>
GameEras.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
GameEras.TypeName = "GameEras"
---**Contexts:** Gameplay, UI
---
---*Query*
---
---Does not work in base game.
---@return number era 
function GameEras:GetCurrentEra() end
---**Contexts:** UI
---
---*Query*
---@return number turn 
function GameEras:GetCurrentEraMinimumEndTurn() end
---**Contexts:** UI
---
---*Query*
---@return number turn 
function GameEras:GetCurrentEraMaximumEndTurn() end
---**Contexts:** UI
---
---*Query*
---@return number turn 
function GameEras:GetCurrentEraStartTurn() end
---**Contexts:** UI
---
---*Query*
---@return number era 
function GameEras:GetFinalEra() end
---**Contexts:** UI
---
---*Query*
---@return number turn 
function GameEras:GetNextEraCountdown() end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@return number amount 
function GameEras:GetPlayerCurrentScore(playerID) end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@return number amount 
function GameEras:GetPlayerNumAllowedCommemorations(playerID) end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@return boolean  
function GameEras:HasDarkAge(playerID) end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@return boolean  
function GameEras:HasGoldenAge(playerID) end
---**Contexts:** Gameplay
---
---*Action*
---@param playerID number 
---@param amount number 
function GameEras:ChangePlayerEraScore(playerID, amount) end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@return number amount 
function GameEras:GetPlayerGoldenAgeThreshold(playerID) end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@return table thresholdBreakdown 
function GameEras:GetPlayerDarkAgeThresholdBreakdown(playerID) end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@return number amount 
function GameEras:GetPlayerPreviousDarkAgeThreshold(playerID) end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@return number amount 
function GameEras:GetPlayerDarkAgeThreshold(playerID) end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@return boolean  
function GameEras:IsPlayerAlwaysAllowedCommemorationQuest(playerID) end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@return table thresholdBreakdown 
function GameEras:GetPlayerGoldenAgeThresholdBreakdown(playerID) end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@return number amount 
function GameEras:GetCurrentEraNumPlayersAsOrLessAdvanced(playerID) end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@return number amount 
function GameEras:GetCurrentEraNumPlayersMoreAdvanced(playerID) end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@return number amount 
function GameEras:GetPlayerPreviousScore(playerID) end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@return boolean  
function GameEras:HasHeroicGoldenAge(playerID) end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@return integer[] commemorationTypes 
function GameEras:GetPlayerCommemorateChoices(playerID) end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@return table eraScoreBreakdown 
function GameEras:GetPlayerPreviousEraScoreBreakdown(playerID) end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@return integer[] commemorationTypes 
function GameEras:GetPlayerActiveCommemorations(playerID) end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@return number amount 
function GameEras:GetPlayerPreviousGoldenAgeThreshold(playerID) end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@return number amount 
function GameEras:GetPlayerThresholdBaseline(playerID) end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
function GameEras:GetPlayerComplimentChoices(playerID) end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@return table eraScoreBreakdown 
function GameEras:GetPlayerCurrentEraScoreBreakdown(playerID) end

z_dontRef_types.GameEras = GameEras