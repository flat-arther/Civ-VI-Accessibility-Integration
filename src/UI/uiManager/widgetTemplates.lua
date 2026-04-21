-- I am putting all templates in this file for now because I don't want to have to add each one in the modinfo file.
        ---@class WidgetTemplate :UIWidget
        ---@field RegisterInputs InputBinding[]
        
--#Nav helpers

---Finds the first visible child in a widget's Children list, searching from startIdx in the given direction.
---Returns the child and its index, or nil if none found.
---@param w UIWidget
---@param startIdx integer -- 1-based index to start searching from
---@param direction 1|-1
---@param allowWrap boolean -- whether to wrap around past the boundary
---@return UIWidget|nil, integer|nil
function FindVisibleChild(w, startIdx, direction, allowWrap)
    local children = w.Children
    if not children then return nil, nil end
    local numChildren = #children
    if numChildren == 0 then return nil, nil end

    for i = 1, numChildren do
        local idx = (startIdx + (i * direction) - 1) % numChildren + 1
        local candidate = children[idx]
        local isHidden = candidate.IsHidden and candidate:IsHidden()
        if not isHidden then
            -- Check if we crossed a boundary
            if not allowWrap then
                local crossedBoundary = false
                if direction > 0 then
                    crossedBoundary = idx < startIdx
                else
                    crossedBoundary = idx > startIdx
                end
                if crossedBoundary then return nil, nil end
            end
            return candidate, idx
        end
    end
    return nil, nil
end

---Finds the first visible child scanning forward from index 1
---@param w UIWidget
---@return UIWidget|nil
function FindFirstVisibleChild(w)
    if not w.Children or #w.Children == 0 then return nil end
    for _, child in ipairs(w.Children) do
        local isHidden = child.IsHidden and child:IsHidden()
        if not isHidden then return child end
    end
    return nil
end

---Finds the last visible child scanning backward from the end
---@param w UIWidget
---@return UIWidget|nil
function FindLastVisibleChild(w)
    if not w.Children or #w.Children == 0 then return nil end
    for i = #w.Children, 1, -1 do
        local child = w.Children[i]
        local isHidden = child.IsHidden and child:IsHidden()
        if not isHidden then return child end
    end
    return nil
end

---Internal navigation helper using FindVisibleChild
---@param w UIWidget
---@param direction 1|-1
---@return boolean
local function NavigateSimpleList(w, direction)
    local children = w.Children
    if not children or #children == 0 then return false end
    local startIdx = w:GetChildIndex(w.FocusedChild) or w.DefaultIndex or 0
    local candidate = FindVisibleChild(w, startIdx, direction, w.WrapAround)
    if candidate then
        w.Manager:SetFocus(candidate)
        return true
    end
    return false
end

---Navigates to the first visible child
---@param w UIWidget
---@return boolean
local function NavigateToFirst(w)
    local child = FindFirstVisibleChild(w)
    if child then
        w.Manager:SetFocus(child)
        return true
    end
    return false
end

---Navigates to the last visible child
---@param w UIWidget
---@return boolean
local function NavigateToLast(w)
    local child = FindLastVisibleChild(w)
    if child then
        w.Manager:SetFocus(child)
        return true
    end
    return false
end

---GetDefaultChild function for containers. Returns focused widget if any, otherwise the first visible child
---@param w UIWidget
function GetContainerDefChild(w)
    if not w.Children or #w.Children == 0 then return end
    if w.FocusedChild then return w.FocusedChild end
    return FindFirstVisibleChild(w)
end

--#Search helpers
---Finds next match to query, starting from given root and stopping at maxDepth
---@param root UIWidget
---@param query string
---@param maxDepth integer
---@return UIWidget|nil
local function FindNextMatch(root, query, maxDepth)
    local children = root.Children
    if not children or #children == 0 then return nil end

    local startIdx = root:GetChildIndex(root.FocusedChild) or 0
    local count = #children

    -- Scan siblings in wrap-around order
    for i = 1, count do
        local idx = ((startIdx + i - 1) % count) + 1
        local candidate = children[idx]

        local found = FindMatchDFS(candidate, query, 0, maxDepth)
        if found then
            return found
        end
    end

    return nil
end

---@param w UIWidget
---@param query string
---@param depth integer
---@param maxDepth integer
---@return UIWidget|nil
function FindMatchDFS(w, query, depth, maxDepth)
    if not w then return nil end

    if w.IsHidden and w:IsHidden() then return nil end

    if w.GetLabel then
        local label = w:GetLabel()
        if label and label:lower():find(query, 1, true) == 1 then
            return w
        end
    end

    if depth >= maxDepth then return nil end

    if w.Children then
        for _, child in ipairs(w.Children) do
            local found = FindMatchDFS(child, query, depth + 1, maxDepth)
            if found then return found end
        end
    end

    return nil
end

--#EditBox helpers

---Returns the selection range as (low, high) or nil if no selection
---@param w UIWidget
---@return integer|nil, integer|nil
function EditBox_GetSelectionRange(w)
    if not w.EditSelStart then return nil, nil end
    local a, b = w.EditSelStart, w.EditCursor
    if a > b then a, b = b, a end
    return a, b
end

---Returns the currently selected text, or empty string
---@param w UIWidget
---@return string
function EditBox_GetSelectedText(w)
    local a, b = EditBox_GetSelectionRange(w)
    if not a then return "" end
    return string.sub(w.EditBuffer, a + 1, b)
end

---Activates the edit box for text input
---@param w UIWidget
function EditBox_Activate(w)
    local text = w.GetValue and w:GetValue() or ""
    text = string.gsub(text, "\r\n", "\n")
    w.EditBuffer = text
    w.EditActive = true
    w.EditOriginal = text
    local label = w.GetLabel and w:GetLabel() or ""
    if w.HighlightOnEdit and #text > 0 then
        w.EditSelStart = 0
        w.EditCursor = #text
        Speak(Locale.Lookup("LOC_CAI_EDIT_ACTIVATE_SELECTED", label, text), true)
    else
        w.EditCursor = #text
        w.EditSelStart = nil
        local displayText = #text > 0 and text or Locale.Lookup("LOC_CAI_EDIT_BLANK")
        Speak(Locale.Lookup("LOC_CAI_EDIT_ACTIVATE", label, displayText), true)
    end
end

---Commits the current buffer and deactivates
---@param w UIWidget
function EditBox_Commit(w)
    w.EditActive = false
    w.EditSelStart = nil
    local text = w.EditBuffer or ""
    if w.OnSetText then w:OnSetText(text) end
    if w.OnCommit then w:OnCommit(text) end
    Speak(Locale.Lookup("LOC_CAI_EDIT_COMMITTED", text))
end

---Cancels editing, restores original text, deactivates
---@param w UIWidget
function EditBox_Cancel(w)
    w.EditActive = false
    w.EditSelStart = nil
    w.EditBuffer = w.EditOriginal or ""
    w.EditCursor = 0
    if w.OnSetText then w:OnSetText(w.EditBuffer) end
    Speak(Locale.Lookup("LOC_CAI_EDIT_CANCELLED"))
end

---Syncs the buffer to the game control via OnSetText
---@param w UIWidget
function EditBox_SyncAndSpeak(w)
    if w.OnSetText then w:OnSetText(w.EditBuffer) end
end

---Sets the text of an Edit widget, normalizing [NEWLINE] tokens into real newlines
---@param w UIWidget
---@param text string|nil
function EditBox_SetText(w, text)
    if not w then return end
    text = text or ""
    text = string.gsub(text, "%[NEWLINE%]", "\n")
    text = string.gsub(text, "\r\n", "\n")
    w.EditBuffer = text
    w.EditCursor = 0
    w.EditSelStart = nil
    if w.EditActive then w.EditOriginal = text end
    if w.OnSetText then w:OnSetText(text) end
end

---Deletes the selected text, collapsing the selection. Returns deleted text.
---@param w UIWidget
---@return string -- the deleted text
function EditBox_DeleteSelection(w)
    local a, b = EditBox_GetSelectionRange(w)
    if not a then return "" end
    local deleted = string.sub(w.EditBuffer, a + 1, b)
    w.EditBuffer = string.sub(w.EditBuffer, 1, a) .. string.sub(w.EditBuffer, b + 1)
    w.EditCursor = a
    w.EditSelStart = nil
    return deleted
end

---Inserts text at cursor, replacing any selection
---@param w UIWidget
---@param text string
function EditBox_InsertText(w, text)
    text = string.gsub(text, "\r\n", "\n")
    if w.EditSelStart then
        EditBox_DeleteSelection(w)
    end
    local buf = w.EditBuffer or ""
    local pos = w.EditCursor or 0
    w.EditBuffer = string.sub(buf, 1, pos) .. text .. string.sub(buf, pos + 1)
    w.EditCursor = pos + #text
end

---Deletes the character before the cursor
---@param w UIWidget
function EditBox_BackspaceChar(w)
    local pos = w.EditCursor or 0
    if pos <= 0 then return end
    local buf = w.EditBuffer or ""
    local deleted = string.sub(buf, pos, pos)
    w.EditBuffer = string.sub(buf, 1, pos - 1) .. string.sub(buf, pos + 1)
    w.EditCursor = pos - 1
    Speak(deleted, true)
end

---Deletes the character after the cursor
---@param w UIWidget
function EditBox_DeleteChar(w)
    local pos = w.EditCursor or 0
    local buf = w.EditBuffer or ""
    if pos >= #buf then return end
    local deleted = string.sub(buf, pos + 1, pos + 1)
    w.EditBuffer = string.sub(buf, 1, pos) .. string.sub(buf, pos + 2)
    Speak(deleted, true)
end

---Finds the word boundary to the left of pos for navigation (Ctrl+Left).
---Lands at the start of the current/previous word.
---Returns true if the character is a word boundary (whitespace or newline)
---@param ch string
---@return boolean
local function IsWordBoundary(ch)
    return ch == " " or ch == "\n" or ch == "\t"
end

---@param buf string
---@param pos integer -- 0-based cursor position
---@return integer -- 0-based position
function EditBox_FindWordLeft(buf, pos)
    if pos <= 0 then return 0 end
    local i = pos
    -- Skip whitespace before cursor (but stop at newlines)
    while i > 0 and string.sub(buf, i, i) == " " do
        i = i - 1
    end
    -- Stop at newline boundary
    if i > 0 and string.sub(buf, i, i) == "\n" then return i end
    -- Skip word chars to find start of word
    while i > 0 and not IsWordBoundary(string.sub(buf, i, i)) do
        i = i - 1
    end
    return i
end

---Finds the delete boundary to the left of pos for Ctrl+Backspace.
---Deletes the word AND any whitespace between it and the previous word,
---so no orphan spaces are left behind. Stops at newline boundaries.
---@param buf string
---@param pos integer -- 0-based cursor position
---@return integer -- 0-based position
function EditBox_FindDeleteLeft(buf, pos)
    if pos <= 0 then return 0 end
    local i = pos
    -- Skip spaces immediately before cursor (stop at newlines)
    local skippedSpace = false
    while i > 0 and string.sub(buf, i, i) == " " do
        i = i - 1
        skippedSpace = true
    end
    -- If we hit a newline, stop here (delete just the spaces + newline)
    if i > 0 and string.sub(buf, i, i) == "\n" then
        return i - 1
    end
    -- Skip word chars (stop at any boundary)
    while i > 0 and not IsWordBoundary(string.sub(buf, i, i)) do
        i = i - 1
    end
    -- If we didn't skip whitespace initially (cursor was right after a word),
    -- also consume spaces before the word so we don't leave orphan spaces
    if not skippedSpace then
        while i > 0 and string.sub(buf, i, i) == " " do
            i = i - 1
        end
    end
    return i
end

---Returns the word starting at/after pos, skipping any leading whitespace.
---Used when speaking after Ctrl+Left/Right so the user hears the full word, not just its first char.
---@param buf string
---@param pos integer -- 0-based cursor position
---@return string
function EditBox_GetWordAt(buf, pos)
    local len = #buf
    if pos >= len then return "" end
    local i = pos + 1
    while i <= len and IsWordBoundary(string.sub(buf, i, i)) do
        i = i + 1
    end
    local start = i
    while i <= len and not IsWordBoundary(string.sub(buf, i, i)) do
        i = i + 1
    end
    return string.sub(buf, start, i - 1)
end

---Finds the word boundary to the right of pos (start of next word, or end of string)
---@param buf string
---@param pos integer -- 0-based
---@return integer -- 0-based position
function EditBox_FindWordRight(buf, pos)
    local len = #buf
    if pos >= len then return len end
    local i = pos + 1
    -- Stop at newline boundary
    if string.sub(buf, i, i) == "\n" then return pos + 1 end
    -- Skip current word chars
    while i <= len and not IsWordBoundary(string.sub(buf, i, i)) do
        i = i + 1
    end
    -- Skip spaces after word (but stop at newlines)
    while i <= len and string.sub(buf, i, i) == " " do
        i = i + 1
    end
    return i - 1
end

---Deletes the word before the cursor (including adjacent whitespace)
---@param w UIWidget
function EditBox_BackspaceWord(w)
    local pos = w.EditCursor or 0
    if pos <= 0 then return end
    local buf = w.EditBuffer or ""
    local deleteStart = EditBox_FindDeleteLeft(buf, pos)
    local deleted = string.sub(buf, deleteStart + 1, pos)
    w.EditBuffer = string.sub(buf, 1, deleteStart) .. string.sub(buf, pos + 1)
    w.EditCursor = deleteStart
    Speak(deleted, true)
end

---Deletes the word after the cursor
---@param w UIWidget
function EditBox_DeleteWordForward(w)
    local pos = w.EditCursor or 0
    local buf = w.EditBuffer or ""
    if pos >= #buf then return end
    local wordEnd = EditBox_FindWordRight(buf, pos)
    local deleted = string.sub(buf, pos + 1, wordEnd)
    w.EditBuffer = string.sub(buf, 1, pos) .. string.sub(buf, wordEnd + 1)
    Speak(deleted, true)
end

--#Line helpers for edit box

---Returns the start position (0-based) of the line containing pos
---@param buf string
---@param pos integer -- 0-based cursor position
---@return integer
function EditBox_LineStart(buf, pos)
    if pos <= 0 then return 0 end
    local i = pos
    while i > 0 and string.sub(buf, i, i) ~= "\n" do
        i = i - 1
    end
    -- If we stopped on a newline, line starts one past it
    if i > 0 then return i end
    return 0
end

---Returns the end position (0-based, after last char) of the line containing pos
---@param buf string
---@param pos integer -- 0-based cursor position
---@return integer
function EditBox_LineEnd(buf, pos)
    local len = #buf
    local i = pos + 1
    while i <= len and string.sub(buf, i, i) ~= "\n" do
        i = i + 1
    end
    return i - 1
end

---Returns the text of the line containing pos
---@param buf string
---@param pos integer -- 0-based cursor position
---@return string
function EditBox_GetCurrentLine(buf, pos)
    local ls = EditBox_LineStart(buf, pos)
    local le = EditBox_LineEnd(buf, pos)
    return string.sub(buf, ls + 1, le)
end

---Speaks the line at pos, saying "Blank" for empty lines
---@param buf string
---@param pos integer -- 0-based cursor position
local function SpeakLine(buf, pos)
    local line = EditBox_GetCurrentLine(buf, pos)
    Speak(#line > 0 and line or Locale.Lookup("LOC_CAI_EDIT_BLANK"), true)
end

---Moves cursor to the previous line, keeping column offset. Returns new pos or nil if no prev line.
---@param buf string
---@param pos integer -- 0-based
---@return integer|nil
function EditBox_PrevLinePos(buf, pos)
    local ls = EditBox_LineStart(buf, pos)
    if ls <= 0 then return nil end -- already on first line
    local col = pos - ls
    -- prevLineEnd is the 0-based exclusive end of the previous line (the position
    -- just before the \n that starts the current line).
    local prevLineEnd = ls - 1
    -- Empty previous line: the char at 1-based position prevLineEnd is itself a \n
    -- (i.e., two \n's back-to-back). LineStart from prevLineEnd-1 would land on the
    -- line BEFORE the empty one and skip it, so handle this case explicitly.
    if prevLineEnd > 0 and string.sub(buf, prevLineEnd, prevLineEnd) == "\n" then
        return prevLineEnd
    end
    local prevLineStart = EditBox_LineStart(buf, prevLineEnd - 1)
    local prevLineLen = prevLineEnd - prevLineStart
    local newCol = math.min(col, prevLineLen)
    return prevLineStart + newCol
end

---Moves cursor to the next line, keeping column offset. Returns new pos or nil if no next line.
---@param buf string
---@param pos integer -- 0-based
---@return integer|nil
function EditBox_NextLinePos(buf, pos)
    local le = EditBox_LineEnd(buf, pos)
    local len = #buf
    if le >= len then return nil end -- already on last line
    -- Next line starts at le + 1 (skip the \n)
    local nextLineStart = le + 1
    local nextLineEnd = EditBox_LineEnd(buf, nextLineStart)
    local col = pos - EditBox_LineStart(buf, pos)
    local nextLineLen = nextLineEnd - nextLineStart
    local newCol = math.min(col, nextLineLen)
    return nextLineStart + newCol
end

---Speaks selection changes: newly selected chars say "X selected",
---lost selection says "X unselected"
---@param w UIWidget
---@param oldSelStart integer|nil
---@param oldCursor integer
local function SpeakSelectionChange(w, oldSelStart, oldCursor)
    local buf = w.EditBuffer or ""

    -- Determine old and new selected ranges
    local oldA, oldB
    if oldSelStart then
        oldA, oldB = oldSelStart, oldCursor
        if oldA > oldB then oldA, oldB = oldB, oldA end
    end
    local newA, newB = EditBox_GetSelectionRange(w)

    -- Selection was removed entirely
    if oldA and not newA then
        local deselected = string.sub(buf, oldA + 1, oldB)
        if deselected ~= "" then
            Speak(Locale.Lookup("LOC_CAI_EDIT_UNSELECTED", deselected), true)
        end
        return
    end

    -- No selection before or after
    if not newA then
        local charAtCursor = string.sub(buf, w.EditCursor + 1, w.EditCursor + 1)
        if charAtCursor == "" then charAtCursor = Locale.Lookup("LOC_CAI_EDIT_BLANK") end
        Speak(charAtCursor, true)
        return
    end

    -- Selection grew or shrank — find the delta
    if not oldA then
        -- Fresh selection from no selection
        local sel = string.sub(buf, newA + 1, newB)
        if sel ~= "" then
            Speak(Locale.Lookup("LOC_CAI_EDIT_SELECTED", sel), true)
        end
        return
    end

    -- Both old and new selection exist — find what changed
    -- The anchor stays the same; only the cursor moved
    local oldEdge = oldCursor
    local newEdge = w.EditCursor
    if oldEdge == newEdge then return end

    local anchor = w.EditSelStart
    -- Determine if selection grew or shrank
    local oldDist = math.abs(oldEdge - anchor)
    local newDist = math.abs(newEdge - anchor)

    if newDist > oldDist then
        -- Selection grew: speak newly selected chars
        local lo = math.min(oldEdge, newEdge)
        local hi = math.max(oldEdge, newEdge)
        local added = string.sub(buf, lo + 1, hi)
        if added ~= "" then
            Speak(Locale.Lookup("LOC_CAI_EDIT_SELECTED", added), true)
        end
    else
        -- Selection shrank: speak deselected chars
        local lo = math.min(oldEdge, newEdge)
        local hi = math.max(oldEdge, newEdge)
        local removed = string.sub(buf, lo + 1, hi)
        if removed ~= "" then
            Speak(Locale.Lookup("LOC_CAI_EDIT_UNSELECTED", removed), true)
        end
    end
end

---Moves the cursor by direction (char or word), optionally extending selection
---@param w UIWidget
---@param direction 1|-1
---@param shift boolean -- extend selection
---@param ctrl boolean -- word-level movement
function EditBox_MoveCursor(w, direction, shift, ctrl)
    local buf = w.EditBuffer or ""
    local pos = w.EditCursor or 0
    local oldSelStart = w.EditSelStart
    local oldCursor = pos

    -- If there is a selection and no shift, collapse to the appropriate edge
    if w.EditSelStart and not shift then
        local a, b = EditBox_GetSelectionRange(w)
        local deselected = EditBox_GetSelectedText(w)
        w.EditCursor = (direction < 0) and a or b
        w.EditSelStart = nil
        if deselected ~= "" then
            Speak(Locale.Lookup("LOC_CAI_EDIT_UNSELECTED", deselected), true)
        end
        return
    end

    -- Start selection anchor if shift is held and we don't have one
    if shift and not w.EditSelStart then
        w.EditSelStart = pos
    end

    local newPos
    if ctrl then
        if direction < 0 then
            newPos = EditBox_FindWordLeft(buf, pos)
        else
            newPos = EditBox_FindWordRight(buf, pos)
        end
    else
        newPos = pos + direction
    end

    -- Clamp
    if newPos < 0 then newPos = 0 end
    if newPos > #buf then newPos = #buf end
    w.EditCursor = newPos

    -- Clear selection if not shift
    if not shift then
        w.EditSelStart = nil
    end

    -- When shift is held, speak selection change; when ctrl (word move), speak the
    -- word at the new cursor position; otherwise speak the single char at cursor.
    if shift then
        SpeakSelectionChange(w, oldSelStart, oldCursor)
    elseif ctrl then
        local word = EditBox_GetWordAt(buf, newPos)
        if word == "" then word = Locale.Lookup("LOC_CAI_EDIT_BLANK") end
        Speak(word, true)
    else
        local charAtCursor = string.sub(buf, newPos + 1, newPos + 1)
        if charAtCursor == "" or charAtCursor == "\n" then
            charAtCursor = Locale.Lookup("LOC_CAI_EDIT_BLANK")
        end
        Speak(charAtCursor, true)
    end
end

---Moves the cursor to a specific position (for Home/End)
---@param w UIWidget
---@param targetPos integer -- 0-based
---@param shift boolean -- extend selection
function EditBox_MoveToEdge(w, targetPos, shift)
    local buf = w.EditBuffer or ""
    local pos = w.EditCursor or 0
    local oldSelStart = w.EditSelStart
    local oldCursor = pos

    if shift and not w.EditSelStart then
        w.EditSelStart = pos
    end

    w.EditCursor = targetPos

    if not shift then
        w.EditSelStart = nil
    end

    SpeakSelectionChange(w, oldSelStart, oldCursor)
end

---Selects all text in the edit box (Ctrl+A)
---@param w UIWidget
function EditBox_SelectAll(w)
    local buf = w.EditBuffer or ""
    if #buf == 0 then
        Speak(Locale.Lookup("LOC_CAI_EDIT_BLANK"), true)
        return
    end
    w.EditSelStart = 0
    w.EditCursor = #buf
    Speak(Locale.Lookup("LOC_CAI_EDIT_SELECTED", buf), true)
end

---@type table<string, WidgetTemplate>
WidgetTemplates = {
    Panel = {
        DefaultIndex = 1,
        WrapAround = true,
        RegisterInputs = {
            { Key = Keys.VK_TAB, MSG = KeyEvents.KeyDown, Action = function(w) return w:Navigate(1) end },
            { Key = Keys.VK_TAB, MSG = KeyEvents.KeyDown, IsShift = true, Action = function(w) return w:Navigate(-1) end },
        },
        Navigate = NavigateSimpleList,
        GetDefaultChild = GetContainerDefChild
    },
    List = {
        DefaultIndex = 1,
        WrapAround = true,
        IsExpanded = true,
        RegisterInputs = {
            { Key = Keys.VK_UP, MSG = KeyEvents.KeyDown, Action = function(w) return w:Navigate(-1) end },
            { Key = Keys.VK_DOWN, MSG = KeyEvents.KeyDown, Action = function(w) return w:Navigate(1) end },
            { Key = Keys.VK_HOME, MSG = KeyEvents.KeyDown, Action = function(w) return NavigateToFirst(w) end },
            { Key = Keys.VK_END, MSG = KeyEvents.KeyDown, Action = function(w) return NavigateToLast(w) end },
        },
        Navigate = NavigateSimpleList,
        GetDefaultChild = GetContainerDefChild,
        OnCharInput = function(w, char)
    local mgr = w.Manager

    mgr:AppendSearchChar(char)
    local query = mgr.SearchBuffer

    local maxDepth = w.SearchDepth or 2
    local match = FindNextMatch(w, query, maxDepth)
    if match then
        mgr:SetFocus(match)
        return true
    end
    Speak(Locale.Lookup("LOC_CAI_SEARCH_NO_MATCH"))
    return false
end
    },
    HorizontalList = {
        DefaultIndex = 1,
        WrapAround = true,
        IsExpanded = true,
        RegisterInputs = {
            { Key = Keys.VK_LEFT, MSG = KeyEvents.KeyDown, Action = function(w) return w:Navigate(-1) end },
            { Key = Keys.VK_RIGHT, MSG = KeyEvents.KeyDown, Action = function(w) return w:Navigate(1) end },
            { Key = Keys.VK_HOME, MSG = KeyEvents.KeyDown, Action = function(w) return NavigateToFirst(w) end },
            { Key = Keys.VK_END, MSG = KeyEvents.KeyDown, Action = function(w) return NavigateToLast(w) end },
        },
        Navigate = NavigateSimpleList,
        GetDefaultChild = GetContainerDefChild
    },
    SubMenu = { --- Basically a list but with different nav behavior, and expand collapse actions
        DefaultIndex = 1,
        WrapAround = true,
        IsExpanded = false,
        RegisterInputs = {
            { Key = Keys.VK_UP, MSG = KeyEvents.KeyDown, Action = function(w)
                if w.IsExpanded then
                    w:Navigate(-1)
                    return true
                end
                return false
            end },
            { Key = Keys.VK_DOWN, MSG = KeyEvents.KeyDown, Action = function(w)
                if w.IsExpanded then
                    w:Navigate(1)
                    return true
                end
                return false
            end },
            { Key = Keys.VK_RETURN, MSG = KeyEvents.KeyDown, Action = function(w) return w:Expand() end},
            { Key = Keys.VK_RIGHT, MSG = KeyEvents.KeyDown, Action = function(w) return w:Expand() end},
            { Key = Keys.VK_LEFT, MSG = KeyEvents.KeyDown, Action = function(w)
                if w.IsExpanded then
                    w.IsExpanded = false
                    w.FocusedChild = nil
                    w.Manager:SetFocus(w)
                    if w.OnToggleExpanded then w:OnToggleExpanded(w.IsExpanded) end
                    return true
                end
                return false
            end },
            { Key = Keys.VK_HOME, MSG = KeyEvents.KeyDown, Action = function(w)
                if w.IsExpanded then return NavigateToFirst(w) end
                return false
            end },
            { Key = Keys.VK_END, MSG = KeyEvents.KeyDown, Action = function(w)
                if w.IsExpanded then return NavigateToLast(w) end
                return false
            end },
        },
        Navigate = NavigateSimpleList,
        Expand = function(w)
                if not w.IsExpanded and w.Children and #w.Children > 0 then
                    w.IsExpanded = true
                    if w.OnToggleExpanded then w:OnToggleExpanded(w.IsExpanded) end
                    w:Navigate(0)
                    return true
                end
                return false
            end,
        GetDefaultChild = function(w)
            if w.IsExpanded and w.FocusedChild then return w.FocusedChild end
            return nil
        end,
    },
    Button = {
        RegisterInputs = {
            { Key = Keys.VK_RETURN, Action = function(w)
                return w:Click(w)
             end },
        {Key = Keys.VK_SPACE, Action = function(w)
            return w:Click(w)
                end},
            },
                Click = function(w)
                    if w.IsDisabled and w:IsDisabled() then return true end
                if w.OnClick then
                    w:OnClick()
                    end
                return true
                end
    },
    DropdownMenu = {
        Role = "DropdownMenu",
        RegisterInputs = {
            { Key = Keys.VK_RETURN, Action = function(w)
                if w.OnClick then w:OnClick() end
                return true
             end },
        },
    },
    Slider = {
        RegisterInputs = {
            { Key = Keys.VK_LEFT, MSG = KeyEvents.KeyDown, Action = function(w)
                if w.Decrement then w:Decrement() end
                w:SetValue(w.GetValue and w:GetValue() or "")
                return true
            end },
            { Key = Keys.VK_RIGHT, MSG = KeyEvents.KeyDown, Action = function(w)
                if w.Increment then w:Increment() end
                w:SetValue(w.GetValue and w:GetValue() or "")
                return true
            end },
            { Key = Keys.VK_PRIOR, MSG = KeyEvents.KeyDown, Action = function(w)
                for i = 1, 10 do
                    if w.Increment then w:Increment() end
                end
                w:SetValue(w.GetValue and w:GetValue() or "")
                return true
            end },
            { Key = Keys.VK_NEXT, MSG = KeyEvents.KeyDown, Action = function(w)
                for i = 1, 10 do
                    if w.Decrement then w:Decrement() end
                end
                w:SetValue(w.GetValue and w:GetValue() or "")
                return true
            end },
        },
    },
    Checkbox = {
        RegisterInputs = {
            { Key = Keys.VK_SPACE, Action = function(w)
                if w.Toggle then w:Toggle() end
                w:SetValue(w.GetValue and w:GetValue() or "")
                return true
            end },
        },
    },
    Edit = {
        Role = "Edit",
        -- EditBox state fields (set by W_EditBox or consumer):
        --   w.EditBuffer    : string    — current text being edited
        --   w.EditCursor    : integer   — 0-based position before which chars are inserted
        --   w.EditSelStart  : integer|nil — 0-based selection anchor (nil = no selection)
        --   w.EditActive    : boolean   — whether we are inside the edit box
        --   w.EditOriginal  : string    — text when editing started (for cancel)
        --   w.OnSetText     : function(w, text) — callback to sync text to the game control
        --   w.OnCommit      : function(w, text) — callback when Enter commits
        --   w.HighlightOnEdit : boolean — select all text on activation (default true)
        IsExpanded = false,
        HighlightOnEdit = true,
        RegisterInputs = {
            -- Enter: if not active, activate; if active, commit
            { Key = Keys.VK_RETURN, Action = function(w)
                if not w.EditActive then
                    EditBox_Activate(w)
                else
                    if not w.EditReadOnly then
                    EditBox_Commit(w)
                    end
                end
                return true
            end },
            -- Escape: cancel editing
            { Key = Keys.VK_ESCAPE, Action = function(w)
                if w.EditActive and not w.AlwaysEdit then
                    EditBox_Cancel(w)
                    return true
                end
                return false
            end },
            -- Backspace: delete char before cursor (or selection)
            { Key = Keys.VK_BACK, MSG = KeyEvents.KeyDown, Action = function(w)
                if w.EditReadOnly or not w.EditActive then return false end
                if w.EditSelStart then
                    local deleted = EditBox_DeleteSelection(w)
                    if deleted ~= "" then Speak(deleted, true) end
                else
                    EditBox_BackspaceChar(w)
                end
                EditBox_SyncAndSpeak(w)
                return true
            end },
            -- Ctrl+Backspace: delete word before cursor (or selection)
            { Key = Keys.VK_BACK, MSG = KeyEvents.KeyDown, IsControl = true, Action = function(w)
                if not w.EditActive or w.EditReadOnly then return false end
                if w.EditSelStart then
                    local deleted = EditBox_DeleteSelection(w)
                    if deleted ~= "" then Speak(deleted, true) end
                else
                    EditBox_BackspaceWord(w)
                end
                EditBox_SyncAndSpeak(w)
                return true
            end },
            -- Delete: delete char after cursor (or selection)
            { Key = Keys.VK_DELETE, MSG = KeyEvents.KeyDown, Action = function(w)
                if not w.EditActive or w.EditReadOnly then return false end
                if w.EditSelStart then
                    local deleted = EditBox_DeleteSelection(w)
                    if deleted ~= "" then Speak(deleted, true) end
                else
                    EditBox_DeleteChar(w)
                end
                EditBox_SyncAndSpeak(w)
                return true
            end },
            -- Ctrl+Delete: delete word after cursor (or selection)
            { Key = Keys.VK_DELETE, MSG = KeyEvents.KeyDown, IsControl = true, Action = function(w)
                if not w.EditActive or w.EditReadOnly then return false end
                if w.EditSelStart then
                    local deleted = EditBox_DeleteSelection(w)
                    if deleted ~= "" then Speak(deleted, true) end
                else
                    EditBox_DeleteWordForward(w)
                end
                EditBox_SyncAndSpeak(w)
                return true
            end },
            -- Left arrow: move cursor left
            { Key = Keys.VK_LEFT, MSG = KeyEvents.KeyDown, Action = function(w)
                if not w.EditActive then return false end
                EditBox_MoveCursor(w, -1, false, false)
                return true
            end },
            -- Shift+Left: extend selection left
            { Key = Keys.VK_LEFT, MSG = KeyEvents.KeyDown, IsShift = true, Action = function(w)
                if not w.EditActive then return false end
                EditBox_MoveCursor(w, -1, true, false)
                return true
            end },
            -- Ctrl+Left: move cursor word left
            { Key = Keys.VK_LEFT, MSG = KeyEvents.KeyDown, IsControl = true, Action = function(w)
                if not w.EditActive then return false end
                EditBox_MoveCursor(w, -1, false, true)
                return true
            end },
            -- Right arrow: move cursor right
            { Key = Keys.VK_RIGHT, MSG = KeyEvents.KeyDown, Action = function(w)
                if not w.EditActive then return false end
                EditBox_MoveCursor(w, 1, false, false)
                return true
            end },
            -- Shift+Right: extend selection right
            { Key = Keys.VK_RIGHT, MSG = KeyEvents.KeyDown, IsShift = true, Action = function(w)
                if not w.EditActive then return false end
                EditBox_MoveCursor(w, 1, true, false)
                return true
            end },
            -- Ctrl+Right: move cursor word right
            { Key = Keys.VK_RIGHT, MSG = KeyEvents.KeyDown, IsControl = true, Action = function(w)
                if not w.EditActive then return false end
                EditBox_MoveCursor(w, 1, false, true)
                return true
            end },
            -- Home: move to start of line
            { Key = Keys.VK_HOME, MSG = KeyEvents.KeyDown, Action = function(w)
                if not w.EditActive then return false end
                local buf = w.EditBuffer or ""
                local pos = w.EditCursor or 0
                EditBox_MoveToEdge(w, EditBox_LineStart(buf, pos), false)
                return true
            end },
            -- Shift+Home: select to start of line
            { Key = Keys.VK_HOME, MSG = KeyEvents.KeyDown, IsShift = true, Action = function(w)
                if not w.EditActive then return false end
                local buf = w.EditBuffer or ""
                local pos = w.EditCursor or 0
                EditBox_MoveToEdge(w, EditBox_LineStart(buf, pos), true)
                return true
            end },
            -- End: move to end of line
            { Key = Keys.VK_END, MSG = KeyEvents.KeyDown, Action = function(w)
                if not w.EditActive then return false end
                local buf = w.EditBuffer or ""
                local pos = w.EditCursor or 0
                EditBox_MoveToEdge(w, EditBox_LineEnd(buf, pos), false)
                return true
            end },
            -- Shift+End: select to end of line
            { Key = Keys.VK_END, MSG = KeyEvents.KeyDown, IsShift = true, Action = function(w)
                if not w.EditActive then return false end
                local buf = w.EditBuffer or ""
                local pos = w.EditCursor or 0
                EditBox_MoveToEdge(w, EditBox_LineEnd(buf, pos), true)
                return true
            end },
            -- Up: move to previous line, speak it; if on first line, speak current line
            { Key = Keys.VK_UP, MSG = KeyEvents.KeyDown, Action = function(w)
                if not w.EditActive then return false end
                local buf = w.EditBuffer or ""
                local pos = w.EditCursor or 0
                local newPos = EditBox_PrevLinePos(buf, pos)
                if not newPos then
                    SpeakLine(buf, pos)
                    return true
                end
                w.EditSelStart = nil
                w.EditCursor = newPos
                SpeakLine(buf, newPos)
                return true
            end },
            -- Down: move to next line, speak it; if on last line, speak current line
            { Key = Keys.VK_DOWN, MSG = KeyEvents.KeyDown, Action = function(w)
                if not w.EditActive then return false end
                local buf = w.EditBuffer or ""
                local pos = w.EditCursor or 0
                local newPos = EditBox_NextLinePos(buf, pos)
                if not newPos then
                    SpeakLine(buf, pos)
                    return true
                end
                w.EditSelStart = nil
                w.EditCursor = newPos
                SpeakLine(buf, newPos)
                return true
            end },
            -- Shift+Up: extend selection to previous line
            { Key = Keys.VK_UP, MSG = KeyEvents.KeyDown, IsShift = true, Action = function(w)
                if not w.EditActive then return false end
                local buf = w.EditBuffer or ""
                local oldSelStart = w.EditSelStart
                local oldCursor = w.EditCursor or 0
                local newPos = EditBox_PrevLinePos(buf, oldCursor)
                if not newPos then return true end
                if not w.EditSelStart then w.EditSelStart = oldCursor end
                w.EditCursor = newPos
                SpeakSelectionChange(w, oldSelStart, oldCursor)
                return true
            end },
            -- Shift+Down: extend selection to next line
            { Key = Keys.VK_DOWN, MSG = KeyEvents.KeyDown, IsShift = true, Action = function(w)
                if not w.EditActive then return false end
                local buf = w.EditBuffer or ""
                local oldSelStart = w.EditSelStart
                local oldCursor = w.EditCursor or 0
                local newPos = EditBox_NextLinePos(buf, oldCursor)
                if not newPos then return true end
                if not w.EditSelStart then w.EditSelStart = oldCursor end
                w.EditCursor = newPos
                SpeakSelectionChange(w, oldSelStart, oldCursor)
                return true
            end },
            -- Ctrl+Home: move to start, speak the line landed on
            { Key = Keys.VK_HOME, MSG = KeyEvents.KeyDown, IsControl = true, Action = function(w)
                if not w.EditActive then return false end
                w.EditCursor = 0
                w.EditSelStart = nil
                SpeakLine(w.EditBuffer or "", 0)
                return true
            end },
            -- Ctrl+End: move to end, speak the line landed on
            { Key = Keys.VK_END, MSG = KeyEvents.KeyDown, IsControl = true, Action = function(w)
                if not w.EditActive then return false end
                local buf = w.EditBuffer or ""
                w.EditCursor = #buf
                w.EditSelStart = nil
                SpeakLine(buf, #buf)
                return true
            end },
            -- Ctrl+Shift+Home: select to start
            { Key = Keys.VK_HOME, MSG = KeyEvents.KeyDown, IsControl = true, IsShift = true, Action = function(w)
                if not w.EditActive then return false end
                EditBox_MoveToEdge(w, 0, true)
                return true
            end },
            -- Ctrl+Shift+End: select to end
            { Key = Keys.VK_END, MSG = KeyEvents.KeyDown, IsControl = true, IsShift = true, Action = function(w)
                if not w.EditActive then return false end
                local len = w.EditBuffer and #w.EditBuffer or 0
                EditBox_MoveToEdge(w, len, true)
                return true
            end },
            -- Ctrl+C: copy to clipboard
            { Key = Keys.C, MSG = KeyEvents.KeyDown, IsControl = true, Action = function(w)
                if not w.EditActive then return false end
                local sel = EditBox_GetSelectedText(w)
                if sel ~= "" then
                    UIManager:SetClipboardString(sel)
                    Speak(Locale.Lookup("LOC_CAI_EDIT_COPIED", sel), true)
                else
                    local buf = w.EditBuffer or ""
                    local pos = w.EditCursor or 0
                    local ch = string.sub(buf, pos + 1, pos + 1)
                    if ch ~= "" then
                        UIManager:SetClipboardString(ch)
                        Speak(Locale.Lookup("LOC_CAI_EDIT_COPIED", ch), true)
                    end
                end
                return true
            end },
            -- Ctrl+V: paste from clipboard
            { Key = Keys.V, MSG = KeyEvents.KeyDown, IsControl = true, Action = function(w)
                if not w.EditActive or w.EditReadOnly then return false end
                local text = CAI.GetClipboardText()
                if text and text ~= "" then
                    EditBox_InsertText(w, text)
                    EditBox_SyncAndSpeak(w)
                    Speak(Locale.Lookup("LOC_CAI_EDIT_PASTED", text), true)
                end
                return true
            end },
            -- Ctrl+A: select all
            { Key = Keys.A, MSG = KeyEvents.KeyDown, IsControl = true, Action = function(w)
                if not w.EditActive then return false end
                EditBox_SelectAll(w)
                return true
            end },
            -- Ctrl+Shift+Left: extend selection word left
            { Key = Keys.VK_LEFT, MSG = KeyEvents.KeyDown, IsControl = true, IsShift = true, Action = function(w)
                if not w.EditActive then return false end
                EditBox_MoveCursor(w, -1, true, true)
                return true
            end },
            -- Ctrl+Shift+Right: extend selection word right
            { Key = Keys.VK_RIGHT, MSG = KeyEvents.KeyDown, IsControl = true, IsShift = true, Action = function(w)
                if not w.EditActive then return false end
                EditBox_MoveCursor(w, 1, true, true)
                return true
            end },
        },
        OnCharInput = function(w, char)
            if not w.EditActive or w.EditReadOnly then return false end
            EditBox_InsertText(w, char)
            EditBox_SyncAndSpeak(w)
            Speak(char, true)
            return true
        end,
        GetDefaultChild = nil,
        OnFocusEnter = function(w) if w.AlwaysEdit and not w.EditActive then EditBox_Activate(w) end end
    },
    Dialog = {
        Role = "Dialog",
        DefaultIndex = 1,
        WrapAround = true,
        RegisterInputs = {
            { Key = Keys.VK_TAB, MSG = KeyEvents.KeyDown, Action = function(w) return w:Navigate(1) end },
            { Key = Keys.VK_TAB, MSG = KeyEvents.KeyDown, IsShift = true, Action = function(w) return w:Navigate(-1) end },
        },
        Navigate = NavigateSimpleList,
        GetDefaultChild = GetContainerDefChild
    },
    Tab = {
        Role = "Tab",
        RegisterInputs = {
            { Key = Keys.VK_RETURN, Action = function(w)
                if w.OnClick then w:OnClick() end
                return true
             end },
        },
    },
    TabBar = {
        Role = "TabBar",
        DefaultIndex = 1,
        WrapAround = true,
        IsExpanded = true,
        RegisterInputs = {
            { Key = Keys.VK_LEFT, MSG = KeyEvents.KeyDown, Action = function(w) return w:Navigate(-1) end },
            { Key = Keys.VK_RIGHT, MSG = KeyEvents.KeyDown, Action = function(w) return w:Navigate(1) end },
            { Key = Keys.VK_HOME, MSG = KeyEvents.KeyDown, Action = function(w) return NavigateToFirst(w) end },
            { Key = Keys.VK_END, MSG = KeyEvents.KeyDown, Action = function(w) return NavigateToLast(w) end },
        },
        Navigate = NavigateSimpleList,
        GetDefaultChild = GetContainerDefChild
    },
    MenuItem = {
        Role = "MenuItem",
        SpeechSettings = { Role = false },
        RegisterInputs = {
            { Key = Keys.VK_RETURN, Action = function(w)
                if w.OnClick then w:OnClick() end
                return true
             end },
        },
    },
    StaticText = {
        Role = "StaticText",
        SpeechSettings = { Role = false },
        RegisterInputs = {
            {Key = Keys.VK_RETURN, Action = function(w)
                if w.Children and #w.Children > 0 and not w.FocusedChild then
                    local edit = w.Children[1]
                    if w.GetValue then
                        edit.GetValue = w.GetValue
                    end
                w.Manager:SetFocus(w.Children[1])
                return true
                end
                return false
                end},
                {Key = Keys.VK_ESCAPE, Action = function(w)
                 if w.FocusedChild then
                        w.Manager:SetFocus(w)
                        w.FocusedChild = nil
                        return true
                    end
                    return false
                end}
        },
        OnCreate = function(w)
            local edit = w.Manager:CreateUIWidget("Edit")
            edit.AlwaysEdit = true
            edit.EditReadOnly = true
            edit.HighlightOnEdit = false
            w:AddChild(edit)
        end,
        OnFocusLeave = function(w) if w.FocusedChild then w.FocusedChild = nil end end
    },
    GameView = {
        GetLabel = function() return Locale.Lookup("LOC_CAI_ROLE_GAME_VIEW") end,
        GetDefaultChild = GetContainerDefChild,
        RegisterInputs = {
            { Key = Keys.VK_UP, MSG = KeyEvents.KeyDown, Action = function(w)
                local cursor = ExposedMembers.CAICursor
                cursor:SetCoords(cursor.curX, cursor.curY+1)
                return true
            end },
            { Key = Keys.VK_DOWN, MSG = KeyEvents.KeyDown, Action = function(w)
                local cursor = ExposedMembers.CAICursor
                cursor:SetCoords(cursor.curX, cursor.curY-1)
                return true
            end },
            { Key = Keys.VK_RIGHT, MSG = KeyEvents.KeyDown, Action = function(w)
                local cursor = ExposedMembers.CAICursor
                cursor:SetCoords(cursor.curX+1, cursor.curY)
                return true
            end },
            { Key = Keys.VK_LEFT, MSG = KeyEvents.KeyDown, Action = function(w)
                local cursor = ExposedMembers.CAICursor
                cursor:SetCoords(cursor.curX-1, cursor.curY)
                return true
            end },
            { Key = Keys.VK_NUMPAD1, MSG = KeyEvents.KeyDown, Action = function(w)
                local cursor = ExposedMembers.CAICursor
                cursor:MoveToNextPlot(DirectionTypes.DIRECTION_SOUTHWEST)
                return true
            end },
            { Key = Keys.VK_NUMPAD3, MSG = KeyEvents.KeyDown, Action = function(w)
                local cursor = ExposedMembers.CAICursor
                cursor:MoveToNextPlot(DirectionTypes.DIRECTION_SOUTHEAST)
                return true
            end },
            { Key = Keys.VK_NUMPAD4, MSG = KeyEvents.KeyDown, Action = function(w)
                local cursor = ExposedMembers.CAICursor
                cursor:MoveToNextPlot(DirectionTypes.DIRECTION_WEST)
                return true
            end },
            { Key = Keys.VK_NUMPAD6, MSG = KeyEvents.KeyDown, Action = function(w)
                local cursor = ExposedMembers.CAICursor
                cursor:MoveToNextPlot(DirectionTypes.DIRECTION_EAST)
                return true
            end },
            { Key = Keys.VK_NUMPAD7, MSG = KeyEvents.KeyDown, Action = function(w)
                local cursor = ExposedMembers.CAICursor
                cursor:MoveToNextPlot(DirectionTypes.DIRECTION_NORTHWEST)
                return true
            end },
            { Key = Keys.VK_NUMPAD9, MSG = KeyEvents.KeyDown, Action = function(w)
                local cursor = ExposedMembers.CAICursor
                cursor:MoveToNextPlot(DirectionTypes.DIRECTION_NORTHEAST)
                return true
            end },
        },
    },
    InterfaceMode = {
        AnnounceRole = false,
    },
}
