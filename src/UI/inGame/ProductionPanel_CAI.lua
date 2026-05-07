include("caiUtils")
include("inGameHelpers_CAI")
include("ProductionPanel")
local mgr                              = ExposedMembers.CAI_UIManager

local LISTMODE                         = { PRODUCTION = 1, PURCHASE_GOLD = 2, PURCHASE_FAITH = 3, PROD_QUEUE = 4 }

local TAB_PRODUCTION                   = 1
local TAB_PURCHASE_GOLD                = 2
local TAB_PURCHASE_FAITH               = 3
local TAB_QUEUE                        = 4

local MAX_QUEUE_SIZE                   = 7

local m_caiPanel                       = nil ---@type UIWidget|nil
local m_caiTabBar                      = nil ---@type UIWidget|nil
local m_caiTabs                        = {} ---@type table<number, UIWidget>
local m_caiBody                        = nil ---@type UIWidget|nil

local m_caiData                        = nil ---@type table|nil
local m_caiTab                         = TAB_PRODUCTION
local m_caiOpenPending                 = false
local m_caiRecommended                 = {} ---@type table<number, boolean>
local m_caiQueueActionActive           = false
local m_caiQueueFocusIndexAfterRebuild = nil ---@type integer|nil
local m_caiLastBuiltTab                = nil ---@type integer|nil
local m_caiLastBuiltCityID             = nil ---@type integer|nil
local m_caiLastBuiltPlayerID           = nil ---@type integer|nil
local m_caiLastCurrentProductionHash   = nil ---@type integer|nil

local m_caiInstanceByHash              = {} ---@type table<number, table>
local m_caiInstancesByModeHash         = {} ---@type table<number, table<number, table>>
local m_caiWonderList                  = nil ---@type table|nil
local m_caiProjectList                 = nil ---@type table|nil
local m_caiDistrictList                = nil ---@type table|nil
local m_caiBuildingList                = nil ---@type table|nil
local m_caiUnitList                    = nil ---@type table|nil
local m_caiCaptureListMode             = nil ---@type integer|nil

function PlayMenuHover()
    UI.PlaySound("Main_Menu_Mouse_Over")
end

function WithFormationSuffix(name, formation)
    if formation == "corps" then
        return name .. " " .. Locale.Lookup("LOC_UNITFLAG_CORPS_SUFFIX")
    elseif formation == "army" then
        return name .. " " .. Locale.Lookup("LOC_UNITFLAG_ARMY_SUFFIX")
    end
    return name
end

function GetListModeForTab(tab)
    if tab == TAB_PRODUCTION then return LISTMODE.PRODUCTION end
    if tab == TAB_PURCHASE_GOLD then return LISTMODE.PURCHASE_GOLD end
    if tab == TAB_PURCHASE_FAITH then return LISTMODE.PURCHASE_FAITH end
    if NormalizeCAITab(tab) == TAB_QUEUE then return LISTMODE.PROD_QUEUE end
    return nil
end

function GetProductionItemClass(item)
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

function GetInstanceForItem(item, tab)
    if not item or not item.Hash then return nil end
    local listMode = GetListModeForTab(tab)
    local byMode = listMode and m_caiInstancesByModeHash[listMode] or nil
    if byMode and byMode[item.Hash] then
        return byMode[item.Hash]
    end
    return m_caiInstanceByHash[item.Hash]
end

function ControlIsHidden(control)
    return control and control.IsHidden and control:IsHidden() or false
end

function ControlIsDisabled(control)
    return control and control.IsDisabled and control:IsDisabled() or false
end

function GetInstanceActionControl(kInstance, formation)
    if not kInstance then return nil end
    if formation == "corps" then return kInstance.TrainCorpsButton or kInstance.Button end
    if formation == "army" then return kInstance.TrainArmyButton or kInstance.Button end
    return kInstance.Button
end

function GetInstanceContainerControl(kInstance, formation)
    if not kInstance then return nil end
    if formation == "corps" then return kInstance.CorpsButtonContainer or kInstance.Root end
    if formation == "army" then return kInstance.ArmyButtonContainer or kInstance.Root end
    return kInstance.Root
end

function IsItemRowHidden(item, tab, formation)
    local kInstance = GetInstanceForItem(item, tab)
    if not kInstance then return false end

    local container = GetInstanceContainerControl(kInstance, formation)
    local actionControl = GetInstanceActionControl(kInstance, formation)
    return ControlIsHidden(container) or ControlIsHidden(actionControl)
end

function IsItemRowDisabled(item, tab, formation)
    local dataDisabled = item and item.Disabled or false
    if formation == "corps" then dataDisabled = item and item.CorpsDisabled or false end
    if formation == "army" then dataDisabled = item and item.ArmyDisabled or false end

    local kInstance = GetInstanceForItem(item, tab)
    local actionControl = GetInstanceActionControl(kInstance, formation)
    return dataDisabled or ControlIsDisabled(actionControl)
end

function GetActiveProductionCity()
    local city = UI.GetHeadSelectedCity and UI.GetHeadSelectedCity() or nil
    if city then return city end
    if m_caiData and m_caiData.City then return m_caiData.City end
    return nil
end

function GetYieldIndex(yieldType)
    local yieldInfo = yieldType and GameInfo.Yields[yieldType] or nil
    return yieldInfo and yieldInfo.Index or nil
end

function RequestPurchaseUnit(city, item, formationType)
    if not city or not item or not item.Hash then return false end
    local yieldIndex = GetYieldIndex(item.Yield)
    if yieldIndex == nil then return false end

    local tParameters = {}
    tParameters[CityCommandTypes.PARAM_UNIT_TYPE] = item.Hash
    tParameters[CityCommandTypes.PARAM_MILITARY_FORMATION_TYPE] = formationType
    tParameters[CityCommandTypes.PARAM_YIELD_TYPE] = yieldIndex

    if item.Yield == "YIELD_GOLD" then
        UI.PlaySound("Purchase_With_Gold")
    else
        UI.PlaySound("Purchase_With_Faith")
    end

    CityManager.RequestCommand(city, CityCommandTypes.PURCHASE, tParameters)
    return true
end

function RequestPurchaseBuilding(city, item)
    if not city or not item or not item.Hash then return false end
    local yieldIndex = GetYieldIndex(item.Yield)
    if yieldIndex == nil then return false end

    local tParameters = {}
    tParameters[CityCommandTypes.PARAM_BUILDING_TYPE] = item.Hash
    tParameters[CityCommandTypes.PARAM_YIELD_TYPE] = yieldIndex

    if item.Yield == "YIELD_GOLD" then
        UI.PlaySound("Purchase_With_Gold")
    else
        UI.PlaySound("Purchase_With_Faith")
    end

    CityManager.RequestCommand(city, CityCommandTypes.PURCHASE, tParameters)
    return true
end

function RequestPurchaseDistrict(city, item)
    if not city or not item or not item.Hash or not item.Type then return false end
    local district = GameInfo.Districts[item.Type]
    local yieldIndex = GetYieldIndex(item.Yield)
    local pBuildQueue = city.GetBuildQueue and city:GetBuildQueue() or nil
    if not district or yieldIndex == nil or not pBuildQueue then return false end

    local bNeedsPlacement = district.RequiresPlacement
    if pBuildQueue.HasBeenPlaced and pBuildQueue:HasBeenPlaced(item.Hash) then
        bNeedsPlacement = false
    end

    local tParameters = {}
    tParameters[CityOperationTypes.PARAM_DISTRICT_TYPE] = item.Hash
    tParameters[CityCommandTypes.PARAM_YIELD_TYPE] = yieldIndex

    if bNeedsPlacement then
        UI.SetInterfaceMode(InterfaceModeTypes.DISTRICT_PLACEMENT, tParameters)
    else
        CityManager.RequestCommand(city, CityCommandTypes.PURCHASE, tParameters)
        if item.Yield == "YIELD_GOLD" then
            UI.PlaySound("Purchase_With_Gold")
        else
            UI.PlaySound("Purchase_With_Faith")
        end
    end

    return true
end

function CurrentTabSupportsQueue()
    return not m_isTutorialRunning and not m_tutorialTestMode
end

function IsProductionTutorialMode()
    local tutorialRunning = false
    if type(IsTutorialRunning) == "function" then
        tutorialRunning = IsTutorialRunning()
    end
    return tutorialRunning
        or m_isTutorialRunning == true
        or m_tutorialTestMode == true
end

function ReadRowLabel(item, formation)
    local kInstance = GetInstanceForItem(item, m_caiTab)
    local nameText = ""
    if kInstance and kInstance.LabelText and kInstance.LabelText.GetText then
        nameText = kInstance.LabelText:GetText() or ""
    end
    if nameText == "" then
        nameText = Locale.Lookup(item.Name or "")
    end

    local parts = {}
    AppendIfNonEmpty(parts, WithFormationSuffix(nameText, formation))
    if m_caiRecommended[item.Hash] and not formation then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_RECOMMENDED"))
    end
    return table.concat(parts, ", ")
end

-- ===========================================================================
-- Detail reconstruction from GameInfo
--
-- We deliberately avoid parsing vanilla's `ToolTipHelper.GetXxxToolTip` output
-- because that text format is irregular (units mix promotion class + stats
-- inline with description, strategic-resource bullets use uppercase
-- `[ICON_BULLET]` while citizen-yield bullets use lowercase `[ICON_Bullet]`,
-- etc.). Instead, mirror the same GameInfo accesses vanilla performs and emit
-- each piece into a structured bucket so the brief tooltip and expandable
-- breakdown can present them consistently.
-- ===========================================================================

function NewDetail()
    return {
        cost = nil,         -- single localized line
        description = {},   -- list of localized lines (prose + promotion class)
        maintenance = nil,  -- single localized line
        stats = {},         -- list (units only): combat, ranged, movement...
        requirements = {},  -- list (tech / civic / resource / district / ...)
        citizenYields = {}, -- list (buildings / districts)
        bonuses = {},       -- list (yields, housing, GP points, adjacency)
        failures = {},      -- list of vanilla [COLOR:Red] failure reasons
    }
end

-- Vanilla appends "[NEWLINE][NEWLINE][COLOR:Red]<reason>[ENDCOLOR]" for each
-- failure reason returned by CanProduce. Pull those back out of item.ToolTip.
local function ExtractFailureReasons(item)
    local out = {}
    if not item or not item.ToolTip then return out end
    for reason in string.gmatch(item.ToolTip, "%[COLOR:Red%](.-)%[ENDCOLOR%]") do
        local trimmed = string.gsub(reason, "%[NEWLINE%]", " ")
        trimmed = string.gsub(trimmed, "^%s*(.-)%s*$", "%1")
        if trimmed ~= "" then table.insert(out, trimmed) end
    end
    return out
end

local function YieldByType(yieldType)
    return GameInfo.Yields[yieldType]
end

local function FormatYieldChange(amount, yieldType)
    local yield = YieldByType(yieldType)
    if not yield then return nil end
    return Locale.Lookup("LOC_TYPE_TRAIT_YIELD", amount, yield.IconString, yield.Name)
end

local function AddCostLine(detail, cost, yieldType, turnsLeft)
    if not cost or cost <= 0 then return end
    local yield = YieldByType(yieldType or "YIELD_PRODUCTION")
    if not yield then return end
    local line = Locale.Lookup("LOC_TOOLTIP_BASE_COST", cost, yield.IconString, yield.Name)
    if turnsLeft and turnsLeft > 0 then
        line = line .. ", " .. Locale.Lookup("LOC_TURNS_REMAINING_VAL", turnsLeft)
    end
    detail.cost = line
end

local function AddMaintenanceLine(detail, maintenance, yieldType)
    if not maintenance or maintenance <= 0 then return end
    local yield = YieldByType(yieldType or "YIELD_GOLD")
    if not yield then return end
    detail.maintenance = Locale.Lookup("LOC_TOOLTIP_MAINTENANCE", maintenance, yield.IconString, yield.Name)
end

local function AddDescription(detail, descLocTag)
    if descLocTag and descLocTag ~= "" then
        AppendIfNonEmpty(detail.description, Locale.Lookup(descLocTag))
    end
end


-- ---------------------------------------------------------------------------
-- Units
-- ---------------------------------------------------------------------------

local function GetUnitDef(item)
    if not item or not item.Type then return nil end
    return GameInfo.Units[item.Type]
end

local function GetUnitFormationCost(item, formation)
    if formation == "corps" then return item.CorpsCost end
    if formation == "army" then return item.ArmyCost end
    return item.Cost
end

function BuildUnitDetail(item, formation)
    local detail = NewDetail()
    local def = GetUnitDef(item)
    if not def then return detail end

    AddCostLine(detail, GetUnitFormationCost(item, formation), item.Yield, item.TurnsLeft)
    AddDescription(detail, def.Description)

    local promoClass = def.PromotionClass and GameInfo.UnitPromotionClasses[def.PromotionClass] or nil
    if promoClass and promoClass.Name and not (def.UnitType and string.find(def.UnitType, "UNIT_HERO")) then
        AppendIfNonEmpty(detail.description,
            Locale.Lookup("LOC_UNIT_PROMOTION_CLASS", promoClass.Name))
    end

    AddMaintenanceLine(detail, def.Maintenance)

    -- Stats: mirror the same numbers vanilla shows, but always include movement
    -- and sight when the unit has them so the row reads consistently across
    -- unit types (vanilla skips movement for a few unit definitions).
    local function statLine(locKey, ...)
        AppendIfNonEmpty(detail.stats, Locale.Lookup(locKey, ...))
    end
    if def.Combat and def.Combat > 0 then
        statLine("LOC_UNIT_COMBAT_STRENGTH", def.Combat)
    end
    if def.RangedCombat and def.RangedCombat > 0 and def.Range and def.Range > 0 then
        statLine("LOC_UNIT_RANGED_STRENGTH", def.RangedCombat, def.Range)
    end
    if def.Bombard and def.Bombard > 0 and def.Range and def.Range > 0 then
        statLine("LOC_UNIT_BOMBARD_STRENGTH", def.Bombard, def.Range)
    end
    if UnitManager and UnitManager.GetUnitTypeBaseLifespan then
        local lifespan = UnitManager.GetUnitTypeBaseLifespan(def.Index)
        if lifespan and lifespan > 0 then
            statLine("LOC_UNIT_LIFESPAN", lifespan)
        end
    end
    if def.BaseMoves and def.BaseMoves > 0 then
        statLine("LOC_UNIT_MOVEMENT", def.BaseMoves)
    end
    if def.AirSlots and def.AirSlots ~= 0 then
        statLine("LOC_TYPE_TRAIT_AIRSLOTS", def.AirSlots)
    end

    if def.StrategicResource then
        local resource = GameInfo.Resources[def.StrategicResource]
        if resource then
            table.insert(detail.requirements,
                "[ICON_" .. resource.ResourceType .. "] " .. Locale.Lookup(resource.Name))
        end
    end

    return detail
end

-- ---------------------------------------------------------------------------
-- Buildings (covers Wonders too)
-- ---------------------------------------------------------------------------

local function GetBuildingDef(item)
    if not item or not item.Type then return nil end
    return GameInfo.Buildings[item.Type]
end

local function AddBuildingYields(detail, buildingType)
    for row in GameInfo.Building_YieldChanges() do
        if row.BuildingType == buildingType then
            local line = FormatYieldChange(row.YieldChange, row.YieldType)
            AppendIfNonEmpty(detail.bonuses, line)
        end
    end
end

local function AddBuildingCitizenYields(detail, buildingType)
    for row in GameInfo.Building_CitizenYieldChanges() do
        if row.BuildingType == buildingType then
            local line = FormatYieldChange(row.YieldChange, row.YieldType)
            AppendIfNonEmpty(detail.citizenYields, line)
        end
    end
end

local function AddBuildingGreatPersonPoints(detail, buildingType)
    for row in GameInfo.Building_GreatPersonPoints() do
        if row.BuildingType == buildingType then
            local cls = GameInfo.GreatPersonClasses[row.GreatPersonClassType]
            if cls then
                AppendIfNonEmpty(detail.bonuses,
                    Locale.Lookup("LOC_TYPE_TRAIT_GREAT_PERSON_POINTS",
                        row.PointsPerTurn, cls.IconString, cls.Name))
            end
        end
    end
end

function BuildBuildingDetail(item)
    local detail = NewDetail()
    local def = GetBuildingDef(item)
    if not def then return detail end

    AddCostLine(detail, item.Cost, item.Yield, item.TurnsLeft)
    AddDescription(detail, def.Description)
    AddMaintenanceLine(detail, def.Maintenance)

    local buildingType = def.BuildingType
    AddBuildingYields(detail, buildingType)

    if def.Housing and def.Housing ~= 0 then
        AppendIfNonEmpty(detail.bonuses, Locale.Lookup("LOC_TYPE_TRAIT_HOUSING", def.Housing))
    end
    if def.CitizenSlots and def.CitizenSlots ~= 0 then
        AppendIfNonEmpty(detail.bonuses, Locale.Lookup("LOC_TYPE_TRAIT_CITIZENS", def.CitizenSlots))
    end
    if def.OuterDefenseHitPoints and def.OuterDefenseHitPoints ~= 0 then
        AppendIfNonEmpty(detail.bonuses,
            Locale.Lookup("LOC_TYPE_TRAIT_OUTER_DEFENSE", def.OuterDefenseHitPoints))
    end
    AddBuildingGreatPersonPoints(detail, buildingType)
    AddBuildingCitizenYields(detail, buildingType)

    -- Requirements — mirror vanilla GetBuildingToolTip's reqLines composition.
    if def.RequiresReligion then
        table.insert(detail.requirements,
            Locale.Lookup("LOC_TOOLTIP_PLACEMENT_REQUIRES_RELIGION"))
    end
    for row in GameInfo.MutuallyExclusiveBuildings() do
        if row.Building == buildingType then
            local ex = GameInfo.Buildings[row.MutuallyExclusiveBuilding]
            if ex then
                table.insert(detail.requirements,
                    Locale.Lookup("LOC_TOOLTIP_BUILDING_MUTUALLY_EXCLUSIVE_WITH", ex.Name))
            end
        end
    end
    for row in GameInfo.BuildingPrereqs() do
        if row.Building == buildingType then
            local pre = GameInfo.Buildings[row.PrereqBuilding]
            if pre then
                local preDistrict = GameInfo.Districts[pre.PrereqDistrict]
                if preDistrict
                    and preDistrict.DistrictType ~= "DISTRICT_CITY_CENTER"
                    and preDistrict.DistrictType ~= def.PrereqDistrict then
                    table.insert(detail.requirements,
                        Locale.Lookup("LOC_TOOLTIP_BUILDING_REQUIRES_BUILDING_WITH_DISTRICT",
                            pre.Name, preDistrict.Name))
                else
                    table.insert(detail.requirements,
                        Locale.Lookup("LOC_TOOLTIP_BUILDING_REQUIRES_BUILDING", pre.Name))
                end
            end
        end
    end
    if def.PrereqDistrict then
        local district = GameInfo.Districts[def.PrereqDistrict]
        if district and district.DistrictType ~= "DISTRICT_CITY_CENTER" then
            table.insert(detail.requirements,
                Locale.Lookup("LOC_TOOLTIP_BUILDING_REQUIRES_DISTRICT", district.Name))
        end
    end
    if def.AdjacentDistrict then
        local adj = GameInfo.Districts[def.AdjacentDistrict]
        if adj then
            table.insert(detail.requirements,
                Locale.Lookup("LOC_TOOLTIP_BUILDING_REQUIRES_ADJACENT_DISTRICT", adj.Name))
        end
    end
    if def.AdjacentImprovement then
        local imp = GameInfo.Improvements[def.AdjacentImprovement]
        if imp then
            -- Vanilla intentionally reuses the adjacent-district loc here.
            table.insert(detail.requirements,
                Locale.Lookup("LOC_TOOLTIP_BUILDING_REQUIRES_ADJACENT_DISTRICT", imp.Name))
        end
    end
    if def.AdjacentResource then
        local resource = GameInfo.Resources[def.AdjacentResource]
        if resource then
            table.insert(detail.requirements,
                Locale.Lookup("LOC_TOOLTIP_BUILDING_REQUIRES_ADJACENT_RESOURCE", resource.Name))
        end
    end
    if def.RequiresRiver or def.RequiresAdjacentRiver then
        table.insert(detail.requirements,
            Locale.Lookup("LOC_TOOLTIP_PLACEMENT_REQUIRES_ADJACENT_RIVER"))
    end
    if def.MustBeLake then
        table.insert(detail.requirements, Locale.Lookup("LOC_TOOLTIP_PLACEMENT_REQUIRES_LAKE"))
    end
    if def.MustNotBeLake then
        table.insert(detail.requirements,
            Locale.Lookup("LOC_TOOLTIP_PLACEMENT_REQUIRES_NOT_LAKE"))
    end
    if def.AdjacentToMountain then
        table.insert(detail.requirements,
            Locale.Lookup("LOC_TOOLTIP_PLACEMENT_REQUIRES_ADJACENT_MOUNTAIN"))
    end
    if def.Coast or def.MustBeAdjacentLand then
        table.insert(detail.requirements, Locale.Lookup("LOC_TOOLTIP_PLACEMENT_REQUIRES_COAST"))
    end

    return detail
end

-- ---------------------------------------------------------------------------
-- Districts
-- ---------------------------------------------------------------------------

local function GetDistrictDef(item)
    if not item or not item.Type then return nil end
    return GameInfo.Districts[item.Type]
end

local function AddDistrictCitizenYields(detail, districtType)
    for row in GameInfo.District_CitizenYieldChanges() do
        if row.DistrictType == districtType then
            AppendIfNonEmpty(detail.citizenYields,
                FormatYieldChange(row.YieldChange, row.YieldType))
        end
    end
end

local function AddDistrictGreatPersonPoints(detail, districtType)
    for row in GameInfo.District_GreatPersonPoints() do
        if row.DistrictType == districtType then
            local cls = GameInfo.GreatPersonClasses[row.GreatPersonClassType]
            if cls then
                AppendIfNonEmpty(detail.bonuses,
                    Locale.Lookup("LOC_TYPE_TRAIT_GREAT_PERSON_POINTS",
                        row.PointsPerTurn, cls.IconString, cls.Name))
            end
        end
    end
end

-- Adjacency bonuses ("+1 Faith from each adjacent natural wonder", etc.) come
-- from vanilla's ToolTipHelper.GetAdjacencyBonuses, which already handles the
-- pile of edge cases (per-N tiles, prereq tech/civic, obsoletes, terrain vs
-- resource vs district vs feature targets).
local function AddDistrictAdjacencyBonuses(detail, districtType)
    if type(ToolTipHelper) ~= "table" or type(ToolTipHelper.GetAdjacencyBonuses) ~= "function" then
        return
    end
    local lines = ToolTipHelper.GetAdjacencyBonuses(
        GameInfo.District_Adjacencies, "DistrictType", districtType)
    if type(lines) ~= "table" then return end
    for _, line in ipairs(lines) do
        AppendIfNonEmpty(detail.bonuses, line)
    end
end

function BuildDistrictDetail(item)
    local detail = NewDetail()
    local def = GetDistrictDef(item)
    if not def then return detail end

    AddCostLine(detail, item.Cost, item.Yield, item.TurnsLeft)
    AddDescription(detail, def.Description)
    AddMaintenanceLine(detail, def.Maintenance)

    AddDistrictGreatPersonPoints(detail, def.DistrictType)

    if def.Housing and def.Housing ~= 0 then
        AppendIfNonEmpty(detail.bonuses, Locale.Lookup("LOC_TYPE_TRAIT_HOUSING", def.Housing))
    end
    if def.Entertainment and def.Entertainment ~= 0 then
        AppendIfNonEmpty(detail.bonuses,
            Locale.Lookup("LOC_TYPE_TRAIT_AMENITY_ENTERTAINMENT", def.Entertainment))
    end
    local airSlots = tonumber(def.AirSlots) or 0
    if airSlots ~= 0 then
        AppendIfNonEmpty(detail.bonuses, Locale.Lookup("LOC_TYPE_TRAIT_AIRSLOTS", airSlots))
    end
    local citizenSlots = tonumber(def.CitizenSlots) or 0
    if citizenSlots ~= 0 then
        AppendIfNonEmpty(detail.bonuses,
            Locale.Lookup("LOC_TYPE_TRAIT_CITIZENSLOTS", citizenSlots))
    end

    AddDistrictAdjacencyBonuses(detail, def.DistrictType)
    AddDistrictCitizenYields(detail, def.DistrictType)

    if def.NoAdjacentCity then
        table.insert(detail.requirements,
            Locale.Lookup("LOC_DISTRICT_REQUIRE_NOT_ADJACENT_TO_CITY"))
    end

    return detail
end

-- ---------------------------------------------------------------------------
-- Projects
-- ---------------------------------------------------------------------------

local function GetProjectDef(item)
    if not item or not item.Type then return nil end
    return GameInfo.Projects[item.Type]
end

function BuildProjectDetail(item)
    local detail = NewDetail()
    local def = GetProjectDef(item)
    if not def then return detail end

    AddCostLine(detail, item.Cost, item.Yield, item.TurnsLeft)
    AddDescription(detail, def.ShortDescription or def.Description)

    if def.AmenitiesWhileActive and def.AmenitiesWhileActive > 0 then
        AppendIfNonEmpty(detail.bonuses,
            Locale.Lookup("LOC_PROJECT_AMENITIES_WHILE_ACTIVE", def.AmenitiesWhileActive))
    end
    for row in GameInfo.Project_YieldConversions() do
        if row.ProjectType == def.ProjectType then
            local yield = GameInfo.Yields[row.YieldType]
            if yield then
                AppendIfNonEmpty(detail.bonuses,
                    Locale.Lookup("LOC_PROJECT_YIELD_CONVERSIONS",
                        yield.IconString, yield.Name, row.PercentOfProductionRate))
            end
        end
    end
    for row in GameInfo.Project_GreatPersonPoints() do
        if row.ProjectType == def.ProjectType then
            local cls = GameInfo.GreatPersonClasses[row.GreatPersonClassType]
            if cls then
                AppendIfNonEmpty(detail.bonuses,
                    Locale.Lookup("LOC_PROJECT_GREAT_PERSON_POINTS",
                        cls.IconString, cls.Name))
            end
        end
    end

    return detail
end

-- ---------------------------------------------------------------------------
-- Dispatcher
-- ---------------------------------------------------------------------------

function BuildItemDetail(item, formation)
    local class = GetProductionItemClass(item)
    local detail
    if class == "unit" then
        detail = BuildUnitDetail(item, formation)
    elseif class == "building" then
        detail = BuildBuildingDetail(item)
    elseif class == "district" then
        detail = BuildDistrictDetail(item)
    elseif class == "project" then
        detail = BuildProjectDetail(item)
    else
        detail = NewDetail()
    end
    for _, reason in ipairs(ExtractFailureReasons(item)) do
        table.insert(detail.failures, reason)
    end
    return detail
end

-- Resolve the active current-production hash to an item-shaped table so the
-- current-production node can reuse the same per-kind detail builders.
function GetCurrentProductionItem()
    if not m_caiData or not m_caiData.City then return nil end
    local pCity = m_caiData.City
    local pBuildQueue = pCity.GetBuildQueue and pCity:GetBuildQueue() or nil
    if not pBuildQueue then return nil end

    local hash = pBuildQueue:GetCurrentProductionTypeHash()
    if hash == 0 and pBuildQueue.GetPreviousProductionTypeHash then
        hash = pBuildQueue:GetPreviousProductionTypeHash()
    end
    if hash == 0 then return nil end

    local function build(typeName, costFn, progressFn)
        local item = { Hash = hash, Type = typeName }
        if costFn then
            local ok, cost = pcall(costFn)
            if ok and type(cost) == "number" then item.Cost = cost end
        end
        if progressFn then
            local ok, prog = pcall(progressFn)
            if ok and type(prog) == "number" then item.Progress = prog end
        end
        if pBuildQueue.GetTurnsLeft then
            local ok, turns = pcall(function() return pBuildQueue:GetTurnsLeft(hash) end)
            if ok and type(turns) == "number" and turns >= 0 then item.TurnsLeft = turns end
        end
        return item
    end

    local b = GameInfo.Buildings[hash]
    if b then
        return build(b.BuildingType,
            function() return pBuildQueue:GetBuildingCost(b.Index) end,
            function() return pBuildQueue:GetBuildingProgress(b.Index) end)
    end
    local d = GameInfo.Districts[hash]
    if d then
        return build(d.DistrictType,
            function() return pBuildQueue:GetDistrictCost(d.Index) end,
            function() return pBuildQueue:GetDistrictProgress(d.Index) end)
    end
    local u = GameInfo.Units[hash]
    if u then
        local item = build(u.UnitType,
            function() return pBuildQueue:GetUnitCost(u.Index) end,
            function() return pBuildQueue:GetUnitProgress(u.Index) end)
        local formation
        local fmt = pBuildQueue.GetCurrentProductionTypeModifier
            and pBuildQueue:GetCurrentProductionTypeModifier() or nil
        if MilitaryFormationTypes then
            if fmt == MilitaryFormationTypes.CORPS_FORMATION then
                formation = "corps"
            elseif fmt == MilitaryFormationTypes.ARMY_FORMATION then
                formation = "army"
            end
        end
        return item, formation
    end
    local p = GameInfo.Projects[hash]
    if p then
        return build(p.ProjectType,
            function() return pBuildQueue:GetProjectCost(p.Index) end,
            function() return pBuildQueue:GetProjectProgress(p.Index) end)
    end
    return nil
end

function BuildCurrentProductionDetail()
    local item, formation = GetCurrentProductionItem()
    if not item then return NewDetail() end
    return BuildItemDetail(item, formation)
end

function FormatCurrentProductionProgressLine()
    local item = GetCurrentProductionItem()
    if not item or not item.Cost or item.Cost <= 0 then return nil end
    local progress = item.Progress or 0
    local pct = math.floor(progress / item.Cost * 100 + 0.5)
    local line = Locale.Lookup("LOC_CAI_RESEARCH_PROGRESS", pct)
    if item.TurnsLeft and item.TurnsLeft > 0 then
        line = line .. ", " .. Locale.Lookup("LOC_TURNS_REMAINING_VAL", item.TurnsLeft)
    end
    return line
end

-- Brief summary used as the outer TreeviewItem tooltip:
-- cost, description, maintenance, then a short preview of the first few
-- requirements and bonuses (mirroring the inline-unlock preview ResearchChooser
-- shows in its own outer tooltips).
local PRODUCTION_TOOLTIP_PREVIEW = 2

-- Append a sentence-final period when the source text doesn't already end in
-- punctuation, so the screen reader pauses naturally between the cost,
-- description, and maintenance sentences.
function AppendPeriodIfMissing(text)
    if not text or text == "" then return text end
    local last = string.sub(text, -1)
    if last == "." or last == "!" or last == "?" or last == ":" then return text end
    return text .. "."
end

function FormatDetailBriefTooltip(detail)
    local parts = {}
    AppendIfNonEmpty(parts, AppendPeriodIfMissing(detail.cost))
    AppendIfNonEmpty(parts, detail.description[1])
    AppendIfNonEmpty(parts, AppendPeriodIfMissing(detail.maintenance))
    if #detail.stats > 0 then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_PRODUCTION_STATS_LABEL"))
        for _, s in ipairs(detail.stats) do AppendIfNonEmpty(parts, s) end
    end
    if #detail.requirements > 0 then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_PRODUCTION_REQUIREMENTS_LABEL"))
        for i = 1, math.min(PRODUCTION_TOOLTIP_PREVIEW, #detail.requirements) do
            AppendIfNonEmpty(parts, detail.requirements[i])
        end
    end
    if #detail.bonuses > 0 then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_PRODUCTION_BONUSES_LABEL"))
        for i = 1, math.min(PRODUCTION_TOOLTIP_PREVIEW, #detail.bonuses) do
            AppendIfNonEmpty(parts, detail.bonuses[i])
        end
    end
    return table.concat(parts, "[NEWLINE]")
end

function ReadRowTooltip(item, formation)
    return FormatDetailBriefTooltip(BuildItemDetail(item, formation))
end

-- Populates the expanded breakdown rows. Top-level rows for cost / description
-- / maintenance, and counted expandable nodes for requirements, citizen yields,
-- and bonuses.
function AddDetailChildren(parent, detail)
    if not parent then return end

    AddTextDetailNode(mgr, parent, AppendPeriodIfMissing(detail.cost))
    for _, d in ipairs(detail.description) do
        AddTextDetailNode(mgr, parent, d)
    end
    for _, reason in ipairs(detail.failures) do
        AddTextDetailNode(mgr, parent, reason)
    end
    AddTextDetailNode(mgr, parent, AppendPeriodIfMissing(detail.maintenance))

    AddCountedListNode(mgr, parent, detail.stats, "CAIProductionStats",
        "LOC_CAI_PRODUCTION_STATS_COUNT_ONE", "LOC_CAI_PRODUCTION_STATS_COUNT")
    AddCountedListNode(mgr, parent, detail.requirements, "CAIProductionRequirements",
        "LOC_CAI_PRODUCTION_REQUIREMENTS_COUNT_ONE", "LOC_CAI_PRODUCTION_REQUIREMENTS_COUNT")
    AddCountedListNode(mgr, parent, detail.citizenYields, "CAIProductionCitizenYields",
        "LOC_CAI_PRODUCTION_CITIZEN_YIELDS_COUNT_ONE", "LOC_CAI_PRODUCTION_CITIZEN_YIELDS_COUNT")
    AddCountedListNode(mgr, parent, detail.bonuses, "CAIProductionBonuses",
        "LOC_CAI_PRODUCTION_BONUSES_COUNT_ONE", "LOC_CAI_PRODUCTION_BONUSES_COUNT")
end

function AddItemDetailChildren(parent, item, formation)
    AddDetailChildren(parent, BuildItemDetail(item, formation))
end

function ReadControlText(control)
    if not control or not control.GetText then return "" end
    return control:GetText() or ""
end

function ReadCurrentProductionName()
    local name = ReadControlText(Controls.CurrentProductionName)
    if name == "" then return "" end
    return name
end

function HasActiveCurrentProduction()
    if not m_caiData or not m_caiData.City then return false end
    local pBuildQueue = m_caiData.City.GetBuildQueue and m_caiData.City:GetBuildQueue() or nil
    if not pBuildQueue then return false end
    return pBuildQueue:GetCurrentProductionTypeHash() ~= 0
end

function ReadCurrentProductionLabel()
    if not HasActiveCurrentProduction() then
        return Locale.Lookup("LOC_PRODUCTION_MANAGER_NO_CURRENT_PRODUCTION")
    end
    local name = ReadCurrentProductionName()
    if name == "" then
        return Locale.Lookup("LOC_PRODUCTION_MANAGER_NO_CURRENT_PRODUCTION")
    end
    local status = ReadControlText(Controls.CurrentProductionStatus)
    if status ~= "" then
        return name .. ", " .. status
    end
    return name
end

function ReadCurrentProductionTooltip()
    if not HasActiveCurrentProduction() then return "" end
    local detail = BuildCurrentProductionDetail()
    local progressLine = FormatCurrentProductionProgressLine()
    if progressLine then detail.cost = progressLine end
    return FormatDetailBriefTooltip(detail)
end

function BuildCurrentProductionNode()
    local node = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIProductionPanelTreeviewItem"), "TreeviewItem", {
        GetLabel = ReadCurrentProductionLabel,
        GetTooltip = ReadCurrentProductionTooltip,
        IsHidden = function()
            return ControlIsHidden(Controls.CurrentProductionContainer)
                or ControlIsHidden(Controls.CurrentProductionButton)
        end,
        IsDisabled = function() return ControlIsDisabled(Controls.CurrentProductionButton) end,
        OnFocusEnter = function() PlayMenuHover() end,
    })
    node._caiFocusKey = "current"
    node.OnClick = function()
        if ControlIsDisabled(Controls.CurrentProductionButton) then return end
        OnItemClicked(Controls, Controls.CurrentProductionButton)
    end
    node:AddInputBinding({
        Key = Keys.VK_DELETE,
        Action = RemoveCurrentProductionFromQueue,
    })

    local progressLine = FormatCurrentProductionProgressLine()
    if progressLine then
        AddTextDetailNode(mgr, node, AppendPeriodIfMissing(progressLine))
    end
    AddDetailChildren(node, BuildCurrentProductionDetail())
    return node
end

function InvokeRightClickPedia(item)
    if m_isTutorialRunning or not item or not item.Type then return false end
    RightClickProductionItem(item.Type)
    return true
end

function BuildItemLeftAction(item, tab, formation)
    return function()
        local city = GetActiveProductionCity()

        if not city then return end
        local itemClass = GetProductionItemClass(item)

        if tab == TAB_PURCHASE_GOLD or tab == TAB_PURCHASE_FAITH then
            if itemClass == "unit" then
                local spokenName = Locale.Lookup(item.Name or "")
                if formation == "corps" then
                    RequestPurchaseUnit(city, item, MilitaryFormationTypes.CORPS_MILITARY_FORMATION)
                    spokenName = WithFormationSuffix(spokenName, "corps")
                elseif formation == "army" then
                    RequestPurchaseUnit(city, item, MilitaryFormationTypes.ARMY_MILITARY_FORMATION)
                    spokenName = WithFormationSuffix(spokenName, "army")
                else
                    RequestPurchaseUnit(city, item, MilitaryFormationTypes.STANDARD_MILITARY_FORMATION)
                end
                if spokenName ~= "" then
                    Speak(Locale.Lookup("LOC_CAI_PRODUCTION_PURCHASED", spokenName))
                end
                Close()
            elseif itemClass == "building" then
                RequestPurchaseBuilding(city, item)
                if item.Name then
                    Speak(Locale.Lookup("LOC_CAI_PRODUCTION_PURCHASED", Locale.Lookup(item.Name)))
                end
                Close()
            elseif itemClass == "district" then
                RequestPurchaseDistrict(city, item)
                if item.Name then
                    Speak(Locale.Lookup("LOC_CAI_PRODUCTION_PURCHASED", Locale.Lookup(item.Name)))
                end
                Close()
            end
            return
        end

        if itemClass == "unit" then
            if formation == "corps" then
                BuildUnitCorps(city, item)
            elseif formation == "army" then
                BuildUnitArmy(city, item)
            else
                BuildUnit(city, item)
            end
            CloseAfterNewProduction()
        elseif itemClass == "building" then
            BuildBuilding(city, item)
        elseif itemClass == "district" then
            ZoneDistrict(city, item)
        elseif itemClass == "project" then
            AdvanceProject(city, item)
            CloseAfterNewProduction()
        end
    end
end

function SpeakQueuedProduction(item, formation)
    if not item or not item.Name then return end

    local spokenName = Locale.Lookup(item.Name)
    if formation == "corps" then
        spokenName = WithFormationSuffix(spokenName, "corps")
    elseif formation == "army" then
        spokenName = WithFormationSuffix(spokenName, "army")
    end

    if spokenName ~= "" then
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_QUEUED", spokenName))
    end
end

function BuildItemQueueAction(item, tab, formation)
    local leftAction = BuildItemLeftAction(item, tab, formation)

    return function()
        if tab ~= TAB_PRODUCTION then return false end

        local restoreManager = false
        if type(CloseManager) == "function" then
            CloseManager()
        end
        if type(OpenQueue) == "function" then
            OpenQueue()
        else
            return false
        end

        m_caiQueueActionActive = true
        leftAction()
        m_caiQueueActionActive = false

        if type(CloseQueue) == "function" then
            CloseQueue()
        end
        if restoreManager and type(OpenManager) == "function" then
            OpenManager()
        end

        SpeakQueuedProduction(item, formation)
        return true
    end
end

function GetItemsForTab(tab)
    local out = {}
    if not m_caiData then return out end

    if tab == TAB_PRODUCTION then
        out.Districts = m_caiData.DistrictItems or {}
        out.Buildings = {}
        out.Wonders = {}
        for _, b in ipairs(m_caiData.BuildingItems or {}) do
            if b.IsWonder then
                table.insert(out.Wonders, b)
            else
                table.insert(out.Buildings, b)
            end
        end
        out.Units = m_caiData.UnitItems or {}
        out.Projects = m_caiData.ProjectItems or {}
    elseif tab == TAB_PURCHASE_GOLD or tab == TAB_PURCHASE_FAITH then
        local yield = tab == TAB_PURCHASE_GOLD and "YIELD_GOLD" or "YIELD_FAITH"
        out.Districts = {}
        out.Buildings = {}
        out.Units = {}
        for _, d in ipairs(m_caiData.DistrictPurchases or {}) do
            if d.Yield == yield then table.insert(out.Districts, d) end
        end
        for _, b in ipairs(m_caiData.BuildingPurchases or {}) do
            if b.Yield == yield then table.insert(out.Buildings, b) end
        end
        for _, u in ipairs(m_caiData.UnitPurchases or {}) do
            if u.Yield == yield then table.insert(out.Units, u) end
        end
    end

    return out
end

function CreateActionNode(props)
    local node = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIProductionPanelTreeviewItem"), "TreeviewItem", {
        GetLabel = props.GetLabel,
        GetTooltip = props.GetTooltip,
        IsDisabled = props.IsDisabled,
        IsHidden = props.IsHidden,
        IsExpanded = props.IsExpanded,
        OnToggleExpanded = props.OnToggleExpanded,
        OnFocusEnter = function() PlayMenuHover() end,
    })
    node._caiFocusKey = props.FocusKey

    if props.LeftAction then
        node.OnClick = function(w)
            InvokePrimaryAction(w, props.LeftAction)
        end
    end
    if props.RightAction then
        node:AddInputBinding({
            Key = Keys.VK_RETURN,
            IsShift = true,
            Action = function(w)
                if w.IsDisabled and w:IsDisabled() then return true end
                return props.RightAction(w) ~= false
            end,
        })
    end
    if props.ControlAction then
        node:AddInputBinding({
            Key = Keys.VK_RETURN,
            IsControl = true,
            Action = function(w)
                if w.IsDisabled and w:IsDisabled() then return true end
                return props.ControlAction(w) ~= false
            end,
        })
    end

    return node
end

function CreateItemRow(item, tab, formation)
    local focusKey = string.format("item:%d:%s:%d", tab, formation or "base", item.Hash or -1)
    local row = CreateActionNode({
        FocusKey = focusKey,
        GetLabel = function() return ReadRowLabel(item, formation) end,
        GetTooltip = function() return ReadRowTooltip(item, formation) end,
        IsDisabled = function() return IsItemRowDisabled(item, tab, formation) end,
        IsHidden = function() return IsItemRowHidden(item, tab, formation) end,
        LeftAction = BuildItemLeftAction(item, tab, formation),
        ControlAction = tab == TAB_PRODUCTION and CurrentTabSupportsQueue() and
            BuildItemQueueAction(item, tab, formation) or nil,
        RightAction = function() return InvokeRightClickPedia(item) end,
    })
    AddItemDetailChildren(row, item, formation)
    return row
end

function AddUnitEntry(parent, unit, tab)
    local hasCorps = unit.Corps and unit.CorpsCost and unit.CorpsCost > 0
    local hasArmy = unit.Army and unit.ArmyCost and unit.ArmyCost > 0
    if not hasCorps and not hasArmy then
        parent:AddChild(CreateItemRow(unit, tab, nil))
        return
    end

    local kInstance = GetInstanceForItem(unit, tab)
    local unitNode = CreateActionNode({
        FocusKey = string.format("unit-group:%d:%d", tab, unit.Hash or -1),
        GetLabel = function() return ReadRowLabel(unit, nil) end,
        GetTooltip = function() return ReadRowTooltip(unit, nil) end,
        IsDisabled = function() return IsItemRowDisabled(unit, tab, nil) end,
        IsHidden = function() return IsItemRowHidden(unit, tab, nil) end,
        IsExpanded = kInstance and kInstance.CorpsArmyArrow and kInstance.CorpsArmyArrow:IsSelected() or false,
        OnToggleExpanded = function(expanded)
            local inst = GetInstanceForItem(unit, tab)
            if inst and inst.CorpsArmyArrow and inst.CorpsArmyArrow:IsSelected() ~= expanded then
                OnCorpsToggle(m_caiUnitList, inst)
            end
        end,
        LeftAction = BuildItemLeftAction(unit, tab, nil),
        ControlAction = tab == TAB_PRODUCTION and CurrentTabSupportsQueue() and
            BuildItemQueueAction(unit, tab, nil) or nil,
        RightAction = function() return InvokeRightClickPedia(unit) end,
    })

    AddItemDetailChildren(unitNode, unit, nil)

    if unit.Corps and unit.CorpsCost and unit.CorpsCost > 0 then
        local corpsItem = setmetatable({
            Cost = unit.CorpsCost,
            TurnsLeft = unit.CorpsTurnsLeft,
            Progress = unit.CorpsProgress,
            Disabled = unit.CorpsDisabled,
        }, { __index = unit })
        unitNode:AddChild(CreateItemRow(corpsItem, tab, "corps"))
    end

    if unit.Army and unit.ArmyCost and unit.ArmyCost > 0 then
        local armyItem = setmetatable({
            Cost = unit.ArmyCost,
            TurnsLeft = unit.ArmyTurnsLeft,
            Progress = unit.ArmyProgress,
            Disabled = unit.ArmyDisabled,
        }, { __index = unit })
        unitNode:AddChild(CreateItemRow(armyItem, tab, "army"))
    end

    parent:AddChild(unitNode)
end

function BuildCategoryNode(focusKey, fallbackLabel, items, extraItems, tab, isUnits, getListRef)
    local total = (items and #items or 0) + (extraItems and #extraItems or 0)
    if total == 0 then return nil end

    local node = CreateActionNode({
        FocusKey = focusKey,
        GetLabel = function()
            local list = getListRef and getListRef() or nil
            if list and list.Header then
                local t = list.Header:GetText()
                if t and t ~= "" then return t end
            end
            return Locale.Lookup(fallbackLabel)
        end,
        IsExpanded = true,
        OnToggleExpanded = function(expanded)
            local list = getListRef and getListRef() or nil
            if not list then return end
            if expanded then OnExpand(list) else OnCollapse(list) end
        end,
    })
    for _, item in ipairs(items or {}) do
        if isUnits then
            AddUnitEntry(node, item, tab)
        else
            node:AddChild(CreateItemRow(item, tab, nil))
        end
    end
    for _, item in ipairs(extraItems or {}) do
        node:AddChild(CreateItemRow(item, tab, nil))
    end
    return node
end

function MakeQueueEntryDescription(entry)
    if not entry then return "" end
    if entry.Directive == CityProductionDirectives.TRAIN and entry.UnitType then
        local def = GameInfo.Units[entry.UnitType]
        if def then return Locale.Lookup(def.Name) end
    elseif entry.Directive == CityProductionDirectives.CONSTRUCT and entry.BuildingType then
        local def = GameInfo.Buildings[entry.BuildingType]
        if def then return Locale.Lookup(def.Name) end
    elseif entry.Directive == CityProductionDirectives.ZONE and entry.DistrictType then
        local def = GameInfo.Districts[entry.DistrictType]
        if def then return Locale.Lookup(def.Name) end
    elseif entry.Directive == CityProductionDirectives.PROJECT and entry.ProjectType then
        local def = GameInfo.Projects[entry.ProjectType]
        if def then return Locale.Lookup(def.Name) end
    end
    return ""
end

function NormalizeCAITab(tab)
    -- Older CAI code used a separate manager tab at index 5; map it to queue.
    if tab == 5 then
        return TAB_QUEUE
    end

    return tab
end

function IsQueueModeTab(tab)
    return NormalizeCAITab(tab) == TAB_QUEUE
end

function GetQueueEntryName(queueIndex)
    if not m_caiData or not m_caiData.City then return "" end

    local pBuildQueue = m_caiData.City:GetBuildQueue()
    if not pBuildQueue then return "" end

    return MakeQueueEntryDescription(pBuildQueue:GetAt(queueIndex))
end

function GetQueueRowCount()
    local count = 0
    if not m_caiData or not m_caiData.City then return count end

    local pBuildQueue = m_caiData.City:GetBuildQueue()
    if not pBuildQueue then return count end

    for i = 1, MAX_QUEUE_SIZE do
        if pBuildQueue:GetAt(i) ~= nil then
            count = i
        end
    end

    return count
end

function GetQueueInstance(queueIndex)
    if not queueIndex or not m_QueueInstanceIM or not m_QueueInstanceIM.GetAllocatedInstance then
        return nil
    end
    return m_QueueInstanceIM:GetAllocatedInstance(queueIndex)
end

function GetFocusedQueueRow()
    local focused = mgr and mgr.GetFocusedWidget and mgr:GetFocusedWidget() or nil
    if focused and focused._caiQueueIndex then
        return focused
    end
    return nil
end

function GetFocusedBodyIndex()
    if not m_caiBody or not m_caiBody.Children or not mgr or not mgr.GetFocusedWidget then
        return nil
    end

    local focused = mgr:GetFocusedWidget()
    if not focused then return nil end

    for idx, child in ipairs(m_caiBody.Children) do
        if child == focused then
            return idx
        end
    end

    return nil
end

function GetCurrentProductionName()
    if Controls.CurrentProductionName and Controls.CurrentProductionName.GetText then
        return Controls.CurrentProductionName:GetText() or ""
    end
    return ""
end

function RemoveQueueIndex(queueIndex, name)
    if queueIndex == nil or queueIndex < 0 then return true end

    m_caiQueueFocusIndexAfterRebuild = GetFocusedBodyIndex()
    UI.PlaySound("Play_UI_Click")
    Speak(Locale.Lookup("LOC_CAI_PRODUCTION_QUEUE_REMOVED", name))
    RemoveQueueItem(queueIndex)
    return true
end

function RemoveFocusedQueueItem()
    local row = GetFocusedQueueRow()
    if row and row._caiQueueIndex and row._caiQueueName then
        return RemoveQueueIndex(row._caiQueueIndex, row._caiQueueName)
    end

    return false
end

function MoveQueueSelection(direction)
    local row = GetFocusedQueueRow()
    local queueIndex = row and row._caiQueueIndex or -1
    local rowName = row and row._caiQueueName or ""

    if queueIndex == -1 then return false end

    local targetIndex = queueIndex + direction
    if targetIndex < 1 or targetIndex > GetQueueRowCount() then
        if rowName ~= "" then
            if direction < 0 then
                Speak(Locale.Lookup("LOC_CAI_PRODUCTION_QUEUE_ALREADY_FIRST", rowName))
            else
                Speak(Locale.Lookup("LOC_CAI_PRODUCTION_QUEUE_ALREADY_LAST", rowName))
            end
        end
        return true
    end

    m_caiQueueFocusIndexAfterRebuild = targetIndex + 1
    SwapQueueItem(queueIndex, targetIndex)
    if rowName ~= "" then
        if direction < 0 then
            Speak(Locale.Lookup("LOC_CAI_PRODUCTION_QUEUE_MOVED_UP", rowName))
        else
            Speak(Locale.Lookup("LOC_CAI_PRODUCTION_QUEUE_MOVED_DOWN", rowName))
        end
    end
    return true
end

function RemoveCurrentProductionFromQueue()
    if not HasActiveCurrentProduction() then return true end
    local name = GetCurrentProductionName()
    if name == "" then return true end

    m_caiQueueFocusIndexAfterRebuild = GetFocusedBodyIndex()
    UI.PlaySound("Play_UI_Click")
    Speak(Locale.Lookup("LOC_CAI_PRODUCTION_CURRENT_REMOVED", name))
    RemoveQueueItem(0)
    return true
end

function CreateQueueRowWidget(queueIndex, name)
    local row = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIProductionPanelButton"), "Button", {
        GetLabel = function() return name end,
        OnClick = function() return true end,
        OnFocusEnter = function(w)
            PlayMenuHover()
        end,
    })

    row._caiFocusKey = "queue:" .. tostring(queueIndex)
    row._caiQueueIndex = queueIndex
    row._caiQueueName = name

    row:AddInputBindings({
        {
            Key = Keys.VK_DELETE,
            Action = function()
                return RemoveFocusedQueueItem()
            end,
        },
        {
            Key = Keys.VK_UP,
            MSG = KeyEvents.KeyDown,
            IsShift = true,
            Action = function()
                return MoveQueueSelection(-1)
            end,
        },
        {
            Key = Keys.VK_DOWN,
            MSG = KeyEvents.KeyDown,
            IsShift = true,
            Action = function()
                return MoveQueueSelection(1)
            end,
        },
    })

    return row
end

function CreateQueueCurrentWidget()
    local row = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIProductionPanelButton"), "Button", {
        GetLabel = ReadCurrentProductionLabel,
        GetTooltip = ReadCurrentProductionTooltip,
        OnClick = function() return true end,
        OnFocusEnter = function() PlayMenuHover() end,
    })

    row._caiFocusKey = "current"

    row:AddInputBindings({
        {
            Key = Keys.VK_DELETE,
            Action = function()
                return RemoveCurrentProductionFromQueue()
            end,
        },
    })

    return row
end

function InvokePrimaryAction(node, leftAction)
    if not node then return false end
    if node.IsDisabled and node:IsDisabled() then return true end
    if leftAction then
        leftAction(node)
        return true
    end
    return false
end

function BuildItemTreeBody(tab)
    local tree = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIProductionPanelTreeview"), "Treeview", {
        GetLabel = function() return Locale.Lookup("LOC_HUD_CHOOSE_PRODUCTION") end,
    })

    local items = GetItemsForTab(tab)

    if tab == TAB_PRODUCTION and HasActiveCurrentProduction() then
        tree:AddChild(BuildCurrentProductionNode())
    end

    if tab == TAB_PRODUCTION then
        tree:AddChild(BuildCategoryNode("cat:districts", "LOC_HUD_DISTRICTS_BUILDINGS",
            items.Districts, items.Buildings, tab, false,
            function() return m_caiDistrictList end))
    else
        tree:AddChild(BuildCategoryNode("cat:districts", "LOC_HUD_DISTRICTS",
            items.Districts, nil, tab, false,
            function() return m_caiDistrictList end))
        tree:AddChild(BuildCategoryNode("cat:buildings", "LOC_HUD_BUILDINGS",
            items.Buildings, nil, tab, false,
            function() return m_caiBuildingList end))
    end

    if tab == TAB_PRODUCTION then
        tree:AddChild(BuildCategoryNode("cat:wonders", "LOC_HUD_CITY_WONDERS",
            items.Wonders, nil, tab, false,
            function() return m_caiWonderList end))
    end

    tree:AddChild(BuildCategoryNode("cat:units", "LOC_TECH_FILTER_UNITS",
        items.Units, nil, tab, true,
        function() return m_caiUnitList end))

    if tab == TAB_PRODUCTION then
        tree:AddChild(BuildCategoryNode("cat:projects", "LOC_HUD_PROJECTS",
            items.Projects, nil, tab, false,
            function() return m_caiProjectList end))
    end

    return tree
end

function BuildQueueBody()
    local list = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIProductionPanelList"), "List", {
        GetLabel = function() return Locale.Lookup("LOC_CAI_PRODUCTION_QUEUE_LIST") end,
    })

    list:AddChild(CreateQueueCurrentWidget())

    if m_caiData and m_caiData.City then
        local pBuildQueue = m_caiData.City:GetBuildQueue()
        if pBuildQueue then
            for i = 1, MAX_QUEUE_SIZE do
                local entry = pBuildQueue:GetAt(i)
                if entry then
                    local desc = MakeQueueEntryDescription(entry)
                    if desc ~= "" then
                        list:AddChild(CreateQueueRowWidget(i, desc))
                    end
                end
            end
        end
    end

    return list
end

function RebuildBody(selectedTab)
    if not m_caiPanel then return end

    local tabChanged = selectedTab ~= nil and selectedTab ~= m_caiTab
    if selectedTab then m_caiTab = selectedTab end

    local focusPath
    if m_caiQueueFocusIndexAfterRebuild then
        focusPath = { m_caiQueueFocusIndexAfterRebuild }
        m_caiQueueFocusIndexAfterRebuild = nil
    elseif not tabChanged and m_caiBody then
        focusPath = mgr:CaptureFocusIndexPath(m_caiBody)
    end

    if m_caiBody then m_caiBody:Destroy() end

    local tab = NormalizeCAITab(m_caiTab)
    if tab == TAB_QUEUE then
        m_caiBody = BuildQueueBody()
    else
        m_caiBody = BuildItemTreeBody(tab)
    end
    m_caiPanel:InsertChild(2, m_caiBody)

    if tabChanged then
        m_caiBody:ClearFocusedChild()
    elseif focusPath then
        mgr:SetFocusIndexPath(m_caiBody, focusPath)
    end

    m_caiLastBuiltTab = tab
    m_caiLastBuiltCityID = m_caiData and m_caiData.City and m_caiData.City:GetID() or nil
    m_caiLastBuiltPlayerID = m_caiData and m_caiData.Owner or nil
end

function CreateTabWidget(tabIndex, control, switchFunc)
    return mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIProductionPanelTab"), "Tab", {
        GetLabel = function() return control:GetText() end,
        IsHidden = function() return IsProductionTutorialMode() or ControlIsHidden(control) end,
        IsDisabled = function() return ControlIsDisabled(control) end,
        OnFocusEnter = function()
            if m_caiTab == tabIndex then return end
            PlayMenuHover()
            switchFunc()
        end,
        OnClick = function()
            switchFunc()
            return true
        end,
    })
end

function GetTabBarIndex(tab)
    for index, child in ipairs(m_caiTabBar.Children) do
        if child == m_caiTabs[tab or m_caiTab] then return index end
    end
    return 1
end

function SetCAITab(tab)
    local normalizedTab = NormalizeCAITab(tab) or TAB_PRODUCTION
    m_caiTab = normalizedTab
    if m_caiTabBar then
        local tabIndex = GetTabBarIndex(normalizedTab)
        m_caiTabBar:SetDefaultIndex(tabIndex)
        m_caiTabBar:SetFocusedChild(tabIndex)
    end
end

local function GetCAITabForListMode(listMode)
    if listMode == LISTMODE.PURCHASE_GOLD then return TAB_PURCHASE_GOLD end
    if listMode == LISTMODE.PURCHASE_FAITH then return TAB_PURCHASE_FAITH end
    if listMode == LISTMODE.PROD_QUEUE then return TAB_QUEUE end
    return TAB_PRODUCTION
end

local function OnVanillaListModeChangedCAI(listMode)
    local targetTab = GetCAITabForListMode(listMode)
    local tabChanged = NormalizeCAITab(m_caiTab) ~= targetTab

    SetCAITab(targetTab)

    if m_caiPanel and (m_caiBody == nil or tabChanged or m_caiLastBuiltTab ~= targetTab) then
        RebuildBody(targetTab)
    end

    if m_caiOpenPending and m_caiPanel and mgr and not mgr:HasWidget(m_caiPanel) then
        m_caiOpenPending = false
        mgr:Push(m_caiPanel, PopupPriority.Low)
    end
end

local function RebuildForTab(tab)
    SetCAITab(tab)
    RebuildBody(tab)
end

function RefreshRecommendations()
    m_caiRecommended = {}
    if not m_caiData or not m_caiData.City then return end
    local cityAI = m_caiData.City.GetCityAI and m_caiData.City:GetCityAI() or nil
    if not cityAI then return end
    local recs = cityAI.GetBuildRecommendations and cityAI:GetBuildRecommendations() or nil
    if not recs then return end
    for _, kItem in ipairs(recs) do
        m_caiRecommended[kItem.BuildItemHash] = true
    end
end

function EnsurePanelBuilt()
    if m_caiPanel then return end

    m_caiPanel = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIProductionPanelPanel"), "Panel", {
        GetLabel = function() return Locale.Lookup("LOC_HUD_CHOOSE_PRODUCTION") end,
    })

    m_caiTabBar = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIProductionPanelTabBar"), "TabBar", {
        GetLabel = function() return Locale.Lookup("LOC_HUD_CHOOSE_PRODUCTION") end,
        IsHidden = function(w)
            return IsProductionTutorialMode() or #w:GetVisibleChildren() == 0
        end,
    })
    m_caiPanel:AddChild(m_caiTabBar)

    m_caiTabs[TAB_PRODUCTION] = CreateTabWidget(TAB_PRODUCTION, Controls.ProductionTab, OnTabChangeProduction)
    m_caiTabs[TAB_PURCHASE_GOLD] = CreateTabWidget(TAB_PURCHASE_GOLD, Controls.PurchaseTab, OnTabChangePurchase)
    m_caiTabs[TAB_PURCHASE_FAITH] = CreateTabWidget(TAB_PURCHASE_FAITH, Controls.PurchaseFaithTab,
        OnTabChangePurchaseFaith)
    m_caiTabs[TAB_QUEUE] = CreateTabWidget(TAB_QUEUE, Controls.QueueTab, OnTabChangeQueue)

    m_caiTabBar:AddChild(m_caiTabs[TAB_PRODUCTION])
    if GameCapabilities.HasCapability("CAPABILITY_GOLD") then
        m_caiTabBar:AddChild(m_caiTabs[TAB_PURCHASE_GOLD])
    end
    if GameCapabilities.HasCapability("CAPABILITY_FAITH") then
        m_caiTabBar:AddChild(m_caiTabs[TAB_PURCHASE_FAITH])
    end
    m_caiTabBar:AddChild(m_caiTabs[TAB_QUEUE])
    m_caiTabBar:SetDefaultIndex(GetTabBarIndex(m_caiTab))
    m_caiTabBar:SetFocusedChild(GetTabBarIndex(m_caiTab))
end

function OnPanelOpenedCAI()
    EnsurePanelBuilt()
    if mgr:HasWidget(m_caiPanel) then return end
    m_caiOpenPending = true
end

function OnPanelClosedCAI()
    if m_caiPanel and mgr:HasWidget(m_caiPanel) then
        mgr:RemoveFromStack(m_caiPanel:GetId())
    elseif m_caiPanel then
        m_caiPanel:Destroy()
    end
    m_caiPanel = nil
    m_caiTabBar = nil
    m_caiTabs = {}
    m_caiBody = nil
    m_caiData = nil
    m_caiRecommended = {}
    m_caiInstanceByHash = {}
    m_caiWonderList = nil
    m_caiProjectList = nil
    m_caiDistrictList = nil
    m_caiBuildingList = nil
    m_caiUnitList = nil
    m_caiInstancesByModeHash = {}
    m_caiCaptureListMode = nil
    m_caiOpenPending = false
    m_caiQueueActionActive = false
    m_caiQueueFocusIndexAfterRebuild = nil
    m_caiLastBuiltTab = nil
    m_caiLastBuiltCityID = nil
    m_caiLastBuiltPlayerID = nil
    m_caiLastCurrentProductionHash = nil
end

PopulateGenericItemData = WrapFunc(PopulateGenericItemData, function(orig, kInstance, kItem)
    orig(kInstance, kItem)
    if kItem and kItem.Hash then
        m_caiInstanceByHash[kItem.Hash] = kInstance
        if m_caiCaptureListMode then
            if not m_caiInstancesByModeHash[m_caiCaptureListMode] then
                m_caiInstancesByModeHash[m_caiCaptureListMode] = {}
            end
            m_caiInstancesByModeHash[m_caiCaptureListMode][kItem.Hash] = kInstance
        end
    end
end)

PopulateList = WrapFunc(PopulateList, function(orig, data, listMode, listIM)
    m_caiCaptureListMode = listMode
    local result = orig(data, listMode, listIM)
    m_caiCaptureListMode = nil
    return result
end)

function WrapPopulateCapture(origFunc, captureFn)
    return WrapFunc(origFunc, function(orig, data, listMode, listIM)
        local before = listIM and listIM.m_iAllocatedInstances or 0
        orig(data, listMode, listIM)
        local after = listIM and listIM.m_iAllocatedInstances or 0
        for i = before + 1, after do
            local inst = listIM.m_AllocatedInstances and listIM.m_AllocatedInstances[i]
            if inst then captureFn(inst, i - before) end
        end
    end)
end

OnTabChangeProduction = WrapFunc(OnTabChangeProduction, function(orig)
    orig()
    RebuildForTab(TAB_PRODUCTION)
end)

OnTabChangePurchase = WrapFunc(OnTabChangePurchase, function(orig)
    orig()
    RebuildForTab(TAB_PURCHASE_GOLD)
end)

OnTabChangePurchaseFaith = WrapFunc(OnTabChangePurchaseFaith, function(orig)
    orig()
    RebuildForTab(TAB_PURCHASE_FAITH)
end)

OnTabChangeQueue = WrapFunc(OnTabChangeQueue, function(orig)
    orig()
    RebuildForTab(TAB_QUEUE)
end)

OnCityPanelChooseProduction = WrapFunc(OnCityPanelChooseProduction, function(orig)
    SetCAITab(TAB_PRODUCTION)
    orig()
end)

OnCityPanelChoosePurchase = WrapFunc(OnCityPanelChoosePurchase, function(orig)
    SetCAITab(TAB_PURCHASE_GOLD)
    orig()
end)

OnCityPanelChoosePurchaseFaith = WrapFunc(OnCityPanelChoosePurchaseFaith, function(orig)
    SetCAITab(TAB_PURCHASE_FAITH)
    orig()
end)

OnCityPanelPurchaseGoldOpen = WrapFunc(OnCityPanelPurchaseGoldOpen, function(orig)
    SetCAITab(TAB_PURCHASE_GOLD)
    orig()
end)

OnCityPanelPurchaseFaithOpen = WrapFunc(OnCityPanelPurchaseFaithOpen, function(orig)
    SetCAITab(TAB_PURCHASE_FAITH)
    orig()
end)

OnProductionOpenForQueue = WrapFunc(OnProductionOpenForQueue, function(orig)
    SetCAITab(TAB_QUEUE)
    orig()
end)

PopulateWonders = WrapPopulateCapture(PopulateWonders, function(inst)
    m_caiWonderList = inst
end)

PopulateProjects = WrapPopulateCapture(PopulateProjects, function(inst)
    m_caiProjectList = inst
end)

PopulateUnits = WrapPopulateCapture(PopulateUnits, function(inst)
    m_caiUnitList = inst
end)

PopulateDistrictsWithNestedBuildings = WrapPopulateCapture(PopulateDistrictsWithNestedBuildings, function(inst)
    m_caiDistrictList = inst
end)

PopulateDistrictsWithoutNestedBuildings = WrapPopulateCapture(PopulateDistrictsWithoutNestedBuildings,
    function(inst, idx)
        if idx == 1 then
            m_caiDistrictList = inst
        else
            m_caiBuildingList = inst
        end
    end)

View = WrapFunc(View, function(orig, data)
    m_caiInstanceByHash = {}
    m_caiInstancesByModeHash = {}
    m_caiWonderList = nil
    m_caiProjectList = nil
    m_caiDistrictList = nil
    m_caiBuildingList = nil
    m_caiUnitList = nil
    m_caiCaptureListMode = nil

    m_caiData = data
    orig(data)
    RefreshRecommendations()
    EnsurePanelBuilt()
    local activeTab = NormalizeCAITab(m_caiTab)
    local cityID = data and data.City and data.City:GetID() or nil
    local ownerID = data and data.Owner or nil

    local currentHash = nil
    local pBuildQueue = data and data.City and data.City.GetBuildQueue and data.City:GetBuildQueue() or nil
    if pBuildQueue then
        currentHash = pBuildQueue:GetCurrentProductionTypeHash()
    end
    local sameContext = m_caiLastBuiltCityID == cityID and m_caiLastBuiltPlayerID == ownerID
    local currentProductionChanged = sameContext and m_caiLastCurrentProductionHash ~= currentHash
    m_caiLastCurrentProductionHash = currentHash

    local shouldRebuild = activeTab == TAB_QUEUE
        or m_caiLastBuiltTab ~= activeTab
        or m_caiLastBuiltCityID ~= cityID
        or m_caiLastBuiltPlayerID ~= ownerID
        or currentProductionChanged

    if shouldRebuild and not m_caiOpenPending then
        RebuildBody()
    end
end)

OnCorpsToggle = WrapFunc(OnCorpsToggle, function(orig, unitList, unitListing)
    orig(unitList, unitListing)
    if m_caiPanel and mgr and mgr:HasWidget(m_caiPanel) and (m_caiTab == TAB_PRODUCTION or m_caiTab == TAB_PURCHASE_GOLD or m_caiTab == TAB_PURCHASE_FAITH) then
        RebuildBody()
    end
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
    -- This panel does not have any popups in its context, so we can skip input handling if the top widget is not the production panel. We do so to avoid conflict with the tutorial root input handler while in the pause menu
    if mgr:GetTop() ~= m_caiPanel then return false end
    local handled = (mgr and mgr:HandleInput(pInputStruct))
    if handled then
        return true
    end
    return orig(pInputStruct)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)

BuildBuilding = WrapFunc(BuildBuilding, function(orig, city, entry)
    if not m_caiQueueActionActive and entry and entry.Name then
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_CHOSEN", Locale.Lookup(entry.Name)))
    end
    return orig(city, entry)
end)

ZoneDistrict = WrapFunc(ZoneDistrict, function(orig, city, entry)
    if not m_caiQueueActionActive and entry and entry.Name then
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_CHOSEN", Locale.Lookup(entry.Name)))
    end
    return orig(city, entry)
end)

BuildUnit = WrapFunc(BuildUnit, function(orig, city, entry)
    if not m_caiQueueActionActive and entry and entry.Name then
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_CHOSEN", Locale.Lookup(entry.Name)))
    end
    return orig(city, entry)
end)

BuildUnitCorps = WrapFunc(BuildUnitCorps, function(orig, city, entry)
    if not m_caiQueueActionActive and entry and entry.Name then
        local n = WithFormationSuffix(Locale.Lookup(entry.Name), "corps")
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_CHOSEN", n))
    end
    return orig(city, entry)
end)

BuildUnitArmy = WrapFunc(BuildUnitArmy, function(orig, city, entry)
    if not m_caiQueueActionActive and entry and entry.Name then
        local n = WithFormationSuffix(Locale.Lookup(entry.Name), "army")
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_CHOSEN", n))
    end
    return orig(city, entry)
end)

AdvanceProject = WrapFunc(AdvanceProject, function(orig, city, entry)
    if not m_caiQueueActionActive and entry and entry.Name then
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_CHOSEN", Locale.Lookup(entry.Name)))
    end
    return orig(city, entry)
end)

PurchaseUnit = WrapFunc(PurchaseUnit, function(orig, city, entry)
    if entry and entry.Name then
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_PURCHASED", Locale.Lookup(entry.Name)))
    end
    return orig(city, entry)
end)

PurchaseUnitCorps = WrapFunc(PurchaseUnitCorps, function(orig, city, entry)
    if entry and entry.Name then
        local n = WithFormationSuffix(Locale.Lookup(entry.Name), "corps")
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_PURCHASED", n))
    end
    return orig(city, entry)
end)

PurchaseUnitArmy = WrapFunc(PurchaseUnitArmy, function(orig, city, entry)
    if entry and entry.Name then
        local n = WithFormationSuffix(Locale.Lookup(entry.Name), "army")
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_PURCHASED", n))
    end
    return orig(city, entry)
end)

PurchaseBuilding = WrapFunc(PurchaseBuilding, function(orig, city, entry)
    if entry and entry.Name then
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_PURCHASED", Locale.Lookup(entry.Name)))
    end
    return orig(city, entry)
end)

PurchaseDistrict = WrapFunc(PurchaseDistrict, function(orig, city, entry)
    if entry and entry.Name then
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_PURCHASED", Locale.Lookup(entry.Name)))
    end
    return orig(city, entry)
end)

LuaEvents.ProductionPanel_Open.Add(OnPanelOpenedCAI)
LuaEvents.ProductionPanel_Close.Add(OnPanelClosedCAI)
LuaEvents.ProductionPanel_ListModeChanged.Add(OnVanillaListModeChangedCAI)

function RefreshIfOpen()
    if m_caiPanel and mgr and mgr:HasWidget(m_caiPanel) and RefreshView then
        RefreshView()
    end
end

if Events then
    if Events.CityProductionChanged then Events.CityProductionChanged.Add(RefreshIfOpen) end
    if Events.CityProductionUpdated then Events.CityProductionUpdated.Add(RefreshIfOpen) end
    if Events.CityWorkersChanged then Events.CityWorkersChanged.Add(RefreshIfOpen) end
end
