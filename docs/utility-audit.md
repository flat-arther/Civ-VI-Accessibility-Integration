# Utility consolidation audit

## Scope and method

The earlier passes were too narrow: they matched familiar helper names and left equivalent operations under other names and inside larger functions. This pass inspected authored in-game Lua recursively, searched generic operations as well as names, and compared normalized private-function bodies. The user expanded the scope to repeated frontend/shared utilities. Edits to frontend/shared screen replacements are restricted to their accessibility blocks; standalone utility modules such as caiUtils and textProcessing remain explicitly in scope. Vendored integrations are not rewritten wholesale.

Run `scripts/Audit-LuaUtilities.ps1` for the remaining repeated-body candidates. It currently inventories 2,915 private helper definitions and reports 66 groups. This is a review aid, not a parser or an extraction approval: identical source can capture different local state. Additional searches covered public helpers, nested functions, inline append/filter loops, string patterns, and direct concatenation. Ordinary `table.concat` or collection insertion is not itself a duplicate utility implementation.

## Corrected in this pass

- Removed or promoted 80 top-level private definitions across 61 inventoried files, plus the nested World Builder text-append wrapper. Callers use the common implementation directly.
- Replaced 101 inline nonempty-text append blocks with `CAIText.AppendIfNonEmpty`; the movement-segment filter now uses it too. The inspected fragments are text/numeric values. Nested fragment flattening retains its original scalar values, including false, through `AppendFragments`.
- Consolidated `AppendIfText`, `AppendLabel`, `AddLine`, `AppendCombatResultClause`, recursive `AppendUnitFlagInfo`/`AddIfPresent`, unique trimmed text, section composition, newline-token conversion, pairwise newline collapse, comparison normalization, crisis inline formatting, scanner trim/split/key sanitization, and promotion conjunction formatting in textProcessing.
- Consolidated balance, signed-value and per-turn formatting from Ribbon, Reports, TopPanel and WorldTracker. Locale formatting patterns and the zero case are preserved. Promotion conjunction formatting still consumes the final list element, matching its old contract.
- Consolidated matching text/tooltip readers from ActionPanel, Chat, research/civics, DealView, options, Minimap, PlayerChange, Production and UnitFlagManager. Optional empty-string and nil-returning contracts remain explicit in CAIControl. Governor tooltip/value assembly preserves the distinction between optional controls and required controls/methods.
- Consolidated seven sort comparators in CAICollection, preserving numeric ordering, nil-last behavior, locale comparison and the explicit boolean ordering variant. Dynamic column headers resolve through CAIText.
- Consolidated cursor-relative plot labels from Climate, Great Works and Reports in hexCoordUtils. Cursor and coordinates are read live. The geometry module explicitly includes textProcessing.
- Removed nine `MakeId` forwarding wrappers and the RET `Lookup` wrapper in favor of the existing manager/Locale APIs. Barbarian-clan wrappers now call the game configuration API directly. Surveyor and terrain helpers share `CAIIsDatabaseTrue`.

## Why remaining text builders stay local

- Unit combat strength, modifier and result builders choose combat-specific localization and live controls. Their generic appends use CAIText; the combat policy stays in UnitPanel.
- Diplomacy relationship, agenda, agreement and conversation builders own diplomacy data and visibility rules. Their generic formatting moved; the screen-specific implementation stays together as requested.
- Civilopedia's nested capture adapter localizes paragraph keys, filters supported captured values, strips tags for article capture and intercepts the vanilla article callbacks. It is not a generic append alias.
- Chat/history/message appenders assign IDs, retain bounded history, update categories or emit events. They are state operations, not text joining.
- Scanner category-ID normalization maps legacy IDs; key schemas and record signatures encode persisted domain identities. Their generic trimming, splitting and sanitization are centralized.
- Government comparison chooses its own newline-pair policy, and improvement duplicate-line removal compares against earlier prose. Both now compose common text primitives without reimplementing those primitives locally.
- Plot/banner bucket builders interpret conditional descriptor schemas. The schema interpreter is a separate candidate below; it must not be replaced by a plain text append.

## Remaining refactor work exposed by the broader audit

These are open work, not a declaration that utility consolidation or the refactor is complete.

1. **Research coordination: implemented.** CAIResearchTree, CAIResearchData and CAIResearchChooser now share the reusable chooser/tree/grid/graph/data/filter/navigation contracts. Domain adapters retain vanilla callbacks, technology columns, civic government/modifiers, and distinct tooltip/action semantics. See the completion audit below; the user confirmed the combined in-game check on 2026-10-04.
2. **Trade integrations: implemented.** CAITradeOrigin, CAITradeOverview and CAITradeData own matching navigation/data contracts; shared CAICapturedDropdown handles native capture synchronization. Integration-specific callbacks and actions stay local. See completion audit below; combined game validation is pending.
3. **Player/game-state helpers:** matching implementations consolidated in CAIGameState and shared CAIModSupport; see the completed batch below. Distinct observer fallback and tooltip-name contracts remain with their existing owners.
4. **Dialog and view lifecycle: audited.** Matching nil-natural sort-dropdown synchronization is shared in CAIColumns. Stack teardown/focus already belong to the manager; screen-local reference cleanup, native callback ordering, input eligibility and view-specific rebuild/focus identities remain local. See completion audit below.
5. **Collection/descriptor schemas: implemented.** CAIDescriptors shares plot/banner key expansion; CAIColumns shares column lookup and sort-menu composition. Cell builders that resolve game records or choose domain-specific presentation remain local; see completion audit below.

The audit script prints exact filenames and function names for the repeated-body candidates, including these deferred families. It does not detect every semantic duplicate, and a clean output would not prove the codebase duplicate-free.

## Verification and remaining game checks

- Full repository verification passes; new coverage exercises nested fragments, sections, UTF-8 trim, literal delimiters, localized number formats, list mutation, live control values, required control failures, sort contracts and live cursor replacement.
- A one-time differential check against pre-change helper bodies passed 131 representative cases. This supplements the earlier 320 formatting comparisons; it does not cover every possible engine value.
- All 61 inventoried changed chunks compile after the narrow Firaxis annotation transform. Searches found no remaining calls to the removed private names.
- New game smoke remains: research/production and diplomacy/espionage text; governor tooltips; banner/plot details; scanner search and custom categories; report sorting and cursor-relative labels; World Builder parameter readouts. No in-game session was run by Codex for this pass.
- The pre-existing missing audio asset remains the documented packaging exception.

## Shared/frontend follow-up

- CAIControl and CAICollection now live in UI/shared and are imported once in both CAIFrontEnd and CAIInGame. Neither depends on live game state. Shared modules may use Locale and common UI controls.
- caiUtils was audited: text trimming/sentence grouping moved to CAIText.SplitTextIntoLines; Keys/Invert moved to CAICollection. All old global callers and LuaLS declarations were migrated. The two speech-section callers explicitly pass the TokenSplitLength setting, preserving user configuration. Speak/SpeakLines, logging, WrapFunc and HijackTable remain in caiUtils; they already are shared APIs. Observer/world-builder/tutorial/action routing is context-dependent code, not pure text processing.
- Frontend control readers, nonempty appends, credits whitespace, explanation composition, staging color/line normalization and duplicate-line composition use shared implementations. ConcatLines preserves blank lines. Lobby's player-name parser retains its specific comma/@ handling. Staging hidden/disabled predicates now return booleans through CAIControl.
- Includes were moved inside the accessibility blocks. Comparing all 31 marked frontend/shared replacements with HEAD confirmed no outside-block source changes (ignoring line endings and trailing file newlines). Standalone utility modules have no such blocks.
- Frontend syntax verification checks the authored accessibility block; it does not claim to compile every unchanged Firaxis annotation. The full regression suite passes. New frontend loading and speech smoke checks remain pending.

## Game-state consolidation (2026-10-02)

- Implemented the matching player/game-state family above in CAIGameState: explicit ID/object/pair contracts, city-state access, era labels, religious classification, known-player names and World Builder state. Callers use the module directly; private forwarding aliases were removed.
- Moved the three identical BBG detectors to shared CAIModSupport after comparing their ID lists. Observer fallback, WorldCongress tooltip names and subsystem-specific research access remain distinct contracts.
- Added 31 production-helper checks covering local/observer/missing players, live religion changes, unmet and multiplayer names, ages, World Builder and all three BBG IDs. Game smoke for this batch is tracked in project_status.md. Research/trade coordination and the other domain families remain open.

## Research chooser batch (2026-10-03)

- Extracted matching queue/current classification and partitioning, turns/boost descriptions, and subtree rebuilding into CAIResearchChooser. Both chooser adapters pass current-turn/control readers and row factories explicitly; vanilla includes/wrappers, control maps, tutorial ordering/delayed push, domain descriptions and activation remain local.
- Registered the module in File and CAIInGame ImportFiles. The 42 regression assertions use production widgets for stable focus, silent same-row restoration, removed-row fallback and sibling-focus preservation; data checks cover queue sentinels, header deduplication, read-only queue factories, live turns precedence and just-completed suppression.
- This is the chooser portion of research coordination. Row/control adapters and technology/civics tree, grid, graph, filters, and view coordination still need comparison and extraction where justified. No performance or player-visible behavior change is claimed.
- The user confirmed the preceding game-state smoke good. The new chooser smoke checklist is in project_status.md; Codex has not run the game.

## Technology/civics completion audit (2026-10-03)

- Finished the research family as one batch at the user's request. CAIResearchTree owns widgets, row factories/detail buckets, era/column grouping, graph edges, queue inspection, filters/results, search, view settings/switches, focus, breadcrumbs and lifecycle. CAIResearchData owns live data descriptions and topology maps; both choosers share control resolution and cost/progress/description formatting in addition to their earlier queue/turn/rebuild extraction.
- The domain screen adapters retain all vanilla/DLC/scenario includes, captured functions and events, operation/path contracts, technology prerequisite-column calculation and alliance output, civics government/policy/modifier data, and the existing distinct tooltip visibility rules. No lazy-rebuild/performance change was made without profiling. No new keys or user-visible behavior are intended.
- Remaining exact-match candidates in these screens were reviewed: GetUiNode/GetLiveData are the explicit context-reader boundary; GetModifierCache owns separate chooser/tree cache lifetimes; OnPanelOpenedCAI closes over distinct builders and pending-open state, with research-only tutorial delay downstream. They remain local deliberately. There is no remaining planned research coordinator extraction.
- The current whole-UI inventory reports 3,258 top-level private definitions and 54 repeated-body groups. It does not inventory nested coordinator functions and is not a completeness metric. The earlier counts reflect different scope/state.
- All 177 research regression assertions pass, including both real screen adapters with production widgets. A one-time original-versus-refactored run passes the same 72 flow assertions and has identical initial/tree/filter snapshots (338 lines). Full repository verification passes. One combined game checklist is tracked in project_status.md; earlier chooser-only pending wording above is superseded by that checklist.

## Trade completion audit (2026-10-04)

- Shared origin controller owns live button matching, list rebuilding, stable focus and lifecycle. Adapters retain city-object versus city-ID capture and native-click versus direct BTS relocation.
- Shared overview controller owns tabs, captured tree rebuilding, choose/produce trader rows, focus and lifecycle. Header schemas/tooltips, native tab callbacks, scenario/BBG selection, running/available route actions and BTS automation remain local.
- Shared trade data owns city/quest queries, destination names, header bonuses and route tooltip composition. Vanilla aggregate and BTS per-yield formats remain distinct; live versus captured yield timing is preserved. Removed the unused vanilla header visibility query.
- Captured dropdown utility lives in UI/shared and is imported in both contexts. Filter deduplication limits and group native IDs remain explicit in adapters.
- Remaining audit candidates: the two BTS BuildRouteTooltip closures bind each screen's captured yield functions and perform city lookup before composing shared text; the two CloseConfirmDialog closures mutate separate context-local dialog references. These are small dependency/state adapters, retained deliberately.
- Verification: 30 helper assertions plus 84 screen assertions across all six variants, using production manager/widgets/dialogs and mocked game APIs. The original adapters pass the same 84 assertions; all 201 speech/tooltip/widget snapshot lines match. Dispatcher tests check BBG/scenario branch selection, not engine mod compatibility. One combined game checklist is in project_status.md.

## Descriptor/column completion audit (2026-10-05)

- CAIDescriptors replaces the two conditional descriptor walkers. It preserves key/keys/bucket precedence, duplicates, traversal order, context reads and exception propagation. Banner kind selection and plot dynamic-group definitions remain local.
- CAIColumns consolidates 13 sort-menu builders and nine column-lookup implementations across 11 screen/helper files; together with plot/banner callers, 13 files were migrated. Twelve sort builders and eight private lookup wrappers were removed; Global Resources retains its column-selection adapter and the unit browser retains its public GetColumn method.
- Caller policies retain separators, direction order, natural-order sentinel values, sort-label preference and filtering of already-grouped columns. The shared helper owns no screen/widget state, cached labels, cell values or sorting operation. Both modules are registered in both UI contexts.
- Cell-column factories remain local where they resolve live unit records, format numeric values, choose game-specific tooltips or build dynamic player columns. Consolidating these would move screen policy into generic helpers; plain column table literals alone do not justify another factory.
- Full verification passed: 118,011 assertions. The descriptor/column suite has 28 assertions, including production banner/plot selectors, live labels, lookup identity, callback failures and production dropdown values. One-time baseline mode passed 343 assertions; all 308 snapshot lines from 15 actual migrated call sites across initial/changed/empty data match the original helpers. The snapshots are committed; the original files stay in ignored local artifacts. Game checks are deferred in docs/refactor-game-tests.md.
- The river suite initially rejected the new registered descriptor include through its old bootstrap allowlist. Its boundary now loads the real descriptor module; the complete river suite passes. No river behavior was changed.

## Dialog/view lifecycle completion audit (2026-10-05)

- Removed eight matching synchronization helpers across City-States, DiplomacyActionView, DiplomacyRibbon, Governors, Great People/Heroes, Global Resources and the unit browser. Nineteen callers now use CAIColumns.SyncSortSelection, which preserves first-match ordering, direction-independent nil natural order, silent selection and unchanged state on a lookup miss. Screen-owned option rebuilding and event callbacks are untouched.
- No generic dialog controller was added. RemoveFromStack already owns destruction and return focus; introducing another owner would duplicate those responsibilities. Simple cleanup closures must still clear their screen-local variables. Frontend pickers, dialog popups and panel teardown differ in whether they retain references, remove child state, or depend on native hide events.
- EventPopup removes the old dialog before native OnClose synchronously opens the next queued popup. Top-dialog identity, root-presence and hidden-context input checks have different meanings. Tutorial Escape gating and fallback handlers remain local.
- View toggles are short forwarding adapters whose setters own different identities: city-state player, governor index or victory competitor team. WorldRankings also rebuilds the active victory entry. These setters remain intact.
- Distinct synchronization stays local: Better Reports unit sync rebuilds options and falls back to the first option; policy/minor sync uses exact direction matching; city-status reports use a string natural sentinel. RET expects its constructed sort control to exist, unlike the pre-build optional-dropdown contract. Do not hide these differences behind generic lifecycle flags.
- Verification: full repository suite passes 118,153 assertions. Test-ViewLifecycle.lua adds 142 checks across actual migrated call expressions and production widgets: silent refresh, missing options, natural order, duplicate first match, sibling focus, user callbacks, nested close, silent return, subtree destruction, repeated close, same-ID reopen and destroyed return targets. Optional baseline mode passed 190 checks against the prior eight helpers. Existing trade/staging/browser suites also pass. No engine test was run; checklist is deferred.

## WorldInput plot-interaction extraction (2026-10-05)

- Moved the approximately 360-line selection-mode plot interaction feature into CAIPlotInteractions, registered for VFS/in-game imports. The factory receives the manager and live context readers rather than caching cursor/interface state. It owns collection, execution, picker construction and the existing suspend-close token.
- WorldInput keeps native/scenario include selection, input dispatch, cursor fallback, active-interface event priority, mode descriptors, World Builder and shutdown. A one-time byte comparison confirms everything outside the extraction and the explicit include/two action calls is identical to the baseline.
- Actions and ordering are preserved: owned units/cities, met major/minor diplomacy, visibility-qualified espionage view, city/district strike, revealed clan and available silo weapons. Silo actions only enter native targeting. No new gameplay commands, keys, validation rules or snapshot timing were introduced.
- Test-PlotInteractions.lua passes 41 checks against the extracted module and the previous WorldInput block with the same production widgets and mocked game APIs. Full verification passes 118,195 assertions. The new checklist is deferred; engine timing, DLC/scenario loading and actual targeting remain game-validation boundaries.

## World Builder input extraction (2026-10-05)

- CAIWorldBuilderInput owns the approximately 540-line editor feature plus brush/sight update hooks: marked source, brush lock, placement/visibility bridge, undo/redo, coordinate entry, tool/editor/quick-navigation bindings and deferred sight recomputation. Live cursor/scanner dependencies are explicit; the module is registered in-game.
- WorldInput retains root stack ownership, native includes/dispatch, event registration, validated cursor/camera handling and update order. The marked-source global and shared CAIInfo reader are rebound each load to the new controller. Status callbacks are added/removed using the same function identity.
- Placement flag pairs, tutorial-independent editor shortcuts, result-aware visibility operations, status bursts and next-tick ownership refresh are unchanged. No new keys or game API calls were added. Existing visibility/scanner modules remain authoritative.
- Production widgets and mocked placement tests pass 74 assertions, including the old implementation comparison, actual WorldInput update/cursor hooks and fresh shared-reader publication. The full suite passed with the initial 65 WB assertions; the strengthened 74-assertion suite then passed independently. Current aggregate coverage is 118,270 assertions. Engine history/brush/visibility timing still needs the deferred checklist.

## Reports ownership review (2026-10-05)

- Extracted the existing shared Resources section into CAIReportResources and Gossip collection/filter/list ownership into CAIReportGossip. Dependencies are live manager/player/resource readers and existing report widget factories; no generic section configuration language was introduced.
- Removed nine declaration-only shared-host leftovers: PANEL_ID, TABS_ID, m_panel, m_tabs, m_trees, m_capturedTabs, m_isMirroringTab, m_activeTab and m_pendingOpenFocusKey. Their live counterparts remain in each variant. Six gossip state locals moved to the gossip owner.
- Retained Yields/City Status and their city-cycling/sort/data relationships in the host. Retained BRS-specific tab logic, its copied vanilla provider and native lifecycle wrappers; these express different data/callback contracts rather than duplicate Resources/Gossip implementations.
- Formalized the five-return CAIReportsDataSource contract in ideHelpers.lua and corrected the shared provider comment. Delayed manager publication is handled by shared RefreshCAIData as well as variant Open. Automated variant/section tests and old-source comparisons pass; engine validation remains deferred.

## World Rankings ownership review (2026-10-05)

- CAIRankingsScore owns Score tree/table builders and contribution formatting usage; CAIRankingsGeneric owns generic/custom victory tree builders. Factories accept the initialized manager and explicit native/data/presentation callbacks. Captured score rows are read per rebuild; no private capture state moves into a presenter.
- Native population wrappers, capture ownership and optional external adapter recovery remain in the host. Scenario/BBG include priority, comparison table configuration, player visibility labels, view switching and tab lifecycle remain shared there. Generic external adapters are the intended protected boundary, unlike bundled scanner callbacks.
- Science/Culture/Domination readers serve both dedicated views and shared comparison/Overall logic; retain those relationships rather than forcing all victories into one row schema. Generic diplomatic tree and dedicated diplomatic comparison table also retain distinct contracts. No new duplicated helper or manager-availability guard was introduced.
- Production host/widget checks pass in base, XP2, BBG and War Machine include configurations; previous-host comparison passes the same 130 checks and all 196 snapshot lines match. Native engine implementations are mocked in that suite; live scenarios/mods remain deferred.
