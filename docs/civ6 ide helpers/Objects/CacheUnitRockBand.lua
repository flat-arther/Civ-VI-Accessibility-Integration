---@meta


---**Contexts:** UI
---@class CacheUnitRockBand
local CacheUnitRockBand = {}
---@type table<userdata, table>
CacheUnitRockBand.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
CacheUnitRockBand.TypeName = "CacheUnitRockBand"
---**Contexts:** UI
---
---*Query*
---@return boolean  
function CacheUnitRockBand:IsMaxLevel() end
---**Contexts:** UI
---
---*Query*
function CacheUnitRockBand:GetRockBandLevel() end
---**Contexts:** UI
---
---*Query*
function CacheUnitRockBand:GetAreaHighlightPlots() end
---**Contexts:** UI
---
---*Query*
function CacheUnitRockBand:GetActivationHighlightPlots() end
---**Contexts:** UI
---
---*Query*
function CacheUnitRockBand:GetAlbumSales() end
---**Contexts:** UI
---
---*Query*
---@return Unit Unit 
function CacheUnitRockBand:GetUnit() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function CacheUnitRockBand:IsMaxPromotions() end

z_dontRef_types.CacheUnitRockBand = CacheUnitRockBand