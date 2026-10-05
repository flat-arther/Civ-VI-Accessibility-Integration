include("CAIResearchData")
include("CAIResearchChooser")
include("CAIControl")
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
local rowControls = CAIResearchChooser.CreateControls(
    function() return m_instanceByHash end,
    function() return m_currentControl or Controls end)

local function GetChildren(c)
    if c and c.GetChildren then return c:GetChildren() or {} end
    return {}
end

-- ===========================================================================
-- Data extraction
-- ===========================================================================

-- Progress-aware remaining turns for the active civic. Vanilla fills the row
-- control (and kData.TurnsLeft) from GetTurnsToProgressCivic, a from-scratch
-- estimate that runs one turn high near completion; its own civics tree uses
-- GetTurnsLeft for the current item, so we do the same.
local function GetCurrentTurnsLeft()
    local ePlayer = Game.GetLocalPlayer()
    local culture = ePlayer and ePlayer ~= -1 and Players[ePlayer]:GetCulture() or nil
    return culture and culture:GetTurnsLeft() or nil
end

local function GetUnlocksText(unlocks)
    if not unlocks or #unlocks == 0 then return nil end
    local names = {}
    for _, u in ipairs(unlocks) do table.insert(names, u.Name) end
    return Locale.Lookup("LOC_CAI_CIVIC_UNLOCKS_HEADER", table.concat(names, "[NEWLINE]"))
end

local function GetObsoletesText(obsoleteNames)
    if not obsoleteNames or #obsoleteNames == 0 then return nil end
    return Locale.Lookup("LOC_CAI_CIVIC_OBSOLETES_HEADER", table.concat(obsoleteNames, "[NEWLINE]"))
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
    return Locale.Lookup("LOC_CAI_CIVIC_LEADS_TO_HEADER", table.concat(names, "[NEWLINE]"))
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
        CAIText.AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_CIVIC_CURRENT", kData.Name))
    elseif CAIResearchChooser.IsJustCompleted(kData) then
        CAIText.AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_CIVIC_JUST_COMPLETED", kData.Name))
    elseif CAIResearchChooser.HasQueuePosition(kData) then
        CAIText.AppendIfNonEmpty(parts, kData.Name)
        CAIText.AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_CIVIC_QUEUE_POSITION", kData.ResearchQueuePosition))
    else
        CAIText.AppendIfNonEmpty(parts, kData.Name)
    end
    CAIText.AppendIfNonEmpty(parts, GetRecommendedPart(kData, rowControls.RowIsDisabled(kData)))
    return table.concat(parts, "[NEWLINE]")
end

local function FormatTooltip(kData, unlocks, obsoleteNames, awardNames)
    local parts = {}
    CAIText.AppendIfNonEmpty(parts, CAIResearchData.CostText(kData.Cost, "LOC_CAI_CIVIC_COST"))
    CAIText.AppendIfNonEmpty(parts, CAIResearchChooser.GetTurnsText(kData, GetCurrentTurnsLeft, rowControls.DisplayControl))
    CAIText.AppendIfNonEmpty(parts, CAIResearchData.ProgressText(kData.Progress, "LOC_CAI_CIVIC_PROGRESS"))
    CAIText.AppendIfNonEmpty(parts, CAIResearchData.DescriptionText(kData.CivicType and GameInfo.Civics[kData.CivicType]))
    CAIText.AppendIfNonEmpty(parts, CAIResearchChooser.GetBoostText(kData))
    CAIText.AppendIfNonEmpty(parts, GetObsoletesText(obsoleteNames))
    CAIText.AppendIfNonEmpty(parts, GetLeadsToText(kData))
    CAIText.AppendIfNonEmpty(parts, GetUnlocksText(unlocks))
    CAIText.AppendIfNonEmpty(parts, GetCivicAwardsText(awardNames))
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
        HiddenPredicate   = function() return rowControls.RowIsHidden(kData) end,
        DisabledPredicate = function() return interactive and rowControls.RowIsDisabled(kData) or false end,
        FocusKey          = "civic:" .. tostring(kData.Hash),
    })
    row:SetFocusSound("Main_Menu_Mouse_Over")

    if interactive then
        row:On("activate", function(w)
            if w:IsDisabled() then return end
            local inst = rowControls.InstanceFor(kData)
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

local function RebuildPanel()
    m_queueRows, m_availableRows = CAIResearchChooser.PartitionRows(m_rowData, m_currentData)
    CAIResearchChooser.RebuildTree(mgr, m_queueTree, m_queueRows, false, CreateRow)
    CAIResearchChooser.RebuildTree(mgr, m_availableTree, m_availableRows, true, CreateRow)
end

-- ===========================================================================
-- Panel build
-- ===========================================================================
local function EnsurePanelBuilt()
    if m_panel then return end

    m_panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function() return CAIControl.Text(Controls.Title) end,
    })

    m_availableTree = mgr:CreateWidget(AVAILABLE_TREE_ID, "Tree", {
        Label       = function() return Locale.Lookup("LOC_CAI_CIVIC_AVAILABLE_LIST") end,
        SearchDepth = 0,
    })
    m_panel:AddChild(m_availableTree)

    m_queueTree = mgr:CreateWidget(QUEUE_TREE_ID, "Tree", {
        Label           = function() return Locale.Lookup("LOC_CAI_CIVIC_QUEUE_LIST") end,
        HiddenPredicate = function() return #m_queueRows == 0 end,
        SearchDepth     = 0,
    })
    m_panel:AddChild(m_queueTree)

    local treeBtn = mgr:CreateWidget(OPEN_TREE_BUTTON_ID, "Button", {
        Label             = function() return CAIControl.Text(Controls.OpenTreeButton) end,
        HiddenPredicate   = function() return CAIControl.IsHidden(Controls.OpenTreeButton) end,
        DisabledPredicate = function()
            return CAIControl.IsDisabled(Controls.OpenTreeButton)
                or not IsCAITutorialControlAllowed("OpenTreeButton")
        end,
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

    mgr:Push(m_panel, { priority = PopupPriority.Low })
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
    if IsCAIEscapeKeyUp(input) and not IsCAITutorialScreenCloseAllowed() then
        AnnounceCAITutorialScreenCloseBlocked()
        return true
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
