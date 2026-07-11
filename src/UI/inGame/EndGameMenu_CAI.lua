include("caiUtils")

local mgr            = ExposedMembers.CAI_UIManager

-- ============================================================================
-- Constants
-- ============================================================================
local m_WasShowing   = false
local PANEL_ID       = "CAIEndGame_Panel"
local MOVIE_PANEL_ID = "CAIEndGame_Movie"
local TABS_ID        = "CAIEndGame_Tabs"
local HOVER_SOUND    = "Main_Menu_Mouse_Over"

-- ============================================================================
-- State
-- ============================================================================
local m_panel        = nil
local m_tabs         = nil
local m_resultsList  = nil
local m_rankingList  = nil
local m_graphsTree   = nil
local m_chatHistory  = nil
local m_chatInput    = nil
local m_chatTarget   = nil
local m_moviePanel   = nil
local m_isBuilt      = false
local m_chatEntries  = {}
local m_chatEntryId  = 1
local m_chatTargetState = {
    targetType = ChatTargetTypes.CHATTARGET_ALL,
    targetID = GetNoPlayerTargetID(),
}

-- ============================================================================
-- Helpers
-- ============================================================================
local function MakeId(prefix)
    return mgr:GenerateWidgetId(prefix)
end

local function SafeGetText(control)
    if control and not control:IsHidden() then
        local text = control:GetText()
        if text and text ~= "" then
            return text
        end
    end
    return nil
end

local function SafeGetTooltip(control)
    if control and control.GetToolTipString and not control:IsHidden() then
        local text = control:GetToolTipString()
        if text and text ~= "" then
            return text
        end
    end
    return nil
end

-- ============================================================================
-- Tab 1: Results
-- ============================================================================
local function RebuildResultsList()
    if not m_resultsList then return end
    m_resultsList:ClearChildren()

    if Controls.VictoryPanel and not Controls.VictoryPanel:IsHidden() then
        local parts = {}
        local typeName = SafeGetText(Controls.VictoryTypeName)
        if typeName then table.insert(parts, typeName) end
        local playerName = SafeGetText(Controls.VictoryPlayerName)
        if playerName then table.insert(parts, playerName) end
        if #parts > 0 then
            local label = table.concat(parts, ", ")
            local blurb = SafeGetText(Controls.VictoryBlurb)
            local item = mgr:CreateWidget(MakeId("CAIEG_res_"), "StaticText", {
                Label = function() return label end,
                Tooltip = blurb and function() return blurb end or nil,
                FocusKey = "endgame:result:winner",
            })
            item:SetFocusSound(HOVER_SOUND)
            m_resultsList:AddChild(item)
        end
    end

    if Controls.DefeatedPanel and not Controls.DefeatedPanel:IsHidden() then
        local parts = {}
        local typeName = SafeGetText(Controls.DefeatedTypeName)
        if typeName then table.insert(parts, typeName) end
        local playerName = SafeGetText(Controls.DefeatedPlayerName)
        if playerName then table.insert(parts, playerName) end
        if #parts > 0 then
            local label = table.concat(parts, ", ")
            local item = mgr:CreateWidget(MakeId("CAIEG_res_"), "StaticText", {
                Label = function() return label end,
                FocusKey = "endgame:result:defeated",
            })
            item:SetFocusSound(HOVER_SOUND)
            m_resultsList:AddChild(item)
        end
    end
end

-- ============================================================================
-- Tab 2: Ranking
-- ============================================================================
local function RebuildRankingList()
    if not m_rankingList then return end
    m_rankingList:ClearChildren()

    local player = Players[Game.GetLocalPlayer()]
    local score = player and player:GetScore() or 0

    local totalRankings = 0
    for _ in GameInfo.HistoricRankings() do
        totalRankings = totalRankings + 1
    end

    local playerAdded = false
    local playerRank = totalRankings
    local count = 1
    local rows = {}
    for row in GameInfo.HistoricRankings() do
        local leaderName = Locale.Lookup(row.HistoricLeader)
        local displayScore
        local quote = nil

        if score >= row.Score and not playerAdded then
            displayScore = Locale.ToNumber(score)
            quote = Locale.Lookup(row.Quote)
            playerRank = count
            playerAdded = true
        else
            displayScore = Locale.ToNumber(row.Score)
        end

        table.insert(rows, {
            label = Locale.Lookup("LOC_UI_ENDGAME_NUMBERING_FORMAT", count) ..
                " " .. leaderName .. ", " .. displayScore,
            quote = quote,
            key = count,
        })

        count = count + 1
    end

    local titleText = SafeGetText(Controls.RankingTitle)
    if titleText then
        local headerLabel = titleText .. ", " .. playerRank .. " / " .. totalRankings
        local header = mgr:CreateWidget(MakeId("CAIEG_rank_"), "StaticText", {
            Label = function() return headerLabel end,
            FocusKey = "endgame:rank:title",
        })
        header:SetFocusSound(HOVER_SOUND)
        m_rankingList:AddChild(header)
    end

    for _, r in ipairs(rows) do
        local capturedQuote = r.quote
        local capturedLabel = r.label
        local item = mgr:CreateWidget(MakeId("CAIEG_rank_"), "StaticText", {
            Label = function() return capturedLabel end,
            Tooltip = capturedQuote and function() return capturedQuote end or nil,
            FocusKey = "endgame:rank:" .. r.key,
        })
        item:SetFocusSound(HOVER_SOUND)
        m_rankingList:AddChild(item)
    end
end

-- ============================================================================
-- Tab 3: Graphs (numeric data per player)
-- ============================================================================
local function RebuildGraphsTree()
    if not m_graphsTree then return end
    m_graphsTree:ClearChildren()

    local initialTurn = g_InitialTurn or GameConfiguration.GetStartTurn()
    local finalTurn = g_FinalTurn or Game.GetCurrentGameTurn()
    local playerInfos = g_PlayerInfos or {}

    if #playerInfos == 0 then
        local noData = mgr:CreateWidget(MakeId("CAIEG_graph_"), "StaticText", {
            Label = function() return Locale.Lookup("LOC_UI_ENDGAME_REPLAY_NOGRAPHDATA") end,
            FocusKey = "endgame:graph:nodata",
        })
        noData:SetFocusSound(HOVER_SOUND)
        m_graphsTree:AddChild(noData)
        return
    end

    local dataSetCount = GameSummary.GetDataSetCount()
    local dataSets = {}
    for dsIdx = 0, dataSetCount - 1 do
        if GameSummary.GetDataSetVisible(dsIdx) and GameSummary.HasDataSetValues(dsIdx) then
            local name = GameSummary.GetDataSetName(dsIdx)
            local displayName = GameSummary.GetDataSetDisplayName(dsIdx)
            if IsValidGraphDataSetToShow(name) then
                table.insert(dataSets, { index = dsIdx, name = name, display = Locale.Lookup(displayName) })
            end
        end
    end
    table.sort(dataSets, function(a, b) return Locale.Compare(a.display, b.display) == -1 end)

    local coalescedData = {}
    for _, ds in ipairs(dataSets) do
        coalescedData[ds.name] = GameSummary.CoalesceDataSet(ds.index, initialTurn, finalTurn)
    end

    for _, pInfo in ipairs(playerInfos) do
        local pName = pInfo.Name and Locale.Lookup(pInfo.Name) or ("Player " .. pInfo.Id)

        local playerNode = mgr:CreateWidget(MakeId("CAIEG_graph_"), "TreeItem", {
            Label = function() return pName end,
            FocusKey = "endgame:graph:player:" .. pInfo.Id,
        })
        playerNode:SetFocusSound(HOVER_SOUND)
        m_graphsTree:AddChild(playerNode)

        for _, ds in ipairs(dataSets) do
            local graphData = coalescedData[ds.name]
            local data = graphData and graphData[pInfo.Id]
            local finalValue = nil
            if data then
                for turn = finalTurn, initialTurn, -1 do
                    if data[turn] ~= nil then
                        finalValue = data[turn]
                        break
                    end
                end
            end

            local valueStr = finalValue and tostring(math.floor(finalValue)) or
                Locale.Lookup("LOC_UI_ENDGAME_REPLAY_NOGRAPHDATA")
            local leafLabel = ds.display .. ": " .. valueStr

            local leaf = mgr:CreateWidget(MakeId("CAIEG_graph_"), "TreeItem", {
                Label = function() return leafLabel end,
                FocusKey = "endgame:graph:" .. pInfo.Id .. ":" .. ds.name,
            })
            leaf:SetFocusSound(HOVER_SOUND)
            playerNode:AddChild(leaf)
        end
    end
end

-- ============================================================================
-- Tab 4: Chat
-- ============================================================================
local function GetChatInputTooltip()
    return SafeGetTooltip(Controls.ChatEntry) or Locale.Lookup("LOC_CHAT_HELP_COMMAND_HINT")
end

local function BuildChatTargetOptions()
    local options = {}
    local selectedIndex = 0
    local localPlayerID = Game.GetLocalPlayer()

    table.insert(options, {
        label = Locale.Lookup("LOC_DIPLO_TO_ALL"),
        value = {
            targetType = ChatTargetTypes.CHATTARGET_ALL,
            targetID = GetNoPlayerTargetID(),
        },
    })
    if m_chatTargetState.targetType == ChatTargetTypes.CHATTARGET_ALL then
        selectedIndex = 1
    end

    if localPlayerID ~= nil and localPlayerID >= 0 then
        local localConfig = PlayerConfigurations[localPlayerID]
        local localTeam = localConfig and localConfig:GetTeam() or TeamTypes.NO_TEAM
        if localTeam ~= TeamTypes.NO_TEAM and GameConfiguration.GetTeamPlayerCount(localTeam, true) > 1 then
            table.insert(options, {
                label = Locale.Lookup("LOC_DIPLO_TO_TEAM"),
                value = {
                    targetType = ChatTargetTypes.CHATTARGET_TEAM,
                    targetID = localTeam,
                },
            })
            if m_chatTargetState.targetType == ChatTargetTypes.CHATTARGET_TEAM then
                selectedIndex = #options
            end
        end
    end

    for _, playerID in ipairs(GameConfiguration.GetParticipatingPlayerIDs()) do
        local cfg = PlayerConfigurations[playerID]
        if playerID ~= localPlayerID and cfg and cfg:IsHuman() then
            table.insert(options, {
                label = Locale.Lookup("LOC_DIPLO_TO_PLAYER", cfg:GetPlayerName()),
                value = {
                    targetType = ChatTargetTypes.CHATTARGET_PLAYER,
                    targetID = playerID,
                },
            })
            if m_chatTargetState.targetType == ChatTargetTypes.CHATTARGET_PLAYER
                and m_chatTargetState.targetID == playerID then
                selectedIndex = #options
            end
        end
    end

    if selectedIndex == 0 and #options > 0 then
        selectedIndex = 1
    end

    return options, selectedIndex
end

local function SyncLocalChatTargetFromVanilla()
    local textControl = Controls.ChatPull and Controls.ChatPull:GetButton() and Controls.ChatPull:GetButton():GetTextControl()
    local liveLabel = textControl and textControl:GetText() or nil
    if not liveLabel or liveLabel == "" then return end

    local options = BuildChatTargetOptions()
    for _, option in ipairs(options) do
        if option.label == liveLabel and option.value then
            m_chatTargetState.targetType = option.value.targetType
            m_chatTargetState.targetID = option.value.targetID
            return
        end
    end
end

local function UpdateVanillaChatTargetState()
    ValidatePlayerTarget(m_chatTargetState)
    UpdatePlayerTargetPulldown(Controls.ChatPull, m_chatTargetState)
    UpdatePlayerTargetEditBox(Controls.ChatEntry, m_chatTargetState)
    UpdatePlayerTargetIcon(Controls.ChatIcon, m_chatTargetState)

    local textControl = Controls.ChatPull and Controls.ChatPull:GetButton() and Controls.ChatPull:GetButton():GetTextControl()
    local label = textControl and textControl:GetText() or nil
    if label and label ~= "" then
        Controls.ChatPull:SetToolTipString(label)
    end

    PlayerTargetChanged(m_chatTargetState)
end

local function RebuildChatTarget()
    if not m_chatTarget then return end

    local options, selectedIndex = BuildChatTargetOptions()
    m_chatTarget:SetOptions(options)
    if selectedIndex > 0 then
        m_chatTarget:SetSelectedIndex(selectedIndex, true)
    end
end

local function SyncChatTargetSelection()
    if not m_chatTarget then return end

    local options, selectedIndex = BuildChatTargetOptions()
    if selectedIndex <= 0 then return end

    local currentIndex = m_chatTarget:GetSelectedIndex()
    if currentIndex == selectedIndex then return end

    local currentOption = options[currentIndex]
    local currentValue = currentOption and currentOption.value or nil
    if currentValue
        and currentValue.targetType == m_chatTargetState.targetType
        and currentValue.targetID == m_chatTargetState.targetID then
        return
    end

    m_chatTarget:SetSelectedIndex(selectedIndex, true)
end

local function AppendChatEntry(text)
    if not text or text == "" then return end

    table.insert(m_chatEntries, {
        Id = m_chatEntryId,
        Label = text,
    })
    m_chatEntryId = m_chatEntryId + 1
end

local function CaptureVanillaChatHistory()
    m_chatEntries = {}
    m_chatEntryId = 1

    local stack = Controls.ChatStack
    if not stack then return end
    local children = stack:GetChildren()
    if not children then return end

    for _, child in ipairs(children) do
        local innerChildren = child:GetChildren()
        if innerChildren then
            for _, inner in ipairs(innerChildren) do
                local text = inner:GetText()
                if text and text ~= "" then
                    AppendChatEntry(text)
                end
            end
        end
    end
end

local function RebuildChatTab()
    if not m_chatHistory then return end

    local capture = mgr:CaptureFocusKey(m_chatHistory)
    m_chatHistory:ClearChildren()

    for _, entry in ipairs(m_chatEntries) do
        local item = mgr:CreateWidget(MakeId("CAIEG_chat_"), "StaticText", {
            Label = function() return entry.Label end,
            FocusKey = "endgame:chat:" .. tostring(entry.Id),
        })
        m_chatHistory:AddChild(item)
    end

    mgr:RestoreFocus(m_chatHistory, capture)
end

local function OnChatReceived()
    if not m_isBuilt then return end
    CaptureVanillaChatHistory()
    RebuildChatTab()
end

local function SendEndGameChat(text)
    if text == nil then return end
    if string.len(text) > 0 then
        local parsedText
        local chatTargetChanged = false
        local printHelp = false

        parsedText, chatTargetChanged, printHelp = ParseInputChatString(text, m_chatTargetState)
        if chatTargetChanged then
            UpdateVanillaChatTargetState()
            SyncChatTargetSelection()
        end

        if printHelp then
            ChatPrintHelp(Controls.ChatStack, {}, Controls.ChatScroll)
        end

        if parsedText ~= "" then
            local chatTarget = {}
            PlayerTargetToChatTarget(m_chatTargetState, chatTarget)
            Network.SendChat(parsedText, chatTarget.targetType, chatTarget.targetID)
            UI.PlaySound("Play_MP_Chat_Message_Sent")
        end
    end

    Controls.ChatEntry:ClearString()
end

-- ============================================================================
-- Action buttons (direct children of panel, below tabs)
-- ============================================================================
local function AddActionButtons()
    if not m_panel then return end

    local actionsPanel = mgr:CreateWidget(MakeId("CAIEG_acts_"), "Panel", { Transparent = true, WrapAround = false })
    m_panel:AddChild(actionsPanel)

    local buttons = {
        { control = Controls.ReplayMovieButton, key = "replaymovie" },
    }

    if Controls.HistoricMoments then
        table.insert(buttons, { control = Controls.HistoricMoments, key = "historicmoments" })
    end
    if Controls.ExportHistoricMoments then
        table.insert(buttons, { control = Controls.ExportHistoricMoments, key = "exportmoments" })
    end

    table.insert(buttons, { control = Controls.MainMenuButton, key = "mainmenu" })
    table.insert(buttons, { control = Controls.NextPlayerButton, key = "nextplayer" })
    table.insert(buttons, { control = Controls.BackButton, key = "onemore" })

    for _, def in ipairs(buttons) do
        local ctrl = def.control
        if ctrl then
            local capturedCtrl = ctrl
            local btn = mgr:CreateWidget(MakeId("CAIEG_act_"), "Button", {
                Label = function()
                    return capturedCtrl:GetText() or ""
                end,
                HiddenPredicate = function()
                    return capturedCtrl:IsHidden()
                end,
                DisabledPredicate = function()
                    return capturedCtrl:IsDisabled()
                end,
                FocusKey = "endgame:action:" .. def.key,
            })
            btn:SetFocusSound(HOVER_SOUND)
            btn:On("activate", function()
                capturedCtrl:DoLeftClick()
            end)
            actionsPanel:AddChild(btn)
        end
    end
end

-- ============================================================================
-- Movie skip panel (pushed on top of main panel during playback)
-- ============================================================================
local function PushMoviePanel()
    if m_moviePanel then return end

    m_moviePanel = mgr:CreateWidget(MOVIE_PANEL_ID, "Panel", {
        Label = function() return Locale.Lookup("LOC_CAI_ENDGAME_MOVIE_PLAYING") end,
    })

    local skipBtn = mgr:CreateWidget(MakeId("CAIEG_movie_"), "Button", {
        Label = function() return Locale.Lookup("LOC_CAI_ENDGAME_MOVIE_SKIP") end,
        FocusKey = "endgame:movie:skip",
    })
    skipBtn:SetFocusSound(HOVER_SOUND)
    skipBtn:On("activate", function()
        OnMovieExitOrFinished()
    end)
    m_moviePanel:AddChild(skipBtn)

    mgr:Push(m_moviePanel, PopupPriority.Current)
end

local function RemoveMoviePanel()
    if m_moviePanel then
        mgr:RemoveFromStack(MOVIE_PANEL_ID)
        m_moviePanel = nil
    end
end

-- ============================================================================
-- Build / Teardown
-- ============================================================================
local function BuildPanel()
    if m_isBuilt then return end

    m_panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function()
            return SafeGetText(Controls.RibbonLabel) or Locale.Lookup("LOC_CAI_ENDGAME_TITLE")
        end,
    })

    m_tabs = mgr:CreateWidget(TABS_ID, "TabControl", {})
    m_panel:AddChild(m_tabs)

    local vanillaTabButtons = {}
    local tabIndex = 0

    -- Tab 1: Results
    tabIndex = tabIndex + 1
    local resultsPage = m_tabs:AddPage(function() return Locale.Lookup("LOC_UI_ENDGAME_VICTORY_INFO") end)
    m_resultsList = mgr:CreateWidget(MakeId("CAIEG_"), "List", {})
    resultsPage:AddChild(m_resultsList)
    vanillaTabButtons[tabIndex] = Controls.InfoButton

    -- Tab 2: Ranking (conditional)
    local hasRankings = GameInfo.HistoricRankings and #GameInfo.HistoricRankings > 0
    if hasRankings then
        tabIndex = tabIndex + 1
        local rankingPage = m_tabs:AddPage(function() return Locale.Lookup("LOC_UI_ENDGAME_RANKING") end)
        m_rankingList = mgr:CreateWidget(MakeId("CAIEG_"), "List", {})
        rankingPage:AddChild(m_rankingList)
        vanillaTabButtons[tabIndex] = Controls.RankingButton
    end

    -- Tab 3: Graphs
    tabIndex = tabIndex + 1
    local graphsPage = m_tabs:AddPage(function() return Locale.Lookup("LOC_UI_ENDGAME_REPLAY") end)
    m_graphsTree = mgr:CreateWidget(MakeId("CAIEG_"), "Tree", {})
    graphsPage:AddChild(m_graphsTree)
    vanillaTabButtons[tabIndex] = Controls.ReplayButton

    -- Tab 4: Chat (multiplayer only)
    local isMP = GameConfiguration.IsNetworkMultiplayer() and UI.HasFeature("Chat")
    if isMP then
        tabIndex = tabIndex + 1
        local chatPage = m_tabs:AddPage(function() return Locale.Lookup("LOC_UI_ENDGAME_CHAT") end)
        vanillaTabButtons[tabIndex] = Controls.ChatButton

        SyncLocalChatTargetFromVanilla()

        m_chatInput = mgr:CreateWidget(MakeId("CAIEG_chat_"), "EditBox", {
            Label = function() return Locale.Lookup("LOC_CAI_ENDGAME_CHAT_INPUT") end,
            Tooltip = GetChatInputTooltip,
            AlwaysEdit = true,
            CommitOnFocusLeave = false,
            HighlightOnEdit = true,
            EnterToCommit = true,
            MaxCharacters = 250,
            FocusKey = "endgame:chat:input",
        })
        m_chatInput:SetValueSetter(function(widget, text)
            if text and text ~= "" then
                SendEndGameChat(text)
                widget:SetText("", true)
            end
        end)
        chatPage:AddChild(m_chatInput)

        m_chatTarget = mgr:CreateWidget(MakeId("CAIEG_chat_"), "Dropdown", {
            Label = function() return Locale.Lookup("LOC_CAI_STAGING_CHAT_TARGET") end,
            FocusKey = "endgame:chat:target",
        })
        m_chatTarget:SetFocusSound(HOVER_SOUND)
        m_chatTarget:SetValueSetter(function(_, target)
            if target then
                m_chatTargetState.targetType = target.targetType
                m_chatTargetState.targetID = target.targetID
                UpdateVanillaChatTargetState()
                RebuildChatTarget()
            end
        end)
        chatPage:AddChild(m_chatTarget)

        m_chatHistory = mgr:CreateWidget(MakeId("CAIEG_chat_"), "List", {
            Label = function() return Locale.Lookup("LOC_CAI_ENDGAME_CHAT_HISTORY") end,
            FocusKey = "endgame:chat:history",
        })
        chatPage:AddChild(m_chatHistory)

        CaptureVanillaChatHistory()
        RebuildChatTarget()
    end

    local isMirroringTab = false
    m_tabs:On("value_changed", function(_, pageIndex)
        if isMirroringTab then return end
        isMirroringTab = true
        local btn = vanillaTabButtons[pageIndex]
        if btn then btn:DoLeftClick() end
        isMirroringTab = false
    end)

    AddActionButtons()

    m_isBuilt = true
end

local function PopulateAll()
    RebuildResultsList()
    if m_rankingList then
        PopulateRankingResults()
        RebuildRankingList()
    end
    ReplayInitialize()
    RebuildGraphsTree()
    if m_chatHistory then
        CaptureVanillaChatHistory()
        RebuildChatTarget()
        RebuildChatTab()
    end
end

local function PushPanel()
    BuildPanel()
    PopulateAll()
    RemoveMoviePanel()
    mgr:Push(m_panel, PopupPriority.EndGameMenu)
end

local function DestroyPanel()
    RemoveMoviePanel()
    if m_isBuilt then
        mgr:RemoveFromStack(PANEL_ID)
        m_panel = nil
        m_tabs = nil
        m_resultsList = nil
        m_rankingList = nil
        m_graphsTree = nil
        m_chatHistory = nil
        m_chatInput = nil
        m_chatTarget = nil
        m_chatEntries = {}
        m_chatEntryId = 1
        m_isBuilt = false
    end
end

-- ============================================================================
-- Lifecycle wraps
-- ============================================================================
OnReplayMovie = WrapFunc(OnReplayMovie, function(orig)
    orig()
    if not m_WasShowing then
        UITutorialManager:AddControlToAlwaysReceiveInput(ContextPtr)
        m_WasShowing = true
    end
    if Controls.MovieFill and not Controls.MovieFill:IsHidden() then
        PushMoviePanel()
    end
end)

OnMovieExitOrFinished = WrapFunc(OnMovieExitOrFinished, function(orig)
    RemoveMoviePanel()
    orig()
    if not m_isBuilt then
        PushPanel()
    end
end)

ShowComplete = WrapFunc(ShowComplete, function(orig)
    orig()
    if not m_moviePanel then
        PushPanel()
    end
end)

Close = WrapFunc(Close, function(orig)
    DestroyPanel()
    orig()
    UITutorialManager:RemoveControlToAlwaysReceiveInput(ContextPtr)
    m_WasShowing = false
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, kInput)
    if m_isBuilt or m_moviePanel then
        if mgr:HandleInput(kInput) then
            return true
        end
    end
    return orig(kInput)
end)

OnChat = WrapFunc(OnChat, function(orig, fromPlayer, toPlayer, text, eTargetType)
    orig(fromPlayer, toPlayer, text, eTargetType)
    OnChatReceived()
end)

ChatPrintHelp = WrapFunc(ChatPrintHelp, function(orig, ...)
    local result = orig(...)
    OnChatReceived()
    return result
end)

OnPlayerInfoChanged = WrapFunc(OnPlayerInfoChanged, function(orig, playerID)
    local result = orig(playerID)
    ValidatePlayerTarget(m_chatTargetState)
    UpdateVanillaChatTargetState()
    RebuildChatTarget()
    return result
end)
