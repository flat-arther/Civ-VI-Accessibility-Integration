-- CAIWidgetHelpers_Search.lua
-- Type-to-find helpers and shared search utilities (query parsing, history,
-- multi-term Search.* queries) used by SearchPanel, scanner search, etc.

CAIWidgetHelpers_Search = {}
local S = CAIWidgetHelpers_Search

--#region Shared search utilities

local MAX_HISTORY = 10
local g_SearchHistory = {}

---Split raw input into whitelist and blacklist terms.
---Terms prefixed with "--" go to the blacklist (the prefix is stripped).
---@param rawQuery string
---@return string[], string[]
function S.ParseQuery(rawQuery)
    local whitelist = {}
    local blacklist = {}
    for term in (rawQuery or ""):gmatch("%S+") do
        if term:sub(1, 2) == "--" and #term > 2 then
            blacklist[#blacklist + 1] = term:sub(3)
        else
            whitelist[#whitelist + 1] = term
        end
    end
    return whitelist, blacklist
end

---@param context string
---@return string[]
function S.GetHistory(context)
    if not g_SearchHistory[context] then g_SearchHistory[context] = {} end
    return g_SearchHistory[context]
end

---@param context string
---@param query string
function S.AddHistory(context, query)
    if not query or query == "" then return end
    local history = S.GetHistory(context)
    for i = #history, 1, -1 do
        if history[i] == query then table.remove(history, i) end
    end
    table.insert(history, 1, query)
    while #history > MAX_HISTORY do table.remove(history) end
end

---Navigate search history. Returns newIndex, entry (or nil at index 0).
---@param context string
---@param currentIndex integer
---@param direction integer  1=older, -1=newer
---@return integer, string|nil
function S.NavigateHistory(context, currentIndex, direction)
    local history = S.GetHistory(context)
    local newIndex = currentIndex + direction
    if newIndex < 0 then newIndex = 0 end
    if newIndex > #history then newIndex = #history end
    if newIndex == 0 then
        return 0, nil
    end
    return newIndex, history[newIndex]
end

---Run a multi-term AND query with blacklist subtraction against a game Search.* context.
---@param searchContext string  The Search.* context name
---@param whitelist string[]
---@param blacklist string[]
---@param maxResults integer
---@return table[]  Array of { key=string, highlighted=string }
function S.MultiTermSearch(searchContext, whitelist, blacklist, maxResults)
    if not Search.HasContext(searchContext) then return {} end

    local hitCounts = {}
    local resultsByKey = {}
    local queryMax = maxResults * 3

    for _, term in ipairs(whitelist) do
        local raw = Search.Search(searchContext, term, queryMax)
        if not raw or #raw == 0 then return {} end
        for _, hit in ipairs(raw) do
            local key = hit[1]
            hitCounts[key] = (hitCounts[key] or 0) + 1
            if not resultsByKey[key] then
                resultsByKey[key] = { key = key, highlighted = hit[2] or "" }
            end
        end
    end

    for _, term in ipairs(blacklist) do
        local raw = Search.Search(searchContext, term, queryMax)
        if raw then
            for _, hit in ipairs(raw) do
                hitCounts[hit[1]] = -1
            end
        end
    end

    local needed = #whitelist
    local results = {}
    for k, count in pairs(hitCounts) do
        if count >= needed and resultsByKey[k] then
            results[#results + 1] = resultsByKey[k]
            if #results >= maxResults then break end
        end
    end
    return results
end

--#endregion

--#region Type-to-find (widget tree prefix search)

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

--#endregion
