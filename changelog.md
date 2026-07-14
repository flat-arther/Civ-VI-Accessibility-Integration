# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

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
