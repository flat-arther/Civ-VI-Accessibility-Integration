# CAI priorities for UI outside elevated native popups

## Current policy (2026-10-07)

User-directed priority experiment implemented:

- Standalone native screen roots without a native popup priority use explicit **99**.
  This covers ResearchChooser, CivicsChooser, ProductionPanel, trade origin/route/
  overview (including Better Trade Screen), PantheonChooser, EspionageChooser/
  Overview, WorldRankings, GreatWorksOverview/Showcase, EraProgressPanel, map input,
  TechTree/CivicsTree, CityStates, CityPanelOverview, ChatPanel, MapPinListPanel,
  MapSearchPanel, all four World Builder editor/placement screens and Intro EULA.
- Owner-relative ChooseArtifact, DisloyalCityChooser, EspionageEscape and
  TreatWithTribePopup dialogs inherit their opener's priority, per the user's
  follow-up clarification. They must not sit below an opener above 99.
  DeclareWarPopup remains a diplomacy exception.
- GovernorPanel, GovernorAssignmentChooser and ClimateScreen use native Low
  (100). GovernorPanel also reparents to `/InGame/Screens`; its explicit native
  queue priority still supplies the CAI priority.
- Previously inherited native popup roots now use their native priority:
  UnitPromotionPopup and SecretSocietyPopup Low (100), CreateCorporationPopup
  High (1000), and MapPinPopup Current (9999). MainMenu explicitly uses native Low.
- Frontend LeaderPicker, CityStatePicker, MapSelect and MultiSelectWindow are
  input-trapping child views of the active setup root, with opaque return-focus
  capture. They have no independent stack priority. This preserves their native
  ownership above queued setup without inheriting a separate root priority.
- Diplomacy, existing explicit popup priorities and CAI-only views are unchanged.
  Notification Center/message buffer is CAI-only, despite being listed with
  ordinary roots in the original inventory below. Quick Deals retains inheritance
  because its native opening explicitly reparents the context.

No manager sorting/input architecture was changed. These are explicit priorities
and a frontend picker ownership adjustment; game acceptance remains unverified.
Inheritance remains appropriate for owned pickers/dialogs/modal views, not only
native reparenting. Ordinary standalone screens stay explicit.

## Original inventory (2026-10-06, before the experiment)

The remainder records the pre-change priorities and source anchors for comparison;
the current policy above supersedes them. No behavior had changed at that time.

The primary list covers accessible screen roots shown through the ordinary native
hierarchy, rather than QueuePopup or PushModal. Native dialogs shown directly and
queued screens retaining parent placement are listed separately. CAI-only stack
views are included because they can also change the active accessible root.
This inventories implemented CAI stack entries, not every native HUD control.

`Inherited` means the Push call supplies no priority. The manager uses a retained
widget priority if present, otherwise the current top's priority, otherwise Low.
It does not mean a fixed Low priority. Numeric values below are the checked-in
IDE enum values and are how CAI's comparator treats those constants.

## In-game ordinary screen roots

Explicit Low (100):

- ResearchChooser — `ResearchChooser_CAI.lua:312`.
- CivicsChooser — `CivicsChooser_CAI.lua:258`.
- ProductionPanel — `ProductionPanel_CAI.lua:1252`.
- TradeRouteChooser, including Better Trade Screen — `TradeRouteChooser_CAI.lua:292`, `TradeRouteChooser_BetterTradeScreen_CAI.lua:456`.
- TradeOriginChooser, including Better Trade Screen — `CAITradeOrigin.lua:116`.
- TradeOverview, including Better Trade Screen — `CAITradeOverview.lua:112`.
- PantheonChooser — `PantheonChooser_CAI.lua:120`.
- EspionageChooser — `EspionageChooser_CAI.lua:671`; additionally uses `below` for EspionagePopup.
- EspionageOverview — `EspionageOverview_CAI.lua:850`.
- WorldRankings — `WorldRankings_CAI.lua:2739`.
- GreatWorksOverview — `GreatWorksOverview_CAI.lua:1036`.
- GreatWorkShowcase — `GreatWorkShowcase_CAI.lua:236`.
- EraProgressPanel — `EraProgressPanel_CAI.lua:316`.
- Game/map view and World Builder map view — `WorldInput_CAI.lua:1084-1087`.

Inherited:

- TechTree and CivicsTree — shared `CAIResearchTree.lua:744`.
- CityStates — `CityStates_CAI.lua:1453-1455`.
- CityPanelOverview — `CityPanelOverview_CAI.lua:1067`.
- DiplomacyRibbon accessible leader list/table — `DiplomacyRibbon_CAI.lua:812`.
- ChatPanel — `ChatPanel_CAI.lua:595`; the separate kick-vote dialog uses Current.
- MapPinListPanel — `MapPinListPanel_CAI.lua:447`.
- MapSearchPanel — `MapSearchPanel_CAI.lua:499`.
- Notification Center / message buffer — `NotificationPanel_CAI.lua:555`.
- WorldBuilderMapEditor — `WorldBuilderMapEditor_CAI.lua:408`.
- WorldBuilderPlacement — `WorldBuilderPlacement_CAI.lua:931`.
- WorldBuilderPlayerEditor — `WorldBuilderPlayerEditor_CAI.lua:759`.
- WorldBuilderPlotEditor — `WorldBuilderPlotEditor_CAI.lua:467`.

Other explicit priorities:

- DiplomacyActionView, including conversation and cinema — Utmost (5000), `DiplomacyActionView_CAI.lua:3046-3081`.
- DiplomacyDealView — Current (9999), `DiplomacyDealView_CAI.lua:1307`.

## Queued screens that retain normal render/input parent placement

These do use QueuePopup, so are not strictly non-popup-queue UIs. However, their
RenderAtCurrentParent/InputAtCurrentParent flags make them relevant when changing
priorities for ordinary screens. All also specify AlwaysVisibleInQueue.

- GovernmentScreen — CAI Low (100); native Low.
- ReligionScreen — CAI Low (100); native Low.
- GreatPeoplePopup — CAI Low (100); native Low.
- GovernorPanel — CAI Inherited; native Low.
- GovernorAssignmentChooser — CAI Current (9999); native Low.
- ClimateScreen — CAI Inherited; native Low.
- HistoricMoments — CAI Medium (500), or Current (9999) when opened from EndGame;
  native uses the same GetPopupPriority function. Its native flag variants retain
  render/input placement in both paths.
- Quick Deals (`qd_dealpopup`) — CAI Inherited; native Low. The supported mod also
  reparents its context to `/InGame/Screens` after queuing.

CAI source anchors: `GovernmentScreen_CAI.lua:1250`, `ReligionScreen_CAI.lua:1482`,
`GreatPeoplePopup_CAI.lua:1649`, `GovernorPanel_CAI.lua:1259`,
`GovernorAssignmentChooser_CAI.lua:289`, `ClimateScreen_CAI.lua:1111`,
`HistoricMoments_CAI.lua:208`, `qd_dealpopup_CAI.lua:777`.

## Native dialogs shown directly, without QueuePopup/PushModal

These are dialog-style UI rather than ordinary panels, but technically also lack
native popup-queue priorities. Keep them explicit rather than treating them as
normal panels solely because they do not call QueuePopup.

- ChooseArtifact — CAI High (1000).
- DisloyalCityChooser — CAI Medium (500).
- EspionageEscape — CAI Low (100).
- DeclareWarPopup — CAI Current (9999).
- TreatWithTribePopup — CAI Inherited.

Source anchors: matching `_CAI.lua` files, lines 52, 53, 72, 145 and 77 respectively.
CreateCorporationPopup is excluded: native ExclusivePopupManager:Lock queues it.

## CAI-only stack views and secondary roots

Explicit Low (100):

- ActionPanel end-turn-blocking notification list.
- CityPanel city-action list and citizen-yield-focus list.
- Unit browser (`CAIUnitBrowser`).
- UnitPanel simple promotions, rename editor, action list, destination list and
  unit-abilities list.
- Minimap lens list.
- TutorialGoals list.

Inherited:

- LaunchBar accessible menu.
- WorldTracker crisis list.
- Research tree filter/search results.
- WorldInput interface-mode roots.
- Plot interaction chooser (`CAIPlotInteractions`).
- World Builder value editor (`CAIWorldBuilderInput`).
- CityPanelOverview city-name editor.
- Scanner category-name editor.
- Shared CAI leader picker (`CAIWidgetHelpers_LeaderPicker`).
- DiplomacyActionView subordinate action lists/panels.
- DiplomacyDealView subordinate deal lists/wrappers.
- EspionageChooser confirmation dialog.
- PantheonChooser confirmation dialog.
- TradeRouteChooser confirmation dialog, vanilla and Better Trade Screen.
- GovernorPanel appointment and promotion confirmations.
- Quick Deals subordinate wrapper.

Explicit Current (9999):

- ChatPanel kick-vote confirmation.
- GovernorAssignmentChooser confirmation.
- Government policy slot picker and all-policies view.
- GreatWorksOverview work picker.
- MapPinListPanel delete confirmation.
- ReligionScreen confirmation dialogs and belief pickers.
- WorldBuilderMapEditor map-tag editor.

Tutorial (2000): TutorialUIRoot's CAI tutorial dialogs. These are tutorial-owned
dialogs, not ordinary panels to lower indiscriminately.

Input Help, Settings, Civilopedia lookup, and the manager SearchPanel are owned
child views rather than separate stack roots, so they have no independent stack
priority. Ambient HUD readers such as TopPanel likewise have no root priority.
ProductionManager has no separate CAI screen implementation.

## Frontend and shared UI

Ordinary hierarchy-based pickers, all CAI Inherited:

- LeaderPicker.
- CityStatePicker.
- MapSelect.
- MultiSelectWindow.
- IntroScreen's EULA panel.

The four setup pickers are opened by SetHide(false) in AdvancedSetup; their native
code may call them popups colloquially, but the open path does not QueuePopup.

Additional CAI-only roots within queued frontend/shared screens:

- MainMenu submenu — Inherited.
- MainMenu update dialog — Current (9999).
- AdvancedSetup conflict dialog — Current (9999).
- Mods group editor — Current (9999).
- StagingRoom exit confirmation — Current (9999).
- WorldBuilderMenu advanced-import confirmation — Current (9999).
- My2K account dialogs — Current (9999).
- Options binding capture — Current (9999).
- Options reset-bindings confirmation — Inherited.
- SaveGameMenu confirmation — Inherited.
- LoadGameMenu quick-load confirmation — Low (100).

LoadScreen's CAI root uses Current (9999). Its engine-owned loading lifecycle is
separate from an ordinary gameplay panel. Multiplayer PBCNotifyRemind's dialog
uses Default (10000); it is a notification dialog, not a normal panel.

MainMenu, AdvancedSetup, ScenarioSetup, Mods, Credits, Hall of Fame/details,
Options, Load/Save menus, multiplayer menus and WorldBuilderMenu are excluded
from the ordinary-screen list because their native opening routes use QueuePopup.
ConfirmKick/EditHotseatPlayer and StateTransition use the native modal stack.
