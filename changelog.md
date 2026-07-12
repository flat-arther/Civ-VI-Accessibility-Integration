# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

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
