-- CAIUITutorialManager.lua
-- Event-driven tutorials presented as Dialog children of the current CAI route.

CAIUITutorialManager = {}
CAIUITutorialManager.__index = CAIUITutorialManager

local CONFIG_SECTION = "Tutorials"
local SEEN_KEY_PREFIX = "Seen_"
local RESET_GENERATION_KEY = "ResetGeneration"
local SHOW_TUTORIALS_SETTING = "ShowTutorials"
local RESET_TUTORIALS_SETTING = "ResetModTutorials"

local function IsValidItemId(itemId)
    return type(itemId) == "string"
        and itemId ~= ""
        and itemId:match("^[%w_.%-]+$") ~= nil
end

local function ResolveLocalizedText(value, context, item)
    if type(value) == "function" then
        return value(context, item) or ""
    end
    if type(value) == "string" then
        return Locale.Lookup(value)
    end
    return ""
end

---@param mgr UIScreenManager
---@return CAIUITutorialManager
function CAIUITutorialManager:New(mgr)
    local tutorialMgr = setmetatable({}, CAIUITutorialManager)
    tutorialMgr.Manager = mgr
    tutorialMgr.Items = {}
    tutorialMgr.Listeners = {}
    tutorialMgr.Queue = {}
    tutorialMgr.Active = nil
    tutorialMgr.NextRegistrationOrder = 0
    tutorialMgr.IsClosing = false
    tutorialMgr.SettingsChangedListener = nil
    tutorialMgr.SettingsHooked = false
    tutorialMgr:HookSettingsChanged()
    return tutorialMgr
end

---@param itemId string
---@return string
function CAIUITutorialManager:GetSeenSettingKey(itemId)
    return SEEN_KEY_PREFIX .. itemId
end

---@return integer
function CAIUITutorialManager:GetResetGeneration()
    return math.max(0, math.floor(tonumber(CAI.GetConfigValue(
        CONFIG_SECTION,
        RESET_GENERATION_KEY,
        "0"
    )) or 0))
end

---@return boolean
function CAIUITutorialManager:AreTutorialsEnabled()
    return CAISettings.GetBool(SHOW_TUTORIALS_SETTING)
end

---@param itemId string
---@return boolean
function CAIUITutorialManager:IsSeen(itemId)
    if not IsValidItemId(itemId) then
        LogError("Tutorial manager IsSeen received invalid item id " .. tostring(itemId))
        return false
    end
    local stored = tostring(CAI.GetConfigValue(
        CONFIG_SECTION,
        self:GetSeenSettingKey(itemId),
        ""
    ))
    if stored:lower() == "true" then
        return self:GetResetGeneration() == 0
    end
    return stored == tostring(self:GetResetGeneration())
end

---@param itemId string
---@return boolean
function CAIUITutorialManager:MarkSeen(itemId)
    if not IsValidItemId(itemId) then
        LogError("Tutorial manager MarkSeen received invalid item id " .. tostring(itemId))
        return false
    end
    return CAI.SetConfigValue(
        CONFIG_SECTION,
        self:GetSeenSettingKey(itemId),
        tostring(self:GetResetGeneration())
    ) and true or false
end

---@param itemId string
---@return boolean
function CAIUITutorialManager:ResetSeen(itemId)
    if not IsValidItemId(itemId) then
        LogError("Tutorial manager ResetSeen received invalid item id " .. tostring(itemId))
        return false
    end
    return CAI.SetConfigValue(
        CONFIG_SECTION,
        self:GetSeenSettingKey(itemId),
        "false"
    ) and true or false
end

---@return boolean
function CAIUITutorialManager:ResetAllSeen()
    return CAI.SetConfigValue(
        CONFIG_SECTION,
        RESET_GENERATION_KEY,
        tostring(self:GetResetGeneration() + 1)
    ) and true or false
end

---@param settingId string
---@param value? any
function CAIUITutorialManager:OnSettingsChanged(settingId, value)
    if settingId ~= RESET_TUTORIALS_SETTING or value ~= "reset" then return end
    if self:ResetAllSeen() then
        Speak(Locale.Lookup("LOC_CAI_TUTORIALS_RESET"))
    else
        Speak(Locale.Lookup("LOC_CAI_TUTORIAL_SAVE_FAILED"))
    end
end

function CAIUITutorialManager:HookSettingsChanged()
    if self.SettingsHooked then return end
    self.SettingsChangedListener = function(settingId, value)
        self:OnSettingsChanged(settingId, value)
    end
    LuaEvents.CAISettingsChanged.Add(self.SettingsChangedListener)
    self.SettingsHooked = true
end

function CAIUITutorialManager:UnhookSettingsChanged()
    if not self.SettingsHooked then return end
    LuaEvents.CAISettingsChanged.Remove(self.SettingsChangedListener)
    self.SettingsChangedListener = nil
    self.SettingsHooked = false
end

---@param item CAITutorialItemDefinition
---@return boolean
function CAIUITutorialManager:RegisterItem(item)
    if type(item) ~= "table" then
        LogError("Tutorial manager RegisterItem expected a definition table")
        return false
    end
    if not IsValidItemId(item.Id) then
        LogError("Tutorial manager RegisterItem received invalid item id " .. tostring(item.Id))
        return false
    end
    if self.Items[item.Id] then
        LogError("Tutorial manager duplicate item id " .. tostring(item.Id))
        return false
    end
    if type(item.RaiseEvents) ~= "table" or #item.RaiseEvents == 0 then
        LogError("Tutorial manager item " .. item.Id .. " has no RaiseEvents")
        return false
    end
    if type(item.Title) ~= "string" and type(item.Title) ~= "function" then
        LogError("Tutorial manager item " .. item.Id .. " has no localized Title")
        return false
    end
    if type(item.Content) ~= "table" or #item.Content == 0 then
        LogError("Tutorial manager item " .. item.Id .. " has no Content")
        return false
    end
    if item.Prerequisites ~= nil and type(item.Prerequisites) ~= "table" then
        LogError("Tutorial manager item " .. item.Id .. " has invalid Prerequisites")
        return false
    end
    if item.CanRaise ~= nil and type(item.CanRaise) ~= "function" then
        LogError("Tutorial manager item " .. item.Id .. " has invalid CanRaise")
        return false
    end
    if item.OnOpen ~= nil and type(item.OnOpen) ~= "function" then
        LogError("Tutorial manager item " .. item.Id .. " has invalid OnOpen")
        return false
    end
    if item.OnContinue ~= nil and type(item.OnContinue) ~= "function" then
        LogError("Tutorial manager item " .. item.Id .. " has invalid OnContinue")
        return false
    end
    for _, contentValue in ipairs(item.Content) do
        if type(contentValue) ~= "string" and type(contentValue) ~= "function" then
            LogError("Tutorial manager item " .. item.Id .. " has invalid Content")
            return false
        end
    end
    for _, prerequisiteId in ipairs(item.Prerequisites or {}) do
        if not IsValidItemId(prerequisiteId) then
            LogError("Tutorial manager item " .. item.Id .. " has an invalid prerequisite id")
            return false
        end
    end
    local raiseEventsSeen = {}
    for _, eventName in ipairs(item.RaiseEvents) do
        if type(eventName) ~= "string" or eventName == "" then
            LogError("Tutorial manager item " .. item.Id .. " has an invalid raise event")
            return false
        end
        if raiseEventsSeen[eventName] then
            LogError("Tutorial manager item " .. item.Id .. " repeats raise event " .. eventName)
            return false
        end
        raiseEventsSeen[eventName] = true
    end

    self.NextRegistrationOrder = self.NextRegistrationOrder + 1
    item.Order = tonumber(item.Order) or 0
    item.Queueable = item.Queueable == true
    item.Prerequisites = item.Prerequisites or {}
    item._registrationOrder = self.NextRegistrationOrder
    self.Items[item.Id] = item

    for _, eventName in ipairs(item.RaiseEvents) do
        self.Listeners[eventName] = self.Listeners[eventName] or {}
        table.insert(self.Listeners[eventName], item)
        table.sort(self.Listeners[eventName], function(a, b)
            if a.Order ~= b.Order then return a.Order < b.Order end
            return a._registrationOrder < b._registrationOrder
        end)
    end

    LogMessage("Tutorial manager registered item " .. item.Id)
    return true
end

---@param items CAITutorialItemDefinition[]
---@return boolean
function CAIUITutorialManager:RegisterItems(items)
    if type(items) ~= "table" then
        LogError("Tutorial manager RegisterItems expected an array")
        return false
    end
    local ok = true
    for _, item in ipairs(items) do
        if not self:RegisterItem(item) then ok = false end
    end
    return ok
end

---@param widget UIWidget|nil
---@return UIWidget|nil
function CAIUITutorialManager:GetStackRoot(widget)
    local root = widget
    while root and root.Parent do root = root.Parent end
    if not root or not self.Manager then return nil end
    for _, stackRoot in ipairs(self.Manager.Stack) do
        if stackRoot == root then return root end
    end
    return nil
end

---@param widget UIWidget|nil
---@return boolean
function CAIUITutorialManager:IsLiveWidget(widget)
    return widget ~= nil
        and widget.Manager == self.Manager
        and widget.Children ~= nil
        and self:GetStackRoot(widget) ~= nil
end

---@param item CAITutorialItemDefinition
---@return boolean
function CAIUITutorialManager:ArePrerequisitesMet(item)
    for _, prerequisiteId in ipairs(item.Prerequisites) do
        if not self.Items[prerequisiteId] then
            LogError("Tutorial manager item " .. item.Id
                .. " references unknown prerequisite " .. tostring(prerequisiteId))
            return false
        end
        if not self:IsSeen(prerequisiteId) then return false end
    end
    return true
end

---@param item CAITutorialItemDefinition
---@param context? any
---@return boolean
function CAIUITutorialManager:IsEligible(item, context)
    if self:IsSeen(item.Id) then return false end
    if not self:ArePrerequisitesMet(item) then return false end
    if item.CanRaise and not item.CanRaise(context, item) then return false end
    return true
end

---@param itemId string
---@return boolean
function CAIUITutorialManager:IsQueued(itemId)
    for _, queued in ipairs(self.Queue) do
        if queued.Item.Id == itemId then return true end
    end
    return false
end

---@param item CAITutorialItemDefinition
---@param owner UIWidget
---@param context? any
function CAIUITutorialManager:QueueItem(item, owner, context)
    if self:IsQueued(item.Id) then return end
    table.insert(self.Queue, {
        Item = item,
        Owner = owner,
        Context = context,
    })
    LogMessage("Tutorial manager queued item " .. item.Id)
end

function CAIUITutorialManager:ClearQueue()
    self.Queue = {}
end

---@return boolean
function CAIUITutorialManager:IsActive()
    return self.Active ~= nil
end

---@param item CAITutorialItemDefinition
---@param owner UIWidget
---@param context? any
---@return boolean
function CAIUITutorialManager:Activate(item, owner, context)
    if self.Active or not self:IsLiveWidget(owner) then return false end
    if self:GetStackRoot(owner) ~= self.Manager:GetTop() then return false end

    local previousFocus = self.Manager:GetFocusedWidget()
    local host = self.Manager:CreateWidget(
        self.Manager:GenerateWidgetId("CAITutorialHost"),
        "Panel",
        {
            Transparent = true,
            WrapAround = true,
            TrapInput = true,
        }
    )
    host:On("focus_enter", function()
        Input.SetActiveContext(InputContext.Shell)
    end)
    host:AddInputBinding({
        Key = Keys.VK_ESCAPE,
        MSG = KeyEvents.KeyDown,
        Description = "LOC_CAI_TUTORIAL_ESCAPE_BLOCKED",
        Action = function() return true end,
    })

    local contentRows = {}
    for _, contentValue in ipairs(item.Content) do
        local rowValue = contentValue
        local row = self.Manager:CreateWidget(
            self.Manager:GenerateWidgetId("CAITutorialText"),
            "StaticText",
            {
                Label = function()
                    return ResolveLocalizedText(rowValue, context, item)
                end,
            }
        )
        table.insert(contentRows, row)
    end

    local showTutorials = self.Manager:CreateWidget(
        self.Manager:GenerateWidgetId("CAITutorialShow"),
        "Checkbox",
        {
            Label = function()
                return Locale.Lookup("LOC_CAI_TUTORIAL_SHOW_TUTORIALS")
            end,
            Tooltip = function()
                return Locale.Lookup("LOC_CAI_TUTORIAL_SHOW_TUTORIALS_TOOLTIP")
            end,
        }
    )
    showTutorials:SetChecked(self:AreTutorialsEnabled(), true)
    showTutorials:SetValueSetter(function(_, checked)
        if CAISettings.SetBool(SHOW_TUTORIALS_SETTING, checked) then
            if not checked then self:ClearQueue() end
        else
            showTutorials:SetChecked(self:AreTutorialsEnabled(), true)
            Speak(Locale.Lookup("LOC_CAI_TUTORIAL_SAVE_FAILED"))
        end
    end)
    table.insert(contentRows, showTutorials)

    local continueButton = self.Manager:CreateWidget(
        self.Manager:GenerateWidgetId("CAITutorialContinue"),
        "Button",
        {
            Label = function() return Locale.Lookup("LOC_CONTINUE") end,
        }
    )
    continueButton:On("activate", function()
        self:Continue()
    end)

    local dialog = self.Manager.WidgetHelpers.MakeGeneralDialog(
        function() return ResolveLocalizedText(item.Title, context, item) end,
        { continueButton },
        contentRows,
        1
    )
    if not dialog then
        host:Destroy()
        LogError("Tutorial manager failed to build dialog for item " .. item.Id)
        return false
    end

    self.Active = {
        Item = item,
        Owner = owner,
        Context = context,
        Host = host,
        Dialog = dialog,
        PreviousFocus = previousFocus,
    }

    host:On("destroy", function()
        if self.Active and self.Active.Host == host then
            LogMessage("Tutorial manager owner removed active item " .. self.Active.Item.Id)
            self.Active = nil
            if not self.IsClosing then self:ProcessQueue() end
        end
    end)

    host:AddChild(dialog)
    owner:AddChild(host)
    if item.OnOpen then item.OnOpen(context, item) end
    CAI.Silence()
    self.Manager:SetFocus(dialog)
    LogMessage("Tutorial manager activated item " .. item.Id)
    return true
end

---@param restoreFocus? boolean
function CAIUITutorialManager:CloseActive(restoreFocus)
    local active = self.Active
    if not active then return end

    self.Active = nil
    self.IsClosing = true
    if active.Host and active.Host.Children then active.Host:Destroy() end
    self.IsClosing = false

    if restoreFocus ~= false then
        if self:IsLiveWidget(active.PreviousFocus)
            and self:GetStackRoot(active.PreviousFocus) == self.Manager:GetTop() then
            self.Manager:SetFocus(active.PreviousFocus)
        elseif self:IsLiveWidget(active.Owner)
            and self:GetStackRoot(active.Owner) == self.Manager:GetTop() then
            self.Manager:SetFocus(active.Owner)
        end
    end
    self:ProcessQueue()
end

---@return boolean
function CAIUITutorialManager:Continue()
    local active = self.Active
    if not active then return false end
    if not self:MarkSeen(active.Item.Id) then
        LogError("Tutorial manager could not persist seen state for item " .. active.Item.Id)
        Speak(Locale.Lookup("LOC_CAI_TUTORIAL_SAVE_FAILED"))
        return false
    end

    if active.Item.OnContinue then
        active.Item.OnContinue(active.Context, active.Item)
    end
    if self.Active == active then self:CloseActive(true) end
    return true
end

---@return boolean opened
function CAIUITutorialManager:ProcessQueue()
    if self.Active then return false end
    if not self:AreTutorialsEnabled() then
        self:ClearQueue()
        return false
    end

    local top = self.Manager and self.Manager:GetTop() or nil
    local i = 1
    while i <= #self.Queue do
        local queued = self.Queue[i]
        if not self:IsLiveWidget(queued.Owner)
            or not self:IsEligible(queued.Item, queued.Context) then
            table.remove(self.Queue, i)
        elseif self:GetStackRoot(queued.Owner) == top then
            table.remove(self.Queue, i)
            return self:Activate(queued.Item, queued.Owner, queued.Context)
        else
            i = i + 1
        end
    end
    return false
end

---@return boolean opened
function CAIUITutorialManager:OnRouteChanged()
    return self:ProcessQueue()
end

---@param eventName string
---@param owner UIWidget
---@param context? any
---@return boolean opened
function CAIUITutorialManager:Check(eventName, owner, context)
    if type(eventName) ~= "string" or eventName == "" then
        LogError("Tutorial manager Check received an invalid event name")
        return false
    end
    if not self:IsLiveWidget(owner) then
        LogWarn("Tutorial manager ignored " .. eventName .. " because its owner route is unavailable")
        return false
    end
    if not self:AreTutorialsEnabled() then
        self:ClearQueue()
        return false
    end

    local listeners = self.Listeners[eventName]
    if not listeners then return false end

    local opened = false
    for _, item in ipairs(listeners) do
        if self:IsEligible(item, context)
            and (not self.Active or self.Active.Item.Id ~= item.Id)
            and not self:IsQueued(item.Id) then
            if not opened and not self.Active
                and self:GetStackRoot(owner) == self.Manager:GetTop() then
                opened = self:Activate(item, owner, context)
            elseif item.Queueable then
                self:QueueItem(item, owner, context)
            end
        end
    end
    return opened
end

function CAIUITutorialManager:Shutdown()
    self:UnhookSettingsChanged()
    self:ClearQueue()
    self:CloseActive(false)
    self.Items = {}
    self.Listeners = {}
    self.Manager = nil
end
