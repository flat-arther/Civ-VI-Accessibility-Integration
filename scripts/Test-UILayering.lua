-- Production adapters/widgets with mocked native lifecycle and controls.
local Trade = dofile("scripts/test-support/TradeHarness.lua")
local count = 0
local function check(value, message)
    count = count + 1
    assert(value, message)
end
local function isFocused(mgr, widget)
    for _, node in ipairs(mgr.CurrentPath) do
        if node == widget then return true end
    end
    return false
end

for _, bts in ipairs({ false, true }) do
    for _, kind in ipairs({ "Origin", "Route", "Overview" }) do
        for _, popupFirst in ipairs({ false, true }) do
            local mgr, state = Trade.Create(kind, bts)
            local world = mgr:CreateWidget("world", "Panel", { Label = "World" })
            mgr:Push(world, { priority = 99 })
            local popup = mgr:CreateWidget("popup", "Panel", { Label = "Popup" })
            local popupInput = 0
            popup:AddInputBinding({ Key = Keys.Z, Action = function()
                popupInput = popupInput + 1
                return true
            end })
            if popupFirst then mgr:Push(popup, { priority = PopupPriority.Low }) end
            Open()
            local prefix = kind == "Overview" and "CAITradeOv" or "CAITrade" .. kind
            local panel = assert(mgr:GetWidgetById(prefix .. "_Panel"))
            check(panel.__priority == 99, "native trade panel has explicit non-popup priority")
            if not popupFirst then mgr:Push(popup, { priority = PopupPriority.Low }) end
            check(mgr:GetTop() == popup and mgr.CurrentPath[1] == popup,
                "Low popup retains top and focus in either arrival order")
            check(state.input(Trade.Key(Keys.Z)) and popupInput == 1,
                "screen input bridge routes to the focused popup")
            mgr:RemoveFromStack("popup")
            check(mgr:GetTop() == panel and mgr.CurrentPath[1] == panel,
                "popup close restores the underlying screen")
            -- CAI-only transient views keep their existing inheritance behavior.
            local childView = mgr:CreateWidget("transient", "Panel", { Label = "Transient" })
            mgr:Push(childView)
            check(childView.__priority == 99 and mgr:GetTop() == childView,
                "CAI-only view inherits the screen's new priority")
        end
    end
end

local Harness = dofile("scripts/test-support/WidgetHarness.lua")
for _, spec in ipairs({
    { "MapSelect", "setup:map-picker" },
    { "LeaderPicker", "setup:leader-picker" },
    { "CityStatePicker", "setup:city-state-picker" },
    { "MultiSelectWindow", "setup:multi-picker" },
}) do
    local mgr = Harness.CreateManager()
    local owner = mgr:CreateWidget("setup", "Panel", { Label = "Setup" })
    local opener = mgr:CreateWidget("opener", "Button", { Label = "Open picker" })
    owner:AddChild(opener)
    mgr:Push(owner, { priority = PopupPriority.Current, focus = opener })
    local escapedToOwner = 0
    owner:AddInputBinding({ Key = Keys.Z, Action = function()
        escapedToOwner = escapedToOwner + 1
        return true
    end })
    local shown, hidden, input
    local control = {
        GetText = function() return "Native control" end,
        GetToolTipString = function() return "" end,
        IsDisabled = function() return false end,
        GetButton = function(self) return self end,
    }
    local noop = function() end
    local env = setmetatable({
        Controls = setmetatable({}, { __index = function() return control end }),
        UI = { PlaySound = noop },
        ContextPtr = {
            SetShowHandler = function(_, fn) shown = fn end,
            SetHideHandler = function(_, fn) hidden = fn end,
            SetInputHandler = function(_, fn) input = fn end,
        },
        Close = function() hidden() end,
        ParameterInitialize = noop, RefreshList = noop, RefreshCountWarning = noop,
        SelectLeadersWithNoWins = noop, SetAllItems = noop,
        LoadMaps = noop, PopulateMapSelectPanel = noop,
        m_kAllMaps = {}, m_sortType = 0,
    }, { __index = _G })
    local path = "src/UI/frontEnd/" .. spec[1] .. ".lua"
    local file = assert(io.open(path, "rb"))
    local source = file:read("a"); file:close()
    local first = assert(source:find("--#Accessibility integration", 1, true))
    local last = assert(source:find("--#End of accessibility integration", first, true))
    assert(load(source:sub(first, last - 1), "@" .. path, "t", env))()
    shown()
    local picker = assert(mgr:FindByFocusKey(owner, spec[2]))
    check(#mgr.Stack == 1 and picker.Parent == owner and picker.__priority == nil,
        "frontend picker is an owned child, not an independently prioritized root")
    check(isFocused(mgr, picker), "owned picker receives focus above queued setup")
    for _ = 1, 12 do input(Harness.Key(Keys.VK_TAB, { Message = KeyEvents.KeyDown })) end
    check(isFocused(mgr, picker), "picker Tab navigation stays inside the child view")
    input(Harness.Key(Keys.Z))
    check(escapedToOwner == 0, "picker traps input before setup bindings")
    local popup = mgr:CreateWidget("frontend-popup", "Panel", { Label = "Popup" })
    mgr:Push(popup, { priority = PopupPriority.Current })
    hidden()
    check(picker.Parent == owner, "temporary native hiding retains picker ownership")
    shown()
    picker = assert(mgr:FindByFocusKey(owner, spec[2]))
    check(picker.Parent == owner and mgr:GetTop() == popup and mgr.CurrentPath[1] == popup,
        "picker rebuild preserves its owner without stealing popup focus")
    mgr:RemoveFromStack("frontend-popup")
    check(isFocused(mgr, picker), "popup close restores rebuilt owned picker")
    env.Close()
    check(mgr:FindByFocusKey(owner, spec[2]) == nil and mgr:GetFocusedWidget() == opener,
        "picker closure destroys child and restores opening control")
    shown()
    input(Harness.Key(Keys.VK_ESCAPE))
    check(mgr:GetFocusedWidget() == opener and #owner.Children == 1,
        "Escape closes reopened picker without leaving stale children")
end
for _, name in ipairs({ "ChooseArtifact", "DisloyalCityChooser", "EspionageEscape", "TreatWithTribePopup" }) do
    for _, ownerPriority in ipairs({ 99, 9999 }) do
        local mgr = Harness.CreateManager({ [name] = true })
        Harness.Run("src/UI/uiManager/helpers/CAIWidgetHelpers_DialogBuilder.lua")
        CAIWidgetHelpers_DialogBuilder.Install(mgr)
        local owner = mgr:CreateWidget("dialog-owner", "Panel", { Label = "Owner" })
        mgr:Push(owner, { priority = ownerPriority })
        local noop = function() end
        local control = {
            GetText = function() return "Native control" end,
            GetToolTipString = function() return "" end,
            IsDisabled = function() return false end,
            IsHidden = function() return false end,
            RegisterCallback = noop,
        }
        local env = setmetatable({
            Controls = setmetatable({}, { __index = function() return control end }),
            ContextPtr = { IsHidden = function() return false end,
                SetInputHandler = noop, SetHideHandler = noop },
            Game = { GetLocalPlayer = function() return -1 end },
            OnOpen = noop, OnClose = noop, OnKeepButton = noop, OnRejectButton = noop,
            OnInputHandler = noop, OnOpenTreatWithTribePopup = noop, ClosePopup = noop,
        }, { __index = _G })
        local path = "src/UI/inGame/" .. name .. "_CAI.lua"
        local file = assert(io.open(path, "rb"))
        local source = file:read("a"); file:close()
        assert(load(source, "@" .. path, "t", env))()
        if name == "TreatWithTribePopup" then env.OnOpenTreatWithTribePopup(55)
        else env.OnOpen() end
        local dialog = mgr:GetTop()
        check(dialog ~= owner and dialog.Type == "Dialog", "native owner-relative dialog opens")
        check(dialog.__priority == ownerPriority and mgr.CurrentPath[1] == dialog,
            "dialog inherits above its opener even when the opener is above 99")
        mgr:RemoveFromStack(dialog:GetId())
        check(mgr:GetTop() == owner and mgr.CurrentPath[1] == owner,
            "dialog close restores its owner")
    end
end
print("UI layering: " .. count .. " assertions passed")
