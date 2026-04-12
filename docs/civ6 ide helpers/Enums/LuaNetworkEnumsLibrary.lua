---@meta


---@enum KickVoteResultType
KickVoteResultType = {
    KICKVOTERESULT_PENDING = 0,
    KICKVOTERESULT_VOTED_NO_KICK = 3,
    KICKVOTERESULT_VOTE_PASSED = 4,
    KICKVOTERESULT_TIME_ELAPSED = 2,
    KICKVOTERESULT_NOT_ENOUGH_PLAYERS = 1
}
---@enum KickVoteReasonType
KickVoteReasonType = {
    KICKVOTE_GRIEFING = 2,
    KICKVOTE_CHEATING = 3,
    KICKVOTE_AFK = 1,
    KICKVOTE_NONE = 0
}
---@enum NetworkCapabilityStates
NetworkCapabilityStates = {
    Enabled = 1622900199,
    Unsupported = 1133691932,
    Disabled = -2106068150
}
---@enum NetworkResult
NetworkResult = {
    NETWORKRESULT_SIGNIN = 3,
    NETWORKRESULT_ERROR = 4,
    NETWORKRESULT_PENDING = 2,
    NETWORKRESULT_EXISTING_OPERATION_PENDING = 6,
    NETWORKRESULT_OK = 1,
    NETWORKRESULT_NO_ROOM = 5,
    NETWORKRESULT_NONE = 0
}
---@enum JoinGameErrorType
JoinGameErrorType = {
    JOINGAME_GAME_STARTED = 2,
    JOINGAME_ROOM_FULL = 1,
    JOINGAME_NO_ERROR = 0,
    JOINGAME_TOO_MANY_MATCHES = 3
}
---@enum NetPlayerTypes
NetPlayerTypes = {
    INVALID_PLAYERID = -1
}
---@enum FireWireTypes
FireWireTypes = {
    FIREWIRE_INVALID_ID = -1
}
---@enum NetworkServicesAccountType
NetworkServicesAccountType = {
    Platform = 3,
    Full = 2,
    Anonymous = 1,
    Unknown = 0
}
---@enum ChatTargetTypes
ChatTargetTypes = {
    NO_CHATTARGET = -1,
    CHATTARGET_TEAM = -3,
    CHATTARGET_PLAYER = -4,
    CHATTARGET_ALL = -2
}
---@enum PlayByCloudReadyBehaviorType
PlayByCloudReadyBehaviorType = {
    PBC_READY_EXIT_LOBBY = 2,
    PBC_READY_DO_NOTHING = 1,
    PBC_READY_ASK_ME = 0
}
---@enum LobbyTypes
LobbyTypes = {
    LOBBY_CROSSPLAY = 5,
    LOBBY_FIRAXIS_CLOUD = 4,
    LOBBY_SERVER = 3,
    LOBBY_INTERNET = 2,
    LOBBY_LAN = 1,
    LOBBY_NONE = 0
}
---@enum KickReason
KickReason = {
    KICK_NO_ROOM = 6,
    KICK_HOST = 2,
    KICK_UNAUTHORIZED = 5,
    KICK_TIMEOUT = 3,
    KICK_NO_HOST = 1,
    KICK_MATCH_DELETED = 10,
    KICK_MOD_MISSING = 9,
    KICK_MOD_ERROR = 8,
    KICK_NONE = 0,
    KICK_UNRECOGNIZED = 4,
    KICK_VERSION_MISMATCH = 7
}
---@enum ServerType
ServerType = {
    SERVER_TYPE_NONE = 0,
    SERVER_TYPE_STEAM = 3,
    SERVER_TYPE_CROSSPLAY = 7,
    SERVER_TYPE_FIRAXIS_CLOUD = 6,
    SERVER_TYPE_HOTSEAT = 5,
    SERVER_TYPE_INTERNET = 2,
    SERVER_TYPE_LAN = 1,
    SERVER_TYPE_STEAM_DEDICATED = 4
}
---@enum NetworkPlatform
NetworkPlatform = {
    NETWORK_PLATFORM_EOS = 3,
    NETWORK_PLATFORM_UNKNOWN = 0,
    NETWORK_PLATFORM_RAIL = 2,
    NETWORK_PLATFORM_STEAM = 1
}
---@enum PlayByCloudEndTurnBehaviorType
PlayByCloudEndTurnBehaviorType = {
    PBC_ENDTURN_DO_NOTHING = 1,
    PBC_ENDTURN_EXIT_MAINMENU = 2,
    PBC_ENDTURN_ASK_ME = 0
}
---@enum TransportType
TransportType = {
    TRANSPORT_ENET = 1,
    TRANSPORT_RAIL = 3,
    TRANSPORT_STEAM = 2,
    TRANSPORT_EOS = 4,
    TRANSPORT_NONE = 0
}
