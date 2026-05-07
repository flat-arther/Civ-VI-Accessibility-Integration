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

No active feature. CivicsTree, GovernmentScreen, and CivicsChooser are implemented and verified in-game.

Latest analysis note:

- GovernmentScreen CAI received a full structural rewrite in `src/UI/inGame/GovernmentScreen_CAI.lua`. The wrapper is now a one-way reactive adapter over vanilla: shared wrappers sync CAI state from live vanilla data and then refresh the visible CAI tree, while `RefreshPoliciesTree()` / `RefreshGovernmentsTree()` are render-only and never call upstream refresh functions. Runtime state was collapsed into `m_state` and `m_ui`, deferred government-policy refresh bookkeeping was removed, tree-refresh reentry protection was removed, and the only remaining special refresh guard is the internal vanilla policy-control refresh guard used during local CAI assign/remove flows. Pending in-game verification.
- GovernmentScreen CAI refresh model was refactored to stop destroying/recreating the whole CAI tab body on tab switches and vanilla refresh hooks. The CAI panel now builds both tab trees once per open: Governments refresh clears and repopulates the root governments tree in place, while Policies keeps the four category row nodes alive and only clears/repopulates their child slot widgets. Action buttons are also persistent and now hide/show by active tab instead of being recreated. Follow-up fix: the wrapped `RefreshAllData()` path now also refreshes the active CAI tree, so vanilla event-driven refreshes such as `GovernmentChanged` cannot leave the accessible tree stale. CAI focus capture/restore was removed from this screen refresh path as unnecessary. Pending in-game verification.
- GovernmentScreen unlock-button blank-label issue traced from in-game logging: on first normal open, vanilla populates `UnlockPolicies` but leaves `UnlockGovernments` empty because the open path is `OnOpenGovernmentScreenMyGovernment()` -> `SwitchTabToMyGovernment()`, not the real vanilla Governments tab. CAI maps vanilla My Government to its own Governments view, so it was rebuilding the CAI Governments action row from `Controls.UnlockGovernments` before vanilla `RealizeGovernmentsPage()` had ever run. Patched by explicitly priming `RealizeGovernmentsPage()` inside the wrapped `SwitchTabToMyGovernment()` before rebuilding the CAI Governments body. Pending in-game verification.
- GovernmentScreen policy-slot regression identified in `src/UI/inGame/GovernmentScreen_CAI.lua`: a recent refactor stopped refreshing CAI's captured active rows from live culture data after vanilla `RealizeActivePoliciesRows()`. Vanilla only realizes filled policy cards there, so empty slots disappeared entirely from the CAI Policies tree after tab switches and especially right after government changes. Fixed by restoring the post-row-rebuild live-slot sync when `m_caiSuppressRebuild` is false, which preserves pending assign/remove mirrors while repopulating empty slots for normal open/tab/government-change flows. Follow-up user test narrowed the remaining trap: the stale data is the built child slot list, not the outer row summaries, because row summary getters are already dynamic. CAI now consumes the pending-government-change flag inside `BuildPoliciesBody()` itself, refreshing the live slot mirror immediately before creating policy-row children so the rebuilt slot widgets use the current government layout on the first automatic switch to Policies. Pending in-game verification.
- GovernmentScreen Policies tree now uses lazy row-child rebuilding on `TreeviewItem.OnToggleExpanded` / focus while expanded, reading live culture slot data per row instead of snapshotting slot children at body-build time. After that refactor, the older captured-row scaffolding was trimmed: unused screen-enum constants, unused government-instance capture, catalog capture, row-capture tables, and thin pass-through rebuild helpers were removed so the wrapper now keeps only the slot-policy mirror needed for pending unconfirmed edits.
- GovernmentScreen policy-change focus trap found after the lazy row-child refactor: rebuilding expanded row children from `OnFocusEnter` could clear and recreate the row subtree while the UI manager was restoring focus back from the policy picker into one of those children, leaving focus effectively stuck. The row-child resync hook is now `OnToggleExpanded` only; ordinary policy assign/remove still refreshes vanilla controls and the slot-policy mirror, but no longer destroys the focused row subtree during focus restoration.
- GovernmentScreen government-change follow-up analysis completed from base Lua plus user screenshot. The screenshot shows vanilla already has the correct new government slot layout and an enabled `Confirm Policies` button, so the bug is in CAI state mirroring rather than the base screen. Confirmed traps so far: `OnAcceptGovernmentChange()` switches to Policies but does not repopulate `m_ActivePolicyRows`, and CAI must not keep its own button-state model here. GovernmentScreen is now back on the `SetCAITab`-driven flow: tab wrappers own body rebuilds, `SetCAITab()` updates both tab-bar selection fields, and rebuild focus only targets the body's second child when vanilla switched tabs and `m_caiUserSwitchedTab` is false. Pending in-game verification.
- ProductionPanel CAI close-path bug found and patched: `OnPanelClosedCAI()` was using `mgr:Pop()`, which could remove the current top widget instead of the actual production panel. During district placement that top widget can be the CAI district-placement interface, which matches the observed focus drop back to game view after confirming placement. The handler now removes the production panel by its own widget id. Verified in-game.
- ProductionPanel district-placement close/reopen behavior is now confirmed from base Lua and documented in `docs/game-api.md`: production-build district placement (`ZoneDistrict`) explicitly closes the panel before placement, queue mode reopens the panel on return via `StrageticView_MapPlacement_ProductionOpen`, non-queue production only auto-reopens on cancel, and purchase-district placement does not use the same explicit close path.
- Interface preview refactor implemented: `src/UI/inGame/unitHelpers_CAI.lua` was renamed to `src/UI/inGame/interfaceInfoHelpers_CAI.lua`, movement preview was generalized into interface-mode preview dispatch, district placement preview now reuses vanilla adjacency helper text plus CAI-owned/purchasable state checks, `PlotInfo5` now reads interface preview instead of movement-only preview, and `WorldInput_CAI.lua` now has a CAI district placement interface widget while dropping the redundant `UnitPathInfo` shortcut. Verified in-game.
- Wonder placement follow-up analysis completed from base Lua. Vanilla uses `InterfaceModeTypes.BUILDING_PLACEMENT`, shows valid and purchasable plots plus hover focus, but does not expose district-style adjacency badges; the main explanatory text for wonders comes from the confirmation popup `SUCCESS_CONDITIONS`. CAI currently only handles `DISTRICT_PLACEMENT`, so wonder placement should be added through the same shared interface-preview path and interface widget pattern.
- Wonder placement CAI support is now implemented in `src/UI/inGame/interfaceInfoHelpers_CAI.lua` and `src/UI/inGame/WorldInput_CAI.lua`: `BUILDING_PLACEMENT` now reports valid / owned / purchasable / invalid through `PlotInfo5` and automatic cursor speech, and exposes the same CAI interface widget pattern as movement and district placement. Pending in-game verification.
- District / wonder placement investigation completed from base Lua. Findings for `StrategicView_MapPlacement`, `DistrictPlotIconManager`, `AdjacencyBonusSupport`, `PlotInfo`, and the district-versus-wonder placement info split are now documented in `docs/game-api.md`.
- Diplomacy UI investigation completed from base Lua. Findings for `LeaderView`, `DiplomacyActionView`, `DiplomacyDealView`, `DiplomacyRibbon`, first-meet flow, open paths, intel tabs, and deal contents are now documented in `docs/game-api.md`.
- LeaderView accessibility wrapper implemented in `src/UI/inGame/LeaderView_CAI.lua` and registered in `src/CivViAccess.modinfo`.
- ProductionPanel open-target analysis completed from base Lua. Vanilla `CreateCorrectTabs()` always initializes to Production first, then city-panel purchase open handlers explicitly switch tabs after `Open()`. CAI now keeps its requested tab across panel close/open teardown so CityPanel purchase actions can reopen the accessibility panel on Gold/Faith instead of falling back to Production. Pending in-game verification.
- ProductionPanel follow-up analysis found the real trap: `include("ProductionPanel")` runs `Initialize()` immediately, so city open LuaEvent handlers and `m_tabs` tab callbacks capture the original vanilla functions before CAI wraps them. The effective CAI sync point is `LuaEvents.ProductionPanel_ListModeChanged(...)`, which fires from the real vanilla tab switch callback. CAI now listens there to update its tab/body/default-index from vanilla's actual selected list mode. Pending in-game verification.

Files involved in the most recent verified work:

- `src/UI/inGame/GovernmentScreen_CAI.lua`
- `src/UI/inGame/CivicsChooser_CAI.lua`
- `src/UI/Popups/InGamePopup_CAI.lua`
- `src/CivViAccess.modinfo`
- `src/Text/en_US/cai_text_ui.xml`
- Shared widget changes in `src/UI/uiManager/widgetTemplates.lua`

What is implemented:

- Government screen wrapper registered as a replacement.
- CAI exposes two tabs: Policies and Governments. Vanilla My Government maps to the CAI Governments view.
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
- After accepting a government change, CAI now forces a full government-screen data refresh before rebuilding Policies so the new policy slot layout appears immediately and Confirm Policies reflects the real remaining empty slots.
- CAI GovernmentScreen action buttons now read live policy/government action state instead of caching a stale snapshot from the first body build.
- GovernmentScreen CAI now reads confirm/unlock button label, hidden, and disabled state directly from the live vanilla controls while keeping the older `SetCAITab` tab-switch/rebuild model. Pending in-game verification.
- GovernmentScreen CAI now keeps its Governments and Policies trees alive for the full open-screen lifetime and refreshes only their changing children in place. Policies category rows stay persistent instead of being rebuilt on each refresh.
- GovernmentScreen CAI state/runtime flow was simplified: the file now uses centralized `m_state` / `m_ui` tables, keeps only one special-purpose refresh guard for internal vanilla policy-control refreshes, and removes deferred government-change policy refresh state.
- XML parse checks passed for the edited XML/modinfo files.
- ActionPanel now has a Ctrl+Space CAI turn blocker list (`ActionPanelOpenTurnBlockers`, `CAIActionPanelTurnBlockerList`). Rows activate through vanilla `DoEndTurn()` / `DoEndTurn(blockerType)` and respect backing vanilla button hidden/disabled state where available.
- Latest chooser/action fixes: ResearchChooser and CivicsChooser first-letter search now stays on root rows, queue position ignores nonqueued sentinel values, WorldTracker research/civic hotkeys respect the live tracker control disabled state before opening choosers, Space/Ctrl+Space end-turn hotkeys respect live disabled state plus tutorial ActionPanel UI-trigger gating and the vanilla tutorial slow-turn input shield, and GovernmentScreen no longer adds its own root Escape binding.
- ProductionPanel CAI tab-sync cleanup: CAI now follows vanilla tab-change callbacks directly for Production / Purchase Gold / Purchase Faith / Queue open paths, redundant pass-through wrappers were removed, and duplicate tab-bar default-index updates were trimmed; pending in-game verification.
- Tutorial ActionPanel analysis: active base-tutorial detailed steps that show ActionPanel are `TURN_BASED_C`, `SELECT_RESEARCH_8`, `SELECT_END_TURN_B`, `SELECT_END_TURN_PRODUCTION`, `SELECT_END_TURN_C`, `SELECT_END_TURN_D`, `SCOUTS_D2`, `SCOUTS_E`, `SELECT_END_TURN_RESEARCH`, and `RESEARCH_IRRIGATION`; `NOTIFICATION_PANEL` only uses an advisor-side ActionPanel pointer.
- Notification analysis documented in `docs/game-api.md`: `NotificationManager.SendNotification(...)` takes a numeric type id, `notification:GetType()` matches `GameInfo.Notifications[...].Hash`, unregistered types fall back to `NotificationTypes.DEFAULT`, and CAI can safely own custom notification types by registering hashes in `g_notificationHandlers[...]` through the `NotificationPanel_*.lua` wildcard include path.
- ActionPanel input handler now only wraps `OnInputActionTriggered`; vanilla `LateInitialize()` registers the wrapped global, avoiding duplicate input-action subscriptions.
- ActionPanel context input handler now routes only through CAI UI manager and no longer falls back to vanilla Enter / Shift+Enter end-turn handling.
- ActionPanel refresh handler speaks the live main action tooltip when it changes, using the post-vanilla `EndTurnButton` tooltip as the source of truth. Speech is gated by ActionPanel context visibility and tutorial ActionPanel permission, and the tutorial allow event forces one current-action announcement.
- ActionPanel turn blocker list closes with Escape.
- Camera/nav cursor analysis documented in `docs/game-api.md`: vanilla exposes `Events.Camera_Updated`, but selected-object sync should primarily use unit/city selection events and explicit `LookAtPlot` touch points, with camera-center sync treated as an optional throttled fallback.
- WorldInput CAI cursor startup now snaps to the current camera focus via `UI.GetMapLookAtWorldTarget()` -> `UI.GetPlotCoordFromWorld(...)`, rather than preferring a selected unit.
- UnitPanel and CityPanel selection summary handlers now move the CAI cursor to the selected unit/city location after speaking the summary.
- UnitPanel action summaries and `SelectionActions` now filter out all vanilla-disabled rows via `action.Disabled`, covering both operations and tutorial-disabled commands such as Delete Unit.
- Unit command hotkeys now mirror the prior unit-operation hotkey expansion: visible vanilla `UnitCommands` without safe existing input paths get `HotkeyId` values in `unitOperationConfig.sql` plus unbound `UNIT` input actions in `hotkey_config.xml`. `UNITCOMMAND_DELETE` is excluded because vanilla already has the `DeleteUnit` action and a separate UnitPanel special case.
- Unit selection category labels and unit navigation/path hotkey labels now have CAI localization. Unit command hotkey labels intentionally use vanilla unit-command localization.

## Pending Test Queue By Area

ProductionPanel:

- Revised to ResearchChooser conventions: every production / purchase row is now an expandable TreeviewItem. Outer label is the item name (plus recommended tag), the item tooltip is a brief summary (cost / turns from vanilla CostText, plus the second line of the vanilla button tooltip), and expanding the row reveals the full breakdown rows from the vanilla button tooltip with the duplicated leading name line skipped. The read-only Edit detail box is gone, along with `LOC_CAI_PRODUCTION_DETAIL_LABEL`.
- Unit formations stay nested: base unit row is itself the build-base activation, with breakdown children plus separate Corps and Army child rows that each carry their own breakdown. Vanilla `CorpsArmyArrow` still toggles via `OnCorpsToggle` when the base row expands or collapses.
- Queue tab kept simple: current production button + queued buttons remain non-expanding rows for management only.
- Verify production/purchase Enter activation and Shift+Enter Civilopedia behavior.
- Verify Right arrow expands an item to the breakdown rows, Left arrow collapses, and Enter still activates rather than expanding.
- Verify the outer item tooltip reads cost/turns plus a short description and does not repeat the item name.
- Verify the breakdown children (yields, prereqs, status lines from the vanilla tooltip) read cleanly with the leading name line stripped.
- Verify base unit expand reveals breakdown rows followed by Corps/Army children, each themselves expandable to their own breakdown, with the vanilla CorpsArmyArrow staying in sync.
- Verify the cost line in every row tooltip / detail also reads the `LOC_TURNS_REMAINING_VAL` turns-left clause, matching the ResearchChooser/CivicsChooser cost-and-turns format.
- Verify the current-production tree node now uses the same `BuildItemDetail` cost/description/maintenance/stats layout as the rest of the production rows (no separate vanilla status/progress/cost duplicate lines).
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
- Verify disabled unit actions do not appear in the spoken action summary or `SelectionActions` list, including tutorial-disabled commands such as Delete Unit.
- Verify enabled commands and operations still activate through vanilla callbacks.
- Verify previous/next unit category announces the localized active category, and unit navigation/path keybinding labels appear localized in Options.
- Verify plot info still reports aggregated units without depending on `UnitPanel_CAI.lua`.

WorldInput / cursor / notifications:

- Verify remappable cursor actions move the CAI cursor and camera correctly.
- Verify numpad no longer moves the cursor unless rebound by the user.
- Verify wonder placement preview is spoken automatically on cursor move and repeats cleanly on `PlotInfo5`.
- Verify the CAI wonder placement interface widget opens during `BUILDING_PLACEMENT`, confirms on primary action, and cancels on Escape.
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
- Verify rewritten GovernmentScreen CAI opens and closes without Lua errors after the one-way reactive refresh rewrite.
- Verify GovernmentScreen Policies rows now always expose the live slot children after opening the screen, switching from Governments back to Policies, and immediately after accepting a government change with newly empty slots.
- Verify GovernmentScreen refresh-in-place does not dump focus unexpectedly when vanilla refreshes the active tab, especially after unlocking policies/governments or after other screen-driven refresh events.
- Verify GovernmentScreen local CAI policy assign/remove still preserves pending slot state correctly even though tree refresh is now strictly render-only and no longer triggers upstream refresh.
- Verify GovernmentScreen first normal open now speaks/shows the Governments-side unlock button label without needing a Policies -> Governments tab cycle.
- Verify GovernmentScreen immediately rebuilds the Policies tree after accepting a new government, including changed slot counts/types, without needing to close and reopen the screen.
- Verify after filling every slot on the new government, Confirm Policies enables and changes from Assign All Policies to Confirm Policies.
- Verify replacing or removing a policy while the screen stays open does not revert the CAI tree back to the committed pre-confirmation layout.
- Verify IntroScreen still skips inaccessible startup/EULA screen as intended.
- Verify LoadGameMenu keyboard behavior with the updated vanilla `KeyHandler` plus CAI block.
- Verify My2K accessible dialogs: account menu, login, sign-up, legal document list/detail, logout/unlink confirmations, disabled-state speech, successful return to main menu.

Unit operation / command hotkeys:

- Verify the mod loads without database errors.
- Verify new unbound Unit Actions appear in Options > Key Bindings.
- Bind a few actions, such as Build Improvement, Pillage, and Upgrade, and verify they trigger the matching selected-unit operation when available.
- Bind a few command actions, such as Promote, Wake, Cancel, Form Corps, Airlift, and Pet the Dog, and verify they trigger the matching selected-unit command when available.
- Verify Delete Unit still appears only through vanilla `DeleteUnit` and does not double-open its confirmation prompt.

## Known Gaps / Next Steps

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
- TutorialGoals now use custom `NOTIFICATION_CAI_TUTORIAL_GOAL_ADDED` / `NOTIFICATION_CAI_TUTORIAL_GOAL_COMPLETED` types sent from Lua and activated through the NotificationPanel wildcard extension path rather than `USER_DEFINED_*`.
- UnitPanel: selected unit info and action list implemented.
- Unit operations and commands: unbound hotkey ids added for visible vanilla operations/commands lacking safe existing `HotkeyId` paths.
- GovernmentScreen: implementation complete and verified in-game.
- CivicsChooser: implementation complete and verified in-game.
- CivicsTree: implementation complete and verified in-game. Live-control labels and tooltips, era-grouped main tree, queue tree with shared row format, filter as a `DropdownMenu` that pushes a `MenuItem` list and rebuilds the main tree on selection, government summary as a read-only `Edit`, `IsDisabled` mirroring vanilla clickability (READY and BLOCKED enabled; RESEARCHED, CURRENT, UNREVEALED disabled), reference links disabled when target is unrevealed, Backspace breadcrumb stack on the main tree using widget ids + `GetChildById`, unified queue-added announcement reporting count and total culture cost, ESC routed through vanilla `Close()` via the wrapped input handler.
