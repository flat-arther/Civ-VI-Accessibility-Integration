## [Unreleased]

### Added

- Added support for the following mods: Detailed map tacs, yet, not another maps pack

### Fixed

- Fixed a bug with mod tutorials that caused the game to stop speaking if an advisor dialog appeared at the same time

## [1.0.1] - 2026-08-04

### Added

- Added an installer

## [1.0.0] - 2026-08-03

### Added

- Dialogs support Home and End to jump to the first and last control.
- Tables support Shift+Home and Shift+End to jump to the first and last column of the current row.
- Technology and Civics Trees include a Graph view for navigating prerequisite relationships directly. Right follows unlocked items, Left follows prerequisites, and Up or Down cycles between alternative branches. A View dropdown or Alt+1, Alt+2, and Alt+3 switches between Grid, Graph, and Tree views while preserving the current selection. Each screen remembers its selected view.
- The following screens now default to sortable comparison tables while retaining their existing alternative views, selectable with Alt+1 and Alt+2:
  - Great People — compares civilization progress toward recruiting each available Great Person.
  - Heroes — compares hero statistics, abilities, and commands.
  - Global Resources — compares known civilizations' resource totals.
  - Governors — compares governor status, promotions, and vanilla statistics.
  - Units List — compares unit status, movement, combat statistics, promotions, and nearby enemies.
  - City Status — compares city population, growth, defense, loyalty, yields, and other important statistics.
- Unit summaries now report the number of visible adjacent enemy units. The same information is available with Shift+0.

### Changed

- Widget positions are announced only within navigable containers such as lists, trees, tables, graphs, tab strips, submenus, and grids. Graphs announce position relative to the available Up/Down alternatives, while grids report row and column coordinates.
- The former Tooltip Section Reader has been expanded into the Focused Widget Reader, allowing it to read more than just tooltips.
- Sorted table headers and companion sort dropdowns now announce the actual sort order (for example, A to Z, Nearest First, or Strongest First) instead of simply Ascending or Descending.
- Units with queued movement now report Moving instead of Busy in the Unit Panel.
- Unit summaries now include available combat statistics. Abilities have been removed from summaries but remain available with Shift+7 or Alt slash when a unit is selected.
- City Status entries now include all city yields in their tooltips and can be sorted by distance or any available yield.

### Fixed

- Fixed a bug where the diplomacy screen could prematurely exit tutorial dialogs by moving focus to the conversation list.
- Fixed the Recall with Faith button on the Heroes screen.
- Fixed ascending table sorting producing inconsistent row order.

## [0.9.1] - 2026-08-02

### Fixed

- Completing ordinary district or wonder placement no longer leaves the accessible Production Panel open after the visual panel closes.

## [0.9.0] - 2026-08-01

### Added

- Tables and grids now support type-ahead. Grids search all cells, while tables search row labels and preserve the current column; standard result cycling, Up/Down navigation, Backspace, Escape, and grid tooltip matching behavior applies.
- Added support for the in-game tutorial. Tutorial screen-control callouts are spoken when their instruction appears and saved in a dedicated Tutorial category in the message buffer. The World Scanner shows the current world-located tutorial callout by its header and removes it when that instruction ends. Note that such callouts only appear in mods that utilize the tutorial system, and may not necessarily appear in a normal game.
- Added an event-driven accessibility tutorial system. Unseen tutorials can open inside the current screen, include a Show mod tutorials checkbox, and are remembered after Continue is pressed. Mod Settings can enable tutorials or reset all tutorial progress without closing Settings. These are mostly meant to explain the layout and input bindings of certain screens
- The Main Menu now introduces the accessibility interface, list, tree, table, and grid navigation, activation, type-ahead, tooltip reading, Input Help, and Mod Settings the first time it opens.
- Added detailed tutorials for complex in-game screens, Hall of Fame, and Additional Content. They describe each screen's actual control order, alternate table, grid, and tree views, contextual actions, and available bindings. Production includes separate queue guidance, while World Congress explains resolution voting, special-session voting, and submitting a proposal at the relevant stages.
- The Civilopedia begins with a new Accessibility Mod section before Basic Concepts. It contains an introduction, a key bindings reference, a search and type-ahead guide, a Screen Tutorials group with every catalog tutorial, and a detailed UI Widgets group organized into Leaf, Value, and Container widget articles. Included widgets have their own titled chapters. The section also contains gameplay articals.
- Added support for the Credits screen with package selection, a treeview for manual reading, and automatic narration synchronized with the visual credits roll. The automatic roll is paused while the treeview is focused. You can also press space to manually pause and unpause it while not focusing the treeview
- Added support  for the mods screen. Allows browsing and toggling installed mods, inspecting mod details, managing mod groups and compatibility warnings, and managing Steam Workshop subscriptions. Note that for subscriptions, the only actions allowed are updating, by pressing enter on a mod that has a pending update, or unsubscribing by pressing delete. Viewing or browsing the workshop uses the steam overlay, which is not accessible.
- Added Pirates scenario support, including relic loadouts and discoveries, Crew Morale in the T readout, ship crew values, scenario unit actions and targeting, Infamy score categories, treasure and infamous-pirate map information, relic sensor signals, Tavern and Sack status, and accessible Main Menu and in-game How to Play pages.
- Added Red Death scenario support, including faction unit actions, turn and global-ability status, Ctrl+W global-ability activation, safe-zone and Red Death cursor speech, scenario map objects in plot information and World Scanner, Grieving Gift targeting, eliminated-player chat and diplomacy state, accessible front-end and in-game tutorials, and observer controls.

### Changed

- The navigation cursor now announces when a directional move reaches the edge of the map.
- District and wonder placement no longer restrict the navigation cursor to the selected city's area or move it to the city center. Existing placement-target navigation and information remain available.
- World Scanner region entries now state how many tiles have been explored. Unexplored regions state their unexplored count, while Pirates and Red Death regions compare explored tiles with the officially shown full region. Geography uses differing explored sizes to distinguish matching names before adding a direction.
- Technology, Civics, Governor Promotions, and Unit Promotions now identify their spatial layouts as grids instead of tables. Record-oriented views such as City-States remain tables and can expose sortable headers.
- City-States defaults to a sortable overview table containing the complete comparison. Envoy cells include every bonus breakdown, Active Quests cells include each quest description, and one Foreign Relationships column combines all met non-player relationships. Tree view offers natural order and both explicitly described directions for every current table column and shares its selected sort with the table. A button or Alt+2 switches to the original expandable tree view, Alt+1 returns to the table, and the selected view is remembered.
- Hall of Fame graphs now organize recorded data by player, then turns containing changes, then the individual values that changed. Repeated values are omitted until they change again.
- In-game chat properly appears in the Online key-binding category.
- End-game results graph data is organized by player and turn. Expanding a player shows only turns containing recorded data, and expanding a turn shows every available replay value for that turn.
- The Tourism lens World Scanner now represents each tourism banner once, grouped by its visible High, Medium, or Low strength. Entries state the tourism value, strength, and international tourists, while cursor tile information reads the same. The interface info binding (space by default) on a tourism tile reads the entire breakdown.
- Government lens World Scanner results are grouped by government type while retaining separate civilization and city territory entries.
- The Multiplayer menu now exposes only the Civ Royale and Pirates tutorials instead of the match making play buttons, and each tutorial ends with Close instead of Play, preventing scenario matchmaking from disabling the accessibility mod. If you want to play any of the two scenarios, manually start a game or join a lobby. This was done to prevent the game from having you join a lobby that does not allow the accessibility mod, due to the host not having it installed
- The tooltip for the great people hotkey now menntions the heroes tab appearing in Heroes & Legends mode

### Fixed

- The Production Panel no longer remains open after the visual panel closes for City Management or another modal view. Cancelling district or wonder placement returns to the same production item.
- Returning from Hall of Fame game details now properly refreshes the accessible ruleset, tab, sort method, Overview, and History. Focus moves directly to Overview. This is a vanilla design choice, and it was previously causing desync issues
- Espionage mission dialogs remain accessible when advisor messages appear above them.
- Fixed the End Game panel not reopening when a player in observer mode reaches the final result screen.

## [0.8.0] - 2026-07-24

### Added

- Added scanner category management, open from under mod settings / world scanner. Categories can be toggled and reordered. Allows creating persistent custom categories from pre-built scanner sources and name filters. Note: filters function the same as scanner search queries, meaning that sub-strings and prefixes are accepted. You may choose to add terms to include or exclude.
- The World Scanner includes a Geography category for connected revealed landmasses and non-lake bodies of water. Landmass labels use revealed continent names; Gathering Storm water regions use official ocean or sea names. Directions relative to the home landmass are used to distinguish duplicates.
- The Surveyor can count revealed nearby land tiles by Breathtaking, Charming, Average, Uninviting, and Disgusting appeal using Ctrl+Shift+X or Ctrl+Shift+Numpad 2.
- Great Works and their work picker can be grouped by building or by city using a checkbox on the Great Works screen; building grouping is enabled by default.
- The Notification Panel has separate tabs for current notifications and message buffer history.
- Capturing another player's unit in multiplayer adds the capture message to message buffer.
- Unit-list rows let players jump the navigation cursor to a unit with Ctrl+Enter without selecting it.
- Added an Events setting to suppress visible combat-result announcements when none of the player's units, cities, or districts participate.
- Added a UI setting to choose whether Tree Home and End stay at the current depth or use the legacy full-tree behavior.
- Added a default-enabled UI setting that makes Up and Down cycle through type-to-find results and keeps the search active until focus leaves its list or tree or the search is cleared manually.
- Added a default-enabled UI setting that includes control tooltips in type-to-find. Tooltip-only matches follow label matches.
- Map tacs owned by the current player can be deleted after confirmation, either from the Map Pin List with Delete or at the navigation cursor with a rebindable action that also defaults to Delete.

### Changed

- World Scanner now groups connected unexplored regions, mountain ranges, and Continent, Political, Government, and Power lens areas into regions that target their nearest tile. Unexplored regions appear under Base terrain and include their tile count. Gathering Storm mountain ranges use their official names; other rulesets use generic names. Terrain also identifies every revealed tile with fresh-water access.
- Mod Settings opens within the current accessible screen and returns focus there when closed, instead of opening as a separate screen layer. This is mainly done to avoid input mis-haps, and you will likely not notice any change in functionality.
- Merged districts and constructed wonders into one scanner category.
- Surveyor terrain counts report hills as their underlying flat terrain plus Hills, report ordinary mountains only as Mountains, omit terrain details already implied by features such as oasis, marsh, floodplains, reef, volcano, and natural wonders, and include the number of tiles with fresh-water access.
- Climate event rows with a revealed map location include their direction from the navigation cursor. Activating one moves the cursor to the event without closing the Climate Screen.
- Great Works building instances include their direction from the navigation cursor. Activating one moves the cursor to its tile while keeping the Great Works screen open.
- Governments are presented as a flat list whose row labels identify the government tier, with concise government, bonus, heritage, prerequisite, and civic-progress information in each row's details. Newly available policies are identified in their row labels, and policy selection uses vanilla's card take/drop sounds.
- When the confirm policies button is disabled in the governments screen, its tooltip identifies every policy slot that still needs to be filled or explains that no policy changes have been made to confirm.
- Merged the yields and resources breakdown tree with the reports screen under Empire Economy and strategic resources. Empire Economy contains the complete yield, trade-route, favor, envoy, influence, and nuclear-stockpile breakdown. Strategic resource rows in the resources tab combine stockpile and per-turn flow with the existing named source details.
- Empire Economy contains all details about gold expenses. Cities lists Districts first and Buildings second, with each type expanding into its city instances; Units expands into its unit types.
- Concrete city, district, building, wonder, and unit rows in Reports include their location relative to the navigation cursor. Activating one closes Reports before moving the cursor to its tile.
- Empire Economy's collapsed summary includes Favor, Envoys, and trade-route usage when available. Science, Culture, Gold, Faith, and Tourism properly expand their city contributions into individual cities and each available city-level source breakdown. Gold deal income and costs expand into individual deals, and WMD maintenance expands by device type.
- World Rankings Overall victories expand into the complete ranked team and civilization list. Team rows expand into their members, and known-player details include victory progress, victory-specific tiebreak values, and additional status such as cultural dominance.
- Cultural World Rankings groups allied civilizations under team rows while leaving civilizations without teammates at the top level. Player details include domestic tourists and estimated turns to victory; expanding your civilization shows how many tourists each other civilization sends you, along with its tourism rate, lifetime tourism, and modifiers. The advisor text at the bottom also explains domestic and visiting tourists.
- World Rankings identifies the local civilization, local team, and multiplayer human names throughout its detailed victory tabs. Score advisor text contains the configured game-turn limit. Science milestones include Spaceport, technology, and project details, and Gathering Storm includes the final light-year requirement while withholding light-year progress until launch. Religion progress uses the full vanilla conversion wording.
- Mod sound effects follow the game's master volume setting.
- Religious units that can engage the player's religion in theological combat appear under enemy units even during diplomatic peace; same-religion units and Religious Alliance partners remain neutral.
- Civilopedia lookup now recognizes icon meanings, ignores parenthetical qualifiers in focused labels, and keeps only complete article-title matches instead of including partial-title suggestions. Seeriously, how do you get Francis from france!

### Fixed

- Civilopedia lookup recognizes article names after colon-prefixed labels, including technology and civic completion popups.
- Espionage mission dialogs no longer open and close repeatedly or briefly announce the placeholder mission title.
- The Climate Screen matches vanilla event visibility, identifies affected-city owners and CO2-contributing leaders, and announces recent polar-ice and sea-level updates.
- The Culture and civic summary (p by default) identifies anarchy and its remaining turns without incorrectly saying that governments are still locked behind Code of Laws.
- Government details no longer repeat base-game legacy descriptions, expose raw flat-bonus values, or announce disabled legacy-progression information in expansion games. Accumulated heritage identifies its complete effect, percentage, and source government, while expansion governments use their Major and Minor bonus labels.
- Monopolies and Corporations Products include their corporation and product benefit in Great Works details.
- Fixed a bug where Great Works gallery did not focus the entry's summary when manually pressing the previous next buttons
- Empire Economy summary and expanded Science, Culture, Gold, and Faith rates use consistent one-decimal rounding.
- Singular tree counts, unit counts, and nuclear-device counts use singular wording.
- Made type-to-find clear after activating or changing a widget, opening a dropdown, or expanding or collapsing a tree or submenu, so ordinary navigation resumes after interaction.
- World Scanner search opens immediately instead of rebuilding and indexing the world before accepting input. Submitted searches use ranked item-name matching
- Renaming a city from City Details waits for the game to apply the new name before returning focus, so the updated name is announced.
- The production panel queue now properly allows you to swap the item currently being produced with the first queued item, and vice versa. Delete on currently produced item removes it and moves up the first queued item

## [0.7.0] - 2026-07-18

### Added

- Added support for the previously missing map-tac visibility selector in multiplayer. Visibility changes take effect immediately so shareable tacs can be sent to chat, while cancelling restores changes that have not already been sent or confirmed.
- CAI now supports all official scenarios both single player or multiplayer, including their setup flows, rules, objectives, scoring, rankings, and event popups, except Pirates and Red Death. Support for those two is planned, though it may take a while
- Added World Scanner settings to control whether City management and Recommendations automatically receive scanner focus when they become available. Both settings are disabled by default.
- Added Cursor settings to independently control whether selecting a city or unit automatically moves the navigation cursor to its tile. Both settings are enabled by default.
- Added ten save-specific map-tac bookmarks. `Ctrl+Shift+1` through `Ctrl+Shift+0` assigns or replaces bookmarks at the navigation cursor, `Ctrl+1` through `Ctrl+0` jumps to them, and `Alt+1` through `Alt+0` reads their direction. All bookmark actions are rebindable. Bookmarks use the game's native map-tac system, which means you are able to share them over chat in multiplayer
- Civilopedia Ctrl+F now searches article titles and body text using the complete entered phrase and shows one extended excerpt in the tooltip. Article-title matches retain the game's relevance priority over body matches. Section, group, Chapter and stat headings are not included in the searchable text. Note: this feature invalidates search term exclusion for the civilopedia
- Added a UI setting to control whether search panels automatically focus their first result. It is enabled by default.

### Changed

- Current production now participates in Production Queue reordering: Shift+Down exchanges it with the first queued item, and Shift+Up on the first queued item moves that item into current production.
- Tree Home and End navigation now stays at the current depth, while Ctrl+Home and Ctrl+End move to the beginning and visible end of the full tree.
- Changed English hotkey names to speak punctuation keys as words, such as `Slash`, `Tilde`, and `Left bracket`, so screen readers do not need all-symbol verbosity to identify them.
- The Production panel now identifies the selected city, remembers that city when focus enters its city list, includes city yields in city-row details, and can sort cities by each yield.
- District placement, wonder placement, and city management now keep the navigation cursor on tiles assigned to the selected city and current purchasable, placeable, or swappable targets.
- In world rankings, custom-victory and Score tabs now follow the rows, order, values, details, and tooltips produced by the active scenario or mod instead of assuming the standard game layout. This was done to avoid having to handle every separat case manually, since these tabs are dynamic
- Research and civic chooser tooltips now identify the technologies or civics they lead to.
- Reading the selected city or unit summary using the key binding (tilde by default) speaks its direction from the navigation cursor first, followed by the summary.
- Control f to open the search panel executes on key-down, same as all other input bindings
- Documented the search panel and type ahead in the readme

### Fixed

- Fixed an issue with mod sounds no longer playing after the computer wakes from sleep
- Map-tac buttons in the chat history now move the navigation cursor to the tac, and chat entries for map tacs retain their location for message-buffer jumping.
- Selected-city yield information no longer repeats each yield name before its per-turn value.
- Natural wonder, city-state, and leader pickers in create game report and toggle checkbox state correctly.
- The City State Picker count slider now uses the available range and current count, instead of setting current to 0 and max range to 100.
- Fixed the label for the map selection filter dropdown
- Religion belief counts and locked slots now follow the active game's Religion Screen instead of always assuming four slots.
- Made tech and civic boost popups report 100% and say the item was completed when a boost finishes it, instead of reporting that progress fell to 0%.
- Policies can now be viewed, selected, replaced, and removed properly from the Government screen in the Black Death scenario.
- Diplomacy and deal screens remain navigable when an advisor message appears while they are open.
- Input help now identifies the Delete shortcut for removing an AI player in Advanced Setup and Scenario Setup.
- Create game now shows Map Type in the Basic view and opens the full map-selection screen from both Basic and Advanced views. Setup options expose their specific invalid-reason explanations, AI leader changes reset incompatible alternate colors, unavailable sections and choices stay hidden or disabled, and options removed by a configuration refresh no longer remain in the CAI list.
- Fixed unit and city ownership labels so that they use the civilization's defined adjective and fall back to its localized name when the adjective is missing, in order to account for raw localization tags in Outback Tycoon and other scenarios.
- Fixed the unit panel failing to load in scenarios that remove unit-operation definitions, including the Alexander scenario. This caused a bug where you couldn't cycle units, or read their info
- Fixed certain UI widgets trapping navigation input if they are disabled
- Fixed an issue with the search pannel, where typed character echo interrupted the search result speech
- Search panels no longer move focus when a search has no results. An empty search now displays `Type text to search` instead of `No results`.

## [0.6.0] - 2026-07-15

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

## [0.5.0] - 2026-07-13

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

## [0.4.0] - 2026-07-12

### Changed

- English display-language speech now simplifies accented Latin letters and ligatures so names with unsupported characters remain readable.

### Added

- The World Scanner Terrain category now includes all hidden tiles under the new Unexplored sub-category.

### Fixed

- World Scanner item navigation now plays the wrapping sound when crossing the first or last item.
- Optimized the scanner so that it performs better on bigger maps

## [0.3.0] - 2026-07-12

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

## [0.2.0] - 2026-07-12

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
