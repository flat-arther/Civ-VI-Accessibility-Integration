-- CAIWidget_TreeItem.lua
-- A node or leaf inside a TreeWidget. IsExpanded is exposed through GetValue so
-- focus speech announces expanded/collapsed state. Enter activates if there are
-- "activate" listeners; otherwise it bubbles up to the parent Tree which
-- toggles expand/collapse.

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
    w.SpeechSettings = { Role = false, IgnoreWhenNotFocused = true }

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

---@return boolean
function TreeItemWidget:Expand()
    if self.IsExpanded then return false end
    if self:IsLeaf() then return false end
    self.IsExpanded = true
    self:Emit("expanded")
    self:SpeakElements({ "value" })
    return true
end

---@return boolean
function TreeItemWidget:Collapse()
    if not self.IsExpanded then return false end
    self.IsExpanded = false
    self._lastFocusedChild = nil
    self:Emit("collapsed")
    self:SpeakElements({ "value" })
    return true
end

---Tree navigation lands on the item itself, never on its children. The flat
---traversal exposes each expanded child as its own focus stop, and
---ExpandOrDescend handles entry explicitly when the user presses Right.
---@return UIWidget|nil
function TreeItemWidget:GetDefaultChild() return nil end

---@param direction 1|-1|0|nil
---@return UIWidget|nil
function TreeItemWidget:GetEntryChild(direction) return nil end

CAIWidgetRegistry.Register("TreeItem", TreeItemWidget.Create)
