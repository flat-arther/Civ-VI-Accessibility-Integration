# Civilization VI Accessibility Integration

## Introduction

Civilization VI Accessibility Integration makes Sid Meier's Civilization VI playable with a screen reader. It adds spoken information and keyboard navigation to the game's menus, dialogs, screens, and other user-interface elements.

The mod supports all three standard rulesets: the base game, Rise and Fall, and Gathering Storm. It also supports the Conquests of Alexander, Outback Tycoon, and Black Death scenarios; other scenarios remain unsupported or untested.

## Installing the mod

1. Copy the included `binaries` folder into the Civilization VI installation folder.

   Steam's default installation folder is:

   `C:\Program Files (x86)\Steam\steamapps\common\Sid Meier's Civilization VI`

   Epic Games' default installation folder is:

   `C:\Program Files\Epic Games\SidMeiersCivilizationVI`

2. Copy the `CivVi-Accessibility-Integration` folder into:

   `%USERPROFILE%\Documents\My Games\Sid Meier's Civilization VI\Mods`. Note that sometimes the documents folder is in one drive

   If the `Sid Meier's Civilization VI` folder does not exist, launch the game once and then close it.

3. Launch Civilization VI. The mod is enabled automatically.

## Using the UI

The accessible interface is made from nested widgets. A screen is usually a panel containing several containers, such as a list of actions, a tree of information, and a row of buttons. Those containers may themselves contain other containers. For example, a panel may contain a tree, the tree may contain ceveral items, similar to a tipical windows treeview

Focus follows this nesting. Moving between the major parts of a screen changes the focused container; moving inside that container changes its focused item. Your screen reader announces the parts of the path that change, followed by the focused item's role, state, value, help text, and position when available. You may disable some of these from mod settings. Press `Shift+F2` whenever you want to hear the complete path from the screen down to the current item.

Press `Ctrl+H` to open a reference of the shortcuts available on the current screen. It includes both standard widget commands and screen-specific commands.

### Common shortcuts

These shortcuts are available from all accessible widgets unless the current screen uses the key for another purpose.

- `Ctrl+H` — open the shortcut reference for the current screen
- `Shift+F1` — read only the shortcuts available on the focused widget
- `Shift+F2` — read the complete focus path
- `F12` — open the accessibility settings
- `Ctrl+I` — look up the focused item in the Civilopedia; available during a game, but not from the main menu or its child screens
- `Alt+Up` / `Alt+Down` — read the previous or next section of the focused item's help text; useful when an item and its description contain a lot of information
- `Alt+Home` / `Alt+End` — read the first or last section of the focused item's help text
- `Ctrl+F` — search the current container when it supports search

### Container navigation

#### Panels

Panels arrange the major controls and sections of a screen.

- `Tab` / `Shift+Tab` — next / previous control or section

#### Dialogs

Dialogs are temporary panels that ask for a choice or display a message.

- `Tab` / `Shift+Tab` — next / previous row
- `Up` / `Down` — previous / next row
- `Enter` — activate the default button, usually ok / continue, even when not focused


#### Lists

Lists contain a single vertical sequence of items.

- `Up` / `Down` — previous / next item; wraps with a click sound at the top and bottom
- `Home` / `End` — first / last item
- `Page Up` / `Page Down` — move backward / forward by several items
- `Ctrl+F` — open list search
- Typing text — use type-to-find to move to a matching item



#### Submenus

A submenu is an item that contains another list of choices.

- `Enter` / `Right Arrow` — expand the submenu and enter it
- `Left Arrow` — collapse the submenu or return to its parent


#### Treeviews

Treeviews organize information into branches and child items. Unlike lists, tree navigation stops at the first and last item instead of wrapping.

- `Up` / `Down` — previous / next visible item
- `Right Arrow` — expand a branch, or move into its children if already expanded
- `Left Arrow` — collapse a branch, or move to its parent if already collapsed
- `Enter` — expand or collapse a branch; activate a selectable item with no children
- `Home` / `End` — first / last visible item
- `Page Up` / `Page Down` — move backward / forward by several visible items
- Typing text — use type-to-find to move to a matching item
- `Ctrl+F` — open tree search. 

#### Dropdowns

A dropdown is a collapsed list used to choose one value.

- `Enter` — open the dropdown
- `Up` / `Down`, `Home` / `End`, and `Page Up` / `Page Down` — navigate the open list
- `Enter` on an option — select it and close the dropdown
- `Escape` — close without changing the value

#### Tabs

Tabs divide a screen into pages.

- `Left` / `Right` on the tab strip — previous / next page; wraps with a click sound at the first and last page
- `Ctrl+Tab` / `Ctrl+Shift+Tab` — next / previous page from anywhere in the tab control; also wraps with a click sound
- `Tab` / `Shift+Tab` — next previous control; also wraps with a click sound

#### Tables

Tables arrange items vertically and horizontally. They do not wrap at their boundaries.

- `Up` / `Down` — previous / next item in the current vertical tier
- `Left` / `Right` — previous / next tier
- `Home` / `End` — first / last item in the current tier
- `Ctrl+Left` / `Ctrl+Right` — previous / next column
- `Ctrl+Home` / `Ctrl+End` — first / last item in the entire table

### Activation and values

After navigating to an item, its role tells you how it behaves.

- **Button** — `Enter` or `Space` activates it.
- **Checkbox** — `Enter` or `Space` switches it on or off.
- **Slider** — `Left` / `Right` decreases / increases the value; `Page Up` / `Page Down` makes a larger change; `Home` / `End` sets the minimum / maximum.
- **Edit box** — some fields accept typing immediately. In other fields, `Enter` begins editing and a second `Enter` commits. On focus, a hint will tell you whether you have to activate an edit box to type in it. `Escape` cancels the edit. Standard text editing, selection, and copy shortcuts are supported. Read-only edit boxes allow text navigation and copying but cannot be changed.
- **Static text** — provides information and has no action. Appears in dialog body text mostly

Disabled controls remain in navigation when their information may be useful. The screen reader announces that they are unavailable, and activation has no effect.

### Type-to-find search

Type-to-find provides quick navigation in lists and treeviews without opening a separate search panel. It searches item names without regard to capitalization and supports exact words, word beginnings, text found anywhere in a name, and prefixes for consecutive words. For example, `war mon` matches `Warrior Monk`, and `monk` can also find `Warrior Monk`.

- More direct matches are preferred over broader partial or multi-word-prefix matches.
- In a treeview, type-to-find can locate an item inside collapsed branches and reveal its path.
- Repeating the same single character cycles through matching items and wraps from the last match to the first.
- Hidden items are skipped. Disabled items may still be found when their information is useful.
- If nothing matches, `No match` is announced and the search text remains available for correction.
- `Backspace` removes the last character from the current search text.
- `Escape` clears the current search text.
- The Search timeout option under accessibility settings controls how long search text remains active. Set it to `0` to keep the text until you clear it.

### Search panel

Press `Ctrl+F` in a supported container to open its search panel. Lists and treeviews support it by default, and some screens provide searches covering additional content. Search results update as the query changes and may include labels, descriptive text, and screen-specific information.

- Enter multiple terms to find items matching all of them. Note: the civilopedia screen matches by full query instead of single terms. This is necessary to provide full search, which allows you to lookup any text that appears in the body of an artical.
- Prefix a term with `--` to exclude matching items. For example, `warrior --monk` finds results matching `warrior` but excludes results matching `monk`. Note: term exclusion does not work in the civilopedia for the reason mentioned above.
- Use `Tab` and `Shift+Tab` to move between the search edit box and results.
- Use normal list-navigation commands to review results.
- Typing or pressing `Backspace` while reviewing results continues editing the search query.
- Press `Enter` from the edit box to activate the first result.
- Press `Enter` on a result to activate it, open it, or move focus to the matching item. In map search, pressing enter on a result moves the navigation cursor to that tile.
- Use `Page Up` and `Page Down` from the edit box to review up to ten recent searches whose result you activated.
- Press `Escape` to close the search panel.
- The Auto focus first search result option under accessibility settings controls whether the first matching result receives focus automatically.

## Gameplay

Civilization VI uses a hexagonal map. Each tile has six neighbors: northwest, northeast, west, east, southwest, and southeast. The accessibility mod therefore uses six movement keys rather than the four directions used on a square grid.

The navigation cursor, Surveyor, and World Scanner work similarly to their equivalents in the Civilization V accessibility mod. Together, they let you explore individual tiles, summarize an area, or find known objects anywhere on the map.

### Navigation cursor

The navigation cursor is an independent map cursor used to explore the world without changing the selected unit or city. Moving it announces the most important information about the new tile. Additional commands read specific kinds of information under the cursor.

#### Moving the cursor

- `Q` or `Numpad 7` — move northwest
- `E` or `Numpad 9` — move northeast
- `A` or `Numpad 4` — move west
- `D` or `Numpad 6` — move east
- `Z` or `Numpad 1` — move southwest
- `C` or `Numpad 3` — move southeast
- `/` — jump the cursor to the selected unit or selected city. When a game begins with nothing selected, the cursor starts at your capital when possible.
- `Ctrl+S` — jump the cursor to your capital city
- `M` — place or edit a map tac at the cursor

#### Reading the current tile

- `S` or `Numpad 5` — read units on the tile
- `W` or `Numpad 8` — read yields, workers, fresh water, and ownership
- `X` or `Numpad 2` — read contamination, movement cost, defense modifier, and appeal
- `Shift+S` or `Shift+Numpad 5` — read coordinates relative to your original capital
- `B` — read geography, including routes, lowlands, volcanoes, disasters, continents, territory, cliffs, rivers, and national parks, followed by districts, buildings, and great works
- `Space` — read information for the current interface target, especially during movement, combat previews, city management, and placement modes
- `Enter` — perform the primary action at the cursor in the current interface mode
- `Ctrl+Enter` — perform the secondary action at the cursor when one is available. This is mainly used in the city management interface, to swap ownership for tiles. The mod announces when this is possible

#### Reading city, district, barbarian and industry banners

When the cursor is on a city or district banner, the number row reads sections of the visible banner information. Some sections are available only in rulesets that use that system. 

- `1` — identity and status, such as the city or district name and health. This also works with banners for barbarian clans, industries and corporations if those modes are enabled. Applicable for when the mod mentions a barbarian clan, industry or corporation under the cursor.
- `2` — city growth and production
- `3` — religion
- `4` — diplomacy, such as ownership, city-state quests, and trading-post status
- `5` — loyalty percentage and breakdown, does not work in the standard ruleset
- `6` — governor information, does not work in the standard ruleset
- `7` — power information, only works in the gathering storm ruleset

### Surveyor

The Surveyor summarizes a circular area centered on the navigation cursor. Its radius can be set from one to five tiles. It reports only information your player is allowed to know; unexplored or hidden information is not revealed.

- `Shift+W` — increase the Surveyor radius
- `Shift+X` — decrease the Surveyor radius
- `Shift+Q` — read the total yields within the radius
- `Shift+A` — read visible resources within the radius
- `Shift+Z` — read revealed terrain within the radius
- `Shift+E` — read friendly units within the radius
- `Shift+D` — read visible enemy units within the radius
- `Shift+C` — read known cities and barbarian outposts within the radius
- `Ctrl+Shift+A` / `Ctrl+Shift+Numpad 4` — count improvements within the radius
- `Ctrl+Shift+D` / `Ctrl+Shift+Numpad 6` — read visible neutral units within the radius
- `Ctrl+Shift+Z` / `Ctrl+Shift+Numpad 1` — count tile ownership within the radius
- `Ctrl+Shift+Q` / `Ctrl+Shift+Numpad 7` — count districts within the radius

### World Scanner

The World Scanner finds known objects across the map without requiring you to inspect every tile. Results are organized into four levels: category, subcategory, group, and item. Categories cover information such as cities, units, resources, terrain, districts, wonders, improvements, valid targets, and other known map objects. Empty categories are skipped.

Moving through the Scanner reads the current result and its direction and distance from the navigation cursor. Category, subcategory, group, and item navigation wraps with a click sound. 

- `Ctrl+Page Up` / `Ctrl+Page Down` — previous / next category
- `Shift+Page Up` / `Shift+Page Down` — previous / next subcategory
- `Page Up` / `Page Down` — previous / next group
- `Alt+Page Up` / `Alt+Page Down` — previous / next item
- `Home` — move the navigation cursor to the current Scanner item or group
- `Backspace` — return the navigation cursor to its position before the last Scanner jump
- `End` — read the direction from the navigation cursor to the current Scanner item
- `Ctrl+F` — search across all Scanner categories

### Lenses

Lenses are a native Civilization VI system that highlights map information such as appeal, religion, loyalty, government, and settler suitability. Press `Ctrl+J` to open the lens list, then activate the lens you want. Some lenses turn on automatically during relevant game actions, such as selecting certain units.

While a lens is active, the mod includes additional lens-specific information in navigation-cursor speech. The World Scanner also adds an Active Lens category containing the objects highlighted by that lens.

### Map tacs

Map tacs are Civilization VI's native system for placing labeled markers on the map. The mod speaks tacs as part of the navigation cursor's tile information and provides a Map Tacs category in the World Scanner. You may also asign map tacs to bookmark slots for quick navigation.

There are ten bookmark slots, numbered 1 through 10, and each populated slot stores one of your map tacs. The slot mapping is stored in the player configuration, so bookmarks belong to the current player and save.

Assigning a bookmark on a tile that already contains one of your map tacs uses that tac and renames it to `Bookmark 1`, `Bookmark 2`, and so on. If the tile has no map tac owned by you, the mod creates one. Reassigning a populated slot deletes the map tac previously stored in that slot. Assigning the same map tac to another slot clears its former slot, so one tac cannot represent two bookmarks. If a bookmarked tac is deleted manually, its slot is treated as empty the next time it is used.

- `M` — place a new map tac at the navigation cursor, or edit the existing tac at that location
- `Ctrl+M` — open or close the list of available map tacs. Press enter on a map tac in the list to jump cursor to it.
- `Ctrl+Shift+1` through `Ctrl+Shift+0` — assign Bookmark 1 through Bookmark 10 at the navigation cursor. An existing owned map tac is renamed and assigned; otherwise a new one is created. Reassigning a slot deletes its previous map tac.
- `Ctrl+1` through `Ctrl+0` — jump the navigation cursor to Bookmark 1 through Bookmark 10.
- `Alt+1` through `Alt+0` — read the direction from the navigation cursor to Bookmark 1 through Bookmark 10.

### Empire information

Empire information commands read important totals and progress without opening the corresponding game screen. The information available depends on the active ruleset and on what's currently unlocked in your game. Most of these can be found in various screens

#### Time, research, and culture

- `T` — read the current turn, time, and date, plus the turn timer when one is active
- `R` — read science per turn and progress on the technology currently being researched
- `P` — read culture per turn and progress on the civic currently being researched
- `Y` — read era score, the current age, thresholds for the next age, and active commemorations

#### Treasury, yields, and resources

- `G` — read the current gold balance, gold per turn, and trade-route capacity
- `F` — read the current faith balance and faith per turn
- `I` — read tourism per turn
- `Ctrl+Y` — open the yields and strategic resources tree. Its two categories provide detailed empire-wide information for science, culture, gold, faith, tourism, diplomatic favor, envoys, influence points, other available top-panel yields, and strategic-resource stockpiles and flow.

#### Diplomacy and government

- `V` — read available envoys, current influence points, and progress toward the next envoy
- `K` — read diplomatic favor yield and World Congress information, such as the number of turns until the next session
- `O` — read available and spent governor titles
- `N` — read the number of nuclear and thermonuclear devices owned by your empire

### Ending your turn

The Action Panel tracks what must happen before the turn can end. By default, the mod automatically speaks a new action when it changes and announces the waiting message between turns. These two automatic announcements can be controlled independently in the Events settings. An action may be a prompt such as choosing production, selecting research, giving orders to a unit, resolving another turn blocker, or ending the turn.

- `Ctrl+Space` — perform the spoken next action. If the turn is ready, this ends the turn. If something is blocking the turn, it cycles to or opens that required action instead.
- `Shift+Space` — speak the current turn-blocking action or between-turn waiting message on demand.
- `Ctrl+Shift+Space` — open the Turn Blockers list. This lists the current next action and the other distinct actions preventing the turn from ending. Use normal list navigation and activate an entry to go to or resolve that action. Press `Escape` to close the list.

### Notifications and message history

The Notification Center contains the game's current active notifications. The message buffer is a separate history of spoken events, including notifications, discoveries, combat, gossip, movement, and chat. Use the Notification Center when you want to act on a current notification; use the message buffer when you want to review something that was spoken earlier.

#### Notification Center

New notifications are spoken as they arrive. Notifications of the same type are grouped when more than one is active.

- `Ctrl+N` — open the Notification Center and focus the newest notification
- Tree navigation keys — move through notification groups and their entries
- `Enter` or `Space` — activate the focused notification using its normal game action
- `Delete` — dismiss the focused notification when the game allows it; on a group, dismiss all dismissible notifications in that group
- `Escape` — close the Notification Center

#### Message buffer

The message buffer keeps a limited history for the current player. It can show all messages or filter them by notification, discovery, combat, gossip, movement, or chat. Changing category skips categories that currently contain no messages. Visible unit movements record the observed direction path and the unit's last known location, so the location-jump action returns to where that movement was last seen. Navigation settings provide separate movement-announcement dropdowns for your units, teammates, hostile civilizations, neutral civilizations, city-states, and barbarians. Each can announce military units, civilian units, both, or neither; only barbarian movement is enabled by default. These choices affect speech without removing history entries. In hotseat games, collected unit movements are announced only when the observing player's next turn begins.

- `;` — read the previous message in the current category
- `'` — read the next message in the current category
- `Ctrl+;` — read the oldest message in the current category
- `Ctrl+'` — read the newest message in the current category
- `Shift+;` / `Shift+'` — previous / next nonempty message category, then read its newest message
- `Shift+Backslash` — move the navigation cursor to the current message's map location, when the message has one

### World actions

World actions operate on the current selection or on the map without requiring a separate screen.

- `M` — place or edit a map tac at the navigation cursor
- `Ctrl+Space` — end the turn or go to the next turn-blocking action
- `Shift+Space` — speak the current turn blocker or between-turn waiting message
- `Ctrl+Shift+Space` — open the Turn Blockers list

### Selection

In civ vi, selection is not only limited to units. You can have either one city or one unit selected at a time. The selection determines which information and actions are available. Selecting a city replaces the selected unit, and selecting a unit replaces the selected city.

All city, unit, and selection actions are input actions and can be remapped from the game's Key Bindings options tab. Press `Tab` with a city or unit selected to open the actions list for that selection. Most city and unit actions in this list have default bindings. You can discover the available actions and their keys from the list, by pressing `Ctrl+H` while focused in the map area, or from the Key Bindings tab in Options.

#### Selection actions

- `,` / `.` — select the previous / next unit that is ready for orders
- `Shift+,` / `Shift+.` — select the previous / next unit, including units that have no orders remaining
- `[` / `]` — select the previous / next city
- `Backslash` — select your capital city
- `Tab` — open the action list for the selected city or unit

#### Selection information

The grave-accent key, usually located to the left of `1`, reads a short summary of the selected city or unit. `Shift+1` through `Shift+0` read individual information sections.

- `` ` `` — city name, population, health, production, and growth; or the unit summary
- `Shift+1` — city name and health; or unit identity and health
- `Shift+2` — city production; or unit movement
- `Shift+3` — city growth; or unit activity
- `Shift+4` — city border growth; or unit charges
- `Shift+5` — city religion; or unit promotions
- `Shift+6` — city population, housing, and buildings or loyalty; or unit statistics
- `Shift+7` — city yields; or unit abilities
- `Shift+8` — normal city yield-focus entries; or special unit information
- `Shift+9` — favored city yield-focus entries; or the unit's queued path
- `Shift+0` — ignored city yield-focus entries; there is currently no unit readout for this key

### User interfaces

Most accessible game screens are panels whose main body is a tree or list. Use the normal tree or list commands to browse the screen. Some screens also have action buttons outside the main body; use `Tab` and `Shift+Tab` to move between the main tree or list and those buttons.

Screens such as World Rankings, the Production Panel, and World Climate contain multiple tabs. Use `Ctrl+Tab` and `Ctrl+Shift+Tab` to switch to the next or previous tab. When focus is on the tab strip, `Left` and `Right` also switch tabs. The newly selected page becomes the active navigation container.

#### Research, civics, and government

- `Ctrl+R` — open the research chooser
- `Ctrl+C` — open the civics chooser
- `Ctrl+Shift+R` — open the Technology Tree
- `Ctrl+Shift+C` — open the Civics Tree
- `Ctrl+P` — open the Government screen
- `Ctrl+O` — open the Governors screen
- `Ctrl+L` — open the Religion screen

#### Cities and empire management

- `F2` — open Empire Reports
- `Ctrl+V` — open the City-States overview
- `Ctrl+T` — open the Trade Routes overview
- `Ctrl+E` — open the Espionage overview
- `Ctrl+U` — open the list of your units
- `Ctrl+Q` — open Global Resources, showing resource ownership across known civilizations

#### World information

- `F1` — open the Civilopedia
- `F3` — open the Great People screen
- `F7` — open the Great Works screen
- `F8` — open World Rankings
- `F9` — open World Climate
- `F10` — open Era Progress
- `F11` — open Historic Moments
- `F4` — open the Diplomacy Ribbon to browse known leaders and enter diplomacy. Pressing enter on a leader opens the diplomacy screen on them. Here you can see a treeview of leaders, expand each to view information. Tab for the list of actions
- `Ctrl+K` — open the World Congress
- `Ctrl+W` — open the active emergencies and competitions list
- `Ctrl+Shift+T` — open the current tutorial goals

#### Map and communication

- `Ctrl+J` — open the lens list
- `Ctrl+M` — open or close the map-tacs list
- `Ctrl+Shift+F` — open Map Search
- `Ctrl+Slash` — open in-game chat
- `Ctrl+N` — open the Notification Center

## Expectations

Tables: more UIs need tables. Unfortunately, by the time the idea came up, I was too far into development to justify slowing down and redoing previous UIs. This is planned for next.

The Mods and Credits screens are inaccessible. Do not go there.

Do not click the Additional Content button in multiplayer lobbies.

Only Conquests of Alexander, Outback Tycoon, and Black Death are currently supported. Other scenarios, including Red Death and Pirates, are not yet supported.

The tutorial is still not supported currently.

World Builder: don't even ask. It is not important right now, but it might be a fun future project.

## Credits

Civilization VI Accessibility Integration was developed by Flat-Arther and Hamada, with assistance from Claude.

Special thanks to:

- bsg-smoke and Nibar Sito for funding the project.
- Rashad for allowing me to steal ideas from his Civilization V accessibility mod and for answering my numerous questions.
