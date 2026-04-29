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
- `Map.GetGridSize()` — returns map width and height
- `Map.GetPlot(x, y)` — returns a Plot for valid coordinates. On maps where `Map:IsWrapX()` is true, X coordinates wrap east/west, so `x = -1` resolves to the last column. Y coordinates only wrap if `Map:IsWrapY()` is true; normal Civ VI maps do not wrap north/south, so `y = -1` returns nil.
- `Map:IsWrapX()` / `Map:IsWrapY()` — return whether the active map wraps on that axis. Check these before manually wrapping absolute coordinates.

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
- `LuaEvents.CAICursorMove(x, y, wrapCoords)` — CAI custom: public absolute cursor move event; call this instead of accessing the cursor object directly. If `wrapCoords` is true, CAI wraps both axes manually using `Map.GetGridSize()` before resolving the plot; otherwise out-of-bounds coordinates are rejected before calling `Map.GetPlot(...)`.
- `LuaEvents.CAICursorMoveRelative(dx, dy, wrapCoords)` — CAI custom: public relative cursor move event used by remappable cursor input actions. `wrapCoords` has the same behavior as absolute cursor moves.
- `LuaEvents.CAICursorMoved(x, y, plot, cursor)` — CAI custom: emitted after the cursor moves; listeners should read/speak plot info here
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

### UIScreenManager priority stack

- `UIWidgetPriority` defines shared root-widget priority levels:
  - `Low = -10`
  - `Normal = 0`
  - `High = 10`
- `mgr:Push(widget, priority)` accepts a numeric priority. Nil priority resolves to `Normal`.
- Stack sorting is deterministic: priority wins first, then push order breaks ties. Equal-priority widgets therefore behave like a normal last-in-first-out stack.
- The active root is always `mgr:GetTop()`, which is the last entry after sorting.
- Pushing a lower-priority root does not refocus or reannounce the existing active root when it remains on top.
- `mgr:Pop()` removes the active root. `mgr:Pop(widget)` removes a specific root widget if a screen needs to close a non-active lower-priority root.
- `mgr:SetFocus(...)` and `mgr:SetFocusPath(...)` only apply focus when the target path belongs to the active root, preventing lower-priority screens from stealing focus while a higher-priority modal/popup is active.

## Lua Context Notes

- Included Civ VI Lua panel files expose their top-level functions directly in the current chunk after `include("...")`, so wrappers can usually reassign names like `PopulateWonders = WrapFunc(PopulateWonders, ...)`.
- Do not rely on `_G` or `rawget(_G, ...)` for panel helper discovery in Civ VI UI contexts. These globals are not consistently available/mod-safe in this project; prefer explicit one-by-one capture/wrapping of the functions you need.
- Tutorial input locking:
  - `TutorialScenarioBase.lua` starts the tutorial with `Input.SetActiveContext(InputContext.Tutorial)`.
  - `TutorialUIRoot.lua` installs `ContextPtr:SetInputHandler(OnInput, true)`, so it receives all input during tutorial flow. Its normal handler only handles debug keys and Escape, but the tutorial system also drives `UITutorialManager` overlays/control filtering.
  - `AdvisorPopup.lua` also installs `ContextPtr:SetInputHandler(OnInputHandler, true)`. When `AdvisorBase` or `MetaBase` is visible, `IsBlockingInput()` returns true, so `OnInputHandler()` consumes most input. Escape is special-cased to fire `LuaEvents.Tutorial_ToggleInGameOptionsMenu()`.
  - `AdvisorPopup.lua` calls `UITutorialManager:SetActiveAlways(isAdvisorVisible)` and `UITutorialManager:EnableOverlay(isAdvisorVisible)` from show/hide handlers. While the advisor is visible, normal UI controls do not get input.
  - Detailed tutorial steps call `RaiseDetailedTutorial(item)`, which shows only the tutorial-triggered controls and calls `UITutorialManager:EnableControlsByIdOrTag(...)` for the item `EnabledControls`. Other controls may be blocked by the tutorial overlay even when the advisor popup is hidden.
  - In the production tutorial steps, vanilla production rows are tagged with `UITutorialManager:GetHash(item.Type)` while the scenario enables hashes such as `UNIT_WARRIOR`, `UNIT_BUILDER`, or `BUILDING_MONUMENT`. CAI production rows should read the live vanilla row controls through widget `IsHidden` / `IsDisabled` methods so UI manager navigation and activation respect the current tutorial-filtered control state.
  - ResearchChooser uses the same pattern: vanilla research rows tag `Top` with `UITutorialManager:GetHash(kData.TechType)` and set `Top:SetDisabled(...)`; CAI research rows should cache the returned vanilla row instance and expose live `Top` / `TopContainer` state through widget `IsHidden` / `IsDisabled`.
  - Base tutorial research "Show me" buttons call `LuaEvents.Tutorial_ResearchOpen()` before `LuaEvents.AdvisorPopup_ShowDetails(advisorInfo)`. That means ResearchChooser can open before `RaiseDetailedTutorial(item)` applies enabled-control filtering, so CAI's initial focus should wait for a post-`RaiseDetailedTutorial` signal before pushing the accessibility panel on tutorial opens.
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
- `UnitPanel.lua` owns selected-unit panel data and action button construction:
  - `ReadUnitData(unit)` builds the panel data table from the live unit, including name, type, movement, health, charges, promotions, abilities, stats, and `Actions`.
  - `GetSubjectData()` returns the current selected-unit data table cached by `View(data)`.
  - `GetUnitActionsTable(unit)` builds `data.Actions` with vanilla action order, disabled state, tooltip/failure text, callback function, callback void values, and optional sound.
  - `data.Actions.displayOrder.primaryArea` and `secondaryArea` define the normal unit-panel action order. Build actions live in `data.Actions["BUILD"]`.
  - `AddActionToTable(...)` also populates vanilla `m_kHotkeyActions` for actions with `HotkeyId`; CAI should let vanilla continue handling directly bound unit-operation keys.
  - `UnitPanel_CAI.lua` extends `ExposedMembers.CAIInfo` with `RequestUnitInfo(unitID, requestedKeys, playerID)`, defaults to `UI.GetHeadSelectedUnit()`, and uses the same `ReadUnitData` / `GetSubjectData` data rather than reimplementing unit state.
  - `UnitPanel_CAI.lua` handles the shared selection info inputs (`~`, `Shift+1` through `Shift+0`) when a unit is selected and opens a transient action list from the existing `SelectionActions` input.
  - Plot info does not call selected-unit info helpers. `worldInfo.lua` keeps a small local plot-unit display-name helper for aggregated plot summaries.
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
- `WorldTracker.lua` is a passive in-game HUD stack, not a modal chooser:
  - It builds `ResearchInstance`, `CivicInstance`, `OtherContainer`, `UnitListInstance`, `ChatPanelContainer`, and `TutorialGoals` under `Controls.WorldTrackerVerticalContainer` in that order.
  - The header has `Controls.ToggleAllButton` to collapse/expand the whole tracker and `Controls.ToggleDropdownButton` to open tracker options.
  - The options dropdown contains checkbox controls for chat, civics, research, and unit list visibility. `CheckEnoughRoom()` disables unchecked options and sets `LOC_WORLDTRACKER_NO_ROOM` when there is not enough vertical space.
  - Research and civics panels are shown only when their capability exists and the local player is alive. They call `RealizeCurrentResearch(...)` / `RealizeCurrentCivic(...)` from `TechAndCivicSupport.lua`, which populate title text, icon, turns remaining, progress meter, boost meter/icon/label, unlock icons, and overflow page-turn button.
  - The research/civics `IconButton` opens the matching chooser through `LuaEvents.WorldTracker_OpenChooseResearch()` / `LuaEvents.WorldTracker_OpenChooseCivic()`. Right-click Civilopedia callbacks are added to title/unlock controls outside tutorial mode.
  - If no current research/civic exists, the panel remains visible but the active title/icon are hidden and `UpdateResearchPanel(...)` / `UpdateCivicsPanel(...)` set the title button text to `LOC_WORLD_TRACKER_CHOOSE_RESEARCH` or `LOC_WORLD_TRACKER_CHOOSE_CIVIC`.
  - The unit list is hidden by default. When visible and `CAPABILITY_UNIT_LIST` exists, it rebuilds on unit add/remove/movement/activity events, groups units by broad type, filters by `UnitsSearchBox`, and each row left-clicks `OnUnitEntryClicked(unitID)` to look at and select that unit.
  - Unit rows use live text from `Button:GetText()`, optional tooltip for renamed units, status icon for sleep/skip/fortify, and text/icon color to indicate whether movement remains.
  - World Tracker hides itself during `VIEW_MODAL_LENS`, can be force-hidden/restored by research/civic choosers and tutorials, and in tutorial restore mode the normal collapse/options buttons are temporarily hidden while research/civics are forced visible.
  - CAI access should use world input actions rather than an ambient mirrored widget panel. Current mappings are `WorldTrackerOpenResearchChooser` -> `LuaEvents.WorldTracker_OpenChooseResearch()`, `WorldTrackerOpenCivicsChooser` -> `LuaEvents.WorldTracker_OpenChooseCivic()`, and `WorldTrackerReadSummary` -> live player-state speech.
  - WorldTracker summary speech should not depend on panel visibility. Build research/civic data from `Players[localPlayer]:GetTechs():GetResearchingTech()`, `Players[localPlayer]:GetCulture():GetProgressingCivic()`, `GetResearchData()`, and `GetCivicData()`. Speak only label, turns remaining, and boost status for each. Build unit count from `Players[localPlayer]:GetUnits():GetCount()`.
- `TopPanel.lua` owns the global top-bar yields/resources:
  - `RefreshYields()` creates yield display instances under `Controls.YieldStack`.
  - Science, culture, and tourism use `YieldButton_SingleLabel` with `YieldIconString`, `YieldPerTurn`, and `YieldBacking` tooltip.
  - Gold and faith use `YieldButton_DoubleLabel` with `YieldIconString`, `YieldBalance`, `YieldPerTurn`, and `YieldBacking` tooltip.
  - Yield tooltips come from `ToolTipHelper_PlayerYields.lua`: `GetScienceTooltip()`, `GetCultureTooltip()`, `GetGoldTooltip()`, and `GetFaithTooltip()`. Tourism builds a tooltip from `LOC_WORLD_RANKINGS_OVERVIEW_CULTURE_TOURISM_RATE` plus `player:GetStats():GetTourismToolTip()`.
  - Base `TopPanel.lua` does not register click callbacks on the yield `YieldBacking` buttons. Only `MenuButton` and `CivpediaButton` get click callbacks in the base file.
  - `RefreshResources()` creates `ResourceInstance` rows under `Controls.ResourceStack`, showing only non-bonus, non-luxury, non-artifact resources with amount > 0. In practice this is the strategic-resource strip.
  - Each visible resource label uses text like `[ICON_RESOURCE_IRON] 3` and a tooltip of localized resource name plus `LOC_TOOLTIP_STRATEGIC_RESOURCE`.
  - If resources overflow the available top-bar width, vanilla shows a single `[ICON_Plus]` label whose tooltip lists the hidden resource amounts and names.
  - CAI TopPanel access should use input actions and pushed CAI widgets, not an ambient mirrored UI. Use vanilla loc strings and tooltip helpers directly; do not strip icon/color markup locally.
  - TopPanel player-yield APIs expose totals plus localized tooltip strings, not structured category tables. Known UI methods are `PlayerTechs:GetScienceYieldToolTip()`, `PlayerCulture:GetCultureYieldToolTip()`, `PlayerReligion:GetFaithYieldToolTip()`, `PlayerStats:GetTourismToolTip()`, `PlayerTreasury:GetGoldYieldToolTip()`, and `PlayerTreasury:GetTotalMaintenanceToolTip()`.
  - Gold has extra direct numeric APIs for major expense totals: `PlayerTreasury:GetBuildingMaintenance()`, `GetDistrictMaintenance()`, `GetUnitMaintenance()`, `GetWMDMaintenance()`, and `GetMaintDiscountPerUnit()`.
  - Yield detail access is a `Treeview`: each top-level yield node is the yield name plus value/rate preview. Use vanilla `LOC_HUD_REPORTS_PER_TURN` to append localized "per turn" text to any single rate value before composing larger labels. Outer yield nodes do not expose the full vanilla tooltip because the tree contains the formatted breakdown. Gold is split into vanilla `LOC_TOP_PANEL_GOLD_INCOME` and `LOC_TOP_PANEL_GOLD_EXPENSE` category nodes with localized tooltip detail lines beneath them. Science, culture, faith, and tourism use localized tooltip breakdown lines as category/detail nodes. CAI uses tooltip indentation/line structure for nesting and does not parse English text.
- `navCursor.lua` owns the CAI map cursor:
  - Public movement should use Lua events, not `ExposedMembers.CAICursor`.
  - Absolute moves use `LuaEvents.CAICursorMove(x, y, wrapCoords)`.
  - Relative moves use `LuaEvents.CAICursorMoveRelative(dx, dy, wrapCoords)`.
  - Cursor `SetCoords(x, y, wrapCoords)` performs its own bounds check before calling `Map.GetPlot(...)`, avoiding Civ VI's implicit X wrapping unless `wrapCoords` is true.
  - Directional helpers exist internally as `LuaEvents.CAICursorMoveDirection(direction)`, but default cursor navigation now uses remappable input actions rather than hardcoded numpad bindings.
  - Query-style access remains available through the WorldInput `UI` hijack: `UI.GetCursorPlotID()` and `UI.GetCursorPlotCoord()`.
  - `LuaEvents.CAICursorMoved(x, y, plot, cursor)` is the post-move notification event used by speech listeners.
  - Current default cursor input actions are `CAICursorMoveUp`, `CAICursorMoveDown`, `CAICursorMoveLeft`, and `CAICursorMoveRight`, bound to arrow keys by default.
- `WorldInput_CAI.lua` wraps vanilla `WorldInput.lua`:
  - CAI installs all `UI` table overrides in one `InstallUIOverrides()` section. Current overrides are `UI.GetCursorPlotID()` and `UI.GetCursorPlotCoord()`.
  - CAI keeps the vanilla `Events.LoadScreenClose` boundary by wrapping `OnLoadScreenClose(...)`; the main game view widget is created and pushed only after the load screen closes.
  - CAI input action entries are records with `Type` and `Action`. Use `Type = "Started"` for repeat-style inputs such as cursor movement, and `Type = "Triggered"` for one-shot inputs such as path info or interface primary action.
  - CAI registers separate dispatchers for `Events.InputActionStarted` and `Events.InputActionTriggered`, while vanilla `WorldInput` keeps its own subscriptions.
  - Interface-mode-specific action records override shared action records for the same action id.
  - Vanilla camera movement has two main paths: continuous camera panning through `UI.PanMap(panX, panY)` / `ProcessPan(...)`, and plot-centering through `SnapToPlot(plotId)` -> `UI.LookAtPlot(plot)`.
  - CAI cursor follow listens to `LuaEvents.CAICursorMoved(x, y, plot, cursor)` and calls `UI.LookAtPlot(plot)` when the plot is valid. This follows the vanilla snap-to-plot pattern without selecting units/cities or changing interface mode.
  - Do not use `UI.PanMap(...)` for CAI cursor follow; it is designed for analog/held camera pan state and does not naturally target a discrete cursor plot.
- `LoadScreen.lua` is the shell-to-game loading context under `UI/FrontEnd/LoadScreen`:
  - It starts with `Input.SetActiveContext(InputContext.Loading)` and only installs its Lua input handler after `Events.LoadGameViewStateDone`.
  - `Events.LoadScreenContentReady` fires when player configuration/game data is ready enough to populate the loading screen; vanilla `OnLoadScreenContentReady()` fills the leader/civilization presentation.
  - `Events.LoadGameViewStateDone` fires when the game view is ready; vanilla sets `m_isLoadComplete = true`, hides the loading message, shows the Begin/Continue button, switches to `InputContext.Ready`, registers button callbacks, and subscribes to `Events.InputActionTriggered`.
  - The close/continue path is `OnActivateButtonClicked()`: unloads loading textures, raises `Events.LoadScreenClose()`, stops Dawn of Man speech/menu music, dequeues the load-screen popup, switches input to `InputContext.World`, resets active lens if needed, and performs Play-By-Cloud follow-up notification checks.
  - Escape, `StartGame`, and `StartGameAlt` only continue when `m_isLoadComplete` is true. Before that, input should not force the game forward.
  - Resync loads, multiplayer games, World Builder editor loads, and automation auto-start can bypass the visible Begin/Continue button by directly calling `OnActivateButtonClicked()` after game-view state is ready.
  - Visual layout is: full-screen black/background root, fallback/loading text, leader background image, leader portrait area, central colored banner, civilization icon/name, era line, leader/challenge name, leader/challenge text, feature/ability stack, loading message, and final Begin/Continue button.
  - Content sources are `Network.GetLocalPlayerID()` with hotseat fallback, `PlayerConfigurations[playerID]`, `GameInfo.LoadingInfo[leaderType]`, `GameInfo.Leaders`, `GameInfo.Eras`, `UI.GetSaveGameMetaData()` for saved-game era, `Challenges` loading texts, and `GetLeaderUniqueTraits()` / `GetCivilizationUniqueTraits()` from `Civ6Common.lua`.
  - Dawn of Man audio is separate from screen-reader output. CAI should not rely on it as the accessible announcement, and should avoid talking over it unless the user explicitly requests load-screen speech.
  - Suggested CAI access is a `LoadScreen.lua` wrapper imported/replaced in the front-end action set. Wrap `OnLoadScreenContentReady()` to capture/live-read populated control text and build a transient `Dialog` or `Panel`; wrap `OnLoadGameViewStateDone()` to add/enable the Begin/Continue button and speak readiness; wrap `OnActivateButtonClicked()` or `OnHide()` to pop/destroy the load-screen widget before the world view is initialized.
  - Keep the existing `WorldInput_CAI.lua` `Events.LoadScreenClose` boundary unchanged. Load-screen accessibility should end before `CAI_MainGamePanel` is pushed.
- `NotificationPanel.lua` owns the ambient right-side notification rail:
  - It creates generic `ItemInstance` rows under `Controls.ScrollStack` and tracks active entries in local `m_notifications[playerID][typeName]`.
  - Each visual notification instance has `MouseInArea`, `MouseOutArea`, `IconBG`, `IconBGInvalidPhase`, `Icon`, `CountImage`, `DismissStackButton`, expanded `TitleInfo`, `Summary`, `LeftArrow`, `RightArrow`, `PagePipStack`, and `Pages`.
  - Notification data should come from the live `Notification` object via `NotificationManager.Find(playerID, notificationID)`. Useful methods include `GetMessage()`, `GetSummary()`, `GetTypeName()`, `GetType()`, `GetIconName()`, `GetGroup()`, `GetCount()`, `GetEndTurnBlocking()`, `CanUserDismiss()`, `IsVisibleInUI()`, `IsValidForPhase()`, `IsLocationValid()`, `GetLocation()`, `IsTargetValid()`, `GetTarget()`, `Activate(true)`, and `GetValue(key)`.
  - Vanilla only creates notification rail entries when the notification is visible in UI, has a displayable icon, is the first visual entry for that type/stack, and is not an end-turn blocker. End-turn blockers are normally displayed by `ActionPanel`; CAI handles them outside the notification center.
  - `SetNotificationText(...)` sets the expanded title from `Locale.Lookup(pNotification:GetMessage())` and summary from `Locale.Lookup(pNotification:GetSummary())`.
  - Left-click activation calls `pNotification:Activate(true)`, which later raises `Events.NotificationActivated`; vanilla type-specific activate handlers then open the correct screen or look at/select the target.
  - Right-click dismiss calls `NotificationManager.Dismiss(...)` only when `pNotification:CanUserDismiss()` is true.
  - Stacked notifications share one visual row by type name. `LeftArrow` / `RightArrow` move the active index and either call `LookAtNotification(...)` or, for `COMMAND_UNITS`, select previous/next ready unit. The count badge's hidden `DismissStackButton` right-click dismisses every dismissible notification in that stack.
  - Wrong-phase notifications keep a visual row but left-click does nothing, right-click can dismiss, and the icon background switches to `IconBGInvalidPhase`.
  - Type-specific vanilla activation handlers include research/civic choosers, production, government/policies, raze city, pantheon/religion/artifact/great people/envoys, espionage escape route, continent lens, boost/completed popups, relic popup, PBC popups, user-defined notification activation, city ranged attack, command units, and default look-at/select behavior.
  - CAI access uses `NotificationPanel_CAI.lua`, a wrapper around vanilla `NotificationPanel.lua`.
  - `Ctrl+N` opens a transient `Treeview` notification center through the `NotificationPanelOpenList` input action.
  - Single notifications are direct tree leaves; grouped notification types become expandable parent nodes with one child per live notification.
  - Leaf `Enter` / `Space` calls `pNotification:Activate(true)` when valid for the current phase.
  - Leaf `Delete` calls `NotificationManager.Dismiss(...)` when `CanUserDismiss()` is true.
  - Group `Shift+Delete` dismisses all dismissible notifications in that group.
  - Notification leaf widget ids are `tostring(notificationID)`, matching the live notification instance id for direct lookup.
  - `OnNotificationDismissed(...)` is wrapped after including vanilla `NotificationPanel.lua`; the wrapper preserves vanilla removal and removes the matching tree leaf with `Treeview:GetChildById(tostring(notificationID), true)` when the CAI tree is open.
  - `OnNotificationAdded(...)` is wrapped after including vanilla `NotificationPanel.lua`; after vanilla creates/updates its rail entry, CAI adds the new notification to the open tree in place when the notification center is open.
  - Live tree updates remove the `LOC_CAI_NOTIFICATION_EMPTY` placeholder, add direct leaves with `tree:AddChild(...)`, append children to existing grouped notification nodes, and convert a same-type direct leaf into a grouped node when a second notification of that type arrives.
  - CAI ties notifications back to vanilla's own `GetNotificationEntry(playerID, notificationID)` lookup and requires the returned entry to have a live `m_Instance`, matching the actual vanilla rail. This intentionally excludes end-turn blockers, which ActionPanel should handle.
  - Rebuilding the tree filters out notification ids that no longer have a vanilla rail instance, plus `IsDismissed()` / `IsExpired()` when those optional methods are available, so stale ids still returned by `NotificationManager.GetList(...)` are not reintroduced.
  - Activating a leaf closes the notification center before calling `pNotification:Activate(true)`, so vanilla action/camera behavior runs after CAI focus is gone.
  - Vanilla `LookAtNotification(...)` syncs the CAI cursor through `LuaEvents.CAICursorMove(x, y)` when a notification has a valid location or target, except while the CAI notification center is open. Browsing the tree should not move the cursor.
  - `NotificationPanel_CAI.lua` also speaks new rail notifications from `Events.NotificationAdded` as `LOC_CAI_NOTIFICATION_ALERT`, followed by summary and `LOC_CAI_NOTIFICATION_AT_LOCATION` when coordinates are available.
  - Notification add speech is de-duplicated by notification id until dismissal because Civ VI can surface the same notification id through the add path more than once.
- Vanilla `ActionPanel.lua` / `ActionPanel.xml`:
  - Main purpose is the bottom-right end-turn/action button plus end-turn blockers. It reads blockers from `NotificationManager.GetFirstEndTurnBlocking(playerID)` and `NotificationManager.GetAllEndTurnBlocking(playerID)`.
  - Known blocker types are mapped in global `g_kMessageInfo` to localized message text, tooltip text, icon name, and optional sound. Covered blockers include units/stacked units, research, civic, policy slot, government change, raze city, production, pantheon/religion/belief, envoys, great person, spy escape route/dragnet priority, and artifact choice.
  - Primary controls are `EndTurnButton`, `EndTurnButtonLabel`, `EndTurnText`, and `CurrentTurnBlockerIcon`. The icon uses `SetIcon(icon)` and `EndTurnText` is truncated through `TruncateStringWithTooltip(...)`.
  - Extra blocker controls are `TurnBlockerButton2`, `TurnBlockerButton3`, and `TurnBlockerButton4`. Overflow blockers are built from `TurnBlockerInstance` rows under `OverflowStack`, opened by `OverflowCheckbox`.
  - The count badge `CountImage` / `Count` shows when there are two or more notifications of the active blocker type.
  - Left-clicking the main button calls `DoEndTurn()`. Left-clicking a secondary/overflow blocker calls `DoEndTurn(blockerType)`. Right-clicking the main button only dismisses the city ranged attack notification in the special city-ranged-attack state.
  - `DoEndTurn(...)` can unready a multiplayer turn, select next ready unit, select a ranged-attack city and enter `InterfaceModeTypes.CITY_RANGE_ATTACK`, request `ActionTypes.ACTION_ENDTURN`, or raise `LuaEvents.ActionPanel_ActivateNotification(pNotification)` for generic blockers.
  - The panel has special non-notification states for auto-end-turn units with moves remaining and city ranged attacks, controlled by user options `AutoEndTurn` and `CityRangeAttackTurnBlocking`.
  - Waiting states set `EndTurnText` and tooltip to please-wait, waiting-for-player, Play-By-Cloud uploading/uploaded, or autoplay text. Multiplayer can include other active human player names and the unready-turn tooltip.
  - The era display uses `EraContainer`, `EraIndicator`, `EraToolTipArea1`, `EraToolTipArea2`, and `EraPipInstance`; `PopulateEraData()` builds pips from `GameInfo.Eras()`, and `RealizeEraIndicator()` rotates the indicator to the local player's era.
  - Turn timer display uses `TurnTimerContainer`, `TurnTimerMeter`, `TurnTimerLabelBG`, and `TurnTimerLabel`; `OnTurnTimerUpdated(...)` sets progress, active/inactive color, tooltip, countdown text, and low-time tick sounds.
  - Observer mode shows `ObserverButtonLabel` and `EndObserverModeButton`, both raising `LuaEvents.ActionPanel_EndObserverMode()`.
  - Input paths include `Input.GetActionId("EndTurn")`, `Events.InputActionTriggered`, and `ContextPtr:SetInputHandler(OnInputHandler, true)`. Enter triggers normal end turn; Shift+Enter forces `ActionTypes.ACTION_ENDTURN` with `REASON = "UserForced"` when no tutorial is running.
  - Tutorial-only controls include `TutNotificationPointer`, many `TutSelectEndTurnAction*` callouts, and `TutorialSlowTurnEnableAnim`.
- CAI `Treeview` / `TreeviewItem` widgets:
  - `Treeview` provides shared Left/Right/Return bindings. Right expands the focused node or moves to its first child; Left collapses the focused node or moves to its parent; Return toggles the focused node.
  - Screens should not add their own expand/collapse bindings. Use `TreeviewItem.OnToggleExpanded` to synchronize vanilla visual state when expansion changes.
  - `TreeviewItem:GetValue()` announces `LOC_CAI_TREEVIEW_EXPANDED`, `LOC_CAI_TREEVIEW_COLLAPSED`, and `LOC_CAI_TREEVIEW_ITEM_COUNT` for expanded nodes.
- CAI widgets require an id at construction: `mgr:CreateUIWidget(id, type, props)`.
  - Use stable semantic ids for widgets that need direct lookup, for example `CAITopPanelYieldInfoTree`.
  - Use `mgr:GenerateWidgetId("CAIScreenWidgetType")` for repeated rows/items that must be unique but do not need stable lookup.
  - Widget ids are expected to be globally unique among live widgets.
  - `widget:GetId()` returns the widget id assigned at construction.
  - `widget:GetChildById(id, recurse)` returns a direct child by id, or recursively searches descendants when `recurse` is true.
  - `mgr:GetWidgetById(id, recurse)` returns the live widget or nil, searching from the active stack root backward.
  - `mgr:RemoveFromStack(id)` closes and destroys a pushed stack-root widget by id.
  - `mgr.CAISettings.ValidateWidgetIds = true` enables attachment-time duplicate-id warnings for debugging without adding normal runtime lookup-table state.

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
