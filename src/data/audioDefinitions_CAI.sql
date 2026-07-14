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
    ('UI_MENU_WRAP', 'sounds/UI/menu_wrap.wav', 'UI_NAVIGATION', 0),
    ('SCANNER_BEACON', 'sounds/UI/scanner_beacon.wav', 'BEACONS', 1),
    ('CURSOR_COAST', 'sounds/cursor/coast.wav', 'CURSOR_TERRAIN', 0),
    ('CURSOR_DESERT', 'sounds/cursor/desert.wav', 'CURSOR_TERRAIN', 0),
    ('CURSOR_FLOODPLAINS', 'sounds/cursor/Floodplains.wav', 'CURSOR_TERRAIN', 0),
    ('CURSOR_FOREST', 'sounds/cursor/forest.wav', 'CURSOR_STINGERS', 0),
    ('CURSOR_GEOTHERMAL_FISSURE', 'sounds/cursor/geothermal_fissure.wav', 'CURSOR_TERRAIN', 0),
    ('CURSOR_GRASS', 'sounds/cursor/grass.wav', 'CURSOR_TERRAIN', 0),
    ('CURSOR_ICE', 'sounds/cursor/ice.wav', 'CURSOR_TERRAIN', 0),
    ('CURSOR_JUNGLE', 'sounds/cursor/jungle.wav', 'CURSOR_TERRAIN', 0),
    ('CURSOR_MARSH', 'sounds/cursor/marsh.wav', 'CURSOR_TERRAIN', 0),
    ('CURSOR_METAL_WALK', 'sounds/cursor/metalWalk.wav', 'CURSOR_STINGERS', 0),
    ('CURSOR_MOUNTAIN', 'sounds/cursor/mountain.wav', 'CURSOR_TERRAIN', 0),
    ('CURSOR_OASIS', 'sounds/cursor/oasis.wav', 'CURSOR_TERRAIN', 0),
    ('CURSOR_OCEAN', 'sounds/cursor/ocean.wav', 'CURSOR_TERRAIN', 0),
    ('CURSOR_PLAINS', 'sounds/cursor/plains.wav', 'CURSOR_TERRAIN', 0),
    ('CURSOR_REEF', 'sounds/cursor/reef.wav', 'CURSOR_TERRAIN', 0),
    ('CURSOR_RIVER_CROSSING', 'sounds/cursor/riverCrossing.wav', 'CURSOR_CROSSINGS', 0),
    ('CURSOR_ROAD_WALK', 'sounds/cursor/roadWalk.wav', 'CURSOR_STINGERS', 0),
    ('CURSOR_SNOW', 'sounds/cursor/snow.wav', 'CURSOR_TERRAIN', 0),
    ('CURSOR_TUNDRA', 'sounds/cursor/tundra.wav', 'CURSOR_TERRAIN', 0),
    ('CURSOR_VOLCANIC_SOIL', 'sounds/cursor/volcanic_soil.wav', 'CURSOR_TERRAIN', 0),
    ('CURSOR_VOLCANO', 'sounds/cursor/volcano.wav', 'CURSOR_STINGERS', 0),
    ('CURSOR_WOOD_WALK', 'sounds/cursor/woodWalk.wav', 'CURSOR_CROSSINGS', 0),
    ('CURSOR_WOOSH', 'sounds/cursor/woosh.wav', 'CURSOR_FOG', 0);
