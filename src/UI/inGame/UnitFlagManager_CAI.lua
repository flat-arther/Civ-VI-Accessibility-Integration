include("inGameHelpers_CAI")

local function GetCurrentRuleSet()
    if GameConfiguration.GetRuleSet ~= nil then
        return GameConfiguration.GetRuleSet()
    end

    if GameConfiguration.GetValue ~= nil then
        return GameConfiguration.GetValue("RULESET")
    end

    return nil
end

local function IsRuleSetActive(ruleSetType)
    return GetCurrentRuleSet() == ruleSetType
end

local function IsBarbarianClansModeActive()
    return GameConfiguration.GetValue("GAMEMODE_BARBARIAN_CLANS")
end

local function IsPiratesScenarioActive()
    return IsRuleSetActive("RULESET_SCENARIO_PIRATES")
end

local function IsCivRoyaleScenarioActive()
    return IsRuleSetActive("RULESET_SCENARIO_CIV_ROYALE")
end

local function GetUnitFlagManagerIncludeName()
    if IsCivRoyaleScenarioActive() then
        return "UnitFlagManager_CivRoyaleScenario"
    end

    if IsPiratesScenarioActive() then
        return "UnitFlagManager_PiratesScenario"
    end

    if IsBarbarianClansModeActive() then
        return "UnitFlagManager_BarbarianClansMode"
    end

    return "UnitFlagManager"
end

include(GetUnitFlagManagerIncludeName())

local info = ExposedMembers.CAIInfo or {}
ExposedMembers.CAIInfo = info

local UNIT_FLAG_INFO_DEFAULT_KEYS = {
    "unitCount",
    "name",
    "queuedMovement",
    "healthPercent",
    "promotionOrLevy",
    "status",
    "religion",
    "archaeology",
    "aircraftCapacity",
    "markers",
    "barbarianClan",
    "pirates",
}

local OWNED_UNIT_PANEL_DETAIL_KEYS = {
    "Stats",
    "Promotions",
    "UpgradeHint",
}

local function AppendUnitFlagInfo(parts, value)
    if type(value) == "table" then
        for _, innerValue in ipairs(value) do
            AppendUnitFlagInfo(parts, innerValue)
        end
        return
    end

    if value ~= nil and value ~= "" then
        table.insert(parts, value)
    end
end

local function GetControlText(control)
    if control ~= nil and control.GetText ~= nil then
        local text = control:GetText()
        if text ~= nil and text ~= "" then
            return text
        end
    end

    return nil
end

local function GetControlTooltip(control)
    if control ~= nil and control.GetToolTipString ~= nil then
        local tooltip = control:GetToolTipString()
        if tooltip ~= nil and tooltip ~= "" then
            return tooltip
        end
    end

    return nil
end

local function FormatUnitFlagDisplayName(unit, count)
    if unit == nil then
        return nil
    end

    local name = FormatOwnedUnitDisplayName(unit)
    if count ~= nil and count > 1 then
        return Locale.Lookup("LOC_CAI_UNIT_FLAG_AGGREGATED_NAME", count, name)
    end

    return name
end

local function GetUnitFlagHealth(unit)
    if unit == nil then
        return nil
    end

    local maxDamage = unit:GetMaxDamage()
    if maxDamage == nil or maxDamage <= 0 then
        return nil
    end

    local currentHealth = maxDamage - unit:GetDamage()
    if currentHealth >= maxDamage then
        return nil
    end

    return Locale.Lookup("LOC_CAI_UNIT_FLAG_HEALTH", currentHealth, maxDamage)
end

local function GetUnitFlagStatus(unit)
    if unit == nil then
        return nil
    end

    if unit:IsEmbarked() then
        return Locale.Lookup("LOC_CAI_UNIT_EMBARKED")
    end

    if unit:GetFortifyTurns() > 0 then
        return Locale.Lookup("LOC_CAI_WORLDTRACKER_UNIT_FORTIFIED")
    end

    return nil
end

local function IsEnemyUnit(unit)
    local owner = unit ~= nil and Players[unit:GetOwner()] or nil
    if owner == nil then
        return false
    end

    if owner:IsBarbarian() then
        return true
    end

    local localPlayer = Players[Game.GetLocalPlayer()]
    local diplomacy = localPlayer ~= nil and localPlayer:GetDiplomacy() or nil
    return diplomacy ~= nil and diplomacy:IsAtWarWith(unit:GetOwner())
end

local function GetEnemyUnitCombatInfo(unit)
    if not IsEnemyUnit(unit) then
        return nil
    end

    local results = {}
    local combat = unit:GetCombat()
    local rangedCombat = unit:GetRangedCombat()
    local range = unit:GetRange()

    AppendUnitFlagInfo(results,
        combat > 0 and Locale.Lookup("LOC_HUD_UNIT_PANEL_STRENGTH") .. ", " .. tostring(combat) or nil)
    AppendUnitFlagInfo(results,
        rangedCombat > 0 and
        Locale.Lookup("LOC_HUD_UNIT_PANEL_RANGED_STRENGTH") .. ", " .. tostring(rangedCombat) or nil)
    AppendUnitFlagInfo(results,
        range > 0 and Locale.Lookup("LOC_CAI_ICON_RANGE_ALIAS") .. ", " .. tostring(range) or nil)

    return #results > 0 and results or nil
end

local function GetOwnedUnitAircraftInfo(unit)
    local aircraftData = GetHostedAircraftData(unit)
    if aircraftData == nil then
        return nil
    end

    local results = {
        Locale.Lookup("LOC_CAI_UNIT_CARRIER_AIRCRAFT_CAPACITY", aircraftData.CurrentCount, aircraftData.MaxSlots),
    }
    local aircraftNames = GetHostedAircraftUnitNames(unit)
    if aircraftNames ~= nil and #aircraftNames > 0 then
        AppendUnitFlagInfo(results,
            Locale.Lookup("LOC_CAI_UNIT_CARRIER_STATIONED_AIRCRAFT", table.concat(aircraftNames, ", ")))
    end

    return results
end

local function GetOwnedUnitFlagDetails(unit, count)
    local results = {
        FormatUnitFlagDisplayName(unit, count),
        Locale.Lookup("LOC_CAI_UNIT_FLAG_HEALTH", unit:GetMaxDamage() - unit:GetDamage(), unit:GetMaxDamage()),
        Locale.Lookup("LOC_CAI_UNIT_MOVES", unit:GetMovementMovesRemaining(), unit:GetMaxMoves()),
    }
    if unit:GetMovesRemaining() <= 0 then
        AppendUnitFlagInfo(results, Locale.Lookup("LOC_CAI_UNIT_OUT_OF_MOVES"))
    end
    AppendUnitFlagInfo(results, GetUnitFlagStatus(unit))
    AppendUnitFlagInfo(results, GetOwnedUnitAircraftInfo(unit))
    if info.RequestUnitInfo ~= nil then
        AppendUnitFlagInfo(results,
            info:RequestUnitInfo(unit:GetID(), OWNED_UNIT_PANEL_DETAIL_KEYS, unit:GetOwner()))
    end
    return #results > 0 and results or nil
end

local function GetForeignUnitFlagDetails(unit, count)
    local results = {}
    if unit:IsEmbarked() then
        AppendUnitFlagInfo(results, Locale.Lookup("LOC_CAI_UNIT_EMBARKED"))
    end
    AppendUnitFlagInfo(results, FormatUnitFlagDisplayName(unit, count))
    AppendUnitFlagInfo(results, GetUnitFlagHealth(unit))
    if not unit:IsEmbarked() and unit:GetFortifyTurns() > 0 then
        AppendUnitFlagInfo(results, Locale.Lookup("LOC_CAI_WORLDTRACKER_UNIT_FORTIFIED"))
    end
    AppendUnitFlagInfo(results, GetEnemyUnitCombatInfo(unit))
    return #results > 0 and results or nil
end

local function GetDefaultUnitFlagDetails(unit, count)
    if unit:GetOwner() == Game.GetLocalPlayer() then
        return GetOwnedUnitFlagDetails(unit, count)
    end

    return GetForeignUnitFlagDetails(unit, count)
end

local function GetUnitFlagPromotionOrLevy(unit)
    if unit == nil then
        return nil
    end

    if GetLevyTurnsRemaining ~= nil then
        local levyTurnsRemaining = GetLevyTurnsRemaining(unit)
        if levyTurnsRemaining ~= nil and levyTurnsRemaining >= 0 then
            return Locale.Lookup("LOC_CAI_UNIT_FLAG_LEVIED_SHORT", levyTurnsRemaining)
        end
    end

    local experience = unit.GetExperience ~= nil and unit:GetExperience() or nil
    if experience == nil then
        return nil
    end

    local level = experience.GetLevel ~= nil and experience:GetLevel() or nil
    if level ~= nil and level >= 2 then
        return Locale.Lookup("LOC_HUD_UNIT_PANEL_LEVEL_ABBREVIATION") .. " " .. tostring(level)
    end

    return nil
end

local function GetUnitFlagReligion(unit, flag)
    if unit == nil then
        return nil
    end

    local religionName = nil
    if flag ~= nil and flag.m_Instance ~= nil then
        religionName = GetControlTooltip(flag.m_Instance.ReligionIconBacking)
    end

    if religionName == nil and unit.GetReligiousStrength ~= nil and unit:GetReligiousStrength() > 0 then
        local religionType = unit:GetReligionType()
        if religionType ~= nil and religionType > 0 and Game.GetReligion ~= nil then
            religionName = Game.GetReligion():GetName(religionType)
        end
    end

    if religionName == nil or religionName == "" then
        return nil
    end

    return Locale.Lookup("LOC_CAI_UNIT_FLAG_RELIGION_SHORT", religionName)
end

local function GetUnitFlagArchaeology(unit)
    if unit == nil then
        return nil
    end

    local results = {}

    local homeCityID = unit:GetArchaeologyHomeCity()
    if homeCityID ~= nil and homeCityID ~= 0 then
        local owner = Players[unit:GetOwner()]
        local city = owner ~= nil and owner:GetCities() ~= nil and owner:GetCities():FindID(homeCityID) or nil
        if city ~= nil then
            AppendUnitFlagInfo(results, Locale.Lookup("LOC_CAI_UNIT_FLAG_HOME_CITY_SHORT", city:GetName()))
        end

        local greatWorkIndex = unit:GetGreatWorkIndex()
        if greatWorkIndex ~= nil and greatWorkIndex >= 0 then
            local greatWorkType = Game.GetGreatWorkType(greatWorkIndex)
            local greatWorkOwner = Game.GetGreatWorkPlayer(greatWorkIndex)
            local greatWorkInfo = greatWorkType ~= nil and GameInfo.GreatWorks[greatWorkType] or nil
            local ownerConfig = greatWorkOwner ~= nil and PlayerConfigurations[greatWorkOwner] or nil
            if greatWorkInfo ~= nil and greatWorkInfo.Name ~= nil and ownerConfig ~= nil then
                AppendUnitFlagInfo(results,
                    Locale.Lookup("LOC_CAI_UNIT_FLAG_ARTIFACT_SHORT",
                        Locale.Lookup(greatWorkInfo.Name),
                        ownerConfig:GetPlayerName()))
            end
        end
    end

    return #results > 0 and results or nil
end

local function GetUnitFlagAircraftCapacity(unit, flag)
    if unit == nil then
        return nil
    end

    local capacityText = GetHostedAircraftCapacityText(unit)
    if capacityText == nil then
        return nil
    end

    if flag ~= nil and flag.m_Instance ~= nil and flag.m_Instance.AirUnitInstance ~= nil then
        local instance = flag.m_Instance.AirUnitInstance
        local currentText = GetControlText(instance.CurrentUnitCount)
        local maxText = GetControlText(instance.MaxUnitCount)
        local aircraftData = GetHostedAircraftData(unit)
        local currentCount = tonumber(currentText) or (aircraftData ~= nil and aircraftData.CurrentCount or 0)
        local maxAirSlots = tonumber(maxText) or (aircraftData ~= nil and aircraftData.MaxSlots or 0)
        return Locale.Lookup("LOC_CAI_UNIT_FLAG_AIRCRAFT_SHORT", currentCount, maxAirSlots)
    end

    return capacityText
end

local function IsHeroUnit(unit)
    if unit == nil then
        return false
    end

    local unitInfo = GameInfo.Units[unit:GetUnitType()]
    if unitInfo == nil or GameInfo.HeroClasses == nil then
        return false
    end

    for row in GameInfo.HeroClasses() do
        if row.UnitType == unitInfo.UnitType then
            return true
        end
    end

    return false
end

local function GetUnitFlagMarkers(unit, flag)
    if unit == nil then
        return nil
    end

    local results = {}

    if IsHeroUnit(unit) or (flag ~= nil and flag.m_Instance ~= nil and flag.m_Instance.HeroGlowInstance ~= nil) then
        AppendUnitFlagInfo(results, Locale.Lookup("LOC_CAI_UNIT_FLAG_HERO_SHORT"))
    end

    if flag ~= nil and flag.bHasAttentionMarker == true then
        AppendUnitFlagInfo(results, Locale.Lookup("LOC_CAI_UNIT_FLAG_THREAT_SHORT"))
    end

    if IsPiratesScenarioActive() and unit:GetMaxDamage() > 100 then
        AppendUnitFlagInfo(results, Locale.Lookup("LOC_CAI_UNIT_FLAG_FLAGSHIP_SHORT"))
    end

    return #results > 0 and results or nil
end

local function GetBarbarianClanPlayerName(playerID)
    local playerConfig = playerID ~= nil and PlayerConfigurations[playerID] or nil
    return playerConfig ~= nil and playerConfig:GetPlayerName() or nil
end

local function GetUnitFlagBarbarianClan(unit)
    if unit == nil or not IsBarbarianClansModeActive() then
        return nil
    end

    local tribeIndex = unit.GetBarbarianTribeIndex ~= nil and unit:GetBarbarianTribeIndex() or -1
    if tribeIndex == nil or tribeIndex < 0 then
        return nil
    end

    local barbarianManager = Game.GetBarbarianManager ~= nil and Game.GetBarbarianManager() or nil
    if barbarianManager == nil or barbarianManager.IsClanExcludeUnitType == nil then
        return nil
    end

    if barbarianManager:IsClanExcludeUnitType(unit:GetType()) then
        return nil
    end

    local results = {}
    local tribeNameType = barbarianManager:GetTribeNameType(tribeIndex)
    local tribeInfo = tribeNameType ~= nil and tribeNameType >= 0 and GameInfo.BarbarianTribeNames[tribeNameType] or nil
    if tribeInfo ~= nil and tribeInfo.TribeDisplayName ~= nil then
        AppendUnitFlagInfo(results,
            Locale.Lookup("LOC_CAI_UNIT_FLAG_CLAN_SHORT", Locale.Lookup(tribeInfo.TribeDisplayName)))
    end

    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == nil or localPlayerID < 0 then
        return #results > 0 and results or nil
    end

    local bribedTurnsRemaining = barbarianManager:GetTribeBribeTurnsRemaining(tribeIndex, localPlayerID)
    if bribedTurnsRemaining ~= nil and bribedTurnsRemaining > 0 then
        AppendUnitFlagInfo(results, Locale.Lookup("LOC_CAI_UNIT_FLAG_BRIBED_SHORT", bribedTurnsRemaining))
        return #results > 0 and results or nil
    end

    local inciteTargetID = barbarianManager:GetTribeInciteTargetPlayer(tribeIndex)
    if inciteTargetID ~= nil and inciteTargetID >= 0 then
        if inciteTargetID == localPlayerID then
            local inciteSourceName = GetBarbarianClanPlayerName(barbarianManager:GetTribeInciteSourcePlayer(tribeIndex))
            if inciteSourceName ~= nil and inciteSourceName ~= "" then
                AppendUnitFlagInfo(results,
                    Locale.Lookup("LOC_CAI_UNIT_FLAG_INCITED_AGAINST_YOU_SHORT", inciteSourceName))
            else
                AppendUnitFlagInfo(results, Locale.Lookup("LOC_CAI_UNIT_FLAG_INCITED_AGAINST_YOU_UNKNOWN_SHORT"))
            end
        else
            local inciteSourceID = barbarianManager:GetTribeInciteSourcePlayer(tribeIndex)
            if inciteSourceID == localPlayerID then
                local inciteTargetName = GetBarbarianClanPlayerName(inciteTargetID)
                if inciteTargetName ~= nil and inciteTargetName ~= "" then
                    AppendUnitFlagInfo(results, Locale.Lookup("LOC_CAI_UNIT_FLAG_INCITED_BY_YOU_SHORT", inciteTargetName))
                end
            end
        end
    end

    return #results > 0 and results or nil
end

local function GetUnitFlagPiratesText(unit)
    if unit == nil or not IsPiratesScenarioActive() then
        return nil
    end

    local playerConfig = PlayerConfigurations[unit:GetOwner()]
    if playerConfig == nil or playerConfig:GetCivilizationTypeName() ~= "CIVILIZATION_BARBARIAN" then
        return nil
    end

    return Locale.Lookup("LOC_PIRATES_BUCCANEER_DESCRIPTION")
end

local function GetUnitFlagWaypoint(unit)
    if unit == nil then
        return nil
    end

    local localPlayer = Game.GetLocalPlayer()
    if localPlayer == nil or unit:GetOwner() ~= localPlayer or info.RequestUnitInfo == nil then
        return nil
    end

    local results = info:RequestUnitInfo(unit:GetID(), { "NextWaypoint" }, unit:GetOwner())
    if results ~= nil and #results > 0 then
        return results[1]
    end

    return nil
end

local function IsUnitFlagVisible(flag, unit)
    if flag == nil or unit == nil then
        return false
    end

    if flag.m_eVisibility ~= RevealedState.VISIBLE then
        return false
    end

    if flag.m_IsForceHide then
        return false
    end

    if flag.m_Instance == nil or flag.m_Instance.Anchor == nil or flag.m_Instance.Anchor:IsHidden() then
        return false
    end

    if ShouldHideFlag ~= nil and ShouldHideFlag(unit) then
        return false
    end

    return true
end

local function GetUnitFlagSignature(unit, flag)
    if unit == nil then
        return nil
    end

    local name = FormatUnitFlagDisplayName(unit)
    local queuedMovement = GetUnitFlagWaypoint(unit)
    local health = GetUnitFlagHealth(unit)
    local status = GetUnitFlagStatus(unit)
    local promotionOrLevy = GetUnitFlagPromotionOrLevy(unit)
    local religion = GetUnitFlagReligion(unit, flag)
    local archaeology = GetUnitFlagArchaeology(unit)
    local aircraftCapacity = GetUnitFlagAircraftCapacity(unit, flag)
    local markers = GetUnitFlagMarkers(unit, flag)
    local barbarianClan = GetUnitFlagBarbarianClan(unit)
    local pirates = GetUnitFlagPiratesText(unit)

    local parts = {}
    AppendUnitFlagInfo(parts, name)
    AppendUnitFlagInfo(parts, queuedMovement)
    AppendUnitFlagInfo(parts, health)
    AppendUnitFlagInfo(parts, status)
    AppendUnitFlagInfo(parts, promotionOrLevy)
    AppendUnitFlagInfo(parts, religion)
    AppendUnitFlagInfo(parts, archaeology)
    AppendUnitFlagInfo(parts, aircraftCapacity)
    AppendUnitFlagInfo(parts, markers)
    AppendUnitFlagInfo(parts, barbarianClan)
    AppendUnitFlagInfo(parts, pirates)

    return table.concat(parts, " ")
end

local function GetMatchingVisibleUnitFlagCount(unit)
    if unit == nil then
        return nil
    end

    local plot = Map.GetPlot(unit:GetX(), unit:GetY())
    if plot == nil then
        return nil
    end

    local unitFlag = GetUnitFlag(unit:GetOwner(), unit:GetID())
    local signature = GetUnitFlagSignature(unit, unitFlag)
    if signature == nil or signature == "" then
        return nil
    end

    local matchingCount = 0
    local units = Units.GetUnitsInPlotLayerID(plot:GetX(), plot:GetY(), MapLayers.ANY)
    for _, otherUnit in ipairs(units) do
        local otherFlag = GetUnitFlag(otherUnit:GetOwner(), otherUnit:GetID())
        if IsUnitFlagVisible(otherFlag, otherUnit) and GetUnitFlagSignature(otherUnit, otherFlag) == signature then
            matchingCount = matchingCount + 1
        end
    end

    if matchingCount > 1 then
        return tostring(matchingCount)
    end

    return nil
end

info.UnitFlagInfo = {
    unitCount = function(unit)
        return GetMatchingVisibleUnitFlagCount(unit)
    end,
    owner = function(unit)
        return GetUnitOwnershipPrefix(unit)
    end,
    name = function(unit)
        return FormatUnitFlagDisplayName(unit)
    end,
    formationSuffix = function(unit)
        return GetUnitFormationSuffix(unit)
    end,
    healthPercent = function(unit)
        return GetUnitFlagHealth(unit)
    end,
    queuedMovement = function(unit)
        local player = Game.GetLocalPlayer()
        if player and player == unit:GetOwner() and UnitManager.GetQueuedDestination(unit) then
            return GetUnitFlagWaypoint(unit)
        end
    end,
    status = function(unit)
        return GetUnitFlagStatus(unit)
    end,
    promotionOrLevy = function(unit, flag)
        return GetUnitFlagPromotionOrLevy(unit, flag)
    end,
    religion = function(unit, flag)
        return GetUnitFlagReligion(unit, flag)
    end,
    archaeology = function(unit)
        return GetUnitFlagArchaeology(unit)
    end,
    aircraftCapacity = function(unit, flag)
        return GetUnitFlagAircraftCapacity(unit, flag)
    end,
    markers = function(unit, flag)
        return GetUnitFlagMarkers(unit, flag)
    end,
    barbarianClan = function(unit)
        return GetUnitFlagBarbarianClan(unit)
    end,
    pirates = function(unit)
        return GetUnitFlagPiratesText(unit)
    end,
}

function info:RequestUnitFlagInfo(playerID, unitID, requestedKeys)
    local flag = GetUnitFlag(playerID, unitID)
    if flag == nil then
        return nil
    end

    local unit = flag:GetUnit()
    if unit == nil or not IsUnitFlagVisible(flag, unit) then
        return nil
    end

    local keys = requestedKeys or UNIT_FLAG_INFO_DEFAULT_KEYS
    local results = {}
    for _, key in ipairs(keys) do
        local helper = self.UnitFlagInfo[key]
        if helper ~= nil then
            AppendUnitFlagInfo(results, helper(unit, flag))
        end
    end

    if #results == 0 then
        return nil
    end

    return table.concat(results, " ")
end

local function GetMatchingVisibleDetailedUnitCount(unit)
    local plot = Map.GetPlot(unit:GetX(), unit:GetY())
    local signatureParts = {}
    AppendUnitFlagInfo(signatureParts, GetDefaultUnitFlagDetails(unit))
    local signature = table.concat(signatureParts, ", ")
    local matchingCount = 0

    for _, otherUnit in ipairs(Units.GetUnitsInPlotLayerID(plot:GetX(), plot:GetY(), MapLayers.ANY)) do
        local otherFlag = GetUnitFlag(otherUnit:GetOwner(), otherUnit:GetID())
        local otherParts = {}
        AppendUnitFlagInfo(otherParts, GetDefaultUnitFlagDetails(otherUnit))
        if IsUnitFlagVisible(otherFlag, otherUnit) and table.concat(otherParts, ", ") == signature then
            matchingCount = matchingCount + 1
        end
    end

    return matchingCount > 1 and matchingCount or nil
end

function info:RequestDetailedUnitFlagInfo(playerID, unitID)
    local flag = GetUnitFlag(playerID, unitID)
    local unit = flag ~= nil and flag:GetUnit() or nil
    if unit == nil or not IsUnitFlagVisible(flag, unit) then
        return nil
    end

    local results = {}
    local matchingCount = GetMatchingVisibleDetailedUnitCount(unit)
    AppendUnitFlagInfo(results, GetDefaultUnitFlagDetails(unit, matchingCount))
    return #results > 0 and table.concat(results, ", ") or nil
end

function info:RequestUnitNamesInPlot(x, y)
    local units = Units.GetUnitsInPlotLayerID(x, y, MapLayers.ANY)
    if not units or #units == 0 then return nil end

    local names = {}
    local seen = {}
    for _, pUnit in ipairs(units) do
        local flag = GetUnitFlag(pUnit:GetOwner(), pUnit:GetID())
        if flag and IsUnitFlagVisible(flag, flag:GetUnit()) then
            local unitInfo = GameInfo.Units[pUnit:GetUnitType()]
            if unitInfo then
                local name = Locale.Lookup(unitInfo.Name)
                if name ~= "" and not seen[name] then
                    seen[name] = true
                    names[#names + 1] = name
                end
            end
        end
    end
    return #names > 0 and names or nil
end
