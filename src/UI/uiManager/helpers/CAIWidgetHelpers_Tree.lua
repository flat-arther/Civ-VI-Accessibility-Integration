-- CAIWidgetHelpers_Tree.lua
-- Flat pre-order traversal over visible TreeItems, descending only into
-- expanded nodes. Shared by Tree navigation and search.

CAIWidgetHelpers_Tree = {}
local T = CAIWidgetHelpers_Tree

local function HasVisibleChildren(w)
    if not w.Children or #w.Children == 0 then return false end
    for _, c in ipairs(w.Children) do
        if not c:IsHidden() then return true end
    end
    return false
end

---Build flat in-order list of visible TreeItems reachable from root,
---honoring IsExpanded on intermediate nodes.
---@param root UIWidget
---@return UIWidget[]
function T.Flatten(root)
    local out = {}
    local function walk(node)
        if not node.Children then return end
        for _, child in ipairs(node.Children) do
            if not child:IsHidden() then
                table.insert(out, child)
                if child.IsExpanded and HasVisibleChildren(child) then
                    walk(child)
                end
            end
        end
    end
    walk(root)
    return out
end

---Walk up from node until we hit a TreeItem (IsTreeItem == true). Stops at root.
---@param root UIWidget
---@param node UIWidget|nil
---@return UIWidget|nil
function T.AscendToTreeItem(root, node)
    while node and node ~= root do
        if node.IsTreeItem then return node end
        node = node.Parent
    end
    return nil
end

---@param root UIWidget
---@return UIWidget|nil
function T.GetFocusedTreeItem(root)
    if not root or not root.Manager then return nil end
    return T.AscendToTreeItem(root, root.Manager:GetFocusedWidget())
end

---@param root UIWidget
---@param item UIWidget|nil
---@return UIWidget|nil
function T.GetParentTreeItem(root, item)
    if not item then return nil end
    return T.AscendToTreeItem(root, item.Parent)
end

---@param root UIWidget
---@param direction 1|-1
---@return boolean
function T.NavigateFlat(root, direction)
    local flat = T.Flatten(root)
    if #flat == 0 then return false end
    local mgr = root.Manager
    local current = mgr:GetFocusedWidget()
    local curIdx
    local node = current
    while node and not curIdx do
        for i, item in ipairs(flat) do
            if item == node then curIdx = i; break end
        end
        node = node.Parent
    end
    local targetIdx
    if not curIdx then
        targetIdx = direction > 0 and 1 or #flat
    else
        targetIdx = curIdx + direction
        if targetIdx < 1 or targetIdx > #flat then return false end
    end
    local target = flat[targetIdx]
    if target.IsTreeItem then target._lastFocusedChild = nil end
    mgr:SetFocus(target, { direction = direction })
    return true
end

---Jump PageSize items forward/backward in flat tree order. Clamps to ends.
---@param root UIWidget
---@param direction 1|-1
---@param pageSize integer
---@return boolean
function T.NavigatePage(root, direction, pageSize)
    pageSize = pageSize or 10
    if pageSize <= 0 then return false end
    local flat = T.Flatten(root)
    if #flat == 0 then return false end
    local mgr = root.Manager
    local current = mgr:GetFocusedWidget()
    local curIdx
    local node = current
    while node and not curIdx do
        for i, item in ipairs(flat) do
            if item == node then curIdx = i; break end
        end
        node = node.Parent
    end
    local targetIdx
    if not curIdx then
        targetIdx = direction > 0 and 1 or #flat
    else
        targetIdx = curIdx + direction * pageSize
        if targetIdx < 1 then targetIdx = 1 end
        if targetIdx > #flat then targetIdx = #flat end
        if targetIdx == curIdx then return false end
    end
    local target = flat[targetIdx]
    if target.IsTreeItem then target._lastFocusedChild = nil end
    mgr:SetFocus(target, { direction = direction })
    return true
end

---@param root UIWidget
---@return boolean
function T.NavigateFirst(root)
    local flat = T.Flatten(root)
    if #flat == 0 then return false end
    if flat[1].IsTreeItem then flat[1]._lastFocusedChild = nil end
    root.Manager:SetFocus(flat[1], { direction = 1 })
    return true
end

---@param root UIWidget
---@return boolean
function T.NavigateLast(root)
    local flat = T.Flatten(root)
    if #flat == 0 then return false end
    local last = flat[#flat]
    if last.IsTreeItem then last._lastFocusedChild = nil end
    root.Manager:SetFocus(last, { direction = -1 })
    return true
end

---Right key behavior on the focused item: expand if collapsed node; descend if already expanded.
---@param root UIWidget
---@return boolean
function T.ExpandOrDescend(root)
    local item = T.GetFocusedTreeItem(root)
    if not item or item:IsLeaf() then return false end
    if not item.IsExpanded then
        item:Expand()
        return true
    end
    local first
    for _, c in ipairs(item.Children) do
        if not c:IsHidden() then first = c; break end
    end
    if not first then return false end
    root.Manager:SetFocus(first)
    return true
end

---Left key behavior on the focused item: collapse if expanded; otherwise jump to parent item.
---@param root UIWidget
---@return boolean
function T.CollapseOrAscend(root)
    local item = T.GetFocusedTreeItem(root)
    if not item then return false end
    if item.IsExpanded then
        item:Collapse()
        return true
    end
    local parent = T.GetParentTreeItem(root, item)
    if not parent then return false end
    parent._lastFocusedChild = nil
    root.Manager:SetFocus(parent)
    return true
end

---Toggle expand/collapse on the focused item (used by Enter on Tree).
---@param root UIWidget
---@return boolean
function T.ToggleFocused(root)
    local item = T.GetFocusedTreeItem(root)
    if not item or item:IsLeaf() then return false end
    if item.IsExpanded then item:Collapse() else item:Expand() end
    return true
end
