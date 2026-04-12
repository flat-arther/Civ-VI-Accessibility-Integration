---@meta


---**Contexts:** Gameplay
---@class AiDiplomacy
local AiDiplomacy = {}
---@type table<userdata, table>
AiDiplomacy.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
AiDiplomacy.TypeName = "AiDiplomacy"
---**Contexts:** Gameplay
---
---*Action*
function AiDiplomacy:AdjustBaseDiplomacy() end
---**Contexts:** UI
---
---*Query*
function AiDiplomacy:GetDiplomaticModifiers() end
---**Contexts:** UI
---
---*Query*
function AiDiplomacy:GetDiplomaticScore() end
---**Contexts:** Gameplay
---
---*Query*
function AiDiplomacy:GetDiplomaticState() end
---**Contexts:** Gameplay
---
---*Query*
function AiDiplomacy:GetTradeWithHuman() end
---**Contexts:** Gameplay
---
---*Action*
function AiDiplomacy:SetTradeWithHuman() end
---**Contexts:** UI
---
---*Action*
function AiDiplomacy:GetTrustFrom() end
---**Contexts:** UI
---
---*Query*
function AiDiplomacy:GetDiplomaticStateIndex() end
---**Contexts:** UI
---
---*Query*
function AiDiplomacy:GetDealItemDesirabilityString() end
---**Contexts:** UI
---
---*Query*
function AiDiplomacy:GetDealItemDesirability() end
---**Contexts:** UI
---
---*Query*
function AiDiplomacy:GetTrustString() end
---**Contexts:** UI
---
---*Query*
function AiDiplomacy:GetThreatFrom() end
---**Contexts:** UI
---
---*Query*
function AiDiplomacy:GetThreatString() end

z_dontRef_types.AiDiplomacy = AiDiplomacy