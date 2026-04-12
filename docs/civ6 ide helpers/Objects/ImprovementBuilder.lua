---@meta


---**Contexts:** Gameplay
ImprovementBuilder = {}
---**Contexts:** Gameplay
---
---*Query*
---@param Plot Plot 
---@param improvementIndex number 
---@param teamID number 
---@return boolean  
function ImprovementBuilder.CanHaveImprovement(Plot, improvementIndex, teamID) end
---**Contexts:** Gameplay
---
---*Action*
---@param Plot Plot 
---@param improvementIndex number 
---@param playerID number 
function ImprovementBuilder.SetImprovementType(Plot, improvementIndex, playerID) end
---**Contexts:** Gameplay
---
---*Action*
---@param Plot Plot 
---@param isPillaged boolean 
function ImprovementBuilder.SetImprovementPillaged(Plot, isPillaged) end