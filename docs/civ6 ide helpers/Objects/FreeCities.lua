---@meta


---**Contexts:** Gameplay
---@class FreeCities
local FreeCities = {}
---@type table<userdata, table>
FreeCities.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
FreeCities.TypeName = "FreeCities"
---**Contexts:** Gameplay
---
---*Query*
---@return number freeCityID 
function FreeCities:GetIndex() end
---**Contexts:** Gameplay
---
---*Query*
---@return {x: number, y: number} location 
function FreeCities:GetLocation() end
---**Contexts:** Gameplay
---
---*Query*
---@return number x 
function FreeCities:GetX() end
---**Contexts:** Gameplay
---
---*Query*
---@return number y 
function FreeCities:GetY() end
---**Contexts:** Gameplay
---
---*Query*
---@return Plot Plot 
function FreeCities:GetPlot() end
---**Contexts:** Gameplay
---
---*Query*
---@return number amount 
function FreeCities:GetUrbanDefenses() end

z_dontRef_types.FreeCities = FreeCities