---@meta


---**Contexts:** Gameplay, UI
---@class TradeManager
local TradeManager = {}
---@type table<userdata, table>
TradeManager.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
TradeManager.TypeName = "TradeManager"
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number yield 
function TradeManager:CalculateDestinationYieldFromAttachingResource() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param originCityPlayerID number 
---@param originCityID number 
---@param toCityPlayerID number 
---@param toCityID number 
---@param yieldIndex number 
---@param resourceIndex number 
---@return number yield 
function TradeManager:CalculateDestinationYieldFromModifiers(originCityPlayerID, originCityID, toCityPlayerID, toCityID, yieldIndex, resourceIndex) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param originCityPlayerID number 
---@param originCityID number 
---@param toCityPlayerID number 
---@param toCityID number 
---@param yieldIndex number 
---@return number yield 
function TradeManager:CalculateDestinationYieldFromPath(originCityPlayerID, originCityID, toCityPlayerID, toCityID, yieldIndex) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param originCityPlayerID number 
---@param originCityID number 
---@param toCityPlayerID number 
---@param toCityID number 
---@param yieldIndex number 
---@return number yield 
function TradeManager:CalculateDestinationYieldFromPotentialRoute(originCityPlayerID, originCityID, toCityPlayerID, toCityID, yieldIndex) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number yield 
function TradeManager:CalculateOriginYieldFromAttachingResource() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param originCityPlayerID number 
---@param originCityID number 
---@param toCityPlayerID number 
---@param toCityID number 
---@param yieldIndex number 
---@return number yield 
function TradeManager:CalculateOriginYieldFromModifiers(originCityPlayerID, originCityID, toCityPlayerID, toCityID, yieldIndex) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param originCityPlayerID number 
---@param originCityID number 
---@param toCityPlayerID number 
---@param toCityID number 
---@param yieldIndex number 
---@return number yield 
function TradeManager:CalculateOriginYieldFromPath(originCityPlayerID, originCityID, toCityPlayerID, toCityID, yieldIndex) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param originCityPlayerID number 
---@param originCityID number 
---@param toCityPlayerID number 
---@param toCityID number 
---@param yieldIndex number 
---@return number yield 
function TradeManager:CalculateOriginYieldFromPotentialRoute(originCityPlayerID, originCityID, toCityPlayerID, toCityID, yieldIndex) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number yield 
function TradeManager:CalculateYieldFromIncomingRoutes() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number yield 
function TradeManager:CalculateYieldFromOutgoingRoutes() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param originCityPlayerID number 
---@param originCityID number 
---@param toCityPlayerID number 
---@param toCityID number 
---@param unknown boolean 
---@return boolean  
function TradeManager:CanStartRoute(originCityPlayerID, originCityID, toCityPlayerID, toCityID, unknown) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function TradeManager:CanStartRouteWithResource() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param originCityPlayerID number 
---@param originCityID number 
---@param toCityPlayerID number 
---@param toCityID number 
---@return table yields 
function TradeManager:CalculateOriginYieldsFromPotentialRoute(originCityPlayerID, originCityID, toCityPlayerID, toCityID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param originCityPlayerID number 
---@param originCityID number 
---@param toCityPlayerID number 
---@param toCityID number 
---@return table yields 
function TradeManager:CalculateDestinationYieldsFromPath(originCityPlayerID, originCityID, toCityPlayerID, toCityID) end
---**Contexts:** Gameplay, UI
---
---*Query*
function TradeManager:CalculateDestinationYieldsFromAttachingResource() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param originCityPlayerID number 
---@param originCityID number 
---@param toCityPlayerID number 
---@param toCityID number 
---@return table yields 
function TradeManager:CalculateOriginYieldsFromModifiers(originCityPlayerID, originCityID, toCityPlayerID, toCityID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param originCityPlayerID number 
---@param originCityID number 
---@param toCityPlayerID number 
---@param toCityID number 
---@return table yields 
function TradeManager:CalculateDestinationYieldsFromPotentialRoute(originCityPlayerID, originCityID, toCityPlayerID, toCityID) end
---**Contexts:** UI
---
---*Query*
---@param originCityPlayerID number 
---@param originCityID number 
---@param toCityPlayerID number 
---@param toCityID number 
---@return Plot[] plots 
---@return table portalEntrances 
---@return table portalExits 
function TradeManager:GetTradeRoutePath(originCityPlayerID, originCityID, toCityPlayerID, toCityID) end
---**Contexts:** Gameplay, UI
---
---*Query*
function TradeManager:CalculateOriginYieldsFromAttachingResource() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param originCityPlayerID number 
---@param originCityID number 
---@param toCityPlayerID number 
---@param toCityID number 
---@return table yields 
function TradeManager:CalculateOriginYieldsFromPath(originCityPlayerID, originCityID, toCityPlayerID, toCityID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param originCityPlayerID number 
---@param originCityID number 
---@param toCityPlayerID number 
---@param toCityID number 
---@return table yields 
function TradeManager:CalculateDestinationYieldsFromModifiers(originCityPlayerID, originCityID, toCityPlayerID, toCityID) end
---**Contexts:** UI
---
---*Query*
---@param originCityPlayerID number 
---@param originCityID number 
---@param toCityPlayerID number 
---@param toCityID number 
---@return number pressure 
function TradeManager:CalculateDestinationReligiousPressureFromPotentialRoute(originCityPlayerID, originCityID, toCityPlayerID, toCityID) end
---**Contexts:** UI
---
---*Query*
---@param originCityPlayerID number 
---@param originCityID number 
---@param toCityPlayerID number 
---@param toCityID number 
---@return boolean  
function TradeManager:IsRouteAllowed(originCityPlayerID, originCityID, toCityPlayerID, toCityID) end
---**Contexts:** UI
---
---*Query*
---@param originCityPlayerID number 
---@param originCityID number 
---@param toCityPlayerID number 
---@param toCityID number 
---@return number pressure 
function TradeManager:CalculateOriginReligiousPressureFromPotentialRoute(originCityPlayerID, originCityID, toCityPlayerID, toCityID) end

z_dontRef_types.TradeManager = TradeManager