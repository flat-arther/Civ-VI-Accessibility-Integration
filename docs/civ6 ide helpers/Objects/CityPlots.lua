---@meta


---**Contexts:** Gameplay, UI
---@class CityPlots
local CityPlots = {}
---@type table<userdata, table>
CityPlots.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
CityPlots.TypeName = "CityPlots"
---**Contexts:** Gameplay
---
---*Query*
function CityPlots.GetPurchasedByCity() end
---**Contexts:** Gameplay, UI
---
---*Query*
function CityPlots.GetPurchasedByCityID() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param City City 
---@return Plot[] plots Every plot owned by a city
function CityPlots.GetPurchasedPlots(City) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param City City 
---@return Plot[] plots Every visible plot owned by a city
function CityPlots.GetVisiblePurchasedPlots(City) end
---**Contexts:** Gameplay, UI
---
---*Query*
function CityPlots.GetWorkingCity() end
---**Contexts:** Gameplay, UI
---
---*Query*
function CityPlots.GetWorkingCityID() end

z_dontRef_types.CityPlots = CityPlots