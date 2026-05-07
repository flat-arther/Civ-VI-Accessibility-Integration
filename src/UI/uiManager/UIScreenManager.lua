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
        SearchTimeout = 1.0,
        ValidateWidgetIds = false
    }
}

--#Includes
include("caiUtils")
include("InputSupport")
include("baseWidget")
include("widgetTemplateHelpers")
include("widgetTemplates")
--#Methods
---Creates a new instance of the UI manager
---@return UIScreenManager
function UIScreenManager:New()
    Speak(Locale.Lookup("LOC_CAI_CREATING_UI_MANAGER"))
    local mgr = setmetatable({}, { __index = UIScreenManager })
    mgr.Stack = {}
    mgr.CurrentPath = {}
    mgr.NextStackOrder = 0
    mgr.NextWidgetId = 0
    mgr.WidgetTemplateHelpers = WidgetTemplateHelpers
    mgr.WidgetTemplateHelpers.Manager = mgr
    return mgr
end

---@param prefix string
---@return string
function UIScreenManager:GenerateWidgetId(prefix)
    self.NextWidgetId = (self.NextWidgetId or 0) + 1
    prefix = prefix or "CAIWidget"
    return string.format("%s%04d", prefix, self.NextWidgetId)
end

---Creates a UI widget given a unique id, type, and optional properties table
---@param id string ---Unique widget id used for lookup
---@param type string ---The type of widget to create. This should correspond to a key in 'WidgetTemplates'. If not, the props table must not be nil or empty
---@param props? table ---A table of properties to override the widget template's defaults. This is optional if you use a template
---@return UIWidget|nil --The created widget, or nil if the type was invalid
function UIScreenManager:CreateUIWidget(id, type, props)
    if not id or id == "" then
        print("CAI CreateUIWidget missing widget id")
        return
    end
    local template = WidgetTemplates[type]
    if not template and not props then return end
    local w = setmetatable({}, { __index = UIWidget }) ---@type UIWidget

    w.Id = id
    w.Manager = self
    w.Type = type
    w.Children = {}
    w.InputMap = {}
    w.SpeechSettings = {}
    w.FocusedChild = nil

    if template then
        for k, v in pairs(template) do
            w[k] = v
        end
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

---Sorts the stack so the last entry is always the active root. Priority wins;
---equal priority falls back to push order, preserving normal stack behavior.
function UIScreenManager:SortStack()
    table.sort(self.Stack, function(a, b)
        local aPriority = a and a.__priority or PopupPriority.Low
        local bPriority = b and b.__priority or PopupPriority.Low
        if aPriority ~= bPriority then
            return aPriority < bPriority
        end

        local aOrder = a and a.__stackOrder or 0
        local bOrder = b and b.__stackOrder or 0
        return aOrder < bOrder
    end)
end

---Adds a UI widget to the stack. The active root is chosen by priority, then by
---push order for ties.
---@param w UIWidget
---@param priority? PopupPriority
function UIScreenManager:Push(w, priority)
    if not w then return end
    if self.CAISettings and self.CAISettings.ValidateWidgetIds then
        self:WarnIfDuplicateWidgetId(w)
    end

    local oldTop = self:GetTop()
    local oldPriority = oldTop and oldTop.__priority
    self.NextStackOrder = (self.NextStackOrder or 0) + 1
    w.__priority = priority or w.__priority or oldPriority or PopupPriority.Low
    w.__stackOrder = self.NextStackOrder
    table.insert(self.Stack, w)
    self:SortStack()
    local newTop = self:GetTop()
    if newTop ~= oldTop or not self.CurrentPath or self.CurrentPath[1] ~= newTop then
        self:UpdateRootFocus()
    end
end

---Updates focus to the active root after push/pop/sort changes.
function UIScreenManager:UpdateRootFocus()
    if #self.Stack == 0 then
        self.CurrentPath = {}
        return
    end

    local current = self.CurrentPath[1]
    local top = self:GetTop()
    if not top then return end
    if current == top then return end

    CAI.Silence()
    self:SetFocus(top)
end

---Removes a widget from the stack. Defaults to the active root.
---@return UIWidget|nil
function UIScreenManager:Pop()
    if #self.Stack == 0 then return nil end
    local w = table.remove(self.Stack, #self.Stack)
    if w then
        w.__priority = nil
        w.__stackOrder = nil
        w:Destroy()
    end

    self:UpdateRootFocus()
    return w
end

---Removes a widget root from the stack by id.
---@param id string
---@return UIWidget|nil
function UIScreenManager:RemoveFromStack(id)
    if not id or id == "" then return nil end
    if #self.Stack == 0 then return nil end

    for i = #self.Stack, 1, -1 do
        local w = self.Stack[i]
        local widgetId = w:GetId()
        if widgetId == id then
            table.remove(self.Stack, i)
            w.__priority = nil
            w.__stackOrder = nil
            w:Destroy()
            self:UpdateRootFocus()
            return w
        end
    end

    return nil
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
            local ignore = ((current.SpeechSettings and current.SpeechSettings.IgnoreWhenNotFocused) and self:GetFocusedWidget() ~= current) or
                false
            if not ignore then
                local speech = current:BuildSpeech()
                if speech then table.insert(announcements, speech) end
            end
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
        local w = newPath[i]
        local next = newPath[i + 1]
        if w.Expand then w:Expand() end
        w.FocusedChild = next
    end

    self.CurrentPath = newPath

    local speechQueue = self:BuildAnnouncement(newPath, diverge)
    if speechQueue and #speechQueue > 0 then
        for _, string in ipairs(speechQueue) do
            Speak(ProcessIcons(string))
        end
    end
end

---Builds and applies a focus path to a given widget
---@param widget UIWidget
---@return boolean
function UIScreenManager:SetFocus(widget)
    local path = self.BuildFocusPath(widget)
    return self:SetFocusPath(path)
end

---Applies a prebuilt focus path directly.
---@param path UIWidget[]|nil
---@return boolean
function UIScreenManager:SetFocusPath(path)
    if not path or #path == 0 then return false end
    if path[1] ~= self:GetTop() then return false end
    self:ApplyFocus(path)
    return true
end

---Capture the focused child-index path from a container root down to the
---current focused descendant.
---@param root UIWidget
---@return integer[]|nil
function UIScreenManager:CaptureFocusIndexPath(root)
    if not root then return nil end

    local focused = self:GetFocusedWidget()
    if not focused then return nil end

    local path = {}
    local node = focused
    while node and node ~= root do
        local parent = node.Parent
        if not parent then return nil end
        local idx = parent:GetChildIndex(node)
        if not idx then return nil end
        table.insert(path, 1, idx)
        node = parent
    end

    if node ~= root or #path == 0 then return nil end
    return path
end

---Build a full widget focus path from a container root plus child indexes.
---@param root UIWidget
---@param indexPath integer[]|nil
---@return UIWidget[]|nil
function UIScreenManager:BuildFocusPathFromIndexPath(root, indexPath)
    if not root or not indexPath or #indexPath == 0 then return nil end

    local path = {}
    local current = root
    while current do
        table.insert(path, 1, current)
        current = current.Parent
    end

    local node = root
    for _, rawIdx in ipairs(indexPath) do
        if not node.Children or #node.Children == 0 then break end

        local idx = rawIdx
        if idx < 1 then idx = 1 end
        if idx > #node.Children then idx = #node.Children end

        local child = node.Children[idx]
        local hidden = child and child.IsHidden and child:IsHidden() or false
        if hidden then
            child = self.WidgetTemplateHelpers:FindVisibleChild(node, idx - 1, 1, true)
                or self.WidgetTemplateHelpers:FindFirstVisibleChild(node)
        end
        if not child then break end

        node.FocusedChild = child
        table.insert(path, child)
        node = child
    end

    return #path > 0 and path or nil
end

---Build and apply focus from a container root plus child indexes.
---@param root UIWidget
---@param indexPath integer[]|nil
---@return boolean
function UIScreenManager:SetFocusIndexPath(root, indexPath)
    if not root or not indexPath or #indexPath == 0 then return false end
    local path = self:BuildFocusPathFromIndexPath(root, indexPath)
    if not path then return false end
    return self:SetFocusPath(path)
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
    self.CurrentPath = {}
    while #self.Stack > 0 do
        local root = table.remove(self.Stack)
        if root then
            root.__priority = nil
            root.__stackOrder = nil
            root:Destroy()
        end
    end
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

---@param id string
---@param recurse? boolean
---@return UIWidget|nil
function UIScreenManager:GetWidgetById(id, recurse)
    if not id or id == "" then return nil end

    for i = #self.Stack, 1, -1 do
        local match = self:FindWidgetByIdInTree(self.Stack[i], id, recurse)
        if match then return match end
    end
    return nil
end

---@param candidate UIWidget
---@param root? UIWidget
function UIScreenManager:WarnIfDuplicateWidgetId(candidate, root)
    if not candidate or not candidate.Id or candidate.Id == "" then return end
    local existing = self:GetWidgetById(candidate.Id, true)
    if existing == candidate then existing = nil end
    if not existing and root then
        existing = self:FindWidgetByIdInTree(root, candidate.Id, true, candidate)
    end
    if existing then
        print("CAI duplicate widget id: " .. tostring(candidate.Id))
    end
end

---@param root UIWidget
---@param id string
---@param recurse? boolean
---@param ignore? UIWidget
---@return UIWidget|nil
function UIScreenManager:FindWidgetByIdInTree(root, id, recurse, ignore)
    if not root or not id or id == "" then return nil end
    if root ~= ignore and root.Id == id then return root end
    if recurse and root.Children then
        for _, child in ipairs(root.Children) do
            local match = self:FindWidgetByIdInTree(child, id, recurse, ignore)
            if match then return match end
        end
    end
    return nil
end

---Adds a char to the search buffer
---@param c string
function UIScreenManager:AppendSearchChar(c)
    local now = Automation.GetTime()
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
