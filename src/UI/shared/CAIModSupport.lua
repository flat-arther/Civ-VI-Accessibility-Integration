-- Scenario and mod-registry queries shared by CAI screens and helpers.
CAIModSupport = {}

local BBG_MOD_IDS = {
    "cb84075d-5007-4207-b662-c35a5f7be240", -- iElden (current)
    "cb84075d-5007-4207-b662-c35a5f7be217", -- codenaugh
    "cb84075d-5007-4207-b662-c35a5f7be231", -- beta
}

function CAIModSupport.IsBBGActive()
    for _, id in ipairs(BBG_MOD_IDS) do
        if Modding.IsModActive(id) then return true end
    end
    return false
end

-- Preserve the UnitFlagManager fallback when GetRuleSet is unavailable.
function CAIModSupport.GetRuleSet()
    if GameConfiguration.GetRuleSet ~= nil then
        return GameConfiguration.GetRuleSet()
    end
    if GameConfiguration.GetValue ~= nil then
        return GameConfiguration.GetValue("RULESET")
    end
    return nil
end

function CAIModSupport.IsCivRoyaleScenarioActive()
    return CAIModSupport.GetRuleSet() == "RULESET_SCENARIO_CIV_ROYALE"
end

function CAIModSupport.IsPiratesScenarioActive()
    return CAIModSupport.GetRuleSet() == "RULESET_SCENARIO_PIRATES"
end

function CAIModSupport.IsWarMachineScenarioActive()
    return CAIModSupport.GetRuleSet() == "RULESET_SCENARIO_WARMACHINE"
end

function CAIModSupport.IsBlackDeathScenarioActive()
    return CAIModSupport.GetRuleSet() == "RULESET_SCENARIO_BLACKDEATH"
end

function CAIModSupport.IsIndonesiaKhmerScenarioActive()
    return CAIModSupport.GetRuleSet() == "RULESET_SCENARIO_INDONESIA_KHMER"
end

function CAIModSupport.IsPolandScenarioActive()
    return CAIModSupport.GetRuleSet() == "RULESET_SCENARIO_POLAND"
end

function CAIModSupport.IsVikingsScenarioActive()
    return CAIModSupport.GetRuleSet() == "RULESET_SCENARIO_VIKINGS"
end

function CAIModSupport.IsAustraliaScenarioActive()
    return CAIModSupport.GetRuleSet() == "RULESET_SCENARIO_AUSTRALIA"
end

function CAIModSupport.IsAlexanderScenarioActive()
    return CAIModSupport.GetRuleSet() == "RULESET_SCENARIO_ALEXANDER"
end

function CAIModSupport.IsNubiaScenarioActive()
    return CAIModSupport.GetRuleSet() == "RULESET_SCENARIO_NUBIA"
end

function CAIModSupport.IsBetterTradeScreenActive()
    return Modding.IsModActive("8d4fa23a-ef43-440c-8422-2bec11f8f5d7")
end

function CAIModSupport.IsBetterReportScreenActive()
    return Modding.IsModActive("6f2888d4-79dc-415f-a8ff-f9d81d7afb53")
end

function CAIModSupport.IsExtendedPolicyCardsActive()
    return Modding.IsModActive("382a187f-c8ba-4094-a6a7-0d5315661f33")
end

function CAIModSupport.IsQuickDealsActive()
    return Modding.IsModActive("5aceed03-8639-4a81-8cbf-03f54d543502")
end

function CAIModSupport.IsDetailedMapTacksActive()
    return Modding.IsModActive("4ecfcc62-5471-4435-b295-590df213e8d8")
end

function CAIModSupport.IsRealEraTrackerActive()
    return Modding.IsModActive("11B9FBBE-25BD-7E24-3909-67A060B2456C")
end

function CAIModSupport.IsTutorialActive()
    return Modding.IsModActive("17462E0F-1EE1-4819-AAAA-052B5896B02A")
end

function CAIModSupport.IsBabylonActive()
    return Modding.IsModActive("8424840C-92EF-4426-A9B4-B4E0CB818049")
end

-- Babylon.modinfo activates its Heroes UI only for this game mode.
function CAIModSupport.IsHeroesModeActive()
    return CAIModSupport.IsBabylonActive() and GameConfiguration.GetValue("GAMEMODE_HEROES") == true
end
