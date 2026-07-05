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

if IsExpansion2Active() then
    include("DiplomacyActionView_Expansion2")
elseif IsExpansion1Active() then
    include("DiplomacyActionView_Expansion1")
else
    include("DiplomacyActionView")
end

local mgr = ExposedMembers.CAI_UIManager

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

local m_ui = {
    root = nil,
    overviewPanel = nil,
    conversationPanel = nil,
    cinemaPanel = nil,
    leadersTree = nil,
    actionsList = nil,
    conversationList = nil,
    leaderEntries = {},
    leaderOrder = {},
}

local m_state = {
    syncingLeaderSelection = false,
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

local function NormalizeText(text)
    if not text then return "" end
    text = tostring(text)
    text = string.gsub(text, "%[ENDCOLOR%]", "")
    text = string.gsub(text, "%[COLOR_[^%]]+%]", "")
    text = string.gsub(text, "%[COLOR:%s*[^%]]+%]", "")
    return text
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
                    table.concat(emergencyNames, ", ")), nil))
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
        if gossipText then
            local label = gossipText
            if gossipTurn and (currentTurn - 1) <= gossipTurn then
                label = "[ICON_New] " .. label
            end

            if gossipTurn and (currentTurn - gossipTurn) <= 10 then
                recentNode:AddChild(CreateReadOnlyNode(
                    mgr:GenerateWidgetId("CAIDiplomacyRecentGossipEntry"),
                    label,
                    nil))
                addedRecent = true
            else
                olderNode:AddChild(CreateReadOnlyNode(
                    mgr:GenerateWidgetId("CAIDiplomacyOlderGossipEntry"),
                    label,
                    nil))
                addedOlder = true
            end
        end
    end

    if not addedRecent then
        recentNode:AddChild(CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyRecentGossipEntry"),
            Locale.Lookup("LOC_DIPLOMACY_GOSSIP_ITEM_NO_RECENT"), nil))
    end

    if recentNode.Children and #recentNode.Children > 0 then
        node:AddChild(recentNode)
    end
    if addedOlder and olderNode.Children and #olderNode.Children > 0 then
        node:AddChild(olderNode)
    end
end

local function AddAccessChildren(node)
    local access = m_vanilla.intelInstances.access
    if not access then return end

    node:AddChild(CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyAccessLevel"),
        Locale.Lookup("LOC_DIPLOMACY_INTEL_ACCESS_LEVEL") .. ": " .. ControlText(access.AccessLevelText),
        ControlTooltip(access.AccessLevelText)))

    local contributionText = ControlText(access.AccessContributionText)
    if contributionText ~= "" then
        local sourcesNode = CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyAccessSources"),
            Locale.Lookup("LOC_CAI_DIPLOMACY_ACTIVE_SOURCES"), nil)
        AddTextLineChildren(sourcesNode, contributionText)
        node:AddChild(sourcesNode)
    end

    local sharedNode = CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyAccessShared"),
        Locale.Lookup("LOC_DIPLOMACY_INTEL_INFORMATION_SHARED_HEADER"), nil)
    AddTextLineChildren(sharedNode, ControlText(access.InformationSharedText))
    if sharedNode.Children and #sharedNode.Children > 0 then
        node:AddChild(sharedNode)
    end

    if access.NextAccessLevelStack and not access.NextAccessLevelStack:IsHidden() then
        local nextNode = CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyAccessNext"),
            Locale.Lookup("LOC_DIPLOMACY_INTEL_NEXT_ACCESS_LEVEL_HEADER"), nil)
        AddTextLineChildren(nextNode, ControlText(access.NextAccessLevelText))
        if nextNode.Children and #nextNode.Children > 0 then
            node:AddChild(nextNode)
        end
    end

    if access.Advisor and not access.Advisor:IsHidden() then
        local advisorNode = CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyAccessAdvisor"),
            Locale.Lookup("LOC_DIPLOMACY_INTEL_GAIN_ACCESS_LEVEL_HEADER"), nil)
        AddTextLineChildren(advisorNode, ControlText(access.AdvisorText))
        if advisorNode.Children and #advisorNode.Children > 0 then
            node:AddChild(advisorNode)
        end
    end
end

local function AddRelationshipChildren(node)
    local relationship = m_vanilla.intelInstances.relationship
    if not relationship then return end

    local selectedPlayerDiplomaticAI = ms_SelectedPlayer and ms_SelectedPlayer.GetDiplomaticAI and
        ms_SelectedPlayer:GetDiplomaticAI() or nil
    if not selectedPlayerDiplomaticAI then return end

    node:AddChild(CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyRelationshipState"),
        Locale.Lookup("LOC_DIPLOMACY_INTEL_RELATIONSHIP") .. ": " .. ControlText(relationship.RelationshipText),
        ControlTooltip(relationship.RelationshipText)))

    local reasonsNode = CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyRelationshipReasons"),
        ControlText(relationship.RelationshipReasonsText), nil)

    local toolTips = selectedPlayerDiplomaticAI:GetDiplomaticModifiers(ms_LocalPlayerID)
    if toolTips then
        table.sort(toolTips, function(a, b) return a.Score > b.Score end)
        for _, tip in ipairs(toolTips) do
            local score = tip.Score
            local text = tip.Text
            if score ~= 0 and text then
                local scoreText = Locale.Lookup("{1_Score : number +#,###.##;-#,###.##}", score)
                local reasonText = text == "LOC_TOOLTIP_DIPLOMACY_UNKNOWN_REASON"
                    and "[COLOR_Grey]" .. Locale.Lookup(text) .. "[ENDCOLOR]"
                    or Locale.Lookup(text)
                reasonsNode:AddChild(CreateReadOnlyNode(
                    mgr:GenerateWidgetId("CAIDiplomacyRelationshipReasonEntry"),
                    JoinNonEmpty({ scoreText, reasonText }, " "),
                    nil))
            end
        end
    end

    if reasonsNode.Children and #reasonsNode.Children > 0 then
        node:AddChild(reasonsNode)
    elseif relationship.NoReasons and not relationship.NoReasons:IsHidden() then
        local noReasonsLabel = ControlText(relationship.NoReasons)
        if noReasonsLabel == "" then
            noReasonsLabel = Locale.Lookup("LOC_DIPLOMACY_INTEL_RELATIONSHIP_NOTHING_ABJECT")
        end
        node:AddChild(CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyRelationshipNoReasons"),
            noReasonsLabel, nil))
    end

    if relationship.Advisor and not relationship.Advisor:IsHidden() then
        local raiseNode = CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyRelationshipRaise"),
            Locale.Lookup("LOC_DIPLOMACY_INTEL_TO_RAISE_RELATIONSHIP"), nil)
        AddTextLineChildren(raiseNode, ControlText(relationship.AdvisorTextRaise))
        if raiseNode.Children and #raiseNode.Children > 0 then
            node:AddChild(raiseNode)
        end

        local lowerNode = CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyRelationshipLower"),
            Locale.Lookup("LOC_DIPLOMACY_INTEL_TO_LOWER_RELATIONSHIP"), nil)
        AddTextLineChildren(lowerNode, ControlText(relationship.AdvisorTextLower))
        if lowerNode.Children and #lowerNode.Children > 0 then
            node:AddChild(lowerNode)
        end
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
    parent:AddChild(CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyAllianceDetail"),
        Locale.Lookup(allianceDefinition.Name) .. ": " ..
        Locale.Lookup("LOC_DIPLOACTION_ALLIANCE_LEVEL", allianceLevel),
        table.concat(bonuses, ", ")))
end

local function AddAllianceChildren(node)
    local localPlayerDiplomacy = ms_LocalPlayer and ms_LocalPlayer.GetDiplomacy and ms_LocalPlayer:GetDiplomacy() or nil
    if not localPlayerDiplomacy then return end

    local allianceLevel = localPlayerDiplomacy:GetAllianceLevel(ms_SelectedPlayerID)
    local allianceType = localPlayerDiplomacy:GetAllianceType(ms_SelectedPlayerID)
    local multiplier = GlobalParameters.ALLIANCE_POINTS_MULTIPLIER

    node:AddChild(CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyAllianceLevel"),
        Locale.Lookup("LOC_CAI_DIPLOMACY_ALLIANCE_LEVEL", allianceLevel), nil))

    -- Alliance points: current of needed plus per-turn gain, or "Maximum" at cap.
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
    node:AddChild(CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyAlliancePoints"),
        pointsLine, JoinTooltipLines(pointsTooltip)))

    -- Current alliance as a single leaf "Current alliance: <Name>, Level N" whose
    -- tooltip leads with the expiration, then the active bonuses, or a "none" leaf.
    if allianceType ~= -1 and GameInfo.Alliances[allianceType] then
        local definition = GameInfo.Alliances[allianceType]
        local tooltipParts = {
            Locale.Lookup("LOC_DIPLOACTION_EXPIRES_IN_X_TURNS",
                localPlayerDiplomacy:GetAllianceTurnsUntilExpiration(ms_SelectedPlayerID)),
        }
        for _, modifier in ipairs(GetAllianceModifierStrings(definition.AllianceType, allianceLevel)) do
            table.insert(tooltipParts, Locale.Lookup(modifier))
        end
        node:AddChild(CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyAllianceCurrent"),
            Locale.Lookup("LOC_CAI_DIPLOMACY_CURRENT_ALLIANCE") .. ": " ..
            Locale.Lookup(definition.Name) .. ", " ..
            Locale.Lookup("LOC_DIPLOACTION_ALLIANCE_LEVEL", allianceLevel),
            table.concat(tooltipParts, "[NEWLINE]")))
    else
        node:AddChild(CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyAllianceCurrent"),
            Locale.Lookup("LOC_CAI_DIPLOMACY_CURRENT_ALLIANCE") .. ": " ..
            Locale.Lookup("LOC_DIPLOACTION_NO_CURRENT_ALLIANCE"), nil))
    end

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
                local entryNode = CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyEmergencyEntry"),
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
        node:AddChild(CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyEmergencyNone"),
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

    -- Headline as the label; the "Having witnessed the hardships..." sentence
    -- becomes its tooltip rather than a separate orphaned leaf.
    node:AddChild(CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyGrievanceFavor"), favorLine, descriptionLine))
    node:AddChild(CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyGrievanceAgainstYou"), againstYouLine, nil))
    node:AddChild(CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyGrievanceAgainstThem"), againstThemLine, nil))

    -- Per-turn change breakdown, just above the log so the summary lines read
    -- first. Each "from:" contribution is its own child line.
    if #breakdownLines > 0 then
        local breakdownNode = CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyGrievanceBreakdown"),
            Locale.Lookup("LOC_CAI_DIPLOMACY_GRIEVANCE_BREAKDOWN", perTurnText), nil)
        for _, line in ipairs(breakdownLines) do
            -- Skip the "LOSING / Grievances per turn from:" header line; the
            -- parent label already states the net change. Header lines end in ":".
            if not string.match(line, ":%s*$") then
                breakdownNode:AddChild(CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyGrievanceBreakdownEntry"),
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
            logNode:AddChild(CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyGrievanceEntry"),
                Locale.Lookup("LOC_CAI_DIPLOMACY_GRIEVANCE_LOG_ENTRY",
                    entry.Turn, entry.Description, entry.Amount, actor), nil))
        end
        node:AddChild(logNode)
    end
end

local function GetKnownReaders()
    if m_knownReaders then return m_knownReaders end
    m_knownReaders = {
        [Locale.ToUpper("LOC_DIPLOMACY_INTEL_REPORT_OVERVIEW")] = AddOverviewChildren,
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
-- Self (local player) unique-trait sections
-- ============================================================================

local function PopulateSelfTraitCategory(category, items)
    if not items or #items == 0 then return end
    for _, item in ipairs(items) do
        if item.Name and item.Name ~= "NONE" then
            local name = Locale.Lookup(item.Name)
            local description = Locale.Lookup(item.Description or "")
            category:AddChild(CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacySelfEntry"), name, description))
        end
    end
end

local function CreateSelfTraitCategory(label)
    return mgr:CreateWidget(mgr:GenerateWidgetId("CAIDiplomacySelfCategory"), "TreeItem", {
        Label = function() return label end,
    })
end

local function BuildSelfChildren(row)
    local playerConfig = PlayerConfigurations[ms_LocalPlayerID]
    local civType = playerConfig and playerConfig:GetCivilizationTypeName() or nil
    local leaderType = playerConfig and playerConfig:GetLeaderTypeName() or nil
    local uniqueAbilities, uniqueUnits, uniqueBuildings = {}, {}, {}
    local civAbilities, civUnits, civBuildings = {}, {}, {}
    if leaderType then
        uniqueAbilities, uniqueUnits, uniqueBuildings = GetLeaderUniqueTraits(leaderType, true)
    end
    if civType then
        civAbilities, civUnits, civBuildings = GetCivilizationUniqueTraits(civType, true)
    end
    for _, item in ipairs(civAbilities) do table.insert(uniqueAbilities, item) end
    for _, item in ipairs(civUnits) do table.insert(uniqueUnits, item) end
    for _, item in ipairs(civBuildings) do table.insert(uniqueBuildings, item) end

    local abilities = CreateSelfTraitCategory(Locale.Lookup("LOC_CAI_DIPLOMACY_SELF_ABILITIES"))
    local units = CreateSelfTraitCategory(Locale.Lookup("LOC_CAI_DIPLOMACY_SELF_UNITS"))
    local buildings = CreateSelfTraitCategory(Locale.Lookup("LOC_CAI_DIPLOMACY_SELF_BUILDINGS"))
    PopulateSelfTraitCategory(abilities, uniqueAbilities)
    PopulateSelfTraitCategory(units, uniqueUnits)
    PopulateSelfTraitCategory(buildings, uniqueBuildings)
    row:AddChild(abilities)
    row:AddChild(units)
    row:AddChild(buildings)
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
    else
        AddGenericPanelChildren(sectionNode, tab.Panel)
    end
end

local function CreateIntelSection(tab)
    -- tab.Header / tab.Panel are resolved lazily on first focus (below): pre-reading
    -- them would require clicking every tab on every build (audible, redundant).
    local section = mgr:CreateWidget(mgr:GenerateWidgetId("CAIDiplomacyIntelSection"), "TreeItem", {
        Label = function() return tab.Header or "" end,
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
        -- Now that this tab's panel is the visible one, resolve its header (drives
        -- reader lookup + label) and panel (generic fallback) once.
        if not tab.Header then
            tab.Header = ms_IntelPanel and ms_IntelPanel.IntelHeader
                and ms_IntelPanel.IntelHeader:GetText() or ""
        end
        -- Populate once. The readers freeze the selected leader's live state into
        -- the child nodes, and a leader's screen never spans a turn change, so the
        -- persisted content stays correct without a teardown on re-entry.
        if not w._intelPopulated then
            tab.Panel = tab.Panel or VisibleIntelPanelChild()
            PopulateSectionChildren(w, tab)
            w._intelPopulated = true
        end
    end)
    return section
end

-- Enumerate the live intel tab buttons in visual (button-stack) order. Every tab
-- -- base (overview / gossip / access / relationship) and DLC (alliance /
-- emergency / world congress) -- lands a button in IntelTabButtonStack; the DLC
-- adders build theirs through CreateTabButton, so walking the finished stack is
-- the only way to see them all. This does NOT click: a tab's header and panel
-- are resolved lazily the first time its section is focused (see
-- CreateIntelSection), keeping leader (re)builds silent. Pooled buttons from a
-- richer prior build linger hidden in the stack; only live tabs are visible.
local function CaptureIntelTabs()
    local tabs = {}
    local panel = ms_IntelPanel
    if not panel or not panel.IntelTabButtonStack then
        return tabs
    end
    for _, button in ipairs(panel.IntelTabButtonStack:GetChildren()) do
        if not ControlIsHidden(button) then
            table.insert(tabs, { Button = button })
        end
    end
    return tabs
end

local function BuildSelectedLeaderChildren()
    local entry = m_ui.leaderEntries[ms_SelectedPlayerID]
    if not entry or not entry.Row then return end

    local isSelf = ms_SelectedPlayerID == ms_LocalPlayerID
    local liveTabs = isSelf and {} or CaptureIntelTabs()

    -- Persist a leader's subtree across re-selection so expand state, populated
    -- content and focus position survive switching away and back. The intel-tab
    -- button instances are pooled and recycled per vanilla rebuild, so when the
    -- tab set is unchanged we only re-bind the existing sections to the current
    -- buttons (mutating the shared tab tables the section closures hold) -- no
    -- teardown, no focus loss. A changed tab count (e.g. DLC tabs arriving) falls
    -- through to a full rebuild.
    if entry.IntelBuilt and entry.IsSelf == isSelf and #entry.Tabs == #liveTabs then
        for i, tab in ipairs(entry.Tabs) do
            tab.Button = liveTabs[i].Button
        end
        return
    end

    local capture = mgr:CaptureFocusKey(entry.Row)
    entry.Row:ClearChildren()
    entry.IsSelf = isSelf
    entry.Tabs = liveTabs

    if isSelf then
        BuildSelfChildren(entry.Row)
    else
        for _, tab in ipairs(liveTabs) do
            entry.Row:AddChild(CreateIntelSection(tab))
        end
    end
    entry.IntelBuilt = true

    mgr:RestoreFocus(entry.Row, capture)
end

-- ============================================================================
-- Leaders tree
-- ============================================================================

local function CreateLeaderNode(playerID)
    local currentID = playerID
    local row = mgr:CreateWidget(GetLeaderRowId(currentID), "TreeItem", {
        Label    = function() return GetLeaderRowLabel(currentID) end,
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
    end)
    row.CAI_PlayerID = currentID
    return row
end

local function EnsureLeadersTreeStructure()
    if not m_ui.leadersTree then return end

    local leaderIDs = GetLeaderIDs()
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

local function SyncSelectedLeaderRow()
    if not m_ui.root or not m_ui.leadersTree then return end
    local selectedEntry = m_ui.leaderEntries[ms_SelectedPlayerID]
    if not selectedEntry or not selectedEntry.Row then return end
    if not IsRootPushed() then return end

    m_state.syncingLeaderSelection = true
    mgr:SetFocus(selectedEntry.Row)
    m_state.syncingLeaderSelection = false
end

local function RefreshOverview()
    -- Short-circuit while harvesting sub-menu options (the eager sub-action
    -- population re-enters PopulateStatementList with the suppress flag set);
    -- we don't want any CAI rebuild for those transient sub-list passes.
    if m_state.suppressActionsRebuild then return end
    if not m_ui.overviewPanel then return end
    EnsureLeadersTreeStructure()
    -- Intel section nodes are rebuilt on selection change / DLC refresh events,
    -- not here, so an action-only refresh doesn't yank the user out of the intel
    -- content they're reading. Section content re-reads live state on focus.
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

    m_vanilla.conversationBindings = {
        Handler = handler,
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

    local liveButtons = Controls.ConversationSelectionStack
        and Controls.ConversationSelectionStack.GetChildren
        and Controls.ConversationSelectionStack:GetChildren()
        or {}
    local visibleIndex = 0

    for _, selection in ipairs(m_vanilla.conversationBindings and m_vanilla.conversationBindings.Selections or {}) do
        visibleIndex = visibleIndex + 1
        local buttonControl = liveButtons[visibleIndex]
        local labelControl = buttonControl and buttonControl.GetTextControl and buttonControl:GetTextControl() or nil
        local currentSelection = selection

        local choice = mgr:CreateWidget(
            mgr:GenerateWidgetId("CAIDiplomacyConversationButton"), "Button", {
                Label = function()
                    local liveText = labelControl and ControlText(labelControl) or ""
                    if liveText ~= "" then return liveText end
                    return Locale.Lookup(currentSelection.Text or "")
                end,
                Tooltip = function()
                    local liveTooltip = buttonControl and ControlTooltip(buttonControl) or ""
                    if liveTooltip ~= "" then return liveTooltip end
                    return GetConversationSelectionTooltip(currentSelection)
                end,
                DisabledPredicate = function()
                    return buttonControl and buttonControl:IsDisabled() or currentSelection.IsDisabled == true
                end,
            })
        PlayHoverSound(choice)
        choice:On("activate", function()
            if m_vanilla.conversationBindings and m_vanilla.conversationBindings.Handler then
                m_vanilla.conversationBindings.Handler.OnSelectionButtonClicked(currentSelection.Key)
                if currentSelection.Key == "CHOICE_EXIT" then
                    ClearConversationState()
                end
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
    m_ui.leadersTree = mgr:CreateWidget(LEADERS_TREE_ID, "Tree", {
        Label = function() return Locale.Lookup("LOC_CAI_DIPLOMACY_LEADERS") end,
    })
    m_ui.actionsList = mgr:CreateWidget(ACTIONS_LIST_ID, "List", {
        Label           = function() return Locale.Lookup("LOC_CAI_DIPLOMACY_ACTIONS") end,
        HiddenPredicate = function() return IsSelfSelected() end,
    })
    m_ui.overviewPanel:AddChild(m_ui.leadersTree)
    m_ui.overviewPanel:AddChild(m_ui.actionsList)

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

    EnsureLeadersTreeStructure()
end

local function ResetState()
    m_ui = {
        root = nil,
        overviewPanel = nil,
        conversationPanel = nil,
        cinemaPanel = nil,
        leadersTree = nil,
        actionsList = nil,
        conversationList = nil,
        leaderEntries = {},
        leaderOrder = {},
    }
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
    EnsureLeadersTreeStructure()
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
    local entry = ms_SelectedPlayerID and m_ui.leaderEntries[ms_SelectedPlayerID] or nil
    if entry and entry.Row then
        mgr:Push(m_ui.root, { priority = PopupPriority.Utmost, focus = entry.Row })
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
    DestroyRoot()
    orig()
end)
ContextPtr:SetHideHandler(OnHide)

OnShutdown = WrapFunc(OnShutdown, function(orig)
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
    EnsureLeadersTreeStructure()
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
    return orig(input)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)

LateInitialize = WrapFunc(LateInitialize, function(orig)
    orig()
    ReapplyStatementHandlers()
end)

OnShow = WrapFunc(OnShow, function(orig)
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
