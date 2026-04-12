# Project Status: Civ VI Accessibility Integration (CAI)

## Overview
Lua accessibility mod for Civilization VI. Adds TTS/screen reader support for blind players by replacing and extending native UI screens. Authors: FlatArther and Hamada.

**Mod folder:** `%USERPROFILE%\Documents\My Games\Sid Meier's Civilization VI\Mods\CivVi-Accessibility-Integration\`
**Source:** `src/` → `CivViAccess.modinfo`

---

## What's Built

### Core Infrastructure (complete)
- `caiUtils.lua` — `Speak()`, `WrapFunc()`, `HijackTable()`, utility helpers
- `UIScreenManager.lua` — widget stack, focus tracking, divergence-aware speech, input routing
- `baseWidget.lua` — `UIWidget` base class with child/parent/input management
- `widgetTemplates.lua` — widget templates
- `ideHelpers.lua` — Lua type annotations for IDE

### In-Game (partial)
- `worldInfo.lua` — full plot info system (`CAIPlotInfo:RequestPlotInfo()`), reads terrain/features/resources/buildings/yields
- `navCursor.lua` — hex grid cursor (`CAICursor`), moves by direction, snaps to units
- `caiIngame.lua` — event listeners: cursor move → speaks plot info, unit selection → speaks unit name/coords
- `WorldInput_CAI.lua` — replaces `WorldInput`; routes keyboard input through UIScreenManager; handles interface modes (e.g. MOVE_TO)
- `ActionPanel_CAI.lua` — replaces `ActionPanel`; hooks `CAIEndTurn` event to trigger end turn
- `AdvisorPopup_CAI.lua` — replaces `AdvisorPopup` (content unknown, needs review)
- `InGameTopOptionsMenu_CAI.lua` — replaces `InGameTopOptionsMenu` (content unknown, needs review)
- `InGame.lua` — root in-game context (modified from vanilla)

### Frontend (partial)
- `IntroScreen.lua` — intro screen (content unknown)
- `MainMenu.lua` — main menu (large file, CAI additions unknown — needs review)
- `FrontEndPopup.lua` — frontend popup (content unknown)

### Shared
- `PopupDialog.lua` — shared popup dialog widget
- `Options.lua` — full options screen accessibility (all 7 tabs: Game, Graphics, Audio, Interface, Application, Language, KeyBindings)

### Data
- `data/hotkey_config.xml` — custom action IDs
- `Text/en_US/cai_text_ui.xml` — localization strings

---

## Known Gaps / Next Steps

- [ ] Review `AdvisorPopup_CAI.lua`, `InGameTopOptionsMenu_CAI.lua`, `IntroScreen.lua`, `FrontEndPopup.lua` — unclear what CAI additions exist
- [ ] Review `MainMenu.lua` — large file, need to find CAI-specific additions
- [ ] `docs/game-api.md` does not exist yet — create as patterns/API knowledge accumulates
- [ ] No deploy script yet — manual copy to Mods folder required
- [ ] Hotkey config (`data/hotkey_config.xml`) needs review for completeness
- [ ] No tests or test harness

---

## Pending Questions / Notes
*(none at session start — ask user what to work on)*
