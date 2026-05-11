include("caiUtils")
include("DiplomacyActionView")

local mgr = ExposedMembers.CAI_UIManager
local CAI_OVERVIEW_MODE = 0
local CAI_CONVERSATION_MODE = 1
local CAI_DEAL_MODE = 3;

local m_ui = {
    root = nil,
    overviewPanel = nil,
    leadersTree = nil,
    actionsList = nil,
    conversationPanel = nil,
    conversationList = nil,
    cinemaPanel = nil,
    leaderEntries = {},
    leaderOrder = {},
}

local m_state = {
    syncingLeaderSelection = false,
    SelectedPlayer = -1,
    activePanel = nil,
    ActiveIntelPanel = nil,
}

local m_vanilla = {
    intelPanels = {},
    intelInstances = {},
    actionLists = {
        root = {},
        sub = {},
    },
    activeIntelKey = "overview",
    conversationBindings = nil,
}

local function PlayHover()
    UI.PlaySound("Main_Menu_Mouse_Over")
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
        if text and text ~= "" then
            return text
        end
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

local function CountEntries(list)
    local count = 0
    if not list then return count end
    for _ in pairs(list) do
        count = count + 1
    end
    return count
end

local function CreateReadOnlyNode(id, label, tooltip)
    return mgr:CreateUIWidget(id, "TreeviewItem", {
        GetLabel = function() return label end,
        GetTooltip = function() return tooltip or "" end,
    })
end

local function GetLeaderRowId(playerID)
    return "CAIDiplomacyLeaderRow_" .. tostring(playerID)
end

local function GetConversationTextId()
    return "CAIDiplomacyConversationText"
end

local function GetConversationReasonId()
    return "CAIDiplomacyConversationReason"
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

local function ClearConversationState()
    m_vanilla.conversationBindings = nil
    if m_ui.conversationList then
        m_ui.conversationList:ClearChildren()
    end
end

local function ResetCapturedState()
    m_vanilla.intelPanels = {}
    m_vanilla.intelInstances = {}
    m_vanilla.actionLists = {
        root = {},
        sub = {},
    }
    m_vanilla.activeIntelKey = "overview"
    ClearConversationState()
end

local function DestroyRoot()
    if not m_ui.root then
        ResetCapturedState()
        m_ui = {
            root = nil,
            overviewPanel = nil,
            leadersTree = nil,
            actionsList = nil,
            conversationPanel = nil,
            conversationList = nil,
            cinemaPanel = nil,
            leaderEntries = {},
            leaderOrder = {},
        }
        m_state.syncingLeaderSelection = false
        m_state.activePanel = nil
        return
    end

    if mgr and mgr:HasWidget(m_ui.root) then
        mgr:RemoveFromStack(m_ui.root:GetId())
    else
        m_ui.root:Destroy()
    end

    m_ui = {
        root = nil,
        overviewPanel = nil,
        leadersTree = nil,
        actionsList = nil,
        conversationPanel = nil,
        conversationList = nil,
        cinemaPanel = nil,
        leaderEntries = {},
        leaderOrder = {},
    }
    m_state.syncingLeaderSelection = false
    m_state.activePanel = nil
    ResetCapturedState()
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

local function RebuildActionSubMenu(subMenu, entry)
    if not subMenu then return end
    subMenu:ClearChildren()

    for _, subEntry in ipairs(SyncSubActionsForEntry(entry)) do
        if not subEntry.IsCancel then
            local currentSubEntry = subEntry
            subMenu:AddChild(mgr:CreateUIWidget(
                mgr:GenerateWidgetId("CAIDiplomacySubActionButton"),
                "Button",
                {
                    GetLabel = function() return ControlText(currentSubEntry.LabelControl) end,
                    GetTooltip = function() return ControlTooltip(currentSubEntry.Button) end,
                    IsDisabled = function() return ControlIsDisabled(currentSubEntry.Button) end,
                    OnFocusEnter = PlayHover,
                    OnClick = function()
                        if currentSubEntry.Callback then
                            currentSubEntry.Callback()
                        end
                        return true
                    end,
                }))
        end
    end
end

local function CreateActionButton(entry)
    return mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIDiplomacyActionButton"), "Button", {
        GetLabel = function() return ControlText(entry.LabelControl) end,
        GetTooltip = function() return ControlTooltip(entry.Button) end,
        IsDisabled = function() return ControlIsDisabled(entry.Button) end,
        OnFocusEnter = function()
            PlayHover()
            ShowOptionStack(false)
            return true
        end,
        OnClick = function()
            if entry.Callback then
                entry.Callback()
            end
            return true
        end,
    })
end

local function CreateActionSubMenu(entry)
    return mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIDiplomacyActionSubMenu"), "SubMenu", {
        GetLabel = function() return ControlText(entry.LabelControl) end,
        GetTooltip = function() return ControlTooltip(entry.Button) end,
        IsDisabled = function() return ControlIsDisabled(entry.Button) end,
        Expand = function(w)
            if w.IsExpanded then return false end
            RebuildActionSubMenu(w, entry)
            if not w.Children or #w.Children == 0 then
                return true
            end
            w.IsExpanded = true
            if w.OnToggleExpanded then
                w:OnToggleExpanded(w.IsExpanded)
            end
            w:Navigate(0)
            return true
        end,
        OnFocusEnter = function()
            PlayHover()
            ShowOptionStack(false)
            return true
        end,
        OnToggleExpanded = function(_, expanded)
            if not expanded then
                ShowOptionStack(false)
            end
        end,
    })
end

local function RebuildActionsList()
    if not m_ui.actionsList then return end
    m_ui.actionsList:ClearChildren()

    if IsSelfSelected() then return end

    if m_LiteMode then
        m_ui.actionsList:AddChild(mgr:CreateUIWidget("CAIDiplomacyNoActions", "Button", {
            GetLabel = function() return Locale.Lookup("LOC_CAI_DIPLOMACY_NO_ACTIONS") end,
            IsDisabled = function() return true end,
            OnFocusEnter = PlayHover,
        }))
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
        m_ui.actionsList:AddChild(mgr:CreateUIWidget("CAIDiplomacyNoActions", "Button", {
            GetLabel = function() return Locale.Lookup("LOC_CAI_DIPLOMACY_NO_ACTIONS") end,
            IsDisabled = function() return true end,
            OnFocusEnter = PlayHover,
        }))
    end
end

local function CacheIntelPanels()
    local container = ms_IntelPanel and ms_IntelPanel.IntelPanelContainer or nil
    if not container or not container.GetChildren then
        m_vanilla.intelPanels = {}
        m_vanilla.activeIntelKey = "overview"
        return
    end

    local liveChildren = {}
    for _, child in ipairs(container:GetChildren()) do
        liveChildren[child] = true
    end

    for key, panel in pairs(m_vanilla.intelPanels) do
        if not liveChildren[panel] then
            m_vanilla.intelPanels[key] = nil
        end
    end
end

local function GetActiveIntelKey()
    for _, key in ipairs({ "overview", "gossip", "access", "relationship" }) do
        local panel = m_vanilla.intelPanels[key]
        if panel and not panel:IsHidden() then
            m_vanilla.activeIntelKey = key
            return key
        end
    end
    return m_vanilla.activeIntelKey or "overview"
end

local function ShowIntelPanel(key)
    local panel = m_vanilla.intelPanels[key]
    if panel and panel:IsHidden() then
        ShowPanel(panel)
    end
    m_state.ActiveIntelPanel = key
end

local function AddTextLineChildren(parent, text)
    for _, line in ipairs(SplitLines(text)) do
        parent:AddChild(CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacyLine"), line, nil))
    end
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

local function CaptureLastIntelPanel(key)
    local container = ms_IntelPanel and ms_IntelPanel.IntelPanelContainer or nil
    if not container or not container.GetChildren then return end
    local children = container:GetChildren()
    if children and #children > 0 then
        m_vanilla.intelPanels[key] = children[#children]
    end
end

local function CaptureIntelInstance(key, instance)
    if instance then
        m_vanilla.intelInstances[key] = instance
    end
end

local function RefreshIntelTabChildren(tabNode, populate)
    if not tabNode then return end
    isExpanded = tabNode.IsExpanded
    tabNode:ClearChildren()
    tabNode.IsExpanded = isExpanded
    populate(tabNode)
end

local function CreatePersistentIntelTabNode(playerID, key, label, populate)
    local currentPlayerID = playerID
    local currentKey = key
    return mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIDiplomacyIntelSection"), "TreeviewItem", {
        GetLabel = function() return label end,
        IsHidden = function()
            if currentKey == "relationship" then
                local selectedPlayer = Players[currentPlayerID]
                return selectedPlayer == nil or selectedPlayer:IsHuman()
            end
            return false
        end,
        OnFocusEnter = function(widget)
            if m_state.ActiveIntelPanel == currentKey then return end
            PlayHover()
            ShowIntelPanel(currentKey)
            RefreshIntelTabChildren(widget, populate)
        end,
    })
end

local function PopulateSelfTraitCategory(category, items)
    if not items or #items == 0 then return end
    for _, item in ipairs(items) do
        if item.Name and item.Name ~= "NONE" then
            local name = Locale.Lookup(item.Name)
            local description = Locale.Lookup(item.Description or "")
            local entry = CreateReadOnlyNode(mgr:GenerateWidgetId("CAIDiplomacySelfEntry"), name, description)
            category:AddChild(entry)
        end
    end
end


local function CreateSelfTraitCategory(label)
    local category = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIDiplomacySelfCategory"), "TreeviewItem", {
        GetLabel = function() return label end,
    })
    return category
end

local function CreateLeaderNode(playerID)
    local currentID = playerID
    local row = mgr:CreateUIWidget(GetLeaderRowId(currentID), "TreeviewItem", {
        GetLabel = function()
            return GetLeaderRowLabel(currentID)
        end,
        OnFocusEnter = function()
            PlayHover()
            if not m_state.syncingLeaderSelection and m_state.SelectedPlayer ~= currentID then
                SelectPlayer(currentID, CAI_OVERVIEW_MODE)
            end
            return true
        end,
    })
    row.CAI_PlayerID = currentID
    return row
end

local function EnsureLeaderEntryChildren(entry)
    if not entry or entry.ChildrenBuilt then return end

    if entry.PlayerID == ms_LocalPlayerID then
        local playerConfig = PlayerConfigurations[ms_LocalPlayerID]
        local civType = playerConfig and playerConfig:GetCivilizationTypeName() or nil
        local leaderType = playerConfig and playerConfig:GetLeaderTypeName() or nil
        local uniqueAbilities = {}
        local uniqueUnits = {}
        local uniqueBuildings = {}
        local civAbilities = {}
        local civUnits = {}
        local civBuildings = {}
        if leaderType then
            uniqueAbilities, uniqueUnits, uniqueBuildings = GetLeaderUniqueTraits(leaderType, true)
        end
        if civType then
            civAbilities, civUnits, civBuildings = GetCivilizationUniqueTraits(civType, true)
        end
        for _, item in ipairs(civAbilities) do table.insert(uniqueAbilities, item) end
        for _, item in ipairs(civUnits) do table.insert(uniqueUnits, item) end
        for _, item in ipairs(civBuildings) do table.insert(uniqueBuildings, item) end

        entry.SelfCategories = {
            abilities = CreateSelfTraitCategory(Locale.Lookup("LOC_CAI_DIPLOMACY_SELF_ABILITIES")),
            units = CreateSelfTraitCategory(Locale.Lookup("LOC_CAI_DIPLOMACY_SELF_UNITS")),
            buildings = CreateSelfTraitCategory(Locale.Lookup("LOC_CAI_DIPLOMACY_SELF_BUILDINGS")),
        }
        PopulateSelfTraitCategory(entry.SelfCategories.abilities, uniqueAbilities)
        PopulateSelfTraitCategory(entry.SelfCategories.units, uniqueUnits)
        PopulateSelfTraitCategory(entry.SelfCategories.buildings, uniqueBuildings)
        entry.Row:AddChild(entry.SelfCategories.abilities)
        entry.Row:AddChild(entry.SelfCategories.units)
        entry.Row:AddChild(entry.SelfCategories.buildings)
    else
        entry.IntelTabs = {
            overview = CreatePersistentIntelTabNode(entry.PlayerID, "overview",
                Locale.Lookup("LOC_DIPLOMACY_INTEL_REPORT_OVERVIEW"), AddOverviewChildren),
            gossip = CreatePersistentIntelTabNode(entry.PlayerID, "gossip",
                Locale.Lookup("LOC_DIPLOMACY_INTEL_REPORT_GOSSIP"), AddGossipChildren),
            access = CreatePersistentIntelTabNode(entry.PlayerID, "access",
                Locale.Lookup("LOC_DIPLOMACY_INTEL_REPORT_ACCESS_LEVEL"), AddAccessChildren),
            relationship = CreatePersistentIntelTabNode(entry.PlayerID, "relationship",
                Locale.Lookup("LOC_DIPLOMACY_INTEL_REPORT_RELATIONSHIP"), AddRelationshipChildren),
        }
        entry.Row:AddChild(entry.IntelTabs.overview)
        entry.Row:AddChild(entry.IntelTabs.gossip)
        entry.Row:AddChild(entry.IntelTabs.access)
        entry.Row:AddChild(entry.IntelTabs.relationship)
    end

    entry.ChildrenBuilt = true
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

    m_ui.leadersTree:ClearChildren()
    m_ui.leaderEntries = {}
    m_ui.leaderOrder = leaderIDs

    for _, playerID in ipairs(leaderIDs) do
        local entry = {
            PlayerID = playerID,
            Row = CreateLeaderNode(playerID),
            ChildrenBuilt = false,
            IntelTabs = {},
            SelfCategories = {},
        }
        EnsureLeaderEntryChildren(entry)
        m_ui.leaderEntries[playerID] = entry
        m_ui.leadersTree:AddChild(entry.Row)
    end
end

local function RefreshSelectedLeaderDetails()
    local entry = m_ui.leaderEntries[ms_SelectedPlayerID]
    if not entry then return end
    if ms_SelectedPlayerID == ms_LocalPlayerID then return end

    CacheIntelPanels()
    for key, tabNode in pairs(entry.IntelTabs or {}) do
        if tabNode then
            RefreshIntelTabChildren(tabNode, key == "overview" and AddOverviewChildren
                or key == "gossip" and AddGossipChildren
                or key == "access" and AddAccessChildren
                or AddRelationshipChildren)
        end
    end
end

local function SyncSelectedLeaderRow()
    if not m_ui.root or not m_ui.leadersTree then return end
    local selectedEntry = m_ui.leaderEntries[ms_SelectedPlayerID]
    if not selectedEntry or not selectedEntry.Row then return end

    local row = m_ui.leadersTree:GetChildById(GetLeaderRowId(ms_SelectedPlayerID), true) or selectedEntry.Row
    local index = m_ui.leadersTree:GetChildIndex(row)
    if not index then return end

    m_state.syncingLeaderSelection = true
    m_ui.leadersTree:SetFocusedChild(index)
    m_state.syncingLeaderSelection = false
end

local function RefreshOverviewPanel()
    if not m_ui.overviewPanel then return end
    EnsureLeadersTreeStructure()
    RefreshSelectedLeaderDetails()
    if not m_state.suppressActionsRebuild then
        RebuildActionsList()
    end
end

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
        if selection.Key ~= "CHOICE_STOP_ASKING" or not Players[ms_OtherPlayerID]:IsHuman() then
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

    local responseText = ControlText(Controls.LeaderResponseText)
    if responseText ~= "" then
        m_ui.conversationList:AddChild(mgr:CreateUIWidget(GetConversationTextId(), "StaticText", {
            GetValue = function() return ControlText(Controls.LeaderResponseText) end,
        }), responseText and responseText ~= "")
    end

    local reasonText = ControlText(Controls.LeaderReasonText)
    if reasonText ~= "" then
        m_ui.conversationList:AddChild(mgr:CreateUIWidget(GetConversationReasonId(), "StaticText", {
            GetValue = function() return ControlText(Controls.LeaderReasonText) end,
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

        m_ui.conversationList:AddChild(mgr:CreateUIWidget(
            mgr:GenerateWidgetId("CAIDiplomacyConversationButton"),
            "Button",
            {
                GetLabel = function()
                    local liveText = labelControl and ControlText(labelControl) or ""
                    if liveText ~= "" then return liveText end
                    return Locale.Lookup(currentSelection.Text or "")
                end,
                GetTooltip = function()
                    local liveTooltip = buttonControl and ControlTooltip(buttonControl) or ""
                    if liveTooltip ~= "" then return liveTooltip end
                    return GetConversationSelectionTooltip(currentSelection)
                end,
                IsDisabled = function()
                    return buttonControl and buttonControl:IsDisabled() or currentSelection.IsDisabled == true
                end,
                OnFocusEnter = PlayHover,
                OnClick = function()
                    if m_vanilla.conversationBindings and m_vanilla.conversationBindings.Handler then
                        m_vanilla.conversationBindings.Handler.OnSelectionButtonClicked(currentSelection.Key)
                        if currentSelection.Key == "CHOICE_EXIT" then
                            ClearConversationState()
                        end
                    end
                    return true
                end,
            }))
    end
end

local function SetActivePanel(panel)
    if not panel then return end
    if panel == m_state.activePanel then return end
    m_state.activePanel = panel
    if mgr:GetTop() == m_ui.root then
        mgr:SetFocus(panel)
    else
        m_ui.root:SetFocusedChild(panel:GetIndexInParent())
    end
end

local function EnsureRootBuilt()
    if m_ui.root then return end

    m_ui.root = mgr:CreateUIWidget("CAIDiplomacyRoot", "Panel", {
        RegisterInputs = {},
        Navigate = function() return false end,
        GetDefaultChild = function(w)
            if w.FocusedChild then return w.FocusedChild end
            return m_state.activePanel
        end,
        GetLabel = GetPanelLabel,
    })

    m_ui.cinemaPanel = mgr:CreateUIWidget("CAIDiplomacyCinemaPanel", "Panel", {
        SpeechSettings = { Role = false, Position = false }
    })

    m_ui.overviewPanel = mgr:CreateUIWidget("CAIDiplomacyOverviewPanel", "Panel", {
        SpeechSettings = { Role = false, Position = false },
        GetLabel = function() return GetPanelLabel() end,
    })
    m_ui.leadersTree = mgr:CreateUIWidget("CAIDiplomacyLeadersTree", "Treeview", {
        GetLabel = function() return Locale.Lookup("LOC_CAI_DIPLOMACY_LEADERS") end,
    })
    m_ui.actionsList = mgr:CreateUIWidget("CAIDiplomacyActionsList", "List", {
        GetLabel = function() return Locale.Lookup("LOC_CAI_DIPLOMACY_ACTIONS") end,
        IsHidden = function() return IsSelfSelected() end,
    })
    m_ui.overviewPanel:AddChild(m_ui.leadersTree)
    m_ui.overviewPanel:AddChild(m_ui.actionsList)

    m_ui.conversationPanel = mgr:CreateUIWidget("CAIDiplomacyConversationPanel", "Panel", {
        SpeechSettings = { Role = false, Position = false },
    })
    m_ui.conversationList = mgr:CreateUIWidget("CAIDiplomacyConversationList", "List", {
        SpeechSettings = { Position = false },
        GetLabel = function()
            local title = ControlText(Controls.LeaderResponseName)
            if title ~= "" then return title end
            return GetPanelLabel()
        end,
    })
    m_ui.conversationPanel:AddChild(m_ui.conversationList)
    m_ui.root:AddChild(m_ui.cinemaPanel)
    m_ui.root:AddChild(m_ui.overviewPanel)
    m_ui.root:AddChild(m_ui.conversationPanel)

    EnsureLeadersTreeStructure()
end

local function PushRoot()
    if not mgr then return end
    if not mgr:HasWidget(m_ui.root) then
        mgr:Push(m_ui.root, PopupPriority.Utmost)
    end
end

local function FocusOverviewPanel()
    SetActivePanel(m_ui.overviewPanel)
end

local function FocusConversationPanel()
    SetActivePanel(m_ui.conversationPanel)
end

local function FocusCinemaPanel()
    SetActivePanel(m_ui.cinemaPanel)
end

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
    RefreshOverviewPanel()
end)

PopulateIntelOverview = WrapFunc(PopulateIntelOverview, function(orig, overviewInstance, ...)
    local result = orig(overviewInstance, ...)
    CaptureIntelInstance("overview", overviewInstance)
    return result
end)

OnActivateIntelGossipHistoryPanel = WrapFunc(OnActivateIntelGossipHistoryPanel, function(orig, gossipInstance, ...)
    local result = orig(gossipInstance, ...)
    CaptureIntelInstance("gossip", gossipInstance)
    return result
end)

OnActivateIntelAccessLevelPanel = WrapFunc(OnActivateIntelAccessLevelPanel, function(orig, accessLevelInstance, ...)
    local result = orig(accessLevelInstance, ...)
    CaptureIntelInstance("access", accessLevelInstance)
    return result
end)

OnActivateIntelRelationshipPanel = WrapFunc(OnActivateIntelRelationshipPanel, function(orig, relationshipInstance, ...)
    local result = orig(relationshipInstance, ...)
    CaptureIntelInstance("relationship", relationshipInstance)
    return result
end)

AddIntelOverview = WrapFunc(AddIntelOverview, function(orig, ...)
    local result = orig(...)
    CaptureLastIntelPanel("overview")
    return result
end)

AddIntelGossip = WrapFunc(AddIntelGossip, function(orig, ...)
    local result = orig(...)
    CaptureLastIntelPanel("gossip")
    return result
end)

AddIntelAccessLevel = WrapFunc(AddIntelAccessLevel, function(orig, ...)
    local result = orig(...)
    CaptureLastIntelPanel("access")
    return result
end)

AddIntelRelationship = WrapFunc(AddIntelRelationship, function(orig, ...)
    local result = orig(...)
    CaptureLastIntelPanel("relationship")
    return result
end)

local originalMakeDealApplyStatement = MakeDeal_ApplyStatement
MakeDeal_ApplyStatement = WrapFunc(MakeDeal_ApplyStatement, function(orig, ...)
    ClearConversationState()
    local result = orig(...)
    return result
end)
if StatementHandlers["MAKE_DEAL"] and StatementHandlers["MAKE_DEAL"].ApplyStatement == originalMakeDealApplyStatement then
    StatementHandlers["MAKE_DEAL"].ApplyStatement = MakeDeal_ApplyStatement
end

local originalMakeDemandApplyStatement = MakeDemand_ApplyStatement
MakeDemand_ApplyStatement = WrapFunc(MakeDemand_ApplyStatement, function(orig, ...)
    ClearConversationState()
    local result = orig(...)
    return result
end)
if StatementHandlers["MAKE_DEMAND"] and StatementHandlers["MAKE_DEMAND"].ApplyStatement == originalMakeDemandApplyStatement then
    StatementHandlers["MAKE_DEMAND"].ApplyStatement = MakeDemand_ApplyStatement
end

ShowPanel = WrapFunc(ShowPanel, function(orig, panelInstance, ...)
    local result = orig(panelInstance, ...)
    if panelInstance then
        for key, panel in pairs(m_vanilla.intelPanels) do
            if panel == panelInstance then
                m_vanilla.activeIntelKey = key
                break
            end
        end
    end
    RefreshSelectedLeaderDetails()
    return result
end)

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
    FocusConversationPanel()
end)

ShowCinemaMode = WrapFunc(ShowCinemaMode, function(orig)
    orig()
    FocusCinemaPanel()
end)

SelectPlayer = WrapFunc(SelectPlayer, function(orig, playerID, mode, refresh, allowDeadPlayer)
    orig(playerID, mode, refresh, allowDeadPlayer)
    m_state.SelectedPlayer = playerID
    EnsureRootBuilt()
    SyncSelectedLeaderRow()
    if mode == CAI_OVERVIEW_MODE then
        FocusOverviewPanel()
    end
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
    PushRoot()
end)
ContextPtr:SetShowHandler(OnShow)
