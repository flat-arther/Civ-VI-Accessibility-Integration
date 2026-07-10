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
-- Array of common invalid search start chars
local INVALID_SEARCH_START_CHARS = {
    ['"'] = true,
    ["'"] = true,
    ['/'] = true,
    ['\\'] = true,
    ['<'] = true,
    ['>'] = true,
    ['|'] = true,
    ['?'] = true,
    ['*'] = true,
    [':'] = true,
    [';'] = true,
    ['.'] = true,
    [','] = true,
    ['('] = true,
    [')'] = true,
    ['['] = true,
    [']'] = true,
    ['{'] = true,
    ['}'] = true,
    ['+'] = true,
    ['='] = true,
    ['%'] = true,
    ['`'] = true,
    ['~'] = true,
    ['!'] = true,
    ['@'] = true,
    ['#'] = true,
    ['$'] = true,
    ['^'] = true,
    ['&'] = true,
    ['_'] = true,
    ['-'] = true,
}

local SEARCH_MATCH = {
    START_WHOLE_WORD = 0,
    START_PREFIX = 1,
    WHOLE_WORD = 2,
    PREFIX = 3,
    SUBSTRING = 4,
    WORD_PREFIX_ABBREVIATION = 5,
}

local WORD_SEPARATORS = {
    [" "] = true,
    ["-"] = true,
    ["_"] = true,
    ["/"] = true,
    ["\\"] = true,
    ["("] = true,
    [")"] = true,
    ["["] = true,
    ["]"] = true,
    ["{"] = true,
    ["}"] = true,
    ["."] = true,
    [","] = true,
    [":"] = true,
    [";"] = true,
    ["\t"] = true,
    ["\n"] = true,
}

local function IsWordSeparator(ch)
    return WORD_SEPARATORS[ch] or false
end

---Collect all searchable widgets in breadth-first order.
---The returned list is used by the search engine for scoring and ranking.
---@param root UIWidget
---@param maxDepth integer
---@return SearchCandidate[]
function S.CollectSearchCandidates(root, maxDepth)
    if not root or not root.Children then
        return {}
    end

    ---@type SearchCandidate[]
    local candidates = {}

    local queue = {}

    for _, child in ipairs(root.Children) do
        queue[#queue + 1] = {
            Widget = child,
            Depth = 0,
        }
    end

    local head = 1
    local bfsIndex = 1

    while head <= #queue do
        local current = queue[head]
        head = head + 1

        ---@type UIWidget
        local widget = current.Widget
        local depth = current.Depth

        if not widget:IsHidden() then
            local label = widget:GetLabel()

            if label and label ~= "" then
                candidates[#candidates + 1] = {
                    Widget = widget,
                    Label = label,
                    LabelLower = label:lower(),
                    BFSIndex = bfsIndex,
                }

                bfsIndex = bfsIndex + 1
            end

            if depth < maxDepth and widget.Children then
                for _, child in ipairs(widget.Children) do
                    queue[#queue + 1] = {
                        Widget = child,
                        Depth = depth + 1,
                    }
                end
            end
        end
    end

    return candidates
end

---Returns whether the character at the given index begins a word.
---@param text string
---@param index integer
---@return boolean
local function IsWordBoundary(text, index)
    if index <= 1 then
        return true
    end

    return IsWordSeparator(text:sub(index - 1, index - 1))
end



---Split a string into lowercase words and their starting positions.
---@param text string
---@return SearchWord[]
local function SplitWords(text)
    ---@type SearchWord[]
    local words = {}

    local start = nil

    for i = 1, #text do
        local ch = text:sub(i, i)

        if IsWordSeparator(ch) then
            if start then
                words[#words + 1] = {
                    Text = text:sub(start, i - 1):lower(),
                    StartPos = start,
                }
                start = nil
            end
        elseif not start then
            start = i
        end
    end

    if start then
        words[#words + 1] = {
            Text = text:sub(start):lower(),
            StartPos = start,
        }
    end

    return words
end

---Find the first occurrence of a query satisfying the given predicate.
---@param label string
---@param query string
---@param predicate fun(startPos:integer,endPos:integer):boolean
---@return integer|nil
local function FindMatch(label, query, predicate)
    local pos = 1

    while true do
        local startPos, endPos = string.find(label, query, pos, true)
        if not startPos then
            return nil
        end

        if predicate(startPos, endPos) then
            return startPos
        end

        pos = startPos + 1
    end
end

---Matches a whole first word.
---@param label string
---@param query string
---@return integer|nil
local function MatchStartWholeWord(label, query)
    return FindMatch(label, query, function(startPos, endPos)
        return startPos == 1
            and IsWordBoundary(label, startPos)
            and IsWordBoundary(label, endPos + 1)
    end)
end

---Matches a prefix of the first word.
---@param label string
---@param query string
---@return integer|nil
local function MatchStartPrefix(label, query)
    return FindMatch(label, query, function(startPos)
        return startPos == 1
    end)
end

---Matches a whole word anywhere in the label.
---@param label string
---@param query string
---@return integer|nil
local function MatchWholeWord(label, query)
    return FindMatch(label, query, function(startPos, endPos)
        return IsWordBoundary(label, startPos)
            and IsWordBoundary(label, endPos + 1)
    end)
end

---Matches the prefix of any word.
---@param label string
---@param query string
---@return integer|nil
local function MatchPrefix(label, query)
    return FindMatch(label, query, function(startPos)
        return IsWordBoundary(label, startPos)
    end)
end

---Matches anywhere in the label.
---@param label string
---@param query string
---@return integer|nil
local function MatchSubstring(label, query)
    return string.find(label, query, 1, true)
end

---Matches word-prefix abbreviations.
---@param label string
---@param query string
---@return integer|nil
local function MatchWordPrefixAbbreviation(label, query)
    local labelWords = SplitWords(label)
    local queryWords = SplitWords(query)

    if #queryWords == 0 or #queryWords > #labelWords then
        return nil
    end

    for startWord = 1, #labelWords - #queryWords + 1 do
        local matched = true

        for i = 1, #queryWords do
            if labelWords[startWord + i - 1].Text:find(queryWords[i].Text, 1, true) ~= 1 then
                matched = false
                break
            end
        end

        if matched then
            return labelWords[startWord].StartPos
        end
    end

    return nil
end

---@param candidate SearchCandidate
---@param query string
---@param tier integer
---@return SearchResult|nil
function S.ScoreSearchCandidate(candidate, query, tier)
    local label = candidate.LabelLower
    local singleChar = #query == 1
    local pos
    if tier == SEARCH_MATCH.START_WHOLE_WORD then
        pos = MatchStartWholeWord(label, query)
        if pos then
            return {
                Candidate = candidate,
                Tier = SEARCH_MATCH.START_WHOLE_WORD,
                MatchPosition = pos,
                LabelLength = #candidate.Label,
            }
        end
    end
    if tier == SEARCH_MATCH.START_PREFIX then
        pos = MatchStartPrefix(label, query)
        if pos then
            return {
                Candidate = candidate,
                Tier = SEARCH_MATCH.START_PREFIX,
                MatchPosition = pos,
                LabelLength = #candidate.Label,
            }
        end
    end

    if tier == SEARCH_MATCH.WHOLE_WORD then
        pos = MatchWholeWord(label, query)
        if pos then
            return {
                Candidate = candidate,
                Tier = SEARCH_MATCH.WHOLE_WORD,
                MatchPosition = pos,
                LabelLength = #candidate.Label,
            }
        end
    end

    if tier == SEARCH_MATCH.PREFIX then
        pos = MatchPrefix(label, query)
        if pos then
            return {
                Candidate = candidate,
                Tier = SEARCH_MATCH.PREFIX,
                MatchPosition = pos,
                LabelLength = #candidate.Label,
            }
        end
    end

    if tier == SEARCH_MATCH.SUBSTRING then
        pos = MatchSubstring(label, query)
        if pos then
            return {
                Candidate = candidate,
                Tier = SEARCH_MATCH.SUBSTRING,
                MatchPosition = pos,
                LabelLength = #candidate.Label,
            }
        end
    end

    if tier == SEARCH_MATCH.WORD_PREFIX_ABBREVIATION then
        pos = MatchWordPrefixAbbreviation(label, query)
        if pos then
            return {
                Candidate = candidate,
                Tier = SEARCH_MATCH.WORD_PREFIX_ABBREVIATION,
                MatchPosition = pos,
                LabelLength = #candidate.Label,
            }
        end
    end

    return nil
end

---Returns true if a is a better match than b.
---@param a SearchResult
---@param b SearchResult
---@return boolean
function S.CompareSearchResults(a, b)
    if a.Tier ~= b.Tier then
        return a.Tier < b.Tier
    end

    if a.MatchPosition ~= b.MatchPosition then
        return a.MatchPosition < b.MatchPosition
    end

    if a.LabelLength ~= b.LabelLength then
        return a.LabelLength < b.LabelLength
    end

    return a.Candidate.BFSIndex < b.Candidate.BFSIndex
end

---Returns whether a character is valid as the first character of a
---type-to-find search.
---@param char string
---@return boolean
function S.IsValidSearchStartCharacter(char)
    if not char or #char ~= 1 then
        return false
    end

    local byte = string.byte(char)

    -- Reject control characters.
    if byte and byte < 32 then
        return false
    end

    -- Reject whitespace.
    if char:match("%s") then
        return false
    end

    -- Reject digits.
    if char:match("%d") then
        return false
    end

    -- Reject common punctuation that is unlikely to begin a widget label.
    return not INVALID_SEARCH_START_CHARS[char]
end

---Find all matching widgets sorted from best to worst.
---@param root UIWidget
---@param query string
---@param maxDepth integer
---@return SearchResult[]
function S.FindSearchResults(root, query, maxDepth)
    if not root or not root.Children then
        return {}
    end

    local candidates = S.CollectSearchCandidates(root, maxDepth)

    local SEARCH_ORDER = {
        SEARCH_MATCH.START_WHOLE_WORD,
        SEARCH_MATCH.START_PREFIX,
        SEARCH_MATCH.WHOLE_WORD,
        SEARCH_MATCH.PREFIX,
        SEARCH_MATCH.SUBSTRING,
        SEARCH_MATCH.WORD_PREFIX_ABBREVIATION,
    }

    for _, tier in ipairs(SEARCH_ORDER) do
        local results = {}

        for _, candidate in ipairs(candidates) do
            local result = S.ScoreSearchCandidate(candidate, query, tier)
            if result then
                results[#results + 1] = result
            end
        end

        if #results > 0 then
            table.sort(results, S.CompareSearchResults)
            return results
        end
    end

    return {}
end

---@param results SearchResult[]
---@param focused UIWidget
---@return integer
function S.FindNextSearchResult(results, focused)
    if not focused then
        return 1
    end

    for i, result in ipairs(results) do
        if result.Candidate.Widget == focused then
            return (i % #results) + 1
        end
    end

    return 1
end

---@param root UIWidget
---@param maxDepth integer
---@param repeatSearch boolean
---@return boolean
function S.ApplyCurrentBuffer(root, maxDepth, repeatSearch)
    local mgr = root.Manager
    if not mgr then
        return false
    end

    local results = S.FindSearchResults(root, mgr:GetSearchBuffer(), maxDepth or 5)

    if #results == 0 then
        Speak(Locale.Lookup("LOC_CAI_SEARCH_NO_MATCH"))
        return false
    end

    local resultIndex = 1

    if repeatSearch then
        resultIndex = S.FindNextSearchResult(results, mgr:GetFocusedWidget())
    end

    mgr:SetFocus(results[resultIndex].Candidate.Widget)
    return true
end

---Convenience: handle a single char input on the widget for search.
---Returns true if a match was focused; speaks the no-match message otherwise.
---
---Same-letter cycling: pressing the same single letter twice within the
---search timeout keeps the search buffer unchanged but advances to the next
---matching widget, wrapping when necessary.
---@param root UIWidget
---@param char string
---@param maxDepth? integer
---@return boolean
function S.HandleChar(root, char, maxDepth)
    local mgr = root.Manager
    if not mgr then
        return false
    end

    local prev = mgr:GetSearchBuffer()

    if #prev == 0 and not S.IsValidSearchStartCharacter(char) then
        return false
    end

    local repeatSearch = #prev == 1 and prev == char:lower()

    if repeatSearch then
        -- Keep the buffer at the single letter; just refresh the timeout.
        mgr.LastTypeTime = Automation.GetTime()
        mgr:TouchSearchBufferTimer()
    else
        mgr:AppendSearchChar(char)
    end

    return S.ApplyCurrentBuffer(root, maxDepth or 5, repeatSearch)
end

---@param root UIWidget
---@param maxDepth? integer
---@return boolean
function S.HandleBackspace(root, maxDepth)
    local mgr = root.Manager
    if not mgr then
        return false
    end

    local buffer = mgr:GetSearchBuffer()
    if buffer == "" then
        return false
    end

    local nextBuffer = mgr:RemoveSearchChar()
    if nextBuffer == "" then
        Speak(Locale.Lookup("LOC_CAI_SEARCH_CLEARED"))
        return true
    end

    return S.ApplyCurrentBuffer(root, maxDepth or 5, false)
end

--#endregion
