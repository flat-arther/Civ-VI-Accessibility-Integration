include("caiUtils")
include("CivicsTree")
include("inGameHelpers_CAI")
include("ToolTipHelper")
include("Civ6Common")

local mgr                 = ExposedMembers.CAI_UIManager

local PANEL_ID            = "CAICivicsTree_Panel"
local QUEUE_LIST_ID       = "CAICivicsTree_QueueList"
local FILTER_LIST_ID      = "CAICivicsTree_FilterList"
local MAIN_TREE_ID        = "CAICivicsTree_MainTree"
local GOV_EDIT_ID         = "CAICivicsTree_GovEdit"
local FILTER_RESULTS_ID   = "CAICivicsTree_FilterResults"

-- ===========================================================================
-- MODULE STATE
-- ===========================================================================
local m_panel             = nil ---@type UIWidget|nil
local m_queueList         = nil ---@type UIWidget|nil
local m_filterList        = nil ---@type UIWidget|nil
local m_mainTree          = nil ---@type UIWidget|nil
local m_govEdit           = nil ---@type UIWidget|nil
local m_filterResults     = nil ---@type UIWidget|nil

local m_civicsByType      = {} ---@type table<string, UIWidget>
local m_leadsToByType     = {} ---@type table<string, string[]>
local m_civicIndexToType  = {} ---@type table<integer, string>

local m_filterEntries     = nil ---@type table|nil
local m_activeFilterEntry = nil ---@type table|nil
local m_activeFilterFunc  = nil ---@type function|nil
local m_lastPlayerData    = nil ---@type table|nil
local m_modifierCache     = nil ---@type table|nil
local m_govEditBuffer     = ""

-- Breadcrumb stack of civicTypes the user navigated *away from* via a ref
-- link. Backspace in the main tree pops the most recent one and jumps back.
local m_breadcrumbs       = {} ---@type string[]

-- ===========================================================================
-- LIVE-CONTROL ACCESSORS
-- ===========================================================================

local function GetLocalPlayerCulture()
    local ePlayer = Game.GetLocalPlayer()
    if ePlayer == PlayerTypes.NONE then return nil, -1 end
    local kPlayer = Players[ePlayer]
    if not kPlayer then return nil, -1 end
    return kPlayer:GetCulture(), ePlayer
end

local function GetUiNode(civicType)
    return g_uiNodes and g_uiNodes[civicType] or nil
end

local function ControlText(ctrl)
    if ctrl and ctrl.GetText then
        local t = ctrl:GetText()
        if t and t ~= "" then return t end
    end
    return ""
end

local function ControlIsHidden(ctrl)
    return ctrl and ctrl.IsHidden and ctrl:IsHidden() or false
end

local function GetLiveData(civicType)
    if not m_lastPlayerData then return nil end
    local liveTable = m_lastPlayerData[DATA_FIELD_LIVEDATA]
    return liveTable and liveTable[civicType] or nil
end

local function GetModifierCache()
    if not m_modifierCache and TechAndCivicSupport_BuildCivicModifierCache then
        m_modifierCache = TechAndCivicSupport_BuildCivicModifierCache()
    end
    return m_modifierCache or {}
end

-- ===========================================================================
-- ROW DATA
-- ===========================================================================

local function GetCivicName(civicType)
    local node = GetUiNode(civicType)
    local name = ControlText(node and node.NodeName)
    if name ~= "" then return name end
    local row = GameInfo.Civics[civicType]
    if row and row.Name then return Locale.Lookup(row.Name) end
    return civicType
end

local function GetCivicCostText(civicType)
    local kLive = GetLiveData(civicType)
    if kLive and kLive.Cost and kLive.Cost > 0 then
        return Locale.Lookup("LOC_CAI_CIVIC_COST", kLive.Cost)
    end
    return nil
end

local function GetCivicTurnsText(civicType)
    local node = GetUiNode(civicType)
    if node and not ControlIsHidden(node.Turns) then
        local raw = ControlText(node.Turns)
        local n = string.match(raw, "%[ICON_Turn%](%d+)")
        if n then return Locale.Lookup("LOC_CAI_CIVIC_TURNS", tonumber(n)) end
        if raw ~= "" then return raw end
    end
    local kLive = GetLiveData(civicType)
    if kLive and kLive.TurnsLeft and kLive.TurnsLeft >= 0 then
        return Locale.Lookup("LOC_CAI_CIVIC_TURNS", kLive.TurnsLeft)
    end
    return nil
end

local function GetCivicProgressText(civicType)
    local kLive = GetLiveData(civicType)
    if not kLive or not kLive.Progress or not kLive.Cost or kLive.Cost <= 0 then
        return nil
    end
    local pct = math.floor((kLive.Progress / kLive.Cost) * 100 + 0.5)
    if pct <= 0 then return nil end
    return Locale.Lookup("LOC_CAI_CIVIC_PROGRESS", pct)
end

local function GetCivicDescriptionText(civicType)
    local row = GameInfo.Civics[civicType]
    local desc = row and row.Description or nil
    if desc and desc ~= "" then
        local text = Locale.Lookup(desc)
        if text and text ~= "" then return text end
    end
    return nil
end

local function GetCivicBoostText(civicType)
    local kStatic = g_kItemDefaults[civicType]
    if not kStatic or not kStatic.IsBoostable then return nil end
    local kLive = GetLiveData(civicType)
    local prefix = Locale.Lookup((kLive and kLive.IsBoosted)
        and "LOC_BOOST_BOOSTED" or "LOC_BOOST_TO_BOOST")
    local trigger = kStatic.BoostText or ""
    if trigger == "" then return prefix end
    return prefix .. " " .. trigger
end

local function GetCivicStatusLabel(kLive)
    if not kLive then return nil end
    local status = kLive.IsRevealed and kLive.Status or ITEM_STATUS.UNREVEALED
    if status == ITEM_STATUS.RESEARCHED then
        return Locale.Lookup("LOC_CAI_CIVIC_STATUS_RESEARCHED")
    elseif status == ITEM_STATUS.CURRENT then
        return Locale.Lookup("LOC_CAI_CIVIC_STATUS_CURRENT")
    elseif status == ITEM_STATUS.BLOCKED then
        return Locale.Lookup("LOC_CAI_CIVIC_STATUS_BLOCKED")
    elseif status == ITEM_STATUS.UNREVEALED then
        return Locale.Lookup("LOC_CAI_CIVIC_STATUS_UNREVEALED")
    end
    return nil
end

local function GetCivicQueuePosition(civicType)
    local row = GameInfo.Civics[civicType]
    if not row then return nil end
    local playerCulture = GetLocalPlayerCulture()
    if not playerCulture then return nil end
    local queue = playerCulture:GetCivicQueue()
    if not queue then return nil end
    for i, id in ipairs(queue) do
        if id == row.Index then return i end
    end
    return nil
end

local function CivicKData(civicType)
    return { CivicType = civicType, Type = civicType }
end

-- ===========================================================================
-- LABEL / TOOLTIP
-- ===========================================================================

local function FormatRowLabel(civicType)
    local parts = {}
    AppendIfNonEmpty(parts, GetCivicName(civicType))
    local kLive = GetLiveData(civicType)
    AppendIfNonEmpty(parts, GetCivicStatusLabel(kLive))
    if kLive and kLive.IsRecommended then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_TECH_FILTER_RECOMMENDED"))
    end
    local qpos = GetCivicQueuePosition(civicType)
    if qpos then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_CIVIC_QUEUE_POSITION", qpos))
    end
    return table.concat(parts, ", ")
end

local function FormatRowTooltip(civicType)
    local kData = CivicKData(civicType)
    local unlocks = GetCivicUnlockObjects(kData)
    local obsoletes = GetObsoletePolicyNames(kData)
    local awards = GetAwardNames(GetModifierCache()[civicType])

    local parts = {}
    AppendIfNonEmpty(parts, GetCivicCostText(civicType))
    AppendIfNonEmpty(parts, GetCivicTurnsText(civicType))
    AppendIfNonEmpty(parts, GetCivicProgressText(civicType))
    AppendIfNonEmpty(parts, GetCivicDescriptionText(civicType))
    AppendIfNonEmpty(parts, GetCivicBoostText(civicType))
    if #obsoletes > 0 then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_CIVIC_OBSOLETES_HEADER", table.concat(obsoletes, ", ")))
    end
    if #unlocks > 0 then
        local names = {}
        for _, u in ipairs(unlocks) do table.insert(names, u.Name) end
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_CIVIC_UNLOCKS_HEADER", table.concat(names, ", ")))
    end
    AppendIfNonEmpty(parts, GetCivicAwardsText(awards))
    return table.concat(parts, ", ")
end

-- ===========================================================================
-- FILTER
-- ===========================================================================

local function EnsureFilterEntries()
    if m_filterEntries then return end
    m_filterEntries = {}
    if not g_TechFilters then return end
    local defs = {
        { "TECHFILTER_FOOD",         "LOC_TECH_FILTER_FOOD" },
        { "TECHFILTER_SCIENCE",      "LOC_TECH_FILTER_SCIENCE" },
        { "TECHFILTER_PRODUCTION",   "LOC_TECH_FILTER_PRODUCTION" },
        { "TECHFILTER_CULTURE",      "LOC_TECH_FILTER_CULTURE" },
        { "TECHFILTER_GOLD",         "LOC_TECH_FILTER_GOLD" },
        { "TECHFILTER_UNITS",        "LOC_TECH_FILTER_UNITS" },
        { "TECHFILTER_IMPROVEMENTS", "LOC_TECH_FILTER_IMPROVEMENTS" },
        { "TECHFILTER_WONDERS",      "LOC_TECH_FILTER_WONDERS" },
    }
    for _, pair in ipairs(defs) do
        local fn = g_TechFilters[pair[1]]
        if fn then
            table.insert(m_filterEntries, {
                Label        = Locale.Lookup(pair[2]),
                Func         = fn,
                VanillaEntry = { Func = fn, Description = pair[2] },
            })
        end
    end
end

local function FilterMatchesCivic(civicType)
    if not m_activeFilterFunc then return true end
    return m_activeFilterFunc(civicType) == true
end

-- ===========================================================================
-- STATIC DATA
-- ===========================================================================

local function BuildStaticMaps()
    m_leadsToByType    = {}
    m_civicIndexToType = {}
    for civicType, kEntry in pairs(g_kItemDefaults) do
        local row = GameInfo.Civics[civicType]
        if row then m_civicIndexToType[row.Index] = civicType end
        for _, prereqType in ipairs(kEntry.Prereqs or {}) do
            if prereqType ~= PREREQ_ID_TREE_START then
                m_leadsToByType[prereqType] = m_leadsToByType[prereqType] or {}
                table.insert(m_leadsToByType[prereqType], civicType)
            end
        end
    end
end

-- ===========================================================================
-- CIVIC ACTIONS
-- ===========================================================================

local function SpeakProgressSummary(civicType)
    local kStatic = g_kItemDefaults[civicType]
    local playerCulture = GetLocalPlayerCulture()
    if not kStatic or not playerCulture then return end
    local pathToCivic = playerCulture:GetCivicPath(kStatic.Hash) or {}
    local count, totalCost = 0, 0
    for _, idx in ipairs(pathToCivic) do
        count = count + 1
        local ct = m_civicIndexToType[idx]
        local kLive = ct and GetLiveData(ct) or nil
        if kLive and kLive.Cost then
            totalCost = totalCost + kLive.Cost
        end
    end
    Speak(Locale.Lookup("LOC_CAI_CIVIC_QUEUE_ADDED", count, totalCost))
end

-- Set-current path: prefer vanilla DoLeftClick on the live node button so any
-- vanilla hooks fire; fall back to a direct player operation when the node UI
-- isn't materialized (filter results list, queue list, etc.).
local function ActivateSetCurrent(civicType)
    local node = GetUiNode(civicType)
    local clicked = false
    if node and node.NodeButton and node.NodeButton.DoLeftClick and not ControlIsHidden(node.NodeButton) then
        node.NodeButton:DoLeftClick()
        clicked = true
    elseif node and node.OtherStates and node.OtherStates.DoLeftClick and not ControlIsHidden(node.OtherStates) then
        node.OtherStates:DoLeftClick()
        clicked = true
    end
    if not clicked then
        local kStatic = g_kItemDefaults[civicType]
        local playerCulture, ePlayer = GetLocalPlayerCulture()
        if not kStatic or not playerCulture or ePlayer == -1 then return end
        local tParameters                               = {}
        tParameters[PlayerOperations.PARAM_CIVIC_TYPE]  = playerCulture:GetCivicPath(kStatic.Hash)
        tParameters[PlayerOperations.PARAM_INSERT_MODE] = PlayerOperations.VALUE_EXCLUSIVE
        UI.RequestPlayerOperation(ePlayer, PlayerOperations.PROGRESS_CIVIC, tParameters)
        UI.PlaySound("Confirm_Civic_CivicsTree")
    end
    SpeakProgressSummary(civicType)
end

-- Append path: vanilla only fires append via the Shift-Click branch inside
-- SetCurrentNode; we can't safely toggle its m_shiftDown from here, so route
-- the operation directly.
local function ActivateAppendToQueue(civicType)
    local kStatic = g_kItemDefaults[civicType]
    local playerCulture, ePlayer = GetLocalPlayerCulture()
    if not kStatic or not playerCulture or ePlayer == -1 then return end
    local tParameters                               = {}
    tParameters[PlayerOperations.PARAM_CIVIC_TYPE]  = playerCulture:GetCivicPath(kStatic.Hash)
    tParameters[PlayerOperations.PARAM_INSERT_MODE] = PlayerOperations.VALUE_APPEND
    UI.RequestPlayerOperation(ePlayer, PlayerOperations.PROGRESS_CIVIC, tParameters)
    UI.PlaySound("Confirm_Civic_CivicsTree")
    SpeakProgressSummary(civicType)
end

local function CanResearch(civicType)
    local kLive = GetLiveData(civicType)
    if not kLive or not kLive.IsRevealed then return false end
    return kLive.Status == ITEM_STATUS.READY
        or kLive.Status == ITEM_STATUS.BLOCKED
end

local function IsCivicRevealed(civicType)
    local kLive = GetLiveData(civicType)
    return kLive ~= nil and kLive.IsRevealed == true
end

-- ===========================================================================
-- JUMP-TO-NODE (ref links, queue rows, filter results all funnel through this)
-- ===========================================================================

-- Walk the focus path from leaf upward, returning the civicType of the
-- innermost civic-row currently in focus (FocusKey "civic:<type>"), or nil.
local function GetFocusedCivicType()
    local path = mgr and mgr.CurrentPath or nil
    if not path then return nil end
    for i = #path, 1, -1 do
        local w = path[i]
        local key = w and w.FocusKey or nil
        if key and string.sub(key, 1, 6) == "civic:" then
            return string.sub(key, 7)
        end
    end
    return nil
end

local function JumpToCivic(civicType, recordBreadcrumb)
    local target = m_civicsByType[civicType]
    if not target then return end

    if recordBreadcrumb then
        local source = GetFocusedCivicType()
        if source and source ~= civicType then
            table.insert(m_breadcrumbs, source)
        end
    end

    Speak(Locale.Lookup("LOC_CAI_CIVICS_TREE_JUMPING", GetCivicName(civicType) or ""), true)
    mgr:SetFocus(target)
end

-- ===========================================================================
-- REFERENCE LINKS + DETAIL CHILDREN
-- ===========================================================================

local function CreateRefLink(parentWidget, civicType)
    local capturedType = civicType
    local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAICivicsTreeRef"), "TreeItem", {
        Label             = function() return GetCivicName(capturedType) end,
        HiddenPredicate   = function() return m_civicsByType[capturedType] == nil end,
        DisabledPredicate = function() return not IsCivicRevealed(capturedType) end,
        FocusKey          = "ref:" .. tostring(capturedType),
    })
    item:On("activate", function(w)
        if w:IsDisabled() then return end
        JumpToCivic(capturedType, true)
    end)
    item:AddInputBindings({
        {
            Key     = Keys.VK_RETURN,
            IsShift = true,
            MSG     = KeyEvents.KeyUp,
            Action  = function(w)
                if w:IsDisabled() then return true end
                if IsTutorialRunning and IsTutorialRunning() then return true end
                LuaEvents.OpenCivilopedia(capturedType)
                return true
            end,
        },
    })
    parentWidget:AddChild(item)
    return item
end

local function AddCivicDetailChildren(civicItem, civicType)
    local kData = CivicKData(civicType)
    local unlocks = GetCivicUnlockObjects(kData)

    -- 1) Unlocks bucket — only entries with descriptions get their own child;
    --    each child has Shift+Enter to open Civilopedia for the unlock type.
    local unlockChildren = {}
    for _, unlock in ipairs(unlocks) do
        if unlock.Description then
            table.insert(unlockChildren, unlock)
        end
    end
    if #unlockChildren > 0 then
        local node = mgr:CreateWidget(mgr:GenerateWidgetId("CAICivicsTreeUnlocks"), "TreeItem", {
            Label = function() return Locale.Lookup("LOC_CAI_CIVICS_TREE_UNLOCKS") end,
        })
        for _, unlock in ipairs(unlockChildren) do
            node:AddChild(CreateUnlockChild(mgr, unlock, "CAICivicsTreeUnlock"))
        end
        civicItem:AddChild(node)
    end

    -- 2) Prerequisites
    local kStatic = g_kItemDefaults[civicType]
    local prereqTypes = {}
    for _, pt in ipairs(kStatic and kStatic.Prereqs or {}) do
        if pt ~= PREREQ_ID_TREE_START then table.insert(prereqTypes, pt) end
    end
    if #prereqTypes > 0 then
        local node = mgr:CreateWidget(mgr:GenerateWidgetId("CAICivicsTreePrereqs"), "TreeItem", {
            Label = function() return Locale.Lookup("LOC_CAI_CIVICS_TREE_PREREQS") end,
        })
        for _, pt in ipairs(prereqTypes) do CreateRefLink(node, pt) end
        civicItem:AddChild(node)
    end

    -- 3) Leads to
    local leadsTo = m_leadsToByType[civicType]
    if leadsTo and #leadsTo > 0 then
        local node = mgr:CreateWidget(mgr:GenerateWidgetId("CAICivicsTreeLeadsTo"), "TreeItem", {
            Label = function() return Locale.Lookup("LOC_CAI_CIVICS_TREE_LEADS_TO") end,
        })
        for _, lt in ipairs(leadsTo) do CreateRefLink(node, lt) end
        civicItem:AddChild(node)
    end

    -- 4) Full path (only when researchable and the path has > 1 step)
    if CanResearch(civicType) and kStatic then
        local playerCulture = GetLocalPlayerCulture()
        local path = playerCulture and playerCulture:GetCivicPath(kStatic.Hash) or nil
        if path and #path > 1 then
            local node = mgr:CreateWidget(mgr:GenerateWidgetId("CAICivicsTreePath"), "TreeItem", {
                Label = function() return Locale.Lookup("LOC_CAI_CIVICS_TREE_PATH_IF_SELECTED") end,
            })
            for i = 1, #path - 1 do
                local ct = m_civicIndexToType[path[i]]
                if ct then CreateRefLink(node, ct) end
            end
            civicItem:AddChild(node)
        end
    end
end

-- ===========================================================================
-- CIVIC NODE FACTORY
-- ===========================================================================

local function BuildCivicNode(civicType)
    local capturedType = civicType
    local civicItem = mgr:CreateWidget(mgr:GenerateWidgetId("CAICivicsTreeCivic"), "TreeItem", {
        Label             = function() return FormatRowLabel(capturedType) end,
        Tooltip           = function() return FormatRowTooltip(capturedType) end,
        DisabledPredicate = function()
            local node = GetUiNode(capturedType)
            if node and node.Top and node.Top:IsDisabled() then return true end
            return not CanResearch(capturedType)
        end,
        FocusKey          = "civic:" .. tostring(capturedType),
    })
    civicItem:SetFocusSound("Main_Menu_Mouse_Over")

    civicItem:On("activate", function(w)
        if w:IsDisabled() then return end
        ActivateSetCurrent(capturedType)
    end)

    civicItem:AddInputBindings({
        {
            Key       = Keys.VK_RETURN,
            IsControl = true,
            MSG       = KeyEvents.KeyUp,
            Action    = function()
                if not CanResearch(capturedType) then return true end
                ActivateAppendToQueue(capturedType)
                return true
            end,
        },
        {
            Key     = Keys.VK_RETURN,
            IsShift = true,
            MSG     = KeyEvents.KeyUp,
            Action  = function()
                if IsTutorialRunning and IsTutorialRunning() then return true end
                LuaEvents.OpenCivilopedia(capturedType)
                return true
            end,
        },
    })

    AddCivicDetailChildren(civicItem, capturedType)
    return civicItem
end

-- ===========================================================================
-- MAIN TREE
-- ===========================================================================

local function RebuildMainTree()
    if not m_mainTree then return end

    local capture = mgr:CaptureFocusKey(m_mainTree)
    m_mainTree:ClearChildren()
    m_civicsByType = {}

    for _, era in ipairs(g_kEras) do
        local eraCivics = {}
        for civicType, kEntry in pairs(g_kItemDefaults) do
            if kEntry.EraType == era.EraType and FilterMatchesCivic(civicType) then
                table.insert(eraCivics, { civicType = civicType, row = kEntry.UITreeRow or 0 })
            end
        end
        if #eraCivics > 0 then
            table.sort(eraCivics, function(a, b) return a.row < b.row end)

            local capturedDescription = era.Description
            local eraItem = mgr:CreateWidget(mgr:GenerateWidgetId("CAICivicsTreeEra"), "TreeItem", {
                Label    = function() return Locale.Lookup(capturedDescription) end,
                FocusKey = "era:" .. tostring(era.EraType),
            })

            for _, entry in ipairs(eraCivics) do
                local widget = BuildCivicNode(entry.civicType)
                m_civicsByType[entry.civicType] = widget
                eraItem:AddChild(widget)
            end
            m_mainTree:AddChild(eraItem)
        end
    end

    mgr:RestoreFocus(m_mainTree, capture)
end

-- ===========================================================================
-- QUEUE LIST (flat list of Buttons; activate jumps to main-tree node)
-- ===========================================================================

local function CreateQueueButton(civicType, isCurrent)
    local capturedType = civicType
    local btn = mgr:CreateWidget(mgr:GenerateWidgetId("CAICivicsTreeQueueRow"), "Button", {
        Label    = function()
            if isCurrent then
                return Locale.Lookup("LOC_CAI_CIVIC_CURRENT", FormatRowLabel(capturedType))
            end
            return FormatRowLabel(capturedType)
        end,
        Tooltip  = function() return FormatRowTooltip(capturedType) end,
        FocusKey = (isCurrent and "queue:current:" or "queue:") .. tostring(capturedType),
    })
    btn:SetFocusSound("Main_Menu_Mouse_Over")
    btn:On("activate", function() JumpToCivic(capturedType) end)
    btn:AddInputBindings({
        {
            Key     = Keys.VK_RETURN,
            IsShift = true,
            MSG     = KeyEvents.KeyUp,
            Action  = function()
                if IsTutorialRunning and IsTutorialRunning() then return true end
                LuaEvents.OpenCivilopedia(capturedType)
                return true
            end,
        },
    })
    return btn
end

local function RebuildQueueList()
    if not m_queueList then return end

    local capture = mgr:CaptureFocusKey(m_queueList)
    m_queueList:ClearChildren()

    local playerCulture = GetLocalPlayerCulture()
    if playerCulture then
        local currentIdx = playerCulture:GetProgressingCivic()
        if currentIdx and currentIdx ~= -1 then
            local ct = m_civicIndexToType[currentIdx]
            if ct then m_queueList:AddChild(CreateQueueButton(ct, true)) end
        end
        local queue = playerCulture:GetCivicQueue()
        if queue then
            for _, civicID in ipairs(queue) do
                local ct = m_civicIndexToType[civicID]
                if ct and ct ~= m_civicIndexToType[currentIdx or -1] then
                    m_queueList:AddChild(CreateQueueButton(ct, false))
                end
            end
        end
    end

    mgr:RestoreFocus(m_queueList, capture)
end

-- ===========================================================================
-- FILTER LIST + RESULTS SUBLIST
-- ===========================================================================

local function ResetFilterToNone()
    m_activeFilterEntry = nil
    m_activeFilterFunc  = nil
    -- Vanilla's "no filter" entry is the one with Func=nil and the
    -- LOC_TECH_FILTER_NONE description; reproduce it here for OnFilterClicked.
    if OnFilterClicked then
        OnFilterClicked({ Func = nil, Description = "LOC_TECH_FILTER_NONE" })
    end
    RebuildMainTree()
end

local function CreateFilterResultButton(civicType)
    local capturedType = civicType
    local btn = mgr:CreateWidget(mgr:GenerateWidgetId("CAICivicsTreeFilterResult"), "Button", {
        Label             = function() return FormatRowLabel(capturedType) end,
        Tooltip           = function() return FormatRowTooltip(capturedType) end,
        DisabledPredicate = function()
            local node = GetUiNode(capturedType)
            if node and node.Top and node.Top:IsDisabled() then return true end
            return false
        end,
        FocusKey          = "filterResult:" .. tostring(capturedType),
    })
    btn:SetFocusSound("Main_Menu_Mouse_Over")
    btn:On("activate", function()
        -- Activate jumps to the node in the main tree. The results list is
        -- popped (its destroy listener resets the filter), so focus lands on
        -- a fully revealed main tree.
        mgr:RemoveFromStack(FILTER_RESULTS_ID)
        JumpToCivic(capturedType)
    end)
    btn:AddInputBindings({
        {
            Key       = Keys.VK_RETURN,
            IsControl = true,
            MSG       = KeyEvents.KeyUp,
            Action    = function()
                if not CanResearch(capturedType) then return true end
                ActivateAppendToQueue(capturedType)
                return true
            end,
        },
        {
            Key     = Keys.VK_RETURN,
            IsShift = true,
            MSG     = KeyEvents.KeyUp,
            Action  = function()
                if IsTutorialRunning and IsTutorialRunning() then return true end
                LuaEvents.OpenCivilopedia(capturedType)
                return true
            end,
        },
    })
    return btn
end

local function OpenFilterResults(entry)
    if not entry or not entry.Func then return end

    m_activeFilterEntry = entry
    m_activeFilterFunc  = entry.Func
    if OnFilterClicked then OnFilterClicked(entry.VanillaEntry) end
    RebuildMainTree()

    m_filterResults = mgr:CreateWidget(FILTER_RESULTS_ID, "List", {
        Label = function()
            return Locale.Lookup("LOC_CAI_CIVICS_TREE_FILTER_RESULTS", entry.Label)
        end,
    })

    -- Pre-order pass through eras matches the visual ordering of the main tree.
    for _, era in ipairs(g_kEras) do
        local eraCivics = {}
        for civicType, kEntry in pairs(g_kItemDefaults) do
            if kEntry.EraType == era.EraType and FilterMatchesCivic(civicType) then
                table.insert(eraCivics, { civicType = civicType, row = kEntry.UITreeRow or 0 })
            end
        end
        table.sort(eraCivics, function(a, b) return a.row < b.row end)
        for _, e in ipairs(eraCivics) do
            m_filterResults:AddChild(CreateFilterResultButton(e.civicType))
        end
    end

    -- Escape pops the results list (and the destroy listener below resets the
    -- filter). Without this, the input bubbles up to vanilla which closes the
    -- whole tree screen.
    m_filterResults:AddInputBindings({
        {
            Key    = Keys.VK_ESCAPE,
            MSG    = KeyEvents.KeyUp,
            Action = function()
                mgr:RemoveFromStack(FILTER_RESULTS_ID)
                return true
            end,
        },
    })

    -- Always reset the vanilla + CAI filter when the results list goes away —
    -- whether the user picked a result (we already removed it from the stack)
    -- or pressed Escape.
    m_filterResults:On("destroy", function()
        m_filterResults = nil
        ResetFilterToNone()
    end)

    mgr:Push(m_filterResults)
end

local function BuildFilterList()
    EnsureFilterEntries()
    m_filterList:ClearChildren()
    if not m_filterEntries then return end
    for _, entry in ipairs(m_filterEntries) do
        local capturedEntry = entry
        local btn = mgr:CreateWidget(mgr:GenerateWidgetId("CAICivicsTreeFilterBtn"), "Button", {
            Label    = function() return capturedEntry.Label end,
            FocusKey = "filter:" .. tostring(capturedEntry.Label),
        })
        btn:SetFocusSound("Main_Menu_Mouse_Over")
        btn:On("activate", function()
            if capturedEntry.Func then
                OpenFilterResults(capturedEntry)
            else
                ResetFilterToNone()
            end
        end)
        m_filterList:AddChild(btn)
    end
end

-- ===========================================================================
-- GOVERNMENT SUMMARY (read-only EditBox)
-- ===========================================================================

local function BuildGovernmentText()
    local function Count(ctrl) return tonumber(ControlText(ctrl)) or 0 end
    local parts = {}
    table.insert(parts, Locale.Lookup("LOC_CAI_GOVERNMENT_SUMMARY",
        ControlText(Controls.GovernmentTitle),
        Count(Controls.DiplomaticIconCount),
        Count(Controls.EconomicIconCount),
        Count(Controls.MilitaryIconCount),
        Count(Controls.WildcardIconCount)))

    if m_lastPlayerData and m_lastPlayerData[DATA_FIELD_GOVERNMENT] then
        local kGov = m_lastPlayerData[DATA_FIELD_GOVERNMENT]
        local function AddPolicies(ids, slotLabel)
            for _, policyId in ipairs(ids or {}) do
                if policyId ~= -1 then
                    local row = GameInfo.Policies[policyId]
                    if row then
                        table.insert(parts, slotLabel .. ": " .. Locale.Lookup(row.Name))
                    end
                end
            end
        end
        AddPolicies(kGov["DIPLOMATICPOLICIES"], Locale.Lookup("LOC_CAI_POLICY_SLOT_DIPLOMATIC"))
        AddPolicies(kGov["ECONOMICPOLICIES"], Locale.Lookup("LOC_CAI_POLICY_SLOT_ECONOMIC"))
        AddPolicies(kGov["MILITARYPOLICIES"], Locale.Lookup("LOC_CAI_POLICY_SLOT_MILITARY"))
        AddPolicies(kGov["WILDCARDPOLICIES"], Locale.Lookup("LOC_CAI_POLICY_SLOT_WILDCARD"))
    end

    return table.concat(parts, "\n")
end

local function RefreshGovernmentEdit()
    if not m_govEdit then return end
    m_govEditBuffer = BuildGovernmentText()
    m_govEdit:SetText(m_govEditBuffer, true)
end

-- ===========================================================================
-- PANEL LIFECYCLE
-- ===========================================================================

local function EnsurePanelBuilt()
    if m_panel or not mgr then return end

    BuildStaticMaps()
    EnsureFilterEntries()

    m_panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function() return ControlText(Controls.ModalScreenTitle) end,
    })

    -- 1) Queue list (hidden when empty)
    m_queueList = mgr:CreateWidget(QUEUE_LIST_ID, "List", {
        Label           = function() return Locale.Lookup("LOC_CAI_CIVICS_TREE_QUEUE_LIST") end,
        HiddenPredicate = function(w) return not w.Children or #w.Children == 0 end,
        SearchDepth     = 0,
    })
    m_panel:AddChild(m_queueList)

    -- 2) Filter buttons list (between queue and main tree)
    m_filterList = mgr:CreateWidget(FILTER_LIST_ID, "List", {
        Label       = function() return Locale.Lookup("LOC_CAI_CIVICS_TREE_FILTER") end,
        SearchDepth = 0,
    })
    m_panel:AddChild(m_filterList)
    BuildFilterList()

    -- 3) Main tree
    m_mainTree = mgr:CreateWidget(MAIN_TREE_ID, "Tree", {
        Label       = function() return Locale.Lookup("LOC_CAI_CIVICS_TREE_MAIN_LIST") end,
        SearchDepth = 2,
    })
    m_mainTree:AddInputBindings({
        {
            Key    = Keys.VK_BACK,
            MSG    = KeyEvents.KeyUp,
            Action = function()
                local source = table.remove(m_breadcrumbs)
                if not source then return false end
                -- Don't push the current civic onto the stack — Backspace is
                -- navigation back, not another forward hop.
                JumpToCivic(source, false)
                return true
            end,
        },
    })
    m_panel:AddChild(m_mainTree)

    -- 4) Government summary (read-only edit)
    m_govEdit = mgr:CreateWidget(GOV_EDIT_ID, "EditBox", {
        Label      = function() return Locale.Lookup("LOC_CAI_CIVICS_TREE_GOVERNMENT") end,
        AlwaysEdit = true,
        ReadOnly   = true,
    })
    m_panel:AddChild(m_govEdit)

    RebuildMainTree()
    RebuildQueueList()
    RefreshGovernmentEdit()
end

local function PushPanel()
    if not mgr then return end
    EnsurePanelBuilt()
    if not m_panel or mgr:GetWidgetById(PANEL_ID) then return end

    local playerCulture = GetLocalPlayerCulture()
    local hasCurrent = playerCulture and playerCulture:GetProgressingCivic() ~= -1
    local focusChild = hasCurrent and m_queueList or m_mainTree
    mgr:Push(m_panel, { focus = focusChild })
end

local function OnPanelClosedCAI()
    if mgr and m_panel then
        mgr:RemoveFromStack(FILTER_RESULTS_ID)
        mgr:RemoveFromStack(PANEL_ID)
    end
    m_panel             = nil
    m_queueList         = nil
    m_filterList        = nil
    m_mainTree          = nil
    m_govEdit           = nil
    m_filterResults     = nil
    m_civicsByType      = {}
    m_leadsToByType     = {}
    m_civicIndexToType  = {}
    m_lastPlayerData    = nil
    m_filterEntries     = nil
    m_activeFilterEntry = nil
    m_activeFilterFunc  = nil
    m_modifierCache     = nil
    m_govEditBuffer     = ""
    m_breadcrumbs       = {}
end

local function IsPanelOnStack()
    return m_panel and mgr and mgr:GetWidgetById(PANEL_ID) ~= nil
end

-- ===========================================================================
-- WRAPS
-- ===========================================================================

View = WrapFunc(View, function(orig, playerData)
    m_lastPlayerData = playerData
    orig(playerData)
    if m_panel then
        RebuildQueueList()
        RefreshGovernmentEdit()
    end
end)

local _origOnOpen = OnOpen
OnOpen = WrapFunc(OnOpen, function(orig)
    orig()
    PushPanel()
end)
LuaEvents.CivicsChooser_RaiseCivicsTree.Remove(_origOnOpen)
LuaEvents.LaunchBar_RaiseCivicsTree.Remove(_origOnOpen)
LuaEvents.CivicsChooser_RaiseCivicsTree.Add(OnOpen)
LuaEvents.LaunchBar_RaiseCivicsTree.Add(OnOpen)

Close = WrapFunc(Close, function(orig)
    OnPanelClosedCAI()
    orig()
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
    if mgr and IsPanelOnStack() then
        if mgr:HandleInput(pInputStruct) then return true end
    end
    return orig(pInputStruct)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)

-- ===========================================================================
-- EVENTS
-- ===========================================================================

local function RefocusIfCivicRow()
    if not IsPanelOnStack() then return end
    local focused = mgr:GetFocusedWidget()
    if not focused or not focused.FocusKey then return end
    local key = focused.FocusKey
    if string.sub(key, 1, 6) == "civic:"
        or string.sub(key, 1, 6) == "queue:" then
        mgr:Refocus()
    end
end

Events.CivicChanged.Add(function(ePlayer)
    if ePlayer == Game.GetLocalPlayer() and IsPanelOnStack() then
        RebuildQueueList()
        RefocusIfCivicRow()
    end
end)

Events.CivicQueueChanged.Add(function(ePlayer)
    if ePlayer == Game.GetLocalPlayer() and IsPanelOnStack() then
        RebuildQueueList()
        RefocusIfCivicRow()
    end
end)

Events.CivicCompleted.Add(function(ePlayer)
    if ePlayer ~= Game.GetLocalPlayer() or not IsPanelOnStack() then return end
    RebuildMainTree()
    RebuildQueueList()
end)

Events.CultureYieldChanged.Add(RefocusIfCivicRow)

local function RefreshGovIfOpen()
    if IsPanelOnStack() then
        Speak(BuildGovernmentText())
        RefreshGovernmentEdit()
    end
end

Events.GovernmentChanged.Add(function(ePlayer)
    if ePlayer == Game.GetLocalPlayer() then RefreshGovIfOpen() end
end)

Events.GovernmentPolicyChanged.Add(function(ePlayer)
    if ePlayer == Game.GetLocalPlayer() then RefreshGovIfOpen() end
end)

Events.GovernmentPolicyObsoleted.Add(function(ePlayer)
    if ePlayer == Game.GetLocalPlayer() then RefreshGovIfOpen() end
end)

Events.LocalPlayerTurnBegin.Add(function(ePlayer)
    if ePlayer == Game.GetLocalPlayer() and IsPanelOnStack() then
        RebuildQueueList()
    end
end)

Events.LocalPlayerChanged.Add(function() OnPanelClosedCAI() end)
