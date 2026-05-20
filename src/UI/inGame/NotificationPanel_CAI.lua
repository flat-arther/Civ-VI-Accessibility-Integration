include("caiUtils")

local mgr = ExposedMembers.CAI_UIManager
local NOTIFICATION_CENTER_ID = "CAINotificationCenterTree"
local EMPTY_NODE_ID = "CAINotificationEmptyTreeItem"
local GROUP_NODE_PREFIX = "CAINotificationGroupTreeItem_"
local ACTION_OPEN_NOTIFICATION_CENTER = Input.GetActionId("NotificationPanelOpenList")
local CAI_TUTORIAL_GOAL_ADDED_TYPE = DB.MakeHash("NOTIFICATION_CAI_TUTORIAL_GOAL_ADDED")
local CAI_TUTORIAL_GOAL_COMPLETED_TYPE = DB.MakeHash("NOTIFICATION_CAI_TUTORIAL_GOAL_COMPLETED")
local BASE_RegisterHandlers = RegisterHandlers
local m_caiNotificationCenter = nil
local m_caiOriginalOnNotificationAdded = OnNotificationAdded
local m_caiOriginalOnNotificationDismissed = OnNotificationDismissed
local m_caiAnnouncedNotificationIDs = {}
local AddEmptyNode = nil

local function GetLocalPlayer()
    local playerID = Game.GetLocalPlayer()
    if playerID == nil or playerID < 0 then return nil end
    return playerID
end

function RegisterHandlers()
    BASE_RegisterHandlers()

    g_notificationHandlers[CAI_TUTORIAL_GOAL_ADDED_TYPE] = MakeDefaultHandlers()
    g_notificationHandlers[CAI_TUTORIAL_GOAL_COMPLETED_TYPE] = MakeDefaultHandlers()
    g_notificationHandlers[CAI_TUTORIAL_GOAL_ADDED_TYPE].Activate = OnCAITutorialGoalNotificationActivate
    g_notificationHandlers[CAI_TUTORIAL_GOAL_COMPLETED_TYPE].Activate = OnCAITutorialGoalNotificationActivate
end

local function LookupNotificationText(notification)
    if not notification then return "", "" end

    local title = notification:GetMessage()
    if title and title ~= "" then
        title = Locale.Lookup(title)
    else
        title = notification:GetTypeName() or ""
    end

    local summary = notification:GetSummary()
    if summary and summary ~= "" then
        summary = Locale.Lookup(summary)
    else
        summary = ""
    end

    return title or "", summary or ""
end

local function GetNotificationCoords(notification)
    if not notification then return nil, nil end

    if notification:IsLocationValid() then
        return notification:GetLocation()
    end

    if notification:IsTargetValid() then
        local targetPlayerID, targetID, targetType = notification:GetTarget()
        local player = targetPlayerID ~= nil and Players[targetPlayerID] or nil
        if player and targetType == PlayerComponentTypes.UNIT then
            local unit = player:GetUnits():FindID(targetID)
            if unit then return unit:GetX(), unit:GetY() end
        elseif player and targetType == PlayerComponentTypes.CITY then
            local city = player:GetCities():FindID(targetID)
            if city then return city:GetX(), city:GetY() end
        end
    end

    return nil, nil
end

LookAtNotification = WrapFunc(LookAtNotification, function(orig, notification)
    local x, y = GetNotificationCoords(notification)
    orig(notification)
    if m_caiNotificationCenter == nil and x ~= nil and y ~= nil then
        local plot = Map.GetPlot(x, y)
        if plot == nil then
            print("CAI NotificationPanel could not resolve notification plot: " .. tostring(x) .. ", " .. tostring(y))
            return
        end

        LuaEvents.CAICursorJump(plot:GetIndex())
    end
end)

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

local function BuildNotificationGroups(playerID)
    local groups = {}
    local groupOrder = {}
    local ids = NotificationManager.GetList(playerID) or {}

    for _, notificationID in ipairs(ids) do
        local notification = GetLiveNotification(playerID, notificationID)
        if IsNotificationAvailable(notification, notificationID, playerID) then
            local typeName = notification:GetTypeName() or tostring(notification:GetType())
            if groups[typeName] == nil then
                groups[typeName] = {
                    TypeName = typeName,
                    Notifications = {},
                }
                table.insert(groupOrder, groups[typeName])
            end
            table.insert(groups[typeName].Notifications, notificationID)
        end
    end

    return groupOrder
end

local function GetNotificationTypeName(notification)
    if not notification then return nil end
    return notification:GetTypeName() or tostring(notification:GetType())
end

local function GetGroupWidgetId(typeName)
    if not typeName then return nil end
    return GROUP_NODE_PREFIX .. typeName
end

local function CloseNotificationCenter()
    m_caiNotificationCenter = nil
    if mgr then
        mgr:RemoveFromStack(NOTIFICATION_CENTER_ID)
    end
end

local function RemoveNotificationWidget(notificationID)
    if not m_caiNotificationCenter then return end

    local leaf = m_caiNotificationCenter:GetChildById(tostring(notificationID), true)
    if not leaf then return end

    local parent = leaf.Parent
    leaf:Destroy()

    if parent and parent ~= m_caiNotificationCenter and parent.Children and #parent.Children == 0 then
        parent:Destroy()
    end

    if m_caiNotificationCenter.Children and #m_caiNotificationCenter.Children == 0 then
        AddEmptyNode(m_caiNotificationCenter)
    end

    if mgr then
        mgr:SetFocus(m_caiNotificationCenter)
    end
end

local function SpeakUnavailable()
    Speak(Locale.Lookup("LOC_CAI_NOTIFICATION_UNAVAILABLE"))
end

function OnCAITutorialGoalNotificationActivate(notificationEntry, notificationID, activatedByUser)
    if notificationEntry == nil or notificationEntry.m_PlayerID ~= Game.GetLocalPlayer() then
        return
    end

    local notification = GetActiveNotificationFromEntry(notificationEntry, notificationID)
    if notification == nil then
        return
    end

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
        local title = LookupNotificationText(notification)
        Speak(Locale.Lookup("LOC_NOTIFICATION_WRONG_PHASE_TT", title))
        return true
    end

    CloseNotificationCenter()

    -- Mirror vanilla rail left-click: route through the registered TryActivate
    -- handler on the notification entry (defaults to OnDefaultTryActivateNotification).
    -- This ensures the engine fires Events.NotificationActivated which vanilla
    -- NotificationPanel dispatches to the registered Activate handler, whether
    -- that is vanilla's USER_DEFINED path or CAI's custom goal notifications.
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
        -- Mirror vanilla rail right-click: route through the registered
        -- TryDismiss handler on the notification entry.
        local notificationEntry = GetVanillaNotificationEntry(playerID, notificationID)
        if notificationEntry and notificationEntry.m_kHandlers and notificationEntry.m_kHandlers.TryDismiss then
            notificationEntry.m_kHandlers.TryDismiss(notificationEntry)
        else
            NotificationManager.Dismiss(playerID, notificationID)
        end
        RemoveNotificationWidget(notificationID)
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
            RemoveNotificationWidget(notificationID)
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

AddEmptyNode = function(tree)
    tree:AddChild(mgr:CreateUIWidget(EMPTY_NODE_ID, "TreeviewItem", {
        GetLabel = function()
            return Locale.Lookup("LOC_CAI_NOTIFICATION_EMPTY")
        end,
    }))
end

local function GetNotificationValue(playerID, notificationID, index, group)
    return function()
        local notification = GetLiveNotification(playerID, notificationID)
        if not IsNotificationAvailable(notification, notificationID, playerID) then
            return Locale.Lookup(
                "LOC_CAI_NOTIFICATION_UNAVAILABLE")
        end

        local parts = {}
        local count = group and group.Notifications and #group.Notifications or nil
        if count and count > 1 then
            table.insert(parts, Locale.Lookup("LOC_CAI_NOTIFICATION_STACK_POSITION", index, count))
        end
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

local function GetNotificationTooltip(playerID, notificationID)
    return function()
        local notification = GetLiveNotification(playerID, notificationID)
        if not IsNotificationAvailable(notification, notificationID, playerID) then
            return Locale.Lookup(
                "LOC_CAI_NOTIFICATION_UNAVAILABLE")
        end

        local _, summary = LookupNotificationText(notification)
        local x, y = GetNotificationCoords(notification)
        if x ~= nil and y ~= nil then
            local location = Locale.Lookup("LOC_CAI_NOTIFICATION_AT_LOCATION", x, y)
            if summary ~= "" then
                return summary .. "[NEWLINE]" .. location
            end
            return location
        end
        return summary
    end
end

local function AddNotificationLeaf(parent, playerID, notificationID, index, group)
    local notification = GetLiveNotification(playerID, notificationID)
    if not IsNotificationAvailable(notification, notificationID, playerID) then return end

    local leaf = mgr:CreateUIWidget(tostring(notificationID), "TreeviewItem", {
        GetLabel = function()
            local liveNotification = GetLiveNotification(playerID, notificationID)
            if not IsNotificationAvailable(liveNotification, notificationID, playerID) then
                return Locale.Lookup(
                    "LOC_CAI_NOTIFICATION_UNAVAILABLE")
            end
            local liveTitle = LookupNotificationText(liveNotification)
            return liveTitle
        end,
        GetValue = GetNotificationValue(playerID, notificationID, index, group),
        GetTooltip = GetNotificationTooltip(playerID, notificationID),
    })
    leaf.NotificationID = notificationID
    leaf.NotificationTypeName = GetNotificationTypeName(notification)
    leaf.NotificationGroup = group

    leaf.OnClick = function()
        ActivateNotification(playerID, notificationID)
    end
    leaf:AddInputBindings({
        {
            Key = Keys.VK_SPACE,
            Action = function()
                return ActivateNotification(playerID, notificationID)
            end,
        },
        {
            Key = Keys.VK_DELETE,
            Action = function()
                return DismissNotification(playerID, notificationID)
            end,
        },
    })

    parent:AddChild(leaf)
    return leaf
end

local function GetGroupLabel(playerID, group)
    return function()
        if group and group.Notifications then
            for _, notificationID in ipairs(group.Notifications) do
                local notification = GetLiveNotification(playerID, notificationID)
                if IsNotificationAvailable(notification, notificationID, playerID) then
                    local title = LookupNotificationText(notification)
                    return title
                end
            end
        end
        return Locale.Lookup("LOC_CAI_NOTIFICATION_UNAVAILABLE")
    end
end

local function GetGroupValue(group)
    return function(w)
        local count = w and w.Children and #w.Children or group and group.Notifications and #group.Notifications or 0
        local parts = { Locale.Lookup("LOC_CAI_NOTIFICATION_GROUP_COUNT", count) }
        if w and w.IsExpanded then
            table.insert(parts, Locale.Lookup("LOC_CAI_TREEVIEW_EXPANDED"))
        else
            table.insert(parts, Locale.Lookup("LOC_CAI_TREEVIEW_COLLAPSED"))
        end
        return table.concat(parts, ", ")
    end
end

local function AddNotificationGroup(tree, playerID, group)
    local count = #group.Notifications
    if count == 1 then
        AddNotificationLeaf(tree, playerID, group.Notifications[1], nil, nil)
        return
    end

    local groupNode = mgr:CreateUIWidget(GetGroupWidgetId(group.TypeName), "TreeviewItem", {
        GetLabel = GetGroupLabel(playerID, group),
        GetValue = GetGroupValue(group),
    })
    groupNode.NotificationTypeName = group.TypeName
    groupNode.Notifications = group.Notifications

    groupNode:AddInputBinding({
        Key = Keys.VK_DELETE,
        IsShift = true,
        Action = function()
            return DismissNotificationGroup(playerID, group)
        end,
    })

    for index, notificationID in ipairs(group.Notifications) do
        AddNotificationLeaf(groupNode, playerID, notificationID, index, group)
    end

    tree:AddChild(groupNode)
    return groupNode
end

local function RemoveEmptyNode(tree)
    if not tree then return end
    local emptyNode = tree:GetChildById(EMPTY_NODE_ID, false)
    if emptyNode then
        emptyNode:Destroy()
    end
end

local function FindTopLevelNotificationWidgetByType(tree, typeName)
    if not tree or not tree.Children or not typeName then return nil end
    for _, child in ipairs(tree.Children) do
        if child and child.NotificationTypeName == typeName then
            return child
        end
    end
    return nil
end

local function AddNotificationToOpenTree(playerID, notificationID)
    if not m_caiNotificationCenter then return end
    if m_caiNotificationCenter:GetChildById(tostring(notificationID), true) then return end

    local notification = GetLiveNotification(playerID, notificationID)
    if not IsNotificationAvailable(notification, notificationID, playerID) then return end

    local typeName = GetNotificationTypeName(notification)
    if not typeName then return end

    RemoveEmptyNode(m_caiNotificationCenter)

    local groupNode = m_caiNotificationCenter:GetChildById(GetGroupWidgetId(typeName), false)
    if groupNode and groupNode.Notifications then
        table.insert(groupNode.Notifications, notificationID)
        AddNotificationLeaf(groupNode, playerID, notificationID, #groupNode.Notifications, {
            TypeName = typeName,
            Notifications = groupNode.Notifications,
        })
        return
    end

    local existingLeaf = FindTopLevelNotificationWidgetByType(m_caiNotificationCenter, typeName)
    if existingLeaf and existingLeaf.NotificationID then
        local existingID = existingLeaf.NotificationID
        existingLeaf:Destroy()
        AddNotificationGroup(m_caiNotificationCenter, playerID, {
            TypeName = typeName,
            Notifications = { existingID, notificationID },
        })
        return
    end

    AddNotificationLeaf(m_caiNotificationCenter, playerID, notificationID, nil, nil)
end

local function OpenNotificationCenter()
    if not mgr then return end
    CloseNotificationCenter()

    local playerID = GetLocalPlayer()
    if not playerID then
        Speak(Locale.Lookup("LOC_CAI_NOTIFICATION_UNAVAILABLE"))
        return
    end

    local tree = mgr:CreateUIWidget(NOTIFICATION_CENTER_ID, "Treeview", {
        GetLabel = function()
            return Locale.Lookup("LOC_CAI_NOTIFICATION_CENTER")
        end,
    })
    tree:AddInputBinding({
        Key = Keys.VK_ESCAPE,
        Action = function()
            CloseNotificationCenter()
            return true
        end,
    })

    local groups = BuildNotificationGroups(playerID)
    if #groups == 0 then
        AddEmptyNode(tree)
    else
        for _, group in ipairs(groups) do
            AddNotificationGroup(tree, playerID, group)
        end
    end
    tree:SetDefaultIndex(#tree.Children)
    m_caiNotificationCenter = tree
    mgr:Push(tree)
end

local function SpeakNotificationAdded(playerID, notificationID)
    if ContextPtr:IsHidden() then return end
    if playerID ~= GetLocalPlayer() then return end
    if m_caiAnnouncedNotificationIDs[notificationID] then return end

    local notification = GetLiveNotification(playerID, notificationID)
    if not IsNotificationAvailable(notification, notificationID, playerID) then return end
    m_caiAnnouncedNotificationIDs[notificationID] = true

    local title, summary = LookupNotificationText(notification)
    local notificationType = notification:GetType()
    local line = Locale.Lookup("LOC_CAI_NOTIFICATION_ALERT", title)
    if notificationType == CAI_TUTORIAL_GOAL_ADDED_TYPE then
        line = Locale.Lookup("LOC_CAI_TUTORIAL_GOAL_ADDED_ALERT", title)
    elseif notificationType == CAI_TUTORIAL_GOAL_COMPLETED_TYPE then
        line = Locale.Lookup("LOC_CAI_TUTORIAL_GOAL_COMPLETED_ALERT", title)
    end
    if summary ~= "" then
        line = line .. "[NEWLINE]" .. summary
    end

    local x, y = GetNotificationCoords(notification)
    if x ~= nil and y ~= nil then
        line = line .. "[NEWLINE]" .. Locale.Lookup("LOC_CAI_NOTIFICATION_AT_LOCATION", x, y)
    end

    Speak(line)
end

OnNotificationAdded = function(playerID, notificationID)
    m_caiOriginalOnNotificationAdded(playerID, notificationID)
    if playerID == GetLocalPlayer() then
        AddNotificationToOpenTree(playerID, notificationID)
    end
    SpeakNotificationAdded(playerID, notificationID)
end

OnNotificationDismissed = function(playerID, notificationID)
    m_caiOriginalOnNotificationDismissed(playerID, notificationID)
    if playerID == GetLocalPlayer() then
        m_caiAnnouncedNotificationIDs[notificationID] = nil
        RemoveNotificationWidget(notificationID)
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
