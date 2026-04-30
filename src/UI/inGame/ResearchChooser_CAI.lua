include("caiUtils")
include("ResearchChooser")
local mgr                        = ExposedMembers.CAI_UIManager

local TUTORIAL_MOD_ID            = "17462E0F-1EE1-4819-AAAA-052B5896B02A"
local UNLOCKS_INLINE             = 2

local m_caiPanel                 = nil ---@type UIWidget|nil
local m_caiAvailableTree         = nil ---@type UIWidget|nil
local m_caiQueueTree             = nil ---@type UIWidget|nil
local m_caiRowData               = {} ---@type table<number, table>
local m_caiAvailableRows         = {} ---@type table<number, table>
local m_caiQueueRows             = {} ---@type table<number, table>
local m_caiCurrentData           = nil ---@type table|nil
local m_caiIsTutorial            = nil ---@type boolean|nil
local m_caiTutorialTechs         = nil ---@type table<number, number>|nil
local m_caiOpenPending           = false ---@type boolean
local m_caiTutorialPushDelay     = false ---@type boolean
local m_caiTutorialControlsReady = false ---@type boolean
local m_caiTutorialPushPending   = false ---@type boolean
local m_caiInstanceByHash        = {} ---@type table<number, table>
local m_caiCurrentControl        = nil ---@type table|nil

-- ===========================================================================
-- Tutorial detection and reorder. Vanilla's m_isTutorial / TUTORIAL_TECHS are
-- file-local to ResearchChooser.lua and unreachable from here, so we replicate
-- them. Reorder drops the matching techs into positions 2/3/4, matching the
-- visual stack ordering vanilla applies via AddChildAtIndex.
-- ===========================================================================
local function IsCAITutorial()
    if m_caiIsTutorial ~= nil then return m_caiIsTutorial end
    m_caiIsTutorial = false
    for _, v in ipairs(Modding.GetActiveMods()) do
        if v.Id == TUTORIAL_MOD_ID then
            m_caiIsTutorial = true
            break
        end
    end
    return m_caiIsTutorial
end

local function GetTutorialTechHashes()
    if m_caiTutorialTechs then return m_caiTutorialTechs end
    m_caiTutorialTechs = {
        [2] = UITutorialManager:GetHash("TECH_MINING"),
        [3] = UITutorialManager:GetHash("TECH_IRRIGATION"),
        [4] = UITutorialManager:GetHash("TECH_POTTERY"),
    }
    return m_caiTutorialTechs
end

local function ReorderForTutorial(rowData)
    if not IsCAITutorial() then return end
    local targets = GetTutorialTechHashes()
    for targetIdx, techHash in pairs(targets) do
        for i, kData in ipairs(rowData) do
            if kData.Hash == techHash and i ~= targetIdx then
                table.remove(rowData, i)
                local insertAt = math.min(targetIdx, #rowData + 1)
                table.insert(rowData, insertAt, kData)
                break
            end
        end
    end
end

-- ===========================================================================
-- Unlock helpers. Reuses the native cached lookup — format is {typeName, Name,
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

local function GetInstanceForResearch(kData)
    if not kData or not kData.Hash then return nil end
    return m_caiInstanceByHash[kData.Hash]
end

local function GetCurrentResearchControl()
    return m_caiCurrentControl or Controls
end

local function GetDisplayControl(kData)
    local instance = GetInstanceForResearch(kData)
    if instance then return instance end
    if kData and kData.IsCurrent then
        return GetCurrentResearchControl()
    end
    return nil
end

local function IsResearchRowHidden(kData)
    local instance = GetInstanceForResearch(kData)
    if not instance then return false end
    return ControlIsHidden(instance.TopContainer) or ControlIsHidden(instance.Top)
end

local function IsResearchRowDisabled(kData)
    local instance = GetInstanceForResearch(kData)
    if not instance then return false end
    return ControlIsDisabled(instance.Top)
end

local function GetUnlockNames(kData)
    if not kData or not kData.TechType then return {} end
    local playerID = Game.GetLocalPlayer()
    local unlockables = GetUnlockablesForTech_Cached(kData.TechType, playerID) or {}
    local names = {}
    for _, v in ipairs(unlockables) do
        local name = v[2]
        if name and name ~= "" then
            table.insert(names, Locale.Lookup(name))
        end
    end
    return names
end

local function GetResearchDisplayName(kData)
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
        if turnsText ~= "" then return turnsText end
    end
    if kData.IsLastCompleted and not kData.Repeatable then
        return Locale.Lookup("LOC_RESEARCH_CHOOSER_JUST_COMPLETED")
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

local function GetResearchTooltipText(kData)
    local control = GetDisplayControl(kData)
    if control then
        local tooltip = ControlTooltip(control.Top)
        if tooltip ~= "" then return tooltip end
    end
    return kData and kData.ToolTip or ""
end

local function GetQueuePositionText(kData)
    local control = GetDisplayControl(kData)
    if control then
        local number = ControlText(control.NodeNumber)
        if number ~= "" then
            return Locale.Lookup("LOC_CAI_RESEARCH_QUEUE_POSITION", number)
        end
    end
    if kData.ResearchQueuePosition and kData.ResearchQueuePosition ~= -1 then
        return Locale.Lookup("LOC_CAI_RESEARCH_QUEUE_POSITION", kData.ResearchQueuePosition)
    end
    return nil
end

local function FormatRowLabel(kData)
    local parts = {}
    if kData.IsCurrent then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_RESEARCH_CURRENT", GetResearchDisplayName(kData)))
    else
        AppendIfNonEmpty(parts, GetResearchDisplayName(kData))
    end
    if kData.IsRecommended then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_TECH_FILTER_RECOMMENDED"))
    end
    return table.concat(parts, ", ")
end

-- ===========================================================================
-- Detail helpers. The old read-only edit contents now live as collapsed child
-- tree items under each research row. Sources:
--   1. kData.ToolTip (name, cost, description, unlocks) from ToolTipHelper.
--   2. Boost line — ToolTipHelper does NOT include boost info; sighted get
--      this via the BoostLabel + boost icon tooltip next to the tech. Built
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

local function SplitTooltipLinesWithoutUnlocks(text)
    local lines = {}
    local skippingUnlocks = false
    for _, line in ipairs(SplitFormattedLines(text)) do
        if IsUnlocksHeader(line) then
            skippingUnlocks = true
        elseif skippingUnlocks and StartsWithIconBullet(line) then
            -- Unlock rows are exposed in the dedicated expandable unlock node.
        else
            skippingUnlocks = false
            table.insert(lines, line)
        end
    end
    return lines
end

local function FormatShortTooltip(kData, unlockNames)
    local parts = {}
    local tooltipLines = SplitTooltipLinesWithoutUnlocks(GetResearchTooltipText(kData))
    AppendIfNonEmpty(parts, tooltipLines[2])
    AppendIfNonEmpty(parts, FormatBoostPart(kData))
    for _, name in ipairs(GetFirstNUnlockNamesFromList(unlockNames, UNLOCKS_INLINE)) do
        AppendIfNonEmpty(parts, name)
    end
    return table.concat(parts, "[NEWLINE]")
end

local function AddTextDetailNode(parent, text)
    if not text or text == "" then return end
    local detailText = text
    parent:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIResearchChooserDetail"), "TreeviewItem", {
        GetLabel = function() return NormalizeFormattedText(detailText) end,
    }))
end

local function AddUnlocksNode(parent, unlockNames)
    local count = #unlockNames
    local unlockNode = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIResearchChooserUnlocks"), "TreeviewItem", {
        GetLabel = function()
            if count == 1 then
                return Locale.Lookup("LOC_CAI_RESEARCH_UNLOCKS_COUNT_ONE", count)
            end
            return Locale.Lookup("LOC_CAI_RESEARCH_UNLOCKS_COUNT", count)
        end,
    })

    if count > 0 then
        for _, name in ipairs(unlockNames) do
            local unlockName = name
            unlockNode:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIResearchChooserUnlock"), "TreeviewItem", {
                GetLabel = function() return unlockName end,
            }))
        end
    else
        unlockNode:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIResearchChooserUnlock"), "TreeviewItem", {
            GetLabel = function() return Locale.Lookup("LOC_CAI_RESEARCH_NO_UNLOCKS") end,
        }))
    end

    parent:AddChild(unlockNode)
end

local function AddResearchDetailChildren(parent, kData, unlockNames)
    for _, line in ipairs(SplitTooltipLinesWithoutUnlocks(GetResearchTooltipText(kData))) do
        AddTextDetailNode(parent, line)
    end

    AddTextDetailNode(parent, NormalizeFormattedText(GetBoostTooltipText(kData)))

    local statusParts = {}
    if kData.IsCurrent then
        table.insert(statusParts, Locale.Lookup("LOC_CAI_RESEARCH_CURRENT_STATUS"))
        local pct = math.floor((kData.Progress or 0) * 100 + 0.5)
        table.insert(statusParts, Locale.Lookup("LOC_CAI_RESEARCH_PROGRESS", pct))
        AppendIfNonEmpty(statusParts, FormatTurnsPart(kData))
    elseif kData.TurnsLeft and kData.TurnsLeft >= 0 then
        AppendIfNonEmpty(statusParts, FormatTurnsPart(kData))
    end
    AppendIfNonEmpty(statusParts, GetQueuePositionText(kData))
    if #statusParts > 0 then
        AddTextDetailNode(parent, table.concat(statusParts, ", "))
    end

    AddUnlocksNode(parent, unlockNames)
end

-- ===========================================================================
-- Partition predicate. Queued-or-current rows go to the view-only queue list;
-- everything else goes to the interactive available list. Current research
-- reports ResearchQueuePosition == -1 so IsCurrent is the separate check.
-- ===========================================================================
local function IsQueuedOrCurrent(kData)
    return kData.IsCurrent
        or (kData.ResearchQueuePosition and kData.ResearchQueuePosition ~= -1)
end

-- ===========================================================================
-- Row factory. `interactive` true = available tree: Enter chooses research.
-- `interactive` false = queue tree: Enter bubbles to the treeview's generic
-- expand/collapse binding, keeping queued/current research view-only.
-- ===========================================================================
local function CreateRowWidget(kData, interactive)
    local captured = kData
    local unlockNames = GetUnlockNames(captured)

    local row = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIResearchChooserItem"), "TreeviewItem", {
        GetLabel = function() return FormatRowLabel(captured) end,
        GetTooltip = function() return FormatShortTooltip(captured, unlockNames) end,
        IsHidden = function() return IsResearchRowHidden(captured) end,
        IsDisabled = function() return interactive and IsResearchRowDisabled(captured) or false end,
        OnFocusEnter = function()
            UI.PlaySound("Main_Menu_Mouse_Over")
        end,
    })
    if interactive then
        row:AddInputBinding({
            Key = Keys.VK_RETURN,
            Action = function(w)
                if w and w.IsDisabled and w:IsDisabled() then return true end
                OnChooseResearch(captured.Hash)
                return true
            end,
        })
    end
    AddResearchDetailChildren(row, captured, unlockNames)
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
-- queue list (vanilla View doesn't route non-Repeatable current research
-- through AddAvailableResearch), and rebuilds both lists.
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
    -- Vanilla View routes current research to RealizeCurrentResearch (not
    -- AddAvailableResearch) unless the tech is Repeatable, so it never lands
    -- in m_caiRowData. Our RealizeCurrentResearch wrap captures it in
    -- m_caiCurrentData — splice it in at the head of the queue list here so
    -- the user sees "Researching: X" as the first queue row.
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

    m_caiPanel = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIResearchChooserPanel"), "Panel", {
        GetLabel = function() return Controls.Title:GetText() end,
    })

    -- Queue tree is hidden when nothing is researching and the queue is empty,
    -- so Tab-order doesn't hit a dead widget in early game.
    m_caiQueueTree = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIResearchChooserTree"), "Treeview", {
        GetLabel = function() return Locale.Lookup("LOC_CAI_RESEARCH_QUEUE_LIST") end,
        IsHidden = function() return #m_caiQueueRows == 0 end,
    })
    m_caiPanel:AddChild(m_caiQueueTree)

    m_caiAvailableTree = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIResearchChooserTree"), "Treeview", {
        GetLabel = function() return Locale.Lookup("LOC_CAI_RESEARCH_AVAILABLE_LIST") end,
    })
    m_caiPanel:AddChild(m_caiAvailableTree)

    local treeBtn = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIResearchChooserButton"), "Button", {
        GetLabel = function() return Controls.OpenTreeButton:GetText() end,
        IsHidden = function() return ControlIsHidden(Controls.OpenTreeButton) end,
        IsDisabled = function() return ControlIsDisabled(Controls.OpenTreeButton) end,
        OnClick = function()
            LuaEvents.ResearchChooser_RaiseTechTree()
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
-- while the stale path [Panel, List] was still current — causing two speech
-- bursts (empty panel, then rebuilt panel with rows). The View wrap consumes
-- m_caiOpenPending below.
local function OnPanelOpenedCAI()
    EnsurePanelBuilt()
    if mgr:HasWidget(m_caiPanel) then return end
    m_caiOpenPending = true
end

local function PushPanelWhenReady()
    if not m_caiPanel or not mgr or mgr:HasWidget(m_caiPanel) then return end

    if m_caiTutorialPushDelay and not m_caiTutorialControlsReady then
        m_caiOpenPending = false
        m_caiTutorialPushPending = true
        return
    end

    m_caiOpenPending = false
    m_caiTutorialPushDelay = false
    m_caiTutorialControlsReady = false
    m_caiTutorialPushPending = false
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
    m_caiTutorialPushDelay     = false
    m_caiTutorialControlsReady = false
    m_caiTutorialPushPending   = false
    m_caiInstanceByHash        = {}
end

local NativeOnOpenPanel = OnOpenPanel

local function OnTutorialResearchOpenCAI()
    m_caiTutorialPushDelay = true
    m_caiTutorialControlsReady = false
    m_caiTutorialPushPending = false
    NativeOnOpenPanel()
end

local function OnTutorialDetailedControlsReadyCAI()
    if not m_caiTutorialPushDelay then return end
    m_caiTutorialControlsReady = true
    if m_caiTutorialPushPending or m_caiOpenPending then
        PushPanelWhenReady()
    end
end

-- ===========================================================================
-- Wraps. View and AddAvailableResearch are called by global-name lookup from
-- inside the native file, so global re-binding takes effect for them.
-- OnInputHandler must be re-registered because Initialize captured the old
-- function reference. OnChooseResearch is wrapped only for selection
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

AddAvailableResearch = WrapFunc(AddAvailableResearch, function(orig, playerID, kData)
    local instance = orig(playerID, kData)
    if playerID ~= -1 then
        table.insert(m_caiRowData, kData)
        if kData and kData.Hash and instance then
            m_caiInstanceByHash[kData.Hash] = instance
        end
    end
    return instance
end)

RealizeCurrentResearch = WrapFunc(RealizeCurrentResearch, function(orig, playerID, kData, kControl)
    m_caiCurrentData = kData
    m_caiCurrentControl = kControl or Controls
    return orig(playerID, kData, kControl)
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

OnChooseResearch = WrapFunc(OnChooseResearch, function(orig, techHash)
    for _, kData in ipairs(m_caiRowData) do
        if kData.Hash == techHash then
            Speak(Locale.Lookup("LOC_HUD_RESEARCH_CHOSEN", kData.Name) or kData.Name)
            break
        end
    end
    return orig(techHash)
end)

-- Every native close path funnels through OnClosePanel (Escape via SlideAnimator,
-- Space via action binding, X button, LaunchBar_CloseChoosers, tech-pick auto-close).
-- The LuaEvent fires only after the slide animation — not reliable for Space —
-- so pop here to sync immediately. OnPanelClosedCAI is idempotent.
OnClosePanel = WrapFunc(OnClosePanel, function(orig)
    orig()
    OnPanelClosedCAI()
end)

LuaEvents.ResearchChooser_ForceHideWorldTracker.Add(OnPanelOpenedCAI)
LuaEvents.ResearchChooser_RestoreWorldTracker.Add(OnPanelClosedCAI)
LuaEvents.Tutorial_ResearchOpen.Remove(NativeOnOpenPanel)
LuaEvents.Tutorial_ResearchOpen.Add(OnTutorialResearchOpenCAI)
LuaEvents.CAI_TutorialDetailedControlsReady.Add(OnTutorialDetailedControlsReadyCAI)

-- Queue changes from vanilla surfaces (for example Tech Tree queue edits) that
-- don't also change the active research don't fire
-- Events.ResearchChanged, so the native Refresh/FlushChanges pipeline misses
-- them. Hook ResearchQueueChanged and call Refresh() — that calls GetData()
-- (which re-reads pPlayerTechs:GetResearchQueue()) and View(kData), which
-- our wrap then turns into RebuildCAIPanel.
if Events and Events.ResearchQueueChanged then
    Events.ResearchQueueChanged.Add(function()
        if m_caiPanel and mgr and mgr:HasWidget(m_caiPanel) and Refresh then
            Refresh()
        end
    end)
end
