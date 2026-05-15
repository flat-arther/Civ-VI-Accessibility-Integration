include("inGameHelpers_CAI")

local Utils = CAIWorldScannerUtils

local CATEGORY_IDS = {
    My = "myUnits",
    Neutral = "neutralUnits",
    Enemy = "enemyUnits",
}

local SUBCATEGORY_IDS = {
    Civilian = "civilian",
    Religious = "religious",
    Melee = "melee",
    Ranged = "ranged",
    Siege = "siege",
    Naval = "naval",
    Air = "air",
    Support = "support",
    Barbarians = "barbarians",
}

local subCategoryLabels = {
    [SUBCATEGORY_IDS.Civilian] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_CIVILIAN",
    [SUBCATEGORY_IDS.Religious] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_RELIGIOUS",
    [SUBCATEGORY_IDS.Melee] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_MELEE",
    [SUBCATEGORY_IDS.Ranged] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_RANGED",
    [SUBCATEGORY_IDS.Siege] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_SIEGE",
    [SUBCATEGORY_IDS.Naval] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_NAVAL",
    [SUBCATEGORY_IDS.Air] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_AIR",
    [SUBCATEGORY_IDS.Support] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_SUPPORT",
    [SUBCATEGORY_IDS.Barbarians] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_BARBARIANS",
}

local subCategoryOrder = {
    SUBCATEGORY_IDS.Civilian,
    SUBCATEGORY_IDS.Religious,
    SUBCATEGORY_IDS.Melee,
    SUBCATEGORY_IDS.Ranged,
    SUBCATEGORY_IDS.Siege,
    SUBCATEGORY_IDS.Naval,
    SUBCATEGORY_IDS.Air,
    SUBCATEGORY_IDS.Support,
    SUBCATEGORY_IDS.Barbarians,
}

local function CreateUnitsCategory(id, labelKey)
    return {
        Id = id,
        LabelKey = labelKey,
        SubCategoryOrder = subCategoryOrder,
        SubCategoryLabels = subCategoryLabels,
        GroupLabelResolver = function(_, firstItem)
            return firstItem ~= nil and firstItem.GroupLabelKey or "LOC_CAI_WORLD_SCANNER_UNKNOWN"
        end,
    }
end

CAIWorldScannerCategory_MyUnits = CreateUnitsCategory(CATEGORY_IDS.My, "LOC_CAI_WORLD_SCANNER_CATEGORY_MY_UNITS")
CAIWorldScannerCategory_NeutralUnits = CreateUnitsCategory(CATEGORY_IDS.Neutral, "LOC_CAI_WORLD_SCANNER_CATEGORY_NEUTRAL_UNITS")
CAIWorldScannerCategory_EnemyUnits = CreateUnitsCategory(CATEGORY_IDS.Enemy, "LOC_CAI_WORLD_SCANNER_CATEGORY_ENEMY_UNITS")

local function GetUnitScannerFormationSuffix(unit)
    if unit == nil then
        return nil
    end

    local unitInfo = GameInfo.Units[unit:GetUnitType()]
    if unitInfo == nil then
        return nil
    end

    local formation = unit:GetMilitaryFormation()
    if formation == MilitaryFormationTypes.CORPS_FORMATION then
        if unitInfo.Domain == "DOMAIN_SEA" then
            return Locale.Lookup("LOC_UNITFLAG_FLEET_SUFFIX")
        end
        return Locale.Lookup("LOC_UNITFLAG_CORPS_SUFFIX")
    elseif formation == MilitaryFormationTypes.ARMY_FORMATION then
        if unitInfo.Domain == "DOMAIN_SEA" then
            return Locale.Lookup("LOC_UNITFLAG_ARMADA_SUFFIX")
        end
        return Locale.Lookup("LOC_UNITFLAG_ARMY_SUFFIX")
    end

    return nil
end

local function IsReligiousCivilian(unitInfo)
    if unitInfo == nil then
        return false
    end

    local function IsGameplayBooleanTrue(value)
        return value == true or value == 1
    end

    local function IsPositiveGameplayNumber(value)
        return type(value) == "number" and value > 0
    end

    return IsGameplayBooleanTrue(unitInfo.TrackReligion)
        or IsGameplayBooleanTrue(unitInfo.FoundReligion)
        or IsPositiveGameplayNumber(unitInfo.ReligiousStrength)
        or IsPositiveGameplayNumber(unitInfo.SpreadCharges)
        or IsPositiveGameplayNumber(unitInfo.ReligiousHealCharges)
        or IsGameplayBooleanTrue(unitInfo.EnabledByReligion)
end

local function GetUnitCategoryId(context, ownerID)
    local localPlayerID = Utils.GetLocalPlayerID(context)
    if ownerID == nil or ownerID == -1 then
        return CATEGORY_IDS.Neutral
    end

    if ownerID == localPlayerID then
        return CATEGORY_IDS.My
    end

    local player = Players[ownerID]
    if player == nil then
        return CATEGORY_IDS.Neutral
    end

    if player:IsBarbarian() then
        return CATEGORY_IDS.Enemy
    end

    local teamID = player.GetTeam and player:GetTeam() or -1
    if teamID ~= -1 and teamID == Utils.GetLocalTeamID(context) then
        return CATEGORY_IDS.My
    end

    local diplomacy = Utils.GetDiplomacy(context)
    if diplomacy ~= nil and diplomacy:IsAtWarWith(ownerID) then
        return CATEGORY_IDS.Enemy
    end

    return CATEGORY_IDS.Neutral
end

local function GetUnitSubCategoryId(player, unitInfo)
    if player ~= nil and player:IsBarbarian() then
        return SUBCATEGORY_IDS.Barbarians
    end

    if IsReligiousCivilian(unitInfo) then
        return SUBCATEGORY_IDS.Religious
    end

    if unitInfo ~= nil and unitInfo.FormationClass == "FORMATION_CLASS_CIVILIAN" then
        return SUBCATEGORY_IDS.Civilian
    end

    if unitInfo ~= nil and unitInfo.FormationClass == "FORMATION_CLASS_SUPPORT" then
        return SUBCATEGORY_IDS.Support
    end

    if unitInfo ~= nil and (unitInfo.FormationClass == "FORMATION_CLASS_AIR" or unitInfo.Domain == "DOMAIN_AIR") then
        return SUBCATEGORY_IDS.Air
    end

    if unitInfo ~= nil and unitInfo.Domain == "DOMAIN_SEA" then
        return SUBCATEGORY_IDS.Naval
    end

    if unitInfo ~= nil and unitInfo.Bombard ~= nil then
        return SUBCATEGORY_IDS.Siege
    end

    if unitInfo ~= nil and unitInfo.RangedCombat ~= nil then
        return SUBCATEGORY_IDS.Ranged
    end

    return SUBCATEGORY_IDS.Melee
end

local function BuildUnitScannerItems(context)
    if context ~= nil and context.UnitScannerItems ~= nil then
        return context.UnitScannerItems
    end

    local out = {}
    local seen = {}
    local visibility = Utils.GetVisibility(context)
    local localPlayerID = Utils.GetLocalPlayerID(context)

    local scanPlayers = {}
    local seenPlayers = {}

    local function AddScanPlayer(player)
        if player == nil or not player:IsAlive() then
            return
        end

        local playerID = player:GetID()
        if playerID == nil or seenPlayers[playerID] then
            return
        end

        seenPlayers[playerID] = true
        scanPlayers[#scanPlayers + 1] = player
    end

    for _, player in ipairs(PlayerManager.GetAlive() or {}) do
        AddScanPlayer(player)
    end

    for _, player in ipairs(Players) do
        if player ~= nil and player:IsBarbarian() then
            AddScanPlayer(player)
        end
    end

    for _, player in ipairs(scanPlayers) do
        local units = player:GetUnits()
        if units ~= nil then
            for _, unit in units:Members() do
                local ownerID = unit:GetOwner()
                local unitID = unit:GetID()
                local uniqueKey = tostring(ownerID) .. ":" .. tostring(unitID)
                if not seen[uniqueKey] then
                    local plotIndex = unit:GetPlotId()
                    local plot = plotIndex ~= nil and plotIndex >= 0 and Map.GetPlotByIndex(plotIndex) or nil
                    local isLocal = ownerID == localPlayerID
                    local isVisible = isLocal or (visibility ~= nil and visibility:IsUnitVisible(unit))
                    if plot ~= nil
                        and Utils.IsPlotRevealed(context, plot)
                        and isVisible
                        and (player:IsBarbarian() or Utils.CanKnowPlayer(context, ownerID)) then
                        seen[uniqueKey] = true
                        local unitType = unit:GetUnitType()
                        local unitInfo = GameInfo.Units[unitType]
                        if unitInfo ~= nil then
                            local unitLabel = FormatOwnedUnitDisplayName(unit, GetUnitScannerFormationSuffix(unit)) or unitInfo.Name
                            local categoryId = GetUnitCategoryId(context, ownerID)
                            local subCategoryId = GetUnitSubCategoryId(player, unitInfo)
                            out[#out + 1] = {
                                Id = "unit:" .. uniqueKey,
                                PlotIndex = plotIndex,
                                LabelKey = unitLabel,
                                CategoryId = categoryId,
                                SubCategoryId = subCategoryId,
                                GroupId = tostring(unitInfo.UnitType),
                                GroupLabelKey = unitInfo.Name,
                                Validate = function(item, validateContext)
                                    local validatePlayer = ownerID ~= nil and Players[ownerID] or nil
                                    if validatePlayer == nil or not validatePlayer:IsAlive() then
                                        return false
                                    end

                                    local validateUnits = validatePlayer:GetUnits()
                                    local validateUnit = validateUnits ~= nil and validateUnits:FindID(unitID) or nil
                                    if validateUnit == nil then
                                        return false
                                    end

                                    local validatePlot = Map.GetPlotByIndex(validateUnit:GetPlotId())
                                    if validatePlot == nil or not Utils.IsPlotRevealed(validateContext, validatePlot) then
                                        return false
                                    end

                                    local validateVisibility = Utils.GetVisibility(validateContext)
                                    local validateVisible = ownerID == Utils.GetLocalPlayerID(validateContext)
                                        or (validateVisibility ~= nil and validateVisibility:IsUnitVisible(validateUnit))
                                    local validateUnitInfo = GameInfo.Units[validateUnit:GetUnitType()]
                                    return validateVisible
                                        and (validatePlayer:IsBarbarian() or Utils.CanKnowPlayer(validateContext, ownerID))
                                        and GetUnitCategoryId(validateContext, ownerID) == item.CategoryId
                                        and GetUnitSubCategoryId(validatePlayer, validateUnitInfo) == item.SubCategoryId
                                        and validateUnit:GetUnitType() == unitType
                                end,
                            }
                        end
                    end
                end
            end
        end
    end

    if context ~= nil then
        context.UnitScannerItems = out
    end

    return out
end

local function FilterItemsForCategory(context, categoryId)
    local filtered = {}
    local items = BuildUnitScannerItems(context)
    for _, item in ipairs(items) do
        if item.CategoryId == categoryId then
            filtered[#filtered + 1] = item
        end
    end

    return filtered
end

function CAIWorldScannerCategory_MyUnits.Scan(context)
    return FilterItemsForCategory(context, CATEGORY_IDS.My)
end

function CAIWorldScannerCategory_NeutralUnits.Scan(context)
    return FilterItemsForCategory(context, CATEGORY_IDS.Neutral)
end

function CAIWorldScannerCategory_EnemyUnits.Scan(context)
    return FilterItemsForCategory(context, CATEGORY_IDS.Enemy)
end

CAIWorldScanner:RegisterCategoryDefinition(CAIWorldScannerCategory_MyUnits)
CAIWorldScanner:RegisterCategoryDefinition(CAIWorldScannerCategory_NeutralUnits)
CAIWorldScanner:RegisterCategoryDefinition(CAIWorldScannerCategory_EnemyUnits)
