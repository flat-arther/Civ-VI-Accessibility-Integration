---@meta


---**Contexts:** Gameplay
---@class Frac
local Frac = {}
---@type table<userdata, table>
Frac.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
Frac.TypeName = "Frac"
---**Contexts:** Gameplay
---
---*Action*
function Frac.BuildRidges() end
---**Contexts:** Gameplay
---
---*Query*
function Frac.GetHeight() end
---**Contexts:** Gameplay
---
---*Action*
function Frac.Destroy() end

z_dontRef_types.Frac = Frac