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

local mgr                     = ExposedMembers.CAI_UIManager

local PANEL_ID                = "CAIResearchChooser_Panel"
local QUEUE_TREE_ID           = "CAIResearchChooser_QueueTree"
local AVAILABLE_TREE_ID       = "CAIResearchChooser_AvailableTree"
local OPEN_TREE_BUTTON_ID     = "CAIResearchChooser_OpenTreeButton"

local TUTORIAL_MOD_ID         = "17462E0F-1EE1-4819-AAAA-052B5896B02A"

local m_panel                 = nil ---@type UIWidget|nil
local m_queueTree             = nil ---@type UIWidget|nil
local m_availableTree         = nil ---@type UIWidget|nil
local m_rowData               = {} ---@type table[]
local m_queueRows             = {} ---@type table[]
local m_availableRows         = {} ---@type table[]
local m_currentData           = nil ---@type table|nil
local m_currentControl        = nil ---@type table|nil
local m_instanceByHash        = {} ---@type table<number, table>
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
    m_isTutorial = false
    for _, v in ipairs(Modding.GetActiveMods()) do
        if v.Id == TUTORIAL_MOD_ID then
            m_isTutorial = true
            break
        end
    end
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

local function ControlTooltip(c)
    if c and c.GetToolTipString then
        local t = c:GetToolTipString()
        if t and t ~= "" then return t end
    end
    return ""
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
    return Locale.Lookup("LOC_CAI_RESEARCH_PROGRESS", pct)
end

local function GetCostText(kData)
    local cost = kData.ResearchCost or kData.Cost
    if cost and cost > 0 then
        return Locale.Lookup("LOC_CAI_RESEARCH_COST", cost)
    end
    return nil
end

local function GetDescriptionText(kData)
    local techRow = kData.TechType and GameInfo.Technologies[kData.TechType] or nil
    local desc = techRow and techRow.Description or nil
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

local function GetAllianceText(kData)
    local inst = InstanceFor(kData) or (kData.IsCurrent and (m_currentControl or Controls)) or nil
    if not inst or not inst.Alliance or not inst.AllianceIcon then return nil end
    if ControlIsHidden(inst.Alliance) then return nil end
    local tip = NormalizeFormattedText(ControlTooltip(inst.AllianceIcon))
    if tip == "" then return nil end
    return Locale.Lookup("LOC_CAI_RESEARCH_ALLIANCE_BONUS", tip)
end

local function GetRevealsText(group)
    local reveals = group and group.Reveals or nil
    if not reveals or #reveals == 0 then return nil end
    local entries = {}
    for _, r in ipairs(reveals) do
        table.insert(entries, Locale.Lookup("LOC_TOOLTIP_UNLOCKS_RESOURCE", r.Name))
    end
    return table.concat(entries, ", ")
end

local function GetUnlocksText(group)
    local unlocks = group and group.Unlocks or nil
    if not unlocks or #unlocks == 0 then return nil end
    local names = {}
    for _, u in ipairs(unlocks) do table.insert(names, u.Name) end
    return Locale.Lookup("LOC_CAI_RESEARCH_UNLOCKS_HEADER", table.concat(names, ", "))
end

-- ===========================================================================
-- Row label + tooltip
-- ===========================================================================
local function FormatLabel(kData)
    local parts = {}
    if kData.IsCurrent then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_RESEARCH_CURRENT", kData.Name))
    elseif HasQueuePosition(kData) then
        AppendIfNonEmpty(parts, kData.Name)
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_RESEARCH_QUEUED", kData.ResearchQueuePosition))
    else
        AppendIfNonEmpty(parts, kData.Name)
    end
    AppendIfNonEmpty(parts, GetRecommendedPart(kData, RowIsDisabled(kData)))
    return table.concat(parts, ", ")
end

local function FormatTooltip(kData, group)
    local parts = {}
    AppendIfNonEmpty(parts, GetCostText(kData))
    AppendIfNonEmpty(parts, GetTurnsText(kData))
    AppendIfNonEmpty(parts, GetProgressText(kData))
    AppendIfNonEmpty(parts, GetDescriptionText(kData))
    AppendIfNonEmpty(parts, GetBoostText(kData))
    AppendIfNonEmpty(parts, GetAllianceText(kData))
    AppendIfNonEmpty(parts, GetRevealsText(group))
    AppendIfNonEmpty(parts, GetUnlocksText(group))
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
        HiddenPredicate   = function() return RowIsHidden(kData) end,
        DisabledPredicate = function() return interactive and RowIsDisabled(kData) or false end,
        FocusKey          = "tech:" .. tostring(kData.Hash),
    })
    row:SetFocusSound("Main_Menu_Mouse_Over")

    if interactive then
        row:On("activate", function(w)
            if w:IsDisabled() then return end
            local inst = InstanceFor(kData)
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
    ReorderForTutorial(m_availableRows)
    table.sort(m_queueRows, function(a, b)
        if a.IsCurrent ~= b.IsCurrent then return a.IsCurrent == true end
        return (a.ResearchQueuePosition or 0) < (b.ResearchQueuePosition or 0)
    end)
    -- Vanilla View routes non-Repeatable current research through
    -- RealizeCurrentResearch (not AddAvailableResearch), so it never lands
    -- in m_rowData. Our RealizeCurrentResearch wrap captures it; splice
    -- in at the head of the queue.
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
        Label           = function() return Locale.Lookup("LOC_CAI_RESEARCH_QUEUE_LIST") end,
        HiddenPredicate = function() return #m_queueRows == 0 end,
        SearchDepth     = 0,
    })
    m_panel:AddChild(m_queueTree)

    m_availableTree = mgr:CreateWidget(AVAILABLE_TREE_ID, "Tree", {
        Label       = function() return Locale.Lookup("LOC_CAI_RESEARCH_AVAILABLE_LIST") end,
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

    if m_tutorialPushDelay and not m_tutorialControlsReady then
        m_openPending = false
        m_tutorialPushPending = true
        return
    end

    m_openPending = false
    m_tutorialPushDelay = false
    m_tutorialControlsReady = false
    m_tutorialPushPending = false

    local ePlayer = Game.GetLocalPlayer()
    local playerTechs = ePlayer and ePlayer ~= -1 and Players[ePlayer]:GetTechs() or nil
    local hasCurrent = playerTechs and playerTechs:GetResearchingTech() ~= -1
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
    return orig(input)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)

OnChooseResearch = WrapFunc(OnChooseResearch, function(orig, techHash)
    for _, kData in ipairs(m_rowData) do
        if kData.Hash == techHash then
            Speak(Locale.Lookup("LOC_HUD_RESEARCH_CHOSEN", kData.Name) or kData.Name)
            break
        end
    end
    return orig(techHash)
end)

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
