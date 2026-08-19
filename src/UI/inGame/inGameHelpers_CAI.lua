include("caiUtils")
include("hexCoordUtils_CAI")
include("MapTacks")
-- Shared function for overriding the base game's GetCursorPlot functions
local CAICursor = ExposedMembers.CAICursor
-- Vanilla implementations captured before hijacking, so queries fall back to
-- the real cursor position while the mod is suspended.
local originalGetCursorPlotID
local originalGetCursorPlotCoord

local function GetCAICursorPlotId()
    if ExposedMembers.CAI_Active == false and originalGetCursorPlotID then
        return originalGetCursorPlotID()
    end
    if not CAICursor then return -1 end
    return CAICursor:GetPlotId()
end

local function GetCAICursorPlotCoord()
    if ExposedMembers.CAI_Active == false and originalGetCursorPlotCoord then
        return originalGetCursorPlotCoord()
    end
    local plotId = GetCAICursorPlotId()
    local plot = Map.GetPlotByIndex(plotId)
    if not plot then return -1, -1 end
    return plot:GetX(), plot:GetY()
end

function InstallUIOverrides()
    originalGetCursorPlotID = UI.GetCursorPlotID
    originalGetCursorPlotCoord = UI.GetCursorPlotCoord
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
    text = string.gsub(text, "[ \t\r\n]+", " ") -- ASCII only; %s corrupts UTF-8 (0xA0)
    return text
end

function SplitFormattedLines(text)
    local lines = {}
    text = text or ""
    text = string.gsub(text, "%[NEWLINE%]", "\n")
    for line in string.gmatch(text, "([^\n]+)") do
        local trimmed = string.gsub(line, "^[ \t\r\n]*(.-)[ \t\r\n]*$", "%1")
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

-- ===========================================================================
-- Shared production/unlock detail builders (moved here from ProductionPanel_CAI
-- so the production panel and the tech/civic unlock lists build item
-- descriptions the same way). The builders read a "detail" table from a bare
-- { Type = ... } item -- the production panel additionally fills in
-- cost/turns/progress/failures, while the unlock lists pass none of those so
-- FormatTooltip renders static info only (description, stats, bonuses,
-- requirements). BuildBuildingDetail takes the city as a parameter (nil in the
-- unlock context) instead of reading production-panel module state.
-- ===========================================================================

function NewDetail()
    return {
        repairNeeded        = false,
        cannotAfford        = false,
        cost                = nil,
        costYield           = nil,
        turnsLeft           = nil,
        progressPct         = nil,
        maintenance         = nil,
        resourceUpkeep      = nil,
        description         = nil,
        promotionClass      = nil, ---@type string|nil (units only; rendered last)
        stats               = {}, ---@type string[]
        citizenYields       = {}, ---@type string[]
        citizenYieldsHeader = nil, ---@type string|nil (loc tag emitted before citizenYields)
        failures            = {}, ---@type string[]
        bonuses             = {}, ---@type string[]
        requirements        = {}, ---@type string[]
        policyUnlocks       = {}, ---@type table[] -- { {name=, description=}, ... }
    }
end

local GREAT_WORK_SLOT_LOC = {
    GREATWORKSLOT_PALACE    = "LOC_TYPE_TRAIT_GREAT_WORKS_PALACE_SLOTS",
    GREATWORKSLOT_ART       = "LOC_TYPE_TRAIT_GREAT_WORKS_ART_SLOTS",
    GREATWORKSLOT_WRITING   = "LOC_TYPE_TRAIT_GREAT_WORKS_WRITING_SLOTS",
    GREATWORKSLOT_MUSIC     = "LOC_TYPE_TRAIT_GREAT_WORKS_MUSIC_SLOTS",
    GREATWORKSLOT_RELIC     = "LOC_TYPE_TRAIT_GREAT_WORKS_RELIC_SLOTS",
    GREATWORKSLOT_ARTIFACT  = "LOC_TYPE_TRAIT_GREAT_WORKS_ARTIFACT_SLOTS",
    GREATWORKSLOT_CATHEDRAL = "LOC_TYPE_TRAIT_GREAT_WORKS_CATHEDRAL_SLOTS",
    GREATWORKSLOT_PRODUCT   = "LOC_TYPE_TRAIT_GREAT_WORKS_PRODUCT_SLOTS",
}

local function FormatYieldChange(amount, yieldType)
    local y = yieldType and GameInfo.Yields[yieldType] or nil
    if not y then return nil end
    return Locale.Lookup("LOC_TYPE_TRAIT_YIELD", amount, y.IconString, y.Name)
end

local function SetCost(detail, cost, yieldType)
    if not cost or cost <= 0 then return end
    detail.cost = cost
    detail.costYield = yieldType or "YIELD_PRODUCTION"
end

local function SetMaintenance(detail, maintenance, yieldType)
    if not maintenance or maintenance <= 0 then return end
    local y = GameInfo.Yields[yieldType or "YIELD_GOLD"]
    if not y then return end
    detail.maintenance = Locale.Lookup("LOC_TOOLTIP_MAINTENANCE", maintenance, y.IconString, y.Name)
end

-- Units
function BuildUnitDetail(item, formation)
    local d = NewDetail()
    local def = item.Type and GameInfo.Units[item.Type] or nil
    if not def then return d end

    local cost = item.Cost
    if formation == "corps" then
        cost = item.CorpsCost
    elseif formation == "army" then
        cost = item.ArmyCost
    end
    SetCost(d, cost, item.Yield)
    if item.TurnsLeft and item.TurnsLeft >= 0 then d.turnsLeft = item.TurnsLeft end

    if def.Description and def.Description ~= "" then
        d.description = Locale.Lookup(def.Description)
    end

    local promo = def.PromotionClass and GameInfo.UnitPromotionClasses[def.PromotionClass] or nil
    if promo and promo.Name and not (def.UnitType and string.find(def.UnitType, "UNIT_HERO")) then
        d.promotionClass = Locale.Lookup("LOC_UNIT_PROMOTION_CLASS", promo.Name)
    end

    SetMaintenance(d, def.Maintenance)

    local function S(key, ...) table.insert(d.stats, Locale.Lookup(key, ...)) end
    if def.Combat and def.Combat > 0 then S("LOC_UNIT_COMBAT_STRENGTH", def.Combat) end
    if def.RangedCombat and def.RangedCombat > 0 and def.Range and def.Range > 0 then
        S("LOC_UNIT_RANGED_STRENGTH", def.RangedCombat, def.Range)
    end
    if def.Bombard and def.Bombard > 0 and def.Range and def.Range > 0 then
        S("LOC_UNIT_BOMBARD_STRENGTH", def.Bombard, def.Range)
    end
    if UnitManager and UnitManager.GetUnitTypeBaseLifespan then
        local life = UnitManager.GetUnitTypeBaseLifespan(def.Index)
        if life and life > 0 then S("LOC_UNIT_LIFESPAN", life) end
    end
    if def.BaseMoves and def.BaseMoves > 0 then S("LOC_UNIT_MOVEMENT", def.BaseMoves) end
    if def.AirSlots and def.AirSlots ~= 0 then S("LOC_TYPE_TRAIT_AIRSLOTS", def.AirSlots) end

    if def.StrategicResource then
        local r = GameInfo.Resources[def.StrategicResource]
        if r then
            table.insert(d.requirements, "[ICON_" .. r.ResourceType .. "] " .. Locale.Lookup(r.Name))
        end
    end

    if GameInfo.UnitConsumption then
        for row in GameInfo.UnitConsumption() do
            if row.UnitType == def.UnitType and row.ResourceMaintenanceAmount and row.ResourceMaintenanceAmount > 0 then
                local r = GameInfo.Resources[row.ResourceType]
                if r then
                    d.resourceUpkeep = Locale.Lookup("LOC_CAI_PRODUCTION_RESOURCE_UPKEEP",
                        row.ResourceMaintenanceAmount, Locale.Lookup(r.Name))
                end
            end
        end
    end

    return d
end

-- Buildings (incl. Wonders)
function BuildBuildingDetail(item, pCity)
    local d = NewDetail()
    local def = item.Type and GameInfo.Buildings[item.Type] or nil
    if not def then return d end

    local bt = def.BuildingType
    local playerID = Game.GetLocalPlayer()

    SetCost(d, item.Cost, item.Yield)
    if item.TurnsLeft and item.TurnsLeft >= 0 then d.turnsLeft = item.TurnsLeft end
    if def.Description and def.Description ~= "" then
        d.description = Locale.Lookup(def.Description)
    end
    SetMaintenance(d, def.Maintenance)

    d.citizenYieldsHeader = "LOC_TOOLTIP_BUILDING_CITIZEN_YIELDS_HEADER"

    local district = nil
    if pCity then
        district = pCity:GetDistricts():GetDistrict(def.PrereqDistrict)
    end

    if pCity then
        for yield in GameInfo.Yields() do
            local change = pCity:GetBuildingPotentialYield(def.Hash, yield.YieldType)
            if change and change ~= 0 then
                local line = FormatYieldChange(change, yield.YieldType)
                if line then table.insert(d.bonuses, line) end
            end
        end
    else
        for row in GameInfo.Building_YieldChanges() do
            if row.BuildingType == bt then
                local line = FormatYieldChange(row.YieldChange, row.YieldType)
                if line then table.insert(d.bonuses, line) end
            end
        end
    end

    for row in GameInfo.Building_YieldDistrictCopies() do
        if row.BuildingType == bt then
            local from = GameInfo.Yields[row.OldYieldType]
            local to = GameInfo.Yields[row.NewYieldType]
            if from and to then
                table.insert(d.bonuses,
                    Locale.Lookup("LOC_TOOLTIP_BUILDING_DISTRICT_COPY",
                        to.IconString, to.Name, from.IconString, from.Name))
            end
        end
    end

    if def.Housing and def.Housing ~= 0 then
        table.insert(d.bonuses, Locale.Lookup("LOC_TYPE_TRAIT_HOUSING", def.Housing))
    end

    local entertainment = def.Entertainment or 0
    if entertainment ~= 0 then
        if district and def.RegionalRange and def.RegionalRange ~= 0 then
            entertainment = entertainment + district:GetExtraRegionalEntertainment()
        end
        table.insert(d.bonuses, Locale.Lookup("LOC_TYPE_TRAIT_AMENITY_ENTERTAINMENT", entertainment))
    end

    if def.CitizenSlots and def.CitizenSlots ~= 0 then
        table.insert(d.bonuses, Locale.Lookup("LOC_TYPE_TRAIT_CITIZENS", def.CitizenSlots))
    end
    if def.OuterDefenseHitPoints and def.OuterDefenseHitPoints ~= 0 then
        table.insert(d.bonuses, Locale.Lookup("LOC_TYPE_TRAIT_OUTER_DEFENSE", def.OuterDefenseHitPoints))
    end
    for row in GameInfo.Building_GreatPersonPoints() do
        if row.BuildingType == bt then
            local cls = GameInfo.GreatPersonClasses[row.GreatPersonClassType]
            if cls then
                table.insert(d.bonuses, Locale.Lookup("LOC_TYPE_TRAIT_GREAT_PERSON_POINTS",
                    row.PointsPerTurn, cls.IconString, cls.Name))
            end
        end
    end
    for row in GameInfo.Building_GreatWorks() do
        if row.BuildingType == bt then
            local key = GREAT_WORK_SLOT_LOC[row.GreatWorkSlotType]
            if key then
                table.insert(d.bonuses, Locale.Lookup(key, row.NumSlots))
            end
        end
    end

    if district and def.RegionalRange and def.RegionalRange ~= 0 then
        local extra = district:GetExtraRegionalRange()
        if extra and extra ~= 0 then
            table.insert(d.bonuses, Locale.Lookup("LOC_TOOLTIP_EXTRA_REGIONAL_RANGE", extra))
        end
    end

    for row in GameInfo.Building_CitizenYieldChanges() do
        if row.BuildingType == bt then
            local line = FormatYieldChange(row.YieldChange, row.YieldType)
            if line then table.insert(d.citizenYields, line) end
        end
    end

    if def.UnlocksGovernmentPolicy and playerID ~= -1 then
        local pCulture = Players[playerID] and Players[playerID]:GetCulture() or nil
        local slot = pCulture and pCulture:GetPolicyToUnlock(def.Index) or -1
        if slot and slot ~= -1 then
            local policy = GameInfo.Policies[slot]
            if policy then
                table.insert(d.policyUnlocks, {
                    name = Locale.Lookup(policy.Name),
                    description = policy.Description and Locale.Lookup(policy.Description) or nil,
                })
            end
        end
    end

    if def.RequiresReligion then
        table.insert(d.requirements, Locale.Lookup("LOC_TOOLTIP_PLACEMENT_REQUIRES_RELIGION"))
    end
    for row in GameInfo.MutuallyExclusiveBuildings() do
        if row.Building == bt then
            local ex = GameInfo.Buildings[row.MutuallyExclusiveBuilding]
            if ex then
                table.insert(d.requirements,
                    Locale.Lookup("LOC_TOOLTIP_BUILDING_MUTUALLY_EXCLUSIVE_WITH", ex.Name))
            end
        end
    end
    local required_buildings = {}
    for row in GameInfo.BuildingPrereqs() do
        if row.Building == bt then
            local pre = GameInfo.Buildings[row.PrereqBuilding]
            if pre then
                local preD = GameInfo.Districts[pre.PrereqDistrict]
                if preD and preD.DistrictType ~= "DISTRICT_CITY_CENTER"
                    and preD.DistrictType ~= def.PrereqDistrict then
                    table.insert(required_buildings, Locale.Lookup(
                        "LOC_TOOLTIP_BUILDING_REQUIRES_BUILDING_WITH_DISTRICT", pre.Name, preD.Name))
                else
                    table.insert(required_buildings, Locale.Lookup(
                        "LOC_TOOLTIP_BUILDING_REQUIRES_BUILDING", pre.Name))
                end
            end
        end
    end
    if #required_buildings == 1 then
        table.insert(d.requirements, required_buildings[1])
    elseif #required_buildings == 2 then
        table.insert(d.requirements, Locale.Lookup(
            "LOC_TOOLTIP_BUILDING_REQUIRES_BUILDING_OR", required_buildings[1], required_buildings[2]))
    elseif #required_buildings > 2 then
        table.insert(d.requirements, Locale.Lookup("LOC_TOOLTIP_BUILDING_REQUIRES_ONE_OF_FOLLOWING"))
        for _, line in ipairs(required_buildings) do
            table.insert(d.requirements, line)
        end
    end
    if def.PrereqDistrict then
        local dist = GameInfo.Districts[def.PrereqDistrict]
        if dist and dist.DistrictType ~= "DISTRICT_CITY_CENTER" then
            table.insert(d.requirements, Locale.Lookup("LOC_TOOLTIP_BUILDING_REQUIRES_DISTRICT", dist.Name))
        end
    end
    if def.AdjacentDistrict then
        local adj = GameInfo.Districts[def.AdjacentDistrict]
        if adj then
            table.insert(d.requirements,
                Locale.Lookup("LOC_TOOLTIP_BUILDING_REQUIRES_ADJACENT_DISTRICT", adj.Name))
        end
    end
    if def.AdjacentImprovement then
        local imp = GameInfo.Improvements[def.AdjacentImprovement]
        if imp then
            table.insert(d.requirements,
                Locale.Lookup("LOC_TOOLTIP_BUILDING_REQUIRES_ADJACENT_DISTRICT", imp.Name))
        end
    end
    if def.AdjacentResource then
        local r = GameInfo.Resources[def.AdjacentResource]
        if r then
            table.insert(d.requirements,
                Locale.Lookup("LOC_TOOLTIP_BUILDING_REQUIRES_ADJACENT_RESOURCE", r.Name))
        end
    end
    if def.RequiresRiver or def.RequiresAdjacentRiver then
        table.insert(d.requirements, Locale.Lookup("LOC_TOOLTIP_PLACEMENT_REQUIRES_ADJACENT_RIVER"))
    end
    if def.MustBeLake then table.insert(d.requirements, Locale.Lookup("LOC_TOOLTIP_PLACEMENT_REQUIRES_LAKE")) end
    if def.MustNotBeLake then table.insert(d.requirements, Locale.Lookup("LOC_TOOLTIP_PLACEMENT_REQUIRES_NOT_LAKE")) end
    if def.AdjacentToMountain then
        table.insert(d.requirements, Locale.Lookup("LOC_TOOLTIP_PLACEMENT_REQUIRES_ADJACENT_MOUNTAIN"))
    end
    if def.Coast or def.MustBeAdjacentLand then
        table.insert(d.requirements, Locale.Lookup("LOC_TOOLTIP_PLACEMENT_REQUIRES_COAST"))
    end

    return d
end

-- Districts
function BuildDistrictDetail(item)
    local d = NewDetail()
    local def = item.Type and GameInfo.Districts[item.Type] or nil
    if not def then return d end

    SetCost(d, item.Cost, item.Yield)
    if item.TurnsLeft and item.TurnsLeft >= 0 then d.turnsLeft = item.TurnsLeft end
    if def.Description and def.Description ~= "" then
        d.description = Locale.Lookup(def.Description)
    end
    SetMaintenance(d, def.Maintenance)

    d.citizenYieldsHeader = "LOC_TOOLTIP_DISTRICT_CITIZEN_YIELDS_HEADER"

    for row in GameInfo.District_GreatPersonPoints() do
        if row.DistrictType == def.DistrictType then
            local cls = GameInfo.GreatPersonClasses[row.GreatPersonClassType]
            if cls then
                table.insert(d.bonuses, Locale.Lookup("LOC_TYPE_TRAIT_GREAT_PERSON_POINTS",
                    row.PointsPerTurn, cls.IconString, cls.Name))
            end
        end
    end
    if def.Housing and def.Housing ~= 0 then
        table.insert(d.bonuses, Locale.Lookup("LOC_TYPE_TRAIT_HOUSING", def.Housing))
    end
    if def.Entertainment and def.Entertainment ~= 0 then
        table.insert(d.bonuses, Locale.Lookup("LOC_TYPE_TRAIT_AMENITY_ENTERTAINMENT", def.Entertainment))
    end
    local air = tonumber(def.AirSlots) or 0
    if air ~= 0 then table.insert(d.bonuses, Locale.Lookup("LOC_TYPE_TRAIT_AIRSLOTS", air)) end
    local cit = tonumber(def.CitizenSlots) or 0
    if cit ~= 0 then table.insert(d.bonuses, Locale.Lookup("LOC_TYPE_TRAIT_CITIZENSLOTS", cit)) end

    if type(ToolTipHelper) == "table" and type(ToolTipHelper.GetAdjacencyBonuses) == "function" then
        local lines = ToolTipHelper.GetAdjacencyBonuses(GameInfo.District_Adjacencies, "DistrictType", def.DistrictType)
        if type(lines) == "table" then
            for _, line in ipairs(lines) do
                if line and line ~= "" then table.insert(d.bonuses, line) end
            end
        end
    end

    for row in GameInfo.District_CitizenYieldChanges() do
        if row.DistrictType == def.DistrictType then
            local line = FormatYieldChange(row.YieldChange, row.YieldType)
            if line then table.insert(d.citizenYields, line) end
        end
    end

    if def.NoAdjacentCity then
        table.insert(d.requirements, Locale.Lookup("LOC_DISTRICT_REQUIRE_NOT_ADJACENT_TO_CITY"))
    end

    return d
end

-- Projects
function BuildProjectDetail(item)
    local d = NewDetail()
    local def = item.Type and GameInfo.Projects[item.Type] or nil
    if not def then return d end

    SetCost(d, item.Cost, item.Yield)
    if item.TurnsLeft and item.TurnsLeft >= 0 then d.turnsLeft = item.TurnsLeft end
    local desc = def.ShortDescription or def.Description
    if desc and desc ~= "" then
        d.description = Locale.Lookup(desc)
    end

    if def.AmenitiesWhileActive and def.AmenitiesWhileActive > 0 then
        table.insert(d.bonuses,
            Locale.Lookup("LOC_PROJECT_AMENITIES_WHILE_ACTIVE", def.AmenitiesWhileActive))
    end
    for row in GameInfo.Project_YieldConversions() do
        if row.ProjectType == def.ProjectType then
            local y = GameInfo.Yields[row.YieldType]
            if y then
                table.insert(d.bonuses,
                    Locale.Lookup("LOC_PROJECT_YIELD_CONVERSIONS",
                        y.IconString, y.Name, row.PercentOfProductionRate))
            end
        end
    end
    for row in GameInfo.Project_GreatPersonPoints() do
        if row.ProjectType == def.ProjectType then
            local cls = GameInfo.GreatPersonClasses[row.GreatPersonClassType]
            if cls then
                table.insert(d.bonuses, Locale.Lookup("LOC_PROJECT_GREAT_PERSON_POINTS",
                    cls.IconString, cls.Name))
            end
        end
    end

    return d
end

local function FormatCostLine(detail)
    if not detail.cost or not detail.costYield then return nil end
    if detail.costYield == "YIELD_GOLD" then
        return Locale.Lookup("LOC_CAI_PRODUCTION_COST_GOLD", detail.cost)
    elseif detail.costYield == "YIELD_FAITH" then
        return Locale.Lookup("LOC_CAI_PRODUCTION_COST_FAITH", detail.cost)
    end
    return Locale.Lookup("LOC_CAI_PRODUCTION_COST_PRODUCTION", detail.cost)
end

function FormatTooltip(detail)
    local parts = {}
    AppendIfNonEmpty(parts, FormatCostLine(detail))
    if detail.turnsLeft and detail.turnsLeft > 0 then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_PRODUCTION_TURNS", detail.turnsLeft))
    end
    if detail.progressPct then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_PRODUCTION_PROGRESS", detail.progressPct))
    end
    AppendIfNonEmpty(parts, detail.maintenance)
    AppendIfNonEmpty(parts, detail.resourceUpkeep)
    AppendIfNonEmpty(parts, detail.description)

    if detail.repairNeeded then AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_PRODUCTION_REPAIR_NEEDED")) end
    for _, s in ipairs(detail.stats) do AppendIfNonEmpty(parts, s) end

    if #detail.citizenYields > 0 then
        if detail.citizenYieldsHeader then
            AppendIfNonEmpty(parts, Locale.Lookup(detail.citizenYieldsHeader))
        end
        for _, c in ipairs(detail.citizenYields) do AppendIfNonEmpty(parts, c) end
    end

    if #detail.requirements > 0 then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_TOOLTIP_BUILDING_REQUIRES"))
        for _, r in ipairs(detail.requirements) do AppendIfNonEmpty(parts, r) end
    end

    if detail.cannotAfford then AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_PRODUCTION_CANNOT_AFFORD")) end
    if #detail.failures > 0 then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_PRODUCTION_FAILURE_REASONS_LABEL"))
        for _, f in ipairs(detail.failures) do AppendIfNonEmpty(parts, f) end
    end

    AppendIfNonEmpty(parts, detail.promotionClass)

    if #detail.bonuses > 0 then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_PRODUCTION_BONUSES_LABEL"))
        for _, b in ipairs(detail.bonuses) do AppendIfNonEmpty(parts, b) end
    end

    if #detail.policyUnlocks > 0 then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_PRODUCTION_UNLOCKS_LABEL"))
        for _, u in ipairs(detail.policyUnlocks) do
            AppendIfNonEmpty(parts, u.name)
            AppendIfNonEmpty(parts, u.description)
        end
    end

    return table.concat(parts, "[NEWLINE]")
end

-- Split on the literal [NEWLINE] token (plain find; not a Lua pattern) so we
-- never touch the locale-sensitive %s class on multibyte text.
local function SplitNewlineToken(text)
    local lines = {}
    local pos = 1
    while true do
        local s, e = string.find(text, "[NEWLINE]", pos, true)
        if not s then
            lines[#lines + 1] = string.sub(text, pos)
            return lines
        end
        lines[#lines + 1] = string.sub(text, pos, s - 1)
        pos = e + 1
    end
end

local function TrimAscii(s)
    return (string.gsub(s or "", "^[ \t\r\n]*(.-)[ \t\r\n]*$", "%1"))
end

-- The category word vanilla puts on the tooltip's second line for each unlock
-- kind ("Policy", "Building", ...). Built lazily and cached; used to lift the
-- category into the widget label and drop it from the spoken tooltip body.
local UNLOCK_CATEGORY_TAGS = {
    "LOC_BUILDING_NAME", "LOC_WONDER_NAME", "LOC_UNIT_NAME", "LOC_DISTRICT_NAME",
    "LOC_IMPROVEMENT_NAME", "LOC_PROJECT_NAME", "LOC_POLICY_NAME",
    "LOC_GOVERNMENT_NAME",
}
local m_unlockCategorySet = nil
local function UnlockCategorySet()
    if m_unlockCategorySet then return m_unlockCategorySet end
    m_unlockCategorySet = {}
    for _, tag in ipairs(UNLOCK_CATEGORY_TAGS) do
        local s = Locale.Lookup(tag)
        -- Locale.Lookup echoes the tag on a miss; skip those.
        if s and s ~= "" and s ~= tag then m_unlockCategorySet[s] = true end
    end
    return m_unlockCategorySet
end

-- Normalized form for substring comparison: drop bracket tokens ([ICON_x],
-- [COLOR_x], [NEWLINE], ...) and collapse ASCII whitespace. Used only to detect
-- duplicated lines, never for display, so token stripping here is safe (the
-- central ProcessText still handles display text). ASCII-only sets avoid the
-- locale-sensitive %s pitfall on multibyte text.
local function NormalizeForCompare(s)
    s = string.gsub(s or "", "%[[^%]]*%]", " ")
    s = string.gsub(s, "[ \t\r\n]+", " ")
    return TrimAscii(s)
end

-- Some vanilla improvement descriptions restate the improvement's base yields in
-- prose, and GetImprovementToolTip then appends those same yields again as
-- separate stat lines (e.g. Offshore Wind Farm reads "... +2 Production ..." and
-- then "+2 Production"). Drop a trailing line whose text already appears in an
-- earlier line so the yield is not spoken twice. Lines that are not already in
-- the description (e.g. yields the prose never mentioned) are kept.
local function DropDuplicateLines(body)
    local out = {}
    for i, line in ipairs(body) do
        local norm = NormalizeForCompare(line)
        local dup = false
        if norm ~= "" and i > 1 then
            local earlier = NormalizeForCompare(table.concat(body, " ", 1, i - 1))
            if string.find(earlier, norm, 1, true) then dup = true end
        end
        if not dup then out[#out + 1] = line end
    end
    return out
end

-- Fallback for unlock kinds with no CAI detail builder (policies, improvements,
-- governments, ...): reshape the vanilla tooltip. Vanilla lays every unlock
-- tooltip out as line 1 = NAME (optionally with a "(Slot)" suffix for
-- policies), line 2 = category word, then the description and stats. Lift the
-- name/category (and slot) into the label and keep only the body as the tooltip.
local function BuildUnlockDisplayFromVanilla(typeName, name, playerID, kind)
    local tip = typeName and ToolTipHelper.GetToolTip(typeName, playerID) or nil
    if not tip or tip == "" then
        return name, GetUnlockDescription(typeName) or ""
    end

    local lines = SplitNewlineToken(tip)
    -- Line 1 is the upper-cased name; only policies append a "(Slot)" suffix.
    local slot = string.match(TrimAscii(lines[1]), "%(([^()]*)%)$")

    -- Line 2 is the category for every generator we care about, except unique
    -- variants whose line reads "replaces X"; keep those in the body instead.
    local category = TrimAscii(lines[2])
    local bodyStart = 2
    if UnlockCategorySet()[category] then
        bodyStart = 3
    else
        category = nil
    end

    local label = name
    if category then label = label .. ", " .. category end
    if slot and slot ~= "" then label = label .. " (" .. slot .. ")" end

    local body = {}
    for i = bodyStart, #lines do
        if TrimAscii(lines[i]) ~= "" then body[#body + 1] = lines[i] end
    end

    -- Improvement descriptions often restate their base yields, which vanilla
    -- then appends again; drop those duplicates.
    if kind == "KIND_IMPROVEMENT" then
        body = DropDuplicateLines(body)
    end

    return label, table.concat(body, "[NEWLINE]")
end

-- Category loc tag for the label ("Catapult, Unit") of producible kinds.
local UNLOCK_KIND_CATEGORY = {
    KIND_UNIT        = "LOC_UNIT_NAME",
    KIND_DISTRICT    = "LOC_DISTRICT_NAME",
    KIND_PROJECT     = "LOC_PROJECT_NAME",
}

-- Build a static CAI detail for the producible kinds the shared builders cover;
-- nil for anything else. The item carries the base production cost from the
-- database (not the player-adjusted build-queue cost) so the tooltip opens with
-- a base production line, but no dynamic turns/progress.
local function BuildStaticUnlockDetail(typeName, kind)
    local item = { Type = typeName }
    if kind == "KIND_UNIT" then
        local def = GameInfo.Units[typeName]
        item.Cost = def and def.Cost or nil
        return BuildUnitDetail(item, nil)
    end
    if kind == "KIND_BUILDING" then
        local def = GameInfo.Buildings[typeName]
        item.Cost = def and def.Cost or nil
        return BuildBuildingDetail(item, nil)
    end
    if kind == "KIND_DISTRICT" then
        local def = GameInfo.Districts[typeName]
        item.Cost = def and def.Cost or nil
        return BuildDistrictDetail(item)
    end
    if kind == "KIND_PROJECT" then
        local def = GameInfo.Projects[typeName]
        item.Cost = def and def.Cost or nil
        return BuildProjectDetail(item)
    end
    return nil
end

-- Build a label + tooltip for one unlock, matching how CAI describes producible
-- items in the production panel: name and type on the label ("Catapult, Unit"),
-- the static description and stats in the tooltip. Producible kinds go through
-- the shared detail builders (static fields only); other kinds fall back to the
-- reshaped vanilla tooltip.
---@param typeName string
---@param name string localized proper-case name
---@param playerID number
---@return string label, string tooltip
function BuildUnlockDisplay(typeName, name, playerID)
    local t = typeName and GameInfo.Types[typeName] or nil
    local kind = t and t.Kind or nil

    local detail = BuildStaticUnlockDetail(typeName, kind)
    if not detail then
        return BuildUnlockDisplayFromVanilla(typeName, name, playerID, kind)
    end

    local catTag
    if kind == "KIND_BUILDING" then
        local b = GameInfo.Buildings[typeName]
        catTag = (b and b.IsWonder) and "LOC_WONDER_NAME" or "LOC_BUILDING_NAME"
    else
        catTag = UNLOCK_KIND_CATEGORY[kind]
    end

    local label = name
    if catTag then
        local cat = Locale.Lookup(catTag)
        if cat and cat ~= "" and cat ~= catTag then label = label .. ", " .. cat end
    end
    return label, FormatTooltip(detail)
end

function GetCivicUnlockObjects(kData)
    local unlocks = {}
    local playerID = Game.GetLocalPlayer()
    for _, u in ipairs(GetCivicUnlockables(kData)) do
        local typeName, locName = u[1], u[2]
        if locName and locName ~= "" then
            local name = Locale.Lookup(locName)
            local label, tooltip = BuildUnlockDisplay(typeName, name, playerID)
            table.insert(unlocks, {
                TypeName = typeName,
                Name = name,
                Description = GetUnlockDescription(typeName),
                -- Name/category (and policy slot) in the label; description and
                -- stats in the tooltip, matching the production panel layout.
                DisplayLabel = label,
                DisplayTooltip = tooltip,
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
                local name = Locale.Lookup(locName)
                local label, tooltip = BuildUnlockDisplay(typeName, name, playerID)
                table.insert(unlocks, {
                    TypeName = typeName,
                    Name = name,
                    Description = GetUnlockDescription(typeName),
                    -- Name/category (and policy slot) in the label; description
                    -- and stats in the tooltip, matching the production panel.
                    DisplayLabel = label,
                    DisplayTooltip = tooltip,
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
        -- Label carries name + category (+ policy slot); tooltip carries the
        -- static description and stats with the header stripped.
        Label    = function() return unlock.DisplayLabel or unlock.Name end,
        Tooltip  = function() return unlock.DisplayTooltip or unlock.Description or "" end,
        FocusKey = "unlock:" .. tostring(unlock.TypeName),
    })
    child:AddInputBindings({
        {
            Key         = Keys.VK_RETURN,
            IsShift     = true,
            MSG         = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_OPEN_CIVILOPEDIA",
            Action      = function()
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
    local label = BuildMapTacLabelWithDMT(
        mapPinCfg,
        playerID,
        localPlayerID
    )

    if label == nil or label == "" or playerID == localPlayerID then
        return label
    end

    local ownerLabel = GetMapTacOwnerLabel(playerID)
    if ownerLabel == nil or ownerLabel == "" then
        return label
    end

    return label .. ", " .. ownerLabel
end

---@param mapPinCfg table|nil
---@param playerID number|nil
---@param localPlayerID number|nil
---@return string|nil
function BuildMapTacLabelWithDMT(mapPinCfg, playerID, localPlayerID)
    local label = BuildMapTacLabel(mapPinCfg)

    if label == nil or label == "" then
        return label
    end

    -- DMT compatibility.
    -- DMT only maintains MapPinSubjects for the local player's pins.
    if playerID ~= localPlayerID then
        return label
    end

    if ExposedMembers.CAIInfo == nil or ExposedMembers.CAIInfo.GetMapPinSubject == nil then
        return label
    end

    local subject = ExposedMembers.CAIInfo.GetMapPinSubject(
        playerID,
        mapPinCfg:GetHexX(),
        mapPinCfg:GetHexY()
    )

    if subject == nil then
        return label
    end

    if subject.YieldToolTip ~= nil
        and subject.YieldToolTip ~= "" then
        label = label
            .. "[NEWLINE]"
            .. subject.YieldToolTip
    end

    if subject.CanPlace == false
        and subject.CanPlaceToolTip ~= nil
        and subject.CanPlaceToolTip ~= "" then
        label = label
            .. "[NEWLINE]"
            .. subject.CanPlaceToolTip
    end

    return label
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
                        Label = BuildMapTacLabelWithDMT(mapPinCfg, iPlayer, localPlayerID),
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
    normalized = string.gsub(normalized, "^[ \t\r\n]*(.-)[ \t\r\n]*$", "%1")
    if normalized == "" then
        return nil
    end

    return normalized
end

-- Unit numbering (e.g. "Warrior 2"). All numbering lives in the shared
-- CAIUnitNumbers registry (CAIUnitNumbers.lua); here we only read it for display.
-- A number is shown only when 2+ units of that owner and type are known, so a
-- lone unit reads just its name.

---Returns the slot number to display for a unit, or nil when none should be
---shown (no number yet, or the unit is currently the only known one of its type).
---@param unit Unit
---@return number|nil
local function GetUnitDisplayNumber(unit)
    local registry = ExposedMembers.CAIUnitNumbers
    if registry == nil then
        return nil
    end

    local ownerID = unit:GetOwner()
    local number = registry:Get(ownerID, unit:GetID())
    if number == nil then
        return nil
    end

    if registry:CountKnownOfType(ownerID, unit:GetUnitType(), unit:GetMilitaryFormation()) < 2 then
        return nil
    end

    return number
end

---Appends the unit's slot number to an already-localized unit name when
---appropriate: the owner has 2+ living units of that type and the unit has no
---custom (veteran) name. Route any spoken unit-name string through this so
---numbering is consistent everywhere (unit panel, units list, report breakdowns,
---flags, etc.). Returns the name unchanged when no number should be shown.
---@param unit Unit|nil
---@param localizedName string|nil
---@return string|nil
function GetNumberedUnitName(unit, localizedName)
    if unit == nil or localizedName == nil or localizedName == "" then
        return localizedName
    end

    local unitInfo = GameInfo.Units[unit:GetUnitType()]
    local rawName = unit:GetName()
    local hasCustomName = unitInfo ~= nil and rawName ~= nil and rawName ~= "" and rawName ~= unitInfo.Name
    if hasCustomName then
        return localizedName
    end

    local number = GetUnitDisplayNumber(unit)
    if number == nil then
        return localizedName
    end

    return Locale.Lookup("LOC_CAI_UNIT_NUMBER_SUFFIX", localizedName, number)
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

    -- Number after the formation suffix, e.g. "Field Cannon Corps 1".
    local formatted = FormatOwnedName(owner, name, formationSuffix or GetUnitFormationSuffix(unit))
    return GetNumberedUnitName(unit, formatted)
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
