dofile("src/UI/inGame/CAIGameState.lua")
dofile("src/UI/shared/CAIModSupport.lua")
local assertions = 0
local function check(actual, expected, label)
    assertions = assertions + 1
    assert(actual == expected, label .. ": " .. tostring(actual))
end
local localID, met, human, multiplayer, majority = -1, false, false, false, 3
Game = { GetLocalPlayer = function() return localID end }
Players = {}
check(CAIGameState.GetLocalPlayerID(), nil, "negative local id")
localID = nil
check(CAIGameState.GetLocalPlayerID(), nil, "absent local id")
localID = 1000
check(CAIGameState.GetLocalPlayerID(), 1000, "positive observer id preserved")
local id, player = CAIGameState.GetLocalPlayer()
check(id, 1000, "id survives missing player")
check(player, nil, "missing player object")
check(CAIGameState.GetExistingLocalPlayer(), nil, "strict player lookup")
localID = 0
local diplomacy = { HasMet = function() return met end, GetAllianceType = function() return 7 end }
Players[0] = { GetDiplomacy = function() return diplomacy end,
    GetReligion = function() return { GetReligionInMajorityOfCities = function() return majority end } end }
check(CAIGameState.GetLocalPlayerObject(), Players[0], "object-only contract")
PlayerManager = { GetAliveMinors = function() return { { GetID = function() return 2 end } } end }
check(CAIGameState.HasMetCityState(nil), false, "missing player city-state check")
check(CAIGameState.HasMetCityState(Players[0]), false, "unmet city-state")
met = true
check(CAIGameState.HasMetCityState(Players[0]), true, "met city-state")
GameInfo = { Alliances = { ALLIANCE_RELIGIOUS = { Index = 7 } } }
check(CAIGameState.IsReligiousAlliance(diplomacy, 2), true, "religious alliance")
GameInfo.Alliances = nil
check(CAIGameState.IsReligiousAlliance(diplomacy, 2), false, "base-game alliance absence")
local unit = { GetReligiousStrength = function() return 10 end, GetReligionType = function() return 3 end }
check(CAIGameState.IsReligiousUnit(unit), true, "religious strength")
check(CAIGameState.IsReligiousUnit(nil), false, "missing unit")
check(CAIGameState.HasLocalMajorityReligion(unit, 0), true, "majority match")
majority = 4
check(CAIGameState.HasLocalMajorityReligion(unit, 0), false, "live majority changes")
check(CAIGameState.HasLocalMajorityReligion(unit, 99), false, "absent religion owner")
local age = 0
local eras = { HasHeroicGoldenAge = function() return age == 3 end,
    HasGoldenAge = function() return age >= 2 end, HasDarkAge = function() return age == 1 end }
for index, tag in ipairs({ "NORMAL", "DARK", "GOLDEN", "HEROIC" }) do
    age = index - 1
    check(CAIGameState.GetPlayerAgeKey(eras, 0), "LOC_ERA_PROGRESS_" .. tag .. "_AGE", "age priority")
end
Locale = { Lookup = function(value) return value end }
GameConfiguration = { IsAnyMultiplayer = function() return multiplayer end }
PlayerConfigurations = { [2] = { IsHuman = function() return human end,
    GetLeaderName = function() return "Leader" end, GetPlayerName = function() return "Human" end } }
met = false
check(CAIGameState.GetKnownPlayerName(2), "LOC_DIPLOPANEL_UNMET_PLAYER", "unmet identity hidden")
multiplayer, human = true, true
check(CAIGameState.GetKnownPlayerName(2), "Leader (Human)", "multiplayer human naming")
human, met = false, true
check(CAIGameState.GetKnownPlayerName(2), "Leader", "met AI naming")
check(CAIGameState.GetKnownPlayerName(99), "", "missing configuration")
WorldBuilder = nil
check(CAIGameState.IsWorldBuilderActive(), false, "absent world builder")
WorldBuilder = { IsActive = function() return true end }
check(CAIGameState.IsWorldBuilderActive(), true, "active world builder")
local activeMod
Modding = { IsModActive = function(id) return id == activeMod end }
check(CAIModSupport.IsBBGActive(), false, "no BBG")
for _, suffix in ipairs({ "240", "217", "231" }) do
    activeMod = "cb84075d-5007-4207-b662-c35a5f7be" .. suffix
    check(CAIModSupport.IsBBGActive(), true, "BBG historical id")
end
print("Game-state helpers: " .. assertions .. " assertions passed")
