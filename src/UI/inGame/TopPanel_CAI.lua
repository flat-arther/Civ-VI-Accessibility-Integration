include("CAIModSupport")
include("CAIGameState")
include("caiUtils")
include("Civ6Common")

if CAIModSupport.IsPiratesScenarioActive() then
    include("PiratesScenario_PropKeys")
    include("TopPanel_PiratesScenario")
elseif CAIModSupport.IsCivRoyaleScenarioActive() then
    include("TopPanel_CivRoyaleScenario_CAIBase")
elseif CAIModSupport.IsWarMachineScenarioActive() then
    include("TopPanel_WarMachineScenario")
elseif CAIModSupport.IsBlackDeathScenarioActive() then
    include("TopPanel_BlackDeathScenario")
elseif IsExpansion2Active() then
    include("TopPanel_Expansion2")
elseif IsExpansion1Active() then
    include("TopPanel_Expansion1")
else
    include("TopPanel")
end

local mgr = CAI:GetUIManager()

local ACTION_SPEAK_TURN_TIME_DATE = Input.GetActionId("UI_TopPanelSpeakTurnTimeDate")
local ACTION_SPEAK_GOLD = Input.GetActionId("UI_TopPanelSpeakGold")
local ACTION_SPEAK_FAITH = Input.GetActionId("UI_TopPanelSpeakFaith")
local ACTION_SPEAK_TOURISM = Input.GetActionId("UI_TopPanelSpeakTourism")
local ACTION_SPEAK_INFLUENCE = Input.GetActionId("UI_TopPanelSpeakInfluence")
local ACTION_SPEAK_NUKES = Input.GetActionId("UI_TopPanelSpeakNukes")
local ACTION_SPEAK_CITY_WARNINGS = Input.GetActionId("UI_TopPanelSpeakCityWarnings")
local ACTION_SPEAK_CITY_WARNINGS_DETAILS = Input.GetActionId("UI_TopPanelSpeakCityWarningsDetails")
local ACTION_SPEAK_GOLD_DETAILS = Input.GetActionId("UI_TopPanelSpeakGoldDetails")
local ACTION_SPEAK_FAITH_DETAILS = Input.GetActionId("UI_TopPanelSpeakFaithDetails")
local ACTION_SPEAK_TOURISM_DETAILS = Input.GetActionId("UI_TopPanelSpeakTourismDetails")
local ACTION_SPEAK_INFLUENCE_DETAILS = Input.GetActionId("UI_TopPanelSpeakInfluenceDetails")
local ACTION_OPEN_DIPLOMACY = Input.GetActionId("UI_TopPanelOpenDiplomacy")
local ACTION_OPEN_REPORTS = Input.GetActionId("UI_TopPanelOpenReports")
local ACTION_OPEN_REPORTS_RESOURCES = Input.GetActionId("UI_TopPanelOpenReportsResources")
local ACTION_OPEN_REPORTS_CITY_STATUS = Input.GetActionId("UI_TopPanelOpenReportsCityStatus")
local ACTION_OPEN_REPORTS_GOSSIP = Input.GetActionId("UI_TopPanelOpenReportsGossip")
local ACTION_OPEN_GLOBAL_RESOURCES = Input.GetActionId("UI_OpenGlobalResourcePopup")

local function IsReportOpeningAction(actionId)
    return actionId == ACTION_OPEN_REPORTS
        or actionId == ACTION_OPEN_REPORTS_RESOURCES
        or actionId == ACTION_OPEN_REPORTS_CITY_STATUS
        or actionId == ACTION_OPEN_REPORTS_GOSSIP
        or actionId == ACTION_OPEN_GLOBAL_RESOURCES
end

-- Read city-wide warning states live, without opening or selecting a city.
local function GetCityWarningParts(city, player)
    local parts = {}
    local function Add(tag, ...)
        parts[#parts + 1] = Locale.Lookup(tag, ...)
    end

    if IsExpansion1Active() or IsExpansion2Active() then
        local identity = city:GetCulturalIdentity()
        if identity then
            local level = GameInfo.LoyaltyLevels[identity:GetLoyaltyLevel()]
            if level.GrowthChange < 1 or level.YieldChange < 0 then
                Add(level.Name)
            end
            if identity:GetLoyaltyPerTurn() < 0 then
                Add("LOC_CAI_LENS_LOYALTY_LOSING")
            end
        end
    end

    local growth = city:GetGrowth()
    if growth:GetHappinessGrowthModifier() < 0 or growth:GetHappinessNonFoodYieldModifier() < 0 then
        Add(GameInfo.Happinesses[growth:GetHappiness()].Name)
    end
    if growth:GetTurnsUntilStarvation() ~= -1 then
        Add("LOC_HUD_REPORTS_STATUS_STARVING")
    end
    local housingMultiplier = growth:GetHousingGrowthModifier()
    if housingMultiplier == 0 then
        Add("LOC_HUD_CITY_POPULATION_GROWTH_HALTED")
    elseif housingMultiplier <= 0.5 then
        Add("LOC_HUD_CITY_POPULATION_GROWTH_SLOWED", (1 - housingMultiplier) * 100)
    end

    if IsExpansion2Active() then
        local power = city:GetPower()
        if power and power:GetRequiredPower() > 0 and not power:IsFullyPowered() then
            Add("LOC_POWER_STATUS_UNPOWERED_NAME")
        end
    end
    local district = player:GetDistricts():FindID(city:GetDistrictID())
    if district then
        if district:IsUnderSiege() then
            Add("LOC_HUD_REPORTS_STATUS_UNDER_SEIGE")
        end
    else
        LogWarn("CityWarnings: City center district unavailable for city " .. tostring(city:GetID()))
    end
    return parts
end

local function SpeakCityWarnings(detailed)
    local _, player = CAIGameState.GetLocalPlayer()
    if not player then
        Speak(Locale.Lookup("LOC_CAI_CITY_BANNER_INFO_UNAVAILABLE"))
        return
    end
    if player:GetCities():GetCount() == 0 then
        Speak(Locale.Lookup("LOC_CAI_NO_CITIES"))
        return
    end

    local warnings = {}
    for _, city in player:GetCities():Members() do
        local parts = GetCityWarningParts(city, player)
        if #parts > 0 then
            warnings[#warnings + 1] = {
                name = Locale.Lookup(city:GetName()),
                id = city:GetID(),
                text = table.concat(parts, ", "),
            }
        end
    end
    if #warnings == 0 then
        Speak(Locale.Lookup("LOC_CAI_CITY_WARNINGS_NONE"))
        return
    end

    local summary = Locale.Lookup("LOC_CAI_CITY_WARNINGS_COUNT", #warnings)
    if not detailed then
        Speak(summary)
        return
    end
    table.sort(warnings, function(a, b)
        if a.name == b.name then return a.id < b.id end
        return Locale.Compare(a.name, b.name) < 0
    end)
    local lines = { summary }
    for _, warning in ipairs(warnings) do
        lines[#lines + 1] = warning.name .. ", " .. warning.text
    end
    Speak(table.concat(lines, "[NEWLINE]"), true)
end

local function GetDisplayedFaithYield(player)
    local faithYield = player:GetReligion():GetFaithYield()
    if CAIModSupport.IsBlackDeathScenarioActive()
        and IsFranceLocalPlayer ~= nil and IsFranceLocalPlayer()
        and RULES ~= nil and RULES.IsPapalSlotFilled ~= nil and RULES.IsPapalSlotFilled() then
        faithYield = faithYield - RULES.PapalSlotUpkeep
    end
    return faithYield
end

-- ===========================================================================
-- Individual yield speech
-- ===========================================================================
local function SpeakGold()
    local _, player = CAIGameState.GetLocalPlayer()
    if not player then return end
    if not GameCapabilities.HasCapability("CAPABILITY_GOLD")
        or not GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
        return
    end

    local parts = {}
    local treasury = player:GetTreasury()
    local goldYield = treasury:GetGoldYield() - treasury:GetTotalMaintenance()
    local goldBalance = math.floor(treasury:GetGoldBalance())
    table.insert(parts, Locale.Lookup("LOC_TOP_PANEL_GOLD") .. ": "
        .. Locale.Lookup("LOC_CAI_TOP_PANEL_BALANCE_AND_RATE",
            CAIText.FormatBalance(goldBalance),
            CAIText.FormatRatePerTurn(FormatValuePerTurn(goldYield))))

    if GameCapabilities.HasCapability("CAPABILITY_TRADE") then
        local playerTrade = player:GetTrade()
        local routesActive = playerTrade:GetNumOutgoingRoutes()
        local routesCapacity = playerTrade:GetOutgoingRouteCapacity()
        if routesCapacity > 0 then
            table.insert(parts, Locale.Lookup("LOC_CAI_TOP_PANEL_TRADE_ROUTES",
                routesActive, routesCapacity))
        end
    end

    Speak(table.concat(parts, "[NEWLINE]"))
end

local function SpeakFaith()
    local _, player = CAIGameState.GetLocalPlayer()
    if not player then return end
    if not GameCapabilities.HasCapability("CAPABILITY_FAITH")
        or not GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
        return
    end

    local religion = player:GetReligion()
    local value = Locale.Lookup("LOC_CAI_TOP_PANEL_BALANCE_AND_RATE",
        CAIText.FormatBalance(religion:GetFaithBalance()),
        CAIText.FormatRatePerTurn(FormatValuePerTurn(GetDisplayedFaithYield(player))))
    Speak(Locale.Lookup("LOC_TOP_PANEL_FAITH") .. ": " .. value)
end

local function SpeakTourism()
    local _, player = CAIGameState.GetLocalPlayer()
    if not player then return end
    if not GameCapabilities.HasCapability("CAPABILITY_TOURISM")
        or not GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
        return
    end

    local tourismRate = Round(player:GetStats():GetTourism(), 1)
    if tourismRate > 0 then
        Speak(Locale.Lookup("LOC_TOP_PANEL_TOURISM") .. ": "
            .. CAIText.FormatRatePerTurn(CAIText.FormatBalance(tourismRate)))
    else
        Speak(Locale.Lookup("LOC_TOP_PANEL_TOURISM") .. ": 0")
    end
end

local function SpeakFavor()
    local _, player = CAIGameState.GetLocalPlayer()
    if not player then return end

    if GameCapabilities.HasCapability("CAPABILITY_TOP_PANEL_ENVOYS") then
        local playerInfluence = player:GetInfluence()
        local currentEnvoys = playerInfluence:GetTokensToGive()
        local influenceBalance = Round(playerInfluence:GetPointsEarned(), 1)
        local influenceThreshold = playerInfluence:GetPointsThreshold()
        Speak(Locale.Lookup("LOC_CAI_TOP_PANEL_ENVOYS_SUMMARY",
            currentEnvoys, influenceBalance, influenceThreshold))
    end
end

local function SpeakNukes()
    local playerID, player = CAIGameState.GetLocalPlayer()
    if not player then return end

    local playerWMDs = player:GetWMDs()
    local parts = {}
    for entry in GameInfo.WMDs() do
        if entry.WeaponType == "WMD_NUCLEAR_DEVICE" then
            local count = playerWMDs:GetWeaponCount(entry.Index)
            if count > 0 then
                table.insert(parts, Locale.Lookup("LOC_CAI_TOP_PANEL_NUCLEAR_DEVICES", count))
            end
        elseif entry.WeaponType == "WMD_THERMONUCLEAR_DEVICE" then
            local count = playerWMDs:GetWeaponCount(entry.Index)
            if count > 0 then
                table.insert(parts, Locale.Lookup("LOC_CAI_TOP_PANEL_THERMONUCLEAR_DEVICES", count))
            end
        end
    end

    if #parts == 0 then
        Speak(Locale.Lookup("LOC_CAI_TOP_PANEL_NO_NUKES"))
    else
        Speak(table.concat(parts, "[NEWLINE]"))
    end
end

local m_caiTurnTimerElapsed = 0
local m_caiTurnTimerMax = 0

local function OnTurnTimerUpdated(elapsedTime, maxTurnTime)
    m_caiTurnTimerElapsed = elapsedTime
    m_caiTurnTimerMax = maxTurnTime
end

local function GetTurnTimerString()
    if m_caiTurnTimerMax <= 0 then return nil end
    local remaining = m_caiTurnTimerMax - m_caiTurnTimerElapsed
    if remaining < 0 then remaining = 0 end
    return Locale.Lookup("LOC_CAI_TOP_PANEL_TURN_TIMER",
        FormatTimeRemaining(remaining, true))
end

local function AddRoyaleWMDParts(parts, player)
    local playerWMDs = player:GetWMDs()
    for entry in GameInfo.WMDs() do
        local count = playerWMDs:GetWeaponCount(entry.Index)
        if count > 0 then
            if entry.WeaponType == "WMD_NUCLEAR_DEVICE" then
                table.insert(parts, Locale.Lookup("LOC_CAI_TOP_PANEL_NUCLEAR_DEVICES", count))
            elseif entry.WeaponType == "WMD_THERMONUCLEAR_DEVICE" then
                table.insert(parts, Locale.Lookup("LOC_CAI_TOP_PANEL_THERMONUCLEAR_DEVICES", count))
            elseif entry.WeaponType == "WMD_HAIL_MARY" then
                table.insert(parts, Locale.Lookup("LOC_CAI_CIV_ROYALE_HAIL_MARY_DEVICES", count))
            end
        end
    end
end

local function AddRoyaleSettlerWarning(parts, playerID, player)
    local playerConfig = PlayerConfigurations[playerID]
    for _, unit in player:GetUnits():Members() do
        if UnitManager.GetTypeName(unit) == "UNIT_SETTLER" then
            local plot = Map.GetPlot(unit:GetX(), unit:GetY())
            if not CheckUnitFalloutStatus(plot, playerConfig) then
                table.insert(parts, Locale.Lookup("LOC_CIV_ROYALE_HUD_CIVILIAN_WARNING"))
                return
            end
        end
    end
end

local function GetRoyaleAbilityParts(playerID, player)
    local config = PlayerConfigurations[playerID]
    if config == nil then return nil end

    local civType = config:GetCivilizationTypeName()
    local nameTag = nil
    local tooltipTag = nil
    local status = nil
    local currentTurn = Game.GetCurrentGameTurn()

    if civType == g_CivTypeNames.Wanderers then
        nameTag = "LOC_ROAD_VISION_NAME"
        tooltipTag = "LOC_ROAD_VISION_TT"
        local lastTurn = player:GetProperty(g_playerPropertyKeys.RoadVisionTurn)
        if lastTurn ~= nil and currentTurn < lastTurn + WANDERER_ROAD_VISION_DURATION then
            status = Locale.Lookup("LOC_ROAD_VISION_ACTIVE_TT",
                lastTurn + WANDERER_ROAD_VISION_DURATION - currentTurn)
        elseif lastTurn ~= nil
            and currentTurn < lastTurn + WANDERER_ROAD_VISION_DURATION + WANDERER_ROAD_VISION_DEBOUNCE then
            status = Locale.Lookup("LOC_ROAD_VISION_RECHARGING_TT",
                lastTurn + WANDERER_ROAD_VISION_DURATION + WANDERER_ROAD_VISION_DEBOUNCE - currentTurn)
        end
    elseif civType == g_CivTypeNames.Pirates then
        nameTag = "LOC_BURN_TREASURE_MAP_NAME"
        tooltipTag = "LOC_BURN_TREASURE_MAP_TT"
        local lastTurn = player:GetProperty(g_playerPropertyKeys.BurnTreasureTurn)
        if lastTurn ~= nil and currentTurn < lastTurn + PIRATES_BURN_TREASURE_MAP_DEBOUNCE then
            status = Locale.Lookup("LOC_BURN_TREASURE_MAP_RECHARGING_TT",
                lastTurn + PIRATES_BURN_TREASURE_MAP_DEBOUNCE - currentTurn)
        end
    elseif civType == g_CivTypeNames.EdgeLords then
        nameTag = "LOC_GRIEVING_GIFT_NAME"
        tooltipTag = "LOC_GRIEVING_GIFT_TT"
        local charges = player:GetProperty(g_playerPropertyKeys.GrievingGiftCount) or 0
        status = Locale.Lookup("LOC_CIV_ROYALE_GLOBAL_ABILITY_CHARGES",
            charges, EDGELORDS_GRIEVING_GIFT_MAX_COUNT)
        local rechargeTurn = player:GetProperty(g_playerPropertyKeys.GrievingGiftTurn)
        if rechargeTurn ~= nil and currentTurn < rechargeTurn + EDGELORDS_GRIEVING_GIFT_DEBOUNCE then
            status = status .. ", " .. Locale.Lookup("LOC_GRIEVING_GIFT_RECHARGING_TT",
                rechargeTurn + EDGELORDS_GRIEVING_GIFT_DEBOUNCE - currentTurn)
        elseif charges <= 0 then
            status = status .. ", " .. Locale.Lookup("LOC_GRIEVING_GIFT_EMPTY_TT")
        end
    end

    if nameTag == nil then return nil end
    if status == nil then
        status = Locale.Lookup("LOC_CIV_ROYALE_GLOBAL_ABILITY_AVAILABLE")
    end

    local tooltip = Locale.Lookup(tooltipTag)
    tooltip = string.gsub(tooltip, "%[NEWLINE%]", ", ")
    tooltip = string.gsub(tooltip, ",%s*,", ",")
    local name = Locale.Lookup(nameTag)
    if string.sub(tooltip, 1, string.len(name)) == name then
        tooltip = string.sub(tooltip, string.len(name) + 1)
        tooltip = string.gsub(tooltip, "^%s*,%s*", "")
    end
    return name .. ", " .. tooltip .. ", " .. status
end

local function AddRoyaleTurnInfo(parts)
    if not CAIModSupport.IsCivRoyaleScenarioActive() then return end

    local currentTurn = Game.GetCurrentGameTurn()
    local nextSafeZoneTurn = Game:GetProperty(g_ObjectStateKeys.NextSafeZoneTurn)
    if nextSafeZoneTurn == -1 then
        table.insert(parts, Locale.Lookup("LOC_CIV_ROYALE_HUD_TURNS_UNTIL_RING_SHRINKS_MIN_SIZE"))
    elseif nextSafeZoneTurn ~= nil then
        table.insert(parts, Locale.Lookup("LOC_CIV_ROYALE_HUD_TURNS_UNTIL_RING_SHRINKS_B",
            math.max(0, nextSafeZoneTurn - currentTurn)))
    end

    local safeZonePhase = Game:GetProperty(g_ObjectStateKeys.SafeZonePhase) or 0
    local falloutDamage = Game.GetFalloutManager():GetFalloutDamageOverride()
    if falloutDamage == FalloutDamages.USE_FALLOUT_DEFAULT or falloutDamage == nil then
        falloutDamage = 0
    end
    table.insert(parts, Locale.Lookup("LOC_CIV_ROYALE_HUD_STORM_STRENGTH",
        safeZonePhase, falloutDamage))

    local playerID, player = CAIGameState.GetLocalPlayer()
    if player == nil then return end
    AddRoyaleWMDParts(parts, player)
    AddRoyaleSettlerWarning(parts, playerID, player)

    local ability = GetRoyaleAbilityParts(playerID, player)
    if ability ~= nil then
        table.insert(parts, ability)
    end
end

local function AddPiratesTurnInfo(parts)
    if not CAIModSupport.IsPiratesScenarioActive() then return end

    local _, player = CAIGameState.GetLocalPlayer()
    if player == nil then return end

    local treasury = player:GetTreasury()
    local goldPerTurn = math.floor(treasury:GetGoldYield() - treasury:GetTotalMaintenance())
    local goldBalance = math.floor(treasury:GetGoldBalance())
    table.insert(parts, Locale.Lookup("LOC_CAI_PIRATES_MORALE_TITLE"))
    table.insert(parts, Locale.Lookup("LOC_CAI_PIRATES_MORALE_GOLD", goldBalance))
    table.insert(parts, Locale.Lookup("LOC_CAI_PIRATES_MORALE_RATE", goldPerTurn))

    if goldPerTurn > 0 then
        table.insert(parts, Locale.Lookup("LOC_PIRATES_MORALE_TRACKER_PROFIT"))
        return
    elseif goldPerTurn == 0 then
        table.insert(parts, Locale.Lookup("LOC_PIRATES_MORALE_TRACKER_STABLE"))
        return
    end

    local currentTurn = Game.GetCurrentGameTurn()
    local lastHadGoldTurn = player:GetProperty(g_playerPropertyKeys.LastHadGoldTurn) or currentTurn
    if goldBalance > 0 then
        local turnsUntilMutiny = math.ceil(goldBalance / -goldPerTurn) + PIRATE_BANKRUPTCY_MUTINY_DELAY
        table.insert(parts, Locale.Lookup("LOC_PIRATES_MORALE_TRACKER_MUTINY_TURNS", turnsUntilMutiny))
    elseif currentTurn < lastHadGoldTurn + PIRATE_BANKRUPTCY_MUTINY_DELAY then
        local turnsUntilMutiny = lastHadGoldTurn + PIRATE_BANKRUPTCY_MUTINY_DELAY - currentTurn
        table.insert(parts, Locale.Lookup("LOC_PIRATES_MORALE_TRACKER_MUTINY_TURNS", turnsUntilMutiny))
    else
        local mutinyTurns = player:GetUnits():GetCount() - 1
        if mutinyTurns > 0 then
            table.insert(parts, Locale.Lookup("LOC_PIRATES_MORALE_TRACKER_TOTAL_MUTINY_TURNS", mutinyTurns))
        else
            table.insert(parts, Locale.Lookup("LOC_PIRATES_MORALE_TRACKER_NO_MORE_UNITS"))
        end
    end
end

local function BuildTurnTimeDateParts(includeClock)
    RefreshTurnsRemaining()
    RefreshTime()

    local parts = {}
    table.insert(parts, Locale.Lookup("LOC_TOP_PANEL_CURRENT_TURN") .. " " .. Controls.Turns:GetText())

    if not CAIModSupport.IsCivRoyaleScenarioActive() then
        local timerStr = GetTurnTimerString()
        if timerStr then
            table.insert(parts, timerStr)
        end
    end

    table.insert(parts, Controls.CurrentDate:GetText())
    if includeClock then
        table.insert(parts, Controls.Time:GetText())
    end
    AddRoyaleTurnInfo(parts)
    AddPiratesTurnInfo(parts)
    return parts
end

local function SpeakTurnTimeDate()
    Speak(table.concat(BuildTurnTimeDateParts(true), "[NEWLINE]"))
end

-- ===========================================================================
-- Yield detail readouts
-- ===========================================================================

local function IsIndentedTooltipLine(text)
    return text ~= nil and string.match(text, "^%s") ~= nil
end

local function GetOuterTooltipLines(tooltip)
    local lines = {}
    for index, line in ipairs(CAIText.SplitLines(tooltip)) do
        if index > 1 and not IsIndentedTooltipLine(line) then
            local cleanedLine = CAIText.TrimStart(line)
            table.insert(lines, cleanedLine)
        end
    end
    return lines
end

local function SpeakStatusDetails(label, tooltip, helpTooltip)
    local parts = GetOuterTooltipLines(tooltip)
    if #parts == 0 then
        table.insert(parts, Locale.Lookup("LOC_CAI_TOP_PANEL_NO_VALUE", label))
    else
        parts[1] = label .. ": " .. parts[1]
    end
    CAIText.AppendIfNonEmpty(parts, helpTooltip)
    Speak(table.concat(parts, ", "))
end

local function SpeakGoldDetails()
    local _, player = CAIGameState.GetLocalPlayer()
    if not player or not GameCapabilities.HasCapability("CAPABILITY_GOLD")
        or not GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then return end
    SpeakStatusDetails(Locale.Lookup("LOC_TOP_PANEL_GOLD"), GetGoldTooltip())
end

local function SpeakFaithDetails()
    local _, player = CAIGameState.GetLocalPlayer()
    if not player or not GameCapabilities.HasCapability("CAPABILITY_FAITH")
        or not GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then return end
    local pantheonProgress = nil
    local religion = player:GetReligion()
    if religion:GetPantheon() < 0 and not religion:CanCreatePantheon() then
        local requiredFaith = Game.GetReligion():GetMinimumFaithNextPantheon()
        pantheonProgress = Locale.Lookup("LOC_UI_RELIGION_WORKING_TOWARDS_PANTHEON") .. ": "
            .. CAIText.FormatBalance(religion:GetFaithBalance()) .. " / " .. CAIText.FormatBalance(requiredFaith) .. " "
            .. Locale.Lookup("LOC_TOP_PANEL_FAITH")
    end

    local parts = GetOuterTooltipLines(GetFaithTooltip())
    if pantheonProgress then table.insert(parts, 1, pantheonProgress) end
    if #parts == 0 then
        table.insert(parts, Locale.Lookup("LOC_CAI_TOP_PANEL_NO_VALUE", Locale.Lookup("LOC_TOP_PANEL_FAITH")))
    elseif not pantheonProgress then
        parts[1] = Locale.Lookup("LOC_TOP_PANEL_FAITH") .. ": " .. parts[1]
    end
    Speak(table.concat(parts, ", "))
end

local function SpeakTourismDetails()
    local _, player = CAIGameState.GetLocalPlayer()
    if not player or not GameCapabilities.HasCapability("CAPABILITY_TOURISM")
        or not GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then return end
    local rate = Round(player:GetStats():GetTourism(), 1)
    local tooltip = Locale.Lookup("LOC_WORLD_RANKINGS_OVERVIEW_CULTURE_TOURISM_RATE", rate)
    local breakdown = player:GetStats():GetTourismToolTip()
    if breakdown and breakdown ~= "" then tooltip = tooltip .. "[NEWLINE][NEWLINE]" .. breakdown end
    SpeakStatusDetails(Locale.Lookup("LOC_TOP_PANEL_TOURISM"), tooltip)
end

local function SpeakInfluenceDetails()
    local _, player = CAIGameState.GetLocalPlayer()
    if not player or not GameCapabilities.HasCapability("CAPABILITY_TOP_PANEL_ENVOYS") then return end
    local influence = player:GetInfluence()
    local tooltip = Locale.Lookup("LOC_TOP_PANEL_INFLUENCE_TOOLTIP_POINTS_THRESHOLD",
        influence:GetTokensPerThreshold(), influence:GetPointsThreshold())
        .. "[NEWLINE][NEWLINE]"
        .. Locale.Lookup("LOC_TOP_PANEL_INFLUENCE_TOOLTIP_POINTS_BALANCE", Round(influence:GetPointsEarned(), 1))
        .. "[NEWLINE]"
        .. Locale.Lookup("LOC_TOP_PANEL_INFLUENCE_TOOLTIP_POINTS_RATE", Round(influence:GetPointsPerTurn(), 1))
    SpeakStatusDetails(Locale.Lookup("LOC_TOP_PANEL_INFLUENCE"), tooltip,
        Locale.Lookup("LOC_TOP_PANEL_INFLUENCE_TOOLTIP_SOURCES_HELP"))
end

-- ===========================================================================
-- Strategic resource tree content
-- ===========================================================================

-- ===========================================================================
-- Input handler
-- ===========================================================================
local function OnCAITopPanelInputAction(actionId)
    if ContextPtr:IsHidden() then return end
    if IsReportOpeningAction(actionId)
        and not IsCAITutorialControlAllowed("LaunchBar_Hook_Reports") then
        Speak(Locale.Lookup("LOC_CAI_UI_BLOCKED_BY_TUTORIAL"))
        return
    end
    if actionId == ACTION_SPEAK_TURN_TIME_DATE then
        SpeakTurnTimeDate()
    elseif actionId == ACTION_SPEAK_CITY_WARNINGS then
        SpeakCityWarnings(false)
    elseif actionId == ACTION_SPEAK_CITY_WARNINGS_DETAILS then
        SpeakCityWarnings(true)
    elseif actionId == ACTION_SPEAK_GOLD then
        SpeakGold()
    elseif actionId == ACTION_SPEAK_GOLD_DETAILS then
        SpeakGoldDetails()
    elseif actionId == ACTION_SPEAK_FAITH then
        SpeakFaith()
    elseif actionId == ACTION_SPEAK_FAITH_DETAILS then
        SpeakFaithDetails()
    elseif actionId == ACTION_SPEAK_TOURISM then
        SpeakTourism()
    elseif actionId == ACTION_SPEAK_TOURISM_DETAILS then
        SpeakTourismDetails()
    elseif actionId == ACTION_SPEAK_INFLUENCE then
        SpeakFavor()
    elseif actionId == ACTION_SPEAK_INFLUENCE_DETAILS then
        SpeakInfluenceDetails()
    elseif actionId == ACTION_SPEAK_NUKES then
        SpeakNukes()
    elseif actionId == ACTION_OPEN_DIPLOMACY then
        if GameCapabilities.HasCapability("CAPABILITY_DIPLOMACY") then
            LuaEvents.TopPanel_OpenDiplomacyActionView()
        else
            Speak(Locale.Lookup("LOC_CAI_UI_DIPLOMACY_UNAVAILABLE"))
        end
    elseif actionId == ACTION_OPEN_REPORTS then
        if GameCapabilities.HasCapability("CAPABILITY_REPORTS_LIST") then
            LuaEvents.TopPanel_OpenReportsScreen()
        else
            Speak(Locale.Lookup("LOC_CAI_UI_REPORTS_UNAVAILABLE"))
        end
    elseif actionId == ACTION_OPEN_REPORTS_RESOURCES then
        if GameCapabilities.HasCapability("CAPABILITY_REPORTS_LIST") then
            LuaEvents.ReportsList_OpenResources()
        else
            Speak(Locale.Lookup("LOC_CAI_UI_REPORTS_UNAVAILABLE"))
        end
    elseif actionId == ACTION_OPEN_REPORTS_CITY_STATUS then
        if GameCapabilities.HasCapability("CAPABILITY_REPORTS_LIST") then
            LuaEvents.ReportsList_OpenCityStatus()
        else
            Speak(Locale.Lookup("LOC_CAI_UI_REPORTS_UNAVAILABLE"))
        end
    elseif actionId == ACTION_OPEN_REPORTS_GOSSIP then
        if not GameCapabilities.HasCapability("CAPABILITY_REPORTS_LIST") then
            Speak(Locale.Lookup("LOC_CAI_UI_REPORTS_UNAVAILABLE"))
        elseif GameCapabilities.HasCapability("CAPABILITY_GOSSIP_REPORT") then
            LuaEvents.ReportsList_OpenGossip()
        else
            Speak(Locale.Lookup("LOC_CAI_UI_GOSSIP_UNAVAILABLE"))
        end
    elseif actionId == ACTION_OPEN_GLOBAL_RESOURCES then
        if GameCapabilities.HasCapability("CAPABILITY_DIPLOMACY_DEALS") then
            LuaEvents.GlobalReportsList_OpenResources()
        else
            Speak(Locale.Lookup("LOC_CAI_UI_GLOBAL_RESOURCES_UNAVAILABLE"))
        end
    end
end

local function OnLocalPlayerTurnBegin()
    Speak(table.concat(BuildTurnTimeDateParts(false), "[NEWLINE]"))
end

local function OnLocalPlayerTurnEnd()
    Speak(Locale.Lookup("LOC_CAI_TOP_PANEL_TURN_ENDED"))
end

function OnShutdown()
    Events.InputActionStarted.Remove(OnCAITopPanelInputAction)
    Events.TurnTimerUpdated.Remove(OnTurnTimerUpdated)
    Events.LocalPlayerTurnBegin.Remove(OnLocalPlayerTurnBegin)
    Events.LocalPlayerTurnEnd.Remove(OnLocalPlayerTurnEnd)
end

ContextPtr:SetShutdown(OnShutdown)

Events.InputActionStarted.Add(OnCAITopPanelInputAction)
Events.TurnTimerUpdated.Add(OnTurnTimerUpdated)
Events.LocalPlayerTurnBegin.Add(OnLocalPlayerTurnBegin)
Events.LocalPlayerTurnEnd.Add(OnLocalPlayerTurnEnd)
