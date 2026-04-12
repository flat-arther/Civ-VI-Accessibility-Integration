---@meta


---**Contexts:** UI
TTManager = {}
---**Contexts:** UI
---
---*Query*
---@return boolean  
function TTManager:IsGamepadToolTipOn() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function TTManager:IsTooltipShowing() end
---**Contexts:** UI
---
---*Query*
---@return number seconds 
function TTManager:GetToolTipDelay() end
---**Contexts:** UI
---
---*Action*
---@param callbackFunc function 
function TTManager:AddToolTipDisplayCallback(callbackFunc) end
---**Contexts:** UI
---
---*Action*
function TTManager:ClearCurrent() end
---**Contexts:** UI
---
---*Action*
---@param tooltipName string 
---@param controlTable table 
function TTManager:GetTypeControlTable(tooltipName, controlTable) end
---**Contexts:** UI
---
---*Action*
---@param callbackFunc function 
function TTManager:RemoveToolTipDisplayCallback(callbackFunc) end
---**Contexts:** UI
---
---*Action*
---@param isOn boolean 
function TTManager:SetGamepadToolTipOn(isOn) end
---**Contexts:** UI
---
---*Action*
---@param seconds number 
function TTManager:SetToolTipDelay(seconds) end
---**Contexts:** UI
---
---*Action*
function TTManager:SetToolTipString() end
---**Contexts:** UI
---
---*Action*
function TTManager:SetToolTipType() end