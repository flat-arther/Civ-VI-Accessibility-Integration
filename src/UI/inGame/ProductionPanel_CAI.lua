include("caiUtils")
include("inGameHelpers_CAI")
include("ProductionPanel")

local BABYLON_MOD_ID = "1B28771A-C749-434B-9053-D1380C553DE9"
local function HasBabylon()
    for _, v in ipairs(Modding.GetActiveMods() or {}) do
        if v.Id == BABYLON_MOD_ID then return true end
    end
    return false
end
if HasBabylon() then include("ProductionPanel_Babylon_Heroes") end

local mgr = ExposedMembers.CAI_UIManager

local PANEL_ID         = "CAIProductionPanel_Panel"
local TABS_ID          = "CAIProductionPanel_Tabs"
local PAGE_PROD_ID     = "CAIProductionPanel_PageProduction"
local PAGE_GOLD_ID     = "CAIProductionPanel_PagePurchaseGold"
local PAGE_FAITH_ID    = "CAIProductionPanel_PagePurchaseFaith"
local PAGE_QUEUE_ID    = "CAIProductionPanel_PageQueue"

local LISTMODE         = { PRODUCTION = 1, PURCHASE_GOLD = 2, PURCHASE_FAITH = 3, PROD_QUEUE = 4 }
local TAB              = { PRODUCTION = 1, PURCHASE_GOLD = 2, PURCHASE_FAITH = 3, QUEUE = 4 }
local MAX_QUEUE_SIZE   = 7

local m_state = {
    activeTab          = TAB.PRODUCTION,
    openPending        = false,
    data               = nil,         ---@type table|nil
    recommended        = {},          ---@type table<number, string|nil>
    isQueueActionActive = false,
    queueFocusIndexAfterRebuild = nil,---@type integer|nil
}

local m_ui = {
    panel      = nil, ---@type UIWidget|nil
    tabs       = nil, ---@type UIWidget|nil
    pages      = {},  ---@type table<integer, UIWidget>
    pageTrees  = {},  ---@type table<integer, UIWidget> -- main Tree per tab (or List for queue)
    categoryNodes = {}, ---@type table<integer, table<string, UIWidget>>
}

local m_vanilla = {
    instanceByHash       = {}, ---@type table<number, table>
    instancesByModeHash  = {}, ---@type table<integer, table<number, table>>
    categoryListsByMode  = {}, ---@type table<integer, table<string, table>>
    captureListMode      = nil,---@type integer|nil
}

-- ===========================================================================
-- Helpers
-- ===========================================================================
local function ControlIsHidden(c) return c and c.IsHidden and c:IsHidden() or false end
local function ControlIsDisabled(c) return c and c.IsDisabled and c:IsDisabled() or false end
local function ControlText(c)
    if c and c.GetText then return c:GetText() or "" end
    return ""
end

function PlayMenuHover() UI.PlaySound("Main_Menu_Mouse_Over") end

function WithFormationSuffix(name, formation)
    if formation == "corps" then return name .. " " .. Locale.Lookup("LOC_UNITFLAG_CORPS_SUFFIX") end
    if formation == "army" then return name .. " " .. Locale.Lookup("LOC_UNITFLAG_ARMY_SUFFIX") end
    return name
end

local function GetListModeForTab(tab)
    if tab == TAB.PRODUCTION then return LISTMODE.PRODUCTION end
    if tab == TAB.PURCHASE_GOLD then return LISTMODE.PURCHASE_GOLD end
    if tab == TAB.PURCHASE_FAITH then return LISTMODE.PURCHASE_FAITH end
    if tab == TAB.QUEUE then return LISTMODE.PROD_QUEUE end
    return nil
end

local function GetTabForListMode(listMode)
    if listMode == LISTMODE.PURCHASE_GOLD then return TAB.PURCHASE_GOLD end
    if listMode == LISTMODE.PURCHASE_FAITH then return TAB.PURCHASE_FAITH end
    if listMode == LISTMODE.PROD_QUEUE then return TAB.QUEUE end
    return TAB.PRODUCTION
end

local function GetProductionItemClass(item)
    if not item then return nil end
    if item.Type and GameInfo.Units[item.Type] then return "unit" end
    if item.Type and GameInfo.Buildings[item.Type] then return "building" end
    if item.Type and GameInfo.Districts[item.Type] then return "district" end
    if item.Type and GameInfo.Projects[item.Type] then return "project" end
    if item.Kind == "KIND_UNIT" then return "unit" end
    if item.Kind == "KIND_BUILDING" then return "building" end
    if item.Kind == "KIND_DISTRICT" then return "district" end
    if item.Kind == "KIND_PROJECT" then return "project" end
    return nil
end

local function GetInstanceForItem(item, tab)
    if not item or not item.Hash then return nil end
    local lm = GetListModeForTab(tab)
    local byMode = lm and m_vanilla.instancesByModeHash[lm] or nil
    if byMode and byMode[item.Hash] then return byMode[item.Hash] end
    return m_vanilla.instanceByHash[item.Hash]
end

local function SetCategoryListForMode(listMode, categoryKey, inst)
    if not listMode or not categoryKey or not inst then return end
    m_vanilla.categoryListsByMode[listMode] = m_vanilla.categoryListsByMode[listMode] or {}
    m_vanilla.categoryListsByMode[listMode][categoryKey] = inst
end

local function GetCategoryListForMode(listMode, categoryKey)
    local byMode = listMode and m_vanilla.categoryListsByMode[listMode] or nil
    return byMode and byMode[categoryKey] or nil
end

local function GetInstanceActionControl(inst, formation)
    if not inst then return nil end
    if formation == "corps" then return inst.TrainCorpsButton or inst.Button end
    if formation == "army" then return inst.TrainArmyButton or inst.Button end
    return inst.Button
end

local function IsItemRowDisabled(item, tab, formation)
    local d = item and item.Disabled or false
    if formation == "corps" then d = item and item.CorpsDisabled or false end
    if formation == "army" then d = item and item.ArmyDisabled or false end
    local inst = GetInstanceForItem(item, tab)
    return d or ControlIsDisabled(GetInstanceActionControl(inst, formation))
end

local function IsItemRowHidden(item, tab, formation)
    local inst = GetInstanceForItem(item, tab)
    if not inst then return false end
    if formation == "corps" then
        return ControlIsHidden(inst.CorpsButtonContainer)
    elseif formation == "army" then
        return ControlIsHidden(inst.ArmyButtonContainer)
    end
    return ControlIsHidden(inst.Root) or ControlIsHidden(inst.Button)
end

local function IsProductionTutorialMode()
    local running = false
    if type(IsTutorialRunning) == "function" then running = IsTutorialRunning() end
    return running or m_isTutorialRunning == true or m_tutorialTestMode == true
end

local function CurrentTabSupportsQueue()
    return not IsProductionTutorialMode()
end

-- ===========================================================================
-- Detail extraction (kept from previous implementation; emit tooltip + details)
-- ===========================================================================
local function NewDetail()
    return {
        repairNeeded   = false,
        alreadyBuilt   = false,
        cannotAfford   = false,
        cost           = nil,
        costYield      = nil,
        turnsLeft      = nil,
        progressPct    = nil,
        maintenance    = nil,
        resourceUpkeep = nil,
        description    = nil,
        stats          = {},  ---@type string[]
        adjacencyHeadline = {}, ---@type string[]
        citizenYields  = {},  ---@type string[]
        failures       = {},  ---@type string[]
        bonuses        = {},  ---@type string[]
        requirements   = {},  ---@type string[]
        unlocks        = {},  ---@type string[]
    }
end

local function ExtractFailureReasons(item)
    local out = {}
    if not item or not item.ToolTip then return out end
    for reason in string.gmatch(item.ToolTip, "%[COLOR:Red%](.-)%[ENDCOLOR%]") do
        local t = string.gsub(reason, "%[NEWLINE%]", " ")
        t = string.gsub(t, "^%s*(.-)%s*$", "%1")
        if t ~= "" then table.insert(out, t) end
    end
    return out
end

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
local function BuildUnitDetail(item, formation)
    local d = NewDetail()
    local def = item.Type and GameInfo.Units[item.Type] or nil
    if not def then return d end

    local cost = item.Cost
    if formation == "corps" then cost = item.CorpsCost
    elseif formation == "army" then cost = item.ArmyCost end
    SetCost(d, cost, item.Yield)
    if item.TurnsLeft and item.TurnsLeft >= 0 then d.turnsLeft = item.TurnsLeft end

    if def.Description and def.Description ~= "" then
        d.description = Locale.Lookup(def.Description)
    end

    local promo = def.PromotionClass and GameInfo.UnitPromotionClasses[def.PromotionClass] or nil
    if promo and promo.Name and not (def.UnitType and string.find(def.UnitType, "UNIT_HERO")) then
        table.insert(d.stats, Locale.Lookup("LOC_UNIT_PROMOTION_CLASS", promo.Name))
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
local function BuildBuildingDetail(item)
    local d = NewDetail()
    local def = item.Type and GameInfo.Buildings[item.Type] or nil
    if not def then return d end

    SetCost(d, item.Cost, item.Yield)
    if item.TurnsLeft and item.TurnsLeft >= 0 then d.turnsLeft = item.TurnsLeft end
    if def.Description and def.Description ~= "" then
        d.description = Locale.Lookup(def.Description)
    end
    SetMaintenance(d, def.Maintenance)

    local bt = def.BuildingType
    for row in GameInfo.Building_YieldChanges() do
        if row.BuildingType == bt then
            local line = FormatYieldChange(row.YieldChange, row.YieldType)
            if line then table.insert(d.bonuses, line) end
        end
    end
    if def.Housing and def.Housing ~= 0 then
        table.insert(d.bonuses, Locale.Lookup("LOC_TYPE_TRAIT_HOUSING", def.Housing))
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
    for row in GameInfo.Building_CitizenYieldChanges() do
        if row.BuildingType == bt then
            local line = FormatYieldChange(row.YieldChange, row.YieldType)
            if line then table.insert(d.citizenYields, line) end
        end
    end

    if def.RequiresReligion then
        local req = Locale.Lookup("LOC_TOOLTIP_PLACEMENT_REQUIRES_RELIGION")
        local pPlayer = Players[Game.GetLocalPlayer()]
        local pReligion = pPlayer and pPlayer:GetReligion() or nil
        local religionType = pReligion and pReligion:GetReligionTypeCreated() or -1
        if religionType ~= -1 then
            local relRow = GameInfo.Religions[religionType]
            if relRow and relRow.Name then
                req = req .. " " .. Locale.Lookup(relRow.Name)
            end
        end
        table.insert(d.requirements, req)
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
    for row in GameInfo.BuildingPrereqs() do
        if row.Building == bt then
            local pre = GameInfo.Buildings[row.PrereqBuilding]
            if pre then
                local preD = GameInfo.Districts[pre.PrereqDistrict]
                if preD and preD.DistrictType ~= "DISTRICT_CITY_CENTER"
                    and preD.DistrictType ~= def.PrereqDistrict then
                    table.insert(d.requirements, Locale.Lookup(
                        "LOC_TOOLTIP_BUILDING_REQUIRES_BUILDING_WITH_DISTRICT", pre.Name, preD.Name))
                else
                    table.insert(d.requirements, Locale.Lookup(
                        "LOC_TOOLTIP_BUILDING_REQUIRES_BUILDING", pre.Name))
                end
            end
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
local function BuildDistrictDetail(item)
    local d = NewDetail()
    local def = item.Type and GameInfo.Districts[item.Type] or nil
    if not def then return d end

    SetCost(d, item.Cost, item.Yield)
    if item.TurnsLeft and item.TurnsLeft >= 0 then d.turnsLeft = item.TurnsLeft end
    if def.Description and def.Description ~= "" then
        d.description = Locale.Lookup(def.Description)
    end
    SetMaintenance(d, def.Maintenance)

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
            if #lines > 0 and #lines <= 2 then
                for _, line in ipairs(lines) do table.insert(d.adjacencyHeadline, line) end
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
local function BuildProjectDetail(item)
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

local function BuildItemDetail(item, formation, tab)
    local class = GetProductionItemClass(item)
    local d
    if class == "unit" then d = BuildUnitDetail(item, formation)
    elseif class == "building" then d = BuildBuildingDetail(item)
    elseif class == "district" then d = BuildDistrictDetail(item)
    elseif class == "project" then d = BuildProjectDetail(item)
    else d = NewDetail() end

    if item and item.Repair then d.repairNeeded = true end

    -- Affordability for purchase tabs: any failure with "[ICON_Gold]"/"[ICON_Faith]" suggests
    -- can't afford; we treat the row being disabled on purchase tab as "cannot afford" only if
    -- there are no other failure reasons.
    local failures = ExtractFailureReasons(item)
    for _, f in ipairs(failures) do table.insert(d.failures, f) end

    if tab == TAB.PURCHASE_GOLD or tab == TAB.PURCHASE_FAITH then
        d.turnsLeft = nil
        if item and item.Disabled then d.cannotAfford = true end
    end

    -- In-progress partial build (for non-current items already partly built)
    if item and item.Progress and item.Cost and item.Cost > 0 then
        local pct = math.floor(item.Progress / item.Cost * 100 + 0.5)
        if pct > 0 and pct < 100 then d.progressPct = pct end
    end

    return d
end

-- Resolve current production item shape (reuses BuildItemDetail dispatch).
local function GetCurrentProductionItem()
    if not m_state.data or not m_state.data.City then return nil end
    local pCity = m_state.data.City
    local pBQ = pCity.GetBuildQueue and pCity:GetBuildQueue() or nil
    if not pBQ then return nil end

    local hash = pBQ:GetCurrentProductionTypeHash()
    if hash == 0 and pBQ.GetPreviousProductionTypeHash then hash = pBQ:GetPreviousProductionTypeHash() end
    if hash == 0 then return nil end

    local function build(typeName, costFn, progressFn)
        local item = { Hash = hash, Type = typeName }
        if costFn then item.Cost = costFn() end
        if progressFn then item.Progress = progressFn() end
        local turns = pBQ:GetTurnsLeft(hash)
        if type(turns) == "number" and turns >= 0 then item.TurnsLeft = turns end
        return item
    end

    local b = GameInfo.Buildings[hash]
    if b then
        return build(b.BuildingType,
            function() return pBQ:GetBuildingCost(b.Index) end,
            function() return pBQ:GetBuildingProgress(b.Index) end)
    end
    local dInfo = GameInfo.Districts[hash]
    if dInfo then
        return build(dInfo.DistrictType,
            function() return pBQ:GetDistrictCost(dInfo.Index) end,
            function() return pBQ:GetDistrictProgress(dInfo.Index) end)
    end
    local u = GameInfo.Units[hash]
    if u then
        local item = build(u.UnitType,
            function() return pBQ:GetUnitCost(u.Index) end,
            function() return pBQ:GetUnitProgress(u.Index) end)
        local formation
        local fmt = pBQ:GetCurrentProductionTypeModifier()
        if MilitaryFormationTypes then
            if fmt == MilitaryFormationTypes.CORPS_FORMATION then formation = "corps"
            elseif fmt == MilitaryFormationTypes.ARMY_FORMATION then formation = "army" end
        end
        return item, formation
    end
    local p = GameInfo.Projects[hash]
    if p then
        return build(p.ProjectType,
            function() return pBQ:GetProjectCost(p.Index) end,
            function() return pBQ:GetProjectProgress(p.Index) end)
    end
    return nil
end

-- ===========================================================================
-- Tooltip / details formatting
-- ===========================================================================
local function FormatCostLine(detail)
    if not detail.cost or not detail.costYield then return nil end
    if detail.costYield == "YIELD_GOLD" then
        return Locale.Lookup("LOC_CAI_PRODUCTION_COST_GOLD", detail.cost)
    elseif detail.costYield == "YIELD_FAITH" then
        return Locale.Lookup("LOC_CAI_PRODUCTION_COST_FAITH", detail.cost)
    end
    return Locale.Lookup("LOC_CAI_PRODUCTION_COST_PRODUCTION", detail.cost)
end

-- A bucket with a single entry collapses into the tooltip; >1 entries are
-- emitted as a TreeItem child whose own children carry the individual lines.
local function BucketIsInline(lines) return lines and #lines <= 1 end

local function FormatTooltip(detail)
    local parts = {}
    if detail.alreadyBuilt then AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_PRODUCTION_ALREADY_BUILT")) end
    if detail.repairNeeded then AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_PRODUCTION_REPAIR_NEEDED")) end
    AppendIfNonEmpty(parts, FormatCostLine(detail))
    if detail.turnsLeft and detail.turnsLeft > 0 then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_PRODUCTION_TURNS", detail.turnsLeft))
    end
    if detail.cannotAfford then AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_PRODUCTION_CANNOT_AFFORD")) end
    if detail.progressPct then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_PRODUCTION_PROGRESS", detail.progressPct))
    end
    AppendIfNonEmpty(parts, detail.maintenance)
    AppendIfNonEmpty(parts, detail.resourceUpkeep)
    AppendIfNonEmpty(parts, detail.description)
    for _, s in ipairs(detail.stats) do AppendIfNonEmpty(parts, s) end
    for _, a in ipairs(detail.adjacencyHeadline) do AppendIfNonEmpty(parts, a) end
    for _, c in ipairs(detail.citizenYields) do AppendIfNonEmpty(parts, c) end
    if BucketIsInline(detail.bonuses) then
        for _, b in ipairs(detail.bonuses) do AppendIfNonEmpty(parts, b) end
    end
    if BucketIsInline(detail.requirements) then
        for _, r in ipairs(detail.requirements) do AppendIfNonEmpty(parts, r) end
    end
    if BucketIsInline(detail.unlocks) then
        for _, u in ipairs(detail.unlocks) do AppendIfNonEmpty(parts, u) end
    end
    for _, f in ipairs(detail.failures) do AppendIfNonEmpty(parts, f) end
    return table.concat(parts, ", ")
end

local function CreateDetailChild(focusKeyPrefix, labelTag, lines)
    local child = mgr:CreateWidget(mgr:GenerateWidgetId("CAIProductionPanelDetail"), "TreeItem", {
        Label    = function() return Locale.Lookup(labelTag) end,
        Tooltip  = function() return table.concat(lines, ", ") end,
        FocusKey = focusKeyPrefix,
    })
    for i, line in ipairs(lines) do
        local leaf = mgr:CreateWidget(mgr:GenerateWidgetId("CAIProductionPanelDetailLeaf"), "TreeItem", {
            Label    = function() return line end,
            FocusKey = focusKeyPrefix .. ":" .. i,
        })
        child:AddChild(leaf)
    end
    return child
end

local function AddItemDetailChildren(row, detail)
    if not BucketIsInline(detail.bonuses) then
        row:AddChild(CreateDetailChild("detail:bonuses",
            "LOC_CAI_PRODUCTION_BONUSES_LABEL", detail.bonuses))
    end
    if not BucketIsInline(detail.requirements) then
        row:AddChild(CreateDetailChild("detail:requirements",
            "LOC_CAI_PRODUCTION_REQUIREMENTS_LABEL", detail.requirements))
    end
    if not BucketIsInline(detail.unlocks) then
        row:AddChild(CreateDetailChild("detail:unlocks",
            "LOC_CAI_PRODUCTION_UNLOCKS_LABEL", detail.unlocks))
    end
end

-- ===========================================================================
-- Row labels
-- ===========================================================================
local function ReadRowName(item, formation)
    local kInst = GetInstanceForItem(item, m_state.activeTab)
    local name = ""
    if kInst and kInst.LabelText and kInst.LabelText.GetText then
        name = kInst.LabelText:GetText() or ""
    end
    if name == "" or string.find(name, "%[NEWLINE%]") then
        name = Locale.Lookup(item.Name or "")
    end
    return name
end

local function FormatRowLabel(item, formation, tab)
    local parts = {}
    AppendIfNonEmpty(parts, WithFormationSuffix(ReadRowName(item, formation), formation))
    if not formation and m_state.recommended[item.Hash]
        and not IsItemRowDisabled(item, tab, formation) then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_RESEARCH_RECOMMENDED"))
    end
    return table.concat(parts, ", ")
end

-- ===========================================================================
-- Activation
-- ===========================================================================
local function InvokeRightClickPedia(item)
    if IsProductionTutorialMode() or not item or not item.Type then return false end
    RightClickProductionItem(item.Type)
    return true
end

local function PerformItemLeftClick(item, tab, formation)
    local inst = GetInstanceForItem(item, tab)
    local btn = GetInstanceActionControl(inst, formation)
    if btn and btn.DoLeftClick then
        btn:DoLeftClick()
        return true
    end
    return false
end

local function SpeakQueuedProduction(item, formation)
    if not item or not item.Name then return end
    local spoken = Locale.Lookup(item.Name)
    if formation then spoken = WithFormationSuffix(spoken, formation) end
    if spoken ~= "" then Speak(Locale.Lookup("LOC_CAI_PRODUCTION_QUEUED", spoken)) end
end

local function BuildItemQueueAction(item, tab, formation)
    return function()
        if tab ~= TAB.PRODUCTION then return false end
        CloseManager()
        OpenQueue()
        m_state.isQueueActionActive = true
        PerformItemLeftClick(item, tab, formation)
        m_state.isQueueActionActive = false
        CloseQueue()
        SpeakQueuedProduction(item, formation)
        return true
    end
end

-- ===========================================================================
-- Row factories
-- ===========================================================================
local function CreateItemRow(item, tab, formation)
    local focusKey = string.format("item:%d:%s:%d", tab, formation or "base", item.Hash or -1)
    local row = mgr:CreateWidget(mgr:GenerateWidgetId("CAIProductionPanelRow"), "TreeItem", {
        Label             = function() return FormatRowLabel(item, formation, tab) end,
        Tooltip           = function() return FormatTooltip(BuildItemDetail(item, formation, tab)) end,
        HiddenPredicate   = function() return IsItemRowHidden(item, tab, formation) end,
        DisabledPredicate = function() return IsItemRowDisabled(item, tab, formation) end,
        FocusKey          = focusKey,
    })
    row:SetFocusSound("Main_Menu_Mouse_Over")

    row:On("activate", function(w)
        if w:IsDisabled() then return end
        PerformItemLeftClick(item, tab, formation)
    end)

    local bindings = {
        {
            Key     = Keys.VK_RETURN,
            IsShift = true,
            MSG     = KeyEvents.KeyUp,
            Action  = function() return InvokeRightClickPedia(item) ~= false end,
        },
    }
    if tab == TAB.PRODUCTION and CurrentTabSupportsQueue() then
        table.insert(bindings, {
            Key       = Keys.VK_RETURN,
            IsControl = true,
            MSG       = KeyEvents.KeyUp,
            Action    = function(w)
                if w.IsDisabled and w:IsDisabled() then return true end
                return BuildItemQueueAction(item, tab, formation)() ~= false
            end,
        })
    end
    row:AddInputBindings(bindings)

    AddItemDetailChildren(row, BuildItemDetail(item, formation, tab))
    return row
end

local function AddUnitEntry(parent, unit, tab)
    local hasCorps = unit.Corps and unit.CorpsCost and unit.CorpsCost > 0
    local hasArmy = unit.Army and unit.ArmyCost and unit.ArmyCost > 0
    if not hasCorps and not hasArmy then
        parent:AddChild(CreateItemRow(unit, tab, nil))
        return
    end

    local group = CreateItemRow(unit, tab, nil)
    if hasCorps then
        local corpsItem = setmetatable({
            Cost = unit.CorpsCost, TurnsLeft = unit.CorpsTurnsLeft,
            Progress = unit.CorpsProgress, Disabled = unit.CorpsDisabled,
        }, { __index = unit })
        group:AddChild(CreateItemRow(corpsItem, tab, "corps"))
    end
    if hasArmy then
        local armyItem = setmetatable({
            Cost = unit.ArmyCost, TurnsLeft = unit.ArmyTurnsLeft,
            Progress = unit.ArmyProgress, Disabled = unit.ArmyDisabled,
        }, { __index = unit })
        group:AddChild(CreateItemRow(armyItem, tab, "army"))
    end
    parent:AddChild(group)
end

-- ===========================================================================
-- Current production node (production tab + queue tab)
-- ===========================================================================
local function HasActiveCurrentProduction()
    if not m_state.data or not m_state.data.City then return false end
    local pBQ = m_state.data.City:GetBuildQueue(); if not pBQ then return false end
    return pBQ:GetCurrentProductionTypeHash() ~= 0
end

local function ReadCurrentProductionLabel()
    if not HasActiveCurrentProduction() then
        return Locale.Lookup("LOC_PRODUCTION_MANAGER_NO_CURRENT_PRODUCTION")
    end
    local name = ControlText(Controls.CurrentProductionName)
    if name == "" then return Locale.Lookup("LOC_PRODUCTION_MANAGER_NO_CURRENT_PRODUCTION") end
    local status = ControlText(Controls.CurrentProductionStatus)
    if status ~= "" then return name .. ", " .. status end
    return name
end

local function ReadCurrentProductionTooltip()
    if not HasActiveCurrentProduction() then return "" end
    local item, formation = GetCurrentProductionItem()
    if not item then return "" end
    return FormatTooltip(BuildItemDetail(item, formation, TAB.PRODUCTION))
end

local function RemoveCurrentProductionFromQueue()
    if not HasActiveCurrentProduction() then return true end
    local name = ControlText(Controls.CurrentProductionName)
    if name == "" then return true end
    UI.PlaySound("Play_UI_Click")
    Speak(Locale.Lookup("LOC_CAI_PRODUCTION_CURRENT_REMOVED", name))
    RemoveQueueItem(0)
    return true
end

local function CreateCurrentProductionRow()
    local row = mgr:CreateWidget(mgr:GenerateWidgetId("CAIProductionPanelCurrent"), "TreeItem", {
        Label           = ReadCurrentProductionLabel,
        Tooltip         = ReadCurrentProductionTooltip,
        HiddenPredicate = function()
            return ControlIsHidden(Controls.CurrentProductionContainer)
                or ControlIsHidden(Controls.CurrentProductionButton)
        end,
        DisabledPredicate = function() return ControlIsDisabled(Controls.CurrentProductionButton) end,
        FocusKey        = "current",
    })
    row:SetFocusSound("Main_Menu_Mouse_Over")
    row:On("activate", function(w)
        if w:IsDisabled() then return end
        if ControlIsDisabled(Controls.CurrentProductionButton) then return end
        if Controls.CurrentProductionButton.DoLeftClick then
            Controls.CurrentProductionButton:DoLeftClick()
        end
    end)
    row:AddInputBindings({
        {
            Key    = Keys.VK_DELETE,
            MSG    = KeyEvents.KeyUp,
            Action = RemoveCurrentProductionFromQueue,
        },
    })
    return row
end

-- ===========================================================================
-- Category nodes
-- ===========================================================================
local function GetVanillaCategoryLabel(tab, categoryKey, fallback)
    local list = GetCategoryListForMode(GetListModeForTab(tab), categoryKey)
    if list and list.Header and list.Header.GetText then
        local t = list.Header:GetText()
        if t and t ~= "" then return t end
    end
    return Locale.Lookup(fallback)
end

local function IsVanillaListExpanded(list)
    if not list then return true end
    if list.HeaderOn and list.HeaderOn.IsHidden then
        return not list.HeaderOn:IsHidden()
    end
    if list.Header and list.Header.IsHidden then
        return list.Header:IsHidden()
    end
    return true
end

local m_categorySyncing = false

local function CreateCategoryNode(tab, categoryKey, fallbackLabelTag, focusKey)
    local node = mgr:CreateWidget(mgr:GenerateWidgetId("CAIProductionPanelCategory"), "TreeItem", {
        Label           = function() return GetVanillaCategoryLabel(tab, categoryKey, fallbackLabelTag) end,
        HiddenPredicate = function(w) return (w.Children == nil) or (#w.Children == 0) end,
        FocusKey        = focusKey,
    })
    node:SetFocusSound("Main_Menu_Mouse_Over")

    -- Initial state mirrors the live vanilla header. Set IsExpanded directly
    -- to seed silently; Expand()/Collapse() would emit the event back at us.
    local list = GetCategoryListForMode(GetListModeForTab(tab), categoryKey)
    node.IsExpanded = IsVanillaListExpanded(list)

    local function syncToVanilla(expand)
        if m_categorySyncing then return end
        local lst = GetCategoryListForMode(GetListModeForTab(tab), categoryKey)
        if not lst then return end
        if expand == IsVanillaListExpanded(lst) then return end
        m_categorySyncing = true
        if expand then OnExpand(lst) else OnCollapse(lst) end
        m_categorySyncing = false
    end
    node:On("expanded", function() syncToVanilla(true) end)
    node:On("collapsed", function() syncToVanilla(false) end)

    return node
end

local CATEGORY_SPECS = {
    [TAB.PRODUCTION] = {
        { key = "districts", label = "LOC_CAI_PRODUCTION_CATEGORY_DISTRICTS",  focusKey = "cat:districts" },
        { key = "wonders",   label = "LOC_CAI_PRODUCTION_CATEGORY_WONDERS",    focusKey = "cat:wonders" },
        { key = "projects",  label = "LOC_CAI_PRODUCTION_CATEGORY_PROJECTS",   focusKey = "cat:projects" },
        { key = "units",     label = "LOC_CAI_PRODUCTION_CATEGORY_UNITS",      focusKey = "cat:units" },
    },
    [TAB.PURCHASE_GOLD] = {
        { key = "districts", label = "LOC_CAI_PRODUCTION_CATEGORY_DISTRICTS",  focusKey = "cat:districts" },
        { key = "buildings", label = "LOC_CAI_PRODUCTION_CATEGORY_BUILDINGS",  focusKey = "cat:buildings" },
        { key = "units",     label = "LOC_CAI_PRODUCTION_CATEGORY_UNITS",      focusKey = "cat:units" },
    },
    [TAB.PURCHASE_FAITH] = {
        { key = "districts", label = "LOC_CAI_PRODUCTION_CATEGORY_DISTRICTS",  focusKey = "cat:districts" },
        { key = "buildings", label = "LOC_CAI_PRODUCTION_CATEGORY_BUILDINGS",  focusKey = "cat:buildings" },
        { key = "units",     label = "LOC_CAI_PRODUCTION_CATEGORY_UNITS",      focusKey = "cat:units" },
    },
}

local function GetItemsForTab(tab)
    local out = { Districts = {}, Buildings = {}, Wonders = {}, Projects = {}, Units = {} }
    if not m_state.data then return out end
    if tab == TAB.PRODUCTION then
        out.Districts = m_state.data.DistrictItems or {}
        out.Projects = m_state.data.ProjectItems or {}
        out.Units = m_state.data.UnitItems or {}
        for _, b in ipairs(m_state.data.BuildingItems or {}) do
            if b.IsWonder then table.insert(out.Wonders, b)
            else table.insert(out.Buildings, b) end
        end
    elseif tab == TAB.PURCHASE_GOLD or tab == TAB.PURCHASE_FAITH then
        local yield = tab == TAB.PURCHASE_GOLD and "YIELD_GOLD" or "YIELD_FAITH"
        for _, d in ipairs(m_state.data.DistrictPurchases or {}) do
            if d.Yield == yield then table.insert(out.Districts, d) end
        end
        for _, b in ipairs(m_state.data.BuildingPurchases or {}) do
            if b.Yield == yield then table.insert(out.Buildings, b) end
        end
        for _, u in ipairs(m_state.data.UnitPurchases or {}) do
            if u.Yield == yield then table.insert(out.Units, u) end
        end
    end
    return out
end

-- ===========================================================================
-- Queue rows
-- ===========================================================================
local function MakeQueueEntryDescription(entry)
    if not entry then return "" end
    if entry.Directive == CityProductionDirectives.TRAIN and entry.UnitType then
        local def = GameInfo.Units[entry.UnitType]; if def then return Locale.Lookup(def.Name) end
    elseif entry.Directive == CityProductionDirectives.CONSTRUCT and entry.BuildingType then
        local def = GameInfo.Buildings[entry.BuildingType]; if def then return Locale.Lookup(def.Name) end
    elseif entry.Directive == CityProductionDirectives.ZONE and entry.DistrictType then
        local def = GameInfo.Districts[entry.DistrictType]; if def then return Locale.Lookup(def.Name) end
    elseif entry.Directive == CityProductionDirectives.PROJECT and entry.ProjectType then
        local def = GameInfo.Projects[entry.ProjectType]; if def then return Locale.Lookup(def.Name) end
    end
    return ""
end

local function GetQueueRowCount()
    if not m_state.data or not m_state.data.City then return 0 end
    local pBQ = m_state.data.City:GetBuildQueue(); if not pBQ then return 0 end
    local count = 0
    for i = 1, MAX_QUEUE_SIZE do
        if pBQ:GetAt(i) ~= nil then count = i end
    end
    return count
end

local function GetFocusedQueueRow()
    local f = mgr and mgr:GetFocusedWidget() or nil
    if f and f._caiQueueIndex then return f end
    return nil
end

local function GetFocusedQueueListIndex()
    local list = m_ui.pageTrees[TAB.QUEUE]
    if not list or not list.Children then return nil end
    local focused = mgr:GetFocusedWidget()
    for i, child in ipairs(list.Children) do
        if child == focused then return i end
    end
    return nil
end

local function RemoveFocusedQueueItem()
    local row = GetFocusedQueueRow()
    if not row or not row._caiQueueIndex then return false end
    m_state.queueFocusIndexAfterRebuild = GetFocusedQueueListIndex()
    UI.PlaySound("Play_UI_Click")
    Speak(Locale.Lookup("LOC_CAI_PRODUCTION_QUEUE_REMOVED", row._caiQueueName or ""))
    RemoveQueueItem(row._caiQueueIndex)
    return true
end

local function MoveQueueSelection(direction)
    local row = GetFocusedQueueRow()
    local idx = row and row._caiQueueIndex or -1
    local name = row and row._caiQueueName or ""
    if idx == -1 then return false end

    local target = idx + direction
    if target < 1 or target > GetQueueRowCount() then
        if name ~= "" then
            local key = direction < 0 and "LOC_CAI_PRODUCTION_QUEUE_ALREADY_FIRST" or "LOC_CAI_PRODUCTION_QUEUE_ALREADY_LAST"
            Speak(Locale.Lookup(key, name))
        end
        return true
    end

    local queueOffset = HasActiveCurrentProduction() and 1 or 0
    m_state.queueFocusIndexAfterRebuild = target + queueOffset
    SwapQueueItem(idx, target)
    if name ~= "" then
        local key = direction < 0 and "LOC_CAI_PRODUCTION_QUEUE_MOVED_UP" or "LOC_CAI_PRODUCTION_QUEUE_MOVED_DOWN"
        Speak(Locale.Lookup(key, name))
    end
    return true
end

local function CreateQueueRow(queueIndex, name)
    local row = mgr:CreateWidget(mgr:GenerateWidgetId("CAIProductionPanelQueueRow"), "Button", {
        Label    = function() return name end,
        FocusKey = "queue:" .. tostring(queueIndex),
    })
    row:SetFocusSound("Main_Menu_Mouse_Over")
    row._caiQueueIndex = queueIndex
    row._caiQueueName = name
    row:AddInputBindings({
        { Key = Keys.VK_DELETE, MSG = KeyEvents.KeyUp, Action = RemoveFocusedQueueItem },
        {
            Key = Keys.VK_UP, IsShift = true, MSG = KeyEvents.KeyDown,
            Action = function() return MoveQueueSelection(-1) end,
        },
        {
            Key = Keys.VK_DOWN, IsShift = true, MSG = KeyEvents.KeyDown,
            Action = function() return MoveQueueSelection(1) end,
        },
    })
    return row
end

local function CreateQueueCurrentRow()
    local row = mgr:CreateWidget(mgr:GenerateWidgetId("CAIProductionPanelQueueCurrent"), "Button", {
        Label    = ReadCurrentProductionLabel,
        Tooltip  = ReadCurrentProductionTooltip,
        FocusKey = "current",
    })
    row:SetFocusSound("Main_Menu_Mouse_Over")
    row:AddInputBindings({
        { Key = Keys.VK_DELETE, MSG = KeyEvents.KeyUp, Action = RemoveCurrentProductionFromQueue },
    })
    return row
end

-- ===========================================================================
-- Rebuild
-- ===========================================================================
local function RebuildTreePage(tab)
    local tree = m_ui.pageTrees[tab]; if not tree then return end
    local capture = mgr:CaptureFocusKey(tree)
    tree:ClearChildren()
    m_ui.categoryNodes[tab] = {}

    if tab == TAB.PRODUCTION then
        tree:AddChild(CreateCurrentProductionRow())
    end

    local items = GetItemsForTab(tab)
    for _, spec in ipairs(CATEGORY_SPECS[tab] or {}) do
        local node = CreateCategoryNode(tab, spec.key, spec.label, spec.focusKey)
        local sourceKey = ({
            districts = "Districts", wonders = "Wonders", projects = "Projects",
            buildings = "Buildings", units = "Units",
        })[spec.key]
        local sourceItems = items[sourceKey] or {}

        if spec.key == "units" then
            for _, u in ipairs(sourceItems) do AddUnitEntry(node, u, tab) end
        else
            for _, it in ipairs(sourceItems) do node:AddChild(CreateItemRow(it, tab, nil)) end
            if tab == TAB.PRODUCTION and spec.key == "districts" then
                for _, b in ipairs(items.Buildings or {}) do
                    node:AddChild(CreateItemRow(b, tab, nil))
                end
            end
        end

        m_ui.categoryNodes[tab][spec.key] = node
        tree:AddChild(node)
    end

    mgr:RestoreFocus(tree, capture)
end

local function RebuildQueuePage()
    local list = m_ui.pageTrees[TAB.QUEUE]; if not list then return end
    local capture = mgr:CaptureFocusKey(list)
    list:ClearChildren()

    if m_state.data and m_state.data.City then
        if HasActiveCurrentProduction() then
            list:AddChild(CreateQueueCurrentRow())
        end
        local pBQ = m_state.data.City:GetBuildQueue()
        if pBQ then
            for i = 1, MAX_QUEUE_SIZE do
                local e = pBQ:GetAt(i)
                if e then
                    local desc = MakeQueueEntryDescription(e)
                    if desc ~= "" then list:AddChild(CreateQueueRow(i, desc)) end
                end
            end
        end
    end

    if m_state.queueFocusIndexAfterRebuild then
        local idx = m_state.queueFocusIndexAfterRebuild
        m_state.queueFocusIndexAfterRebuild = nil
        if list.Children and list.Children[idx] then
            mgr:SetFocus(list.Children[idx])
            return
        end
    end
    mgr:RestoreFocus(list, capture)
end

local function RefreshActivePage()
    if m_state.activeTab == TAB.QUEUE then RebuildQueuePage()
    else RebuildTreePage(m_state.activeTab) end
end

local function RefreshAllPages()
    for tab, _ in pairs(m_ui.pageTrees) do
        if tab == TAB.QUEUE then RebuildQueuePage()
        else RebuildTreePage(tab) end
    end
end

-- ===========================================================================
-- Recommendations
-- ===========================================================================
local function RefreshRecommendations()
    m_state.recommended = {}
    if not m_state.data or not m_state.data.City then return end
    local ai = m_state.data.City:GetCityAI()
    local recs = ai and ai:GetBuildRecommendations() or {}
    for _, kItem in ipairs(recs) do
        m_state.recommended[kItem.BuildItemHash] = true
    end
end

-- ===========================================================================
-- Tab switching
-- ===========================================================================
local m_settingTab = false

local function GetPageIdForTab(tab)
    if tab == TAB.PRODUCTION then return PAGE_PROD_ID end
    if tab == TAB.PURCHASE_GOLD then return PAGE_GOLD_ID end
    if tab == TAB.PURCHASE_FAITH then return PAGE_FAITH_ID end
    return PAGE_QUEUE_ID
end

local function SetCAITabSilent(tab)
    if not m_ui.tabs or m_settingTab then return end
    if m_state.activeTab == tab then return end
    m_state.activeTab = tab
    m_settingTab = true
    m_ui.tabs:SetActivePageById(GetPageIdForTab(tab), true)
    m_settingTab = false
end

-- ===========================================================================
-- Panel build
-- ===========================================================================
local function EnsurePanelBuilt()
    if m_ui.panel then return end

    m_ui.panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function() return Locale.Lookup("LOC_CAI_PRODUCTION_PANEL_TITLE") end,
    })

    m_ui.tabs = mgr:CreateWidget(TABS_ID, "TabControl", {
        Label = function() return Locale.Lookup("LOC_CAI_PRODUCTION_PANEL_TITLE") end,
    })
    m_ui.panel:AddChild(m_ui.tabs)

    local function MakeTreePage(pageId, labelTag, tab)
        local page = m_ui.tabs:AddPage(function() return Locale.Lookup(labelTag) end)
        page.Id = pageId
        m_ui.pages[tab] = page

        local tree = mgr:CreateWidget(mgr:GenerateWidgetId("CAIProductionPanelTree"), "Tree", {
            Label       = function() return Locale.Lookup(labelTag) end,
            SearchDepth = 2,
        })
        page:AddChild(tree)
        m_ui.pageTrees[tab] = tree
    end

    MakeTreePage(PAGE_PROD_ID, "LOC_CAI_PRODUCTION_TAB_PRODUCTION", TAB.PRODUCTION)

    if GameCapabilities.HasCapability("CAPABILITY_GOLD") then
        MakeTreePage(PAGE_GOLD_ID, "LOC_CAI_PRODUCTION_TAB_PURCHASE_GOLD", TAB.PURCHASE_GOLD)
    end
    if GameCapabilities.HasCapability("CAPABILITY_FAITH") then
        MakeTreePage(PAGE_FAITH_ID, "LOC_CAI_PRODUCTION_TAB_PURCHASE_FAITH", TAB.PURCHASE_FAITH)
    end

    local queuePage = m_ui.tabs:AddPage(function() return Locale.Lookup("LOC_CAI_PRODUCTION_TAB_QUEUE") end)
    queuePage.Id = PAGE_QUEUE_ID
    m_ui.pages[TAB.QUEUE] = queuePage
    local queueList = mgr:CreateWidget(mgr:GenerateWidgetId("CAIProductionPanelQueueList"), "List", {
        Label = function() return Locale.Lookup("LOC_CAI_PRODUCTION_QUEUE_LIST") end,
    })
    queuePage:AddChild(queueList)
    m_ui.pageTrees[TAB.QUEUE] = queueList

    m_ui.tabs:On("value_changed", function(_, pageIdx)
        if m_settingTab then return end
        local page = m_ui.tabs:GetPage(pageIdx)
        if not page then return end
        m_settingTab = true
        if page.Id == PAGE_PROD_ID then
            m_state.activeTab = TAB.PRODUCTION; OnTabChangeProduction()
        elseif page.Id == PAGE_GOLD_ID then
            m_state.activeTab = TAB.PURCHASE_GOLD; OnTabChangePurchase()
        elseif page.Id == PAGE_FAITH_ID then
            m_state.activeTab = TAB.PURCHASE_FAITH; OnTabChangePurchaseFaith()
        elseif page.Id == PAGE_QUEUE_ID then
            m_state.activeTab = TAB.QUEUE; OnTabChangeQueue()
        end
        m_settingTab = false
    end)
end

-- ===========================================================================
-- Lifecycle
-- ===========================================================================
local function PushPanelIfNeeded()
    if not m_ui.panel or not mgr then return end
    if mgr:GetWidgetById(PANEL_ID) then return end
    mgr:Push(m_ui.panel, { priority = PopupPriority.Low,
        focus = m_ui.pageTrees[m_state.activeTab] })
end

local function OnPanelOpenedCAI()
    m_state.openPending = true
    EnsurePanelBuilt()
    if mgr:GetWidgetById(PANEL_ID) then return end
end

local function OnPanelClosedCAI()
    if m_ui.panel and mgr and mgr:GetWidgetById(PANEL_ID) then
        mgr:RemoveFromStack(PANEL_ID)
    end
    m_ui = { panel = nil, tabs = nil, pages = {}, pageTrees = {}, categoryNodes = {} }
    m_state.data = nil
    m_state.openPending = false
    m_state.recommended = {}
    m_state.isQueueActionActive = false
    m_state.queueFocusIndexAfterRebuild = nil
    m_state.activeTab = TAB.PRODUCTION
    m_vanilla = {
        instanceByHash = {}, instancesByModeHash = {},
        categoryListsByMode = {}, captureListMode = nil,
    }
end

local function OnVanillaListModeChangedCAI(listMode)
    local tab = GetTabForListMode(listMode)
    SetCAITabSilent(tab)
    if m_ui.panel then RefreshActivePage() end
    if m_state.openPending then
        PushPanelIfNeeded()
        m_state.openPending = false
    end
end

-- ===========================================================================
-- Wraps
-- ===========================================================================
PopulateGenericItemData = WrapFunc(PopulateGenericItemData, function(orig, kInstance, kItem)
    orig(kInstance, kItem)
    if kItem and kItem.Hash then
        m_vanilla.instanceByHash[kItem.Hash] = kInstance
        if m_vanilla.captureListMode then
            m_vanilla.instancesByModeHash[m_vanilla.captureListMode] =
                m_vanilla.instancesByModeHash[m_vanilla.captureListMode] or {}
            m_vanilla.instancesByModeHash[m_vanilla.captureListMode][kItem.Hash] = kInstance
        end
    end
end)

PopulateList = WrapFunc(PopulateList, function(orig, data, listMode, listIM)
    m_vanilla.captureListMode = listMode
    orig(data, listMode, listIM)
    m_vanilla.captureListMode = nil
end)

local function WrapCategoryCapture(origFunc, categoryFn)
    return WrapFunc(origFunc, function(orig, data, listMode, listIM)
        local before = listIM.m_iAllocatedInstances or 0
        orig(data, listMode, listIM)
        local after = listIM.m_iAllocatedInstances or 0
        for i = before + 1, after do
            local inst = listIM.m_AllocatedInstances[i]
            if inst then categoryFn(inst, i - before) end
        end
    end)
end

PopulateWonders = WrapCategoryCapture(PopulateWonders, function(inst)
    SetCategoryListForMode(m_vanilla.captureListMode, "wonders", inst)
end)
PopulateProjects = WrapCategoryCapture(PopulateProjects, function(inst)
    SetCategoryListForMode(m_vanilla.captureListMode, "projects", inst)
end)
PopulateUnits = WrapCategoryCapture(PopulateUnits, function(inst)
    SetCategoryListForMode(m_vanilla.captureListMode, "units", inst)
end)
PopulateDistrictsWithNestedBuildings = WrapCategoryCapture(PopulateDistrictsWithNestedBuildings, function(inst)
    SetCategoryListForMode(m_vanilla.captureListMode, "districts", inst)
end)
PopulateDistrictsWithoutNestedBuildings = WrapCategoryCapture(PopulateDistrictsWithoutNestedBuildings,
    function(inst, idx)
        if idx == 1 then SetCategoryListForMode(m_vanilla.captureListMode, "districts", inst)
        else SetCategoryListForMode(m_vanilla.captureListMode, "buildings", inst) end
    end)

View = WrapFunc(View, function(orig, data)
    m_vanilla.instanceByHash = {}
    m_vanilla.instancesByModeHash = {}
    m_vanilla.categoryListsByMode = {}
    m_vanilla.captureListMode = nil

    m_state.data = data
    orig(data)
    RefreshRecommendations()

    if not m_ui.panel and not m_state.openPending then return end

    EnsurePanelBuilt()
    if not m_state.openPending then RefreshAllPages() end
end)

local function FindCategoryNodeByInstance(instance)
    for listMode, byKey in pairs(m_vanilla.categoryListsByMode) do
        for key, inst in pairs(byKey) do
            if inst == instance then
                local tab = GetTabForListMode(listMode)
                local byTab = m_ui.categoryNodes[tab]
                return byTab and byTab[key] or nil
            end
        end
    end
    return nil
end

OnExpand = WrapFunc(OnExpand, function(orig, instance)
    orig(instance)
    if m_categorySyncing then return end
    local node = FindCategoryNodeByInstance(instance)
    if node and not node.IsExpanded then
        m_categorySyncing = true
        node:Expand()
        m_categorySyncing = false
    end
end)

OnCollapse = WrapFunc(OnCollapse, function(orig, instance)
    orig(instance)
    if m_categorySyncing then return end
    local node = FindCategoryNodeByInstance(instance)
    if node and node.IsExpanded then
        m_categorySyncing = true
        node:Collapse()
        m_categorySyncing = false
    end
end)

OnCorpsToggle = WrapFunc(OnCorpsToggle, function(orig, unitList, unitListing)
    orig(unitList, unitListing)
    if m_ui.panel and mgr and mgr:GetWidgetById(PANEL_ID)
        and m_state.activeTab ~= TAB.QUEUE then
        RefreshActivePage()
    end
end)

OnTabChangeProduction = WrapFunc(OnTabChangeProduction, function(orig)
    orig()
    SetCAITabSilent(TAB.PRODUCTION)
    if m_ui.panel then RefreshActivePage() end
end)
OnTabChangePurchase = WrapFunc(OnTabChangePurchase, function(orig)
    orig()
    SetCAITabSilent(TAB.PURCHASE_GOLD)
    if m_ui.panel then RefreshActivePage() end
end)
OnTabChangePurchaseFaith = WrapFunc(OnTabChangePurchaseFaith, function(orig)
    orig()
    SetCAITabSilent(TAB.PURCHASE_FAITH)
    if m_ui.panel then RefreshActivePage() end
end)
OnTabChangeQueue = WrapFunc(OnTabChangeQueue, function(orig)
    orig()
    SetCAITabSilent(TAB.QUEUE)
    if m_ui.panel then RefreshActivePage() end
end)

OnCityPanelChooseProduction = WrapFunc(OnCityPanelChooseProduction, function(orig)
    SetCAITabSilent(TAB.PRODUCTION); orig()
end)
OnCityPanelChoosePurchase = WrapFunc(OnCityPanelChoosePurchase, function(orig)
    SetCAITabSilent(TAB.PURCHASE_GOLD); orig()
end)
OnCityPanelChoosePurchaseFaith = WrapFunc(OnCityPanelChoosePurchaseFaith, function(orig)
    SetCAITabSilent(TAB.PURCHASE_FAITH); orig()
end)
OnCityPanelPurchaseGoldOpen = WrapFunc(OnCityPanelPurchaseGoldOpen, function(orig)
    SetCAITabSilent(TAB.PURCHASE_GOLD); orig()
end)
OnCityPanelPurchaseFaithOpen = WrapFunc(OnCityPanelPurchaseFaithOpen, function(orig)
    SetCAITabSilent(TAB.PURCHASE_FAITH); orig()
end)
OnProductionOpenForQueue = WrapFunc(OnProductionOpenForQueue, function(orig)
    SetCAITabSilent(TAB.QUEUE); orig()
end)

-- Speech wraps
BuildBuilding = WrapFunc(BuildBuilding, function(orig, city, entry)
    if not m_state.isQueueActionActive and entry and entry.Name then
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_CHOSEN", Locale.Lookup(entry.Name)))
    end
    orig(city, entry)
end)
ZoneDistrict = WrapFunc(ZoneDistrict, function(orig, city, entry)
    if not m_state.isQueueActionActive and entry and entry.Name then
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_CHOSEN", Locale.Lookup(entry.Name)))
    end
    orig(city, entry)
end)
BuildUnit = WrapFunc(BuildUnit, function(orig, city, entry)
    if not m_state.isQueueActionActive and entry and entry.Name then
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_CHOSEN", Locale.Lookup(entry.Name)))
    end
    orig(city, entry)
end)
BuildUnitCorps = WrapFunc(BuildUnitCorps, function(orig, city, entry)
    if not m_state.isQueueActionActive and entry and entry.Name then
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_CHOSEN",
            WithFormationSuffix(Locale.Lookup(entry.Name), "corps")))
    end
    orig(city, entry)
end)
BuildUnitArmy = WrapFunc(BuildUnitArmy, function(orig, city, entry)
    if not m_state.isQueueActionActive and entry and entry.Name then
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_CHOSEN",
            WithFormationSuffix(Locale.Lookup(entry.Name), "army")))
    end
    orig(city, entry)
end)
AdvanceProject = WrapFunc(AdvanceProject, function(orig, city, entry)
    if not m_state.isQueueActionActive and entry and entry.Name then
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_CHOSEN", Locale.Lookup(entry.Name)))
    end
    orig(city, entry)
end)
PurchaseUnit = WrapFunc(PurchaseUnit, function(orig, city, entry)
    if entry and entry.Name then
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_PURCHASED", Locale.Lookup(entry.Name)))
    end
    orig(city, entry)
end)
PurchaseUnitCorps = WrapFunc(PurchaseUnitCorps, function(orig, city, entry)
    if entry and entry.Name then
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_PURCHASED",
            WithFormationSuffix(Locale.Lookup(entry.Name), "corps")))
    end
    orig(city, entry)
end)
PurchaseUnitArmy = WrapFunc(PurchaseUnitArmy, function(orig, city, entry)
    if entry and entry.Name then
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_PURCHASED",
            WithFormationSuffix(Locale.Lookup(entry.Name), "army")))
    end
    orig(city, entry)
end)
PurchaseBuilding = WrapFunc(PurchaseBuilding, function(orig, city, entry)
    if entry and entry.Name then
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_PURCHASED", Locale.Lookup(entry.Name)))
    end
    orig(city, entry)
end)
PurchaseDistrict = WrapFunc(PurchaseDistrict, function(orig, city, entry)
    if entry and entry.Name then
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_PURCHASED", Locale.Lookup(entry.Name)))
    end
    orig(city, entry)
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
    if mgr and mgr:GetTop() ~= m_ui.panel then return orig(pInputStruct) end
    if mgr and mgr:HandleInput(pInputStruct) then return true end
    return orig(pInputStruct)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)

LuaEvents.ProductionPanel_Open.Add(OnPanelOpenedCAI)
LuaEvents.ProductionPanel_Close.Add(OnPanelClosedCAI)
LuaEvents.ProductionPanel_ListModeChanged.Add(OnVanillaListModeChangedCAI)

local function RefreshIfOpen()
    if m_ui.panel and mgr and mgr:GetWidgetById(PANEL_ID) and Refresh then
        Refresh()
    end
end
Events.CityProductionChanged.Add(RefreshIfOpen)
Events.CityProductionUpdated.Add(RefreshIfOpen)
Events.CityProductionQueueChanged.Add(RefreshIfOpen)
