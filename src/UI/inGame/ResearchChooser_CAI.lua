include("caiUtils")
include("ResearchChooser")
local mgr = ExposedMembers.CAI_UIManager

local TUTORIAL_MOD_ID   = "17462E0F-1EE1-4819-AAAA-052B5896B02A"
local UNLOCKS_INLINE    = 2

local m_caiPanel            = nil ---@type UIWidget|nil
local m_caiAvailableList    = nil ---@type UIWidget|nil
local m_caiAvailableDetail  = nil ---@type UIWidget|nil
local m_caiQueueList        = nil ---@type UIWidget|nil
local m_caiQueueDetail      = nil ---@type UIWidget|nil
local m_caiRowData          = {}  ---@type table<number, table>
local m_caiAvailableRows    = {}  ---@type table<number, table>
local m_caiQueueRows        = {}  ---@type table<number, table>
local m_caiCurrentData      = nil ---@type table|nil
local m_caiIsTutorial       = nil ---@type boolean|nil
local m_caiTutorialTechs    = nil ---@type table<number, number>|nil
local m_caiOpenPending      = false ---@type boolean

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

local function GetFirstNUnlockNames(kData, n)
    local names = GetUnlockNames(kData)
    local head = {}
    for i, name in ipairs(names) do
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
    if kData.IsLastCompleted and not kData.Repeatable then
        return Locale.Lookup("LOC_RESEARCH_CHOOSER_JUST_COMPLETED")
    end
    if kData.TurnsLeft and kData.TurnsLeft >= 0 then
        return Locale.Lookup("LOC_TURNS_REMAINING_VAL", kData.TurnsLeft)
    end
    return nil
end

local function FormatBoostPart(kData)
    if not kData.Boostable then return nil end
    if kData.BoostTriggered then
        return Locale.Lookup("LOC_TECH_HAS_BEEN_BOOSTED")
    end
    return Locale.Lookup("LOC_TECH_CAN_BE_BOOSTED")
end

local function FormatRowLabel(kData, inlineUnlocks)
    local parts = {}
    -- Current-research row gets the "Researching: {Name}" prefix and an inline
    -- progress % so the queue list's first row replaces what the old standalone
    -- summary StaticText used to announce.
    if kData.IsCurrent then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_RESEARCH_CURRENT", kData.Name))
    else
        AppendIfNonEmpty(parts, kData.Name)
    end
    if kData.IsRecommended then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_TECH_FILTER_RECOMMENDED"))
    end
    AppendIfNonEmpty(parts, FormatBoostPart(kData))
    if kData.ResearchCost and kData.ResearchCost > 0 then
        AppendIfNonEmpty(parts, kData.ResearchCost .. " " .. Locale.Lookup("LOC_YIELD_SCIENCE_NAME"))
    end
    if kData.IsCurrent and kData.Progress then
        local pct = math.floor((kData.Progress or 0) * 100 + 0.5)
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_RESEARCH_PROGRESS", pct))
    end
    AppendIfNonEmpty(parts, FormatTurnsPart(kData))
    if kData.ResearchQueuePosition and kData.ResearchQueuePosition ~= -1 then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_RESEARCH_QUEUE_POSITION", kData.ResearchQueuePosition))
    end
    for _, name in ipairs(inlineUnlocks) do
        AppendIfNonEmpty(parts, name)
    end
    return table.concat(parts, ", ")
end

-- ===========================================================================
-- Compose the detail text for the Edit widget. Sections are joined with blank
-- lines so arrow-through landings match sighted breaks. Sources:
--   1. kData.ToolTip (name, cost, description, unlocks) from ToolTipHelper.
--   2. Boost line — ToolTipHelper does NOT include boost info; sighted get
--      this via the BoostLabel + boost icon tooltip next to the tech. Built
--      to match the sighted icon tooltip: "Can/Has been boosted: <trigger>".
--   3. Live status (IsCurrent progress/turns, queue position).
-- [NEWLINE] tokens are left in the composed string; SetEditBoxText converts
-- them to real newline characters when it pushes the buffer.
-- ===========================================================================
local function ComposeDetail(kData)
    if not kData then return "" end
    local sections = {}

    local tip = kData.ToolTip or ""
    if tip ~= "" then table.insert(sections, tip) end

    if kData.Boostable and kData.TriggerDesc then
        local label = kData.BoostTriggered
            and Locale.Lookup("LOC_TECH_HAS_BEEN_BOOSTED")
            or Locale.Lookup("LOC_TECH_CAN_BE_BOOSTED")
        local trigger = Locale.Lookup(kData.TriggerDesc)
        table.insert(sections, label .. ": " .. trigger)
    end

    local statusParts = {}
    if kData.IsCurrent then
        table.insert(statusParts, Locale.Lookup("LOC_CAI_RESEARCH_CURRENT_STATUS"))
        local pct = math.floor((kData.Progress or 0) * 100 + 0.5)
        table.insert(statusParts, Locale.Lookup("LOC_CAI_RESEARCH_PROGRESS", pct))
        if kData.TurnsLeft and kData.TurnsLeft >= 0 then
            table.insert(statusParts, Locale.Lookup("LOC_TURNS_REMAINING_VAL", kData.TurnsLeft))
        end
    end
    if kData.ResearchQueuePosition and kData.ResearchQueuePosition ~= -1 then
        table.insert(statusParts, Locale.Lookup("LOC_CAI_RESEARCH_QUEUE_POSITION", kData.ResearchQueuePosition))
    end
    if #statusParts > 0 then
        table.insert(sections, table.concat(statusParts, ", "))
    end

    return table.concat(sections, "[NEWLINE][NEWLINE]")
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
-- Row factory. `interactive` true = available list: Enter chooses research.
-- `interactive` false = queue list: Enter is a no-op (the queue is view-only).
-- OnFocusEnter always updates the companion detail Edit.
-- ===========================================================================
local function CreateRowWidget(kData, detailEdit, interactive)
    local captured = kData
    local inline = GetFirstNUnlockNames(captured, UNLOCKS_INLINE)

    local row = mgr:CreateUIWidget("Button", {
        GetLabel = function() return FormatRowLabel(captured, inline) end,
        OnClick = interactive
            and function() OnChooseResearch(captured.Hash) end
            or  function() end,
        OnFocusEnter = function()
            UI.PlaySound("Main_Menu_Mouse_Over")
            if detailEdit then
                mgr.WidgetTemplateHelpers:SetEditBoxText(detailEdit, ComposeDetail(captured))
            end
        end,
    })
    row._caiHash = captured.Hash
    return row
end

-- ===========================================================================
-- Rebuild one list's children from its row table and seed the companion
-- detail Edit with the first row's details.
-- ===========================================================================
local function RebuildOneList(listWidget, rows, detailEdit, interactive)
    if not listWidget then return end
    listWidget:ClearChildren()
    for _, kData in ipairs(rows) do
        listWidget:AddChild(CreateRowWidget(kData, detailEdit, interactive))
    end
    if detailEdit then
        mgr.WidgetTemplateHelpers:SetEditBoxText(detailEdit,
            rows[1] and ComposeDetail(rows[1]) or "")
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
            if row.Hash == m_caiCurrentData.Hash then already = true break end
        end
        if not already then
            table.insert(m_caiQueueRows, 1, m_caiCurrentData)
        end
    end

    RebuildOneList(m_caiAvailableList, m_caiAvailableRows, m_caiAvailableDetail, true)
    RebuildOneList(m_caiQueueList,     m_caiQueueRows,     m_caiQueueDetail,     false)
end

-- ===========================================================================
-- Build the static panel scaffolding once. List contents are filled by
-- RebuildCAIPanel() each time the native View() runs.
-- ===========================================================================
local function EnsurePanelBuilt()
    if m_caiPanel then return end

    m_caiPanel = mgr:CreateUIWidget("Panel", {
        GetLabel = function() return Controls.Title:GetText() end,
    })

    m_caiAvailableList = mgr:CreateUIWidget("List", {
        GetLabel = function() return Locale.Lookup("LOC_CAI_RESEARCH_AVAILABLE_LIST") end,
    })
    m_caiPanel:AddChild(m_caiAvailableList)

    m_caiAvailableDetail = mgr:CreateUIWidget("Edit", {
        GetLabel = function() return Locale.Lookup("LOC_CAI_RESEARCH_AVAILABLE_DETAILS") end,
        GetValue = function() return m_caiAvailableDetail and m_caiAvailableDetail.EditBuffer or "" end,
        AlwaysEdit = true,
        EditReadOnly = true,
        HighlightOnEdit = false,
        EditBuffer = "",
    })
    m_caiPanel:AddChild(m_caiAvailableDetail)

    -- Queue list + detail are hidden when nothing is researching and the
    -- queue is empty (early game), so Tab-order doesn't hit dead widgets.
    m_caiQueueList = mgr:CreateUIWidget("List", {
        GetLabel = function() return Locale.Lookup("LOC_CAI_RESEARCH_QUEUE_LIST") end,
        IsHidden = function() return #m_caiQueueRows == 0 end,
    })
    m_caiPanel:AddChild(m_caiQueueList)

    m_caiQueueDetail = mgr:CreateUIWidget("Edit", {
        GetLabel = function() return Locale.Lookup("LOC_CAI_RESEARCH_QUEUE_DETAILS") end,
        GetValue = function() return m_caiQueueDetail and m_caiQueueDetail.EditBuffer or "" end,
        IsHidden = function() return #m_caiQueueRows == 0 end,
        AlwaysEdit = true,
        EditReadOnly = true,
        HighlightOnEdit = false,
        EditBuffer = "",
    })
    m_caiPanel:AddChild(m_caiQueueDetail)

    if not Controls.OpenTreeButton:IsHidden() then
        local treeBtn = mgr:CreateUIWidget("Button", {
            GetLabel = function() return Controls.OpenTreeButton:GetText() end,
            OnClick = function()
                LuaEvents.ResearchChooser_RaiseTechTree()
                OnClosePanel()
            end,
        })
        m_caiPanel:AddChild(treeBtn)
    end

    local closeBtn = mgr:CreateUIWidget("Button", {
        GetLabel = function() return Controls.CloseButton:GetToolTipString() or "Close" end,
        OnClick = function() OnClosePanel() end,
    })
    m_caiPanel:AddChild(closeBtn)

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

local function OnPanelClosedCAI()
    if m_caiPanel and mgr:HasWidget(m_caiPanel) then
        mgr:Pop()
    end
    -- Null out so next open rebuilds; mgr:Pop destroys children and detaches
    -- the panel, making it unusable for a subsequent push.
    m_caiPanel           = nil
    m_caiAvailableList   = nil
    m_caiAvailableDetail = nil
    m_caiQueueList       = nil
    m_caiQueueDetail     = nil
    m_caiRowData         = {}
    m_caiAvailableRows   = {}
    m_caiQueueRows       = {}
    m_caiCurrentData     = nil
    m_caiOpenPending     = false
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
    orig(playerID, kData)
    RebuildCAIPanel()
    -- Initial open: OnPanelOpenedCAI set m_caiOpenPending but deferred the
    -- Push. Now that the list has its real rows, let the UI screen manager
    -- choose the initial focus path.
    if m_caiOpenPending and m_caiPanel and mgr and not mgr:HasWidget(m_caiPanel) then
        m_caiOpenPending = false
        mgr:Push(m_caiPanel)
    end
end)

AddAvailableResearch = WrapFunc(AddAvailableResearch, function(orig, playerID, kData)
    local instance = orig(playerID, kData)
    if playerID ~= -1 then
        table.insert(m_caiRowData, kData)
    end
    return instance
end)

RealizeCurrentResearch = WrapFunc(RealizeCurrentResearch, function(orig, playerID, kData, kControl)
    m_caiCurrentData = kData
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
