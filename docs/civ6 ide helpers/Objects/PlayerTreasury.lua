---@meta


---**Contexts:** Gameplay, UI
---@class PlayerTreasury
local PlayerTreasury = {}
---@type table<userdata, table>
PlayerTreasury.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
PlayerTreasury.TypeName = "PlayerTreasury"
---**Contexts:** UI
---
---*Query*
function PlayerTreasury:CanAfford() end
---**Contexts:** Gameplay
---
---*Action*
function PlayerTreasury:ChangeGoldBalance() end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerTreasury:GetBuildingMaintenance() end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerTreasury:GetDistrictMaintenance() end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerTreasury:GetGoldBalance() end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerTreasury:GetGoldYield() end
---**Contexts:** UI
---
---*Query*
function PlayerTreasury:GetGoldYieldToolTip() end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerTreasury:GetTotalMaintenance() end
---**Contexts:** UI
---
---*Query*
function PlayerTreasury:GetTotalMaintenanceToolTip() end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerTreasury:GetUnitMaintenance() end
---**Contexts:** Gameplay, UI
---
---*Query*
function PlayerTreasury:GetWMDMaintenance() end
---**Contexts:** Gameplay
---
---*Action*
function PlayerTreasury:SetGoldBalance() end
---**Contexts:** Gameplay
---
---*Action*
function PlayerTreasury:ChangeGoldBalanceByPercentage() end
---**Contexts:** UI
---
---*Query*
function PlayerTreasury:GetMaintDiscountPerUnit() end

z_dontRef_types.PlayerTreasury = PlayerTreasury