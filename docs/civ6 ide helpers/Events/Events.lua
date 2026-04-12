---@meta


Events = {}
---@overload fun(playerID: number, otherplayerID: number, allianceIndex: number)
Events.AllianceAvailable = {}
---*Query*
---@return number amount
function Events.AllianceAvailable.Count() end
---*Action*
function Events.AllianceAvailable.RemoveAll() end
---*Action*
function Events.AllianceAvailable.Dispatch() end
Events.AllianceAvailable = {}
---*Query*
---@return number amount
function Events.AllianceAvailable.Count() end
---*Action*
function Events.AllianceAvailable.RemoveAll() end
---*Action*
function Events.AllianceAvailable.Dispatch() end
---*Action*
---@param playerID number
---@param otherplayerID number
---@param allianceIndex number
function Events.AllianceAvailable.Call(playerID, otherplayerID, allianceIndex) end
---*Action*
---@param playerID number
---@param otherplayerID number
---@param allianceIndex number
function Events.AllianceAvailable.CallImmediate(playerID, otherplayerID, allianceIndex) end
---*Action*
---@param func fun(playerID: number, otherplayerID: number, allianceIndex: number)
---@return fun(playerID: number, otherplayerID: number, allianceIndex: number)
function Events.AllianceAvailable.Add(func) end
---*Action*
---@param func function
function Events.AllianceAvailable.Remove(func) end

---@overload fun(playerID: number, otherplayerID: number, allianceIndex: number)
Events.AllianceEnded = {}
---*Query*
---@return number amount
function Events.AllianceEnded.Count() end
---*Action*
function Events.AllianceEnded.RemoveAll() end
---*Action*
function Events.AllianceEnded.Dispatch() end
Events.AllianceEnded = {}
---*Query*
---@return number amount
function Events.AllianceEnded.Count() end
---*Action*
function Events.AllianceEnded.RemoveAll() end
---*Action*
function Events.AllianceEnded.Dispatch() end
---*Action*
---@param playerID number
---@param otherplayerID number
---@param allianceIndex number
function Events.AllianceEnded.Call(playerID, otherplayerID, allianceIndex) end
---*Action*
---@param playerID number
---@param otherplayerID number
---@param allianceIndex number
function Events.AllianceEnded.CallImmediate(playerID, otherplayerID, allianceIndex) end
---*Action*
---@param func fun(playerID: number, otherplayerID: number, allianceIndex: number)
---@return fun(playerID: number, otherplayerID: number, allianceIndex: number)
function Events.AllianceEnded.Add(func) end
---*Action*
---@param func function
function Events.AllianceEnded.Remove(func) end

---@overload fun()
Events.AnarchyBegins = {}
---*Query*
---@return number amount
function Events.AnarchyBegins.Count() end
---*Action*
function Events.AnarchyBegins.RemoveAll() end
---*Action*
function Events.AnarchyBegins.Dispatch() end
Events.AnarchyBegins = {}
---*Query*
---@return number amount
function Events.AnarchyBegins.Count() end
---*Action*
function Events.AnarchyBegins.RemoveAll() end
---*Action*
function Events.AnarchyBegins.Dispatch() end
---*Action*
function Events.AnarchyBegins.Call() end
---*Action*
function Events.AnarchyBegins.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.AnarchyBegins.Add(func) end
---*Action*
---@param func function
function Events.AnarchyBegins.Remove(func) end

---@overload fun()
Events.AnarchyEnds = {}
---*Query*
---@return number amount
function Events.AnarchyEnds.Count() end
---*Action*
function Events.AnarchyEnds.RemoveAll() end
---*Action*
function Events.AnarchyEnds.Dispatch() end
Events.AnarchyEnds = {}
---*Query*
---@return number amount
function Events.AnarchyEnds.Count() end
---*Action*
function Events.AnarchyEnds.RemoveAll() end
---*Action*
function Events.AnarchyEnds.Dispatch() end
---*Action*
function Events.AnarchyEnds.Call() end
---*Action*
function Events.AnarchyEnds.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.AnarchyEnds.Add(func) end
---*Action*
---@param func function
function Events.AnarchyEnds.Remove(func) end

---@overload fun()
Events.BarbarianRaidStarted = {}
---*Query*
---@return number amount
function Events.BarbarianRaidStarted.Count() end
---*Action*
function Events.BarbarianRaidStarted.RemoveAll() end
---*Action*
function Events.BarbarianRaidStarted.Dispatch() end
Events.BarbarianRaidStarted = {}
---*Query*
---@return number amount
function Events.BarbarianRaidStarted.Count() end
---*Action*
function Events.BarbarianRaidStarted.RemoveAll() end
---*Action*
function Events.BarbarianRaidStarted.Dispatch() end
---*Action*
function Events.BarbarianRaidStarted.Call() end
---*Action*
function Events.BarbarianRaidStarted.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.BarbarianRaidStarted.Add(func) end
---*Action*
---@param func function
function Events.BarbarianRaidStarted.Remove(func) end

---@overload fun(playerID: number, unitID: number, cityOwner: number, cityID: number)
Events.BarbarianSpottedCity = {}
---*Query*
---@return number amount
function Events.BarbarianSpottedCity.Count() end
---*Action*
function Events.BarbarianSpottedCity.RemoveAll() end
---*Action*
function Events.BarbarianSpottedCity.Dispatch() end
Events.BarbarianSpottedCity = {}
---*Query*
---@return number amount
function Events.BarbarianSpottedCity.Count() end
---*Action*
function Events.BarbarianSpottedCity.RemoveAll() end
---*Action*
function Events.BarbarianSpottedCity.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
---@param cityOwner number
---@param cityID number
function Events.BarbarianSpottedCity.Call(playerID, unitID, cityOwner, cityID) end
---*Action*
---@param playerID number
---@param unitID number
---@param cityOwner number
---@param cityID number
function Events.BarbarianSpottedCity.CallImmediate(playerID, unitID, cityOwner, cityID) end
---*Action*
---@param func fun(playerID: number, unitID: number, cityOwner: number, cityID: number)
---@return fun(playerID: number, unitID: number, cityOwner: number, cityID: number)
function Events.BarbarianSpottedCity.Add(func) end
---*Action*
---@param func function
function Events.BarbarianSpottedCity.Remove(func) end

---@overload fun()
Events.BeginWonderReveal = {}
---*Query*
---@return number amount
function Events.BeginWonderReveal.Count() end
---*Action*
function Events.BeginWonderReveal.RemoveAll() end
---*Action*
function Events.BeginWonderReveal.Dispatch() end
Events.BeginWonderReveal = {}
---*Query*
---@return number amount
function Events.BeginWonderReveal.Count() end
---*Action*
function Events.BeginWonderReveal.RemoveAll() end
---*Action*
function Events.BeginWonderReveal.Dispatch() end
---*Action*
function Events.BeginWonderReveal.Call() end
---*Action*
function Events.BeginWonderReveal.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.BeginWonderReveal.Add(func) end
---*Action*
---@param func function
function Events.BeginWonderReveal.Remove(func) end

---@overload fun(playerID: number, beliefID: number)
Events.BeliefAdded = {}
---*Query*
---@return number amount
function Events.BeliefAdded.Count() end
---*Action*
function Events.BeliefAdded.RemoveAll() end
---*Action*
function Events.BeliefAdded.Dispatch() end
Events.BeliefAdded = {}
---*Query*
---@return number amount
function Events.BeliefAdded.Count() end
---*Action*
function Events.BeliefAdded.RemoveAll() end
---*Action*
function Events.BeliefAdded.Dispatch() end
---*Action*
---@param playerID number
---@param beliefID number
function Events.BeliefAdded.Call(playerID, beliefID) end
---*Action*
---@param playerID number
---@param beliefID number
function Events.BeliefAdded.CallImmediate(playerID, beliefID) end
---*Action*
---@param func fun(playerID: number, beliefID: number)
---@return fun(playerID: number, beliefID: number)
function Events.BeliefAdded.Add(func) end
---*Action*
---@param func function
function Events.BeliefAdded.Remove(func) end

---@overload fun(X: number, Y: number, buildingID: number, playerID: number, misc2: any, misc3: any)
Events.BuildingAddedToMap = {}
---*Query*
---@return number amount
function Events.BuildingAddedToMap.Count() end
---*Action*
function Events.BuildingAddedToMap.RemoveAll() end
---*Action*
function Events.BuildingAddedToMap.Dispatch() end
Events.BuildingAddedToMap = {}
---*Query*
---@return number amount
function Events.BuildingAddedToMap.Count() end
---*Action*
function Events.BuildingAddedToMap.RemoveAll() end
---*Action*
function Events.BuildingAddedToMap.Dispatch() end
---*Action*
---@param X number
---@param Y number
---@param buildingID number
---@param playerID number
---@param misc2 any
---@param misc3 any
function Events.BuildingAddedToMap.Call(X, Y, buildingID, playerID, misc2, misc3) end
---*Action*
---@param X number
---@param Y number
---@param buildingID number
---@param playerID number
---@param misc2 any
---@param misc3 any
function Events.BuildingAddedToMap.CallImmediate(X, Y, buildingID, playerID, misc2, misc3) end
---*Action*
---@param func fun(X: number, Y: number, buildingID: number, playerID: number, misc2: any, misc3: any)
---@return fun(X: number, Y: number, buildingID: number, playerID: number, misc2: any, misc3: any)
function Events.BuildingAddedToMap.Add(func) end
---*Action*
---@param func function
function Events.BuildingAddedToMap.Remove(func) end

---@overload fun()
Events.BuildingBuildProgressChanged = {}
---*Query*
---@return number amount
function Events.BuildingBuildProgressChanged.Count() end
---*Action*
function Events.BuildingBuildProgressChanged.RemoveAll() end
---*Action*
function Events.BuildingBuildProgressChanged.Dispatch() end
Events.BuildingBuildProgressChanged = {}
---*Query*
---@return number amount
function Events.BuildingBuildProgressChanged.Count() end
---*Action*
function Events.BuildingBuildProgressChanged.RemoveAll() end
---*Action*
function Events.BuildingBuildProgressChanged.Dispatch() end
---*Action*
function Events.BuildingBuildProgressChanged.Call() end
---*Action*
function Events.BuildingBuildProgressChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.BuildingBuildProgressChanged.Add(func) end
---*Action*
---@param func function
function Events.BuildingBuildProgressChanged.Remove(func) end

---@overload fun(X: number, Y: number, buildingID: number, playerID: number, percentComplete: number, unknown: number)
Events.BuildingChanged = {}
---*Query*
---@return number amount
function Events.BuildingChanged.Count() end
---*Action*
function Events.BuildingChanged.RemoveAll() end
---*Action*
function Events.BuildingChanged.Dispatch() end
Events.BuildingChanged = {}
---*Query*
---@return number amount
function Events.BuildingChanged.Count() end
---*Action*
function Events.BuildingChanged.RemoveAll() end
---*Action*
function Events.BuildingChanged.Dispatch() end
---*Action*
---@param X number
---@param Y number
---@param buildingID number
---@param playerID number
---@param percentComplete number
---@param unknown number
function Events.BuildingChanged.Call(X, Y, buildingID, playerID, percentComplete, unknown) end
---*Action*
---@param X number
---@param Y number
---@param buildingID number
---@param playerID number
---@param percentComplete number
---@param unknown number
function Events.BuildingChanged.CallImmediate(X, Y, buildingID, playerID, percentComplete, unknown) end
---*Action*
---@param func fun(X: number, Y: number, buildingID: number, playerID: number, percentComplete: number, unknown: number)
---@return fun(X: number, Y: number, buildingID: number, playerID: number, percentComplete: number, unknown: number)
function Events.BuildingChanged.Add(func) end
---*Action*
---@param func function
function Events.BuildingChanged.Remove(func) end

---@overload fun()
Events.BuildingPillaged = {}
---*Query*
---@return number amount
function Events.BuildingPillaged.Count() end
---*Action*
function Events.BuildingPillaged.RemoveAll() end
---*Action*
function Events.BuildingPillaged.Dispatch() end
Events.BuildingPillaged = {}
---*Query*
---@return number amount
function Events.BuildingPillaged.Count() end
---*Action*
function Events.BuildingPillaged.RemoveAll() end
---*Action*
function Events.BuildingPillaged.Dispatch() end
---*Action*
function Events.BuildingPillaged.Call() end
---*Action*
function Events.BuildingPillaged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.BuildingPillaged.Add(func) end
---*Action*
---@param func function
function Events.BuildingPillaged.Remove(func) end

---@overload fun(X: number, Y: number)
Events.BuildingRemovedFromMap = {}
---*Query*
---@return number amount
function Events.BuildingRemovedFromMap.Count() end
---*Action*
function Events.BuildingRemovedFromMap.RemoveAll() end
---*Action*
function Events.BuildingRemovedFromMap.Dispatch() end
Events.BuildingRemovedFromMap = {}
---*Query*
---@return number amount
function Events.BuildingRemovedFromMap.Count() end
---*Action*
function Events.BuildingRemovedFromMap.RemoveAll() end
---*Action*
function Events.BuildingRemovedFromMap.Dispatch() end
---*Action*
---@param X number
---@param Y number
function Events.BuildingRemovedFromMap.Call(X, Y) end
---*Action*
---@param X number
---@param Y number
function Events.BuildingRemovedFromMap.CallImmediate(X, Y) end
---*Action*
---@param func fun(X: number, Y: number)
---@return fun(X: number, Y: number)
function Events.BuildingRemovedFromMap.Add(func) end
---*Action*
---@param func function
function Events.BuildingRemovedFromMap.Remove(func) end

---@overload fun()
Events.BuildingVisibilityChanged = {}
---*Query*
---@return number amount
function Events.BuildingVisibilityChanged.Count() end
---*Action*
function Events.BuildingVisibilityChanged.RemoveAll() end
---*Action*
function Events.BuildingVisibilityChanged.Dispatch() end
Events.BuildingVisibilityChanged = {}
---*Query*
---@return number amount
function Events.BuildingVisibilityChanged.Count() end
---*Action*
function Events.BuildingVisibilityChanged.RemoveAll() end
---*Action*
function Events.BuildingVisibilityChanged.Dispatch() end
---*Action*
function Events.BuildingVisibilityChanged.Call() end
---*Action*
function Events.BuildingVisibilityChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.BuildingVisibilityChanged.Add(func) end
---*Action*
---@param func function
function Events.BuildingVisibilityChanged.Remove(func) end

---@overload fun()
Events.CacheUpdate = {}
---*Query*
---@return number amount
function Events.CacheUpdate.Count() end
---*Action*
function Events.CacheUpdate.RemoveAll() end
---*Action*
function Events.CacheUpdate.Dispatch() end
Events.CacheUpdate = {}
---*Query*
---@return number amount
function Events.CacheUpdate.Count() end
---*Action*
function Events.CacheUpdate.RemoveAll() end
---*Action*
function Events.CacheUpdate.Dispatch() end
---*Action*
function Events.CacheUpdate.Call() end
---*Action*
function Events.CacheUpdate.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.CacheUpdate.Add(func) end
---*Action*
---@param func function
function Events.CacheUpdate.Remove(func) end

---@overload fun(vFocusX: number, vFocusY: number, fZoomLevel: number)
Events.CameraUpdated = {}
---*Query*
---@return number amount
function Events.CameraUpdated.Count() end
---*Action*
function Events.CameraUpdated.RemoveAll() end
---*Action*
function Events.CameraUpdated.Dispatch() end
Events.CameraUpdated = {}
---*Query*
---@return number amount
function Events.CameraUpdated.Count() end
---*Action*
function Events.CameraUpdated.RemoveAll() end
---*Action*
function Events.CameraUpdated.Dispatch() end
---*Action*
---@param vFocusX number
---@param vFocusY number
---@param fZoomLevel number
function Events.CameraUpdated.Call(vFocusX, vFocusY, fZoomLevel) end
---*Action*
---@param vFocusX number
---@param vFocusY number
---@param fZoomLevel number
function Events.CameraUpdated.CallImmediate(vFocusX, vFocusY, fZoomLevel) end
---*Action*
---@param func fun(vFocusX: number, vFocusY: number, fZoomLevel: number)
---@return fun(vFocusX: number, vFocusY: number, fZoomLevel: number)
function Events.CameraUpdated.Add(func) end
---*Action*
---@param func function
function Events.CameraUpdated.Remove(func) end

---@overload fun(playerID: number, cityID: number)
Events.CapitalCityChanged = {}
---*Query*
---@return number amount
function Events.CapitalCityChanged.Count() end
---*Action*
function Events.CapitalCityChanged.RemoveAll() end
---*Action*
function Events.CapitalCityChanged.Dispatch() end
Events.CapitalCityChanged = {}
---*Query*
---@return number amount
function Events.CapitalCityChanged.Count() end
---*Action*
function Events.CapitalCityChanged.RemoveAll() end
---*Action*
function Events.CapitalCityChanged.Dispatch() end
---*Action*
---@param playerID number
---@param cityID number
function Events.CapitalCityChanged.Call(playerID, cityID) end
---*Action*
---@param playerID number
---@param cityID number
function Events.CapitalCityChanged.CallImmediate(playerID, cityID) end
---*Action*
---@param func fun(playerID: number, cityID: number)
---@return fun(playerID: number, cityID: number)
function Events.CapitalCityChanged.Add(func) end
---*Action*
---@param func function
function Events.CapitalCityChanged.Remove(func) end

---@overload fun(playerID: number, cityID: number, X: number, Y: number)
Events.CityAddedToMap = {}
---*Query*
---@return number amount
function Events.CityAddedToMap.Count() end
---*Action*
function Events.CityAddedToMap.RemoveAll() end
---*Action*
function Events.CityAddedToMap.Dispatch() end
Events.CityAddedToMap = {}
---*Query*
---@return number amount
function Events.CityAddedToMap.Count() end
---*Action*
function Events.CityAddedToMap.RemoveAll() end
---*Action*
function Events.CityAddedToMap.Dispatch() end
---*Action*
---@param playerID number
---@param cityID number
---@param X number
---@param Y number
function Events.CityAddedToMap.Call(playerID, cityID, X, Y) end
---*Action*
---@param playerID number
---@param cityID number
---@param X number
---@param Y number
function Events.CityAddedToMap.CallImmediate(playerID, cityID, X, Y) end
---*Action*
---@param func fun(playerID: number, cityID: number, X: number, Y: number)
---@return fun(playerID: number, cityID: number, X: number, Y: number)
function Events.CityAddedToMap.Add(func) end
---*Action*
---@param func function
function Events.CityAddedToMap.Remove(func) end

---@overload fun()
Events.CityChanged = {}
---*Query*
---@return number amount
function Events.CityChanged.Count() end
---*Action*
function Events.CityChanged.RemoveAll() end
---*Action*
function Events.CityChanged.Dispatch() end
Events.CityChanged = {}
---*Query*
---@return number amount
function Events.CityChanged.Count() end
---*Action*
function Events.CityChanged.RemoveAll() end
---*Action*
function Events.CityChanged.Dispatch() end
---*Action*
function Events.CityChanged.Call() end
---*Action*
function Events.CityChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.CityChanged.Add(func) end
---*Action*
---@param func function
function Events.CityChanged.Remove(func) end

---@overload fun(cityOwnerID: number, cityID: number, districtOwnerID: number, districtID: number, commandType: CityCommandTypes, data1: number)
Events.CityCommandStarted = {}
---*Query*
---@return number amount
function Events.CityCommandStarted.Count() end
---*Action*
function Events.CityCommandStarted.RemoveAll() end
---*Action*
function Events.CityCommandStarted.Dispatch() end
Events.CityCommandStarted = {}
---*Query*
---@return number amount
function Events.CityCommandStarted.Count() end
---*Action*
function Events.CityCommandStarted.RemoveAll() end
---*Action*
function Events.CityCommandStarted.Dispatch() end
---*Action*
---@param cityOwnerID number
---@param cityID number
---@param districtOwnerID number
---@param districtID number
---@param commandType CityCommandTypes
---@param data1 number
function Events.CityCommandStarted.Call(cityOwnerID, cityID, districtOwnerID, districtID, commandType, data1) end
---*Action*
---@param cityOwnerID number
---@param cityID number
---@param districtOwnerID number
---@param districtID number
---@param commandType CityCommandTypes
---@param data1 number
function Events.CityCommandStarted.CallImmediate(cityOwnerID, cityID, districtOwnerID, districtID, commandType, data1) end
---*Action*
---@param func fun(cityOwnerID: number, cityID: number, districtOwnerID: number, districtID: number, commandType: CityCommandTypes, data1: number)
---@return fun(cityOwnerID: number, cityID: number, districtOwnerID: number, districtID: number, commandType: CityCommandTypes, data1: number)
function Events.CityCommandStarted.Add(func) end
---*Action*
---@param func function
function Events.CityCommandStarted.Remove(func) end

---@overload fun(playerID: number, value: number)
Events.CityDefenseStatusChanged = {}
---*Query*
---@return number amount
function Events.CityDefenseStatusChanged.Count() end
---*Action*
function Events.CityDefenseStatusChanged.RemoveAll() end
---*Action*
function Events.CityDefenseStatusChanged.Dispatch() end
Events.CityDefenseStatusChanged = {}
---*Query*
---@return number amount
function Events.CityDefenseStatusChanged.Count() end
---*Action*
function Events.CityDefenseStatusChanged.RemoveAll() end
---*Action*
function Events.CityDefenseStatusChanged.Dispatch() end
---*Action*
---@param playerID number
---@param value number
function Events.CityDefenseStatusChanged.Call(playerID, value) end
---*Action*
---@param playerID number
---@param value number
function Events.CityDefenseStatusChanged.CallImmediate(playerID, value) end
---*Action*
---@param func fun(playerID: number, value: number)
---@return fun(playerID: number, value: number)
function Events.CityDefenseStatusChanged.Add(func) end
---*Action*
---@param func function
function Events.CityDefenseStatusChanged.Remove(func) end

---@overload fun(playerID: number, cityID: number)
Events.CityFocusChanged = {}
---*Query*
---@return number amount
function Events.CityFocusChanged.Count() end
---*Action*
function Events.CityFocusChanged.RemoveAll() end
---*Action*
function Events.CityFocusChanged.Dispatch() end
Events.CityFocusChanged = {}
---*Query*
---@return number amount
function Events.CityFocusChanged.Count() end
---*Action*
function Events.CityFocusChanged.RemoveAll() end
---*Action*
function Events.CityFocusChanged.Dispatch() end
---*Action*
---@param playerID number
---@param cityID number
function Events.CityFocusChanged.Call(playerID, cityID) end
---*Action*
---@param playerID number
---@param cityID number
function Events.CityFocusChanged.CallImmediate(playerID, cityID) end
---*Action*
---@param func fun(playerID: number, cityID: number)
---@return fun(playerID: number, cityID: number)
function Events.CityFocusChanged.Add(func) end
---*Action*
---@param func function
function Events.CityFocusChanged.Remove(func) end

---@overload fun(playerID: number, cityID: number, X: number, Y: number)
Events.CityInitialized = {}
---*Query*
---@return number amount
function Events.CityInitialized.Count() end
---*Action*
function Events.CityInitialized.RemoveAll() end
---*Action*
function Events.CityInitialized.Dispatch() end
Events.CityInitialized = {}
---*Query*
---@return number amount
function Events.CityInitialized.Count() end
---*Action*
function Events.CityInitialized.RemoveAll() end
---*Action*
function Events.CityInitialized.Dispatch() end
---*Action*
---@param playerID number
---@param cityID number
---@param X number
---@param Y number
function Events.CityInitialized.Call(playerID, cityID, X, Y) end
---*Action*
---@param playerID number
---@param cityID number
---@param X number
---@param Y number
function Events.CityInitialized.CallImmediate(playerID, cityID, X, Y) end
---*Action*
---@param func fun(playerID: number, cityID: number, X: number, Y: number)
---@return fun(playerID: number, cityID: number, X: number, Y: number)
function Events.CityInitialized.Add(func) end
---*Action*
---@param func function
function Events.CityInitialized.Remove(func) end

---@overload fun(playerID: number, cityID: number)
Events.CityLiberated = {}
---*Query*
---@return number amount
function Events.CityLiberated.Count() end
---*Action*
function Events.CityLiberated.RemoveAll() end
---*Action*
function Events.CityLiberated.Dispatch() end
Events.CityLiberated = {}
---*Query*
---@return number amount
function Events.CityLiberated.Count() end
---*Action*
function Events.CityLiberated.RemoveAll() end
---*Action*
function Events.CityLiberated.Dispatch() end
---*Action*
---@param playerID number
---@param cityID number
function Events.CityLiberated.Call(playerID, cityID) end
---*Action*
---@param playerID number
---@param cityID number
function Events.CityLiberated.CallImmediate(playerID, cityID) end
---*Action*
---@param func fun(playerID: number, cityID: number)
---@return fun(playerID: number, cityID: number)
function Events.CityLiberated.Add(func) end
---*Action*
---@param func function
function Events.CityLiberated.Remove(func) end

---@overload fun(playerID: number, cityID: number)
Events.CityLoyaltyChanged = {}
---*Query*
---@return number amount
function Events.CityLoyaltyChanged.Count() end
---*Action*
function Events.CityLoyaltyChanged.RemoveAll() end
---*Action*
function Events.CityLoyaltyChanged.Dispatch() end
Events.CityLoyaltyChanged = {}
---*Query*
---@return number amount
function Events.CityLoyaltyChanged.Count() end
---*Action*
function Events.CityLoyaltyChanged.RemoveAll() end
---*Action*
function Events.CityLoyaltyChanged.Dispatch() end
---*Action*
---@param playerID number
---@param cityID number
function Events.CityLoyaltyChanged.Call(playerID, cityID) end
---*Action*
---@param playerID number
---@param cityID number
function Events.CityLoyaltyChanged.CallImmediate(playerID, cityID) end
---*Action*
---@param func fun(playerID: number, cityID: number)
---@return fun(playerID: number, cityID: number)
function Events.CityLoyaltyChanged.Add(func) end
---*Action*
---@param func function
function Events.CityLoyaltyChanged.Remove(func) end

---@overload fun(playerID: number, cityID: number, X: number, Y: number, eventSubType: EventSubTypes, purchasableItemIndex: number)
Events.CityMadePurchase = {}
---*Query*
---@return number amount
function Events.CityMadePurchase.Count() end
---*Action*
function Events.CityMadePurchase.RemoveAll() end
---*Action*
function Events.CityMadePurchase.Dispatch() end
Events.CityMadePurchase = {}
---*Query*
---@return number amount
function Events.CityMadePurchase.Count() end
---*Action*
function Events.CityMadePurchase.RemoveAll() end
---*Action*
function Events.CityMadePurchase.Dispatch() end
---*Action*
---@param playerID number
---@param cityID number
---@param X number
---@param Y number
---@param eventSubType EventSubTypes
---@param purchasableItemIndex number
function Events.CityMadePurchase.Call(playerID, cityID, X, Y, eventSubType, purchasableItemIndex) end
---*Action*
---@param playerID number
---@param cityID number
---@param X number
---@param Y number
---@param eventSubType EventSubTypes
---@param purchasableItemIndex number
function Events.CityMadePurchase.CallImmediate(playerID, cityID, X, Y, eventSubType, purchasableItemIndex) end
---*Action*
---@param func fun(playerID: number, cityID: number, X: number, Y: number, eventSubType: EventSubTypes, purchasableItemIndex: number)
---@return fun(playerID: number, cityID: number, X: number, Y: number, eventSubType: EventSubTypes, purchasableItemIndex: number)
function Events.CityMadePurchase.Add(func) end
---*Action*
---@param func function
function Events.CityMadePurchase.Remove(func) end

---@overload fun(playerID: number, cityID: number)
Events.CityNameChanged = {}
---*Query*
---@return number amount
function Events.CityNameChanged.Count() end
---*Action*
function Events.CityNameChanged.RemoveAll() end
---*Action*
function Events.CityNameChanged.Dispatch() end
Events.CityNameChanged = {}
---*Query*
---@return number amount
function Events.CityNameChanged.Count() end
---*Action*
function Events.CityNameChanged.RemoveAll() end
---*Action*
function Events.CityNameChanged.Dispatch() end
---*Action*
---@param playerID number
---@param cityID number
function Events.CityNameChanged.Call(playerID, cityID) end
---*Action*
---@param playerID number
---@param cityID number
function Events.CityNameChanged.CallImmediate(playerID, cityID) end
---*Action*
---@param func fun(playerID: number, cityID: number)
---@return fun(playerID: number, cityID: number)
function Events.CityNameChanged.Add(func) end
---*Action*
---@param func function
function Events.CityNameChanged.Remove(func) end

---@overload fun(playerID: number, cityID: number)
Events.CityOccupationChanged = {}
---*Query*
---@return number amount
function Events.CityOccupationChanged.Count() end
---*Action*
function Events.CityOccupationChanged.RemoveAll() end
---*Action*
function Events.CityOccupationChanged.Dispatch() end
Events.CityOccupationChanged = {}
---*Query*
---@return number amount
function Events.CityOccupationChanged.Count() end
---*Action*
function Events.CityOccupationChanged.RemoveAll() end
---*Action*
function Events.CityOccupationChanged.Dispatch() end
---*Action*
---@param playerID number
---@param cityID number
function Events.CityOccupationChanged.Call(playerID, cityID) end
---*Action*
---@param playerID number
---@param cityID number
function Events.CityOccupationChanged.CallImmediate(playerID, cityID) end
---*Action*
---@param func fun(playerID: number, cityID: number)
---@return fun(playerID: number, cityID: number)
function Events.CityOccupationChanged.Add(func) end
---*Action*
---@param func function
function Events.CityOccupationChanged.Remove(func) end

---@overload fun(playerID: number, cityID: number, cityPopulation: number)
Events.CityPopulationChanged = {}
---*Query*
---@return number amount
function Events.CityPopulationChanged.Count() end
---*Action*
function Events.CityPopulationChanged.RemoveAll() end
---*Action*
function Events.CityPopulationChanged.Dispatch() end
Events.CityPopulationChanged = {}
---*Query*
---@return number amount
function Events.CityPopulationChanged.Count() end
---*Action*
function Events.CityPopulationChanged.RemoveAll() end
---*Action*
function Events.CityPopulationChanged.Dispatch() end
---*Action*
---@param playerID number
---@param cityID number
---@param cityPopulation number
function Events.CityPopulationChanged.Call(playerID, cityID, cityPopulation) end
---*Action*
---@param playerID number
---@param cityID number
---@param cityPopulation number
function Events.CityPopulationChanged.CallImmediate(playerID, cityID, cityPopulation) end
---*Action*
---@param func fun(playerID: number, cityID: number, cityPopulation: number)
---@return fun(playerID: number, cityID: number, cityPopulation: number)
function Events.CityPopulationChanged.Add(func) end
---*Action*
---@param func function
function Events.CityPopulationChanged.Remove(func) end

---@overload fun(playerID: number, cityID: number, productionID: number, objectID: number, wasCancelled: boolean)
Events.CityProductionChanged = {}
---*Query*
---@return number amount
function Events.CityProductionChanged.Count() end
---*Action*
function Events.CityProductionChanged.RemoveAll() end
---*Action*
function Events.CityProductionChanged.Dispatch() end
Events.CityProductionChanged = {}
---*Query*
---@return number amount
function Events.CityProductionChanged.Count() end
---*Action*
function Events.CityProductionChanged.RemoveAll() end
---*Action*
function Events.CityProductionChanged.Dispatch() end
---*Action*
---@param playerID number
---@param cityID number
---@param productionID number
---@param objectID number
---@param wasCancelled boolean
function Events.CityProductionChanged.Call(playerID, cityID, productionID, objectID, wasCancelled) end
---*Action*
---@param playerID number
---@param cityID number
---@param productionID number
---@param objectID number
---@param wasCancelled boolean
function Events.CityProductionChanged.CallImmediate(playerID, cityID, productionID, objectID, wasCancelled) end
---*Action*
---@param func fun(playerID: number, cityID: number, productionID: number, objectID: number, wasCancelled: boolean)
---@return fun(playerID: number, cityID: number, productionID: number, objectID: number, wasCancelled: boolean)
function Events.CityProductionChanged.Add(func) end
---*Action*
---@param func function
function Events.CityProductionChanged.Remove(func) end

---@overload fun(playerID: number, cityID: number, constructionType: number, unitID: number, wasCancelled: any)
Events.CityProductionCompleted = {}
---*Query*
---@return number amount
function Events.CityProductionCompleted.Count() end
---*Action*
function Events.CityProductionCompleted.RemoveAll() end
---*Action*
function Events.CityProductionCompleted.Dispatch() end
Events.CityProductionCompleted = {}
---*Query*
---@return number amount
function Events.CityProductionCompleted.Count() end
---*Action*
function Events.CityProductionCompleted.RemoveAll() end
---*Action*
function Events.CityProductionCompleted.Dispatch() end
---*Action*
---@param playerID number
---@param cityID number
---@param constructionType number
---@param unitID number
---@param wasCancelled any
function Events.CityProductionCompleted.Call(playerID, cityID, constructionType, unitID, wasCancelled) end
---*Action*
---@param playerID number
---@param cityID number
---@param constructionType number
---@param unitID number
---@param wasCancelled any
function Events.CityProductionCompleted.CallImmediate(playerID, cityID, constructionType, unitID, wasCancelled) end
---*Action*
---@param func fun(playerID: number, cityID: number, constructionType: number, unitID: number, wasCancelled: any)
---@return fun(playerID: number, cityID: number, constructionType: number, unitID: number, wasCancelled: any)
function Events.CityProductionCompleted.Add(func) end
---*Action*
---@param func function
function Events.CityProductionCompleted.Remove(func) end

---@overload fun(playerID: number, cityID: number, objectID: number, productionID: number)
Events.CityProductionUpdated = {}
---*Query*
---@return number amount
function Events.CityProductionUpdated.Count() end
---*Action*
function Events.CityProductionUpdated.RemoveAll() end
---*Action*
function Events.CityProductionUpdated.Dispatch() end
Events.CityProductionUpdated = {}
---*Query*
---@return number amount
function Events.CityProductionUpdated.Count() end
---*Action*
function Events.CityProductionUpdated.RemoveAll() end
---*Action*
function Events.CityProductionUpdated.Dispatch() end
---*Action*
---@param playerID number
---@param cityID number
---@param objectID number
---@param productionID number
function Events.CityProductionUpdated.Call(playerID, cityID, objectID, productionID) end
---*Action*
---@param playerID number
---@param cityID number
---@param objectID number
---@param productionID number
function Events.CityProductionUpdated.CallImmediate(playerID, cityID, objectID, productionID) end
---*Action*
---@param func fun(playerID: number, cityID: number, objectID: number, productionID: number)
---@return fun(playerID: number, cityID: number, objectID: number, productionID: number)
function Events.CityProductionUpdated.Add(func) end
---*Action*
---@param func function
function Events.CityProductionUpdated.Remove(func) end

---@overload fun(playerID: number, cityID: number, projectID: number, buildingIndex: number, X: number, Y: number, isCancelled: any)
Events.CityProjectCompleted = {}
---*Query*
---@return number amount
function Events.CityProjectCompleted.Count() end
---*Action*
function Events.CityProjectCompleted.RemoveAll() end
---*Action*
function Events.CityProjectCompleted.Dispatch() end
Events.CityProjectCompleted = {}
---*Query*
---@return number amount
function Events.CityProjectCompleted.Count() end
---*Action*
function Events.CityProjectCompleted.RemoveAll() end
---*Action*
function Events.CityProjectCompleted.Dispatch() end
---*Action*
---@param playerID number
---@param cityID number
---@param projectID number
---@param buildingIndex number
---@param X number
---@param Y number
---@param isCancelled any
function Events.CityProjectCompleted.Call(playerID, cityID, projectID, buildingIndex, X, Y, isCancelled) end
---*Action*
---@param playerID number
---@param cityID number
---@param projectID number
---@param buildingIndex number
---@param X number
---@param Y number
---@param isCancelled any
function Events.CityProjectCompleted.CallImmediate(playerID, cityID, projectID, buildingIndex, X, Y, isCancelled) end
---*Action*
---@param func fun(playerID: number, cityID: number, projectID: number, buildingIndex: number, X: number, Y: number, isCancelled: any)
---@return fun(playerID: number, cityID: number, projectID: number, buildingIndex: number, X: number, Y: number, isCancelled: any)
function Events.CityProjectCompleted.Add(func) end
---*Action*
---@param func function
function Events.CityProjectCompleted.Remove(func) end

---@overload fun(playerID: number, cityID: number, eVisibility: number, otherCityID: number)
Events.CityReligionChanged = {}
---*Query*
---@return number amount
function Events.CityReligionChanged.Count() end
---*Action*
function Events.CityReligionChanged.RemoveAll() end
---*Action*
function Events.CityReligionChanged.Dispatch() end
Events.CityReligionChanged = {}
---*Query*
---@return number amount
function Events.CityReligionChanged.Count() end
---*Action*
function Events.CityReligionChanged.RemoveAll() end
---*Action*
function Events.CityReligionChanged.Dispatch() end
---*Action*
---@param playerID number
---@param cityID number
---@param eVisibility number
---@param otherCityID number
function Events.CityReligionChanged.Call(playerID, cityID, eVisibility, otherCityID) end
---*Action*
---@param playerID number
---@param cityID number
---@param eVisibility number
---@param otherCityID number
function Events.CityReligionChanged.CallImmediate(playerID, cityID, eVisibility, otherCityID) end
---*Action*
---@param func fun(playerID: number, cityID: number, eVisibility: number, otherCityID: number)
---@return fun(playerID: number, cityID: number, eVisibility: number, otherCityID: number)
function Events.CityReligionChanged.Add(func) end
---*Action*
---@param func function
function Events.CityReligionChanged.Remove(func) end

---@overload fun(playerID: number, cityID: number, eVisibility: number, influencingCItyID: number)
Events.CityReligionFollowersChanged = {}
---*Query*
---@return number amount
function Events.CityReligionFollowersChanged.Count() end
---*Action*
function Events.CityReligionFollowersChanged.RemoveAll() end
---*Action*
function Events.CityReligionFollowersChanged.Dispatch() end
Events.CityReligionFollowersChanged = {}
---*Query*
---@return number amount
function Events.CityReligionFollowersChanged.Count() end
---*Action*
function Events.CityReligionFollowersChanged.RemoveAll() end
---*Action*
function Events.CityReligionFollowersChanged.Dispatch() end
---*Action*
---@param playerID number
---@param cityID number
---@param eVisibility number
---@param influencingCItyID number
function Events.CityReligionFollowersChanged.Call(playerID, cityID, eVisibility, influencingCItyID) end
---*Action*
---@param playerID number
---@param cityID number
---@param eVisibility number
---@param influencingCItyID number
function Events.CityReligionFollowersChanged.CallImmediate(playerID, cityID, eVisibility, influencingCItyID) end
---*Action*
---@param func fun(playerID: number, cityID: number, eVisibility: number, influencingCItyID: number)
---@return fun(playerID: number, cityID: number, eVisibility: number, influencingCItyID: number)
function Events.CityReligionFollowersChanged.Add(func) end
---*Action*
---@param func function
function Events.CityReligionFollowersChanged.Remove(func) end

---@overload fun(playerID: number, cityID: number)
Events.CityRemovedFromMap = {}
---*Query*
---@return number amount
function Events.CityRemovedFromMap.Count() end
---*Action*
function Events.CityRemovedFromMap.RemoveAll() end
---*Action*
function Events.CityRemovedFromMap.Dispatch() end
Events.CityRemovedFromMap = {}
---*Query*
---@return number amount
function Events.CityRemovedFromMap.Count() end
---*Action*
function Events.CityRemovedFromMap.RemoveAll() end
---*Action*
function Events.CityRemovedFromMap.Dispatch() end
---*Action*
---@param playerID number
---@param cityID number
function Events.CityRemovedFromMap.Call(playerID, cityID) end
---*Action*
---@param playerID number
---@param cityID number
function Events.CityRemovedFromMap.CallImmediate(playerID, cityID) end
---*Action*
---@param func fun(playerID: number, cityID: number)
---@return fun(playerID: number, cityID: number)
function Events.CityRemovedFromMap.Add(func) end
---*Action*
---@param func function
function Events.CityRemovedFromMap.Remove(func) end

---@overload fun(playerID: number, cityID: number, isBesieged: boolean)
Events.CitySiegeStatusChanged = {}
---*Query*
---@return number amount
function Events.CitySiegeStatusChanged.Count() end
---*Action*
function Events.CitySiegeStatusChanged.RemoveAll() end
---*Action*
function Events.CitySiegeStatusChanged.Dispatch() end
Events.CitySiegeStatusChanged = {}
---*Query*
---@return number amount
function Events.CitySiegeStatusChanged.Count() end
---*Action*
function Events.CitySiegeStatusChanged.RemoveAll() end
---*Action*
function Events.CitySiegeStatusChanged.Dispatch() end
---*Action*
---@param playerID number
---@param cityID number
---@param isBesieged boolean
function Events.CitySiegeStatusChanged.Call(playerID, cityID, isBesieged) end
---*Action*
---@param playerID number
---@param cityID number
---@param isBesieged boolean
function Events.CitySiegeStatusChanged.CallImmediate(playerID, cityID, isBesieged) end
---*Action*
---@param func fun(playerID: number, cityID: number, isBesieged: boolean)
---@return fun(playerID: number, cityID: number, isBesieged: boolean)
function Events.CitySiegeStatusChanged.Add(func) end
---*Action*
---@param func function
function Events.CitySiegeStatusChanged.Remove(func) end

---@overload fun(ownerID: number, cityID: number)
Events.CityTileOwnershipChanged = {}
---*Query*
---@return number amount
function Events.CityTileOwnershipChanged.Count() end
---*Action*
function Events.CityTileOwnershipChanged.RemoveAll() end
---*Action*
function Events.CityTileOwnershipChanged.Dispatch() end
Events.CityTileOwnershipChanged = {}
---*Query*
---@return number amount
function Events.CityTileOwnershipChanged.Count() end
---*Action*
function Events.CityTileOwnershipChanged.RemoveAll() end
---*Action*
function Events.CityTileOwnershipChanged.Dispatch() end
---*Action*
---@param ownerID number
---@param cityID number
function Events.CityTileOwnershipChanged.Call(ownerID, cityID) end
---*Action*
---@param ownerID number
---@param cityID number
function Events.CityTileOwnershipChanged.CallImmediate(ownerID, cityID) end
---*Action*
---@param func fun(ownerID: number, cityID: number)
---@return fun(ownerID: number, cityID: number)
function Events.CityTileOwnershipChanged.Add(func) end
---*Action*
---@param func function
function Events.CityTileOwnershipChanged.Remove(func) end

---@overload fun(playerID: number, cityID: number)
Events.CityTransfered = {}
---*Query*
---@return number amount
function Events.CityTransfered.Count() end
---*Action*
function Events.CityTransfered.RemoveAll() end
---*Action*
function Events.CityTransfered.Dispatch() end
Events.CityTransfered = {}
---*Query*
---@return number amount
function Events.CityTransfered.Count() end
---*Action*
function Events.CityTransfered.RemoveAll() end
---*Action*
function Events.CityTransfered.Dispatch() end
---*Action*
---@param playerID number
---@param cityID number
function Events.CityTransfered.Call(playerID, cityID) end
---*Action*
---@param playerID number
---@param cityID number
function Events.CityTransfered.CallImmediate(playerID, cityID) end
---*Action*
---@param func fun(playerID: number, cityID: number)
---@return fun(playerID: number, cityID: number)
function Events.CityTransfered.Add(func) end
---*Action*
---@param func function
function Events.CityTransfered.Remove(func) end

---@overload fun(playerID: number, cityID: number)
Events.CityUnitsChanged = {}
---*Query*
---@return number amount
function Events.CityUnitsChanged.Count() end
---*Action*
function Events.CityUnitsChanged.RemoveAll() end
---*Action*
function Events.CityUnitsChanged.Dispatch() end
Events.CityUnitsChanged = {}
---*Query*
---@return number amount
function Events.CityUnitsChanged.Count() end
---*Action*
function Events.CityUnitsChanged.RemoveAll() end
---*Action*
function Events.CityUnitsChanged.Dispatch() end
---*Action*
---@param playerID number
---@param cityID number
function Events.CityUnitsChanged.Call(playerID, cityID) end
---*Action*
---@param playerID number
---@param cityID number
function Events.CityUnitsChanged.CallImmediate(playerID, cityID) end
---*Action*
---@param func fun(playerID: number, cityID: number)
---@return fun(playerID: number, cityID: number)
function Events.CityUnitsChanged.Add(func) end
---*Action*
---@param func function
function Events.CityUnitsChanged.Remove(func) end

---@overload fun(playerID: number, cityID: number, eVisibility: number)
Events.CityVisibilityChanged = {}
---*Query*
---@return number amount
function Events.CityVisibilityChanged.Count() end
---*Action*
function Events.CityVisibilityChanged.RemoveAll() end
---*Action*
function Events.CityVisibilityChanged.Dispatch() end
Events.CityVisibilityChanged = {}
---*Query*
---@return number amount
function Events.CityVisibilityChanged.Count() end
---*Action*
function Events.CityVisibilityChanged.RemoveAll() end
---*Action*
function Events.CityVisibilityChanged.Dispatch() end
---*Action*
---@param playerID number
---@param cityID number
---@param eVisibility number
function Events.CityVisibilityChanged.Call(playerID, cityID, eVisibility) end
---*Action*
---@param playerID number
---@param cityID number
---@param eVisibility number
function Events.CityVisibilityChanged.CallImmediate(playerID, cityID, eVisibility) end
---*Action*
---@param func fun(playerID: number, cityID: number, eVisibility: number)
---@return fun(playerID: number, cityID: number, eVisibility: number)
function Events.CityVisibilityChanged.Add(func) end
---*Action*
---@param func function
function Events.CityVisibilityChanged.Remove(func) end

---@overload fun(ownerPlayerID: number, cityID: number, X: number, Y: number)
Events.CityWorkerChanged = {}
---*Query*
---@return number amount
function Events.CityWorkerChanged.Count() end
---*Action*
function Events.CityWorkerChanged.RemoveAll() end
---*Action*
function Events.CityWorkerChanged.Dispatch() end
Events.CityWorkerChanged = {}
---*Query*
---@return number amount
function Events.CityWorkerChanged.Count() end
---*Action*
function Events.CityWorkerChanged.RemoveAll() end
---*Action*
function Events.CityWorkerChanged.Dispatch() end
---*Action*
---@param ownerPlayerID number
---@param cityID number
---@param X number
---@param Y number
function Events.CityWorkerChanged.Call(ownerPlayerID, cityID, X, Y) end
---*Action*
---@param ownerPlayerID number
---@param cityID number
---@param X number
---@param Y number
function Events.CityWorkerChanged.CallImmediate(ownerPlayerID, cityID, X, Y) end
---*Action*
---@param func fun(ownerPlayerID: number, cityID: number, X: number, Y: number)
---@return fun(ownerPlayerID: number, cityID: number, X: number, Y: number)
function Events.CityWorkerChanged.Add(func) end
---*Action*
---@param func function
function Events.CityWorkerChanged.Remove(func) end

---@overload fun(playerID: number, civicIndex: number, unknownA: number, unknownB: number)
Events.CivicBoostTriggered = {}
---*Query*
---@return number amount
function Events.CivicBoostTriggered.Count() end
---*Action*
function Events.CivicBoostTriggered.RemoveAll() end
---*Action*
function Events.CivicBoostTriggered.Dispatch() end
Events.CivicBoostTriggered = {}
---*Query*
---@return number amount
function Events.CivicBoostTriggered.Count() end
---*Action*
function Events.CivicBoostTriggered.RemoveAll() end
---*Action*
function Events.CivicBoostTriggered.Dispatch() end
---*Action*
---@param playerID number
---@param civicIndex number
---@param unknownA number
---@param unknownB number
function Events.CivicBoostTriggered.Call(playerID, civicIndex, unknownA, unknownB) end
---*Action*
---@param playerID number
---@param civicIndex number
---@param unknownA number
---@param unknownB number
function Events.CivicBoostTriggered.CallImmediate(playerID, civicIndex, unknownA, unknownB) end
---*Action*
---@param func fun(playerID: number, civicIndex: number, unknownA: number, unknownB: number)
---@return fun(playerID: number, civicIndex: number, unknownA: number, unknownB: number)
function Events.CivicBoostTriggered.Add(func) end
---*Action*
---@param func function
function Events.CivicBoostTriggered.Remove(func) end

---@overload fun(playerID: number, civicIndex: number)
Events.CivicChanged = {}
---*Query*
---@return number amount
function Events.CivicChanged.Count() end
---*Action*
function Events.CivicChanged.RemoveAll() end
---*Action*
function Events.CivicChanged.Dispatch() end
Events.CivicChanged = {}
---*Query*
---@return number amount
function Events.CivicChanged.Count() end
---*Action*
function Events.CivicChanged.RemoveAll() end
---*Action*
function Events.CivicChanged.Dispatch() end
---*Action*
---@param playerID number
---@param civicIndex number
function Events.CivicChanged.Call(playerID, civicIndex) end
---*Action*
---@param playerID number
---@param civicIndex number
function Events.CivicChanged.CallImmediate(playerID, civicIndex) end
---*Action*
---@param func fun(playerID: number, civicIndex: number)
---@return fun(playerID: number, civicIndex: number)
function Events.CivicChanged.Add(func) end
---*Action*
---@param func function
function Events.CivicChanged.Remove(func) end

---@overload fun(playerID: number, civicIndex: number, isCancelled: number)
Events.CivicCompleted = {}
---*Query*
---@return number amount
function Events.CivicCompleted.Count() end
---*Action*
function Events.CivicCompleted.RemoveAll() end
---*Action*
function Events.CivicCompleted.Dispatch() end
Events.CivicCompleted = {}
---*Query*
---@return number amount
function Events.CivicCompleted.Count() end
---*Action*
function Events.CivicCompleted.RemoveAll() end
---*Action*
function Events.CivicCompleted.Dispatch() end
---*Action*
---@param playerID number
---@param civicIndex number
---@param isCancelled number
function Events.CivicCompleted.Call(playerID, civicIndex, isCancelled) end
---*Action*
---@param playerID number
---@param civicIndex number
---@param isCancelled number
function Events.CivicCompleted.CallImmediate(playerID, civicIndex, isCancelled) end
---*Action*
---@param func fun(playerID: number, civicIndex: number, isCancelled: number)
---@return fun(playerID: number, civicIndex: number, isCancelled: number)
function Events.CivicCompleted.Add(func) end
---*Action*
---@param func function
function Events.CivicCompleted.Remove(func) end

---@overload fun()
Events.CivicQueueChanged = {}
---*Query*
---@return number amount
function Events.CivicQueueChanged.Count() end
---*Action*
function Events.CivicQueueChanged.RemoveAll() end
---*Action*
function Events.CivicQueueChanged.Dispatch() end
Events.CivicQueueChanged = {}
---*Query*
---@return number amount
function Events.CivicQueueChanged.Count() end
---*Action*
function Events.CivicQueueChanged.RemoveAll() end
---*Action*
function Events.CivicQueueChanged.Dispatch() end
---*Action*
function Events.CivicQueueChanged.Call() end
---*Action*
function Events.CivicQueueChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.CivicQueueChanged.Add(func) end
---*Action*
---@param func function
function Events.CivicQueueChanged.Remove(func) end

---@overload fun()
Events.CivicsUnlocked = {}
---*Query*
---@return number amount
function Events.CivicsUnlocked.Count() end
---*Action*
function Events.CivicsUnlocked.RemoveAll() end
---*Action*
function Events.CivicsUnlocked.Dispatch() end
Events.CivicsUnlocked = {}
---*Query*
---@return number amount
function Events.CivicsUnlocked.Count() end
---*Action*
function Events.CivicsUnlocked.RemoveAll() end
---*Action*
function Events.CivicsUnlocked.Dispatch() end
---*Action*
function Events.CivicsUnlocked.Call() end
---*Action*
function Events.CivicsUnlocked.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.CivicsUnlocked.Add(func) end
---*Action*
---@param func function
function Events.CivicsUnlocked.Remove(func) end

---@overload fun()
Events.CliffAddedToMap = {}
---*Query*
---@return number amount
function Events.CliffAddedToMap.Count() end
---*Action*
function Events.CliffAddedToMap.RemoveAll() end
---*Action*
function Events.CliffAddedToMap.Dispatch() end
Events.CliffAddedToMap = {}
---*Query*
---@return number amount
function Events.CliffAddedToMap.Count() end
---*Action*
function Events.CliffAddedToMap.RemoveAll() end
---*Action*
function Events.CliffAddedToMap.Dispatch() end
---*Action*
function Events.CliffAddedToMap.Call() end
---*Action*
function Events.CliffAddedToMap.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.CliffAddedToMap.Add(func) end
---*Action*
---@param func function
function Events.CliffAddedToMap.Remove(func) end

---@overload fun()
Events.CliffRemovedFromMap = {}
---*Query*
---@return number amount
function Events.CliffRemovedFromMap.Count() end
---*Action*
function Events.CliffRemovedFromMap.RemoveAll() end
---*Action*
function Events.CliffRemovedFromMap.Dispatch() end
Events.CliffRemovedFromMap = {}
---*Query*
---@return number amount
function Events.CliffRemovedFromMap.Count() end
---*Action*
function Events.CliffRemovedFromMap.RemoveAll() end
---*Action*
function Events.CliffRemovedFromMap.Dispatch() end
---*Action*
function Events.CliffRemovedFromMap.Call() end
---*Action*
function Events.CliffRemovedFromMap.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.CliffRemovedFromMap.Add(func) end
---*Action*
---@param func function
function Events.CliffRemovedFromMap.Remove(func) end

---@overload fun(combatResult: table)
Events.Combat = {}
---*Query*
---@return number amount
function Events.Combat.Count() end
---*Action*
function Events.Combat.RemoveAll() end
---*Action*
function Events.Combat.Dispatch() end
Events.Combat = {}
---*Query*
---@return number amount
function Events.Combat.Count() end
---*Action*
function Events.Combat.RemoveAll() end
---*Action*
function Events.Combat.Dispatch() end
---*Action*
---@param combatResult table
function Events.Combat.Call(combatResult) end
---*Action*
---@param combatResult table
function Events.Combat.CallImmediate(combatResult) end
---*Action*
---@param func fun(combatResult: table)
---@return fun(combatResult: table)
function Events.Combat.Add(func) end
---*Action*
---@param func function
function Events.Combat.Remove(func) end

---@overload fun()
Events.CulturalIdentityCitizenConverted = {}
---*Query*
---@return number amount
function Events.CulturalIdentityCitizenConverted.Count() end
---*Action*
function Events.CulturalIdentityCitizenConverted.RemoveAll() end
---*Action*
function Events.CulturalIdentityCitizenConverted.Dispatch() end
Events.CulturalIdentityCitizenConverted = {}
---*Query*
---@return number amount
function Events.CulturalIdentityCitizenConverted.Count() end
---*Action*
function Events.CulturalIdentityCitizenConverted.RemoveAll() end
---*Action*
function Events.CulturalIdentityCitizenConverted.Dispatch() end
---*Action*
function Events.CulturalIdentityCitizenConverted.Call() end
---*Action*
function Events.CulturalIdentityCitizenConverted.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.CulturalIdentityCitizenConverted.Add(func) end
---*Action*
---@param func function
function Events.CulturalIdentityCitizenConverted.Remove(func) end

---@overload fun(playerID: number, cityID: number, influencingPlayerID: number)
Events.CulturalIdentityCityConverted = {}
---*Query*
---@return number amount
function Events.CulturalIdentityCityConverted.Count() end
---*Action*
function Events.CulturalIdentityCityConverted.RemoveAll() end
---*Action*
function Events.CulturalIdentityCityConverted.Dispatch() end
Events.CulturalIdentityCityConverted = {}
---*Query*
---@return number amount
function Events.CulturalIdentityCityConverted.Count() end
---*Action*
function Events.CulturalIdentityCityConverted.RemoveAll() end
---*Action*
function Events.CulturalIdentityCityConverted.Dispatch() end
---*Action*
---@param playerID number
---@param cityID number
---@param influencingPlayerID number
function Events.CulturalIdentityCityConverted.Call(playerID, cityID, influencingPlayerID) end
---*Action*
---@param playerID number
---@param cityID number
---@param influencingPlayerID number
function Events.CulturalIdentityCityConverted.CallImmediate(playerID, cityID, influencingPlayerID) end
---*Action*
---@param func fun(playerID: number, cityID: number, influencingPlayerID: number)
---@return fun(playerID: number, cityID: number, influencingPlayerID: number)
function Events.CulturalIdentityCityConverted.Add(func) end
---*Action*
---@param func function
function Events.CulturalIdentityCityConverted.Remove(func) end

---@overload fun(playerID: number, cityID: number, conversionOutcome: IdentityConversionOutcome)
Events.CulturalIdentityConversionOutcomeChanged = {}
---*Query*
---@return number amount
function Events.CulturalIdentityConversionOutcomeChanged.Count() end
---*Action*
function Events.CulturalIdentityConversionOutcomeChanged.RemoveAll() end
---*Action*
function Events.CulturalIdentityConversionOutcomeChanged.Dispatch() end
Events.CulturalIdentityConversionOutcomeChanged = {}
---*Query*
---@return number amount
function Events.CulturalIdentityConversionOutcomeChanged.Count() end
---*Action*
function Events.CulturalIdentityConversionOutcomeChanged.RemoveAll() end
---*Action*
function Events.CulturalIdentityConversionOutcomeChanged.Dispatch() end
---*Action*
---@param playerID number
---@param cityID number
---@param conversionOutcome IdentityConversionOutcome
function Events.CulturalIdentityConversionOutcomeChanged.Call(playerID, cityID, conversionOutcome) end
---*Action*
---@param playerID number
---@param cityID number
---@param conversionOutcome IdentityConversionOutcome
function Events.CulturalIdentityConversionOutcomeChanged.CallImmediate(playerID, cityID, conversionOutcome) end
---*Action*
---@param func fun(playerID: number, cityID: number, conversionOutcome: IdentityConversionOutcome)
---@return fun(playerID: number, cityID: number, conversionOutcome: IdentityConversionOutcome)
function Events.CulturalIdentityConversionOutcomeChanged.Add(func) end
---*Action*
---@param func function
function Events.CulturalIdentityConversionOutcomeChanged.Remove(func) end

---@overload fun()
Events.CultureChanged = {}
---*Query*
---@return number amount
function Events.CultureChanged.Count() end
---*Action*
function Events.CultureChanged.RemoveAll() end
---*Action*
function Events.CultureChanged.Dispatch() end
Events.CultureChanged = {}
---*Query*
---@return number amount
function Events.CultureChanged.Count() end
---*Action*
function Events.CultureChanged.RemoveAll() end
---*Action*
function Events.CultureChanged.Dispatch() end
---*Action*
function Events.CultureChanged.Call() end
---*Action*
function Events.CultureChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.CultureChanged.Add(func) end
---*Action*
---@param func function
function Events.CultureChanged.Remove(func) end

---@overload fun(playerID: number)
Events.CultureYieldChanged = {}
---*Query*
---@return number amount
function Events.CultureYieldChanged.Count() end
---*Action*
function Events.CultureYieldChanged.RemoveAll() end
---*Action*
function Events.CultureYieldChanged.Dispatch() end
Events.CultureYieldChanged = {}
---*Query*
---@return number amount
function Events.CultureYieldChanged.Count() end
---*Action*
function Events.CultureYieldChanged.RemoveAll() end
---*Action*
function Events.CultureYieldChanged.Dispatch() end
---*Action*
---@param playerID number
function Events.CultureYieldChanged.Call(playerID) end
---*Action*
---@param playerID number
function Events.CultureYieldChanged.CallImmediate(playerID) end
---*Action*
---@param func fun(playerID: number)
---@return fun(playerID: number)
function Events.CultureYieldChanged.Add(func) end
---*Action*
---@param func function
function Events.CultureYieldChanged.Remove(func) end

---@overload fun()
Events.DiplomacyDealEnacted = {}
---*Query*
---@return number amount
function Events.DiplomacyDealEnacted.Count() end
---*Action*
function Events.DiplomacyDealEnacted.RemoveAll() end
---*Action*
function Events.DiplomacyDealEnacted.Dispatch() end
Events.DiplomacyDealEnacted = {}
---*Query*
---@return number amount
function Events.DiplomacyDealEnacted.Count() end
---*Action*
function Events.DiplomacyDealEnacted.RemoveAll() end
---*Action*
function Events.DiplomacyDealEnacted.Dispatch() end
---*Action*
function Events.DiplomacyDealEnacted.Call() end
---*Action*
function Events.DiplomacyDealEnacted.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.DiplomacyDealEnacted.Add(func) end
---*Action*
---@param func function
function Events.DiplomacyDealEnacted.Remove(func) end

---@overload fun()
Events.DiplomacyDealExpired = {}
---*Query*
---@return number amount
function Events.DiplomacyDealExpired.Count() end
---*Action*
function Events.DiplomacyDealExpired.RemoveAll() end
---*Action*
function Events.DiplomacyDealExpired.Dispatch() end
Events.DiplomacyDealExpired = {}
---*Query*
---@return number amount
function Events.DiplomacyDealExpired.Count() end
---*Action*
function Events.DiplomacyDealExpired.RemoveAll() end
---*Action*
function Events.DiplomacyDealExpired.Dispatch() end
---*Action*
function Events.DiplomacyDealExpired.Call() end
---*Action*
function Events.DiplomacyDealExpired.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.DiplomacyDealExpired.Add(func) end
---*Action*
---@param func function
function Events.DiplomacyDealExpired.Remove(func) end

---@overload fun(firstPlayerID: number, secondPlayerID: number)
Events.DiplomacyDeclareWar = {}
---*Query*
---@return number amount
function Events.DiplomacyDeclareWar.Count() end
---*Action*
function Events.DiplomacyDeclareWar.RemoveAll() end
---*Action*
function Events.DiplomacyDeclareWar.Dispatch() end
Events.DiplomacyDeclareWar = {}
---*Query*
---@return number amount
function Events.DiplomacyDeclareWar.Count() end
---*Action*
function Events.DiplomacyDeclareWar.RemoveAll() end
---*Action*
function Events.DiplomacyDeclareWar.Dispatch() end
---*Action*
---@param firstPlayerID number
---@param secondPlayerID number
function Events.DiplomacyDeclareWar.Call(firstPlayerID, secondPlayerID) end
---*Action*
---@param firstPlayerID number
---@param secondPlayerID number
function Events.DiplomacyDeclareWar.CallImmediate(firstPlayerID, secondPlayerID) end
---*Action*
---@param func fun(firstPlayerID: number, secondPlayerID: number)
---@return fun(firstPlayerID: number, secondPlayerID: number)
function Events.DiplomacyDeclareWar.Add(func) end
---*Action*
---@param func function
function Events.DiplomacyDeclareWar.Remove(func) end

---@overload fun(fromPlayerID: number, toPlayerID: number, actionType: DiplomacyActionTypes)
Events.DiplomacyIncomingDeal = {}
---*Query*
---@return number amount
function Events.DiplomacyIncomingDeal.Count() end
---*Action*
function Events.DiplomacyIncomingDeal.RemoveAll() end
---*Action*
function Events.DiplomacyIncomingDeal.Dispatch() end
Events.DiplomacyIncomingDeal = {}
---*Query*
---@return number amount
function Events.DiplomacyIncomingDeal.Count() end
---*Action*
function Events.DiplomacyIncomingDeal.RemoveAll() end
---*Action*
function Events.DiplomacyIncomingDeal.Dispatch() end
---*Action*
---@param fromPlayerID number
---@param toPlayerID number
---@param actionType DiplomacyActionTypes
function Events.DiplomacyIncomingDeal.Call(fromPlayerID, toPlayerID, actionType) end
---*Action*
---@param fromPlayerID number
---@param toPlayerID number
---@param actionType DiplomacyActionTypes
function Events.DiplomacyIncomingDeal.CallImmediate(fromPlayerID, toPlayerID, actionType) end
---*Action*
---@param func fun(fromPlayerID: number, toPlayerID: number, actionType: DiplomacyActionTypes)
---@return fun(fromPlayerID: number, toPlayerID: number, actionType: DiplomacyActionTypes)
function Events.DiplomacyIncomingDeal.Add(func) end
---*Action*
---@param func function
function Events.DiplomacyIncomingDeal.Remove(func) end

---@overload fun(firstPlayerID: number, secondPlayerID: number)
Events.DiplomacyMakePeace = {}
---*Query*
---@return number amount
function Events.DiplomacyMakePeace.Count() end
---*Action*
function Events.DiplomacyMakePeace.RemoveAll() end
---*Action*
function Events.DiplomacyMakePeace.Dispatch() end
Events.DiplomacyMakePeace = {}
---*Query*
---@return number amount
function Events.DiplomacyMakePeace.Count() end
---*Action*
function Events.DiplomacyMakePeace.RemoveAll() end
---*Action*
function Events.DiplomacyMakePeace.Dispatch() end
---*Action*
---@param firstPlayerID number
---@param secondPlayerID number
function Events.DiplomacyMakePeace.Call(firstPlayerID, secondPlayerID) end
---*Action*
---@param firstPlayerID number
---@param secondPlayerID number
function Events.DiplomacyMakePeace.CallImmediate(firstPlayerID, secondPlayerID) end
---*Action*
---@param func fun(firstPlayerID: number, secondPlayerID: number)
---@return fun(firstPlayerID: number, secondPlayerID: number)
function Events.DiplomacyMakePeace.Add(func) end
---*Action*
---@param func function
function Events.DiplomacyMakePeace.Remove(func) end

---@overload fun(player1ID: number, player2ID: number)
Events.DiplomacyMeet = {}
---*Query*
---@return number amount
function Events.DiplomacyMeet.Count() end
---*Action*
function Events.DiplomacyMeet.RemoveAll() end
---*Action*
function Events.DiplomacyMeet.Dispatch() end
Events.DiplomacyMeet = {}
---*Query*
---@return number amount
function Events.DiplomacyMeet.Count() end
---*Action*
function Events.DiplomacyMeet.RemoveAll() end
---*Action*
function Events.DiplomacyMeet.Dispatch() end
---*Action*
---@param player1ID number
---@param player2ID number
function Events.DiplomacyMeet.Call(player1ID, player2ID) end
---*Action*
---@param player1ID number
---@param player2ID number
function Events.DiplomacyMeet.CallImmediate(player1ID, player2ID) end
---*Action*
---@param func fun(player1ID: number, player2ID: number)
---@return fun(player1ID: number, player2ID: number)
function Events.DiplomacyMeet.Add(func) end
---*Action*
---@param func function
function Events.DiplomacyMeet.Remove(func) end

---@overload fun()
Events.DiplomacyMeetMajorMinor = {}
---*Query*
---@return number amount
function Events.DiplomacyMeetMajorMinor.Count() end
---*Action*
function Events.DiplomacyMeetMajorMinor.RemoveAll() end
---*Action*
function Events.DiplomacyMeetMajorMinor.Dispatch() end
Events.DiplomacyMeetMajorMinor = {}
---*Query*
---@return number amount
function Events.DiplomacyMeetMajorMinor.Count() end
---*Action*
function Events.DiplomacyMeetMajorMinor.RemoveAll() end
---*Action*
function Events.DiplomacyMeetMajorMinor.Dispatch() end
---*Action*
function Events.DiplomacyMeetMajorMinor.Call() end
---*Action*
function Events.DiplomacyMeetMajorMinor.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.DiplomacyMeetMajorMinor.Add(func) end
---*Action*
---@param func function
function Events.DiplomacyMeetMajorMinor.Remove(func) end

---@overload fun()
Events.DiplomacyMeetMajors = {}
---*Query*
---@return number amount
function Events.DiplomacyMeetMajors.Count() end
---*Action*
function Events.DiplomacyMeetMajors.RemoveAll() end
---*Action*
function Events.DiplomacyMeetMajors.Dispatch() end
Events.DiplomacyMeetMajors = {}
---*Query*
---@return number amount
function Events.DiplomacyMeetMajors.Count() end
---*Action*
function Events.DiplomacyMeetMajors.RemoveAll() end
---*Action*
function Events.DiplomacyMeetMajors.Dispatch() end
---*Action*
function Events.DiplomacyMeetMajors.Call() end
---*Action*
function Events.DiplomacyMeetMajors.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.DiplomacyMeetMajors.Add(func) end
---*Action*
---@param func function
function Events.DiplomacyMeetMajors.Remove(func) end

---@overload fun(actingPlayerID: number, reactingPlayerID: number)
Events.DiplomacyRefusePeace = {}
---*Query*
---@return number amount
function Events.DiplomacyRefusePeace.Count() end
---*Action*
function Events.DiplomacyRefusePeace.RemoveAll() end
---*Action*
function Events.DiplomacyRefusePeace.Dispatch() end
Events.DiplomacyRefusePeace = {}
---*Query*
---@return number amount
function Events.DiplomacyRefusePeace.Count() end
---*Action*
function Events.DiplomacyRefusePeace.RemoveAll() end
---*Action*
function Events.DiplomacyRefusePeace.Dispatch() end
---*Action*
---@param actingPlayerID number
---@param reactingPlayerID number
function Events.DiplomacyRefusePeace.Call(actingPlayerID, reactingPlayerID) end
---*Action*
---@param actingPlayerID number
---@param reactingPlayerID number
function Events.DiplomacyRefusePeace.CallImmediate(actingPlayerID, reactingPlayerID) end
---*Action*
---@param func fun(actingPlayerID: number, reactingPlayerID: number)
---@return fun(actingPlayerID: number, reactingPlayerID: number)
function Events.DiplomacyRefusePeace.Add(func) end
---*Action*
---@param func function
function Events.DiplomacyRefusePeace.Remove(func) end

---@overload fun(player1ID: number, player2ID: number)
Events.DiplomacyRelationshipChanged = {}
---*Query*
---@return number amount
function Events.DiplomacyRelationshipChanged.Count() end
---*Action*
function Events.DiplomacyRelationshipChanged.RemoveAll() end
---*Action*
function Events.DiplomacyRelationshipChanged.Dispatch() end
Events.DiplomacyRelationshipChanged = {}
---*Query*
---@return number amount
function Events.DiplomacyRelationshipChanged.Count() end
---*Action*
function Events.DiplomacyRelationshipChanged.RemoveAll() end
---*Action*
function Events.DiplomacyRelationshipChanged.Dispatch() end
---*Action*
---@param player1ID number
---@param player2ID number
function Events.DiplomacyRelationshipChanged.Call(player1ID, player2ID) end
---*Action*
---@param player1ID number
---@param player2ID number
function Events.DiplomacyRelationshipChanged.CallImmediate(player1ID, player2ID) end
---*Action*
---@param func fun(player1ID: number, player2ID: number)
---@return fun(player1ID: number, player2ID: number)
function Events.DiplomacyRelationshipChanged.Add(func) end
---*Action*
---@param func function
function Events.DiplomacyRelationshipChanged.Remove(func) end

---@overload fun(sessionID: number)
Events.DiplomacySessionClosed = {}
---*Query*
---@return number amount
function Events.DiplomacySessionClosed.Count() end
---*Action*
function Events.DiplomacySessionClosed.RemoveAll() end
---*Action*
function Events.DiplomacySessionClosed.Dispatch() end
Events.DiplomacySessionClosed = {}
---*Query*
---@return number amount
function Events.DiplomacySessionClosed.Count() end
---*Action*
function Events.DiplomacySessionClosed.RemoveAll() end
---*Action*
function Events.DiplomacySessionClosed.Dispatch() end
---*Action*
---@param sessionID number
function Events.DiplomacySessionClosed.Call(sessionID) end
---*Action*
---@param sessionID number
function Events.DiplomacySessionClosed.CallImmediate(sessionID) end
---*Action*
---@param func fun(sessionID: number)
---@return fun(sessionID: number)
function Events.DiplomacySessionClosed.Add(func) end
---*Action*
---@param func function
function Events.DiplomacySessionClosed.Remove(func) end

---@overload fun(actingPlayerID: number, reactingPlayerID: number, values: table)
Events.DiplomacyStatement = {}
---*Query*
---@return number amount
function Events.DiplomacyStatement.Count() end
---*Action*
function Events.DiplomacyStatement.RemoveAll() end
---*Action*
function Events.DiplomacyStatement.Dispatch() end
Events.DiplomacyStatement = {}
---*Query*
---@return number amount
function Events.DiplomacyStatement.Count() end
---*Action*
function Events.DiplomacyStatement.RemoveAll() end
---*Action*
function Events.DiplomacyStatement.Dispatch() end
---*Action*
---@param actingPlayerID number
---@param reactingPlayerID number
---@param values table
function Events.DiplomacyStatement.Call(actingPlayerID, reactingPlayerID, values) end
---*Action*
---@param actingPlayerID number
---@param reactingPlayerID number
---@param values table
function Events.DiplomacyStatement.CallImmediate(actingPlayerID, reactingPlayerID, values) end
---*Action*
---@param func fun(actingPlayerID: number, reactingPlayerID: number, values: table)
---@return fun(actingPlayerID: number, reactingPlayerID: number, values: table)
function Events.DiplomacyStatement.Add(func) end
---*Action*
---@param func function
function Events.DiplomacyStatement.Remove(func) end

---@overload fun(playerID: number, districtID: number, cityID: number, X: number, Y: number, districtIndex: number, percentComplete: number)
Events.DistrictAddedToMap = {}
---*Query*
---@return number amount
function Events.DistrictAddedToMap.Count() end
---*Action*
function Events.DistrictAddedToMap.RemoveAll() end
---*Action*
function Events.DistrictAddedToMap.Dispatch() end
Events.DistrictAddedToMap = {}
---*Query*
---@return number amount
function Events.DistrictAddedToMap.Count() end
---*Action*
function Events.DistrictAddedToMap.RemoveAll() end
---*Action*
function Events.DistrictAddedToMap.Dispatch() end
---*Action*
---@param playerID number
---@param districtID number
---@param cityID number
---@param X number
---@param Y number
---@param districtIndex number
---@param percentComplete number
function Events.DistrictAddedToMap.Call(playerID, districtID, cityID, X, Y, districtIndex, percentComplete) end
---*Action*
---@param playerID number
---@param districtID number
---@param cityID number
---@param X number
---@param Y number
---@param districtIndex number
---@param percentComplete number
function Events.DistrictAddedToMap.CallImmediate(playerID, districtID, cityID, X, Y, districtIndex, percentComplete) end
---*Action*
---@param func fun(playerID: number, districtID: number, cityID: number, X: number, Y: number, districtIndex: number, percentComplete: number)
---@return fun(playerID: number, districtID: number, cityID: number, X: number, Y: number, districtIndex: number, percentComplete: number)
function Events.DistrictAddedToMap.Add(func) end
---*Action*
---@param func function
function Events.DistrictAddedToMap.Remove(func) end

---@overload fun()
Events.DistrictBuildingRestore = {}
---*Query*
---@return number amount
function Events.DistrictBuildingRestore.Count() end
---*Action*
function Events.DistrictBuildingRestore.RemoveAll() end
---*Action*
function Events.DistrictBuildingRestore.Dispatch() end
Events.DistrictBuildingRestore = {}
---*Query*
---@return number amount
function Events.DistrictBuildingRestore.Count() end
---*Action*
function Events.DistrictBuildingRestore.RemoveAll() end
---*Action*
function Events.DistrictBuildingRestore.Dispatch() end
---*Action*
function Events.DistrictBuildingRestore.Call() end
---*Action*
function Events.DistrictBuildingRestore.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.DistrictBuildingRestore.Add(func) end
---*Action*
---@param func function
function Events.DistrictBuildingRestore.Remove(func) end

---@overload fun(playerID: number, districtID: number, cityID: number, X: number, Y: number, districtIndex: number, era: number, civilizationIndex: number, percentComplete: number, appeal: number, isPillaged: boolean)
Events.DistrictBuildProgressChanged = {}
---*Query*
---@return number amount
function Events.DistrictBuildProgressChanged.Count() end
---*Action*
function Events.DistrictBuildProgressChanged.RemoveAll() end
---*Action*
function Events.DistrictBuildProgressChanged.Dispatch() end
Events.DistrictBuildProgressChanged = {}
---*Query*
---@return number amount
function Events.DistrictBuildProgressChanged.Count() end
---*Action*
function Events.DistrictBuildProgressChanged.RemoveAll() end
---*Action*
function Events.DistrictBuildProgressChanged.Dispatch() end
---*Action*
---@param playerID number
---@param districtID number
---@param cityID number
---@param X number
---@param Y number
---@param districtIndex number
---@param era number
---@param civilizationIndex number
---@param percentComplete number
---@param appeal number
---@param isPillaged boolean
function Events.DistrictBuildProgressChanged.Call(playerID, districtID, cityID, X, Y, districtIndex, era, civilizationIndex, percentComplete, appeal, isPillaged) end
---*Action*
---@param playerID number
---@param districtID number
---@param cityID number
---@param X number
---@param Y number
---@param districtIndex number
---@param era number
---@param civilizationIndex number
---@param percentComplete number
---@param appeal number
---@param isPillaged boolean
function Events.DistrictBuildProgressChanged.CallImmediate(playerID, districtID, cityID, X, Y, districtIndex, era, civilizationIndex, percentComplete, appeal, isPillaged) end
---*Action*
---@param func fun(playerID: number, districtID: number, cityID: number, X: number, Y: number, districtIndex: number, era: number, civilizationIndex: number, percentComplete: number, appeal: number, isPillaged: boolean)
---@return fun(playerID: number, districtID: number, cityID: number, X: number, Y: number, districtIndex: number, era: number, civilizationIndex: number, percentComplete: number, appeal: number, isPillaged: boolean)
function Events.DistrictBuildProgressChanged.Add(func) end
---*Action*
---@param func function
function Events.DistrictBuildProgressChanged.Remove(func) end

---@overload fun(eventSubType: EventSubTypes, playerID: number, districtID: number)
Events.DistrictCombatChanged = {}
---*Query*
---@return number amount
function Events.DistrictCombatChanged.Count() end
---*Action*
function Events.DistrictCombatChanged.RemoveAll() end
---*Action*
function Events.DistrictCombatChanged.Dispatch() end
Events.DistrictCombatChanged = {}
---*Query*
---@return number amount
function Events.DistrictCombatChanged.Count() end
---*Action*
function Events.DistrictCombatChanged.RemoveAll() end
---*Action*
function Events.DistrictCombatChanged.Dispatch() end
---*Action*
---@param eventSubType EventSubTypes
---@param playerID number
---@param districtID number
function Events.DistrictCombatChanged.Call(eventSubType, playerID, districtID) end
---*Action*
---@param eventSubType EventSubTypes
---@param playerID number
---@param districtID number
function Events.DistrictCombatChanged.CallImmediate(eventSubType, playerID, districtID) end
---*Action*
---@param func fun(eventSubType: EventSubTypes, playerID: number, districtID: number)
---@return fun(eventSubType: EventSubTypes, playerID: number, districtID: number)
function Events.DistrictCombatChanged.Add(func) end
---*Action*
---@param func function
function Events.DistrictCombatChanged.Remove(func) end

---@overload fun(playerID: number, districtID: number, defenseType: DefenseTypes, newDamage: number, oldDamage: number)
Events.DistrictDamageChanged = {}
---*Query*
---@return number amount
function Events.DistrictDamageChanged.Count() end
---*Action*
function Events.DistrictDamageChanged.RemoveAll() end
---*Action*
function Events.DistrictDamageChanged.Dispatch() end
Events.DistrictDamageChanged = {}
---*Query*
---@return number amount
function Events.DistrictDamageChanged.Count() end
---*Action*
function Events.DistrictDamageChanged.RemoveAll() end
---*Action*
function Events.DistrictDamageChanged.Dispatch() end
---*Action*
---@param playerID number
---@param districtID number
---@param defenseType DefenseTypes
---@param newDamage number
---@param oldDamage number
function Events.DistrictDamageChanged.Call(playerID, districtID, defenseType, newDamage, oldDamage) end
---*Action*
---@param playerID number
---@param districtID number
---@param defenseType DefenseTypes
---@param newDamage number
---@param oldDamage number
function Events.DistrictDamageChanged.CallImmediate(playerID, districtID, defenseType, newDamage, oldDamage) end
---*Action*
---@param func fun(playerID: number, districtID: number, defenseType: DefenseTypes, newDamage: number, oldDamage: number)
---@return fun(playerID: number, districtID: number, defenseType: DefenseTypes, newDamage: number, oldDamage: number)
function Events.DistrictDamageChanged.Add(func) end
---*Action*
---@param func function
function Events.DistrictDamageChanged.Remove(func) end

---@overload fun(ownerID: number, districtID: number, cityID: number, X: number, Y: number, districtIndex: number, percentComplete: number, isPillaged: boolean)
Events.DistrictPillaged = {}
---*Query*
---@return number amount
function Events.DistrictPillaged.Count() end
---*Action*
function Events.DistrictPillaged.RemoveAll() end
---*Action*
function Events.DistrictPillaged.Dispatch() end
Events.DistrictPillaged = {}
---*Query*
---@return number amount
function Events.DistrictPillaged.Count() end
---*Action*
function Events.DistrictPillaged.RemoveAll() end
---*Action*
function Events.DistrictPillaged.Dispatch() end
---*Action*
---@param ownerID number
---@param districtID number
---@param cityID number
---@param X number
---@param Y number
---@param districtIndex number
---@param percentComplete number
---@param isPillaged boolean
function Events.DistrictPillaged.Call(ownerID, districtID, cityID, X, Y, districtIndex, percentComplete, isPillaged) end
---*Action*
---@param ownerID number
---@param districtID number
---@param cityID number
---@param X number
---@param Y number
---@param districtIndex number
---@param percentComplete number
---@param isPillaged boolean
function Events.DistrictPillaged.CallImmediate(ownerID, districtID, cityID, X, Y, districtIndex, percentComplete, isPillaged) end
---*Action*
---@param func fun(ownerID: number, districtID: number, cityID: number, X: number, Y: number, districtIndex: number, percentComplete: number, isPillaged: boolean)
---@return fun(ownerID: number, districtID: number, cityID: number, X: number, Y: number, districtIndex: number, percentComplete: number, isPillaged: boolean)
function Events.DistrictPillaged.Add(func) end
---*Action*
---@param func function
function Events.DistrictPillaged.Remove(func) end

---@overload fun(playerID: number, districtID: number)
Events.DistrictRemovedFromMap = {}
---*Query*
---@return number amount
function Events.DistrictRemovedFromMap.Count() end
---*Action*
function Events.DistrictRemovedFromMap.RemoveAll() end
---*Action*
function Events.DistrictRemovedFromMap.Dispatch() end
Events.DistrictRemovedFromMap = {}
---*Query*
---@return number amount
function Events.DistrictRemovedFromMap.Count() end
---*Action*
function Events.DistrictRemovedFromMap.RemoveAll() end
---*Action*
function Events.DistrictRemovedFromMap.Dispatch() end
---*Action*
---@param playerID number
---@param districtID number
function Events.DistrictRemovedFromMap.Call(playerID, districtID) end
---*Action*
---@param playerID number
---@param districtID number
function Events.DistrictRemovedFromMap.CallImmediate(playerID, districtID) end
---*Action*
---@param func fun(playerID: number, districtID: number)
---@return fun(playerID: number, districtID: number)
function Events.DistrictRemovedFromMap.Add(func) end
---*Action*
---@param func function
function Events.DistrictRemovedFromMap.Remove(func) end

---@overload fun(playerID: number, districtID: number)
Events.DistrictUnitsChanged = {}
---*Query*
---@return number amount
function Events.DistrictUnitsChanged.Count() end
---*Action*
function Events.DistrictUnitsChanged.RemoveAll() end
---*Action*
function Events.DistrictUnitsChanged.Dispatch() end
Events.DistrictUnitsChanged = {}
---*Query*
---@return number amount
function Events.DistrictUnitsChanged.Count() end
---*Action*
function Events.DistrictUnitsChanged.RemoveAll() end
---*Action*
function Events.DistrictUnitsChanged.Dispatch() end
---*Action*
---@param playerID number
---@param districtID number
function Events.DistrictUnitsChanged.Call(playerID, districtID) end
---*Action*
---@param playerID number
---@param districtID number
function Events.DistrictUnitsChanged.CallImmediate(playerID, districtID) end
---*Action*
---@param func fun(playerID: number, districtID: number)
---@return fun(playerID: number, districtID: number)
function Events.DistrictUnitsChanged.Add(func) end
---*Action*
---@param func function
function Events.DistrictUnitsChanged.Remove(func) end

---@overload fun(playerID: number, districtID: number, eVisibility: number)
Events.DistrictVisibilityChanged = {}
---*Query*
---@return number amount
function Events.DistrictVisibilityChanged.Count() end
---*Action*
function Events.DistrictVisibilityChanged.RemoveAll() end
---*Action*
function Events.DistrictVisibilityChanged.Dispatch() end
Events.DistrictVisibilityChanged = {}
---*Query*
---@return number amount
function Events.DistrictVisibilityChanged.Count() end
---*Action*
function Events.DistrictVisibilityChanged.RemoveAll() end
---*Action*
function Events.DistrictVisibilityChanged.Dispatch() end
---*Action*
---@param playerID number
---@param districtID number
---@param eVisibility number
function Events.DistrictVisibilityChanged.Call(playerID, districtID, eVisibility) end
---*Action*
---@param playerID number
---@param districtID number
---@param eVisibility number
function Events.DistrictVisibilityChanged.CallImmediate(playerID, districtID, eVisibility) end
---*Action*
---@param func fun(playerID: number, districtID: number, eVisibility: number)
---@return fun(playerID: number, districtID: number, eVisibility: number)
function Events.DistrictVisibilityChanged.Add(func) end
---*Action*
---@param func function
function Events.DistrictVisibilityChanged.Remove(func) end

---@overload fun()
Events.EmergenciesUpdated = {}
---*Query*
---@return number amount
function Events.EmergenciesUpdated.Count() end
---*Action*
function Events.EmergenciesUpdated.RemoveAll() end
---*Action*
function Events.EmergenciesUpdated.Dispatch() end
Events.EmergenciesUpdated = {}
---*Query*
---@return number amount
function Events.EmergenciesUpdated.Count() end
---*Action*
function Events.EmergenciesUpdated.RemoveAll() end
---*Action*
function Events.EmergenciesUpdated.Dispatch() end
---*Action*
function Events.EmergenciesUpdated.Call() end
---*Action*
function Events.EmergenciesUpdated.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.EmergenciesUpdated.Add(func) end
---*Action*
---@param func function
function Events.EmergenciesUpdated.Remove(func) end

---@overload fun(targetPlayerID: number, emergencyIndex: number)
Events.EmergencyAvailable = {}
---*Query*
---@return number amount
function Events.EmergencyAvailable.Count() end
---*Action*
function Events.EmergencyAvailable.RemoveAll() end
---*Action*
function Events.EmergencyAvailable.Dispatch() end
Events.EmergencyAvailable = {}
---*Query*
---@return number amount
function Events.EmergencyAvailable.Count() end
---*Action*
function Events.EmergencyAvailable.RemoveAll() end
---*Action*
function Events.EmergencyAvailable.Dispatch() end
---*Action*
---@param targetPlayerID number
---@param emergencyIndex number
function Events.EmergencyAvailable.Call(targetPlayerID, emergencyIndex) end
---*Action*
---@param targetPlayerID number
---@param emergencyIndex number
function Events.EmergencyAvailable.CallImmediate(targetPlayerID, emergencyIndex) end
---*Action*
---@param func fun(targetPlayerID: number, emergencyIndex: number)
---@return fun(targetPlayerID: number, emergencyIndex: number)
function Events.EmergencyAvailable.Add(func) end
---*Action*
---@param func function
function Events.EmergencyAvailable.Remove(func) end

---@overload fun()
Events.EmergencyAvailableParticipant = {}
---*Query*
---@return number amount
function Events.EmergencyAvailableParticipant.Count() end
---*Action*
function Events.EmergencyAvailableParticipant.RemoveAll() end
---*Action*
function Events.EmergencyAvailableParticipant.Dispatch() end
Events.EmergencyAvailableParticipant = {}
---*Query*
---@return number amount
function Events.EmergencyAvailableParticipant.Count() end
---*Action*
function Events.EmergencyAvailableParticipant.RemoveAll() end
---*Action*
function Events.EmergencyAvailableParticipant.Dispatch() end
---*Action*
function Events.EmergencyAvailableParticipant.Call() end
---*Action*
function Events.EmergencyAvailableParticipant.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.EmergencyAvailableParticipant.Add(func) end
---*Action*
---@param func function
function Events.EmergencyAvailableParticipant.Remove(func) end

---@overload fun(playerID: number, targetPlayerID: number, turn: number)
Events.EmergencyCompleted = {}
---*Query*
---@return number amount
function Events.EmergencyCompleted.Count() end
---*Action*
function Events.EmergencyCompleted.RemoveAll() end
---*Action*
function Events.EmergencyCompleted.Dispatch() end
Events.EmergencyCompleted = {}
---*Query*
---@return number amount
function Events.EmergencyCompleted.Count() end
---*Action*
function Events.EmergencyCompleted.RemoveAll() end
---*Action*
function Events.EmergencyCompleted.Dispatch() end
---*Action*
---@param playerID number
---@param targetPlayerID number
---@param turn number
function Events.EmergencyCompleted.Call(playerID, targetPlayerID, turn) end
---*Action*
---@param playerID number
---@param targetPlayerID number
---@param turn number
function Events.EmergencyCompleted.CallImmediate(playerID, targetPlayerID, turn) end
---*Action*
---@param func fun(playerID: number, targetPlayerID: number, turn: number)
---@return fun(playerID: number, targetPlayerID: number, turn: number)
function Events.EmergencyCompleted.Add(func) end
---*Action*
---@param func function
function Events.EmergencyCompleted.Remove(func) end

---@overload fun()
Events.EmergencyCompleteParticipants = {}
---*Query*
---@return number amount
function Events.EmergencyCompleteParticipants.Count() end
---*Action*
function Events.EmergencyCompleteParticipants.RemoveAll() end
---*Action*
function Events.EmergencyCompleteParticipants.Dispatch() end
Events.EmergencyCompleteParticipants = {}
---*Query*
---@return number amount
function Events.EmergencyCompleteParticipants.Count() end
---*Action*
function Events.EmergencyCompleteParticipants.RemoveAll() end
---*Action*
function Events.EmergencyCompleteParticipants.Dispatch() end
---*Action*
function Events.EmergencyCompleteParticipants.Call() end
---*Action*
function Events.EmergencyCompleteParticipants.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.EmergencyCompleteParticipants.Add(func) end
---*Action*
---@param func function
function Events.EmergencyCompleteParticipants.Remove(func) end

---@overload fun()
Events.EmergencyRejected = {}
---*Query*
---@return number amount
function Events.EmergencyRejected.Count() end
---*Action*
function Events.EmergencyRejected.RemoveAll() end
---*Action*
function Events.EmergencyRejected.Dispatch() end
Events.EmergencyRejected = {}
---*Query*
---@return number amount
function Events.EmergencyRejected.Count() end
---*Action*
function Events.EmergencyRejected.RemoveAll() end
---*Action*
function Events.EmergencyRejected.Dispatch() end
---*Action*
function Events.EmergencyRejected.Call() end
---*Action*
function Events.EmergencyRejected.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.EmergencyRejected.Add(func) end
---*Action*
---@param func function
function Events.EmergencyRejected.Remove(func) end

---@overload fun(playerID: number, targetPlayerID: number, turn: number)
Events.EmergencyStarted = {}
---*Query*
---@return number amount
function Events.EmergencyStarted.Count() end
---*Action*
function Events.EmergencyStarted.RemoveAll() end
---*Action*
function Events.EmergencyStarted.Dispatch() end
Events.EmergencyStarted = {}
---*Query*
---@return number amount
function Events.EmergencyStarted.Count() end
---*Action*
function Events.EmergencyStarted.RemoveAll() end
---*Action*
function Events.EmergencyStarted.Dispatch() end
---*Action*
---@param playerID number
---@param targetPlayerID number
---@param turn number
function Events.EmergencyStarted.Call(playerID, targetPlayerID, turn) end
---*Action*
---@param playerID number
---@param targetPlayerID number
---@param turn number
function Events.EmergencyStarted.CallImmediate(playerID, targetPlayerID, turn) end
---*Action*
---@param func fun(playerID: number, targetPlayerID: number, turn: number)
---@return fun(playerID: number, targetPlayerID: number, turn: number)
function Events.EmergencyStarted.Add(func) end
---*Action*
---@param func function
function Events.EmergencyStarted.Remove(func) end

---@overload fun(prevEndTurnBlockingType: EndTurnBlockingTypes, newEndTurnBlockingType: EndTurnBlockingTypes)
Events.EndTurnBlockingChanged = {}
---*Query*
---@return number amount
function Events.EndTurnBlockingChanged.Count() end
---*Action*
function Events.EndTurnBlockingChanged.RemoveAll() end
---*Action*
function Events.EndTurnBlockingChanged.Dispatch() end
Events.EndTurnBlockingChanged = {}
---*Query*
---@return number amount
function Events.EndTurnBlockingChanged.Count() end
---*Action*
function Events.EndTurnBlockingChanged.RemoveAll() end
---*Action*
function Events.EndTurnBlockingChanged.Dispatch() end
---*Action*
---@param prevEndTurnBlockingType EndTurnBlockingTypes
---@param newEndTurnBlockingType EndTurnBlockingTypes
function Events.EndTurnBlockingChanged.Call(prevEndTurnBlockingType, newEndTurnBlockingType) end
---*Action*
---@param prevEndTurnBlockingType EndTurnBlockingTypes
---@param newEndTurnBlockingType EndTurnBlockingTypes
function Events.EndTurnBlockingChanged.CallImmediate(prevEndTurnBlockingType, newEndTurnBlockingType) end
---*Action*
---@param func fun(prevEndTurnBlockingType: EndTurnBlockingTypes, newEndTurnBlockingType: EndTurnBlockingTypes)
---@return fun(prevEndTurnBlockingType: EndTurnBlockingTypes, newEndTurnBlockingType: EndTurnBlockingTypes)
function Events.EndTurnBlockingChanged.Add(func) end
---*Action*
---@param func function
function Events.EndTurnBlockingChanged.Remove(func) end

---@overload fun()
Events.EndTurnDirty = {}
---*Query*
---@return number amount
function Events.EndTurnDirty.Count() end
---*Action*
function Events.EndTurnDirty.RemoveAll() end
---*Action*
function Events.EndTurnDirty.Dispatch() end
Events.EndTurnDirty = {}
---*Query*
---@return number amount
function Events.EndTurnDirty.Count() end
---*Action*
function Events.EndTurnDirty.RemoveAll() end
---*Action*
function Events.EndTurnDirty.Dispatch() end
---*Action*
function Events.EndTurnDirty.Call() end
---*Action*
function Events.EndTurnDirty.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.EndTurnDirty.Add(func) end
---*Action*
---@param func function
function Events.EndTurnDirty.Remove(func) end

---@overload fun()
Events.EndWonderReveal = {}
---*Query*
---@return number amount
function Events.EndWonderReveal.Count() end
---*Action*
function Events.EndWonderReveal.RemoveAll() end
---*Action*
function Events.EndWonderReveal.Dispatch() end
Events.EndWonderReveal = {}
---*Query*
---@return number amount
function Events.EndWonderReveal.Count() end
---*Action*
function Events.EndWonderReveal.RemoveAll() end
---*Action*
function Events.EndWonderReveal.Dispatch() end
---*Action*
function Events.EndWonderReveal.Call() end
---*Action*
function Events.EndWonderReveal.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.EndWonderReveal.Add(func) end
---*Action*
---@param func function
function Events.EndWonderReveal.Remove(func) end

---@overload fun(popupData: table)
Events.EventPopupRequest = {}
---*Query*
---@return number amount
function Events.EventPopupRequest.Count() end
---*Action*
function Events.EventPopupRequest.RemoveAll() end
---*Action*
function Events.EventPopupRequest.Dispatch() end
Events.EventPopupRequest = {}
---*Query*
---@return number amount
function Events.EventPopupRequest.Count() end
---*Action*
function Events.EventPopupRequest.RemoveAll() end
---*Action*
function Events.EventPopupRequest.Dispatch() end
---*Action*
---@param popupData table
function Events.EventPopupRequest.Call(popupData) end
---*Action*
---@param popupData table
function Events.EventPopupRequest.CallImmediate(popupData) end
---*Action*
---@param func fun(popupData: table)
---@return fun(popupData: table)
function Events.EventPopupRequest.Add(func) end
---*Action*
---@param func function
function Events.EventPopupRequest.Remove(func) end

---@overload fun()
Events.EventSoundRequest = {}
---*Query*
---@return number amount
function Events.EventSoundRequest.Count() end
---*Action*
function Events.EventSoundRequest.RemoveAll() end
---*Action*
function Events.EventSoundRequest.Dispatch() end
Events.EventSoundRequest = {}
---*Query*
---@return number amount
function Events.EventSoundRequest.Count() end
---*Action*
function Events.EventSoundRequest.RemoveAll() end
---*Action*
function Events.EventSoundRequest.Dispatch() end
---*Action*
function Events.EventSoundRequest.Call() end
---*Action*
function Events.EventSoundRequest.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.EventSoundRequest.Add(func) end
---*Action*
---@param func function
function Events.EventSoundRequest.Remove(func) end

---@overload fun(playerID: number, yield: number, balance: number)
Events.FaithChanged = {}
---*Query*
---@return number amount
function Events.FaithChanged.Count() end
---*Action*
function Events.FaithChanged.RemoveAll() end
---*Action*
function Events.FaithChanged.Dispatch() end
Events.FaithChanged = {}
---*Query*
---@return number amount
function Events.FaithChanged.Count() end
---*Action*
function Events.FaithChanged.RemoveAll() end
---*Action*
function Events.FaithChanged.Dispatch() end
---*Action*
---@param playerID number
---@param yield number
---@param balance number
function Events.FaithChanged.Call(playerID, yield, balance) end
---*Action*
---@param playerID number
---@param yield number
---@param balance number
function Events.FaithChanged.CallImmediate(playerID, yield, balance) end
---*Action*
---@param func fun(playerID: number, yield: number, balance: number)
---@return fun(playerID: number, yield: number, balance: number)
function Events.FaithChanged.Add(func) end
---*Action*
---@param func function
function Events.FaithChanged.Remove(func) end

---@overload fun(X: number, Y: number)
Events.FeatureAddedToMap = {}
---*Query*
---@return number amount
function Events.FeatureAddedToMap.Count() end
---*Action*
function Events.FeatureAddedToMap.RemoveAll() end
---*Action*
function Events.FeatureAddedToMap.Dispatch() end
Events.FeatureAddedToMap = {}
---*Query*
---@return number amount
function Events.FeatureAddedToMap.Count() end
---*Action*
function Events.FeatureAddedToMap.RemoveAll() end
---*Action*
function Events.FeatureAddedToMap.Dispatch() end
---*Action*
---@param X number
---@param Y number
function Events.FeatureAddedToMap.Call(X, Y) end
---*Action*
---@param X number
---@param Y number
function Events.FeatureAddedToMap.CallImmediate(X, Y) end
---*Action*
---@param func fun(X: number, Y: number)
---@return fun(X: number, Y: number)
function Events.FeatureAddedToMap.Add(func) end
---*Action*
---@param func function
function Events.FeatureAddedToMap.Remove(func) end

---@overload fun()
Events.FeatureChanged = {}
---*Query*
---@return number amount
function Events.FeatureChanged.Count() end
---*Action*
function Events.FeatureChanged.RemoveAll() end
---*Action*
function Events.FeatureChanged.Dispatch() end
Events.FeatureChanged = {}
---*Query*
---@return number amount
function Events.FeatureChanged.Count() end
---*Action*
function Events.FeatureChanged.RemoveAll() end
---*Action*
function Events.FeatureChanged.Dispatch() end
---*Action*
function Events.FeatureChanged.Call() end
---*Action*
function Events.FeatureChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.FeatureChanged.Add(func) end
---*Action*
---@param func function
function Events.FeatureChanged.Remove(func) end

---@overload fun(X: number, Y: number)
Events.FeatureRemovedFromMap = {}
---*Query*
---@return number amount
function Events.FeatureRemovedFromMap.Count() end
---*Action*
function Events.FeatureRemovedFromMap.RemoveAll() end
---*Action*
function Events.FeatureRemovedFromMap.Dispatch() end
Events.FeatureRemovedFromMap = {}
---*Query*
---@return number amount
function Events.FeatureRemovedFromMap.Count() end
---*Action*
function Events.FeatureRemovedFromMap.RemoveAll() end
---*Action*
function Events.FeatureRemovedFromMap.Dispatch() end
---*Action*
---@param X number
---@param Y number
function Events.FeatureRemovedFromMap.Call(X, Y) end
---*Action*
---@param X number
---@param Y number
function Events.FeatureRemovedFromMap.CallImmediate(X, Y) end
---*Action*
---@param func fun(X: number, Y: number)
---@return fun(X: number, Y: number)
function Events.FeatureRemovedFromMap.Add(func) end
---*Action*
---@param func function
function Events.FeatureRemovedFromMap.Remove(func) end

---@overload fun()
Events.FeatureVisibilityChanged = {}
---*Query*
---@return number amount
function Events.FeatureVisibilityChanged.Count() end
---*Action*
function Events.FeatureVisibilityChanged.RemoveAll() end
---*Action*
function Events.FeatureVisibilityChanged.Dispatch() end
Events.FeatureVisibilityChanged = {}
---*Query*
---@return number amount
function Events.FeatureVisibilityChanged.Count() end
---*Action*
function Events.FeatureVisibilityChanged.RemoveAll() end
---*Action*
function Events.FeatureVisibilityChanged.Dispatch() end
---*Action*
function Events.FeatureVisibilityChanged.Call() end
---*Action*
function Events.FeatureVisibilityChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.FeatureVisibilityChanged.Add(func) end
---*Action*
---@param func function
function Events.FeatureVisibilityChanged.Remove(func) end

---@overload fun(previousEraIndex: number, newEraIndex: number)
Events.GameEraChanged = {}
---*Query*
---@return number amount
function Events.GameEraChanged.Count() end
---*Action*
function Events.GameEraChanged.RemoveAll() end
---*Action*
function Events.GameEraChanged.Dispatch() end
Events.GameEraChanged = {}
---*Query*
---@return number amount
function Events.GameEraChanged.Count() end
---*Action*
function Events.GameEraChanged.RemoveAll() end
---*Action*
function Events.GameEraChanged.Dispatch() end
---*Action*
---@param previousEraIndex number
---@param newEraIndex number
function Events.GameEraChanged.Call(previousEraIndex, newEraIndex) end
---*Action*
---@param previousEraIndex number
---@param newEraIndex number
function Events.GameEraChanged.CallImmediate(previousEraIndex, newEraIndex) end
---*Action*
---@param func fun(previousEraIndex: number, newEraIndex: number)
---@return fun(previousEraIndex: number, newEraIndex: number)
function Events.GameEraChanged.Add(func) end
---*Action*
---@param func function
function Events.GameEraChanged.Remove(func) end

---@overload fun(momentIndex: number, unknown: number)
Events.GameHistoryMomentRecorded = {}
---*Query*
---@return number amount
function Events.GameHistoryMomentRecorded.Count() end
---*Action*
function Events.GameHistoryMomentRecorded.RemoveAll() end
---*Action*
function Events.GameHistoryMomentRecorded.Dispatch() end
Events.GameHistoryMomentRecorded = {}
---*Query*
---@return number amount
function Events.GameHistoryMomentRecorded.Count() end
---*Action*
function Events.GameHistoryMomentRecorded.RemoveAll() end
---*Action*
function Events.GameHistoryMomentRecorded.Dispatch() end
---*Action*
---@param momentIndex number
---@param unknown number
function Events.GameHistoryMomentRecorded.Call(momentIndex, unknown) end
---*Action*
---@param momentIndex number
---@param unknown number
function Events.GameHistoryMomentRecorded.CallImmediate(momentIndex, unknown) end
---*Action*
---@param func fun(momentIndex: number, unknown: number)
---@return fun(momentIndex: number, unknown: number)
function Events.GameHistoryMomentRecorded.Add(func) end
---*Action*
---@param func function
function Events.GameHistoryMomentRecorded.Remove(func) end

---@overload fun(playerID: number, unitID: number, unknown1: number, unknown2: number)
Events.GoodyHutReward = {}
---*Query*
---@return number amount
function Events.GoodyHutReward.Count() end
---*Action*
function Events.GoodyHutReward.RemoveAll() end
---*Action*
function Events.GoodyHutReward.Dispatch() end
Events.GoodyHutReward = {}
---*Query*
---@return number amount
function Events.GoodyHutReward.Count() end
---*Action*
function Events.GoodyHutReward.RemoveAll() end
---*Action*
function Events.GoodyHutReward.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
---@param unknown1 number
---@param unknown2 number
function Events.GoodyHutReward.Call(playerID, unitID, unknown1, unknown2) end
---*Action*
---@param playerID number
---@param unitID number
---@param unknown1 number
---@param unknown2 number
function Events.GoodyHutReward.CallImmediate(playerID, unitID, unknown1, unknown2) end
---*Action*
---@param func fun(playerID: number, unitID: number, unknown1: number, unknown2: number)
---@return fun(playerID: number, unitID: number, unknown1: number, unknown2: number)
function Events.GoodyHutReward.Add(func) end
---*Action*
---@param func function
function Events.GoodyHutReward.Remove(func) end

---@overload fun()
Events.GovDistrictPolicyLocked = {}
---*Query*
---@return number amount
function Events.GovDistrictPolicyLocked.Count() end
---*Action*
function Events.GovDistrictPolicyLocked.RemoveAll() end
---*Action*
function Events.GovDistrictPolicyLocked.Dispatch() end
Events.GovDistrictPolicyLocked = {}
---*Query*
---@return number amount
function Events.GovDistrictPolicyLocked.Count() end
---*Action*
function Events.GovDistrictPolicyLocked.RemoveAll() end
---*Action*
function Events.GovDistrictPolicyLocked.Dispatch() end
---*Action*
function Events.GovDistrictPolicyLocked.Call() end
---*Action*
function Events.GovDistrictPolicyLocked.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.GovDistrictPolicyLocked.Add(func) end
---*Action*
---@param func function
function Events.GovDistrictPolicyLocked.Remove(func) end

---@overload fun(playerID: number, policyIndex: number)
Events.GovDistrictPolicyUnlocked = {}
---*Query*
---@return number amount
function Events.GovDistrictPolicyUnlocked.Count() end
---*Action*
function Events.GovDistrictPolicyUnlocked.RemoveAll() end
---*Action*
function Events.GovDistrictPolicyUnlocked.Dispatch() end
Events.GovDistrictPolicyUnlocked = {}
---*Query*
---@return number amount
function Events.GovDistrictPolicyUnlocked.Count() end
---*Action*
function Events.GovDistrictPolicyUnlocked.RemoveAll() end
---*Action*
function Events.GovDistrictPolicyUnlocked.Dispatch() end
---*Action*
---@param playerID number
---@param policyIndex number
function Events.GovDistrictPolicyUnlocked.Call(playerID, policyIndex) end
---*Action*
---@param playerID number
---@param policyIndex number
function Events.GovDistrictPolicyUnlocked.CallImmediate(playerID, policyIndex) end
---*Action*
---@param func fun(playerID: number, policyIndex: number)
---@return fun(playerID: number, policyIndex: number)
function Events.GovDistrictPolicyUnlocked.Add(func) end
---*Action*
---@param func function
function Events.GovDistrictPolicyUnlocked.Remove(func) end

---@overload fun(playerID: number, governmentID: number)
Events.GovernmentChanged = {}
---*Query*
---@return number amount
function Events.GovernmentChanged.Count() end
---*Action*
function Events.GovernmentChanged.RemoveAll() end
---*Action*
function Events.GovernmentChanged.Dispatch() end
Events.GovernmentChanged = {}
---*Query*
---@return number amount
function Events.GovernmentChanged.Count() end
---*Action*
function Events.GovernmentChanged.RemoveAll() end
---*Action*
function Events.GovernmentChanged.Dispatch() end
---*Action*
---@param playerID number
---@param governmentID number
function Events.GovernmentChanged.Call(playerID, governmentID) end
---*Action*
---@param playerID number
---@param governmentID number
function Events.GovernmentChanged.CallImmediate(playerID, governmentID) end
---*Action*
---@param func fun(playerID: number, governmentID: number)
---@return fun(playerID: number, governmentID: number)
function Events.GovernmentChanged.Add(func) end
---*Action*
---@param func function
function Events.GovernmentChanged.Remove(func) end

---@overload fun(playerID: number, policyID: number)
Events.GovernmentPolicyChanged = {}
---*Query*
---@return number amount
function Events.GovernmentPolicyChanged.Count() end
---*Action*
function Events.GovernmentPolicyChanged.RemoveAll() end
---*Action*
function Events.GovernmentPolicyChanged.Dispatch() end
Events.GovernmentPolicyChanged = {}
---*Query*
---@return number amount
function Events.GovernmentPolicyChanged.Count() end
---*Action*
function Events.GovernmentPolicyChanged.RemoveAll() end
---*Action*
function Events.GovernmentPolicyChanged.Dispatch() end
---*Action*
---@param playerID number
---@param policyID number
function Events.GovernmentPolicyChanged.Call(playerID, policyID) end
---*Action*
---@param playerID number
---@param policyID number
function Events.GovernmentPolicyChanged.CallImmediate(playerID, policyID) end
---*Action*
---@param func fun(playerID: number, policyID: number)
---@return fun(playerID: number, policyID: number)
function Events.GovernmentPolicyChanged.Add(func) end
---*Action*
---@param func function
function Events.GovernmentPolicyChanged.Remove(func) end

---@overload fun(playerID: number)
Events.GovernmentPolicyObsoleted = {}
---*Query*
---@return number amount
function Events.GovernmentPolicyObsoleted.Count() end
---*Action*
function Events.GovernmentPolicyObsoleted.RemoveAll() end
---*Action*
function Events.GovernmentPolicyObsoleted.Dispatch() end
Events.GovernmentPolicyObsoleted = {}
---*Query*
---@return number amount
function Events.GovernmentPolicyObsoleted.Count() end
---*Action*
function Events.GovernmentPolicyObsoleted.RemoveAll() end
---*Action*
function Events.GovernmentPolicyObsoleted.Dispatch() end
---*Action*
---@param playerID number
function Events.GovernmentPolicyObsoleted.Call(playerID) end
---*Action*
---@param playerID number
function Events.GovernmentPolicyObsoleted.CallImmediate(playerID) end
---*Action*
---@param func fun(playerID: number)
---@return fun(playerID: number)
function Events.GovernmentPolicyObsoleted.Add(func) end
---*Action*
---@param func function
function Events.GovernmentPolicyObsoleted.Remove(func) end

---@overload fun(playerID: number, governorID: number)
Events.GovernorAppointed = {}
---*Query*
---@return number amount
function Events.GovernorAppointed.Count() end
---*Action*
function Events.GovernorAppointed.RemoveAll() end
---*Action*
function Events.GovernorAppointed.Dispatch() end
Events.GovernorAppointed = {}
---*Query*
---@return number amount
function Events.GovernorAppointed.Count() end
---*Action*
function Events.GovernorAppointed.RemoveAll() end
---*Action*
function Events.GovernorAppointed.Dispatch() end
---*Action*
---@param playerID number
---@param governorID number
function Events.GovernorAppointed.Call(playerID, governorID) end
---*Action*
---@param playerID number
---@param governorID number
function Events.GovernorAppointed.CallImmediate(playerID, governorID) end
---*Action*
---@param func fun(playerID: number, governorID: number)
---@return fun(playerID: number, governorID: number)
function Events.GovernorAppointed.Add(func) end
---*Action*
---@param func function
function Events.GovernorAppointed.Remove(func) end

---@overload fun(cityPlayerID: number, cityID: number, governorPlayerID: number, governorID: number)
Events.GovernorAssigned = {}
---*Query*
---@return number amount
function Events.GovernorAssigned.Count() end
---*Action*
function Events.GovernorAssigned.RemoveAll() end
---*Action*
function Events.GovernorAssigned.Dispatch() end
Events.GovernorAssigned = {}
---*Query*
---@return number amount
function Events.GovernorAssigned.Count() end
---*Action*
function Events.GovernorAssigned.RemoveAll() end
---*Action*
function Events.GovernorAssigned.Dispatch() end
---*Action*
---@param cityPlayerID number
---@param cityID number
---@param governorPlayerID number
---@param governorID number
function Events.GovernorAssigned.Call(cityPlayerID, cityID, governorPlayerID, governorID) end
---*Action*
---@param cityPlayerID number
---@param cityID number
---@param governorPlayerID number
---@param governorID number
function Events.GovernorAssigned.CallImmediate(cityPlayerID, cityID, governorPlayerID, governorID) end
---*Action*
---@param func fun(cityPlayerID: number, cityID: number, governorPlayerID: number, governorID: number)
---@return fun(cityPlayerID: number, cityID: number, governorPlayerID: number, governorID: number)
function Events.GovernorAssigned.Add(func) end
---*Action*
---@param func function
function Events.GovernorAssigned.Remove(func) end

---@overload fun(playerID: number, governorID: number)
Events.GovernorChanged = {}
---*Query*
---@return number amount
function Events.GovernorChanged.Count() end
---*Action*
function Events.GovernorChanged.RemoveAll() end
---*Action*
function Events.GovernorChanged.Dispatch() end
Events.GovernorChanged = {}
---*Query*
---@return number amount
function Events.GovernorChanged.Count() end
---*Action*
function Events.GovernorChanged.RemoveAll() end
---*Action*
function Events.GovernorChanged.Dispatch() end
---*Action*
---@param playerID number
---@param governorID number
function Events.GovernorChanged.Call(playerID, governorID) end
---*Action*
---@param playerID number
---@param governorID number
function Events.GovernorChanged.CallImmediate(playerID, governorID) end
---*Action*
---@param func fun(playerID: number, governorID: number)
---@return fun(playerID: number, governorID: number)
function Events.GovernorChanged.Add(func) end
---*Action*
---@param func function
function Events.GovernorChanged.Remove(func) end

---@overload fun()
Events.GovernorEstablished = {}
---*Query*
---@return number amount
function Events.GovernorEstablished.Count() end
---*Action*
function Events.GovernorEstablished.RemoveAll() end
---*Action*
function Events.GovernorEstablished.Dispatch() end
Events.GovernorEstablished = {}
---*Query*
---@return number amount
function Events.GovernorEstablished.Count() end
---*Action*
function Events.GovernorEstablished.RemoveAll() end
---*Action*
function Events.GovernorEstablished.Dispatch() end
---*Action*
function Events.GovernorEstablished.Call() end
---*Action*
function Events.GovernorEstablished.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.GovernorEstablished.Add(func) end
---*Action*
---@param func function
function Events.GovernorEstablished.Remove(func) end

---@overload fun(playerID: number, delta: number)
Events.GovernorPointsChanged = {}
---*Query*
---@return number amount
function Events.GovernorPointsChanged.Count() end
---*Action*
function Events.GovernorPointsChanged.RemoveAll() end
---*Action*
function Events.GovernorPointsChanged.Dispatch() end
Events.GovernorPointsChanged = {}
---*Query*
---@return number amount
function Events.GovernorPointsChanged.Count() end
---*Action*
function Events.GovernorPointsChanged.RemoveAll() end
---*Action*
function Events.GovernorPointsChanged.Dispatch() end
---*Action*
---@param playerID number
---@param delta number
function Events.GovernorPointsChanged.Call(playerID, delta) end
---*Action*
---@param playerID number
---@param delta number
function Events.GovernorPointsChanged.CallImmediate(playerID, delta) end
---*Action*
---@param func fun(playerID: number, delta: number)
---@return fun(playerID: number, delta: number)
function Events.GovernorPointsChanged.Add(func) end
---*Action*
---@param func function
function Events.GovernorPointsChanged.Remove(func) end

---@overload fun(playerID: number, governorIndex: number, promotionIndex: number)
Events.GovernorPromoted = {}
---*Query*
---@return number amount
function Events.GovernorPromoted.Count() end
---*Action*
function Events.GovernorPromoted.RemoveAll() end
---*Action*
function Events.GovernorPromoted.Dispatch() end
Events.GovernorPromoted = {}
---*Query*
---@return number amount
function Events.GovernorPromoted.Count() end
---*Action*
function Events.GovernorPromoted.RemoveAll() end
---*Action*
function Events.GovernorPromoted.Dispatch() end
---*Action*
---@param playerID number
---@param governorIndex number
---@param promotionIndex number
function Events.GovernorPromoted.Call(playerID, governorIndex, promotionIndex) end
---*Action*
---@param playerID number
---@param governorIndex number
---@param promotionIndex number
function Events.GovernorPromoted.CallImmediate(playerID, governorIndex, promotionIndex) end
---*Action*
---@param func fun(playerID: number, governorIndex: number, promotionIndex: number)
---@return fun(playerID: number, governorIndex: number, promotionIndex: number)
function Events.GovernorPromoted.Add(func) end
---*Action*
---@param func function
function Events.GovernorPromoted.Remove(func) end

---@overload fun(playerID: number)
Events.GreatPeoplePointsChanged = {}
---*Query*
---@return number amount
function Events.GreatPeoplePointsChanged.Count() end
---*Action*
function Events.GreatPeoplePointsChanged.RemoveAll() end
---*Action*
function Events.GreatPeoplePointsChanged.Dispatch() end
Events.GreatPeoplePointsChanged = {}
---*Query*
---@return number amount
function Events.GreatPeoplePointsChanged.Count() end
---*Action*
function Events.GreatPeoplePointsChanged.RemoveAll() end
---*Action*
function Events.GreatPeoplePointsChanged.Dispatch() end
---*Action*
---@param playerID number
function Events.GreatPeoplePointsChanged.Call(playerID) end
---*Action*
---@param playerID number
function Events.GreatPeoplePointsChanged.CallImmediate(playerID) end
---*Action*
---@param func fun(playerID: number)
---@return fun(playerID: number)
function Events.GreatPeoplePointsChanged.Add(func) end
---*Action*
---@param func function
function Events.GreatPeoplePointsChanged.Remove(func) end

---@overload fun()
Events.GreatPeopleTimelineChanged = {}
---*Query*
---@return number amount
function Events.GreatPeopleTimelineChanged.Count() end
---*Action*
function Events.GreatPeopleTimelineChanged.RemoveAll() end
---*Action*
function Events.GreatPeopleTimelineChanged.Dispatch() end
Events.GreatPeopleTimelineChanged = {}
---*Query*
---@return number amount
function Events.GreatPeopleTimelineChanged.Count() end
---*Action*
function Events.GreatPeopleTimelineChanged.RemoveAll() end
---*Action*
function Events.GreatPeopleTimelineChanged.Dispatch() end
---*Action*
function Events.GreatPeopleTimelineChanged.Call() end
---*Action*
function Events.GreatPeopleTimelineChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.GreatPeopleTimelineChanged.Add(func) end
---*Action*
---@param func function
function Events.GreatPeopleTimelineChanged.Remove(func) end

---@overload fun(playerID: number, unitID: number, cityPlotX: number, cityPlotY: number, buildingID: number, greatWorkID: number)
Events.GreatWorkCreated = {}
---*Query*
---@return number amount
function Events.GreatWorkCreated.Count() end
---*Action*
function Events.GreatWorkCreated.RemoveAll() end
---*Action*
function Events.GreatWorkCreated.Dispatch() end
Events.GreatWorkCreated = {}
---*Query*
---@return number amount
function Events.GreatWorkCreated.Count() end
---*Action*
function Events.GreatWorkCreated.RemoveAll() end
---*Action*
function Events.GreatWorkCreated.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
---@param cityPlotX number
---@param cityPlotY number
---@param buildingID number
---@param greatWorkID number
function Events.GreatWorkCreated.Call(playerID, unitID, cityPlotX, cityPlotY, buildingID, greatWorkID) end
---*Action*
---@param playerID number
---@param unitID number
---@param cityPlotX number
---@param cityPlotY number
---@param buildingID number
---@param greatWorkID number
function Events.GreatWorkCreated.CallImmediate(playerID, unitID, cityPlotX, cityPlotY, buildingID, greatWorkID) end
---*Action*
---@param func fun(playerID: number, unitID: number, cityPlotX: number, cityPlotY: number, buildingID: number, greatWorkID: number)
---@return fun(playerID: number, unitID: number, cityPlotX: number, cityPlotY: number, buildingID: number, greatWorkID: number)
function Events.GreatWorkCreated.Add(func) end
---*Action*
---@param func function
function Events.GreatWorkCreated.Remove(func) end

---@overload fun(fromCityPlayerID: number, fromCityID: number, toCityPlayerID: number, toCityID: number, buildingID: number, greatWorkTypeIndex: number)
Events.GreatWorkMoved = {}
---*Query*
---@return number amount
function Events.GreatWorkMoved.Count() end
---*Action*
function Events.GreatWorkMoved.RemoveAll() end
---*Action*
function Events.GreatWorkMoved.Dispatch() end
Events.GreatWorkMoved = {}
---*Query*
---@return number amount
function Events.GreatWorkMoved.Count() end
---*Action*
function Events.GreatWorkMoved.RemoveAll() end
---*Action*
function Events.GreatWorkMoved.Dispatch() end
---*Action*
---@param fromCityPlayerID number
---@param fromCityID number
---@param toCityPlayerID number
---@param toCityID number
---@param buildingID number
---@param greatWorkTypeIndex number
function Events.GreatWorkMoved.Call(fromCityPlayerID, fromCityID, toCityPlayerID, toCityID, buildingID, greatWorkTypeIndex) end
---*Action*
---@param fromCityPlayerID number
---@param fromCityID number
---@param toCityPlayerID number
---@param toCityID number
---@param buildingID number
---@param greatWorkTypeIndex number
function Events.GreatWorkMoved.CallImmediate(fromCityPlayerID, fromCityID, toCityPlayerID, toCityID, buildingID, greatWorkTypeIndex) end
---*Action*
---@param func fun(fromCityPlayerID: number, fromCityID: number, toCityPlayerID: number, toCityID: number, buildingID: number, greatWorkTypeIndex: number)
---@return fun(fromCityPlayerID: number, fromCityID: number, toCityPlayerID: number, toCityID: number, buildingID: number, greatWorkTypeIndex: number)
function Events.GreatWorkMoved.Add(func) end
---*Action*
---@param func function
function Events.GreatWorkMoved.Remove(func) end

---@overload fun(X: number, Y: number, unitOwner: any, unitID: number, improvementType: any, improvementOwner: any, activationType: any)
Events.ImprovementActivated = {}
---*Query*
---@return number amount
function Events.ImprovementActivated.Count() end
---*Action*
function Events.ImprovementActivated.RemoveAll() end
---*Action*
function Events.ImprovementActivated.Dispatch() end
Events.ImprovementActivated = {}
---*Query*
---@return number amount
function Events.ImprovementActivated.Count() end
---*Action*
function Events.ImprovementActivated.RemoveAll() end
---*Action*
function Events.ImprovementActivated.Dispatch() end
---*Action*
---@param X number
---@param Y number
---@param unitOwner any
---@param unitID number
---@param improvementType any
---@param improvementOwner any
---@param activationType any
function Events.ImprovementActivated.Call(X, Y, unitOwner, unitID, improvementType, improvementOwner, activationType) end
---*Action*
---@param X number
---@param Y number
---@param unitOwner any
---@param unitID number
---@param improvementType any
---@param improvementOwner any
---@param activationType any
function Events.ImprovementActivated.CallImmediate(X, Y, unitOwner, unitID, improvementType, improvementOwner, activationType) end
---*Action*
---@param func fun(X: number, Y: number, unitOwner: any, unitID: number, improvementType: any, improvementOwner: any, activationType: any)
---@return fun(X: number, Y: number, unitOwner: any, unitID: number, improvementType: any, improvementOwner: any, activationType: any)
function Events.ImprovementActivated.Add(func) end
---*Action*
---@param func function
function Events.ImprovementActivated.Remove(func) end

---@overload fun(X: number, Y: number, improvementIndex: number, playerID: number)
Events.ImprovementAddedToMap = {}
---*Query*
---@return number amount
function Events.ImprovementAddedToMap.Count() end
---*Action*
function Events.ImprovementAddedToMap.RemoveAll() end
---*Action*
function Events.ImprovementAddedToMap.Dispatch() end
Events.ImprovementAddedToMap = {}
---*Query*
---@return number amount
function Events.ImprovementAddedToMap.Count() end
---*Action*
function Events.ImprovementAddedToMap.RemoveAll() end
---*Action*
function Events.ImprovementAddedToMap.Dispatch() end
---*Action*
---@param X number
---@param Y number
---@param improvementIndex number
---@param playerID number
function Events.ImprovementAddedToMap.Call(X, Y, improvementIndex, playerID) end
---*Action*
---@param X number
---@param Y number
---@param improvementIndex number
---@param playerID number
function Events.ImprovementAddedToMap.CallImmediate(X, Y, improvementIndex, playerID) end
---*Action*
---@param func fun(X: number, Y: number, improvementIndex: number, playerID: number)
---@return fun(X: number, Y: number, improvementIndex: number, playerID: number)
function Events.ImprovementAddedToMap.Add(func) end
---*Action*
---@param func function
function Events.ImprovementAddedToMap.Remove(func) end

---@overload fun(X: number, Y: number, improvementIndex: number, improvementPlayerID: number, resourceIndex: number, isPillaged: boolean, isWorked: boolean)
Events.ImprovementChanged = {}
---*Query*
---@return number amount
function Events.ImprovementChanged.Count() end
---*Action*
function Events.ImprovementChanged.RemoveAll() end
---*Action*
function Events.ImprovementChanged.Dispatch() end
Events.ImprovementChanged = {}
---*Query*
---@return number amount
function Events.ImprovementChanged.Count() end
---*Action*
function Events.ImprovementChanged.RemoveAll() end
---*Action*
function Events.ImprovementChanged.Dispatch() end
---*Action*
---@param X number
---@param Y number
---@param improvementIndex number
---@param improvementPlayerID number
---@param resourceIndex number
---@param isPillaged boolean
---@param isWorked boolean
function Events.ImprovementChanged.Call(X, Y, improvementIndex, improvementPlayerID, resourceIndex, isPillaged, isWorked) end
---*Action*
---@param X number
---@param Y number
---@param improvementIndex number
---@param improvementPlayerID number
---@param resourceIndex number
---@param isPillaged boolean
---@param isWorked boolean
function Events.ImprovementChanged.CallImmediate(X, Y, improvementIndex, improvementPlayerID, resourceIndex, isPillaged, isWorked) end
---*Action*
---@param func fun(X: number, Y: number, improvementIndex: number, improvementPlayerID: number, resourceIndex: number, isPillaged: boolean, isWorked: boolean)
---@return fun(X: number, Y: number, improvementIndex: number, improvementPlayerID: number, resourceIndex: number, isPillaged: boolean, isWorked: boolean)
function Events.ImprovementChanged.Add(func) end
---*Action*
---@param func function
function Events.ImprovementChanged.Remove(func) end

---@overload fun()
Events.ImprovementOwnershipChanged = {}
---*Query*
---@return number amount
function Events.ImprovementOwnershipChanged.Count() end
---*Action*
function Events.ImprovementOwnershipChanged.RemoveAll() end
---*Action*
function Events.ImprovementOwnershipChanged.Dispatch() end
Events.ImprovementOwnershipChanged = {}
---*Query*
---@return number amount
function Events.ImprovementOwnershipChanged.Count() end
---*Action*
function Events.ImprovementOwnershipChanged.RemoveAll() end
---*Action*
function Events.ImprovementOwnershipChanged.Dispatch() end
---*Action*
function Events.ImprovementOwnershipChanged.Call() end
---*Action*
function Events.ImprovementOwnershipChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.ImprovementOwnershipChanged.Add(func) end
---*Action*
---@param func function
function Events.ImprovementOwnershipChanged.Remove(func) end

---@overload fun(X: number, Y: number, owningPlayerID: number)
Events.ImprovementRemovedFromMap = {}
---*Query*
---@return number amount
function Events.ImprovementRemovedFromMap.Count() end
---*Action*
function Events.ImprovementRemovedFromMap.RemoveAll() end
---*Action*
function Events.ImprovementRemovedFromMap.Dispatch() end
Events.ImprovementRemovedFromMap = {}
---*Query*
---@return number amount
function Events.ImprovementRemovedFromMap.Count() end
---*Action*
function Events.ImprovementRemovedFromMap.RemoveAll() end
---*Action*
function Events.ImprovementRemovedFromMap.Dispatch() end
---*Action*
---@param X number
---@param Y number
---@param owningPlayerID number
function Events.ImprovementRemovedFromMap.Call(X, Y, owningPlayerID) end
---*Action*
---@param X number
---@param Y number
---@param owningPlayerID number
function Events.ImprovementRemovedFromMap.CallImmediate(X, Y, owningPlayerID) end
---*Action*
---@param func fun(X: number, Y: number, owningPlayerID: number)
---@return fun(X: number, Y: number, owningPlayerID: number)
function Events.ImprovementRemovedFromMap.Add(func) end
---*Action*
---@param func function
function Events.ImprovementRemovedFromMap.Remove(func) end

---@overload fun(X: number, Y: number, improvementIndex: number, eVisibility: number)
Events.ImprovementVisibilityChanged = {}
---*Query*
---@return number amount
function Events.ImprovementVisibilityChanged.Count() end
---*Action*
function Events.ImprovementVisibilityChanged.RemoveAll() end
---*Action*
function Events.ImprovementVisibilityChanged.Dispatch() end
Events.ImprovementVisibilityChanged = {}
---*Query*
---@return number amount
function Events.ImprovementVisibilityChanged.Count() end
---*Action*
function Events.ImprovementVisibilityChanged.RemoveAll() end
---*Action*
function Events.ImprovementVisibilityChanged.Dispatch() end
---*Action*
---@param X number
---@param Y number
---@param improvementIndex number
---@param eVisibility number
function Events.ImprovementVisibilityChanged.Call(X, Y, improvementIndex, eVisibility) end
---*Action*
---@param X number
---@param Y number
---@param improvementIndex number
---@param eVisibility number
function Events.ImprovementVisibilityChanged.CallImmediate(X, Y, improvementIndex, eVisibility) end
---*Action*
---@param func fun(X: number, Y: number, improvementIndex: number, eVisibility: number)
---@return fun(X: number, Y: number, improvementIndex: number, eVisibility: number)
function Events.ImprovementVisibilityChanged.Add(func) end
---*Action*
---@param func function
function Events.ImprovementVisibilityChanged.Remove(func) end

---@overload fun()
Events.InfluenceChanged = {}
---*Query*
---@return number amount
function Events.InfluenceChanged.Count() end
---*Action*
function Events.InfluenceChanged.RemoveAll() end
---*Action*
function Events.InfluenceChanged.Dispatch() end
Events.InfluenceChanged = {}
---*Query*
---@return number amount
function Events.InfluenceChanged.Count() end
---*Action*
function Events.InfluenceChanged.RemoveAll() end
---*Action*
function Events.InfluenceChanged.Dispatch() end
---*Action*
function Events.InfluenceChanged.Call() end
---*Action*
function Events.InfluenceChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.InfluenceChanged.Add(func) end
---*Action*
---@param func function
function Events.InfluenceChanged.Remove(func) end

---@overload fun(citystateID: number, playerID: number)
Events.InfluenceGiven = {}
---*Query*
---@return number amount
function Events.InfluenceGiven.Count() end
---*Action*
function Events.InfluenceGiven.RemoveAll() end
---*Action*
function Events.InfluenceGiven.Dispatch() end
Events.InfluenceGiven = {}
---*Query*
---@return number amount
function Events.InfluenceGiven.Count() end
---*Action*
function Events.InfluenceGiven.RemoveAll() end
---*Action*
function Events.InfluenceGiven.Dispatch() end
---*Action*
---@param citystateID number
---@param playerID number
function Events.InfluenceGiven.Call(citystateID, playerID) end
---*Action*
---@param citystateID number
---@param playerID number
function Events.InfluenceGiven.CallImmediate(citystateID, playerID) end
---*Action*
---@param func fun(citystateID: number, playerID: number)
---@return fun(citystateID: number, playerID: number)
function Events.InfluenceGiven.Add(func) end
---*Action*
---@param func function
function Events.InfluenceGiven.Remove(func) end

---@overload fun(originalOwnerID: number)
Events.LevyCounterChanged = {}
---*Query*
---@return number amount
function Events.LevyCounterChanged.Count() end
---*Action*
function Events.LevyCounterChanged.RemoveAll() end
---*Action*
function Events.LevyCounterChanged.Dispatch() end
Events.LevyCounterChanged = {}
---*Query*
---@return number amount
function Events.LevyCounterChanged.Count() end
---*Action*
function Events.LevyCounterChanged.RemoveAll() end
---*Action*
function Events.LevyCounterChanged.Dispatch() end
---*Action*
---@param originalOwnerID number
function Events.LevyCounterChanged.Call(originalOwnerID) end
---*Action*
---@param originalOwnerID number
function Events.LevyCounterChanged.CallImmediate(originalOwnerID) end
---*Action*
---@param func fun(originalOwnerID: number)
---@return fun(originalOwnerID: number)
function Events.LevyCounterChanged.Add(func) end
---*Action*
---@param func function
function Events.LevyCounterChanged.Remove(func) end

---@overload fun(localPlayerID: number, prevLocalPlayerID: number)
Events.LocalPlayerChanged = {}
---*Query*
---@return number amount
function Events.LocalPlayerChanged.Count() end
---*Action*
function Events.LocalPlayerChanged.RemoveAll() end
---*Action*
function Events.LocalPlayerChanged.Dispatch() end
Events.LocalPlayerChanged = {}
---*Query*
---@return number amount
function Events.LocalPlayerChanged.Count() end
---*Action*
function Events.LocalPlayerChanged.RemoveAll() end
---*Action*
function Events.LocalPlayerChanged.Dispatch() end
---*Action*
---@param localPlayerID number
---@param prevLocalPlayerID number
function Events.LocalPlayerChanged.Call(localPlayerID, prevLocalPlayerID) end
---*Action*
---@param localPlayerID number
---@param prevLocalPlayerID number
function Events.LocalPlayerChanged.CallImmediate(localPlayerID, prevLocalPlayerID) end
---*Action*
---@param func fun(localPlayerID: number, prevLocalPlayerID: number)
---@return fun(localPlayerID: number, prevLocalPlayerID: number)
function Events.LocalPlayerChanged.Add(func) end
---*Action*
---@param func function
function Events.LocalPlayerChanged.Remove(func) end

---@overload fun()
Events.LocalPlayerTurnBegin = {}
---*Query*
---@return number amount
function Events.LocalPlayerTurnBegin.Count() end
---*Action*
function Events.LocalPlayerTurnBegin.RemoveAll() end
---*Action*
function Events.LocalPlayerTurnBegin.Dispatch() end
Events.LocalPlayerTurnBegin = {}
---*Query*
---@return number amount
function Events.LocalPlayerTurnBegin.Count() end
---*Action*
function Events.LocalPlayerTurnBegin.RemoveAll() end
---*Action*
function Events.LocalPlayerTurnBegin.Dispatch() end
---*Action*
function Events.LocalPlayerTurnBegin.Call() end
---*Action*
function Events.LocalPlayerTurnBegin.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.LocalPlayerTurnBegin.Add(func) end
---*Action*
---@param func function
function Events.LocalPlayerTurnBegin.Remove(func) end

---@overload fun()
Events.LocalPlayerTurnEnd = {}
---*Query*
---@return number amount
function Events.LocalPlayerTurnEnd.Count() end
---*Action*
function Events.LocalPlayerTurnEnd.RemoveAll() end
---*Action*
function Events.LocalPlayerTurnEnd.Dispatch() end
Events.LocalPlayerTurnEnd = {}
---*Query*
---@return number amount
function Events.LocalPlayerTurnEnd.Count() end
---*Action*
function Events.LocalPlayerTurnEnd.RemoveAll() end
---*Action*
function Events.LocalPlayerTurnEnd.Dispatch() end
---*Action*
function Events.LocalPlayerTurnEnd.Call() end
---*Action*
function Events.LocalPlayerTurnEnd.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.LocalPlayerTurnEnd.Add(func) end
---*Action*
---@param func function
function Events.LocalPlayerTurnEnd.Remove(func) end

---@overload fun()
Events.LocalPlayerTurnUnready = {}
---*Query*
---@return number amount
function Events.LocalPlayerTurnUnready.Count() end
---*Action*
function Events.LocalPlayerTurnUnready.RemoveAll() end
---*Action*
function Events.LocalPlayerTurnUnready.Dispatch() end
Events.LocalPlayerTurnUnready = {}
---*Query*
---@return number amount
function Events.LocalPlayerTurnUnready.Count() end
---*Action*
function Events.LocalPlayerTurnUnready.RemoveAll() end
---*Action*
function Events.LocalPlayerTurnUnready.Dispatch() end
---*Action*
function Events.LocalPlayerTurnUnready.Call() end
---*Action*
function Events.LocalPlayerTurnUnready.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.LocalPlayerTurnUnready.Add(func) end
---*Action*
---@param func function
function Events.LocalPlayerTurnUnready.Remove(func) end

---@overload fun()
Events.MapYieldsChanged = {}
---*Query*
---@return number amount
function Events.MapYieldsChanged.Count() end
---*Action*
function Events.MapYieldsChanged.RemoveAll() end
---*Action*
function Events.MapYieldsChanged.Dispatch() end
Events.MapYieldsChanged = {}
---*Query*
---@return number amount
function Events.MapYieldsChanged.Count() end
---*Action*
function Events.MapYieldsChanged.RemoveAll() end
---*Action*
function Events.MapYieldsChanged.Dispatch() end
---*Action*
function Events.MapYieldsChanged.Call() end
---*Action*
function Events.MapYieldsChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.MapYieldsChanged.Add(func) end
---*Action*
---@param func function
function Events.MapYieldsChanged.Remove(func) end

---@overload fun()
Events.NationalParkAdded = {}
---*Query*
---@return number amount
function Events.NationalParkAdded.Count() end
---*Action*
function Events.NationalParkAdded.RemoveAll() end
---*Action*
function Events.NationalParkAdded.Dispatch() end
Events.NationalParkAdded = {}
---*Query*
---@return number amount
function Events.NationalParkAdded.Count() end
---*Action*
function Events.NationalParkAdded.RemoveAll() end
---*Action*
function Events.NationalParkAdded.Dispatch() end
---*Action*
function Events.NationalParkAdded.Call() end
---*Action*
function Events.NationalParkAdded.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.NationalParkAdded.Add(func) end
---*Action*
---@param func function
function Events.NationalParkAdded.Remove(func) end

---@overload fun()
Events.NationalParkRemoved = {}
---*Query*
---@return number amount
function Events.NationalParkRemoved.Count() end
---*Action*
function Events.NationalParkRemoved.RemoveAll() end
---*Action*
function Events.NationalParkRemoved.Dispatch() end
Events.NationalParkRemoved = {}
---*Query*
---@return number amount
function Events.NationalParkRemoved.Count() end
---*Action*
function Events.NationalParkRemoved.RemoveAll() end
---*Action*
function Events.NationalParkRemoved.Dispatch() end
---*Action*
function Events.NationalParkRemoved.Call() end
---*Action*
function Events.NationalParkRemoved.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.NationalParkRemoved.Add(func) end
---*Action*
---@param func function
function Events.NationalParkRemoved.Remove(func) end

---@overload fun()
Events.NationalParkVisibilityChanged = {}
---*Query*
---@return number amount
function Events.NationalParkVisibilityChanged.Count() end
---*Action*
function Events.NationalParkVisibilityChanged.RemoveAll() end
---*Action*
function Events.NationalParkVisibilityChanged.Dispatch() end
Events.NationalParkVisibilityChanged = {}
---*Query*
---@return number amount
function Events.NationalParkVisibilityChanged.Count() end
---*Action*
function Events.NationalParkVisibilityChanged.RemoveAll() end
---*Action*
function Events.NationalParkVisibilityChanged.Dispatch() end
---*Action*
function Events.NationalParkVisibilityChanged.Call() end
---*Action*
function Events.NationalParkVisibilityChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.NationalParkVisibilityChanged.Add(func) end
---*Action*
---@param func function
function Events.NationalParkVisibilityChanged.Remove(func) end

---@overload fun(X: number, Y: number, featureIndex: number, wasFirstToFind: boolean)
Events.NaturalWonderRevealed = {}
---*Query*
---@return number amount
function Events.NaturalWonderRevealed.Count() end
---*Action*
function Events.NaturalWonderRevealed.RemoveAll() end
---*Action*
function Events.NaturalWonderRevealed.Dispatch() end
Events.NaturalWonderRevealed = {}
---*Query*
---@return number amount
function Events.NaturalWonderRevealed.Count() end
---*Action*
function Events.NaturalWonderRevealed.RemoveAll() end
---*Action*
function Events.NaturalWonderRevealed.Dispatch() end
---*Action*
---@param X number
---@param Y number
---@param featureIndex number
---@param wasFirstToFind boolean
function Events.NaturalWonderRevealed.Call(X, Y, featureIndex, wasFirstToFind) end
---*Action*
---@param X number
---@param Y number
---@param featureIndex number
---@param wasFirstToFind boolean
function Events.NaturalWonderRevealed.CallImmediate(X, Y, featureIndex, wasFirstToFind) end
---*Action*
---@param func fun(X: number, Y: number, featureIndex: number, wasFirstToFind: boolean)
---@return fun(X: number, Y: number, featureIndex: number, wasFirstToFind: boolean)
function Events.NaturalWonderRevealed.Add(func) end
---*Action*
---@param func function
function Events.NaturalWonderRevealed.Remove(func) end

---@overload fun(playerID: number, notificationID: number, wasActivatedByUser: boolean)
Events.NotificationActivated = {}
---*Query*
---@return number amount
function Events.NotificationActivated.Count() end
---*Action*
function Events.NotificationActivated.RemoveAll() end
---*Action*
function Events.NotificationActivated.Dispatch() end
Events.NotificationActivated = {}
---*Query*
---@return number amount
function Events.NotificationActivated.Count() end
---*Action*
function Events.NotificationActivated.RemoveAll() end
---*Action*
function Events.NotificationActivated.Dispatch() end
---*Action*
---@param playerID number
---@param notificationID number
---@param wasActivatedByUser boolean
function Events.NotificationActivated.Call(playerID, notificationID, wasActivatedByUser) end
---*Action*
---@param playerID number
---@param notificationID number
---@param wasActivatedByUser boolean
function Events.NotificationActivated.CallImmediate(playerID, notificationID, wasActivatedByUser) end
---*Action*
---@param func fun(playerID: number, notificationID: number, wasActivatedByUser: boolean)
---@return fun(playerID: number, notificationID: number, wasActivatedByUser: boolean)
function Events.NotificationActivated.Add(func) end
---*Action*
---@param func function
function Events.NotificationActivated.Remove(func) end

---@overload fun(playerID: number, notificationID: number)
Events.NotificationAdded = {}
---*Query*
---@return number amount
function Events.NotificationAdded.Count() end
---*Action*
function Events.NotificationAdded.RemoveAll() end
---*Action*
function Events.NotificationAdded.Dispatch() end
Events.NotificationAdded = {}
---*Query*
---@return number amount
function Events.NotificationAdded.Count() end
---*Action*
function Events.NotificationAdded.RemoveAll() end
---*Action*
function Events.NotificationAdded.Dispatch() end
---*Action*
---@param playerID number
---@param notificationID number
function Events.NotificationAdded.Call(playerID, notificationID) end
---*Action*
---@param playerID number
---@param notificationID number
function Events.NotificationAdded.CallImmediate(playerID, notificationID) end
---*Action*
---@param func fun(playerID: number, notificationID: number)
---@return fun(playerID: number, notificationID: number)
function Events.NotificationAdded.Add(func) end
---*Action*
---@param func function
function Events.NotificationAdded.Remove(func) end

---@overload fun(playerID: number, notificationID: number)
Events.NotificationDismissed = {}
---*Query*
---@return number amount
function Events.NotificationDismissed.Count() end
---*Action*
function Events.NotificationDismissed.RemoveAll() end
---*Action*
function Events.NotificationDismissed.Dispatch() end
Events.NotificationDismissed = {}
---*Query*
---@return number amount
function Events.NotificationDismissed.Count() end
---*Action*
function Events.NotificationDismissed.RemoveAll() end
---*Action*
function Events.NotificationDismissed.Dispatch() end
---*Action*
---@param playerID number
---@param notificationID number
function Events.NotificationDismissed.Call(playerID, notificationID) end
---*Action*
---@param playerID number
---@param notificationID number
function Events.NotificationDismissed.CallImmediate(playerID, notificationID) end
---*Action*
---@param func fun(playerID: number, notificationID: number)
---@return fun(playerID: number, notificationID: number)
function Events.NotificationDismissed.Add(func) end
---*Action*
---@param func function
function Events.NotificationDismissed.Remove(func) end

---@overload fun()
Events.NotificationRefreshRequested = {}
---*Query*
---@return number amount
function Events.NotificationRefreshRequested.Count() end
---*Action*
function Events.NotificationRefreshRequested.RemoveAll() end
---*Action*
function Events.NotificationRefreshRequested.Dispatch() end
Events.NotificationRefreshRequested = {}
---*Query*
---@return number amount
function Events.NotificationRefreshRequested.Count() end
---*Action*
function Events.NotificationRefreshRequested.RemoveAll() end
---*Action*
function Events.NotificationRefreshRequested.Dispatch() end
---*Action*
function Events.NotificationRefreshRequested.Call() end
---*Action*
function Events.NotificationRefreshRequested.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.NotificationRefreshRequested.Add(func) end
---*Action*
---@param func function
function Events.NotificationRefreshRequested.Remove(func) end

---@overload fun(eventSubType: EventSubTypes, parentOwner: any, parentType: any, parentID: number, childOwner: any, childType: any, childID: number)
Events.ObjectPairing = {}
---*Query*
---@return number amount
function Events.ObjectPairing.Count() end
---*Action*
function Events.ObjectPairing.RemoveAll() end
---*Action*
function Events.ObjectPairing.Dispatch() end
Events.ObjectPairing = {}
---*Query*
---@return number amount
function Events.ObjectPairing.Count() end
---*Action*
function Events.ObjectPairing.RemoveAll() end
---*Action*
function Events.ObjectPairing.Dispatch() end
---*Action*
---@param eventSubType EventSubTypes
---@param parentOwner any
---@param parentType any
---@param parentID number
---@param childOwner any
---@param childType any
---@param childID number
function Events.ObjectPairing.Call(eventSubType, parentOwner, parentType, parentID, childOwner, childType, childID) end
---*Action*
---@param eventSubType EventSubTypes
---@param parentOwner any
---@param parentType any
---@param parentID number
---@param childOwner any
---@param childType any
---@param childID number
function Events.ObjectPairing.CallImmediate(eventSubType, parentOwner, parentType, parentID, childOwner, childType, childID) end
---*Action*
---@param func fun(eventSubType: EventSubTypes, parentOwner: any, parentType: any, parentID: number, childOwner: any, childType: any, childID: number)
---@return fun(eventSubType: EventSubTypes, parentOwner: any, parentType: any, parentID: number, childOwner: any, childType: any, childID: number)
function Events.ObjectPairing.Add(func) end
---*Action*
---@param func function
function Events.ObjectPairing.Remove(func) end

---@overload fun()
Events.OnAiAdvisorUpdated = {}
---*Query*
---@return number amount
function Events.OnAiAdvisorUpdated.Count() end
---*Action*
function Events.OnAiAdvisorUpdated.RemoveAll() end
---*Action*
function Events.OnAiAdvisorUpdated.Dispatch() end
Events.OnAiAdvisorUpdated = {}
---*Query*
---@return number amount
function Events.OnAiAdvisorUpdated.Count() end
---*Action*
function Events.OnAiAdvisorUpdated.RemoveAll() end
---*Action*
function Events.OnAiAdvisorUpdated.Dispatch() end
---*Action*
function Events.OnAiAdvisorUpdated.Call() end
---*Action*
function Events.OnAiAdvisorUpdated.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.OnAiAdvisorUpdated.Add(func) end
---*Action*
---@param func function
function Events.OnAiAdvisorUpdated.Remove(func) end

---@overload fun(unitOwner: number, unitID: number, greatPersonClassID: number, greatPersonIndividualID: number)
Events.UnitGreatPersonActivated = {}
---*Query*
---@return number amount
function Events.UnitGreatPersonActivated.Count() end
---*Action*
function Events.UnitGreatPersonActivated.RemoveAll() end
---*Action*
function Events.UnitGreatPersonActivated.Dispatch() end
Events.UnitGreatPersonActivated = {}
---*Query*
---@return number amount
function Events.UnitGreatPersonActivated.Count() end
---*Action*
function Events.UnitGreatPersonActivated.RemoveAll() end
---*Action*
function Events.UnitGreatPersonActivated.Dispatch() end
---*Action*
---@param unitOwner number
---@param unitID number
---@param greatPersonClassID number
---@param greatPersonIndividualID number
function Events.UnitGreatPersonActivated.Call(unitOwner, unitID, greatPersonClassID, greatPersonIndividualID) end
---*Action*
---@param unitOwner number
---@param unitID number
---@param greatPersonClassID number
---@param greatPersonIndividualID number
function Events.UnitGreatPersonActivated.CallImmediate(unitOwner, unitID, greatPersonClassID, greatPersonIndividualID) end
---*Action*
---@param func fun(unitOwner: number, unitID: number, greatPersonClassID: number, greatPersonIndividualID: number)
---@return fun(unitOwner: number, unitID: number, greatPersonClassID: number, greatPersonIndividualID: number)
function Events.UnitGreatPersonActivated.Add(func) end
---*Action*
---@param func function
function Events.UnitGreatPersonActivated.Remove(func) end

---@overload fun(playerID: any)
Events.PantheonFounded = {}
---*Query*
---@return number amount
function Events.PantheonFounded.Count() end
---*Action*
function Events.PantheonFounded.RemoveAll() end
---*Action*
function Events.PantheonFounded.Dispatch() end
Events.PantheonFounded = {}
---*Query*
---@return number amount
function Events.PantheonFounded.Count() end
---*Action*
function Events.PantheonFounded.RemoveAll() end
---*Action*
function Events.PantheonFounded.Dispatch() end
---*Action*
---@param playerID any
function Events.PantheonFounded.Call(playerID) end
---*Action*
---@param playerID any
function Events.PantheonFounded.CallImmediate(playerID) end
---*Action*
---@param func fun(playerID: any)
---@return fun(playerID: any)
function Events.PantheonFounded.Add(func) end
---*Action*
---@param func function
function Events.PantheonFounded.Remove(func) end

---@overload fun()
Events.PhaseBegin = {}
---*Query*
---@return number amount
function Events.PhaseBegin.Count() end
---*Action*
function Events.PhaseBegin.RemoveAll() end
---*Action*
function Events.PhaseBegin.Dispatch() end
Events.PhaseBegin = {}
---*Query*
---@return number amount
function Events.PhaseBegin.Count() end
---*Action*
function Events.PhaseBegin.RemoveAll() end
---*Action*
function Events.PhaseBegin.Dispatch() end
---*Action*
function Events.PhaseBegin.Call() end
---*Action*
function Events.PhaseBegin.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.PhaseBegin.Add(func) end
---*Action*
---@param func function
function Events.PhaseBegin.Remove(func) end

---@overload fun()
Events.PhaseEnd = {}
---*Query*
---@return number amount
function Events.PhaseEnd.Count() end
---*Action*
function Events.PhaseEnd.RemoveAll() end
---*Action*
function Events.PhaseEnd.Dispatch() end
Events.PhaseEnd = {}
---*Query*
---@return number amount
function Events.PhaseEnd.Count() end
---*Action*
function Events.PhaseEnd.RemoveAll() end
---*Action*
function Events.PhaseEnd.Dispatch() end
---*Action*
function Events.PhaseEnd.Call() end
---*Action*
function Events.PhaseEnd.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.PhaseEnd.Add(func) end
---*Action*
---@param func function
function Events.PhaseEnd.Remove(func) end

---@overload fun(playerID: number)
Events.PlayerAgeChanged = {}
---*Query*
---@return number amount
function Events.PlayerAgeChanged.Count() end
---*Action*
function Events.PlayerAgeChanged.RemoveAll() end
---*Action*
function Events.PlayerAgeChanged.Dispatch() end
Events.PlayerAgeChanged = {}
---*Query*
---@return number amount
function Events.PlayerAgeChanged.Count() end
---*Action*
function Events.PlayerAgeChanged.RemoveAll() end
---*Action*
function Events.PlayerAgeChanged.Dispatch() end
---*Action*
---@param playerID number
function Events.PlayerAgeChanged.Call(playerID) end
---*Action*
---@param playerID number
function Events.PlayerAgeChanged.CallImmediate(playerID) end
---*Action*
---@param func fun(playerID: number)
---@return fun(playerID: number)
function Events.PlayerAgeChanged.Add(func) end
---*Action*
---@param func function
function Events.PlayerAgeChanged.Remove(func) end

---@overload fun()
Events.PlayerBordersChanged = {}
---*Query*
---@return number amount
function Events.PlayerBordersChanged.Count() end
---*Action*
function Events.PlayerBordersChanged.RemoveAll() end
---*Action*
function Events.PlayerBordersChanged.Dispatch() end
Events.PlayerBordersChanged = {}
---*Query*
---@return number amount
function Events.PlayerBordersChanged.Count() end
---*Action*
function Events.PlayerBordersChanged.RemoveAll() end
---*Action*
function Events.PlayerBordersChanged.Dispatch() end
---*Action*
function Events.PlayerBordersChanged.Call() end
---*Action*
function Events.PlayerBordersChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.PlayerBordersChanged.Add(func) end
---*Action*
---@param func function
function Events.PlayerBordersChanged.Remove(func) end

---@overload fun(playerID: number)
Events.PlayerDarkAgeChanged = {}
---*Query*
---@return number amount
function Events.PlayerDarkAgeChanged.Count() end
---*Action*
function Events.PlayerDarkAgeChanged.RemoveAll() end
---*Action*
function Events.PlayerDarkAgeChanged.Dispatch() end
Events.PlayerDarkAgeChanged = {}
---*Query*
---@return number amount
function Events.PlayerDarkAgeChanged.Count() end
---*Action*
function Events.PlayerDarkAgeChanged.RemoveAll() end
---*Action*
function Events.PlayerDarkAgeChanged.Dispatch() end
---*Action*
---@param playerID number
function Events.PlayerDarkAgeChanged.Call(playerID) end
---*Action*
---@param playerID number
function Events.PlayerDarkAgeChanged.CallImmediate(playerID) end
---*Action*
---@param func fun(playerID: number)
---@return fun(playerID: number)
function Events.PlayerDarkAgeChanged.Add(func) end
---*Action*
---@param func function
function Events.PlayerDarkAgeChanged.Remove(func) end

---@overload fun(playerID: number, defeatIndex: any, eventID: number)
Events.PlayerDefeat = {}
---*Query*
---@return number amount
function Events.PlayerDefeat.Count() end
---*Action*
function Events.PlayerDefeat.RemoveAll() end
---*Action*
function Events.PlayerDefeat.Dispatch() end
Events.PlayerDefeat = {}
---*Query*
---@return number amount
function Events.PlayerDefeat.Count() end
---*Action*
function Events.PlayerDefeat.RemoveAll() end
---*Action*
function Events.PlayerDefeat.Dispatch() end
---*Action*
---@param playerID number
---@param defeatIndex any
---@param eventID number
function Events.PlayerDefeat.Call(playerID, defeatIndex, eventID) end
---*Action*
---@param playerID number
---@param defeatIndex any
---@param eventID number
function Events.PlayerDefeat.CallImmediate(playerID, defeatIndex, eventID) end
---*Action*
---@param func fun(playerID: number, defeatIndex: any, eventID: number)
---@return fun(playerID: number, defeatIndex: any, eventID: number)
function Events.PlayerDefeat.Add(func) end
---*Action*
---@param func function
function Events.PlayerDefeat.Remove(func) end

---@overload fun()
Events.PlayerDestroyed = {}
---*Query*
---@return number amount
function Events.PlayerDestroyed.Count() end
---*Action*
function Events.PlayerDestroyed.RemoveAll() end
---*Action*
function Events.PlayerDestroyed.Dispatch() end
Events.PlayerDestroyed = {}
---*Query*
---@return number amount
function Events.PlayerDestroyed.Count() end
---*Action*
function Events.PlayerDestroyed.RemoveAll() end
---*Action*
function Events.PlayerDestroyed.Dispatch() end
---*Action*
function Events.PlayerDestroyed.Call() end
---*Action*
function Events.PlayerDestroyed.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.PlayerDestroyed.Add(func) end
---*Action*
---@param func function
function Events.PlayerDestroyed.Remove(func) end

---@overload fun(playerID: number, eraIndex: number)
Events.PlayerEraChanged = {}
---*Query*
---@return number amount
function Events.PlayerEraChanged.Count() end
---*Action*
function Events.PlayerEraChanged.RemoveAll() end
---*Action*
function Events.PlayerEraChanged.Dispatch() end
Events.PlayerEraChanged = {}
---*Query*
---@return number amount
function Events.PlayerEraChanged.Count() end
---*Action*
function Events.PlayerEraChanged.RemoveAll() end
---*Action*
function Events.PlayerEraChanged.Dispatch() end
---*Action*
---@param playerID number
---@param eraIndex number
function Events.PlayerEraChanged.Call(playerID, eraIndex) end
---*Action*
---@param playerID number
---@param eraIndex number
function Events.PlayerEraChanged.CallImmediate(playerID, eraIndex) end
---*Action*
---@param func fun(playerID: number, eraIndex: number)
---@return fun(playerID: number, eraIndex: number)
function Events.PlayerEraChanged.Add(func) end
---*Action*
---@param func function
function Events.PlayerEraChanged.Remove(func) end

---@overload fun(playerID: number, amountAwarded: number)
Events.PlayerEraScoreChanged = {}
---*Query*
---@return number amount
function Events.PlayerEraScoreChanged.Count() end
---*Action*
function Events.PlayerEraScoreChanged.RemoveAll() end
---*Action*
function Events.PlayerEraScoreChanged.Dispatch() end
Events.PlayerEraScoreChanged = {}
---*Query*
---@return number amount
function Events.PlayerEraScoreChanged.Count() end
---*Action*
function Events.PlayerEraScoreChanged.RemoveAll() end
---*Action*
function Events.PlayerEraScoreChanged.Dispatch() end
---*Action*
---@param playerID number
---@param amountAwarded number
function Events.PlayerEraScoreChanged.Call(playerID, amountAwarded) end
---*Action*
---@param playerID number
---@param amountAwarded number
function Events.PlayerEraScoreChanged.CallImmediate(playerID, amountAwarded) end
---*Action*
---@param func fun(playerID: number, amountAwarded: number)
---@return fun(playerID: number, amountAwarded: number)
function Events.PlayerEraScoreChanged.Add(func) end
---*Action*
---@param func function
function Events.PlayerEraScoreChanged.Remove(func) end

---@overload fun(playerID: number)
Events.PlayerEraTransitionBegins = {}
---*Query*
---@return number amount
function Events.PlayerEraTransitionBegins.Count() end
---*Action*
function Events.PlayerEraTransitionBegins.RemoveAll() end
---*Action*
function Events.PlayerEraTransitionBegins.Dispatch() end
Events.PlayerEraTransitionBegins = {}
---*Query*
---@return number amount
function Events.PlayerEraTransitionBegins.Count() end
---*Action*
function Events.PlayerEraTransitionBegins.RemoveAll() end
---*Action*
function Events.PlayerEraTransitionBegins.Dispatch() end
---*Action*
---@param playerID number
function Events.PlayerEraTransitionBegins.Call(playerID) end
---*Action*
---@param playerID number
function Events.PlayerEraTransitionBegins.CallImmediate(playerID) end
---*Action*
---@param func fun(playerID: number)
---@return fun(playerID: number)
function Events.PlayerEraTransitionBegins.Add(func) end
---*Action*
---@param func function
function Events.PlayerEraTransitionBegins.Remove(func) end

---@overload fun()
Events.PlayerOperationComplete = {}
---*Query*
---@return number amount
function Events.PlayerOperationComplete.Count() end
---*Action*
function Events.PlayerOperationComplete.RemoveAll() end
---*Action*
function Events.PlayerOperationComplete.Dispatch() end
Events.PlayerOperationComplete = {}
---*Query*
---@return number amount
function Events.PlayerOperationComplete.Count() end
---*Action*
function Events.PlayerOperationComplete.RemoveAll() end
---*Action*
function Events.PlayerOperationComplete.Dispatch() end
---*Action*
function Events.PlayerOperationComplete.Call() end
---*Action*
function Events.PlayerOperationComplete.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.PlayerOperationComplete.Add(func) end
---*Action*
---@param func function
function Events.PlayerOperationComplete.Remove(func) end

---@overload fun(ownerPlayerID: number, resourceTypeID: number)
Events.PlayerResourceChanged = {}
---*Query*
---@return number amount
function Events.PlayerResourceChanged.Count() end
---*Action*
function Events.PlayerResourceChanged.RemoveAll() end
---*Action*
function Events.PlayerResourceChanged.Dispatch() end
Events.PlayerResourceChanged = {}
---*Query*
---@return number amount
function Events.PlayerResourceChanged.Count() end
---*Action*
function Events.PlayerResourceChanged.RemoveAll() end
---*Action*
function Events.PlayerResourceChanged.Dispatch() end
---*Action*
---@param ownerPlayerID number
---@param resourceTypeID number
function Events.PlayerResourceChanged.Call(ownerPlayerID, resourceTypeID) end
---*Action*
---@param ownerPlayerID number
---@param resourceTypeID number
function Events.PlayerResourceChanged.CallImmediate(ownerPlayerID, resourceTypeID) end
---*Action*
---@param func fun(ownerPlayerID: number, resourceTypeID: number)
---@return fun(ownerPlayerID: number, resourceTypeID: number)
function Events.PlayerResourceChanged.Add(func) end
---*Action*
---@param func function
function Events.PlayerResourceChanged.Remove(func) end

---@overload fun()
Events.PlayerRestored = {}
---*Query*
---@return number amount
function Events.PlayerRestored.Count() end
---*Action*
function Events.PlayerRestored.RemoveAll() end
---*Action*
function Events.PlayerRestored.Dispatch() end
Events.PlayerRestored = {}
---*Query*
---@return number amount
function Events.PlayerRestored.Count() end
---*Action*
function Events.PlayerRestored.RemoveAll() end
---*Action*
function Events.PlayerRestored.Dispatch() end
---*Action*
function Events.PlayerRestored.Call() end
---*Action*
function Events.PlayerRestored.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.PlayerRestored.Add(func) end
---*Action*
---@param func function
function Events.PlayerRestored.Remove(func) end

---@overload fun()
Events.PlayerRevived = {}
---*Query*
---@return number amount
function Events.PlayerRevived.Count() end
---*Action*
function Events.PlayerRevived.RemoveAll() end
---*Action*
function Events.PlayerRevived.Dispatch() end
Events.PlayerRevived = {}
---*Query*
---@return number amount
function Events.PlayerRevived.Count() end
---*Action*
function Events.PlayerRevived.RemoveAll() end
---*Action*
function Events.PlayerRevived.Dispatch() end
---*Action*
function Events.PlayerRevived.Call() end
---*Action*
function Events.PlayerRevived.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.PlayerRevived.Add(func) end
---*Action*
---@param func function
function Events.PlayerRevived.Remove(func) end

---@overload fun(playerID: number, isFirstTurn: boolean)
Events.PlayerTurnActivated = {}
---*Query*
---@return number amount
function Events.PlayerTurnActivated.Count() end
---*Action*
function Events.PlayerTurnActivated.RemoveAll() end
---*Action*
function Events.PlayerTurnActivated.Dispatch() end
Events.PlayerTurnActivated = {}
---*Query*
---@return number amount
function Events.PlayerTurnActivated.Count() end
---*Action*
function Events.PlayerTurnActivated.RemoveAll() end
---*Action*
function Events.PlayerTurnActivated.Dispatch() end
---*Action*
---@param playerID number
---@param isFirstTurn boolean
function Events.PlayerTurnActivated.Call(playerID, isFirstTurn) end
---*Action*
---@param playerID number
---@param isFirstTurn boolean
function Events.PlayerTurnActivated.CallImmediate(playerID, isFirstTurn) end
---*Action*
---@param func fun(playerID: number, isFirstTurn: boolean)
---@return fun(playerID: number, isFirstTurn: boolean)
function Events.PlayerTurnActivated.Add(func) end
---*Action*
---@param func function
function Events.PlayerTurnActivated.Remove(func) end

---@overload fun(playerID: number)
Events.PlayerTurnDeactivated = {}
---*Query*
---@return number amount
function Events.PlayerTurnDeactivated.Count() end
---*Action*
function Events.PlayerTurnDeactivated.RemoveAll() end
---*Action*
function Events.PlayerTurnDeactivated.Dispatch() end
Events.PlayerTurnDeactivated = {}
---*Query*
---@return number amount
function Events.PlayerTurnDeactivated.Count() end
---*Action*
function Events.PlayerTurnDeactivated.RemoveAll() end
---*Action*
function Events.PlayerTurnDeactivated.Dispatch() end
---*Action*
---@param playerID number
function Events.PlayerTurnDeactivated.Call(playerID) end
---*Action*
---@param playerID number
function Events.PlayerTurnDeactivated.CallImmediate(playerID) end
---*Action*
---@param func fun(playerID: number)
---@return fun(playerID: number)
function Events.PlayerTurnDeactivated.Add(func) end
---*Action*
---@param func function
function Events.PlayerTurnDeactivated.Remove(func) end

---@overload fun()
Events.PlayerVictory = {}
---*Query*
---@return number amount
function Events.PlayerVictory.Count() end
---*Action*
function Events.PlayerVictory.RemoveAll() end
---*Action*
function Events.PlayerVictory.Dispatch() end
Events.PlayerVictory = {}
---*Query*
---@return number amount
function Events.PlayerVictory.Count() end
---*Action*
function Events.PlayerVictory.RemoveAll() end
---*Action*
function Events.PlayerVictory.Dispatch() end
---*Action*
function Events.PlayerVictory.Call() end
---*Action*
function Events.PlayerVictory.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.PlayerVictory.Add(func) end
---*Action*
---@param func function
function Events.PlayerVictory.Remove(func) end

---@overload fun()
Events.PlotAppealChanged = {}
---*Query*
---@return number amount
function Events.PlotAppealChanged.Count() end
---*Action*
function Events.PlotAppealChanged.RemoveAll() end
---*Action*
function Events.PlotAppealChanged.Dispatch() end
Events.PlotAppealChanged = {}
---*Query*
---@return number amount
function Events.PlotAppealChanged.Count() end
---*Action*
function Events.PlotAppealChanged.RemoveAll() end
---*Action*
function Events.PlotAppealChanged.Dispatch() end
---*Action*
function Events.PlotAppealChanged.Call() end
---*Action*
function Events.PlotAppealChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.PlotAppealChanged.Add(func) end
---*Action*
---@param func function
function Events.PlotAppealChanged.Remove(func) end

---@overload fun(X: number, Y: number)
Events.PlotMarkerChanged = {}
---*Query*
---@return number amount
function Events.PlotMarkerChanged.Count() end
---*Action*
function Events.PlotMarkerChanged.RemoveAll() end
---*Action*
function Events.PlotMarkerChanged.Dispatch() end
Events.PlotMarkerChanged = {}
---*Query*
---@return number amount
function Events.PlotMarkerChanged.Count() end
---*Action*
function Events.PlotMarkerChanged.RemoveAll() end
---*Action*
function Events.PlotMarkerChanged.Dispatch() end
---*Action*
---@param X number
---@param Y number
function Events.PlotMarkerChanged.Call(X, Y) end
---*Action*
---@param X number
---@param Y number
function Events.PlotMarkerChanged.CallImmediate(X, Y) end
---*Action*
---@param func fun(X: number, Y: number)
---@return fun(X: number, Y: number)
function Events.PlotMarkerChanged.Add(func) end
---*Action*
---@param func function
function Events.PlotMarkerChanged.Remove(func) end

---@overload fun(X: number, Y: number)
Events.PlotPropertyChanged = {}
---*Query*
---@return number amount
function Events.PlotPropertyChanged.Count() end
---*Action*
function Events.PlotPropertyChanged.RemoveAll() end
---*Action*
function Events.PlotPropertyChanged.Dispatch() end
Events.PlotPropertyChanged = {}
---*Query*
---@return number amount
function Events.PlotPropertyChanged.Count() end
---*Action*
function Events.PlotPropertyChanged.RemoveAll() end
---*Action*
function Events.PlotPropertyChanged.Dispatch() end
---*Action*
---@param X number
---@param Y number
function Events.PlotPropertyChanged.Call(X, Y) end
---*Action*
---@param X number
---@param Y number
function Events.PlotPropertyChanged.CallImmediate(X, Y) end
---*Action*
---@param func fun(X: number, Y: number)
---@return fun(X: number, Y: number)
function Events.PlotPropertyChanged.Add(func) end
---*Action*
---@param func function
function Events.PlotPropertyChanged.Remove(func) end

---@overload fun(X: number, Y: number, visibilityType: number)
Events.PlotVisibilityChanged = {}
---*Query*
---@return number amount
function Events.PlotVisibilityChanged.Count() end
---*Action*
function Events.PlotVisibilityChanged.RemoveAll() end
---*Action*
function Events.PlotVisibilityChanged.Dispatch() end
Events.PlotVisibilityChanged = {}
---*Query*
---@return number amount
function Events.PlotVisibilityChanged.Count() end
---*Action*
function Events.PlotVisibilityChanged.RemoveAll() end
---*Action*
function Events.PlotVisibilityChanged.Dispatch() end
---*Action*
---@param X number
---@param Y number
---@param visibilityType number
function Events.PlotVisibilityChanged.Call(X, Y, visibilityType) end
---*Action*
---@param X number
---@param Y number
---@param visibilityType number
function Events.PlotVisibilityChanged.CallImmediate(X, Y, visibilityType) end
---*Action*
---@param func fun(X: number, Y: number, visibilityType: number)
---@return fun(X: number, Y: number, visibilityType: number)
function Events.PlotVisibilityChanged.Add(func) end
---*Action*
---@param func function
function Events.PlotVisibilityChanged.Remove(func) end

---@overload fun(X: number, Y: number)
Events.PlotYieldChanged = {}
---*Query*
---@return number amount
function Events.PlotYieldChanged.Count() end
---*Action*
function Events.PlotYieldChanged.RemoveAll() end
---*Action*
function Events.PlotYieldChanged.Dispatch() end
Events.PlotYieldChanged = {}
---*Query*
---@return number amount
function Events.PlotYieldChanged.Count() end
---*Action*
function Events.PlotYieldChanged.RemoveAll() end
---*Action*
function Events.PlotYieldChanged.Dispatch() end
---*Action*
---@param X number
---@param Y number
function Events.PlotYieldChanged.Call(X, Y) end
---*Action*
---@param X number
---@param Y number
function Events.PlotYieldChanged.CallImmediate(X, Y) end
---*Action*
---@param func fun(X: number, Y: number)
---@return fun(X: number, Y: number)
function Events.PlotYieldChanged.Add(func) end
---*Action*
---@param func function
function Events.PlotYieldChanged.Remove(func) end

---@overload fun(playerID: number, policyID: number, wasEnacted: boolean)
Events.PolicyChanged = {}
---*Query*
---@return number amount
function Events.PolicyChanged.Count() end
---*Action*
function Events.PolicyChanged.RemoveAll() end
---*Action*
function Events.PolicyChanged.Dispatch() end
Events.PolicyChanged = {}
---*Query*
---@return number amount
function Events.PolicyChanged.Count() end
---*Action*
function Events.PolicyChanged.RemoveAll() end
---*Action*
function Events.PolicyChanged.Dispatch() end
---*Action*
---@param playerID number
---@param policyID number
---@param wasEnacted boolean
function Events.PolicyChanged.Call(playerID, policyID, wasEnacted) end
---*Action*
---@param playerID number
---@param policyID number
---@param wasEnacted boolean
function Events.PolicyChanged.CallImmediate(playerID, policyID, wasEnacted) end
---*Action*
---@param func fun(playerID: number, policyID: number, wasEnacted: boolean)
---@return fun(playerID: number, policyID: number, wasEnacted: boolean)
function Events.PolicyChanged.Add(func) end
---*Action*
---@param func function
function Events.PolicyChanged.Remove(func) end

---@overload fun(CityStateID: number, CompletedQuestPlayerID: number)
Events.QuestChanged = {}
---*Query*
---@return number amount
function Events.QuestChanged.Count() end
---*Action*
function Events.QuestChanged.RemoveAll() end
---*Action*
function Events.QuestChanged.Dispatch() end
Events.QuestChanged = {}
---*Query*
---@return number amount
function Events.QuestChanged.Count() end
---*Action*
function Events.QuestChanged.RemoveAll() end
---*Action*
function Events.QuestChanged.Dispatch() end
---*Action*
---@param CityStateID number
---@param CompletedQuestPlayerID number
function Events.QuestChanged.Call(CityStateID, CompletedQuestPlayerID) end
---*Action*
---@param CityStateID number
---@param CompletedQuestPlayerID number
function Events.QuestChanged.CallImmediate(CityStateID, CompletedQuestPlayerID) end
---*Action*
---@param func fun(CityStateID: number, CompletedQuestPlayerID: number)
---@return fun(CityStateID: number, CompletedQuestPlayerID: number)
function Events.QuestChanged.Add(func) end
---*Action*
---@param func function
function Events.QuestChanged.Remove(func) end

---@overload fun()
Events.QueueFlushed = {}
---*Query*
---@return number amount
function Events.QueueFlushed.Count() end
---*Action*
function Events.QueueFlushed.RemoveAll() end
---*Action*
function Events.QueueFlushed.Dispatch() end
Events.QueueFlushed = {}
---*Query*
---@return number amount
function Events.QueueFlushed.Count() end
---*Action*
function Events.QueueFlushed.RemoveAll() end
---*Action*
function Events.QueueFlushed.Dispatch() end
---*Action*
function Events.QueueFlushed.Call() end
---*Action*
function Events.QueueFlushed.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.QueueFlushed.Add(func) end
---*Action*
---@param func function
function Events.QueueFlushed.Remove(func) end

---@overload fun(playerID: number, religionID: number)
Events.ReligionFounded = {}
---*Query*
---@return number amount
function Events.ReligionFounded.Count() end
---*Action*
function Events.ReligionFounded.RemoveAll() end
---*Action*
function Events.ReligionFounded.Dispatch() end
Events.ReligionFounded = {}
---*Query*
---@return number amount
function Events.ReligionFounded.Count() end
---*Action*
function Events.ReligionFounded.RemoveAll() end
---*Action*
function Events.ReligionFounded.Dispatch() end
---*Action*
---@param playerID number
---@param religionID number
function Events.ReligionFounded.Call(playerID, religionID) end
---*Action*
---@param playerID number
---@param religionID number
function Events.ReligionFounded.CallImmediate(playerID, religionID) end
---*Action*
---@param func fun(playerID: number, religionID: number)
---@return fun(playerID: number, religionID: number)
function Events.ReligionFounded.Add(func) end
---*Action*
---@param func function
function Events.ReligionFounded.Remove(func) end

---@overload fun()
Events.RemotePlayerTurnBegin = {}
---*Query*
---@return number amount
function Events.RemotePlayerTurnBegin.Count() end
---*Action*
function Events.RemotePlayerTurnBegin.RemoveAll() end
---*Action*
function Events.RemotePlayerTurnBegin.Dispatch() end
Events.RemotePlayerTurnBegin = {}
---*Query*
---@return number amount
function Events.RemotePlayerTurnBegin.Count() end
---*Action*
function Events.RemotePlayerTurnBegin.RemoveAll() end
---*Action*
function Events.RemotePlayerTurnBegin.Dispatch() end
---*Action*
function Events.RemotePlayerTurnBegin.Call() end
---*Action*
function Events.RemotePlayerTurnBegin.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.RemotePlayerTurnBegin.Add(func) end
---*Action*
---@param func function
function Events.RemotePlayerTurnBegin.Remove(func) end

---@overload fun()
Events.RemotePlayerTurnEnd = {}
---*Query*
---@return number amount
function Events.RemotePlayerTurnEnd.Count() end
---*Action*
function Events.RemotePlayerTurnEnd.RemoveAll() end
---*Action*
function Events.RemotePlayerTurnEnd.Dispatch() end
Events.RemotePlayerTurnEnd = {}
---*Query*
---@return number amount
function Events.RemotePlayerTurnEnd.Count() end
---*Action*
function Events.RemotePlayerTurnEnd.RemoveAll() end
---*Action*
function Events.RemotePlayerTurnEnd.Dispatch() end
---*Action*
function Events.RemotePlayerTurnEnd.Call() end
---*Action*
function Events.RemotePlayerTurnEnd.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.RemotePlayerTurnEnd.Add(func) end
---*Action*
---@param func function
function Events.RemotePlayerTurnEnd.Remove(func) end

---@overload fun()
Events.RemotePlayerTurnUnready = {}
---*Query*
---@return number amount
function Events.RemotePlayerTurnUnready.Count() end
---*Action*
function Events.RemotePlayerTurnUnready.RemoveAll() end
---*Action*
function Events.RemotePlayerTurnUnready.Dispatch() end
Events.RemotePlayerTurnUnready = {}
---*Query*
---@return number amount
function Events.RemotePlayerTurnUnready.Count() end
---*Action*
function Events.RemotePlayerTurnUnready.RemoveAll() end
---*Action*
function Events.RemotePlayerTurnUnready.Dispatch() end
---*Action*
function Events.RemotePlayerTurnUnready.Call() end
---*Action*
function Events.RemotePlayerTurnUnready.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.RemotePlayerTurnUnready.Add(func) end
---*Action*
---@param func function
function Events.RemotePlayerTurnUnready.Remove(func) end

---@overload fun(playerID: number, technologyIndex: number)
Events.ResearchChanged = {}
---*Query*
---@return number amount
function Events.ResearchChanged.Count() end
---*Action*
function Events.ResearchChanged.RemoveAll() end
---*Action*
function Events.ResearchChanged.Dispatch() end
Events.ResearchChanged = {}
---*Query*
---@return number amount
function Events.ResearchChanged.Count() end
---*Action*
function Events.ResearchChanged.RemoveAll() end
---*Action*
function Events.ResearchChanged.Dispatch() end
---*Action*
---@param playerID number
---@param technologyIndex number
function Events.ResearchChanged.Call(playerID, technologyIndex) end
---*Action*
---@param playerID number
---@param technologyIndex number
function Events.ResearchChanged.CallImmediate(playerID, technologyIndex) end
---*Action*
---@param func fun(playerID: number, technologyIndex: number)
---@return fun(playerID: number, technologyIndex: number)
function Events.ResearchChanged.Add(func) end
---*Action*
---@param func function
function Events.ResearchChanged.Remove(func) end

---@overload fun(playerID: number, technologyIndex: number)
Events.ResearchCompleted = {}
---*Query*
---@return number amount
function Events.ResearchCompleted.Count() end
---*Action*
function Events.ResearchCompleted.RemoveAll() end
---*Action*
function Events.ResearchCompleted.Dispatch() end
Events.ResearchCompleted = {}
---*Query*
---@return number amount
function Events.ResearchCompleted.Count() end
---*Action*
function Events.ResearchCompleted.RemoveAll() end
---*Action*
function Events.ResearchCompleted.Dispatch() end
---*Action*
---@param playerID number
---@param technologyIndex number
function Events.ResearchCompleted.Call(playerID, technologyIndex) end
---*Action*
---@param playerID number
---@param technologyIndex number
function Events.ResearchCompleted.CallImmediate(playerID, technologyIndex) end
---*Action*
---@param func fun(playerID: number, technologyIndex: number)
---@return fun(playerID: number, technologyIndex: number)
function Events.ResearchCompleted.Add(func) end
---*Action*
---@param func function
function Events.ResearchCompleted.Remove(func) end

---@overload fun(playerID: number, technologyIndex: number)
Events.ResearchQueueChanged = {}
---*Query*
---@return number amount
function Events.ResearchQueueChanged.Count() end
---*Action*
function Events.ResearchQueueChanged.RemoveAll() end
---*Action*
function Events.ResearchQueueChanged.Dispatch() end
Events.ResearchQueueChanged = {}
---*Query*
---@return number amount
function Events.ResearchQueueChanged.Count() end
---*Action*
function Events.ResearchQueueChanged.RemoveAll() end
---*Action*
function Events.ResearchQueueChanged.Dispatch() end
---*Action*
---@param playerID number
---@param technologyIndex number
function Events.ResearchQueueChanged.Call(playerID, technologyIndex) end
---*Action*
---@param playerID number
---@param technologyIndex number
function Events.ResearchQueueChanged.CallImmediate(playerID, technologyIndex) end
---*Action*
---@param func fun(playerID: number, technologyIndex: number)
---@return fun(playerID: number, technologyIndex: number)
function Events.ResearchQueueChanged.Add(func) end
---*Action*
---@param func function
function Events.ResearchQueueChanged.Remove(func) end

---@overload fun(playerID: number)
Events.ResearchYieldChanged = {}
---*Query*
---@return number amount
function Events.ResearchYieldChanged.Count() end
---*Action*
function Events.ResearchYieldChanged.RemoveAll() end
---*Action*
function Events.ResearchYieldChanged.Dispatch() end
Events.ResearchYieldChanged = {}
---*Query*
---@return number amount
function Events.ResearchYieldChanged.Count() end
---*Action*
function Events.ResearchYieldChanged.RemoveAll() end
---*Action*
function Events.ResearchYieldChanged.Dispatch() end
---*Action*
---@param playerID number
function Events.ResearchYieldChanged.Call(playerID) end
---*Action*
---@param playerID number
function Events.ResearchYieldChanged.CallImmediate(playerID) end
---*Action*
---@param func fun(playerID: number)
---@return fun(playerID: number)
function Events.ResearchYieldChanged.Add(func) end
---*Action*
---@param func function
function Events.ResearchYieldChanged.Remove(func) end

---@overload fun(X: number, Y: number, resourceIndex: number)
Events.ResourceAddedToMap = {}
---*Query*
---@return number amount
function Events.ResourceAddedToMap.Count() end
---*Action*
function Events.ResourceAddedToMap.RemoveAll() end
---*Action*
function Events.ResourceAddedToMap.Dispatch() end
Events.ResourceAddedToMap = {}
---*Query*
---@return number amount
function Events.ResourceAddedToMap.Count() end
---*Action*
function Events.ResourceAddedToMap.RemoveAll() end
---*Action*
function Events.ResourceAddedToMap.Dispatch() end
---*Action*
---@param X number
---@param Y number
---@param resourceIndex number
function Events.ResourceAddedToMap.Call(X, Y, resourceIndex) end
---*Action*
---@param X number
---@param Y number
---@param resourceIndex number
function Events.ResourceAddedToMap.CallImmediate(X, Y, resourceIndex) end
---*Action*
---@param func fun(X: number, Y: number, resourceIndex: number)
---@return fun(X: number, Y: number, resourceIndex: number)
function Events.ResourceAddedToMap.Add(func) end
---*Action*
---@param func function
function Events.ResourceAddedToMap.Remove(func) end

---@overload fun()
Events.ResourceChanged = {}
---*Query*
---@return number amount
function Events.ResourceChanged.Count() end
---*Action*
function Events.ResourceChanged.RemoveAll() end
---*Action*
function Events.ResourceChanged.Dispatch() end
Events.ResourceChanged = {}
---*Query*
---@return number amount
function Events.ResourceChanged.Count() end
---*Action*
function Events.ResourceChanged.RemoveAll() end
---*Action*
function Events.ResourceChanged.Dispatch() end
---*Action*
function Events.ResourceChanged.Call() end
---*Action*
function Events.ResourceChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.ResourceChanged.Add(func) end
---*Action*
---@param func function
function Events.ResourceChanged.Remove(func) end

---@overload fun(iX: number, iY: number, resourceIndex: number)
Events.ResourceRemovedFromMap = {}
---*Query*
---@return number amount
function Events.ResourceRemovedFromMap.Count() end
---*Action*
function Events.ResourceRemovedFromMap.RemoveAll() end
---*Action*
function Events.ResourceRemovedFromMap.Dispatch() end
Events.ResourceRemovedFromMap = {}
---*Query*
---@return number amount
function Events.ResourceRemovedFromMap.Count() end
---*Action*
function Events.ResourceRemovedFromMap.RemoveAll() end
---*Action*
function Events.ResourceRemovedFromMap.Dispatch() end
---*Action*
---@param iX number
---@param iY number
---@param resourceIndex number
function Events.ResourceRemovedFromMap.Call(iX, iY, resourceIndex) end
---*Action*
---@param iX number
---@param iY number
---@param resourceIndex number
function Events.ResourceRemovedFromMap.CallImmediate(iX, iY, resourceIndex) end
---*Action*
---@param func fun(iX: number, iY: number, resourceIndex: number)
---@return fun(iX: number, iY: number, resourceIndex: number)
function Events.ResourceRemovedFromMap.Add(func) end
---*Action*
---@param func function
function Events.ResourceRemovedFromMap.Remove(func) end

---@overload fun(X: number, Y: number, resourceIndex: number, visibilityType: number)
Events.ResourceVisibilityChanged = {}
---*Query*
---@return number amount
function Events.ResourceVisibilityChanged.Count() end
---*Action*
function Events.ResourceVisibilityChanged.RemoveAll() end
---*Action*
function Events.ResourceVisibilityChanged.Dispatch() end
Events.ResourceVisibilityChanged = {}
---*Query*
---@return number amount
function Events.ResourceVisibilityChanged.Count() end
---*Action*
function Events.ResourceVisibilityChanged.RemoveAll() end
---*Action*
function Events.ResourceVisibilityChanged.Dispatch() end
---*Action*
---@param X number
---@param Y number
---@param resourceIndex number
---@param visibilityType number
function Events.ResourceVisibilityChanged.Call(X, Y, resourceIndex, visibilityType) end
---*Action*
---@param X number
---@param Y number
---@param resourceIndex number
---@param visibilityType number
function Events.ResourceVisibilityChanged.CallImmediate(X, Y, resourceIndex, visibilityType) end
---*Action*
---@param func fun(X: number, Y: number, resourceIndex: number, visibilityType: number)
---@return fun(X: number, Y: number, resourceIndex: number, visibilityType: number)
function Events.ResourceVisibilityChanged.Add(func) end
---*Action*
---@param func function
function Events.ResourceVisibilityChanged.Remove(func) end

---@overload fun()
Events.RiverAddedToMap = {}
---*Query*
---@return number amount
function Events.RiverAddedToMap.Count() end
---*Action*
function Events.RiverAddedToMap.RemoveAll() end
---*Action*
function Events.RiverAddedToMap.Dispatch() end
Events.RiverAddedToMap = {}
---*Query*
---@return number amount
function Events.RiverAddedToMap.Count() end
---*Action*
function Events.RiverAddedToMap.RemoveAll() end
---*Action*
function Events.RiverAddedToMap.Dispatch() end
---*Action*
function Events.RiverAddedToMap.Call() end
---*Action*
function Events.RiverAddedToMap.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.RiverAddedToMap.Add(func) end
---*Action*
---@param func function
function Events.RiverAddedToMap.Remove(func) end

---@overload fun()
Events.RiverRemovedFromMap = {}
---*Query*
---@return number amount
function Events.RiverRemovedFromMap.Count() end
---*Action*
function Events.RiverRemovedFromMap.RemoveAll() end
---*Action*
function Events.RiverRemovedFromMap.Dispatch() end
Events.RiverRemovedFromMap = {}
---*Query*
---@return number amount
function Events.RiverRemovedFromMap.Count() end
---*Action*
function Events.RiverRemovedFromMap.RemoveAll() end
---*Action*
function Events.RiverRemovedFromMap.Dispatch() end
---*Action*
function Events.RiverRemovedFromMap.Call() end
---*Action*
function Events.RiverRemovedFromMap.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.RiverRemovedFromMap.Add(func) end
---*Action*
---@param func function
function Events.RiverRemovedFromMap.Remove(func) end

---@overload fun()
Events.RouteAddedToMap = {}
---*Query*
---@return number amount
function Events.RouteAddedToMap.Count() end
---*Action*
function Events.RouteAddedToMap.RemoveAll() end
---*Action*
function Events.RouteAddedToMap.Dispatch() end
Events.RouteAddedToMap = {}
---*Query*
---@return number amount
function Events.RouteAddedToMap.Count() end
---*Action*
function Events.RouteAddedToMap.RemoveAll() end
---*Action*
function Events.RouteAddedToMap.Dispatch() end
---*Action*
function Events.RouteAddedToMap.Call() end
---*Action*
function Events.RouteAddedToMap.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.RouteAddedToMap.Add(func) end
---*Action*
---@param func function
function Events.RouteAddedToMap.Remove(func) end

---@overload fun(X: number, Y: number)
Events.RouteChanged = {}
---*Query*
---@return number amount
function Events.RouteChanged.Count() end
---*Action*
function Events.RouteChanged.RemoveAll() end
---*Action*
function Events.RouteChanged.Dispatch() end
Events.RouteChanged = {}
---*Query*
---@return number amount
function Events.RouteChanged.Count() end
---*Action*
function Events.RouteChanged.RemoveAll() end
---*Action*
function Events.RouteChanged.Dispatch() end
---*Action*
---@param X number
---@param Y number
function Events.RouteChanged.Call(X, Y) end
---*Action*
---@param X number
---@param Y number
function Events.RouteChanged.CallImmediate(X, Y) end
---*Action*
---@param func fun(X: number, Y: number)
---@return fun(X: number, Y: number)
function Events.RouteChanged.Add(func) end
---*Action*
---@param func function
function Events.RouteChanged.Remove(func) end

---@overload fun()
Events.RouteRemovedFromMap = {}
---*Query*
---@return number amount
function Events.RouteRemovedFromMap.Count() end
---*Action*
function Events.RouteRemovedFromMap.RemoveAll() end
---*Action*
function Events.RouteRemovedFromMap.Dispatch() end
Events.RouteRemovedFromMap = {}
---*Query*
---@return number amount
function Events.RouteRemovedFromMap.Count() end
---*Action*
function Events.RouteRemovedFromMap.RemoveAll() end
---*Action*
function Events.RouteRemovedFromMap.Dispatch() end
---*Action*
function Events.RouteRemovedFromMap.Call() end
---*Action*
function Events.RouteRemovedFromMap.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.RouteRemovedFromMap.Add(func) end
---*Action*
---@param func function
function Events.RouteRemovedFromMap.Remove(func) end

---@overload fun()
Events.RouteVisibilityChanged = {}
---*Query*
---@return number amount
function Events.RouteVisibilityChanged.Count() end
---*Action*
function Events.RouteVisibilityChanged.RemoveAll() end
---*Action*
function Events.RouteVisibilityChanged.Dispatch() end
Events.RouteVisibilityChanged = {}
---*Query*
---@return number amount
function Events.RouteVisibilityChanged.Count() end
---*Action*
function Events.RouteVisibilityChanged.RemoveAll() end
---*Action*
function Events.RouteVisibilityChanged.Dispatch() end
---*Action*
function Events.RouteVisibilityChanged.Call() end
---*Action*
function Events.RouteVisibilityChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.RouteVisibilityChanged.Add(func) end
---*Action*
---@param func function
function Events.RouteVisibilityChanged.Remove(func) end

---@overload fun(spyPlayerID: number, spyUnitID: number)
Events.SpyAdded = {}
---*Query*
---@return number amount
function Events.SpyAdded.Count() end
---*Action*
function Events.SpyAdded.RemoveAll() end
---*Action*
function Events.SpyAdded.Dispatch() end
Events.SpyAdded = {}
---*Query*
---@return number amount
function Events.SpyAdded.Count() end
---*Action*
function Events.SpyAdded.RemoveAll() end
---*Action*
function Events.SpyAdded.Dispatch() end
---*Action*
---@param spyPlayerID number
---@param spyUnitID number
function Events.SpyAdded.Call(spyPlayerID, spyUnitID) end
---*Action*
---@param spyPlayerID number
---@param spyUnitID number
function Events.SpyAdded.CallImmediate(spyPlayerID, spyUnitID) end
---*Action*
---@param func fun(spyPlayerID: number, spyUnitID: number)
---@return fun(spyPlayerID: number, spyUnitID: number)
function Events.SpyAdded.Add(func) end
---*Action*
---@param func function
function Events.SpyAdded.Remove(func) end

---@overload fun(playerID: number, missionID: number)
Events.SpyMissionCompleted = {}
---*Query*
---@return number amount
function Events.SpyMissionCompleted.Count() end
---*Action*
function Events.SpyMissionCompleted.RemoveAll() end
---*Action*
function Events.SpyMissionCompleted.Dispatch() end
Events.SpyMissionCompleted = {}
---*Query*
---@return number amount
function Events.SpyMissionCompleted.Count() end
---*Action*
function Events.SpyMissionCompleted.RemoveAll() end
---*Action*
function Events.SpyMissionCompleted.Dispatch() end
---*Action*
---@param playerID number
---@param missionID number
function Events.SpyMissionCompleted.Call(playerID, missionID) end
---*Action*
---@param playerID number
---@param missionID number
function Events.SpyMissionCompleted.CallImmediate(playerID, missionID) end
---*Action*
---@param func fun(playerID: number, missionID: number)
---@return fun(playerID: number, missionID: number)
function Events.SpyMissionCompleted.Add(func) end
---*Action*
---@param func function
function Events.SpyMissionCompleted.Remove(func) end

---@overload fun()
Events.SpyMissionUpdated = {}
---*Query*
---@return number amount
function Events.SpyMissionUpdated.Count() end
---*Action*
function Events.SpyMissionUpdated.RemoveAll() end
---*Action*
function Events.SpyMissionUpdated.Dispatch() end
Events.SpyMissionUpdated = {}
---*Query*
---@return number amount
function Events.SpyMissionUpdated.Count() end
---*Action*
function Events.SpyMissionUpdated.RemoveAll() end
---*Action*
function Events.SpyMissionUpdated.Dispatch() end
---*Action*
function Events.SpyMissionUpdated.Call() end
---*Action*
function Events.SpyMissionUpdated.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.SpyMissionUpdated.Add(func) end
---*Action*
---@param func function
function Events.SpyMissionUpdated.Remove(func) end

---@overload fun(spyPlayerID: number, counterSpyPlayerID: number)
Events.SpyRemoved = {}
---*Query*
---@return number amount
function Events.SpyRemoved.Count() end
---*Action*
function Events.SpyRemoved.RemoveAll() end
---*Action*
function Events.SpyRemoved.Dispatch() end
Events.SpyRemoved = {}
---*Query*
---@return number amount
function Events.SpyRemoved.Count() end
---*Action*
function Events.SpyRemoved.RemoveAll() end
---*Action*
function Events.SpyRemoved.Dispatch() end
---*Action*
---@param spyPlayerID number
---@param counterSpyPlayerID number
function Events.SpyRemoved.Call(spyPlayerID, counterSpyPlayerID) end
---*Action*
---@param spyPlayerID number
---@param counterSpyPlayerID number
function Events.SpyRemoved.CallImmediate(spyPlayerID, counterSpyPlayerID) end
---*Action*
---@param func fun(spyPlayerID: number, counterSpyPlayerID: number)
---@return fun(spyPlayerID: number, counterSpyPlayerID: number)
function Events.SpyRemoved.Add(func) end
---*Action*
---@param func function
function Events.SpyRemoved.Remove(func) end

---@overload fun()
Events.SpyUpdated = {}
---*Query*
---@return number amount
function Events.SpyUpdated.Count() end
---*Action*
function Events.SpyUpdated.RemoveAll() end
---*Action*
function Events.SpyUpdated.Dispatch() end
Events.SpyUpdated = {}
---*Query*
---@return number amount
function Events.SpyUpdated.Count() end
---*Action*
function Events.SpyUpdated.RemoveAll() end
---*Action*
function Events.SpyUpdated.Dispatch() end
---*Action*
function Events.SpyUpdated.Call() end
---*Action*
function Events.SpyUpdated.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.SpyUpdated.Add(func) end
---*Action*
---@param func function
function Events.SpyUpdated.Remove(func) end

---@overload fun()
Events.StatusMessage = {}
---*Query*
---@return number amount
function Events.StatusMessage.Count() end
---*Action*
function Events.StatusMessage.RemoveAll() end
---*Action*
function Events.StatusMessage.Dispatch() end
Events.StatusMessage = {}
---*Query*
---@return number amount
function Events.StatusMessage.Count() end
---*Action*
function Events.StatusMessage.RemoveAll() end
---*Action*
function Events.StatusMessage.Dispatch() end
---*Action*
function Events.StatusMessage.Call() end
---*Action*
function Events.StatusMessage.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.StatusMessage.Add(func) end
---*Action*
---@param func function
function Events.StatusMessage.Remove(func) end

---@overload fun(type: any, tag: any, data1: number, data2: number, data3: string)
Events.SystemUpdateUI = {}
---*Query*
---@return number amount
function Events.SystemUpdateUI.Count() end
---*Action*
function Events.SystemUpdateUI.RemoveAll() end
---*Action*
function Events.SystemUpdateUI.Dispatch() end
Events.SystemUpdateUI = {}
---*Query*
---@return number amount
function Events.SystemUpdateUI.Count() end
---*Action*
function Events.SystemUpdateUI.RemoveAll() end
---*Action*
function Events.SystemUpdateUI.Dispatch() end
---*Action*
---@param type any
---@param tag any
---@param data1 number
---@param data2 number
---@param data3 string
function Events.SystemUpdateUI.Call(type, tag, data1, data2, data3) end
---*Action*
---@param type any
---@param tag any
---@param data1 number
---@param data2 number
---@param data3 string
function Events.SystemUpdateUI.CallImmediate(type, tag, data1, data2, data3) end
---*Action*
---@param func fun(type: any, tag: any, data1: number, data2: number, data3: string)
---@return fun(type: any, tag: any, data1: number, data2: number, data3: string)
function Events.SystemUpdateUI.Add(func) end
---*Action*
---@param func function
function Events.SystemUpdateUI.Remove(func) end

---@overload fun()
Events.TeamVictory = {}
---*Query*
---@return number amount
function Events.TeamVictory.Count() end
---*Action*
function Events.TeamVictory.RemoveAll() end
---*Action*
function Events.TeamVictory.Dispatch() end
Events.TeamVictory = {}
---*Query*
---@return number amount
function Events.TeamVictory.Count() end
---*Action*
function Events.TeamVictory.RemoveAll() end
---*Action*
function Events.TeamVictory.Dispatch() end
---*Action*
function Events.TeamVictory.Call() end
---*Action*
function Events.TeamVictory.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.TeamVictory.Add(func) end
---*Action*
---@param func function
function Events.TeamVictory.Remove(func) end

---@overload fun(playerID: number, techBoosted: number, unknownA: number, unknownB: number)
Events.TechBoostTriggered = {}
---*Query*
---@return number amount
function Events.TechBoostTriggered.Count() end
---*Action*
function Events.TechBoostTriggered.RemoveAll() end
---*Action*
function Events.TechBoostTriggered.Dispatch() end
Events.TechBoostTriggered = {}
---*Query*
---@return number amount
function Events.TechBoostTriggered.Count() end
---*Action*
function Events.TechBoostTriggered.RemoveAll() end
---*Action*
function Events.TechBoostTriggered.Dispatch() end
---*Action*
---@param playerID number
---@param techBoosted number
---@param unknownA number
---@param unknownB number
function Events.TechBoostTriggered.Call(playerID, techBoosted, unknownA, unknownB) end
---*Action*
---@param playerID number
---@param techBoosted number
---@param unknownA number
---@param unknownB number
function Events.TechBoostTriggered.CallImmediate(playerID, techBoosted, unknownA, unknownB) end
---*Action*
---@param func fun(playerID: number, techBoosted: number, unknownA: number, unknownB: number)
---@return fun(playerID: number, techBoosted: number, unknownA: number, unknownB: number)
function Events.TechBoostTriggered.Add(func) end
---*Action*
---@param func function
function Events.TechBoostTriggered.Remove(func) end

---@overload fun()
Events.TerrainTypeChanged = {}
---*Query*
---@return number amount
function Events.TerrainTypeChanged.Count() end
---*Action*
function Events.TerrainTypeChanged.RemoveAll() end
---*Action*
function Events.TerrainTypeChanged.Dispatch() end
Events.TerrainTypeChanged = {}
---*Query*
---@return number amount
function Events.TerrainTypeChanged.Count() end
---*Action*
function Events.TerrainTypeChanged.RemoveAll() end
---*Action*
function Events.TerrainTypeChanged.Dispatch() end
---*Action*
function Events.TerrainTypeChanged.Call() end
---*Action*
function Events.TerrainTypeChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.TerrainTypeChanged.Add(func) end
---*Action*
---@param func function
function Events.TerrainTypeChanged.Remove(func) end

---@overload fun(playerID: number, originPlayerID: number, originCityID: number, targetPlayerID: number, targetCityID: number)
Events.TradeRouteActivityChanged = {}
---*Query*
---@return number amount
function Events.TradeRouteActivityChanged.Count() end
---*Action*
function Events.TradeRouteActivityChanged.RemoveAll() end
---*Action*
function Events.TradeRouteActivityChanged.Dispatch() end
Events.TradeRouteActivityChanged = {}
---*Query*
---@return number amount
function Events.TradeRouteActivityChanged.Count() end
---*Action*
function Events.TradeRouteActivityChanged.RemoveAll() end
---*Action*
function Events.TradeRouteActivityChanged.Dispatch() end
---*Action*
---@param playerID number
---@param originPlayerID number
---@param originCityID number
---@param targetPlayerID number
---@param targetCityID number
function Events.TradeRouteActivityChanged.Call(playerID, originPlayerID, originCityID, targetPlayerID, targetCityID) end
---*Action*
---@param playerID number
---@param originPlayerID number
---@param originCityID number
---@param targetPlayerID number
---@param targetCityID number
function Events.TradeRouteActivityChanged.CallImmediate(playerID, originPlayerID, originCityID, targetPlayerID, targetCityID) end
---*Action*
---@param func fun(playerID: number, originPlayerID: number, originCityID: number, targetPlayerID: number, targetCityID: number)
---@return fun(playerID: number, originPlayerID: number, originCityID: number, targetPlayerID: number, targetCityID: number)
function Events.TradeRouteActivityChanged.Add(func) end
---*Action*
---@param func function
function Events.TradeRouteActivityChanged.Remove(func) end

---@overload fun(playerID: number, X: number, Y: number)
Events.TradeRouteAddedToMap = {}
---*Query*
---@return number amount
function Events.TradeRouteAddedToMap.Count() end
---*Action*
function Events.TradeRouteAddedToMap.RemoveAll() end
---*Action*
function Events.TradeRouteAddedToMap.Dispatch() end
Events.TradeRouteAddedToMap = {}
---*Query*
---@return number amount
function Events.TradeRouteAddedToMap.Count() end
---*Action*
function Events.TradeRouteAddedToMap.RemoveAll() end
---*Action*
function Events.TradeRouteAddedToMap.Dispatch() end
---*Action*
---@param playerID number
---@param X number
---@param Y number
function Events.TradeRouteAddedToMap.Call(playerID, X, Y) end
---*Action*
---@param playerID number
---@param X number
---@param Y number
function Events.TradeRouteAddedToMap.CallImmediate(playerID, X, Y) end
---*Action*
---@param func fun(playerID: number, X: number, Y: number)
---@return fun(playerID: number, X: number, Y: number)
function Events.TradeRouteAddedToMap.Add(func) end
---*Action*
---@param func function
function Events.TradeRouteAddedToMap.Remove(func) end

---@overload fun(playerID: number)
Events.TradeRouteCapacityChanged = {}
---*Query*
---@return number amount
function Events.TradeRouteCapacityChanged.Count() end
---*Action*
function Events.TradeRouteCapacityChanged.RemoveAll() end
---*Action*
function Events.TradeRouteCapacityChanged.Dispatch() end
Events.TradeRouteCapacityChanged = {}
---*Query*
---@return number amount
function Events.TradeRouteCapacityChanged.Count() end
---*Action*
function Events.TradeRouteCapacityChanged.RemoveAll() end
---*Action*
function Events.TradeRouteCapacityChanged.Dispatch() end
---*Action*
---@param playerID number
function Events.TradeRouteCapacityChanged.Call(playerID) end
---*Action*
---@param playerID number
function Events.TradeRouteCapacityChanged.CallImmediate(playerID) end
---*Action*
---@param func fun(playerID: number)
---@return fun(playerID: number)
function Events.TradeRouteCapacityChanged.Add(func) end
---*Action*
---@param func function
function Events.TradeRouteCapacityChanged.Remove(func) end

---@overload fun()
Events.TradeRouteRangeChanged = {}
---*Query*
---@return number amount
function Events.TradeRouteRangeChanged.Count() end
---*Action*
function Events.TradeRouteRangeChanged.RemoveAll() end
---*Action*
function Events.TradeRouteRangeChanged.Dispatch() end
Events.TradeRouteRangeChanged = {}
---*Query*
---@return number amount
function Events.TradeRouteRangeChanged.Count() end
---*Action*
function Events.TradeRouteRangeChanged.RemoveAll() end
---*Action*
function Events.TradeRouteRangeChanged.Dispatch() end
---*Action*
function Events.TradeRouteRangeChanged.Call() end
---*Action*
function Events.TradeRouteRangeChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.TradeRouteRangeChanged.Add(func) end
---*Action*
---@param func function
function Events.TradeRouteRangeChanged.Remove(func) end

---@overload fun(playerID: number, X: number, Y: number)
Events.TradeRouteRemovedFromMap = {}
---*Query*
---@return number amount
function Events.TradeRouteRemovedFromMap.Count() end
---*Action*
function Events.TradeRouteRemovedFromMap.RemoveAll() end
---*Action*
function Events.TradeRouteRemovedFromMap.Dispatch() end
Events.TradeRouteRemovedFromMap = {}
---*Query*
---@return number amount
function Events.TradeRouteRemovedFromMap.Count() end
---*Action*
function Events.TradeRouteRemovedFromMap.RemoveAll() end
---*Action*
function Events.TradeRouteRemovedFromMap.Dispatch() end
---*Action*
---@param playerID number
---@param X number
---@param Y number
function Events.TradeRouteRemovedFromMap.Call(playerID, X, Y) end
---*Action*
---@param playerID number
---@param X number
---@param Y number
function Events.TradeRouteRemovedFromMap.CallImmediate(playerID, X, Y) end
---*Action*
---@param func fun(playerID: number, X: number, Y: number)
---@return fun(playerID: number, X: number, Y: number)
function Events.TradeRouteRemovedFromMap.Add(func) end
---*Action*
---@param func function
function Events.TradeRouteRemovedFromMap.Remove(func) end

---@overload fun(playerID: number, yield: number, balance: any)
Events.TreasuryChanged = {}
---*Query*
---@return number amount
function Events.TreasuryChanged.Count() end
---*Action*
function Events.TreasuryChanged.RemoveAll() end
---*Action*
function Events.TreasuryChanged.Dispatch() end
Events.TreasuryChanged = {}
---*Query*
---@return number amount
function Events.TreasuryChanged.Count() end
---*Action*
function Events.TreasuryChanged.RemoveAll() end
---*Action*
function Events.TreasuryChanged.Dispatch() end
---*Action*
---@param playerID number
---@param yield number
---@param balance any
function Events.TreasuryChanged.Call(playerID, yield, balance) end
---*Action*
---@param playerID number
---@param yield number
---@param balance any
function Events.TreasuryChanged.CallImmediate(playerID, yield, balance) end
---*Action*
---@param func fun(playerID: number, yield: number, balance: any)
---@return fun(playerID: number, yield: number, balance: any)
function Events.TreasuryChanged.Add(func) end
---*Action*
---@param func function
function Events.TreasuryChanged.Remove(func) end

---@overload fun()
Events.TurnBegin = {}
---*Query*
---@return number amount
function Events.TurnBegin.Count() end
---*Action*
function Events.TurnBegin.RemoveAll() end
---*Action*
function Events.TurnBegin.Dispatch() end
Events.TurnBegin = {}
---*Query*
---@return number amount
function Events.TurnBegin.Count() end
---*Action*
function Events.TurnBegin.RemoveAll() end
---*Action*
function Events.TurnBegin.Dispatch() end
---*Action*
function Events.TurnBegin.Call() end
---*Action*
function Events.TurnBegin.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.TurnBegin.Add(func) end
---*Action*
---@param func function
function Events.TurnBegin.Remove(func) end

---@overload fun()
Events.TurnEnd = {}
---*Query*
---@return number amount
function Events.TurnEnd.Count() end
---*Action*
function Events.TurnEnd.RemoveAll() end
---*Action*
function Events.TurnEnd.Dispatch() end
Events.TurnEnd = {}
---*Query*
---@return number amount
function Events.TurnEnd.Count() end
---*Action*
function Events.TurnEnd.RemoveAll() end
---*Action*
function Events.TurnEnd.Dispatch() end
---*Action*
function Events.TurnEnd.Call() end
---*Action*
function Events.TurnEnd.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.TurnEnd.Add(func) end
---*Action*
---@param func function
function Events.TurnEnd.Remove(func) end

---@overload fun(playerID: number, unitID: number, unitAbilityIndex: number)
Events.UnitAbilityGained = {}
---*Query*
---@return number amount
function Events.UnitAbilityGained.Count() end
---*Action*
function Events.UnitAbilityGained.RemoveAll() end
---*Action*
function Events.UnitAbilityGained.Dispatch() end
Events.UnitAbilityGained = {}
---*Query*
---@return number amount
function Events.UnitAbilityGained.Count() end
---*Action*
function Events.UnitAbilityGained.RemoveAll() end
---*Action*
function Events.UnitAbilityGained.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
---@param unitAbilityIndex number
function Events.UnitAbilityGained.Call(playerID, unitID, unitAbilityIndex) end
---*Action*
---@param playerID number
---@param unitID number
---@param unitAbilityIndex number
function Events.UnitAbilityGained.CallImmediate(playerID, unitID, unitAbilityIndex) end
---*Action*
---@param func fun(playerID: number, unitID: number, unitAbilityIndex: number)
---@return fun(playerID: number, unitID: number, unitAbilityIndex: number)
function Events.UnitAbilityGained.Add(func) end
---*Action*
---@param func function
function Events.UnitAbilityGained.Remove(func) end

---@overload fun(playerID: number, unitID: number, unitAbilityIndex: number)
Events.UnitAbilityLost = {}
---*Query*
---@return number amount
function Events.UnitAbilityLost.Count() end
---*Action*
function Events.UnitAbilityLost.RemoveAll() end
---*Action*
function Events.UnitAbilityLost.Dispatch() end
Events.UnitAbilityLost = {}
---*Query*
---@return number amount
function Events.UnitAbilityLost.Count() end
---*Action*
function Events.UnitAbilityLost.RemoveAll() end
---*Action*
function Events.UnitAbilityLost.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
---@param unitAbilityIndex number
function Events.UnitAbilityLost.Call(playerID, unitID, unitAbilityIndex) end
---*Action*
---@param playerID number
---@param unitID number
---@param unitAbilityIndex number
function Events.UnitAbilityLost.CallImmediate(playerID, unitID, unitAbilityIndex) end
---*Action*
---@param func fun(playerID: number, unitID: number, unitAbilityIndex: number)
---@return fun(playerID: number, unitID: number, unitAbilityIndex: number)
function Events.UnitAbilityLost.Add(func) end
---*Action*
---@param func function
function Events.UnitAbilityLost.Remove(func) end

---@overload fun()
Events.UnitActivate = {}
---*Query*
---@return number amount
function Events.UnitActivate.Count() end
---*Action*
function Events.UnitActivate.RemoveAll() end
---*Action*
function Events.UnitActivate.Dispatch() end
Events.UnitActivate = {}
---*Query*
---@return number amount
function Events.UnitActivate.Count() end
---*Action*
function Events.UnitActivate.RemoveAll() end
---*Action*
function Events.UnitActivate.Dispatch() end
---*Action*
function Events.UnitActivate.Call() end
---*Action*
function Events.UnitActivate.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.UnitActivate.Add(func) end
---*Action*
---@param func function
function Events.UnitActivate.Remove(func) end

---@overload fun(playerID: number, unitID: number, activityType: ActivityTypes)
Events.UnitActivityChanged = {}
---*Query*
---@return number amount
function Events.UnitActivityChanged.Count() end
---*Action*
function Events.UnitActivityChanged.RemoveAll() end
---*Action*
function Events.UnitActivityChanged.Dispatch() end
Events.UnitActivityChanged = {}
---*Query*
---@return number amount
function Events.UnitActivityChanged.Count() end
---*Action*
function Events.UnitActivityChanged.RemoveAll() end
---*Action*
function Events.UnitActivityChanged.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
---@param activityType ActivityTypes
function Events.UnitActivityChanged.Call(playerID, unitID, activityType) end
---*Action*
---@param playerID number
---@param unitID number
---@param activityType ActivityTypes
function Events.UnitActivityChanged.CallImmediate(playerID, unitID, activityType) end
---*Action*
---@param func fun(playerID: number, unitID: number, activityType: ActivityTypes)
---@return fun(playerID: number, unitID: number, activityType: ActivityTypes)
function Events.UnitActivityChanged.Add(func) end
---*Action*
---@param func function
function Events.UnitActivityChanged.Remove(func) end

---@overload fun(playerID: number, unitID: number)
Events.UnitAddedToMap = {}
---*Query*
---@return number amount
function Events.UnitAddedToMap.Count() end
---*Action*
function Events.UnitAddedToMap.RemoveAll() end
---*Action*
function Events.UnitAddedToMap.Dispatch() end
Events.UnitAddedToMap = {}
---*Query*
---@return number amount
function Events.UnitAddedToMap.Count() end
---*Action*
function Events.UnitAddedToMap.RemoveAll() end
---*Action*
function Events.UnitAddedToMap.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
function Events.UnitAddedToMap.Call(playerID, unitID) end
---*Action*
---@param playerID number
---@param unitID number
function Events.UnitAddedToMap.CallImmediate(playerID, unitID) end
---*Action*
---@param func fun(playerID: number, unitID: number)
---@return fun(playerID: number, unitID: number)
function Events.UnitAddedToMap.Add(func) end
---*Action*
---@param func function
function Events.UnitAddedToMap.Remove(func) end

---@overload fun()
Events.UnitAirlifted = {}
---*Query*
---@return number amount
function Events.UnitAirlifted.Count() end
---*Action*
function Events.UnitAirlifted.RemoveAll() end
---*Action*
function Events.UnitAirlifted.Dispatch() end
Events.UnitAirlifted = {}
---*Query*
---@return number amount
function Events.UnitAirlifted.Count() end
---*Action*
function Events.UnitAirlifted.RemoveAll() end
---*Action*
function Events.UnitAirlifted.Dispatch() end
---*Action*
function Events.UnitAirlifted.Call() end
---*Action*
function Events.UnitAirlifted.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.UnitAirlifted.Add(func) end
---*Action*
---@param func function
function Events.UnitAirlifted.Remove(func) end

---@overload fun(playerID: number, unitID: number)
Events.UnitArtifactChanged = {}
---*Query*
---@return number amount
function Events.UnitArtifactChanged.Count() end
---*Action*
function Events.UnitArtifactChanged.RemoveAll() end
---*Action*
function Events.UnitArtifactChanged.Dispatch() end
Events.UnitArtifactChanged = {}
---*Query*
---@return number amount
function Events.UnitArtifactChanged.Count() end
---*Action*
function Events.UnitArtifactChanged.RemoveAll() end
---*Action*
function Events.UnitArtifactChanged.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
function Events.UnitArtifactChanged.Call(playerID, unitID) end
---*Action*
---@param playerID number
---@param unitID number
function Events.UnitArtifactChanged.CallImmediate(playerID, unitID) end
---*Action*
---@param func fun(playerID: number, unitID: number)
---@return fun(playerID: number, unitID: number)
function Events.UnitArtifactChanged.Add(func) end
---*Action*
---@param func function
function Events.UnitArtifactChanged.Remove(func) end

---@overload fun(currentUnitPlayerID: number, unitID: number, owningPlayerID: number, capturingPlayerID: number)
Events.UnitCaptured = {}
---*Query*
---@return number amount
function Events.UnitCaptured.Count() end
---*Action*
function Events.UnitCaptured.RemoveAll() end
---*Action*
function Events.UnitCaptured.Dispatch() end
Events.UnitCaptured = {}
---*Query*
---@return number amount
function Events.UnitCaptured.Count() end
---*Action*
function Events.UnitCaptured.RemoveAll() end
---*Action*
function Events.UnitCaptured.Dispatch() end
---*Action*
---@param currentUnitPlayerID number
---@param unitID number
---@param owningPlayerID number
---@param capturingPlayerID number
function Events.UnitCaptured.Call(currentUnitPlayerID, unitID, owningPlayerID, capturingPlayerID) end
---*Action*
---@param currentUnitPlayerID number
---@param unitID number
---@param owningPlayerID number
---@param capturingPlayerID number
function Events.UnitCaptured.CallImmediate(currentUnitPlayerID, unitID, owningPlayerID, capturingPlayerID) end
---*Action*
---@param func fun(currentUnitPlayerID: number, unitID: number, owningPlayerID: number, capturingPlayerID: number)
---@return fun(currentUnitPlayerID: number, unitID: number, owningPlayerID: number, capturingPlayerID: number)
function Events.UnitCaptured.Add(func) end
---*Action*
---@param func function
function Events.UnitCaptured.Remove(func) end

---@overload fun(playerID: number, unitID: number, newCharges: number, oldCharges: number)
Events.UnitChargesChanged = {}
---*Query*
---@return number amount
function Events.UnitChargesChanged.Count() end
---*Action*
function Events.UnitChargesChanged.RemoveAll() end
---*Action*
function Events.UnitChargesChanged.Dispatch() end
Events.UnitChargesChanged = {}
---*Query*
---@return number amount
function Events.UnitChargesChanged.Count() end
---*Action*
function Events.UnitChargesChanged.RemoveAll() end
---*Action*
function Events.UnitChargesChanged.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
---@param newCharges number
---@param oldCharges number
function Events.UnitChargesChanged.Call(playerID, unitID, newCharges, oldCharges) end
---*Action*
---@param playerID number
---@param unitID number
---@param newCharges number
---@param oldCharges number
function Events.UnitChargesChanged.CallImmediate(playerID, unitID, newCharges, oldCharges) end
---*Action*
---@param func fun(playerID: number, unitID: number, newCharges: number, oldCharges: number)
---@return fun(playerID: number, unitID: number, newCharges: number, oldCharges: number)
function Events.UnitChargesChanged.Add(func) end
---*Action*
---@param func function
function Events.UnitChargesChanged.Remove(func) end

---@overload fun(playerID: number, unitID: number, commandType: UnitCommandTypes, data1: number)
Events.UnitCommandStarted = {}
---*Query*
---@return number amount
function Events.UnitCommandStarted.Count() end
---*Action*
function Events.UnitCommandStarted.RemoveAll() end
---*Action*
function Events.UnitCommandStarted.Dispatch() end
Events.UnitCommandStarted = {}
---*Query*
---@return number amount
function Events.UnitCommandStarted.Count() end
---*Action*
function Events.UnitCommandStarted.RemoveAll() end
---*Action*
function Events.UnitCommandStarted.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
---@param commandType UnitCommandTypes
---@param data1 number
function Events.UnitCommandStarted.Call(playerID, unitID, commandType, data1) end
---*Action*
---@param playerID number
---@param unitID number
---@param commandType UnitCommandTypes
---@param data1 number
function Events.UnitCommandStarted.CallImmediate(playerID, unitID, commandType, data1) end
---*Action*
---@param func fun(playerID: number, unitID: number, commandType: UnitCommandTypes, data1: number)
---@return fun(playerID: number, unitID: number, commandType: UnitCommandTypes, data1: number)
function Events.UnitCommandStarted.Add(func) end
---*Action*
---@param func function
function Events.UnitCommandStarted.Remove(func) end

---@overload fun(playerID: number, unitID: number, newDamage: number, prevDamage: number)
Events.UnitDamageChanged = {}
---*Query*
---@return number amount
function Events.UnitDamageChanged.Count() end
---*Action*
function Events.UnitDamageChanged.RemoveAll() end
---*Action*
function Events.UnitDamageChanged.Dispatch() end
Events.UnitDamageChanged = {}
---*Query*
---@return number amount
function Events.UnitDamageChanged.Count() end
---*Action*
function Events.UnitDamageChanged.RemoveAll() end
---*Action*
function Events.UnitDamageChanged.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
---@param newDamage number
---@param prevDamage number
function Events.UnitDamageChanged.Call(playerID, unitID, newDamage, prevDamage) end
---*Action*
---@param playerID number
---@param unitID number
---@param newDamage number
---@param prevDamage number
function Events.UnitDamageChanged.CallImmediate(playerID, unitID, newDamage, prevDamage) end
---*Action*
---@param func fun(playerID: number, unitID: number, newDamage: number, prevDamage: number)
---@return fun(playerID: number, unitID: number, newDamage: number, prevDamage: number)
function Events.UnitDamageChanged.Add(func) end
---*Action*
---@param func function
function Events.UnitDamageChanged.Remove(func) end

---@overload fun(playerID: number, unitID: number, isEmbarked: boolean)
Events.UnitEmbarkedStateChanged = {}
---*Query*
---@return number amount
function Events.UnitEmbarkedStateChanged.Count() end
---*Action*
function Events.UnitEmbarkedStateChanged.RemoveAll() end
---*Action*
function Events.UnitEmbarkedStateChanged.Dispatch() end
Events.UnitEmbarkedStateChanged = {}
---*Query*
---@return number amount
function Events.UnitEmbarkedStateChanged.Count() end
---*Action*
function Events.UnitEmbarkedStateChanged.RemoveAll() end
---*Action*
function Events.UnitEmbarkedStateChanged.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
---@param isEmbarked boolean
function Events.UnitEmbarkedStateChanged.Call(playerID, unitID, isEmbarked) end
---*Action*
---@param playerID number
---@param unitID number
---@param isEmbarked boolean
function Events.UnitEmbarkedStateChanged.CallImmediate(playerID, unitID, isEmbarked) end
---*Action*
---@param func fun(playerID: number, unitID: number, isEmbarked: boolean)
---@return fun(playerID: number, unitID: number, isEmbarked: boolean)
function Events.UnitEmbarkedStateChanged.Add(func) end
---*Action*
---@param func function
function Events.UnitEmbarkedStateChanged.Remove(func) end

---@overload fun(firstUnitPlayerID: number, firstUnitID: number, secondUnitPlayerID: number, secondUnitID: number)
Events.UnitEnterFormation = {}
---*Query*
---@return number amount
function Events.UnitEnterFormation.Count() end
---*Action*
function Events.UnitEnterFormation.RemoveAll() end
---*Action*
function Events.UnitEnterFormation.Dispatch() end
Events.UnitEnterFormation = {}
---*Query*
---@return number amount
function Events.UnitEnterFormation.Count() end
---*Action*
function Events.UnitEnterFormation.RemoveAll() end
---*Action*
function Events.UnitEnterFormation.Dispatch() end
---*Action*
---@param firstUnitPlayerID number
---@param firstUnitID number
---@param secondUnitPlayerID number
---@param secondUnitID number
function Events.UnitEnterFormation.Call(firstUnitPlayerID, firstUnitID, secondUnitPlayerID, secondUnitID) end
---*Action*
---@param firstUnitPlayerID number
---@param firstUnitID number
---@param secondUnitPlayerID number
---@param secondUnitID number
function Events.UnitEnterFormation.CallImmediate(firstUnitPlayerID, firstUnitID, secondUnitPlayerID, secondUnitID) end
---*Action*
---@param func fun(firstUnitPlayerID: number, firstUnitID: number, secondUnitPlayerID: number, secondUnitID: number)
---@return fun(firstUnitPlayerID: number, firstUnitID: number, secondUnitPlayerID: number, secondUnitID: number)
function Events.UnitEnterFormation.Add(func) end
---*Action*
---@param func function
function Events.UnitEnterFormation.Remove(func) end

---@overload fun(firstUnitPlayerID: number, firstUnitID: number, secondUnitPlayerID: number, secondUnitID: number)
Events.UnitExitFormation = {}
---*Query*
---@return number amount
function Events.UnitExitFormation.Count() end
---*Action*
function Events.UnitExitFormation.RemoveAll() end
---*Action*
function Events.UnitExitFormation.Dispatch() end
Events.UnitExitFormation = {}
---*Query*
---@return number amount
function Events.UnitExitFormation.Count() end
---*Action*
function Events.UnitExitFormation.RemoveAll() end
---*Action*
function Events.UnitExitFormation.Dispatch() end
---*Action*
---@param firstUnitPlayerID number
---@param firstUnitID number
---@param secondUnitPlayerID number
---@param secondUnitID number
function Events.UnitExitFormation.Call(firstUnitPlayerID, firstUnitID, secondUnitPlayerID, secondUnitID) end
---*Action*
---@param firstUnitPlayerID number
---@param firstUnitID number
---@param secondUnitPlayerID number
---@param secondUnitID number
function Events.UnitExitFormation.CallImmediate(firstUnitPlayerID, firstUnitID, secondUnitPlayerID, secondUnitID) end
---*Action*
---@param func fun(firstUnitPlayerID: number, firstUnitID: number, secondUnitPlayerID: number, secondUnitID: number)
---@return fun(firstUnitPlayerID: number, firstUnitID: number, secondUnitPlayerID: number, secondUnitID: number)
function Events.UnitExitFormation.Add(func) end
---*Action*
---@param func function
function Events.UnitExitFormation.Remove(func) end

---@overload fun()
Events.UnitExperienceChanged = {}
---*Query*
---@return number amount
function Events.UnitExperienceChanged.Count() end
---*Action*
function Events.UnitExperienceChanged.RemoveAll() end
---*Action*
function Events.UnitExperienceChanged.Dispatch() end
Events.UnitExperienceChanged = {}
---*Query*
---@return number amount
function Events.UnitExperienceChanged.Count() end
---*Action*
function Events.UnitExperienceChanged.RemoveAll() end
---*Action*
function Events.UnitExperienceChanged.Dispatch() end
---*Action*
function Events.UnitExperienceChanged.Call() end
---*Action*
function Events.UnitExperienceChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.UnitExperienceChanged.Add(func) end
---*Action*
---@param func function
function Events.UnitExperienceChanged.Remove(func) end

---@overload fun(playerID: number, unitID: number)
Events.UnitFormArmy = {}
---*Query*
---@return number amount
function Events.UnitFormArmy.Count() end
---*Action*
function Events.UnitFormArmy.RemoveAll() end
---*Action*
function Events.UnitFormArmy.Dispatch() end
Events.UnitFormArmy = {}
---*Query*
---@return number amount
function Events.UnitFormArmy.Count() end
---*Action*
function Events.UnitFormArmy.RemoveAll() end
---*Action*
function Events.UnitFormArmy.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
function Events.UnitFormArmy.Call(playerID, unitID) end
---*Action*
---@param playerID number
---@param unitID number
function Events.UnitFormArmy.CallImmediate(playerID, unitID) end
---*Action*
---@param func fun(playerID: number, unitID: number)
---@return fun(playerID: number, unitID: number)
function Events.UnitFormArmy.Add(func) end
---*Action*
---@param func function
function Events.UnitFormArmy.Remove(func) end

---@overload fun()
Events.UnitFormationChanged = {}
---*Query*
---@return number amount
function Events.UnitFormationChanged.Count() end
---*Action*
function Events.UnitFormationChanged.RemoveAll() end
---*Action*
function Events.UnitFormationChanged.Dispatch() end
Events.UnitFormationChanged = {}
---*Query*
---@return number amount
function Events.UnitFormationChanged.Count() end
---*Action*
function Events.UnitFormationChanged.RemoveAll() end
---*Action*
function Events.UnitFormationChanged.Dispatch() end
---*Action*
function Events.UnitFormationChanged.Call() end
---*Action*
function Events.UnitFormationChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.UnitFormationChanged.Add(func) end
---*Action*
---@param func function
function Events.UnitFormationChanged.Remove(func) end

---@overload fun(playerID: number, unitID: number)
Events.UnitFormCorps = {}
---*Query*
---@return number amount
function Events.UnitFormCorps.Count() end
---*Action*
function Events.UnitFormCorps.RemoveAll() end
---*Action*
function Events.UnitFormCorps.Dispatch() end
Events.UnitFormCorps = {}
---*Query*
---@return number amount
function Events.UnitFormCorps.Count() end
---*Action*
function Events.UnitFormCorps.RemoveAll() end
---*Action*
function Events.UnitFormCorps.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
function Events.UnitFormCorps.Call(playerID, unitID) end
---*Action*
---@param playerID number
---@param unitID number
function Events.UnitFormCorps.CallImmediate(playerID, unitID) end
---*Action*
---@param func fun(playerID: number, unitID: number)
---@return fun(playerID: number, unitID: number)
function Events.UnitFormCorps.Add(func) end
---*Action*
---@param func function
function Events.UnitFormCorps.Remove(func) end

---@overload fun(playerID: number, unitID: number)
Events.UnitFortificationChanged = {}
---*Query*
---@return number amount
function Events.UnitFortificationChanged.Count() end
---*Action*
function Events.UnitFortificationChanged.RemoveAll() end
---*Action*
function Events.UnitFortificationChanged.Dispatch() end
Events.UnitFortificationChanged = {}
---*Query*
---@return number amount
function Events.UnitFortificationChanged.Count() end
---*Action*
function Events.UnitFortificationChanged.RemoveAll() end
---*Action*
function Events.UnitFortificationChanged.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
function Events.UnitFortificationChanged.Call(playerID, unitID) end
---*Action*
---@param playerID number
---@param unitID number
function Events.UnitFortificationChanged.CallImmediate(playerID, unitID) end
---*Action*
---@param func fun(playerID: number, unitID: number)
---@return fun(playerID: number, unitID: number)
function Events.UnitFortificationChanged.Add(func) end
---*Action*
---@param func function
function Events.UnitFortificationChanged.Remove(func) end

---@overload fun()
Events.UnitGreatPersonChanged = {}
---*Query*
---@return number amount
function Events.UnitGreatPersonChanged.Count() end
---*Action*
function Events.UnitGreatPersonChanged.RemoveAll() end
---*Action*
function Events.UnitGreatPersonChanged.Dispatch() end
Events.UnitGreatPersonChanged = {}
---*Query*
---@return number amount
function Events.UnitGreatPersonChanged.Count() end
---*Action*
function Events.UnitGreatPersonChanged.RemoveAll() end
---*Action*
function Events.UnitGreatPersonChanged.Dispatch() end
---*Action*
function Events.UnitGreatPersonChanged.Call() end
---*Action*
function Events.UnitGreatPersonChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.UnitGreatPersonChanged.Add(func) end
---*Action*
---@param func function
function Events.UnitGreatPersonChanged.Remove(func) end

---@overload fun(playerID: number, unitID: number, greatPersonClassID: number, greatPersonIndividualID: number)
Events.UnitGreatPersonCreated = {}
---*Query*
---@return number amount
function Events.UnitGreatPersonCreated.Count() end
---*Action*
function Events.UnitGreatPersonCreated.RemoveAll() end
---*Action*
function Events.UnitGreatPersonCreated.Dispatch() end
Events.UnitGreatPersonCreated = {}
---*Query*
---@return number amount
function Events.UnitGreatPersonCreated.Count() end
---*Action*
function Events.UnitGreatPersonCreated.RemoveAll() end
---*Action*
function Events.UnitGreatPersonCreated.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
---@param greatPersonClassID number
---@param greatPersonIndividualID number
function Events.UnitGreatPersonCreated.Call(playerID, unitID, greatPersonClassID, greatPersonIndividualID) end
---*Action*
---@param playerID number
---@param unitID number
---@param greatPersonClassID number
---@param greatPersonIndividualID number
function Events.UnitGreatPersonCreated.CallImmediate(playerID, unitID, greatPersonClassID, greatPersonIndividualID) end
---*Action*
---@param func fun(playerID: number, unitID: number, greatPersonClassID: number, greatPersonIndividualID: number)
---@return fun(playerID: number, unitID: number, greatPersonClassID: number, greatPersonIndividualID: number)
function Events.UnitGreatPersonCreated.Add(func) end
---*Action*
---@param func function
function Events.UnitGreatPersonCreated.Remove(func) end

---@overload fun(killedPlayerID: number, killedUnitID: number, playerID: number, unitID: number)
Events.UnitKilledInCombat = {}
---*Query*
---@return number amount
function Events.UnitKilledInCombat.Count() end
---*Action*
function Events.UnitKilledInCombat.RemoveAll() end
---*Action*
function Events.UnitKilledInCombat.Dispatch() end
Events.UnitKilledInCombat = {}
---*Query*
---@return number amount
function Events.UnitKilledInCombat.Count() end
---*Action*
function Events.UnitKilledInCombat.RemoveAll() end
---*Action*
function Events.UnitKilledInCombat.Dispatch() end
---*Action*
---@param killedPlayerID number
---@param killedUnitID number
---@param playerID number
---@param unitID number
function Events.UnitKilledInCombat.Call(killedPlayerID, killedUnitID, playerID, unitID) end
---*Action*
---@param killedPlayerID number
---@param killedUnitID number
---@param playerID number
---@param unitID number
function Events.UnitKilledInCombat.CallImmediate(killedPlayerID, killedUnitID, playerID, unitID) end
---*Action*
---@param func fun(killedPlayerID: number, killedUnitID: number, playerID: number, unitID: number)
---@return fun(killedPlayerID: number, killedUnitID: number, playerID: number, unitID: number)
function Events.UnitKilledInCombat.Add(func) end
---*Action*
---@param func function
function Events.UnitKilledInCombat.Remove(func) end

---@overload fun(playerID: number, unitID: number, X: number, Y: number)
Events.UnitMoveComplete = {}
---*Query*
---@return number amount
function Events.UnitMoveComplete.Count() end
---*Action*
function Events.UnitMoveComplete.RemoveAll() end
---*Action*
function Events.UnitMoveComplete.Dispatch() end
Events.UnitMoveComplete = {}
---*Query*
---@return number amount
function Events.UnitMoveComplete.Count() end
---*Action*
function Events.UnitMoveComplete.RemoveAll() end
---*Action*
function Events.UnitMoveComplete.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
---@param X number
---@param Y number
function Events.UnitMoveComplete.Call(playerID, unitID, X, Y) end
---*Action*
---@param playerID number
---@param unitID number
---@param X number
---@param Y number
function Events.UnitMoveComplete.CallImmediate(playerID, unitID, X, Y) end
---*Action*
---@param func fun(playerID: number, unitID: number, X: number, Y: number)
---@return fun(playerID: number, unitID: number, X: number, Y: number)
function Events.UnitMoveComplete.Add(func) end
---*Action*
---@param func function
function Events.UnitMoveComplete.Remove(func) end

---@overload fun(playerID: number, unitID: number, X: number, Y: number, locallyVisible: any, stateChange: any)
Events.UnitMoved = {}
---*Query*
---@return number amount
function Events.UnitMoved.Count() end
---*Action*
function Events.UnitMoved.RemoveAll() end
---*Action*
function Events.UnitMoved.Dispatch() end
Events.UnitMoved = {}
---*Query*
---@return number amount
function Events.UnitMoved.Count() end
---*Action*
function Events.UnitMoved.RemoveAll() end
---*Action*
function Events.UnitMoved.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
---@param X number
---@param Y number
---@param locallyVisible any
---@param stateChange any
function Events.UnitMoved.Call(playerID, unitID, X, Y, locallyVisible, stateChange) end
---*Action*
---@param playerID number
---@param unitID number
---@param X number
---@param Y number
---@param locallyVisible any
---@param stateChange any
function Events.UnitMoved.CallImmediate(playerID, unitID, X, Y, locallyVisible, stateChange) end
---*Action*
---@param func fun(playerID: number, unitID: number, X: number, Y: number, locallyVisible: any, stateChange: any)
---@return fun(playerID: number, unitID: number, X: number, Y: number, locallyVisible: any, stateChange: any)
function Events.UnitMoved.Add(func) end
---*Action*
---@param func function
function Events.UnitMoved.Remove(func) end

---@overload fun(playerID: number, unitID: number, movementPoints: number)
Events.UnitMovementPointsChanged = {}
---*Query*
---@return number amount
function Events.UnitMovementPointsChanged.Count() end
---*Action*
function Events.UnitMovementPointsChanged.RemoveAll() end
---*Action*
function Events.UnitMovementPointsChanged.Dispatch() end
Events.UnitMovementPointsChanged = {}
---*Query*
---@return number amount
function Events.UnitMovementPointsChanged.Count() end
---*Action*
function Events.UnitMovementPointsChanged.RemoveAll() end
---*Action*
function Events.UnitMovementPointsChanged.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
---@param movementPoints number
function Events.UnitMovementPointsChanged.Call(playerID, unitID, movementPoints) end
---*Action*
---@param playerID number
---@param unitID number
---@param movementPoints number
function Events.UnitMovementPointsChanged.CallImmediate(playerID, unitID, movementPoints) end
---*Action*
---@param func fun(playerID: number, unitID: number, movementPoints: number)
---@return fun(playerID: number, unitID: number, movementPoints: number)
function Events.UnitMovementPointsChanged.Add(func) end
---*Action*
---@param func function
function Events.UnitMovementPointsChanged.Remove(func) end

---@overload fun(playerID: number, unitID: number)
Events.UnitMovementPointsCleared = {}
---*Query*
---@return number amount
function Events.UnitMovementPointsCleared.Count() end
---*Action*
function Events.UnitMovementPointsCleared.RemoveAll() end
---*Action*
function Events.UnitMovementPointsCleared.Dispatch() end
Events.UnitMovementPointsCleared = {}
---*Query*
---@return number amount
function Events.UnitMovementPointsCleared.Count() end
---*Action*
function Events.UnitMovementPointsCleared.RemoveAll() end
---*Action*
function Events.UnitMovementPointsCleared.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
function Events.UnitMovementPointsCleared.Call(playerID, unitID) end
---*Action*
---@param playerID number
---@param unitID number
function Events.UnitMovementPointsCleared.CallImmediate(playerID, unitID) end
---*Action*
---@param func fun(playerID: number, unitID: number)
---@return fun(playerID: number, unitID: number)
function Events.UnitMovementPointsCleared.Add(func) end
---*Action*
---@param func function
function Events.UnitMovementPointsCleared.Remove(func) end

---@overload fun(playerID: number, unitID: number, MovementPoints: any)
Events.UnitMovementPointsRestored = {}
---*Query*
---@return number amount
function Events.UnitMovementPointsRestored.Count() end
---*Action*
function Events.UnitMovementPointsRestored.RemoveAll() end
---*Action*
function Events.UnitMovementPointsRestored.Dispatch() end
Events.UnitMovementPointsRestored = {}
---*Query*
---@return number amount
function Events.UnitMovementPointsRestored.Count() end
---*Action*
function Events.UnitMovementPointsRestored.RemoveAll() end
---*Action*
function Events.UnitMovementPointsRestored.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
---@param MovementPoints any
function Events.UnitMovementPointsRestored.Call(playerID, unitID, MovementPoints) end
---*Action*
---@param playerID number
---@param unitID number
---@param MovementPoints any
function Events.UnitMovementPointsRestored.CallImmediate(playerID, unitID, MovementPoints) end
---*Action*
---@param func fun(playerID: number, unitID: number, MovementPoints: any)
---@return fun(playerID: number, unitID: number, MovementPoints: any)
function Events.UnitMovementPointsRestored.Add(func) end
---*Action*
---@param func function
function Events.UnitMovementPointsRestored.Remove(func) end

---@overload fun(playerID: number, unitID: number, unknown: number, operationType: UnitOperationTypes)
Events.UnitOperationAdded = {}
---*Query*
---@return number amount
function Events.UnitOperationAdded.Count() end
---*Action*
function Events.UnitOperationAdded.RemoveAll() end
---*Action*
function Events.UnitOperationAdded.Dispatch() end
Events.UnitOperationAdded = {}
---*Query*
---@return number amount
function Events.UnitOperationAdded.Count() end
---*Action*
function Events.UnitOperationAdded.RemoveAll() end
---*Action*
function Events.UnitOperationAdded.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
---@param unknown number
---@param operationType UnitOperationTypes
function Events.UnitOperationAdded.Call(playerID, unitID, unknown, operationType) end
---*Action*
---@param playerID number
---@param unitID number
---@param unknown number
---@param operationType UnitOperationTypes
function Events.UnitOperationAdded.CallImmediate(playerID, unitID, unknown, operationType) end
---*Action*
---@param func fun(playerID: number, unitID: number, unknown: number, operationType: UnitOperationTypes)
---@return fun(playerID: number, unitID: number, unknown: number, operationType: UnitOperationTypes)
function Events.UnitOperationAdded.Add(func) end
---*Action*
---@param func function
function Events.UnitOperationAdded.Remove(func) end

---@overload fun(playerID: number, unitID: number, operationType: UnitOperationTypes, data1: number)
Events.UnitOperationDeactivated = {}
---*Query*
---@return number amount
function Events.UnitOperationDeactivated.Count() end
---*Action*
function Events.UnitOperationDeactivated.RemoveAll() end
---*Action*
function Events.UnitOperationDeactivated.Dispatch() end
Events.UnitOperationDeactivated = {}
---*Query*
---@return number amount
function Events.UnitOperationDeactivated.Count() end
---*Action*
function Events.UnitOperationDeactivated.RemoveAll() end
---*Action*
function Events.UnitOperationDeactivated.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
---@param operationType UnitOperationTypes
---@param data1 number
function Events.UnitOperationDeactivated.Call(playerID, unitID, operationType, data1) end
---*Action*
---@param playerID number
---@param unitID number
---@param operationType UnitOperationTypes
---@param data1 number
function Events.UnitOperationDeactivated.CallImmediate(playerID, unitID, operationType, data1) end
---*Action*
---@param func fun(playerID: number, unitID: number, operationType: UnitOperationTypes, data1: number)
---@return fun(playerID: number, unitID: number, operationType: UnitOperationTypes, data1: number)
function Events.UnitOperationDeactivated.Add(func) end
---*Action*
---@param func function
function Events.UnitOperationDeactivated.Remove(func) end

---@overload fun(playerID: number, unitID: number, commandType: UnitCommandTypes, data1: number)
Events.UnitOperationSegmentComplete = {}
---*Query*
---@return number amount
function Events.UnitOperationSegmentComplete.Count() end
---*Action*
function Events.UnitOperationSegmentComplete.RemoveAll() end
---*Action*
function Events.UnitOperationSegmentComplete.Dispatch() end
Events.UnitOperationSegmentComplete = {}
---*Query*
---@return number amount
function Events.UnitOperationSegmentComplete.Count() end
---*Action*
function Events.UnitOperationSegmentComplete.RemoveAll() end
---*Action*
function Events.UnitOperationSegmentComplete.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
---@param commandType UnitCommandTypes
---@param data1 number
function Events.UnitOperationSegmentComplete.Call(playerID, unitID, commandType, data1) end
---*Action*
---@param playerID number
---@param unitID number
---@param commandType UnitCommandTypes
---@param data1 number
function Events.UnitOperationSegmentComplete.CallImmediate(playerID, unitID, commandType, data1) end
---*Action*
---@param func fun(playerID: number, unitID: number, commandType: UnitCommandTypes, data1: number)
---@return fun(playerID: number, unitID: number, commandType: UnitCommandTypes, data1: number)
function Events.UnitOperationSegmentComplete.Add(func) end
---*Action*
---@param func function
function Events.UnitOperationSegmentComplete.Remove(func) end

---@overload fun(ownerID: number, unitID: number, operationID: number)
Events.UnitOperationStarted = {}
---*Query*
---@return number amount
function Events.UnitOperationStarted.Count() end
---*Action*
function Events.UnitOperationStarted.RemoveAll() end
---*Action*
function Events.UnitOperationStarted.Dispatch() end
Events.UnitOperationStarted = {}
---*Query*
---@return number amount
function Events.UnitOperationStarted.Count() end
---*Action*
function Events.UnitOperationStarted.RemoveAll() end
---*Action*
function Events.UnitOperationStarted.Dispatch() end
---*Action*
---@param ownerID number
---@param unitID number
---@param operationID number
function Events.UnitOperationStarted.Call(ownerID, unitID, operationID) end
---*Action*
---@param ownerID number
---@param unitID number
---@param operationID number
function Events.UnitOperationStarted.CallImmediate(ownerID, unitID, operationID) end
---*Action*
---@param func fun(ownerID: number, unitID: number, operationID: number)
---@return fun(ownerID: number, unitID: number, operationID: number)
function Events.UnitOperationStarted.Add(func) end
---*Action*
---@param func function
function Events.UnitOperationStarted.Remove(func) end

---@overload fun(playerID: number, unitID: number, commandType: UnitCommandTypes, data1: number)
Events.UnitOperationsCleared = {}
---*Query*
---@return number amount
function Events.UnitOperationsCleared.Count() end
---*Action*
function Events.UnitOperationsCleared.RemoveAll() end
---*Action*
function Events.UnitOperationsCleared.Dispatch() end
Events.UnitOperationsCleared = {}
---*Query*
---@return number amount
function Events.UnitOperationsCleared.Count() end
---*Action*
function Events.UnitOperationsCleared.RemoveAll() end
---*Action*
function Events.UnitOperationsCleared.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
---@param commandType UnitCommandTypes
---@param data1 number
function Events.UnitOperationsCleared.Call(playerID, unitID, commandType, data1) end
---*Action*
---@param playerID number
---@param unitID number
---@param commandType UnitCommandTypes
---@param data1 number
function Events.UnitOperationsCleared.CallImmediate(playerID, unitID, commandType, data1) end
---*Action*
---@param func fun(playerID: number, unitID: number, commandType: UnitCommandTypes, data1: number)
---@return fun(playerID: number, unitID: number, commandType: UnitCommandTypes, data1: number)
function Events.UnitOperationsCleared.Add(func) end
---*Action*
---@param func function
function Events.UnitOperationsCleared.Remove(func) end

---@overload fun()
Events.UnitParadropped = {}
---*Query*
---@return number amount
function Events.UnitParadropped.Count() end
---*Action*
function Events.UnitParadropped.RemoveAll() end
---*Action*
function Events.UnitParadropped.Dispatch() end
Events.UnitParadropped = {}
---*Query*
---@return number amount
function Events.UnitParadropped.Count() end
---*Action*
function Events.UnitParadropped.RemoveAll() end
---*Action*
function Events.UnitParadropped.Dispatch() end
---*Action*
function Events.UnitParadropped.Call() end
---*Action*
function Events.UnitParadropped.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.UnitParadropped.Add(func) end
---*Action*
---@param func function
function Events.UnitParadropped.Remove(func) end

---@overload fun(playerID: number, unitID: number)
Events.UnitPromoted = {}
---*Query*
---@return number amount
function Events.UnitPromoted.Count() end
---*Action*
function Events.UnitPromoted.RemoveAll() end
---*Action*
function Events.UnitPromoted.Dispatch() end
Events.UnitPromoted = {}
---*Query*
---@return number amount
function Events.UnitPromoted.Count() end
---*Action*
function Events.UnitPromoted.RemoveAll() end
---*Action*
function Events.UnitPromoted.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
function Events.UnitPromoted.Call(playerID, unitID) end
---*Action*
---@param playerID number
---@param unitID number
function Events.UnitPromoted.CallImmediate(playerID, unitID) end
---*Action*
---@param func fun(playerID: number, unitID: number)
---@return fun(playerID: number, unitID: number)
function Events.UnitPromoted.Add(func) end
---*Action*
---@param func function
function Events.UnitPromoted.Remove(func) end

---@overload fun(playerID: number, unitID: number, promotionID: number)
Events.UnitPromotionAvailable = {}
---*Query*
---@return number amount
function Events.UnitPromotionAvailable.Count() end
---*Action*
function Events.UnitPromotionAvailable.RemoveAll() end
---*Action*
function Events.UnitPromotionAvailable.Dispatch() end
Events.UnitPromotionAvailable = {}
---*Query*
---@return number amount
function Events.UnitPromotionAvailable.Count() end
---*Action*
function Events.UnitPromotionAvailable.RemoveAll() end
---*Action*
function Events.UnitPromotionAvailable.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
---@param promotionID number
function Events.UnitPromotionAvailable.Call(playerID, unitID, promotionID) end
---*Action*
---@param playerID number
---@param unitID number
---@param promotionID number
function Events.UnitPromotionAvailable.CallImmediate(playerID, unitID, promotionID) end
---*Action*
---@param func fun(playerID: number, unitID: number, promotionID: number)
---@return fun(playerID: number, unitID: number, promotionID: number)
function Events.UnitPromotionAvailable.Add(func) end
---*Action*
---@param func function
function Events.UnitPromotionAvailable.Remove(func) end

---@overload fun(playerID: number, unitID: number)
Events.UnitRemovedFromMap = {}
---*Query*
---@return number amount
function Events.UnitRemovedFromMap.Count() end
---*Action*
function Events.UnitRemovedFromMap.RemoveAll() end
---*Action*
function Events.UnitRemovedFromMap.Dispatch() end
Events.UnitRemovedFromMap = {}
---*Query*
---@return number amount
function Events.UnitRemovedFromMap.Count() end
---*Action*
function Events.UnitRemovedFromMap.RemoveAll() end
---*Action*
function Events.UnitRemovedFromMap.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
function Events.UnitRemovedFromMap.Call(playerID, unitID) end
---*Action*
---@param playerID number
---@param unitID number
function Events.UnitRemovedFromMap.CallImmediate(playerID, unitID) end
---*Action*
---@param func fun(playerID: number, unitID: number)
---@return fun(playerID: number, unitID: number)
function Events.UnitRemovedFromMap.Add(func) end
---*Action*
---@param func function
function Events.UnitRemovedFromMap.Remove(func) end

---@overload fun(playerID: number, unitID: number, X: number, Y: number)
Events.UnitTeleported = {}
---*Query*
---@return number amount
function Events.UnitTeleported.Count() end
---*Action*
function Events.UnitTeleported.RemoveAll() end
---*Action*
function Events.UnitTeleported.Dispatch() end
Events.UnitTeleported = {}
---*Query*
---@return number amount
function Events.UnitTeleported.Count() end
---*Action*
function Events.UnitTeleported.RemoveAll() end
---*Action*
function Events.UnitTeleported.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
---@param X number
---@param Y number
function Events.UnitTeleported.Call(playerID, unitID, X, Y) end
---*Action*
---@param playerID number
---@param unitID number
---@param X number
---@param Y number
function Events.UnitTeleported.CallImmediate(playerID, unitID, X, Y) end
---*Action*
---@param func fun(playerID: number, unitID: number, X: number, Y: number)
---@return fun(playerID: number, unitID: number, X: number, Y: number)
function Events.UnitTeleported.Add(func) end
---*Action*
---@param func function
function Events.UnitTeleported.Remove(func) end

---@overload fun(playerID: number, unitID: number)
Events.UnitTradeChanged = {}
---*Query*
---@return number amount
function Events.UnitTradeChanged.Count() end
---*Action*
function Events.UnitTradeChanged.RemoveAll() end
---*Action*
function Events.UnitTradeChanged.Dispatch() end
Events.UnitTradeChanged = {}
---*Query*
---@return number amount
function Events.UnitTradeChanged.Count() end
---*Action*
function Events.UnitTradeChanged.RemoveAll() end
---*Action*
function Events.UnitTradeChanged.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
function Events.UnitTradeChanged.Call(playerID, unitID) end
---*Action*
---@param playerID number
---@param unitID number
function Events.UnitTradeChanged.CallImmediate(playerID, unitID) end
---*Action*
---@param func fun(playerID: number, unitID: number)
---@return fun(playerID: number, unitID: number)
function Events.UnitTradeChanged.Add(func) end
---*Action*
---@param func function
function Events.UnitTradeChanged.Remove(func) end

---@overload fun(playerID: number, unitID: number)
Events.UnitUpgraded = {}
---*Query*
---@return number amount
function Events.UnitUpgraded.Count() end
---*Action*
function Events.UnitUpgraded.RemoveAll() end
---*Action*
function Events.UnitUpgraded.Dispatch() end
Events.UnitUpgraded = {}
---*Query*
---@return number amount
function Events.UnitUpgraded.Count() end
---*Action*
function Events.UnitUpgraded.RemoveAll() end
---*Action*
function Events.UnitUpgraded.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
function Events.UnitUpgraded.Call(playerID, unitID) end
---*Action*
---@param playerID number
---@param unitID number
function Events.UnitUpgraded.CallImmediate(playerID, unitID) end
---*Action*
---@param func fun(playerID: number, unitID: number)
---@return fun(playerID: number, unitID: number)
function Events.UnitUpgraded.Add(func) end
---*Action*
---@param func function
function Events.UnitUpgraded.Remove(func) end

---@overload fun(playerID: number, unitID: number)
Events.UnitVisibilityChanged = {}
---*Query*
---@return number amount
function Events.UnitVisibilityChanged.Count() end
---*Action*
function Events.UnitVisibilityChanged.RemoveAll() end
---*Action*
function Events.UnitVisibilityChanged.Dispatch() end
Events.UnitVisibilityChanged = {}
---*Query*
---@return number amount
function Events.UnitVisibilityChanged.Count() end
---*Action*
function Events.UnitVisibilityChanged.RemoveAll() end
---*Action*
function Events.UnitVisibilityChanged.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
function Events.UnitVisibilityChanged.Call(playerID, unitID) end
---*Action*
---@param playerID number
---@param unitID number
function Events.UnitVisibilityChanged.CallImmediate(playerID, unitID) end
---*Action*
---@param func fun(playerID: number, unitID: number)
---@return fun(playerID: number, unitID: number)
function Events.UnitVisibilityChanged.Add(func) end
---*Action*
---@param func function
function Events.UnitVisibilityChanged.Remove(func) end

---@overload fun(playerID: number, WMDIndex: number)
Events.WMDCountChanged = {}
---*Query*
---@return number amount
function Events.WMDCountChanged.Count() end
---*Action*
function Events.WMDCountChanged.RemoveAll() end
---*Action*
function Events.WMDCountChanged.Dispatch() end
Events.WMDCountChanged = {}
---*Query*
---@return number amount
function Events.WMDCountChanged.Count() end
---*Action*
function Events.WMDCountChanged.RemoveAll() end
---*Action*
function Events.WMDCountChanged.Dispatch() end
---*Action*
---@param playerID number
---@param WMDIndex number
function Events.WMDCountChanged.Call(playerID, WMDIndex) end
---*Action*
---@param playerID number
---@param WMDIndex number
function Events.WMDCountChanged.CallImmediate(playerID, WMDIndex) end
---*Action*
---@param func fun(playerID: number, WMDIndex: number)
---@return fun(playerID: number, WMDIndex: number)
function Events.WMDCountChanged.Add(func) end
---*Action*
---@param func function
function Events.WMDCountChanged.Remove(func) end

---@overload fun(X: number, Y: number, playerID: number, WMDIndex: number)
Events.WMDDetonated = {}
---*Query*
---@return number amount
function Events.WMDDetonated.Count() end
---*Action*
function Events.WMDDetonated.RemoveAll() end
---*Action*
function Events.WMDDetonated.Dispatch() end
Events.WMDDetonated = {}
---*Query*
---@return number amount
function Events.WMDDetonated.Count() end
---*Action*
function Events.WMDDetonated.RemoveAll() end
---*Action*
function Events.WMDDetonated.Dispatch() end
---*Action*
---@param X number
---@param Y number
---@param playerID number
---@param WMDIndex number
function Events.WMDDetonated.Call(X, Y, playerID, WMDIndex) end
---*Action*
---@param X number
---@param Y number
---@param playerID number
---@param WMDIndex number
function Events.WMDDetonated.CallImmediate(X, Y, playerID, WMDIndex) end
---*Action*
---@param func fun(X: number, Y: number, playerID: number, WMDIndex: number)
---@return fun(X: number, Y: number, playerID: number, WMDIndex: number)
function Events.WMDDetonated.Add(func) end
---*Action*
---@param func function
function Events.WMDDetonated.Remove(func) end

---@overload fun()
Events.WMDFalloutChanged = {}
---*Query*
---@return number amount
function Events.WMDFalloutChanged.Count() end
---*Action*
function Events.WMDFalloutChanged.RemoveAll() end
---*Action*
function Events.WMDFalloutChanged.Dispatch() end
Events.WMDFalloutChanged = {}
---*Query*
---@return number amount
function Events.WMDFalloutChanged.Count() end
---*Action*
function Events.WMDFalloutChanged.RemoveAll() end
---*Action*
function Events.WMDFalloutChanged.Dispatch() end
---*Action*
function Events.WMDFalloutChanged.Call() end
---*Action*
function Events.WMDFalloutChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.WMDFalloutChanged.Add(func) end
---*Action*
---@param func function
function Events.WMDFalloutChanged.Remove(func) end

---@overload fun()
Events.WMDFalloutVisibilityChanged = {}
---*Query*
---@return number amount
function Events.WMDFalloutVisibilityChanged.Count() end
---*Action*
function Events.WMDFalloutVisibilityChanged.RemoveAll() end
---*Action*
function Events.WMDFalloutVisibilityChanged.Dispatch() end
Events.WMDFalloutVisibilityChanged = {}
---*Query*
---@return number amount
function Events.WMDFalloutVisibilityChanged.Count() end
---*Action*
function Events.WMDFalloutVisibilityChanged.RemoveAll() end
---*Action*
function Events.WMDFalloutVisibilityChanged.Dispatch() end
---*Action*
function Events.WMDFalloutVisibilityChanged.Call() end
---*Action*
function Events.WMDFalloutVisibilityChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.WMDFalloutVisibilityChanged.Add(func) end
---*Action*
---@param func function
function Events.WMDFalloutVisibilityChanged.Remove(func) end

---@overload fun(X: number, Y: number, buildingIndex: number, playerIndex: number, cityID: number, percentComplete: number, unknown: number)
Events.WonderCompleted = {}
---*Query*
---@return number amount
function Events.WonderCompleted.Count() end
---*Action*
function Events.WonderCompleted.RemoveAll() end
---*Action*
function Events.WonderCompleted.Dispatch() end
Events.WonderCompleted = {}
---*Query*
---@return number amount
function Events.WonderCompleted.Count() end
---*Action*
function Events.WonderCompleted.RemoveAll() end
---*Action*
function Events.WonderCompleted.Dispatch() end
---*Action*
---@param X number
---@param Y number
---@param buildingIndex number
---@param playerIndex number
---@param cityID number
---@param percentComplete number
---@param unknown number
function Events.WonderCompleted.Call(X, Y, buildingIndex, playerIndex, cityID, percentComplete, unknown) end
---*Action*
---@param X number
---@param Y number
---@param buildingIndex number
---@param playerIndex number
---@param cityID number
---@param percentComplete number
---@param unknown number
function Events.WonderCompleted.CallImmediate(X, Y, buildingIndex, playerIndex, cityID, percentComplete, unknown) end
---*Action*
---@param func fun(X: number, Y: number, buildingIndex: number, playerIndex: number, cityID: number, percentComplete: number, unknown: number)
---@return fun(X: number, Y: number, buildingIndex: number, playerIndex: number, cityID: number, percentComplete: number, unknown: number)
function Events.WonderCompleted.Add(func) end
---*Action*
---@param func function
function Events.WonderCompleted.Remove(func) end

---@overload fun(reportingStatusType: ReportingStatusTypes, gossipIndex: number, X: number, Y: number, text: string)
Events.WorldTextMessage = {}
---*Query*
---@return number amount
function Events.WorldTextMessage.Count() end
---*Action*
function Events.WorldTextMessage.RemoveAll() end
---*Action*
function Events.WorldTextMessage.Dispatch() end
Events.WorldTextMessage = {}
---*Query*
---@return number amount
function Events.WorldTextMessage.Count() end
---*Action*
function Events.WorldTextMessage.RemoveAll() end
---*Action*
function Events.WorldTextMessage.Dispatch() end
---*Action*
---@param reportingStatusType ReportingStatusTypes
---@param gossipIndex number
---@param X number
---@param Y number
---@param text string
function Events.WorldTextMessage.Call(reportingStatusType, gossipIndex, X, Y, text) end
---*Action*
---@param reportingStatusType ReportingStatusTypes
---@param gossipIndex number
---@param X number
---@param Y number
---@param text string
function Events.WorldTextMessage.CallImmediate(reportingStatusType, gossipIndex, X, Y, text) end
---*Action*
---@param func fun(reportingStatusType: ReportingStatusTypes, gossipIndex: number, X: number, Y: number, text: string)
---@return fun(reportingStatusType: ReportingStatusTypes, gossipIndex: number, X: number, Y: number, text: string)
function Events.WorldTextMessage.Add(func) end
---*Action*
---@param func function
function Events.WorldTextMessage.Remove(func) end

---@overload fun(playerID: number, unitID: number)
Events.UnitCreated = {}
---*Query*
---@return number amount
function Events.UnitCreated.Count() end
---*Action*
function Events.UnitCreated.RemoveAll() end
---*Action*
function Events.UnitCreated.Dispatch() end
Events.UnitCreated = {}
---*Query*
---@return number amount
function Events.UnitCreated.Count() end
---*Action*
function Events.UnitCreated.RemoveAll() end
---*Action*
function Events.UnitCreated.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
function Events.UnitCreated.Call(playerID, unitID) end
---*Action*
---@param playerID number
---@param unitID number
function Events.UnitCreated.CallImmediate(playerID, unitID) end
---*Action*
---@param func fun(playerID: number, unitID: number)
---@return fun(playerID: number, unitID: number)
function Events.UnitCreated.Add(func) end
---*Action*
---@param func function
function Events.UnitCreated.Remove(func) end

---@overload fun(prevInterfaceModeType: InterfaceModeTypes, newInterfaceModeType: InterfaceModeTypes)
Events.InterfaceModeChanged = {}
---*Query*
---@return number amount
function Events.InterfaceModeChanged.Count() end
---*Action*
function Events.InterfaceModeChanged.RemoveAll() end
---*Action*
function Events.InterfaceModeChanged.Dispatch() end
Events.InterfaceModeChanged = {}
---*Query*
---@return number amount
function Events.InterfaceModeChanged.Count() end
---*Action*
function Events.InterfaceModeChanged.RemoveAll() end
---*Action*
function Events.InterfaceModeChanged.Dispatch() end
---*Action*
---@param prevInterfaceModeType InterfaceModeTypes
---@param newInterfaceModeType InterfaceModeTypes
function Events.InterfaceModeChanged.Call(prevInterfaceModeType, newInterfaceModeType) end
---*Action*
---@param prevInterfaceModeType InterfaceModeTypes
---@param newInterfaceModeType InterfaceModeTypes
function Events.InterfaceModeChanged.CallImmediate(prevInterfaceModeType, newInterfaceModeType) end
---*Action*
---@param func fun(prevInterfaceModeType: InterfaceModeTypes, newInterfaceModeType: InterfaceModeTypes)
---@return fun(prevInterfaceModeType: InterfaceModeTypes, newInterfaceModeType: InterfaceModeTypes)
function Events.InterfaceModeChanged.Add(func) end
---*Action*
---@param func function
function Events.InterfaceModeChanged.Remove(func) end

---@overload fun(playerID: number, unitID: number, hexI: number, hexJ: number, hexK: number, isSelected: boolean, IsEditable: boolean)
Events.UnitSelectionChanged = {}
---*Query*
---@return number amount
function Events.UnitSelectionChanged.Count() end
---*Action*
function Events.UnitSelectionChanged.RemoveAll() end
---*Action*
function Events.UnitSelectionChanged.Dispatch() end
Events.UnitSelectionChanged = {}
---*Query*
---@return number amount
function Events.UnitSelectionChanged.Count() end
---*Action*
function Events.UnitSelectionChanged.RemoveAll() end
---*Action*
function Events.UnitSelectionChanged.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
---@param hexI number
---@param hexJ number
---@param hexK number
---@param isSelected boolean
---@param IsEditable boolean
function Events.UnitSelectionChanged.Call(playerID, unitID, hexI, hexJ, hexK, isSelected, IsEditable) end
---*Action*
---@param playerID number
---@param unitID number
---@param hexI number
---@param hexJ number
---@param hexK number
---@param isSelected boolean
---@param IsEditable boolean
function Events.UnitSelectionChanged.CallImmediate(playerID, unitID, hexI, hexJ, hexK, isSelected, IsEditable) end
---*Action*
---@param func fun(playerID: number, unitID: number, hexI: number, hexJ: number, hexK: number, isSelected: boolean, IsEditable: boolean)
---@return fun(playerID: number, unitID: number, hexI: number, hexJ: number, hexK: number, isSelected: boolean, IsEditable: boolean)
function Events.UnitSelectionChanged.Add(func) end
---*Action*
---@param func function
function Events.UnitSelectionChanged.Remove(func) end

---@overload fun(actionID: number)
Events.InputActionTriggered = {}
---*Query*
---@return number amount
function Events.InputActionTriggered.Count() end
---*Action*
function Events.InputActionTriggered.RemoveAll() end
---*Action*
function Events.InputActionTriggered.Dispatch() end
Events.InputActionTriggered = {}
---*Query*
---@return number amount
function Events.InputActionTriggered.Count() end
---*Action*
function Events.InputActionTriggered.RemoveAll() end
---*Action*
function Events.InputActionTriggered.Dispatch() end
---*Action*
---@param actionID number
function Events.InputActionTriggered.Call(actionID) end
---*Action*
---@param actionID number
function Events.InputActionTriggered.CallImmediate(actionID) end
---*Action*
---@param func fun(actionID: number)
---@return fun(actionID: number)
function Events.InputActionTriggered.Add(func) end
---*Action*
---@param func function
function Events.InputActionTriggered.Remove(func) end

---@overload fun(playerID: number, unitID: number, hexI: number, hexJ: number, hexK: number, isSelected: boolean, IsEditable: boolean)
Events.CitySelectionChanged = {}
---*Query*
---@return number amount
function Events.CitySelectionChanged.Count() end
---*Action*
function Events.CitySelectionChanged.RemoveAll() end
---*Action*
function Events.CitySelectionChanged.Dispatch() end
Events.CitySelectionChanged = {}
---*Query*
---@return number amount
function Events.CitySelectionChanged.Count() end
---*Action*
function Events.CitySelectionChanged.RemoveAll() end
---*Action*
function Events.CitySelectionChanged.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
---@param hexI number
---@param hexJ number
---@param hexK number
---@param isSelected boolean
---@param IsEditable boolean
function Events.CitySelectionChanged.Call(playerID, unitID, hexI, hexJ, hexK, isSelected, IsEditable) end
---*Action*
---@param playerID number
---@param unitID number
---@param hexI number
---@param hexJ number
---@param hexK number
---@param isSelected boolean
---@param IsEditable boolean
function Events.CitySelectionChanged.CallImmediate(playerID, unitID, hexI, hexJ, hexK, isSelected, IsEditable) end
---*Action*
---@param func fun(playerID: number, unitID: number, hexI: number, hexJ: number, hexK: number, isSelected: boolean, IsEditable: boolean)
---@return fun(playerID: number, unitID: number, hexI: number, hexJ: number, hexK: number, isSelected: boolean, IsEditable: boolean)
function Events.CitySelectionChanged.Add(func) end
---*Action*
---@param func function
function Events.CitySelectionChanged.Remove(func) end

---@overload fun()
Events.EventPopupResponse = {}
---*Query*
---@return number amount
function Events.EventPopupResponse.Count() end
---*Action*
function Events.EventPopupResponse.RemoveAll() end
---*Action*
function Events.EventPopupResponse.Dispatch() end
Events.EventPopupResponse = {}
---*Query*
---@return number amount
function Events.EventPopupResponse.Count() end
---*Action*
function Events.EventPopupResponse.RemoveAll() end
---*Action*
function Events.EventPopupResponse.Dispatch() end
---*Action*
function Events.EventPopupResponse.Call() end
---*Action*
function Events.EventPopupResponse.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.EventPopupResponse.Add(func) end
---*Action*
---@param func function
function Events.EventPopupResponse.Remove(func) end

---@overload fun()
Events.CombatVisBegin = {}
---*Query*
---@return number amount
function Events.CombatVisBegin.Count() end
---*Action*
function Events.CombatVisBegin.RemoveAll() end
---*Action*
function Events.CombatVisBegin.Dispatch() end
Events.CombatVisBegin = {}
---*Query*
---@return number amount
function Events.CombatVisBegin.Count() end
---*Action*
function Events.CombatVisBegin.RemoveAll() end
---*Action*
function Events.CombatVisBegin.Dispatch() end
---*Action*
function Events.CombatVisBegin.Call() end
---*Action*
function Events.CombatVisBegin.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.CombatVisBegin.Add(func) end
---*Action*
---@param func function
function Events.CombatVisBegin.Remove(func) end

---@overload fun()
Events.CrossPlayServersConnected = {}
---*Query*
---@return number amount
function Events.CrossPlayServersConnected.Count() end
---*Action*
function Events.CrossPlayServersConnected.RemoveAll() end
---*Action*
function Events.CrossPlayServersConnected.Dispatch() end
Events.CrossPlayServersConnected = {}
---*Query*
---@return number amount
function Events.CrossPlayServersConnected.Count() end
---*Action*
function Events.CrossPlayServersConnected.RemoveAll() end
---*Action*
function Events.CrossPlayServersConnected.Dispatch() end
---*Action*
function Events.CrossPlayServersConnected.Call() end
---*Action*
function Events.CrossPlayServersConnected.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.CrossPlayServersConnected.Add(func) end
---*Action*
---@param func function
function Events.CrossPlayServersConnected.Remove(func) end

---@overload fun()
Events.GameConfigChanged = {}
---*Query*
---@return number amount
function Events.GameConfigChanged.Count() end
---*Action*
function Events.GameConfigChanged.RemoveAll() end
---*Action*
function Events.GameConfigChanged.Dispatch() end
Events.GameConfigChanged = {}
---*Query*
---@return number amount
function Events.GameConfigChanged.Count() end
---*Action*
function Events.GameConfigChanged.RemoveAll() end
---*Action*
function Events.GameConfigChanged.Dispatch() end
---*Action*
function Events.GameConfigChanged.Call() end
---*Action*
function Events.GameConfigChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.GameConfigChanged.Add(func) end
---*Action*
---@param func function
function Events.GameConfigChanged.Remove(func) end

---@overload fun()
Events.UploadCloudPlayerConfigComplete = {}
---*Query*
---@return number amount
function Events.UploadCloudPlayerConfigComplete.Count() end
---*Action*
function Events.UploadCloudPlayerConfigComplete.RemoveAll() end
---*Action*
function Events.UploadCloudPlayerConfigComplete.Dispatch() end
Events.UploadCloudPlayerConfigComplete = {}
---*Query*
---@return number amount
function Events.UploadCloudPlayerConfigComplete.Count() end
---*Action*
function Events.UploadCloudPlayerConfigComplete.RemoveAll() end
---*Action*
function Events.UploadCloudPlayerConfigComplete.Dispatch() end
---*Action*
function Events.UploadCloudPlayerConfigComplete.Call() end
---*Action*
function Events.UploadCloudPlayerConfigComplete.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.UploadCloudPlayerConfigComplete.Add(func) end
---*Action*
---@param func function
function Events.UploadCloudPlayerConfigComplete.Remove(func) end

---@overload fun()
Events.MultiplayerGameLaunchFailed = {}
---*Query*
---@return number amount
function Events.MultiplayerGameLaunchFailed.Count() end
---*Action*
function Events.MultiplayerGameLaunchFailed.RemoveAll() end
---*Action*
function Events.MultiplayerGameLaunchFailed.Dispatch() end
Events.MultiplayerGameLaunchFailed = {}
---*Query*
---@return number amount
function Events.MultiplayerGameLaunchFailed.Count() end
---*Action*
function Events.MultiplayerGameLaunchFailed.RemoveAll() end
---*Action*
function Events.MultiplayerGameLaunchFailed.Dispatch() end
---*Action*
function Events.MultiplayerGameLaunchFailed.Call() end
---*Action*
function Events.MultiplayerGameLaunchFailed.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.MultiplayerGameLaunchFailed.Add(func) end
---*Action*
---@param func function
function Events.MultiplayerGameLaunchFailed.Remove(func) end

---@overload fun()
Events.WorldBuilderSignal = {}
---*Query*
---@return number amount
function Events.WorldBuilderSignal.Count() end
---*Action*
function Events.WorldBuilderSignal.RemoveAll() end
---*Action*
function Events.WorldBuilderSignal.Dispatch() end
Events.WorldBuilderSignal = {}
---*Query*
---@return number amount
function Events.WorldBuilderSignal.Count() end
---*Action*
function Events.WorldBuilderSignal.RemoveAll() end
---*Action*
function Events.WorldBuilderSignal.Dispatch() end
---*Action*
function Events.WorldBuilderSignal.Call() end
---*Action*
function Events.WorldBuilderSignal.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.WorldBuilderSignal.Add(func) end
---*Action*
---@param func function
function Events.WorldBuilderSignal.Remove(func) end

---@overload fun()
Events.LoadComplete = {}
---*Query*
---@return number amount
function Events.LoadComplete.Count() end
---*Action*
function Events.LoadComplete.RemoveAll() end
---*Action*
function Events.LoadComplete.Dispatch() end
Events.LoadComplete = {}
---*Query*
---@return number amount
function Events.LoadComplete.Count() end
---*Action*
function Events.LoadComplete.RemoveAll() end
---*Action*
function Events.LoadComplete.Dispatch() end
---*Action*
function Events.LoadComplete.Call() end
---*Action*
function Events.LoadComplete.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.LoadComplete.Add(func) end
---*Action*
---@param func function
function Events.LoadComplete.Remove(func) end

---@overload fun()
Events.PlayCameraAnimationAtHex = {}
---*Query*
---@return number amount
function Events.PlayCameraAnimationAtHex.Count() end
---*Action*
function Events.PlayCameraAnimationAtHex.RemoveAll() end
---*Action*
function Events.PlayCameraAnimationAtHex.Dispatch() end
Events.PlayCameraAnimationAtHex = {}
---*Query*
---@return number amount
function Events.PlayCameraAnimationAtHex.Count() end
---*Action*
function Events.PlayCameraAnimationAtHex.RemoveAll() end
---*Action*
function Events.PlayCameraAnimationAtHex.Dispatch() end
---*Action*
function Events.PlayCameraAnimationAtHex.Call() end
---*Action*
function Events.PlayCameraAnimationAtHex.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.PlayCameraAnimationAtHex.Add(func) end
---*Action*
---@param func function
function Events.PlayCameraAnimationAtHex.Remove(func) end

---@overload fun()
Events.My2KActivate = {}
---*Query*
---@return number amount
function Events.My2KActivate.Count() end
---*Action*
function Events.My2KActivate.RemoveAll() end
---*Action*
function Events.My2KActivate.Dispatch() end
Events.My2KActivate = {}
---*Query*
---@return number amount
function Events.My2KActivate.Count() end
---*Action*
function Events.My2KActivate.RemoveAll() end
---*Action*
function Events.My2KActivate.Dispatch() end
---*Action*
function Events.My2KActivate.Call() end
---*Action*
function Events.My2KActivate.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.My2KActivate.Add(func) end
---*Action*
---@param func function
function Events.My2KActivate.Remove(func) end

---@overload fun()
Events.UserConfirmedClose = {}
---*Query*
---@return number amount
function Events.UserConfirmedClose.Count() end
---*Action*
function Events.UserConfirmedClose.RemoveAll() end
---*Action*
function Events.UserConfirmedClose.Dispatch() end
Events.UserConfirmedClose = {}
---*Query*
---@return number amount
function Events.UserConfirmedClose.Count() end
---*Action*
function Events.UserConfirmedClose.RemoveAll() end
---*Action*
function Events.UserConfirmedClose.Dispatch() end
---*Action*
function Events.UserConfirmedClose.Call() end
---*Action*
function Events.UserConfirmedClose.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.UserConfirmedClose.Add(func) end
---*Action*
---@param func function
function Events.UserConfirmedClose.Remove(func) end

---@overload fun()
Events.MultiplayerPlayerConnected = {}
---*Query*
---@return number amount
function Events.MultiplayerPlayerConnected.Count() end
---*Action*
function Events.MultiplayerPlayerConnected.RemoveAll() end
---*Action*
function Events.MultiplayerPlayerConnected.Dispatch() end
Events.MultiplayerPlayerConnected = {}
---*Query*
---@return number amount
function Events.MultiplayerPlayerConnected.Count() end
---*Action*
function Events.MultiplayerPlayerConnected.RemoveAll() end
---*Action*
function Events.MultiplayerPlayerConnected.Dispatch() end
---*Action*
function Events.MultiplayerPlayerConnected.Call() end
---*Action*
function Events.MultiplayerPlayerConnected.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.MultiplayerPlayerConnected.Add(func) end
---*Action*
---@param func function
function Events.MultiplayerPlayerConnected.Remove(func) end

---@overload fun()
Events.CityProductionQueueChanged = {}
---*Query*
---@return number amount
function Events.CityProductionQueueChanged.Count() end
---*Action*
function Events.CityProductionQueueChanged.RemoveAll() end
---*Action*
function Events.CityProductionQueueChanged.Dispatch() end
Events.CityProductionQueueChanged = {}
---*Query*
---@return number amount
function Events.CityProductionQueueChanged.Count() end
---*Action*
function Events.CityProductionQueueChanged.RemoveAll() end
---*Action*
function Events.CityProductionQueueChanged.Dispatch() end
---*Action*
function Events.CityProductionQueueChanged.Call() end
---*Action*
function Events.CityProductionQueueChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.CityProductionQueueChanged.Add(func) end
---*Action*
---@param func function
function Events.CityProductionQueueChanged.Remove(func) end

---@overload fun()
Events.SteamFriendsStatusUpdated = {}
---*Query*
---@return number amount
function Events.SteamFriendsStatusUpdated.Count() end
---*Action*
function Events.SteamFriendsStatusUpdated.RemoveAll() end
---*Action*
function Events.SteamFriendsStatusUpdated.Dispatch() end
Events.SteamFriendsStatusUpdated = {}
---*Query*
---@return number amount
function Events.SteamFriendsStatusUpdated.Count() end
---*Action*
function Events.SteamFriendsStatusUpdated.RemoveAll() end
---*Action*
function Events.SteamFriendsStatusUpdated.Dispatch() end
---*Action*
function Events.SteamFriendsStatusUpdated.Call() end
---*Action*
function Events.SteamFriendsStatusUpdated.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.SteamFriendsStatusUpdated.Add(func) end
---*Action*
---@param func function
function Events.SteamFriendsStatusUpdated.Remove(func) end

---@overload fun()
Events.GameCoreEventPublishComplete = {}
---*Query*
---@return number amount
function Events.GameCoreEventPublishComplete.Count() end
---*Action*
function Events.GameCoreEventPublishComplete.RemoveAll() end
---*Action*
function Events.GameCoreEventPublishComplete.Dispatch() end
Events.GameCoreEventPublishComplete = {}
---*Query*
---@return number amount
function Events.GameCoreEventPublishComplete.Count() end
---*Action*
function Events.GameCoreEventPublishComplete.RemoveAll() end
---*Action*
function Events.GameCoreEventPublishComplete.Dispatch() end
---*Action*
function Events.GameCoreEventPublishComplete.Call() end
---*Action*
function Events.GameCoreEventPublishComplete.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.GameCoreEventPublishComplete.Add(func) end
---*Action*
---@param func function
function Events.GameCoreEventPublishComplete.Remove(func) end

---@overload fun()
Events.UserRequestClose = {}
---*Query*
---@return number amount
function Events.UserRequestClose.Count() end
---*Action*
function Events.UserRequestClose.RemoveAll() end
---*Action*
function Events.UserRequestClose.Dispatch() end
Events.UserRequestClose = {}
---*Query*
---@return number amount
function Events.UserRequestClose.Count() end
---*Action*
function Events.UserRequestClose.RemoveAll() end
---*Action*
function Events.UserRequestClose.Dispatch() end
---*Action*
function Events.UserRequestClose.Call() end
---*Action*
function Events.UserRequestClose.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.UserRequestClose.Add(func) end
---*Action*
---@param func function
function Events.UserRequestClose.Remove(func) end

---@overload fun()
Events.MultiplayerChat = {}
---*Query*
---@return number amount
function Events.MultiplayerChat.Count() end
---*Action*
function Events.MultiplayerChat.RemoveAll() end
---*Action*
function Events.MultiplayerChat.Dispatch() end
Events.MultiplayerChat = {}
---*Query*
---@return number amount
function Events.MultiplayerChat.Count() end
---*Action*
function Events.MultiplayerChat.RemoveAll() end
---*Action*
function Events.MultiplayerChat.Dispatch() end
---*Action*
function Events.MultiplayerChat.Call() end
---*Action*
function Events.MultiplayerChat.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.MultiplayerChat.Add(func) end
---*Action*
---@param func function
function Events.MultiplayerChat.Remove(func) end

---@overload fun()
Events.BenchmarkStart = {}
---*Query*
---@return number amount
function Events.BenchmarkStart.Count() end
---*Action*
function Events.BenchmarkStart.RemoveAll() end
---*Action*
function Events.BenchmarkStart.Dispatch() end
Events.BenchmarkStart = {}
---*Query*
---@return number amount
function Events.BenchmarkStart.Count() end
---*Action*
function Events.BenchmarkStart.RemoveAll() end
---*Action*
function Events.BenchmarkStart.Dispatch() end
---*Action*
function Events.BenchmarkStart.Call() end
---*Action*
function Events.BenchmarkStart.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.BenchmarkStart.Add(func) end
---*Action*
---@param func function
function Events.BenchmarkStart.Remove(func) end

---@overload fun()
Events.MultiplayerGameAbandoned = {}
---*Query*
---@return number amount
function Events.MultiplayerGameAbandoned.Count() end
---*Action*
function Events.MultiplayerGameAbandoned.RemoveAll() end
---*Action*
function Events.MultiplayerGameAbandoned.Dispatch() end
Events.MultiplayerGameAbandoned = {}
---*Query*
---@return number amount
function Events.MultiplayerGameAbandoned.Count() end
---*Action*
function Events.MultiplayerGameAbandoned.RemoveAll() end
---*Action*
function Events.MultiplayerGameAbandoned.Dispatch() end
---*Action*
function Events.MultiplayerGameAbandoned.Call() end
---*Action*
function Events.MultiplayerGameAbandoned.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.MultiplayerGameAbandoned.Add(func) end
---*Action*
---@param func function
function Events.MultiplayerGameAbandoned.Remove(func) end

---@overload fun()
Events.OptionChangeRequiresAppRestart = {}
---*Query*
---@return number amount
function Events.OptionChangeRequiresAppRestart.Count() end
---*Action*
function Events.OptionChangeRequiresAppRestart.RemoveAll() end
---*Action*
function Events.OptionChangeRequiresAppRestart.Dispatch() end
Events.OptionChangeRequiresAppRestart = {}
---*Query*
---@return number amount
function Events.OptionChangeRequiresAppRestart.Count() end
---*Action*
function Events.OptionChangeRequiresAppRestart.RemoveAll() end
---*Action*
function Events.OptionChangeRequiresAppRestart.Dispatch() end
---*Action*
function Events.OptionChangeRequiresAppRestart.Call() end
---*Action*
function Events.OptionChangeRequiresAppRestart.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.OptionChangeRequiresAppRestart.Add(func) end
---*Action*
---@param func function
function Events.OptionChangeRequiresAppRestart.Remove(func) end

---@overload fun()
Events.SteamServersDisconnected = {}
---*Query*
---@return number amount
function Events.SteamServersDisconnected.Count() end
---*Action*
function Events.SteamServersDisconnected.RemoveAll() end
---*Action*
function Events.SteamServersDisconnected.Dispatch() end
Events.SteamServersDisconnected = {}
---*Query*
---@return number amount
function Events.SteamServersDisconnected.Count() end
---*Action*
function Events.SteamServersDisconnected.RemoveAll() end
---*Action*
function Events.SteamServersDisconnected.Dispatch() end
---*Action*
function Events.SteamServersDisconnected.Call() end
---*Action*
function Events.SteamServersDisconnected.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.SteamServersDisconnected.Add(func) end
---*Action*
---@param func function
function Events.SteamServersDisconnected.Remove(func) end

---@overload fun()
Events.PlayCameraAnimationAtPos = {}
---*Query*
---@return number amount
function Events.PlayCameraAnimationAtPos.Count() end
---*Action*
function Events.PlayCameraAnimationAtPos.RemoveAll() end
---*Action*
function Events.PlayCameraAnimationAtPos.Dispatch() end
Events.PlayCameraAnimationAtPos = {}
---*Query*
---@return number amount
function Events.PlayCameraAnimationAtPos.Count() end
---*Action*
function Events.PlayCameraAnimationAtPos.RemoveAll() end
---*Action*
function Events.PlayCameraAnimationAtPos.Dispatch() end
---*Action*
function Events.PlayCameraAnimationAtPos.Call() end
---*Action*
function Events.PlayCameraAnimationAtPos.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.PlayCameraAnimationAtPos.Add(func) end
---*Action*
---@param func function
function Events.PlayCameraAnimationAtPos.Remove(func) end

---@overload fun()
Events.OptionChangeRequiresResolutionAck = {}
---*Query*
---@return number amount
function Events.OptionChangeRequiresResolutionAck.Count() end
---*Action*
function Events.OptionChangeRequiresResolutionAck.RemoveAll() end
---*Action*
function Events.OptionChangeRequiresResolutionAck.Dispatch() end
Events.OptionChangeRequiresResolutionAck = {}
---*Query*
---@return number amount
function Events.OptionChangeRequiresResolutionAck.Count() end
---*Action*
function Events.OptionChangeRequiresResolutionAck.RemoveAll() end
---*Action*
function Events.OptionChangeRequiresResolutionAck.Dispatch() end
---*Action*
function Events.OptionChangeRequiresResolutionAck.Call() end
---*Action*
function Events.OptionChangeRequiresResolutionAck.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.OptionChangeRequiresResolutionAck.Add(func) end
---*Action*
---@param func function
function Events.OptionChangeRequiresResolutionAck.Remove(func) end

---@overload fun()
Events.UserSetupWarning = {}
---*Query*
---@return number amount
function Events.UserSetupWarning.Count() end
---*Action*
function Events.UserSetupWarning.RemoveAll() end
---*Action*
function Events.UserSetupWarning.Dispatch() end
Events.UserSetupWarning = {}
---*Query*
---@return number amount
function Events.UserSetupWarning.Count() end
---*Action*
function Events.UserSetupWarning.RemoveAll() end
---*Action*
function Events.UserSetupWarning.Dispatch() end
---*Action*
function Events.UserSetupWarning.Call() end
---*Action*
function Events.UserSetupWarning.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.UserSetupWarning.Add(func) end
---*Action*
---@param func function
function Events.UserSetupWarning.Remove(func) end

---@overload fun()
Events.BarbarianClanConversionDisabled = {}
---*Query*
---@return number amount
function Events.BarbarianClanConversionDisabled.Count() end
---*Action*
function Events.BarbarianClanConversionDisabled.RemoveAll() end
---*Action*
function Events.BarbarianClanConversionDisabled.Dispatch() end
Events.BarbarianClanConversionDisabled = {}
---*Query*
---@return number amount
function Events.BarbarianClanConversionDisabled.Count() end
---*Action*
function Events.BarbarianClanConversionDisabled.RemoveAll() end
---*Action*
function Events.BarbarianClanConversionDisabled.Dispatch() end
---*Action*
function Events.BarbarianClanConversionDisabled.Call() end
---*Action*
function Events.BarbarianClanConversionDisabled.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.BarbarianClanConversionDisabled.Add(func) end
---*Action*
---@param func function
function Events.BarbarianClanConversionDisabled.Remove(func) end

---@overload fun()
Events.LoadScreenContentReady = {}
---*Query*
---@return number amount
function Events.LoadScreenContentReady.Count() end
---*Action*
function Events.LoadScreenContentReady.RemoveAll() end
---*Action*
function Events.LoadScreenContentReady.Dispatch() end
Events.LoadScreenContentReady = {}
---*Query*
---@return number amount
function Events.LoadScreenContentReady.Count() end
---*Action*
function Events.LoadScreenContentReady.RemoveAll() end
---*Action*
function Events.LoadScreenContentReady.Dispatch() end
---*Action*
function Events.LoadScreenContentReady.Call() end
---*Action*
function Events.LoadScreenContentReady.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.LoadScreenContentReady.Add(func) end
---*Action*
---@param func function
function Events.LoadScreenContentReady.Remove(func) end

---@overload fun()
Events.InputActionStarted = {}
---*Query*
---@return number amount
function Events.InputActionStarted.Count() end
---*Action*
function Events.InputActionStarted.RemoveAll() end
---*Action*
function Events.InputActionStarted.Dispatch() end
Events.InputActionStarted = {}
---*Query*
---@return number amount
function Events.InputActionStarted.Count() end
---*Action*
function Events.InputActionStarted.RemoveAll() end
---*Action*
function Events.InputActionStarted.Dispatch() end
---*Action*
function Events.InputActionStarted.Call() end
---*Action*
function Events.InputActionStarted.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.InputActionStarted.Add(func) end
---*Action*
---@param func function
function Events.InputActionStarted.Remove(func) end

---@overload fun()
Events.InputActionFinished = {}
---*Query*
---@return number amount
function Events.InputActionFinished.Count() end
---*Action*
function Events.InputActionFinished.RemoveAll() end
---*Action*
function Events.InputActionFinished.Dispatch() end
Events.InputActionFinished = {}
---*Query*
---@return number amount
function Events.InputActionFinished.Count() end
---*Action*
function Events.InputActionFinished.RemoveAll() end
---*Action*
function Events.InputActionFinished.Dispatch() end
---*Action*
function Events.InputActionFinished.Call() end
---*Action*
function Events.InputActionFinished.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.InputActionFinished.Add(func) end
---*Action*
---@param func function
function Events.InputActionFinished.Remove(func) end

---@overload fun()
Events.WorldCongressFinished = {}
---*Query*
---@return number amount
function Events.WorldCongressFinished.Count() end
---*Action*
function Events.WorldCongressFinished.RemoveAll() end
---*Action*
function Events.WorldCongressFinished.Dispatch() end
Events.WorldCongressFinished = {}
---*Query*
---@return number amount
function Events.WorldCongressFinished.Count() end
---*Action*
function Events.WorldCongressFinished.RemoveAll() end
---*Action*
function Events.WorldCongressFinished.Dispatch() end
---*Action*
function Events.WorldCongressFinished.Call() end
---*Action*
function Events.WorldCongressFinished.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.WorldCongressFinished.Add(func) end
---*Action*
---@param func function
function Events.WorldCongressFinished.Remove(func) end

---@overload fun()
Events.GamePauseStateChanged = {}
---*Query*
---@return number amount
function Events.GamePauseStateChanged.Count() end
---*Action*
function Events.GamePauseStateChanged.RemoveAll() end
---*Action*
function Events.GamePauseStateChanged.Dispatch() end
Events.GamePauseStateChanged = {}
---*Query*
---@return number amount
function Events.GamePauseStateChanged.Count() end
---*Action*
function Events.GamePauseStateChanged.RemoveAll() end
---*Action*
function Events.GamePauseStateChanged.Dispatch() end
---*Action*
function Events.GamePauseStateChanged.Call() end
---*Action*
function Events.GamePauseStateChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.GamePauseStateChanged.Add(func) end
---*Action*
---@param func function
function Events.GamePauseStateChanged.Remove(func) end

---@overload fun()
Events.UnitPlayCinematicAnimation = {}
---*Query*
---@return number amount
function Events.UnitPlayCinematicAnimation.Count() end
---*Action*
function Events.UnitPlayCinematicAnimation.RemoveAll() end
---*Action*
function Events.UnitPlayCinematicAnimation.Dispatch() end
Events.UnitPlayCinematicAnimation = {}
---*Query*
---@return number amount
function Events.UnitPlayCinematicAnimation.Count() end
---*Action*
function Events.UnitPlayCinematicAnimation.RemoveAll() end
---*Action*
function Events.UnitPlayCinematicAnimation.Dispatch() end
---*Action*
function Events.UnitPlayCinematicAnimation.Call() end
---*Action*
function Events.UnitPlayCinematicAnimation.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.UnitPlayCinematicAnimation.Add(func) end
---*Action*
---@param func function
function Events.UnitPlayCinematicAnimation.Remove(func) end

---@overload fun()
Events.DisableColorKey = {}
---*Query*
---@return number amount
function Events.DisableColorKey.Count() end
---*Action*
function Events.DisableColorKey.RemoveAll() end
---*Action*
function Events.DisableColorKey.Dispatch() end
Events.DisableColorKey = {}
---*Query*
---@return number amount
function Events.DisableColorKey.Count() end
---*Action*
function Events.DisableColorKey.RemoveAll() end
---*Action*
function Events.DisableColorKey.Dispatch() end
---*Action*
function Events.DisableColorKey.Call() end
---*Action*
function Events.DisableColorKey.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.DisableColorKey.Add(func) end
---*Action*
---@param func function
function Events.DisableColorKey.Remove(func) end

---@overload fun()
Events.GeothermalFissureRevealed = {}
---*Query*
---@return number amount
function Events.GeothermalFissureRevealed.Count() end
---*Action*
function Events.GeothermalFissureRevealed.RemoveAll() end
---*Action*
function Events.GeothermalFissureRevealed.Dispatch() end
Events.GeothermalFissureRevealed = {}
---*Query*
---@return number amount
function Events.GeothermalFissureRevealed.Count() end
---*Action*
function Events.GeothermalFissureRevealed.RemoveAll() end
---*Action*
function Events.GeothermalFissureRevealed.Dispatch() end
---*Action*
function Events.GeothermalFissureRevealed.Call() end
---*Action*
function Events.GeothermalFissureRevealed.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.GeothermalFissureRevealed.Add(func) end
---*Action*
---@param func function
function Events.GeothermalFissureRevealed.Remove(func) end

---@overload fun()
Events.MultiplayerMatchHostMigrated = {}
---*Query*
---@return number amount
function Events.MultiplayerMatchHostMigrated.Count() end
---*Action*
function Events.MultiplayerMatchHostMigrated.RemoveAll() end
---*Action*
function Events.MultiplayerMatchHostMigrated.Dispatch() end
Events.MultiplayerMatchHostMigrated = {}
---*Query*
---@return number amount
function Events.MultiplayerMatchHostMigrated.Count() end
---*Action*
function Events.MultiplayerMatchHostMigrated.RemoveAll() end
---*Action*
function Events.MultiplayerMatchHostMigrated.Dispatch() end
---*Action*
function Events.MultiplayerMatchHostMigrated.Call() end
---*Action*
function Events.MultiplayerMatchHostMigrated.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.MultiplayerMatchHostMigrated.Add(func) end
---*Action*
---@param func function
function Events.MultiplayerMatchHostMigrated.Remove(func) end

---@overload fun(playerID: number, unitID: number)
Events.UnitPropertyChanged = {}
---*Query*
---@return number amount
function Events.UnitPropertyChanged.Count() end
---*Action*
function Events.UnitPropertyChanged.RemoveAll() end
---*Action*
function Events.UnitPropertyChanged.Dispatch() end
Events.UnitPropertyChanged = {}
---*Query*
---@return number amount
function Events.UnitPropertyChanged.Count() end
---*Action*
function Events.UnitPropertyChanged.RemoveAll() end
---*Action*
function Events.UnitPropertyChanged.Dispatch() end
---*Action*
---@param playerID number
---@param unitID number
function Events.UnitPropertyChanged.Call(playerID, unitID) end
---*Action*
---@param playerID number
---@param unitID number
function Events.UnitPropertyChanged.CallImmediate(playerID, unitID) end
---*Action*
---@param func fun(playerID: number, unitID: number)
---@return fun(playerID: number, unitID: number)
function Events.UnitPropertyChanged.Add(func) end
---*Action*
---@param func function
function Events.UnitPropertyChanged.Remove(func) end

---@overload fun()
Events.CrossPlayServersDisconnected = {}
---*Query*
---@return number amount
function Events.CrossPlayServersDisconnected.Count() end
---*Action*
function Events.CrossPlayServersDisconnected.RemoveAll() end
---*Action*
function Events.CrossPlayServersDisconnected.Dispatch() end
Events.CrossPlayServersDisconnected = {}
---*Query*
---@return number amount
function Events.CrossPlayServersDisconnected.Count() end
---*Action*
function Events.CrossPlayServersDisconnected.RemoveAll() end
---*Action*
function Events.CrossPlayServersDisconnected.Dispatch() end
---*Action*
function Events.CrossPlayServersDisconnected.Call() end
---*Action*
function Events.CrossPlayServersDisconnected.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.CrossPlayServersDisconnected.Add(func) end
---*Action*
---@param func function
function Events.CrossPlayServersDisconnected.Remove(func) end

---@overload fun()
Events.WorldCongressStage2 = {}
---*Query*
---@return number amount
function Events.WorldCongressStage2.Count() end
---*Action*
function Events.WorldCongressStage2.RemoveAll() end
---*Action*
function Events.WorldCongressStage2.Dispatch() end
Events.WorldCongressStage2 = {}
---*Query*
---@return number amount
function Events.WorldCongressStage2.Count() end
---*Action*
function Events.WorldCongressStage2.RemoveAll() end
---*Action*
function Events.WorldCongressStage2.Dispatch() end
---*Action*
function Events.WorldCongressStage2.Call() end
---*Action*
function Events.WorldCongressStage2.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.WorldCongressStage2.Add(func) end
---*Action*
---@param func function
function Events.WorldCongressStage2.Remove(func) end

---@overload fun()
Events.PopupActivated = {}
---*Query*
---@return number amount
function Events.PopupActivated.Count() end
---*Action*
function Events.PopupActivated.RemoveAll() end
---*Action*
function Events.PopupActivated.Dispatch() end
Events.PopupActivated = {}
---*Query*
---@return number amount
function Events.PopupActivated.Count() end
---*Action*
function Events.PopupActivated.RemoveAll() end
---*Action*
function Events.PopupActivated.Dispatch() end
---*Action*
function Events.PopupActivated.Call() end
---*Action*
function Events.PopupActivated.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.PopupActivated.Add(func) end
---*Action*
---@param func function
function Events.PopupActivated.Remove(func) end

---@overload fun()
Events.BenchmarkEnd = {}
---*Query*
---@return number amount
function Events.BenchmarkEnd.Count() end
---*Action*
function Events.BenchmarkEnd.RemoveAll() end
---*Action*
function Events.BenchmarkEnd.Dispatch() end
Events.BenchmarkEnd = {}
---*Query*
---@return number amount
function Events.BenchmarkEnd.Count() end
---*Action*
function Events.BenchmarkEnd.RemoveAll() end
---*Action*
function Events.BenchmarkEnd.Dispatch() end
---*Action*
function Events.BenchmarkEnd.Call() end
---*Action*
function Events.BenchmarkEnd.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.BenchmarkEnd.Add(func) end
---*Action*
---@param func function
function Events.BenchmarkEnd.Remove(func) end

---@overload fun()
Events.WorldCongressSpecialSessionBeingCalled = {}
---*Query*
---@return number amount
function Events.WorldCongressSpecialSessionBeingCalled.Count() end
---*Action*
function Events.WorldCongressSpecialSessionBeingCalled.RemoveAll() end
---*Action*
function Events.WorldCongressSpecialSessionBeingCalled.Dispatch() end
Events.WorldCongressSpecialSessionBeingCalled = {}
---*Query*
---@return number amount
function Events.WorldCongressSpecialSessionBeingCalled.Count() end
---*Action*
function Events.WorldCongressSpecialSessionBeingCalled.RemoveAll() end
---*Action*
function Events.WorldCongressSpecialSessionBeingCalled.Dispatch() end
---*Action*
function Events.WorldCongressSpecialSessionBeingCalled.Call() end
---*Action*
function Events.WorldCongressSpecialSessionBeingCalled.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.WorldCongressSpecialSessionBeingCalled.Add(func) end
---*Action*
---@param func function
function Events.WorldCongressSpecialSessionBeingCalled.Remove(func) end

---@overload fun()
Events.LensChanged = {}
---*Query*
---@return number amount
function Events.LensChanged.Count() end
---*Action*
function Events.LensChanged.RemoveAll() end
---*Action*
function Events.LensChanged.Dispatch() end
Events.LensChanged = {}
---*Query*
---@return number amount
function Events.LensChanged.Count() end
---*Action*
function Events.LensChanged.RemoveAll() end
---*Action*
function Events.LensChanged.Dispatch() end
---*Action*
function Events.LensChanged.Call() end
---*Action*
function Events.LensChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.LensChanged.Add(func) end
---*Action*
---@param func function
function Events.LensChanged.Remove(func) end

---@overload fun()
Events.UserAcceptsOutdatedDriver = {}
---*Query*
---@return number amount
function Events.UserAcceptsOutdatedDriver.Count() end
---*Action*
function Events.UserAcceptsOutdatedDriver.RemoveAll() end
---*Action*
function Events.UserAcceptsOutdatedDriver.Dispatch() end
Events.UserAcceptsOutdatedDriver = {}
---*Query*
---@return number amount
function Events.UserAcceptsOutdatedDriver.Count() end
---*Action*
function Events.UserAcceptsOutdatedDriver.RemoveAll() end
---*Action*
function Events.UserAcceptsOutdatedDriver.Dispatch() end
---*Action*
function Events.UserAcceptsOutdatedDriver.Call() end
---*Action*
function Events.UserAcceptsOutdatedDriver.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.UserAcceptsOutdatedDriver.Add(func) end
---*Action*
---@param func function
function Events.UserAcceptsOutdatedDriver.Remove(func) end

---@overload fun()
Events.OptionChangeRequiresGameRestart = {}
---*Query*
---@return number amount
function Events.OptionChangeRequiresGameRestart.Count() end
---*Action*
function Events.OptionChangeRequiresGameRestart.RemoveAll() end
---*Action*
function Events.OptionChangeRequiresGameRestart.Dispatch() end
Events.OptionChangeRequiresGameRestart = {}
---*Query*
---@return number amount
function Events.OptionChangeRequiresGameRestart.Count() end
---*Action*
function Events.OptionChangeRequiresGameRestart.RemoveAll() end
---*Action*
function Events.OptionChangeRequiresGameRestart.Dispatch() end
---*Action*
function Events.OptionChangeRequiresGameRestart.Call() end
---*Action*
function Events.OptionChangeRequiresGameRestart.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.OptionChangeRequiresGameRestart.Add(func) end
---*Action*
---@param func function
function Events.OptionChangeRequiresGameRestart.Remove(func) end

---@overload fun()
Events.UserAcceptsEULA = {}
---*Query*
---@return number amount
function Events.UserAcceptsEULA.Count() end
---*Action*
function Events.UserAcceptsEULA.RemoveAll() end
---*Action*
function Events.UserAcceptsEULA.Dispatch() end
Events.UserAcceptsEULA = {}
---*Query*
---@return number amount
function Events.UserAcceptsEULA.Count() end
---*Action*
function Events.UserAcceptsEULA.RemoveAll() end
---*Action*
function Events.UserAcceptsEULA.Dispatch() end
---*Action*
function Events.UserAcceptsEULA.Call() end
---*Action*
function Events.UserAcceptsEULA.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.UserAcceptsEULA.Add(func) end
---*Action*
---@param func function
function Events.UserAcceptsEULA.Remove(func) end

---@overload fun()
Events.RandomEventStarted = {}
---*Query*
---@return number amount
function Events.RandomEventStarted.Count() end
---*Action*
function Events.RandomEventStarted.RemoveAll() end
---*Action*
function Events.RandomEventStarted.Dispatch() end
Events.RandomEventStarted = {}
---*Query*
---@return number amount
function Events.RandomEventStarted.Count() end
---*Action*
function Events.RandomEventStarted.RemoveAll() end
---*Action*
function Events.RandomEventStarted.Dispatch() end
---*Action*
function Events.RandomEventStarted.Call() end
---*Action*
function Events.RandomEventStarted.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.RandomEventStarted.Add(func) end
---*Action*
---@param func function
function Events.RandomEventStarted.Remove(func) end

---@overload fun()
Events.UserOptionChanged = {}
---*Query*
---@return number amount
function Events.UserOptionChanged.Count() end
---*Action*
function Events.UserOptionChanged.RemoveAll() end
---*Action*
function Events.UserOptionChanged.Dispatch() end
Events.UserOptionChanged = {}
---*Query*
---@return number amount
function Events.UserOptionChanged.Count() end
---*Action*
function Events.UserOptionChanged.RemoveAll() end
---*Action*
function Events.UserOptionChanged.Dispatch() end
---*Action*
function Events.UserOptionChanged.Call() end
---*Action*
function Events.UserOptionChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.UserOptionChanged.Add(func) end
---*Action*
---@param func function
function Events.UserOptionChanged.Remove(func) end

---@overload fun()
Events.ConnectedToNetSessionHost = {}
---*Query*
---@return number amount
function Events.ConnectedToNetSessionHost.Count() end
---*Action*
function Events.ConnectedToNetSessionHost.RemoveAll() end
---*Action*
function Events.ConnectedToNetSessionHost.Dispatch() end
Events.ConnectedToNetSessionHost = {}
---*Query*
---@return number amount
function Events.ConnectedToNetSessionHost.Count() end
---*Action*
function Events.ConnectedToNetSessionHost.RemoveAll() end
---*Action*
function Events.ConnectedToNetSessionHost.Dispatch() end
---*Action*
function Events.ConnectedToNetSessionHost.Call() end
---*Action*
function Events.ConnectedToNetSessionHost.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.ConnectedToNetSessionHost.Add(func) end
---*Action*
---@param func function
function Events.ConnectedToNetSessionHost.Remove(func) end

---@overload fun()
Events.UserAcceptsUnknownDevice = {}
---*Query*
---@return number amount
function Events.UserAcceptsUnknownDevice.Count() end
---*Action*
function Events.UserAcceptsUnknownDevice.RemoveAll() end
---*Action*
function Events.UserAcceptsUnknownDevice.Dispatch() end
Events.UserAcceptsUnknownDevice = {}
---*Query*
---@return number amount
function Events.UserAcceptsUnknownDevice.Count() end
---*Action*
function Events.UserAcceptsUnknownDevice.RemoveAll() end
---*Action*
function Events.UserAcceptsUnknownDevice.Dispatch() end
---*Action*
function Events.UserAcceptsUnknownDevice.Call() end
---*Action*
function Events.UserAcceptsUnknownDevice.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.UserAcceptsUnknownDevice.Add(func) end
---*Action*
---@param func function
function Events.UserAcceptsUnknownDevice.Remove(func) end

---@overload fun()
Events.CorporationAdded = {}
---*Query*
---@return number amount
function Events.CorporationAdded.Count() end
---*Action*
function Events.CorporationAdded.RemoveAll() end
---*Action*
function Events.CorporationAdded.Dispatch() end
Events.CorporationAdded = {}
---*Query*
---@return number amount
function Events.CorporationAdded.Count() end
---*Action*
function Events.CorporationAdded.RemoveAll() end
---*Action*
function Events.CorporationAdded.Dispatch() end
---*Action*
function Events.CorporationAdded.Call() end
---*Action*
function Events.CorporationAdded.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.CorporationAdded.Add(func) end
---*Action*
---@param func function
function Events.CorporationAdded.Remove(func) end

---@overload fun()
Events.MultiplayerGameListClear = {}
---*Query*
---@return number amount
function Events.MultiplayerGameListClear.Count() end
---*Action*
function Events.MultiplayerGameListClear.RemoveAll() end
---*Action*
function Events.MultiplayerGameListClear.Dispatch() end
Events.MultiplayerGameListClear = {}
---*Query*
---@return number amount
function Events.MultiplayerGameListClear.Count() end
---*Action*
function Events.MultiplayerGameListClear.RemoveAll() end
---*Action*
function Events.MultiplayerGameListClear.Dispatch() end
---*Action*
function Events.MultiplayerGameListClear.Call() end
---*Action*
function Events.MultiplayerGameListClear.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.MultiplayerGameListClear.Add(func) end
---*Action*
---@param func function
function Events.MultiplayerGameListClear.Remove(func) end

---@overload fun()
Events.GamePropertyChanged = {}
---*Query*
---@return number amount
function Events.GamePropertyChanged.Count() end
---*Action*
function Events.GamePropertyChanged.RemoveAll() end
---*Action*
function Events.GamePropertyChanged.Dispatch() end
Events.GamePropertyChanged = {}
---*Query*
---@return number amount
function Events.GamePropertyChanged.Count() end
---*Action*
function Events.GamePropertyChanged.RemoveAll() end
---*Action*
function Events.GamePropertyChanged.Dispatch() end
---*Action*
function Events.GamePropertyChanged.Call() end
---*Action*
function Events.GamePropertyChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.GamePropertyChanged.Add(func) end
---*Action*
---@param func function
function Events.GamePropertyChanged.Remove(func) end

---@overload fun()
Events.MultiplayerHostMigrated = {}
---*Query*
---@return number amount
function Events.MultiplayerHostMigrated.Count() end
---*Action*
function Events.MultiplayerHostMigrated.RemoveAll() end
---*Action*
function Events.MultiplayerHostMigrated.Dispatch() end
Events.MultiplayerHostMigrated = {}
---*Query*
---@return number amount
function Events.MultiplayerHostMigrated.Count() end
---*Action*
function Events.MultiplayerHostMigrated.RemoveAll() end
---*Action*
function Events.MultiplayerHostMigrated.Dispatch() end
---*Action*
function Events.MultiplayerHostMigrated.Call() end
---*Action*
function Events.MultiplayerHostMigrated.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.MultiplayerHostMigrated.Add(func) end
---*Action*
---@param func function
function Events.MultiplayerHostMigrated.Remove(func) end

---@overload fun()
Events.VolcanoRevealed = {}
---*Query*
---@return number amount
function Events.VolcanoRevealed.Count() end
---*Action*
function Events.VolcanoRevealed.RemoveAll() end
---*Action*
function Events.VolcanoRevealed.Dispatch() end
Events.VolcanoRevealed = {}
---*Query*
---@return number amount
function Events.VolcanoRevealed.Count() end
---*Action*
function Events.VolcanoRevealed.RemoveAll() end
---*Action*
function Events.VolcanoRevealed.Dispatch() end
---*Action*
function Events.VolcanoRevealed.Call() end
---*Action*
function Events.VolcanoRevealed.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.VolcanoRevealed.Add(func) end
---*Action*
---@param func function
function Events.VolcanoRevealed.Remove(func) end

---@overload fun()
Events.CloudGameQuit = {}
---*Query*
---@return number amount
function Events.CloudGameQuit.Count() end
---*Action*
function Events.CloudGameQuit.RemoveAll() end
---*Action*
function Events.CloudGameQuit.Dispatch() end
Events.CloudGameQuit = {}
---*Query*
---@return number amount
function Events.CloudGameQuit.Count() end
---*Action*
function Events.CloudGameQuit.RemoveAll() end
---*Action*
function Events.CloudGameQuit.Dispatch() end
---*Action*
function Events.CloudGameQuit.Call() end
---*Action*
function Events.CloudGameQuit.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.CloudGameQuit.Add(func) end
---*Action*
---@param func function
function Events.CloudGameQuit.Remove(func) end

---@overload fun()
Events.CloudUnseenCompleteCheckComplete = {}
---*Query*
---@return number amount
function Events.CloudUnseenCompleteCheckComplete.Count() end
---*Action*
function Events.CloudUnseenCompleteCheckComplete.RemoveAll() end
---*Action*
function Events.CloudUnseenCompleteCheckComplete.Dispatch() end
Events.CloudUnseenCompleteCheckComplete = {}
---*Query*
---@return number amount
function Events.CloudUnseenCompleteCheckComplete.Count() end
---*Action*
function Events.CloudUnseenCompleteCheckComplete.RemoveAll() end
---*Action*
function Events.CloudUnseenCompleteCheckComplete.Dispatch() end
---*Action*
function Events.CloudUnseenCompleteCheckComplete.Call() end
---*Action*
function Events.CloudUnseenCompleteCheckComplete.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.CloudUnseenCompleteCheckComplete.Add(func) end
---*Action*
---@param func function
function Events.CloudUnseenCompleteCheckComplete.Remove(func) end

---@overload fun()
Events.TurnTimerUpdated = {}
---*Query*
---@return number amount
function Events.TurnTimerUpdated.Count() end
---*Action*
function Events.TurnTimerUpdated.RemoveAll() end
---*Action*
function Events.TurnTimerUpdated.Dispatch() end
Events.TurnTimerUpdated = {}
---*Query*
---@return number amount
function Events.TurnTimerUpdated.Count() end
---*Action*
function Events.TurnTimerUpdated.RemoveAll() end
---*Action*
function Events.TurnTimerUpdated.Dispatch() end
---*Action*
function Events.TurnTimerUpdated.Call() end
---*Action*
function Events.TurnTimerUpdated.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.TurnTimerUpdated.Add(func) end
---*Action*
---@param func function
function Events.TurnTimerUpdated.Remove(func) end

---@overload fun()
Events.CityProjectCompletedNarrative = {}
---*Query*
---@return number amount
function Events.CityProjectCompletedNarrative.Count() end
---*Action*
function Events.CityProjectCompletedNarrative.RemoveAll() end
---*Action*
function Events.CityProjectCompletedNarrative.Dispatch() end
Events.CityProjectCompletedNarrative = {}
---*Query*
---@return number amount
function Events.CityProjectCompletedNarrative.Count() end
---*Action*
function Events.CityProjectCompletedNarrative.RemoveAll() end
---*Action*
function Events.CityProjectCompletedNarrative.Dispatch() end
---*Action*
function Events.CityProjectCompletedNarrative.Call() end
---*Action*
function Events.CityProjectCompletedNarrative.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.CityProjectCompletedNarrative.Add(func) end
---*Action*
---@param func function
function Events.CityProjectCompletedNarrative.Remove(func) end

---@overload fun()
Events.WorldCongressRibbonUpdate = {}
---*Query*
---@return number amount
function Events.WorldCongressRibbonUpdate.Count() end
---*Action*
function Events.WorldCongressRibbonUpdate.RemoveAll() end
---*Action*
function Events.WorldCongressRibbonUpdate.Dispatch() end
Events.WorldCongressRibbonUpdate = {}
---*Query*
---@return number amount
function Events.WorldCongressRibbonUpdate.Count() end
---*Action*
function Events.WorldCongressRibbonUpdate.RemoveAll() end
---*Action*
function Events.WorldCongressRibbonUpdate.Dispatch() end
---*Action*
function Events.WorldCongressRibbonUpdate.Call() end
---*Action*
function Events.WorldCongressRibbonUpdate.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.WorldCongressRibbonUpdate.Add(func) end
---*Action*
---@param func function
function Events.WorldCongressRibbonUpdate.Remove(func) end

---@overload fun()
Events.RestartWonderMovie = {}
---*Query*
---@return number amount
function Events.RestartWonderMovie.Count() end
---*Action*
function Events.RestartWonderMovie.RemoveAll() end
---*Action*
function Events.RestartWonderMovie.Dispatch() end
Events.RestartWonderMovie = {}
---*Query*
---@return number amount
function Events.RestartWonderMovie.Count() end
---*Action*
function Events.RestartWonderMovie.RemoveAll() end
---*Action*
function Events.RestartWonderMovie.Dispatch() end
---*Action*
function Events.RestartWonderMovie.Call() end
---*Action*
function Events.RestartWonderMovie.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.RestartWonderMovie.Add(func) end
---*Action*
---@param func function
function Events.RestartWonderMovie.Remove(func) end

---@overload fun()
Events.ExitToMainMenu = {}
---*Query*
---@return number amount
function Events.ExitToMainMenu.Count() end
---*Action*
function Events.ExitToMainMenu.RemoveAll() end
---*Action*
function Events.ExitToMainMenu.Dispatch() end
Events.ExitToMainMenu = {}
---*Query*
---@return number amount
function Events.ExitToMainMenu.Count() end
---*Action*
function Events.ExitToMainMenu.RemoveAll() end
---*Action*
function Events.ExitToMainMenu.Dispatch() end
---*Action*
function Events.ExitToMainMenu.Call() end
---*Action*
function Events.ExitToMainMenu.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.ExitToMainMenu.Add(func) end
---*Action*
---@param func function
function Events.ExitToMainMenu.Remove(func) end

---@overload fun()
Events.SteamFriendsPresenceUpdated = {}
---*Query*
---@return number amount
function Events.SteamFriendsPresenceUpdated.Count() end
---*Action*
function Events.SteamFriendsPresenceUpdated.RemoveAll() end
---*Action*
function Events.SteamFriendsPresenceUpdated.Dispatch() end
Events.SteamFriendsPresenceUpdated = {}
---*Query*
---@return number amount
function Events.SteamFriendsPresenceUpdated.Count() end
---*Action*
function Events.SteamFriendsPresenceUpdated.RemoveAll() end
---*Action*
function Events.SteamFriendsPresenceUpdated.Dispatch() end
---*Action*
function Events.SteamFriendsPresenceUpdated.Call() end
---*Action*
function Events.SteamFriendsPresenceUpdated.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.SteamFriendsPresenceUpdated.Add(func) end
---*Action*
---@param func function
function Events.SteamFriendsPresenceUpdated.Remove(func) end

---@overload fun()
Events.ShowLeaderScreen = {}
---*Query*
---@return number amount
function Events.ShowLeaderScreen.Count() end
---*Action*
function Events.ShowLeaderScreen.RemoveAll() end
---*Action*
function Events.ShowLeaderScreen.Dispatch() end
Events.ShowLeaderScreen = {}
---*Query*
---@return number amount
function Events.ShowLeaderScreen.Count() end
---*Action*
function Events.ShowLeaderScreen.RemoveAll() end
---*Action*
function Events.ShowLeaderScreen.Dispatch() end
---*Action*
function Events.ShowLeaderScreen.Call() end
---*Action*
function Events.ShowLeaderScreen.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.ShowLeaderScreen.Add(func) end
---*Action*
---@param func function
function Events.ShowLeaderScreen.Remove(func) end

---@overload fun()
Events.MultiplayerJoinRoomComplete = {}
---*Query*
---@return number amount
function Events.MultiplayerJoinRoomComplete.Count() end
---*Action*
function Events.MultiplayerJoinRoomComplete.RemoveAll() end
---*Action*
function Events.MultiplayerJoinRoomComplete.Dispatch() end
Events.MultiplayerJoinRoomComplete = {}
---*Query*
---@return number amount
function Events.MultiplayerJoinRoomComplete.Count() end
---*Action*
function Events.MultiplayerJoinRoomComplete.RemoveAll() end
---*Action*
function Events.MultiplayerJoinRoomComplete.Dispatch() end
---*Action*
function Events.MultiplayerJoinRoomComplete.Call() end
---*Action*
function Events.MultiplayerJoinRoomComplete.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.MultiplayerJoinRoomComplete.Add(func) end
---*Action*
---@param func function
function Events.MultiplayerJoinRoomComplete.Remove(func) end

---@overload fun()
Events.MultiplayerPingTimesChanged = {}
---*Query*
---@return number amount
function Events.MultiplayerPingTimesChanged.Count() end
---*Action*
function Events.MultiplayerPingTimesChanged.RemoveAll() end
---*Action*
function Events.MultiplayerPingTimesChanged.Dispatch() end
Events.MultiplayerPingTimesChanged = {}
---*Query*
---@return number amount
function Events.MultiplayerPingTimesChanged.Count() end
---*Action*
function Events.MultiplayerPingTimesChanged.RemoveAll() end
---*Action*
function Events.MultiplayerPingTimesChanged.Dispatch() end
---*Action*
function Events.MultiplayerPingTimesChanged.Call() end
---*Action*
function Events.MultiplayerPingTimesChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.MultiplayerPingTimesChanged.Add(func) end
---*Action*
---@param func function
function Events.MultiplayerPingTimesChanged.Remove(func) end

---@overload fun()
Events.CulturalIdentityPerturnFromModifiersChanged = {}
---*Query*
---@return number amount
function Events.CulturalIdentityPerturnFromModifiersChanged.Count() end
---*Action*
function Events.CulturalIdentityPerturnFromModifiersChanged.RemoveAll() end
---*Action*
function Events.CulturalIdentityPerturnFromModifiersChanged.Dispatch() end
Events.CulturalIdentityPerturnFromModifiersChanged = {}
---*Query*
---@return number amount
function Events.CulturalIdentityPerturnFromModifiersChanged.Count() end
---*Action*
function Events.CulturalIdentityPerturnFromModifiersChanged.RemoveAll() end
---*Action*
function Events.CulturalIdentityPerturnFromModifiersChanged.Dispatch() end
---*Action*
function Events.CulturalIdentityPerturnFromModifiersChanged.Call() end
---*Action*
function Events.CulturalIdentityPerturnFromModifiersChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.CulturalIdentityPerturnFromModifiersChanged.Add(func) end
---*Action*
---@param func function
function Events.CulturalIdentityPerturnFromModifiersChanged.Remove(func) end

---@overload fun()
Events.CameraAnimationNotFound = {}
---*Query*
---@return number amount
function Events.CameraAnimationNotFound.Count() end
---*Action*
function Events.CameraAnimationNotFound.RemoveAll() end
---*Action*
function Events.CameraAnimationNotFound.Dispatch() end
Events.CameraAnimationNotFound = {}
---*Query*
---@return number amount
function Events.CameraAnimationNotFound.Count() end
---*Action*
function Events.CameraAnimationNotFound.RemoveAll() end
---*Action*
function Events.CameraAnimationNotFound.Dispatch() end
---*Action*
function Events.CameraAnimationNotFound.Call() end
---*Action*
function Events.CameraAnimationNotFound.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.CameraAnimationNotFound.Add(func) end
---*Action*
---@param func function
function Events.CameraAnimationNotFound.Remove(func) end

---@overload fun()
Events.WorldCongressEmergencyReady = {}
---*Query*
---@return number amount
function Events.WorldCongressEmergencyReady.Count() end
---*Action*
function Events.WorldCongressEmergencyReady.RemoveAll() end
---*Action*
function Events.WorldCongressEmergencyReady.Dispatch() end
Events.WorldCongressEmergencyReady = {}
---*Query*
---@return number amount
function Events.WorldCongressEmergencyReady.Count() end
---*Action*
function Events.WorldCongressEmergencyReady.RemoveAll() end
---*Action*
function Events.WorldCongressEmergencyReady.Dispatch() end
---*Action*
function Events.WorldCongressEmergencyReady.Call() end
---*Action*
function Events.WorldCongressEmergencyReady.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.WorldCongressEmergencyReady.Add(func) end
---*Action*
---@param func function
function Events.WorldCongressEmergencyReady.Remove(func) end

---@overload fun()
Events.FiraxisLiveActivate = {}
---*Query*
---@return number amount
function Events.FiraxisLiveActivate.Count() end
---*Action*
function Events.FiraxisLiveActivate.RemoveAll() end
---*Action*
function Events.FiraxisLiveActivate.Dispatch() end
Events.FiraxisLiveActivate = {}
---*Query*
---@return number amount
function Events.FiraxisLiveActivate.Count() end
---*Action*
function Events.FiraxisLiveActivate.RemoveAll() end
---*Action*
function Events.FiraxisLiveActivate.Dispatch() end
---*Action*
function Events.FiraxisLiveActivate.Call() end
---*Action*
function Events.FiraxisLiveActivate.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.FiraxisLiveActivate.Add(func) end
---*Action*
---@param func function
function Events.FiraxisLiveActivate.Remove(func) end

---@overload fun()
Events.Begin2KLoginProcess = {}
---*Query*
---@return number amount
function Events.Begin2KLoginProcess.Count() end
---*Action*
function Events.Begin2KLoginProcess.RemoveAll() end
---*Action*
function Events.Begin2KLoginProcess.Dispatch() end
Events.Begin2KLoginProcess = {}
---*Query*
---@return number amount
function Events.Begin2KLoginProcess.Count() end
---*Action*
function Events.Begin2KLoginProcess.RemoveAll() end
---*Action*
function Events.Begin2KLoginProcess.Dispatch() end
---*Action*
function Events.Begin2KLoginProcess.Call() end
---*Action*
function Events.Begin2KLoginProcess.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.Begin2KLoginProcess.Add(func) end
---*Action*
---@param func function
function Events.Begin2KLoginProcess.Remove(func) end

---@overload fun()
Events.ARXTap = {}
---*Query*
---@return number amount
function Events.ARXTap.Count() end
---*Action*
function Events.ARXTap.RemoveAll() end
---*Action*
function Events.ARXTap.Dispatch() end
Events.ARXTap = {}
---*Query*
---@return number amount
function Events.ARXTap.Count() end
---*Action*
function Events.ARXTap.RemoveAll() end
---*Action*
function Events.ARXTap.Dispatch() end
---*Action*
function Events.ARXTap.Call() end
---*Action*
function Events.ARXTap.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.ARXTap.Add(func) end
---*Action*
---@param func function
function Events.ARXTap.Remove(func) end

---@overload fun()
Events.CloudTurnCheckComplete = {}
---*Query*
---@return number amount
function Events.CloudTurnCheckComplete.Count() end
---*Action*
function Events.CloudTurnCheckComplete.RemoveAll() end
---*Action*
function Events.CloudTurnCheckComplete.Dispatch() end
Events.CloudTurnCheckComplete = {}
---*Query*
---@return number amount
function Events.CloudTurnCheckComplete.Count() end
---*Action*
function Events.CloudTurnCheckComplete.RemoveAll() end
---*Action*
function Events.CloudTurnCheckComplete.Dispatch() end
---*Action*
function Events.CloudTurnCheckComplete.Call() end
---*Action*
function Events.CloudTurnCheckComplete.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.CloudTurnCheckComplete.Add(func) end
---*Action*
---@param func function
function Events.CloudTurnCheckComplete.Remove(func) end

---@overload fun()
Events.CrossPlayDisplayMessage = {}
---*Query*
---@return number amount
function Events.CrossPlayDisplayMessage.Count() end
---*Action*
function Events.CrossPlayDisplayMessage.RemoveAll() end
---*Action*
function Events.CrossPlayDisplayMessage.Dispatch() end
Events.CrossPlayDisplayMessage = {}
---*Query*
---@return number amount
function Events.CrossPlayDisplayMessage.Count() end
---*Action*
function Events.CrossPlayDisplayMessage.RemoveAll() end
---*Action*
function Events.CrossPlayDisplayMessage.Dispatch() end
---*Action*
function Events.CrossPlayDisplayMessage.Call() end
---*Action*
function Events.CrossPlayDisplayMessage.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.CrossPlayDisplayMessage.Add(func) end
---*Action*
---@param func function
function Events.CrossPlayDisplayMessage.Remove(func) end

---@overload fun()
Events.LeaderScreenFinishedLoading = {}
---*Query*
---@return number amount
function Events.LeaderScreenFinishedLoading.Count() end
---*Action*
function Events.LeaderScreenFinishedLoading.RemoveAll() end
---*Action*
function Events.LeaderScreenFinishedLoading.Dispatch() end
Events.LeaderScreenFinishedLoading = {}
---*Query*
---@return number amount
function Events.LeaderScreenFinishedLoading.Count() end
---*Action*
function Events.LeaderScreenFinishedLoading.RemoveAll() end
---*Action*
function Events.LeaderScreenFinishedLoading.Dispatch() end
---*Action*
function Events.LeaderScreenFinishedLoading.Call() end
---*Action*
function Events.LeaderScreenFinishedLoading.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.LeaderScreenFinishedLoading.Add(func) end
---*Action*
---@param func function
function Events.LeaderScreenFinishedLoading.Remove(func) end

---@overload fun()
Events.MultiplayerSnapshotRequested = {}
---*Query*
---@return number amount
function Events.MultiplayerSnapshotRequested.Count() end
---*Action*
function Events.MultiplayerSnapshotRequested.RemoveAll() end
---*Action*
function Events.MultiplayerSnapshotRequested.Dispatch() end
Events.MultiplayerSnapshotRequested = {}
---*Query*
---@return number amount
function Events.MultiplayerSnapshotRequested.Count() end
---*Action*
function Events.MultiplayerSnapshotRequested.RemoveAll() end
---*Action*
function Events.MultiplayerSnapshotRequested.Dispatch() end
---*Action*
function Events.MultiplayerSnapshotRequested.Call() end
---*Action*
function Events.MultiplayerSnapshotRequested.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.MultiplayerSnapshotRequested.Add(func) end
---*Action*
---@param func function
function Events.MultiplayerSnapshotRequested.Remove(func) end

---@overload fun()
Events.LensLayerOff = {}
---*Query*
---@return number amount
function Events.LensLayerOff.Count() end
---*Action*
function Events.LensLayerOff.RemoveAll() end
---*Action*
function Events.LensLayerOff.Dispatch() end
Events.LensLayerOff = {}
---*Query*
---@return number amount
function Events.LensLayerOff.Count() end
---*Action*
function Events.LensLayerOff.RemoveAll() end
---*Action*
function Events.LensLayerOff.Dispatch() end
---*Action*
function Events.LensLayerOff.Call() end
---*Action*
function Events.LensLayerOff.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.LensLayerOff.Add(func) end
---*Action*
---@param func function
function Events.LensLayerOff.Remove(func) end

---@overload fun()
Events.MultiplayerGameListComplete = {}
---*Query*
---@return number amount
function Events.MultiplayerGameListComplete.Count() end
---*Action*
function Events.MultiplayerGameListComplete.RemoveAll() end
---*Action*
function Events.MultiplayerGameListComplete.Dispatch() end
Events.MultiplayerGameListComplete = {}
---*Query*
---@return number amount
function Events.MultiplayerGameListComplete.Count() end
---*Action*
function Events.MultiplayerGameListComplete.RemoveAll() end
---*Action*
function Events.MultiplayerGameListComplete.Dispatch() end
---*Action*
function Events.MultiplayerGameListComplete.Call() end
---*Action*
function Events.MultiplayerGameListComplete.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.MultiplayerGameListComplete.Add(func) end
---*Action*
---@param func function
function Events.MultiplayerGameListComplete.Remove(func) end

---@overload fun()
Events.UploadCloudEndTurnComplete = {}
---*Query*
---@return number amount
function Events.UploadCloudEndTurnComplete.Count() end
---*Action*
function Events.UploadCloudEndTurnComplete.RemoveAll() end
---*Action*
function Events.UploadCloudEndTurnComplete.Dispatch() end
Events.UploadCloudEndTurnComplete = {}
---*Query*
---@return number amount
function Events.UploadCloudEndTurnComplete.Count() end
---*Action*
function Events.UploadCloudEndTurnComplete.RemoveAll() end
---*Action*
function Events.UploadCloudEndTurnComplete.Dispatch() end
---*Action*
function Events.UploadCloudEndTurnComplete.Call() end
---*Action*
function Events.UploadCloudEndTurnComplete.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.UploadCloudEndTurnComplete.Add(func) end
---*Action*
---@param func function
function Events.UploadCloudEndTurnComplete.Remove(func) end

---@overload fun()
Events.UserOptionsActivated = {}
---*Query*
---@return number amount
function Events.UserOptionsActivated.Count() end
---*Action*
function Events.UserOptionsActivated.RemoveAll() end
---*Action*
function Events.UserOptionsActivated.Dispatch() end
Events.UserOptionsActivated = {}
---*Query*
---@return number amount
function Events.UserOptionsActivated.Count() end
---*Action*
function Events.UserOptionsActivated.RemoveAll() end
---*Action*
function Events.UserOptionsActivated.Dispatch() end
---*Action*
function Events.UserOptionsActivated.Call() end
---*Action*
function Events.UserOptionsActivated.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.UserOptionsActivated.Add(func) end
---*Action*
---@param func function
function Events.UserOptionsActivated.Remove(func) end

---@overload fun()
Events.Camera_Updated = {}
---*Query*
---@return number amount
function Events.Camera_Updated.Count() end
---*Action*
function Events.Camera_Updated.RemoveAll() end
---*Action*
function Events.Camera_Updated.Dispatch() end
Events.Camera_Updated = {}
---*Query*
---@return number amount
function Events.Camera_Updated.Count() end
---*Action*
function Events.Camera_Updated.RemoveAll() end
---*Action*
function Events.Camera_Updated.Dispatch() end
---*Action*
function Events.Camera_Updated.Call() end
---*Action*
function Events.Camera_Updated.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.Camera_Updated.Add(func) end
---*Action*
---@param func function
function Events.Camera_Updated.Remove(func) end

---@overload fun()
Events.KickVoteComplete = {}
---*Query*
---@return number amount
function Events.KickVoteComplete.Count() end
---*Action*
function Events.KickVoteComplete.RemoveAll() end
---*Action*
function Events.KickVoteComplete.Dispatch() end
Events.KickVoteComplete = {}
---*Query*
---@return number amount
function Events.KickVoteComplete.Count() end
---*Action*
function Events.KickVoteComplete.RemoveAll() end
---*Action*
function Events.KickVoteComplete.Dispatch() end
---*Action*
function Events.KickVoteComplete.Call() end
---*Action*
function Events.KickVoteComplete.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.KickVoteComplete.Add(func) end
---*Action*
---@param func function
function Events.KickVoteComplete.Remove(func) end

---@overload fun()
Events.PlayerIntroduced = {}
---*Query*
---@return number amount
function Events.PlayerIntroduced.Count() end
---*Action*
function Events.PlayerIntroduced.RemoveAll() end
---*Action*
function Events.PlayerIntroduced.Dispatch() end
Events.PlayerIntroduced = {}
---*Query*
---@return number amount
function Events.PlayerIntroduced.Count() end
---*Action*
function Events.PlayerIntroduced.RemoveAll() end
---*Action*
function Events.PlayerIntroduced.Dispatch() end
---*Action*
function Events.PlayerIntroduced.Call() end
---*Action*
function Events.PlayerIntroduced.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.PlayerIntroduced.Add(func) end
---*Action*
---@param func function
function Events.PlayerIntroduced.Remove(func) end

---@overload fun()
Events.LeaveGameComplete = {}
---*Query*
---@return number amount
function Events.LeaveGameComplete.Count() end
---*Action*
function Events.LeaveGameComplete.RemoveAll() end
---*Action*
function Events.LeaveGameComplete.Dispatch() end
Events.LeaveGameComplete = {}
---*Query*
---@return number amount
function Events.LeaveGameComplete.Count() end
---*Action*
function Events.LeaveGameComplete.RemoveAll() end
---*Action*
function Events.LeaveGameComplete.Dispatch() end
---*Action*
function Events.LeaveGameComplete.Call() end
---*Action*
function Events.LeaveGameComplete.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.LeaveGameComplete.Add(func) end
---*Action*
---@param func function
function Events.LeaveGameComplete.Remove(func) end

---@overload fun()
Events.StormChanged = {}
---*Query*
---@return number amount
function Events.StormChanged.Count() end
---*Action*
function Events.StormChanged.RemoveAll() end
---*Action*
function Events.StormChanged.Dispatch() end
Events.StormChanged = {}
---*Query*
---@return number amount
function Events.StormChanged.Count() end
---*Action*
function Events.StormChanged.RemoveAll() end
---*Action*
function Events.StormChanged.Dispatch() end
---*Action*
function Events.StormChanged.Call() end
---*Action*
function Events.StormChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.StormChanged.Add(func) end
---*Action*
---@param func function
function Events.StormChanged.Remove(func) end

---@overload fun()
Events.PostTourismBomb = {}
---*Query*
---@return number amount
function Events.PostTourismBomb.Count() end
---*Action*
function Events.PostTourismBomb.RemoveAll() end
---*Action*
function Events.PostTourismBomb.Dispatch() end
Events.PostTourismBomb = {}
---*Query*
---@return number amount
function Events.PostTourismBomb.Count() end
---*Action*
function Events.PostTourismBomb.RemoveAll() end
---*Action*
function Events.PostTourismBomb.Dispatch() end
---*Action*
function Events.PostTourismBomb.Call() end
---*Action*
function Events.PostTourismBomb.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.PostTourismBomb.Add(func) end
---*Action*
---@param func function
function Events.PostTourismBomb.Remove(func) end

---@overload fun()
Events.CrossPlayLoginStateUpdated = {}
---*Query*
---@return number amount
function Events.CrossPlayLoginStateUpdated.Count() end
---*Action*
function Events.CrossPlayLoginStateUpdated.RemoveAll() end
---*Action*
function Events.CrossPlayLoginStateUpdated.Dispatch() end
Events.CrossPlayLoginStateUpdated = {}
---*Query*
---@return number amount
function Events.CrossPlayLoginStateUpdated.Count() end
---*Action*
function Events.CrossPlayLoginStateUpdated.RemoveAll() end
---*Action*
function Events.CrossPlayLoginStateUpdated.Dispatch() end
---*Action*
function Events.CrossPlayLoginStateUpdated.Call() end
---*Action*
function Events.CrossPlayLoginStateUpdated.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.CrossPlayLoginStateUpdated.Add(func) end
---*Action*
---@param func function
function Events.CrossPlayLoginStateUpdated.Remove(func) end

---@overload fun()
Events.FavorChanged = {}
---*Query*
---@return number amount
function Events.FavorChanged.Count() end
---*Action*
function Events.FavorChanged.RemoveAll() end
---*Action*
function Events.FavorChanged.Dispatch() end
Events.FavorChanged = {}
---*Query*
---@return number amount
function Events.FavorChanged.Count() end
---*Action*
function Events.FavorChanged.RemoveAll() end
---*Action*
function Events.FavorChanged.Dispatch() end
---*Action*
function Events.FavorChanged.Call() end
---*Action*
function Events.FavorChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.FavorChanged.Add(func) end
---*Action*
---@param func function
function Events.FavorChanged.Remove(func) end

---@overload fun()
Events.EOSInviteReceived = {}
---*Query*
---@return number amount
function Events.EOSInviteReceived.Count() end
---*Action*
function Events.EOSInviteReceived.RemoveAll() end
---*Action*
function Events.EOSInviteReceived.Dispatch() end
Events.EOSInviteReceived = {}
---*Query*
---@return number amount
function Events.EOSInviteReceived.Count() end
---*Action*
function Events.EOSInviteReceived.RemoveAll() end
---*Action*
function Events.EOSInviteReceived.Dispatch() end
---*Action*
function Events.EOSInviteReceived.Call() end
---*Action*
function Events.EOSInviteReceived.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.EOSInviteReceived.Add(func) end
---*Action*
---@param func function
function Events.EOSInviteReceived.Remove(func) end

---@overload fun()
Events.MultiplayerPrePlayerDisconnected = {}
---*Query*
---@return number amount
function Events.MultiplayerPrePlayerDisconnected.Count() end
---*Action*
function Events.MultiplayerPrePlayerDisconnected.RemoveAll() end
---*Action*
function Events.MultiplayerPrePlayerDisconnected.Dispatch() end
Events.MultiplayerPrePlayerDisconnected = {}
---*Query*
---@return number amount
function Events.MultiplayerPrePlayerDisconnected.Count() end
---*Action*
function Events.MultiplayerPrePlayerDisconnected.RemoveAll() end
---*Action*
function Events.MultiplayerPrePlayerDisconnected.Dispatch() end
---*Action*
function Events.MultiplayerPrePlayerDisconnected.Call() end
---*Action*
function Events.MultiplayerPrePlayerDisconnected.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.MultiplayerPrePlayerDisconnected.Add(func) end
---*Action*
---@param func function
function Events.MultiplayerPrePlayerDisconnected.Remove(func) end

---@overload fun()
Events.LoadScreenClose = {}
---*Query*
---@return number amount
function Events.LoadScreenClose.Count() end
---*Action*
function Events.LoadScreenClose.RemoveAll() end
---*Action*
function Events.LoadScreenClose.Dispatch() end
Events.LoadScreenClose = {}
---*Query*
---@return number amount
function Events.LoadScreenClose.Count() end
---*Action*
function Events.LoadScreenClose.RemoveAll() end
---*Action*
function Events.LoadScreenClose.Dispatch() end
---*Action*
function Events.LoadScreenClose.Call() end
---*Action*
function Events.LoadScreenClose.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.LoadScreenClose.Add(func) end
---*Action*
---@param func function
function Events.LoadScreenClose.Remove(func) end

---@overload fun()
Events.WorldRenderViewChanged = {}
---*Query*
---@return number amount
function Events.WorldRenderViewChanged.Count() end
---*Action*
function Events.WorldRenderViewChanged.RemoveAll() end
---*Action*
function Events.WorldRenderViewChanged.Dispatch() end
Events.WorldRenderViewChanged = {}
---*Query*
---@return number amount
function Events.WorldRenderViewChanged.Count() end
---*Action*
function Events.WorldRenderViewChanged.RemoveAll() end
---*Action*
function Events.WorldRenderViewChanged.Dispatch() end
---*Action*
function Events.WorldRenderViewChanged.Call() end
---*Action*
function Events.WorldRenderViewChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.WorldRenderViewChanged.Add(func) end
---*Action*
---@param func function
function Events.WorldRenderViewChanged.Remove(func) end

---@overload fun()
Events.PlayerInfoChanged = {}
---*Query*
---@return number amount
function Events.PlayerInfoChanged.Count() end
---*Action*
function Events.PlayerInfoChanged.RemoveAll() end
---*Action*
function Events.PlayerInfoChanged.Dispatch() end
Events.PlayerInfoChanged = {}
---*Query*
---@return number amount
function Events.PlayerInfoChanged.Count() end
---*Action*
function Events.PlayerInfoChanged.RemoveAll() end
---*Action*
function Events.PlayerInfoChanged.Dispatch() end
---*Action*
function Events.PlayerInfoChanged.Call() end
---*Action*
function Events.PlayerInfoChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.PlayerInfoChanged.Add(func) end
---*Action*
---@param func function
function Events.PlayerInfoChanged.Remove(func) end

---@overload fun()
Events.MultiplayerGameLaunched = {}
---*Query*
---@return number amount
function Events.MultiplayerGameLaunched.Count() end
---*Action*
function Events.MultiplayerGameLaunched.RemoveAll() end
---*Action*
function Events.MultiplayerGameLaunched.Dispatch() end
Events.MultiplayerGameLaunched = {}
---*Query*
---@return number amount
function Events.MultiplayerGameLaunched.Count() end
---*Action*
function Events.MultiplayerGameLaunched.RemoveAll() end
---*Action*
function Events.MultiplayerGameLaunched.Dispatch() end
---*Action*
function Events.MultiplayerGameLaunched.Call() end
---*Action*
function Events.MultiplayerGameLaunched.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.MultiplayerGameLaunched.Add(func) end
---*Action*
---@param func function
function Events.MultiplayerGameLaunched.Remove(func) end

---@overload fun()
Events.PowerGeneratedFromResource = {}
---*Query*
---@return number amount
function Events.PowerGeneratedFromResource.Count() end
---*Action*
function Events.PowerGeneratedFromResource.RemoveAll() end
---*Action*
function Events.PowerGeneratedFromResource.Dispatch() end
Events.PowerGeneratedFromResource = {}
---*Query*
---@return number amount
function Events.PowerGeneratedFromResource.Count() end
---*Action*
function Events.PowerGeneratedFromResource.RemoveAll() end
---*Action*
function Events.PowerGeneratedFromResource.Dispatch() end
---*Action*
function Events.PowerGeneratedFromResource.Call() end
---*Action*
function Events.PowerGeneratedFromResource.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.PowerGeneratedFromResource.Add(func) end
---*Action*
---@param func function
function Events.PowerGeneratedFromResource.Remove(func) end

---@overload fun()
Events.OverlaySystemInitialized = {}
---*Query*
---@return number amount
function Events.OverlaySystemInitialized.Count() end
---*Action*
function Events.OverlaySystemInitialized.RemoveAll() end
---*Action*
function Events.OverlaySystemInitialized.Dispatch() end
Events.OverlaySystemInitialized = {}
---*Query*
---@return number amount
function Events.OverlaySystemInitialized.Count() end
---*Action*
function Events.OverlaySystemInitialized.RemoveAll() end
---*Action*
function Events.OverlaySystemInitialized.Dispatch() end
---*Action*
function Events.OverlaySystemInitialized.Call() end
---*Action*
function Events.OverlaySystemInitialized.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.OverlaySystemInitialized.Add(func) end
---*Action*
---@param func function
function Events.OverlaySystemInitialized.Remove(func) end

---@overload fun()
Events.BarbarianClanConversionEnabled = {}
---*Query*
---@return number amount
function Events.BarbarianClanConversionEnabled.Count() end
---*Action*
function Events.BarbarianClanConversionEnabled.RemoveAll() end
---*Action*
function Events.BarbarianClanConversionEnabled.Dispatch() end
Events.BarbarianClanConversionEnabled = {}
---*Query*
---@return number amount
function Events.BarbarianClanConversionEnabled.Count() end
---*Action*
function Events.BarbarianClanConversionEnabled.RemoveAll() end
---*Action*
function Events.BarbarianClanConversionEnabled.Dispatch() end
---*Action*
function Events.BarbarianClanConversionEnabled.Call() end
---*Action*
function Events.BarbarianClanConversionEnabled.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.BarbarianClanConversionEnabled.Add(func) end
---*Action*
---@param func function
function Events.BarbarianClanConversionEnabled.Remove(func) end

---@overload fun()
Events.GameCoreEventPlaybackComplete = {}
---*Query*
---@return number amount
function Events.GameCoreEventPlaybackComplete.Count() end
---*Action*
function Events.GameCoreEventPlaybackComplete.RemoveAll() end
---*Action*
function Events.GameCoreEventPlaybackComplete.Dispatch() end
Events.GameCoreEventPlaybackComplete = {}
---*Query*
---@return number amount
function Events.GameCoreEventPlaybackComplete.Count() end
---*Action*
function Events.GameCoreEventPlaybackComplete.RemoveAll() end
---*Action*
function Events.GameCoreEventPlaybackComplete.Dispatch() end
---*Action*
function Events.GameCoreEventPlaybackComplete.Call() end
---*Action*
function Events.GameCoreEventPlaybackComplete.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.GameCoreEventPlaybackComplete.Add(func) end
---*Action*
---@param func function
function Events.GameCoreEventPlaybackComplete.Remove(func) end

---@overload fun()
Events.FinishedGameplayContentConfigure = {}
---*Query*
---@return number amount
function Events.FinishedGameplayContentConfigure.Count() end
---*Action*
function Events.FinishedGameplayContentConfigure.RemoveAll() end
---*Action*
function Events.FinishedGameplayContentConfigure.Dispatch() end
Events.FinishedGameplayContentConfigure = {}
---*Query*
---@return number amount
function Events.FinishedGameplayContentConfigure.Count() end
---*Action*
function Events.FinishedGameplayContentConfigure.RemoveAll() end
---*Action*
function Events.FinishedGameplayContentConfigure.Dispatch() end
---*Action*
function Events.FinishedGameplayContentConfigure.Call() end
---*Action*
function Events.FinishedGameplayContentConfigure.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.FinishedGameplayContentConfigure.Add(func) end
---*Action*
---@param func function
function Events.FinishedGameplayContentConfigure.Remove(func) end

---@overload fun()
Events.VisualStateRestored = {}
---*Query*
---@return number amount
function Events.VisualStateRestored.Count() end
---*Action*
function Events.VisualStateRestored.RemoveAll() end
---*Action*
function Events.VisualStateRestored.Dispatch() end
Events.VisualStateRestored = {}
---*Query*
---@return number amount
function Events.VisualStateRestored.Count() end
---*Action*
function Events.VisualStateRestored.RemoveAll() end
---*Action*
function Events.VisualStateRestored.Dispatch() end
---*Action*
function Events.VisualStateRestored.Call() end
---*Action*
function Events.VisualStateRestored.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.VisualStateRestored.Add(func) end
---*Action*
---@param func function
function Events.VisualStateRestored.Remove(func) end

---@overload fun()
Events.UIIdle = {}
---*Query*
---@return number amount
function Events.UIIdle.Count() end
---*Action*
function Events.UIIdle.RemoveAll() end
---*Action*
function Events.UIIdle.Dispatch() end
Events.UIIdle = {}
---*Query*
---@return number amount
function Events.UIIdle.Count() end
---*Action*
function Events.UIIdle.RemoveAll() end
---*Action*
function Events.UIIdle.Dispatch() end
---*Action*
function Events.UIIdle.Call() end
---*Action*
function Events.UIIdle.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.UIIdle.Add(func) end
---*Action*
---@param func function
function Events.UIIdle.Remove(func) end

---@overload fun()
Events.CameraAnimationStopped = {}
---*Query*
---@return number amount
function Events.CameraAnimationStopped.Count() end
---*Action*
function Events.CameraAnimationStopped.RemoveAll() end
---*Action*
function Events.CameraAnimationStopped.Dispatch() end
Events.CameraAnimationStopped = {}
---*Query*
---@return number amount
function Events.CameraAnimationStopped.Count() end
---*Action*
function Events.CameraAnimationStopped.RemoveAll() end
---*Action*
function Events.CameraAnimationStopped.Dispatch() end
---*Action*
function Events.CameraAnimationStopped.Call() end
---*Action*
function Events.CameraAnimationStopped.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.CameraAnimationStopped.Add(func) end
---*Action*
---@param func function
function Events.CameraAnimationStopped.Remove(func) end

---@overload fun()
Events.LensLayerOn = {}
---*Query*
---@return number amount
function Events.LensLayerOn.Count() end
---*Action*
function Events.LensLayerOn.RemoveAll() end
---*Action*
function Events.LensLayerOn.Dispatch() end
Events.LensLayerOn = {}
---*Query*
---@return number amount
function Events.LensLayerOn.Count() end
---*Action*
function Events.LensLayerOn.RemoveAll() end
---*Action*
function Events.LensLayerOn.Dispatch() end
---*Action*
function Events.LensLayerOn.Call() end
---*Action*
function Events.LensLayerOn.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.LensLayerOn.Add(func) end
---*Action*
---@param func function
function Events.LensLayerOn.Remove(func) end

---@overload fun()
Events.UnitKilledByFallout = {}
---*Query*
---@return number amount
function Events.UnitKilledByFallout.Count() end
---*Action*
function Events.UnitKilledByFallout.RemoveAll() end
---*Action*
function Events.UnitKilledByFallout.Dispatch() end
Events.UnitKilledByFallout = {}
---*Query*
---@return number amount
function Events.UnitKilledByFallout.Count() end
---*Action*
function Events.UnitKilledByFallout.RemoveAll() end
---*Action*
function Events.UnitKilledByFallout.Dispatch() end
---*Action*
function Events.UnitKilledByFallout.Call() end
---*Action*
function Events.UnitKilledByFallout.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.UnitKilledByFallout.Add(func) end
---*Action*
---@param func function
function Events.UnitKilledByFallout.Remove(func) end

---@overload fun()
Events.ModStatusUpdated = {}
---*Query*
---@return number amount
function Events.ModStatusUpdated.Count() end
---*Action*
function Events.ModStatusUpdated.RemoveAll() end
---*Action*
function Events.ModStatusUpdated.Dispatch() end
Events.ModStatusUpdated = {}
---*Query*
---@return number amount
function Events.ModStatusUpdated.Count() end
---*Action*
function Events.ModStatusUpdated.RemoveAll() end
---*Action*
function Events.ModStatusUpdated.Dispatch() end
---*Action*
function Events.ModStatusUpdated.Call() end
---*Action*
function Events.ModStatusUpdated.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.ModStatusUpdated.Add(func) end
---*Action*
---@param func function
function Events.ModStatusUpdated.Remove(func) end

---@overload fun()
Events.MapMinMajorPlayersChanged = {}
---*Query*
---@return number amount
function Events.MapMinMajorPlayersChanged.Count() end
---*Action*
function Events.MapMinMajorPlayersChanged.RemoveAll() end
---*Action*
function Events.MapMinMajorPlayersChanged.Dispatch() end
Events.MapMinMajorPlayersChanged = {}
---*Query*
---@return number amount
function Events.MapMinMajorPlayersChanged.Count() end
---*Action*
function Events.MapMinMajorPlayersChanged.RemoveAll() end
---*Action*
function Events.MapMinMajorPlayersChanged.Dispatch() end
---*Action*
function Events.MapMinMajorPlayersChanged.Call() end
---*Action*
function Events.MapMinMajorPlayersChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.MapMinMajorPlayersChanged.Add(func) end
---*Action*
---@param func function
function Events.MapMinMajorPlayersChanged.Remove(func) end

---@overload fun()
Events.BenchmarkToggleLookAt = {}
---*Query*
---@return number amount
function Events.BenchmarkToggleLookAt.Count() end
---*Action*
function Events.BenchmarkToggleLookAt.RemoveAll() end
---*Action*
function Events.BenchmarkToggleLookAt.Dispatch() end
Events.BenchmarkToggleLookAt = {}
---*Query*
---@return number amount
function Events.BenchmarkToggleLookAt.Count() end
---*Action*
function Events.BenchmarkToggleLookAt.RemoveAll() end
---*Action*
function Events.BenchmarkToggleLookAt.Dispatch() end
---*Action*
function Events.BenchmarkToggleLookAt.Call() end
---*Action*
function Events.BenchmarkToggleLookAt.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.BenchmarkToggleLookAt.Add(func) end
---*Action*
---@param func function
function Events.BenchmarkToggleLookAt.Remove(func) end

---@overload fun()
Events.UnitStopCinematicAnimation = {}
---*Query*
---@return number amount
function Events.UnitStopCinematicAnimation.Count() end
---*Action*
function Events.UnitStopCinematicAnimation.RemoveAll() end
---*Action*
function Events.UnitStopCinematicAnimation.Dispatch() end
Events.UnitStopCinematicAnimation = {}
---*Query*
---@return number amount
function Events.UnitStopCinematicAnimation.Count() end
---*Action*
function Events.UnitStopCinematicAnimation.RemoveAll() end
---*Action*
function Events.UnitStopCinematicAnimation.Dispatch() end
---*Action*
function Events.UnitStopCinematicAnimation.Call() end
---*Action*
function Events.UnitStopCinematicAnimation.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.UnitStopCinematicAnimation.Add(func) end
---*Action*
---@param func function
function Events.UnitStopCinematicAnimation.Remove(func) end

---@overload fun()
Events.KickVoteStarted = {}
---*Query*
---@return number amount
function Events.KickVoteStarted.Count() end
---*Action*
function Events.KickVoteStarted.RemoveAll() end
---*Action*
function Events.KickVoteStarted.Dispatch() end
Events.KickVoteStarted = {}
---*Query*
---@return number amount
function Events.KickVoteStarted.Count() end
---*Action*
function Events.KickVoteStarted.RemoveAll() end
---*Action*
function Events.KickVoteStarted.Dispatch() end
---*Action*
function Events.KickVoteStarted.Call() end
---*Action*
function Events.KickVoteStarted.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.KickVoteStarted.Add(func) end
---*Action*
---@param func function
function Events.KickVoteStarted.Remove(func) end

---@overload fun()
Events.CycleUnitSelectionRequest = {}
---*Query*
---@return number amount
function Events.CycleUnitSelectionRequest.Count() end
---*Action*
function Events.CycleUnitSelectionRequest.RemoveAll() end
---*Action*
function Events.CycleUnitSelectionRequest.Dispatch() end
Events.CycleUnitSelectionRequest = {}
---*Query*
---@return number amount
function Events.CycleUnitSelectionRequest.Count() end
---*Action*
function Events.CycleUnitSelectionRequest.RemoveAll() end
---*Action*
function Events.CycleUnitSelectionRequest.Dispatch() end
---*Action*
function Events.CycleUnitSelectionRequest.Call() end
---*Action*
function Events.CycleUnitSelectionRequest.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.CycleUnitSelectionRequest.Add(func) end
---*Action*
---@param func function
function Events.CycleUnitSelectionRequest.Remove(func) end

---@overload fun()
Events.FloodplainRevealed = {}
---*Query*
---@return number amount
function Events.FloodplainRevealed.Count() end
---*Action*
function Events.FloodplainRevealed.RemoveAll() end
---*Action*
function Events.FloodplainRevealed.Dispatch() end
Events.FloodplainRevealed = {}
---*Query*
---@return number amount
function Events.FloodplainRevealed.Count() end
---*Action*
function Events.FloodplainRevealed.RemoveAll() end
---*Action*
function Events.FloodplainRevealed.Dispatch() end
---*Action*
function Events.FloodplainRevealed.Call() end
---*Action*
function Events.FloodplainRevealed.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.FloodplainRevealed.Add(func) end
---*Action*
---@param func function
function Events.FloodplainRevealed.Remove(func) end

---@overload fun()
Events.My2KLinkAccountResult = {}
---*Query*
---@return number amount
function Events.My2KLinkAccountResult.Count() end
---*Action*
function Events.My2KLinkAccountResult.RemoveAll() end
---*Action*
function Events.My2KLinkAccountResult.Dispatch() end
Events.My2KLinkAccountResult = {}
---*Query*
---@return number amount
function Events.My2KLinkAccountResult.Count() end
---*Action*
function Events.My2KLinkAccountResult.RemoveAll() end
---*Action*
function Events.My2KLinkAccountResult.Dispatch() end
---*Action*
function Events.My2KLinkAccountResult.Call() end
---*Action*
function Events.My2KLinkAccountResult.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.My2KLinkAccountResult.Add(func) end
---*Action*
---@param func function
function Events.My2KLinkAccountResult.Remove(func) end

---@overload fun()
Events.LoadGameViewStateDone = {}
---*Query*
---@return number amount
function Events.LoadGameViewStateDone.Count() end
---*Action*
function Events.LoadGameViewStateDone.RemoveAll() end
---*Action*
function Events.LoadGameViewStateDone.Dispatch() end
Events.LoadGameViewStateDone = {}
---*Query*
---@return number amount
function Events.LoadGameViewStateDone.Count() end
---*Action*
function Events.LoadGameViewStateDone.RemoveAll() end
---*Action*
function Events.LoadGameViewStateDone.Dispatch() end
---*Action*
function Events.LoadGameViewStateDone.Call() end
---*Action*
function Events.LoadGameViewStateDone.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.LoadGameViewStateDone.Add(func) end
---*Action*
---@param func function
function Events.LoadGameViewStateDone.Remove(func) end

---@overload fun()
Events.MultiplayerGameLastPlayer = {}
---*Query*
---@return number amount
function Events.MultiplayerGameLastPlayer.Count() end
---*Action*
function Events.MultiplayerGameLastPlayer.RemoveAll() end
---*Action*
function Events.MultiplayerGameLastPlayer.Dispatch() end
Events.MultiplayerGameLastPlayer = {}
---*Query*
---@return number amount
function Events.MultiplayerGameLastPlayer.Count() end
---*Action*
function Events.MultiplayerGameLastPlayer.RemoveAll() end
---*Action*
function Events.MultiplayerGameLastPlayer.Dispatch() end
---*Action*
function Events.MultiplayerGameLastPlayer.Call() end
---*Action*
function Events.MultiplayerGameLastPlayer.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.MultiplayerGameLastPlayer.Add(func) end
---*Action*
---@param func function
function Events.MultiplayerGameLastPlayer.Remove(func) end

---@overload fun()
Events.CloudGameKilled = {}
---*Query*
---@return number amount
function Events.CloudGameKilled.Count() end
---*Action*
function Events.CloudGameKilled.RemoveAll() end
---*Action*
function Events.CloudGameKilled.Dispatch() end
Events.CloudGameKilled = {}
---*Query*
---@return number amount
function Events.CloudGameKilled.Count() end
---*Action*
function Events.CloudGameKilled.RemoveAll() end
---*Action*
function Events.CloudGameKilled.Dispatch() end
---*Action*
function Events.CloudGameKilled.Call() end
---*Action*
function Events.CloudGameKilled.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.CloudGameKilled.Add(func) end
---*Action*
---@param func function
function Events.CloudGameKilled.Remove(func) end

---@overload fun()
Events.UnitSimPositionChanged = {}
---*Query*
---@return number amount
function Events.UnitSimPositionChanged.Count() end
---*Action*
function Events.UnitSimPositionChanged.RemoveAll() end
---*Action*
function Events.UnitSimPositionChanged.Dispatch() end
Events.UnitSimPositionChanged = {}
---*Query*
---@return number amount
function Events.UnitSimPositionChanged.Count() end
---*Action*
function Events.UnitSimPositionChanged.RemoveAll() end
---*Action*
function Events.UnitSimPositionChanged.Dispatch() end
---*Action*
function Events.UnitSimPositionChanged.Call() end
---*Action*
function Events.UnitSimPositionChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.UnitSimPositionChanged.Add(func) end
---*Action*
---@param func function
function Events.UnitSimPositionChanged.Remove(func) end

---@overload fun()
Events.GovernorEjected = {}
---*Query*
---@return number amount
function Events.GovernorEjected.Count() end
---*Action*
function Events.GovernorEjected.RemoveAll() end
---*Action*
function Events.GovernorEjected.Dispatch() end
Events.GovernorEjected = {}
---*Query*
---@return number amount
function Events.GovernorEjected.Count() end
---*Action*
function Events.GovernorEjected.RemoveAll() end
---*Action*
function Events.GovernorEjected.Dispatch() end
---*Action*
function Events.GovernorEjected.Call() end
---*Action*
function Events.GovernorEjected.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.GovernorEjected.Add(func) end
---*Action*
---@param func function
function Events.GovernorEjected.Remove(func) end

---@overload fun()
Events.StopAllCameraAnimations = {}
---*Query*
---@return number amount
function Events.StopAllCameraAnimations.Count() end
---*Action*
function Events.StopAllCameraAnimations.RemoveAll() end
---*Action*
function Events.StopAllCameraAnimations.Dispatch() end
Events.StopAllCameraAnimations = {}
---*Query*
---@return number amount
function Events.StopAllCameraAnimations.Count() end
---*Action*
function Events.StopAllCameraAnimations.RemoveAll() end
---*Action*
function Events.StopAllCameraAnimations.Dispatch() end
---*Action*
function Events.StopAllCameraAnimations.Call() end
---*Action*
function Events.StopAllCameraAnimations.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.StopAllCameraAnimations.Add(func) end
---*Action*
---@param func function
function Events.StopAllCameraAnimations.Remove(func) end

---@overload fun()
Events.ARXOrientationChanged = {}
---*Query*
---@return number amount
function Events.ARXOrientationChanged.Count() end
---*Action*
function Events.ARXOrientationChanged.RemoveAll() end
---*Action*
function Events.ARXOrientationChanged.Dispatch() end
Events.ARXOrientationChanged = {}
---*Query*
---@return number amount
function Events.ARXOrientationChanged.Count() end
---*Action*
function Events.ARXOrientationChanged.RemoveAll() end
---*Action*
function Events.ARXOrientationChanged.Dispatch() end
---*Action*
function Events.ARXOrientationChanged.Call() end
---*Action*
function Events.ARXOrientationChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.ARXOrientationChanged.Add(func) end
---*Action*
---@param func function
function Events.ARXOrientationChanged.Remove(func) end

---@overload fun()
Events.LeaderAnimationComplete = {}
---*Query*
---@return number amount
function Events.LeaderAnimationComplete.Count() end
---*Action*
function Events.LeaderAnimationComplete.RemoveAll() end
---*Action*
function Events.LeaderAnimationComplete.Dispatch() end
Events.LeaderAnimationComplete = {}
---*Query*
---@return number amount
function Events.LeaderAnimationComplete.Count() end
---*Action*
function Events.LeaderAnimationComplete.RemoveAll() end
---*Action*
function Events.LeaderAnimationComplete.Dispatch() end
---*Action*
function Events.LeaderAnimationComplete.Call() end
---*Action*
function Events.LeaderAnimationComplete.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.LeaderAnimationComplete.Add(func) end
---*Action*
---@param func function
function Events.LeaderAnimationComplete.Remove(func) end

---@overload fun()
Events.PreTurnBegin = {}
---*Query*
---@return number amount
function Events.PreTurnBegin.Count() end
---*Action*
function Events.PreTurnBegin.RemoveAll() end
---*Action*
function Events.PreTurnBegin.Dispatch() end
Events.PreTurnBegin = {}
---*Query*
---@return number amount
function Events.PreTurnBegin.Count() end
---*Action*
function Events.PreTurnBegin.RemoveAll() end
---*Action*
function Events.PreTurnBegin.Dispatch() end
---*Action*
function Events.PreTurnBegin.Call() end
---*Action*
function Events.PreTurnBegin.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.PreTurnBegin.Add(func) end
---*Action*
---@param func function
function Events.PreTurnBegin.Remove(func) end

---@overload fun()
Events.FrontEndPopup = {}
---*Query*
---@return number amount
function Events.FrontEndPopup.Count() end
---*Action*
function Events.FrontEndPopup.RemoveAll() end
---*Action*
function Events.FrontEndPopup.Dispatch() end
Events.FrontEndPopup = {}
---*Query*
---@return number amount
function Events.FrontEndPopup.Count() end
---*Action*
function Events.FrontEndPopup.RemoveAll() end
---*Action*
function Events.FrontEndPopup.Dispatch() end
---*Action*
function Events.FrontEndPopup.Call() end
---*Action*
function Events.FrontEndPopup.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.FrontEndPopup.Add(func) end
---*Action*
---@param func function
function Events.FrontEndPopup.Remove(func) end

---@overload fun()
Events.MapMaxMajorPlayersChanged = {}
---*Query*
---@return number amount
function Events.MapMaxMajorPlayersChanged.Count() end
---*Action*
function Events.MapMaxMajorPlayersChanged.RemoveAll() end
---*Action*
function Events.MapMaxMajorPlayersChanged.Dispatch() end
Events.MapMaxMajorPlayersChanged = {}
---*Query*
---@return number amount
function Events.MapMaxMajorPlayersChanged.Count() end
---*Action*
function Events.MapMaxMajorPlayersChanged.RemoveAll() end
---*Action*
function Events.MapMaxMajorPlayersChanged.Dispatch() end
---*Action*
function Events.MapMaxMajorPlayersChanged.Call() end
---*Action*
function Events.MapMaxMajorPlayersChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.MapMaxMajorPlayersChanged.Add(func) end
---*Action*
---@param func function
function Events.MapMaxMajorPlayersChanged.Remove(func) end

---@overload fun()
Events.EnableColorKey = {}
---*Query*
---@return number amount
function Events.EnableColorKey.Count() end
---*Action*
function Events.EnableColorKey.RemoveAll() end
---*Action*
function Events.EnableColorKey.Dispatch() end
Events.EnableColorKey = {}
---*Query*
---@return number amount
function Events.EnableColorKey.Count() end
---*Action*
function Events.EnableColorKey.RemoveAll() end
---*Action*
function Events.EnableColorKey.Dispatch() end
---*Action*
function Events.EnableColorKey.Call() end
---*Action*
function Events.EnableColorKey.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.EnableColorKey.Add(func) end
---*Action*
---@param func function
function Events.EnableColorKey.Remove(func) end

---@overload fun()
Events.UploadCloudEndTurnStart = {}
---*Query*
---@return number amount
function Events.UploadCloudEndTurnStart.Count() end
---*Action*
function Events.UploadCloudEndTurnStart.RemoveAll() end
---*Action*
function Events.UploadCloudEndTurnStart.Dispatch() end
Events.UploadCloudEndTurnStart = {}
---*Query*
---@return number amount
function Events.UploadCloudEndTurnStart.Count() end
---*Action*
function Events.UploadCloudEndTurnStart.RemoveAll() end
---*Action*
function Events.UploadCloudEndTurnStart.Dispatch() end
---*Action*
function Events.UploadCloudEndTurnStart.Call() end
---*Action*
function Events.UploadCloudEndTurnStart.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.UploadCloudEndTurnStart.Add(func) end
---*Action*
---@param func function
function Events.UploadCloudEndTurnStart.Remove(func) end

---@overload fun()
Events.MultiplayerGameListUpdated = {}
---*Query*
---@return number amount
function Events.MultiplayerGameListUpdated.Count() end
---*Action*
function Events.MultiplayerGameListUpdated.RemoveAll() end
---*Action*
function Events.MultiplayerGameListUpdated.Dispatch() end
Events.MultiplayerGameListUpdated = {}
---*Query*
---@return number amount
function Events.MultiplayerGameListUpdated.Count() end
---*Action*
function Events.MultiplayerGameListUpdated.RemoveAll() end
---*Action*
function Events.MultiplayerGameListUpdated.Dispatch() end
---*Action*
function Events.MultiplayerGameListUpdated.Call() end
---*Action*
function Events.MultiplayerGameListUpdated.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.MultiplayerGameListUpdated.Add(func) end
---*Action*
---@param func function
function Events.MultiplayerGameListUpdated.Remove(func) end

---@overload fun()
Events.BeforeMultiplayerInviteProcessing = {}
---*Query*
---@return number amount
function Events.BeforeMultiplayerInviteProcessing.Count() end
---*Action*
function Events.BeforeMultiplayerInviteProcessing.RemoveAll() end
---*Action*
function Events.BeforeMultiplayerInviteProcessing.Dispatch() end
Events.BeforeMultiplayerInviteProcessing = {}
---*Query*
---@return number amount
function Events.BeforeMultiplayerInviteProcessing.Count() end
---*Action*
function Events.BeforeMultiplayerInviteProcessing.RemoveAll() end
---*Action*
function Events.BeforeMultiplayerInviteProcessing.Dispatch() end
---*Action*
function Events.BeforeMultiplayerInviteProcessing.Call() end
---*Action*
function Events.BeforeMultiplayerInviteProcessing.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.BeforeMultiplayerInviteProcessing.Add(func) end
---*Action*
---@param func function
function Events.BeforeMultiplayerInviteProcessing.Remove(func) end

---@overload fun()
Events.RandomEventOccurred = {}
---*Query*
---@return number amount
function Events.RandomEventOccurred.Count() end
---*Action*
function Events.RandomEventOccurred.RemoveAll() end
---*Action*
function Events.RandomEventOccurred.Dispatch() end
Events.RandomEventOccurred = {}
---*Query*
---@return number amount
function Events.RandomEventOccurred.Count() end
---*Action*
function Events.RandomEventOccurred.RemoveAll() end
---*Action*
function Events.RandomEventOccurred.Dispatch() end
---*Action*
function Events.RandomEventOccurred.Call() end
---*Action*
function Events.RandomEventOccurred.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.RandomEventOccurred.Add(func) end
---*Action*
---@param func function
function Events.RandomEventOccurred.Remove(func) end

---@overload fun()
Events.SaveComplete = {}
---*Query*
---@return number amount
function Events.SaveComplete.Count() end
---*Action*
function Events.SaveComplete.RemoveAll() end
---*Action*
function Events.SaveComplete.Dispatch() end
Events.SaveComplete = {}
---*Query*
---@return number amount
function Events.SaveComplete.Count() end
---*Action*
function Events.SaveComplete.RemoveAll() end
---*Action*
function Events.SaveComplete.Dispatch() end
---*Action*
function Events.SaveComplete.Call() end
---*Action*
function Events.SaveComplete.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.SaveComplete.Add(func) end
---*Action*
---@param func function
function Events.SaveComplete.Remove(func) end

---@overload fun()
Events.MultiplayerJoinGameComplete = {}
---*Query*
---@return number amount
function Events.MultiplayerJoinGameComplete.Count() end
---*Action*
function Events.MultiplayerJoinGameComplete.RemoveAll() end
---*Action*
function Events.MultiplayerJoinGameComplete.Dispatch() end
Events.MultiplayerJoinGameComplete = {}
---*Query*
---@return number amount
function Events.MultiplayerJoinGameComplete.Count() end
---*Action*
function Events.MultiplayerJoinGameComplete.RemoveAll() end
---*Action*
function Events.MultiplayerJoinGameComplete.Dispatch() end
---*Action*
function Events.MultiplayerJoinGameComplete.Call() end
---*Action*
function Events.MultiplayerJoinGameComplete.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.MultiplayerJoinGameComplete.Add(func) end
---*Action*
---@param func function
function Events.MultiplayerJoinGameComplete.Remove(func) end

---@overload fun()
Events.UpdateGraphicsOptions = {}
---*Query*
---@return number amount
function Events.UpdateGraphicsOptions.Count() end
---*Action*
function Events.UpdateGraphicsOptions.RemoveAll() end
---*Action*
function Events.UpdateGraphicsOptions.Dispatch() end
Events.UpdateGraphicsOptions = {}
---*Query*
---@return number amount
function Events.UpdateGraphicsOptions.Count() end
---*Action*
function Events.UpdateGraphicsOptions.RemoveAll() end
---*Action*
function Events.UpdateGraphicsOptions.Dispatch() end
---*Action*
function Events.UpdateGraphicsOptions.Call() end
---*Action*
function Events.UpdateGraphicsOptions.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.UpdateGraphicsOptions.Add(func) end
---*Action*
---@param func function
function Events.UpdateGraphicsOptions.Remove(func) end

---@overload fun()
Events.CityPowerChanged = {}
---*Query*
---@return number amount
function Events.CityPowerChanged.Count() end
---*Action*
function Events.CityPowerChanged.RemoveAll() end
---*Action*
function Events.CityPowerChanged.Dispatch() end
Events.CityPowerChanged = {}
---*Query*
---@return number amount
function Events.CityPowerChanged.Count() end
---*Action*
function Events.CityPowerChanged.RemoveAll() end
---*Action*
function Events.CityPowerChanged.Dispatch() end
---*Action*
function Events.CityPowerChanged.Call() end
---*Action*
function Events.CityPowerChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.CityPowerChanged.Add(func) end
---*Action*
---@param func function
function Events.CityPowerChanged.Remove(func) end

---@overload fun()
Events.MultiplayerPostPlayerDisconnected = {}
---*Query*
---@return number amount
function Events.MultiplayerPostPlayerDisconnected.Count() end
---*Action*
function Events.MultiplayerPostPlayerDisconnected.RemoveAll() end
---*Action*
function Events.MultiplayerPostPlayerDisconnected.Dispatch() end
Events.MultiplayerPostPlayerDisconnected = {}
---*Query*
---@return number amount
function Events.MultiplayerPostPlayerDisconnected.Count() end
---*Action*
function Events.MultiplayerPostPlayerDisconnected.RemoveAll() end
---*Action*
function Events.MultiplayerPostPlayerDisconnected.Dispatch() end
---*Action*
function Events.MultiplayerPostPlayerDisconnected.Call() end
---*Action*
function Events.MultiplayerPostPlayerDisconnected.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.MultiplayerPostPlayerDisconnected.Add(func) end
---*Action*
---@param func function
function Events.MultiplayerPostPlayerDisconnected.Remove(func) end

---@overload fun()
Events.HideLeaderScreen = {}
---*Query*
---@return number amount
function Events.HideLeaderScreen.Count() end
---*Action*
function Events.HideLeaderScreen.RemoveAll() end
---*Action*
function Events.HideLeaderScreen.Dispatch() end
Events.HideLeaderScreen = {}
---*Query*
---@return number amount
function Events.HideLeaderScreen.Count() end
---*Action*
function Events.HideLeaderScreen.RemoveAll() end
---*Action*
function Events.HideLeaderScreen.Dispatch() end
---*Action*
function Events.HideLeaderScreen.Call() end
---*Action*
function Events.HideLeaderScreen.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.HideLeaderScreen.Add(func) end
---*Action*
---@param func function
function Events.HideLeaderScreen.Remove(func) end

---@overload fun()
Events.MultiplayerMatchmakingFailed = {}
---*Query*
---@return number amount
function Events.MultiplayerMatchmakingFailed.Count() end
---*Action*
function Events.MultiplayerMatchmakingFailed.RemoveAll() end
---*Action*
function Events.MultiplayerMatchmakingFailed.Dispatch() end
Events.MultiplayerMatchmakingFailed = {}
---*Query*
---@return number amount
function Events.MultiplayerMatchmakingFailed.Count() end
---*Action*
function Events.MultiplayerMatchmakingFailed.RemoveAll() end
---*Action*
function Events.MultiplayerMatchmakingFailed.Dispatch() end
---*Action*
function Events.MultiplayerMatchmakingFailed.Call() end
---*Action*
function Events.MultiplayerMatchmakingFailed.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.MultiplayerMatchmakingFailed.Add(func) end
---*Action*
---@param func function
function Events.MultiplayerMatchmakingFailed.Remove(func) end

---@overload fun()
Events.MultiplayerJoinRoomFailed = {}
---*Query*
---@return number amount
function Events.MultiplayerJoinRoomFailed.Count() end
---*Action*
function Events.MultiplayerJoinRoomFailed.RemoveAll() end
---*Action*
function Events.MultiplayerJoinRoomFailed.Dispatch() end
Events.MultiplayerJoinRoomFailed = {}
---*Query*
---@return number amount
function Events.MultiplayerJoinRoomFailed.Count() end
---*Action*
function Events.MultiplayerJoinRoomFailed.RemoveAll() end
---*Action*
function Events.MultiplayerJoinRoomFailed.Dispatch() end
---*Action*
function Events.MultiplayerJoinRoomFailed.Call() end
---*Action*
function Events.MultiplayerJoinRoomFailed.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.MultiplayerJoinRoomFailed.Add(func) end
---*Action*
---@param func function
function Events.MultiplayerJoinRoomFailed.Remove(func) end

---@overload fun()
Events.MultiplayerSnapshotProcessed = {}
---*Query*
---@return number amount
function Events.MultiplayerSnapshotProcessed.Count() end
---*Action*
function Events.MultiplayerSnapshotProcessed.RemoveAll() end
---*Action*
function Events.MultiplayerSnapshotProcessed.Dispatch() end
Events.MultiplayerSnapshotProcessed = {}
---*Query*
---@return number amount
function Events.MultiplayerSnapshotProcessed.Count() end
---*Action*
function Events.MultiplayerSnapshotProcessed.RemoveAll() end
---*Action*
function Events.MultiplayerSnapshotProcessed.Dispatch() end
---*Action*
function Events.MultiplayerSnapshotProcessed.Call() end
---*Action*
function Events.MultiplayerSnapshotProcessed.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.MultiplayerSnapshotProcessed.Add(func) end
---*Action*
---@param func function
function Events.MultiplayerSnapshotProcessed.Remove(func) end

---@overload fun()
Events.MultiplayerJoinRoomAttempt = {}
---*Query*
---@return number amount
function Events.MultiplayerJoinRoomAttempt.Count() end
---*Action*
function Events.MultiplayerJoinRoomAttempt.RemoveAll() end
---*Action*
function Events.MultiplayerJoinRoomAttempt.Dispatch() end
Events.MultiplayerJoinRoomAttempt = {}
---*Query*
---@return number amount
function Events.MultiplayerJoinRoomAttempt.Count() end
---*Action*
function Events.MultiplayerJoinRoomAttempt.RemoveAll() end
---*Action*
function Events.MultiplayerJoinRoomAttempt.Dispatch() end
---*Action*
function Events.MultiplayerJoinRoomAttempt.Call() end
---*Action*
function Events.MultiplayerJoinRoomAttempt.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.MultiplayerJoinRoomAttempt.Add(func) end
---*Action*
---@param func function
function Events.MultiplayerJoinRoomAttempt.Remove(func) end

---@overload fun()
Events.SteamServersConnected = {}
---*Query*
---@return number amount
function Events.SteamServersConnected.Count() end
---*Action*
function Events.SteamServersConnected.RemoveAll() end
---*Action*
function Events.SteamServersConnected.Dispatch() end
Events.SteamServersConnected = {}
---*Query*
---@return number amount
function Events.SteamServersConnected.Count() end
---*Action*
function Events.SteamServersConnected.RemoveAll() end
---*Action*
function Events.SteamServersConnected.Dispatch() end
---*Action*
function Events.SteamServersConnected.Call() end
---*Action*
function Events.SteamServersConnected.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.SteamServersConnected.Add(func) end
---*Action*
---@param func function
function Events.SteamServersConnected.Remove(func) end

---@overload fun()
Events.CombatVisEnd = {}
---*Query*
---@return number amount
function Events.CombatVisEnd.Count() end
---*Action*
function Events.CombatVisEnd.RemoveAll() end
---*Action*
function Events.CombatVisEnd.Dispatch() end
Events.CombatVisEnd = {}
---*Query*
---@return number amount
function Events.CombatVisEnd.Count() end
---*Action*
function Events.CombatVisEnd.RemoveAll() end
---*Action*
function Events.CombatVisEnd.Dispatch() end
---*Action*
function Events.CombatVisEnd.Call() end
---*Action*
function Events.CombatVisEnd.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.CombatVisEnd.Add(func) end
---*Action*
---@param func function
function Events.CombatVisEnd.Remove(func) end

---@overload fun()
Events.InputGestureRecorded = {}
---*Query*
---@return number amount
function Events.InputGestureRecorded.Count() end
---*Action*
function Events.InputGestureRecorded.RemoveAll() end
---*Action*
function Events.InputGestureRecorded.Dispatch() end
Events.InputGestureRecorded = {}
---*Query*
---@return number amount
function Events.InputGestureRecorded.Count() end
---*Action*
function Events.InputGestureRecorded.RemoveAll() end
---*Action*
function Events.InputGestureRecorded.Dispatch() end
---*Action*
function Events.InputGestureRecorded.Call() end
---*Action*
function Events.InputGestureRecorded.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.InputGestureRecorded.Add(func) end
---*Action*
---@param func function
function Events.InputGestureRecorded.Remove(func) end

---@overload fun()
Events.MarketingPushDataUpdated = {}
---*Query*
---@return number amount
function Events.MarketingPushDataUpdated.Count() end
---*Action*
function Events.MarketingPushDataUpdated.RemoveAll() end
---*Action*
function Events.MarketingPushDataUpdated.Dispatch() end
Events.MarketingPushDataUpdated = {}
---*Query*
---@return number amount
function Events.MarketingPushDataUpdated.Count() end
---*Action*
function Events.MarketingPushDataUpdated.RemoveAll() end
---*Action*
function Events.MarketingPushDataUpdated.Dispatch() end
---*Action*
function Events.MarketingPushDataUpdated.Call() end
---*Action*
function Events.MarketingPushDataUpdated.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.MarketingPushDataUpdated.Add(func) end
---*Action*
---@param func function
function Events.MarketingPushDataUpdated.Remove(func) end

---@overload fun()
Events.CorporationNameChanged = {}
---*Query*
---@return number amount
function Events.CorporationNameChanged.Count() end
---*Action*
function Events.CorporationNameChanged.RemoveAll() end
---*Action*
function Events.CorporationNameChanged.Dispatch() end
Events.CorporationNameChanged = {}
---*Query*
---@return number amount
function Events.CorporationNameChanged.Count() end
---*Action*
function Events.CorporationNameChanged.RemoveAll() end
---*Action*
function Events.CorporationNameChanged.Dispatch() end
---*Action*
function Events.CorporationNameChanged.Call() end
---*Action*
function Events.CorporationNameChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.CorporationNameChanged.Add(func) end
---*Action*
---@param func function
function Events.CorporationNameChanged.Remove(func) end

---@overload fun()
Events.CityPropertyChanged = {}
---*Query*
---@return number amount
function Events.CityPropertyChanged.Count() end
---*Action*
function Events.CityPropertyChanged.RemoveAll() end
---*Action*
function Events.CityPropertyChanged.Dispatch() end
Events.CityPropertyChanged = {}
---*Query*
---@return number amount
function Events.CityPropertyChanged.Count() end
---*Action*
function Events.CityPropertyChanged.RemoveAll() end
---*Action*
function Events.CityPropertyChanged.Dispatch() end
---*Action*
function Events.CityPropertyChanged.Call() end
---*Action*
function Events.CityPropertyChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.CityPropertyChanged.Add(func) end
---*Action*
---@param func function
function Events.CityPropertyChanged.Remove(func) end

---@overload fun()
Events.WorldCongressStage1 = {}
---*Query*
---@return number amount
function Events.WorldCongressStage1.Count() end
---*Action*
function Events.WorldCongressStage1.RemoveAll() end
---*Action*
function Events.WorldCongressStage1.Dispatch() end
Events.WorldCongressStage1 = {}
---*Query*
---@return number amount
function Events.WorldCongressStage1.Count() end
---*Action*
function Events.WorldCongressStage1.RemoveAll() end
---*Action*
function Events.WorldCongressStage1.Dispatch() end
---*Action*
function Events.WorldCongressStage1.Call() end
---*Action*
function Events.WorldCongressStage1.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.WorldCongressStage1.Add(func) end
---*Action*
---@param func function
function Events.WorldCongressStage1.Remove(func) end

---@overload fun()
Events.MatchEndTurnComplete = {}
---*Query*
---@return number amount
function Events.MatchEndTurnComplete.Count() end
---*Action*
function Events.MatchEndTurnComplete.RemoveAll() end
---*Action*
function Events.MatchEndTurnComplete.Dispatch() end
Events.MatchEndTurnComplete = {}
---*Query*
---@return number amount
function Events.MatchEndTurnComplete.Count() end
---*Action*
function Events.MatchEndTurnComplete.RemoveAll() end
---*Action*
function Events.MatchEndTurnComplete.Dispatch() end
---*Action*
function Events.MatchEndTurnComplete.Call() end
---*Action*
function Events.MatchEndTurnComplete.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.MatchEndTurnComplete.Add(func) end
---*Action*
---@param func function
function Events.MatchEndTurnComplete.Remove(func) end

---@overload fun()
Events.GameViewStateDone = {}
---*Query*
---@return number amount
function Events.GameViewStateDone.Count() end
---*Action*
function Events.GameViewStateDone.RemoveAll() end
---*Action*
function Events.GameViewStateDone.Dispatch() end
Events.GameViewStateDone = {}
---*Query*
---@return number amount
function Events.GameViewStateDone.Count() end
---*Action*
function Events.GameViewStateDone.RemoveAll() end
---*Action*
function Events.GameViewStateDone.Dispatch() end
---*Action*
function Events.GameViewStateDone.Call() end
---*Action*
function Events.GameViewStateDone.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.GameViewStateDone.Add(func) end
---*Action*
---@param func function
function Events.GameViewStateDone.Remove(func) end

---@overload fun()
Events.CorporationRemoved = {}
---*Query*
---@return number amount
function Events.CorporationRemoved.Count() end
---*Action*
function Events.CorporationRemoved.RemoveAll() end
---*Action*
function Events.CorporationRemoved.Dispatch() end
Events.CorporationRemoved = {}
---*Query*
---@return number amount
function Events.CorporationRemoved.Count() end
---*Action*
function Events.CorporationRemoved.RemoveAll() end
---*Action*
function Events.CorporationRemoved.Dispatch() end
---*Action*
function Events.CorporationRemoved.Call() end
---*Action*
function Events.CorporationRemoved.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.CorporationRemoved.Add(func) end
---*Action*
---@param func function
function Events.CorporationRemoved.Remove(func) end

---@overload fun()
Events.OptionsReverted = {}
---*Query*
---@return number amount
function Events.OptionsReverted.Count() end
---*Action*
function Events.OptionsReverted.RemoveAll() end
---*Action*
function Events.OptionsReverted.Dispatch() end
Events.OptionsReverted = {}
---*Query*
---@return number amount
function Events.OptionsReverted.Count() end
---*Action*
function Events.OptionsReverted.RemoveAll() end
---*Action*
function Events.OptionsReverted.Dispatch() end
---*Action*
function Events.OptionsReverted.Call() end
---*Action*
function Events.OptionsReverted.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.OptionsReverted.Add(func) end
---*Action*
---@param func function
function Events.OptionsReverted.Remove(func) end

---@overload fun()
Events.LoadCanceled = {}
---*Query*
---@return number amount
function Events.LoadCanceled.Count() end
---*Action*
function Events.LoadCanceled.RemoveAll() end
---*Action*
function Events.LoadCanceled.Dispatch() end
Events.LoadCanceled = {}
---*Query*
---@return number amount
function Events.LoadCanceled.Count() end
---*Action*
function Events.LoadCanceled.RemoveAll() end
---*Action*
function Events.LoadCanceled.Dispatch() end
---*Action*
function Events.LoadCanceled.Call() end
---*Action*
function Events.LoadCanceled.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.LoadCanceled.Add(func) end
---*Action*
---@param func function
function Events.LoadCanceled.Remove(func) end

---@overload fun()
Events.SaveCanceled = {}
---*Query*
---@return number amount
function Events.SaveCanceled.Count() end
---*Action*
function Events.SaveCanceled.RemoveAll() end
---*Action*
function Events.SaveCanceled.Dispatch() end
Events.SaveCanceled = {}
---*Query*
---@return number amount
function Events.SaveCanceled.Count() end
---*Action*
function Events.SaveCanceled.RemoveAll() end
---*Action*
function Events.SaveCanceled.Dispatch() end
---*Action*
function Events.SaveCanceled.Call() end
---*Action*
function Events.SaveCanceled.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.SaveCanceled.Add(func) end
---*Action*
---@param func function
function Events.SaveCanceled.Remove(func) end

---@overload fun()
Events.MonopolyGained = {}
---*Query*
---@return number amount
function Events.MonopolyGained.Count() end
---*Action*
function Events.MonopolyGained.RemoveAll() end
---*Action*
function Events.MonopolyGained.Dispatch() end
Events.MonopolyGained = {}
---*Query*
---@return number amount
function Events.MonopolyGained.Count() end
---*Action*
function Events.MonopolyGained.RemoveAll() end
---*Action*
function Events.MonopolyGained.Dispatch() end
---*Action*
function Events.MonopolyGained.Call() end
---*Action*
function Events.MonopolyGained.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.MonopolyGained.Add(func) end
---*Action*
---@param func function
function Events.MonopolyGained.Remove(func) end

---@overload fun()
Events.AchievementProgress = {}
---*Query*
---@return number amount
function Events.AchievementProgress.Count() end
---*Action*
function Events.AchievementProgress.RemoveAll() end
---*Action*
function Events.AchievementProgress.Dispatch() end
Events.AchievementProgress = {}
---*Query*
---@return number amount
function Events.AchievementProgress.Count() end
---*Action*
function Events.AchievementProgress.RemoveAll() end
---*Action*
function Events.AchievementProgress.Dispatch() end
---*Action*
function Events.AchievementProgress.Call() end
---*Action*
function Events.AchievementProgress.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.AchievementProgress.Add(func) end
---*Action*
---@param func function
function Events.AchievementProgress.Remove(func) end

---@overload fun()
Events.DroughtAddedToMap = {}
---*Query*
---@return number amount
function Events.DroughtAddedToMap.Count() end
---*Action*
function Events.DroughtAddedToMap.RemoveAll() end
---*Action*
function Events.DroughtAddedToMap.Dispatch() end
Events.DroughtAddedToMap = {}
---*Query*
---@return number amount
function Events.DroughtAddedToMap.Count() end
---*Action*
function Events.DroughtAddedToMap.RemoveAll() end
---*Action*
function Events.DroughtAddedToMap.Dispatch() end
---*Action*
function Events.DroughtAddedToMap.Call() end
---*Action*
function Events.DroughtAddedToMap.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.DroughtAddedToMap.Add(func) end
---*Action*
---@param func function
function Events.DroughtAddedToMap.Remove(func) end

---@overload fun()
Events.HostPlayTogetherGame = {}
---*Query*
---@return number amount
function Events.HostPlayTogetherGame.Count() end
---*Action*
function Events.HostPlayTogetherGame.RemoveAll() end
---*Action*
function Events.HostPlayTogetherGame.Dispatch() end
Events.HostPlayTogetherGame = {}
---*Query*
---@return number amount
function Events.HostPlayTogetherGame.Count() end
---*Action*
function Events.HostPlayTogetherGame.RemoveAll() end
---*Action*
function Events.HostPlayTogetherGame.Dispatch() end
---*Action*
function Events.HostPlayTogetherGame.Call() end
---*Action*
function Events.HostPlayTogetherGame.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.HostPlayTogetherGame.Add(func) end
---*Action*
---@param func function
function Events.HostPlayTogetherGame.Remove(func) end

---@overload fun()
Events.GameConfigurationRebuilt = {}
---*Query*
---@return number amount
function Events.GameConfigurationRebuilt.Count() end
---*Action*
function Events.GameConfigurationRebuilt.RemoveAll() end
---*Action*
function Events.GameConfigurationRebuilt.Dispatch() end
Events.GameConfigurationRebuilt = {}
---*Query*
---@return number amount
function Events.GameConfigurationRebuilt.Count() end
---*Action*
function Events.GameConfigurationRebuilt.RemoveAll() end
---*Action*
function Events.GameConfigurationRebuilt.Dispatch() end
---*Action*
function Events.GameConfigurationRebuilt.Call() end
---*Action*
function Events.GameConfigurationRebuilt.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.GameConfigurationRebuilt.Add(func) end
---*Action*
---@param func function
function Events.GameConfigurationRebuilt.Remove(func) end

---@overload fun()
Events.RaiseHostDefaultGame = {}
---*Query*
---@return number amount
function Events.RaiseHostDefaultGame.Count() end
---*Action*
function Events.RaiseHostDefaultGame.RemoveAll() end
---*Action*
function Events.RaiseHostDefaultGame.Dispatch() end
Events.RaiseHostDefaultGame = {}
---*Query*
---@return number amount
function Events.RaiseHostDefaultGame.Count() end
---*Action*
function Events.RaiseHostDefaultGame.RemoveAll() end
---*Action*
function Events.RaiseHostDefaultGame.Dispatch() end
---*Action*
function Events.RaiseHostDefaultGame.Call() end
---*Action*
function Events.RaiseHostDefaultGame.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.RaiseHostDefaultGame.Add(func) end
---*Action*
---@param func function
function Events.RaiseHostDefaultGame.Remove(func) end

---@overload fun()
Events.RandomEventOccurredNarrative = {}
---*Query*
---@return number amount
function Events.RandomEventOccurredNarrative.Count() end
---*Action*
function Events.RandomEventOccurredNarrative.RemoveAll() end
---*Action*
function Events.RandomEventOccurredNarrative.Dispatch() end
Events.RandomEventOccurredNarrative = {}
---*Query*
---@return number amount
function Events.RandomEventOccurredNarrative.Count() end
---*Action*
function Events.RandomEventOccurredNarrative.RemoveAll() end
---*Action*
function Events.RandomEventOccurredNarrative.Dispatch() end
---*Action*
function Events.RandomEventOccurredNarrative.Call() end
---*Action*
function Events.RandomEventOccurredNarrative.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.RandomEventOccurredNarrative.Add(func) end
---*Action*
---@param func function
function Events.RandomEventOccurredNarrative.Remove(func) end

---@overload fun()
Events.ContentOutOfDatePopup = {}
---*Query*
---@return number amount
function Events.ContentOutOfDatePopup.Count() end
---*Action*
function Events.ContentOutOfDatePopup.RemoveAll() end
---*Action*
function Events.ContentOutOfDatePopup.Dispatch() end
Events.ContentOutOfDatePopup = {}
---*Query*
---@return number amount
function Events.ContentOutOfDatePopup.Count() end
---*Action*
function Events.ContentOutOfDatePopup.RemoveAll() end
---*Action*
function Events.ContentOutOfDatePopup.Dispatch() end
---*Action*
function Events.ContentOutOfDatePopup.Call() end
---*Action*
function Events.ContentOutOfDatePopup.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.ContentOutOfDatePopup.Add(func) end
---*Action*
---@param func function
function Events.ContentOutOfDatePopup.Remove(func) end

---@overload fun()
Events.MultiplayerPurchasePopup = {}
---*Query*
---@return number amount
function Events.MultiplayerPurchasePopup.Count() end
---*Action*
function Events.MultiplayerPurchasePopup.RemoveAll() end
---*Action*
function Events.MultiplayerPurchasePopup.Dispatch() end
Events.MultiplayerPurchasePopup = {}
---*Query*
---@return number amount
function Events.MultiplayerPurchasePopup.Count() end
---*Action*
function Events.MultiplayerPurchasePopup.RemoveAll() end
---*Action*
function Events.MultiplayerPurchasePopup.Dispatch() end
---*Action*
function Events.MultiplayerPurchasePopup.Call() end
---*Action*
function Events.MultiplayerPurchasePopup.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.MultiplayerPurchasePopup.Add(func) end
---*Action*
---@param func function
function Events.MultiplayerPurchasePopup.Remove(func) end

---@overload fun()
Events.MultiplayerGameInvite = {}
---*Query*
---@return number amount
function Events.MultiplayerGameInvite.Count() end
---*Action*
function Events.MultiplayerGameInvite.RemoveAll() end
---*Action*
function Events.MultiplayerGameInvite.Dispatch() end
Events.MultiplayerGameInvite = {}
---*Query*
---@return number amount
function Events.MultiplayerGameInvite.Count() end
---*Action*
function Events.MultiplayerGameInvite.RemoveAll() end
---*Action*
function Events.MultiplayerGameInvite.Dispatch() end
---*Action*
function Events.MultiplayerGameInvite.Call() end
---*Action*
function Events.MultiplayerGameInvite.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.MultiplayerGameInvite.Add(func) end
---*Action*
---@param func function
function Events.MultiplayerGameInvite.Remove(func) end

---@overload fun()
Events.CursorHexPositionChanged = {}
---*Query*
---@return number amount
function Events.CursorHexPositionChanged.Count() end
---*Action*
function Events.CursorHexPositionChanged.RemoveAll() end
---*Action*
function Events.CursorHexPositionChanged.Dispatch() end
Events.CursorHexPositionChanged = {}
---*Query*
---@return number amount
function Events.CursorHexPositionChanged.Count() end
---*Action*
function Events.CursorHexPositionChanged.RemoveAll() end
---*Action*
function Events.CursorHexPositionChanged.Dispatch() end
---*Action*
function Events.CursorHexPositionChanged.Call() end
---*Action*
function Events.CursorHexPositionChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.CursorHexPositionChanged.Add(func) end
---*Action*
---@param func function
function Events.CursorHexPositionChanged.Remove(func) end

---@overload fun()
Events.FinishedGameplayContentChange = {}
---*Query*
---@return number amount
function Events.FinishedGameplayContentChange.Count() end
---*Action*
function Events.FinishedGameplayContentChange.RemoveAll() end
---*Action*
function Events.FinishedGameplayContentChange.Dispatch() end
Events.FinishedGameplayContentChange = {}
---*Query*
---@return number amount
function Events.FinishedGameplayContentChange.Count() end
---*Action*
function Events.FinishedGameplayContentChange.RemoveAll() end
---*Action*
function Events.FinishedGameplayContentChange.Dispatch() end
---*Action*
function Events.FinishedGameplayContentChange.Call() end
---*Action*
function Events.FinishedGameplayContentChange.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.FinishedGameplayContentChange.Add(func) end
---*Action*
---@param func function
function Events.FinishedGameplayContentChange.Remove(func) end

---@overload fun()
Events.GameConfigurationParameterChanged = {}
---*Query*
---@return number amount
function Events.GameConfigurationParameterChanged.Count() end
---*Action*
function Events.GameConfigurationParameterChanged.RemoveAll() end
---*Action*
function Events.GameConfigurationParameterChanged.Dispatch() end
Events.GameConfigurationParameterChanged = {}
---*Query*
---@return number amount
function Events.GameConfigurationParameterChanged.Count() end
---*Action*
function Events.GameConfigurationParameterChanged.RemoveAll() end
---*Action*
function Events.GameConfigurationParameterChanged.Dispatch() end
---*Action*
function Events.GameConfigurationParameterChanged.Call() end
---*Action*
function Events.GameConfigurationParameterChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.GameConfigurationParameterChanged.Add(func) end
---*Action*
---@param func function
function Events.GameConfigurationParameterChanged.Remove(func) end

---@overload fun()
Events.PurchaseFullGame = {}
---*Query*
---@return number amount
function Events.PurchaseFullGame.Count() end
---*Action*
function Events.PurchaseFullGame.RemoveAll() end
---*Action*
function Events.PurchaseFullGame.Dispatch() end
Events.PurchaseFullGame = {}
---*Query*
---@return number amount
function Events.PurchaseFullGame.Count() end
---*Action*
function Events.PurchaseFullGame.RemoveAll() end
---*Action*
function Events.PurchaseFullGame.Dispatch() end
---*Action*
function Events.PurchaseFullGame.Call() end
---*Action*
function Events.PurchaseFullGame.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.PurchaseFullGame.Add(func) end
---*Action*
---@param func function
function Events.PurchaseFullGame.Remove(func) end

---@overload fun()
Events.OptionsSaved = {}
---*Query*
---@return number amount
function Events.OptionsSaved.Count() end
---*Action*
function Events.OptionsSaved.RemoveAll() end
---*Action*
function Events.OptionsSaved.Dispatch() end
Events.OptionsSaved = {}
---*Query*
---@return number amount
function Events.OptionsSaved.Count() end
---*Action*
function Events.OptionsSaved.RemoveAll() end
---*Action*
function Events.OptionsSaved.Dispatch() end
---*Action*
function Events.OptionsSaved.Call() end
---*Action*
function Events.OptionsSaved.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.OptionsSaved.Add(func) end
---*Action*
---@param func function
function Events.OptionsSaved.Remove(func) end

---@overload fun()
Events.DragCamera = {}
---*Query*
---@return number amount
function Events.DragCamera.Count() end
---*Action*
function Events.DragCamera.RemoveAll() end
---*Action*
function Events.DragCamera.Dispatch() end
Events.DragCamera = {}
---*Query*
---@return number amount
function Events.DragCamera.Count() end
---*Action*
function Events.DragCamera.RemoveAll() end
---*Action*
function Events.DragCamera.Dispatch() end
---*Action*
function Events.DragCamera.Call() end
---*Action*
function Events.DragCamera.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.DragCamera.Add(func) end
---*Action*
---@param func function
function Events.DragCamera.Remove(func) end

---@overload fun()
Events.PlayerTurnCompleteIgnored = {}
---*Query*
---@return number amount
function Events.PlayerTurnCompleteIgnored.Count() end
---*Action*
function Events.PlayerTurnCompleteIgnored.RemoveAll() end
---*Action*
function Events.PlayerTurnCompleteIgnored.Dispatch() end
Events.PlayerTurnCompleteIgnored = {}
---*Query*
---@return number amount
function Events.PlayerTurnCompleteIgnored.Count() end
---*Action*
function Events.PlayerTurnCompleteIgnored.RemoveAll() end
---*Action*
function Events.PlayerTurnCompleteIgnored.Dispatch() end
---*Action*
function Events.PlayerTurnCompleteIgnored.Call() end
---*Action*
function Events.PlayerTurnCompleteIgnored.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.PlayerTurnCompleteIgnored.Add(func) end
---*Action*
---@param func function
function Events.PlayerTurnCompleteIgnored.Remove(func) end

---@overload fun()
Events.RequestLoad = {}
---*Query*
---@return number amount
function Events.RequestLoad.Count() end
---*Action*
function Events.RequestLoad.RemoveAll() end
---*Action*
function Events.RequestLoad.Dispatch() end
Events.RequestLoad = {}
---*Query*
---@return number amount
function Events.RequestLoad.Count() end
---*Action*
function Events.RequestLoad.RemoveAll() end
---*Action*
function Events.RequestLoad.Dispatch() end
---*Action*
function Events.RequestLoad.Call() end
---*Action*
function Events.RequestLoad.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.RequestLoad.Add(func) end
---*Action*
---@param func function
function Events.RequestLoad.Remove(func) end

---@overload fun()
Events.ShowEndDemoPurchaseDialog = {}
---*Query*
---@return number amount
function Events.ShowEndDemoPurchaseDialog.Count() end
---*Action*
function Events.ShowEndDemoPurchaseDialog.RemoveAll() end
---*Action*
function Events.ShowEndDemoPurchaseDialog.Dispatch() end
Events.ShowEndDemoPurchaseDialog = {}
---*Query*
---@return number amount
function Events.ShowEndDemoPurchaseDialog.Count() end
---*Action*
function Events.ShowEndDemoPurchaseDialog.RemoveAll() end
---*Action*
function Events.ShowEndDemoPurchaseDialog.Dispatch() end
---*Action*
function Events.ShowEndDemoPurchaseDialog.Call() end
---*Action*
function Events.ShowEndDemoPurchaseDialog.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.ShowEndDemoPurchaseDialog.Add(func) end
---*Action*
---@param func function
function Events.ShowEndDemoPurchaseDialog.Remove(func) end

---@overload fun()
Events.StopCameraAnimationByID = {}
---*Query*
---@return number amount
function Events.StopCameraAnimationByID.Count() end
---*Action*
function Events.StopCameraAnimationByID.RemoveAll() end
---*Action*
function Events.StopCameraAnimationByID.Dispatch() end
Events.StopCameraAnimationByID = {}
---*Query*
---@return number amount
function Events.StopCameraAnimationByID.Count() end
---*Action*
function Events.StopCameraAnimationByID.RemoveAll() end
---*Action*
function Events.StopCameraAnimationByID.Dispatch() end
---*Action*
function Events.StopCameraAnimationByID.Call() end
---*Action*
function Events.StopCameraAnimationByID.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.StopCameraAnimationByID.Add(func) end
---*Action*
---@param func function
function Events.StopCameraAnimationByID.Remove(func) end

---@overload fun()
Events.DemoTurnLimitReached = {}
---*Query*
---@return number amount
function Events.DemoTurnLimitReached.Count() end
---*Action*
function Events.DemoTurnLimitReached.RemoveAll() end
---*Action*
function Events.DemoTurnLimitReached.Dispatch() end
Events.DemoTurnLimitReached = {}
---*Query*
---@return number amount
function Events.DemoTurnLimitReached.Count() end
---*Action*
function Events.DemoTurnLimitReached.RemoveAll() end
---*Action*
function Events.DemoTurnLimitReached.Dispatch() end
---*Action*
function Events.DemoTurnLimitReached.Call() end
---*Action*
function Events.DemoTurnLimitReached.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.DemoTurnLimitReached.Add(func) end
---*Action*
---@param func function
function Events.DemoTurnLimitReached.Remove(func) end

---@overload fun()
Events.SecretSocietyDiscovered = {}
---*Query*
---@return number amount
function Events.SecretSocietyDiscovered.Count() end
---*Action*
function Events.SecretSocietyDiscovered.RemoveAll() end
---*Action*
function Events.SecretSocietyDiscovered.Dispatch() end
Events.SecretSocietyDiscovered = {}
---*Query*
---@return number amount
function Events.SecretSocietyDiscovered.Count() end
---*Action*
function Events.SecretSocietyDiscovered.RemoveAll() end
---*Action*
function Events.SecretSocietyDiscovered.Dispatch() end
---*Action*
function Events.SecretSocietyDiscovered.Call() end
---*Action*
function Events.SecretSocietyDiscovered.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.SecretSocietyDiscovered.Add(func) end
---*Action*
---@param func function
function Events.SecretSocietyDiscovered.Remove(func) end

---@overload fun()
Events.AfterPlayerTurnActivated = {}
---*Query*
---@return number amount
function Events.AfterPlayerTurnActivated.Count() end
---*Action*
function Events.AfterPlayerTurnActivated.RemoveAll() end
---*Action*
function Events.AfterPlayerTurnActivated.Dispatch() end
Events.AfterPlayerTurnActivated = {}
---*Query*
---@return number amount
function Events.AfterPlayerTurnActivated.Count() end
---*Action*
function Events.AfterPlayerTurnActivated.RemoveAll() end
---*Action*
function Events.AfterPlayerTurnActivated.Dispatch() end
---*Action*
function Events.AfterPlayerTurnActivated.Call() end
---*Action*
function Events.AfterPlayerTurnActivated.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.AfterPlayerTurnActivated.Add(func) end
---*Action*
---@param func function
function Events.AfterPlayerTurnActivated.Remove(func) end

---@overload fun()
Events.InputDeviceLayoutChanged = {}
---*Query*
---@return number amount
function Events.InputDeviceLayoutChanged.Count() end
---*Action*
function Events.InputDeviceLayoutChanged.RemoveAll() end
---*Action*
function Events.InputDeviceLayoutChanged.Dispatch() end
Events.InputDeviceLayoutChanged = {}
---*Query*
---@return number amount
function Events.InputDeviceLayoutChanged.Count() end
---*Action*
function Events.InputDeviceLayoutChanged.RemoveAll() end
---*Action*
function Events.InputDeviceLayoutChanged.Dispatch() end
---*Action*
function Events.InputDeviceLayoutChanged.Call() end
---*Action*
function Events.InputDeviceLayoutChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.InputDeviceLayoutChanged.Add(func) end
---*Action*
---@param func function
function Events.InputDeviceLayoutChanged.Remove(func) end

---@overload fun()
Events.UnitTourismBomb = {}
---*Query*
---@return number amount
function Events.UnitTourismBomb.Count() end
---*Action*
function Events.UnitTourismBomb.RemoveAll() end
---*Action*
function Events.UnitTourismBomb.Dispatch() end
Events.UnitTourismBomb = {}
---*Query*
---@return number amount
function Events.UnitTourismBomb.Count() end
---*Action*
function Events.UnitTourismBomb.RemoveAll() end
---*Action*
function Events.UnitTourismBomb.Dispatch() end
---*Action*
function Events.UnitTourismBomb.Call() end
---*Action*
function Events.UnitTourismBomb.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.UnitTourismBomb.Add(func) end
---*Action*
---@param func function
function Events.UnitTourismBomb.Remove(func) end

---@overload fun()
Events.BeforeGameplayContentConfigure = {}
---*Query*
---@return number amount
function Events.BeforeGameplayContentConfigure.Count() end
---*Action*
function Events.BeforeGameplayContentConfigure.RemoveAll() end
---*Action*
function Events.BeforeGameplayContentConfigure.Dispatch() end
Events.BeforeGameplayContentConfigure = {}
---*Query*
---@return number amount
function Events.BeforeGameplayContentConfigure.Count() end
---*Action*
function Events.BeforeGameplayContentConfigure.RemoveAll() end
---*Action*
function Events.BeforeGameplayContentConfigure.Dispatch() end
---*Action*
function Events.BeforeGameplayContentConfigure.Call() end
---*Action*
function Events.BeforeGameplayContentConfigure.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.BeforeGameplayContentConfigure.Add(func) end
---*Action*
---@param func function
function Events.BeforeGameplayContentConfigure.Remove(func) end

---@overload fun()
Events.MatchUpdateSaveGameComplete = {}
---*Query*
---@return number amount
function Events.MatchUpdateSaveGameComplete.Count() end
---*Action*
function Events.MatchUpdateSaveGameComplete.RemoveAll() end
---*Action*
function Events.MatchUpdateSaveGameComplete.Dispatch() end
Events.MatchUpdateSaveGameComplete = {}
---*Query*
---@return number amount
function Events.MatchUpdateSaveGameComplete.Count() end
---*Action*
function Events.MatchUpdateSaveGameComplete.RemoveAll() end
---*Action*
function Events.MatchUpdateSaveGameComplete.Dispatch() end
---*Action*
function Events.MatchUpdateSaveGameComplete.Call() end
---*Action*
function Events.MatchUpdateSaveGameComplete.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.MatchUpdateSaveGameComplete.Add(func) end
---*Action*
---@param func function
function Events.MatchUpdateSaveGameComplete.Remove(func) end

---@overload fun()
Events.MainMenuStateDone = {}
---*Query*
---@return number amount
function Events.MainMenuStateDone.Count() end
---*Action*
function Events.MainMenuStateDone.RemoveAll() end
---*Action*
function Events.MainMenuStateDone.Dispatch() end
Events.MainMenuStateDone = {}
---*Query*
---@return number amount
function Events.MainMenuStateDone.Count() end
---*Action*
function Events.MainMenuStateDone.RemoveAll() end
---*Action*
function Events.MainMenuStateDone.Dispatch() end
---*Action*
function Events.MainMenuStateDone.Call() end
---*Action*
function Events.MainMenuStateDone.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.MainMenuStateDone.Add(func) end
---*Action*
---@param func function
function Events.MainMenuStateDone.Remove(func) end

---@overload fun()
Events.WorldCongressPlayersChoice = {}
---*Query*
---@return number amount
function Events.WorldCongressPlayersChoice.Count() end
---*Action*
function Events.WorldCongressPlayersChoice.RemoveAll() end
---*Action*
function Events.WorldCongressPlayersChoice.Dispatch() end
Events.WorldCongressPlayersChoice = {}
---*Query*
---@return number amount
function Events.WorldCongressPlayersChoice.Count() end
---*Action*
function Events.WorldCongressPlayersChoice.RemoveAll() end
---*Action*
function Events.WorldCongressPlayersChoice.Dispatch() end
---*Action*
function Events.WorldCongressPlayersChoice.Call() end
---*Action*
function Events.WorldCongressPlayersChoice.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.WorldCongressPlayersChoice.Add(func) end
---*Action*
---@param func function
function Events.WorldCongressPlayersChoice.Remove(func) end

---@overload fun()
Events.TakeUserToDLCScreen = {}
---*Query*
---@return number amount
function Events.TakeUserToDLCScreen.Count() end
---*Action*
function Events.TakeUserToDLCScreen.RemoveAll() end
---*Action*
function Events.TakeUserToDLCScreen.Dispatch() end
Events.TakeUserToDLCScreen = {}
---*Query*
---@return number amount
function Events.TakeUserToDLCScreen.Count() end
---*Action*
function Events.TakeUserToDLCScreen.RemoveAll() end
---*Action*
function Events.TakeUserToDLCScreen.Dispatch() end
---*Action*
function Events.TakeUserToDLCScreen.Call() end
---*Action*
function Events.TakeUserToDLCScreen.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.TakeUserToDLCScreen.Add(func) end
---*Action*
---@param func function
function Events.TakeUserToDLCScreen.Remove(func) end

---@overload fun()
Events.OptionsReset = {}
---*Query*
---@return number amount
function Events.OptionsReset.Count() end
---*Action*
function Events.OptionsReset.RemoveAll() end
---*Action*
function Events.OptionsReset.Dispatch() end
Events.OptionsReset = {}
---*Query*
---@return number amount
function Events.OptionsReset.Count() end
---*Action*
function Events.OptionsReset.RemoveAll() end
---*Action*
function Events.OptionsReset.Dispatch() end
---*Action*
function Events.OptionsReset.Call() end
---*Action*
function Events.OptionsReset.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.OptionsReset.Add(func) end
---*Action*
---@param func function
function Events.OptionsReset.Remove(func) end

---@overload fun()
Events.AllDistrictsDeselected = {}
---*Query*
---@return number amount
function Events.AllDistrictsDeselected.Count() end
---*Action*
function Events.AllDistrictsDeselected.RemoveAll() end
---*Action*
function Events.AllDistrictsDeselected.Dispatch() end
Events.AllDistrictsDeselected = {}
---*Query*
---@return number amount
function Events.AllDistrictsDeselected.Count() end
---*Action*
function Events.AllDistrictsDeselected.RemoveAll() end
---*Action*
function Events.AllDistrictsDeselected.Dispatch() end
---*Action*
function Events.AllDistrictsDeselected.Call() end
---*Action*
function Events.AllDistrictsDeselected.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.AllDistrictsDeselected.Add(func) end
---*Action*
---@param func function
function Events.AllDistrictsDeselected.Remove(func) end

---@overload fun()
Events.GamepadActiveChanged = {}
---*Query*
---@return number amount
function Events.GamepadActiveChanged.Count() end
---*Action*
function Events.GamepadActiveChanged.RemoveAll() end
---*Action*
function Events.GamepadActiveChanged.Dispatch() end
Events.GamepadActiveChanged = {}
---*Query*
---@return number amount
function Events.GamepadActiveChanged.Count() end
---*Action*
function Events.GamepadActiveChanged.RemoveAll() end
---*Action*
function Events.GamepadActiveChanged.Dispatch() end
---*Action*
function Events.GamepadActiveChanged.Call() end
---*Action*
function Events.GamepadActiveChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.GamepadActiveChanged.Add(func) end
---*Action*
---@param func function
function Events.GamepadActiveChanged.Remove(func) end

---@overload fun()
Events.BeforeGameplayContentChange = {}
---*Query*
---@return number amount
function Events.BeforeGameplayContentChange.Count() end
---*Action*
function Events.BeforeGameplayContentChange.RemoveAll() end
---*Action*
function Events.BeforeGameplayContentChange.Dispatch() end
Events.BeforeGameplayContentChange = {}
---*Query*
---@return number amount
function Events.BeforeGameplayContentChange.Count() end
---*Action*
function Events.BeforeGameplayContentChange.RemoveAll() end
---*Action*
function Events.BeforeGameplayContentChange.Dispatch() end
---*Action*
function Events.BeforeGameplayContentChange.Call() end
---*Action*
function Events.BeforeGameplayContentChange.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.BeforeGameplayContentChange.Add(func) end
---*Action*
---@param func function
function Events.BeforeGameplayContentChange.Remove(func) end

---@overload fun()
Events.UnitHeroCreated = {}
---*Query*
---@return number amount
function Events.UnitHeroCreated.Count() end
---*Action*
function Events.UnitHeroCreated.RemoveAll() end
---*Action*
function Events.UnitHeroCreated.Dispatch() end
Events.UnitHeroCreated = {}
---*Query*
---@return number amount
function Events.UnitHeroCreated.Count() end
---*Action*
function Events.UnitHeroCreated.RemoveAll() end
---*Action*
function Events.UnitHeroCreated.Dispatch() end
---*Action*
function Events.UnitHeroCreated.Call() end
---*Action*
function Events.UnitHeroCreated.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.UnitHeroCreated.Add(func) end
---*Action*
---@param func function
function Events.UnitHeroCreated.Remove(func) end

---@overload fun()
Events.AuthenticateDLC = {}
---*Query*
---@return number amount
function Events.AuthenticateDLC.Count() end
---*Action*
function Events.AuthenticateDLC.RemoveAll() end
---*Action*
function Events.AuthenticateDLC.Dispatch() end
Events.AuthenticateDLC = {}
---*Query*
---@return number amount
function Events.AuthenticateDLC.Count() end
---*Action*
function Events.AuthenticateDLC.RemoveAll() end
---*Action*
function Events.AuthenticateDLC.Dispatch() end
---*Action*
function Events.AuthenticateDLC.Call() end
---*Action*
function Events.AuthenticateDLC.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.AuthenticateDLC.Add(func) end
---*Action*
---@param func function
function Events.AuthenticateDLC.Remove(func) end

---@overload fun()
Events.RequestSave = {}
---*Query*
---@return number amount
function Events.RequestSave.Count() end
---*Action*
function Events.RequestSave.RemoveAll() end
---*Action*
function Events.RequestSave.Dispatch() end
Events.RequestSave = {}
---*Query*
---@return number amount
function Events.RequestSave.Count() end
---*Action*
function Events.RequestSave.RemoveAll() end
---*Action*
function Events.RequestSave.Dispatch() end
---*Action*
function Events.RequestSave.Call() end
---*Action*
function Events.RequestSave.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.RequestSave.Add(func) end
---*Action*
---@param func function
function Events.RequestSave.Remove(func) end

---@overload fun()
Events.DLCDownloaded = {}
---*Query*
---@return number amount
function Events.DLCDownloaded.Count() end
---*Action*
function Events.DLCDownloaded.RemoveAll() end
---*Action*
function Events.DLCDownloaded.Dispatch() end
Events.DLCDownloaded = {}
---*Query*
---@return number amount
function Events.DLCDownloaded.Count() end
---*Action*
function Events.DLCDownloaded.RemoveAll() end
---*Action*
function Events.DLCDownloaded.Dispatch() end
---*Action*
function Events.DLCDownloaded.Call() end
---*Action*
function Events.DLCDownloaded.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.DLCDownloaded.Add(func) end
---*Action*
---@param func function
function Events.DLCDownloaded.Remove(func) end

---@overload fun()
Events.AllCitiesDeselected = {}
---*Query*
---@return number amount
function Events.AllCitiesDeselected.Count() end
---*Action*
function Events.AllCitiesDeselected.RemoveAll() end
---*Action*
function Events.AllCitiesDeselected.Dispatch() end
Events.AllCitiesDeselected = {}
---*Query*
---@return number amount
function Events.AllCitiesDeselected.Count() end
---*Action*
function Events.AllCitiesDeselected.RemoveAll() end
---*Action*
function Events.AllCitiesDeselected.Dispatch() end
---*Action*
function Events.AllCitiesDeselected.Call() end
---*Action*
function Events.AllCitiesDeselected.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.AllCitiesDeselected.Add(func) end
---*Action*
---@param func function
function Events.AllCitiesDeselected.Remove(func) end

---@overload fun()
Events.NuclearReactorChanged = {}
---*Query*
---@return number amount
function Events.NuclearReactorChanged.Count() end
---*Action*
function Events.NuclearReactorChanged.RemoveAll() end
---*Action*
function Events.NuclearReactorChanged.Dispatch() end
Events.NuclearReactorChanged = {}
---*Query*
---@return number amount
function Events.NuclearReactorChanged.Count() end
---*Action*
function Events.NuclearReactorChanged.RemoveAll() end
---*Action*
function Events.NuclearReactorChanged.Dispatch() end
---*Action*
function Events.NuclearReactorChanged.Call() end
---*Action*
function Events.NuclearReactorChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.NuclearReactorChanged.Add(func) end
---*Action*
---@param func function
function Events.NuclearReactorChanged.Remove(func) end

---@overload fun()
Events.CameraAnimationStarted = {}
---*Query*
---@return number amount
function Events.CameraAnimationStarted.Count() end
---*Action*
function Events.CameraAnimationStarted.RemoveAll() end
---*Action*
function Events.CameraAnimationStarted.Dispatch() end
Events.CameraAnimationStarted = {}
---*Query*
---@return number amount
function Events.CameraAnimationStarted.Count() end
---*Action*
function Events.CameraAnimationStarted.RemoveAll() end
---*Action*
function Events.CameraAnimationStarted.Dispatch() end
---*Action*
function Events.CameraAnimationStarted.Call() end
---*Action*
function Events.CameraAnimationStarted.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.CameraAnimationStarted.Add(func) end
---*Action*
---@param func function
function Events.CameraAnimationStarted.Remove(func) end

---@overload fun()
Events.StormAddedToMap = {}
---*Query*
---@return number amount
function Events.StormAddedToMap.Count() end
---*Action*
function Events.StormAddedToMap.RemoveAll() end
---*Action*
function Events.StormAddedToMap.Dispatch() end
Events.StormAddedToMap = {}
---*Query*
---@return number amount
function Events.StormAddedToMap.Count() end
---*Action*
function Events.StormAddedToMap.RemoveAll() end
---*Action*
function Events.StormAddedToMap.Dispatch() end
---*Action*
function Events.StormAddedToMap.Call() end
---*Action*
function Events.StormAddedToMap.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.StormAddedToMap.Add(func) end
---*Action*
---@param func function
function Events.StormAddedToMap.Remove(func) end

---@overload fun()
Events.CloudGameInfoUpdated = {}
---*Query*
---@return number amount
function Events.CloudGameInfoUpdated.Count() end
---*Action*
function Events.CloudGameInfoUpdated.RemoveAll() end
---*Action*
function Events.CloudGameInfoUpdated.Dispatch() end
Events.CloudGameInfoUpdated = {}
---*Query*
---@return number amount
function Events.CloudGameInfoUpdated.Count() end
---*Action*
function Events.CloudGameInfoUpdated.RemoveAll() end
---*Action*
function Events.CloudGameInfoUpdated.Dispatch() end
---*Action*
function Events.CloudGameInfoUpdated.Call() end
---*Action*
function Events.CloudGameInfoUpdated.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.CloudGameInfoUpdated.Add(func) end
---*Action*
---@param func function
function Events.CloudGameInfoUpdated.Remove(func) end

---@overload fun()
Events.OptionChanged = {}
---*Query*
---@return number amount
function Events.OptionChanged.Count() end
---*Action*
function Events.OptionChanged.RemoveAll() end
---*Action*
function Events.OptionChanged.Dispatch() end
Events.OptionChanged = {}
---*Query*
---@return number amount
function Events.OptionChanged.Count() end
---*Action*
function Events.OptionChanged.RemoveAll() end
---*Action*
function Events.OptionChanged.Dispatch() end
---*Action*
function Events.OptionChanged.Call() end
---*Action*
function Events.OptionChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.OptionChanged.Add(func) end
---*Action*
---@param func function
function Events.OptionChanged.Remove(func) end

---@overload fun()
Events.PlayerDiscoveredHero = {}
---*Query*
---@return number amount
function Events.PlayerDiscoveredHero.Count() end
---*Action*
function Events.PlayerDiscoveredHero.RemoveAll() end
---*Action*
function Events.PlayerDiscoveredHero.Dispatch() end
Events.PlayerDiscoveredHero = {}
---*Query*
---@return number amount
function Events.PlayerDiscoveredHero.Count() end
---*Action*
function Events.PlayerDiscoveredHero.RemoveAll() end
---*Action*
function Events.PlayerDiscoveredHero.Dispatch() end
---*Action*
function Events.PlayerDiscoveredHero.Call() end
---*Action*
function Events.PlayerDiscoveredHero.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.PlayerDiscoveredHero.Add(func) end
---*Action*
---@param func function
function Events.PlayerDiscoveredHero.Remove(func) end

---@overload fun()
Events.UploadCloudSaveComplete = {}
---*Query*
---@return number amount
function Events.UploadCloudSaveComplete.Count() end
---*Action*
function Events.UploadCloudSaveComplete.RemoveAll() end
---*Action*
function Events.UploadCloudSaveComplete.Dispatch() end
Events.UploadCloudSaveComplete = {}
---*Query*
---@return number amount
function Events.UploadCloudSaveComplete.Count() end
---*Action*
function Events.UploadCloudSaveComplete.RemoveAll() end
---*Action*
function Events.UploadCloudSaveComplete.Dispatch() end
---*Action*
function Events.UploadCloudSaveComplete.Call() end
---*Action*
function Events.UploadCloudSaveComplete.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.UploadCloudSaveComplete.Add(func) end
---*Action*
---@param func function
function Events.UploadCloudSaveComplete.Remove(func) end

---@overload fun()
Events.LeaderAnimationChanged = {}
---*Query*
---@return number amount
function Events.LeaderAnimationChanged.Count() end
---*Action*
function Events.LeaderAnimationChanged.RemoveAll() end
---*Action*
function Events.LeaderAnimationChanged.Dispatch() end
Events.LeaderAnimationChanged = {}
---*Query*
---@return number amount
function Events.LeaderAnimationChanged.Count() end
---*Action*
function Events.LeaderAnimationChanged.RemoveAll() end
---*Action*
function Events.LeaderAnimationChanged.Dispatch() end
---*Action*
function Events.LeaderAnimationChanged.Call() end
---*Action*
function Events.LeaderAnimationChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.LeaderAnimationChanged.Add(func) end
---*Action*
---@param func function
function Events.LeaderAnimationChanged.Remove(func) end

---@overload fun()
Events.AchievementUnlocked = {}
---*Query*
---@return number amount
function Events.AchievementUnlocked.Count() end
---*Action*
function Events.AchievementUnlocked.RemoveAll() end
---*Action*
function Events.AchievementUnlocked.Dispatch() end
Events.AchievementUnlocked = {}
---*Query*
---@return number amount
function Events.AchievementUnlocked.Count() end
---*Action*
function Events.AchievementUnlocked.RemoveAll() end
---*Action*
function Events.AchievementUnlocked.Dispatch() end
---*Action*
function Events.AchievementUnlocked.Call() end
---*Action*
function Events.AchievementUnlocked.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.AchievementUnlocked.Add(func) end
---*Action*
---@param func function
function Events.AchievementUnlocked.Remove(func) end

---@overload fun()
Events.LensFocusCity = {}
---*Query*
---@return number amount
function Events.LensFocusCity.Count() end
---*Action*
function Events.LensFocusCity.RemoveAll() end
---*Action*
function Events.LensFocusCity.Dispatch() end
Events.LensFocusCity = {}
---*Query*
---@return number amount
function Events.LensFocusCity.Count() end
---*Action*
function Events.LensFocusCity.RemoveAll() end
---*Action*
function Events.LensFocusCity.Dispatch() end
---*Action*
function Events.LensFocusCity.Call() end
---*Action*
function Events.LensFocusCity.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.LensFocusCity.Add(func) end
---*Action*
---@param func function
function Events.LensFocusCity.Remove(func) end

---@overload fun()
Events.DLCFullGameRequiredPopup = {}
---*Query*
---@return number amount
function Events.DLCFullGameRequiredPopup.Count() end
---*Action*
function Events.DLCFullGameRequiredPopup.RemoveAll() end
---*Action*
function Events.DLCFullGameRequiredPopup.Dispatch() end
Events.DLCFullGameRequiredPopup = {}
---*Query*
---@return number amount
function Events.DLCFullGameRequiredPopup.Count() end
---*Action*
function Events.DLCFullGameRequiredPopup.RemoveAll() end
---*Action*
function Events.DLCFullGameRequiredPopup.Dispatch() end
---*Action*
function Events.DLCFullGameRequiredPopup.Call() end
---*Action*
function Events.DLCFullGameRequiredPopup.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.DLCFullGameRequiredPopup.Add(func) end
---*Action*
---@param func function
function Events.DLCFullGameRequiredPopup.Remove(func) end

---@overload fun()
Events.InputSourceChanged = {}
---*Query*
---@return number amount
function Events.InputSourceChanged.Count() end
---*Action*
function Events.InputSourceChanged.RemoveAll() end
---*Action*
function Events.InputSourceChanged.Dispatch() end
Events.InputSourceChanged = {}
---*Query*
---@return number amount
function Events.InputSourceChanged.Count() end
---*Action*
function Events.InputSourceChanged.RemoveAll() end
---*Action*
function Events.InputSourceChanged.Dispatch() end
---*Action*
function Events.InputSourceChanged.Call() end
---*Action*
function Events.InputSourceChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.InputSourceChanged.Add(func) end
---*Action*
---@param func function
function Events.InputSourceChanged.Remove(func) end

---@overload fun()
Events.PublisherServicesLoginStateChange = {}
---*Query*
---@return number amount
function Events.PublisherServicesLoginStateChange.Count() end
---*Action*
function Events.PublisherServicesLoginStateChange.RemoveAll() end
---*Action*
function Events.PublisherServicesLoginStateChange.Dispatch() end
Events.PublisherServicesLoginStateChange = {}
---*Query*
---@return number amount
function Events.PublisherServicesLoginStateChange.Count() end
---*Action*
function Events.PublisherServicesLoginStateChange.RemoveAll() end
---*Action*
function Events.PublisherServicesLoginStateChange.Dispatch() end
---*Action*
function Events.PublisherServicesLoginStateChange.Call() end
---*Action*
function Events.PublisherServicesLoginStateChange.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.PublisherServicesLoginStateChange.Add(func) end
---*Action*
---@param func function
function Events.PublisherServicesLoginStateChange.Remove(func) end

---@overload fun()
Events.UnitAttacksRemainingChanged = {}
---*Query*
---@return number amount
function Events.UnitAttacksRemainingChanged.Count() end
---*Action*
function Events.UnitAttacksRemainingChanged.RemoveAll() end
---*Action*
function Events.UnitAttacksRemainingChanged.Dispatch() end
Events.UnitAttacksRemainingChanged = {}
---*Query*
---@return number amount
function Events.UnitAttacksRemainingChanged.Count() end
---*Action*
function Events.UnitAttacksRemainingChanged.RemoveAll() end
---*Action*
function Events.UnitAttacksRemainingChanged.Dispatch() end
---*Action*
function Events.UnitAttacksRemainingChanged.Call() end
---*Action*
function Events.UnitAttacksRemainingChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.UnitAttacksRemainingChanged.Add(func) end
---*Action*
---@param func function
function Events.UnitAttacksRemainingChanged.Remove(func) end

---@overload fun()
Events.ContextVisibilityChanged = {}
---*Query*
---@return number amount
function Events.ContextVisibilityChanged.Count() end
---*Action*
function Events.ContextVisibilityChanged.RemoveAll() end
---*Action*
function Events.ContextVisibilityChanged.Dispatch() end
Events.ContextVisibilityChanged = {}
---*Query*
---@return number amount
function Events.ContextVisibilityChanged.Count() end
---*Action*
function Events.ContextVisibilityChanged.RemoveAll() end
---*Action*
function Events.ContextVisibilityChanged.Dispatch() end
---*Action*
function Events.ContextVisibilityChanged.Call() end
---*Action*
function Events.ContextVisibilityChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.ContextVisibilityChanged.Add(func) end
---*Action*
---@param func function
function Events.ContextVisibilityChanged.Remove(func) end

---@overload fun()
Events.UnitKilledLifespanExpired = {}
---*Query*
---@return number amount
function Events.UnitKilledLifespanExpired.Count() end
---*Action*
function Events.UnitKilledLifespanExpired.RemoveAll() end
---*Action*
function Events.UnitKilledLifespanExpired.Dispatch() end
Events.UnitKilledLifespanExpired = {}
---*Query*
---@return number amount
function Events.UnitKilledLifespanExpired.Count() end
---*Action*
function Events.UnitKilledLifespanExpired.RemoveAll() end
---*Action*
function Events.UnitKilledLifespanExpired.Dispatch() end
---*Action*
function Events.UnitKilledLifespanExpired.Call() end
---*Action*
function Events.UnitKilledLifespanExpired.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.UnitKilledLifespanExpired.Add(func) end
---*Action*
---@param func function
function Events.UnitKilledLifespanExpired.Remove(func) end

---@overload fun()
Events.StormRemovedFromMap = {}
---*Query*
---@return number amount
function Events.StormRemovedFromMap.Count() end
---*Action*
function Events.StormRemovedFromMap.RemoveAll() end
---*Action*
function Events.StormRemovedFromMap.Dispatch() end
Events.StormRemovedFromMap = {}
---*Query*
---@return number amount
function Events.StormRemovedFromMap.Count() end
---*Action*
function Events.StormRemovedFromMap.RemoveAll() end
---*Action*
function Events.StormRemovedFromMap.Dispatch() end
---*Action*
function Events.StormRemovedFromMap.Call() end
---*Action*
function Events.StormRemovedFromMap.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.StormRemovedFromMap.Add(func) end
---*Action*
---@param func function
function Events.StormRemovedFromMap.Remove(func) end

---@overload fun()
Events.DroughtRemovedFromMap = {}
---*Query*
---@return number amount
function Events.DroughtRemovedFromMap.Count() end
---*Action*
function Events.DroughtRemovedFromMap.RemoveAll() end
---*Action*
function Events.DroughtRemovedFromMap.Dispatch() end
Events.DroughtRemovedFromMap = {}
---*Query*
---@return number amount
function Events.DroughtRemovedFromMap.Count() end
---*Action*
function Events.DroughtRemovedFromMap.RemoveAll() end
---*Action*
function Events.DroughtRemovedFromMap.Dispatch() end
---*Action*
function Events.DroughtRemovedFromMap.Call() end
---*Action*
function Events.DroughtRemovedFromMap.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.DroughtRemovedFromMap.Add(func) end
---*Action*
---@param func function
function Events.DroughtRemovedFromMap.Remove(func) end

---@overload fun()
Events.MonopolyLost = {}
---*Query*
---@return number amount
function Events.MonopolyLost.Count() end
---*Action*
function Events.MonopolyLost.RemoveAll() end
---*Action*
function Events.MonopolyLost.Dispatch() end
Events.MonopolyLost = {}
---*Query*
---@return number amount
function Events.MonopolyLost.Count() end
---*Action*
function Events.MonopolyLost.RemoveAll() end
---*Action*
function Events.MonopolyLost.Dispatch() end
---*Action*
function Events.MonopolyLost.Call() end
---*Action*
function Events.MonopolyLost.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.MonopolyLost.Add(func) end
---*Action*
---@param func function
function Events.MonopolyLost.Remove(func) end

---@overload fun()
Events.GameCoreProcessingComplete = {}
---*Query*
---@return number amount
function Events.GameCoreProcessingComplete.Count() end
---*Action*
function Events.GameCoreProcessingComplete.RemoveAll() end
---*Action*
function Events.GameCoreProcessingComplete.Dispatch() end
Events.GameCoreProcessingComplete = {}
---*Query*
---@return number amount
function Events.GameCoreProcessingComplete.Count() end
---*Action*
function Events.GameCoreProcessingComplete.RemoveAll() end
---*Action*
function Events.GameCoreProcessingComplete.Dispatch() end
---*Action*
function Events.GameCoreProcessingComplete.Call() end
---*Action*
function Events.GameCoreProcessingComplete.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.GameCoreProcessingComplete.Add(func) end
---*Action*
---@param func function
function Events.GameCoreProcessingComplete.Remove(func) end

---@overload fun()
Events.DemoExit = {}
---*Query*
---@return number amount
function Events.DemoExit.Count() end
---*Action*
function Events.DemoExit.RemoveAll() end
---*Action*
function Events.DemoExit.Dispatch() end
Events.DemoExit = {}
---*Query*
---@return number amount
function Events.DemoExit.Count() end
---*Action*
function Events.DemoExit.RemoveAll() end
---*Action*
function Events.DemoExit.Dispatch() end
---*Action*
function Events.DemoExit.Call() end
---*Action*
function Events.DemoExit.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.DemoExit.Add(func) end
---*Action*
---@param func function
function Events.DemoExit.Remove(func) end

---@overload fun()
Events.AppInitComplete = {}
---*Query*
---@return number amount
function Events.AppInitComplete.Count() end
---*Action*
function Events.AppInitComplete.RemoveAll() end
---*Action*
function Events.AppInitComplete.Dispatch() end
Events.AppInitComplete = {}
---*Query*
---@return number amount
function Events.AppInitComplete.Count() end
---*Action*
function Events.AppInitComplete.RemoveAll() end
---*Action*
function Events.AppInitComplete.Dispatch() end
---*Action*
function Events.AppInitComplete.Call() end
---*Action*
function Events.AppInitComplete.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.AppInitComplete.Add(func) end
---*Action*
---@param func function
function Events.AppInitComplete.Remove(func) end

---@overload fun()
Events.LensUnFocusCity = {}
---*Query*
---@return number amount
function Events.LensUnFocusCity.Count() end
---*Action*
function Events.LensUnFocusCity.RemoveAll() end
---*Action*
function Events.LensUnFocusCity.Dispatch() end
Events.LensUnFocusCity = {}
---*Query*
---@return number amount
function Events.LensUnFocusCity.Count() end
---*Action*
function Events.LensUnFocusCity.RemoveAll() end
---*Action*
function Events.LensUnFocusCity.Dispatch() end
---*Action*
function Events.LensUnFocusCity.Call() end
---*Action*
function Events.LensUnFocusCity.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.LensUnFocusCity.Add(func) end
---*Action*
---@param func function
function Events.LensUnFocusCity.Remove(func) end

---@overload fun()
Events.GameConfigurationResolved = {}
---*Query*
---@return number amount
function Events.GameConfigurationResolved.Count() end
---*Action*
function Events.GameConfigurationResolved.RemoveAll() end
---*Action*
function Events.GameConfigurationResolved.Dispatch() end
Events.GameConfigurationResolved = {}
---*Query*
---@return number amount
function Events.GameConfigurationResolved.Count() end
---*Action*
function Events.GameConfigurationResolved.RemoveAll() end
---*Action*
function Events.GameConfigurationResolved.Dispatch() end
---*Action*
function Events.GameConfigurationResolved.Call() end
---*Action*
function Events.GameConfigurationResolved.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.GameConfigurationResolved.Add(func) end
---*Action*
---@param func function
function Events.GameConfigurationResolved.Remove(func) end

---@overload fun()
Events.NaturalWonderRevealedNarrative = {}
---*Query*
---@return number amount
function Events.NaturalWonderRevealedNarrative.Count() end
---*Action*
function Events.NaturalWonderRevealedNarrative.RemoveAll() end
---*Action*
function Events.NaturalWonderRevealedNarrative.Dispatch() end
Events.NaturalWonderRevealedNarrative = {}
---*Query*
---@return number amount
function Events.NaturalWonderRevealedNarrative.Count() end
---*Action*
function Events.NaturalWonderRevealedNarrative.RemoveAll() end
---*Action*
function Events.NaturalWonderRevealedNarrative.Dispatch() end
---*Action*
function Events.NaturalWonderRevealedNarrative.Call() end
---*Action*
function Events.NaturalWonderRevealedNarrative.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.NaturalWonderRevealedNarrative.Add(func) end
---*Action*
---@param func function
function Events.NaturalWonderRevealedNarrative.Remove(func) end

---@overload fun()
Events.CloudGameJoinResponse = {}
---*Query*
---@return number amount
function Events.CloudGameJoinResponse.Count() end
---*Action*
function Events.CloudGameJoinResponse.RemoveAll() end
---*Action*
function Events.CloudGameJoinResponse.Dispatch() end
Events.CloudGameJoinResponse = {}
---*Query*
---@return number amount
function Events.CloudGameJoinResponse.Count() end
---*Action*
function Events.CloudGameJoinResponse.RemoveAll() end
---*Action*
function Events.CloudGameJoinResponse.Dispatch() end
---*Action*
function Events.CloudGameJoinResponse.Call() end
---*Action*
function Events.CloudGameJoinResponse.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.CloudGameJoinResponse.Add(func) end
---*Action*
---@param func function
function Events.CloudGameJoinResponse.Remove(func) end

---@overload fun()
Events.SecretSocietyLeft = {}
---*Query*
---@return number amount
function Events.SecretSocietyLeft.Count() end
---*Action*
function Events.SecretSocietyLeft.RemoveAll() end
---*Action*
function Events.SecretSocietyLeft.Dispatch() end
Events.SecretSocietyLeft = {}
---*Query*
---@return number amount
function Events.SecretSocietyLeft.Count() end
---*Action*
function Events.SecretSocietyLeft.RemoveAll() end
---*Action*
function Events.SecretSocietyLeft.Dispatch() end
---*Action*
function Events.SecretSocietyLeft.Call() end
---*Action*
function Events.SecretSocietyLeft.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.SecretSocietyLeft.Add(func) end
---*Action*
---@param func function
function Events.SecretSocietyLeft.Remove(func) end

---@overload fun()
Events.CloudGameListUpdated = {}
---*Query*
---@return number amount
function Events.CloudGameListUpdated.Count() end
---*Action*
function Events.CloudGameListUpdated.RemoveAll() end
---*Action*
function Events.CloudGameListUpdated.Dispatch() end
Events.CloudGameListUpdated = {}
---*Query*
---@return number amount
function Events.CloudGameListUpdated.Count() end
---*Action*
function Events.CloudGameListUpdated.RemoveAll() end
---*Action*
function Events.CloudGameListUpdated.Dispatch() end
---*Action*
function Events.CloudGameListUpdated.Call() end
---*Action*
function Events.CloudGameListUpdated.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.CloudGameListUpdated.Add(func) end
---*Action*
---@param func function
function Events.CloudGameListUpdated.Remove(func) end

---@overload fun()
Events.PostTourismBombNarrative = {}
---*Query*
---@return number amount
function Events.PostTourismBombNarrative.Count() end
---*Action*
function Events.PostTourismBombNarrative.RemoveAll() end
---*Action*
function Events.PostTourismBombNarrative.Dispatch() end
Events.PostTourismBombNarrative = {}
---*Query*
---@return number amount
function Events.PostTourismBombNarrative.Count() end
---*Action*
function Events.PostTourismBombNarrative.RemoveAll() end
---*Action*
function Events.PostTourismBombNarrative.Dispatch() end
---*Action*
function Events.PostTourismBombNarrative.Call() end
---*Action*
function Events.PostTourismBombNarrative.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.PostTourismBombNarrative.Add(func) end
---*Action*
---@param func function
function Events.PostTourismBombNarrative.Remove(func) end

---@overload fun()
Events.UnitEnteredBarbarianCamp = {}
---*Query*
---@return number amount
function Events.UnitEnteredBarbarianCamp.Count() end
---*Action*
function Events.UnitEnteredBarbarianCamp.RemoveAll() end
---*Action*
function Events.UnitEnteredBarbarianCamp.Dispatch() end
Events.UnitEnteredBarbarianCamp = {}
---*Query*
---@return number amount
function Events.UnitEnteredBarbarianCamp.Count() end
---*Action*
function Events.UnitEnteredBarbarianCamp.RemoveAll() end
---*Action*
function Events.UnitEnteredBarbarianCamp.Dispatch() end
---*Action*
function Events.UnitEnteredBarbarianCamp.Call() end
---*Action*
function Events.UnitEnteredBarbarianCamp.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.UnitEnteredBarbarianCamp.Add(func) end
---*Action*
---@param func function
function Events.UnitEnteredBarbarianCamp.Remove(func) end

---@overload fun()
Events.SecretSocietyJoined = {}
---*Query*
---@return number amount
function Events.SecretSocietyJoined.Count() end
---*Action*
function Events.SecretSocietyJoined.RemoveAll() end
---*Action*
function Events.SecretSocietyJoined.Dispatch() end
Events.SecretSocietyJoined = {}
---*Query*
---@return number amount
function Events.SecretSocietyJoined.Count() end
---*Action*
function Events.SecretSocietyJoined.RemoveAll() end
---*Action*
function Events.SecretSocietyJoined.Dispatch() end
---*Action*
function Events.SecretSocietyJoined.Call() end
---*Action*
function Events.SecretSocietyJoined.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.SecretSocietyJoined.Add(func) end
---*Action*
---@param func function
function Events.SecretSocietyJoined.Remove(func) end

---@overload fun()
Events.AllUnitsDeselected = {}
---*Query*
---@return number amount
function Events.AllUnitsDeselected.Count() end
---*Action*
function Events.AllUnitsDeselected.RemoveAll() end
---*Action*
function Events.AllUnitsDeselected.Dispatch() end
Events.AllUnitsDeselected = {}
---*Query*
---@return number amount
function Events.AllUnitsDeselected.Count() end
---*Action*
function Events.AllUnitsDeselected.RemoveAll() end
---*Action*
function Events.AllUnitsDeselected.Dispatch() end
---*Action*
function Events.AllUnitsDeselected.Call() end
---*Action*
function Events.AllUnitsDeselected.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.AllUnitsDeselected.Add(func) end
---*Action*
---@param func function
function Events.AllUnitsDeselected.Remove(func) end

---@overload fun()
Events.DistrictSelectionChanged = {}
---*Query*
---@return number amount
function Events.DistrictSelectionChanged.Count() end
---*Action*
function Events.DistrictSelectionChanged.RemoveAll() end
---*Action*
function Events.DistrictSelectionChanged.Dispatch() end
Events.DistrictSelectionChanged = {}
---*Query*
---@return number amount
function Events.DistrictSelectionChanged.Count() end
---*Action*
function Events.DistrictSelectionChanged.RemoveAll() end
---*Action*
function Events.DistrictSelectionChanged.Dispatch() end
---*Action*
function Events.DistrictSelectionChanged.Call() end
---*Action*
function Events.DistrictSelectionChanged.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.DistrictSelectionChanged.Add(func) end
---*Action*
---@param func function
function Events.DistrictSelectionChanged.Remove(func) end

---@overload fun()
Events.AfterGameplayContentChange = {}
---*Query*
---@return number amount
function Events.AfterGameplayContentChange.Count() end
---*Action*
function Events.AfterGameplayContentChange.RemoveAll() end
---*Action*
function Events.AfterGameplayContentChange.Dispatch() end
Events.AfterGameplayContentChange = {}
---*Query*
---@return number amount
function Events.AfterGameplayContentChange.Count() end
---*Action*
function Events.AfterGameplayContentChange.RemoveAll() end
---*Action*
function Events.AfterGameplayContentChange.Dispatch() end
---*Action*
function Events.AfterGameplayContentChange.Call() end
---*Action*
function Events.AfterGameplayContentChange.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.AfterGameplayContentChange.Add(func) end
---*Action*
---@param func function
function Events.AfterGameplayContentChange.Remove(func) end

---@overload fun()
Events.LensFocusHex = {}
---*Query*
---@return number amount
function Events.LensFocusHex.Count() end
---*Action*
function Events.LensFocusHex.RemoveAll() end
---*Action*
function Events.LensFocusHex.Dispatch() end
Events.LensFocusHex = {}
---*Query*
---@return number amount
function Events.LensFocusHex.Count() end
---*Action*
function Events.LensFocusHex.RemoveAll() end
---*Action*
function Events.LensFocusHex.Dispatch() end
---*Action*
function Events.LensFocusHex.Call() end
---*Action*
function Events.LensFocusHex.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.LensFocusHex.Add(func) end
---*Action*
---@param func function
function Events.LensFocusHex.Remove(func) end

---@overload fun()
Events.BeginGameView = {}
---*Query*
---@return number amount
function Events.BeginGameView.Count() end
---*Action*
function Events.BeginGameView.RemoveAll() end
---*Action*
function Events.BeginGameView.Dispatch() end
Events.BeginGameView = {}
---*Query*
---@return number amount
function Events.BeginGameView.Count() end
---*Action*
function Events.BeginGameView.RemoveAll() end
---*Action*
function Events.BeginGameView.Dispatch() end
---*Action*
function Events.BeginGameView.Call() end
---*Action*
function Events.BeginGameView.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.BeginGameView.Add(func) end
---*Action*
---@param func function
function Events.BeginGameView.Remove(func) end

---@overload fun()
Events.SubscriptionDownloadStatus = {}
---*Query*
---@return number amount
function Events.SubscriptionDownloadStatus.Count() end
---*Action*
function Events.SubscriptionDownloadStatus.RemoveAll() end
---*Action*
function Events.SubscriptionDownloadStatus.Dispatch() end
Events.SubscriptionDownloadStatus = {}
---*Query*
---@return number amount
function Events.SubscriptionDownloadStatus.Count() end
---*Action*
function Events.SubscriptionDownloadStatus.RemoveAll() end
---*Action*
function Events.SubscriptionDownloadStatus.Dispatch() end
---*Action*
function Events.SubscriptionDownloadStatus.Call() end
---*Action*
function Events.SubscriptionDownloadStatus.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.SubscriptionDownloadStatus.Add(func) end
---*Action*
---@param func function
function Events.SubscriptionDownloadStatus.Remove(func) end

---@overload fun()
Events.AfterGameplayContentConfigure = {}
---*Query*
---@return number amount
function Events.AfterGameplayContentConfigure.Count() end
---*Action*
function Events.AfterGameplayContentConfigure.RemoveAll() end
---*Action*
function Events.AfterGameplayContentConfigure.Dispatch() end
Events.AfterGameplayContentConfigure = {}
---*Query*
---@return number amount
function Events.AfterGameplayContentConfigure.Count() end
---*Action*
function Events.AfterGameplayContentConfigure.RemoveAll() end
---*Action*
function Events.AfterGameplayContentConfigure.Dispatch() end
---*Action*
function Events.AfterGameplayContentConfigure.Call() end
---*Action*
function Events.AfterGameplayContentConfigure.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.AfterGameplayContentConfigure.Add(func) end
---*Action*
---@param func function
function Events.AfterGameplayContentConfigure.Remove(func) end

---@overload fun()
Events.WorldCongressStage3 = {}
---*Query*
---@return number amount
function Events.WorldCongressStage3.Count() end
---*Action*
function Events.WorldCongressStage3.RemoveAll() end
---*Action*
function Events.WorldCongressStage3.Dispatch() end
Events.WorldCongressStage3 = {}
---*Query*
---@return number amount
function Events.WorldCongressStage3.Count() end
---*Action*
function Events.WorldCongressStage3.RemoveAll() end
---*Action*
function Events.WorldCongressStage3.Dispatch() end
---*Action*
function Events.WorldCongressStage3.Call() end
---*Action*
function Events.WorldCongressStage3.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.WorldCongressStage3.Add(func) end
---*Action*
---@param func function
function Events.WorldCongressStage3.Remove(func) end

---@overload fun()
Events.ClimateChangeEvent = {}
---*Query*
---@return number amount
function Events.ClimateChangeEvent.Count() end
---*Action*
function Events.ClimateChangeEvent.RemoveAll() end
---*Action*
function Events.ClimateChangeEvent.Dispatch() end
Events.ClimateChangeEvent = {}
---*Query*
---@return number amount
function Events.ClimateChangeEvent.Count() end
---*Action*
function Events.ClimateChangeEvent.RemoveAll() end
---*Action*
function Events.ClimateChangeEvent.Dispatch() end
---*Action*
function Events.ClimateChangeEvent.Call() end
---*Action*
function Events.ClimateChangeEvent.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.ClimateChangeEvent.Add(func) end
---*Action*
---@param func function
function Events.ClimateChangeEvent.Remove(func) end

---@overload fun()
Events.EndGameView = {}
---*Query*
---@return number amount
function Events.EndGameView.Count() end
---*Action*
function Events.EndGameView.RemoveAll() end
---*Action*
function Events.EndGameView.Dispatch() end
Events.EndGameView = {}
---*Query*
---@return number amount
function Events.EndGameView.Count() end
---*Action*
function Events.EndGameView.RemoveAll() end
---*Action*
function Events.EndGameView.Dispatch() end
---*Action*
function Events.EndGameView.Call() end
---*Action*
function Events.EndGameView.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.EndGameView.Add(func) end
---*Action*
---@param func function
function Events.EndGameView.Remove(func) end

---@overload fun()
Events.WonderCompletedNarrative = {}
---*Query*
---@return number amount
function Events.WonderCompletedNarrative.Count() end
---*Action*
function Events.WonderCompletedNarrative.RemoveAll() end
---*Action*
function Events.WonderCompletedNarrative.Dispatch() end
Events.WonderCompletedNarrative = {}
---*Query*
---@return number amount
function Events.WonderCompletedNarrative.Count() end
---*Action*
function Events.WonderCompletedNarrative.RemoveAll() end
---*Action*
function Events.WonderCompletedNarrative.Dispatch() end
---*Action*
function Events.WonderCompletedNarrative.Call() end
---*Action*
function Events.WonderCompletedNarrative.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.WonderCompletedNarrative.Add(func) end
---*Action*
---@param func function
function Events.WonderCompletedNarrative.Remove(func) end

---@overload fun()
Events.LensUnFocusHex = {}
---*Query*
---@return number amount
function Events.LensUnFocusHex.Count() end
---*Action*
function Events.LensUnFocusHex.RemoveAll() end
---*Action*
function Events.LensUnFocusHex.Dispatch() end
Events.LensUnFocusHex = {}
---*Query*
---@return number amount
function Events.LensUnFocusHex.Count() end
---*Action*
function Events.LensUnFocusHex.RemoveAll() end
---*Action*
function Events.LensUnFocusHex.Dispatch() end
---*Action*
function Events.LensUnFocusHex.Call() end
---*Action*
function Events.LensUnFocusHex.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.LensUnFocusHex.Add(func) end
---*Action*
---@param func function
function Events.LensUnFocusHex.Remove(func) end

---@overload fun()
Events.GenericObjectSimActionTrigger = {}
---*Query*
---@return number amount
function Events.GenericObjectSimActionTrigger.Count() end
---*Action*
function Events.GenericObjectSimActionTrigger.RemoveAll() end
---*Action*
function Events.GenericObjectSimActionTrigger.Dispatch() end
Events.GenericObjectSimActionTrigger = {}
---*Query*
---@return number amount
function Events.GenericObjectSimActionTrigger.Count() end
---*Action*
function Events.GenericObjectSimActionTrigger.RemoveAll() end
---*Action*
function Events.GenericObjectSimActionTrigger.Dispatch() end
---*Action*
function Events.GenericObjectSimActionTrigger.Call() end
---*Action*
function Events.GenericObjectSimActionTrigger.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.GenericObjectSimActionTrigger.Add(func) end
---*Action*
---@param func function
function Events.GenericObjectSimActionTrigger.Remove(func) end

---@overload fun()
Events.LoadingBarUpdate = {}
---*Query*
---@return number amount
function Events.LoadingBarUpdate.Count() end
---*Action*
function Events.LoadingBarUpdate.RemoveAll() end
---*Action*
function Events.LoadingBarUpdate.Dispatch() end
Events.LoadingBarUpdate = {}
---*Query*
---@return number amount
function Events.LoadingBarUpdate.Count() end
---*Action*
function Events.LoadingBarUpdate.RemoveAll() end
---*Action*
function Events.LoadingBarUpdate.Dispatch() end
---*Action*
function Events.LoadingBarUpdate.Call() end
---*Action*
function Events.LoadingBarUpdate.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.LoadingBarUpdate.Add(func) end
---*Action*
---@param func function
function Events.LoadingBarUpdate.Remove(func) end

---@overload fun()
Events.BeginMy2KLinkAccountProcess = {}
---*Query*
---@return number amount
function Events.BeginMy2KLinkAccountProcess.Count() end
---*Action*
function Events.BeginMy2KLinkAccountProcess.RemoveAll() end
---*Action*
function Events.BeginMy2KLinkAccountProcess.Dispatch() end
Events.BeginMy2KLinkAccountProcess = {}
---*Query*
---@return number amount
function Events.BeginMy2KLinkAccountProcess.Count() end
---*Action*
function Events.BeginMy2KLinkAccountProcess.RemoveAll() end
---*Action*
function Events.BeginMy2KLinkAccountProcess.Dispatch() end
---*Action*
function Events.BeginMy2KLinkAccountProcess.Call() end
---*Action*
function Events.BeginMy2KLinkAccountProcess.CallImmediate() end
---*Action*
---@param func fun()
---@return fun()
function Events.BeginMy2KLinkAccountProcess.Add(func) end
---*Action*
---@param func function
function Events.BeginMy2KLinkAccountProcess.Remove(func) end
