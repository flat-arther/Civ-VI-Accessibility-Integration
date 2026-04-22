include("caiUtils")
include("ProductionPanel")
local mgr = ExposedMembers.CAI_UIManager

-- Mirrors vanilla LISTMODE (ProductionPanel.lua:37).
local LISTMODE = { PRODUCTION = 1, PURCHASE_GOLD = 2, PURCHASE_FAITH = 3, PROD_QUEUE = 4 }

-- Four tabs: Manager is dropped since vanilla OnTabChangeManager maps to the
-- same LISTMODE.PROD_QUEUE as Queue with only cosmetic differences.
local TAB_PRODUCTION      = 1
local TAB_PURCHASE_GOLD   = 2
local TAB_PURCHASE_FAITH  = 3
local TAB_QUEUE           = 4

local MAX_QUEUE_SIZE = 7

-- Widget handles. Nulled in OnPanelClosedCAI so the next open rebuilds clean.
local m_caiPanel            = nil ---@type UIWidget|nil
local m_caiTabBar           = nil ---@type UIWidget|nil
local m_caiTabs             = {}  ---@type table<number, UIWidget>
local m_caiTree             = nil ---@type UIWidget|nil
local m_caiCurrentNode      = nil ---@type UIWidget|nil
local m_caiQueueNode        = nil ---@type UIWidget|nil
local m_caiCatDistricts     = nil ---@type UIWidget|nil
local m_caiCatWonders       = nil ---@type UIWidget|nil
local m_caiCatBuildings     = nil ---@type UIWidget|nil
local m_caiCatUnits         = nil ---@type UIWidget|nil
local m_caiCatProjects      = nil ---@type UIWidget|nil
local m_caiDetailEdit       = nil ---@type UIWidget|nil
local m_caiCloseBtn         = nil ---@type UIWidget|nil

-- Captured state. m_caiData holds the most recent GetData() result so tab
-- focus handlers can rebuild rows without re-reading game state.
local m_caiData             = nil ---@type table|nil
local m_caiTab              = TAB_PRODUCTION
local m_caiOpenPending      = false
local m_caiRecommended      = {}  ---@type table<number, boolean>

-- ===========================================================================
-- Helpers
-- ===========================================================================
-- Strip vanilla tooltip markup ([ICON_*], [COLOR:*], [ENDCOLOR], [NEWLINE])
-- before TTS. SetEditBoxText converts [NEWLINE] into real newlines when the
-- string lands in the Edit buffer, but for Speak() we want a space instead.
local function StripMarkup(s)
    if not s or s == "" then return "" end
    s = s:gsub("%[ICON_[^%]]*%]", "")
    s = s:gsub("%[COLOR[^%]]*%]", "")
    s = s:gsub("%[ENDCOLOR%]", "")
    s = s:gsub("%[NEWLINE%]", " ")
    s = s:gsub("%s+", " ")
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    return s
end

local function AppendPart(parts, text)
    if text and text ~= "" then table.insert(parts, text) end
end

-- Formation suffix. name is already localized; suffix comes from vanilla.
local function WithFormationSuffix(name, formation)
    if formation == "corps" then
        return name .. " " .. Locale.Lookup("LOC_UNITFLAG_CORPS_SUFFIX")
    elseif formation == "army" then
        return name .. " " .. Locale.Lookup("LOC_UNITFLAG_ARMY_SUFFIX")
    end
    return name
end

-- Build a row's speech label. Name is already localized (LOC_*); other
-- fragments are Locale.Lookup'd.
local function FormatRowLabel(item, tab, formation)
    local parts = {}
    local name = Locale.Lookup(item.Name)
    name = WithFormationSuffix(name, formation)
    AppendPart(parts, name)

    if m_caiRecommended[item.Hash] then
        AppendPart(parts, Locale.Lookup("LOC_RECOMMENDED"))
    end

    local cost = item.Cost
    if cost and cost > 0 then
        if tab == TAB_PRODUCTION or tab == TAB_QUEUE then
            AppendPart(parts, Locale.Lookup("LOC_CAI_PRODUCTION_COST_PRODUCTION", cost))
        elseif tab == TAB_PURCHASE_GOLD then
            AppendPart(parts, Locale.Lookup("LOC_CAI_PRODUCTION_COST_GOLD", cost))
        elseif tab == TAB_PURCHASE_FAITH then
            AppendPart(parts, Locale.Lookup("LOC_CAI_PRODUCTION_COST_FAITH", cost))
        end
    end

    if item.TurnsLeft and item.TurnsLeft > 0
        and (tab == TAB_PRODUCTION or tab == TAB_QUEUE) then
        AppendPart(parts, Locale.Lookup("LOC_CAI_PRODUCTION_TURNS_AT", item.TurnsLeft))
    end

    if item.Progress and item.Cost and item.Progress > 0 and item.Progress < item.Cost then
        AppendPart(parts, Locale.Lookup("LOC_CAI_PRODUCTION_PROGRESS", item.Progress, item.Cost))
    end

    return table.concat(parts, ", ")
end

local function ComposeDetail(item)
    if not item then return "" end
    local tip = item.ToolTip or ""
    if tip == "" then return Locale.Lookup(item.Name or "") end
    return tip
end

-- Dispatch table for committing a selection. Kind + tab determines which
-- vanilla function to call. formation is "standard"/"corps"/"army" (nil = standard).
local function Commit(item, tab, formation)
    if not m_caiData or not m_caiData.City then return end
    local city = m_caiData.City

    if tab == TAB_PURCHASE_GOLD or tab == TAB_PURCHASE_FAITH then
        if item.Kind == "KIND_UNIT" then
            if formation == "corps" then PurchaseUnitCorps(city, item)
            elseif formation == "army" then PurchaseUnitArmy(city, item)
            else PurchaseUnit(city, item) end
        elseif item.Kind == "KIND_BUILDING" then
            PurchaseBuilding(city, item)
        elseif item.Kind == "KIND_DISTRICT" then
            PurchaseDistrict(city, item)
        end
    else
        if item.Kind == "KIND_UNIT" then
            if formation == "corps" then BuildUnitCorps(city, item)
            elseif formation == "army" then BuildUnitArmy(city, item)
            else BuildUnit(city, item) end
        elseif item.Kind == "KIND_BUILDING" then
            BuildBuilding(city, item)
        elseif item.Kind == "KIND_DISTRICT" then
            ZoneDistrict(city, item)
        elseif item.Kind == "KIND_PROJECT" then
            AdvanceProject(city, item)
        end
    end
end

-- ===========================================================================
-- Partitioning GetData() output by tab.
-- ===========================================================================
local function GetItemsForTab(tab)
    local out = {}
    if not m_caiData then return out end

    if tab == TAB_PRODUCTION or tab == TAB_QUEUE then
        out.Districts = m_caiData.DistrictItems or {}
        out.Wonders = {}
        out.Buildings = {}
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
        local yield = (tab == TAB_PURCHASE_GOLD) and "YIELD_GOLD" or "YIELD_FAITH"
        out.Districts = {}
        for _, d in ipairs(m_caiData.DistrictPurchases or {}) do
            if d.Yield == yield then table.insert(out.Districts, d) end
        end
        out.Buildings = {}
        for _, b in ipairs(m_caiData.BuildingPurchases or {}) do
            if b.Yield == yield then table.insert(out.Buildings, b) end
        end
        out.Units = {}
        for _, u in ipairs(m_caiData.UnitPurchases or {}) do
            if u.Yield == yield then table.insert(out.Units, u) end
        end
    end

    return out
end

-- ===========================================================================
-- Row factory. Enter/Space are already routed by the Button template
-- (Click → OnClick); only Shift+Enter (Civilopedia) is CAI-specific and is
-- layered on top via AddInputBinding so the template defaults survive.
-- ===========================================================================
local function CreateRowWidget(item, tab, formation)
    local captured = item
    local capturedTab = tab
    local capturedFormation = formation

    local row = mgr:CreateUIWidget("Button", {
        GetLabel = function() return FormatRowLabel(captured, capturedTab, capturedFormation) end,
        IsDisabled = function()
            if capturedFormation == "corps" then return captured.CorpsDisabled end
            if capturedFormation == "army"  then return captured.ArmyDisabled  end
            return captured.Disabled
        end,
        OnClick = function() Commit(captured, capturedTab, capturedFormation) end,
        OnFocusEnter = function()
            if m_caiDetailEdit then
                mgr.WidgetTemplateHelpers:SetEditBoxText(m_caiDetailEdit, ComposeDetail(captured))
            end
        end,
    })

    row:AddInputBindings({
        -- Explicit Enter → OnClick so activation doesn't depend on the Button
        -- template's default RegisterInputs surviving composition.
        { Key = Keys.VK_RETURN, Action = function(w)
            if w.IsDisabled and w:IsDisabled() then return true end
            if w.OnClick then w:OnClick() end
            return true
        end },
        { Key = Keys.VK_RETURN, IsShift = true, Action = function()
            if captured.Type then LuaEvents.OpenCivilopedia(captured.Type) end
            return true
        end },
    })

    row._caiItem = captured
    return row
end

-- A unit with Corps/Army formations becomes a TreeNode containing the three
-- (or two) formation rows. A unit without formations is just a leaf Button.
local function AddUnitEntry(parent, unit, tab)
    local hasCorps = unit.Corps and unit.CorpsCost and unit.CorpsCost > 0
    local hasArmy  = unit.Army  and unit.ArmyCost  and unit.ArmyCost  > 0

    if not hasCorps and not hasArmy then
        parent:AddChild(CreateRowWidget(unit, tab, nil))
        return
    end

    local unitNode = mgr:CreateUIWidget("TreeNode", {
        GetLabel = function() return Locale.Lookup(unit.Name) end,
    })

    unitNode:AddChild(CreateRowWidget(unit, tab, nil))

    if hasCorps then
        local corpsItem = setmetatable({
            Cost = unit.CorpsCost,
            TurnsLeft = unit.CorpsTurnsLeft,
            Progress = unit.CorpsProgress,
            Disabled = unit.CorpsDisabled,
            ToolTip = unit.CorpsTooltip or unit.ToolTip,
        }, { __index = unit })
        unitNode:AddChild(CreateRowWidget(corpsItem, tab, "corps"))
    end

    if hasArmy then
        local armyItem = setmetatable({
            Cost = unit.ArmyCost,
            TurnsLeft = unit.ArmyTurnsLeft,
            Progress = unit.ArmyProgress,
            Disabled = unit.ArmyDisabled,
            ToolTip = unit.ArmyTooltip or unit.ToolTip,
        }, { __index = unit })
        unitNode:AddChild(CreateRowWidget(armyItem, tab, "army"))
    end

    parent:AddChild(unitNode)
end

local function FillCategoryNode(node, items, tab, isUnits)
    if not node then return end
    node:ClearChildren()
    if not items then return end
    for _, item in ipairs(items) do
        if isUnits then
            AddUnitEntry(node, item, tab)
        else
            node:AddChild(CreateRowWidget(item, tab, nil))
        end
    end
end

-- ===========================================================================
-- Queue rows. Speak announcement, remove via vanilla RemoveQueueItem. Delete
-- binding is layered on via AddInputBinding (same additive pattern as rows).
-- ===========================================================================
local function MakeQueueEntryDescription(entry)
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

local function CreateQueueRowWidget(queueIndex, name)
    local capturedName = name
    local capturedIdx = queueIndex

    local row = mgr:CreateUIWidget("Button", {
        GetLabel = function() return capturedName end,
        OnClick = function() end, -- Informational; Delete removes.
        OnFocusEnter = function()
            if m_caiDetailEdit then
                mgr.WidgetTemplateHelpers:SetEditBoxText(m_caiDetailEdit, capturedName)
            end
        end,
    })

    row:AddInputBinding({
        Key = Keys.VK_DELETE,
        Action = function()
            Speak(Locale.Lookup("LOC_CAI_PRODUCTION_QUEUE_REMOVED", capturedName))
            RemoveQueueItem(capturedIdx)
            return true
        end,
    })
    return row
end

local function FillQueueNode()
    if not m_caiQueueNode then return end
    m_caiQueueNode:ClearChildren()
    if not m_caiData or not m_caiData.City then return end
    local pBuildQueue = m_caiData.City:GetBuildQueue()
    if not pBuildQueue then return end
    for i = 1, MAX_QUEUE_SIZE do
        local entry = pBuildQueue:GetAt(i)
        if entry then
            local desc = MakeQueueEntryDescription(entry)
            if desc ~= "" then
                m_caiQueueNode:AddChild(CreateQueueRowWidget(i, desc))
            end
        end
    end
end

-- ===========================================================================
-- Current production block. GetLabel recomputes live so mid-turn progress
-- updates reflect without rebuilding the widget.
-- ===========================================================================
local function GetCurrentProductionInfo()
    if not m_caiData or not m_caiData.City then return nil end
    local pBuildQueue = m_caiData.City:GetBuildQueue()
    if not pBuildQueue then return nil end
    local hash = pBuildQueue:GetCurrentProductionTypeHash()
    if hash == 0 then return nil end
    return GetProductionInfoOfCity(m_caiData.City, hash)
end

local function FormatCurrentProductionLabel()
    local info = GetCurrentProductionInfo()
    if not info or not info.Name or info.Name == "" then
        return Locale.Lookup("LOC_PRODUCTION_MANAGER_NO_CURRENT_PRODUCTION")
    end
    local parts = { Locale.Lookup("LOC_CAI_PRODUCTION_CURRENT", info.Name) }
    if info.Progress and info.Cost and info.Cost > 0 then
        table.insert(parts, Locale.Lookup("LOC_CAI_PRODUCTION_PROGRESS", info.Progress, info.Cost))
    end
    if info.Turns and info.Turns > 0 then
        table.insert(parts, Locale.Lookup("LOC_TURNS_REMAINING_VAL", info.Turns))
    end
    return table.concat(parts, ", ")
end

-- ===========================================================================
-- Visibility per tab: Production/Queue see all categories plus current +
-- queue nodes. Purchase tabs show only Districts, Buildings, Units.
-- ===========================================================================
local function ApplyTabVisibility(tab)
    local productionLike = (tab == TAB_PRODUCTION or tab == TAB_QUEUE)

    if m_caiCurrentNode  then m_caiCurrentNode._caiHidden  = not productionLike end
    if m_caiQueueNode    then m_caiQueueNode._caiHidden    = not productionLike end
    if m_caiCatWonders   then m_caiCatWonders._caiHidden   = not productionLike end
    if m_caiCatProjects  then m_caiCatProjects._caiHidden  = not productionLike end
end

-- ===========================================================================
-- Rebuild body rows for the current tab. Panel scaffolding is stable across
-- rebuilds; only category nodes and the queue node change.
-- ===========================================================================
local function RebuildBody()
    if not m_caiPanel then return end

    local items = GetItemsForTab(m_caiTab)
    FillCategoryNode(m_caiCatDistricts, items.Districts, m_caiTab, false)
    FillCategoryNode(m_caiCatWonders,   items.Wonders,   m_caiTab, false)
    FillCategoryNode(m_caiCatBuildings, items.Buildings, m_caiTab, false)
    FillCategoryNode(m_caiCatUnits,     items.Units,     m_caiTab, true)
    FillCategoryNode(m_caiCatProjects,  items.Projects,  m_caiTab, false)

    FillQueueNode()
    ApplyTabVisibility(m_caiTab)

    if m_caiDetailEdit then
        mgr.WidgetTemplateHelpers:SetEditBoxText(m_caiDetailEdit, "")
    end
end

-- ===========================================================================
-- Panel scaffolding. Built once per open; destroyed on close so next open
-- rebuilds from scratch.
-- ===========================================================================
local function CreateTabWidget(index, vanillaTabControl, vanillaHandler)
    local capturedIdx = index
    return mgr:CreateUIWidget("Tab", {
        GetLabel = function()
            if vanillaTabControl and vanillaTabControl.GetText then
                return StripMarkup(vanillaTabControl:GetText() or "")
            end
            return ""
        end,
        OnFocusEnter = function()
            m_caiTab = capturedIdx
            if vanillaHandler then vanillaHandler() end
            RebuildBody()
        end,
    })
end

local function CreateCategoryNode(labelKey, hidable)
    return mgr:CreateUIWidget("TreeNode", {
        GetLabel = function() return Locale.Lookup(labelKey) end,
        IsHidden = function(w)
            if hidable and w._caiHidden then return true end
            return not w.Children or #w.Children == 0
        end,
    })
end

local function EnsurePanelBuilt()
    if m_caiPanel then return end

    m_caiPanel = mgr:CreateUIWidget("Panel", {
        GetLabel = function() return Locale.Lookup("LOC_HUD_CITY_PRODUCTION") end,
    })

    m_caiTabBar = mgr:CreateUIWidget("TabBar", {
        GetLabel = function() return Locale.Lookup("LOC_HUD_CITY_PRODUCTION") end,
    })
    m_caiPanel:AddChild(m_caiTabBar)

    m_caiTabs[TAB_PRODUCTION]     = CreateTabWidget(TAB_PRODUCTION,     Controls.ProductionTab,     OnTabChangeProduction)
    m_caiTabs[TAB_PURCHASE_GOLD]  = CreateTabWidget(TAB_PURCHASE_GOLD,  Controls.PurchaseTab,       OnTabChangePurchase)
    m_caiTabs[TAB_PURCHASE_FAITH] = CreateTabWidget(TAB_PURCHASE_FAITH, Controls.PurchaseFaithTab,  OnTabChangePurchaseFaith)
    m_caiTabs[TAB_QUEUE]          = CreateTabWidget(TAB_QUEUE,          Controls.QueueTab,          OnTabChangeQueue)

    for i = 1, 4 do m_caiTabBar:AddChild(m_caiTabs[i]) end

    m_caiTree = mgr:CreateUIWidget("Tree", {
        GetLabel = function() return Locale.Lookup("LOC_HUD_CITY_PRODUCTION") end,
    })
    m_caiPanel:AddChild(m_caiTree)

    -- Current production: zero-child TreeNode that reads like a headline.
    m_caiCurrentNode = mgr:CreateUIWidget("TreeNode", {
        GetLabel = FormatCurrentProductionLabel,
        IsHidden = function(w) return w._caiHidden end,
    })
    m_caiTree:AddChild(m_caiCurrentNode)

    m_caiQueueNode = mgr:CreateUIWidget("TreeNode", {
        GetLabel = function() return Locale.Lookup("LOC_CAI_PRODUCTION_QUEUE_LIST") end,
        IsHidden = function(w)
            if w._caiHidden then return true end
            return not w.Children or #w.Children == 0
        end,
    })
    m_caiTree:AddChild(m_caiQueueNode)

    -- Category labels use the same vanilla keys that vanilla SetTexts onto
    -- the list headers (ProductionPanel.lua:798-1228).
    m_caiCatDistricts = CreateCategoryNode("LOC_HUD_DISTRICTS", false)
    m_caiTree:AddChild(m_caiCatDistricts)

    m_caiCatWonders = CreateCategoryNode("LOC_HUD_CITY_WONDERS", true)
    m_caiTree:AddChild(m_caiCatWonders)

    m_caiCatBuildings = CreateCategoryNode("LOC_HUD_BUILDINGS", false)
    m_caiTree:AddChild(m_caiCatBuildings)

    m_caiCatUnits = CreateCategoryNode("LOC_TECH_FILTER_UNITS", false)
    m_caiTree:AddChild(m_caiCatUnits)

    m_caiCatProjects = CreateCategoryNode("LOC_HUD_PROJECTS", true)
    m_caiTree:AddChild(m_caiCatProjects)

    m_caiDetailEdit = mgr:CreateUIWidget("Edit", {
        GetLabel = function() return Locale.Lookup("LOC_CAI_PRODUCTION_DETAIL_LABEL") end,
        GetValue = function() return m_caiDetailEdit and m_caiDetailEdit.EditBuffer or "" end,
        AlwaysEdit = true,
        EditReadOnly = true,
        HighlightOnEdit = false,
        EditBuffer = "",
    })
    m_caiPanel:AddChild(m_caiDetailEdit)

    m_caiCloseBtn = mgr:CreateUIWidget("Button", {
        GetLabel = function()
            if Controls.CloseButton and Controls.CloseButton.GetToolTipString then
                local tip = Controls.CloseButton:GetToolTipString()
                if tip and tip ~= "" then return tip end
            end
            return Locale.Lookup("LOC_HUD_CLOSE")
        end,
        OnClick = function() Close() end,
    })
    m_caiPanel:AddChild(m_caiCloseBtn)

    ApplyTabVisibility(m_caiTab)
end

-- ===========================================================================
-- Update m_caiRecommended from city AI. Vanilla's m_kRecommendedItems is
-- file-local; replicate the same read here.
-- ===========================================================================
local function RefreshRecommendations()
    m_caiRecommended = {}
    if not m_caiData or not m_caiData.City then return end
    local recs = m_caiData.City:GetCityAI():GetBuildRecommendations()
    if not recs then return end
    for _, kItem in ipairs(recs) do
        m_caiRecommended[kItem.BuildItemHash] = true
    end
end

-- ===========================================================================
-- Open/close plumbing. Vanilla fires ProductionPanel_Open when Open() runs
-- and ProductionPanel_Close inside Close(), so bridging there is sufficient.
-- ===========================================================================
local function OnPanelOpenedCAI()
    EnsurePanelBuilt()
    if mgr:HasWidget(m_caiPanel) then return end
    m_caiOpenPending = true
end

local function OnPanelClosedCAI()
    if m_caiPanel and mgr:HasWidget(m_caiPanel) then
        mgr:Pop()
    end
    m_caiPanel          = nil
    m_caiTabBar         = nil
    m_caiTabs           = {}
    m_caiTree           = nil
    m_caiCurrentNode    = nil
    m_caiQueueNode      = nil
    m_caiCatDistricts   = nil
    m_caiCatWonders     = nil
    m_caiCatBuildings   = nil
    m_caiCatUnits       = nil
    m_caiCatProjects    = nil
    m_caiDetailEdit     = nil
    m_caiCloseBtn       = nil
    m_caiData           = nil
    m_caiRecommended    = {}
    m_caiOpenPending    = false
end

-- ===========================================================================
-- Wraps. View is re-invoked on every PPP Refresh, so this is the single
-- capture point for both initial open and mid-session refreshes.
-- ===========================================================================
View = WrapFunc(View, function(orig, data)
    m_caiData = data
    orig(data)
    RefreshRecommendations()
    EnsurePanelBuilt()
    RebuildBody()

    if m_caiOpenPending and m_caiPanel and mgr and not mgr:HasWidget(m_caiPanel) then
        m_caiOpenPending = false
        mgr:Push(m_caiPanel)
    end
end)

-- Returning true when mgr consumes the input prevents WorldInput_CAI from
-- re-firing mgr:HandleInput (per feedback_input_handler_consume.md).
OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
    if mgr then
        local panelWasOnStack = m_caiPanel and mgr:HasWidget(m_caiPanel)
        if mgr:HandleInput(pInputStruct) then
            if panelWasOnStack and not mgr:HasWidget(m_caiPanel) then
                Close()
            end
            return true
        end
    end
    return orig(pInputStruct)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)

-- Selection-announce wraps. Sighted-click paths also go through these, so the
-- announcement fires for mouse clicks too.
BuildBuilding = WrapFunc(BuildBuilding, function(orig, city, entry)
    if entry and entry.Name then
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_CHOSEN", Locale.Lookup(entry.Name)))
    end
    return orig(city, entry)
end)

ZoneDistrict = WrapFunc(ZoneDistrict, function(orig, city, entry)
    if entry and entry.Name then
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_CHOSEN", Locale.Lookup(entry.Name)))
    end
    return orig(city, entry)
end)

BuildUnit = WrapFunc(BuildUnit, function(orig, city, entry)
    if entry and entry.Name then
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_CHOSEN", Locale.Lookup(entry.Name)))
    end
    return orig(city, entry)
end)

BuildUnitCorps = WrapFunc(BuildUnitCorps, function(orig, city, entry)
    if entry and entry.Name then
        local n = WithFormationSuffix(Locale.Lookup(entry.Name), "corps")
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_CHOSEN", n))
    end
    return orig(city, entry)
end)

BuildUnitArmy = WrapFunc(BuildUnitArmy, function(orig, city, entry)
    if entry and entry.Name then
        local n = WithFormationSuffix(Locale.Lookup(entry.Name), "army")
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_CHOSEN", n))
    end
    return orig(city, entry)
end)

AdvanceProject = WrapFunc(AdvanceProject, function(orig, city, entry)
    if entry and entry.Name then
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

-- LuaEvents bridges.
LuaEvents.ProductionPanel_Open.Add(OnPanelOpenedCAI)
LuaEvents.ProductionPanel_Close.Add(OnPanelClosedCAI)

-- External refresh: production/queue changes while open need to rerun
-- vanilla Refresh so our View wrap re-rebuilds with fresh data.
local function RefreshIfOpen()
    if m_caiPanel and mgr and mgr:HasWidget(m_caiPanel) and RefreshView then
        RefreshView()
    end
end

if Events then
    if Events.CityProductionChanged then Events.CityProductionChanged.Add(RefreshIfOpen) end
    if Events.CityProductionUpdated then Events.CityProductionUpdated.Add(RefreshIfOpen) end
    if Events.CityProductionQueueChanged then Events.CityProductionQueueChanged.Add(RefreshIfOpen) end
    if Events.CityWorkersChanged then Events.CityWorkersChanged.Add(RefreshIfOpen) end
end
