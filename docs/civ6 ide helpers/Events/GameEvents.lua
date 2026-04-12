---@meta


GameEvents = {}
GameEvents.BuildingConstructed = {}
---*Query*
---@return number amount
function GameEvents.BuildingConstructed.Count() end
---*Action*
function GameEvents.BuildingConstructed.RemoveAll() end
---*Query*
function GameEvents.BuildingConstructed.Accumulate() end
---*Query*
function GameEvents.BuildingConstructed.AccumulateINT() end
---*Action*
function GameEvents.BuildingConstructed.TestAny() end
---*Action*
function GameEvents.BuildingConstructed.TestAll() end
---*Action*
---@param playerID number
---@param cityID number
---@param buildingID number
---@param plotID number
---@param isOriginalConstruction boolean
function GameEvents.BuildingConstructed.Call(playerID, cityID, buildingID, plotID, isOriginalConstruction) end
---*Action*
---@param func fun(playerID: number, cityID: number, buildingID: number, plotID: number, isOriginalConstruction: boolean)
---@return fun(playerID: number, cityID: number, buildingID: number, plotID: number, isOriginalConstruction: boolean)
function GameEvents.BuildingConstructed.Add(func) end
---*Action*
---@param func function
function GameEvents.BuildingConstructed.Remove(func) end

GameEvents.BuildingPillageStateChanged = {}
---*Query*
---@return number amount
function GameEvents.BuildingPillageStateChanged.Count() end
---*Action*
function GameEvents.BuildingPillageStateChanged.RemoveAll() end
---*Query*
function GameEvents.BuildingPillageStateChanged.Accumulate() end
---*Query*
function GameEvents.BuildingPillageStateChanged.AccumulateINT() end
---*Action*
function GameEvents.BuildingPillageStateChanged.TestAny() end
---*Action*
function GameEvents.BuildingPillageStateChanged.TestAll() end
---*Action*
---@param playerID number
---@param cityID number
---@param buildingID number
---@param isPillaged boolean
function GameEvents.BuildingPillageStateChanged.Call(playerID, cityID, buildingID, isPillaged) end
---*Action*
---@param func fun(playerID: number, cityID: number, buildingID: number, isPillaged: boolean)
---@return fun(playerID: number, cityID: number, buildingID: number, isPillaged: boolean)
function GameEvents.BuildingPillageStateChanged.Add(func) end
---*Action*
---@param func function
function GameEvents.BuildingPillageStateChanged.Remove(func) end

GameEvents.CityBuilt = {}
---*Query*
---@return number amount
function GameEvents.CityBuilt.Count() end
---*Action*
function GameEvents.CityBuilt.RemoveAll() end
---*Query*
function GameEvents.CityBuilt.Accumulate() end
---*Query*
function GameEvents.CityBuilt.AccumulateINT() end
---*Action*
function GameEvents.CityBuilt.TestAny() end
---*Action*
function GameEvents.CityBuilt.TestAll() end
---*Action*
---@param playerID number
---@param cityID number
---@param X number
---@param Y number
function GameEvents.CityBuilt.Call(playerID, cityID, X, Y) end
---*Action*
---@param func fun(playerID: number, cityID: number, X: number, Y: number)
---@return fun(playerID: number, cityID: number, X: number, Y: number)
function GameEvents.CityBuilt.Add(func) end
---*Action*
---@param func function
function GameEvents.CityBuilt.Remove(func) end

GameEvents.CityConquered = {}
---*Query*
---@return number amount
function GameEvents.CityConquered.Count() end
---*Action*
function GameEvents.CityConquered.RemoveAll() end
---*Query*
function GameEvents.CityConquered.Accumulate() end
---*Query*
function GameEvents.CityConquered.AccumulateINT() end
---*Action*
function GameEvents.CityConquered.TestAny() end
---*Action*
function GameEvents.CityConquered.TestAll() end
---*Action*
---@param newPlayerID number
---@param oldPlayerID number
---@param newCityID number
---@param cityX number
---@param cityY number
function GameEvents.CityConquered.Call(newPlayerID, oldPlayerID, newCityID, cityX, cityY) end
---*Action*
---@param func fun(newPlayerID: number, oldPlayerID: number, newCityID: number, cityX: number, cityY: number)
---@return fun(newPlayerID: number, oldPlayerID: number, newCityID: number, cityX: number, cityY: number)
function GameEvents.CityConquered.Add(func) end
---*Action*
---@param func function
function GameEvents.CityConquered.Remove(func) end

GameEvents.DiploSurpriseDeclareWar = {}
---*Query*
---@return number amount
function GameEvents.DiploSurpriseDeclareWar.Count() end
---*Action*
function GameEvents.DiploSurpriseDeclareWar.RemoveAll() end
---*Query*
function GameEvents.DiploSurpriseDeclareWar.Accumulate() end
---*Query*
function GameEvents.DiploSurpriseDeclareWar.AccumulateINT() end
---*Action*
function GameEvents.DiploSurpriseDeclareWar.TestAny() end
---*Action*
function GameEvents.DiploSurpriseDeclareWar.TestAll() end
---*Action*
---@param mainPlayer any
---@param opponentPlayer any
function GameEvents.DiploSurpriseDeclareWar.Call(mainPlayer, opponentPlayer) end
---*Action*
---@param func fun(mainPlayer: any, opponentPlayer: any)
---@return fun(mainPlayer: any, opponentPlayer: any)
function GameEvents.DiploSurpriseDeclareWar.Add(func) end
---*Action*
---@param func function
function GameEvents.DiploSurpriseDeclareWar.Remove(func) end

GameEvents.EventPopupChoice = {}
---*Query*
---@return number amount
function GameEvents.EventPopupChoice.Count() end
---*Action*
function GameEvents.EventPopupChoice.RemoveAll() end
---*Query*
function GameEvents.EventPopupChoice.Accumulate() end
---*Query*
function GameEvents.EventPopupChoice.AccumulateINT() end
---*Action*
function GameEvents.EventPopupChoice.TestAny() end
---*Action*
function GameEvents.EventPopupChoice.TestAll() end
---*Action*
---@param playerID number
---@param parameters table
function GameEvents.EventPopupChoice.Call(playerID, parameters) end
---*Action*
---@param func fun(playerID: number, parameters: table)
---@return fun(playerID: number, parameters: table)
function GameEvents.EventPopupChoice.Add(func) end
---*Action*
---@param func function
function GameEvents.EventPopupChoice.Remove(func) end

GameEvents.FoundNewWorld = {}
---*Query*
---@return number amount
function GameEvents.FoundNewWorld.Count() end
---*Action*
function GameEvents.FoundNewWorld.RemoveAll() end
---*Query*
function GameEvents.FoundNewWorld.Accumulate() end
---*Query*
function GameEvents.FoundNewWorld.AccumulateINT() end
---*Action*
function GameEvents.FoundNewWorld.TestAny() end
---*Action*
function GameEvents.FoundNewWorld.TestAll() end
---*Action*
---@param playerID number
---@param threshold number
function GameEvents.FoundNewWorld.Call(playerID, threshold) end
---*Action*
---@param func fun(playerID: number, threshold: number)
---@return fun(playerID: number, threshold: number)
function GameEvents.FoundNewWorld.Add(func) end
---*Action*
---@param func function
function GameEvents.FoundNewWorld.Remove(func) end

GameEvents.HasFourCities = {}
---*Query*
---@return number amount
function GameEvents.HasFourCities.Count() end
---*Action*
function GameEvents.HasFourCities.RemoveAll() end
---*Query*
function GameEvents.HasFourCities.Accumulate() end
---*Query*
function GameEvents.HasFourCities.AccumulateINT() end
---*Action*
function GameEvents.HasFourCities.TestAny() end
---*Action*
function GameEvents.HasFourCities.TestAll() end
---*Action*
---@param playerID number
---@param threshold any
function GameEvents.HasFourCities.Call(playerID, threshold) end
---*Action*
---@param func fun(playerID: number, threshold: any)
---@return fun(playerID: number, threshold: any)
function GameEvents.HasFourCities.Add(func) end
---*Action*
---@param func function
function GameEvents.HasFourCities.Remove(func) end

GameEvents.OnCityPopulationChanged = {}
---*Query*
---@return number amount
function GameEvents.OnCityPopulationChanged.Count() end
---*Action*
function GameEvents.OnCityPopulationChanged.RemoveAll() end
---*Query*
function GameEvents.OnCityPopulationChanged.Accumulate() end
---*Query*
function GameEvents.OnCityPopulationChanged.AccumulateINT() end
---*Action*
function GameEvents.OnCityPopulationChanged.TestAny() end
---*Action*
function GameEvents.OnCityPopulationChanged.TestAll() end
---*Action*
---@param cityOwner number
---@param cityID number
---@param amountChanged number
function GameEvents.OnCityPopulationChanged.Call(cityOwner, cityID, amountChanged) end
---*Action*
---@param func fun(cityOwner: number, cityID: number, amountChanged: number)
---@return fun(cityOwner: number, cityID: number, amountChanged: number)
function GameEvents.OnCityPopulationChanged.Add(func) end
---*Action*
---@param func function
function GameEvents.OnCityPopulationChanged.Remove(func) end

GameEvents.OnCivicCulturevated = {}
---*Query*
---@return number amount
function GameEvents.OnCivicCulturevated.Count() end
---*Action*
function GameEvents.OnCivicCulturevated.RemoveAll() end
---*Query*
function GameEvents.OnCivicCulturevated.Accumulate() end
---*Query*
function GameEvents.OnCivicCulturevated.AccumulateINT() end
---*Action*
function GameEvents.OnCivicCulturevated.TestAny() end
---*Action*
function GameEvents.OnCivicCulturevated.TestAll() end
---*Action*
---@param playerID number
---@param civicIndex number
function GameEvents.OnCivicCulturevated.Call(playerID, civicIndex) end
---*Action*
---@param func fun(playerID: number, civicIndex: number)
---@return fun(playerID: number, civicIndex: number)
function GameEvents.OnCivicCulturevated.Add(func) end
---*Action*
---@param func function
function GameEvents.OnCivicCulturevated.Remove(func) end

GameEvents.OnDistrictConstructed = {}
---*Query*
---@return number amount
function GameEvents.OnDistrictConstructed.Count() end
---*Action*
function GameEvents.OnDistrictConstructed.RemoveAll() end
---*Query*
function GameEvents.OnDistrictConstructed.Accumulate() end
---*Query*
function GameEvents.OnDistrictConstructed.AccumulateINT() end
---*Action*
function GameEvents.OnDistrictConstructed.TestAny() end
---*Action*
function GameEvents.OnDistrictConstructed.TestAll() end
---*Action*
---@param playerID number
---@param districtID number
---@param X number
---@param Y number
function GameEvents.OnDistrictConstructed.Call(playerID, districtID, X, Y) end
---*Action*
---@param func fun(playerID: number, districtID: number, X: number, Y: number)
---@return fun(playerID: number, districtID: number, X: number, Y: number)
function GameEvents.OnDistrictConstructed.Add(func) end
---*Action*
---@param func function
function GameEvents.OnDistrictConstructed.Remove(func) end

GameEvents.OnFaithEarned = {}
---*Query*
---@return number amount
function GameEvents.OnFaithEarned.Count() end
---*Action*
function GameEvents.OnFaithEarned.RemoveAll() end
---*Query*
function GameEvents.OnFaithEarned.Accumulate() end
---*Query*
function GameEvents.OnFaithEarned.AccumulateINT() end
---*Action*
function GameEvents.OnFaithEarned.TestAny() end
---*Action*
function GameEvents.OnFaithEarned.TestAll() end
---*Action*
---@param playerID number
---@param amountEarned number
function GameEvents.OnFaithEarned.Call(playerID, amountEarned) end
---*Action*
---@param func fun(playerID: number, amountEarned: number)
---@return fun(playerID: number, amountEarned: number)
function GameEvents.OnFaithEarned.Add(func) end
---*Action*
---@param func function
function GameEvents.OnFaithEarned.Remove(func) end

GameEvents.OnGameTurnStarted = {}
---*Query*
---@return number amount
function GameEvents.OnGameTurnStarted.Count() end
---*Action*
function GameEvents.OnGameTurnStarted.RemoveAll() end
---*Query*
function GameEvents.OnGameTurnStarted.Accumulate() end
---*Query*
function GameEvents.OnGameTurnStarted.AccumulateINT() end
---*Action*
function GameEvents.OnGameTurnStarted.TestAny() end
---*Action*
function GameEvents.OnGameTurnStarted.TestAll() end
---*Action*
---@param playerID number
function GameEvents.OnGameTurnStarted.Call(playerID) end
---*Action*
---@param func fun(playerID: number)
---@return fun(playerID: number)
function GameEvents.OnGameTurnStarted.Add(func) end
---*Action*
---@param func function
function GameEvents.OnGameTurnStarted.Remove(func) end

GameEvents.OnNewMajorityReligion = {}
---*Query*
---@return number amount
function GameEvents.OnNewMajorityReligion.Count() end
---*Action*
function GameEvents.OnNewMajorityReligion.RemoveAll() end
---*Query*
function GameEvents.OnNewMajorityReligion.Accumulate() end
---*Query*
function GameEvents.OnNewMajorityReligion.AccumulateINT() end
---*Action*
function GameEvents.OnNewMajorityReligion.TestAny() end
---*Action*
function GameEvents.OnNewMajorityReligion.TestAll() end
---*Action*
function GameEvents.OnNewMajorityReligion.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.OnNewMajorityReligion.Add(func) end
---*Action*
---@param func function
function GameEvents.OnNewMajorityReligion.Remove(func) end

GameEvents.OnPillage = {}
---*Query*
---@return number amount
function GameEvents.OnPillage.Count() end
---*Action*
function GameEvents.OnPillage.RemoveAll() end
---*Query*
function GameEvents.OnPillage.Accumulate() end
---*Query*
function GameEvents.OnPillage.AccumulateINT() end
---*Action*
function GameEvents.OnPillage.TestAny() end
---*Action*
function GameEvents.OnPillage.TestAll() end
---*Action*
---@param playerID number
---@param unitID number
---@param isPillaged boolean
---@param buildingIndex number
function GameEvents.OnPillage.Call(playerID, unitID, isPillaged, buildingIndex) end
---*Action*
---@param func fun(playerID: number, unitID: number, isPillaged: boolean, buildingIndex: number)
---@return fun(playerID: number, unitID: number, isPillaged: boolean, buildingIndex: number)
function GameEvents.OnPillage.Add(func) end
---*Action*
---@param func function
function GameEvents.OnPillage.Remove(func) end

GameEvents.OnPlayerCommandSetObjectState = {}
---*Query*
---@return number amount
function GameEvents.OnPlayerCommandSetObjectState.Count() end
---*Action*
function GameEvents.OnPlayerCommandSetObjectState.RemoveAll() end
---*Query*
function GameEvents.OnPlayerCommandSetObjectState.Accumulate() end
---*Query*
function GameEvents.OnPlayerCommandSetObjectState.AccumulateINT() end
---*Action*
function GameEvents.OnPlayerCommandSetObjectState.TestAny() end
---*Action*
function GameEvents.OnPlayerCommandSetObjectState.TestAll() end
---*Action*
---@param playerID number
---@param parameters table
function GameEvents.OnPlayerCommandSetObjectState.Call(playerID, parameters) end
---*Action*
---@param func fun(playerID: number, parameters: table)
---@return fun(playerID: number, parameters: table)
function GameEvents.OnPlayerCommandSetObjectState.Add(func) end
---*Action*
---@param func function
function GameEvents.OnPlayerCommandSetObjectState.Remove(func) end

GameEvents.OnPlayerGaveInfluenceToken = {}
---*Query*
---@return number amount
function GameEvents.OnPlayerGaveInfluenceToken.Count() end
---*Action*
function GameEvents.OnPlayerGaveInfluenceToken.RemoveAll() end
---*Query*
function GameEvents.OnPlayerGaveInfluenceToken.Accumulate() end
---*Query*
function GameEvents.OnPlayerGaveInfluenceToken.AccumulateINT() end
---*Action*
function GameEvents.OnPlayerGaveInfluenceToken.TestAny() end
---*Action*
function GameEvents.OnPlayerGaveInfluenceToken.TestAll() end
---*Action*
---@param majorID number
---@param minorID number
---@param amount number
function GameEvents.OnPlayerGaveInfluenceToken.Call(majorID, minorID, amount) end
---*Action*
---@param func fun(majorID: number, minorID: number, amount: number)
---@return fun(majorID: number, minorID: number, amount: number)
function GameEvents.OnPlayerGaveInfluenceToken.Add(func) end
---*Action*
---@param func function
function GameEvents.OnPlayerGaveInfluenceToken.Remove(func) end

GameEvents.OnRandomEventOccurred = {}
---*Query*
---@return number amount
function GameEvents.OnRandomEventOccurred.Count() end
---*Action*
function GameEvents.OnRandomEventOccurred.RemoveAll() end
---*Query*
function GameEvents.OnRandomEventOccurred.Accumulate() end
---*Query*
function GameEvents.OnRandomEventOccurred.AccumulateINT() end
---*Action*
function GameEvents.OnRandomEventOccurred.TestAny() end
---*Action*
function GameEvents.OnRandomEventOccurred.TestAll() end
---*Action*
---@param iType number
---@param severity number
---@param X number
---@param Y number
---@param mitigationLevel number
function GameEvents.OnRandomEventOccurred.Call(iType, severity, X, Y, mitigationLevel) end
---*Action*
---@param func fun(iType: number, severity: number, X: number, Y: number, mitigationLevel: number)
---@return fun(iType: number, severity: number, X: number, Y: number, mitigationLevel: number)
function GameEvents.OnRandomEventOccurred.Add(func) end
---*Action*
---@param func function
function GameEvents.OnRandomEventOccurred.Remove(func) end

GameEvents.OnUnitRetreated = {}
---*Query*
---@return number amount
function GameEvents.OnUnitRetreated.Count() end
---*Action*
function GameEvents.OnUnitRetreated.RemoveAll() end
---*Query*
function GameEvents.OnUnitRetreated.Accumulate() end
---*Query*
function GameEvents.OnUnitRetreated.AccumulateINT() end
---*Action*
function GameEvents.OnUnitRetreated.TestAny() end
---*Action*
function GameEvents.OnUnitRetreated.TestAll() end
---*Action*
---@param unitOwner any
---@param unitID number
function GameEvents.OnUnitRetreated.Call(unitOwner, unitID) end
---*Action*
---@param func fun(unitOwner: any, unitID: number)
---@return fun(unitOwner: any, unitID: number)
function GameEvents.OnUnitRetreated.Add(func) end
---*Action*
---@param func function
function GameEvents.OnUnitRetreated.Remove(func) end

GameEvents.PlayerTurnStartComplete = {}
---*Query*
---@return number amount
function GameEvents.PlayerTurnStartComplete.Count() end
---*Action*
function GameEvents.PlayerTurnStartComplete.RemoveAll() end
---*Query*
function GameEvents.PlayerTurnStartComplete.Accumulate() end
---*Query*
function GameEvents.PlayerTurnStartComplete.AccumulateINT() end
---*Action*
function GameEvents.PlayerTurnStartComplete.TestAny() end
---*Action*
function GameEvents.PlayerTurnStartComplete.TestAll() end
---*Action*
---@param playerID number
function GameEvents.PlayerTurnStartComplete.Call(playerID) end
---*Action*
---@param func fun(playerID: number)
---@return fun(playerID: number)
function GameEvents.PlayerTurnStartComplete.Add(func) end
---*Action*
---@param func function
function GameEvents.PlayerTurnStartComplete.Remove(func) end

GameEvents.PlayerTurnStarted = {}
---*Query*
---@return number amount
function GameEvents.PlayerTurnStarted.Count() end
---*Action*
function GameEvents.PlayerTurnStarted.RemoveAll() end
---*Query*
function GameEvents.PlayerTurnStarted.Accumulate() end
---*Query*
function GameEvents.PlayerTurnStarted.AccumulateINT() end
---*Action*
function GameEvents.PlayerTurnStarted.TestAny() end
---*Action*
function GameEvents.PlayerTurnStarted.TestAll() end
---*Action*
---@param playerID number
function GameEvents.PlayerTurnStarted.Call(playerID) end
---*Action*
---@param func fun(playerID: number)
---@return fun(playerID: number)
function GameEvents.PlayerTurnStarted.Add(func) end
---*Action*
---@param func function
function GameEvents.PlayerTurnStarted.Remove(func) end

GameEvents.PlotOwnershipChanged = {}
---*Query*
---@return number amount
function GameEvents.PlotOwnershipChanged.Count() end
---*Action*
function GameEvents.PlotOwnershipChanged.RemoveAll() end
---*Query*
function GameEvents.PlotOwnershipChanged.Accumulate() end
---*Query*
function GameEvents.PlotOwnershipChanged.AccumulateINT() end
---*Action*
function GameEvents.PlotOwnershipChanged.TestAny() end
---*Action*
function GameEvents.PlotOwnershipChanged.TestAll() end
---*Action*
function GameEvents.PlotOwnershipChanged.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.PlotOwnershipChanged.Add(func) end
---*Action*
---@param func function
function GameEvents.PlotOwnershipChanged.Remove(func) end

GameEvents.PlotPropertyChanged = {}
---*Query*
---@return number amount
function GameEvents.PlotPropertyChanged.Count() end
---*Action*
function GameEvents.PlotPropertyChanged.RemoveAll() end
---*Query*
function GameEvents.PlotPropertyChanged.Accumulate() end
---*Query*
function GameEvents.PlotPropertyChanged.AccumulateINT() end
---*Action*
function GameEvents.PlotPropertyChanged.TestAny() end
---*Action*
function GameEvents.PlotPropertyChanged.TestAll() end
---*Action*
---@param X number
---@param Y number
function GameEvents.PlotPropertyChanged.Call(X, Y) end
---*Action*
---@param func fun(X: number, Y: number)
---@return fun(X: number, Y: number)
function GameEvents.PlotPropertyChanged.Add(func) end
---*Action*
---@param func function
function GameEvents.PlotPropertyChanged.Remove(func) end

GameEvents.PolicyChanged = {}
---*Query*
---@return number amount
function GameEvents.PolicyChanged.Count() end
---*Action*
function GameEvents.PolicyChanged.RemoveAll() end
---*Query*
function GameEvents.PolicyChanged.Accumulate() end
---*Query*
function GameEvents.PolicyChanged.AccumulateINT() end
---*Action*
function GameEvents.PolicyChanged.TestAny() end
---*Action*
function GameEvents.PolicyChanged.TestAll() end
---*Action*
---@param playerID number
---@param policyID number
---@param wasEnacted boolean
function GameEvents.PolicyChanged.Call(playerID, policyID, wasEnacted) end
---*Action*
---@param func fun(playerID: number, policyID: number, wasEnacted: boolean)
---@return fun(playerID: number, policyID: number, wasEnacted: boolean)
function GameEvents.PolicyChanged.Add(func) end
---*Action*
---@param func function
function GameEvents.PolicyChanged.Remove(func) end

GameEvents.UnitAddedToMap = {}
---*Query*
---@return number amount
function GameEvents.UnitAddedToMap.Count() end
---*Action*
function GameEvents.UnitAddedToMap.RemoveAll() end
---*Query*
function GameEvents.UnitAddedToMap.Accumulate() end
---*Query*
function GameEvents.UnitAddedToMap.AccumulateINT() end
---*Action*
function GameEvents.UnitAddedToMap.TestAny() end
---*Action*
function GameEvents.UnitAddedToMap.TestAll() end
---*Action*
---@param playerID number
---@param unitID number
function GameEvents.UnitAddedToMap.Call(playerID, unitID) end
---*Action*
---@param func fun(playerID: number, unitID: number)
---@return fun(playerID: number, unitID: number)
function GameEvents.UnitAddedToMap.Add(func) end
---*Action*
---@param func function
function GameEvents.UnitAddedToMap.Remove(func) end

GameEvents.ScenarioCommand_UnitCloak = {}
---*Query*
---@return number amount
function GameEvents.ScenarioCommand_UnitCloak.Count() end
---*Action*
function GameEvents.ScenarioCommand_UnitCloak.RemoveAll() end
---*Query*
function GameEvents.ScenarioCommand_UnitCloak.Accumulate() end
---*Query*
function GameEvents.ScenarioCommand_UnitCloak.AccumulateINT() end
---*Action*
function GameEvents.ScenarioCommand_UnitCloak.TestAny() end
---*Action*
function GameEvents.ScenarioCommand_UnitCloak.TestAll() end
---*Action*
function GameEvents.ScenarioCommand_UnitCloak.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.ScenarioCommand_UnitCloak.Add(func) end
---*Action*
---@param func function
function GameEvents.ScenarioCommand_UnitCloak.Remove(func) end

GameEvents.WC_Validate_ArmsControlTreaty = {}
---*Query*
---@return number amount
function GameEvents.WC_Validate_ArmsControlTreaty.Count() end
---*Action*
function GameEvents.WC_Validate_ArmsControlTreaty.RemoveAll() end
---*Query*
function GameEvents.WC_Validate_ArmsControlTreaty.Accumulate() end
---*Query*
function GameEvents.WC_Validate_ArmsControlTreaty.AccumulateINT() end
---*Action*
function GameEvents.WC_Validate_ArmsControlTreaty.TestAny() end
---*Action*
function GameEvents.WC_Validate_ArmsControlTreaty.TestAll() end
---*Action*
function GameEvents.WC_Validate_ArmsControlTreaty.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.WC_Validate_ArmsControlTreaty.Add(func) end
---*Action*
---@param func function
function GameEvents.WC_Validate_ArmsControlTreaty.Remove(func) end

GameEvents.ScenarioCommand_ShoreParty = {}
---*Query*
---@return number amount
function GameEvents.ScenarioCommand_ShoreParty.Count() end
---*Action*
function GameEvents.ScenarioCommand_ShoreParty.RemoveAll() end
---*Query*
function GameEvents.ScenarioCommand_ShoreParty.Accumulate() end
---*Query*
function GameEvents.ScenarioCommand_ShoreParty.AccumulateINT() end
---*Action*
function GameEvents.ScenarioCommand_ShoreParty.TestAny() end
---*Action*
function GameEvents.ScenarioCommand_ShoreParty.TestAll() end
---*Action*
function GameEvents.ScenarioCommand_ShoreParty.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.ScenarioCommand_ShoreParty.Add(func) end
---*Action*
---@param func function
function GameEvents.ScenarioCommand_ShoreParty.Remove(func) end

GameEvents.ScenarioCommand_HoarderActive = {}
---*Query*
---@return number amount
function GameEvents.ScenarioCommand_HoarderActive.Count() end
---*Action*
function GameEvents.ScenarioCommand_HoarderActive.RemoveAll() end
---*Query*
function GameEvents.ScenarioCommand_HoarderActive.Accumulate() end
---*Query*
function GameEvents.ScenarioCommand_HoarderActive.AccumulateINT() end
---*Action*
function GameEvents.ScenarioCommand_HoarderActive.TestAny() end
---*Action*
function GameEvents.ScenarioCommand_HoarderActive.TestAll() end
---*Action*
function GameEvents.ScenarioCommand_HoarderActive.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.ScenarioCommand_HoarderActive.Add(func) end
---*Action*
---@param func function
function GameEvents.ScenarioCommand_HoarderActive.Remove(func) end

GameEvents.WC_Validate_BorderControl = {}
---*Query*
---@return number amount
function GameEvents.WC_Validate_BorderControl.Count() end
---*Action*
function GameEvents.WC_Validate_BorderControl.RemoveAll() end
---*Query*
function GameEvents.WC_Validate_BorderControl.Accumulate() end
---*Query*
function GameEvents.WC_Validate_BorderControl.AccumulateINT() end
---*Action*
function GameEvents.WC_Validate_BorderControl.TestAny() end
---*Action*
function GameEvents.WC_Validate_BorderControl.TestAll() end
---*Action*
function GameEvents.WC_Validate_BorderControl.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.WC_Validate_BorderControl.Add(func) end
---*Action*
---@param func function
function GameEvents.WC_Validate_BorderControl.Remove(func) end

GameEvents.UnitInitialized = {}
---*Query*
---@return number amount
function GameEvents.UnitInitialized.Count() end
---*Action*
function GameEvents.UnitInitialized.RemoveAll() end
---*Query*
function GameEvents.UnitInitialized.Accumulate() end
---*Query*
function GameEvents.UnitInitialized.AccumulateINT() end
---*Action*
function GameEvents.UnitInitialized.TestAny() end
---*Action*
function GameEvents.UnitInitialized.TestAll() end
---*Action*
function GameEvents.UnitInitialized.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.UnitInitialized.Add(func) end
---*Action*
---@param func function
function GameEvents.UnitInitialized.Remove(func) end

GameEvents.WC_Validate_WorldIdeology = {}
---*Query*
---@return number amount
function GameEvents.WC_Validate_WorldIdeology.Count() end
---*Action*
function GameEvents.WC_Validate_WorldIdeology.RemoveAll() end
---*Query*
function GameEvents.WC_Validate_WorldIdeology.Accumulate() end
---*Query*
function GameEvents.WC_Validate_WorldIdeology.AccumulateINT() end
---*Action*
function GameEvents.WC_Validate_WorldIdeology.TestAny() end
---*Action*
function GameEvents.WC_Validate_WorldIdeology.TestAll() end
---*Action*
function GameEvents.WC_Validate_WorldIdeology.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.WC_Validate_WorldIdeology.Add(func) end
---*Action*
---@param func function
function GameEvents.WC_Validate_WorldIdeology.Remove(func) end

GameEvents.WC_ValidateGovernanceDoctrine = {}
---*Query*
---@return number amount
function GameEvents.WC_ValidateGovernanceDoctrine.Count() end
---*Action*
function GameEvents.WC_ValidateGovernanceDoctrine.RemoveAll() end
---*Query*
function GameEvents.WC_ValidateGovernanceDoctrine.Accumulate() end
---*Query*
function GameEvents.WC_ValidateGovernanceDoctrine.AccumulateINT() end
---*Action*
function GameEvents.WC_ValidateGovernanceDoctrine.TestAny() end
---*Action*
function GameEvents.WC_ValidateGovernanceDoctrine.TestAll() end
---*Action*
function GameEvents.WC_ValidateGovernanceDoctrine.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.WC_ValidateGovernanceDoctrine.Add(func) end
---*Action*
---@param func function
function GameEvents.WC_ValidateGovernanceDoctrine.Remove(func) end

GameEvents.ScenarioCommand_PlaceTrap = {}
---*Query*
---@return number amount
function GameEvents.ScenarioCommand_PlaceTrap.Count() end
---*Action*
function GameEvents.ScenarioCommand_PlaceTrap.RemoveAll() end
---*Query*
function GameEvents.ScenarioCommand_PlaceTrap.Accumulate() end
---*Query*
function GameEvents.ScenarioCommand_PlaceTrap.AccumulateINT() end
---*Action*
function GameEvents.ScenarioCommand_PlaceTrap.TestAny() end
---*Action*
function GameEvents.ScenarioCommand_PlaceTrap.TestAll() end
---*Action*
function GameEvents.ScenarioCommand_PlaceTrap.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.ScenarioCommand_PlaceTrap.Add(func) end
---*Action*
---@param func function
function GameEvents.ScenarioCommand_PlaceTrap.Remove(func) end

GameEvents.WC_Validate_PowerResourceBan = {}
---*Query*
---@return number amount
function GameEvents.WC_Validate_PowerResourceBan.Count() end
---*Action*
function GameEvents.WC_Validate_PowerResourceBan.RemoveAll() end
---*Query*
function GameEvents.WC_Validate_PowerResourceBan.Accumulate() end
---*Query*
function GameEvents.WC_Validate_PowerResourceBan.AccumulateINT() end
---*Action*
function GameEvents.WC_Validate_PowerResourceBan.TestAny() end
---*Action*
function GameEvents.WC_Validate_PowerResourceBan.TestAll() end
---*Action*
function GameEvents.WC_Validate_PowerResourceBan.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.WC_Validate_PowerResourceBan.Add(func) end
---*Action*
---@param func function
function GameEvents.WC_Validate_PowerResourceBan.Remove(func) end

GameEvents.WC_Validate_DeforestationFeature = {}
---*Query*
---@return number amount
function GameEvents.WC_Validate_DeforestationFeature.Count() end
---*Action*
function GameEvents.WC_Validate_DeforestationFeature.RemoveAll() end
---*Query*
function GameEvents.WC_Validate_DeforestationFeature.Accumulate() end
---*Query*
function GameEvents.WC_Validate_DeforestationFeature.AccumulateINT() end
---*Action*
function GameEvents.WC_Validate_DeforestationFeature.TestAny() end
---*Action*
function GameEvents.WC_Validate_DeforestationFeature.TestAll() end
---*Action*
function GameEvents.WC_Validate_DeforestationFeature.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.WC_Validate_DeforestationFeature.Add(func) end
---*Action*
---@param func function
function GameEvents.WC_Validate_DeforestationFeature.Remove(func) end

GameEvents.OnUnitMoved = {}
---*Query*
---@return number amount
function GameEvents.OnUnitMoved.Count() end
---*Action*
function GameEvents.OnUnitMoved.RemoveAll() end
---*Query*
function GameEvents.OnUnitMoved.Accumulate() end
---*Query*
function GameEvents.OnUnitMoved.AccumulateINT() end
---*Action*
function GameEvents.OnUnitMoved.TestAny() end
---*Action*
function GameEvents.OnUnitMoved.TestAll() end
---*Action*
function GameEvents.OnUnitMoved.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.OnUnitMoved.Add(func) end
---*Action*
---@param func function
function GameEvents.OnUnitMoved.Remove(func) end

GameEvents.CivRoyale_GetSafeZone = {}
---*Query*
---@return number amount
function GameEvents.CivRoyale_GetSafeZone.Count() end
---*Action*
function GameEvents.CivRoyale_GetSafeZone.RemoveAll() end
---*Query*
function GameEvents.CivRoyale_GetSafeZone.Accumulate() end
---*Query*
function GameEvents.CivRoyale_GetSafeZone.AccumulateINT() end
---*Action*
function GameEvents.CivRoyale_GetSafeZone.TestAny() end
---*Action*
function GameEvents.CivRoyale_GetSafeZone.TestAll() end
---*Action*
function GameEvents.CivRoyale_GetSafeZone.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.CivRoyale_GetSafeZone.Add(func) end
---*Action*
---@param func function
function GameEvents.CivRoyale_GetSafeZone.Remove(func) end

GameEvents.OnWMDCountChanged = {}
---*Query*
---@return number amount
function GameEvents.OnWMDCountChanged.Count() end
---*Action*
function GameEvents.OnWMDCountChanged.RemoveAll() end
---*Query*
function GameEvents.OnWMDCountChanged.Accumulate() end
---*Query*
function GameEvents.OnWMDCountChanged.AccumulateINT() end
---*Action*
function GameEvents.OnWMDCountChanged.TestAny() end
---*Action*
function GameEvents.OnWMDCountChanged.TestAll() end
---*Action*
function GameEvents.OnWMDCountChanged.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.OnWMDCountChanged.Add(func) end
---*Action*
---@param func function
function GameEvents.OnWMDCountChanged.Remove(func) end

GameEvents.ScenarioCommand_BurnTreasureMap = {}
---*Query*
---@return number amount
function GameEvents.ScenarioCommand_BurnTreasureMap.Count() end
---*Action*
function GameEvents.ScenarioCommand_BurnTreasureMap.RemoveAll() end
---*Query*
function GameEvents.ScenarioCommand_BurnTreasureMap.Accumulate() end
---*Query*
function GameEvents.ScenarioCommand_BurnTreasureMap.AccumulateINT() end
---*Action*
function GameEvents.ScenarioCommand_BurnTreasureMap.TestAny() end
---*Action*
function GameEvents.ScenarioCommand_BurnTreasureMap.TestAll() end
---*Action*
function GameEvents.ScenarioCommand_BurnTreasureMap.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.ScenarioCommand_BurnTreasureMap.Add(func) end
---*Action*
---@param func function
function GameEvents.ScenarioCommand_BurnTreasureMap.Remove(func) end

GameEvents.WC_Validate_LuxuryBan = {}
---*Query*
---@return number amount
function GameEvents.WC_Validate_LuxuryBan.Count() end
---*Action*
function GameEvents.WC_Validate_LuxuryBan.RemoveAll() end
---*Query*
function GameEvents.WC_Validate_LuxuryBan.Accumulate() end
---*Query*
function GameEvents.WC_Validate_LuxuryBan.AccumulateINT() end
---*Action*
function GameEvents.WC_Validate_LuxuryBan.TestAny() end
---*Action*
function GameEvents.WC_Validate_LuxuryBan.TestAll() end
---*Action*
function GameEvents.WC_Validate_LuxuryBan.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.WC_Validate_LuxuryBan.Add(func) end
---*Action*
---@param func function
function GameEvents.WC_Validate_LuxuryBan.Remove(func) end

GameEvents.ScenarioCommand_HolyFervor = {}
---*Query*
---@return number amount
function GameEvents.ScenarioCommand_HolyFervor.Count() end
---*Action*
function GameEvents.ScenarioCommand_HolyFervor.RemoveAll() end
---*Query*
function GameEvents.ScenarioCommand_HolyFervor.Accumulate() end
---*Query*
function GameEvents.ScenarioCommand_HolyFervor.AccumulateINT() end
---*Action*
function GameEvents.ScenarioCommand_HolyFervor.TestAny() end
---*Action*
function GameEvents.ScenarioCommand_HolyFervor.TestAll() end
---*Action*
function GameEvents.ScenarioCommand_HolyFervor.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.ScenarioCommand_HolyFervor.Add(func) end
---*Action*
---@param func function
function GameEvents.ScenarioCommand_HolyFervor.Remove(func) end

GameEvents.ScenarioCommand_Purge = {}
---*Query*
---@return number amount
function GameEvents.ScenarioCommand_Purge.Count() end
---*Action*
function GameEvents.ScenarioCommand_Purge.RemoveAll() end
---*Query*
function GameEvents.ScenarioCommand_Purge.Accumulate() end
---*Query*
function GameEvents.ScenarioCommand_Purge.AccumulateINT() end
---*Action*
function GameEvents.ScenarioCommand_Purge.TestAny() end
---*Action*
function GameEvents.ScenarioCommand_Purge.TestAll() end
---*Action*
function GameEvents.ScenarioCommand_Purge.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.ScenarioCommand_Purge.Add(func) end
---*Action*
---@param func function
function GameEvents.ScenarioCommand_Purge.Remove(func) end

GameEvents.ScenarioCommand_UnitShield = {}
---*Query*
---@return number amount
function GameEvents.ScenarioCommand_UnitShield.Count() end
---*Action*
function GameEvents.ScenarioCommand_UnitShield.RemoveAll() end
---*Query*
function GameEvents.ScenarioCommand_UnitShield.Accumulate() end
---*Query*
function GameEvents.ScenarioCommand_UnitShield.AccumulateINT() end
---*Action*
function GameEvents.ScenarioCommand_UnitShield.TestAny() end
---*Action*
function GameEvents.ScenarioCommand_UnitShield.TestAll() end
---*Action*
function GameEvents.ScenarioCommand_UnitShield.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.ScenarioCommand_UnitShield.Add(func) end
---*Action*
---@param func function
function GameEvents.ScenarioCommand_UnitShield.Remove(func) end

GameEvents.ScenarioCommand_RoadVision = {}
---*Query*
---@return number amount
function GameEvents.ScenarioCommand_RoadVision.Count() end
---*Action*
function GameEvents.ScenarioCommand_RoadVision.RemoveAll() end
---*Query*
function GameEvents.ScenarioCommand_RoadVision.Accumulate() end
---*Query*
function GameEvents.ScenarioCommand_RoadVision.AccumulateINT() end
---*Action*
function GameEvents.ScenarioCommand_RoadVision.TestAny() end
---*Action*
function GameEvents.ScenarioCommand_RoadVision.TestAll() end
---*Action*
function GameEvents.ScenarioCommand_RoadVision.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.ScenarioCommand_RoadVision.Add(func) end
---*Action*
---@param func function
function GameEvents.ScenarioCommand_RoadVision.Remove(func) end

GameEvents.ScenarioCommand_Careening = {}
---*Query*
---@return number amount
function GameEvents.ScenarioCommand_Careening.Count() end
---*Action*
function GameEvents.ScenarioCommand_Careening.RemoveAll() end
---*Query*
function GameEvents.ScenarioCommand_Careening.Accumulate() end
---*Query*
function GameEvents.ScenarioCommand_Careening.AccumulateINT() end
---*Action*
function GameEvents.ScenarioCommand_Careening.TestAny() end
---*Action*
function GameEvents.ScenarioCommand_Careening.TestAll() end
---*Action*
function GameEvents.ScenarioCommand_Careening.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.ScenarioCommand_Careening.Add(func) end
---*Action*
---@param func function
function GameEvents.ScenarioCommand_Careening.Remove(func) end

GameEvents.WC_Validate_TradeTreaty = {}
---*Query*
---@return number amount
function GameEvents.WC_Validate_TradeTreaty.Count() end
---*Action*
function GameEvents.WC_Validate_TradeTreaty.RemoveAll() end
---*Query*
function GameEvents.WC_Validate_TradeTreaty.Accumulate() end
---*Query*
function GameEvents.WC_Validate_TradeTreaty.AccumulateINT() end
---*Action*
function GameEvents.WC_Validate_TradeTreaty.TestAny() end
---*Action*
function GameEvents.WC_Validate_TradeTreaty.TestAll() end
---*Action*
function GameEvents.WC_Validate_TradeTreaty.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.WC_Validate_TradeTreaty.Add(func) end
---*Action*
---@param func function
function GameEvents.WC_Validate_TradeTreaty.Remove(func) end

GameEvents.WC_Validate_YieldBan = {}
---*Query*
---@return number amount
function GameEvents.WC_Validate_YieldBan.Count() end
---*Action*
function GameEvents.WC_Validate_YieldBan.RemoveAll() end
---*Query*
function GameEvents.WC_Validate_YieldBan.Accumulate() end
---*Query*
function GameEvents.WC_Validate_YieldBan.AccumulateINT() end
---*Action*
function GameEvents.WC_Validate_YieldBan.TestAny() end
---*Action*
function GameEvents.WC_Validate_YieldBan.TestAll() end
---*Action*
function GameEvents.WC_Validate_YieldBan.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.WC_Validate_YieldBan.Add(func) end
---*Action*
---@param func function
function GameEvents.WC_Validate_YieldBan.Remove(func) end

GameEvents.ScenarioCommand_Minister = {}
---*Query*
---@return number amount
function GameEvents.ScenarioCommand_Minister.Count() end
---*Action*
function GameEvents.ScenarioCommand_Minister.RemoveAll() end
---*Query*
function GameEvents.ScenarioCommand_Minister.Accumulate() end
---*Query*
function GameEvents.ScenarioCommand_Minister.AccumulateINT() end
---*Action*
function GameEvents.ScenarioCommand_Minister.TestAny() end
---*Action*
function GameEvents.ScenarioCommand_Minister.TestAll() end
---*Action*
function GameEvents.ScenarioCommand_Minister.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.ScenarioCommand_Minister.Add(func) end
---*Action*
---@param func function
function GameEvents.ScenarioCommand_Minister.Remove(func) end

GameEvents.WC_Validate_ESPIONAGE_PACT = {}
---*Query*
---@return number amount
function GameEvents.WC_Validate_ESPIONAGE_PACT.Count() end
---*Action*
function GameEvents.WC_Validate_ESPIONAGE_PACT.RemoveAll() end
---*Query*
function GameEvents.WC_Validate_ESPIONAGE_PACT.Accumulate() end
---*Query*
function GameEvents.WC_Validate_ESPIONAGE_PACT.AccumulateINT() end
---*Action*
function GameEvents.WC_Validate_ESPIONAGE_PACT.TestAny() end
---*Action*
function GameEvents.WC_Validate_ESPIONAGE_PACT.TestAll() end
---*Action*
function GameEvents.WC_Validate_ESPIONAGE_PACT.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.WC_Validate_ESPIONAGE_PACT.Add(func) end
---*Action*
---@param func function
function GameEvents.WC_Validate_ESPIONAGE_PACT.Remove(func) end

GameEvents.OnImprovementPillaged = {}
---*Query*
---@return number amount
function GameEvents.OnImprovementPillaged.Count() end
---*Action*
function GameEvents.OnImprovementPillaged.RemoveAll() end
---*Query*
function GameEvents.OnImprovementPillaged.Accumulate() end
---*Query*
function GameEvents.OnImprovementPillaged.AccumulateINT() end
---*Action*
function GameEvents.OnImprovementPillaged.TestAny() end
---*Action*
function GameEvents.OnImprovementPillaged.TestAll() end
---*Action*
function GameEvents.OnImprovementPillaged.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.OnImprovementPillaged.Add(func) end
---*Action*
---@param func function
function GameEvents.OnImprovementPillaged.Remove(func) end

GameEvents.PostUnitPromotionEarned = {}
---*Query*
---@return number amount
function GameEvents.PostUnitPromotionEarned.Count() end
---*Action*
function GameEvents.PostUnitPromotionEarned.RemoveAll() end
---*Query*
function GameEvents.PostUnitPromotionEarned.Accumulate() end
---*Query*
function GameEvents.PostUnitPromotionEarned.AccumulateINT() end
---*Action*
function GameEvents.PostUnitPromotionEarned.TestAny() end
---*Action*
function GameEvents.PostUnitPromotionEarned.TestAll() end
---*Action*
function GameEvents.PostUnitPromotionEarned.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.PostUnitPromotionEarned.Add(func) end
---*Action*
---@param func function
function GameEvents.PostUnitPromotionEarned.Remove(func) end

GameEvents.WC_Validate_PublicWorks = {}
---*Query*
---@return number amount
function GameEvents.WC_Validate_PublicWorks.Count() end
---*Action*
function GameEvents.WC_Validate_PublicWorks.RemoveAll() end
---*Query*
function GameEvents.WC_Validate_PublicWorks.Accumulate() end
---*Query*
function GameEvents.WC_Validate_PublicWorks.AccumulateINT() end
---*Action*
function GameEvents.WC_Validate_PublicWorks.TestAny() end
---*Action*
function GameEvents.WC_Validate_PublicWorks.TestAll() end
---*Action*
function GameEvents.WC_Validate_PublicWorks.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.WC_Validate_PublicWorks.Add(func) end
---*Action*
---@param func function
function GameEvents.WC_Validate_PublicWorks.Remove(func) end

GameEvents.WC_Validate_DiploVictory = {}
---*Query*
---@return number amount
function GameEvents.WC_Validate_DiploVictory.Count() end
---*Action*
function GameEvents.WC_Validate_DiploVictory.RemoveAll() end
---*Query*
function GameEvents.WC_Validate_DiploVictory.Accumulate() end
---*Query*
function GameEvents.WC_Validate_DiploVictory.AccumulateINT() end
---*Action*
function GameEvents.WC_Validate_DiploVictory.TestAny() end
---*Action*
function GameEvents.WC_Validate_DiploVictory.TestAll() end
---*Action*
function GameEvents.WC_Validate_DiploVictory.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.WC_Validate_DiploVictory.Add(func) end
---*Action*
---@param func function
function GameEvents.WC_Validate_DiploVictory.Remove(func) end

GameEvents.OnPlayerTurnEnded = {}
---*Query*
---@return number amount
function GameEvents.OnPlayerTurnEnded.Count() end
---*Action*
function GameEvents.OnPlayerTurnEnded.RemoveAll() end
---*Query*
function GameEvents.OnPlayerTurnEnded.Accumulate() end
---*Query*
function GameEvents.OnPlayerTurnEnded.AccumulateINT() end
---*Action*
function GameEvents.OnPlayerTurnEnded.TestAny() end
---*Action*
function GameEvents.OnPlayerTurnEnded.TestAll() end
---*Action*
function GameEvents.OnPlayerTurnEnded.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.OnPlayerTurnEnded.Add(func) end
---*Action*
---@param func function
function GameEvents.OnPlayerTurnEnded.Remove(func) end

GameEvents.WC_Validate_GreatWorkObjects = {}
---*Query*
---@return number amount
function GameEvents.WC_Validate_GreatWorkObjects.Count() end
---*Action*
function GameEvents.WC_Validate_GreatWorkObjects.RemoveAll() end
---*Query*
function GameEvents.WC_Validate_GreatWorkObjects.Accumulate() end
---*Query*
function GameEvents.WC_Validate_GreatWorkObjects.AccumulateINT() end
---*Action*
function GameEvents.WC_Validate_GreatWorkObjects.TestAny() end
---*Action*
function GameEvents.WC_Validate_GreatWorkObjects.TestAll() end
---*Action*
function GameEvents.WC_Validate_GreatWorkObjects.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.WC_Validate_GreatWorkObjects.Add(func) end
---*Action*
---@param func function
function GameEvents.WC_Validate_GreatWorkObjects.Remove(func) end

GameEvents.ScenarioCommand_Study = {}
---*Query*
---@return number amount
function GameEvents.ScenarioCommand_Study.Count() end
---*Action*
function GameEvents.ScenarioCommand_Study.RemoveAll() end
---*Query*
function GameEvents.ScenarioCommand_Study.Accumulate() end
---*Query*
function GameEvents.ScenarioCommand_Study.AccumulateINT() end
---*Action*
function GameEvents.ScenarioCommand_Study.TestAny() end
---*Action*
function GameEvents.ScenarioCommand_Study.TestAll() end
---*Action*
function GameEvents.ScenarioCommand_Study.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.ScenarioCommand_Study.Add(func) end
---*Action*
---@param func function
function GameEvents.ScenarioCommand_Study.Remove(func) end

GameEvents.PiratesScenario_DeleteUnitsAtGoal = {}
---*Query*
---@return number amount
function GameEvents.PiratesScenario_DeleteUnitsAtGoal.Count() end
---*Action*
function GameEvents.PiratesScenario_DeleteUnitsAtGoal.RemoveAll() end
---*Query*
function GameEvents.PiratesScenario_DeleteUnitsAtGoal.Accumulate() end
---*Query*
function GameEvents.PiratesScenario_DeleteUnitsAtGoal.AccumulateINT() end
---*Action*
function GameEvents.PiratesScenario_DeleteUnitsAtGoal.TestAny() end
---*Action*
function GameEvents.PiratesScenario_DeleteUnitsAtGoal.TestAll() end
---*Action*
function GameEvents.PiratesScenario_DeleteUnitsAtGoal.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.PiratesScenario_DeleteUnitsAtGoal.Add(func) end
---*Action*
---@param func function
function GameEvents.PiratesScenario_DeleteUnitsAtGoal.Remove(func) end

GameEvents.ScenarioCommand_UnitRadSpread = {}
---*Query*
---@return number amount
function GameEvents.ScenarioCommand_UnitRadSpread.Count() end
---*Action*
function GameEvents.ScenarioCommand_UnitRadSpread.RemoveAll() end
---*Query*
function GameEvents.ScenarioCommand_UnitRadSpread.Accumulate() end
---*Query*
function GameEvents.ScenarioCommand_UnitRadSpread.AccumulateINT() end
---*Action*
function GameEvents.ScenarioCommand_UnitRadSpread.TestAny() end
---*Action*
function GameEvents.ScenarioCommand_UnitRadSpread.TestAll() end
---*Action*
function GameEvents.ScenarioCommand_UnitRadSpread.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.ScenarioCommand_UnitRadSpread.Add(func) end
---*Action*
---@param func function
function GameEvents.ScenarioCommand_UnitRadSpread.Remove(func) end

GameEvents.OnNuclearWeaponDetonated = {}
---*Query*
---@return number amount
function GameEvents.OnNuclearWeaponDetonated.Count() end
---*Action*
function GameEvents.OnNuclearWeaponDetonated.RemoveAll() end
---*Query*
function GameEvents.OnNuclearWeaponDetonated.Accumulate() end
---*Query*
function GameEvents.OnNuclearWeaponDetonated.AccumulateINT() end
---*Action*
function GameEvents.OnNuclearWeaponDetonated.TestAny() end
---*Action*
function GameEvents.OnNuclearWeaponDetonated.TestAll() end
---*Action*
function GameEvents.OnNuclearWeaponDetonated.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.OnNuclearWeaponDetonated.Add(func) end
---*Action*
---@param func function
function GameEvents.OnNuclearWeaponDetonated.Remove(func) end

GameEvents.OnGreatPersonActivated = {}
---*Query*
---@return number amount
function GameEvents.OnGreatPersonActivated.Count() end
---*Action*
function GameEvents.OnGreatPersonActivated.RemoveAll() end
---*Query*
function GameEvents.OnGreatPersonActivated.Accumulate() end
---*Query*
function GameEvents.OnGreatPersonActivated.AccumulateINT() end
---*Action*
function GameEvents.OnGreatPersonActivated.TestAny() end
---*Action*
function GameEvents.OnGreatPersonActivated.TestAll() end
---*Action*
function GameEvents.OnGreatPersonActivated.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.OnGreatPersonActivated.Add(func) end
---*Action*
---@param func function
function GameEvents.OnGreatPersonActivated.Remove(func) end

GameEvents.ScenarioCommand_UnitSacrifice = {}
---*Query*
---@return number amount
function GameEvents.ScenarioCommand_UnitSacrifice.Count() end
---*Action*
function GameEvents.ScenarioCommand_UnitSacrifice.RemoveAll() end
---*Query*
function GameEvents.ScenarioCommand_UnitSacrifice.Accumulate() end
---*Query*
function GameEvents.ScenarioCommand_UnitSacrifice.AccumulateINT() end
---*Action*
function GameEvents.ScenarioCommand_UnitSacrifice.TestAny() end
---*Action*
function GameEvents.ScenarioCommand_UnitSacrifice.TestAll() end
---*Action*
function GameEvents.ScenarioCommand_UnitSacrifice.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.ScenarioCommand_UnitSacrifice.Add(func) end
---*Action*
---@param func function
function GameEvents.ScenarioCommand_UnitSacrifice.Remove(func) end

GameEvents.CanUseResolutions = {}
---*Query*
---@return number amount
function GameEvents.CanUseResolutions.Count() end
---*Action*
function GameEvents.CanUseResolutions.RemoveAll() end
---*Query*
function GameEvents.CanUseResolutions.Accumulate() end
---*Query*
function GameEvents.CanUseResolutions.AccumulateINT() end
---*Action*
function GameEvents.CanUseResolutions.TestAny() end
---*Action*
function GameEvents.CanUseResolutions.TestAll() end
---*Action*
function GameEvents.CanUseResolutions.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.CanUseResolutions.Add(func) end
---*Action*
---@param func function
function GameEvents.CanUseResolutions.Remove(func) end

GameEvents.CivRoyale_SmallSafeZone = {}
---*Query*
---@return number amount
function GameEvents.CivRoyale_SmallSafeZone.Count() end
---*Action*
function GameEvents.CivRoyale_SmallSafeZone.RemoveAll() end
---*Query*
function GameEvents.CivRoyale_SmallSafeZone.Accumulate() end
---*Query*
function GameEvents.CivRoyale_SmallSafeZone.AccumulateINT() end
---*Action*
function GameEvents.CivRoyale_SmallSafeZone.TestAny() end
---*Action*
function GameEvents.CivRoyale_SmallSafeZone.TestAll() end
---*Action*
function GameEvents.CivRoyale_SmallSafeZone.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.CivRoyale_SmallSafeZone.Add(func) end
---*Action*
---@param func function
function GameEvents.CivRoyale_SmallSafeZone.Remove(func) end

GameEvents.WC_Validate_MILITARY_ADVISORY = {}
---*Query*
---@return number amount
function GameEvents.WC_Validate_MILITARY_ADVISORY.Count() end
---*Action*
function GameEvents.WC_Validate_MILITARY_ADVISORY.RemoveAll() end
---*Query*
function GameEvents.WC_Validate_MILITARY_ADVISORY.Accumulate() end
---*Query*
function GameEvents.WC_Validate_MILITARY_ADVISORY.AccumulateINT() end
---*Action*
function GameEvents.WC_Validate_MILITARY_ADVISORY.TestAny() end
---*Action*
function GameEvents.WC_Validate_MILITARY_ADVISORY.TestAll() end
---*Action*
function GameEvents.WC_Validate_MILITARY_ADVISORY.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.WC_Validate_MILITARY_ADVISORY.Add(func) end
---*Action*
---@param func function
function GameEvents.WC_Validate_MILITARY_ADVISORY.Remove(func) end

GameEvents.TradeRoutePlundered = {}
---*Query*
---@return number amount
function GameEvents.TradeRoutePlundered.Count() end
---*Action*
function GameEvents.TradeRoutePlundered.RemoveAll() end
---*Query*
function GameEvents.TradeRoutePlundered.Accumulate() end
---*Query*
function GameEvents.TradeRoutePlundered.AccumulateINT() end
---*Action*
function GameEvents.TradeRoutePlundered.TestAny() end
---*Action*
function GameEvents.TradeRoutePlundered.TestAll() end
---*Action*
function GameEvents.TradeRoutePlundered.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.TradeRoutePlundered.Add(func) end
---*Action*
---@param func function
function GameEvents.TradeRoutePlundered.Remove(func) end

GameEvents.ScenarioCommand_BuryTreasure = {}
---*Query*
---@return number amount
function GameEvents.ScenarioCommand_BuryTreasure.Count() end
---*Action*
function GameEvents.ScenarioCommand_BuryTreasure.RemoveAll() end
---*Query*
function GameEvents.ScenarioCommand_BuryTreasure.Accumulate() end
---*Query*
function GameEvents.ScenarioCommand_BuryTreasure.AccumulateINT() end
---*Action*
function GameEvents.ScenarioCommand_BuryTreasure.TestAny() end
---*Action*
function GameEvents.ScenarioCommand_BuryTreasure.TestAll() end
---*Action*
function GameEvents.ScenarioCommand_BuryTreasure.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.ScenarioCommand_BuryTreasure.Add(func) end
---*Action*
---@param func function
function GameEvents.ScenarioCommand_BuryTreasure.Remove(func) end

GameEvents.OnCombatOccurred = {}
---*Query*
---@return number amount
function GameEvents.OnCombatOccurred.Count() end
---*Action*
function GameEvents.OnCombatOccurred.RemoveAll() end
---*Query*
function GameEvents.OnCombatOccurred.Accumulate() end
---*Query*
function GameEvents.OnCombatOccurred.AccumulateINT() end
---*Action*
function GameEvents.OnCombatOccurred.TestAny() end
---*Action*
function GameEvents.OnCombatOccurred.TestAll() end
---*Action*
function GameEvents.OnCombatOccurred.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.OnCombatOccurred.Add(func) end
---*Action*
---@param func function
function GameEvents.OnCombatOccurred.Remove(func) end

GameEvents.ScenarioCommand_VisitTavern = {}
---*Query*
---@return number amount
function GameEvents.ScenarioCommand_VisitTavern.Count() end
---*Action*
function GameEvents.ScenarioCommand_VisitTavern.RemoveAll() end
---*Query*
function GameEvents.ScenarioCommand_VisitTavern.Accumulate() end
---*Query*
function GameEvents.ScenarioCommand_VisitTavern.AccumulateINT() end
---*Action*
function GameEvents.ScenarioCommand_VisitTavern.TestAny() end
---*Action*
function GameEvents.ScenarioCommand_VisitTavern.TestAll() end
---*Action*
function GameEvents.ScenarioCommand_VisitTavern.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.ScenarioCommand_VisitTavern.Add(func) end
---*Action*
---@param func function
function GameEvents.ScenarioCommand_VisitTavern.Remove(func) end

GameEvents.WC_Validate_MigrationTreaty = {}
---*Query*
---@return number amount
function GameEvents.WC_Validate_MigrationTreaty.Count() end
---*Action*
function GameEvents.WC_Validate_MigrationTreaty.RemoveAll() end
---*Query*
function GameEvents.WC_Validate_MigrationTreaty.Accumulate() end
---*Query*
function GameEvents.WC_Validate_MigrationTreaty.AccumulateINT() end
---*Action*
function GameEvents.WC_Validate_MigrationTreaty.TestAny() end
---*Action*
function GameEvents.WC_Validate_MigrationTreaty.TestAll() end
---*Action*
function GameEvents.WC_Validate_MigrationTreaty.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.WC_Validate_MigrationTreaty.Add(func) end
---*Action*
---@param func function
function GameEvents.WC_Validate_MigrationTreaty.Remove(func) end

GameEvents.ScenarioCommand_CaptureBoat = {}
---*Query*
---@return number amount
function GameEvents.ScenarioCommand_CaptureBoat.Count() end
---*Action*
function GameEvents.ScenarioCommand_CaptureBoat.RemoveAll() end
---*Query*
function GameEvents.ScenarioCommand_CaptureBoat.Accumulate() end
---*Query*
function GameEvents.ScenarioCommand_CaptureBoat.AccumulateINT() end
---*Action*
function GameEvents.ScenarioCommand_CaptureBoat.TestAny() end
---*Action*
function GameEvents.ScenarioCommand_CaptureBoat.TestAll() end
---*Action*
function GameEvents.ScenarioCommand_CaptureBoat.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.ScenarioCommand_CaptureBoat.Add(func) end
---*Action*
---@param func function
function GameEvents.ScenarioCommand_CaptureBoat.Remove(func) end

GameEvents.WC_Validate_PolicyTreaty = {}
---*Query*
---@return number amount
function GameEvents.WC_Validate_PolicyTreaty.Count() end
---*Action*
function GameEvents.WC_Validate_PolicyTreaty.RemoveAll() end
---*Query*
function GameEvents.WC_Validate_PolicyTreaty.Accumulate() end
---*Query*
function GameEvents.WC_Validate_PolicyTreaty.AccumulateINT() end
---*Action*
function GameEvents.WC_Validate_PolicyTreaty.TestAny() end
---*Action*
function GameEvents.WC_Validate_PolicyTreaty.TestAll() end
---*Action*
function GameEvents.WC_Validate_PolicyTreaty.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.WC_Validate_PolicyTreaty.Add(func) end
---*Action*
---@param func function
function GameEvents.WC_Validate_PolicyTreaty.Remove(func) end

GameEvents.WC_Validate_Patronage = {}
---*Query*
---@return number amount
function GameEvents.WC_Validate_Patronage.Count() end
---*Action*
function GameEvents.WC_Validate_Patronage.RemoveAll() end
---*Query*
function GameEvents.WC_Validate_Patronage.Accumulate() end
---*Query*
function GameEvents.WC_Validate_Patronage.AccumulateINT() end
---*Action*
function GameEvents.WC_Validate_Patronage.TestAny() end
---*Action*
function GameEvents.WC_Validate_Patronage.TestAll() end
---*Action*
function GameEvents.WC_Validate_Patronage.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.WC_Validate_Patronage.Add(func) end
---*Action*
---@param func function
function GameEvents.WC_Validate_Patronage.Remove(func) end

GameEvents.ScenarioCommand_Pacify = {}
---*Query*
---@return number amount
function GameEvents.ScenarioCommand_Pacify.Count() end
---*Action*
function GameEvents.ScenarioCommand_Pacify.RemoveAll() end
---*Query*
function GameEvents.ScenarioCommand_Pacify.Accumulate() end
---*Query*
function GameEvents.ScenarioCommand_Pacify.AccumulateINT() end
---*Action*
function GameEvents.ScenarioCommand_Pacify.TestAny() end
---*Action*
function GameEvents.ScenarioCommand_Pacify.TestAll() end
---*Action*
function GameEvents.ScenarioCommand_Pacify.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.ScenarioCommand_Pacify.Add(func) end
---*Action*
---@param func function
function GameEvents.ScenarioCommand_Pacify.Remove(func) end

GameEvents.UnitTriggerGoodyHut = {}
---*Query*
---@return number amount
function GameEvents.UnitTriggerGoodyHut.Count() end
---*Action*
function GameEvents.UnitTriggerGoodyHut.RemoveAll() end
---*Query*
function GameEvents.UnitTriggerGoodyHut.Accumulate() end
---*Query*
function GameEvents.UnitTriggerGoodyHut.AccumulateINT() end
---*Action*
function GameEvents.UnitTriggerGoodyHut.TestAny() end
---*Action*
function GameEvents.UnitTriggerGoodyHut.TestAll() end
---*Action*
function GameEvents.UnitTriggerGoodyHut.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.UnitTriggerGoodyHut.Add(func) end
---*Action*
---@param func function
function GameEvents.UnitTriggerGoodyHut.Remove(func) end

GameEvents.ScenarioCommand_PrivateerActive = {}
---*Query*
---@return number amount
function GameEvents.ScenarioCommand_PrivateerActive.Count() end
---*Action*
function GameEvents.ScenarioCommand_PrivateerActive.RemoveAll() end
---*Query*
function GameEvents.ScenarioCommand_PrivateerActive.Accumulate() end
---*Query*
function GameEvents.ScenarioCommand_PrivateerActive.AccumulateINT() end
---*Action*
function GameEvents.ScenarioCommand_PrivateerActive.TestAny() end
---*Action*
function GameEvents.ScenarioCommand_PrivateerActive.TestAll() end
---*Action*
function GameEvents.ScenarioCommand_PrivateerActive.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.ScenarioCommand_PrivateerActive.Add(func) end
---*Action*
---@param func function
function GameEvents.ScenarioCommand_PrivateerActive.Remove(func) end

GameEvents.ScenarioCommand_SwashbucklerActive = {}
---*Query*
---@return number amount
function GameEvents.ScenarioCommand_SwashbucklerActive.Count() end
---*Action*
function GameEvents.ScenarioCommand_SwashbucklerActive.RemoveAll() end
---*Query*
function GameEvents.ScenarioCommand_SwashbucklerActive.Accumulate() end
---*Query*
function GameEvents.ScenarioCommand_SwashbucklerActive.AccumulateINT() end
---*Action*
function GameEvents.ScenarioCommand_SwashbucklerActive.TestAny() end
---*Action*
function GameEvents.ScenarioCommand_SwashbucklerActive.TestAll() end
---*Action*
function GameEvents.ScenarioCommand_SwashbucklerActive.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.ScenarioCommand_SwashbucklerActive.Add(func) end
---*Action*
---@param func function
function GameEvents.ScenarioCommand_SwashbucklerActive.Remove(func) end

GameEvents.ScenarioCommand_ShorePartyEmbark = {}
---*Query*
---@return number amount
function GameEvents.ScenarioCommand_ShorePartyEmbark.Count() end
---*Action*
function GameEvents.ScenarioCommand_ShorePartyEmbark.RemoveAll() end
---*Query*
function GameEvents.ScenarioCommand_ShorePartyEmbark.Accumulate() end
---*Query*
function GameEvents.ScenarioCommand_ShorePartyEmbark.AccumulateINT() end
---*Action*
function GameEvents.ScenarioCommand_ShorePartyEmbark.TestAny() end
---*Action*
function GameEvents.ScenarioCommand_ShorePartyEmbark.TestAll() end
---*Action*
function GameEvents.ScenarioCommand_ShorePartyEmbark.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.ScenarioCommand_ShorePartyEmbark.Add(func) end
---*Action*
---@param func function
function GameEvents.ScenarioCommand_ShorePartyEmbark.Remove(func) end

GameEvents.ScenarioCommand_GrievingGift = {}
---*Query*
---@return number amount
function GameEvents.ScenarioCommand_GrievingGift.Count() end
---*Action*
function GameEvents.ScenarioCommand_GrievingGift.RemoveAll() end
---*Query*
function GameEvents.ScenarioCommand_GrievingGift.Accumulate() end
---*Query*
function GameEvents.ScenarioCommand_GrievingGift.AccumulateINT() end
---*Action*
function GameEvents.ScenarioCommand_GrievingGift.TestAny() end
---*Action*
function GameEvents.ScenarioCommand_GrievingGift.TestAll() end
---*Action*
function GameEvents.ScenarioCommand_GrievingGift.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.ScenarioCommand_GrievingGift.Add(func) end
---*Action*
---@param func function
function GameEvents.ScenarioCommand_GrievingGift.Remove(func) end

GameEvents.WC_Validate_UrbanDevelopment = {}
---*Query*
---@return number amount
function GameEvents.WC_Validate_UrbanDevelopment.Count() end
---*Action*
function GameEvents.WC_Validate_UrbanDevelopment.RemoveAll() end
---*Query*
function GameEvents.WC_Validate_UrbanDevelopment.Accumulate() end
---*Query*
function GameEvents.WC_Validate_UrbanDevelopment.AccumulateINT() end
---*Action*
function GameEvents.WC_Validate_UrbanDevelopment.TestAny() end
---*Action*
function GameEvents.WC_Validate_UrbanDevelopment.TestAll() end
---*Action*
function GameEvents.WC_Validate_UrbanDevelopment.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.WC_Validate_UrbanDevelopment.Add(func) end
---*Action*
---@param func function
function GameEvents.WC_Validate_UrbanDevelopment.Remove(func) end

GameEvents.ScenarioCommand_DreadPirateActive = {}
---*Query*
---@return number amount
function GameEvents.ScenarioCommand_DreadPirateActive.Count() end
---*Action*
function GameEvents.ScenarioCommand_DreadPirateActive.RemoveAll() end
---*Query*
function GameEvents.ScenarioCommand_DreadPirateActive.Accumulate() end
---*Query*
function GameEvents.ScenarioCommand_DreadPirateActive.AccumulateINT() end
---*Action*
function GameEvents.ScenarioCommand_DreadPirateActive.TestAny() end
---*Action*
function GameEvents.ScenarioCommand_DreadPirateActive.TestAll() end
---*Action*
function GameEvents.ScenarioCommand_DreadPirateActive.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.ScenarioCommand_DreadPirateActive.Add(func) end
---*Action*
---@param func function
function GameEvents.ScenarioCommand_DreadPirateActive.Remove(func) end

GameEvents.WC_Validate_PowerBuilding = {}
---*Query*
---@return number amount
function GameEvents.WC_Validate_PowerBuilding.Count() end
---*Action*
function GameEvents.WC_Validate_PowerBuilding.RemoveAll() end
---*Query*
function GameEvents.WC_Validate_PowerBuilding.Accumulate() end
---*Query*
function GameEvents.WC_Validate_PowerBuilding.AccumulateINT() end
---*Action*
function GameEvents.WC_Validate_PowerBuilding.TestAny() end
---*Action*
function GameEvents.WC_Validate_PowerBuilding.TestAll() end
---*Action*
function GameEvents.WC_Validate_PowerBuilding.Call() end
---*Action*
---@param func fun()
---@return fun()
function GameEvents.WC_Validate_PowerBuilding.Add(func) end
---*Action*
---@param func function
function GameEvents.WC_Validate_PowerBuilding.Remove(func) end
