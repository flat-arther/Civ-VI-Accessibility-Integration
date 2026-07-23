include("Civ6Common")

local Utils = CAIWorldScannerUtils
local ZoneUtils = CAIWorldScannerZoneUtils
local HexCoordUtils = CAIHexCoordUtils
local WATER_CLASS = GameInfo.TerrainClasses["TERRAIN_CLASS_WATER"]

local SUBCATEGORY_LANDMASSES = "landmasses"
local SUBCATEGORY_OCEANS = "oceans"
local GROUP_LANDMASSES = "landmasses"
local GROUP_OCEANS = "oceans"

local m_landPlotIndices = {}
local m_oceanPlotIndices = {}

local subCategoryLabels = {
    [SUBCATEGORY_LANDMASSES] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_LANDMASSES",
    [SUBCATEGORY_OCEANS] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_OCEANS",
}

CAIWorldScannerCategory_Geography = {
    Id = "geography",
    LabelKey = "LOC_CAI_WORLD_SCANNER_CATEGORY_GEOGRAPHY",
    SubCategoryOrder = { SUBCATEGORY_LANDMASSES, SUBCATEGORY_OCEANS },
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

local function DisambiguateLabels(entries, anchorX, anchorY)
    local counts = {}
    for _, entry in ipairs(entries) do
        entry.LabelKey = Utils.ResolveText(entry.LabelKey)
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

function CAIWorldScannerCategory_Geography.BeginExtract()
    m_landPlotIndices = {}
    m_oceanPlotIndices = {}
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
    DisambiguateLabels(entries, anchorX, anchorY)
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
    DisambiguateLabels(entries, anchorX, anchorY)
    for _, entry in ipairs(entries) do
        collect(entry)
    end
end

CAIWorldScanner:RegisterCategoryDefinition(CAIWorldScannerCategory_Geography)
