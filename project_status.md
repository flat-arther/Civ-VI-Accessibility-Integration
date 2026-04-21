# Project Status: Civ VI Accessibility Integration (CAI)

## Overview
Lua accessibility mod for Civilization VI. Adds TTS/screen reader support for blind players by replacing and extending native UI screens. Authors: FlatArther and Hamada.

**Mod folder:** `%USERPROFILE%\Documents\My Games\Sid Meier's Civilization VI\Mods\CivVi-Accessibility-Integration\`
**Source:** `src/` → `CivViAccess.modinfo`

---

## What's Built

### Core Infrastructure (complete)
- `caiUtils.lua` — `Speak()`, `WrapFunc()`, `HijackTable()`, utility helpers
- `UIScreenManager.lua` — widget stack, focus tracking, divergence-aware speech, input routing, global CAISettings for speech element control
- `baseWidget.lua` — `UIWidget` base class with child/parent/input management, `SetValue()` with `OnValueChanged` callback, `SpeakElements()` with per-widget SpeechSettings, `GetVisiblePosition()` for hidden-aware positioning, `GetInfoStrings()` returning label/role/value/position/state/tooltip, `InsertChild(index, widget)` for positional child insertion
- `widgetTemplates.lua` — widget templates: Panel, List, HorizontalList, SubMenu, Button, DropdownMenu, Slider, Checkbox, Edit, Dialog, Tab, TabBar, MenuItem, StaticText, GameView, InterfaceMode. Global nav helpers: `FindVisibleChild`, `FindFirstVisibleChild`, `FindLastVisibleChild`
- `ideHelpers.lua` — Lua type annotations for IDE

### In-Game (partial)
- `worldInfo.lua` — full plot info system (`CAIPlotInfo:RequestPlotInfo()`), reads terrain/features/resources/buildings/yields
- `navCursor.lua` — hex grid cursor (`CAICursor`), moves by direction, snaps to units
- `caiIngame.lua` — event listeners: cursor move → speaks plot info, unit selection → speaks unit name/coords
- `WorldInput_CAI.lua` — replaces `WorldInput`; routes keyboard input through UIScreenManager; handles interface modes (e.g. MOVE_TO). All strings localized
- `ActionPanel_CAI.lua` — replaces `ActionPanel`; hooks `CAIEndTurn` event to trigger end turn
- `AdvisorPopup_CAI.lua` — replaces `AdvisorPopup`; uses Dialog type for main panel, StaticText for body
- `InGameTopOptionsMenu_CAI.lua` — replaces `InGameTopOptionsMenu` (content unknown, needs review)
- `ResearchChooser_CAI.lua` — partial replacement for `ResearchChooser`; wraps `View` / `AddAvailableResearch` / `RealizeCurrentResearch`. Panel is split into two lists — an interactive **Available Research** list (Enter chooses; **Shift+Enter queues** via `GetResearchPath` + `VALUE_APPEND`) and a view-only **Research Queue** list sorted current-first then ascending `ResearchQueuePosition` — each with its own read-only detail Edit. Current research is the first row of the queue list (prefixed "Researching:" with inline progress %), not a standalone summary widget. Push/pops via `LuaEvents.ResearchChooser_ForceHideWorldTracker` / `RestoreWorldTracker`. Adds a missing `Events.ResearchQueueChanged` listener (vanilla's chooser only listens to `ResearchChanged`/`ResearchCompleted`, which don't fire on queue append/reorder) that calls `Refresh()` — fixes the "queue position appears only on the second queue" bug, since `RequestPlayerOperation(VALUE_APPEND)` commits async and any synchronous refresh immediately after sees stale queue state.
- `InGame.lua` — root in-game context (modified from vanilla). All strings localized

### Frontend (partial)
- `IntroScreen.lua` — intro screen (content unknown)
- `MainMenu.lua` — main menu with full accessibility: MenuItem widgets, SubMenu groups for Help/Play Now, localized labels
- `AdvancedSetup.lua` — Create Game screen with tab bar (Basic/Advanced views), static pulldowns, leader selection, dynamic game parameters, player management. See "Current Work" below
- `FrontEndPopup.lua` — frontend popup (content unknown)

### Shared
- `PopupDialog.lua` — shared popup dialog widget using Dialog type, StaticText for text, Button for actions
- `Options.lua` — full options screen accessibility (all 7 tabs: Game, Graphics, Audio, Interface, Application, Language, KeyBindings). Features: DropdownMenu/Checkbox/Slider/Edit widgets with GetValue, TabBar with tab-switch-aware rebuilding, keybinding capture popup with engine gesture recording, volume/scroll/text sliders step by 0.01

### Data
- `data/hotkey_config.xml` — custom action IDs
- `Text/en_US/cai_text_ui.xml` — complete localization: roles, states, UI labels, keybinding strings, all user-facing text

### Docs
- `docs/game-api.md` — comprehensive API reference: Input system, Locale, Options, UI Controls, InstanceManager, Events, ExposedMembers, CAI custom API, Interface Modes, Sound, Modding, Game State, Network

### Scripts
- `scripts/Deploy-Mod.ps1` — copies src/ to Mods folder via robocopy, launches Civ VI via Steam on success (legacy — `src/` is now symlinked into the mod folder, no copy step required)

---

## Current Work (2026-04-14): AdvancedSetup.lua — Create Game Screen

### What's done
- Basic view: Tab bar (Basic/Advanced tabs), flat settings list with static pulldowns (Ruleset, Leader, Difficulty, Speed, Map Size), Map Select button, dynamic params (game modes, booleans, pulldowns, sliders)
- Advanced view: Player management (local player leader/color, AI player submenus with leader selection and delete, Add AI button), parameter sections (Primary, GameModes, Victories, Advanced)
- Tab switching: OnFocusEnter on tabs triggers SwitchToTab, ESC/Back always closes from either tab
- Action buttons: Start, Default, Back (always visible), LoadConfig/SaveConfig (visible only on Advanced tab)
- Forward-declared `SwitchToTab` to fix Lua upvalue scoping bug

### Just deployed — needs testing
- **Restructured advanced view layout**: sections (Players, Primary, GameModes, Victories, Advanced) are now direct children of `CAI_Panel` (Dialog) instead of nested inside `CAI_SettingsList`
- Tab/Shift-Tab jumps between sections; Up/Down navigates within each section
- `RemoveAdvancedSections()` helper removes advanced sections from panel when switching back to basic
- `PopulateBasicView()` restores `CAI_SettingsList` to panel
- `GetDefaultChild` on panel returns appropriate first section based on active tab
- `InsertChild(index, widget)` added to baseWidget.lua

### What to test
1. Basic view unchanged — one list, Up/Down through settings
2. Switch to Advanced tab, Tab forward — should land on Players section, then Primary, GameModes, Victories, Advanced, then action buttons
3. Up/Down wraps within each section
4. Tab/Shift-Tab jumps between sections
5. ESC closes from either view
6. Empty sections still appear (not skipped)
7. Switch back to Basic — flat list restored

### Potential issues
- `RemoveFromParent()` calls `RemoveChild()` which checks focused widget and may call `SetFocus` — should be fine since tab is focused during switch, not the sections
- If `GetChildIndex` on `CAI_Panel` doesn't find `CAI_SettingsList` correctly, basic view restoration could fail

---

## Known Gaps / Next Steps

- [ ] Review `InGameTopOptionsMenu_CAI.lua` — unclear what CAI additions exist
- [ ] Review `IntroScreen.lua`, `FrontEndPopup.lua` — unclear what CAI additions exist
- [ ] Hotkey config (`data/hotkey_config.xml`) needs review for completeness
- [ ] No tests or test harness
- [ ] In-game UI screens beyond WorldInput/ActionPanel/AdvisorPopup need accessibility work
- [ ] MapSelect.lua — map picker popup (file exists but status unknown)

---

## Pending Questions / Notes
- Awaiting test results for advanced view section restructuring (deployed 2026-04-14)
