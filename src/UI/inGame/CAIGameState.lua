-- Live in-game queries. Preserve local-player and visibility contracts; do not cache state.
CAIGameState = {}

function CAIGameState.GetLocalPlayer()
    local playerID = CAIGameState.GetLocalPlayerID()
    if playerID == nil then return nil, nil end
    return playerID, Players[playerID]
end

-- Unlike GetLocalPlayer, discard the ID when its player object is absent.
function CAIGameState.GetExistingLocalPlayer()
    local playerID, player = CAIGameState.GetLocalPlayer()
    if player == nil then return nil, nil end

    return playerID, player
end

function CAIGameState.GetKnownPlayerName(playerID)
    if playerID < 0 then return "" end
    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID < 0 then return "" end
    local pConfig = PlayerConfigurations[playerID]
    if not pConfig then return "" end
    local isMP = GameConfiguration.IsAnyMultiplayer()
    local isMet = (playerID == localPlayerID)
    if not isMet then
        local pDip = Players[localPlayerID]:GetDiplomacy()
        isMet = pDip:HasMet(playerID)
    end
    if not isMet and not (isMP and pConfig:IsHuman()) then
        return Locale.Lookup("LOC_DIPLOPANEL_UNMET_PLAYER")
    end
    local name = Locale.Lookup(pConfig:GetLeaderName())
    if isMP and pConfig:IsHuman() then
        name = name .. " (" .. pConfig:GetPlayerName() .. ")"
    end
    return name
end

function CAIGameState.IsWorldBuilderActive()
    return WorldBuilder ~= nil
        and WorldBuilder.IsActive ~= nil
        and WorldBuilder.IsActive()
end

function CAIGameState.GetPlayerAgeKey(gameEras, playerID)
    if gameEras:HasHeroicGoldenAge(playerID) then
        return "LOC_ERA_PROGRESS_HEROIC_AGE"
    elseif gameEras:HasGoldenAge(playerID) then
        return "LOC_ERA_PROGRESS_GOLDEN_AGE"
    elseif gameEras:HasDarkAge(playerID) then
        return "LOC_ERA_PROGRESS_DARK_AGE"
    else
        return "LOC_ERA_PROGRESS_NORMAL_AGE"
    end
end

function CAIGameState.IsReligiousUnit(unit)
    return unit ~= nil and unit:GetReligiousStrength() > 0
end

function CAIGameState.IsReligiousAlliance(diplomacy, ownerID)
    local religiousAlliance = GameInfo.Alliances ~= nil
        and GameInfo.Alliances["ALLIANCE_RELIGIOUS"] or nil
    return religiousAlliance ~= nil
        and diplomacy ~= nil
        and diplomacy:GetAllianceType(ownerID) == religiousAlliance.Index
end

function CAIGameState.HasLocalMajorityReligion(unit, localPlayerID)
    local localPlayer = localPlayerID ~= nil and Players[localPlayerID] or nil
    local localReligion = localPlayer ~= nil and localPlayer:GetReligion() or nil
    if localReligion == nil then
        return false
    end

    local religionType = unit:GetReligionType()
    local localReligionType = localReligion:GetReligionInMajorityOfCities()
    return religionType ~= nil and religionType >= 0 and religionType == localReligionType
end

function CAIGameState.GetLocalPlayerID()
    local playerID = Game.GetLocalPlayer()
    if playerID == nil or playerID < 0 then return nil end
    return playerID
end

function CAIGameState.GetLocalPlayerObject()
    local _, player = CAIGameState.GetLocalPlayer()
    return player
end

function CAIGameState.HasMetCityState(player)
    if player == nil then return false end
    local diplomacy = player:GetDiplomacy()
    for _, minor in ipairs(PlayerManager.GetAliveMinors()) do
        if diplomacy:HasMet(minor:GetID()) then return true end
    end
    return false
end

function CAIGameState.GetReligionName(religionType)
    if religionType == nil or religionType < 0 then
        return nil
    end

    local gameReligion = Game.GetReligion ~= nil and Game.GetReligion() or nil
    if gameReligion ~= nil and gameReligion.GetName ~= nil then
        local name = gameReligion:GetName(religionType)
        if name ~= nil and name ~= "" then
            return Locale.Lookup(name)
        end
    end

    return nil
end
