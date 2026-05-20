include("caiUtils")
include("hexCoordUtils_CAI")
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

function StartsWithIconBullet(text)
    return text and string.find(text, "^%s*%[ICON_Bullet%]") ~= nil
end

function IsUnlocksHeader(text)
    if not text or text == "" then return false end
    local label = Locale.Lookup("LOC_TOOLTIP_UNLOCKS")
    return label and label ~= "" and string.find(text, label, 1, true) ~= nil
end

function IsMakesObsoleteHeader(text)
    if not text or text == "" then return false end
    local label = Locale.Lookup("LOC_TOOLTIP_MAKES_OBSOLETE")
    return label and label ~= "" and string.find(text, label, 1, true) ~= nil
end

-- Tech/research tooltips: drop the Unlocks header and its bullet rows so the
-- expandable unlocks node doesn't duplicate them.
function SplitTooltipLinesWithoutUnlocks(text)
    local lines = {}
    local skippingUnlocks = false
    for _, line in ipairs(SplitFormattedLines(text)) do
        if IsUnlocksHeader(line) then
            skippingUnlocks = true
        elseif skippingUnlocks and StartsWithIconBullet(line) then
            -- handled by AddTechUnlocksNode
        else
            skippingUnlocks = false
            table.insert(lines, line)
        end
    end
    return lines
end

-- Civic tooltips: drop both the Unlocks and Makes Obsolete headers and their
-- bullet rows so the expandable unlocks/obsolete nodes don't duplicate them.
function SplitTooltipLinesWithoutSpecialLists(text)
    local lines = {}
    local skippingList = false
    for _, line in ipairs(SplitFormattedLines(text)) do
        if IsUnlocksHeader(line) or IsMakesObsoleteHeader(line) then
            skippingList = true
        elseif skippingList and StartsWithIconBullet(line) then
            -- handled by AddCivicUnlocksNode / AddMakesObsoleteNode
        else
            skippingList = false
            table.insert(lines, line)
        end
    end
    return lines
end

-- ===========================================================================
-- Domain queries
-- ===========================================================================

function GetTechUnlockNames(kData)
    local techType = kData and (kData.TechType or kData.Type)
    if not techType then return {} end
    local playerID = Game.GetLocalPlayer()
    local unlockables = GetUnlockablesForTech_Cached(techType, playerID) or {}
    local names = {}
    for _, v in ipairs(unlockables) do
        local name = v[2]
        if name and name ~= "" then
            table.insert(names, Locale.Lookup(name))
        end
    end
    return names
end

local function GetCivicUnlockables(kData)
    local civicType = kData and (kData.CivicType or kData.Type)
    if not civicType then return {} end
    local playerID = Game.GetLocalPlayer()
    return GetUnlockablesForCivic_Cached(civicType, playerID) or {}
end

function GetCivicUnlockNames(kData)
    local unlockables = GetCivicUnlockables(kData)
    local names = {}
    for _, v in ipairs(unlockables) do
        local name = v[2]
        if name and name ~= "" then
            table.insert(names, Locale.Lookup(name))
        end
    end
    return names
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
-- Widget builders
-- ===========================================================================

function AddTextDetailNode(mgr, parent, text)
    if not text or text == "" then return end
    local detailText = text
    parent:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIDetailNode"), "TreeviewItem", {
        GetLabel = function() return NormalizeFormattedText(detailText) end,
    }))
end

-- Generic counted expandable list node. `items` is a list of strings; the parent
-- gets one TreeviewItem child whose label is `locOne` (with count = 1) or
-- `locMany` (with count = N), and whose children are one TreeviewItem per item.
function AddCountedListNode(mgr, parent, items, widgetIdPrefix, locOne, locMany)
    local count = items and #items or 0
    if count <= 0 then return end

    local node = mgr:CreateUIWidget(mgr:GenerateWidgetId(widgetIdPrefix), "TreeviewItem", {
        GetLabel = function()
            if count == 1 then return Locale.Lookup(locOne, count) end
            return Locale.Lookup(locMany, count)
        end,
    })

    for _, text in ipairs(items) do
        local itemText = text
        node:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId(widgetIdPrefix .. "Item"), "TreeviewItem", {
            GetLabel = function() return NormalizeFormattedText(itemText) end,
        }))
    end

    parent:AddChild(node)
end

function AddTechUnlocksNode(mgr, parent, unlockNames)
    local count = #unlockNames
    local unlockNode = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIResearchUnlocks"), "TreeviewItem", {
        GetLabel = function()
            if count == 1 then
                return Locale.Lookup("LOC_CAI_RESEARCH_UNLOCKS_COUNT_ONE", count)
            end
            return Locale.Lookup("LOC_CAI_RESEARCH_UNLOCKS_COUNT", count)
        end,
    })

    if count > 0 then
        for _, name in ipairs(unlockNames) do
            local unlockName = name
            unlockNode:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIResearchUnlock"), "TreeviewItem", {
                GetLabel = function() return unlockName end,
            }))
        end
    else
        unlockNode:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIResearchUnlock"), "TreeviewItem", {
            GetLabel = function() return Locale.Lookup("LOC_CAI_RESEARCH_NO_UNLOCKS") end,
        }))
    end

    parent:AddChild(unlockNode)
end

function AddCivicUnlocksNode(mgr, parent, unlockNames)
    local count = #unlockNames
    local unlockNode = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICivicUnlocks"), "TreeviewItem", {
        GetLabel = function()
            if count == 1 then
                return Locale.Lookup("LOC_CAI_CIVIC_UNLOCKS_COUNT_ONE", count)
            end
            return Locale.Lookup("LOC_CAI_CIVIC_UNLOCKS_COUNT", count)
        end,
    })

    if count > 0 then
        for _, name in ipairs(unlockNames) do
            local unlockName = name
            unlockNode:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICivicUnlockItem"), "TreeviewItem", {
                GetLabel = function() return unlockName end,
            }))
        end
    else
        unlockNode:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICivicUnlockItem"), "TreeviewItem", {
            GetLabel = function() return Locale.Lookup("LOC_CAI_CIVIC_NO_UNLOCKS") end,
        }))
    end

    parent:AddChild(unlockNode)
end

function AddMakesObsoleteNode(mgr, parent, obsoleteNames)
    local count = #obsoleteNames
    if count <= 0 then return end

    local obsoleteNode = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICivicObsolete"), "TreeviewItem", {
        GetLabel = function()
            if count == 1 then
                return Locale.Lookup("LOC_CAI_CIVIC_MAKES_OBSOLETE_COUNT_ONE", count)
            end
            return Locale.Lookup("LOC_CAI_CIVIC_MAKES_OBSOLETE_COUNT", count)
        end,
    })

    for _, name in ipairs(obsoleteNames) do
        local obsoleteName = name
        obsoleteNode:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICivicObsoleteItem"), "TreeviewItem", {
            GetLabel = function() return obsoleteName end,
        }))
    end

    parent:AddChild(obsoleteNode)
end

--#Unit info helpers
---Returns the player's civ prefix, as an adjective.
---@param playerID number|nil
---@return string|nil
function GetPlayerOwnershipPrefix(playerID)
    if playerID == nil or playerID == -1 then
        return nil
    end

    local playerConfig = PlayerConfigurations[playerID]
    if playerConfig ~= nil then
        local civName = playerConfig:GetCivilizationShortDescription()
        if civName ~= nil and civName ~= "" then
            local adjective = civName:gsub("_NAME", "_ADJECTIVE")
            if adjective ~= nil and adjective ~= "" then
                return Locale.Lookup(adjective)
            end
        end
    end

    return Locale.Lookup("LOC_TOOLTIP_PLAYER_ID", playerID)
end

---Returns the unit's owner civ prefix, as an adjective.
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
