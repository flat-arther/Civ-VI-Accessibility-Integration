include("Civ6Common")

local Utils = CAIWorldScannerUtils

local SUBCATEGORY_WATER = "settlerWater"
local SUBCATEGORY_LOYALTY = "settlerLoyalty"
local SUBCATEGORY_DISASTERS = "settlerDisasters"
local SUBCATEGORY_APPEAL = "appeal"
local SUBCATEGORY_CONTINENT = "continent"
local SUBCATEGORY_MY = "my"
local SUBCATEGORY_NEUTRAL = "neutral"
local SUBCATEGORY_ENEMY = "enemy"
local SUBCATEGORY_POWER_SOURCES = "powerSources"
local SUBCATEGORY_POWER_RANGE = "powerRange"
local SUBCATEGORY_POWERED = "poweredCityPlots"
local SUBCATEGORY_UNPOWERED = "unpoweredCityPlots"
local SUBCATEGORY_TOURISM_CITY = "tourismCity"
local SUBCATEGORY_TOURISM_STRENGTH = "tourismStrength"

local GROUP_WATER_VALID = "water:valid"
local GROUP_WATER_FRESH = "water:fresh"
local GROUP_WATER_COASTAL = "water:coastal"
local GROUP_WATER_NO_WATER = "water:noWater"
local GROUP_WATER_BLOCKED = "water:blocked"

local GROUP_DISASTER_FLOOD = "disaster:flood"
local GROUP_DISASTER_VOLCANO = "disaster:volcano"
local GROUP_DISASTER_COASTAL_1 = "disaster:coastal:1"
local GROUP_DISASTER_COASTAL_2 = "disaster:coastal:2"
local GROUP_DISASTER_COASTAL_3 = "disaster:coastal:3"

local GROUP_APPEAL_BREATHTAKING = "appeal:breathtaking"
local GROUP_APPEAL_CHARMING = "appeal:charming"
local GROUP_APPEAL_AVERAGE = "appeal:average"
local GROUP_APPEAL_UNINVITING = "appeal:uninviting"
local GROUP_APPEAL_DISGUSTING = "appeal:disgusting"
local GROUP_TOURISM_HIGH = "tourism:high"
local GROUP_TOURISM_MEDIUM = "tourism:medium"
local GROUP_TOURISM_LOW = "tourism:low"

local LENS_SETTLER = "WaterAvailability"
local LENS_APPEAL = "Appeal"
local LENS_CONTINENT = "Continent"
local LENS_OWNER = "OwningCiv"
local LENS_GOVERNMENT = "Government"
local LENS_POWER = "Power"
local LENS_TOURISM = "Tourism"

local LAYER_SETTLER = UILens.CreateLensLayerHash("Hex_Coloring_Water_Availablity")
local LAYER_APPEAL = UILens.CreateLensLayerHash("Hex_Coloring_Appeal_Level")
local LAYER_CONTINENT = UILens.CreateLensLayerHash("Hex_Coloring_Continent")
local LAYER_OWNER = UILens.CreateLensLayerHash("Hex_Coloring_Owning_Civ")
local LAYER_GOVERNMENT = UILens.CreateLensLayerHash("Hex_Coloring_Government")
local LAYER_POWER = UILens.CreateLensLayerHash("Power_Lens")
local LAYER_TOURISM = UILens.CreateLensLayerHash("Tourist_Tokens")

local MAYA_CIVILIZATION_TYPE = "CIVILIZATION_MAYA"
local TOURISM_SCORE_HIGH = 16
local TOURISM_SCORE_MEDIUM = 8

local WATER_GROUP_LABEL_KEYS = {
    [GROUP_WATER_VALID] = "LOC_HUD_UNIT_PANEL_TOOLTIP_VALID_LOCATION",
    [GROUP_WATER_FRESH] = "LOC_HUD_UNIT_PANEL_TOOLTIP_FRESH_WATER",
    [GROUP_WATER_COASTAL] = "LOC_HUD_UNIT_PANEL_TOOLTIP_COASTAL_WATER",
    [GROUP_WATER_NO_WATER] = "LOC_HUD_UNIT_PANEL_TOOLTIP_NO_WATER",
    [GROUP_WATER_BLOCKED] = "LOC_HUD_UNIT_PANEL_TOOLTIP_TOO_CLOSE_TO_CITY",
}

local DISASTER_GROUP_LABEL_KEYS = {
    [GROUP_DISASTER_FLOOD] = "LOC_CAI_WORLD_SCANNER_SETTLER_DISASTER_FLOOD",
    [GROUP_DISASTER_VOLCANO] = "LOC_CAI_WORLD_SCANNER_SETTLER_DISASTER_VOLCANO",
    [GROUP_DISASTER_COASTAL_1] = "LOC_COASTAL_LOWLAND_1M_NAME",
    [GROUP_DISASTER_COASTAL_2] = "LOC_COASTAL_LOWLAND_2M_NAME",
    [GROUP_DISASTER_COASTAL_3] = "LOC_COASTAL_LOWLAND_3M_NAME",
}

local APPEAL_GROUP_LABEL_KEYS = {
    [GROUP_APPEAL_BREATHTAKING] = "LOC_TOOLTIP_APPEAL_BREATHTAKING",
    [GROUP_APPEAL_CHARMING] = "LOC_TOOLTIP_APPEAL_CHARMING",
    [GROUP_APPEAL_AVERAGE] = "LOC_TOOLTIP_APPEAL_AVERAGE",
    [GROUP_APPEAL_UNINVITING] = "LOC_TOOLTIP_APPEAL_UNINVITING",
    [GROUP_APPEAL_DISGUSTING] = "LOC_TOOLTIP_APPEAL_DISGUSTING",
}

local TOURISM_GROUP_LABEL_KEYS = {
    [GROUP_TOURISM_HIGH] = "LOC_CAI_WORLD_SCANNER_TOURISM_HIGH",
    [GROUP_TOURISM_MEDIUM] = "LOC_CAI_WORLD_SCANNER_TOURISM_MEDIUM",
    [GROUP_TOURISM_LOW] = "LOC_CAI_WORLD_SCANNER_TOURISM_LOW",
}

local subCategoryLabels = {
    [SUBCATEGORY_WATER] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_SETTLER_WATER",
    [SUBCATEGORY_LOYALTY] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_SETTLER_LOYALTY",
    [SUBCATEGORY_DISASTERS] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_SETTLER_DISASTERS",
    [SUBCATEGORY_APPEAL] = "LOC_HUD_APPEAL_LENS",
    [SUBCATEGORY_CONTINENT] = "LOC_HUD_CONTINENT_LENS",
    [SUBCATEGORY_MY] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_MY",
    [SUBCATEGORY_NEUTRAL] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_NEUTRAL",
    [SUBCATEGORY_ENEMY] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_ENEMY",
    [SUBCATEGORY_POWER_SOURCES] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_POWER_SOURCES",
    [SUBCATEGORY_POWER_RANGE] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_POWER_RANGE",
    [SUBCATEGORY_POWERED] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_POWERED_CITY_PLOTS",
    [SUBCATEGORY_UNPOWERED] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_UNPOWERED_CITY_PLOTS",
    [SUBCATEGORY_TOURISM_CITY] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_TOURISM_CITY",
    [SUBCATEGORY_TOURISM_STRENGTH] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_TOURISM_STRENGTH",
}

local DISASTER_GROUP_ORDER = {
    GROUP_DISASTER_FLOOD,
    GROUP_DISASTER_VOLCANO,
    GROUP_DISASTER_COASTAL_1,
    GROUP_DISASTER_COASTAL_2,
    GROUP_DISASTER_COASTAL_3,
}

local APPEAL_GROUP_ORDER = {
    GROUP_APPEAL_BREATHTAKING,
    GROUP_APPEAL_CHARMING,
    GROUP_APPEAL_AVERAGE,
    GROUP_APPEAL_UNINVITING,
    GROUP_APPEAL_DISGUSTING,
}

local TOURISM_GROUP_ORDER = {
    GROUP_TOURISM_HIGH,
    GROUP_TOURISM_MEDIUM,
    GROUP_TOURISM_LOW,
}

local function AddItem(out, item)
    out[#out + 1] = item
end

local function IsLocalPlayerMaya(context)
    local playerID = Utils.GetLocalPlayerID(context)
    if playerID == nil or playerID < 0 then
        return false
    end

    local config = PlayerConfigurations[playerID]
    return config ~= nil and config:GetCivilizationTypeName() == MAYA_CIVILIZATION_TYPE
end

local function FormatSignedNumber(value)
    if value == nil then
        return "0"
    end

    local numeric = tonumber(value) or 0
    if numeric > 0 then
        return "+" .. tostring(numeric)
    end

    return tostring(numeric)
end

local function MakeLoyaltyGroupId(value)
    local numeric = tonumber(value) or 0
    return "loyalty:" .. tostring(numeric)
end

local function MakeLoyaltyLabelKey(value)
    return Locale.Lookup("LOC_CAI_WORLD_SCANNER_SETTLER_LOYALTY_VALUE", FormatSignedNumber(value))
end

local function CanIdentifyPlayer(context, playerID)
    if playerID == nil or playerID < 0 then
        return false
    end

    local player = Players[playerID]
    if player ~= nil and player.IsFreeCities ~= nil and player:IsFreeCities() then
        return true
    end

    return Utils.CanKnowPlayer(context, playerID)
end

local function GetGovernmentGroupData(playerID)
    local player = playerID ~= nil and playerID >= 0 and Players[playerID] or nil
    if player == nil then
        return nil, nil
    end

    if player.IsFreeCities ~= nil and player:IsFreeCities() then
        return "government:freeCities", "LOC_CIVILIZATION_FREE_CITIES_NAME"
    end

    local culture = player.GetCulture ~= nil and player:GetCulture() or nil
    if culture == nil then
        return nil, nil
    end

    if culture.IsInAnarchy ~= nil and culture:IsInAnarchy() then
        return "government:anarchy", "LOC_GOVERNMENT_ANARCHY_NAME"
    end

    local governmentId = culture.GetCurrentGovernment ~= nil and culture:GetCurrentGovernment() or -1
    if governmentId == nil or governmentId < 0 then
        return "government:cityStates", "LOC_CITY_STATES_TITLE"
    end

    local government = GameInfo.Governments[governmentId]
    if government == nil then
        return "government:unknown", "LOC_CAI_WORLD_SCANNER_UNKNOWN"
    end

    return "government:" .. tostring(government.GovernmentType), government.Name
end

local function GetOwningCityForPlot(plot)
    if plot == nil then
        return nil
    end

    local city = Cities.GetPlotPurchaseCity(plot)
    if city ~= nil then
        return city
    end

    return Cities.GetCityInPlot(plot:GetX(), plot:GetY())
end

local function MakeGovernmentPlotLabel(governmentLabelKey, ownerID, plot)
    local city = GetOwningCityForPlot(plot)
    if city == nil then
        return nil, nil
    end

    local playerLabel = Utils.ResolveText(Utils.GetPlayerLabel(ownerID))
    local cityLabel = Utils.ResolveText(Utils.GetCityLabel(city))
    local groupId = governmentLabelKey
        .. ":player:" .. tostring(ownerID)
        .. ":city:" .. tostring(city:GetID())
    local groupLabel = Locale.Lookup(
        "LOC_CAI_WORLD_SCANNER_GOVERNMENT_GROUP_WITH_CITY",
        Utils.ResolveText(governmentLabelKey),
        playerLabel,
        cityLabel
    )

    return groupId, groupLabel
end

local function MakePowerCityGroupLabel(labelKey, city)
    return Locale.Lookup(labelKey, Utils.ResolveText(Utils.GetCityLabel(city)))
end

local function GetTourismStrengthGroupId(tourismValue)
    if tourismValue >= TOURISM_SCORE_HIGH then
        return GROUP_TOURISM_HIGH
    end
    if tourismValue >= TOURISM_SCORE_MEDIUM then
        return GROUP_TOURISM_MEDIUM
    end

    return GROUP_TOURISM_LOW
end

local function MakeTourismItemLabel(tourismValue, touristCount)
    return Locale.Lookup(
        "LOC_CAI_WORLD_SCANNER_TOURISM_ITEM",
        tostring(tourismValue),
        tostring(touristCount)
    )
end

local function AddPlotListWithSharedLabel(out, lensId, subCategoryId, plotList, groupId, labelKey, context)
    if plotList == nil then
        return
    end

    for _, plotIndex in ipairs(plotList) do
        local plot = Map.GetPlotByIndex(plotIndex)
        if plot ~= nil and Utils.IsPlotRevealed(context, plot) then
            AddItem(out, {
                Id = "activeLens:" .. lensId .. ":" .. subCategoryId .. ":" .. tostring(groupId) .. ":" .. tostring(plotIndex),
                PlotIndex = plotIndex,
                LabelKey = labelKey,
                SubCategoryId = subCategoryId,
                GroupId = groupId,
                GroupLabelKey = labelKey,
            })
        end
    end
end

local function ScanSettlerLens(context)
    local out = {}
    local fullWaterPlots, coastalWaterPlots, noWaterPlots, noSettlePlots = Map.GetContinentPlotsWaterAvailability()

    if IsLocalPlayerMaya(context) then
        AddPlotListWithSharedLabel(out, LENS_SETTLER, SUBCATEGORY_WATER, fullWaterPlots, GROUP_WATER_VALID, WATER_GROUP_LABEL_KEYS[GROUP_WATER_VALID], context)
        AddPlotListWithSharedLabel(out, LENS_SETTLER, SUBCATEGORY_WATER, coastalWaterPlots, GROUP_WATER_VALID, WATER_GROUP_LABEL_KEYS[GROUP_WATER_VALID], context)
        AddPlotListWithSharedLabel(out, LENS_SETTLER, SUBCATEGORY_WATER, noWaterPlots, GROUP_WATER_VALID, WATER_GROUP_LABEL_KEYS[GROUP_WATER_VALID], context)
    else
        AddPlotListWithSharedLabel(out, LENS_SETTLER, SUBCATEGORY_WATER, fullWaterPlots, GROUP_WATER_FRESH, WATER_GROUP_LABEL_KEYS[GROUP_WATER_FRESH], context)
        AddPlotListWithSharedLabel(out, LENS_SETTLER, SUBCATEGORY_WATER, coastalWaterPlots, GROUP_WATER_COASTAL, WATER_GROUP_LABEL_KEYS[GROUP_WATER_COASTAL], context)
        AddPlotListWithSharedLabel(out, LENS_SETTLER, SUBCATEGORY_WATER, noWaterPlots, GROUP_WATER_NO_WATER, WATER_GROUP_LABEL_KEYS[GROUP_WATER_NO_WATER], context)
    end

    AddPlotListWithSharedLabel(out, LENS_SETTLER, SUBCATEGORY_WATER, noSettlePlots, GROUP_WATER_BLOCKED, WATER_GROUP_LABEL_KEYS[GROUP_WATER_BLOCKED], context)

    if IsExpansion1Active() then
        local plots = Map.GetContinentPlotsLoyalty()
        if plots ~= nil then
            for plotIndex, loyaltyValue in pairs(plots) do
                local plot = Map.GetPlotByIndex(plotIndex)
                if plot ~= nil and Utils.IsPlotRevealed(context, plot) then
                    local labelKey = MakeLoyaltyLabelKey(loyaltyValue)
                    AddItem(out, {
                        Id = "activeLens:" .. LENS_SETTLER .. ":" .. SUBCATEGORY_LOYALTY .. ":" .. tostring(plotIndex) .. ":" .. tostring(loyaltyValue),
                        PlotIndex = plotIndex,
                        LabelKey = labelKey,
                        SubCategoryId = SUBCATEGORY_LOYALTY,
                        GroupId = MakeLoyaltyGroupId(loyaltyValue),
                        GroupLabelKey = labelKey,
                        GroupSortValue = tonumber(loyaltyValue) or 0,
                    })
                end
            end
        end
    end

    if IsExpansion2Active() then
        Utils.ForEachRevealedPlot(context, function(plotIndex, plot)
            if RiverManager.CanBeFlooded(plot) then
                AddItem(out, {
                    Id = "activeLens:" .. LENS_SETTLER .. ":" .. SUBCATEGORY_DISASTERS .. ":" .. GROUP_DISASTER_FLOOD .. ":" .. tostring(plotIndex),
                    PlotIndex = plotIndex,
                    LabelKey = DISASTER_GROUP_LABEL_KEYS[GROUP_DISASTER_FLOOD],
                    SubCategoryId = SUBCATEGORY_DISASTERS,
                    GroupId = GROUP_DISASTER_FLOOD,
                    GroupLabelKey = DISASTER_GROUP_LABEL_KEYS[GROUP_DISASTER_FLOOD],
                })
            end

            if MapFeatureManager.CanSufferEruption(plot) then
                AddItem(out, {
                    Id = "activeLens:" .. LENS_SETTLER .. ":" .. SUBCATEGORY_DISASTERS .. ":" .. GROUP_DISASTER_VOLCANO .. ":" .. tostring(plotIndex),
                    PlotIndex = plotIndex,
                    LabelKey = DISASTER_GROUP_LABEL_KEYS[GROUP_DISASTER_VOLCANO],
                    SubCategoryId = SUBCATEGORY_DISASTERS,
                    GroupId = GROUP_DISASTER_VOLCANO,
                    GroupLabelKey = DISASTER_GROUP_LABEL_KEYS[GROUP_DISASTER_VOLCANO],
                })
            end

            if not TerrainManager.IsProtected(plot) then
                local coastalLowlandType = TerrainManager.GetCoastalLowlandType(plot)
                local disasterGroupId = nil
                if coastalLowlandType == 0 then
                    disasterGroupId = GROUP_DISASTER_COASTAL_1
                elseif coastalLowlandType == 1 then
                    disasterGroupId = GROUP_DISASTER_COASTAL_2
                elseif coastalLowlandType == 2 then
                    disasterGroupId = GROUP_DISASTER_COASTAL_3
                end

                if disasterGroupId ~= nil then
                    AddItem(out, {
                        Id = "activeLens:" .. LENS_SETTLER .. ":" .. SUBCATEGORY_DISASTERS .. ":" .. disasterGroupId .. ":" .. tostring(plotIndex),
                        PlotIndex = plotIndex,
                        LabelKey = DISASTER_GROUP_LABEL_KEYS[disasterGroupId],
                        SubCategoryId = SUBCATEGORY_DISASTERS,
                        GroupId = disasterGroupId,
                        GroupLabelKey = DISASTER_GROUP_LABEL_KEYS[disasterGroupId],
                    })
                end
            end
        end)
    end

    return out
end

local function ScanAppealLens(context)
    local out = {}
    local breathtakingPlots, charmingPlots, averagePlots, uninvitingPlots, disgustingPlots = Map.GetContinentPlotsAppeal()

    AddPlotListWithSharedLabel(out, LENS_APPEAL, SUBCATEGORY_APPEAL, breathtakingPlots, GROUP_APPEAL_BREATHTAKING, APPEAL_GROUP_LABEL_KEYS[GROUP_APPEAL_BREATHTAKING], context)
    AddPlotListWithSharedLabel(out, LENS_APPEAL, SUBCATEGORY_APPEAL, charmingPlots, GROUP_APPEAL_CHARMING, APPEAL_GROUP_LABEL_KEYS[GROUP_APPEAL_CHARMING], context)
    AddPlotListWithSharedLabel(out, LENS_APPEAL, SUBCATEGORY_APPEAL, averagePlots, GROUP_APPEAL_AVERAGE, APPEAL_GROUP_LABEL_KEYS[GROUP_APPEAL_AVERAGE], context)
    AddPlotListWithSharedLabel(out, LENS_APPEAL, SUBCATEGORY_APPEAL, uninvitingPlots, GROUP_APPEAL_UNINVITING, APPEAL_GROUP_LABEL_KEYS[GROUP_APPEAL_UNINVITING], context)
    AddPlotListWithSharedLabel(out, LENS_APPEAL, SUBCATEGORY_APPEAL, disgustingPlots, GROUP_APPEAL_DISGUSTING, APPEAL_GROUP_LABEL_KEYS[GROUP_APPEAL_DISGUSTING], context)

    return out
end

local function ScanContinentLens(context)
    local out = {}
    local continents = Map.GetContinentsInUse()
    if continents == nil then
        return out
    end

    for _, continentId in ipairs(continents) do
        local continent = GameInfo.Continents[continentId]
        if continent ~= nil then
            local labelKey = continent.Description
            local plots = Map.GetVisibleContinentPlots(continentId)
            AddPlotListWithSharedLabel(out, LENS_CONTINENT, SUBCATEGORY_CONTINENT, plots, "continent:" .. tostring(continentId), labelKey, context)
        end
    end

    return out
end

local function ScanOwnerLens(context)
    local out = {}

    Utils.ForEachRevealedPlot(context, function(plotIndex, plot)
        local ownerID = plot:GetOwner()
        if not CanIdentifyPlayer(context, ownerID) then
            return
        end

        local stance = Utils.GetTeamStance(context, ownerID)
        local labelKey = Utils.GetPlayerLabel(ownerID)
        AddItem(out, {
            Id = "activeLens:" .. LENS_OWNER .. ":" .. stance .. ":" .. tostring(ownerID) .. ":" .. tostring(plotIndex),
            PlotIndex = plotIndex,
            LabelKey = labelKey,
            SubCategoryId = stance,
            GroupId = "player:" .. tostring(ownerID),
            GroupLabelKey = labelKey,
            Validate = function(item, validateContext)
                local validatePlot = Map.GetPlotByIndex(item.PlotIndex)
                if validatePlot == nil or not Utils.IsPlotRevealed(validateContext, validatePlot) then
                    return false
                end

                return validatePlot:GetOwner() == ownerID
                    and CanIdentifyPlayer(validateContext, ownerID)
                    and Utils.GetTeamStance(validateContext, ownerID) == item.SubCategoryId
            end,
        })
    end)

    return out
end

local function ScanGovernmentLens(context)
    local out = {}

    Utils.ForEachRevealedPlot(context, function(plotIndex, plot)
        local ownerID = plot:GetOwner()
        if not CanIdentifyPlayer(context, ownerID) then
            return
        end

        local governmentGroupId, governmentLabelKey = GetGovernmentGroupData(ownerID)
        if governmentGroupId == nil or governmentLabelKey == nil then
            return
        end

        local groupId, labelKey = MakeGovernmentPlotLabel(governmentLabelKey, ownerID, plot)
        if groupId == nil or labelKey == nil then
            return
        end

        local stance = Utils.GetTeamStance(context, ownerID)
        AddItem(out, {
            Id = "activeLens:" .. LENS_GOVERNMENT .. ":" .. stance .. ":" .. tostring(groupId) .. ":" .. tostring(plotIndex),
            PlotIndex = plotIndex,
            LabelKey = labelKey,
            SubCategoryId = stance,
            GroupId = groupId,
            GroupLabelKey = labelKey,
            Validate = function(item, validateContext)
                local validatePlot = Map.GetPlotByIndex(item.PlotIndex)
                if validatePlot == nil or not Utils.IsPlotRevealed(validateContext, validatePlot) then
                    return false
                end

                local validateOwnerID = validatePlot:GetOwner()
                if validateOwnerID ~= ownerID or not CanIdentifyPlayer(validateContext, validateOwnerID) then
                    return false
                end

                local validateGovernmentGroupId, validateGovernmentLabelKey = GetGovernmentGroupData(validateOwnerID)
                if validateGovernmentGroupId ~= governmentGroupId or validateGovernmentLabelKey ~= governmentLabelKey then
                    return false
                end

                local validateCompositeGroupId = MakeGovernmentPlotLabel(validateGovernmentLabelKey, validateOwnerID, validatePlot)
                return validateCompositeGroupId == groupId
                    and Utils.GetTeamStance(validateContext, validateOwnerID) == item.SubCategoryId
            end,
        })
    end)

    return out
end

local function ScanPowerLens(context)
    local out = {}
    local localPlayer = Utils.GetLocalPlayer(context)
    if localPlayer == nil or localPlayer.GetCities == nil then
        return out
    end

    for _, city in localPlayer:GetCities():Members() do
        local cityPower = city.GetPower ~= nil and city:GetPower() or nil
        if cityPower ~= nil then
            local cityGroupId = "city:" .. tostring(city:GetID())

            local poweredPlots = cityPower.GetPlotsCoveredByRegionalPower ~= nil and cityPower:GetPlotsCoveredByRegionalPower() or nil
            if poweredPlots ~= nil then
                local groupLabel = MakePowerCityGroupLabel("LOC_CAI_WORLD_SCANNER_POWER_RANGE_CITY", city)
                for plotIndex, isPowered in pairs(poweredPlots) do
                    local plot = Map.GetPlotByIndex(plotIndex)
                    if isPowered and plot ~= nil and Utils.IsPlotRevealed(context, plot) then
                        AddItem(out, {
                            Id = "activeLens:" .. LENS_POWER .. ":" .. SUBCATEGORY_POWER_RANGE .. ":" .. cityGroupId .. ":" .. tostring(plotIndex),
                            PlotIndex = plotIndex,
                            LabelKey = groupLabel,
                            SubCategoryId = SUBCATEGORY_POWER_RANGE,
                            GroupId = cityGroupId,
                            GroupLabelKey = groupLabel,
                        })
                    end
                end
            end

            local plotsProvidingPower = cityPower.GetPlotsProvidingPower ~= nil and cityPower:GetPlotsProvidingPower() or nil
            if plotsProvidingPower ~= nil then
                for plotIndex, powerString in pairs(plotsProvidingPower) do
                    local plot = Map.GetPlotByIndex(plotIndex)
                    if plot ~= nil and Utils.IsPlotRevealed(context, plot) then
                        local labelKey = powerString
                        local groupId = "source:" .. tostring(powerString)
                        AddItem(out, {
                            Id = "activeLens:" .. LENS_POWER .. ":" .. SUBCATEGORY_POWER_SOURCES .. ":" .. groupId .. ":" .. tostring(plotIndex),
                            PlotIndex = plotIndex,
                            LabelKey = labelKey,
                            SubCategoryId = SUBCATEGORY_POWER_SOURCES,
                            GroupId = groupId,
                            GroupLabelKey = labelKey,
                        })
                    end
                end
            end

            local cityPlots = Map.GetCityPlots():GetPurchasedPlots(city)
            if cityPlots ~= nil then
                local isFullyPowered = cityPower.IsFullyPowered ~= nil and cityPower:IsFullyPowered() or false
                local requiredPower = cityPower.GetRequiredPower ~= nil and cityPower:GetRequiredPower() or 0
                local isPoweredCity = isFullyPowered and requiredPower > 0
                local subCategoryId = isPoweredCity and SUBCATEGORY_POWERED or SUBCATEGORY_UNPOWERED
                local groupLabel = MakePowerCityGroupLabel(
                    isPoweredCity and "LOC_CAI_WORLD_SCANNER_POWER_PLOTS_POWERED" or "LOC_CAI_WORLD_SCANNER_POWER_PLOTS_UNPOWERED",
                    city
                )

                for _, plotIndex in ipairs(cityPlots) do
                    local plot = Map.GetPlotByIndex(plotIndex)
                    if plot ~= nil and Utils.IsPlotRevealed(context, plot) then
                        AddItem(out, {
                            Id = "activeLens:" .. LENS_POWER .. ":" .. subCategoryId .. ":" .. cityGroupId .. ":" .. tostring(plotIndex),
                            PlotIndex = plotIndex,
                            LabelKey = groupLabel,
                            SubCategoryId = subCategoryId,
                            GroupId = cityGroupId,
                            GroupLabelKey = groupLabel,
                        })
                    end
                end
            end
        end
    end

    return out
end

local function ScanTourismLens(context)
    local out = {}
    local localPlayer = Utils.GetLocalPlayer(context)
    if localPlayer == nil or localPlayer.GetCulture == nil or localPlayer.GetCities == nil then
        return out
    end

    local culture = localPlayer:GetCulture()
    if culture == nil then
        return out
    end

    for _, city in localPlayer:GetCities():Members() do
        local cityPlots = Map.GetCityPlots():GetPurchasedPlots(city)
        if cityPlots ~= nil then
            local cityGroupId = "city:" .. tostring(city:GetID())
            local cityLabel = Utils.GetCityLabel(city)
            for _, plotIndex in ipairs(cityPlots) do
                local plot = Map.GetPlotByIndex(plotIndex)
                if plot ~= nil and Utils.IsPlotRevealed(context, plot) then
                    local tourismValue = culture.GetTourismAt ~= nil and culture:GetTourismAt(plotIndex) or 0
                    if tourismValue > 0 then
                        local touristCount = culture.GetTouristsAt ~= nil and culture:GetTouristsAt(plotIndex) or 0
                        local itemLabel = MakeTourismItemLabel(tourismValue, touristCount)
                        local strengthGroupId = GetTourismStrengthGroupId(tourismValue)
                        local strengthLabel = TOURISM_GROUP_LABEL_KEYS[strengthGroupId]

                        AddItem(out, {
                            Id = "activeLens:" .. LENS_TOURISM .. ":" .. SUBCATEGORY_TOURISM_CITY .. ":" .. cityGroupId .. ":" .. tostring(plotIndex),
                            PlotIndex = plotIndex,
                            LabelKey = itemLabel,
                            SubCategoryId = SUBCATEGORY_TOURISM_CITY,
                            GroupId = cityGroupId,
                            GroupLabelKey = cityLabel,
                        })

                        AddItem(out, {
                            Id = "activeLens:" .. LENS_TOURISM .. ":" .. SUBCATEGORY_TOURISM_STRENGTH .. ":" .. strengthGroupId .. ":" .. tostring(plotIndex),
                            PlotIndex = plotIndex,
                            LabelKey = itemLabel,
                            SubCategoryId = SUBCATEGORY_TOURISM_STRENGTH,
                            GroupId = strengthGroupId,
                            GroupLabelKey = strengthLabel,
                        })
                    end
                end
            end
        end
    end

    return out
end

local supportedLenses = {
    {
        Id = LENS_SETTLER,
        IsActive = function()
            return UILens.IsLayerOn(LAYER_SETTLER)
        end,
        Scan = ScanSettlerLens,
    },
    {
        Id = LENS_APPEAL,
        IsActive = function()
            return UILens.IsLayerOn(LAYER_APPEAL)
        end,
        Scan = ScanAppealLens,
    },
    {
        Id = LENS_CONTINENT,
        IsActive = function()
            return UILens.IsLayerOn(LAYER_CONTINENT)
        end,
        Scan = ScanContinentLens,
    },
    {
        Id = LENS_OWNER,
        IsActive = function()
            return UILens.IsLayerOn(LAYER_OWNER)
        end,
        Scan = ScanOwnerLens,
    },
    {
        Id = LENS_GOVERNMENT,
        IsActive = function()
            return UILens.IsLayerOn(LAYER_GOVERNMENT)
        end,
        Scan = ScanGovernmentLens,
    },
    {
        Id = LENS_POWER,
        IsActive = function()
            return IsExpansion2Active() and UILens.IsLayerOn(LAYER_POWER)
        end,
        Scan = ScanPowerLens,
    },
    {
        Id = LENS_TOURISM,
        IsActive = function()
            return UILens.IsLayerOn(LAYER_TOURISM)
        end,
        Scan = ScanTourismLens,
    },
}

local function GetActiveSupportedLens()
    for _, lens in ipairs(supportedLenses) do
        if lens.IsActive ~= nil and lens.IsActive() then
            return lens
        end
    end

    return nil
end

CAIWorldScannerCategory_ActiveLens = {
    Id = "activeLens",
    LabelKey = "LOC_CAI_WORLD_SCANNER_CATEGORY_ACTIVE_LENS",
    BuildOncePerDynamicState = true,
    SubCategoryOrder = {
        SUBCATEGORY_WATER,
        SUBCATEGORY_LOYALTY,
        SUBCATEGORY_DISASTERS,
        SUBCATEGORY_APPEAL,
        SUBCATEGORY_CONTINENT,
        SUBCATEGORY_MY,
        SUBCATEGORY_NEUTRAL,
        SUBCATEGORY_ENEMY,
        SUBCATEGORY_POWER_SOURCES,
        SUBCATEGORY_POWER_RANGE,
        SUBCATEGORY_POWERED,
        SUBCATEGORY_UNPOWERED,
        SUBCATEGORY_TOURISM_CITY,
        SUBCATEGORY_TOURISM_STRENGTH,
    },
    SubCategoryLabels = subCategoryLabels,
    GroupOrderBySubCategory = {
        [SUBCATEGORY_WATER] = {
            GROUP_WATER_VALID,
            GROUP_WATER_FRESH,
            GROUP_WATER_COASTAL,
            GROUP_WATER_NO_WATER,
            GROUP_WATER_BLOCKED,
        },
        [SUBCATEGORY_DISASTERS] = DISASTER_GROUP_ORDER,
        [SUBCATEGORY_APPEAL] = APPEAL_GROUP_ORDER,
        [SUBCATEGORY_TOURISM_STRENGTH] = TOURISM_GROUP_ORDER,
    },
    GroupLabelResolver = function(_, firstItem)
        return firstItem ~= nil and firstItem.GroupLabelKey or "LOC_CAI_WORLD_SCANNER_UNKNOWN"
    end,
    GroupComparatorBySubCategory = {
        [SUBCATEGORY_LOYALTY] = function(a, b)
            local aValue = a.SortValue or 0
            local bValue = b.SortValue or 0
            if aValue ~= bValue then
                return aValue > bValue
            end

            return nil
        end,
    },
    CanScan = function()
        return GetActiveSupportedLens() ~= nil
    end,
}

function CAIWorldScannerCategory_ActiveLens.Scan(context)
    local activeLens = GetActiveSupportedLens()
    if activeLens == nil or activeLens.Scan == nil then
        return {}
    end

    return activeLens.Scan(context)
end

CAIWorldScanner:RegisterCategoryDefinition(CAIWorldScannerCategory_ActiveLens)
