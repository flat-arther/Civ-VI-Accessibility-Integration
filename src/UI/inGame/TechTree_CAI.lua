include("CAIModSupport")
include("CAIResearchData")
include("CAIResearchTree")
include("CAIControl")
include("caiUtils")
include("inGameHelpers_CAI")
include("ToolTipHelper")
include("Civ6Common")

-- Ruleset/expansion-aware include chain. Australia's wrapper preserves its
-- native scenario layout behavior. XP1 adds AllianceResearchSupport (per-node
-- alliance research icon/tooltip); XP2 includes XP1 and adds revealed-only
-- search. CAI replaces the screen context outright, so it must load the exact
-- variant vanilla would.
if CAIModSupport.IsAustraliaScenarioActive() then
    include("TechTree_AustraliaScenario")
elseif IsExpansion2Active and IsExpansion2Active() then
    include("TechTree_Expansion2")
elseif IsExpansion1Active and IsExpansion1Active() then
    include("TechTree_Expansion1")
else
    include("TechTree")
end

local mgr = CAI:GetUIManager()
local tree
local m_leadsToByType = {}
local m_techIndexToType = {}
local m_techTierByType = {}
local m_lastPlayerData
local m_techColumnByType = {}

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

local function GetLiveData(techType)
    if not m_lastPlayerData then return nil end
    local liveTable = m_lastPlayerData[DATA_FIELD_LIVEDATA]
    return liveTable and liveTable[techType] or nil
end

local data = CAIResearchData.Create({
    GetLiveData = GetLiveData,
    GetUiNode = GetUiNode,
    GetRow = function(itemType) return GameInfo.Technologies[itemType] end,
    GetStatic = function(itemType) return g_kItemDefaults[itemType] end,
    GetEra = function(eraType) return g_kEras and g_kEras[eraType] end,
    GetTier = function(itemType) return m_techTierByType[itemType] end,
    GetQueue = function()
        local player = GetLocalPlayerTechs()
        return player and player:GetResearchQueue() or nil
    end,
    Statuses = ITEM_STATUS,
    Text = {
        Unrevealed = "LOC_TECH_TREE_NOT_REVEALED_TECH",
        Cost = "LOC_CAI_RESEARCH_COST",
        Turns = "LOC_CAI_RESEARCH_TURNS",
        Progress = "LOC_CAI_RESEARCH_PROGRESS",
        Researched = "LOC_CAI_TECH_STATUS_RESEARCHED",
        Current = "LOC_CAI_TECH_STATUS_CURRENT",
        Blocked = "LOC_CAI_TECH_STATUS_BLOCKED",
        HiddenStatus = "LOC_CAI_TECH_STATUS_UNREVEALED",
    },
})

local function GetAllianceText(techType)
    local node = GetUiNode(techType)
    if not node or not node.Alliance or not node.AllianceIcon then return nil end
    if CAIControl.IsHidden(node.Alliance) then return nil end
    local tip = CAIText.NormalizeFormattedText(node.AllianceIcon:GetToolTipString())
    if tip == "" then return nil end
    return Locale.Lookup("LOC_CAI_RESEARCH_ALLIANCE_BONUS", tip)
end

local function TechKData(techType)
    return { TechType = techType, Type = techType }
end

local function FormatRowLabel(techType)
    local kLive = GetLiveData(techType)
    if kLive and not kLive.IsRevealed then
        return data.Name(techType)
    end
    local parts = {}
    CAIText.AppendIfNonEmpty(parts, data.Name(techType))
    CAIText.AppendIfNonEmpty(parts, data.Status(kLive))
    CAIText.AppendIfNonEmpty(parts, GetRecommendedPart(kLive, false))
    local qpos = data.QueuePosition(techType)
    if qpos then
        CAIText.AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_RESEARCH_QUEUED", qpos))
    end
    return table.concat(parts, "[NEWLINE]")
end

local function FormatRowTooltip(techType)
    -- Vanilla hides an unrevealed tech's cost / turns / description / boost /
    -- reveals / unlocks (generic node tooltip + hidden unlock stack). But it
    -- still draws the prereq/leads-to connector lines for every node, so the
    -- topology is visible — keep those even when unrevealed.
    local kLive = GetLiveData(techType)
    local revealed = not (kLive and not kLive.IsRevealed)

    local parts = {}

    if revealed then
        CAIText.AppendIfNonEmpty(parts, data.Cost(techType))
        CAIText.AppendIfNonEmpty(parts, data.Turns(techType))
        CAIText.AppendIfNonEmpty(parts, data.Progress(techType))
        CAIText.AppendIfNonEmpty(parts, data.Description(techType))
        CAIText.AppendIfNonEmpty(parts, data.Boost(techType))
        CAIText.AppendIfNonEmpty(parts, GetAllianceText(techType))

        local kStatic = g_kItemDefaults[techType]
        local currentEraType = kStatic and kStatic.EraType

        local prereqTypes = {}
        for _, pt in ipairs(kStatic and kStatic.Prereqs or {}) do
            if pt ~= PREREQ_ID_TREE_START then table.insert(prereqTypes, pt) end
        end
        if #prereqTypes > 0 then
            local names = data.RelatedNames(prereqTypes, currentEraType)
            CAIText.AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_RESEARCH_PREREQS_HEADER", table.concat(names, "[NEWLINE]")))
        end

        local leadsTo = m_leadsToByType[techType]
        if leadsTo and #leadsTo > 0 then
            local names = data.RelatedNames(leadsTo, currentEraType)
            CAIText.AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_RESEARCH_LEADS_TO_HEADER", table.concat(names, "[NEWLINE]")))
        end

        local group = GetTechUnlockObjects(TechKData(techType))
        if #group.Reveals > 0 then
            local names = {}
            for _, r in ipairs(group.Reveals) do
                table.insert(names, Locale.Lookup("LOC_TOOLTIP_UNLOCKS_RESOURCE", r.Name))
            end
            CAIText.AppendIfNonEmpty(parts, table.concat(names, "[NEWLINE]"))
        end
        if #group.Unlocks > 0 then
            local names = {}
            for _, u in ipairs(group.Unlocks) do table.insert(names, u.Name) end
            CAIText.AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_RESEARCH_UNLOCKS_HEADER", table.concat(names, "[NEWLINE]")))
        end
    end

    return table.concat(parts, "[NEWLINE]")
end

local function ComputeTechColumn(techType)
    local cached = m_techColumnByType[techType]
    if cached then return cached end
    local kEntry = g_kItemDefaults[techType]
    if not kEntry then return 1 end
    local maxPrereqCol = 0
    for _, prereqType in ipairs(kEntry.Prereqs or {}) do
        if prereqType ~= PREREQ_ID_TREE_START then
            local kPrereq = g_kItemDefaults[prereqType]
            if kPrereq and kPrereq.EraType == kEntry.EraType then
                local c = ComputeTechColumn(prereqType)
                if c > maxPrereqCol then maxPrereqCol = c end
            end
        end
    end
    local col = maxPrereqCol + 1
    m_techColumnByType[techType] = col
    return col
end

local function BuildStaticMaps()
    m_techColumnByType = {}
    for techType in pairs(g_kItemDefaults) do ComputeTechColumn(techType) end
    m_leadsToByType, m_techIndexToType, m_techTierByType =
        CAIResearchData.BuildMaps(g_kItemDefaults,
            function(itemType) return GameInfo.Technologies[itemType] end,
            function(itemType, entry) return m_techColumnByType[itemType] or 1 end, PREREQ_ID_TREE_START)
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
    if node and node.NodeButton and node.NodeButton.DoLeftClick and not CAIControl.IsHidden(node.NodeButton) then
        node.NodeButton:DoLeftClick()
        clicked = true
    elseif node and node.OtherStates and node.OtherStates.DoLeftClick and not CAIControl.IsHidden(node.OtherStates) then
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


tree = CAIResearchTree.Create(mgr, {
    IdPrefix = "CAITechTree",
    GridIdPrefix = "CAITechGrid",
    NodeSuffix = "Tech",
    DebugName = "TechTree",
    SettingID = "TechTreeViewMode",
    ViewFocusKey = "tech-tree:view",
    FocusPrefix = "tech:",
    SearchContext = "Technologies",
    PrereqStart = PREREQ_ID_TREE_START,
    GetEntries = function() return g_kItemDefaults end,
    GetEras = function() return g_kEras end,
    GetFilters = function() return g_TechFilters end,
    GetTitle = function() return CAIControl.Text(Controls.ModalScreenTitle) end,
    GetColumn = function(itemType, entry) return m_techColumnByType[itemType] or 1 end,
    GetTypeForIndex = function(index) return m_techIndexToType[index] end,
    GetName = data.Name,
    GetRelatedLabel = data.RelatedLabel,
    GetUiNode = GetUiNode,
    FormatLabel = FormatRowLabel,
    FormatTooltip = FormatRowTooltip,
    CanResearch = data.CanResearch,
    IsRevealed = data.IsRevealed,
    SetCurrent = ActivateSetCurrent,
    AppendToQueue = ActivateAppendToQueue,
    GetUnlocks = function(itemType) return GetTechUnlockObjects(TechKData(itemType)).Unlocks end,
    GetLeadsTo = function(itemType) return m_leadsToByType[itemType] end,
    GetPath = function(hash)
        local player = GetLocalPlayerTechs()
        return player and player:GetResearchPath(hash) or nil
    end,
    Prepare = BuildStaticMaps,
    ReadQueue = function()
        local player = GetLocalPlayerTechs()
        if not player then return nil, nil end
        return player:GetResearchingTech(), player:GetResearchQueue()
    end,
    ApplyFilter = function(entry)
        if OnFilterClicked then OnFilterClicked(entry) end
    end,
    ResetData = function()
        m_leadsToByType = {}
        m_techIndexToType = {}
        m_techTierByType = {}
        m_lastPlayerData = nil
        m_techColumnByType = {}
    end,
    FilterDefinitions = {
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
    },
    Text = {
        Prerequisites = "LOC_CAI_TECH_TREE_PREREQS",
        LeadsTo = "LOC_CAI_TECH_TREE_LEADS_TO",
        Path = "LOC_CAI_TECH_TREE_PATH_IF_SELECTED",
        QueueAction = "LOC_CAI_KB_QUEUE_RESEARCH",
        BackAction = "LOC_CAI_KB_GO_BACK",
        Jump = "LOC_CAI_TECH_TREE_JUMPING",
        Current = "LOC_CAI_RESEARCH_CURRENT",
        FilterResults = "LOC_CAI_TECH_TREE_FILTER_RESULTS",
        QueueList = "LOC_CAI_TECH_TREE_QUEUE_LIST",
        Filter = "LOC_CAI_TECH_TREE_FILTER",
        MainList = "LOC_CAI_TECH_TREE_MAIN_LIST",
        Unlocks = "LOC_CAI_TECH_TREE_UNLOCKS",
    },
})

View = WrapFunc(View, function(orig, playerData)
    m_lastPlayerData = playerData
    orig(playerData)
    if tree.HasPanel() then
        tree.RebuildQueue()
    end
end)

local _origOnOpen = OnOpen
OnOpen = WrapFunc(OnOpen, function(orig)
    orig()
    tree.Open()
end)
LuaEvents.LaunchBar_RaiseTechTree.Remove(_origOnOpen)
LuaEvents.ResearchChooser_RaiseTechTree.Remove(_origOnOpen)
LuaEvents.LaunchBar_RaiseTechTree.Add(OnOpen)
LuaEvents.ResearchChooser_RaiseTechTree.Add(OnOpen)

Close = WrapFunc(Close, function(orig)
    tree.Close()
    orig()
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
    if mgr and tree.IsOpen() then
        if mgr:HandleInput(pInputStruct) then return true end
    end
    if IsCAIEscapeKeyUp(pInputStruct)
        and not IsCAITutorialScreenCloseAllowed("TechTreeModal") then
        AnnounceCAITutorialScreenCloseBlocked()
        return true
    end
    return orig(pInputStruct)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)

-- ===========================================================================
-- EVENTS
-- ===========================================================================

Events.ResearchChanged.Add(function(ePlayer)
    if ePlayer == Game.GetLocalPlayer() and tree.IsOpen() then
        tree.RebuildQueue()
        tree.RefocusRow()
    end
end)

Events.ResearchQueueChanged.Add(function(ePlayer)
    if ePlayer == Game.GetLocalPlayer() and tree.IsOpen() then
        tree.RebuildQueue()
        tree.RefocusRow()
    end
end)

Events.ResearchCompleted.Add(function(ePlayer)
    if ePlayer ~= Game.GetLocalPlayer() or not tree.IsOpen() then return end
    tree.RebuildViews()
    tree.RebuildQueue()
end)

Events.LocalPlayerTurnBegin.Add(function(ePlayer)
    if ePlayer == Game.GetLocalPlayer() and tree.IsOpen() then
        tree.RebuildQueue()
    end
end)

Events.LocalPlayerChanged.Add(function() tree.Close() end)
