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
- `baseWidget.lua` — `UIWidget` base class with child/parent/input management, `SetValue()` with `OnValueChanged` callback, `SpeakElements()` with per-widget SpeechSettings, `GetVisiblePosition()` for hidden-aware positioning, `GetInfoStrings()` returning label/role/value/position/state/tooltip
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
- `InGame.lua` — root in-game context (modified from vanilla). All strings localized

### Frontend (partial)
- `IntroScreen.lua` — intro screen (content unknown)
- `MainMenu.lua` — main menu with full accessibility: MenuItem widgets, SubMenu groups for Help/Play Now, localized labels
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
- `scripts/Deploy-Mod.ps1` — copies src/ to Mods folder via robocopy, launches Civ VI via Steam on success

---

## Recent Session Work (2026-04-12)

Production-readiness overhaul of the UI manager system:

1. **Widget roles and types** — proper role labeling (DropdownMenu, Edit, Dialog, Tab, TabBar, MenuItem, StaticText). MenuItem/StaticText suppress role in speech
2. **Value/state separation** — GetValue as function (sliders, checkboxes, dropdowns), GetState limited to disabled only
3. **SpeechSettings system** — per-widget overrides (e.g. `{Role = false}`) with global CAISettings fallback
4. **SetValue + SpeakElements** — value changes instantly announced, SpeakElements accepts element array
5. **Hidden-aware navigation** — FindVisibleChild/FindFirstVisibleChild/FindLastVisibleChild extracted globally, position announcements skip hidden elements
6. **Navigation improvements** — Home/End for lists, default MSG=KeyUp with KeyDown for navigation, slider PageUp/PageDown for 10x stepping
7. **Options restructuring** — TabBar as first child of OptionsPanel, tab-switch-aware list rebuilding, keybinding capture popup using engine gesture recording
8. **MainMenu** — SubMenu groups replacing HorizontalLists
9. **Localization** — all hardcoded strings replaced with locale tags
10. **Deploy script** — updated to launch game after deploy
11. **game-api.md** — created comprehensive API reference

---

## Known Gaps / Next Steps

- [ ] Review `InGameTopOptionsMenu_CAI.lua` — unclear what CAI additions exist
- [ ] Review `IntroScreen.lua`, `FrontEndPopup.lua` — unclear what CAI additions exist
- [ ] Hotkey config (`data/hotkey_config.xml`) needs review for completeness
- [ ] No tests or test harness
- [ ] In-game UI screens beyond WorldInput/ActionPanel/AdvisorPopup need accessibility work

---

## Pending Questions / Notes
*(none — all requested work complete)*
