include("caiUtils")
include("inGameHelpers_CAI")
include("ToolTipHelper")
include("Civ6Common")

-- Expansion-aware include chain. XP1 adds AllianceResearchSupport (per-node
-- alliance research icon/tooltip); XP2 includes XP1 and adds revealed-only
-- search. CAI replaces the screen context outright, so it must load the exact
-- variant vanilla would.
if IsExpansion2Active and IsExpansion2Active() then
    include("TechTree_Expansion2")
elseif IsExpansion1Active and IsExpansion1Active() then
    include("TechTree_Expansion1")
else
    include("TechTree")
end

local mgr                 = ExposedMembers.CAI_UIManager

local PANEL_ID            = "CAITechTree_Panel"
local QUEUE_LIST_ID       = "CAITechTree_QueueList"
local FILTER_LIST_ID      = "CAITechTree_FilterList"
local MAIN_TREE_ID        = "CAITechTree_MainTree"
local TABLE_VIEW_ID       = "CAITechTree_TableView"
local UNLOCKS_LIST_ID     = "CAITechTree_UnlocksList"
local CHANGE_VIEW_ID      = "CAITechTree_ChangeView"
local FILTER_RESULTS_ID   = "CAITechTree_FilterResults"

-- ===========================================================================
-- MODULE STATE
-- ===========================================================================
local m_panel             = nil ---@type UIWidget|nil
local m_queueList         = nil ---@type UIWidget|nil
local m_filterList        = nil ---@type UIWidget|nil
local m_mainTree          = nil ---@type UIWidget|nil
local m_tableView         = nil ---@type UIWidget|nil
local m_unlocksList       = nil ---@type UIWidget|nil
local m_changeViewBtn     = nil ---@type UIWidget|nil
local m_filterResults     = nil ---@type UIWidget|nil

-- "table" (default) or "tree". The toggle button swaps between them; the
-- inactive view is hidden so navigation skips it.
local m_viewMode          = "table"

local m_treeTechs         = {} ---@type table<string, UIWidget> techType -> tree node
local m_tableTechs        = {} ---@type table<string, UIWidget> techType -> table cell
local m_leadsToByType     = {} ---@type table<string, string[]>
local m_techIndexToType   = {} ---@type table<integer, string>
local m_techTierByType    = {} ---@type table<string, integer> techType -> tier number within its era
-- Prereq-based column per tech (1 = no in-era prereqs). Computed by CAI rather
-- than read from vanilla's kEntry.Column, because the base tech tree lays out
-- columns by COST, not prerequisites. We mirror the civics tree (and vanilla's
-- "PREREQ" layout method) so tiers reflect the research dependency chain.
local m_techColumnByType  = {} ---@type table<string, integer> techType -> prereq column within its era

local m_filterEntries     = nil ---@type table|nil
local m_activeFilterEntry = nil ---@type table|nil
local m_activeFilterFunc  = nil ---@type function|nil
local m_lastPlayerData    = nil ---@type table|nil

-- Breadcrumb stack of techTypes the user navigated *away from* via a ref
-- link. Backspace in the main tree pops the most recent one and jumps back.
local m_breadcrumbs       = {} ---@type string[]

-- ===========================================================================
-- LIVE-CONTROL ACCESSORS
-- ===========================================================================

local function GetLocalPlayerTechs()
    local ePlayer = Game.GetLocalPlayer()
    if ePlayer == PlayerTypes.NONE then return nil, -1 end
    local kPlayer = Players[ePlayer]
    if not kPlayer then return nil, -1 end
    return kPlayer:GetTechs(), ePlayer
end

local function GetUiNode(techType)
    return g_uiNodes and g_uiNodes[techType] or nil
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

local function GetLiveData(techType)
    if not m_lastPlayerData then return nil end
    local liveTable = m_lastPlayerData[DATA_FIELD_LIVEDATA]
    return liveTable and liveTable[techType] or nil
end

-- ===========================================================================
-- ROW DATA
-- ===========================================================================

local function GetTechName(techType)
    -- Unrevealed techs hide their identity in vanilla (the node shows
    -- "Not revealed"); never leak the real name through labels or ref links.
    local kLive = GetLiveData(techType)
    if kLive and not kLive.IsRevealed then
        return Locale.Lookup("LOC_TECH_TREE_NOT_REVEALED_TECH")
    end
    local node = GetUiNode(techType)
    local name = ControlText(node and node.NodeName)
    if name ~= "" then return name end
    local row = GameInfo.Technologies[techType]
    if row and row.Name then return Locale.Lookup(row.Name) end
    return techType
end

local function GetTechCostText(techType)
    local kLive = GetLiveData(techType)
    if kLive and kLive.Cost and kLive.Cost > 0 then
        return Locale.Lookup("LOC_CAI_RESEARCH_COST", kLive.Cost)
    end
    return nil
end

local function GetTechTurnsText(techType)
    local node = GetUiNode(techType)
    if node and not ControlIsHidden(node.Turns) then
        local raw = ControlText(node.Turns)
        local n = string.match(raw, "%[ICON_Turn%](%d+)")
        if n then return Locale.Lookup("LOC_CAI_RESEARCH_TURNS", tonumber(n)) end
        if raw ~= "" then return raw end
    end
    local kLive = GetLiveData(techType)
    if kLive and kLive.TurnsLeft and kLive.TurnsLeft >= 0 then
        return Locale.Lookup("LOC_CAI_RESEARCH_TURNS", kLive.TurnsLeft)
    end
    return nil
end

local function GetTechProgressText(techType)
    local kLive = GetLiveData(techType)
    if not kLive or not kLive.Progress or not kLive.Cost or kLive.Cost <= 0 then
        return nil
    end
    local pct = math.floor((kLive.Progress / kLive.Cost) * 100 + 0.5)
    if pct <= 0 then return nil end
    return Locale.Lookup("LOC_CAI_RESEARCH_PROGRESS", pct)
end

local function GetTechDescriptionText(techType)
    local row = GameInfo.Technologies[techType]
    local desc = row and row.Description or nil
    if desc and desc ~= "" then
        local text = Locale.Lookup(desc)
        if text and text ~= "" then return text end
    end
    return nil
end

local function GetTechBoostText(techType)
    local kStatic = g_kItemDefaults[techType]
    if not kStatic or not kStatic.IsBoostable then return nil end
    local kLive = GetLiveData(techType)
    local prefix = Locale.Lookup((kLive and kLive.IsBoosted)
        and "LOC_BOOST_BOOSTED" or "LOC_BOOST_TO_BOOST")
    local trigger = kStatic.BoostText or ""
    if trigger == "" then return prefix end
    return prefix .. " " .. trigger
end

local function GetTechStatusLabel(kLive)
    if not kLive then return nil end
    local status = kLive.IsRevealed and kLive.Status or ITEM_STATUS.UNREVEALED
    if status == ITEM_STATUS.RESEARCHED then
        return Locale.Lookup("LOC_CAI_TECH_STATUS_RESEARCHED")
    elseif status == ITEM_STATUS.CURRENT then
        return Locale.Lookup("LOC_CAI_TECH_STATUS_CURRENT")
    elseif status == ITEM_STATUS.BLOCKED then
        return Locale.Lookup("LOC_CAI_TECH_STATUS_BLOCKED")
    elseif status == ITEM_STATUS.UNREVEALED then
        return Locale.Lookup("LOC_CAI_TECH_STATUS_UNREVEALED")
    end
    return nil
end

local function GetTechQueuePosition(techType)
    local row = GameInfo.Technologies[techType]
    if not row then return nil end
    local playerTechs = GetLocalPlayerTechs()
    if not playerTechs then return nil end
    local queue = playerTechs:GetResearchQueue()
    if not queue then return nil end
    for i, id in ipairs(queue) do
        if id == row.Index then return i end
    end
    return nil
end

-- XP1/XP2 only: the expansion's PopulateNode populates node.Alliance /
-- node.AllianceIcon when an ally has or is researching this tech. Mirrors the
-- research chooser's alliance tooltip line.
local function GetAllianceText(techType)
    local node = GetUiNode(techType)
    if not node or not node.Alliance or not node.AllianceIcon then return nil end
    if ControlIsHidden(node.Alliance) then return nil end
    local tip = NormalizeFormattedText(node.AllianceIcon:GetToolTipString())
    if tip == "" then return nil end
    return Locale.Lookup("LOC_CAI_RESEARCH_ALLIANCE_BONUS", tip)
end

local function TechKData(techType)
    return { TechType = techType, Type = techType }
end

-- ===========================================================================
-- RELATED-TECH NAMING (prereqs / leads-to)
-- An unrevealed tech hides its name but its connector line is still drawn, so
-- we convey its tree location instead: "<era>, Tier N" (era omitted when it
-- matches the tech we're listing from). These run at speak time, after
-- BuildStaticMaps has populated m_techTierByType.
-- ===========================================================================

local function IsTechHidden(techType)
    local kLive = GetLiveData(techType)
    return kLive ~= nil and kLive.IsRevealed == false
end

---@return string[] prefix parts ("<era>", "Tier N"), possibly empty
local function UnrevealedLocationPrefix(techType, currentEraType)
    local parts = {}
    local kEntry = g_kItemDefaults[techType]
    if kEntry and kEntry.EraType and kEntry.EraType ~= currentEraType then
        local era = g_kEras and g_kEras[kEntry.EraType]
        if era and era.Description then table.insert(parts, Locale.Lookup(era.Description)) end
    end
    local tier = m_techTierByType[techType]
    if tier then table.insert(parts, Locale.Lookup("LOC_CAI_TREE_TIER", tier)) end
    return parts
end

-- Per-entry label (used for the individually focusable ref-link rows).
local function GetRelatedTechLabel(techType, currentEraType)
    if not IsTechHidden(techType) then return GetTechName(techType) end
    local prefix = UnrevealedLocationPrefix(techType, currentEraType)
    local notRevealed = Locale.Lookup("LOC_TECH_TREE_NOT_REVEALED_TECH")
    if #prefix > 0 then return table.concat(prefix, ", ") .. " " .. notRevealed end
    return notRevealed
end

-- Comma-list for the tooltip: revealed techs by name, unrevealed grouped by
-- location, e.g. "Pottery, Future Era, Tier 1: Not revealed, Not revealed".
local function FormatRelatedTechNames(techTypes, currentEraType)
    local out, groupOrder, groups = {}, {}, {}
    for _, tt in ipairs(techTypes) do
        if not IsTechHidden(tt) then
            table.insert(out, GetTechName(tt))
        else
            local prefix = UnrevealedLocationPrefix(tt, currentEraType)
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
    local notRevealed = Locale.Lookup("LOC_TECH_TREE_NOT_REVEALED_TECH")
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

local function FormatRowLabel(techType)
    local kLive = GetLiveData(techType)
    if kLive and not kLive.IsRevealed then
        return GetTechName(techType)
    end
    local parts = {}
    AppendIfNonEmpty(parts, GetTechName(techType))
    AppendIfNonEmpty(parts, GetTechStatusLabel(kLive))
    if kLive and kLive.IsRecommended then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_TECH_FILTER_RECOMMENDED"))
    end
    local qpos = GetTechQueuePosition(techType)
    if qpos then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_RESEARCH_QUEUED", qpos))
    end
    return table.concat(parts, ", ")
end

local function FormatRowTooltip(techType)
    -- Vanilla hides an unrevealed tech's cost / turns / description / boost /
    -- reveals / unlocks (generic node tooltip + hidden unlock stack). But it
    -- still draws the prereq/leads-to connector lines for every node, so the
    -- topology is visible — keep those even when unrevealed.
    local kLive = GetLiveData(techType)
    local revealed = not (kLive and not kLive.IsRevealed)

    local parts = {}

    if revealed then
        AppendIfNonEmpty(parts, GetTechCostText(techType))
        AppendIfNonEmpty(parts, GetTechTurnsText(techType))
        AppendIfNonEmpty(parts, GetTechProgressText(techType))
        AppendIfNonEmpty(parts, GetTechDescriptionText(techType))
        AppendIfNonEmpty(parts, GetTechBoostText(techType))
        AppendIfNonEmpty(parts, GetAllianceText(techType))
        local group = GetTechUnlockObjects(TechKData(techType))
        if #group.Reveals > 0 then
            local names = {}
            for _, r in ipairs(group.Reveals) do
                table.insert(names, Locale.Lookup("LOC_TOOLTIP_UNLOCKS_RESOURCE", r.Name))
            end
            AppendIfNonEmpty(parts, table.concat(names, ", "))
        end
        if #group.Unlocks > 0 then
            local names = {}
            for _, u in ipairs(group.Unlocks) do table.insert(names, u.Name) end
            AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_RESEARCH_UNLOCKS_HEADER", table.concat(names, ", ")))
        end
    end

    local kStatic = g_kItemDefaults[techType]
    local currentEraType = kStatic and kStatic.EraType

    local prereqTypes = {}
    for _, pt in ipairs(kStatic and kStatic.Prereqs or {}) do
        if pt ~= PREREQ_ID_TREE_START then table.insert(prereqTypes, pt) end
    end
    if #prereqTypes > 0 then
        local names = FormatRelatedTechNames(prereqTypes, currentEraType)
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_RESEARCH_PREREQS_HEADER", table.concat(names, ", ")))
    end

    local leadsTo = m_leadsToByType[techType]
    if leadsTo and #leadsTo > 0 then
        local names = FormatRelatedTechNames(leadsTo, currentEraType)
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_RESEARCH_LEADS_TO_HEADER", table.concat(names, ", ")))
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
        { "TECHFILTER_FAITH",        "LOC_TECH_FILTER_FAITH" },
        { "TECHFILTER_HOUSING",      "LOC_TECH_FILTER_HOUSING" },
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

local function FilterMatchesTech(techType)
    if not m_activeFilterFunc then return true end
    return m_activeFilterFunc(techType) == true
end

-- ===========================================================================
-- STATIC DATA
-- ===========================================================================

-- Prereq-based column for a tech, memoized into m_techColumnByType. A tech with
-- no in-era prerequisites sits in column 1; every other tech is placed one
-- column past its deepest in-era prereq. Cross-era prereqs do not push the
-- column (each era restarts at 1), matching vanilla's civics layout and the
-- tech tree's own "PREREQ" layout method (1 + in-era prereq chain depth).
local function ComputeTechColumn(techType)
    local cached = m_techColumnByType[techType]
    if cached then return cached end
    local kEntry = g_kItemDefaults[techType]
    if not kEntry then return 1 end
    local maxPrereqCol = 0
    for _, prereqType in ipairs(kEntry.Prereqs or {}) do
        if prereqType ~= PREREQ_ID_TREE_START then
            local kPrereq = g_kItemDefaults[prereqType]
            if kPrereq and kPrereq.EraType == kEntry.EraType then
                local c = ComputeTechColumn(prereqType)
                if c > maxPrereqCol then maxPrereqCol = c end
            end
        end
    end
    local col = maxPrereqCol + 1
    m_techColumnByType[techType] = col
    return col
end

local function BuildStaticMaps()
    m_leadsToByType   = {}
    m_techIndexToType = {}
    m_techTierByType  = {}
    m_techColumnByType = {}

    for techType, kEntry in pairs(g_kItemDefaults) do
        local row = GameInfo.Technologies[techType]
        if row then m_techIndexToType[row.Index] = techType end
        for _, prereqType in ipairs(kEntry.Prereqs or {}) do
            if prereqType ~= PREREQ_ID_TREE_START then
                m_leadsToByType[prereqType] = m_leadsToByType[prereqType] or {}
                table.insert(m_leadsToByType[prereqType], techType)
            end
        end
    end

    -- Compute each tech's prereq-based column (the basis for its tier).
    for techType in pairs(g_kItemDefaults) do ComputeTechColumn(techType) end

    -- Collect each era's distinct prereq columns so we can rank a tech's tier
    -- (1-based position of its column among the era's columns). Prereq columns
    -- are normally contiguous, but rank-compression keeps tiers gap-free.
    local eraColumnSet = {} ---@type table<string, table<integer, boolean>>
    for techType, kEntry in pairs(g_kItemDefaults) do
        if kEntry.EraType then
            eraColumnSet[kEntry.EraType] = eraColumnSet[kEntry.EraType] or {}
            eraColumnSet[kEntry.EraType][m_techColumnByType[techType] or 1] = true
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
    for techType, kEntry in pairs(g_kItemDefaults) do
        local rank = kEntry.EraType and tierByEraColumn[kEntry.EraType]
        m_techTierByType[techType] = rank and rank[m_techColumnByType[techType] or 1] or nil
    end
end

-- ===========================================================================
-- TECH ACTIONS
-- ===========================================================================

local function CanResearch(techType)
    local kLive = GetLiveData(techType)
    if not kLive or not kLive.IsRevealed then return false end
    return kLive.Status == ITEM_STATUS.READY
        or kLive.Status == ITEM_STATUS.BLOCKED
end

local function IsTechRevealed(techType)
    local kLive = GetLiveData(techType)
    return kLive ~= nil and kLive.IsRevealed == true
end

local function SpeakProgressSummary(techType)
    local kStatic = g_kItemDefaults[techType]
    local playerTechs = GetLocalPlayerTechs()
    if not kStatic or not playerTechs then return end
    local pathToTech = playerTechs:GetResearchPath(kStatic.Hash) or {}
    local count, totalCost = 0, 0
    for _, idx in ipairs(pathToTech) do
        count = count + 1
        local tt = m_techIndexToType[idx]
        local kLive = tt and GetLiveData(tt) or nil
        if kLive and kLive.Cost then
            totalCost = totalCost + kLive.Cost
        end
    end
    Speak(Locale.Lookup("LOC_CAI_TECH_QUEUE_ADDED", count, totalCost))
end

local function ActivateSetCurrent(techType)
    local node = GetUiNode(techType)
    local clicked = false
    if node and node.NodeButton and node.NodeButton.DoLeftClick and not ControlIsHidden(node.NodeButton) then
        node.NodeButton:DoLeftClick()
        clicked = true
    elseif node and node.OtherStates and node.OtherStates.DoLeftClick and not ControlIsHidden(node.OtherStates) then
        node.OtherStates:DoLeftClick()
        clicked = true
    end
    if not clicked then
        local kStatic = g_kItemDefaults[techType]
        local playerTechs, ePlayer = GetLocalPlayerTechs()
        if not kStatic or not playerTechs or ePlayer == -1 then return end
        local tParameters                               = {}
        tParameters[PlayerOperations.PARAM_TECH_TYPE]   = playerTechs:GetResearchPath(kStatic.Hash)
        tParameters[PlayerOperations.PARAM_INSERT_MODE] = PlayerOperations.VALUE_EXCLUSIVE
        UI.RequestPlayerOperation(ePlayer, PlayerOperations.RESEARCH, tParameters)
        UI.PlaySound("Confirm_Tech_TechTree")
    end
    SpeakProgressSummary(techType)
end

local function ActivateAppendToQueue(techType)
    local kStatic = g_kItemDefaults[techType]
    local playerTechs, ePlayer = GetLocalPlayerTechs()
    if not kStatic or not playerTechs or ePlayer == -1 then return end
    local tParameters                               = {}
    tParameters[PlayerOperations.PARAM_TECH_TYPE]   = playerTechs:GetResearchPath(kStatic.Hash)
    tParameters[PlayerOperations.PARAM_INSERT_MODE] = PlayerOperations.VALUE_APPEND
    UI.RequestPlayerOperation(ePlayer, PlayerOperations.RESEARCH, tParameters)
    UI.PlaySound("Confirm_Tech_TechTree")
    SpeakProgressSummary(techType)
end

-- ===========================================================================
-- JUMP-TO-NODE
-- ===========================================================================

local function GetFocusedTechType()
    local path = mgr and mgr.CurrentPath or nil
    if not path then return nil end
    for i = #path, 1, -1 do
        local w = path[i]
        local key = w and w.FocusKey or nil
        if key and string.sub(key, 1, 5) == "tech:" then
            return string.sub(key, 6)
        end
    end
    return nil
end

-- The focusable widget for a tech in the currently active view.
local function GetActiveTechWidget(techType)
    if m_viewMode == "table" then return m_tableTechs[techType] end
    return m_treeTechs[techType]
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

local function JumpToTech(techType, recordBreadcrumb)
    local target = GetActiveTechWidget(techType)
    if not target then return end

    if recordBreadcrumb then
        local source = GetFocusedTechType()
        if source and source ~= techType then
            table.insert(m_breadcrumbs, source)
        end
    end

    -- Tree mode: era/tier nodes are IgnoreWhenNotFocused, so focus speech won't
    -- mention them on a jump. Fold the diverging era/tier into the spoken line,
    -- announcing only what actually changed (compared by widget, so Tier 1 of a
    -- different era still counts as different). Table mode gets the era for free
    -- via the column header's natural focus speech, so it just says the tech.
    local parts = { GetTechName(techType) or "" }
    if m_viewMode == "tree" then
        local srcEra, srcTier = GetEnclosingEraTier(mgr:GetFocusedWidget())
        local tgtEra, tgtTier = GetEnclosingEraTier(target)
        if tgtTier and tgtTier ~= srcTier then AppendIfNonEmpty(parts, tgtTier:GetLabel()) end
        if tgtEra and tgtEra ~= srcEra then AppendIfNonEmpty(parts, tgtEra:GetLabel()) end
    end

    Speak(Locale.Lookup("LOC_CAI_TECH_TREE_JUMPING", table.concat(parts, ", ")), true)
    mgr:SetFocus(target)
end

-- ===========================================================================
-- REF LINKS + DETAIL CHILDREN
-- ===========================================================================

local function CreateRefLink(parentWidget, techType, currentEraType)
    local capturedType = techType
    local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAITechTreeRef"), "TreeItem", {
        Label             = function() return GetRelatedTechLabel(capturedType, currentEraType) end,
        HiddenPredicate   = function() return m_treeTechs[capturedType] == nil end,
        DisabledPredicate = function() return not IsTechRevealed(capturedType) end,
        FocusKey          = "ref:" .. tostring(capturedType),
    })
    item:On("activate", function(w)
        if w:IsDisabled() then return end
        JumpToTech(capturedType, true)
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

local function AddTechDetailChildren(techItem, techType)
    -- Unlocks (and the Path bucket) are hidden for unrevealed techs, but the
    -- prereq/leads-to buckets mirror the connector lines vanilla always draws,
    -- so they stay regardless of reveal status.
    local kStatic = g_kItemDefaults[techType]
    local currentEraType = kStatic and kStatic.EraType

    -- 1) Unlocks bucket (revealed only)
    if IsTechRevealed(techType) then
        local unlockChildren = {}
        for _, unlock in ipairs(GetTechUnlockObjects(TechKData(techType)).Unlocks) do
            if unlock.Description then
                table.insert(unlockChildren, unlock)
            end
        end
        if #unlockChildren > 0 then
            local node = mgr:CreateWidget(mgr:GenerateWidgetId("CAITechTreeUnlocks"), "TreeItem", {
                Label = function() return Locale.Lookup("LOC_CAI_TECH_TREE_UNLOCKS") end,
            })
            for _, unlock in ipairs(unlockChildren) do
                node:AddChild(CreateUnlockChild(mgr, unlock, "CAITechTreeUnlock"))
            end
            techItem:AddChild(node)
        end
    end

    -- 2) Prerequisites
    local prereqTypes = {}
    for _, pt in ipairs(kStatic and kStatic.Prereqs or {}) do
        if pt ~= PREREQ_ID_TREE_START then table.insert(prereqTypes, pt) end
    end
    if #prereqTypes > 0 then
        local node = mgr:CreateWidget(mgr:GenerateWidgetId("CAITechTreePrereqs"), "TreeItem", {
            Label = function() return Locale.Lookup("LOC_CAI_TECH_TREE_PREREQS") end,
        })
        for _, pt in ipairs(prereqTypes) do CreateRefLink(node, pt, currentEraType) end
        techItem:AddChild(node)
    end

    -- 3) Leads to
    local leadsTo = m_leadsToByType[techType]
    if leadsTo and #leadsTo > 0 then
        local node = mgr:CreateWidget(mgr:GenerateWidgetId("CAITechTreeLeadsTo"), "TreeItem", {
            Label = function() return Locale.Lookup("LOC_CAI_TECH_TREE_LEADS_TO") end,
        })
        for _, lt in ipairs(leadsTo) do CreateRefLink(node, lt, currentEraType) end
        techItem:AddChild(node)
    end

    -- 4) Full path (only when researchable and the path has > 1 step)
    if CanResearch(techType) and kStatic then
        local playerTechs = GetLocalPlayerTechs()
        local path = playerTechs and playerTechs:GetResearchPath(kStatic.Hash) or nil
        if path and #path > 1 then
            local node = mgr:CreateWidget(mgr:GenerateWidgetId("CAITechTreePath"), "TreeItem", {
                Label = function() return Locale.Lookup("LOC_CAI_TECH_TREE_PATH_IF_SELECTED") end,
            })
            for i = 1, #path - 1 do
                local tt = m_techIndexToType[path[i]]
                if tt then CreateRefLink(node, tt, currentEraType) end
            end
            techItem:AddChild(node)
        end
    end
end

-- ===========================================================================
-- TECH NODE FACTORY
-- ===========================================================================

local function BuildTechNode(techType)
    local capturedType = techType
    local techItem = mgr:CreateWidget(mgr:GenerateWidgetId("CAITechTreeTech"), "TreeItem", {
        Label             = function() return FormatRowLabel(capturedType) end,
        Tooltip           = function() return FormatRowTooltip(capturedType) end,
        DisabledPredicate = function()
            local node = GetUiNode(capturedType)
            if node and node.Top and node.Top:IsDisabled() then return true end
            return not CanResearch(capturedType)
        end,
        FocusKey          = "tech:" .. tostring(capturedType),
    })
    techItem:SetFocusSound("Main_Menu_Mouse_Over")

    techItem:On("activate", function(w)
        if w:IsDisabled() then return end
        ActivateSetCurrent(capturedType)
    end)

    techItem:AddInputBindings({
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
                if not IsTechRevealed(capturedType) then return true end
                if IsTutorialRunning and IsTutorialRunning() then return true end
                LuaEvents.OpenCivilopedia(capturedType)
                return true
            end,
        },
    })

    AddTechDetailChildren(techItem, capturedType)
    return techItem
end

-- ===========================================================================
-- MAIN TREE
-- ===========================================================================

local function RebuildMainTree()
    if not m_mainTree then return end

    local capture = mgr:CaptureFocusKey(m_mainTree)
    m_mainTree:ClearChildren()
    m_treeTechs = {}

    for _, era in ipairs(g_kEras) do
        -- Group this era's filtered techs by their prereq column; each distinct
        -- column is one prereq tier (a tier-N tech's in-era prereqs sit in tier
        -- N-1), so tier 1 holds the era's root techs, tier 2 their leads-to, etc.
        local byColumn, colValues = {}, {}
        for techType, kEntry in pairs(g_kItemDefaults) do
            if kEntry.EraType == era.EraType and FilterMatchesTech(techType) then
                local col = m_techColumnByType[techType] or 1
                if not byColumn[col] then byColumn[col] = {}; table.insert(colValues, col) end
                table.insert(byColumn[col], { techType = techType, row = kEntry.UITreeRow or 0 })
            end
        end
        if #colValues > 0 then
            table.sort(colValues)

            local capturedDescription = era.Description
            local eraItem = mgr:CreateWidget(mgr:GenerateWidgetId("CAITechTreeEra"), "TreeItem", {
                Label    = function() return Locale.Lookup(capturedDescription) end,
                FocusKey = "era:" .. tostring(era.EraType),
            })

            for tierIndex, colVal in ipairs(colValues) do
                local tierNumber = tierIndex
                local tierItem = mgr:CreateWidget(mgr:GenerateWidgetId("CAITechTreeTier"), "TreeItem", {
                    Label    = function() return Locale.Lookup("LOC_CAI_TREE_TIER", tierNumber) end,
                    FocusKey = "tier:" .. tostring(era.EraType) .. ":" .. tostring(colVal),
                })

                local tierTechs = byColumn[colVal]
                table.sort(tierTechs, function(a, b) return a.row < b.row end)
                for _, entry in ipairs(tierTechs) do
                    local widget = BuildTechNode(entry.techType)
                    m_treeTechs[entry.techType] = widget
                    tierItem:AddChild(widget)
                end

                -- Auto-expanded: expanding the era reveals each tier's techs
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
-- tech Buttons stacked by UITreeRow). A sibling unlocks list mirrors the
-- focused tech's described unlocks.
-- ===========================================================================

-- Rebuild the unlocks list to mirror the focused tech. Focus stays on the
-- table cell; the list is a passive sibling, so no capture/restore is needed.
local function RebuildUnlocksList(techType)
    if not m_unlocksList then return end
    m_unlocksList:ClearChildren()
    if not techType then return end
    if not IsTechRevealed(techType) then return end
    for _, unlock in ipairs(GetTechUnlockObjects(TechKData(techType)).Unlocks) do
        if unlock.Description then
            m_unlocksList:AddChild(CreateUnlockChild(mgr, unlock, "CAITechTableUnlock"))
        end
    end
end

local function BuildTechCell(techType)
    local capturedType = techType
    local cell = mgr:CreateWidget(mgr:GenerateWidgetId("CAITechTableTech"), "Button", {
        Label             = function() return FormatRowLabel(capturedType) end,
        Tooltip           = function() return FormatRowTooltip(capturedType) end,
        DisabledPredicate = function()
            local node = GetUiNode(capturedType)
            if node and node.Top and node.Top:IsDisabled() then return true end
            return not CanResearch(capturedType)
        end,
        FocusKey          = "tech:" .. tostring(capturedType),
    })
    cell:SetFocusSound("Main_Menu_Mouse_Over")

    cell:On("activate", function(w)
        if w:IsDisabled() then return end
        ActivateSetCurrent(capturedType)
    end)

    -- Keep the unlocks list in step with the focused tech.
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
                if not IsTechRevealed(capturedType) then return true end
                if IsTutorialRunning and IsTutorialRunning() then return true end
                LuaEvents.OpenCivilopedia(capturedType)
                return true
            end,
        },
    })
    return cell
end

local function RebuildTableView()
    if not m_tableView then return end

    local capture = mgr:CaptureFocusKey(m_tableView)
    m_tableView:ClearChildren()
    m_tableTechs = {}

    for _, era in ipairs(g_kEras) do
        -- Group this era's filtered techs by their prereq column; each distinct
        -- column becomes one side-by-side tier, ordered left to right.
        local byColumn, colValues = {}, {}
        for techType, kEntry in pairs(g_kItemDefaults) do
            if kEntry.EraType == era.EraType and FilterMatchesTech(techType) then
                local col = m_techColumnByType[techType] or 1
                if not byColumn[col] then byColumn[col] = {}; table.insert(colValues, col) end
                table.insert(byColumn[col], { techType = techType, row = kEntry.UITreeRow or 0 })
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
                local tierTechs = byColumn[colVal]
                table.sort(tierTechs, function(a, b) return a.row < b.row end)
                for _, entry in ipairs(tierTechs) do
                    local cell = BuildTechCell(entry.techType)
                    m_tableTechs[entry.techType] = cell
                    m_tableView:AddItem(column, tierIndex, cell)
                end
            end
        end
    end

    mgr:RestoreFocus(m_tableView, capture)
end

-- Rebuild whichever tech views exist, keeping both in sync with game/filter
-- state so jumps land correctly regardless of the active mode.
local function RebuildTechViews()
    RebuildMainTree()
    RebuildTableView()
end

local function ToggleViewMode()
    m_viewMode = (m_viewMode == "tree") and "table" or "tree"
    local active = (m_viewMode == "table") and m_tableView or m_mainTree
    if active then mgr:SetFocus(active) end
end

-- ===========================================================================
-- QUEUE LIST
-- ===========================================================================

local function CreateQueueButton(techType, isCurrent)
    local capturedType = techType
    local btn = mgr:CreateWidget(mgr:GenerateWidgetId("CAITechTreeQueueRow"), "Button", {
        Label    = function()
            if isCurrent then
                return Locale.Lookup("LOC_CAI_RESEARCH_CURRENT", FormatRowLabel(capturedType))
            end
            return FormatRowLabel(capturedType)
        end,
        Tooltip  = function() return FormatRowTooltip(capturedType) end,
        FocusKey = (isCurrent and "queue:current:" or "queue:") .. tostring(capturedType),
    })
    btn:SetFocusSound("Main_Menu_Mouse_Over")
    btn:On("activate", function() JumpToTech(capturedType) end)
    btn:AddInputBindings({
        {
            Key     = Keys.VK_RETURN,
            IsShift = true,
            MSG     = KeyEvents.KeyUp,
            Action  = function()
                if not IsTechRevealed(capturedType) then return true end
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

    local playerTechs = GetLocalPlayerTechs()
    if playerTechs then
        local currentIdx = playerTechs:GetResearchingTech()
        if currentIdx and currentIdx ~= -1 then
            local tt = m_techIndexToType[currentIdx]
            if tt then m_queueList:AddChild(CreateQueueButton(tt, true)) end
        end
        local queue = playerTechs:GetResearchQueue()
        if queue then
            for _, techID in ipairs(queue) do
                local tt = m_techIndexToType[techID]
                if tt and tt ~= m_techIndexToType[currentIdx or -1] then
                    m_queueList:AddChild(CreateQueueButton(tt, false))
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
    if OnFilterClicked then
        OnFilterClicked({ Func = nil, Description = "LOC_TECH_FILTER_NONE" })
    end
    RebuildTechViews()
end

local function CreateFilterResultButton(techType)
    local capturedType = techType
    local btn = mgr:CreateWidget(mgr:GenerateWidgetId("CAITechTreeFilterResult"), "Button", {
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
        mgr:RemoveFromStack(FILTER_RESULTS_ID)
        JumpToTech(capturedType)
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
                if not IsTechRevealed(capturedType) then return true end
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
    RebuildTechViews()

    m_filterResults = mgr:CreateWidget(FILTER_RESULTS_ID, "List", {
        Label = function()
            return Locale.Lookup("LOC_CAI_TECH_TREE_FILTER_RESULTS", entry.Label)
        end,
    })

    for _, era in ipairs(g_kEras) do
        local eraTechs = {}
        for techType, kEntry in pairs(g_kItemDefaults) do
            if kEntry.EraType == era.EraType and FilterMatchesTech(techType) then
                table.insert(eraTechs, { techType = techType, col = m_techColumnByType[techType] or 1, row = kEntry.UITreeRow or 0 })
            end
        end
        table.sort(eraTechs, function(a, b)
            if a.col ~= b.col then return a.col < b.col end
            return a.row < b.row
        end)
        for _, e in ipairs(eraTechs) do
            m_filterResults:AddChild(CreateFilterResultButton(e.techType))
        end
    end

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
        local btn = mgr:CreateWidget(mgr:GenerateWidgetId("CAITechTreeFilterBtn"), "Button", {
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
-- PANEL LIFECYCLE
-- ===========================================================================

local function EnsurePanelBuilt()
    if m_panel or not mgr then return end

    BuildStaticMaps()
    EnsureFilterEntries()

    m_panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function() return ControlText(Controls.ModalScreenTitle) end,
    })

    m_queueList = mgr:CreateWidget(QUEUE_LIST_ID, "List", {
        Label           = function() return Locale.Lookup("LOC_CAI_TECH_TREE_QUEUE_LIST") end,
        HiddenPredicate = function(w) return not w.Children or #w.Children == 0 end,
        SearchDepth     = 0,
    })
    m_panel:AddChild(m_queueList)

    m_filterList = mgr:CreateWidget(FILTER_LIST_ID, "List", {
        Label       = function() return Locale.Lookup("LOC_CAI_TECH_TREE_FILTER") end,
        SearchDepth = 0,
    })
    m_panel:AddChild(m_filterList)
    BuildFilterList()

    -- Main tree (hidden in table mode)
    m_mainTree = mgr:CreateWidget(MAIN_TREE_ID, "Tree", {
        Label           = function() return Locale.Lookup("LOC_CAI_TECH_TREE_MAIN_LIST") end,
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
                JumpToTech(source, false)
                return true
            end,
        },
    })
    m_panel:AddChild(m_mainTree)

    -- Table view (hidden in tree mode): eras = columns, tiers = Column-groups
    m_tableView = mgr:CreateWidget(TABLE_VIEW_ID, "Table", {
        Label           = function() return Locale.Lookup("LOC_CAI_TECH_TREE_TABLE") end,
        HiddenPredicate = function() return m_viewMode ~= "table" end,
    })
    m_panel:AddChild(m_tableView)

    -- Unlocks list beside the table; mirrors the focused tech (table mode only,
    -- and only when the focused tech has described unlocks)
    m_unlocksList = mgr:CreateWidget(UNLOCKS_LIST_ID, "List", {
        Label           = function() return Locale.Lookup("LOC_CAI_TECH_TREE_UNLOCKS") end,
        HiddenPredicate = function(w)
            return m_viewMode ~= "table" or not w.Children or #w.Children == 0
        end,
        SearchDepth     = 0,
    })
    m_panel:AddChild(m_unlocksList)

    -- View toggle — must remain the last child. Label reflects the mode it
    -- switches *to*.
    m_changeViewBtn = mgr:CreateWidget(CHANGE_VIEW_ID, "Button", {
        Label = function()
            return Locale.Lookup(m_viewMode == "table"
                and "LOC_CAI_TREE_SWITCH_TO_TREE"
                or  "LOC_CAI_TREE_SWITCH_TO_TABLE")
        end,
    })
    m_changeViewBtn:On("activate", function() ToggleViewMode() end)
    m_panel:AddChild(m_changeViewBtn)

    RebuildTechViews()
    RebuildQueueList()
end

local function PushPanel()
    if not mgr then return end
    EnsurePanelBuilt()
    if not m_panel or mgr:GetWidgetById(PANEL_ID) then return end

    local playerTechs = GetLocalPlayerTechs()
    local hasCurrent = playerTechs and playerTechs:GetResearchingTech() ~= -1
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
    m_changeViewBtn     = nil
    m_filterResults     = nil
    m_viewMode          = "table"
    m_treeTechs         = {}
    m_tableTechs        = {}
    m_leadsToByType     = {}
    m_techIndexToType   = {}
    m_techTierByType    = {}
    m_techColumnByType  = {}
    m_lastPlayerData    = nil
    m_filterEntries     = nil
    m_activeFilterEntry = nil
    m_activeFilterFunc  = nil
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
    end
end)

local _origOnOpen = OnOpen
OnOpen = WrapFunc(OnOpen, function(orig)
    orig()
    PushPanel()
end)
LuaEvents.LaunchBar_RaiseTechTree.Remove(_origOnOpen)
LuaEvents.ResearchChooser_RaiseTechTree.Remove(_origOnOpen)
LuaEvents.LaunchBar_RaiseTechTree.Add(OnOpen)
LuaEvents.ResearchChooser_RaiseTechTree.Add(OnOpen)

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

local function RefocusIfTechRow()
    if not IsPanelOnStack() then return end
    local focused = mgr:GetFocusedWidget()
    if not focused or not focused.FocusKey then return end
    local key = focused.FocusKey
    if string.sub(key, 1, 5) == "tech:"
        or string.sub(key, 1, 6) == "queue:" then
        mgr:Refocus()
    end
end

Events.ResearchChanged.Add(function(ePlayer)
    if ePlayer == Game.GetLocalPlayer() and IsPanelOnStack() then
        RebuildQueueList()
        RefocusIfTechRow()
    end
end)

Events.ResearchQueueChanged.Add(function(ePlayer)
    if ePlayer == Game.GetLocalPlayer() and IsPanelOnStack() then
        RebuildQueueList()
        RefocusIfTechRow()
    end
end)

Events.ResearchCompleted.Add(function(ePlayer)
    if ePlayer ~= Game.GetLocalPlayer() or not IsPanelOnStack() then return end
    RebuildTechViews()
    RebuildQueueList()
end)

Events.LocalPlayerTurnBegin.Add(function(ePlayer)
    if ePlayer == Game.GetLocalPlayer() and IsPanelOnStack() then
        RebuildQueueList()
    end
end)

Events.LocalPlayerChanged.Add(function() OnPanelClosedCAI() end)
