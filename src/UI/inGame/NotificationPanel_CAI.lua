include("caiUtils")

local mgr                                  = ExposedMembers.CAI_UIManager

local NOTIFICATION_CENTER_ID               = "CAINotificationCenter_Tree"
local EMPTY_NODE_ID                        = "CAINotificationCenter_Empty"
local GROUP_ID_PREFIX                      = "CAINotificationCenter_Group_"
local LEAF_ID_PREFIX                       = "CAINotificationCenter_Leaf_"

local ACTION_OPEN_NOTIFICATION_CENTER      = Input.GetActionId("NotificationPanelOpenList")
local CAI_TUTORIAL_GOAL_ADDED_TYPE         = DB.MakeHash("NOTIFICATION_CAI_TUTORIAL_GOAL_ADDED")
local CAI_TUTORIAL_GOAL_COMPLETED_TYPE     = DB.MakeHash("NOTIFICATION_CAI_TUTORIAL_GOAL_COMPLETED")

local BASE_LookAtNotification               = LookAtNotification
local BASE_RegisterHandlers                = RegisterHandlers
local m_caiOriginalOnNotificationAdded     = OnNotificationAdded
local m_caiOriginalOnNotificationDismissed = OnNotificationDismissed

local m_centerTree                         = nil ---@type UIWidget|nil
local m_caiAnnouncedNotificationIDs        = {}

local function GetLocalPlayer()
    local playerID = Game.GetLocalPlayer()
    if playerID == nil or playerID < 0 then return nil end
    return playerID
end

function RegisterHandlers()
    BASE_RegisterHandlers()

    g_notificationHandlers[CAI_TUTORIAL_GOAL_ADDED_TYPE]              = MakeDefaultHandlers()
    g_notificationHandlers[CAI_TUTORIAL_GOAL_COMPLETED_TYPE]          = MakeDefaultHandlers()
    g_notificationHandlers[CAI_TUTORIAL_GOAL_ADDED_TYPE].Activate     = OnCAITutorialGoalNotificationActivate
    g_notificationHandlers[CAI_TUTORIAL_GOAL_COMPLETED_TYPE].Activate = OnCAITutorialGoalNotificationActivate
end

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
    m_centerTree = nil
    if mgr then mgr:RemoveFromStack(NOTIFICATION_CENTER_ID) end
end

LookAtNotification = function(pNotification)
    BASE_LookAtNotification(pNotification)
    if m_centerTree then return end
    if pNotification and pNotification:IsLocationValid() then
        local x, y = pNotification:GetLocation()
        local plot = Map.GetPlot(x, y)
        if plot then
            LuaEvents.CAICursorMoveTo(plot:GetIndex(), "jump")
        end
    end
end

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
        return table.concat(parts, ", ")
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
            Key    = Keys.VK_SPACE,
            MSG    = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_ACTIVATE_NOTIFICATION",
            Action = function() return ActivateNotification(playerID, notificationID) end,
        },
        {
            Key    = Keys.VK_DELETE,
            MSG    = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_DISMISS_NOTIFICATION",
            Action = function() return DismissNotification(playerID, notificationID) end,
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
        Key    = Keys.VK_DELETE,
        MSG    = KeyEvents.KeyUp,
        Description = "LOC_CAI_KB_DISMISS_STACK",
        Action = function() return DismissNotificationGroup(playerID, group) end,
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

local function RebuildTree()
    if not m_centerTree then return end
    local playerID = GetLocalPlayer()
    if not playerID then return end

    local capture = mgr:CaptureFocusKey(m_centerTree)
    m_centerTree:ClearChildren()
    PopulateTree(m_centerTree, playerID)
    mgr:RestoreFocus(m_centerTree, capture)
end

local function OpenNotificationCenter()
    if not mgr then return end
    CloseNotificationCenter()

    local playerID = GetLocalPlayer()
    if not playerID then
        Speak(Locale.Lookup("LOC_CAI_NOTIFICATION_UNAVAILABLE"))
        return
    end

    local tree = mgr:CreateWidget(NOTIFICATION_CENTER_ID, "Tree", {
        Label = function() return Locale.Lookup("LOC_CAI_NOTIFICATION_CENTER") end,
    })
    tree:AddInputBinding({
        Key    = Keys.VK_ESCAPE,
        MSG    = KeyEvents.KeyUp,
        Description = "LOC_CAI_KB_CLOSE",
        Action = function()
            CloseNotificationCenter()
            return true
        end,
    })

    local latestKey = PopulateTree(tree, playerID)
    m_centerTree = tree
    mgr:Push(tree, latestKey and { focus = latestKey } or nil)
end

local function SpeakNotificationAdded(playerID, notificationID)
    if ContextPtr:IsHidden() then return end
    if playerID ~= GetLocalPlayer() then return end
    if m_caiAnnouncedNotificationIDs[notificationID] then return end

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

    Speak(line)
end

OnNotificationAdded = function(playerID, notificationID)
    m_caiOriginalOnNotificationAdded(playerID, notificationID)
    if playerID == GetLocalPlayer() and m_centerTree then
        RebuildTree()
    end
    SpeakNotificationAdded(playerID, notificationID)
end

OnNotificationDismissed = function(playerID, notificationID)
    m_caiOriginalOnNotificationDismissed(playerID, notificationID)
    if playerID == GetLocalPlayer() then
        m_caiAnnouncedNotificationIDs[notificationID] = nil
        if m_centerTree then RebuildTree() end
    end
end

local function OnCAINotificationInputAction(actionId)
    if actionId == ACTION_OPEN_NOTIFICATION_CENTER then
        OpenNotificationCenter()
    end
end

OnShutdown = WrapFunc(OnShutdown, function(orig)
    Events.InputActionStarted.Remove(OnCAINotificationInputAction)
    CloseNotificationCenter()
    orig()
end)

Events.InputActionStarted.Add(OnCAINotificationInputAction)
