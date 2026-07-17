include("caiUtils")
include("hexCoordUtils_CAI")
include("Civ6Common")

local function GetCityPanelIncludeName()
    if GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_BLACKDEATH" then
        return "CityPanel_BlackDeathScenario"
    end

    if IsExpansion2Active() then
        return "CityPanel_Expansion2"
    end

    if IsExpansion1Active() then
        return "CityPanel_Expansion1"
    end

    return "CityPanel"
end

include(GetCityPanelIncludeName())

--#State
local mgr = ExposedMembers.CAI_UIManager
local m_IsGameStarted = false
local CITY_ACTION_CATEGORY = "LOC_OPTIONS_HOTKEY_CATEGORY_CITY"
local HexCoordUtils = CAIHexCoordUtils

info = ExposedMembers.CAIInfo or {}
ExposedMembers.CAIInfo = info

local CITY_INFO_BUCKETS = {
    Summary = { "Name", "Population", "Health", "Production", "Growth" },
    Info1 = { "Name", "Health" },
    Info2 = { "Production" },
    Info3 = { "Growth" },
    Info4 = { "BorderGrowth" },
    Info5 = { "Religion" },
    Info6 = { "Population", "Housing", "BuildingsOrLoyalty" },
    Info7 = { "VisibleYields" },
    Info8 = { "NormalFocusYields" },
    Info9 = { "FavoredFocusYields" },
    Info10 = { "IgnoredFocusYields" },
}
--#City Info Lookup

function GetCityInfoData(city)
    if city == nil then
        return nil, nil
    end

    local data = GetCityData(city)
    return data, city
end

--#City Info Formatting

function AppendCityInfo(results, value)
    if value ~= nil and value ~= "" then
        table.insert(results, value)
    end
end

function JoinCityInfo(parts, separator)
    local results = {}

    for _, part in ipairs(parts) do
        if part ~= nil and part ~= "" then
            table.insert(results, part)
        end
    end

    return table.concat(results, separator or ", ")
end

function GetCityInfoName(data)
    if data == nil or data.CityName == nil then
        return nil
    end

    return (data.IsCapital and "[ICON_Capital]" or "") .. Locale.ToUpper(Locale.Lookup(data.CityName))
end

function GetCityInfoPopulation(data)
    if data == nil then
        return nil
    end

    return Locale.Lookup("LOC_CAI_CITY_POPULATION", data.Population)
end

function GetCityInfoHealth(data)
    if data == nil then
        return nil
    end

    local tooltip = Locale.Lookup("LOC_HUD_UNIT_PANEL_HEALTH_TOOLTIP", data.HitpointsCurrent, data.HitpointsTotal)
    if data.CityWallTotalHP > 0 then
        tooltip = tooltip ..
            "[NEWLINE]" ..
            Locale.Lookup("LOC_HUD_UNIT_PANEL_WALL_HEALTH_TOOLTIP", data.CityWallCurrentHP, data.CityWallTotalHP)
    end

    return tooltip
end

function GetCityInfoYieldText(value, icon)
    return icon .. toPlusMinusString(value)
end

function GetCityInfoPercentText(value)
    if value == nil then
        return nil
    end

    return tostring(math.floor((value * 100) + 0.5)) .. "%"
end

function GetCityInfoValueText(value)
    if value == nil then
        return nil
    end

    local rounded = math.floor((value * 10) + 0.5) / 10
    if math.abs(rounded - math.floor(rounded)) < 0.05 then
        return Locale.ToNumber(math.floor(rounded))
    end

    return Locale.ToNumber(rounded, "#.#")
end

function GetCityInfoCurrentProgressText(value)
    local percentText = GetCityInfoPercentText(value)
    if percentText == nil then
        return nil
    end

    return Locale.Lookup("LOC_CAI_CURRENT_PROGRESS") .. ", " .. percentText
end

function GetCityInfoNextTurnProgressText(value)
    local percentText = GetCityInfoPercentText(value)
    if percentText == nil then
        return nil
    end

    return Locale.Lookup("LOC_CAI_NEXT_TURN_PROGRESS") .. ", " .. percentText
end

function GetCityInfoLabelValueText(locKey, value)
    local valueText = GetCityInfoValueText(value)
    if valueText == nil then
        return nil
    end

    return Locale.Lookup(locKey) .. ", " .. valueText
end

function GetCityInfoYieldState(data, yieldType)
    if data == nil or data.YieldFilters == nil then
        return nil
    end

    return data.YieldFilters[yieldType]
end

function GetCityInfoYieldEntry(data, yieldType, value, icon)
    if data == nil then
        return nil
    end

    local yieldInfo = GameInfo.Yields[yieldType]
    if yieldInfo == nil then
        return nil
    end

    return Locale.Lookup(yieldInfo.Name) .. ", " .. GetCityInfoYieldText(value, icon)
end

function GetCityInfoCultureYield(data)
    if data == nil then
        return nil
    end

    return GetCityInfoYieldText(data.CulturePerTurn, "[ICON_Culture]")
end

function GetCityInfoFoodYield(data)
    if data == nil then
        return nil
    end

    return GetCityInfoYieldText(data.FoodPerTurn, "[ICON_Food]")
end

function GetCityInfoProductionYield(data)
    if data == nil then
        return nil
    end

    return GetCityInfoYieldText(data.ProductionPerTurn, "[ICON_Production]")
end

function GetCityInfoScienceYield(data)
    if data == nil then
        return nil
    end

    return GetCityInfoYieldText(data.SciencePerTurn, "[ICON_Science]")
end

function GetCityInfoFaithYield(data)
    if data == nil then
        return nil
    end

    return GetCityInfoYieldText(data.FaithPerTurn, "[ICON_Faith]")
end

function GetCityInfoGoldYield(data)
    if data == nil then
        return nil
    end

    return GetCityInfoYieldText(data.GoldPerTurn, "[ICON_Gold]")
end

function GetCityInfoVisibleYields(data)
    local results = {}

    AppendCityInfo(results, GetCityInfoYieldEntry(data, YieldTypes.CULTURE, data.CulturePerTurn, "[ICON_Culture]"))
    AppendCityInfo(results, GetCityInfoYieldEntry(data, YieldTypes.FOOD, data.FoodPerTurn, "[ICON_Food]"))
    AppendCityInfo(results,
        GetCityInfoYieldEntry(data, YieldTypes.PRODUCTION, data.ProductionPerTurn, "[ICON_Production]"))
    AppendCityInfo(results, GetCityInfoYieldEntry(data, YieldTypes.SCIENCE, data.SciencePerTurn, "[ICON_Science]"))
    AppendCityInfo(results, GetCityInfoYieldEntry(data, YieldTypes.FAITH, data.FaithPerTurn, "[ICON_Faith]"))
    AppendCityInfo(results, GetCityInfoYieldEntry(data, YieldTypes.GOLD, data.GoldPerTurn, "[ICON_Gold]"))

    return results
end

function GetCityInfoFilteredYields(data, filterState)
    if data == nil then
        return {}
    end

    local results = {}
    local visibleYields = {
        { Type = YieldTypes.CULTURE,    Value = data.CulturePerTurn,    Icon = "[ICON_Culture]" },
        { Type = YieldTypes.FOOD,       Value = data.FoodPerTurn,       Icon = "[ICON_Food]" },
        { Type = YieldTypes.PRODUCTION, Value = data.ProductionPerTurn, Icon = "[ICON_Production]" },
        { Type = YieldTypes.SCIENCE,    Value = data.SciencePerTurn,    Icon = "[ICON_Science]" },
        { Type = YieldTypes.FAITH,      Value = data.FaithPerTurn,      Icon = "[ICON_Faith]" },
        { Type = YieldTypes.GOLD,       Value = data.GoldPerTurn,       Icon = "[ICON_Gold]" },
    }

    for _, yieldData in ipairs(visibleYields) do
        local yieldState = GetCityInfoYieldState(data, yieldData.Type)
        if filterState == nil then
            if yieldState ~= YIELD_STATE.FAVORED and yieldState ~= YIELD_STATE.IGNORED then
                AppendCityInfo(results, GetCityInfoYieldEntry(data, yieldData.Type, yieldData.Value, yieldData.Icon))
            end
        elseif yieldState == filterState then
            AppendCityInfo(results, GetCityInfoYieldEntry(data, yieldData.Type, yieldData.Value, yieldData.Icon))
        end
    end

    return results
end

function GetCityInfoBuildings(data)
    if data == nil then
        return nil
    end

    return Locale.Lookup("LOC_HUD_CITY_BUILDINGS") .. ", " .. tostring(data.BuildingsNum)
end

function GetCityInfoReligionFollowers(data)
    if data == nil then
        return nil
    end

    if not GameCapabilities.HasCapability("CAPABILITY_CITY_HUD_RELIGION_TAB") then
        return nil
    end

    return Locale.Lookup("LOC_HUD_CITY_RELIGIOUS_CITIZENS") .. ", " .. tostring(data.ReligionFollowers)
end

function GetCityInfoAmenities(data)
    if data == nil then
        return nil
    end

    local amenitiesNumText = data.AmenitiesNetAmount
    if data.AmenitiesNetAmount > 0 then
        amenitiesNumText = "+" .. amenitiesNumText
    end

    return Locale.Lookup("LOC_HUD_CITY_AMENITIES") .. ", " .. tostring(amenitiesNumText)
end

function GetCityInfoHousing(data)
    if data == nil then
        return nil
    end

    return Locale.Lookup("LOC_HUD_CITY_HOUSING") .. ", " .. tostring(data.Population) .. " of " .. tostring(data.Housing)
end

function GetCityInfoGrowth(data)
    if data == nil then
        return nil
    end

    local progressText = JoinCityInfo({
        GetCityInfoCurrentProgressText(data.CurrentFoodPercent),
        GetCityInfoNextTurnProgressText(data.FoodPercentNextTurn),
    }, ", ")

    if data.Occupied then
        return JoinCityInfo({
            tostring(math.abs(data.TurnsUntilGrowth)) ..
            " " .. Locale.ToUpper(Locale.Lookup("LOC_HUD_CITY_GROWTH_OCCUPIED")),
            progressText,
        }, ", ")
    elseif data.TurnsUntilGrowth >= 0 then
        return JoinCityInfo({
            tostring(math.abs(data.TurnsUntilGrowth)) ..
            " " .. Locale.ToUpper(Locale.Lookup("LOC_HUD_CITY_TURNS_UNTIL_GROWTH", data.TurnsUntilGrowth)),
            progressText,
        }, ", ")
    else
        return JoinCityInfo({
            tostring(math.abs(data.TurnsUntilGrowth)) ..
            " " .. Locale.ToUpper(Locale.Lookup("LOC_HUD_CITY_TURNS_UNTIL_LOSS", math.abs(data.TurnsUntilGrowth))),
            progressText,
        }, ", ")
    end
end

function GetCityBorderGrowthDirectionText(city, plotId)
    if city == nil or plotId == nil or plotId == -1 or HexCoordUtils == nil then
        return nil
    end

    local plot = Map.GetPlotByIndex(plotId)
    if plot == nil then
        return nil
    end

    local direction = HexCoordUtils.directionString(city:GetX(), city:GetY(), plot:GetX(), plot:GetY())
    if direction == nil or direction == "" then
        return nil
    end

    return direction
end

function GetCityBorderGrowthStoredRequiredText(currentCulture, cost)
    local currentCultureText = GetCityInfoValueText(currentCulture)
    local costText = GetCityInfoValueText(cost)
    if currentCultureText == nil or costText == nil then
        return nil
    end

    return JoinCityInfo({
        Locale.Lookup("LOC_CAI_CITY_TOTAL_CULTURE") .. ": " .. currentCultureText,
        Locale.Lookup("LOC_HUD_CITY_REQUIRED") .. ": " .. costText,
    }, ", ")
end

function GetCityBorderGrowthPerTurnText(currentYield)
    local currentYieldText = GetCityInfoValueText(currentYield)
    if currentYieldText == nil then
        return nil
    end

    return currentYieldText ..
        " " ..
        Locale.ToLower(Locale.Lookup("LOC_HUD_CITY_CULTURE_PER_TURN", currentYieldText)):gsub(
            "^" .. currentYieldText .. "%s*", "")
end

function GetCityBorderGrowth(data, city)
    if city == nil or not HasCapability("CAPABILITY_CULTURE") then
        return nil
    end

    if IsExpansion2Active() then
        local localPlayerID = Game.GetLocalPlayer()
        local resolutions = Game.GetWorldCongress():GetResolutions(localPlayerID)
        if resolutions ~= nil then
            for _, resolutionData in pairs(resolutions) do
                if type(resolutionData) == "table" and
                    resolutionData.ChosenOption == "LOC_WORLD_CONGRESS_NO_CULTURE_BORDER_GROWTH_DESC" and
                    tonumber(resolutionData.ChosenThing) == localPlayerID then
                    return nil
                end
            end
        end
    end

    local cityCulture = city:GetCulture()
    if cityCulture == nil then
        return nil
    end

    local nextGrowthPlot = cityCulture:GetNextPlot()
    if nextGrowthPlot == nil or nextGrowthPlot == -1 then
        return nil
    end

    local cost = cityCulture:GetNextPlotCultureCost()
    local currentCulture = cityCulture:GetCurrentCulture()
    local currentYield = cityCulture:GetCultureYield()
    if cost == nil or cost <= 0 or currentCulture == nil or currentYield == nil then
        return nil
    end

    local currentGrowth = math.max(math.min(currentCulture / cost, 1.0), 0)
    local nextTurnGrowth = math.max(math.min((currentCulture + currentYield) / cost, 1.0), 0)
    local turnsRemaining = cityCulture:GetTurnsUntilExpansion()

    return JoinCityInfo({
        Locale.Lookup("LOC_HUD_CITY_BORDER_EXPANSION", turnsRemaining),
        GetCityBorderGrowthDirectionText(city, nextGrowthPlot),
        GetCityBorderGrowthStoredRequiredText(currentCulture, cost),
        GetCityBorderGrowthPerTurnText(currentYield),
        GetCityInfoCurrentProgressText(currentGrowth),
        GetCityInfoNextTurnProgressText(nextTurnGrowth),
    }, ", ")
end

function GetCityInfoProduction(data)
    if data == nil then
        return nil
    end

    if data.CurrentProductionName == Locale.Lookup("LOC_HUD_CITY_PRODUCTION_NOTHING_PRODUCED")
        or data.CurrentProductionName == Locale.Lookup("LOC_HUD_CITY_NOTHING_PRODUCED")
        or (data.CurrentTurnsLeft <= 0 and (data.CurrentProductionStats == nil or data.CurrentProductionStats == "")
            and (data.CurrentProductionDescription == nil or data.CurrentProductionDescription == "")) then
        return Locale.ToUpper(Locale.Lookup("LOC_HUD_CITY_NOTHING_PRODUCED"))
    end

    return JoinCityInfo({
        data.CurrentProductionName,
        tostring(data.CurrentTurnsLeft) ..
        " " .. Locale.ToUpper(Locale.Lookup("LOC_HUD_CITY_TURNS_UNTIL_COMPLETED", data.CurrentTurnsLeft)),
        GetCityInfoCurrentProgressText(data.CurrentProdPercent),
        GetCityInfoNextTurnProgressText(data.ProdPercentNextTurn),
        data.CurrentProductionStats,
        data.CurrentProductionDescription,
    }, ", ")
end

function GetCityInfoBuildingsOrLoyalty(data, city)
    if data == nil then
        return nil
    end

    if (IsExpansion2Active() or IsExpansion1Active()) and city ~= nil then
        local culturalIdentity = city:GetCulturalIdentity()
        if culturalIdentity ~= nil then
            return Locale.Lookup("LOC_CULTURAL_IDENTITY_LOYALTY_SUBSECTION") .. ", " ..
                tostring(Round(culturalIdentity:GetLoyalty(), 1))
        end
    end

    return Locale.Lookup("LOC_HUD_CITY_BUILDINGS") .. ", " .. tostring(data.BuildingsNum)
end

--#City Info Registry

CityInfo = {
    Name = function(data, city)
        return GetCityInfoName(data)
    end,

    Health = function(data, city)
        return GetCityInfoHealth(data)
    end,

    Population = function(data, city)
        return GetCityInfoPopulation(data)
    end,

    Growth = function(data, city)
        return GetCityInfoGrowth(data)
    end,

    BorderGrowth = function(data, city)
        return GetCityBorderGrowth(data, city)
    end,

    Production = function(data, city)
        return GetCityInfoProduction(data)
    end,

    Housing = function(data, city)
        return GetCityInfoHousing(data)
    end,

    Religion = function(data, city)
        return GetCityInfoReligionFollowers(data)
    end,

    BuildingsOrLoyalty = function(data, city)
        return GetCityInfoBuildingsOrLoyalty(data, city)
    end,

    VisibleYields = function(data, city)
        return GetCityInfoVisibleYields(data)
    end,

    NormalFocusYields = function(data, city)
        return GetCityInfoFilteredYields(data, nil)
    end,

    FavoredFocusYields = function(data, city)
        return GetCityInfoFilteredYields(data, YIELD_STATE.FAVORED)
    end,

    IgnoredFocusYields = function(data, city)
        return GetCityInfoFilteredYields(data, YIELD_STATE.IGNORED)
    end,
}

CityInfo.BuildingCount = CityInfo.BuildingsOrLoyalty
CityInfo.ReligiousFollowersCount = CityInfo.Religion
CityInfo.AmenitiesSummary = function(data, city) return GetCityInfoAmenities(data) end
CityInfo.HousingSummary = CityInfo.Housing
CityInfo.GrowthSummary = CityInfo.Growth
CityInfo.ProductionSummary = CityInfo.Production
CityInfo.BuildingsAmenitiesSummary = function(data, city)
    return {
        GetCityInfoBuildingsOrLoyalty(data, city),
        GetCityInfoAmenities(data),
    }
end

info.CityInfo = CityInfo
info.CityInfoBuckets = CITY_INFO_BUCKETS
CityInfoActionMap = {}
CityInfoFallbacks = {
    Religion                = "LOC_CAI_CITY_NO_RELIGION_INFO",
    ReligiousFollowersCount = "LOC_CAI_CITY_NO_RELIGION_INFO",
    BorderGrowth            = "LOC_CAI_CITY_NO_BORDER_GROWTH_INFO",
    NormalFocusYields       = "LOC_CAI_CITY_NO_NORMAL_FOCUS_YIELDS",
    FavoredFocusYields      = "LOC_CAI_CITY_NO_FAVORED_YIELDS",
    IgnoredFocusYields      = "LOC_CAI_CITY_NO_IGNORED_YIELDS",
}
CityActionMap = {}
CityActionList = nil
CityActionCategoryIds = nil
--#Action Metadata

function GetActionText(actionId, getter)
    if actionId == nil or getter == nil then
        return ""
    end

    local locKey = getter(actionId)
    if locKey == nil or locKey == "" then
        return ""
    end

    return Locale.Lookup(locKey)
end

function GetActionNameText(actionId)
    return GetActionText(actionId, Input.GetActionName)
end

function GetActionDescriptionText(actionId)
    return GetActionText(actionId, Input.GetActionDescription)
end

function GetActionBindingText(actionId)
    if actionId == nil then
        return nil
    end

    local bindings = {}
    local g1 = Input.GetGestureDisplayString(actionId, 0)
    local g2 = Input.GetGestureDisplayString(actionId, 1)
    if g1 ~= nil and g1 ~= "" then
        table.insert(bindings, g1)
    end
    if g2 ~= nil and g2 ~= "" then
        table.insert(bindings, g2)
    end

    if #bindings == 0 then
        return nil
    end

    return table.concat(bindings, ", ")
end

function GetActionNameWithBindingText(actionId)
    local label = GetActionNameText(actionId)
    local binding = GetActionBindingText(actionId)
    if binding == nil then
        return label
    end

    return label .. ": " .. binding
end

function GetCityChangeProductionTooltip()
    local data = GetCityInfoData(UI.GetHeadSelectedCity())
    return GetCityInfoProduction(data) or ""
end

function GetActionDescriptionIfDistinct(actionId)
    if actionId == Input.GetActionId("CityChangeProduction") then
        return GetCityChangeProductionTooltip()
    end

    local label = GetActionNameText(actionId)
    local tooltip = GetActionDescriptionText(actionId)
    if tooltip == "" or tooltip == label then
        return ""
    end

    return tooltip
end

function IsControlAvailable(control, allowDisabled)
    if control == nil or control:IsHidden() then
        return false
    end

    if not allowDisabled and control:IsDisabled() then
        return false
    end

    return true
end

function IsCityPanelActionAvailable(control)
    return UI.GetHeadSelectedCity() ~= nil and ContextPtr:IsHidden() == false and IsControlAvailable(control, false)
end

function IsCityPanelActionVisible(control)
    return UI.GetHeadSelectedCity() ~= nil and ContextPtr:IsHidden() == false and IsControlAvailable(control, true)
end

--#City Action Menu

function ToggleCityPanelCheck(control)
    if control == nil or control:IsDisabled() or control:IsHidden() then
        return
    end

    control:SetAndCall(not control:IsChecked())
end

function IsVanillaProductionPanelVisible()
    local productionPanel = ContextPtr:LookUpControl("/InGame/ProductionPanel")
    return productionPanel ~= nil and not productionPanel:IsHidden()
end

function OpenOrToggleCityProduction()
    if Controls.ChangeProductionCheck == nil or Controls.ChangeProductionCheck:IsDisabled()
        or Controls.ChangeProductionCheck:IsHidden() then
        return
    end

    if not IsVanillaProductionPanelVisible() then
        if LuaEvents.CityPanel_ProductionOpen ~= nil then
            LuaEvents.CityPanel_ProductionOpen()
            return
        end
    end

    ToggleCityPanelCheck(Controls.ChangeProductionCheck)
end

local CITY_ACTION_LIST_ID = "CAICityPanel_ActionList"

function CloseCityActionList()
    if CityActionList ~= nil then
        mgr:RemoveFromStack(CITY_ACTION_LIST_ID)
        CityActionList = nil
    end
end

function BuildCityActionData(helper, isEnabled)
    return {
        helper = helper,
        IsEnabled = isEnabled or function()
            return true
        end,
    }
end

function GetCityCategoryActionIds()
    if CityActionCategoryIds ~= nil then
        return CityActionCategoryIds
    end

    local excluded = {
        [Input.GetActionId("SelectionActions")] = true,
    }

    CityActionCategoryIds = {}
    for _, actionId in ipairs(GetInputActionsByCategory(CITY_ACTION_CATEGORY)) do
        if not excluded[actionId] and CityActionMap[actionId] ~= nil then
            table.insert(CityActionCategoryIds, actionId)
        end
    end

    return CityActionCategoryIds
end

function GetOrderedCityActionIds()
    local ordered = {
        Input.GetActionId("CityChangeProduction"),
        Input.GetActionId("CityManageCity"),
        Input.GetActionId("CityPurchaseWithGold"),
        Input.GetActionId("CityPurchaseWithFaith"),
        Input.GetActionId("CityToggleOverview"),
        Input.GetActionId("CityChangeCitizenYieldFocus"),
    }

    local seen = {}
    local results = {}

    for _, actionId in ipairs(ordered) do
        if actionId ~= nil and CityActionMap[actionId] ~= nil and not seen[actionId] then
            seen[actionId] = true
            table.insert(results, actionId)
        end
    end

    for _, actionId in ipairs(GetCityCategoryActionIds()) do
        if actionId ~= nil and CityActionMap[actionId] ~= nil and not seen[actionId] then
            seen[actionId] = true
            table.insert(results, actionId)
        end
    end

    return results
end

function CanToggleCombinedCityManagement()
    local canManage = IsCityPanelActionAvailable(Controls.ManageCitizensCheck)
    local canPurchase = GameCapabilities.HasCapability("CAPABILITY_GOLD")
        and IsCityPanelActionAvailable(Controls.PurchaseTileCheck)
    return canManage or canPurchase
end

function ToggleCombinedCityManagement()
    local canManage = IsCityPanelActionAvailable(Controls.ManageCitizensCheck)
    local canPurchase = GameCapabilities.HasCapability("CAPABILITY_GOLD")
        and IsCityPanelActionAvailable(Controls.PurchaseTileCheck)

    if not canManage and not canPurchase then
        return
    end

    local allActive = (not canManage or Controls.ManageCitizensCheck:IsChecked())
        and (not canPurchase or Controls.PurchaseTileCheck:IsChecked())
    local targetState = not allActive

    if canPurchase and Controls.PurchaseTileCheck:IsChecked() ~= targetState then
        Controls.PurchaseTileCheck:SetAndCall(targetState)
    end

    if canManage and Controls.ManageCitizensCheck:IsChecked() ~= targetState then
        Controls.ManageCitizensCheck:SetAndCall(targetState)
    end
end

function EnsureCityOverviewPanelOpen()
    if Controls.ToggleOverviewPanel == nil or Controls.ToggleOverviewPanel:IsChecked() then
        return
    end

    Controls.ToggleOverviewPanel:SetAndCall(true)
end

function OpenCityOverviewLoyalty()
    if UI.GetHeadSelectedCity() == nil or ContextPtr:IsHidden() then
        return
    end

    EnsureCityOverviewPanelOpen()
    if LuaEvents.CityPanel_ToggleOverviewLoyalty ~= nil then
        LuaEvents.CityPanel_ToggleOverviewLoyalty()
    end
end

function OpenCityOverviewPower()
    if UI.GetHeadSelectedCity() == nil or ContextPtr:IsHidden() then
        return
    end

    EnsureCityOverviewPanelOpen()
    if LuaEvents.CityPanel_ToggleOverviewPower ~= nil then
        LuaEvents.CityPanel_ToggleOverviewPower()
    end
end

function CanOpenAnyCityOverviewTab()
    return UI.GetHeadSelectedCity() ~= nil
        and ContextPtr:IsHidden() == false
        and Controls.ToggleOverviewPanel ~= nil
        and not Controls.ToggleOverviewPanel:IsHidden()
        and not Controls.ToggleOverviewPanel:IsDisabled()
end

function IsOverviewTabControlAvailable(control)
    if control == nil then
        return false
    end

    if not control:IsHidden() and not control:IsDisabled() then
        return true
    end

    return CanOpenAnyCityOverviewTab()
end

function OpenCityOverviewBuildings()
    if not IsOverviewTabControlAvailable(Controls.BreakdownButton) then
        return
    end

    EnsureCityOverviewPanelOpen()
    if LuaEvents.CityPanel_ToggleOverviewBuildings ~= nil then
        LuaEvents.CityPanel_ToggleOverviewBuildings()
    end
end

function OpenCityOverviewReligion()
    if not CanOpenAnyCityOverviewTab() then
        return
    end

    if Controls.ReligionButton ~= nil and (Controls.ReligionButton:IsHidden() or Controls.ReligionButton:IsDisabled()) then
        return
    end

    if not GameCapabilities.HasCapability("CAPABILITY_CITY_HUD_RELIGION_TAB") then
        return
    end

    EnsureCityOverviewPanelOpen()
    if LuaEvents.CityPanel_ToggleOverviewReligion ~= nil then
        LuaEvents.CityPanel_ToggleOverviewReligion()
    end
end

function OpenCityOverviewCitizens()
    if not IsOverviewTabControlAvailable(Controls.CitizensGrowthButton) then
        return
    end

    EnsureCityOverviewPanelOpen()
    if LuaEvents.CityPanel_ToggleOverviewCitizens ~= nil then
        LuaEvents.CityPanel_ToggleOverviewCitizens()
    end
end

function OpenCityOverviewAmenities()
    if not IsOverviewTabControlAvailable(Controls.AmenitiesButton) then
        return
    end

    OpenCityOverviewCitizens()
end

function OpenCityOverviewHousing()
    if not IsOverviewTabControlAvailable(Controls.HousingButton) then
        return
    end

    OpenCityOverviewCitizens()
end

function GetDistrictDisplayName(district)
    if district == nil then
        return nil
    end

    local districtDef = GameInfo.Districts[district:GetType()]
    if districtDef == nil or districtDef.Name == nil then
        return nil
    end

    return Locale.Lookup(districtDef.Name)
end

function IsDistrictInCity(district, city)
    if district == nil or city == nil then
        return false
    end

    local districtCity = district:GetCity()
    return districtCity ~= nil and districtCity:GetID() == city:GetID()
end

function IsCityCenterDistrict(district)
    return district ~= nil and district:GetType() == GameInfo.Districts["DISTRICT_CITY_CENTER"].Index
end

function GetDistrictPlot(district)
    if district == nil then
        return nil
    end

    return Map.GetPlot(district:GetX(), district:GetY())
end

function GetCityRangeStrikeActions(city)
    local actions = {}
    if city == nil or city:GetOwner() ~= Game.GetLocalPlayer() then
        return actions
    end

    if CityManager.CanStartCommand(city, CityCommandTypes.RANGE_ATTACK) then
        table.insert(actions, {
            Label = Locale.Lookup("LOC_CAI_CITY_ACTION_RANGE_STRIKE_CITY"),
            Tooltip = Locale.Lookup("LOC_CAI_CITY_ACTION_RANGE_STRIKE_CITY_TOOLTIP"),
            Action = function()
                UI.SelectCity(city)
                UI.SetInterfaceMode(InterfaceModeTypes.CITY_RANGE_ATTACK)
            end,
        })
    end

    local player = Players[city:GetOwner()]
    local districts = player ~= nil and player:GetDistricts() or nil
    if districts == nil or districts.Members == nil then
        return actions
    end

    for _, district in districts:Members() do
        if district ~= nil then
            if IsDistrictInCity(district, city) and not IsCityCenterDistrict(district) and
                CityManager.CanStartCommand(district, CityCommandTypes.RANGE_ATTACK) then
                local districtName = GetDistrictDisplayName(district)
                if districtName ~= nil then
                    table.insert(actions, {
                        Label = Locale.Lookup("LOC_CAI_CITY_ACTION_RANGE_STRIKE_DISTRICT", districtName),
                        Tooltip = Locale.Lookup("LOC_CAI_CITY_ACTION_RANGE_STRIKE_DISTRICT_TOOLTIP", districtName),
                        Action = function()
                            local districtPlot = GetDistrictPlot(district)
                            if districtPlot ~= nil then
                                LuaEvents.CAICursorMoveTo(districtPlot:GetIndex(), "select")
                            end
                            UI.DeselectAll()
                            UI.SelectDistrict(district)
                            UI.SetInterfaceMode(InterfaceModeTypes.DISTRICT_RANGE_ATTACK)
                        end,
                    })
                end
            end
        end
    end

    return actions
end

function CanDistrictPerformWMDStrike(city, districtPlot, wmdType)
    if city == nil or districtPlot == nil or wmdType == nil then
        return false
    end

    local parameters = {}
    parameters[CityCommandTypes.PARAM_WMD_TYPE] = wmdType
    parameters[CityCommandTypes.PARAM_X0] = districtPlot:GetX()
    parameters[CityCommandTypes.PARAM_Y0] = districtPlot:GetY()

    local results = CityManager.GetCommandTargets(city, CityCommandTypes.WMD_STRIKE, parameters)
    local plots = results ~= nil and results[CityCommandResults.PLOTS] or nil
    return plots ~= nil
end

function BuildDistrictWMDStrikeAction(city, district, districtPlot, wmdDef)
    if city == nil or district == nil or districtPlot == nil or wmdDef == nil or wmdDef.Name == nil then
        return nil
    end

    local districtName = GetDistrictDisplayName(district)
    if districtName == nil then
        return nil
    end

    local weaponName = Locale.Lookup(wmdDef.Name)
    return {
        Label = Locale.Lookup("LOC_CAI_CITY_ACTION_WMD_STRIKE_DISTRICT", districtName, weaponName),
        Tooltip = Locale.Lookup("LOC_CAI_CITY_ACTION_WMD_STRIKE_DISTRICT_TOOLTIP", districtName, weaponName),
        Action = function()
            LuaEvents.CAICursorMoveTo(districtPlot:GetIndex(), "select")
            if UI.GetInterfaceMode() == InterfaceModeTypes.ICBM_STRIKE then
                UI.SetInterfaceMode(InterfaceModeTypes.SELECTION)
            end
            UI.SelectCity(city)
            UILens.SetActive("Default")
            local parameters = {}
            parameters[CityCommandTypes.PARAM_WMD_TYPE] = wmdDef.Index
            parameters[CityCommandTypes.PARAM_X0] = districtPlot:GetX()
            parameters[CityCommandTypes.PARAM_Y0] = districtPlot:GetY()
            UI.SetInterfaceMode(InterfaceModeTypes.ICBM_STRIKE, parameters)
        end,
    }
end

function GetCityWMDStrikeActions(city)
    local actions = {}
    if city == nil or city:GetOwner() ~= Game.GetLocalPlayer() then
        return actions
    end

    local player = Players[city:GetOwner()]
    local districts = player ~= nil and player:GetDistricts() or nil
    local playerWMDs = player ~= nil and player:GetWMDs() or nil
    if districts == nil or districts.Members == nil or playerWMDs == nil then
        return actions
    end

    local supportedWMDTypes = {
        GameInfo.WMDs["WMD_NUCLEAR_DEVICE"],
        GameInfo.WMDs["WMD_THERMONUCLEAR_DEVICE"],
    }

    for _, district in districts:Members() do
        if district ~= nil and IsDistrictInCity(district, city) and not IsCityCenterDistrict(district) then
            local districtPlot = GetDistrictPlot(district)
            if districtPlot ~= nil then
                for _, wmdDef in ipairs(supportedWMDTypes) do
                    if wmdDef ~= nil and playerWMDs:GetWeaponCount(wmdDef.Index) > 0 and
                        CanDistrictPerformWMDStrike(city, districtPlot, wmdDef.Index) then
                        local action = BuildDistrictWMDStrikeAction(city, district, districtPlot, wmdDef)
                        if action ~= nil then
                            table.insert(actions, action)
                        end
                    end
                end
            end
        end
    end

    return actions
end

local function MakeCityActionMenuItem(idPrefix, getLabel, getTooltip, onActivate)
    local item = mgr:CreateWidget(mgr:GenerateWidgetId(idPrefix), "MenuItem", {
        Label   = getLabel,
        Tooltip = getTooltip,
    })
    item:SetFocusSound("Main_Menu_Mouse_Over")
    item:On("activate", function()
        onActivate()
        CloseCityActionList()
    end)
    return item
end

function BuildCityActionList()
    local data, city = GetCityInfoData(UI.GetHeadSelectedCity())
    local cityName = GetCityInfoName(data) or Locale.Lookup("LOC_CAI_CITY_ACTIONS")
    local list = mgr:CreateWidget(CITY_ACTION_LIST_ID, "List", {
        Label = function() return Locale.Lookup("LOC_CAI_SELECTION_ACTIONS_FOR", cityName) end,
    })

    list:AddInputBindings({
        {
            Key         = Keys.VK_ESCAPE,
            MSG         = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_CLOSE",
            Action      = function()
                CloseCityActionList(); return true
            end,
        },
    })

    for _, strikeAction in ipairs(GetCityRangeStrikeActions(city)) do
        local current = strikeAction
        list:AddChild(MakeCityActionMenuItem("CAICityPanelRangeStrikeItem",
            function() return current.Label end,
            function() return current.Tooltip end,
            current.Action))
    end

    for _, wmdAction in ipairs(GetCityWMDStrikeActions(city)) do
        local current = wmdAction
        list:AddChild(MakeCityActionMenuItem("CAICityPanelWMDStrikeItem",
            function() return current.Label end,
            function() return current.Tooltip end,
            current.Action))
    end

    for _, actionId in ipairs(GetOrderedCityActionIds()) do
        local actionData = CityActionMap[actionId]
        if actionData ~= nil and actionData.IsEnabled() then
            local currentActionId = actionId
            list:AddChild(MakeCityActionMenuItem("CAICityPanelMenuItem",
                function() return GetActionNameWithBindingText(currentActionId) end,
                function() return GetActionDescriptionIfDistinct(currentActionId) end,
                actionData.helper))
        end
    end

    return list
end

function OpenCityActionList()
    if mgr == nil or UI.GetHeadSelectedCity() == nil or ContextPtr:IsHidden() then
        return
    end

    if CityActionList ~= nil then
        CloseCityActionList()
    end

    CityActionList = BuildCityActionList()
    if CityActionList ~= nil and CityActionList.Children ~= nil and #CityActionList.Children > 0 then
        mgr:Push(CityActionList, { priority = PopupPriority.Low })
    else
        CityActionList = nil
    end
end

--#Citizen Yield Focus

local CAI_YIELD_FOCUS_YIELDS = {
    { Type = YieldTypes.FOOD },
    { Type = YieldTypes.PRODUCTION },
    { Type = YieldTypes.GOLD },
    { Type = YieldTypes.SCIENCE },
    { Type = YieldTypes.CULTURE },
    { Type = YieldTypes.FAITH },
}

local CAI_YIELD_FOCUS_LIST_ID = "CAICityYieldFocusList"

function CAI_GetYieldStateName(state)
    if state == YIELD_STATE.FAVORED then
        return Locale.Lookup("LOC_CAI_CITY_YIELD_STATE_FAVORED")
    elseif state == YIELD_STATE.IGNORED then
        return Locale.Lookup("LOC_CAI_CITY_YIELD_STATE_IGNORED")
    else
        return Locale.Lookup("LOC_CAI_CITY_YIELD_STATE_NORMAL")
    end
end

function CAI_SetCitizenFocusTo(yieldType, targetState)
    local city = g_pCity or UI.GetHeadSelectedCity()
    if city == nil then return end
    local pCitizens = city:GetCitizens()
    local isFavored = pCitizens:IsFavoredYield(yieldType)
    local isDisfavored = pCitizens:IsDisfavoredYield(yieldType)

    if targetState == YIELD_STATE.FAVORED then
        if not isFavored then SetYieldFocus(yieldType) end
    elseif targetState == YIELD_STATE.IGNORED then
        if not isDisfavored then SetYieldIgnore(yieldType) end
    else
        if isFavored then
            SetYieldFocus(yieldType)
        elseif isDisfavored then
            SetYieldIgnore(yieldType)
        end
    end
end

local CAI_YIELD_FOCUS_STATES = {
    { state = YIELD_STATE.NORMAL,  loc = "LOC_CAI_CITY_YIELD_STATE_NORMAL" },
    { state = YIELD_STATE.FAVORED, loc = "LOC_CAI_CITY_YIELD_STATE_FAVORED" },
    { state = YIELD_STATE.IGNORED, loc = "LOC_CAI_CITY_YIELD_STATE_IGNORED" },
}

local function GetYieldFocusOptions()
    local out = {}
    for _, entry in ipairs(CAI_YIELD_FOCUS_STATES) do
        table.insert(out, { label = Locale.Lookup(entry.loc), value = entry.state })
    end
    return out
end

local function GetSelectedYieldStateIndex(yieldType)
    local liveData = GetCityInfoData(UI.GetHeadSelectedCity())
    local current = GetCityInfoYieldState(liveData, yieldType)
    for i, entry in ipairs(CAI_YIELD_FOCUS_STATES) do
        if entry.state == YIELD_STATE.NORMAL
            and current ~= YIELD_STATE.FAVORED and current ~= YIELD_STATE.IGNORED then
            return i
        elseif entry.state == current then
            return i
        end
    end
    return 1
end

local function CreateCitizenYieldFocusDropdown(yieldType, yieldName)
    local dd = mgr:CreateWidget(mgr:GenerateWidgetId("CAICityYieldFocusDropdown"), "Dropdown", {
        Label = function() return yieldName end,
    })
    dd:SetFocusSound("Main_Menu_Mouse_Over")
    dd:SetOptions(GetYieldFocusOptions())
    dd:SetSelectedIndex(GetSelectedYieldStateIndex(yieldType), true)
    dd:SetValueSetter(function(_, targetState)
        CAI_SetCitizenFocusTo(yieldType, targetState)
    end)
    return dd
end

function OpenCitizenYieldFocusList()
    if mgr == nil or UI.GetHeadSelectedCity() == nil or ContextPtr:IsHidden() then return end

    local data = GetCityInfoData(UI.GetHeadSelectedCity())
    local cityName = GetCityInfoName(data) or Locale.Lookup("LOC_CAI_CITY_ACTIONS")

    local outerList = mgr:CreateWidget(CAI_YIELD_FOCUS_LIST_ID, "List", {
        Label = function() return Locale.Lookup("LOC_CAI_CITY_YIELD_FOCUS_LIST", cityName) end,
    })
    outerList:AddInputBindings({
        {
            Key         = Keys.VK_ESCAPE,
            MSG         = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_CLOSE",
            Action      = function()
                mgr:RemoveFromStack(CAI_YIELD_FOCUS_LIST_ID); return true
            end,
        },
    })

    for _, yieldEntry in ipairs(CAI_YIELD_FOCUS_YIELDS) do
        local yieldType = yieldEntry.Type
        local yieldInfo = GameInfo.Yields[yieldType]
        if yieldInfo ~= nil then
            local yieldName = Locale.Lookup(yieldInfo.Name)
            outerList:AddChild(CreateCitizenYieldFocusDropdown(yieldType, yieldName))
        end
    end

    mgr:Push(outerList, { priority = PopupPriority.Low })
end

--#Action Maps

function InitializeCityActionMap()
    CityActionMap = {
        [Input.GetActionId("SelectionActions")] = BuildCityActionData(
            OpenCityActionList,
            function()
                return UI.GetHeadSelectedCity() ~= nil and ContextPtr:IsHidden() == false
            end
        ),
        [Input.GetActionId("CityToggleOverview")] = BuildCityActionData(
            function()
                ToggleCityPanelCheck(Controls.ToggleOverviewPanel)
            end,
            function()
                return IsCityPanelActionAvailable(Controls.ToggleOverviewPanel)
            end
        ),
        [Input.GetActionId("CityManageCity")] = BuildCityActionData(
            ToggleCombinedCityManagement,
            CanToggleCombinedCityManagement
        ),
        [Input.GetActionId("CityPurchaseWithGold")] = BuildCityActionData(
            function()
                ToggleCityPanelCheck(Controls.ProduceWithGoldCheck)
            end,
            function()
                return GameCapabilities.HasCapability("CAPABILITY_GOLD")
                    and IsCityPanelActionAvailable(Controls.ProduceWithGoldCheck)
            end
        ),
        [Input.GetActionId("CityChangeCitizenYieldFocus")] = BuildCityActionData(
            OpenCitizenYieldFocusList,
            function()
                return UI.GetHeadSelectedCity() ~= nil
                    and ContextPtr:IsHidden() == false
                    and Controls.YieldsArea ~= nil
                    and not Controls.YieldsArea:IsHidden()
                    and not Controls.YieldsArea:IsDisabled()
            end
        ),
        [Input.GetActionId("CityPurchaseWithFaith")] = BuildCityActionData(
            function()
                ToggleCityPanelCheck(Controls.ProduceWithFaithCheck)
            end,
            function()
                return IsCityPanelActionAvailable(Controls.ProduceWithFaithCheck)
            end
        ),
        [Input.GetActionId("CityChangeProduction")] = BuildCityActionData(
            OpenOrToggleCityProduction,
            function()
                return IsCityPanelActionAvailable(Controls.ChangeProductionCheck)
            end
        ),
    }
end

function InitializeCityInfoActionMap()
    CityInfoActionMap = {
        [Input.GetActionId("ReadSelectionSummary")] = CITY_INFO_BUCKETS.Summary,
        [Input.GetActionId("ReadSelectionInfo1")] = CITY_INFO_BUCKETS.Info1,
        [Input.GetActionId("ReadSelectionInfo2")] = CITY_INFO_BUCKETS.Info2,
        [Input.GetActionId("ReadSelectionInfo3")] = CITY_INFO_BUCKETS.Info3,
        [Input.GetActionId("ReadSelectionInfo4")] = CITY_INFO_BUCKETS.Info4,
        [Input.GetActionId("ReadSelectionInfo5")] = CITY_INFO_BUCKETS.Info5,
        [Input.GetActionId("ReadSelectionInfo6")] = CITY_INFO_BUCKETS.Info6,
        [Input.GetActionId("ReadSelectionInfo7")] = CITY_INFO_BUCKETS.Info7,
        [Input.GetActionId("ReadSelectionInfo8")] = CITY_INFO_BUCKETS.Info8,
        [Input.GetActionId("ReadSelectionInfo9")] = CITY_INFO_BUCKETS.Info9,
        [Input.GetActionId("ReadSelectionInfo10")] = CITY_INFO_BUCKETS.Info10,
    }
end

--#Event Listeners and input handling
function OnHandleInput(inputStruct)
    if not mgr then return false end
    return mgr:HandleInput(inputStruct)
end

function OnSelectionInfoInputActionStarted(actionId)
    if ContextPtr:IsHidden() then return end
    local requestedKeys = CityInfoActionMap[actionId]
    local city = UI.GetHeadSelectedCity()
    local results

    if requestedKeys == nil or city == nil then
        return
    end

    results = info:RequestCityInfo(nil, requestedKeys)
    if results == nil or #results == 0 then
        if #requestedKeys == 1 then
            local fallback = CityInfoFallbacks[requestedKeys[1]]
            if fallback ~= nil then
                Speak(Locale.Lookup(fallback))
            end
        end
        return
    end

    local summary = table.concat(results, ", ")
    if actionId == Input.GetActionId("ReadSelectionSummary") then
        local cursor = ExposedMembers.CAICursor
        if cursor ~= nil then
            local cursorX, cursorY = cursor:GetCoords()
            if cursorX ~= nil and cursorY ~= nil then
                local direction = HexCoordUtils.directionString(
                    cursorX, cursorY, city:GetX(), city:GetY())
                SpeakLines({ direction, summary })
                return
            end
        end
    end

    Speak(summary)
end

function OnCityActionInputActionStarted(actionId)
    local action = CityActionMap[actionId]

    if action == nil or not action.IsEnabled() then
        return
    end

    action.helper()
end

function OnLoadScreenClose()
    if not m_IsGameStarted then
        m_IsGameStarted = true
    end
end

Events.LoadScreenClose.Add(OnLoadScreenClose)
m_IsGameStarted = true
function OnCitySelectionChanged(ownerPlayerID, cityID, i, j, k, isSelected, isEditable)
    if ContextPtr:IsHidden() then return end
    if not isSelected then return end
    if not m_IsGameStarted then return end
    if CAISettings.GetBool("AutoMoveCursorToSelectedCity") then
        local plot = Map.GetPlot(i, j)
        if plot == nil then
            LogWarn("CAI CityPanel could not resolve selected city plot: " .. tostring(i) .. ", " .. tostring(j))
            return
        end
        LuaEvents.CAICursorMoveTo(plot:GetIndex(), "select")
    end
    local results = info:RequestCityInfo(cityID, CITY_INFO_BUCKETS.Summary, ownerPlayerID)
    local focused = mgr:GetFocusedWidget()
    local isInWorld = focused and (focused.Type == "GameView" or focused.Type == "InterfaceMode")
    if isInWorld then
        if results == nil or #results == 0 then
            return
        end

        Speak(table.concat(results, ", "))
    end
end

--#Public API
---Returns info about a given city, given a city id, a list of keys, and a player
---@param cityID number|nil
---@param requestedKeys string[]|nil
---@param playerID number|nil
---@return string[]
function info:RequestCityInfo(cityID, requestedKeys, playerID)
    local city = nil
    if cityID == nil then
        city = UI.GetHeadSelectedCity()
    else
        local lookupPlayerID = playerID
        if lookupPlayerID == nil or lookupPlayerID == -1 then
            lookupPlayerID = Game.GetLocalPlayer()
        end

        if lookupPlayerID ~= nil and lookupPlayerID ~= -1 then
            city = CityManager.GetCity(lookupPlayerID, cityID)
        end
    end

    local data
    data, city = GetCityInfoData(city)
    local results = {}

    if data == nil then
        return results
    end

    requestedKeys = requestedKeys or CITY_INFO_BUCKETS.Summary

    for _, key in ipairs(requestedKeys) do
        local helper = self.CityInfo[key]
        if helper ~= nil then
            local output = helper(data, city)
            if type(output) == "table" then
                for _, value in ipairs(output) do
                    AppendCityInfo(results, value)
                end
            else
                AppendCityInfo(results, output)
            end
        end
    end

    return results
end

--#Initialization

InitializeCityActionMap()
InitializeCityInfoActionMap()
Events.CitySelectionChanged.Add(OnCitySelectionChanged)
Events.InputActionStarted.Add(OnCityActionInputActionStarted)
Events.InputActionStarted.Add(OnSelectionInfoInputActionStarted)
Events.LoadScreenClose.Add(OnLoadScreenClose)
ContextPtr:SetInputHandler(OnHandleInput, true)
