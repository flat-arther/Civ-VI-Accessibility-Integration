---@meta


---**Contexts:** Gameplay, UI
GameRandomEvents = {}
---**Contexts:** Gameplay, UI
---
---*Query*
---@return table cities 
function GameRandomEvents.GetCurrentAffectedCities() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return {PopLost: number, UnitsLost: number, TilesDamaged: number, FertilityAdded: number} eventResults 
function GameRandomEvents.GetCurrentTurnEvent() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param plotID number 
---@return {PopLost: number, UnitsLost: number, TilesDamaged: number, FertilityAdded: number} eventResults 
function GameRandomEvents.GetCurrentTurnEventAtPlot(plotID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param turn number 
---@return table events 
function GameRandomEvents.GetEventsForTurn(turn) end
---**Contexts:** Gameplay
---
---*Action*
---@param eventParameters table 
function GameRandomEvents.ApplyEvent(eventParameters) end