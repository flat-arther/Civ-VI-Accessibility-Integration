# World Builder

Investigation notes and CAI design direction for Civ VI's World Builder. Source of truth for how the vanilla editor is structured and the decisions we've made for accessibility.

## What World Builder is

A map/scenario editor overlaid on the live game map. It is **not** a gameplay context.

- Runs in a single interface mode, `InterfaceModeTypes.WB_SELECT_PLOT`, for its entire lifetime. Both editor panels force this mode on show and never leave it; the parent context bulk-hides the whole HUD.
- The only input the mode handles is plot editing: `WorldInput.lua` registers just `OnMouseEnd/RButtonDown/RButtonUp/MouseMove_WBSelectPlot`, which fire `LuaEvents.WorldInput_WBSelectPlot(plotID, edge, lbutton, rbutton)` and `LuaEvents.WorldInput_WBMouseOverPlot(plotID)`.
- **No gameplay preview.** There is no unit selection, no unit movement/pathing, no `SELECT_UNIT` mode, no ActionPanel/end-turn, no combat, no turn processing. Units you "place" are static map data (type, owner, position). To actually play a map you save it and start a real game from it.

Implication for CAI: treat this as a **static data editor**. None of the unit-selection / movement / waypoint / recommendation machinery applies here. The CAI cursor is purely an editor plot cursor — there is no live unit selection to reconcile with.

## Firm decisions

- **CAI always runs World Builder in Advanced mode.** Pin `WorldBuilder.SetWBAdvancedMode(true)` whenever CAI is active. Basic/Advanced is purely UI-gating (hides fields, swaps the goody-hut/improvements icon, disables a few edit boxes). Advanced is a strict superset, so forcing it gives one code path with every field present and no live "is this hidden right now" branching. The only extras Advanced exposes are the full improvements list (which already includes goody huts) and the ruleset/map-script/"is a mod" packaging fields — both harmless to expose.
- **Unify the tile-editing surfaces; keep Players and Map as siblings.** See "CAI design direction" below.

## Vanilla file map

- `WorldBuilder.lua` / `.xml` — parent context. Pause menu, undo/redo hotkeys (Ctrl+Z, Ctrl+Shift+Z / Ctrl+Y), bulk-hide of HUD/WorldViewControls for the fullscreen map.
- `WorldBuilderLaunchBar.lua` — bottom bar: Player Editor / Map Editor / Menu buttons, plus the **StatusLine** text field. That status line is the primary feedback channel — every action writes a localized result there via `LuaEvents.WorldBuilder_SetPlacementStatus` (e.g. "Ocean placed", "River: invalid location", "Undo", "Already exists"). PlayerEditor button hidden unless Advanced.
- `WorldBuilderToolsPalette.lua` — upper-left tool picker (16 tools + Basic/Advanced toggle). Tool metadata table `m_kToolData` carries each tool's ID, icon, hotkey, `IsAdvanced`, `PlacementFunc`, and `PlacementValid`.
- `WorldBuilderMapTools.lua` / `.xml` — container holding a two-tab TabControl: the Placement panel and the Plot Editor panel. Owns the TabHeader label.
- `WorldBuilderPlacement.lua` — the paint/brush workflow.
- `WorldBuilderPlotEditor.lua` — the single-plot inspect-and-edit workflow.
- `WorldBuilderMapEditor.lua` — modal, map-level metadata.
- `WorldBuilderPlayerEditor.lua` — modal, players/cities (Advanced only).
- `FrontEnd/WorldBuilderMenu.lua` — main-menu entry path; flips `GameConfiguration.SetWorldBuilderEditor(true)` and launches the editor (new map or import via `WBImport.lua`).

## Two editing paradigms

Everything hinges on the two tabs in MapTools, both acting on the same underlying `WorldBuilder.MapManager()` data:

1. **Placement ("paint") tab.** Pick a tool + a sub-item (an icon grid), then left-click a hex to add, right-click to remove. Continuous: holding and dragging paints across hexes. Edits batch into undo blocks (~800–1000 ops per block).
2. **Plot Editor ("select") tab.** Left-click one hex; a form of pulldowns appears for exactly that plot. One tile at a time, precise dropdowns, no brush.

### Brushes

The vanilla "brush" is a **parameter plus a fan-out loop**, not a data-layer gesture. `m_BrushSize` is 1 / 7 / 19; `PlacementFunc` places the center then iterates the ring(s) itself.

- Small = 1 hex, Medium = 7 (center + 6 adjacent), Large = 19 (center + two rings).
- Brushes are **only enabled for the Terrain and Continents tools**. Every other tool forces size 1 and disables the brush buttons.
- Mouse-over highlights valid target hexes green (`MOVEMENT`) and invalid ones red (`ATTACK`), previewing the whole brush footprint.

### Placement vs drawing

Mostly placement, two exceptions:

- **Terrain/Continents** feel like painting (brush + click-drag).
- **Rivers and Cliffs are edge-based** — the closest thing to drawing. Vanilla force-enables the grid and reads `GetCursorNearestPlotEdge`; you click near a hex edge to toggle a river/cliff segment along it (validated: joining rivers, splitting, must be near water, etc.).

Everything else is "select an item, click a hex."

Smart auto-cleanup runs throughout: painting ocean adds coast to neighbors; painting land beside ocean converts it to coast and may add cliffs; changing terrain strips now-invalid features/resources/improvements; removing a river removes orphaned floodplains. Plus whole-map Generate / Clear resources, feature rotation for directional wonders, and global undo/redo.

## Basic vs Advanced (reference)

Kept for completeness; CAI ignores this split and forces Advanced.

- Toggle in the tools palette (`ToggleAdvanced`, confirm popup), backed by `WorldBuilder.GetWBAdvancedMode()`, fires `LuaEvents.WorldBuilder_ModeChanged()`. Panels listen and show/hide fields.
- **Basic = physical map:** Terrain, Features, Wonders, Continents, Rivers, Cliffs, Resources, Goody Huts. Plot Editor shows only Terrain, Feature, Feature Direction, Resource (+ amount), Coastal Lowland.
- **Advanced = scenario authoring (superset):** adds Cities, Districts, Buildings, Units, Routes, Start Positions, Ownership, Visibility; full Improvements list (slot 8 icon/tooltip swaps from Goody Huts); Plot Editor adds Improvement, District, Route, Owner, Start Position; the whole Player Editor; and Map Editor Mod tab + ruleset/map-script/"is a mod" packaging. Switching back to Basic while on an advanced tool auto-jumps to Terrain.

## Surface inventory

### Tools Palette
Mode selector only: 16 tools (Terrain, Features, Wonders, Continents, Rivers, Cliffs, Resources, Improvements/GoodyHuts, Cities, Districts, Buildings, Units, Routes, Start Positions, Ownership, Visibility) + Basic/Advanced toggle + undo/redo.

### Placement panel
Per selected tool: an icon grid of that tool's items (terrain types, features, wonders, resources, districts, buildings, units, improvements), plus tool-specific extras:
- Continents: continent pulldown
- Resources: strategic-amount box; whole-map Generate / Clear Resources buttons
- Brush size buttons (Terrain/Continents only)
- Feature rotation (rotate left/right + direction readout)
- Start Positions: player pulldown
- Cities: city-owner pulldown
- Units: unit-owner pulldown
- Districts: pillaged check
- Ownership: owner pulldown
- Visibility: player pulldown + Reveal All button

### Plot Editor (one focused hex)
Coordinates label, then pulldowns: Terrain; Feature; Feature Direction; Resource (+ amount); Improvement (+ pillaged); District (+ pillaged); Route (+ pillaged); Owner (city); Start Position (type + player/leader/civ sub-pulldown); Coastal Lowland (GS). Same data the Placement tools write, one tile at a time.

### Map Editor (modal)
Map-level metadata, not tile-scoped.
- General: map ID (+ generate new), width/height (read-only), ruleset, map script, reference-image path + alpha, "is a mod" checkbox.
- Mod tab.
- Text: per-language localization editor — language pulldown, key/string list, add/remove entries, edit tag + string. Where scenario text lives.

### Player Editor (modal)
A players hierarchy:
- Player list: add player, add AI, remove.
- Per player: General (civ, leader, era, gold, civ level); Techs page and Civics page (grant/revoke); Cities page (new/remove city) → per-city General (name, population), Districts, Buildings.

## CAI design direction

The map cursor is the hub — reading a hex already surfaces its full state via the existing plot-tooltip / interface-info path, which is the same data as the Plot Editor's read side.

**Collapse the tile-editing surfaces into cursor + tool + one form.** Placement tools, the Plot Editor form, and the plot tooltip are all editing one tile; unify them:
- A **tool & item picker** (one list: pick tool → pick item), then Enter paints the current hex. Absorbs the Tools Palette and every Placement item grid.
- An **"edit this tile" panel** — the Plot Editor form pushed on demand for the focused hex, for precise single-tile work.
- Both act on the same cursor and the same `WorldBuilder.MapManager()` calls, so "paint many" and "edit one" become two verbs on one cursor rather than separate screens.

**Keep Players and Map as their own pushed screens** under one WB root menu — different domains, not tile-scoped. Player Editor fits `TreeWidget` (players → cities → districts/buildings); Map Editor is a short form + the text-table editor.

**Unified shape:** one World Builder root (one hotkey/launch) offering Tool & item picker, Edit focused tile, Players…, Map settings…, and whole-map ops (generate/clear resources, undo/redo). The map cursor with place/delete keys does actual placement inline like the rest of CAI.

### Brush / multiplace plan

The event signature is `(plotID, edge, lbutton, rbutton)` — Enter → add (lbutton), a separate delete key → remove (rbutton). Plan two activation keys per tool.

1. **Brush size as a cycled, announced setting.** One key cycles Small(1)/Medium(7)/Large(19), spoken ("Brush: medium, 7 tiles"). Mirror vanilla gating: only live for Terrain/Continents; elsewhere fixed at single-tile. Enter respects the current size — zero-cost multiplace, faithful to vanilla.
2. **A "paint mode" toggle** — the accessible replacement for click-drag. Toggle on: every cursor move auto-places the current tool+item on the hex you land on (delete key paint-erases); toggle off to stop. Works for every tool, reuses the existing directional cursor keys unchanged. Announce each placement's status line (queued, non-interrupting, per the no-interrupt speech rule).
3. **Two-point fill (later).** Mark an anchor hex, move to a second hex, Enter fills the line/region between. Most efficient for large areas and straight features; most code (region/line math). Treat as a later add-on.

**Rivers and Cliffs** are edge-based, so "place on current hex" doesn't apply. Reuse the six directional keys (NW/NE/E/SE/SW/W) as edge pickers: cursor on a hex, press a direction to toggle the river/cliff on that shared edge. Natural accessible model for the closest-to-drawing tools.

Ship brush-size cycling + paint-mode toggle first (they cover both vanilla multiplace paths), keep the delete key explicit, handle rivers/cliffs as directional edge toggles, hold two-point fill for later.

## Implementation status

### Shared CAI systems now reach WB — FIXED (two layers).

World Builder has **no local player** (`Game.GetLocalPlayer()` returns nil/-1; no vanilla WB file references it). Two things blocked the shared systems there:

1. **Input dispatch gate.** `DispatchInputAction` bailed unless `m_caiGameViewWidget` was set; in WB only `m_caiWorldBuilderWidget` exists. Now gates on `m_caiGameViewWidget or m_caiWorldBuilderWidget`, so all `Events.InputActionStarted` CAI actions dispatch. (The WB widget's own manager bindings, e.g. Tab → tools panel, always worked.)

2. **Per-player state never created.** Cursor, message buffer, scanner, and reveal all build state through the shared `PlayerStateManager` (`PlayerStateManager_CAI.lua`), keyed on `GetActivePlayerID()` → `Game.GetLocalPlayer()` → nil in WB → `Get()` rejects it (`< 0`), so nothing initialized. Fixed with an **observer fallback**: new `GetViewingPlayerID()` / `IsObserverView()` in `caiUtils.lua`. When there's no local player it returns the observer, and `PlayerTypes.OBSERVER` is the positive sentinel `1000` — a stable, valid state key (`Players[1000]` is nil, and visibility code already treats `== OBSERVER` as see-all). `PlayerStateManager`, the scanner context, and reveal now key on this, so all four systems initialize in WB/observer.

**Ownership under an observer collapses to neutral** (observers own nothing and see everything). `IsObserverView()` gates the classifiers: Surveyor `IsOwnOrTeamUnit` → false, `IsKnownPlayer` → true, resources → see-all; the World Scanner's `Utils.CanKnowPlayer` → true. Player-relative stance collapses to neutral, **but barbarians stay enemy** — they're classified by what they are, not relative to a viewer: Surveyor `IsEnemyUnit`/`IsNeutralUnit`, the units category `GetUnitCategoryId`, and `Utils.GetTeamStance` all keep the `IsBarbarian()` → enemy branch under an observer. So the scanner/surveyor list human/AI units and cities under neutral and barbarians under enemy, with no "own" bucket. Reveal keys on the observer but has nothing to announce in a fully-revealed map. Cursor audio (`cursorAudio_CAI.lua`) also gated its terrain/fog sounds on `IsPlotRevealed`/`IsPlotVisible` via the local player, so it was silent under an observer; both now return see-all when `IsObserverView()`.

### Placement tools panel — BUILT (picker + host, no placement bridge). Needs in-game test.

`src/UI/inGame/WorldBuilderPlacement_CAI.lua` (ReplaceUIScript on `WorldBuilderPlacement`). One pushed `Panel`: a `List` of the 16 tools (advanced order) over a transparent settings container that rebuilds per armed tool. Focus-enter a tool row arms it (`OnToolSelectMode`); Enter on a tool row closes. Tab order per tool = item **Type** first, then extras (brush / rotation / amount+generate+clear / pillaged / owner|player|continent|route / reveal-all); Rivers & Cliffs have no settings. Every choice field — the item Type and the continent/route/owner/player pickers alike — is a **Dropdown**, not a commit-on-focus list, so navigating options never changes the selection by accident; only opening a dropdown and activating an option commits. The Type dropdown seeds to the item vanilla currently has selected. Opened by **Tab** via the placement context's own input handler (+ `LuaEvents.CAIWorldBuilderTools_Toggle`); panel nav rides `WorldInput_CAI`'s existing world→`mgr:HandleInput` forwarding. 15 `LOC_CAI_WB_*` tags in all 6 languages.

- **Tool row readout = name + every selected param, read live.** `BuildToolParamString` reads the armed tool's full selection each time the focused row's label is built (type via the selected grid item's `Active` overlay; owner/player/continent/route via the vanilla pulldown's `GetSelectedEntry`; brush/rotation from CAI mirrors; amount when the strategic field is shown; pillaged when checked). This replaced a single `m_lastItemLabel[toolID]` that only held the last field changed (so "Units, Japan" instead of "Units, AT Crew, Japan"). Live-read is correct on first open with no user change because focus-enter arms the tool (running `RebuildSettings`, refilling `m_capture`) before the manager builds the row's speech — only the focused (= armed) row's label is ever read.
- **Opens on the currently-armed tool,** not always the first row: `OpenPanel` pushes with `focus = "caiwb:tool:"..GetSelectedEntry().ID` so reopening lands where the user left off.

### Key mechanism — reading/writing vanilla's locked item selection

Vanilla keeps every grid tool's item list and `SelectedIndex` in **file-locals** (`m_TerrainTypeData` … `m_ImprovementTypeData`) with **no public setter** for 6 of the 8 grid tools. Cross-context CAI code (which `include`s the base and can only reach its *global* functions) therefore cannot set the selection directly. Solution:

- **Capture, don't reach in.** `WrapFunc` the global `MakeItem` (called by `MakeItemGrid` for every grid item as the grid rebuilds). Its args are effectively `(itemIndex, icon, localizedLabel, selectClosure)` — the closure sets `srcTable.SelectedIndex = idx`, updates the highlight, and fires `SelectedCallback`. Capturing `{idx, label, selectClosure}` per call yields the full ordered item list *and* a click-equivalent setter, without positional `GetChildren` indexing (which returns hidden leftovers) or a `CallCallback` idiom (unused in CAI). Reset the capture at the top of the wrapped `OnPlacementTypeSelected`; it refills during `orig`.
- **Live mode + PlacementFunc** come from `Controls.PlacementPullDown:GetSelectedEntry()` (a real control) — the returned entry table still carries `.ID` and `.PlacementFunc`, exactly as vanilla's own `OnPlotSelected` reads them.
- **Named controls** (brush buttons, generate/clear, reveal-all, pillaged checks) are driven with `control:DoLeftClick()` (the sanctioned CAI idiom, per `docs/ui-manager.md` §14); rotation via the global `OnRotateLeft/Right`.
- **Pulldown-backed tools** (continents/routes/players/cities) re-derive their option lists from the same `GameInfo`/`WorldBuilder.PlayerManager()` sources vanilla uses (same order ⇒ index parity) and commit through `Controls.*PullDown:SetSelectedIndex(i, true)`.

### Place / delete bridge — BUILT (single-tile). Needs in-game test.

The World Builder interface widget (`m_caiWorldBuilderWidget` in `WorldInput_CAI.lua`) carries three **direct input bindings** (not rebindable input actions — World Builder has no rebindable CAI actions):

- **Enter (primary) → place.** `WBEditCursorPlot(true)` fires the `LuaEvents.WorldInput_WBSelectPlot(plot, edge, true, false)` + `(…, false, false)` pair — the exact LButtonUp sequence vanilla's WorldInput fires. That runs the armed tool's `PlacementFunc` with `bAdd=true` inside one undo block. Brush size is read inside vanilla `OnPlotSelected` from placement's own state (driven by the CAI tools panel), so a place honours the current brush with no extra work.
- **Delete → remove.** `WBEditCursorPlot(false)` fires the RButtonDown/RButtonUp pair `(…, true, true)` + `(…, false, true)`, running `PlacementFunc` with `bAdd=false`. Map-pin deletion (Delete's usual binding) does not apply in World Builder.
- **Ctrl+Enter (secondary) → edit tile.** STUBBED: raises `LuaEvents.CAIWorldBuilderPlotEditor_Toggle(plotID)` for the cursor plot. The CAI Plot Editor form that consumes it is not built yet, so this key is currently inert. Note vanilla's Plot Editor `OnPlotSelected` only runs while its *tab* is visible, so editing cannot reuse the placement bridge — it needs our own pushed form.

The cursor plot comes from `GetCurrentCAICursorPlotId()`; `edge` is `UI.GetCursorNearestPlotEdge()` (unused by non-edge tools). Because these fire the placement event, the Placement tab must stay the visible MapTools tab (it is — CAI never switches to the Plot Editor tab).

### Placement preview + feedback — BUILT. Needs in-game test.

Two channels, mirroring how vanilla surfaces placement info:

- **Pre-placement validity (on the InterfaceInfo key), the accessible replacement for the green/red mouse-over highlight.** Vanilla's highlight is `PlacementValid(plotID, mode)` → green (valid) / red (invalid); `mode = Controls.PlacementPullDown:GetSelectedEntry()` already encodes tool + item + rotation, so it's **one call for every tool, no per-tool branch**. `PlacementValid` and the pulldown live in the placement context, which `interfaceInfoHelpers_CAI` (WorldInput context) can't reach, so `WorldBuilderPlacement_CAI` publishes `ExposedMembers.CAIInfo.GetWorldBuilderPlacementValidity(plotId)` returning `{ valid, footprint, brushValid?, brushTotal? }` (data only; the helper localizes). `interfaceInfoHelpers_CAI` registers **one** helper on `InterfaceModeTypes.WB_SELECT_PLOT` (all WB tools share that mode) that speaks Valid/Invalid + footprint (multi-tile wonders via `aValidPlots`) + brush count (Terrain/Continents only, computed by a distance≤2 ring gather — vanilla's `m_19HexTable` is an unreachable placement-context local). Read at the **cursor**, so you can roam and probe tiles. Rivers have no validator (`PlacementValid` → true ⇒ always "Valid"); cliffs have one; full edge-aware preview is deferred with the edge tools.
- **Post-placement reason (spoken automatically), the reason text `PlacementValid` never gives.** Vanilla writes every result ("Ocean placed", "Wonder too close", "Requires higher tech", "Undo") to `Controls.StatusLine` via `OnSetPlacementStatus` in `WorldBuilderLaunchBar.lua`. New `WorldBuilderLaunchBar_CAI.lua` (ReplaceUIScript on `WorldBuilderLaunchBar`) removes the base listener, `WrapFunc`s `OnSetPlacementStatus` (call `orig`, then `Speak(Controls.StatusLine:GetText())`), and re-adds it. De-dupe is **per keypress, not global**: `WBEditCursorPlot` fires `LuaEvents.CAIWorldBuilderStatusBurstBegin` before each place/delete, which resets the last-spoken text — so a brush stroke's repeated identical statuses within one keypress collapse, but pressing Enter twice on the same failure ("Couldn't place X here") speaks both times.

### Locked placement source ("mark") — BUILT. Needs in-game test.

`M` (direct binding on the WB widget, map pins don't apply in WB) toggles `m_wbMarkedPlotId` between the current cursor tile and nil, announced. When set, place / remove / edit act on the marked tile via `WBPlacementSourcePlot()` (`m_wbMarkedPlotId or cursor`) instead of the live cursor — so the cursor can roam and read validity of other tiles (InterfaceInfo key) without moving where edits land. Placement validity is always read at the cursor; only the edit *source* respects the mark.

### Map-tack hotkeys moved out of WorldInput

The map-pin / minimap-list input-action listeners (place pin `M`, lens list, map-pin list) were moved from `WorldInput_CAI` into the map-tacks UI (`MapPinListPanel_CAI`, which already owns `m_mapPinActions` incl. `CAIDeleteMapTac`). `WorldInput_CAI` runs in World Builder too, so those listeners there collided with the WB cursor keys (`M` mark, `Delete` remove). `MapPinListPanel_CAI`'s `OnMapPinInputActionStarted` now early-outs when `GameConfiguration.IsWorldBuilderEditor()`, so none of the map-tack hotkeys fire in WB. `PlaceMapPin` is a vanilla `WorldInput` global, so it's invoked across the context boundary via `LuaEvents.CAIRequestPlaceMapPin` (bridged in `WorldInput_CAI`).

### Advanced mode now actually forced — FIXED

The "always Advanced" firm decision was documented but never implemented (no `SetWBAdvancedMode` call existed). Symptom: the Improvements tool placed **tribal villages** regardless of the chosen item — in Basic mode that slot *is* the Goody Huts tool (`PlacementFunc = PlaceGoodyHut`). Fix: `WorldBuilderToolsPalette_CAI.lua` calls `SetAdvancedMode(true)` after the base `include` (vanilla `Initialize()` ran `SetAdvancedMode(false)` during it). `SetAdvancedMode` flips the engine flag and fires `WorldBuilder_ModeChanged`, so the placement/plot-editor contexts repopulate with the full advanced lists. Guarded with `if not WorldBuilder.GetWBAdvancedMode()`.

### Plot tooltip: WB info + real coordinates — BUILT. Needs in-game test.

- **Coordinates:** `HexCoordUtils.coordinateString` returned capital-relative offsets and produced `""` in WB (no local player/capital). Now, when `WorldBuilder.IsActive()`, it returns the map's **actual `x, y`**. Covers both the cursor-move coordinate readout and the `PlotReadRelativeCoords` action.
- **`wbStartPosition`** in `PlotToolTip_CAI.lua`, gated on `GameConfiguration.IsWorldBuilderEditor()`, appended at the **end** of the cursor-move + default priority lists (self-gating, inert outside WB): `WorldBuilder.PlayerManager():GetStartPositionInfo(index)` → player/leader/civ name. Tag `LOC_CAI_WB_TT_START_POSITION` in all 6 languages.
- **Visibility: no Lua read path exists — CONFIRMED, feature parked.** Vanilla shows visibility as **one selected player's fog** (Set Visibility tool + preview player; no all-players view, no green/red overlay). The revealed data is **C++-render-only**: verified in-game that with the tool set to Norway, Norway's fog renders correctly, yet `PlayerVisibilityManager.GetPlayerVisibility(Norway):IsRevealed` returns false for those same revealed tiles — the gameplay visibility layer never sees WB's `SetRevealed`. And there is **no revealed getter anywhere**: not on `Plot` (90 methods), `Map`, or any WB manager (`MapManager` only has `SetRevealed`/`SetAllRevealed` + generic `GetPlotValue`/`SetPlotValue`; revealed is not written via `SetPlotValue` so `GetPlotValue` can't read it). Attempting to gate the fog helper on the selected player therefore suppressed ALL plot info behind "Uncharted Territory" (since the read is always false), so that change was reverted — `IsPlotVisible`/`IsPlotFogged` are back to the local-observer (see-all) behavior. `GetPlotValue` was tested in-game (a real-method probe): it returns a constant `0` for every argument shape/key and `Plot:GetProperty('Revealed')` is `nil` — no Lua read path exists. So visibility is recorded **on the plot itself** via `Plot:SetProperty`/`GetProperty` — the persistent per-plot store that saves with the map, so it survives save/load (a Lua-side session table would not). BUILT, needs in-game test:
- **Storage** (`WorldBuilderPlacement_CAI`): a per-player plot property `CAI_WB_REVEALED_P<player>` = 1 (revealed) / 0 (hidden), absent = not revealed. Accessors on `CAIInfo`: `SetWorldBuilderRevealed(player, plot, bAdd)` (`plot:SetProperty`), `GetWorldBuilderRevealed(player, plot)` (`plot:GetProperty == 1`), `SetWorldBuilderRevealedAll(player)` (writes the property to every plot, mirroring the vanilla Reveal All), and `GetWorldBuilderVisibilityPlayer()` (the tool's selected player, nil unless SET_VISIBILITY is armed).
- **Writers:** `WBEditCursorPlot` (WorldInput_CAI) writes the property on each reveal/hide when the Visibility tool is armed; the panel's Reveal All button calls `SetWorldBuilderRevealedAll`.
- **Reader:** `info.IsPlotVisible`/`IsPlotFogged` (PlotToolTip) gate on `GetWorldBuilderRevealed` for the selected player while WB + Visibility tool are active → unrevealed plots read as fog-of-war (terrain hidden), like the sighted single-player fog; `IsPlotFogged` is always false in that mode; otherwise both fall back to the local observer (see-all).
- **VERIFY:** that Plot properties persist through a WB map save/load (the whole reason for this approach). If they do not, revisit. Also still can't see reveals a sighted user makes by mouse (those bypass CAI), though those would set the vanilla revealed state, not our property. `wbStartPosition` and real coordinates are unaffected.

### Map Editor — BUILT. Needs in-game test.

`src/UI/inGame/WorldBuilderMapEditor_CAI.lua` (ReplaceUIScript on `WorldBuilderMapEditor`; LuaContext is the LuaContext **ID** `WorldBuilderMapEditor`, i.e. the Lua FileName, not the XML `<Context Name>` `WorldBuilderMapModEditor`). Includes the base, hooks `LuaEvents.WorldBuilder_ShowMapEditor` to push/tear-down one CAI `Panel` mirroring the vanilla modal's open/close (the launch-bar button toggles via `WorldBuilder.lua` → this event). **Opened by `F1`:** `WorldBuilderLaunchBar_CAI` adds the launch bar's only input handler, which on `F1` KeyUp fires the base `OnOpenMapEditor()` (identical to clicking the button) — but only while the focused widget's id is `CAIWorldBuilderMode` (the World Builder map interface widget created in `WorldInput_CAI`), so the shortcut is inert inside any pushed CAI panel/screen. A `TabControl` with **two** pages — General and Text. **No Mod tab:** vanilla's third tab (Advanced only) is genuinely empty — `ViewMapModPage`/`UpdateModPage` and the `ModInstance` XML have zero controls — so it's a blank panel with nothing to expose.

- **General page:** a **Map metadata `List`** (label `LOC_CAI_WB_MAP_METADATA`) of the read-only details — ID (a **Button** whose label reads "ID: <value>", tooltip `LOC_CAI_WB_GENERATE_ID_TT`; activate = `SetID(GenerateID())` then re-announce), Width / Height (StaticText, from `ConfigurationManager():GetMapValues()`) — then the **Is Mod** Checkbox (→ `WorldBuilder.SetMod`), then the editable fields: Ruleset / Map Script / Reference Map / Reference Alpha (`AlwaysEdit` EditBoxes). The edit boxes **commit on Enter only** (`SetCommitOnFocusLeave(false)`), through the base's own global `On*Edited` handlers (`OnRulesetEdited`, `OnMapScriptEdited`, `OnMapReferenceEdited`, `OnMapReferenceAlphaEdited`), so validation and the reference-map/alpha status-line feedback (spoken by `WorldBuilderLaunchBar_CAI`) are vanilla's. **No max-length or numeric restriction** on any General field — matching vanilla exactly (its General boxes are plain `EditMode="1"`; Reference Alpha is not numeric-input-restricted, it's validated on commit via `tonumber` + 0..1 range → status line). The only vanilla `SetMaxCharacters` is 64 on the Text-tab tag/string boxes, replicated as `MAX_TEXT_CHARS`. Each commit first fires `LuaEvents.CAIWorldBuilderStatusBurstBegin` to reset the launch bar's status-line de-dupe, so committing the same value twice (e.g. a repeated "Reference map file not found") is spoken each time rather than swallowed as a duplicate. Reference map/alpha are a sighted visual-tracing aid with no accessible payoff but are exposed for full parity; the path field seeds empty because the base's `m_ReferenceMapName` is an unreachable file-local.
- **Text page = language Dropdown + entry List + Add button.** The list is re-derived from `WorldBuilder.ModManager():GetKeyStringPairByIndex(i, lang)` (index parity, no reaching into the base's per-tab control instances — which exist only while their tab is the one currently built). **System entries (1–4)** read their specific annotation (`MAPEDIT_MODTITLE/MODDESC/MAPTITLE/MAPDESC`); **custom entries (5+)** read their **localization tag (unique key)** since they'd otherwise all share one generic annotation. That generic annotation (`MAPEDIT_ADDLDATA`, "for mod creator's use (optional)") is instead the **Add button's tooltip**. The string value follows the head when present. **Delete** on a row removes it via `RemoveString` — bound only on rows ≥ 5, honoring vanilla's disabled Remove for the four system slots. **Enter** opens an editor Dialog titled `LOC_CAI_WB_EDIT_LOCALIZATION` (Tag + String `AlwaysEdit` boxes, `LOC_OK`/`LOC_CANCEL`); OK commits via `SetKeyStringPairByIndex` (existing) or `SetString` (new). The **Add** button below the list opens that same editor for a fresh entry, and **leaves focus on the Add button** after OK (so Shift+Tab lands on the list, not the language dropdown); an **edit** updates the captured entry so the row's live label reflects the change and just closes back onto that same row (no rebuild); **delete** rebuilds and announces the new landing once (the list is one tab-stop — from a row, Tab/Shift+Tab step to the Add button / language dropdown, arrows move between rows). The language Dropdown replicates vanilla's copy-system-strings-into-an-untranslated-language side effect (`EnsureSystemStrings`) on commit.
- Four new tags in all 6 languages: `LOC_CAI_WB_DELETE_TEXT` (row-Delete hint), `LOC_CAI_WB_EDIT_LOCALIZATION` (entry editor dialog title), `LOC_CAI_WB_MAP_METADATA` (General metadata list label), `LOC_CAI_WB_GENERATE_ID_TT` (ID button tooltip); every other field/label/tab/button label reuses existing vanilla `LOC_WORLDBUILDER_*` / `LOC_OK` / `LOC_CANCEL` / `LOC_OPTIONS_LANGUAGE` tags.
- Input rides a **wrap of the base global `OnInputHandler`** (forward to `mgr:HandleInput` while the panel is open, else `orig`) rather than a fresh `ContextPtr:SetInputHandler`, so it survives the base `OnInit` re-registering the handler after this file's top-level code runs.

### Player Editor — BUILT. Needs in-game test.

`src/UI/inGame/WorldBuilderPlayerEditor_CAI.lua` (ReplaceUIScript on `WorldBuilderPlayerEditor`; LuaContext is the Lua FileName `WorldBuilderPlayerEditor`, per `WorldBuilder.xml`'s `<LuaContext ID FileName>`). Includes the base, hooks `LuaEvents.WorldBuilder_ShowPlayerEditor` to push/tear down the CAI panels (and `WorldBuilder_ShowMapEditor` to close when the Map Editor takes over, mirroring vanilla's `OnShowMapEditor`). **Opened by `F2`:** `WorldBuilderLaunchBar_CAI`'s input handler now fires the base `OnOpenPlayerEditor()` on F2 KeyUp (alongside F1 → Map Editor), gated to when the focused widget is `CAIWorldBuilderMode` so both shortcuts are inert inside any pushed CAI panel. Input rides a wrap of the base global `OnInputHandler` (forward to `mgr:HandleInput` while the players panel is open), like the Map Editor.

**One pushed panel** holding both surfaces side by side, mirroring vanilla's single modal (list + 4-tab editor):

- **Players `List`** of open, non-barbarian slots (enumerated like vanilla `UpdatePlayerList`; row label = "Human/AI - Name"). **Add Player / Add AI are the last two rows *in* the list** (MenuItems; `AddPlayer(false/true)`, then focus the new player row); **Delete** on a player row = `UninitializePlayer`.
- **`TabControl`** as the panel's second child (so **Tab from the list lands on it**) — **General** (Civ / Leader / Civ Level / Era **Dropdowns** + Gold / Faith number EditBoxes), **Techs** and **Civics** (flat checkbox `List`s over sorted `GameInfo` rows), **Cities** (a `Tree`).

**Selection follows focus.** There is no separate detail screen: **a player is selected on its row's `focus_enter`** (guarded by `IsFocused()` and a changed index). The tab widgets are built **once** and read the live selection (`SelIndex()`); switching player is a **reseed, not a rebuild** — `RefreshDetail` re-seeds every Dropdown's selected index, the Gold/Faith text, and every tech/civic checkbox's checked state (all silent), and rebuilds the city `Tree`. Because that runs while focus is on the list, it never steals focus (the tree's `CaptureFocusKey` returns nil ⇒ `RestoreFocus` no-op). When nothing is selected (empty list) every control is disabled via its predicate.

**Dropdowns track live state.** Vanilla shows **all** leaders in the Leader pulldown (not filtered by civ) — CAI matches that. Choosing a civ sets that civ's *default leader* via `SetPlayerLeader`, which fires `WorldBuilder_PlayerEdited`; CAI listens and runs `ReseedGeneral` (re-seed the General dropdowns + Gold/Faith from the live config) for the selected player, so the Leader dropdown updates to the new default leader — exactly like vanilla's `UpdateGeneralTabValues` off the same event. Gold/Faith edit boxes are `NumbersOnly` with max length 22 (vanilla `SetNumberInput` + `MaxLength="22"`).

**Key mechanism — option lists re-derived from GameInfo.** The base keeps its civ/leader/level/era/tech/civic/district/building entry tables as file-locals (`m_CivEntries` …) with no cross-context reach, so the CAI file rebuilds them from the same `GameInfo` sources vanilla's `OnInit` uses (memoized module-level). Commits go through `WorldBuilder.PlayerManager()` (`SetPlayerLeader` / `SetPlayerEra` / `SetPlayerGold` / `SetPlayerFaith` / `SetPlayerHasTech` / `SetPlayerHasCivic`) on the live `SelIndex()` by Type/Index, exactly as vanilla's `On*Selected`. Dropdowns don't commit on focus; live disable rules mirror vanilla (Era/Gold/Faith need `IsPlayerInitialized`; Gold/Faith off for barbarians; Leader off unless `IsFullCiv`).

**Cities tree.** Each city node (label = city name; **Delete** = `CityManager():Remove`, then rebuild) expands to: a **Population `EditBox` row directly in the tree** (a plain non-`AlwaysEdit` box so Up/Down still navigate the tree — Enter begins editing, Enter commits → `SetCityValue(city,"Population",v)`, Escape cancels; `NumbersOnly` + max length 22 like vanilla `PopulationEdit`), a **Districts** subtree, and a **Buildings** subtree. (The tree's `Flatten` collects every visible child, not just `TreeItem`s, and the nav helpers treat a plain leaf as a leaf, so an EditBox is a valid tree row.) Each district/building leaf reads live state via `ItemStateLabel` — "Not added" / "Added" / "Added, Pillaged" (**pillage is display-only**, matching vanilla's read-only checkbox; `DistrictState`/`BuildingState` read `HasDistrict`/`HasBuilding` + `IsPillaged`). Enter on an **unadded** item adds it; **Delete** removes it (`RemoveDistrict(pDistrict)` / `RemoveBuilding(city, type)`, then the leaf re-announces its new state — no full rebuild since the leaf persists).

**Placement handoffs stay faithful — no camera/cursor aid.** A city and a district need a plot, so **Add City** and adding a **district** fire `LuaEvents.WorldBuilderModeChangeRequest(PLACE_CITIES / PLACE_DISTRICTS, kParams)` exactly as vanilla, which closes the editor (→ our `CloseAll` via `ShowPlayerEditor(false)`) and arms the tool on the map; the user then places with the existing place bridge. **Buildings** here are all non-placement (the list filters `RequiresPlacement ~= true`), so add is an inline `CreateBuilding(city, type, 100)`; the base global `PlacementSetResults` speaks the success/failure reason through the status line (`WorldBuilderLaunchBar_CAI`), preceded by `CAIWorldBuilderStatusBurstBegin` so the reason is never de-duped away.

- Four new tags in all 6 languages: `LOC_CAI_WB_PE_ADDED`, `LOC_CAI_WB_PE_NOT_ADDED`, `LOC_CAI_WB_PE_PILLAGED` (district/building state readout), `LOC_CAI_WB_PE_REMOVE` (Delete-binding description). Every other label/tab/button reuses existing vanilla `LOC_WORLDBUILDER_*` / `LOC_PLAYERS` / `LOC_HUD_REPORTS_HEADER_POPULATION` tags.

### Still to do

Plot Editor form (consumes `CAIWorldBuilderPlotEditor_Toggle`), then brush-size cycling + paint-mode toggle + river/cliff directional edge toggles.
