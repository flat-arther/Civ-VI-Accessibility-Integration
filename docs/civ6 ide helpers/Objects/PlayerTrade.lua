---@meta


---**Contexts:** Gameplay, UI
---@class PlayerTrade
local PlayerTrade = {}
---@type table<userdata, table>
PlayerTrade.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
PlayerTrade.TypeName = "PlayerTrade"
---**Contexts:** Gameplay
---
---*Query*
function PlayerTrade:CountOutgoingRoutes() end
---**Contexts:** UI
---
---*Query*
function PlayerTrade:GetLandRangeRefuel() end
---**Contexts:** UI
---
---*Query*
function PlayerTrade:GetNumOutgoingRoutes() end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerTrade:GetOutgoingRouteCapacity() end
---**Contexts:** UI
---
---*Query*
function PlayerTrade:GetWaterRangeRefuel() end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerTrade:CalcFavorPerTurnFromTradePartners() end
---**Contexts:** UI
---
---*Query*
function PlayerTrade:GetInternationalYieldModifier() end

z_dontRef_types.PlayerTrade = PlayerTrade