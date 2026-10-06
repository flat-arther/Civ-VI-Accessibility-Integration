include("CAIModSupport")
include("CAIResearchData")
include("CAIResearchChooser")
include("CAIControl")
include("caiUtils")
include("inGameHelpers_CAI")
include("ToolTipHelper")
include("Civ6Common")

-- Expansion-aware include chain. The XP1 and XP2 replacement files are
-- byte-identical; both wrap View/AddAvailableResearch/RealizeCurrentResearch
-- to populate kControl.Alliance / kControl.AllianceIcon for the active player.
if IsExpansion2Active and IsExpansion2Active() then
    include("ResearchChooser_Expansion1")
elseif IsExpansion1Active and IsExpansion1Active() then
    include("ResearchChooser_Expansion1")
else
    include("ResearchChooser")
end

local mgr                     = CAI:GetUIManager()

local PANEL_ID                = "CAIResearchChooser_Panel"
local QUEUE_TREE_ID           = "CAIResearchChooser_QueueTree"
local AVAILABLE_TREE_ID       = "CAIResearchChooser_AvailableTree"
local OPEN_TREE_BUTTON_ID     = "CAIResearchChooser_OpenTreeButton"

local m_panel                 = nil ---@type UIWidget|nil
local m_queueTree             = nil ---@type UIWidget|nil
local m_availableTree         = nil ---@type UIWidget|nil
local m_rowData               = {} ---@type table[]
local m_queueRows             = {} ---@type table[]
local m_availableRows         = {} ---@type table[]
local m_currentData           = nil ---@type table|nil
local m_currentControl        = nil ---@type table|nil
local m_instanceByHash        = {} ---@type table<number, table>
local m_leadsToByType         = nil ---@type table<string, string[]>|nil
local m_openPending           = false
local m_isTutorial            = nil ---@type boolean|nil
local m_tutorialTechs         = nil ---@type table<number, number>|nil
local m_tutorialPushDelay     = false
local m_tutorialControlsReady = false
local m_tutorialPushPending   = false

-- ===========================================================================
-- Tutorial detection (vanilla's m_isTutorial / TUTORIAL_TECHS are file-local)
-- ===========================================================================
local function IsCAITutorial()
    if m_isTutorial ~= nil then return m_isTutorial end
    m_isTutorial = CAIModSupport.IsTutorialActive()
    return m_isTutorial
end

local function GetTutorialTechHashes()
    if m_tutorialTechs then return m_tutorialTechs end
    m_tutorialTechs = {
        [2] = UITutorialManager:GetHash("TECH_MINING"),
        [3] = UITutorialManager:GetHash("TECH_IRRIGATION"),
        [4] = UITutorialManager:GetHash("TECH_POTTERY"),
    }
    return m_tutorialTechs
end

local function ReorderForTutorial(rowData)
    if not IsCAITutorial() then return end
    local targets = GetTutorialTechHashes()
    for targetIdx, techHash in pairs(targets) do
        for i, kData in ipairs(rowData) do
            if kData.Hash == techHash and i ~= targetIdx then
                table.remove(rowData, i)
                table.insert(rowData, math.min(targetIdx, #rowData + 1), kData)
                break
            end
        end
    end
end

-- ===========================================================================
-- Control helpers
-- ===========================================================================
local rowControls = CAIResearchChooser.CreateControls(
    function() return m_instanceByHash end,
    function() return m_currentControl or Controls end)

-- ===========================================================================
-- Data extraction
-- ===========================================================================

-- Progress-aware remaining turns for the active research. Vanilla fills the row
-- control (and kData.TurnsLeft) from GetTurnsToResearch, a from-scratch estimate
-- that runs one turn high near completion; its own tech tree uses GetTurnsLeft
-- for the current item, so we do the same.
local function GetCurrentTurnsLeft()
    local ePlayer = Game.GetLocalPlayer()
    local techs = ePlayer and ePlayer ~= -1 and Players[ePlayer]:GetTechs() or nil
    return techs and techs:GetTurnsLeft() or nil
end

local function GetAllianceText(kData)
    local inst = rowControls.InstanceFor(kData) or (kData.IsCurrent and (m_currentControl or Controls)) or nil
    if not inst or not inst.Alliance or not inst.AllianceIcon then return nil end
    if CAIControl.IsHidden(inst.Alliance) then return nil end
    local tip = CAIText.NormalizeFormattedText(CAIControl.Tooltip(inst.AllianceIcon))
    if tip == "" then return nil end
    return Locale.Lookup("LOC_CAI_RESEARCH_ALLIANCE_BONUS", tip)
end

local function GetLeadsToText(kData)
    local techType = kData and kData.TechType
    if not techType then return nil end

    if not m_leadsToByType then
        m_leadsToByType = {}
        for prereq in GameInfo.TechnologyPrereqs() do
            local leadsTo = m_leadsToByType[prereq.PrereqTech]
            if not leadsTo then
                leadsTo = {}
                m_leadsToByType[prereq.PrereqTech] = leadsTo
            end
            leadsTo[#leadsTo + 1] = prereq.Technology
        end
    end

    local localPlayer = Game.GetLocalPlayer()
    local player = localPlayer ~= PlayerTypes.NONE and Players[localPlayer] or nil
    local playerTechs = player and player:GetTechs() or nil
    local names = {}
    for _, targetType in ipairs(m_leadsToByType[techType] or {}) do
        local tech = GameInfo.Technologies[targetType]
        if tech then
            local isRevealed = not playerTechs or not playerTechs.IsTechRevealed
                or playerTechs:IsTechRevealed(tech.Index)
            names[#names + 1] = isRevealed and Locale.Lookup(tech.Name)
                or Locale.Lookup("LOC_TECH_TREE_NOT_REVEALED_TECH")
        end
    end
    if #names == 0 then return nil end
    return Locale.Lookup("LOC_CAI_RESEARCH_LEADS_TO_HEADER", table.concat(names, "[NEWLINE]"))
end

local function GetRevealsText(group)
    local reveals = group and group.Reveals or nil
    if not reveals or #reveals == 0 then return nil end
    local entries = {}
    for _, r in ipairs(reveals) do
        table.insert(entries, Locale.Lookup("LOC_TOOLTIP_UNLOCKS_RESOURCE", r.Name))
    end
    return table.concat(entries, "[NEWLINE]")
end

local function GetUnlocksText(group)
    local unlocks = group and group.Unlocks or nil
    if not unlocks or #unlocks == 0 then return nil end
    local names = {}
    for _, u in ipairs(unlocks) do table.insert(names, u.Name) end
    return Locale.Lookup("LOC_CAI_RESEARCH_UNLOCKS_HEADER", table.concat(names, "[NEWLINE]"))
end

-- ===========================================================================
-- Row label + tooltip
-- ===========================================================================
local function FormatLabel(kData)
    local parts = {}
    if kData.IsCurrent then
        CAIText.AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_RESEARCH_CURRENT", kData.Name))
    elseif CAIResearchChooser.IsJustCompleted(kData) then
        CAIText.AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_RESEARCH_JUST_COMPLETED", kData.Name))
    elseif CAIResearchChooser.HasQueuePosition(kData) then
        CAIText.AppendIfNonEmpty(parts, kData.Name)
        CAIText.AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_RESEARCH_QUEUED", kData.ResearchQueuePosition))
    else
        CAIText.AppendIfNonEmpty(parts, kData.Name)
    end
    CAIText.AppendIfNonEmpty(parts, GetRecommendedPart(kData, rowControls.RowIsDisabled(kData)))
    return table.concat(parts, "[NEWLINE]")
end

local function FormatTooltip(kData, group)
    local parts = {}
    CAIText.AppendIfNonEmpty(parts, CAIResearchData.CostText(kData.ResearchCost or kData.Cost, "LOC_CAI_RESEARCH_COST"))
    CAIText.AppendIfNonEmpty(parts, CAIResearchChooser.GetTurnsText(kData, GetCurrentTurnsLeft, rowControls.DisplayControl))
    CAIText.AppendIfNonEmpty(parts, CAIResearchData.ProgressText(kData.Progress, "LOC_CAI_RESEARCH_PROGRESS"))
    CAIText.AppendIfNonEmpty(parts, CAIResearchData.DescriptionText(kData.TechType and GameInfo.Technologies[kData.TechType]))
    CAIText.AppendIfNonEmpty(parts, CAIResearchChooser.GetBoostText(kData))
    CAIText.AppendIfNonEmpty(parts, GetAllianceText(kData))
    CAIText.AppendIfNonEmpty(parts, GetLeadsToText(kData))
    CAIText.AppendIfNonEmpty(parts, GetRevealsText(group))
    CAIText.AppendIfNonEmpty(parts, GetUnlocksText(group))
    return table.concat(parts, "[NEWLINE]")
end

-- ===========================================================================
-- Row factory
-- ===========================================================================
local function CreateRow(kData, interactive)
    local group = GetTechUnlockObjects(kData)

    local row = mgr:CreateWidget(mgr:GenerateWidgetId("CAIResearchChooserRow"), "TreeItem", {
        Label             = function() return FormatLabel(kData) end,
        Tooltip           = function() return FormatTooltip(kData, group) end,
        HiddenPredicate   = function() return rowControls.RowIsHidden(kData) end,
        DisabledPredicate = function() return interactive and rowControls.RowIsDisabled(kData) or false end,
        FocusKey          = "tech:" .. tostring(kData.Hash),
    })
    row:SetFocusSound("Main_Menu_Mouse_Over")

    if interactive then
        row:On("activate", function(w)
            if w:IsDisabled() then return end
            local inst = rowControls.InstanceFor(kData)
            if inst and inst.Top and inst.Top.DoLeftClick then
                inst.Top:DoLeftClick()
            else
                OnChooseResearch(kData.Hash)
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
                if kData.TechType then LuaEvents.OpenCivilopedia(kData.TechType) end
                return true
            end,
        },
    })

    for _, unlock in ipairs(group.Unlocks) do
        if unlock.Description then
            row:AddChild(CreateUnlockChild(mgr, unlock, "CAIResearchChooserUnlock"))
        end
    end

    return row
end

-- ===========================================================================
-- Rebuild
-- ===========================================================================

local function RebuildPanel()
    m_queueRows, m_availableRows = CAIResearchChooser.PartitionRows(m_rowData, m_currentData)
    ReorderForTutorial(m_availableRows)
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
        Label       = function() return Locale.Lookup("LOC_CAI_RESEARCH_AVAILABLE_LIST") end,
        SearchDepth = 0,
    })
    m_panel:AddChild(m_availableTree)

    m_queueTree = mgr:CreateWidget(QUEUE_TREE_ID, "Tree", {
        Label           = function() return Locale.Lookup("LOC_CAI_RESEARCH_QUEUE_LIST") end,
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

    if m_tutorialPushDelay and not m_tutorialControlsReady then
        m_openPending = false
        m_tutorialPushPending = true
        return
    end

    m_openPending = false
    m_tutorialPushDelay = false
    m_tutorialControlsReady = false
    m_tutorialPushPending = false

    mgr:Push(m_panel, { priority = 99 })
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
    m_openPending = false
    m_tutorialPushDelay = false
    m_tutorialControlsReady = false
    m_tutorialPushPending = false
end

-- ===========================================================================
-- Wraps
-- ===========================================================================
local NativeOnOpenPanel = OnOpenPanel

local function OnTutorialResearchOpenCAI()
    m_tutorialPushDelay = true
    m_tutorialControlsReady = false
    m_tutorialPushPending = false
    NativeOnOpenPanel()
end

local function OnTutorialDetailedControlsReadyCAI()
    if not m_tutorialPushDelay then return end
    m_tutorialControlsReady = true
    if m_tutorialPushPending or m_openPending then
        PushPanelWhenReady()
    end
end

View = WrapFunc(View, function(orig, playerID, kData)
    m_rowData = {}
    m_currentData = nil
    m_currentControl = nil
    m_instanceByHash = {}
    orig(playerID, kData)
    RebuildPanel()
    if m_openPending then PushPanelWhenReady() end
end)

AddAvailableResearch = WrapFunc(AddAvailableResearch, function(orig, playerID, kData)
    local instance = orig(playerID, kData)
    if playerID ~= -1 then
        table.insert(m_rowData, kData)
        if kData and kData.Hash and instance then
            m_instanceByHash[kData.Hash] = instance
        end
    end
    return instance
end)

RealizeCurrentResearch = WrapFunc(RealizeCurrentResearch, function(orig, playerID, kData, kControl)
    m_currentData = kData
    m_currentControl = kControl or Controls
    return orig(playerID, kData, kControl)
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
LuaEvents.Tutorial_ResearchOpen.Remove(NativeOnOpenPanel)
LuaEvents.Tutorial_ResearchOpen.Add(OnTutorialResearchOpenCAI)
LuaEvents.CAI_TutorialDetailedControlsReady.Add(OnTutorialDetailedControlsReadyCAI)

-- Queue edits made elsewhere (e.g. Tech Tree) that don't also flip the
-- active research don't fire Events.ResearchChanged, so the native
-- Refresh/FlushChanges pipeline misses them.
if Events and Events.ResearchQueueChanged then
    Events.ResearchQueueChanged.Add(function()
        if m_panel and mgr and mgr:GetWidgetById(PANEL_ID) and Refresh then
            Refresh()
        end
    end)
end

-- Re-announce the focused row when its underlying tech state changes.
local function RefocusIfTechRow()
    if not mgr or not m_panel or not mgr:GetWidgetById(PANEL_ID) then return end
    local focused = mgr:GetFocusedWidget()
    if focused and focused.FocusKey and string.sub(focused.FocusKey, 1, 5) == "tech:" then
        mgr:Refocus()
    end
end
if Events and Events.ResearchChanged then Events.ResearchChanged.Add(RefocusIfTechRow) end
if Events and Events.ResearchCompleted then Events.ResearchCompleted.Add(RefocusIfTechRow) end
