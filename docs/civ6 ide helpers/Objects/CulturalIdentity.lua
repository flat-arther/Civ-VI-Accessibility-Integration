---@meta


---**Contexts:** UI
---@class CulturalIdentity
local CulturalIdentity = {}
---@type table<userdata, table>
CulturalIdentity.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
CulturalIdentity.TypeName = "CulturalIdentity"
---**Contexts:** UI
---
---*Query*
---@return table sources 
function CulturalIdentity:GetIdentitySourcesBreakdown() end
---**Contexts:** UI
---
---*Query*
---@return IdentityConversionOutcome conversionOutcome 
function CulturalIdentity:GetConversionOutcome() end
---**Contexts:** UI
---
---*Query*
---@return table identities 
function CulturalIdentity:GetPlayerIdentitiesInCity() end
---**Contexts:** UI
---
---*Query*
---@return number amount 
function CulturalIdentity:GetLoyaltyPerTurn() end
---**Contexts:** UI
---
---*Query*
function CulturalIdentity:GetGovernorIdentityPressures() end
---**Contexts:** UI
---
---*Query*
---@return number playerID 
function CulturalIdentity:GetPotentialTransferPlayer() end
---**Contexts:** UI
---
---*Query*
---@return table pressureBreakdown 
function CulturalIdentity:GetIdentitySourcesDetailedBreakdown() end
---**Contexts:** UI
---
---*Query*
function CulturalIdentity:GetLoyaltyPerTurnStatus() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function CulturalIdentity:IsAlwaysFullyLoyal() end
---**Contexts:** UI
---
---*Query*
---@return number loyaltyLevel 
function CulturalIdentity:GetLoyaltyLevel() end
---**Contexts:** UI
---
---*Query*
---@return table identityPressures 
function CulturalIdentity:GetCityIdentityPressures() end
---**Contexts:** UI
---
---*Query*
---@return number ratio 
function CulturalIdentity:GetLoyaltyPerTurnFromIdentityPressureRatio() end
---**Contexts:** UI
---
---*Query*
---@return number turns 
function CulturalIdentity:GetTurnsToConversion() end
---**Contexts:** UI
---
---*Query*
---@return number amount 
function CulturalIdentity:GetMaxLoyalty() end
---**Contexts:** UI
---
---*Query*
---@return number amount 
function CulturalIdentity:GetLoyalty() end

z_dontRef_types.CulturalIdentity = CulturalIdentity