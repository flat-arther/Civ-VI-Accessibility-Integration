include("caiUtils")

local mgr                              = ExposedMembers.CAI_UIManager

local NOTIFICATION_CENTER_ID           = "CAINotificationCenter_Panel"
local NOTIFICATION_TABS_ID             = "CAINotificationCenter_Tabs"
local NOTIFICATION_TREE_ID             = "CAINotificationCenter_Tree"
local EMPTY_NODE_ID                    = "CAINotificationCenter_Empty"
local GROUP_ID_PREFIX                  = "CAINotificationCenter_Group_"
local LEAF_ID_PREFIX                   = "CAINotificationCenter_Leaf_"
local MESSAGE_FILTER_ID                = "CAINotificationCenter_MessageFilter"
local MESSAGE_COPY_ID                  = "CAINotificationCenter_MessageCopy"
local MESSAGE_LIST_ID                  = "CAINotificationCenter_MessageList"
local MESSAGE_EMPTY_ID                 = "CAINotificationCenter_MessageEmpty"
local MESSAGE_ID_PREFIX                = "CAINotificationCenter_Message_"
local m_IsGameStarted                  = false
local ACTION_OPEN_NOTIFICATION_CENTER  = Input.GetActionId("UI_NotificationPanelOpenList")
local CAI_TUTORIAL_GOAL_ADDED_TYPE     = DB.MakeHash("NOTIFICATION_CAI_TUTORIAL_GOAL_ADDED")
local CAI_TUTORIAL_GOAL_COMPLETED_TYPE = DB.MakeHash("NOTIFICATION_CAI_TUTORIAL_GOAL_COMPLETED")
local DEFAULT_NOTIFICATION_SOUND       = "ALERT_NEUTRAL"
local DEFAULT_SOUND_EXCLUDED_TYPES     = {
    [NotificationTypes.PLAYER_MET] = true,
}

local m_centerPanel                    = nil ---@type PanelWidget|nil
local m_centerTree                     = nil ---@type TreeWidget|nil
local m_messageList                    = nil ---@type ListWidget|nil
local m_caiAnnouncedNotificationIDs    = {}
local m_caiDeferedNotificationAnnounce = {}

local function GetLocalPlayer()
    local playerID = Game.GetLocalPlayer()
    if playerID == nil or playerID < 0 then return nil end
    return playerID
end

RegisterHandlers = WrapFunc(RegisterHandlers, function(orig)
    orig()
    g_notificationHandlers[CAI_TUTORIAL_GOAL_ADDED_TYPE]              = MakeDefaultHandlers()
    g_notificationHandlers[CAI_TUTORIAL_GOAL_COMPLETED_TYPE]          = MakeDefaultHandlers()
    g_notificationHandlers[CAI_TUTORIAL_GOAL_ADDED_TYPE].Activate     = OnCAITutorialGoalNotificationActivate
    g_notificationHandlers[CAI_TUTORIAL_GOAL_COMPLETED_TYPE].Activate = OnCAITutorialGoalNotificationActivate
end)

-- Vanilla naming is reversed from CAI usage:
--   notification:GetMessage() -> short title / headline ("Tech boost")
--   notification:GetSummary() -> long content text ("Bronze Working boosted ...")
local function NotificationTitle(notification)
    if not notification then return "" end
    local t = notification:GetMessage()
    if t and t ~= "" then return Locale.Lookup(t) end
    return notification:GetTypeName() or ""
end

local function NotificationContent(notification)
    if not notification then return "" end
    local c = notification:GetSummary()
    if c and c ~= "" then return Locale.Lookup(c) end
    return ""
end

local function GetVanillaNotificationEntry(playerID, notificationID)
    if GetNotificationEntry == nil then return nil end
    return GetNotificationEntry(playerID, notificationID)
end

local function IsNotificationInVanillaRail(playerID, notificationID)
    local notificationEntry = GetVanillaNotificationEntry(playerID, notificationID)
    return notificationEntry ~= nil and notificationEntry.m_Instance ~= nil
end

local function IsNotificationAvailable(notification, notificationID, playerID)
    if not notification or not notification:IsVisibleInUI() then return false end
    if playerID ~= nil and notificationID ~= nil and not IsNotificationInVanillaRail(playerID, notificationID) then return false end
    if notification.IsDismissed and notification:IsDismissed() then return false end
    if notification.IsExpired and notification:IsExpired() then return false end
    return true
end

local function GetLiveNotification(playerID, notificationID)
    if not playerID or not notificationID then return nil end
    return NotificationManager.Find(playerID, notificationID)
end

local function GetNotificationTypeName(notification)
    if not notification then return nil end
    return notification:GetTypeName() or tostring(notification:GetType())
end

local function BuildNotificationGroups(playerID)
    local groups = {}
    local groupOrder = {}
    local ids = NotificationManager.GetList(playerID) or {}

    for _, notificationID in ipairs(ids) do
        local notification = GetLiveNotification(playerID, notificationID)
        if IsNotificationAvailable(notification, notificationID, playerID) then
            local typeName = GetNotificationTypeName(notification)
            if groups[typeName] == nil then
                groups[typeName] = {
                    TypeName      = typeName,
                    Notifications = {},
                }
                table.insert(groupOrder, groups[typeName])
            end
            table.insert(groups[typeName].Notifications, notificationID)
        end
    end

    return groupOrder
end

local function SpeakUnavailable()
    Speak(Locale.Lookup("LOC_CAI_NOTIFICATION_UNAVAILABLE"))
end

local function CloseNotificationCenter()
    m_centerPanel = nil
    m_centerTree = nil
    m_messageList = nil
    if mgr then mgr:RemoveFromStack(NOTIFICATION_CENTER_ID) end
end

LookAtNotification = WrapFunc(LookAtNotification, function(orig, pNotification)
    orig(pNotification)
    if m_centerPanel then return end
    if pNotification and pNotification:IsLocationValid() then
        local x, y = pNotification:GetLocation()
        local plot = Map.GetPlot(x, y)
        if plot then
            LuaEvents.CAICursorMoveTo(plot:GetIndex(), "jump")
        end
    end
end)

function OnCAITutorialGoalNotificationActivate(notificationEntry, notificationID, activatedByUser)
    if notificationEntry == nil or notificationEntry.m_PlayerID ~= Game.GetLocalPlayer() then return end

    local notification = GetActiveNotificationFromEntry(notificationEntry, notificationID)
    if notification == nil then return end

    LookAtNotification(notification)
    LuaEvents.CAI_TutorialGoalNotificationActivate(notification:GetPlayerID(), notification:GetID(), activatedByUser)
end

local function ActivateNotification(playerID, notificationID)
    local notification = GetLiveNotification(playerID, notificationID)
    if not IsNotificationAvailable(notification, notificationID, playerID) then
        SpeakUnavailable()
        return true
    end

    if not notification:IsValidForPhase() then
        Speak(Locale.Lookup("LOC_NOTIFICATION_WRONG_PHASE_TT", NotificationTitle(notification)))
        return true
    end

    CloseNotificationCenter()

    -- Mirror vanilla rail left-click: route through the registered TryActivate
    -- handler so Events.NotificationActivated dispatches to the right Activate.
    local notificationEntry = GetVanillaNotificationEntry(playerID, notificationID)
    if notificationEntry and notificationEntry.m_kHandlers and notificationEntry.m_kHandlers.TryActivate then
        notificationEntry.m_kHandlers.TryActivate(notificationEntry)
    else
        notification:Activate(true)
    end
    return true
end

local function DismissNotification(playerID, notificationID)
    local notification = GetLiveNotification(playerID, notificationID)
    if not IsNotificationAvailable(notification, notificationID, playerID) then
        SpeakUnavailable()
        return true
    end

    if notification:CanUserDismiss() then
        local notificationEntry = GetVanillaNotificationEntry(playerID, notificationID)
        if notificationEntry and notificationEntry.m_kHandlers and notificationEntry.m_kHandlers.TryDismiss then
            notificationEntry.m_kHandlers.TryDismiss(notificationEntry)
        else
            NotificationManager.Dismiss(playerID, notificationID)
        end
        Speak(Locale.Lookup("LOC_CAI_NOTIFICATION_DISMISSED"))
    else
        Speak(Locale.Lookup("LOC_CAI_NOTIFICATION_CANNOT_DISMISS"))
    end
    return true
end

local function DismissNotificationGroup(playerID, group)
    if not group or not group.Notifications then return true end

    local dismissed = 0
    for _, notificationID in ipairs(group.Notifications) do
        local notification = GetLiveNotification(playerID, notificationID)
        if IsNotificationAvailable(notification, notificationID, playerID) and notification:CanUserDismiss() then
            NotificationManager.Dismiss(playerID, notificationID)
            dismissed = dismissed + 1
        end
    end

    if dismissed > 0 then
        Speak(Locale.Lookup("LOC_CAI_NOTIFICATION_GROUP_DISMISSED", dismissed))
    else
        Speak(Locale.Lookup("LOC_CAI_NOTIFICATION_CANNOT_DISMISS"))
    end
    return true
end

local function BuildLeafTooltip(playerID, notificationID)
    return function()
        local notification = GetLiveNotification(playerID, notificationID)
        if not IsNotificationAvailable(notification, notificationID, playerID) then
            return Locale.Lookup("LOC_CAI_NOTIFICATION_UNAVAILABLE")
        end

        local parts = {}
        if not notification:IsValidForPhase() then
            table.insert(parts, Locale.Lookup("LOC_CAI_NOTIFICATION_WRONG_PHASE"))
        end
        if notification:CanUserDismiss() then
            table.insert(parts, Locale.Lookup("LOC_CAI_NOTIFICATION_DISMISSIBLE"))
        end
        if notification:AutoExpires() then
            local expireTurn = notification:GetExpireTurn()
            if expireTurn ~= nil and expireTurn >= 0 then
                table.insert(parts, Locale.Lookup("LOC_CAI_NOTIFICATION_EXPIRES_TURN", expireTurn))
            end
        end
        return table.concat(parts, "[NEWLINE]")
    end
end

local function CreateLeafWidget(playerID, notificationID)
    local leaf = mgr:CreateWidget(LEAF_ID_PREFIX .. tostring(notificationID), "TreeItem", {
        Label    = function()
            local notification = GetLiveNotification(playerID, notificationID)
            if not IsNotificationAvailable(notification, notificationID, playerID) then
                return Locale.Lookup("LOC_CAI_NOTIFICATION_UNAVAILABLE")
            end
            local content = NotificationContent(notification)
            if content ~= "" then return content end
            return NotificationTitle(notification)
        end,
        Tooltip  = BuildLeafTooltip(playerID, notificationID),
        FocusKey = "notification:" .. tostring(notificationID),
    })

    leaf:On("activate", function() ActivateNotification(playerID, notificationID) end)
    leaf:AddInputBindings({
        {
            Key         = Keys.VK_SPACE,
            MSG         = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_ACTIVATE_NOTIFICATION",
            Action      = function() return ActivateNotification(playerID, notificationID) end,
        },
        {
            Key         = Keys.VK_DELETE,
            MSG         = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_DISMISS_NOTIFICATION",
            Action      = function() return DismissNotification(playerID, notificationID) end,
        },
    })

    return leaf
end

local function CreateGroupWidget(playerID, group)
    local groupNode = mgr:CreateWidget(GROUP_ID_PREFIX .. group.TypeName, "TreeItem", {
        Label    = function()
            for _, notificationID in ipairs(group.Notifications) do
                local notification = GetLiveNotification(playerID, notificationID)
                if IsNotificationAvailable(notification, notificationID, playerID) then
                    return NotificationTitle(notification)
                end
            end
            return Locale.Lookup("LOC_CAI_NOTIFICATION_UNAVAILABLE")
        end,
        Tooltip  = function()
            return Locale.Lookup("LOC_CAI_NOTIFICATION_GROUP_COUNT", #group.Notifications)
        end,
        FocusKey = "group:" .. tostring(group.TypeName),
    })

    groupNode:AddInputBinding({
        Key         = Keys.VK_DELETE,
        MSG         = KeyEvents.KeyUp,
        Description = "LOC_CAI_KB_DISMISS_STACK",
        Action      = function() return DismissNotificationGroup(playerID, group) end,
    })

    for idx, notificationID in ipairs(group.Notifications) do
        groupNode:AddChild(CreateLeafWidget(playerID, notificationID))
    end

    return groupNode
end

local function AddEmptyNode(tree)
    tree:AddChild(mgr:CreateWidget(EMPTY_NODE_ID, "TreeItem", {
        Label    = function() return Locale.Lookup("LOC_CAI_NOTIFICATION_EMPTY") end,
        FocusKey = "empty",
    }))
end

local function PopulateTree(tree, playerID)
    local groups = BuildNotificationGroups(playerID)
    if #groups == 0 then
        AddEmptyNode(tree)
        return nil
    end
    local lastLeafKey = nil
    for _, group in ipairs(groups) do
        if #group.Notifications == 1 then
            tree:AddChild(CreateLeafWidget(playerID, group.Notifications[1]))
            lastLeafKey = "notification:" .. tostring(group.Notifications[1])
        else
            tree:AddChild(CreateGroupWidget(playerID, group))
            local lastInGroup = group.Notifications[#group.Notifications]
            lastLeafKey = "notification:" .. tostring(lastInGroup)
        end
    end
    return lastLeafKey
end

local function RebuildNotificationTree()
    if not m_centerTree then return end
    local playerID = GetLocalPlayer()
    if not playerID then return end

    local capture = mgr:CaptureFocusKey(m_centerTree)
    m_centerTree:ClearChildren()
    PopulateTree(m_centerTree, playerID)
    mgr:RestoreFocus(m_centerTree, capture)
end

local function GetMessageBuffer()
    if not CAI or not CAI.GetMessageBuffer then
        LogError("NotificationPanel: message buffer getter is unavailable")
        return nil
    end
    return CAI.GetMessageBuffer()
end

local function FormatMessageTurn(turn)
    return Locale.Lookup("LOC_CAI_MESSAGE_BUFFER_TURN", turn)
end

local function FormatMessageEntry(buffer, entry, includeLocation)
    local turnText = FormatMessageTurn(entry.turn)
    if includeLocation then
        local locationText = buffer:GetEntryLocationText(entry)
        if locationText and locationText ~= "" then
            return Locale.Lookup(
                "LOC_CAI_MESSAGE_BUFFER_LIST_ENTRY_WITH_LOCATION",
                entry.text,
                locationText,
                turnText
            )
        end
    end
    return Locale.Lookup("LOC_CAI_MESSAGE_BUFFER_LIST_ENTRY", entry.text, turnText)
end

local function BuildMessageTooltip(entry)
    return Locale.Lookup("LOC_CAI_MESSAGE_BUFFER_CAT_" .. string.upper(entry.category))
end

local function ActivateMessageLocation(buffer, entry)
    CloseNotificationCenter()
    buffer:JumpToEntryLocation(entry)
    return true
end

local function PopulateMessageList(list, buffer)
    local entries = buffer:GetEntries()
    if #entries == 0 then
        list:AddChild(mgr:CreateWidget(MESSAGE_EMPTY_ID, "StaticText", {
            Label = function() return Locale.Lookup("LOC_CAI_MESSAGE_BUFFER_EMPTY") end,
            FocusKey = "message:empty",
        }))
        return
    end

    for _, entry in ipairs(entries) do
        local messageEntry = entry
        local hasLocation = messageEntry.location ~= nil
            and messageEntry.location.x ~= nil
            and messageEntry.location.y ~= nil
        local widgetType = hasLocation and "Button" or "StaticText"
        local row = mgr:CreateWidget(MESSAGE_ID_PREFIX .. tostring(messageEntry.id), widgetType, {
            Label = function() return FormatMessageEntry(buffer, messageEntry, true) end,
            Tooltip = function() return BuildMessageTooltip(messageEntry) end,
            FocusKey = "message:" .. tostring(messageEntry.id),
        })
        if hasLocation then
            row:On("activate", function() return ActivateMessageLocation(buffer, messageEntry) end)
        end
        list:AddChild(row)
    end
    list:SetDefaultIndex(#list.Children)
end

local function RebuildMessageList()
    if not m_messageList then return end
    local buffer = GetMessageBuffer()
    if not buffer then return end

    local capture = mgr:CaptureFocusKey(m_messageList)
    m_messageList:ClearChildren()
    PopulateMessageList(m_messageList, buffer)
    mgr:RestoreFocus(m_messageList, capture)
end

local function CreateMessageFilter(buffer)
    local dropdown = mgr:CreateWidget(MESSAGE_FILTER_ID, "Dropdown", {
        Label = function() return Locale.Lookup("LOC_CAI_MESSAGE_BUFFER_FILTER") end,
    })
    local options = {}
    local selectedIndex = 1
    for i, category in ipairs(buffer.GetCategories()) do
        options[i] = {
            label = Locale.Lookup("LOC_CAI_MESSAGE_BUFFER_CAT_" .. string.upper(category)),
            value = category,
        }
        if category == buffer:GetFilter() then selectedIndex = i end
    end
    dropdown:SetOptions(options)
    dropdown:SetSelectedIndex(selectedIndex, true)
    dropdown:SetValueSetter(function(_, category)
        buffer:SetFilter(category)
        RebuildMessageList()
    end)
    return dropdown
end

local function CopyMessageBuffer(buffer)
    local lines = {}
    for _, entry in ipairs(buffer:GetEntries()) do
        local line = FormatMessageEntry(buffer, entry, false):gsub("%[NEWLINE%]", "\r\n")
        table.insert(lines, ProcessIcons(line))
    end
    UIManager:SetClipboardString(table.concat(lines, "\r\n"))
    Speak(Locale.Lookup("LOC_CAI_MESSAGE_BUFFER_COPIED"))
    return true
end

local function CreateCopyBufferButton(buffer)
    local button = mgr:CreateWidget(MESSAGE_COPY_ID, "Button", {
        Label = function() return Locale.Lookup("LOC_CAI_MESSAGE_BUFFER_COPY") end,
        Tooltip = function() return Locale.Lookup("LOC_CAI_MESSAGE_BUFFER_COPY_TOOLTIP") end,
        DisabledPredicate = function() return #buffer:GetEntries() == 0 end,
    })
    button:On("activate", function() return CopyMessageBuffer(buffer) end)
    return button
end

local function OpenNotificationCenter()
    if not mgr then return end
    CloseNotificationCenter()

    local playerID = GetLocalPlayer()
    if not playerID then
        Speak(Locale.Lookup("LOC_CAI_NOTIFICATION_UNAVAILABLE"))
        return
    end

    local panel = mgr:CreateWidget(NOTIFICATION_CENTER_ID, "Panel", {
        Label = function() return Locale.Lookup("LOC_CAI_NOTIFICATION_CENTER") end,
    })
    panel:AddInputBinding({
        Key         = Keys.VK_ESCAPE,
        MSG         = KeyEvents.KeyUp,
        Description = "LOC_CAI_KB_CLOSE",
        Action      = function()
            CloseNotificationCenter()
            return true
        end,
    })

    local tabs = mgr:CreateWidget(NOTIFICATION_TABS_ID, "TabControl", {})
    local notificationsPage = tabs:AddPage(function()
        return Locale.Lookup("LOC_CAI_MESSAGE_BUFFER_CAT_NOTIFICATION")
    end)
    local tree = mgr:CreateWidget(NOTIFICATION_TREE_ID, "Tree", {})
    notificationsPage:AddChild(tree)
    local latestKey = PopulateTree(tree, playerID)

    local messagesPage = tabs:AddPage(function()
        return Locale.Lookup("LOC_CAI_MESSAGE_BUFFER")
    end)
    local buffer = GetMessageBuffer()
    if buffer then
        local messageList = mgr:CreateWidget(MESSAGE_LIST_ID, "List", {})
        messagesPage:AddChild(messageList)
        PopulateMessageList(messageList, buffer)
        m_messageList = messageList
        messagesPage:AddChild(CreateMessageFilter(buffer))
        messagesPage:AddChild(CreateCopyBufferButton(buffer))
    else
        messagesPage:AddChild(mgr:CreateWidget(MESSAGE_EMPTY_ID, "StaticText", {
            Label = function() return Locale.Lookup("LOC_CAI_MESSAGE_BUFFER_EMPTY") end,
        }))
    end

    panel:AddChild(tabs)
    m_centerPanel = panel
    m_centerTree = tree
    mgr:Push(panel, latestKey and { focus = latestKey } or nil)
end


local function DeferNotification(playerID, notificationID)
    if playerID and notificationID then
        table.insert(m_caiDeferedNotificationAnnounce, { pId = playerID, Id = notificationID })
    end
end

local function SpeakNotificationAdded(playerID, notificationID)
    if ContextPtr:IsHidden() then return end
    if playerID ~= GetLocalPlayer() then return end
    if m_caiAnnouncedNotificationIDs[notificationID] then return end
    if not m_IsGameStarted then
        DeferNotification(playerID, notificationID)
        return
    end
    local notification = GetLiveNotification(playerID, notificationID)
    if not IsNotificationAvailable(notification, notificationID, playerID) then return end
    m_caiAnnouncedNotificationIDs[notificationID] = true

    local content = NotificationContent(notification)
    if content == "" then content = NotificationTitle(notification) end
    local notificationType = notification:GetType()
    local line
    if notificationType == CAI_TUTORIAL_GOAL_ADDED_TYPE then
        line = Locale.Lookup("LOC_CAI_TUTORIAL_GOAL_ADDED_ALERT", content)
    elseif notificationType == CAI_TUTORIAL_GOAL_COMPLETED_TYPE then
        line = Locale.Lookup("LOC_CAI_TUTORIAL_GOAL_COMPLETED_ALERT", content)
    else
        line = Locale.Lookup("LOC_CAI_NOTIFICATION_ALERT", content)
    end
    local x, y
    if notification:IsLocationValid() then
        x, y = notification:GetLocation()
    elseif notification:IsTargetValid() then
        local targetPlayerID, targetID, targetType = notification:GetTarget()
        if targetType == PlayerComponentTypes.UNIT then
            local pUnit = Players[targetPlayerID]:GetUnits():FindID(targetID) ---@type Unit
            if pUnit ~= nil then
                x, y = pUnit:GetLocation()
            end
        elseif targetType == PlayerComponentTypes.CITY then
            local pCity = Players[targetPlayerID]:GetCities():FindID(targetID)
            if pCity ~= nil then
                x, y = pCity:GetLocation()
            end
        end
    end
    local location
    if x and y then location = { x = x, y = y } end
    LuaEvents.CAIAppendToMessageBuffer(line, "notification", location)
end

local function PlayDefaultNotificationSound(playerID, notificationID)
    if playerID ~= GetLocalPlayer() then return end
    if not m_IsGameStarted then return end

    local playerConfig = PlayerConfigurations[playerID]
    if playerConfig == nil or not playerConfig:IsAlive() then return end

    local notification = GetLiveNotification(playerID, notificationID)
    if not IsNotificationAvailable(notification, notificationID, playerID) then return end

    local handler = GetHandler(notification:GetType())
    if handler == nil then return end
    if handler.AddSound ~= nil and handler.AddSound ~= "" then return end

    -- These notifications receive audio outside the handler's AddSound field.
    if DEFAULT_SOUND_EXCLUDED_TYPES[notification:GetType()] then return end

    UI.PlaySound(DEFAULT_NOTIFICATION_SOUND)
end

OnNotificationAdded = WrapFunc(OnNotificationAdded, function(orig, playerID, notificationID)
    orig(playerID, notificationID)
    PlayDefaultNotificationSound(playerID, notificationID)
    if playerID == GetLocalPlayer() and m_centerTree then
        RebuildNotificationTree()
    end
    SpeakNotificationAdded(playerID, notificationID)
end)

OnNotificationDismissed = WrapFunc(OnNotificationDismissed, function(orig, playerID, notificationID)
    orig(playerID, notificationID)
    if playerID == GetLocalPlayer() then
        m_caiAnnouncedNotificationIDs[notificationID] = nil
        if m_centerTree then RebuildNotificationTree() end
    end
end)

local function OnMessageBufferEntryAdded()
    RebuildMessageList()
end

local function OnCAINotificationInputAction(actionId)
    if actionId == ACTION_OPEN_NOTIFICATION_CENTER then
        OpenNotificationCenter()
    end
end

-- ensure notifications are not announced in the load screen
function OnLoadScreenClose()
    if not m_IsGameStarted then
        m_IsGameStarted = true
        if #m_caiDeferedNotificationAnnounce > 0 then
            for _, n in ipairs(m_caiDeferedNotificationAnnounce) do
                SpeakNotificationAdded(n.pId, n.Id)
            end
        end
    end
end

OnShutdown = WrapFunc(OnShutdown, function(orig)
    Events.InputActionStarted.Remove(OnCAINotificationInputAction)
    Events.LoadScreenClose.Remove(OnLoadScreenClose)
    LuaEvents.CAIAppendToMessageBuffer.Remove(OnMessageBufferEntryAdded)
    CloseNotificationCenter()
    orig()
end)


Events.InputActionStarted.Add(OnCAINotificationInputAction)
Events.LoadScreenClose.Add(OnLoadScreenClose)
LuaEvents.CAIAppendToMessageBuffer.Add(OnMessageBufferEntryAdded)
