# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- Added mod support for the Nubia scenario. 
- Added mod support to the Black Death scenario
- Added mod support to the Conquests of Alexander scenario
- Added mod support to the Outback Tycoon scenario
- Added mod support to scenario event popups, including their descriptions, effects, unlocks, and mandatory choices.
- Added the single-player Scenarios option to the accessible Main Menu and mod support for scenario Setup. Note that this is in preparation for adding support to official scenarios. While some might work currently, keep in mind that they are untested, and others are simply not yet integrated
- Added World Scanner settings to control whether City management and Recommendations automatically receive scanner focus when they become available. Both settings are disabled by default.
- Added Cursor settings to independently control whether selecting a city or unit automatically moves the navigation cursor to its tile. Both settings are enabled by default.
- Added ten save-specific map-tac bookmarks. `Ctrl+Shift+1` through `Ctrl+Shift+0` assigns or replaces bookmarks at the navigation cursor, `Ctrl+1` through `Ctrl+0` jumps to them, and `Alt+1` through `Alt+0` reads their direction. All bookmark actions are rebindable.
- Civilopedia Ctrl+F now searches article titles and body text using the complete entered phrase and shows one extended excerpt in the tooltip. Article-title matches retain the game's relevance priority over body matches. Section, group, Chapter and stat headings are not included in the searchable text. Note: this feature invalidates search term exclusion
- Added a UI setting to control whether search panels automatically focus their first result. It is enabled by default.

### Changed

- In world rankings, custom-victory and Score tabs now follow the rows, order, values, details, and tooltips produced by the active scenario or mod instead of assuming the standard game layout. This was done to avoid having to handle every separat case manually, since these tabs are dynamic
- Research and civic chooser tooltips now identify the technologies or civics they lead to.
- Reading the selected city or unit summary using the key binding (tilde by default) speaks its direction from the navigation cursor first, followed by the summary.
- Control f to open the search panel executes on key-down, same as all other input bindings
- Documented the search panel and type ahead in the readme

### Fixed

- Tech and civic boost popups now report 100% and say the item was completed when a boost finishes it, instead of reporting that progress fell to 0%.
- Policies can now be viewed, selected, replaced, and removed from the Government screen in the Black Death scenario.
- Diplomacy and deal screens remain navigable when an advisor message appears while they are open.
- Input help now identifies the Delete shortcut for removing an AI player in Advanced Setup and Scenario Setup.
- Create game now shows Map Type in the Basic view and opens the full map-selection screen from both Basic and Advanced views. Setup options expose their specific invalid-reason explanations, AI leader changes reset incompatible alternate colors, unavailable sections and choices stay hidden or disabled, and options removed by a configuration refresh no longer remain in the CAI list.
- Unit and city ownership labels now use the civilization's defined adjective and fall back to its localized name when the adjective is missing, fixing raw localization tags in Outback Tycoon and other scenarios.
- Fixed the unit panel failing to load in scenarios that remove unit-operation definitions, including the Alexander scenario. This caused a bug where you couldn't cycle units, or read their info
- Fixed certain UI widgets trapping navigation input if they are disabled
- Fixed an issue with the search pannel, where typed character echo interrupted the search result speech
- Search panels no longer move focus when a search has no results. An empty search now displays `Type text to search` instead of `No results`.

## [0.1.5] - 2026-07-15

### Added

- `F6` quick load now asks for confirmation before loading the quick-save slot and announces when loading is unavailable. The action is rebindable in the Key bindings tab.
- `F5` quick save announces whether the game was saved or saving is currently unavailable. The action is rebindable in the Key bindings tab.
- Added UI-opening key bindings announcements for why a screen cannot open, including unmet city-states, missing Great Works, unavailable spy or trade-route capacity, tutorial restrictions, disabled game capabilities, and the World Congress starting era.
- Added Surveyor commands for counting nearby improvements (`Ctrl+Shift+A` / `Ctrl+Shift+Numpad 4`), districts (`Ctrl+Shift+Q` / `Ctrl+Shift+Numpad 7`), and tile ownership (`Ctrl+Shift+Z` / `Ctrl+Shift+Numpad 1`), as well as listing visible neutral units (`Ctrl+Shift+D` / `Ctrl+Shift+Numpad 6`). All of these are rebindable in the Key bindings tab in game options
- `Shift+Space` (rebindable) speaks the current Action Panel turn blocker or between-turn waiting message. New Events settings independently control automatic turn-blocker and between-turn announcements.
- Changing the cursor audio volume plays a cursor step sound as a preview. Only works in game. You can still change the volume from the main menu should you wish
- World Scanner settings now include a beacon volume slider that plays a centered beacon preview when adjusted. Preview sound only works in game

### Changed

- Choosing a World Congress resolution outcome now automatically commits the free first vote. Special-session proposals still require an explicit vote to be added. This closely matches vanilla flow
- In world congress, the order in which you fill in each resolution is no longer fixed. as long as you resolve all blockers, you will be able to click the next button.
- World Congress target choices are always available and remain selected when changing outcomes. The Next button's tooltip now identifies every resolution or special proposal that still needs an outcome, target, or vote.
- Relative direction text now says `Here` whenever the target is on the reference tile, including unit rows, map tacks, map search, and scanner results.
- Unit-list row tooltips now report location followed by summary details.
- World Scanner group and item navigation refreshes the current live category, reflecting newly added or removed map items.
- Scanner sorting now stays anchored when inspecting or jumping to items. Changing category or subcategory resets the sorting origin to the current cursor, while spoken directions and distance continue using the cursor's live position. This should no longer jumble items around just because users moved the cursor.

### Fixed

- World Congress navigation now returns to the previously focused resolution after leaving and re-entering the resolution tree.
- Multiplayer join failures restore accessibility mod before displaying their error dialog, including missing-content and failed content-configuration cases. This should solve the mod failing to read localized text or any UI widget roles
- Map tacs now properly speak direction in the map-tacs list. This was broken
- Fixed escape handling for the governer confirm promotion dialog.
- Fixed an issue where the scanner tried to validate all items for every category on every scan. This caused it to lag in huge maps, or maps that are fully revealed. Woops
- Made staging-room team choices display as Team 1, Team 2, and so on instead of exposing zero-based team numbers.
- Fixed open dropdowns so that they keep focus on the same option when their screen content refreshes.
- Play By Cloud game setup refreshes no longer announce a stray `2`.
- Spatial sounds attenuate properly instead of playing at full volume regardless of posission
- Fixed an issue with popup dialogs not letting you press enter to do default action while focused on an edit box

## [0.1.4] - 2026-07-13

### Added

- World Scanner items can play a positional beacon from their map location when focused or when their direction is repeated via the end key (default binding). The beacon can be disabled in the World scanner settings.
- `Ctrl+S` now moves the navigation cursor to your capital city without changing the current selection.
- Successful immediate unit actions now announce their result, including stationary orders, improvements, feature and resource work, repairs, religious actions, support actions, and other direct commands. Improvement results identify what changed, such as `Farm built`, `Woods removed`, or `Farm repaired`.
- Visible unit movements are recorded in the persistent message buffer with their exact visible path, or their net direction when the path is discontinuous, plus their last known location. As with any other buffer entries that carry locations, you may use shift backslash (default) to jump cursor to this tile. Units moving together in a formation produce one movement-log message listing all formation members. Event settings allow you to choose what to announce; Military units, civilian units, both, or neither for each owner relationship. Only barbarian movement is enabled by default.
- Hotseat unit-movement announcements are held until the observing player's next turn begins.

### Changed

- Unit actions now trigger on key down instead of key release. This should solve the issue of them failing to execute due to releasing alt too quickly
- Navigation settings are now organized into Cursor, World scanner, and Events sections. Existing values for the moved settings will reset to their defaults because their storage sections changed. Sorry
- The Resources, City Status, and Gossip tabs in Empire Reports no longer have default key gestures. Their actions remain available for custom key bindings. You can still access the tabs from the reports screen, `f2` by default
- Expanded unit information when pressing the s key: friendly units include movement, status, combat stats, experience, upgrades, promotions, and carried aircraft; enemy units include combat strength, ranged strength, and range.
- Unit information now calls the unit's range value `Range` because it can represent noncombat capabilities such as an Observation Balloon's observation radius.

### Fixed

- - Interface information, spoken on cursor move or via space (default binding), now says that an area is uncharted without revealing hidden tile details.
- Queued paths, waypoints, and unit-action targets in the World Scanner once again announce their tile information instead of the `No tile` debug message.
- Formation movement is now tracked correctly in the unit-movement log and movement-cost previews.

## [0.1.3] - 2026-07-12

### Changed

- English display-language speech now simplifies accented Latin letters and ligatures so names with unsupported characters remain readable.

### Added

- The World Scanner Terrain category now includes all hidden tiles under the new Unexplored sub-category.

### Fixed

- World Scanner item navigation now plays the wrapping sound when crossing the first or last item.
- Optimized the scanner so that it performs better on bigger maps

## [0.1.2] - 2026-07-12

### Added
- Movement cursor information now reports the selected unit's total movement cost and, when nonzero, movement remaining on arrival. It respects all known movement rules.

### Changed

- World Scanner cities can now be grouped by civilization or navigated as one group per city. Grouping by civilization is enabled by default.
- Long tooltips and Great Person biographies are now divided into shorter, natural reading sections. The target length for splitting long text into spoken sections can be changed in mod Settings, under the UI category.
- Movement cursor information now reports the selected unit's total movement cost and, when nonzero, movement remaining on arrival.
- The geography tile readout now includes districts, buildings, and great works.
- Surveyor radius controls now use Shift+W to grow and Shift+X to shrink. Note: You need to manually rebind this or clear your "%localappdata%\Firaxis Games\Sid Meier's Civilization VI\InputSettings.json"

- Queued movement paths and waypoints now reflect the unit's current route whenever they are read, including on non-selected unit flags.

### Fixed

- Movement arriving next turn is now announced as taking 1 turn instead of 2 turns.

## [0.1.1] - 2026-07-12

### Changed

- In the options screen, dropdowns that only offer Enabled and Disabled are now presented as checkboxes.
- The Switch UI Layout control is no longer included in the accessible Options menu. It is useless for us.
- The Ctrl+Y tree now combines yields and strategic resources in two categories.
- Unit quick-move actions now announce `Not enough movement` instead of queueing an adjacent move for a later turn.
- Tooltips that only duplicate a label are no longer spoken.
- civilopedia lookup now opens using ctrl + i

### Fixed

- Unit movement no longer asks for combat confirmation when entering hostile territory or a non-attackable district without an attackable target.
- Fixed modifier-based input actions not registering when the modifier was released too early.

## [0.1.0]

### Added

- Initial release.
