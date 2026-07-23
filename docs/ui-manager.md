# CAI UI Manager

A class-based widget framework for the CAI accessibility mod. Provides
TTS-friendly focus, navigation, speech, and input handling on top of Civ VI's
Lua UI runtime. This document is the source of truth for the new manager; the
matching LuaLS annotations live in `src/ideHelpers.lua`.

---

## 1. Architecture

The manager has four layers:

1. **Manager** (`CAIUIScreenManager.lua`) — singleton hung off
   `ExposedMembers.CAI_UIManager`. Owns the widget stack, the canonical focus
   path, input dispatch, and speech announcement on focus change.
2. **Base classes** — `UIWidget` → `ContainerWidget` and `ValueWidget`. Real
   class inheritance via metatable chains; not the old template-merging model.
3. **Concrete widgets** — Button, MenuItem, StaticText, Panel, Dialog,
   Dropdown, List, HorizontalList, SubMenu, Tree, TreeItem, Checkbox, Slider,
   EditBox, TabControl, Tab, TabPage, Table, GameView, InterfaceMode. Each is
   one file under `src/UI/uiManager/`.
4. **Helpers** (`src/UI/uiManager/helpers/`) — stateless utilities used by
   widgets and the manager: navigation, search, tree walks, edit-box logic,
   dialog builders.

Construction always goes through the registry. A screen calls
`mgr:CreateWidget(id, type, props)`; the registry looks up the type name and
calls the matching class constructor, which builds a new instance, applies the
props, and returns it.

```lua
local btn = mgr:CreateWidget("Btn_Save", "Button", {
    Label   = function() return Locale.Lookup("LOC_CAI_SAVE") end,
    Tooltip = function() return saveBtn:GetToolTipString() end,
})
btn:On("activate", function() vanillaSaveAction() end)
panel:AddChild(btn)
```

---

## 2. Class hierarchy

```
UIWidget                       identity, tree, events, input, speech
├── ContainerWidget            navigable parent (Ctrl+F search via AllowSearch)
│   ├── PanelWidget
│   │   └── SearchPanelWidget  Ctrl+F overlay (managed singleton)
│   ├── DialogWidget
│   ├── ListWidget             AllowSearch=true by default
│   ├── HorizontalListWidget
│   ├── SubMenuWidget
│   ├── TreeWidget             AllowSearch=true by default
│   ├── TreeItemWidget
│   ├── TabPageWidget
│   ├── TabControlWidget
│   ├── DropdownWidget         container of an inner List of MenuItems
│   ├── GameViewWidget
│   └── InterfaceModeWidget
├── ValueWidget                stateful value with bound setter
│   ├── CheckboxWidget
│   ├── SliderWidget
│   └── EditBoxWidget
├── ButtonWidget               leaf
├── MenuItemWidget             leaf
├── StaticTextWidget           leaf
├── TabWidget                  leaf, parented to a TabControl
└── TableWidget                row-major; cells are arbitrary widgets
```

Inheritance is real: each concrete class has its own metatable that chains up
to `ContainerWidget`/`ValueWidget`/`UIWidget`. Instances are `setmetatable({},
ClassMT)` once at `Create`, so method lookup walks the chain without per-key
field copying.

---

## 3. Lifecycle

### Create

```lua
local w = mgr:CreateWidget(id, "Button", props)
```

- `id` must be non-empty and globally unique within the manager's stack scope.
  Use `mgr:GenerateWidgetId(prefix)` for transient/auto widgets.
- `type` must be registered. Each widget file registers itself at the bottom
  with `CAIWidgetRegistry.Register("TypeName", Class.Create)`.
- `props` is an instance-override table. Keys with a matching `Set<Name>`
  setter (e.g. `Label`, `Tooltip`, `WrapAround`, `FocusKey`, `Transparent`)
  route through the setter. Other keys assign directly to the instance.
- `StaticText` has only one spoken text channel. If a caller supplies both
  `Label` and `Tooltip`, the widget exposes them together from `GetLabel()`,
  separated by `[NEWLINE]`, and `GetTooltip()` returns an empty string. An
  empty label promotes the tooltip to the label; identical values are not
  repeated. Prefer putting the complete text in `Label` at new call sites.

### Push / Pop

```lua
mgr:Push(root, { priority = PopupPriority.Current, focus = "edit:name" })
mgr:Pop()
mgr:RemoveFromStack("ScreenRoot_City")
```

- `priority` controls stack sort. Ties resolve by push order (FIFO).
- `focus` is a widget reference or a `FocusKey` string. Applied only when the
  pushed widget becomes the new top. Avoids screens reaching into
  `FocusedChild` to pre-position focus.
- The active root is always the top of the stack. Focus follows automatically.

### Destroy

```lua
w:Destroy()
```

- Emits `destroy` on `w` first (listeners may clean up subscriptions).
- Calls `Manager:NotifyDestroy(w)` so the focus path silently truncates from
  this widget downward. Screens are expected to follow rebuilds with their
  own `SetFocus` or `RestoreFocus` — no automatic re-speak.
- Recursively destroys children, clears listeners, nils refs.

---

## 4. Focus model

The manager is the single source of truth for focus. There is no per-widget
`FocusedChild` field that the framework respects — screens that try to write
it directly are bypassing the model.

### Canonical state

`Manager.CurrentPath` is an ordered array of widgets from root (top of stack)
to the focused leaf. `Manager:GetFocusedWidget()` returns `CurrentPath[#CurrentPath]`.

### Setting focus

```lua
mgr:SetFocus(widget)                                  -- re-entry / programmatic
mgr:SetFocus(widget, { direction = 1, announce = true }) -- directional nav
mgr:SetFocus(widget, false)                           -- legacy boolean = announce=false
```

A screen that is shown with no readable view (e.g. a cinematic intro where every
vanilla container is hidden) should give the manager a Transparent, childless
focus-holder widget to land on rather than trying to focus nothing — `SetFocus`
with no target is not a supported "clear focus" path. Gate that holder's
`HiddenPredicate` on the cinematic state so normal navigation skips it.

`SetFocus` calls `BuildFocusPath(widget, direction)`:

1. Walks `widget.Parent` chain to the root, producing a `[root, ..., widget]`
   prefix.
1a. Auto-expands any collapsed expandable ancestor in that prefix (calls
   `anc:Expand(true)` — silent, no event) so a focus target buried inside a
   collapsed TreeItem/SubMenu is reachable and visible. The target itself
   keeps its own expand state.
2. Descends from `widget` to a leaf. Each step calls one of:
   - `GetEntryChild(direction)` if `direction` is set (Windows tab-stop
     semantics: forward → first visible, backward → last visible).
   - `GetDefaultChild()` otherwise (re-entry / `RestoreFocus` / `Push focus`
     path: uses cached `_lastFocusedKey` → `_lastFocusedChild` → `DefaultIndex`
     → first visible).

Then `ApplyFocus`:

- Emits `focus_leave` on the old path from the divergence index downward.
- Emits `focus_enter` on the new path from the divergence index downward.
- Updates each parent's `_lastFocusedChild` and `_lastFocusedKey` hints.
- Plays `_focusSound` (via `UI.PlaySound`) on newly entered widgets that
  have one.

Then `BuildAnnouncement` collects per-widget speech strings for everything
from the divergence index downward, skipping any widget marked `Transparent`,
and `SpeakLines(announcements, true)` speaks them — first line interrupts,
rest queue.

Tooltip section navigation uses the shared `SplitTextIntoLines(text, maxLength)`
utility. It preserves explicit `[NEWLINE]` / physical-line boundaries and
groups complete sentences up to the default 75-character target. A sentence
longer than the target remains intact on its own line.

### Direction semantics

- `direction = 1` (forward / Tab / Down / Right / PgDn): entering a container
  lands on its first visible child when that container uses directional entry;
  otherwise it lands on its cached default child.
- `direction = -1` (backward / Shift+Tab / Up / Left / PgUp): entering a
  container lands on its last visible child when that container uses
  directional entry; otherwise it lands on its cached default child.
- `direction = nil/0` (programmatic): entering a container lands on its
  cached default child.

This is the **only** place Windows tab-stop convention kicks in. By default,
only `Transparent` layout containers use that directional first/last descent;
set `UseDirectionalEntry = false` on a transparent container to opt it back
into normal cached-default re-entry. After a
rebuild, `RestoreFocus` deliberately omits direction so the user lands where
they were, not at the start/end of the new children.

### Container entry overrides

- `SubMenuWidget:GetEntryChild` / `GetDefaultChild` return nil while collapsed
  **or** while expanded but with no remembered focus child (no
  `_lastFocusedChild` / `_lastFocusedKey`) — mirrors `TreeItem`. So a bare
  `Expand(true)` (e.g. `BuildFocusPath` opening an ancestor, or a seeded node)
  leaves the submenu a focus stop instead of auto-entering its first child;
  only an explicit `EnterFirstChild` (Enter/Right from the collapsed node)
  descends. `EnterFirstChild` is a no-op once expanded, so a Right/Enter that
  bubbles up from a child does not re-enter and yank focus back to the first.
- `TreeItemWidget:GetEntryChild` returns nil while collapsed (same).
- `TabControlWidget` inherits the default — Shift+Tab into it lands on the
  active page (last child), Tab forward into it lands on the tab strip (first
  child). Override if your screen needs different semantics.

### Stable focus across rebuilds

Widgets that get rebuilt (lists driven by game state, tree views, queue rows)
should set `FocusKey` to a stable string identifying the row across rebuilds:

```lua
row.FocusKey = "production:queue:row:" .. unitId
```

The screen wraps the rebuild with capture + restore:

```lua
local capture = mgr:CaptureFocusKey(treeRoot)
treeRoot:ClearChildren()
RebuildTree(treeRoot, gameData)
mgr:RestoreFocus(treeRoot, capture)
```

`CaptureFocusKey` walks from the focused leaf up to `root` and returns
`{ key, path }` — `key` is the deepest `FocusKey` on the path (or nil),
`path` is the index path as a fallback. It returns `nil` when focus is not
inside `root` (including the "no focus yet" first-paint case).

`RestoreFocus` is scoped to the rebuilt subtree: **a nil capture is a no-op**,
so a passive rebuild never steals focus from elsewhere or plants initial
focus. When capture is non-nil it tries in order: match `key` via DFS → walk
`path` clamping out-of-range or hidden cells → fall back to the first visible
child of `root` (the item under focus went away). Initial focus on screen
open is set by `Push` itself (via `UpdateRootFocus` → `SetFocus(top)`); do
not rely on `RestoreFocus` to anchor it.

The `key` match restores silently (`announce = false`) — same logical position,
nothing new to say. The `path` walk and first-visible-child fallback re-`SetFocus`
and **speak**, since the original item moved or went away and the user should
hear where focus landed. The `path` walk also **stops at a collapsed expandable**
(a node whose `IsExpanded` is false): the captured position pointed inside a
subtree the rebuild left closed, so focus lands on the collapsed node rather than
silently re-opening it (which previously auto-entered submenus / tree items).

Dropdown option rows automatically use `<dropdown focus key or id>:option:<index>`
as their `FocusKey`, preferring the dropdown's stable `FocusKey` when present.
Setting focus to any dropdown descendant silently opens its dropdown
ancestor, just as focusing inside a collapsed tree or submenu expands that
ancestor. When an option key matches after a rebuild, `RestoreFocus` therefore
returns to the option inside the open dropdown instead of landing on its outer
control.

Dropdown commit is deliberately different from passive refresh. It temporarily
sets the manager's `FocusRestoreKeyOverride` to the outer dropdown's stable key
while its value setter and `value_changed` handlers run. The new value is thus
committed before close, but a synchronous rebuild restores directly to the
closed replacement dropdown instead of reopening its option row. The prior
override is restored afterward so the transaction remains scoped.

A screen that is itself about to move focus elsewhere after a rebuild (e.g. the
diplomacy ActionView rebuilds its statement list inside `SelectPlayer` and then
hands focus to the conversation list) should skip the restore for that pass —
pass a `nil` capture so `RestoreFocus` no-ops — rather than relying on a silent
restore. The default restore is meant to speak.

When vanilla refreshes part of a screen, CAI refreshes only the mirrored widget
container for that same vanilla-owned area. Do not remove and re-push the whole
CAI root, and do not rebuild unrelated sibling widgets, unless the user
explicitly asks for that behavior or vanilla has actually closed/reopened the
whole screen. For list/tree/table refreshes, keep the root mounted and use the
container-local focus tools above (`CaptureFocusKey` / `RestoreFocus`, or
`PrepareFocus` when the rebuilt container is not currently focused). This avoids
spurious root-focus resets such as tab-strip focus bouncing into a refreshed
tree and back out.

### Re-announcing without re-focusing

When a focused widget's data updates due to a game event:

```lua
Events.SomeGameStateChanged.Add(function()
    if mgr:GetFocusedWidget() == myWidget then
        mgr:Refocus()
    end
end)
```

`Refocus()` re-speaks the current leaf using `BuildAnnouncement` over the leaf
only. `focus_enter`/`focus_leave` are not re-fired.

To announce a specific widget out of band:

```lua
otherWidget:Announce()                  -- all canonical elements
otherWidget:Announce({ "value" })       -- only the value element
```

---

## 5. Speech model

Speech is **one TTS line per widget** — the Windows screen-reader convention.
Focus changes produce N lines (N = widgets in the path tail from the
divergence index), all sent through `SpeakLines(lines, true)`. First line
interrupts ongoing speech; the rest queue so per-widget lines don't trample
each other.

### What gets spoken per widget

`UIWidget:BuildSpeech(elements?)` assembles a string from these canonical
elements, in order:

1. `label` — `GetLabel()`
2. `role` — `Locale.Lookup("LOC_UIWidget_Role_" .. (Role or Type))`
3. `value` — `GetValue()`
4. `position` — `Locale.Lookup("LOC_UIWidget_Element_Pos", visIdx, visTotal)`
5. `state` — disabled marker + `GetState()`
6. `tooltip` — `GetTooltip()`

Each element is included only if non-empty. The widget's `SpeechSettings`
table can mute individual elements (`SpeechSettings = { Role = false }`),
and the manager's `CAISettings` table has global toggles (`speakLabel`,
`speakRole`, ...).

### Transparent widgets

A widget marked `Transparent = true` is skipped entirely by
`BuildAnnouncement`. Use this for layout-only containers — the dialog button
row is the canonical example. Transparent containers also use directional
first/last entry by default; set `UseDirectionalEntry = false` when a
transparent container should stay silent in speech but still restore its
cached/default child on entry.

### Custom speech triggers

- `ValueWidget:SetValue(v)` (non-silent) speaks the value element after firing
  `value_changed`.
- `TreeItemWidget:Expand/Collapse` speak the value element on toggle so the
  user hears "expanded, 5 items" / "collapsed", and focus speech announces the
  same state on every node as the user navigates (the standard tree readout).
  The crucial rule: **only user-driven toggles speak**. Both methods take a
  `silent` flag (`Expand(true)` / `Collapse(true)`) that suppresses **both** the
  `expanded`/`collapsed` event and the speech — every automatic or programmatic
  caller passes it (seeding initial state, the focus-path ancestor auto-expand,
  a screen's re-expand listener), so navigation and deliberate Left/Right/Enter
  toggles are the only things that ever speak the state. The default (no flag),
  used by the Tree key handlers, is the user-driven speaking path.
  `Collapse` always tears down its whole subtree: every descendant is collapsed
  (silently, no events) so a later re-expand reveals one clean level. Seed
  initial expand state with `Expand(true)` after children exist; only fall back
  to a direct `IsExpanded = true` write when children are added later (the leaf
  guard makes `Expand` a no-op on a childless node). `SubMenuWidget`
  expand/collapse don't speak a value at all — the focus change announces.
- `EditBoxWidget` speaks per-keystroke characters, deleted text, selection
  changes, line content on Up/Down, etc. — all routed through `Speak(.., true)`
  for the interrupting feel. A successful buffer mutation speaks its typed,
  pasted, deleted, cancelled, or programmatic value feedback before emitting
  `text_changed`, so listener work cannot interrupt the edit echo.

### Speech setting precedence

```
SpeechSettings[Key] == false       → mute on this widget
CAISettings["speak"..Key] == false → mute globally
otherwise → include if the info string is non-empty
```

### `IgnoreWhenNotFocused`

`SpeechSettings = { IgnoreWhenNotFocused = true }` makes a widget contribute
to focus-change speech only when it is the focus leaf. Useful for TreeItems
which would otherwise re-announce themselves while focus passes through their
subtree.

---

## 6. Event system

Multi-listener, snapshot-iterated events on every widget.

```lua
local token = widget:On("activate", function(w) ... end)
widget:Off("activate", token)
widget:Emit("activate")
widget:Emit("value_changed", newValue)
```

Listeners receive `(widget, ...extraArgs)`. The snapshot semantics mean a
handler can add or remove listeners during dispatch without breaking
iteration.

### Standard events

| Event             | When fired                                                   | Extra args |
|-------------------|--------------------------------------------------------------|------------|
| `focus_enter`     | Widget or descendant became part of CurrentPath              | `(path, index)` |
| `focus_leave`     | Widget left CurrentPath                                      | `(path, index)` |
| `activate`        | Button / MenuItem / TreeItem-leaf activation                 | —          |
| `value_changed`   | `SetValue` (non-silent), `Toggle`, `Increment`/`Decrement`, EditBox `Commit` | `(newValue)` |
| `expanded`        | TreeItem or SubMenu expanded                                 | —          |
| `collapsed`       | TreeItem or SubMenu collapsed                                | —          |
| `destroy`         | First step of `Destroy`; listeners should clean up           | —          |

`navigation_wrap` fires after a successful navigation move crosses a wrapping
container or TabControl boundary. Its extra argument is the direction (`1` or
`-1`). The manager's default listener plays the `UI_MENU_WRAP` raw-audio cue.

### `focus_enter` contract

`focus_enter` fires on **every newly-populated path slot**, not only the
focus leaf. A handler on a Panel will fire when focus moves into any
descendant. To do work only when the widget *is* the leaf, check
`w:IsFocused()` inside the handler.

`Manager.CurrentPath` is committed **before** events fire, so `IsFocused()`
and `Manager:GetFocusedWidget()` reflect the post-change state from inside
the handler. Speech still runs after all events have fired (the manager
assembles announcement strings once `ApplyFocus` returns), so handlers can
update vanilla control state — labels, selection, tooltip text — and that
new state is what gets spoken. Inside a `focus_leave` handler, `IsFocused()`
is false; the old path is available as the event's first extra arg if you
need it.

---

## 7. Value / action model

`ValueWidget` is the base for stateful widgets. Pattern:

```lua
local checkbox = mgr:CreateWidget(id, "Checkbox", {
    Label = function() return "Notifications" end,
})
checkbox:SetValueSetter(function(_, v) gameSettings.notifications = v end)
checkbox:On("value_changed", function(_, v) print("now", v) end)
checkbox:Toggle()
```

- `SetValue(v, silent)` — sets internal value, calls the bound setter (unless
  silent), emits `value_changed`, speaks the value element.
- `GetValue()` — returns the internal value.
- `SetValueSetter(fn)` — function called when the value changes through the
  widget. Use this to push the value into the vanilla game system. EditBox
  `Commit` runs the same setter. Enter commits for all non-read-only edit
  boxes by default. Set `EnterToCommit = false` to make Enter bubble instead
  (useful when a parent confirm binding should handle it).

For EditBox: the buffer/commit phase is internal. Per-keystroke editing
mutates `_buffer` only — no events fire. `Commit()` promotes the buffer to
`_value`, calls the setter, and emits `value_changed` once. The convention
for distinguishing user commits from programmatic refresh is the `silent`
flag on `SetText` / `SetValue`: refresh calls pass `silent=true` and emit
nothing; user commits run non-silent and fire `value_changed`.
All non-read-only edit boxes commit on Enter by default (`EnterToCommit`
is true). Set `EnterToCommit = false` to make Enter bubble — useful when a
parent confirm wrapper should handle the commit. `AlwaysEdit` writable
boxes auto-commit on focus leave by default. Set `CommitOnFocusLeave = false`
when a screen should preserve the live buffer while focus moves away.
For writable `AlwaysEdit`, `HighlightOnEdit` selects the existing text when
focus lands on the widget. That selection is silent because focus entry is not a
user-driven edit command; the manager's normal focus speech reads the selected
value once. When `HighlightOnEdit` is off, focus entry does not reposition the
cursor. Read-only `AlwaysEdit` viewers preserve their cursor when focus leaves
and returns.
`EditBox:GetTooltip()` prepends a live interaction hint to any tooltip supplied
by the screen. `AlwaysEdit` boxes prepend `LOC_CAI_EDIT_HINT_TYPE_TEXT`;
inactive non-`AlwaysEdit` boxes prepend `LOC_CAI_EDIT_HINT_PRESS_ENTER`.
Read-only boxes never add an interaction hint. An active non-`AlwaysEdit` box
also exposes only its screen-specific tooltip.

Direct methods are preferred over string-dispatched actions. EditBox exposes
`BeginEdit`, `Commit`, `Cancel`. Checkbox: `Toggle`, `SetChecked`. Slider:
`Increment`, `Decrement`, `PageIncrement`, `PageDecrement`. Dropdown:
`SetOptions`, `SetSelectedIndex`, `GetSelectedIndex`, `Commit`, `Open`,
`Close`, `IsOpen`.

Slider `SetMin` / `SetMax` are configuration operations. If a new bound clamps
the current internal value, that clamp is silent: it does not call the backing
setter, emit `value_changed`, or announce a value. Screens should seed the live
value explicitly with `SetValue(value, true)` after configuring the bounds.

### Dropdown open / commit

Dropdown is a ContainerWidget that owns a single inner List of MenuItems —
one per option. The list's label mirrors the dropdown label (so opening
re-announces context) and its position-in-parent is suppressed (it is the
dropdown's only child). The list is hidden via a hidden predicate keyed on
`_isOpen`, so when closed the dropdown has no navigable children and arrow
keys bubble to the enclosing list/panel.

Enter on a closed dropdown calls `Open()`: unhides the list, focuses the
MenuItem matching the committed selection, emits `opened`. Inside the open
list the existing List navigation handles Up/Down/Home/End/PageUp/PageDown
and type-to-find with wrap-around — no preview state to maintain. Activating
a MenuItem calls `dropdown:Commit(i)`, which fires `value_changed` and
closes (returning focus to the dropdown so the new value is announced).
Escape on an open dropdown closes without changing the value (the binding
lives on the dropdown so it catches the key bubbling up from MenuItem →
List → Dropdown). Losing focus while open closes silently — no event, no
SetFocus back to the dropdown.

Screens that mirror a vanilla `PullDown` listen for `opened` / `closed` and
call `pulldown:SetOpen(true/false)` so the vanilla panel tracks the widget's
mode. The silent focus_leave close skips the event because the screen is
typically already tearing down the vanilla control on that path; call
`Close()` explicitly from screen code if you need the event.

---

## 8. Input dispatch

Civ VI routes raw input through context-bound handlers. The CAI manager
installs `Manager:HandleInput(input)` for the active context. It:

1. Starts at `GetFocusedWidget()` (the leaf).
2. Walks `node.Parent` upward.
3. Skips any node whose `IsHidden()` is true.
4. For each node with an `OnHandleInput`, calls it.
5. Returns true the first time a handler returns true (consumed).

`UIWidget:OnHandleInput` does the default: walks `InputMap` for a binding
whose key, modifier mask, and message type match the incoming event, then
calls its `Action(self)`. Return `true` to consume, `false` to bubble up
to the parent widget, or `nil` to skip this binding and try the next one
in the same widget's `InputMap` (useful for class bindings that defer to
screen-level overrides).

Char input bubbles through `OnCharInput` the same way (used by `List`/`Tree`
type-to-find and `EditBox` typing).

### Adding a binding

```lua
widget:AddInputBindings({
    { Key = Keys.VK_F1, MSG = KeyEvents.KeyUp, Action = function(w) Speak("help") return true end },
    { Key = Keys.S, MSG = KeyEvents.KeyDown, IsControl = true, Action = function(w) DoSave() return true end },
})
```

Binding defaults: `IsShift=false`, `IsControl=false`, `IsAlt=false`,
`MSG=KeyEvents.KeyUp`.

Non-common bindings are normally consumed without running their action when the
focused widget is disabled. Set `BubbleWhenDisabled=true` on navigation
bindings that should instead continue to an ancestor. Disabled EditBoxes use
this for unmodified Up/Down and Home/End so an inactive field cannot trap
navigation belonging to its containing List; editing and activation bindings
remain blocked.

---

## 9. Navigation

`ContainerWidget` provides the navigation primitives. Concrete container
widgets bind the keys that should call them.

| Method               | Default keys                  |
|----------------------|-------------------------------|
| `NavigateNext`       | List Down / HList Right / Panel Tab |
| `NavigatePrev`       | List Up / HList Left / Panel Shift+Tab |
| `NavigateToFirst`    | Home                          |
| `NavigateToLast`     | End                           |
| `NavigatePage(dir)`  | PgUp/PgDn (default page size 10) |

`PageSize` defaults to 10. Override per widget via `SetPageSize(n)` or the
`PageSize` prop. Set to 0 to disable paging on that widget.

### Direction is threaded through

All four navigators pass `{ direction = ±1 }` into `SetFocus`. That direction
controls how the target container is entered (first vs last child). This is
what makes Shift+Tab from a content row into the dialog's button row land on
the **last** button (Cancel), not the first (OK).

### Tree navigation

Trees use flat visible order for Up/Down and paging, while Home/End operate on
the focused row's sibling level. The helper module
`CAIWidgetHelpers_Tree`:

- `Flatten(root)` — pre-order list of every visible TreeItem reachable from
  root, descending only into expanded nodes.
- `NavigateFlat(root, dir)` — Up/Down moves through the flat list.
- `NavigatePage(root, dir, pageSize)` — PgUp/PgDn jumps PageSize positions.
- `NavigateFirst/Last(root)` — Home/End moves to the first/last visible sibling at the focused row's current depth.
- `NavigateTreeFirst/Last(root)` — Ctrl+Home/Ctrl+End moves to the first/last row in the flattened visible tree; the last row may be a deep descendant of an expanded final branch.
- The `TreeHomeEndCurrentDepth` UI setting selects which pair plain Home/End uses. It defaults to current-depth navigation; disabling it restores legacy full-tree navigation. Ctrl+Home/Ctrl+End remain full-tree regardless.
- `ExpandOrDescend(root)` — Right key: expand if collapsed; descend to first
  child if already expanded.
- `CollapseOrAscend(root)` — Left key: collapse if expanded; jump to parent
  TreeItem if collapsed.
- `ToggleFocused(root)` — Enter key on Tree: toggle focused item's expand
  state. Bubbles only when the focused item has no `activate` listener.

### Type-to-find search

`CAIWidgetHelpers_Search.HandleChar(root, char, maxDepth)`:

- Appends the char to `Manager.SearchBuffer`, with timeout behavior controlled
  by the `SearchTimeout` setting when persistent result navigation is disabled.
- Collects depth-limited candidates and applies the existing match-tier and
  relevance ordering before focusing the first result.
- **Same-letter cycling**: pressing the same single letter again while that
  one-character search remains active doesn't extend the buffer. The next
  search starts after the focused
  match, cycling through every item starting with that letter. Matches the
  JAWS/NVDA convention.
- The default-enabled `TypeToFindResultNavigation` UI setting turns the ranked
  matches into a persistent flat result list. While its buffer is non-empty,
  Up/Down move to the previous/next result and wrap at the ends. The timeout is
  suspended without changing result collection or sorting.
- A persistent search is owned by the List or Tree where typing began. Moving
  focus outside that container clears it silently. A successful widget
  interaction also clears it silently: activation, value or text changes,
  dropdown open/close, TreeItem or SubMenu expand/collapse, and entering an
  EditBox or an already-expanded TreeItem. Programmatic silent refreshes do not
  clear it. After clearing, ordinary widget navigation resumes immediately.
- When the type-to-find buffer is non-empty, manager-level `Escape` clears it
  and speaks `Search cleared`. `Backspace` removes the last character; if that
  empties the buffer, it also speaks `Search cleared`.
- `CAIWidgetHelpers_Search.MatchSearchText(label, query)` exposes the same
  start-whole-word, start-prefix, whole-word, word-prefix, substring, and
  word-prefix-abbreviation classifier to non-widget consumers. It returns the
  best `SearchResult` tier for that label or `nil` when the label does not
  match; callers retain ownership of result grouping and tie-breaking.

Wire it up on a container:

```lua
function MyList:OnCharInput(char)
    return CAIWidgetHelpers_Search.HandleChar(self, char, self.SearchDepth)
end
```

`SearchDepth` defaults: List = 2, Tree = 3.

### Ctrl+F search panel

`ContainerWidget` owns the Ctrl+F search integration. Every container has an
`AllowSearch` flag (default `false`). When `AllowSearch` is true and the user
presses Ctrl+F, the container opens a `SearchPanelWidget` overlay that indexes
descendants via the game's `Search.*` API, presents matching results as a
navigable list, and jumps to the selected widget on activation.

**Lists and Trees enable search by default** — they set `AllowSearch = true` in
their constructors. All other containers (Panel, Dialog, TabPage, etc.) keep it
off unless explicitly enabled.

#### Enabling search

```lua
-- Enable with default widget-label indexing:
myPanel:EnableSearch()
-- or
myPanel:SetAllowSearch(true)

-- Enable with a custom query handler (implicitly sets AllowSearch = true):
myTree:SetSearchQueryHandler(function(query, maxResults)
    -- Return a list of { key, label, onActivate?, widget?, tooltip? }
    return results
end)

-- Full-text contexts can receive the complete query once:
myTree:SetSearchQueryMode("raw")

-- Disable:
myPanel:DisableSearch()
```

#### Custom query handlers

A query handler receives `(query, maxResults)` and must return a list of result
tables. Each result has:

- `key` — string, used as `FocusKey` on the result button.
- `label` — string, the display text for this result.
- `onActivate` — optional function, called when the user activates the result.
  If omitted and `widget` is present, focus jumps to that widget.
- `widget` — optional `UIWidget`, the target for focus-jump on activation.

When no custom handler is set, the SearchPanel walks the container's descendants,
collects their speech text, builds a `Search.*` context, and matches against it.

The default query mode is `"terms"`. The panel parses the edit text into
whitelisted terms, intersects their result sets, and subtracts `--term` matches.
A custom handler is therefore called once for each parsed term. This behavior is
well suited to labels in maps, trees, and ordinary lists.

Call `container:SetSearchQueryMode("raw")` for a full-text index. Raw mode passes
the complete edit-box string to the custom handler once, without CAI term or
exclusion parsing, and preserves the search provider's phrase ranking and
preview. If no custom handler is installed, the full string is passed once to
the panel's `Search.*` context.

#### Accessing the search panel from a screen

```lua
-- Forward results programmatically while the panel is open:
container:SetSearchResults(myResults)

-- Get the active search panel (nil if not open on this container):
local panel = container:GetSearchPanel()
```

The manager owns a single shared `SearchPanelWidget` instance. When
`mgr:OpenSearch(container)` is called, it applies the container's stored query
handler and query mode to the panel before opening it.

The result list always contains an empty-state row when there are no results.
It reads `Type text to search` while the edit box is empty and `No results`
after a nonempty query. The empty-state row is never auto-focused. If a rebuild
destroys a focused result, focus remains on the result-list container.

The UI setting `AutoFocusFirstSearchResult` controls whether a successful
result rebuild moves focus to the first result. It defaults to enabled. When
disabled, rebuilding results does not explicitly move focus.

### Manager-bound widget helpers

`mgr.WidgetHelpers` is a per-manager table of quick widget builders. Helper
modules contribute to it by exposing an `Install(mgr)` function that closes
over the owning manager and binds named methods. Screens then call
`mgr.WidgetHelpers.X(...)` without threading the manager through every call,
and the manager keeps full ownership of its helpers — no module-global state.

Currently installed at init:

- `mgr.WidgetHelpers.MakeGeneralDialog(titleFn, buttons, contentRows?, defaultIndex?)`
- `mgr.WidgetHelpers.CreatePopupDialog(popup)` — vanilla `PopupDialog` wrapper.

To add a new builder: define `YourHelper.Install(mgr)` that assigns closures
onto `mgr.WidgetHelpers`, then call it from `UIScreenManager:Init()` alongside
the existing `CAIWidgetHelpers_DialogBuilder.Install(mgr)`.

---

## 10. TabControl

`TabControlWidget` owns its tabs and pages — there's no separate "tab strip"
widget that screens need to manage. `AddPage(labelOrFn)` creates the Tab and
TabPage internally and returns the TabPage to populate.

```lua
local tabs = mgr:CreateWidget("CityPanel_Tabs", "TabControl", { Label = ... })
-- WrapAround defaults to true; call tabs:SetWrapAround(false) to opt out.

local overview = tabs:AddPage(function() return Locale.Lookup("LOC_OVERVIEW") end)
overview:AddChild(headerStaticText)
overview:AddChild(actionsList)

local citizens = tabs:AddPage(function() return Locale.Lookup("LOC_CITIZENS") end)
citizens:AddChild(citizenTable)

tabs:On("value_changed", function(_, idx)
    Speak("Switched to tab " .. tostring(idx))
end)
```

### Internal structure

`tabs.Children` is always `[_tabStrip, activePage]`. The strip is a
HorizontalList of Tab widgets; non-active pages live in `_pages[]` but are
detached from the children list. `SetActivePage(i)` swaps slot 2.

### Navigation

- First-time entry into the TabControl (no prior focus inside) lands on the
  active page, not the tab strip. `GetDefaultChild` / `GetEntryChild` both
  return the active page.
- Left/Right within the strip cycles tabs and immediately activates the
  page (via the `focus_enter` → `_OnTabFocused` hook on each Tab).
- `Ctrl+Tab` / `Ctrl+Shift+Tab` cycles tabs from anywhere inside the
  TabControl (bindings live on the TabControl itself; input bubbles up).
  Focus follows the user's current context: if they're in the tab strip the
  new tab is focused; otherwise the new page is focused so they can keep
  working in page content.
- Tab / Shift+Tab inside the control behave as standard ContainerWidget
  navigation — strip is child 1, active page is child 2.

### API

| Method                          | What                                       |
|---------------------------------|--------------------------------------------|
| `AddPage(labelOrFn)`            | Create & append; returns the TabPage       |
| `GetPageCount/GetPage(i)`       | Iterate                                    |
| `GetPageById(id)`               | Lookup by id                               |
| `GetActivePage()`               | Currently active page                      |
| `GetActivePageIndex()`          | 1-based index                              |
| `SetActivePage(i, silent)`      | Programmatic switch; focus follows context |
| `SetActivePageById(id, silent)` |                                            |
| `NextPage/PreviousPage(silent)` | Wraps by default; `SetWrapAround(false)` to disable |

---

## 11. Table

Three-level hierarchy: **Table → Column → Tier → item cell**.

- **Column** is a labeled group (e.g. a civics-tree era). It speaks only its
  header label — role and position are muted — and owns its cells through
  tiers. Because of that ownership, the manager's focus-divergence machinery
  announces the column header automatically when, and only when, focus crosses
  into a new column. No custom speech code.
- **Tier** is a side-by-side sub-column inside a column. A column of `width` N
  holds N tiers laid out left-to-right. Tiers are `Transparent` — they
  contribute nothing of their own to speech.
- **Item cell** is an arbitrary widget stacked vertically inside a tier. Its
  position element reads as its vertical index within the tier ("3 of 7").

A plain data grid is the degenerate case: every column has one tier (`width`
defaults to 1), so Left/Right walks columns and Up/Down walks rows, and each
column header is announced as you move across.

```lua
-- Plain grid
local tbl = mgr:CreateWidget(id, "Table", { Label = ... })
tbl:AddColumn({ header = "Unit" })
tbl:AddColumn({ header = "Health" })
for _, unit in ipairs(units) do
    tbl:AddRow({ cellStaticText(unit.name), cellStaticText(unit.healthString) })
end

-- Multi-tier (civics tree: era column with several tiers side by side)
local era = tbl:AddColumn({ header = eraName, width = 3 })
tbl:AddItem(era, 1, civicWidget)   -- tier 1, appended vertically
tbl:AddItem(era, 2, otherCivic)    -- tier 2
```

| Method                          | What                                          |
|---------------------------------|-----------------------------------------------|
| `AddColumn({ header, width? })` | Append a column (width = tier count); returns the column widget |
| `GetColumnCount / GetColumnWidget(i)` |                                         |
| `GetTier(column, tierIndex?)`   | Tier widget (column = widget or index)        |
| `AddItem(column, tierIndex, w)` | Append a cell into a tier; returns item index |
| `AddRow(cells)`                 | Grid convenience: one cell per column, tier 1 |
| `SetCell(row, col, widget)`     | Replace/insert a grid cell in column's tier 1 |
| `GetCell(row, col)`             | Grid cell from column's tier 1                |
| `GetRowCount`                   | Longest first-tier stack across columns       |
| `RemoveRow(row)`                | Destroys the row-th cell in each column's tier 1 |
| `ClearRows`                     | Destroys all cells; keeps column/tier structure |

### Grid navigation

All navigation lives on the `TableWidget` (it reads the live focus leaf via
`Manager:GetFocusedWidget()`). Hidden and empty cells are **skipped in the
direction of travel** — never landed on. There is no wrap; reaching an edge
with no candidate returns false so input bubbles to the parent.

- **Up / Down** — move within the focused cell's tier.
- **Left / Right** — step to the adjacent tier in the flattened tier list
  (across all columns), landing on the cell at the same vertical index
  (clamped). Crossing a column boundary triggers the header announce.
- **Home / End** — first / last visible cell in the current tier.
- **Ctrl+Home / Ctrl+End** — table-wide first / last navigable cell.
- **Ctrl+Left / Ctrl+Right** — jump to the first cell of the previous / next
  column.

---

## 12. Dialog

`DialogWidget` is the host for modal popups. Tab / Shift+Tab / Up / Down all
navigate dialog rows (content rows + the button row, in that order).

```lua
local d = mgr:CreateWidget(id, "Dialog", { Label = titleFn })
d:AddChildren(contentRows)
d:SetButtons({okBtn, cancelBtn}, 1)   -- defaultIndex = OK
mgr:Push(d, { priority = PopupPriority.Current })
```

`SetButtons(buttons, defaultIndex)` auto-creates a `Transparent` Panel as the
last child of the dialog, wires Left/Right + Up/Down (all four cycle buttons
within the row — Tab escapes), and sets the default action widget. Enter on
the dialog fires that widget's `activate`.

`GetActionButtons()` and `GetContent()` return the button-row children and
all other (non-button-row) children respectively.

---

## 13. Adding a new widget

1. **Pick the base class.** Navigable container → `ContainerWidget`.
   Stateful value with bound setter → `ValueWidget`. Leaf / simple → `UIWidget`.
2. **Create the file** in `src/UI/uiManager/CAIWidget_<Name>.lua`. The `CAI`
   prefix is required to avoid VFS collisions with vanilla Lua names.
3. **Declare the class** with metatable chain:

   ```lua
   ---@class MyWidget : ContainerWidget
   MyWidget = setmetatable({}, { __index = ContainerWidget })
   MyWidget.__index = MyWidget
   ```

4. **Write `Create(mgr, id, props)`**. Start with the parent constructor,
   set `Id`/`Type`/`Role`/`Manager`, add input bindings, hook events, apply
   props last:

   ```lua
   function MyWidget.Create(mgr, id, props)
       local w = ContainerWidget.New(MyWidget)
       w.Id = id
       w.Type = "MyWidget"
       w.Role = "MyWidget"
       w.Manager = mgr
       w:AddInputBindings({ ... })
       CAIWidgetRegistry.ApplyProps(w, props)
       return w
   end
   ```

5. **Add public methods** as needed.
6. **Register** at the bottom:

   ```lua
   CAIWidgetRegistry.Register("MyWidget", MyWidget.Create)
   ```

7. **Include** in `CAIUIScreenManager.lua` (`include("CAIWidget_MyWidget")`)
   before the manager's `Init` call.
8. **Add to `.modinfo`** in all three blocks: top-level `<Files>`, FrontEnd
   `<ImportFiles>`, InGame `<ImportFiles>`.
9. **Add LuaLS annotations** to `src/ideHelpers.lua`.

---

## 14. Binding vanilla controls

The recurring pattern in CAI screens. The CAI widget mirrors live vanilla
state — never caches displayed values, always reads through to the control.

```lua
local btn = mgr:CreateWidget(id, "Button", {
    Label   = function() return vanillaButton:GetText() or "" end,
    Tooltip = function() return vanillaButton:GetToolTipString() or "" end,
})
btn:SetHiddenPredicate(function() return vanillaButton:IsHidden() end)
btn:SetDisabledPredicate(function() return vanillaButton:IsDisabled() end)
btn:On("activate", function() vanillaButton:CallCallback("Click") end)
```

For checkboxes:

```lua
check:SetChecked(vanillaCheck:IsChecked(), true)
check:SetValueSetter(function(_, v)
    if vanillaCheck:IsChecked() ~= v then vanillaCheck:DoLeftClick() end
end)
```

For edit boxes wrapping a vanilla `EditBox`:

```lua
edit:SetText(vanillaEdit:GetText() or "", true)
edit:SetValueSetter(function(_, text) vanillaEdit:SetText(text) end)
-- SetValueSetter is also called on Commit.
-- Enter commits by default. Set edit:SetEnterToCommit(false) to bubble instead.
```

---

## 15. File layout

```
src/UI/uiManager/
  CAIUIScreenManager.lua          entry point
  CAIWidgetRegistry.lua           type-name → ctor map
  CAIWidget_Base.lua              UIWidget
  CAIWidget_Container.lua         ContainerWidget
  CAIWidget_Value.lua             ValueWidget
  CAIWidget_Button.lua
  CAIWidget_MenuItem.lua
  CAIWidget_StaticText.lua
  CAIWidget_Panel.lua
  CAIWidget_Dialog.lua
  CAIWidget_List.lua
  CAIWidget_HorizontalList.lua
  CAIWidget_SubMenu.lua
  CAIWidget_Tree.lua
  CAIWidget_TreeItem.lua
  CAIWidget_Dropdown.lua
  CAIWidget_Checkbox.lua
  CAIWidget_Slider.lua
  CAIWidget_EditBox.lua
  CAIWidget_TabControl.lua
  CAIWidget_Tab.lua
  CAIWidget_TabPage.lua
  CAIWidget_Table.lua
  CAIWidget_GameView.lua
  CAIWidget_InterfaceMode.lua
  CAIWidget_SearchPanel.lua
  helpers/
    CAIWidgetHelpers_Navigation.lua
    CAIWidgetHelpers_Search.lua
    CAIWidgetHelpers_Tree.lua
    CAIWidgetHelpers_EditBox.lua
    CAIWidgetHelpers_DialogBuilder.lua
```

Include order matters: `CAIUIScreenManager.lua` includes every widget file
**before** calling `UIScreenManager:Init()`, so the registry is fully
populated by the time anyone calls `CreateWidget`.

---

## 16. Migration guide for screens

When migrating a screen from the old template-merged manager:

1. **Replace `mgr:CreateUIWidget(id, type, props)`** with `mgr:CreateWidget(id, type, props)`.
2. **Replace single-callback fields**:
   - `OnClick = fn` → `w:On("activate", fn)`
   - `OnFocusEnter = fn` → `w:On("focus_enter", fn)`
   - `OnFocusLeave = fn` → `w:On("focus_leave", fn)`
   - `OnCommit = fn` → `w:On("value_changed", fn)` (EditBox emits it on Commit; programmatic refresh uses `SetText(text, true)` silent so it doesn't fire)
   - `OnValueChanged = fn` → `w:On("value_changed", fn)`
   - `OnToggleExpanded = fn` → `w:On("expanded", fn)` / `w:On("collapsed", fn)`
3. **Replace `widget.FocusedChild = X` and `widget:SetFocusedChild(N)`** with
   `mgr:SetFocus(child)` or `mgr:Push(root, { focus = child })`.
4. **Replace rebuild-and-restore dances** with:
   - Set `FocusKey` on rebuilt rows.
   - `local capture = mgr:CaptureFocusKey(root)`
   - rebuild
   - `mgr:RestoreFocus(root, capture)`
5. **Replace `w:SpeakElements(...)`** with `w:Announce(...)` (the legacy name
   still works).
6. **Replace `OnFocusEnter = function() UI.PlaySound("X") end`** with
   `w:SetFocusSound("X")`.
7. **Replace manual tab-row screens** (toggle IsHidden on sibling containers)
   with a `TabControl` + `AddPage` per tab.
8. **Replace ad-hoc dialog assembly** (Dialog + button-row Panel +
   default-action wiring) with `Dialog:SetButtons(buttons, defaultIndex)` or
   `mgr.WidgetHelpers.MakeGeneralDialog(titleFn, buttons, contentRows, defaultIndex)`.
9. **Old type-name aliases** (`Treeview` → `Tree`, `TreeviewItem` → `TreeItem`,
   `Edit` → `EditBox`, `TabBar` → not directly mapped; screens that used
   `TabBar` should migrate to `TabControl`) need explicit renames in
   `CreateWidget` calls.

---

## 17. Don'ts

- Don't read or write `w.FocusedChild` directly — use `mgr:SetFocus(w)` or
  `w:GetFocusedChild()` (manager-derived).
- Don't keep widget references across rebuilds — the path may contain dead
  references for a single frame before the next `SetFocus` call. Use
  `FocusKey` + `RestoreFocus` instead.
- Don't call `Speak()` for focus-driven announcements — the manager does it.
  Use `w:Announce()` or `mgr:Refocus()` for out-of-band re-announces.
- Don't add `OnHandleInput` overrides that always return true; that breaks
  bubbling. Return false when you didn't actually handle the input.
- Don't bypass `BeginEdit`/`Commit`/`Cancel` on EditBox by writing `_buffer`
  directly. Use `SetText` for committed text; the buffer is a working copy.
- Don't pass display-time strings to `SetLabel` — pass either a literal or a
  getter function so live values stay live.

---

## 18. Reference: events on each widget

| Widget         | Emits                                          |
|----------------|------------------------------------------------|
| ButtonWidget   | activate                                       |
| MenuItemWidget | activate                                       |
| DropdownWidget | value_changed, opened, closed                  |
| CheckboxWidget | value_changed                                  |
| SliderWidget   | value_changed                                  |
| EditBoxWidget  | text_changed (every buffer mutation, after edit speech); value_changed (on Commit) |
| TreeItemWidget | activate (leaf only), expanded, collapsed      |
| SubMenuWidget  | expanded, collapsed                            |
| TabControlWidget | value_changed (page index)                   |
| (all)          | focus_enter, focus_leave, destroy, navigation_wrap |

---

## 19. Reference: bindings on each widget

| Widget         | Keys                                                          |
|----------------|---------------------------------------------------------------|
| Base widget     | Shift+F1 speaks the focused widget's specific bindings followed by common bindings; Shift+F2 speaks the full focus path |
| Container (base)| Ctrl+F → open SearchPanel (when AllowSearch=true)            |
| Button         | Enter, Space → activate                                       |
| MenuItem       | Enter → activate                                              |
| Panel          | Tab / Shift+Tab → next/prev                                   |
| Dialog         | Tab / Shift+Tab / Up / Down → next/prev row; Enter → default  |
| Dialog buttons | Left / Right / Up / Down → cycle (sticky)                     |
| List           | Up/Down/Home/End/PgUp/PgDn; Ctrl+F → search; chars → search  |
| HorizontalList | Left/Right/Home/End/PgUp/PgDn                                 |
| SubMenu        | Enter / Right → expand-enter; Left → collapse-exit;            |
|                | when expanded: Up/Down/Home/End/PgUp/PgDn                     |
| Tree           | Up/Down/PgUp/PgDn flat; Home/End current depth; Ctrl+Home/End tree edge; Right expand-or-descend; |
|                | Left collapse-or-ascend; Enter toggle; Ctrl+F; chars → search |
| SearchPanel    | Tab/Shift+Tab → edit/results; Esc → close; Enter → first result|
| Checkbox       | Space / Enter → toggle                                        |
| Slider         | Left/Right step; PgUp/PgDn page; Home/End bounds; all consume even at bounds |
| EditBox        | Enter → BeginEdit/Commit (EnterToCommit=false makes Enter bubble); Esc → Cancel; full text-editing set |
| TabControl     | Ctrl+Tab / Ctrl+Shift+Tab → cycle pages                       |
| Tab strip      | Left / Right (via HorizontalList) cycles tabs and switches    |
| Dropdown       | Closed: Enter → open. Open: List nav on inner items;           |
|                | Enter on item → commit + close; Esc → close without commit     |
| Table          | Up/Down → within tier; Left/Right → across tiers; Home/End →  |
|                | tier edge; Ctrl+Home/End → table edge; Ctrl+Left/Right → column |
