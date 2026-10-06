# Project Status: Civ VI Accessibility Integration (CAI)

## Current focus

- UI layering investigation complete (2026-10-06): native ordering combines live context hierarchy, popup queue parameters, explicit modal stack and input contexts; CAI's priority/push-order approximation can diverge, and popup wrappers can fall through to native handlers when another CAI root is top. Findings: `docs/ui-layering-investigation.md` and `docs/game-api.md`. No runtime fix or game reproduction performed. Proposed next stage: native-state/input diagnostics to verify popup/modal identity, flags, top direction and Current/Default semantics, then a context-owned central ordering/input resolver. Await user direction before implementation.
- Pirates loading report diagnosed (2026-10-06): latest 18:31 attempt aborts during gameplay database configuration, before scenario UI initialization. Modding.log records failed database updates/rollback at 306550.553/306550.568; Database.log identifies missing expansion tables and scenario-excluded references in BBG and BBG Expanded 2.1 components. No CAI code change justified by this failure. Next: restart and launch Pirates with CAI and required official content only, then check its contextual scanner category. Mod-support checks pass (267 assertions); successful Pirates loading remains unverified. Frontend CAI nil errors follow the aborted launch and need separate reproduction if they persist after a clean restart.
- Scanner regression repaired (2026-10-06): user reports other tested behavior appears in order, but scanner entries/navigation/category management fail. Live Lua.log identifies stale `MapInfo.IsActive` calls after scenario query consolidation; both Red Death and Pirates adapters now query CAIModSupport. Full verification passes 119,954 assertions (267 mod-support checks). Reload and scanner retest remain pending; unspecified scenario/mod variants are not presumed tested.
- Refactor implementation is complete as of 2026-10-06, including the final CAI namespace and scenario/supported-mod query stages. Final handoff: use `docs/refactor-game-tests.md` for all outstanding game validation; address reported regressions before claiming in-game acceptance.
- Final implementation commit: `253896d` (scenario/mod queries), following `0670a9a` (CAI namespace) and `3c7565e` (final utility audit). No game validation is implied by automated results.
- Final handoff verification passed on 2026-10-06: 119,941 assertions, 57 XML files, 348 VFS files, 93 replacements and 12 locale directories. The known missing audio asset remains a separate packaging-source decision; ProductionManager/multi-queue remains separate feature scope.
- Workflow: finish each authorized stage, verify, update documentation and commit to `beta`; summarize the commit and next step, then wait for user direction. Do not push or include unrelated local settings. Implementation-stage game tests were deferred; the complete checklist is now ready for the user.

## Test status

- On 2026-10-01 the user confirmed: "everything is tested and working, feel free to close every pending". All previously pending in-game tests, retests, regressions, optional fixture checks, and result requests are closed as successful based on that confirmation.
- No historical game test remains pending. Future implementation creates its own focused verification requirements.
- Verification passes: 57 XML files, 348 VFS files, 93 replacements, 12 locale directories; 290 formatting/syntax + 89 shared utility/caller + 31 game-state + 51 research chooser + 72 research tree + 54 research data + 28 descriptor/column + 142 view lifecycle + 41 plot interaction + 74 World Builder input + 824 interface-mode + 85 scanner/focus + 98 report sections + 130 Rankings + 45 production queue + 60 final audit + 94 namespace + 255 scenario/mod queries + 30 trade data/dropdown + 84 trade screen + 16 Minimap/manager + 40 browser + 74 staging lifecycle + 161 RET + 117,073 river assertions (119,941 total). Remaining UnitPanel compiles. Local Lua 5.4.8 lives under ignored `obj/test-lua`. The fixture-free river mode has 116,809 assertions; GitHub Actions itself has not run. Details: `docs/verification.md`.
- Minimap repair confirmed working in game by the user on 2026-10-01; its pending check is closed.
- Browser extraction and formatting consolidation confirmed working by the user on 2026-10-02; their pending game checks are closed.

## Next steps and open findings

- The user confirmed the first control/collection batch passed. The deeper corrective audit removed/promoted 80 more private helpers across 61 inventoried files, replaced 102 inline text filters and one nested forwarding wrapper, and consolidated generic formatting, control readers, sort comparators and location helpers. See `docs/utility-audit.md` for scope, evidence and remaining work.
- User reported the corrective/shared/frontend utility work good so far and authorized continuation; prior utility smoke requests are closed on that basis.
- Shared/frontend batch complete: CAIControl/CAICollection live in UI/shared with both-context registration; caiUtils sentence splitting and collection primitives moved to their owners; frontend duplicates migrated. All 31 marked replacements preserve source outside accessibility blocks.
- Game-state batch implemented: CAIGameState consolidates matching local-player, city-state, era, religion/alliance, name-visibility and World Builder queries; shared CAIModSupport consolidates three BBG detectors. Return contracts remain explicit; no observer fallback added. Automated suite passes; Codex has not run the game.
- Minimap now uses the current root lookup with object identity; obsolete LeaderView was removed after checking registrations, source references, and vanilla include behavior.
- Resolve the pre-existing missing `Platforms/Windows/Audio/English(US)/225557858.wem` manifest entry as a packaging-source decision; passing game tests does not supply the missing file.
- AGENTS now points to the existing `docs/Civ-6-Documentation/Civ6Docs.html` and Lua IDE helpers.
- Historical feature backlog is preserved in the archive; test closure does not imply unimplemented features are complete. ProductionManager/multi-queue remains a separate scope per project instructions.

- Game-state smoke closed as successful on 2026-10-03: user reported all good so far for the listed checks, including BBG where installed.
- Technology/civics refactor complete (2026-10-03): CAIResearchTree owns shared tree/grid/graph, filters/search, queue inspection, detail/reference rows, navigation and lifecycle; CAIResearchData owns shared live readers/topology; CAIResearchChooser owns shared chooser controls/queue/rebuild mechanics. Domain callbacks, technology column calculation, civics government/policies and vanilla hooks remain in screen adapters. All 177 research checks pass; pre-refactor snapshots match across 338 widget snapshot lines.
- Combined technology/civics in-game test confirmed successful by the user on 2026-10-04: "All works well." The research batch is implemented and game-verified; its pending checklist is closed.
- Trade implementation finished: CAITradeOrigin, CAITradeOverview and CAITradeData are registered in-game; generic CAICapturedDropdown is registered in both contexts. Thirty helper checks and 84 screen checks pass; the same 84 screen checks pass against pre-refactor adapters, with all 201 snapshot lines identical. Remaining repeated tooltip/dialog closures are small dependency/state adapters, documented in docs/utility-audit.md.
- Trade game validation is deferred to the end of the full refactor. The complete trade checklist and other outstanding game checks are maintained in docs/refactor-game-tests.md; none is marked passed by deferral.
- Next step: complete the consolidated game validation in docs/refactor-game-tests.md, then address observed regressions. Planned refactor implementation stages are finished; 29 remaining repeated-body candidate groups have explicit retention reasons in docs/utility-audit.md. ProductionManager/multi-queue and the missing audio packaging-source decision remain separate scope. No push requested.

## Durable decisions

- CAI owns all mod cross-context systems and state. caiUtils aliases ExposedMembers.CAI and supplies colon-style system getters; owners publish/clear CAI fields. Do not restore top-level CAI-prefixed ExposedMembers fields. External mod bridges retain their original contracts.

- Keep screen-specific code together unless demonstrated reuse or a concrete maintenance benefit justifies extraction. A separate responsibility or shorter host file alone is insufficient; the ProductionPanel queue extraction was reversed on this basis.

- `docs/ui-manager.md` defines the class-based framework; `src/ideHelpers.lua` defines annotations. Retired template APIs stay retired. Manager owns focus; screens use widget events, stable FocusKey identities, and public capture/restore operations.
- Preserve vanilla callbacks, input contexts, dialogs, DLC/scenario wrappers, live control text, and game state changes. Cross-context/local include behavior and VFS registrations constrain module extraction.
- New imported helpers require collision-safe names and appropriate File/ImportFiles registration; screen replacements also require their existing ReplaceUIScript mappings.
- Frontend/shared screen changes are restricted to accessibility blocks. Standalone shared utility modules may be refactored as explicitly requested. Generic utility modules belong in UI/shared; game-specific utilities retain in-game ownership. Screen ownership is a valid boundary; keep diplomacy behavior together.
- Before 1.0.0, releases increment the minor version and reset patch to zero.
- Specific gameplay, scenario, speech, and integration decisions remain in AGENTS.md and `docs/game-api.md`.

## Compressed history

- The class-based UI migration and subsequent gameplay, scenario, mod integration, scanner, speech, World Builder, and frontend corrections were implemented across the earlier sessions. All historical pending checks are now closed by the user's confirmation.
- Full former status retained in `docs/project-status-archive-2026-10-01.md` with an explicit test-closure notice. Its pending wording is historical, not an active work queue.
- Review added the refactor plan and API findings. Phase 1 repaired Minimap and removed obsolete LeaderView; Phase 2 extracted the browser, reused shared focus-key formatting, and consolidated widget-test setup. Frontend and localization remain unchanged; shared textProcessing is the explicitly authorized formatting exception. Changelog records the player-visible lens fix; browser extraction intentionally preserves behavior. Formatting comparison against pre-refactor helpers passed 320 representative cases. Verification docs explain test scope and the unresolved audio exception.
