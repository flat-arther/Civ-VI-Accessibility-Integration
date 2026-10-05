-- Production Minimap and manager regression. Run from the repository root.
local assertions = 0
local function check(value, message)
    assertions = assertions + 1
    assert(value, message)
end
local harness = dofile('scripts/test-support/WidgetHarness.lua')
local mgr = harness.CreateManager({ MinimapPanel = true })
local run = harness.Run
local speech = harness.Speech
local player, mode, editor, capability = 0, 0, false, true
InterfaceModeTypes = { DISTRICT_PLACEMENT = 1 }
UI = { GetInterfaceMode = function() return mode end, PlaySound = function() end }
Game = { GetLocalPlayer = function() return player end }
GameConfiguration = { GetRuleSet = function() return "RULESET_STANDARD" end, IsWorldBuilderEditor = function() return editor end }
GameCapabilities = { HasCapability = function() return capability end }
ContextPtr = { SetShutdown = function(_, fn) ContextPtr.shutdown = fn end, SetInputHandler = function() end }
local function control(name)
    return {
        hidden = false, disabled = false,
        IsHidden = function(self) return self.hidden end,
        IsDisabled = function(self) return self.disabled end,
        GetText = function() return name end,
        GetToolTipString = function() return name .. " tooltip" end,
        IsChecked = function() return false end,
        RegisterCallback = function() end,
    }
end
Controls = {}
for _, name in ipairs({ "LensButton", "ReligionLensButton", "ContinentLensButton", "AppealLensButton",
    "WaterLensButton", "GovernmentLensButton", "OwnerLensButton", "TourismLensButton", "MapPinListButton",
    "MapPinListPanel", "MapSearchPanel" }) do Controls[name] = control(name) end
local toggles = 0
for _, name in ipairs({ "ToggleReligionLens", "ToggleContinentLens", "ToggleAppealLens", "ToggleWaterLens",
    "ToggleGovernmentLens", "ToggleOwnerLens", "ToggleTourismLens" }) do
    _G[name] = function() toggles = toggles + 1 end
end
LensPanelHotkeyControl, ToggleMapPinMode, ToggleMapSearchPanel = function() end, function() end, function() end
OnInputActionTriggered, LateInitialize, OnShutdown = function() end, function() end, function() end
OnInputHandler = function() return false end

run("src/UI/inGame/MinimapPanel_CAI.lua")
local base = mgr:CreateWidget("test-world", "Panel", {})
local initial = mgr:CreateWidget("test-selection", "Button", { Label = "selection", FocusKey = "selection" })
base:AddChild(initial)
mgr:Push(base)
local function lens() return mgr:GetWidgetById("CAIMinimapLensList") end
local function toggle() LuaEvents.CAIMinimapLensListToggle() end
toggle()
check(lens() ~= nil and mgr:GetTop() == lens(), "opening pushes the lens root")
check(mgr:GetFocusedWidget().Parent == lens(), "opening focuses a lens entry")
toggle()
check(lens() == nil and mgr:GetFocusedWidget() == initial, "second toggle closes and restores focus")
toggle()
check(lens() ~= nil and #mgr.Stack == 2, "reopening creates exactly one lens root")
mgr:HandleInput({
    GetKey = function() return Keys.VK_ESCAPE end,
    GetMessageType = function() return KeyEvents.KeyUp end,
    IsShiftDown = function() return false end,
    IsControlDown = function() return false end,
    IsAltDown = function() return false end,
})
check(lens() == nil and mgr:GetFocusedWidget() == initial, "Escape closes and restores focus")
toggle()
local first = lens().Children[1]
Controls.ReligionLensButton.disabled = true
first:Activate()
check(toggles == 0 and lens() ~= nil, "live disabled state prevents activation")
Controls.ReligionLensButton.disabled = false
first:Activate()
check(toggles == 1 and lens() == nil, "activation uses vanilla callback once and closes")
mode = InterfaceModeTypes.DISTRICT_PLACEMENT
toggle()
check(lens() == nil and speech[#speech] == "LOC_CAI_UI_LENSES_DISTRICT_PLACEMENT", "placement gate is preserved")
mode = 0
editor = true
toggle()
check(lens() == nil, "World Builder gate is preserved")
editor = false
toggle()
mgr:RemoveFromStack("CAIMinimapLensList")
toggle()
check(lens() ~= nil and #mgr.Stack == 2, "stale reference after external removal can reopen")
local modal = mgr:CreateWidget("test-modal", "Panel", {})
modal:AddChild(mgr:CreateWidget("test-modal-button", "Button", { Label = "modal" }))
mgr:Push(modal, { priority = PopupPriority.Medium })
toggle()
check(lens() == nil and mgr:GetTop() == modal, "closing a covered lens root preserves the higher modal")
mgr:Pop()
check(mgr:GetFocusedWidget() == initial, "modal pop restores world selection")
local capture = mgr:CaptureFocusKey(base)
base:ClearChildren()
local replacement = mgr:CreateWidget("test-new-selection", "Button", { Label = "selection", FocusKey = "selection" })
base:AddChild(replacement)
local speechBefore = #speech
mgr:RestoreFocus(base, capture)
check(mgr:GetFocusedWidget() == replacement, "rebuild restores focus by stable identity")
check(#speech == speechBefore, "same logical focus restores without repeated speech")
toggle()
ContextPtr.shutdown()
check(lens() == nil and mgr:GetFocusedWidget() == replacement, "shutdown removes the lens root")
toggle()
check(lens() == nil, "shutdown unsubscribes the toggle event")
print("Minimap and manager: " .. assertions .. " assertions passed")
