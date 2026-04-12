---@meta


---**Contexts:** Gameplay, UI
MapConfiguration = {}
---**Contexts:** UI
---
---*Query*
---@return string mapSizeType 
function MapConfiguration.GetMapSize() end
---**Contexts:** UI
---
---*Query*
---@return number amount 
function MapConfiguration.GetMaxMajorPlayers() end
---**Contexts:** UI
---
---*Query*
---@return number amount 
function MapConfiguration.GetMaxMinorPlayers() end
---**Contexts:** UI
---
---*Query*
---@return number amount 
function MapConfiguration.GetMinMajorPlayers() end
---**Contexts:** UI
---
---*Query*
---@return number amount 
function MapConfiguration.GetMinMinorPlayers() end
---**Contexts:** UI
---
---*Query*
---@return string filename 
function MapConfiguration.GetScript() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param configKey string 
---@return any value 
function MapConfiguration.GetValue(configKey) end
---**Contexts:** UI
---
---*Action*
---@param mapSizeType string 
function MapConfiguration.SetMapSize(mapSizeType) end
---**Contexts:** UI
---
---*Action*
---@param amount number 
function MapConfiguration.SetMaxMajorPlayers(amount) end
---**Contexts:** UI
---
---*Action*
---@param amount number 
function MapConfiguration.SetMaxMinorPlayers(amount) end
---**Contexts:** UI
---
---*Action*
---@param amount number 
function MapConfiguration.SetMinMajorPlayers(amount) end
---**Contexts:** UI
---
---*Action*
---@param amount number 
function MapConfiguration.SetMinMinorPlayers(amount) end
---**Contexts:** UI
---
---*Action*
---@param filename string 
function MapConfiguration.SetScript(filename) end
---**Contexts:** UI
---
---*Action*
---@param configKey string 
---@param value any 
function MapConfiguration.SetValue(configKey, value) end