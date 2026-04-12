---@meta


---**Contexts:** Gameplay, UI
---@class DiplomacyDealItem
local DiplomacyDealItem = {}
---@type table<userdata, table>
DiplomacyDealItem.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
DiplomacyDealItem.TypeName = "DiplomacyDealItem"
---**Contexts:** Gameplay, UI
---
---*Action*
function DiplomacyDealItem:SetToPlayerID() end
---**Contexts:** Gameplay, UI
---
---*Query*
function DiplomacyDealItem:GetEndTurn() end
---**Contexts:** Gameplay, UI
---
---*Action*
function DiplomacyDealItem:SetValueType() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function DiplomacyDealItem:HasPossibleAmounts() end
---**Contexts:** Gameplay, UI
---
---*Query*
function DiplomacyDealItem:GetAmount() end
---**Contexts:** Gameplay, UI
---
---*Action*
function DiplomacyDealItem:SetLocked() end
---**Contexts:** Gameplay, UI
---
---*Action*
function DiplomacyDealItem:SetParameterValue() end
---**Contexts:** Gameplay, UI
---
---*Query*
function DiplomacyDealItem:GetToPlayerID() end
---**Contexts:** Gameplay, UI
---
---*Query*
function DiplomacyDealItem:GetParentID() end
---**Contexts:** Gameplay, UI
---
---*Query*
function DiplomacyDealItem:HasPossibleDurations() end
---**Contexts:** Gameplay, UI
---
---*Query*
function DiplomacyDealItem:GetParameterValue() end
---**Contexts:** Gameplay, UI
---
---*Query*
function DiplomacyDealItem:GetSubType() end
---**Contexts:** Gameplay, UI
---
---*Query*
function DiplomacyDealItem:GetMaxAmount() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function DiplomacyDealItem:IsChild() end
---**Contexts:** Gameplay, UI
---
---*Query*
function DiplomacyDealItem:GetDuration() end
---**Contexts:** Gameplay, UI
---
---*Query*
function DiplomacyDealItem:GetValueTypeNameID() end
---**Contexts:** Gameplay, UI
---
---*Query*
function DiplomacyDealItem:SetFromPlayerID() end
---**Contexts:** Gameplay, UI
---
---*Query*
function DiplomacyDealItem:GetSubTypeID() end
---**Contexts:** Gameplay, UI
---
---*Query*
function DiplomacyDealItem:GetValueType() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function DiplomacyDealItem:IsValid() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function DiplomacyDealItem:IsLocked() end
---**Contexts:** Gameplay, UI
---
---*Query*
function DiplomacyDealItem:GetEnactedTurn() end
---**Contexts:** Gameplay, UI
---
---*Query*
function DiplomacyDealItem:GetValueCategory() end
---**Contexts:** Gameplay, UI
---
---*Action*
function DiplomacyDealItem:SetAmount() end
---**Contexts:** Gameplay, UI
---
---*Action*
function DiplomacyDealItem:SetDuration() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function DiplomacyDealItem:IsUnacceptable() end
---**Contexts:** Gameplay, UI
---
---*Query*
function DiplomacyDealItem:GetFromPlayerID() end
---**Contexts:** Gameplay, UI
---
---*Query*
function DiplomacyDealItem:GetMinAmount() end
---**Contexts:** Gameplay, UI
---
---*Query*
function DiplomacyDealItem:GetSubTypeNameID() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function DiplomacyDealItem:HasPossibleValues() end
---**Contexts:** Gameplay, UI
---
---*Query*
function DiplomacyDealItem:GetID() end
---**Contexts:** Gameplay, UI
---
---*Action*
function DiplomacyDealItem:SetSubType() end
---**Contexts:** Gameplay, UI
---
---*Query*
function DiplomacyDealItem:GetValueTypeID() end
---**Contexts:** Gameplay, UI
---
---*Action*
function DiplomacyDealItem:SetPlayerIDs() end
---**Contexts:** Gameplay, UI
---
---*Query*
function DiplomacyDealItem:GetType() end
---**Contexts:** Gameplay, UI
---
---*Query*
function DiplomacyDealItem:GetPlayerIDs() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function DiplomacyDealItem:IsExpired() end

z_dontRef_types.DiplomacyDealItem = DiplomacyDealItem