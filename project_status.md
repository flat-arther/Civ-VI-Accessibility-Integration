# Project Status: Civ VI Accessibility Integration (CAI)

Last compacted: 2026-04-30

## Purpose

Civilization VI accessibility mod for blind players. Adds TTS/screen reader navigation through Lua UI replacements and wrappers.

- Authors: FlatArther and Hamada
- Source entry: `src/CivViAccess.modinfo`
- Deploy model: `src/` is symlinked into the Civ VI mod folder; no copy/deploy step is normally needed
- Core rule: all TTS goes through `Speak()` from `caiUtils.lua`
- API notes and discovered Civ VI behavior live in `docs/game-api.md`

## Gate Check

- Tier 1 analysis is effectively complete for current work.
- `docs/game-api.md` documents the input system, safe mod keys, context/input handler patterns, localization/control APIs, and the screen-specific Civ VI patterns found so far.
- Before new feature work, keep following the project rule: check `docs/game-api.md`, then verify uncertain details against actual Lua under `decompiled/` or the Steam install.

## Built Core

- `caiUtils.lua`: `Speak()`, function wrapping, table hijack helpers.
- `UIScreenManager.lua`: widget stack, focus routing, priority roots, duplicate-id diagnostics, stack root removal by id.
- `baseWidget.lua`: widget lifecycle, focusable children, visible-child helpers, child lookup by id, robust clear/destroy behavior.
- `widgetTemplates.lua` and `widgetTemplateHelpers.lua`: Panel, List, SubMenu, Button, DropdownMenu, Slider, Checkbox, Edit, Dialog, TabBar, Treeview, TreeviewItem, GameView, InterfaceMode, helper construction APIs.
- `ideHelpers.lua`: Lua annotations.
- Shared/localized UI text lives in `src/Text/en_US/cai_text_ui.xml`.
- Bindable actions live in `src/data/hotkey_config.xml`.

## Current Focus

GovernmentScreen accessibility is the latest active implementation and needs in-game verification.
CivicsChooser accessibility has also been implemented and needs in-game verification.

Files involved:

- `src/UI/inGame/GovernmentScreen_CAI.lua`
- `src/UI/inGame/CivicsChooser_CAI.lua`
- `src/UI/Popups/InGamePopup_CAI.lua`
- `src/CivViAccess.modinfo`
- `src/Text/en_US/cai_text_ui.xml`
- Shared widget changes in `src/UI/uiManager/widgetTemplates.lua`

What is implemented:

- Government screen wrapper registered as a replacement.
- CAI exposes two tabs: Policies and Governments. Vanilla My Government opens map to CAI Policies.
- Policies tab is a slot-first tree with Military, Economic, Diplomatic, and Wildcard categories.
- Empty and filled policy slots are represented from live player culture slot APIs.
- Change mode supports Enter on a slot to open a filtered picker; Delete removes a filled policy.
- View mode is read-only.
- Policy picker and View All Policies use expandable policy trees.
- Governments tab uses an expandable tree. Unlocked governments activate through vanilla selection; locked governments are readable only.
- Confirm, Unlock Policies, Unlock Governments, and View All Policies mirror vanilla visibility/disabled state.
- Government confirmation dialogs are handled through `InGamePopup_CAI.lua`, with manager-first input routing.
- CAI suppresses unsafe rebuilds around vanilla confirmation/popup flows to avoid focus loss.
- After accepting a government change, CAI mirrors vanilla by returning to Policies.
- XML parse checks passed for the edited XML/modinfo files.
- ActionPanel now has a Ctrl+Space CAI turn blocker list (`ActionPanelOpenTurnBlockers`, `CAIActionPanelTurnBlockerList`). Rows activate through vanilla `DoEndTurn()` / `DoEndTurn(blockerType)` and respect backing vanilla button hidden/disabled state where available.
- Latest chooser/action fixes: ResearchChooser and CivicsChooser first-letter search now stays on root rows, queue position ignores nonqueued sentinel values, WorldTracker research/civic hotkeys respect the live tracker control disabled state before opening choosers, Space/Ctrl+Space end-turn hotkeys respect live disabled state plus tutorial ActionPanel UI-trigger gating and the vanilla tutorial slow-turn input shield, and GovernmentScreen no longer adds its own root Escape binding.
- Tutorial ActionPanel analysis: active base-tutorial detailed steps that show ActionPanel are `TURN_BASED_C`, `SELECT_RESEARCH_8`, `SELECT_END_TURN_B`, `SELECT_END_TURN_PRODUCTION`, `SELECT_END_TURN_C`, `SELECT_END_TURN_D`, `SCOUTS_D2`, `SCOUTS_E`, `SELECT_END_TURN_RESEARCH`, and `RESEARCH_IRRIGATION`; `NOTIFICATION_PANEL` only uses an advisor-side ActionPanel pointer.
- ActionPanel input handler now only wraps `OnInputActionTriggered`; vanilla `LateInitialize()` registers the wrapped global, avoiding duplicate input-action subscriptions.
- ActionPanel context input handler now routes only through CAI UI manager and no longer falls back to vanilla Enter / Shift+Enter end-turn handling.
- ActionPanel refresh handler speaks the live main action tooltip when it changes, using the post-vanilla `EndTurnButton` tooltip as the source of truth. Speech is gated by ActionPanel context visibility and tutorial ActionPanel permission, and the tutorial allow event forces one current-action announcement.
- ActionPanel turn blocker list closes with Escape.
- Camera/nav cursor analysis documented in `docs/game-api.md`: vanilla exposes `Events.Camera_Updated`, but selected-object sync should primarily use unit/city selection events and explicit `LookAtPlot` touch points, with camera-center sync treated as an optional throttled fallback.
- WorldInput CAI cursor startup now snaps to the current camera focus via `UI.GetMapLookAtWorldTarget()` -> `UI.GetPlotCoordFromWorld(...)`, rather than preferring a selected unit.
- UnitPanel and CityPanel selection summary handlers now move the CAI cursor to the selected unit/city location after speaking the summary.

GovernmentScreen test queue:

1. Launch a game and verify no Lua errors from `GovernmentScreen_CAI.lua` or `InGamePopup_CAI.lua`.
2. Press F7 and verify CAI exposes only Policies and Governments.
3. Verify vanilla My Government opens land on CAI Policies, and vanilla Governments opens land on CAI Governments.
4. Verify Policies view mode is read-only and shows all four categories with one child per live slot.
5. Verify category summaries speak used/total slot count and filled policy names.
6. Verify Enter on empty and filled slots in change mode opens the filtered picker for that exact slot.
7. Verify choosing a policy assigns/replaces the exact slot and makes the old policy available again.
8. Verify Delete removes a filled policy only in change mode.
9. Verify no policy movement workflow or movement shortcut is exposed.
10. Verify Wildcard slot pickers include all unused legal policies.
11. Verify View All Policies opens a read-only categorized tree and policies expand to detail children.
12. Verify Confirm Policies uses the vanilla confirmation dialog and applies policy changes.
13. Verify Unlock Policies / Unlock Governments preserve vanilla cost and disabled behavior.
14. Verify Governments rows read selected, locked, slot mix, bonuses, and prerequisite/progress info.
15. Verify Enter on an unlocked government opens the vanilla confirmation; accepting changes government and switches to Policies.
16. Verify locked government rows are readable but not activatable.
17. Verify Shift+Enter on policy entries opens Civilopedia outside tutorial mode and does nothing harmful during tutorial mode.
18. Verify Escape closes pushed picker/view-all trees first; on the CAI root, vanilla handles Escape and any unsaved-policy warning.

CivicsChooser test queue:

1. Launch a game and verify no Lua errors from `CivicsChooser_CAI.lua`.
2. Open CivicsChooser from the ActionPanel civic blocker and from WorldTracker `C`.
3. Verify opening CivicsChooser does not also open when ResearchChooser opens.
4. Verify initial focus lands on the civics queue tree while a civic is active, otherwise on available civics.
5. Verify available civic rows speak name, recommendation, turns, boost, tooltip detail, and first unlocks, without queue position `99`.
6. Verify Enter on available civics selects the civic, speaks the chosen-civic confirmation, plays vanilla confirm sound, and closes the chooser.
7. Verify queued/current civic rows are read-only and expandable.
8. Verify Shift+Enter opens Civilopedia outside tutorial mode and does nothing harmful during tutorial mode.
9. Verify Open Civics Tree opens the full CivicsTree and closes the chooser.
10. Verify rows disabled by zero culture yield or tutorial filtering are announced disabled and do not activate.
11. Verify Escape, close button, title/icon close, and `LaunchBar_CloseChoosers` close both CAI and vanilla state.

## Pending Test Queue By Area

ProductionPanel:

- Verify production/purchase Enter activation and Shift+Enter Civilopedia behavior.
- Verify non-leaf tree expand/collapse with Enter, Left, and Right.
- Verify queue tab is queue-management only: current production first, queued items after it, rows spoken as buttons, Delete removes focused row, Shift+Up/Down reorders.
- Verify Ctrl+Enter from Production tab appends to queue without duplicate browser/focus noise.
- Verify tutorial gating: hidden/disabled vanilla controls are skipped or announced disabled, and blocked rows do not activate.
- ProductionManager / multi-queue accessibility still needs implementation.

ResearchChooser:

- CAI research chooser now uses Treeview widgets instead of List + read-only Edit detail boxes.
- Queue/current/recent rows are in the first tree; available research is in the second tree.
- Research items start collapsed, append the vanilla recommended tag to the outer label, and expose cost/boost/first unlocks as the item tooltip.
- Expanding a research item exposes full detail rows; the final detail row is an expandable unlock-count node with one child per unlock.
- Vanilla tooltip unlock lines are filtered out of the outer detail breakdown to avoid duplicating the dedicated unlock section.
- CAI now prefers live chooser control text and tooltips such as `TechName`, `Top`, `TurnsLeft`, boost icon tooltips, `NodeNumber`, `Title`, `OpenTreeButton`, and `CloseButton`, with localization fallbacks only where vanilla exposes no control string.
- Panel default focus is queue first when current research is active, otherwise available research second when choosing new research.
- Verify Enter chooses available research.
- Verify Enter on queued/current research expands/collapses instead of choosing or queueing.
- Verify research detail rows and nested unlock nodes start collapsed and expand with the shared tree controls.
- Verify unlock names appear only under the expandable unlock-count node, not duplicated in the outer detail breakdown.
- Verify outer research tooltips include cost, boost status, and roughly two unlocks.
- Verify default focus lands on the queue tree while research is active and available research when no current research is selected.
- Verify Shift+Enter no longer queues research.
- Verify queued/current research remains read-only and inspectable.
- Verify tutorial-open first focus already respects filtered/disabled vanilla row state.
- Verify Open Tech Tree still follows the live vanilla control state, and Escape remains the chooser close path.
- Verify first-letter search in both research trees only lands on top-level research rows, even after expanding detail/unlock nodes.
- Verify nonqueued research rows do not speak queue position `99`, while actual queued rows still speak their queue position.
- Verify opening CivicsChooser does not push a ResearchChooser CAI panel, and opening ResearchChooser does not push a CivicsChooser CAI panel.

CityPanel:

- Verify `ExposedMembers.CAIInfo:RequestCityInfo(...)` for selected and explicit local-player city ids.
- Verify city summary, coordinates, buildings, followers, amenities, housing, growth, production, and yield helpers match vanilla.
- Verify `~`, `Shift+1` through `Shift+0`, and `SelectionActions` behave correctly for cities.
- Verify new CITY actions appear in key bindings, are unbound by default, and trigger vanilla city-panel actions when bound.

UnitPanel:

- Verify no Lua errors from `UnitPanel_CAI.lua`, `worldInfo.lua`, or `caiIngame.lua`.
- Verify unit selection speaks one concise summary.
- Verify `~`, `Shift+1` through `Shift+0`, and `SelectionActions` behave correctly for units.
- Verify disabled unit actions are readable and do not execute.
- Verify plot info still reports aggregated units without depending on `UnitPanel_CAI.lua`.

WorldInput / cursor / notifications:

- Verify remappable cursor actions move the CAI cursor and camera correctly.
- Verify numpad no longer moves the cursor unless rebound by the user.
- Verify notification speech de-duplicates and includes summary/location when available.
- Verify `Ctrl+N` opens the notification tree; Enter/Space activate, Delete dismisses, Shift+Delete dismisses group items.
- Verify wrong-phase notifications do not activate and end-turn blockers stay out of the notification center.
- Verify Space and Ctrl+Space do not trigger next action/end turn during tutorial steps without an ActionPanel detailed UI trigger, especially the first `OPEN_CITY_PANEL` / city-panel production selection step, and remain inert while the vanilla tutorial slow-turn input shield is visible.
- Verify ActionPanel speaks the current main blocker tooltip once when it changes, such as end turn, choose production, select unit, research, civic, or policy blockers, without repeating on ordinary refreshes.
- Verify Escape closes the `Ctrl+Space` ActionPanel turn blocker list.

WorldTracker:

- Verify `T` opens ResearchChooser, `C` opens CivicsChooser, and `W` speaks live research/civic/unit summary.
- Verify `T` and `C` do nothing when the matching live WorldTracker research/civic open control is disabled by tutorial or WorldTracker filtering.
- Verify summaries still work when visual WorldTracker panels are hidden/collapsed.
- Verify no persistent WorldTracker CAI panel appears in Tab navigation.

TopPanel:

- Verify `Shift+T`, `Y`, `Ctrl+Y`, and `Q` behavior.
- Verify yield/resource pushed lists close with Escape and return to normal focus.
- Verify yield breakdowns use localized vanilla text and do not repeat full tooltips unnecessarily.

Frontend/shared:

- Verify refreshed frontend/shared files still open without Lua errors.
- Verify IntroScreen still skips inaccessible startup/EULA screen as intended.
- Verify LoadGameMenu keyboard behavior with the updated vanilla `KeyHandler` plus CAI block.
- Verify My2K accessible dialogs: account menu, login, sign-up, legal document list/detail, logout/unlink confirmations, disabled-state speech, successful return to main menu.

Unit operation hotkeys:

- Verify the mod loads without database errors.
- Verify new unbound Unit Actions appear in Options > Key Bindings.
- Bind a few actions, such as Build Improvement, Pillage, and Upgrade, and verify they trigger the matching selected-unit operation when available.

## Known Gaps / Next Steps

- Test GovernmentScreen first; it is the current active feature.
- Test CivicsChooser accessibility after GovernmentScreen.
- Implement ProductionManager / multi-queue accessibility.
- Implement LoadScreen accessibility from the existing plan in `docs/game-api.md`.
- Review unclear older replacements: `InGameTopOptionsMenu_CAI.lua`, `IntroScreen.lua`, `FrontEndPopup.lua`, `MapSelect.lua`.
- Review `data/hotkey_config.xml` for completeness after the recent hotkey expansions.
- No automated test harness exists; rely on XML parse checks plus in-game Lua log/user testing.
- In-game UI screens beyond the current wrappers still need accessibility work.

## Durable Decisions / Traps

- Civ VI UI Lua does not reliably expose included local functions through `_G`; wrap direct function names immediately after `include(...)` when possible.
- Prefer live vanilla control state for visibility/disabled checks. Hidden widgets may still be built, but navigation skips them through `IsHidden`.
- Prefer existing control text/tooltips through `GetText()` / `GetToolTipString()` over manual `Locale.Lookup()`.
- Use `Locale.Lookup()` only when no existing control exposes the text or for CAI-specific strings.
- Tree expand/collapse behavior belongs in the generic `Treeview` template; screens add only screen-specific activation logic.
- Pushed transient trees/lists should usually inherit the current stack priority and close themselves cleanly through the UI manager.
- Avoid persistent mirrors for ambient HUD panels when hotkey/read-on-demand access works better.
- End-turn-blocking notifications belong with ActionPanel access, not the notification center, because vanilla does not create rail instances for them.
- Do not silently cache displayed values. Cache references/ids only, then read live data.

## Recently Completed / Compressed History

- AdvancedSetup: verified working, with accessible Basic/Advanced tabs and ESC/back behavior.
- Frontend/shared refresh: full replacement files refreshed from Steam install and CAI blocks reinserted.
- My2K: accessible dialog coverage implemented.
- ProductionPanel: major tree/queue/tutorial-gating accessibility work implemented; pending in-game verification.
- ResearchChooser: aligned with vanilla selection flow; tutorial/live-control state added.
- CityPanel: selected city info helpers and action list implemented.
- UIScreenManager: priority stack, focus guards, widget id APIs, and destruction fixes added.
- WorldTracker: hotkey-driven research/civic/unit summary access implemented.
- TopPanel: hotkey-driven turn/time/yield/resource access implemented.
- NotificationPanel: transient notification tree and event-driven cursor sync implemented.
- UnitPanel: selected unit info and action list implemented.
- Unit operations: unbound hotkey ids added for vanilla operations lacking `HotkeyId`.
- GovernmentScreen: latest implementation complete enough for in-game testing.
