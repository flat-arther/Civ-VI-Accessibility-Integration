-- All helpers (Nav / Search / EditBox) live on WidgetTemplateHelpers (see
-- widgetTemplateHelpers.lua). Templates close over a local alias so each
-- binding can dispatch through it without re-resolving the global.
include("InputSupport")
---@class WidgetTemplate :UIWidget
---@field RegisterInputs InputBinding[]

local H = WidgetTemplateHelpers

---@type table<string, WidgetTemplate>
WidgetTemplates = {
    Panel = {
        DefaultIndex = 1,
        WrapAround = true,
        RegisterInputs = {
            { Key = Keys.VK_TAB, MSG = KeyEvents.KeyDown, Action = function(w) return w:Navigate(1) end },
            {
                Key = Keys.VK_TAB,
                MSG = KeyEvents.KeyDown,
                IsShift = true,
                Action = function(
                    w)
                    return w:Navigate(-1)
                end
            },
        },
        Navigate = function(w, dir) return H:NavigateSimpleList(w, dir) end,
        GetDefaultChild = function(w) return H:GetContainerDefChild(w) end
    },
    List = {
        DefaultIndex = 1,
        WrapAround = true,
        IsExpanded = true,
        RegisterInputs = {
            { Key = Keys.VK_UP,   MSG = KeyEvents.KeyDown, Action = function(w) return w:Navigate(-1) end },
            { Key = Keys.VK_DOWN, MSG = KeyEvents.KeyDown, Action = function(w) return w:Navigate(1) end },
            { Key = Keys.VK_HOME, MSG = KeyEvents.KeyDown, Action = function(w) return H:NavigateToFirst(w) end },
            { Key = Keys.VK_END,  MSG = KeyEvents.KeyDown, Action = function(w) return H:NavigateToLast(w) end },
        },
        Navigate = function(w, dir) return H:NavigateSimpleList(w, dir) end,
        GetDefaultChild = function(w) return H:GetContainerDefChild(w) end,
        OnCharInput = function(w, char)
            local mgr = w.Manager
            mgr:AppendSearchChar(char)
            local query = mgr.SearchBuffer
            local maxDepth = w.SearchDepth or 2
            local match = H:FindNextMatch(w, query, maxDepth)
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
            { Key = Keys.VK_LEFT,  MSG = KeyEvents.KeyDown, Action = function(w) return w:Navigate(-1) end },
            { Key = Keys.VK_RIGHT, MSG = KeyEvents.KeyDown, Action = function(w) return w:Navigate(1) end },
            { Key = Keys.VK_HOME,  MSG = KeyEvents.KeyDown, Action = function(w) return H:NavigateToFirst(w) end },
            { Key = Keys.VK_END,   MSG = KeyEvents.KeyDown, Action = function(w) return H:NavigateToLast(w) end },
        },
        Navigate = function(w, dir) return H:NavigateSimpleList(w, dir) end,
        GetDefaultChild = function(w) return H:GetContainerDefChild(w) end
    },
    SubMenu = {
        DefaultIndex = 1,
        WrapAround = true,
        IsExpanded = false,
        RegisterInputs = {
            {
                Key = Keys.VK_UP,
                MSG = KeyEvents.KeyDown,
                Action = function(w)
                    if w.IsExpanded then
                        w:Navigate(-1); return true
                    end
                    return false
                end
            },
            {
                Key = Keys.VK_DOWN,
                MSG = KeyEvents.KeyDown,
                Action = function(w)
                    if w.IsExpanded then
                        w:Navigate(1); return true
                    end
                    return false
                end
            },
            { Key = Keys.VK_RETURN, MSG = KeyEvents.KeyDown, Action = function(w) return w:Expand() end },
            { Key = Keys.VK_RIGHT,  MSG = KeyEvents.KeyDown, Action = function(w) return w:Expand() end },
            {
                Key = Keys.VK_LEFT,
                MSG = KeyEvents.KeyDown,
                Action = function(w)
                    if w.IsExpanded then
                        w.IsExpanded = false
                        w.FocusedChild = nil
                        w.Manager:SetFocus(w)
                        if w.OnToggleExpanded then w:OnToggleExpanded(w.IsExpanded) end
                        return true
                    end
                    return false
                end
            },
            {
                Key = Keys.VK_HOME,
                MSG = KeyEvents.KeyDown,
                Action = function(w)
                    if w.IsExpanded then return H:NavigateToFirst(w) end
                    return false
                end
            },
            {
                Key = Keys.VK_END,
                MSG = KeyEvents.KeyDown,
                Action = function(w)
                    if w.IsExpanded then return H:NavigateToLast(w) end
                    return false
                end
            },
        },
        Navigate = function(w, dir) return H:NavigateSimpleList(w, dir) end,
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
            { Key = Keys.VK_RETURN, MSG = KeyEvents.KeyUp, Action = function(w) return w:Click(w) end },
            { Key = Keys.VK_SPACE,  Action = function(w) return w:Click(w) end },
        },
        Click = function(w)
            if w.IsDisabled and w:IsDisabled() then return true end
            if w.OnClick then w:OnClick() end
            return true
        end
    },
    DropdownMenu = {
        Role = "DropdownMenu",
        RegisterInputs = {
            {
                Key = Keys.VK_RETURN,
                Action = function(w)
                    if w.OnClick then w:OnClick() end
                    return true
                end
            },
        },
    },
    Slider = {
        RegisterInputs = {
            {
                Key = Keys.VK_LEFT,
                MSG = KeyEvents.KeyDown,
                Action = function(w)
                    if w.Decrement then w:Decrement() end
                    w:SetValue(w.GetValue and w:GetValue() or "")
                    return true
                end
            },
            {
                Key = Keys.VK_RIGHT,
                MSG = KeyEvents.KeyDown,
                Action = function(w)
                    if w.Increment then w:Increment() end
                    w:SetValue(w.GetValue and w:GetValue() or "")
                    return true
                end
            },
            {
                Key = Keys.VK_PRIOR,
                MSG = KeyEvents.KeyDown,
                Action = function(w)
                    for i = 1, 10 do if w.Increment then w:Increment() end end
                    w:SetValue(w.GetValue and w:GetValue() or "")
                    return true
                end
            },
            {
                Key = Keys.VK_NEXT,
                MSG = KeyEvents.KeyDown,
                Action = function(w)
                    for i = 1, 10 do if w.Decrement then w:Decrement() end end
                    w:SetValue(w.GetValue and w:GetValue() or "")
                    return true
                end
            },
        },
    },
    Checkbox = {
        RegisterInputs = {
            {
                Key = Keys.VK_SPACE,
                Action = function(w)
                    if w.Toggle then w:Toggle() end
                    w:SetValue(w.GetValue and w:GetValue() or "")
                    return true
                end
            },
        },
    },
    TriStateToggle = {
        Role = "Checkbox",
        RegisterInputs = {
            {
                Key = Keys.VK_RETURN,
                Action = function(w)
                    if w.AdvanceState then w:AdvanceState() end
                    w:SpeakElements({ "label", "value", "state", "tooltip" })
                    return true
                end
            },
            {
                Key = Keys.VK_SPACE,
                Action = function(w)
                    if w.AdvanceState then w:AdvanceState() end
                    w:SpeakElements({ "label", "value", "state", "tooltip" })
                    return true
                end
            },
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
            {
                Key = Keys.VK_RETURN,
                Action = function(w)
                    if not w.EditActive then
                        H:EditBox_Activate(w)
                    else
                        if not w.EditReadOnly then H:EditBox_Commit(w) end
                    end
                    return true
                end
            },
            {
                Key = Keys.VK_ESCAPE,
                Action = function(w)
                    if w.EditActive and not w.AlwaysEdit then
                        H:EditBox_Cancel(w)
                        return true
                    end
                    return false
                end
            },
            {
                Key = Keys.VK_BACK,
                MSG = KeyEvents.KeyDown,
                Action = function(w)
                    if w.EditReadOnly or not w.EditActive then return false end
                    if w.EditSelStart then
                        local deleted = H:EditBox_DeleteSelection(w)
                        if deleted ~= "" then Speak(deleted, true) end
                    else
                        H:EditBox_BackspaceChar(w)
                    end
                    H:EditBox_SyncAndSpeak(w)
                    return true
                end
            },
            {
                Key = Keys.VK_BACK,
                MSG = KeyEvents.KeyDown,
                IsControl = true,
                Action = function(w)
                    if not w.EditActive or w.EditReadOnly then return false end
                    if w.EditSelStart then
                        local deleted = H:EditBox_DeleteSelection(w)
                        if deleted ~= "" then Speak(deleted, true) end
                    else
                        H:EditBox_BackspaceWord(w)
                    end
                    H:EditBox_SyncAndSpeak(w)
                    return true
                end
            },
            {
                Key = Keys.VK_DELETE,
                MSG = KeyEvents.KeyDown,
                Action = function(w)
                    if not w.EditActive or w.EditReadOnly then return false end
                    if w.EditSelStart then
                        local deleted = H:EditBox_DeleteSelection(w)
                        if deleted ~= "" then Speak(deleted, true) end
                    else
                        H:EditBox_DeleteChar(w)
                    end
                    H:EditBox_SyncAndSpeak(w)
                    return true
                end
            },
            {
                Key = Keys.VK_DELETE,
                MSG = KeyEvents.KeyDown,
                IsControl = true,
                Action = function(w)
                    if not w.EditActive or w.EditReadOnly then return false end
                    if w.EditSelStart then
                        local deleted = H:EditBox_DeleteSelection(w)
                        if deleted ~= "" then Speak(deleted, true) end
                    else
                        H:EditBox_DeleteWordForward(w)
                    end
                    H:EditBox_SyncAndSpeak(w)
                    return true
                end
            },
            {
                Key = Keys.VK_LEFT,
                MSG = KeyEvents.KeyDown,
                Action = function(w)
                    if not w.EditActive then return false end
                    H:EditBox_MoveCursor(w, -1, false, false)
                    return true
                end
            },
            {
                Key = Keys.VK_LEFT,
                MSG = KeyEvents.KeyDown,
                IsShift = true,
                Action = function(w)
                    if not w.EditActive then return false end
                    H:EditBox_MoveCursor(w, -1, true, false)
                    return true
                end
            },
            {
                Key = Keys.VK_LEFT,
                MSG = KeyEvents.KeyDown,
                IsControl = true,
                Action = function(w)
                    if not w.EditActive then return false end
                    H:EditBox_MoveCursor(w, -1, false, true)
                    return true
                end
            },
            {
                Key = Keys.VK_RIGHT,
                MSG = KeyEvents.KeyDown,
                Action = function(w)
                    if not w.EditActive then return false end
                    H:EditBox_MoveCursor(w, 1, false, false)
                    return true
                end
            },
            {
                Key = Keys.VK_RIGHT,
                MSG = KeyEvents.KeyDown,
                IsShift = true,
                Action = function(w)
                    if not w.EditActive then return false end
                    H:EditBox_MoveCursor(w, 1, true, false)
                    return true
                end
            },
            {
                Key = Keys.VK_RIGHT,
                MSG = KeyEvents.KeyDown,
                IsControl = true,
                Action = function(w)
                    if not w.EditActive then return false end
                    H:EditBox_MoveCursor(w, 1, false, true)
                    return true
                end
            },
            {
                Key = Keys.VK_HOME,
                MSG = KeyEvents.KeyDown,
                Action = function(w)
                    if not w.EditActive then return false end
                    local buf = w.EditBuffer or ""
                    local pos = w.EditCursor or 0
                    H:EditBox_MoveToEdge(w, H:EditBox_LineStart(buf, pos), false)
                    return true
                end
            },
            {
                Key = Keys.VK_HOME,
                MSG = KeyEvents.KeyDown,
                IsShift = true,
                Action = function(w)
                    if not w.EditActive then return false end
                    local buf = w.EditBuffer or ""
                    local pos = w.EditCursor or 0
                    H:EditBox_MoveToEdge(w, H:EditBox_LineStart(buf, pos), true)
                    return true
                end
            },
            {
                Key = Keys.VK_END,
                MSG = KeyEvents.KeyDown,
                Action = function(w)
                    if not w.EditActive then return false end
                    local buf = w.EditBuffer or ""
                    local pos = w.EditCursor or 0
                    H:EditBox_MoveToEdge(w, H:EditBox_LineEnd(buf, pos), false)
                    return true
                end
            },
            {
                Key = Keys.VK_END,
                MSG = KeyEvents.KeyDown,
                IsShift = true,
                Action = function(w)
                    if not w.EditActive then return false end
                    local buf = w.EditBuffer or ""
                    local pos = w.EditCursor or 0
                    H:EditBox_MoveToEdge(w, H:EditBox_LineEnd(buf, pos), true)
                    return true
                end
            },
            {
                Key = Keys.VK_UP,
                MSG = KeyEvents.KeyDown,
                Action = function(w)
                    if not w.EditActive then return false end
                    local buf = w.EditBuffer or ""
                    local pos = w.EditCursor or 0
                    local newPos = H:EditBox_PrevLinePos(buf, pos)
                    if not newPos then
                        H:SpeakLine(buf, pos)
                        return true
                    end
                    w.EditSelStart = nil
                    w.EditCursor = newPos
                    H:SpeakLine(buf, newPos)
                    return true
                end
            },
            {
                Key = Keys.VK_DOWN,
                MSG = KeyEvents.KeyDown,
                Action = function(w)
                    if not w.EditActive then return false end
                    local buf = w.EditBuffer or ""
                    local pos = w.EditCursor or 0
                    local newPos = H:EditBox_NextLinePos(buf, pos)
                    if not newPos then
                        H:SpeakLine(buf, pos)
                        return true
                    end
                    w.EditSelStart = nil
                    w.EditCursor = newPos
                    H:SpeakLine(buf, newPos)
                    return true
                end
            },
            {
                Key = Keys.VK_UP,
                MSG = KeyEvents.KeyDown,
                IsShift = true,
                Action = function(w)
                    if not w.EditActive then return false end
                    local buf = w.EditBuffer or ""
                    local oldSelStart = w.EditSelStart
                    local oldCursor = w.EditCursor or 0
                    local newPos = H:EditBox_PrevLinePos(buf, oldCursor)
                    if not newPos then return true end
                    if not w.EditSelStart then w.EditSelStart = oldCursor end
                    w.EditCursor = newPos
                    H:SpeakSelectionChange(w, oldSelStart, oldCursor)
                    return true
                end
            },
            {
                Key = Keys.VK_DOWN,
                MSG = KeyEvents.KeyDown,
                IsShift = true,
                Action = function(w)
                    if not w.EditActive then return false end
                    local buf = w.EditBuffer or ""
                    local oldSelStart = w.EditSelStart
                    local oldCursor = w.EditCursor or 0
                    local newPos = H:EditBox_NextLinePos(buf, oldCursor)
                    if not newPos then return true end
                    if not w.EditSelStart then w.EditSelStart = oldCursor end
                    w.EditCursor = newPos
                    H:SpeakSelectionChange(w, oldSelStart, oldCursor)
                    return true
                end
            },
            {
                Key = Keys.VK_HOME,
                MSG = KeyEvents.KeyDown,
                IsControl = true,
                Action = function(w)
                    if not w.EditActive then return false end
                    w.EditCursor = 0
                    w.EditSelStart = nil
                    H:SpeakLine(w.EditBuffer or "", 0)
                    return true
                end
            },
            {
                Key = Keys.VK_END,
                MSG = KeyEvents.KeyDown,
                IsControl = true,
                Action = function(w)
                    if not w.EditActive then return false end
                    local buf = w.EditBuffer or ""
                    w.EditCursor = #buf
                    w.EditSelStart = nil
                    H:SpeakLine(buf, #buf)
                    return true
                end
            },
            {
                Key = Keys.VK_HOME,
                MSG = KeyEvents.KeyDown,
                IsControl = true,
                IsShift = true,
                Action = function(w)
                    if not w.EditActive then return false end
                    H:EditBox_MoveToEdge(w, 0, true)
                    return true
                end
            },
            {
                Key = Keys.VK_END,
                MSG = KeyEvents.KeyDown,
                IsControl = true,
                IsShift = true,
                Action = function(w)
                    if not w.EditActive then return false end
                    local len = w.EditBuffer and #w.EditBuffer or 0
                    H:EditBox_MoveToEdge(w, len, true)
                    return true
                end
            },
            {
                Key = Keys.C,
                MSG = KeyEvents.KeyDown,
                IsControl = true,
                Action = function(w)
                    if not w.EditActive then return false end
                    local sel = H:EditBox_GetSelectedText(w)
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
                end
            },
            {
                Key = Keys.V,
                MSG = KeyEvents.KeyDown,
                IsControl = true,
                Action = function(w)
                    if not w.EditActive or w.EditReadOnly then return false end
                    local text = CAI.GetClipboardText()
                    if text and text ~= "" then
                        H:EditBox_InsertText(w, text)
                        H:EditBox_SyncAndSpeak(w)
                        Speak(Locale.Lookup("LOC_CAI_EDIT_PASTED", text), true)
                    end
                    return true
                end
            },
            {
                Key = Keys.A,
                MSG = KeyEvents.KeyDown,
                IsControl = true,
                Action = function(w)
                    if not w.EditActive then return false end
                    H:EditBox_SelectAll(w)
                    return true
                end
            },
            {
                Key = Keys.VK_LEFT,
                MSG = KeyEvents.KeyDown,
                IsControl = true,
                IsShift = true,
                Action = function(w)
                    if not w.EditActive then return false end
                    H:EditBox_MoveCursor(w, -1, true, true)
                    return true
                end
            },
            {
                Key = Keys.VK_RIGHT,
                MSG = KeyEvents.KeyDown,
                IsControl = true,
                IsShift = true,
                Action = function(w)
                    if not w.EditActive then return false end
                    H:EditBox_MoveCursor(w, 1, true, true)
                    return true
                end
            },
        },
        OnCharInput = function(w, char)
            if not w.EditActive or w.EditReadOnly then return false end
            H:EditBox_InsertText(w, char)
            H:EditBox_SyncAndSpeak(w)
            Speak(char, true)
            return true
        end,
        GetDefaultChild = nil,
        OnFocusEnter = function(w) if w.AlwaysEdit and not w.EditActive then H:EditBox_Activate(w) end end
    },
    Dialog = {
        Role = "Dialog",
        DefaultIndex = 1,
        WrapAround = true,
        RegisterInputs = {
            { Key = Keys.VK_TAB, MSG = KeyEvents.KeyDown, Action = function(w) return w:Navigate(1) end },
            {
                Key = Keys.VK_TAB,
                MSG = KeyEvents.KeyDown,
                IsShift = true,
                Action = function(
                    w)
                    return w:Navigate(-1)
                end
            },
        },
        Navigate = function(w, dir) return H:NavigateSimpleList(w, dir) end,
        GetDefaultChild = function(w) return H:GetContainerDefChild(w) end
    },
    Tab = {
        Role = "Tab",
    },
    TabBar = {
        Role = "TabBar",
        DefaultIndex = 1,
        WrapAround = true,
        IsExpanded = true,
        RegisterInputs = {
            { Key = Keys.VK_LEFT,  MSG = KeyEvents.KeyDown, Action = function(w) return w:Navigate(-1) end },
            { Key = Keys.VK_RIGHT, MSG = KeyEvents.KeyDown, Action = function(w) return w:Navigate(1) end },
            { Key = Keys.VK_HOME,  MSG = KeyEvents.KeyDown, Action = function(w) return H:NavigateToFirst(w) end },
            { Key = Keys.VK_END,   MSG = KeyEvents.KeyDown, Action = function(w) return H:NavigateToLast(w) end },
        },
        Navigate = function(w, dir) return H:NavigateSimpleList(w, dir) end,
        GetDefaultChild = function(w) return H:GetContainerDefChild(w) end
    },
    MenuItem = {
        Role = "MenuItem",
        SpeechSettings = { Role = false },
        RegisterInputs = {
            {
                Key = Keys.VK_RETURN,
                Action = function(w)
                    if w.OnClick then w:OnClick() end
                    return true
                end
            },
        },
    },
    StaticText = {
        Role = "StaticText",
        SpeechSettings = { Role = false },
        RegisterInputs = {
            {
                Key = Keys.VK_RETURN,
                Action = function(w)
                    if w.Children and #w.Children > 0 and not w.FocusedChild then
                        local edit = w.Children[1]
                        if w.GetValue then
                            edit.GetValue = w.GetValue
                        end
                        w.Manager:SetFocus(w.Children[1])
                        return true
                    end
                    return false
                end,
                IsAlt = true
            },
            {
                Key = Keys.VK_ESCAPE,
                Action = function(w)
                    if w.FocusedChild then
                        w.Manager:SetFocus(w)
                        w.FocusedChild = nil
                        return true
                    end
                    return false
                end
            }
        },
        OnCreate = function(w)
            local edit = w.Manager:CreateUIWidget(w.Manager:GenerateWidgetId("CAIwidgetTemplatesEdit"), "Edit")
            edit.AlwaysEdit = true
            edit.EditReadOnly = true
            edit.HighlightOnEdit = false
            w:AddChild(edit)
        end,
        OnFocusLeave = function(w) if w.FocusedChild then w.FocusedChild = nil end end
    },
    GameView = {
        GetLabel = function() return Locale.Lookup("LOC_CAI_ROLE_GAME_VIEW") end,
        GetDefaultChild = function(w) return H:GetContainerDefChild(w) end,
        OnFocusEnter = function(w)
            Input.SetActiveContext(InputContext.World)
        end,
        OnFocusLeave = function(w)
            Input.SetActiveContext(InputContext.GameOptions)
        end,
    },
    InterfaceMode = {
        AnnounceRole = false,
    },

    -- =======================================================================
    -- Treeview: container that owns flat navigation and generic node
    -- expand/collapse for the whole visible tree of TreeviewItems. Screens can
    -- still attach item activation bindings and react to expansion with
    -- OnToggleExpanded.
    -- =======================================================================
    Treeview = {
        Role = "Treeview",
        WrapAround = false,
        SearchDepth = 3,
        RegisterInputs = {
            {
                Key = Keys.VK_UP,
                MSG = KeyEvents.KeyDown,
                Action = function(w)
                    return
                        H:NavigateTreeFlat(w, -1)
                end
            },
            {
                Key = Keys.VK_DOWN,
                MSG = KeyEvents.KeyDown,
                Action = function(w)
                    return
                        H:NavigateTreeFlat(w, 1)
                end
            },
            {
                Key = Keys.VK_RIGHT,
                MSG = KeyEvents.KeyDown,
                Action = function(w)
                    return
                        H:ExpandOrDescendTree(w)
                end
            },
            {
                Key = Keys.VK_LEFT,
                MSG = KeyEvents.KeyDown,
                Action = function(w)
                    return
                        H:CollapseOrAscendTree(w)
                end
            },
            { Key = Keys.VK_RETURN, Action = function(w) return H:ToggleFocusedTreeItem(w) end },
            {
                Key = Keys.VK_HOME,
                MSG = KeyEvents.KeyDown,
                Action = function(w)
                    return
                        H:NavigateTreeFirst(w)
                end
            },
            {
                Key = Keys.VK_END,
                MSG = KeyEvents.KeyDown,
                Action = function(w)
                    return
                        H:NavigateTreeLast(w)
                end
            },
        },
        Navigate = function(w, dir) return H:NavigateTreeFlat(w, dir) end,
        GetDefaultChild = function(w) return H:GetContainerDefChild(w) end,
        OnCharInput = function(w, char)
            local mgr = w.Manager
            mgr:AppendSearchChar(char)
            local query = mgr.SearchBuffer
            local maxDepth = w.SearchDepth or 3
            local match = H:FindNextMatch(w, query, maxDepth)
            if match then
                mgr:SetFocus(match)
                return true
            end
            Speak(Locale.Lookup("LOC_CAI_SEARCH_NO_MATCH"))
            return false
        end
    },

    -- =======================================================================
    -- TreeviewItem: leaf or node. Expansion state is exposed as value so focus
    -- and SetValue announcements say whether a node is expanded/collapsed.
    -- =======================================================================
    TreeviewItem = {
        Role = "TreeviewItem",
        IsExpanded = false,
        SpeechSettings = {
            Role = false,
            IgnoreWhenNotFocused = true
        },
        IsLeaf = function(w)
            return not w.Children or #w.Children == 0
        end,
        GetValue = function(w)
            if w:IsLeaf() then return "" end
            if w.IsExpanded then
                local childCount = #(w:GetVisibleChildren())
                return Locale.Lookup("LOC_CAI_TREEVIEW_EXPANDED") .. ", "
                    .. Locale.Lookup("LOC_CAI_TREEVIEW_ITEM_COUNT", childCount)
            end
            return Locale.Lookup("LOC_CAI_TREEVIEW_COLLAPSED")
        end,
        Expand = function(w)
            if w.IsExpanded then return false end
            if not w.Children or #w.Children == 0 then return false end
            w.IsExpanded = true
            if w.OnToggleExpanded then w:OnToggleExpanded(true) end
            w:SetValue(w.GetValue and w:GetValue() or "")
            return true
        end,
        Collapse = function(w)
            if not w.IsExpanded then return false end
            w.IsExpanded = false
            w.FocusedChild = nil
            if w.OnToggleExpanded then w:OnToggleExpanded(false) end
            w:SetValue(w.GetValue and w:GetValue() or "")
            return true
        end,
        GetDefaultChild = function(w)
            if w.IsExpanded and w.FocusedChild then return w.FocusedChild end
            return nil
        end,
    },
}
