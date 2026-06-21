include("caiUtils")
include("hexCoordUtils_CAI")
include("inGameHelpers_CAI")

CAISurveyor = CAISurveyor or {}

local Surveyor = CAISurveyor
local HexCoordUtils = CAIHexCoordUtils

-- ===========================================================================
-- Radius state
-- ===========================================================================

local MIN_RADIUS = 1
local MAX_RADIUS = 5
local m_radius = MIN_RADIUS

local function SetRadius(radius)
    m_radius = math.max(MIN_RADIUS, math.min(MAX_RADIUS, radius))
    return m_radius
end

local function GetRadius()
    return m_radius
end

local function FormatRadius(radius)
    if radius <= MIN_RADIUS then
        return Locale.Lookup("LOC_CAI_SURVEYOR_RADIUS_MIN", radius)
    end
    if radius >= MAX_RADIUS then
        return Locale.Lookup("LOC_CAI_SURVEYOR_RADIUS_MAX", radius)
    end
    return Locale.Lookup("LOC_CAI_SURVEYOR_RADIUS", radius)
end

-- ===========================================================================
-- Shared formatting and sorting
-- ===========================================================================

local YIELD_ORDER = {
    "YIELD_FOOD",
    "YIELD_PRODUCTION",
    "YIELD_GOLD",
    "YIELD_SCIENCE",
    "YIELD_CULTURE",
    "YIELD_FAITH",
}

local function ResolveText(labelKey)
    if labelKey == nil then
        return ""
    end

    local value = tostring(labelKey)
    if string.sub(value, 1, 4) == "LOC_" then
        return Locale.Lookup(value)
    end
    return value
end

local function AppendUnexplored(body, unexplored)
    if unexplored <= 0 then
        return body
    end

    local suffix = Locale.Lookup("LOC_CAI_SURVEYOR_UNEXPLORED_SUFFIX", unexplored)
    if body == nil or body == "" then
        return suffix
    end
    return body .. ". " .. suffix
end

local function SortBucketEntries(buckets)
    local entries = {}
    for label, count in pairs(buckets) do
        entries[#entries + 1] = {
            Label = label,
            Count = count,
        }
    end

    table.sort(entries, function(a, b)
        if a.Count ~= b.Count then
            return a.Count > b.Count
        end
        return Locale.Compare(a.Label, b.Label) < 0
    end)

    return entries
end

local function FormatBucketEntries(entries)
    local parts = {}
    for _, entry in ipairs(entries) do
        parts[#parts + 1] = Locale.Lookup("LOC_CAI_SURVEYOR_COUNT", entry.Count, entry.Label)
    end
    return table.concat(parts, ", ")
end

local function CompareInstances(a, b)
    if a.Distance ~= b.Distance then
        return a.Distance < b.Distance
    end
    if a.DirectionRank ~= b.DirectionRank then
        return a.DirectionRank < b.DirectionRank
    end
    return Locale.Compare(a.Label, b.Label) < 0
end

local function FormatInstances(instances, centerX, centerY, labelDirectionSeparator, instanceSeparator)
    table.sort(instances, CompareInstances)

    local parts = {}
    for _, instance in ipairs(instances) do
        local directionText = HexCoordUtils.directionString(centerX, centerY, instance.X, instance.Y)
        if directionText == nil or directionText == "" then
            directionText = Locale.Lookup("LOC_CAI_HERE")
        end
        parts[#parts + 1] = instance.Label .. labelDirectionSeparator .. directionText
    end

    return table.concat(parts, instanceSeparator)
end

local function AddInstance(instances, centerX, centerY, plot, label)
    local x = plot:GetX()
    local y = plot:GetY()
    instances[#instances + 1] = {
        X = x,
        Y = y,
        Distance = HexCoordUtils.cubeDistance(centerX, centerY, x, y),
        DirectionRank = HexCoordUtils.directionRank(centerX, centerY, x, y),
        Label = label ~= nil and label ~= "" and label or Locale.Lookup("LOC_CAI_WORLD_SCANNER_UNKNOWN"),
    }
end

local function SpeakSurveyor(text)
    Speak(text, true)
end

-- ===========================================================================
-- Range helpers
-- ===========================================================================

local function GetCursorPlot()
    if CAICursor == nil then
        return nil
    end

    local plotId = CAICursor:GetPlotId()
    if plotId == nil or plotId < 0 then
        return nil
    end
    return Map.GetPlotByIndex(plotId)
end

local function GetSurveyRange()
    local plot = GetCursorPlot()
    if plot == nil then
        print("Surveyor: cursor plot unavailable")
        return nil, nil
    end

    local x = plot:GetX()
    local y = plot:GetY()
    return {
        X = x,
        Y = y,
        Range = HexCoordUtils.plotsInRange(x, y, GetRadius()),
    }, plot
end

local function IsVisiblePlot(plot)
    local observer = Game.GetLocalObserver()
    if observer == PlayerTypes.OBSERVER then
        return true
    end

    local visibility = PlayersVisibility[observer]
    return visibility ~= nil and visibility:IsVisible(plot:GetIndex())
end

local function IsKnownPlayer(playerID)
    if playerID == nil or playerID == -1 then
        return false
    end

    local localPlayerID = Game.GetLocalPlayer()
    if playerID == localPlayerID then
        return true
    end

    local localPlayer = Players[localPlayerID]
    local diplomacy = localPlayer and localPlayer:GetDiplomacy()
    return diplomacy ~= nil and diplomacy:HasMet(playerID)
end

local function IsOwnOrTeamUnit(unit)
    local localPlayerID = Game.GetLocalPlayer()
    local ownerID = unit:GetOwner()
    if ownerID == localPlayerID then
        return true
    end

    local localPlayer = Players[localPlayerID]
    local owner = Players[ownerID]
    return localPlayer ~= nil and owner ~= nil and localPlayer:GetTeam() == owner:GetTeam()
end

local function IsEnemyUnit(unit)
    local ownerID = unit:GetOwner()
    local owner = Players[ownerID]
    if owner == nil then
        return false
    end
    if owner:IsBarbarian() then
        return true
    end
    if not IsKnownPlayer(ownerID) then
        return false
    end

    local localPlayer = Players[Game.GetLocalPlayer()]
    local diplomacy = localPlayer and localPlayer:GetDiplomacy()
    return diplomacy ~= nil and diplomacy:IsAtWarWith(ownerID)
end

local function IsUnitVisible(unit)
    local ownerID = unit:GetOwner()
    if ownerID == Game.GetLocalPlayer() then
        return true
    end

    local observer = Game.GetLocalObserver()
    if observer == PlayerTypes.OBSERVER then
        return true
    end

    local visibility = PlayersVisibility[observer]
    return visibility ~= nil and visibility:IsUnitVisible(unit)
end

local function GetUnitsOnPlot(plot)
    return Units.GetUnitsInPlotLayerID(plot:GetX(), plot:GetY(), MapLayers.ANY) or {}
end

-- ===========================================================================
-- Scopes
-- ===========================================================================

function Surveyor.GrowRadius()
    return FormatRadius(SetRadius(GetRadius() + 1))
end

function Surveyor.ShrinkRadius()
    return FormatRadius(SetRadius(GetRadius() - 1))
end

function Surveyor.ReadYields()
    local survey = GetSurveyRange()
    if survey == nil then
        return Locale.Lookup("LOC_CAI_SURVEYOR_CURSOR_UNAVAILABLE")
    end

    local totals = {}
    for _, yieldType in ipairs(YIELD_ORDER) do
        totals[yieldType] = 0
    end

    for _, plot in ipairs(survey.Range.plots) do
        for _, yieldType in ipairs(YIELD_ORDER) do
            local yieldInfo = GameInfo.Yields[yieldType]
            totals[yieldType] = totals[yieldType] + plot:GetYield(yieldInfo.Index)
        end
    end

    local parts = {}
    for _, yieldType in ipairs(YIELD_ORDER) do
        local amount = totals[yieldType]
        if amount > 0 then
            local yieldInfo = GameInfo.Yields[yieldType]
            parts[#parts + 1] = Locale.Lookup(
                "LOC_CAI_SURVEYOR_YIELD_COUNT",
                amount,
                Locale.Lookup(yieldInfo.IconString),
                Locale.Lookup(yieldInfo.Name)
            )
        end
    end

    local body = #parts > 0 and table.concat(parts, ", ") or Locale.Lookup("LOC_CAI_SURVEYOR_EMPTY_YIELDS")
    return AppendUnexplored(body, survey.Range.unexplored)
end

function Surveyor.ReadResources()
    local survey = GetSurveyRange()
    if survey == nil then
        return Locale.Lookup("LOC_CAI_SURVEYOR_CURSOR_UNAVAILABLE")
    end

    local localPlayer = Players[Game.GetLocalPlayer()]
    local playerResources = localPlayer and localPlayer:GetResources()
    local buckets = {}

    for _, plot in ipairs(survey.Range.plots) do
        local resourceType = plot:GetResourceType()
        local resourceInfo = resourceType ~= nil and resourceType >= 0 and GameInfo.Resources[resourceType] or nil
        if resourceInfo ~= nil
            and playerResources ~= nil
            and playerResources:IsResourceVisible(resourceInfo.Hash) then
            local label = Locale.Lookup(resourceInfo.Name)
            local count = plot:GetResourceCount()
            if count == nil or count < 1 then
                count = 1
            end
            buckets[label] = (buckets[label] or 0) + count
        end
    end

    local entries = SortBucketEntries(buckets)
    local body = #entries > 0 and FormatBucketEntries(entries) or Locale.Lookup("LOC_CAI_SURVEYOR_EMPTY_RESOURCES")
    return AppendUnexplored(body, survey.Range.unexplored)
end

function Surveyor.ReadTerrain()
    local survey = GetSurveyRange()
    if survey == nil then
        return Locale.Lookup("LOC_CAI_SURVEYOR_CURSOR_UNAVAILABLE")
    end

    local buckets = {}
    local function AddBucket(labelKey)
        local label = ResolveText(labelKey)
        buckets[label] = (buckets[label] or 0) + 1
    end

    for _, plot in ipairs(survey.Range.plots) do
        local terrainInfo = GameInfo.Terrains[plot:GetTerrainType()]
        if terrainInfo ~= nil then
            if terrainInfo.TerrainType == "TERRAIN_COAST" then
                AddBucket(plot:IsLake() and "LOC_TOOLTIP_LAKE" or "LOC_TOOLTIP_COAST")
            else
                AddBucket(terrainInfo.Name)
            end
        end

        local featureInfo = GameInfo.Features[plot:GetFeatureType()]
        if featureInfo ~= nil then
            AddBucket(featureInfo.Name)
        end

        if plot:IsMountain() then
            AddBucket("LOC_CAI_SURVEYOR_MOUNTAINS")
        elseif plot:IsHills() then
            AddBucket("LOC_CAI_SURVEYOR_HILLS")
        end
    end

    local entries = SortBucketEntries(buckets)
    local body = #entries > 0 and FormatBucketEntries(entries) or Locale.Lookup("LOC_CAI_SURVEYOR_EMPTY_TERRAIN")
    return AppendUnexplored(body, survey.Range.unexplored)
end

function Surveyor.ReadOwnUnits()
    local survey = GetSurveyRange()
    if survey == nil then
        return Locale.Lookup("LOC_CAI_SURVEYOR_CURSOR_UNAVAILABLE")
    end

    local instances = {}
    for _, plot in ipairs(survey.Range.plots) do
        for _, unit in ipairs(GetUnitsOnPlot(plot)) do
            if IsOwnOrTeamUnit(unit) then
                local label = FormatOwnedUnitDisplayName(unit)
                if label ~= nil and label ~= "" then
                    AddInstance(instances, survey.X, survey.Y, plot, label)
                end
            end
        end
    end

    local body = #instances > 0
        and FormatInstances(instances, survey.X, survey.Y, ", ", ". ")
        or Locale.Lookup("LOC_CAI_SURVEYOR_EMPTY_OWN_UNITS")
    return AppendUnexplored(body, survey.Range.unexplored)
end

function Surveyor.ReadEnemyUnits()
    local survey = GetSurveyRange()
    if survey == nil then
        return Locale.Lookup("LOC_CAI_SURVEYOR_CURSOR_UNAVAILABLE")
    end

    local instances = {}
    for _, plot in ipairs(survey.Range.plots) do
        if IsVisiblePlot(plot) then
            for _, unit in ipairs(GetUnitsOnPlot(plot)) do
                if IsUnitVisible(unit) and IsEnemyUnit(unit) then
                    local label = FormatOwnedUnitDisplayName(unit)
                    if label ~= nil and label ~= "" then
                        AddInstance(instances, survey.X, survey.Y, plot, label)
                    end
                end
            end
        end
    end

    local body = #instances > 0
        and FormatInstances(instances, survey.X, survey.Y, ", ", ". ")
        or Locale.Lookup("LOC_CAI_SURVEYOR_EMPTY_ENEMY_UNITS")
    return AppendUnexplored(body, survey.Range.unexplored)
end

function Surveyor.ReadCities()
    local survey = GetSurveyRange()
    if survey == nil then
        return Locale.Lookup("LOC_CAI_SURVEYOR_CURSOR_UNAVAILABLE")
    end

    local campInfo = GameInfo.Improvements.IMPROVEMENT_BARBARIAN_CAMP
    local instances = {}

    for _, plot in ipairs(survey.Range.plots) do
        local city = Cities.GetCityInPlot(plot:GetX(), plot:GetY())
        if city ~= nil and city:GetX() == plot:GetX() and city:GetY() == plot:GetY() then
            local ownerID = city:GetOwner()
            if IsKnownPlayer(ownerID) then
                AddInstance(instances, survey.X, survey.Y, plot, FormatOwnedCityDisplayName(ownerID, city:GetName()))
            end
        elseif campInfo ~= nil and plot:GetImprovementType() == campInfo.Index then
            AddInstance(instances, survey.X, survey.Y, plot, Locale.Lookup(campInfo.Name))
        end
    end

    local body = #instances > 0
        and FormatInstances(instances, survey.X, survey.Y, " ", ", ")
        or Locale.Lookup("LOC_CAI_SURVEYOR_EMPTY_CITIES")
    return AppendUnexplored(body, survey.Range.unexplored)
end

-- ===========================================================================
-- Input dispatch
-- ===========================================================================

function Surveyor.SpeakResult(readFunc)
    local text = readFunc()
    if text ~= nil and text ~= "" then
        SpeakSurveyor(text)
    end
    return true
end
