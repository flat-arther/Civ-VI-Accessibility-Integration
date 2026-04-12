---@meta


---**Contexts:** Gameplay, UI
---@class PlayerUnits
local PlayerUnits = {}
---@type table<userdata, table>
PlayerUnits.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
PlayerUnits.TypeName = "PlayerUnits"
---**Contexts:** Gameplay
---
---*Action*
---@param unitID number 
---@param x number 
---@param y number 
function PlayerUnits:Create(unitID, x, y) end
---**Contexts:** Gameplay
---
---*Action*
function PlayerUnits:Destroy() end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerUnits:FindID() end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerUnits:GetCount() end
---**Contexts:** UI
---
---*Query*
function PlayerUnits:GetFirstReadyUnit() end
---**Contexts:** UI
---
---*Query*
function PlayerUnits:GetNextExtractingArchaeologist() end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerUnits:Members() end
---**Contexts:** Gameplay
---
---*Action*
function PlayerUnits:SetBuildDisabled() end
---**Contexts:** Gameplay
---
---*Action*
function PlayerUnits:RecomputeAllCosts() end
---**Contexts:** Gameplay
---
---*Action*
function PlayerUnits:RecomputeCost() end
---**Contexts:** UI
---
---*Query*
---@return {NeedsAttention: number, Total: number, Automated: number, CanMove: number} info 
function PlayerUnits:GetProcessingState() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function PlayerUnits:IsBuildDisabled() end

z_dontRef_types.PlayerUnits = PlayerUnits