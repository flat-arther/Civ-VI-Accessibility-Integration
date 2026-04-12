---@meta


---**Contexts:** Gameplay, UI
---@class PlayerInfluence
local PlayerInfluence = {}
---@type table<userdata, table>
PlayerInfluence.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
PlayerInfluence.TypeName = "PlayerInfluence"
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerInfluence:CanGiveInfluence() end
---**Contexts:** UI
---
---*Query*
function PlayerInfluence:CanGiveTokensToPlayer() end
---**Contexts:** UI
---
---*Query*
function PlayerInfluence:CanLevyMilitary() end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerInfluence:CanReceiveInfluence() end
---**Contexts:** Gameplay
---
---*Action*
function PlayerInfluence:ChangeTokensToGive() end
---**Contexts:** UI
---
---*Query*
function PlayerInfluence:GetLevyMilitaryCost() end
---**Contexts:** UI
---
---*Query*
function PlayerInfluence:GetLevyTurnCounter() end
---**Contexts:** UI
---
---*Query*
function PlayerInfluence:GetLevyTurnLimit() end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerInfluence:GetMostTokensReceived() end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerInfluence:GetPointsEarned() end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerInfluence:GetPointsPerTurn() end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerInfluence:GetPointsThreshold() end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerInfluence:GetSuzerain() end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerInfluence:GetTokensPerThreshold() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param playerID number 
---@return number amount 
function PlayerInfluence:GetTokensReceived(playerID) end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerInfluence:GetTokensToGive() end
---**Contexts:** Gameplay
---
---*Action*
function PlayerInfluence:GiveFreeTokenToPlayer() end
---**Contexts:** UI
---
---*Query*
function PlayerInfluence:IsGivingTokensConsidered() end
---**Contexts:** UI
---
---*Query*
function PlayerInfluence:IsSuzerainUniqueBonusDisabled() end
---**Contexts:** UI
---
---*Action*
function PlayerInfluence:SetGivingTokensConsidered() end

z_dontRef_types.PlayerInfluence = PlayerInfluence