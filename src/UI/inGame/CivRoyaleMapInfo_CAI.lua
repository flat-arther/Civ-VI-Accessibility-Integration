CAICivRoyaleMapInfo = CAICivRoyaleMapInfo or {}

local RULESET = "RULESET_SCENARIO_CIV_ROYALE"
local isActive = GameConfiguration.GetRuleSet() == RULESET

if isActive then
    include("CivRoyaleScenario_PropKeys")
end

local function GetImprovementIndex(typeName)
    local row = GameInfo.Improvements[typeName]
    return row and row.Index or -1
end

local function GetImprovementName(typeName)
    local row = GameInfo.Improvements[typeName]
    return row and Locale.Lookup(row.Name) or nil
end

local function IsFaction(playerID, civType)
    local config = PlayerConfigurations[playerID]
    return config ~= nil and config:GetCivilizationTypeName() == civType
end

local hungerTargetsByPlayer = {}

local function GetHexCoordUtils()
    if CAIHexCoordUtils == nil then
        include("hexCoordUtils_CAI")
    end
    return CAIHexCoordUtils
end

local function GetFalloutDamage()
    local damage = Game.GetFalloutManager():GetFalloutDamageOverride()
    if damage == FalloutDamages.USE_FALLOUT_DEFAULT or damage == nil then
        return 0
    end
    return damage
end

function CAICivRoyaleMapInfo.RefreshHungerTargets(playerID)
    local targets = {}
    hungerTargetsByPlayer[playerID] = targets
    if not isActive or not IsFaction(playerID, g_CivTypeNames.Zombies) then return end
    local visibility = PlayersVisibility[playerID]
    local localPlayer = Players[playerID]
    if visibility == nil or localPlayer == nil then return end

    for _, zombie in localPlayer:GetUnits():Members() do
        local closestUnit = nil
        local closestDistance = 8
        for _, otherPlayer in ipairs(PlayerManager.GetAlive()) do
            if otherPlayer:GetID() ~= playerID then
                for _, unit in otherPlayer:GetUnits():Members() do
                    if not visibility:IsUnitVisible(unit) then
                        local distance = Map.GetPlotDistance(
                            zombie:GetX(), zombie:GetY(), unit:GetX(), unit:GetY())
                        if distance < closestDistance then
                            closestUnit = unit
                            closestDistance = distance
                        end
                    end
                end
            end
        end
        if closestUnit ~= nil then
            targets[Map.GetPlotIndex(closestUnit:GetX(), closestUnit:GetY())] = true
        end
    end
end

local function IsZombieHungerTarget(plot, playerID, refresh)
    if refresh or hungerTargetsByPlayer[playerID] == nil then
        CAICivRoyaleMapInfo.RefreshHungerTargets(playerID)
    end
    return hungerTargetsByPlayer[playerID][plot:GetIndex()] == true
end

function CAICivRoyaleMapInfo.IsActive()
    return isActive
end

function CAICivRoyaleMapInfo.GetSafeZoneCenterPlot()
    if not isActive then return nil end

    local phase = Game:GetProperty(g_ObjectStateKeys.SafeZonePhase) or 0
    local centerX = Game:GetProperty(g_ObjectStateKeys.SafeZoneX)
    local centerY = Game:GetProperty(g_ObjectStateKeys.SafeZoneY)
    if phase <= 0 or centerX == nil or centerY == nil then return nil end

    return Map.GetPlot(centerX, centerY)
end

function CAICivRoyaleMapInfo.GetSafeZoneCenterSpeech(plot)
    if plot == nil then return nil end

    local centerPlot = CAICivRoyaleMapInfo.GetSafeZoneCenterPlot()
    if centerPlot == nil or plot:GetIndex() ~= centerPlot:GetIndex() then
        return nil
    end

    return Locale.Lookup("LOC_CAI_WORLD_SCANNER_CIV_ROYALE_SAFE_ZONE_CENTER")
end

function CAICivRoyaleMapInfo.GetShrinkStatusSpeech()
    if not isActive then return nil end

    local nextSafeZoneTurn = Game:GetProperty(g_ObjectStateKeys.NextSafeZoneTurn)
    if nextSafeZoneTurn == -1 then
        return Locale.Lookup("LOC_CIV_ROYALE_HUD_TURNS_UNTIL_RING_SHRINKS_MIN_SIZE")
    elseif nextSafeZoneTurn ~= nil then
        return Locale.Lookup("LOC_CIV_ROYALE_HUD_TURNS_UNTIL_RING_SHRINKS_B",
            math.max(0, nextSafeZoneTurn - Game.GetCurrentGameTurn()))
    end
    return nil
end

function CAICivRoyaleMapInfo.GetStormStrengthSpeech()
    if not isActive then return nil end

    local phase = Game:GetProperty(g_ObjectStateKeys.SafeZonePhase) or 0
    return Locale.Lookup("LOC_CIV_ROYALE_HUD_STORM_STRENGTH", phase, GetFalloutDamage())
end

function CAICivRoyaleMapInfo.GetZoneState(plot, playerID)
    if not isActive or plot == nil or playerID == nil or playerID < 0 then return nil end

    local state = {
        SafeZone = nil,
        Fallout = nil,
    }

    local phase = Game:GetProperty(g_ObjectStateKeys.SafeZonePhase) or 0
    local centerX = Game:GetProperty(g_ObjectStateKeys.SafeZoneX)
    local centerY = Game:GetProperty(g_ObjectStateKeys.SafeZoneY)
    local radius = Game:GetProperty(g_ObjectStateKeys.CurrentSafeZoneDistance)
    if phase > 0 and centerX ~= nil and centerY ~= nil and radius ~= nil and radius >= 0 then
        local distance = Map.GetPlotDistance(plot:GetX(), plot:GetY(), centerX, centerY)
        state.SafeZone = distance <= radius and "safe" or "outside"
    end

    local falloutManager = Game.GetFalloutManager()
    if falloutManager:HasFallout(plot:GetIndex()) then
        local mutantDropped = plot:GetProperty(g_plotStateKeys.MutantDropped)
        if mutantDropped == nil or mutantDropped < 0 then
            state.Fallout = "redDeath"
        elseif IsFaction(playerID, g_CivTypeNames.Mutants)
            or PlayersVisibility[playerID]:IsVisible(plot:GetIndex()) then
            state.Fallout = "mutant"
        end
    end

    return state
end

function CAICivRoyaleMapInfo.GetZoneSpeech(plot, playerID)
    local state = CAICivRoyaleMapInfo.GetZoneState(plot, playerID)
    if state == nil then return nil end

    if state.Fallout == "redDeath" then
        return Locale.Lookup("LOC_CAI_CIV_ROYALE_RED_DEATH")
    elseif state.SafeZone == "safe" then
        return Locale.Lookup("LOC_CAI_CIV_ROYALE_SAFE_ZONE")
    end

    return Locale.Lookup("LOC_CAI_CIV_ROYALE_OUTSIDE_SAFE_ZONE")
end

function CAICivRoyaleMapInfo.GetZoneDetailSpeech(plot, playerID)
    local state = CAICivRoyaleMapInfo.GetZoneState(plot, playerID)
    if state == nil then return nil end

    if state.Fallout == "redDeath" then
        return Locale.Lookup("LOC_CAI_CIV_ROYALE_RED_DEATH")
            .. ", " .. CAICivRoyaleMapInfo.GetStormStrengthSpeech()
    end

    if state.SafeZone ~= "safe" then
        return Locale.Lookup("LOC_CAI_CIV_ROYALE_OUTSIDE_SAFE_ZONE")
    end

    local parts = { Locale.Lookup("LOC_CAI_CIV_ROYALE_SAFE_ZONE") }
    local centerPlot = CAICivRoyaleMapInfo.GetSafeZoneCenterPlot()
    if centerPlot ~= nil then
        local direction = GetHexCoordUtils().directionString(
            plot:GetX(), plot:GetY(), centerPlot:GetX(), centerPlot:GetY())
        parts[#parts + 1] = Locale.Lookup("LOC_CAI_CIV_ROYALE_SAFE_ZONE_CENTER_DIRECTION", direction)
    end

    local shrinkStatus = CAICivRoyaleMapInfo.GetShrinkStatusSpeech()
    if shrinkStatus ~= nil then
        parts[#parts + 1] = shrinkStatus
    end
    return table.concat(parts, "[NEWLINE]")
end

function CAICivRoyaleMapInfo.GetObjectSpeech(plot, playerID, refreshHunger)
    if not isActive or plot == nil or playerID == nil or playerID < 0 then return nil end

    local parts = {}
    local improvement = plot:GetImprovementType()
    local improvementOwner = plot:GetImprovementOwner()
    local localPlayer = Players[playerID]

    local gift = GetImprovementIndex(EDGELORDS_GRIEVING_GIFT_IMPROVEMENT)
    if improvement == gift and improvementOwner == playerID then
        parts[#parts + 1] = Locale.Lookup("LOC_CAI_CIV_ROYALE_OWN_GRIEVING_GIFT")
    end

    if IsFaction(playerID, g_CivTypeNames.Preppers)
        and improvement == GetImprovementIndex(PREPPER_TRAP_IMPROVEMENT) then
        parts[#parts + 1] = GetImprovementName(PREPPER_TRAP_IMPROVEMENT)
    end

    if localPlayer ~= nil
        and localPlayer:GetProperty(g_playerPropertyKeys.TreasurePlotIndex) == plot:GetIndex() then
        parts[#parts + 1] = Locale.Lookup("LOC_CAI_CIV_ROYALE_PIRATE_TREASURE")
    end

    if plot:GetProperty(g_plotStateKeys.DeferredGiftOwner) == playerID then
        parts[#parts + 1] = Locale.Lookup("LOC_CAI_CIV_ROYALE_INCOMING_GRIEVING_GIFT")
    end

    if IsZombieHungerTarget(plot, playerID, refreshHunger) then
        parts[#parts + 1] = Locale.Lookup("LOC_CAI_CIV_ROYALE_ZOMBIE_HUNGER")
    end

    return #parts > 0 and parts or nil
end
