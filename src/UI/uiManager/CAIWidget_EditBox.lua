-- CAIWidget_EditBox.lua
-- ValueWidget for editable text. Value is the committed text; _buffer is the
-- in-progress edit. BeginEdit copies value -> buffer; Commit promotes buffer
-- -> value and fires value_changed; Cancel discards the buffer.
--
-- Set AlwaysEdit=true to enter edit mode on focus and never exit; pair with
-- ReadOnly for navigable read-only viewers (used by StaticText-style hosts).

EditModes = {
    Normal = 0,
    LettersOnly = 1,
    NumbersOnly = 2,
    AlphanumericOnly = 3,
}

---@class EditBoxWidget : ValueWidget
---@field _buffer string
---@field _cursor integer
---@field _selStart? integer
---@field _active boolean
---@field _original string
---@field _readOnly boolean
---@field _alwaysEdit boolean
---@field _highlightOnEdit boolean
---@field _editMode integer
---@field _maxChars? integer
---@field _validator? fun(text:string):boolean
---@field _commitValidator? fun(text:string):string|nil
---@field _enterToCommit boolean
---@field _passwordMask boolean
---@field _commitOnFocusLeave boolean
EditBoxWidget = setmetatable({}, { __index = ValueWidget })
EditBoxWidget.__index = EditBoxWidget

local E = CAIWidgetHelpers_EditBox

local function NormalizeText(text)
    text = text or ""
    text = string.gsub(text, "%[NEWLINE%]", "\n")
    text = string.gsub(text, "\r\n", "\n")
    return text
end

---@param mode integer
---@param ch string
---@return boolean
local function CharAllowed(mode, ch)
    if mode == EditModes.NumbersOnly then return ch:match("[0-9]") ~= nil end
    if mode == EditModes.LettersOnly then return ch:match("[%a]") ~= nil end
    if mode == EditModes.AlphanumericOnly then return ch:match("[%w]") ~= nil end
    return true
end

local function ApplyEditStartPosition(w, text, selectAll)
    if selectAll and not w._readOnly and #text > 0 then
        w._selStart = 0
        w._cursor = #text
    else
        w._cursor = w._readOnly and 0 or #text
        w._selStart = nil
    end
end

---@param mgr UIScreenManager
---@param id string
---@param props? table
---@return EditBoxWidget
function EditBoxWidget.Create(mgr, id, props)
    local w = ValueWidget.New(EditBoxWidget)
    w.Id = id
    w.Type = "EditBox"
    w.Role = "Edit"
    w.Manager = mgr
    w._value = ""
    w._buffer = ""
    w._cursor = 0
    w._selStart = nil
    w._active = false
    w._original = ""
    w._readOnly = false
    w._alwaysEdit = false
    w._highlightOnEdit = true
    w._editMode = EditModes.Normal
    w._enterToCommit = true
    w._passwordMask = false
    w._commitOnBufferChanged = false
    w._commitOnFocusLeave = true

    -- Focus speech reads only what the cursor is on: the current selection if
    -- any, otherwise the line at the cursor. Reading the entire buffer on focus
    -- entry is noisy for multi-line and useless for re-focus mid-edit.
    w:SetValueGetter(function(self)
        local buf = (self._active and self._buffer) or self._value or ""
        if buf == "" then return "" end
        local cursor = self._cursor or 0
        local out
        if self._selStart then
            local a, b = self._selStart, cursor
            if a > b then a, b = b, a end
            out = string.sub(buf, a + 1, b)
        else
            out = E.GetCurrentLine(buf, cursor)
        end
        if self._passwordMask then return string.rep("*", #out) end
        return out
    end)

    w:AddInputBindings(EditBoxWidget._BuildBindings())

    -- Fallback: ensure AlwaysEdit boxes are in edit mode by the time focus lands,
    -- even if SetAlwaysEdit ran before widget setup. Focus entry should not
    -- reposition the cursor; the only focus-driven state change is explicit
    -- writable select-all when HighlightOnEdit is enabled.
    w:On("focus_enter", function(self)
        if self._alwaysEdit and not self._active then self:BeginEdit(true) end
        local text = self._buffer or ""
        if self._alwaysEdit and self._highlightOnEdit and not self._readOnly and #text > 0 then
            self._selStart = 0
            self._cursor = #text
        end
    end)

    -- Leaving focus mid-edit on a non-AlwaysEdit box would silently strand the
    -- buffer (and lose the cancel-restore point on the next refresh). Auto-
    -- cancel so the committed value stays intact and the user hears it.
    -- AlwaysEdit + writable boxes auto-commit on focus loss (matches vanilla
    -- edit-mode behavior where the field value is always live).
    w:On("focus_leave", function(self)
        if self._active and not self._alwaysEdit then
            self:Cancel()
        elseif self._alwaysEdit and not self._readOnly and self._commitOnFocusLeave then
            self:Commit()
        end
    end)

    CAIWidgetRegistry.ApplyProps(w, props)
    return w
end

--#region Public API

---Set the committed value (and the buffer when not actively editing).
---Normalizes [NEWLINE]/\r\n and resolves icon tokens for display.
---@param text string
---@param silent? boolean
function EditBoxWidget:SetText(text, silent)
    local normalized = ProcessIcons(NormalizeText(text))
    self._buffer = normalized
    -- Read-only viewers anchor at the top so refreshes don't drop the cursor on
    -- the last line of newly loaded content.
    self._cursor = self._readOnly and 0 or #normalized
    self._selStart = nil
    if self._active then self._original = normalized end
    ValueWidget.SetValue(self, normalized, silent)
    self:_FireTextChanged()
end

---@return string
function EditBoxWidget:GetText() return self._value or "" end

---Prepend the interaction hint appropriate to the live edit state while
---preserving any screen-specific tooltip supplied by the caller.
---@return string
function EditBoxWidget:GetTooltip()
    local tooltip = UIWidget.GetTooltip(self) or ""
    if self._readOnly then return tooltip end

    local hint = ""
    if self._alwaysEdit then
        hint = Locale.Lookup("LOC_CAI_EDIT_HINT_TYPE_TEXT")
    elseif not self._active then
        hint = Locale.Lookup("LOC_CAI_EDIT_HINT_PRESS_ENTER")
    end

    if hint == "" then return tooltip end
    if tooltip == "" then return hint end
    return hint .. " " .. tooltip
end

function EditBoxWidget:SetReadOnly(b)
    self._readOnly = b and true or false
    self.Role = self._readOnly and "EditReadOnly" or "Edit"
    -- Highlight-on-edit (select-all on BeginEdit) is meaningless for a viewer
    -- and would just dump the whole buffer to TTS. Force it off here so prop
    -- order in ApplyProps doesn't matter.
    if self._readOnly then
        self._highlightOnEdit = false
        self._selStart = nil
        if self._active then self._cursor = 0 end
    end
end

---When enabled, auto-enter edit mode immediately (silent — focus speech still
---runs normally when the widget gains focus). Focus_enter is the fallback path.
function EditBoxWidget:SetAlwaysEdit(b)
    self._alwaysEdit = b and true or false
    if self._alwaysEdit and not self._active then self:BeginEdit(true) end
end

function EditBoxWidget:SetHighlightOnEdit(b)
    self._highlightOnEdit = b and true or false
    if not self._highlightOnEdit then self._selStart = nil end
end

function EditBoxWidget:SetMaxCharacters(n) self._maxChars = n end

---Per-keystroke / paste guard. Receives the proposed full buffer; return false
---to reject the insertion. Runs silently — the input is just dropped.
function EditBoxWidget:SetValidator(fn) self._validator = fn end

---Commit-time guard. Receives the committed text; return nil to allow commit
---or a string to block it (the string is spoken to the user as an error).
function EditBoxWidget:SetCommitValidator(fn) self._commitValidator = fn end

function EditBoxWidget:SetEnterToCommit(b) self._enterToCommit = b and true or false end

function EditBoxWidget:SetPasswordMask(b) self._passwordMask = b and true or false end

function EditBoxWidget:SetCommitOnBufferChanged(b) self._commitOnBufferChanged = b and true or false end

function EditBoxWidget:SetCommitOnFocusLeave(b) self._commitOnFocusLeave = b and true or false end

function EditBoxWidget:SetEditMode(mode) self._editMode = mode or EditModes.Normal end

---Enter edit mode. By default speaks "Editing {label}: {selection or current
---line}". Pass silent=true to flip state without speech — used for focus_enter
---and SetAlwaysEdit so the normal focus announcement isn't doubled up.
---@param silent? boolean
function EditBoxWidget:BeginEdit(silent)
    local text = self._value or ""
    self._buffer = text
    self._active = true
    self._original = text
    ApplyEditStartPosition(self, text, not silent and self._highlightOnEdit)
    if silent then return end

    local label = self:GetLabel()
    local buf = self._buffer
    local spoken
    if self._selStart then
        local a, b = self._selStart, self._cursor
        if a > b then a, b = b, a end
        local raw = string.sub(buf, a + 1, b)
        if #raw > 500 then
            Speak(Locale.Lookup("LOC_CAI_EDIT_ACTIVATE_SELECTED_COUNT", label, #raw), true, false)
        else
            spoken = self._passwordMask and string.rep("*", #raw) or raw
            if spoken == "" then spoken = Locale.Lookup("LOC_CAI_EDIT_BLANK") end
            Speak(Locale.Lookup("LOC_CAI_EDIT_ACTIVATE_SELECTED", label, spoken), true, false)
        end
    else
        spoken = E.GetCurrentLine(buf, self._cursor)
        if self._passwordMask then spoken = string.rep("*", #spoken) end
        if spoken == "" then spoken = Locale.Lookup("LOC_CAI_EDIT_BLANK") end
        Speak(Locale.Lookup("LOC_CAI_EDIT_ACTIVATE", label, spoken), true, false)
    end
end

function EditBoxWidget:Commit()
    local text = self._buffer or ""
    if self._commitValidator then
        local err = self._commitValidator(text)
        if err then
            Speak(err, true, false)
            return
        end
    end
    if not self._alwaysEdit then self._active = false end
    self._selStart = nil
    self._value = text
    if self._valueSetter then self._valueSetter(self, text) end
    self:Emit("value_changed", text)
    -- AlwaysEdit boxes commit on every Enter as part of normal use; speaking
    -- "committed" every time becomes noise. Listeners can announce their own
    -- confirmation if they need one.
    if not self._alwaysEdit then
        Speak(Locale.Lookup("LOC_CAI_EDIT_COMMITTED", self._passwordMask and string.rep("*", #text) or text), false,
            false)
    end
end

function EditBoxWidget:Cancel()
    local changed = (self._buffer or "") ~= (self._original or "")
    self._active = false
    self._selStart = nil
    self._buffer = self._original or ""
    self._cursor = #self._buffer
    Speak(Locale.Lookup("LOC_CAI_EDIT_CANCELLED"), false, false)
    if changed then self:_FireTextChanged() end
end

--#endregion

--#region Char input + bindings

function EditBoxWidget:_FireTextChanged()
    if self._commitOnBufferChanged then
        self._value = self._buffer or ""
    end
    self:Emit("text_changed", self._buffer or "")
end

---@param char string
---@return boolean
function EditBoxWidget:OnCharInput(char, silent)
    if not self._active then return false end
    if self._readOnly then return true end
    if not CharAllowed(self._editMode, char) then return true end
    if not E.InsertText(self, char) then return true end
    if not silent then
        Speak(self._passwordMask and "*" or char, true, false)
    end
    self:_FireTextChanged()
    return true
end

function EditBoxWidget._BuildBindings()
    local kd = KeyEvents.KeyDown
    local function active(self) return self._active end
    return {
        {
            Key = Keys.VK_RETURN,
            Description = "LOC_CAI_KB_EDIT_ENTER",
            Action = function(self)
                if not self._active then
                    self:BeginEdit()
                    return true
                end
                if self._readOnly or not self._enterToCommit then
                    return false
                end
                self:Commit()
                return true
            end,
        },
        {
            Key = Keys.VK_ESCAPE,
            Description = "LOC_CAI_KB_EDIT_CANCEL",
            Action = function(self)
                if self._active and not self._alwaysEdit then
                    self:Cancel(); return true
                end
                return nil
            end,
        },
        -- Char deletion
        {
            Key = Keys.VK_BACK,
            MSG = kd,
            Description = "LOC_CAI_KB_DELETE_BACK",
            Action = function(self)
                if not active(self) or self._readOnly then return false end
                local d
                if self._selStart then
                    d = E.DeleteSelection(self)
                else
                    d = E.BackspaceChar(self)
                end
                if d ~= "" then
                    Speak(self._passwordMask and string.rep("*", #d) or d, true, false)
                    self:_FireTextChanged()
                end
                return true
            end,
        },
        {
            Key = Keys.VK_BACK,
            MSG = kd,
            IsControl = true,
            Description = "LOC_CAI_KB_DELETE_WORD_BACK",
            Action = function(self)
                if not active(self) or self._readOnly then return false end
                local d
                if self._selStart then
                    d = E.DeleteSelection(self)
                else
                    d = E.BackspaceWord(self)
                end
                if d ~= "" then
                    Speak(self._passwordMask and string.rep("*", #d) or d, true, false)
                    self:_FireTextChanged()
                end
                return true
            end,
        },
        {
            Key = Keys.VK_DELETE,
            MSG = kd,
            Description = "LOC_CAI_KB_DELETE_FORWARD",
            Action = function(self)
                if not active(self) or self._readOnly then return false end
                local d
                if self._selStart then
                    d = E.DeleteSelection(self)
                else
                    d = E.DeleteChar(self)
                end
                if d ~= "" then
                    Speak(self._passwordMask and string.rep("*", #d) or d, true, false)
                    self:_FireTextChanged()
                end
                return true
            end,
        },
        {
            Key = Keys.VK_DELETE,
            MSG = kd,
            IsControl = true,
            Description = "LOC_CAI_KB_DELETE_WORD_FORWARD",
            Action = function(self)
                if not active(self) or self._readOnly then return false end
                local d
                if self._selStart then
                    d = E.DeleteSelection(self)
                else
                    d = E.DeleteWordForward(self)
                end
                if d ~= "" then
                    Speak(self._passwordMask and string.rep("*", #d) or d, true, false)
                    self:_FireTextChanged()
                end
                return true
            end,
        },
        -- Cursor movement
        {
            Key = Keys.VK_LEFT,
            MSG = kd,
            Description = "LOC_CAI_KB_CURSOR_LEFT",
            Action = function(self)
                if not active(self) then return false end
                E.MoveCursor(self, -1, false, false); return true
            end
        },
        {
            Key = Keys.VK_LEFT,
            MSG = kd,
            IsShift = true,
            Description = "LOC_CAI_KB_SELECT_LEFT",
            Action = function(
                self)
                if not active(self) then return false end
                E.MoveCursor(self, -1, true, false); return true
            end
        },
        {
            Key = Keys.VK_LEFT,
            MSG = kd,
            IsControl = true,
            Description = "LOC_CAI_KB_WORD_LEFT",
            Action = function(
                self)
                if not active(self) then return false end
                E.MoveCursor(self, -1, false, true); return true
            end
        },
        {
            Key = Keys.VK_LEFT,
            MSG = kd,
            IsControl = true,
            IsShift = true,
            Description = "LOC_CAI_KB_SELECT_WORD_LEFT",
            Action = function(
                self)
                if not active(self) then return false end
                E.MoveCursor(self, -1, true, true); return true
            end
        },
        {
            Key = Keys.VK_RIGHT,
            MSG = kd,
            Description = "LOC_CAI_KB_CURSOR_RIGHT",
            Action = function(self)
                if not active(self) then return false end
                E.MoveCursor(self, 1, false, false); return true
            end
        },
        {
            Key = Keys.VK_RIGHT,
            MSG = kd,
            IsShift = true,
            Description = "LOC_CAI_KB_SELECT_RIGHT",
            Action = function(
                self)
                if not active(self) then return false end
                E.MoveCursor(self, 1, true, false); return true
            end
        },
        {
            Key = Keys.VK_RIGHT,
            MSG = kd,
            IsControl = true,
            Description = "LOC_CAI_KB_WORD_RIGHT",
            Action = function(
                self)
                if not active(self) then return false end
                E.MoveCursor(self, 1, false, true); return true
            end
        },
        {
            Key = Keys.VK_RIGHT,
            MSG = kd,
            IsControl = true,
            IsShift = true,
            Description = "LOC_CAI_KB_SELECT_WORD_RIGHT",
            Action = function(
                self)
                if not active(self) then return false end
                E.MoveCursor(self, 1, true, true); return true
            end
        },
        -- Line-edge movement
        {
            Key = Keys.VK_HOME,
            MSG = kd,
            BubbleWhenDisabled = true,
            Description = "LOC_CAI_KB_LINE_START",
            Action = function(self)
                if not active(self) then return false end
                local buf = self._buffer or ""
                E.MoveToEdge(self, E.LineStart(buf, self._cursor or 0), false); return true
            end,
        },
        {
            Key = Keys.VK_HOME,
            MSG = kd,
            IsShift = true,
            Description = "LOC_CAI_KB_SELECT_TO_LINE_START",
            Action = function(self)
                if not active(self) then return false end
                local buf = self._buffer or ""
                E.MoveToEdge(self, E.LineStart(buf, self._cursor or 0), true); return true
            end,
        },
        {
            Key = Keys.VK_END,
            MSG = kd,
            BubbleWhenDisabled = true,
            Description = "LOC_CAI_KB_LINE_END",
            Action = function(self)
                if not active(self) then return false end
                local buf = self._buffer or ""
                E.MoveToEdge(self, E.LineEnd(buf, self._cursor or 0), false); return true
            end,
        },
        {
            Key = Keys.VK_END,
            MSG = kd,
            IsShift = true,
            Description = "LOC_CAI_KB_SELECT_TO_LINE_END",
            Action = function(self)
                if not active(self) then return false end
                local buf = self._buffer or ""
                E.MoveToEdge(self, E.LineEnd(buf, self._cursor or 0), true); return true
            end,
        },
        {
            Key = Keys.VK_HOME,
            MSG = kd,
            IsControl = true,
            Description = "LOC_CAI_KB_DOCUMENT_START",
            Action = function(self)
                if not active(self) then return false end
                local prevSelStart, prevCursor = self._selStart, self._cursor or 0
                self._cursor = 0
                self._selStart = nil
                E.SpeakWithDeselect(self, E.GetLineText(self, 0), prevSelStart, prevCursor)
                return true
            end,
        },
        {
            Key = Keys.VK_END,
            MSG = kd,
            IsControl = true,
            Description = "LOC_CAI_KB_DOCUMENT_END",
            Action = function(self)
                if not active(self) then return false end
                local prevSelStart, prevCursor = self._selStart, self._cursor or 0
                self._cursor = #(self._buffer or "")
                self._selStart = nil
                E.SpeakWithDeselect(self, E.GetLineText(self, self._cursor), prevSelStart, prevCursor)
                return true
            end,
        },
        {
            Key = Keys.VK_HOME,
            MSG = kd,
            IsControl = true,
            IsShift = true,
            Description = "LOC_CAI_KB_SELECT_TO_DOCUMENT_START",
            Action = function(self)
                if not active(self) then return false end
                E.MoveToEdge(self, 0, true); return true
            end
        },
        {
            Key = Keys.VK_END,
            MSG = kd,
            IsControl = true,
            IsShift = true,
            Description = "LOC_CAI_KB_SELECT_TO_DOCUMENT_END",
            Action = function(self)
                if not active(self) then return false end
                E.MoveToEdge(self, #(self._buffer or ""), true); return true
            end
        },
        -- Vertical movement
        {
            Key = Keys.VK_UP,
            MSG = kd,
            BubbleWhenDisabled = true,
            Description = "LOC_CAI_KB_LINE_UP",
            Action = function(self)
                if not active(self) then return false end
                local buf = self._buffer or ""
                local prevSelStart, prevCursor = self._selStart, self._cursor or 0
                local newPos = E.PrevLinePos(buf, prevCursor)
                if newPos then self._cursor = newPos end
                self._selStart = nil
                E.SpeakWithDeselect(self, E.GetLineText(self, self._cursor), prevSelStart, prevCursor)
                return true
            end,
        },
        {
            Key = Keys.VK_DOWN,
            MSG = kd,
            BubbleWhenDisabled = true,
            Description = "LOC_CAI_KB_LINE_DOWN",
            Action = function(self)
                if not active(self) then return false end
                local buf = self._buffer or ""
                local prevSelStart, prevCursor = self._selStart, self._cursor or 0
                local newPos = E.NextLinePos(buf, prevCursor)
                if newPos then self._cursor = newPos end
                self._selStart = nil
                E.SpeakWithDeselect(self, E.GetLineText(self, self._cursor), prevSelStart, prevCursor)
                return true
            end,
        },
        {
            Key = Keys.VK_UP,
            MSG = kd,
            IsShift = true,
            Description = "LOC_CAI_KB_SELECT_LINE_UP",
            Action = function(self)
                if not active(self) then return false end
                local buf = self._buffer or ""
                local oldSelStart = self._selStart
                local oldCursor = self._cursor or 0
                local newPos = E.PrevLinePos(buf, oldCursor)
                if not newPos then return true end
                if not self._selStart then self._selStart = oldCursor end
                self._cursor = newPos
                E.SpeakSelectionChange(self, oldSelStart, oldCursor); return true
            end,
        },
        {
            Key = Keys.VK_DOWN,
            MSG = kd,
            IsShift = true,
            Description = "LOC_CAI_KB_SELECT_LINE_DOWN",
            Action = function(self)
                if not active(self) then return false end
                local buf = self._buffer or ""
                local oldSelStart = self._selStart
                local oldCursor = self._cursor or 0
                local newPos = E.NextLinePos(buf, oldCursor)
                if not newPos then return true end
                if not self._selStart then self._selStart = oldCursor end
                self._cursor = newPos
                E.SpeakSelectionChange(self, oldSelStart, oldCursor); return true
            end,
        },
        -- Clipboard + select-all
        {
            Key = Keys.C,
            MSG = kd,
            IsControl = true,
            Description = "LOC_CAI_KB_COPY",
            Action = function(self)
                if not active(self) then return false end
                local sel = E.GetSelectedText(self)
                if sel ~= "" then
                    UIManager:SetClipboardString(sel)
                    Speak(E.FormatCopied(self, sel), true, false)
                else
                    local buf = self._buffer or ""
                    local pos = self._cursor or 0
                    local ch = string.sub(buf, pos + 1, pos + 1)
                    if ch ~= "" then
                        UIManager:SetClipboardString(ch)
                        Speak(E.FormatCopied(self, ch), true, false)
                    end
                end
                return true
            end,
        },
        {
            Key = Keys.V,
            MSG = kd,
            IsControl = true,
            Description = "LOC_CAI_KB_PASTE",
            Action = function(self)
                if not active(self) or self._readOnly then return false end
                local text = CAI.GetClipboardText()
                if text and text ~= "" then
                    if E.InsertText(self, text) then
                        Speak(E.FormatPasted(self, text), true, false)
                        self:_FireTextChanged()
                    end
                end
                return true
            end,
        },
        {
            Key = Keys.A,
            MSG = kd,
            IsControl = true,
            Description = "LOC_CAI_KB_SELECT_ALL",
            Action = function(self)
                if not active(self) then return false end
                E.SelectAll(self); return true
            end,
        },
    }
end

--#endregion

CAIWidgetRegistry.Register("EditBox", EditBoxWidget.Create)
