Updated scope: generic utilities in frontend/shared code are included. Frontend/shared replacement edits must stay inside accessibility blocks. Standalone utility modules are explicitly in scope; non-game-specific helpers belong in UI/shared. This supersedes earlier exemption wording below.

# In-game refactor evaluation and plan

Date: 2026-10-01. Reviewed branch: `beta`.

Implementation progress (2026-10-01): the first Phase 1 slice is implemented. Added the pinned Windows test runtime bootstrap, repository verifier and CI workflow, repaired Minimap stack membership calls with production regression coverage, removed unregistered obsolete LeaderView, and corrected the project documentation reference. The river mock's table-mutation defect is fixed; CI explicitly omits only checks requiring untracked vanilla source. See `docs/verification.md` for results and the narrowly documented missing-audio exception. Broader dead-code/utility work and later phases remain; this is not completion of the full refactor.

Implementation progress (2026-10-02): Minimap is confirmed in game. The Phase 2 browser pilot is extracted to `CAIUnitBrowser.lua`, including shared cycling sort/anchor state. UnitPanel retains event wiring and supplies context-specific data readers. Removed the duplicate focus-key helper and consolidated Minimap/browser test setup in `scripts/test-support/WidgetHarness.lua`. Forty browser assertions pass with production widgets and record helpers, and the remaining UnitPanel chunk compiles. Browser game regression is pending; formatting/utility consolidation and remaining phases are next.

## Scope and baseline

This is a static architecture review and implementation plan, not an exhaustive correctness audit. The inventory contains 161 Lua files under `src/UI/inGame` and 40 under `src/UI/uiManager`. Review covered representative large screens, the scanner, manager contracts, lifecycle wiring, mod registration, and existing test/release infrastructure. The native integration, installer, and every scenario/vendor implementation have not received a detailed audit.

Frontend and shared UI files are exempt from refactoring. This includes `src/UI/frontEnd`, `src/UI/shared`, and frontend-only integrations such as FiraxisLive. Change them only when a deliberate API change requires a caller migration. The user explicitly adds `src/UI/shared/textProcessing.lua` as an exception: centralize reusable text-formatting functions there and migrate their in-scope callers. The reusable widget framework in `src/UI/uiManager` is treated as infrastructure in scope, but its existing public behavior should remain stable. No wholesale rewrite of shared utilities such as `caiUtils` is proposed.

The user confirmed on 2026-10-01 that everything is tested and working and authorized closing every pending test. All previous pending game checks are closed on that basis. New static findings below are separate from those historical checks. No runtime code changed during this review.

## Assessment

The architecture has useful foundations: class-based widgets, central focus ownership and restoration, live label getters, vanilla callback composition, domain helpers for targeting and city management, and scanner category modules. Preserve these. The strongest opportunity is to make dependencies and feature ownership explicit within the in-game layer.

Some large files combine independently changing responsibilities, but size and multiple subviews alone do not justify extraction. Screen-specific behavior belongs with its owning screen; DiplomacyActionView's leader views, gossip, grievances, and conversation flow stay together. Extract code when there is demonstrated reuse or an independently owned feature boundary. Keep context-specific vanilla hooks beside their includes: Civ VI's context and local-function behavior makes a universal hook loader risky.

### Findings, ordered by priority

1. **Active API mismatch: Minimap lens list.** `src/UI/inGame/MinimapPanel_CAI.lua:215` and `:295` call `mgr:HasWidget`, absent from the current manager and annotations. The branch is conditional on an existing list, so this is not proof that the first opening fails. Replace the calls with the current stack membership lookup, preserving identity semantics where needed. Validate opening, toggling while open, Escape, and reopening. Do not add a compatibility method for a retired API.

2. **Validation is not a repeatable repository gate.** `scripts/Test-RealEraTracker.lua` and `scripts/Test-RiverDownstream.lua` exercise production logic, but `.github/workflows/release.yml` is the sole workflow and does not invoke them. Its repository validation checks required paths rather than Lua contracts and all VFS registrations. `src/CivViAccess.modinfo:13` references `Platforms/Windows/Audio/English(US)/225557858.wem`, absent in this checkout. This is a packaging question, not proof of a gameplay fault. Resolve the asset's intended source before enforcing a clean manifest check. No Lua interpreter or LuaLS executable was found on PATH during review.

3. **General in-game helpers have too many responsibilities.** `inGameHelpers_CAI.lua` owns cursor API overrides (line 29), string utilities (49), production detail builders (222), unlock widgets (938), map-tack integration (981 onward), unit records and selection (1481 onward), city-state data (1644 onward), and terrain descriptions (1796 onward). This mixes pure formatting, game queries, widgets, and side effects in a widely included file.

4. **UnitPanel and WorldInput are feature hosts as well as vanilla adapters.** `UnitPanel_CAI.lua:2970` onward contains the unit browser's records, columns, sorting, views, and filters; destination selection starts around 2838 and combat inspection around 4011. WorldInput owns plot interactions (319), mode descriptors (1112), dispatch (1425), World Builder commands/editor UI (1477 onward), and runtime lifecycle (2153 onward). These are natural extraction boundaries. Recommendation shutdown is present at line 2289; the issue is split lifecycle ownership, not a confirmed leak.

5. **Technology and civics repeat substantial view coordination.** Compare `TechTree_CAI.lua:812,1064,1072` with `CivicsTree_CAI.lua:774,1026,1034`: era trees, grids, graphs, view selection, filters, queue presentation, and focus restoration have parallel structures. Domain differences matter: technology columns are computed from prerequisites; civics uses Column data and adds government content. Share view mechanics while retaining separate data and activation adapters.

6. **Some screen code reaches into focus internals.** `WorldScannerCategoryManager.lua:581` writes `_lastFocusedKey` and `_lastFocusedChild`, and its Open function reads them. This return path differs from ordinary active-subtree rebuild capture. Establish whether existing public focus methods can express it; otherwise add a small opaque return-focus contract. Do not simply substitute `CaptureFocusKey`, which can legitimately return nil here.

7. **Scanner failure policy is broader than project policy.** `WorldScannerCore.lua:51` wraps bundled category callbacks with `pcall`; `BuildCategory` and `BuildAllCategories` can omit failed categories. This logs errors, so it is not literally silent, but internal programming errors become missing results. Restrict recovery to documented external boundaries. The World Rankings external adapter at `WorldRankings_CAI.lua:281` is an example where protected invocation is justified.

8. **There is obsolete code and documentation drift.** `LeaderView_CAI.lua:51` uses the retired widget API and line 3 contains literal speech. No source registration/reference was found, so assess it as a removal candidate rather than an active screen migration. `docs/Civ6Docs.md`, named by project instructions, is absent; the checkout instead contains `docs/Civ-6-Documentation/Civ6Docs.html`. The former project status mixed current work with extensive historical pending lists; this review archives that history and closes those lists per the user's confirmation.

### Lower-priority opportunities

- Reports already has a useful `CAIReports_DataSource` seam (`ReportScreen_CAI.lua:143`) and separate vanilla/BRS variants. Formalize the returned data shape and separate report sections before considering a larger adapter framework. Preserve BRS-specific getters and its necessary copied vanilla data routine.
- DiplomacyActionView retains its screen-specific behavior and subviews. Its repeated generic text operations are candidates for `textProcessing.lua`, and genuinely repeated non-text functions may move to the appropriate utility helper. No diplomacy screen decomposition is planned.
- WorldRankings can separate individual victory presenters behind its existing adapter boundary. Do not force score, cultural victory, and scenario objectives into an overgeneralized row schema.
- Both research screens eagerly rebuild three views. Measure rebuild time and allocation before changing this. If worthwhile, use per-view dirty state and rebuild on activation, retaining stable entity keys and up-to-date labels. No performance claim is established by source inspection alone.

## Target organization

Keep each `{OriginalName}_CAI.lua` as the integration entry point: select the vanilla/DLC implementation, capture direct functions, attach wrappers, and compose feature modules. Each extracted feature should separate these concerns where it materially helps:

- Data queries resolve current game state from IDs and return documented records.
- Reusable text-formatting operations live in `textProcessing.lua`. Screen-specific selection of information, game queries, and localization meaning stay with their screen/domain; they compose content through those common operations.
- Views create widgets and attach events through the current manager API.
- Controllers own actions and lifecycle and call the existing vanilla callbacks.

Use namespaced module tables and pass context-local dependencies explicitly. Introduce no second global service locator. Keep cross-context `ExposedMembers` APIs small, documented, and based on stable identities where possible. Do not cache displayed values as a substitute for live reads.

Suggested modules are examples, not a requirement to create every file:

- `CAIUnitBrowser`, `CAIUnitDestinations`, `CAIUnitCombatPreview`.
- `CAIPlotInteractions`, `CAIWorldBuilderInput`, `CAIWorldInputModes`.
- `CAIUnlockDetails`, `CAIMapTacInfo`, `CAIUnitRecords`, `CAICityStateInfo`, `CAITerrainDescription`, `CAICursorUIOverrides`.
- `CAIResearchTree` and `CAIResearchData`, with separate technology and civics adapters (implemented).

New include files need collision-safe basenames and the appropriate VFS/import registrations. Extracted helpers are imports, not additional ReplaceUIScript contexts. Keep existing screen replacement mappings unchanged unless the actual context contract changes.

## Implementation sequence

### Phase 1: Establish an executable baseline and resolve stale contracts

Deliver a Windows verification command and CI job with a documented Lua toolchain. Run existing production tests; validate locale XML/tag/placeholder consistency, modinfo paths and registrations, and retired API usage in reachable authored code. Account for Firaxis Lua type annotations through a documented parser or narrow test loader, rather than claiming stock Lua parses every game file unchanged. Vendor code needs its own scope and provenance checks.

Resolve the Minimap API calls, decide the unregistered LeaderView file's disposition, and resolve the missing audio asset reference. Make the documentation reference accurate. Add behavioral coverage for the Minimap lifecycle and manager focus/stack contracts before changing those areas.

Audit dead code throughout the in-scope authored code: unused functions, unreachable branches, abandoned experiments, stale wrappers and obsolete files. Establish reachability through modinfo, includes (including wildcard resolution), XML callbacks, event registrations, exported tables, and DLC/mod/scenario loading before deletion. A zero-match name search alone is insufficient. Remove confirmed dead code and its now-unused registrations/references in the same commit; retain an explicit reason for uncertain candidates. Repeat this cleanup after each extraction so old implementations do not accumulate.

Exit: one reproducible command reports a meaningful result; manifest exceptions are explicitly resolved or documented; active retired-API calls are addressed. Baseline tests pass. This phase can be split into tooling, Minimap, and packaging/documentation commits.

### Phase 2: Extract the unit browser as the pilot

Move the `CAIUnitList` feature into a module instantiated with its manager, live unit queries, and action callbacks. Keep UnitPanel's vanilla include/wrappers in place. Move the relevant unit-record helpers only as needed, updating all their callers in the same change. Preserve current table/list preference, sorting, filtering, keys, and announcements.

Exit: UnitPanel delegates browser behavior through one explicit object; tests cover removed units, selection changes, sorting/filtering, table/list switching and focus retention. Game check covers selection, jumping, Civilopedia, open/close, and local-player changes. Use this extraction to refine the module pattern before applying it broadly.

### Phase 3: Centralize formatting, consolidate utilities, and split WorldInput features

Progress (2026-10-02): the first formatting batch uses `CAIText` directly and deletes generic local copies, including tooltip variants, banner trimming and label joining. Automated verification passes; the user confirmed the formatting batch good. A subsequent dead-code pass removed 34 unreferenced private functions across 12 in-game files. The next utility slice consolidated 24 control-access/map-count definitions across 14 callers into dependency-free CAIControl/CAICollection modules; automated checks pass and the user confirmed its game check. The user identified that this inventory was too narrow. A corrective pass removed/promoted 80 additional private helpers, consolidated inline text filters and generic readers/formatters/comparators, and inventoried remaining domain families. See `docs/utility-audit.md`; the larger utility/refactor work remains explicitly open. Only genuinely case-specific functions stay local; do not retain forwarding wrappers for generic operations.

Make `textProcessing.lua` the single owner of reusable text formatting. Inventory trimming, line splitting/joining, empty-part filtering, whitespace normalization, and generic text conversion across in-scope screens and helpers. Existing examples include `inGameHelpers_CAI.NormalizeFormattedText` / `SplitFormattedLines`, ClimateScreen's `NormalizeText` / `JoinNonEmpty`, and DiplomacyActionView's `NormalizeText` / `SplitLines` / `JoinNonEmpty`. Compare semantics before merging: the line splitters differ in trimming and CR/LF handling. Define explicit behavior for nil/empty input, separators, line endings, and whitespace rather than silently changing existing announcements.

Preserve `ProcessText(text, tidy)` as the final speech-filtering entry point and keep speech routed through `Speak`. Do not apply token filtering twice. Preserve ASCII-safe whitespace handling, UTF-8 text, Civ VI tokens, localized numbers, and layout-preserving `tidy=false` behavior. Add focused input/output tests for the consolidated operations and migrate callers before deleting their local copies. The explicit permission to modify textProcessing does not authorize unrelated frontend/shared cleanup.

Consolidate repeated non-text functions into existing utility helpers when their behavior and dependencies match. Group new helpers by a specific responsibility, document their input/output contracts, and keep game-state access separate from generic operations. Avoid replacing duplicates with a catch-all utility file or configurable helpers whose flags encode unrelated screen behavior. Single-screen logic remains local, including diplomacy logic.

Extract cohesive helper groups one at a time, then separate plot interactions and World Builder input from WorldInput. Extract mode descriptors last because targeting, scanner legality, cursor validity and vanilla confirmation callbacks must agree. Preserve the existing target resolver as the authority.

Keep a single explicit lifecycle owner for each module. Centralize its Initialize/Shutdown pairing without inventing a generic event framework unless repeated use justifies one. Preserve include order and direct vanilla function captures.

Exit: migrated text operations have one implementation in textProcessing; repeated utility behavior has one appropriate owner; obsolete copies are removed; no feature reaches into another feature's private state. Formatting tests preserve existing output, including accented/non-Latin text and intentional line breaks. Verify valid/invalid targeting, movement modes, district purchases, war/WMD confirmations, tutorial restrictions, scenario commands, World Builder entry/exit, and shutdown/reload for the changed slices. Land formatting, utility consolidation, and WorldInput extractions as separate reviewable changes.

### Phase 4: Consolidate research view mechanics

Implementation complete (2026-10-03): CAIResearchTree/CAIResearchData plus the shared chooser helper cover the common mechanics. The 177 research checks and full repository verification pass; one-time pre-refactor comparisons match. User explicitly requested one combined in-game check after the complete family, now pending in project_status.md. Separate domain behavior and eager rebuild policy are retained.

Extract the smallest common view coordinator supported by both research screens. Supply domain callbacks for identity, prerequisites, era placement, labels, visibility, queue state, and activation. Retain civic government UI separately. Avoid a configuration language with a large set of exceptional flags.

Exit: fixes to common tree/grid/graph coordination live once; technology and civics behavior remains distinct where the game differs. Verify era/tier ordering, hidden nodes, prerequisites, jump/back behavior, queue inspection, view switching, focus, and speech. ResearchChooser retains its existing read-only queue/current-research contract.

### Phase 5: Tighten scanner and framework contracts

Remove private focus-field access through an appropriate public return-focus operation, with coverage for destroyed/rebuilt return targets and inactive parents. Audit every caller of the changed contract. Adjust scanner error handling so bundled programming errors remain visible and optional external integration failures recover at their actual boundary.

Preserve the scanner's shared plot traversal, category indexing, reveal rules, sorting, pruning, and slot behavior. Its model selection cursor is not automatically the same thing as widget focus; retain its domain-specific capture/restore logic where appropriate.

Exit: scanner UI does not modify manager internals; category failures follow a documented policy; ordinary categories, external integrations, settings return, search, quick slots, and local-player changes pass focused checks. API edits must also update `docs/ui-manager.md` and `src/ideHelpers.lua`.

### Phase 6: Apply the proven pattern to remaining large screens

Review Reports and WorldRankings one at a time, extracting reusable or independently owned code behind existing seams only where justified. Review ProductionPanel and other large screens afterward based on coupling and change frequency, not file size alone. Keep DiplomacyActionView's screen-specific code together. Introduce common helpers only after real callers demonstrate matching semantics, and finish with a dead-code and remaining-duplication audit across the in-scope code.

Exit: every extraction preserves its screen's live controls, vanilla actions, focus, speech, and DLC/mod variants. Stop when remaining duplication expresses genuine game differences or an abstraction costs more than it removes.

## API migration and acceptance rules

- Keep manager public methods, widget event names, focus semantics, settings keys, localization tags, and hotkeys stable by default.
- Before changing an API, enumerate callers across the whole repository, including exempt files. Specify old/new signatures and behavior. Migrate required frontend/shared callers in the same change; make no unrelated edits there.
- Preserve stack priority, modal ownership, Enter key ownership, disabled activation, hidden navigation, and one-line widget speech. Exercise these contracts rather than only asserting source text.
- Every meaningful extraction runs affected automated tests plus registration/localization checks. Game tests are scoped to the modified feature and actual compatibility variants. A mock cannot prove engine load order or UI context behavior.
- Source moves should be behavior-preserving commits. Land intentional behavior fixes separately and document player-visible changes in `changelog.md`.
- Keep each stage independently reviewable and reversible. Roll back a failed slice without coupling it to unrelated screens.

## Recommendation

Start with Phase 1, then the unit-browser pilot. Keep the existing widget architecture and scanner decomposition. The expected payoff is narrower change scope, clearer dependencies, and reliable regression checks; runtime speed improvements require measurement and are a separate decision.

Review verification: source inspection and repository searches only; no game session or Lua suite was executed during this review. Historical in-game acceptance is the user's confirmation. The resulting documentation changes are checked with `git diff --check`.

## Feature extraction progress (2026-10-05)

- WorldInput selection-mode plot interactions now live in CAIPlotInteractions with explicit live context readers. Native input dispatch, target resolution and scenario selection remain in WorldInput. Automated baseline comparisons pass; game checks are deferred per the current user workflow.
- World Builder commands/editor UI and marked-tile state now live in CAIWorldBuilderInput. Context event registration, camera work and update order remain in WorldInput; next-tick sight and placement-source contracts are preserved and tested. Next boundary: interface-mode descriptors/construction with explicit native callback dependencies.
- Interface-mode descriptors and construction now live in CAIWorldInputModes (2026-10-05), with explicit native/scenario context dependencies. WorldInput retains dispatch and lifecycle ordering. All 824 mode checks pass against extracted and previous implementations; full verification passes. Next stage: scanner/focus contract audit from Phase 5.
- Phase 5 implemented (2026-10-05): public return-focus tokens replace scanner private focus-cache access; Settings uses the same contract. Bundled scanner callback failures propagate and optional DMT lookup recovers at its external boundary. Eighty-five new checks and full verification pass; 45 scanner preservation checks also pass against the previous core. Next stage: review Reports for justified extraction, then WorldRankings separately.
- Reports review implemented (2026-10-05): CAIReportResources and CAIReportGossip own cohesive shared sections; the five-return data-source contract is annotated. Nine dead host declarations were removed and shared manager refresh now handles delayed publication. Yields/City Status coupling and BRS-specific data/lifecycle remain local. Full verification passes; 98 report checks and 84 snapshot lines match the previous host under normal initialization. Next stage: WorldRankings ownership review.
- World Rankings review implemented (2026-10-05): Score tree/table and generic/custom tree presenters extracted with explicit dependencies. Host-owned native capture, optional external adapters, scenario includes and view lifecycle remain intact. Full verification passes; 130 checks and 196 snapshot lines match the previous implementation. Next stage: review ProductionPanel for justified ownership/duplication cleanup, followed by the final audit. User correction: remove the unnecessary Reports manager-initialization guards/artificial test and related claims during that later cleanup; WorldInput initializes the manager first.

- ProductionPanel review implemented (2026-10-05): queue presentation/operations/focus remain in ProductionPanel; the unnecessary extraction was reversed at the user's direction. Duplicated queue bindings are consolidated locally. Production/purchase callbacks, native capture, tutorial and placement lifecycle remain in the host. All 45 production-widget checks pass against both implementations; full verification passes (119,455 assertions). Next stage: final duplication/dead-code audit, including removal of the unnecessary Reports manager-initialization protections, artificial delayed-manager test and associated claims. Game tests remain deferred.
