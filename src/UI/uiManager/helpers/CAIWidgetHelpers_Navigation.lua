-- CAIWidgetHelpers_Navigation.lua
-- Stateless visible-child walks shared by every navigable container.

CAIWidgetHelpers_Navigation = {}
local H = CAIWidgetHelpers_Navigation

---Iterate children starting from startIdx in direction (+1/-1), skipping hidden.
---@param w UIWidget
---@param startIdx integer
---@param direction 1|-1
---@param allowWrap boolean
---@return UIWidget|nil, integer|nil
function H.FindVisible(w, startIdx, direction, allowWrap)
    local children = w.Children
    if not children then return nil, nil end
    local n = #children
    if n == 0 then return nil, nil end
    for step = 1, n do
        local idx = ((startIdx + step * direction) - 1) % n + 1
        local c = children[idx]
        if not c:IsHidden() then
            if not allowWrap then
                -- Wrapped if we didn't actually advance past startIdx in the
                -- intended direction. Using <= / >= (not strict) catches the
                -- n == 1 case where the modulo cycles back to startIdx after
                -- one step — without this, single-child containers would
                -- silently re-select their only child as "the next sibling".
                local wrapped = direction > 0 and idx <= startIdx or direction < 0 and idx >= startIdx
                if wrapped then return nil, nil end
            end
            return c, idx
        end
    end
    return nil, nil
end

---@param w UIWidget
---@return UIWidget|nil
function H.First(w)
    if not w.Children then return nil end
    for _, c in ipairs(w.Children) do
        if not c:IsHidden() then return c end
    end
    return nil
end

---@param w UIWidget
---@return UIWidget|nil
function H.Last(w)
    if not w.Children then return nil end
    for i = #w.Children, 1, -1 do
        local c = w.Children[i]
        if not c:IsHidden() then return c end
    end
    return nil
end

---Default child for a container. Resolution order:
---  1. _lastFocusedKey: scan children for a matching FocusKey (survives rebuild).
---  2. _lastFocusedChild widget ref (still parented and visible).
---  3. DefaultIndex, searching forward for the first visible child.
---  4. First visible child.
---@param w UIWidget
---@return UIWidget|nil
function H.DefaultChild(w)
    if not w.Children or #w.Children == 0 then return nil end
    local lastKey = w._lastFocusedKey
    if lastKey then
        for _, c in ipairs(w.Children) do
            if c.FocusKey == lastKey and not c:IsHidden() then return c end
        end
    end
    local last = w._lastFocusedChild
    if last and last.Parent == w and not last:IsHidden() then return last end
    local defaultIndex = w.DefaultIndex or 1
    local c = H.FindVisible(w, defaultIndex - 1, 1, true)
    return c or H.First(w)
end

---Move focus to next/prev visible sibling within a container.
---@param w UIWidget
---@param direction 1|-1
---@return boolean
function H.Navigate(w, direction)
    if not w.Children or #w.Children == 0 then return false end
    local focused = w:GetFocusedChild()
    -- When nothing is focused yet we must start at 0 so FindVisible considers
    -- index 1 on a forward search; using DefaultIndex would skip it.
    local startIdx = focused and w:GetChildIndex(focused) or 0
    local candidate = H.FindVisible(w, startIdx, direction, w.WrapAround)
    if candidate then
        w.Manager:SetFocus(candidate, { direction = direction })
        return true
    end
    return false
end

---@param w UIWidget
---@return boolean
function H.NavigateToFirst(w)
    local c = H.First(w)
    if c then w.Manager:SetFocus(c, { direction = 1 }); return true end
    return false
end

---@param w UIWidget
---@return boolean
function H.NavigateToLast(w)
    local c = H.Last(w)
    if c then w.Manager:SetFocus(c, { direction = -1 }); return true end
    return false
end

---Direction-aware entry point used by BuildFocusPath. For normal containers
---we always use DefaultChild (cached _lastFocusedKey / _lastFocusedChild,
---falling back to first visible) — Shift+Tab into a container restores the
---previous focus instead of jumping to the last child. Transparent layout-only
---containers (e.g. dialog button rows, inline button strips) can opt into
---directional entry, where Tab lands on first and Shift+Tab on last.
---@param w UIWidget
---@param direction 1|-1|0|nil
---@return UIWidget|nil
function H.EntryChild(w, direction)
    if not w.Children or #w.Children == 0 then return nil end
    if w.Transparent and w.UseDirectionalEntry ~= false then
        if direction == 1 then return H.First(w) end
        if direction == -1 then return H.Last(w) end
    end
    return H.DefaultChild(w)
end

---Jump focus by PageSize visible siblings in the given direction. Clamps to
---ends; returns false when already at the boundary.
---@param w UIWidget
---@param direction 1|-1
---@param pageSize integer
---@return boolean
function H.NavigatePage(w, direction, pageSize)
    if not w.Children or #w.Children == 0 then return false end
    pageSize = pageSize or 10
    if pageSize <= 0 then return false end
    local visible = w:GetVisibleChildren()
    if #visible == 0 then return false end
    local focused = w:GetFocusedChild()
    local curIdx
    if focused then
        for i, v in ipairs(visible) do
            if v == focused then curIdx = i; break end
        end
    end
    local targetIdx
    if not curIdx then
        targetIdx = direction > 0 and 1 or #visible
    else
        targetIdx = curIdx + direction * pageSize
        if targetIdx < 1 then targetIdx = 1 end
        if targetIdx > #visible then targetIdx = #visible end
        if targetIdx == curIdx then return false end
    end
    w.Manager:SetFocus(visible[targetIdx], { direction = direction })
    return true
end
