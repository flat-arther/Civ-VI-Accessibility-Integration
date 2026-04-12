---@meta


---**Contexts:** Gameplay, UI
UnitManager = {}
---**Contexts:** Gameplay
---
---*Query*
---@param playerID number 
---@param domain number 
---@param militaryFormationType number 
---@param Unit Unit 
---@return boolean  
function UnitManager.CanFormMilitaryFormation(playerID, domain, militaryFormationType, Unit) end
---**Contexts:** UI
---
---*Query*
---@param Unit Unit 
---@param commandType UnitCommandTypes 
---@param unitCommandParameters table 
---@param returnResults boolean 
---@return boolean  
---@return table results 
function UnitManager.CanStartCommand(Unit, commandType, unitCommandParameters, returnResults) end
---**Contexts:** UI
---
---*Query*
---@param Unit Unit 
---@param operationType UnitOperationTypes 
---@param Plot Plot Can be nil if operationParameters is not nil
---@param operationParameters table Can be nil if Plot is not nil
---@param returnResults boolean 
---@return boolean  
---@return table results 
function UnitManager.CanStartOperation(Unit, operationType, Plot, operationParameters, returnResults) end
---**Contexts:** Gameplay
---
---*Action*
---@param Unit Unit 
---@param amount number 
function UnitManager.ChangeMovesRemaining(Unit, amount) end
---**Contexts:** Gameplay
---
---*Action*
---@param Unit Unit 
function UnitManager.FinishMoves(Unit) end
---**Contexts:** UI
---
---*Query*
---@param Unit Unit 
---@return number activityType 
function UnitManager.GetActivityType(Unit) end
---**Contexts:** UI
---
---*Query*
---@param Unit Unit 
---@param commandType UnitCommandTypes 
---@return table results 
function UnitManager.GetCommandTargets(Unit, commandType) end
---**Contexts:** UI
---
---*Query*
---@param Unit Unit 
---@param City City 
---@return number turns 
function UnitManager.GetEstablishInCityTime(Unit, City) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param Unit Unit 
---@param plotID number 
---@return Plot[] plots 
function UnitManager.GetMoveToPath(Unit, plotID) end
---**Contexts:** UI
---
---*Query*
function UnitManager.GetOperationConfirmationText() end
---**Contexts:** UI
---
---*Query*
---@param operationType UnitOperationTypes 
---@param Unit Unit 
---@param Plot Plot 
---@return string operationDetails 
function UnitManager.GetOperationDetailText(operationType, Unit, Plot) end
---**Contexts:** UI
---
---*Query*
---@param Unit Unit 
---@param operationType UnitOperationTypes 
---@param operationParameters table 
---@return table results 
function UnitManager.GetOperationTargets(Unit, operationType, operationParameters) end
---**Contexts:** Gameplay
---
---*Query*
function UnitManager.GetOperationTypeName() end
---**Contexts:** Gameplay
---
---*Query*
function UnitManager.GetOwnerName() end
---**Contexts:** UI
---
---*Query*
---@param Unit Unit 
---@return number plotID 
function UnitManager.GetQueuedDestination(Unit) end
---**Contexts:** UI
---
---*Query*
---@param Unit Unit 
---@return Plot[] plots 
function UnitManager.GetReachableMovement(Unit) end
---**Contexts:** UI
---
---*Query*
---@param Unit Unit 
---@return Plot[] plots 
function UnitManager.GetReachableTargets(Unit) end
---**Contexts:** UI
---
---*Query*
---@param Unit Unit 
---@param areVisibleToUnit boolean 
---@return Plot[] plots 
function UnitManager.GetReachableZonesOfControl(Unit, areVisibleToUnit) end
---**Contexts:** UI
---
---*Query*
---@param operationType UnitOperationTypes 
---@param Unit Unit 
---@param Plot Plot 
---@return table resultProbability 
function UnitManager.GetResultProbability(operationType, Unit, Plot) end
---**Contexts:** UI
---
---*Query*
---@param operationType UnitOperationTypes 
---@param Unit Unit 
---@return number turns 
function UnitManager.GetTimeToComplete(operationType, Unit) end
---**Contexts:** UI
---
---*Query*
---@param Unit Unit 
---@return number turns 
function UnitManager.GetTravelTime(Unit) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param Unit Unit 
---@return string unitTypeName 
function UnitManager.GetTypeName(Unit) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param playerID number 
---@param unitID number 
---@return Unit Unit 
function UnitManager.GetUnit(playerID, unitID) end
---**Contexts:** Gameplay
---
---*Action*
---@param playerID number 
---@param unitType string 
---@param x number 
---@param y number 
---@return Unit Unit 
function UnitManager.InitUnit(playerID, unitType, x, y) end
---**Contexts:** Gameplay
---
---*Action*
---@param playerID number 
---@param unitType string 
---@param x number 
---@param y number 
---@param unkown number 
function UnitManager.InitUnitValidAdjacentHex(playerID, unitType, x, y, unkown) end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UnitManager.IsUnit() end
---**Contexts:** Gameplay
---
---*Action*
---@param Unit Unit 
function UnitManager.Kill(Unit) end
---**Contexts:** Gameplay
---
---*Action*
---@param Unit Unit 
---@param newMapX number 
---@param newMapY number 
function UnitManager.MoveUnit(Unit, newMapX, newMapY) end
---**Contexts:** Gameplay
---
---*Action*
---@param Unit Unit 
---@param newMapX number 
---@param newMapY number 
function UnitManager.PlaceUnit(Unit, newMapX, newMapY) end
---**Contexts:** Gameplay
---
---*Action*
---@param Unit Unit 
---@param event string 
function UnitManager.ReportActivation(Unit, event) end
---**Contexts:** UI
---
---*Action*
---@param Unit Unit 
---@param commandType UnitCommandTypes 
---@param commandParameters table 
function UnitManager.RequestCommand(Unit, commandType, commandParameters) end
---**Contexts:** UI
---
---*Action*
---@param Unit Unit 
---@param operationType UnitOperationTypes 
---@param operationParameters table 
function UnitManager.RequestOperation(Unit, operationType, operationParameters) end
---**Contexts:** Gameplay
---
---*Action*
---@param Unit Unit 
function UnitManager.RestoreMovement(Unit) end
---**Contexts:** Gameplay
---
---*Action*
---@param Unit Unit 
function UnitManager.RestoreMovementToFormation(Unit) end
---**Contexts:** Gameplay
---
---*Action*
---@param Unit Unit 
function UnitManager.RestoreUnitAttacks(Unit) end
---**Contexts:** Gameplay
---
---*Action*
---@param Unit Unit 
function UnitManager.WakeUnit(Unit) end
---**Contexts:** UI
---
---*Query*
---@param unitID number 
---@return number baseLifespan 
function UnitManager.GetUnitTypeBaseLifespan(unitID) end
---**Contexts:** UI
---
---*Action*
function UnitManager.RequestCommandImmediate() end
---**Contexts:** UI
---
---*Query*
---@param unitHash number 
---@return number cost 
function UnitManager.GetUnitCorpsMaintenance(unitHash) end
---**Contexts:** UI
---
---*Query*
---@param unitHash number 
---@return number cost 
function UnitManager.GetUnitArmyMaintenance(unitHash) end
---**Contexts:** UI
---
---*Query*
---@param unitHash number 
---@return number cost 
function UnitManager.GetUnitMaintenance(unitHash) end
---**Contexts:** UI
---
---*Query*
function UnitManager.GetCommandResults() end
---**Contexts:** UI
---
---*Query*
---@param Unit Unit 
---@param plotID number 
---@return table pathInfo 
function UnitManager.GetMoveToPathEx(Unit, plotID) end
---**Contexts:** UI
---
---*Query*
---@param unitCommandHash number 
---@param playerID number 
---@return string commandDescription 
function UnitManager.GetCommandHelpText(unitCommandHash, playerID) end
---**Contexts:** UI
---
---*Query*
---@param unitAbilityID number 
---@return table summaries 
function UnitManager.GetAbilitySummaries(unitAbilityID) end