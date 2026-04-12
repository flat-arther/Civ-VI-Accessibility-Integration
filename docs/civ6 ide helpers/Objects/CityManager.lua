---@meta


---**Contexts:** Gameplay, UI
CityManager = {}
---**Contexts:** UI
---
---*Query*
---@param City City 
---@param commandType CityCommandTypes 
---@param operationParameters table 
---@return boolean  
function CityManager.CanStartCommand(City, commandType, operationParameters) end
---**Contexts:** UI
---
---*Query*
---@param City City 
---@param operationType CityOperationTypes 
---@param operationParameters table 
---@return boolean  
function CityManager.CanStartOperation(City, operationType, operationParameters) end
---**Contexts:** Gameplay
---
---*Action*
---@param playerID number 
---@param districtID number 
function CityManager.DestroyCity(playerID, districtID) end
---**Contexts:** Gameplay
---
---*Action*
function CityManager.DestroyDistrict() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param Player Player 
---@param cityID number 
---@return City City 
function CityManager.GetCity(Player, cityID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param x number 
---@param y number 
---@return City City 
function CityManager.GetCityAt(x, y) end
---**Contexts:** UI
---
---*Query*
---@param City City 
---@param commandType CityCommandTypes 
---@param operationParameters table 
---@return table targets 
function CityManager.GetCommandTargets(City, commandType, operationParameters) end
---**Contexts:** Gameplay
---
---*Query*
function CityManager.GetDistrict() end
---**Contexts:** Gameplay, UI
---
---*Query*
function CityManager.GetDistrictAt() end
---**Contexts:** UI
---
---*Query*
---@param City City 
---@param operationType CityOperationTypes 
---@param operationParameters table 
---@return table targets 
function CityManager.GetOperationTargets(City, operationType, operationParameters) end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function CityManager.IsCity() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function CityManager.IsDistrict() end
---**Contexts:** UI
---
---*Action*
---@param City City 
---@param commandType CityCommandTypes 
---@param operationParameters table 
function CityManager.RequestCommand(City, commandType, operationParameters) end
---**Contexts:** UI
---
---*Action*
---@param City City 
---@param operationType CityOperationTypes 
---@param operationParameters table 
function CityManager.RequestOperation(City, operationType, operationParameters) end
---**Contexts:** Gameplay
---
---*Action*
---@param City City 
function CityManager.SetAsCapital(City) end
---**Contexts:** Gameplay
---
---*Action*
---@param City City 
function CityManager.SetAsOriginalCapital(City) end
---**Contexts:** Gameplay
---
---*Action*
---@param City City 
function CityManager.TransferCityToFreeCities(City) end
---**Contexts:** Gameplay
---
---*Action*
---@param City City 
---@param playerID number 
---@param transferType CityTransferTypes 
function CityManager.TransferCity(City, playerID, transferType) end
---**Contexts:** Gameplay
---
---*Query*
---@param x number 
---@param y number 
---@return FreeCities FreeCities 
function CityManager.GetFreeCityAt(x, y) end