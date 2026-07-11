-- CAIWidgetHelpers_EditBox.lua
-- Stateless edit utilities operating on EditBoxWidget internal fields:
--   _buffer, _cursor, _selStart, _active, _original, _passwordMask
-- Cursor positions are 0-based "before this index" offsets, matching the old
-- widgetTemplateHelpers EditBox model.

CAIWidgetHelpers_EditBox = {}
local E = CAIWidgetHelpers_EditBox

-- Above this length, selection/deselection speech collapses to a count so the
-- screen reader doesn't lag piping thousands of chars through TTS.
local SELECTION_SPEAK_LIMIT = 500

local function IsWordBoundary(ch) return ch == " " or ch == "\n" or ch == "\t" end

local function MaskIfNeeded(w, text)
    if not w._passwordMask or not text or text == "" then return text end
    return string.rep("*", #text)
end

---Format a "selected" announcement, swapping in a character-count message when
---the selection is too large to speak verbatim.
---@param w EditBoxWidget
---@param text string
---@return string
function E.FormatSelected(w, text)
    if #text > SELECTION_SPEAK_LIMIT then
        return Locale.Lookup("LOC_CAI_EDIT_SELECTED_COUNT", #text)
    end
    return Locale.Lookup("LOC_CAI_EDIT_SELECTED", MaskIfNeeded(w, text))
end

---@param w EditBoxWidget
---@param text string
---@return string
function E.FormatUnselected(w, text)
    if #text > SELECTION_SPEAK_LIMIT then
        return Locale.Lookup("LOC_CAI_EDIT_UNSELECTED_COUNT", #text)
    end
    return Locale.Lookup("LOC_CAI_EDIT_UNSELECTED", MaskIfNeeded(w, text))
end

---@param w EditBoxWidget
---@param text string
---@return string
function E.FormatCopied(w, text)
    if #text > SELECTION_SPEAK_LIMIT then
        return Locale.Lookup("LOC_CAI_EDIT_COPIED_COUNT", #text)
    end
    return Locale.Lookup("LOC_CAI_EDIT_COPIED", MaskIfNeeded(w, text))
end

---@param w EditBoxWidget
---@param text string
---@return string
function E.FormatPasted(w, text)
    if #text > SELECTION_SPEAK_LIMIT then
        return Locale.Lookup("LOC_CAI_EDIT_PASTED_COUNT", #text)
    end
    return Locale.Lookup("LOC_CAI_EDIT_PASTED", MaskIfNeeded(w, text))
end

--#region Selection

---@param w EditBoxWidget
---@return integer|nil, integer|nil
function E.GetSelectionRange(w)
    if not w._selStart then return nil, nil end
    local a, b = w._selStart, w._cursor
    if a > b then a, b = b, a end
    return a, b
end

---@param w EditBoxWidget
---@return string
function E.GetSelectedText(w)
    local a, b = E.GetSelectionRange(w)
    if not a then return "" end
    return string.sub(w._buffer, a + 1, b)
end

---@param w EditBoxWidget
---@return string deleted
function E.DeleteSelection(w)
    local a, b = E.GetSelectionRange(w)
    if not a then return "" end
    local deleted = string.sub(w._buffer, a + 1, b)
    w._buffer = string.sub(w._buffer, 1, a) .. string.sub(w._buffer, b + 1)
    w._cursor = a
    w._selStart = nil
    return deleted
end

---@param w EditBoxWidget
function E.SelectAll(w)
    local buf = w._buffer or ""
    if #buf == 0 then
        Speak(Locale.Lookup("LOC_CAI_EDIT_BLANK"), true)
        return
    end
    w._selStart = 0
    w._cursor = #buf
    Speak(E.FormatSelected(w, buf), true)
end

--#endregion

--#region Word/line boundaries

---@param buf string
---@param pos integer
---@return integer
function E.FindWordLeft(buf, pos)
    if pos <= 0 then return 0 end
    local i = pos
    while i > 0 and string.sub(buf, i, i) == " " do i = i - 1 end
    if i > 0 and string.sub(buf, i, i) == "\n" then return i end
    while i > 0 and not IsWordBoundary(string.sub(buf, i, i)) do i = i - 1 end
    return i
end

---@param buf string
---@param pos integer
---@return integer
function E.FindDeleteLeft(buf, pos)
    if pos <= 0 then return 0 end
    local i = pos
    local skippedSpace = false
    while i > 0 and string.sub(buf, i, i) == " " do i = i - 1; skippedSpace = true end
    if i > 0 and string.sub(buf, i, i) == "\n" then return i - 1 end
    while i > 0 and not IsWordBoundary(string.sub(buf, i, i)) do i = i - 1 end
    if not skippedSpace then
        while i > 0 and string.sub(buf, i, i) == " " do i = i - 1 end
    end
    return i
end

---@param buf string
---@param pos integer
---@return integer
function E.FindWordRight(buf, pos)
    local len = #buf
    if pos >= len then return len end
    local i = pos + 1
    if string.sub(buf, i, i) == "\n" then return pos + 1 end
    while i <= len and not IsWordBoundary(string.sub(buf, i, i)) do i = i + 1 end
    while i <= len and string.sub(buf, i, i) == " " do i = i + 1 end
    return i - 1
end

---@param buf string
---@param pos integer
---@return string
function E.GetWordAt(buf, pos)
    local len = #buf
    if pos >= len then return "" end
    local i = pos + 1
    while i <= len and IsWordBoundary(string.sub(buf, i, i)) do i = i + 1 end
    local startIdx = i
    while i <= len and not IsWordBoundary(string.sub(buf, i, i)) do i = i + 1 end
    return string.sub(buf, startIdx, i - 1)
end

---@param buf string
---@param pos integer
---@return integer
function E.LineStart(buf, pos)
    if pos <= 0 then return 0 end
    local i = pos
    while i > 0 and string.sub(buf, i, i) ~= "\n" do i = i - 1 end
    return i > 0 and i or 0
end

---@param buf string
---@param pos integer
---@return integer
function E.LineEnd(buf, pos)
    local len = #buf
    local i = pos + 1
    while i <= len and string.sub(buf, i, i) ~= "\n" do i = i + 1 end
    return i - 1
end

---@param buf string
---@param pos integer
---@return string
function E.GetCurrentLine(buf, pos)
    local ls, le = E.LineStart(buf, pos), E.LineEnd(buf, pos)
    return string.sub(buf, ls + 1, le)
end

---Text-form of the line at `pos`, with mask + blank-fallback applied. Useful
---when the caller wants to compose it with another spoken line (e.g. a queued
---deselection notice via SpeakWithDeselect).
---@param w EditBoxWidget
---@param pos integer
---@return string
function E.GetLineText(w, pos)
    local buf = w._buffer or ""
    local line = MaskIfNeeded(w, E.GetCurrentLine(buf, pos))
    return (#line > 0) and line or Locale.Lookup("LOC_CAI_EDIT_BLANK")
end

---@param w EditBoxWidget
---@param pos integer
function E.SpeakLine(w, pos)
    Speak(E.GetLineText(w, pos), true)
end

---Speak `primary` interrupting, then queue an "unselected" notice when the
---given previous selection was non-empty. Use after a non-shift cursor move
---that wiped a selection (line moves, Ctrl+Home/End) so the cursor target is
---heard first and the housekeeping line follows.
---@param w EditBoxWidget
---@param primary string
---@param prevSelStart integer|nil
---@param prevCursor integer
function E.SpeakWithDeselect(w, primary, prevSelStart, prevCursor)
    if not prevSelStart then
        Speak(primary, true)
        return
    end
    local a, b = prevSelStart, prevCursor
    if a > b then a, b = b, a end
    local deselected = string.sub(w._buffer or "", a + 1, b)
    if deselected == "" then
        Speak(primary, true)
        return
    end
    SpeakLines({ primary, E.FormatUnselected(w, deselected) }, true)
end

---@param buf string
---@param pos integer
---@return integer|nil
function E.PrevLinePos(buf, pos)
    local ls = E.LineStart(buf, pos)
    if ls <= 0 then return nil end
    local col = pos - ls
    local prevLineEnd = ls - 1
    if prevLineEnd > 0 and string.sub(buf, prevLineEnd, prevLineEnd) == "\n" then
        return prevLineEnd
    end
    local prevLineStart = E.LineStart(buf, prevLineEnd - 1)
    local prevLineLen = prevLineEnd - prevLineStart
    return prevLineStart + math.min(col, prevLineLen)
end

---@param buf string
---@param pos integer
---@return integer|nil
function E.NextLinePos(buf, pos)
    local le = E.LineEnd(buf, pos)
    local len = #buf
    if le >= len then return nil end
    local nextLineStart = le + 1
    local nextLineEnd = E.LineEnd(buf, nextLineStart)
    local col = pos - E.LineStart(buf, pos)
    local nextLineLen = nextLineEnd - nextLineStart
    return nextLineStart + math.min(col, nextLineLen)
end

--#endregion

--#region Mutation

---Insert text at the cursor (replacing any selection). Honors _maxChars and
---the per-keystroke _validator: if the validator rejects the proposed full
---buffer, the widget state is left untouched. Returns true on success.
---@param w EditBoxWidget
---@param text string
---@return boolean inserted
function E.InsertText(w, text)
    text = string.gsub(text, "\r\n", "\n")
    -- Snapshot state so a validator rejection rolls back the selection delete.
    local origBuffer = w._buffer or ""
    local origCursor = w._cursor or 0
    local origSelStart = w._selStart
    if w._selStart then E.DeleteSelection(w) end
    local buf = w._buffer or ""
    local pos = w._cursor or 0
    if w._maxChars and (#buf + #text) > w._maxChars then
        local room = w._maxChars - #buf
        if room <= 0 then
            w._buffer, w._cursor, w._selStart = origBuffer, origCursor, origSelStart
            LogMessage("EditBox helper InsertText blocked by max character limit on widget " .. tostring(w.Id or "?"))
            return false
        end
        text = string.sub(text, 1, room)
    end
    local proposed = string.sub(buf, 1, pos) .. text .. string.sub(buf, pos + 1)
    if w._validator and not w._validator(proposed) then
        w._buffer, w._cursor, w._selStart = origBuffer, origCursor, origSelStart
        LogMessage("EditBox helper InsertText rejected by validator on widget " .. tostring(w.Id or "?"))
        return false
    end
    w._buffer = proposed
    w._cursor = pos + #text
    return true
end

---@param w EditBoxWidget
function E.BackspaceChar(w)
    local pos = w._cursor or 0
    if pos <= 0 then return end
    local buf = w._buffer or ""
    local deleted = string.sub(buf, pos, pos)
    w._buffer = string.sub(buf, 1, pos - 1) .. string.sub(buf, pos + 1)
    w._cursor = pos - 1
    Speak(MaskIfNeeded(w, deleted), true)
end

---@param w EditBoxWidget
function E.DeleteChar(w)
    local pos = w._cursor or 0
    local buf = w._buffer or ""
    if pos >= #buf then return end
    local deleted = string.sub(buf, pos + 1, pos + 1)
    w._buffer = string.sub(buf, 1, pos) .. string.sub(buf, pos + 2)
    Speak(MaskIfNeeded(w, deleted), true)
end

---@param w EditBoxWidget
function E.BackspaceWord(w)
    local pos = w._cursor or 0
    if pos <= 0 then return end
    local buf = w._buffer or ""
    local deleteStart = E.FindDeleteLeft(buf, pos)
    local deleted = string.sub(buf, deleteStart + 1, pos)
    w._buffer = string.sub(buf, 1, deleteStart) .. string.sub(buf, pos + 1)
    w._cursor = deleteStart
    Speak(MaskIfNeeded(w, deleted), true)
end

---@param w EditBoxWidget
function E.DeleteWordForward(w)
    local pos = w._cursor or 0
    local buf = w._buffer or ""
    if pos >= #buf then return end
    local wordEnd = E.FindWordRight(buf, pos)
    local deleted = string.sub(buf, pos + 1, wordEnd)
    w._buffer = string.sub(buf, 1, pos) .. string.sub(buf, wordEnd + 1)
    Speak(MaskIfNeeded(w, deleted), true)
end

--#endregion

--#region Selection-change announcements

---@param w EditBoxWidget
---@param oldSelStart integer|nil
---@param oldCursor integer
function E.SpeakSelectionChange(w, oldSelStart, oldCursor)
    local buf = w._buffer or ""
    local oldA, oldB
    if oldSelStart then
        oldA, oldB = oldSelStart, oldCursor
        if oldA > oldB then oldA, oldB = oldB, oldA end
    end
    local newA, newB = E.GetSelectionRange(w)

    -- Selection cleared (e.g. Home/End without Shift over a prior selection).
    -- Speak the landing char first, then queue the unselected notice so the
    -- user hears where the cursor went before the housekeeping line.
    if oldA and not newA then
        local ch = string.sub(buf, w._cursor + 1, w._cursor + 1)
        if ch == "" or ch == "\n" then ch = Locale.Lookup("LOC_CAI_EDIT_BLANK") end
        local primary = MaskIfNeeded(w, ch)
        local deselected = string.sub(buf, oldA + 1, oldB)
        if deselected ~= "" then
            SpeakLines({ primary, E.FormatUnselected(w, deselected) }, true)
        else
            Speak(primary, true)
        end
        return
    end
    if not newA then
        local ch = string.sub(buf, w._cursor + 1, w._cursor + 1)
        if ch == "" then ch = Locale.Lookup("LOC_CAI_EDIT_BLANK") end
        Speak(MaskIfNeeded(w, ch), true)
        return
    end
    if not oldA then
        local sel = string.sub(buf, newA + 1, newB)
        if sel ~= "" then
            Speak(E.FormatSelected(w, sel), true)
        end
        return
    end
    if oldCursor == w._cursor then return end

    local anchor = w._selStart
    local oldDist = math.abs(oldCursor - anchor)
    local newDist = math.abs(w._cursor - anchor)
    local lo = math.min(oldCursor, w._cursor)
    local hi = math.max(oldCursor, w._cursor)
    local span = string.sub(buf, lo + 1, hi)
    if span == "" then return end
    if newDist > oldDist then
        Speak(E.FormatSelected(w, span), true)
    else
        Speak(E.FormatUnselected(w, span), true)
    end
end

---@param w EditBoxWidget
---@param direction 1|-1
---@param shift boolean
---@param ctrl boolean
function E.MoveCursor(w, direction, shift, ctrl)
    local buf = w._buffer or ""
    local pos = w._cursor or 0
    local oldSelStart = w._selStart
    local oldCursor = pos

    if w._selStart and not shift then
        local a, b = E.GetSelectionRange(w)
        local deselected = E.GetSelectedText(w)
        w._cursor = (direction < 0) and a or b
        w._selStart = nil
        -- Speak landing char/word first; queue the unselected notice after so
        -- the user hears the cursor target before the housekeeping line.
        local newPos = w._cursor
        local primary
        if ctrl then
            local word = E.GetWordAt(buf, newPos)
            primary = (word == "") and Locale.Lookup("LOC_CAI_EDIT_BLANK") or MaskIfNeeded(w, word)
        else
            local ch = string.sub(buf, newPos + 1, newPos + 1)
            if ch == "" or ch == "\n" then ch = Locale.Lookup("LOC_CAI_EDIT_BLANK") end
            primary = MaskIfNeeded(w, ch)
        end
        if deselected ~= "" then
            SpeakLines({ primary, E.FormatUnselected(w, deselected) }, true)
        else
            Speak(primary, true)
        end
        return
    end

    if shift and not w._selStart then w._selStart = pos end

    local newPos
    if ctrl then
        newPos = direction < 0 and E.FindWordLeft(buf, pos) or E.FindWordRight(buf, pos)
    else
        newPos = pos + direction
    end
    if newPos < 0 then newPos = 0 end
    if newPos > #buf then newPos = #buf end
    w._cursor = newPos
    if not shift then w._selStart = nil end

    if shift then
        E.SpeakSelectionChange(w, oldSelStart, oldCursor)
    elseif ctrl then
        local word = E.GetWordAt(buf, newPos)
        if word == "" then word = Locale.Lookup("LOC_CAI_EDIT_BLANK") end
        Speak(MaskIfNeeded(w, word), true)
    else
        local ch = string.sub(buf, newPos + 1, newPos + 1)
        if ch == "" or ch == "\n" then ch = Locale.Lookup("LOC_CAI_EDIT_BLANK") end
        Speak(MaskIfNeeded(w, ch), true)
    end
end

---@param w EditBoxWidget
---@param targetPos integer
---@param shift boolean
function E.MoveToEdge(w, targetPos, shift)
    local pos = w._cursor or 0
    local oldSelStart = w._selStart
    local oldCursor = pos
    if shift and not w._selStart then w._selStart = pos end
    w._cursor = targetPos
    if not shift then w._selStart = nil end
    E.SpeakSelectionChange(w, oldSelStart, oldCursor)
end

--#endregion
