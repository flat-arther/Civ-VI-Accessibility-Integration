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
- `Surveyor_CAI.lua` is implemented as a world-input sibling to cursor reads and the scanner. It answers radius-based questions around the CAI cursor for yields, visible resources, terrain, friendly units, visible enemy units, and known cities/barbarian camps. Radius is private module-local state, clamped 1-5.
- `WorldScannerCategory_waterAvailability.lua` now adds a water-availability world scanner category gated by the live settler water lens layer. It mirrors the vanilla legend locale keys, rebuilds on lens layer on/off, and collapses fresh/coastal/no-water into a single valid-location subcategory for Maya.
- `MinimapPanel_CAI.lua` now wraps the vanilla minimap lens flyout with a CAI list through the shared UI manager. A new bindable `CAIMinimapOpenLensList` action defaults to `Ctrl+L`, mirrors the live vanilla lens button visibility and checked state, and supports `Escape` to close the CAI list and underlying vanilla lens panel together.
- `RevealAnnouncements_CAI.lua` now mirrors the older Civ V-style split with a cleaner internal layout: first-reveal plots are tracked separately from revisit visibility, foreign units come from a live visible-unit snapshot diff, foreign cities/resources/districts/ordinary improvements are first-reveal-only, city-center districts are skipped as redundant with cities, and gone announces revisited barbarian outposts or tribal villages that disappeared since the last sighting. `WorldInput_CAI.lua` still drives the shared 0.5 second quiet-period flush, and all visibility events refresh that timer so deferred Civ VI callbacks can extend the burst instead of flushing early.
- Shared unit naming now lives in `inGameHelpers_CAI.lua`: formation suffix resolution and owned-unit display formatting are centralized there, and `UnitFlagManager_CAI.lua`, `UnitPanel_CAI.lua`, `WorldScannerCategory_units.lua`, and `RevealAnnouncements_CAI.lua` now use that one path.
- `interfaceTargetHelpers_CAI.lua` now owns neutral active-target resolution and scalar target caching for Space interface info and the Valid Targets scanner, while plot-target speech comes from `PlotToolTip_CAI.lua` through `ExposedMembers.CAIInfo:RequestPlotInfo(...)`.

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
- Verify the new unit summary path: tilde and unit selection should speak name, activity, health, moves, charges, upgrade hint, promotion info, builder recommendation, settler water guide, and abilities in that order, with no location line.
- Verify spoken abilities truncate after 10 entries and append `+ n more` when additional abilities exist.
- Verify plot info remains independent from selected-unit helper logic.
- Static parity audit on 2026-05-16 against vanilla `UnitPanel.lua` / `.xml` plus DLC replacements found missing CAI coverage for disabled unit actions, the unit list popup / portrait controls, settler water guide details, spy mission status, lifespan stat speech, recommended build action, and combat-preview target info. Expansion replacement check result: `Expansion1\UI\Replacements\UnitPanel_Expansion1.lua` only includes the base panel, while `Expansion2\UI\Replacements\UnitPanel_Expansion2.lua` adds rock band stats, park charges, adjacent-improvement builder actions, strategic-resource upgrade cost text, and railroad build icons that CAI does not currently expose.
- 2026-05-16: `UnitPanel_CAI.lua` was rewritten to branch to `UnitPanel_Expansion2` when XP2 is active, keep disabled actions in the CAI action list with live tooltips, replace raw unit coords with hex-coordinate speech, add activity / identity / lifespan coverage, expose XP2 rock band and park-charge info, add a `Ctrl+U` CAI unit list, and fix promotion speech so `choose promotion` is based on real promote availability rather than `GetPromotionBannerVisibility()`.
- 2026-05-16: Documented vanilla combat-preview lifecycle in `docs/game-api.md`: mode entry through `OnInterfaceModeChanged(...)`, hover refresh through `InspectWhatsBelowTheCursor()` / `InspectPlot(...)`, flag-hover refresh through `OnUnitFlagPointerEntered(...)`, simulation via `GetCombatResults(...)` or `CombatManager.SimulateAttackVersus(...)`, target fill through `ReadTargetData(...)`, and final visibility through `OnShowCombat(...)`.
- 2026-05-16: Combat preview speech was reformatted to a compact target-first sequence using live UnitPanel control text for names, strength numbers, assessment, and modifiers. Main attacker/defender strength speech appends localized stat-type labels derived from vanilla combat type because those stat icons are image controls; interceptor and anti-air strength sections keep their visible numeric labels only. Damage is spoken from vanilla `GetCombatPreviewResults()` values because UnitPanel health meters do not expose a useful percent getter here; interceptor and anti-air names/strengths/modifiers are included only when their grids are visible.
- 2026-05-16: Space is now `InterfaceInfo`, while end turn moved to `Ctrl+Space` and turn blockers to `Ctrl+Shift+Space`. `interfaceInfoHelpers_CAI.lua` owns one shared `SpeakActiveInterfacePlotInfo(...)` wrapper; move/placement helpers still return lines, while ranged/city/district/air attack helpers request combat preview through `LuaEvents.CAISpeakCombatPreview()`.
- 2026-05-16: `WorldInput_CAI.lua` now creates a shared CAI targeting widget for unit ranged attack, city ranged attack, district ranged attack, air attack, WMD strike, ICBM strike, and coastal raid. Return delegates to vanilla execution handlers and Escape delegates through vanilla `OnPlacementKeyUp(...)`.
- 2026-05-16: `WorldScannerCategory_validTargets.lua` adds a dynamic Valid Targets scanner category for active targeting modes. It rebuilds on interface-mode changes and computes eligible plots from vanilla operation / command target APIs rather than reading vanilla `g_targetPlots`.
- 2026-05-17: Remaining WorldInput-owned target/destination modes now share the same CAI targeting shape: deploy, rebase, teleport to city, form corps, form army, airlift, soothsayer sacrifice, kill weaker unit, transform unit, restore unit moves, and naval gold raid. Return delegates to vanilla handlers, Escape routes through vanilla `OnPlacementKeyUp(...)`, Space reports valid/invalid target state, and the Valid Targets scanner uses the shared target resolver for both plot targets and formation unit targets.
- 2026-05-17: World scanner rebuilds were optimized after target-mode coverage exposed a freeze. Scanner categories now keep lightweight definition slots and build category contents only when navigation tries to focus that category. Cursor movement resorts only the current built category. Interface-mode and selected-unit changes rebuild only `validTargets`, and water-lens layer changes rebuild only `waterAvailability`. `ValidTargets` no longer re-calls target APIs from per-item validation.
- 2026-05-17: Scanner category cycling now discards and rebuilds ordinary scanner categories from live data each category cycle, while dynamic one-shot categories opt in with `BuildOncePerDynamicState`. CAI currently keeps that one-shot behavior only for `validTargets` and `waterAvailability`.
- 2026-05-17: `UnitPanel_CAI.lua` summary speech now delegates through `RequestUnitInfo(...)` using `UnitName`, `Activity`, `Health`, `Moves`, `Charges`, `Promotions`, and `Abilities`. Tilde and unit-selection speech both use that shared path, unit-panel location speech was removed, and the spoken abilities helper now truncates to the first 10 abilities before appending `+ n more`.
- 2026-05-17: `UnitPanel_CAI.lua` now maps `Shift+6` to real unit stats, `Shift+7` to abilities, `Shift+8` to `SpecialInfo`, and `Shift+9` to queued path. `SpecialInfo` now owns great-person passive, spy mission state, trader route state, and rock-band details; summary speech adds upgrade availability before promotions plus builder recommendation and settler water guide before abilities, while the stats helper skips fake combat speech for non-combat units and uses trader route stats for traders.
- 2026-05-17: Target-mode interface info still caches only scalar target item data, but `interfaceTargetHelpers_CAI.lua` is now reduced to target discovery/cache ownership. Plot-target labels come from `ExposedMembers.CAIInfo:RequestPlotInfo(...)`, including full no-key dumps for WMD and ICBM targets.

UnitFlagManager / PlotToolTip:

- Verify `UnitFlagManager_CAI.lua` exports `ExposedMembers.CAIInfo:RequestUnitFlagInfo(playerID, unitID, requestedKeys)` only for visible flags.
- Verify grouped same-tile unit speech merges only exact spoken matches by owner, name, formation suffix, rounded health percent, and visible status.
- Verify plot `units` speech in `PlotToolTip_CAI.lua` now mirrors UnitFlagManager-based speech instead of local name/count reconstruction.

WorldInput / Notifications / ActionPanel:

- Verify remappable cursor movement and camera sync.
- Verify reveal announcements:
- multiple identical labels in the same category should aggregate to `count + label`.
- reveal output should follow the older Civ V-style line split:
- `<N> tiles revealed` when first-reveal plots were involved, otherwise `Revealed`.
- payload sections should be `Enemy`, `Units`, `Cities`, `Resources`, `Districts`, `Improvements` in that order.
- hidden should speak as `Hidden: ...` and gone should speak as `Gone: ...`.
- tile wording should always speak the count and should come from the Civ VI plural-loc tag rather than Lua singular/plural branching.
- reveal, hidden, and gone should flush as separate lines in that order when present.
- unit reveal and hidden should now come from the visible-unit snapshot diff rather than direct `UnitVisibilityChanged` labels.
- cross-map `UnitVisibilityChanged` noise should no longer produce hidden speech for units the player never locally saw.
- destroyed or captured foreign units should not be re-announced as hidden.
- gone should announce previously seen barbarian outposts and tribal villages when a revisited visible plot no longer has that same special improvement.
- first reveal of foreign non-city-center districts and foreign ordinary improvements should announce under `Districts` and `Improvements`.
- city-center districts should not announce as districts.
- revisiting already revealed districts and ordinary improvements should not re-announce them.
- gone detection currently bootstraps only from plots visible in this session, not from a Civ VI revealed-improvement memory API.
- a new visibility event inside the 0.5 second window should extend the shared flush timer rather than causing an early partial announcement.
- shutdown / reload should not duplicate subscriptions or replay stale queued announcements.
- Verify `PlotToolTip_CAI.lua` picks the correct vanilla include for base, Expansion 2, and Barbarian Clans games, and that `RequestPlotInfo(...)` now reads per-detail strings without the old plot-info action buckets or coord line.
- Verify river direction speech in `PlotToolTip_CAI.lua`: CAI now appends edge directions to the river line using the six-edge positional helper (`self: E/SE/SW`, neighbors: `W/NW/NE`), and on Gathering Storm / Expansion 2 it appends those directions to the named-river string.
- Verify new plot read hotkeys in game: `S` units, `W` yields/river/owner, `X` movement+defense+appeal, `Shift+S` relative coordinates, `B` district/buildings. `WorldTrackerReadSummary` now defaults to `Shift+W`.
- Verify wonder placement speech and the CAI wonder-placement interface flow.
- Verify notification speech, notification tree activation/dismissal, and blocker filtering.
- Verify tutorial-safe handling of Space and Ctrl+Space.
- Verify Space interface info:
- movement mode should speak movement/path info, district and wonder placement should speak placement validity, and ranged/city/district/air attack should speak combat preview once.
- Verify Shift+0 no longer speaks combat preview from UnitPanel; combat preview should only be requested contextually through interface info or the `LuaEvents.CAISpeakCombatPreview` event.
- Verify targeting widgets:
- ranged attack, city ranged attack, district ranged attack, air attack, WMD strike, ICBM strike, coastal raid, deploy, rebase, teleport to city, form corps, form army, airlift, sacrifice selection, kill weaker unit, transform unit, restore unit moves, and naval gold raid should push a CAI interface widget, Return should execute the vanilla handler, and Escape should cancel through vanilla `OnPlacementKeyUp(...)`.
- Verify Valid Targets scanner category:
- it should appear only in active targeting modes, list vanilla-eligible target plots, label visible units before city/district/improvement/generic plot fallback, list `FORM_CORPS` / `FORM_ARMY` targets as unit names rather than anonymous plots, jump the CAI cursor with Home, and disappear after leaving targeting mode.
- Verify non-attack Space interface info:
- deploy, rebase, teleport to city, airlift, sacrifice selection, kill weaker unit, transform unit, restore unit moves, and naval gold raid should speak valid plus the plot label on eligible targets and `Invalid target` elsewhere.
- form corps and form army should speak valid plus the target unit name and `formation target` on eligible target units, and `Invalid target` elsewhere.
- Verify blocker-tooltip speech changes and Escape closing of the ActionPanel blocker list.
- Verify world scanner hotkeys and speech:
- `Ctrl+PageUp` / `Ctrl+PageDown` categories, `Shift+PageUp` / `Shift+PageDown` subcategories, `PageUp` / `PageDown` groups, `Alt+PageUp` / `Alt+PageDown` items.
- Verify scanner performance:
- entering and leaving target modes should no longer freeze from full-map category rebuilds.
- moving the CAI cursor should only resort the currently focused scanner category.
- category navigation should still skip empty categories even though categories are now built lazily.
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
- Verify Surveyor hotkeys and speech:
- `Ctrl+Shift+W` grows radius, `Shift+W` shrinks radius, clamped from 1 to 5.
- `Shift+Q` yields, `Shift+A` resources, `Shift+Z` terrain, `Shift+E` friendly units, `Shift+D` enemy units, `Shift+C` cities/camps.
- Surveyor should exclude unrevealed plots, append unexplored-tile counts, hide invisible strategic resources, and reflect live unit/city/resource state without caching.
- Verify moved defaults still work: World Tracker summary on `R`, district/building plot read on `Shift+X`, unit abilities on `Ctrl+A`, civics chooser on `Ctrl+C`.
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
