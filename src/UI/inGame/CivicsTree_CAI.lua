include("caiUtils")
include("inGameHelpers_CAI")
include("ToolTipHelper")
include("Civ6Common")

-- Expansion-aware include chain. Only XP2 ships a CivicsTree replacement (adds
-- revealed-only search; there is no XP1 civics variant and no alliance on the
-- civics side). CAI replaces the screen context outright, so it must load the
-- exact variant vanilla would.
if IsExpansion2Active and IsExpansion2Active() then
    include("CivicsTree_Expansion2")
else
    include("CivicsTree")
end

local mgr                 = ExposedMembers.CAI_UIManager

local PANEL_ID            = "CAICivicsTree_Panel"
local QUEUE_LIST_ID       = "CAICivicsTree_QueueList"
local FILTER_LIST_ID      = "CAICivicsTree_FilterList"
local MAIN_TREE_ID        = "CAICivicsTree_MainTree"
local TABLE_VIEW_ID       = "CAICivicsTree_TableView"
local UNLOCKS_LIST_ID     = "CAICivicsTree_UnlocksList"
local GOV_EDIT_ID         = "CAICivicsTree_GovEdit"
local CHANGE_VIEW_ID      = "CAICivicsTree_ChangeView"
local FILTER_RESULTS_ID   = "CAICivicsTree_FilterResults"

-- ===========================================================================
-- MODULE STATE
-- ===========================================================================
local m_panel             = nil ---@type UIWidget|nil
local m_queueList         = nil ---@type UIWidget|nil
local m_filterList        = nil ---@type UIWidget|nil
local m_mainTree          = nil ---@type UIWidget|nil
local m_tableView         = nil ---@type UIWidget|nil
local m_unlocksList       = nil ---@type UIWidget|nil
local m_govEdit           = nil ---@type UIWidget|nil
local m_changeViewBtn     = nil ---@type UIWidget|nil
local m_filterResults     = nil ---@type UIWidget|nil

-- "table" (default) or "tree". The toggle button swaps between them; the
-- inactive view is hidden so navigation skips it.
local m_viewMode          = "table"

local m_treeCivics        = {} ---@type table<string, UIWidget> civicType -> tree node
local m_tableCivics       = {} ---@type table<string, UIWidget> civicType -> table cell
local m_leadsToByType     = {} ---@type table<string, string[]>
local m_civicIndexToType  = {} ---@type table<integer, string>
local m_civicTierByType   = {} ---@type table<string, integer> civicType -> tier number within its era

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
    -- Unrevealed civics hide their identity in vanilla (the node shows
    -- "Not revealed"); never leak the real name through labels or ref links.
    local kLive = GetLiveData(civicType)
    if kLive and not kLive.IsRevealed then
        return Locale.Lookup("LOC_CIVICS_TREE_NOT_REVEALED_CIVIC")
    end
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
-- RELATED-CIVIC NAMING (prereqs / leads-to)
-- An unrevealed civic hides its name but its connector line is still drawn, so
-- we convey its tree location instead: "<era>, Tier N" (era omitted when it
-- matches the civic we're listing from). These run at speak time, after
-- BuildStaticMaps has populated m_civicTierByType.
-- ===========================================================================

local function IsCivicHidden(civicType)
    local kLive = GetLiveData(civicType)
    return kLive ~= nil and kLive.IsRevealed == false
end

---@return string[] prefix parts ("<era>", "Tier N"), possibly empty
local function UnrevealedLocationPrefix(civicType, currentEraType)
    local parts = {}
    local kEntry = g_kItemDefaults[civicType]
    if kEntry and kEntry.EraType and kEntry.EraType ~= currentEraType then
        local era = g_kEras and g_kEras[kEntry.EraType]
        if era and era.Description then table.insert(parts, Locale.Lookup(era.Description)) end
    end
    local tier = m_civicTierByType[civicType]
    if tier then table.insert(parts, Locale.Lookup("LOC_CAI_TREE_TIER", tier)) end
    return parts
end

-- Per-entry label (used for the individually focusable ref-link rows).
local function GetRelatedCivicLabel(civicType, currentEraType)
    if not IsCivicHidden(civicType) then return GetCivicName(civicType) end
    local prefix = UnrevealedLocationPrefix(civicType, currentEraType)
    local notRevealed = Locale.Lookup("LOC_CIVICS_TREE_NOT_REVEALED_CIVIC")
    if #prefix > 0 then return table.concat(prefix, ", ") .. " " .. notRevealed end
    return notRevealed
end

-- Comma-list for the tooltip: revealed civics by name, unrevealed grouped by
-- location, e.g. "Craftsmanship, Future Era, Tier 1: Not revealed, Not revealed".
local function FormatRelatedCivicNames(civicTypes, currentEraType)
    local out, groupOrder, groups = {}, {}, {}
    for _, ct in ipairs(civicTypes) do
        if not IsCivicHidden(ct) then
            table.insert(out, GetCivicName(ct))
        else
            local prefix = UnrevealedLocationPrefix(ct, currentEraType)
            local key = table.concat(prefix, "|")
            local g = groups[key]
            if not g then
                g = { prefix = prefix, count = 0 }
                groups[key] = g
                table.insert(groupOrder, g)
            end
            g.count = g.count + 1
        end
    end
    local notRevealed = Locale.Lookup("LOC_CIVICS_TREE_NOT_REVEALED_CIVIC")
    for _, g in ipairs(groupOrder) do
        local prefixStr = table.concat(g.prefix, ", ")
        if g.count == 1 then
            -- "Future Era, Tier 1 Not revealed"
            table.insert(out, prefixStr ~= "" and (prefixStr .. " " .. notRevealed) or notRevealed)
        else
            -- "Tier 1: Not revealed, Not revealed"
            local items = {}
            for _ = 1, g.count do table.insert(items, notRevealed) end
            local joined = table.concat(items, ", ")
            table.insert(out, prefixStr ~= "" and (prefixStr .. ": " .. joined) or joined)
        end
    end
    return out
end

-- ===========================================================================
-- LABEL / TOOLTIP
-- ===========================================================================

local function FormatRowLabel(civicType)
    local kLive = GetLiveData(civicType)
    if kLive and not kLive.IsRevealed then
        return GetCivicName(civicType)
    end
    local parts = {}
    AppendIfNonEmpty(parts, GetCivicName(civicType))
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
    -- Vanilla hides an unrevealed civic's cost / turns / description / boost /
    -- obsoletes / unlocks / awards (generic node tooltip + hidden unlock stack).
    -- But it still draws the prereq/leads-to connector lines for every node, so
    -- the topology is visible — keep those even when unrevealed.
    local kLive = GetLiveData(civicType)
    local revealed = not (kLive and not kLive.IsRevealed)

    local parts = {}

    if revealed then
        AppendIfNonEmpty(parts, GetCivicCostText(civicType))
        AppendIfNonEmpty(parts, GetCivicTurnsText(civicType))
        AppendIfNonEmpty(parts, GetCivicProgressText(civicType))
        AppendIfNonEmpty(parts, GetCivicDescriptionText(civicType))
        AppendIfNonEmpty(parts, GetCivicBoostText(civicType))
        local obsoletes = GetObsoletePolicyNames(CivicKData(civicType))
        if #obsoletes > 0 then
            AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_CIVIC_OBSOLETES_HEADER", table.concat(obsoletes, ", ")))
        end
    end

    local kStatic = g_kItemDefaults[civicType]
    local currentEraType = kStatic and kStatic.EraType

    local prereqTypes = {}
    for _, pt in ipairs(kStatic and kStatic.Prereqs or {}) do
        if pt ~= PREREQ_ID_TREE_START then table.insert(prereqTypes, pt) end
    end
    if #prereqTypes > 0 then
        local names = FormatRelatedCivicNames(prereqTypes, currentEraType)
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_CIVIC_PREREQS_HEADER", table.concat(names, ", ")))
    end

    local leadsTo = m_leadsToByType[civicType]
    if leadsTo and #leadsTo > 0 then
        local names = FormatRelatedCivicNames(leadsTo, currentEraType)
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_CIVIC_LEADS_TO_HEADER", table.concat(names, ", ")))
    end

    if revealed then
        local unlocks = GetCivicUnlockObjects(CivicKData(civicType))
        if #unlocks > 0 then
            local names = {}
            for _, u in ipairs(unlocks) do table.insert(names, u.Name) end
            AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_CIVIC_UNLOCKS_HEADER", table.concat(names, ", ")))
        end
        AppendIfNonEmpty(parts, GetCivicAwardsText(GetModifierCache()[civicType]))
    end

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
    m_civicTierByType  = {}

    -- Collect each era's distinct Column values so we can rank a civic's tier
    -- (1-based position of its Column among the era's columns). Mirrors the
    -- Column grouping used when building the tree/table tiers.
    local eraColumnSet = {} ---@type table<string, table<integer, boolean>>
    for civicType, kEntry in pairs(g_kItemDefaults) do
        local row = GameInfo.Civics[civicType]
        if row then m_civicIndexToType[row.Index] = civicType end
        for _, prereqType in ipairs(kEntry.Prereqs or {}) do
            if prereqType ~= PREREQ_ID_TREE_START then
                m_leadsToByType[prereqType] = m_leadsToByType[prereqType] or {}
                table.insert(m_leadsToByType[prereqType], civicType)
            end
        end
        if kEntry.EraType then
            eraColumnSet[kEntry.EraType] = eraColumnSet[kEntry.EraType] or {}
            eraColumnSet[kEntry.EraType][kEntry.Column or 0] = true
        end
    end

    local tierByEraColumn = {} ---@type table<string, table<integer, integer>>
    for eraType, colSet in pairs(eraColumnSet) do
        local cols = {}
        for c in pairs(colSet) do table.insert(cols, c) end
        table.sort(cols)
        local rank = {}
        for i, c in ipairs(cols) do rank[c] = i end
        tierByEraColumn[eraType] = rank
    end
    for civicType, kEntry in pairs(g_kItemDefaults) do
        local rank = kEntry.EraType and tierByEraColumn[kEntry.EraType]
        m_civicTierByType[civicType] = rank and rank[kEntry.Column or 0] or nil
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

-- The focusable widget for a civic in the currently active view.
local function GetActiveCivicWidget(civicType)
    if m_viewMode == "table" then return m_tableCivics[civicType] end
    return m_treeCivics[civicType]
end

-- Walk a widget's ancestor chain for the enclosing tree era and tier nodes
-- (identified by their FocusKey prefixes). Returns nil for widgets outside the
-- tree (queue/filter rows), which the caller treats as "everything diverges".
local function GetEnclosingEraTier(widget)
    local era, tier
    local node = widget
    while node do
        local key = node.FocusKey
        if key then
            if not tier and string.sub(key, 1, 5) == "tier:" then tier = node end
            if not era and string.sub(key, 1, 4) == "era:" then era = node end
        end
        node = node.Parent
    end
    return era, tier
end

local function JumpToCivic(civicType, recordBreadcrumb)
    local target = GetActiveCivicWidget(civicType)
    if not target then return end

    if recordBreadcrumb then
        local source = GetFocusedCivicType()
        if source and source ~= civicType then
            table.insert(m_breadcrumbs, source)
        end
    end

    -- Tree mode: era/tier nodes are IgnoreWhenNotFocused, so focus speech won't
    -- mention them on a jump. Fold the diverging era/tier into the spoken line,
    -- announcing only what actually changed (compared by widget, so Tier 1 of a
    -- different era still counts as different). Table mode gets the era for free
    -- via the column header's natural focus speech, so it just says the civic.
    local parts = { GetCivicName(civicType) or "" }
    if m_viewMode == "tree" then
        local srcEra, srcTier = GetEnclosingEraTier(mgr:GetFocusedWidget())
        local tgtEra, tgtTier = GetEnclosingEraTier(target)
        if tgtTier and tgtTier ~= srcTier then AppendIfNonEmpty(parts, tgtTier:GetLabel()) end
        if tgtEra and tgtEra ~= srcEra then AppendIfNonEmpty(parts, tgtEra:GetLabel()) end
    end

    Speak(Locale.Lookup("LOC_CAI_CIVICS_TREE_JUMPING", table.concat(parts, ", ")), true)
    mgr:SetFocus(target)
end

-- ===========================================================================
-- REFERENCE LINKS + DETAIL CHILDREN
-- ===========================================================================

local function CreateRefLink(parentWidget, civicType, currentEraType)
    local capturedType = civicType
    local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAICivicsTreeRef"), "TreeItem", {
        Label             = function() return GetRelatedCivicLabel(capturedType, currentEraType) end,
        HiddenPredicate   = function() return m_treeCivics[capturedType] == nil end,
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
    -- Unlocks (and the Path bucket) are hidden for unrevealed civics, but the
    -- prereq/leads-to buckets mirror the connector lines vanilla always draws,
    -- so they stay regardless of reveal status.
    local kStatic = g_kItemDefaults[civicType]
    local currentEraType = kStatic and kStatic.EraType

    -- 1) Unlocks bucket (revealed only) — only entries with descriptions get
    --    their own child; each child has Shift+Enter Civilopedia.
    if IsCivicRevealed(civicType) then
        local unlockChildren = {}
        for _, unlock in ipairs(GetCivicUnlockObjects(CivicKData(civicType))) do
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
    end

    -- 2) Prerequisites
    local prereqTypes = {}
    for _, pt in ipairs(kStatic and kStatic.Prereqs or {}) do
        if pt ~= PREREQ_ID_TREE_START then table.insert(prereqTypes, pt) end
    end
    if #prereqTypes > 0 then
        local node = mgr:CreateWidget(mgr:GenerateWidgetId("CAICivicsTreePrereqs"), "TreeItem", {
            Label = function() return Locale.Lookup("LOC_CAI_CIVICS_TREE_PREREQS") end,
        })
        for _, pt in ipairs(prereqTypes) do CreateRefLink(node, pt, currentEraType) end
        civicItem:AddChild(node)
    end

    -- 3) Leads to
    local leadsTo = m_leadsToByType[civicType]
    if leadsTo and #leadsTo > 0 then
        local node = mgr:CreateWidget(mgr:GenerateWidgetId("CAICivicsTreeLeadsTo"), "TreeItem", {
            Label = function() return Locale.Lookup("LOC_CAI_CIVICS_TREE_LEADS_TO") end,
        })
        for _, lt in ipairs(leadsTo) do CreateRefLink(node, lt, currentEraType) end
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
                if ct then CreateRefLink(node, ct, currentEraType) end
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
                if not IsCivicRevealed(capturedType) then return true end
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
    m_treeCivics = {}

    for _, era in ipairs(g_kEras) do
        -- Group this era's filtered civics by tree Column; each distinct Column
        -- is one prereq tier (a Column-N civic's prereqs sit in Column N-1), so
        -- tier 1 holds the era's root civics, tier 2 their leads-to, and so on.
        local byColumn, colValues = {}, {}
        for civicType, kEntry in pairs(g_kItemDefaults) do
            if kEntry.EraType == era.EraType and FilterMatchesCivic(civicType) then
                local col = kEntry.Column or 0
                if not byColumn[col] then byColumn[col] = {}; table.insert(colValues, col) end
                table.insert(byColumn[col], { civicType = civicType, row = kEntry.UITreeRow or 0 })
            end
        end
        if #colValues > 0 then
            table.sort(colValues)

            local capturedDescription = era.Description
            local eraItem = mgr:CreateWidget(mgr:GenerateWidgetId("CAICivicsTreeEra"), "TreeItem", {
                Label    = function() return Locale.Lookup(capturedDescription) end,
                FocusKey = "era:" .. tostring(era.EraType),
            })

            for tierIndex, colVal in ipairs(colValues) do
                local tierNumber = tierIndex
                local tierItem = mgr:CreateWidget(mgr:GenerateWidgetId("CAICivicsTreeTier"), "TreeItem", {
                    Label    = function() return Locale.Lookup("LOC_CAI_TREE_TIER", tierNumber) end,
                    FocusKey = "tier:" .. tostring(era.EraType) .. ":" .. tostring(colVal),
                })

                local tierCivics = byColumn[colVal]
                table.sort(tierCivics, function(a, b) return a.row < b.row end)
                for _, entry in ipairs(tierCivics) do
                    local widget = BuildCivicNode(entry.civicType)
                    m_treeCivics[entry.civicType] = widget
                    tierItem:AddChild(widget)
                end

                -- Auto-expanded: expanding the era reveals each tier's civics
                -- directly, without a separate expand step per tier.
                tierItem:Expand(true)
                eraItem:AddChild(tierItem)
            end

            -- Whenever the era is (re-)expanded, force every tier open. This
            -- keeps tiers visible even after a recursive collapse closes them.
            eraItem:On("expanded", function(self)
                for _, tier in ipairs(self.Children) do
                    tier:Expand(true)
                end
            end)

            m_mainTree:AddChild(eraItem)
        end
    end

    mgr:RestoreFocus(m_mainTree, capture)
end

-- ===========================================================================
-- TABLE VIEW (eras = columns, tier = a Column-group within an era, cells =
-- civic Buttons stacked by UITreeRow). A sibling unlocks list mirrors the
-- focused civic's described unlocks.
-- ===========================================================================

-- Rebuild the unlocks list to mirror the focused civic. Focus stays on the
-- table cell; the list is a passive sibling, so no capture/restore is needed.
local function RebuildUnlocksList(civicType)
    if not m_unlocksList then return end
    m_unlocksList:ClearChildren()
    if not civicType then return end
    if not IsCivicRevealed(civicType) then return end
    for _, unlock in ipairs(GetCivicUnlockObjects(CivicKData(civicType))) do
        if unlock.Description then
            m_unlocksList:AddChild(CreateUnlockChild(mgr, unlock, "CAICivicsTableUnlock"))
        end
    end
end

local function BuildCivicCell(civicType)
    local capturedType = civicType
    local cell = mgr:CreateWidget(mgr:GenerateWidgetId("CAICivicsTableCivic"), "Button", {
        Label             = function() return FormatRowLabel(capturedType) end,
        Tooltip           = function() return FormatRowTooltip(capturedType) end,
        DisabledPredicate = function()
            local node = GetUiNode(capturedType)
            if node and node.Top and node.Top:IsDisabled() then return true end
            return not CanResearch(capturedType)
        end,
        FocusKey          = "civic:" .. tostring(capturedType),
    })
    cell:SetFocusSound("Main_Menu_Mouse_Over")

    cell:On("activate", function(w)
        if w:IsDisabled() then return end
        ActivateSetCurrent(capturedType)
    end)

    -- Keep the unlocks list in step with the focused civic.
    cell:On("focus_enter", function(w)
        if w:IsFocused() then RebuildUnlocksList(capturedType) end
    end)

    cell:AddInputBindings({
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
                if not IsCivicRevealed(capturedType) then return true end
                if IsTutorialRunning and IsTutorialRunning() then return true end
                LuaEvents.OpenCivilopedia(capturedType)
                return true
            end,
        },
    })
    return cell
end

local function MakeTableSpacer()
    return mgr:CreateWidget(mgr:GenerateWidgetId("CAICivicTableSpacer"), "StaticText", {
        HiddenPredicate = function() return true end,
    })
end

local function RebuildTableView()
    if not m_tableView then return end

    local capture = mgr:CaptureFocusKey(m_tableView)
    m_tableView:ClearChildren()
    m_tableCivics = {}

    for _, era in ipairs(g_kEras) do
        -- Group this era's filtered civics by their tree Column; each distinct
        -- Column becomes one side-by-side tier, ordered left to right.
        local byColumn, colValues = {}, {}
        local rowMin, rowMax = 0, 0
        for civicType, kEntry in pairs(g_kItemDefaults) do
            if kEntry.EraType == era.EraType and FilterMatchesCivic(civicType) then
                local col = kEntry.Column or 0
                if not byColumn[col] then byColumn[col] = {}; table.insert(colValues, col) end
                local row = kEntry.UITreeRow or 0
                table.insert(byColumn[col], { civicType = civicType, row = row })
                if row < rowMin then rowMin = row end
                if row > rowMax then rowMax = row end
            end
        end
        if #colValues > 0 then
            table.sort(colValues)
            local capturedDescription = era.Description
            local column = m_tableView:AddColumn({
                header = function() return Locale.Lookup(capturedDescription) end,
                width  = #colValues,
            })
            for tierIndex, colVal in ipairs(colValues) do
                local tierCivics = byColumn[colVal]
                -- Build a sparse map from row -> entry
                local byRow = {}
                for _, entry in ipairs(tierCivics) do byRow[entry.row] = entry end
                -- Fill every slot from rowMin to rowMax; real cells at occupied
                -- rows, hidden spacers elsewhere so indices align across tiers.
                for r = rowMin, rowMax do
                    local entry = byRow[r]
                    if entry then
                        local cell = BuildCivicCell(entry.civicType)
                        m_tableCivics[entry.civicType] = cell
                        m_tableView:AddItem(column, tierIndex, cell)
                    else
                        m_tableView:AddItem(column, tierIndex, MakeTableSpacer())
                    end
                end
            end
        end
    end

    mgr:RestoreFocus(m_tableView, capture)
end

-- Rebuild whichever civic views exist, keeping both in sync with game/filter
-- state so jumps land correctly regardless of the active mode.
local function RebuildCivicsViews()
    RebuildMainTree()
    RebuildTableView()
end

local function ToggleViewMode()
    m_viewMode = (m_viewMode == "tree") and "table" or "tree"
    local active = (m_viewMode == "table") and m_tableView or m_mainTree
    if active then mgr:SetFocus(active) end
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
                if not IsCivicRevealed(capturedType) then return true end
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
    RebuildCivicsViews()
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
                if not IsCivicRevealed(capturedType) then return true end
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
    RebuildCivicsViews()

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
                table.insert(eraCivics, { civicType = civicType, col = kEntry.Column or 0, row = kEntry.UITreeRow or 0 })
            end
        end
        table.sort(eraCivics, function(a, b)
            if a.col ~= b.col then return a.col < b.col end
            return a.row < b.row
        end)
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

    -- 3) Main tree (hidden in table mode)
    m_mainTree = mgr:CreateWidget(MAIN_TREE_ID, "Tree", {
        Label           = function() return Locale.Lookup("LOC_CAI_CIVICS_TREE_MAIN_LIST") end,
        HiddenPredicate = function() return m_viewMode ~= "tree" end,
        SearchDepth     = 3,
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

    -- 4) Table view (hidden in tree mode): eras = columns, tiers = Column-groups
    m_tableView = mgr:CreateWidget(TABLE_VIEW_ID, "Table", {
        Label           = function() return Locale.Lookup("LOC_CAI_CIVICS_TREE_TABLE") end,
        HiddenPredicate = function() return m_viewMode ~= "table" end,
    })
    m_panel:AddChild(m_tableView)

    -- 5) Unlocks list beside the table; mirrors the focused civic (table mode
    --    only, and only when the focused civic has described unlocks)
    m_unlocksList = mgr:CreateWidget(UNLOCKS_LIST_ID, "List", {
        Label           = function() return Locale.Lookup("LOC_CAI_CIVICS_TREE_UNLOCKS") end,
        HiddenPredicate = function(w)
            return m_viewMode ~= "table" or not w.Children or #w.Children == 0
        end,
        SearchDepth     = 0,
    })
    m_panel:AddChild(m_unlocksList)

    -- 6) Government summary (read-only edit)
    m_govEdit = mgr:CreateWidget(GOV_EDIT_ID, "EditBox", {
        Label      = function() return Locale.Lookup("LOC_CAI_CIVICS_TREE_GOVERNMENT") end,
        AlwaysEdit = true,
        ReadOnly   = true,
    })
    m_panel:AddChild(m_govEdit)

    -- 7) View toggle — must remain the last child. Label reflects the mode it
    --    switches *to*.
    m_changeViewBtn = mgr:CreateWidget(CHANGE_VIEW_ID, "Button", {
        Label = function()
            return Locale.Lookup(m_viewMode == "table"
                and "LOC_CAI_TREE_SWITCH_TO_TREE"
                or  "LOC_CAI_TREE_SWITCH_TO_TABLE")
        end,
    })
    m_changeViewBtn:On("activate", function() ToggleViewMode() end)
    m_panel:AddChild(m_changeViewBtn)

    RebuildCivicsViews()
    RebuildQueueList()
    RefreshGovernmentEdit()
end

local function PushPanel()
    if not mgr then return end
    EnsurePanelBuilt()
    if not m_panel or mgr:GetWidgetById(PANEL_ID) then return end

    local playerCulture = GetLocalPlayerCulture()
    local hasCurrent = playerCulture and playerCulture:GetProgressingCivic() ~= -1
    local activeView = (m_viewMode == "table") and m_tableView or m_mainTree
    local focusChild = hasCurrent and m_queueList or activeView
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
    m_tableView         = nil
    m_unlocksList       = nil
    m_govEdit           = nil
    m_changeViewBtn     = nil
    m_filterResults     = nil
    m_viewMode          = "table"
    m_treeCivics        = {}
    m_tableCivics       = {}
    m_leadsToByType     = {}
    m_civicIndexToType  = {}
    m_civicTierByType   = {}
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
    RebuildCivicsViews()
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
