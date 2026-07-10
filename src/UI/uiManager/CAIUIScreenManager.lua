-- CAIUIScreenManager.lua
-- Entry point for the CAI UI manager: stack, focus path, input dispatch, speech.
-- Focus is authoritative on the manager (CurrentPath); containers only cache a
-- _lastFocusedChild hint for restoring focus when re-entered.

include("caiUtils")
include("InputSupport")
include("audioManager_CAI")
include("CAIWidgetHelpers_Navigation")
include("CAIWidgetHelpers_Search")
include("CAIWidgetHelpers_Tree")
include("CAIWidgetHelpers_EditBox")
include("CAIWidgetHelpers_DialogBuilder")
include("CAIWidgetHelpers_PediaLookup")
include("CAIWidgetHelpers_Settings")
include("CAIWidgetHelpers_InputHelp")
include("CAIWidgetHelpers_TooltipReader")
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
include("CAIWidget_SearchPanel")

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
    local mgr = setmetatable({}, { __index = UIScreenManager })
    mgr.Stack = {}
    mgr.CurrentPath = {}
    mgr.NextStackOrder = 0
    mgr.NextWidgetId = 0
    mgr.WidgetHelpers = {}
    mgr.AppRegainedFocusTime = 0
    mgr.SearchBufferExpireTime = nil
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
--- ignoreFocus: boolean, if true focus is not updated (used by screens that push a widget but don't expect you to interact with it currently).
--- announce:  boolean, if true the new focus path is spoken (default true).
---@param w UIWidget
---@param opts? { priority?: PopupPriority, focus?: UIWidget|string, ignoreFocus?: boolean, announce?: boolean }
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

    -- Ignore updating focus if ops.ignoreFocus is true. This is used by screens that want to push a widget but not expect you to interact with it currently. Normally priority would take care of this, but some screens push on async events and so priority is not effective.
    if opts.ignoreFocus then return end
    -- Resolve opts.focus up-front. When we have a specific target we set
    -- focus straight to it so the full path [root, ..., target] speaks in a
    -- single announcement; otherwise fall back to the default root entry.
    local target = opts.focus
    if type(target) == "string" then target = self:FindByFocusKey(w, target) end
    local willFocusTarget = target ~= nil and newTop == w

    if willFocusTarget then
        if CAI and CAI.Silence then CAI.Silence() end
        self:SetFocus(target)
    elseif newTop ~= oldTop or not self.CurrentPath or self.CurrentPath[1] ~= newTop then
        local announce = opts.announce
        if announce == nil then announce = true end
        self:UpdateRootFocus(announce)
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
    -- If the target sits inside collapsed expandable ancestors, expand them
    -- (silently — no speech, no expand/collapse events) so the focus leaf is
    -- actually reachable and visible. The target itself keeps its own state.
    for i = 1, #path - 1 do
        local anc = path[i]
        if anc.IsExpanded == false and anc.Expand then
            anc:Expand(true)
        end
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
                if s then out[#out + 1] = s end
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
---Resets the timer for app regained focus. Used to prevent input from leaking when focus lands on the window, causing you to accidentally escape screens or trigger input actions
function UIScreenManager:TouchAppRegainedFocusTimer() self.AppRegainedFocusTime = Automation.GetTime() end

---@param input InputStruct
---@return boolean
function UIScreenManager:HandleInput(input)
    local msg = input:GetMessageType()
    if msg == KeyEvents.KeyUp then
        local key = input:GetKey()
        if key == Keys.VK_ESCAPE and self:ClearSearchBuffer(true) then
            return true
        end
        if key == Keys.VK_BACK then
            local node = self:GetFocusedWidget()
            while node do
                if not node:IsHidden() and node.OnSearchBackspace then
                    if node:OnSearchBackspace() then return true end
                end
                node = node.Parent
            end
        end
    end
    if self.AppRegainedFocusTime > 0 and (Automation.GetTime() - self.AppRegainedFocusTime) <= 0.25 then return true end
    local node = self:GetFocusedWidget()
    while node do
        if not node:IsHidden() and node.OnHandleInput then
            if node:OnHandleInput(input) or node.TrapInput then
                return true
            end
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
            -- Don't descend through a node that is now collapsed (an expandable
            -- whose IsExpanded is false): the captured position pointed inside a
            -- subtree the rebuild left closed, so land on the collapsed node
            -- rather than silently re-opening it (which auto-entered submenus /
            -- tree items). The captured key, if any, already had first crack.
            if node ~= root and node.Expand and node.IsExpanded == false then break end
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

---Seed the _lastFocusedKey / _lastFocusedChild cache from `root` down to the
---widget matching `key`, without moving global focus. Use this when the target
---subtree is not the current stack top (e.g. a rebuild happened while a modal
---capture widget was pushed). When the modal pops and focus naturally descends
---back into the subtree, GetDefaultChild will follow the seeded cache to the
---correct widget. Also expands collapsed TreeItem ancestors silently.
---@param root UIWidget
---@param key string
---@return boolean
function UIScreenManager:PrepareFocus(root, key)
    if not root or not key then return false end
    local match = self:FindByFocusKey(root, key)
    if not match then return false end
    local chain = {}
    local node = match
    while node and node ~= root do
        table.insert(chain, 1, node)
        node = node.Parent
    end
    if node ~= root then return false end
    local parent = root
    for _, child in ipairs(chain) do
        parent._lastFocusedChild = child
        parent._lastFocusedKey = child.FocusKey
        if parent.IsExpanded == false and parent.Expand then
            parent:Expand(true)
        end
        parent = child
    end
    return true
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

function UIScreenManager:ExpireSearchBufferIfNeeded()
    local expireTime = self.SearchBufferExpireTime
    if expireTime ~= nil and Automation.GetTime() >= expireTime then
        self.SearchBuffer = ""
        self.LastTypeTime = nil
        self.SearchBufferExpireTime = nil
        return true
    end
    return false
end

function UIScreenManager:TouchSearchBufferTimer()
    self:ExpireSearchBufferIfNeeded()
    local buffer = self.SearchBuffer or ""
    local timeout = CAISettings.GetNumber("SearchTimeout")

    if buffer == "" or timeout <= 0 then
        self.SearchBufferExpireTime = nil
        return
    end

    self.SearchBufferExpireTime = Automation.GetTime() + timeout
end

function UIScreenManager:OnUpdate()
    self:ExpireSearchBufferIfNeeded()
    self:UpdateAudioManager()
end

---@param announce? boolean
---@return boolean
function UIScreenManager:ClearSearchBuffer(announce)
    local buffer = self:GetSearchBuffer()
    if buffer == "" then
        return false
    end

    self.SearchBuffer = ""
    self.LastTypeTime = nil
    self.SearchBufferExpireTime = nil

    if announce then
        Speak(Locale.Lookup("LOC_CAI_SEARCH_CLEARED"))
    end

    return true
end

---@return string
function UIScreenManager:RemoveSearchChar()
    local buffer = self:GetSearchBuffer()
    if buffer == "" then
        return ""
    end

    if #buffer <= 1 then
        self.SearchBuffer = ""
        self.LastTypeTime = nil
        self.SearchBufferExpireTime = nil
        return ""
    end

    self.SearchBuffer = string.sub(buffer, 1, #buffer - 1)
    self.LastTypeTime = Automation.GetTime()
    self:TouchSearchBufferTimer()
    return self.SearchBuffer
end

---@param c string
function UIScreenManager:AppendSearchChar(c)
    self:ExpireSearchBufferIfNeeded()
    local now = Automation.GetTime()
    self.LastTypeTime = now
    self.SearchBuffer = (self.SearchBuffer or "") .. c:lower()
    self:TouchSearchBufferTimer()
end

function UIScreenManager:GetSearchBuffer()
    self:ExpireSearchBufferIfNeeded()
    return self.SearchBuffer or ""
end

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

--#region Search

function UIScreenManager:OpenSearch(container)
    if not container then return end
    if self._searchPanel then
        self._searchPanel:Close(true)
    end
    local panel = self:CreateWidget(self:GenerateWidgetId("CAI_SearchPanel"), "SearchPanel")
    if not panel then return end
    self._searchPanel = panel
    local handler = container.GetSearchQueryHandler and container:GetSearchQueryHandler() or nil
    panel:SetQueryHandler(handler)
    local historyCtx = container.GetSearchHistoryContext and container:GetSearchHistoryContext()
    panel:SetHistoryContext(historyCtx or container.Id or "default")
    panel:Open(container)
end

---@return SearchPanelWidget|nil
function UIScreenManager:GetSearchPanel()
    return self._searchPanel
end

--#endregion

--#region Lifecycle

function UIScreenManager:GetAudioManager()
    return self.AudioManager
end

function UIScreenManager:InitializeAudioManager()
    if self.AudioManager == nil then
        self.AudioManager = CAIAudioManager:New()
    end

    self.AudioManager:Initialize(self)
    ExposedMembers.CAI_AudioManager = self.AudioManager
end

function UIScreenManager:UpdateAudioManager()
    local audio = self:GetAudioManager()
    if audio ~= nil then
        audio:Update()
    end
end

function UIScreenManager:ShutdownAudioManager()
    local audio = self:GetAudioManager()
    if audio == nil then
        ExposedMembers.CAI_AudioManager = nil
        return
    end

    audio:Shutdown()
    self.AudioManager = nil
    ExposedMembers.CAI_AudioManager = nil
end

function UIScreenManager:Init()
    ExposedMembers.CAI_UIManager = self:New()
    local mgr = ExposedMembers.CAI_UIManager
    mgr:InitializeAudioManager()
    if CAIWidgetHelpers_DialogBuilder and CAIWidgetHelpers_DialogBuilder.Install then
        CAIWidgetHelpers_DialogBuilder.Install(mgr)
    end
    if CAI and CAI.RegisterGlobalCharInputHandler then
        CAI.RegisterGlobalCharInputHandler(function(char)
            return mgr:HandleCharInput(char)
        end)
    end
    LuaEvents.CAIUIManagerInitialized(mgr)
end

function UIScreenManager:ShutDown(unregCharInput, preserveAudio)
    if preserveAudio ~= true then
        self:ShutdownAudioManager()
    end
    if preserveAudio ~= true then
        ExposedMembers.CAI_UIManager = nil
    end
    if unregCharInput == nil then unregCharInput = true end
    if unregCharInput and CAI and CAI.UnregisterGlobalCharInputHandler then
        CAI.UnregisterGlobalCharInputHandler()
    end
end

UIScreenManager:Init()

--#endregion
