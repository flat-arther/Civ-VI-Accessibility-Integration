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
- `ResearchChooser_CAI.lua` - partial replacement for `ResearchChooser`; wraps `View` / `AddAvailableResearch` / `RealizeCurrentResearch`. Panel is split into two lists - an interactive available research list (Enter chooses; Shift+Enter queues) and a view-only queue list with its own detail edit
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
- `TreeviewItem` is back to being a minimal template; ProductionPanel now adds its own row bindings with `AddInputBinding(...)`
- ProductionPanel CAI layer was rewritten to mirror vanilla interaction flow more closely: Enter maps to vanilla left click, Shift+Enter maps to vanilla right click, and focus reuses vanilla hover behavior
- Queue and Manager are now separate accessible tabs instead of treating Queue like another production list
- Expand/collapse behavior moved off the `TreeviewItem` template and onto the ProductionPanel tree container, with category toggles calling vanilla expand/collapse handlers
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
- Tree widgets should follow the CAI pattern where templates stay generic and screen-specific bindings are added by the consumer
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
