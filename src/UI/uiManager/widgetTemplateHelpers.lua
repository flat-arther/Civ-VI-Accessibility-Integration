---@class WidgetTemplateHelpers
---@field Manager UIScreenManager
WidgetTemplateHelpers = {}

-- ===========================================================================
-- Edit-widget convenience: push text into a CAI Edit widget, normalizing
-- [NEWLINE] tokens. Used by panels that drive read-only detail editors.
-- ===========================================================================
---@param w UIWidget
---@param text string|nil
function WidgetTemplateHelpers:SetEditBoxText(w, text)
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

-- ===========================================================================
-- PopupDialog wrapper: build a Dialog widget around a vanilla PopupDialog.
-- ===========================================================================
---@param popup table
---@return UIWidget|nil
function WidgetTemplateHelpers:CreatePopupDialog(popup)
    local mgr = self.Manager
    if not mgr or not popup then return end
    local dlgContent = {}
    local buttonRow = {}

    for _, item in ipairs(popup.PopupControls) do
        local type = item.Type
        local w
        if type == "Text" then
            w = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIwidgetTemplateHelpersStaticText"), "StaticText", {
                GetLabel = function() return item.Control:GetText() end
            })
        elseif type == "Check" then
            w = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIwidgetTemplateHelpersCheckbox"), "Checkbox", {
                GetLabel = function()
                    if item.Control.GetTextButton then
                        return item.Control:GetTextButton():GetText() or ""
                    end
                    return item.Control:GetText() or ""
                end,
                GetValue = function()
                    return item.Control:IsChecked()
                        and Locale.Lookup("LOC_OPTIONS_ENABLED")
                        or Locale.Lookup("LOC_OPTIONS_DISABLED")
                end,
                Toggle = function() item.Callback() end,
                OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end
            })
        elseif type == "EditBox" then
            w = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIwidgetTemplateHelpersEdit"), "Edit", {
                GetLabel     = function()
                    local p = item.Control:GetParent()
                    if not p or not p.EditLabel then return "" end
                    return p.EditLabel:GetText() or ""
                end,
                GetValue     = function() return item.Control:GetText() end,
                OnSetText    = function(w, text) item.Control:SetText(text) end,
                OnCommit     = function(w, text) item.Control:SetText(text) end,
                OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end
            })
        elseif type == "Count" then
            w = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIwidgetTemplateHelpersStaticText"), "StaticText", {
                GetLabel = function()
                    local val = nil
                    for _, child in ipairs(item.Control:GetChildren()) do
                        if child:GetID() == "Text" then
                            val = child;
                            break;
                        end
                    end
                    if not val then return "" end
                    local text = val:GetText()
                    return Locale.Lookup("LOC_CAI_DIALOG_COUNT", text) or ""
                end,
                OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end
            })
        elseif type == "Button" then
            w = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIwidgetTemplateHelpersButton"), "Button", {
                GetLabel = function() return item.Control:GetText() or "" end,
                GetTooltip = function() return item.Control:GetToolTipString() or "" end,
                IsDisabled = function() return item.Control:IsDisabled() end,
                OnClick = function() item.Callback() end,
                OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end
            })
        end
        if w then
            w.SpeechSettings["Position"] = false
            if type ~= "Button" then
                table.insert(dlgContent, w)
            else
                table.insert(buttonRow, w)
            end
        end
    end

    local function GetTitle() return popup.Controls.PopupTitle:GetText() end
    return self:MakeGeneralDialog(GetTitle, buttonRow, dlgContent)
end

-- ===========================================================================
-- Generic dialog scaffold: title + content rows + button row.
-- ===========================================================================
---@param titleFunc function
---@param actionButtons UIWidget[]
---@param dlgContent UIWidget[]
---@param defaultActionButton integer ---The index of the default action button to click when pressing enter
---@return UIWidget|nil
function WidgetTemplateHelpers:MakeGeneralDialog(titleFunc, actionButtons, dlgContent, defaultActionButton)
    local mgr = self.Manager
    if not mgr or not titleFunc or not actionButtons then return end
    local d = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIwidgetTemplateHelpersDialog"), "Dialog", {
        GetLabel = titleFunc,
    })
    d:AddInputBindings({
        { Key = Keys.VK_UP,   MSG = KeyEvents.KeyDown, Action = function(w) return w:Navigate(-1) end },
        { Key = Keys.VK_DOWN, MSG = KeyEvents.KeyDown, Action = function(w) return w:Navigate(1) end }
    })
    local buttonRow = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIwidgetTemplateHelpersPanel"), "Panel", {
        WrapAround = false,
        SpeechSettings = { Position = false, Role = false },
        OnFocusLeave = function(w) w.FocusedChild = nil end,
    })
    buttonRow:AddInputBindings({
        { Key = Keys.VK_LEFT,  MSG = KeyEvents.KeyDown, Action = function(w) return w:Navigate(-1) end },
        { Key = Keys.VK_RIGHT, MSG = KeyEvents.KeyDown, Action = function(w) return w:Navigate(1) end },
    })
    if dlgContent and #dlgContent > 0 then
        d:AddChildren(dlgContent)
    end
    buttonRow:AddChildren(actionButtons)
    d:AddChild(buttonRow)
    if not defaultActionButton then defaultActionButton = 1 end
    if defaultActionButton > #actionButtons then defaultActionButton = #actionButtons end
    if defaultActionButton < 1 then defaultActionButton = 1 end
    d:SetDefaultActionWidget(actionButtons[defaultActionButton])
    return d
end

-- ===========================================================================
-- Navigation helpers
-- ===========================================================================

---Finds the first visible child in a widget's Children list, searching from
---startIdx in the given direction. Returns the child and its index.
---@param w UIWidget
---@param startIdx integer
---@param direction 1|-1
---@param allowWrap boolean
---@return UIWidget|nil, integer|nil
function WidgetTemplateHelpers:FindVisibleChild(w, startIdx, direction, allowWrap)
    local children = w.Children
    if not children then return nil, nil end
    local numChildren = #children
    if numChildren == 0 then return nil, nil end

    for i = 1, numChildren do
        local idx = (startIdx + (i * direction) - 1) % numChildren + 1
        local candidate = children[idx]
        local isHidden = candidate.IsHidden and candidate:IsHidden()
        if not isHidden then
            if not allowWrap then
                local crossedBoundary
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

---@param w UIWidget
---@return UIWidget|nil
function WidgetTemplateHelpers:FindFirstVisibleChild(w)
    if not w.Children or #w.Children == 0 then return nil end
    for _, child in ipairs(w.Children) do
        local isHidden = child.IsHidden and child:IsHidden()
        if not isHidden then return child end
    end
    return nil
end

---@param w UIWidget
---@return UIWidget|nil
function WidgetTemplateHelpers:FindLastVisibleChild(w)
    if not w.Children or #w.Children == 0 then return nil end
    for i = #w.Children, 1, -1 do
        local child = w.Children[i]
        local isHidden = child.IsHidden and child:IsHidden()
        if not isHidden then return child end
    end
    return nil
end

---@param w UIWidget
---@param direction 1|-1
---@return boolean
function WidgetTemplateHelpers:NavigateSimpleList(w, direction)
    local children = w.Children
    if not children or #children == 0 then return false end
    local startIdx = w:GetChildIndex(w.FocusedChild) or w.DefaultIndex or 0
    local candidate = self:FindVisibleChild(w, startIdx, direction, w.WrapAround)
    if candidate then
        w.Manager:SetFocus(candidate)
        return true
    end
    return false
end

---@param w UIWidget
---@return boolean
function WidgetTemplateHelpers:NavigateToFirst(w)
    local child = self:FindFirstVisibleChild(w)
    if child then
        w.Manager:SetFocus(child)
        return true
    end
    return false
end

---@param w UIWidget
---@return boolean
function WidgetTemplateHelpers:NavigateToLast(w)
    local child = self:FindLastVisibleChild(w)
    if child then
        w.Manager:SetFocus(child)
        return true
    end
    return false
end

---Returns FocusedChild if any, else first visible child.
---@param w UIWidget
function WidgetTemplateHelpers:GetContainerDefChild(w)
    if not w.Children or #w.Children == 0 then return end
    if w.FocusedChild then return w.FocusedChild end
    local defaultIndex = w.DefaultIndex or 1
    local child = self:FindVisibleChild(w, defaultIndex - 1, 1, true)
    if child then return child end
    return self:FindFirstVisibleChild(w)
end

-- ===========================================================================
-- Treeview flat traversal: pre-order walk over visible TreeviewItems,
-- descending into a node's children only when the node IsExpanded.
-- ===========================================================================

---Returns true if the widget has any non-hidden children.
local function HasVisibleChildren(self, w)
    if not w.Children or #w.Children == 0 then return false end
    for _, c in ipairs(w.Children) do
        local hidden = c.IsHidden and c:IsHidden()
        if not hidden then return true end
    end
    return false
end

---Build a flat in-order list of every visible TreeviewItem reachable from root,
---honoring IsExpanded on intermediate nodes.
---@param root UIWidget
---@return UIWidget[]
function WidgetTemplateHelpers:FlattenTree(root)
    local out = {}
    local function walk(node)
        if not node.Children then return end
        for _, child in ipairs(node.Children) do
            local hidden = child.IsHidden and child:IsHidden()
            if not hidden then
                table.insert(out, child)
                if child.IsExpanded and HasVisibleChildren(self, child) then
                    walk(child)
                end
            end
        end
    end
    walk(root)
    return out
end

---Move focus to the next/previous visible TreeviewItem in flat order.
---@param root UIWidget
---@param direction 1|-1
---@return boolean
function WidgetTemplateHelpers:NavigateTreeFlat(root, direction)
    local flat = self:FlattenTree(root)
    if #flat == 0 then return false end

    local mgr = root.Manager
    local current = mgr:GetFocusedWidget()

    -- Find current index in the flat list (walk up to a flat entry if focus is below one).
    local curIdx
    local node = current
    while node and not curIdx do
        for i, item in ipairs(flat) do
            if item == node then
                curIdx = i; break
            end
        end
        node = node.Parent
    end

    local targetIdx
    if not curIdx then
        targetIdx = (direction > 0) and 1 or #flat
    else
        targetIdx = curIdx + direction
        if targetIdx < 1 or targetIdx > #flat then return false end
    end

    local target = flat[targetIdx]
    if target and target.Type == "TreeviewItem" then
        target.FocusedChild = nil
    end
    mgr:SetFocus(target)
    return true
end

---@param root UIWidget
---@return boolean
function WidgetTemplateHelpers:NavigateTreeFirst(root)
    local flat = self:FlattenTree(root)
    if #flat == 0 then return false end
    if flat[1].Type == "TreeviewItem" then
        flat[1].FocusedChild = nil
    end
    root.Manager:SetFocus(flat[1])
    return true
end

---@param root UIWidget
---@return boolean
function WidgetTemplateHelpers:NavigateTreeLast(root)
    local flat = self:FlattenTree(root)
    if #flat == 0 then return false end
    if flat[#flat].Type == "TreeviewItem" then
        flat[#flat].FocusedChild = nil
    end
    root.Manager:SetFocus(flat[#flat])
    return true
end

---@param root UIWidget
---@param node UIWidget|nil
---@return UIWidget|nil
function WidgetTemplateHelpers:GetTreeItemForWidget(root, node)
    while node and node ~= root do
        if node.Type == "TreeviewItem" then return node end
        node = node.Parent
    end
    return nil
end

---@param root UIWidget
---@return UIWidget|nil
function WidgetTemplateHelpers:GetFocusedTreeItem(root)
    if not root or not root.Manager then return nil end
    return self:GetTreeItemForWidget(root, root.Manager:GetFocusedWidget())
end

---@param root UIWidget
---@param item UIWidget|nil
---@return UIWidget|nil
function WidgetTemplateHelpers:GetParentTreeItem(root, item)
    if not item then return nil end
    return self:GetTreeItemForWidget(root, item.Parent)
end

---@param item UIWidget|nil
---@return boolean
function WidgetTemplateHelpers:ExpandTreeItem(item)
    if not item or item:IsLeaf() or item.IsExpanded then return false end
    item:Expand()
    return true
end

---@param item UIWidget|nil
---@return boolean
function WidgetTemplateHelpers:CollapseTreeItem(item)
    if not item or not item.IsExpanded then return false end
    item:Collapse()
    return true
end

---@param item UIWidget|nil
---@return boolean
function WidgetTemplateHelpers:ToggleTreeItem(item)
    if not item or item:IsLeaf() then return false end
    if item.IsExpanded then
        item:Collapse()
    else
        item:Expand()
    end
    return true
end

---@param root UIWidget
---@return boolean
function WidgetTemplateHelpers:ToggleFocusedTreeItem(root)
    return self:ToggleTreeItem(self:GetFocusedTreeItem(root))
end

---@param item UIWidget|nil
---@return boolean
function WidgetTemplateHelpers:FocusTreeFirstChild(item)
    if not item or item:IsLeaf() then return false end
    local child = self:FindFirstVisibleChild(item)
    if not child then return false end
    item.Manager:SetFocus(child)
    return true
end

---@param root UIWidget
---@param item UIWidget|nil
---@return boolean
function WidgetTemplateHelpers:FocusParentTreeItem(root, item)
    local parent = self:GetParentTreeItem(root, item)
    if not parent then return false end
    parent.FocusedChild = nil
    root.Manager:SetFocus(parent)
    return true
end

---@param root UIWidget
---@return boolean
function WidgetTemplateHelpers:ExpandOrDescendTree(root)
    local item = self:GetFocusedTreeItem(root)
    if not item then return false end
    if type(item.IsLeaf) == "function" and item:IsLeaf() then return false end
    if self:ExpandTreeItem(item) then
        return true
    end
    return self:FocusTreeFirstChild(item)
end

---@param root UIWidget
---@return boolean
function WidgetTemplateHelpers:CollapseOrAscendTree(root)
    local item = self:GetFocusedTreeItem(root)
    if not item then return false end
    if self:CollapseTreeItem(item) then
        return true
    end
    return self:FocusParentTreeItem(root, item)
end

-- ===========================================================================
-- Search helpers (type-to-find)
-- ===========================================================================

---@param root UIWidget
---@param query string
---@param maxDepth integer
---@return UIWidget|nil
function WidgetTemplateHelpers:FindNextMatch(root, query, maxDepth)
    local children = root.Children
    if not children or #children == 0 then return nil end

    local startIdx = root:GetChildIndex(root.FocusedChild) or 0
    local count = #children

    for i = 1, count do
        local idx = ((startIdx + i - 1) % count) + 1
        local candidate = children[idx]
        local found = self:FindMatchDFS(candidate, query, 0, maxDepth)
        if found then
            local current = found
            while current do
                if current.Expand then current:Expand() end
                current = current.Parent
            end
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
function WidgetTemplateHelpers:FindMatchDFS(w, query, depth, maxDepth)
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
            local found = self:FindMatchDFS(child, query, depth + 1, maxDepth)
            if found then return found end
        end
    end
    return nil
end

-- ===========================================================================
-- EditBox helpers
-- ===========================================================================

---@param w UIWidget
---@return integer|nil, integer|nil
function WidgetTemplateHelpers:EditBox_GetSelectionRange(w)
    if not w.EditSelStart then return nil, nil end
    local a, b = w.EditSelStart, w.EditCursor
    if a > b then a, b = b, a end
    return a, b
end

---@param w UIWidget
---@return string
function WidgetTemplateHelpers:EditBox_GetSelectedText(w)
    local a, b = self:EditBox_GetSelectionRange(w)
    if not a then return "" end
    return string.sub(w.EditBuffer, a + 1, b)
end

---@param w UIWidget
function WidgetTemplateHelpers:EditBox_Activate(w)
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

---@param w UIWidget
function WidgetTemplateHelpers:EditBox_Commit(w)
    w.EditActive = false
    w.EditSelStart = nil
    local text = w.EditBuffer or ""
    if w.OnSetText then w:OnSetText(text) end
    if w.OnCommit then w:OnCommit(text) end
    Speak(Locale.Lookup("LOC_CAI_EDIT_COMMITTED", text))
end

---@param w UIWidget
function WidgetTemplateHelpers:EditBox_Cancel(w)
    w.EditActive = false
    w.EditSelStart = nil
    w.EditBuffer = w.EditOriginal or ""
    w.EditCursor = 0
    if w.OnSetText then w:OnSetText(w.EditBuffer) end
    Speak(Locale.Lookup("LOC_CAI_EDIT_CANCELLED"))
end

---@param w UIWidget
function WidgetTemplateHelpers:EditBox_SyncAndSpeak(w)
    if w.OnSetText then w:OnSetText(w.EditBuffer) end
end

---@param w UIWidget
---@return string
function WidgetTemplateHelpers:EditBox_DeleteSelection(w)
    local a, b = self:EditBox_GetSelectionRange(w)
    if not a then return "" end
    local deleted = string.sub(w.EditBuffer, a + 1, b)
    w.EditBuffer = string.sub(w.EditBuffer, 1, a) .. string.sub(w.EditBuffer, b + 1)
    w.EditCursor = a
    w.EditSelStart = nil
    return deleted
end

---@param w UIWidget
---@param text string
function WidgetTemplateHelpers:EditBox_InsertText(w, text)
    text = string.gsub(text, "\r\n", "\n")
    if w.EditSelStart then
        self:EditBox_DeleteSelection(w)
    end
    local buf = w.EditBuffer or ""
    local pos = w.EditCursor or 0
    w.EditBuffer = string.sub(buf, 1, pos) .. text .. string.sub(buf, pos + 1)
    w.EditCursor = pos + #text
end

---@param w UIWidget
function WidgetTemplateHelpers:EditBox_BackspaceChar(w)
    local pos = w.EditCursor or 0
    if pos <= 0 then return end
    local buf = w.EditBuffer or ""
    local deleted = string.sub(buf, pos, pos)
    w.EditBuffer = string.sub(buf, 1, pos - 1) .. string.sub(buf, pos + 1)
    w.EditCursor = pos - 1
    Speak(deleted, true)
end

---@param w UIWidget
function WidgetTemplateHelpers:EditBox_DeleteChar(w)
    local pos = w.EditCursor or 0
    local buf = w.EditBuffer or ""
    if pos >= #buf then return end
    local deleted = string.sub(buf, pos + 1, pos + 1)
    w.EditBuffer = string.sub(buf, 1, pos) .. string.sub(buf, pos + 2)
    Speak(deleted, true)
end

---@param ch string
---@return boolean
function WidgetTemplateHelpers:IsWordBoundary(ch)
    return ch == " " or ch == "\n" or ch == "\t"
end

---@param buf string
---@param pos integer
---@return integer
function WidgetTemplateHelpers:EditBox_FindWordLeft(buf, pos)
    if pos <= 0 then return 0 end
    local i = pos
    while i > 0 and string.sub(buf, i, i) == " " do
        i = i - 1
    end
    if i > 0 and string.sub(buf, i, i) == "\n" then return i end
    while i > 0 and not self:IsWordBoundary(string.sub(buf, i, i)) do
        i = i - 1
    end
    return i
end

---@param buf string
---@param pos integer
---@return integer
function WidgetTemplateHelpers:EditBox_FindDeleteLeft(buf, pos)
    if pos <= 0 then return 0 end
    local i = pos
    local skippedSpace = false
    while i > 0 and string.sub(buf, i, i) == " " do
        i = i - 1
        skippedSpace = true
    end
    if i > 0 and string.sub(buf, i, i) == "\n" then
        return i - 1
    end
    while i > 0 and not self:IsWordBoundary(string.sub(buf, i, i)) do
        i = i - 1
    end
    if not skippedSpace then
        while i > 0 and string.sub(buf, i, i) == " " do
            i = i - 1
        end
    end
    return i
end

---@param buf string
---@param pos integer
---@return string
function WidgetTemplateHelpers:EditBox_GetWordAt(buf, pos)
    local len = #buf
    if pos >= len then return "" end
    local i = pos + 1
    while i <= len and self:IsWordBoundary(string.sub(buf, i, i)) do
        i = i + 1
    end
    local start = i
    while i <= len and not self:IsWordBoundary(string.sub(buf, i, i)) do
        i = i + 1
    end
    return string.sub(buf, start, i - 1)
end

---@param buf string
---@param pos integer
---@return integer
function WidgetTemplateHelpers:EditBox_FindWordRight(buf, pos)
    local len = #buf
    if pos >= len then return len end
    local i = pos + 1
    if string.sub(buf, i, i) == "\n" then return pos + 1 end
    while i <= len and not self:IsWordBoundary(string.sub(buf, i, i)) do
        i = i + 1
    end
    while i <= len and string.sub(buf, i, i) == " " do
        i = i + 1
    end
    return i - 1
end

---@param w UIWidget
function WidgetTemplateHelpers:EditBox_BackspaceWord(w)
    local pos = w.EditCursor or 0
    if pos <= 0 then return end
    local buf = w.EditBuffer or ""
    local deleteStart = self:EditBox_FindDeleteLeft(buf, pos)
    local deleted = string.sub(buf, deleteStart + 1, pos)
    w.EditBuffer = string.sub(buf, 1, deleteStart) .. string.sub(buf, pos + 1)
    w.EditCursor = deleteStart
    Speak(deleted, true)
end

---@param w UIWidget
function WidgetTemplateHelpers:EditBox_DeleteWordForward(w)
    local pos = w.EditCursor or 0
    local buf = w.EditBuffer or ""
    if pos >= #buf then return end
    local wordEnd = self:EditBox_FindWordRight(buf, pos)
    local deleted = string.sub(buf, pos + 1, wordEnd)
    w.EditBuffer = string.sub(buf, 1, pos) .. string.sub(buf, wordEnd + 1)
    Speak(deleted, true)
end

---@param buf string
---@param pos integer
---@return integer
function WidgetTemplateHelpers:EditBox_LineStart(buf, pos)
    if pos <= 0 then return 0 end
    local i = pos
    while i > 0 and string.sub(buf, i, i) ~= "\n" do
        i = i - 1
    end
    if i > 0 then return i end
    return 0
end

---@param buf string
---@param pos integer
---@return integer
function WidgetTemplateHelpers:EditBox_LineEnd(buf, pos)
    local len = #buf
    local i = pos + 1
    while i <= len and string.sub(buf, i, i) ~= "\n" do
        i = i + 1
    end
    return i - 1
end

---@param buf string
---@param pos integer
---@return string
function WidgetTemplateHelpers:EditBox_GetCurrentLine(buf, pos)
    local ls = self:EditBox_LineStart(buf, pos)
    local le = self:EditBox_LineEnd(buf, pos)
    return string.sub(buf, ls + 1, le)
end

---@param buf string
---@param pos integer
function WidgetTemplateHelpers:SpeakLine(buf, pos)
    local line = self:EditBox_GetCurrentLine(buf, pos)
    Speak(#line > 0 and line or Locale.Lookup("LOC_CAI_EDIT_BLANK"), true)
end

---@param buf string
---@param pos integer
---@return integer|nil
function WidgetTemplateHelpers:EditBox_PrevLinePos(buf, pos)
    local ls = self:EditBox_LineStart(buf, pos)
    if ls <= 0 then return nil end
    local col = pos - ls
    local prevLineEnd = ls - 1
    if prevLineEnd > 0 and string.sub(buf, prevLineEnd, prevLineEnd) == "\n" then
        return prevLineEnd
    end
    local prevLineStart = self:EditBox_LineStart(buf, prevLineEnd - 1)
    local prevLineLen = prevLineEnd - prevLineStart
    local newCol = math.min(col, prevLineLen)
    return prevLineStart + newCol
end

---@param buf string
---@param pos integer
---@return integer|nil
function WidgetTemplateHelpers:EditBox_NextLinePos(buf, pos)
    local le = self:EditBox_LineEnd(buf, pos)
    local len = #buf
    if le >= len then return nil end
    local nextLineStart = le + 1
    local nextLineEnd = self:EditBox_LineEnd(buf, nextLineStart)
    local col = pos - self:EditBox_LineStart(buf, pos)
    local nextLineLen = nextLineEnd - nextLineStart
    local newCol = math.min(col, nextLineLen)
    return nextLineStart + newCol
end

---@param w UIWidget
---@param oldSelStart integer|nil
---@param oldCursor integer
function WidgetTemplateHelpers:SpeakSelectionChange(w, oldSelStart, oldCursor)
    local buf = w.EditBuffer or ""

    local oldA, oldB
    if oldSelStart then
        oldA, oldB = oldSelStart, oldCursor
        if oldA > oldB then oldA, oldB = oldB, oldA end
    end
    local newA, newB = self:EditBox_GetSelectionRange(w)

    if oldA and not newA then
        local deselected = string.sub(buf, oldA + 1, oldB)
        if deselected ~= "" then
            Speak(Locale.Lookup("LOC_CAI_EDIT_UNSELECTED", deselected), true)
        end
        return
    end

    if not newA then
        local charAtCursor = string.sub(buf, w.EditCursor + 1, w.EditCursor + 1)
        if charAtCursor == "" then charAtCursor = Locale.Lookup("LOC_CAI_EDIT_BLANK") end
        Speak(charAtCursor, true)
        return
    end

    if not oldA then
        local sel = string.sub(buf, newA + 1, newB)
        if sel ~= "" then
            Speak(Locale.Lookup("LOC_CAI_EDIT_SELECTED", sel), true)
        end
        return
    end

    local oldEdge = oldCursor
    local newEdge = w.EditCursor
    if oldEdge == newEdge then return end

    local anchor = w.EditSelStart
    local oldDist = math.abs(oldEdge - anchor)
    local newDist = math.abs(newEdge - anchor)

    if newDist > oldDist then
        local lo = math.min(oldEdge, newEdge)
        local hi = math.max(oldEdge, newEdge)
        local added = string.sub(buf, lo + 1, hi)
        if added ~= "" then
            Speak(Locale.Lookup("LOC_CAI_EDIT_SELECTED", added), true)
        end
    else
        local lo = math.min(oldEdge, newEdge)
        local hi = math.max(oldEdge, newEdge)
        local removed = string.sub(buf, lo + 1, hi)
        if removed ~= "" then
            Speak(Locale.Lookup("LOC_CAI_EDIT_UNSELECTED", removed), true)
        end
    end
end

---@param w UIWidget
---@param direction 1|-1
---@param shift boolean
---@param ctrl boolean
function WidgetTemplateHelpers:EditBox_MoveCursor(w, direction, shift, ctrl)
    local buf = w.EditBuffer or ""
    local pos = w.EditCursor or 0
    local oldSelStart = w.EditSelStart
    local oldCursor = pos

    if w.EditSelStart and not shift then
        local a, b = self:EditBox_GetSelectionRange(w)
        local deselected = self:EditBox_GetSelectedText(w)
        w.EditCursor = (direction < 0) and a or b
        w.EditSelStart = nil
        if deselected ~= "" then
            Speak(Locale.Lookup("LOC_CAI_EDIT_UNSELECTED", deselected), true)
        end
        return
    end

    if shift and not w.EditSelStart then
        w.EditSelStart = pos
    end

    local newPos
    if ctrl then
        if direction < 0 then
            newPos = self:EditBox_FindWordLeft(buf, pos)
        else
            newPos = self:EditBox_FindWordRight(buf, pos)
        end
    else
        newPos = pos + direction
    end

    if newPos < 0 then newPos = 0 end
    if newPos > #buf then newPos = #buf end
    w.EditCursor = newPos

    if not shift then
        w.EditSelStart = nil
    end

    if shift then
        self:SpeakSelectionChange(w, oldSelStart, oldCursor)
    elseif ctrl then
        local word = self:EditBox_GetWordAt(buf, newPos)
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

---@param w UIWidget
---@param targetPos integer
---@param shift boolean
function WidgetTemplateHelpers:EditBox_MoveToEdge(w, targetPos, shift)
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

    self:SpeakSelectionChange(w, oldSelStart, oldCursor)
end

---@param w UIWidget
function WidgetTemplateHelpers:EditBox_SelectAll(w)
    local buf = w.EditBuffer or ""
    if #buf == 0 then
        Speak(Locale.Lookup("LOC_CAI_EDIT_BLANK"), true)
        return
    end
    w.EditSelStart = 0
    w.EditCursor = #buf
    Speak(Locale.Lookup("LOC_CAI_EDIT_SELECTED", buf), true)
end
