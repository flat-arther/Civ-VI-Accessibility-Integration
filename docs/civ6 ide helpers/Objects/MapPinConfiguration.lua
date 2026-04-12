---@meta


---**Contexts:** UI
---@class MapPinConfiguration
local MapPinConfiguration = {}
---@type table<userdata, table>
MapPinConfiguration.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
MapPinConfiguration.TypeName = "MapPinConfiguration"
---**Contexts:** UI
---
---*Query*
---@return string iconName 
function MapPinConfiguration:GetIconName() end
---**Contexts:** UI
---
---*Query*
---@return number y 
function MapPinConfiguration:GetHexY() end
---**Contexts:** UI
---
---*Action*
---@param chatTargetType ChatTargetTypes 
function MapPinConfiguration:SetVisibility(chatTargetType) end
---**Contexts:** UI
---
---*Action*
---@param iconName string 
function MapPinConfiguration:SetIconName(iconName) end
---**Contexts:** UI
---
---*Query*
---@return number x 
function MapPinConfiguration:GetHexX() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function MapPinConfiguration:IsPrivate() end
---**Contexts:** UI
---
---*Query*
---@param playerID number 
---@return boolean  
function MapPinConfiguration:IsVisible(playerID) end
---**Contexts:** UI
---
---*Query*
---@return ChatTargetTypes chatTargetType 
function MapPinConfiguration:GetVisibility() end
---**Contexts:** UI
---
---*Query*
---@return number playerID 
function MapPinConfiguration:GetPlayerID() end
---**Contexts:** UI
---
---*Action*
---@param name string 
function MapPinConfiguration:SetName(name) end
---**Contexts:** UI
---
---*Query*
---@return number pinID 
function MapPinConfiguration:GetID() end
---**Contexts:** UI
---
---*Query*
---@return string name 
function MapPinConfiguration:GetName() end

z_dontRef_types.MapPinConfiguration = MapPinConfiguration