-- CAIWidgetHelpers_Search.lua
-- Type-to-find: depth-limited DFS that prefix-matches on widget labels.

CAIWidgetHelpers_Search = {}
local S = CAIWidgetHelpers_Search

---DFS rooted at w; matches the lowercased label prefix against query.
---@param w UIWidget
---@param query string
---@param depth integer
---@param maxDepth integer
---@return UIWidget|nil
function S.MatchDFS(w, query, depth, maxDepth)
    if not w or w:IsHidden() then return nil end
    local label = w:GetLabel()
    if label and label ~= "" and label:lower():find(query, 1, true) == 1 then
        return w
    end
    if depth >= maxDepth then return nil end
    if w.Children then
        for _, child in ipairs(w.Children) do
            local found = S.MatchDFS(child, query, depth + 1, maxDepth)
            if found then return found end
        end
    end
    return nil
end

---Starting after the focused child, find the next prefix-match within root.
---Wraps once. Returns the matched widget or nil.
---@param root UIWidget
---@param query string
---@param maxDepth integer
---@return UIWidget|nil
function S.FindNext(root, query, maxDepth)
    local children = root.Children
    if not children or #children == 0 then return nil end
    local focused = root:GetFocusedChild()
    local startIdx = focused and root:GetChildIndex(focused) or 0
    local n = #children
    for i = 1, n do
        local idx = ((startIdx + i - 1) % n) + 1
        local found = S.MatchDFS(children[idx], query, 0, maxDepth)
        if found then return found end
    end
    return nil
end

---Convenience: handle a single char input on the widget for search.
---Returns true if a match was focused; speaks the no-match message otherwise.
---
---Same-letter cycling: pressing the same single letter twice within the
---search timeout doesn't extend the buffer — FindNext naturally cycles
---because it skips the currently focused child and walks forward, returning
---the next match starting with that letter. Matches JAWS/NVDA convention.
---@param root UIWidget
---@param char string
---@param maxDepth? integer
---@return boolean
function S.HandleChar(root, char, maxDepth)
    local mgr = root.Manager
    if not mgr then return false end
    local lowerChar = char:lower()
    local prev = mgr:GetSearchBuffer()
    local now = Automation.GetTime()
    local timeout = mgr.CAISettings.SearchTimeout or 1.0
    local withinTimeout = mgr.LastTypeTime and (now - mgr.LastTypeTime) <= timeout

    if withinTimeout and #prev == 1 and prev == lowerChar then
        -- Keep buffer at the single letter; just refresh the typing timestamp.
        mgr.LastTypeTime = now
    else
        mgr:AppendSearchChar(char)
    end

    local match = S.FindNext(root, mgr:GetSearchBuffer(), maxDepth or 2)
    if match then
        mgr:SetFocus(match)
        return true
    end
    Speak(Locale.Lookup("LOC_CAI_SEARCH_NO_MATCH"))
    return false
end
