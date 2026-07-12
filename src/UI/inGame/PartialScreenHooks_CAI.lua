include("caiUtils")
include("Civ6Common")
if IsExpansion2Active() then
    include("PartialScreenHooks_Expansion2")
elseif IsExpansion1Active() then
    include("PartialScreenHooks_Expansion1")
else
    include("PartialScreenHooks")
end

local m_caiOpenCityStatesId = Input.GetActionId("UI_CAIOpenCityStates")
local m_caiOpenEspionageId = Input.GetActionId("UI_CAIOpenEspionage")
local m_caiOpenWorldRankingsId = Input.GetActionId("UI_CAIOpenWorldRankings")
local m_caiOpenTradeOverviewId = Input.GetActionId("UI_CAIOpenTradeOverview")

local m_vanillaToggleCityStates = Input.GetActionId("ToggleCityStates")
local m_vanillaToggleEspionage = Input.GetActionId("ToggleEspionage")
local m_vanillaToggleRankings = Input.GetActionId("ToggleRankings")
local m_vanillaToggleTradeRoutes = Input.GetActionId("ToggleTradeRoutes")

local m_caiOpenEraProgressId
if IsExpansion1Active() or IsExpansion2Active() then
    m_caiOpenEraProgressId = Input.GetActionId("UI_CAIOpenEraProgress")
end
Events.InputActionTriggered.Remove(OnInputActionTriggered)
OnInputActionStarted = WrapFunc(OnInputActionTriggered, function(orig, actionId)
    if m_caiOpenCityStatesId and actionId == m_caiOpenCityStatesId then
        orig(m_vanillaToggleCityStates)
        return
    end
    if m_caiOpenEspionageId and actionId == m_caiOpenEspionageId then
        orig(m_vanillaToggleEspionage)
        return
    end
    if m_caiOpenWorldRankingsId and actionId == m_caiOpenWorldRankingsId then
        orig(m_vanillaToggleRankings)
        return
    end
    if m_caiOpenTradeOverviewId and actionId == m_caiOpenTradeOverviewId then
        orig(m_vanillaToggleTradeRoutes)
        return
    end
    if m_caiOpenEraProgressId and actionId == m_caiOpenEraProgressId then
        OnToggleEraProgress()
        return
    end
end)
Events.InputActionStarted.Add(OnInputActionStarted)
