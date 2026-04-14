# Changelog

All notable changes to the CAI (Civ VI Accessibility Integration) mod.

## 2026-04-13 — Edit Box Improvements

### Added
- Edit box now announces its label when entering edit mode (e.g. "Editing Player Name: text selected")
- Ctrl+V paste support in edit boxes

### Fixed
- Up and Down arrow keys now speak the current line when there is no further line to move to, instead of going silent
- Empty lines are now announced as "Blank" instead of being silent
- Newlines are now treated as word boundaries during word deletion (Ctrl+Backspace / Ctrl+Delete), preventing entire text from being deleted
- Home and End keys now move to start/end of the current line instead of the entire text

## 2026-04-12 — UI Manager Production-Readiness Overhaul

### Added
- Widget roles: DropdownMenu, Edit, Dialog, Tab, TabBar, MenuItem, StaticText, GameView, InterfaceMode
- Per-widget SpeechSettings overrides (e.g. `{Role = false}`) with global CAISettings fallback
- SetValue/SpeakElements system for instant value change announcements
- Hidden-aware position announcements and navigation (FindVisibleChild, FindFirstVisibleChild, FindLastVisibleChild)
- Home/End navigation for lists, TabBar, SubMenu
- PageUp/PageDown 10x stepping for sliders
- Keybinding capture popup using engine gesture recording
- Dropdown focus auto-selects current value on open
- SubMenu GetDefaultChild for proper focus restoration
- Deploy script launches game directly after deploy
- docs/game-api.md — comprehensive API reference

### Changed
- GetValue is now a function for widgets with live data (sliders, checkboxes, dropdowns)
- GetState limited to disabled state only
- Default input binding MSG changed to KeyUp; navigation bindings use KeyDown
- Options TabBar moved to first child of OptionsPanel, tab-switch-aware list rebuilding
- MainMenu uses SubMenu groups instead of HorizontalLists, dynamic submenu labels from parent option
- MainMenu list has no label (redundant with panel)
- Options tabs no longer say "Selected"
- MenuItem and StaticText suppress role in speech
- All hardcoded user-facing strings replaced with locale tags
- Volume/scroll/text sliders step by 0.01

### Fixed
- Tooltips not speaking (speakTooltip was false)
- Options tab switch causing list to speak when not focused
- Slider PageUp/PageDown were inverted (Up now increments, Down decrements)
