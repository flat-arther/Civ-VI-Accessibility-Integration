---@meta


---**Contexts:** Gameplay, UI
---@class Notification
local Notification = {}
---@type table<userdata, table>
Notification.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
Notification.TypeName = "Notification"
---**Contexts:** Gameplay, UI
---
---*Query*
function Notification:GetTarget() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Notification:GetType() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Notification:IsVisibleInUI() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Notification:GetAddedTurn() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Notification:IsExpired() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Notification:GetPlayerID() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Notification:IsDismissed() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Notification:GetSummary() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Notification:IsTargetValid() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Notification:GetMessage() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Notification:GetLocation() end
---**Contexts:** Gameplay, UI
---
---*Action*
function Notification:Activate() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Notification:IsIconDisplayable() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Notification:GetValue() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Notification:IsAutoNotify() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Notification:IsNeeded() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Notification:GetCount() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Notification:CanUserDismiss() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Notification:GetTypeName() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Notification:IsValidForPhase() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Notification:GetGroup() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Notification:GetEndTurnBlocking() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Notification:GetSeverity() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Notification:AutoExpires() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Notification:GetExpireTurn() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Notification:GetIconName() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Notification:GetID() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Notification:IsLocationValid() end

z_dontRef_types.Notification = Notification