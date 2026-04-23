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

### Needs testing
1. Enter on production and purchase rows should commit again
2. Shift+Enter on rows with a `Type` should open Civilopedia
3. Enter on non-leaf tree items should toggle expand/collapse
4. Left and Right on the tree should collapse, expand, move to parent, or move to first child appropriately
5. Category headers, queue labels, detail label, and spoken choose/purchase/remove announcements should all localize correctly
6. Queue and Manager tabs should now behave as separate modes, with current production only in Production/Queue and queue rows active in Queue/Manager
7. Unit corps/army subtree toggles should stay in sync with vanilla `OnCorpsToggle`

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
