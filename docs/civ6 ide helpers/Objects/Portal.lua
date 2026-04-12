---@meta


---**Contexts:** Gameplay, UI
---@class Portal
local Portal = {}
---@type table<userdata, table>
Portal.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
Portal.TypeName = "Portal"
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number plotID 
function Portal.GetEntrancePlotIndex() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number amount 
function Portal.GetExitCount() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number plotID 
function Portal.GetExitPlotIndex() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Portal.HasEntranceAt() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Portal.HasExitAt() end

z_dontRef_types.Portal = Portal