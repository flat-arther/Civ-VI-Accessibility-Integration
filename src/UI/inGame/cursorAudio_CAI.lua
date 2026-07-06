-- ===========================================================================
-- CAICursorAudio.lua
-- Audio cues for the CAI navigation cursor.
--
-- Included from WorldInput, then calls CAICursorAudio.OnUpdate()
-- from the update function.
-- ===========================================================================

CAICursorAudio = CAICursorAudio or {}

local STINGER_DELAY_SECONDS = 0.08
local BRIDGE_SOUND_PLACEHOLDER = "Play_woosh"

local m_audioQueue = {}

-- ===========================================================================
-- Sound mappings
-- ===========================================================================

local TERRAIN_SOUNDS = {
    TERRAIN_GRASS = "Play_grass",
    TERRAIN_GRASS_HILLS = "Play_grass",

    TERRAIN_PLAINS = "Play_plains",
    TERRAIN_PLAINS_HILLS = "Play_plains",

    TERRAIN_DESERT = "Play_desert",
    TERRAIN_DESERT_HILLS = "Play_desert",
    TERRAIN_DESERT_MOUNTAIN = "Play_desert",

    TERRAIN_TUNDRA = "Play_tundra",
    TERRAIN_TUNDRA_HILLS = "Play_tundra",
    TERRAIN_TUNDRA_MOUNTAIN = "Play_tundra",

    TERRAIN_SNOW = "Play_snow",
    TERRAIN_SNOW_HILLS = "Play_snow",
    TERRAIN_SNOW_MOUNTAIN = "Play_snow",

    TERRAIN_COAST = "Play_coast",
    TERRAIN_OCEAN = "Play_coast",
}

local FEATURE_BEDS = {
    FEATURE_JUNGLE = "Play_jungle",
    FEATURE_MARSH = "Play_marsh",

    FEATURE_FLOODPLAINS = "Play_Floodplains",
    FEATURE_FLOODPLAINS_GRASSLAND = "Play_Floodplains",
    FEATURE_FLOODPLAINS_PLAINS = "Play_Floodplains",

    FEATURE_OASIS = "Play_oasis",
    FEATURE_ICE = "Play_ice",
    FEATURE_REEF = "Play_reef",
    FEATURE_GEOTHERMAL_FISSURE = "Play_geothermal_fissure",
    FEATURE_VOLCANIC_SOIL = "Play_volcanic_soil",
}

local FEATURE_STINGERS = {
    FEATURE_FOREST = "Play_forest",
    FEATURE_VOLCANO = "Play_volcano",
}

-- ===========================================================================
-- Queue
-- ===========================================================================

local function GetTime()
    return Automation.GetTime()
end

local function ClearQueue()
    m_audioQueue = {}
end

local function QueueSound(sound, delaySeconds)
    if sound == nil or sound == "" then return end

    table.insert(m_audioQueue, {
        Sound = sound,
        Time = GetTime() + (delaySeconds or 0),
    })
end

function CAICursorAudio.OnUpdate()
    if #m_audioQueue == 0 then return end

    local now = GetTime()

    for i = #m_audioQueue, 1, -1 do
        local item = m_audioQueue[i]
        if now >= item.Time then
            UI.PlaySound(item.Sound)
            table.remove(m_audioQueue, i)
        end
    end
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

local function GetRouteType(plot)
    if plot == nil then return -1 end

    if plot.GetRouteType ~= nil then
        return plot:GetRouteType() or -1
    end

    return -1
end

local function HasRoute(plot)
    return GetRouteType(plot) >= 0
end

local function GetCrossingSound(fromPlot, toPlot)
    if fromPlot == nil or toPlot == nil then return nil end

    if not fromPlot:IsRiverCrossingToPlot(toPlot) then
        return nil
    end

    if HasRoute(fromPlot) and HasRoute(toPlot) then
        -- Placeholder until the bank has a dedicated Play_bridge event.
        return BRIDGE_SOUND_PLACEHOLDER
    end

    return "Play_river_crossing"
end

local function GetBedSound(plot)
    if plot == nil then return nil end

    local feature = GetFeatureRow(plot)
    if feature ~= nil then
        local featureSound = FEATURE_BEDS[feature.FeatureType]
        if featureSound ~= nil then
            return featureSound
        end
    end

    if plot:IsWater() then
        return "Play_coast"
    end

    local terrain = GetTerrainRow(plot)
    if terrain ~= nil then
        local terrainSound = TERRAIN_SOUNDS[terrain.TerrainType]
        if terrainSound ~= nil then
            return terrainSound
        end
    end

    return "Play_grass"
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

    return results
end

-- ===========================================================================
-- Public API
-- ===========================================================================

function CAICursorAudio.PlayPlot(plot, prevPlot)
    if plot == nil then return end
    if not IsPlotRevealed(plot) then return end

    UI.PlaySound("Stop_CursorAudio")
    ClearQueue()

    local crossing = GetCrossingSound(prevPlot, plot)
    local bedDelay = 0

    if crossing ~= nil then
        QueueSound(crossing, 0)
        bedDelay = STINGER_DELAY_SECONDS
    end

    QueueSound(GetBedSound(plot), bedDelay)

    for _, stinger in ipairs(GetStingers(plot)) do
        QueueSound(stinger, bedDelay + STINGER_DELAY_SECONDS)
    end
end

function CAICursorAudio.PlayPlotById(plotId, prevPlotId)
    if plotId == nil or plotId < 0 then return end

    local plot = Map.GetPlotByIndex(plotId)
    if plot == nil then return end

    local prevPlot = nil
    if prevPlotId ~= nil and prevPlotId >= 0 then
        prevPlot = Map.GetPlotByIndex(prevPlotId)
    end

    CAICursorAudio.PlayPlot(plot, prevPlot)
end

local function OnCAICursorMoved(data)
    if data == nil then return end
    CAICursorAudio.PlayPlotById(data.toPlotId, data.fromPlotId)
end

function CAICursorAudio.Initialize()
    LuaEvents.CAICursorMoved.Add(OnCAICursorMoved)
    ClearQueue()
end

function CAICursorAudio.Shutdown()
    LuaEvents.CAICursorMoved.Remove(OnCAICursorMoved)
    ClearQueue()
end
