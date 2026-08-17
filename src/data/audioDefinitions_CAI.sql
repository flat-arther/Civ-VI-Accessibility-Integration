-- ===========================================================================
-- CAI Audio Definitions
-- Raw sound definitions loaded by UI/shared/audioManager_CAI.lua
-- ===========================================================================

CREATE TABLE IF NOT EXISTS CAI_AudioDefinitions (
    SoundId         TEXT NOT NULL PRIMARY KEY,
    RelativePath    TEXT NOT NULL,
    Tag             TEXT NOT NULL,
    IsPositional    INTEGER NOT NULL DEFAULT 0
);

INSERT OR REPLACE INTO CAI_AudioDefinitions
    (SoundId, RelativePath, Tag, IsPositional)
VALUES
    ('UI_MENU_WRAP', 'UI/menu_wrap.wav', 'UI_NAVIGATION', 0),
    ('SCANNER_BEACON', 'UI/scanner_beacon.wav', 'BEACONS', 1),
    ('CURSOR_COAST', 'cursor/coast.wav', 'CURSOR_TERRAIN', 0),
    ('CURSOR_DESERT', 'cursor/desert.wav', 'CURSOR_TERRAIN', 0),
    ('CURSOR_FLOODPLAINS', 'cursor/Floodplains.wav', 'CURSOR_TERRAIN', 0),
    ('CURSOR_FOREST', 'cursor/forest.wav', 'CURSOR_STINGERS', 0),
    ('CURSOR_GEOTHERMAL_FISSURE', 'cursor/geothermal_fissure.wav', 'CURSOR_TERRAIN', 0),
    ('CURSOR_GRASS', 'cursor/grass.wav', 'CURSOR_TERRAIN', 0),
    ('CURSOR_ICE', 'cursor/ice.wav', 'CURSOR_TERRAIN', 0),
    ('CURSOR_JUNGLE', 'cursor/jungle.wav', 'CURSOR_TERRAIN', 0),
    ('CURSOR_MARSH', 'cursor/marsh.wav', 'CURSOR_TERRAIN', 0),
    ('CURSOR_METAL_WALK', 'cursor/metalWalk.wav', 'CURSOR_STINGERS', 0),
    ('CURSOR_MOUNTAIN', 'cursor/mountain.wav', 'CURSOR_TERRAIN', 0),
    ('CURSOR_OASIS', 'cursor/oasis.wav', 'CURSOR_TERRAIN', 0),
    ('CURSOR_OCEAN', 'cursor/ocean.wav', 'CURSOR_TERRAIN', 0),
    ('CURSOR_PLAINS', 'cursor/plains.wav', 'CURSOR_TERRAIN', 0),
    ('CURSOR_REEF', 'cursor/reef.wav', 'CURSOR_TERRAIN', 0),
    ('CURSOR_RIVER_CROSSING', 'cursor/riverCrossing.wav', 'CURSOR_CROSSINGS', 0),
    ('CURSOR_ROAD_WALK', 'cursor/roadWalk.wav', 'CURSOR_STINGERS', 0),
    ('CURSOR_SNOW', 'cursor/snow.wav', 'CURSOR_TERRAIN', 0),
    ('CURSOR_TUNDRA', 'cursor/tundra.wav', 'CURSOR_TERRAIN', 0),
    ('CURSOR_VOLCANIC_SOIL', 'cursor/volcanic_soil.wav', 'CURSOR_TERRAIN', 0),
    ('CURSOR_VOLCANO', 'cursor/volcano.wav', 'CURSOR_STINGERS', 0),
    ('CURSOR_WOOD_WALK', 'cursor/woodWalk.wav', 'CURSOR_CROSSINGS', 0),
    ('CURSOR_WOOSH', 'cursor/woosh.wav', 'CURSOR_FOG', 0);
