---@meta


---**Contexts:** Gameplay, UI
DealManager = {}
---**Contexts:** Gameplay, UI
---
---*Query*
---@param initiatingPlayerID number 
---@param otherPlayerID number 
---@return boolean  
function DealManager.AreWorkingDealsEqual(initiatingPlayerID, otherPlayerID) end
---**Contexts:** Gameplay, UI
---
---*Action*
---@param direction DealDirection 
---@param initiatingPlayerID number 
---@param otherPlayerID number 
function DealManager.ClearWorkingDeal(direction, initiatingPlayerID, otherPlayerID) end
---**Contexts:** Gameplay, UI
---
---*Action*
---@param initiatingPlayerID number 
---@param otherPlayerID number 
function DealManager.CopyIncomingToOutgoingWorkingDeal(initiatingPlayerID, otherPlayerID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param initiatingPlayerID number 
---@param otherPlayerID number 
---@return table deals 
function DealManager.GetPlayerDeals(initiatingPlayerID, otherPlayerID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param initiatingPlayerID number 
---@param otherPlayerID number 
---@param itemType DealItemTypes 
---@param DiplomacyDeal DiplomacyDeal 
---@return DiplomacyDealItem[] dealItems 
function DealManager.GetPossibleDealItems(initiatingPlayerID, otherPlayerID, itemType, DiplomacyDeal) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param direction DealDirection 
---@param initiatingPlayerID number 
---@param otherPlayerID number 
---@return DiplomacyDeal DiplomacyDeal 
function DealManager.GetWorkingDeal(direction, initiatingPlayerID, otherPlayerID) end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param initiatingPlayerID number 
---@param otherPlayerID number 
---@return boolean  
function DealManager.HasPendingDeal(initiatingPlayerID, otherPlayerID) end
---**Contexts:** Gameplay, UI
---
---*Action*
---@param proposalAction DealProposalAction 
---@param initiatingPlayerID number 
---@param otherPlayerID number 
function DealManager.SendWorkingDeal(proposalAction, initiatingPlayerID, otherPlayerID) end
---**Contexts:** Gameplay
---
---*Action*
function DealManager.RequestUpdate() end
---**Contexts:** UI
---
---*Action*
function DealManager.EditWorkingDeal() end
---**Contexts:** Gameplay
---
---*Action*
function DealManager.EnactWorkingDeal() end
---**Contexts:** UI
---
---*Action*
function DealManager.ViewPendingDeal() end