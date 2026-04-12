---@meta


---**Contexts:** UI
---@class Trade
local Trade = {}
---@type table<userdata, table>
Trade.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
Trade.TypeName = "Trade"
---**Contexts:** UI
---
---*Query*
---@return table routes 
function Trade:GetIncomingRoutes() end
---**Contexts:** UI
---
---*Query*
---@return table routes 
function Trade:GetOutgoingRoutes() end
---**Contexts:** UI
---
---*Query*
---@param Player Player 
---@return boolean  
function Trade:HasActiveTradingPost(Player) end
---**Contexts:** UI
---
---*Query*
---@param Player Player 
---@return boolean  
function Trade:HasInactiveTradingPost(Player) end
---**Contexts:** UI
---
---*Query*
---@return City City 
function Trade:GetCity() end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@return boolean  
function Trade:HasTradeRouteFrom(playerID) end

z_dontRef_types.Trade = Trade