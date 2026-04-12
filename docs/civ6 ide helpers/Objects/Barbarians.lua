---@meta


---**Contexts:** Gameplay, UI
---@class Barbarians
local Barbarians = {}
---@type table<userdata, table>
Barbarians.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
Barbarians.TypeName = "Barbarians"
---**Contexts:** Gameplay
---
---*Action*
---@param tribeID number 
---@param plotID number 
function Barbarians:CreateTribeOfType(tribeID, plotID) end
---**Contexts:** Gameplay
---
---*Action*
---@param tribeID number 
---@param unitPromotionClassType string 
---@param amount number 
---@param plotID number 
---@param withinHexDistance number 
function Barbarians:CreateTribeUnits(tribeID, unitPromotionClassType, amount, plotID, withinHexDistance) end
---**Contexts:** Gameplay
---
---*Action*
---@param tribeID number 
---@param behaviorTrees_TreeName string 
---@param targetPlayerID number 
---@param targetCityID number 
function Barbarians:StartOperationWithCityTarget(tribeID, behaviorTrees_TreeName, targetPlayerID, targetCityID) end
---**Contexts:** Gameplay
---
---*Action*
function Barbarians:CreateSpecificTribe() end
---**Contexts:** UI
---
---*Query*
---@return number cost 
function Barbarians:GetTribeInciteCost() end
---**Contexts:** UI
---
---*Query*
function Barbarians:GetTribeInciteTargets() end
---**Contexts:** UI
---
---*Query*
function Barbarians:GetTribeConversionPoints() end
---**Contexts:** UI
---
---*Query*
function Barbarians:GetTribeBribeTurnsRemaining() end
---**Contexts:** UI
---
---*Query*
function Barbarians:GetTribeInciteTargetPlayer() end
---**Contexts:** UI
---
---*Query*
function Barbarians:GetTribeConversionPercent() end
---**Contexts:** UI
---
---*Query*
function Barbarians:GetTribeIndexAtLocation() end
---**Contexts:** UI
---
---*Query*
function Barbarians:GetTribeType() end
---**Contexts:** UI
---
---*Query*
function Barbarians:GetTribeNameType() end
---**Contexts:** UI
---
---*Query*
function Barbarians:GetTribeRansomUnit() end
---**Contexts:** UI
---
---*Query*
function Barbarians:GetTribeConversionPointsRequired() end
---**Contexts:** UI
---
---*Query*
function Barbarians:GetTribeConversionDisabledHelp() end
---**Contexts:** UI
---
---*Query*
function Barbarians:GetTribeCampLocation() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Barbarians:IsClanExcludeUnitType() end
---**Contexts:** UI
---
---*Query*
---@param tribeID number 
---@return number playerID 
function Barbarians:GetTribeInciteSourcePlayer(tribeID) end

z_dontRef_types.Barbarians = Barbarians