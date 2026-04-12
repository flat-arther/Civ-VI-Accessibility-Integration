---@meta


---**Contexts:** UI
UIManager = {}
---**Contexts:** UI
---
---*Action*
---@param unknown boolean 
function UIManager:DisablePopupQueue(unknown) end
---**Contexts:** UI
---
---*Query*
function UIManager:GetFilePath() end
---**Contexts:** UI
---
---*Action*
function UIManager:SetUICursor() end
---**Contexts:** UI
---
---*Query*
function UIManager:GetControlUnderMouse() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UIManager:IsModal() end
---**Contexts:** UI
---
---*Query*
function UIManager:DequeuePopup() end
---**Contexts:** UI
---
---*Query*
function UIManager:GetLastTimeDelta() end
---**Contexts:** UI
---
---*Query*
function UIManager:ShowDelayedPopups() end
---**Contexts:** UI
---
---*Query*
function UIManager:GetFontFamilyFromStyle() end
---**Contexts:** UI
---
---*Query*
function UIManager:GetHash() end
---**Contexts:** UI
---
---*Query*
function UIManager:PopModal() end
---**Contexts:** UI
---
---*Query*
function UIManager:GetNormalizedMousePos() end
---**Contexts:** UI
---
---*Action*
---
---Prints a message to UserInterface.log, will be truncated if too long.
---@param message string 
function UIManager:Log(message) end
---**Contexts:** UI
---
---*Query*
function UIManager:GetRootContexts() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UIManager:IsPopupQueueDisabled() end
---**Contexts:** UI
---
---*Query*
function UIManager:PushModal() end
---**Contexts:** UI
---
---*Query*
function UIManager:GetMousePos() end
---**Contexts:** UI
---
---*Query*
function UIManager:SetGlobalInputHandler() end
---**Contexts:** UI
---
---*Query*
function UIManager:GetMouseOverControls() end
---**Contexts:** UI
---
---*Action*
function UIManager:QueuePopup() end
---**Contexts:** UI
---
---*Query*
function UIManager:GetModalContexts() end
---**Contexts:** UI
---
---*Query*
function UIManager:GetPopupStack() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UIManager:IsGamepadActive() end
---**Contexts:** UI
---
---*Query*
function UIManager:GetMouseOverWorld() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UIManager:IsInPopupQueue() end
---**Contexts:** UI
---
---*Query*
function UIManager:SetClipboardString() end
---**Contexts:** UI
---
---*Action*
function UIManager:ClearPopupChangeHandler() end
---**Contexts:** UI
---
---*Query*
function UIManager:GetScreenSizeVal() end
---**Contexts:** UI
---
---*Action*
function UIManager:SetPopupChangeHandler() end