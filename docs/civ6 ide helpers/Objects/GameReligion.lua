---@meta


---**Contexts:** Gameplay, UI
---@class GameReligion
local GameReligion = {}
---@type table<userdata, table>
GameReligion.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
GameReligion.TypeName = "GameReligion"
---**Contexts:** Gameplay
---
---*Action*
function GameReligion:AddBelief() end
---**Contexts:** Gameplay
---
---*Action*
---@param playerID number 
---@param beliefID number 
function GameReligion:FoundPantheon(playerID, beliefID) end
---**Contexts:** Gameplay
---
---*Action*
function GameReligion:FoundReligion() end
---**Contexts:** UI
---
---*Query*
function GameReligion:GetName() end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameReligion:GetReligions() end
---**Contexts:** Gameplay
---
---*Action*
function GameReligion:AddBeliefHash() end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameReligion:IsInSomePantheon() end
---**Contexts:** Gameplay
---
---*Action*
function GameReligion:AddBuilding() end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameReligion:IsTooManyForReligion() end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameReligion:HasBeenFounded() end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameReligion:IsInSomeReligion() end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameReligion:HasBeliefEachType() end
---**Contexts:** Gameplay, UI
---
---*Query*
function GameReligion:IsNewTypeForReligion() end
---**Contexts:** Gameplay
---
---*Action*
function GameReligion:FoundPantheonHash() end
---**Contexts:** UI
---
---*Query*
function GameReligion:GetMinimumFaithNextPantheon() end

z_dontRef_types.GameReligion = GameReligion