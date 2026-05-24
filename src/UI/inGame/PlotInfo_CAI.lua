include("caiUtils")
include("cityManagementInterfaceHelpers_CAI")
include("PlotInfo")

local CITY_MANAGEMENT_WIDGET_ID = "CAIWorldInputCityManagement"
local m_lastHoverAnimatedPlotId = nil
local m_pendingCityManagementAction = nil

local function SpeakActionUnavailable()
    Speak(Locale.Lookup("LOC_CAI_PLOT_INTERFACE_INVALID_TARGET"))
end

local function BuildCityManagementSpeechText(plotId)
    return CAICityManagementInterface.BuildSpeechTextOrInvalid(plotId)
end

local function ClearPendingCityManagementAction()
    m_pendingCityManagementAction = nil
end

local function SetPendingCityManagementAction(kind, plotId)
    local city = UI.GetHeadSelectedCity()
    if city == nil then
        ClearPendingCityManagementAction()
        return
    end

    m_pendingCityManagementAction = {
        Kind = kind,
        Owner = city:GetOwner(),
        CityID = city:GetID(),
        PlotId = plotId,
    }
end

local function IsMatchingPendingCityManagementAction(kind, owner, cityID, plotId)
    return m_pendingCityManagementAction ~= nil
        and m_pendingCityManagementAction.Kind == kind
        and m_pendingCityManagementAction.Owner == owner
        and m_pendingCityManagementAction.CityID == cityID
        and (plotId == nil or m_pendingCityManagementAction.PlotId == plotId)
end

local function TryHandleCityManagementPrimary(plotId)
    local stateData = CAICityManagementInterface.GetStateData()
    if stateData == nil then
        SpeakActionUnavailable()
        return true
    end

    local action = CAICityManagementInterface.ResolvePrimaryAction(plotId, stateData)

    if action == "purchase" then
        return OnClickPurchasePlot(plotId)
    end

    if action == "manage" then
        return OnClickCitizen(plotId)
    end

    SpeakActionUnavailable()
    return true
end

local function TryHandleCityManagementSecondary(plotId)
    local stateData = CAICityManagementInterface.GetStateData()
    if stateData == nil then
        SpeakActionUnavailable()
        return true
    end

    local action = CAICityManagementInterface.ResolveSecondaryAction(plotId, stateData)

    if action == "swap" then
        return OnClickSwapTile(plotId)
    end

    SpeakActionUnavailable()
    return true
end

local function OnCAIInterfaceWidgetPrimaryAction(widgetId, plotId)
    if widgetId ~= CITY_MANAGEMENT_WIDGET_ID then
        return
    end

    if plotId < 0 then
        SpeakActionUnavailable()
        return
    end

    TryHandleCityManagementPrimary(plotId)
end

local function OnCAIInterfaceWidgetSecondaryAction(widgetId, plotId)
    if widgetId ~= CITY_MANAGEMENT_WIDGET_ID then
        return
    end

    if plotId < 0 then
        SpeakActionUnavailable()
        return
    end

    TryHandleCityManagementSecondary(plotId)
end

local function OnCAICursorMoved(x, y, plotId)
    if not CAICityManagementInterface.IsActive() then
        m_lastHoverAnimatedPlotId = nil
        return
    end

    if plotId < 0 or plotId == m_lastHoverAnimatedPlotId then
        return
    end

    local stateData = CAICityManagementInterface.GetStateData()
    local state = CAICityManagementInterface.GetPlotState(plotId, stateData)
    if state == nil or state.Purchase == nil or not state.Purchase.Affordable then
        m_lastHoverAnimatedPlotId = nil
        return
    end

    local instance = m_uiWorldMap[plotId]
    if instance == nil or instance.PurchaseButton:IsHidden() then
        m_lastHoverAnimatedPlotId = nil
        return
    end

    OnSpinningCoinAnimMouseEnter(instance.PurchaseAnim)
    m_lastHoverAnimatedPlotId = plotId
end

local function OnCAICityWorkerChanged(ownerPlayerID, cityID)
    if not IsMatchingPendingCityManagementAction("manage", ownerPlayerID, cityID) then
        return
    end

    local plotId = m_pendingCityManagementAction.PlotId
    ClearPendingCityManagementAction()
    Speak(BuildCityManagementSpeechText(plotId))
end

local function OnCAICityMadePurchase(owner, cityID, plotX, plotY, purchaseType, objectType)
    local plot = Map.GetPlot(plotX, plotY)
    local plotId = plot:GetIndex()
    if not IsMatchingPendingCityManagementAction("purchase", owner, cityID, plotId) then
        return
    end

    ClearPendingCityManagementAction()
    Speak(Locale.Lookup("LOC_CAI_CITY_MANAGEMENT_TILE_PURCHASED"))
end

local function OnCAICityTileOwnershipChanged(owner, cityID)
    if not IsMatchingPendingCityManagementAction("swap", owner, cityID) then
        return
    end

    local plotId = m_pendingCityManagementAction.PlotId
    ClearPendingCityManagementAction()
    Speak(Locale.Lookup("LOC_CAI_CITY_MANAGEMENT_TILE_SWAPPED"))
    Speak(BuildCityManagementSpeechText(plotId))
end

OnClickCitizen = WrapFunc(OnClickCitizen, function(orig, plotId)
    SetPendingCityManagementAction("manage", plotId)
    return orig(plotId)
end)

OnClickPurchasePlot = WrapFunc(OnClickPurchasePlot, function(orig, plotId)
    SetPendingCityManagementAction("purchase", plotId)
    return orig(plotId)
end)

OnClickSwapTile = WrapFunc(OnClickSwapTile, function(orig, plotId)
    SetPendingCityManagementAction("swap", plotId)
    return orig(plotId)
end)

OnShutdown = WrapFunc(OnShutdown, function(orig)
    LuaEvents.CAIInterfaceWidgetPrimaryAction.Remove(OnCAIInterfaceWidgetPrimaryAction)
    LuaEvents.CAIInterfaceWidgetSecondaryAction.Remove(OnCAIInterfaceWidgetSecondaryAction)
    LuaEvents.CAICursorMoved.Remove(OnCAICursorMoved)
    Events.CityWorkerChanged.Remove(OnCAICityWorkerChanged)
    Events.CityMadePurchase.Remove(OnCAICityMadePurchase)
    Events.CityTileOwnershipChanged.Remove(OnCAICityTileOwnershipChanged)
    orig()
end)

ContextPtr:SetShutdown(OnShutdown)
LuaEvents.CAIInterfaceWidgetPrimaryAction.Add(OnCAIInterfaceWidgetPrimaryAction)
LuaEvents.CAIInterfaceWidgetSecondaryAction.Add(OnCAIInterfaceWidgetSecondaryAction)
LuaEvents.CAICursorMoved.Add(OnCAICursorMoved)
Events.CityWorkerChanged.Add(OnCAICityWorkerChanged)
Events.CityMadePurchase.Add(OnCAICityMadePurchase)
Events.CityTileOwnershipChanged.Add(OnCAICityTileOwnershipChanged)
