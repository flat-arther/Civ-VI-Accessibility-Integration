include("caiUtils")
include("TechTree")
include("inGameHelpers_CAI")

local mgr                 = ExposedMembers.CAI_UIManager

local UNLOCKS_INLINE      = 2

-- ===========================================================================
-- MODULE STATE
-- ===========================================================================
local m_caiPanel          = nil ---@type UIWidget|nil
local m_caiFilterList ---@type UIWidget|nil
local m_caiQueueTree      = nil ---@type UIWidget|nil
local m_caiMainTree       = nil ---@type UIWidget|nil
local m_caiFilterDropdown = nil ---@type UIWidget|nil

local m_caiTechsByType    = {} ---@type table<string, UIWidget>
local m_leadsToByType     = {} ---@type table<string, table>
local m_techIndexToType   = {} ---@type table<integer, string>

local m_caiFilterEntries  = nil ---@type table|nil
local m_activeFilterEntry = nil ---@type table|nil
local m_activeFilterFunc  = nil ---@type function|nil
local m_lastPlayerData    = nil ---@type table|nil

-- Stack of source tech widget IDs the user navigated away from via reference
-- links. Backspace inside the main tree pops the last one and re-focuses it.
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

local function ControlTooltip(ctrl)
    if ctrl and ctrl.GetToolTipString then
        local t = ctrl:GetToolTipString()
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
-- ROW LABEL / TOOLTIP (live controls)
-- ===========================================================================

local function GetTechName(techType)
    local node = GetUiNode(techType)
    return ControlText(node and node.NodeName)
end

local function GetTechTooltipText(techType)
    local node = GetUiNode(techType)
    return ControlTooltip(node and node.NodeButton)
end

local function GetTechTurnsText(techType)
    local node = GetUiNode(techType)
    if not node or ControlIsHidden(node.Turns) then return nil end
    local t = ControlText(node.Turns)
    if t == "" then return nil end
    return t
end

local function GetTechBoostFirstLine(techType)
    local kStatic = g_kItemDefaults[techType]
    if not kStatic or not kStatic.IsBoostable then return nil end
    local kLive = GetLiveData(techType)
    local prefix
    if kLive and kLive.IsBoosted then
        prefix = Locale.Lookup("LOC_TECH_HAS_BEEN_BOOSTED")
    else
        prefix = Locale.Lookup("LOC_TECH_CAN_BE_BOOSTED")
    end
    local boostText = kStatic.BoostText or ""
    if boostText == "" then return prefix end
    return prefix .. ": " .. boostText
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
    -- READY is the default available state; no announcement needed.
    return nil
end

local function FormatRowLabel(techType)
    local parts = {}
    AppendIfNonEmpty(parts, GetTechName(techType))
    local kLive = GetLiveData(techType)
    AppendIfNonEmpty(parts, GetTechStatusLabel(kLive))
    if kLive and kLive.IsRecommended then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_TECH_FILTER_RECOMMENDED"))
    end
    return table.concat(parts, ", ")
end

local function GetFirstNNames(names, n)
    local head = {}
    for i, name in ipairs(names or {}) do
        if i <= n then table.insert(head, name) else break end
    end
    return head
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

local function FormatRowTooltip(techType)
    local parts = {}

    AppendIfNonEmpty(parts, GetTechTurnsText(techType))

    local tooltipLines = SplitTooltipLinesWithoutUnlocks(GetTechTooltipText(techType))
    AppendIfNonEmpty(parts, tooltipLines[2])

    AppendIfNonEmpty(parts, GetTechBoostFirstLine(techType))

    local kData = { TechType = techType, Type = techType }
    local unlockNames = GetTechUnlockNames(kData)

    for _, name in ipairs(GetFirstNNames(unlockNames, UNLOCKS_INLINE)) do
        AppendIfNonEmpty(parts, name)
    end

    local queuePosition = GetTechQueuePosition(techType)
    if queuePosition then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_RESEARCH_QUEUE_POSITION", queuePosition))
    end

    return table.concat(parts, "[NEWLINE]")
end

-- ===========================================================================
-- FILTER
-- ===========================================================================

local function EnsureFilterEntries()
    if m_caiFilterEntries then return end
    m_caiFilterEntries = {
        {
            Label        = Locale.Lookup("LOC_TECH_FILTER_NONE"),
            Func         = nil,
            VanillaEntry = { Func = nil, Description = "LOC_TECH_FILTER_NONE" },
        },
    }
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
            table.insert(m_caiFilterEntries, {
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
-- STATIC DATA (leads-to and Index<->Type lookups)
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
-- TECH ACTIONS (set current vs. append to queue)
-- ===========================================================================

local function RequestProgressTech(techType, append)
    local kStatic = g_kItemDefaults[techType]
    local playerTechs, ePlayer = GetLocalPlayerTechs()
    if not kStatic or not playerTechs or ePlayer == -1 then return end

    local pathToTech                                = playerTechs:GetResearchPath(kStatic.Hash)
    local tParameters                               = {}
    tParameters[PlayerOperations.PARAM_TECH_TYPE]   = pathToTech
    tParameters[PlayerOperations.PARAM_INSERT_MODE] = append
        and PlayerOperations.VALUE_APPEND
        or PlayerOperations.VALUE_EXCLUSIVE
    UI.RequestPlayerOperation(ePlayer, PlayerOperations.RESEARCH, tParameters)
    UI.PlaySound("Confirm_Tech_TechTree")

    -- BLOCKED techs queue the whole prereq chain; READY techs queue just one.
    -- The announcement is the same for set-current and append: count and total
    -- science cost summed from live data for each step in the path.
    local count, totalCost = 0, 0
    for _, idx in ipairs(pathToTech or {}) do
        count = count + 1
        local tt = m_techIndexToType[idx]
        local kLive = tt and GetLiveData(tt) or nil
        if kLive and kLive.Cost then
            totalCost = totalCost + kLive.Cost
        end
    end
    Speak(Locale.Lookup("LOC_CAI_TECH_QUEUE_ADDED", count, totalCost))
end

-- Vanilla wires the click callback to both NodeButton and OtherStates, so
-- clicking is functional for any revealed tech. BLOCKED is intentionally
-- clickable: GetResearchPath returns the prereq chain, queueing the whole path.
-- RESEARCHED / CURRENT have no useful path (already done / in progress) and
-- UNREVEALED isn't a valid target.
local function CanResearch(techType)
    local kLive = GetLiveData(techType)
    if not kLive or not kLive.IsRevealed then return false end
    return kLive.Status == ITEM_STATUS.READY
        or kLive.Status == ITEM_STATUS.BLOCKED
end

-- ===========================================================================
-- REFERENCE LINKS (jump to tech node) and DETAIL CHILDREN
-- ===========================================================================

local function IsTechRevealed(techType)
    local kLive = GetLiveData(techType)
    return kLive ~= nil and kLive.IsRevealed == true
end

local function CreateRefLink(parentWidget, techType, sourceTechId)
    local capturedType = techType
    local capturedSourceId = sourceTechId
    local item = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAITechTreeRef"), "TreeviewItem", {
        GetLabel   = function() return GetTechName(capturedType) end,
        IsHidden   = function() return m_caiTechsByType[capturedType] == nil end,
        IsDisabled = function() return not IsTechRevealed(capturedType) end,
        OnClick    = function(w)
            if w.IsDisabled and w:IsDisabled() then return end
            local target = m_caiTechsByType[capturedType]
            if target then
                if capturedSourceId then
                    table.insert(m_breadcrumbs, capturedSourceId)
                end
                mgr:SetFocus(target)
            end
        end,
    })
    item:AddInputBinding({
        Key = Keys.VK_RETURN,
        IsShift = true,
        Action = function(w)
            if w.IsDisabled and w:IsDisabled() then return true end
            if IsTutorialRunning and IsTutorialRunning() then return true end
            LuaEvents.OpenCivilopedia(capturedType)
            return true
        end,
    })
    parentWidget:AddChild(item)
    return item
end

local function AddTechDetailChildren(techItem, techType, sourceTechId)
    local kStatic = g_kItemDefaults[techType]
    if not kStatic then return end

    -- Description body lines from the live tooltip; the unlocks bullet list
    -- is dropped here and rebuilt as a collapsed node below.
    for _, line in ipairs(SplitTooltipLinesWithoutUnlocks(GetTechTooltipText(techType))) do
        AddTextDetailNode(mgr, techItem, line)
    end

    AddTextDetailNode(mgr, techItem, GetTechBoostFirstLine(techType))

    local kData = { TechType = techType, Type = techType }
    AddTechUnlocksNode(mgr, techItem, GetTechUnlockNames(kData))

    local prereqTypes = {}
    for _, pt in ipairs(kStatic.Prereqs or {}) do
        if pt ~= PREREQ_ID_TREE_START then table.insert(prereqTypes, pt) end
    end
    if #prereqTypes > 0 then
        local node = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAITechTreePrereqs"), "TreeviewItem", {
            GetLabel = function() return Locale.Lookup("LOC_CAI_TECH_TREE_PREREQS") end,
        })
        for _, pt in ipairs(prereqTypes) do CreateRefLink(node, pt, sourceTechId) end
        techItem:AddChild(node)
    end

    local leadsTo = m_leadsToByType[techType]
    if leadsTo and #leadsTo > 0 then
        local node = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAITechTreeLeadsTo"), "TreeviewItem", {
            GetLabel = function() return Locale.Lookup("LOC_CAI_TECH_TREE_LEADS_TO") end,
        })
        for _, lt in ipairs(leadsTo) do CreateRefLink(node, lt, sourceTechId) end
        techItem:AddChild(node)
    end

    if CanResearch(techType) then
        local playerTechs = GetLocalPlayerTechs()
        local path = playerTechs and playerTechs:GetResearchPath(kStatic.Hash) or nil
        if path and #path > 1 then
            local node = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAITechTreePath"), "TreeviewItem", {
                GetLabel = function() return Locale.Lookup("LOC_CAI_TECH_TREE_PATH_IF_SELECTED") end,
            })
            for i = 1, #path - 1 do
                local tt = m_techIndexToType[path[i]]
                if tt then CreateRefLink(node, tt, sourceTechId) end
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
    local techId = mgr:GenerateWidgetId("CAITechTreeTech")
    local techItem = mgr:CreateUIWidget(techId, "TreeviewItem", {
        GetLabel     = function() return FormatRowLabel(capturedType) end,
        GetTooltip   = function() return FormatRowTooltip(capturedType) end,
        IsDisabled   = function()
            local node = GetUiNode(capturedType)
            if node and node.Top:IsDisabled() then return true end
            return not CanResearch(capturedType)
        end,
        OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
        OnClick      = function()
            if not CanResearch(capturedType) then return end
            RequestProgressTech(capturedType, false)
        end,
    })

    techItem:AddInputBinding({
        Key = Keys.VK_RETURN,
        IsControl = true,
        Action = function()
            if not CanResearch(capturedType) then return true end
            RequestProgressTech(capturedType, true)
            return true
        end,
    })
    techItem:AddInputBinding({
        Key = Keys.VK_RETURN,
        IsShift = true,
        Action = function()
            if IsTutorialRunning and IsTutorialRunning() then return true end
            LuaEvents.OpenCivilopedia(capturedType)
            return true
        end,
    })

    AddTechDetailChildren(techItem, techType, techId)
    return techItem
end

-- ===========================================================================
-- MAIN TREE REBUILD (era-grouped, filter is a structural exclusion)
-- ===========================================================================

local function CaptureFocusedTechType()
    if not mgr.GetFocusedWidget then return nil end
    local focused = mgr:GetFocusedWidget()
    if not focused then return nil end
    for tt, widget in pairs(m_caiTechsByType) do
        if widget == focused then return tt end
    end
    return nil
end

local function RebuildMainTree()
    if not m_caiMainTree then return end

    local focusedType = CaptureFocusedTechType()
    m_caiMainTree:ClearChildren()
    m_caiTechsByType = {}
    -- Old tech widget ids are gone; previously-recorded breadcrumbs would
    -- never resolve through GetChildById, so drop them.
    m_breadcrumbs = {}

    -- Vanilla PopulateEraData inserts each era twice into g_kEras: once into
    -- the array part (sorted by ChronologyIndex) and once keyed by EraType.
    -- ipairs walks only the array half so each era surfaces exactly once.
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
            local eraItem = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAITechTreeEra"), "TreeviewItem", {
                GetLabel = function() return capturedDescription end,
            })

            for _, entry in ipairs(eraTechs) do
                local widget = BuildTechNode(entry.techType)
                if widget then
                    m_caiTechsByType[entry.techType] = widget
                    eraItem:AddChild(widget)
                end
            end
            m_caiMainTree:AddChild(eraItem)
        end
    end

    if focusedType and m_caiTechsByType[focusedType] and m_caiPanel and mgr:HasWidget(m_caiPanel) then
        mgr:SetFocus(m_caiTechsByType[focusedType])
    end
end

-- ===========================================================================
-- QUEUE TREE REBUILD (current tech + queued techs)
-- ===========================================================================

local function CreateQueueRow(techType, prefix)
    local capturedType = techType
    local row = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAITechTreeQueueRow"), "TreeviewItem", {
        GetLabel = function()
            local label = FormatRowLabel(capturedType)
            if prefix then return prefix .. ": " .. label end
            return label
        end,
        GetTooltip = function() return FormatRowTooltip(capturedType) end,
        OnClick = function()
            local target = m_caiTechsByType[capturedType]
            if target then mgr:SetFocus(target) end
        end,
    })
    row:AddInputBinding({
        Key = Keys.VK_RETURN,
        IsShift = true,
        Action = function()
            if IsTutorialRunning and IsTutorialRunning() then return true end
            LuaEvents.OpenCivilopedia(capturedType)
            return true
        end,
    })
    return row
end

local function RebuildQueueTree()
    if not m_caiQueueTree then return end

    local focusPath = mgr:CaptureFocusIndexPath(m_caiQueueTree)
    m_caiQueueTree:ClearChildren()

    local playerTechs = GetLocalPlayerTechs()
    if playerTechs then
        local queue = playerTechs:GetResearchQueue()
        if queue then
            for _, techID in ipairs(queue) do
                local techType = m_techIndexToType[techID]
                if techType then
                    m_caiQueueTree:AddChild(CreateQueueRow(techType, nil))
                end
            end
        end
    end

    if focusPath and m_caiPanel and mgr:HasWidget(m_caiPanel) then
        mgr:SetFocusIndexPath(m_caiQueueTree, focusPath)
    end
end

-- ===========================================================================
-- FILTER DROPDOWN (single DropdownMenu; OnClick pushes a List of MenuItems)
-- ===========================================================================

local function OnFilterChosen(entry)
    m_activeFilterEntry = entry
    m_activeFilterFunc  = entry.Func
    if OnFilterClicked then OnFilterClicked(entry.VanillaEntry) end
    RebuildMainTree()
    if m_caiMainTree and m_caiPanel and mgr:HasWidget(m_caiPanel) then
        mgr:SetFocus(m_caiMainTree)
    end
end

local function OpenFilterList()
    EnsureFilterEntries()
    if not m_caiFilterEntries then return end

    m_caiFilterList = mgr:CreateUIWidget("CAITechTreeFilterList", "List", {
        GetLabel = function() return Locale.Lookup("LOC_CAI_TECH_TREE_FILTER") end,
    })
    m_caiFilterList:AddInputBinding({
        Key = Keys.VK_ESCAPE,
        Action = function()
            mgr:Pop(); return true
        end,
    })

    for _, entry in ipairs(m_caiFilterEntries) do
        local capturedEntry = entry
        m_caiFilterList:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAITechTreeFilterItem"), "MenuItem", {
            GetLabel = function() return capturedEntry.Label end,
            GetState = function()
                return m_activeFilterEntry == capturedEntry
                    and Locale.Lookup("LOC_CAI_STATE_SELECTED") or nil
            end,
            OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
            OnClick = function()
                OnFilterChosen(capturedEntry)
                mgr:Pop()
            end,
        }))
    end

    mgr:Push(m_caiFilterList)
end

-- ===========================================================================
-- PANEL LIFECYCLE
-- ===========================================================================

local function EnsurePanelBuilt()
    if m_caiPanel or not mgr then return end

    BuildStaticMaps()
    EnsureFilterEntries()

    m_caiPanel = mgr:CreateUIWidget("CAITechTreePanel", "Panel", {
        GetLabel = function() return ControlText(Controls.ModalScreenTitle) end,
    })

    m_caiQueueTree = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAITechTreeQueue"), "Treeview", {
        GetLabel    = function() return Locale.Lookup("LOC_CAI_TECH_TREE_QUEUE_LIST") end,
        IsHidden    = function(w) return not w.Children or #w.Children == 0 end,
        SearchDepth = 0,
    })
    m_caiPanel:AddChild(m_caiQueueTree)

    m_caiMainTree = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAITechTreeMain"), "Treeview", {
        GetLabel    = function() return Locale.Lookup("LOC_CAI_TECH_TREE_MAIN_LIST") end,
        SearchDepth = 2,
    })
    m_caiMainTree:AddInputBinding({
        Key = Keys.VK_BACK,
        Action = function()
            local id = table.remove(m_breadcrumbs)
            if not id then return false end
            local widget = m_caiMainTree:GetChildById(id, true)
            if widget then mgr:SetFocus(widget) end
            return true
        end,
    })
    m_caiPanel:AddChild(m_caiMainTree)

    m_caiFilterDropdown = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAITechTreeFilter"), "DropdownMenu", {
        GetLabel     = function() return Locale.Lookup("LOC_CAI_TECH_TREE_FILTER") end,
        GetValue     = function()
            return (m_activeFilterEntry and m_activeFilterEntry.Label)
                or Locale.Lookup("LOC_TECH_FILTER_NONE")
        end,
        OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
        OnClick      = OpenFilterList,
    })
    m_caiPanel:AddChild(m_caiFilterDropdown)

    RebuildMainTree()
    RebuildQueueTree()
end

local function PushPanel()
    if not mgr then return end
    EnsurePanelBuilt()
    if not m_caiPanel or mgr:HasWidget(m_caiPanel) then return end

    local playerTechs = GetLocalPlayerTechs()
    local hasCurrent = playerTechs and playerTechs:GetResearchingTech() ~= -1
    -- Index 1 = queue, 2 = main tree, 3 = filter
    m_caiPanel:SetDefaultIndex(hasCurrent and 1 or 2)
    mgr:Push(m_caiPanel)
end

local function OnPanelClosedCAI()
    if m_caiPanel and mgr and mgr:HasWidget(m_caiPanel) then
        mgr:Pop()
    end
    m_caiPanel          = nil
    m_caiQueueTree      = nil
    m_caiMainTree       = nil
    m_caiFilterDropdown = nil
    m_caiTechsByType    = {}
    m_leadsToByType     = {}
    m_techIndexToType   = {}
    m_lastPlayerData    = nil
    m_caiFilterEntries  = nil
    m_activeFilterEntry = nil
    m_activeFilterFunc  = nil
    m_breadcrumbs       = {}
end

local function IsPanelOnStack()
    return m_caiPanel and mgr and mgr:HasWidget(m_caiPanel)
end

-- ===========================================================================
-- WRAPS
-- ===========================================================================

View = WrapFunc(View, function(orig, playerData)
    m_lastPlayerData = playerData
    orig(playerData)
    if m_caiPanel then
        RebuildQueueTree()
    end
end)


-- Vanilla Initialize subscribed the original OnOpen reference to the open
-- LuaEvents before this file loaded; rewrap-and-reswap so the wrapped version
-- is what actually fires.
local _origOnOpen = OnOpen
OnOpen = WrapFunc(OnOpen, function(orig)
    orig()
    PushPanel()
end)
LuaEvents.LaunchBar_RaiseTechTree.Remove(_origOnOpen)
LuaEvents.ResearchChooser_RaiseTechTree.Remove(_origOnOpen)
LuaEvents.LaunchBar_RaiseTechTree.Add(OnOpen)
LuaEvents.ResearchChooser_RaiseTechTree.Add(OnOpen)

-- KeyUpHandler ESC and OnClose both call Close() by global name, so wrapping
-- Close catches every vanilla close path including LaunchBar_CloseTechTree.
-- Pop the CAI panel before orig() fires TechTree_CloseTechTree, otherwise the
-- tutorial may synchronously raise an advisor popup onto the stack between
-- orig() and the pop, and mgr:Pop() would remove that popup instead of the
-- tech tree panel.
Close = WrapFunc(Close, function(orig)
    OnPanelClosedCAI()
    orig()
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
    local top = mgr:GetTop()
    if top ~= m_caiPanel and top ~= m_caiFilterList then return false end
    if mgr:HandleInput(pInputStruct) then
        return true
    end
    return orig(pInputStruct)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)

-- ===========================================================================
-- EVENTS
-- ===========================================================================

local function RebuildQueueIfOpen()
    if IsPanelOnStack() then RebuildQueueTree() end
end

Events.ResearchChanged.Add(function(ePlayer)
    if ePlayer == Game.GetLocalPlayer() then RebuildQueueIfOpen() end
end)

Events.ResearchQueueChanged.Add(function(ePlayer)
    if ePlayer == Game.GetLocalPlayer() then RebuildQueueIfOpen() end
end)

Events.ResearchCompleted.Add(function(ePlayer)
    if ePlayer ~= Game.GetLocalPlayer() or not IsPanelOnStack() then return end
    if not m_lastPlayerData then return end
    local focusedType = CaptureFocusedTechType()
    RebuildMainTree()
    RebuildQueueTree()
    if focusedType and m_caiTechsByType[focusedType] then
        mgr:SetFocus(m_caiTechsByType[focusedType])
    end
end)

Events.LocalPlayerTurnBegin.Add(function(ePlayer)
    if ePlayer == Game.GetLocalPlayer() then RebuildQueueIfOpen() end
end)

Events.LocalPlayerChanged.Add(function() OnPanelClosedCAI() end)
