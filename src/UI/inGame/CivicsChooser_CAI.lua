include("caiUtils")
include("CivicsChooser")
local mgr                        = ExposedMembers.CAI_UIManager

local UNLOCKS_INLINE             = 2

local m_caiPanel                 = nil ---@type UIWidget|nil
local m_caiAvailableTree         = nil ---@type UIWidget|nil
local m_caiQueueTree             = nil ---@type UIWidget|nil
local m_caiRowData               = {} ---@type table<number, table>
local m_caiAvailableRows         = {} ---@type table<number, table>
local m_caiQueueRows             = {} ---@type table<number, table>
local m_caiCurrentData           = nil ---@type table|nil
local m_caiOpenPending           = false ---@type boolean
local m_caiInstanceByHash        = {} ---@type table<number, table>
local m_caiCurrentControl        = nil ---@type table|nil

-- ===========================================================================
-- Vanilla CivicsChooser does not have the base tutorial reorder hack that
-- ResearchChooser has. Tutorial behavior is still respected by reading the
-- live native row controls for hidden/disabled state.
-- ===========================================================================
local function ReorderForTutorial(rowData)
    return rowData
end

-- ===========================================================================
-- Unlock helpers. Reuses the native cached lookup - format is {typeName, Name,
-- CivilopediaKey}. Entries missing a name are skipped.
-- ===========================================================================
local function ControlIsHidden(control)
    return control and control.IsHidden and control:IsHidden() or false
end

local function ControlIsDisabled(control)
    return control and control.IsDisabled and control:IsDisabled() or false
end

local function ControlText(control)
    if control and control.GetText then
        local text = control:GetText()
        if text and text ~= "" then return text end
    end
    if control and control.GetTextControl then
        local textControl = control:GetTextControl()
        if textControl and textControl.GetText then
            local text = textControl:GetText()
            if text and text ~= "" then return text end
        end
    end
    return ""
end

local function ControlTooltip(control)
    if control and control.GetToolTipString then
        local text = control:GetToolTipString()
        if text and text ~= "" then return text end
    end
    return ""
end

local function GetChildren(control)
    if control and control.GetChildren then
        return control:GetChildren() or {}
    end
    return {}
end

local function FindControlTextRecursive(control, targetText)
    if not control or not targetText or targetText == "" then return nil end
    if ControlText(control) == targetText then return control end
    for _, child in ipairs(GetChildren(control)) do
        local found = FindControlTextRecursive(child, targetText)
        if found then return found end
    end
    return nil
end

local function FindControlTooltipRecursive(control, targetTooltip)
    if not control or not targetTooltip or targetTooltip == "" then return nil end
    if ControlTooltip(control) == targetTooltip then return control end
    for _, child in ipairs(GetChildren(control)) do
        local found = FindControlTooltipRecursive(child, targetTooltip)
        if found then return found end
    end
    return nil
end

local function BuildCivicInstanceFromContainer(topContainer, kData)
    if not topContainer then return nil end
    local children = GetChildren(topContainer)
    return {
        TopContainer = topContainer,
        Top = FindControlTooltipRecursive(topContainer, kData and kData.ToolTip or "") or children[1] or topContainer,
        TechName = FindControlTextRecursive(topContainer, kData and Locale.ToUpper(kData.Name) or ""),
    }
end

local function GetLatestCivicInstanceFromStack(beforeCount, kData)
    local children = GetChildren(Controls.CivicStack)
    local targetName = kData and Locale.ToUpper(kData.Name) or ""
    if targetName ~= "" then
        for _, topContainer in ipairs(children) do
            local instance = BuildCivicInstanceFromContainer(topContainer, kData)
            if instance and instance.TechName then
                return instance
            end
        end
    end
    local topContainer = children[beforeCount + 1] or children[#children]
    return BuildCivicInstanceFromContainer(topContainer, kData)
end

local function GetInstanceForCivic(kData)
    if not kData or not kData.Hash then return nil end
    return m_caiInstanceByHash[kData.Hash]
end

local function GetCurrentCivicControl()
    return m_caiCurrentControl or Controls
end

local function GetDisplayControl(kData)
    local instance = GetInstanceForCivic(kData)
    if instance then return instance end
    if kData and kData.IsCurrent then
        return GetCurrentCivicControl()
    end
    return nil
end

local function IsCivicRowHidden(kData)
    local instance = GetInstanceForCivic(kData)
    if not instance then return false end
    return ControlIsHidden(instance.TopContainer) or ControlIsHidden(instance.Top)
end

local function IsCivicRowDisabled(kData)
    local instance = GetInstanceForCivic(kData)
    if not instance then return false end
    return ControlIsDisabled(instance.Top)
end

local function GetUnlockables(kData)
    if not kData or not kData.CivicType then return {} end
    local playerID = Game.GetLocalPlayer()
    return GetUnlockablesForCivic_Cached(kData.CivicType, playerID) or {}
end

local function GetUnlockNames(kData)
    local unlockables = GetUnlockables(kData)
    local names = {}
    for _, v in ipairs(unlockables) do
        local name = v[2]
        if name and name ~= "" then
            table.insert(names, Locale.Lookup(name))
        end
    end
    return names
end

local function GetObsoletePolicyNames(kData)
    local unlockables = GetUnlockables(kData)
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

local function GetCivicDisplayName(kData)
    local control = GetDisplayControl(kData)
    if control then
        local name = ControlText(control.TechName) or ""
        if name ~= "" then return name end
        name = ControlText(control.TitleButton) or ""
        if name ~= "" then return name end
    end
    return kData and kData.Name or ""
end

local function GetFirstNUnlockNamesFromList(names, n)
    local head = {}
    for i, name in ipairs(names or {}) do
        if i <= n then table.insert(head, name) else break end
    end
    return head
end

-- ===========================================================================
-- Formatting. Order of parts matches the user spec: name first, then any
-- status badges (recommended, boost), then cost, turns, queue, first N unlocks.
-- ===========================================================================
local function AppendIfNonEmpty(parts, text)
    if text and text ~= "" then table.insert(parts, text) end
end

local function FormatTurnsPart(kData)
    local control = GetDisplayControl(kData)
    if control then
        local turnsText = ControlText(control.TurnsLeft)
        local turnsNumber = string.match(turnsText, "%[ICON_Turn%](%d+)")
        if turnsNumber then
            return Locale.Lookup("LOC_TURNS_REMAINING_VAL", tonumber(turnsNumber))
        end
        if turnsText ~= "" then return turnsText end
    end
    if kData.IsLastCompleted and not kData.Repeatable then
        return Locale.Lookup("LOC_CAI_CIVIC_JUST_COMPLETED", GetCivicDisplayName(kData))
    end
    if kData.TurnsLeft and kData.TurnsLeft >= 0 then
        return Locale.Lookup("LOC_TURNS_REMAINING_VAL", kData.TurnsLeft)
    end
    return nil
end

local function GetBoostTooltipText(kData)
    local control = GetDisplayControl(kData)
    if control and kData and kData.Boostable then
        if kData.BoostTriggered then
            local tooltip = ControlTooltip(control.IconHasBeenBoosted)
            if tooltip ~= "" then return tooltip end
        else
            local tooltip = ControlTooltip(control.IconCanBeBoosted)
            if tooltip ~= "" then return tooltip end
        end
    end
    if not kData.Boostable then return "" end
    local trigger = kData.TriggerDesc and Locale.Lookup(kData.TriggerDesc) or ""
    if kData.BoostTriggered then
        return Locale.Lookup("LOC_TECH_HAS_BEEN_BOOSTED") .. ((trigger ~= "" and "[NEWLINE]" .. trigger) or "")
    end
    return Locale.Lookup("LOC_TECH_CAN_BE_BOOSTED") .. ((trigger ~= "" and "[NEWLINE]" .. trigger) or "")
end

local function FormatBoostPart(kData)
    local tooltip = GetBoostTooltipText(kData)
    if tooltip == "" then return nil end
    tooltip = string.gsub(tooltip, "%[NEWLINE%]", "\n")
    local firstLine = string.match(tooltip, "([^\n]+)")
    if not firstLine then return nil end
    return string.gsub(firstLine, "^%s*(.-)%s*$", "%1")
end

local function GetCivicTooltipText(kData)
    local control = GetDisplayControl(kData)
    if control then
        local tooltip = ControlTooltip(control.Top)
        if tooltip ~= "" then return tooltip end
    end
    return kData and kData.ToolTip or ""
end

local function HasQueuePosition(kData)
    if not kData or kData.IsCurrent then return false end
    local position = kData.ResearchQueuePosition
    return position ~= nil and position ~= -1 and position ~= 99
end

local function GetQueuePositionText(kData)
    if not HasQueuePosition(kData) then return nil end
    local control = GetDisplayControl(kData)
    if control then
        local number = ControlText(control.NodeNumber)
        if number ~= "" and number ~= "99" then
            return Locale.Lookup("LOC_CAI_CIVIC_QUEUE_POSITION", number)
        end
    end
    return Locale.Lookup("LOC_CAI_CIVIC_QUEUE_POSITION", kData.ResearchQueuePosition)
end

local function FormatRowLabel(kData)
    local parts = {}
    if kData.IsCurrent then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_CIVIC_CURRENT", GetCivicDisplayName(kData)))
    else
        AppendIfNonEmpty(parts, GetCivicDisplayName(kData))
    end
    if kData.IsRecommended then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_TECH_FILTER_RECOMMENDED"))
    end
    return table.concat(parts, ", ")
end

-- ===========================================================================
-- Detail helpers. The old read-only edit contents now live as collapsed child
-- tree items under each Civic row. Sources:
--   1. kData.ToolTip (name, cost, description, unlocks) from ToolTipHelper.
--   2. Boost line - ToolTipHelper does NOT include boost info; sighted get
--      this via the BoostLabel + boost icon tooltip next to the civic. Built
--      to match the sighted icon tooltip: "Can/Has been boosted: <trigger>".
--   3. Live status (IsCurrent progress/turns, queue position).
-- [NEWLINE] tokens are split into tree rows for easier navigation.
-- ===========================================================================
local function NormalizeFormattedText(text)
    text = text or ""
    text = string.gsub(text, "%[NEWLINE%]", ", ")
    text = string.gsub(text, "%s+", " ")
    return text
end

local function SplitFormattedLines(text)
    local lines = {}
    text = text or ""
    text = string.gsub(text, "%[NEWLINE%]", "\n")
    for line in string.gmatch(text, "([^\n]+)") do
        local trimmed = string.gsub(line, "^%s*(.-)%s*$", "%1")
        if trimmed ~= "" then
            table.insert(lines, trimmed)
        end
    end
    return lines
end

local function StartsWithIconBullet(text)
    return text and string.find(text, "^%s*%[ICON_Bullet%]") ~= nil
end

local function IsUnlocksHeader(text)
    if not text or text == "" then return false end
    local unlocksLabel = Locale.Lookup("LOC_TOOLTIP_UNLOCKS")
    return unlocksLabel and unlocksLabel ~= "" and string.find(text, unlocksLabel, 1, true) ~= nil
end

local function IsMakesObsoleteHeader(text)
    if not text or text == "" then return false end
    local obsoleteLabel = Locale.Lookup("LOC_TOOLTIP_MAKES_OBSOLETE")
    return obsoleteLabel and obsoleteLabel ~= "" and string.find(text, obsoleteLabel, 1, true) ~= nil
end

local function SplitTooltipLinesWithoutSpecialLists(text)
    local lines = {}
    local skippingList = false
    for _, line in ipairs(SplitFormattedLines(text)) do
        if IsUnlocksHeader(line) or IsMakesObsoleteHeader(line) then
            skippingList = true
        elseif skippingList and StartsWithIconBullet(line) then
            -- Unlock and obsolete rows are exposed in dedicated expandable nodes.
        else
            skippingList = false
            table.insert(lines, line)
        end
    end
    return lines
end

local function FormatShortTooltip(kData, unlockNames, obsoleteNames)
    local parts = {}
    local tooltipLines = SplitTooltipLinesWithoutSpecialLists(GetCivicTooltipText(kData))
    AppendIfNonEmpty(parts, FormatTurnsPart(kData))
    AppendIfNonEmpty(parts, tooltipLines[2])
    AppendIfNonEmpty(parts, FormatBoostPart(kData))
    for _, name in ipairs(GetFirstNUnlockNamesFromList(unlockNames, UNLOCKS_INLINE)) do
        AppendIfNonEmpty(parts, name)
    end
    local obsoletePreview = table.concat(GetFirstNUnlockNamesFromList(obsoleteNames, UNLOCKS_INLINE), ", ")
    if obsoletePreview ~= "" then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_CIVIC_MAKES_OBSOLETE_PREVIEW", obsoletePreview))
    end
    return table.concat(parts, "[NEWLINE]")
end

local function AddTextDetailNode(parent, text)
    if not text or text == "" then return end
    local detailText = text
    parent:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICivicsChooserDetail"), "TreeviewItem", {
        GetLabel = function() return NormalizeFormattedText(detailText) end,
    }))
end

local function AddUnlocksNode(parent, unlockNames)
    local count = #unlockNames
    local unlockNode = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICivicsChooserUnlocks"), "TreeviewItem", {
        GetLabel = function()
            if count == 1 then
                return Locale.Lookup("LOC_CAI_CIVIC_UNLOCKS_COUNT_ONE", count)
            end
            return Locale.Lookup("LOC_CAI_CIVIC_UNLOCKS_COUNT", count)
        end,
    })

    if count > 0 then
        for _, name in ipairs(unlockNames) do
            local unlockName = name
            unlockNode:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICivicsChooserUnlock"), "TreeviewItem", {
                GetLabel = function() return unlockName end,
            }))
        end
    else
        unlockNode:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICivicsChooserUnlock"), "TreeviewItem", {
            GetLabel = function() return Locale.Lookup("LOC_CAI_CIVIC_NO_UNLOCKS") end,
        }))
    end

    parent:AddChild(unlockNode)
end

local function AddMakesObsoleteNode(parent, obsoleteNames)
    local count = #obsoleteNames
    if count <= 0 then return end

    local obsoleteNode = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICivicsChooserObsolete"), "TreeviewItem", {
        GetLabel = function()
            if count == 1 then
                return Locale.Lookup("LOC_CAI_CIVIC_MAKES_OBSOLETE_COUNT_ONE", count)
            end
            return Locale.Lookup("LOC_CAI_CIVIC_MAKES_OBSOLETE_COUNT", count)
        end,
    })

    for _, name in ipairs(obsoleteNames) do
        local obsoleteName = name
        obsoleteNode:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICivicsChooserObsoleteItem"), "TreeviewItem", {
            GetLabel = function() return obsoleteName end,
        }))
    end

    parent:AddChild(obsoleteNode)
end

local function AddCivicDetailChildren(parent, kData, unlockNames, obsoleteNames)
    for _, line in ipairs(SplitTooltipLinesWithoutSpecialLists(GetCivicTooltipText(kData))) do
        AddTextDetailNode(parent, line)
    end

    AddTextDetailNode(parent, NormalizeFormattedText(GetBoostTooltipText(kData)))

    local statusParts = {}
    if kData.IsCurrent then
        table.insert(statusParts, Locale.Lookup("LOC_CAI_CIVIC_CURRENT_STATUS"))
        local pct = math.floor((kData.Progress or 0) * 100 + 0.5)
        table.insert(statusParts, Locale.Lookup("LOC_CAI_CIVIC_PROGRESS", pct))
        AppendIfNonEmpty(statusParts, FormatTurnsPart(kData))
    elseif kData.TurnsLeft and kData.TurnsLeft >= 0 then
        AppendIfNonEmpty(statusParts, FormatTurnsPart(kData))
    end
    AppendIfNonEmpty(statusParts, GetQueuePositionText(kData))
    if #statusParts > 0 then
        AddTextDetailNode(parent, table.concat(statusParts, ", "))
    end

    AddUnlocksNode(parent, unlockNames)
    AddMakesObsoleteNode(parent, obsoleteNames)
end

-- ===========================================================================
-- Partition predicate. Queued-or-current rows go to the view-only queue list;
-- everything else goes to the interactive available list. Current Civic
-- uses IsCurrent; vanilla can use sentinel queue positions for nonqueued rows.
-- ===========================================================================
local function IsQueuedOrCurrent(kData)
    return kData.IsCurrent
        or HasQueuePosition(kData)
end

-- ===========================================================================
-- Row factory. `interactive` true = available tree: Enter chooses Civic.
-- `interactive` false = queue tree: Enter bubbles to the treeview's generic
-- expand/collapse binding, keeping queued/current civic view-only.
-- ===========================================================================
local function CreateRowWidget(kData, interactive)
    local captured = kData
    local unlockNames = GetUnlockNames(captured)
    local obsoleteNames = GetObsoletePolicyNames(captured)

    local row = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICivicsChooserItem"), "TreeviewItem", {
        GetLabel = function() return FormatRowLabel(captured) end,
        GetTooltip = function() return FormatShortTooltip(captured, unlockNames, obsoleteNames) end,
        IsHidden = function() return IsCivicRowHidden(captured) end,
        IsDisabled = function() return interactive and IsCivicRowDisabled(captured) or false end,
        OnFocusEnter = function()
            UI.PlaySound("Main_Menu_Mouse_Over")
        end,
    })
    if interactive then
        row:AddInputBinding({
            Key = Keys.VK_RETURN,
            Action = function(w)
                if w and w.IsDisabled and w:IsDisabled() then return true end
                OnChooseCivic(captured.Hash)
                return true
            end,
        })
    end
    row:AddInputBinding({
        Key = Keys.VK_RETURN,
        IsShift = true,
        Action = function()
            if IsTutorialRunning and IsTutorialRunning() then return true end
            if captured.CivicType then
                LuaEvents.OpenCivilopedia(captured.CivicType)
            end
            return true
        end,
    })
    AddCivicDetailChildren(row, captured, unlockNames, obsoleteNames)
    row._caiHash = captured.Hash
    return row
end

-- ===========================================================================
-- Rebuild one tree's children from its row table.
-- ===========================================================================
local function RebuildOneTree(treeWidget, rows, interactive)
    if not treeWidget then return end
    treeWidget:ClearChildren()
    for _, kData in ipairs(rows) do
        treeWidget:AddChild(CreateRowWidget(kData, interactive))
    end
end

-- ===========================================================================
-- Full panel rebuild. Partitions m_caiRowData, applies tutorial reorder to
-- the available list only, sorts queue by (IsCurrent first, then
-- ResearchQueuePosition asc), splices m_caiCurrentData in at the head of the
-- queue list (vanilla View doesn't route non-Repeatable current Civic
-- through AddAvailableCivic), and rebuilds both lists.
-- ===========================================================================
local function RebuildCAIPanel()
    m_caiAvailableRows = {}
    m_caiQueueRows = {}
    for _, kData in ipairs(m_caiRowData) do
        if IsQueuedOrCurrent(kData) then
            table.insert(m_caiQueueRows, kData)
        else
            table.insert(m_caiAvailableRows, kData)
        end
    end
    ReorderForTutorial(m_caiAvailableRows)
    table.sort(m_caiQueueRows, function(a, b)
        if a.IsCurrent ~= b.IsCurrent then return a.IsCurrent == true end
        return (a.ResearchQueuePosition or 0) < (b.ResearchQueuePosition or 0)
    end)
    -- Vanilla View routes current Civic to RealizeCurrentCivic (not
    -- AddAvailableCivic) unless the civic is Repeatable, so it never lands
    -- in m_caiRowData. Our RealizeCurrentCivic wrap captures it in
    -- m_caiCurrentData - splice it in at the head of the queue list here so
    -- the user sees "Civic: X" as the first queue row.
    if m_caiCurrentData then
        local already = false
        for _, row in ipairs(m_caiQueueRows) do
            if row.Hash == m_caiCurrentData.Hash then
                already = true
                break
            end
        end
        if not already then
            table.insert(m_caiQueueRows, 1, m_caiCurrentData)
        end
    end

    RebuildOneTree(m_caiQueueTree, m_caiQueueRows, false)
    RebuildOneTree(m_caiAvailableTree, m_caiAvailableRows, true)
    if m_caiPanel then
        m_caiPanel:SetDefaultIndex(m_caiCurrentData and m_caiCurrentData.IsCurrent and 1 or 2)
    end
end

-- ===========================================================================
-- Build the static panel scaffolding once. List contents are filled by
-- RebuildCAIPanel() each time the native View() runs.
-- ===========================================================================
local function EnsurePanelBuilt()
    if m_caiPanel then return end

    m_caiPanel = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICivicsChooserPanel"), "Panel", {
        GetLabel = function() return Controls.Title:GetText() end,
    })

    -- Queue tree is hidden when no civic is active and the queue is empty,
    -- so Tab-order doesn't hit a dead widget in early game.
    m_caiQueueTree = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICivicsChooserTree"), "Treeview", {
        GetLabel = function() return Locale.Lookup("LOC_CAI_CIVIC_QUEUE_LIST") end,
        IsHidden = function() return #m_caiQueueRows == 0 end,
        SearchDepth = 0,
    })
    m_caiPanel:AddChild(m_caiQueueTree)

    m_caiAvailableTree = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICivicsChooserTree"), "Treeview", {
        GetLabel = function() return Locale.Lookup("LOC_CAI_CIVIC_AVAILABLE_LIST") end,
        SearchDepth = 0,
    })
    m_caiPanel:AddChild(m_caiAvailableTree)

    local treeBtn = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICivicsChooserButton"), "Button", {
        GetLabel = function() return Controls.OpenTreeButton:GetText() end,
        IsHidden = function() return ControlIsHidden(Controls.OpenTreeButton) end,
        IsDisabled = function() return ControlIsDisabled(Controls.OpenTreeButton) end,
        OnClick = function()
            LuaEvents.CivicsChooser_RaiseCivicsTree()
            OnClosePanel()
        end,
    })
    m_caiPanel:AddChild(treeBtn)

    RebuildCAIPanel()
end

-- ===========================================================================
-- LuaEvents bridges. Native open/close paths register handlers by reference
-- before our wraps exist, so we observe the public LuaEvents the native
-- already fires on every open and every animated close.
-- ===========================================================================
-- Defer the Push until the View wrap finishes populating the rows. Pushing
-- here would focus an empty list, then View's rebuild would add children
-- while the stale path [Panel, List] was still current - causing two speech
-- bursts (empty panel, then rebuilt panel with rows). The View wrap consumes
-- m_caiOpenPending below.
local function OnPanelOpenedCAI()
    EnsurePanelBuilt()
    if mgr:HasWidget(m_caiPanel) then return end
    m_caiOpenPending = true
end

local function PushPanelWhenReady()
    if not m_caiPanel or not mgr or mgr:HasWidget(m_caiPanel) then return end

    m_caiOpenPending = false
    mgr:Push(m_caiPanel, PopupPriority.Low)
end

local function OnPanelClosedCAI()
    if m_caiPanel and mgr:HasWidget(m_caiPanel) then
        mgr:Pop()
    end
    -- Null out so next open rebuilds; mgr:Pop destroys children and detaches
    -- the panel, making it unusable for a subsequent push.
    m_caiPanel                 = nil
    m_caiAvailableTree         = nil
    m_caiQueueTree             = nil
    m_caiRowData               = {}
    m_caiAvailableRows         = {}
    m_caiQueueRows             = {}
    m_caiCurrentData           = nil
    m_caiCurrentControl        = nil
    m_caiOpenPending           = false
    m_caiInstanceByHash        = {}
end

-- ===========================================================================
-- Wraps. View and AddAvailableCivic are called by global-name lookup from
-- inside the native file, so global re-binding takes effect for them.
-- OnInputHandler must be re-registered because Initialize captured the old
-- function reference. OnChooseCivic is wrapped only for selection
-- announcement on CAI-initiated calls (sighted-mouse clicks bypass it).
-- ===========================================================================
View = WrapFunc(View, function(orig, playerID, kData)
    m_caiRowData = {}
    m_caiCurrentData = nil
    m_caiCurrentControl = nil
    m_caiInstanceByHash = {}
    orig(playerID, kData)
    RebuildCAIPanel()
    -- Initial open: OnPanelOpenedCAI set m_caiOpenPending but deferred the
    -- Push. Now that the list has its real rows, let the UI screen manager
    -- choose the initial focus path.
    if m_caiOpenPending and m_caiPanel and mgr and not mgr:HasWidget(m_caiPanel) then
        PushPanelWhenReady()
    end
end)

AddAvailableCivic = WrapFunc(AddAvailableCivic, function(orig, playerID, kData)
    local beforeCount = #GetChildren(Controls.CivicStack)
    orig(playerID, kData)
    local instance = GetLatestCivicInstanceFromStack(beforeCount, kData)
    if playerID ~= -1 then
        table.insert(m_caiRowData, kData)
        if kData and kData.Hash and instance then
            m_caiInstanceByHash[kData.Hash] = instance
        end
    end
end)

RealizeCurrentCivic = WrapFunc(RealizeCurrentCivic, function(orig, playerID, kData, kControl, cachedModifiers)
    m_caiCurrentData = kData
    m_caiCurrentControl = kControl or Controls
    return orig(playerID, kData, kControl, cachedModifiers)
end)

-- Returning true when mgr consumes the input prevents WorldInput's wrapped
-- handler from receiving the same event and calling mgr:HandleInput a second
-- time (which caused focus to jump twice on Up/Down/Tab). When the input
-- causes our panel to pop, also close the native slide animator so visual
-- and accessibility state stay in sync.
OnInputHandler = WrapFunc(OnInputHandler, function(orig, kInputStruct)
    if mgr then
        local panelWasOnStack = m_caiPanel and mgr:HasWidget(m_caiPanel)
        if mgr:HandleInput(kInputStruct) then
            if panelWasOnStack and not mgr:HasWidget(m_caiPanel) then
                OnClosePanel()
            end
            return true
        end
    end
    return orig(kInputStruct)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)

OnChooseCivic = WrapFunc(OnChooseCivic, function(orig, civicHash)
    for _, kData in ipairs(m_caiRowData) do
        if kData.Hash == civicHash then
            Speak(Locale.Lookup("LOC_CAI_CIVIC_CHOSEN", kData.Name) or kData.Name)
            break
        end
    end
    return orig(civicHash)
end)

-- Every native close path funnels through OnClosePanel (Escape via SlideAnimator,
-- Space via action binding, X button, LaunchBar_CloseChoosers, civic-pick auto-close).
-- The LuaEvent fires only after the slide animation - not reliable for Space -
-- so pop here to sync immediately. OnPanelClosedCAI is idempotent.
OnClosePanel = WrapFunc(OnClosePanel, function(orig)
    orig()
    OnPanelClosedCAI()
end)

LuaEvents.ResearchChooser_ForceHideWorldTracker.Add(OnPanelOpenedCAI)
LuaEvents.ResearchChooser_RestoreWorldTracker.Add(OnPanelClosedCAI)

-- Queue changes from vanilla surfaces (for example Civics Tree queue edits) that
-- don't also change the active Civic don't fire
-- Events.CivicChanged, so the native Refresh/FlushChanges pipeline misses
-- them. Hook CivicQueueChanged and call Refresh() - that calls GetData()
-- (which re-reads pPlayerCulture:GetCivicQueue()) and View(kData), which
-- our wrap then turns into RebuildCAIPanel.
if Events and Events.CivicQueueChanged then
    Events.CivicQueueChanged.Add(function()
        if m_caiPanel and mgr and mgr:HasWidget(m_caiPanel) and Refresh then
            Refresh()
        end
    end)
end

