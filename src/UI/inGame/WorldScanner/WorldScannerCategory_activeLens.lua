include("Civ6Common")

local Utils = CAIWorldScannerUtils
local ZoneUtils = CAIWorldScannerZoneUtils

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
local SUBCATEGORY_RELIGION = "religion"
local SUBCATEGORY_LOYALTY_LENS = "loyaltyLens"
local SUBCATEGORY_PLAGUE = "plague"

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
local LENS_RELIGION = "Religion"
local LENS_LOYALTY = "Loyalty"
local LENS_PLAGUE = "Plague"

local LAYER_SETTLER = UILens.CreateLensLayerHash("Hex_Coloring_Water_Availablity")
local LAYER_APPEAL = UILens.CreateLensLayerHash("Hex_Coloring_Appeal_Level")
local LAYER_CONTINENT = UILens.CreateLensLayerHash("Hex_Coloring_Continent")
local LAYER_OWNER = UILens.CreateLensLayerHash("Hex_Coloring_Owning_Civ")
local LAYER_GOVERNMENT = UILens.CreateLensLayerHash("Hex_Coloring_Government")
local LAYER_POWER = UILens.CreateLensLayerHash("Power_Lens")
local LAYER_TOURISM = UILens.CreateLensLayerHash("Tourist_Tokens")
local LAYER_RELIGION = UILens.CreateLensLayerHash("Hex_Coloring_Religion")
local LAYER_LOYALTY = UILens.CreateLensLayerHash("Cultural_Identity_Lens")

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
    [SUBCATEGORY_RELIGION] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_RELIGION",
    [SUBCATEGORY_LOYALTY_LENS] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_LOYALTY",
    [SUBCATEGORY_PLAGUE] = "LOC_HUD_PLAGUE_LENS",
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
            local revealedPlots = {}
            for _, plotIndex in ipairs(plots or {}) do
                local plot = Map.GetPlotByIndex(plotIndex)
                if plot ~= nil and Utils.IsPlotRevealed(context, plot) then
                    revealedPlots[#revealedPlots + 1] = plotIndex
                end
            end
            for _, zone in ipairs(ZoneUtils.PartitionPlotIndices(revealedPlots)) do
                local zoneContinentId = continentId
                AddItem(out, {
                    Id = "activeLens:" .. LENS_CONTINENT .. ":"
                        .. tostring(zoneContinentId) .. ":" .. tostring(zone.MinPlotIndex),
                    PlotIndex = zone.MinPlotIndex,
                    ZonePlotIndices = zone.PlotIndices,
                    ZoneValidatePlot = function(_, plot, validateContext)
                        return Utils.IsPlotRevealed(validateContext, plot)
                            and plot:GetContinentType() == zoneContinentId
                    end,
                    LabelKey = labelKey,
                    SubCategoryId = SUBCATEGORY_CONTINENT,
                    GroupId = "continent:" .. tostring(zoneContinentId),
                    GroupLabelKey = labelKey,
                })
            end
        end
    end

    return out
end

local function ScanOwnerLens(context)
    local out = {}
    local buckets = {}

    Utils.ForEachRevealedPlot(context, function(plotIndex, plot)
        local ownerID = plot:GetOwner()
        if not CanIdentifyPlayer(context, ownerID) then
            return
        end

        local stance = Utils.GetTeamStance(context, ownerID)
        local labelKey = Utils.GetPlayerLabel(ownerID)
        local key = stance .. ":" .. tostring(ownerID)
        local bucket = buckets[key]
        if bucket == nil then
            bucket = {
                PlotIndices = {},
                OwnerID = ownerID,
                Stance = stance,
                LabelKey = labelKey,
            }
            buckets[key] = bucket
        end
        bucket.PlotIndices[#bucket.PlotIndices + 1] = plotIndex
    end)

    for key, bucket in pairs(buckets) do
        for _, zone in ipairs(ZoneUtils.PartitionPlotIndices(bucket.PlotIndices)) do
            local ownerID = bucket.OwnerID
            local stance = bucket.Stance
            AddItem(out, {
                Id = "activeLens:" .. LENS_OWNER .. ":" .. key .. ":" .. tostring(zone.MinPlotIndex),
                PlotIndex = zone.MinPlotIndex,
                ZonePlotIndices = zone.PlotIndices,
                ZoneValidatePlot = function(_, plot, validateContext)
                    return Utils.IsPlotRevealed(validateContext, plot)
                        and plot:GetOwner() == ownerID
                        and CanIdentifyPlayer(validateContext, ownerID)
                        and Utils.GetTeamStance(validateContext, ownerID) == stance
                end,
                LabelKey = bucket.LabelKey,
                SubCategoryId = stance,
                GroupId = "player:" .. tostring(ownerID),
                GroupLabelKey = bucket.LabelKey,
            })
        end
    end

    return out
end

local function ScanGovernmentLens(context)
    local out = {}
    local buckets = {}

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
        local key = stance .. ":" .. tostring(groupId)
        local bucket = buckets[key]
        if bucket == nil then
            bucket = {
                PlotIndices = {},
                OwnerID = ownerID,
                Stance = stance,
                GovernmentGroupId = governmentGroupId,
                GovernmentLabelKey = governmentLabelKey,
                GroupId = groupId,
                LabelKey = labelKey,
            }
            buckets[key] = bucket
        end
        bucket.PlotIndices[#bucket.PlotIndices + 1] = plotIndex
    end)

    for key, bucket in pairs(buckets) do
        for _, zone in ipairs(ZoneUtils.PartitionPlotIndices(bucket.PlotIndices)) do
            local ownerID = bucket.OwnerID
            local stance = bucket.Stance
            local governmentGroupId = bucket.GovernmentGroupId
            local governmentLabelKey = bucket.GovernmentLabelKey
            local groupId = bucket.GroupId
            AddItem(out, {
                Id = "activeLens:" .. LENS_GOVERNMENT .. ":" .. key .. ":" .. tostring(zone.MinPlotIndex),
                PlotIndex = zone.MinPlotIndex,
                ZonePlotIndices = zone.PlotIndices,
                ZoneValidatePlot = function(_, plot, validateContext)
                    if not Utils.IsPlotRevealed(validateContext, plot)
                        or plot:GetOwner() ~= ownerID
                        or not CanIdentifyPlayer(validateContext, ownerID) then
                        return false
                    end

                    local validateGovernmentGroupId, validateGovernmentLabelKey =
                        GetGovernmentGroupData(ownerID)
                    if validateGovernmentGroupId ~= governmentGroupId
                        or validateGovernmentLabelKey ~= governmentLabelKey then
                        return false
                    end

                    local validateCompositeGroupId =
                        MakeGovernmentPlotLabel(validateGovernmentLabelKey, ownerID, plot)
                    return validateCompositeGroupId == groupId
                        and Utils.GetTeamStance(validateContext, ownerID) == stance
                end,
                LabelKey = bucket.LabelKey,
                SubCategoryId = stance,
                GroupId = groupId,
                GroupLabelKey = bucket.LabelKey,
            })
        end
    end

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
                local revealedPlots = {}
                for plotIndex, isPowered in pairs(poweredPlots) do
                    local plot = Map.GetPlotByIndex(plotIndex)
                    if isPowered and plot ~= nil and Utils.IsPlotRevealed(context, plot) then
                        revealedPlots[#revealedPlots + 1] = plotIndex
                    end
                end

                for _, zone in ipairs(ZoneUtils.PartitionPlotIndices(revealedPlots)) do
                    local ownerID = city:GetOwner()
                    local cityID = city:GetID()
                    AddItem(out, {
                        Id = "activeLens:" .. LENS_POWER .. ":" .. SUBCATEGORY_POWER_RANGE
                            .. ":" .. cityGroupId .. ":" .. tostring(zone.MinPlotIndex),
                        PlotIndex = zone.MinPlotIndex,
                        ZonePlotIndices = zone.PlotIndices,
                        ZoneValidatePlot = function(_, plot, validateContext)
                            if not Utils.IsPlotRevealed(validateContext, plot) then
                                return false
                            end
                            local liveCity = CityManager.GetCity(ownerID, cityID)
                            local livePower = liveCity ~= nil
                                and liveCity.GetPower ~= nil
                                and liveCity:GetPower()
                                or nil
                            local livePlots = livePower ~= nil
                                and livePower.GetPlotsCoveredByRegionalPower ~= nil
                                and livePower:GetPlotsCoveredByRegionalPower()
                                or nil
                            return livePlots ~= nil and livePlots[plot:GetIndex()]
                        end,
                        LabelKey = groupLabel,
                        SubCategoryId = SUBCATEGORY_POWER_RANGE,
                        GroupId = cityGroupId,
                        GroupLabelKey = groupLabel,
                    })
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

local GROUP_RELIGION_NO_MAJORITY = "religion:noMajority"

local function GetReligionName(religionType)
    if religionType == nil or religionType < 0 then
        return nil
    end

    local gameReligion = Game.GetReligion ~= nil and Game.GetReligion() or nil
    if gameReligion ~= nil and gameReligion.GetName ~= nil then
        local name = gameReligion:GetName(religionType)
        if name ~= nil and name ~= "" then
            return Locale.Lookup(name)
        end
    end

    return nil
end

local function ScanReligionLens(context)
    local out = {}
    local seenCities = {}

    Utils.ForEachRevealedPlot(context, function(plotIndex, plot)
        local city = Cities.GetCityInPlot(plot:GetX(), plot:GetY())
        if city == nil or city:GetX() ~= plot:GetX() or city:GetY() ~= plot:GetY() then
            return
        end

        local ownerID = city:GetOwner()
        if not Utils.CanKnowPlayer(context, ownerID) then
            return
        end

        local cityID = city:GetID()
        local uniqueKey = tostring(ownerID) .. ":" .. tostring(cityID)
        if seenCities[uniqueKey] then
            return
        end
        seenCities[uniqueKey] = true

        local cityReligion = city.GetReligion ~= nil and city:GetReligion() or nil
        if cityReligion == nil then
            return
        end

        local majorityType = cityReligion.GetMajorityReligion ~= nil and cityReligion:GetMajorityReligion() or -1
        local groupId
        local groupLabel

        if majorityType ~= nil and majorityType >= 0 then
            local religionName = GetReligionName(majorityType)
            if religionName == nil then
                return
            end
            groupId = "religion:" .. tostring(majorityType)
            groupLabel = religionName
        else
            groupId = GROUP_RELIGION_NO_MAJORITY
            groupLabel = "LOC_CAI_WORLD_SCANNER_RELIGION_NO_MAJORITY"
        end

        local cityLabel = Utils.ResolveText(Utils.GetCityLabel(city))
        local itemLabel = groupLabel ~= nil and (Utils.ResolveText(groupLabel) .. ", " .. cityLabel) or cityLabel

        AddItem(out, {
            Id = "activeLens:" .. LENS_RELIGION .. ":" .. SUBCATEGORY_RELIGION .. ":" .. groupId .. ":" .. tostring(plotIndex),
            PlotIndex = plotIndex,
            LabelKey = itemLabel,
            SubCategoryId = SUBCATEGORY_RELIGION,
            GroupId = groupId,
            GroupLabelKey = groupLabel,
            Validate = function(item, validateContext)
                local validatePlot = Map.GetPlotByIndex(item.PlotIndex)
                if validatePlot == nil or not Utils.IsPlotRevealed(validateContext, validatePlot) then
                    return false
                end

                local validateCity = Cities.GetCityInPlot(validatePlot:GetX(), validatePlot:GetY())
                if validateCity == nil or validateCity:GetOwner() ~= ownerID or validateCity:GetID() ~= cityID then
                    return false
                end

                if not Utils.CanKnowPlayer(validateContext, ownerID) then
                    return false
                end

                local validateReligion = validateCity.GetReligion ~= nil and validateCity:GetReligion() or nil
                if validateReligion == nil then
                    return false
                end

                local validateMajority = validateReligion.GetMajorityReligion ~= nil and validateReligion:GetMajorityReligion() or -1
                local validateGroupId
                if validateMajority ~= nil and validateMajority >= 0 then
                    validateGroupId = "religion:" .. tostring(validateMajority)
                else
                    validateGroupId = GROUP_RELIGION_NO_MAJORITY
                end

                return validateGroupId == item.GroupId
            end,
        })
    end)

    return out
end

local function GetLoyaltyLevelGroupData(identity)
    if identity.IsAlwaysFullyLoyal ~= nil and identity:IsAlwaysFullyLoyal() then
        return "loyaltyLevel:alwaysLoyal", "LOC_CAI_LENS_LOYALTY_ALWAYS_LOYAL"
    end

    local levelIndex = identity.GetLoyaltyLevel ~= nil and identity:GetLoyaltyLevel() or nil
    if levelIndex == nil then
        return nil, nil
    end

    local levelInfo = GameInfo.LoyaltyLevels and GameInfo.LoyaltyLevels[levelIndex] or nil
    if levelInfo == nil or levelInfo.Name == nil then
        return nil, nil
    end

    return "loyaltyLevel:" .. tostring(levelIndex), levelInfo.Name
end

local function ScanLoyaltyLens(context)
    local out = {}
    local seenCities = {}

    Utils.ForEachRevealedPlot(context, function(plotIndex, plot)
        local city = Cities.GetCityInPlot(plot:GetX(), plot:GetY())
        if city == nil or city:GetX() ~= plot:GetX() or city:GetY() ~= plot:GetY() then
            return
        end

        local ownerID = city:GetOwner()
        if not Utils.CanKnowPlayer(context, ownerID) then
            return
        end

        local cityID = city:GetID()
        local uniqueKey = tostring(ownerID) .. ":" .. tostring(cityID)
        if seenCities[uniqueKey] then
            return
        end

        local identity = city.GetCulturalIdentity ~= nil and city:GetCulturalIdentity() or nil
        if identity == nil then
            return
        end

        seenCities[uniqueKey] = true

        local groupId, groupLabelKey = GetLoyaltyLevelGroupData(identity)
        if groupId == nil or groupLabelKey == nil then
            return
        end

        local loyaltyPerTurn = identity.GetLoyaltyPerTurn ~= nil and identity:GetLoyaltyPerTurn() or 0
        local perTurnText = Locale.Lookup("LOC_CAI_LENS_LOYALTY_PER_TURN", FormatSignedNumber(math.floor(loyaltyPerTurn)))
        local cityLabel = Utils.ResolveText(Utils.GetCityLabel(city))
        local levelLabel = Utils.ResolveText(groupLabelKey)

        AddItem(out, {
            Id = "activeLens:" .. LENS_LOYALTY .. ":" .. SUBCATEGORY_LOYALTY_LENS .. ":" .. tostring(plotIndex),
            PlotIndex = plotIndex,
            LabelKey = levelLabel .. ", " .. cityLabel .. ", " .. perTurnText,
            SubCategoryId = SUBCATEGORY_LOYALTY_LENS,
            GroupId = groupId,
            GroupLabelKey = groupLabelKey,
            Validate = function(item, validateContext)
                local validatePlot = Map.GetPlotByIndex(item.PlotIndex)
                if validatePlot == nil or not Utils.IsPlotRevealed(validateContext, validatePlot) then
                    return false
                end

                local validateCity = Cities.GetCityInPlot(validatePlot:GetX(), validatePlot:GetY())
                if validateCity == nil or validateCity:GetOwner() ~= ownerID or validateCity:GetID() ~= cityID then
                    return false
                end

                if not Utils.CanKnowPlayer(validateContext, ownerID) then
                    return false
                end

                local validateIdentity = validateCity.GetCulturalIdentity ~= nil and validateCity:GetCulturalIdentity() or nil
                if validateIdentity == nil then
                    return false
                end

                local validateGroupId = GetLoyaltyLevelGroupData(validateIdentity)
                return validateGroupId == item.GroupId
            end,
        })
    end)

    return out
end

local function ScanPlagueLens(context)
    local out = {}
    local falloutManager = Game.GetFalloutManager()
    if falloutManager == nil then
        return out
    end

    Utils.ForEachRevealedPlot(context, function(plotIndex, plot)
        local plagueTurns = falloutManager:GetFalloutTurnsRemaining(plotIndex) or 0
        if plagueTurns <= 0 then
            return
        end

        local plagueLabel = Locale.Lookup("LOC_TOOLTIP_PLOT_CONTAMINATED_TEXT", plagueTurns)
        AddItem(out, {
            Id = "activeLens:" .. LENS_PLAGUE .. ":" .. SUBCATEGORY_PLAGUE .. ":" .. tostring(plotIndex),
            PlotIndex = plotIndex,
            LabelKey = plagueLabel,
            SubCategoryId = SUBCATEGORY_PLAGUE,
            GroupId = "plague:" .. tostring(plagueTurns),
            GroupLabelKey = plagueLabel,
            GroupSortValue = plagueTurns,
            Validate = function(item, validateContext)
                local validatePlot = Map.GetPlotByIndex(item.PlotIndex)
                if validatePlot == nil or not Utils.IsPlotRevealed(validateContext, validatePlot) then
                    return false
                end

                local validateFalloutManager = Game.GetFalloutManager()
                if validateFalloutManager == nil then
                    return false
                end

                local currentTurns = validateFalloutManager:GetFalloutTurnsRemaining(item.PlotIndex) or 0
                return currentTurns > 0 and item.GroupId == "plague:" .. tostring(currentTurns)
            end,
        })
    end)

    return out
end

local supportedLenses = {
    {
        Id = LENS_PLAGUE,
        IsActive = function()
            return GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_BLACKDEATH"
                and ExposedMembers.CAIPlagueLensActive == true
        end,
        Scan = ScanPlagueLens,
    },
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
    {
        Id = LENS_RELIGION,
        IsActive = function()
            return UILens.IsLayerOn(LAYER_RELIGION)
        end,
        Scan = ScanReligionLens,
    },
    {
        Id = LENS_LOYALTY,
        IsActive = function()
            return IsExpansion1Active() and UILens.IsLayerOn(LAYER_LOYALTY)
        end,
        Scan = ScanLoyaltyLens,
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
    Contextual = true,
    ManagementSettings = { "ScannerAutoFocusActiveLens" },
    BuildOncePerDynamicState = true,
    AutoFocus = true,
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
        SUBCATEGORY_RELIGION,
        SUBCATEGORY_LOYALTY_LENS,
        SUBCATEGORY_PLAGUE,
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
        [SUBCATEGORY_PLAGUE] = function(a, b)
            local aValue = a.SortValue or 0
            local bValue = b.SortValue or 0
            if aValue ~= bValue then
                return aValue > bValue
            end

            return nil
        end,
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
