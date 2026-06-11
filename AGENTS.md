## Project Overview

Civilization VI accessibility mod (CAI). It adds TTS and screen-reader navigation for blind players through Lua UI replacements and wrappers.

User:

- Blind screen-reader user.
- Experienced programmer/modder.
- User directs; Codex codes and explains.
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

## File Creation Rules

- **In-game screens** are partial replacements. Create a file named `{OriginalName}_CAI.lua`. At the top, include the base file conditionally: if the original has DLC replacements, include those with `if IsExpansion2Active() then include("X_Expansion2") elseif IsExpansion1Active() then include("X_Expansion1") else include("X") end`. Register the file in `CivViAccess.modinfo` as a `<ReplaceUIScript>` with `<LuaContext>` matching the vanilla context name and `<LuaReplace>` pointing to the new file.
- **Front-end or shared UI** (main menu, options menu) are full replacements. Copy the vanilla file into the mod, then add accessibility code directly before the `Initialize()` call at the end, between `--#Accessibility integration` and `--#End of accessibility integration` comments.
- Every new CAI screen file must be added to both the top-level `<File>` list (which registers it on the VFS) and as a `<ReplaceUIScript>` entry in `src/CivViAccess.modinfo` or it will not load. The top-level `<File>` list is separate from `<ImportFiles>` — even `<ReplaceUIScript>` files need a top-level `<File>` entry.
- If the original vanilla file uses a wildcard-style `include()` (e.g. `include("FileName")`  resolved at runtime from any loaded context), the CAI file must also be added to the `<ImportFiles>` section under `<ImportFiles id="CAIInGame">` in addition to the `<File>` list. This makes it available for wildcard resolution.

## Coding Rules

- Logs and code comments are English.
- All user-facing strings must be localized. Never use literal strings for user-facing text; only debug prints may use literals.
- Prefer existing control text and tooltips through `control:GetText()` and `control:GetToolTipString()`.
- Use `Locale.Lookup()` when no existing control exposes the text or for CAI-specific localization tags. Add new `LOC_CAI_` tags to `src/Text/en_US/cai_text_ui.xml` when vanilla has no suitable key.
- TTS output must always go through `Speak()` in `caiUtils.lua`; never call `CAI.output` directly.
- Work with vanilla game mechanics. Preserve vanilla callbacks, events, input contexts, dialogs, and state changes where possible.
- Do not override vanilla game keys casually. Use safe mod keys or bindable input actions.
- Cache references or ids, not displayed values. Always read live data before speaking or rendering state.
- Use defensive nil handling only where nil is an expected, legitimate state: public API boundaries, real lookup misses, or early-show `Controls.X` timing.
- Do not add broad chained guards or silent empty returns for private/internal code. If something that should exist is nil, let it crash so the error reaches `Lua.log`.
- When nil is expected, log or announce clearly instead of failing silently.
- Reserve try/catch-style protection for reflection/external calls such as Tolk or changing external APIs.
- Debug logging should remain cheap when debug mode is off.

## Accessibility Widget Rules

The UI manager is a class-based widget framework rebuilt on the `UIManagerRework` branch. `docs/ui-manager.md` is the source of truth; `src/ideHelpers.lua` carries the LuaLS annotations. Use the framework primitives below — do not fall back to the old template/single-callback patterns.

- Create widgets through `mgr:CreateWidget(id, type, props)`. The full type catalog is in `docs/ui-manager.md` section 2.
- Attach behavior with the event system: `w:On("activate", fn)`, `w:On("value_changed", fn)`, `w:On("focus_enter", fn)`. Never assign `OnClick`/`OnFocusEnter`/`OnCommit` as fields.
- Pre-position focus on push with `mgr:Push(w, { focus = childOrKey })`. Never write `widget.FocusedChild = ...` or call `widget:SetFocusedChild(N)`.
- For lists/trees/rows that rebuild from game state, set `FocusKey` on each rebuilt row and wrap the rebuild with `mgr:CaptureFocusKey(root)` / `mgr:RestoreFocus(root, capture)`. Do not reinvent the capture-and-restore dance per screen.
- For tabs, use `TabControl:AddPage(labelOrFn)` — never toggle `IsHidden` on sibling containers to fake tab swaps.
- For dialogs, use `Dialog:SetButtons(buttons, defaultIndex)` or `CAIWidgetHelpers_DialogBuilder.MakeGeneralDialog`. The button row is `Transparent` and gets Left/Right + Up/Down sticky navigation automatically.
- Do not wire widgets one by one for list/grid rows. Wrap the vanilla init/populate function where controls/items are created and attach accessibility there.
- Hidden vanilla controls may still have CAI widgets, but navigation must skip them through live `IsHidden` checks (manager honors `IsHidden` during input bubble and child resolution).
- Disabled vanilla controls should remain readable when useful, but activation must honor live disabled state (`Button:Activate` no-ops when `IsDisabled()` is true).
- Tree expand/collapse behavior belongs in `TreeWidget` / `TreeItemWidget`. Screens add only screen-specific activation by attaching an `activate` listener on leaf items.
- Pushed transient trees/lists should inherit current stack priority and close cleanly through the manager (`mgr:Pop`, `mgr:RemoveFromStack`).
- Prefer hotkey/read-on-demand access for ambient HUD panels instead of persistent mirrored widgets.
- For out-of-band re-speak after a game event updates focused data, call `mgr:Refocus()` or `widget:Announce({ "value" })`. Do not call `Speak()` directly for focus-driven output.

## Firm Project Decisions / Traps

- The `UIManagerRework` branch is a no-back-compat rewrite of the UI manager. The four old files (`baseWidget.lua`, `widgetTemplates.lua`, `widgetTemplateHelpers.lua`, `UIScreenManager.lua`) are deleted. All widget files now live under `src/UI/uiManager/` with the `CAIWidget_` / `CAIUIScreenManager` / `CAIWidgetHelpers_` prefix (Civ VI VFS collision avoidance). Screens still on the old API will not load until migrated per `docs/ui-manager.md` section 16.
- The Manager owns focus as `Manager.CurrentPath`. Direction is threaded through `SetFocus(widget, { direction = ±1 })` for Windows tab-stop semantics; programmatic focus omits direction and uses `_lastFocusedKey` / `_lastFocusedChild` cache.
- Speech is one TTS line per widget (Windows screen-reader model). Multi-line announcements route through `SpeakLines(lines, interrupt)` where only the first line interrupts.
- A disposable test screen lives at `src/UI/test/CAITestScreen.lua` and fires via `LuaEvents.CAITest_Open/Close/Rebuild/Refocus`. Delete once the first real screen has been migrated and verified in-game.
- Civ VI UI Lua does not reliably expose included local functions through `_G`; wrap direct function names immediately after `include(...)` when possible.
- Prefer live vanilla control state for visibility, disabled checks, labels, and tooltips.
- End-turn-blocking notifications belong with ActionPanel accessibility, not the notification center, because vanilla does not create rail instances for them.
- Notification activation should preserve vanilla by calling `pNotification:Activate(true)` when valid.
- Notification dismissal should call `NotificationManager.Dismiss(playerID, notificationID)` only when `CanUserDismiss()` is true.
- ProductionPanel queue rows are dummy CAI buttons, not checkboxes; vanilla queue selection is a single-item pick-up mode.
- ProductionManager / multi-queue is a separate UI context and still needs its own accessibility work.
- ResearchChooser should not add custom Shift+Enter queueing; keep queue/current research read-only and inspectable.
- GovernmentScreen CAI exposes Governments and Policies only (Governments is tab 1, Policies is tab 2); vanilla screen enums 1 (My Government) and 2 (Governments) open to the Governments tab, enum 3 (Policies) opens to the Policies tab. Accepting a government change auto-switches to the Policies tab.
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
- `docs/ui-manager.md`: source of truth for the class-based UI manager rework (architecture, focus, speech, events, widgets, migration guide). Consult this before any UI manager or widget work.
- `src/ideHelpers.lua`: LuaLS annotations for every widget class, manager method, event name, and helper module. Use for autocomplete and signature checks.
- `docs/game-api.md`: Civ VI API discoveries, safe keys, screen patterns, and firm implementation notes.
- `docs/ACCESSIBILITY_MODDING_GUIDE.md`: CAI implementation patterns.
- `docs/setup-guide.md`: project setup flow.
- `templates/`: reusable code templates.
- `scripts/`: build/helper scripts.
