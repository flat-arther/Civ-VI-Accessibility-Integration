---@meta


---**Contexts:** Gameplay, UI
TerrainManager = {}
---**Contexts:** Gameplay, UI
---
---*Query*
function TerrainManager.GetCoastalLowlandType() end
---**Contexts:** Gameplay, UI
---
---*Query*
function TerrainManager.IsFlooded() end
---**Contexts:** Gameplay, UI
---
---*Query*
function TerrainManager.IsSubmerged() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param Plot Plot 
---@return boolean  
function TerrainManager.IsProtected(Plot) end
---**Contexts:** Gameplay
---
---*Action*
function TerrainManager.ClearCoastalFlooding() end
---**Contexts:** Gameplay
---
---*Action*
function TerrainManager.SubmergeCoast() end
---**Contexts:** Gameplay
---
---*Action*
function TerrainManager.FloodCoast() end