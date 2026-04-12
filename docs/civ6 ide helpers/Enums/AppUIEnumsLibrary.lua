---@meta


---@enum DiplomaticThreatTypes
DiplomaticThreatTypes = {
    NO_THREAT = 4,
    MAJOR_THREAT = 1,
    UNKNOWN_THREAT = -1,
    INVALID_THREAT = 0,
    MODERATE_THREAT = 2,
    MINOR_THREAT = 3
}
---@enum TradeItemDesirability
TradeItemDesirability = {
    POOR = 3,
    DESIRED = 0,
    NEUTRAL = 1,
    FORBIDDEN = 4,
    DISFAVORED = 2
}
---@enum SaveLocationOptions
SaveLocationOptions = {
    PREVIOUS = 8,
    LOAD_METADATA = 32,
    QUICKSAVE = 2,
    MOST_RECENT_ONLY = 64,
    AUTOSAVE = 4,
    NORMAL = 1,
    DIRECTORIES = 256,
    NO_OPTIONS = 0
}
---@enum InputLayoutTypes
InputLayoutTypes = {
    PC = 0,
    CONSOLE = 1
}
---@enum CombatVisType
CombatVisType = {
    DEFENDER = 1,
    INTERCEPTOR = 2,
    ANTI_AIR = 3,
    ATTACKER = 0
}
---@enum SaveDirectories
SaveDirectories = {
    AUTOMATION = 3,
    DEFAULT = 0,
    BENCHMARK = 2,
    USER = 1,
    DEMO = 5,
    TUTORIAL = 4
}
---@enum MainMenuStateDoneData
MainMenuStateDoneData = {
    eBeginGame = 0
}
---@enum RibbonHUDStats
RibbonHUDStats = {
    HIDE = 0,
    FOCUS = 1,
    SHOW = 2
}
---@enum DiplomaticVisibilityTypes
DiplomaticVisibilityTypes = {
    LIMITED = 1,
    SECRET = 3,
    NONE = -1,
    TOP_SECRET = 4,
    FULL = 2
}
---@enum TurnNotifyFrequencyModes
TurnNotifyFrequencyModes = {
    TurnNotify_EveryTurn = 1,
    TurnNotify_MyTurn = 0
}
---@enum ARXDeviceTypes
ARXDeviceTypes = {
    IPHONE = 1,
    ANDROID_UNKNOWN = 7,
    ANDROID_XLARGE = 6,
    UNKNOWN = 0,
    IPAD = 2,
    ANDROID_LARGE = 5,
    ANDROID_SMALL = 3
}
---@enum WorldRenderView
WorldRenderView = {
    VIEW_3D = 0,
    VIEW_2D = 1
}
---@enum OptionFileTypes
OptionFileTypes = {
    Application = 1,
    Audio = 2,
    Graphics = 3,
    User = 5,
    KeyMap = 4
}
---@enum PushDataSearchOptions
PushDataSearchOptions = {
    IsSeen = 4,
    IsOpen = 1,
    IsClosed = 2,
    IsUnseen = 8
}
---@enum PlayerTypes
PlayerTypes = {
    NONE = -1,
    OBSERVER = 1000,
    BARBARIAN = 63
}
---@enum CursorTypes
CursorTypes = {
    NORMAL = -2047893672,
    WAIT = 547071007,
    RANGE_ATTACK = -46722710
}
---@enum SlotStatus
SlotStatus = {
    SS_TAKEN = 3,
    SS_COMPUTER = 1,
    SS_OBSERVER = 4,
    SS_OPEN = 0,
    SS_CLOSED = 2
}
---@enum PopupPriority
PopupPriority = {
    Achievement = 4000,
    WorldCongressBetweenTurns = 503,
    Civilopedia = 3000,
    Low = 100,
    TutorialHigh = 2500,
    HotSeatBackground = 5001,
    Default = 10000,
    High = 1000,
    Current = 9999,
    Utmost = 5000,
    MediumHigh = 700,
    Medium = 500,
    PausePanel = 5002,
    EndGameMenu = 5004,
    PlayerChange = 5003,
    Tutorial = 2000,
    InGameTopOptionsMenu = 5005,
    WorldCongressIntro = 501,
    WorldCongressPopup = 502
}
---@enum LensLayers
LensLayers = {
    DISTRICTS_CITY_CENTER = 9,
    TRADE_ROUTE = 39,
    MAP_HEX_MASK = 42,
    ADJACENCY_BONUS_DISTRICTS = 49,
    IMPROVEMENTS = 5,
    NUM_LENS_LAYERS = 57,
    CITY_YIELDS = 47,
    DISTRICTS_NEARBY_MOUNTAIN = 12,
    HEX_COLORING_RELIGION = 35,
    ADJACENCY_BONUS_UNITS = 40,
    MOVEMENT_PATH = 37,
    WORLD_CURSOR = 56,
    LOYALTY_FREECITY_WARNING = 55,
    HEX_COLORING_MOVEMENT = 53,
    CULTURAL_IDENTITY_LENS = 54,
    HEX_COLORING_PLACEMENT = 52,
    DISTRICTS_CAMPUS = 11,
    SELECTION = 41,
    MOVEMENT_ZONE_OF_CONTROL = 38,
    DISTRICTS_COMMERICAL_HUB = 15,
    HEX_COLORING_CONTINENT = 32,
    RESOURCES_BONUS = 6,
    HEX_COLORING_WATER_AVAILABLITY = 34,
    DISTRICTS = 48,
    NUMBERS = 50,
    LABELS_EMPIRE = 28,
    RESOURCES_STRATEGIC = 8,
    HEX_COLORING_APPEAL_LEVEL = 33,
    LABELS_CONTINENT = 29,
    ATTACK_RANGE = 46,
    HEX_COLORING_GREAT_PEOPLE = 36,
    CITIZEN_MANAGEMENT = 45,
    DISTRICTS_ENCAMPMENT_MILITARY = 14,
    RECOMMENDATION_BUILDER = 26,
    CULTURE_BORDERS = 27,
    DISTRICTS_NEIGHBORHOOD = 21,
    DISTRICTS_INDUSTRIAL_ZONE = 20,
    UNITS_ARCHAELOGY = 3,
    RECOMMENDATION_SETTLER = 25,
    RESOURCES_LUXURY = 7,
    YIELD_ICONS = 4,
    UNITS_MILITARY = 0,
    UNITS_RELIGIOUS = 1,
    PURCHASE_PLOT = 43,
    DISTRICTS_AQUEDUCT = 18,
    MOVEMENT_RANGE = 44,
    DISTRICTS_HARBOR = 17,
    DISTRICTS_AERODROME = 22,
    HEX_COLORING_GOVERNMENT = 30,
    DISTRICTS_FIRST = 9,
    DISTRICTS_ENTERTAINMENT_COMPLEX = 19,
    DISTRICTS_THEATER_DISTRICT = 16,
    DISTRICTS_SPACEPORT = 23,
    DISTRICTS_LAST = 23,
    DISTRICTS_HOLY_SITE = 13,
    DISTRICTS_ENCAMPMENT_DEFENSE = 10,
    UNITS_CIVILIAN = 2,
    TOURIST_TOKENS = 24,
    HEX_COLORING_OWNING_CIV = 31,
    HEX_COLORING_ATTACK = 51
}
---@enum DiplomaticTrustTypes
DiplomaticTrustTypes = {
    BARELY_KNOWN = 3,
    UNKNOWN_TRUST = -1,
    DISTRUSTED = 5,
    LOW_TRUST = 4,
    NO_TRUST = 6,
    INVALID_TRUST = 0,
    SOME_TRUST = 2,
    TRUSTED = 1
}
---@enum SaveLocations
SaveLocations = {
    STEAM_CLOUD = 2,
    LOCAL_STORAGE = 1,
    FIRAXIS_CLOUD = 3
}
---@enum SaveTypes
SaveTypes = {
    SINGLE_PLAYER = 1,
    TILED_MAP = 5,
    NETWORK_MULTIPLAYER = 2,
    WORLDBUILDER_MAP = 4,
    HOTSEAT = 3
}
---@enum SaveFileTypes
SaveFileTypes = {
    GAME_CONFIGURATION = 1,
    GAME_STATE = 0
}
