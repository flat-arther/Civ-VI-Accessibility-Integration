-- CAIWidget_TabControl.lua
-- Windows-style tab control that owns its tabs and pages. The widget's
-- Children list always holds [_tabStrip, activePage]; inactive pages live in
-- the private _pages array but are out of the tree until selected.
--
-- Tab.focus_enter calls _OnTabFocused so Left/Right in the strip immediately
-- swaps the active page. Ctrl+Tab / Ctrl+Shift+Tab cycles from anywhere
-- inside the control (input bubbles up to TabControl). Tab/Shift+Tab inside
-- the control behave like any ContainerWidget — strip is child 1, page is
-- child 2.

---@class TabControlWidget : ContainerWidget
---@field _tabs TabWidget[]
---@field _pages TabPageWidget[]
---@field _activeIndex integer
---@field _tabStrip ContainerWidget
TabControlWidget = setmetatable({}, { __index = ContainerWidget })
TabControlWidget.__index = TabControlWidget

local Nav = CAIWidgetHelpers_Navigation

-- Internal strip: HorizontalList-like container.
local function MakeTabStrip(mgr, ownerId)
    local strip = mgr:CreateWidget(ownerId .. "_Strip", "HorizontalList", {
        Label = function() return Locale.Lookup("LOC_CAI_TAB_STRIP_LABEL") end,
    })
    strip.SpeechSettings = { Role = false }
    return strip
end

---@param mgr UIScreenManager
---@param id string
---@param props? table
---@return TabControlWidget
function TabControlWidget.Create(mgr, id, props)
    local w = ContainerWidget.New(TabControlWidget)
    w.Id = id
    w.Type = "TabControl"
    w.Role = "TabControl"
    w.Manager = mgr
    w._tabs = {}
    w._pages = {}
    w._activeIndex = 0
    w.WrapAround = false
    -- The TabControl is a layout shell — the speakable structure the user
    -- cares about is the strip and the active page. Marking it Transparent
    -- suppresses its own announcement (role + label + position) on focus.
    w.Transparent = true

    w._tabStrip = MakeTabStrip(mgr, id)
    UIWidget.AddChild(w, w._tabStrip)

    w:AddInputBindings({
        { Key = Keys.VK_TAB, MSG = KeyEvents.KeyDown, IsControl = true,                  Action = function(self) return self:NextPage() end },
        { Key = Keys.VK_TAB, MSG = KeyEvents.KeyDown, IsControl = true, IsShift = true,  Action = function(self) return self:PreviousPage() end },
        -- Plain Tab keeps focus inside the TabControl as a cycle:
        --   strip -> (Tab) -> first child of page
        --   last child of page -> (Tab) -> active tab in strip
        -- The page's NavigateNext consumes Tab while children remain; only
        -- the boundary case bubbles here.
        { Key = Keys.VK_TAB, MSG = KeyEvents.KeyDown,                                    Action = function(self) return self:_TabForwardCycle() end },
        -- Symmetric reverse cycle: Shift+Tab from inside the page returns to
        -- the active tab; Shift+Tab from a tab in the strip bubbles so the
        -- user can exit the TabControl backward.
        { Key = Keys.VK_TAB, MSG = KeyEvents.KeyDown, IsShift = true,                    Action = function(self) return self:_ReturnToStripFromPage() end },
    })

    CAIWidgetRegistry.ApplyProps(w, props)
    return w
end

---Default focus entry skips the tab strip and lands on the active page so
---first-time entry into the TabControl places the user on page content.
---ExpandOrDescend-style strip access still works because Tabs are reachable
---via Shift+Tab from the page (_ReturnToStripFromPage) and the strip is the
---first child for backward containers descent.
---@return UIWidget|nil
function TabControlWidget:GetDefaultChild()
    return self:GetActivePage() or self._tabStrip
end

---@param direction 1|-1|0|nil
---@return UIWidget|nil
function TabControlWidget:GetEntryChild(direction)
    return self:GetActivePage() or self._tabStrip
end

--#region Focus location helpers

---True when the manager's focused leaf is the given subtree root or a descendant.
---@param subtreeRoot UIWidget|nil
---@return boolean
function TabControlWidget:_FocusInside(subtreeRoot)
    if not subtreeRoot then return false end
    local node = self.Manager and self.Manager:GetFocusedWidget()
    while node do
        if node == subtreeRoot then return true end
        node = node.Parent
    end
    return false
end

---Tab pressed: if focus is in the strip, move into the active page; otherwise
---let the event bubble.
---@param direction 1|-1
---@return boolean
function TabControlWidget:_EnterPageFromStrip(direction)
    if not self:_FocusInside(self._tabStrip) then return false end
    local page = self:GetActivePage()
    if not page then return false end
    self.Manager:SetFocus(page, { direction = direction })
    return true
end

---Forward-Tab cycle inside the TabControl. Bubbles in two cases:
---  * Focus is in the strip → step into the page (first child).
---  * Focus is in the page, NavigateNext already returned false (last child)
---    → wrap back to the active tab in the strip.
---@return boolean
function TabControlWidget:_TabForwardCycle()
    if self:_EnterPageFromStrip(1) then return true end
    local page = self:GetActivePage()
    if not self:_FocusInside(page) then return false end
    local tab = self._tabs[self._activeIndex]
    if not tab then return false end
    self.Manager:SetFocus(tab, { direction = 1 })
    return true
end

---Shift+Tab pressed: if focus is inside the active page, move back to the
---matching tab in the strip; otherwise let the event bubble.
---@return boolean
function TabControlWidget:_ReturnToStripFromPage()
    local page = self:GetActivePage()
    if not self:_FocusInside(page) then return false end
    local tab = self._tabs[self._activeIndex]
    if not tab then return false end
    self.Manager:SetFocus(tab, { direction = -1 })
    return true
end

--#endregion

--#region Active page management

local function MountActivePage(self)
    -- Children: index 1 is tab strip; index 2 (if present) is the active page.
    local kids = self.Children
    if kids[2] then
        kids[2].Parent = nil
        kids[2] = nil
    end
    local page = self._pages[self._activeIndex]
    if page then
        page.Parent = self
        kids[2] = page
    end
end

---Tab signaled focus_enter on itself; activate the matching page.
---@param tabIndex integer
function TabControlWidget:_OnTabFocused(tabIndex)
    if tabIndex == self._activeIndex then return end
    self._activeIndex = tabIndex
    MountActivePage(self)
    self:Emit("value_changed", tabIndex)
end

--#endregion

--#region Public API

---@param labelOrFn string|fun():string
---@return TabPageWidget
function TabControlWidget:AddPage(labelOrFn)
    local mgr = self.Manager
    local idx = #self._tabs + 1
    local pageId = self.Id .. "_Page" .. idx
    local tabId  = self.Id .. "_Tab"  .. idx

    local page = mgr:CreateWidget(pageId, "TabPage", { Label = labelOrFn })
    self._pages[idx] = page

    local tab = mgr:CreateWidget(tabId, "Tab", { Label = labelOrFn })
    tab._control = self
    tab._tabIndex = idx
    self._tabs[idx] = tab
    self._tabStrip:AddChild(tab)

    if self._activeIndex == 0 then
        self._activeIndex = 1
        MountActivePage(self)
    end
    return page
end

---@return integer
function TabControlWidget:GetPageCount() return #self._pages end

---@param i integer
---@return TabPageWidget|nil
function TabControlWidget:GetPage(i) return self._pages[i] end

---@param id string
---@return TabPageWidget|nil
function TabControlWidget:GetPageById(id)
    for _, p in ipairs(self._pages) do
        if p.Id == id then return p end
    end
    return nil
end

---@return TabPageWidget|nil
function TabControlWidget:GetActivePage() return self._pages[self._activeIndex] end

---@return integer
function TabControlWidget:GetActivePageIndex() return self._activeIndex end

---@param i integer
---@param silent? boolean
function TabControlWidget:SetActivePage(i, silent)
    if i < 1 or i > #self._pages or i == self._activeIndex then return end
    -- Capture focus location BEFORE remount: MountActivePage detaches the old
    -- page from the widget tree, which would break _FocusInside walks.
    local focusInStrip = self:_FocusInside(self._tabStrip)
    local focusInside = self:_FocusInside(self)
    self._activeIndex = i
    MountActivePage(self)
    if not silent then self:Emit("value_changed", i) end
    -- Focus lands on the new page so the user hears the page contents, unless
    -- they were navigating the tab strip — then focus the new tab. External
    -- callers (focus outside the control) get the legacy tab-focus behavior.
    if focusInside and not focusInStrip then
        self.Manager:SetFocus(self._pages[i])
    else
        self.Manager:SetFocus(self._tabs[i])
    end
end

---@param id string
---@param silent? boolean
function TabControlWidget:SetActivePageById(id, silent)
    for i, p in ipairs(self._pages) do
        if p.Id == id then self:SetActivePage(i, silent); return end
    end
end

---@param silent? boolean
---@return boolean
function TabControlWidget:NextPage(silent)
    local n = #self._pages
    if n == 0 then return false end
    local nextIdx = self._activeIndex + 1
    if nextIdx > n then
        if not self.WrapAround then return false end
        nextIdx = 1
    end
    self:SetActivePage(nextIdx, silent)
    return true
end

---@param silent? boolean
---@return boolean
function TabControlWidget:PreviousPage(silent)
    local n = #self._pages
    if n == 0 then return false end
    local prevIdx = self._activeIndex - 1
    if prevIdx < 1 then
        if not self.WrapAround then return false end
        prevIdx = n
    end
    self:SetActivePage(prevIdx, silent)
    return true
end

function TabControlWidget:SetWrapAround(b) self.WrapAround = b and true or false end

--#endregion

CAIWidgetRegistry.Register("TabControl", TabControlWidget.Create)
