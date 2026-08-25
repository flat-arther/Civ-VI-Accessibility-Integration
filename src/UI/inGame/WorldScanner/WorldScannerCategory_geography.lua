include("Civ6Common")

local Utils = CAIWorldScannerUtils
local ZoneUtils = CAIWorldScannerZoneUtils
local HexCoordUtils = CAIHexCoordUtils
local WATER_CLASS = GameInfo.TerrainClasses["TERRAIN_CLASS_WATER"]

local SUBCATEGORY_LANDMASSES = "landmasses"
local SUBCATEGORY_OCEANS = "oceans"
local SUBCATEGORY_DISASTERS = "disasters"
local GROUP_LANDMASSES = "landmasses"
local GROUP_OCEANS = "oceans"
local GROUP_DISASTERS = "disasters"

local m_landPlotIndices = {}
local m_oceanPlotIndices = {}
-- keyed by disaster instance (storm/drought id or erupting volcano plot); each
-- holds its kind, localized name, drought turns, and affected visible plots.
local m_disasterGroups = {}
-- Natural disasters are a Gathering Storm feature; GameClimate and the volcano
-- eruption APIs do not exist without XP2, so the whole pass is gated on it.
local m_disastersEnabled = false

local subCategoryLabels = {
    [SUBCATEGORY_LANDMASSES] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_LANDMASSES",
    [SUBCATEGORY_OCEANS] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_OCEANS",
    [SUBCATEGORY_DISASTERS] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_DISASTERS",
}

CAIWorldScannerCategory_Geography = {
    Id = "geography",
    LabelKey = "LOC_CAI_WORLD_SCANNER_CATEGORY_GEOGRAPHY",
    SubCategoryOrder = { SUBCATEGORY_LANDMASSES, SUBCATEGORY_OCEANS, SUBCATEGORY_DISASTERS },
    SubCategoryLabels = subCategoryLabels,
    GroupLabelResolver = function(_, firstItem)
        return firstItem ~= nil and firstItem.GroupLabelKey or "LOC_CAI_WORLD_SCANNER_UNKNOWN"
    end,
}

local function ResolveAnchor(context)
    local player = Utils.GetLocalPlayer(context)
    if player ~= nil then
        local cities = player:GetCities()
        if cities ~= nil then
            local firstCity = nil
            for _, city in cities:Members() do
                firstCity = firstCity or city
                if city:IsCapital() then
                    local plot = Map.GetPlot(city:GetX(), city:GetY())
                    return plot and plot:GetIndex() or nil, city:GetX(), city:GetY()
                end
            end
            if firstCity ~= nil then
                local plot = Map.GetPlot(firstCity:GetX(), firstCity:GetY())
                return plot and plot:GetIndex() or nil, firstCity:GetX(), firstCity:GetY()
            end
        end

        local units = player:GetUnits()
        if units ~= nil then
            for _, unit in units:Members() do
                local plot = Map.GetPlot(unit:GetX(), unit:GetY())
                if plot ~= nil then
                    return plot:GetIndex(), plot:GetX(), plot:GetY()
                end
            end
        end
    end

    local x = context and context.SortOriginX or nil
    local y = context and context.SortOriginY or nil
    local plot = x ~= nil and y ~= nil and Map.GetPlot(x, y) or nil
    return plot and plot:GetIndex() or nil, x, y
end

local function GetContinentComposition(plotIndices)
    local names = {}
    local seen = {}
    for _, plotIndex in ipairs(plotIndices) do
        local plot = Map.GetPlotByIndex(plotIndex)
        local continentId = plot ~= nil and plot:GetContinentType() or -1
        local continent = continentId ~= nil and continentId >= 0 and GameInfo.Continents[continentId] or nil
        if continent ~= nil then
            local name = Utils.ResolveText(continent.Description)
            if name ~= "" and not seen[name] then
                seen[name] = true
                names[#names + 1] = name
            end
        end
    end
    table.sort(names, function(a, b)
        return Locale.Compare(a, b) < 0
    end)
    return table.concat(names, Locale.Lookup("LOC_CAI_WORLD_SCANNER_LANDMASS_CONTINENT_SEPARATOR"))
end

local function MakeBaseLandmassLabel(plotIndices, anchorPlotIndex)
    local isHome = anchorPlotIndex ~= nil
    if isHome then
        isHome = false
        for _, plotIndex in ipairs(plotIndices) do
            if plotIndex == anchorPlotIndex then
                isHome = true
                break
            end
        end
    end

    local continents = GetContinentComposition(plotIndices)
    if continents == "" then
        return Locale.Lookup(isHome
            and "LOC_CAI_WORLD_SCANNER_HOME_LANDMASS"
            or "LOC_CAI_WORLD_SCANNER_LANDMASS")
    end
    return Locale.Lookup(isHome
        and "LOC_CAI_WORLD_SCANNER_HOME_LANDMASS_CONTINENTS"
        or "LOC_CAI_WORLD_SCANNER_LANDMASS_CONTINENTS", continents)
end

local function GetGatheringStormWaterLabel(plotIndices)
    if not IsExpansion2Active()
        or Territories == nil
        or Territories.GetTerritoryAt == nil
        or WATER_CLASS == nil then
        return nil
    end

    local oceanNames = {}
    local seaNames = {}
    local seenTerritories = {}
    local seenOceanNames = {}
    local seenSeaNames = {}
    for _, plotIndex in ipairs(plotIndices) do
        local territory = Territories.GetTerritoryAt(plotIndex)
        if territory ~= nil
            and territory:GetTerrainClass() == WATER_CLASS.Index
            and not territory:IsLake()
            and not seenTerritories[territory:GetID()] then
            seenTerritories[territory:GetID()] = true
            local name = Utils.ResolveText(territory:GetName())
            if territory:IsSea() then
                if name ~= "" and not seenSeaNames[name] then
                    seenSeaNames[name] = true
                    seaNames[#seaNames + 1] = name
                end
            elseif name ~= "" and not seenOceanNames[name] then
                seenOceanNames[name] = true
                oceanNames[#oceanNames + 1] = name
            end
        end
    end

    local names = #oceanNames > 0 and oceanNames or seaNames
    table.sort(names, function(a, b)
        return Locale.Compare(a, b) < 0
    end)
    if #names == 0 then
        return nil
    end
    return table.concat(names, Locale.Lookup("LOC_CAI_WORLD_SCANNER_WATER_NAME_SEPARATOR"))
end

local function DisambiguateLabels(entries, context, anchorX, anchorY)
    local counts = {}
    for _, entry in ipairs(entries) do
        entry.LabelKey = ZoneUtils.MakeTileCountLabel(
            entry.LabelKey,
            entry.ZonePlotIndices,
            context
        )
        if ZoneUtils.IsAreaFullyRevealed(entry.ZonePlotIndices) then
            entry.LabelKey = ZoneUtils.WithFullyRevealedSuffix(entry.LabelKey)
        end
        entry.ZoneTileCountEmbedded = true
        counts[entry.LabelKey] = (counts[entry.LabelKey] or 0) + 1
    end

    for _, entry in ipairs(entries) do
        if counts[entry.LabelKey] > 1 and anchorX ~= nil and anchorY ~= nil then
            local nearestIndex = ZoneUtils.FindNearestPlotIndex(entry.ZonePlotIndices, anchorX, anchorY)
            local plot = nearestIndex ~= nil and Map.GetPlotByIndex(nearestIndex) or nil
            if plot ~= nil then
                local direction = HexCoordUtils.directionString(anchorX, anchorY, plot:GetX(), plot:GetY())
                entry.LabelKey = Locale.Lookup(
                    "LOC_CAI_WORLD_SCANNER_GEOGRAPHY_DIRECTION_FROM_HOME",
                    entry.LabelKey,
                    direction
                )
            end
        end
    end

    counts = {}
    for _, entry in ipairs(entries) do
        counts[entry.LabelKey] = (counts[entry.LabelKey] or 0) + 1
    end
    local ordinals = {}
    for _, entry in ipairs(entries) do
        if counts[entry.LabelKey] > 1 then
            ordinals[entry.LabelKey] = (ordinals[entry.LabelKey] or 0) + 1
            entry.LabelKey = Locale.Lookup(
                "LOC_CAI_WORLD_SCANNER_GEOGRAPHY_NUMBERED_FALLBACK",
                entry.LabelKey,
                ordinals[entry.LabelKey]
            )
        end
    end
end

-- Record any active natural disaster on a visible plot, grouped by instance so
-- one storm/drought becomes one zone. Storms and droughts carry a RandomEvents
-- type whose Name is the localized disaster name; erupting volcanoes are keyed
-- per plot. Only what the plot tooltip already exposes is read.
local function CollectDisaster(plotIndex, plot)
    local x, y = plot:GetX(), plot:GetY()

    local stormType = GameClimate.GetActiveStormTypeAtPlot(plot)
    if stormType ~= nil and stormType >= 0 then
        local key = "storm:" .. tostring(GameClimate.GetActiveStormIDAtPlot(x, y))
        local group = m_disasterGroups[key]
        if group == nil then
            local eventInfo = GameInfo.RandomEvents[stormType]
            group = {
                kind = "storm",
                name = eventInfo ~= nil and eventInfo.Name or "LOC_CAI_WORLD_SCANNER_UNKNOWN",
                plots = {},
            }
            m_disasterGroups[key] = group
        end
        group.plots[#group.plots + 1] = plotIndex
    end

    local droughtType = GameClimate.GetActiveDroughtTypeAtPlot(plot)
    if droughtType ~= nil and droughtType >= 0 then
        local key = "drought:" .. tostring(GameClimate.GetActiveDroughtIDAtPlot(x, y))
        local group = m_disasterGroups[key]
        if group == nil then
            local eventInfo = GameInfo.RandomEvents[droughtType]
            group = {
                kind = "drought",
                name = eventInfo ~= nil and eventInfo.Name or "LOC_CAI_WORLD_SCANNER_UNKNOWN",
                turns = 0,
                plots = {},
            }
            m_disasterGroups[key] = group
        end
        local turns = GameClimate.GetDroughtTurnsAtPlot(plot) or 0
        if turns > group.turns then
            group.turns = turns
        end
        group.plots[#group.plots + 1] = plotIndex
    end

    if MapFeatureManager.IsVolcanoErupting(plot) then
        m_disasterGroups["eruption:" .. tostring(plotIndex)] = {
            kind = "eruption",
            name = MapFeatureManager.GetVolcanoName(plot),
            plots = { plotIndex },
        }
    end
end

local function DisasterItemLabel(group)
    if group.kind == "drought" then
        return Locale.Lookup(
            "LOC_CAI_WORLD_SCANNER_DISASTER_DROUGHT",
            Utils.ResolveText(group.name),
            group.turns
        )
    end
    if group.kind == "eruption" then
        return Locale.Lookup(
            "LOC_CAI_WORLD_SCANNER_DISASTER_ERUPTION",
            Utils.ResolveText(group.name)
        )
    end
    return Utils.ResolveText(group.name)
end

-- Live prune: a disaster member is valid only while the plot stays revealed and
-- still carries that disaster. Storms and droughts move and expire; eruptions
-- end. Revealed (not visible) matches the plot tooltip's own gating.
local function MakeDisasterValidator(kind)
    return function(_, plot, validateContext)
        if not Utils.IsPlotRevealed(validateContext, plot) then
            return false
        end
        if kind == "storm" then
            local stormType = GameClimate.GetActiveStormTypeAtPlot(plot)
            return stormType ~= nil and stormType >= 0
        end
        if kind == "drought" then
            local droughtType = GameClimate.GetActiveDroughtTypeAtPlot(plot)
            return droughtType ~= nil and droughtType >= 0
        end
        return MapFeatureManager.IsVolcanoErupting(plot)
    end
end

function CAIWorldScannerCategory_Geography.BeginExtract()
    m_landPlotIndices = {}
    m_oceanPlotIndices = {}
    m_disasterGroups = {}
    m_disastersEnabled = IsExpansion2Active()
        and GameClimate ~= nil
        and GameClimate.GetActiveStormTypeAtPlot ~= nil
        and MapFeatureManager ~= nil
        and MapFeatureManager.IsVolcanoErupting ~= nil
end

function CAIWorldScannerCategory_Geography.PlotExtract(plotIndex, plot, _, _, isRevealed)
    if not isRevealed then
        return
    end
    if plot:IsWater() then
        if not plot:IsLake() then
            m_oceanPlotIndices[#m_oceanPlotIndices + 1] = plotIndex
        end
    else
        m_landPlotIndices[#m_landPlotIndices + 1] = plotIndex
    end

    -- Match the plot tooltip, which shows a plot's active disaster on any
    -- revealed tile (PlotToolTip gates on IsRevealed). We are already past the
    -- isRevealed early-return above, so revealed gating is implicit here.
    if m_disastersEnabled then
        CollectDisaster(plotIndex, plot)
    end
end

function CAIWorldScannerCategory_Geography.EndExtract(context, collect)
    local anchorPlotIndex, anchorX, anchorY = ResolveAnchor(context)
    local entries = {}

    for _, zone in ipairs(ZoneUtils.PartitionPlotIndices(m_landPlotIndices)) do
        entries[#entries + 1] = {
            Id = "geography:landmass:" .. tostring(zone.MinPlotIndex),
            PlotIndex = zone.MinPlotIndex,
            ZonePlotIndices = zone.PlotIndices,
            ZoneValidatePlot = function(_, plot, validateContext)
                return Utils.IsPlotRevealed(validateContext, plot) and not plot:IsWater()
            end,
            LabelKey = MakeBaseLandmassLabel(zone.PlotIndices, anchorPlotIndex),
            SubCategoryId = SUBCATEGORY_LANDMASSES,
            GroupId = GROUP_LANDMASSES,
            GroupLabelKey = subCategoryLabels[SUBCATEGORY_LANDMASSES],
        }
    end
    DisambiguateLabels(entries, context, anchorX, anchorY)
    for _, entry in ipairs(entries) do
        collect(entry)
    end

    entries = {}
    for _, zone in ipairs(ZoneUtils.PartitionPlotIndices(m_oceanPlotIndices)) do
        entries[#entries + 1] = {
            Id = "geography:ocean:" .. tostring(zone.MinPlotIndex),
            PlotIndex = zone.MinPlotIndex,
            ZonePlotIndices = zone.PlotIndices,
            ZoneValidatePlot = function(_, plot, validateContext)
                return Utils.IsPlotRevealed(validateContext, plot) and plot:IsWater() and not plot:IsLake()
            end,
            LabelKey = GetGatheringStormWaterLabel(zone.PlotIndices)
                or "LOC_CAI_WORLD_SCANNER_OCEAN_ZONE",
            SubCategoryId = SUBCATEGORY_OCEANS,
            GroupId = GROUP_OCEANS,
            GroupLabelKey = subCategoryLabels[SUBCATEGORY_OCEANS],
        }
    end
    DisambiguateLabels(entries, context, anchorX, anchorY)
    for _, entry in ipairs(entries) do
        collect(entry)
    end

    for key, group in pairs(m_disasterGroups) do
        for _, zone in ipairs(ZoneUtils.PartitionPlotIndices(group.plots)) do
            local kind = group.kind
            collect({
                Id = "geography:disaster:" .. key .. ":" .. tostring(zone.MinPlotIndex),
                PlotIndex = zone.MinPlotIndex,
                ZonePlotIndices = zone.PlotIndices,
                ZoneTileCountEmbedded = true,
                ZoneValidatePlot = MakeDisasterValidator(kind),
                LabelKey = DisasterItemLabel(group),
                SubCategoryId = SUBCATEGORY_DISASTERS,
                GroupId = GROUP_DISASTERS,
                GroupLabelKey = subCategoryLabels[SUBCATEGORY_DISASTERS],
            })
        end
    end
end

CAIWorldScanner:RegisterCategoryDefinition(CAIWorldScannerCategory_Geography)
