---@meta


---**Contexts:** UI
Options = {}
---**Contexts:** UI
---
---*Query*
function Options.GetGraphicsOption() end
---**Contexts:** UI
---
---*Query*
function Options.GetUserOption() end
---**Contexts:** UI
---
---*Query*
function Options.GetDisplayHeight() end
---**Contexts:** UI
---
---*Query*
function Options.GetAvailableDisplayModes() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Options.IsUIUpscaleAllowed() end
---**Contexts:** UI
---
---*Query*
function Options.GetAppOption() end
---**Contexts:** UI
---
---*Action*
function Options.SetGraphicsOption() end
---**Contexts:** UI
---
---*Action*
function Options.SaveOptions() end
---**Contexts:** UI
---
---*Query*
function Options.GetAudioOption() end
---**Contexts:** UI
---
---*Query*
function Options.GetGraphicsDefault() end
---**Contexts:** UI
---
---*Action*
function Options.ResetOptions() end
---**Contexts:** UI
---
---*Action*
function Options.SetUserOption() end
---**Contexts:** UI
---
---*Action*
function Options.RevertOptions() end
---**Contexts:** UI
---
---*Action*
function Options.RevertResolutionChanges() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Options.IsMultiNodeGPU() end
---**Contexts:** UI
---
---*Action*
function Options.SetAppOption() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Options.IsAppInMainMenuState() end
---**Contexts:** UI
---
---*Action*
function Options.ApplyGraphicsOptions() end
---**Contexts:** UI
---
---*Action*
function Options.SetAudioOption() end
---**Contexts:** UI
---
---*Query*
function Options.GetDisplayWidth() end
---**Contexts:** UI
---
---*Query*
function Options.GetAvailableDisplayAdapters() end