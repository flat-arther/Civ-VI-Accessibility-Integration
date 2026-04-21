--- The entry point for the entire UI manager system
---@class UIScreenManager
---@field Stack UIWidget[]
---@field CurrentPath UIWidget[]
---@field SearchBuffer string
---@field LastTypeTime number
---@field CAISettings table<string, any>
---@field WidgetTemplateHelpers WidgetTemplateHelpers
local UIScreenManager = {
    CAISettings = {
        speakLabel = true,
        speakRole = true,
        speakValue = true,
        speakPosition = true,
        speakState = true,
        speakTooltip = true,
        SearchTimeout = 1.0
    }
}

--#Includes
include ("caiUtils")
include("baseWidget")
include("widgetTemplates")
include("widgetTemplateHelpers")
--#Methods
---Creates a new instance of the UI manager
---@return UIScreenManager
function UIScreenManager:New()
    Speak(Locale.Lookup("LOC_CAI_CREATING_UI_MANAGER"))
    local mgr = setmetatable({}, {__index = UIScreenManager})
    mgr.Stack = {}
    mgr.WidgetTemplateHelpers = WidgetTemplateHelpers
    mgr.WidgetTemplateHelpers.Manager = mgr
    return mgr
end

---Creates a UI widget given a type and an optional properties table
---@param type string ---The type of widget to create. This should correspond to a key in 'WidgetTemplates'. If not, the props table must not be nil or empty
---@param props? table ---A table of properties to override the widget template's defaults. This is optional if you use a template
---@return UIWidget|nil --The created widget, or nil if the type was invalid
function UIScreenManager:CreateUIWidget(type, props)
        local template = WidgetTemplates[type]
    if not template and not props then return end
    local w = setmetatable({}, {__index = UIWidget}) ---@type UIWidget

    w.Manager = self
    w.Type = type
    w.Children = {}
    w.InputMap = {}
    w.SpeechSettings = {}
    w.FocusedChild = nil
        
    for k, v in pairs(template) do
        w[k] = v
    end
    if props then
        for k, v in pairs(props) do
            w[k] = v
        end
    end
        if w.RegisterInputs then
            w:AddInputBindings(w.RegisterInputs)
        end
        if w.OnCreate then w:OnCreate() end
    return w
end

---Adds a UI widget to the top of the stack.
---@param w UIWidget
function UIScreenManager:Push(w)
    table.insert(self.Stack, w)
    self:SetFocus(w)
end

---Removes the top UI widget
function UIScreenManager:Pop()
    if #self.Stack > 0 then
    local w = table.remove(self.Stack)
    w:Destroy()
    end
    if #self.Stack == 0 then return end
    self:SetFocus(self.Stack[#self.Stack])
end

---Returns the top widget in the stack
---@return UIWidget
function UIScreenManager:GetTop()
return self.Stack[#self.Stack]
end

---Recursively searches and returns the deepest focused widget
---@return UIWidget|nil
function UIScreenManager:GetFocusedWidget()
    local root = self:GetTop()
    if not root then return nil end

    local current = root
    while current.FocusedChild do
        current = current.FocusedChild
    end
    return current
end

---Builds an array of strings representing the focus path
---@param path UIWidget[]
---@param diverge integer
---@return string[]
function UIScreenManager:BuildAnnouncement(path, diverge)
    local announcements = {}

    for i = diverge, #path do
        local current = path[i]
        if current.BuildSpeech then
            local speech = current:BuildSpeech()
            if speech then table.insert(announcements, speech) end
        end
    end

    return announcements
end

---Returns a path of widgets leading to the provided widget
---@param widget UIWidget
---@return UIWidget[] --Path array, ordered from deepest to shallowest
function UIScreenManager.BuildFocusPath(widget)
    local path = {}

    local current = widget
    while current do
        table.insert(path, 1, current)
        current = current.Parent
    end

    local node = path[#path]
    while node.GetDefaultChild do
        local child = node:GetDefaultChild()
        if not child then break end
        node = child
        table.insert(path, node)
    end

    return path
end

---Helper to find the divergence index between two widget paths
---@param oldPath UIWidget[]
---@param newPath UIWidget[]
---@return integer
function UIScreenManager.FindDivergence(oldPath, newPath)
    local len = math.min(#oldPath, #newPath)
    local i = 1

    while i <= len and oldPath[i] == newPath[i] do
        i = i + 1
    end

    if i > #newPath and #newPath > 0 then
        return #newPath
    end

    return i
end

---Applies a given focus widget path and speaks any changes starting from the point of diverge
---@param newPath UIWidget[]
function UIScreenManager:ApplyFocus(newPath)
    local oldPath = self.CurrentPath or {}
    local diverge = self.FindDivergence(oldPath, newPath)
    for i = #oldPath, diverge, -1 do
        local w = oldPath[i]
        if w.OnFocusLeave then
            w:OnFocusLeave()
        end
    end

    for i = diverge, #newPath do
        local w = newPath[i]
        if w.OnFocusEnter then
            w:OnFocusEnter(newPath, i)
        end
    end

    for i = 1, #newPath - 1 do
        newPath[i].FocusedChild = newPath[i + 1]
    end

    self.CurrentPath = newPath

    local speechQueue = self:BuildAnnouncement(newPath, diverge)
    if speechQueue and #speechQueue > 0 then
        for _, string in ipairs(speechQueue) do
            Speak(string)
        end
    end
end

---Builds and applies a focus path to a given widget
---@param widget UIWidget
function UIScreenManager:SetFocus(widget)
    local path = self.BuildFocusPath(widget)
    self:ApplyFocus(path)
end

---Global input handler: Calls the widget's local 'OnHandleInput' if any, starting from deepest focused widget
---Note: make sure to manually set this input handler for every context that requires it. See 'UI/MainMenu.lua' for an example
---@param input InputStruct
---@return boolean --True if input was handled
function UIScreenManager:HandleInput(input)
    local current = self:GetFocusedWidget()
    while current do
        if current.OnHandleInput then
            local handled = current:OnHandleInput(input)
            if handled then
                return true
            end
        end

        current = current.Parent
    end

    return false
end

---Handles character input (text input), bubbling from focused widget upward
---@param char string
---@return boolean -- true if handled
function UIScreenManager:HandleCharInput(char)
    local current = self:GetFocusedWidget()

    while current do
        if current.OnCharInput then
            local handled = current:OnCharInput(char)
            if handled then
                return true
            end
        end

        current = current.Parent
    end

    return false
end

---Clears the manager's widget stack. Also destroys all widgets
function UIScreenManager:Clear()
    local root = self:GetTop()
    if root then root:Destroy() end
    self.Stack = {}
end

---Check for whether the manager's stack is empty
---@return boolean
function UIScreenManager:IsEmpty()
    return #self.Stack == 0
end

---Checks if the widget exists in the manager's stack
---@param w UIWidget
---@return boolean
function UIScreenManager:HasWidget(w)
    for _, widget in ipairs(self.Stack) do
        if widget == w then return true end
    end
    return false
end

---Adds a char to the search buffer
---@param c string
function UIScreenManager:AppendSearchChar(c)
    local now = os.clock()
    if not self.LastTypeTime or (now - self.LastTypeTime) > self.CAISettings.SearchTimeout then
        self.SearchBuffer = ""
    end

    self.LastTypeTime = now
    self.SearchBuffer = (self.SearchBuffer or "") .. c:lower()
end

--#Life cycle
function UIScreenManager:Init()
    if not ExposedMembers.CAI_UIManager then
    ExposedMembers.CAI_UIManager = self:New()
    end
    local mgr = ExposedMembers.CAI_UIManager
    CAI.RegisterGlobalCharInputHandler(function(char)
        return mgr:HandleCharInput(char)
    end)
end

function UIScreenManager:ShutDown()
    ExposedMembers.CAI_UIManager = nil
    CAI.UnregisterGlobalCharInputHandler()
    Speak("Shutting down manager")
end

UIScreenManager:Init()