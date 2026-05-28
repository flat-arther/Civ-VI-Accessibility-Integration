-- CAIUIScreenManager.lua
-- Entry point for the CAI UI manager: stack, focus path, input dispatch, speech.
-- Focus is authoritative on the manager (CurrentPath); containers only cache a
-- _lastFocusedChild hint for restoring focus when re-entered.

include("caiUtils")
include("InputSupport")
include("CAIWidgetHelpers_Navigation")
include("CAIWidgetHelpers_Search")
include("CAIWidgetHelpers_Tree")
include("CAIWidgetHelpers_EditBox")
include("CAIWidgetHelpers_DialogBuilder")
include("CAIWidget_Base")
include("CAIWidget_Container")
include("CAIWidget_Value")
include("CAIWidgetRegistry")
include("CAIWidget_Button")
include("CAIWidget_MenuItem")
include("CAIWidget_StaticText")
include("CAIWidget_Panel")
include("CAIWidget_Dialog")
include("CAIWidget_List")
include("CAIWidget_HorizontalList")
include("CAIWidget_SubMenu")
include("CAIWidget_Dropdown")
include("CAIWidget_Tree")
include("CAIWidget_TreeItem")
include("CAIWidget_Checkbox")
include("CAIWidget_Slider")
include("CAIWidget_EditBox")
include("CAIWidget_Tab")
include("CAIWidget_TabPage")
include("CAIWidget_TabControl")
include("CAIWidget_Table")
include("CAIWidget_GameView")
include("CAIWidget_InterfaceMode")

---@class UIScreenManager
---@field Stack UIWidget[]
---@field CurrentPath UIWidget[]
---@field CAISettings table<string, any>
---@field WidgetHelpers table<string, function> Manager-bound quick widget helpers (dialog builders, etc.) installed by helper modules at init time.
UIScreenManager = {
    CAISettings = {
        speakLabel = true,
        speakRole = true,
        speakValue = true,
        speakPosition = true,
        speakState = true,
        speakTooltip = true,
        SearchTimeout = 1.0,
        ValidateWidgetIds = false,
    },
}

---@return UIScreenManager
function UIScreenManager:New()
    Speak(Locale.Lookup("LOC_CAI_CREATING_UI_MANAGER"))
    local mgr = setmetatable({}, { __index = UIScreenManager })
    mgr.Stack = {}
    mgr.CurrentPath = {}
    mgr.NextStackOrder = 0
    mgr.NextWidgetId = 0
    mgr.WidgetHelpers = {}
    return mgr
end

---@param prefix? string
---@return string
function UIScreenManager:GenerateWidgetId(prefix)
    self.NextWidgetId = (self.NextWidgetId or 0) + 1
    prefix = prefix or "CAIWidget"
    return string.format("%s%04d", prefix, self.NextWidgetId)
end

---Construct a widget through the registry. Type must be registered.
---@param id string
---@param type string
---@param props? table
---@return UIWidget|nil
function UIScreenManager:CreateWidget(id, type, props)
    if not id or id == "" then
        print("CAI CreateWidget: missing id for type " .. tostring(type))
        return nil
    end
    local ctor = CAIWidgetRegistry.GetCtor(type)
    if not ctor then
        print("CAI CreateWidget: unknown type " .. tostring(type))
        return nil
    end
    return ctor(self, id, props)
end

--#region Stack

function UIScreenManager:SortStack()
    table.sort(self.Stack, function(a, b)
        local ap = a and a.__priority or PopupPriority.Low
        local bp = b and b.__priority or PopupPriority.Low
        if ap ~= bp then return ap < bp end
        local ao = a and a.__stackOrder or 0
        local bo = b and b.__stackOrder or 0
        return ao < bo
    end)
end

---Push a widget root onto the stack. Optional opts:
---  priority: PopupPriority override for stack sort.
---  focus:    UIWidget or string FocusKey to focus once mounted (when the pushed
---            widget becomes the new top). Avoids screens reaching into
---            FocusedChild to pre-position focus.
---@param w UIWidget
---@param opts? { priority?: PopupPriority, focus?: UIWidget|string }
function UIScreenManager:Push(w, opts)
    if not w then return end
    opts = opts or {}
    if type(opts) == "number" then opts = { priority = opts } end -- legacy convenience
    local oldTop = self:GetTop()
    local oldPriority = oldTop and oldTop.__priority
    self.NextStackOrder = (self.NextStackOrder or 0) + 1
    w.__priority = opts.priority or w.__priority or oldPriority or PopupPriority.Low
    w.__stackOrder = self.NextStackOrder
    table.insert(self.Stack, w)
    self:SortStack()
    local newTop = self:GetTop()

    -- Resolve opts.focus up-front. When we have a specific target we set
    -- focus straight to it so the full path [root, ..., target] speaks in a
    -- single announcement; otherwise fall back to the default root entry.
    local target = opts.focus
    if type(target) == "string" then target = self:FindByFocusKey(w, target) end
    local willFocusTarget = target ~= nil and newTop == w

    if willFocusTarget then
        self:SetFocus(target)
    elseif newTop ~= oldTop or not self.CurrentPath or self.CurrentPath[1] ~= newTop then
        self:UpdateRootFocus(true)
    end
end

---@param announce? boolean defaults true; pass false to suppress speech
function UIScreenManager:UpdateRootFocus(announce)
    if #self.Stack == 0 then
        self.CurrentPath = {}
        return
    end
    local top = self:GetTop()
    if not top or self.CurrentPath[1] == top then return end
    if CAI and CAI.Silence then CAI.Silence() end
    self:SetFocus(top, { announce = announce ~= false })
end

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

---@param id string
---@return UIWidget|nil
function UIScreenManager:RemoveFromStack(id)
    if not id or id == "" then return nil end
    for i = #self.Stack, 1, -1 do
        local w = self.Stack[i]
        if w:GetId() == id then
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

---@return UIWidget|nil
function UIScreenManager:GetTop() return self.Stack[#self.Stack] end

function UIScreenManager:IsEmpty() return #self.Stack == 0 end

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

--#endregion

--#region Focus path

---@return UIWidget|nil
function UIScreenManager:GetFocusedWidget()
    local path = self.CurrentPath
    if not path or #path == 0 then return nil end
    return path[#path]
end

---Walk parent chain up from widget, then descend to a leaf. When direction is
---set the descent uses each container's GetEntryChild(direction) so forward
---navigation enters at first-visible and backward at last-visible (Windows
---tab-stop convention). Otherwise it uses GetDefaultChild for re-entry /
---programmatic focus.
---@param widget UIWidget
---@param direction? 1|-1
---@return UIWidget[]
function UIScreenManager.BuildFocusPath(widget, direction)
    local path = {}
    local node = widget
    while node do
        table.insert(path, 1, node)
        node = node.Parent
    end
    local leaf = path[#path]
    while leaf do
        local child
        if direction and leaf.GetEntryChild then
            child = leaf:GetEntryChild(direction)
        elseif leaf.GetDefaultChild then
            child = leaf:GetDefaultChild()
        else
            break
        end
        if not child or child:IsHidden() then break end
        table.insert(path, child)
        leaf = child
    end
    return path
end

---@param oldPath UIWidget[]
---@param newPath UIWidget[]
---@return integer
function UIScreenManager.FindDivergence(oldPath, newPath)
    local len = math.min(#oldPath, #newPath)
    local i = 1
    while i <= len and oldPath[i] == newPath[i] do i = i + 1 end
    if i > #newPath and #newPath > 0 then return #newPath end
    return i
end

---@param newPath UIWidget[]
---@return UIWidget[], integer
function UIScreenManager:ApplyFocus(newPath)
    local oldPath = self.CurrentPath or {}
    local diverge = self.FindDivergence(oldPath, newPath)

    -- Commit the new path BEFORE firing events. This makes IsFocused() and
    -- GetFocusedWidget() reflect the post-change state inside focus_enter /
    -- focus_leave handlers, matching the documented contract. Speech still
    -- runs after ApplyFocus returns (in SetFocusPath), so handlers can update
    -- vanilla state before TTS reads it. The old path is still available via
    -- the focus_leave event's extra arg for handlers that need it.
    self.CurrentPath = newPath

    for i = #oldPath, diverge, -1 do
        local w = oldPath[i]
        if w then w:Emit("focus_leave", oldPath, i) end
    end

    for i = diverge, #newPath do
        local w = newPath[i]
        if w then w:Emit("focus_enter", newPath, i) end
    end

    -- Cache focused-child hints on each parent. _lastFocusedKey takes priority
    -- because it survives rebuilds; _lastFocusedChild is the widget-ref fallback.
    for i = 1, #newPath - 1 do
        local parent = newPath[i]
        local child = newPath[i + 1]
        parent._lastFocusedChild = child
        parent._lastFocusedKey = child.FocusKey
    end

    -- Play one focus sound per focus change: the deepest newly-entered widget
    -- that has _focusSound wins. Avoids stacking sounds when a Panel, its
    -- List, and the focused row all set sounds.
    if UI and UI.PlaySound then
        for i = #newPath, diverge, -1 do
            local w = newPath[i]
            if w and w._focusSound then
                UI.PlaySound(w._focusSound)
                break
            end
        end
    end

    return newPath, diverge
end

---@param path UIWidget[]
---@param diverge integer
---@return string[]
function UIScreenManager:BuildAnnouncement(path, diverge)
    local out = {}
    local focused = self:GetFocusedWidget()
    for i = diverge, #path do
        local w = path[i]
        if w and not w.Transparent and w.BuildSpeech then
            local settings = w.SpeechSettings or {}
            local skip = settings.IgnoreWhenNotFocused and w ~= focused
            if not skip then
                local s = w:BuildSpeech()
                if s then out[#out + 1] = ProcessIcons(s) end
            end
        end
    end
    return out
end

---Focus a widget. opts.direction (1 forward, -1 backward) controls how
---container descent picks its entry child — pass it from Tab/Shift+Tab /
---arrow nav so Shift+Tab into a row lands on its last button (Windows
---convention). Programmatic focus (RestoreFocus, Push focus) omits direction
---and uses the cached default. opts.announce defaults to true.
---@param widget UIWidget
---@param opts? boolean|{ direction?: 1|-1, announce?: boolean }
---@return boolean
function UIScreenManager:SetFocus(widget, opts)
    if type(opts) == "boolean" then opts = { announce = opts } end
    opts = opts or {}
    local path = self.BuildFocusPath(widget, opts.direction)
    return self:SetFocusPath(path, nil, opts.announce)
end

---@param path UIWidget[]|nil
---@param root? UIWidget
---@param announce? boolean
---@return boolean
function UIScreenManager:SetFocusPath(path, root, announce)
    if not path or #path == 0 then return false end
    if root == nil then root = self:GetTop() end
    if path[1] ~= root then return false end
    local newPath, diverge = self:ApplyFocus(path)
    if announce == nil then announce = true end
    if announce then
        -- Focus speech never interrupts: callers that need to interrupt (e.g.
        -- "Jumping to X" feedback before a ref-link jump) should Speak with
        -- interrupt=true themselves and let the focus lines queue behind.
        SpeakLines(self:BuildAnnouncement(newPath, diverge), false)
    end
    return true
end

---Re-speak the current focus leaf without re-firing focus_enter/leave. Use
---after a focused widget's data changes externally.
function UIScreenManager:Refocus()
    local path = self.CurrentPath
    if not path or #path == 0 then return end
    SpeakLines(self:BuildAnnouncement(path, #path), false)
end

--#endregion

--#region Input

---@param input InputStruct
---@return boolean
function UIScreenManager:HandleInput(input)
    local node = self:GetFocusedWidget()
    while node do
        if not node:IsHidden() and node.OnHandleInput then
            if node:OnHandleInput(input) then return true end
        end
        node = node.Parent
    end
    return false
end

---@param char string
---@return boolean
function UIScreenManager:HandleCharInput(char)
    local node = self:GetFocusedWidget()
    while node do
        if not node:IsHidden() and node.OnCharInput then
            if node:OnCharInput(char) then return true end
        end
        node = node.Parent
    end
    return false
end

--#endregion

--#region Focus keys + rebuild restoration

---Depth-first search rooted at `root` for a widget whose FocusKey matches.
---@param root UIWidget
---@param key string
---@return UIWidget|nil
function UIScreenManager:FindByFocusKey(root, key)
    if not root or not key then return nil end
    if root.FocusKey == key then return root end
    if root.Children then
        for _, child in ipairs(root.Children) do
            local m = self:FindByFocusKey(child, key)
            if m then return m end
        end
    end
    return nil
end

---Capture the currently focused widget's position under `root` so it can be
---restored after a rebuild. Returns nil if focus is not inside root. The
---capture is opaque — pass it to RestoreFocus.
---@param root UIWidget
---@return { key?: string, path: integer[] }|nil
function UIScreenManager:CaptureFocusKey(root)
    if not root then return nil end
    local focused = self:GetFocusedWidget()
    if not focused then return nil end
    local indices = {}
    local key = nil
    local node = focused
    while node and node ~= root do
        if not key and node.FocusKey then key = node.FocusKey end
        local parent = node.Parent
        if not parent then return nil end
        local idx = parent:GetChildIndex(node)
        if idx == 0 then return nil end
        table.insert(indices, 1, idx)
        node = parent
    end
    if node ~= root then return nil end
    if #indices == 0 then return nil end
    return { key = key, path = indices }
end

---Restore focus inside `root` from a capture token. Scoped to the rebuilt
---subtree: a nil capture means focus was not inside root at capture time, so
---this is a no-op (the caller's rebuild should not steal focus from elsewhere
---or plant initial focus). Resolution order when capture is non-nil:
---  1. Match by FocusKey via DFS.
---  2. Walk the captured index path, clamping and skipping hidden children.
---  3. Fall back to the first visible child of root (item under focus went away).
---@param root UIWidget
---@param capture { key?: string, path?: integer[] }|nil
---@return boolean
function UIScreenManager:RestoreFocus(root, capture)
    if not root then return false end
    if not capture then return false end
    if capture.key then
        local match = self:FindByFocusKey(root, capture.key)
        if match then
            -- FocusKey match means the rebuild replaced the widget object but
            -- the logical focus position is unchanged. Restore silently so a
            -- passive refresh doesn't re-speak or interrupt. (Checking the
            -- current focused leaf doesn't work here: ClearChildren has
            -- already pruned the old leaf via NotifyDestroy, so capture.key
            -- itself is the evidence the previous leaf carried that key.)
            return self:SetFocus(match, { announce = false })
        end
    end
    if capture.path then
        local Nav = CAIWidgetHelpers_Navigation
        local node = root
        for _, idx in ipairs(capture.path) do
            local children = node.Children
            if not children or #children == 0 then break end
            local i = idx
            if i < 1 then i = 1 end
            if i > #children then i = #children end
            local child = children[i]
            if child:IsHidden() then
                child = Nav.FindVisible(node, i - 1, 1, true) or Nav.First(node)
            end
            if not child then break end
            node = child
        end
        if node and node ~= root then return self:SetFocus(node) end
    end
    local Nav = CAIWidgetHelpers_Navigation
    local first = Nav.First(root)
    if first then return self:SetFocus(first) end
    return false
end

--#endregion

--#region Destroy pruning

---Called by UIWidget:Destroy. Truncates CurrentPath from the destroyed widget
---onward (silently — no focus_leave or speech) so input dispatch and later
---SetFocus calls don't dereference dead widgets. Screens that follow a rebuild
---with their own SetFocus are unaffected; screens that don't get a path that
---stops at the deepest surviving ancestor.
---@param w UIWidget
function UIScreenManager:NotifyDestroy(w)
    local path = self.CurrentPath
    if not path or #path == 0 then return end
    for i = 1, #path do
        if path[i] == w then
            for k = #path, i, -1 do path[k] = nil end
            return
        end
    end
end

--#endregion

--#region Type-to-find search buffer

---@param c string
function UIScreenManager:AppendSearchChar(c)
    local now = Automation.GetTime()
    local timeout = self.CAISettings.SearchTimeout or 1.0
    if not self.LastTypeTime or (now - self.LastTypeTime) > timeout then
        self.SearchBuffer = ""
    end
    self.LastTypeTime = now
    self.SearchBuffer = (self.SearchBuffer or "") .. c:lower()
end

function UIScreenManager:GetSearchBuffer() return self.SearchBuffer or "" end

--#endregion

--#region Lookup

---@param id string
---@param recurse? boolean
---@return UIWidget|nil
function UIScreenManager:GetWidgetById(id, recurse)
    if not id or id == "" then return nil end
    for i = #self.Stack, 1, -1 do
        local m = self:FindByIdInTree(self.Stack[i], id, recurse)
        if m then return m end
    end
    return nil
end

---@param root UIWidget
---@param id string
---@param recurse? boolean
---@return UIWidget|nil
function UIScreenManager:FindByIdInTree(root, id, recurse)
    if not root then return nil end
    if root.Id == id then return root end
    if recurse and root.Children then
        for _, child in ipairs(root.Children) do
            local m = self:FindByIdInTree(child, id, recurse)
            if m then return m end
        end
    end
    return nil
end

--#endregion

--#region Lifecycle

function UIScreenManager:Init()
    if not ExposedMembers.CAI_UIManager then
        ExposedMembers.CAI_UIManager = self:New()
    end
    local mgr = ExposedMembers.CAI_UIManager
    if CAIWidgetHelpers_DialogBuilder and CAIWidgetHelpers_DialogBuilder.Install then
        CAIWidgetHelpers_DialogBuilder.Install(mgr)
    end
    if CAI and CAI.RegisterGlobalCharInputHandler then
        CAI.RegisterGlobalCharInputHandler(function(char)
            return mgr:HandleCharInput(char)
        end)
    end
end

function UIScreenManager:ShutDown()
    ExposedMembers.CAI_UIManager = nil
    if CAI and CAI.UnregisterGlobalCharInputHandler then
        CAI.UnregisterGlobalCharInputHandler()
    end
    Speak("Shutting down manager")
end

UIScreenManager:Init()

--#endregion
