include("caiUtils")
include("TechTree")
include("inGameHelpers_CAI")
include("ToolTipHelper")
include("Civ6Common")

local mgr                 = ExposedMembers.CAI_UIManager

local PANEL_ID            = "CAITechTree_Panel"
local QUEUE_LIST_ID       = "CAITechTree_QueueList"
local FILTER_LIST_ID      = "CAITechTree_FilterList"
local MAIN_TREE_ID        = "CAITechTree_MainTree"
local FILTER_RESULTS_ID   = "CAITechTree_FilterResults"

-- ===========================================================================
-- MODULE STATE
-- ===========================================================================
local m_panel             = nil ---@type UIWidget|nil
local m_queueList         = nil ---@type UIWidget|nil
local m_filterList        = nil ---@type UIWidget|nil
local m_mainTree          = nil ---@type UIWidget|nil
local m_filterResults     = nil ---@type UIWidget|nil

local m_techsByType       = {} ---@type table<string, UIWidget>
local m_leadsToByType     = {} ---@type table<string, string[]>
local m_techIndexToType   = {} ---@type table<integer, string>

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

local function TechKData(techType)
    return { TechType = techType, Type = techType }
end

-- ===========================================================================
-- LABEL / TOOLTIP
-- ===========================================================================

local function FormatRowLabel(techType)
    local parts = {}
    AppendIfNonEmpty(parts, GetTechName(techType))
    local kLive = GetLiveData(techType)
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
    local kData = TechKData(techType)
    local group = GetTechUnlockObjects(kData)

    local parts = {}
    AppendIfNonEmpty(parts, GetTechCostText(techType))
    AppendIfNonEmpty(parts, GetTechTurnsText(techType))
    AppendIfNonEmpty(parts, GetTechProgressText(techType))
    AppendIfNonEmpty(parts, GetTechDescriptionText(techType))
    AppendIfNonEmpty(parts, GetTechBoostText(techType))
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

local function BuildStaticMaps()
    m_leadsToByType   = {}
    m_techIndexToType = {}
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

local function JumpToTech(techType, recordBreadcrumb)
    local target = m_techsByType[techType]
    if not target then return end

    if recordBreadcrumb then
        local source = GetFocusedTechType()
        if source and source ~= techType then
            table.insert(m_breadcrumbs, source)
        end
    end

    Speak(Locale.Lookup("LOC_CAI_TECH_TREE_JUMPING", GetTechName(techType) or ""), true)
    mgr:SetFocus(target)
end

-- ===========================================================================
-- REF LINKS + DETAIL CHILDREN
-- ===========================================================================

local function CreateRefLink(parentWidget, techType)
    local capturedType = techType
    local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAITechTreeRef"), "TreeItem", {
        Label             = function() return GetTechName(capturedType) end,
        HiddenPredicate   = function() return m_techsByType[capturedType] == nil end,
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
    local kData = TechKData(techType)
    local group = GetTechUnlockObjects(kData)

    -- 1) Unlocks bucket
    local unlockChildren = {}
    for _, unlock in ipairs(group.Unlocks) do
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

    -- 2) Prerequisites
    local kStatic = g_kItemDefaults[techType]
    local prereqTypes = {}
    for _, pt in ipairs(kStatic and kStatic.Prereqs or {}) do
        if pt ~= PREREQ_ID_TREE_START then table.insert(prereqTypes, pt) end
    end
    if #prereqTypes > 0 then
        local node = mgr:CreateWidget(mgr:GenerateWidgetId("CAITechTreePrereqs"), "TreeItem", {
            Label = function() return Locale.Lookup("LOC_CAI_TECH_TREE_PREREQS") end,
        })
        for _, pt in ipairs(prereqTypes) do CreateRefLink(node, pt) end
        techItem:AddChild(node)
    end

    -- 3) Leads to
    local leadsTo = m_leadsToByType[techType]
    if leadsTo and #leadsTo > 0 then
        local node = mgr:CreateWidget(mgr:GenerateWidgetId("CAITechTreeLeadsTo"), "TreeItem", {
            Label = function() return Locale.Lookup("LOC_CAI_TECH_TREE_LEADS_TO") end,
        })
        for _, lt in ipairs(leadsTo) do CreateRefLink(node, lt) end
        techItem:AddChild(node)
    end

    -- 4) Full path
    if CanResearch(techType) and kStatic then
        local playerTechs = GetLocalPlayerTechs()
        local path = playerTechs and playerTechs:GetResearchPath(kStatic.Hash) or nil
        if path and #path > 1 then
            local node = mgr:CreateWidget(mgr:GenerateWidgetId("CAITechTreePath"), "TreeItem", {
                Label = function() return Locale.Lookup("LOC_CAI_TECH_TREE_PATH_IF_SELECTED") end,
            })
            for i = 1, #path - 1 do
                local tt = m_techIndexToType[path[i]]
                if tt then CreateRefLink(node, tt) end
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
    m_techsByType = {}

    for _, era in ipairs(g_kEras) do
        local eraTechs = {}
        for techType, kEntry in pairs(g_kItemDefaults) do
            if kEntry.EraType == era.EraType and FilterMatchesTech(techType) then
                table.insert(eraTechs, { techType = techType, row = kEntry.UITreeRow or 0 })
            end
        end
        if #eraTechs > 0 then
            table.sort(eraTechs, function(a, b) return a.row < b.row end)

            local capturedDescription = era.Description
            local eraItem = mgr:CreateWidget(mgr:GenerateWidgetId("CAITechTreeEra"), "TreeItem", {
                Label    = function() return Locale.Lookup(capturedDescription) end,
                FocusKey = "era:" .. tostring(era.EraType),
            })

            for _, entry in ipairs(eraTechs) do
                local widget = BuildTechNode(entry.techType)
                m_techsByType[entry.techType] = widget
                eraItem:AddChild(widget)
            end
            m_mainTree:AddChild(eraItem)
        end
    end

    mgr:RestoreFocus(m_mainTree, capture)
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
    RebuildMainTree()
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
            return Locale.Lookup("LOC_CAI_TECH_TREE_FILTER_RESULTS", entry.Label)
        end,
    })

    for _, era in ipairs(g_kEras) do
        local eraTechs = {}
        for techType, kEntry in pairs(g_kItemDefaults) do
            if kEntry.EraType == era.EraType and FilterMatchesTech(techType) then
                table.insert(eraTechs, { techType = techType, row = kEntry.UITreeRow or 0 })
            end
        end
        table.sort(eraTechs, function(a, b) return a.row < b.row end)
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

    m_mainTree = mgr:CreateWidget(MAIN_TREE_ID, "Tree", {
        Label       = function() return Locale.Lookup("LOC_CAI_TECH_TREE_MAIN_LIST") end,
        SearchDepth = 2,
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

    RebuildMainTree()
    RebuildQueueList()
end

local function PushPanel()
    if not mgr then return end
    EnsurePanelBuilt()
    if not m_panel or mgr:GetWidgetById(PANEL_ID) then return end

    local playerTechs = GetLocalPlayerTechs()
    local hasCurrent = playerTechs and playerTechs:GetResearchingTech() ~= -1
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
    m_filterResults     = nil
    m_techsByType       = {}
    m_leadsToByType     = {}
    m_techIndexToType   = {}
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
    RebuildMainTree()
    RebuildQueueList()
end)

Events.LocalPlayerTurnBegin.Add(function(ePlayer)
    if ePlayer == Game.GetLocalPlayer() and IsPanelOnStack() then
        RebuildQueueList()
    end
end)

Events.LocalPlayerChanged.Add(function() OnPanelClosedCAI() end)
