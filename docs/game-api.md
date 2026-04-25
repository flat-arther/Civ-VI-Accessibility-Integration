# Civ VI Game API Reference (CAI Mod)

Documented APIs used by the CAI accessibility mod. Updated as new patterns are discovered.

## Safe Mod Keys

Keys confirmed safe to bind in mods without conflicting with game defaults:

- `Keys.VK_TAB` — not bound by default in game
- `Keys.VK_HOME`, `Keys.VK_END` — not bound by default
- `Keys.VK_PRIOR` (Page Up), `Keys.VK_NEXT` (Page Down) — not bound by default
- `Keys.VK_NUMPAD1` through `Keys.VK_NUMPAD9` — hex grid navigation
- `Keys.VK_SPACE` — safe for checkbox toggle (game uses for other contexts)
- `Keys.VK_RETURN` — safe for button activation
- `Keys.VK_ESCAPE` — standard cancel/close
- `Keys.A` through `Keys.Z` — letter keys (use with IsControl for shortcuts like Ctrl+A)

## Input System

### InputStruct

Passed to input handlers. Methods:

- `input:GetKey()` — returns key code (`Keys.VK_*`)
- `input:GetMessageType()` — returns `KeyEvents.KeyDown` or `KeyEvents.KeyUp`
- `input:IsShiftDown()` — boolean
- `input:IsControlDown()` — boolean

### KeyEvents

- `KeyEvents.KeyDown` — fires on press (repeats while held)
- `KeyEvents.KeyUp` — fires once on release

### Input (global)

- `Input.GetActionId(name)` — returns numeric action ID for a named action
- `Input.GetActionCount()` — total number of registered input actions
- `Input.GetActionName(actionId)` — returns LOC key for action name
- `Input.GetActionCategory(actionId)` — returns LOC key for action category
- `Input.GetActionDescription(actionId)` — returns LOC key for action description
- `Input.ShouldShowActionKeybinding(actionId)` — whether this action appears in keybinding UI
- `Input.GetGestureDisplayString(actionId, index)` — human-readable key string for binding (index 0 = primary, 1 = alt); nil if unbound
- `Input.BindAction(actionId, index, gesture)` — binds a gesture to an action
- `Input.ClearGesture(actionId, index)` — clears a binding
- `Input.BeginRecordingGestures(exclusive)` — starts capturing key input for binding; fires `Events.InputGestureRecorded` when captured. Works at engine level below Lua input handlers.
- `Input.StopRecordingGestures()` — stops gesture capture
- `Input.ClearRecordedGestures()` — clears captured gestures
- `Input.SetActiveContext(context)` — sets the active input context (e.g. `InputContext.Startup`)

### ContextPtr

- `ContextPtr:SetInputHandler(function(input) ... end, interceptAll)` — sets the Lua input handler for this context. If `interceptAll` is true, handler receives all input before the engine. Return true to consume, false to pass through.

## Locale

- `Locale.Lookup(tag, ...)` — looks up a localized string by tag, with optional format args
- `Locale.ToUpper(str)` — uppercase
- `Locale.Compare(a, b)` — returns -1, 0, or 1

## Options

### Options (global)

- `Options.GetAppOption(category, key)` — reads an app-level option
- `Options.SetAppOption(category, key, value)` — writes an app-level option
- `Options.GetUserOption(category, key)` — reads a user-level option
- `Options.SetUserOption(category, key, value)` — writes a user-level option
- `Options.SetGraphicsOption(category, key, value, flag)` — writes a graphics option
- `Options.SetAudioOption(group, key, value, flag)` — writes an audio option
- `Options.GetAvailableDisplayAdapters()` — returns table of GPU names
- `Options.GetAvailableDisplayModes()` — returns table of `{Width, Height, RefreshRate}`
- `Options.SaveOptions()` — persists all options to disk
- `Options.RevertOptions()` — reverts to last saved state

## UI Controls

### Common Control Methods

These are methods on Civ VI's native XML-backed UI controls:

- `ctrl:GetText()` / `ctrl:SetText(str)` — text content
- `ctrl:GetToolTipString()` / `ctrl:SetToolTipString(str)` — tooltip
- `ctrl:IsHidden()` / `ctrl:SetHide(bool)` — visibility
- `ctrl:IsDisabled()` / `ctrl:SetDisabled(bool)` — disabled state
- `ctrl:IsVisible()` — true if not hidden
- `ctrl:IsSelected()` / `ctrl:SetSelected(bool)` — checkbox/toggle state
- `ctrl:IsChecked()` / `ctrl:SetCheck(bool)` — alternate checkbox API
- `ctrl:GetValue()` / `ctrl:SetValue(float)` — slider value (0.0–1.0)
- `ctrl:GetStep()` / `ctrl:GetNumSteps()` — stepped slider position
- `ctrl:SetStepAndCall(step)` — sets step and fires callback
- `ctrl:RegisterCallback(mouseEvent, fn)` — registers click/hover handlers
- `ctrl:ClearCallback(mouseEvent)` — removes a callback
- `ctrl:CalculateSize()` — recalculates layout
- `ctrl:DestroyAllChildren()` — removes all child instances

### PullDown (ComboBox) Controls

- `ctrl:GetButton()` — returns the button sub-control (has `:GetText()`, `:SetText()`)

### EditBox Controls

- `ctrl:ClearString()` — empties the text
- `ctrl:RegisterCommitCallback(fn)` — fires on Enter
- `ctrl:RegisterStringChangedCallback(fn)` — fires on text change
- `ctrl:GetText()` — current text

### Mouse Events

- `Mouse.eLClick` — left click
- `Mouse.eMouseEnter` — hover enter

## UIManager (global)

- `UIManager:SetClipboardString(str)` — copies text to the system clipboard

## InstanceManager

Used to create dynamic UI instances from XML templates:

- `InstanceManager:new(instanceName, topControlName, parentControl)` — creates a manager
- `im:GetInstance()` — allocates a new instance, returns control table
- `im:ResetInstances()` — returns all instances to pool
- `im.m_AllocatedInstances` — array of currently allocated instances

## Map & Plot

- `Map.GetPlotByIndex(plotId)` — returns a Plot object
- `plot:GetX()`, `plot:GetY()` — plot coordinates

## Events

### Engine Events (Events.*)

- `Events.InputGestureRecorded` — fired when gesture recording captures a key combo
- `Events.InputActionTriggered` — fired when a bound input action is triggered
- `Events.InterfaceModeChanged` — fired when interface mode changes (e.g. MOVE_TO)
- `Events.UserAcceptsEULA` — EULA accepted
- `Events.UserConfirmedClose` — user confirmed app exit
- `Events.UserRequestClose` — user requested app exit
- `Events.FrontEndPopup` — frontend popup requested (256 char limit)

### Lua Events (LuaEvents.*)

- `LuaEvents.CAIEndTurn` — CAI custom: triggers end turn
- `LuaEvents.CAICursorMoved` — CAI custom: cursor position changed
- `LuaEvents.MainMenu_ShowAdditionalContent` — opens mods screen
- `LuaEvents.MainMenu_UserRequestClose` — main menu exit request
- `LuaEvents.MainMenu_LaunchError` — game launch error
- `LuaEvents.MultiplayerPopup` — multiplayer popup (no char limit)
- `LuaEvents.FrontEndPopup_CloseConfirmationWithoutAction` — popup closed without action
- `LuaEvents.OnRaisePopupInGame` — raises an in-game popup dialog

## ExposedMembers

Shared global table for cross-context communication:

- `ExposedMembers.CAI_UIManager` — the UIScreenManager singleton
- `ExposedMembers.CAICursor` — the navigation cursor object
- `ExposedMembers.CAICursorOverrides` — cursor coordinate override functions
- `ExposedMembers.CAI_MainGamePanel` — the root in-world CAI game panel created by `WorldInput_CAI.lua`; in-world HUD accessibility layers can attach themselves with `AddChild(...)` instead of pushing a separate screen

## CAI Custom API

### CAI (C++ bridge)

- `CAI.output(text, interrupt)` — sends text to screen reader. Always use `Speak()` wrapper instead.
- `CAI.onCharInput` — callback property. Assign a `function(char)` to receive raw character input. Called by the engine when a character key is pressed (operates alongside the regular input system). Return true to consume.
- `CAI.enableCharInput(bool)` — enables or disables the character input callback.

### Speak(text, interrupt)

Wrapper for `CAI.output`. Use this for all TTS output.

## Lua Context Notes

- Included Civ VI Lua panel files expose their top-level functions directly in the current chunk after `include("...")`, so wrappers can usually reassign names like `PopulateWonders = WrapFunc(PopulateWonders, ...)`.
- Do not rely on `_G` or `rawget(_G, ...)` for panel helper discovery in Civ VI UI contexts. These globals are not consistently available/mod-safe in this project; prefer explicit one-by-one capture/wrapping of the functions you need.
- Tutorial input locking:
  - `TutorialScenarioBase.lua` starts the tutorial with `Input.SetActiveContext(InputContext.Tutorial)`.
  - `TutorialUIRoot.lua` installs `ContextPtr:SetInputHandler(OnInput, true)`, so it receives all input during tutorial flow. Its normal handler only handles debug keys and Escape, but the tutorial system also drives `UITutorialManager` overlays/control filtering.
  - `AdvisorPopup.lua` also installs `ContextPtr:SetInputHandler(OnInputHandler, true)`. When `AdvisorBase` or `MetaBase` is visible, `IsBlockingInput()` returns true, so `OnInputHandler()` consumes most input. Escape is special-cased to fire `LuaEvents.Tutorial_ToggleInGameOptionsMenu()`.
  - `AdvisorPopup.lua` calls `UITutorialManager:SetActiveAlways(isAdvisorVisible)` and `UITutorialManager:EnableOverlay(isAdvisorVisible)` from show/hide handlers. While the advisor is visible, normal UI controls do not get input.
  - Detailed tutorial steps call `RaiseDetailedTutorial(item)`, which shows only the tutorial-triggered controls and calls `UITutorialManager:EnableControlsByIdOrTag(...)` for the item `EnabledControls`. Other controls may be blocked by the tutorial overlay even when the advisor popup is hidden.
  - Tutorial items are data objects loaded by `TutorialUIRoot.LoadItems()`. They define raise listeners, prereqs, advisor text/buttons, advisor-only UI triggers, detailed-mode UI triggers, enabled controls, disabled controls, done listeners, cleanup, and optional chain `NextID`.
  - `TutorialCheck(listenerName)` is the central state machine. It ignores checks while disabled or during the load screen, checks only valid local-player tutorial events, deactivates the active item when its done listener/function matches, then activates unseen eligible items or queues queueable ones.
  - `ActivateItem(item)` sets `m_active`, optionally runs the global pre-activate function and item open function, enables tutorial checks, adds goals, then raises the advisor popup through `LuaEvents.TutorialUIRoot_AdvisorRaise(item.AdvisorInfo)`.
  - Advisor buttons either call `LuaEvents.AdvisorPopup_ClearActive(advisorInfo)` to mark/deactivate/chain, or `LuaEvents.AdvisorPopup_ShowDetails(advisorInfo)` to mark seen and enter detailed mode.
  - `TutorialInput.lua` is a separate lightweight input-filter context. `ActivateInputFiltering()` shows that context through `LuaEvents.TutorialUIRoot_FilterKeysActive()`, and `DisableInputFiltering()` hides it; while active it primarily catches Escape for the tutorial options menu.
  - In the base tutorial `OPEN_CITY_PANEL` item, the only explicitly enabled target is the city panel `ChangeProductionCheck`, and completion is `CityPanel_ProductionOpen` -> `ProductionPanelViaCityOpen`. This is why normal arrow/Escape navigation can appear stolen until that control is activated.
  - In the base tutorial `TURN_BASED_B` item, the OK button calls `LuaEvents.AdvisorPopup_ShowDetails(advisorInfo)`. `TutorialUIRoot.OnAdvisorPopupShowDetails()` marks the active item seen and calls `RaiseDetailedTutorial(item)`. Because `TURN_BASED_B` has no `UITriggers`, `RaiseDetailedTutorial()` immediately calls `DeActivateItem(item)`, which chains into `TURN_BASED_C`.
  - `TURN_BASED_C` is the detailed end-turn step: it sets `UITriggers("ActionPanel", "TutorialSelectEndTurn")`, enables `UITutorialManager:GetHash("ActionPanel")`, disables `UITutorialManager:GetHash("ChangeProductionCheck")`, and completes on `LocalPlayerTurnEnd`.
  - If the game access-violates on the `TURN_BASED_B` OK click with no Lua traceback, the native crash is likely during the `AdvisorPopup_ShowDetails` -> `RaiseDetailedTutorial` -> `DeActivateItem` -> `ActivateItem(TURN_BASED_C)` chain, especially around `UITutorialManager` showing/enabling ActionPanel tutorial controls.
- `ProductionPanel.lua` queue selection is a single-item pick-up mode, not multi-select:
  - the real selected queue item is local `m_kSelectedQueueItem = { Parent, Button, Index }`
  - `OnItemClicked(parent, button)` selects when `Index == -1`, swaps with the clicked queue index when another item is selected, or deselects when clicking the same item
  - `HighlightButtons(true)` calls `SetSelected(true)` on current production and every valid queue slot, so `control:IsSelected()` means "queue selection mode is active", not "this exact row is selected"
  - `RefreshQueue(...)` starts with `DeselectItem()`, so queue rebuilds intentionally clear vanilla selection
- `ProductionManager.lua` is the separate multi-queue UI context opened by `ProductionPanel.lua` Manager tab:
  - `OnTabChangeManager()` calls `OpenManager()`, which broadcasts `LuaEvents.ProductionPanel_OpenManager()`
  - `ProductionManager.lua` listens for `ProductionPanel_OpenManager`, `ProductionPanel_CloseManager`, `ProductionPanel_ProductionClicked`, and `ProductionPanel_CancelManagerSelection`
  - it owns `Controls.FilterPulldown`, `Controls.CityStack`, per-city `CityInstance` rows, per-city `CurrentProductionGrid`, per-city queue slots, and per-city `TrashButton`
  - `SetupFilters()` creates sort entries with `Controls.FilterPulldown:BuildEntry("FilterItemInstance", controlTable)`; each entry button calls `Refresh(sortFunc, name)`
  - built-in sort filters are founding order, city name, and population
- `FiraxisLive/My2K.lua` is a front-end popup context hosted under `/FrontEnd/MainMenu/My2K`:
  - Vanilla uses a legacy 3-argument `InputHandler(uiMsg, wParam, lParam)` and `ContextPtr:SetShowHideHandler(ShowHideHandler)`.
  - CAI can replace that input handler with the extended `InputStruct` form after vanilla setup and preserve Escape behavior by checking `input:GetMessageType()`, `input:GetKey()`, `m_bESCEnabled`, and `m_cancelFunction`.
  - Dialog state is selected by `m_currentDialogID` and created by `ShowHideHandler()` through `Create2KMainMenu`, `CreateLoginDialog`, `CreateNewUserDialog`, `CreateUserNameDialog`, `CreateLegalDialog`, `CreateLegalItemDialog`, `CreateMessageDialog`, `CreateLogoutDialog`, and `CreateUnlinkConfirmationDialog`.
  - My2K dialog instances are XML-backed and short-lived through `InstanceManager`; accessible replacements should rebuild from the live `m_currentDialog` instance after each `Create*Dialog()` call.
  - The shared `WidgetTemplateHelpers:MakeGeneralDialog(titleFunc, actionButtons, dlgContent)` helper is the preferred CAI scaffold for these modal dialogs.
- `CityPanel.lua` exposes the live selected-city data table as local `m_kData` inside the included chunk, so a wrapper can read the same live data after wrapping `Refresh()`.
- `CitySupport.lua` exposes `GetCityData(city)`, and `CityPanel.lua` includes `CitySupport`, so `CityPanel_CAI.lua` can request fresh city data without wrapping `Refresh()`.
- `CityManager.GetCity(playerID, cityID)` is available in UI context and can resolve a city for helper-based city info requests.
- `CityPanel_CAI.lua` now extends `ExposedMembers.CAIInfo` with:
  - `CityInfo` helper table (`Summary`, `BuildingCount`, `ReligiousFollowersCount`, `AmenitiesSummary`, `HousingSummary`, `GrowthSummary`, `ProductionSummary`, `VisibleYields`, `NormalFocusYields`, `FavoredFocusYields`, `IgnoredFocusYields`)
  - `RequestCityInfo(cityOrCityID, requestedKeys, playerID)` which defaults to the currently selected city when no city is passed
- `CityPanel_CAI.lua` now builds city info from `GetCityData(city)` using the same vanilla loc keys / string assembly patterns as `CityPanel.lua`; it does not read back from UI controls or call `ViewMain(data)`.
- City growth / production helpers can also expose the visible progress-bar state from `GetCityData(city)`:
  - growth: `CurrentFoodPercent`, `FoodPercentNextTurn`
  - production: `CurrentProdPercent`, `ProdPercentNextTurn`
- Vanilla does not appear to provide clean city-panel loc tags for labeling those two percentage values as speech output, so `CityPanel_CAI.lua` uses CAI loc tags for:
  - `LOC_CAI_CURRENT_PROGRESS`
  - `LOC_CAI_NEXT_TURN_PROGRESS`
- `CityPanel_CAI.lua` also listens to `Events.InputActionTriggered(actionId)` and uses an action-id-to-helper map instead of an `if` / `elseif` chain.
- Current city selection hotkey mapping in `src/data/hotkey_config.xml`:
  - `ReadSelectionSummary` -> `Summary`
  - `ReadSelectionInfo1` -> `BuildingCount`
  - `ReadSelectionInfo2` -> `ReligiousFollowersCount`
  - `ReadSelectionInfo3` -> `AmenitiesSummary`
  - `ReadSelectionInfo4` -> `HousingSummary`
  - `ReadSelectionInfo5` -> `GrowthSummary`
  - `ReadSelectionInfo6` -> `ProductionSummary`
  - `ReadSelectionInfo7` -> `VisibleYields`
  - `ReadSelectionInfo8` -> `NormalFocusYields`
  - `ReadSelectionInfo9` -> `FavoredFocusYields`
  - `ReadSelectionInfo10` -> `IgnoredFocusYields`
- City yield focus states in `GetCityData(city)` are stored in `data.YieldFilters[yieldType]` and map to:
  - `YIELD_STATE.FAVORED`
  - `YIELD_STATE.IGNORED`
  - any other value = normal
- City yield preferences use a native three-state model:
  - `YIELD_STATE.FAVORED`
  - `YIELD_STATE.IGNORED`
  - neither state = normal
- CityPanel helpers for yield preference changes:
  - `OnCheckYield(yieldType, yieldName)` transitions normal to favored, or favored to ignored depending on the checkbox visual state
  - `OnResetYieldToNormal(yieldType, yieldName)` transitions ignored back to normal
  - `SetYieldFocus(yieldType)` and `SetYieldIgnore(yieldType)` are the lower-level command helpers used underneath

## Interface Modes

- `InterfaceModeTypes.MOVE_TO` — unit movement mode
- `UI.GetInterfaceMode()` — returns current interface mode
- `UI.SetInterfaceMode(mode)` — changes interface mode

## Sound

- `UI.PlaySound(soundKey)` — plays a UI sound effect
  - `"Main_Menu_Mouse_Over"` — standard hover sound

## Modding

- `Modding.IsModInstalled(modGuid)` — checks if a mod is active
- `Modding.CheckRequirements(mods, saveType)` — validates mod compatibility

## Game State

- `GameConfiguration.GetGameState()` — returns current state
- `GameStateTypes.GAMESTATE_PREGAME` — pre-game state constant

## Network

- `Network.LeaveGame()` — leaves current network session
- `Network.LoadGame(saveData, serverType)` — loads a save file
- `Network.GetFriends()` — returns friends API object
