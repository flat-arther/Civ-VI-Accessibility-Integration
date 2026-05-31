-- CAIWidget_TreeItem.lua
-- A node or leaf inside a TreeWidget. Focus speech announces expand/collapse
-- state via the value element. The toggle itself is spoken only on the
-- user-driven Expand/Collapse path; automatic/programmatic calls pass
-- silent=true. Enter activates if there are "activate" listeners; otherwise it
-- bubbles up to the parent Tree which toggles expand/collapse.

---@class TreeItemWidget : ContainerWidget
---@field IsExpanded boolean
---@field IsTreeItem boolean
TreeItemWidget = setmetatable({}, { __index = ContainerWidget })
TreeItemWidget.__index = TreeItemWidget

local function HasActivateListener(self)
    local bucket = self._listeners and self._listeners.activate
    if not bucket then return false end
    for _ in pairs(bucket) do return true end
    return false
end

---@param mgr UIScreenManager
---@param id string
---@param props? table
---@return TreeItemWidget
function TreeItemWidget.Create(mgr, id, props)
    local w = ContainerWidget.New(TreeItemWidget)
    w.Id = id
    w.Type = "TreeItem"
    w.Role = "TreeItem"
    w.Manager = mgr
    w.IsExpanded = false
    w.IsTreeItem = true
    w.SpeechSettings = { IgnoreWhenNotFocused = true, Role = false }

    -- Focus speech announces expand/collapse state (and item count when open)
    -- on every node, the standard tree-item readout. The toggle itself is
    -- announced by the user-driven Expand/Collapse path; automatic/programmatic
    -- expands and collapses pass silent=true so only navigation and deliberate
    -- toggles ever speak the state.
    w:SetValueGetter(function(self)
        if self:IsLeaf() then return "" end
        if self.IsExpanded then
            local n = #self:GetVisibleChildren()
            return Locale.Lookup("LOC_CAI_TREEVIEW_EXPANDED")
                .. ", " .. Locale.Lookup("LOC_CAI_TREEVIEW_ITEM_COUNT", n)
        end
        return Locale.Lookup("LOC_CAI_TREEVIEW_COLLAPSED")
    end)

    w:AddInputBindings({
        {
            Key = Keys.VK_RETURN,
            Action = function(self)
                if self:IsDisabled() then return true end
                if HasActivateListener(self) then
                    self:Emit("activate")
                    return true
                end
                return false -- bubble to Tree -> toggle expand/collapse
            end,
        },
    })

    CAIWidgetRegistry.ApplyProps(w, props)
    return w
end

---@return boolean
function TreeItemWidget:IsLeaf()
    return #self:GetVisibleChildren() == 0
end

-- Recursively collapse every descendant in place — no speech, no events.
-- Collapsing a node tears down its whole subtree so a later re-expand reveals
-- a single clean level rather than whatever deep state was left behind.
local function CollapseDescendants(node)
    for _, child in ipairs(node.Children or {}) do
        if child.IsExpanded then
            child.IsExpanded = false
            child._lastFocusedChild = nil
        end
        CollapseDescendants(child)
    end
end

---Expand this node. `silent` suppresses both the `expanded` event and speech
---(use it for seeding initial state or auto-expanding focus ancestors); the
---default user-driven path emits and announces.
---@param silent? boolean
---@return boolean
function TreeItemWidget:Expand(silent)
    if self.IsExpanded then return false end
    if self:IsLeaf() then return false end
    self.IsExpanded = true
    if not silent then
        self:Emit("expanded")
        self:SpeakElements({ "value" })
    end
    return true
end

---Collapse this node and, recursively, every descendant. Descendant collapses
---are always silent; `silent` controls whether this node emits `collapsed` and
---speaks.
---@param silent? boolean
---@return boolean
function TreeItemWidget:Collapse(silent)
    if not self.IsExpanded then return false end
    self.IsExpanded = false
    self._lastFocusedChild = nil
    CollapseDescendants(self)
    if not silent then
        self:Emit("collapsed")
        self:SpeakElements({ "value" })
    end
    return true
end

---Descent into an expanded item is gated by the descent cache. Within-tree
---navigation helpers (NavigateFlat/Page/First/Last, CollapseOrAscend, search)
---wipe the cache via Tree.ClearDescent before calling SetFocus so the item
---lands as the focus leaf. Descent that's just passing through (Tab back into
---the tree, screen Push focusing a higher container) leaves the cache intact
---and restores deep focus. Direction is irrelevant.
---@return UIWidget|nil
function TreeItemWidget:GetDefaultChild()
    if not self.IsExpanded then return nil end
    if not self._lastFocusedChild and not self._lastFocusedKey then return nil end
    return ContainerWidget.GetDefaultChild(self)
end

---@return UIWidget|nil
function TreeItemWidget:GetEntryChild()
    return self:GetDefaultChild()
end

CAIWidgetRegistry.Register("TreeItem", TreeItemWidget.Create)
