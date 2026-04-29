# Project Status: Civ VI Accessibility Integration (CAI)

## Overview
Lua accessibility mod for Civilization VI. Adds TTS/screen reader support for blind players by replacing and extending native UI screens. Authors: FlatArther and Hamada.

**Mod folder:** `%USERPROFILE%\Documents\My Games\Sid Meier's Civilization VI\Mods\CivVi-Accessibility-Integration\`
**Source:** `src/` -> `CivViAccess.modinfo`

---

## What's Built

### Core Infrastructure (complete)
- `caiUtils.lua` - `Speak()`, `WrapFunc()`, `HijackTable()`, utility helpers
- `UIScreenManager.lua` - widget stack, focus tracking, divergence-aware speech, input routing, global CAISettings for speech element control
- `baseWidget.lua` - `UIWidget` base class with child/parent/input management, `SetValue()` with `OnValueChanged` callback, `SpeakElements()` with per-widget SpeechSettings, `GetVisiblePosition()` for hidden-aware positioning, `GetInfoStrings()` returning label/role/value/position/state/tooltip, `InsertChild(index, widget)` for positional child insertion
- `widgetTemplates.lua` - widget templates: Panel, List, HorizontalList, SubMenu, Button, DropdownMenu, Slider, Checkbox, Edit, Dialog, Tab, TabBar, MenuItem, StaticText, GameView, InterfaceMode, Treeview, TreeviewItem. Global nav helpers live in `widgetTemplateHelpers.lua`
- `ideHelpers.lua` - Lua type annotations for IDE

### In-Game (partial)
- `worldInfo.lua` - full plot info system (`CAIPlotInfo:RequestPlotInfo()`), reads terrain/features/resources/buildings/yields
- `navCursor.lua` - hex grid cursor (`CAICursor`), moves by direction, snaps to units
- `caiIngame.lua` - event listeners: cursor move -> speaks plot info, unit selection -> speaks unit name/coords
- `WorldInput_CAI.lua` - replaces `WorldInput`; routes keyboard input through UIScreenManager; handles interface modes (for example `MOVE_TO`). All strings localized
- `ActionPanel_CAI.lua` - replaces `ActionPanel`; hooks `CAIEndTurn` event to trigger end turn
- `AdvisorPopup_CAI.lua` - replaces `AdvisorPopup`; uses Dialog type for main panel, StaticText for body
- `InGameTopOptionsMenu_CAI.lua` - replaces `InGameTopOptionsMenu` (content unknown, needs review)
- `ResearchChooser_CAI.lua` - partial replacement for `ResearchChooser`; wraps `View` / `AddAvailableResearch` / `RealizeCurrentResearch`. Panel is split into two lists - an interactive available research list (Enter chooses) and a view-only queue list with its own detail edit
- `ProductionPanel_CAI.lua` - in active development; Treeview-based accessibility layer added, but still needs in-game verification
- `InGame.lua` - root in-game context (modified from vanilla). All strings localized

### Frontend (partial)
- `IntroScreen.lua` - intro screen (content unknown)
- `MainMenu.lua` - main menu with full accessibility: MenuItem widgets, SubMenu groups for Help/Play Now, localized labels
- `AdvancedSetup.lua` - Create Game screen with tab bar (Basic/Advanced views), static pulldowns, leader selection, dynamic game parameters, player management
- `FrontEndPopup.lua` - frontend popup (content unknown)

### Shared
- `PopupDialog.lua` - shared popup dialog widget using Dialog type, StaticText for text, Button for actions
- `Options.lua` - full options screen accessibility (all 7 tabs: Game, Graphics, Audio, Interface, Application, Language, KeyBindings)

### Data
- `data/hotkey_config.xml` - custom action IDs
- `Text/en_US/cai_text_ui.xml` - localization for widget roles, states, CAI UI labels, and ProductionPanel strings

### Docs
- `docs/game-api.md` - API reference for input, locale, controls, events, ExposedMembers, CAI custom API, and Civ VI Lua context notes
- Vanilla `ActionPanel.lua` / `ActionPanel.xml` analysis added to `docs/game-api.md`: end-turn blockers, secondary/overflow blocker controls, era indicator, turn timer, observer mode, input paths, and generic `LuaEvents.ActionPanel_ActivateNotification(...)` behavior are now documented.

### Scripts
- `scripts/Deploy-Mod.ps1` - legacy deploy script; `src/` is now symlinked into the mod folder so no copy step is normally needed

---

## Current Work (2026-04-14): AdvancedSetup.lua

### Status
- Verified by user as working fine
- Earlier restructuring issue is closed

### Summary
- Basic and Advanced tabs are accessible
- Section-based navigation in Advanced view works
- ESC/back behavior works from either view

---

## Current Work (2026-04-23): ProductionPanel accessibility follow-up

### What's done
- Replaced the remaining generic populate-wrapper helper that used `rawget(_G, ...)`
- Production panel now captures vanilla `Populate*` helpers explicitly one by one (`PopulateWonders`, `PopulateProjects`, `PopulateUnits`, `PopulateDistrictsWithNestedBuildings`, `PopulateDistrictsWithoutNestedBuildings`)
- Documented the Civ VI Lua limitation in `docs/game-api.md`: prefer direct function wrapping after `include(...)`, not `_G` lookup
- `Treeview` owns shared Left/Right/Return expand-collapse bindings; screen trees only add screen-specific activation bindings where needed
- ProductionPanel CAI layer was rewritten to mirror vanilla interaction flow more closely: Enter maps to vanilla left click, Shift+Enter maps to vanilla right click, and focus reuses vanilla hover behavior
- Queue and Manager are now separate accessible tabs instead of treating Queue like another production list
- Expand/collapse behavior lives on the generic `Treeview` template, with screen-specific nodes reacting through `OnToggleExpanded` where needed
- Added missing localization entries for ProductionPanel CAI strings, Treeview roles, and search feedback
- Production panel title now uses vanilla `LOC_HUD_CHOOSE_PRODUCTION`
- Removed the local ProductionPanel markup-stripping helpers so row labels, tooltips, and detail text now use the raw vanilla strings directly
- `WidgetTemplateHelpers:GetContainerDefChild(...)` now respects a widget's `DefaultIndex` when there is no focused child, instead of always starting from the first visible child
- `ProductionPanel_CAI.lua` now sets the tab bar `DefaultIndex` from the currently selected tab so reopening the CAI production panel starts on the active vanilla tab
- CAI no longer exposes separate Queue and Manager tabs; both vanilla queue modes are merged into one accessible queue tab
- The CAI queue tab is now intended as queue management only: current production stays separate and queued items start at build queue index `1`
- Queue management now uses widget input bindings directly on the CAI tree and queue rows instead of bindable hotkey config actions
- On the normal CAI Production tab, `Ctrl+Enter` now queues a production item by temporarily using vanilla's queue-open insertion path instead of sending a custom build request
- Added focused-row queue controls:
  - `Enter` / `Space` are dummy activation only on queue rows
  - `Delete` removes the focused queue item
  - `Delete` on current production removes current production
  - `Shift+Up` / `Shift+Down` move the focused queue item earlier or later in the queue
- Added spoken queue feedback for remove, move up, move down, current-production remove, top/bottom reorder bounds, and `Ctrl+Enter` queueing from the Production tab
- The Queue tab no longer shows the production tree; it now uses a dedicated list with current production first, followed by queued items
- Queue list children are now dummy CAI `Button` widgets because vanilla queue selection is a single-item pick-up mode, not checkbox or multi-select state
- Queue focus is no longer restored with direct `SetFocus(...)` calls; move and remove now preserve focus by queue-list child index through `List:SetFocusedChild(...)`
- Added generic `UIScreenManager` focus-path APIs for nested widgets: flat lists restore by child index, while trees restore by a captured child-index path from root to focused leaf
- Production tree tabs no longer rebuild their CAI body on every vanilla `View()` refresh; CAI now rebuilds only when the active tab or city context changes, while the Queue tab still rebuilds on queue refreshes
- Production tab `OnFocusEnter` now always runs the matching vanilla tab-selection helper, but only rebuilds CAI content when the focused tab actually changed
- Production read-only detail text now deduplicates by focused widget key so tab/shift-tab reentry on the same item does not recompute and reannounce identical detail content
- Removed redundant queue-tab `RebuildBody()` calls from several wrapped vanilla helpers so queue remove/swap/selection changes no longer clear and rebuild the CAI queue multiple times per action
- Fixed a general UI manager child-destruction bug in `baseWidget.lua`: `ClearChildren()` / `Destroy()` no longer iterate a mutating `Children` table with `ipairs`, which could skip widgets and leave stale focus references behind after rebuilds
- ProductionPanel tab-focus rebuilds now opt out of tree focus restoration, preventing stale tree focus from announcing current production while focus is still in the tab bar
- ProductionPanel queue-list rebuilds now preserve the currently focused queue-list child when no explicit post-action focus target is pending
- Removed CAI's extra `CityProductionQueueChanged` refresh listener because vanilla already refreshes the panel on that event, causing duplicate queue rebuilds after remove/reorder actions
- Removed CAI queue selection mirroring from `ProductionPanel_CAI.lua`; Delete and move actions now operate only on the focused queue row
- Queue item rows no longer expose a tooltip because vanilla queue rows do not provide useful queue-item detail beyond the item name
- Traced vanilla `ProductionManager.lua`: the multi-queue tab is a separate UI context opened via `LuaEvents.ProductionPanel_OpenManager`, with its own city list, filter pulldown, per-city current production, queue slots, and trash buttons
- Updated `navCursor.lua` coordinate handling: `CAICursor:SetCoords(x, y, wrapCoords)` now bounds-checks before `Map.GetPlot(...)` so Civ VI's implicit X wrapping is not used. When `wrapCoords` is true, CAI manually wraps both X and Y using `Map.GetGridSize()`. Public cursor move LuaEvents now accept the same optional `wrapCoords` flag.

### Needs testing
1. Enter on production and purchase rows should commit again
2. Shift+Enter on rows with a `Type` should open Civilopedia
3. Enter on non-leaf tree items should toggle expand/collapse
4. Left and Right on the tree should collapse, expand, move to parent, or move to first child appropriately
5. Category headers, queue labels, detail label, and spoken choose/purchase/remove announcements should all localize correctly
6. The single CAI queue tab should act as queue management only, with current production separate from queued items and no separate CAI manager tab shown
7. Unit corps/army subtree toggles should stay in sync with vanilla `OnCorpsToggle`
8. Reopen the CAI production panel from each vanilla tab and verify focus starts on that same selected tab
9. Verify the CAI production panel title now speaks `LOC_HUD_CHOOSE_PRODUCTION`
10. Verify removing the local markup stripping does not make row labels, tooltips, detail text, or tab labels regress in spoken output
11. In the merged queue tab:
    - `Enter` / `Space` on queue rows should not toggle selection or announce enabled/disabled
    - `Delete` should remove the focused queue row
    - `Delete` on current production should remove current production
    - `Shift+Up` / `Shift+Down` should reorder queue rows and announce movement
    - moving the first or last queue item further outward should not change the queue and should announce that it is already at the boundary
12. On the CAI Production tab, `Ctrl+Enter` on producible rows should append them to the city queue without opening a duplicate production browser in the Queue tab
13. Verify the Queue tab now presents a simple list with current production first and that it no longer exposes the production tree there
14. Verify queue-item removal preserves focus by list position without label-based matching, including repeated deletes near the end of the queue
15. Verify queue actions are driven by widget `AddInputBinding` / `AddInputBindings` only and that no new production queue actions were added to the bindable hotkey menu
16. Verify queueing from the Production tab no longer rebuilds the production tree or announces an unrelated row before returning focus to the queued item
17. Verify tab/shift-tab back onto the active tab does not rebuild content, and refocusing the same widget does not recompose identical read-only detail text
18. Verify queue remove/swap no longer causes a second stray rebuild that drops focus to `nil` after an initial correct announcement
19. Verify rebuilt lists/trees no longer leave stale focus behind after `ClearChildren()`, especially in the ProductionPanel queue list
20. Verify switching CAI ProductionPanel tabs while focus is in the tab bar announces only the newly focused tab, not current production or another tree item
21. Verify deleting a queued item from the CAI queue list keeps focus at the intended list position after the queue-change event settles, including pressing Down immediately afterward
22. Verify Queue tab rows are spoken as buttons, not checkboxes; they should not speak enabled/disabled and Delete should remove the focused row
23. ProductionManager / multi-queue accessibility still needs implementation: filter pulldown, city rows, per-city current production, per-city queue slots, and trash buttons

---

## Known Gaps / Next Steps

- [ ] Test frontend/shared inline patch layout: fresh base files in `src/UI/frontEnd` and `src/UI/shared` now contain CAI code directly inside marked accessibility regions before startup
- [ ] Verify `ProductionPanel_CAI.lua` in game and fix remaining interaction issues
- [ ] Review `InGameTopOptionsMenu_CAI.lua` - unclear what CAI additions exist
- [ ] Review `IntroScreen.lua`, `FrontEndPopup.lua` - unclear what CAI additions exist
- [ ] Review `data/hotkey_config.xml` for completeness
- [ ] No automated test harness
- [ ] In-game UI screens beyond WorldInput/ActionPanel/AdvisorPopup still need accessibility work
- [ ] MapSelect.lua - map picker popup exists but status is still unknown

---

## Pending Questions / Notes

- ProductionPanel follow-up: `_G`/`rawget` is not safe in Civ VI UI Lua here; explicit one-by-one wrapping is the chosen pattern
- Tree widgets use generic template bindings for Left/Right/Return expand-collapse; consumers add only screen-specific activation bindings and react through `OnToggleExpanded`
- Tutorial input tracing:
  - Vanilla tutorial flow can intentionally consume keys through `AdvisorPopup.lua` while the advisor/metapopup is visible, and through `UITutorialManager` overlay/control gating during detailed tutorial steps.
  - `OPEN_CITY_PANEL` enables only `ChangeProductionCheck` and completes via `CityPanel_ProductionOpen` -> `ProductionPanelViaCityOpen`.
  - CAI-side issue fixed: `CityPanel_CAI.lua` called `mgr:OnHandleInput(inputStruct)`, but `UIScreenManager` exposes `HandleInput(input)`. The stray per-key `Speak(ContextPtr:GetID())` debug output was removed too.

## Current Work (2026-04-24): CityPanel accessibility

### What's done
- Added `UI/inGame/CityPanel_CAI.lua` as a wrapper around vanilla `CityPanel.lua`
- Removed the previous CAI city-panel widget tree from `CityPanel_CAI.lua`; the file is now a thin data-helper layer on top of vanilla `CityPanel.lua`
- Added `ExposedMembers.CAIInfo.CityInfo` helper functions for:
  - `Summary`
  - `BuildingCount`
  - `ReligiousFollowersCount`
  - `AmenitiesSummary`
  - `HousingSummary`
  - `GrowthSummary`
  - `ProductionSummary`
- Added city yield helper functions for future input bindings:
  - `VisibleYields`
  - `NormalFocusYields`
  - `FavoredFocusYields`
  - `IgnoredFocusYields`
- Added selection info input actions in `src/data/hotkey_config.xml`:
  - `ReadSelectionSummary` on `~`
  - `ReadSelectionInfo1` through `ReadSelectionInfo10` on `Shift+1` through `Shift+0`
- `CityPanel_CAI.lua` now listens to `Events.InputActionTriggered` and maps those selection actions to city helper keys through a lookup table, then speaks the returned info via `Speak()`
- Added `ExposedMembers.CAIInfo:RequestCityInfo(cityOrCityID, requestedKeys, playerID)` to return requested localized info strings, defaulting to the selected city
- City info helpers now build directly from `GetCityData(city)` using vanilla loc keys / formatting logic instead of reading text back from controls
- Growth and production helpers now also include the visible bar percentages from the vanilla city panel (`CurrentFoodPercent`, `FoodPercentNextTurn`, `CurrentProdPercent`, `ProdPercentNextTurn`)
- Fixed the empty production case so it no longer says `0 turns until completed`
- Added CAI loc tags for percentage labels where vanilla did not provide suitable city-panel speech labels:
  - `LOC_CAI_CURRENT_PROGRESS`
  - `LOC_CAI_NEXT_TURN_PROGRESS`
- Documented the `GetCityData(city)` / `CityManager.GetCity(playerID, cityID)` pattern in `docs/game-api.md`
- Added a new `CITY` hotkey category in `src/data/hotkey_config.xml`
- Added unbound city action input IDs for non-yield city-panel actions and a placeholder `CityChangeCitizenYieldFocus` action
- `CityPanel_CAI.lua` now maps the non-yield city action inputs to the same vanilla helpers/check handlers used by the clickable city-panel buttons
- Added an unbound `SelectionActions` input action in `src/data/hotkey_config.xml`
- Refactored city action mappings in `CityPanel_CAI.lua` so each action entry is `{ helper, IsEnabled }`
- `SelectionActions` now opens a CAI list widget built from the `CITY` input category, using input action names/descriptions for labels and tooltips while filtering out actions that the vanilla city panel would not currently show
- City summary now includes the selected city's coordinates immediately after the city name
- `RequestCityInfo` now resolves either the selected city or a `cityID` through `CityManager.GetCity(playerID, cityID)`, then passes the city table into `GetCityData(city)`
- Added a city-selection listener in `CityPanel_CAI.lua` that speaks the `Summary` info when a city becomes selected

### Needs testing
1. Call `ExposedMembers.CAIInfo:RequestCityInfo(nil)` with a city selected and verify the summary/buildings/religion/amenities/production strings are spoken as expected
2. Call `ExposedMembers.CAIInfo:RequestCityInfo(cityID, {"Summary"}, playerID)` and verify non-selected city lookup works for local-player cities
3. Confirm the production helper stays in sync when current production changes, including "nothing produced"
4. Confirm amenities, followers, housing, growth, and building counts match the vanilla city panel values
5. Confirm the yield helpers match the city panel:
   - `VisibleYields` should return all six visible yields with signed values
   - `NormalFocusYields`, `FavoredFocusYields`, and `IgnoredFocusYields` should filter those same yield/value pairs by vanilla `YieldFilters`
6. Confirm the new selection hotkeys fire in the city panel:
   - `~` should speak `Summary`
   - `Shift+1` through `Shift+0` should speak the mapped helper outputs in order
7. Bind the new `CITY` hotkeys in game and verify they trigger the same vanilla actions as clicking the city panel buttons:
   - overview, buildings, religion, amenities, housing, citizens/growth
   - purchase tile, manage citizens, purchase with gold, purchase with faith, change production
8. Confirm the `CITY` category appears in Key Bindings and that the new actions are intentionally unbound by default
9. Bind `SelectionActions` and verify it opens the city action list with only currently available actions, using each action name as the spoken label and its description as the tooltip
10. Verify the spoken city summary now says city name, coordinates, and labeled population in that order
11. Verify selecting a city triggers the CAI `OnCitySelectionChanged` listener and speaks the summary once without duplicating vanilla announcements unexpectedly

## Current Work (2026-04-25): Frontend/shared vanilla Lua refresh

### What's done
- Refreshed full replacement frontend/shared Lua files from the current Steam install at `C:\Program Files (x86)\Steam\steamapps\common\Sid Meier's Civilization VI\Base\Assets\UI`
- Reinserted each marked CAI accessibility block (`--#Accessibility integration` through `--#End of accessibility integration`) above the final startup call:
  - `src/UI/frontEnd/AdvancedSetup.lua`
  - `src/UI/frontEnd/CityStatePicker.lua`
  - `src/UI/frontEnd/FrontEnd.lua`
  - `src/UI/frontEnd/FrontEndPopup.lua`
  - `src/UI/frontEnd/IntroScreen.lua` before `Startup();`
  - `src/UI/frontEnd/LeaderPicker.lua`
  - `src/UI/frontEnd/MainMenu.lua`
  - `src/UI/frontEnd/MapSelect.lua`
  - `src/UI/frontEnd/MultiSelectWindow.lua`
  - `src/UI/frontEnd/TutorialSetup.lua`
  - `src/UI/shared/LoadGameMenu.lua`
  - `src/UI/shared/Options.lua`
  - `src/UI/shared/PopupDialog.lua` at end of file because vanilla has no final `Initialize();`
- Confirmed each refreshed file has exactly one CAI accessibility block
- Did not touch `src/UI/inGame` partial replacement files
- Restored accessibility-related code that lived outside the marked CAI blocks:
  - `src/UI/shared/Options.lua` keeps the top-level `include("UIScreenManager")`
  - `src/UI/frontEnd/IntroScreen.lua` keeps the accessibility-oriented `AcceptEULA();` startup bypass
- `src/UI/shared/LoadGameMenu.lua` intentionally matches the updated vanilla `KeyHandler`; the old outside-block arrow-key file-list navigation and Delete handling were not kept
- Left the old hardcoded `Speak("Multiplayer popup")` out intentionally

### Needs testing
1. Launch to frontend and verify main menu, popups, setup screens, load game, options, leader/city-state/map/multiselect pickers, and tutorial setup still open without Lua errors
2. Verify `IntroScreen.lua` still skips the inaccessible startup/EULA screen as intended
3. Verify `LoadGameMenu.lua` keyboard behavior with the updated vanilla `KeyHandler` plus the CAI block

## Current Work (2026-04-25): My2K frontend accessibility

### What's done
- Added `src/UI/FiraxisLive/My2K.lua` as a full frontend replacement copied from the Steam install at `C:\Program Files (x86)\Steam\steamapps\Sid-Meiers-Civilization-VI\Base\Assets\UI\FiraxisLive\My2K.lua`
- Registered `UI/FiraxisLive/My2K.lua` in `src/CivViAccess.modinfo` under `<Files>` and the frontend `ImportFiles` action
- Added a marked CAI accessibility block to My2K before `FiraxisLive.SetUIReady()`
- My2K now replaces the legacy 3-argument input handler with a CAI `InputStruct` handler while preserving vanilla Escape behavior through `m_bESCEnabled` and `m_cancelFunction`
- My2K accessible dialogs are built through `WidgetTemplateHelpers:MakeGeneralDialog(...)`
- Added accessible dialog coverage for:
  - main My2K account menu
  - unlink confirmation
  - login
  - new-user email
  - username/email
  - legal document list
  - legal document detail
  - message dialog
  - logout confirmation
- Dialog content uses live vanilla control text and edit-box values; action buttons read live disabled state from the vanilla buttons
- Documented the My2K/FiraxisLive frontend popup pattern in `docs/game-api.md`

### Needs testing
1. Open My2K from the frontend main menu and verify no Lua errors
2. Verify Tab/Shift+Tab moves through dialog rows and action buttons, Up/Down moves dialog rows, and Left/Right moves within the action row
3. Verify Escape cancels only where vanilla allows it, and does not cancel the legal consent screen
4. Verify login email/password entry works with CAI edit controls, including typing, backspace, cursor movement, and Enter commit
5. Verify invalid email keeps submit buttons disabled and valid email enables them
6. Verify legal document list exposes every document and opens the selected document
7. Verify legal document detail can be read and OK returns to the legal list
8. Verify pending login/sign-up/unlink actions speak disabled state after activation
9. Verify successful My2K activation/link events close the popup and return safely to the main menu

## Investigation (2026-04-25): Tutorial native access violation at TURN_BASED_B

### Findings
- User reports a deterministic native access violation, not a Lua crash, when clicking OK during `item_turnBasedB` in `TutorialScenarioBase.lua`
- `Lua.log` from the latest checked run had no Lua traceback; it ended after tutorial startup and city selection
- Windows Application logs show repeated `CivilizationVI.exe` crashes with exception `0xc0000005` at fault offset `0x0000000000078abb`
- `TURN_BASED_B` OK calls `LuaEvents.AdvisorPopup_ShowDetails(advisorInfo)`
- `TutorialUIRoot.OnAdvisorPopupShowDetails()` calls `RaiseDetailedTutorial(item)`
- Because `TURN_BASED_B` has no `UITriggers`, `RaiseDetailedTutorial()` immediately deactivates it and chains to `TURN_BASED_C`
- `TURN_BASED_C` enables the ActionPanel tutorial target (`ActionPanel`, `TutorialSelectEndTurn`) and disables `ChangeProductionCheck`
- Documented this flow in `docs/game-api.md`

### Next debug steps
1. Reproduce once with `CAI_AdvisorPopup` replacement disabled in `src/CivViAccess.modinfo`
2. If it still crashes, reproduce with `CAI_ActionPanel` replacement disabled
3. If disabling one replacement fixes the crash, instrument only that file around advisor hide/show or ActionPanel tutorial activation

## Current Work (2026-04-25): ResearchChooser vanilla alignment

### What's done
- Removed CAI's custom Shift+Enter research queueing from `src/UI/inGame/ResearchChooser_CAI.lua`
- Kept the view-only research queue list/detail so queued items remain inspectable when vanilla exposes them
- Removed manual ResearchChooser focus preservation/restoration (`FocusedChild` clearing, hash-based refocus, and `mgr:SetFocus(...)`) so UIScreenManager owns focus behavior
- Updated stale comments that described the removed queue and focus behavior

### Needs testing
1. Open ResearchChooser and verify Enter still chooses the focused available research item
2. Verify Shift+Enter no longer queues research from the chooser
3. Verify queued/current research remains visible in the read-only queue list
4. Verify opening and refreshing ResearchChooser uses the normal UIScreenManager focus behavior without stray focus jumps

## Current Work (2026-04-27): UIScreenManager priority stack

### What's done
- Finished the root-widget priority stack in `src/UI/uiManager/UIScreenManager.lua`
- Added shared `UIWidgetPriority` levels for low/normal/high roots
- Added deterministic stack sorting: priority first, then push order as the equal-priority tie breaker
- Removed the extra priority normalization helper; `Push` now defaults nil priority directly to `UIWidgetPriority.Normal`
- Fixed first-push focus initialization by initializing `CurrentPath` and always focusing the sorted active root when it changes
- Pushing a lower-priority root now leaves the already-focused active root alone, with no refocus or duplicate announcement
- Guarded `SetFocus(...)` / `SetFocusPath(...)` so lower-priority roots cannot steal active focus while a higher-priority root is on top
- Added optional `mgr:Pop(widget)` support for closing a specific non-active root; plain `mgr:Pop()` still removes the active root
- Updated `Clear()` so it destroys every root widget in the stack, not only the current top root
- Documented the priority stack behavior in `docs/game-api.md`

### Needs testing
1. Push two same-priority roots and verify the later push receives focus and pops back to the earlier root
2. Push a lower-priority root while a higher-priority root is active and verify focus stays on the higher-priority root
3. Push a high-priority root over a normal-priority root and verify focus moves to the high-priority root, then returns when popped
4. Verify `mgr:Pop(widget)` can close a non-active lower-priority root without changing focus
5. Verify existing screens that call `mgr:Push(...)` without a priority still behave as normal-priority LIFO screens

## Current Work (2026-04-27): ProductionPanel tutorial gating

### What's done
- Traced vanilla tutorial gating:
  - `TutorialUIRoot.RaiseDetailedTutorial(item)` calls `UITutorialManager:ShowControlsByID(...)` for `UITriggers`
  - It then calls `UITutorialManager:EnableControlsByIdOrTag(...)` for each `EnabledControls` value and disables any `DisabledControls`
  - Production tutorial steps enable production rows by `UITutorialManager:GetHash(item.Type)`, for example `UNIT_WARRIOR`, `UNIT_BUILDER`, and `BUILDING_MONUMENT`
- `ProductionPanel_CAI.lua` now exposes live vanilla row control state through each CAI row widget's `IsHidden` / `IsDisabled` methods
- CAI production row activation now relies on those widget disabled predicates, so disabled rows do not activate through Enter
- Hidden rows and tabs are still built as widgets; UI manager navigation skips them through their `IsHidden` methods
- Production tab widgets now read hidden/disabled state from both full and mini vanilla tab controls where Civ VI has both, so purchase with gold/faith tabs follow the actual visible vanilla tab variant during tutorial gating
- Added `UIWidget:GetVisibleChildren()` and hid the ProductionPanel tab bar itself when all tab children are hidden
- ProductionPanel now hides its CAI tab bar and close button during vanilla production tutorial mode because `TabContainer` and `CloseButton` sit outside the tutorial-triggered `ChooseProductionMenu` container
- ProductionPanel tutorial-mode detection now calls public `IsTutorialRunning()` instead of relying on vanilla file-local `m_isTutorialRunning` / `m_tutorialTestMode` values
- Scanned `TutorialScenarioBase.lua` production-panel steps:
  - active detailed production steps all use `SetUITriggers("ChooseProductionMenu", ...)`
  - each enables a specific production item hash such as `UNIT_WARRIOR`, `UNIT_BUILDER`, `BUILDING_MONUMENT`, `UNIT_SETTLER`, `UNIT_SLINGER`, `DISTRICT_CAMPUS`, or `BUILDING_LIBRARY`
  - no active production step enables `TabContainer`, `TabRow`, purchase tabs, queue tab, or `CloseButton`
- `Ctrl+Enter` queue insertion remains unavailable while vanilla queue support is disabled for tutorial mode
- Documented the live-control tutorial-state pattern in `docs/game-api.md`

### Needs testing
1. In the tutorial production step for warriors, verify CAI navigation skips production rows whose vanilla controls are hidden by tutorial gating
2. In the builder and monument tutorial production steps, verify CAI follows the vanilla hidden/disabled state for each row
3. Verify disabled production rows that vanilla still shows are spoken as disabled and do not activate
4. Verify rows hidden by vanilla, including disabled rows when disabled display is off, are skipped by CAI navigation
5. Verify normal non-tutorial production, purchase, unit corps/army expansion, and queue actions still work

## Current Work (2026-04-27): ResearchChooser live control state

### What's done
- Applied the same live-control pattern used for ProductionPanel to `ResearchChooser_CAI.lua`
- CAI now caches the vanilla instance returned by `AddAvailableResearch(...)` by research hash
- CAI research row widgets now expose:
  - `IsHidden` from the vanilla row's `TopContainer` / `Top`
  - `IsDisabled` from the vanilla row's `Top` for interactive available research rows
- Hidden research rows are still built; UI manager navigation skips them through `IsHidden`
- The Open Tech Tree and Close buttons are always built and now expose live `IsHidden` / `IsDisabled` from the vanilla controls
- Fixed the first-focus tutorial timing issue:
  - `TutorialScenarioBase.lua` opens ResearchChooser before `AdvisorPopup_ShowDetails(...)`
  - `TutorialUIRoot_CAI.lua` now emits `CAI_TutorialDetailedControlsReady` after `RaiseDetailedTutorial(item)` returns
  - `ResearchChooser_CAI.lua` delays only the tutorial-open initial `mgr:Push(...)` until that signal, so first focus reads the already-filtered vanilla control state
- Documented the ResearchChooser tutorial/live-control pattern in `docs/game-api.md`

### Needs testing
1. In the tutorial research step, open ResearchChooser from the advisor "Show me" button and verify the initial focus skips/marks disabled rows immediately, without needing to move away and back
2. Verify disabled available research rows speak disabled and do not activate
3. Verify normal non-tutorial ResearchChooser still chooses available research with Enter
4. Verify Open Tech Tree and Close button visibility follows the vanilla controls
5. Verify queued/current research rows remain read-only and inspectable

## Investigation (2026-04-28): WorldTracker controls and accessibility plan

### Findings
- Vanilla `WorldTracker.lua` is an ambient HUD stack under `WorldTrackerVerticalContainer`, not a modal screen
- Static visual sections are header, empty message, research panel, civics panel, unit list panel, chat panel, dynamic "other" panels, and tutorial goals
- Header controls:
  - `ToggleAllButton` collapses/expands the full tracker
  - `ToggleDropdownButton` opens/closes the options dropdown
- Options dropdown controls are checkboxes for chat, civics, research, and unit list visibility; unchecked options become disabled with `LOC_WORLDTRACKER_NO_ROOM` when vertical space is insufficient
- Research and civics panels are capability/player-state gated, use `TechAndCivicSupport.lua` to populate title, icon, turn count, progress/boost meters, boost text/icons, unlock icons, and overflow page-turner
- Research/civics icon buttons open the vanilla choosers through `LuaEvents.WorldTracker_OpenChooseResearch()` and `LuaEvents.WorldTracker_OpenChooseCivic()`
- Unit list is hidden by default; when enabled it rebuilds on unit events, filters through `UnitsSearchBox`, groups units by broad type, and unit rows select/look at the unit on click
- World Tracker is hidden during modal lens mode, force-hidden by research/civic choosers and tutorial events, and tutorial restore mode forces research/civics visible while hiding the normal collapse/options buttons
- Documented the WorldTracker pattern in `docs/game-api.md`

## Current Work (2026-04-28): WorldTracker accessibility

### What's done
- Added `src/UI/inGame/WorldTracker_CAI.lua` as a wrapper around vanilla `WorldTracker.lua`
- Registered the WorldTracker replacement in `src/CivViAccess.modinfo`
- Fixed an existing duplicate replacement id typo by renaming the ProductionPanel replacement id from `CAI_ResearchChooser` to `CAI_ProductionPanel`
- Scrapped the ambient CAI WorldTracker widget mirror; no persistent WorldTracker panel is attached to `ExposedMembers.CAI_MainGamePanel`
- `WorldTracker_CAI.lua` now follows the CityPanel/TopPanel input-action pattern:
  - `T` -> `WorldTrackerOpenResearchChooser` -> `LuaEvents.WorldTracker_OpenChooseResearch()`
  - `C` -> `WorldTrackerOpenCivicsChooser` -> `LuaEvents.WorldTracker_OpenChooseCivic()`
  - `W` -> `WorldTrackerReadSummary` -> speaks current research, current civic, and total local-player unit count
- Research and civic summary data is read from live player state through `GetResearchData()` and `GetCivicData()`, so it works regardless of visual panel visibility
- Research/civic summary lines intentionally speak only label, turns remaining, and boost status; progress, boost trigger text, and unlock summaries are not included
- `W` speaks summary lines directly without a leading "World Tracker summary" heading
- Unit count is read directly from `Players[localPlayer]:GetUnits():GetCount()`, so it does not depend on the vanilla unit list being visible or populated
- Added WorldTracker hotkey actions to `src/data/hotkey_config.xml`
- Added WorldTracker hotkey/summary localization strings to `src/Text/en_US/cai_text_ui.xml`
- Updated `docs/game-api.md` to document the hotkey-based WorldTracker pattern

### Needs testing
1. Launch a normal game and verify no Lua errors from `WorldTracker_CAI.lua`
2. Press `T` and verify the vanilla Research Chooser opens
3. Press `C` and verify the vanilla Civics Chooser opens
4. Press `W` and verify the summary speaks current research label/turns/boost status, current civic label/turns/boost status, and total unit count
5. Hide/collapse the visual World Tracker panels, then press `W` and verify research/civic/unit summaries still speak from live player state
6. Choose new research/civics and verify `W` updates immediately
7. Add/remove units and verify `W` reports the updated total unit count
8. Verify no persistent WorldTracker CAI panel appears in Tab navigation
9. Verify tutorial WorldTracker force-hide/restore events do not leave stale CAI focus or Lua errors

## Current Work (2026-04-28): TopPanel hotkey access

### What's done
- Traced vanilla `TopPanel.lua`:
  - `RefreshYields()` owns global science, culture, faith, gold, and tourism display
  - `RefreshResources()` owns the strategic-resource strip
  - base TopPanel yield buttons do not register click callbacks; only menu and Civilopedia buttons do in the base file
- Added `src/UI/inGame/TopPanel_CAI.lua` as a wrapper around vanilla `TopPanel.lua`
- Registered `TopPanel_CAI.lua` in `src/CivViAccess.modinfo`
- Added CAI input actions in `src/data/hotkey_config.xml`:
  - `Shift+T` -> `TopPanelSpeakTurnTimeDate`
  - `Y` -> `TopPanelSpeakYields`
  - `Ctrl+Y` -> `TopPanelYieldInfoList`
  - `Q` -> `TopPanelResourceInfoList`
- `Shift+T` refreshes and speaks the current turn, date, time, and full time tooltip
- `Y` speaks all TopPanel yield summaries shown by vanilla TopPanel, including gold and faith balance plus per-turn rate
- Faith yield tree nodes now mirror the TopPanel double-label display by previewing current faith balance plus faith per turn
- Removed the separate `TopPanelSpeakBalanceYields` action
- `Ctrl+Y` pushes a CAI tree containing all TopPanel yields; each yield node is the yield name plus a preview value
- `Ctrl+Y` yield nodes now contain localized category nodes:
  - gold is split into vanilla income and expense categories, each with its total in the label and localized vanilla tooltip detail lines underneath
  - science, culture, faith, and tourism put the rate/balance preview in the outer yield label, then expose vanilla localized breakdown lines as category/detail nodes using indentation/line structure, without English text parsing
- `Ctrl+Y` outer yield nodes no longer expose the full vanilla tooltip because the tree already contains the formatted breakdown
- Science, culture, tourism, gold, and faith rate previews now append localized vanilla `LOC_HUD_REPORTS_PER_TURN` text
- Confirmed the base UI/IDE helpers do not expose structured player-yield breakdown rows for science, culture, faith, or tourism; vanilla TopPanel relies on localized tooltip strings for those details
- `Ctrl+Y` yield tree and `Q` resource list now pop themselves when focus leaves their pushed widget
- Reverted the experimental `UIScreenManager:Pop(target)` idea; `Pop()` is again stack-top only
- `UIScreenManager:CreateUIWidget(id, type, props)` now requires a widget id
- Added recursive live-stack lookup through singular `GetWidgetById(id, recurse)`; ids are expected to be unique among live widgets
- Added `UIWidget:GetId()` for reading a widget's assigned id
- Added `UIScreenManager:RemoveFromStack(id)` for closing pushed stack-root widgets by unique id
- Added `GenerateWidgetId(prefix)` for repeated row/item widgets that need unique ids but do not need stable lookup
- Added opt-in duplicate-id diagnostics through `mgr.CAISettings.ValidateWidgetIds` to catch accidental duplicate ids during debugging
- Migrated all `CreateUIWidget(...)` calls in `src/` to pass ids
- Removed redundant TopPanel manager reinitialization checks; TopPanel now uses the manager captured at file load
- Tree expand/collapse behavior now comes from the shared `Treeview` template:
  - `Right` expands or descends
  - `Left` collapses or ascends
  - `Return` toggles the focused node when the focused item has no screen-specific Return action
  - tree nodes now announce `Expanded`, `Collapsed`, and visible child count through `TreeviewItem:GetValue()`
- `Q` pushes a CAI list of TopPanel strategic resources using the same inclusion rule as vanilla: non-bonus, non-luxury, non-artifact resources with amount > 0
- Did not add production to TopPanel access because vanilla TopPanel does not show global production
- Did not add local markup filtering; strings and tooltips are passed through as vanilla/localized text for future global formatting
- Documented the TopPanel pattern in `docs/game-api.md`

### Needs testing
1. Launch a normal game and verify no Lua errors from `TopPanel_CAI.lua`
2. Verify `Shift+T` speaks current turn, visible date, visible time, and time tooltip
3. Verify `Y` speaks science, culture, tourism when visible, gold, and faith; it should not speak production
4. Verify `Shift+S` no longer triggers a CAI TopPanel balance action
5. Verify `Ctrl+Y` opens a navigable yield info tree with yield nodes, localized category nodes, and detail children for science, culture, tourism, gold, and faith when available
6. Verify gold expands into income and expense categories, each category label includes its total, and each category contains the correct vanilla localized detail lines
7. Verify science, culture, faith, and tourism outer labels include the rate/balance preview and expand directly to localized category/detail nodes such as cities/envoys/etc. without English-only parsing
8. Verify outer yield nodes do not repeat the full vanilla tooltip after the label/value
9. Verify `Q` opens a navigable strategic-resource list, or "No strategic resources" when none are owned
10. Verify Escape closes the yield/resource pushed lists and returns to normal game focus

## Investigation (2026-04-28): NotificationPanel accessibility plan

### Findings
- Vanilla `NotificationPanel.lua` is an ambient right-side HUD rail under `Controls.ScrollStack`, not a modal screen
- Visual notification rows are created only for visible, icon-displayable, non-end-turn-blocking notifications; end-turn blockers are normally owned visually by ActionPanel but remain live notifications
- Each visual row includes:
  - icon/button area
  - expanded title and summary labels
  - optional stack count badge
  - optional hidden dismiss-stack hit target on the count badge
  - optional previous/next arrows for stacked notifications
  - page pips or a page-number label for large stacks
  - valid/invalid-phase icon background state
- Live notification data is available through `NotificationManager.Find(playerID, notificationID)` and `NotificationManager.GetList(playerID)`
- Useful notification APIs include `GetMessage()`, `GetSummary()`, `GetTypeName()`, `GetType()`, `GetIconName()`, `GetGroup()`, `GetCount()`, `GetEndTurnBlocking()`, `CanUserDismiss()`, `IsVisibleInUI()`, `IsValidForPhase()`, `IsLocationValid()`, `GetLocation()`, `IsTargetValid()`, `GetTarget()`, `Activate(true)`, and `GetValue(key)`
- Vanilla activation should be preserved by calling `pNotification:Activate(true)`; the engine then routes to the same type-specific handlers used by mouse activation
- Vanilla dismiss should be preserved by calling `NotificationManager.Dismiss(playerID, notificationID)` only when `CanUserDismiss()` is true
- Stacked notification previous/next behavior is type-sensitive: most stacks look at/select the next notification target, while `COMMAND_UNITS` maps previous/next to previous/next ready unit selection
- Documented the NotificationPanel pattern in `docs/game-api.md`

### Suggested CAI integration
- Add `NotificationPanel_CAI.lua` as a wrapper around vanilla `NotificationPanel.lua`
- Register it as a `ReplaceUIScript` for the `NotificationPanel` Lua context
- Add a bindable input action such as `NotificationPanelOpenList` to push a transient accessible notification list
- Build the accessible list from live `NotificationManager.GetList(Game.GetLocalPlayer())` data, grouped by `GetTypeName()` to mirror vanilla stacked rows
- Each group/list row should expose the localized title from `GetMessage()`, summary from `GetSummary()`, stack position/count, dismissible state, valid-phase state, and location/target availability
- Row controls should preserve vanilla actions:
  - `Enter` / `Space` activates the focused notification with `pNotification:Activate(true)` when valid for phase
  - `Delete` or a row action dismisses the focused notification when `CanUserDismiss()` is true
  - `Shift+Delete` dismisses all dismissible notifications in the focused stack
  - `Left` / `Right` move previous/next within the focused stack, matching vanilla stack order
- Use optional concise speech on `Events.NotificationAdded` for important new notifications, but avoid pushing persistent CAI focus or creating a permanent mirrored widget
- Do not include end-turn blockers in the notification center; ActionPanel should expose those because vanilla does not create rail instances for them

### Needs implementation
1. Add `NotificationPanel_CAI.lua` wrapper and modinfo replacement entry
2. Add notification hotkey actions and localized strings
3. Implement live notification grouping/list generation
4. Preserve vanilla activate, dismiss, stack navigation, and wrong-phase behavior
5. Test normal notifications, stacked notifications, `COMMAND_UNITS`, wrong-phase notifications, end-turn blocker exclusion, and notification refresh/local-player-change flows

## Current Work (2026-04-28): Event-driven cursor and NotificationPanel tree

### What's done
- Refactored CAI cursor movement away from `ExposedMembers.CAICursor` access
- Added public cursor movement events:
  - `LuaEvents.CAICursorMove(x, y)` for absolute movement
  - `LuaEvents.CAICursorMoveRelative(dx, dy)` for relative movement
  - `LuaEvents.CAICursorMoveDirection(direction)` for internal directional helpers
  - `LuaEvents.CAICursorSnapToUnit(unit)`, `LuaEvents.CAICursorSnapToStartPlot()`, and `LuaEvents.CAICursorSnapToPlot(plot)` for existing snap flows
- Removed hardcoded cursor navigation bindings from the `GameView` widget template
- Added remappable cursor input actions to `src/data/hotkey_config.xml`:
  - `CAICursorMoveUp` -> Up arrow
  - `CAICursorMoveDown` -> Down arrow
  - `CAICursorMoveLeft` -> Left arrow
  - `CAICursorMoveRight` -> Right arrow
- Routed those cursor input actions through the `SharedInputActions` table in `WorldInput_CAI.lua`
- Left query-style cursor access on the `UI` hijack as `UI.GetCursorPlotID()` and `UI.GetCursorPlotCoord()`
- Refactored `WorldInput_CAI.lua`:
  - CAI input action records now declare `Type = "Started"` for repeat-style inputs and `Type = "Triggered"` for one-shot inputs
  - cursor movement actions are handled from `Events.InputActionStarted`
  - path info and interface primary action are handled from `Events.InputActionTriggered`
  - all CAI `UI` table overrides are centralized in `InstallUIOverrides()`
  - CAI still initializes the main game view from wrapped vanilla `OnLoadScreenClose(...)`, preserving the load-screen boundary
  - CAI event registration/unregistration is grouped in `RegisterCAIEvents()` / `UnregisterCAIEvents()`
  - CAI camera follow now listens to `LuaEvents.CAICursorMoved(...)` and calls vanilla `UI.LookAtPlot(plot)` so the camera follows cursor movement without changing selection or interface mode
- Added `src/UI/inGame/NotificationPanel_CAI.lua` as a wrapper around vanilla `NotificationPanel.lua`
- Registered `NotificationPanel_CAI.lua` in `src/CivViAccess.modinfo` as a replacement for the `NotificationPanel` Lua context
- Added `NotificationPanelOpenList` input action, bound by default to `Ctrl+N`
- Implemented a transient CAI notification center as a `Treeview`:
  - single notifications are direct leaves
  - stacked/grouped notification types become expandable group nodes
  - leaf `Enter` / `Space` calls `pNotification:Activate(true)`
  - leaf `Delete` dismisses the notification when `CanUserDismiss()` is true
  - group `Shift+Delete` dismisses all dismissible notifications in that group
  - end-turn-blocking notifications are excluded because vanilla does not create rail instances for them
  - activating a notification closes the notification center before executing the vanilla action
- Notification tree stale-dismissal handling:
  - notification leaf widget ids now match their notification instance ids via `tostring(notificationID)`
  - added `UIWidget:GetChildById(id, recurse)` for direct child lookup in open trees/stacks
  - wrapped vanilla `OnNotificationDismissed(...)` so CAI preserves vanilla deletion and removes the matching tree leaf immediately
  - wrapped vanilla `OnNotificationAdded(...)` so an already-open notification tree updates in place when new rail notifications arrive
  - open-tree add removes the empty placeholder, appends new direct leaves, appends to existing group nodes, and converts a same-type direct leaf into a group when a stack forms live
  - tied CAI availability checks to vanilla `GetNotificationEntry(playerID, notificationID).m_Instance` so reopened trees reject ids that vanilla already released from the visible rail
  - CAI notification center now intentionally excludes end-turn blockers because vanilla tracks them without rail instances; ActionPanel should handle those separately
  - tree rebuilds also filter optional `IsDismissed()` / `IsExpired()` notification states when those methods are available
- Added notification announcement de-duplication by notification id so repeated add-path calls do not speak the same notification twice
- Wrapped vanilla `LookAtNotification(...)` so vanilla notification camera jumps also sync the CAI cursor, except while the notification center tree is open
- Added `Events.NotificationAdded` speech after vanilla add processing:
  - speaks `Alert: notification title`
  - includes summary text when available
  - includes `At x, y` when the notification exposes a location or target
- Added notification and cursor localization strings to `src/Text/en_US/cai_text_ui.xml`
- Updated `docs/game-api.md` with the event-driven cursor API and NotificationPanel tree behavior
- XML parse checks pass for `src/data/hotkey_config.xml`, `src/Text/en_US/cai_text_ui.xml`, and `src/CivViAccess.modinfo`

### Needs testing
1. Launch a game and verify no Lua errors from `navCursor.lua`, `WorldInput_CAI.lua`, or `NotificationPanel_CAI.lua`
2. Verify arrow keys still move the CAI cursor through the new input actions
3. Rebind cursor movement actions in Key Bindings and verify movement follows the new bindings
4. Verify numpad keys no longer move the CAI cursor unless explicitly rebound by the user
5. Trigger a notification and verify it speaks as `Alert: ...`, with summary and `At x, y` when available
6. Press `Ctrl+N` and verify the notification center opens as a navigable tree
7. Verify single notifications appear as direct leaves
8. Verify grouped notifications appear as expandable parent nodes with one child per notification
9. Verify focusing/browsing a notification with a target/location does not move the CAI cursor while the notification tree is open
10. Verify `Enter` / `Space` closes the tree, then preserves vanilla activation behavior and moves the CAI cursor only through the resulting vanilla look-at flow
11. Verify `Delete` dismisses dismissible leaves and reports when a notification cannot be dismissed
12. Verify `Shift+Delete` on a group dismisses all dismissible notifications in that group
13. Verify wrong-phase notifications do not activate and announce the wrong-phase message
14. Verify end-turn blockers no longer appear in the notification center; they should be handled through ActionPanel access next

## Investigation (2026-04-29): LoadScreen accessibility plan

### Findings
- Vanilla `LoadScreen.lua` is the shell-to-game loading context under `UI/FrontEnd/LoadScreen`, shown while moving from front end/load/save setup into the game.
- The XML layout is a full-screen visual scene:
  - black/root background and fallback `Loading, please wait...` text
  - leader background image and leader portrait
  - central colored civilization banner
  - civilization icon and civilization name
  - fixed "Joins the World Stage" label
  - era/save-era line
  - leader or challenge name
  - leader/challenge loading text
  - "Features & Abilities" section with unique abilities, units, buildings, districts, and improvements
  - loading message
  - final Begin Game / Continue Game button once loading is complete
- Data is populated on `Events.LoadScreenContentReady` from `PlayerConfigurations`, `GameInfo.LoadingInfo`, `GameInfo.Leaders`, `GameInfo.Eras`, saved-game metadata, `Challenges`, and `GetLeaderUniqueTraits()` / `GetCivilizationUniqueTraits()`.
- `Events.LoadGameViewStateDone` marks load complete, hides the loading message, shows the Begin/Continue button, sets `InputContext.Ready`, registers callbacks, and listens for `StartGame` / `StartGameAlt`.
- `OnActivateButtonClicked()` is the only continue path to preserve: it raises `Events.LoadScreenClose()`, stops loading speech/music, dequeues the popup, switches to `InputContext.World`, and handles Play-By-Cloud follow-up checks.
- Escape and StartGame actions are only honored after `m_isLoadComplete`; before that, input must not force progression.
- Resync, multiplayer, World Builder, and automation can skip the visible button and call the continue path automatically.
- Existing `WorldInput_CAI.lua` correctly initializes CAI game view only after `Events.LoadScreenClose`; load-screen CAI should not disturb that boundary.
- Documented the LoadScreen pattern in `docs/game-api.md`.

### Suggested CAI integration
- Add a front-end `UI/frontEnd/LoadScreen.lua` wrapper or imported replacement and register it in `src/CivViAccess.modinfo` front-end files.
- Include `caiUtils` and use `ExposedMembers.CAI_UIManager`; keep all speech through `Speak()`.
- Wrap `OnLoadScreenContentReady()` after vanilla population to build a transient accessible panel/dialog from live control text:
  - civilization name from `Controls.CivName:GetText()`
  - era from visible `Controls.EraInfo:GetText()`
  - leader/challenge name from `Controls.LeaderName:GetText()`
  - leader/challenge text from visible `Controls.LeaderInfo:GetText()`
  - unique feature rows from the instances built into `Controls.FeaturesStack`, or preferably from the same trait tables before/while building widgets if instance inspection is unreliable
- Represent the screen as a read-only `Dialog` or `Panel` with `StaticText` children plus a final `Button` for Begin/Continue once ready.
- Wrap `OnLoadGameViewStateDone()` to update/speak readiness and add/enable the Begin/Continue button widget. Its `OnClick` should call vanilla `OnActivateButtonClicked()`.
- Wrap `OnActivateButtonClicked()` or `OnHide()` to remove/destroy the load-screen CAI widget before the in-game main panel initializes.
- For resync/multiplayer/World Builder/autostart paths, announce a short localized loading/entering-game message only if CAI is active, but do not block automatic continuation.
- Avoid announcing all feature text automatically by default because Dawn of Man audio may be playing; prefer initial short summary plus navigable read-on-demand content.

### Needs implementation
1. Add `src/UI/frontEnd/LoadScreen.lua` based on vanilla `LoadScreen.lua` plus CAI accessibility region.
2. Register the file in the front-end import list in `src/CivViAccess.modinfo`.
3. Add CAI localization for loading-screen panel title, ready state, and any missing labels not exposed by vanilla controls.
4. Verify normal new-game loading, saved-game loading, challenge loading, multiplayer/resync auto-continue, World Builder load, and automation auto-start.

## Current Work (2026-04-29): Unit operation hotkey configuration

### What's done
- Added `src/data/unitOperationConfig.sql` with `update UnitOperations set HotkeyId='...' where OperationType='...';` statements for all vanilla unit operations that previously had no `HotkeyId`.
- Added matching unbound `InputActions` rows in `src/data/hotkey_config.xml` under the base `UNIT` category.
- Reused each operation's existing localized description tag for the hotkey action name and description.
- Pointed `UNITOPERATION_TELEPORT_TO` at the existing vanilla `LOC_UNITOPERATION_TELEPORT_TO_CITY_DESCRIPTION` text tag, because vanilla references `LOC_UNITOPERATION_TELEPORT_TO` in operation data but does not define that tag in `InGameText.xml`.
- Registered `data/unitOperationConfig.sql` in `src/CivViAccess.modinfo` and added an in-game `UpdateDatabase` action for it.
- XML parse checks pass for `src/data/hotkey_config.xml` and `src/CivViAccess.modinfo`; `src/data/unitOperationConfig.sql` contains 47 `UnitOperations` update statements.

### Needs testing
1. Launch the game and verify the mod loads without database errors.
2. Open Options > Key Bindings > Unit Actions and verify the new unit operation actions appear.
3. Verify the new unit operation actions are unbound by default.
4. Bind a few actions, such as Build Improvement, Pillage, and Upgrade, and verify they trigger the selected unit's matching operation when available.

## Current Work (2026-04-29): UnitPanel selection info and action list

### What's done
- Added `src/UI/inGame/UnitPanel_CAI.lua` as a wrapper around vanilla `UnitPanel.lua`.
- Registered `UnitPanel_CAI.lua` in `src/CivViAccess.modinfo` as the replacement for the `UnitPanel` Lua context.
- Added selected-unit info access through `ExposedMembers.CAIInfo:RequestUnitInfo(unitID, requestedKeys, playerID)`.
- Moved selected-unit info responsibility out of `worldInfo.lua`; plot info now keeps only its own small aggregated unit-name helper for plot summaries.
- Preserved the old unit nationality/adjective behavior by adding it to the new unit-panel name helper.
- Removed the outdated selected-unit announcer from `caiIngame.lua` so unit selection speech is not duplicated.
- Reused the existing selection info actions:
  - `~` reads selected-unit summary.
  - `Shift+1` through `Shift+0` read unit info slots for health, movement, combat, charges, promotions, formation, abilities, special state, available actions, and full details.
- Reused `SelectionActions` to open a transient CAI unit action list built from vanilla `GetSubjectData().Actions`.
- Unit action rows preserve vanilla callback functions, callback parameters, action order, disabled/failure tooltip text, and action sounds.
- Reused existing vanilla unit-panel and keybinding localization strings instead of adding CAI-specific unit-panel tags.
- Documented the UnitPanel data/action pattern in `docs/game-api.md`.
- XML parse checks pass for `src/CivViAccess.modinfo`, `src/Text/en_US/cai_text_ui.xml`, `src/data/hotkey_config.xml`, and `src/data/unitOperationConfig.xml`.

### Needs testing
1. Launch a game and verify no Lua errors from `UnitPanel_CAI.lua`, `worldInfo.lua`, or `caiIngame.lua`.
2. Select several unit types and verify one concise selection summary is spoken.
3. Verify `~` and `Shift+1` through `Shift+0` read selected-unit info while a unit is selected.
4. Verify city selection info still works for cities and does not conflict with unit selection info.
5. Bind/use `SelectionActions` and verify the unit action list opens for the selected unit.
6. Verify action-list `Enter` / `Space` triggers normal vanilla actions, including build improvements, promotion, delete confirmation, spy actions, and ranged/targeting modes.
7. Verify disabled unit actions are readable and speak their tooltip/failure reason without executing.
8. Verify plot info still reports aggregated units on a plot without depending on `UnitPanel_CAI.lua`.
