# Civ VI Game API Reference (CAI Mod)

Documented APIs used by the CAI accessibility mod. Updated as new patterns are discovered.

## Safe Mod Keys

Keys confirmed safe to bind in mods without conflicting with game defaults:

- `Keys.VK_TAB` — not bound by default in game
- `Keys.VK_HOME`, `Keys.VK_END` — not bound by default
- `Keys.VK_PRIOR` (Page Up), `Keys.VK_NEXT` (Page Down) — not bound by default
- `Keys.VK_NUMPAD1` through `Keys.VK_NUMPAD9` — hex grid navigation
- `Keys.VK_SPACE` — safe for checkbox toggle (game uses for other contexts)
- `Keys.VK_RETURN` — safe for button activation
- `Keys.VK_ESCAPE` — standard cancel/close
- `Keys.A` through `Keys.Z` — letter keys (use with IsControl for shortcuts like Ctrl+A)

## Input System

### InputStruct

Passed to input handlers. Methods:

- `input:GetKey()` — returns key code (`Keys.VK_*`)
- `input:GetMessageType()` — returns `KeyEvents.KeyDown` or `KeyEvents.KeyUp`
- `input:IsShiftDown()` — boolean
- `input:IsControlDown()` — boolean

### KeyEvents

- `KeyEvents.KeyDown` — fires on press (repeats while held)
- `KeyEvents.KeyUp` — fires once on release

### Input (global)

- `Input.GetActionId(name)` — returns numeric action ID for a named action
- `Input.GetActionCount()` — total number of registered input actions
- `Input.GetActionName(actionId)` — returns LOC key for action name
- `Input.GetActionCategory(actionId)` — returns LOC key for action category
- `Input.GetActionDescription(actionId)` — returns LOC key for action description
- `Input.ShouldShowActionKeybinding(actionId)` — whether this action appears in keybinding UI
- `Input.GetGestureDisplayString(actionId, index)` — human-readable key string for binding (index 0 = primary, 1 = alt); nil if unbound
- `Input.BindAction(actionId, index, gesture)` — binds a gesture to an action
- `Input.ClearGesture(actionId, index)` — clears a binding
- `Input.BeginRecordingGestures(exclusive)` — starts capturing key input for binding; fires `Events.InputGestureRecorded` when captured. Works at engine level below Lua input handlers.
- `Input.StopRecordingGestures()` — stops gesture capture
- `Input.ClearRecordedGestures()` — clears captured gestures
- `Input.SetActiveContext(context)` — sets the active input context (e.g. `InputContext.Startup`)

### ContextPtr

- `ContextPtr:SetInputHandler(function(input) ... end, interceptAll)` — sets the Lua input handler for this context. If `interceptAll` is true, handler receives all input before the engine. Return true to consume, false to pass through.

## Locale

- `Locale.Lookup(tag, ...)` — looks up a localized string by tag, with optional format args
- `Locale.ToUpper(str)` — uppercase
- `Locale.Compare(a, b)` — returns -1, 0, or 1

## Options

### Options (global)

- `Options.GetAppOption(category, key)` — reads an app-level option
- `Options.SetAppOption(category, key, value)` — writes an app-level option
- `Options.GetUserOption(category, key)` — reads a user-level option
- `Options.SetUserOption(category, key, value)` — writes a user-level option
- `Options.SetGraphicsOption(category, key, value, flag)` — writes a graphics option
- `Options.SetAudioOption(group, key, value, flag)` — writes an audio option
- `Options.GetAvailableDisplayAdapters()` — returns table of GPU names
- `Options.GetAvailableDisplayModes()` — returns table of `{Width, Height, RefreshRate}`
- `Options.SaveOptions()` — persists all options to disk
- `Options.RevertOptions()` — reverts to last saved state

## UI Controls

### Common Control Methods

These are methods on Civ VI's native XML-backed UI controls:

- `ctrl:GetText()` / `ctrl:SetText(str)` — text content
- `ctrl:GetToolTipString()` / `ctrl:SetToolTipString(str)` — tooltip
- `ctrl:IsHidden()` / `ctrl:SetHide(bool)` — visibility
- `ctrl:IsDisabled()` / `ctrl:SetDisabled(bool)` — disabled state
- `ctrl:IsVisible()` — true if not hidden
- `ctrl:IsSelected()` / `ctrl:SetSelected(bool)` — checkbox/toggle state
- `ctrl:IsChecked()` / `ctrl:SetCheck(bool)` — alternate checkbox API
- `ctrl:GetValue()` / `ctrl:SetValue(float)` — slider value (0.0–1.0)
- `ctrl:GetStep()` / `ctrl:GetNumSteps()` — stepped slider position
- `ctrl:SetStepAndCall(step)` — sets step and fires callback
- `ctrl:RegisterCallback(mouseEvent, fn)` — registers click/hover handlers
- `ctrl:ClearCallback(mouseEvent)` — removes a callback
- `ctrl:CalculateSize()` — recalculates layout
- `ctrl:DestroyAllChildren()` — removes all child instances

### PullDown (ComboBox) Controls

- `ctrl:GetButton()` — returns the button sub-control (has `:GetText()`, `:SetText()`)

### EditBox Controls

- `ctrl:ClearString()` — empties the text
- `ctrl:RegisterCommitCallback(fn)` — fires on Enter
- `ctrl:RegisterStringChangedCallback(fn)` — fires on text change
- `ctrl:GetText()` — current text

### Mouse Events

- `Mouse.eLClick` — left click
- `Mouse.eMouseEnter` — hover enter

## UIManager (global)

- `UIManager:SetClipboardString(str)` — copies text to the system clipboard

## InstanceManager

Used to create dynamic UI instances from XML templates:

- `InstanceManager:new(instanceName, topControlName, parentControl)` — creates a manager
- `im:GetInstance()` — allocates a new instance, returns control table
- `im:ResetInstances()` — returns all instances to pool
- `im.m_AllocatedInstances` — array of currently allocated instances

## Map & Plot

- `Map.GetPlotByIndex(plotId)` — returns a Plot object
- `plot:GetX()`, `plot:GetY()` — plot coordinates
- `Map.GetGridSize()` — returns map width and height
- `Map.GetPlot(x, y)` — returns a Plot for valid coordinates. On maps where `Map:IsWrapX()` is true, X coordinates wrap east/west, so `x = -1` resolves to the last column. Y coordinates only wrap if `Map:IsWrapY()` is true; normal Civ VI maps do not wrap north/south, so `y = -1` returns nil.
- `Map:IsWrapX()` / `Map:IsWrapY()` — return whether the active map wraps on that axis. Check these before manually wrapping absolute coordinates.
- `plot:IsRiver()` and named-river membership can be true even when the legacy edge booleans `IsNEOfRiver()`, `IsWOfRiver()`, and `IsNWOfRiver()` all report false for that same plot.
- `plot:IsFreshWater()` is the better coarse helper when CAI wants to announce settlement/fresh-water access. Use `LOC_SETTLEMENT_RECOMMENDATION_FRESH_WATER` for that spoken line rather than inferring fresh water from `IsRiver()`.
- CAI's river-edge speech model uses Civ VI's positional ownership flags:
  - this plot's `IsWOfRiver()` means the river is on this plot's `E` edge
  - this plot's `IsNWOfRiver()` means the river is on this plot's `SE` edge
  - this plot's `IsNEOfRiver()` means the river is on this plot's `SW` edge
  - this plot's `W` edge comes from the west neighbor's `IsWOfRiver()`
  - this plot's `NW` edge comes from the northwest neighbor's `IsNWOfRiver()`
  - this plot's `NE` edge comes from the northeast neighbor's `IsNEOfRiver()`
- Diagnostic logs showed `IsRiverCrossingToPlot(...)` can report river relationships even when those legacy booleans return false. Treat that as evidence that Civ VI tracks some river-topology cases outside the old edge-flag model, not as a proven replacement for the intended ownership model.
- The flow getters `GetRiverEFlowDirection()`, `GetRiverSEFlowDirection()`, and `GetRiverSWFlowDirection()` exist, but CAI's current river helper uses only edge-presence checks for direction speech.
- CAI should use the inverted positional helper above for spoken river directions rather than the older literal-edge interpretation.
- `plot:IsRiver()` is still the coarse yes/no helper and is what vanilla `PlotToolTip.lua` uses for the generic "River" line.
- In CAI plot reads, the `W` action now announces fresh water before rivers and owner so players can distinguish broad fresh-water access from actual river-edge directions.
- In Gathering Storm / Expansion 2, `PlotTooltip_Expansion2.lua` populates `data.RiverNames` from `RiverManager.GetRiverName(pPlot)`. CAI should treat that as a named-river collection shape, not as a single lookup argument, and append the computed edge-direction suffix to each named river entry individually.
- Vanilla's settler lens calls `Map.GetContinentPlotsWaterAvailability()`, which returns four explicit plot lists in this order: fresh water, coastal water, no water, and cannot-settle / blocked. `MinimapPanel.lua` colors those arrays directly for the `WaterAvailability` lens, and `ModalLensPanel.lua` / `UnitPanel.lua` supply the localized meanings.
- For Maya (`TRAIT_CIVILIZATION_MAYAB`), vanilla collapses the first three settler-lens meanings into a single "valid settling location" bucket and keeps only the blocked bucket separate.
- The shared decompiled UI still uses that same `WaterAvailability` path with expansions enabled; I did not find an XP1/XP2 branch that adds loyalty or coastal-lowland buckets to `Map.GetContinentPlotsWaterAvailability()`.
- Gathering Storm coastal-lowland state is exposed separately through `TerrainManager.GetCoastalLowlandType(plotIndex)` and `GameInfo.CoastalLowlands()`. That is a distinct API path from the settler water-availability lens.

## Events

### Engine Events (Events.*)

- `Events.InputGestureRecorded` — fired when gesture recording captures a key combo
- `Events.InputActionTriggered` — fired when a bound input action is triggered
- `Events.InterfaceModeChanged` — fired when interface mode changes (e.g. MOVE_TO)
- `Events.UserAcceptsEULA` — EULA accepted
- `Events.UserConfirmedClose` — user confirmed app exit
- `Events.UserRequestClose` — user requested app exit
- `Events.FrontEndPopup` — frontend popup requested (256 char limit)

### Lua Events (LuaEvents.*)

- `LuaEvents.CAIEndTurn` — CAI custom: triggers end turn
- `LuaEvents.CAICursorMove(x, y)` — CAI custom: public absolute cursor move event; call this instead of accessing the cursor object directly.
- `LuaEvents.CAICursorMoveDirection(direction)` — CAI custom: public directional cursor move event; calls `CAICursor:MoveToNextPlot(direction)` so Civ VI's adjacent-plot logic handles wrapping.
- `LuaEvents.CAICursorJump(plotId)` — CAI custom: public jump cursor event; resolves the target from a plot id, speaks jump direction from the old cursor plot, then moves the cursor.
- `LuaEvents.CAICursorMoved(x, y, plotId)` — CAI custom: emitted after the cursor moves; listeners should resolve the plot with `Map.GetPlotByIndex(plotId)` before reading or speaking plot info
- `LuaEvents.MainMenu_ShowAdditionalContent` — opens mods screen
- `LuaEvents.MainMenu_UserRequestClose` — main menu exit request
- `LuaEvents.MainMenu_LaunchError` — game launch error
- `LuaEvents.MultiplayerPopup` — multiplayer popup (no char limit)
- `LuaEvents.FrontEndPopup_CloseConfirmationWithoutAction` — popup closed without action
- `LuaEvents.OnRaisePopupInGame` — raises an in-game popup dialog

## ExposedMembers

Shared global table for cross-context communication:

- `ExposedMembers.CAI_UIManager` — the UIScreenManager singleton
- `ExposedMembers.CAICursor` — the navigation cursor object
- `ExposedMembers.CAICursorOverrides` — cursor coordinate override functions
- `ExposedMembers.CAI_MainGamePanel` — the root in-world CAI game panel created by `WorldInput_CAI.lua`; in-world HUD accessibility layers can attach themselves with `AddChild(...)` instead of pushing a separate screen

## CAI Custom API

### CAI (C++ bridge)

- `CAI.output(text, interrupt)` — sends text to screen reader. Always use `Speak()` wrapper instead.
- `CAI.onCharInput` — callback property. Assign a `function(char)` to receive raw character input. Called by the engine when a character key is pressed (operates alongside the regular input system). Return true to consume.
- `CAI.enableCharInput(bool)` — enables or disables the character input callback.

### Speak(text, interrupt)

Wrapper for `CAI.output`. Use this for all TTS output.

### World scanner module layout

- CAI's world scanner now lives under `src/UI/InGame/WorldScanner/`.
- Entry point: `WorldScanner_CAI.lua`
- Shared modules:
  - `WorldScannerCategoryUtils.lua`
  - `WorldScannerCore.lua`
- Category modules:
  - `WorldScannerCategory_cities.lua`
  - `WorldScannerCategory_barbarianCamps.lua`
  - `WorldScannerCategory_improvements.lua`
  - `WorldScannerCategory_terrain.lua`
  - `WorldScannerCategory_waterAvailability.lua`
  - `WorldScannerCategory_resources.lua`
  - `WorldScannerCategory_units.lua`
  - `WorldScannerCategory_validTargets.lua`
  - `WorldScannerCategory_specialMapObjects.lua`
- `WorldScanner_CAI.lua` includes the shared modules directly and then uses `include("WorldScannerCategory_", true)` so all loaded category files with that prefix are pulled in automatically, matching the vanilla late-include pattern.
- `WorldInput_CAI.lua` includes the scanner entry point and dispatches scanner input actions through `Events.InputActionTriggered`.
- `WorldInput_CAI.lua` also drives `RevealAnnouncements_CAI.UpdateVisibility()` through a `ContextPtr:SetUpdate(...)` timer hook so visibility event speech can be throttled without speaking directly inside engine callbacks.
- `RevealAnnouncements_CAI.lua` subscribes to `PlotVisibilityChanged`, `UnitVisibilityChanged`, `ImprovementVisibilityChanged`, `ResourceVisibilityChanged`, `CityVisibilityChanged`, `DistrictVisibilityChanged`, and `LocalPlayerTurnBegin`.
- All visibility callbacks refresh the same 0.5 second quiet-period timer. Plot callbacks still own the reveal/revisit plot-state buffer, while the other visibility callbacks exist so late deferred object events can extend the burst instead of letting the queue flush early.
- Reveal announcements now mirror the older Civ V-style split:
  - reveal tracks first-reveal plots separately from revisit-visible plots
  - first reveal is detected from a Lua-side `PlayerVisibility:IsRevealed(plot)` snapshot rather than a custom C++ hook
  - the reveal line speaks `<N> tiles revealed` when unexplored plots were involved, otherwise `Revealed`
  - hidden speaks as its own `Hidden: ...` line
  - gone speaks as its own `Gone: ...` line
- Unit reveal and hidden speech is snapshot-driven:
  - visibility events only refresh the shared timer
  - flush rebuilds the currently visible foreign-unit set from live unit state
  - reveal units are `current - previous`
  - hidden units are `previous - current`
  - destroyed or captured units are dropped from the hidden line by checking whether they still exist under the previous owner
  - this avoids noisy cross-map `UnitVisibilityChanged` callbacks from speaking units the player never locally saw
- First-reveal payload mirrors the older Civ V reveal model while using Civ VI's visibility APIs:
  - units can speak on first reveal or revisit, but only from the visible-unit snapshot diff
  - cities and resources speak only for first-reveal plots
  - foreign districts and foreign ordinary improvements speak only for first-reveal plots
  - city-center districts are skipped because they are redundant with city announcements
- Reveal-payload skip rules mirror the older mod logic:
  - natural wonders are excluded from the reveal payload
  - barbarian outposts and tribal villages are excluded from the reveal payload
  - own units, own cities, own districts, own improvements, teammates, and unmet foreign players are filtered out
  - foreign districts use live `plot:GetDistrictType()` / `GameInfo.Districts[...]` and skip `DISTRICT_CITY_CENTER` plus internal-only districts when detectable
  - foreign improvements use live `plot:GetImprovementType()` / `GameInfo.Improvements[...]`; ownership comes from `plot:GetImprovementOwner()`
- Gone speech is snapshot-driven for Civ VI's special removable improvements:
  - barbarian outposts are still the `IMPROVEMENT_BARBARIAN_CAMP` improvement with `BarbarianCamp="true"`
  - tribal villages are still the `IMPROVEMENT_GOODY_HUT` improvement with `Goody="true"`
  - both use `RemoveOnEntry="true"` in `decompiled/Assets/Gameplay/Data/Improvements.xml`
  - CAI keeps a Lua-side last-known per-plot snapshot for visible plots and, on revisit, announces the prior special improvement as gone if that plot no longer has the same special improvement
  - unlike the older Civ V-style file, this Civ VI version still cannot bootstrap from a revealed-improvement memory API because I did not find a Civ VI Lua equivalent to `GetRevealedImprovementType(...)`
- Flush grammar is line-oriented rather than queue-category-oriented:
  - reveal speaks either `<N> tiles revealed: ...`, `<N> tiles revealed`, or `Revealed: ...`
  - hidden speaks `Hidden: ...`
  - gone speaks `Gone: ...`
  - repeated labels aggregate to `count + label`
  - reveal payload section order is `Enemy`, `Units`, `Cities`, `Resources`, `Districts`, `Improvements`
- Scanner rebuild policy in the current scanner: category definitions are registered up front, but only dynamic categories keep their built contents across category cycles. Ordinary categories are discarded and rebuilt from live data whenever the player cycles scanner categories, which keeps stale entries from lingering without reintroducing a full scanner rebuild on every cursor move.
- Category definitions can opt into dynamic one-shot behavior with `BuildOncePerDynamicState = true`. CAI currently uses that for `validTargets` and `waterAvailability`.
- Scanner invalidation is category-scoped where possible: `Events.InterfaceModeChanged` and local unit selection changes rebuild only `validTargets`; water-lens layer changes rebuild only `waterAvailability`; `Events.LocalPlayerTurnBegin` clears all built category contents.
- Category definitions can expose a cheap `CanScan(context)` predicate to avoid expensive API calls when a category cannot currently exist, such as `validTargets` outside supported interface modes or `waterAvailability` while the water lens is off.
- Cursor movement resorts only the current built category. It does not rebuild or resort every scanner category.
- Scanner distance sorting uses the current CAI cursor plot and `Map.GetPlotDistance(...)`.
- Scanner jump and return use CAI cursor movement through `LuaEvents.CAICursorMove(x, y)`.
- Full-map scanner categories should iterate plots with `for plotIndex = 0, Map.GetPlotCount() - 1 do` and `Map.GetPlotByIndex(plotIndex)`. Do not use `Map.GetNumPlots()`.
- `WorldScannerCategory_validTargets.lua` appears only in active targeting modes. It gets target items from the neutral `CAIInterfaceTargets` helper in `interfaceTargetHelpers_CAI.lua`, so scanner and Space interface info use the same live target resolution without the scanner depending on `interfaceInfoHelpers_CAI.lua`. It does not attach per-item validation callbacks because the category is rebuilt when target mode or selected unit changes, and re-calling target APIs during scanner core validation is too expensive.
- `CAIInterfaceTargets` is now a slim target enumeration/cache helper. It owns target discovery, mode support checks, cache signatures, cached scalar item data, and plot lookup by plot id. It should not own standalone plot-label heuristics beyond the formation-unit special case.
- `CAIInterfaceTargets` caches only scalar target item data: plot ids, unit owner/id, labels, and a plot-id lookup table. Do not cache live `Plot`, `Unit`, `City`, or `District` objects. The cache is cleared on interface-mode and selected-local-unit changes so target APIs such as `UnitManager.GetOperationTargets(... REBASE ...)` are not called on every cursor move.
- Valid Targets plot modes are computed from vanilla `UnitManager.GetOperationTargets(...)`, `UnitManager.GetCommandTargets(...)`, or `CityManager.GetCommandTargets(...)` instead of vanilla `g_targetPlots`. Normal ranged/city/district/air attacks filter for `MODIFIER_IS_TARGET`; WMD, ICBM, coastal raid, deploy, rebase, teleport-to-city, airlift, soothsayer sacrifice, hero target commands, and naval gold raid use the eligible plot list vanilla exposes.
- `FORM_CORPS` and `FORM_ARMY` are unit-target modes, not plot-target modes. Vanilla reads `UnitCommandResults.UNITS` from `UnitManager.GetCommandTargets(selectedUnit, UnitCommandTypes.FORM_CORPS/FORM_ARMY)`, highlights each target unit plot, draws form-corps wave overlays from target unit to selected unit, and activation chooses the valid unit on the cursor plot through the vanilla `FormCorps()` / `FormArmy()` handlers.
- Valid Targets plot labels should go through `ExposedMembers.CAIInfo:RequestPlotInfo(...)` with mode-appropriate requested keys, so plot-tooltip helpers remain the single source of spoken target details. WMD and ICBM targets should request full plot info by passing no keys. Formation scanner items still use the target unit display name and stable owner/id item ids.

### Surveyor world input

- `Surveyor_CAI.lua` is an in-world hotkey module for answering "what is within N tiles of the CAI cursor."
- It is included by `WorldInput_CAI.lua`, uses `CAIHexCoordUtils.plotsInRange(...)`, and keeps its radius as private module-local state clamped from 1 to 5.
- Surveyor reads live game state on each action rather than caching scope results.
- Current default bindings:
  - `Ctrl+Shift+W` grows Surveyor radius.
  - `Shift+W` shrinks Surveyor radius.
  - `Shift+Q` reads summed yields.
  - `Shift+A` reads visible resources.
  - `Shift+Z` reads terrain, features, and elevation.
  - `Shift+E` reads friendly units.
  - `Shift+D` reads visible enemy units.
  - `Shift+C` reads known cities and barbarian camps.
- To free those Surveyor keys, `WorldTrackerReadSummary` is now `R`, `PlotReadDistrictBuildings` is `Shift+X`, `UnitViewAbilities` is `Ctrl+A`, and `WorldTrackerOpenCivicsChooser` is `Ctrl+C`.
- Surveyor resources should use `plot:GetResourceType()`, `plot:GetResourceCount()`, and `localPlayer:GetResources():IsResourceVisible(resource.Hash)` so invisible strategic resources stay hidden.
- Surveyor units should scan `Units.GetUnitsInPlotLayerID(x, y, MapLayers.ANY)` on revealed plots; enemy-unit speech should additionally require actual visibility through `PlayersVisibility[observer]:IsUnitVisible(unit)`.

### World scanner reveal and object rules

- Terrain scanner gates on revealed plots only. It intentionally emits separate entries for base terrain, feature, and elevation on the same revealed plot.
- Resources should use `plot:GetResourceType()` together with the local player's `GetResources():IsResourceVisible(resource.Hash)` check so invisible strategic resources stay hidden.
- Improvements use the same live plot getters as vanilla `PlotToolTip.lua`: `plot:GetImprovementType()`, `plot:IsImprovementPillaged()`, `plot:IsRoute()`, `plot:IsRoutePillaged()`, and `plot:GetRouteType()`. Civ VI models routes separately from improvements.
- Barbarian camps and tribal villages are improvements in Civ VI data:
  - `IMPROVEMENT_BARBARIAN_CAMP` has `BarbarianCamp="true"`
  - `IMPROVEMENT_GOODY_HUT` has `Goody="true"`
- Natural wonders are feature rows with `NaturalWonder="true"` in `GameInfo.Features`.
- Non-local city and unit scanner entries should be gated by diplomacy met state via `localPlayer:GetDiplomacy():HasMet(playerID)`.
- Non-local unit scanner entries should also respect actual visibility through `PlayersVisibility[observer]:IsUnitVisible(unit)`.
- For scanner units, prefer player-based unit enumeration, but do not rely on a raw `0 .. PlayerManager.GetWasEverAliveCount() - 1` loop for barbarians. Mirror the `UnitFlagManager` pattern instead: scan normal alive players and also do an explicit `for _, pPlayer in ipairs(Players) do if pPlayer:IsBarbarian() then ... end end` pass, then apply the usual revealed-plot and `IsUnitVisible(unit)` gates.
- Scanner units now use three top-level categories from the same `WorldScannerCategory_units.lua` file: my units, neutral units, and enemy units.
- Unit scanner subcategories should stay broad for navigation. CAI now derives them from live unit metadata in this order: barbarians, religious, civilian, support, air, naval, siege, ranged, then melee fallback.
- When classifying religious units from `GameInfo.Units`, do not treat Civ VI gameplay booleans or numeric stats as plain Lua truthy checks. Database booleans arrive as `0` or `1`, and `ReligiousStrength` / charge columns default to `0`; in Lua, `0` is truthy, so scanner logic must check `== 1` / `== true` or `> 0` explicitly.
- Every scanner category now gets an implicit `All` subcategory from `WorldScannerCore.lua`. It is always inserted first and contains every validated item in that category, grouped through the same `GroupId` / `GroupLabelResolver` path as normal subcategories.
- `hexCoordUtils_CAI.lua` now owns shared original-capital lookup, relative-coordinate math, wrap-aware spoken hex geometry helpers, and reusable direction/path utilities (`directionString`, `stepListString`, `stepListFromPath`, `unitVector`, `cubeDistance`, `directionRank`, `plotsInRange`).
- Plot tooltip relative coordinates should call `GetRelativeCoords(plot)` and format the returned `dx, dy` locally; world scanner item speech should call `GetDirectionString(cursorX, cursorY, targetX, targetY)` and speak direction text instead of tile distance.
- Shared unit naming now lives in `inGameHelpers_CAI.lua`:
  - `GetUnitFormationSuffix(unit)` is the single formation-suffix helper for live unit objects
  - `GetUnitDataFormationSuffix(data)` is the matching helper for vanilla `UnitPanel` data tables
  - `FormatOwnedUnitDisplayName(unit)` now auto-applies the shared formation suffix when the caller does not pass one explicitly
  - `UnitFlagManager_CAI.lua`, `UnitPanel_CAI.lua`, `WorldScannerCategory_units.lua`, and `RevealAnnouncements_CAI.lua` should use those helpers instead of duplicating corps/army/fleet/armada logic
- A future scanner category can mirror vanilla settler-lens water availability exactly by consuming `Map.GetContinentPlotsWaterAvailability()` and mapping its returned arrays to localized subcategories rather than reverse-engineering lens colors.

### UIScreenManager priority stack

- `UIWidgetPriority` defines shared root-widget priority levels:
  - `Low = -10`
  - `Normal = 0`
  - `High = 10`
- `mgr:Push(widget, priority)` accepts a numeric priority. Nil priority resolves to `Normal`.
- Stack sorting is deterministic: priority wins first, then push order breaks ties. Equal-priority widgets therefore behave like a normal last-in-first-out stack.
- The active root is always `mgr:GetTop()`, which is the last entry after sorting.
- Pushing a lower-priority root does not refocus or reannounce the existing active root when it remains on top.
- `mgr:Pop()` removes the active root. `mgr:Pop(widget)` removes a specific root widget if a screen needs to close a non-active lower-priority root.
- `mgr:SetFocus(...)` and `mgr:SetFocusPath(...)` only apply focus when the target path belongs to the active root, preventing lower-priority screens from stealing focus while a higher-priority modal/popup is active.

## Lua Context Notes

- Included Civ VI Lua panel files expose their top-level functions directly in the current chunk after `include("...")`, so wrappers can usually reassign names like `PopulateWonders = WrapFunc(PopulateWonders, ...)`.
- Do not rely on `_G` or `rawget(_G, ...)` for panel helper discovery in Civ VI UI contexts. These globals are not consistently available/mod-safe in this project; prefer explicit one-by-one capture/wrapping of the functions you need.
- Camera/map movement:
  - `WorldInput.lua` pans the map through `UI.PanMap(panX, panY)` from camera pan input actions and focuses plots through `UI.LookAtPlot(...)` in `SnapToPlot(plotId)`.
  - Minimap clicks call `UI.LookAtPosition(worldX, worldY)`. City and unit panels also call `UI.LookAtPlot(...)` for explicit recenter actions.
  - `WorldView/CameraManager.lua` is combat-specific despite its broad name: it listens to `Events.CombatVisBegin` / `Events.CombatVisEnd`, optionally calls `UI.LookAtPlot(combatMembers.x, combatMembers.y, zoom)` based on gameplay options, saves the previous zoom with `UI.SetRestoreMapZoom(prevZoom)`, and restores it with `UI.RestoreMapZoom()`. It does not manage normal selected unit/city camera sync.
  - Current camera focus can be read with `UI.GetMapLookAtWorldTarget()`, which returns world-space `x, y`. Vanilla `WorldInput.lua` uses it as the drag-start focus, and `Automation_ObserverCamera.lua` converts it to plot coordinates with `UI.GetPlotCoordFromWorld(wx, wy)`.
  - `Events.Camera_Updated` exists. Vanilla uses it for camera/zoom-sensitive world anchors, e.g. `CityPanel.lua` updates the border-growth anchor and `TourismBannerManager.lua` refreshes banner positions. It is not used by vanilla as the primary unit/city selection signal.
  - The event can pass focus and zoom values (`OnCameraUpdate(vFocusX, vFocusY, fZoomLevel)` in `CityPanel.lua`). For selected-object cursor sync, prefer `Events.UnitSelectionChanged`, `Events.CitySelectionChanged`, and explicit CAI/vanilla `LookAtPlot` touch points; use `Camera_Updated` only as a throttled/manual camera-center fallback, probably by reading `UI.GetMapLookAtWorldTarget()` and converting through `UI.GetPlotCoordFromWorld(...)`.
- Tutorial input locking:
  - `TutorialScenarioBase.lua` starts the tutorial with `Input.SetActiveContext(InputContext.Tutorial)`.
  - `TutorialUIRoot.lua` installs `ContextPtr:SetInputHandler(OnInput, true)`, so it receives all input during tutorial flow. Its normal handler only handles debug keys and Escape, but the tutorial system also drives `UITutorialManager` overlays/control filtering.
  - `AdvisorPopup.lua` also installs `ContextPtr:SetInputHandler(OnInputHandler, true)`. When `AdvisorBase` or `MetaBase` is visible, `IsBlockingInput()` returns true, so `OnInputHandler()` consumes most input. Escape is special-cased to fire `LuaEvents.Tutorial_ToggleInGameOptionsMenu()`.
  - `AdvisorPopup.lua` calls `UITutorialManager:SetActiveAlways(isAdvisorVisible)` and `UITutorialManager:EnableOverlay(isAdvisorVisible)` from show/hide handlers. While the advisor is visible, normal UI controls do not get input.
  - Detailed tutorial steps call `RaiseDetailedTutorial(item)`, which shows only the tutorial-triggered controls and calls `UITutorialManager:EnableControlsByIdOrTag(...)` for the item `EnabledControls`. Other controls may be blocked by the tutorial overlay even when the advisor popup is hidden.
  - In the production tutorial steps, vanilla production rows are tagged with `UITutorialManager:GetHash(item.Type)` while the scenario enables hashes such as `UNIT_WARRIOR`, `UNIT_BUILDER`, or `BUILDING_MONUMENT`. CAI production rows should read the live vanilla row controls through widget `IsHidden` / `IsDisabled` methods so UI manager navigation and activation respect the current tutorial-filtered control state.
  - ResearchChooser uses the same pattern: vanilla research rows tag `Top` with `UITutorialManager:GetHash(kData.TechType)` and set `Top:SetDisabled(...)`; CAI research rows should cache the returned vanilla row instance and expose live `Top` / `TopContainer` state through widget `IsHidden` / `IsDisabled`.
  - Base tutorial research "Show me" buttons call `LuaEvents.Tutorial_ResearchOpen()` before `LuaEvents.AdvisorPopup_ShowDetails(advisorInfo)`. That means ResearchChooser can open before `RaiseDetailedTutorial(item)` applies enabled-control filtering, so CAI's initial focus should wait for a post-`RaiseDetailedTutorial` signal before pushing the accessibility panel on tutorial opens.
  - Tutorial items are data objects loaded by `TutorialUIRoot.LoadItems()`. They define raise listeners, prereqs, advisor text/buttons, advisor-only UI triggers, detailed-mode UI triggers, enabled controls, disabled controls, done listeners, cleanup, and optional chain `NextID`.
  - `TutorialCheck(listenerName)` is the central state machine. It ignores checks while disabled or during the load screen, checks only valid local-player tutorial events, deactivates the active item when its done listener/function matches, then activates unseen eligible items or queues queueable ones.
  - `ActivateItem(item)` sets `m_active`, optionally runs the global pre-activate function and item open function, enables tutorial checks, adds goals, then raises the advisor popup through `LuaEvents.TutorialUIRoot_AdvisorRaise(item.AdvisorInfo)`.
  - Advisor buttons either call `LuaEvents.AdvisorPopup_ClearActive(advisorInfo)` to mark/deactivate/chain, or `LuaEvents.AdvisorPopup_ShowDetails(advisorInfo)` to mark seen and enter detailed mode.
  - `TutorialInput.lua` is a separate lightweight input-filter context. `ActivateInputFiltering()` shows that context through `LuaEvents.TutorialUIRoot_FilterKeysActive()`, and `DisableInputFiltering()` hides it; while active it primarily catches Escape for the tutorial options menu.
  - In the base tutorial `OPEN_CITY_PANEL` item, the only explicitly enabled target is the city panel `ChangeProductionCheck`, and completion is `CityPanel_ProductionOpen` -> `ProductionPanelViaCityOpen`. This is why normal arrow/Escape navigation can appear stolen until that control is activated.
  - In the base tutorial `TURN_BASED_B` item, the OK button calls `LuaEvents.AdvisorPopup_ShowDetails(advisorInfo)`. `TutorialUIRoot.OnAdvisorPopupShowDetails()` marks the active item seen and calls `RaiseDetailedTutorial(item)`. Because `TURN_BASED_B` has no `UITriggers`, `RaiseDetailedTutorial()` immediately calls `DeActivateItem(item)`, which chains into `TURN_BASED_C`.
  - `TURN_BASED_C` is the detailed end-turn step: it sets `UITriggers("ActionPanel", "TutorialSelectEndTurn")`, enables `UITutorialManager:GetHash("ActionPanel")`, disables `UITutorialManager:GetHash("ChangeProductionCheck")`, and completes on `LocalPlayerTurnEnd`.
  - Base tutorial detailed steps that show the ActionPanel use `SetUITriggers("ActionPanel", ...)`. Active entries found in `TutorialScenarioBase.lua`: `TURN_BASED_C`, `SELECT_RESEARCH_8`, `SELECT_END_TURN_B`, `SELECT_END_TURN_PRODUCTION`, `SELECT_END_TURN_C`, `SELECT_END_TURN_D`, `SCOUTS_D2`, `SCOUTS_E`, `SELECT_END_TURN_RESEARCH`, and `RESEARCH_IRRIGATION`. `NOTIFICATION_PANEL` uses `SetAdvisorUITriggers("ActionPanel", "TutorialNotificationPointer")` only while the advisor popup is still active. The commented `SELECT_END_TURN_UNIT_ORDERS` block is inactive.
  - `TutorialUIRoot_CAI.lua` emits `LuaEvents.CAI_TutorialActionPanelAllowed(isAllowed)` when detailed tutorial controls are raised or deactivated. `ActionPanel_CAI.lua` should block Space/Ctrl+Space and its blocker-list panel while `IsTutorialRunning()` is true unless the current detailed item has the `ActionPanel` UI trigger.
  - Base tutorial setup calls `SetSlowNextTurnEnable(true)` once. `TutorialUIRoot.SetSlowNextTurnEnable(...)` only broadcasts `LuaEvents.Tutorial_SlowNextTurnEnable(isEnabled)`. `ActionPanel.lua` listens with `OnTutorialSlowTurnEnable(...)`, stores `m_isSlowTurnEnable`, and on every `OnLocalPlayerTurnBegin()` briefly shows `TutorialSlowTurnEnableAnim`, a hidden-by-default `AlphaAnim` with `ConsumeAllMouse="1"`, then hides it again from its animation end callback. This is a mouse click-spam shield, not a persistent ActionPanel enabled/disabled flag.
  - If the game access-violates on the `TURN_BASED_B` OK click with no Lua traceback, the native crash is likely during the `AdvisorPopup_ShowDetails` -> `RaiseDetailedTutorial` -> `DeActivateItem` -> `ActivateItem(TURN_BASED_C)` chain, especially around `UITutorialManager` showing/enabling ActionPanel tutorial controls.
- `TechCivicCompletedPopup.lua` (decompiled/Assets/UI/Popups/) shows tech and civic completions through an internal queue and a UIManager popup:
  - `AddCompletedPopup(player, civic, tech, isByUser)` appends to `m_kPopupData` and calls `UIManager:QueuePopup(ContextPtr, PopupPriority.Low, { DelayShow = true })` on the first entry.
  - `OnShow()` runs `RealizeNextPopup()`, which pops the next `m_kPopupData` entry and dispatches to `ShowTechCompletedPopup(player, tech, quote, audio)` or `ShowCivicCompletedPopup(player, civic, quote, audio)` based on whether `tech` is nil.
  - `TryClose()` fires `LuaEvents.TechCivicCompletedPopup_TechShown` or `_CivicShown`, then either re-enters `RealizeNextPopup()` when more entries remain or calls `Close()` which clears the queue and dequeues from UIManager. Because `TryClose` chains, a single user dismiss can immediately trigger another `Show*Completed*Popup`, so CAI wrappers must pop the previous CAI dialog before each build.
  - `ShowCivicCompletedPopup` is the only path that shows `Controls.ChangeGovernmentButton`. The button label switches between `LOC_GOVT_GOVERNMENT_UNLOCKED` (callback `OnChangeGovernment`) and `LOC_GOVT_CHANGE_POLICIES` (callback `OnChangePolicy`). Both globals call `Close()` themselves after firing `LuaEvents.TechCivicCompletedPopup_GovernmentOpenGovernments` / `_OpenPolicies`.
  - Quote text is written with `Controls.QuoteLabel:LocalizeAndSetText(quote)`, so reading `:GetText()` returns the already-localized string. `Controls.HeaderLabel`, `Controls.ResearchName`, `Controls.CivicMsgLabel`, and `Controls.UnlockCountLabel` are also pre-localized and safe to read live.
  - `OnInputHandler` returns `true` for all input, so CAI's wrapped handler must only delegate to vanilla after `mgr:HandleInput` rejects the event, and only when the CAI dialog is on top of the widget stack.
- `ProductionPanel.lua` queue selection is a single-item pick-up mode, not multi-select:
  - the real selected queue item is local `m_kSelectedQueueItem = { Parent, Button, Index }`
  - `OnItemClicked(parent, button)` selects when `Index == -1`, swaps with the clicked queue index when another item is selected, or deselects when clicking the same item
  - `HighlightButtons(true)` calls `SetSelected(true)` on current production and every valid queue slot, so `control:IsSelected()` means "queue selection mode is active", not "this exact row is selected"
  - `RefreshQueue(...)` starts with `DeselectItem()`, so queue rebuilds intentionally clear vanilla selection
- ProductionPanel CAI open/tab sync:
  - `LuaEvents.ProductionPanel_ListModeChanged(...)` is still the correct CAI sync point for ordinary vanilla tab changes because vanilla emits it directly from `OnTabChangeProduction`, `OnTabChangePurchase`, `OnTabChangePurchaseFaith`, `OnTabChangeQueue`, and `OnTabChangeManager`.
  - For delayed open, `LuaEvents.ProductionPanel_Open()` should be treated only as an "open pending" signal. Vanilla `Open()` fires it before the caller has necessarily selected the final tab.
  - The practical open handshake is therefore: mark CAI open-pending on `ProductionPanel_Open`, wait for the first real `ProductionPanel_ListModeChanged(...)`, then sync the CAI active tab from `m_CurrentListMode` and push the CAI panel.
  - Because this flow relies on vanilla's own later `m_tabs.SelectTab(...)`, CAI does not need to wrap and re-register the city/notification/tutorial open-entry LuaEvent handlers just to discover the final tab.
  - Vanilla only shows the shared current-production summary container on the Production tab and the Queue tab. `OnTabChangePurchase()` and `OnTabChangePurchaseFaith()` both hide `Controls.CurrentProductionContainer`, while `OnTabChangeProduction()` and `OnTabChangeQueue()` show it when `m_hasProductionToShow` is true.
  - CAI production refresh hooks should use the real engine events `Events.CityProductionChanged`, `Events.CityProductionUpdated`, and `Events.CityProductionQueueChanged`. The older speculative `CityWorkersChanged` hook is not documented in the IDE helpers and should not be relied on.
  - Vanilla category expanded state lives on the header-pair visibility, not a separate Lua flag: `OnExpand(instance)` hides `instance.Header`, shows `instance.HeaderOn`, and shows `instance.List`; `OnCollapse(instance)` does the reverse and only hides `instance.List` after the collapse animation finishes.
  - For CAI category widgets, treat that header visibility only as an initial-build hint. After the CAI category nodes are created, expand/collapse is ordinary CAI tree state and does not need ongoing sync back to vanilla headers.
  - `View(data)` repopulates more than one production list mode in a single pass. CAI category/header captures therefore need to be keyed by `listMode`; a single shared `wonderList` / `districtList` / `unitList` reference will be overwritten by later populate calls and can make category labels or expand/collapse callbacks point at the wrong vanilla header instance.
- Vanilla district / wonder placement UI:
  - `ProductionPanel.lua` enters placement mode with `UI.SetInterfaceMode(InterfaceModeTypes.DISTRICT_PLACEMENT, tParameters)` for districts and district purchases, or `UI.SetInterfaceMode(InterfaceModeTypes.BUILDING_PLACEMENT, tParameters)` for wonders.
  - Production-build district placement (`ZoneDistrict(...)`) explicitly closes the production panel immediately after entering `DISTRICT_PLACEMENT` by calling `Close()`. This also happens from queue mode; `m_isQueueOpen` stays true because `Close()` does not clear it.
  - Placement exit is routed through `StrategicView_MapPlacement.lua`, which fires `LuaEvents.StrageticView_MapPlacement_ProductionOpen(bWasCancelled)` when leaving district/building placement. `ProductionPanel.lua` reopens on the queue tab whenever `m_isQueueOpen` is still true, reopens on the manager tab whenever `m_isManagerOpen` is true, and in the normal non-queue production path only auto-reopens when placement was cancelled.
  - Purchase-district placement (`PurchaseDistrict(...)`) is different: it enters `DISTRICT_PLACEMENT` without calling `Close()`, and `ProductionPanel.OnInterfaceModeChanged(...)` does not auto-close on `DISTRICT_PLACEMENT`. So the explicit close-on-placement behavior belongs to the production-build path, not the district-purchase path.
  - `StrategicView_MapPlacement.lua` owns the in-world placement flow. It highlights owned valid plots as `Placement_Valid`, highlights purchasable valid plots as `Placement_Purchase`, and focuses the currently hovered plot through `RealizeCurrentPlaceDistrictOrWonderPlot()`.
  - Wonder placement uses the same hover-focus path as district placement: `RealizeCurrentPlaceDistrictOrWonderPlot()` unfocuses the previous placement hex and focuses the current one only when the hovered plot is one of the selectable placement hexes.
  - District placement shows more information than wonder placement. `DistrictPlotIconManager.lua` uses `AdjacencyBonusSupport.GetAdjacentYieldBonusString(...)` on each valid district plot and shows:
    - a centered bonus badge (`BonusText`) with the summarized result such as adjacency yields or housing
    - a tooltip on that badge containing the detailed adjacency / housing breakdown from `plot:GetAdjacencyBonusTooltip(...)`
    - an alert icon (`PrereqIcon`) when `requiredText` is returned, with the icon tooltip describing what prerequisite or rule still matters for that placement
    - border adjacency markers around neighboring plots from `AddAdjacentPlotBonuses(...)`, indicating which adjacent terrain, district, wonder, river, resource, etc. is contributing to the bonus
  - `AdjacencyBonusSupport.GetAdjacentYieldBonusString(...)` returns three values for a candidate district plot:
    - a short summary string (`iconString`), normally the net yields or housing
    - a detailed tooltip string (`tooltipText`), built from `plot:GetAdjacencyBonusTooltip(...)`
    - an optional requirement or warning string (`requiredText`)
  - Neighborhood-style districts (`OnePerCity == false`) are a special case: the summary is driven from appeal / housing rather than per-yield adjacency, and the tooltip text is replaced by `LOC_DISTRICT_ZONE_NEIGHBORHOOD_TOOLTIP`.
  - Wonder placement does not build the same bonus badge UI. `DistrictPlotIconManager.lua` only marks which plots are valid or purchasable for the wonder; `BonusText` is cleared and `PrereqIcon` is hidden for wonders.
  - `StrategicView_MapPlacement.ConfirmPlaceWonder(...)` builds the wonder confirmation popup from `LOC_DISTRICT_ZONE_CONFIRM_WONDER_POPUP`, then appends every `CityOperationResults.SUCCESS_CONDITIONS` entry returned by `CityManager.CanStartOperation(...)`. In practice, this means some of the most useful wonder-specific rule text is only visible at confirm time rather than on hover.
  - Wonder and district confirmation both call `CityManager.CanStartOperation(...)` (or `CityManager.CanStartCommand(...)` for purchased districts) with `testVisible=true`, then append every returned `SUCCESS_CONDITIONS` string into the confirmation popup text. Some explanatory placement text therefore appears only at confirm time, especially for wonders.
  - `PlotInfo.lua` filters the purchasable-plot overlay during district / wonder placement so only plots that both can be purchased and can legally host the selected district / wonder receive purchase buttons.
  - `CityPanel.lua` disables the normal city-management toggles during `DISTRICT_PLACEMENT`, hides the growth tile when leaving district or wonder placement, and still shows the growth tile during either placement mode if the pending district / wonder could legally be placed on the city's next-growth plot.
- `ProductionPanel.lua` tab-open sequencing matters:
  - `CreateCorrectTabs()` always initializes vanilla tabs by calling `m_tabs.SelectTab(m_productionTab)` once during setup.
  - Specific city-panel open handlers then switch to the requested tab after `Open()`, for example `OnCityPanelPurchaseGoldOpen()` -> `Open()` -> `m_tabs.SelectTab(m_purchaseTab)` and `OnCityPanelPurchaseFaithOpen()` -> `Open()` -> `m_tabs.SelectTab(m_faithTab)`.
  - The reliable CAI sync point is `LuaEvents.ProductionPanel_ListModeChanged(listMode)`, because the original vanilla tab callbacks always emit it after the real tab switch.
  - CAI should treat `ProductionPanel_ListModeChanged` as the source of truth for the currently active vanilla tab, especially on open where the final vanilla tab choice happens after `Open()`.
  - CAI tab widgets should resolve the live vanilla tab controls (`m_productionTab`, `m_purchaseTab`, `m_faithTab`, `m_queueTab`) instead of assuming `Controls.ProductionTab` / `PurchaseTab` / `PurchaseFaithTab` / `QueueTab` are the active controls, because `CreateCorrectTabs()` may swap in the mini-tab controls before any open handler runs.
- `ProductionManager.lua` is the separate multi-queue UI context opened by `ProductionPanel.lua` Manager tab:
  - `OnTabChangeManager()` calls `OpenManager()`, which broadcasts `LuaEvents.ProductionPanel_OpenManager()`
  - `ProductionManager.lua` listens for `ProductionPanel_OpenManager`, `ProductionPanel_CloseManager`, `ProductionPanel_ProductionClicked`, and `ProductionPanel_CancelManagerSelection`
  - it owns `Controls.FilterPulldown`, `Controls.CityStack`, per-city `CityInstance` rows, per-city `CurrentProductionGrid`, per-city queue slots, and per-city `TrashButton`
  - `SetupFilters()` creates sort entries with `Controls.FilterPulldown:BuildEntry("FilterItemInstance", controlTable)`; each entry button calls `Refresh(sortFunc, name)`
  - built-in sort filters are founding order, city name, and population
- `DeclareWarPopup.lua` is the dedicated declare-war confirmation popup used by diplomacy, city-state, Civ6Common, and world-input flows:
  - vanilla open routes are `LuaEvents.DiplomacyActionView_ConfirmWarDialog`, `LuaEvents.CityStates_ConfirmWarDialog`, `LuaEvents.Civ6Common_ConfirmWarDialog`, and `LuaEvents.WorldInput_ConfirmWarDialog`
  - `OnShow(eAttackingPlayer, kDefendingPlayers, eWarType, confirmCallbackFn)` populates the live popup state, including `Controls.Message`, `Controls.Targets`, the visible consequence containers, and the `Yes` callback
  - when `confirmCallbackFn` is nil, vanilla builds a default callback that loops defending players and calls `DeclareWar(...)` for each target
  - visible consequence sections are `WarmongerContainer`, `DefensivePactContainer`, `CityStateContainer`, `TradeRouteContainer`, and `DealsContainer`; hidden sections should be skipped by CAI speech
  - `OnClose()` hides every consequence container and the context itself, and `Events.LocalPlayerTurnEnd` also closes the popup
  - CAI can safely wrap `OnShow(...)`, `OnClose()`, and `OnInputHandler(...)`, then rebuild a transient dialog from live control text instead of rebinding the popup's Lua event registrations
- `FiraxisLive/My2K.lua` is a front-end popup context hosted under `/FrontEnd/MainMenu/My2K`:
  - Vanilla uses a legacy 3-argument `InputHandler(uiMsg, wParam, lParam)` and `ContextPtr:SetShowHideHandler(ShowHideHandler)`.
  - CAI can replace that input handler with the extended `InputStruct` form after vanilla setup and preserve Escape behavior by checking `input:GetMessageType()`, `input:GetKey()`, `m_bESCEnabled`, and `m_cancelFunction`.
  - Dialog state is selected by `m_currentDialogID` and created by `ShowHideHandler()` through `Create2KMainMenu`, `CreateLoginDialog`, `CreateNewUserDialog`, `CreateUserNameDialog`, `CreateLegalDialog`, `CreateLegalItemDialog`, `CreateMessageDialog`, `CreateLogoutDialog`, and `CreateUnlinkConfirmationDialog`.
  - My2K dialog instances are XML-backed and short-lived through `InstanceManager`; accessible replacements should rebuild from the live `m_currentDialog` instance after each `Create*Dialog()` call.
  - The shared `WidgetTemplateHelpers:MakeGeneralDialog(titleFunc, actionButtons, dlgContent)` helper is the preferred CAI scaffold for these modal dialogs.
- `CityPanel.lua` exposes the live selected-city data table as local `m_kData` inside the included chunk, so a wrapper can read the same live data after wrapping `Refresh()`.
- `CitySupport.lua` exposes `GetCityData(city)`, and `CityPanel.lua` includes `CitySupport`, so `CityPanel_CAI.lua` can request fresh city data without wrapping `Refresh()`.
- `CityManager.GetCity(playerID, cityID)` is available in UI context and can resolve a city for helper-based city info requests.
- `CityPanel_CAI.lua` now extends `ExposedMembers.CAIInfo` with:
  - `CityInfo` helper table (`Summary`, `Name`, `Coords`, `Health`, `BuildingCount`, `ReligiousFollowersCount`, `AmenitiesSummary`, `HousingSummary`, `GrowthSummary`, `ProductionSummary`, `BuildingsAmenitiesSummary`, `VisibleYields`, `NormalFocusYields`, `FavoredFocusYields`, `IgnoredFocusYields`)
  - `RequestCityInfo(cityOrCityID, requestedKeys, playerID)` which defaults to the currently selected city when no city is passed
- `CityPanel_CAI.lua` now builds city info from `GetCityData(city)` using the same vanilla loc keys / string assembly patterns as `CityPanel.lua`; it does not read back from UI controls or call `ViewMain(data)`.
- City growth / production helpers can also expose the visible progress-bar state from `GetCityData(city)`:
  - growth: `CurrentFoodPercent`, `FoodPercentNextTurn`
  - production: `CurrentProdPercent`, `ProdPercentNextTurn`
- `UnitPanel.lua` owns selected-unit panel data and action button construction:
  - `ReadUnitData(unit)` builds the panel data table from the live unit, including name, type, movement, health, charges, promotions, abilities, stats, and `Actions`.
  - `GetSubjectData()` returns the current selected-unit data table cached by `View(data)`.
  - `GetUnitActionsTable(unit)` builds `data.Actions` with vanilla action order, disabled state, tooltip/failure text, callback function, callback void values, and optional sound.
  - Vanilla unit commands and operations use loose `UnitManager.CanStartCommand(...)` / `CanStartOperation(...)` checks to decide whether an action should be visible, then stricter current-executability checks where needed. If the stricter check or tutorial gating fails, the row can still be added with `Disabled = true` and failure reasons appended to `helpString`.
  - `data.Actions.displayOrder.primaryArea` and `secondaryArea` define the normal unit-panel action order. Build actions live in `data.Actions["BUILD"]`.
  - `AddActionToTable(...)` also populates vanilla `m_kHotkeyActions` for actions with `HotkeyId`; CAI should let vanilla continue handling directly bound unit operation / command keys.
  - Combat preview is a live hover pipeline:
    - `OnInterfaceModeChanged(...)` is the attack-preview mode-entry path for `CITY_RANGE_ATTACK` and `DISTRICT_RANGE_ATTACK`. It makes the panel visible, swaps the subject view to the attacker city-center district or district, and calls `OnShowCombat(...)`.
    - `OnInputHandler(...)` calls `InspectWhatsBelowTheCursor()` on every `MouseMove` while the panel is processing input and no unit flag has focus.
    - `InspectWhatsBelowTheCursor()` checks `UI.GetCursorPlotID()` against `m_plotId`; when the cursor enters a new visible plot it calls `InspectPlot(plot)`, otherwise it does nothing.
    - `InspectPlot(plot)` is the main plot-hover preview entry point. It calls `GetCombatResults(...)`, then `ReadTargetData(attacker)`, `CanShowCombat()`, and `OnShowCombat(isValidToShow)`.
    - `OnUnitFlagPointerEntered(playerID, unitID)` is the unit-flag-hover entry point. It simulates direct combat against the hovered defender with `CombatManager.SimulateAttackVersus(...)`, then calls `ReadTargetData(attacker)` and `OnShowCombat(isValidToShow)`.
    - `OnUnitFlagPointerExited(...)` clears flag focus, resets `m_plotId`, and reruns `InspectWhatsBelowTheCursor()` so preview falls back to the plot under the cursor.
    - `GetCombatResults(attacker, x, y)` skips duplicate attacker+plot requests by caching `m_attackerUnit`, `m_locX`, and `m_locY`. It uses `CombatManager.SimulateAttackInto(...)` normally and `SimulatePriorityAttackInto(...)` in `PRIORITY_TARGET`.
    - `ReadTargetData(attacker)` populates `g_targetData` from `m_combatResults` for unit, district, and improvement / plot defenders, including interceptor and anti-air side data when present.
    - `OnShowCombat(showCombat)` is the final display gate. If `m_combatResults` is nil it hides preview; otherwise it renders the attacker/target combat UI from the current live state.
    - CAI combat-preview speech reads visible UnitPanel controls for names, strength numbers, assessment, and modifier text. Since subject/target combat stat icons are image controls, CAI appends localized stat labels for the main attacker/defender strengths by mirroring vanilla's `COMBAT_TYPE` icon-selection logic. Interceptor and anti-air strength sections use only their visible numeric labels. Damage comes from vanilla `GetCombatPreviewResults()` / `CombatResultParameters` rather than health meters, because UnitPanel meter controls are write-only for this purpose.
    - As of 2026-05-18, CAI preview damage speech now uses unsigned dealt-damage values. For walled-city targets, `GetTargetPreviewDamageText()` speaks city damage first and appends wall state in the same target clause: ordinary wall hits append the wall damage amount, while a wall-breaking hit appends `destroys walls` using the same `FINAL_DEFENSE_DAMAGE_TO >= MAX_DEFENSE_HIT_POINTS` check CAI uses for post-combat wall-destruction wording.
    - `Events.Combat(combatResults)` fires after combat resolves and reuses the same hashed `CombatResultParameters` table shape as preview simulation. CAI can read `ATTACKER`, `DEFENDER`, `INTERCEPTOR`, `ANTI_AIR`, `COMBAT_TYPE`, `LOCATION`, `ATTACKER_ADVANCES`, `DEFENDER_CAPTURED`, `DEFENDER_RETALIATES`, `LOCATION_PILLAGED`, `DAMAGE_TO`, `FINAL_DAMAGE_TO`, `DEFENSE_DAMAGE_TO`, `FINAL_DEFENSE_DAMAGE_TO`, `MAX_HIT_POINTS`, `MAX_DEFENSE_HIT_POINTS`, and the nested `ID` payloads from that event without depending on UnitPanel preview visibility.
    - Nested combatant ids in the results table use the same component-id shape UnitPanel reads from `CombatResultParameters.ID`: `id.player`, `id.id`, and `id.type`. Vanilla resolves unit ids with `UnitManager.GetUnit(id.player, id.id)` and district ids with `Players[id.player]:GetDistricts():FindID(id.id)`. Plot-only targets fall back to `CombatResultParameters.LOCATION`.
    - Preview-only text arrays such as `PREVIEW_TEXT_TERRAIN`, `PREVIEW_TEXT_HEALTH`, `PREVIEW_TEXT_OPPONENT`, `PREVIEW_TEXT_MODIFIER`, `PREVIEW_TEXT_ASSIST`, `PREVIEW_TEXT_PROMOTION`, `PREVIEW_TEXT_DEFENSES`, `PREVIEW_TEXT_RESOURCES`, `PREVIEW_TEXT_INTERCEPTOR`, and `PREVIEW_TEXT_ANTI_AIR` are useful for verbose preview breakdowns, but a post-combat summary can ignore them and instead derive concise spoken outcomes from resolved names plus `DAMAGE_TO` / `FINAL_*` / capture-pillaged flags.
  - `src/data/unitOperationConfig.sql` assigns missing `HotkeyId` values for visible vanilla `UnitOperations` and visible vanilla `UnitCommands`. Unit-command action ids use the `UnitCommand...` prefix to avoid colliding with operation action ids such as `Upgrade`.
  - `UNITCOMMAND_DELETE` is intentionally not assigned through `UnitCommands.HotkeyId`: vanilla already exposes the `DeleteUnit` input action and separately special-cases it in `OnInputActionTriggered`, so adding it to `m_kHotkeyActions` could double-call the delete prompt.
  - `UnitPanel_CAI.lua` extends `ExposedMembers.CAIInfo` with `RequestUnitInfo(unitID, requestedKeys, playerID)`, defaults to `UI.GetHeadSelectedUnit()`, and uses the same `ReadUnitData` / `GetSubjectData` data rather than reimplementing unit state.
- `UnitPanel_CAI.lua` handles the shared selection info inputs (`~`, `Shift+1` through `Shift+0`) when a unit is selected and opens a transient action list from the existing `SelectionActions` input.
  - Current unit bucket mapping is:
    - `Shift+6` -> unit stats
    - `Shift+7` -> unit abilities
    - `Shift+8` -> special unit info (spy, trader, rock band, great person passive)
    - `Shift+9` -> queued movement path
  - Summary speech now reuses the same helper pipeline and inserts upgrade availability before promotions, plus builder recommendation and settler water guide before abilities.
  - Unit stats should skip combat speech for spies and ordinary civilians, use trade-route name plus land/sea ranges for traders, and keep normal combat/religious stat speech for units that actually expose those stats.
  - Summary-only builder recommendation should prefer the live `RecommendedActionButton` tooltip text, and settler water guide should prefer the live UnitPanel settler-water control tooltips and header text.
- Vanilla shows or refreshes combat preview in these cases:
  - entering city or district ranged-attack mode
  - moving the cursor onto a different visible plot while a valid attacking unit, district, or city attack context is active
  - moving the cursor onto an enemy unit flag while a valid attacking context is active
  - leaving an enemy unit flag, which immediately re-evaluates the plot under the cursor
- Vanilla `WorldInput.lua` attack-related interface modes:
  - `RANGE_ATTACK` executes `UnitOperationTypes.RANGE_ATTACK`; it shows valid target plots on the attack-range lens with attack arcs from the unit, focuses a valid target hex on mouse move, and enables UnitPanel combat preview on hover/flag focus.
  - `CITY_RANGE_ATTACK` and `DISTRICT_RANGE_ATTACK` execute `CityCommandTypes.RANGE_ATTACK`; they show valid target plots on the attack-range lens with arcs from the city center or district, focus valid target hexes on mouse move, and enable UnitPanel combat preview. UnitPanel also swaps the subject display to the attacking city-center district or district on mode entry.
  - `AIR_ATTACK` executes `UnitOperationTypes.AIR_ATTACK`; it highlights valid target plots on `Hex_Coloring_Attack`. UnitPanel records explicit air-attack target plots and can show combat preview for hovered unit, district, improvement, or owned plot targets, including interceptor and anti-air data when present.
  - `WMD_STRIKE` executes `UnitOperationTypes.WMD_STRIKE`; it highlights valid strike plots with attack-range-style target arcs, but UnitPanel `CanShowCombat()` explicitly suppresses combat preview. Selection shows only the targeting lens plus the launch / war confirmation flow.
  - `ICBM_STRIKE` executes `CityCommandTypes.WMD_STRIKE`; it highlights valid strike plots with attack-range-style target arcs and uses the launch / war confirmation flow. Vanilla WorldInput does not pair it with a UnitPanel combat-preview subject path.
  - `COASTAL_RAID` executes `UnitOperationTypes.COASTAL_RAID`; it highlights valid raid plots on `Hex_Coloring_Attack` and may trigger war confirmation. WorldInput itself does not add target details beyond the lens.
  - `InterfaceModeTypes.ATTACK` is allocated in the handler table but has no vanilla enter/leave/mouse mappings in `WorldInput.lua`.
  - Several non-attack modes reuse `CursorTypes.RANGE_ATTACK` or target-plot highlighting (`DEPLOY`, `REBASE`, `TELEPORT_TO_CITY`, `FORM_CORPS`, `FORM_ARMY`, `AIRLIFT`, `SACRIFICE_SELECTION`, hero `KILL_WEAKER_UNIT`, `TRANSFORM_UNIT`, `RESTORE_UNIT_MOVES`, `NAVAL_GOLD_RAID`), but their displayed information is only eligible target plots / movement-style lens feedback, not normal combat-preview data.
- Vanilla suppresses or hides combat preview in these cases:
  - `m_combatResults` is nil
  - `CanShowCombat()` rejects the current mode, currently including `WMD_STRIKE`
  - the selected unit has neither normal combat nor religious strength
  - the hovered plot is not visible to the local player
  - the hovered flag belongs to the local player
  - `UI.IsGameCoreBusy()` prevents simulation
- `Events.UnitOperationAdded`, `Events.UnitOperationDeactivated`, and `Events.UnitOperationsCleared` request a vanilla UnitPanel refresh for the selected unit.
- Normal panel refresh events such as `OnUnitSelectionChanged(...)`, `OnUnitCommandStarted(...)`, `OnUnitOperationAdded(...)`, `OnUnitOperationDeactivated(...)`, `OnUnitOperationsCleared(...)`, and movement-point refreshes update the UnitPanel itself, but they do not independently recompute combat preview unless one of the hover or mode-entry paths above runs again. `OnUnitSelectionChanged(...)` explicitly clears `m_combatResults`.
- Plot info does not call selected-unit info helpers. `worldInfo.lua` keeps a small local plot-unit display-name helper for aggregated plot summaries.
- `UnitFlagManager_CAI.lua` exposes `ExposedMembers.CAIInfo:RequestUnitFlagInfo(playerID, unitID, requestedKeys)` for visible unit flags only. The default bucket now speaks grouped count for exact spoken matches on the same tile, owner adjective, localized unit name, owned-unit queued movement, rounded damaged-health percent, and visible non-normal flag state (`Fortified`, `Embarked`).
- Owned local-player units now reuse `RequestUnitInfo(unitID, { "NextWaypoint" }, ownerID)` from `UnitPanel_CAI.lua`, so unit-flag and plot `units` speech says `Next waypoint: ...`. `UnitFlagManager_CAI.lua` no longer uses the older queued-destination direction helper for queued movement speech.
- `UnitFlagManager.lua` / `UnitFlagManager.xml` own the ambient world-map unit flags:
  - Persistent on-map information is mostly iconographic, not textual: frame style, unit emblem icon, optional health bar, promotion-or-levy badge, corps/army marker, religion badge, hero glow, barbarian attention `!`, and for air-capable hosts an air-capacity counter plus a popup list of stationed aircraft.
  - `CreateUnitFlag(...)` chooses style from the unit role: land combat and air -> military, naval -> naval, support -> support, civilian traders -> trade, religious civilians -> religion, and other civilians -> civilian.
  - `UpdateFlagType()` can override that role frame with embarked or fortified visuals, so the base role is not always what sighted players see.
  - There is no persistent visible name label on the flag itself. Identity/details live in the unit-icon tooltip from `UpdateName()`: civilization short name, multiplayer human player name when relevant, unit name, renamed-vs-type suffix, corps/fleet/army/armada suffix, archaeology home city and artifact owner, religion name, and levy status with turns remaining.
  - The religion badge is separately visible only when `GetReligionType() > 0` and `GetReligiousStrength() > 0`; its tooltip is the religion name.
  - Damage swaps the normal frame/button out for a visible health bar. Thresholds are green at `>= 80%`, yellow at `>= 40%`, and red below that.
  - Local human units dim when not `IsReadyToSelect()`. Selection overrides that dimming so the selected unit stays full alpha.
  - Hidden states are layered: non-visible fog state hides the flag; combat visualization temporarily force-hides attacker/defender/interceptor/anti-air flags; turning the relevant lens layer off hides the entire manager context; and stationed air units usually hide their own individual flags on airstrips, aerodromes, and carriers, except intercepting air units keep a visible flag.
  - Same-tile stacking is communicated visually with per-role offsets and duo/trio formation-link graphics. Those link graphics can be suppressed for non-local players when one member of the formation is hidden.
  - Clicking your own visible flag selects the unit when the current interface mode allows it. Clicking a visible enemy flag with a selected local unit can trigger range attack or move-to-attack.
- Vanilla does not appear to provide clean city-panel loc tags for labeling those two percentage values as speech output, so `CityPanel_CAI.lua` uses CAI loc tags for:
  - `LOC_CAI_CURRENT_PROGRESS`
  - `LOC_CAI_NEXT_TURN_PROGRESS`
- `CityPanel_CAI.lua` also listens to `Events.InputActionTriggered(actionId)` and uses an action-id-to-helper map instead of an `if` / `elseif` chain.
- Current city selection hotkey mapping in `src/data/hotkey_config.xml`:
  - `ReadSelectionSummary` -> `Name`, `Coords`, `Health`, `GrowthSummary`, `ProductionSummary`
  - `ReadSelectionInfo1` -> `Health`
  - `ReadSelectionInfo2` -> `ProductionSummary`
  - `ReadSelectionInfo3` -> `GrowthSummary`
  - `ReadSelectionInfo4` -> `HousingSummary`
  - `ReadSelectionInfo5` -> `BuildingsAmenitiesSummary`
  - `ReadSelectionInfo6` -> `ReligiousFollowersCount`
  - `ReadSelectionInfo7` -> `VisibleYields`
  - `ReadSelectionInfo8` -> `NormalFocusYields`
  - `ReadSelectionInfo9` -> `FavoredFocusYields`
  - `ReadSelectionInfo10` -> `IgnoredFocusYields`
  - `SelectionActions` -> `Tab`
- City yield focus states in `GetCityData(city)` are stored in `data.YieldFilters[yieldType]` and map to:
  - `YIELD_STATE.FAVORED`
  - `YIELD_STATE.IGNORED`
  - any other value = normal
- City yield preferences use a native three-state model:
  - `YIELD_STATE.FAVORED`
  - `YIELD_STATE.IGNORED`
  - neither state = normal
- CityPanel helpers for yield preference changes:
  - `OnCheckYield(yieldType, yieldName)` transitions normal to favored, or favored to ignored depending on the checkbox visual state
  - `OnResetYieldToNormal(yieldType, yieldName)` transitions ignored back to normal
  - `SetYieldFocus(yieldType)` and `SetYieldIgnore(yieldType)` are the lower-level command helpers used underneath
- `WorldTracker.lua` is a passive in-game HUD stack, not a modal chooser:
  - It builds `ResearchInstance`, `CivicInstance`, `OtherContainer`, `UnitListInstance`, `ChatPanelContainer`, and `TutorialGoals` under `Controls.WorldTrackerVerticalContainer` in that order.
  - The header has `Controls.ToggleAllButton` to collapse/expand the whole tracker and `Controls.ToggleDropdownButton` to open tracker options.
  - The options dropdown contains checkbox controls for chat, civics, research, and unit list visibility. `CheckEnoughRoom()` disables unchecked options and sets `LOC_WORLDTRACKER_NO_ROOM` when there is not enough vertical space.
  - Research and civics panels are shown only when their capability exists and the local player is alive. They call `RealizeCurrentResearch(...)` / `RealizeCurrentCivic(...)` from `TechAndCivicSupport.lua`, which populate title text, icon, turns remaining, progress meter, boost meter/icon/label, unlock icons, and overflow page-turn button.
  - The research/civics `IconButton` opens the matching chooser through `LuaEvents.WorldTracker_OpenChooseResearch()` / `LuaEvents.WorldTracker_OpenChooseCivic()`. Right-click Civilopedia callbacks are added to title/unlock controls outside tutorial mode.
  - If no current research/civic exists, the panel remains visible but the active title/icon are hidden and `UpdateResearchPanel(...)` / `UpdateCivicsPanel(...)` set the title button text to `LOC_WORLD_TRACKER_CHOOSE_RESEARCH` or `LOC_WORLD_TRACKER_CHOOSE_CIVIC`.
  - The unit list is hidden by default. When visible and `CAPABILITY_UNIT_LIST` exists, it rebuilds on unit add/remove/movement/activity events, groups units by broad type, filters by `UnitsSearchBox`, and each row left-clicks `OnUnitEntryClicked(unitID)` to look at and select that unit.
  - Unit rows use live text from `Button:GetText()`, optional tooltip for renamed units, status icon for sleep/skip/fortify, and text/icon color to indicate whether movement remains.
  - World Tracker hides itself during `VIEW_MODAL_LENS`, can be force-hidden/restored by research/civic choosers and tutorials, and in tutorial restore mode the normal collapse/options buttons are temporarily hidden while research/civics are forced visible.
  - CAI access should use world input actions rather than an ambient mirrored widget panel. Current mappings are `WorldTrackerOpenResearchChooser` -> `LuaEvents.WorldTracker_OpenChooseResearch()`, `WorldTrackerOpenCivicsChooser` -> `LuaEvents.WorldTracker_OpenChooseCivic()`, and `WorldTrackerReadSummary` -> live player-state speech.
  - `WorldTrackerOpenResearchChooser` / `WorldTrackerOpenCivicsChooser` should return without raising chooser LuaEvents when the live WorldTracker research/civic `IconButton`, `TitleButton`, or `MainPanel` is hidden/disabled. This lets tutorial and WorldTracker control filtering remain the source of truth instead of adding visibility guards inside the chooser push path.
  - WorldTracker summary speech should not depend on panel visibility. Build research/civic data from `Players[localPlayer]:GetTechs():GetResearchingTech()`, `Players[localPlayer]:GetCulture():GetProgressingCivic()`, `GetResearchData()`, and `GetCivicData()`. Speak only label, turns remaining, and boost status for each. Build unit count from `Players[localPlayer]:GetUnits():GetCount()`.
- Vanilla `ResearchChooser.lua` / `ResearchChooser.xml`:
  - `AddAvailableResearch(...)` writes the live row strings onto native controls: `TechName:SetText(...)`, `Top:LocalizeAndSetToolTip(...)`, `NodeNumber:SetText(...)`, `TurnsLeft:SetText(...)`, and boost icon `SetToolTipString(...)`.
  - `RealizeCurrentResearch(...)` writes the active header text through `TitleButton:SetText(...)`, uses the shared turns-left helper to populate `TurnsLeft`, and reuses the same boost icon tooltip path for current research.
  - CAI wrappers should prefer those live control values through `GetText()` / `GetToolTipString()` over rebuilding text with `Locale.Lookup(...)`, except for CAI-only wrapper labels or synthesized state strings that vanilla does not expose on a control.
- `TopPanel.lua` owns the global top-bar yields/resources:
  - `RefreshYields()` creates yield display instances under `Controls.YieldStack`.
  - Science, culture, and tourism use `YieldButton_SingleLabel` with `YieldIconString`, `YieldPerTurn`, and `YieldBacking` tooltip.
  - Gold and faith use `YieldButton_DoubleLabel` with `YieldIconString`, `YieldBalance`, `YieldPerTurn`, and `YieldBacking` tooltip.
  - Yield tooltips come from `ToolTipHelper_PlayerYields.lua`: `GetScienceTooltip()`, `GetCultureTooltip()`, `GetGoldTooltip()`, and `GetFaithTooltip()`. Tourism builds a tooltip from `LOC_WORLD_RANKINGS_OVERVIEW_CULTURE_TOURISM_RATE` plus `player:GetStats():GetTourismToolTip()`.
  - Base `TopPanel.lua` does not register click callbacks on the yield `YieldBacking` buttons. Only `MenuButton` and `CivpediaButton` get click callbacks in the base file.
  - `RefreshResources()` creates `ResourceInstance` rows under `Controls.ResourceStack`, showing only non-bonus, non-luxury, non-artifact resources with amount > 0. In practice this is the strategic-resource strip.
  - Each visible resource label uses text like `[ICON_RESOURCE_IRON] 3` and a tooltip of localized resource name plus `LOC_TOOLTIP_STRATEGIC_RESOURCE`.
  - If resources overflow the available top-bar width, vanilla shows a single `[ICON_Plus]` label whose tooltip lists the hidden resource amounts and names.
  - CAI TopPanel access should use input actions and pushed CAI widgets, not an ambient mirrored UI. Use vanilla loc strings and tooltip helpers directly; do not strip icon/color markup locally.
  - TopPanel player-yield APIs expose totals plus localized tooltip strings, not structured category tables. Known UI methods are `PlayerTechs:GetScienceYieldToolTip()`, `PlayerCulture:GetCultureYieldToolTip()`, `PlayerReligion:GetFaithYieldToolTip()`, `PlayerStats:GetTourismToolTip()`, `PlayerTreasury:GetGoldYieldToolTip()`, and `PlayerTreasury:GetTotalMaintenanceToolTip()`.
  - Gold has extra direct numeric APIs for major expense totals: `PlayerTreasury:GetBuildingMaintenance()`, `GetDistrictMaintenance()`, `GetUnitMaintenance()`, `GetWMDMaintenance()`, and `GetMaintDiscountPerUnit()`.
  - Yield detail access is a `Treeview`: each top-level yield node is the yield name plus value/rate preview. Use vanilla `LOC_HUD_REPORTS_PER_TURN` to append localized "per turn" text to any single rate value before composing larger labels. Outer yield nodes do not expose the full vanilla tooltip because the tree contains the formatted breakdown. Gold is split into vanilla `LOC_TOP_PANEL_GOLD_INCOME` and `LOC_TOP_PANEL_GOLD_EXPENSE` category nodes with localized tooltip detail lines beneath them. Science, culture, faith, and tourism use localized tooltip breakdown lines as category/detail nodes. CAI uses tooltip indentation/line structure for nesting and does not parse English text.
- `CivilopediaScreen.lua` / `CivilopediaSupport.lua` / `CivilopediaScreen.xml` define the in-game encyclopedia popup:
  - Vanilla opens it through `LuaEvents.ToggleCivilopedia()` or `LuaEvents.OpenCivilopedia(sectionOrSearch, pageId)`. The latter accepts either a direct section/page request or a search term and then navigates to the first result.
  - The sighted layout has five main regions:
    - a top horizontal section-tab strip with icon buttons for the major Civilopedia categories
    - a left search box plus vertical page list for the current section
    - optional collapsible page-group headers inside that page list
    - a breadcrumb/history strip with explicit Back and Forward buttons
    - a large scrollable article pane on the right
  - The article pane supports both a full-width chapter layout and a two-column layout. Two-column pages typically put text chapters on the left and portraits, quote panels, and stat boxes on the right.
  - Section tabs and page rows are mouse-first in vanilla. The active section/page is shown selected and disabled. Page-group headers toggle collapse/expand in place.
  - Search is live type-ahead. `SearchEditBox` calls `Search.Search("Civilopedia", str)` on text change, fills a separate result popup list, and Enter commits the current query by reopening the Civilopedia on the first hit.
  - Civilopedia maintains its own history trail in `m_kPageTrail`, with clickable breadcrumb buttons and input actions `CivilopediaBack` / `CivilopediaForward`.
  - The base context input handler only special-cases `Escape` to close. Vanilla does not provide a richer keyboard reading/navigation model for article content.
  - Article content itself can contain interactive navigation:
    - `HookupIcon(...)` wires many icon buttons to related Civilopedia pages when icon data includes a search target
    - right-column quote panels may expose a Play button that calls `UI.PlaySound(audio)`
    - technology, civic, unit, government, religion, and similar layouts use icon links for prerequisites, unlocks, upgrades, replacements, uniques, and related entries
  - Content is data-driven from `Assets/Gameplay/Data/Civilopedia.xml`: sections define top tabs, page groups define left-list buckets, pages and page queries populate entries, and page layouts map into Lua templates such as `Simple`, `Technology`, `Unit`, `Government`, `Feature`, and `Leader`.
  - CAI implication: model Civilopedia as a document browser with separate accessible structures for section tabs, page tree/search results, history, article chapters, and related-entry links. A flat single-speech dump would miss too much of the sighted interaction model.
- `navCursor.lua` owns the CAI map cursor:
  - Public movement should use Lua events, not `ExposedMembers.CAICursor`.
  - Absolute moves use `LuaEvents.CAICursorMove(x, y)`.
  - Directional moves use `LuaEvents.CAICursorMoveDirection(direction)`.
  - Cursor `SetCoords(x, y)` resolves the target plot directly with `Map.GetPlot(...)`; directional movement relies on `Map.GetAdjacentPlot(...)`.
  - Query-style access remains available through the WorldInput `UI` hijack: `UI.GetCursorPlotID()` and `UI.GetCursorPlotCoord()`.
  - `LuaEvents.CAICursorJump(plotId)` is the jump-specific public API for scanner jumps and selection-driven cursor snaps when CAI should also speak the direction from the prior cursor plot.
  - `LuaEvents.CAICursorMoved(x, y, plotId)` is the post-move notification event used by speech listeners.
  - Current default cursor input actions are `CAICursorMoveNorthWest`, `CAICursorMoveNorthEast`, `CAICursorMoveWest`, `CAICursorMoveEast`, `CAICursorMoveSouthWest`, and `CAICursorMoveSouthEast`, bound by default to `Q/E`, `A/D`, `Z/C` with numpad `7/9`, `4/6`, `1/3` as alternate bindings.
- `WorldInput_CAI.lua` wraps vanilla `WorldInput.lua`:
  - CAI installs all `UI` table overrides in one `InstallUIOverrides()` section. Current overrides are `UI.GetCursorPlotID()` and `UI.GetCursorPlotCoord()`.
  - CAI keeps the vanilla `Events.LoadScreenClose` boundary by wrapping `OnLoadScreenClose(...)`; the main game view widget is created and pushed only after the load screen closes.
  - CAI input action entries are records with `Type` and `Action`. Use `Type = "Started"` for repeat-style inputs such as cursor movement, and `Type = "Triggered"` for one-shot inputs such as path info or interface primary action.
  - CAI registers separate dispatchers for `Events.InputActionStarted` and `Events.InputActionTriggered`, while vanilla `WorldInput` keeps its own subscriptions.
  - Interface-mode-specific action records override shared action records for the same action id.
  - `InterfaceInfo` is the Space-bound world action. `WorldInput_CAI.lua` dispatches it to `SpeakActiveInterfacePlotInfo(...)`, which resolves the CAI cursor plot and calls the active `InterfaceInfoHelpers[UI.GetInterfaceMode()]` function.
  - Current default ActionPanel bindings are `SharedEndTurn` on `Ctrl+Space` and `ActionPanelOpenTurnBlockers` on `Ctrl+Shift+Space`; plain Space is reserved for interface-specific information.
  - CAI targeting widgets cover `RANGE_ATTACK`, `CITY_RANGE_ATTACK`, `DISTRICT_RANGE_ATTACK`, `AIR_ATTACK`, `WMD_STRIKE`, `ICBM_STRIKE`, and `COASTAL_RAID`. Return delegates to the matching vanilla execution handler and Escape delegates through vanilla `OnPlacementKeyUp(...)`.
  - Vanilla camera movement has two main paths: continuous camera panning through `UI.PanMap(panX, panY)` / `ProcessPan(...)`, and plot-centering through `SnapToPlot(plotId)` -> `UI.LookAtPlot(plot)`.
  - CAI cursor follow listens to `LuaEvents.CAICursorMoved(x, y, plotId)`, resolves the plot with `Map.GetPlotByIndex(plotId)`, and calls `UI.LookAtPlot(plot)` when the plot is valid. This follows the vanilla snap-to-plot pattern without selecting units/cities or changing interface mode.
  - Do not use `UI.PanMap(...)` for CAI cursor follow; it is designed for analog/held camera pan state and does not naturally target a discrete cursor plot.
- `LoadScreen.lua` is the shell-to-game loading context under `UI/FrontEnd/LoadScreen`:
  - It starts with `Input.SetActiveContext(InputContext.Loading)` and only installs its Lua input handler after `Events.LoadGameViewStateDone`.
  - `Events.LoadScreenContentReady` fires when player configuration/game data is ready enough to populate the loading screen; vanilla `OnLoadScreenContentReady()` fills the leader/civilization presentation.
  - `Events.LoadGameViewStateDone` fires when the game view is ready; vanilla sets `m_isLoadComplete = true`, hides the loading message, shows the Begin/Continue button, switches to `InputContext.Ready`, registers button callbacks, and subscribes to `Events.InputActionTriggered`.
  - The close/continue path is `OnActivateButtonClicked()`: unloads loading textures, raises `Events.LoadScreenClose()`, stops Dawn of Man speech/menu music, dequeues the load-screen popup, switches input to `InputContext.World`, resets active lens if needed, and performs Play-By-Cloud follow-up notification checks.
  - Escape, `StartGame`, and `StartGameAlt` only continue when `m_isLoadComplete` is true. Before that, input should not force the game forward.
  - Resync loads, multiplayer games, World Builder editor loads, and automation auto-start can bypass the visible Begin/Continue button by directly calling `OnActivateButtonClicked()` after game-view state is ready.
  - Visual layout is: full-screen black/background root, fallback/loading text, leader background image, leader portrait area, central colored banner, civilization icon/name, era line, leader/challenge name, leader/challenge text, feature/ability stack, loading message, and final Begin/Continue button.
  - Content sources are `Network.GetLocalPlayerID()` with hotseat fallback, `PlayerConfigurations[playerID]`, `GameInfo.LoadingInfo[leaderType]`, `GameInfo.Leaders`, `GameInfo.Eras`, `UI.GetSaveGameMetaData()` for saved-game era, `Challenges` loading texts, and `GetLeaderUniqueTraits()` / `GetCivilizationUniqueTraits()` from `Civ6Common.lua`.
  - Dawn of Man audio is separate from screen-reader output. CAI should not rely on it as the accessible announcement, and should avoid talking over it unless the user explicitly requests load-screen speech.
  - Suggested CAI access is a `LoadScreen.lua` wrapper imported/replaced in the front-end action set. Wrap `OnLoadScreenContentReady()` to capture/live-read populated control text and build a transient `Dialog` or `Panel`; wrap `OnLoadGameViewStateDone()` to add/enable the Begin/Continue button and speak readiness; wrap `OnActivateButtonClicked()` or `OnHide()` to pop/destroy the load-screen widget before the world view is initialized.
  - Keep the existing `WorldInput_CAI.lua` `Events.LoadScreenClose` boundary unchanged. Load-screen accessibility should end before `CAI_MainGamePanel` is pushed.
- `NotificationPanel.lua` owns the ambient right-side notification rail:
  - It creates generic `ItemInstance` rows under `Controls.ScrollStack` and tracks active entries in local `m_notifications[playerID][typeName]`.
  - Each visual notification instance has `MouseInArea`, `MouseOutArea`, `IconBG`, `IconBGInvalidPhase`, `Icon`, `CountImage`, `DismissStackButton`, expanded `TitleInfo`, `Summary`, `LeftArrow`, `RightArrow`, `PagePipStack`, and `Pages`.
  - Notification data should come from the live `Notification` object via `NotificationManager.Find(playerID, notificationID)`. Useful methods include `GetMessage()`, `GetSummary()`, `GetTypeName()`, `GetType()`, `GetIconName()`, `GetGroup()`, `GetCount()`, `GetEndTurnBlocking()`, `CanUserDismiss()`, `IsVisibleInUI()`, `IsValidForPhase()`, `IsLocationValid()`, `GetLocation()`, `IsTargetValid()`, `GetTarget()`, `Activate(true)`, and `GetValue(key)`.
  - `NotificationManager.SendNotification(playerID, notificationType, text, desc, mapX, mapY)` accepts the numeric notification type id, not the string type name. The tutorial code path proves that `notification:GetType()` can be compared directly against `GameInfo.Notifications["NOTIFICATION_FOO"].Hash`, so resolving custom notification ids through `GameInfo.Notifications[...]` is a safe runtime path when a `NotificationTypes.*` constant is uncertain.
  - Vanilla only creates notification rail entries when the notification is visible in UI, has a displayable icon, is the first visual entry for that type/stack, and is not an end-turn blocker. End-turn blockers are normally displayed by `ActionPanel`; CAI handles them outside the notification center.
  - `SetNotificationText(...)` sets the expanded title from `Locale.Lookup(pNotification:GetMessage())` and summary from `Locale.Lookup(pNotification:GetSummary())`.
  - Left-click activation calls `pNotification:Activate(true)`, which later raises `Events.NotificationActivated`; vanilla type-specific activate handlers then open the correct screen or look at/select the target.
  - Right-click dismiss calls `NotificationManager.Dismiss(...)` only when `pNotification:CanUserDismiss()` is true.
  - Stacked notifications share one visual row by type name. `LeftArrow` / `RightArrow` move the active index and either call `LookAtNotification(...)` or, for `COMMAND_UNITS`, select previous/next ready unit. The count badge's hidden `DismissStackButton` right-click dismisses every dismissible notification in that stack.
  - Wrong-phase notifications keep a visual row but left-click does nothing, right-click can dismiss, and the icon background switches to `IconBGInvalidPhase`.
  - Type-specific vanilla activation handlers include research/civic choosers, production, government/policies, raze city, pantheon/religion/artifact/great people/envoys, espionage escape route, continent lens, boost/completed popups, relic popup, PBC popups, user-defined notification activation, city ranged attack, command units, and default look-at/select behavior.
  - `RegisterHandlers()` explicitly assigns all nine `NotificationTypes.USER_DEFINED_*` entries both default handlers and `OnUserNotificationActivate`, which raises `LuaEvents.NotificationPanel_UserNotificationActivate(playerID, notificationID)`. These slots are convenient, but CAI can also register its own custom notification hashes in `g_notificationHandlers[...]` through the notification-panel wildcard include path.
  - `GetHandler(notificationType)` falls back to `NotificationTypes.DEFAULT` when a type has no explicit registration. That means a database-added notification type can still get generic rail UI, but it will not automatically get a custom Lua activation hook unless CAI or vanilla registers one.
  - `WorldView/CityBannerManager.lua` owns the floating map banners for cities and city-linked districts:
  - It creates two full city-center variants: `TeamCityBanner` for the local player and `OtherCityBanner` for everyone else, plus mini-banners for aerodromes, missile silos, encampments, and other districts.
  - Core city-center visuals for both variants are city name, population number, population meter, defense strength, district and outer-defense health bars when relevant, majority-religion or pantheon icon, and player-color styling. Foreign-city banners also show the owner's civilization icon.
  - The name line can carry situational markers: capital icon, trading-post icon, disabled trading-post icon, under-siege icon, occupied icon, insufficient-housing icon, insufficient-amenities icon, and city-state quest icon. The quest tooltip lists each active quest from that city-state.
  - Local-player city banners additionally show production directly in the banner: current production icon, progress meter, turns-left label, tooltip text, and a clickable production button. Foreign-city banners keep some of those controls in XML but vanilla hides the owner-only production visuals.
  - Population always shows as a large number. For the local player only, the banner also shows turns until growth or starvation, color-codes that turns label, and adds a tooltip with growth, stagnation, or starvation details plus food surplus.
  - Defense info comes from the city-center district: defense strength number, garrison hit points, optional outer-defense hit points, and color-coded health bars. A city-range-strike button appears only for the local player when the city can currently perform a ranged strike.
  - Religion has two layers. The normal banner can show a majority-religion icon or pantheon icon with a tooltip. When the religion lens is active, an attached religion panel appears under the banner with religion icons present in the city, conversion-turns status, a detailed follower list with pressure values, outgoing pressure, and a follower pie chart.
  - CAI no longer requires that religion lens panel to be visibly open for banner speech. `CityBannerManager_CAI.lua` now falls back to live `city:GetReligion()` data for conversion turns, follower-pressure lines, and outgoing pressure when the vanilla religion detail panel is hidden.
  - `AerodromeBanner` shows stationed aircraft as `current/max`, a capacity tooltip, and a dropdown list of air units with icon, uppercase name, and dimmed styling for units that cannot move. When the plot is only revealed, the count bar is hidden and the dropdown is disabled.
  - `WMDBanner` is local-player-only and shows nuclear and thermonuclear stockpile counts plus strike buttons that are enabled only when the silo has valid targets.
  - `EncampmentBanner` shows district defense strength, district hit points, optional outer-defense hit points, and a district ranged-strike button when usable by the local player.
  - `DistrictBanner` is normally force-hidden and becomes visible through the city-details or empire-details lens. When shown it displays the district or wonder icon, an under-construction overlay if incomplete, and a tooltip with the district or wonder name plus description.
  - CAI now ignores that lens-only force-hide for `BANNERTYPE_OTHER_DISTRICT` when resolving banner info reads. For accessibility reads, generic district name/type/construction/description can be spoken even with the lens off, as long as the underlying mini-banner instance exists and the plot is not fully hidden by fog.
  - Expansion 1 (`DLC/Expansion1/UI/CityBanners/CityBannerManager.lua`) keeps the base city-center and mini-banner inventory, but adds loyalty and governors to city-center banners:
    - A governor status widget in `CityStatusStack` with governor portrait/fill art, tooltip, turns-left label, and ambassador count.
    - A loyalty flyout under the city banner with a compact bar and an expanded panel. The compact panel shows owner civ icon, most-influential civ icon, a loyalty pressure icon, and a loyalty fill meter.
    - The expanded loyalty panel adds a loyalty percentage label plus per-source breakdown widgets for population pressure, governors, happiness, other modifiers, city-state bonus, and free-city bonus, and an `IdentityBreakdownStack` of detailed influence lines.
    - Expansion 1 also replaces the old center-row production display with `CityStatProduction` in the city status stack for city-center banners, alongside the population and governor widgets.
  - Expansion 2 (`DLC/Expansion2/UI/CityBanners/CityBannerManager.lua`) keeps the Expansion 1 loyalty/governor city-center additions and adds:
    - Two new improvement mini-banner types: `BANNERTYPE_MOUNTAIN_TUNNEL` and `BANNERTYPE_QHAPAQ_NAN`, each rendered as a small icon-only improvement banner with the improvement-name tooltip.
    - A new `CityDetailsEffects` stack and `CityDetailEffect` instances at the top of the city banner. Firaxis marks this in code as the XP2 difference for the power menu.
    - New `CityInfoType` and `CityInfoCondition` instance managers in the city info row, including rising/falling condition overlays. These are the extra icon/condition slots Expansion 2 adds around the city name for city detail summaries.
  - Click behavior is important for accessibility parity: clicking your own city banner selects the city, clicking a met major civ banner opens diplomacy, clicking a met city-state banner opens the city-state panel, clicking during trade-route mode sets that city as the destination, and clicking local mini-banners selects their district or triggers unit or strike actions.
  - CAI extends vanilla through the wildcard include file `src/UI/inGame/CityBannerManager_CAI.lua` and exposes `ExposedMembers.CAIInfo:RequestCityBannerInfo(requestedKeys)` for on-demand cursor reads.
  - The banner reader tracks the current cursor plot from `LuaEvents.CAICursorMoved`, resolves the active live city or mini-banner for that plot, and only speaks banner-backed information.
  - Dedicated city-banner bucket actions are `CityBannerReadIdentityStatus`, `CityBannerReadGrowthInfluence`, `CityBannerReadReligion`, and `CityBannerReadDiplomacy`.
  - The input-action bucket mapping is table-driven in `CityBannerManager_CAI.lua`, with separate `city` and `district` key lists so bucket order and banner-type variants can be edited in one place.
  - Base data defines `KIND_NOTIFICATION` rows in `Gameplay/Data/Notifications.xml` under both `Types` and `Notifications`. The base game already reserves `NOTIFICATION_USER_DEFINED_1` through `NOTIFICATION_USER_DEFINED_9` there, all grouped as `USER`.
  - CAI access uses `NotificationPanel_CAI.lua` through vanilla's `include("NotificationPanel_", true)` wildcard extension path rather than a full `ReplaceUIScript`.
  - `Ctrl+N` opens a transient `Treeview` notification center through the `NotificationPanelOpenList` input action.
  - Single notifications are direct tree leaves; grouped notification types become expandable parent nodes with one child per live notification.
  - Leaf `Enter` / `Space` calls `pNotification:Activate(true)` when valid for the current phase.
  - Leaf `Delete` calls `NotificationManager.Dismiss(...)` when `CanUserDismiss()` is true.
  - Group `Shift+Delete` dismisses all dismissible notifications in that group.
  - Notification leaf widget ids are `tostring(notificationID)`, matching the live notification instance id for direct lookup.
  - `NotificationPanel_CAI.lua` captures the base `OnNotificationAdded(...)` / `OnNotificationDismissed(...)` globals before base `Initialize()` runs, then replaces those globals so base `LateInitialize()` registers the wrapped versions.
  - The wrapped add path preserves vanilla rail creation, then adds the new notification to the open CAI tree in place when the notification center is open.
  - Live tree updates remove the `LOC_CAI_NOTIFICATION_EMPTY` placeholder, add direct leaves with `tree:AddChild(...)`, append children to existing grouped notification nodes, and convert a same-type direct leaf into a grouped node when a second notification of that type arrives.
  - CAI ties notifications back to vanilla's own `GetNotificationEntry(playerID, notificationID)` lookup and requires the returned entry to have a live `m_Instance`, matching the actual vanilla rail. This intentionally excludes end-turn blockers, which ActionPanel should handle.
  - Rebuilding the tree filters out notification ids that no longer have a vanilla rail instance, plus `IsDismissed()` / `IsExpired()` when those optional methods are available, so stale ids still returned by `NotificationManager.GetList(...)` are not reintroduced.
  - Activating a leaf closes the notification center before calling `pNotification:Activate(true)`, so vanilla action/camera behavior runs after CAI focus is gone.
  - CAI tutorial goals now use custom notification types `NOTIFICATION_CAI_TUTORIAL_GOAL_ADDED` and `NOTIFICATION_CAI_TUTORIAL_GOAL_COMPLETED`, resolved in Lua with `DB.MakeHash(...)`, sent with direct text via `NotificationManager.SendNotification(...)`, and activated through custom `g_notificationHandlers[...]` entries that open the tutorial goals list.
  - Vanilla `LookAtNotification(...)` syncs the CAI cursor through `LuaEvents.CAICursorJump(plotId)` when a notification has a valid location or target, except while the CAI notification center is open. Browsing the tree should not move the cursor.
  - `NotificationPanel_CAI.lua` also speaks new rail notifications from `Events.NotificationAdded` as `LOC_CAI_NOTIFICATION_ALERT`, followed by summary and `LOC_CAI_NOTIFICATION_AT_LOCATION` when coordinates are available.
  - Notification add speech is de-duplicated by notification id until dismissal because Civ VI can surface the same notification id through the add path more than once.
- Vanilla `ActionPanel.lua` / `ActionPanel.xml`:
  - Main purpose is the bottom-right end-turn/action button plus end-turn blockers. It reads blockers from `NotificationManager.GetFirstEndTurnBlocking(playerID)` and `NotificationManager.GetAllEndTurnBlocking(playerID)`.
  - Known blocker types are mapped in global `g_kMessageInfo` to localized message text, tooltip text, icon name, and optional sound. Covered blockers include units/stacked units, research, civic, policy slot, government change, raze city, production, pantheon/religion/belief, envoys, great person, spy escape route/dragnet priority, and artifact choice.
  - Primary controls are `EndTurnButton`, `EndTurnButtonLabel`, `EndTurnText`, and `CurrentTurnBlockerIcon`. The icon uses `SetIcon(icon)` and `EndTurnText` is truncated through `TruncateStringWithTooltip(...)`.
  - Extra blocker controls are `TurnBlockerButton2`, `TurnBlockerButton3`, and `TurnBlockerButton4`. Overflow blockers are built from `TurnBlockerInstance` rows under `OverflowStack`, opened by `OverflowCheckbox`.
  - Vanilla deduplicates ActionPanel blocker buttons by blocker type through `BlockerIsVisible(blockerType)`. Unlike the notification rail, ActionPanel does not expose left/right cycling between individual notifications of the same type.
  - The count badge `CountImage` / `Count` shows when there are two or more notifications of the active blocker type, but activating the button still calls `DoEndTurn(blockerType)`, which uses `NotificationManager.FindEndTurnBlocking(blockerType, playerID)` rather than a specific notification id.
  - Left-clicking the main button calls `DoEndTurn()`. Left-clicking a secondary/overflow blocker calls `DoEndTurn(blockerType)`. Right-clicking the main button only dismisses the city ranged attack notification in the special city-ranged-attack state.
  - `DoEndTurn(...)` can unready a multiplayer turn, select next ready unit, select a ranged-attack city and enter `InterfaceModeTypes.CITY_RANGE_ATTACK`, request `ActionTypes.ACTION_ENDTURN`, or raise `LuaEvents.ActionPanel_ActivateNotification(pNotification)` for generic blockers.
  - The panel has special non-notification states for auto-end-turn units with moves remaining and city ranged attacks, controlled by user options `AutoEndTurn` and `CityRangeAttackTurnBlocking`.
  - Waiting states set `EndTurnText` and tooltip to please-wait, waiting-for-player, Play-By-Cloud uploading/uploaded, or autoplay text. Multiplayer can include other active human player names and the unready-turn tooltip.
  - The era display uses `EraContainer`, `EraIndicator`, `EraToolTipArea1`, `EraToolTipArea2`, and `EraPipInstance`; `PopulateEraData()` builds pips from `GameInfo.Eras()`, and `RealizeEraIndicator()` rotates the indicator to the local player's era.
  - Turn timer display uses `TurnTimerContainer`, `TurnTimerMeter`, `TurnTimerLabelBG`, and `TurnTimerLabel`; `OnTurnTimerUpdated(...)` sets progress, active/inactive color, tooltip, countdown text, and low-time tick sounds.
  - Observer mode shows `ObserverButtonLabel` and `EndObserverModeButton`, both raising `LuaEvents.ActionPanel_EndObserverMode()`.
  - Input paths include `Input.GetActionId("EndTurn")`, `Events.InputActionTriggered`, and `ContextPtr:SetInputHandler(OnInputHandler, true)`. Enter triggers normal end turn; Shift+Enter forces `ActionTypes.ACTION_ENDTURN` with `REASON = "UserForced"` when no tutorial is running.
  - CAI `ActionPanel_CAI.lua` wraps `OnInputActionTriggered` with `WrapFunc(...)` after including vanilla and does not add its own input-action event subscription. `ActionPanel.lua` registers `OnInputActionTriggered` later from `LateInitialize()`, so the wrapped global is what vanilla registers. Adding another `Events.InputActionTriggered.Add(...)` from the wrapper can double-fire the action.
  - CAI replaces the context input handler with a manager-only handler via `ContextPtr:SetInputHandler(OnCAIActionPanelInputHandler, true)`. It routes input through `ExposedMembers.CAI_UIManager:HandleInput(...)` and otherwise returns false, intentionally avoiding vanilla `OnInputHandler` because vanilla maps Enter / Shift+Enter directly to end-turn actions.
  - `Events.EndTurnBlockingChanged` is the blocker change event, but vanilla's `OnEndTurnBlockingChanged(...)` does not set the spoken action text. The main button tooltip is assigned from `OnRefresh()` via `Controls.EndTurnButton:SetToolTipString(...)`, so CAI wraps and reinstalls the refresh handler with `ContextPtr:SetRefreshHandler(OnRefresh)`, then speaks the live `EndTurnButton` tooltip only when it changes. Tooltip speech is gated by `ContextPtr:IsHidden()` and, during tutorials, `LuaEvents.CAI_TutorialActionPanelAllowed`; when that tutorial event allows the ActionPanel, CAI forces one current-tooltip announcement.
  - Hotkey-triggered end turn must respect live `EndTurnButton` / `EndTurnButtonLabel` disabled state before calling vanilla `OnInputActionTriggered(...)`. During tutorials, it must also respect the current detailed item's ActionPanel UI trigger state from `LuaEvents.CAI_TutorialActionPanelAllowed`; the tutorial can block ActionPanel interaction through `UITutorialManager` without necessarily making the vanilla end-turn button report disabled to CAI. Also respect `TutorialSlowTurnEnableAnim` visibility because vanilla uses it as a short click-spam shield at turn begin.
  - CAI turn blocker list id is `CAIActionPanelTurnBlockerList`, opened by default with `Ctrl+Space`. It uses the vanilla primary action plus one deduplicated row per blocker type. Enter on a row calls `DoEndTurn()` or `DoEndTurn(blockerType)`, matching vanilla button behavior. Escape removes the list from the CAI stack.
  - Tutorial-only controls include `TutNotificationPointer`, many `TutSelectEndTurnAction*` callouts, and `TutorialSlowTurnEnableAnim`.
- Vanilla `GovernmentScreen.lua` / `GovernmentScreen.xml`:
  - The default keybinding is `ToggleGovernment`, bound to `LOC_OPTIONS_KEY_F7` in `Configuration/Data/InputConfiguration.xml`. `LaunchBar.lua` handles the action by calling `OnOpenGovernment()`, which raises `LuaEvents.LaunchBar_GovernmentOpenMyGovernment()` or `LuaEvents.LaunchBar_GovernmentOpenGovernments()` depending on current government/civic state.
  - The screen is a low-priority popup queued with `UIManager:QueuePopup(ContextPtr, PopupPriority.Low, { RenderAtCurrentParent=true, InputAtCurrentParent=true, AlwaysVisibleInQueue=true })`.
  - The top tab strip has up to three tabs: `ButtonMyGovernment`, `ButtonPolicies`, and `ButtonGovernments`. My Government and Policies are hidden until the player has a current government. Tab labels change between view/change wording based on `IsAbleToChangeGovernment()` and `IsAbleToChangePolicies()`.
  - My Government shows the current government card on the left/top area: government name, slot/stat summary, government art, inherent bonus, current accumulated/legacy bonus progress, and a scrollable heritage bonus stack. Below/alongside it are the same four active policy rows used by the Policies tab.
  - Policies shows four horizontal active policy rows: Military, Economic, Diplomatic, and Wildcard. Each row has a row label, count badges, category icon, watermark, optional empty-state text, and active policy card instances in `StackMilitary`, `StackEconomic`, `StackDiplomatic`, or `StackWildcard`.
  - The policy catalog appears to the right of the policy rows. It is a parchment panel with a horizontal scroll panel (`PolicyScroller` / `PolicyCatalog`) containing `PolicyCard` instances, plus filter tab buttons in `FilterStack`, back/forward filter scroll buttons, a hidden fallback pulldown, and bottom action buttons `ConfirmPolicies` / `UnlockPolicies`.
  - Policy cards are `140x150` draggable visual cards with title, description, colored type background, optional new icon, and tooltip. Drag/drop is the primary mouse flow; double-clicking a catalog card calls `AddToNextAvailRow(cardInstance)`, and double-clicking an active row card removes it.
  - Active policy row card rebuild is owned by `RealizeActivePoliciesRows()`. It destroys row children, rebuilds each occupied or empty slot, registers drag/drop/double-click/Civilopedia callbacks, updates row counters, and updates the confirm/unlock button state.
  - The Governments tab is a horizontal scroller (`GovernmentScroller`) with a parchment background. Government cards are grouped into columns by total policy-slot count, with vertical era-divider labels rendered between columns. Each government card shows name, stats, art strip, mini slot icons, inherent bonus, accumulated bonus/progress, selected overlay, locked overlay, and prerequisite civic icon/progress when locked.
  - Government selection is driven by `OnGovernmentSelected(governmentType)`, which opens a vanilla `PopupDialogInGame` confirmation. Accepting calls `RequestChangeGovernment(...)`, then usually switches to the Policies tab.
  - Policy confirmation is driven by `OnConfirmPolicies()`. It builds clear/add slot lists from `m_ActivePoliciesBySlot`, calls `RequestPolicyChanges(clearList, addList)`, resets the dirty flag, and closes the screen after confirmation.
  - Escape closes through `Close()`. Enter is consumed by `OnInputHandler()`; when the policies tab confirm overlay is visible and policies can be changed, Enter calls `OnConfirmPolicies()`.
  - Tab activation should use the vanilla tab callback path, not direct calls to `SwitchTabTo...()`. `m_tabs` is local to `GovernmentScreen.lua`, but `CreateTabs.AddTab(...)` stores the same select path on `Controls.Button...["CallbackFunc"]`; calling that callback changes vanilla visual selection and rebuilds the vanilla body. CAI tab widgets should switch tabs from `OnFocusEnter` so left/right arrow movement through the tab bar changes the active tab.
  - Vanilla tab text is set in `RealizeTabs()` on `Controls.ButtonGovernments` / `Controls.ButtonPolicies` with `SetText(Locale.Lookup(...))`. CAI should read the live control text rather than duplicating that label logic. For GovernmentScreen tab buttons, `GetTextControl():GetText()` may expose the visible text if direct `GetText()` is empty. For vanilla-populated controls such as `ModalScreenTitle`, `ModalScreenClose`, tab buttons, confirm buttons, and unlock buttons, do not add a CAI localization fallback; read `GetText()` / text subcontrols / `GetToolTipString()` from the control.
  - Vanilla registers `Mouse.eMouseEnter` hover sounds with `UI.PlaySound("Main_Menu_Mouse_Over")` for its government tabs, `ConfirmPolicies`, `PolicyPanelCheckbox`, unlock buttons, and filter navigation buttons. CAI should mirror the relevant exposed widgets by playing the same sound from `OnFocusEnter` for tabs, Confirm Policies, View All Policies, Unlock Policies, and Unlock Governments.
  - CAI accessibility should wrap this screen rather than replacing its game logic. The accessible government screen intentionally exposes only the Policies and Governments tabs; vanilla My Government can still exist internally, but any CAI My Government open state maps to Policies to avoid an extra navigation step.
  - CAI Policies is slot-first: four expandable row categories contain one child per live policy slot. Slot data can be rebuilt from `Players[Game.GetLocalPlayer()]:GetCulture():GetNumPolicySlots()`, `GetSlotType(slotIndex)`, and `GetSlotPolicy(slotIndex)`, mirroring vanilla `PopulateLivePlayerData(...)`; this is more reliable than capturing only filled card instances because empty cards do not pass through `RealizePolicyCard(...)`.
  - CAI policy assignment uses Enter on a focused slot to push a filtered policy `Treeview`. Picking an unused legal policy calls `SetActivePolicyAtSlotIndex(slotIndex, policyType)` for the exact slot. Delete on a filled slot calls `RemoveActivePolicyAtSlotIndex(slotIndex)`. Dedicated policy movement is intentionally omitted; replace/remove/reassign covers the needed gameplay result without exposing vanilla drag/drop movement as its own workflow.
  - CAI slot widgets should keep stable widget identity during pending policy edits. Store a small pending slot-policy mirror for labels/tooltips and suppress CAI body rebuilds while calling vanilla `RealizePolicyCatalog()` / `RealizeActivePoliciesRows()` after assignment/removal. Rebuilding from live player culture during an unconfirmed edit reads committed policy state and can make removal or replacement appear to fail.
  - CAI slot and government activation should use the default key-up binding path. Put item actions on the focused item itself so the manager handles them before input bubbles to the generic tree Return toggle or vanilla handler.
  - CAI View All Policies is a pushed read-only categorized policy `Treeview`; policy items expand to detail children. It replaces the inaccessible policy-list checkbox access from vanilla My Government and does not assign or remove policies.
  - CAI Governments is an expandable `Treeview`: government items own the Enter binding to `OnGovernmentSelected(governmentType)`, while child detail items expose slot mix, selected/locked state, bonuses, stats, and prerequisite details.
  - Do not rebuild the CAI Governments tree from `RealizeGovernmentsPage()` while the tab is already open. Vanilla calls that function when opening/canceling the government confirmation dialog, but the accessible government list is structurally stable; rebuilding there destroys focus. Rebuild on CAI tab switches/open instead.
- After `OnAcceptGovernmentChange()`, vanilla calls `m_tabs.SelectTab(Controls.ButtonPolicies)`. CAI should mirror this by switching/rebuilding to the Policies tab after the accepted government change, since the available policy slots can change.
- `OnAcceptGovernmentChange()` does not repopulate `m_ActivePolicyRows` by itself. A wrapper that rebuilds accessible policy slots from live culture data must refresh through `RefreshAllData()` or `PopulateLivePlayerData(...)` after the accepted government change; otherwise the screen can keep the old slot layout until close/reopen, which also leaves Confirm Policies disabled because CAI still sees an unfilled old/new slot mix.
- CAI policy confirmation / unlock buttons should not maintain a parallel action-state model here. Read label/hidden/disabled state directly from the live vanilla controls such as `Controls.ConfirmPolicies`, `Controls.UnlockPolicies`, and `Controls.UnlockGovernments`/`Controls.UnlockGovernmentsContainer`, because vanilla updates them in place while the screen stays open.
- After `SetActivePolicyAtSlotIndex(...)` / `RemoveActivePolicyAtSlotIndex(...)`, CAI can safely rebuild its own Policies body only if it preserves the current slot mirror. Rebuilding that body from committed live culture data during unconfirmed edits will drop the pending slot arrangement even though vanilla's local `m_ActivePoliciesBySlot` is already correct.
- GovernmentScreen CAI should keep its tab bodies alive for the lifetime of the open screen instead of destroying and recreating them on every refresh. Build the Governments and Policies trees once on open, then refresh only the changing children in place.
- Vanilla uses `RefreshAllData()` as the shared dirty-data path for multiple GovernmentScreen engine events, including `GovernmentChanged`, policy unlock/change events, and local-player turn/state updates. CAI should therefore refresh the active accessibility tree from the wrapped `RefreshAllData()` path as well, not only from explicit tab/page callbacks.
- Policies-side category rows are structurally static. Keep the four category `TreeviewItem` nodes alive, and on refresh call `:ClearChildren()` only on each row node before repopulating its slot widgets from the live culture data or pending slot-policy mirror.
- Governments-side refresh can clear the root governments tree and repopulate it directly; no CAI focus capture/restore is needed for this screen refresh path.
- GovernmentScreen CAI tree refreshers should be reactionary and render-only. `RefreshPoliciesTree()` and `RefreshGovernmentsTree()` should never call `RefreshAllData()` or otherwise initiate upstream vanilla data refresh; wrappers and direct CAI actions own the data-sync step, then call the render refresh.
- The only CAI-specific refresh guard still needed for this screen is the internal vanilla policy-control refresh guard used around `RealizePolicyCatalog()` and `RealizeActivePoliciesRows()`. This protects local pending CAI slot edits from being overwritten by an immediate live-state resync during vanilla control realization.
- The sensitive open-path timing is the CAI `Push()`/focus step, not panel-object creation by itself. Building the CAI panel before vanilla `OnOpenGovernmentScreen(...)` is fine because CAI widget labels are getter-based; the problematic sequence is pushing the panel before the CAI body exists, which causes an initial tab-bar focus bounce before focus moves into the body. Prefer: build panel if needed, run vanilla open/tab selection, build CAI body from the final selected tab, then push and focus the body once.
- Some live Civ VI button controls, especially nested `GridButton` layouts such as `UnlockGovernments`, may expose their visible text only on child controls. CAI control-text helpers should fall back to recursively checking child controls for nonempty live text before giving up.
- When CAI changes tabs programmatically, also update the CAI tab bar's `DefaultIndex` and `FocusedChild` to the selected tab widget. Otherwise Shift+Tab back from the body can restore the tab bar's stale focused child, e.g. Governments after vanilla has moved to Policies.
  - Important local tables such as `m_tabs`, `m_kPolicyCatalogData`, `m_kPolicyCatalogOrder`, `m_ActivePolicyRows`, and `m_kUnlockedGovernments` are not visible to a replacement wrapper after `include("GovernmentScreen")`. Capture populated government instances by wrapping `RealizeGovernmentInstance(governmentType, inst, ...)`; use public vanilla helpers such as `GetPolicyFromCatalog(policyType)`, `IsPolicyTypeLegalInRow(rowIndex, policyType)`, `IsPolicyTypeActive(policyType)`, and `IsPolicyAvailable(culture, policyHash)` for policy availability and derived data.
- Vanilla `CivicsChooser.lua` / `CivicsChooser.xml`:
  - The chooser is a left slide-out tray opened by `LuaEvents.ActionPanel_OpenChooseCivic` and `LuaEvents.WorldTracker_OpenChooseCivic`; it closes through `OnClosePanel()`, `LaunchBar_CloseChoosers`, the title/current-civic button, the icon button, the close button, or after choosing a civic.
  - Opening hides the visual WorldTracker through `LuaEvents.ResearchChooser_ForceHideWorldTracker()` and closing restores it through `LuaEvents.ResearchChooser_RestoreWorldTracker()`.
  - The top current-civic panel shows the active or most recently completed civic: title button, civic icon, progress meter, boost meter/icon/label, turns-left label, recommended icon, and unlock icons with overflow paging.
  - Below the current-civic panel is `OpenTreeButton`, which raises `LuaEvents.CivicsChooser_RaiseCivicsTree()` and closes the chooser.
  - Available civic rows are `CivicListInstance` instances under `CivicStack` inside `ChooseCivicList`. Each row has `TopContainer`, clickable `Top`, `TechName`, progress/boost meters, civic icon, boost icon/label, turns-left text, queue badge/number, unlock icon stack, overflow page-turner, and optional recommended icon.
  - `GetData()` reads live local player culture data from `Players[playerID]:GetCulture()`, current civic from `GetProgressingCivic()`, queue from `GetCivicQueue(...)`, and recommendations from `GetGrandStrategicAI():GetCivicsRecommendations()`.
  - `View()` sorts civics alphabetically by localized name, routes current/last-completed civic to `RealizeCurrentCivic(...)`, and calls `AddAvailableCivic(...)` for selectable rows. Repeatable current civics also appear in the available list.
  - `AddAvailableCivic(...)` builds row controls, sets tutorial tags from `UITutorialManager:GetHash(kData.CivicType)`, wires left-click to `OnChooseCivic(kData.Hash)`, wires right-click Civilopedia outside tutorial mode, disables rows when `GetCultureYield() <= 0`, and shows queue/recommended badges.
  - Choosing a civic calls `UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.PROGRESS_CIVIC, parameters)` with `PARAM_CIVIC_TYPE` and exclusive insert mode, plays `Confirm_Civic`, then closes the tray if expanded.
  - The data shape from `GetCivicData(...)` includes `ID`, `Hash`, localized `Name`, `CivicType`, `ToolTip`, `Cost`, normalized `Progress`, `TurnsLeft`, boost fields, repeatable flag, current/last-completed flags, queue position, and recommendation fields.
  - CAI can largely mirror `ResearchChooser_CAI.lua`: include vanilla `CivicsChooser`, wrap `View`, `AddAvailableCivic`, `RealizeCurrentCivic`, `OnInputHandler`, `OnChooseCivic`, and `OnClosePanel`, then expose an accessibility `Panel` with a read-only current/queue tree, an available civics tree, Open Civics Tree, and Close.
  - Unlike ResearchChooser, vanilla CivicsChooser has no base-tutorial special reorder handler. It does use tutorial tags/disabled state, so CAI rows should keep a mapping from civic hash to native row instance and read live `TopContainer` / `Top` hidden-disabled state.
- Vanilla diplomacy flow:
  - First contact / greeting uses `Popups/LeaderView.lua` plus `LeaderView.xml`, not `DiplomacyActionView.lua`.
  - `LeaderView.xml` is minimal: `LeaderText`, `DeclareWarButton`, and `GoodbyeButton`. `ShowFirstMeetingLeader(...)` sets `LeaderText` to `LOC_LEADER_SCREEN_GREETING`, shows the leader scene with `Events.ShowLeaderScreen(...)`, and opens the popup for either participant in `Events.LeaderPopup` / `Events.DiplomacyMeet`.
  - In the current base file, first meet only exposes the greeting text and Goodbye flow. The declare-war button exists in XML but `ShowFirstMeetingLeader(...)` does not unhide it.
  - The same lightweight popup is also reused for some direct leader popups such as war declaration / refuse peace, with `LeaderText` changed to `LOC_DECLARE_WAR` or `LOC_REFUSE_PEACE`.
  - Talking to an already met leader routes out of `LeaderView.lua` into the full diplomacy screen through `OnTalkToLeader(playerID)`, which is subscribed to `LuaEvents.CityBannerManager_TalkToLeader` and `LuaEvents.DiploPopup_TalkToLeader`.
  - The repository contains `src/UI/inGame/LeaderView_CAI.lua`, but the current `src/CivViAccess.modinfo` does not register a `ReplaceUIScript` for `LuaContext` `LeaderView`. In the current build, first-meet / war / refuse-peace `LeaderView` popups therefore bypass CAI entirely unless that registration is restored.
  - The CAI wrapper includes vanilla `LeaderView`, keeps the leader scene active underneath, and pushes a transient CAI `Dialog` built with `WidgetTemplateHelpers:MakeGeneralDialog(...)`.
  - The CAI dialog reads only live vanilla control text: title and body from `Controls.LeaderText:GetText()`, plus visible button labels from `GoodbyeButton` / `DeclareWarButton`.
  - The CAI dialog should be rebuilt from the `LeaderView` context show/hide lifecycle rather than by rebinding the popup events. That avoids depending on the order of include-time `Events.*` registrations inside `LeaderView.lua`.
  - CAI wraps `OnContinue()` and removes the CAI dialog before calling the vanilla close path.
  - CAI wraps `OnDeclareWar()`, removes the CAI dialog before the vanilla action, then rebuilds a fresh dialog from the updated live popup state because vanilla `OnDeclareWar()` does not close the popup.
  - `LeaderView.lua` registers its events during `include("LeaderView")`, so post-include function reassignment is not a reliable hook for meet-popup open paths. The safer hook is the context becoming visible, plus direct wrapping of local close/action functions such as `OnContinue()` and `OnDeclareWar()`.
  - `LeaderView` cleanup must remove the specific CAI dialog by id through `mgr:RemoveFromStack(...)`; plain `mgr:Pop()` can close the wrong root if another accessibility popup is currently above it.
  - CAI installs a context input handler for `LeaderView` that routes input through the UI manager only while the popup is visible and the CAI dialog is the active top widget.
  - CAI also installs a hide handler so external popup hides clean up the CAI dialog even if the flow bypasses `OnContinue()` / `OnDeclareWar()`.
  - The full diplomacy hub is `DiplomacyActionView.lua`. `OnOpenDiplomacyActionView(otherPlayerID)` initializes the screen, populates a vertical diplomacy ribbon of met leaders, selects the target leader, and opens in `OVERVIEW_MODE`.
  - Verified open routes into `DiplomacyActionView` are `LuaEvents.DiplomacyRibbon_OpenDiplomacyActionView`, `LuaEvents.TopPanel_OpenDiplomacyActionView`, `LuaEvents.CityBannerManager_TalkToLeader`, `LuaEvents.DiploPopup_TalkToLeader`, and the lite variant `LuaEvents.DiplomacyActionView_OpenLite`.
  - `TopPanel_OpenDiplomacyActionView` is raised by `PartialScreenHooks.lua` `OnOpenDiplomacy()` with no explicit player id, so the default top-panel open path falls through to the diplomacy screen's local-player/self selection behavior.
  - `DiplomacyRibbon.lua` opens the full diplomacy hub when a met leader portrait is clicked. It always shows the local player first, then met major leaders ordered by met turn.
- The diplomacy overview body is split into two areas: top-level statement/action buttons on the left and an intel panel on the right. `PopulatePlayerPanel(...)` calls `AddStatmentOptions(...)` and `AddIntelPanel(...)`.
- For CAI, the accessible overview can be safely reshaped into two persistent widgets without replacing vanilla game logic: one leaders tree that owns self/intel detail nodes, and one action list that mirrors the root action list plus submenu stacks.
  - Top-level actions come from the parsed `GREETING` diplomacy statement. `GetInitialStatementOptions(...)` groups actions by `GameInfo.DiplomaticActions[...].UIGroup`, turning `DISCUSS` and `FORMALWAR` into submenu buttons and leaving other valid actions on the root list.
  - Verified direct action/session entries in `OnSelectInitialDiplomacyStatement(...)` include `CHOICE_MAKE_PEACE`, `CHOICE_MAKE_DEAL`, `CHOICE_VIEW_DEAL`, `CHOICE_MAKE_DEMAND`, `CHOICE_VIEW_DEMAND`, `CHOICE_DENOUNCE`, `CHOICE_DIPLOMATIC_DELEGATION`, `CHOICE_DECLARE_FRIENDSHIP`, `CHOICE_RESIDENT_EMBASSY`, `CHOICE_OPEN_BORDERS`, and promise-demand actions for spying, settling nearby, converting cities, and digging artifacts.
  - War choices are a submenu. Verified supported casus belli entries are surprise, formal, holy, liberation, reconquest, protectorate, colonial, and territorial war.
- Conversation sessions use `CONVERSATION_MODE` or `CINEMA_MODE` depending on the leader animation. `VOICEOVER_SUPPORT` currently includes `KUDOS`, `WARNING`, `DECLARE_WAR_FROM_HUMAN`, `DECLARE_WAR_FROM_AI`, `FIRST_MEET`, `DEFEAT`, and `ENRAGED`.
- Voiced diplomacy can open hidden in `CINEMA_MODE` first. In that path `SelectPlayer(..., CINEMA_MODE, ...)` only sets `m_cinemaMode = true` while hidden, `OnShow()` plays the cinema presentation, and later `ToggleCinemaMode()` reveals the real response popup again. There is no single universal "conversation opened" helper in base Lua that covers both normal conversation and all close paths. `SetConversationMode()` is a real open point for normal conversations, but cinema reveal and session close still fan out through separate mutators such as `ToggleCinemaMode()`, `SelectPlayer(..., OVERVIEW_MODE, ...)`, deal/demand apply handlers, and `OnDiplomacySessionClosed(...)`. Any CAI wrapper that assumes one global open hook, or that reconstructs state after the fact instead of following the actual statement/apply lifecycle, is likely to drift.
- The intel panel has tabs for Overview, Gossip, Access Level, and Relationship. The Relationship tab is omitted for human-controlled targets.
- When mirroring the intel panel into CAI tree nodes, keep the first-level tab widgets persistent and do not hide non-selected leaders' child nodes in CAI. Leader focus already triggers a real vanilla selection change plus refresh, which should resolve focus and live detail content naturally. Also do not force leader/tree expansion from selection state; user collapse/expand state should stay under CAI tree control.
- In a replacement `DiplomacyActionView` wrapper, the local intel `InstanceManager` objects and per-row local instance tables are not directly safe to read by name after `include("DiplomacyActionView")`. Prefer capturing live instance tables from vanilla callbacks that receive them, such as `PopulateIntelOverview(overviewInstance)`, `OnActivateIntelGossipHistoryPanel(gossipInstance)`, `OnActivateIntelAccessLevelPanel(accessLevelInstance)`, and `OnActivateIntelRelationshipPanel(relationshipInstance)`. The overview sub-row instances themselves are still created inside local helper functions, so if you need those exact row controls you must either capture them at creation time or rebuild just that sub-data from stable game APIs.
- Selecting yourself in `DiplomacyActionView` switches to a self-view instead of the normal action/intel panel: the right-side player panel is hidden, the large leader/civ header stays visible, and the body becomes a scrollable "Features & Abilities" list built from leader/civilization unique abilities, units, and buildings.
- For CAI text on this screen, prefer live vanilla controls and vanilla loc keys over CAI-owned replacements wherever the base screen already exposes the text. Useful direct sources include `Controls.PlayerNameText`, `Controls.CivNameText`, `Controls.LeaderResponseName`, and `ms_IntelPanel.IntelHeader`. Keep CAI localization only for wrapper-owned group labels or synthesized states that vanilla never names on a control.
  - Overview rows are built in this order: recent gossip count, access level, current government, agendas, active agreements, our relationship with them, and their relationships with other met leaders.
  - Overview gossip is only a summary count for the last turn: `LOC_DIPLOMACY_GOSSIP_ITEM_COUNT` or `LOC_DIPLOMACY_GOSSIP_ITEM_NONE_THIS_TURN`.
  - Overview access level shows current diplomatic visibility icon plus `GameInfo.Visibilities[iAccessLevel].Name`.
  - Overview government shows the target's current government, anarchy with turns remaining, or `LOC_DIPLOMACY_GOVERNMENT_NONE`.
  - Overview agendas show the historical agenda for AI leaders, then either revealed random agendas or a hidden-agenda count depending on current visibility. Human targets hide this row.
  - Overview agreements can show delegation, embassy, defensive pact, open borders in either direction, research agreement, and joint war.
  - Overview "our relationship" shows the selected leader's diplomatic state toward us, with special tooltip handling for denouncements and declared friendship turns remaining.
  - Overview "other relationships" shows non-neutral relationships the selected leader has with other met major players, filtered through `DiplomacyRibbonSupport.lua` rules. Valid displayed states include allied, declared friend, denounced, war, and for AI also unfriendly/friendly.
  - The Access Level tab shows active visibility sources, the info shared at the current level, the info unlocked at the next level, and advisor suggestions for new visibility sources.
- The Gossip tab shows visible gossip from the last 100 turns, split into "last ten turns" and older items, with a "new" indicator for this turn or last turn. If there is no recent gossip, the first section shows `LOC_DIPLOMACY_GOSSIP_ITEM_NO_RECENT`.
- The Relationship tab shows the selected AI leader's diplomatic state toward us, a relationship bar/icon, sorted positive and negative modifier reasons from `GetDiplomaticModifiers(...)`, and advisor suggestions for improving or worsening relations.
- In CAI wrappers, do not rely on `LastTenTurnsStack:GetChildren()` or `RelationshipReasonStack:GetChildren()` to recover per-row data by field name after vanilla instance-manager rebuilds. The stable sources are `Game.GetGossipManager():GetRecentVisibleGossipStrings(...)` for gossip rows and `selectedPlayerDiplomaticAI:GetDiplomaticModifiers(ms_LocalPlayerID)` for relationship-reason rows; live control text remains appropriate for section headers and advisor text blocks.
- Root diplomacy actions are rendered as one vertical button list plus an optional sublist. `DISCUSS` and `FORMALWAR` actions become submenu buttons, and opening a submenu adds an explicit Cancel button that returns to the root list.
- In CAI, root diplomacy actions map cleanly to a `List` containing `Button` rows for direct actions and `SubMenu` rows for grouped actions. Submenu expansion should rebuild its button children from the current live vanilla sub-option stack, and submenu collapse should mirror `ShowOptionStack(false)`.
- Conversation close is still fragmented in base Lua. Besides overview-return and deal/demand close paths, CAI should also clear its conversation dialog and cached bindings on concrete goodbye/session-close paths such as `CHOICE_EXIT` activation and `OnDiplomacySessionClosed(...)`.
  - `DiplomacyDealView.lua` is the separate make-deal / make-demand screen. `DiplomacyActionView` opens it through `LuaEvents.DiploPopup_ShowMakeDeal(ms_OtherPlayerID)` or `LuaEvents.DiploPopup_ShowMakeDemand(ms_OtherPlayerID)`.
  - Sighted players normally reach `DiplomacyDealView` from the full diplomacy hub, not directly from the map. `DiplomacyRibbon.lua` opens `DiplomacyActionView` from leader portraits, `PartialScreenHooks.lua` opens the diplomacy hub from the top panel, and `DiplomacyActionView.lua` then switches from a `MAKE_DEAL` or `MAKE_DEMAND` statement into the separate deal screen by hiding its own overview/conversation containers and raising the `DiploPopup_ShowMakeDeal` / `DiploPopup_ShowMakeDemand` Lua events.
  - Available trade inventory groups are gold, luxury resources, strategic resources, agreements, cities, other players, great works, and captives.
  - The current deal area can show resources, agreements, cities, great works, and captives. City deal entries can expand for detailed city contents.
  - Deal action buttons include `EqualizeDeal`, `AcceptDeal`, `DemandDeal`, `RefuseDeal`, and `ResumeGame`, with visibility depending on whether the current screen is a deal, a demand, or a pending viewed proposal.
  - Visually, `DiplomacyDealView.xml` is a full-screen modal sheet with a tall parchment/banner panel on the left half of the screen, an animated leader speech bubble at the top, and a small animated yield strip in the top-right for science, culture, faith, and gold. Inside the main trade panel, the content is split into two mirrored columns: left for the local player and right for the other player.
  - The body is vertically divided into two mirrored sections. The upper section is the current offer area, labeled `My Offer` and `Their Offer`; the lower section is the inventory area showing what each side can add. A draggable resize handle sits between them, so sighted players can drag the divider to give more height to offers or inventory.
  - Inventory items are presented as icon tiles or icon-plus-text rows grouped under headers. Gold and resources are mostly compact horizontal icon rows. Agreements, cities, great works, and captives use vertical category blocks with collapsible headers. When collapsed, the category turns into a minimized icon strip rather than disappearing completely.
  - Offer items are interactive review rows rather than plain text. Left click edits an item's amount or parameter when the item supports it, right click removes the item, and a dedicated remove button is also shown on the row. For AI-proposed items the screen can also show a small "don't ask again" marker button for unacceptable items.
  - Editing an item opens a centered darkened-overlay popup inside the same screen. For gold/resources it shows the item icon, amount field, left/right arrow buttons, and a confirm/back button. For agreement items it instead shows a scrollable option list, such as alliance type, research target, or joint-war target.
  - City items are visually richer than other rows. They can show a collapse/expand button that reveals child detail icons inside the row's own detail grid, so sighted players can inspect the city's bundled contents before deciding whether to keep it in the trade.
  - The leader-dialog bubble at the top is reused as deal feedback text. It changes to reactions such as unfair deal, invalid deal, gift, acceptable proposal, equalize failed, and demand flavor text, so sighted players get immediate conversational feedback while modifying the deal.
  - Human interaction on this screen is strongly mouse-oriented in vanilla. Players click inventory items to add them, click or arrow-adjust existing deal items to edit values, right click or hit remove to take items back out, click header chevrons to collapse deal categories, drag the central resize handle, and use the bottom action buttons to propose, accept, demand, refuse, cancel, or resume.
  - Keyboard handling in base Lua is minimal here. `DiplomacyDealView.lua` explicitly handles Escape only, routing it to popup close, Resume Game, or Refuse/Cancel depending on state. Everything else is expected to go through ordinary control focus/click behavior rather than a screen-specific keyboard navigation layer.
- Vanilla `InGamePopup.lua`:
  - `PopupDialogInGame:Open()` raises `LuaEvents.OnRaisePopupInGame(id, options)`, which is handled by the separate `InGamePopup` context. Government confirmation dialogs therefore do not receive input through `GovernmentScreen`'s input handler.
  - Vanilla `InGamePopup` uses the old `InputHandler(uiMsg, wParam, lParam)` signature and registers it with `ContextPtr:SetInputHandler(InputHandler)`. CAI replacement should wrap that handler, call `mgr:HandleInput(input)` first, then preserve vanilla Escape/Enter behavior by calling the original handler with `input:GetMessageType()` and `input:GetKey()`. Register the wrapper with `ContextPtr:SetInputHandler(InputHandler, true)`.
- CAI `Treeview` / `TreeviewItem` widgets:
  - `Treeview` provides shared Left/Right/Return bindings. Right expands the focused node or moves to its first child; Left collapses the focused node or moves to its parent; Return toggles the focused node.
  - Screens should not add their own expand/collapse bindings. Use `TreeviewItem.OnToggleExpanded` to synchronize vanilla visual state when expansion changes.
  - `TreeviewItem:GetValue()` announces `LOC_CAI_TREEVIEW_EXPANDED`, `LOC_CAI_TREEVIEW_COLLAPSED`, and `LOC_CAI_TREEVIEW_ITEM_COUNT` for expanded nodes.
- CAI interface preview helpers:
  - `interfaceInfoHelpers_CAI.lua` is the shared helper module for interface-specific plot previews.
  - `interfaceTargetHelpers_CAI.lua` owns neutral active-target resolution used by both interface info and the world scanner.
  - The legacy movement path helpers remain there unchanged for callers such as `UnitPanel_CAI.lua`.
  - Vanilla movement-path behavior lives in `decompiled/Assets/UI/WorldInput.lua`, centered on `RealizeMovementPath(showQueuedPath)`. That function is primarily a renderer for sighted feedback, not a text-summary API.
  - Lifecycle and entry points for vanilla move-path visuals:
    - entering `InterfaceModeTypes.MOVE_TO` calls `OnInterfaceModeChange_MoveTo()` -> `RealizeMovementPath()`
    - while already in move mode, mouse move calls `OnMouseMoveToUpdate()` -> `RealizeMovementPath()`
    - while in normal selection mode, holding right mouse to quick-move calls `OnMouseSelectionUnitMoveStart()` / `OnMouseSelectionMove()` -> `RealizeMovementPath()`
    - touch pathing calls `OnTouchSelectionStart()` / `OnTouchSelectionUpdate()` or `OnTouchMoveToUpdate()` -> `RealizeMovementPath()`
    - selecting a unit with a queued destination calls `OnUnitSelectionChanged(..., isSelected=true, ...)` -> `RealizeMovementPath(true)`
    - cancelling movement clears the active preview, then restores queued-path preview if the selected unit still has one
    - leaving move mode calls `OnInterfaceModeChange_MoveToLeave()` -> `ClearMovementPath()`
  - Queued-order ownership:
    - Vanilla Lua clearly knows about already queued movement through `UnitManager.GetQueuedDestination(unit)`, but the actual act of making a move become queued is not exposed as a Lua branch in the decompiled UI.
    - `WorldInput.lua` move confirmation paths such as `OnMouseSelectionUnitMoveEnd()` and `OnMouseMoveToEnd()` simply call `MoveUnitToCursorPlot(unit)` with no `Shift` or queue-specific condition.
    - `MoveUnitToCursorPlot()` in `WorldInput.lua` delegates to `MoveUnitToPlot()`, and `MoveUnitToPlot()` / `RequestMoveOperation()` in `Civ6Common.lua` submit the same normal `UnitManager.RequestOperation(unit, UnitOperationTypes.MOVE_TO, tParameters)` request used for ordinary movement.
    - The only move modifiers Lua supplies there are combat / fog related (`ATTACK`, `MOVE_IGNORE_UNEXPLORED_DESTINATION`, or `NONE`); no exposed `UnitOperationMoveModifiers` value represents `queue movement`.
    - Practical implication: sighted queued movement is a real engine-level state that Lua can read back and render, but the input rule that turns a move order into a queued order is likely handled below Lua rather than by a visible `if Shift then queue` script branch.
  - Early-exit conditions:
    - no path is shown if `UI.IsMovementPathOn()` is false or `UI.IsGameCoreBusy()` is true
    - no path is shown with no selected unit
    - no path is shown for `IgnoreMoves` units
    - no path is shown when `UI.GetCursorPlotID()` is not a valid plot
  - `RealizeMovementPath(...)` computes or consumes these concrete data points:
    - end plot: current cursor plot, or `UnitManager.GetQueuedDestination(unit)` when `showQueuedPath=true`
    - full path data from `UnitManager.GetMoveToPathEx(unit, endPlotId)`, notably `plots`, `turns`, `obstacles`, `entrancePortals`, and `exitPortals`
    - tutorial / constrained-path invalidity from `IsPlotPathRestrictedForUnit(pathInfo.plots, pathInfo.turns, unit)`
    - fog-of-war state by checking every plot in the path against `PlayersVisibility[localPlayer]:IsVisible(plotId)`
    - enemy presence on the destination plot by scanning visible units in that plot
    - implicit ranged-attack targeting by checking `UnitManager.GetOperationTargets(unit, UnitOperationTypes.RANGE_ATTACK)` for the hovered end plot
    - swap-with-unit validity by testing `UnitManager.CanStartOperation(unit, UnitOperationTypes.SWAP_UNITS, nil, params)`
  - What a sighted player is told by the movement preview:
    - The preview is almost entirely visual. Vanilla does not build a spoken or tooltip summary string here.
    - Path validity category is conveyed by lens family:
      - `MovementGood`: ordinary valid movement path
      - `MovementQueue`: queued path for an already issued order
      - `MovementBad`: restricted / invalid path, including tutorial-forbidden destinations
      - `MovementFOW`: otherwise valid path that enters fog or mid-fog
    - Origin / destination are shown with dedicated path-end variants such as `_Origin` and `_Destination`.
    - Turn count is conveyed visually by numbered markers added with `UI.AddNumberToPath(turnNumber, plotId)`. Markers are placed at each turn break and at the final path plot. This is not a per-step numeric breakdown.
    - Non-turn-break intermediate plots are shown as ordinary pips (`..._Pip`).
    - Obstacles along the path, such as river crossings, are shown with `..._Minus` markers between the obstacle plot and the following plot.
    - If the cursor target is a valid same-turn ranged attack for the selected unit, vanilla does not show a movement path at all. It instead highlights the target hex in the attack-range lens and focuses that hex.
    - If the cursor target is a valid unit-swap destination, vanilla shows a special two-plot move path with turn `1` markers on both ends.
    - If no multi-plot path exists:
      - same tile: only a `MovementGood_Destination` marker on the current plot
      - different invalid tile: only a `MovementBad_Destination` marker on the target plot
    - If a visible enemy unit is on the destination and arrival is this turn, vanilla hides the normal destination marker. For later-turn arrivals, the destination marker is still shown.
    - Mountain-tunnel travel is drawn as segmented path pieces using `exitPortals` / `entrancePortals`; the function comments note there are no special portal-entry/exit variations yet.
  - Non-visual feedback in this path system is minimal:
    - when a path first becomes multi-turn (`lastTurn == 2` and the previous preview was 1 turn), vanilla plays `UI_Multi_Turn_Movement_Alert`
    - when confirming a move after at least one realized turn count, vanilla plays `UI_Move_Confirm`
    - `RealizeMovementPath(...)` itself does not generate text, tooltip content, or combat-preview strings
  - Design implication for CAI:
    - vanilla preview exposes a small set of stable semantic facts: valid / queued / restricted / fog, implicit ranged attack vs movement, visible enemy-at-end affecting marker visibility, turn-break count, obstacles, swap, and portal segmentation
    - many current CAI movement sentences are interpretations layered on top of those visuals, not direct vanilla wording. A clean redesign should treat the items above as the real vanilla source model and decide separately what spoken abstraction best serves blind play.
  - CAI movement speech now treats `UnitManager.GetMoveToPathEx(...)` as the source for path structure and uses the final `pathInfo.turns[#pathInfo.turns]` entry as the arrival turn. Do not use `#pathInfo.turns` as the turn count; that is the number of path nodes.
  - Implicit ranged-attack detection must run before movement-failure diagnosis, not only after a successful path build. Otherwise hostile cursor targets for ranged units can fall through to bogus move-failure speech like `Blocked by unit` instead of the intended attack-preview branch.
  - Mirror vanilla `RealizeMovementPath(showQueuedPath)` branch order when classifying preview state: queued-destination override, invalid-plot bail, swap test, `GetMoveToPathEx(...)`, implicit ranged-attack check only on real multi-plot paths, then queue/restricted/FOW/good lens selection. Keep the separate fallback branch for `#pathInfo.plots <= 1`: off-unit targets are the no-path `MovementBad` case, while the current unit tile is the same-tile case.
  - Vanilla has two different `MovementBad` shapes that CAI must not collapse together. A restricted path still has a real route, counters, and path details; a no-path target has only a bad destination marker. Speech should only announce enemy-at-end, delayed-combat, and route geometry for branches that actually have a real path.
  - Movement path direction speech should use `CAIHexCoordUtils.stepListFromPath(...)` with `{ x, y }` path nodes. Civ VI vanilla uses `IsVisible(...)` to choose the `MovementFOW` lens, but speech must distinguish revealed fog from unexplored tiles: use `IsRevealed(...)` for the route-geometry cutoff and only say `Then unexplored` after the first unrevealed path tile.
  - If active `MOVE_TO` interface info would immediately resolve as combat against an at-war visible unit, city, or district, CAI requests `LuaEvents.CAISpeakCombatPreview()` and suppresses movement speech. Queued-path reads keep speaking queued movement information instead of firing combat preview.
  - `MovementActions_CAI.lua` now owns shared move-target activation for both `MOVE_TO` primary action and the adjacent quick-move hotkeys. It analyzes destination plot ids directly with `BuildMovementPathInfo(...)`, arms one pending `{ owner, unitId, targetPlotId }` combat confirmation only for immediate move-to melee combat, silently syncs the CAI cursor to the target, then commits through the same vanilla `OnMouseMoveToEnd()` path used by mouse move confirmation.
  - Quick-move hotkeys are selection-driven, not cursor-driven. They resolve adjacency from the selected unit's live plot with `Map.GetAdjacentPlot(...)`, reuse the same movement-failure speech path as move mode, and only require a second press when the exact same unit and target plot are still immediate combat on a fresh re-analysis.
  - When `GetMoveToPathEx(...)` fails and CAI synthesizes a bad-path result with no real path nodes, movement diagnostics must still read the unit's live `unit:GetPlotId()` as the origin. Using `pathInfo.plots[1]` in that case can silently replace the true start plot with the destination plot and break embark-tech failure diagnosis for coastal water targets.
  - Runtime dumps confirm `GetMoveToPathEx(...)` exposes only the keys vanilla uses (`plots`, `turns`, `obstacles`, `entrancePortals`, `exitPortals`), so CAI should not promise Civ V-style MP spent / MP remaining unless a future engine hook exposes per-node remaining movement.
  - 2026-05-19 comparison against Civ V Access `CivVAccess_PathDiagnostic.lua` / `CivVAccess_UnitControlMovement.lua`: that mod does not settle for a generic move failure. It re-runs the engine pathfinder with progressively relaxed flags, then names causes such as blocked borders / would declare war, friendly stacking, at-war enemy blocker, no embark tech, no deep-water tech, mountain or natural wonder, no naval connection, cannot attack from land, cannot attack from water, and cannot travel to land.
  - Civ VI does not expose a Civ V-style discriminative path API. In confirmed Lua/UI surfaces we have only the `GetMoveToPathEx(...)` structure, `UnitManager.GetOperationTargets(...)` for implicit ranged attacks, `UnitManager.GetReachableZonesOfControl(...)`, `CombatManager.IsAttackChangeWarState(...)`, plot terrain/water queries, visibility checks, and generic `UnitManager.CanStartOperation(...)` booleans.
  - Civ VI's generic `UnitManager.CanStartOperation(unit, operationType, plotOrParams, returnResults)` signature can return `UnitOperationResults.FAILURE_REASONS` for many unit operations when `returnResults=true`, and vanilla `UnitPanel.lua` appends those localized strings for disabled actions. However, direct probing showed that per-destination `MOVE_TO` preview does not populate useful `FAILURE_REASONS`, `ACTION_NAME`, or `ADDITIONAL_DESCRIPTION` data through the tested `CanStartOperation(...)` call shapes, so CAI should not rely on that path for movement diagnostics.
  - CAI adds movement hints from other confirmed vanilla systems: visible ZOC entry is detected by intersecting `pathInfo.plots` with `UnitManager.GetReachableZonesOfControl(unit, true)`, and war-start warning follows `CombatManager.IsAttackChangeWarState(unit:GetComponentID(), x, y)`.
  - Normal movement previews should not speak generic embark/disembark requirements at all. Access or tech requirements belong only to the failure diagnostic path, for example `Requires: <tech> technology` on an invalid target.
  - Delayed combat speech should be driven directly by hostile destination state plus arrival turn, not by a route-text fallback. If the destination will trigger combat after movement, CAI should say only `Encounters combat this turn` or `Encounters combat in n turns`; do not fall back to `Enemy at destination` for delayed hostile contact.
  - Current practical parity judgement versus Civ V:
    - can match directly now: blocked visible unit, impassable terrain / mountain, land-vs-water attack incompatibility, sea unit cannot travel to land, ZOC entry, war-start warning, embark/disembark along a valid route, fog vs unexplored, swap, queued path, arrival turn, and combat-at-end preview suppression
    - can now approximate in CAI from start/target plot state: blocked foreign territory, unit-specific embark tech (`TECH_SAILING` for builders, `TECH_CELESTIAL_NAVIGATION` for traders, `TECH_SHIPBUILDING` for other land units), and `TECH_CARTOGRAPHY`-gated ocean travel when the destination plot itself is ocean once embark is already unlocked
    - confirmed gameplay data: `Technologies.xml` uses `EmbarkUnitType="UNIT_BUILDER"` on `TECH_SAILING`, `EmbarkUnitType="UNIT_TRADER"` on `TECH_CELESTIAL_NAVIGATION`, `EmbarkAll="true"` on `TECH_SHIPBUILDING`, and `CARTOGRAPHY_GRANT_OCEAN_NAVIGATION` on `TECH_CARTOGRAPHY`
    - cannot currently match from confirmed Civ VI Lua alone: Civ V-style closest-reachable direction beyond adjacent plots, natural-wonder-specific blocker naming, and naval no-water-connection diagnosis
  - `BuildMovementResultSpeech(unit, targetX, targetY, turnsToArrival)` formats post-move result text for later event handlers. It compares the unit's live position to the original target; on arrival it uses `unit:GetMovementMovesRemaining()` as Civ VI's display movement value, so no Civ V-style `MOVE_DENOMINATOR` conversion is needed. If the unit stopped short, caller-supplied `turnsToArrival` controls whether CAI says `Stopped short, n turns till arrival` or bare `Stopped short`.
  - `EventSubs_CAI.lua` owns orphan event subscriptions that do not naturally belong to a screen override. It currently listens to `Events.UnitMoveComplete(playerID, unitID, x, y)` for the local player only, finds the unit, checks `UnitManager.GetQueuedDestination(unit)`, re-runs `UnitManager.GetMoveToPathEx(unit, queuedPlotId)` when a queued destination remains, and passes the final turn entry to `BuildMovementResultSpeech(...)` before speaking the result.
  - `UnitWaypoints_CAI.lua` is a WorldInput-owned singleton service for the currently selected unit's queued-path cache. It is included from `WorldInput_CAI.lua`, not from `PlotToolTip_CAI.lua`, because the authoritative lifecycle events (`Events.UnitSelectionChanged` and `Events.UnitMoveComplete`) already belong to world input and the world scanner also lives in that same context.
  - The service caches exactly one full queued path at a time, for the currently selected unit only. Each cached entry stores a `PlotId` plus `IsWaypoint` boolean. Waypoints are end-of-turn stop plots on that queued path, derived by walking `GetMoveToPathEx(unit, queuedDestination).turns` and marking `plots[i - 1]` when `turns[i]` increases. The unit's current plot is never marked as a waypoint, so an already-exhausted unit does not speak `Next waypoint: Here`.
  - `UnitWaypoints_CAI.lua` exposes read-only queries through `ExposedMembers.CAIInfo`:
    - `GetQueuedPath()` -> copied `{ PlotId, IsWaypoint }[]` cache for the selected unit's queued path
    - `GetQueuedPathArrivalTurn()` -> cached final `pathInfo.turns[#turns]`
    - `GetUnitWaypoints()` -> copied `plotId[]` filtered from cached queued-path entries where `IsWaypoint == true`
    - `GetNextUnitWaypoint()` -> first cached waypoint plot id, or nil when no end-of-turn stop remains before the queued destination
    - `IsQueuedPathPlot(plotId)` -> true when that plot appears anywhere on the cached queued path
    - `IsWaypointPlot(plotId)` -> true when that plot is marked as an end-of-turn waypoint on the cached queued path
  - `UnitWaypoints_CAI.lua` clears and repopulates the cache on `Events.UnitSelectionChanged` when a local unit becomes selected, refreshes it on `Events.UnitMoveComplete` only for the currently selected unit, and every public getter/query self-clears when the currently selected unit no longer has a queued destination.
  - `UnitPanel_CAI.lua` uses `GetNextUnitWaypoint()` plus `CAIHexCoordUtils.directionString(unitX, unitY, waypointX, waypointY)` to speak `Next waypoint: ...` from the unit's location. Summary speech inserts it immediately after activity.
  - `UnitPanel_CAI.lua` queued-path reads no longer recalculate from the pathfinder. They rebuild explicit queued-path speech from cached queued-path entries plus live visibility, using `GetQueuedPath()`, `GetQueuedPathArrivalTurn()`, and `CAIHexCoordUtils.stepListFromPath(...)`.
  - `PlotToolTip_CAI.lua` consumes `IsWaypointPlot(plotId)` through a `waypoint` plot-info helper and can announce `Waypoint` for matching plots.
  - `WorldScannerCategory_waypoints.lua` now represents the selected unit's cached queued path as a dynamic `Queued path` scanner category with `Full path` and `Waypoints` subcategories. Scanner item labels are built from `RequestPlotInfo(..., { "waypoint", "plotName", "feature", "cityName", "districtTitle", "cityDistrictTitle" }, plotId)` so the category reuses normal plot naming instead of custom label logic.
  - `GetActiveInterfacePlotInfo(plot)` dispatches by `UI.GetInterfaceMode()` through `InterfaceInfoHelpers[...]`.
  - `SpeakActiveInterfacePlotInfo(plot)` is the one-shot speech wrapper for the Space-bound `InterfaceInfo` action. Helpers remain plain functions and return either a string, a list of strings, nil, or `false` when explicit speech was handled by side effect.
  - Current supported preview modes include `MOVE_TO`, `DISTRICT_PLACEMENT`, `BUILDING_PLACEMENT`, `RANGE_ATTACK`, `CITY_RANGE_ATTACK`, `DISTRICT_RANGE_ATTACK`, `AIR_ATTACK`, `DEPLOY`, `REBASE`, `TELEPORT_TO_CITY`, `FORM_CORPS`, `FORM_ARMY`, `AIRLIFT`, `SACRIFICE_SELECTION`, `KILL_WEAKER_UNIT`, `TRANSFORM_UNIT`, `RESTORE_UNIT_MOVES`, and `NAVAL_GOLD_RAID`.
  - Ranged, city ranged, district ranged, and air attack helpers call `LuaEvents.CAISpeakCombatPreview()` and return `false`; combat preview speech remains owned by `UnitPanel_CAI.lua`.
  - District placement preview reuses vanilla `AdjacencyBonusSupport.GetAdjacentYieldBonusString(...)` for the short bonus summary, detailed tooltip text, and requirement/warning text, while CAI computes owned-valid versus purchasable-valid state locally from `CityManager.GetOperationTargets(...)` and `CityManager.GetCommandTargets(...)`.
  - Wonder placement uses valid owned plots from `CityManager.GetOperationTargets(...)` and valid purchasable plots from `CityManager.GetCommandTargets(...)` filtered through `plot:CanHaveWonder(...)`.
  - Non-attack targeting/destination helpers use shared `CAIInterfaceTargets` target resolution. Space says `Valid` plus the plot target label, `Invalid target` when the CAI cursor is not on an eligible plot, and for `FORM_CORPS` / `FORM_ARMY` appends `formation target` after the target unit name.
  - `PlotToolTip_CAI.lua` now treats `PlotInfo5` as a general interface preview slot rather than a movement-only slot, and automatic cursor speech includes the same interface preview lines when the active mode supplies them.
  - CAI cursor-move plot speech now distinguishes revealed fog from both live-visible plots and unexplored plots. Use `PlayersVisibility[observer]:IsRevealed(plot)` together with `:IsVisible(plot:GetIndex())`: revealed plus not visible should speak the CAI-owned `Fog` helper, while unrevealed plots still fall back to the terrain-name helper's fog-of-war behavior.
  - `PlotToolTip_CAI.lua` now selects its vanilla include by active rules content: base `PlotToolTip`, `PlotTooltip_Expansion2` when `IsExpansion2Active()` is true, `PlotToolTip_BarbarianClansMode` when `GameConfiguration.GetValue("GAMEMODE_BARBARIAN_CLANS") == 1`, and `PlotTooltip_Expansion2_BarbarianClansMode` when both are active.
  - `ExposedMembers.CAIInfo:RequestPlotInfo(plot, requestedKeys, optionalPlotId)` returns a flat `string[]`. Existing callers can keep passing the explicit `plot` object. Callers that need info for a specific target plot without depending on the current cursor plot can pass `nil` for `plot` and the target plot id as `optionalPlotId`. Individual plot info helpers may return either one string or a list of strings; the request path must flatten helper tables before concatenating speech. This matters for `interfaceInfoHelpers_CAI.lua`, whose movement and placement previews are multi-line.
  - `PlotToolTip_CAI.lua` also owns one-shot plot read actions through `Events.InputActionTriggered`. The current action ids are `PlotReadUnits`, `PlotReadYieldRiverOwner`, `PlotReadStats`, `PlotReadRelativeCoords`, and `PlotReadDistrictBuildings`; each action builds a requested-key list and then routes through the same `RequestPlotInfo(...)` / helper pipeline used by cursor speech.
  - `PlotReadStats` intentionally uses separate `movement`, `defense`, and `appeal` helpers instead of a bundled physical-info bucket. `relativeCoords` is the one helper allowed to speak when plot visibility gates would otherwise suppress normal tooltip data.
  - Current default bindings in `src/data/hotkey_config.xml`: `S` / `NP_5` -> `PlotReadUnits`, `W` / `NP_8` -> `PlotReadYieldRiverOwner`, `X` / `NP_2` -> `PlotReadStats`, `Shift+S` / `Shift+NP_5` -> `PlotReadRelativeCoords`, `B` -> `PlotReadDistrictBuildings`. `WorldTrackerReadSummary` moved to `Shift+W` to free `W` for plot reads.
  - `WorldInput_CAI.lua` exposes both move mode and district placement mode through CAI `InterfaceMode` widgets; district placement uses the same Escape / primary-action widget pattern as move mode, but routed to `OnMouseDistrictPlacementCancel()` and `OnMouseDistrictPlacementEnd()`.
  - `WorldInput_CAI.lua` also exposes targeting widgets for `RANGE_ATTACK`, `CITY_RANGE_ATTACK`, `DISTRICT_RANGE_ATTACK`, `AIR_ATTACK`, `WMD_STRIKE`, `ICBM_STRIKE`, `COASTAL_RAID`, `DEPLOY`, `REBASE`, `TELEPORT_TO_CITY`, `FORM_CORPS`, `FORM_ARMY`, `AIRLIFT`, `SACRIFICE_SELECTION`, `KILL_WEAKER_UNIT`, `TRANSFORM_UNIT`, `RESTORE_UNIT_MOVES`, and `NAVAL_GOLD_RAID`. Return delegates to the matching vanilla execution function, and Escape delegates through vanilla `OnPlacementKeyUp(...)`.
- CAI widgets require an id at construction: `mgr:CreateUIWidget(id, type, props)`.
  - Use stable semantic ids for widgets that need direct lookup, for example `CAITopPanelYieldInfoTree`.
  - Use `mgr:GenerateWidgetId("CAIScreenWidgetType")` for repeated rows/items that must be unique but do not need stable lookup.
  - Widget ids are expected to be globally unique among live widgets.
  - `widget:GetId()` returns the widget id assigned at construction.
  - `widget:GetChildById(id, recurse)` returns a direct child by id, or recursively searches descendants when `recurse` is true.
  - `mgr:GetWidgetById(id, recurse)` returns the live widget or nil, searching from the active stack root backward.
  - `mgr:RemoveFromStack(id)` closes and destroys a pushed stack-root widget by id.
  - `mgr.CAISettings.ValidateWidgetIds = true` enables attachment-time duplicate-id warnings for debugging without adding normal runtime lookup-table state.
- `CivilopediaScreen.lua` / `CivilopediaSupport.lua` (decompiled/Assets/UI/Civilopedia/):
  - Data model: `_Sections`, `_PagesBySection[sid]`, `_PageGroupsBySection[sid]`. Public accessors `GetSections()`, `GetPages(sid)`, `GetPageGroup(sid, gid)`, `GetPage(sid, pid)`, `GetCurrentPage()` (returns `sid, pid`). `_CurrentSectionId` / `_CurrentPageId` are file-locals; always go through `GetCurrentPage()`.
  - Entry points: `OnOpenCivilopedia(sectionId_or_search, pageId)` opens or searches and ends with `UIManager:QueuePopup(ContextPtr, PopupPriority.Civilopedia)`; `OnClose()` calls `UIManager:DequeuePopup(ContextPtr)`. `LuaEvents.OpenCivilopedia` and `LuaEvents.ToggleCivilopedia` register the original open functions in `Initialize()`, and `Controls.WindowCloseButton:RegisterCallback(Mouse.eLClick, OnClose)` captures the original close function there too. If CAI wraps `OnOpenCivilopedia` / `OnClose` after `include("CivilopediaScreen")`, remove and re-add the `LuaEvents.OpenCivilopedia` listener and re-register the close button callback so the wrapped functions become the live open/close path.
  - Navigation: `NavigateTo(SectionId, PageId)` is the single re-render point for both the chapter stacks and the right-column quotes/icon lists. Wrap it to refresh CAI state on every page change; the same wrap fires whether the user clicked vanilla tabs or activated a CAI tree node.
  - History: vanilla breadcrumb state lives in file-local `m_kPageTrail`, so CAI cannot read the trail table directly from a wrapper file. Mirror the trail in CAI by wrapping `NavigateTo(...)` for append/truncate behavior and `NavigateToPageTrailIndex(index, bUpdateScroll)` for current-index changes, then call the vanilla `NavigateToPageTrailIndex(...)` from accessible history buttons so activation still uses the native path.
  - Readable text: text reaches the article through `SetPageHeader`, `SetPageSubHeader`, `AddFullWidthChapter` / `AddFullWidthHeader` / `AddFullWidthParagraph` / `AddFullWidthParagraphs`, `AddLeftColumnChapter` / `AddLeftColumnHeader` / `AddLeftColumnParagraph` / `AddLeftColumnParagraphs`, `AddLeftColumnHeaderBody`, and `AddLeftColumnIconHeaderBody`. Each takes a localized text key (often a `LOC_…`). Wrapping these and capturing `Locale.Lookup` of each argument is more reliable than walking `Controls.PageChaptersStack` / `LeftColumnStack` instance children.
  - Quotes: `AddQuote(quote, audio)` renders into `_RightColumnQuoteManager`. When `audio` is a non-empty string the instance's `PlayQuote` button is shown and registered to call `UI.PlaySound(audio)`. CAI captures both in the `AddQuote` wrap and exposes activation through a Button widget whose `OnClick` plays the audio.
  - Related links: `HookupIcon(icon_data, icon_control, button_control)` is the single point that wires every clickable related-concept icon (used by stat boxes' `AddIconLabel` / `AddIconList` and by `Do_AddIconHeaderBody`). When `icon_data` is a table with a non-nil `search_term` at index 3 the button's `eLClick` runs `CivilopediaSearch(search_term, 1)` then `NavigateTo(result.SectionId, result.PageId)`. CAI captures `{tooltip = icon_data[2], search_term = icon_data[3]}` and reproduces the click behavior on a Button widget in the article list.
  - Capture-buffer reset: clear text/quote/link buffers at the top of the `NavigateTo` wrap (before `orig`), because vanilla calls the text-add and `HookupIcon`/`AddQuote` functions during `RefreshPageContent` inside `orig`.
  - Section / page label fields: `section.TabName` (label, tooltip), `group.TabName`, `page.Title` (full title used for crumbs), `page.TabName` (short tab text), `page.PageGroupId` (may be nil for top-level pages). Not every page belongs to a group.
  - Stat boxes: `AddRightColumnStatBox(title, populate_method)` (line 1641) builds a stat box and calls `populate_method(stat_box)` once. `stat_box` is a local table built fresh per call, with methods `AddSeparator`, `AddHeader(caption)`, `AddLabel(caption)`, `AddSmallLabel(caption)`, `AddIconLabel(icon, caption)`, `AddIconNumberLabel(icon, value, caption)`, `AddIconList(icon1..icon4)`. These methods cannot be wrapped globally — wrap `AddRightColumnStatBox` itself and replace `stat_box[name]` with a shim that records and delegates before invoking the user populate. The user populate must still run; do not run it twice.
  - `AddIconLabel` / `AddIconList` internally call `HookupIcon`, so a global `HookupIcon` wrap will see every stat-box icon. If you also capture related links through `HookupIcon`, suppress that capture (via a state flag) for the duration of the wrapped stat-box populate so icons inside stat boxes don't duplicate into a global Related list.
  - Focus seeding on a deep `TreeviewItem` requires expanding its ancestor tree items first: `TreeviewItem.GetDefaultChild` returns nil when `IsExpanded` is false (`src/UI/uiManager/widgetTemplates.lua:878-883`), so `mgr:SetFocus(leaf)` will not land on a leaf inside collapsed ancestors. Walk `node.Parent` up to the Treeview root and call `:Expand()` on each ancestor `TreeviewItem` before `SetFocus`.

## Interface Modes

- `InterfaceModeTypes.MOVE_TO` — unit movement mode
- `UI.GetInterfaceMode()` — returns current interface mode
- `UI.SetInterfaceMode(mode)` — changes interface mode

## Sound

- `UI.PlaySound(soundKey)` — plays a UI sound effect
  - `"Main_Menu_Mouse_Over"` — standard hover sound

## Modding

- `Modding.IsModInstalled(modGuid)` — checks if a mod is active
- `Modding.CheckRequirements(mods, saveType)` — validates mod compatibility

## Game State

- `GameConfiguration.GetGameState()` — returns current state
- `GameStateTypes.GAMESTATE_PREGAME` — pre-game state constant

## Network

- `Network.LeaveGame()` — leaves current network session
- `Network.LoadGame(saveData, serverType)` — loads a save file
- `Network.GetFriends()` — returns friends API object

## City Banner XP1 / XP2

- `Civ6Common.lua` exposes `IsExpansion1Active()` and `IsExpansion2Active()`, and CAI can include it directly in in-game UI helpers when behavior needs to branch on Rise and Fall / Gathering Storm.
- `CityBannerManager` expansion loyalty data can be rebuilt from live `city:GetCulturalIdentity()` calls without the loyalty lens. Useful methods are `GetLoyalty()`, `GetMaxLoyalty()`, `GetLoyaltyPerTurn()`, `GetPotentialTransferPlayer()`, `GetPlayerIdentitiesInCity()`, and `GetIdentitySourcesBreakdown()`.
- Expansion loyalty mini-panel control names are stable enough for CAI tree labels/tooltips: `LoyaltyInfo.LoyaltyPercentageLabel`, `PopulationTop`, `GovernorTop`, `Happiness`, `OtherTop`, `CityStateTop`, `FreeCityTop`, and `IdentityBreakdownStack`.
- GS power banner text can be mirrored from `city:GetPower()` with vanilla loc keys. Firaxis uses `GetFreePower()`, `GetTemporaryPower()`, `GetRequiredPower()`, `IsFullyPowered()`, and `IsFullyPoweredByActiveProject()` together with `LOC_CITY_BANNER_POWERED_CITY`, `LOC_CITY_BANNER_POWERED_CITY_FROM_ACTIVE_PROJECT`, and `LOC_CITY_BANNER_UNPOWERED_CITY`.
