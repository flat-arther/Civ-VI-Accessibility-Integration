---@meta


---**Contexts:** Gameplay, UI
RiverManager = {}
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function RiverManager.CanBeFlooded() end
---**Contexts:** Gameplay, UI
---
---*Action*
function RiverManager.EnumerateRivers() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param riverID number 
---@return Plot[] plots 
function RiverManager.GetFloodplainPlots(riverID) end
---**Contexts:** Gameplay, UI
---
---*Query*
function RiverManager.GetNumFloodableRivers() end
---**Contexts:** Gameplay, UI
---
---*Query*
function RiverManager.GetNumRivers() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param x number 
---@param y number 
---@return number riverID 
function RiverManager.GetRiverForFloodplain(x, y) end
---**Contexts:** Gameplay, UI
---
---*Query*
function RiverManager.GetRiverName() end
---**Contexts:** Gameplay, UI
---
---*Query*
function RiverManager.GetNumFloods() end
---**Contexts:** Gameplay, UI
---
---*Query*
function RiverManager.GetRiverNameByType() end
---**Contexts:** Gameplay, UI
---
---*Query*
function RiverManager.GetFloodplainLocation() end
---**Contexts:** Gameplay, UI
---
---*Query*
function RiverManager.GetRiverByIndex() end
---**Contexts:** Gameplay, UI
---
---*Query*
function RiverManager.GetRiverIDAtIndex() end
---**Contexts:** Gameplay, UI
---
---*Query*
function RiverManager.GetRiverTypeAtIndex() end
---**Contexts:** Gameplay, UI
---
---*Query*
function RiverManager.GetRiverType() end
---**Contexts:** Gameplay, UI
---
---*Query*
function RiverManager.GetRiverIndexByID() end
---**Contexts:** Gameplay, UI
---
---*Query*
function RiverManager.GetRiverByID() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function RiverManager.IsFlooded() end
---**Contexts:** Gameplay, UI
---
---*Query*
function RiverManager.GetRiverTypes() end