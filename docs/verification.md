# Repository verification

Run from PowerShell on Windows. No game deployment or global PATH change is required.

## Setup

Install Visual Studio or Visual Studio Build Tools with the Desktop development with C++ workload. Then run:

```powershell
./scripts/Install-TestLua.ps1
```

The script downloads [Lua 5.4.8 from the official source archive](https://www.lua.org/ftp/), checks its published SHA-256, and builds an x64 test interpreter using the installed MSVC toolchain. Source, archive, object files, and executable stay in the ignored `obj/test-lua` directory. It does not modify the game or install a global interpreter. A checksum mismatch stops the build; remove the named archive before retrying a failed download.

## Run checks

```powershell
./scripts/Verify-Repository.ps1
```

The default command requires the local vanilla fixture at `decompiled/Assets/Maps/Utility/RiversLakes.lua`. To run the redistributable subset on a fresh checkout without decompiled game sources:

```powershell
./scripts/Verify-Repository.ps1 -WithoutVanillaRiverFixture
```

This explicitly skips 264 river assertions that compare against vanilla source. The remaining production geometry, reveal restrictions, formatter, scanner, and destination tests still run. CI uses this mode because decompiled Firaxis code is not tracked or redistributed.

Use `-LuaPath C:/path/to/lua.exe` for an existing Lua 5.4 interpreter. `-StaticOnly` runs just the repository checks and explicitly reports that behavior tests were not run. Neither option silently falls back when a requested test fails.

## Coverage

- XML parsing across `src`, modinfo file existence, duplicate VFS entries, action-file registration, and required replacement properties.
- Localization Row/Replace uniqueness, language attributes, English tag counterparts, numbered placeholder identities, and full tag parity for the six complete locale directories. Metadata-only locales are checked for their existing entries, without requiring a complete translation.
- Retired manager calls in registered authored in-game Lua. This is a targeted guard, not a full Lua type checker or dead-code detector.
- Production Minimap and manager: open/toggle/reopen, Escape, disabled activation, vanilla lens callback, placement/World Builder gates, externally removed roots, modal priority, return focus, stable-key rebuild without repeat speech, and shutdown unsubscription.
- Production unit browser, widgets and shared record helpers: live names/health, selected-unit focus, filtering and sorting, table/list switching, close-before-selection, cursor jumps, Civilopedia, stale/removed records, empty rosters, local-player identity on reopening, and ready/all unit cycling with fixed distance anchors, remembered sort, and wrapping. The remaining UnitPanel chunk is syntax-checked with the narrow Firaxis annotation transform.
- Real text composition helpers: nil/empty values, separators, optional values, UTF-8, indentation, CR/LF distinctions, section boundaries and final speech filtering. All in-game callers containing `CAIText` are syntax-checked. A one-time comparison against pre-refactor helper bodies also passed 320 representative cases.
- Existing Real Era Tracker and river suites. The river test enumerates a snapshot of mock plot owners so adjacency lookups cannot mutate the table being traversed and skip records.
- Frontend staging lifecycle: production JoiningRoom and StagingRoom accessibility blocks with real widgets; cloud recovery waits, duplicate/completion/cancellation/failure events, preservation of save mods, recycled native controls, changing slot counts, submenu/chat-dropdown focus, missing colour rows, and construction/refresh failures. The optional first argument to `Test-StagingLifecycle.lua` supplies an older StagingRoom source for regression comparison.

The tests load production Lua against narrow game/control mocks. Minimap and browser tests share `scripts/test-support/WidgetHarness.lua` to load the real manager and widgets while substituting game APIs and unrelated helper services. It explicitly suppresses automatic manager initialization so each test owns lifecycle. The Real Era Tracker suite has a narrow transformation for Firaxis type annotations; this is not a general parser for all annotated game Lua. Passing these checks does not establish engine UI-context load order, scenario coverage, or an in-game playthrough.

## Known packaging exception

`src/CivViAccess.modinfo` still lists `Platforms/Windows/Audio/English(US)/225557858.wem`, which is absent from this checkout. The verifier warns for exactly this path. Other missing registered files fail verification. The existing reference is retained until its intended source or removal is established; verification success does not mean a complete audio package. Once resolved, remove this exception from the verifier and this document.

## Current results (2026-10-04)

- Static checks passed: 57 XML files, 340 VFS files, 93 replacements, 12 locale directories.
- Minimap/manager: 16 assertions; unit browser: 40; staging lifecycle: 74; Real Era Tracker: 161; full river suite: 117,073. Text formatting and caller syntax: 208. Shared utilities and caller checks: 89. Game-state helpers: 31. Research chooser: 51; research trees: 72; research data: 54. Trade data/dropdowns: 30; trade screens: 84. Descriptor/column helpers: 28. Total: 118,011. The complete repository suite passed after the initial staging fixes (then 54 lifecycle assertions). After the engine retest exposed the preparatory-leave regression, the corrected lifecycle suite passed all 55 assertions. The subsequent diagnostics-only addition passes 66 lifecycle assertions, including disabled logging without queries, missing parameter versus missing value, deduplication, preserved constructor returns and original exceptions. The subsequent content-preservation fix passes 74 lifecycle assertions, modeling destructive true-mode behavior and checking GUID-only/case-insensitive membership and copied identities. The user confirmed the repaired cloud-save flow works in game on 2026-10-04; no new log was inspected for exact content counts. Unrelated suites were not repeated.
- The staging lifecycle test fails against the pre-fix source at `CAI_GetRoleStatus` when it accesses a recycled control. The repaired code passes. All three changed frontend/shared replacements preserve their original source byte-for-byte outside the accessibility markers. Cloud-save creation is confirmed working by the user. Remote map-size changes still need engine testing.
- The fixture-free mode omits 264 vanilla-source assertions (116,809 remaining river/location checks). That mode passed before the corrective utility batch; it was not rerun for this batch. GitHub Actions itself has not been run in this session.
- The Minimap regression was also checked against the previous API calls in memory: it fails at the second toggle on undefined `HasWidget`, establishing that the test detects the repaired defect.
- Minimap confirmed working in game by the user. Browser also confirmed working in game by the user. The recommended browser regression checklist was: open Ctrl+U, sort/filter and switch views, select/jump/open Civilopedia, close/reopen, then cycle ready/all units with remembered sort and wrapping. Check a unit removal and local-player switch where available. Historical checks remain closed.

- User reported the formatting batch good; its pending smoke check is closed. The subsequent private dead-code cleanup passed syntax checks for all 12 changed chunks (63 assertions including the shared formatting cases). Removed functions had no references outside their definitions; dependent TopPanel helpers were removed only after their callers disappeared. Full regression suite passed; no game session was run by Codex.

- Control/collection utility checks cover live state, absent methods, untouched text, native getter errors, sparse key counts, caller syntax and explicit includes. The user confirmed the initial module batch passed. The user subsequently reported the utility work good so far; the game-state smoke was confirmed good on 2026-10-03. The user confirmed the completed technology/civics batch works on 2026-10-04.

- Corrective utility audit: 131 additional differential cases against pre-change helpers passed. All 61 inventoried modified Lua chunks compile (146 assertions including shared text cases); the main suite covers discovered CAIText/CAIControl/CAICollection callers. The river suite now includes seven live relative-location checks. docs/utility-audit.md records the audit scope and remaining families.

- Shared modules are verified in both frontend/in-game ImportFiles. Text/caller syntax coverage now includes frontend accessibility blocks, shared modules and affected framework helpers. Shared utility tests run with no Game/Players/Map dependencies. The user reported the shared/frontend batch good so far; automated checks do not substitute for engine coverage.

- Game-state tests cover the different local-player return contracts, city-state meeting, era ages, religious predicates, unmet/multiplayer names, World Builder state and all supported BBG identities. Caller syntax coverage includes CAIGameState and CAIModSupport consumers.

- Research chooser tests cover queue sentinels, current-first ordering, separately captured header deduplication, completed/current turn precedence, boost descriptions and read-only queue factory arguments. Production-widget checks cover silent stable-key restore, removed-row fallback and sibling focus. Both chooser adapters compile. The full repository suite passed after this extraction; in-game verification remains pending.

- Complete research verification: 177 assertions across chooser controls/turn/queue contracts, shared live data/topology, and both production tree screen adapters using real widgets. Coverage includes grid/graph/tree selection, dropdown persistence, native/fallback operations, disabled/reveal/tutorial gates, search/filter navigation, jump/back, queue inspection, filtered close, government slot focus, missing local player and empty catalogs. Both original adapters passed the same 72 flow checks in a one-time differential run; 338 initial/tree/filter snapshot lines match. Automated checks do not establish DLC context load order or game-engine behavior. The user confirmed the combined research test on 2026-10-04.

- Trade consolidation: full repository suite rerun and passed on 2026-10-04 (117,980 assertions). Test-TradeScreens.lua loads all six production vanilla/BTS adapters through their dispatchers and the real manager/widgets/dialog builder. Its 84 checks cover same-name origins, live controls, missing-button fallback, refresh focus, filters, confirmation/cancellation, sorting, repeat/best-route automation, overview tabs, group-ID mapping, trader actions and lifecycle cleanup. Thirty data/dropdown checks cover lookup misses, quest availability, distinct yield formats, religion, tourism/visibility wording and silent synchronization. Engine APIs and BTS sorting are mocked; actual sorting engine behavior and mod load order require the combined game check.
- Optional Test-TradeScreens.lua arguments: adapter source directory, then snapshot output path. One-time comparison against saved pre-refactor adapters passed the same 84 assertions with 201 identical widget snapshot lines. The baseline is an ignored local artifact, not a CI dependency.

- Descriptor/column stage (2026-10-05): full repository verification passed, totaling 118,011 assertions with 340 VFS files. Test-DescriptorColumns.lua exercises production descriptor selectors, key expansion, column lookup, live sort labels, failure propagation and a production Dropdown. It executes sort-menu expressions from all 15 migrated call sites against a committed 308-line pre-refactor fixture. An optional baseline directory argument compares the removed helper bodies and regenerates that fixture; this one-time mode passed 343 assertions. Normal CI uses no local baseline artifacts. The suite does not load every affected full screen or prove game-engine integration; game tests remain deferred.
