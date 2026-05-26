# Project Status: Civ VI Accessibility Integration (CAI)

Last compacted: 2026-05-21
Last updated: 2026-05-26 (InGameTopOptionsMenu migration to new UI manager)

## UI Manager Rework (branch: UIManagerRework)

The UI manager has been rewritten as a class-based widget framework. The four old files (`baseWidget.lua`, `widgetTemplates.lua`, `widgetTemplateHelpers.lua`, `UIScreenManager.lua`) are deleted. The new framework lives under `src/UI/uiManager/` and `src/UI/uiManager/helpers/` with `CAIWidget_*` / `CAIWidgetHelpers_*` / `CAIUIScreenManager` file naming for VFS uniqueness.

- Framework is complete: `UIWidget` / `ContainerWidget` / `ValueWidget` base classes plus 20 concrete widgets (Button, MenuItem, StaticText, Panel, Dialog, List, HorizontalList, SubMenu, Tree, TreeItem, Dropdown, Checkbox, Slider, EditBox, TabControl, Tab, TabPage, Table, GameView, InterfaceMode). Five helper modules (Navigation, Search, Tree, EditBox, DialogBuilder).
- Manager-level additions over the old model: multi-listener event system (`On/Off/Emit`), single-source-of-truth focus path with directional entry (Windows tab-stop semantics), `FocusKey` + `CaptureFocusKey` + `RestoreFocus` for rebuild-survival, `Refocus` and `Announce` for out-of-band re-speak, path pruning on destroy, hidden-ancestor input skip, `_focusSound` auto-played on focus enter, `Transparent` widget flag, PgUp/PgDn paging, same-letter type-to-find cycling.
- Speech follows the Windows one-line-per-widget model. Multi-line emission routes through `SpeakLines(lines, interrupt)` where only the first line interrupts; the rest queue.
- Docs: `docs/ui-manager.md` is the source of truth (19 sections — architecture, focus, speech, events, widgets, helpers, migration). LuaLS annotations in `src/ideHelpers.lua`.
- A disposable test screen lives at `src/UI/test/CAITestScreen.lua`, exercised via `LuaEvents.CAITest_Open/Close/Rebuild/Refocus`. Delete once the first migrated screen is verified.
- **Migrated screens:** `src/UI/frontEnd/MainMenu.lua` CAI block and `src/UI/inGame/InGameTopOptionsMenu_CAI.lua` now use the new framework (CreateWidget, On("activate"/"focus_enter"/"focus_leave"), CaptureFocusKey/RestoreFocus, FocusKey rows, Push with mirrored vanilla flow). The disposable `src/UI/test/CAITestScreen.lua` and the `UI/test/` directory have been deleted along with the three `.modinfo` references. All other `*_CAI.lua` screens still use the old API and will fail to load on this branch; migrate them per `docs/ui-manager.md` section 16. Next pilots: `LoadGameMenu.lua` or `Options.lua` before tackling `ProductionPanel_CAI.lua` / `CivicsTree_CAI.lua`.
- **InGameTopOptionsMenu migration notes:** main button list activates rows by calling `child:DoLeftClick()` on the underlying vanilla `GridButton` instead of mapping controls to specific action functions; children of `MainStack` are filtered by non-empty `GetID()` so unnamed spacer Containers are skipped. The information section (`DetailsBox`) and the mods section (`ModsInUse`) are read-only `AlwaysEdit` EditBoxes — `SetText` normalizes `[NEWLINE]` to `\n` so no manual newline splitting is needed for the version tooltip; the mods listing's vanilla single-space spacer instance is emitted as a real `\n` separator, but only when it sits between real entries (leading/trailing spacer instances are trimmed). Expansion include chain: the file follows `Civ6Common`'s `IsExpansion1Active`/`IsExpansion2Active` to include `Expansion1_InGameTopOptionsMenu` when an expansion is active — required so the expansion's `LateInitialize` registers the `ExpansionNewFeatures` eLClick callback that `DoLeftClick()` relies on.
- **Manager mirrors vanilla flow** (durable rule). CAI never drives push/pop on its own; it observes vanilla's screen state and uses `mgr:RemoveFromStack(id)` (not `Pop`) when vanilla closes/rebuilds a section. Escape is NOT bound at the manager level — vanilla owns Escape, CAI follows. MainMenu submenu teardown is driven by inspecting `m_currentOptions[i].isSelected` after vanilla's `ToggleOption` runs.

## Purpose

Civilization VI accessibility mod for blind players. Adds TTS and screen-reader navigation through Lua UI replacements and wrappers.

- Authors: FlatArther and Hamada
- Source entry: `src/CivViAccess.modinfo`
- Deploy model: `src/` is symlinked into the Civ VI mod folder
- Core rule: all TTS goes through `Speak()` from `caiUtils.lua`
- API notes and discovered behavior live in `docs/game-api.md`

## Gate Check

- Tier 1 analysis is complete for the current codebase.
- Before new feature work: check `docs/game-api.md`, then verify uncertain behavior against actual Lua in `decompiled/` or the Steam install.
- Safe mod keys, input/context rules, localization rules, and screen-specific patterns are documented in `docs/game-api.md`.

## Current State

The large implementation backlog from earlier sessions is considered resolved for tracking purposes and has been compacted out of this file at the user's request.

- Core in-game CAI systems are implemented and integrated.
- Shared UI manager, widget system, and focus-routing infrastructure are in place.
- Major screen replacements and wrappers are in place for city, unit, diplomacy, government, civilopedia, world input, scanner, notifications, top-panel/world-tracker style reads, and related helpers.
- The old open verification queue has been closed administratively during compaction. Some items were implemented but not exhaustively re-verified in game before being removed from the queue.

## Resolved Areas

- `caiUtils.lua`: shared speech and utility wrappers; now exposes `Speak` and `SpeakLines`.
- UI manager rewritten on the `UIManagerRework` branch into a class-based framework under `src/UI/uiManager/` and `src/UI/uiManager/helpers/`. The four old files are deleted; see the "UI Manager Rework" section above for the new layout and `docs/ui-manager.md` for the design.
- `CityPanel_CAI.lua`: city summary, helper reads, and city `SelectionActions` support are implemented.
- `UnitPanel_CAI.lua`: unit summary, stats, actions list, queued path, combat preview speech, post-combat speech, unit list, builder recommendation gating, build-improvement submenu, and carrier special-info reads are implemented.
- `UnitFlagManager_CAI.lua`: expansion-aware include selection and short spoken flag info are implemented, including aircraft capacity count.
- `PlotToolTip_CAI.lua`: plot detail reads and shared plot info access are implemented.
- `WorldInput_CAI.lua` and helper modules: cursor, interface info, move/path speech, targeting widgets, quick-move confirmation, and related scanner hooks are implemented.
- `WorldScanner` modules: scanner categories, lazy rebuild behavior, valid-targets integration, waypoint support, and supporting helpers are implemented.
- `DiplomacyActionView_CAI.lua`, `DiplomacyDealView_CAI.lua`, and `DeclareWarPopup_CAI.lua`: major diplomacy accessibility wrappers are implemented.
- `ProductionPanel_CAI.lua`, `ResearchChooser_CAI.lua`, `CivicsChooser_CAI.lua`, `CivicsTree_CAI.lua`, `GovernmentScreen_CAI.lua`, and `CivilopediaScreen_CAI.lua`: major screen accessibility work is implemented.
- Frontend accessibility work for items such as Advanced Setup and My2K is implemented.

## Recent Decisions

- Shared unit naming lives in `inGameHelpers_CAI.lua`; avoid duplicating formation/name formatting logic.
- `SubMenu` in `widgetTemplates.lua` is now an entered child container, not a spoken expanded/collapsed tree-style node.
- Unit build improvements are grouped into a dedicated CAI submenu under unit `SelectionActions`.
- Disabled build-improvement actions are hidden only when vanilla provides no failure reason.
- Carrier/unit-hosted aircraft details are shared through `inGameHelpers_CAI.lua`; unit flags still speak count/capacity only.
- Plot-target and interface-target speech should prefer shared helper/data paths over screen-local reconstruction.
- City banner growth/production reads must support both vanilla base controls and XP1/XP2 stat-row instance managers; expansion banners move those tooltips and meters off the top-level banner instance.
- City banner bucket layout is now intended as `1` identity/status, `2` growth/production, `3` religion, `4` diplomacy, `5` loyalty, `6` governor, `7` power.
- City panel parity check shows `CityPanel_CAI.lua` still only covers compact summary reads plus action/toggle access; it does not yet mirror vanilla overview breakdown tabs (district/building/wonder/trading-post lists, religion beliefs, amenities/housing source breakdowns, detailed growth math, production queue) or XP1/XP2 loyalty/governor/power tabs.
- Main `CityPanel` buckets were redone to use single-purpose helpers plus shared request buckets. Current main-panel mapping is summary/tilde = name, population, health, production, growth; `Shift+1` name+health; `Shift+2` production; `Shift+3` food growth; `Shift+4` border growth; `Shift+5` religion; `Shift+6` population + housing + buildings or loyalty depending on active expansion; `Shift+7` through `Shift+0` are the yield buckets.
- City panel border-growth speech now aims at city-panel growth-tile parity: it includes the target hex direction relative to the city plus stored culture, culture per turn, required culture, and current / next-turn meter percentages.
- City `SelectionActions` ordering is now explicit instead of relying on the CITY hotkey-category order. Dynamic strike actions stay at the top, and the separate manage-citizens / purchase-tile actions are merged into one combined `Manage city` action that toggles both available city-management lenses together.
- City `SelectionActions` now append dynamic ranged-strike rows for the selected local-player city center and any strike-capable districts belonging to that city. Visibility is driven by `CityManager.CanStartCommand(..., CityCommandTypes.RANGE_ATTACK)` so the centralized list only shows attacks that vanilla would currently allow.
- City `SelectionActions` also append dynamic WMD strike rows for supported district launches such as missile silos. Availability is driven by vanilla-style `CityCommandTypes.WMD_STRIKE` target checks per district plot and per weapon type, and launching mirrors the banner `OnICBMStrikeButtonClick(...)` flow while also jumping the CAI cursor to the firing district.
- City panel action-list parity now includes the expansion overview tabs: `CityPanel_CAI.lua` follows the base / XP1 / XP2 `CityPanel` include chain, exposes XP1/XP2 loyalty-governor overview access through `LuaEvents.CityPanel_ToggleOverviewLoyalty()`, and exposes XP2 power overview access through `LuaEvents.CityPanel_ToggleOverviewPower()` when the underlying expansion capability is active.
- City-panel `Change production` accessibility should no longer blindly toggle `ChangeProductionCheck` when the vanilla production context is hidden. CAI now checks `/InGame/ProductionPanel` visibility first and calls `LuaEvents.CityPanel_ProductionOpen()` directly when needed, preserving vanilla queue-first tab choice while avoiding checkbox-state mismatches that consumed the first activation.
- `ProductionPanel_CAI.lua` now mirrors the Civilopedia-style rebuild focus handling: capture the focused body row before clearing, rebuild, restore by stable CAI focus key when possible, and otherwise reset the active body to its first child. Queue move/remove overrides still take precedence through the explicit post-rebuild queue index path.

## Durable Rules

- Prefer live vanilla control state for visibility, disabled checks, and exposed localized text.
- Prefer `GetText()` / `GetToolTipString()` over manual `Locale.Lookup()` when vanilla already exposes the text.
- Use `Locale.Lookup()` only when no control exposes the text or when the string is CAI-owned.
- Cache references and ids only; always read live values when speaking state.
- Tree expand/collapse logic belongs in shared templates, not screen-specific code.
- Pushed transient lists, trees, and dialogs should inherit current stack priority and close cleanly through the UI manager.
- Avoid persistent mirrors for ambient HUD panels when hotkey/read-on-demand access is better.
- End-turn blockers belong with ActionPanel access, not the notification center.
- For Civ VI gameplay DB values in Lua, remember that `0` is truthy. Explicitly test boolean-like DB fields and stat thresholds.

## Known Remaining Work

- Screen migration to the new class-based UI manager (per `docs/ui-manager.md` section 16). `MainMenu.lua` CAI block and `InGameTopOptionsMenu_CAI.lua` have been ported; every other `*_CAI.lua` file still uses the old `OnClick`/`OnFocusEnter`/`FocusedChild` patterns and must be ported. Tackle `ProductionPanel_CAI.lua` and `CivicsTree_CAI.lua` once an easier screen confirms the pattern; both currently carry 130-line rebuild-restore dances that collapse to ~3 lines via `FocusKey` + `RestoreFocus`.
- **Pending in-game test:** verify the new MainMenu CAI block on launch. Things to confirm: main menu rows speak with correct labels/tooltips/hidden state; opening Single Player / Multiplayer / Additional Content / Benchmark / WorldBuilder pushes a submenu list that reads; same-key re-toggle and switching parents both remove the old submenu cleanly via `RemoveFromStack`; Escape inside a submenu collapses via vanilla (not via the manager); MotD changes are re-announced only when focused; cloud-notify label changes refocus the matching row; carousel autoscroll pauses on focus_enter and resumes on focus_leave.
- **InGameTopOptionsMenu verified (partial):** other buttons activate via `DoLeftClick()`, `ExpansionNewFeatures` activates after fixing the expansion include chain, mods edit box no longer shows a leading blank line. Still worth confirming in a real save: navigation between button list / mods edit / details edit via Tab, arrow-key navigation inside both edit boxes (line-by-line read-on-demand), behavior with no enabled-modes section vs. enabled-modes + alphabetical mods (the spacer-only-between-entries rule), and Escape cleanly tearing down via vanilla `Close()` + `RemoveFromStack(PANEL_ID)` on the hide handler.
- `ProductionManager` / multi-queue accessibility is still not implemented.
- `LoadScreen` accessibility is still planned, not implemented.

## Session Notes

- Previous detailed implementation history and exhaustive verification backlog were intentionally removed during compaction to keep this file small.
- If older reasoning is needed, check `docs/game-api.md` and git history first.
- UI-manager refactor planning pass on 2026-05-24: current architecture is functional but mixed. `UIScreenManager.lua` is acting as factory + stack/focus controller, `widgetTemplates.lua` mixes declarative template defaults with widget-specific behavior, and `widgetTemplateHelpers.lua` has grown into a catch-all for navigation, dialog builders, search, and full edit-box behavior. Likely next step is to split shared container behavior from concrete widget classes and introduce a clearer widget-construction API before adding new composite widgets such as tables.
- `navCursor.lua` zone-change speech was cleaned up so cursor movement now tracks continent and owner-territory changes as stateful zones, speaks the localized continent name directly from `plot:GetContinentType()`, and uses vanilla `LOC_MINIMAP_UNCLAIMED_TOOLTIP` for unclaimed territory instead of the older CAI placeholder.
- NavCursor owner-zone speech now treats the local player as a known owner even though diplomacy `HasMet(...)` is not meaningful for self, and continent-zone speech now uses the CAI loc wrapper `LOC_CAI_NAV_CURSOR_CONTINENT_ZONE` (`The continent of {1_Name}`) instead of speaking the raw continent name.
- Settler-lens expansion analysis was verified against decompiled UI: the base / expansion minimap still colors only the four `Map.GetContinentPlotsWaterAvailability()` buckets, while expansion-only extras are overlay managers layered on top of that lens. `SettlerInfluenceIconManager.lua` adds loyalty-pressure number icons from `Map.GetContinentPlotsLoyalty()`, and `SettlerWarningIconManager.lua` adds flood, volcano, and XP2 coastal-lowland warning icons from environmental APIs.
- Settler-lens loyalty overlay semantics were also confirmed: Firaxis shows the exact loyalty-per-turn value for a hypothetical newly founded city on that plot, not a fixed named bucket set. Any scanner grouping beyond exact value would be CAI-defined behavior.
- The world scanner now exposes the current supported modal lens through an `Active lens` category. Supported first-pass lenses are settler, appeal, continent, owner, government, tourism, and XP2 power. The settler path still presents water availability, exact loyalty-per-turn values when XP1+ is active, and disaster overlays when XP2 is active. Loyalty group ordering is CAI-defined as highest value to lowest.
- Government-lens scanner grouping is now plot-owner aware at the city level: groups are keyed by government + owning civ + owning city so mixed empires do not collapse into one giant government bucket.
- Tourism-lens scanner support now mirrors the vanilla tourism banners with two simple views: `By city` and `By strength`. Strength buckets match Firaxis' own thresholds from `TourismBannerManager.lua` (`>= 16`, `>= 8`, and low otherwise).
- XP2 power-lens scanner support now mirrors the simple vanilla overlay shapes: `Power sources`, `Power range`, `Powered city plots`, and `Unpowered city plots`. Scanner invalidation also listens for `Events.CityPowerChanged` when that event exists.
- Minimap lens investigation is now documented for follow-up scanner work: base modal lenses are religion, continent, appeal, settler, government, owner, tourism, and empire; XP1 adds loyalty; XP2 adds power. The strongest next scanner candidates from confirmed live data are appeal, continent, owner, government, power, and tourism, while empire remains lower confidence because Firaxis implements it mostly through city / district banner detail instead of a dedicated plot-bucket data source.
- City-management investigation confirmed the base ownership split: `CityPanel.lua` owns the shell and toggles, `CityPanelOverview.lua` owns the detailed subpanels, `PlotInfo.lua` owns workable-plot / purchase / swap overlays, and `WorldInput.lua` only owns `CITY_MANAGEMENT` mode routing.
- The next city-management accessibility pass should prioritize structured speech for overview subpanels and a navigable model for `PlotInfo.lua` overlays, since those are the main parity gaps left for sighted city management.
- `CITY_MANAGEMENT` interface-mode accessibility is now routed through `interfaceInfoHelpers_CAI.lua` with a dedicated helper that rebuilds `PlotInfo.lua` state from live `CityManager.GetCommandTargets(...)` results rather than scraping overlay controls.
- The world scanner now has a `City management` category for active in-world city-management mode, grouped into state subcategories such as locked, specialists, worked, swappable, and purchasable tiles.
- `WorldInput_CAI.lua` now has a generalized interface-widget activation fallback: primary and secondary widget actions raise `LuaEvents.CAIInterfaceWidgetPrimaryAction(widgetId, plotId)` and `LuaEvents.CAIInterfaceWidgetSecondaryAction(widgetId, plotId)` when a mode widget does not override them directly.
- `PlotInfo_CAI.lua` now wraps vanilla `PlotInfo` for city management: it listens for the generic interface-widget events when `widgetId == "CAIWorldInputCityManagement"`, routes primary to purchase/manage and secondary to swap based on the current cursor plot state, and mirrors the vanilla affordable-purchase hover coin animation on `LuaEvents.CAICursorMoved`.
- City-management interface speech was tightened to state-only output: it no longer repeats base plot identity from `PlotToolTip_CAI.lua`, uses `Invalid target` for non-actionable plots, says `Unworked`, vanilla worked-citizen text, short specialist counts, `Swappable`, and purchase affordability only when present. `PlotInfo_CAI.lua` now speaks purchase / worker / swap feedback by wrapping the vanilla click handlers directly instead of listening to city change events.
- City-management action feedback now uses a primed pending-action payload plus matching game events instead of click-return data: manage waits for `CityWorkerChanged` and matches only owner + city, purchase waits for `CityMadePurchase` and matches owner + city + purchased plot, and swap waits for `CityTileOwnershipChanged` and matches owner + city before speaking the pending plot's refreshed state.
- `WorldInput_CAI.lua` now follows the base / XP1 / XP2 include chain via `Civ6Common.lua` expansion helpers instead of always including base `WorldInput`. CAI also exposes XP1 `PARADROP` / `PRIORITY_TARGET` and XP2 `BUILD_IMPROVEMENT_ADJACENT` / `MOVE_JUMP` as interface widgets, interface-info targets, and valid-target scanner modes.
- Unit hotkey cleanup policy was refined: only expose unit operations and commands as bindable actions when vanilla marks them `VisibleInUI="true"` in `UnitOperations.xml` or `UnitCommands.xml`.
- Data-file naming convention was tightened: files under `src/data/` should use a `_CAI` suffix to reduce future mod filename collisions, and `.modinfo` references should use those suffixed names.
- CAI keybinding UI now logs raw action loc tags on focus for debugging bad entries, and unit upgrade should be exposed only once through `UNITOPERATION_UPGRADE`, not a duplicate `UNITCOMMAND_UPGRADE` entry.
- Dynamic vanilla unit actions should not be exposed as direct keybindings. Current removed set: build improvements, enter formation, WMD strike, and offensive-spy mission rows that vanilla folds into a single chooser action.
