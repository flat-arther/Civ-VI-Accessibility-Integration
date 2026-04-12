---@meta


---**Contexts:** Gameplay, UI
---@class Citizens
local Citizens = {}
---@type table<userdata, table>
Citizens.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
Citizens.TypeName = "Citizens"
---**Contexts:** UI
---
---*Query*
---@param yieldType YieldTypes 
---@return boolean  
function Citizens:IsDisfavoredYield(yieldType) end
---**Contexts:** UI
---
---*Query*
---@param yieldType YieldTypes 
---@return boolean  
function Citizens:IsFavoredYield(yieldType) end
---**Contexts:** UI
---
---*Query*
---@param x number 
---@param y number 
---@return boolean  
function Citizens:IsPlotWorked(x, y) end
---**Contexts:** Gameplay
---
---*Action*
---@param yieldType YieldTypes 
---@param isFavored boolean 
---@return boolean wasSuccess 
function Citizens:SetFavoredYield(yieldType, isFavored) end
---**Contexts:** Gameplay
---
---*Query*
---@return YieldTypes yieldType 
function Citizens:SetDisfavoredYield() end
---**Contexts:** Gameplay
---
---*Query*
---@param yieldType YieldTypes 
function Citizens:IsYieldDisfavored(yieldType) end
---**Contexts:** Gameplay
---
---*Query*
---@param yieldType YieldTypes 
function Citizens:IsYieldFavored(yieldType) end

z_dontRef_types.Citizens = Citizens