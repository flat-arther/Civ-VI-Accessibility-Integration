include("caiUtils")
include("TutorialGoals")

local mgr = ExposedMembers.CAI_UIManager

local TUTORIAL_GOALS_LIST_ID = "CAITutorialGoalsList"
local CAI_OPEN_TUTORIAL_GOALS_ACTION = Input.GetActionId("TutorialGoalsOpenList")
local CAI_TUTORIAL_GOAL_ADDED_TYPE = DB.MakeHash("NOTIFICATION_CAI_TUTORIAL_GOAL_ADDED")
local CAI_TUTORIAL_GOAL_COMPLETED_TYPE = DB.MakeHash("NOTIFICATION_CAI_TUTORIAL_GOAL_COMPLETED")

local m_caiGoalsList = nil

-- Mirror of vanilla goal state. We can't read vanilla's m_kGoals upvalues
-- from _G, so we maintain our own table populated from the same LuaEvents
-- that vanilla TutorialGoals.lua subscribes to.
local m_caiGoals = {}     -- [goalId] = { Text=, Tooltip=, IsCompleted=, CompletedOnTurn= }
local m_caiGoalOrder = {} -- ordered array of goalIds for stable list order

-- We don't capture notification ids at send time (the engine fires
-- NotificationAdded asynchronously). Instead, on activation we resolve the
-- notification back to a goal by matching notification:GetMessage() against
-- goal.Text -- both are loc tags, so it's a direct equality check.


local function GetLocalPlayerID()
    local playerID = Game.GetLocalPlayer()
    if playerID == nil or playerID < 0 then return nil end
    return playerID
end

local function CloseGoalsList()
    if mgr then
        mgr:RemoveFromStack(TUTORIAL_GOALS_LIST_ID)
    end
    m_caiGoalsList = nil
end

local function FindGoalIndex(goalId)
    for i, id in ipairs(m_caiGoalOrder) do
        if id == goalId then return i end
    end
    return nil
end

local function RemoveGoalFromMirror(goalId)
    if m_caiGoals[goalId] == nil then return end
    m_caiGoals[goalId] = nil
    local idx = FindGoalIndex(goalId)
    if idx then table.remove(m_caiGoalOrder, idx) end
end

local function BuildGoalsList()
    local list = mgr:CreateUIWidget(TUTORIAL_GOALS_LIST_ID, "List", {
        GetLabel = function() return Locale.Lookup("LOC_CAI_TUTORIAL_GOALS") end,
    })
    list:AddInputBinding({
        Key = Keys.VK_ESCAPE,
        Action = function()
            CloseGoalsList()
            return true
        end,
    })

    for _, id in ipairs(m_caiGoalOrder) do
        local goal = m_caiGoals[id]
        if goal then
            list:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAITutorialGoalEntry"), "StaticText", {
                GetLabel = function()
                    local g = m_caiGoals[id]
                    return g and (g.Text or "") or ""
                end,
                GetValue = function()
                    local g = m_caiGoals[id]
                    if g and g.IsCompleted then
                        return Locale.Lookup("LOC_CAI_TUTORIAL_GOAL_COMPLETE")
                    end
                    return Locale.Lookup("LOC_CAI_TUTORIAL_GOAL_INCOMPLETE")
                end,
                GetTooltip = function()
                    local g = m_caiGoals[id]
                    return g and (g.Tooltip or "") or ""
                end,
            }))
        end
    end
    return list
end

local function OpenGoalsList()
    CloseGoalsList()

    if #m_caiGoalOrder == 0 then
        Speak(Locale.Lookup("LOC_CAI_TUTORIAL_GOALS_NO_GOALS"))
        return
    end

    m_caiGoalsList = BuildGoalsList()
    m_caiGoalsList:SetDefaultIndex(#m_caiGoalsList.Children)
    mgr:Push(m_caiGoalsList, PopupPriority.Low)
end

local function OpenGoalsListFocusedOn(goalId)
    CloseGoalsList()
    if #m_caiGoalOrder == 0 then return end

    local list = BuildGoalsList()
    -- Per spec: clear current focus, then set default index to the goal that
    -- is the subject of the notification.
    list.FocusedChild = nil
    local idx = FindGoalIndex(goalId) or #list.Children
    list:SetDefaultIndex(idx)
    mgr:Push(list, PopupPriority.Low)
end

local function SendGoalNotification(goalId, notificationType)
    local playerID = GetLocalPlayerID()
    if playerID == nil then return end
    local goal = m_caiGoals[goalId]
    if goal == nil then return end

    NotificationManager.SendNotification(
        playerID,
        notificationType,
        goal.Text or "",
        goal.Tooltip or ""
    )
end

-- Resolves a notification back to a goal by matching notification:GetMessage()
-- (the title loc tag we sent) against goal.Text in the live mirror.
local function FindGoalIdByNotification(notification)
    if notification == nil then return nil end
    local title = notification:GetMessage()
    if title == nil or title == "" then return nil end
    for id, goal in pairs(m_caiGoals) do
        if goal.Text == title then
            return id
        end
    end
    return nil
end


--#Lua-event listeners on the vanilla goal channel

local function OnCAIGoalAdd(goal)
    if not goal or goal.Id == nil then return end
    if m_caiGoals[goal.Id] == nil then
        table.insert(m_caiGoalOrder, goal.Id)
    end
    m_caiGoals[goal.Id] = {
        Text = goal.Text,
        Tooltip = goal.Tooltip,
        IsCompleted = goal.IsCompleted == true,
        CompletedOnTurn = goal.CompletedOnTurn,
    }
    SendGoalNotification(goal.Id, CAI_TUTORIAL_GOAL_ADDED_TYPE)
end

local function OnCAIGoalMarkComplete(goalId, currentTurn)
    if goalId == nil then return end
    local goal = m_caiGoals[goalId]
    if goal == nil then return end
    goal.IsCompleted = true
    goal.CompletedOnTurn = currentTurn
    SendGoalNotification(goalId, CAI_TUTORIAL_GOAL_COMPLETED_TYPE)
end

local function OnCAIGoalRemove(goal)
    if not goal or goal.Id == nil then return end
    RemoveGoalFromMirror(goal.Id)
end

local function OnCAIGoalAutoRemove(currentTurn)
    -- Mirror vanilla OnGoalAutoRemove: drop completed goals whose
    -- CompletedOnTurn precedes the current turn.
    for i = #m_caiGoalOrder, 1, -1 do
        local id = m_caiGoalOrder[i]
        local goal = m_caiGoals[id]
        if goal and goal.IsCompleted and goal.CompletedOnTurn ~= nil
            and goal.CompletedOnTurn < currentTurn then
            RemoveGoalFromMirror(id)
        end
    end
end

local function OnCAICloseGoals()
    CloseGoalsList()
end


--#Notification activation

local function OnCAITutorialGoalNotificationActivate(playerID, notificationID)
    if playerID ~= GetLocalPlayerID() then return end
    local notification = NotificationManager.Find(playerID, notificationID)
    if notification == nil then return end

    local notificationType = notification:GetType()
    if notificationType ~= CAI_TUTORIAL_GOAL_ADDED_TYPE
        and notificationType ~= CAI_TUTORIAL_GOAL_COMPLETED_TYPE then
        return
    end

    local goalId = FindGoalIdByNotification(notification)
    if goalId == nil then return end
    OpenGoalsListFocusedOn(goalId)
end


--#Hotkey

local function OnCAITutorialGoalsInputAction(actionId)
    if actionId == CAI_OPEN_TUTORIAL_GOALS_ACTION then
        OpenGoalsList()
    end
end


--#Context input handler: manager handles input, otherwise simply return true.

function OnCAITutorialGoalsInputHandler(inputStruct)
    if mgr then
        if mgr:GetTop() ~= m_caiGoalsList then return false end
        mgr:HandleInput(inputStruct)
    end
    return true
end

--#Wire everything up

LuaEvents.TutorialUIRoot_GoalAdd.Add(OnCAIGoalAdd)
LuaEvents.TutorialUIRoot_GoalMarkComplete.Add(OnCAIGoalMarkComplete)
LuaEvents.TutorialUIRoot_GoalRemove.Add(OnCAIGoalRemove)
LuaEvents.TutorialUIRoot_GoalAutoRemove.Add(OnCAIGoalAutoRemove)
LuaEvents.TutorialUIRoot_CloseGoals.Add(OnCAICloseGoals)

LuaEvents.CAI_TutorialGoalNotificationActivate.Add(OnCAITutorialGoalNotificationActivate)

Events.InputActionTriggered.Add(OnCAITutorialGoalsInputAction)

ContextPtr:SetInputHandler(OnCAITutorialGoalsInputHandler, true)
