include("inGameHelpers_CAI")
include("UnitFlagManager")

local info = ExposedMembers.CAIInfo or {}
ExposedMembers.CAIInfo = info

local UNIT_FLAG_INFO_DEFAULT_KEYS = {
    "unitCount",
    "name",
    "queuedMovement",
    "healthPercent",
    "status",
}

local function AppendUnitFlagInfo(parts, value)
    if value ~= nil and value ~= "" then
        table.insert(parts, value)
    end
end

local function FormatUnitFlagDisplayName(unit)
    if unit == nil then
        return nil
    end

    return FormatOwnedUnitDisplayName(unit)
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

local function GetUnitFlagSignature(unit)
    if unit == nil then
        return nil
    end

    local name = FormatUnitFlagDisplayName(unit)
    local queuedMovement = GetUnitFlagWaypoint(unit)
    local health = GetUnitFlagHealth(unit)
    local status = GetUnitFlagStatus(unit)

    local parts = {}
    AppendUnitFlagInfo(parts, name)
    AppendUnitFlagInfo(parts, queuedMovement)
    AppendUnitFlagInfo(parts, health)
    AppendUnitFlagInfo(parts, status)

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

    local signature = GetUnitFlagSignature(unit)
    if signature == nil or signature == "" then
        return nil
    end

    local matchingCount = 0
    local units = Units.GetUnitsInPlotLayerID(plot:GetX(), plot:GetY(), MapLayers.ANY)
    for _, otherUnit in ipairs(units) do
        local otherFlag = GetUnitFlag(otherUnit:GetOwner(), otherUnit:GetID())
        if IsUnitFlagVisible(otherFlag, otherUnit) and GetUnitFlagSignature(otherUnit) == signature then
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
        return GetUnitFlagWaypoint(unit)
    end,
    status = function(unit)
        return GetUnitFlagStatus(unit)
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
