# Tutorial Scenario Compatibility Audit

## Scope

This audit traces the base on-rails tutorial from:

- `decompiled/Assets/UI/TutorialUIRoot.lua`
- `decompiled/Assets/Scenarios/Tutorial/TutorialScenarioBase.lua`
- the native UI contexts and XML tutorial triggers used by that scenario
- CAI replacements, wildcard additions, input handlers, and UI-manager widgets for those contexts

The result is a static compatibility assessment. It identifies paths that preserve
the native tutorial contract, paths that are likely to fail, and paths that need
focused in-game verification.

## Tutorial inventory

After removing Lua block comments and line comments, the scenario defines:

- 246 active tutorial items.
- 244 items reachable from a `SetRaiseEvents(...)` root through `NextID` chains.
- 2 active but unreachable items: `CONSTRUCTING_BUILDINGS_D` and
  `CONSTRUCTING_BUILDINGS_E`. `CONSTRUCTING_BUILDINGS_C` has no `NextID`, and
  neither later item has a raise event.
- 57 active detailed-interaction items using `SetUITriggers(...)`.
- 13 active advisor-only pointer items using `SetAdvisorUITriggers(...)`.
- 176 active items with no native UI trigger. These are advisor narration,
  event/prerequisite checks, camera or selection setup, goal handling, or
  cleanup. They do not depend on an enabled native control tree while active.

The file also contains 14 block-commented item definitions. They are not part of
the runtime inventory: `CIVICS_TREE_A`, `BUILDERS_O`, `BUILDERS_P`,
`MEETS_ANOTHER_CIV_D` through `MEETS_ANOTHER_CIV_M`, and
`FIRST_TRADE_UNIT_D`.

## Native tutorial contract

`InitializeTutorial()` selects `InputContext.Tutorial`, activates tutorial input
filtering, disables several unit operations, disables automatic end turn, and
applies permanent city-panel restrictions for the scripted portion.

For a detailed item, `TutorialUIRoot.RaiseDetailedTutorial()`:

1. Shows every ID/trigger in `UITriggers`.
2. Enables each control ID or tag in `EnabledControls`.
3. Disables each tag in `DisabledControls`.
4. Applies the tutorial overlay state.

Completing the intended native action must still raise the item's exact
`SetIsDoneEvents(...)` listener or satisfy its done function. Merely changing
the same game state through an unrelated API is not always sufficient.

CAI is safest where its widget activates the live native control with
`DoLeftClick()` or calls the final vanilla handler that raises the same event.

## Detailed and advisor-trigger matrix

### Advisor popup

Assessment: compatible on the normal path.

CAI mirrors the live advisor text and native button stack. Activating a CAI
advisor button calls the corresponding native button's `DoLeftClick()`, which
retains `AdvisorPopup_ShowDetails`, `AdvisorPopup_ClearActive`, audio cleanup,
and item-specific callbacks.

There are 20 active calls to `AdvisorPopup_ShowDetails(...)`; other detailed
items have no advisor button and enter detailed mode immediately.

### Action Panel

Detailed items:

- `TURN_BASED_C`
- `SELECT_RESEARCH_8`
- `SELECT_END_TURN_B`
- `SELECT_END_TURN_PRODUCTION`
- `SELECT_END_TURN_C`
- `SELECT_END_TURN_D`
- `SCOUTS_D2`
- `SCOUTS_E`
- `SELECT_END_TURN_RESEARCH`
- `RESEARCH_IRRIGATION`

Advisor-only pointer:

- `NOTIFICATION_PANEL`

Assessment: intended end-turn actions are implemented, but the permission timing
is unsafe.

CAI's end-turn hotkey delegates to vanilla `OnInputActionTriggered` and checks
the live end-turn controls, the slow-turn input shield, and
`CAI_TutorialActionPanelAllowed`. This preserves `LocalPlayerTurnEnd`,
production/research blocker opening, and vanilla notification activation.

However, `TutorialUIRoot_CAI.NotifyActionPanelAllowed()` derives permission from
the active item's declared `UITriggers`, not from whether
`RaiseDetailedTutorial()` has actually run. `ActivateItem()` calls it while the
advisor is still visible. An Action Panel item is therefore enabled before the
player selects the advisor's Details/OK path. Conversely, every advisor-only
item with no detailed triggers is treated as allowing Action Panel input.

Likely failure: pressing the CAI end-turn binding while an Action Panel advisor
is still open can complete or advance game state underneath the active advisor,
leaving the tutorial chain and popup lifecycle out of order.

### Production Panel

Detailed items:

- `TRAIN_WARRIORS`
- `TRAIN_BUILDER`
- `CONSTRUCTING_BUILDINGS_C`
- `TRAIN_SETTLER_B`
- `TRAIN_SLINGER`
- `DISTRICTS_F`
- `CAMPUS_COMPLETE_D`

Assessment: strong static match; focused test still required.

These items expose only the `ChooseProductionMenu` subtree and a tagged
production row. `TutorialUIRoot_CAI` adds the whole `/InGame/ProductionPanel`
context to `UITutorialManager`'s always-receive-input set for exactly these seven
items. CAI rows activate the live vanilla production buttons, preserving
`CityProductionChanged_*` and `DistrictPlacementInterfaceMode`.

CAI also disables queue-only behavior while `IsTutorialRunning()` is true,
which matches the tutorial's single-choice production flow.

Risk: `tutorialActivatedIds` in `TutorialUIRoot_CAI.lua` is empty even though
the surrounding input-handler code says it exists to route manager input when
only a partial context is active. The always-receive-input hooks may make that
route redundant, but this cannot be proven statically.

### City Panel

Detailed items:

- `OPEN_CITY_PANEL`
- `CONSTRUCTING_BUILDINGS_B`
- `TRAIN_SETTLER_A`
- `DISTRICTS_A`
- `CAMPUS_COMPLETE_C`

Assessment: compatible on the intended path.

CAI's production action uses `LuaEvents.CityPanel_ProductionOpen()` when the
panel is closed. `TutorialUIRoot` listens to that same event as
`ProductionPanelViaCityOpen`, so the tutorial completion contract is retained.

The scenario's permanent `Tutorial_ContextDisableItems("CityPanel", ...)`
restrictions still affect the included vanilla City Panel. CAI exposes
additional city information and actions through its own widgets, so the
tutorial restriction is not a complete accessibility-layer sandbox.

### Unit selection, Unit Panel, and World Input

Unit Flag Manager detailed items:

- `SELECT_SETTLER`
- `SELECT_WARRIOR_B2`
- `MOVE_WARRIOR`
- `EXPLORE_B`
- `MOVE_WARRIOR_B`
- `MOVE_WARRIOR_C`
- `BUILDERS_D`
- `CITY_DEFENSE_C`
- `EXPLAIN_RESOURCES_E`
- `FORTIFY_WARRIOR_B`
- `SETTLER_FORMATION`
- `MOVE_SETTLER`

Unit Panel detailed items:

- `FOUND_FIRST_CITY`
- `MOVE_WARRIOR`
- `MOVE_WARRIOR_B`
- `MOVE_WARRIOR_C`
- `BUILDERS_D`
- `BUILDERS_F`
- `CITY_DEFENSE_B`
- `CITY_DEFENSE_C`
- `EXPLAIN_RESOURCES_E`
- `EXPLAIN_RESOURCES_F`
- `FORTIFY_WARRIOR_B`
- `SETTLER_FORMATION`
- `MOVE_SETTLER`

World Input detailed items:

- `SELECT_SETTLER`
- `SELECT_WARRIOR_B2`
- `MOVE_WARRIOR`
- `EXPLORE_B`
- `MOVE_WARRIOR_B`
- `MOVE_WARRIOR_C`
- `SCOUTS_D2`
- `BUILDERS_D`
- `CITY_DEFENSE_C`
- `EXPLAIN_RESOURCES_E`
- `FORTIFY_WARRIOR_B`
- `SETTLER_FORMATION`
- `MOVE_SETTLER`
- `PLACE_DISTRICT`

Assessment: action execution and movement restrictions mostly match, but CAI can
bypass the native map-selection lock.

CAI Unit Panel consumes the final vanilla action table. Tutorial-disabled unit
operations therefore remain disabled, and CAI activation uses the final action
control/handler. The movement helper mirrors the tutorial's unit-type, hex, and
single-destination restrictions before issuing a move.

CAI World Input's primary plot action independently collects units and cities
and calls `UI.SelectUnit()`/`UI.SelectCity()` directly. It does not consult
vanilla World Input's local `m_kTutorialPermittedHexes`, which is set by
`Tutorial_DisableMapSelect`. During locked movement/placement steps, a player
can therefore select an otherwise forbidden unit or city through CAI. Most
done functions reject the wrong unit, but selection can still disturb the
scripted state or expose actions Firaxis intended to suppress.

The tutorial restriction listeners are also registered twice in the World
Input context: once at the end of `interfaceInfoHelpers_CAI.lua` and again by
`EventSubs_CAI.lua`. Most state changes are idempotent, but duplicate unit
restriction events log false data errors and hex restrictions are temporarily
duplicated.

### Research Chooser

Detailed items:

- `SELECT_RESEARCH_A`
- `SELECT_POTTERY_TECH`
- `RESEARCH_IRRIGATION_B`
- `RESEARCH_IRRIGATION_C`

Assessment: compatible on the intended path.

The chooser activates the tagged live vanilla technology row with
`DoLeftClick()`, preserving `ResearchChanged`. CAI blocks its ordinary
World Tracker chooser hotkey while a tutorial is running, preventing an
unprompted chooser from bypassing the rail.

### Technology Tree

Detailed items:

- `TECH_TREE_G2`
- `TECH_TREE_K`

Advisor-only pointer items:

- `TECH_TREE_D`
- `TECH_TREE_E`
- `TECH_TREE_F`
- `TECH_TREE_H`
- `TECH_TREE_I`
- `TECH_TREE_J`

Assessment: compatible on the intended path, with input-filter verification
required for close.

CAI selects Writing through the live vanilla node button when available, which
preserves `ResearchChanged`. The close item includes both the `TechTree`
context and `TechTreeModal` hash, and the CAI root ID is included in the
tutorial Escape passthrough list.

### Civics Tree

Detailed items:

- `CIVICS_TREE_E`
- `CIVICS_TREE_G`
- `CIVICS_TREE_H` (pointer-only trigger string, but still a detailed item)

Assessment: deliberately bridged and likely compatible.

Opening uses the final Launch Bar action. Civic selection prefers the live
vanilla node button and preserves `CivicChanged`. The close item exposes only
`TutorialCloseCivicsPointer`; CAI compensates by adding the whole
`/InGame/CivicsTree` context to the always-receive-input set for
`CIVICS_TREE_H`. Its accessible panel ID is also in the Escape passthrough
list.

### Government and policies

Detailed items:

- `GOVERNMENT_POLICIES_D` through Launch Bar
- `GOVERNMENT_POLICIES_H` through `ButtonPolicies`

Assessment: deliberately bridged and likely compatible.

The open hotkey delegates to vanilla's government toggle. Policy-tab activation
clicks `Controls.ButtonPolicies`, preserving `GovernmentPoliciesOpened`.
Because `GOVERNMENT_POLICIES_H` exposes only the button subtree, CAI adds the
whole `/InGame/GovernmentScreen` context to the always-receive-input set for
that item.

### Launch Bar

Detailed items:

- `GOVERNMENT_POLICIES_D`
- `CIVICS_TREE_E`
- `TECH_TREE_A`
- `GREAT_PEOPLE_C`
- `FIRST_PANTHEON_D`

Assessment: callback-compatible, input-filter behavior needs verification.

Each CAI shortcut checks the live native Launch Bar button and delegates to the
corresponding vanilla toggle action. That preserves `GovernmentScreenOpened`,
`CivicsTreeOpened`, `TechTreeOpened`, `GreatPeopleOpened`, and
`PantheonPanelOpened`.

The tutorial enables the native button tag, while the user presses a CAI input
action. Static Lua cannot prove that every custom `InputActionStarted` event is
allowed by the native tutorial control filter.

### Great People

Detailed open item:

- `GREAT_PEOPLE_C`

Advisor-only pointers:

- `GREAT_PEOPLE_D`
- `GREAT_PEOPLE_E`

Assessment: compatible for this chain.

The Great People accessibility layer is a wildcard addition and retains the
final vanilla popup. These tutorial steps only inspect ability and cost while
the advisor is active; no detailed Great Person purchase/recruit action is
required.

### Pantheon Chooser

Detailed close item:

- `FIRST_PANTHEON_I`

Assessment: high risk of a hard stop.

The item completes only on `ReligionPanelClosed` or `PantheonPanelClosed`.
CAI's Pantheon root (`CAIPantheon_Panel`) has no root Escape binding and is not
in `TutorialUIRoot_CAI.escapePassthroughIds`. TutorialUIRoot receives Escape
first and opens the pause menu, so the chooser's original input handler does
not receive the close key. The accessible list also contains only beliefs; its
Cancel control is exposed only inside the confirmation dialog.

Unless the live chooser closes automatically at this stage or another global
toggle remains available, `FIRST_PANTHEON_I` can strand the tutorial.

### World Rankings

Detailed open item:

- `OPEN_WORLD_RANKINGS`

Later dependency:

- `CAMPUS_COMPLETE_J` raises only on `WorldRankingsClosed`.

Assessment: high risk of a hard stop.

CAI opens Rankings by delegating to vanilla's toggle action, preserving
`WorldRankingsOpened`. Its accessible panel closes only through an Escape input
binding. `CAIWorldRank_Panel` is absent from the tutorial Escape passthrough
list, so TutorialUIRoot can consume Escape and open the pause menu before the
Rankings handler runs. The same toggle hotkey may still close the partial
screen, but that is not the normal accessible close path and must be tested
under the tutorial filter.

### Trade Route Chooser

Advisor-only pointer:

- `FIRST_TRADE_UNIT_E`

Detailed items:

- `FIRST_TRADE_UNIT_G`
- `FIRST_TRADE_UNIT_H`

Assessment: compatible on the intended path.

Destination activation calls final `OnTradeRouteSelected`, and Begin Route
clicks the live `BeginRouteButton`. These preserve `TradeRouteConsidered` and
`TradeRouteAddedToMap`.

### Top Panel

Advisor-only pointers:

- `CAMPUS_COMPLETE_K`
- `FIRST_PANTHEON_B`
- `FIRST_TRADE_UNIT_C`

Assessment: no interaction break identified.

These items only show native callouts while the advisor is active. CAI does not
need to activate a Top Panel control to complete them.

### Partial Screen Hooks

Detailed item:

- `OPEN_WORLD_RANKINGS`

Assessment: opening preserves vanilla; see the World Rankings close risk above.

## Non-triggered UI effects

The 176 items without native UI triggers are not all UI-neutral. Important
forced effects include:

- `GET_STARTED`: switches to world view and hides the World Tracker.
- `NURTURE_CITY`, `CONSTRUCTING_BUILDINGS_B`, `TRAIN_SETTLER_A`,
  `DISTRICTS_A`, and `CAMPUS_COMPLETE_C`: select a city and raise
  `Tutorial_CityPanelOpen`.
- `SELECT_RESEARCH_A` and `SELECT_POTTERY_TECH`: raise
  `Tutorial_ResearchOpen`.
- `TECH_TREE_C` and `TECH_TREE_F`: scroll the native Technology Tree.
- `FIRST_TRADE_UNIT_J`: closes Launch Bar and partial screens and changes
  movement constraints.
- `PLAYER_VICTORY_B`: hides the bulk in-game UI.
- `CAMPUS_COMPLETE_K`: removes the scripted tutorial restrictions and adds
  long-term goals.

These effects remain wired because CAI composes the vanilla scripts and the
same Lua events. The main exception is any CAI-owned widget route that does not
observe the visibility/state change made by the vanilla context.

## Confirmed and likely breakpoints

### 1. Tutorial goals list uses deleted manager APIs — confirmed failure

`TutorialGoals_CAI.lua` still calls `mgr:CreateUIWidget(...)` twice and writes
`list.FocusedChild` directly. The no-back-compat manager exposes
`CreateWidget(...)` and owns focus as `Manager.CurrentPath`.

The file loads because the obsolete calls are inside `BuildGoalsList()`. The
failure occurs when the player presses the tutorial-goals hotkey or activates a
CAI tutorial-goal notification. Goal creation/completion notifications may work
until the list is opened.

Impact after `CAMPUS_COMPLETE_K`: the three post-rail goals are added, but the
player cannot reliably inspect them.

### 2. Pantheon close can be swallowed by TutorialUIRoot — likely hard stop

`FIRST_PANTHEON_I` requires a close event. The accessible Pantheon root is not
an Escape passthrough target and has no ordinary root close widget.

### 3. World Rankings close can be swallowed by TutorialUIRoot — likely hard stop

The end of the scripted rail waits for `WorldRankingsClosed`, while the
accessible Rankings screen relies on Escape and is not a passthrough target.

### 4. Action Panel is enabled during the advisor phase — confirmed timing bug

The gate is derived from declared triggers during `ActivateItem()`, rather than
from the current detailed-mode state. Early end-turn input can advance the
world beneath an advisor.

### 5. Native map-selection locks do not cover CAI plot interaction — confirmed bypass

CAI can directly select a local unit or city while Firaxis has disabled map
selection. Intended steps remain possible, but the on-rails sandbox is weaker
than the native tutorial expects.

### 6. Partial-context manager routing table is empty — unresolved high-risk gap

The code explicitly describes routing manager input through TutorialUIRoot when
only part of a context is activated, but `tutorialActivatedIds` has no entries.
Production, Civics close, and Government policies have explicit
always-receive-input hooks; no general bridge exists.

### 7. Era Complete/advisor priority loop — known runtime conflict

XP1/XP2 Era Complete remains queued at High priority while AdvisorPopup uses
Tutorial priority. Priority alternation can repeatedly re-show Era Complete,
restart its animation, and raise the advisor again. Existing logs already show
the loop. This is not specific to one base scenario item, but it can interrupt
a long tutorial game that crosses an era boundary.

### 8. Tutorial restriction listeners are duplicated — confirmed defect, lower severity

World Input registers the same CAI restriction handlers in both
`interfaceInfoHelpers_CAI.lua` and `EventSubs_CAI.lua`.

### 9. CAI TutorialUIRoot does not compose the expansion replacement — lower risk for RAILS

`TutorialUIRoot_CAI.lua` includes only `TutorialUIRoot`, not the XP1/XP2
replacement. The missing overrides add expansion listener names that may be
processed outside the local player's turn. The base RAILS item bank does not
depend on those expansion listener names, but this is still a replacement
composition gap.

## Recommended focused playthrough

Test in this order so the earliest blocking defects are isolated:

1. `GET_STARTED` through `TURN_BASED_C`: verify advisor Details, settler
   selection, Found City, City Panel production, Warrior selection, and the
   first end turn.
2. Research and early movement: verify Mining selection, plot interaction,
   movement restrictions, end-turn blockers, and Builder production.
3. Production variants: Monument, Settler, Slinger, Campus placement, and
   Library.
4. Government/Civics/Technology screens: verify open, selection, and Escape
   close while the detailed tutorial filter is active.
5. Pantheon: specifically verify that `FIRST_PANTHEON_I` can close and advance.
6. Great People and trade route chains.
7. World Rankings: open it at `OPEN_WORLD_RANKINGS`, close it through the
   documented accessible path, and confirm `CAMPUS_COMPLETE_J` raises.
8. After `CAMPUS_COMPLETE_K`, open the tutorial goals list. This is expected to
   fail until `TutorialGoals_CAI.lua` is migrated.
9. If the game crosses an era during any chain, capture the AdvisorPopup/Era
   Complete priority behavior separately.

## Overall conclusion

The tutorial is not currently safe to play end to end with CAI.

Most intended actions are structurally sound because CAI delegates back to
live vanilla controls and handlers. The highest-probability scripted hard stops
are Pantheon close and World Rankings close. The tutorial-goals list is a
separate confirmed failure after the scripted rail. Action Panel timing and
CAI's map-selection bypass can desynchronize the tutorial if the user invokes
actions outside the advisor's intended moment.
