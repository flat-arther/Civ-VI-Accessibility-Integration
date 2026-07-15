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

local m_vanillaToggleEspionage = Input.GetActionId("ToggleEspionage")
local m_vanillaToggleRankings = Input.GetActionId("ToggleRankings")
local m_vanillaToggleTradeRoutes = Input.GetActionId("ToggleTradeRoutes")

local m_caiOpenEraProgressId = Input.GetActionId("UI_CAIOpenEraProgress")

local function GetLocalPlayer()
    local playerID = Game.GetLocalPlayer()
    if playerID == nil or playerID < 0 then return nil end
    return Players[playerID]
end

local function HasMetCityState(player)
    if player == nil then return false end
    local diplomacy = player:GetDiplomacy()
    for _, minor in ipairs(PlayerManager.GetAliveMinors()) do
        if diplomacy:HasMet(minor:GetID()) then return true end
    end
    return false
end

local function OnCAIOpenCityStates()
    local player = GetLocalPlayer()
    if not GameCapabilities.HasCapability("CAPABILITY_CITY_STATES_VIEW") then
        Speak(Locale.Lookup("LOC_CAI_UI_UNAVAILABLE_IN_CURRENT_GAME"))
    elseif not HasMetCityState(player) then
        Speak(Locale.Lookup("LOC_CAI_UI_NO_CITY_STATES_MET"))
    else
        CheckCityStatesUnlocked(player)
        OnToggleCityStates()
        UI.PlaySound("Play_UI_Click")
    end
end

Events.InputActionTriggered.Remove(OnInputActionTriggered)
OnInputActionStarted = WrapFunc(OnInputActionTriggered, function(orig, actionId)
    if m_caiOpenCityStatesId and actionId == m_caiOpenCityStatesId then
        OnCAIOpenCityStates()
        return
    end
    if m_caiOpenEspionageId and actionId == m_caiOpenEspionageId then
        local player = GetLocalPlayer()
        if not GameCapabilities.HasCapability("CAPABILITY_ESPIONAGE_VIEW") then
            Speak(Locale.Lookup("LOC_CAI_UI_UNAVAILABLE_IN_CURRENT_GAME"))
        elseif UI.QueryGlobalParameterInt("DISABLE_ESPIONAGE_HOTKEY") == 1 then
            Speak(Locale.Lookup("LOC_CAI_UI_ESPIONAGE_HOTKEY_DISABLED"))
        elseif player == nil or player:GetDiplomacy():GetSpyCapacity() <= 0 then
            Speak(Locale.Lookup("LOC_CAI_UI_NO_SPY_CAPACITY"))
        else
            orig(m_vanillaToggleEspionage)
        end
        return
    end
    if m_caiOpenWorldRankingsId and actionId == m_caiOpenWorldRankingsId then
        if GameCapabilities.HasCapability("CAPABILITY_DISPLAY_HUD_WORLD_RANKINGS") then
            orig(m_vanillaToggleRankings)
        else
            Speak(Locale.Lookup("LOC_CAI_UI_WORLD_RANKINGS_UNAVAILABLE"))
        end
        return
    end
    if m_caiOpenTradeOverviewId and actionId == m_caiOpenTradeOverviewId then
        local player = GetLocalPlayer()
        if not GameCapabilities.HasCapability("CAPABILITY_TRADE_VIEW") then
            Speak(Locale.Lookup("LOC_CAI_UI_UNAVAILABLE_IN_CURRENT_GAME"))
        elseif player == nil or player:GetTrade():GetOutgoingRouteCapacity() <= 0 then
            Speak(Locale.Lookup("LOC_CAI_UI_NO_TRADE_ROUTE_CAPACITY"))
        else
            orig(m_vanillaToggleTradeRoutes)
        end
        return
    end
    if m_caiOpenEraProgressId and actionId == m_caiOpenEraProgressId then
        if not (IsExpansion1Active() or IsExpansion2Active()) then
            Speak(Locale.Lookup("LOC_CAI_UI_REQUIRES_RISE_AND_FALL"))
        elseif GameCapabilities.HasCapability("CAPABILITY_ERAS") then
            OnToggleEraProgress()
        else
            Speak(Locale.Lookup("LOC_CAI_UI_UNAVAILABLE_IN_CURRENT_GAME"))
        end
        return
    end
end)
Events.InputActionStarted.Add(OnInputActionStarted)
