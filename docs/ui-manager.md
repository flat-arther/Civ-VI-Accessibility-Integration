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
├── ContainerWidget            navigable parent
│   ├── PanelWidget
│   ├── DialogWidget
│   ├── ListWidget
│   ├── HorizontalListWidget
│   ├── SubMenuWidget
│   ├── TreeWidget
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

### Direction semantics

- `direction = 1` (forward / Tab / Down / Right / PgDn): entering a container
  lands on its first visible child.
- `direction = -1` (backward / Shift+Tab / Up / Left / PgUp): entering a
  container lands on its last visible child.
- `direction = nil/0` (programmatic): entering a container lands on its
  cached default child.

This is the **only** place Windows tab-stop convention kicks in. After a
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

A screen that is itself about to move focus elsewhere after a rebuild (e.g. the
diplomacy ActionView rebuilds its statement list inside `SelectPlayer` and then
hands focus to the conversation list) should skip the restore for that pass —
pass a `nil` capture so `RestoreFocus` no-ops — rather than relying on a silent
restore. The default restore is meant to speak.

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
row is the canonical example.

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
  for the interrupting feel.

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
  `Commit` runs the same setter on Enter.

For EditBox: the buffer/commit phase is internal. Per-keystroke editing
mutates `_buffer` only — no events fire. `Commit()` promotes the buffer to
`_value`, calls the setter, and emits `value_changed` once. The convention
for distinguishing user commits from programmatic refresh is the `silent`
flag on `SetText` / `SetValue`: refresh calls pass `silent=true` and emit
nothing; user commits run non-silent and fire `value_changed`.

Direct methods are preferred over string-dispatched actions. EditBox exposes
`BeginEdit`, `Commit`, `Cancel`. Checkbox: `Toggle`, `SetChecked`. Slider:
`Increment`, `Decrement`, `PageIncrement`, `PageDecrement`. Dropdown:
`SetOptions`, `SetSelectedIndex`, `GetSelectedIndex`, `Commit`, `Open`,
`Close`, `IsOpen`.

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
calls its `Action(self)` — return true to consume.

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

Trees navigate **flat**, not by sibling. The helper module
`CAIWidgetHelpers_Tree`:

- `Flatten(root)` — pre-order list of every visible TreeItem reachable from
  root, descending only into expanded nodes.
- `NavigateFlat(root, dir)` — Up/Down moves through the flat list.
- `NavigatePage(root, dir, pageSize)` — PgUp/PgDn jumps PageSize positions.
- `NavigateFirst/Last(root)` — Home/End.
- `ExpandOrDescend(root)` — Right key: expand if collapsed; descend to first
  child if already expanded.
- `CollapseOrAscend(root)` — Left key: collapse if expanded; jump to parent
  TreeItem if collapsed.
- `ToggleFocused(root)` — Enter key on Tree: toggle focused item's expand
  state. Bubbles only when the focused item has no `activate` listener.

### Type-to-find search

`CAIWidgetHelpers_Search.HandleChar(root, char, maxDepth)`:

- Appends the char to `Manager.SearchBuffer`, with a 1-second timeout reset.
- DFS from root to find the first widget whose label (lowercased) starts with
  the buffer, depth-limited.
- Cycles forward — search starts after the currently focused child.
- **Same-letter cycling**: pressing the same single letter twice within the
  timeout doesn't extend the buffer. The next search starts after the focused
  match, cycling through every item starting with that letter. Matches the
  JAWS/NVDA convention.

Wire it up on a container:

```lua
function MyList:OnCharInput(char)
    return CAIWidgetHelpers_Search.HandleChar(self, char, self.SearchDepth)
end
```

`SearchDepth` defaults: List = 2, Tree = 3.

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
check:SetValueGetter(function() return vanillaCheck:IsChecked() end)
check:On("value_changed", function(_, _) vanillaCheck:CallCallback("CheckHandler") end)
```

For edit boxes wrapping a vanilla `EditBox`:

```lua
edit:SetText(vanillaEdit:GetText() or "", true)
edit:SetValueSetter(function(_, text) vanillaEdit:SetText(text) end)
-- (SetValueSetter is also called on Commit, so no separate commit handler is needed)
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
| EditBoxWidget  | value_changed (on Commit only — no per-keystroke event) |
| TreeItemWidget | activate (leaf only), expanded, collapsed      |
| SubMenuWidget  | expanded, collapsed                            |
| TabControlWidget | value_changed (page index)                   |
| (all)          | focus_enter, focus_leave, destroy              |

---

## 19. Reference: bindings on each widget

| Widget         | Keys                                                          |
|----------------|---------------------------------------------------------------|
| Button         | Enter, Space → activate                                       |
| MenuItem       | Enter → activate                                              |
| Panel          | Tab / Shift+Tab → next/prev                                   |
| Dialog         | Tab / Shift+Tab / Up / Down → next/prev row; Enter → default  |
| Dialog buttons | Left / Right / Up / Down → cycle (sticky)                     |
| List           | Up/Down/Home/End/PgUp/PgDn; chars → search                    |
| HorizontalList | Left/Right/Home/End/PgUp/PgDn                                 |
| SubMenu        | Enter / Right → expand-enter; Left → collapse-exit;            |
|                | when expanded: Up/Down/Home/End/PgUp/PgDn                     |
| Tree           | Up/Down/Home/End/PgUp/PgDn flat; Right expand-or-descend;     |
|                | Left collapse-or-ascend; Enter toggle/activate; chars → search|
| Checkbox       | Space / Enter → toggle                                        |
| Slider         | Left/Right step; PgUp/PgDn page; Home/End bounds              |
| EditBox        | Enter → BeginEdit/Commit; Esc → Cancel; full text-editing set |
| TabControl     | Ctrl+Tab / Ctrl+Shift+Tab → cycle pages                       |
| Tab strip      | Left / Right (via HorizontalList) cycles tabs and switches    |
| Dropdown       | Closed: Enter → open. Open: List nav on inner items;           |
|                | Enter on item → commit + close; Esc → close without commit     |
| Table          | Up/Down → within tier; Left/Right → across tiers; Home/End →  |
|                | tier edge; Ctrl+Home/End → table edge; Ctrl+Left/Right → column |
