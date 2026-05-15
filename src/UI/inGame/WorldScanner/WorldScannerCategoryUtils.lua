---@class WorldScannerUtils
---@type WorldScannerUtils
CAIWorldScannerUtils = CAIWorldScannerUtils or {}

local Utils = CAIWorldScannerUtils
local m_currentCursorX = nil
local m_currentCursorY = nil

---@param labelKey string|number|nil
---@return string
function Utils.ResolveText(labelKey)
    if labelKey == nil then
        return ""
    end

    local value = tostring(labelKey)
    if string.sub(value, 1, 4) == "LOC_" then
        return Locale.Lookup(value)
    end

    return value
end

function Utils.GetPlotCount()
    return Map.GetPlotCount()
end

---@param callback fun(plotIndex:integer, plot:table)
function Utils.ForEachPlot(callback)
    local plotCount = Utils.GetPlotCount()
    for plotIndex = 0, plotCount - 1 do
        local plot = Map.GetPlotByIndex(plotIndex)
        if plot ~= nil then
            callback(plotIndex, plot)
        end
    end
end

---@param context WorldScannerContext|nil
---@param callback fun(plotIndex:integer, plot:table)
function Utils.ForEachRevealedPlot(context, callback)
    Utils.ForEachPlot(function(plotIndex, plot)
        if Utils.IsPlotRevealed(context, plot) then
            callback(plotIndex, plot)
        end
    end)
end

function Utils.GetPlotCoords(plotIndex)
    local plot = Map.GetPlotByIndex(plotIndex)
    if plot == nil then
        return nil, nil
    end

    return plot:GetX(), plot:GetY()
end

---@param x integer
---@param y integer
function Utils.SetCurrentCursorPosition(x, y)
    m_currentCursorX = x
    m_currentCursorY = y
end

---@param context WorldScannerContext|nil
function Utils.GetLocalPlayer(context)
    local localPlayerID = Utils.GetLocalPlayerID(context)
    if localPlayerID == nil or localPlayerID == -1 then
        return nil
    end

    return Players[localPlayerID]
end

---@param context WorldScannerContext|nil
---@return integer
function Utils.GetLocalPlayerID(context)
    return context and context.LocalPlayerID or Game.GetLocalPlayer()
end

---@param context WorldScannerContext|nil
---@return integer
function Utils.GetLocalTeamID(context)
    local localPlayer = Utils.GetLocalPlayer(context)
    return localPlayer and localPlayer.GetTeam and localPlayer:GetTeam() or -1
end

---@param context WorldScannerContext|nil
---@return integer
function Utils.GetObserverID(context)
    return context and context.ObserverID or Game.GetLocalObserver()
end

---@param context WorldScannerContext|nil
function Utils.GetVisibility(context)
    local observerID = Utils.GetObserverID(context)
    if observerID == nil or observerID == PlayerTypes.OBSERVER then
        return nil
    end

    return PlayersVisibility[observerID]
end

---@param context WorldScannerContext|nil
function Utils.GetDiplomacy(context)
    local localPlayer = Utils.GetLocalPlayer(context)
    return localPlayer and localPlayer.GetDiplomacy and localPlayer:GetDiplomacy() or nil
end

---@param context WorldScannerContext|nil
function Utils.GetPlayerResources(context)
    local localPlayer = Utils.GetLocalPlayer(context)
    return localPlayer and localPlayer.GetResources and localPlayer:GetResources() or nil
end

---@param context WorldScannerContext|nil
---@param plotIndex integer
---@return number
function Utils.GetDistance(context, plotIndex)
    if m_currentCursorX == nil or m_currentCursorY == nil then
        return math.huge
    end

    local plot = Map.GetPlotByIndex(plotIndex)
    if plot == nil then
        return math.huge
    end

    return Map.GetPlotDistance(m_currentCursorX, m_currentCursorY, plot:GetX(), plot:GetY())
end

---@param context WorldScannerContext|nil
---@param plot table|nil
---@return boolean
function Utils.IsPlotRevealed(context, plot)
    if plot == nil then
        return false
    end

    local visibility = Utils.GetVisibility(context)
    if visibility == nil then
        return true
    end

    return visibility:IsRevealed(plot)
end

---@param context WorldScannerContext|nil
---@param plot table|nil
---@return boolean
function Utils.IsPlotVisible(context, plot)
    if plot == nil then
        return false
    end

    local visibility = Utils.GetVisibility(context)
    if visibility == nil then
        return true
    end

    return visibility:IsVisible(plot:GetIndex())
end

---@param context WorldScannerContext|nil
---@param playerID integer|nil
---@return boolean
function Utils.CanKnowPlayer(context, playerID)
    if playerID == nil or playerID == -1 then
        return false
    end

    local localPlayerID = Utils.GetLocalPlayerID(context)
    if context == nil or localPlayerID == nil or localPlayerID == -1 then
        return true
    end

    if playerID == localPlayerID then
        return true
    end

    local diplomacy = Utils.GetDiplomacy(context)
    return diplomacy ~= nil and diplomacy:HasMet(playerID)
end

---@param context WorldScannerContext|nil
---@param playerID integer|nil
---@return "my"|"neutral"|"enemy"
function Utils.GetTeamStance(context, playerID)
    if playerID == nil or playerID == -1 then
        return "neutral"
    end

    local localPlayerID = Utils.GetLocalPlayerID(context)
    if context == nil or localPlayerID == nil or localPlayerID == -1 then
        return "neutral"
    end

    if playerID == localPlayerID then
        return "my"
    end

    local player = Players[playerID]
    if player == nil then
        return "neutral"
    end

    local teamID = player.GetTeam and player:GetTeam() or -1
    if teamID ~= -1 and teamID == Utils.GetLocalTeamID(context) then
        return "my"
    end

    local diplomacy = Utils.GetDiplomacy(context)
    if diplomacy ~= nil and diplomacy:IsAtWarWith(playerID) then
        return "enemy"
    end

    return "neutral"
end

function Utils.GetPlayerLabel(playerID)
    local config = playerID ~= nil and playerID ~= -1 and PlayerConfigurations[playerID] or nil
    if config == nil then
        return "LOC_CAI_WORLD_SCANNER_UNKNOWN"
    end

    local civName = config:GetCivilizationDescription()
    if civName ~= nil and civName ~= "" then
        return civName
    end

    local leaderName = config:GetLeaderName()
    if leaderName ~= nil and leaderName ~= "" then
        return leaderName
    end

    return "LOC_CAI_WORLD_SCANNER_UNKNOWN"
end

function Utils.GetCityLabel(city)
    if city == nil or city.GetName == nil then
        return "LOC_CAI_WORLD_SCANNER_UNKNOWN"
    end

    local name = city:GetName()
    if name == nil or name == "" then
        return "LOC_CAI_WORLD_SCANNER_UNKNOWN"
    end

    return name
end

function Utils.GetUnitTypeLabel(unitType)
    local info = unitType ~= nil and GameInfo.Units[unitType] or nil
    return info and info.Name or "LOC_CAI_WORLD_SCANNER_UNKNOWN"
end

function Utils.GetImprovementLabel(improvementType)
    local info = improvementType ~= nil and GameInfo.Improvements[improvementType] or nil
    return info and info.Name or "LOC_CAI_WORLD_SCANNER_UNKNOWN"
end

function Utils.GetRouteLabel(routeType)
    local info = routeType ~= nil and GameInfo.Routes[routeType] or nil
    return info and info.Name or "LOC_CAI_WORLD_SCANNER_UNKNOWN"
end

function Utils.GetResourceLabel(resourceType)
    local info = resourceType ~= nil and GameInfo.Resources[resourceType] or nil
    return info and info.Name or "LOC_CAI_WORLD_SCANNER_UNKNOWN"
end

function Utils.GetFeatureLabel(featureType)
    local info = featureType ~= nil and GameInfo.Features[featureType] or nil
    return info and info.Name or "LOC_CAI_WORLD_SCANNER_UNKNOWN"
end

function Utils.GetTerrainLabel(terrainType)
    local info = terrainType ~= nil and GameInfo.Terrains[terrainType] or nil
    return info and info.Name or "LOC_CAI_WORLD_SCANNER_UNKNOWN"
end

function Utils.GetResourceClassKey(resourceType)
    local info = resourceType ~= nil and GameInfo.Resources[resourceType] or nil
    if info == nil then
        return nil
    end

    return info.ResourceClassType
end

function Utils.GetResourceClassLabel(resourceClassType)
    if resourceClassType == "RESOURCECLASS_BONUS" then
        return "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_BONUS"
    end
    if resourceClassType == "RESOURCECLASS_LUXURY" then
        return "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_LUXURY"
    end
    if resourceClassType == "RESOURCECLASS_STRATEGIC" then
        return "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_STRATEGIC"
    end
    if resourceClassType == "RESOURCECLASS_ARTIFACT" then
        return "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_ARTIFACT"
    end

    return "LOC_CAI_WORLD_SCANNER_UNKNOWN"
end

function Utils.GetUnitClassKey(unitType)
    local info = unitType ~= nil and GameInfo.Units[unitType] or nil
    if info == nil then
        return nil
    end

    return info.PromotionClass
end

function Utils.GetUnitClassLabel(unitClassType)
    local info = unitClassType ~= nil and GameInfo.UnitPromotionClasses[unitClassType] or nil
    if info ~= nil and info.Name ~= nil then
        return info.Name
    end

    return "LOC_CAI_WORLD_SCANNER_UNKNOWN"
end

function Utils.MakePositionText(index, total)
    return Locale.Lookup("LOC_UIWidget_Element_Pos", index, total)
end
