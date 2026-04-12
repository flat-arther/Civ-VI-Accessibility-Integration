---@meta


---**Contexts:** Gameplay, UI
WorldBuilder = {}
---**Contexts:** Gameplay
---
---*Query*
---@return WorldBuilderMapManager WorldBuilderMapManager 
function WorldBuilder.MapManager() end
---**Contexts:** Gameplay
---
---*Query*
---@return WorldBuilderConfigurationManager WorldBuilderConfigurationManager 
function WorldBuilder.ConfigurationManager() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function WorldBuilder.CanUndo() end
---**Contexts:** Gameplay
---
---*Query*
---@return WorldBuilderPlayerManager WorldBuilderPlayerManager 
function WorldBuilder.PlayerManager() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function WorldBuilder.CanRedo() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilder.StartUndoBlock() end
---**Contexts:** Gameplay
---
---*Query*
---@return WorldBuilderModManager WorldBuilderModManager 
function WorldBuilder.ModManager() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilder.SetMod() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilder.Redo() end
---**Contexts:** Gameplay
---
---*Query*
---@return WorldBuilderCityManager WorldBuilderCityManager 
function WorldBuilder.CityManager() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilder.Undo() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function WorldBuilder.GetWBAdvancedMode() end
---**Contexts:** Gameplay
---
---*Query*
---@return string modGUID 
function WorldBuilder.GetID() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilder.ClearVisibilityPreviewPlayer() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilder.SetWBAdvancedMode() end
---**Contexts:** Gameplay
---
---*Query*
---@return boolean  
function WorldBuilder.IsMod() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilder.SetVisibilityPreviewPlayer() end
---**Contexts:** Gameplay
---
---*Action*
---@param modGUID string 
---@return boolean wasSuccess 
function WorldBuilder.SetID(modGUID) end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilder.EndUndoBlock() end
---**Contexts:** Gameplay
---
---*Query*
---@return WorldBuilderUnitManager WorldBuilderUnitManager 
function WorldBuilder.UnitManager() end
---**Contexts:** Gameplay
---
---*Action*
function WorldBuilder.GenerateID() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function WorldBuilder.IsActive() end