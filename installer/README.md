# Civilization VI Accessibility Installer

A small Windows installer for Civilization VI Accessibility Integration.

## Version detection

The installed version is read directly from:

`Documents\My Games\Sid Meier's Civilization VI\Mods\CivVi-Accessibility-Integration\CivViAccess.modinfo`

The installer parses the XML `version` attribute on the root `Mod` element. The installer manifest is used only to remember the selected installation mode and game directory.

Published release versions are also read from `src/CivViAccess.modinfo` at each GitHub release tag, so Git tags are not treated as the authoritative version source.

## Changes since installed version

The installer retrieves published GitHub releases, compares their modinfo versions with the installed modinfo version, and displays the combined release notes for every newer release.

## Build

```powershell
dotnet publish CivVIAccessInstaller.csproj -c Release
```
