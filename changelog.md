# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [0.1.2] - 2026-07-12

### Added
- Movement cursor information now reports the selected unit's total movement cost and, when nonzero, movement remaining on arrival. It respects all known movement rules.

### Changed

- Each city in the World Scanner is now a separate entry when navigating groups, while cities remain divided by relationship subcategory.
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
