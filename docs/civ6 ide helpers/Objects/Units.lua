---@meta


---**Contexts:** Gameplay, UI
Units = {}
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Units.AreUnitsInPlot() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Units.AreUnitsInPlotLayerID() end
---**Contexts:** UI
---
---*Query*
function Units.GetLayerCount() end
---**Contexts:** UI
---
---*Query*
function Units.GetPlayerUnitsInPlot() end
---**Contexts:** UI
---
---*Query*
function Units.GetPlayerUnitsInPlotLayerID() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Units.GetUnitByIndexInPlot() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number amount 
function Units.GetUnitCountInPlot() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number amount 
function Units.GetUnitCountInPlotLayerID() end
---**Contexts:** UI
---
---*Query*
---@return number amount 
function Units.GetUnitCountInPlotLayerIndex() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param Plot Plot 
---@return Unit[] units 
function Units.GetUnitsInPlot(Plot) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param x number 
---@param y number 
---@param mapLayer MapLayers 
---@return Unit[] units 
function Units.GetUnitsInPlotLayerID(x, y, mapLayer) end
---**Contexts:** UI
---
---*Query*
---@return Unit[] units 
function Units.GetUnitsInPlotLayerIndex() end