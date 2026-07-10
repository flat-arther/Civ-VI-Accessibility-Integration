-- ===========================================================================
-- CAI Settings
-- ===========================================================================

CREATE TABLE IF NOT EXISTS CAI_Settings (
    SettingId       TEXT NOT NULL PRIMARY KEY,
    Section         TEXT NOT NULL,
    SortIndex       INTEGER NOT NULL DEFAULT 0,

    ValueType       TEXT NOT NULL,
    UIType          TEXT NOT NULL,

    DefaultValue    TEXT NOT NULL,

    Label           TEXT NOT NULL,
    Tooltip         TEXT,

    MinValue        REAL,
    MaxValue        REAL,
    StepValue       REAL,
    PageStepValue   REAL,

    EditMode        TEXT
);

CREATE TABLE IF NOT EXISTS CAI_SettingOptions (
    SettingId   TEXT NOT NULL,
    Value       TEXT NOT NULL,
    Label       TEXT NOT NULL,
    Tooltip     TEXT,
    SortIndex   INTEGER NOT NULL DEFAULT 0,

    PRIMARY KEY (SettingId, Value)
);

INSERT OR REPLACE INTO CAI_Settings
    (SettingId, Section, SortIndex, ValueType, UIType, DefaultValue, Label, Tooltip, EditMode)
VALUES
    ('SpeakTooltip', 'UI', 10, 'bool', 'checkbox', 'true',
     'LOC_CAI_SETTING_SPEAK_TOOLTIP', 'LOC_CAI_SETTING_SPEAK_TOOLTIP_TOOLTIP', NULL),

    ('SpeakPosition', 'UI', 20, 'bool', 'checkbox', 'true',
     'LOC_CAI_SETTING_SPEAK_POSITION', 'LOC_CAI_SETTING_SPEAK_POSITION_TOOLTIP', NULL),

    ('SpeakRole', 'UI', 30, 'bool', 'checkbox', 'true',
     'LOC_CAI_SETTING_SPEAK_ROLE', 'LOC_CAI_SETTING_SPEAK_ROLE_TOOLTIP', NULL),

    ('SearchTimeout', 'UI', 40, 'number', 'editbox', '1.0',
     'LOC_CAI_SETTING_SEARCH_TIMEOUT', 'LOC_CAI_SETTING_SEARCH_TIMEOUT_TOOLTIP', 'NumbersOnly'),

    ('AudioTagEnabled_CURSOR', 'Navigation', 10, 'bool', 'checkbox', 'true',
     'LOC_CAI_SETTING_CURSOR_AUDIO_ENABLED', 'LOC_CAI_SETTING_CURSOR_AUDIO_ENABLED_TOOLTIP', NULL),

    ('AudioTagVolume_CURSOR', 'Navigation', 20, 'number', 'slider', '100',
     'LOC_CAI_SETTING_CURSOR_AUDIO_VOLUME', 'LOC_CAI_SETTING_CURSOR_AUDIO_VOLUME_TOOLTIP', NULL),

    ('ScannerAutoMoveCursor', 'Navigation', 30, 'bool', 'checkbox', 'false',
     'LOC_CAI_SETTING_SCANNER_AUTO_MOVE_CURSOR', 'LOC_CAI_SETTING_SCANNER_AUTO_MOVE_CURSOR_TOOLTIP', NULL),

    ('ScannerCoordinates', 'Navigation', 31, 'string', 'dropdown', 'disabled',
     'LOC_CAI_SETTING_SCANNER_COORDINATES', 'LOC_CAI_SETTING_SCANNER_COORDINATES_TOOLTIP', NULL),

    ('ScannerAutoFocusValidTargets', 'Navigation', 32, 'bool', 'checkbox', 'false',
     'LOC_CAI_SETTING_SCANNER_AUTO_FOCUS_VALID_TARGETS', 'LOC_CAI_SETTING_SCANNER_AUTO_FOCUS_VALID_TARGETS_TOOLTIP', NULL),

    ('ScannerAutoFocusActiveLens', 'Navigation', 33, 'bool', 'checkbox', 'false',
     'LOC_CAI_SETTING_SCANNER_AUTO_FOCUS_ACTIVE_LENS', 'LOC_CAI_SETTING_SCANNER_AUTO_FOCUS_ACTIVE_LENS_TOOLTIP', NULL),

    ('CursorCoordinates', 'Navigation', 40, 'string', 'dropdown', 'disabled',
     'LOC_CAI_SETTING_CURSOR_COORDINATES', 'LOC_CAI_SETTING_CURSOR_COORDINATES_TOOLTIP', NULL),

    ('SpeakOwnerZone', 'Navigation', 50, 'bool', 'checkbox', 'true',
     'LOC_CAI_SETTING_SPEAK_OWNER_ZONE', 'LOC_CAI_SETTING_SPEAK_OWNER_ZONE_TOOLTIP', NULL),

    ('SpeakTerritoryZone', 'Navigation', 60, 'bool', 'checkbox', 'true',
     'LOC_CAI_SETTING_SPEAK_TERRITORY_ZONE', 'LOC_CAI_SETTING_SPEAK_TERRITORY_ZONE_TOOLTIP', NULL),

    ('SpeakContinentZone', 'Navigation', 70, 'bool', 'checkbox', 'true',
     'LOC_CAI_SETTING_SPEAK_CONTINENT_ZONE', 'LOC_CAI_SETTING_SPEAK_CONTINENT_ZONE_TOOLTIP', NULL),

    ('SpeakNationalParkZone', 'Navigation', 80, 'bool', 'checkbox', 'true',
     'LOC_CAI_SETTING_SPEAK_NATIONAL_PARK_ZONE', 'LOC_CAI_SETTING_SPEAK_NATIONAL_PARK_ZONE_TOOLTIP', NULL),

    ('AnnounceVisibilityChangesTurnStart', 'Navigation', 90, 'bool', 'checkbox', 'true',
     'LOC_CAI_SETTING_ANNOUNCE_VISIBILITY_TURN_START', 'LOC_CAI_SETTING_ANNOUNCE_VISIBILITY_TURN_START_TOOLTIP', NULL),

    ('AnnounceVisibilityChangesOutsideTurn', 'Navigation', 100, 'bool', 'checkbox', 'false',
     'LOC_CAI_SETTING_ANNOUNCE_VISIBILITY_OUTSIDE_TURN', 'LOC_CAI_SETTING_ANNOUNCE_VISIBILITY_OUTSIDE_TURN_TOOLTIP', NULL),

    ('AnnounceVisibilityChangesWhileMoving', 'Navigation', 110, 'bool', 'checkbox', 'true',
     'LOC_CAI_SETTING_ANNOUNCE_VISIBILITY_WHILE_MOVING', 'LOC_CAI_SETTING_ANNOUNCE_VISIBILITY_WHILE_MOVING_TOOLTIP', NULL),

    ('SpeakMessageBufferNotifications', 'MessageBuffer', 10, 'bool', 'checkbox', 'true',
     'LOC_CAI_SETTING_SPEAK_MESSAGE_BUFFER_NOTIFICATIONS', 'LOC_CAI_SETTING_SPEAK_MESSAGE_BUFFER_NOTIFICATIONS_TOOLTIP', NULL),

    ('SpeakMessageBufferReveals', 'MessageBuffer', 20, 'bool', 'checkbox', 'true',
     'LOC_CAI_SETTING_SPEAK_MESSAGE_BUFFER_REVEALS', 'LOC_CAI_SETTING_SPEAK_MESSAGE_BUFFER_REVEALS_TOOLTIP', NULL),

    ('SpeakMessageBufferCombat', 'MessageBuffer', 30, 'bool', 'checkbox', 'true',
     'LOC_CAI_SETTING_SPEAK_MESSAGE_BUFFER_COMBAT', 'LOC_CAI_SETTING_SPEAK_MESSAGE_BUFFER_COMBAT_TOOLTIP', NULL),

    ('SpeakMessageBufferMovement', 'MessageBuffer', 40, 'bool', 'checkbox', 'true',
     'LOC_CAI_SETTING_SPEAK_MESSAGE_BUFFER_MOVEMENT', 'LOC_CAI_SETTING_SPEAK_MESSAGE_BUFFER_MOVEMENT_TOOLTIP', NULL),

    ('SpeakMessageBufferChat', 'MessageBuffer', 50, 'bool', 'checkbox', 'true',
     'LOC_CAI_SETTING_SPEAK_MESSAGE_BUFFER_CHAT', 'LOC_CAI_SETTING_SPEAK_MESSAGE_BUFFER_CHAT_TOOLTIP', NULL),

    ('SpeakMessageBufferGossip', 'MessageBuffer', 60, 'bool', 'checkbox', 'true',
     'LOC_CAI_SETTING_SPEAK_MESSAGE_BUFFER_GOSSIP', 'LOC_CAI_SETTING_SPEAK_MESSAGE_BUFFER_GOSSIP_TOOLTIP', NULL),

    ('MessageBufferLimit', 'MessageBuffer', 70, 'number', 'editbox', '5000',
     'LOC_CAI_SETTING_MESSAGE_BUFFER_LIMIT', 'LOC_CAI_SETTING_MESSAGE_BUFFER_LIMIT_TOOLTIP', 'NumbersOnly');

UPDATE CAI_Settings
SET MinValue = 0, MaxValue = 100, StepValue = 5, PageStepValue = 10
WHERE SettingId = 'AudioTagVolume_CURSOR';

INSERT OR REPLACE INTO CAI_SettingOptions
    (SettingId, Value, Label, Tooltip, SortIndex)
VALUES
    ('CursorCoordinates', 'disabled',
     'LOC_CAI_SETTING_CURSOR_COORDINATES_DISABLED',
     'LOC_CAI_SETTING_CURSOR_COORDINATES_DISABLED_TOOLTIP', 10),

    ('CursorCoordinates', 'append',
     'LOC_CAI_SETTING_CURSOR_COORDINATES_APPEND',
     'LOC_CAI_SETTING_CURSOR_COORDINATES_APPEND_TOOLTIP', 20),

    ('CursorCoordinates', 'prepend',
     'LOC_CAI_SETTING_CURSOR_COORDINATES_PREPEND',
     'LOC_CAI_SETTING_CURSOR_COORDINATES_PREPEND_TOOLTIP', 30),

    ('ScannerCoordinates', 'disabled',
     'LOC_CAI_SETTING_SCANNER_COORDINATES_DISABLED',
     'LOC_CAI_SETTING_SCANNER_COORDINATES_DISABLED_TOOLTIP', 10),

    ('ScannerCoordinates', 'append',
     'LOC_CAI_SETTING_SCANNER_COORDINATES_APPEND',
     'LOC_CAI_SETTING_SCANNER_COORDINATES_APPEND_TOOLTIP', 20),

    ('ScannerCoordinates', 'prepend',
     'LOC_CAI_SETTING_SCANNER_COORDINATES_PREPEND',
     'LOC_CAI_SETTING_SCANNER_COORDINATES_PREPEND_TOOLTIP', 30);
