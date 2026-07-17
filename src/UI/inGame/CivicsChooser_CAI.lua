include("caiUtils")
include("inGameHelpers_CAI")
include("ToolTipHelper")
include("Civ6Common")
include("CivicsChooser")

local mgr                 = ExposedMembers.CAI_UIManager

local PANEL_ID            = "CAICivicsChooser_Panel"
local QUEUE_TREE_ID       = "CAICivicsChooser_QueueTree"
local AVAILABLE_TREE_ID   = "CAICivicsChooser_AvailableTree"
local OPEN_TREE_BUTTON_ID = "CAICivicsChooser_OpenTreeButton"

local m_panel             = nil ---@type UIWidget|nil
local m_queueTree         = nil ---@type UIWidget|nil
local m_availableTree     = nil ---@type UIWidget|nil
local m_rowData           = {} ---@type table[]
local m_queueRows         = {} ---@type table[]
local m_availableRows     = {} ---@type table[]
local m_currentData       = nil ---@type table|nil
local m_currentControl    = nil ---@type table|nil
local m_instanceByHash    = {} ---@type table<number, table>
local m_modifierCache     = nil ---@type table|nil
local m_leadsToByType     = nil ---@type table<string, string[]>|nil
local m_openPending       = false

local function GetModifierCache()
    if not m_modifierCache and TechAndCivicSupport_BuildCivicModifierCache then
        m_modifierCache = TechAndCivicSupport_BuildCivicModifierCache()
    end
    return m_modifierCache or {}
end

-- ===========================================================================
-- Control helpers
-- ===========================================================================
local function ControlIsHidden(c)
    return c and c.IsHidden and c:IsHidden() or false
end

local function ControlIsDisabled(c)
    return c and c.IsDisabled and c:IsDisabled() or false
end

local function ControlText(c)
    if not c then return "" end
    if c.GetText then
        local t = c:GetText()
        if t and t ~= "" then return t end
    end
    return ""
end

local function GetChildren(c)
    if c and c.GetChildren then return c:GetChildren() or {} end
    return {}
end

local function InstanceFor(kData)
    if not kData or not kData.Hash then return nil end
    return m_instanceByHash[kData.Hash]
end

local function DisplayControl(kData)
    local inst = InstanceFor(kData)
    if inst then return inst end
    if kData and kData.IsCurrent then return m_currentControl or Controls end
    return nil
end

local function RowIsHidden(kData)
    local inst = InstanceFor(kData)
    if not inst then return false end
    return ControlIsHidden(inst.TopContainer) or ControlIsHidden(inst.Top)
end

local function RowIsDisabled(kData)
    local inst = InstanceFor(kData)
    if not inst then return false end
    return ControlIsDisabled(inst.Top)
end

-- ===========================================================================
-- Data extraction
-- ===========================================================================
local function HasQueuePosition(kData)
    if not kData or kData.IsCurrent then return false end
    local p = kData.ResearchQueuePosition
    return p ~= nil and p ~= -1 and p ~= 99
end

local function IsQueuedOrCurrent(kData)
    return kData.IsCurrent or HasQueuePosition(kData)
end

local function GetTurnsText(kData)
    local inst = DisplayControl(kData)
    if inst then
        local t = ControlText(inst.TurnsLeft)
        local n = string.match(t, "%[ICON_Turn%](%d+)")
        if n then return Locale.Lookup("LOC_CAI_RESEARCH_TURNS", tonumber(n)) end
        if t ~= "" then return t end
    end
    if kData.TurnsLeft and kData.TurnsLeft >= 0 then
        return Locale.Lookup("LOC_CAI_RESEARCH_TURNS", kData.TurnsLeft)
    end
    return nil
end

local function GetProgressText(kData)
    if not kData or not kData.Progress then return nil end
    local pct = math.floor(kData.Progress * 100 + 0.5)
    if pct <= 0 then return nil end
    return Locale.Lookup("LOC_CAI_CIVIC_PROGRESS", pct)
end

local function GetCostText(kData)
    local cost = kData.Cost
    if cost and cost > 0 then
        return Locale.Lookup("LOC_CAI_CIVIC_COST", cost)
    end
    return nil
end

local function GetDescriptionText(kData)
    local civicRow = kData.CivicType and GameInfo.Civics[kData.CivicType] or nil
    local desc = civicRow and civicRow.Description or nil
    if desc and desc ~= "" then
        local text = Locale.Lookup(desc)
        if text and text ~= "" then return text end
    end
    return nil
end

local function GetBoostText(kData)
    if not kData or not kData.Boostable then return nil end
    local trigger = kData.TriggerDesc and Locale.Lookup(kData.TriggerDesc) or ""
    local prefix = Locale.Lookup(kData.BoostTriggered and "LOC_BOOST_BOOSTED" or "LOC_BOOST_TO_BOOST")
    if trigger == "" then return prefix end
    return prefix .. " " .. trigger
end

local function GetUnlocksText(unlocks)
    if not unlocks or #unlocks == 0 then return nil end
    local names = {}
    for _, u in ipairs(unlocks) do table.insert(names, u.Name) end
    return Locale.Lookup("LOC_CAI_CIVIC_UNLOCKS_HEADER", table.concat(names, ", "))
end

local function GetObsoletesText(obsoleteNames)
    if not obsoleteNames or #obsoleteNames == 0 then return nil end
    return Locale.Lookup("LOC_CAI_CIVIC_OBSOLETES_HEADER", table.concat(obsoleteNames, ", "))
end

local function GetLeadsToText(kData)
    local civicType = kData and kData.CivicType
    if not civicType then return nil end

    if not m_leadsToByType then
        m_leadsToByType = {}
        for prereq in GameInfo.CivicPrereqs() do
            local leadsTo = m_leadsToByType[prereq.PrereqCivic]
            if not leadsTo then
                leadsTo = {}
                m_leadsToByType[prereq.PrereqCivic] = leadsTo
            end
            leadsTo[#leadsTo + 1] = prereq.Civic
        end
    end

    local localPlayer = Game.GetLocalPlayer()
    local player = localPlayer ~= PlayerTypes.NONE and Players[localPlayer] or nil
    local playerCulture = player and player:GetCulture() or nil
    local names = {}
    for _, targetType in ipairs(m_leadsToByType[civicType] or {}) do
        local civic = GameInfo.Civics[targetType]
        if civic then
            local isRevealed = not playerCulture or not playerCulture.IsCivicRevealed
                or playerCulture:IsCivicRevealed(civic.Index)
            names[#names + 1] = isRevealed and Locale.Lookup(civic.Name)
                or Locale.Lookup("LOC_CIVICS_TREE_NOT_REVEALED_CIVIC")
        end
    end
    if #names == 0 then return nil end
    return Locale.Lookup("LOC_CAI_CIVIC_LEADS_TO_HEADER", table.concat(names, ", "))
end

local function GetAwardNamesFor(kData)
    local civicType = kData and kData.CivicType
    if not civicType then return {} end
    return GetAwardNames(GetModifierCache()[civicType])
end

-- ===========================================================================
-- Row label + tooltip
-- ===========================================================================
local function FormatLabel(kData)
    local parts = {}
    if kData.IsCurrent then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_CIVIC_CURRENT", kData.Name))
    elseif HasQueuePosition(kData) then
        AppendIfNonEmpty(parts, kData.Name)
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_CIVIC_QUEUE_POSITION", kData.ResearchQueuePosition))
    else
        AppendIfNonEmpty(parts, kData.Name)
    end
    AppendIfNonEmpty(parts, GetRecommendedPart(kData, RowIsDisabled(kData)))
    return table.concat(parts, ", ")
end

local function FormatTooltip(kData, unlocks, obsoleteNames, awardNames)
    local parts = {}
    AppendIfNonEmpty(parts, GetCostText(kData))
    AppendIfNonEmpty(parts, GetTurnsText(kData))
    AppendIfNonEmpty(parts, GetProgressText(kData))
    AppendIfNonEmpty(parts, GetDescriptionText(kData))
    AppendIfNonEmpty(parts, GetBoostText(kData))
    AppendIfNonEmpty(parts, GetObsoletesText(obsoleteNames))
    AppendIfNonEmpty(parts, GetLeadsToText(kData))
    AppendIfNonEmpty(parts, GetUnlocksText(unlocks))
    AppendIfNonEmpty(parts, GetCivicAwardsText(awardNames))
    return table.concat(parts, "[NEWLINE]")
end

-- ===========================================================================
-- Row factory
-- ===========================================================================
local function CreateRow(kData, interactive)
    local unlocks = GetCivicUnlockObjects(kData)
    local obsoleteNames = GetObsoletePolicyNames(kData)
    local awardNames = GetAwardNamesFor(kData)

    local row = mgr:CreateWidget(mgr:GenerateWidgetId("CAICivicsChooserRow"), "TreeItem", {
        Label             = function() return FormatLabel(kData) end,
        Tooltip           = function() return FormatTooltip(kData, unlocks, obsoleteNames, awardNames) end,
        HiddenPredicate   = function() return RowIsHidden(kData) end,
        DisabledPredicate = function() return interactive and RowIsDisabled(kData) or false end,
        FocusKey          = "civic:" .. tostring(kData.Hash),
    })
    row:SetFocusSound("Main_Menu_Mouse_Over")

    if interactive then
        row:On("activate", function(w)
            if w:IsDisabled() then return end
            local inst = InstanceFor(kData)
            if inst and inst.Top and inst.Top.DoLeftClick then
                inst.Top:DoLeftClick()
            else
                OnChooseCivic(kData.Hash)
            end
        end)
    end

    row:AddInputBindings({
        {
            Key         = Keys.VK_RETURN,
            IsShift     = true,
            MSG         = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_OPEN_CIVILOPEDIA",
            Action      = function()
                if IsTutorialRunning and IsTutorialRunning() then return true end
                if kData.CivicType then LuaEvents.OpenCivilopedia(kData.CivicType) end
                return true
            end,
        },
    })

    for _, unlock in ipairs(unlocks) do
        if unlock.Description then
            row:AddChild(CreateUnlockChild(mgr, unlock, "CAICivicsChooserUnlock"))
        end
    end

    return row
end

-- ===========================================================================
-- Rebuild
-- ===========================================================================
local function RebuildTree(tree, rows, interactive)
    if not tree then return end
    local capture = mgr:CaptureFocusKey(tree)
    tree:ClearChildren()
    for _, kData in ipairs(rows) do
        tree:AddChild(CreateRow(kData, interactive))
    end
    mgr:RestoreFocus(tree, capture)
end

local function RebuildPanel()
    m_queueRows = {}
    m_availableRows = {}
    for _, kData in ipairs(m_rowData) do
        if IsQueuedOrCurrent(kData) then
            table.insert(m_queueRows, kData)
        else
            table.insert(m_availableRows, kData)
        end
    end
    table.sort(m_queueRows, function(a, b)
        if a.IsCurrent ~= b.IsCurrent then return a.IsCurrent == true end
        return (a.ResearchQueuePosition or 0) < (b.ResearchQueuePosition or 0)
    end)
    -- Vanilla View routes non-Repeatable current civic through
    -- RealizeCurrentCivic (not AddAvailableCivic), so it never lands in
    -- m_rowData. Our RealizeCurrentCivic wrap captures it; splice it in at
    -- the head of the queue.
    if m_currentData then
        local already = false
        for _, r in ipairs(m_queueRows) do
            if r.Hash == m_currentData.Hash then
                already = true
                break
            end
        end
        if not already then table.insert(m_queueRows, 1, m_currentData) end
    end

    RebuildTree(m_queueTree, m_queueRows, false)
    RebuildTree(m_availableTree, m_availableRows, true)

    if m_panel then
        m_panel.DefaultIndex = (#m_queueRows > 0) and 1 or 2
    end
end

-- ===========================================================================
-- Panel build
-- ===========================================================================
local function EnsurePanelBuilt()
    if m_panel then return end

    m_panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function() return ControlText(Controls.Title) end,
    })

    m_queueTree = mgr:CreateWidget(QUEUE_TREE_ID, "Tree", {
        Label           = function() return Locale.Lookup("LOC_CAI_CIVIC_QUEUE_LIST") end,
        HiddenPredicate = function() return #m_queueRows == 0 end,
        SearchDepth     = 0,
    })
    m_panel:AddChild(m_queueTree)

    m_availableTree = mgr:CreateWidget(AVAILABLE_TREE_ID, "Tree", {
        Label       = function() return Locale.Lookup("LOC_CAI_CIVIC_AVAILABLE_LIST") end,
        SearchDepth = 0,
    })
    m_panel:AddChild(m_availableTree)

    local treeBtn = mgr:CreateWidget(OPEN_TREE_BUTTON_ID, "Button", {
        Label             = function() return ControlText(Controls.OpenTreeButton) end,
        HiddenPredicate   = function() return ControlIsHidden(Controls.OpenTreeButton) end,
        DisabledPredicate = function() return ControlIsDisabled(Controls.OpenTreeButton) end,
    })
    treeBtn:SetFocusSound("Main_Menu_Mouse_Over")
    treeBtn:On("activate", function(w)
        if w:IsDisabled() then return end
        Controls.OpenTreeButton:DoLeftClick()
    end)
    m_panel:AddChild(treeBtn)

    RebuildPanel()
end

-- ===========================================================================
-- Lifecycle
-- ===========================================================================
local function PushPanelWhenReady()
    if not m_panel or not mgr then return end
    if mgr:GetWidgetById(PANEL_ID) then return end
    m_openPending = false

    local ePlayer = Game.GetLocalPlayer()
    local playerCulture = ePlayer and ePlayer ~= -1 and Players[ePlayer]:GetCulture() or nil
    local hasCurrent = playerCulture and playerCulture:GetProgressingCivic() ~= -1
    local focusChild = hasCurrent and m_queueTree or m_availableTree
    mgr:Push(m_panel, { focus = focusChild, priority = PopupPriority.Low })
end

local function OnPanelOpenedCAI()
    EnsurePanelBuilt()
    if mgr:GetWidgetById(PANEL_ID) then return end
    m_openPending = true
end

local function OnPanelClosedCAI()
    if mgr and m_panel then
        mgr:RemoveFromStack(PANEL_ID)
    end
    m_panel = nil
    m_queueTree = nil
    m_availableTree = nil
    m_rowData = {}
    m_queueRows = {}
    m_availableRows = {}
    m_currentData = nil
    m_currentControl = nil
    m_instanceByHash = {}
    m_modifierCache = nil
    m_openPending = false
end

-- ===========================================================================
-- Wraps
-- ===========================================================================
View = WrapFunc(View, function(orig, playerID, kData)
    m_rowData = {}
    m_currentData = nil
    m_currentControl = nil
    m_instanceByHash = {}
    orig(playerID, kData)
    RebuildPanel()
    if m_openPending then PushPanelWhenReady() end
end)

-- Vanilla AddAvailableCivic is void and doesn't expose its instance. The
-- vanilla InstanceManager appends exactly one container to Controls.CivicStack
-- per call, so the new child at beforeCount+1 is the instance for this kData.
AddAvailableCivic = WrapFunc(AddAvailableCivic, function(orig, playerID, kData)
    local stackChildren = GetChildren(Controls.CivicStack)
    local beforeCount = #stackChildren
    orig(playerID, kData)
    if playerID ~= -1 then
        table.insert(m_rowData, kData)
        if kData and kData.Hash then
            local after = GetChildren(Controls.CivicStack)
            local topContainer = after[beforeCount + 1] or after[#after]
            if topContainer then
                local children = GetChildren(topContainer)
                m_instanceByHash[kData.Hash] = {
                    TopContainer = topContainer,
                    Top = children[1] or topContainer,
                }
            end
        end
    end
end)

RealizeCurrentCivic = WrapFunc(RealizeCurrentCivic, function(orig, playerID, kData, kControl, cachedModifiers)
    m_currentData = kData
    m_currentControl = kControl or Controls
    return orig(playerID, kData, kControl, cachedModifiers)
end)

-- Returning true on mgr consume prevents WorldInput_CAI's wrapped handler
-- from re-firing mgr:HandleInput. Sync the slide animator if the input
-- triggered our panel teardown.
OnInputHandler = WrapFunc(OnInputHandler, function(orig, input)
    if mgr then
        local hadPanel = mgr:GetWidgetById(PANEL_ID) ~= nil
        if mgr:HandleInput(input) then
            if hadPanel and not mgr:GetWidgetById(PANEL_ID) then
                OnClosePanel()
            end
            return true
        end
    end
    return orig(input)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)

OnClosePanel = WrapFunc(OnClosePanel, function(orig)
    orig()
    OnPanelClosedCAI()
end)

LuaEvents.ResearchChooser_ForceHideWorldTracker.Add(OnPanelOpenedCAI)
LuaEvents.ResearchChooser_RestoreWorldTracker.Add(OnPanelClosedCAI)

-- Queue edits made elsewhere (e.g. Civics Tree) that don't also flip the
-- active civic don't fire Events.CivicChanged, so the native Refresh/FlushChanges
-- pipeline misses them.
if Events and Events.CivicQueueChanged then
    Events.CivicQueueChanged.Add(function()
        if m_panel and mgr and mgr:GetWidgetById(PANEL_ID) and Refresh then
            Refresh()
        end
    end)
end

-- Re-announce the focused row when its underlying civic state changes.
local function RefocusIfCivicRow()
    if not mgr or not m_panel or not mgr:GetWidgetById(PANEL_ID) then return end
    local focused = mgr:GetFocusedWidget()
    if focused and focused.FocusKey and string.sub(focused.FocusKey, 1, 6) == "civic:" then
        mgr:Refocus()
    end
end
if Events and Events.CivicChanged then Events.CivicChanged.Add(RefocusIfCivicRow) end
if Events and Events.CivicCompleted then Events.CivicCompleted.Add(RefocusIfCivicRow) end
if Events and Events.CultureYieldChanged then Events.CultureYieldChanged.Add(RefocusIfCivicRow) end
