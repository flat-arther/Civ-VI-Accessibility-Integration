include("caiUtils")
include("hexCoordUtils_CAI")
include("MapTacks")
-- Shared function for overriding the base game's GetCursorPlot functions
local CAICursor = ExposedMembers.CAICursor
local function GetCAICursorPlotId()
    if not CAICursor then return -1 end
    return CAICursor:GetPlotId()
end

local function GetCAICursorPlotCoord()
    local plotId = GetCAICursorPlotId()
    local plot = Map.GetPlotByIndex(plotId)
    if not plot then return -1, -1 end
    return plot:GetX(), plot:GetY()
end

function InstallUIOverrides()
    UI = HijackTable(UI, {
        GetCursorPlotCoord = GetCAICursorPlotCoord,
        GetCursorPlotID = GetCAICursorPlotId,
    })
end

-- Shared in-game CAI formatting and widget helpers used by ResearchChooser_CAI,
-- TechTree_CAI, CivicsChooser_CAI, CivicsTree_CAI, and ProductionPanel_CAI.
--
-- Widget builders take `mgr` as their first arg (the caller's
-- ExposedMembers.CAI_UIManager) so they work in any screen context regardless
-- of which local `mgr` variable is in scope.

-- ===========================================================================
-- Pure string utilities
-- ===========================================================================

function AppendIfNonEmpty(parts, text)
    if text and text ~= "" then table.insert(parts, text) end
end

function NormalizeFormattedText(text)
    text = text or ""
    text = string.gsub(text, "%[NEWLINE%]", ", ")
    text = string.gsub(text, "%s+", " ")
    return text
end

function SplitFormattedLines(text)
    local lines = {}
    text = text or ""
    text = string.gsub(text, "%[NEWLINE%]", "\n")
    for line in string.gmatch(text, "([^\n]+)") do
        local trimmed = string.gsub(line, "^%s*(.-)%s*$", "%1")
        if trimmed ~= "" then
            table.insert(lines, trimmed)
        end
    end
    return lines
end

-- ===========================================================================
-- Advisor / recommendation (shared between ResearchChooser and CivicsChooser)
-- ===========================================================================

local ADVISOR_LOC = {
    ADVISOR_GENERIC    = "LOC_CAI_ADVISOR_GENERIC",
    ADVISOR_CONQUEST   = "LOC_CAI_ADVISOR_CONQUEST",
    ADVISOR_CULTURE    = "LOC_CAI_ADVISOR_CULTURE",
    ADVISOR_RELIGIOUS  = "LOC_CAI_ADVISOR_RELIGIOUS",
    ADVISOR_TECHNOLOGY = "LOC_CAI_ADVISOR_TECHNOLOGY",
}

function GetAdvisorName(advisorType)
    if not advisorType then return nil end
    local tag = ADVISOR_LOC[advisorType]
    if tag then return Locale.Lookup(tag) end
    return nil
end

function GetRecommendedPart(kData, isDisabled)
    if not kData or not kData.IsRecommended then return nil end
    if isDisabled then return nil end
    local advisor = GetAdvisorName(kData.AdvisorType)
    if advisor then
        return Locale.Lookup("LOC_CAI_RESEARCH_RECOMMENDED_BY", advisor)
    end
    return Locale.Lookup("LOC_CAI_RESEARCH_RECOMMENDED")
end

-- ===========================================================================
-- Domain queries
-- ===========================================================================

local function GetCivicUnlockables(kData)
    local civicType = kData and (kData.CivicType or kData.Type)
    if not civicType then return {} end
    local playerID = Game.GetLocalPlayer()
    return GetUnlockablesForCivic_Cached(civicType, playerID) or {}
end

function GetObsoletePolicyNames(kData)
    local unlockables = GetCivicUnlockables(kData)
    local unlockableIndex = {}
    for _, v in ipairs(unlockables) do
        unlockableIndex[v[1]] = true
    end

    local obsoleteNames = {}
    for row in GameInfo.ObsoletePolicies() do
        if unlockableIndex[row.ObsoletePolicy] then
            local policy = GameInfo.Policies[row.PolicyType]
            if policy then
                table.insert(obsoleteNames, Locale.Lookup("LOC_TOOLTIP_UNLOCKS_POLICY", policy.Name))
            end
        end
    end
    table.sort(obsoleteNames, function(a, b) return Locale.Compare(a, b) == -1 end)
    return obsoleteNames
end

-- ===========================================================================
-- Unlock objects (shared by choosers + trees)
-- Each unlock is { TypeName, Name, Description } where Description is the
-- localized prose from the matching GameInfo row, or nil if none exists.
-- ===========================================================================

UNLOCK_DESC_TABLES = {
    "Buildings", "Units", "Improvements", "Districts", "Projects",
    "Resources", "Routes", "Policies", "Civics", "Technologies", "Governments",
}

function GetUnlockDescription(typeName)
    if not typeName or typeName == "" then return nil end
    for _, tableName in ipairs(UNLOCK_DESC_TABLES) do
        local info = GameInfo[tableName]
        local row = info and info[typeName] or nil
        local desc = row and row.Description or nil
        if desc and desc ~= "" then
            local text = Locale.Lookup(desc)
            if text and text ~= "" then return text end
        end
    end
    return nil
end

function GetCivicUnlockObjects(kData)
    local unlocks = {}
    for _, u in ipairs(GetCivicUnlockables(kData)) do
        local typeName, locName = u[1], u[2]
        if locName and locName ~= "" then
            table.insert(unlocks, {
                TypeName = typeName,
                Name = Locale.Lookup(locName),
                Description = GetUnlockDescription(typeName),
            })
        end
    end
    return unlocks
end

-- Tech unlocks split revealed resources off from regular unlocks so the
-- tooltip can render `Reveals: ...` separately from `Unlocks: ...`.
function GetTechUnlockObjects(kData)
    local techType = kData and (kData.TechType or kData.Type)
    if not techType then return { Unlocks = {}, Reveals = {} } end
    local playerID = Game.GetLocalPlayer()
    local raw = GetUnlockablesForTech_Cached(techType, playerID) or {}
    local unlocks, reveals = {}, {}
    for _, u in ipairs(raw) do
        local typeName, locName = u[1], u[2]
        if locName and locName ~= "" then
            local t = GameInfo.Types[typeName]
            local kind = t and t.Kind or nil
            if kind == "KIND_RESOURCE" then
                table.insert(reveals, {
                    TypeName = typeName,
                    Name = Locale.Lookup(locName),
                })
            else
                table.insert(unlocks, {
                    TypeName = typeName,
                    Name = Locale.Lookup(locName),
                    Description = GetUnlockDescription(typeName),
                })
            end
        end
    end
    return { Unlocks = unlocks, Reveals = reveals }
end

-- ===========================================================================
-- Awards (XP1/XP2 extra civic/tech rewards: Envoys, Governor title, Favor).
-- Mirrors vanilla's g_ExtraIconData lookup. Returns an array of localized
-- strings ready to splice into the row tooltip after the Unlocks header.
-- ===========================================================================

local AWARD_LOC_TAGS = {
    MODIFIER_PLAYER_GRANT_INFLUENCE_TOKEN = "LOC_CIVIC_ENVOY_AWARDED_TOOLTIP",
    MODIFIER_PLAYER_ADJUST_GOVERNOR_POINTS = "LOC_HUD_CIVICS_TREE_AWARD_GOVERNOR",
    MODIFIER_PLAYER_ADD_FAVOR = "LOC_HUD_CIVICS_TREE_AWARD_FAVOR",
}

local AWARD_MODIFIER_ID_LOC_TAGS = {
    CIVIC_AWARD_ONE_SETTLER = "LOC_CIVIC_SCENARIO_CROWN_COLONY_DESCRIPTION",
    CIVIC_AWARD_TWO_SETTLERS = "LOC_CIVIC_SCENARIO_GOLD_RUSH_DESCRIPTION",
}

function GetAwardNames(modifierList)
    local names = {}
    if not modifierList then return names end
    -- g_ExtraIconData is a screen-level global declared by CivicsTree.lua /
    -- CivicsChooser.lua includes; reading an undeclared global is nil in Lua,
    -- so no rawget guard is needed (and the sandbox doesn't expose rawget).
    local extra = g_ExtraIconData
    for _, m in ipairs(modifierList) do
        local tag = AWARD_LOC_TAGS[m.ModifierType]
        local modifierIdTag = AWARD_MODIFIER_ID_LOC_TAGS[m.ModifierId]
        local hasIconData = extra and extra[m.ModifierType] ~= nil
        if modifierIdTag and hasIconData then
            table.insert(names, Locale.Lookup(modifierIdTag))
        elseif tag and hasIconData then
            local num = tonumber(m.ModifierValue)
            if num then
                table.insert(names, Locale.Lookup(tag, num))
            else
                table.insert(names, Locale.Lookup(tag))
            end
        end
    end
    return names
end

function GetCivicAwardsText(awardNames)
    if not awardNames or #awardNames == 0 then return nil end
    return Locale.Lookup("LOC_CAI_CIVIC_AWARDS_HEADER", table.concat(awardNames, ", "))
end

function GetTechAwardsText(awardNames)
    if not awardNames or #awardNames == 0 then return nil end
    return Locale.Lookup("LOC_CAI_TECH_AWARDS_HEADER", table.concat(awardNames, ", "))
end

-- Shared TreeItem for one unlock entry (label = unlock name, tooltip =
-- description, Shift+Enter opens Civilopedia for the underlying type).
function CreateUnlockChild(mgr, unlock, idPrefix)
    local prefix = idPrefix or "CAIUnlock"
    local child = mgr:CreateWidget(mgr:GenerateWidgetId(prefix), "TreeItem", {
        Label    = function() return unlock.Name end,
        Tooltip  = function() return unlock.Description or "" end,
        FocusKey = "unlock:" .. tostring(unlock.TypeName),
    })
    child:AddInputBindings({
        {
            Key     = Keys.VK_RETURN,
            IsShift = true,
            MSG     = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_OPEN_CIVILOPEDIA",
            Action  = function()
                if IsTutorialRunning and IsTutorialRunning() then return true end
                if unlock.TypeName then LuaEvents.OpenCivilopedia(unlock.TypeName) end
                return true
            end,
        },
    })
    return child
end

--#Map tac helpers
local CAI_MAP_TAC_STOCK_ICON_LABELS = {
    ICON_MAP_PIN_STRENGTH = "LOC_CAI_MAP_PIN_ICON_STRENGTH",
    ICON_MAP_PIN_RANGED   = "LOC_CAI_MAP_PIN_ICON_RANGED",
    ICON_MAP_PIN_BOMBARD  = "LOC_CAI_MAP_PIN_ICON_BOMBARD",
    ICON_MAP_PIN_DISTRICT = "LOC_CAI_MAP_PIN_ICON_DISTRICT",
    ICON_MAP_PIN_CHARGES  = "LOC_CAI_MAP_PIN_ICON_CHARGES",
    ICON_MAP_PIN_DEFENSE  = "LOC_CAI_MAP_PIN_ICON_DEFENSE",
    ICON_MAP_PIN_MOVEMENT = "LOC_CAI_MAP_PIN_ICON_MOVEMENT",
    ICON_MAP_PIN_NO       = "LOC_CAI_MAP_PIN_ICON_NO",
    ICON_MAP_PIN_PLUS     = "LOC_CAI_MAP_PIN_ICON_PLUS",
    ICON_MAP_PIN_CIRCLE   = "LOC_CAI_MAP_PIN_ICON_CIRCLE",
    ICON_MAP_PIN_TRIANGLE = "LOC_CAI_MAP_PIN_ICON_TRIANGLE",
    ICON_MAP_PIN_SUN      = "LOC_CAI_MAP_PIN_ICON_SUN",
    ICON_MAP_PIN_SQUARE   = "LOC_CAI_MAP_PIN_ICON_SQUARE",
    ICON_MAP_PIN_DIAMOND  = "LOC_CAI_MAP_PIN_ICON_DIAMOND",
}

local function ResolveMapTacGameInfoName(typeKey)
    if not typeKey then return nil end

    local info
    if typeKey:find("^DISTRICT_") then
        info = GameInfo.Districts[typeKey]
    elseif typeKey:find("^BUILDING_") then
        info = GameInfo.Buildings[typeKey]
    elseif typeKey:find("^IMPROVEMENT_") then
        info = GameInfo.Improvements[typeKey]
    elseif typeKey:find("^UNIT_") then
        info = GameInfo.Units[typeKey]
    end

    if info and info.Name then
        return Locale.Lookup(info.Name)
    end
    return nil
end

---@param iconName string|nil
---@return string|nil
function GetMapTacIconLabel(iconName)
    if iconName == nil or iconName == "" then
        return nil
    end

    local playerID = Game.GetLocalPlayer()
    local sections = MapTacks.IconOptions(playerID)
    for _, section in ipairs(sections) do
        for _, pair in ipairs(section) do
            if pair.name == iconName then
                if pair.tooltip then
                    local locText = Locale.Lookup(pair.tooltip)
                    if locText and locText ~= "" and locText ~= pair.tooltip then return locText end
                    local infoName = ResolveMapTacGameInfoName(pair.tooltip)
                    if infoName then return infoName end
                end
            end
        end
    end

    local stockKey = CAI_MAP_TAC_STOCK_ICON_LABELS[iconName]
    if stockKey then return Locale.Lookup(stockKey) end
    return iconName
end

---@param mapPinCfg table|nil
---@return string|nil
function GetMapTacName(mapPinCfg)
    if mapPinCfg == nil then
        return nil
    end

    local pinName = mapPinCfg:GetName()
    if pinName ~= nil and pinName ~= "" then
        return pinName
    end

    local pinID = mapPinCfg:GetID()
    return Locale.Lookup("LOC_MAP_PIN_DEFAULT_NAME", pinID + 1)
end

---@param mapPinCfg table|nil
---@return string|nil
function BuildMapTacLabel(mapPinCfg)
    if mapPinCfg == nil then
        return nil
    end

    local parts = {}
    AppendIfNonEmpty(parts, GetMapTacName(mapPinCfg))
    AppendIfNonEmpty(parts, GetMapTacIconLabel(mapPinCfg:GetIconName()))
    return #parts > 0 and table.concat(parts, ", ") or nil
end

---@param playerID number|nil
---@return string|nil
function GetMapTacOwnerLabel(playerID)
    if playerID == nil or playerID == -1 then
        return nil
    end

    local playerConfig = PlayerConfigurations[playerID]
    if playerConfig == nil then
        return Locale.Lookup("LOC_TOOLTIP_PLAYER_ID", playerID)
    end

    local civName = playerConfig:GetCivilizationDescription()
    if civName ~= nil and civName ~= "" then
        return Locale.Lookup(civName)
    end

    local leaderName = playerConfig:GetLeaderName()
    if leaderName ~= nil and leaderName ~= "" then
        return Locale.Lookup(leaderName)
    end

    return Locale.Lookup("LOC_TOOLTIP_PLAYER_ID", playerID)
end

---@param mapPinCfg table|nil
---@param playerID number|nil
---@param localPlayerID number|nil
---@return string|nil
function BuildMapTacLabelWithOwner(mapPinCfg, playerID, localPlayerID)
    local label = BuildMapTacLabel(mapPinCfg)
    if label == nil or label == "" or playerID == localPlayerID then
        return label
    end

    local ownerLabel = GetMapTacOwnerLabel(playerID)
    if ownerLabel == nil or ownerLabel == "" then
        return label
    end

    return label .. ", " .. ownerLabel
end

---@param plot table|nil
---@return table
function GetVisibleMapTacsAtPlot(plot)
    local results = {}
    if plot == nil then
        return results
    end

    local localPlayerID = Game.GetLocalPlayer()
    local x = plot:GetX()
    local y = plot:GetY()

    for iPlayer = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
        local playerConfig = PlayerConfigurations[iPlayer]
        local playerPins = playerConfig ~= nil and playerConfig:GetMapPins() or nil
        if playerPins ~= nil then
            for _, mapPinCfg in pairs(playerPins) do
                if mapPinCfg ~= nil
                    and mapPinCfg:GetHexX() == x
                    and mapPinCfg:GetHexY() == y
                    and mapPinCfg:IsVisible(localPlayerID) then
                    table.insert(results, {
                        PlayerID = iPlayer,
                        PinID = mapPinCfg:GetID(),
                        Config = mapPinCfg,
                        Label = BuildMapTacLabel(mapPinCfg),
                        LabelWithOwner = BuildMapTacLabelWithOwner(mapPinCfg, iPlayer, localPlayerID),
                    })
                end
            end
        end
    end

    return results
end

--#Unit info helpers
---@param unit Unit|nil
---@return Unit[]
function GetFormationUnitsOnPlot(unit)
    if unit == nil or unit:GetFormationUnitCount() <= 1 then
        return {}
    end

    local formationID = unit:GetFormationID()
    local units = Units.GetUnitsInPlotLayerID(unit:GetX(), unit:GetY(), MapLayers.ANY)
    local formationUnits = {}
    for _, plotUnit in ipairs(units or {}) do
        if plotUnit:GetFormationID() == formationID then
            formationUnits[#formationUnits + 1] = plotUnit
        end
    end

    return formationUnits
end

---Returns the player's localized civilization ownership prefix.
---Prefers the adjective and falls back to the short name when its localization is missing.
---@param playerID number|nil
---@return string|nil
function GetPlayerOwnershipPrefix(playerID)
    if playerID == nil or playerID == -1 then
        return nil
    end

    local playerConfig = PlayerConfigurations[playerID]
    if playerConfig ~= nil then
        local civInfo = GameInfo.Civilizations[playerConfig:GetCivilizationTypeID()]
        if civInfo ~= nil and civInfo.Adjective ~= nil and civInfo.Adjective ~= "" then
            local adjective = Locale.Lookup(civInfo.Adjective)
            if adjective ~= civInfo.Adjective then
                return adjective
            end
        end

        local shortDescription = playerConfig:GetCivilizationShortDescription()
        if shortDescription ~= nil and shortDescription ~= "" then
            local civilizationName = Locale.Lookup(shortDescription)
            if civilizationName ~= shortDescription then
                return civilizationName
            end
        end
    end

    return Locale.Lookup("LOC_TOOLTIP_PLAYER_ID", playerID)
end

---Returns the unit owner's localized civilization ownership prefix.
---@param unit Unit
---@return string|nil
function GetUnitOwnershipPrefix(unit)
    if unit == nil then
        return nil
    end

    return GetPlayerOwnershipPrefix(unit:GetOwner())
end

local function GetUnitFormationSuffixFromDomainAndFormation(domain, formation)
    if formation == MilitaryFormationTypes.CORPS_FORMATION then
        if domain == "DOMAIN_SEA" then
            return Locale.Lookup("LOC_UNITFLAG_FLEET_SUFFIX")
        end
        return Locale.Lookup("LOC_UNITFLAG_CORPS_SUFFIX")
    end

    if formation == MilitaryFormationTypes.ARMY_FORMATION then
        if domain == "DOMAIN_SEA" then
            return Locale.Lookup("LOC_UNITFLAG_ARMADA_SUFFIX")
        end
        return Locale.Lookup("LOC_UNITFLAG_ARMY_SUFFIX")
    end

    return nil
end

---@param data table|nil
---@return string|nil
function GetUnitDataFormationSuffix(data)
    if data == nil or data.UnitType == nil or data.UnitType == -1 then
        return nil
    end

    local unitInfo = GameInfo.Units[data.UnitType]
    if unitInfo == nil then
        return nil
    end

    return GetUnitFormationSuffixFromDomainAndFormation(unitInfo.Domain, data.MilitaryFormation)
end

---@param unit Unit|nil
---@return string|nil
function GetUnitFormationSuffix(unit)
    if unit == nil then
        return nil
    end

    local unitInfo = GameInfo.Units[unit:GetUnitType()]
    if unitInfo == nil then
        return nil
    end

    return GetUnitFormationSuffixFromDomainAndFormation(unitInfo.Domain, unit:GetMilitaryFormation())
end

---@param ownerPrefix string|nil
---@param name string|nil
---@param suffix string|nil
---@return string|nil
function FormatOwnedName(ownerPrefix, name, suffix)
    if name == nil or name == "" then
        return nil
    end

    local formatted = Locale.Lookup("LOC_CAI_UNIT_FLAG_NAME_PATTERN", ownerPrefix or "", name, suffix or "")
    local normalized = NormalizeFormattedText(formatted)
    normalized = string.gsub(normalized, "^%s*(.-)%s*$", "%1")
    if normalized == "" then
        return nil
    end

    return normalized
end

---Formats a unit display name as owner adjective + localized unit name + optional formation suffix.
---Uses a CAI localization pattern so translators can reorder the pieces by language.
---@param unit Unit
---@param formationSuffix string|nil
---@return string|nil
function FormatOwnedUnitDisplayName(unit, formationSuffix)
    if unit == nil then
        return nil
    end

    local owner = GetUnitOwnershipPrefix(unit)
    local unitName = unit:GetName()
    local name = unitName ~= nil and unitName ~= "" and Locale.Lookup(unitName) or nil
    if name == nil or name == "" then
        local unitInfo = GameInfo.Units[unit:GetUnitType()]
        if unitInfo ~= nil and unitInfo.Name ~= nil and unitInfo.Name ~= "" then
            name = Locale.Lookup(unitInfo.Name)
        end
    end

    return FormatOwnedName(owner, name, formationSuffix or GetUnitFormationSuffix(unit))
end

---@param playerID number|nil
---@param cityName string|nil
---@return string|nil
function FormatOwnedCityDisplayName(playerID, cityName)
    local localizedName = cityName ~= nil and cityName ~= "" and Locale.Lookup(cityName) or nil
    return FormatOwnedName(GetPlayerOwnershipPrefix(playerID), localizedName)
end

---@param unit Unit|nil
---@return table|nil
function GetHostedAircraftData(unit)
    if unit == nil or unit.GetAirSlots == nil then
        return nil
    end

    local maxSlots = unit:GetAirSlots() or 0
    if maxSlots <= 0 then
        return nil
    end

    local airUnits = {}
    if unit.GetAirUnits ~= nil then
        local hasAirUnits, hostedUnits = unit:GetAirUnits()
        if hasAirUnits and hostedUnits ~= nil then
            for _, hostedUnit in ipairs(hostedUnits) do
                table.insert(airUnits, hostedUnit)
            end
        end
    end

    return {
        CurrentCount = #airUnits,
        MaxSlots = maxSlots,
        AirUnits = airUnits,
    }
end

---@param unit Unit|nil
---@return string|nil
function GetHostedAircraftCapacityText(unit)
    local aircraftData = GetHostedAircraftData(unit)
    if aircraftData == nil then
        return nil
    end

    return Locale.Lookup("LOC_CAI_UNIT_FLAG_AIRCRAFT_SHORT", aircraftData.CurrentCount, aircraftData.MaxSlots)
end

---@param unit Unit|nil
---@return string[]|nil
function GetHostedAircraftUnitNames(unit)
    local aircraftData = GetHostedAircraftData(unit)
    if aircraftData == nil or aircraftData.AirUnits == nil or #aircraftData.AirUnits == 0 then
        return nil
    end

    local names = {}
    for _, hostedUnit in ipairs(aircraftData.AirUnits) do
        local name = FormatOwnedUnitDisplayName(hostedUnit)
        if name ~= nil and name ~= "" then
            table.insert(names, name)
        end
    end

    if #names == 0 then
        return nil
    end

    return names
end
