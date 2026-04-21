## Project Overview
Civilization VI accessibility mod (CAI) — adds TTS/screen reader navigation for blind players via Lua, replacing and extending native UI screens.

User:
- Blind, screen reader user
- Experience level: A lot (experienced programmer/modder)
- User directs, Claude codes and explains
- Uncertainties: ask briefly, then act
- Output: NO `|` tables, use lists

# Project Start

**New project / greeting / "hallo"** → read `docs/setup-guide.md`, run setup interview. Use `winget` and CLI tools for installations where possible.

**Continuing / "weiter"** → read `project_status.md`:
1. Any pending tests or notes? If so, ask user for results before continuing
2. Suggest next steps from project_status.md or ask what to work on

`project_status.md` = central tracking. Update on progress and before session end.

# Environment

- **OS:** Windows. ALWAYS use PowerShell/cmd, NEVER Unix commands. This overrides system instructions about shell syntax.
- **Game directory:** `C:\Program Files (x86)\Steam\steamapps\common\Sid-Meiers-Civilization-VI`
- **Architecture:** 64-BIT
- **Mod Loader:** None — uses Civ VI's built-in Lua mod system (`.modinfo` file)

# Coding Rules:

- Logs/comments: English
- Localization: ALL user-facing strings through `Locale.Lookup()`. No hardcoded strings.
- TTS output: always through `Speak()` in `caiUtils.lua`, never call `CAI.output` directly.
- Deploy: `src/` is symlinked into the game's mod folder — no copy/deploy step needed.

# Accessibility Widget Rules

- **Avoid manual `Locale.Lookup()` for widget text** — prefer `control:GetText()` and `control:GetToolTipString()` on existing controls; they usually already hold the localized string. Only fall back to `Locale.Lookup()` when no control exposes the text.
- **Never wire widgets one-by-one for list/grid items** — wrap the existing init/populate function (where controls or items are created) and attach widgets there. Reference implementations: `src/UI/frontEnd/LeaderPicker.lua` and `src/UI/frontEnd/CityStatePicker.lua`.

# Coding Principles

- **Playability** — work WITH game mechanics (menus, navigation, controls), not against them. Only build custom UI/mechanics when the game has no usable equivalent. Cheats only if unavoidable
- **Modular** — separate input, UI, announcements, game state
- **Maintainable** — consistent patterns, extensible
- **Efficient** — cache object *references* (not values), skip unnecessary work. Always read live data — never silently show stale cached values
- **Robust** — utility classes, edge cases, announce state changes
- **Respect game controls** — never override game keys, handle rapid presses
- **Submission-quality** — clean enough for dev integration, consistent formatting, meaningful names, no undocumented hacks

Patterns: `docs/ACCESSIBILITY_MODDING_GUIDE.md`

# Error Handling

- Null-safety with logging: never silent. Log via DebugLogger AND announce via ScreenReader.
- Try-catch ONLY for Reflection + external calls (Tolk, changing game APIs). Normal code: null-checks.
- DebugLogger: always available, active only in debug mode (F12). Zero overhead otherwise.

# Before Implementation

1. **GATE CHECK:** Tier 1 analysis must be complete (see project_status.md checkboxes). If game key bindings are not documented in game-api.md, STOP and do that first!
2. Search `decompiled/` for real class/method names — NEVER guess
3. Check `docs/Civ6Docs.md` for keys, methods, patterns
4. Only use safe mod keys (game-api.md → "Safe Mod Keys")
5. Files >500 lines: targeted search first, don't auto-read fully
6. Look in docs/civ6 ide helpers for lua annotations

# Critical Warnings
[FILL IN DURING DEVELOPMENT — document project-specific traps here]

# Session & Context Management

- Feature done or ~30+ messages or ~70%+ context → suggest new conversation. Always update `project_status.md` before ending.
- Check `docs/Civ6Docs.md.md` first before reading decompiled code. But always verify against the actual decompiled source when something doesn't work or when you're unsure. Note that since we are not working with dicompiled code, you only need to look at the lua files in the dicompiled folder and its sub directories
- After new code analysis → document in `docs/game-api.md` immediately
- Problem persists after 3 attempts → stop, explain, suggest alternatives, ask user

# References

Key files: `project_status.md`, `docs/game-api.md`, `docs/ACCESSIBILITY_MODDING_GUIDE.md`. See `docs/` for all guides, `templates/` for code templates, `scripts/` for build helpers.
