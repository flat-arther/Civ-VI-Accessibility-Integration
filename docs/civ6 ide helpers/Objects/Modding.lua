---@meta


---**Contexts:** UI
Modding = {}
---**Contexts:** UI
---
---*Query*
function Modding.GetModGroups() end
---**Contexts:** UI
---
---*Query*
function Modding.CheckRequirements() end
---**Contexts:** UI
---
---*Action*
---@param workshopItemID number 
function Modding.Unsubscribe(workshopItemID) end
---**Contexts:** UI
---
---*Query*
function Modding.GetModText() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Modding.CanDisableMod() end
---**Contexts:** UI
---
---*Query*
function Modding.GetSubscriptionDetails() end
---**Contexts:** UI
---
---*Query*
function Modding.GetGameModesFromConfigurationString() end
---**Contexts:** UI
---
---*Action*
function Modding.CreateModGroup() end
---**Contexts:** UI
---
---*Action*
function Modding.DeleteModGroup() end
---**Contexts:** UI
---
---*Action*
function Modding.JumpToDigitalMarketplace() end
---**Contexts:** UI
---
---*Query*
function Modding.GetSubscriptions() end
---**Contexts:** UI
---
---*Action*
function Modding.SetIgnoreCompatibilityWarnings() end
---**Contexts:** UI
---
---*Query*
function Modding.GetModProperty() end
---**Contexts:** UI
---
---*Query*
function Modding.GetUserInterfaces() end
---**Contexts:** UI
---
---*Query*
---@return table mods 
function Modding.GetInstalledMods() end
---**Contexts:** UI
---
---*Action*
function Modding.EnableMod() end
---**Contexts:** UI
---
---*Query*
---@param modHandle number 
---@return table modInfo 
function Modding.GetModInfo(modHandle) end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Modding.IsModEnabled() end
---**Contexts:** UI
---
---*Query*
function Modding.GetModHandle() end
---**Contexts:** UI
---
---*Query*
function Modding.ParseModUri() end
---**Contexts:** UI
---
---*Query*
function Modding.ShouldShowCompatibilityWarnings() end
---**Contexts:** UI
---
---*Query*
function Modding.GetIgnoreCompatibilityWarnings() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Modding.CanEnableMod() end
---**Contexts:** UI
---
---*Query*
function Modding.GetSubscriptionDownloadStatus() end
---**Contexts:** UI
---
---*Query*
function Modding.GetAvailableDLC() end
---**Contexts:** UI
---
---*Action*
function Modding.UpdateSubscription() end
---**Contexts:** UI
---
---*Query*
function Modding.GetBundleId() end
---**Contexts:** UI
---
---*Query*
function Modding.GetLastModErrorString() end
---**Contexts:** UI
---
---*Query*
function Modding.GetDLCNeeedsUpdateMessage() end
---**Contexts:** UI
---
---*Query*
function Modding.GetODRDownloadInfo() end
---**Contexts:** UI
---
---*Action*
function Modding.PurchaseDLC() end
---**Contexts:** UI
---
---*Query*
function Modding.SetCurrentModGroup() end
---**Contexts:** UI
---
---*Query*
function Modding.GetDLCPurchaseState() end
---**Contexts:** UI
---
---*Query*
function Modding.GetDLCDetails() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Modding.IsModCompatible() end
---**Contexts:** UI
---
---*Query*
function Modding.GetCurrentModGroup() end
---**Contexts:** UI
---
---*Action*
function Modding.LaunchURL() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Modding.IsTransitioningFromAutosave() end
---**Contexts:** UI
---
---*Query*
function Modding.BundleModText() end
---**Contexts:** UI
---
---*Action*
function Modding.RestoreOutOfDateDLC() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Modding.IsModActive() end
---**Contexts:** UI
---
---*Query*
---@return table mods 
function Modding.GetActiveMods() end
---**Contexts:** UI
---
---*Query*
function Modding.GetFreeTurnsRemaining() end
---**Contexts:** UI
---
---*Query*
function Modding.GetModAssociations() end
---**Contexts:** UI
---
---*Query*
function Modding.GetAvailableFreeTurnDLC() end
---**Contexts:** UI
---
---*Action*
function Modding.ConsumeFreeTurn() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Modding.IsJoinGameAllowed() end
---**Contexts:** UI
---
---*Action*
function Modding.DisableMod() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Modding.IsModOfficial() end
---**Contexts:** UI
---
---*Query*
function Modding.GetModsFromConfigurationString() end
---**Contexts:** UI
---
---*Query*
function Modding.OwnsDLC() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Modding.IsLeaderAllowed() end
---**Contexts:** UI
---
---*Action*
function Modding.UpdateParameter() end
---**Contexts:** UI
---
---*Query*
function Modding.GetLastLoadError() end
---**Contexts:** UI
---
---*Query*
function Modding.RestorePurchase() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Modding.IsModInstalled() end
---**Contexts:** UI
---
---*Action*
function Modding.RestorePurchases() end