---@meta


---**Contexts:** Gameplay, UI
Territories = {}
---**Contexts:** Gameplay, UI
---
---*Query*
---@param plotID number 
---@return Territory Territory 
function Territories.GetTerritoryAt(plotID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return table territories 
function Territories.Members() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Territories.MembersAux() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param territoryID number 
---@return Territory Territory 
function Territories.GetTerritory(territoryID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number amount 
function Territories.GetCount() end