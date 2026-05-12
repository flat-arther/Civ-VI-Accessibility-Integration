# Project Status: Civ VI Accessibility Integration (CAI)

Last compacted: 2026-05-11

## Purpose

Civilization VI accessibility mod for blind players. Adds TTS and screen-reader navigation through Lua UI replacements and wrappers.

- Authors: FlatArther and Hamada
- Source entry: `src/CivViAccess.modinfo`
- Deploy model: `src/` is symlinked into the Civ VI mod folder
- Core rule: all TTS goes through `Speak()` from `caiUtils.lua`
- API notes and discovered behavior live in `docs/game-api.md`

## Gate Check

- Tier 1 analysis is complete for current work.
- Before new feature work: check `docs/game-api.md`, then verify uncertain behavior against actual Lua in `decompiled/` or the Steam install.
- Safe mod keys, input/context rules, localization rules, and screen-specific patterns are documented in `docs/game-api.md`.

## Core Systems

- `caiUtils.lua`: `Speak()`, wrappers, table hijack helpers.
- `UIScreenManager.lua`: widget stack, focus routing, priority roots, duplicate-id diagnostics, stack removal by id.
- `baseWidget.lua`: lifecycle, child lookup, visible-child handling, clear/destroy robustness.
- `widgetTemplates.lua` and `widgetTemplateHelpers.lua`: shared widget types and helper constructors.
- `ideHelpers.lua`: Lua annotations.
- Shared text: `src/Text/en_US/cai_text_ui.xml`
- Bindable actions: `src/data/hotkey_config.xml`

## Current Focus

Diplomacy/production polish plus remaining in-game verification.

- `DiplomacyDealView_CAI.lua`: root panel with tab bar, offers tree, inventory tree, and actions list is implemented. Amount editing, agreement-option selection, delete, unacceptable-item marking, category inventory activation, and demand-mode side handling are wired to live vanilla behavior.
- `DiplomacyActionView_CAI.lua`: persistent CAI root with leaders tree, actions list, conversation panel, and cinema handling is implemented. Intel tabs, submenu rebuilds, conversation lifecycle sync, and close-path cleanup are in place.
- `DeclareWarPopup_CAI.lua`: dedicated declare-war warning dialog wrapper is implemented for diplomacy, city-state, Civ6Common, and world-input open paths, with live targets/consequence summaries and modal button handling.
- `ProductionPanel_CAI.lua`: per-tab CAI bodies, expandable production rows, queue management rows, live category capture, and vanilla tab-sync/open timing fixes are implemented.

## Verified Recently

- `CityPanel_CAI.lua`: `~` now reads name, coords, health, growth, and production through `RequestCityInfo(...)`.
- `CityPanel_CAI.lua`: city helper order is now `Shift+1` health, `Shift+2` production, `Shift+3` growth, `Shift+4` housing, `Shift+5` buildings plus amenities, `Shift+6` religious citizens, with yield helpers unchanged on `Shift+7` through `Shift+0`.
- `ProductionPanel_CAI.lua`: refactor to `m_state` / `m_ui` / `m_vanilla`, delayed open handshake through `ProductionPanel_ListModeChanged(...)`, and tighter production refresh hooks are working in game.
- `UIScreenManager.lua` and shared widget helpers: stale hidden focused-child recovery is fixed and verified.
- `GovernmentScreen_CAI.lua`: implementation is complete and verified in game.
- `CivicsChooser` and `CivicsTree`: implementations are complete and verified in game.
- `CivilopediaScreen_CAI.lua`: implementation is complete. CAI now exposes sections, article content, quotes, related links, and a mirrored native history list with reopen/history-path fixes and boundary speech.
- Frontend AdvancedSetup and My2K accessibility work are implemented and working.

## Open Test Queue

ProductionPanel:

- Verify production and purchase row activation, Civilopedia access, and expand/collapse behavior.
- Verify tooltip/detail cleanup, including cost/turns wording and stripped duplicate title lines.
- Verify category expand/collapse mirrors vanilla correctly without snapping back on refresh.
- Verify current-production widget appears only on Production and Queue.
- Verify queue management rows support reorder/delete cleanly.
- Verify tutorial-gated or disabled rows are skipped or announced disabled.
- ProductionManager / multi-queue accessibility still needs implementation.

ResearchChooser:

- Verify available research activation, queued/current read-only behavior, and default focus rules.
- Verify expand/collapse behavior for detail rows and nested unlock nodes.
- Verify tooltip summaries, unlock deduplication, first-letter navigation, and queue-position speech.
- Verify tutorial filtering and chooser separation from CivicsChooser.

CityPanel:

- Verify `ExposedMembers.CAIInfo:RequestCityInfo(...)` for selected and explicit local-player city ids.
- Verify city info helpers and `SelectionActions` match vanilla behavior.
- Verify CITY actions appear in key bindings and trigger the correct vanilla city-panel actions.

UnitPanel:

- Verify no Lua errors from `UnitPanel_CAI.lua`, `worldInfo.lua`, or `caiIngame.lua`.
- Verify summary speech, helper ordering, action activation, disabled-action filtering, and localized category/keybinding announcements.
- Verify plot info remains independent from selected-unit helper logic.

WorldInput / Notifications / ActionPanel:

- Verify remappable cursor movement and camera sync.
- Verify wonder placement speech and the CAI wonder-placement interface flow.
- Verify notification speech, notification tree activation/dismissal, and blocker filtering.
- Verify tutorial-safe handling of Space and Ctrl+Space.
- Verify blocker-tooltip speech changes and Escape closing of the ActionPanel blocker list.

WorldTracker and TopPanel:

- Verify `T`, `C`, `W`, `Shift+T`, `Y`, `Ctrl+Y`, and `Q`.
- Verify pushed yield/resource lists close cleanly with Escape and use localized vanilla text.

TechCivicCompletedPopup:

- Verify tech completion announces header, name, unlock count, and quote, and that Continue and Escape dismiss the popup.
- Verify civic completion announces the CivicMsgLabel ("free government change") when present, and the Change Government / Change Policies action button opens the Government screen.
- Verify chained popups (tech + civic finished same turn) announce the second after the first closes without a stale CAI widget.

Frontend / Shared:

- Verify DiplomacyActionView overview shape, intel-tab expansion, submenu behavior, and conversation close flows.
- Verify DeclareWarPopup opens from diplomacy, city-state, and world-input paths, reads targets and visible consequence sections, and cleans up on confirm, cancel, Escape, and turn end.
- Verify GovernmentScreen tab/body refresh remains stable during tab switches, government changes, and policy edits.
- Verify IntroScreen skip behavior, LoadGameMenu keyboard behavior, and My2K dialog coverage.

Unit operation / command hotkeys:

- Verify the mod loads without database errors.
- Verify new unbound Unit Actions appear in Options > Key Bindings.
- Verify bound operations and commands trigger the correct selected-unit behavior.
- Verify `DeleteUnit` remains single-path and does not double-open confirmation.

## Known Gaps / Next Steps

- Implement ProductionManager / multi-queue accessibility.
- Implement LoadScreen accessibility from the plan in `docs/game-api.md`.
- Review older replacements for clarity and maintenance:
  - `InGameTopOptionsMenu_CAI.lua`
  - `IntroScreen.lua`
  - `FrontEndPopup.lua`
  - `MapSelect.lua`
- Review `data/hotkey_config.xml` for completeness after recent hotkey expansion.
- No automated test harness exists; rely on XML parse checks plus in-game Lua log and user testing.

## Durable Decisions / Traps

- Do not assume included Civ VI Lua locals are reachable through `_G`; wrap direct function names immediately after `include(...)` when needed.
- Prefer live vanilla control state for visibility and disabled checks.
- Prefer `GetText()` / `GetToolTipString()` over manual `Locale.Lookup()` when vanilla already exposes the text.
- Use `Locale.Lookup()` only when no control exposes the string or for CAI-owned text.
- Tree expand/collapse behavior belongs in the shared `Treeview` template; keep screen logic separate.
- Pushed transient lists and trees should inherit current stack priority and close cleanly through the UI manager.
- Avoid persistent mirrors for ambient HUD panels when hotkey/read-on-demand access is better.
- End-turn blockers belong with ActionPanel access, not the notification center.
- Cache references and ids only; always read live values when speaking state.

## Compressed History

- Shared icon processing now resolves bracket tokens through one replacement table, converts `[NEWLINE]`, resolves unknown yield/resource icons when possible, and drops unmatched markup.
- Diplomacy screen investigation is documented in `docs/game-api.md`, including `DiplomacyActionView`, `DiplomacyDealView`, ribbon/open paths, intel tabs, deal contents, and conversation flow traps.
- `CityPanel_CAI.lua` exposes city info helpers through `ExposedMembers.CAIInfo` and supports reordered selection helper keys plus a city action list.
- `UnitPanel_CAI.lua` exposes unit info helpers, filtered spoken actions, and `SelectionActions`.
- `WorldTracker`, `TopPanel`, and `NotificationPanel` hotkey-driven access patterns are implemented.
- Nav cursor movement now uses six remappable hex-direction actions wired through `LuaEvents.CAICursorMoveDirection(...)` and `Map.GetAdjacentPlot(...)`, with alphanumeric and numpad defaults.
- Tutorial goals now use custom CAI notification types rather than `USER_DEFINED_*`.
- Unit operations and commands gained unbound hotkey ids where vanilla had no safe direct binding path.
