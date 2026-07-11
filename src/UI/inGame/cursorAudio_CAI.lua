-- ===========================================================================
-- CAICursorAudio.lua
-- Audio cues for the CAI navigation cursor.
--
-- Included from WorldInput, then calls CAICursorAudio.OnUpdate()
-- from the update function.
-- ===========================================================================

CAICursorAudio = CAICursorAudio or {}

local STINGER_DELAY_SECONDS = 0.1
local CURSOR_AUDIO_TAGS = {
    "CURSOR_CROSSINGS",
    "CURSOR_FOG",
    "CURSOR_TERRAIN",
    "CURSOR_STINGERS",
}

local function GetAudioManager()
    local uiMgr = ExposedMembers.CAI_UIManager
    if uiMgr ~= nil and uiMgr.GetAudioManager ~= nil then
        return uiMgr:GetAudioManager()
    end

    return ExposedMembers.CAI_AudioManager
end

-- ===========================================================================
-- Sound mappings
-- ===========================================================================

local TERRAIN_SOUNDS = {
    TERRAIN_GRASS = "CURSOR_GRASS",
    TERRAIN_GRASS_HILLS = "CURSOR_GRASS",

    TERRAIN_PLAINS = "CURSOR_PLAINS",
    TERRAIN_PLAINS_HILLS = "CURSOR_PLAINS",

    TERRAIN_DESERT = "CURSOR_DESERT",
    TERRAIN_DESERT_HILLS = "CURSOR_DESERT",
    TERRAIN_DESERT_MOUNTAIN = "CURSOR_DESERT",

    TERRAIN_TUNDRA = "CURSOR_TUNDRA",
    TERRAIN_TUNDRA_HILLS = "CURSOR_TUNDRA",
    TERRAIN_TUNDRA_MOUNTAIN = "CURSOR_TUNDRA",

    TERRAIN_SNOW = "CURSOR_SNOW",
    TERRAIN_SNOW_HILLS = "CURSOR_SNOW",
    TERRAIN_SNOW_MOUNTAIN = "CURSOR_SNOW",

    TERRAIN_COAST = "CURSOR_COAST",
    TERRAIN_OCEAN = "CURSOR_OCEAN",
}

local FEATURE_BEDS = {
    FEATURE_JUNGLE = "CURSOR_JUNGLE",
    FEATURE_MARSH = "CURSOR_MARSH",

    FEATURE_FLOODPLAINS = "CURSOR_FLOODPLAINS",
    FEATURE_FLOODPLAINS_GRASSLAND = "CURSOR_FLOODPLAINS",
    FEATURE_FLOODPLAINS_PLAINS = "CURSOR_FLOODPLAINS",

    FEATURE_OASIS = "CURSOR_OASIS",
    FEATURE_ICE = "CURSOR_ICE",
    FEATURE_REEF = "CURSOR_REEF",
    FEATURE_GEOTHERMAL_FISSURE = "CURSOR_GEOTHERMAL_FISSURE",
    FEATURE_VOLCANIC_SOIL = "CURSOR_VOLCANIC_SOIL",
}

local FEATURE_STINGERS = {
    FEATURE_FOREST = "CURSOR_FOREST",
    FEATURE_VOLCANO = "CURSOR_VOLCANO",
}

local function HasRiverCrossing(sourcePlot, targetPlot)
    if sourcePlot == nil or targetPlot == nil then
        return false
    end

    local ok, result = pcall(function()
        return sourcePlot:IsRiverCrossingToPlot(targetPlot)
    end)
    if not ok then
        LogWarn("CAICursorAudio.HasRiverCrossing: IsRiverCrossingToPlot failed")
        return false
    end

    return result == true
end

-- ===========================================================================
-- Playback
-- ===========================================================================

local function StopCursorTags()
    local audio = GetAudioManager()
    if audio == nil then
        LogWarn("CAICursorAudio.StopCursorTags: CAI_AudioManager is unavailable")
        return
    end

    for _, tag in ipairs(CURSOR_AUDIO_TAGS) do
        if audio.SoundsByTag[tag] ~= nil then
            audio:StopTag(tag)
        end
    end
end

local function QueueSound(soundId, delaySeconds)
    if soundId == nil or soundId == "" then return end

    local audio = GetAudioManager()
    if audio == nil then
        LogWarn("CAICursorAudio.QueueSound: CAI_AudioManager is unavailable for " .. tostring(soundId))
        return
    end

    audio:QueueSound(soundId, delaySeconds)
end

-- ===========================================================================
-- Plot helpers
-- ===========================================================================

local function GetFeatureRow(plot)
    if plot == nil then return nil end

    local featureType = plot:GetFeatureType()
    if featureType == nil or featureType < 0 then return nil end

    return GameInfo.Features[featureType]
end

local function GetTerrainRow(plot)
    if plot == nil then return nil end

    local terrainType = plot:GetTerrainType()
    if terrainType == nil or terrainType < 0 then return nil end

    return GameInfo.Terrains[terrainType]
end

local function IsPlotRevealed(plot)
    if plot == nil then return false end

    local playerID = Game.GetLocalPlayer()
    if playerID == nil or playerID < 0 then return false end

    local visibility = PlayersVisibility[playerID]
    if visibility == nil then return false end

    return visibility:IsRevealed(plot)
end

local function IsPlotVisible(plot)
    if plot == nil then return false end

    local playerID = Game.GetLocalPlayer()
    if playerID == nil or playerID < 0 then return false end

    local visibility = PlayersVisibility[playerID]
    if visibility == nil then return false end

    return visibility:IsVisible(plot:GetIndex())
end

local function GetRouteRow(plot)
    if plot == nil or not plot:IsRoute() or plot:IsRoutePillaged() then
        return nil
    end

    local routeType = plot:GetRouteType()
    if routeType == nil or routeType < 0 then
        return nil
    end

    return GameInfo.Routes[routeType]
end

local function RouteSupportsBridges(route)
    if route == nil then
        return false
    end

    local value = route.SupportsBridges
    return value == true or value == 1 or value == "true" or value == "1"
end

local function GetBedSound(plot)
    if plot == nil then return nil end

    if plot:IsMountain() then
        return "CURSOR_MOUNTAIN"
    end

    local feature = GetFeatureRow(plot)
    if feature ~= nil and not feature.NaturalWonder then
        local featureSound = FEATURE_BEDS[feature.FeatureType]
        if featureSound ~= nil then
            return featureSound
        end
    end

    local terrain = GetTerrainRow(plot)
    if terrain ~= nil then
        local terrainSound = TERRAIN_SOUNDS[terrain.TerrainType]
        if terrainSound ~= nil then
            return terrainSound
        end
    end

    if plot:IsWater() then
        return "CURSOR_COAST"
    end

    return "CURSOR_GRASS"
end

local function GetStingers(plot)
    local results = {}

    local feature = GetFeatureRow(plot)
    if feature ~= nil then
        local stinger = FEATURE_STINGERS[feature.FeatureType]
        if stinger ~= nil then
            table.insert(results, stinger)
        end
    end

    local route = GetRouteRow(plot)
    if route ~= nil then
        if route.RouteType == "ROUTE_RAILROAD" then
            table.insert(results, "CURSOR_METAL_WALK")
        else
            table.insert(results, "CURSOR_ROAD_WALK")
        end
    end

    return results
end

local function GetFogSound(plot)
    if plot == nil then return nil end
    if not IsPlotRevealed(plot) then return nil end
    if IsPlotVisible(plot) then return nil end
    return "CURSOR_WOOSH"
end

local function GetCrossingSound(plot, prevPlot, moveReason)
    if plot == nil or prevPlot == nil then
        return nil
    end

    if moveReason ~= "step" then
        return nil
    end

    if not HasRiverCrossing(prevPlot, plot) then
        return nil
    end

    local fromRoute = GetRouteRow(prevPlot)
    local toRoute = GetRouteRow(plot)
    if fromRoute ~= nil and toRoute ~= nil and RouteSupportsBridges(fromRoute) and RouteSupportsBridges(toRoute) then
        return "CURSOR_WOOD_WALK"
    end

    return "CURSOR_RIVER_CROSSING"
end

-- ===========================================================================
-- Public API
-- ===========================================================================

function CAICursorAudio.PlayPlot(plot, prevPlot, moveReason)
    if plot == nil then return end
    if not IsPlotRevealed(plot) then return end

    StopCursorTags()

    local fog = GetFogSound(plot)
    local crossing = GetCrossingSound(plot, prevPlot, moveReason)
    local bedDelay = 0
    if crossing ~= nil then
        QueueSound(crossing, 0)
        bedDelay = STINGER_DELAY_SECONDS
    end

    QueueSound(GetBedSound(plot), bedDelay)
    QueueSound(fog, bedDelay)

    for _, stinger in ipairs(GetStingers(plot)) do
        if not (crossing == "CURSOR_WOOD_WALK" and (stinger == "CURSOR_ROAD_WALK" or stinger == "CURSOR_METAL_WALK")) then
            QueueSound(stinger, bedDelay + STINGER_DELAY_SECONDS)
        end
    end
end

function CAICursorAudio.PlayPlotById(plotId, prevPlotId, moveReason)
    local audio = GetAudioManager()
    if audio ~= nil and not audio:IsTagEnabled("CURSOR") then
        return
    end
    if plotId == nil or plotId < 0 then return end

    local plot = Map.GetPlotByIndex(plotId)
    if plot == nil then return end

    local prevPlot = nil
    if prevPlotId ~= nil and prevPlotId >= 0 then
        prevPlot = Map.GetPlotByIndex(prevPlotId)
    end

    CAICursorAudio.PlayPlot(plot, prevPlot, moveReason)
end

local function OnCAICursorMoved(data)
    if data == nil then return end
    if data.fromPlotId == data.toPlotId then return end
    CAICursorAudio.PlayPlotById(data.toPlotId, data.fromPlotId, data.reason)
end

function CAICursorAudio.Initialize()
    LuaEvents.CAICursorMoved.Add(OnCAICursorMoved)
end

function CAICursorAudio.Shutdown()
    LuaEvents.CAICursorMoved.Remove(OnCAICursorMoved)
    StopCursorTags()
end
