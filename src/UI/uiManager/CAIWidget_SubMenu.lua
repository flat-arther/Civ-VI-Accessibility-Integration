-- CAIWidget_SubMenu.lua
-- Entered-child container: collapsed by default; Enter or Right expands and
-- focuses the first child; Left collapses and returns focus to the submenu node.
-- Up/Down navigates children only while expanded.

---@class SubMenuWidget : ContainerWidget
---@field IsExpanded boolean
SubMenuWidget = setmetatable({}, { __index = ContainerWidget })
SubMenuWidget.__index = SubMenuWidget

local Nav = CAIWidgetHelpers_Navigation

-- Recursively collapse every descendant in place — no events. Mirrors the
-- TreeItem rule so collapsing tears down the whole subtree beneath it.
local function CollapseDescendants(node)
    for _, child in ipairs(node.Children or {}) do
        if child.IsExpanded then
            child.IsExpanded = false
            child._lastFocusedChild = nil
        end
        CollapseDescendants(child)
    end
end

-- Enter (expand + focus first child) only from the collapsed node. Once
-- expanded the user is *inside* the submenu, so a bubbled Right/Enter from a
-- child must not re-enter (which would yank focus back to the first child);
-- let it bubble past instead.
local function EnterFirstChild(self)
    if self.IsExpanded then return false end
    local first = Nav.First(self)
    if not first then return false end
    self:Expand()
    self.Manager:SetFocus(first)
    return true
end

---@param mgr UIScreenManager
---@param id string
---@param props? table
---@return SubMenuWidget
function SubMenuWidget.Create(mgr, id, props)
    local w = ContainerWidget.New(SubMenuWidget)
    w.Id = id
    w.Type = "SubMenu"
    w.Role = "SubMenu"
    w.Manager = mgr
    w.IsExpanded = false
    w.SpeechSettings = { IgnoreWhenNotFocused = true }

    w:AddInputBindings({
        { Key = Keys.VK_RETURN, Description = "LOC_CAI_KB_ENTER_SUBMENU", Action = function(self) return EnterFirstChild(
            self) end },
        { Key = Keys.VK_RIGHT,  MSG = KeyEvents.KeyDown,                  Description = "LOC_CAI_KB_ENTER_SUBMENU",                Action = function(
            self) return EnterFirstChild(self) end },
        {
            Key = Keys.VK_LEFT,
            MSG = KeyEvents.KeyDown,
            Description = "LOC_CAI_KB_COLLAPSE_SUBMENU",
            Action = function(self)
                if not self:Collapse() then return false end
                self.Manager:SetFocus(self)
                return true
            end
        },
        { Key = Keys.VK_UP,    MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_MOVE_UP",       Action = function(self) return
            self.IsExpanded and self:NavigatePrev() or false end },
        { Key = Keys.VK_DOWN,  MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_MOVE_DOWN",     Action = function(self) return
            self.IsExpanded and self:NavigateNext() or false end },
        { Key = Keys.VK_HOME,  MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_MOVE_TO_FIRST", Action = function(self) return
            self.IsExpanded and self:NavigateToFirst() or false end },
        { Key = Keys.VK_END,   MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_MOVE_TO_LAST",  Action = function(self) return
            self.IsExpanded and self:NavigateToLast() or false end },
        { Key = Keys.VK_PRIOR, MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_PAGE_UP",       Action = function(self) return
            self.IsExpanded and self:NavigatePage(-1) or false end },
        { Key = Keys.VK_NEXT,  MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_PAGE_DOWN",     Action = function(self) return
            self.IsExpanded and self:NavigatePage(1) or false end },
    })

    CAIWidgetRegistry.ApplyProps(w, props)
    return w
end

---Expand the submenu (state only — focus movement is the caller's job, so the
---focus path can descend past it). `silent` suppresses the `expanded` event;
---there is no expand/collapse value to speak (focus change announces).
---@param silent? boolean
---@return boolean
function SubMenuWidget:Expand(silent)
    if self.IsExpanded then return false end
    if not self.Children or #self.Children == 0 then return false end
    self.IsExpanded = true
    if not silent then self:Emit("expanded") end
    return true
end

---Collapse the submenu and, recursively, every descendant (descendants always
---silent). `silent` suppresses this node's `collapsed` event.
---@param silent? boolean
---@return boolean
function SubMenuWidget:Collapse(silent)
    if not self.IsExpanded then return false end
    self.IsExpanded = false
    self._lastFocusedChild = nil
    CollapseDescendants(self)
    if not silent then self:Emit("collapsed") end
    return true
end

---Default-child resolution mirrors TreeItem: descend only when expanded AND a
---focused child is remembered. A bare expand (e.g. BuildFocusPath silently
---expanding an ancestor, or a freshly seeded node) leaves no cache, so the
---submenu stays the focus leaf instead of auto-entering its first child.
---@return UIWidget|nil
function SubMenuWidget:GetDefaultChild()
    if not self.IsExpanded then return nil end
    if not self._lastFocusedChild and not self._lastFocusedKey then return nil end
    return ContainerWidget.GetDefaultChild(self)
end

---Entry resolution follows GetDefaultChild: collapsed (or cache-less) submenus
---are focus stops, never auto-entered.
---@param direction 1|-1|0|nil
---@return UIWidget|nil
function SubMenuWidget:GetEntryChild(direction)
    if not self.IsExpanded then return nil end
    if not self._lastFocusedChild and not self._lastFocusedKey then return nil end
    return ContainerWidget.GetEntryChild(self, direction)
end

CAIWidgetRegistry.Register("SubMenu", SubMenuWidget.Create)
