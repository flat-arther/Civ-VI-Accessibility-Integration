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

---Wipe descent cache so SetFocus(item) lands ON the item rather than on a
---cached descendant. Call before SetFocus from every within-tree navigation
---path (flat nav, search, ascent) — without this, an expanded item whose
---cache still points to a previously focused child would auto-descend on
---re-entry and Up/flat-Down would become no-ops.
---@param item UIWidget
function T.ClearDescent(item)
    if not item or not item.IsTreeItem then return end
    item._lastFocusedChild = nil
    item._lastFocusedKey = nil
end

local ClearDescent = T.ClearDescent


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
    if #flat == 0 then
        LogMessage("Tree helper NavigateFlat found no visible tree items")
        return false
    end
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
        if targetIdx < 1 or targetIdx > #flat then
            LogMessage("Tree helper NavigateFlat hit tree boundary at index " .. tostring(curIdx))
            return false
        end
    end
    local target = flat[targetIdx]
    ClearDescent(target)
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
    if pageSize <= 0 then
        LogWarn("Tree helper NavigatePage called with non-positive page size " .. tostring(pageSize))
        return false
    end
    local flat = T.Flatten(root)
    if #flat == 0 then
        LogMessage("Tree helper NavigatePage found no visible tree items")
        return false
    end
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
        if targetIdx == curIdx then
            LogMessage("Tree helper NavigatePage hit tree boundary at index " .. tostring(curIdx))
            return false
        end
    end
    local target = flat[targetIdx]
    ClearDescent(target)
    mgr:SetFocus(target, { direction = direction })
    return true
end

---Find the visible tree row containing the current focus. This also supports
---plain non-TreeItem leaves, which are valid rows in a tree.
---@param root UIWidget
---@param flat UIWidget[]
---@return UIWidget|nil
local function GetFocusedVisibleRow(root, flat)
    local node = root.Manager:GetFocusedWidget()
    while node and node ~= root do
        for _, item in ipairs(flat) do
            if item == node then return item end
        end
        node = node.Parent
    end
    return nil
end

---Home / End: jump to the first / last visible sibling at the focused row's
---current tree depth. If focus is not already on a visible row, use the tree's
---top level.
---@param root UIWidget
---@param direction 1|-1
---@return boolean
local function NavigateLevelEdge(root, direction)
    local flat = T.Flatten(root)
    if #flat == 0 then return false end
    local current = GetFocusedVisibleRow(root, flat)
    local level = current and current.Parent or root
    local target
    if direction > 0 then
        for _, child in ipairs(level.Children or {}) do
            if not child:IsHidden() then target = child; break end
        end
    else
        for i = #(level.Children or {}), 1, -1 do
            local child = level.Children[i]
            if not child:IsHidden() then target = child; break end
        end
    end
    if not target then return false end
    ClearDescent(target)
    root.Manager:SetFocus(target, { direction = direction })
    return true
end

---@param root UIWidget
---@return boolean
function T.NavigateFirst(root)
    return NavigateLevelEdge(root, 1)
end

---@param root UIWidget
---@return boolean
function T.NavigateLast(root)
    return NavigateLevelEdge(root, -1)
end

---Ctrl+Home: jump to the first row in the whole visible tree.
---@param root UIWidget
---@return boolean
function T.NavigateTreeFirst(root)
    local flat = T.Flatten(root)
    if #flat == 0 then return false end
    ClearDescent(flat[1])
    root.Manager:SetFocus(flat[1], { direction = 1 })
    return true
end

---Ctrl+End: jump to the deepest last row in the whole visible tree.
---@param root UIWidget
---@return boolean
function T.NavigateTreeLast(root)
    local flat = T.Flatten(root)
    if #flat == 0 then return false end
    local last = flat[#flat]
    ClearDescent(last)
    root.Manager:SetFocus(last, { direction = -1 })
    return true
end

---Right key behavior on the focused item: expand if collapsed node; descend if
---already expanded. A focused widget that is not itself a TreeItem (a plain leaf
---placed inside the tree) is a leaf by default, so Right is a no-op on it.
---@param root UIWidget
---@return boolean
function T.ExpandOrDescend(root)
    local item = root.Manager:GetFocusedWidget()
    if not item or not item.IsTreeItem or item:IsLeaf() then
        LogMessage("Tree helper ExpandOrDescend ignored because focused widget is not an expandable tree item")
        return false
    end
    if not item.IsExpanded then
        item:Expand()
        return true
    end
    local first
    for _, c in ipairs(item.Children) do
        if not c:IsHidden() then first = c; break end
    end
    if not first then
        LogWarn("Tree helper ExpandOrDescend found expanded tree item with no visible children")
        return false
    end
    root.Manager:SetFocus(first)
    return true
end

---Left key behavior on the focused item: collapse if it is an expanded TreeItem;
---otherwise jump to the parent TreeItem. A focused non-TreeItem leaf is treated as
---a leaf, so Left ascends to its enclosing TreeItem rather than collapsing it.
---@param root UIWidget
---@return boolean
function T.CollapseOrAscend(root)
    local focused = root.Manager:GetFocusedWidget()
    if not focused then return false end
    if focused.IsTreeItem and focused.IsExpanded then
        focused:Collapse()
        return true
    end
    local parent = T.GetParentTreeItem(root, focused)
    if not parent then
        LogMessage("Tree helper CollapseOrAscend could not find parent tree item")
        return false
    end
    ClearDescent(parent)
    root.Manager:SetFocus(parent)
    return true
end

---Toggle expand/collapse on the focused item (used by Enter on Tree). No-op when
---the focused widget is not a TreeItem (a plain leaf) or is a leaf TreeItem.
---@param root UIWidget
---@return boolean
function T.ToggleFocused(root)
    local item = root.Manager:GetFocusedWidget()
    if not item or not item.IsTreeItem or item:IsLeaf() then
        LogMessage("Tree helper ToggleFocused ignored because focused widget is not a toggleable tree item")
        return false
    end
    if item.IsExpanded then item:Collapse() else item:Expand() end
    return true
end
