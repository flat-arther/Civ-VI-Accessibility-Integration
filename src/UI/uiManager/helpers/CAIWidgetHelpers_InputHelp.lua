-- CAIWidgetHelpers_InputHelp.lua
-- Input help overlay: collects described bindings from the focused widget
-- up through the root, grouped by non-transparent widget, and presents
-- them in a treeview. Enter on a binding activates its action.

CAIWidgetHelpers_InputHelp = {}
local H = CAIWidgetHelpers_InputHelp

local g_helpOpen = false

--#region Key display names

local KEY_NAMES = {
    -- Letters
    [Keys.A] = "LOC_OPTIONS_KEY_A",
    [Keys.B] = "LOC_OPTIONS_KEY_B",
    [Keys.C] = "LOC_OPTIONS_KEY_C",
    [Keys.D] = "LOC_OPTIONS_KEY_D",
    [Keys.E] = "LOC_OPTIONS_KEY_E",
    [Keys.F] = "LOC_OPTIONS_KEY_F",
    [Keys.G] = "LOC_OPTIONS_KEY_G",
    [Keys.H] = "LOC_OPTIONS_KEY_H",
    [Keys.I] = "LOC_OPTIONS_KEY_I",
    [Keys.J] = "LOC_OPTIONS_KEY_J",
    [Keys.K] = "LOC_OPTIONS_KEY_K",
    [Keys.L] = "LOC_OPTIONS_KEY_L",
    [Keys.M] = "LOC_OPTIONS_KEY_M",
    [Keys.N] = "LOC_OPTIONS_KEY_N",
    [Keys.O] = "LOC_OPTIONS_KEY_O",
    [Keys.P] = "LOC_OPTIONS_KEY_P",
    [Keys.Q] = "LOC_OPTIONS_KEY_Q",
    [Keys.R] = "LOC_OPTIONS_KEY_R",
    [Keys.S] = "LOC_OPTIONS_KEY_S",
    [Keys.T] = "LOC_OPTIONS_KEY_T",
    [Keys.U] = "LOC_OPTIONS_KEY_U",
    [Keys.V] = "LOC_OPTIONS_KEY_V",
    [Keys.W] = "LOC_OPTIONS_KEY_W",
    [Keys.X] = "LOC_OPTIONS_KEY_X",
    [Keys.Y] = "LOC_OPTIONS_KEY_Y",
    [Keys.Z] = "LOC_OPTIONS_KEY_Z",

    -- Number row
    [Keys["0"]] = "LOC_OPTIONS_KEY_0",
    [Keys["1"]] = "LOC_OPTIONS_KEY_1",
    [Keys["2"]] = "LOC_OPTIONS_KEY_2",
    [Keys["3"]] = "LOC_OPTIONS_KEY_3",
    [Keys["4"]] = "LOC_OPTIONS_KEY_4",
    [Keys["5"]] = "LOC_OPTIONS_KEY_5",
    [Keys["6"]] = "LOC_OPTIONS_KEY_6",
    [Keys["7"]] = "LOC_OPTIONS_KEY_7",
    [Keys["8"]] = "LOC_OPTIONS_KEY_8",
    [Keys["9"]] = "LOC_OPTIONS_KEY_9",

    -- Numpad
    [Keys.VK_NUMPAD0] = "LOC_OPTIONS_KEY_NP_0",
    [Keys.VK_NUMPAD1] = "LOC_OPTIONS_KEY_NP_1",
    [Keys.VK_NUMPAD2] = "LOC_OPTIONS_KEY_NP_2",
    [Keys.VK_NUMPAD3] = "LOC_OPTIONS_KEY_NP_3",
    [Keys.VK_NUMPAD4] = "LOC_OPTIONS_KEY_NP_4",
    [Keys.VK_NUMPAD5] = "LOC_OPTIONS_KEY_NP_5",
    [Keys.VK_NUMPAD6] = "LOC_OPTIONS_KEY_NP_6",
    [Keys.VK_NUMPAD7] = "LOC_OPTIONS_KEY_NP_7",
    [Keys.VK_NUMPAD8] = "LOC_OPTIONS_KEY_NP_8",
    [Keys.VK_NUMPAD9] = "LOC_OPTIONS_KEY_NP_9",
    [Keys.VK_MULTIPLY] = "LOC_OPTIONS_KEY_NP_MULTIPLY",
    [Keys.VK_ADD] = "LOC_OPTIONS_KEY_NP_PLUS",
    [Keys.VK_SUBTRACT] = "LOC_OPTIONS_KEY_NP_MINUS",
    [Keys.VK_DECIMAL] = "LOC_OPTIONS_KEY_NP_DECIMAL",
    [Keys.VK_DIVIDE] = "LOC_OPTIONS_KEY_NP_DIVIDE",

    -- Function keys
    [Keys.VK_F1] = "LOC_OPTIONS_KEY_F1",
    [Keys.VK_F2] = "LOC_OPTIONS_KEY_F2",
    [Keys.VK_F3] = "LOC_OPTIONS_KEY_F3",
    [Keys.VK_F4] = "LOC_OPTIONS_KEY_F4",
    [Keys.VK_F5] = "LOC_OPTIONS_KEY_F5",
    [Keys.VK_F6] = "LOC_OPTIONS_KEY_F6",
    [Keys.VK_F7] = "LOC_OPTIONS_KEY_F7",
    [Keys.VK_F8] = "LOC_OPTIONS_KEY_F8",
    [Keys.VK_F9] = "LOC_OPTIONS_KEY_F9",
    [Keys.VK_F10] = "LOC_OPTIONS_KEY_F10",
    [Keys.VK_F11] = "LOC_OPTIONS_KEY_F11",
    [Keys.VK_F12] = "LOC_OPTIONS_KEY_F12",
    [Keys.VK_F13] = "LOC_OPTIONS_KEY_F13",
    [Keys.VK_F14] = "LOC_OPTIONS_KEY_F14",
    [Keys.VK_F15] = "LOC_OPTIONS_KEY_F15",
    [Keys.VK_F16] = "LOC_OPTIONS_KEY_F16",
    [Keys.VK_F17] = "LOC_OPTIONS_KEY_F17",
    [Keys.VK_F18] = "LOC_OPTIONS_KEY_F18",
    [Keys.VK_F19] = "LOC_OPTIONS_KEY_F19",
    [Keys.VK_F20] = "LOC_OPTIONS_KEY_F20",
    [Keys.VK_F21] = "LOC_OPTIONS_KEY_F21",
    [Keys.VK_F22] = "LOC_OPTIONS_KEY_F22",
    [Keys.VK_F23] = "LOC_OPTIONS_KEY_F23",
    [Keys.VK_F24] = "LOC_OPTIONS_KEY_F24",

    -- Navigation
    [Keys.VK_INSERT] = "LOC_OPTIONS_KEY_INSERT",
    [Keys.VK_HOME] = "LOC_OPTIONS_KEY_HOME",
    [Keys.VK_PRIOR] = "LOC_OPTIONS_KEY_PAGEUP",
    [Keys.VK_DELETE] = "LOC_OPTIONS_KEY_DELETE",
    [Keys.VK_END] = "LOC_OPTIONS_KEY_END",
    [Keys.VK_NEXT] = "LOC_OPTIONS_KEY_PAGEDOWN",

    -- Arrows
    [Keys.VK_LEFT] = "LOC_OPTIONS_KEY_LEFT",
    [Keys.VK_UP] = "LOC_OPTIONS_KEY_UP",
    [Keys.VK_RIGHT] = "LOC_OPTIONS_KEY_RIGHT",
    [Keys.VK_DOWN] = "LOC_OPTIONS_KEY_DOWN",

    -- Punctuation
    [Keys.VK_OEM_1] = "LOC_OPTIONS_KEY_SEMICOLON",
    [Keys.VK_OEM_PLUS] = "LOC_OPTIONS_KEY_PLUS",
    [Keys.VK_OEM_COMMA] = "LOC_OPTIONS_KEY_COMMA",
    [Keys.VK_OEM_MINUS] = "LOC_OPTIONS_KEY_MINUS",
    [Keys.VK_OEM_PERIOD] = "LOC_OPTIONS_KEY_PERIOD",
    [Keys.VK_OEM_2] = "LOC_OPTIONS_KEY_SLASH",
    [Keys.VK_OEM_3] = "LOC_OPTIONS_KEY_TILDE",
    [Keys.VK_OEM_4] = "LOC_OPTIONS_KEY_LBRACKET",
    [Keys.VK_OEM_5] = "LOC_OPTIONS_KEY_BACKSLASH",
    [Keys.VK_OEM_6] = "LOC_OPTIONS_KEY_RBRACKET",
    [Keys.VK_OEM_7] = "LOC_OPTIONS_KEY_QUOTE",

    -- Misc
    [Keys.VK_SNAPSHOT] = "LOC_OPTIONS_KEY_PRINTSCREEN",
    [Keys.VK_PAUSE] = "LOC_OPTIONS_KEY_PAUSE",
    [Keys.VK_SPACE] = "LOC_OPTIONS_KEY_SPACE",
    [Keys.VK_TAB] = "LOC_OPTIONS_KEY_TAB",
    [Keys.VK_RETURN] = "LOC_OPTIONS_KEY_RETURN",
    [Keys.VK_ESCAPE] = "LOC_OPTIONS_KEY_ESCAPE",
    [Keys.VK_BACK] = "LOC_OPTIONS_KEY_BACKSPACE",

    -- Modifiers
    [Keys.VK_SHIFT] = "LOC_OPTIONS_KEY_SHIFT",
    [Keys.VK_CONTROL] = "LOC_OPTIONS_KEY_CONTROL",
    [Keys.VK_ALT] = "LOC_OPTIONS_KEY_ALT",

    [Keys.VK_LSHIFT] = "LOC_OPTIONS_KEY_LSHIFT",
    [Keys.VK_RSHIFT] = "LOC_OPTIONS_KEY_RSHIFT",
    [Keys.VK_LCONTROL] = "LOC_OPTIONS_KEY_LCONTROL",
    [Keys.VK_RCONTROL] = "LOC_OPTIONS_KEY_RCONTROL",
    [Keys.VK_LMENU] = "LOC_OPTIONS_KEY_LALT",
    [Keys.VK_RMENU] = "LOC_OPTIONS_KEY_RALT",

    -- Locks
    [Keys.VK_CAPITAL] = "LOC_OPTIONS_KEY_CAPSLOCK",
    [Keys.VK_NUMLOCK] = "LOC_OPTIONS_KEY_NUMLOCK",
    [Keys.VK_SCROLL] = "LOC_OPTIONS_KEY_SCROLLLOCK",

    -- Windows keys
    [Keys.VK_LWIN] = "LOC_OPTIONS_KEY_LWIN",
    [Keys.VK_RWIN] = "LOC_OPTIONS_KEY_RWIN",
    [Keys.VK_APPS] = "LOC_OPTIONS_KEY_APPS",

    -- Gamepad
    [Keys.PAD_A] = "LOC_OPTIONS_PAD_A",
    [Keys.PAD_B] = "LOC_OPTIONS_PAD_B",
    [Keys.PAD_X] = "LOC_OPTIONS_PAD_X",
    [Keys.PAD_Y] = "LOC_OPTIONS_PAD_Y",

    [Keys.PAD_LSHOULDER] = "LOC_OPTIONS_PAD_LSHOULDER",
    [Keys.PAD_RSHOULDER] = "LOC_OPTIONS_PAD_RSHOULDER",
    [Keys.PAD_LTRIGGER] = "LOC_OPTIONS_PAD_LTRIGGER",
    [Keys.PAD_RTRIGGER] = "LOC_OPTIONS_PAD_RTRIGGER",

    [Keys.PAD_UP] = "LOC_OPTIONS_PAD_DPAD_UP",
    [Keys.PAD_DOWN] = "LOC_OPTIONS_PAD_DPAD_DOWN",
    [Keys.PAD_LEFT] = "LOC_OPTIONS_PAD_DPAD_LEFT",
    [Keys.PAD_RIGHT] = "LOC_OPTIONS_PAD_DPAD_RIGHT",

    [Keys.PAD_START] = "LOC_OPTIONS_PAD_START",
    [Keys.PAD_BACK] = "LOC_OPTIONS_PAD_BACK",

    [Keys.PAD_LTHUMB_PRESS] = "LOC_OPTIONS_PAD_LTHUMB_PRESS",
    [Keys.PAD_RTHUMB_PRESS] = "LOC_OPTIONS_PAD_RTHUMB_PRESS",

    [Keys.PAD_STICK_LEFT] = "LOC_OPTIONS_PAD_LTHUMB_AXIS",
    [Keys.PAD_STICK_RIGHT] = "LOC_OPTIONS_PAD_RTHUMB_AXIS",

    [Keys.PAD_TOOLTIP_REFRESH] = "LOC_OPTIONS_PAD_TOOLTIP_REFRESH",

    -- Media keys
    [Keys.VK_VOLUME_MUTE] = "LOC_OPTIONS_KEY_VOLUME_MUTE",
    [Keys.VK_VOLUME_DOWN] = "LOC_OPTIONS_KEY_VOLUME_DOWN",
    [Keys.VK_VOLUME_UP] = "LOC_OPTIONS_KEY_VOLUME_UP",

    [Keys.VK_MEDIA_NEXT_TRACK] = "LOC_OPTIONS_KEY_MEDIA_NEXT_TRACK",
    [Keys.VK_MEDIA_PREV_TRACK] = "LOC_OPTIONS_KEY_MEDIA_PREV_TRACK",
    [Keys.VK_MEDIA_STOP] = "LOC_OPTIONS_KEY_MEDIA_STOP",
    [Keys.VK_MEDIA_PLAY_PAUSE] = "LOC_OPTIONS_KEY_MEDIA_PLAY_PAUSE",
}

local function GetKeyDisplayName(keyCode)
    local name = KEY_NAMES[keyCode]
    if not name then return "?" end
    return Locale.Lookup(name)
end

local function FormatBinding(binding)
    local parts = {}
    if binding.IsControl then parts[#parts + 1] = Locale.Lookup(KEY_NAMES[Keys.VK_CONTROL]) end
    if binding.IsShift then parts[#parts + 1] = Locale.Lookup(KEY_NAMES[Keys.VK_SHIFT]) end
    if binding.IsAlt then parts[#parts + 1] = Locale.Lookup(KEY_NAMES[Keys.VK_ALT]) end
    parts[#parts + 1] = GetKeyDisplayName(binding.Key)
    return table.concat(parts, "+")
end

--#endregion

--#region Input action collection

local VANILLA_CATEGORIES = {
    ["LOC_OPTIONS_HOTKEY_CATEGORY_UI"] = true,
    ["LOC_OPTIONS_HOTKEY_CATEGORY_UNIT"] = true,
    ["LOC_OPTIONS_HOTKEY_CATEGORY_GLOBAL"] = true,
    ["LOC_OPTIONS_HOTKEY_CATEGORY_ONLINE"] = true,
    ["LOC_OPTIONS_HOTKEY_CATEGORY_LENSES"] = true,
    ["LOC_OPTIONS_HOTKEY_CATEGORY_UI_XP1"] = true,
    ["LOC_OPTIONS_HOTKEY_CATEGORY_UI_XP2"] = true,
}

local function CollectInputActions()
    local actions = {}
    local count = Input.GetActionCount()
    for i = 0, count - 1 do
        local action = Input.GetActionId(i)
        if Input.ShouldShowActionKeybinding(action) and not VANILLA_CATEGORIES[Input.GetActionCategory(action)] then
            local g1 = Input.GetGestureDisplayString(action, 0)
            local g2 = Input.GetGestureDisplayString(action, 1)
            local keys = {}
            if g1 and g1 ~= "" then keys[#keys + 1] = g1 end
            if g2 and g2 ~= "" then keys[#keys + 1] = g2 end
            if #keys > 0 then
                table.insert(actions, {
                    id       = action,
                    name     = Locale.Lookup(Input.GetActionName(action)),
                    category = Locale.Lookup(Input.GetActionCategory(action)),
                    keyCombo = table.concat(keys, ", "),
                })
            end
        end
    end
    table.sort(actions, function(a, b)
        local r = Locale.Compare(a.category, b.category)
        if r == 0 then return Locale.Compare(a.name, b.name) == -1 end
        return r == -1
    end)
    return actions
end

--#endregion

--#region Binding collection

local function GetWidgetLabel(widget)
    local label
    if widget.GetLabel then
        label = widget:GetLabel()
    end
    local role = Locale.Lookup("LOC_UIWidget_Role_" .. widget.Role or widget.Type)
    return label .. ", " .. role
end

local function MergeBindings(bindings)
    local merged = {}
    local descIndex = {}
    for _, entry in ipairs(bindings) do
        local existing = descIndex[entry.description]
        if existing then
            local dominated = false
            for part in existing.keyCombo:gmatch("[^,]+") do
                if part:match("^%s*(.-)%s*$") == entry.keyCombo then
                    dominated = true
                    break
                end
            end
            if not dominated then
                existing.keyCombo = existing.keyCombo .. ", " .. entry.keyCombo
            end
        else
            local copy = {
                description = entry.description,
                keyCombo = entry.keyCombo,
                action = entry.action,
                owner = entry.owner,
            }
            merged[#merged + 1] = copy
            descIndex[entry.description] = copy
        end
    end
    return merged
end

local function CollectBindings(widget)
    local groups = {}
    local commonBindings = {}
    local w = widget
    while w do
        if not w.TrapInput then
            local described = {}
            for _, b in ipairs(w.InputMap) do
                if b.Description and b.Action then
                    local entry = {
                        description = Locale.Lookup(b.Description),
                        keyCombo = FormatBinding(b),
                        action = b.Action,
                        owner = w,
                    }
                    if b.Common then
                        commonBindings[#commonBindings + 1] = entry
                    else
                        described[#described + 1] = entry
                    end
                end
            end
            described = MergeBindings(described)
            if #described > 0 then
                groups[#groups + 1] = {
                    label = GetWidgetLabel(w),
                    bindings = described,
                }
            end
        end
        w = w.Parent
    end
    commonBindings = MergeBindings(commonBindings)
    return groups, commonBindings
end

--#endregion

--#region Public API

function H.RunHelp(widget)
    if g_helpOpen then return false end
    local mgr = widget.Manager
    if not mgr then return false end

    local groups, commonBindings = CollectBindings(widget)
    local inputActions = {}
    if Input.GetActiveContext() == InputContext.World then
        inputActions = CollectInputActions()
    end
    if #groups == 0 and #commonBindings == 0 and #inputActions == 0 then
        Speak(Locale.Lookup("LOC_CAI_INPUT_HELP_NONE"))
        return true
    end

    local root = mgr:GetTop()
    local previousFocus = mgr:GetFocusedWidget()

    g_helpOpen = true

    local panelId = mgr:GenerateWidgetId("CAI_InputHelp")
    local panel = mgr:CreateWidget(panelId, "Panel", {
        Transparent = true,
        WrapAround = true,
        TrapInput = true
    })
    panel:On("focus_enter", function() Input.SetActiveContext(InputContext.Shell) end)
    local tree = mgr:CreateWidget(panelId .. "_Tree", "Tree", {
        Label = function() return Locale.Lookup("LOC_CAI_INPUT_HELP_TITLE") end,
    })

    local function CloseHelp()
        g_helpOpen = false
        panel:Destroy()
        if previousFocus then mgr:SetFocus(previousFocus) end
    end

    local function MakeBindingItem(entry)
        local itemId = mgr:GenerateWidgetId("CAI_InputHelpItem")
        local item = mgr:CreateWidget(itemId, "TreeItem", {
            Label = entry.description .. ": " .. entry.keyCombo,
        })
        local capturedAction = entry.action
        local capturedOwner = entry.owner
        item:On("activate", function()
            CloseHelp()
            capturedAction(capturedOwner)
        end)
        return item
    end

    local catNode, catKey
    local catNodes = {}
    for _, info in ipairs(inputActions) do
        if info.category ~= catKey then
            catKey = info.category
            catNode = mgr:CreateWidget(mgr:GenerateWidgetId("CAI_InputHelpCat"), "TreeItem", {
                Label = info.category,
            })
            catNodes[#catNodes + 1] = catNode
            tree:AddChild(catNode)
        end
        local actionId = info.id
        local itemId = mgr:GenerateWidgetId("CAI_InputHelpAction")
        local item = mgr:CreateWidget(itemId, "StaticText", {
            Label = info.name .. ": " .. info.keyCombo,
            Tooltip = function() return Locale.Lookup(Input.GetActionDescription(actionId)) or "" end,
        })
        catNode:AddChild(item)
    end
    for _, node in ipairs(catNodes) do
        node:Expand(true)
    end

    local uiCategory = mgr:CreateWidget(panelId .. "_UI", "TreeItem", {
        Label = function() return Locale.Lookup("LOC_CAI_INPUT_HELP_UI_CATEGORY") end,
    })

    for _, entry in ipairs(commonBindings) do
        uiCategory:AddChild(MakeBindingItem(entry))
    end

    for _, group in ipairs(groups) do
        local groupItem = mgr:CreateWidget(mgr:GenerateWidgetId("CAI_InputHelpGroup"), "TreeItem", {
            Label = group.label,
        })
        for _, entry in ipairs(group.bindings) do
            groupItem:AddChild(MakeBindingItem(entry))
        end
        groupItem:Expand(true)
        uiCategory:AddChild(groupItem)
    end

    uiCategory:Expand(true)
    tree:AddChild(uiCategory)

    panel:AddChild(tree)
    panel:AddInputBindings({ {
        Key = Keys.VK_ESCAPE,
        Description = "LOC_CAI_KB_CLOSE",
        Action = function()
            CloseHelp()
            return true
        end,
    },
    })

    root:AddChild(panel)
    mgr:SetFocus(tree)
    return true
end

--#endregion
