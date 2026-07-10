-- ===========================================================================
-- CAI Audio Definitions
-- Raw sound definitions loaded by UI/shared/audioManager_CAI.lua
-- ===========================================================================

CREATE TABLE IF NOT EXISTS CAI_AudioDefinitions (
    SoundId         TEXT NOT NULL PRIMARY KEY,
    RelativePath    TEXT NOT NULL,
    Tag             TEXT NOT NULL
);

INSERT OR REPLACE INTO CAI_AudioDefinitions
    (SoundId, RelativePath, Tag)
VALUES
    ('CURSOR_COAST', 'sounds/cursor/coast.wav', 'CURSOR_TERRAIN'),
    ('CURSOR_DESERT', 'sounds/cursor/desert.wav', 'CURSOR_TERRAIN'),
    ('CURSOR_FLOODPLAINS', 'sounds/cursor/Floodplains.wav', 'CURSOR_TERRAIN'),
    ('CURSOR_FOREST', 'sounds/cursor/forest.wav', 'CURSOR_STINGERS'),
    ('CURSOR_GEOTHERMAL_FISSURE', 'sounds/cursor/geothermal_fissure.wav', 'CURSOR_TERRAIN'),
    ('CURSOR_GRASS', 'sounds/cursor/grass.wav', 'CURSOR_TERRAIN'),
    ('CURSOR_ICE', 'sounds/cursor/ice.wav', 'CURSOR_TERRAIN'),
    ('CURSOR_JUNGLE', 'sounds/cursor/jungle.wav', 'CURSOR_TERRAIN'),
    ('CURSOR_MARSH', 'sounds/cursor/marsh.wav', 'CURSOR_TERRAIN'),
    ('CURSOR_MOUNTAIN', 'sounds/cursor/mountain.wav', 'CURSOR_TERRAIN'),
    ('CURSOR_OASIS', 'sounds/cursor/oasis.wav', 'CURSOR_TERRAIN'),
    ('CURSOR_OCEAN', 'sounds/cursor/ocean.wav', 'CURSOR_TERRAIN'),
    ('CURSOR_PLAINS', 'sounds/cursor/plains.wav', 'CURSOR_TERRAIN'),
    ('CURSOR_REEF', 'sounds/cursor/reef.wav', 'CURSOR_TERRAIN'),
    ('CURSOR_SNOW', 'sounds/cursor/snow.wav', 'CURSOR_TERRAIN'),
    ('CURSOR_TUNDRA', 'sounds/cursor/tundra.wav', 'CURSOR_TERRAIN'),
    ('CURSOR_VOLCANIC_SOIL', 'sounds/cursor/volcanic_soil.wav', 'CURSOR_TERRAIN'),
    ('CURSOR_VOLCANO', 'sounds/cursor/volcano.wav', 'CURSOR_STINGERS'),
    ('CURSOR_WOOSH', 'sounds/cursor/woosh.wav', 'CURSOR_FOG');
