---@meta


---**Contexts:** Gameplay, UI
---@class DiplomacyDeal
local DiplomacyDeal = {}
---@type table<userdata, table>
DiplomacyDeal.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
DiplomacyDeal.TypeName = "DiplomacyDeal"
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function DiplomacyDeal:IsDemand() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number playerID 
function DiplomacyDeal:GetOtherPlayerID() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param itemType DealItemTypes 
---@param agreementType DealAgreementTypes 
---@return DiplomacyDealItem DiplomacyDealItem 
function DiplomacyDeal:FindItemByType(itemType, agreementType) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param itemType DealItemTypes 
---@param dealSubType DealItemSubTypes 
---@param valueType number 
---@param playerID number 
---@return DiplomacyDealItem DiplomacyDealItem 
function DiplomacyDeal:FindItemByValueType(itemType, dealSubType, valueType, playerID) end
---**Contexts:** Gameplay, UI
---
---*Action*
---@param itemID number 
function DiplomacyDeal:RemoveItemByID(itemID) end
---**Contexts:** Gameplay, UI
---
---*Action*
---@param itemType DealItemTypes 
---@param playerID number 
function DiplomacyDeal:AddItemOfType(itemType, playerID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number playerID 
function DiplomacyDeal:GetPlayer1ID() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function DiplomacyDeal:IsGift() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number amount 
function DiplomacyDeal:GetItemCount() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return DiplomacyDealItem[] diplomacyDealItems 
function DiplomacyDeal:FindItemsByValueType() end
---**Contexts:** Gameplay, UI
---
---*Action*
function DiplomacyDeal:SetUnacceptableItem() end
---**Contexts:** Gameplay, UI
---
---*Action*
function DiplomacyDeal:ClearItemsByValue() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function DiplomacyDeal:IsValid() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param itemType DealItemTypes 
---@param dealSubType DealItemSubTypes 
---@param playerID number 
function DiplomacyDeal:FindItemsByType(itemType, dealSubType, playerID) end
---**Contexts:** Gameplay, UI
---
---*Query*
function DiplomacyDeal:ClearItemsByType() end
---**Contexts:** Gameplay, UI
---
---*Action*
function DiplomacyDeal:SetUnacceptableItemByID() end
---**Contexts:** Gameplay, UI
---
---*Query*
function DiplomacyDeal:Items() end
---**Contexts:** Gameplay, UI
---
---*Action*
function DiplomacyDeal:Validate() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return number playerID 
function DiplomacyDeal:GetPlayer2ID() end
---**Contexts:** Gameplay, UI
---
---*Query*
function DiplomacyDeal:GetItemParent() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function DiplomacyDeal:HasUnacceptableItems() end
---**Contexts:** Gameplay, UI
---
---*Action*
function DiplomacyDeal:RemoveItem() end
---**Contexts:** Gameplay, UI
---
---*Query*
function DiplomacyDeal:FindItemByID() end

z_dontRef_types.DiplomacyDeal = DiplomacyDeal