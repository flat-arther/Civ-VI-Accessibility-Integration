---@meta


---**Contexts:** Gameplay, UI
---@class PlayerTechs
local PlayerTechs = {}
---@type table<userdata, table>
PlayerTechs.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
PlayerTechs.TypeName = "PlayerTechs"
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function PlayerTechs:CanResearch() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function PlayerTechs:CanTriggerBoost() end
---**Contexts:** Gameplay
---
---*Action*
function PlayerTechs:ChangeCurrentResearchProgress() end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerTechs:GetResearchCost() end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerTechs:GetResearchingTech() end
---**Contexts:** UI
---
---*Query*
function PlayerTechs:GetResearchPath() end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerTechs:GetResearchProgress() end
---**Contexts:** UI
---
---*Query*
function PlayerTechs:GetResearchQueue() end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerTechs:GetScienceYield() end
---**Contexts:** UI
---
---*Query*
function PlayerTechs:GetScienceYieldToolTip() end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerTechs:GetTurnsLeft() end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerTechs:GetTurnsToResearch() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function PlayerTechs:HasBoostBeenTriggered() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function PlayerTechs:HasTech() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function PlayerTechs:IsResearchingTech() end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerTechs:ResearchQueue() end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerTechs:ResearchQueueAux() end
---**Contexts:** Gameplay
---
---*Action*
function PlayerTechs:ReverseBoost() end
---**Contexts:** Gameplay
---
---*Action*
function PlayerTechs:SetResearchingTech() end
---**Contexts:** Gameplay
---
---*Action*
function PlayerTechs:SetResearchProgress() end
---**Contexts:** Gameplay
---
---*Action*
function PlayerTechs:SetTech() end
---**Contexts:** Gameplay
---
---*Action*
function PlayerTechs:TriggerBoost() end
---**Contexts:** UI
---
---*Action*
---@return boolean  
function PlayerTechs:IsTechRevealed() end

z_dontRef_types.PlayerTechs = PlayerTechs