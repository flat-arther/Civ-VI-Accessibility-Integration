---@meta


---**Contexts:** Gameplay, UI
DB = {}
---**Contexts:** Gameplay, UI
---
---*Action*
---
---Hashes inputted text the same way the Gameplay DB does
---@param text string 
---@return number hash 
function DB.MakeHash(text) end
---**Contexts:** Gameplay, UI
---
---*Action*
function DB.CollectMemoryUsage() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number amount 
function DB.ConfigurationQueryCount() end
---**Contexts:** Gameplay, UI
---
---*Query*
---
---Query the Gameplay DB, no write permissions so select statements only
---@param SQLQuery string 
---@return table[] resultSet 
function DB.Query(SQLQuery) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number memoryUsage 
function DB.GetMemoryUsage() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number amount 
function DB.QueryCount() end
---**Contexts:** Gameplay, UI
---
---*Action*
---@param unknown integer Might be the Index for SQL queries made in your specific Lua Context
---@return string SQLQuery 
function DB.ConfigurationQuerySQL(unknown) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number amount 
function DB.ConfigurationChanges() end
---**Contexts:** Gameplay, UI
---
---*Action*
---
---Query the Configuration DB, read/write permissions
---@param SQLQuery string 
---@return table[] resultSet 
function DB.ConfigurationQuery(SQLQuery) end
---**Contexts:** Gameplay, UI
---
---*Action*
---@param unknown integer Might be the Index for SQL queries made in your specific Lua Context
---@return string SQLQuery 
function DB.QuerySQL(unknown) end