include("caiUtils")
include("Civ6Common")
local info = ExposedMembers.CAIInfo or {}
ExposedMembers.CAIInfo = info

local currentPlotId = -1
local CITY_BANNER_INFO_UNAVAILABLE = "LOC_CAI_CITY_BANNER_INFO_UNAVAILABLE"
local ACTION_BANNER_IDENTITY_STATUS = Input.GetActionId("CityBannerReadIdentityStatus")
local ACTION_BANNER_GROWTH_INFLUENCE = Input.GetActionId("CityBannerReadGrowthInfluence")
local ACTION_BANNER_RELIGION = Input.GetActionId("CityBannerReadReligion")
local ACTION_BANNER_DIPLOMACY = Input.GetActionId("CityBannerReadDiplomacy")
local ACTION_BANNER_LOYALTY_SUMMARY = Input.GetActionId("CityBannerReadLoyaltySummary")
local ACTION_BANNER_GOVERNOR = Input.GetActionId("CityBannerReadGovernor")
local ACTION_BANNER_POWER = Input.GetActionId("CityBannerReadPower")

local function AppendResult(results, value)
    if value ~= nil and value ~= "" then
        table.insert(results, value)
    end
end

local function TrimString(value)
    if value == nil then
        return nil
    end

    local trimmed = tostring(value):gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed == "" then
        return nil
    end

    return trimmed
end

local function NormalizeBannerText(value)
    if value == nil then
        return nil
    end

    local normalized = tostring(value)
    normalized = normalized:gsub("%[NEWLINE%]", "\n")
    return TrimString(normalized)
end

local function SplitBannerLines(value)
    local normalized = NormalizeBannerText(value)
    if normalized == nil then
        return {}
    end

    local lines = {}
    for line in normalized:gmatch("[^\n]+") do
        local trimmed = TrimString(line)
        if trimmed ~= nil then
            table.insert(lines, trimmed)
        end
    end

    return lines
end

local function GetControlText(control)
    if control == nil or control.GetText == nil then
        return nil
    end

    return NormalizeBannerText(control:GetText())
end

local function GetControlTooltip(control)
    if control == nil or control.GetToolTipString == nil then
        return nil
    end

    return NormalizeBannerText(control:GetToolTipString())
end

local function GetFirstAllocatedInstance(instanceManager)
    if instanceManager == nil or instanceManager.m_AllocatedInstances == nil then
        return nil
    end

    for i = 1, #instanceManager.m_AllocatedInstances do
        local instance = instanceManager.m_AllocatedInstances[i]
        if instance ~= nil then
            return instance
        end
    end

    for _, instance in pairs(instanceManager.m_AllocatedInstances) do
        if instance ~= nil then
            return instance
        end
    end

    return nil
end

local function GetAllocatedInstances(instanceManager)
    local results = {}
    if instanceManager == nil or instanceManager.m_AllocatedInstances == nil then
        return results
    end

    for i = 1, #instanceManager.m_AllocatedInstances do
        local instance = instanceManager.m_AllocatedInstances[i]
        if instance ~= nil then
            table.insert(results, instance)
        end
    end

    if #results > 0 then
        return results
    end

    for _, instance in pairs(instanceManager.m_AllocatedInstances) do
        if instance ~= nil then
            table.insert(results, instance)
        end
    end

    return results
end

local function AppendUniqueText(results, seen, value)
    local normalized = NormalizeBannerText(value)
    if normalized == nil or seen[normalized] then
        return
    end

    seen[normalized] = true
    table.insert(results, normalized)
end

local function GetInstanceTooltip(instance, ...)
    if instance == nil then
        return nil
    end

    local controlNames = { ... }
    for i = 1, #controlNames do
        local control = instance[controlNames[i]]
        local tooltip = GetControlTooltip(control)
        if tooltip ~= nil then
            return tooltip
        end
    end

    return nil
end

local function CollectInstanceTooltips(instanceManager, ...)
    local results = {}
    local seen = {}
    local instances = GetAllocatedInstances(instanceManager)
    for i = 1, #instances do
        AppendUniqueText(results, seen, GetInstanceTooltip(instances[i], ...))
    end

    return results
end

local function FindInstanceTooltip(instanceManager, predicate, ...)
    local instances = GetAllocatedInstances(instanceManager)
    for i = 1, #instances do
        local tooltip = GetInstanceTooltip(instances[i], ...)
        if tooltip ~= nil and predicate(tooltip) then
            return tooltip
        end
    end

    return nil
end

local function IsControlVisible(control)
    return control ~= nil and control.IsHidden ~= nil and not control:IsHidden()
end

local function IsBannerVisible(banner)
    if banner == nil or banner.m_Instance == nil or banner.m_Instance.Anchor == nil then
        return false
    end

    if banner.m_IsForceHide then
        return false
    end

    if banner.m_IsCurrentlyVisible == false then
        return false
    end

    return not banner.m_Instance.Anchor:IsHidden()
end

local function IsBannerReadable(banner)
    if banner == nil or banner.m_Instance == nil then
        return false
    end

    if banner.m_IsCurrentlyVisible == false then
        return false
    end

    if banner.m_Type == BANNERTYPE_OTHER_DISTRICT then
        return banner.m_FogState ~= PLOT_HIDDEN
    end

    return IsBannerVisible(banner)
end

local function IsDistrictContext(ctx)
    return ctx ~= nil and ctx.kind == "district"
end

local function GetUnavailableText()
    return Locale.Lookup(CITY_BANNER_INFO_UNAVAILABLE)
end

local function GetPlayerCivilizationText(playerID)
    local config = PlayerConfigurations[playerID]
    if config == nil then
        return nil
    end

    local civName = config:GetCivilizationDescription()
    if civName ~= nil and civName ~= "" then
        return Locale.Lookup(civName)
    end

    local leaderName = config:GetLeaderName()
    if leaderName ~= nil and leaderName ~= "" then
        return Locale.Lookup(leaderName)
    end

    return nil
end

local function BuildDistrictTypeLine(name)
    if name == nil or name == "" then
        return GetUnavailableText()
    end

    return Locale.Lookup("LOC_CAI_CITY_BANNER_DISTRICT_TYPE", name)
end

local function BuildProgressLine(percent)
    if percent == nil then
        return GetUnavailableText()
    end

    return Locale.Lookup("LOC_CAI_CITY_BANNER_PROGRESS", percent)
end

local function GetCurrentCursorPlot()
    if currentPlotId ~= nil and currentPlotId >= 0 then
        local plot = Map.GetPlotByIndex(currentPlotId)
        if plot ~= nil then
            return plot
        end
    end

    return nil
end

local function HasLoyaltyExpansion()
    return IsExpansion1Active ~= nil and IsExpansion2Active ~= nil and (IsExpansion1Active() or IsExpansion2Active())
end

local function HasPowerExpansion()
    return IsExpansion2Active ~= nil and IsExpansion2Active()
end

local function HasGovernorExpansion()
    return HasLoyaltyExpansion()
end

local function GetDistrictBannerTypeName(ctx)
    if ctx == nil then
        return nil
    end

    if ctx.district ~= nil then
        local districtDef = GameInfo.Districts[ctx.district:GetType()]
        if districtDef ~= nil and districtDef.Name ~= nil then
            return Locale.Lookup(districtDef.Name)
        end
    end

    if ctx.plot ~= nil then
        local improvementType = ctx.plot:GetImprovementType()
        if improvementType ~= nil and improvementType ~= -1 then
            local improvementDef = GameInfo.Improvements[improvementType]
            if improvementDef ~= nil and improvementDef.Name ~= nil then
                return Locale.Lookup(improvementDef.Name)
            end
        end
    end

    return nil
end

local function ResolveBannerContext(plot)
    if plot == nil then
        return nil
    end

    local owner = plot:GetOwner()
    local plotX = plot:GetX()
    local plotY = plot:GetY()
    local district = CityManager.GetDistrictAt(plotX, plotY)

    if district ~= nil then
        local districtOwner = district:GetOwner()
        if districtOwner ~= nil and districtOwner ~= -1 then
            local districtCity = district:GetCity()
            if districtCity ~= nil and districtCity:GetX() == plotX and districtCity:GetY() == plotY then
                local cityBanner = GetCityBanner(districtOwner, districtCity:GetID())
                if IsBannerVisible(cityBanner) then
                    return {
                        kind = "city",
                        plot = plot,
                        plotId = plot:GetIndex(),
                        owner = districtOwner,
                        city = districtCity,
                        district = district,
                        banner = cityBanner,
                        bannerType = cityBanner.m_Type,
                        instance = cityBanner.m_Instance,
                    }
                end
            else
                local miniBanner = GetMiniBanner(districtOwner, district:GetID())
                if IsBannerReadable(miniBanner) then
                    return {
                        kind = "district",
                        plot = plot,
                        plotId = plot:GetIndex(),
                        owner = districtOwner,
                        city = districtCity,
                        district = district,
                        banner = miniBanner,
                        bannerType = miniBanner.m_Type,
                        instance = miniBanner.m_Instance,
                    }
                end
            end
        end
    end

    local city = Cities.GetPlotPurchaseCity(plot)
    if city ~= nil and city:GetX() == plotX and city:GetY() == plotY then
        local cityBanner = GetCityBanner(city:GetOwner(), city:GetID())
        if IsBannerVisible(cityBanner) then
            return {
                kind = "city",
                plot = plot,
                plotId = plot:GetIndex(),
                owner = city:GetOwner(),
                city = city,
                district = district,
                banner = cityBanner,
                bannerType = cityBanner.m_Type,
                instance = cityBanner.m_Instance,
            }
        end
    end

    if owner ~= nil and owner ~= -1 then
        local miniBanner = GetMiniBanner(owner, plot:GetIndex())
        if IsBannerReadable(miniBanner) then
            return {
                kind = "district",
                plot = plot,
                plotId = plot:GetIndex(),
                owner = owner,
                city = city,
                district = nil,
                banner = miniBanner,
                bannerType = miniBanner.m_Type,
                instance = miniBanner.m_Instance,
            }
        end
    end

    return nil
end

local GetPowerSummaryText

local function GetStatusList(ctx)
    if ctx == nil or ctx.instance == nil then
        return nil
    end

    local statuses = {}
    local instance = ctx.instance

    local function AddStatus(control, fallbackLoc)
        if not IsControlVisible(control) then
            return
        end

        local tooltip = GetControlTooltip(control)
        if tooltip ~= nil then
            table.insert(statuses, tooltip)
        elseif fallbackLoc ~= nil then
            table.insert(statuses, Locale.Lookup(fallbackLoc))
        end
    end

    AddStatus(instance.CityOccupiedIcon, "LOC_CAI_CITY_STATUS_OCCUPIED")
    AddStatus(instance.CityUnderSiegeIcon, "LOC_HUD_REPORTS_STATUS_UNDER_SEIGE")
    AddStatus(instance.CityHousingInsufficientIcon, "LOC_CITY_BANNER_HOUSING_INSUFFICIENT")
    AddStatus(instance.CityAmenitiesInsufficientIcon, "LOC_CITY_BANNER_AMENITIES_INSUFFICIENT")

    if IsControlVisible(instance.UnderConstructionIcon) then
        table.insert(statuses, Locale.Lookup("LOC_TOOLTIP_PLOT_CONSTRUCTION_TEXT"))
    end

    local powerTooltip = GetPowerSummaryText(ctx)
    local effectTooltips = CollectInstanceTooltips(ctx.banner and ctx.banner.m_DetailEffectsIM, "Icon", "Button")
    for i = 1, #effectTooltips do
        if powerTooltip == nil or effectTooltips[i] ~= powerTooltip then
            table.insert(statuses, effectTooltips[i])
        end
    end

    if #statuses == 0 then
        return nil
    end

    return table.concat(statuses, ", ")
end

local function GetPopulationStatInstance(ctx)
    if ctx == nil or ctx.banner == nil then
        return nil
    end

    return GetFirstAllocatedInstance(ctx.banner.m_StatPopulationIM)
end

local function GetProductionStatInstance(ctx)
    if ctx == nil or ctx.banner == nil then
        return nil
    end

    return GetFirstAllocatedInstance(ctx.banner.m_StatProductionIM)
end

local function GetGovernorTooltips(ctx)
    if ctx == nil or ctx.banner == nil then
        return {}
    end

    return CollectInstanceTooltips(ctx.banner.m_StatGovernorIM, "FillMeter", "Button")
end

local function GetDetailStatusTooltip(ctx, predicate)
    if ctx == nil or ctx.banner == nil then
        return nil
    end

    return FindInstanceTooltip(ctx.banner.m_DetailStatusIM, predicate, "Icon", "Button")
end

local function GetPopulationGrowthLines(ctx)
    if ctx == nil or ctx.instance == nil then
        return {}
    end

    local tooltip = GetControlTooltip(ctx.instance.CityPopulation)
    if tooltip == nil then
        local populationInstance = GetPopulationStatInstance(ctx)
        tooltip = GetControlTooltip(populationInstance and populationInstance.FillMeter)
            or GetControlTooltip(populationInstance and populationInstance.Button)
    end

    local lines = SplitBannerLines(tooltip)
    if #lines <= 1 then
        return {}
    end

    local results = {}
    for i = 2, #lines do
        table.insert(results, lines[i])
    end
    return results
end

local function GetProductionTooltipLines(ctx)
    if ctx == nil or ctx.instance == nil then
        return {}
    end

    local tooltip = GetControlTooltip(ctx.instance.CityProduction)
    if tooltip == nil then
        local productionInstance = GetProductionStatInstance(ctx)
        tooltip = GetControlTooltip(productionInstance and productionInstance.Button)
    end

    return SplitBannerLines(tooltip)
end

local function GetDistrictTooltipLines(ctx)
    if ctx == nil or ctx.instance == nil or ctx.instance.DistrictIcon == nil then
        return {}
    end

    return SplitBannerLines(GetControlTooltip(ctx.instance.DistrictIcon))
end

local function GetBannerMeterPercent(control)
    if control == nil or control.GetPercent == nil then
        return nil
    end

    local percent = control:GetPercent()
    if percent == nil then
        return nil
    end

    return math.floor((percent * 100) + 0.5)
end

local function GetDetailedReligionInstance(ctx)
    if ctx == nil or ctx.instance == nil then
        return nil
    end

    return ctx.instance[DATA_FIELD_RELIGION_INFO_INSTANCE]
end

local function GetActiveReligionsInCity(ctx)
    if ctx == nil or ctx.kind ~= "city" or ctx.city == nil then
        return {}
    end

    local cityReligion = ctx.city:GetReligion()
    if cityReligion == nil then
        return {}
    end

    local cityPopulation = ctx.city:GetPopulation()
    if cityPopulation == nil or cityPopulation <= 0 then
        cityPopulation = 1
    end

    local activeReligions = {}
    local religionsInCity = cityReligion:GetReligionsInCity()
    for _, cityReligionInfo in pairs(religionsInCity) do
        local religion = cityReligionInfo.Religion
        if religion ~= nil and religion >= 0 then
            local religionDef = GameInfo.Religions[religion]
            if religionDef ~= nil then
                local followers = cityReligionInfo.Followers or 0
                local fillPercent = followers / cityPopulation
                table.insert(activeReligions, {
                    Religion = religion,
                    ReligionDef = religionDef,
                    Followers = followers,
                    Pressure = cityReligion:GetTotalPressureOnCity(religion),
                    LifetimePressure = cityReligionInfo.Pressure,
                    FillPercent = fillPercent,
                })
            end
        end
    end

    table.sort(activeReligions, function(a, b)
        return a.Followers > b.Followers
    end)

    return activeReligions
end

local function GetReligionDisplayName(religionIndex, isPredominant)
    if religionIndex == nil or religionIndex < 0 then
        return nil
    end

    local religionName = Game.GetReligion():GetName(religionIndex)
    if religionName == nil or religionName == "" then
        return nil
    end

    if isPredominant then
        return Locale.Lookup("LOC_CITY_BANNER_PREDOMINANT_RELIGION", religionName)
    end

    return religionName
end

local function GetReligionFollowerTooltip(ctx)
    local religionInfoInst = GetDetailedReligionInstance(ctx)
    if religionInfoInst ~= nil and religionInfoInst.ReligionPopChartContainer ~= nil then
        local tooltip = GetControlTooltip(religionInfoInst.ReligionPopChartContainer)
        if tooltip ~= nil then
            return tooltip
        end
    end

    local activeReligions = GetActiveReligionsInCity(ctx)
    if #activeReligions == 0 then
        return nil
    end

    local tooltip = Locale.Lookup("LOC_CITY_BANNER_FOLLOWER_PRESSURE_TOOLTIP_HEADER")
    for i, religionInfo in ipairs(activeReligions) do
        local religionName = GetReligionDisplayName(religionInfo.Religion, i == 1)
        if religionName ~= nil then
            tooltip = tooltip .. "[NEWLINE][NEWLINE]" ..
                Locale.Lookup(
                    "LOC_CITY_BANNER_FOLLOWER_PRESSURE_TOOLTIP",
                    religionName,
                    religionInfo.Followers,
                    Round(religionInfo.LifetimePressure)
                )
        end
    end

    return NormalizeBannerText(tooltip)
end

local function GetDetailedReligionPressure(ctx)
    local religionInfoInst = GetDetailedReligionInstance(ctx)
    if religionInfoInst ~= nil then
        local pressure = GetControlText(religionInfoInst.ExertedReligiousPressure)
        if pressure ~= nil then
            return Locale.Lookup("LOC_CAI_CITY_BANNER_OUTGOING_PRESSURE", pressure)
        end
    end

    if ctx == nil or ctx.kind ~= "city" or ctx.city == nil then
        return nil
    end

    local cityReligion = ctx.city:GetReligion()
    if cityReligion == nil then
        return nil
    end

    return Locale.Lookup(
        "LOC_CAI_CITY_BANNER_OUTGOING_PRESSURE",
        Locale.Lookup("LOC_CITY_BANNER_RELIGIOUS_PRESSURE", Round(cityReligion:GetPressureFromCity()))
    )
end

local function GetConstructionState(ctx)
    if ctx == nil or ctx.instance == nil then
        return nil
    end

    if ctx.instance.UnderConstructionIcon == nil then
        return nil
    end

    if IsControlVisible(ctx.instance.UnderConstructionIcon) then
        return Locale.Lookup("LOC_TOOLTIP_PLOT_CONSTRUCTION_TEXT")
    end

    return nil
end

local function GetAerodromeUnitNames(ctx)
    if ctx == nil or ctx.bannerType ~= BANNERTYPE_AERODROME then
        return nil
    end

    if ctx.instance == nil or ctx.instance.AerodromeBase == nil or ctx.instance.AerodromeBase:IsHidden() then
        return nil
    end

    local names = {}
    if ctx.district ~= nil then
        local hasAirUnits, airUnits = ctx.district:GetAirUnits()
        if hasAirUnits and airUnits ~= nil then
            for _, unit in ipairs(airUnits) do
                if unit ~= nil then
                    table.insert(names, Locale.ToUpper(unit:GetName()))
                end
            end
        end
    else
        local airUnits = ctx.plot ~= nil and ctx.plot:GetAirUnits() or nil
        if airUnits ~= nil then
            for _, unit in ipairs(airUnits) do
                if unit ~= nil then
                    table.insert(names, Locale.ToUpper(unit:GetName()))
                end
            end
        end
    end

    if #names == 0 then
        return nil
    end

    return Locale.Lookup("LOC_CAI_CITY_BANNER_AIR_UNITS", table.concat(names, ", "))
end

local function GetBannerStrikeTooltip(ctx)
    if ctx == nil or ctx.instance == nil or ctx.instance.CityStrikeButton == nil then
        return nil
    end

    if ctx.instance.CityStrike == nil or ctx.instance.CityStrike:IsHidden() then
        return nil
    end

    local tooltip = GetControlTooltip(ctx.instance.CityStrikeButton)
    if tooltip == nil then
        return nil
    end

    return tooltip
end

local function GetLoyaltyInfoInstance(ctx)
    if ctx == nil or ctx.kind ~= "city" or ctx.instance == nil then
        return nil
    end

    return ctx.instance.LoyaltyInfo
end

local function GetLoyaltyIdentity(ctx)
    if ctx == nil or ctx.kind ~= "city" or ctx.city == nil or not HasLoyaltyExpansion() then
        return nil
    end

    return ctx.city:GetCulturalIdentity()
end

local function FormatSignedLoyaltyValue(value)
    if value == nil then
        return nil
    end

    local rounded = Round(value, 1)
    if rounded > 0 then
        return "+" .. tostring(rounded)
    end

    return tostring(rounded)
end

local function GetLoyaltyPercentText(ctx)
    local culturalIdentity = GetLoyaltyIdentity(ctx)
    if culturalIdentity == nil then
        return nil
    end

    local currentLoyalty = culturalIdentity:GetLoyalty()
    local maxLoyalty = culturalIdentity:GetMaxLoyalty()
    if currentLoyalty == nil or maxLoyalty == nil or maxLoyalty == 0 then
        return nil
    end

    local percent = math.floor(((currentLoyalty / maxLoyalty) * 100) + 0.5)
    return Locale.Lookup("LOC_CAI_CITY_BANNER_LOYALTY_PERCENT", percent)
end

local function GetLoyaltyPerTurnText(ctx)
    local culturalIdentity = GetLoyaltyIdentity(ctx)
    if culturalIdentity == nil then
        return nil
    end

    local loyaltyPerTurn = culturalIdentity:GetLoyaltyPerTurn()
    if loyaltyPerTurn == nil then
        return nil
    end

    return Locale.Lookup("LOC_CAI_CITY_BANNER_LOYALTY_PER_TURN", FormatSignedLoyaltyValue(loyaltyPerTurn))
end

local function GetPressureValueText(value)
    if value == nil then
        return nil
    end

    if value > 0 then
        return Locale.Lookup("LOC_CULTURAL_IDENTITY_POSITIVE_PRESSURE", Round(value, 1))
    end

    if value < 0 then
        return tostring(Round(value, 1))
    end

    return Locale.Lookup("LOC_CULTURAL_IDENTITY_POSITIVE_PRESSURE", 0)
end

local function GetLoyaltyBucketLabel(control)
    local lines = SplitBannerLines(GetControlTooltip(control))
    if #lines > 0 then
        return lines[1]
    end

    return nil
end

local function GetLoyaltyBreakdownValue(ctx, bucketIndex)
    local loyaltyInfo = GetLoyaltyInfoInstance(ctx)
    local culturalIdentity = GetLoyaltyIdentity(ctx)
    if culturalIdentity == nil or loyaltyInfo == nil then
        return nil
    end

    local breakdown = culturalIdentity:GetIdentitySourcesBreakdown() or {}
    local bucketControls = {
        loyaltyInfo.PopulationTop,
        loyaltyInfo.GovernorTop,
        loyaltyInfo.Happiness,
        loyaltyInfo.OtherTop,
        loyaltyInfo.CityStateTop,
        loyaltyInfo.FreeCityTop,
    }

    local pressure = breakdown[bucketIndex]
    local control = bucketControls[bucketIndex]
    local value = nil
    if type(pressure) == "table" then
        for _, candidate in pairs(pressure) do
            if type(candidate) == "number" then
                value = candidate
                break
            end
        end
    end

    if control == nil or value == nil then
        return nil
    end

    local label = GetLoyaltyBucketLabel(control)
    local text = GetPressureValueText(value)
    if label == nil or text == nil then
        return nil
    end

    return label .. ": " .. text
end

local function GetLoyaltyInfluenceText(ctx)
    local culturalIdentity = GetLoyaltyIdentity(ctx)
    if ctx == nil or culturalIdentity == nil then
        return nil
    end

    local localPlayerID = Game.GetLocalPlayer()
    local localPlayer = localPlayerID ~= nil and localPlayerID ~= -1 and Players[localPlayerID] or nil
    local identitiesInCity = culturalIdentity:GetPlayerIdentitiesInCity() or {}
    local firstIdentity = next(identitiesInCity)
    if firstIdentity == nil then
        return nil
    end

    table.sort(identitiesInCity, function(left, right)
        return (left.IdentityTotal or 0) > (right.IdentityTotal or 0)
    end)

    local lines = {}
    local numInfluencers = 0
    for index, playerPresence in ipairs(identitiesInCity) do
        local total = playerPresence.IdentityTotal
        if total ~= nil and total > 0 then
            if numInfluencers < 2 or playerPresence.Player == localPlayerID then
                numInfluencers = numInfluencers + 1
                local config = PlayerConfigurations[playerPresence.Player]
                if config ~= nil then
                    local civName = Locale.Lookup(config:GetCivilizationShortDescription())
                    local hasBeenMet = localPlayer == nil or playerPresence.Player == localPlayerID
                        or (localPlayer.GetDiplomacy ~= nil and localPlayer:GetDiplomacy():HasMet(playerPresence.Player))
                    if not hasBeenMet then
                        civName = Locale.Lookup("LOC_LOYALTY_PANEL_UNMET_CIV")
                    end

                    local valueText = (index == 1 and "[ICON_Bolt] " or "") .. tostring(Round(total, 1))
                    table.insert(lines, civName .. ": " .. valueText)
                end
            end
        end
    end

    if #lines == 0 then
        return nil
    end

    return table.concat(lines, "\n")
end

GetPowerSummaryText = function(ctx)
    if ctx == nil or ctx.kind ~= "city" or ctx.city == nil or not HasPowerExpansion() then
        return nil
    end

    local cityPower = ctx.city:GetPower()
    if cityPower == nil then
        return nil
    end

    local freePower = cityPower.GetFreePower ~= nil and cityPower:GetFreePower() or 0
    local temporaryPower = cityPower.GetTemporaryPower ~= nil and cityPower:GetTemporaryPower() or 0
    local requiredPower = cityPower.GetRequiredPower ~= nil and cityPower:GetRequiredPower() or 0
    if freePower <= 0 and temporaryPower <= 0 and requiredPower <= 0 then
        return nil
    end

    local powerTooltip
    if cityPower.IsFullyPowered ~= nil and cityPower:IsFullyPowered() then
        powerTooltip = Locale.Lookup("LOC_CITY_BANNER_POWERED_CITY", requiredPower, freePower, temporaryPower)
        if cityPower.IsFullyPoweredByActiveProject ~= nil and cityPower:IsFullyPoweredByActiveProject() then
            powerTooltip = powerTooltip ..
            "[NEWLINE]" .. Locale.Lookup("LOC_CITY_BANNER_POWERED_CITY_FROM_ACTIVE_PROJECT")
        end
    else
        powerTooltip = Locale.Lookup("LOC_CITY_BANNER_UNPOWERED_CITY", requiredPower, freePower, temporaryPower)
    end

    return NormalizeBannerText(powerTooltip)
end

info.CityBannerInfo = {
    name = function(ctx)
        if ctx == nil or ctx.instance == nil then
            return nil
        end

        if ctx.kind == "city" then
            return GetControlText(ctx.instance.CityName)
        end

        local lines = GetDistrictTooltipLines(ctx)
        if #lines > 0 then
            return lines[1]
        end

        local districtName = GetDistrictBannerTypeName(ctx)
        if districtName ~= nil then
            return districtName
        end

        return GetUnavailableText()
    end,
    owner = function(ctx)
        if ctx == nil or ctx.kind ~= "city" or ctx.banner == nil or ctx.banner:IsTeam() then
            return nil
        end

        local ownerName = GetPlayerCivilizationText(ctx.owner)
        if ownerName == nil then
            return nil
        end

        return Locale.Lookup("LOC_HUD_CITY_OWNER", ownerName)
    end,
    population = function(ctx)
        if ctx == nil or ctx.kind ~= "city" or ctx.instance == nil then
            return nil
        end

        local value = GetControlText(ctx.instance.CityPopulation)
        if value == nil then
            local populationInstance = GetPopulationStatInstance(ctx)
            value = GetControlText(populationInstance and populationInstance.CityPopulation)
        end

        if value == nil then
            return nil
        end

        return Locale.Lookup("LOC_CAI_CITY_POPULATION", tonumber(value) or value)
    end,
    defense = function(ctx)
        if ctx == nil or ctx.instance == nil then
            return nil
        end

        local tooltip = GetControlTooltip(ctx.instance.BannerStrengthBacking) or
            GetControlTooltip(ctx.instance.DistrictDefenseGrid)
        if tooltip ~= nil then
            return tooltip
        end

        return nil
    end,
    hitPoints = function(ctx)
        if ctx == nil or ctx.instance == nil then
            return nil
        end

        local lines = SplitBannerLines(GetControlTooltip(ctx.instance.CityHealthBarBacking) or
            GetControlTooltip(ctx.instance.EncampmentBannerContainer))
        if #lines > 0 then
            return lines[1]
        end

        return nil
    end,
    outerDefense = function(ctx)
        if ctx == nil or ctx.instance == nil then
            return nil
        end

        local lines = SplitBannerLines(GetControlTooltip(ctx.instance.CityHealthBarBacking) or
            GetControlTooltip(ctx.instance.EncampmentBannerContainer))
        if #lines > 1 then
            return lines[2]
        end

        if ctx.kind == "city" then
            return Locale.Lookup("LOC_CAI_CITY_NO_WALLS")
        end

        return nil
    end,
    statuses = function(ctx)
        local statuses = GetStatusList(ctx)
        if statuses == nil then
            return nil
        end

        return statuses
    end,
    rangeStrike = function(ctx)
        return GetBannerStrikeTooltip(ctx)
    end,
    districtType = function(ctx)
        if not IsDistrictContext(ctx) then
            return nil
        end

        local districtName = info.CityBannerInfo.name(ctx)
        if ctx.district ~= nil then
            local districtDef = GameInfo.Districts[ctx.district:GetType()]
            if districtDef ~= nil then
                local districtTypeName = Locale.Lookup(districtDef.Name)
                if districtTypeName ~= nil and districtTypeName ~= districtName then
                    return BuildDistrictTypeLine(districtTypeName)
                end
                return nil
            end
        end

        local bannerDistrictName = GetDistrictBannerTypeName(ctx)
        if bannerDistrictName ~= nil and bannerDistrictName ~= districtName then
            return BuildDistrictTypeLine(bannerDistrictName)
        end

        return nil
    end,
    constructionState = function(ctx)
        if not IsDistrictContext(ctx) then
            return nil
        end

        return GetConstructionState(ctx)
    end,
    growthState = function(ctx)
        if ctx == nil or ctx.kind ~= "city" then
            return nil
        end

        local lines = GetPopulationGrowthLines(ctx)
        if #lines >= 1 then
            return lines[1]
        end

        return nil
    end,
    foodSurplus = function(ctx)
        if ctx == nil or ctx.kind ~= "city" then
            return nil
        end

        local lines = GetPopulationGrowthLines(ctx)
        if #lines >= 2 then
            return lines[2]
        end

        return nil
    end,
    production = function(ctx)
        if ctx == nil or ctx.kind ~= "city" then
            return nil
        end

        local lines = GetProductionTooltipLines(ctx)
        if #lines >= 1 then
            return lines[1]
        end

        return nil
    end,
    productionTurns = function(ctx)
        if ctx == nil or ctx.kind ~= "city" then
            return nil
        end

        local lines = GetProductionTooltipLines(ctx)
        if #lines >= 2 then
            return lines[2]
        end

        return nil
    end,
    productionProgress = function(ctx)
        if ctx == nil or ctx.kind ~= "city" or ctx.instance == nil then
            return nil
        end

        if ctx.instance.CityProductionProgress ~= nil and not ctx.instance.CityProductionProgress:IsHidden() then
            return BuildProgressLine(GetBannerMeterPercent(ctx.instance.CityProductionMeter))
        end

        local productionInstance = GetProductionStatInstance(ctx)
        if productionInstance == nil or not IsControlVisible(productionInstance.FillMeter) then
            return nil
        end

        return BuildProgressLine(GetBannerMeterPercent(productionInstance.FillMeter))
    end,
    religionSummary = function(ctx)
        if ctx == nil or ctx.kind ~= "city" or ctx.instance == nil then
            return nil
        end

        if ctx.instance.ReligionBannerIconContainer == nil or ctx.instance.ReligionBannerIconContainer:IsHidden() then
            return nil
        end

        local tooltip = GetControlTooltip(ctx.instance.ReligionBannerIconContainer)
        if tooltip == nil then
            return nil
        end

        return tooltip
    end,
    religionConversion = function(ctx)
        local religionInfoInst = GetDetailedReligionInstance(ctx)
        if religionInfoInst ~= nil and religionInfoInst.ReligionConversionTurnsStack ~= nil and
            not religionInfoInst.ReligionConversionTurnsStack:IsHidden() then
            return GetControlText(religionInfoInst.ConvertingReligionLabel)
        end

        if ctx == nil or ctx.kind ~= "city" or ctx.city == nil then
            return nil
        end

        local cityReligion = ctx.city:GetReligion()
        if cityReligion == nil then
            return nil
        end

        local nextReligion = cityReligion:GetNextReligion()
        local turnsTillNextReligion = cityReligion:GetTurnsToNextReligion()
        if nextReligion == nil or nextReligion == -1 or turnsTillNextReligion == nil or turnsTillNextReligion <= 0 then
            return nil
        end

        return Locale.Lookup("LOC_CITY_BANNER_CONVERTS_IN_X_TURNS", turnsTillNextReligion)
    end,
    religionFollowers = function(ctx)
        local tooltip = GetReligionFollowerTooltip(ctx)
        if tooltip == nil then
            return nil
        end

        return tooltip
    end,
    religionOutgoingPressure = function(ctx)
        local pressure = GetDetailedReligionPressure(ctx)
        if pressure == nil then
            return nil
        end

        return pressure
    end,
    quest = function(ctx)
        if ctx == nil or ctx.kind ~= "city" or ctx.instance == nil then
            return nil
        end

        if ctx.instance.CityQuestIcon ~= nil then
            local text = GetControlText(ctx.instance.CityQuestIcon)
            if text ~= nil then
                return GetControlTooltip(ctx.instance.CityQuestIcon)
            end
        end

        local questHeader = Locale.Lookup("LOC_CITY_STATES_QUESTS")
        return GetDetailStatusTooltip(ctx, function(tooltip)
            local lines = SplitBannerLines(tooltip)
            return #lines > 0 and lines[1] == questHeader
        end)
    end,
    tradingPost = function(ctx)
        if ctx == nil or ctx.kind ~= "city" or ctx.instance == nil then
            return nil
        end

        if IsControlVisible(ctx.instance.TradingPostDisabledIcon) then
            return Locale.Lookup("LOC_CAI_CITY_BANNER_TRADING_POST_INACTIVE")
        end

        if IsControlVisible(ctx.instance.TradingPostIcon) then
            return Locale.Lookup("LOC_CAI_CITY_BANNER_TRADING_POST_ACTIVE")
        end

        local activeTrade = Locale.Lookup("LOC_CITY_BANNER_ACTIVE_TRADING")
        local inactiveTrade = Locale.Lookup("LOC_CITY_BANNER_INACTIVE_TRADING")
        local tooltip = GetDetailStatusTooltip(ctx, function(candidate)
            return candidate == activeTrade or candidate == inactiveTrade
        end)
        if tooltip == inactiveTrade then
            return Locale.Lookup("LOC_CAI_CITY_BANNER_TRADING_POST_INACTIVE")
        end
        if tooltip == activeTrade then
            return Locale.Lookup("LOC_CAI_CITY_BANNER_TRADING_POST_ACTIVE")
        end

        return nil
    end,
    governor = function(ctx)
        if ctx == nil or ctx.kind ~= "city" then
            return nil
        end

        local tooltips = GetGovernorTooltips(ctx)
        if #tooltips == 0 then
            return nil
        end

        return table.concat(tooltips, ", ")
    end,
    powerSummary = function(ctx)
        return GetPowerSummaryText(ctx)
    end,
    powerDetails = function(ctx)
        return info.CityBannerInfo.powerSummary(ctx)
    end,
    aerodromeCapacity = function(ctx)
        if ctx == nil or ctx.bannerType ~= BANNERTYPE_AERODROME or ctx.instance == nil or ctx.instance.AerodromeBase == nil then
            return nil
        end

        if ctx.instance.AerodromeBase:IsHidden() then
            return nil
        end

        return GetControlTooltip(ctx.instance.AerodromeBase)
    end,
    aerodromeUnits = function(ctx)
        return GetAerodromeUnitNames(ctx)
    end,
    districtDescription = function(ctx)
        if not IsDistrictContext(ctx) then
            return nil
        end

        local lines = GetDistrictTooltipLines(ctx)
        if #lines >= 2 then
            return lines[2]
        end

        return nil
    end,
    nuclearDevices = function(ctx)
        if ctx == nil or ctx.bannerType ~= BANNERTYPE_MISSILE_SILO or ctx.instance == nil or ctx.instance.NukeCountLabel == nil then
            return nil
        end

        return Locale.Lookup("LOC_CAI_CITY_BANNER_NUCLEAR_DEVICES", GetControlText(ctx.instance.NukeCountLabel) or "0")
    end,
    thermonuclearDevices = function(ctx)
        if ctx == nil or ctx.bannerType ~= BANNERTYPE_MISSILE_SILO or ctx.instance == nil or ctx.instance.ThermoNukeCountLabel == nil then
            return nil
        end

        return Locale.Lookup("LOC_CAI_CITY_BANNER_THERMONUCLEAR_DEVICES",
            GetControlText(ctx.instance.ThermoNukeCountLabel) or "0")
    end,
    nuclearStrike = function(ctx)
        if ctx == nil or ctx.bannerType ~= BANNERTYPE_MISSILE_SILO or ctx.instance == nil or ctx.instance.NukeBombButton == nil then
            return nil
        end

        return GetControlTooltip(ctx.instance.NukeBombButton)
    end,
    thermonuclearStrike = function(ctx)
        if ctx == nil or ctx.bannerType ~= BANNERTYPE_MISSILE_SILO or ctx.instance == nil or ctx.instance.ThermoNukeBombButton == nil then
            return nil
        end

        return GetControlTooltip(ctx.instance.ThermoNukeBombButton)
    end,
    loyaltyPercent = function(ctx)
        return GetLoyaltyPercentText(ctx)
    end,
    loyaltyPerTurn = function(ctx)
        return GetLoyaltyPerTurnText(ctx)
    end,
    loyaltyPopulationPressure = function(ctx)
        return GetLoyaltyBreakdownValue(ctx, 1)
    end,
    loyaltyGovernorPressure = function(ctx)
        return GetLoyaltyBreakdownValue(ctx, 2)
    end,
    loyaltyHappinessPressure = function(ctx)
        return GetLoyaltyBreakdownValue(ctx, 3)
    end,
    loyaltyOtherPressure = function(ctx)
        return GetLoyaltyBreakdownValue(ctx, 4)
    end,
    loyaltyCityStatePressure = function(ctx)
        return GetLoyaltyBreakdownValue(ctx, 5)
    end,
    loyaltyFreeCityPressure = function(ctx)
        return GetLoyaltyBreakdownValue(ctx, 6)
    end,
    loyaltyInfluence = function(ctx)
        return GetLoyaltyInfluenceText(ctx)
    end,
}

local function IsForeignCityContext(ctx)
    return ctx ~= nil and ctx.kind == "city" and ctx.banner ~= nil and not ctx.banner:IsTeam()
end

local function HasPopulationGrowthTooltip(ctx)
    return ctx ~= nil and #GetPopulationGrowthLines(ctx) >= 2
end

local function HasVisibleReligionDetails(ctx)
    return ctx ~= nil and info.CityBannerInfo.religionSummary(ctx) ~= nil
end

local function HasVisibleReligionConversion(ctx)
    return ctx ~= nil and info.CityBannerInfo.religionConversion(ctx) ~= nil
end

local function HasVisibleReligionFollowers(ctx)
    return ctx ~= nil and info.CityBannerInfo.religionFollowers(ctx) ~= nil
end

local function HasVisibleReligionOutgoingPressure(ctx)
    return ctx ~= nil and info.CityBannerInfo.religionOutgoingPressure(ctx) ~= nil
end

local function IsCityLoyaltyContext(ctx)
    return ctx ~= nil and ctx.kind == "city" and HasLoyaltyExpansion()
end

local function IsCityPowerContext(ctx)
    return ctx ~= nil and ctx.kind == "city" and HasPowerExpansion()
end

local function IsCityGovernorContext(ctx)
    return ctx ~= nil and ctx.kind == "city" and HasGovernorExpansion()
end

local function AppendBucketKeys(results, ctx, definitions)
    if definitions == nil then
        return results
    end

    for _, entry in ipairs(definitions) do
        if type(entry) == "string" then
            table.insert(results, entry)
        elseif type(entry) == "table" then
            local include = entry.when == nil or entry.when(ctx)
            if include then
                if entry.key ~= nil then
                    table.insert(results, entry.key)
                elseif entry.keys ~= nil then
                    AppendBucketKeys(results, ctx, entry.keys)
                end
            end
        end
    end

    return results
end

local function BuildBucketKeys(ctx, action)
    if action == nil or ctx == nil then
        return {}
    end

    if ctx.kind == "city" then
        return AppendBucketKeys({}, ctx, action.city)
    end

    local districtDefinitions = action.district
    if districtDefinitions == nil then
        return {}
    end

    local definition = districtDefinitions[ctx.bannerType] or districtDefinitions.default
    return AppendBucketKeys({}, ctx, definition)
end

local BannerBucketActions = {
    [ACTION_BANNER_IDENTITY_STATUS] = {
        emptyLoc = "LOC_CAI_CITY_BANNER_NO_IDENTITY_STATUS",
        city = {
            "name",
            { key = "owner", when = IsForeignCityContext },
            "population",
            "hitPoints",
            "outerDefense",
            "defense",
            "statuses",
            "rangeStrike",
        },
        district = {
            [BANNERTYPE_ENCAMPMENT] = { "name", "districtType", "hitPoints", "outerDefense", "defense", "rangeStrike" },
            [BANNERTYPE_AERODROME] = { "name", "districtType", "aerodromeCapacity", "aerodromeUnits" },
            [BANNERTYPE_MISSILE_SILO] = {
                "name",
                "districtType",
                "nuclearDevices",
                "thermonuclearDevices",
                "nuclearStrike",
                "thermonuclearStrike",
            },
            default = { "name", "districtType", "constructionState", "districtDescription" },
        },
    },
    [ACTION_BANNER_GROWTH_INFLUENCE] = {
        emptyLoc = "LOC_CAI_CITY_BANNER_NO_GROWTH",
        city = {
            "growthState",
            { key = "foodSurplus", when = HasPopulationGrowthTooltip },
            "production",
            "productionTurns",
            "productionProgress",
        },
        district = {},
    },
    [ACTION_BANNER_RELIGION] = {
        emptyLoc = "LOC_CAI_CITY_BANNER_NO_RELIGION",
        city = {
            { key = "religionSummary",          when = HasVisibleReligionDetails },
            { key = "religionConversion",       when = HasVisibleReligionConversion },
            { key = "religionFollowers",        when = HasVisibleReligionFollowers },
            { key = "religionOutgoingPressure", when = HasVisibleReligionOutgoingPressure },
        },
        district = {},
    },
    [ACTION_BANNER_DIPLOMACY] = {
        emptyLoc = "LOC_CAI_CITY_BANNER_NO_DIPLOMACY",
        city = {
            { key = "owner", when = IsForeignCityContext },
            "quest",
            "tradingPost",
        },
        district = {},
    },
    [ACTION_BANNER_LOYALTY_SUMMARY] = {
        emptyLoc = CITY_BANNER_INFO_UNAVAILABLE,
        city = {
            { key = "loyaltyPercent",            when = IsCityLoyaltyContext },
            { key = "loyaltyPerTurn",            when = IsCityLoyaltyContext },
            { key = "loyaltyPopulationPressure", when = IsCityLoyaltyContext },
            { key = "loyaltyGovernorPressure",   when = IsCityLoyaltyContext },
            { key = "loyaltyHappinessPressure",  when = IsCityLoyaltyContext },
            { key = "loyaltyOtherPressure",      when = IsCityLoyaltyContext },
            { key = "loyaltyCityStatePressure",  when = IsCityLoyaltyContext },
            { key = "loyaltyFreeCityPressure",   when = IsCityLoyaltyContext },
            { key = "loyaltyInfluence",          when = IsCityLoyaltyContext },
        },
        district = {},
    },
    [ACTION_BANNER_GOVERNOR] = {
        emptyLoc = "LOC_CAI_CITY_BANNER_NO_GOVERNOR",
        city = {
            { key = "governor", when = IsCityGovernorContext },
        },
        district = {},
    },
    [ACTION_BANNER_POWER] = {
        emptyLoc = CITY_BANNER_INFO_UNAVAILABLE,
        city = {
            { key = "powerDetails", when = IsCityPowerContext },
        },
        district = {},
    },
}

local function BuildBucketRequest(ctx, actionId)
    local action = BannerBucketActions[actionId]
    if action == nil then
        return nil
    end

    return {
        keys = BuildBucketKeys(ctx, action),
        emptyLoc = action.emptyLoc,
    }
end

function info:RequestCityBannerInfo(requestedKeys)
    local plot = GetCurrentCursorPlot()
    local ctx = ResolveBannerContext(plot)
    if ctx == nil then
        return {}
    end

    local keys = requestedKeys or { "name" }
    local results = {}
    for _, key in ipairs(keys) do
        local helper = self.CityBannerInfo[key]
        if helper ~= nil then
            AppendResult(results, helper(ctx))
        end
    end

    return results
end

local function OnCityBannerInfoInputActionTriggered(actionId)
    local plot = GetCurrentCursorPlot()
    local ctx = ResolveBannerContext(plot)
    if ctx == nil then
        if BannerBucketActions[actionId] ~= nil then
            Speak(Locale.Lookup("LOC_CAI_CITY_BANNER_NO_BANNER"))
        end
        return
    end

    local request = BuildBucketRequest(ctx, actionId)
    if request == nil or request.keys == nil then
        return
    end

    local results = info:RequestCityBannerInfo(request.keys)
    if results == nil or #results == 0 then
        Speak(Locale.Lookup(request.emptyLoc))
        return
    end

    Speak(ProcessIcons(table.concat(results, ", ")))
end

local function OnCAICursorMoved(state)
    currentPlotId = state.toPlotId ~= nil and state.toPlotId or -1
end

local function OnCAIOpenOverviewForEnemyCity(playerID, cityID)
    OnCapitalIconClicked(playerID, cityID)
end

local function OnShutdown()
    Events.InputActionTriggered.Remove(OnCityBannerInfoInputActionTriggered)
    LuaEvents.CAICursorMoved.Remove(OnCAICursorMoved)
    if IsExpansion2Active() then
        LuaEvents.CAIOpenOverviewForEnemyCity.Remove(OnCAIOpenOverviewForEnemyCity)
    end
end

ContextPtr:SetShutdown(OnShutdown)
Events.InputActionTriggered.Add(OnCityBannerInfoInputActionTriggered)
LuaEvents.CAICursorMoved.Add(OnCAICursorMoved)
if IsExpansion2Active() then
    LuaEvents.CAIOpenOverviewForEnemyCity.Add(OnCAIOpenOverviewForEnemyCity)
end
