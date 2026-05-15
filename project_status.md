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
- World scanner v1 scaffolding is implemented under `src/UI/InGame/WorldScanner/`, with category scanning for cities, barbarian camps, improvements and routes, terrain, resources, units, and special map objects, plus CAI cursor jump/return navigation through new input actions.
- `WorldScannerCategory_units.lua` now splits units into three top-level scanner categories: my units, neutral units, and enemy units. Each category uses broad combat-role subcategories, and enemy units adds a dedicated barbarians subcategory.
- `WorldScannerCore.lua` now injects an implicit `All` subcategory at the front of every scanner category. It aggregates all validated items in that category without replacing the category-specific subcategories.
- `hexCoordUtils_CAI.lua` now centralizes original-capital lookup, relative coordinates, wrap-aware hex direction math, and shared path/direction utility helpers. Scanner items now speak direction from the CAI cursor instead of tile distance.
- `WorldScannerCategory_waterAvailability.lua` now adds a water-availability world scanner category gated by the live settler water lens layer. It mirrors the vanilla legend locale keys, rebuilds on lens layer on/off, and collapses fresh/coastal/no-water into a single valid-location subcategory for Maya.
- `MinimapPanel_CAI.lua` now wraps the vanilla minimap lens flyout with a CAI list through the shared UI manager. A new bindable `CAIMinimapOpenLensList` action defaults to `Ctrl+L`, mirrors the live vanilla lens button visibility and checked state, and supports `Escape` to close the CAI list and underlying vanilla lens panel together.
- `RevealAnnouncements_CAI.lua` now batches visibility-change callbacks into three top-level queues: reveal, hidden, and gone. `WorldInput_CAI.lua` drives a shared 0.5 second quiet-period flush, and reveal output is grouped in category order: tiles, units, resources, cities, districts, improvements.

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

UnitFlagManager / PlotToolTip:

- Verify `UnitFlagManager_CAI.lua` exports `ExposedMembers.CAIInfo:RequestUnitFlagInfo(playerID, unitID, requestedKeys)` only for visible flags.
- Verify grouped same-tile unit speech merges only exact spoken matches by owner, name, formation suffix, rounded health percent, and visible status.
- Verify plot `units` speech in `PlotToolTip_CAI.lua` now mirrors UnitFlagManager-based speech instead of local name/count reconstruction.

WorldInput / Notifications / ActionPanel:

- Verify remappable cursor movement and camera sync.
- Verify reveal announcements:
- multiple identical labels in the same category should aggregate to `count + label`.
- reveal output should say `Revealed {text}` and hidden output should say `{text} hidden`.
- reveal category order should be tiles, units, resources, cities, districts, improvements.
- tile wording should always speak the count and should come from the Civ VI plural-loc tag rather than Lua singular/plural branching.
- reveal and hidden should flush as separate lines in order, not as one merged per-item state list.
- unit reveal and hidden should now come from the visible-unit snapshot diff rather than direct `UnitVisibilityChanged` labels.
- cross-map `UnitVisibilityChanged` noise should no longer produce hidden speech for units the player never locally saw.
- only resources should currently enter the hidden queue directly from visibility events.
- gone should announce previously seen barbarian outposts and tribal villages when a revisited visible plot no longer has that same special improvement.
- gone detection currently bootstraps only from plots visible in this session, not from a Civ VI revealed-improvement memory API.
- a new visibility event inside the 0.5 second window should extend the shared flush timer rather than causing an early partial announcement.
- shutdown / reload should not duplicate subscriptions or replay stale queued announcements.
- Verify `PlotToolTip_CAI.lua` picks the correct vanilla include for base, Expansion 2, and Barbarian Clans games, and that `RequestPlotInfo(...)` now reads per-detail strings without the old plot-info action buckets or coord line.
- Verify river direction speech in `PlotToolTip_CAI.lua`: CAI now appends edge directions to the river line using the six-edge positional helper (`self: E/SE/SW`, neighbors: `W/NW/NE`), and on Gathering Storm / Expansion 2 it appends those directions to the named-river string.
- Verify new plot read hotkeys in game: `S` units, `W` yields/river/owner, `X` movement+defense+appeal, `Shift+S` relative coordinates, `B` district/buildings. `WorldTrackerReadSummary` now defaults to `Shift+W`.
- Verify wonder placement speech and the CAI wonder-placement interface flow.
- Verify notification speech, notification tree activation/dismissal, and blocker filtering.
- Verify tutorial-safe handling of Space and Ctrl+Space.
- Verify blocker-tooltip speech changes and Escape closing of the ActionPanel blocker list.
- Verify world scanner hotkeys and speech:
- `Ctrl+PageUp` / `Ctrl+PageDown` categories, `Shift+PageUp` / `Shift+PageDown` subcategories, `PageUp` / `PageDown` groups, `Alt+PageUp` / `Alt+PageDown` items.
- Verify the new minimap lens list hotkey and wrapper:
- `Ctrl+L` should open and close the accessible minimap lens list through the wrapped vanilla lens panel.
- `Escape` from the CAI lens list should close both the CAI widget and the vanilla flyout.
- The CAI list should mirror only currently visible vanilla lens entries and announce selected/disabled state from live button state.
- Verify the new water-availability scanner category:
- it should appear only while the `Hex_Coloring_Water_Availablity` layer is on.
- subcategories should use the same vanilla meanings as `ModalLensPanel.lua`.
- Maya should collapse fresh/coastal/no-water into a single valid-location subcategory while leaving blocked separate.
- Verify `End` speaks only the direction string for the currently selected scanner item, without moving the CAI cursor.
- Verify `Home` jumps the CAI cursor to the current scanner target and `Backspace` returns to the prior cursor plot.
- Verify group navigation speaks the first item in the group rather than a synthetic group label.
- Verify category/subcategory navigation skips empty entries and rebuilds cleanly on local turn begin.
- Verify the implicit `All` subcategory appears first in every scanner category and includes every item from that category.
- Verify scanner unit subcategories after the religion-classification fix in `WorldScannerCategory_units.lua`: barbarian units should appear under Enemy Units > Barbarians, and non-religious units should no longer collapse into Religious because Civ VI `GameInfo.Units` booleans and default stat values use `0` / `1`.
- Verify scanner barbarian-unit discovery after the player-enumeration fix in `WorldScannerCategory_units.lua`: unit scanning now mirrors the `UnitFlagManager` approach by scanning alive players plus an explicit `ipairs(Players)` barbarian pass, rather than relying on the `GetWasEverAliveCount()` player loop.
- Verify scanner direction speech: items should now announce direction from the CAI cursor, including `Here` on the same tile and grouped direction wording such as `4 E, 1 NE`.
- Verify the scanner refactor:
- full-map categories now use `Map.GetPlotCount()` rather than `Map.GetNumPlots()`.
- category files now emit flat scanner items and the core rebuilds `subcategory -> group -> items`.
- Verify the wildcard category include refactor:
- `WorldScanner_CAI.lua` should load category modules through `include("WorldScannerCategory_", true)` without direct per-category include lines.
- renamed scanner files should still load from `.modinfo` and `WorldInput_CAI.lua` with the new `WorldScanner...` names.
- Verify scanner reveal and stance gating:
- cities and units should respect met-state rules for non-local players.
- units should respect actual visibility, not just revealed plots.
- resources should hide invisible strategic resources until the reveal prereq is met.
- routes and improvements should both appear in the improvements scanner without double-counting the same object kind.

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
- Verify CityBannerManager cursor reads: summary/info1-info6 should read city-center and visible mini-banner data from live banner state only, with correct unavailable/fallback behavior when the current cursor has no visible banner.
- Verify district mini-banners stay district-only for identity/status; no parent-city summary should leak into generic district reads.
- Verify city banner religion, loyalty, and power reads still work with the relevant vanilla lenses off, while full-fog and no-banner cases stay silent except for the normal unavailable callouts.
- Verify district identity/status reads cover aerodrome, encampment, missile-silo, and generic district details from visible banner state, including revealed-only aerodrome hiding and strike availability wording.
- Verify city banner loyalty on `5` now reads percent, loyalty per turn, source buckets, and influencer lines directly, without the old separate breakdown UI.

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
- World scanner v1 is a data/navigation layer, not a pushed CAI widget tree yet.
- World scanner groups are structural only; when a group changes, CAI should speak the group's first item rather than a group label.
- World scanner routes should remain separate from improvements in scan logic because Civ VI exposes them through `plot:IsRoute()` / `plot:GetRouteType()` rather than `plot:GetImprovementType()`.
- When reading Civ VI gameplay DB rows in Lua, remember that `0` is truthy. Classification logic must test boolean columns like `TrackReligion`, `FoundReligion`, and `EnabledByReligion` explicitly, and treat religious stat columns as active only when `> 0`.

## Compressed History

- Shared icon processing now resolves bracket tokens through one replacement table, converts `[NEWLINE]`, resolves unknown yield/resource icons when possible, and drops unmatched markup.
- Diplomacy screen investigation is documented in `docs/game-api.md`, including `DiplomacyActionView`, `DiplomacyDealView`, ribbon/open paths, intel tabs, deal contents, and conversation flow traps.
- `CityPanel_CAI.lua` exposes city info helpers through `ExposedMembers.CAIInfo` and supports reordered selection helper keys plus a city action list.
- `UnitPanel_CAI.lua` exposes unit info helpers, filtered spoken actions, and `SelectionActions`.
- `WorldTracker`, `TopPanel`, and `NotificationPanel` hotkey-driven access patterns are implemented.
- `SelectionActions` now defaults to `Tab` in `src/data/hotkey_config.xml`, shared by the city and unit selection action lists.
- `CityBannerManager_CAI.lua` now ignores vanilla lens-only force-hide for generic district banner reads, so ordinary district name/type/construction/description can be spoken without turning on city or empire detail lenses, while still respecting full fog hiding.
- `CityBannerManager_CAI.lua` now also ignores religion-lens visibility for city banner religion reads by falling back to live `city:GetReligion()` data for conversion turns, follower pressure, and outgoing pressure.
- `CityBannerManager_CAI.lua` now adds expansion-aware city banner reads on `5` and `6` for loyalty and GS power. Loyalty `5` now speaks the full loyalty breakdown directly in bucket order from live `city:GetCulturalIdentity()` data instead of using a separate breakdown UI.
- Nav cursor movement now uses six remappable hex-direction actions wired through `LuaEvents.CAICursorMoveDirection(...)` and `Map.GetAdjacentPlot(...)`, with alphanumeric and numpad defaults.
- Tutorial goals now use custom CAI notification types rather than `USER_DEFINED_*`.
- Unit operations and commands gained unbound hotkey ids where vanilla had no safe direct binding path.
- `PlotToolTip_CAI.lua` now exposes helper-driven plot read actions for units, yields/river/owner, movement/defense/appeal, relative coordinates, and district/building info through `Events.InputActionTriggered`.
- `CityBannerManager.lua` visual banner inventory is now documented in `docs/game-api.md`, covering city-center banners, religion details, and district mini-banners for later CAI work.
- `CityBannerManager_CAI.lua` now exposes `ExposedMembers.CAIInfo:RequestCityBannerInfo(requestedKeys)` and handles dedicated `CityBannerReadIdentityStatus` through `CityBannerReadDiplomacy` actions with a table-driven city/district bucket definition.
- `WorldScannerCategory_units.lua` religious-unit detection now uses explicit `0` / `1` and `> 0` checks, preventing ordinary units from collapsing into the Religious subcategory and restoring the intended enemy and barbarian role buckets.
- `WorldScannerCategory_units.lua` now mirrors `UnitFlagManager` for barbarian discovery by scanning alive players plus an explicit `ipairs(Players)` barbarian pass, while keeping the normal revealed-plot and `IsUnitVisible(unit)` gates for scanner visibility.
- World scanner category files now use the `WorldScannerCategory_*.lua` naming pattern, and `WorldScanner_CAI.lua` loads them via the same wildcard include style vanilla `NotificationPanel.lua` uses.
- World scanner now has a dedicated `WorldScannerSpeakCurrentDirection` action on `End`, which speaks only the current item's direction string via `CAIWorldScanner:SpeakCurrentDirection()`.
