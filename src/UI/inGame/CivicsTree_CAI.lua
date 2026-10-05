include("CAIResearchData")
include("CAIResearchTree")
include("CAIControl")
include("caiUtils")
include("inGameHelpers_CAI")
include("ToolTipHelper")
include("Civ6Common")

-- Expansion-aware include chain. Only XP2 ships a CivicsTree replacement (adds
-- revealed-only search; there is no XP1 civics variant and no alliance on the
-- civics side). CAI replaces the screen context outright, so it must load the
-- exact variant vanilla would.
if IsExpansion2Active and IsExpansion2Active() then
    include("CivicsTree_Expansion2")
else
    include("CivicsTree")
end

local mgr = ExposedMembers.CAI_UIManager
local tree
local m_leadsToByType = {}
local m_civicIndexToType = {}
local m_civicTierByType = {}
local m_lastPlayerData
local m_modifierCache, m_govTree

local function GetLocalPlayerCulture()
    local ePlayer = Game.GetLocalPlayer()
    if ePlayer == PlayerTypes.NONE then return nil, -1 end
    local kPlayer = Players[ePlayer]
    if not kPlayer then return nil, -1 end
    return kPlayer:GetCulture(), ePlayer
end

local function GetUiNode(civicType)
    return g_uiNodes and g_uiNodes[civicType] or nil
end

local function GetLiveData(civicType)
    if not m_lastPlayerData then return nil end
    local liveTable = m_lastPlayerData[DATA_FIELD_LIVEDATA]
    return liveTable and liveTable[civicType] or nil
end

local data = CAIResearchData.Create({
    GetLiveData = GetLiveData,
    GetUiNode = GetUiNode,
    GetRow = function(itemType) return GameInfo.Civics[itemType] end,
    GetStatic = function(itemType) return g_kItemDefaults[itemType] end,
    GetEra = function(eraType) return g_kEras and g_kEras[eraType] end,
    GetTier = function(itemType) return m_civicTierByType[itemType] end,
    GetQueue = function()
        local player = GetLocalPlayerCulture()
        return player and player:GetCivicQueue() or nil
    end,
    Statuses = ITEM_STATUS,
    Text = {
        Unrevealed = "LOC_CIVICS_TREE_NOT_REVEALED_CIVIC",
        Cost = "LOC_CAI_CIVIC_COST",
        Turns = "LOC_CAI_CIVIC_TURNS",
        Progress = "LOC_CAI_CIVIC_PROGRESS",
        Researched = "LOC_CAI_CIVIC_STATUS_RESEARCHED",
        Current = "LOC_CAI_CIVIC_STATUS_CURRENT",
        Blocked = "LOC_CAI_CIVIC_STATUS_BLOCKED",
        HiddenStatus = "LOC_CAI_CIVIC_STATUS_UNREVEALED",
    },
})

local function GetModifierCache()
    if not m_modifierCache and TechAndCivicSupport_BuildCivicModifierCache then
        m_modifierCache = TechAndCivicSupport_BuildCivicModifierCache()
    end
    return m_modifierCache or {}
end

local function CivicKData(civicType)
    return { CivicType = civicType, Type = civicType }
end

local function FormatRowLabel(civicType)
    local kLive = GetLiveData(civicType)
    if kLive and not kLive.IsRevealed then
        return data.Name(civicType)
    end
    local parts = {}
    CAIText.AppendIfNonEmpty(parts, data.Name(civicType))
    CAIText.AppendIfNonEmpty(parts, data.Status(kLive))
    CAIText.AppendIfNonEmpty(parts, GetRecommendedPart(kLive, false))
    local qpos = data.QueuePosition(civicType)
    if qpos then
        CAIText.AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_CIVIC_QUEUE_POSITION", qpos))
    end
    return table.concat(parts, "[NEWLINE]")
end

local function FormatRowTooltip(civicType)
    -- Vanilla hides an unrevealed civic's cost / turns / description / boost /
    -- obsoletes / unlocks / awards (generic node tooltip + hidden unlock stack).
    -- But it still draws the prereq/leads-to connector lines for every node, so
    -- the topology is visible — keep those even when unrevealed.
    local kLive = GetLiveData(civicType)
    local revealed = not (kLive and not kLive.IsRevealed)

    local parts = {}

    if revealed then
        CAIText.AppendIfNonEmpty(parts, data.Cost(civicType))
        CAIText.AppendIfNonEmpty(parts, data.Turns(civicType))
        CAIText.AppendIfNonEmpty(parts, data.Progress(civicType))
        CAIText.AppendIfNonEmpty(parts, data.Description(civicType))
        CAIText.AppendIfNonEmpty(parts, data.Boost(civicType))
        local obsoletes = GetObsoletePolicyNames(CivicKData(civicType))
        if #obsoletes > 0 then
            CAIText.AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_CIVIC_OBSOLETES_HEADER", table.concat(obsoletes, "[NEWLINE]")))
        end
    end

    local kStatic = g_kItemDefaults[civicType]
    local currentEraType = kStatic and kStatic.EraType

    local prereqTypes = {}
    for _, pt in ipairs(kStatic and kStatic.Prereqs or {}) do
        if pt ~= PREREQ_ID_TREE_START then table.insert(prereqTypes, pt) end
    end
    if #prereqTypes > 0 then
        local names = data.RelatedNames(prereqTypes, currentEraType)
        CAIText.AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_CIVIC_PREREQS_HEADER", table.concat(names, "[NEWLINE]")))
    end

    local leadsTo = m_leadsToByType[civicType]
    if leadsTo and #leadsTo > 0 then
        local names = data.RelatedNames(leadsTo, currentEraType)
        CAIText.AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_CIVIC_LEADS_TO_HEADER", table.concat(names, "[NEWLINE]")))
    end

    if revealed then
        local unlocks = GetCivicUnlockObjects(CivicKData(civicType))
        if #unlocks > 0 then
            local names = {}
            for _, u in ipairs(unlocks) do table.insert(names, u.Name) end
            CAIText.AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_CIVIC_UNLOCKS_HEADER", table.concat(names, "[NEWLINE]")))
        end
        CAIText.AppendIfNonEmpty(parts, GetCivicAwardsText(GetAwardNames(GetModifierCache()[civicType])))
    end

    return table.concat(parts, "[NEWLINE]")
end

local function BuildStaticMaps()
    m_leadsToByType, m_civicIndexToType, m_civicTierByType =
        CAIResearchData.BuildMaps(g_kItemDefaults,
            function(itemType) return GameInfo.Civics[itemType] end,
            function(itemType, entry) return entry.Column or 0 end, PREREQ_ID_TREE_START)
end

local function SpeakProgressSummary(civicType)
    local kStatic = g_kItemDefaults[civicType]
    local playerCulture = GetLocalPlayerCulture()
    if not kStatic or not playerCulture then return end
    local pathToCivic = playerCulture:GetCivicPath(kStatic.Hash) or {}
    local count, totalCost = 0, 0
    for _, idx in ipairs(pathToCivic) do
        count = count + 1
        local ct = m_civicIndexToType[idx]
        local kLive = ct and GetLiveData(ct) or nil
        if kLive and kLive.Cost then
            totalCost = totalCost + kLive.Cost
        end
    end
    Speak(Locale.Lookup("LOC_CAI_CIVIC_QUEUE_ADDED", count, totalCost))
end

local function ActivateSetCurrent(civicType)
    local node = GetUiNode(civicType)
    local clicked = false
    if node and node.NodeButton and node.NodeButton.DoLeftClick and not CAIControl.IsHidden(node.NodeButton) then
        node.NodeButton:DoLeftClick()
        clicked = true
    elseif node and node.OtherStates and node.OtherStates.DoLeftClick and not CAIControl.IsHidden(node.OtherStates) then
        node.OtherStates:DoLeftClick()
        clicked = true
    end
    if not clicked then
        local kStatic = g_kItemDefaults[civicType]
        local playerCulture, ePlayer = GetLocalPlayerCulture()
        if not kStatic or not playerCulture or ePlayer == -1 then return end
        local tParameters                               = {}
        tParameters[PlayerOperations.PARAM_CIVIC_TYPE]  = playerCulture:GetCivicPath(kStatic.Hash)
        tParameters[PlayerOperations.PARAM_INSERT_MODE] = PlayerOperations.VALUE_EXCLUSIVE
        UI.RequestPlayerOperation(ePlayer, PlayerOperations.PROGRESS_CIVIC, tParameters)
        UI.PlaySound("Confirm_Civic_CivicsTree")
    end
    SpeakProgressSummary(civicType)
end

local function ActivateAppendToQueue(civicType)
    local kStatic = g_kItemDefaults[civicType]
    local playerCulture, ePlayer = GetLocalPlayerCulture()
    if not kStatic or not playerCulture or ePlayer == -1 then return end
    local tParameters                               = {}
    tParameters[PlayerOperations.PARAM_CIVIC_TYPE]  = playerCulture:GetCivicPath(kStatic.Hash)
    tParameters[PlayerOperations.PARAM_INSERT_MODE] = PlayerOperations.VALUE_APPEND
    UI.RequestPlayerOperation(ePlayer, PlayerOperations.PROGRESS_CIVIC, tParameters)
    UI.PlaySound("Confirm_Civic_CivicsTree")
    SpeakProgressSummary(civicType)
end


local function GetGovernmentSummary()
    local function Count(control) return tonumber(CAIControl.Text(control)) or 0 end
    return Locale.Lookup("LOC_CAI_GOVERNMENT_SUMMARY",
        CAIControl.Text(Controls.GovernmentTitle),
        Count(Controls.DiplomaticIconCount),
        Count(Controls.EconomicIconCount),
        Count(Controls.MilitaryIconCount),
        Count(Controls.WildcardIconCount))
end

local GOVERNMENT_POLICY_ROWS = {
    {
        Key = "military",
        DataField = "MILITARYPOLICIES",
        Label = "LOC_CAI_POLICY_SLOT_MILITARY",
        Empty = "LOC_GOVT_NO_MILITARY_SLOTS",
    },
    {
        Key = "economic",
        DataField = "ECONOMICPOLICIES",
        Label = "LOC_CAI_POLICY_SLOT_ECONOMIC",
        Empty = "LOC_GOVT_NO_ECONOMIC_SLOTS",
    },
    {
        Key = "diplomatic",
        DataField = "DIPLOMATICPOLICIES",
        Label = "LOC_CAI_POLICY_SLOT_DIPLOMATIC",
        Empty = "LOC_GOVT_NO_DIPLOMACY_SLOTS",
    },
    {
        Key = "wildcard",
        DataField = "WILDCARDPOLICIES",
        Label = "LOC_CAI_POLICY_SLOT_WILDCARD",
        Empty = "LOC_GOVT_NO_WILDCARD_SLOTS",
    },
}

local function BuildGovernmentTree()
    if not m_govTree then return end
    local government = m_lastPlayerData and m_lastPlayerData[DATA_FIELD_GOVERNMENT] or nil

    for _, rowData in ipairs(GOVERNMENT_POLICY_ROWS) do
        local rowKey = rowData.Key
        local rowLabel = rowData.Label
        local emptyLabel = rowData.Empty
        local policyIDs = government and government[rowData.DataField] or {}
        local used = 0
        for _, policyID in ipairs(policyIDs or {}) do
            if policyID ~= -1 then used = used + 1 end
        end

        local category = mgr:CreateWidget(mgr:GenerateWidgetId("CAICivicsTreePolicyRow"), "TreeItem", {
            Label = function() return Locale.Lookup(rowLabel) end,
            Tooltip = function()
                return Locale.Lookup("LOC_CAI_GOVERNMENT_SLOTS_USED", used, #(policyIDs or {}))
            end,
            FocusKey = "government-policy-row:" .. rowKey,
        })

        if #(policyIDs or {}) == 0 then
            category:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAICivicsTreePolicyEmpty"), "TreeItem", {
                Label = function() return Locale.Lookup(emptyLabel) end,
                FocusKey = "government-policy-empty:" .. rowKey,
            }))
        else
            for slotOrdinal, policyID in ipairs(policyIDs) do
                local capturedID = policyID
                local capturedOrdinal = slotOrdinal
                category:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAICivicsTreePolicy"), "TreeItem", {
                    Label = function()
                        if capturedID == -1 then
                            return Locale.Lookup("LOC_CAI_GOVERNMENT_EMPTY_SLOT", capturedOrdinal)
                        end
                        local policy = GameInfo.Policies[capturedID]
                        return Locale.Lookup(policy.Name)
                    end,
                    Tooltip = function()
                        if capturedID == -1 then return "" end
                        local policy = GameInfo.Policies[capturedID]
                        return GetUnlockDescription(policy.PolicyType) or ""
                    end,
                    FocusKey = "government-policy:" .. rowKey .. ":" .. tostring(capturedOrdinal),
                }))
            end
        end

        m_govTree:AddChild(category)
    end
end

local function RefreshGovernmentTree()
    if not m_govTree then return end
    local capture = mgr:CaptureFocusKey(m_govTree)
    m_govTree:ClearChildren()
    BuildGovernmentTree()
    mgr:RestoreFocus(m_govTree, capture)
end

tree = CAIResearchTree.Create(mgr, {
    IdPrefix = "CAICivicsTree",
    GridIdPrefix = "CAICivicsGrid",
    NodeSuffix = "Civic",
    DebugName = "CivicsTree",
    SettingID = "CivicsTreeViewMode",
    ViewFocusKey = "civics-tree:view",
    FocusPrefix = "civic:",
    SearchContext = "Civics",
    PrereqStart = PREREQ_ID_TREE_START,
    GetEntries = function() return g_kItemDefaults end,
    GetEras = function() return g_kEras end,
    GetFilters = function() return g_TechFilters end,
    GetTitle = function() return CAIControl.Text(Controls.ModalScreenTitle) end,
    GetColumn = function(itemType, entry) return entry.Column or 0 end,
    GetTypeForIndex = function(index) return m_civicIndexToType[index] end,
    GetName = data.Name,
    GetRelatedLabel = data.RelatedLabel,
    GetUiNode = GetUiNode,
    FormatLabel = FormatRowLabel,
    FormatTooltip = FormatRowTooltip,
    CanResearch = data.CanResearch,
    IsRevealed = data.IsRevealed,
    SetCurrent = ActivateSetCurrent,
    AppendToQueue = ActivateAppendToQueue,
    GetUnlocks = function(itemType) return GetCivicUnlockObjects(CivicKData(itemType)) end,
    GetLeadsTo = function(itemType) return m_leadsToByType[itemType] end,
    GetPath = function(hash)
        local player = GetLocalPlayerCulture()
        return player and player:GetCivicPath(hash) or nil
    end,
    Prepare = BuildStaticMaps,
    ReadQueue = function()
        local player = GetLocalPlayerCulture()
        if not player then return nil, nil end
        return player:GetProgressingCivic(), player:GetCivicQueue()
    end,
    ApplyFilter = function(entry)
        if OnFilterClicked then OnFilterClicked(entry) end
    end,
    ResetData = function()
        m_leadsToByType = {}
        m_civicIndexToType = {}
        m_civicTierByType = {}
        m_lastPlayerData = nil
        m_modifierCache, m_govTree = nil, nil
    end,
    AddExtraPanels = function(panel)
        m_govTree = mgr:CreateWidget("CAICivicsTree_GovTree", "Tree", {
            Label = GetGovernmentSummary,
            SearchDepth = 0,
        })
        panel:AddChild(m_govTree)
    end,
    RefreshExtra = RefreshGovernmentTree,
    FilterDefinitions = {
        { "TECHFILTER_FOOD",         "LOC_TECH_FILTER_FOOD" },
        { "TECHFILTER_SCIENCE",      "LOC_TECH_FILTER_SCIENCE" },
        { "TECHFILTER_PRODUCTION",   "LOC_TECH_FILTER_PRODUCTION" },
        { "TECHFILTER_CULTURE",      "LOC_TECH_FILTER_CULTURE" },
        { "TECHFILTER_GOLD",         "LOC_TECH_FILTER_GOLD" },
        { "TECHFILTER_UNITS",        "LOC_TECH_FILTER_UNITS" },
        { "TECHFILTER_IMPROVEMENTS", "LOC_TECH_FILTER_IMPROVEMENTS" },
        { "TECHFILTER_WONDERS",      "LOC_TECH_FILTER_WONDERS" },
    },
    Text = {
        Prerequisites = "LOC_CAI_CIVICS_TREE_PREREQS",
        LeadsTo = "LOC_CAI_CIVICS_TREE_LEADS_TO",
        Path = "LOC_CAI_CIVICS_TREE_PATH_IF_SELECTED",
        QueueAction = "LOC_CAI_KB_ADD_TO_QUEUE",
        BackAction = "LOC_CAI_KB_NAVIGATE_BACK",
        Jump = "LOC_CAI_CIVICS_TREE_JUMPING",
        Current = "LOC_CAI_CIVIC_CURRENT",
        FilterResults = "LOC_CAI_CIVICS_TREE_FILTER_RESULTS",
        QueueList = "LOC_CAI_CIVICS_TREE_QUEUE_LIST",
        Filter = "LOC_CAI_CIVICS_TREE_FILTER",
        MainList = "LOC_CAI_CIVICS_TREE_MAIN_LIST",
        Unlocks = "LOC_CAI_CIVICS_TREE_UNLOCKS",
    },
})

View = WrapFunc(View, function(orig, playerData)
    m_lastPlayerData = playerData
    orig(playerData)
    if tree.HasPanel() then
        tree.RebuildQueue()
        RefreshGovernmentTree()
    end
end)

local _origOnOpen = OnOpen
OnOpen = WrapFunc(OnOpen, function(orig)
    orig()
    tree.Open()
end)
LuaEvents.CivicsChooser_RaiseCivicsTree.Remove(_origOnOpen)
LuaEvents.LaunchBar_RaiseCivicsTree.Remove(_origOnOpen)
LuaEvents.CivicsChooser_RaiseCivicsTree.Add(OnOpen)
LuaEvents.LaunchBar_RaiseCivicsTree.Add(OnOpen)

Close = WrapFunc(Close, function(orig)
    tree.Close()
    orig()
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
    if mgr and tree.IsOpen() then
        if mgr:HandleInput(pInputStruct) then return true end
    end
    if IsCAIEscapeKeyUp(pInputStruct)
        and not IsCAITutorialScreenCloseAllowed("CivicsTreeModal") then
        AnnounceCAITutorialScreenCloseBlocked()
        return true
    end
    return orig(pInputStruct)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)

-- ===========================================================================
-- EVENTS
-- ===========================================================================

Events.CivicChanged.Add(function(ePlayer)
    if ePlayer == Game.GetLocalPlayer() and tree.IsOpen() then
        tree.RebuildQueue()
        tree.RefocusRow()
    end
end)

Events.CivicQueueChanged.Add(function(ePlayer)
    if ePlayer == Game.GetLocalPlayer() and tree.IsOpen() then
        tree.RebuildQueue()
        tree.RefocusRow()
    end
end)

Events.CivicCompleted.Add(function(ePlayer)
    if ePlayer ~= Game.GetLocalPlayer() or not tree.IsOpen() then return end
    tree.RebuildViews()
    tree.RebuildQueue()
end)

Events.CultureYieldChanged.Add(tree.RefocusRow)

local function RefreshGovIfOpen()
    if tree.IsOpen() then
        RefreshGovernmentTree()
    end
end

Events.GovernmentChanged.Add(function(ePlayer)
    if ePlayer == Game.GetLocalPlayer() then RefreshGovIfOpen() end
end)

Events.GovernmentPolicyChanged.Add(function(ePlayer)
    if ePlayer == Game.GetLocalPlayer() then RefreshGovIfOpen() end
end)

Events.GovernmentPolicyObsoleted.Add(function(ePlayer)
    if ePlayer == Game.GetLocalPlayer() then RefreshGovIfOpen() end
end)

Events.LocalPlayerTurnBegin.Add(function(ePlayer)
    if ePlayer == Game.GetLocalPlayer() and tree.IsOpen() then
        tree.RebuildQueue()
    end
end)

Events.LocalPlayerChanged.Add(function() tree.Close() end)
