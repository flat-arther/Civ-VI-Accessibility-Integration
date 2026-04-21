# Changelog

All notable changes to the CAI (Civ VI Accessibility Integration) mod.

## 2026-04-21 — ResearchChooser Split into Available + Queue lists

### Changed
- `UI/inGame/ResearchChooser_CAI.lua` — the single research list is now split into two lists on the CAI panel: an interactive **Available Research** list and a view-only **Research Queue** list. Each list has its own read-only detail Edit field that updates on row focus. Queue list sorts current research first, then queued techs by ascending `ResearchQueuePosition`.
- The standalone current-research progress StaticText is removed; current research now lives as the first row of the queue list. `FormatRowLabel` prefixes that row with "Researching: {Name}" and includes the progress percentage so the row replaces what the old summary widget used to announce.
- Queue list is view-only: Enter is a no-op, no Shift+Enter binding. Rows otherwise use the same label formatting as available rows, so focus/arrow navigation and detail announcement work identically.
- Tutorial reorder now applies to the available list only (queued/current techs keep their queue-order placement).

### Fixed
- Queue position no longer requires queuing a tech twice to appear. Root cause: `UI.RequestPlayerOperation(..., VALUE_APPEND)` commits asynchronously, so the synchronous `Refresh()` called immediately after ran against stale queue state. Fix: drop the synchronous `Refresh` and hook `Events.ResearchQueueChanged` (missing from vanilla's chooser listeners — only `TechTree.lua` listens). The event fires once the engine commits the queue mutation; our handler calls the vanilla `Refresh()` which does `GetData()` → `View(kData)` with the live queue. This also catches queue edits made from the tech tree while the chooser panel is open.

### Added
- Loc keys `LOC_CAI_RESEARCH_AVAILABLE_LIST`, `LOC_CAI_RESEARCH_QUEUE_LIST`, `LOC_CAI_RESEARCH_AVAILABLE_DETAILS`, `LOC_CAI_RESEARCH_QUEUE_DETAILS` in `src/Text/en_US/cai_text_ui.xml`.

## 2026-04-19 — ResearchChooser Accessibility

### Added
- `UI/inGame/ResearchChooser_CAI.lua` — sidecar partial replacement for the tech research chooser panel
- CAI Panel + List exposing every available research; each row announces name, turns left, queue position, recommended/boost flags via tooltip
- Enter on a row chooses the research via the same `OnChooseResearch` entry point the native click uses
- **Shift+Enter on a row queues the research** (mirrors TechTree.lua's shift-click path: `GetResearchPath` + `VALUE_APPEND`)
- Open Tech Tree and Close buttons exposed as sibling widgets
- `ReplaceUIScript id="CAI_ResearchChooser"` registered in `CivViAccess.modinfo`

### Fixed
- ResearchChooser navigation no longer jumps focus twice per Up/Down/Tab. Wrapped `OnInputHandler` now returns true when `mgr:HandleInput` consumes the event, preventing the input from bubbling to `WorldInput_CAI`'s own input handler (which would call `mgr:HandleInput` a second time). When a CAI input causes the panel to pop, the native slide animator is also closed so visual and accessibility state stay in sync.

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
