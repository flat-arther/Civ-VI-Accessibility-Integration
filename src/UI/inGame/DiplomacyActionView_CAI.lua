-- DiplomacyActionView_CAI.lua
--
-- Accessibility layer for the diplomacy action view (the leader screen: intel,
-- statement actions, conversation choices, and the cinematic intro).
--
-- Unlike DiplomacyDealView, DiplomacyActionView has NO wildcard include, so the
-- CAI layer is still a ReplaceUIScript. To stay correct on every ruleset we must
-- re-include the exact vanilla script the game would otherwise load: with an
-- expansion installed the active context is DiplomacyActionView_Expansion1/2,
-- which add the Alliance / Emergency / World Congress intel tabs and override
-- war-type and statement logic. Re-including the base file there would silently
-- drop all of that. Mirrors GovernmentScreen_CAI's variant include.

include("caiUtils")
include("Civ6Common") -- IsExpansion1Active / IsExpansion2Active

-- Quick Deals also replaces the DiplomacyActionView context, but only to wrap
-- OnDiplomacyStatement/LateInitialize so it can close its popup and its silent
-- diplomacy sessions when a surprise statement (e.g. a war declaration) arrives
-- while the popup is open. CAI wins the ReplaceUIScript, so we would otherwise
-- drop that cleanup. Quick Deals exports diplomacyactionview_qd via ImportFiles
-- precisely so other mods can chain it; it re-includes the correct vanilla
-- variant itself, then installs its wraps, which CAI then wraps on top of.
if IsQuickDealsActive() then
    include("diplomacyactionview_qd")
elseif IsExpansion2Active() then
    include("DiplomacyActionView_Expansion2")
elseif IsExpansion1Active() then
    include("DiplomacyActionView_Expansion1")
else
    include("DiplomacyActionView")
end

local mgr = ExposedMembers.CAI_UIManager
local m_alwaysReceivesInput = false

local function SetAlwaysReceivesInput(enabled)
    if m_alwaysReceivesInput == enabled then return end
    if enabled then
        UITutorialManager:AddControlToAlwaysReceiveInput(ContextPtr)
    else
        UITutorialManager:RemoveControlToAlwaysReceiveInput(ContextPtr)
    end
    m_alwaysReceivesInput = enabled
end

local CAI_OVERVIEW_MODE = 0
local CAI_CONVERSATION_MODE = 1
local CAI_CINEMA_MODE = 2
local CAI_DEAL_MODE = 3

local ROOT_ID = "CAIDiplomacyRoot"
local OVERVIEW_PANEL_ID = "CAIDiplomacyOverviewPanel"
local CONVERSATION_PANEL_ID = "CAIDiplomacyConversationPanel"
local CINEMA_PANEL_ID = "CAIDiplomacyCinemaPanel"
local LEADERS_TREE_ID = "CAIDiplomacyLeadersTree"
local ACTIONS_LIST_ID = "CAIDiplomacyActionsList"
local CONVERSATION_LIST_ID = "CAIDiplomacyConversationList"
local TABLE_ID = "CAIDiplomacyLeaderTable"
local LOCAL_LEADER_ID = "CAIDiplomacyLocalLeader"
local TREE_SORT_ID = "CAIDiplomacyTreeSort"
local GOSSIP_FILTER_ID = "CAIDiplomacyGossipFilter"
local SWITCH_VIEW_ID = "CAIDiplomacySwitchView"
local GOSSIP_PANEL_ID = "CAIDiplomacyGossipPanel"
local GRIEVANCE_LOG_ID = "CAIDiplomacyGrievanceLogPanel"

local VIEW_SETTING_SECTION = "DiplomacyActionView"
local VIEW_SETTING_ID = "ViewMode"

local m_ui = {
    root = nil,
    overviewPanel = nil,
    conversationPanel = nil,
    cinemaPanel = nil,
    leadersTree = nil,
    table = nil,
    localLeader = nil,
    treeSort = nil,
    gossipFilter = nil,
    switchView = nil,
    actionsList = nil,
    conversationList = nil,
    leaderEntries = {},
    leaderOrder = {},
}

local function LoadViewModeSetting()
    local stored = tostring(CAI.GetConfigValue(VIEW_SETTING_SECTION, VIEW_SETTING_ID, "table")):lower()
    if stored == "tree" then return "tree" end
    return "table"
end

local function SaveViewModeSetting(viewMode)
    if not CAI.SetConfigValue(VIEW_SETTING_SECTION, VIEW_SETTING_ID, viewMode) then
        LogError("Diplomacy failed to save view mode " .. tostring(viewMode))
    end
end

local m_viewMode = LoadViewModeSetting()
-- Shared sort across table headers and the tree "Order by" dropdown.
local m_sortColumn = nil
local m_sortAscending = false
local m_sortOptions = {}
-- Current gossip group filter for both the tree-mode dropdown and the drill-down
-- panel; "ALL" shows every group.
local m_gossipGroupFilter = "ALL"

local m_state = {
    syncingLeaderSelection = false,
    selectingFromRow = false,
    suppressActionsRebuild = false,
    selectedPlayer = -1,
    -- True while a cinematic intro is playing. Both vanilla containers are hidden
    -- in cinema, so the only navigable widget is the (silent) cinema panel; this
    -- flag drives its HiddenPredicate and tells the focus code to land there.
    cinema = false,
}

local m_vanilla = {
    intelInstances = {},
    actionLists = { root = {}, sub = {} },
    conversationBindings = nil,
}

-- Map of vanilla intel-tab header text -> clean hand-authored reader. Built lazily
-- so the Locale lookups resolve after the context is up. Tabs not in this map
-- (DLC alliance / emergency / world congress, future content) fall back to a
-- generic panel-text reader so they are still exposed.
local m_knownReaders = nil

-- ============================================================================
-- Control helpers
-- ============================================================================

local function PlayHoverSound(widget)
    widget:SetFocusSound("Main_Menu_Mouse_Over")
end

local function ControlIsHidden(control)
    return control and control.IsHidden and control:IsHidden() or false
end

local function ControlIsDisabled(control)
    return control and control.IsDisabled and control:IsDisabled() or false
end

local function ControlText(control)
    if not control or ControlIsHidden(control) then return "" end
    if control.GetText then
        local text = control:GetText()
        if text and text ~= "" then return text end
    end
    return ""
end

local function ControlTooltip(control)
    if not control or ControlIsHidden(control) or not control.GetToolTipString then return "" end
    return control:GetToolTipString() or ""
end

-- Read a button's on-screen label. The conversation SelectionButton keeps its
-- text in a child "SelectionText" Label, not in the button's intrinsic text
-- control, so GetTextControl() misses it -- fall back to the first visible child
-- that reports text. Used so a live button announces its real label even when it
-- has no paired re-derived selection (e.g. a disabled war reply CAI's extraction
-- dropped but vanilla still renders).
local function ControlButtonText(control)
    if not control then return "" end
    if control.GetTextControl then
        local text = ControlText(control:GetTextControl())
        if text ~= "" then return text end
    end
    if control.GetChildren then
        for _, child in ipairs(control:GetChildren()) do
            local text = ControlText(child)
            if text ~= "" then return text end
        end
    end
    return ""
end

local function NormalizeText(text)
    -- Color/tag stripping happens centrally in Speak()/ProcessText; keep only
    -- nil-safety here. SplitLines still splits on newlines (ASCII-safe) below.
    if not text then return "" end
    return tostring(text)
end

local function SplitLines(text)
    local lines = {}
    text = NormalizeText(text or "")
    text = string.gsub(text, "%[NEWLINE%]", "\n")
    text = string.gsub(text, "\r\n", "\n")
    text = string.gsub(text, "\r", "\n")
    text = text .. "\n"
    for line in string.gmatch(text, "(.-)\n") do
        if line ~= "" then
            table.insert(lines, line)
        end
    end
    return lines
end

local function JoinNonEmpty(parts, separator)
    local out = {}
    for _, part in ipairs(parts) do
        if part and part ~= "" then
            table.insert(out, part)
        end
    end
    return table.concat(out, separator)
end


local function JoinTooltipLines(text)
    if not text or text == "" then return text end
    return table.concat(SplitLines(text), "[NEWLINE]")
end

local function CountEntries(list)
    local count = 0
    if not list then return count end
    for _ in pairs(list) do
        count = count + 1
    end
    return count
end

local function CreateReadOnlyNode(id, label, tooltip)
    return mgr:CreateWidget(id, "TreeItem", {
        Label   = function() return label end,
        Tooltip = function() return tooltip or "" end,
    })
end

local function CreateReadOnlyText(id, label, details)
    local fullLabel = JoinNonEmpty({ label, details }, "[NEWLINE]")
    return mgr:CreateWidget(id, "StaticText", {
        Label = function() return fullLabel end,
    })
end

local function GetLeaderRowId(playerID)
    return "CAIDiplomacyLeaderRow_" .. tostring(playerID)
end

local function GetSelectedPlayerConfig()
    return ms_SelectedPlayerID ~= nil and PlayerConfigurations[ms_SelectedPlayerID] or nil
end

local function GetPanelLabel()
    local playerConfig = GetSelectedPlayerConfig()
    if playerConfig then
        return Locale.Lookup("LOC_DIPLOMACY_DEAL_PLAYER_PANEL_TITLE",
            playerConfig:GetLeaderName(),
            playerConfig:GetCivilizationDescription())
    end

    local playerName = ControlText(Controls.PlayerNameText)
    local civName = ControlText(Controls.CivNameText)
    return JoinNonEmpty({ playerName, civName }, ": ")
end

local function GetLeaderRowLabel(playerID)
    local playerConfig = PlayerConfigurations[playerID]
    if not playerConfig then return "" end
    return Locale.Lookup("LOC_DIPLOMACY_DEAL_PLAYER_PANEL_TITLE",
        playerConfig:GetLeaderName(),
        playerConfig:GetCivilizationDescription())
end

local function GetLeaderIDs()
    local ids = {}
    if ms_LocalPlayerID ~= nil and ms_LocalPlayerID >= 0 then
        table.insert(ids, ms_LocalPlayerID)
    end

    local diplomacy = ms_LocalPlayer and ms_LocalPlayer.GetDiplomacy and ms_LocalPlayer:GetDiplomacy() or nil
    if not diplomacy then return ids end

    for _, player in ipairs(PlayerManager.GetAliveMajors()) do
        local playerID = player:GetID()
        if playerID ~= ms_LocalPlayerID and diplomacy:HasMet(playerID) then
            table.insert(ids, playerID)
        end
    end

    return ids
end

local function IsSelfSelected()
    return ms_SelectedPlayerID ~= nil and ms_SelectedPlayerID == ms_LocalPlayerID
end

-- True when the Secret Societies game mode (Ethiopia pack) is enabled. Cheap engine
-- capability check; gates the diplomacy overview Secret Society row so non-Ethiopia
-- games add nothing.
local function IsSecretSocietiesActive()
    return GameCapabilities and GameCapabilities.HasCapability
        and GameCapabilities.HasCapability("CAPABILITY_SECRETSOCIETIES")
end

-- ============================================================================
-- View switching (replaces the old three-panel SetActivePanel hack). One of two
-- panels is navigable at a time, gated by HiddenPredicate following the live
-- vanilla containers; cinema hides both, so nothing is focused during it.
-- ============================================================================

local function IsRootPushed()
    return mgr and mgr:GetWidgetById(ROOT_ID) ~= nil
end

-- "Conversation" is the active navigable view whenever the vanilla conversation
-- container is shown. Vanilla hides ConversationContainer when it routes a demand
-- straight to the deal view or drops back to the overview, so reading the live
-- container state keeps the overview navigable without a separate view flag,
-- empty-list, or focus-visibility check.
local function IsConversationContainerShown()
    return not ControlIsHidden(Controls.ConversationContainer)
end

local function HasConversationChildren()
    return m_ui.conversationList
        and m_ui.conversationList.Children
        and #m_ui.conversationList.Children > 0
end

local function IsConversationActive()
    return IsConversationContainerShown() and HasConversationChildren()
end

-- True when the live focus leaf already sits inside the overview panel. When a
-- SelectPlayer refresh returns to the overview we only need to drop focus back
-- onto the overview when it is NOT already there -- i.e. focus is nil (the deal
-- overlay closed while both containers were hidden, so the manager could not
-- restore the prior leaf), or still parked in the now-hidden conversation panel.
-- Focus already on an overview widget (an action button after a make-demand round
-- trip, an intel node) is left untouched so it is not re-announced. This is a
-- purely structural ancestry walk -- visibility is decided by the panels'
-- container-driven HiddenPredicates, not here.
local function IsFocusInOverview()
    local w = mgr and mgr:GetFocusedWidget() or nil
    while w do
        if w == m_ui.overviewPanel then return true end
        w = w.Parent
    end
    return false
end

-- Focus the conversation list only once it actually has content. Called from
-- both SetConversationMode and RefreshConversationPanel because their order is
-- not guaranteed: whichever runs second (with the conversation container shown
-- and the list populated) lands focus on fresh response text + reply choices.
-- Guards: never steals focus unless the action-view root is the live top, and
-- never focuses an empty list (e.g. a demand that routes straight to the deal).
local function FocusConversationIfReady()
    if IsConversationContainerShown() and mgr:GetTop() == m_ui.root then
        CAI.Silence()
        mgr:SetFocus(m_ui.conversationList)
    end
end

-- ============================================================================
-- Statement actions list
-- ============================================================================

local function ClearConversationState()
    m_vanilla.conversationBindings = nil
    if m_ui.conversationList then
        m_ui.conversationList:ClearChildren()
    end
end

local function CaptureActionList(options, isSubList, createdInstances)
    local entries = {}

    for index, instance in ipairs(createdInstances) do
        local selection = options[index]
        local isCancel = isSubList and index > #options
        if selection or isCancel then
            table.insert(entries, {
                Selection = selection,
                Button = instance.Button,
                LabelControl = instance.ButtonText,
                Callback = instance.__CAI_ClickCallback,
                IsCancel = isCancel,
            })
        end
        instance.__CAI_ClickCallback = nil
    end

    if isSubList then
        m_vanilla.actionLists.sub = entries
    else
        m_vanilla.actionLists.root = entries
    end
end

local function SyncSubActionsForEntry(entry)
    if not entry or not entry.Callback then return {} end
    m_state.suppressActionsRebuild = true
    entry.Callback()
    m_state.suppressActionsRebuild = false
    local subEntries = m_vanilla.actionLists.sub or {}
    ShowOptionStack(false)
    return subEntries
end

-- Stable per-action key so RestoreFocus matches by FocusKey (silent) across the
-- frequent action-list rebuilds, and so focus returns to e.g. the Make Deal
-- button after the deal screen closes instead of jumping to the leader row.
local function GetActionFocusKey(entry, prefix)
    local key = entry.Selection and entry.Selection.Key
    return "diplo:action:" .. tostring(prefix) .. ":" .. tostring(key or ControlText(entry.LabelControl))
end

local function CreateActionButton(entry)
    local btn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIDiplomacyActionButton"), "Button", {
        Label             = function() return ControlText(entry.LabelControl) end,
        Tooltip           = function() return ControlTooltip(entry.Button) end,
        DisabledPredicate = function() return ControlIsDisabled(entry.Button) end,
        FocusKey          = GetActionFocusKey(entry, "btn"),
    })
    PlayHoverSound(btn)
    btn:On("focus_enter", function(w)
        if w:IsFocused() then ShowOptionStack(false) end
    end)
    btn:On("activate", function()
        if entry.Callback then entry.Callback() end
    end)
    return btn
end

local function CreateActionSubMenu(entry)
    local sub = mgr:CreateWidget(mgr:GenerateWidgetId("CAIDiplomacyActionSubMenu"), "SubMenu", {
        Label             = function() return ControlText(entry.LabelControl) end,
        Tooltip           = function() return ControlTooltip(entry.Button) end,
        DisabledPredicate = function() return ControlIsDisabled(entry.Button) end,
        FocusKey          = GetActionFocusKey(entry, "sub"),
    })
    PlayHoverSound(sub)
    sub:On("focus_enter", function(w)
        if w:IsFocused() then ShowOptionStack(false) end
    end)
    sub:On("collapsed", function() ShowOptionStack(false) end)

    -- Pre-populate sub-options now (guarded so the vanilla sub-list rebuild does
    -- not recurse into another actions rebuild). SubMenu:Expand refuses to open
    -- a childless node, so lazy population on the expand event would not work.
    --
    -- All sub-lists share the g_ActionListIM instance pool, so harvesting a later
    -- submenu (e.g. Casus Belli) ResetInstances()es and overwrites the very
    -- controls an earlier submenu (e.g. Ask For Promise) captured. Snapshot the
    -- label/tooltip/disabled as values here -- while the pooled control still
    -- holds this submenu's data -- instead of reading the recycled control live.
    for _, subEntry in ipairs(SyncSubActionsForEntry(entry)) do
        if not subEntry.IsCancel then
            local callback = subEntry.Callback
            local label    = ControlText(subEntry.LabelControl)
            local tooltip  = ControlTooltip(subEntry.Button)
            local disabled = ControlIsDisabled(subEntry.Button)
            local child    = mgr:CreateWidget(
                mgr:GenerateWidgetId("CAIDiplomacySubActionButton"), "Button", {
                    Label             = function() return label end,
                    Tooltip           = function() return tooltip end,
                    DisabledPredicate = function() return disabled end,
                })
            PlayHoverSound(child)
            child:On("activate", function()
                if callback then callback() end
            end)
            sub:AddChild(child)
        end
    end

    return sub
end

local function RebuildActionsList()
    if not m_ui.actionsList then return end
    -- During a transition away from the overview (vanilla SelectPlayer rebuilds
    -- the statement list and only THEN flips to conversation/cinema/deal), the
    -- caller is about to hand focus to the conversation list / a pushed context.
    -- Skip our focus restore for that pass -- a nil capture makes every
    -- RestoreFocus below a no-op -- so the actions list doesn't audibly land on
    -- a leftover button (e.g. Casus Belli) before the real destination speaks.
    local capture = (not m_state.suppressActionsFocus)
        and mgr:CaptureFocusKey(m_ui.actionsList) or nil
    m_ui.actionsList:ClearChildren()

    if IsSelfSelected() then
        -- Keep the action list in the tab chain (so Shift+Tab from the switch-view
        -- button still lands here) with a read-only "no actions" entry for self.
        m_ui.actionsList:AddChild(mgr:CreateWidget("CAIDiplomacyNoActions", "Button", {
            Label             = function() return Locale.Lookup("LOC_CAI_DIPLOMACY_NO_ACTIONS") end,
            DisabledPredicate = function() return true end,
        }))
        mgr:RestoreFocus(m_ui.actionsList, capture)
        return
    end

    if m_LiteMode then
        m_ui.actionsList:AddChild(mgr:CreateWidget("CAIDiplomacyNoActions", "Button", {
            Label             = function() return Locale.Lookup("LOC_CAI_DIPLOMACY_NO_ACTIONS") end,
            DisabledPredicate = function() return true end,
        }))
        mgr:RestoreFocus(m_ui.actionsList, capture)
        return
    end

    for _, entry in ipairs(m_vanilla.actionLists.root or {}) do
        if entry.Selection and entry.Selection.Key == nil and entry.Callback then
            m_ui.actionsList:AddChild(CreateActionSubMenu(entry))
        else
            m_ui.actionsList:AddChild(CreateActionButton(entry))
        end
    end

    if not m_ui.actionsList.Children or #m_ui.actionsList.Children == 0 then
        m_ui.actionsList:AddChild(mgr:CreateWidget("CAIDiplomacyNoActions", "Button", {
            Label             = function() return Locale.Lookup("LOC_CAI_DIPLOMACY_NO_ACTIONS") end,
            DisabledPredicate = function() return true end,
        }))
    end

    mgr:RestoreFocus(m_ui.actionsList, capture)
end

-- ============================================================================
-- Intel: hand-authored readers (clean output for the well-known vanilla tabs).
-- These read the live game state / captured typed instances, matching vanilla.
-- ============================================================================

local function AddTextLineChildren(parent, text)
    for _, line in ipairs(SplitLines(text)) do
        parent:AddChild(CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyLine"), line, nil))
    end
end

local function JoinLines(lines)
    local out = {}
    for _, line in ipairs(lines or {}) do
        local normalized = NormalizeText(line)
        if normalized ~= "" then
            table.insert(out, normalized)
        end
    end
    return table.concat(out, "[NEWLINE]")
end

local function AppendSectionLines(lines, title, entries)
    if not entries or #entries == 0 then
        return
    end

    if title and title ~= "" then
        table.insert(lines, title)
    end
    for _, entry in ipairs(entries) do
        local normalized = NormalizeText(entry)
        if normalized ~= "" then
            table.insert(lines, normalized)
        end
    end
end

local function GetRelationshipData(targetID)
    local selectedID = targetID or ms_SelectedPlayerID
    local selectedPlayer = selectedID ~= nil and Players[selectedID] or nil
    local selectedPlayerDiplomaticAI = selectedPlayer and selectedPlayer.GetDiplomaticAI and
        selectedPlayer:GetDiplomaticAI() or nil
    if not selectedPlayerDiplomaticAI then return nil end

    local stateIndex = selectedPlayerDiplomaticAI:GetDiplomaticStateIndex(ms_LocalPlayerID)
    local stateInfo = GameInfo.DiplomaticStates[stateIndex]
    if not stateInfo then return nil end

    local relationshipLabel = Locale.Lookup(stateInfo.Name)
    if Players[ms_LocalPlayerID]:GetTeam() == Players[selectedID]:GetTeam() then
        relationshipLabel = "(" ..
            Locale.Lookup("LOC_WORLD_RANKINGS_TEAM", Players[ms_LocalPlayerID]:GetTeam()) ..
            ") " .. relationshipLabel
    end

    local relationshipTooltip = nil
    local localPlayerDiplomacy = ms_LocalPlayer and ms_LocalPlayer.GetDiplomacy and ms_LocalPlayer:GetDiplomacy() or nil
    if localPlayerDiplomacy and stateInfo.StateType == "DIPLO_STATE_DENOUNCED" then
        local ourDenounceTurn = localPlayerDiplomacy:GetDenounceTurn(selectedID)
        local theirDenounceTurn = Players[selectedID]:GetDiplomacy():GetDenounceTurn(ms_LocalPlayerID)
        local playerOrderAdjustment = 0
        if theirDenounceTurn >= ourDenounceTurn then
            if selectedID > ms_LocalPlayerID then
                playerOrderAdjustment = 1
            end
        elseif ms_LocalPlayerID > selectedID then
            playerOrderAdjustment = 1
        end

        local remainingTurns
        if ourDenounceTurn >= theirDenounceTurn then
            remainingTurns = 1 + ourDenounceTurn + Game.GetGameDiplomacy():GetDenounceTimeLimit()
                - Game.GetCurrentGameTurn() + playerOrderAdjustment
            relationshipTooltip = Locale.Lookup("LOC_DIPLOMACY_DENOUNCED_TOOLTIP",
                PlayerConfigurations[ms_LocalPlayerID]:GetCivilizationShortDescription(),
                PlayerConfigurations[selectedID]:GetCivilizationShortDescription())
        else
            remainingTurns = 1 + theirDenounceTurn + Game.GetGameDiplomacy():GetDenounceTimeLimit()
                - Game.GetCurrentGameTurn() + playerOrderAdjustment
            relationshipTooltip = Locale.Lookup("LOC_DIPLOMACY_DENOUNCED_TOOLTIP",
                PlayerConfigurations[selectedID]:GetCivilizationShortDescription(),
                PlayerConfigurations[ms_LocalPlayerID]:GetCivilizationShortDescription())
        end

        relationshipTooltip = relationshipTooltip .. " ["
            .. Locale.Lookup("LOC_ESPIONAGEPOPUP_TURNS_REMAINING", remainingTurns) .. "]"
    elseif localPlayerDiplomacy and stateInfo.StateType == "DIPLO_STATE_DECLARED_FRIEND" then
        local friendshipTurn = localPlayerDiplomacy:GetDeclaredFriendshipTurn(selectedID)
        local remainingTurns = friendshipTurn + Game.GetGameDiplomacy():GetDenounceTimeLimit() -
            Game.GetCurrentGameTurn()
        relationshipTooltip = Locale.Lookup("LOC_DIPLOMACY_DECLARED_FRIENDSHIP_TOOLTIP",
            PlayerConfigurations[ms_LocalPlayerID]:GetCivilizationShortDescription(),
            PlayerConfigurations[selectedID]:GetCivilizationShortDescription(),
            remainingTurns)
    end

    return {
        StateInfo = stateInfo,
        Label = relationshipLabel,
        Tooltip = relationshipTooltip,
    }
end

local function BuildRelationshipReasonLines(targetID)
    local selectedID = targetID or ms_SelectedPlayerID
    local selectedPlayer = selectedID ~= nil and Players[selectedID] or nil
    local selectedPlayerDiplomaticAI = selectedPlayer and selectedPlayer.GetDiplomaticAI and
        selectedPlayer:GetDiplomaticAI() or nil
    if not selectedPlayerDiplomaticAI then return {} end

    local lines = {}
    local toolTips = selectedPlayerDiplomaticAI:GetDiplomaticModifiers(ms_LocalPlayerID)
    if toolTips then
        table.sort(toolTips, function(a, b) return a.Score > b.Score end)
        for _, tip in ipairs(toolTips) do
            if tip.Score ~= 0 and tip.Text then
                local scoreText = Locale.Lookup("{1_Score : number +#,###.##;-#,###.##}", tip.Score)
                table.insert(lines, JoinNonEmpty({ scoreText, Locale.Lookup(tip.Text) }, " "))
            end
        end
    end
    if #lines == 0 then
        table.insert(lines, Locale.Lookup("LOC_DIPLOMACY_INTEL_RELATIONSHIP_NOTHING_ABJECT"))
    end
    return lines
end

local function BuildRelationshipAdvisorLines(targetID)
    local selectedID = targetID or ms_SelectedPlayerID
    local selectedPlayer = selectedID ~= nil and Players[selectedID] or nil
    local selectedCivName = ""
    local playerConfig = PlayerConfigurations[selectedID]
    if playerConfig then
        selectedCivName = playerConfig:GetCivilizationDescription()
    end

    local raiseLines = {
        Locale.Lookup("LOC_DIPLOMACY_ADVISOR_OFFER"),
        Locale.Lookup("LOC_DIPLOMACY_ADVISOR_TRADE_ROUTE", selectedCivName),
    }
    if not selectedPlayer:GetDiplomacy():HasOpenBordersFrom(ms_LocalPlayer:GetID()) then
        table.insert(raiseLines, Locale.Lookup("LOC_DIPLOMACY_ADVISOR_OPEN_BORDERS", selectedCivName))
    end
    if not ms_LocalPlayer:GetDiplomacy():HasDelegationAt(selectedID)
        and not ms_LocalPlayer:GetDiplomacy():HasEmbassyAt(selectedID) then
        table.insert(raiseLines, Locale.Lookup("LOC_DIPLOMACY_ADVISOR_DELEGATION_EMBASSY"))
    end
    table.insert(raiseLines, Locale.Lookup("LOC_DIPLOMACY_ADVISOR_POSITIVE_AGENDA", selectedCivName))

    local lowerLines = {
        Locale.Lookup("LOC_DIPLOMACY_ADVISOR_NEGATIVE_AGENDA", selectedCivName),
        Locale.Lookup("LOC_DIPLOMACY_ADVISOR_DENOUNCE_THEM"),
        Locale.Lookup("LOC_DIPLOMACY_ADVISOR_REJECT_PROMISE"),
        Locale.Lookup("LOC_DIPLOMACY_ADVISOR_BREAK_PROMISE"),
    }

    return raiseLines, lowerLines
end

local function GetAccessLevelName(targetID)
    local selectedID = targetID or ms_SelectedPlayerID
    local localPlayerDiplomacy = ms_LocalPlayer and ms_LocalPlayer.GetDiplomacy and ms_LocalPlayer:GetDiplomacy() or nil
    if not localPlayerDiplomacy then return "" end
    local accessLevel = localPlayerDiplomacy:GetVisibilityOn(selectedID)
    local visibility = GameInfo.Visibilities[accessLevel]
    return visibility and Locale.Lookup(visibility.Name) or ""
end

local function BuildActiveVisibilitySourceLines(targetID)
    local selectedID = targetID or ms_SelectedPlayerID
    local localPlayerDiplomacy = ms_LocalPlayer and ms_LocalPlayer.GetDiplomacy and ms_LocalPlayer:GetDiplomacy() or nil
    if not localPlayerDiplomacy then return {} end

    local lines = {}
    for row in GameInfo.DiplomaticVisibilitySources() do
        if localPlayerDiplomacy:IsVisibilitySourceActive(selectedID, row.Index) and row.Description then
            table.insert(lines, Locale.Lookup(row.Description))
        end
    end
    return lines
end

local function BuildInformationSharedLines(offset, targetID)
    local selectedID = targetID or ms_SelectedPlayerID
    local localPlayerDiplomacy = ms_LocalPlayer and ms_LocalPlayer.GetDiplomacy and ms_LocalPlayer:GetDiplomacy() or nil
    if not localPlayerDiplomacy then return {} end

    local accessLevel = localPlayerDiplomacy:GetVisibilityOn(selectedID) + (offset or 0)
    local lines = {}
    for row in GameInfo.Gossips() do
        if row.VisibilityLevel == accessLevel and row.Description then
            table.insert(lines, Locale.Lookup(row.Description))
        end
    end
    return lines
end

local function BuildAccessAdvisorLines(targetID)
    if not GameCapabilities.HasCapability("CAPABILITY_DIPLOMACY_ACCESS_LEVEL_INFO") then
        return {}
    end

    local selectedID = targetID or ms_SelectedPlayerID
    local localPlayerDiplomacy = ms_LocalPlayer and ms_LocalPlayer.GetDiplomacy and ms_LocalPlayer:GetDiplomacy() or nil
    if not localPlayerDiplomacy then return {} end

    local lines = {}
    for row in GameInfo.DiplomaticVisibilitySources() do
        if not localPlayerDiplomacy:IsVisibilitySourceActive(selectedID, row.Index) and row.ActionDescription then
            table.insert(lines, Locale.Lookup(row.ActionDescription))
        end
    end
    return lines
end

local function BuildAccessSectionTooltip(targetID)
    local lines = {}
    AppendSectionLines(lines, Locale.Lookup("LOC_CAI_DIPLOMACY_ACTIVE_SOURCES"), BuildActiveVisibilitySourceLines(targetID))
    AppendSectionLines(lines, Locale.Lookup("LOC_DIPLOMACY_INTEL_INFORMATION_SHARED_HEADER"),
        BuildInformationSharedLines(0, targetID))
    if GameCapabilities.HasCapability("CAPABILITY_DIPLOMACY_ACCESS_LEVEL_INFO") then
        AppendSectionLines(lines, Locale.Lookup("LOC_DIPLOMACY_INTEL_NEXT_ACCESS_LEVEL_HEADER"),
            BuildInformationSharedLines(1, targetID))
    end
    AppendSectionLines(lines, Locale.Lookup("LOC_DIPLOMACY_INTEL_GAIN_ACCESS_LEVEL_HEADER"), BuildAccessAdvisorLines(targetID))
    return JoinLines(lines)
end

local function BuildRelationshipSectionTooltip(targetID)
    local relationship = GetRelationshipData(targetID)
    return relationship and JoinTooltipLines(relationship.Tooltip or "") or ""
end

local function BuildGossipSectionTooltip(targetID)
    local selectedID = targetID or ms_SelectedPlayerID
    local gossipManager = Game.GetGossipManager()
    local currentTurn = Game.GetCurrentGameTurn()
    local earliestTurn = currentTurn - 100
    local gossipItems = gossipManager and gossipManager.GetRecentVisibleGossipStrings and
        gossipManager:GetRecentVisibleGossipStrings(earliestTurn, ms_LocalPlayerID, selectedID) or {}
    local recentLines = {}
    local olderLines = {}

    for _, gossipItem in ipairs(gossipItems) do
        local gossipText = gossipItem[1]
        local gossipTurn = gossipItem[2]
        if gossipText then
            local label = gossipText
            if gossipTurn and (currentTurn - 1) <= gossipTurn then
                label = "[ICON_New] " .. label
            end

            if gossipTurn and (currentTurn - gossipTurn) <= 10 then
                table.insert(recentLines, label)
            else
                table.insert(olderLines, label)
            end
        end
    end

    if #recentLines == 0 then
        table.insert(recentLines, Locale.Lookup("LOC_DIPLOMACY_GOSSIP_ITEM_NO_RECENT"))
    end

    local lines = {}
    AppendSectionLines(lines, Locale.Lookup("LOC_DIPLOMACY_INTEL_LAST_TEN_TURNS"), recentLines)
    AppendSectionLines(lines, Locale.Lookup("LOC_DIPLOMACY_INTEL_OLDER"), olderLines)
    return JoinLines(lines)
end

local function BuildAgendaSummaryLines(playerID, selectedPlayer)
    playerID = playerID or ms_SelectedPlayerID
    selectedPlayer = selectedPlayer or ms_SelectedPlayer
    local playerConfig = PlayerConfigurations[playerID]
    if not playerConfig or playerConfig:IsHuman() then
        return {}
    end

    local lines = {}
    local seenAgendaTypes = {}
    local leaderType = playerConfig:GetLeaderTypeName()
    local function AddAgendaLine(agendaType)
        if not agendaType or seenAgendaTypes[agendaType] then
            return false
        end

        local agenda = GameInfo.Agendas[agendaType]
        if not agenda then
            return false
        end

        seenAgendaTypes[agendaType] = true
        table.insert(lines, Locale.Lookup(agenda.Name) .. ": " .. Locale.Lookup(agenda.Description))
        return true
    end

    local localPlayerDiplomacy = ms_LocalPlayer and ms_LocalPlayer.GetDiplomacy and ms_LocalPlayer:GetDiplomacy() or nil
    local accessLevel = localPlayerDiplomacy and localPlayerDiplomacy:GetVisibilityOn(playerID) or -1

    if selectedPlayer and selectedPlayer.GetAgendasAndVisibilities then
        local agendas = selectedPlayer:GetAgendasAndVisibilities() or {}
        local hiddenCount = 0
        local shownCount = 0
        for _, entry in ipairs(agendas) do
            if entry.Visibility <= accessLevel then
                if AddAgendaLine(entry.Agenda) then
                    shownCount = shownCount + 1
                end
            else
                hiddenCount = hiddenCount + 1
            end
        end
        if hiddenCount > 0 then
            table.insert(lines, Locale.Lookup("LOC_DIPLOMACY_HIDDEN_AGENDAS", hiddenCount, hiddenCount > 1))
        elseif shownCount == 0 then
            table.insert(lines, Locale.Lookup("LOC_DIPLOMACY_RANDOM_AGENDA_NONE"))
        end
        return lines
    end

    for row in GameInfo.HistoricalAgendas() do
        if row.LeaderType == leaderType then
            AddAgendaLine(row.AgendaType)
            break
        end
    end

    local revealRandom = false
    for row in GameInfo.Visibilities() do
        if row.Index <= accessLevel and row.RevealAgendas == true then
            revealRandom = true
        end
    end

    local agendaTypes = selectedPlayer and selectedPlayer.GetAgendaTypes and selectedPlayer:GetAgendaTypes() or {}
    table.remove(agendaTypes, 1)
    if #agendaTypes > 0 then
        if revealRandom then
            for _, agendaType in ipairs(agendaTypes) do
                AddAgendaLine(agendaType)
            end
        else
            table.insert(lines, Locale.Lookup("LOC_DIPLOMACY_HIDDEN_AGENDAS", #agendaTypes, #agendaTypes > 1))
        end
    else
        table.insert(lines, Locale.Lookup("LOC_DIPLOMACY_RANDOM_AGENDA_NONE"))
    end
    return lines
end

local function BuildLeaderOverviewTooltip(playerID)
    playerID = playerID or ms_SelectedPlayerID
    local selectedPlayer = Players[playerID]
    local playerConfig = PlayerConfigurations[playerID]
    if not selectedPlayer or not playerConfig then
        return ""
    end

    local lines = {}

    if not playerConfig:IsHuman() then
        local relationshipLabel = Locale.Lookup(GameInfo.DiplomaticStates
        [selectedPlayer:GetDiplomaticAI():GetDiplomaticStateIndex(ms_LocalPlayerID)].Name)
        if Players[ms_LocalPlayerID]:GetTeam() == Players[playerID]:GetTeam() then
            relationshipLabel = "(" ..
                Locale.Lookup("LOC_WORLD_RANKINGS_TEAM", Players[ms_LocalPlayerID]:GetTeam()) ..
                ") " .. relationshipLabel
        end
        table.insert(lines, Locale.Lookup("LOC_DIPLOMACY_OVERVIEW_OUR_RELATIONSHIP") .. ": " .. relationshipLabel)
    end

    local localPlayerDiplomacy = ms_LocalPlayer and ms_LocalPlayer.GetDiplomacy and ms_LocalPlayer:GetDiplomacy() or nil
    if localPlayerDiplomacy then
        local accessLevel = localPlayerDiplomacy:GetVisibilityOn(playerID)
        local visibility = GameInfo.Visibilities[accessLevel]
        table.insert(lines, Locale.Lookup("LOC_DIPLOMACY_OVERVIEW_ACCESS_LEVEL") .. ": "
            .. (visibility and Locale.Lookup(visibility.Name) or ""))
    end

    local governmentText = Locale.Lookup("LOC_DIPLOMACY_GOVERNMENT_NONE")
    local selectedCulture = selectedPlayer.GetCulture and selectedPlayer:GetCulture() or nil
    local selectedGovernment = selectedCulture and selectedCulture:GetCurrentGovernment() or -1
    if selectedGovernment ~= -1 and GameInfo.Governments[selectedGovernment] then
        governmentText = Locale.Lookup(GameInfo.Governments[selectedGovernment].Name)
    elseif selectedCulture and selectedCulture:IsInAnarchy() then
        governmentText = Locale.Lookup("LOC_GOVERNMENT_ANARCHY_TURNS",
            selectedCulture:GetAnarchyEndTurn() - Game.GetCurrentGameTurn())
    end
    table.insert(lines, Locale.Lookup("LOC_DIPLOMACY_OVERVIEW_GOVERNMENT") .. ": " .. governmentText)

    local gossipCount = CountEntries(Game.GetGossipManager():GetRecentVisibleGossipStrings(
        Game.GetCurrentGameTurn() - 1,
        ms_LocalPlayerID,
        playerID))
    local gossipText = gossipCount > 0
        and Locale.Lookup("LOC_DIPLOMACY_GOSSIP_ITEM_COUNT", gossipCount)
        or Locale.Lookup("LOC_DIPLOMACY_GOSSIP_ITEM_NONE_THIS_TURN")
    table.insert(lines, Locale.Lookup("LOC_DIPLOMACY_OVERVIEW_GOSSIP") .. ": " .. gossipText)

    if IsSecretSocietiesActive() then
        local selectedGovernors = selectedPlayer.GetGovernors and selectedPlayer:GetGovernors() or nil
        if selectedGovernors and selectedGovernors.GetSecretSociety then
            local society = selectedGovernors:GetSecretSociety()
            local label = Locale.Lookup("LOC_SECRETSOCIETY_DIPLO_NONE_NAME")
            if society ~= -1 then
                if selectedGovernors:IsAwareOfSecretSociety(society) and GameInfo.SecretSocieties[society] then
                    label = Locale.Lookup(GameInfo.SecretSocieties[society].Name)
                else
                    label = Locale.Lookup("LOC_SECRETSOCIETY_DIPLO_UNKNOWN_NAME")
                end
            end
            table.insert(lines, Locale.Lookup("LOC_SECRETSOCIETY") .. ": " .. label)
        end
    end

    local agendaLines = BuildAgendaSummaryLines(playerID, selectedPlayer)
    if #agendaLines > 0 then
        table.insert(lines, Locale.Lookup("LOC_DIPLOMACY_OVERVIEW_AGENDAS"))
        for _, line in ipairs(agendaLines) do
            table.insert(lines, line)
        end
    end

    return JoinLines(lines)
end

local function BuildSelfLeaderTooltip(playerID)
    local playerConfig = PlayerConfigurations[playerID]
    if not playerConfig then return "" end

    local lines = {
        Locale.Lookup(playerConfig:GetLeaderName()) .. ", " ..
            Locale.Lookup(playerConfig:GetCivilizationDescription()),
    }

    local civType = playerConfig:GetCivilizationTypeName()
    local leaderType = playerConfig:GetLeaderTypeName()
    local leaderAbilities = {}
    local leaderUnits = {}
    local leaderBuildings = {}
    local civAbilities = {}
    local civUnits = {}
    local civBuildings = {}
    if leaderType then
        leaderAbilities, leaderUnits, leaderBuildings = GetLeaderUniqueTraits(leaderType, true)
    end
    if civType then
        civAbilities, civUnits, civBuildings = GetCivilizationUniqueTraits(civType, true)
    end

    if civAbilities[1] then
        table.insert(lines, Locale.Lookup("LOC_CAI_ADVANCED_SETUP_CIV_ABILITY") .. ": "
            .. Locale.Lookup(civAbilities[1].Name) .. ": "
            .. Locale.Lookup(civAbilities[1].Description or ""))
    end
    if leaderAbilities[1] then
        table.insert(lines, Locale.Lookup("LOC_CAI_ADVANCED_SETUP_LEADER_ABILITY") .. ": "
            .. Locale.Lookup(leaderAbilities[1].Name) .. ": "
            .. Locale.Lookup(leaderAbilities[1].Description or ""))
    end
    local uniqueUnits = {}
    local uniqueBuildings = {}
    for _, item in ipairs(civUnits or {}) do table.insert(uniqueUnits, item) end
    for _, item in ipairs(leaderUnits or {}) do table.insert(uniqueUnits, item) end
    for _, item in ipairs(civBuildings or {}) do table.insert(uniqueBuildings, item) end
    for _, item in ipairs(leaderBuildings or {}) do table.insert(uniqueBuildings, item) end
    if #uniqueUnits > 0 then
        table.insert(lines, Locale.Lookup(#uniqueUnits > 1 and "LOC_CAI_UNIQUE_UNITS" or "LOC_CAI_UNIQUE_UNIT"))
        for _, item in ipairs(uniqueUnits) do
            table.insert(lines, Locale.Lookup(item.Name) .. ": " .. Locale.Lookup(item.Description or ""))
        end
    end
    if #uniqueBuildings > 0 then
        table.insert(lines,
            Locale.Lookup(#uniqueBuildings > 1 and "LOC_CAI_UNIQUE_BUILDINGS" or "LOC_CAI_UNIQUE_BUILDING"))
        for _, item in ipairs(uniqueBuildings) do
            table.insert(lines, Locale.Lookup(item.Name) .. ": " .. Locale.Lookup(item.Description or ""))
        end
    end

    return JoinLines(lines)
end

local function IsSelectedPlayerInCrisis(crisis)
    if crisis.TargetID == ms_SelectedPlayerID then return true end
    for _, memberID in ipairs(crisis.MemberIDs) do
        if memberID == ms_SelectedPlayerID then return true end
    end
    return false
end

local function AddOverviewChildren(node)
    local gossipCount = CountEntries(Game.GetGossipManager():GetRecentVisibleGossipStrings(
        Game.GetCurrentGameTurn() - 1,
        ms_LocalPlayerID,
        ms_SelectedPlayerID))
    local gossipText = gossipCount > 0
        and Locale.Lookup("LOC_DIPLOMACY_GOSSIP_ITEM_COUNT", gossipCount)
        or Locale.Lookup("LOC_DIPLOMACY_GOSSIP_ITEM_NONE_THIS_TURN")
    node:AddChild(CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyOverviewGossip"),
        Locale.Lookup("LOC_DIPLOMACY_OVERVIEW_GOSSIP") .. ": " .. gossipText, nil))

    local localPlayerDiplomacy = ms_LocalPlayer and ms_LocalPlayer.GetDiplomacy and ms_LocalPlayer:GetDiplomacy() or nil
    local accessLevel = localPlayerDiplomacy and localPlayerDiplomacy:GetVisibilityOn(ms_SelectedPlayerID) or -1
    local accessName = accessLevel >= 0 and GameInfo.Visibilities[accessLevel]
        and Locale.Lookup(GameInfo.Visibilities[accessLevel].Name) or ""
    node:AddChild(CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyOverviewAccess"),
        Locale.Lookup("LOC_DIPLOMACY_OVERVIEW_ACCESS_LEVEL") .. ": " .. accessName, nil))

    local governmentText = Locale.Lookup("LOC_DIPLOMACY_GOVERNMENT_NONE")
    local selectedCulture = ms_SelectedPlayer and ms_SelectedPlayer.GetCulture and ms_SelectedPlayer:GetCulture() or nil
    local selectedGovernment = selectedCulture and selectedCulture:GetCurrentGovernment() or -1
    if selectedGovernment ~= -1 and GameInfo.Governments[selectedGovernment] then
        governmentText = Locale.Lookup(GameInfo.Governments[selectedGovernment].Name)
    elseif selectedCulture and selectedCulture:IsInAnarchy() then
        governmentText = Locale.Lookup("LOC_GOVERNMENT_ANARCHY_TURNS",
            selectedCulture:GetAnarchyEndTurn() - Game.GetCurrentGameTurn())
    end
    node:AddChild(CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyOverviewGovernment"),
        Locale.Lookup("LOC_DIPLOMACY_OVERVIEW_GOVERNMENT") .. ": " .. governmentText, nil))

    if not PlayerConfigurations[ms_SelectedPlayerID]:IsHuman() then
        local agendasNode = CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyOverviewAgendas"),
            Locale.Lookup("LOC_DIPLOMACY_OVERVIEW_AGENDAS"), nil)

        local leaderType = PlayerConfigurations[ms_SelectedPlayerID]:GetLeaderTypeName()
        for row in GameInfo.HistoricalAgendas() do
            if row.LeaderType == leaderType then
                local agenda = GameInfo.Agendas[row.AgendaType]
                if agenda then
                    agendasNode:AddChild(CreateReadOnlyNode(
                        mgr:GenerateWidgetId("CAIDiplomacyOverviewAgendaEntry"),
                        Locale.Lookup(agenda.Name),
                        Locale.Lookup(agenda.Description)))
                    break
                end
            end
        end

        local revealRandom = false
        if localPlayerDiplomacy then
            for row in GameInfo.Visibilities() do
                if row.Index <= accessLevel and row.RevealAgendas == true then
                    revealRandom = true
                end
            end
        end

        local agendaTypes = ms_SelectedPlayer:GetAgendaTypes() or {}
        table.remove(agendaTypes, 1)
        local randomCount = CountEntries(agendaTypes)
        if randomCount > 0 then
            if revealRandom then
                for _, agendaType in ipairs(agendaTypes) do
                    local agenda = GameInfo.Agendas[agendaType]
                    if agenda then
                        agendasNode:AddChild(CreateReadOnlyNode(
                            mgr:GenerateWidgetId("CAIDiplomacyOverviewAgendaEntry"),
                            Locale.Lookup(agenda.Name),
                            Locale.Lookup(agenda.Description)))
                    end
                end
            else
                agendasNode:AddChild(CreateReadOnlyNode(
                    mgr:GenerateWidgetId("CAIDiplomacyOverviewAgendaEntry"),
                    Locale.Lookup("LOC_DIPLOMACY_HIDDEN_AGENDAS", randomCount, randomCount > 1),
                    Locale.Lookup("LOC_DIPLOMACY_HIDDEN_AGENDAS_TT")))
            end
        elseif randomCount == 0 then
            agendasNode:AddChild(CreateReadOnlyNode(
                mgr:GenerateWidgetId("CAIDiplomacyOverviewAgendaEntry"),
                Locale.Lookup("LOC_DIPLOMACY_RANDOM_AGENDA_NONE"),
                nil))
        end

        if agendasNode.Children and #agendasNode.Children > 0 then
            node:AddChild(agendasNode)
        end
    end

    if localPlayerDiplomacy then
        local agreementsNode = CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyOverviewAgreements"),
            Locale.Lookup("LOC_DIPLOMACY_OVERVIEW_AGREEMENTS"), nil)
        local agreements = {}

        if localPlayerDiplomacy:HasDelegationAt(ms_SelectedPlayer:GetID()) then
            table.insert(agreements, Locale.Lookup("LOC_DIPLO_MODIFIER_DELEGATION"))
        end
        if localPlayerDiplomacy:HasEmbassyAt(ms_SelectedPlayer:GetID()) then
            table.insert(agreements, Locale.Lookup("LOC_DIPLO_MODIFIER_RESIDENT_EMBASSY"))
        end
        if localPlayerDiplomacy:HasDefensivePact(ms_SelectedPlayer:GetID()) then
            table.insert(agreements, Locale.Lookup("LOC_DIPLO_MODIFIER_DEFENSIVE_PACT"))
        end
        if localPlayerDiplomacy:HasOpenBordersFrom(ms_SelectedPlayer:GetID()) then
            table.insert(agreements, Locale.Lookup("LOC_DIPLO_MODIFIER_RECEIVED_OPEN_BORDERS"))
        end
        if ms_SelectedPlayer:GetDiplomacy():HasOpenBordersFrom(ms_LocalPlayer:GetID()) then
            table.insert(agreements, Locale.Lookup("LOC_DIPLO_MODIFIER_GAVE_OPEN_BORDERS"))
        end
        if localPlayerDiplomacy:GetResearchAgreementTech(ms_SelectedPlayer:GetID()) ~= -1 then
            table.insert(agreements, Locale.Lookup("LOC_DIPLOACTION_RESEARCH_AGREEMENT_NAME"))
        end
        if localPlayerDiplomacy:IsFightingAnyJointWarWith(ms_SelectedPlayer:GetID()) then
            table.insert(agreements, Locale.Lookup("LOC_DIPLOACTION_JOINT_WAR_NAME"))
        end

        for _, label in ipairs(agreements) do
            agreementsNode:AddChild(CreateReadOnlyNode(
                mgr:GenerateWidgetId("CAIDiplomacyOverviewAgreementEntry"),
                label,
                label))
        end

        if agreementsNode.Children and #agreementsNode.Children > 0 then
            node:AddChild(agreementsNode)
        end
    end

    if not PlayerConfigurations[ms_SelectedPlayerID]:IsHuman() then
        local selectedPlayerDiplomaticAI = ms_SelectedPlayer:GetDiplomaticAI()
        local stateIndex = selectedPlayerDiplomaticAI:GetDiplomaticStateIndex(ms_LocalPlayerID)
        local relationshipLabel = Locale.Lookup(GameInfo.DiplomaticStates[stateIndex].Name)
        if Players[ms_LocalPlayerID]:GetTeam() == Players[ms_SelectedPlayerID]:GetTeam() then
            relationshipLabel = "(" ..
                Locale.Lookup("LOC_WORLD_RANKINGS_TEAM", Players[ms_LocalPlayerID]:GetTeam()) ..
                ") " .. relationshipLabel
        end

        local relationshipTooltip = nil
        if localPlayerDiplomacy and GameInfo.DiplomaticStates[stateIndex].StateType == "DIPLO_STATE_DENOUNCED" then
            local ourDenounceTurn = localPlayerDiplomacy:GetDenounceTurn(ms_SelectedPlayerID)
            local theirDenounceTurn = Players[ms_SelectedPlayerID]:GetDiplomacy():GetDenounceTurn(ms_LocalPlayerID)
            local playerOrderAdjustment = 0
            if theirDenounceTurn >= ourDenounceTurn then
                if ms_SelectedPlayerID > ms_LocalPlayerID then
                    playerOrderAdjustment = 1
                end
            elseif ms_LocalPlayerID > ms_SelectedPlayerID then
                playerOrderAdjustment = 1
            end

            local remainingTurns
            if ourDenounceTurn >= theirDenounceTurn then
                remainingTurns = 1 + ourDenounceTurn + Game.GetGameDiplomacy():GetDenounceTimeLimit()
                    - Game.GetCurrentGameTurn() + playerOrderAdjustment
                relationshipTooltip = Locale.Lookup("LOC_DIPLOMACY_DENOUNCED_TOOLTIP",
                    PlayerConfigurations[ms_LocalPlayerID]:GetCivilizationShortDescription(),
                    PlayerConfigurations[ms_SelectedPlayerID]:GetCivilizationShortDescription())
            else
                remainingTurns = 1 + theirDenounceTurn + Game.GetGameDiplomacy():GetDenounceTimeLimit()
                    - Game.GetCurrentGameTurn() + playerOrderAdjustment
                relationshipTooltip = Locale.Lookup("LOC_DIPLOMACY_DENOUNCED_TOOLTIP",
                    PlayerConfigurations[ms_SelectedPlayerID]:GetCivilizationShortDescription(),
                    PlayerConfigurations[ms_LocalPlayerID]:GetCivilizationShortDescription())
            end

            relationshipTooltip = relationshipTooltip .. " ["
                .. Locale.Lookup("LOC_ESPIONAGEPOPUP_TURNS_REMAINING", remainingTurns) .. "]"
        elseif localPlayerDiplomacy and GameInfo.DiplomaticStates[stateIndex].StateType == "DIPLO_STATE_DECLARED_FRIEND" then
            local friendshipTurn = localPlayerDiplomacy:GetDeclaredFriendshipTurn(ms_SelectedPlayerID)
            local remainingTurns = friendshipTurn + Game.GetGameDiplomacy():GetDenounceTimeLimit() -
                Game.GetCurrentGameTurn()
            relationshipTooltip = Locale.Lookup("LOC_DIPLOMACY_DECLARED_FRIENDSHIP_TOOLTIP",
                PlayerConfigurations[ms_LocalPlayerID]:GetCivilizationShortDescription(),
                PlayerConfigurations[ms_SelectedPlayerID]:GetCivilizationShortDescription(),
                remainingTurns)
        end

        node:AddChild(CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyOverviewOurRelationship"),
            Locale.Lookup("LOC_DIPLOMACY_OVERVIEW_OUR_RELATIONSHIP") .. ": " .. relationshipLabel,
            relationshipTooltip))
    end

    local relationshipsNode = CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyOverviewOtherRelationships"),
        Locale.Lookup("LOC_DIPLOMACY_OVERVIEW_OTHER_RELATIONSHIPS"), nil)
    local selectedPlayerDiplomacy = ms_SelectedPlayer and ms_SelectedPlayer.GetDiplomacy and
        ms_SelectedPlayer:GetDiplomacy() or nil
    if localPlayerDiplomacy and selectedPlayerDiplomacy then
        for _, player in ipairs(PlayerManager.GetAliveMajors()) do
            local playerID = player:GetID()
            if player:IsMajor()
                and playerID ~= ms_LocalPlayerID
                and playerID ~= ms_SelectedPlayer:GetID()
                and selectedPlayerDiplomacy:HasMet(playerID) then
                local relationState = player:GetDiplomaticAI():GetDiplomaticStateIndex(ms_SelectedPlayer:GetID())
                local relationInfo = GameInfo.DiplomaticStates[relationState]
                if relationInfo and relationInfo.Hash ~= DiplomaticStates.NEUTRAL then
                    local isHumanRelation = not (ms_SelectedPlayer:IsAI() or player:IsAI())
                    local relationType = relationInfo.StateType
                    local isValid = (isHumanRelation and Relationship.IsValidWithHuman(relationType))
                        or ((not isHumanRelation) and Relationship.IsValidWithAI(relationType))
                    if isValid then
                        local otherConfig = PlayerConfigurations[playerID]
                        local civLabel
                        if localPlayerDiplomacy:HasMet(playerID) then
                            civLabel = Locale.Lookup("LOC_DIPLOMACY_DEAL_PLAYER_PANEL_TITLE",
                                otherConfig:GetLeaderName(),
                                otherConfig:GetCivilizationDescription())
                        else
                            civLabel = Locale.Lookup("LOC_DIPLOPANEL_UNMET_PLAYER")
                        end
                        local relationLabel = Locale.Lookup(relationInfo.Name)
                        relationshipsNode:AddChild(CreateReadOnlyNode(
                            mgr:GenerateWidgetId("CAIDiplomacyOtherRelationshipEntry"),
                            civLabel .. ": " .. relationLabel,
                            relationLabel))
                    end
                end
            end
        end
    end
    if relationshipsNode.Children and #relationshipsNode.Children > 0 then
        node:AddChild(relationshipsNode)
    end

    if IsExpansion1Active() then
        local emergencyMgr = Game.GetEmergencyManager()
        local crisisData = emergencyMgr and emergencyMgr.GetEmergencyInfoTable
            and emergencyMgr:GetEmergencyInfoTable(ms_LocalPlayerID) or {}
        local emergencyNames = {}
        for _, crisis in ipairs(crisisData) do
            if crisis.HasBegun and IsSelectedPlayerInCrisis(crisis) then
                local localInvolved = crisis.TargetID == ms_LocalPlayerID
                if not localInvolved then
                    for _, memberID in ipairs(crisis.MemberIDs) do
                        if memberID == ms_LocalPlayerID then
                            localInvolved = true
                            break
                        end
                    end
                end
                if localInvolved then
                    table.insert(emergencyNames, Locale.Lookup(crisis.NameText))
                end
            end
        end
        if #emergencyNames > 0 then
            node:AddChild(CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyOverviewEmergency"),
                Locale.Lookup("LOC_CAI_DIPLOMACY_OVERVIEW_EMERGENCY",
                    table.concat(emergencyNames, "[NEWLINE]")), nil))
        end
    end

    -- Secret Society (Ethiopia game mode). Vanilla injects this as an overview ROW
    -- via DiploScene_RefreshOverviewRows (DiplomacyActionView_SecretSocietyRow), not
    -- as an intel tab, so it lives here rather than as its own reader. That addon is
    -- a separate context whose Controls we cannot read, so rebuild from the governors
    -- API. The vanilla row checks awareness against the SELECTED player's own governors
    -- (a leader is always aware of their own society), so the real society name shows
    -- on screen once a leader has joined one; replicated here for screen parity.
    if IsSecretSocietiesActive() then
        local selectedGovernors = ms_SelectedPlayer and ms_SelectedPlayer.GetGovernors
            and ms_SelectedPlayer:GetGovernors() or nil
        if selectedGovernors and selectedGovernors.GetSecretSociety then
            local society = selectedGovernors:GetSecretSociety()
            local label, tooltip
            if society ~= -1 then
                if selectedGovernors:IsAwareOfSecretSociety(society) and GameInfo.SecretSocieties[society] then
                    label = Locale.Lookup(GameInfo.SecretSocieties[society].Name)
                else
                    label = Locale.Lookup("LOC_SECRETSOCIETY_DIPLO_UNKNOWN_NAME")
                    tooltip = Locale.Lookup("LOC_SECRETSOCIETY_DIPLO_UNKNOWN_DESCRIPTION")
                end
            else
                label = Locale.Lookup("LOC_SECRETSOCIETY_DIPLO_NONE_NAME")
            end
            node:AddChild(CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyOverviewSecretSociety"),
                Locale.Lookup("LOC_SECRETSOCIETY") .. ": " .. label, tooltip))
        end
    end
end

-- Format one gossip line with its turn (and leader), reusing the reports screen's
-- gossip-entry string so every gossip line reads the same way everywhere.
local function FormatGossipLine(targetID, turn, text, isNew)
    if isNew then text = "[ICON_New] " .. text end
    local config = PlayerConfigurations[targetID or ms_SelectedPlayerID]
    local leaderName = config and Locale.Lookup(config:GetLeaderName()) or ""
    return Locale.Lookup("LOC_CAI_REPORTS_GOSSIP_ENTRY", turn or 0, leaderName, text)
end

local function AddGossipChildren(node)
    local recentNode = CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyRecentGossip"),
        Locale.Lookup("LOC_DIPLOMACY_INTEL_LAST_TEN_TURNS"), nil)
    local olderNode = CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyOlderGossip"),
        Locale.Lookup("LOC_DIPLOMACY_INTEL_OLDER"), nil)

    local gossipManager = Game.GetGossipManager()
    local currentTurn = Game.GetCurrentGameTurn()
    local earliestTurn = currentTurn - 100
    local gossipItems = gossipManager and gossipManager.GetRecentVisibleGossipStrings and
        gossipManager:GetRecentVisibleGossipStrings(earliestTurn, ms_LocalPlayerID, ms_SelectedPlayerID) or {}

    local addedRecent = false
    local addedOlder = false
    for _, gossipItem in ipairs(gossipItems) do
        local gossipText = gossipItem[1]
        local gossipTurn = gossipItem[2]
        local gossipData = GameInfo.Gossips[gossipItem[3]]
        local passGroup = m_gossipGroupFilter == "ALL"
            or (gossipData and gossipData.GroupType == m_gossipGroupFilter)
        if gossipText and passGroup then
            local isNew = gossipTurn ~= nil and (currentTurn - 1) <= gossipTurn
            local label = FormatGossipLine(ms_SelectedPlayerID, gossipTurn, gossipText, isNew)

            if gossipTurn and (currentTurn - gossipTurn) <= 10 then
                recentNode:AddChild(CreateReadOnlyText(
                    mgr:GenerateWidgetId("CAIDiplomacyRecentGossipEntry"),
                    label,
                    nil))
                addedRecent = true
            else
                olderNode:AddChild(CreateReadOnlyText(
                    mgr:GenerateWidgetId("CAIDiplomacyOlderGossipEntry"),
                    label,
                    nil))
                addedOlder = true
            end
        end
    end

    if not addedRecent then
        recentNode:AddChild(CreateReadOnlyText(mgr:GenerateWidgetId("CAIDiplomacyRecentGossipEntry"),
            Locale.Lookup("LOC_DIPLOMACY_GOSSIP_ITEM_NO_RECENT"), nil))
    end

    if recentNode.Children and #recentNode.Children > 0 then
        node:AddChild(recentNode)
    end
    if addedOlder and olderNode.Children and #olderNode.Children > 0 then
        node:AddChild(olderNode)
    end
end

-- Local player's active agreements with the target leader, as localized labels.
-- Shared by the relationship tree section and the table's Agreements column.
-- Extracted from the (previously unused) overview reader so both stay in sync.
local function GetAgreementsList(targetID)
    local selectedID = targetID or ms_SelectedPlayerID
    local selectedPlayer = selectedID ~= nil and Players[selectedID] or nil
    local localPlayerDiplomacy = ms_LocalPlayer and ms_LocalPlayer.GetDiplomacy and ms_LocalPlayer:GetDiplomacy() or nil
    local agreements = {}
    if not localPlayerDiplomacy or not selectedPlayer then return agreements end
    if localPlayerDiplomacy:HasDelegationAt(selectedID) then
        table.insert(agreements, Locale.Lookup("LOC_DIPLO_MODIFIER_DELEGATION"))
    end
    if localPlayerDiplomacy:HasEmbassyAt(selectedID) then
        table.insert(agreements, Locale.Lookup("LOC_DIPLO_MODIFIER_RESIDENT_EMBASSY"))
    end
    if localPlayerDiplomacy:HasDefensivePact(selectedID) then
        table.insert(agreements, Locale.Lookup("LOC_DIPLO_MODIFIER_DEFENSIVE_PACT"))
    end
    if localPlayerDiplomacy:HasOpenBordersFrom(selectedID) then
        table.insert(agreements, Locale.Lookup("LOC_DIPLO_MODIFIER_RECEIVED_OPEN_BORDERS"))
    end
    if selectedPlayer:GetDiplomacy():HasOpenBordersFrom(ms_LocalPlayer:GetID()) then
        table.insert(agreements, Locale.Lookup("LOC_DIPLO_MODIFIER_GAVE_OPEN_BORDERS"))
    end
    if localPlayerDiplomacy:GetResearchAgreementTech(selectedID) ~= -1 then
        table.insert(agreements, Locale.Lookup("LOC_DIPLOACTION_RESEARCH_AGREEMENT_NAME"))
    end
    if localPlayerDiplomacy:IsFightingAnyJointWarWith(selectedID) then
        table.insert(agreements, Locale.Lookup("LOC_DIPLOACTION_JOINT_WAR_NAME"))
    end
    return agreements
end

-- Friendliness rank per diplomatic state, high = friendlier. Drives both the
-- best-to-worst ordering inside a foreign-relations cell and the column sort.
local FOREIGN_REL_RANK = {
    DIPLO_STATE_ALLIED          = 6,
    DIPLO_STATE_DECLARED_FRIEND = 5,
    DIPLO_STATE_FRIENDLY        = 4,
    DIPLO_STATE_NEUTRAL         = 3,
    DIPLO_STATE_UNFRIENDLY      = 2,
    DIPLO_STATE_DENOUNCED       = 1,
    DIPLO_STATE_WAR             = 0,
    DIPLO_STATE_DECLARED_WAR    = 0,
}

-- The target leader's relationships with other met majors, sorted friendliest
-- first. Returns the entry list plus an aggregate score (sum of ranks) used as
-- the column sort key. Mirrors the relationship-section loop.
local function GetForeignRelationsEntries(targetID)
    local selectedID = targetID or ms_SelectedPlayerID
    local selectedPlayer = selectedID ~= nil and Players[selectedID] or nil
    local localPlayerDiplomacy = ms_LocalPlayer and ms_LocalPlayer.GetDiplomacy and ms_LocalPlayer:GetDiplomacy() or nil
    local selectedPlayerDiplomacy = selectedPlayer and selectedPlayer.GetDiplomacy and selectedPlayer:GetDiplomacy() or nil
    local entries = {}
    local score = 0
    if not localPlayerDiplomacy or not selectedPlayerDiplomacy then return entries, score end
    for _, player in ipairs(PlayerManager.GetAliveMajors()) do
        local playerID = player:GetID()
        if player:IsMajor()
            and playerID ~= ms_LocalPlayerID
            and playerID ~= selectedID
            and selectedPlayerDiplomacy:HasMet(playerID) then
            local relationState = player:GetDiplomaticAI():GetDiplomaticStateIndex(selectedID)
            local relationInfo = GameInfo.DiplomaticStates[relationState]
            if relationInfo and relationInfo.Hash ~= DiplomaticStates.NEUTRAL then
                local isHumanRelation = not (selectedPlayer:IsAI() or player:IsAI())
                local relationType = relationInfo.StateType
                local isValid = (isHumanRelation and Relationship.IsValidWithHuman(relationType))
                    or ((not isHumanRelation) and Relationship.IsValidWithAI(relationType))
                if isValid then
                    local otherConfig = PlayerConfigurations[playerID]
                    local civLabel
                    if localPlayerDiplomacy:HasMet(playerID) then
                        civLabel = Locale.Lookup("LOC_DIPLOMACY_DEAL_PLAYER_PANEL_TITLE",
                            otherConfig:GetLeaderName(),
                            otherConfig:GetCivilizationDescription())
                    else
                        civLabel = Locale.Lookup("LOC_DIPLOPANEL_UNMET_PLAYER")
                    end
                    local relationLabel = Locale.Lookup(relationInfo.Name)
                    local rank = FOREIGN_REL_RANK[relationType] or 3
                    score = score + rank
                    table.insert(entries, { label = civLabel .. ": " .. relationLabel, rank = rank })
                end
            end
        end
    end
    table.sort(entries, function(a, b)
        if a.rank == b.rank then return Locale.Compare(a.label, b.label) < 0 end
        return a.rank > b.rank
    end)
    return entries, score
end

local function AddAccessChildren(node)
    local sourceLines = BuildActiveVisibilitySourceLines()
    if #sourceLines > 0 then
        node:AddChild(CreateReadOnlyText(mgr:GenerateWidgetId("CAIDiplomacyAccessSources"),
            Locale.Lookup("LOC_CAI_DIPLOMACY_ACTIVE_SOURCES"),
            JoinLines(sourceLines)))
    end

    local sharedLines = BuildInformationSharedLines(0)
    if #sharedLines > 0 then
        node:AddChild(CreateReadOnlyText(mgr:GenerateWidgetId("CAIDiplomacyAccessShared"),
            Locale.Lookup("LOC_DIPLOMACY_INTEL_INFORMATION_SHARED_HEADER"),
            JoinLines(sharedLines)))
    end

    local nextLines = BuildInformationSharedLines(1)
    if GameCapabilities.HasCapability("CAPABILITY_DIPLOMACY_ACCESS_LEVEL_INFO") and #nextLines > 0 then
        node:AddChild(CreateReadOnlyText(mgr:GenerateWidgetId("CAIDiplomacyAccessNext"),
            Locale.Lookup("LOC_DIPLOMACY_INTEL_NEXT_ACCESS_LEVEL_HEADER"),
            JoinLines(nextLines)))
    end

    local advisorLines = BuildAccessAdvisorLines()
    if #advisorLines > 0 then
        node:AddChild(CreateReadOnlyText(mgr:GenerateWidgetId("CAIDiplomacyAccessAdvisor"),
            Locale.Lookup("LOC_DIPLOMACY_INTEL_GAIN_ACCESS_LEVEL_HEADER"),
            JoinLines(advisorLines)))
    end
end

local function AddRelationshipChildren(node)
    node:AddChild(CreateReadOnlyText(mgr:GenerateWidgetId("CAIDiplomacyRelationshipReasons"),
        Locale.Lookup("LOC_DIPLOMACY_INTEL_RELATIONSHIP_REASONS"),
        JoinLines(BuildRelationshipReasonLines())))

    if GameCapabilities.HasCapability("CAPABILITY_DIPLOMACY_RELATIONSHIP_INFO") then
        local raiseLines, lowerLines = BuildRelationshipAdvisorLines()
        if #raiseLines > 0 then
            node:AddChild(CreateReadOnlyText(mgr:GenerateWidgetId("CAIDiplomacyRelationshipRaise"),
                Locale.Lookup("LOC_DIPLOMACY_INTEL_TO_RAISE_RELATIONSHIP"),
                JoinLines(raiseLines)))
        end
        if #lowerLines > 0 then
            node:AddChild(CreateReadOnlyText(mgr:GenerateWidgetId("CAIDiplomacyRelationshipLower"),
                Locale.Lookup("LOC_DIPLOMACY_INTEL_TO_LOWER_RELATIONSHIP"),
                JoinLines(lowerLines)))
        end
    end

    local relationshipsNode = CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyOverviewOtherRelationships"),
        Locale.Lookup("LOC_CAI_DIPLOMACY_FOREIGN_RELATIONSHIPS"), nil)
    for _, entry in ipairs(GetForeignRelationsEntries()) do
        relationshipsNode:AddChild(CreateReadOnlyText(
            mgr:GenerateWidgetId("CAIDiplomacyOtherRelationshipEntry"),
            entry.label,
            nil))
    end
    if relationshipsNode.Children and #relationshipsNode.Children > 0 then
        node:AddChild(relationshipsNode)
    end

    -- Agreements live under the relationship section (vanilla shows them on the
    -- overview, which we fold in here). Same source as the table's column.
    local agreements = GetAgreementsList()
    if #agreements > 0 then
        local agreementsNode = CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyRelationshipAgreements"),
            Locale.Lookup("LOC_DIPLOMACY_OVERVIEW_AGREEMENTS"), nil)
        for _, label in ipairs(agreements) do
            agreementsNode:AddChild(CreateReadOnlyText(
                mgr:GenerateWidgetId("CAIDiplomacyRelationshipAgreementEntry"), label, nil))
        end
        node:AddChild(agreementsNode)
    end
end

-- Generic fallback: walk a captured vanilla panel control and surface every
-- visible, non-empty text string. Used for DLC tabs (alliance / emergency /
-- world congress) and any future tab we have no hand-authored reader for.
local function CollectControlText(control, out, seen)
    if not control then return end
    if control.IsHidden and control:IsHidden() then return end
    if control.GetText then
        local t = control:GetText()
        if t and t ~= "" then
            local norm = NormalizeText(t)
            if norm ~= "" and not seen[norm] then
                seen[norm] = true
                table.insert(out, norm)
            end
        end
    end
    if control.GetChildren then
        for _, child in ipairs(control:GetChildren()) do
            CollectControlText(child, out, seen)
        end
    end
end

local function AddGenericPanelChildren(node, panel)
    if not panel then return end
    local lines, seen = {}, {}
    CollectControlText(panel, lines, seen)
    for _, line in ipairs(lines) do
        node:AddChild(CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyGenericLine"), line, nil))
    end
end

-- ============================================================================
-- DLC intel readers (Rise & Fall / Gathering Storm). The vanilla DLC tabs load
-- their own separate contexts whose control trees we cannot reliably scrape, so
-- each reader rebuilds from the same stable game APIs the vanilla Refresh
-- functions use. Output mirrors the base readers: "Category: value" leaves for
-- single values, category TreeItems with child entries for grouped lists.
-- ============================================================================

local ALLIANCE_MAX_LEVEL = 3

-- Active-summary modifier strings for an alliance at the given level, replicated
-- from DiplomacyActionView_AllianceTab.GetAllianceModifiersFromDB.
local function GetAllianceModifierStrings(allianceType, allianceLevel)
    local modifiers = {}
    local effects = DB.Query("SELECT ModifierID, LevelRequirement from AllianceEffects WHERE AllianceType = ?",
        allianceType)
    for _, effect in ipairs(effects) do
        if effect.LevelRequirement <= allianceLevel then
            local modifierText = DB.Query(
                "SELECT Text from ModifierStrings where ModifierID = ? and Context = 'Summary'", effect.ModifierID)
            if modifierText and modifierText[1] then
                table.insert(modifiers, modifierText[1].Text)
            end
        end
    end
    return modifiers
end

-- One alliance type as a single leaf "<Name>: Level N" whose tooltip lists its
-- bonus summaries. The bonus set is short, so there is no need to expand each
-- type to read it.
local function AddAllianceDetailNode(parent, allianceDefinition, allianceLevel)
    local bonuses = {}
    for _, modifier in ipairs(GetAllianceModifierStrings(allianceDefinition.AllianceType, allianceLevel)) do
        table.insert(bonuses, Locale.Lookup(modifier))
    end
    parent:AddChild(CreateReadOnlyText(mgr:GenerateWidgetId("CAIDiplomacyAllianceDetail"),
        Locale.Lookup(allianceDefinition.Name) .. ": " ..
        Locale.Lookup("LOC_DIPLOACTION_ALLIANCE_LEVEL", allianceLevel),
        table.concat(bonuses, "[NEWLINE]")))
end

local function AddAllianceChildren(node)
    local localPlayerDiplomacy = ms_LocalPlayer and ms_LocalPlayer.GetDiplomacy and ms_LocalPlayer:GetDiplomacy() or nil
    if not localPlayerDiplomacy then return end

    local allianceLevel = localPlayerDiplomacy:GetAllianceLevel(ms_SelectedPlayerID)
    local allianceType = localPlayerDiplomacy:GetAllianceType(ms_SelectedPlayerID)
    local multiplier = GlobalParameters.ALLIANCE_POINTS_MULTIPLIER

    local pointsLine
    if allianceLevel >= ALLIANCE_MAX_LEVEL then
        pointsLine = Locale.Lookup("LOC_CAI_DIPLOMACY_ALLIANCE_POINTS_MAX")
    else
        local current = localPlayerDiplomacy:GetAllianceTurnsThisLevel(ms_SelectedPlayerID) / multiplier
        local needed = localPlayerDiplomacy:GetAllianceTurnsToNextLevel(ms_SelectedPlayerID) / multiplier
        if allianceType ~= -1 then
            local perTurn = localPlayerDiplomacy:GetAlliancePointsPerTurn(ms_SelectedPlayerID) / multiplier
            pointsLine = Locale.Lookup("LOC_CAI_DIPLOMACY_ALLIANCE_POINTS_LINE", current, needed, perTurn)
        else
            pointsLine = Locale.Lookup("LOC_CAI_DIPLOMACY_ALLIANCE_POINTS_LINE_NO_RATE", current, needed)
        end
    end
    -- The raw points tooltip is a per-turn rate breakdown. With no alliance,
    -- vanilla prepends a "you must be allied to gain points" clarifier so the
    -- rates are not misread as current holdings; mirror that.
    local pointsTooltip = localPlayerDiplomacy:GetAlliancePointsTooltip(ms_SelectedPlayerID)
    if allianceType == -1 then
        pointsTooltip = Locale.Lookup("LOC_DIPLOMACY_NEED_ALLIANCE_TO_GAIN_POINTS_TT", pointsTooltip)
    end
    node:AddChild(CreateReadOnlyText(mgr:GenerateWidgetId("CAIDiplomacyAlliancePoints"),
        pointsLine, JoinTooltipLines(pointsTooltip)))

    -- Benefits of every alliance type at the relevant level (next when allied and
    -- below cap, otherwise current), matching vanilla's possible-alliance list.
    local benefitsHeaderKey, levelToShow
    if allianceType ~= -1 then
        benefitsHeaderKey = "LOC_DIPLOACTION_BENEFITS_NEXT_LEVEL"
        levelToShow = allianceLevel < ALLIANCE_MAX_LEVEL and allianceLevel + 1 or allianceLevel
    else
        benefitsHeaderKey = "LOC_DIPLOACTION_BENEFITS_CURRENT_LEVEL"
        levelToShow = allianceLevel
    end

    local benefitsNode = CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyAllianceBenefits"),
        Locale.Lookup(benefitsHeaderKey), nil)
    for alliance in GameInfo.Alliances() do
        -- ALLIANCE_TEAMUP has no modifiers; vanilla skips it.
        if alliance.AllianceType ~= "ALLIANCE_TEAMUP" then
            AddAllianceDetailNode(benefitsNode, alliance, levelToShow)
        end
    end
    if benefitsNode.Children and #benefitsNode.Children > 0 then
        node:AddChild(benefitsNode)
    end
end

local function BuildEmergencyTooltip(crisis)
    local parts = {}
    if crisis.DescriptionText and crisis.DescriptionText ~= "" then
        table.insert(parts, Locale.Lookup(crisis.DescriptionText))
    end
    if crisis.GoalDescription and crisis.GoalDescription ~= "" then
        table.insert(parts, crisis.GoalDescription)
    end
    if crisis.GoalsTable then
        local done, total = 0, 0
        for _, goal in ipairs(crisis.GoalsTable) do
            total = total + 1
            if goal.Completed then done = done + 1 end
        end
        if total > 0 then
            table.insert(parts, Locale.Lookup("LOC_CAI_DIPLOMACY_EMERGENCY_PROGRESS", done, total))
        end
    end
    return table.concat(parts, "[NEWLINE]")
end

local function AddEmergencyChildren(node)
    local manager = Game.GetEmergencyManager()
    local crisisData = manager and manager.GetEmergencyInfoTable
        and manager:GetEmergencyInfoTable(ms_LocalPlayerID) or {}

    local targetingNode = CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyEmergencyTargeting"),
        Locale.Lookup("LOC_DIPLOMACY_EMERGENCIES_TARGET_YOU"), nil)
    local participatingNode = CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyEmergencyParticipating"),
        Locale.Lookup("LOC_DIPLOMACY_EMERGENCIES_PARTICIPATING_YOU"), nil)

    for _, crisis in ipairs(crisisData) do
        if IsSelectedPlayerInCrisis(crisis) then
            local destination = nil
            if crisis.TargetID == ms_LocalPlayerID then
                destination = targetingNode
            else
                for _, memberID in ipairs(crisis.MemberIDs) do
                    if memberID == ms_LocalPlayerID then
                        destination = participatingNode
                        break
                    end
                end
            end

            if destination then
                local status = crisis.TurnsLeft >= 0
                    and Locale.Lookup("LOC_CAI_DIPLOMACY_EMERGENCY_TURNS_LEFT", crisis.TurnsLeft)
                    or Locale.Lookup("LOC_EMERGENCY_TAB_COMPLETED")
                local entryNode = CreateReadOnlyText(mgr:GenerateWidgetId("CAIDiplomacyEmergencyEntry"),
                    Locale.Lookup("LOC_CAI_DIPLOMACY_EMERGENCY_ENTRY",
                        Locale.Lookup(crisis.NameText), status),
                    BuildEmergencyTooltip(crisis))
                destination:AddChild(entryNode)
            end
        end
    end

    if targetingNode.Children and #targetingNode.Children > 0 then
        node:AddChild(targetingNode)
    end
    if participatingNode.Children and #participatingNode.Children > 0 then
        node:AddChild(participatingNode)
    end
    if (not targetingNode.Children or #targetingNode.Children == 0)
        and (not participatingNode.Children or #participatingNode.Children == 0) then
        node:AddChild(CreateReadOnlyText(mgr:GenerateWidgetId("CAIDiplomacyEmergencyNone"),
            Locale.Lookup("LOC_CAI_DIPLOMACY_EMERGENCY_NONE"), nil))
    end
end

local function AddGrievancesChildren(node)
    local localPlayerDiplomacy = ms_LocalPlayer and ms_LocalPlayer.GetDiplomacy and ms_LocalPlayer:GetDiplomacy() or nil
    local gameDiplomacy = Game.GetGameDiplomacy()
    if not localPlayerDiplomacy or not gameDiplomacy then return end

    local targetName = PlayerConfigurations[ms_SelectedPlayerID]:GetCivilizationShortDescription()
    local totalGrievances = localPlayerDiplomacy:GetGrievancesAgainst(ms_SelectedPlayerID)
    local perTurn = gameDiplomacy:GetGrievanceChangePerTurn(ms_SelectedPlayerID, ms_LocalPlayerID)
    -- The per-turn tooltip is a multi-line breakdown ("Grievances per turn from:
    -- ...") surfaced below as its own expandable category, not as a flat tooltip.
    local breakdownLines = SplitLines(gameDiplomacy:GetGrievanceChangeTooltip(ms_SelectedPlayerID, ms_LocalPlayerID))

    -- Sign follows vanilla: >0 favors the local player (grievances against them),
    -- <0 favors the selected player (grievances against you).
    local againstThem, againstYou = 0, 0
    local favorLine, descriptionLine
    if totalGrievances == 0 then
        favorLine = Locale.Lookup("LOC_GRIEVANCE_LOG_WORLD_FAVORS_NONE")
        descriptionLine = Locale.Lookup("LOC_GRIEVANCE_LOG_DESCRIPTION_DEFAULT", targetName, 0)
    elseif totalGrievances > 0 then
        againstThem = totalGrievances
        favorLine = Locale.Lookup("LOC_GRIEVANCE_LOG_WORLD_FAVORS_YOU")
        descriptionLine = Locale.Lookup("LOC_GRIEVANCE_LOG_DESCRIPTION_POSITIVE", targetName, totalGrievances)
    else
        againstYou = -totalGrievances
        favorLine = Locale.Lookup("LOC_GRIEVANCE_LOG_WORLD_FAVORS", targetName)
        descriptionLine = Locale.Lookup("LOC_GRIEVANCE_LOG_DESCRIPTION_NEGATIVE", targetName, againstYou)
    end

    local perTurnText = Locale.Lookup("{1: number +#,###.#;-#,###.#}", perTurn)
    local againstYouLine = Locale.Lookup("LOC_CAI_DIPLOMACY_GRIEVANCES_AGAINST_YOU", againstYou)
    local againstThemLine = Locale.Lookup("LOC_CAI_DIPLOMACY_GRIEVANCES_AGAINST_THEM", againstThem)
    if totalGrievances < 0 then
        againstYouLine = againstYouLine .. ", " .. Locale.Lookup("LOC_CAI_DIPLOMACY_GRIEVANCE_PER_TURN", perTurnText)
    elseif totalGrievances > 0 then
        againstThemLine = againstThemLine .. ", " .. Locale.Lookup("LOC_CAI_DIPLOMACY_GRIEVANCE_PER_TURN", perTurnText)
    end

    if #breakdownLines > 0 then
        local breakdownNode = CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyGrievanceBreakdown"),
            Locale.Lookup("LOC_CAI_DIPLOMACY_GRIEVANCE_BREAKDOWN", perTurnText), nil)
        for _, line in ipairs(breakdownLines) do
            -- Skip the "LOSING / Grievances per turn from:" header line; the
            -- parent label already states the net change. Header lines end in ":".
            if not string.match(line, ":[ \t\r\n]*$") then
                breakdownNode:AddChild(CreateReadOnlyText(mgr:GenerateWidgetId("CAIDiplomacyGrievanceBreakdownEntry"),
                    line, nil))
            end
        end
        node:AddChild(breakdownNode)
    end

    local logEntries = gameDiplomacy:GetGrievanceLogEntries(ms_SelectedPlayerID, ms_LocalPlayerID) or {}
    table.sort(logEntries, function(a, b) return a.Turn > b.Turn end)
    if #logEntries > 0 then
        local logNode = CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyGrievanceLog"),
            Locale.Lookup("LOC_CAI_DIPLOMACY_GRIEVANCE_LOG"), nil)
        for _, entry in ipairs(logEntries) do
            local actor = entry.Initiator == ms_LocalPlayerID
                and Locale.Lookup("LOC_CAI_DIPLOMACY_GRIEVANCE_BY_YOU")
                or Locale.Lookup("LOC_CAI_DIPLOMACY_GRIEVANCE_BY_THEM")
            logNode:AddChild(CreateReadOnlyText(mgr:GenerateWidgetId("CAIDiplomacyGrievanceEntry"),
                Locale.Lookup("LOC_CAI_DIPLOMACY_GRIEVANCE_LOG_ENTRY",
                    entry.Turn, entry.Description, entry.Amount, actor), nil))
        end
        node:AddChild(logNode)
    end
end

-- ============================================================================
-- Table cell / tooltip / sort builders. Each takes the row leader's playerID and
-- reads live game state for that leader (independent of the vanilla selection),
-- reusing the parameterized intel builders above. Advisor text is placed last in
-- every tooltip where it applies. Multi-value cells stay single spoken lines;
-- the rich breakdown lives in the tooltip, except emergencies, whose full detail
-- the user asked to carry in the cell itself.
-- ============================================================================

-- Relationship -----------------------------------------------------------------
local function CellRelationship(targetID)
    local data = GetRelationshipData(targetID)
    return data and data.Label or ""
end

local function TooltipRelationship(targetID)
    local lines = {}
    local data = GetRelationshipData(targetID)
    if data and data.Tooltip and data.Tooltip ~= "" then
        table.insert(lines, JoinTooltipLines(data.Tooltip))
    end
    AppendSectionLines(lines, Locale.Lookup("LOC_DIPLOMACY_INTEL_RELATIONSHIP_REASONS"),
        BuildRelationshipReasonLines(targetID))
    if GameCapabilities.HasCapability("CAPABILITY_DIPLOMACY_RELATIONSHIP_INFO") then
        local raiseLines, lowerLines = BuildRelationshipAdvisorLines(targetID)
        AppendSectionLines(lines, Locale.Lookup("LOC_DIPLOMACY_INTEL_TO_RAISE_RELATIONSHIP"), raiseLines)
        AppendSectionLines(lines, Locale.Lookup("LOC_DIPLOMACY_INTEL_TO_LOWER_RELATIONSHIP"), lowerLines)
    end
    return JoinLines(lines)
end

local function RelationshipSortKey(targetID)
    local data = GetRelationshipData(targetID)
    if not data or not data.StateInfo then return nil end
    return FOREIGN_REL_RANK[data.StateInfo.StateType] or 3
end

-- Access -----------------------------------------------------------------------
local function GetAccessLevelValue(targetID)
    local selectedID = targetID or ms_SelectedPlayerID
    local localPlayerDiplomacy = ms_LocalPlayer and ms_LocalPlayer.GetDiplomacy and ms_LocalPlayer:GetDiplomacy() or nil
    if not localPlayerDiplomacy then return nil end
    return localPlayerDiplomacy:GetVisibilityOn(selectedID)
end

-- Agendas ----------------------------------------------------------------------
local function CellAgendas(targetID)
    local selectedID = targetID or ms_SelectedPlayerID
    local parts = {}
    for _, line in ipairs(BuildAgendaSummaryLines(selectedID, Players[selectedID])) do
        table.insert(parts, string.match(line, "^(.-): ") or line)
    end
    return table.concat(parts, "; ")
end

local function TooltipAgendas(targetID)
    local selectedID = targetID or ms_SelectedPlayerID
    return JoinLines(BuildAgendaSummaryLines(selectedID, Players[selectedID]))
end

local function AgendaSortKey(targetID)
    local selectedID = targetID or ms_SelectedPlayerID
    return #BuildAgendaSummaryLines(selectedID, Players[selectedID])
end

-- Gossip -----------------------------------------------------------------------
local function GetGossipNewCount(targetID)
    local selectedID = targetID or ms_SelectedPlayerID
    return CountEntries(Game.GetGossipManager():GetRecentVisibleGossipStrings(
        Game.GetCurrentGameTurn() - 1, ms_LocalPlayerID, selectedID))
end

local function CellGossip(targetID)
    local n = GetGossipNewCount(targetID)
    return n > 0
        and Locale.Lookup("LOC_DIPLOMACY_GOSSIP_ITEM_COUNT", n)
        or Locale.Lookup("LOC_DIPLOMACY_GOSSIP_ITEM_NONE_THIS_TURN")
end

-- Full visible gossip for one leader, newest first, for the drill-down panel.
-- Each raw tuple is {text, turn, gossipTypeIndex, initiatorID, ...}; index 3
-- keys GameInfo.Gossips for the group filter.
local function GetGossipItemsForPlayer(targetID)
    local selectedID = targetID or ms_SelectedPlayerID
    local gossipManager = Game.GetGossipManager()
    local items = gossipManager and gossipManager.GetRecentVisibleGossipStrings and
        gossipManager:GetRecentVisibleGossipStrings(0, ms_LocalPlayerID, selectedID) or {}
    local list = {}
    for _, item in ipairs(items) do list[#list + 1] = item end
    table.sort(list, function(a, b) return (a[2] or 0) > (b[2] or 0) end)
    return list
end

-- Foreign relationships --------------------------------------------------------
local function CellForeignRelations(targetID)
    local parts = {}
    for _, entry in ipairs(GetForeignRelationsEntries(targetID)) do parts[#parts + 1] = entry.label end
    return table.concat(parts, "; ")
end

local function TooltipForeignRelations(targetID)
    local parts = {}
    for _, entry in ipairs(GetForeignRelationsEntries(targetID)) do parts[#parts + 1] = entry.label end
    return table.concat(parts, "[NEWLINE]")
end

local function ForeignRelationsSortKey(targetID)
    local _, score = GetForeignRelationsEntries(targetID)
    return score
end

-- Agreements -------------------------------------------------------------------
local function CellAgreements(targetID)
    local list = GetAgreementsList(targetID)
    if #list == 0 then return Locale.Lookup("LOC_CAI_DIPLOMACY_AGREEMENTS_NONE") end
    return table.concat(list, "; ")
end

local function TooltipAgreements(targetID)
    return table.concat(GetAgreementsList(targetID), "[NEWLINE]")
end

local function AgreementsSortKey(targetID)
    return #GetAgreementsList(targetID)
end

-- Alliance ---------------------------------------------------------------------
local function GetAllianceInfo(targetID)
    local selectedID = targetID or ms_SelectedPlayerID
    local localPlayerDiplomacy = ms_LocalPlayer and ms_LocalPlayer.GetDiplomacy and ms_LocalPlayer:GetDiplomacy() or nil
    if not localPlayerDiplomacy then return nil end
    local allianceLevel = localPlayerDiplomacy:GetAllianceLevel(selectedID)
    local allianceType = localPlayerDiplomacy:GetAllianceType(selectedID)
    local multiplier = GlobalParameters.ALLIANCE_POINTS_MULTIPLIER
    local pointsLine
    if allianceLevel >= ALLIANCE_MAX_LEVEL then
        pointsLine = Locale.Lookup("LOC_CAI_DIPLOMACY_ALLIANCE_POINTS_MAX")
    else
        local current = localPlayerDiplomacy:GetAllianceTurnsThisLevel(selectedID) / multiplier
        local needed = localPlayerDiplomacy:GetAllianceTurnsToNextLevel(selectedID) / multiplier
        if allianceType ~= -1 then
            local perTurn = localPlayerDiplomacy:GetAlliancePointsPerTurn(selectedID) / multiplier
            pointsLine = Locale.Lookup("LOC_CAI_DIPLOMACY_ALLIANCE_POINTS_LINE", current, needed, perTurn)
        else
            pointsLine = Locale.Lookup("LOC_CAI_DIPLOMACY_ALLIANCE_POINTS_LINE_NO_RATE", current, needed)
        end
    end
    local typeName = (allianceType ~= -1 and GameInfo.Alliances[allianceType])
        and Locale.Lookup(GameInfo.Alliances[allianceType].Name)
        or Locale.Lookup("LOC_DIPLOACTION_NO_CURRENT_ALLIANCE")
    return { level = allianceLevel, type = allianceType, typeName = typeName, pointsLine = pointsLine }
end

local function CellAlliance(targetID)
    local info = GetAllianceInfo(targetID)
    if not info then return "" end
    return JoinNonEmpty({
        info.typeName,
        Locale.Lookup("LOC_CAI_DIPLOMACY_ALLIANCE_LEVEL", info.level),
        info.pointsLine,
    }, ", ")
end

local function TooltipAlliance(targetID)
    local selectedID = targetID or ms_SelectedPlayerID
    local localPlayerDiplomacy = ms_LocalPlayer and ms_LocalPlayer.GetDiplomacy and ms_LocalPlayer:GetDiplomacy() or nil
    if not localPlayerDiplomacy then return "" end
    local allianceLevel = localPlayerDiplomacy:GetAllianceLevel(selectedID)
    local allianceType = localPlayerDiplomacy:GetAllianceType(selectedID)
    local lines = {}
    local pointsTooltip = localPlayerDiplomacy:GetAlliancePointsTooltip(selectedID)
    if allianceType == -1 then
        pointsTooltip = Locale.Lookup("LOC_DIPLOMACY_NEED_ALLIANCE_TO_GAIN_POINTS_TT", pointsTooltip)
    end
    table.insert(lines, JoinTooltipLines(pointsTooltip))

    local benefitsHeaderKey, levelToShow
    if allianceType ~= -1 then
        benefitsHeaderKey = "LOC_DIPLOACTION_BENEFITS_NEXT_LEVEL"
        levelToShow = allianceLevel < ALLIANCE_MAX_LEVEL and allianceLevel + 1 or allianceLevel
    else
        benefitsHeaderKey = "LOC_DIPLOACTION_BENEFITS_CURRENT_LEVEL"
        levelToShow = allianceLevel
    end
    table.insert(lines, Locale.Lookup(benefitsHeaderKey))
    for alliance in GameInfo.Alliances() do
        if alliance.AllianceType ~= "ALLIANCE_TEAMUP" then
            local bonuses = {}
            for _, modifier in ipairs(GetAllianceModifierStrings(alliance.AllianceType, levelToShow)) do
                table.insert(bonuses, Locale.Lookup(modifier))
            end
            local detail = Locale.Lookup(alliance.Name) .. ": " ..
                Locale.Lookup("LOC_DIPLOACTION_ALLIANCE_LEVEL", levelToShow)
            if #bonuses > 0 then detail = detail .. ": " .. table.concat(bonuses, "; ") end
            table.insert(lines, detail)
        end
    end
    return JoinLines(lines)
end

local function AllianceSortKey(targetID)
    local info = GetAllianceInfo(targetID)
    return info and info.level or nil
end

-- Grievances -------------------------------------------------------------------
local function GetGrievanceInfo(targetID)
    local selectedID = targetID or ms_SelectedPlayerID
    local localPlayerDiplomacy = ms_LocalPlayer and ms_LocalPlayer.GetDiplomacy and ms_LocalPlayer:GetDiplomacy() or nil
    local gameDiplomacy = Game.GetGameDiplomacy()
    if not localPlayerDiplomacy or not gameDiplomacy then return nil end
    local targetName = PlayerConfigurations[selectedID]:GetCivilizationShortDescription()
    local totalGrievances = localPlayerDiplomacy:GetGrievancesAgainst(selectedID)
    local perTurn = gameDiplomacy:GetGrievanceChangePerTurn(selectedID, ms_LocalPlayerID)
    local breakdownLines = SplitLines(gameDiplomacy:GetGrievanceChangeTooltip(selectedID, ms_LocalPlayerID))
    local againstThem, againstYou = 0, 0
    local favorLine, descriptionLine
    if totalGrievances == 0 then
        favorLine = Locale.Lookup("LOC_GRIEVANCE_LOG_WORLD_FAVORS_NONE")
        descriptionLine = Locale.Lookup("LOC_GRIEVANCE_LOG_DESCRIPTION_DEFAULT", targetName, 0)
    elseif totalGrievances > 0 then
        againstThem = totalGrievances
        favorLine = Locale.Lookup("LOC_GRIEVANCE_LOG_WORLD_FAVORS_YOU")
        descriptionLine = Locale.Lookup("LOC_GRIEVANCE_LOG_DESCRIPTION_POSITIVE", targetName, totalGrievances)
    else
        againstYou = -totalGrievances
        favorLine = Locale.Lookup("LOC_GRIEVANCE_LOG_WORLD_FAVORS", targetName)
        descriptionLine = Locale.Lookup("LOC_GRIEVANCE_LOG_DESCRIPTION_NEGATIVE", targetName, againstYou)
    end
    return {
        perTurn = perTurn,
        perTurnText = Locale.Lookup("{1: number +#,###.#;-#,###.#}", perTurn),
        againstYou = againstYou,
        againstThem = againstThem,
        favorLine = favorLine,
        descriptionLine = descriptionLine,
        breakdownLines = breakdownLines,
    }
end

local function TooltipGrievanceChange(targetID)
    local info = GetGrievanceInfo(targetID)
    if not info then return "" end
    local lines = { info.favorLine, info.descriptionLine }
    for _, line in ipairs(info.breakdownLines) do
        -- Skip header lines ("... per turn from:"); the value is already stated.
        if not string.match(line, ":[ \t\r\n]*$") then table.insert(lines, line) end
    end
    return JoinLines(lines)
end

local function GetGrievanceLogEntriesForPlayer(targetID)
    local selectedID = targetID or ms_SelectedPlayerID
    local gameDiplomacy = Game.GetGameDiplomacy()
    if not gameDiplomacy then return {} end
    local logEntries = gameDiplomacy:GetGrievanceLogEntries(selectedID, ms_LocalPlayerID) or {}
    table.sort(logEntries, function(a, b) return a.Turn > b.Turn end)
    local result = {}
    for _, entry in ipairs(logEntries) do
        local actor = entry.Initiator == ms_LocalPlayerID
            and Locale.Lookup("LOC_CAI_DIPLOMACY_GRIEVANCE_BY_YOU")
            or Locale.Lookup("LOC_CAI_DIPLOMACY_GRIEVANCE_BY_THEM")
        table.insert(result, Locale.Lookup("LOC_CAI_DIPLOMACY_GRIEVANCE_LOG_ENTRY",
            entry.Turn, entry.Description, entry.Amount, actor))
    end
    return result
end

-- Secret society ---------------------------------------------------------------
local function GetSecretSocietyInfo(targetID)
    local selectedID = targetID or ms_SelectedPlayerID
    local selectedPlayer = selectedID ~= nil and Players[selectedID] or nil
    local selectedGovernors = selectedPlayer and selectedPlayer.GetGovernors and selectedPlayer:GetGovernors() or nil
    if not selectedGovernors or not selectedGovernors.GetSecretSociety then return nil end
    local society = selectedGovernors:GetSecretSociety()
    local label, tooltip
    if society ~= -1 then
        if selectedGovernors:IsAwareOfSecretSociety(society) and GameInfo.SecretSocieties[society] then
            label = Locale.Lookup(GameInfo.SecretSocieties[society].Name)
        else
            label = Locale.Lookup("LOC_SECRETSOCIETY_DIPLO_UNKNOWN_NAME")
            tooltip = Locale.Lookup("LOC_SECRETSOCIETY_DIPLO_UNKNOWN_DESCRIPTION")
        end
    else
        label = Locale.Lookup("LOC_SECRETSOCIETY_DIPLO_NONE_NAME")
    end
    return { label = label, tooltip = tooltip or "" }
end

-- Emergencies ------------------------------------------------------------------
local function InCrisisWith(crisis, id)
    if crisis.TargetID == id then return true end
    for _, memberID in ipairs(crisis.MemberIDs) do
        if memberID == id then return true end
    end
    return false
end

-- mode "participating": local is a member (not the target) and the row leader is
-- in the same crisis. mode "targeting": local is the crisis target and the row
-- leader is in it.
local function GetEmergenciesForPlayer(targetID, mode)
    local selectedID = targetID or ms_SelectedPlayerID
    local manager = Game.GetEmergencyManager()
    local crisisData = manager and manager.GetEmergencyInfoTable
        and manager:GetEmergencyInfoTable(ms_LocalPlayerID) or {}
    local result = {}
    for _, crisis in ipairs(crisisData) do
        if crisis.HasBegun and InCrisisWith(crisis, selectedID) then
            local localIsTarget = crisis.TargetID == ms_LocalPlayerID
            local localIsMember = false
            for _, memberID in ipairs(crisis.MemberIDs) do
                if memberID == ms_LocalPlayerID then
                    localIsMember = true
                    break
                end
            end
            local include = (mode == "targeting" and localIsTarget)
                or (mode == "participating" and not localIsTarget and localIsMember)
            if include then
                local status = crisis.TurnsLeft >= 0
                    and Locale.Lookup("LOC_CAI_DIPLOMACY_EMERGENCY_TURNS_LEFT", crisis.TurnsLeft)
                    or Locale.Lookup("LOC_EMERGENCY_TAB_COMPLETED")
                table.insert(result, {
                    name = Locale.Lookup(crisis.NameText),
                    status = status,
                    detail = BuildEmergencyTooltip(crisis),
                })
            end
        end
    end
    return result
end

local function CellEmergencies(targetID, mode)
    local list = GetEmergenciesForPlayer(targetID, mode)
    if #list == 0 then return "" end
    local lines = {}
    for _, e in ipairs(list) do
        table.insert(lines, Locale.Lookup("LOC_CAI_DIPLOMACY_EMERGENCY_ENTRY", e.name, e.status))
        if e.detail and e.detail ~= "" then table.insert(lines, e.detail) end
    end
    return JoinLines(lines)
end

local function GetKnownReaders()
    if m_knownReaders then return m_knownReaders end
    m_knownReaders = {
        [Locale.ToUpper("LOC_DIPLOMACY_INTEL_REPORT_GOSSIP")] = AddGossipChildren,
        [Locale.ToUpper("LOC_DIPLOMACY_INTEL_REPORT_ACCESS_LEVEL")] = AddAccessChildren,
        [Locale.ToUpper("LOC_DIPLOMACY_INTEL_REPORT_RELATIONSHIP")] = AddRelationshipChildren,
        [Locale.ToUpper("LOC_DIPLOACTION_INTEL_REPORT_ALLIANCE")] = AddAllianceChildren,
        [Locale.ToUpper("LOC_DIPLOACTION_INTEL_REPORT_EMERGENCY")] = AddEmergencyChildren,
        [Locale.ToUpper("LOC_DIPLOACTION_INTEL_REPORT_GRIEVANCES")] = AddGrievancesChildren,
    }
    return m_knownReaders
end

-- ============================================================================
-- Intel sections for the selected leader, built from the live vanilla tab set
-- (enumerated silently by CaptureIntelTabs). Each leader's sections persist
-- across re-selection; see BuildSelectedLeaderChildren.
-- ============================================================================

-- The currently-shown intel panel (ShowPanel hides all the others). Used as the
-- generic-fallback source for an unknown tab, resolved when that tab is shown.
local function VisibleIntelPanelChild()
    local panel = ms_IntelPanel
    if not panel or not panel.IntelPanelContainer then return nil end
    for _, child in ipairs(panel.IntelPanelContainer:GetChildren()) do
        if not ControlIsHidden(child) then return child end
    end
    return nil
end

local function PopulateSectionChildren(sectionNode, tab)
    local reader = GetKnownReaders()[tab.Header]
    if reader then
        reader(sectionNode)
    end
end

local function CreateIntelSection(tab)
    local section = mgr:CreateWidget(mgr:GenerateWidgetId("CAIDiplomacyIntelSection"), "TreeItem", {
        Label = function()
            if tab.Header == Locale.ToUpper("LOC_DIPLOMACY_INTEL_REPORT_GOSSIP") then
                local gossipCount = CountEntries(Game.GetGossipManager():GetRecentVisibleGossipStrings(
                    Game.GetCurrentGameTurn() - 1,
                    ms_LocalPlayerID,
                    ms_SelectedPlayerID))
                local gossipText = gossipCount > 0
                    and Locale.Lookup("LOC_DIPLOMACY_GOSSIP_ITEM_COUNT", gossipCount)
                    or Locale.Lookup("LOC_DIPLOMACY_GOSSIP_ITEM_NONE_THIS_TURN")
                return tab.Header .. ", " .. gossipText
            end
            if tab.Header == Locale.ToUpper("LOC_DIPLOMACY_INTEL_REPORT_ACCESS_LEVEL") then
                return tab.Header .. ", " .. GetAccessLevelName()
            end
            if tab.Header == Locale.ToUpper("LOC_DIPLOMACY_INTEL_REPORT_RELATIONSHIP") then
                local relationship = GetRelationshipData()
                return relationship and (tab.Header .. ", " .. relationship.Label) or (tab.Header or "")
            end
            return tab.Header or ""
        end,
        Tooltip = function()
            if tab.Header == Locale.ToUpper("LOC_DIPLOMACY_INTEL_REPORT_RELATIONSHIP") then
                return BuildRelationshipSectionTooltip()
            end
            if tab.Header == Locale.ToUpper("LOC_DIPLOACTION_INTEL_REPORT_ALLIANCE") then
                local localPlayerDiplomacy = ms_LocalPlayer and ms_LocalPlayer.GetDiplomacy and
                ms_LocalPlayer:GetDiplomacy() or nil
                if not localPlayerDiplomacy then return "" end
                local allianceLevel = localPlayerDiplomacy:GetAllianceLevel(ms_SelectedPlayerID)
                local allianceType = localPlayerDiplomacy:GetAllianceType(ms_SelectedPlayerID)
                local multiplier = GlobalParameters.ALLIANCE_POINTS_MULTIPLIER
                local currentPoints = localPlayerDiplomacy:GetAllianceTurnsThisLevel(ms_SelectedPlayerID) / multiplier
                local neededPoints = localPlayerDiplomacy:GetAllianceTurnsToNextLevel(ms_SelectedPlayerID) / multiplier
                local pointsLine
                if allianceLevel >= ALLIANCE_MAX_LEVEL then
                    pointsLine = Locale.Lookup("LOC_CAI_DIPLOMACY_ALLIANCE_POINTS_MAX")
                else
                    pointsLine = Locale.Lookup("LOC_CAI_DIPLOMACY_ALLIANCE_POINTS_LINE_NO_RATE", currentPoints,
                        neededPoints)
                end
                local currentAllianceText = Locale.Lookup("LOC_DIPLOACTION_NO_CURRENT_ALLIANCE")
                if allianceType ~= -1 and GameInfo.Alliances[allianceType] then
                    currentAllianceText = Locale.Lookup(GameInfo.Alliances[allianceType].Name)
                end
                return JoinLines({
                    Locale.Lookup("LOC_CAI_DIPLOMACY_CURRENT_ALLIANCE") .. ": " .. currentAllianceText,
                    pointsLine,
                    Locale.Lookup("LOC_CAI_DIPLOMACY_ALLIANCE_LEVEL", allianceLevel),
                })
            end
            if tab.Header == Locale.ToUpper("LOC_DIPLOACTION_INTEL_REPORT_GRIEVANCES") then
                local localPlayerDiplomacy = ms_LocalPlayer and ms_LocalPlayer.GetDiplomacy and
                ms_LocalPlayer:GetDiplomacy() or nil
                local gameDiplomacy = Game.GetGameDiplomacy()
                if not localPlayerDiplomacy or not gameDiplomacy then return "" end
                local targetName = PlayerConfigurations[ms_SelectedPlayerID]:GetCivilizationShortDescription()
                local totalGrievances = localPlayerDiplomacy:GetGrievancesAgainst(ms_SelectedPlayerID)
                local perTurn = gameDiplomacy:GetGrievanceChangePerTurn(ms_SelectedPlayerID, ms_LocalPlayerID)
                local againstThem, againstYou = 0, 0
                local favorLine, descriptionLine
                if totalGrievances == 0 then
                    favorLine = Locale.Lookup("LOC_GRIEVANCE_LOG_WORLD_FAVORS_NONE")
                    descriptionLine = Locale.Lookup("LOC_GRIEVANCE_LOG_DESCRIPTION_DEFAULT", targetName, 0)
                elseif totalGrievances > 0 then
                    againstThem = totalGrievances
                    favorLine = Locale.Lookup("LOC_GRIEVANCE_LOG_WORLD_FAVORS_YOU")
                    descriptionLine = Locale.Lookup("LOC_GRIEVANCE_LOG_DESCRIPTION_POSITIVE", targetName, totalGrievances)
                else
                    againstYou = -totalGrievances
                    favorLine = Locale.Lookup("LOC_GRIEVANCE_LOG_WORLD_FAVORS", targetName)
                    descriptionLine = Locale.Lookup("LOC_GRIEVANCE_LOG_DESCRIPTION_NEGATIVE", targetName, againstYou)
                end
                local perTurnText = Locale.Lookup("{1: number +#,###.#;-#,###.#}", perTurn)
                local againstYouLine = Locale.Lookup("LOC_CAI_DIPLOMACY_GRIEVANCES_AGAINST_YOU", againstYou)
                local againstThemLine = Locale.Lookup("LOC_CAI_DIPLOMACY_GRIEVANCES_AGAINST_THEM", againstThem)
                if totalGrievances < 0 then
                    againstYouLine = againstYouLine ..
                    ", " .. Locale.Lookup("LOC_CAI_DIPLOMACY_GRIEVANCE_PER_TURN", perTurnText)
                elseif totalGrievances > 0 then
                    againstThemLine = againstThemLine ..
                    ", " .. Locale.Lookup("LOC_CAI_DIPLOMACY_GRIEVANCE_PER_TURN", perTurnText)
                end
                return JoinLines({
                    favorLine,
                    descriptionLine,
                    againstYouLine,
                    againstThemLine,
                })
            end
            return ""
        end,
    })
    section:On("focus_enter", function(w)
        -- Bubbles on subtree entry (a focused child counts), so this fires whenever
        -- the user enters this tab from anywhere. Only drive the real tab button
        -- when this tab is not already the one vanilla shows: IsSelected() tracks
        -- the live shown tab (ShowPanel SetSelected()s it), so re-entering the
        -- current tab -- Shift+Tab back from the actions list, moving among this
        -- tab's own children, or focusing Overview right after a leader select
        -- (vanilla leaves it shown) -- fires no click and no rebuild. Switching to
        -- a different tab is the one case that legitimately clicks.
        local button = tab.Button
        if button and not (button.IsSelected and button:IsSelected()) then
            button:DoLeftClick()
        end
    end)
    return section
end

local function BuildManualIntelTabs()
    local tabs = {
        {
            Header = Locale.ToUpper("LOC_DIPLOMACY_INTEL_REPORT_GOSSIP"),
            ButtonTooltip = Locale.Lookup("LOC_DIPLOMACY_INTEL_GOSSIP_COLON_TOOLTIP"),
        },
        {
            Header = Locale.ToUpper("LOC_DIPLOMACY_INTEL_REPORT_ACCESS_LEVEL"),
            ButtonTooltip = Locale.Lookup("LOC_DIPLOMACY_INTEL_ACCESS_LEVEL_COLON_TOOLTIP"),
        },
        {
            Header = Locale.ToUpper("LOC_DIPLOMACY_INTEL_REPORT_RELATIONSHIP"),
            ButtonTooltip = Locale.Lookup("LOC_DIPLOMACY_INTEL_OUR_RELATIONSHIP_TOOLTIP"),
        },
    }

    if IsExpansion1Active() and ms_SelectedPlayer and ms_LocalPlayer
        and ms_SelectedPlayer:GetTeam() ~= ms_LocalPlayer:GetTeam() then
        table.insert(tabs, {
            Header = Locale.ToUpper("LOC_DIPLOACTION_INTEL_REPORT_ALLIANCE"),
            ButtonTooltip = Locale.Lookup("LOC_DIPLOACTION_ALLIANCE_TAB_TOOLTIP"),
        })
    end

    if IsExpansion1Active() then
        local manager = Game.GetEmergencyManager()
        local crisisData = manager and manager.GetEmergencyInfoTable
            and manager:GetEmergencyInfoTable(ms_SelectedPlayerID) or {}
        local showEmergency = false
        for _, crisis in ipairs(crisisData) do
            if crisis.HasBegun then
                local involvesLocalPlayer = crisis.TargetID == ms_LocalPlayerID
                local involvesSelectedPlayer = crisis.TargetID == ms_SelectedPlayerID
                for _, memberID in ipairs(crisis.MemberIDs) do
                    if memberID == ms_LocalPlayerID then
                        involvesLocalPlayer = true
                    end
                    if memberID == ms_SelectedPlayerID then
                        involvesSelectedPlayer = true
                    end
                end
                if involvesLocalPlayer and involvesSelectedPlayer then
                    showEmergency = true
                    break
                end
            end
        end
        if showEmergency then
            table.insert(tabs, {
                Header = Locale.ToUpper("LOC_DIPLOACTION_INTEL_REPORT_EMERGENCY"),
                ButtonTooltip = Locale.Lookup("LOC_DIPLOMACY_OVERVIEW_EMERGENCIES"),
            })
        end
    end

    if IsExpansion2Active() and Game.GetEras():GetCurrentEra() >= GlobalParameters.WORLD_CONGRESS_INITIAL_ERA then
        table.insert(tabs, {
            Header = Locale.ToUpper("LOC_DIPLOACTION_INTEL_REPORT_GRIEVANCES"),
            ButtonTooltip = Locale.Lookup("LOC_DIPLOACTION_WORLD_CONGRESS_TAB_TOOLTIP"),
        })
    end

    return tabs
end

local function BindIntelButtons(tabs)
    local panel = ms_IntelPanel
    if not panel or not panel.IntelTabButtonStack then
        return
    end

    local buttonsByTooltip = {}
    local overviewTooltip = Locale.Lookup("LOC_DIPLOMACY_INTEL_OVERVIEW_COLON_TOOLTIP")
    for _, button in ipairs(panel.IntelTabButtonStack:GetChildren()) do
        local tooltip = button.GetToolTipString and button:GetToolTipString() or ""
        if not ControlIsHidden(button) and tooltip ~= overviewTooltip and tooltip ~= "" then
            buttonsByTooltip[tooltip] = button
        end
    end

    for _, tab in ipairs(tabs) do
        tab.Button = buttonsByTooltip[tab.ButtonTooltip]
    end
end

local function BuildSelectedLeaderChildren()
    local entry = m_ui.leaderEntries[ms_SelectedPlayerID]
    if not entry or not entry.Row then return end

    local isSelf = ms_SelectedPlayerID == ms_LocalPlayerID
    if isSelf then
        entry.IsSelf = true
        entry.Tabs = {}
        entry.IntelBuilt = true
        return
    end

    local liveTabs = isSelf and {} or BuildManualIntelTabs()
    BindIntelButtons(liveTabs)

    local capture = mgr:CaptureFocusKey(entry.Row)
    entry.Row:ClearChildren()
    entry.IsSelf = isSelf
    entry.Tabs = liveTabs

    if not isSelf then
        for _, tab in ipairs(liveTabs) do
            local section = CreateIntelSection(tab)
            PopulateSectionChildren(section, tab)
            entry.Row:AddChild(section)
        end
    end
    entry.IntelBuilt = true

    mgr:RestoreFocus(entry.Row, capture)
end

-- ============================================================================
-- Leader table (table view), view switching, and drill-down panels
-- ============================================================================

-- Active column definitions for the current game state, plus the leader set and
-- column signature the table was last built against (so rebuilds are skipped
-- when nothing structural changed). Column cell values are live getters, so data
-- changes never need a rebuild -- only membership, sort, or column-set changes.
local m_activeColumns = {}
local m_tableLeaderOrder = {}
local m_tableColumnSig = nil
local m_gossipOptions = {}
-- Last leader focused in the table, so leaving the local-leader widget can
-- restore selection to it (the local player when none yet).
local m_lastTableLeaderID = nil

-- Forward declarations: column onActivate closures (built in BuildTableColumns)
-- reference these drill-down openers, which are defined later in this section.
local OpenGossipPanel, OpenGrievanceLog

local function CellGovernment(targetID)
    local selectedID = targetID or ms_SelectedPlayerID
    local selectedPlayer = selectedID ~= nil and Players[selectedID] or nil
    local governmentText = Locale.Lookup("LOC_DIPLOMACY_GOVERNMENT_NONE")
    local culture = selectedPlayer and selectedPlayer.GetCulture and selectedPlayer:GetCulture() or nil
    local government = culture and culture:GetCurrentGovernment() or -1
    if government ~= -1 and GameInfo.Governments[government] then
        governmentText = Locale.Lookup(GameInfo.Governments[government].Name)
    elseif culture and culture:IsInAnarchy() then
        governmentText = Locale.Lookup("LOC_GOVERNMENT_ANARCHY_TURNS",
            culture:GetAnarchyEndTurn() - Game.GetCurrentGameTurn())
    end
    return governmentText
end

-- Gossip tooltip shows only the last ten turns (older gossip is reachable via the
-- drill-down panel's full log).
local function GossipRecentTooltip(targetID)
    local selectedID = targetID or ms_SelectedPlayerID
    local gossipManager = Game.GetGossipManager()
    local currentTurn = Game.GetCurrentGameTurn()
    local items = gossipManager and gossipManager.GetRecentVisibleGossipStrings and
        gossipManager:GetRecentVisibleGossipStrings(currentTurn - 100, ms_LocalPlayerID, selectedID) or {}
    local lines = { Locale.Lookup("LOC_DIPLOMACY_INTEL_LAST_TEN_TURNS") }
    local added = false
    for _, item in ipairs(items) do
        local text, turn = item[1], item[2]
        if text and turn and (currentTurn - turn) <= 10 then
            lines[#lines + 1] = FormatGossipLine(selectedID, turn, text, (currentTurn - 1) <= turn)
            added = true
        end
    end
    if not added then lines[#lines + 1] = Locale.Lookup("LOC_DIPLOMACY_GOSSIP_ITEM_NO_RECENT") end
    return JoinLines(lines)
end

local SORT_HIGH = "LOC_CAI_SORT_HIGHEST_FIRST"
local SORT_LOW  = "LOC_CAI_SORT_LOWEST_FIRST"
local SORT_MOST = "LOC_CAI_SORT_MOST_FIRST"
local SORT_FEW  = "LOC_CAI_SORT_FEWEST_FIRST"
local SORT_AZ   = "LOC_CAI_SORT_A_TO_Z"
local SORT_ZA   = "LOC_CAI_SORT_Z_TO_A"

local function CompareSortValues(a, b)
    if a == b then return 0 end
    if a == nil then return 1 end
    if b == nil then return -1 end
    if type(a) == "number" and type(b) == "number" then return a < b and -1 or 1 end
    if type(a) == "boolean" and type(b) == "boolean" then return a and 1 or -1 end
    return Locale.Compare(tostring(a), tostring(b))
end

-- Table rows are every met major except the local player (who sits in the
-- separate local-leader widget above the table).
local function GetTableLeaderIDs()
    local ids = {}
    for _, playerID in ipairs(GetLeaderIDs()) do
        if playerID ~= ms_LocalPlayerID then table.insert(ids, playerID) end
    end
    return ids
end

local function GetTableRowFocusKey(playerID)
    return TABLE_ID .. ":row:" .. tostring(playerID)
end

local function GrievanceColumnsActive()
    return IsExpansion2Active()
        and Game.GetEras():GetCurrentEra() >= GlobalParameters.WORLD_CONGRESS_INITIAL_ERA
end

local function BuildTableColumns(leaderIDs)
    local columns = {
        {
            key = "leader",
            header = function() return Locale.Lookup("LOC_CAI_DIPLOMACY_LEADERS") end,
            getCell = function(pid) return GetLeaderRowLabel(pid) end,
            sortKey = function(pid) return GetLeaderRowLabel(pid) end,
            sortAscendingDescription = SORT_AZ,
            sortDescendingDescription = SORT_ZA,
        },
        {
            key = "relationship",
            header = function() return Locale.Lookup("LOC_DIPLOMACY_OVERVIEW_OUR_RELATIONSHIP") end,
            getCell = CellRelationship,
            getTooltip = TooltipRelationship,
            sortKey = RelationshipSortKey,
            sortAscendingDescription = "LOC_CAI_SORT_MOST_HOSTILE_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_FRIENDLIEST_FIRST",
        },
        {
            key = "access",
            header = function() return Locale.Lookup("LOC_DIPLOMACY_OVERVIEW_ACCESS_LEVEL") end,
            getCell = function(pid) return GetAccessLevelName(pid) end,
            getTooltip = function(pid) return BuildAccessSectionTooltip(pid) end,
            sortKey = GetAccessLevelValue,
            sortAscendingDescription = SORT_LOW,
            sortDescendingDescription = SORT_HIGH,
        },
        {
            key = "government",
            header = function() return Locale.Lookup("LOC_DIPLOMACY_OVERVIEW_GOVERNMENT") end,
            getCell = CellGovernment,
            sortKey = CellGovernment,
            sortAscendingDescription = SORT_AZ,
            sortDescendingDescription = SORT_ZA,
        },
        {
            -- No numeric value: full agenda text lives in the label, no tooltip.
            key = "agendas",
            header = function() return Locale.Lookup("LOC_DIPLOMACY_OVERVIEW_AGENDAS") end,
            getCell = TooltipAgendas,
            sortKey = AgendaSortKey,
            sortAscendingDescription = SORT_FEW,
            sortDescendingDescription = SORT_MOST,
        },
        {
            -- Numeric value (new-item count) in the label; last-ten-turns breakdown
            -- in the tooltip; Enter opens the full gossip log (a Button cell).
            key = "gossip",
            header = function() return Locale.Lookup("LOC_DIPLOMACY_OVERVIEW_GOSSIP") end,
            getCell = CellGossip,
            getTooltip = GossipRecentTooltip,
            onActivate = function(pid) OpenGossipPanel(pid) end,
            sortKey = GetGossipNewCount,
            sortAscendingDescription = SORT_FEW,
            sortDescendingDescription = SORT_MOST,
        },
        {
            -- No numeric value: the sorted list lives in the label, no tooltip.
            key = "foreign",
            header = function() return Locale.Lookup("LOC_CAI_DIPLOMACY_FOREIGN_RELATIONSHIPS") end,
            getCell = CellForeignRelations,
            sortKey = ForeignRelationsSortKey,
            sortAscendingDescription = SORT_LOW,
            sortDescendingDescription = SORT_HIGH,
        },
        {
            -- No numeric value: the agreement list lives in the label, no tooltip.
            key = "agreements",
            header = function() return Locale.Lookup("LOC_DIPLOMACY_OVERVIEW_AGREEMENTS") end,
            getCell = CellAgreements,
            sortKey = AgreementsSortKey,
            sortAscendingDescription = SORT_FEW,
            sortDescendingDescription = SORT_MOST,
        },
    }

    if IsExpansion1Active() then
        table.insert(columns, {
            key = "alliance",
            header = function() return Locale.Lookup("LOC_CAI_DIPLO_COLUMN_ALLIANCE") end,
            getCell = CellAlliance,
            getTooltip = TooltipAlliance,
            sortKey = AllianceSortKey,
            sortAscendingDescription = SORT_LOW,
            sortDescendingDescription = SORT_HIGH,
        })
    end

    if GrievanceColumnsActive() then
        table.insert(columns, {
            -- Value (per-turn change) in the label; status + breakdown in the
            -- tooltip; Enter opens the grievance log (a Button cell).
            key = "grievance-change",
            header = function() return Locale.Lookup("LOC_CAI_DIPLO_COLUMN_GRIEVANCE_CHANGE") end,
            getCell = function(pid) local i = GetGrievanceInfo(pid); return i and i.perTurnText or "" end,
            getTooltip = TooltipGrievanceChange,
            onActivate = function(pid) OpenGrievanceLog(pid) end,
            sortKey = function(pid) local i = GetGrievanceInfo(pid); return i and i.perTurn or nil end,
            sortAscendingDescription = SORT_LOW,
            sortDescendingDescription = SORT_HIGH,
        })
        table.insert(columns, {
            key = "grievance-you",
            header = function() return Locale.Lookup("LOC_CAI_DIPLO_COLUMN_GRIEVANCES_AGAINST_YOU") end,
            getCell = function(pid) local i = GetGrievanceInfo(pid); return i and tostring(i.againstYou) or "" end,
            onActivate = function(pid) OpenGrievanceLog(pid) end,
            sortKey = function(pid) local i = GetGrievanceInfo(pid); return i and i.againstYou or nil end,
            sortAscendingDescription = SORT_LOW,
            sortDescendingDescription = SORT_HIGH,
        })
        table.insert(columns, {
            key = "grievance-them",
            header = function() return Locale.Lookup("LOC_CAI_DIPLO_COLUMN_GRIEVANCES_AGAINST_THEM") end,
            getCell = function(pid) local i = GetGrievanceInfo(pid); return i and tostring(i.againstThem) or "" end,
            onActivate = function(pid) OpenGrievanceLog(pid) end,
            sortKey = function(pid) local i = GetGrievanceInfo(pid); return i and i.againstThem or nil end,
            sortAscendingDescription = SORT_LOW,
            sortDescendingDescription = SORT_HIGH,
        })
    end

    if IsSecretSocietiesActive() then
        table.insert(columns, {
            key = "secret-society",
            header = function() return Locale.Lookup("LOC_SECRETSOCIETY") end,
            getCell = function(pid) local i = GetSecretSocietyInfo(pid); return i and i.label or "" end,
            getTooltip = function(pid) local i = GetSecretSocietyInfo(pid); return i and i.tooltip or "" end,
            sortKey = function(pid) local i = GetSecretSocietyInfo(pid); return i and i.label or nil end,
            sortAscendingDescription = SORT_AZ,
            sortDescendingDescription = SORT_ZA,
        })
    end

    -- Emergency columns appear only when at least one leader has an entry in that
    -- bucket, matching vanilla's conditional Emergency tab.
    if IsExpansion1Active() then
        local hasParticipating, hasTargeting = false, false
        for _, pid in ipairs(leaderIDs) do
            if not hasParticipating and #GetEmergenciesForPlayer(pid, "participating") > 0 then
                hasParticipating = true
            end
            if not hasTargeting and #GetEmergenciesForPlayer(pid, "targeting") > 0 then
                hasTargeting = true
            end
            if hasParticipating and hasTargeting then break end
        end
        if hasParticipating then
            table.insert(columns, {
                key = "emergency-participating",
                header = function() return Locale.Lookup("LOC_CAI_DIPLO_COLUMN_EMERGENCY_PARTICIPATING") end,
                getCell = function(pid) return CellEmergencies(pid, "participating") end,
                sortKey = function(pid) return #GetEmergenciesForPlayer(pid, "participating") end,
                sortAscendingDescription = SORT_FEW,
                sortDescendingDescription = SORT_MOST,
            })
        end
        if hasTargeting then
            table.insert(columns, {
                key = "emergency-targeting",
                header = function() return Locale.Lookup("LOC_CAI_DIPLO_COLUMN_EMERGENCY_TARGETING") end,
                getCell = function(pid) return CellEmergencies(pid, "targeting") end,
                sortKey = function(pid) return #GetEmergenciesForPlayer(pid, "targeting") end,
                sortAscendingDescription = SORT_FEW,
                sortDescendingDescription = SORT_MOST,
            })
        end
    end

    return columns
end

local function ResolveColumnHeader(column)
    return type(column.header) == "function" and column.header() or column.header or ""
end

local function ColumnsSignature(columns)
    local keys = {}
    for _, column in ipairs(columns) do keys[#keys + 1] = column.key end
    return table.concat(keys, ",")
end

local function GetActiveColumn(key)
    for _, column in ipairs(m_activeColumns) do
        if column.key == key then return column end
    end
    return nil
end

-- Tree/table share one sort. The dropdown lists natural order plus, for each
-- sortable column, its two directions labelled by the same semantic tags the
-- header speaks.
local function BuildSortOptions(columns)
    local options = {
        { label = Locale.Lookup("LOC_CAI_DATATABLE_SORT_NATURAL"), value = { column = nil, ascending = false } },
    }
    for _, column in ipairs(columns) do
        if column.sortKey then
            local header = ResolveColumnHeader(column)
            table.insert(options, {
                label = header .. "[NEWLINE]" .. Locale.Lookup(column.sortDescendingDescription),
                value = { column = column.key, ascending = false },
            })
            table.insert(options, {
                label = header .. "[NEWLINE]" .. Locale.Lookup(column.sortAscendingDescription),
                value = { column = column.key, ascending = true },
            })
        end
    end
    return options
end

local function SyncSortDropdown()
    if not m_ui.treeSort then return end
    for index, option in ipairs(m_sortOptions) do
        local sort = option.value
        if sort.column == m_sortColumn and (sort.column == nil or sort.ascending == m_sortAscending) then
            m_ui.treeSort:SetSelectedIndex(index, true)
            return
        end
    end
end

-- Complete set of gossip groups, so the filter is stable regardless of which
-- leader is in view. LOC_HUD_REPORTS_FILTER_<GroupType> is the vanilla label.
local function BuildGossipGroupOptions()
    local seen = {}
    local options = { { label = Locale.Lookup("LOC_CAI_DIPLOMACY_GOSSIP_FILTER_ALL"), value = "ALL" } }
    for row in GameInfo.Gossips() do
        if row.GroupType and not seen[row.GroupType] then
            seen[row.GroupType] = true
            table.insert(options, {
                label = Locale.Lookup("LOC_HUD_REPORTS_FILTER_" .. row.GroupType),
                value = row.GroupType,
            })
        end
    end
    return options
end

local function SyncGossipFilterDropdown()
    if not m_ui.gossipFilter then return end
    for index, option in ipairs(m_gossipOptions) do
        if option.value == m_gossipGroupFilter then
            m_ui.gossipFilter:SetSelectedIndex(index, true)
            return
        end
    end
end

-- Recompute columns for the current state and rebuild the table widget only when
-- the leader set or column set actually changed. Always refreshes m_activeColumns
-- and the shared sort options (both cheap) so the tree sort stays consistent.
local function EnsureTableStructure()
    local leaderIDs = GetTableLeaderIDs()
    local columns = BuildTableColumns(leaderIDs)
    m_activeColumns = columns
    m_sortOptions = BuildSortOptions(columns)

    -- A dynamic column can drop out (era regress is impossible, but emergencies
    -- end and secret societies stay); clear a sort that points at a gone column.
    if m_sortColumn and not GetActiveColumn(m_sortColumn) then
        m_sortColumn = nil
        m_sortAscending = false
    end

    if not m_ui.table then return end

    local sig = ColumnsSignature(columns)
    local needs = sig ~= m_tableColumnSig or #leaderIDs ~= #m_tableLeaderOrder
    if not needs then
        for i, id in ipairs(leaderIDs) do
            if m_tableLeaderOrder[i] ~= id then
                needs = true
                break
            end
        end
    end
    if not needs then return end

    m_tableLeaderOrder = leaderIDs
    m_tableColumnSig = sig
    m_ui.table:SetColumns(columns)
    m_ui.table:SetDefaultSort(m_sortColumn
        and { column = m_sortColumn, ascending = m_sortAscending } or nil)
    m_ui.table:Rebuild()

    if m_ui.treeSort then
        local capture = mgr:CaptureFocusKey(m_ui.treeSort)
        m_ui.treeSort:SetOptions(m_sortOptions)
        SyncSortDropdown()
        if capture then mgr:RestoreFocus(m_ui.treeSort, capture) end
    end
end

-- Tree leader order: local player stays first; the rest follow the shared sort.
local function GetSortedTreeLeaderIDs()
    local localID, others = nil, {}
    for _, id in ipairs(GetLeaderIDs()) do
        if id == ms_LocalPlayerID then localID = id else others[#others + 1] = id end
    end
    local column = m_sortColumn and GetActiveColumn(m_sortColumn) or nil
    if column and column.sortKey then
        local decorated = {}
        for i, pid in ipairs(others) do
            decorated[i] = { pid = pid, idx = i, value = column.sortKey(pid) }
        end
        table.sort(decorated, function(x, y)
            local cmp = CompareSortValues(x.value, y.value)
            if cmp == 0 then return x.idx < y.idx end
            if m_sortAscending then return cmp < 0 end
            return cmp > 0
        end)
        others = {}
        for _, d in ipairs(decorated) do others[#others + 1] = d.pid end
    end
    local result = {}
    if localID ~= nil then result[#result + 1] = localID end
    for _, id in ipairs(others) do result[#result + 1] = id end
    return result
end

-- Focus the leader browser for the active view. Table view lands on the selected
-- leader's row (or the local-leader widget when self/none is selected); tree view
-- always lands on the tree, per the requested focus rules.
local function FocusLeaderView(focusPlayerID)
    if m_viewMode == "tree" then
        if not m_ui.leadersTree then return end
        if focusPlayerID ~= nil and focusPlayerID >= 0 then
            mgr:PrepareFocus(m_ui.leadersTree, "diplo:leader:" .. tostring(focusPlayerID))
        end
        mgr:SetFocus(m_ui.leadersTree)
        return
    end
    if not m_ui.table then return end
    if focusPlayerID == nil or focusPlayerID < 0 or focusPlayerID == ms_LocalPlayerID then
        if m_ui.localLeader then
            mgr:SetFocus(m_ui.localLeader)
            return
        end
    end
    mgr:PrepareFocus(m_ui.table, GetTableRowFocusKey(focusPlayerID))
    mgr:SetFocus(m_ui.table)
end

local function SetViewMode(viewMode)
    if viewMode ~= "table" and viewMode ~= "tree" then
        LogError("Diplomacy received invalid view mode " .. tostring(viewMode))
        return false
    end
    if m_viewMode ~= viewMode then
        m_viewMode = viewMode
        SaveViewModeSetting(viewMode)
    end
    FocusLeaderView(ms_SelectedPlayerID)
    return true
end

local function ToggleViewMode()
    return SetViewMode(m_viewMode == "table" and "tree" or "table")
end

-- Enter on a gossip cell: full gossip for that leader plus a group filter.
function OpenGossipPanel(playerID)
    if not mgr or mgr:GetWidgetById(GOSSIP_PANEL_ID) then return end
    -- Not Transparent: a real container so the list is its own navigation boundary
    -- and wraps its own items (a Transparent panel would flatten filter + items
    -- into one flow governed by the panel's wrap).
    local panel = mgr:CreateWidget(GOSSIP_PANEL_ID, "Panel", {
        Label = function()
            return JoinNonEmpty({ Locale.Lookup("LOC_DIPLOMACY_OVERVIEW_GOSSIP"), GetLeaderRowLabel(playerID) }, ", ")
        end,
    })

    local items = GetGossipItemsForPlayer(playerID)
    local list = mgr:CreateWidget(GOSSIP_PANEL_ID .. "_List", "List", {
        SpeechSettings = { Position = false },
        Label = function() return Locale.Lookup("LOC_DIPLOMACY_OVERVIEW_GOSSIP") end,
    })

    local function RebuildGossipList()
        local capture = mgr:CaptureFocusKey(list)
        list:ClearChildren()
        local currentTurn = Game.GetCurrentGameTurn()
        local added = false
        for gi, item in ipairs(items) do
            local gossipData = GameInfo.Gossips[item[3]]
            local pass = m_gossipGroupFilter == "ALL"
                or (gossipData and gossipData.GroupType == m_gossipGroupFilter)
            if pass and item[1] then
                -- Reuse the reports screen's gossip-entry string (turn + leader).
                local label = FormatGossipLine(playerID, item[2], item[1], item[2] and (currentTurn - 1) <= item[2])
                list:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAIDiplomacyGossipEntry"), "StaticText", {
                    Label = function() return label end,
                    FocusKey = "diplo:gossipentry:" .. tostring(gi),
                }))
                added = true
            end
        end
        if not added then
            list:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAIDiplomacyGossipEntry"), "StaticText", {
                Label = function() return Locale.Lookup("LOC_DIPLOMACY_GOSSIP_ITEM_NO_RECENT") end,
            }))
        end
        mgr:RestoreFocus(list, capture)
    end

    local filter = mgr:CreateWidget(GOSSIP_PANEL_ID .. "_Filter", "Dropdown", {
        Label = function() return Locale.Lookup("LOC_CAI_DIPLOMACY_GOSSIP_FILTER") end,
        FocusKey = "diplo:gossippanel:filter",
    })
    local panelOptions = BuildGossipGroupOptions()
    filter:SetOptions(panelOptions)
    for i, opt in ipairs(panelOptions) do
        if opt.value == m_gossipGroupFilter then
            filter:SetSelectedIndex(i, true)
            break
        end
    end
    filter:On("value_changed", function(_, val)
        m_gossipGroupFilter = val
        RebuildGossipList()
        SyncGossipFilterDropdown()
    end)

    panel:AddChild(filter)
    panel:AddChild(list)
    RebuildGossipList()
    panel:AddInputBindings({ {
        Key = Keys.VK_ESCAPE,
        Description = "LOC_CAI_KB_CLOSE",
        Action = function()
            mgr:RemoveFromStack(GOSSIP_PANEL_ID)
            return true
        end,
    } })
    mgr:Push(panel, { focus = list })
end

-- Enter on any grievance cell: the full grievance log for that leader.
function OpenGrievanceLog(playerID)
    if not mgr or mgr:GetWidgetById(GRIEVANCE_LOG_ID) then return end
    local entries = GetGrievanceLogEntriesForPlayer(playerID)
    local list = mgr:CreateWidget(GRIEVANCE_LOG_ID, "List", {
        Label = function()
            return JoinNonEmpty({ Locale.Lookup("LOC_CAI_DIPLOMACY_GRIEVANCE_LOG"), GetLeaderRowLabel(playerID) }, ", ")
        end,
    })
    if #entries == 0 then
        list:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAIDiplomacyGrievanceLogEntry"), "StaticText", {
            Label = function() return Locale.Lookup("LOC_CAI_DIPLOMACY_GRIEVANCE_LOG_EMPTY") end,
        }))
    else
        for _, text in ipairs(entries) do
            list:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAIDiplomacyGrievanceLogEntry"), "StaticText", {
                Label = function() return text end,
            }))
        end
    end
    list:AddInputBindings({ {
        Key = Keys.VK_ESCAPE,
        Description = "LOC_CAI_KB_CLOSE",
        Action = function()
            mgr:RemoveFromStack(GRIEVANCE_LOG_ID)
            return true
        end,
    } })
    mgr:Push(list, { focus = list })
end

-- ============================================================================
-- Leaders tree
-- ============================================================================

local function CreateLeaderNode(playerID)
    local currentID = playerID
    if currentID == ms_LocalPlayerID then
        local row = mgr:CreateWidget(GetLeaderRowId(currentID), "StaticText", {
            Label = function() return BuildSelfLeaderTooltip(currentID) end,
            FocusKey = "diplo:leader:" .. tostring(currentID),
        })
        PlayHoverSound(row)
        row:On("focus_enter", function()
            if not m_state.syncingLeaderSelection and ms_SelectedPlayerID ~= currentID then
                m_state.selectingFromRow = true
                SelectPlayer(currentID, CAI_OVERVIEW_MODE)
                m_state.selectingFromRow = false
            end
        end)
        row.CAI_PlayerID = currentID
        return row
    end

    local row = mgr:CreateWidget(GetLeaderRowId(currentID), "TreeItem", {
        Label    = function() return GetLeaderRowLabel(currentID) end,
        Tooltip  = function()
            return BuildLeaderOverviewTooltip(currentID)
        end,
        FocusKey = "diplo:leader:" .. tostring(currentID),
    })
    PlayHoverSound(row)
    -- Reselect whenever this leader's subtree is entered (not just when the row
    -- itself is the focus leaf). With the row expanded, arrowing back up from
    -- another leader lands on one of this leader's intel children, firing the
    -- row's focus_enter as a non-leaf; if we bailed there, vanilla would stay on
    -- the other leader and the intel readers (which key off ms_SelectedPlayerID)
    -- would render the wrong leader's data. Compare against the live vanilla
    -- selection rather than the CAI mirror.
    row:On("focus_enter", function(w)
        if not m_state.syncingLeaderSelection and ms_SelectedPlayerID ~= currentID then
            -- The user focused into this leader; flag it so SelectPlayer doesn't
            -- re-focus the same row (which would re-announce it).
            m_state.selectingFromRow = true
            SelectPlayer(currentID, CAI_OVERVIEW_MODE)
            m_state.selectingFromRow = false
        end
        if w:IsFocused() and currentID ~= ms_LocalPlayerID then
            ShowOverviewPanel()
        end
    end)
    row.CAI_PlayerID = currentID
    return row
end

local function EnsureLeadersTreeStructure()
    if not m_ui.leadersTree then return end

    local leaderIDs = GetSortedTreeLeaderIDs()
    local needsRebuild = #leaderIDs ~= #m_ui.leaderOrder
    if not needsRebuild then
        for index, playerID in ipairs(leaderIDs) do
            if m_ui.leaderOrder[index] ~= playerID then
                needsRebuild = true
                break
            end
        end
    end
    if not needsRebuild then return end

    local capture = mgr:CaptureFocusKey(m_ui.leadersTree)
    m_ui.leadersTree:ClearChildren()
    m_ui.leaderEntries = {}
    m_ui.leaderOrder = leaderIDs

    for _, playerID in ipairs(leaderIDs) do
        local entry = { PlayerID = playerID, Row = CreateLeaderNode(playerID) }
        m_ui.leaderEntries[playerID] = entry
        m_ui.leadersTree:AddChild(entry.Row)
    end

    mgr:RestoreFocus(m_ui.leadersTree, capture)
end

-- Rebuild both leader views (table structure first so the tree can read the
-- shared sort's active column). Cheap when nothing structural changed.
local function EnsureLeaderViews()
    EnsureTableStructure()
    EnsureLeadersTreeStructure()
end

local function SyncSelectedLeaderRow()
    if not m_ui.root then return end
    if not IsRootPushed() then return end

    m_state.syncingLeaderSelection = true
    FocusLeaderView(ms_SelectedPlayerID)
    m_state.syncingLeaderSelection = false
end

local function RefreshOverview()
    -- Short-circuit while harvesting sub-menu options (the eager sub-action
    -- population re-enters PopulateStatementList with the suppress flag set);
    -- we don't want any CAI rebuild for those transient sub-list passes.
    if m_state.suppressActionsRebuild then return end
    if not m_ui.overviewPanel then return end
    EnsureLeaderViews()
    if not m_state.buildingIntel and ms_SelectedPlayerID ~= nil and ms_SelectedPlayerID >= 0 then
        BuildSelectedLeaderChildren()
    end
    RebuildActionsList()
end

-- ============================================================================
-- Conversation panel
-- ============================================================================

local function GetConversationSelectionTooltip(selection)
    if selection.IsDisabled and selection.FailureReasons and selection.FailureReasons[1] then
        return Locale.Lookup(selection.FailureReasons[1])
    end
    if selection.Tooltip then
        return Locale.Lookup(selection.Tooltip)
    end
    return ""
end

local function FilterConversationSelections(selections)
    local filtered = {}
    if not selections then return filtered end
    for _, selection in ipairs(selections) do
        if selection.Key ~= "CHOICE_STOP_ASKING" or not GetOtherPlayer():IsHuman() then
            table.insert(filtered, selection)
        end
    end
    return filtered
end

local function UpdateConversationBindings(handler, statementTypeName, statementSubTypeName, toPlayer, kStatement)
    local mood = GetStatementMood(kStatement.FromPlayer, kStatement.FromPlayerMood)
    local parsed = handler.ExtractStatement(handler, statementTypeName, statementSubTypeName, kStatement.FromPlayer, mood,
        kStatement.Initiator)
    handler.RemoveInvalidSelections(parsed, ms_LocalPlayerID, ms_OtherPlayerID)

    -- Selections are kept only to recover a reply's label/tooltip fallback and to
    -- spot the explicit exit choice; activation fires the live button's own
    -- vanilla callback via DoLeftClick, so the handler is no longer stored.
    m_vanilla.conversationBindings = {
        Selections = FilterConversationSelections(parsed.Selections),
    }
end

local function RefreshConversationPanel()
    if not m_ui.conversationList then return end
    m_ui.conversationList:ClearChildren()
    -- A conversation rebuild always presents a fresh leader response, so focus
    -- belongs on the first item (the response text), never the positional slot of
    -- the reply just picked. Drop the entry-descent cache so FocusConversationIfReady
    -- lands on the first child instead of restoring a remembered choice button (the
    -- replies carry no FocusKey, so a capture/restore would only match by index).
    m_ui.conversationList._lastFocusedKey = nil
    m_ui.conversationList._lastFocusedChild = nil

    local responseText = ControlText(Controls.LeaderResponseText)
    if responseText ~= "" then
        m_ui.conversationList:AddChild(mgr:CreateWidget("CAIDiplomacyConversationText", "StaticText", {
            Label = function() return ControlText(Controls.LeaderResponseText) end,
        }))
    end

    local reasonText = ControlText(Controls.LeaderReasonText)
    if reasonText ~= "" then
        m_ui.conversationList:AddChild(mgr:CreateWidget("CAIDiplomacyConversationReason", "StaticText", {
            Label = function() return ControlText(Controls.LeaderReasonText) end,
        }))
    end

    -- The ConversationSelectionInstance pool re-parents each reused instance to
    -- the BOTTOM of the stack on GetInstance and hides the ones it does not reuse
    -- (see InstanceManager:GetInstance / :ResetInstances). So whenever a prior
    -- statement created more selection buttons than the current one,
    -- GetChildren() returns stale hidden leftovers AHEAD of the live buttons.
    -- Indexing the raw child list then maps a selection onto a hidden leftover
    -- and inherits its stale label/disabled state (e.g. an active "Goodbye"
    -- reading "unavailable"). Keep only the visible children: they line up, in
    -- order, with the filtered selection list -- both are exactly what vanilla
    -- renders this pass.
    local rawButtons = Controls.ConversationSelectionStack
        and Controls.ConversationSelectionStack.GetChildren
        and Controls.ConversationSelectionStack:GetChildren()
        or {}
    local liveButtons = {}
    for _, button in ipairs(rawButtons) do
        if not ControlIsHidden(button) then
            table.insert(liveButtons, button)
        end
    end

    -- Drive the list off the visible buttons, not off the re-extracted selection
    -- list, so CAI exposes exactly the choices vanilla renders -- never a phantom
    -- row for a selection vanilla dropped, never one short. The live button
    -- supplies label/tooltip/disabled; the selection supplies only the choice Key
    -- for activation. Pair the two by matching the button's on-screen label to the
    -- selection's localized Text (vanilla sets the label from exactly that Text),
    -- NOT by index: CAI's re-derivation is not always identical to vanilla's
    -- render -- a disabled reply can survive in the rendered stack while
    -- RemoveInvalidSelections drops it here -- which would shift every index after
    -- it. Enabled replies are always valid, so their selection survives and
    -- matches, giving activation its Key; a disabled button that fails to match
    -- stays readable and inert (it needs no Key).
    local selections = m_vanilla.conversationBindings and m_vanilla.conversationBindings.Selections or {}
    local remainingSelections = {}
    for _, selection in ipairs(selections) do
        table.insert(remainingSelections, selection)
    end
    local function TakeSelectionForLabel(label)
        if label == "" then return nil end
        for i, selection in ipairs(remainingSelections) do
            if Locale.Lookup(selection.Text or "") == label then
                table.remove(remainingSelections, i)
                return selection
            end
        end
        return nil
    end

    for _, buttonControl in ipairs(liveButtons) do
        local currentSelection = TakeSelectionForLabel(ControlButtonText(buttonControl))

        local choice = mgr:CreateWidget(
            mgr:GenerateWidgetId("CAIDiplomacyConversationButton"), "Button", {
                Label = function()
                    local liveText = ControlButtonText(buttonControl)
                    if liveText ~= "" then return liveText end
                    return currentSelection and Locale.Lookup(currentSelection.Text or "") or ""
                end,
                Tooltip = function()
                    local liveTooltip = ControlTooltip(buttonControl)
                    if liveTooltip ~= "" then return liveTooltip end
                    return currentSelection and GetConversationSelectionTooltip(currentSelection) or ""
                end,
                DisabledPredicate = function()
                    return ControlIsDisabled(buttonControl)
                end,
            })
        PlayHoverSound(choice)
        choice:On("activate", function()
            -- Fire the button's own vanilla click callback (the exact
            -- OnSelectionButtonClicked closure, including any war-confirm or
            -- stop-asking popup it wires) instead of re-dispatching a re-derived
            -- key -- so activation is always correct even when the pairing above
            -- found no selection. Disabled buttons register no callback, and the
            -- manager already no-ops Activate on them, so this stays safe.
            if buttonControl.DoLeftClick then
                buttonControl:DoLeftClick()
            end
            -- Leaving the conversation tears the CAI list down; the session-closed
            -- wrap clears it too, this just keeps parity on the explicit exit.
            if currentSelection and currentSelection.Key == "CHOICE_EXIT" then
                ClearConversationState()
            end
        end)
        m_ui.conversationList:AddChild(choice)
    end

    FocusConversationIfReady()
end

-- ============================================================================
-- Build / lifecycle
-- ============================================================================

local function EnsureRootBuilt()
    if m_ui.root then return end

    m_ui.root = mgr:CreateWidget(ROOT_ID, "Panel", {
        Transparent = true,
    })
    m_ui.root:SetWrapAround(false)
    -- View panels are structural (the root carries the leader title and each
    -- inner tree/list has its own label), so they are Transparent — they must
    -- not announce a bare "panel" or re-speak the title on every focus change.
    m_ui.overviewPanel = mgr:CreateWidget(OVERVIEW_PANEL_ID, "Panel", {
        SpeechSettings = { Position = false },
        HiddenPredicate = function() return ControlIsHidden(Controls.OverviewContainer) end,
        Label = function() return GetPanelLabel() end,
    })
    -- Alt+1 / Alt+2 switch view from anywhere in the overview (input bubbles up).
    m_ui.overviewPanel:AddInputBindings({
        {
            Key = Keys["1"], IsAlt = true, MSG = KeyEvents.KeyDown,
            Description = "LOC_CAI_TREE_SWITCH_TO_TABLE",
            Action = function() return SetViewMode("table") end,
        },
        {
            Key = Keys["2"], IsAlt = true, MSG = KeyEvents.KeyDown,
            Description = "LOC_CAI_TREE_SWITCH_TO_TREE",
            Action = function() return SetViewMode("tree") end,
        },
    })

    -- Local leader (table view only): the local player sits outside the table.
    -- Focusing it selects the local leader in vanilla, mirroring the tree's self
    -- node. Focus leaving it lands on the table's remembered/first row on its own.
    m_ui.localLeader = mgr:CreateWidget(LOCAL_LEADER_ID, "StaticText", {
        Label = function() return BuildSelfLeaderTooltip(ms_LocalPlayerID) end,
        FocusKey = "diplo:localleader",
        HiddenPredicate = function() return m_viewMode ~= "table" end,
    })
    PlayHoverSound(m_ui.localLeader)
    m_ui.localLeader:On("focus_enter", function(w)
        if w:IsFocused() and not m_state.syncingLeaderSelection and ms_SelectedPlayerID ~= ms_LocalPlayerID then
            m_state.selectingFromRow = true
            SelectPlayer(ms_LocalPlayerID, CAI_OVERVIEW_MODE)
            m_state.selectingFromRow = false
        end
    end)
    -- Leaving the local leader restores selection to the last leader focused in
    -- the table (the local player if none yet), so navigating back into the table
    -- returns to the leader you were on. Guarded so it never steals focus.
    m_ui.localLeader:On("focus_leave", function()
        local target = m_lastTableLeaderID or ms_LocalPlayerID
        if not m_state.syncingLeaderSelection and ms_SelectedPlayerID ~= target then
            m_state.selectingFromRow = true
            SelectPlayer(target, CAI_OVERVIEW_MODE)
            m_state.selectingFromRow = false
        end
    end)

    -- Tree-view sort dropdown (headers do the sorting in table view).
    m_ui.treeSort = mgr:CreateWidget(TREE_SORT_ID, "Dropdown", {
        Label = function() return Locale.Lookup("LOC_CAI_REPORTS_SORT_BY") end,
        FocusKey = "diplo:tree-sort",
        HiddenPredicate = function() return m_viewMode ~= "tree" end,
    })
    m_ui.treeSort:SetOptions(m_sortOptions)
    SyncSortDropdown()
    m_ui.treeSort:On("value_changed", function(_, sort)
        m_sortColumn = sort.column
        m_sortAscending = sort.ascending == true
        if m_ui.table then
            m_ui.table:SetDefaultSort(sort.column
                and { column = sort.column, ascending = sort.ascending } or nil)
            m_ui.table:Rebuild()
        end
        EnsureLeadersTreeStructure()
    end)

    -- Tree-view gossip filter (the drill-down panel is unavailable in the tree).
    m_ui.gossipFilter = mgr:CreateWidget(GOSSIP_FILTER_ID, "Dropdown", {
        Label = function() return Locale.Lookup("LOC_CAI_DIPLOMACY_GOSSIP_FILTER") end,
        FocusKey = "diplo:gossip-filter",
        HiddenPredicate = function() return m_viewMode ~= "tree" end,
    })
    m_gossipOptions = BuildGossipGroupOptions()
    m_ui.gossipFilter:SetOptions(m_gossipOptions)
    SyncGossipFilterDropdown()
    m_ui.gossipFilter:On("value_changed", function(_, val)
        m_gossipGroupFilter = val
        if not m_state.buildingIntel and ms_SelectedPlayerID ~= nil and ms_SelectedPlayerID >= 0 then
            BuildSelectedLeaderChildren()
        end
    end)

    m_ui.table = mgr:CreateWidget(TABLE_ID, "DataTable", {
        Label           = function() return Locale.Lookup("LOC_CAI_DIPLOMACY_LEADERS") end,
        HiddenPredicate = function() return m_viewMode ~= "table" end,
    })
    m_ui.table:SetRowsProvider(GetTableLeaderIDs)
    m_ui.table:SetRowKeyGetter(function(pid) return pid end)
    m_ui.table:SetRowLabelGetter(function(pid) return GetLeaderRowLabel(pid) end)
    m_ui.table:On("row_focus_enter", function(_, playerID, rowIndex)
        if rowIndex and rowIndex > 0 and playerID then
            m_lastTableLeaderID = playerID
            if not m_state.syncingLeaderSelection and ms_SelectedPlayerID ~= playerID then
                m_state.selectingFromRow = true
                SelectPlayer(playerID, CAI_OVERVIEW_MODE)
                m_state.selectingFromRow = false
            end
        end
    end)
    -- Drill-downs are per-cell Button columns (onActivate), so the table needs no
    -- row_activate; leader selection happens on row_focus_enter above.
    m_ui.table:On("sort_changed", function(_, columnKey, ascending)
        m_sortColumn = columnKey
        m_sortAscending = ascending == true
        SyncSortDropdown()
        EnsureLeadersTreeStructure()
    end)

    m_ui.leadersTree = mgr:CreateWidget(LEADERS_TREE_ID, "Tree", {
        Label           = function() return Locale.Lookup("LOC_CAI_DIPLOMACY_LEADERS") end,
        HiddenPredicate = function() return m_viewMode ~= "tree" end,
    })
    -- Always present in the tab chain (shows a read-only "no actions" entry for
    -- self) so Shift+Tab from the switch-view button reliably reaches it.
    m_ui.actionsList = mgr:CreateWidget(ACTIONS_LIST_ID, "List", {
        Label = function() return Locale.Lookup("LOC_CAI_DIPLOMACY_ACTIONS") end,
    })

    m_ui.switchView = mgr:CreateWidget(SWITCH_VIEW_ID, "Button", {
        Label = function()
            return Locale.Lookup(m_viewMode == "table"
                and "LOC_CAI_TREE_SWITCH_TO_TREE"
                or "LOC_CAI_TREE_SWITCH_TO_TABLE")
        end,
    })
    m_ui.switchView:On("activate", function() ToggleViewMode() end)

    -- Child order defines Tab order; hidden widgets are skipped. Table view:
    -- local leader, table, actions, switch. Tree view: sort, gossip filter,
    -- tree, actions, switch.
    m_ui.overviewPanel:AddChild(m_ui.localLeader)
    m_ui.overviewPanel:AddChild(m_ui.treeSort)
    m_ui.overviewPanel:AddChild(m_ui.gossipFilter)
    m_ui.overviewPanel:AddChild(m_ui.table)
    m_ui.overviewPanel:AddChild(m_ui.leadersTree)
    m_ui.overviewPanel:AddChild(m_ui.actionsList)
    m_ui.overviewPanel:AddChild(m_ui.switchView)

    m_ui.conversationPanel = mgr:CreateWidget(CONVERSATION_PANEL_ID, "Panel", {
        Transparent     = true,
        HiddenPredicate = function() return ControlIsHidden(Controls.ConversationContainer) end,
    })
    m_ui.conversationPanel:SetWrapAround(false)
    m_ui.conversationList = mgr:CreateWidget(CONVERSATION_LIST_ID, "List", {
        SpeechSettings = { Position = false },
        Label          = function()
            local title = ControlText(Controls.LeaderResponseName)
            if title ~= "" then return title end
            return GetPanelLabel()
        end,
    })
    m_ui.conversationPanel:AddChild(m_ui.conversationList)

    -- Cinema has no readable content of its own (the leader's line shows up in
    -- the conversation list once cinema reveals it), so this panel is a silent,
    -- childless focus holder: Transparent so it announces nothing, navigable only
    -- while m_state.cinema is set. Focusing it captures input (arrows do nothing,
    -- Escape/clicks bubble to vanilla) without speaking and without letting the
    -- overview grab focus by default during the cinematic.
    m_ui.cinemaPanel = mgr:CreateWidget(CINEMA_PANEL_ID, "Panel", {
        SpeechSettings = { Position = false },
        Label = function() return GetPanelLabel() end,
        HiddenPredicate = function() return not m_state.cinema end,
    })
    m_ui.cinemaPanel:SetWrapAround(false)
    m_ui.root:AddChild(m_ui.overviewPanel)
    m_ui.root:AddChild(m_ui.conversationPanel)
    m_ui.root:AddChild(m_ui.cinemaPanel)

    EnsureLeaderViews()
end

local function ResetState()
    m_ui = {
        root = nil,
        overviewPanel = nil,
        conversationPanel = nil,
        cinemaPanel = nil,
        leadersTree = nil,
        table = nil,
        localLeader = nil,
        treeSort = nil,
        gossipFilter = nil,
        switchView = nil,
        actionsList = nil,
        conversationList = nil,
        leaderEntries = {},
        leaderOrder = {},
    }
    m_tableLeaderOrder = {}
    m_tableColumnSig = nil
    m_activeColumns = {}
    m_lastTableLeaderID = nil
    m_state.syncingLeaderSelection = false
    m_state.selectingFromRow = false
    m_state.suppressActionsRebuild = false
    m_state.suppressActionsFocus = false
    m_state.buildingIntel = false
    m_state.selectedPlayer = -1
    m_state.cinema = false
    m_vanilla.intelInstances = {}
    m_vanilla.actionLists = { root = {}, sub = {} }
    m_vanilla.conversationBindings = nil
end

local function DestroyRoot()
    if m_ui.root and mgr then
        if mgr:GetWidgetById(ROOT_ID) then
            mgr:RemoveFromStack(ROOT_ID)
        else
            m_ui.root:Destroy()
        end
    end
    ResetState()
end

-- Push focusing the right child for the current view: the cinema panel while a
-- cinematic intro is playing (so the screen has a real focus target even when it
-- opens straight into the cinematic), otherwise the *selected* leader's row --
-- not the tree's first visible row (which is self). m_state.selectedPlayer is
-- pre-set by the caller so the row's focus_enter guard sees itself as already
-- selected and doesn't re-trigger SelectPlayer. After this first push the tree's
-- _lastFocusedKey cache keeps later re-entries on the right row.
local function PushRootFocusingSelected()
    if not mgr then return end
    EnsureRootBuilt()
    if IsRootPushed() then return end
    EnsureLeaderViews()
    if m_state.cinema then
        mgr:Push(m_ui.root, { priority = PopupPriority.Utmost, focus = m_ui.cinemaPanel })
        return
    end
    -- Opening straight into a conversation (e.g. an AI request to place an embassy):
    -- vanilla runs OnDiplomacyStatement -> SetConversationMode + ApplyStatement
    -- BEFORE OnShow, so the conversation container is already shown and its list
    -- populated by the time we push, but the overview panel is hidden. Land on the
    -- conversation list rather than the selected leader's row, which sits inside the
    -- hidden overview -- SetFocus to an explicit target does not reject hidden
    -- ancestors, so focusing the row there would silently navigate into a hidden tree.
    if IsConversationContainerShown() then
        mgr:Push(m_ui.root, {
            priority = PopupPriority.Utmost,
            focus = HasConversationChildren() and m_ui.conversationList or m_ui.conversationPanel
        })
        return
    end
    -- Table view lands on the selected leader's row (or the local-leader widget
    -- when self/none is selected); tree view always lands on the tree.
    local focusTarget
    if m_viewMode == "tree" then
        if ms_SelectedPlayerID ~= nil and ms_SelectedPlayerID >= 0 then
            focusTarget = "diplo:leader:" .. tostring(ms_SelectedPlayerID)
        else
            focusTarget = m_ui.leadersTree
        end
    elseif ms_SelectedPlayerID ~= nil and ms_SelectedPlayerID >= 0
        and ms_SelectedPlayerID ~= ms_LocalPlayerID then
        focusTarget = GetTableRowFocusKey(ms_SelectedPlayerID)
    else
        focusTarget = m_ui.localLeader
    end
    if focusTarget then
        mgr:Push(m_ui.root, { priority = PopupPriority.Utmost, focus = focusTarget })
    else
        mgr:Push(m_ui.root, PopupPriority.Utmost)
    end
end

-- ============================================================================
-- Vanilla wraps
-- ============================================================================

local originalApplyStatement = ApplyStatement
ApplyStatement = WrapFunc(ApplyStatement,
    function(orig, handler, statementTypeName, statementSubTypeName, toPlayer, kStatement)
        orig(handler, statementTypeName, statementSubTypeName, toPlayer, kStatement)
        UpdateConversationBindings(handler, statementTypeName, statementSubTypeName, toPlayer, kStatement)
        RefreshConversationPanel()
    end)

function ReapplyStatementHandlers()
    for _, statementHandler in pairs(StatementHandlers) do
        if statementHandler and statementHandler.ApplyStatement == originalApplyStatement then
            statementHandler.ApplyStatement = ApplyStatement
        end
    end
end

PopulateStatementList = WrapFunc(PopulateStatementList, function(orig, options, rootControl, isSubList)
    local buttonIM = isSubList and g_ActionListIM or g_SubActionListIM
    local createdInstances = {}
    local originalGetInstance = buttonIM.GetInstance

    buttonIM.GetInstance = function(self, ...)
        local instance = originalGetInstance(self, ...)
        table.insert(createdInstances, instance)

        local button = instance.Button
        local originalRegister = button.RegisterCallback
        button.RegisterCallback = function(control, event, callback)
            if event == Mouse.eLClick then
                instance.__CAI_ClickCallback = callback
            end
            return originalRegister(control, event, callback)
        end

        instance.__CAI_OriginalRegisterCallback = originalRegister
        return instance
    end

    orig(options, rootControl, isSubList)
    buttonIM.GetInstance = originalGetInstance

    for _, instance in ipairs(createdInstances) do
        if instance.Button and instance.__CAI_OriginalRegisterCallback then
            instance.Button.RegisterCallback = instance.__CAI_OriginalRegisterCallback
            instance.__CAI_OriginalRegisterCallback = nil
        end
    end

    CaptureActionList(options, isSubList, createdInstances)
    RefreshOverview()
end)

-- The selected leader's sections are (re)built from the finished tab bar in the
-- SelectPlayer wrap, after orig() has created every tab. The DLC alliance /
-- emergency / world-congress adders build their buttons through CreateTabButton
-- and fire DiploScene_RefreshTabs / RefreshOverviewRows *during* this build, so
-- flag the build window to keep those handlers from rebuilding against a
-- half-built tab stack.
AddIntelPanel = WrapFunc(AddIntelPanel, function(orig, rootControl, ...)
    m_state.buildingIntel = true
    local result = orig(rootControl, ...)
    m_state.buildingIntel = false
    return result
end)

PopulateIntelOverview = WrapFunc(PopulateIntelOverview, function(orig, overviewInstance, ...)
    local result = orig(overviewInstance, ...)
    if overviewInstance then m_vanilla.intelInstances.overview = overviewInstance end
    return result
end)

OnActivateIntelGossipHistoryPanel = WrapFunc(OnActivateIntelGossipHistoryPanel, function(orig, gossipInstance, ...)
    local result = orig(gossipInstance, ...)
    if gossipInstance then m_vanilla.intelInstances.gossip = gossipInstance end
    return result
end)

OnActivateIntelAccessLevelPanel = WrapFunc(OnActivateIntelAccessLevelPanel, function(orig, accessLevelInstance, ...)
    local result = orig(accessLevelInstance, ...)
    if accessLevelInstance then m_vanilla.intelInstances.access = accessLevelInstance end
    return result
end)

OnActivateIntelRelationshipPanel = WrapFunc(OnActivateIntelRelationshipPanel, function(orig, relationshipInstance, ...)
    local result = orig(relationshipInstance, ...)
    if relationshipInstance then m_vanilla.intelInstances.relationship = relationshipInstance end
    return result
end)

local originalMakeDealApplyStatement = MakeDeal_ApplyStatement
MakeDeal_ApplyStatement = WrapFunc(MakeDeal_ApplyStatement, function(orig, ...)
    ClearConversationState()
    return orig(...)
end)
if StatementHandlers["MAKE_DEAL"] and StatementHandlers["MAKE_DEAL"].ApplyStatement == originalMakeDealApplyStatement then
    StatementHandlers["MAKE_DEAL"].ApplyStatement = MakeDeal_ApplyStatement
end

local originalMakeDemandApplyStatement = MakeDemand_ApplyStatement
MakeDemand_ApplyStatement = WrapFunc(MakeDemand_ApplyStatement, function(orig, ...)
    ClearConversationState()
    return orig(...)
end)
if StatementHandlers["MAKE_DEMAND"] and StatementHandlers["MAKE_DEMAND"].ApplyStatement == originalMakeDemandApplyStatement then
    StatementHandlers["MAKE_DEMAND"].ApplyStatement = MakeDemand_ApplyStatement
end

OnDiplomacySessionClosed = WrapFunc(OnDiplomacySessionClosed, function(orig, ...)
    orig(...)
    ClearConversationState()
end)

OnHide = WrapFunc(OnHide, function(orig)
    SetAlwaysReceivesInput(false)
    DestroyRoot()
    orig()
end)
ContextPtr:SetHideHandler(OnHide)

OnShutdown = WrapFunc(OnShutdown, function(orig)
    SetAlwaysReceivesInput(false)
    DestroyRoot()
    orig()
end)
ContextPtr:SetShutdown(OnShutdown)

SetConversationMode = WrapFunc(SetConversationMode, function(orig, player)
    orig(player)
    -- Leaving any cinematic intro: the conversation is now the live view.
    m_state.cinema = false
    -- orig shows the vanilla ConversationContainer, so the conversation panel is
    -- now navigable. Focus only if the conversation list is already populated;
    -- otherwise the ApplyStatement -> RefreshConversationPanel pass focuses it
    -- with fresh text.
    FocusConversationIfReady()
end)

SelectPlayer = WrapFunc(SelectPlayer, function(orig, playerID, mode, refresh, allowDeadPlayer)
    EnsureRootBuilt()
    local prevSelected = m_state.selectedPlayer
    local fromRow = m_state.selectingFromRow
    -- Set the guard before orig so any focus settling on this leader's row does
    -- not recursively re-enter SelectPlayer.
    m_state.selectedPlayer = playerID
    -- Track cinema across the SelectPlayer/OnShow split: a voiced open calls
    -- SelectPlayer(CINEMA) while hidden, then OnShow plays the cinematic. This
    -- flag drives the cinema panel's HiddenPredicate and tells OnShow's push (and
    -- the in-place focus below) to land on the cinema panel.
    m_state.cinema = mode == CAI_CINEMA_MODE
    -- Vanilla SelectPlayer rebuilds the statement list (-> RebuildActionsList)
    -- and only afterwards flips into conversation/cinema. The actions list is
    -- hidden in those modes and the conversation list (or cinema line) is the
    -- real destination, so suppress the actions focus restore for the duration
    -- of orig() -- otherwise a picked sub-option whose submenu just dissolved
    -- falls to the positional restore and audibly lands on a leftover button
    -- (e.g. Casus Belli) before the conversation speaks. DEAL mode is excluded:
    -- the triggering button (Make Deal/Demand) survives the rebuild, so its
    -- restore is a silent FocusKey match that also preserves the spot to return
    -- to when the deal closes.
    m_state.suppressActionsFocus = mode == CAI_CONVERSATION_MODE
        or mode == CAI_CINEMA_MODE
    orig(playerID, mode, refresh, allowDeadPlayer)
    m_state.suppressActionsFocus = false
    EnsureLeaderViews()
    BuildSelectedLeaderChildren()
    if mode == CAI_OVERVIEW_MODE then
        if not IsRootPushed() then
            PushRootFocusingSelected()
        elseif fromRow then
            -- User navigated onto the row themselves; focus is already correct.
        elseif playerID ~= prevSelected then
            -- Programmatic switch to a different leader: the old action position
            -- is meaningless for the new leader, so land on its row.
            SyncSelectedLeaderRow()
        elseif not IsFocusInOverview() then
            -- Same leader, but focus is not in the overview: either still parked
            -- in the conversation panel vanilla just hid, or nil because a deal
            -- overlay closed while both containers were hidden and the manager
            -- could not restore the prior leaf. Drop back into the overview where
            -- we were -- the action that launched the conversation/deal -- NOT the
            -- leaders tree. Focusing the (transparent) overview panel descends
            -- through the cached _lastFocusedKey/_lastFocusedChild chain, so it
            -- lands on that action (or its submenu), falling back to the first row
            -- only if no prior position survives. When focus already rests on an
            -- overview widget (actions list after a make-demand round trip, an
            -- intel node) the per-subtree restore kept it, so we leave it alone.
            mgr:SetFocus(m_ui.overviewPanel)
        end
        -- implicit else (same leader, focus already resting on a live overview
        -- widget): leave it where the manager restored it, e.g. the Make Deal
        -- button still focused after the deal closes.
    elseif mode == CAI_CINEMA_MODE and IsRootPushed() then
        -- Cinematic intro on an already-open screen (e.g. declaring war): both
        -- vanilla containers are hidden, so the cinema panel is the only navigable
        -- widget. Focus it -- it is Transparent, so this captures input without
        -- speaking; the leader's line stays readable in the conversation list once
        -- cinema reveals it. (When the screen opens straight into cinema the root
        -- is not pushed yet; OnShow's PushRootFocusingSelected focuses it there.)
        CAI.Silence()
        mgr:SetFocus(m_ui.cinemaPanel)
    end
    -- DEAL mode needs no view bookkeeping: the deal screen overlays via its own
    -- context and the overview/conversation panels follow their vanilla
    -- containers' live hidden state once it closes.
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, input)
    local handled = mgr and mgr:HandleInput(input) or false
    if handled then return true end
    -- Vanilla Escape first backs out of dialogs, conversations, cinema, or
    -- deals. Only the overview-state Escape actually dismisses the screen.
    if IsCAIEscapeKeyUp(input) and mgr and mgr:GetTop() == m_ui.root
        and IsFocusInOverview()
        and not IsCAITutorialScreenCloseAllowed() then
        AnnounceCAITutorialScreenCloseBlocked()
        return true
    end
    return orig(input)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)

LateInitialize = WrapFunc(LateInitialize, function(orig)
    orig()
    ReapplyStatementHandlers()
end)

OnShow = WrapFunc(OnShow, function(orig)
    -- AdvisorPopup can enable tutorial-wide input filtering after diplomacy has
    -- already opened. Keep the live diplomacy context reachable in that state.
    SetAlwaysReceivesInput(true)
    orig()
    EnsureRootBuilt()
    -- Only push here if a leader is already selected (so we can focus that row).
    -- Otherwise the push is deferred to the first overview SelectPlayer, which
    -- knows the target and avoids landing focus on the self row by default. When
    -- opening straight into a cinematic intro (orig ran ShowCinemaMode for the
    -- prior SelectPlayer(CINEMA)), PushRootFocusingSelected sees m_state.cinema
    -- and focuses the cinema panel instead of the leader row.
    if ms_SelectedPlayerID ~= nil and ms_SelectedPlayerID >= 0 then
        m_state.selectedPlayer = ms_SelectedPlayerID
        PushRootFocusingSelected()
    end
end)
ContextPtr:SetShowHandler(OnShow)

-- DLC additions (alliance/emergency/world-congress tabs, secret-society overview
-- row) repopulate asynchronously via these LuaEvents. Rebuild the selected
-- leader's sections so the new content is reachable.
local function OnDLCDiploSceneRefresh()
    if m_state.buildingIntel then return end
    if m_ui.root and not ContextPtr:IsHidden() then BuildSelectedLeaderChildren() end
end
if LuaEvents.DiploScene_RefreshTabs then
    LuaEvents.DiploScene_RefreshTabs.Add(OnDLCDiploSceneRefresh)
end
if LuaEvents.DiploScene_RefreshOverviewRows then
    LuaEvents.DiploScene_RefreshOverviewRows.Add(OnDLCDiploSceneRefresh)
end
