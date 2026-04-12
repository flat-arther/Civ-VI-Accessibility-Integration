---@meta


---**Contexts:** Gameplay, UI
Game = {}
---**Contexts:** Gameplay
---
---*Action*
---@param eventSubType EventSubTypes 
---@param text string 
---@param x number 
---@param y number 
function Game.AddWorldViewText(eventSubType, text, x, y) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return Barbarians Barbarians 
function Game.GetBarbarianManager() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number turn 
function Game.GetCurrentGameTurn() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return GameEras GameEras 
function Game.GetEras() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return FalloutManager FalloutManager 
function Game.GetFalloutManager() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return GameDiplomacy GameDiplomacy 
function Game.GetGameDiplomacy() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return GameGreatPeople GameGreatPeople 
function Game.GetGreatPeople() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return PlayerTypes | integer playerID 
function Game.GetLocalObserver() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number playerID 
function Game.GetLocalPlayer() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param areMajor boolean 
---@param areAlive boolean 
---@return Player[] players 
function Game.GetPlayers(areMajor, areAlive) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param property string 
---@return any value 
function Game:GetProperty(property) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return QuestsManager QuestsManager 
function Game.GetQuestsManager() end
---**Contexts:** Gameplay
---
---*Query*
---@param upperLimit number 
---@param logDescription string 
---@return number number 
function Game.GetRandNum(upperLimit, logDescription) end
---**Contexts:** Gameplay
---
---*Query*
---@return number gameRandomSeed 
function Game.GetRandomSeed() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return GameReligion GameReligion 
function Game.GetReligion() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return TradeManager TradeManager 
function Game.GetTradeManager() end
---**Contexts:** UI
---
---*Query*
---@return CacheCongressManager CacheCongressManager 
function Game.GetWorldCongress() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param playerID number 
---@return boolean  
function Game.IsAllowStrategicCommands(playerID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param playerID number 
---@return boolean  
function Game.IsAllowTacticalCommands(playerID) end
---**Contexts:** Gameplay, UI
---
---*Query*
function Game.ObserverCanSeePlayer() end
---**Contexts:** Gameplay
---
---*Action*
---@param turn number 
function Game.SetCurrentGameTurn(turn) end
---**Contexts:** Gameplay
---
---*Action*
---@param propertyKey string 
---@param value any 
function Game:SetProperty(propertyKey, value) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return table properties 
function Game.GetProperties() end
---**Contexts:** Gameplay
---
---*Action*
---@param seed number 
function Game.SetRandomSeed(seed) end
---**Contexts:** Gameplay
---
---*Action*
---@param playerID number 
---@param achievement string 
function Game.UnlockAchievement(playerID, achievement) end
---**Contexts:** Gameplay
---
---*Action*
function Game.WriteHistoryLog() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Game.GetComponentID() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return GameHeroesManager GameHeroesManager 
function Game.GetHeroesManager() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param playerID number 
---@param defeatType string 
---@return string requirementSet 
function Game.GetDefeatRequirements(playerID, defeatType) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return string turnSegName 
function Game.GetCurrentTurnSegmentName() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number turnSegHash 
function Game.GetCurrentTurnSegment() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Game.GetCurrentTurnPhase() end
---**Contexts:** Gameplay
---
---*Action*
---@param playerID number 
function Game.RetirePlayer(playerID) end
---**Contexts:** Gameplay, UI
---
---*Action*
function Game.GetPhaseName() end
---**Contexts:** Gameplay
---
---*Action*
---@param componentID table 
---@return table object 
function Game.GetObjectFromComponentID(componentID) end
---**Contexts:** Gameplay, UI
---
---*Action*
function Game.GetCurrentTurnPhaseName() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param defeatType string 
---@return boolean  
function Game.IsDefeatEnabled(defeatType) end
---**Contexts:** Gameplay
---
---*Action*
---@param teamID number 
function Game.SetWinningTeam(teamID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param teamID number 
---@param victoryType string 
---@return number requirementSetID 
function Game.GetVictoryRequirements(teamID, victoryType) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number teamID 
---@return string victoryType 
function Game.GetWinningTeam() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param victoryType string 
---@param teamID number 
---@return number score 
function Game.GetVictoryProgressForTeam(victoryType, teamID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param victoryType string 
---@return boolean  
function Game.IsVictoryEnabled(victoryType) end
---**Contexts:** UI
---
---*Query*
---@param greatWorkType string 
function Game.GetGreatWorkType(greatWorkType) end
---**Contexts:** UI
---
---*Query*
---@return CacheGameTechs CacheGameTechs 
function Game.GetTechs() end
---**Contexts:** UI
---
---*Query*
---@param plotID number 
---@return table artifactInfo 
function Game.GetArtifactAtPlot(plotID) end
---**Contexts:** UI
---
---*Query*
---@return CacheGameHistoryManager CacheGameHistoryManager 
function Game.GetHistoryManager() end
---**Contexts:** UI
---
---*Query*
---@return number amount 
function Game.GetActivePlayerCount() end
---**Contexts:** UI
---
---*Query*
---@return CacheGameEconomicManager CacheGameEconomicManager 
function Game.GetEconomicManager() end
---**Contexts:** UI
---
---*Query*
---@return number maxTurns 
function Game.GetMaxGameTurns() end
---**Contexts:** UI
---
---*Query*
---@param Unit Unit 
---@return string nameSuffix 
function Game.GetUnitNameSuffix(Unit) end
---**Contexts:** UI
---
---*Query*
---@return string phaseSound 
function Game.GetCurrentTurnPhaseSound() end
---**Contexts:** UI
---
---*Query*
---@return Unit[] units 
function Game.GetUnits() end
---**Contexts:** UI
---
---*Query*
---@return CacheEmergencyManager CacheEmergencyManager 
function Game.GetEmergencyManager() end
---**Contexts:** UI
---
---*Query*
---@param greatWorkIndex number 
---@return number greatWorkType 
function Game.GetGreatWorkTypeFromIndex(greatWorkIndex) end
---**Contexts:** UI
---
---*Query*
---@param Unit Unit 
function Game.GetUnitNamePrefix(Unit) end
---**Contexts:** UI
---
---*Query*
---@param Unit Unit 
---@param prefix string 
---@param suffix string 
---@return string name 
function Game.GenerateUnitName(Unit, prefix, suffix) end
---**Contexts:** UI
---
---*Query*
---@param artifactID number 
---@return table artifactInfo 
function Game.GetArtifactByIndex(artifactID) end
---**Contexts:** UI
---
---*Query*
---@return number turn 
function Game.GetGameEndTurn() end
---**Contexts:** UI
---
---*Query*
---@return CacheGameNationalParks CacheGameNationalParks 
function Game.GetNationalParks() end
---**Contexts:** UI
---
---*Query*
---@return CacheGameGossipManager CacheGameGossipManager 
function Game.GetGossipManager() end
---**Contexts:** UI
---
---*Query*
---@return CacheGameCulture CacheGameCulture 
function Game.GetCulture() end
---**Contexts:** UI
---
---*Query*
---@param greatWorkIndex number 
---@return number playerID 
function Game.GetGreatWorkPlayer(greatWorkIndex) end
---**Contexts:** UI
---
---*Query*
---@param greatWorkIndex number 
---@return table greatWorkData 
function Game.GetGreatWorkDataFromIndex(greatWorkIndex) end
---**Contexts:** UI
---
---*Query*
---@return string phaseSound 
function Game.GetPhaseSound() end