# Better Report Screen (BRS) accessibility support — plan

Status: FINALIZED build spec. Shape agreed with the user; all §8 decisions resolved.
Only code written so far is the detection helper `IsBetterReportScreenActive()` in
`src/UI/shared/caiUtils.lua`. Implementation may begin from this document.

## 1. Goal

Make CAI's accessible Report Screen work when the Better Report Screen mod (Infixo,
"Better Report Screen (UI)", mod UUID `6f2888d4-79dc-415f-a8ff-f9d81d7afb53`) is
active, exposing all of BRS's tabs to the screen reader. When BRS is not active, CAI
keeps its current vanilla-based accessible report unchanged.

Scope decisions already made:
- Full BRS-aware layer (all tabs, including the five BRS adds).
- Optional / runtime-detected. BRS is not a hard dependency.
- Accessibility is for the report screen and its contents only. The ReportsList
  popup (the little menu that opens each report) is out of scope.

## 2. Why this is needed (the conflict)

Both mods register `<ReplaceUIScript LuaContext="ReportScreen">`. Only one Lua file can
own a context; the highest `LoadOrder` wins.

- BRS: LoadOrder 1010 (Rise & Fall) / 1020 (Gathering Storm).
- CAI (`src/CivViAccess.modinfo`, id `CAI_ReportScreen`): LoadOrder 999999999.

So CAI always wins the context, and today, with both mods enabled, BRS's
`reportscreen.lua` never runs. CAI's report is built entirely against the *vanilla*
data model (`GetData()`), which BRS removes. Result: BRS is effectively suppressed and
its extra tabs are invisible. We want CAI, when BRS is present, to build accessibility
on top of BRS instead of vanilla.

## 3. Reference pattern: BetterTradeScreen

CAI already solves the identical problem for the trade screens. `TradeOverview_CAI.lua`
is a dispatcher that:

1. Chain-includes the correct base script for the active environment.
2. Detects the third-party mod and, when active, hands off to a dedicated variant file
   and returns before the vanilla-path accessibility code runs:

   ```lua
   if IsBetterTradeScreenActive() and AddRouteInstanceFromRouteInfo ~= nil then
       include("TradeOverview_BetterTradeScreen_CAI")
       return
   end
   ```

The variant `TradeOverview_BetterTradeScreen_CAI.lua` is a self-contained accessibility
layer that `WrapFunc`s the mod's differently-named emit functions
(`AddRouteInstanceFromRouteInfo`, `CreatePlayerHeader`, `AddFilter`, `AddGroupByEntry`,
…), reading the mod's structured data to build accessible trees. The variant files are
registered in the modinfo both as top-level `<File>` and under `<ImportFiles>` because
they are pulled by a runtime `include()`.

We mirror this exactly for reports.

## 4. Proposed architecture

### 4.1 Detection helper (DONE)

Added to `src/UI/shared/caiUtils.lua`, mirroring `IsBetterTradeScreenActive`:

```lua
local BETTER_REPORT_SCREEN_UUID = "6f2888d4-79dc-415f-a8ff-f9d81d7afb53"
function IsBetterReportScreenActive()
    return Modding.IsModActive(BETTER_REPORT_SCREEN_UUID)
end
```

### 4.2 Dispatcher branch in `ReportScreen_CAI.lua`

Near the top, after the base include chain, before the vanilla-path CAI code:

```lua
if IsBetterReportScreenActive() and ViewDealsPage ~= nil then
    include("ReportScreen_BetterReportsScreen_CAI")
    return
end
```

`ViewDealsPage ~= nil` is the equivalent of BTS's `AddRouteInstanceFromRouteInfo ~= nil`
guard: `ViewDealsPage` only exists if BRS's engine actually loaded into this context. If
the guard is false, we fall through to the existing vanilla path (fail-safe, no crash).

### 4.3 New variant file `ReportScreen_BetterReportsScreen_CAI.lua`

Self-contained accessible layer for all nine BRS tabs. Registered in
`src/CivViAccess.modinfo` in both places (top-level `<File>` list and the in-game
`<ImportFiles>` group), same as the three BTS variant files.

### 4.4 The one runtime unknown to verify in-game

The dispatcher's base include (`include("ReportScreen")` / `ReportScreen_Expansion1` /
`ReportScreen_Expansion2`) must resolve so that BRS's `View*Page` functions become
defined in this context. BRS exports its `reportscreen.lua` via `ImportFiles` under a
name that collides case-insensitively with vanilla `ReportScreen.lua`. The BTS
precedent shows `include("<VanillaName>")` picks up the mod's replacement when the mod
is active. We must confirm via `Lua.log` that when BRS is active, the base include pulls
BRS (so `ViewDealsPage` is defined) rather than vanilla. If it reliably pulls vanilla
instead, the fallback is to vendor a verbatim BRS entry copy (the pattern used for BBG:
`TradeOverview_BetterBalancedGame_CAIBase`), at a maintenance cost. Decide after the
in-game check; the `~= nil` guard keeps a wrong resolution safe meanwhile.

## 5. BRS data model (why this is wraps, not a rewrite)

Every BRS page follows the same clean shape:

- `GetDataXxx()` returns a well-structured data table.
- `UpdateXxxData()` caches it in a module global and clears a dirty flag in `g_DirtyFlag`.
- `ViewXxxPage()` renders that global into `Controls.Stack`.

So for each tab the variant does: `WrapFunc(ViewXxxPage, function(orig) orig(); <read
the data global>; <build accessible tree> end)`. Calling `orig()` lets BRS populate its
data global and visuals; we then read the structured global. This is the same mechanism
as the BTS layer.

Tab-by-tab data source inventory:

- Tab 1 Yields — global `m_kCityData` (+ `m_kCityTotalData`, `m_kUnitData`, `m_kDealData`,
  `m_kModifiers`); getter `GetDataYields()`. `m_kCityData` is produced via
  `RMA.GetCityData` and is close to the vanilla `GetData` city shape, so CAI's existing
  yields tree logic is largely reusable. Bottom filter checkboxes (e.g.
  `HideCityBuildingsCheckbox`).
- Tab 2 Resources — global `m_kResourceData`; getter `GetDataResources()`. Per-resource
  entries flagged `IsStrategic` / `IsLuxury` / `IsBonus`, with per-city sources/uses and
  Monopolies/Corporations data. Filters: `StrategicCheckbox`, `LuxuryCheckbox`,
  `BonusCheckbox`.
- Tab 3 City Status — global `m_kCity1Data`; getter `GetDataCityStatus()`. Per-city rows
  with sortable columns. Overlaps CAI's current City Status tab.
- Tab 4 Gossip — no data global; reads
  `Game.GetGossipManager():GetRecentVisibleGossipStrings` live in the view. CAI's
  existing `GatherGossip()` / `FilterCAIGossip()` already read the same source, so this
  tab ports almost verbatim, including the group and leader filters.
- Tab 5 Deals (new) — global `m_kCurrentDeals`; getter `GetDataDeals()`. Grouped per
  met major civ: `{ WithCivilization, GoldBalance, EndTurn, Deals = { { Incoming,
  Outgoing, Enacted, EndTurn } } }`.
- Tab 6 Units (new) — see §6.Units. We do NOT build from BRS's `m_kUnitDataReport`.
  Instead we reuse CAI's existing Ctrl+U unit-list pattern (`CAIUnitList` in
  `UnitPanel_CAI.lua`), which reads live `player:GetUnits()` — the same source BRS's
  `GetDataUnits()` uses. BRS's only extra data of interest is per-unit maintenance
  (`MaintenanceAfterDiscount`) and nearest-city context, which we can compute directly.
- Tab 7 Policy (new) — global `m_kPolicyData`; getter/updater `UpdatePolicyData()`.
  Grouped by slot type (military/economic/diplomatic/wildcard/great-person/dark-age/
  pantheon/follower). Each policy `{ Name, Description, IsActive, IsSlotted, Impact,
  Yields, ImpactToolTip, UnknownEffect, IsImpact }`. Filters:
  `HideInactivePoliciesCheckbox`, `HideNoImpactPoliciesCheckbox`.
- Tab 8 Minor / City-States (new) — see §6.Minor. We do NOT build from BRS's
  `m_kMinorData`. Instead we reuse CAI's existing City-States screen pattern
  (`CityStates_CAI.lua`), which reads live city-state data
  (`PlayerManager.GetAliveMinors()`, influence/suzerain/quests/relationships). BRS's
  `m_kMinorData` category-bonus impact analysis (small/medium/large envoy influence
  levels and how many city-states sit at each) is the one piece the diplomacy screen
  does not already show; we may optionally surface it as a summary. BRS filters
  (`HideNotMetMinorsCheckbox`, `HideNoImpactMinorsCheckbox`) map to a met/all filter.
- Tab 9 Cities2 (new, Gathering Storm only) — global `m_kCity2Data`; getter
  `GetDataCities2()`. Per-city power / resource-consumption / CO2 rows, sortable.
  Only present when `bIsGatheringStorm`.

Shared engine functions BRS exposes that we can lean on: `GetGreatWorksForCity()` and
`GetCityData()` (in `RealModifierAnalysis.lua`), `RMA.YieldTableGetInfo`, `spairs`,
`toPlusMinusNoneString`.

## 6. Presentation plan per tab

General model, reusing the widget infrastructure already in `ReportScreen_CAI.lua`: a
`Panel` holding a `TabControl`; each tab is a `Tree` (hierarchical breakdowns) or `List`
(flat rows); rows carry `FocusKey`s and are rebuilt with
`mgr:CaptureFocusKey`/`mgr:RestoreFocus`; TTS via `Speak`/widget text; filters exposed
as CAI `List`/dropdown widgets or toggle rows that drive the same BRS `Controls.*`
checkboxes and re-run the view.

- Yields — Tree. City income group with per-city / per-district / per-building / wonder /
  route / worked-tiles / amenity / pop-culture breakdown, plus empire economy. Reuse the
  existing yields tree code adapted to `m_kCityData`. Jump-to-plot on cities/districts/
  buildings via the existing `ActivatePlot`/`ActivateCity`.
- Resources — Tree grouped by resource, children per city. Honor the strategic/luxury/
  bonus filter checkboxes.
- City Status — reuse CAI's existing City Status tab (table/list view, sorting, city
  cycling) sourced from `m_kCity1Data`.
- Gossip — List, reusing CAI's existing gossip gather/filter/list, with leader and group
  filter widgets.
- Deals — Tree: one node per civ (label = civ name, deal count, gold balance, turns to
  completion), children = each deal's incoming/outgoing/turns. Read-only.
- Units — a single unit view of the local player's units (live `player:GetUnits()`),
  reusing CAI's Ctrl+U unit-list machinery (`CAIUnitList` record/resolve/sort/activate),
  with a dual **table / list** view (persisted view-mode + switch button). NOT BRS's
  separate per-class tables — one table whose columns adapt to the active filter.
  - Filter `Dropdown` by class, using BRS's class groups: All, Military (land/naval/air/
    support), Civilian, Religious, Great People, Spy, Trader.
  - Table view: one `DataTable`, one row per unit, columns driven by the filter:
    - Common columns (always shown): Type (cell icon/name, tooltip = unit name +
      description + promotions + abilities/effects), Name, Status/activity, Moves
      (current/max), Nearest City (name when close), Maintenance (gold after discount; GS
      resource-maintenance indicator).
    - Class-specific columns, shown when that class is filtered: Military → Level,
      Experience, Health, and the strength columns (melee/ranged/bombard/anti-air);
      Civilian → Build Charges, Albums (GS rock bands); Religious → Spread Charges,
      Religious Strength; Great People → Level, Great-Person Class; Spy → Operation,
      Turns; Trader → Route, route Yields.
    - The **All** filter shows every unit with the full superset of columns (class-
      specific columns present, empty cells where they do not apply to a unit's class).
    - Every column is sortable via the DataTable's column sort (`sortKey` +
      ascending/descending descriptions), as in `CAIUnitList.BuildColumns()`.
  - List view: a flat `List` with a filter `Dropdown` and a sort `Dropdown` (same filter
    and sort options as the table). Each item is one unit; the item label is a concise
    summary (name + key state) and the item's **tooltip carries the full per-unit
    details** (the same fields the table spreads across columns). Behaves like the table
    but flattened for linear reading.
  - Row/item activation selects the unit and jumps to its plot (optionally opens
    Civilopedia), reusing `CAIUnitList`'s activate machinery. Report-context caveat: the
    report may be open away from the map, so activation closes the report first (as the
    yields/city jumps already do) before selecting/looking at the unit.
  - Reuse note: this is essentially the Ctrl+U list hosted inside the report's
    TabControl. The unit record build/resolve and select+jump activation are shared via
    `inGameHelpers_CAI.lua` (§8 #6); the column set, class filter, and BRS-only columns
    (maintenance, nearest city, class-specific fields) are written fresh here.
- Policy — Tree grouped by slot; leaf per policy with active/slotted status, name,
  description (tooltip), impact and yields. Expose the two filter toggles.
- Minor — a dual **tree / table** view (persisted view-mode + switch button, the broad
  shape borrowed from `CityStates_CAI.lua` but NOT a one-to-one copy). It is read-only
  and impact/yields-focused, matching what BRS's Minor tab actually shows. No diplomacy
  actions (envoy sending, levy, war-peace) are duplicated here; an optional Look At / jump
  to the city-state's capital is the only action worth considering.

  BRS's category header has no tooltip, so we reuse that slot: the three envoy-tier
  bonuses live in the category node's tooltip in tree view, and the tree children are the
  city-states only.

  - Tree view: one node per city-state category (Cultural, Militaristic, …).
    - Category node tooltip carries the three envoy-tier bonuses (Small = 1 envoy,
      Medium = 3, Large = 6): each tier's bonus description, plus that tier's yields
      multiplied by how many of your city-states reach the tier, plus that count. (Counts
      are cumulative/overlapping — a city-state at 6 envoys satisfies all three tiers —
      which is why tiers are reference text on the category, not parents of the
      city-states.)
    - Category children: one row per city-state, carrying envoy/suzerain status, your
      envoy count, the suzerain-bonus description (tooltip), and the per-yield impact.
    - A tree **sort Dropdown** with the same sort options as the table columns below.
  - Table view: a `DataTable`, one row per city-state, all columns sortable (BRS's Minor
    tab has no sorting, so this is a net gain):
    - Name — sort A–Z.
    - Category — Cultural / Militaristic / etc.; recovers the grouping the flat table
      drops. Sort A–Z. Each Category cell's tooltip carries that category's three
      envoy-tier bonuses (same content as the tree category node's tooltip), so the tier
      bonuses are available in table view too.
    - Status — suzerain / has-envoys / met-only; short cell, fuller state in tooltip.
      Sort suzerain-first.
    - Envoys — your envoy count. Numeric sort.
    - Suzerain — current suzerain (you / other leader / none). Sort A–Z.
    - One column per yield (Food, Production, Gold, Science, Culture, Faith, … plus the
      R&F/GS extras BRS shows). Each cell shows this city-state's value for that yield;
      each cell's tooltip carries that yield's breakdown. Each yield column sorts
      independently. Do NOT collapse yields into a single summary column.
    - The tier bonuses appear in table view via the Category column cell tooltips (above),
      mirroring the tree category node tooltip.
  - Two checkboxes after the tree/table, applying to both views: Hide not-met (maps BRS's
    `HideNotMetMinorsCheckbox`, default on) and Hide no-impact (maps
    `HideNoImpactMinorsCheckbox`, default off).
  - Data comes from live city-state data plus RMA impact/yields (the same sources BRS's
    `UpdateMinorData` uses). The city-state data readers (`GetCityStateData` /
    `GetAllCityStatesData`) are shared via `inGameHelpers_CAI.lua` (§8 #6); the columns,
    rows, and tier-bonus/yields content are written fresh here.
- Cities2 (Gathering Storm only, gated behind `bIsGatheringStorm`) — read-only, sourced
  from BRS's `m_kCity2Data`. A `DataTable` (or flat `List`), one row per city, with a
  concise summary of the Gathering Storm city figures BRS shows: power produced vs.
  consumed / deficit, resource stockpile/consumption, and CO2 contribution. Columns are
  sortable; the fuller per-figure breakdown lives in per-cell (table) or per-item (list)
  tooltips rather than as extra columns. No new columns beyond what BRS surfaces.

Read-only vs. actionable: all nine tabs are informational. The only interactive
elements are jump-to-plot (yields, units, city status) and the filter toggles
(resources, policy, minor, gossip). No new game actions are introduced. This matches the
"expose only what vanilla/BRS shows" rule.

## 7. Localization

New CAI tab and label tags (only where BRS/vanilla has no reusable key) go in
`src/Text/en_US/cai_text_ui.xml` as `LOC_CAI_...`, and must be added to every shipped
language folder under `src/Text/` (using `<Replace>` in non-en_US files). BRS ships its
own localized tab names (`LOC_HUD_REPORTS_TAB_DEALS/UNITS/POLICIES/MINORS/CITIES2`) which
we can reuse for tab labels. Prefer existing control text and BRS/vanilla LOC tags before
minting new ones.

## 8. Resolved decisions

1. Yields and City Status builders: write fresh BRS-specific builders that read BRS's
   data globals (`m_kCityData`, `m_kCity1Data`), rather than force-reusing the vanilla-
   shaped builders. Where a BRS field is byte-for-byte the same as vanilla's (BRS's
   `m_kCityData` comes from `RMA.GetCityData`, close to vanilla), the existing yields-tree
   logic may be lifted as-is; confirm field parity at build time and do not couple to it
   otherwise.
2. Filters: expose each tab's BRS filters as CAI toggle widgets placed after the tab's
   content (tree/table), driving the same underlying BRS `Controls.*` checkboxes and
   re-running the view. Default states match BRS: Minor Hide-not-met on / Hide-no-impact
   off; Policy Hide-inactive on / Hide-no-impact off; Resources Strategic/Luxury/Bonus all
   on; Gossip group and leader filters default to All.
3. City cycling: yes. The BRS City Status tab feeds the existing world city-cycling
   feature (`OnCAICycleSelectedCity`) the same way the vanilla path does, sourced from the
   BRS city data.
4. Cities2: a concise per-city summary (power / resource consumption / CO2) in the
   table/list, with the fuller breakdown in per-cell / per-item tooltips. Gated behind
   `bIsGatheringStorm`. Read-only. See §6.
5. File layout: split. A main dispatcher-variant (`ReportScreen_BetterReportsScreen_CAI.lua`)
   plus one included file per tab (or per logical group), mirroring BRS's own
   page-per-file layout, since the combined code is large. All run in the ReportScreen
   context. Every split file is registered in the modinfo `<File>` list and, because it is
   pulled by a runtime `include()`, under `<ImportFiles>`.
6. Shared game-state readers: extract only the game-state-reading helpers into
   `src/UI/inGame/inGameHelpers_CAI.lua` (already a shared cross-context module included by
   ReportScreen_CAI) and include it in `UnitPanel_CAI.lua`, `CityStates_CAI.lua`, and the
   report variant. Extract: the unit record build/resolve and select+jump activation from
   `CAIUnitList`; and `GetCityStateData` / `GetAllCityStatesData` from `CityStates_CAI.lua`.
   Do NOT share column/row/filter definitions — those are written fresh per tab because the
   report content differs from the shipped screens. Moving these functions is a behavior-
   preserving refactor; the two shipped screens must be re-verified in-game afterward
   (they affect all users, not just BRS users).
7. Data source: Units and Minor read live game state (`player:GetUnits()`, live city-state
   data) — the same sources BRS uses — not BRS's cached `m_kUnitDataReport` / `m_kMinorData`
   tables.

## 9. Testing checklist (user, in-game)

- After the §8 #6 refactor, the shipped screens are unchanged in behavior: the Ctrl+U
  unit list and the City-States screen still open, read, sort, filter, and act correctly
  (this is verified before any report tab is built on the shared readers).
- With BRS active: `Lua.log` shows the BRS engine loaded and the CAI BRS variant taking
  over (confirm the base include resolved to BRS and `ViewDealsPage` was defined).
- Each tab opens, reads correctly, and navigates with the screen reader.
- Filters and sorting announce and apply.
- Jump-to-plot works from yields, units, and city status.
- City cycling still works and follows the BRS City Status sort.
- With BRS disabled: CAI's vanilla report is unchanged.
- Escape/close and reopen preserve the last tab; no double-speak or focus loss.

## 10. Phasing

Because the dispatcher's early `return` means only implemented tabs are accessible once
the branch is on, the branch is flipped on only after all nine tabs are built (decision:
full variant in one pass).

Step 0 — Shared readers (§8 #6): extract the unit record build/resolve/activate and the
city-state data readers into `inGameHelpers_CAI.lua`; repoint `UnitPanel_CAI.lua` and
`CityStates_CAI.lua` at them; re-verify both shipped screens in-game. This lands before
any report tab work so a regression there is caught in isolation.

Then build the tabs (dispatcher branch still off), suggested order: Deals (smallest,
proves the wrap+tree pattern) → Units → Policy → Minor → Cities2 → Resources → Gossip →
City Status → Yields (largest, most reuse). Finally flip the dispatcher branch on and run
the §9 checklist.
