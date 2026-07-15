include("caiUtils")
include("Civ6Common")
include("ChatPanel")
include("InGameHelpers_CAI")

local mgr = ExposedMembers.CAI_UIManager

local ACTION_OPEN_CHAT_PANEL = Input.GetActionId("UI_OpenChatPanel")
local CHAT_PANEL_ROOT_ID = "CAIChatPanel_Root"
local CHAT_HISTORY_ID = "CAIChatPanel_History"
local CHAT_PLAYERS_ID = "CAIChatPanel_Players"
local KICK_DIALOG_ID = "CAIChatPanel_KickVoteDialog"
local HOVER_SOUND = "Main_Menu_Mouse_Over"
local CHAT_HISTORY_LIMIT = 200

local m_caiPanel = nil
local m_caiChatInput = nil
local m_caiChatTarget = nil
local m_caiChatHistory = nil
local m_caiPlayersList = nil
local m_caiKickVoteDialog = nil
local m_caiVisualChatInstances = {}
local m_caiChatEntries = {}
local m_caiChatEntryNextId = 1
local m_caiPlayerTarget = {
    targetType = ChatTargetTypes.CHATTARGET_ALL,
    targetID = GetNoPlayerTargetID(),
}
local m_caiKickVotes = {}

local m_vanillaInputHandler = InputHandler
local m_vanillaMapPinSendHandler = OnSendPinToChat
local m_vanillaMapPinTargetRequestHandler = OnMapPinPopup_RequestChatPlayerTarget
local m_vanillaBuildPlayerList = BuildPlayerList
local m_vanillaKickVoteStarted = OnKickVoteStarted
local m_vanillaKickVoteComplete = OnKickVoteComplete

local CAI_KICKVOTE_REASONS = {
    [KickVoteReasonType.KICKVOTE_AFK] = "LOC_KICK_VOTE_REASON_AFK",
    [KickVoteReasonType.KICKVOTE_GRIEFING] = "LOC_KICK_VOTE_REASON_GRIEFING",
    [KickVoteReasonType.KICKVOTE_CHEATING] = "LOC_KICK_VOTE_REASON_CHEATING",
}

local function CAI_Lookup(text, ...)
    if text == nil then return "" end
    return Locale.Lookup(text, ...)
end

local function CAI_IsHidden(control)
    return control and control.IsHidden and control:IsHidden() or false
end

local function CAI_IsDisabled(control)
    return control and control.IsDisabled and control:IsDisabled() or false
end

local function CAI_ControlText(control)
    if control and control.GetText then
        local text = control:GetText()
        if text and text ~= "" then return text end
    end
    return ""
end

local function CAI_ControlTooltip(control)
    if control and control.GetToolTipString then
        local text = control:GetToolTipString()
        if text and text ~= "" then return text end
    end
    return ""
end

local function CAI_JoinNonEmpty(parts, separator)
    local results = {}
    for _, part in ipairs(parts) do
        if part ~= nil and part ~= "" then
            table.insert(results, part)
        end
    end
    return table.concat(results, separator or ", ")
end

local function CAI_GetChatInputTooltip()
    local tooltip = CAI_ControlTooltip(Controls.ChatEntry)
    if tooltip ~= "" then return tooltip end
    return CAI_Lookup("LOC_CHAT_HELP_COMMAND_HINT")
end

local function CAI_UpdateVanillaTargetState()
    ValidatePlayerTarget(m_caiPlayerTarget)
    UpdatePlayerTargetPulldown(Controls.ChatPull, m_caiPlayerTarget)
    UpdatePlayerTargetEditBox(Controls.ChatEntry, m_caiPlayerTarget)
    UpdatePlayerTargetIcon(Controls.ChatIcon, m_caiPlayerTarget)

    local label = CAI_ControlText(Controls.ChatPull:GetButton():GetTextControl())
    if label ~= "" then
        Controls.ChatPull:SetToolTipString(label)
    end

    PlayerTargetChanged(m_caiPlayerTarget)
end

local function CAI_BuildChatTargetOptions()
    local options = {}
    local selectedIndex = 0
    local localPlayerID = Game.GetLocalPlayer()

    table.insert(options, {
        label = CAI_Lookup("LOC_DIPLO_TO_ALL"),
        value = {
            targetType = ChatTargetTypes.CHATTARGET_ALL,
            targetID = GetNoPlayerTargetID(),
        },
    })
    if m_caiPlayerTarget.targetType == ChatTargetTypes.CHATTARGET_ALL then
        selectedIndex = 1
    end

    if localPlayerID ~= nil and localPlayerID >= 0 then
        local localConfig = PlayerConfigurations[localPlayerID]
        local localTeam = localConfig and localConfig:GetTeam() or TeamTypes.NO_TEAM
        if localTeam ~= TeamTypes.NO_TEAM and GameConfiguration.GetTeamPlayerCount(localTeam, true) > 1 then
            table.insert(options, {
                label = CAI_Lookup("LOC_DIPLO_TO_TEAM"),
                value = {
                    targetType = ChatTargetTypes.CHATTARGET_TEAM,
                    targetID = localTeam,
                },
            })
            if m_caiPlayerTarget.targetType == ChatTargetTypes.CHATTARGET_TEAM then
                selectedIndex = #options
            end
        end
    end

    for _, playerID in ipairs(GameConfiguration.GetParticipatingPlayerIDs()) do
        local cfg = PlayerConfigurations[playerID]
        if playerID ~= localPlayerID and cfg and cfg:IsHuman() then
            table.insert(options, {
                label = CAI_Lookup("LOC_DIPLO_TO_PLAYER", cfg:GetPlayerName()),
                value = {
                    targetType = ChatTargetTypes.CHATTARGET_PLAYER,
                    targetID = playerID,
                },
            })
            if m_caiPlayerTarget.targetType == ChatTargetTypes.CHATTARGET_PLAYER
                and m_caiPlayerTarget.targetID == playerID then
                selectedIndex = #options
            end
        end
    end

    if selectedIndex == 0 and #options > 0 then
        selectedIndex = 1
    end

    return options, selectedIndex
end

local function CAI_RebuildChatTarget()
    if not m_caiChatTarget then return end

    local options, selectedIndex = CAI_BuildChatTargetOptions()
    m_caiChatTarget:SetOptions(options)
    if selectedIndex > 0 then
        m_caiChatTarget:SetSelectedIndex(selectedIndex, true)
    end
end

local function CAI_SyncChatTargetSelection()
    if not m_caiChatTarget then return end

    local options, selectedIndex = CAI_BuildChatTargetOptions()
    if selectedIndex <= 0 then return end

    local currentIndex = m_caiChatTarget:GetSelectedIndex()
    if currentIndex == selectedIndex then return end

    local currentOption = options[currentIndex]
    local currentValue = currentOption and currentOption.value or nil
    if currentValue
        and currentValue.targetType == m_caiPlayerTarget.targetType
        and currentValue.targetID == m_caiPlayerTarget.targetID then
        return
    end

    m_caiChatTarget:SetSelectedIndex(selectedIndex, true)
end

local function CAI_CanUseRealtimeChat()
    return UI.HasFeature("Chat")
        and GameConfiguration.IsNetworkMultiplayer()
        and Controls.ChatEntry ~= nil
end

local function CAI_RequestWorldTrackerShowChat()
    LuaEvents.CAIWorldTrackerShowChat()
end

local function CAI_MakeChatPrefix(fromPlayer, toPlayer, eTargetType)
    local fromConfig = PlayerConfigurations[fromPlayer]
    if not fromConfig then return nil end

    local playerName = CAI_Lookup(fromConfig:GetPlayerName())
    if eTargetType == ChatTargetTypes.CHATTARGET_PLAYER then
        local targetConfig = PlayerConfigurations[toPlayer]
        if targetConfig then
            return CAI_Lookup("LOC_CAI_STAGING_CHAT_WHISPER", playerName, CAI_Lookup(targetConfig:GetPlayerName()))
        end
    elseif eTargetType == ChatTargetTypes.CHATTARGET_TEAM then
        return CAI_Lookup("LOC_CAI_STAGING_CHAT_TEAM", playerName)
    end

    return playerName
end

local function CAI_TrimChatEntries()
    while #m_caiChatEntries > CHAT_HISTORY_LIMIT do
        table.remove(m_caiChatEntries, 1)
    end
end

local function CAI_AppendChatEntry(entry)
    entry.Id = entry.Id or m_caiChatEntryNextId
    m_caiChatEntryNextId = m_caiChatEntryNextId + 1
    table.insert(m_caiChatEntries, entry)
    CAI_TrimChatEntries()
    return entry
end

local function CAI_AppendBuffer(text)
    if text ~= nil and text ~= "" then
        LuaEvents.CAIAppendToMessageBuffer(text, "chat")
    end
end

local function CAI_RecordTextEntry(text, appendToBuffer)
    if text == nil or text == "" then return nil end
    local entry = CAI_AppendChatEntry({
        Kind = "text",
        Label = text,
    })
    if appendToBuffer then
        CAI_AppendBuffer(text)
    end
    return entry
end

local function CAI_RecordPinEntry(prefix, pinPlayerID, pinID, appendToBuffer)
    local mapPinCfg = GetMapPinConfig(pinPlayerID, pinID)
    if mapPinCfg == nil then return nil end

    local pinLabel = BuildMapTacLabel(mapPinCfg)
    if pinLabel == nil or pinLabel == "" then
        pinLabel = GetMapTacName(mapPinCfg) or CAI_Lookup("LOC_MAP_PIN_DEFAULT_NAME", mapPinCfg:GetID() + 1)
    end

    local line = CAI_Lookup("LOC_CAI_STAGING_CHAT_LINE", prefix, pinLabel)
    local tooltip = line
    local entry = CAI_AppendChatEntry({
        Kind = "pin",
        Label = line,
        Tooltip = tooltip,
        PlayerID = pinPlayerID,
        PinID = pinID,
        HexX = mapPinCfg:GetHexX(),
        HexY = mapPinCfg:GetHexY(),
    })
    if appendToBuffer then
        CAI_AppendBuffer(line)
    end
    return entry
end

local function CAI_RebuildChatHistory()
    if not m_caiChatHistory then return end

    local capture = mgr:CaptureFocusKey(m_caiChatHistory)
    m_caiChatHistory:ClearChildren()

    for _, entry in ipairs(m_caiChatEntries) do
        local widget
        if entry.Kind == "pin" then
            widget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIChatPin"), "Button", {
                Label = function() return entry.Label end,
                Tooltip = function() return entry.Tooltip or entry.Label end,
                FocusKey = "chat:" .. tostring(entry.Id),
            })
            widget:SetFocusSound(HOVER_SOUND)
            widget:On("activate", function()
                if entry.HexX ~= nil and entry.HexY ~= nil then
                    UI.LookAtPlot(entry.HexX, entry.HexY)
                end
            end)
        else
            widget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIChatLine"), "StaticText", {
                Label = function() return entry.Label end,
                FocusKey = "chat:" .. tostring(entry.Id),
            })
        end
        m_caiChatHistory:AddChild(widget)
    end

    mgr:RestoreFocus(m_caiChatHistory, capture)
end

local function CAI_GetPlayerEntrySummary(playerID)
    local parts = {}
    local playerEntry = GetPlayerListEntry(playerID)
    local cfg = PlayerConfigurations[playerID]
    if playerEntry ~= nil then
        local name = CAI_ControlText(playerEntry.PlayerName)
        local status = CAI_ControlText(playerEntry.ConnectionLabel)
        if name ~= "" then table.insert(parts, name) end
        if status ~= "" then table.insert(parts, status) end
        if Players[playerID] and Players[playerID]:IsTurnActive() then
            table.insert(parts, Locale.Lookup("LOC_CAI_DIPLO_RIBBON_ACTIVE_TURN"))
        end
    else
        if cfg ~= nil then
            table.insert(parts, CAI_Lookup(cfg:GetSlotName()))
        end
    end
    return CAI_JoinNonEmpty(parts, ", ")
end

local function CAI_GetPlayerEntryTooltip(playerID)
    local playerEntry = GetPlayerListEntry(playerID)
    if playerEntry == nil then return "" end

    return CAI_ControlTooltip(playerEntry.ConnectionIcon)
end

local function CAI_BuildPlayerActionWidgets(playerID, submenu)
    local actions = GetPlayerListPullData() or {}
    local count = 0

    for actionIndex, actionData in ipairs(actions) do
        if actionData.isValidFunction == nil or actionData.isValidFunction(playerID) then
            local child = mgr:CreateWidget(mgr:GenerateWidgetId("CAIChatPlayerAction"), "Button", {
                Label = function() return CAI_Lookup(actionData.name) end,
                Tooltip = function() return CAI_Lookup(actionData.tooltip) end,
                FocusKey = "player:" .. tostring(playerID) .. ":action:" .. tostring(actionIndex),
            })
            child:SetFocusSound(HOVER_SOUND)
            child:On("activate", function()
                OnPlayerListPull(playerID, actionIndex)
            end)
            submenu:AddChild(child)
            count = count + 1
        end
    end

    if count == 0 then
        local noActions = mgr:CreateWidget(mgr:GenerateWidgetId("CAIChatPlayerNoActions"), "StaticText", {
            Label = function() return CAI_Lookup("LOC_CAI_CHAT_PANEL_NO_PLAYER_ACTIONS") end,
            FocusKey = "player:" .. tostring(playerID) .. ":none",
        })
        submenu:AddChild(noActions)
    end
end

local function CAI_RebuildPlayersList(skipVanillaRefresh)
    if not m_caiPlayersList then return end

    if not skipVanillaRefresh and m_vanillaBuildPlayerList then
        m_vanillaBuildPlayerList()
    end

    local capture = mgr:CaptureFocusKey(m_caiPlayersList)
    m_caiPlayersList:ClearChildren()

    for _, playerID in ipairs(GameConfiguration.GetInUsePlayerIDs()) do
        local cfg = PlayerConfigurations[playerID]
        if cfg ~= nil and cfg:IsHuman() and not Network.IsPlayerKicked(playerID) then
            local submenu = mgr:CreateWidget(mgr:GenerateWidgetId("CAIChatPlayer"), "SubMenu", {
                Label = function() return CAI_GetPlayerEntrySummary(playerID) end,
                Tooltip = function() return CAI_GetPlayerEntryTooltip(playerID) end,
                FocusKey = "player:" .. tostring(playerID),
            })
            submenu:SetFocusSound(HOVER_SOUND)
            CAI_BuildPlayerActionWidgets(playerID, submenu)
            m_caiPlayersList:AddChild(submenu)
        elseif cfg ~= nil
            and cfg:GetSlotStatus() == 4
            and GameConfiguration.IsNetworkMultiplayer()
            and Network.IsPlayerConnected(playerID) then
            local submenu = mgr:CreateWidget(mgr:GenerateWidgetId("CAIChatPlayer"), "SubMenu", {
                Label = function() return CAI_GetPlayerEntrySummary(playerID) end,
                Tooltip = function() return CAI_GetPlayerEntryTooltip(playerID) end,
                FocusKey = "player:" .. tostring(playerID),
            })
            submenu:SetFocusSound(HOVER_SOUND)
            CAI_BuildPlayerActionWidgets(playerID, submenu)
            m_caiPlayersList:AddChild(submenu)
        end
    end

    mgr:RestoreFocus(m_caiPlayersList, capture)
end

local function CAI_RemoveKickVoteByTarget(targetPlayerID)
    for i = #m_caiKickVotes, 1, -1 do
        if m_caiKickVotes[i].TargetPlayerID == targetPlayerID then
            table.remove(m_caiKickVotes, i)
        end
    end
end

local function CAI_RemoveKickVoteDialog()
    if mgr and m_caiKickVoteDialog then
        mgr:RemoveFromStack(KICK_DIALOG_ID)
        m_caiKickVoteDialog = nil
    end
end

local function CAI_BuildKickVoteDialog()
    CAI_RemoveKickVoteDialog()

    if mgr == nil or #m_caiKickVotes == 0 then return end

    local currentVote = m_caiKickVotes[1]
    local title = currentVote.Title
    local contentRows = {}

    if currentVote.ReasonText ~= nil and currentVote.ReasonText ~= "" then
        table.insert(contentRows, mgr:CreateWidget(mgr:GenerateWidgetId("CAIChatKickReason"), "StaticText", {
            Label = function() return currentVote.ReasonText end,
        }))
    end

    local yesButton = mgr:CreateWidget(mgr:GenerateWidgetId("CAIChatKickYes"), "Button", {
        Label = function() return CAI_Lookup("LOC_POPUP_YES") end,
        Tooltip = function() return CAI_Lookup("LOC_KICK_VOTE_YES_BUTTON_TOOLTIP", currentVote.PlayerName) end,
    })
    yesButton:On("activate", function()
        CAI_RemoveKickVoteByTarget(currentVote.TargetPlayerID)
        CAI_RemoveKickVoteDialog()
        Network.KickVote(currentVote.TargetPlayerID, true)
        CAI_BuildKickVoteDialog()
    end)

    local noButton = mgr:CreateWidget(mgr:GenerateWidgetId("CAIChatKickNo"), "Button", {
        Label = function() return CAI_Lookup("LOC_POPUP_NO") end,
        Tooltip = function() return CAI_Lookup("LOC_KICK_VOTE_NO_BUTTON_TOOLTIP", currentVote.PlayerName) end,
    })
    noButton:On("activate", function()
        CAI_RemoveKickVoteByTarget(currentVote.TargetPlayerID)
        CAI_RemoveKickVoteDialog()
        Network.KickVote(currentVote.TargetPlayerID, false)
        CAI_BuildKickVoteDialog()
    end)

    m_caiKickVoteDialog = mgr.WidgetHelpers.MakeGeneralDialog(
        function() return title end,
        { yesButton, noButton },
        contentRows,
        1
    )

    if m_caiKickVoteDialog then
        m_caiKickVoteDialog.Id = KICK_DIALOG_ID
        mgr:Push(m_caiKickVoteDialog, { priority = PopupPriority.Current })
    end
end

local function CAI_RecordIncomingChat(fromPlayer, toPlayer, text, eTargetType, appendToBuffer)
    local prefix = CAI_MakeChatPrefix(fromPlayer, toPlayer, eTargetType)
    if prefix == nil or prefix == "" then return nil end

    if string.find(text, "%[pin:%d+,%d+%]") then
        local pinStr = string.sub(text, string.find(text, "%[pin:%d+,%d+%]"))
        local pinPlayerIDStr = string.sub(pinStr, string.find(pinStr, "%d+"))
        local comma = string.find(pinStr, ",")
        local pinIDStr = string.sub(pinStr, string.find(pinStr, "%d+", comma))
        local pinPlayerID = tonumber(pinPlayerIDStr)
        local pinID = tonumber(pinIDStr)
        if pinPlayerID ~= nil and pinID ~= nil and GetMapPinConfig(pinPlayerID, pinID) ~= nil then
            return CAI_RecordPinEntry(prefix, pinPlayerID, pinID, appendToBuffer)
        end
    end

    local parsedText = ParseChatText(text)
    local line = CAI_Lookup("LOC_CAI_STAGING_CHAT_LINE", prefix, parsedText)
    return CAI_RecordTextEntry(line, appendToBuffer)
end

local function CAI_SendChat(text)
    if text == nil then return end
    if string.len(text) > 0 then
        local parsedText
        local chatTargetChanged = false
        local printHelp = false

        parsedText, chatTargetChanged, printHelp = ParseInputChatString(text, m_caiPlayerTarget)
        if chatTargetChanged then
            CAI_UpdateVanillaTargetState()
            CAI_SyncChatTargetSelection()
        end

        if printHelp then
            ChatPrintHelp(Controls.ChatEntryStack, m_caiVisualChatInstances, Controls.ChatLogPanel)
        end

        if parsedText ~= "" then
            local chatTarget = {}
            PlayerTargetToChatTarget(m_caiPlayerTarget, chatTarget)
            Network.SendChat(parsedText, chatTarget.targetType, chatTarget.targetID)
            UI.PlaySound("Play_MP_Chat_Message_Sent")
        end
    end

    Controls.ChatEntry:ClearString()
end

local function CAI_RebuildAllPanelData()
    CAI_RebuildChatTarget()
    CAI_RebuildChatHistory()
    CAI_RebuildPlayersList()
end

local function CAI_BuildPanel()
    m_caiPanel = mgr:CreateWidget(CHAT_PANEL_ROOT_ID, "Panel", {
        Label = function() return CAI_Lookup("LOC_CAI_CHAT_PANEL_TITLE") end,
    })

    m_caiChatInput = mgr:CreateWidget("CAIChatPanel_Input", "EditBox", {
        Label = function() return CAI_Lookup("LOC_CAI_ENDGAME_CHAT_INPUT") end,
        Tooltip = CAI_GetChatInputTooltip,
        AlwaysEdit = true,
        CommitOnFocusLeave = false,
        HighlightOnEdit = true,
        EnterToCommit = true,
        MaxCharacters = 250,
        DisabledPredicate = function() return not CAI_CanUseRealtimeChat() or CAI_IsDisabled(Controls.ChatEntry) end,
        FocusKey = "chat:input",
    })
    m_caiChatInput:SetValueSetter(function(widget, text)
        if text and text ~= "" then
            CAI_SendChat(text)
            widget:SetText("", true)
        end
    end)
    m_caiPanel:AddChild(m_caiChatInput)

    m_caiChatTarget = mgr:CreateWidget("CAIChatPanel_Target", "Dropdown", {
        Label = function() return CAI_Lookup("LOC_CAI_STAGING_CHAT_TARGET") end,
        DisabledPredicate = function() return not CAI_CanUseRealtimeChat() end,
        FocusKey = "chat:target",
    })
    m_caiChatTarget:SetFocusSound(HOVER_SOUND)
    m_caiChatTarget:SetValueSetter(function(_, target)
        if target then
            m_caiPlayerTarget.targetType = target.targetType
            m_caiPlayerTarget.targetID = target.targetID
            CAI_UpdateVanillaTargetState()
            CAI_RebuildChatTarget()
        end
    end)
    m_caiPanel:AddChild(m_caiChatTarget)

    m_caiChatHistory = mgr:CreateWidget(CHAT_HISTORY_ID, "List", {
        Label = function() return CAI_Lookup("LOC_CAI_ENDGAME_CHAT_HISTORY") end,
        FocusKey = "chat:history",
    })
    m_caiPanel:AddChild(m_caiChatHistory)

    m_caiPlayersList = mgr:CreateWidget(CHAT_PLAYERS_ID, "List", {
        Label = function() return CAI_Lookup("LOC_CAI_CHAT_PANEL_PLAYERS") end,
        FocusKey = "players",
    })
    m_caiPanel:AddChild(m_caiPlayersList)
end

local function CAI_PushPanel()
    if mgr == nil or not CAI_CanUseRealtimeChat() then return end

    CAI_RequestWorldTrackerShowChat()

    if m_caiPanel == nil then
        CAI_BuildPanel()
    end

    CAI_RebuildAllPanelData()

    if mgr:GetWidgetById(CHAT_PANEL_ROOT_ID) then
        if m_caiChatInput then
            mgr:SetFocus(m_caiChatInput)
        end
        return
    end

    mgr:Push(m_caiPanel, {
        focus = "chat:input",
    })
end

local function CAI_PopPanel()
    if mgr then
        CAI_RemoveKickVoteDialog()
        mgr:RemoveFromStack(CHAT_PANEL_ROOT_ID)
    end
    m_caiPanel = nil
    m_caiChatInput = nil
    m_caiChatTarget = nil
    m_caiChatHistory = nil
    m_caiPlayersList = nil
end

local function CAI_OnInputActionStarted(actionId)
    if actionId ~= ACTION_OPEN_CHAT_PANEL then return end
    if not CAI_CanUseRealtimeChat() then
        Speak(Locale.Lookup("LOC_CAI_UI_CHAT_NETWORK_ONLY"))
        return
    end
    CAI_PushPanel()
end

local function CAI_HandleInput(input)
    if mgr and (mgr:GetWidgetById(CHAT_PANEL_ROOT_ID) or mgr:GetWidgetById(KICK_DIALOG_ID)) then
        if mgr:HandleInput(input) then
            return true
        end
    end

    if input:GetMessageType() == KeyEvents.KeyUp and input:GetKey() == Keys.VK_ESCAPE then
        if mgr and mgr:GetTop() and mgr:GetTop():GetId() == KICK_DIALOG_ID then
            CAI_RemoveKickVoteDialog()
            return true
        end
        if mgr and mgr:GetTop() and mgr:GetTop():GetId() == CHAT_PANEL_ROOT_ID then
            CAI_PopPanel()
            return true
        end
    end

    if m_vanillaInputHandler then
        return m_vanillaInputHandler(input)
    end

    return false
end

local function CAI_OnMapPinPopupRequestTarget()
    CAI_UpdateVanillaTargetState()
end

local function CAI_OnMapPinPopupSendPin(playerID, pinID)
    local mapPinStr = "[pin:" .. tostring(playerID) .. "," .. tostring(pinID) .. "]"
    CAI_SendChat(mapPinStr)
end

local function CAI_OnPlayerInfoChanged(playerID)
    ValidatePlayerTarget(m_caiPlayerTarget)
    CAI_UpdateVanillaTargetState()
    CAI_RebuildChatTarget()
    CAI_RebuildPlayersList()
end

local function CAI_OnPingTimesChanged()
    CAI_RebuildPlayersList()
end

local function CAI_OnKickVoteStarted(targetPlayerID, fromPlayerID, reason)
    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID ~= targetPlayerID and localPlayerID ~= fromPlayerID then
        CAI_RemoveKickVoteByTarget(targetPlayerID)

        local playerConfig = PlayerConfigurations[targetPlayerID]
        local playerName = playerConfig and CAI_Lookup(playerConfig:GetPlayerName()) or
            CAI_Lookup("LOC_TOOLTIP_PLAYER_ID", targetPlayerID)
        local reasonText = CAI_KICKVOTE_REASONS[reason] and CAI_Lookup(CAI_KICKVOTE_REASONS[reason]) or ""

        table.insert(m_caiKickVotes, {
            TargetPlayerID = targetPlayerID,
            PlayerName = playerName,
            Title = CAI_Lookup("LOC_KICK_VOTE_LABEL", playerName),
            ReasonText = reasonText,
        })
        CAI_BuildKickVoteDialog()
    end
end

local function CAI_OnKickVoteComplete(targetPlayerID)
    CAI_RemoveKickVoteByTarget(targetPlayerID)
    CAI_BuildKickVoteDialog()
    CAI_RebuildPlayersList()
end

OnChat = WrapFunc(OnChat, function(orig, fromPlayer, toPlayer, text, eTargetType, playSounds)
    local result = orig(fromPlayer, toPlayer, text, eTargetType, playSounds)
    CAI_RecordIncomingChat(fromPlayer, toPlayer, text, eTargetType, true)
    CAI_RebuildChatHistory()
    return result
end)

OnKickVoteStarted = WrapFunc(OnKickVoteStarted, function(orig, targetPlayerID, fromPlayerID, reason)
    local result = orig(targetPlayerID, fromPlayerID, reason)

    local playerConfig = PlayerConfigurations[targetPlayerID]
    local playerName = playerConfig and playerConfig:GetPlayerName() or
        CAI_Lookup("LOC_TOOLTIP_PLAYER_ID", targetPlayerID)
    local reasonText = CAI_KICKVOTE_REASONS[reason] and CAI_Lookup(CAI_KICKVOTE_REASONS[reason]) or ""
    local text = CAI_Lookup("LOC_KICK_VOTE_STARTED_CHAT_ENTRY", playerName, reasonText)
    CAI_RecordTextEntry(text, true)
    CAI_RebuildChatHistory()

    CAI_OnKickVoteStarted(targetPlayerID, fromPlayerID, reason)
    return result
end)

OnKickVoteComplete = WrapFunc(OnKickVoteComplete, function(orig, targetPlayerID, kickResult)
    local result = orig(targetPlayerID, kickResult)

    local playerConfig = PlayerConfigurations[targetPlayerID]
    local playerName = playerConfig and playerConfig:GetPlayerName() or
        CAI_Lookup("LOC_TOOLTIP_PLAYER_ID", targetPlayerID)
    local locKey = "LOC_KICK_VOTE_FAILED_CHAT_ENTRY"
    if kickResult == KickVoteResultType.KICKVOTERESULT_VOTE_PASSED then
        locKey = "LOC_KICK_VOTE_SUCCEEDED_CHAT_ENTRY"
    elseif kickResult == KickVoteResultType.KICKVOTERESULT_TIME_ELAPSED then
        locKey = "LOC_KICK_VOTE_TIME_ELAPSED_CHAT_ENTRY"
    elseif kickResult == KickVoteResultType.KICKVOTERESULT_NOT_ENOUGH_PLAYERS then
        locKey = "LOC_KICK_VOTE_NOT_ENOUGH_PLAYERS_CHAT_ENTRY"
    end

    CAI_RecordTextEntry(CAI_Lookup(locKey, playerName), true)
    CAI_RebuildChatHistory()

    CAI_OnKickVoteComplete(targetPlayerID)
    return result
end)

ChatPrintHelp = WrapFunc(ChatPrintHelp, function(orig, ...)
    local result = orig(...)
    local helpText = CAI_Lookup("LOC_CHAT_HELP_COMMAND_TEXT")
    CAI_RecordTextEntry(helpText, true)
    CAI_RebuildChatHistory()
    return result
end)

BuildPlayerList = WrapFunc(BuildPlayerList, function(orig, ...)
    local result = orig(...)
    CAI_RebuildPlayersList(true)
    return result
end)

Controls.ChatEntry:RegisterCommitCallback(CAI_SendChat)
CAI_UpdateVanillaTargetState()
ContextPtr:SetInputHandler(CAI_HandleInput, true)
Events.InputActionStarted.Add(CAI_OnInputActionStarted)
Events.PlayerInfoChanged.Add(CAI_OnPlayerInfoChanged)
Events.MultiplayerPingTimesChanged.Add(CAI_OnPingTimesChanged)
Events.KickVoteStarted.Remove(m_vanillaKickVoteStarted)
Events.KickVoteStarted.Add(OnKickVoteStarted)
Events.KickVoteComplete.Remove(m_vanillaKickVoteComplete)
Events.KickVoteComplete.Add(OnKickVoteComplete)
LuaEvents.MapPinPopup_SendPinToChat.Remove(m_vanillaMapPinSendHandler)
LuaEvents.MapPinPopup_SendPinToChat.Add(CAI_OnMapPinPopupSendPin)
LuaEvents.MapPinPopup_RequestChatPlayerTarget.Remove(m_vanillaMapPinTargetRequestHandler)
LuaEvents.MapPinPopup_RequestChatPlayerTarget.Add(CAI_OnMapPinPopupRequestTarget)

OnShutdown = WrapFunc(OnShutdown, function(orig)
    Events.InputActionStarted.Remove(CAI_OnInputActionStarted)
    Events.PlayerInfoChanged.Remove(CAI_OnPlayerInfoChanged)
    Events.MultiplayerPingTimesChanged.Remove(CAI_OnPingTimesChanged)
    Events.KickVoteStarted.Remove(OnKickVoteStarted)
    Events.KickVoteComplete.Remove(OnKickVoteComplete)
    LuaEvents.MapPinPopup_SendPinToChat.Remove(CAI_OnMapPinPopupSendPin)
    LuaEvents.MapPinPopup_RequestChatPlayerTarget.Remove(CAI_OnMapPinPopupRequestTarget)
    CAI_PopPanel()
    orig()
end)
ContextPtr:SetShutdown(OnShutdown)
