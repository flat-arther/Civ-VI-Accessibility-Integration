# Simplified Chinese Screen-Reader Smoke Test

Use this checklist with Civilization VI set to Simplified Chinese and the CAI
development build enabled. For each check, replace `Not run` with `Pass` or
`Fail` and record any wording, pronunciation, focus, or loading issue under
Notes.

## Setup

1. Set the Civilization VI language to Simplified Chinese in Steam.
2. Enable only the development build of Civ VI Accessibility Integration.
3. Start ZDSR (Zhengdu Screen Reader / 争渡读屏) and confirm Tolk output is reaching the selected synthesizer.
4. Start Civilization VI with DX 11.
5. After each front-end and in-game test pass, exit the game before reading the logs.

## Checks

### Mod Browser Metadata

- Result: Not run
- Notes:
- Confirm the mod name, teaser, and description are Simplified Chinese rather than raw `LOC_CAI_*` keys or English fallback text.

### Main Menu

- Result: Not run
- Notes:
- Confirm the menu, accessibility introduction, widget roles, positions, states, and tooltips speak natural Simplified Chinese.

### Accessibility Settings

- Result: Not run
- Notes:
- Press F12. Check every category, option, selected value, and tooltip, including UI, cursor, events, World Scanner, and message buffer settings.

### Input Help

- Result: Not run
- Notes:
- Press Ctrl+H. Check physical key names, modifiers, general bindings, and screen-specific actions. Confirm `Ctrl`, `Shift`, and `Alt` remain understandable in Chinese speech.

### Accessibility Tutorials

- Result: Not run
- Notes:
- Enable mod tutorials, open representative front-end and in-game screens, and confirm tutorial titles, instructions, buttons, and reset feedback are all Chinese.

### Civilopedia Accessibility Section

- Result: Not run
- Notes:
- Press F1 and open the Accessibility Mod section. Check the introduction, key reference, search guide, screen tutorials, widget articles, and gameplay articles.

### Navigation Cursor

- Result: Not run
- Notes:
- Move across land, water, fog, civilization borders, continents, named regions, and a national park. Check direction, distance, terrain, ownership, coordinates, and zone announcements.

### Surveyor

- Result: Not run
- Notes:
- Open the Surveyor and check rings, directions, terrain summaries, yields, features, resources, units, cities, and empty-result feedback.

### World Scanner

- Result: Not run
- Notes:
- Browse built-in, contextual, custom, lens, city-management, recommendation, and scenario categories. Check category management, search terms, coordinates, and positional beacon settings.

### Tutorial Advisor Replacements

- Result: Not run
- Notes:
- Start the official tutorial and confirm advisor instructions use Chinese accessibility directions for unit movement, city production, research, civics, government, and trade routes.

### English Fallback

- Result: Not run
- Notes:
- Switch the game back to English and confirm the mod still loads with its original English text and no raw localization keys.

## Log Review

- `Database.log` result: Not run
- `Database.log` notes:
- `Modding.log` result: Not run
- `Modding.log` notes:
- `Lua.log` result: Not run
- `Lua.log` notes:
- Confirm `CAI_LOC_FrontEnd` and `CAI_LOC_Ingame` load without XML, SQL, localization database, or Lua errors.
