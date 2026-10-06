include("CAIControl")
include("textProcessing")

-- One coordinator per vanilla UI context. All context data is read through the
-- adapter at use time; this module owns widgets, view/filter state and breadcrumbs.
CAIResearchTree = {}

---@param mgr UIScreenManager
---@param adapter CAIResearchTreeAdapter
---@return CAIResearchTreeController
function CAIResearchTree.Create(mgr, adapter)
    local PANEL_ID = adapter.IdPrefix .. "_Panel"
    local QUEUE_LIST_ID = adapter.IdPrefix .. "_QueueList"
    local FILTER_LIST_ID = adapter.IdPrefix .. "_FilterList"
    local MAIN_TREE_ID = adapter.IdPrefix .. "_MainTree"
    local GRID_VIEW_ID = adapter.IdPrefix .. "_GridView"
    local GRAPH_VIEW_ID = adapter.IdPrefix .. "_GraphView"
    local UNLOCKS_LIST_ID = adapter.IdPrefix .. "_UnlocksList"
    local CHANGE_VIEW_ID = adapter.IdPrefix .. "_ChangeView"
    local FILTER_RESULTS_ID = adapter.IdPrefix .. "_FilterResults"
    local VIEW_MODES = { "grid", "graph", "tree" }
    local m_panel, m_queueList, m_filterList, m_mainTree, m_gridView, m_graphView
    local m_unlocksList, m_viewDropdown, m_filterResults
    local m_treeItems, m_gridItems, m_graphItems = {}, {}, {}
    local m_lastFocusedItem
    local m_filterEntries, m_activeFilterFunc
    local m_breadcrumbs = {}
    local m_viewMode

    local function GetViewModeIndex(viewMode)
        for index, mode in ipairs(VIEW_MODES) do
            if mode == viewMode then return index end
        end
        return nil
    end

    local function LoadViewModeSetting()
        local stored = tostring(CAI.GetConfigValue(
            "UI", adapter.SettingID, "grid")):lower()
        if GetViewModeIndex(stored) then return stored end
        LogWarn(adapter.DebugName .. " ignored invalid saved view mode " .. tostring(stored))
        return "grid"
    end

    local function SaveViewModeSetting(viewMode)
        if not CAI.SetConfigValue("UI", adapter.SettingID, viewMode) then
            LogError(adapter.DebugName .. " failed to save view mode " .. tostring(viewMode))
        end
    end

    m_viewMode = LoadViewModeSetting()

    local function EnsureFilterEntries()
        if m_filterEntries then return end
        m_filterEntries = {}
        if not adapter.GetFilters() then return end
        local defs = adapter.FilterDefinitions
        for _, pair in ipairs(defs) do
            local fn = adapter.GetFilters()[pair[1]]
            if fn then
                table.insert(m_filterEntries, {
                    Label        = Locale.Lookup(pair[2]),
                    Func         = fn,
                    VanillaEntry = { Func = fn, Description = pair[2] },
                })
            end
        end
    end

    local function FilterMatchesItem(itemType)
        if not m_activeFilterFunc then return true end
        return m_activeFilterFunc(itemType) == true
    end

    -- Shared layout input; each consumer retains its own ordering policy.
    local function GetEraEntries(era)
        local entries = {}
        for itemType, entry in pairs(adapter.GetEntries()) do
            if entry.EraType == era.EraType and FilterMatchesItem(itemType) then
                entries[#entries + 1] = {
                    itemType = itemType,
                    column = adapter.GetColumn(itemType, entry),
                    row = entry.UITreeRow or 0,
                }
            end
        end
        return entries
    end

    local function GroupEraColumns(era)
        local byColumn, columns = {}, {}
        -- Zero is part of the grid extent even if every occupied row has one sign.
        local rowMin, rowMax = 0, 0
        for _, entry in ipairs(GetEraEntries(era)) do
            if not byColumn[entry.column] then
                byColumn[entry.column] = {}
                columns[#columns + 1] = entry.column
            end
            table.insert(byColumn[entry.column], entry)
            rowMin = math.min(rowMin, entry.row)
            rowMax = math.max(rowMax, entry.row)
        end
        table.sort(columns)
        return byColumn, columns, rowMin, rowMax
    end

    local function GetFocusedItemType()
        local path = mgr and mgr.CurrentPath or nil
        if not path then return nil end
        for i = #path, 1, -1 do
            local w = path[i]
            local key = w and w.FocusKey or nil
            if key and string.sub(key, 1, #adapter.FocusPrefix) == adapter.FocusPrefix then
                return string.sub(key, #adapter.FocusPrefix + 1)
            end
        end
        return nil
    end

    local function GetActiveItemWidget(itemType)
        if m_viewMode == "grid" then return m_gridItems[itemType] end
        if m_viewMode == "graph" then return m_graphItems[itemType] end
        return m_treeItems[itemType]
    end

    local function GetActiveItemView()
        if m_viewMode == "grid" then return m_gridView end
        if m_viewMode == "graph" then return m_graphView end
        return m_mainTree
    end

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

    local function JumpToItem(itemType, recordBreadcrumb)
        local target = GetActiveItemWidget(itemType)
        if not target then return end

        if recordBreadcrumb then
            local source = GetFocusedItemType()
            if source and source ~= itemType then
                table.insert(m_breadcrumbs, source)
            end
        end
        local parts = { adapter.GetName(itemType) or "" }
        if m_viewMode == "tree" then
            local srcEra, srcTier = GetEnclosingEraTier(mgr:GetFocusedWidget())
            local tgtEra, tgtTier = GetEnclosingEraTier(target)
            if tgtTier and tgtTier ~= srcTier then CAIText.AppendIfNonEmpty(parts, tgtTier:GetLabel()) end
            if tgtEra and tgtEra ~= srcEra then CAIText.AppendIfNonEmpty(parts, tgtEra:GetLabel()) end
        end

        Speak(Locale.Lookup(adapter.Text.Jump, table.concat(parts, "[NEWLINE]")), true)
        mgr:SetFocus(target)
    end

    local function AddRowBindings(widget, itemType, allowQueue)
        local bindings = {
            {
                Key         = Keys.VK_RETURN,
                IsControl   = true,
                MSG         = KeyEvents.KeyUp,
                Description = adapter.Text.QueueAction,
                Action      = function()
                    if not adapter.CanResearch(itemType) then return true end
                    adapter.AppendToQueue(itemType)
                    return true
                end,
            },
            {
                Key         = Keys.VK_RETURN,
                IsShift     = true,
                MSG         = KeyEvents.KeyUp,
                Description = "LOC_CAI_KB_OPEN_CIVILOPEDIA",
                Action      = function()
                    if not adapter.IsRevealed(itemType) then return true end
                    if IsTutorialRunning and IsTutorialRunning() then return true end
                    LuaEvents.OpenCivilopedia(itemType)
                    return true
                end,
            },
        }
        if not allowQueue then table.remove(bindings, 1) end
        widget:AddInputBindings(bindings)
    end

    local function CreateRefLink(parentWidget, itemType, currentEraType)
        local capturedType = itemType
        local item = mgr:CreateWidget(mgr:GenerateWidgetId(adapter.IdPrefix .. "Ref"), "TreeItem", {
            Label             = function() return adapter.GetRelatedLabel(capturedType, currentEraType) end,
            HiddenPredicate   = function() return m_treeItems[capturedType] == nil end,
            DisabledPredicate = function() return not adapter.IsRevealed(capturedType) end,
            FocusKey          = "ref:" .. tostring(capturedType),
        })
        item:On("activate", function(w)
            if w:IsDisabled() then return end
            JumpToItem(capturedType, true)
        end)
        item:AddInputBindings({
            {
                Key         = Keys.VK_RETURN,
                IsShift     = true,
                MSG         = KeyEvents.KeyUp,
                Description = "LOC_CAI_KB_OPEN_CIVILOPEDIA",
                Action      = function(w)
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

    local function AddDetailChildren(item, itemType)
        local kStatic = adapter.GetEntries()[itemType]
        local currentEraType = kStatic and kStatic.EraType
        if adapter.IsRevealed(itemType) then
            local unlockChildren = {}
            for _, unlock in ipairs(adapter.GetUnlocks(itemType)) do
                if unlock.Description then
                    table.insert(unlockChildren, unlock)
                end
            end
            if #unlockChildren > 0 then
                local node = mgr:CreateWidget(mgr:GenerateWidgetId(adapter.IdPrefix .. "Unlocks"), "TreeItem", {
                    Label = function() return Locale.Lookup(adapter.Text.Unlocks) end,
                })
                for _, unlock in ipairs(unlockChildren) do
                    node:AddChild(CreateUnlockChild(mgr, unlock, adapter.IdPrefix .. "Unlock"))
                end
                item:AddChild(node)
            end
        end
        local prereqTypes = {}
        for _, pt in ipairs(kStatic and kStatic.Prereqs or {}) do
            if pt ~= adapter.PrereqStart then table.insert(prereqTypes, pt) end
        end
        if #prereqTypes > 0 then
            local node = mgr:CreateWidget(mgr:GenerateWidgetId(adapter.IdPrefix .. "Prereqs"), "TreeItem", {
                Label = function() return Locale.Lookup(adapter.Text.Prerequisites) end,
            })
            for _, pt in ipairs(prereqTypes) do CreateRefLink(node, pt, currentEraType) end
            item:AddChild(node)
        end
        local leadsTo = adapter.GetLeadsTo(itemType)
        if leadsTo and #leadsTo > 0 then
            local node = mgr:CreateWidget(mgr:GenerateWidgetId(adapter.IdPrefix .. "LeadsTo"), "TreeItem", {
                Label = function() return Locale.Lookup(adapter.Text.LeadsTo) end,
            })
            for _, lt in ipairs(leadsTo) do CreateRefLink(node, lt, currentEraType) end
            item:AddChild(node)
        end
        if adapter.CanResearch(itemType) and kStatic then
            local path = adapter.GetPath(kStatic.Hash)
            if path and #path > 1 then
                local node = mgr:CreateWidget(mgr:GenerateWidgetId(adapter.IdPrefix .. "Path"), "TreeItem", {
                    Label = function() return Locale.Lookup(adapter.Text.Path) end,
                })
                for i = 1, #path - 1 do
                    local tt = adapter.GetTypeForIndex(path[i])
                    if tt then CreateRefLink(node, tt, currentEraType) end
                end
                item:AddChild(node)
            end
        end
    end

    local function RebuildUnlocksList(itemType)
        if not m_unlocksList then return end
        m_unlocksList:ClearChildren()
        if not itemType then return end
        if not adapter.IsRevealed(itemType) then return end
        for _, unlock in ipairs(adapter.GetUnlocks(itemType)) do
            if unlock.Description then
                m_unlocksList:AddChild(CreateUnlockChild(mgr, unlock, adapter.GridIdPrefix .. "Unlock"))
            end
        end
    end

    local function BuildItem(itemType, asTree)
        local capturedType = itemType
        local item = mgr:CreateWidget(mgr:GenerateWidgetId((asTree and adapter.IdPrefix or adapter.GridIdPrefix) .. adapter.NodeSuffix), asTree and "TreeItem" or "Button", {
            Label             = function() return adapter.FormatLabel(capturedType) end,
            Tooltip           = function() return adapter.FormatTooltip(capturedType) end,
            DisabledPredicate = function()
                local node = adapter.GetUiNode(capturedType)
                if node and node.Top and node.Top:IsDisabled() then return true end
                return not adapter.CanResearch(capturedType)
            end,
            FocusKey          = adapter.FocusPrefix .. tostring(capturedType),
        })
        item:SetFocusSound("Main_Menu_Mouse_Over")

        item:On("focus_enter", function(w)
            m_lastFocusedItem = capturedType
            if not asTree then RebuildUnlocksList(capturedType) end
        end)

        item:On("activate", function(w)
            if w:IsDisabled() then return end
            adapter.SetCurrent(capturedType)
        end)

        AddRowBindings(item, capturedType, true)

        if asTree then AddDetailChildren(item, capturedType) end
        return item
    end

    local function RebuildMainTree()
        if not m_mainTree then return end

        local capture = mgr:CaptureFocusKey(m_mainTree)
        m_mainTree:ClearChildren()
        m_treeItems = {}

        for _, era in ipairs(adapter.GetEras()) do
            local byColumn, colValues = GroupEraColumns(era)
            if #colValues > 0 then

                local capturedDescription = era.Description
                local eraItem = mgr:CreateWidget(mgr:GenerateWidgetId(adapter.IdPrefix .. "Era"), "TreeItem", {
                    Label    = function() return Locale.Lookup(capturedDescription) end,
                    FocusKey = "era:" .. tostring(era.EraType),
                })

                for tierIndex, colVal in ipairs(colValues) do
                    local tierNumber = tierIndex
                    local tierItem = mgr:CreateWidget(mgr:GenerateWidgetId(adapter.IdPrefix .. "Tier"), "TreeItem", {
                        Label    = function() return Locale.Lookup("LOC_CAI_TREE_TIER", tierNumber) end,
                        FocusKey = "tier:" .. tostring(era.EraType) .. ":" .. tostring(colVal),
                    })

                    local tierItems = byColumn[colVal]
                    table.sort(tierItems, function(a, b) return a.row < b.row end)
                    for _, entry in ipairs(tierItems) do
                        local widget = BuildItem(entry.itemType, true)
                        m_treeItems[entry.itemType] = widget
                        tierItem:AddChild(widget)
                    end
                    tierItem:Expand(true)
                    eraItem:AddChild(tierItem)
                end
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

    local function MakeGridSpacer()
        return mgr:CreateWidget(mgr:GenerateWidgetId(adapter.GridIdPrefix .. "Spacer"), "StaticText", {
            HiddenPredicate = function() return true end,
        })
    end

    local function RebuildGridView()
        if not m_gridView then return end

        local capture = mgr:CaptureFocusKey(m_gridView)
        m_gridView:ClearChildren()
        m_gridItems = {}

        for _, era in ipairs(adapter.GetEras()) do
            local byColumn, colValues, rowMin, rowMax = GroupEraColumns(era)
            if #colValues > 0 then
                local capturedDescription = era.Description
                local column = m_gridView:AddColumn({
                    header = function() return Locale.Lookup(capturedDescription) end,
                    width  = #colValues,
                })
                for tierIndex, colVal in ipairs(colValues) do
                    local tierItems = byColumn[colVal]
                    local byRow = {}
                    for _, entry in ipairs(tierItems) do byRow[entry.row] = entry end
                    for r = rowMin, rowMax do
                        local entry = byRow[r]
                        if entry then
                            local cell = BuildItem(entry.itemType, false)
                            m_gridItems[entry.itemType] = cell
                            m_gridView:AddItem(column, tierIndex, cell)
                        else
                            m_gridView:AddItem(column, tierIndex, MakeGridSpacer())
                        end
                    end
                end
            end
        end

        mgr:RestoreFocus(m_gridView, capture)
    end

    local function RebuildGraphView()
        if not m_graphView then return end

        local capture = mgr:CaptureFocusKey(m_graphView)
        m_graphView:ClearGraph()
        m_graphItems = {}

        for _, era in ipairs(adapter.GetEras()) do
            local eraItems = GetEraEntries(era)
            table.sort(eraItems, function(a, b)
                if a.column ~= b.column then return a.column < b.column end
                if a.row ~= b.row then return a.row < b.row end
                return a.itemType < b.itemType
            end)
            if #eraItems > 0 then
                local capturedDescription = era.Description
                m_graphView:AddGroup({
                    key = era.EraType,
                    label = function() return Locale.Lookup(capturedDescription) end,
                })
                for _, entry in ipairs(eraItems) do
                    local node = BuildItem(entry.itemType, false)
                    m_graphItems[entry.itemType] = node
                    m_graphView:AddNode(entry.itemType, node, { group = era.EraType })
                end
            end
        end

        for itemType, kEntry in pairs(adapter.GetEntries()) do
            if m_graphItems[itemType] then
                for _, prereqType in ipairs(kEntry.Prereqs or {}) do
                    if prereqType ~= adapter.PrereqStart and m_graphItems[prereqType] then
                        m_graphView:AddEdge(prereqType, itemType)
                    end
                end
            end
        end

        mgr:RestoreFocus(m_graphView, capture)
    end

    local function RebuildItemViews()
        RebuildMainTree()
        RebuildGridView()
        RebuildGraphView()
    end

    local function SetViewMode(viewMode)
        local selectedIndex = GetViewModeIndex(viewMode)
        assert(selectedIndex ~= nil, adapter.DebugName .. " received invalid view mode " .. tostring(viewMode))

        if m_viewMode ~= viewMode then
            m_viewMode = viewMode
            SaveViewModeSetting(viewMode)
        end
        if m_viewDropdown and m_viewDropdown:GetSelectedIndex() ~= selectedIndex then
            m_viewDropdown:SetSelectedIndex(selectedIndex, true)
        end
        local active = GetActiveItemView()
        local target = m_lastFocusedItem and GetActiveItemWidget(m_lastFocusedItem) or nil
        if target then mgr:SetFocus(target) elseif active then mgr:SetFocus(active) end
        return true
    end

    local function CreateQueueButton(itemType, isCurrent)
        local capturedType = itemType
        local btn = mgr:CreateWidget(mgr:GenerateWidgetId(adapter.IdPrefix .. "QueueRow"), "Button", {
            Label    = function()
                if isCurrent then
                    return Locale.Lookup(adapter.Text.Current, adapter.FormatLabel(capturedType))
                end
                return adapter.FormatLabel(capturedType)
            end,
            Tooltip  = function() return adapter.FormatTooltip(capturedType) end,
            FocusKey = (isCurrent and "queue:current:" or "queue:") .. tostring(capturedType),
        })
        btn:SetFocusSound("Main_Menu_Mouse_Over")
        btn:On("activate", function() JumpToItem(capturedType) end)
        AddRowBindings(btn, capturedType, false)
        return btn
    end

    local function RebuildQueueList()
        if not m_queueList then return end

        local capture = mgr:CaptureFocusKey(m_queueList)
        m_queueList:ClearChildren()

        local currentIdx, queue = adapter.ReadQueue()
        if queue or currentIdx then
            if currentIdx and currentIdx ~= -1 then
                local tt = adapter.GetTypeForIndex(currentIdx)
                if tt then m_queueList:AddChild(CreateQueueButton(tt, true)) end
            end
            if queue then
                for _, itemID in ipairs(queue) do
                    local tt = adapter.GetTypeForIndex(itemID)
                    if tt and tt ~= adapter.GetTypeForIndex(currentIdx or -1) then
                        m_queueList:AddChild(CreateQueueButton(tt, false))
                    end
                end
            end
        end

        mgr:RestoreFocus(m_queueList, capture)
    end

    local function ResetFilterToNone()
        m_activeFilterFunc  = nil
        adapter.ApplyFilter({ Func = nil, Description = "LOC_TECH_FILTER_NONE" })
        RebuildItemViews()
    end

    local function CreateFilterResultButton(itemType)
        local capturedType = itemType
        local btn = mgr:CreateWidget(mgr:GenerateWidgetId(adapter.IdPrefix .. "FilterResult"), "Button", {
            Label             = function() return adapter.FormatLabel(capturedType) end,
            Tooltip           = function() return adapter.FormatTooltip(capturedType) end,
            DisabledPredicate = function()
                local node = adapter.GetUiNode(capturedType)
                if node and node.Top and node.Top:IsDisabled() then return true end
                return false
            end,
            FocusKey          = "filterResult:" .. tostring(capturedType),
        })
        btn:SetFocusSound("Main_Menu_Mouse_Over")
        btn:On("activate", function()
            mgr:RemoveFromStack(FILTER_RESULTS_ID)
            JumpToItem(capturedType)
        end)
        AddRowBindings(btn, capturedType, true)
        return btn
    end

    local function OpenFilterResults(entry)
        if not entry or not entry.Func then return end

        m_activeFilterFunc  = entry.Func
        adapter.ApplyFilter(entry.VanillaEntry)
        RebuildItemViews()

        m_filterResults = mgr:CreateWidget(FILTER_RESULTS_ID, "List", {
            Label = function()
                return Locale.Lookup(adapter.Text.FilterResults, entry.Label)
            end,
        })

        for _, era in ipairs(adapter.GetEras()) do
            local eraItems = GetEraEntries(era)
            table.sort(eraItems, function(a, b)
                if a.column ~= b.column then return a.column < b.column end
                return a.row < b.row
            end)
            for _, e in ipairs(eraItems) do
                m_filterResults:AddChild(CreateFilterResultButton(e.itemType))
            end
        end

        m_filterResults:AddInputBindings({
            {
                Key         = Keys.VK_ESCAPE,
                MSG         = KeyEvents.KeyUp,
                Description = "LOC_CAI_KB_CLOSE",
                Action      = function()
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
            local btn = mgr:CreateWidget(mgr:GenerateWidgetId(adapter.IdPrefix .. "FilterBtn"), "Button", {
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

    local function ItemSearchHandler(query, maxResults)
        local results = {}
        local seen = {}
        if not Search.HasContext(adapter.SearchContext) then return results end
        local raw = Search.Search(adapter.SearchContext, query)
        if not raw then return results end
        for _, hit in ipairs(raw) do
            local itemType = hit[1]
            if not seen[itemType] then
                seen[itemType] = true
                local label = adapter.FormatLabel(itemType)
                if label and label ~= "" then
                    local tooltip = adapter.FormatTooltip(itemType)
                    results[#results + 1] = {
                        key        = itemType,
                        label      = label,
                        tooltip    = tooltip ~= "" and tooltip or nil,
                        onActivate = function() JumpToItem(itemType, false) end,
                    }
                end
                if #results >= maxResults then break end
            end
        end
        return results
    end

    local function EnsurePanelBuilt()
        if m_panel or not mgr then return end

        adapter.Prepare()
        EnsureFilterEntries()

        m_panel = mgr:CreateWidget(PANEL_ID, "Panel", {
            Label = function() return adapter.GetTitle() end,
        })
        m_panel:AddInputBindings({
            {
                Key = Keys["1"], IsAlt = true, MSG = KeyEvents.KeyDown,
                Description = "LOC_CAI_TREE_SWITCH_TO_GRID",
                Action = function() return SetViewMode("grid") end,
            },
            {
                Key = Keys["2"], IsAlt = true, MSG = KeyEvents.KeyDown,
                Description = "LOC_CAI_TREE_SWITCH_TO_GRAPH",
                Action = function() return SetViewMode("graph") end,
            },
            {
                Key = Keys["3"], IsAlt = true, MSG = KeyEvents.KeyDown,
                Description = "LOC_CAI_TREE_SWITCH_TO_TREE",
                Action = function() return SetViewMode("tree") end,
            },
        })

        m_queueList = mgr:CreateWidget(QUEUE_LIST_ID, "List", {
            Label           = function() return Locale.Lookup(adapter.Text.QueueList) end,
            HiddenPredicate = function(w) return not w.Children or #w.Children == 0 end,
            SearchDepth     = 0,
        })
        m_filterList = mgr:CreateWidget(FILTER_LIST_ID, "List", {
            Label       = function() return Locale.Lookup(adapter.Text.Filter) end,
            SearchDepth = 0,
        })
        BuildFilterList()
        m_mainTree = mgr:CreateWidget(MAIN_TREE_ID, "Tree", {
            Label           = function() return Locale.Lookup(adapter.Text.MainList) end,
            HiddenPredicate = function() return m_viewMode ~= "tree" end,
            SearchDepth     = 3,
        })
        m_mainTree:SetSearchQueryHandler(ItemSearchHandler)
        m_mainTree:AddInputBindings({
            {
                Key         = Keys.VK_BACK,
                MSG         = KeyEvents.KeyUp,
                Description = adapter.Text.BackAction,
                Action      = function()
                    local source = table.remove(m_breadcrumbs)
                    if not source then return false end
                    JumpToItem(source, false)
                    return true
                end,
            },
        })
        m_panel:AddChild(m_mainTree)
        m_gridView = mgr:CreateWidget(GRID_VIEW_ID, "Grid", {
            Label           = function() return Locale.Lookup(adapter.Text.MainList) end,
            HiddenPredicate = function() return m_viewMode ~= "grid" end,
        })
        m_gridView:SetSearchQueryHandler(ItemSearchHandler)
        m_panel:AddChild(m_gridView)
        m_graphView = mgr:CreateWidget(GRAPH_VIEW_ID, "Graph", {
            Label           = function() return Locale.Lookup(adapter.Text.MainList) end,
            HiddenPredicate = function() return m_viewMode ~= "graph" end,
        })
        m_graphView:SetSearchQueryHandler(ItemSearchHandler)
        m_panel:AddChild(m_graphView)
        m_unlocksList = mgr:CreateWidget(UNLOCKS_LIST_ID, "List", {
            Label           = function() return Locale.Lookup(adapter.Text.Unlocks) end,
            HiddenPredicate = function(w)
                return (m_viewMode ~= "grid" and m_viewMode ~= "graph")
                    or not w.Children or #w.Children == 0
            end,
            SearchDepth     = 0,
        })
        m_panel:AddChild(m_unlocksList)

        m_panel:AddChild(m_filterList)
        m_panel:AddChild(m_queueList)
        if adapter.AddExtraPanels then adapter.AddExtraPanels(m_panel) end
        m_viewDropdown = mgr:CreateWidget(CHANGE_VIEW_ID, "Dropdown", {
            Label = function() return Locale.Lookup("LOC_CAI_TREE_VIEW_MODE") end,
            FocusKey = adapter.ViewFocusKey,
        })
        m_viewDropdown:SetOptions({
            { label = Locale.Lookup("LOC_CAI_TREE_VIEW_GRID"), value = "grid" },
            { label = Locale.Lookup("LOC_CAI_TREE_VIEW_GRAPH"), value = "graph" },
            { label = Locale.Lookup("LOC_CAI_TREE_VIEW_TREE"), value = "tree" },
        })
        m_viewDropdown:SetSelectedIndex(GetViewModeIndex(m_viewMode), true)
        m_viewDropdown:On("value_changed", function(_, viewMode) SetViewMode(viewMode) end)
        m_panel:AddChild(m_viewDropdown)

        RebuildItemViews()
        RebuildQueueList()
        if adapter.RefreshExtra then adapter.RefreshExtra() end
    end

    local function PushPanel()
        if not mgr then return end
        EnsurePanelBuilt()
        if not m_panel or mgr:GetWidgetById(PANEL_ID) then return end

        mgr:Push(m_panel, { priority = 99 })
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
        m_gridView          = nil
        m_graphView         = nil
        m_unlocksList       = nil
        m_viewDropdown      = nil
        m_filterResults     = nil
        m_treeItems         = {}
        m_gridItems         = {}
        m_graphItems        = {}
        m_lastFocusedItem   = nil
        m_filterEntries     = nil
        m_activeFilterFunc  = nil
        m_breadcrumbs       = {}
        adapter.ResetData()
    end

    local function IsPanelOnStack()
        return m_panel and mgr and mgr:GetWidgetById(PANEL_ID) ~= nil
    end

    local function RefocusIfItemRow()
        if not IsPanelOnStack() then return end
        local focused = mgr:GetFocusedWidget()
        if not focused or not focused.FocusKey then return end
        local key = focused.FocusKey
        if string.sub(key, 1, #adapter.FocusPrefix) == adapter.FocusPrefix
            or string.sub(key, 1, 6) == "queue:" then
            mgr:Refocus()
        end
    end

    return {
        Open = PushPanel,
        Close = OnPanelClosedCAI,
        IsOpen = IsPanelOnStack,
        HasPanel = function() return m_panel ~= nil end,
        RebuildViews = RebuildItemViews,
        RebuildQueue = RebuildQueueList,
        RefocusRow = RefocusIfItemRow,
    }
end
