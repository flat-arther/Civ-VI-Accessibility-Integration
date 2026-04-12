---@meta


---**Contexts:** UI
UITutorialManager = {}
---**Contexts:** UI
---
---*Action*
function UITutorialManager:ShowControlsByID() end
---**Contexts:** UI
---
---*Action*
function UITutorialManager:HideControlsByID() end
---**Contexts:** UI
---
---*Action*
function UITutorialManager:SetActiveAlways() end
---**Contexts:** UI
---
---*Action*
function UITutorialManager:EnableOverlay() end
---**Contexts:** UI
---
---*Query*
function UITutorialManager:GetHash() end
---**Contexts:** UI
---
---*Action*
function UITutorialManager:HideAll() end
---**Contexts:** UI
---
---*Action*
function UITutorialManager:ClearPersistantInputControls() end
---**Contexts:** UI
---
---*Action*
function UITutorialManager:EnableControlsByIdOrTag() end
---**Contexts:** UI
---
---*Query*
function UITutorialManager:IsOverlayEnabled() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UITutorialManager:IsActive() end
---**Contexts:** UI
---
---*Action*
function UITutorialManager:AddControlToAlwaysReceiveInput() end
---**Contexts:** UI
---
---*Action*
function UITutorialManager:RemoveControlToAlwaysReceiveInput() end