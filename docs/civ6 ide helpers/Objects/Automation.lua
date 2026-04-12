---@meta


---**Contexts:** Gameplay, UI
Automation = {}
---**Contexts:** Gameplay, UI
---
---*Query*
---@return string saveName 
function Automation.GenerateSaveName() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param paramSet string 
---@param param string 
---@return any value 
function Automation.GetSetParameter(paramSet, param) end
---**Contexts:** Gameplay, UI
---
---*Action*
function Automation.LogDateAndTime() end
---**Contexts:** Gameplay, UI
---
---*Action*
---@param localParam string 
---@param value any 
function Automation.SetLocalParameter(localParam, value) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param localParam string 
---@param unknown any 
---@return any value 
function Automation.GetLocalParameter(localParam, unknown) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number unixTimeStamp 
function Automation.GetTime() end
---**Contexts:** Gameplay, UI
---
---*Action*
---@param inputHandler function 
function Automation.SetInputHandler(inputHandler) end
---**Contexts:** Gameplay, UI
---
---*Action*
---@param isEnabled boolean 
function Automation.SetAutoStartEnabled(isEnabled) end
---**Contexts:** Gameplay, UI
---
---*Action*
---@param inputHandler function 
function Automation.RemoveInputHandler(inputHandler) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Automation.IsAutoStartEnabled() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Automation.IsPaused() end
---**Contexts:** Gameplay, UI
---
---*Action*
---
---Prints a message to Automation.log, there is no known limit on length.
---@param message string 
function Automation.Log(message) end
---**Contexts:** Gameplay, UI
---
---*Action*
---@param paramSet string 
function Automation.ClearParameterSet(paramSet) end
---**Contexts:** Gameplay, UI
---
---*Action*
---@param paramSet string 
---@param param string 
---@param value any 
function Automation.SetSetParameter(paramSet, param, value) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param startupParam string 
---@return any value 
function Automation.GetStartupParameter(startupParam) end
---**Contexts:** Gameplay, UI
---
---*Action*
---@param paramSet string 
---@param params table 
function Automation.SetParameterSet(paramSet, params) end
---**Contexts:** Gameplay, UI
---
---*Query*
function Automation.LogDivider() end
---**Contexts:** Gameplay, UI
---
---*Action*
function Automation.SendTestComplete() end
---**Contexts:** Gameplay, UI
---
---*Action*
---@param isActive boolean 
function Automation.SetActive(isActive) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param roof number 
---@return number randInt 
function Automation.GetRandomNumber(roof) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Automation.IsActive() end
---**Contexts:** Gameplay, UI
---
---*Action*
---@param isPaused boolean 
function Automation.Pause(isPaused) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param paramSet string 
---@return table params 
function Automation.GetParameterSet(paramSet) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return string saveName 
function Automation.GetLastGeneratedSaveName() end