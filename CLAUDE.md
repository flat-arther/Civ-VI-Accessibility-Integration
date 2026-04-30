## Project Overview

Civilization VI accessibility mod (CAI). It adds TTS and screen-reader navigation for blind players through Lua UI replacements and wrappers.

User:

- Blind screen-reader user.
- Experienced programmer/modder.
- User directs; Claude codes and explains.
- If uncertain, ask briefly, then act.
- Do not use `|` tables in responses.

## Session Start

New project / greeting / "hallo":

1. Read `docs/setup-guide.md`.
2. Run the setup interview.
3. Use `winget` and CLI tools for installations where possible.

Continuing / "weiter":

1. Read `project_status.md`.
2. If it lists pending tests or user-result questions, ask for those results before continuing.
3. Suggest next steps from `project_status.md` or ask what to work on.

Always treat `project_status.md` as the central working memory. Update it after meaningful progress and before ending a session.

## Environment

- OS: Windows. Use PowerShell or cmd. Do not use Unix shell commands.
- Game directory: `C:\Program Files (x86)\Steam\steamapps\common\Sid-Meiers-Civilization-VI`
- Architecture: 64-bit.
- Mod loader: none. The project uses Civ VI's built-in Lua mod system through `.modinfo`.
- Deploy model: `src/` is symlinked into the game's mod folder; no copy/deploy step is normally needed.

## Startup Gate Before Coding

Before implementation work:

1. Read `project_status.md` for current focus, pending tests, and known gaps.
2. Check `docs/game-api.md` for documented Civ VI APIs, safe keys, and discovered screen patterns.
3. If key bindings or input actions are involved, confirm the key/action is documented under safe mod keys or existing action patterns in `docs/game-api.md`.
4. Check `docs/Civ6Docs.md` for known Civ VI keys, methods, and patterns.
5. Verify uncertain game behavior against actual Lua under `decompiled/` or the Steam install. Do not guess class, method, event, or control names.
6. For files over 500 lines, use targeted search first instead of reading the whole file.
7. Look in the docs/Civ6 IDE helpers for Lua annotations when signatures or globals are unclear.

If `project_status.md` says a user test is pending, ask for that result before layering more code on the same area.

## Coding Rules

- Logs and code comments are English.
- All user-facing strings must be localized.
- Prefer existing control text and tooltips through `control:GetText()` and `control:GetToolTipString()`.
- Use `Locale.Lookup()` when no existing control exposes the text or for CAI-specific localization tags.
- TTS output must always go through `Speak()` in `caiUtils.lua`; never call `CAI.output` directly.
- Work with vanilla game mechanics. Preserve vanilla callbacks, events, input contexts, dialogs, and state changes where possible.
- Do not override vanilla game keys casually. Use safe mod keys or bindable input actions.
- Cache references or ids, not displayed values. Always read live data before speaking or rendering state.
- Null checks should log and announce rather than fail silently.
- Normal Lua code should use explicit nil checks. Reserve try/catch-style protection for reflection/external calls such as Tolk or changing external APIs.
- Debug logging should remain cheap when debug mode is off.

## Accessibility Widget Rules

- Do not wire widgets one by one for list/grid rows. Wrap the vanilla init/populate function where controls/items are created and attach accessibility there.
- Reference patterns: `src/UI/frontEnd/LeaderPicker.lua` and `src/UI/frontEnd/CityStatePicker.lua`.
- Hidden vanilla controls may still have CAI widgets, but navigation must skip them through live `IsHidden` checks.
- Disabled vanilla controls should remain readable when useful, but activation must honor live disabled state.
- Tree expand/collapse behavior belongs in the shared `Treeview` template. Screens should add only screen-specific activation logic.
- Pushed transient trees/lists should usually inherit current stack priority and close cleanly through `UIScreenManager`.
- Prefer hotkey/read-on-demand access for ambient HUD panels instead of persistent mirrored widgets.
- Do not expose stale focus after rebuilds. Preserve focus by stable ids, child index, or tree path when that matches the vanilla interaction.

## Firm Project Decisions / Traps

- Civ VI UI Lua does not reliably expose included local functions through `_G`; wrap direct function names immediately after `include(...)` when possible.
- Prefer live vanilla control state for visibility, disabled checks, labels, and tooltips.
- End-turn-blocking notifications belong with ActionPanel accessibility, not the notification center, because vanilla does not create rail instances for them.
- Notification activation should preserve vanilla by calling `pNotification:Activate(true)` when valid.
- Notification dismissal should call `NotificationManager.Dismiss(playerID, notificationID)` only when `CanUserDismiss()` is true.
- ProductionPanel queue rows are dummy CAI buttons, not checkboxes; vanilla queue selection is a single-item pick-up mode.
- ProductionManager / multi-queue is a separate UI context and still needs its own accessibility work.
- ResearchChooser should not add custom Shift+Enter queueing; keep queue/current research read-only and inspectable.
- GovernmentScreen CAI exposes Policies and Governments only; vanilla My Government opens map to Policies.
- Government policy movement shortcuts are intentionally not exposed. Use slot picker/replace/remove flows instead.
- LoadScreen accessibility must preserve `OnActivateButtonClicked()` as the continue path and must not force progress before load completion.

## Documentation Rules

- After new code analysis or discovered Civ VI behavior, update `docs/game-api.md` immediately.
- Keep `project_status.md` compact: current focus, pending tests, next steps, durable decisions, and compressed history only.
- Do not let `project_status.md` become a chronological scratch log again.
- Put long API findings in `docs/game-api.md`, not in `project_status.md`.

## Coding Principles

- Playability: work with menus, navigation, controls, and game mechanics. Build custom UI only when the game has no usable equivalent.
- Modular: separate input, UI, announcements, and game-state helpers.
- Maintainable: follow existing CAI patterns and keep naming consistent.
- Efficient: avoid unnecessary rebuilds and duplicate speech.
- Robust: handle edge cases, rapid key presses, modal dialogs, tutorial gating, and local-player changes.
- Submission-quality: keep code clean enough for dev integration, with meaningful names and no undocumented hacks.

Patterns: `docs/ACCESSIBILITY_MODDING_GUIDE.md`

## Session Management

- If a feature is done, the conversation is long, or context is getting heavy, update `project_status.md` and suggest a new conversation.
- If a problem persists after three attempts, stop, explain what was tried, suggest alternatives, and ask the user how to proceed.
- Before ending, summarize what changed, what was verified, and what still needs user/game testing.

## References

- `project_status.md`: current working memory and pending tests.
- `docs/game-api.md`: Civ VI API discoveries, safe keys, screen patterns, and firm implementation notes.
- `docs/ACCESSIBILITY_MODDING_GUIDE.md`: CAI implementation patterns.
- `docs/setup-guide.md`: project setup flow.
- `templates/`: reusable code templates.
- `scripts/`: build/helper scripts.
