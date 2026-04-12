# Known Issues & Compatibility Warnings

This file is checked automatically during project setup (Step 4). When the game's engine, Unity version, or mod loader is identified, Claude scans this list and warns the user about any matching issues.

**How to add entries:** Add a new item under the matching category. Include the affected version/component, a short description, and a workaround if one exists.

---

## Unity + MelonLoader

- **Unity 6000.2.2f1**: MelonLoader fails to start. Throws null-reference errors during loader initialization. No workaround known — use BepInEx instead, or wait for a MelonLoader update.
- **Unity 2022.3.62f2**: Crash beim Start während IL2CPP-Initialisierung. BepInEx 6 Bleeding Edge crasht ebenfalls. Kein Fix bekannt. ([GitHub Issue #1063](https://github.com/LavaGang/MelonLoader/issues/1063))
- **Unity 2022.3.58**: UnityDependencies-Download schlägt fehl. **Fix:** MelonLoader auf die neueste Version aktualisieren — die fehlende Version wurde im Dependency-Repo nachgetragen. ([GitHub Issue #936](https://github.com/LavaGang/MelonLoader/issues/936))
- **Unity 5.x**: MelonLoader generally does not support Unity 5. Use BepInEx 5.x instead. See `docs/legacy-unity-modding.md`.
- **Unity 4.x and older**: Neither MelonLoader nor BepInEx work. Only assembly patching is possible. See `docs/legacy-unity-modding.md`.

## Unity + BepInEx

- **Unity 6000+**: BepInEx 5.x does not support Unity 6. BepInEx 6 (bleeding edge) may work but is not stable. Check the BepInEx GitHub for the latest status before proceeding.

## Engine-Specific Issues

_(Add entries here when engine-specific compatibility problems are confirmed.)_

## Game-Specific Issues

_(Add entries here when a specific game has known modding hurdles that aren't covered by the categories above.)_

---

## How Claude Uses This File

During setup (Step 4), after detecting the engine and version:

1. Read this file
2. Check if any entry matches the detected configuration
3. If a match is found: warn the user immediately, explain the issue, and suggest the documented workaround
4. Log the warning in `project_status.md` so it's not forgotten
