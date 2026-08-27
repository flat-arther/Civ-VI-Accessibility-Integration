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
    -- ASCII whitespace split only; %S is locale-sensitive and would break CJK
    -- queries mid-character. Space-less scripts stay as a single term.
    for term in (rawQuery or ""):gmatch("[^ \t\r\n]+") do
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
    if not Search.HasContext(searchContext) then
        LogWarn("Search helper MultiTermSearch missing context " .. tostring(searchContext))
        return {}
    end

    local hitCounts = {}
    local resultsByKey = {}
    local queryMax = maxResults * 3

    for _, term in ipairs(whitelist) do
        local raw = Search.Search(searchContext, term, queryMax)
        if not raw or #raw == 0 then
            LogMessage("Search helper MultiTermSearch whitelist term had no hits in context "
                .. tostring(searchContext) .. ": " .. tostring(term))
            return {}
        end
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
    LogMessage("Search helper MultiTermSearch context=" .. tostring(searchContext)
        .. ", whitelist=" .. tostring(#whitelist)
        .. ", blacklist=" .. tostring(#blacklist)
        .. ", results=" .. tostring(#results))
    return results
end

--#endregion

--#region Type-to-find (widget tree prefix search)

-- Accented Latin letters (Latin-1 Supplement + Latin Extended-A, both cases)
-- mapped by Unicode CODE POINT to their base ASCII letter, so a plain query
-- letter matches every accented form (a == a/à/á/â/ã/ä/å/ā, c == ç/č, n == ñ,
-- ...). Keyed by integer code point, NOT by a byte-string: Civ VI's Lua does not
-- reliably match bytes >= 0x80 through string patterns or look them up as string
-- keys (the same locale/charset trap that makes %s corrupt UTF-8), so FoldText
-- decodes each character to a number and looks it up here. Code points absent
-- from this table -- ASCII, CJK, and any other script -- pass through untouched.
-- Vietnamese/Latin Extended Additional (3-byte) is not folded.
local CP_FOLD = {}
do
    local groups = {
        a = { 0xC0, 0xC1, 0xC2, 0xC3, 0xC4, 0xC5, 0xE0, 0xE1, 0xE2, 0xE3, 0xE4, 0xE5,
              0x100, 0x101, 0x102, 0x103, 0x104, 0x105 },
        c = { 0xC7, 0xE7, 0x106, 0x107, 0x108, 0x109, 0x10A, 0x10B, 0x10C, 0x10D },
        d = { 0x10E, 0x10F, 0x110, 0x111 },
        e = { 0xC8, 0xC9, 0xCA, 0xCB, 0xE8, 0xE9, 0xEA, 0xEB,
              0x112, 0x113, 0x114, 0x115, 0x116, 0x117, 0x118, 0x119, 0x11A, 0x11B },
        g = { 0x11C, 0x11D, 0x11E, 0x11F, 0x120, 0x121, 0x122, 0x123 },
        i = { 0xCC, 0xCD, 0xCE, 0xCF, 0xEC, 0xED, 0xEE, 0xEF,
              0x128, 0x129, 0x12A, 0x12B, 0x12C, 0x12D, 0x12E, 0x12F, 0x130, 0x131 },
        l = { 0x139, 0x13A, 0x13B, 0x13C, 0x13D, 0x13E, 0x13F, 0x140, 0x141, 0x142 },
        n = { 0xD1, 0xF1, 0x143, 0x144, 0x145, 0x146, 0x147, 0x148 },
        o = { 0xD2, 0xD3, 0xD4, 0xD5, 0xD6, 0xD8, 0xF2, 0xF3, 0xF4, 0xF5, 0xF6, 0xF8,
              0x14C, 0x14D, 0x14E, 0x14F, 0x150, 0x151 },
        r = { 0x154, 0x155, 0x156, 0x157, 0x158, 0x159 },
        s = { 0x15A, 0x15B, 0x15C, 0x15D, 0x15E, 0x15F, 0x160, 0x161, 0x218, 0x219 },
        t = { 0x162, 0x163, 0x164, 0x165, 0x166, 0x167, 0x21A, 0x21B },
        u = { 0xD9, 0xDA, 0xDB, 0xDC, 0xF9, 0xFA, 0xFB, 0xFC,
              0x168, 0x169, 0x16A, 0x16B, 0x16C, 0x16D, 0x16E, 0x16F, 0x170, 0x171, 0x172, 0x173 },
        y = { 0xDD, 0xFD, 0xFF, 0x176, 0x177, 0x178 },
        z = { 0x179, 0x17A, 0x17B, 0x17C, 0x17D, 0x17E },
    }
    for base, points in pairs(groups) do
        for _, cp in ipairs(points) do
            CP_FOLD[cp] = base
        end
    end
end

---Fold search text to a locale-safe comparison form: lowercase ASCII A-Z and map
---accented Latin letters to their base ASCII letter. Implemented as a raw byte
---scan using string.byte (integer comparisons only) instead of string patterns or
---string.lower: Civ VI's Lua is locale/charset-sensitive on bytes >= 0x80 (it
---misclassifies UTF-8 bytes in %-classes and does not reliably match them in
---pattern sets), so anything pattern-based here silently fails and corrupts CJK.
---Numeric byte handling is locale-independent. Query and label are folded through
---this same path so they stay byte-for-byte comparable.
---@param s string
---@return string
function S.FoldText(s)
    local out = {}
    local i = 1
    local n = #s
    while i <= n do
        local b = string.byte(s, i)
        if b >= 65 and b <= 90 then
            -- ASCII A-Z -> lowercase.
            out[#out + 1] = string.char(b + 32)
            i = i + 1
        elseif b >= 0xC2 and b <= 0xDF and i < n then
            -- Any 2-byte UTF-8 lead (0xC2-0xDF) + continuation (0x80-0xBF).
            -- Decode the code point numerically and fold it if it is a known
            -- accented Latin letter; otherwise keep both bytes unchanged.
            local b2 = string.byte(s, i + 1)
            if b2 >= 0x80 and b2 <= 0xBF then
                local cp = (b - 0xC0) * 0x40 + (b2 - 0x80)
                local base = CP_FOLD[cp]
                out[#out + 1] = base or string.sub(s, i, i + 1)
                i = i + 2
            else
                -- Malformed sequence; copy the lead byte and continue.
                out[#out + 1] = string.char(b)
                i = i + 1
            end
        else
            -- ASCII (non A-Z) or any byte of a 3-byte+ sequence (CJK, etc.):
            -- copy verbatim so multi-byte scripts are never altered.
            out[#out + 1] = string.char(b)
            i = i + 1
        end
    end
    return table.concat(out)
end
local FoldText = S.FoldText

-- TEMP load-time self-test: proves accent folding is active in the live engine.
-- Château = "Ch" .. \195\162(â) .. "teau"; expect "chateau". Remove once verified.
if LogMessage then
    LogMessage("Search helper fold self-test: FoldText('Ch\195\162teau')='"
        .. FoldText("Ch\195\162teau") .. "'")
end

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

local SEARCH_ORDER = {
    SEARCH_MATCH.START_WHOLE_WORD,
    SEARCH_MATCH.START_PREFIX,
    SEARCH_MATCH.WHOLE_WORD,
    SEARCH_MATCH.PREFIX,
    SEARCH_MATCH.SUBSTRING,
    SEARCH_MATCH.WORD_PREFIX_ABBREVIATION,
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

---Build a normalized type-to-find candidate for a custom candidate source.
---@param widget UIWidget
---@param label string
---@param bfsIndex integer
---@param tooltip? string
---@return SearchCandidate
function S.MakeSearchCandidate(widget, label, bfsIndex, tooltip)
    label = label or ""
    tooltip = tooltip or ""
    return {
        Widget = widget,
        Label = label,
        LabelLower = FoldText(label),
        Tooltip = tooltip,
        TooltipLower = FoldText(tooltip),
        BFSIndex = bfsIndex,
    }
end

---Collect all searchable widgets in breadth-first order.
---The returned list is used by the search engine for scoring and ranking.
---@param root UIWidget
---@param maxDepth integer
---@param includeTooltips? boolean
---@return SearchCandidate[]
function S.CollectSearchCandidates(root, maxDepth, includeTooltips)
    if not root or not root.Children then
        return {}
    end
    if includeTooltips == nil then
        includeTooltips = CAISettings.GetBool("TypeToFindIncludeTooltips")
    end

    ---@type SearchCandidate[]
    local candidates = {}
    local bfsIndex = 1

    -- Breadth-first, one level at a time. This preserves the exact visitation
    -- order (and therefore the BFSIndex tie-break ordering) of the previous
    -- queue-based walk, but stores plain widget references per level instead of
    -- allocating a { Widget, Depth } wrapper table for every node each keystroke.
    --
    -- Visibility: the previous walk called widget:IsHidden() on every node, which
    -- re-climbs the entire ancestor chain per node -- O(N * depth) and repeated
    -- game-control reads for the same ancestors. We only ever descend into
    -- children of already-visible widgets, so a node's OWN _hiddenFn is
    -- sufficient here: the ancestor chain is known visible. That is equivalent to
    -- IsHidden() for this top-down traversal and collapses the check to O(N).
    local level = {}
    for _, child in ipairs(root.Children) do
        level[#level + 1] = child
    end

    local depth = 0
    while #level > 0 do
        local nextLevel = {}
        for _, widget in ipairs(level) do
            local hiddenFn = widget._hiddenFn
            if not (hiddenFn and hiddenFn(widget)) then
                local label = widget:GetLabel()

                if label and label ~= "" then
                    local tooltip = ""
                    if includeTooltips then
                        tooltip = widget:GetTooltip() or ""
                    end
                    candidates[#candidates + 1] = S.MakeSearchCandidate(widget, label, bfsIndex, tooltip)

                    bfsIndex = bfsIndex + 1
                end

                if depth < maxDepth and widget.Children then
                    for _, child in ipairs(widget.Children) do
                        nextLevel[#nextLevel + 1] = child
                    end
                end
            end
        end
        level = nextLevel
        depth = depth + 1
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
                    Text = FoldText(text:sub(start, i - 1)),
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
            Text = FoldText(text:sub(start)),
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
---@param textLower? string
---@param textLength? integer
---@param sourceRank? integer
---@return SearchResult|nil
function S.ScoreSearchCandidate(candidate, query, tier, textLower, textLength, sourceRank)
    local label = textLower or candidate.LabelLower
    local matchLength = textLength or #candidate.Label
    local matchSourceRank = sourceRank or 0
    local pos
    if tier == SEARCH_MATCH.START_WHOLE_WORD then
        pos = MatchStartWholeWord(label, query)
        if pos then
            return {
                Candidate = candidate,
                Tier = SEARCH_MATCH.START_WHOLE_WORD,
                SourceRank = matchSourceRank,
                MatchPosition = pos,
                LabelLength = matchLength,
            }
        end
    end
    if tier == SEARCH_MATCH.START_PREFIX then
        pos = MatchStartPrefix(label, query)
        if pos then
            return {
                Candidate = candidate,
                Tier = SEARCH_MATCH.START_PREFIX,
                SourceRank = matchSourceRank,
                MatchPosition = pos,
                LabelLength = matchLength,
            }
        end
    end

    if tier == SEARCH_MATCH.WHOLE_WORD then
        pos = MatchWholeWord(label, query)
        if pos then
            return {
                Candidate = candidate,
                Tier = SEARCH_MATCH.WHOLE_WORD,
                SourceRank = matchSourceRank,
                MatchPosition = pos,
                LabelLength = matchLength,
            }
        end
    end

    if tier == SEARCH_MATCH.PREFIX then
        pos = MatchPrefix(label, query)
        if pos then
            return {
                Candidate = candidate,
                Tier = SEARCH_MATCH.PREFIX,
                SourceRank = matchSourceRank,
                MatchPosition = pos,
                LabelLength = matchLength,
            }
        end
    end

    if tier == SEARCH_MATCH.SUBSTRING then
        pos = MatchSubstring(label, query)
        if pos then
            return {
                Candidate = candidate,
                Tier = SEARCH_MATCH.SUBSTRING,
                SourceRank = matchSourceRank,
                MatchPosition = pos,
                LabelLength = matchLength,
            }
        end
    end

    if tier == SEARCH_MATCH.WORD_PREFIX_ABBREVIATION then
        pos = MatchWordPrefixAbbreviation(label, query)
        if pos then
            return {
                Candidate = candidate,
                Tier = SEARCH_MATCH.WORD_PREFIX_ABBREVIATION,
                SourceRank = matchSourceRank,
                MatchPosition = pos,
                LabelLength = matchLength,
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
    -- Closer to the current tree depth (the search anchor) sorts first; this only
    -- orders the list, it never removes farther matches. When proximity ties, the
    -- remaining keys (source, tier, position, length, BFS index) decide.
    local pa = a.Proximity or 0
    local pb = b.Proximity or 0
    if pa ~= pb then
        return pa > pb
    end

    if a.SourceRank ~= b.SourceRank then
        return a.SourceRank < b.SourceRank
    end

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
    if not char or char == "" then
        return false
    end

    -- Multi-byte input is a UTF-8 character (e.g. CJK); it is always a valid
    -- search start. The control/whitespace/digit/punctuation filter below only
    -- applies to single-byte ASCII.
    if #char ~= 1 then
        return true
    end

    local byte = string.byte(char)

    -- Reject control characters.
    if byte and byte < 32 then
        return false
    end

    -- Reject whitespace. Control chars are already rejected above; space is the
    -- only remaining ASCII whitespace. Avoid %s (locale-sensitive on raw bytes).
    if char == " " then
        return false
    end

    -- Reject digits.
    if char:match("%d") then
        return false
    end

    -- Reject common punctuation that is unlikely to begin a widget label.
    return not INVALID_SEARCH_START_CHARS[char]
end

---Map every widget on the path from the anchor up to (and including) root to its
---depth from root, so a deeper shared ancestor means a closer candidate. Returns
---nil when there is no usable anchor inside root, which disables proximity bias
---and preserves the plain global ordering.
---@param anchor UIWidget|nil
---@param root UIWidget
---@return table<UIWidget, integer>|nil
local function BuildFocusDepths(anchor, root)
    if not anchor then
        return nil
    end
    local chain = {}
    local node = anchor
    local reachedRoot = false
    while node do
        chain[#chain + 1] = node
        if node == root then
            reachedRoot = true
            break
        end
        node = node.Parent
    end
    -- Anchor is not inside this tree; nothing to bias toward.
    if not reachedRoot then
        return nil
    end
    -- chain[1] = anchor (deepest), chain[#chain] = root (depth 0).
    local depths = {}
    local n = #chain
    for i, w in ipairs(chain) do
        depths[w] = n - i
    end
    return depths
end

---Proximity of a candidate to the anchor: the depth of the deepest ancestor it
---shares with the anchor path. Larger is closer. Candidates outside the anchor
---path score below root (-1) so they only surface when nothing closer matches.
---@param widget UIWidget
---@param focusDepths table<UIWidget, integer>
---@return integer
local function CandidateProximity(widget, focusDepths)
    local node = widget
    while node do
        local d = focusDepths[node]
        if d then return d end
        node = node.Parent
    end
    return -1
end

---Score one candidate's text (label or tooltip) at its best matching tier.
---Returns the SearchResult with Proximity filled in, or nil when nothing matched.
---@param candidate SearchCandidate
---@param query string
---@param textLower string
---@param textLength integer
---@param sourceRank integer
---@param focusDepths? table<UIWidget, integer>
---@return SearchResult|nil
local function ScoreText(candidate, query, textLower, textLength, sourceRank, focusDepths)
    if textLower == "" then return nil end
    for _, tier in ipairs(SEARCH_ORDER) do
        local result = S.ScoreSearchCandidate(candidate, query, tier, textLower, textLength, sourceRank)
        if result then
            result.Proximity = focusDepths
                and CandidateProximity(candidate.Widget, focusDepths)
                or 0
            return result
        end
    end
    return nil
end

---Score every candidate at its best matching tier and return them all, ranked.
---Proximity, tier, match position, and length only ORDER the list (via
---CompareSearchResults); nothing is dropped for "losing". A closer or stronger
---match sorts to the front, but a weaker or farther match still appears further
---down instead of vanishing, so every widget that matches the query is reachable.
---
---Single pass over the candidates: each is scored against its label first; only
---when the label does not match is the tooltip scored. Label and tooltip hits go
---to separate buckets, sorted independently, then concatenated (all label matches
---ahead of all tooltip matches). This preserves the exact ordering of the former
---two-pass form -- label results never interleave with tooltip results -- while
---iterating the candidate list once instead of twice and dropping the
---excluded-widgets bookkeeping (a label hit simply skips its own tooltip).
---@param candidates SearchCandidate[]
---@param query string
---@param includeTooltips boolean
---@param focusDepths? table<UIWidget, integer>
---@return SearchResult[]
local function FindRankedResults(candidates, query, includeTooltips, focusDepths)
    ---@type SearchResult[]
    local labelResults = {}
    ---@type SearchResult[]
    local tooltipResults = {}

    for _, candidate in ipairs(candidates) do
        local labelResult = ScoreText(
            candidate, query, candidate.LabelLower, #candidate.Label, 0, focusDepths)
        if labelResult then
            labelResults[#labelResults + 1] = labelResult
        elseif includeTooltips then
            local tooltipResult = ScoreText(
                candidate, query, candidate.TooltipLower, #candidate.Tooltip, 1, focusDepths)
            if tooltipResult then
                tooltipResults[#tooltipResults + 1] = tooltipResult
            end
        end
    end

    table.sort(labelResults, S.CompareSearchResults)
    table.sort(tooltipResults, S.CompareSearchResults)
    for _, result in ipairs(tooltipResults) do
        labelResults[#labelResults + 1] = result
    end
    return labelResults
end

---Find all matching widgets sorted from best to worst.
---@param root UIWidget
---@param query string
---@param maxDepth integer
---@return SearchResult[]
function S.FindSearchResults(root, query, maxDepth)
    if not root then
        return {}
    end

    local includeTooltips = CAISettings.GetBool("TypeToFindIncludeTooltips")
    local candidates
    if type(root.GetTypeToFindCandidates) == "function" then
        candidates = root:GetTypeToFindCandidates(includeTooltips)
    else
        candidates = S.CollectSearchCandidates(root, maxDepth, includeTooltips)
    end

    -- Bias results toward where focus was when the query began (the current tree
    -- depth). Falls back to live focus, then to no bias, so plain callers are
    -- unaffected.
    local mgr = root.Manager
    local anchor = mgr and (mgr:GetSearchAnchor() or mgr:GetFocusedWidget())
    local focusDepths = BuildFocusDepths(anchor, root)

    return FindRankedResults(candidates, query, includeTooltips, focusDepths)
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

---@param results SearchResult[]
---@param focused UIWidget|nil
---@param root UIWidget
---@return integer|nil
local function FindFocusedSearchResult(results, focused, root)
    local node = focused
    while node and node ~= root do
        for i, result in ipairs(results) do
            if result.Candidate.Widget == node then
                return i
            end
        end
        node = node.Parent
    end
    return nil
end

---Classify one label against a query using the shared type-to-find tiers.
---Returns the best matching tier for this label, or nil when it does not match.
---@param label string
---@param query string
---@return SearchResult|nil
function S.MatchSearchText(label, query)
    if label == nil or label == "" or query == nil or query == "" then
        return nil
    end

    local candidate = {
        Label = label,
        LabelLower = FoldText(label),
        BFSIndex = 0,
    }
    local lowerQuery = FoldText(query)

    for _, tier in ipairs(SEARCH_ORDER) do
        local result = S.ScoreSearchCandidate(candidate, lowerQuery, tier)
        if result ~= nil then
            return result
        end
    end

    return nil
end

---Navigate the current type-to-find result set without changing its existing
---collection, match-tier, or ranking behavior. Returns false when persistent
---result navigation is not active so the container can use ordinary Up/Down.
---@param root UIWidget
---@param direction 1|-1
---@param maxDepth? integer
---@return boolean
function S.NavigateResults(root, direction, maxDepth)
    local mgr = root.Manager
    if not mgr then
        LogWarn("Search helper NavigateResults called without manager")
        return false
    end
    if not CAISettings.GetBool("TypeToFindResultNavigation")
        or mgr.TypeToFindTarget ~= root
        or mgr:GetSearchBuffer() == "" then
        return false
    end

    local results = S.FindSearchResults(root, mgr:GetSearchBuffer(), maxDepth or 5)
    if #results == 0 then
        Speak(Locale.Lookup("LOC_CAI_SEARCH_NO_MATCH"))
        return true
    end

    local currentIndex = FindFocusedSearchResult(results, mgr:GetFocusedWidget(), root)
    local resultIndex
    local wrapped = false
    if currentIndex then
        resultIndex = currentIndex + direction
        if resultIndex < 1 then
            resultIndex = #results
            wrapped = true
        elseif resultIndex > #results then
            resultIndex = 1
            wrapped = true
        end
    else
        resultIndex = direction > 0 and 1 or #results
    end

    local target = results[resultIndex].Candidate.Widget
    if target.IsTreeItem then
        CAIWidgetHelpers_Tree.ClearDescent(target)
    end
    mgr:SetFocus(target)
    if wrapped then root:Emit("navigation_wrap", direction) end
    LogMessage("Search helper NavigateResults focused search result " .. tostring(resultIndex)
        .. " of " .. tostring(#results))
    return true
end

---@param root UIWidget
---@param maxDepth integer
---@param repeatSearch boolean
---@return boolean
function S.ApplyCurrentBuffer(root, maxDepth, repeatSearch)
    local mgr = root.Manager
    if not mgr then
        LogWarn("Search helper ApplyCurrentBuffer called without manager")
        return false
    end

    local results = S.FindSearchResults(root, mgr:GetSearchBuffer(), maxDepth or 5)

    if #results == 0 then
        LogMessage("Search helper ApplyCurrentBuffer NO MATCH for buffer='"
            .. mgr:GetSearchBuffer() .. "'")
        Speak(Locale.Lookup("LOC_CAI_SEARCH_NO_MATCH"))
        return false
    end

    local resultIndex = 1

    if repeatSearch then
        resultIndex = S.FindNextSearchResult(results, mgr:GetFocusedWidget())
    end

    mgr:SetFocus(results[resultIndex].Candidate.Widget)
    LogMessage("Search helper ApplyCurrentBuffer buffer='" .. mgr:GetSearchBuffer()
        .. "' focused search result " .. tostring(resultIndex)
        .. " of " .. tostring(#results))
    return true
end

---Convenience: handle a single char input on the widget for search.
---Returns true if a match was focused; speaks the no-match message otherwise.
---
---Same-letter cycling: pressing the same single letter again while that
---single-character search remains active keeps the buffer unchanged but
---advances to the next matching widget, wrapping when necessary.
---@param root UIWidget
---@param char string
---@param maxDepth? integer
---@return boolean
function S.HandleChar(root, char, maxDepth)
    local mgr = root.Manager
    if not mgr then
        LogWarn("Search helper HandleChar called without manager")
        return false
    end

    local prev = mgr:GetSearchBuffer()

    if #prev == 0 and not S.IsValidSearchStartCharacter(char) then
        LogMessage("Search helper rejected invalid search start character '" .. tostring(char) .. "'")
        return false
    end

    if CAISettings.GetBool("TypeToFindResultNavigation") then
        mgr:BeginTypeToFind(root)
        prev = mgr:GetSearchBuffer()
    end

    -- Same-letter cycling is a single-byte concept, so this comparison stays
    -- false for multi-byte characters, which is correct. FoldText matches the
    -- fold used when the buffer was built.
    local repeatSearch = #prev == 1 and #char == 1 and prev == FoldText(char)

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
        LogWarn("Search helper HandleBackspace called without manager")
        return false
    end

    local buffer = mgr:GetSearchBuffer()
    if buffer == "" then
        LogMessage("Search helper HandleBackspace ignored because search buffer is empty")
        return false
    end

    local nextBuffer = mgr:RemoveSearchChar()
    if nextBuffer == "" then
        LogMessage("Search helper cleared search buffer via backspace")
        Speak(Locale.Lookup("LOC_CAI_SEARCH_CLEARED"))
        return true
    end

    return S.ApplyCurrentBuffer(root, maxDepth or 5, false)
end

--#endregion
