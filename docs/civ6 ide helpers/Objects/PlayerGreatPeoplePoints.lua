---@meta


---**Contexts:** Gameplay, UI
---@class PlayerGreatPeoplePoints
local PlayerGreatPeoplePoints = {}
---@type table<userdata, table>
PlayerGreatPeoplePoints.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
PlayerGreatPeoplePoints.TypeName = "PlayerGreatPeoplePoints"
---**Contexts:** Gameplay
---
---*Query*
function PlayerGreatPeoplePoints:CalculatePointsPerTurn() end
---**Contexts:** Gameplay
---
---*Action*
---@param greatPersonClassIndex number 
---@param amount number 
function PlayerGreatPeoplePoints:ChangePointsTotal(greatPersonClassIndex, amount) end
---**Contexts:** UI
---
---*Query*
function PlayerGreatPeoplePoints:GetPointsPerTurn() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param greatPersonClassIndex number 
---@return number amount 
function PlayerGreatPeoplePoints:GetPointsTotal(greatPersonClassIndex) end
---**Contexts:** Gameplay
---
---*Action*
function PlayerGreatPeoplePoints:SetPointsTotal() end
---**Contexts:** UI
---
---*Query*
function PlayerGreatPeoplePoints:IsNoPatronageWith() end

z_dontRef_types.PlayerGreatPeoplePoints = PlayerGreatPeoplePoints