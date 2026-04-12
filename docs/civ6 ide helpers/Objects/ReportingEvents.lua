---@meta


---**Contexts:** Gameplay, UI
ReportingEvents = {}
---**Contexts:** Gameplay, UI
---
---*Action*
---@param event string 
---@param params table 
function ReportingEvents.Send(event, params) end
---**Contexts:** Gameplay, UI
---
---*Action*
---@param luaEvent string 
---@param params table 
function ReportingEvents.SendLuaEvent(luaEvent, params) end