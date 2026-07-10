include("caiUtils")
include("interfaceInfoHelpers_CAI")
include("inGameHelpers_CAI")
include("hexCoordUtils_CAI")
include("Civ6Common")

local HexCoordUtils = CAIHexCoordUtils

local function IsBarbarianClansModeActive()
    return GameConfiguration.GetValue("GAMEMODE_BARBARIAN_CLANS") == true
end

local function GetPlotToolTipIncludeName()
    if IsExpansion2Active() then
        if IsBarbarianClansModeActive() then
            return "PlotTooltip_Expansion2_BarbarianClansMode"
        end
        return "PlotTooltip_Expansion2"
    end

    if IsBarbarianClansModeActive() then
        return "PlotToolTip_BarbarianClansMode"
    end

    return "PlotToolTip"
end

local PLOT_TOOLTIP_INCLUDE = GetPlotToolTipIncludeName()
local IS_XP2_TOOLTIP = PLOT_TOOLTIP_INCLUDE == "PlotTooltip_Expansion2"
    or PLOT_TOOLTIP_INCLUDE == "PlotTooltip_Expansion2_BarbarianClansMode"
local IS_BARBARIAN_CLANS_TOOLTIP = PLOT_TOOLTIP_INCLUDE == "PlotToolTip_BarbarianClansMode"
    or PLOT_TOOLTIP_INCLUDE == "PlotTooltip_Expansion2_BarbarianClansMode"

include(PLOT_TOOLTIP_INCLUDE)

local currentPlot = -1
local info = ExposedMembers.CAIInfo or {}
ExposedMembers.CAIInfo = info


local STATIC_INFO_PRIORITY = {
    "plotName",
    "mapTac",
    "owner",
    "feature",
    "nationalPark",
    "resource",
    "volcano",
    "freshWater",
    "river",
    "cliff",
    "territory",
    "storm",
    "drought",
    "movement",
    "waypoint",
    "route",
    "defense",
    "appeal",
    "continent",
    "coastalLowland",
    "wonderTitle",
    "cityDistrictTitle",
    "cityResourceExtraction",
    "districtSpecialistsHeader",
    "districtTitle",
    "districtResourceExtraction",
    "improvement",
    "barbarianClan",
    "plotResourceExtraction",
    "impassable",
    "naturalWonder",
    "buildingsHeader",
    "greatWorksHeader",
    "workers",
    "fallout",
    "units",
    "interfaceInfo",
    "lensInfo",
}

local CURSOR_MOVE_INFO_PRIORITY = {
    "isFog",
    "units",
    "mapTac",
    "interfaceInfo",
    "lensInfo",
    "waypoint",
    "fallout",
    "coastalLowland",
    "volcano",
    "storm",
    "drought",
    "cityName",
    "wonderTitle",
    "districtTitle",
    "plotName",
    "feature",
    "resource",
    "improvement",
    "routeName",
    "barbarianClan",
    "river",
    "cliff",
    "workers",
    "recommendation",
}

local PlotInfoActionRequestBuilders = {}

local function GetCurrentCursorPlot()
    return Map.GetPlotByIndex(currentPlot)
end

local function AddIfPresent(results, value)
    if value == nil then
        return
    end

    if type(value) == "table" then
        for _, innerValue in ipairs(value) do
            AddIfPresent(results, innerValue)
        end
        return
    end

    if value ~= "" then
        table.insert(results, value)
    end
end

local function HasEntries(t)
    return t ~= nil and next(t) ~= nil
end

local function GetOrderedYieldTypes(yieldTable)
    local ordered = {}
    if yieldTable == nil then
        return ordered
    end

    for row in GameInfo.Yields() do
        if yieldTable[row.YieldType] ~= nil then
            table.insert(ordered, row.YieldType)
        end
    end

    return ordered
end

local function GetYieldLine(yieldType, amount)
    local yieldInfo = GameInfo.Yields[yieldType]
    if yieldInfo == nil or amount == nil then
        return nil
    end

    return tostring(amount) .. Locale.Lookup(yieldInfo.IconString) .. Locale.Lookup(yieldInfo.Name)
end

local function GetRelativeCoordinateString(plot)
    if plot == nil then
        return nil
    end

    local coordinateString = HexCoordUtils.coordinateString(plot:GetX(), plot:GetY())
    if coordinateString == nil or coordinateString == "" then
        return nil
    end

    return coordinateString
end

local function BuildPlotInfoData(plot)
    if not plot then
        return nil
    end

    local data = FetchData(plot)
    FetchAdditionalData(plot, data)
    data.IsVisible = info.IsPlotVisible(plot:GetIndex())
    data.Units = Units.GetUnitsInPlotLayerID(plot:GetX(), plot:GetY(), MapLayers.ANY)

    return data
end

local function GetPlotFeatureInfo(data)
    if data.FeatureType == nil then
        return nil
    end
    return GameInfo.Features[data.FeatureType]
end

local function GetPlotResourceContext(data)
    if data._CAIResourceContext ~= nil then
        return data._CAIResourceContext
    end

    if data.ResourceType == nil then
        data._CAIResourceContext = false
        return nil
    end

    local resource = GameInfo.Resources[data.ResourceType]
    if resource == nil then
        data._CAIResourceContext = false
        return nil
    end

    local context = {
        Resource = resource,
        ResourceHash = resource.Hash,
        ResourceString = Locale.Lookup(resource.Name),
        ResourceTechType = nil,
        ValidFeature = false,
        ValidTerrain = false,
        ValidResources = false,
    }

    local terrainInfo = data.TerrainType ~= nil and GameInfo.Terrains[data.TerrainType] or nil

    for row in GameInfo.Improvement_ValidResources() do
        if row.ResourceType == data.ResourceType then
            local improvementType = row.ImprovementType
            local improvement = GameInfo.Improvements[improvementType]

            if improvement ~= nil then
                local hasFeature = false
                for innerRow in GameInfo.Improvement_ValidFeatures() do
                    if innerRow.ImprovementType == improvementType then
                        hasFeature = true
                        if innerRow.FeatureType == data.FeatureType then
                            context.ValidFeature = true
                        end
                    end
                end
                if not hasFeature then
                    context.ValidFeature = true
                end

                local hasTerrain = false
                for innerRow in GameInfo.Improvement_ValidTerrains() do
                    if innerRow.ImprovementType == improvementType then
                        hasTerrain = true
                        if innerRow.TerrainType == data.TerrainType then
                            context.ValidTerrain = true
                        end
                    end
                end
                if not hasTerrain then
                    context.ValidTerrain = true
                end

                for innerRow in GameInfo.Improvement_ValidResources() do
                    if innerRow.ImprovementType == improvementType and innerRow.ResourceType == data.ResourceType then
                        context.ValidResources = true
                        break
                    end
                end

                if terrainInfo ~= nil then
                    if terrainInfo.TerrainType == "TERRAIN_COAST" then
                        if improvement.Domain == "DOMAIN_SEA" then
                            context.ValidTerrain = true
                        elseif improvement.Domain == "DOMAIN_LAND" then
                            context.ValidTerrain = false
                        end
                    else
                        if improvement.Domain == "DOMAIN_SEA" then
                            context.ValidTerrain = false
                        elseif improvement.Domain == "DOMAIN_LAND" then
                            context.ValidTerrain = true
                        end
                    end
                end

                if (context.ValidFeature and context.ValidTerrain) or context.ValidResources then
                    context.ResourceTechType = improvement.PrereqTech
                    break
                end
            end
        end
    end

    data._CAIResourceContext = context
    return context
end

local function GetVisibleResourceString(data)
    local context = GetPlotResourceContext(data)
    if context == nil then
        return nil
    end

    local localPlayer = Players[Game.GetLocalPlayer()]
    if localPlayer ~= nil then
        local playerResources = localPlayer:GetResources()
        if not playerResources:IsResourceVisible(context.ResourceHash) then
            return nil
        end

        local resourceString = context.ResourceString
        if context.ResourceTechType ~= nil and ((context.ValidFeature and context.ValidTerrain) or context.ValidResources) then
            local playerTechs = localPlayer:GetTechs()
            local techType = GameInfo.Technologies[context.ResourceTechType]
            if techType ~= nil and not playerTechs:HasTech(techType.Index) then
                resourceString = resourceString
                    .. "[COLOR:Civ6Red]  ( "
                    .. Locale.Lookup("LOC_TOOLTIP_REQUIRES")
                    .. " "
                    .. Locale.Lookup(techType.Name)
                    .. ")[ENDCOLOR]"
            end
        end

        return resourceString
    elseif GameConfiguration.IsWorldBuilderEditor() then
        local resourceString = context.ResourceString
        if context.ResourceTechType ~= nil and ((context.ValidFeature and context.ValidTerrain) or context.ValidResources) then
            local techType = GameInfo.Technologies[context.ResourceTechType]
            if techType ~= nil then
                resourceString = resourceString
                    .. "( "
                    .. Locale.Lookup("LOC_TOOLTIP_REQUIRES")
                    .. " "
                    .. Locale.Lookup(techType.Name)
                    .. ")[ENDCOLOR]"
            end
        end

        return resourceString
    end

    return nil
end

local function GetResourceAccumulationString(data, plot, requiresExtractablePlot)
    if not IS_XP2_TOOLTIP or data.ResourceType == nil then
        return nil
    end

    local localPlayer = Players[Game.GetLocalPlayer()]
    if localPlayer == nil then
        return nil
    end

    local context = GetPlotResourceContext(data)
    if context == nil then
        return nil
    end

    local playerResources = localPlayer:GetResources()
    if not playerResources:IsResourceVisible(context.ResourceHash) then
        return nil
    end

    if requiresExtractablePlot and (plot == nil or not playerResources:IsResourceExtractableAt(plot)) then
        return nil
    end

    local resourceTechType = GameInfo.Resources[data.ResourceType].PrereqTech
    if resourceTechType == nil then
        return nil
    end

    local techType = GameInfo.Technologies[resourceTechType]
    if techType == nil or not localPlayer:GetTechs():HasTech(techType.Index) then
        return nil
    end

    local consumption = GameInfo.Resource_Consumption[data.ResourceType]
    if consumption == nil or not consumption.Accumulate then
        return nil
    end

    local extraction = consumption.ImprovedExtractionRate
    if extraction == nil or extraction <= 0 then
        return nil
    end

    return Locale.Lookup(
        "LOC_RESOURCE_ACCUMULATION_EXISTING_IMPROVEMENT",
        extraction,
        "[ICON_" .. data.ResourceType .. "]",
        GameInfo.Resources[data.ResourceType].Name
    )
end

local function GetCoastalLowlandString(data)
    if not IS_XP2_TOOLTIP or data.CoastalLowland == nil or data.CoastalLowland == -1 then
        return nil
    end

    local detailText = ""
    if data.CoastalLowland == 0 then
        detailText = Locale.Lookup("LOC_COASTAL_LOWLAND_1M_NAME")
    elseif data.CoastalLowland == 1 then
        detailText = Locale.Lookup("LOC_COASTAL_LOWLAND_2M_NAME")
    elseif data.CoastalLowland == 2 then
        detailText = Locale.Lookup("LOC_COASTAL_LOWLAND_3M_NAME")
    end

    if data.Submerged then
        detailText = detailText .. " " .. Locale.Lookup("LOC_COASTAL_LOWLAND_SUBMERGED")
    elseif data.Flooded then
        detailText = detailText .. " " .. Locale.Lookup("LOC_COASTAL_LOWLAND_FLOODED")
    end

    return detailText ~= "" and detailText or nil
end

local function GetVolcanoString(data)
    if not IS_XP2_TOOLTIP or not data.IsVolcano then
        return nil
    end

    local volcanoString = Locale.Lookup("LOC_VOLCANO_TOOLTIP_STRING", data.VolcanoName)
    if data.Erupting then
        volcanoString = volcanoString .. " " .. Locale.Lookup("LOC_VOLCANO_ERUPTING_STRING")
    elseif data.Active then
        volcanoString = volcanoString .. " " .. Locale.Lookup("LOC_VOLCANO_ACTIVE_STRING")
    end

    return volcanoString
end

local function BuildDefaultRequestedKeys(data)
    local keys = {}
    for _, key in ipairs(STATIC_INFO_PRIORITY) do
        table.insert(keys, key)

        if key == "cityDistrictTitle" then
            for _, yieldType in ipairs(GetOrderedYieldTypes(data.Yields)) do
                table.insert(keys, "cityYield:" .. yieldType)
            end
        elseif key == "districtSpecialistsHeader" then
            for _, yieldType in ipairs(GetOrderedYieldTypes(data.Yields)) do
                table.insert(keys, "districtSpecialistYield:" .. yieldType)
            end
        elseif key == "districtTitle" then
            for _, yieldType in ipairs(GetOrderedYieldTypes(data.DistrictYields)) do
                table.insert(keys, "districtYield:" .. yieldType)
            end
        elseif key == "improvement" then
            for _, yieldType in ipairs(GetOrderedYieldTypes(data.Yields)) do
                table.insert(keys, "plotYield:" .. yieldType)
            end
        elseif key == "buildingsHeader" and data.BuildingNames ~= nil then
            for i = 1, #data.BuildingNames do
                table.insert(keys, "building:" .. tostring(i))
            end
        elseif key == "greatWorksHeader" then
            local greatWorkCount = data._CAIGreatWorkCount or 0
            for i = 1, greatWorkCount do
                table.insert(keys, "greatWork:" .. tostring(i))
            end
        end
    end
    return keys
end

function info.IsPlotVisible(plot)
    if not plot then return false end
    local observer = Game.GetLocalObserver()
    if observer == PlayerTypes.OBSERVER then return true end
    local vis = PlayersVisibility[observer]
    if not vis then return false end
    return vis:IsRevealed(plot)
end

function info.IsPlotFogged(plot)
    if not plot then
        return false
    end

    local observer = Game.GetLocalObserver()
    if observer == PlayerTypes.OBSERVER then
        return false
    end

    local vis = PlayersVisibility[observer]
    if vis == nil then
        return false
    end

    return vis:IsRevealed(plot) and not vis:IsVisible(plot:GetIndex())
end

local function CacheGreatWorks(data)
    if data._CAIGreatWorksCached then
        return
    end

    data._CAIGreatWorksCached = true
    data._CAIGreatWorks = {}

    if data.BuildingNames == nil or data.OwnerCity == nil then
        data._CAIGreatWorkCount = 0
        return
    end

    local cityBuildings = data.OwnerCity:GetBuildings()
    if cityBuildings == nil then
        data._CAIGreatWorkCount = 0
        return
    end

    for i = 1, #data.BuildingNames do
        local slots = cityBuildings:GetNumGreatWorkSlots(data.BuildingTypes[i])
        for j = 0, slots - 1 do
            local idx = cityBuildings:GetGreatWorkInSlot(data.BuildingTypes[i], j)
            if idx ~= -1 then
                local greatWorkType = cityBuildings:GetGreatWorkTypeFromIndex(idx)
                local greatWork = GameInfo.GreatWorks[greatWorkType]
                if greatWork ~= nil then
                    table.insert(data._CAIGreatWorks, "- " .. Locale.Lookup(greatWork.Name))
                end
            end
        end
    end

    data._CAIGreatWorkCount = #data._CAIGreatWorks
end

local RIVER_SELF_EDGES = {
    { dir = "LOC_CAI_DIR_E",  hasRiver = function(p) return p ~= nil and p:IsWOfRiver() end },
    { dir = "LOC_CAI_DIR_SE", hasRiver = function(p) return p ~= nil and p:IsNWOfRiver() end },
    { dir = "LOC_CAI_DIR_SW", hasRiver = function(p) return p ~= nil and p:IsNEOfRiver() end },
}

local RIVER_NEIGHBOR_EDGES = {
    {
        dir = "LOC_CAI_DIR_W",
        neighborDir = DirectionTypes.DIRECTION_WEST,
        hasRiver = function(p)
            return p ~= nil and p:IsWOfRiver()
        end
    },
    {
        dir = "LOC_CAI_DIR_NW",
        neighborDir = DirectionTypes.DIRECTION_NORTHWEST,
        hasRiver = function(p)
            return p ~= nil and p:IsNWOfRiver()
        end
    },
    {
        dir = "LOC_CAI_DIR_NE",
        neighborDir = DirectionTypes.DIRECTION_NORTHEAST,
        hasRiver = function(p)
            return p ~= nil and p:IsNEOfRiver()
        end
    },
}

local RIVER_SPOKEN_ORDER = {
    "LOC_CAI_DIR_NE",
    "LOC_CAI_DIR_E",
    "LOC_CAI_DIR_SE",
    "LOC_CAI_DIR_SW",
    "LOC_CAI_DIR_W",
    "LOC_CAI_DIR_NW",
}

local CLIFF_SELF_EDGES = {
    { dir = "LOC_CAI_DIR_E",  hasCliff = function(p) return p ~= nil and p:IsWOfCliff() end },
    { dir = "LOC_CAI_DIR_SE", hasCliff = function(p) return p ~= nil and p:IsNWOfCliff() end },
    { dir = "LOC_CAI_DIR_SW", hasCliff = function(p) return p ~= nil and p:IsNEOfCliff() end },
}

local CLIFF_NEIGHBOR_EDGES = {
    {
        dir = "LOC_CAI_DIR_W",
        neighborDir = DirectionTypes.DIRECTION_WEST,
        hasCliff = function(p)
            return p ~= nil and p:IsWOfCliff()
        end
    },
    {
        dir = "LOC_CAI_DIR_NW",
        neighborDir = DirectionTypes.DIRECTION_NORTHWEST,
        hasCliff = function(p)
            return p ~= nil and p:IsNWOfCliff()
        end
    },
    {
        dir = "LOC_CAI_DIR_NE",
        neighborDir = DirectionTypes.DIRECTION_NORTHEAST,
        hasCliff = function(p)
            return p ~= nil and p:IsNEOfCliff()
        end
    },
}

local function GetCliffDirectionString(plot)
    if plot == nil then
        return nil
    end

    if not plot:IsNWOfCliff() and not plot:IsWOfCliff() and not plot:IsNEOfCliff() then
        local x = plot:GetX()
        local y = plot:GetY()
        local hasAny = false
        for _, edge in ipairs(CLIFF_NEIGHBOR_EDGES) do
            local neighbor = Map.GetAdjacentPlot(x, y, edge.neighborDir)
            if edge.hasCliff(neighbor) then
                hasAny = true
                break
            end
        end
        if not hasAny then
            return nil
        end
    end

    local presentEdges = {}
    for _, edge in ipairs(CLIFF_SELF_EDGES) do
        if edge.hasCliff(plot) then
            presentEdges[edge.dir] = true
        end
    end

    local x = plot:GetX()
    local y = plot:GetY()
    for _, edge in ipairs(CLIFF_NEIGHBOR_EDGES) do
        local neighbor = Map.GetAdjacentPlot(x, y, edge.neighborDir)
        if edge.hasCliff(neighbor) then
            presentEdges[edge.dir] = true
        end
    end

    local directions = {}
    for _, dirTag in ipairs(RIVER_SPOKEN_ORDER) do
        if presentEdges[dirTag] then
            table.insert(directions, Locale.Lookup(dirTag))
        end
    end

    if #directions == 0 then
        return nil
    end

    return table.concat(directions, " ")
end

local function GetRiverDirectionString(plot)
    if plot == nil or not plot:IsRiver() then
        return nil
    end

    local presentEdges = {}
    for _, edge in ipairs(RIVER_SELF_EDGES) do
        if edge.hasRiver(plot) then
            presentEdges[edge.dir] = true
        end
    end

    local x = plot:GetX()
    local y = plot:GetY()
    for _, edge in ipairs(RIVER_NEIGHBOR_EDGES) do
        local neighbor = Map.GetAdjacentPlot(x, y, edge.neighborDir)
        if edge.hasRiver(neighbor) then
            presentEdges[edge.dir] = true
        end
    end

    local directions = {}
    for _, dirTag in ipairs(RIVER_SPOKEN_ORDER) do
        if presentEdges[dirTag] then
            table.insert(directions, Locale.Lookup(dirTag))
        end
    end

    if #directions == 0 then
        return nil
    end

    return table.concat(directions, " ")
end

local function LogRiverDebug(plot, data, directionString)
    if plot == nil then
        return
    end

    local function TryRiverCrossingToPlot(sourcePlot, targetPlot)
        if sourcePlot == nil or targetPlot == nil then
            return "nil"
        end

        local ok, result = pcall(function()
            return sourcePlot:IsRiverCrossingToPlot(targetPlot)
        end)

        if not ok then
            return "error"
        end

        return tostring(result)
    end

    local x = plot:GetX()
    local y = plot:GetY()
    local northeast = Map.GetAdjacentPlot(x, y, DirectionTypes.DIRECTION_NORTHEAST)
    local west = Map.GetAdjacentPlot(x, y, DirectionTypes.DIRECTION_WEST)
    local northwest = Map.GetAdjacentPlot(x, y, DirectionTypes.DIRECTION_NORTHWEST)
    local riverNames = data ~= nil and data.RiverNames or nil
    local riverNameText = ""
    if type(riverNames) == "table" then
        local parts = {}
        for _, name in pairs(riverNames) do
            if name ~= nil and name ~= "" then
                table.insert(parts, tostring(name))
            end
        end
        riverNameText = table.concat(parts, "|")
    elseif riverNames ~= nil then
        riverNameText = tostring(riverNames)
    end

    print(string.format(
        "CAI_RIVER_DEBUG plot=(%d,%d) isRiver=%s isRiverAdjacent=%s isRiverSide=%s isRiverCrossing=%s names=%s directions=%s self[E<-W=%s,SE<-NW=%s,SW<-NE=%s] west[W<-W=%s] northwest[NW<-NW=%s] northeast[NE<-NE=%s] crossingTo[NE=%s,E=%s,SE=%s,SW=%s,W=%s,NW=%s]",
        x,
        y,
        tostring(plot:IsRiver()),
        tostring(plot:IsRiverAdjacent()),
        tostring(plot:IsRiverSide()),
        tostring(plot:IsRiverCrossing()),
        riverNameText,
        tostring(directionString),
        tostring(plot:IsWOfRiver()),
        tostring(plot:IsNWOfRiver()),
        tostring(plot:IsNEOfRiver()),
        tostring(west ~= nil and west:IsWOfRiver() or false),
        tostring(northwest ~= nil and northwest:IsNWOfRiver() or false),
        tostring(northeast ~= nil and northeast:IsNEOfRiver() or false),
        TryRiverCrossingToPlot(plot, northeast),
        TryRiverCrossingToPlot(plot, Map.GetAdjacentPlot(x, y, DirectionTypes.DIRECTION_EAST)),
        TryRiverCrossingToPlot(plot, Map.GetAdjacentPlot(x, y, DirectionTypes.DIRECTION_SOUTHEAST)),
        TryRiverCrossingToPlot(plot, Map.GetAdjacentPlot(x, y, DirectionTypes.DIRECTION_SOUTHWEST)),
        TryRiverCrossingToPlot(plot, west),
        TryRiverCrossingToPlot(plot, northwest)
    ))
end

local function FormatNamedRiverString(riverNames, directionString)
    if riverNames == nil then
        return nil
    end

    local localizedNames = {}
    if type(riverNames) == "table" then
        for _, riverName in pairs(riverNames) do
            if riverName ~= nil and riverName ~= "" then
                local riverText = Locale.Lookup("LOC_RIVER_TOOLTIP_STRING", riverName)
                if directionString ~= nil and directionString ~= "" then
                    riverText = Locale.Lookup("LOC_CAI_PLOT_RIVER_WITH_DIRECTIONS", riverText, directionString)
                end
                table.insert(localizedNames, riverText)
            end
        end
    else
        local riverText = Locale.Lookup("LOC_RIVER_TOOLTIP_STRING", riverNames)
        if directionString ~= nil and directionString ~= "" then
            riverText = Locale.Lookup("LOC_CAI_PLOT_RIVER_WITH_DIRECTIONS", riverText, directionString)
        end
        table.insert(localizedNames, riverText)
    end

    if #localizedNames == 0 then
        return nil
    end

    return table.concat(localizedNames, ", ")
end

local function GetPlainRiverString(data, plot)
    if not data.IsVisible or not data.IsRiver then
        return nil
    end

    local directionString = GetRiverDirectionString(plot)
    LogRiverDebug(plot, data, directionString)

    local riverString = Locale.Lookup("LOC_TOOLTIP_RIVER")
    if directionString ~= nil then
        return Locale.Lookup("LOC_CAI_PLOT_RIVER_WITH_DIRECTIONS", riverString, directionString)
    end

    return riverString
end

local function GetNamedRiverString(data, plot)
    if not data.IsVisible or not data.IsRiver then
        return nil
    end

    local directionString = GetRiverDirectionString(plot)
    LogRiverDebug(plot, data, directionString)

    if IS_XP2_TOOLTIP and data.RiverNames then
        local riverString = FormatNamedRiverString(data.RiverNames, directionString)
        if riverString ~= nil then
            return riverString
        end
    end

    local riverString = Locale.Lookup("LOC_TOOLTIP_RIVER")
    if directionString ~= nil then
        return Locale.Lookup("LOC_CAI_PLOT_RIVER_WITH_DIRECTIONS", riverString, directionString)
    end

    return riverString
end


---@type table<string, fun(data:table, plot:table, arg:string|nil):string|string[]|nil>
info.PlotInfoHelpers = {
    isFog = function(data, plot)
        if plot == nil or info.IsPlotFogged == nil then
            return nil
        end

        if info.IsPlotFogged(plot) then
            return Locale.Lookup("LOC_CAI_PLOT_FOG")
        end

        return nil
    end,

    plotName = function(data)
        if not data.IsVisible then
            return Locale.Lookup("LOC_MINIMAP_FOG_OF_WAR_TOOLTIP")
        end
        if data.IsLake then
            return Locale.Lookup("LOC_TOOLTIP_LAKE")
        end
        if data.TerrainTypeName == "LOC_TERRAIN_COAST_NAME" then
            return Locale.Lookup("LOC_TOOLTIP_COAST")
        end
        return Locale.Lookup(data.TerrainTypeName)
    end,

    relativeCoords = function(data, plot)
        return GetRelativeCoordinateString(plot)
    end,

    cityName = function(data)
        if not data.IsVisible or data.OwningCityName == nil or data.OwningCityName == "" then
            return nil
        end
        return Locale.Lookup(data.OwningCityName)
    end,

    owner = function(data)
        if not data.IsVisible or data.Owner == nil then return nil end

        local ownerString
        local playerConfig = PlayerConfigurations[data.Owner]

        if playerConfig ~= nil then
            ownerString = Locale.Lookup(playerConfig:GetCivilizationShortDescription())
        end

        if ownerString == nil or string.len(ownerString) == 0 then
            ownerString = Locale.Lookup("LOC_TOOLTIP_PLAYER_ID", data.Owner)
        end

        local player = Players[data.Owner]
        if GameConfiguration:IsAnyMultiplayer() and player ~= nil and player:IsHuman() then
            ownerString = ownerString .. " (" .. Locale.Lookup(playerConfig:GetPlayerName()) .. ")"
        end

        return Locale.Lookup("LOC_TOOLTIP_CITY_OWNER", ownerString, data.OwningCityName)
    end,

    feature = function(data)
        if not data.IsVisible or data.FeatureType == nil then return nil end

        local featureInfo = GetPlotFeatureInfo(data)
        if featureInfo == nil then
            return nil
        end

        local featureString = Locale.Lookup(featureInfo.Name)
        local localPlayer = Players[Game.GetLocalPlayer()]
        local addCivicName = featureInfo.AddCivic

        if localPlayer ~= nil and addCivicName ~= nil then
            local civicInfo = GameInfo.Civics[addCivicName]
            if civicInfo ~= nil and localPlayer:GetCulture():HasCivic(civicInfo.Index) then
                local additionalString
                if not data.FeatureAdded then
                    additionalString = Locale.Lookup("LOC_TOOLTIP_PLOT_WOODS_OLD_GROWTH")
                else
                    additionalString = Locale.Lookup("LOC_TOOLTIP_PLOT_WOODS_SECONDARY")
                end
                featureString = featureString .. " " .. additionalString
            end
        end

        return featureString
    end,

    nationalPark = function(data)
        if not data.IsVisible or data.NationalPark == "" then return nil end
        return data.NationalPark
    end,

    resource = function(data)
        if not data.IsVisible then return nil end
        return GetVisibleResourceString(data)
    end,

    volcano = function(data)
        if not data.IsVisible then return nil end
        return GetVolcanoString(data)
    end,

    freshWater = function(data, plot)
        if not data.IsVisible or plot == nil then return nil end
        if plot:IsFreshWater() then
            return Locale.Lookup("LOC_SETTLEMENT_RECOMMENDATION_FRESH_WATER")
        end
        return nil
    end,

    river = function(data, plot)
        return GetPlainRiverString(data, plot)
    end,

    riverNamed = function(data, plot)
        return GetNamedRiverString(data, plot)
    end,

    cliff = function(data, plot)
        if not data.IsVisible then return nil end
        local directionString = GetCliffDirectionString(plot)
        if directionString == nil then
            return nil
        end
        local cliffString = Locale.Lookup("LOC_TOOLTIP_CLIFF")
        return Locale.Lookup("LOC_CAI_PLOT_CLIFF_WITH_DIRECTIONS", cliffString, directionString)
    end,

    territory = function(data)
        if not data.IsVisible or not IS_XP2_TOOLTIP or data.TerritoryName == nil then return nil end
        return Locale.Lookup(data.TerritoryName)
    end,

    storm = function(data)
        if not data.IsVisible or not IS_XP2_TOOLTIP or data.Storm == nil or data.Storm == -1 then return nil end
        local randomEvent = GameInfo.RandomEvents[data.Storm]
        return randomEvent ~= nil and Locale.Lookup(randomEvent.Name) or nil
    end,

    drought = function(data)
        if not data.IsVisible or not IS_XP2_TOOLTIP or data.Drought == nil or data.Drought == -1 then return nil end
        local randomEvent = GameInfo.RandomEvents[data.Drought]
        if randomEvent == nil then
            return nil
        end
        return Locale.Lookup("LOC_DROUGHT_TOOLTIP_STRING", randomEvent.Name, data.DroughtTurns)
    end,

    movement = function(data)
        if not data.IsVisible then return nil end
        if not data.Impassable and data.MovementCost > 0 then
            return Locale.Lookup("LOC_TOOLTIP_MOVEMENT_COST", data.MovementCost)
        end
        return nil
    end,

    waypoint = function(data, plot)
        if plot == nil or info.IsWaypointPlot == nil then
            return nil
        end

        if info:IsWaypointPlot(plot:GetIndex()) then
            return Locale.Lookup("LOC_CAI_PLOT_WAYPOINT")
        end

        return nil
    end,

    routeName = function(data)
        if not data.IsVisible or not data.IsRoute then return nil end
        if IS_XP2_TOOLTIP and data.Impassable then
            return nil
        end

        local routeInfo = GameInfo.Routes[data.RouteType]
        if routeInfo == nil or routeInfo.MovementCost == nil or routeInfo.Name == nil then
            return nil
        end

        if data.RoutePillaged then
            return Locale.Lookup(routeInfo.Name) .. " " .. Locale.Lookup("LOC_TOOLTIP_PLOT_PILLAGED_TEXT")
        end

        return Locale.Lookup(routeInfo.Name)
    end,

    route = function(data)
        if not data.IsVisible or not data.IsRoute then return nil end
        if IS_XP2_TOOLTIP and data.Impassable then
            return nil
        end

        local routeInfo = GameInfo.Routes[data.RouteType]
        if routeInfo == nil or routeInfo.MovementCost == nil or routeInfo.Name == nil then
            return nil
        end

        if data.RoutePillaged then
            return Locale.Lookup("LOC_TOOLTIP_ROUTE_MOVEMENT_PILLAGED", routeInfo.MovementCost, routeInfo.Name)
        end
        return Locale.Lookup("LOC_TOOLTIP_ROUTE_MOVEMENT", routeInfo.MovementCost, routeInfo.Name)
    end,

    defense = function(data)
        if not data.IsVisible or data.DefenseModifier == 0 then return nil end
        return Locale.Lookup("LOC_TOOLTIP_DEFENSE_MODIFIER", data.DefenseModifier)
    end,

    appeal = function(data)
        if not data.IsVisible then return nil end

        local featureInfo = GetPlotFeatureInfo(data)
        if not GameCapabilities.HasCapability("CAPABILITY_LENS_APPEAL") then
            return nil
        end

        if ((data.FeatureType ~= nil and featureInfo ~= nil and featureInfo.NaturalWonder) or not data.IsWater) then
            for row in GameInfo.AppealHousingChanges() do
                if data.Appeal >= row.MinimumValue then
                    return Locale.Lookup("LOC_TOOLTIP_APPEAL", Locale.Lookup(row.Description), data.Appeal)
                end
            end
        end

        return nil
    end,

    continent = function(data)
        if not data.IsVisible or data.Continent == nil then return nil end
        local continent = GameInfo.Continents[data.Continent]
        return continent ~= nil and Locale.Lookup("LOC_TOOLTIP_CONTINENT", continent.Description) or nil
    end,

    coastalLowland = function(data)
        if not data.IsVisible then return nil end
        return GetCoastalLowlandString(data)
    end,

    wonderTitle = function(data)
        if not data.IsVisible or data.WonderType == nil then return nil end
        local wonderInfo = GameInfo.Buildings[data.WonderType]
        if wonderInfo == nil then
            return nil
        end
        local wonderName = Locale.Lookup(wonderInfo.Name)
        if data.WonderComplete then
            return wonderName
        end
        return wonderName .. " " .. Locale.Lookup("LOC_TOOLTIP_PLOT_CONSTRUCTION_TEXT")
    end,

    cityDistrictTitle = function(data)
        if not data.IsVisible or not data.IsCity or data.DistrictType == nil then return nil end
        local districtInfo = GameInfo.Districts[data.DistrictType]
        return districtInfo ~= nil and Locale.Lookup(districtInfo.Name) or nil
    end,

    cityResourceExtraction = function(data, plot)
        if not data.IsVisible or not IS_XP2_TOOLTIP or not data.IsCity or data.DistrictType == nil then return nil end
        return GetResourceAccumulationString(data, plot, false)
    end,

    districtSpecialistsHeader = function(data)
        if not data.IsVisible or data.DistrictID == -1 or data.DistrictType == nil then return nil end
        if GameInfo.Districts[data.DistrictType] == nil or GameInfo.Districts[data.DistrictType].InternalOnly then
            return nil
        end
        if data.Owner ~= Game.GetLocalPlayer() or not HasEntries(data.Yields) then
            return nil
        end
        return Locale.Lookup("LOC_PEDIA_CONCEPTS_PAGE_CITIES_9_CHAPTER_CONTENT_TITLE")
    end,

    districtTitle = function(data)
        if not data.IsVisible or data.DistrictID == -1 or data.DistrictType == nil then return nil end

        local districtInfo = GameInfo.Districts[data.DistrictType]
        if districtInfo == nil or districtInfo.InternalOnly then
            return nil
        end

        local districtName = Locale.Lookup(districtInfo.Name)
        if data.DistrictPillaged then
            districtName = districtName .. " " .. Locale.Lookup("LOC_TOOLTIP_PLOT_PILLAGED_TEXT")
        elseif not data.DistrictComplete then
            districtName = districtName .. " " .. Locale.Lookup("LOC_TOOLTIP_PLOT_CONSTRUCTION_TEXT")
        end

        return districtName
    end,

    districtResourceExtraction = function(data, plot)
        if not data.IsVisible or not IS_XP2_TOOLTIP or data.IsCity or data.DistrictID == -1 or data.DistrictType == nil then return nil end
        local districtInfo = GameInfo.Districts[data.DistrictType]
        if districtInfo == nil or districtInfo.InternalOnly then
            return nil
        end
        return GetResourceAccumulationString(data, plot, false)
    end,

    improvement = function(data)
        if not data.IsVisible then return nil end

        if data.WonderType ~= nil or (data.IsCity and data.DistrictType ~= nil) then
            return nil
        end

        if data.DistrictID ~= -1 and data.DistrictType ~= nil then
            return nil
        end

        if IS_XP2_TOOLTIP then
            if data.ImprovementType ~= nil then
                local improvementInfo = GameInfo.Improvements[data.ImprovementType]
                if improvementInfo == nil then
                    return nil
                end
                local improvementString = Locale.Lookup(improvementInfo.Name)
                if data.ImprovementPillaged then
                    improvementString = improvementString .. " " .. Locale.Lookup("LOC_TOOLTIP_PLOT_PILLAGED_TEXT")
                end
                return improvementString
            end
            return nil
        end

        if data.Impassable then
            return nil
        end

        if data.ImprovementType ~= nil then
            local improvementInfo = GameInfo.Improvements[data.ImprovementType]
            if improvementInfo == nil then
                return nil
            end
            local improvementString = Locale.Lookup(improvementInfo.Name)
            if data.ImprovementPillaged then
                improvementString = improvementString .. " " .. Locale.Lookup("LOC_TOOLTIP_PLOT_PILLAGED_TEXT")
            end
            return improvementString
        end

        return nil
    end,

    barbarianClan = function(data)
        if not data.IsVisible or not IS_BARBARIAN_CLANS_TOOLTIP or data.ImprovementType ~= "IMPROVEMENT_BARBARIAN_CAMP" then
            return nil
        end

        local barbManager = Game.GetBarbarianManager()
        if barbManager == nil then
            return nil
        end

        local tribeIndex = barbManager:GetTribeIndexAtLocation(data.X, data.Y)
        if tribeIndex < 0 then
            return nil
        end

        local tribeNameType = barbManager:GetTribeNameType(tribeIndex)
        local tribeInfo = GameInfo.BarbarianTribeNames[tribeNameType]
        if tribeInfo == nil then
            return nil
        end

        return Locale.Lookup("LOC_TOOLTIP_BARBARIAN_CLAN_NAME", tribeInfo.TribeDisplayName)
    end,

    plotResourceExtraction = function(data, plot)
        if not data.IsVisible or not IS_XP2_TOOLTIP then return nil end
        if data.ImprovementType == nil or data.ResourceType == nil then return nil end
        if data.WonderType ~= nil or (data.IsCity and data.DistrictType ~= nil) or (data.DistrictID ~= -1 and data.DistrictType ~= nil) then
            return nil
        end
        return GetResourceAccumulationString(data, plot, true)
    end,

    impassable = function(data)
        if not data.IsVisible or not data.Impassable then return nil end

        if IS_XP2_TOOLTIP then
            return Locale.Lookup("LOC_TOOLTIP_PLOT_IMPASSABLE_TEXT")
        end

        if data.WonderType ~= nil or (data.IsCity and data.DistrictType ~= nil) then
            return nil
        end

        if data.DistrictID ~= -1 and data.DistrictType ~= nil then
            return nil
        end

        return Locale.Lookup("LOC_TOOLTIP_PLOT_IMPASSABLE_TEXT")
    end,

    naturalWonder = function(data)
        if not data.IsVisible or data.FeatureType == nil then return nil end
        local featureInfo = GetPlotFeatureInfo(data)
        if featureInfo ~= nil and featureInfo.NaturalWonder then
            return Locale.Lookup(featureInfo.Description)
        end
        return nil
    end,

    buildingsHeader = function(data)
        if not data.IsVisible then return nil end
        if not (data.IsCity or data.WonderType ~= nil or data.DistrictID ~= -1) then return nil end
        if data.BuildingNames == nil or #data.BuildingNames == 0 or data.WonderType ~= nil then
            return nil
        end
        return Locale.Lookup("LOC_TOOLTIP_PLOT_BUILDINGS_TEXT")
    end,

    greatWorksHeader = function(data)
        if not data.IsVisible then return nil end
        CacheGreatWorks(data)
        if data._CAIGreatWorkCount > 0 then
            return Locale.Lookup("LOC_GREAT_WORKS") .. ":"
        end
        return nil
    end,

    workers = function(data)
        if not data.IsVisible then return nil end
        if data.Owner == Game.GetLocalPlayer() and data.Workers > 0 then
            return Locale.Lookup("LOC_TOOLTIP_PLOT_WORKED_TEXT", data.Workers)
        end
        return nil
    end,

    fallout = function(data)
        if not data.IsVisible or data.Fallout <= 0 then return nil end
        return Locale.Lookup("LOC_TOOLTIP_PLOT_CONTAMINATED_TEXT", data.Fallout)
    end,

    units = function(data)
        local units = data.Units
        if not units or #units == 0 or info.RequestUnitFlagInfo == nil then return nil end

        local results = {}
        local seen = {}
        for _, unit in ipairs(units) do
            local unitInfo = info:RequestUnitFlagInfo(unit:GetOwner(), unit:GetID())
            if unitInfo ~= nil and not seen[unitInfo] then
                seen[unitInfo] = true
                table.insert(results, unitInfo)
            end
        end

        return #results > 0 and table.concat(results, ", ") or nil
    end,

    mapTac = function(data, plot)
        if not data.IsVisible or plot == nil then return nil end

        local mapTacs = GetVisibleMapTacsAtPlot(plot)
        if #mapTacs == 0 then
            return nil
        end

        local labels = {}
        for _, entry in ipairs(mapTacs) do
            local label = entry.LabelWithOwner or entry.Label
            if label ~= nil and label ~= "" then
                table.insert(labels, label)
            end
        end

        if #labels == 0 then
            return nil
        end

        return Locale.Lookup("LOC_CAI_PLOT_MAP_TACS", table.concat(labels, ", "))
    end,

    interfaceInfo = function(data, plot)
        if plot == nil then return nil end
        return GetActiveInterfacePlotInfo(plot)
    end,

    lensInfo = function(data, plot)
        if plot == nil then return nil end
        return GetActiveLensPlotInfo(plot)
    end,

    recommendation = function(data, plot)
        if plot == nil or info.GetRecommendationForPlot == nil then return nil end
        return info.GetRecommendationForPlot(plot:GetIndex())
    end,
}

local DynamicPlotInfoHelpers = {
    cityYield = function(data, _, yieldType)
        if not data.IsVisible or not data.IsCity or data.DistrictType == nil then return nil end
        return GetYieldLine(yieldType, data.Yields[yieldType])
    end,

    districtSpecialistYield = function(data, _, yieldType)
        if not data.IsVisible or data.DistrictID == -1 or data.DistrictType == nil then return nil end
        if GameInfo.Districts[data.DistrictType] == nil or GameInfo.Districts[data.DistrictType].InternalOnly then
            return nil
        end
        if data.Owner ~= Game.GetLocalPlayer() then
            return nil
        end
        return GetYieldLine(yieldType, data.Yields[yieldType])
    end,

    districtYield = function(data, _, yieldType)
        if not data.IsVisible or data.DistrictID == -1 or data.DistrictType == nil then return nil end
        if GameInfo.Districts[data.DistrictType] == nil or GameInfo.Districts[data.DistrictType].InternalOnly then
            return nil
        end
        return GetYieldLine(yieldType, data.DistrictYields[yieldType])
    end,

    plotYield = function(data, _, yieldType)
        if not data.IsVisible then return nil end
        if data.WonderType ~= nil or (data.IsCity and data.DistrictType ~= nil) then
            return nil
        end
        if data.DistrictID ~= -1 and data.DistrictType ~= nil then
            return nil
        end
        if not IS_XP2_TOOLTIP and data.Impassable then
            return nil
        end
        return GetYieldLine(yieldType, data.Yields[yieldType])
    end,

    building = function(data, _, indexArg)
        if not data.IsVisible or data.BuildingNames == nil then return nil end

        local index = tonumber(indexArg)
        if index == nil or data.BuildingNames[index] == nil then
            return nil
        end

        if data.WonderType == nil then
            if data.BuildingsPillaged[index] then
                return "- " ..
                    Locale.Lookup(data.BuildingNames[index]) .. " " .. Locale.Lookup("LOC_TOOLTIP_PLOT_PILLAGED_TEXT")
            end
            return "- " .. Locale.Lookup(data.BuildingNames[index])
        end

        return nil
    end,

    greatWork = function(data, _, indexArg)
        CacheGreatWorks(data)

        local index = tonumber(indexArg)
        if index == nil or data._CAIGreatWorks[index] == nil then
            return nil
        end

        return data._CAIGreatWorks[index]
    end,
}

local function ResolvePlotInfoHelper(key)
    local helper = info.PlotInfoHelpers[key]
    if helper ~= nil then
        return helper, nil
    end

    local prefix, arg = string.match(key, "^([%a%d_]+)%:(.+)$")
    if prefix ~= nil then
        local dynamicHelper = DynamicPlotInfoHelpers[prefix]
        if dynamicHelper ~= nil then
            return dynamicHelper, arg
        end
    end

    return nil, nil
end

local function RequestPlotInfoFromData(plot, data, requestedKeys)
    local keys = requestedKeys or BuildDefaultRequestedKeys(data)
    local results = {}

    for _, key in ipairs(keys) do
        local helper, arg = ResolvePlotInfoHelper(key)
        if helper ~= nil then
            AddIfPresent(results, helper(data, plot, arg))
        end
    end

    return results
end

local function BuildYieldInfoRequestKeys(data)
    local keys = {}

    if data.IsCity == true and data.DistrictType ~= nil then
        for _, yieldType in ipairs(GetOrderedYieldTypes(data.Yields)) do
            table.insert(keys, "cityYield:" .. yieldType)
        end
        return keys
    end

    if data.DistrictID ~= -1 and data.DistrictType ~= nil then
        local districtInfo = GameInfo.Districts[data.DistrictType]
        if districtInfo ~= nil and not districtInfo.InternalOnly then
            if data.Owner == Game.GetLocalPlayer() and HasEntries(data.Yields) then
                table.insert(keys, "districtSpecialistsHeader")
                for _, yieldType in ipairs(GetOrderedYieldTypes(data.Yields)) do
                    table.insert(keys, "districtSpecialistYield:" .. yieldType)
                end
            end

            for _, yieldType in ipairs(GetOrderedYieldTypes(data.DistrictYields)) do
                table.insert(keys, "districtYield:" .. yieldType)
            end
        end

        return keys
    end

    for _, yieldType in ipairs(GetOrderedYieldTypes(data.Yields)) do
        table.insert(keys, "plotYield:" .. yieldType)
    end

    return keys
end

local function BuildDistrictAndBuildingRequestKeys(data)
    local keys = {
        "wonderTitle",
        "cityDistrictTitle",
        "districtTitle",
        "buildingsHeader",
    }

    if data.BuildingNames ~= nil then
        for i = 1, #data.BuildingNames do
            table.insert(keys, "building:" .. tostring(i))
        end
    end

    CacheGreatWorks(data)
    if data._CAIGreatWorkCount > 0 then
        table.insert(keys, "greatWorksHeader")
        for i = 1, data._CAIGreatWorkCount do
            table.insert(keys, "greatWork:" .. tostring(i))
        end
    end

    return keys
end

local function BuildCursorMoveRequestKeys(data)
    local keys = {}
    for _, key in ipairs(CURSOR_MOVE_INFO_PRIORITY) do
        table.insert(keys, key)
    end

    table.insert(keys, "cityResourceExtraction")
    table.insert(keys, "districtResourceExtraction")
    table.insert(keys, "plotResourceExtraction")

    table.insert(keys, "buildingsHeader")
    if data.BuildingNames ~= nil then
        for i = 1, #data.BuildingNames do
            table.insert(keys, "building:" .. tostring(i))
        end
    end

    CacheGreatWorks(data)
    if data._CAIGreatWorkCount > 0 then
        table.insert(keys, "greatWorksHeader")
        for i = 1, data._CAIGreatWorkCount do
            table.insert(keys, "greatWork:" .. tostring(i))
        end
    end

    return keys
end

local function InitializePlotInfoActionRequestBuilders()
    PlotInfoActionRequestBuilders = {
        [Input.GetActionId("PlotReadUnits")] = function(plot, data)
            return {
                keys = { "units" },
                emptyLoc = "LOC_CAI_PLOT_NO_UNITS",
            }
        end,
        [Input.GetActionId("PlotReadYieldRiverOwner")] = function(plot, data)
            local keys = BuildYieldInfoRequestKeys(data)
            table.insert(keys, "workers")
            table.insert(keys, "freshWater")
            table.insert(keys, "owner")
            return {
                keys = keys,
                emptyLoc = "LOC_CAI_PLOT_NO_YIELD_RIVER_OWNER_INFO",
            }
        end,
        [Input.GetActionId("PlotReadStats")] = function(plot, data)
            return {
                keys = { "fallout", "movement", "defense", "appeal" },
                emptyLoc = "LOC_CAI_PLOT_NO_PHYSICAL_INFO",
            }
        end,
        [Input.GetActionId("PlotReadRelativeCoords")] = function(plot, data)
            return {
                keys = { "relativeCoords" },
                emptyLoc = "LOC_CAI_PLOT_NO_COORDINATES",
            }
        end,
        [Input.GetActionId("PlotReadDistrictBuildings")] = function(plot, data)
            return {
                keys = BuildDistrictAndBuildingRequestKeys(data),
                emptyLoc = "LOC_CAI_PLOT_NO_DISTRICTS_OR_BUILDINGS",
            }
        end,
        [Input.GetActionId("PlotReadGeography")] = function(plot, data)
            return {
                keys = {
                    "route",
                    "coastalLowland",
                    "volcano",
                    "storm",
                    "drought",
                    "continent",
                    "territory",
                    "cliff",
                    "riverNamed",
                    "nationalPark",
                },
                emptyLoc = "LOC_CAI_PLOT_NO_GEOGRAPHY_INFO",
            }
        end,
    }
end

function info.GetCursorPlotInfoBucket()
    return CURSOR_MOVE_INFO_PRIORITY
end

function info:RequestCursorMovePlotInfo(plot, explicitPlotId)
    local targetPlot = plot
    if explicitPlotId ~= nil and Map.IsPlot(explicitPlotId) then
        targetPlot = Map.GetPlotByIndex(explicitPlotId)
    end
    if not targetPlot then return {} end

    local data = BuildPlotInfoData(targetPlot)
    if data == nil then return {} end

    local keys = BuildCursorMoveRequestKeys(data)
    return RequestPlotInfoFromData(targetPlot, data, keys)
end

---@param plot Plot|nil
---@param requestedKeys string[]|nil
---@param explicitPlotId integer|nil
---@return string[]
function info:RequestPlotInfo(plot, requestedKeys, explicitPlotId)
    local targetPlot = plot
    if explicitPlotId ~= nil and Map.IsPlot(explicitPlotId) then
        targetPlot = Map.GetPlotByIndex(explicitPlotId)
    end

    if not targetPlot then return { "No plot" } end

    local data = BuildPlotInfoData(targetPlot)
    if data == nil then
        return {}
    end

    if requestedKeys == nil then
        CacheGreatWorks(data)
    end

    return RequestPlotInfoFromData(targetPlot, data, requestedKeys)
end

function OnCAICursorMove(state)
    local plotId = state.toPlotId
    currentPlot = plotId ~= nil and plotId or -1

    if state.reason == "select" then
        return
    end

    if plotId == nil or plotId < 0 or not Map.IsPlot(plotId) then
        print("CAI PlotToolTip received invalid cursor plot id: " .. tostring(plotId))
        return
    end

    local current = Map.GetPlotByIndex(plotId)
    if current == nil then
        print("CAI PlotToolTip could not resolve cursor plot id: " .. tostring(plotId))
        return
    end
    local data = BuildPlotInfoData(current)
    if data == nil then
        return
    end
    local keys = BuildCursorMoveRequestKeys(data)
    local results = RequestPlotInfoFromData(current, data, keys)

    local coordsAnnounceMode = CAISettings.GetString("CursorCoordinates")
    if coordsAnnounceMode ~= "disabled" then
        local coords = RequestPlotInfoFromData(current, data, { "relativeCoords" })[1]
        if coordsAnnounceMode == "prepend" then table.insert(results, 1, coords) end
        if coordsAnnounceMode == "append" then table.insert(results, coords) end
    end

    if #results > 0 then
        Speak(table.concat(results, ", "))
    end
end

function OnPlotInfoInputActionTriggered(actionId)
    local buildRequestKeys = PlotInfoActionRequestBuilders[actionId]
    if buildRequestKeys == nil then
        return
    end

    local plot = GetCurrentCursorPlot()
    if plot == nil then
        return
    end

    local data = BuildPlotInfoData(plot)
    if data == nil then
        return
    end

    local request = buildRequestKeys(plot, data)
    if request == nil then
        return
    end

    local requestKeys = request.keys
    if requestKeys == nil then
        return
    end

    local results = RequestPlotInfoFromData(plot, data, requestKeys)
    if #results == 0 then
        if request.emptyLoc ~= nil then
            Speak(Locale.Lookup(request.emptyLoc))
        end
        return
    end

    Speak(table.concat(results, ", "))
end

InitializePlotInfoActionRequestBuilders()
Events.InputActionTriggered.Add(OnPlotInfoInputActionTriggered)
LuaEvents.CAICursorMoved.Add(OnCAICursorMove)
