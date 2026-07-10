# Civ VI Game API Reference (CAI Mod)

Documented APIs used by the CAI accessibility mod. Updated as new patterns are discovered.

## Safe Mod Keys

Keys confirmed safe to bind in mods without conflicting with game defaults:

- `Keys.VK_TAB` — not bound by default in game
- `Keys.VK_HOME`, `Keys.VK_END` — not bound by default
- `Keys.VK_PRIOR` (Page Up), `Keys.VK_NEXT` (Page Down) — not bound by default
- `Keys.VK_NUMPAD1` through `Keys.VK_NUMPAD9` — hex grid navigation
- `Keys.VK_OEM_2` / `/` — CAI global cursor-to-selection action
- `Keys.VK_SPACE` — safe for checkbox toggle (game uses for other contexts)
- `Keys.VK_RETURN` — safe for button activation
- `Keys.VK_ESCAPE` — standard cancel/close
- `Keys.A` through `Keys.Z` — letter keys (use with IsControl for shortcuts like Ctrl+A)

## Input System

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
- CAI hotkey categories in `src/data/hotkey_config_CAI.xml` are intentionally split by task instead of one broad CAI bucket. Current narrow buckets are `CAI_MESSAGE_BUFFER`, `CAI_NAVIGATION_CURSOR`, `CAI_WORLD_SCANNER`, `CAI_SURVEYOR`, and `CAI_INFORMATION`; the existing `CAI_UNIT`, `CAI_GLOBAL`, `CAI_UI`, `CITY`, `CAI_ONLINE`, and `CAI_LENSES` categories remain separate.
- For CAI unit hotkeys, keep the hotkey surface aligned with vanilla `VisibleInUI`. If a `UnitOperations.xml` or `UnitCommands.xml` row is hidden there, do not register a CAI `InputActions` row for it and do not assign a `HotkeyId`, or it will appear in the keybinding UI even though vanilla intentionally hides it.
- Avoid exposing duplicate keybinding entries for the same user action. In particular, `UNITOPERATION_UPGRADE` already covers unit upgrading in the keybinding UI, so CAI should not also expose a separate `UNITCOMMAND_UPGRADE` binding row.
- Also avoid exposing unit actions whose vanilla UI expands one action id into multiple concrete choices or collapses several DB rows into one chooser. Confirmed examples are `UNITOPERATION_BUILD_IMPROVEMENT`, `UNITCOMMAND_ENTER_FORMATION`, `UNITOPERATION_WMD_STRIKE`, and the offensive-spy mission operations.

### ContextPtr

- To receive input in a LUA context, set a function to be a callback handler.
The handler function should return true if the input was handled.
The handler function should return false if the input was not handled or it was handled but should be considered by other inputs.
Once input is marked as handled (true), no other controls (or contexts) within that root context will receive input. But other controls/contexts within other root contexts will receive a chance to handle the input, despite if it was marked has handled (true) in a different root context.
(NOTE: Root contexts are set via C++, chances are you are working within a single root context.)
Only one input handler callback can be set per context.
There are two types of handlers that can receive input.
Simple Handler
The simple handler will callback when input occurs passing in 3 parameters:
function InputHandler( uiMsg, wParam, lParam )
The uiMsg will be the type of input (keyboard, mouse, pointer, etc…), wParam and lParam will be values that have meaning, based on the type of input that comes in.
To set the handler call SetInputHandler() on the context, passing in the name of function to receive input.
ContextPtr:SetInputHandler( InputHandler );
Example
function InputHandler( uiMsg, wParam, lParam )
if (uiMsg==KeyEvents.KeyDown) then
if (wParam==Keys.VK_ESCAPE) then
OnBack();
return true;
end
end
if (uiMsg==MouseEvents.MouseMove) then        
InspectWhatsBelowTheCursor();
return true;
end
return false;
end
ContextPtr:SetInputHandler( InputHandler );
Extended Handler
The extended handler works almost the same as the simple handler except that it receives a single parameter which is a table of input information:
function InputHandler( inputStruct )
The inputStruct is the same one as "InputStruct" defined in ForgeUI. It allows for detailed querying of the input through various functions.
To set the input handler:
ContextPtr:SetInputHandler(
InputHandler, true );
InputStruct functions include:
Function
Returns
Description
GetFlags
number
Return the low level bit-flags the input system is using.
GetKey
number
Obtain the AppHost key code.
GetMessageType
number
The type of input message contained in this instance of the structure.
Values include:
KeyEvents.KeyDown
KeyEvents.KeyUp
MouseEvents.LButtonDown
MouseEvents.LButtonDoubleClick
MouseEvents.LButtonUp
MouseEvents.MButtonDown
MouseEvents.MButtonDoubleClick
MouseEvents.MButtonUp
MouseEvents.PointerDown
MouseEvents.PointerUp
MouseEvents.RButtonDown
MouseEvents.RButtonDoubleClick
MouseEvents.RButtonUp
GetMouseDX
number
Obtain the horizontal delta for the mouse since the last frame of input.
GetMouseDY
number
Obtain the vertical delta for the mouse since the last frame of input.
GetTouchID
number
The unique ID associate with this touch generating an event.
GetWheel
number
Get mouse wheel value
GetX
number
Horizontal coordinate for this mouse or touch event.
GetY
number
Vertical coordinate for this mouse or touch event.
IsShiftDown
bool
Is the shift key held down?
IsControlDown
bool
Is the control key held down?
IsLButtonDown
bool
Is the left mouse button (or touch equivalent) down?
IsRButtonDown
bool
Is the right mouse button down?
IsMButtonDown
bool
Is the middle mouse button (commonly the mouse wheel) down?
IsAnyButtonDown
bool
Is the left, right, or middle mouse button down?

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
- `ctrl:DoLeftClick()` — available from the base control class for XML-backed controls; use it directly to preserve vanilla click callbacks when mirroring activation.
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
- `UIManager:GetFilePath(fileName)` — resolves a VFS-loaded Lua file name to its absolute filesystem path. CAI can use this to derive the current mod root by asking for a CAI-owned Lua file and walking up from `.../UI/...`.

## InstanceManager

Used to create dynamic UI instances from XML templates:

- `InstanceManager:new(instanceName, topControlName, parentControl)` — creates a manager
- `im:GetInstance()` — allocates a new instance, returns control table
- `im:ResetInstances()` — returns all instances to pool
- `im.m_AllocatedInstances` — array of currently allocated instances

## Map & Plot

- `Map.GetPlotByIndex(plotId)` — returns a Plot object
- `plot:GetX()`, `plot:GetY()` — plot coordinates
- `plot:GetContinentType()` returns the numeric `GameInfo.Continents.Index` for the plot, so CAI can read the localized continent name directly from `GameInfo.Continents[index].Description` without the older extra type-map hop.
- `plot:GetOwner()` returns `-1` / no owner for unclaimed plots. For NavCursor-style territory change speech, use vanilla `LOC_MINIMAP_UNCLAIMED_TOOLTIP` for that case instead of a CAI-owned placeholder string.
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
- Rise and Fall / Gathering Storm do add extra settlement information, but not by changing the four water-availability color buckets:
  - `DLC/Expansion2/UI/Additions/SettlerInfluenceIconManager.lua` listens for `Hex_Coloring_Water_Availablity`, calls `Map.GetContinentPlotsLoyalty()`, and draws numeric loyalty-pressure icons on top of the active settler lens. Tooltip loc key: `LOC_SETTLER_LOYALTY_WARNING_TOOLTIP`.
    - The settler-lens loyalty overlay is not a named category set like fresh/coastal/no-water/blocked. Firaxis displays the exact `loyaltyVal` returned by `Map.GetContinentPlotsLoyalty()` on each plot, and the tooltip says that nearby cities would apply that many loyalty-per-turn to a new city settled there.
  - `DLC/Expansion2/UI/Additions/SettlerWarningIconManager.lua` also listens for `Hex_Coloring_Water_Availablity` and overlays hazard icons for floodplains, volcano risk, and XP2 coastal lowlands. The coastal warning comes from `TerrainManager.GetCoastalLowlandType(plot)` plus `GameInfo.CoastalLowlands()[...]`, not from the water-availability array.
  - Those overlays are independent of the separate XP1 loyalty lens in `MinimapPanel_Expansion1.lua`, which uses `UILens.SetActive("Loyalty")` and `pCity:GetCulturalIdentity()` pressure waves / flag markers for existing cities.
- CAI now exposes the current supported modal lens through a single dynamic scanner category in `src/UI/InGame/WorldScanner/WorldScannerCategory_activeLens.lua`:
  - active-lens detection is registry-driven through the actual minimap layer state (`UILens.IsLayerOn(...)` for hashes such as `Hex_Coloring_Water_Availablity`, `Hex_Coloring_Appeal_Level`, `Hex_Coloring_Continent`, `Hex_Coloring_Owning_Civ`, `Hex_Coloring_Government`, and XP2 `Power_Lens`), rather than hard-wiring scanner rebuild logic to the settler water layer
  - currently supported scanner-backed lenses are `WaterAvailability`, `Appeal`, `Continent`, `OwningCiv`, `Government`, `Tourism`, and XP2 `Power`
  - the settler implementation remains the richest one so far: subcategories are `Water availability`, `Loyalty`, and `Disasters`
  - appeal uses a single subcategory grouped into breathtaking, charming, average, uninviting, and disgusting
  - continent uses a single subcategory grouped by continent name
  - owning-civ uses stance subcategories `My`, `Neutral`, and `Enemy`, then groups within those by owner
  - government also uses stance subcategories `My`, `Neutral`, and `Enemy`, but groups by government + owning civ + owning city. The reliable city lookup for arbitrary owned plots is `Cities.GetPlotPurchaseCity(plot)` with `Cities.GetCityInPlot(x, y)` as a city-center fallback
  - tourism follows `TourismBannerManager.lua`: it scans only the local player's purchased city plots, keeps only plots where `player:GetCulture():GetTourismAt(plotID) > 0`, and exposes two subcategories: `By city` and `By strength`
  - tourism strength grouping mirrors Firaxis' visual thresholds from `TourismBannerManager.lua`: `High` at `>= 16`, `Medium` at `>= 8`, and `Low` otherwise. Item labels use tourism value plus tourist count from `GetTourismAt(plotID)` and `GetTouristsAt(plotID)`
  - XP2 power uses four simple subcategories derived from `PowerLensManager.lua`: `Power sources`, `Power range`, `Powered city plots`, and `Unpowered city plots`. It rebuilds from local-player cities only, matching the vanilla power lens
  - loyalty groups are keyed by exact loyalty-per-turn value and sorted highest to lowest through a scanner-core subcategory comparator hook
  - disaster groups currently mirror the visual overlay types: flood risk, volcano risk, and coastal lowland 1 / 2 / 3
- Gathering Storm coastal-lowland state is exposed separately through `TerrainManager.GetCoastalLowlandType(plotIndex)` and `GameInfo.CoastalLowlands()`. That is a distinct API path from the settler water-availability lens.
- Minimap modal-lens ownership is split across files:
  - base `Assets/UI/MinimapPanel.lua` toggles `Religion`, `Continent`, `Appeal`, `WaterAvailability`, `Government`, `OwningCiv`, `Tourism`, and `EmpireDetails`
  - XP1 `DLC/Expansion1/UI/Replacements/MinimapPanel_Expansion1.lua` adds `Loyalty`
  - XP2 `DLC/Expansion2/UI/Replacements/MinimapPanel_Expansion2.lua` adds `Power`
- Scanner-friendly lens data paths confirmed during minimap investigation:
  - `Appeal` uses `Map.GetContinentPlotsAppeal()` for five explicit plot buckets: breathtaking, charming, average, uninviting, disgusting
  - `Continent` uses `Map.GetVisibleContinentPlots(continentID)` and `GameInfo.Continents[...].Description`
  - `Government` colors each city's purchased plots via `Map.GetCityPlots():GetPurchasedPlots(city)` and the owner's `player:GetCulture():GetCurrentGovernment()`
  - `OwningCiv` / political colors each city's purchased plots via `Map.GetCityPlots():GetPurchasedPlots(city)` and the owner's player color; XP1 modal-lens key adds a distinct free-city entry
  - `Loyalty` is expansion-only and city-based: `MinimapPanel_Expansion1.lua` uses `city:GetCulturalIdentity():GetConversionOutcome()` plus `GetCityIdentityPressures()` for rising / falling city markers and pressure waves, while settler-lens loyalty uses the separate plot API `Map.GetContinentPlotsLoyalty()`
  - `Power` is XP2-only and lives in `DLC/Expansion2/UI/Additions/PowerLensManager.lua`; it rebuilds from `city:GetPower()` using `GetPlotsCoveredByRegionalPower()`, `GetPlotsProvidingPower()`, `IsFullyPowered()`, and `Map.GetCityPlots():GetPurchasedPlots(city)`
  - `Tourism` uses `Assets/UI/WorldView/TourismBannerManager.lua`; per plot it reads `player:GetCulture():GetTourismAt(plotID)`, `GetTouristsAt(plotID)`, and `GetTourismTooltipAt(plotID)` and creates banners only for owned plots with tourism > 0. Current CAI scanner support mirrors that with local-player-only plot scanning, plus `By city` and `By strength` groupings
  - `EmpireDetails` does not expose a unique plot-bucket API in `MinimapPanel`; the visible effect is largely city / district banner detail and district-banner reveal, so it is a weaker scanner target than the other modal lenses

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
- `LuaEvents.CAICursorMoveTo(plotId, reason)` — CAI custom: unified cursor move request. Reason is `"step"`, `"jump"`, `"select"`, or `"snap"`. Speaks direction when distance > 1. Always fires `CAICursorMoved`.
- `LuaEvents.CAICursorMoveDirection(direction)` — CAI custom: directional cursor step; resolves the adjacent plot and calls `MoveTo` with reason `"step"`.
- `LuaEvents.CAICursorMoved(state)` — CAI custom: emitted after every cursor move. `state` is a table with `fromPlotId`, `toPlotId`, `distance`, `fromX`, `fromY`, `toX`, `toY`, `reason`. Listeners use `state.reason` to decide behavior (e.g. PlotToolTip speaks on `"step"`/`"jump"`, silent on `"select"`/`"snap"`).
- `LuaEvents.CAIWorldTrackerShowChat()` — CAI custom: asks `WorldTracker_CAI.lua` to force the vanilla in-game chat panel visible and re-realized before CAI pushes its own accessibility panel.
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

## Chat panel findings

- `Assets/UI/Popups/ChatPanel.lua` owns four main behaviors: send/edit target handling, incoming chat history, clickable map-pin chat entries, and the player-action / kick-vote area.
- The in-game chat parser path matches staging-room behavior through shared helpers: `ParseInputChatString(...)` handles `/g`, `/t`, `/w`, and `/help`, and `PlayerTargetToChatTarget(...)` converts the player-target model into the `Network.SendChat(...)` tuple.
- `/help` uses two different vanilla outputs:
  - `ChatPrintHelpHint(...)` seeds the one-line hint near the input.
  - `ChatPrintHelp(...)` prints the full help text into chat history.
- Clickable map pins are transmitted as `[pin:<playerID>,<pinID>]`. `OnChat(...)` special-cases that token and resolves the live pin through `GetMapPinConfig(...)`.
- `BuildPlayerList()` is the durable rebuild choke point for the player-actions area. Vanilla chat already calls it for kick-vote changes, player connect/disconnect, host migration, player-info changes, and game-config changes.
- `OnMapPinPopup_RequestChatPlayerTarget()` only needs the current target state; the base screen answers by calling `PlayerTargetChanged(m_playerTarget)`.
- A `ChatPanel` include-after wrapper cannot directly reuse base locals like `m_playerTarget`, so `ChatPanel_CAI.lua` needs its own mirrored target/history state and should reuse the global helper functions instead of trying to mutate the base locals.

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
- Current implementation is a singleton, not a per-player store: `m_firstRevealPlots`, `m_nowVisiblePlots`, `m_knownRevealedPlots`, `m_previousVisibleUnits`, `m_specialImprovementKinds`, and the debounce timer are all shared globals. For hotseat, those buffers must be keyed by the active local player and flush only the active player's queue; otherwise one human can inherit another human's pending reveal speech or visibility snapshot.
- Reveal announcements now mirror the older Civ V-style split:
  - reveal tracks first-reveal plots separately from revisit-visible plots
  - first reveal is detected from a Lua-side `PlayerVisibility:IsRevealed(plot)` snapshot rather than a custom C++ hook
  - the reveal line speaks `<N> tiles revealed` when unexplored plots were involved, otherwise `Revealed`

## Screen Investigation Notes

### Great People Popup

- Base popup files are `decompiled/Assets/UI/Popups/GreatPeoplePopup.lua` and `.xml`.
- The popup is opened from the Launch Bar via `LuaEvents.LaunchBar_OpenGreatPeoplePopup`, from the notification center via `LuaEvents.NotificationPanel_OpenGreatPeoplePopup`, and from the `ToggleGreatPeople` input action handled in `LaunchBar.lua`.
- Base game tabs are `Great People` and `Previously Recruited`. The popup uses `CreateTabs(...)`, but its own input handler only consumes `Escape`; all per-item interaction in the Lua file is wired through mouse callbacks (`Mouse.eLClick`) on the tab buttons and row controls.
- When opened from a `CLAIM_GREAT_PERSON` notification, the popup explicitly selects the `Great People` tab.
- The `Great People` tab is a horizontally scrolling strip of one card per currently available Great Person candidate. If any candidate is currently recruitable, the popup auto-scrolls to the first recruitable card on open or refresh.
- Each Great Person card contains:
  - class name, individual name, era, portrait, passive/active effect list
  - a `Biography` button that swaps the card into a biography view populated from Civilopedia history loc keys
  - a `Recruit progress` section with one collapsed local-player row plus expandable rows for all alive major players
  - per-player progress rows formatted as `current points / recruit cost`, with a progress bar and a tooltip containing that player's per-turn rate for the class
  - contextual action buttons: `Recruit`, `Pass`, `Gold patronage`, `Faith patronage`
  - a red `Cannot Recruit` label when `Game.GetGreatPeople():GetEarnConditionsText(...)` returns a restriction string
- Recruit / pass / patronage actions call `UI.RequestPlayerOperation(...)` and immediately close the popup.
- The `Previously Recruited` tab switches to a vertical history table showing earn date, Great Person, claimant civ/leader, and passive/active ability summaries.
- The popup listens for `Events.GreatPeoplePointsChanged` and refreshes live while open, and closes automatically on hotseat turn end.
- Expansion behavior is additive through the wildcard include at the bottom of `GreatPeoplePopup.lua`:
  - `Expansion1` overrides the gold / faith patronage tooltips when the player is not allowed to patronize with that yield (`IsNoPatronageWith(...)`).
  - `Expansion2` overrides `IsReadOnly()` so the popup becomes read-only during an active World Congress session.
  - `Babylon Heroes` adds a third `Heroes` tab instead of replacing the existing tabs. The screen title/tooltip become `Heroes & Great People`, and the extra tab is driven by `GreatPeopleHeroPanel.lua/.xml`.
- The Babylon `Heroes` tab reuses the same horizontal card metaphor but swaps in hero-specific controls:
  - hero portrait, stats, abilities, commands, status
  - `Look At` button for the current hero or origin city
  - `Civilopedia` button
  - `Faith Recall` button when the claimed local hero is dead and recall is allowed
  - hidden speaks as its own `Hidden: ...` line
  - gone speaks as its own `Gone: ...` line

## World Congress popup

- Gathering Storm's World Congress UI is split across three standalone popup contexts under `decompiled/DLC/Expansion2/UI/Additions/`:
  - `WorldCongressIntro.lua/.xml`: a full-screen intro banner with title, two centered body paragraphs, and one `Continue` button. It opens on `Events.WorldCongressStage1/Stage2`, and `Escape`, `Enter`, and the `EndTurn` action all dismiss it into the main congress popup.
  - `WorldCongressPopup.lua/.xml`: the main congress screen. It is a full-screen framed overlay with a fixed left member ribbon (`CongressMembers`), a centered title + Favor total, a large central content frame, bottom navigation buttons, a top launch-bar strip with `World Congress` and `Diplomacy` buttons, and a close button in the top-right corner.
  - `WorldCongressBetweenTurns.lua/.xml`: the between-turns waiting banner shown after the player submits votes in single-player. It shows a vertical list of leader portraits with `Waiting` / `Submitted` status rows and a centered status line until all players finish.
- Main popup stages and phases:
  - stage 1 = regular session voting
  - stage 2 = special session / emergency voting
  - stage 4 = out-of-session review
  - while in session, the popup uses two phases: phase 1 is vote entry, phase 2 is a summary/confirmation screen before submission
- Sighted stage-1 / stage-2 layout:
  - left column: one portrait tile per alive major civ, wrapping vertically, with Favor and sometimes grievance values beneath the portrait
  - main body: a scrollable stack of framed cards
  - bottom buttons: `Prev`, `Next`, `Pass`, `Submit`, or `Return` depending on stage/tab
  - the active screen title also shows the local player's remaining spendable Diplomatic Favor on the right
- Resolution cards (`ResolutionItem`) are visually rich and stateful:
  - title + icon + description
  - two large A/B outcome slots
  - each outcome has a separate up/down vote widget with live vote count and incremental Favor cost
  - a target selector under the chosen outcome, using either a normal pulldown or a player pulldown with civ + leader icons
  - favored/disfavored player badges showing how many leaders prefer each side
  - a `MoreInfo` button whose tooltip summarizes how this same resolution went the previous time it appeared
  - visual selection state is shown by swapping frame textures and line colors once the player has both chosen an outcome and selected a target
- Discussion / emergency proposal cards (`ProposalItem`, `EmergencyProposalItem`) show:
  - title, description, target leader or proposal-type icon
  - a single vote widget for up/down support during an active session
  - expandable emergency details outside a session
  - in the `Available Proposals` review tab, a checkbox-style selector is used instead of live voting so the player chooses which emergency proposals to submit for a future special session
- Review mode (stage 4) has three top tabs:
  - `Last Session Results`: shows passed/failed resolutions and discussions, with expandable per-player vote breakdowns
  - `Active Effects`: shows currently active resolutions and how many turns remain
  - `Available Proposals`: shows emergencies/special-session proposals the player can currently submit
- Input and launch behavior:
  - the HUD congress button (`CongressButton.lua`) either resumes the live congress session or opens the results/review popup when congress is not in session
  - the main popup's `DiploButton` opens diplomacy directly from the congress overlay
  - clicking leader portraits in the left ribbon opens diplomacy for that leader when met
  - `Enter` advances from phase 1 to phase 2, or submits on the confirmation screen; in review mode it activates the visible submit/return path
  - `Escape` closes the popup; the close button mirrors that behavior
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
- Scanner invalidation is category-scoped where possible: `Events.InterfaceModeChanged` and local unit selection changes rebuild only `validTargets`; the dynamic active-lens category now rebuilds on generic lens toggles plus supporting world events such as plot visibility, city visibility, tile ownership, government, diplomacy, local-player change, city occupation, and XP2 `Events.CityPowerChanged`; `Events.LocalPlayerTurnBegin` clears all built category contents.
- Category definitions can expose a cheap `CanScan(context)` predicate to avoid expensive API calls when a category cannot currently exist, such as `validTargets` outside supported interface modes or `waterAvailability` while the water lens is off.
- Cursor movement resorts only the current built category. It does not rebuild or resort every scanner category.
- Scanner distance sorting uses the current CAI cursor plot and `Map.GetPlotDistance(...)`.
- Scanner jump and return use `LuaEvents.CAICursorMoveTo(plotIndex, "jump")`.
- Scanner item focus now has a distinct cursor-follow path from jump: when `ScannerAutoMoveCursor` is enabled, scanner selection moves the CAI cursor with `LuaEvents.CAICursorMoveTo(plotIndex, "snap")` after the item/category announcement, so the spoken direction still reflects the pre-move cursor position while the cursor then follows the selected target for subsequent scans.
- Scanner coordinate speech is setting-driven and mirrors cursor-coordinate behavior: `ScannerCoordinates` uses the same `disabled` / `append` / `prepend` shape, and scanner item announcements build the coordinate text from `CAIHexCoordUtils.coordinateString(x, y)`.
- Full-map scanner categories should iterate plots with `for plotIndex = 0, Map.GetPlotCount() - 1 do` and `Map.GetPlotByIndex(plotIndex)`. Do not use `Map.GetNumPlots()`.
- `WorldScannerCategory_validTargets.lua` appears only in active targeting modes. It gets target items from the neutral `CAIInterfaceTargets` helper in `interfaceTargetHelpers_CAI.lua`, so scanner and Space interface info use the same live target resolution without the scanner depending on `interfaceInfoHelpers_CAI.lua`. It does not attach per-item validation callbacks because the category is rebuilt when target mode or selected unit changes, and re-calling target APIs during scanner core validation is too expensive.
- Auto-focus for dynamic scanner categories is no longer hardwired. `validTargets` and `activeLens` still declare `AutoFocus = true`, but `WorldScanner_CAI.lua` gates that through navigation settings (`ScannerAutoFocusValidTargets`, `ScannerAutoFocusActiveLens`) both when ordering category slots during rebuild and when deciding whether a category-scoped rebuild should steal scanner focus.
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
- To free those Surveyor keys, `WorldTrackerReadSummary` is now `R`, `PlotReadDistrictBuildings` is `Shift+X`, `UnitViewAbilities` is `Alt+/`, and `WorldTrackerOpenCivicsChooser` is `Ctrl+C`.
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
- Map tacs / map pins are read from `PlayerConfigurations[iPlayer]:GetMapPins()` and filtered with `mapPinCfg:IsVisible(localPlayerID)`. Shared label helpers live in `inGameHelpers_CAI.lua`: `BuildMapTacLabel(mapPinCfg)` returns name + icon, `BuildMapTacLabelWithOwner(mapPinCfg, playerID, localPlayerID)` appends the owner name for non-local tacs, `GetVisibleMapTacsAtPlot(plot)` returns visible tacs on a plot, and `GetMapTacIconLabel(iconName)` mirrors `MapTacks.IconOptions(...)` tooltip resolution plus CAI stock-icon localization fallbacks. The world scanner `mapTacs` category builds dynamic subcategories: `My` first, then one subcategory per other visible pin owner. Scanner groups use the item label as their normal group label. `PlotToolTip_CAI.lua` collects visible tack labels into one owner-aware list and speaks it through `LOC_CAI_PLOT_MAP_TACS` as `Map tacks: {list}`.
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
- Vanilla `ProductionPanel.lua` recommendation visuals are generic, not advisor-specific:
  - `pSelectedCity:GetCityAI():GetBuildRecommendations()` is read in `View(...)`, but vanilla stores only `BuildItemHash -> BuildItemScore` in `m_kRecommendedItems`
  - `PopulateGenericItemData(...)` checks whether `m_kRecommendedItems[kItem.Hash]` exists and then only calls `kInstance.RecommendedIcon:SetHide(false)`
  - there is no advisor-type lookup, no advisor-specific icon swap, and no recommendation color branch in the base production panel Lua
  - practical implication: any spoken advisor-type recommendation detail in CAI production would be an enhancement, not parity with a distinct vanilla recommendation color
- ProductionPanel CAI open/tab sync:
  - `LuaEvents.ProductionPanel_ListModeChanged(...)` is still the correct CAI sync point for ordinary vanilla tab changes because vanilla emits it directly from `OnTabChangeProduction`, `OnTabChangePurchase`, `OnTabChangePurchaseFaith`, `OnTabChangeQueue`, and `OnTabChangeManager`.
  - For delayed open, `LuaEvents.ProductionPanel_Open()` should be treated only as an "open pending" signal. Vanilla `Open()` fires it before the caller has necessarily selected the final tab.
  - The practical open handshake is therefore: mark CAI open-pending on `ProductionPanel_Open`, wait for the first real `ProductionPanel_ListModeChanged(...)`, then sync the CAI active tab from `m_CurrentListMode` and push the CAI panel.
  - `CityPanel.lua` treats `Controls.ChangeProductionCheck` as the toggle for the whole production-side panel family, not specifically the production chooser. `OnProductionPanelListModeChanged(...)` sets that check true for both `LISTMODE.PRODUCTION` and `LISTMODE.PROD_QUEUE`.
  - `ProductionPanel.OnCityPanelProductionOpen()` also defaults to the queue tab when `GetQueueSize(m_pCity) > 1` or auto-queue is enabled. Practical implication: a city-panel "change production" activation can land on queue mode first, and if CAI blindly toggles `ChangeProductionCheck` while queue mode already owns that check, the first activation just flips panel state instead of forcing the chooser tab.
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
  - CAI now folds the non-queue manager affordances into `ProductionPanel_CAI.lua` instead of replacing the separate manager screen: the production-panel CAI root has sibling widgets for the existing production `TabControl`, a local-player city `List`, and a `Sort by` dropdown using the same founding/name/population options. Focusing a city row calls `UI.SelectCity(city)` only when it is not already selected, letting vanilla city-selection refresh rebuild the active production page.
  - The production-panel CAI root also owns panel-local `Alt+Left` / `Alt+Right` widget bindings for previous/next city. These step through the same currently sorted city list used by the city `List`, wrap at the ends, and seed the city list's internal remembered focus key through `mgr:PrepareFocus(list, cityFocusKey)` before selecting the city. The next city-list rebuild consumes that pending key instead of restoring a stale captured row, so refresh focus restoration stays aligned with the newly selected city.
  - CAI current-production reads are shared: `GetCurrentProductionItem(city)`, `HasActiveCurrentProduction(city)`, and `ReadCurrentProductionLabel(readTurns, city)` accept an optional city. The selected-city path still reads live vanilla controls for status text, while non-selected city-list rows reuse the same item helper instead of duplicating production-name lookup. Do not use `ipairs(GameInfo.Units)` or similar: those collections are userdata in-game and raise `bad argument #1 to 'pGlobal_ipairs'`.
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
  - `CityInfo` helper table. Current single-purpose city-panel helpers are `Name`, `Population`, `Health`, `Growth`, `BorderGrowth`, `Production`, `Housing`, `Religion`, `BuildingsOrLoyalty`, `VisibleYields`, `NormalFocusYields`, `FavoredFocusYields`, and `IgnoredFocusYields`
  - `CityInfoBuckets`, which define the current main city-panel read buckets:
    - summary / tilde: `Name`, `Population`, `Health`, `Production`, `Growth`
    - `Shift+1`: `Name`, `Health`
    - `Shift+2`: `Production`
    - `Shift+3`: `Growth`
    - `Shift+4`: `BorderGrowth`
    - `Shift+5`: `Religion`
    - `Shift+6`: `Population`, `Housing`, `BuildingsOrLoyalty`
    - `Shift+7`: `VisibleYields`
    - `Shift+8`: `NormalFocusYields`
    - `Shift+9`: `FavoredFocusYields`
    - `Shift+0`: `IgnoredFocusYields`
  - `RequestCityInfo(cityOrCityID, requestedKeys, playerID)` which defaults to the currently selected city when no city is passed
- `CityPanel_CAI.lua` now builds city info from `GetCityData(city)` using the same vanilla loc keys / string assembly patterns as `CityPanel.lua`; it does not read back from UI controls or call `ViewMain(data)`.
- The city-selection speech path is now consistent with manual summary reads: `Events.CitySelectionChanged` requests the same summary bucket instead of a separate summary helper.
- City growth / production helpers can also expose the visible progress-bar state from `GetCityData(city)`:
  - growth: `CurrentFoodPercent`, `FoodPercentNextTurn`
  - production: `CurrentProdPercent`, `ProdPercentNextTurn`
- City panel border-growth speech now uses the city-panel growth tile as parity target: it speaks the target hex direction relative to the city via `CAIHexCoordUtils.directionString(...)` plus the same live culture values vanilla uses for the tile meters (`GetNextPlot()`, `GetCurrentCulture()`, `GetCultureYield()`, `GetNextPlotCultureCost()`, `GetTurnsUntilExpansion()`).
- Main `CityPanel` parity rules currently mirrored by CAI:
  - the old city coords helper was removed from normal city-panel reads
  - border growth is a dedicated helper built from `city:GetCulture()` (`GetNextPlot()`, `GetNextPlotCultureCost()`, `GetCurrentCulture()`, `GetCultureYield()`, `GetTurnsUntilExpansion()`)
  - XP1 / XP2 main-panel first-slot parity uses `IsExpansion1Active()` / `IsExpansion2Active()` from `Civ6Common.lua`; when an expansion ruleset is active CAI speaks current loyalty from `city:GetCulturalIdentity():GetLoyalty()`, otherwise it speaks building count like base vanilla
- `UnitPanel.lua` owns selected-unit panel data and action button construction:
  - `ReadUnitData(unit)` builds the panel data table from the live unit, including name, type, movement, health, charges, promotions, abilities, stats, and `Actions`.
  - `GetSubjectData()` returns the current selected-unit data table cached by `View(data)`.
  - `GetUnitActionsTable(unit)` builds `data.Actions` with vanilla action order, disabled state, tooltip/failure text, callback function, callback void values, and optional sound.
  - Vanilla unit commands and operations use loose `UnitManager.CanStartCommand(...)` / `CanStartOperation(...)` checks to decide whether an action should be visible, then stricter current-executability checks where needed. If the stricter check or tutorial gating fails, the row can still be added with `Disabled = true` and failure reasons appended to `helpString`.
  - `data.Actions.displayOrder.primaryArea` and `secondaryArea` define the normal unit-panel action order. Build actions live in `data.Actions["BUILD"]`.
  - Vanilla does not mix build-improvement actions into the ordinary action stacks. `View(data)` renders `data.Actions["BUILD"]` separately through `BuildActionsStack`, and `RecommendedActionButton` is just a second view over the single `BUILD` entry whose row has `IsBestImprovement = true`.
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
  - `src/data/unitOperationConfig_CAI.sql` assigns missing `HotkeyId` values for visible vanilla `UnitOperations` and visible vanilla `UnitCommands`. Unit-command action ids use the `UnitCommand...` prefix to avoid colliding with operation action ids such as `Upgrade`.
  - `UNITCOMMAND_DELETE` is intentionally not assigned through `UnitCommands.HotkeyId`: vanilla already exposes the `DeleteUnit` input action and separately special-cases it in `OnInputActionTriggered`, so adding it to `m_kHotkeyActions` could double-call the delete prompt.
- `UnitPanel_CAI.lua` extends `ExposedMembers.CAIInfo` with `RequestUnitInfo(unitID, requestedKeys, playerID)`, defaults to `UI.GetHeadSelectedUnit()`, and uses the same `ReadUnitData` / `GetSubjectData` data rather than reimplementing unit state.
- `UnitPanel_CAI.lua` handles the shared selection info inputs (`~`, `Shift+1` through `Shift+0`) when a unit is selected and opens a transient action list from the existing `SelectionActions` input.
  - CAI unit action-list labels append bound gestures after `: ` by mapping each vanilla action row's `userTag` hash back to its `UnitOperations.HotkeyId` or `UnitCommands.HotkeyId`, then reading `Input.GetGestureDisplayString(actionId, 0/1)`.
  - The standalone view-abilities action id is `UnitViewAbilities`; keep Lua `Input.GetActionId(...)`, `hotkey_config_CAI.xml`, and default gestures on that exact id. `UI_UnitViewAbilities` is not a registered input action.
  - `CAIDeleteUnit` replaces vanilla's `DeleteUnit` input binding for CAI defaults. It must still call vanilla `OnPromptToDeleteUnit()`, not request deletion directly, so the `CanStartCommand(... DELETE ...)` check, confirmation dialog, `m_DeleteInProgress` guard, and `OnDeleteUnit(unitID)` lens cleanup remain vanilla-owned. The action-list binding display special-cases `UNITCOMMAND_DELETE` to `CAIDeleteUnit` because vanilla intentionally does not assign `UnitCommands.HotkeyId` for delete.
  - Current unit bucket mapping is:
    - `Shift+6` -> unit stats
    - `Shift+7` -> unit abilities
    - `Shift+8` -> special unit info (spy, trader, rock band, great person passive)
    - `Shift+9` -> queued movement path
  - `Shift+5` promotion info speaks level / XP progress first, then each earned promotion as `{Name}: {Description}` using `data.CurrentPromotions.Name` / `.Desc`, matching the earned-promotion icon tooltip content sighted players can inspect on the vanilla panel.
  - CAI command-hash lookups should use full DB command keys such as `GameInfo.UnitCommands["UNITCOMMAND_PROMOTE"]`, not short names like `"PROMOTE"`. The selection action list labels promote rows as `LOC_HUD_UNIT_CHOOSE_PROMOTION_TEXT` and adds a synthetic promote row only when live `UnitManager.CanStartCommand(unit, UnitCommandTypes.PROMOTE, true, true)` returns non-empty promotion choices but the cached vanilla action data did not include a promote row.
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
  - `UpdatePromotions()` is also doing double duty as a levy/promotion badge: levied military units show a turn icon instead of a promotion count, while normal units show the earned-promotion count only.
  - `UpdateAircraftCounter()` adds host-carrier / host-airfield capacity info that vanilla exposes visually and through the popup list only: current stationed-aircraft count, max air slots, aircraft names, aircraft icons, and ready/not-ready dimming inside that popup.
  - DLC / mode replacements add extra flag-specific data instead of replacing the whole base model:
    - `BarbarianClansMode` adds tribe tooltip/status coverage for tribe display name, bribed turns, incited-against-you source player, incited-by-you target player, and a tribe-status icon path that takes precedence over the normal promotion badge for eligible clan units.
    - `PiratesScenario` reuses the army marker as a special flagship / infamous-pirate marker for `GetMaxDamage() > 100`, and pirate barbarians replace the tooltip text with the Buccaneer description plus unit name.
    - `CivRoyaleScenario` adds a transient combat-preview bar on visible enemy flags and uses Great Person individual icon overrides plus multiplayer player-name tooltip formatting.
    - `PolandScenario` ships its own older `UnitFlagManager.lua`, but for spoken-info parity it matches the same base tooltip and badge categories above rather than adding new scenario-only unit-flag text.
  - `UnitFlagManager_CAI.lua` now chooses its vanilla include dynamically:
    - `RULESET_SCENARIO_CIV_ROYALE` -> `UnitFlagManager_CivRoyaleScenario`
    - `RULESET_SCENARIO_PIRATES` -> `UnitFlagManager_PiratesScenario`
    - `GAMEMODE_BARBARIAN_CLANS = 1` -> `UnitFlagManager_BarbarianClansMode`
    - otherwise -> `UnitFlagManager`
  - CAI unit-flag speech now keeps the ambient buckets short and additive instead of mirroring the full vanilla tooltip text. New helpers cover promotion count or levy turns, religion name, archaeology home city and artifact owner, aircraft capacity as `current/max`, hero / threat / flagship markers, Barbarian Clans short status, and the Pirates Buccaneer label.
  - Carrier / host-aircraft popup contents come straight from the host unit each refresh. `UpdateAircraftCounter()` uses `unit:GetAirSlots()` for capacity, `unit:GetAirUnits()` for the stationed-aircraft rows, writes the counts into `AirUnitInstance.CurrentUnitCount` / `MaxUnitCount`, and rebuilds `UnitListPopup` from that live list.
  - Local human units dim when not `IsReadyToSelect()`. Selection overrides that dimming so the selected unit stays full alpha.
  - Hidden states are layered: non-visible fog state hides the flag; combat visualization temporarily force-hides attacker/defender/interceptor/anti-air flags; turning the relevant lens layer off hides the entire manager context; and stationed air units usually hide their own individual flags on airstrips, aerodromes, and carriers, except intercepting air units keep a visible flag.
  - Same-tile stacking is communicated visually with per-role offsets and duo/trio formation-link graphics. Those link graphics can be suppressed for non-local players when one member of the formation is hidden.
  - Clicking your own visible flag selects the unit when the current interface mode allows it. Clicking a visible enemy flag with a selected local unit can trigger range attack or move-to-attack.
- Vanilla does not appear to provide clean city-panel loc tags for labeling the two percentage values as speech output, so `CityPanel_CAI.lua` uses CAI loc tags only for:
  - `LOC_CAI_CURRENT_PROGRESS`
  - `LOC_CAI_NEXT_TURN_PROGRESS`
- `CityPanel_CAI.lua` also listens to `Events.InputActionTriggered(actionId)` and uses an action-id-to-helper map instead of an `if` / `elseif` chain.
- Current city selection hotkey mapping uses the shared city-panel buckets:
  - `ReadSelectionSummary` -> `Name`, `Population`, `Health`, `Production`, `Growth`
  - `ReadSelectionInfo1` -> `Name`, `Health`
  - `ReadSelectionInfo2` -> `Production`
  - `ReadSelectionInfo3` -> `Growth`
  - `ReadSelectionInfo4` -> `BorderGrowth`
  - `ReadSelectionInfo5` -> `Religion`
  - `ReadSelectionInfo6` -> `Population`, `Housing`, `BuildingsOrLoyalty`
  - `ReadSelectionInfo7` -> `VisibleYields`
  - `ReadSelectionInfo8` -> `NormalFocusYields`
  - `ReadSelectionInfo9` -> `FavoredFocusYields`
  - `ReadSelectionInfo10` -> `IgnoredFocusYields`
- `CityPanel_CAI.lua` now appends dynamic ranged-strike rows to the city `SelectionActions` list:
  - availability is gated by `CityManager.CanStartCommand(target, CityCommandTypes.RANGE_ATTACK)` for both the city center and each district owned by the selected city
  - city rows reuse vanilla city targeting flow: `UI.SelectCity(city)` then `UI.SetInterfaceMode(InterfaceModeTypes.CITY_RANGE_ATTACK)`
  - district rows reuse vanilla district targeting flow: `UI.DeselectAll()`, `UI.SelectDistrict(district)`, then `UI.SetInterfaceMode(InterfaceModeTypes.DISTRICT_RANGE_ATTACK)`
  - these rows are CAI-only synthetic menu items, so they centralize strike-capable city and district attacks even though vanilla normally exposes them only on banners / minibanners
- `CityPanel_CAI.lua` also appends dynamic WMD strike rows for strike-capable city districts such as missile silos:
  - availability mirrors vanilla `UpdateWMDBanner()` instead of using `CanStartCommand(...)`: for each supported WMD type, CAI checks local stock through `player:GetWMDs():GetWeaponCount(wmd.Index)` and then calls `CityManager.GetCommandTargets(city, CityCommandTypes.WMD_STRIKE, parameters)` with the district plot as `PARAM_X0` / `PARAM_Y0`
  - launch flow mirrors vanilla `OnICBMStrikeButtonClick(...)`: if already in `ICBM_STRIKE`, switch back to `SELECTION`, then `UI.SelectCity(city)`, `UILens.SetActive("Default")`, and finally `UI.SetInterfaceMode(InterfaceModeTypes.ICBM_STRIKE, parameters)` using the chosen weapon type and district plot
  - CAI additionally jumps the cursor to the firing district plot before entering strike mode so the centralized action list stays spatially grounded
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
- Compared against vanilla base `CityPanelOverview.lua`, current `CityPanel_CAI.lua` only exposes compact speech for summary, health, production summary, growth summary, housing summary, amenity/building counts, religion follower count, visible yields, and yield-focus state. It does not yet mirror most of the detailed left-panel overview content.
- Vanilla base city panel overview exposes these information groups that CAI does not currently speak in structured form:
  - breakdown tab: district count vs district cap, built districts with pillage state, each built building with pillage state, per-entry yield strings, wonders, and trading-post owners
  - religion tab: pantheon belief, dominant religion, other religions in the city, and dominant-religion belief list
  - amenities tab: city mood, growth/yield effect text, amenity advice, required amenities, and the detailed amenity-source breakdown
  - housing tab: housing growth state, housing advice, and the detailed housing-source breakdown
  - citizens/growth tab: gross food, food consumption, net food, growth threshold, happiness bonus, other growth modifiers, housing multiplier, occupation multiplier, modified food, and total surplus/deficit
  - production tab: current production unit stats and explicit production queue rows
- `CityPanel_CAI.lua` currently opens the same vanilla tabs and toggles through native callbacks / controls, but its spoken info registry in `CityInfo` does not include keys for those detailed overview breakdowns.
- Base city-management ownership split confirmed from the decompiled UI:
  - `CityPanel.lua` owns the compact selected-city shell, the overview toggle, the manage-citizens toggle, the purchase-tile toggle, and the enter/leave transitions for `InterfaceModeTypes.CITY_MANAGEMENT`.
  - `CityPanelOverview.lua` owns the detailed left-side overview tabs and their data views: breakdown, religion, amenities, housing, citizens/growth math, current production detail, and production queue.
  - `PlotInfo.lua` owns the in-world per-plot city-management overlays. In citizen management it exposes workable plots, specialist capacity meters, and locked-citizen icons; in tile purchase it exposes per-plot gold buttons and affordability tooltip state; it also owns tile-swap buttons and the city-yield overlay.
  - `WorldInput.lua` does not own the city-management content itself. It only owns the `CITY_MANAGEMENT` mode routing, including enter/leave handlers, Escape-style key handling through `OnPlacementKeyUp`, and a pointer-up no-op so plot overlays, not world selection, consume interaction while the mode is active.
- Expansion 1 adds loyalty/culture data to the city panel:
  - main panel swaps the first stat from building count to current loyalty in `CityPanel_Expansion1.lua`
  - overview adds a loyalty tab (`CityPanelCulture.lua`) with current/max loyalty, loyalty level, per-turn pressure status, detailed source breakdown, loyalty effects, loyalty advice, diplomatic presence, and assigned-governor details including establishment state / turns
  - XP1 also changes citizens-growth math display to show loyalty growth modifiers instead of the old occupation-only wording, and adds governor-derived amenities in `ViewPanelAmenities`
- Expansion 2 keeps the XP1 loyalty/governor culture tab and further adds a power tab (`CityPanelPower.lua`) with:
  - consumed vs required power totals
  - power status name and description
  - consumed, required, and generated power-source breakdowns
  - power advice
- `CityPanel_CAI.lua` should include the same base / XP1 / XP2 `CityPanel` replacement chain that vanilla would load:
  - base ruleset -> `CityPanel`
  - Expansion 1 active -> `CityPanel_Expansion1`
  - Expansion 2 active -> `CityPanel_Expansion2`
- The city action list can open the expansion overview tabs through the overview context LuaEvents rather than loading those panels itself:
  - XP1 / XP2 loyalty-governor overview -> `LuaEvents.CityPanel_ToggleOverviewLoyalty()`
  - XP2 power overview -> `LuaEvents.CityPanel_ToggleOverviewPower()`
- For the planned city-panel redo, the largest parity gaps are the overview subpanels and the XP1/XP2 dynamic tabs, not the main action buttons.
- `WorldTracker.lua` is a passive in-game HUD stack, not a modal chooser:
  - It builds `ResearchInstance`, `CivicInstance`, `OtherContainer`, `UnitListInstance`, `ChatPanelContainer`, and `TutorialGoals` under `Controls.WorldTrackerVerticalContainer` in that order.
  - The header has `Controls.ToggleAllButton` to collapse/expand the whole tracker and `Controls.ToggleDropdownButton` to open tracker options.
  - The options dropdown contains checkbox controls for chat, civics, research, and unit list visibility. `CheckEnoughRoom()` disables unchecked options and sets `LOC_WORLDTRACKER_NO_ROOM` when there is not enough vertical space.
  - Research and civics panels are shown only when their capability exists and the local player is alive. They call `RealizeCurrentResearch(...)` / `RealizeCurrentCivic(...)` from `TechAndCivicSupport.lua`, which populate title text, icon, turns remaining, progress meter, boost meter/icon/label, unlock icons, and overflow page-turn button.
- `Assets/UI/Popups/ChatPanel.lua/.xml` is the in-world multiplayer chat surface mounted inside WorldTracker's `ChatPanelContainer`, not a standalone modal. Base layout is a compact bottom-left tracker card (`294x118` plus border) with a `ChatLogPanel` scroll area, a target `PullDown` styled as `ChatPullDown`, expand/contract buttons, and a drag-resize handle. In Play By Cloud the normal chat card is hidden and replaced by a minimal `PlayByCloudPanel` that only exposes the show-player-list toggle.
- Sighted chat usage is primarily mouse and keyboard-enter based: type into the `ChatEntry` edit box owned by the `ChatPullDown` style, press Enter to send, switch target with the pulldown (`To All`, `To Team` when applicable, or a human player whisper target), click expand/collapse, or drag the bottom-right resize handle. Target changes also recolor the edit box through `PlayerTargetLogic.lua` (`ChatMessage_Global`, `ChatMessage_Team`, `ChatMessage_Whisper`) and can be changed with slash commands parsed in `ChatLogic.lua` (`/g`, `/t`, `/w`, `/help`).
- Chat history is a bottom-growing stacked log of plain text rows plus special map-pin rows. Normal messages are rendered as `player name: text`, with whisper rows including the target name. Messages containing `[pin:x,y]` become `MapPinChatEntry` rows with a clickable pin-name button that calls `UI.LookAtPlot(hexX, hexY)`. The panel auto-scrolls only once the history exceeds the visible log height, and it seeds the log with `LOC_CHAT_HELP_COMMAND_HINT`.
- The adjacent `PlayerListPanel` is a separate toggleable side panel offset to the right of chat. It lists current human / connected players as `PlayerListEntry` pulldowns with a connection-status icon, player name, and a status label from `NetConnectionIconLogic.lua`. Per-player pulldown actions are conditional: host kick, start kick vote, and friend request. The panel may also append an Invite button and an EOS/crossplay join-code row whose text copies to the system clipboard on click.
- Kick-vote flow is another side panel (`KickVotePanel`) using `VoteKickPlayerEntry` rows with a title plus Yes/No buttons. Starting or completing a vote also writes chat-log lines. The local player only sees live vote buttons when they are neither the target nor the initiator.
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
  - `ReportScreen.lua` city-income data is built from `GetCityData(pCity)` plus `GetWorkedTileYieldData(pCity, pCulture)`. District rows come from `data.BuildingsAndDistricts`: each district exposes its own per-turn yields plus an `AdjacencyBonus` table and per-building rows from the district plot. Great works are attached separately through `GetGreatWorksForCity(pCity)`. For CAI, passive report rows should stay `StaticText` so they do not speak expand/collapse state, while district tooltip totals should aggregate the district row's own yields plus adjacency, building, and attached great-work yields.
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
  - Public movement uses two LuaEvents: `CAICursorMoveTo(plotId, reason)` for absolute moves and `CAICursorMoveDirection(direction)` for hex stepping.
  - `reason` is `"step"` (adjacent hex), `"jump"` (scanner/search), `"select"` (unit/city selection), or `"snap"` (post-move/initial placement).
  - `CAICursor:MoveTo(plotId, reason)` is the single internal entry point. It updates coordinates and zones, speaks direction on `"jump"` and `"select"`, and fires `LuaEvents.CAICursorMoved(state)` with a state table (`fromPlotId`, `toPlotId`, `distance`, `fromX`, `fromY`, `toX`, `toY`, `reason`).
  - Listeners use `state.reason` to decide behavior: PlotToolTip speaks on all reasons except `"select"`. Direction speech is reason-based (`"jump"` and `"select"`), not distance-based.
  - Zone tracking announces continent, owner, territory (XP2 deserts/mountains/seas/lakes/oceans), volcano (XP2), natural wonder, and national park on first entry only.
  - Query-style access remains available through the WorldInput `UI` hijack: `UI.GetCursorPlotID()` and `UI.GetCursorPlotCoord()`.
  - Current implementation stores one global cursor position plus one global zone-memory set (`curX`, `curY`, `lastOwnerZone`, `lastContinentZone`, `lastTerritoryZone`, `lastVolcanoZone`, `lastNationalParkZone`). For hotseat, that state should be split per local player so turn handoff can restore the right plot and zone history before any focus-driven speech resumes.
  - Current default cursor input actions are `CAICursorMoveNorthWest`, `CAICursorMoveNorthEast`, `CAICursorMoveWest`, `CAICursorMoveEast`, `CAICursorMoveSouthWest`, and `CAICursorMoveSouthEast`, bound by default to `Q/E`, `A/D`, `Z/C` with numpad `7/9`, `4/6`, `1/3` as alternate bindings.
  - `CAICursorJumpToSelection` is a global world input action bound to `/`. It checks `UI.GetHeadSelectedUnit()` first, then `UI.GetHeadSelectedCity()`, resolves the object's plot with `Map.GetPlot(x, y):GetIndex()`, and raises `LuaEvents.CAICursorMoveTo(plotIndex, "jump")`.
  - CAI city selection replacements use `WorldSelectPreviousCity_CAI` (`[`), `WorldSelectNextCity_CAI` (`]`), and `WorldSelectCapitalCity_CAI` (`\`). They mirror vanilla `WorldInput.lua`: previous/next call `UI.SelectPrevCity(UI.GetHeadSelectedCity())` / `UI.SelectNextCity(UI.GetHeadSelectedCity())`; capital resolves the local capital city and calls `UI.SelectNextCity(capital)`. Use CAI-owned name/description locale keys for these replacement actions; reusing vanilla `LOC_OPTIONS_HOTKEY_GLOBAL_*` labels conflicts in the keybinding UI.
- `WorldInput_CAI.lua` wraps vanilla `WorldInput.lua`:
  - CAI installs all `UI` table overrides in one `InstallUIOverrides()` section. Current overrides are `UI.GetCursorPlotID()` and `UI.GetCursorPlotCoord()`.
  - CAI keeps the vanilla `Events.LoadScreenClose` boundary by wrapping `OnLoadScreenClose(...)`; the main game view widget is created and pushed only after the load screen closes.
  - CAI input action entries are records with `Type` and `Action`. Use `Type = "Started"` for repeat-style inputs such as cursor movement, and `Type = "Triggered"` for one-shot inputs such as path info or interface primary action.
  - CAI registers separate dispatchers for `Events.InputActionStarted` and `Events.InputActionTriggered`, while vanilla `WorldInput` keeps its own subscriptions.
  - Interface-mode-specific action records override shared action records for the same action id.
  - `InterfaceInfo` is the Space-bound world action. `WorldInput_CAI.lua` dispatches it to `SpeakActiveInterfacePlotInfo(...)`, which resolves the CAI cursor plot and calls the active `InterfaceInfoHelpers[UI.GetInterfaceMode()]` function.
  - Shared interface widget activation now has a generic event fallback: when the active interface widget does not override `InterfaceWidgetPrimaryAction` or `InterfaceWidgetSecondaryAction`, `WorldInput_CAI.lua` raises `LuaEvents.CAIInterfaceWidgetPrimaryAction(widgetId, plotId)` or `LuaEvents.CAIInterfaceWidgetSecondaryAction(widgetId, plotId)` using the current CAI widget id and the plot id under the CAI cursor.
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
  - Vanilla `LookAtNotification(...)` syncs the CAI cursor through `LuaEvents.CAICursorMoveTo(plotId, "jump")` when a notification has a valid location or target, except while the CAI notification center is open. Browsing the tree should not move the cursor.
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
- Vanilla `DedicationPopup.lua` / `DedicationPopup.xml` (XP1 / XP2 additions):
  - Each dedication row is a `SelectCheck` `GridButton` under `Controls.CommemorationsStack` with two readable child labels inside its detail stack: `MomentCategory` and `MomentBonuses`.
  - `CreateCommemoration(...)` fills `MomentCategory` from `CategoryDescription` and fills `MomentBonuses` from the age-appropriate bonus description text, appending the normal-age quest line for heroic ages when `IsPlayerAlwaysAllowedCommemorationQuest(...)` is true.
  - The CAI popup should keep reading the live `MomentBonuses` control text for tooltip speech, but if that control contains a heading line followed by bonus lines, trim only the first line so the checkbox label does not immediately repeat the dedication heading before the actual bonus text.
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
- Intel tabs do NOT all share a single creation chokepoint. The base tabs (overview/gossip/access/relationship) are built by `AddIntelTab(tabPanelIM, tooltip, header, icon)`, but the expansion tabs are added by separate adders that bypass it: `AddIntelAlliance`/`AddIntelEmergency` (Expansion1 replacement) and `AddWorldCongressInfoTab` (Expansion2) each call the lower-level `CreateTabButton()` and `GetTabAnchor()` + `ContextPtr:LoadNewContext(...)`, loading the tab's content into its own context. So wrapping `AddIntelTab` only captures the base tabs. Conditions for the DLC tabs: Alliance shows for any selected player NOT on your team; Emergency shows only when `AreThereEmergenciesForPlayer(selectedID)` (a begun emergency involving both you and them); World Congress is added unconditionally but its whole tab bar is hidden before `GlobalParameters.WORLD_CONGRESS_INITIAL_ERA`. DLC adders that should hide bail before `GetTabAnchor`/`SetHide(true)`, so they don't linger as live tabs.
- To enumerate ALL intel tabs (base + DLC) generically from a wrapper, walk the live tab bar after the panel build instead of wrapping creation: iterate `ms_IntelPanel.IntelTabButtonStack:GetChildren()` and skip `IsHidden()` (pooled/stale) buttons. `ms_IntelPanel` itself is a global and is reachable; the panel/anchor/button instance managers are file-locals and attached Lua fields (`m_HeaderText`/`m_ButtonInstance`) do NOT survive `GetChildren()` (cf. the `LastTenTurnsStack` note below) — only `.CData`-backed control methods are reliable on `GetChildren()` results.
- **Do NOT pre-resolve each tab's header/panel by clicking through them.** `button:DoLeftClick()` is NOT silent: although `ShowPanel(...)` itself plays no sound, `DoLeftClick` fires the Button control's own native press SoundData (from its XML `Style`), so clicking every tab on every panel build produces an audible click-storm. Resolve a tab lazily instead — only when the user actually navigates into it: `DoLeftClick` that one button, then read its title from `ms_IntelPanel.IntelHeader:GetText()` (equals the tab's `Locale.ToUpper("LOC_..._REPORT_*")`, usable as a reader key) and grab the now-visible child of `ms_IntelPanel.IntelPanelContainer` as its panel.
- **Gate the panel switch on live `button:IsSelected()`.** `ShowPanel` calls `SetSelected(true)` on the shown tab's button and `false` on the rest (DLC anchors set `m_ButtonInstance`/`m_HeaderText`, so this works for them too), and `AddIntelPanel` ends with `ShowOverviewPanel()` so Overview is the shown/selected tab after every (re)build. So a tab is already displayed iff its `button:IsSelected()` — skip the `DoLeftClick` in that case to avoid a redundant click (e.g. focusing Overview right after a leader select, or re-entering the tab you're already on). Only an actual tab change should click.
- The base readers' typed instances are captured eagerly: vanilla calls `PopulateIntelOverview`/`OnActivateIntelGossipHistoryPanel`/`OnActivateIntelAccessLevelPanel`/`OnActivateIntelRelationshipPanel` inside `AddIntelPanel` (right after each `AddIntelTab`), NOT on tab click. So wrapping those to stash the instances works without driving any tab clicks.
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
  - Overview Secret Society row (Ethiopia / Secret Societies mode, gated by `GameCapabilities.HasCapability("CAPABILITY_SECRETSOCIETIES")`): vanilla `DiplomacyActionView_SecretSocietyRow.Refresh(selectedID)` reads `Players[selectedID]:GetGovernors():GetSecretSociety()` (a hash, or `-1` for none). Indexes `GameInfo.SecretSocieties[hash].Name` for the known name; `LOC_SECRETSOCIETY_DIPLO_NONE_NAME` when `-1`; and `LOC_SECRETSOCIETY_DIPLO_UNKNOWN_NAME` + `_DESCRIPTION` (tooltip) when unaware. Row header label is `LOC_SECRETSOCIETY`. Quirk: the awareness check `IsAwareOfSecretSociety(hash)` is run against the SELECTED player's own governors (the computed `pLocalPlayer` is unused), so a leader is always aware of their own society and the real name is shown on screen whenever they have joined one — the "Unknown" branch is effectively dead. CAI reconstructs from this same API (the addon is a separate context whose Controls are not reachable) and replicates the awareness quirk for screen parity, surfacing the row as a leaf in the overview reader (`AddOverviewChildren`), not as a separate intel tab.
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
  - In the CAI deal inventory, quantity-bearing rows such as `Iron x60` or `Diplomatic Favor 42` should not repeat the same name again as a tooltip when the tooltip adds no extra detail; otherwise focus speech becomes redundant.
  - Diplomatic Favor is a Gathering Storm-only deal item (`DealItemTypes.FAVOR`), added by the `DiplomacyDealView_Expansion2` wildcard rider, not the base script. It is a bare-amount lump-sum item like gold (no value-type name), traded via the global `OnClickAvailableOneTimeFavor(player, amount)` with a default add amount of `1`. Vanilla `PopulateAvailableFavor` shows it only when `player:GetFavor() > 0` and `not ms_bIsDemand` (favor is not demandable). On-screen amount is the side's current favor balance. `GameInfo`/loc: `LOC_DIPLOMATIC_FAVOR_NAME`, icon `ICON_YIELD_FAVOR`. Because favor carries no `GetValueTypeNameID()`, a generic deal-item label/header path renders it blank+silent — FAVOR needs an explicit branch reading `LOC_DIPLOMATIC_FAVOR_NAME` + `GetAmount()`. Accumulated/stockpiled strategic resources (also GS) need no special handling: they come back from `GetPossibleDealItems(..., DealItemTypes.RESOURCES, ...)` as ordinary `RESOURCES` entries (`MaxAmount` = stockpile, `duration == 0` lump sum) and reuse the XP2-overridden global `OnClickAvailableResource`.
  - The current deal area can show resources, agreements, cities, great works, and captives. City deal entries can expand for detailed city contents.
  - Deal action buttons include `EqualizeDeal`, `AcceptDeal`, `DemandDeal`, `RefuseDeal`, and `ResumeGame`, with visibility depending on whether the current screen is a deal, a demand, or a pending viewed proposal.
  - Visually, `DiplomacyDealView.xml` is a full-screen modal sheet with a tall parchment/banner panel on the left half of the screen, an animated leader speech bubble at the top, and a small animated yield strip in the top-right for science, culture, faith, and gold. Inside the main trade panel, the content is split into two mirrored columns: left for the local player and right for the other player.
  - The body is vertically divided into two mirrored sections. The upper section is the current offer area, labeled `My Offer` and `Their Offer`; the lower section is the inventory area showing what each side can add. A draggable resize handle sits between them, so sighted players can drag the divider to give more height to offers or inventory.
  - Inventory items are presented as icon tiles or icon-plus-text rows grouped under headers. Gold and resources are mostly compact horizontal icon rows. Agreements, cities, great works, and captives use vertical category blocks with collapsible headers. When collapsed, the category turns into a minimized icon strip rather than disappearing completely.
  - Offer items are interactive review rows rather than plain text. Left click edits an item's amount or parameter when the item supports it, right click removes the item, and a dedicated remove button is also shown on the row. For AI-proposed items the screen can also show a small "don't ask again" marker button for unacceptable items.
  - CAI offer-diff announcements need three cases from the per-side offer snapshot: removed items, changed-in-place items (same deal item ID, different spoken label such as amount or target), and newly added items. Speak them in that order so mutations are heard as removals/changes before additions.
  - `DLC/KublaiKhan_Vietnam/UI/Replacements/DiplomacyDealView_KublaiKhanVietnam_MODE.lua` does not add new deal-item types or interactions. Its deal-view impact is limited to Monopolies & Corporations product great works: it overrides `GetGreatWorkIcon(...)` to swap in the product resource icon and overrides `GetGreatWorkTooltip(...)` to append the product's `GameInfo.ResourceIndustries().ResourceEffectTExt` line. CAI deal-view great-work tooltip sites should therefore follow vanilla's own pattern and call `GetGreatWorkTooltip(greatWorkDesc, GreatWorksSupport_GetBasicTooltip(...))` directly, so DLC/mode overrides stay in the path.
  - Deal-view tooltip rule: prefer the same vanilla tooltip functions and primary-row tooltip logic before building CAI text. Current relevant vanilla paths are `MakeCityToolTip(...)`, `GetParentItemTransferToolTip(...)`, `GetGreatWorkTooltip(...)`, and the primary-row rules in `PopulateAvailable*` / `PopulateDeal*` (for example: available agreements with no duration have no main tooltip, captives have no main tooltip, city-child great works use plain `GreatWorksSupport_GetBasicTooltip(...)`, and invalid available resources append the red no-cap-room message instead of reusing the normal tooltip).
  - Vanilla localization keys matter here too: the per-item unacceptable marker text is `LOC_DIPLO_DEAL_UNACCEPTABLE_ITEM_TOOLTIP` (`Offer blocking deal`), not `LOC_DIPLOMACY_DEAL_UNACCEPTABLE`, and the stop-asking affordance text already exists as `LOC_DIPLO_DEAL_MARK_UNACCEPTABLE`. Prefer those vanilla loc keys over CAI-owned substitutes.
  - `OnClickAvailableAgreement(player, agreementType, agreementTurns)` does NOT add an item for `DealAgreementTypes.JOINT_WAR`, `THIRD_PARTY_WAR`, or `RESEARCH_AGREEMENT` — it calls `ShowAgreementOptionPopup(...)` to pick the target/war-type/tech first, and only `OnSelectAgreementOption(agreementType, turns, value, parameters, fromPlayerID)` then adds the item. All other agreement types (and `ALLIANCE`) add directly on click; their value, where any, is chosen later via the offer item's value-edit. So a CAI layer that only wraps the click + offer-edit path will silently no-op on joint/third-party war and research agreements (the item never gets created, and the vanilla option popup is mouse-only). The accessible fix is to detect those three types at inventory-click time and push the same option list the offer-edit selector builds (`GetPossibleDealItems(from, to, AGREEMENTS, agreementType, pForDeal)` → rows with `ForType`/`Parameters.WarType`, activated via `OnSelectAgreementOption`).
  - Editing an item opens a centered darkened-overlay popup inside the same screen. For gold/resources it shows the item icon, amount field, left/right arrow buttons, and a confirm/back button. For agreement items it instead shows a scrollable option list, such as alliance type, research target, or joint-war target.
  - City items are visually richer than other rows. They can show a collapse/expand button that reveals child detail icons inside the row's own detail grid, so sighted players can inspect the city's bundled contents before deciding whether to keep it in the trade.
  - The leader-dialog bubble at the top is reused as deal feedback text. It changes to reactions such as unfair deal, invalid deal, gift, acceptable proposal, equalize failed, and demand flavor text, so sighted players get immediate conversational feedback while modifying the deal.
  - Human interaction on this screen is strongly mouse-oriented in vanilla. Players click inventory items to add them, click or arrow-adjust existing deal items to edit values, right click or hit remove to take items back out, click header chevrons to collapse deal categories, drag the central resize handle, and use the bottom action buttons to propose, accept, demand, refuse, cancel, or resume.
  - Keyboard handling in base Lua is minimal here. `DiplomacyDealView.lua` explicitly handles Escape only, routing it to popup close, Resume Game, or Refuse/Cancel depending on state. Everything else is expected to go through ordinary control focus/click behavior rather than a screen-specific keyboard navigation layer.
- Trade route UI family:
  - Base `InGame.xml` registers three direct contexts: `TradeOverview`, `TradeRouteChooser`, and `TradeOriginChooser`. The base game has no wildcard include for these contexts. I found no XP1/XP2 replacements for the route chooser or origin chooser in the decompiled mirror; the only DLC replacement found was `DLC/Indonesia_KhmerScenario/UI/Replacements/TradeOverview_Indonesia_KhmerScenario.lua`, which includes base `TradeOverview` and only adds the maritime city-state icon branch.
  - `TradeOverview.lua/.xml` is the trade-routes side panel opened from `PartialScreenHooks` through the `ToggleTradeRoutes` input action or the launch-bar trade hook. It is unlocked once the local player's outgoing route capacity is greater than zero and requires `CAPABILITY_TRADE_VIEW`.
  - Visually, `TradeOverview.xml` is a tall right-side style partial panel with a dark title/header frame, three tab buttons across the top (`My Routes`, `Routes to My Cities`, `Available Routes`), a header row with active/capacity text where relevant, origin/destination column labels, a central `BenefitsButton` that toggles whether route rows show my benefits or their benefits, and a vertical scroll body of section headers plus route rows.
  - `TradeOverview` route rows are compact 482x78 list buttons. Each row shows an origin-to-destination label, origin and destination civilization/city-state icons, a benefactor arrow pointing to the side whose benefits are being displayed, a horizontal yield strip, optional religion-pressure icon/value, optional trade-route bonus icon, trading-post indicator, route distance in turns, and on the My Routes tab a trade-route status icon. The row tooltip is the detailed yield-source breakdown returned by `TradeSupport.GetYieldsForRoute(...)`.
  - `TradeOverview` tabs rebuild different models: `My Routes` groups the local player's outgoing routes by destination player and appends unused-route rows; `Routes to My Cities` groups foreign incoming routes by origin player; `Available Routes` scans every local origin city against every known destination city with `Game.GetTradeManager():CanStartRoute(...)`.
  - Interaction in `TradeOverview` is mostly mouse clicks: tab buttons switch sections; `BenefitsButton` toggles my/their benefits; route rows with live trader units select and center that trader; available-route rows from idle traders also raise `LuaEvents.TradeOverview_SelectRouteFromOverview(destinationPlayerID, destinationCityID)` to open/select that destination in `TradeRouteChooser`; unused-route rows either select an idle trader with `Choose Route` or show a disabled `Produce Trade Unit` row.
  - `TradeRouteChooser.lua/.xml` is the left slide-out destination picker for `InterfaceModeTypes.MAKE_TRADE_ROUTE`. Opening it sets `LuaEvents.TradeRouteChooser_SetTradeUnitStatus("LOC_HUD_UNIT_PANEL_CHOOSING_TRADE_ROUTE")`, activates the `TradeRoutes` lens, rebuilds possible destination cities from the selected trader's origin city, draws every filtered route path on the map lens, and optionally preselects the last completed route or a route requested by `TradeOverview`.
  - Visually, `TradeRouteChooser.xml` has a 310px left panel. The top preview card shows the selected destination city banner, trading-post and route-bonus icons, quest icon for city-state trade-route quests, route distance, two resource boxes for what the destination receives and what the origin receives, and `No benefits` text when applicable. The lower panel has a pulldown filter and a vertical scroll list of destination city cards. A bottom confirmation drawer appears for a selected route, with `Begin Route` and `Cancel`.
  - Destination rows in `TradeRouteChooser` mirror small city banners: selected brace, city name colored by owner, trading-post icon, route-bonus icon, city-state quest icon, distance, and a yield/religion strip. Row tooltip is the origin-side route yield breakdown. Clicking a row selects it, moves the camera to the destination city with `UI.LookAtPlotScreenPosition(...)`, refreshes the map route lens, and raises `LuaEvents.TradeRouteChooser_RouteConsidered()`.
  - `TradeRouteChooser` filters are built dynamically into `DestinationFilterPulldown`: all routes, each reachable civilization/city-state group, city-states, and one entry per yield type. Yield filters sort by descending yield value. Filter choice rebuilds only the destination stack and route-path lens, not the origin city.
  - Confirming a route calls `UnitManager.RequestOperation(selectedTrader, UnitOperationTypes.MAKE_TRADE_ROUTE, { X0/Y0 = destination city, X1/Y1 = trader plot })` after rechecking `UnitManager.CanStartOperation(...)`, then returns to `InterfaceModeTypes.SELECTION` and plays `START_TRADE_ROUTE`. Escape closes the chooser and restores the default lens.
  - `TradeOriginChooser.lua/.xml` is a much simpler left slide-out used for `InterfaceModeTypes.TELEPORT_TO_CITY` when the selected unit is a trade unit. It lists the local player's other cities that pass `UnitManager.CanStartOperation(...)` for the active operation. Clicking a city requests that operation with destination `PARAM_X/PARAM_Y`, returns to selection mode, plays `Unit_Relocate`, and closes.
  - `TradeSupport.lua` is shared by `TradeOverview` and `TradeRouteChooser`. `GetIdleTradeUnits(playerID)` identifies trade units with no matching outgoing route. `GetYieldsForRoute(originCity, destinationCity, bReturnDestinationYields)` combines route yields, path/trading-post yields, modifier yields, international yield multipliers, and majority-religion pressure into `kYieldValues`, `TooltipText`, `HasPathBonus`, `MajorityReligion`, and `ReligionPressure`.
  - Accessibility-shape implication: `TradeOverview` should be a CAI `Panel` containing a `TabControl`, a benefits toggle button, and per-tab `Tree`/`List` content grouped by player/city-state/unused routes. `TradeRouteChooser` should be a separate CAI surface with a destination filter `Dropdown`, a destination `List`, a read-only selected-route summary, and explicit `Begin Route` / `Cancel` buttons. `TradeOriginChooser` can be a small transient `List` of cities. All three should preserve vanilla callbacks by wrapping `Open`/`Close`/`Refresh`/selection functions and activating live controls or vanilla functions rather than issuing operations from duplicated UI state except where vanilla itself already does so.
- Diplomacy context-extension mechanics (important for CAI load strategy):
  - `DiplomacyDealView.lua` ends with `include("DiplomacyDealView_", true)` — a **wildcard host**: it pulls in every loaded file whose name starts with `DiplomacyDealView_`. `Initialize()` is called on the line *after* the wildcard include (`DiplomacyDealView.lua:3179` vs `:3177`), so a wildcard-included file runs while all vanilla functions exist but before handlers are registered. The file's own comment says a new `DiplomacyDealView_*` file must NOT `include("DiplomacyDealView")`. CAI therefore ships `DiplomacyDealView_CAI.lua` as a wildcard rider (InGame `<ImportFiles>` File, no `ReplaceUIScript`): it only reassigns globals and lets vanilla's later `Initialize()` register them. `ms_bIsDemand` and the `OnClickAvailable*` / `OnValueEditButton` / `OnSelectAgreementOption` callbacks are true globals, reachable from the rider.
  - `DiplomacyActionView.lua` has **no** wildcard include, so it must be extended via `ReplaceUIScript`. The expansions register their own `ReplaceUIScript` on the same `DiplomacyActionView` context (`Expansion1.modinfo` criteria=Expansion1 → `DiplomacyActionView_Expansion1.lua`; `Expansion2.modinfo` criteria=Expansion2 → `DiplomacyActionView_Expansion2.lua`, which chain-includes the XP1 file). A CAI `ReplaceUIScript` that `include("DiplomacyActionView")` (base) would clobber all expansion logic on XP1/XP2. Fix: branch on `IsExpansion2Active()` / `IsExpansion1Active()` and re-include the matching variant (same approach as `GovernmentScreen_CAI`).
  - `AddIntelTab(tabPanelIM, buttonTooltip, headerText, buttonIcon)` is the single chokepoint that creates every intel tab — base overview/gossip/access/relationship and all DLC tabs. It returns the panel instance; `inst:GetTopControl()` is the panel control, and it caches `m_ButtonInstance` / `m_HeaderText` on that control. Wrapping `AddIntelTab` captures the full live tab set generically (the `headerText` arg is the already-`Locale.ToUpper`'d display string). `AddIntelPanel(rootControl)` is the per-selected-player rebuild that runs `PopulateIntelPanels` → the `AddIntel*` adders.
  - DLC intel additions are separate contexts that populate reserved containers in response to `LuaEvents.DiploScene_RefreshTabs(playerID)` and `LuaEvents.DiploScene_RefreshOverviewRows(playerID)`, both raised synchronously *during* the intel build (XP1's `PopulateIntelPanels` override raises RefreshTabs; base `AddIntelOverview` raises RefreshOverviewRows). XP1 adds the Alliance and Emergency tabs (`DiplomacyActionView_AllianceTab` / `_EmergencyTab`); XP2 adds the World Congress tab (`_WorldCongressTab`); the Ethiopia/Secret-Societies mode adds an overview row via `_SecretSocietyRow`.
  - The base intel tab order is stable: `AddIntelOverview()` creates the Overview tab first, then Gossip, Access Level, and, only for non-human selected players, Relationship. XP1/XP2 append Alliance, Emergency, and World Congress after that base set. The overview tab button tooltip is `LOC_DIPLOMACY_INTEL_OVERVIEW_COLON_TOOLTIP`, which is a reliable identifier when CAI wants to suppress the overview node but still keep vanilla tab selection in sync.
  - Agenda sourcing differs by ruleset. Base overview uses `selectedPlayer:GetAgendaTypes()` and removes the first entry as the historical agenda before applying visibility gating. The XP2 override instead uses `selectedPlayer:GetAgendasAndVisibilities()` and checks each returned entry's `Visibility` against the local player's current access level. For GS-safe parity, prefer the XP2-style `GetAgendasAndVisibilities()` path when present and fall back to the base `GetAgendaTypes()` path otherwise.
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
  - CAI adds movement hints from other confirmed vanilla systems: for non-queued movement preview only, visible ZOC is detected by intersecting `pathInfo.plots` with `UnitManager.GetReachableZonesOfControl(unit, true)`. CAI tracks two internal facts from that set: any non-destination path node means `intersects zone of control`, while a destination plot means `ends at zone of control`. Spoken output is intentionally mutually exclusive: destination ZOC takes priority, otherwise CAI speaks intersection. War-start warning still follows `CombatManager.IsAttackChangeWarState(unit:GetComponentID(), x, y)`.
  - CAI now splits movement preview verbosity by caller: ordinary move-mode cursor reads from `GetActiveInterfacePlotInfo(...)` keep the compact summary only, while explicit `Space` reads through `SpeakActiveInterfacePlotInfo(...)` add the step-by-step path line plus fog / unexplored path lines. Compact cursor reads should still keep failure, arrival turn, obstacle, tunnel, ZOC, war-start, combat-at-destination, and blocked-state speech.
  - Detailed path-step speech now honors turn breaks in both places that expose the full path. Explicit move preview splits visible steps into per-turn segments using `pathInfo.turns`, while queued-path speech splits cached visible steps at queued waypoint markers; both join segments with localized `then`.
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
  - `WorldScannerCategory_cityManagement.lua` now exposes the active `CITY_MANAGEMENT` overlay as a scanner category when that interface mode is active and either the citizen-management lens or purchase lens is on.
    - It rebuilds from the shared city-management helper instead of caching live controls.
    - Current subcategories are `locked`, `specialists`, `worked`, `available`, `swappable`, `purchasable`, and `tooExpensive`.
    - Scanner item labels reuse the same full spoken line as `InterfaceInfo` for that plot so Space reads and scanner reads stay aligned.
  - `GetActiveInterfacePlotInfo(plot)` dispatches by `UI.GetInterfaceMode()` through `InterfaceInfoHelpers[...]`.
  - `SpeakActiveInterfacePlotInfo(plot)` is the one-shot speech wrapper for the Space-bound `InterfaceInfo` action. Helpers remain plain functions and return either a string, a list of strings, nil, or `false` when explicit speech was handled by side effect.
  - Current supported preview modes include `MOVE_TO`, `CITY_MANAGEMENT`, `DISTRICT_PLACEMENT`, `BUILDING_PLACEMENT`, `RANGE_ATTACK`, `CITY_RANGE_ATTACK`, `DISTRICT_RANGE_ATTACK`, `AIR_ATTACK`, `DEPLOY`, `REBASE`, `TELEPORT_TO_CITY`, `FORM_CORPS`, `FORM_ARMY`, `AIRLIFT`, `SACRIFICE_SELECTION`, `KILL_WEAKER_UNIT`, `TRANSFORM_UNIT`, `RESTORE_UNIT_MOVES`, and `NAVAL_GOLD_RAID`.
  - Ranged, city ranged, district ranged, and air attack helpers call `LuaEvents.CAISpeakCombatPreview()` and return `false`; combat preview speech remains owned by `UnitPanel_CAI.lua`.
  - `CITY_MANAGEMENT` interface info is now rebuilt from the same live `CityManager.GetCommandTargets(...)` data that `PlotInfo.lua` uses instead of reading overlay controls:
    - citizen management uses `CityCommandTypes.MANAGE` and reads `PLOTS`, `CITIZENS`, `MAX_CITIZENS`, and `LOCKED_CITIZENS`
    - tile swapping uses `CityCommandTypes.SWAP_TILE_OWNER`
    - tile purchase uses `CityCommandTypes.PURCHASE` plus live `city:GetGold():GetPlotPurchaseCost(plotId)` and local treasury gold
    - speech intentionally does not split compact vs explicit modes; passive preview and explicit `Space` both say the same full plot-state line and omit unavailable states
  - `PlotInfo_CAI.lua` now replaces `PlotInfo` and keeps vanilla overlay logic, but listens for the generic `CAIInterfaceWidgetPrimaryAction` and `CAIInterfaceWidgetSecondaryAction` Lua events.
    - It reacts only when `widgetId == "CAIWorldInputCityManagement"`.
    - Primary resolves to purchase first when the purchase lens is active on that plot, otherwise citizen manage; secondary resolves explicitly to tile swap.
    - It wraps vanilla `OnClickCitizen(...)`, `OnClickPurchasePlot(...)`, and `OnClickSwapTile(...)` only to prime a pending action payload with owner, city id, and clicked plot id.
    - Result speech is then driven by matching game events: `CityWorkerChanged(ownerPlayerID, cityID)` for manage, `CityMadePurchase(owner, cityID, plotX, plotY, purchaseType, objectType)` for purchase, and `CityTileOwnershipChanged(owner, cityID)` for swap.
    - Vanilla uses both a 2-arg and a 4-arg `OnCityWorkerChanged` helper signature in different UI files, but CAI's pending manage feedback should treat the event as owner + city only and then speak the pending plot's refreshed state.
    - Purchase matching should agree on owner, city, and purchased plot id. Swap matching should agree on owner and city, then speak the pending plot's refreshed state.
    - It also listens to `LuaEvents.CAICursorMoved` and reuses vanilla `OnSpinningCoinAnimMouseEnter(...)` to play the purchase coin animation when the CAI cursor lands on an affordable purchase plot.
  - District placement preview reuses vanilla `AdjacencyBonusSupport.GetAdjacentYieldBonusString(...)` for the short bonus summary, detailed tooltip text, and requirement/warning text, while CAI computes owned-valid versus purchasable-valid state locally from `CityManager.GetOperationTargets(...)` and `CityManager.GetCommandTargets(...)`.
  - Wonder placement uses valid owned plots from `CityManager.GetOperationTargets(...)` and valid purchasable plots from `CityManager.GetCommandTargets(...)` filtered through `plot:CanHaveWonder(...)`.
  - Non-attack targeting/destination helpers use shared `CAIInterfaceTargets` target resolution. Space says `Valid` plus the plot target label, `Invalid target` when the CAI cursor is not on an eligible plot, and for `FORM_CORPS` / `FORM_ARMY` appends `formation target` after the target unit name.
  - `PlotToolTip_CAI.lua` now treats `PlotInfo5` as a general interface preview slot rather than a movement-only slot, and automatic cursor speech includes the same interface preview lines when the active mode supplies them.
- CAI cursor-move plot speech now distinguishes revealed fog from both live-visible plots and unexplored plots. Use `PlayersVisibility[observer]:IsRevealed(plot)` together with `:IsVisible(plot:GetIndex())`: revealed plus not visible should speak the CAI-owned `Fog` helper, while unrevealed plots still fall back to the terrain-name helper's fog-of-war behavior.
- NavCursor zone-state updates should use that same visibility gate. When the cursor lands on an unrevealed plot, do not recompute or overwrite the remembered continent / owner zone state; only visible or revealed plots should update those zone trackers.
  - `PlotToolTip_CAI.lua` now selects its vanilla include by active rules content: base `PlotToolTip`, `PlotTooltip_Expansion2` when `IsExpansion2Active()` is true, `PlotToolTip_BarbarianClansMode` when `GameConfiguration.GetValue("GAMEMODE_BARBARIAN_CLANS") == 1`, and `PlotTooltip_Expansion2_BarbarianClansMode` when both are active.
  - `ExposedMembers.CAIInfo:RequestPlotInfo(plot, requestedKeys, optionalPlotId)` returns a flat `string[]`. Existing callers can keep passing the explicit `plot` object. Callers that need info for a specific target plot without depending on the current cursor plot can pass `nil` for `plot` and the target plot id as `optionalPlotId`. Individual plot info helpers may return either one string or a list of strings; the request path must flatten helper tables before concatenating speech. This matters for `interfaceInfoHelpers_CAI.lua`, whose movement and placement previews are multi-line.
  - `PlotToolTip_CAI.lua` also owns one-shot plot read actions through `Events.InputActionTriggered`. The current action ids are `PlotReadUnits`, `PlotReadYieldRiverOwner`, `PlotReadStats`, `PlotReadRelativeCoords`, and `PlotReadDistrictBuildings`; each action builds a requested-key list and then routes through the same `RequestPlotInfo(...)` / helper pipeline used by cursor speech.
  - `PlotReadStats` intentionally uses separate `movement`, `defense`, and `appeal` helpers instead of a bundled physical-info bucket. `relativeCoords` is the one helper allowed to speak when plot visibility gates would otherwise suppress normal tooltip data.
  - Current default bindings in `src/data/hotkey_config.xml`: `S` / `NP_5` -> `PlotReadUnits`, `W` / `NP_8` -> `PlotReadYieldRiverOwner`, `X` / `NP_2` -> `PlotReadStats`, `Shift+S` / `Shift+NP_5` -> `PlotReadRelativeCoords`, `B` -> `PlotReadDistrictBuildings`. `WorldTrackerReadSummary` moved to `Shift+W` to free `W` for plot reads.
  - `WorldInput_CAI.lua` exposes both move mode and district placement mode through CAI `InterfaceMode` widgets; district placement uses the same Escape / primary-action widget pattern as move mode, but routed to `OnMouseDistrictPlacementCancel()` and `OnMouseDistrictPlacementEnd()`.
  - `WorldInput_CAI.lua` also exposes targeting widgets for `RANGE_ATTACK`, `CITY_RANGE_ATTACK`, `DISTRICT_RANGE_ATTACK`, `AIR_ATTACK`, `WMD_STRIKE`, `ICBM_STRIKE`, `COASTAL_RAID`, `DEPLOY`, `REBASE`, `TELEPORT_TO_CITY`, `FORM_CORPS`, `FORM_ARMY`, `AIRLIFT`, `SACRIFICE_SELECTION`, `KILL_WEAKER_UNIT`, `TRANSFORM_UNIT`, `RESTORE_UNIT_MOVES`, and `NAVAL_GOLD_RAID`. Return delegates to the matching vanilla execution function, and Escape delegates through vanilla `OnPlacementKeyUp(...)`.
  - Base-game interface modes that still do not have CAI world-input widgets fall into two groups:
    - World-input-light modes whose useful information lives elsewhere:
      - `MAKE_TRADE_ROUTE` - `WorldInput.lua` only changes cursor; route choice and route details live in `Choosers/TradeRouteChooser.lua` plus related city-banner trade selection hooks.
      - `PLACE_MAP_PIN` - `WorldInput.lua` only changes cursor and commits placement; the user-facing flow lives in `Popups/MapPinListPanel.lua`.
      - `SPY_CHOOSE_MISSION` and `SPY_TRAVEL_TO_CITY` - `WorldInput.lua` only resets cursor/lens; chooser content lives in `Choosers/EspionageChooser.lua` and `Popups/EspionagePopup.lua`.
      - `FULLSCREEN_MAP` - visible content lives in `FullscreenMapPopup.lua`.
      - `VIEW_MODAL_LENS` - world input only routes clicks; active lens labels and state live in `MinimapPanel.lua`, `Panels/ModalLensPanel.lua`, and other HUD listeners.
      - `CITY_SELECTION` - `WorldInput.lua` only resets cursor; the mode is entered by `Panels/CityPanelOverview.lua` and coordinated with `Panels/ModalLensPanel.lua`.
      - `CINEMATIC` and deprecated `NATURAL_WONDER` - world input only toggles fixed tilt / cursor state; actual content lives in cinematic popups such as `NaturalWonderPopup.lua`, `WonderBuiltPopup.lua`, and `ProjectBuiltPopup.lua`.
    - Modes with little or no normal gameplay payload in world input:
      - `SELECTION` - ambient/default world mode. Useful speech is already split across CAI cursor reads, plot tooltip, scanner, surveyor, unit panel, city panel, and notification/HUD readers rather than a dedicated world-input widget.
      - `DEBUG` and `WB_SELECT_PLOT` - debug / World Builder only.
  - Expansion world-input replacements add interface modes that CAI currently does not mirror:
    - Expansion 1 adds `PARADROP` and `PRIORITY_TARGET` in `DLC/Expansion1/UI/Replacements/WorldInput_Expansion1.lua`. Expansion 2 includes that XP1 replacement layer too.
    - Expansion 2 adds `BUILD_IMPROVEMENT_ADJACENT` and `MOVE_JUMP` in `DLC/Expansion2/UI/Replacements/WorldInput_Expansion2.lua`.
    - Unlike city management, these four expansion modes are true world-input-owned target-selection modes. Their visible payload is built directly by the world-input replacement itself from `UnitManager.GetCommandTargets(...)` or `UnitManager.GetOperationTargets(...)` plus placement / movement overlays, so CAI should eventually add first-class interface widgets for them rather than delegating them to another popup or panel.
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

- `ReligionScreen.lua` / `ReligionScreen.xml` (decompiled/Assets/UI/):
  - Mainline base, Rise and Fall, and Gathering Storm all register the same `ReligionScreen` context. Base `Assets/UI/InGame.xml`, XP1 `DLC/Expansion1/UI/InGame.xml`, and XP2 `DLC/Expansion2/UI/Replacements/InGame.xml` each declare `<LuaContext ID="ReligionScreen" FileName="ReligionScreen" Hidden="1"/>`; there is no separate XP1/XP2 religion-screen replacement in the decompiled UI mirror.
  - Mainline base, Rise and Fall, and Gathering Storm also keep the same standalone `PantheonChooser` context. `Assets/UI/InGame.xml` registers `<LuaContext ID="PantheonChooser" FileName="PantheonChooser" Hidden="1"/>`, and there is no separate XP1/XP2 pantheon-chooser replacement in the decompiled UI mirror.
  - Opening path is split across three vanilla entry points:
    - `LaunchBar.lua` opens `PantheonChooser` instead of `ReligionScreen` when the local player can found a pantheon and has none yet; otherwise it raises `LuaEvents.LaunchBar_OpenReligionPanel()`.
    - `NotificationPanel.lua` routes both choose-pantheon and choose-religion notifications into the religion flow (`OpenPantheonChooser` for pantheon, `OpenReligionPanel` for religion).
    - `PantheonChooser.lua` closes after founding the pantheon, then immediately raises `LuaEvents.PantheonChooser_OpenReligionPanel()` so the full religion screen opens next.
  - `PantheonChooser.lua` / `PantheonChooser.xml` (decompiled/Assets/UI/Choosers/) is a separate compact left slide-out chooser:
    - `PantheonChooserSlideAnim` slides a 495px-wide panel in from the left.
    - Top panel: decorative religion frame plus either the generic `Choosing a Pantheon` title or a selected-belief summary card.
    - Body panel: one scrollable vertical stack of pantheon belief buttons; each row is a large card with icon, uppercase belief name, and wrapped description.
    - Bottom drawer: `Found this Pantheon` confirm button plus `Reselect Pantheon` clear-selection button.
    - Interaction model: single-select only. Clicking a belief highlights it and reveals the confirm drawer; clicking the selected summary card or the reset button clears the selection; Escape or the close button closes the chooser.
    - Confirm path: `ConfirmPantheon()` submits `PlayerOperations.FOUND_PANTHEON`, closes the chooser, then raises `LuaEvents.PantheonChooser_OpenReligionPanel()` to open the full religion screen.
  - The religion screen is a single stateful popup that swaps whole-page containers on one shared context. `ViewMyReligion()` is the state router and chooses among:
    - `WorkingTowardsPantheon()`
    - `WorkingTowardsReligion()`
    - `ChooseReligion()`
    - `SelectPantheonBeliefs()`
    - `SelectReligionBeliefs()`
    - `ConfirmPantheonBeliefs()`
    - `ConfirmReligionBeliefs()`
    - `ViewReligion(religionType)`
    - `ViewAllReligions()`
  - XML top-level sections are:
    - `WorkingTowards`: progress/instructions before founding
    - `SelectBeliefs`: choose beliefs for a pantheon or first-time religion founding
    - `AddBeliefs`: add beliefs to an existing founded religion
    - `ChooseReligion`: icon-grid religion picker plus optional custom-name edit box
    - `ViewReligion`: one religion detail page with beliefs, pantheon, unit icons, and city table
    - `ViewAllReligions`: scrollable multi-card summary of every founded religion
  - Tab strip behavior:
    - Tabs are rebuilt every open from live religion state.
    - First tab is always the local player's current religion/pantheon state (`My Religion` or `My Pantheon`).
    - One tab is added for each founded non-pantheon religion other than the player's own.
    - Final tab is `All Religions` only when at least one religion has been founded.
    - When tabs do not fit, middle religion tabs collapse to icon-only buttons and expose the religion name by tooltip instead of visible text.
  - `ViewReligion(...)` is the main sighted-information page. It shows:
    - Religion identity block: large icon, religion name, founder civ, holy city, dominant-city count
    - Unit icon strip: all religious-strength units the local player can own/build in the current ruleset, including scenario-added units; the count badge shows how many are owned, and alpha dimming indicates none owned
    - Pantheon summary block: pantheon icon plus full belief description
    - Beliefs list: unlocked beliefs first, then gray `Locked belief` placeholders up to `NUM_MAX_BELIEFS` (4)
    - Cities table: city name, follower counts for each founded religion, and the active pantheon belief description for that city
    - City filter pull-down with two modes: cities following the selected religion, or cities where the religion is merely present
  - `ViewAllReligions()` is not interactive beyond scrolling; it renders one card per founded religion with religion icon, founder, dominant-city count, and a compact list of equipped beliefs.
  - `ChooseReligion()` uses a grid of clickable religion icons (`ReligionOption` instances). Selecting one updates the big preview icon/title on the left and may enable a custom-name `EditBox` when `RequiresCustomName` and `CAPABILITY_RENAME` are both true.
  - Belief-picking behavior:
    - Available beliefs are displayed as large button rows with icon, uppercase name, and description.
    - Clicking a belief disables its source row and adds it to the selected-beliefs list.
    - When the player has no equipped religion beliefs yet, vanilla forces the first pick to be a follower belief before broader religion beliefs become available.
    - Confirm/reselect buttons swap in only after the required number of beliefs is selected.
    - Pantheon founding is single-belief-only in both the standalone chooser and the religion-screen pantheon state.
  - Input/lifecycle:
    - Escape closes the popup.
    - The screen is a low-priority popup queued at the current parent, not a full hard modal over everything.
    - `Events.BeliefAdded`, `PantheonFounded`, and `ReligionFounded` refresh the screen, except during the short post-confirm blocking-state window guarded by `m_isConfirmedBeliefs`.
  - Scenario exceptions:
    - `DLC/PolandScenario/UI/ReligionScreen.lua` and `DLC/VikingsScenario/UI/ReligionScreen.lua` each ship their own full `ReligionScreen.lua` copy, including pantheon-selection states (`SelectPantheonBeliefs`, `ConfirmPantheonBeliefs`) and `FOUND_PANTHEON` handling inside the full-screen religion UI rather than the standalone chooser.
    - `DLC/Indonesia_KhmerScenario/UI/Replacements/ReligionScreen_Indonesia_KhmerScenario.lua` is only a thin wrapper around base `ReligionScreen` that overrides `AddLockedBeliefs`; it does not replace the pantheon-founding interaction model.
  - Accessibility-shape implication: this is fundamentally a tabbed multi-state information-and-picker screen, not one flat list. CAI should preserve the state model and expose explicit widgets for tab strip, current page body, religion icon grid, belief lists, and the per-city follower matrix rather than flattening everything into one monolithic reader.

- `GovernorPanel.lua` / `GovernorDetailsPanel.lua` / `GovernorAssignmentChooser.lua` (decompiled/DLC/Expansion1/UI/Additions/ and decompiled/DLC/Expansion2/UI/Additions/):
  - Governors are not part of `GovernmentScreen`. They are a separate popup family opened from `LaunchBar.OnOpenGovernors()` through `LuaEvents.GovernorPanel_Open()` / `_Close()`, tracked by `LaunchBar`'s `isGovernorPanelOpen` flag, and treated as one of the mutually exclusive major popups.
  - There is no base-game governor screen context in `Assets/UI/InGame.xml`; governors are expansion-era content. The screen family consists of:
    - `GovernorPanel`: the main horizontally scrolling governor roster.
    - `GovernorDetailsPanel`: an inline child context declared inside `GovernorPanel.xml` (`LuaContext ID="DetailsPanel"`), used for the promotion tree / biography view.
    - `GovernorAssignmentChooser`: a separate popup used when assigning or reassigning a governor to a city.
  - Main roster layout (`GovernorPanel.xml`):
    - Full-screen tiled governor background with top header `LOC_GOVERNORS_TITLE`.
    - Two summary counters near the top: available governor titles and spent governor titles.
    - One horizontal `ScrollPanel` of tall governor columns (`GovernorInstanceStack`), each about `234x680`.
    - Each standard governor column shows portrait, name plaque, title, turns-to-establish stat, loyalty / identity-pressure stat, a short status block, earned promotions list, available promotions list, and footer buttons for `Details` plus `Assign` or `Appoint`.
    - Assigned governors swap to the "column on" art; unassigned governors stay on the darker "column off" art. Neutralized governors show a large neutralized overlay plus a dimmed fade layer.
  - Secret-society pseudo-governors are integrated into the same roster ahead of normal governors. The code identifies them with `IsCannotAssign(governorDef)` and uses the alternate `SocietyGovernorInstance` art (`Secret_Column_BackgroundTile`, `Secret_NamePlaque`, `SocietyIcon`). They never expose assignment, only details / appoint / promote.
  - Main roster interaction:
    - `Appoint` triggers `PlayerOperations.APPOINT_GOVERNOR`.
    - `Assign` opens `GovernorAssignmentChooser` through `LuaEvents.GovernorAssignmentChooser_RequestAssignment(...)`.
    - `Details` opens `GovernorDetailsPanel` through `LuaEvents.GovernorDetailsPanel_OpenDetails(...)`.
    - The screen auto-opens or refreshes on governor-related notifications (`NOTIFICATION_GOVERNOR_APPOINTMENT_AVAILABLE`, `_OPPORTUNITY_AVAILABLE`, `_PROMOTION_AVAILABLE`, `_IDLE`, and Secret Society level-up).
    - Closing with Escape / close button calls `PlayerRequestClose()`, which marks `localPlayer:GetGovernors():SetTitleConsidered(true)` if the player had not yet considered the title prompt.
  - Details view layout (`GovernorDetailsPanel.xml`):
    - Left profile card: selected portrait, name/title plaque, scrollable biography text, establish-turn / identity-pressure stats, governor status lines, and an assign / reassign / appoint button for normal governors.
    - The biography region is a plain `ScrollPanel` containing `GovernorBioLabel`; `GovernorDetailsPanel.Refresh()` fills it directly from `Locale.Lookup(pGovernorDef.Description)`, so CAI can mirror biography text from the governor definition in row tooltips instead of scraping promotion controls.
    - Right promotion area (`PromotionAnchor`): a large promotion panel with either a 3-column tree for standard governors or a vertical list for secret societies.
    - Bottom button row: `Back` when nothing is queued, `Confirm` when a promotion is currently selected.
  - Standard promotion-tree behavior:
    - Base ability is shown separately at the top.
    - Non-base promotions are positioned by `GovernorPromotions.Column` and `Level`, producing a fixed 3x3 visual tree with prerequisite connector art (`ReqLinesLeft`, `ReqLinesRight`, `ReqLinesDown`).
    - Clicking an earnable promotion only selects it first (`m_SelectedPromotion`); confirming the choice is a second explicit step via the `Confirm` button or Enter key.
    - Already-owned promotions are disabled and shown in a completed visual state; locked promotions are disabled; available promotions stay clickable unless the screen is read-only.
    - Vanilla uses `playerGovernors:CanEarnPromotion(governorHash, promotionHash)` as the individual promotion clickability test. The UI does not separately expose "missing prerequisite" versus "cannot afford a governor title right now"; both collapse into the disabled / locked branch when `CanEarnPromotion` is false.
  - Secret-society promotion behavior:
    - Uses a simple vertical list rather than the 3x3 branch tree.
    - Hidden promotions use `GetPromotionHiddenName()` / `GetPromotionHiddenDescription()` until prerequisites are met.
    - Hidden future promotions are marked with `FireFX_SecretSocietySmoke`.
  - Assignment chooser layout and flow (`GovernorAssignmentChooser.xml` / `.lua`):
    - A left slide-out panel (`AssignmentChooserSlideAnim`) opens over the world.
    - Top panel shows the selected city, the incoming governor summary, and when relevant the outgoing governor summary.
    - Bottom panel is a scrollable list of city rows. Each row mirrors a city-banner card, showing city name, capital marker, current / projected identity pressure, governor icon if one is already present, and establish turns.
    - On open, the chooser activates the Loyalty lens and usually moves the camera to the governor's currently assigned city or to a newly selected city. Closing restores the default lens unless the player is already in `VIEW_MODAL_LENS`.
    - Selecting a city updates the top panel preview only; actual assignment requires pressing `Confirm`.
    - Confirm sends `PlayerOperations.ASSIGN_GOVERNOR`. If the target city already has one of the local player's governors, vanilla shows a yes/no replacement confirmation first.
  - XP1 versus XP2:
    - XP1 and XP2 both ship the full governor panel family under their own DLC folders.
    - The biggest XP2-only behavior difference is read-only gating during World Congress. `GovernorPanel_Expansion2.IsReadOnly()` returns `Game.GetWorldCongress():IsInSession()`, and the XP2 details panel receives that state so appoint / assign / promote affordances disable cleanly during congress.
    - Secret Society support is already present throughout these later governor-panel files (roster art, icon, hidden-promotion smoke, notification hash), so CAI should treat that as part of the modern governor experience whenever the associated content is active.
  - Accessibility-shape implication: this is a three-stage flow, not one flat screen:
    - Stage 1: governor roster across columns.
    - Stage 2: per-governor promotion / biography details.
    - Stage 3: city assignment chooser with world-camera / loyalty-lens context.
    - A good CAI integration should preserve those stages as separate push/pop surfaces, keep normal versus secret-society governors distinct, expose promotion trees structurally, and speak assignment consequences before confirmation instead of flattening everything into one long list.
  - `GovernorAssignmentChooser_CAI.lua` now uses a Pantheon-style CAI overlay for stage 3:
    - the CAI chooser itself is only a `List` of city rows, not a mirrored preview panel
    - row labels speak just city name plus capital marker
    - row tooltips read the live vanilla row controls for current governor, identity-pressure before/after, establish turns, and disabled reasons
    - activating a CAI row drives the live vanilla row button's `DoLeftClick()` instead of calling `OnSelectCity(...)` directly, so vanilla keeps ownership of camera movement, loyalty-lens activation, and preview rebuild
    - the CAI confirmation dialog is populated from the live top preview controls after vanilla selection updates them
    - when the preview's current-governor slot is the vanilla no-governor placeholder, `AddGovernorInstance(..., nil, nil, ..., true)` hides `IdentityPressureContainer` and `TurnsToEstablishIcon`; CAI must honor those hidden states so stale identity-pressure / establish-turn tooltips are not spoken after `LOC_GOVERNOR_ASSIGNMENT_NO_GOVERNOR`
    - confirmation drives the live vanilla `ConfirmButton:DoLeftClick()`; dialog-only reselect/escape is CAI-local because vanilla has no equivalent sub-step control

## Interface Modes

- `InterfaceModeTypes.MOVE_TO` — unit movement mode
- `UI.GetInterfaceMode()` — returns current interface mode
- `UI.SetInterfaceMode(mode)` — changes interface mode

## Unit Promotion Popup

- Vanilla registers `UnitPromotionPopup` as a `WorldPopups` context in base, XP1, and XP2 `InGame.xml`, all pointing to `FileName="UnitPromotionPopup"`. No XP1/XP2 `UnitPromotionPopup.lua/.xml` replacement exists in the decompiled UI mirror; the expansions only replace/wrap `UnitPanel`.
- Opening is driven by the unit panel's promote action. `UnitPanel.GetUnitActionsTable(...)` adds the promote action only when `UnitManager.CanStartCommand(pUnit, UnitCommandTypes.PROMOTE, true, true)` returns a non-empty `UnitCommandResults.PROMOTIONS` list.
- `UnitPanel.ShowPromotionsList(tPromotions)` has two paths:
  - if `GameInfo.Units[unitType].NumRandomChoices > 0`, vanilla shows the compact in-panel `Controls.PromotionPanel` list, with one button per available random promotion choice;
  - otherwise vanilla raises `LuaEvents.UnitPanel_PromoteUnit()`, which opens the standalone `UnitPromotionPopup`.
  - `UnitPromotionPopup.lua` rebuilds a full promotion tree from `GameInfo.UnitPromotions()` filtered by the selected unit's `GameInfo.Units[pUnit:GetUnitType()].PromotionClass`, plus prerequisite rows from `GameInfo.UnitPromotionPrereqs()`. It overlays earned/current promotions, available promotions returned by `CanStartCommand`, and locked future promotions in one tree.
  - Promotion identities are mixed by design: prerequisite relationships use `UnitPromotionType` strings, while `UnitCommandResults.PROMOTIONS`, `UnitExperience:GetPromotions()`, and `UnitCommandTypes.PARAM_PROMOTION_TYPE` use numeric `GameInfo.UnitPromotions` indexes. When CAI builds a local model, relationship sorting must use that local model, not the global/current `m_model`, because `m_model` is not assigned until after `BuildPromotionModel()` returns.
  - `UnitPromotionPrereqs` rows are individual unlock edges, not an all-prerequisites list. Some branches intentionally have reciprocal same-tier rows, such as Heavy Cavalry `Marauding <-> Rout`, so CAI should speak these as `Unlocked by` / `Unlocks` rather than `Prerequisites` / `Leads to`. Keep relationship lists comma-separated for concise scan/readback.
  - `UnitPanel.View(data)` displays already-earned promotions as small `EarnedPromotionInstance` icons in `Controls.EarnedPromotionsStack`. Each icon receives a tooltip containing the promotion name plus `Locale.Lookup(promotion.Desc)` from `data.CurrentPromotions`, so sighted players can inspect earned promotion descriptions from the unit panel even when the full promotion popup is not available.
  - Standalone popup layout (`UnitPromotionPopup.xml`): darkened full-screen backdrop; centered framed panel with close button; header `LOC_HUD_UNIT_CHOOSE_PROMOTION_TEXT`; top-left combat/movement stat icons assembled from live unit values; top-right XP label; scrollable promotion tree. Each node is a 212x106 promotion card containing icon, uppercase promotion name, and truncated description. Completed promotions use `Promotion_ButtonCompleted`; unearned cards use `Promotion_Button`; available cards are enabled, locked/future cards are disabled. Prerequisite connector lines are solid blue when both endpoint promotions are owned, dashed otherwise.
- Standalone interaction: click an enabled promotion card to immediately call `UnitManager.RequestCommand(pUnit, UnitCommandTypes.PROMOTE, { [UnitCommandTypes.PARAM_PROMOTION_TYPE] = ePromotion })`; there is no confirmation step. Escape or the close button closes the popup. It also closes on city selection change, hotseat turn end, and `LuaEvents.UnitPanel_HideUnitPromotion()`.
- Compact random-choice promotion panel layout (`UnitPanel.xml`): a 300x287 HUD frame anchored above the unit panel action area, with header `LOC_HUD_UNIT_CHOOSE_PROMOTION_TEXT`, vertical scroll list, and small close button. Each row is a rectangular button with promotion tier roman numeral, name, and description. Clicking a row immediately requests the same `UnitCommandTypes.PROMOTE` command.
- The compact random-choice promotion panel is not a tree: it only lists the available promotion ids returned by `UnitManager.CanStartCommand(... PROMOTE ...)`, does not build `UnitPromotionPrereqs`, and has no prerequisite / unlock connector lines. Vanilla row visuals are a gray 32x32 `PromotionsSmall` badge area with a roman-numeral tier label (`I` through `V`) over it, followed by localized promotion name and localized description text.
- `UnitPanel_CAI.lua` wraps `ShowPromotionsList(tPromotions)` and calls vanilla first. If vanilla actually shows `Controls.PromotionPanel` for a `NumRandomChoices > 0` unit, CAI pushes a transient list mirrored from the live vanilla `Controls.PromotionList` rows. Each CAI row reads `PromotionTier:GetText()` plus `PromotionName:GetText()` as the label, reads `PromotionDescription:GetText()` as the tooltip, and activates with `PromotionSlot:DoLeftClick()` so the vanilla registered left-click callback remains the command path. `HidePromotionPanel()` and unit selection changes remove the CAI list.
- The veteran rename panel is also UnitPanel-owned. `ShowNameUnitPanel()` shows `Controls.VeteranNamePanel` and calls `RandomizeName()`. `RandomizeName()` writes the generated localized name into `Controls.VeteranNameField` and stores the command payload in `m_FullVeteranName`. Manual edits must call `OnEditCustomVeteranName()` after writing `VeteranNameField`, because `OnConfirmVeteranName()` reads `m_FullVeteranName` before requesting `UnitCommandTypes.NAME_UNIT`. `UnitPanel_CAI.lua` mirrors this panel with a transient CAI panel: edit box text is bound to `VeteranNameField` through `SetValueSetter`, Enter on the `AlwaysEdit` edit box bubbles to a panel binding that clicks `ConfirmVeteranName`, the `OnConfirmVeteranName` wrapper commits the CAI edit before vanilla reads `m_FullVeteranName`, randomize clicks `RandomNameButton:DoLeftClick()` and resyncs from the vanilla field, Escape clicks `VeteranNamingCancelButton`, and `HideNameUnitPanel()` is the only close/remove path for the CAI panel.
- Confirmed standard-rules trigger: Gathering Storm Rock Bands (`UNIT_ROCK_BAND`) define `InitialLevel="2"`, `NumRandomChoices="3"`, and `PromotionClass="PROMOTION_CLASS_ROCK_BAND"` in `DLC/Expansion2/Data/Expansion2_Units.xml`. Buying a Rock Band and opening its initial promotion action should show the compact in-panel list instead of the standalone tree.
- XP1 `UnitPanel_Expansion1.lua` is only `include("UnitPanel")`. XP2 `UnitPanel_Expansion2.lua` includes XP1 and adds Rock Band / adjacent-build / railroad-upgrade behavior, but does not alter the promotion popup or promote command flow.

## Espionage UI

- Vanilla registers four main espionage UI contexts from `InGame.xml`: `EspionageOverview`, `EspionageChooser`, `EspionagePopup`, and `EspionageEscape`. Shared behavior lives in `EspionageSupport.lua`; `EspionageViewManager.lua` only stores the current city being viewed for espionage-side-panel purposes.
- DLC replacements found in XP1 and XP2 are only `EspionageChooser_Expansion1.lua` and `EspionageOverview_Expansion1.lua`; both are also shipped under `DLC/Expansion2/UI/Replacements/` with the same XP1 filename. No DLC replacement was found for `EspionagePopup.lua/.xml`, `EspionageEscape.lua/.xml`, `EspionageSupport.lua`, or the XML layouts for chooser/overview.
- `EspionageChooser` is a left slide-out chooser with two modes:
  - `SPY_TRAVEL_TO_CITY`: destination picker. Rows are city-banner cards with city name/capital marker, total travel plus establish time, district icons, and district-scroll arrows when the district strip is longer than the visible slots. Selecting a row moves the camera to the city, shows a top selected-city banner, shows a non-clickable possible-missions preview, and exposes `Confirm Placement` / `Cancel`. Confirm sends `UnitOperationTypes.SPY_TRAVEL_NEW_CITY` with `PARAM_X/PARAM_Y`, unless the selected city is the local city the spy already occupies, in which case vanilla switches to mission-chooser mode for counterspy selection.
  - Same-current-city destination rows still display `UnitManager.GetTravelTime(m_spy, city)` / `GetEstablishInCityTime(...)` in vanilla `AddDestination` and `UpdateCityBanner`. The current-city special case is not applied until `OnConfirmPlacement()`, so the row can misleadingly say travel time even though confirming it opens counterspy mission selection instead of moving the spy.
  - `SPY_CHOOSE_MISSION`: mission picker for the city where the spy currently sits. Enemy-city offensive missions are rows with mission icon, localized operation name, operation detail text, target district, turn count, and success chance. Disabled offensive missions are still listed when `CanStartOperation(..., returnResults=true)` provides failure reasons, with those reasons shown in red. Local-player cities list counterspy target rows by district and activate immediately with `SPY_COUNTERSPY`.
- In base rules, `EspionageChooser.RefreshDestinationList()` adds revealed local-player cities plus revealed non-minor player cities. XP1/XP2 override that function to skip Free Cities explicitly while preserving the same broad destination shape. `EspionageOverview_Expansion1.RefreshCityActivity()` calls the base city-activity refresh and then appends city-state cities.
- `EspionagePopup` is a centered parchment popup. In mission briefing state it shows mission title/icon, objective, duration, possible outcome percentages, and bottom `Accept Mission` / `Cancel` buttons. Accept calls `UnitManager.RequestOperation(m_spy, m_operation.Hash)`; the operation target is already established by the chooser selection path. In abort state it shows current mission details, turns remaining, `Abort Mission` / `Cancel`, and abort calls `UnitManager.RequestCommand(m_spy, UnitCommandTypes.CANCEL)`. Listening Post and Counterspy aborts skip the popup and cancel immediately. In mission-completed state it shows success/failure outcome, rewards such as promotion-ready and loot, consequences such as relationship damage or killed/captured agent, and may show `Renew Mission` for Listening Post or Counterspy if the mission can still be started at the target.
- `EspionagePopup.xml` control inventory:
  - Primary live text/detail controls: `MissionTitle`, `MissionObjectiveLabel`, `MissionDurationLabel`, `MissionOutcomeLabel`, `MissionOutcomeDescription`, `SpyPromotionLabel`, `SpyPromotionDescription`, `SpyLootRewardLabel`, `SpyLootRewardDescription`, `RelationshipDamageTitle`, `RelationshipDamageDescription`, `LostAgentTitle`, `LostAgentDescription`, `RenewableMissionDetails`, `MissionDistrictName`, `TurnsToCompleteLabel`, `ProbabilityLabel`.
  - Visibility containers: `MissionObjectiveContainer`, `MissionOutcomeContainer`, `MissionRewardsContainer`, `SpyLootGrid`, `MissionConsequencesContainer`, `LostAgentGrid`, `MissionDurationContainer`, `PossibleOutcomesContainer`, `RenewableMissionContainer`, `ProbabilityGrid`.
  - Instance-driven possible-outcome rows are created under `OutcomeStack` from `OutcomeLabelInstance` (`OutcomeLabel`) and `OutcomePercentInstance` (`Top`, `OutcomePercentNumber`, `OutcomePercentLabel`).
  - User-action controls: `AcceptButton`, `RenewButton`, `AbortButton`, `CancelButton`, `MissionSucceedButton`, `MissionFailureButton`. There is no close button; Escape calls `Close()`.
- `EspionageSupport.RefreshMissionStats(...)` is the shared source for displayed mission stats: `UnitManager.GetTimeToComplete(...)`, `UnitManager.GetResultProbability(...)` summed across `ESPIONAGE_SUCCESS_UNDETECTED` and `ESPIONAGE_SUCCESS_MUST_ESCAPE`, color-coded probability thresholds, and target district resolution from operation result plots or city center fallback.
- `EspionageChooser_CAI.lua` must not pair recomputed CAI missions with `Controls.MissionStack:GetChildren()[i]`. Vanilla mission rows are created through `AddCounterspyOperation`, `AddAvailableOffensiveOperation`, and `AddDisabledOffensiveOperation`; CAI captures rows from those wrappers and stores the live mission button. Activation should call the captured button's `DoLeftClick()` so vanilla's registered counterspy/offensive/disabled callbacks remain the source of truth.
- `EspionageChooser_CAI.lua` should treat `Refresh()` as the mode synchronization choke point. After vanilla refreshes, read live vanilla visibility (`MissionPanel` visible means mission mode; `DestinationPanel` visible means destination mode, with interface mode only as fallback), rebuild CAI widgets, and move focus only when that derived mode changes. Do not special-case `OnConfirmPlacement()` for same-city spy assignment; vanilla already switches from destination mode to mission mode inside that flow.
- Keep destination and mission navigation as separate CAI widgets. The destination view is a `Tree` of city rows with read-only possible-mission children. The mission view is a sibling `List` of actionable mission rows. Their hidden predicates are driven by the derived vanilla mode, so refreshes and edge-case mode switches cannot leave mission rows mixed into the destination tree. The parent panel label must also be derived from the same mode state, so the screen context changes from destination chooser text to mission chooser text when focus moves across a vanilla mode switch.
- `EspionageOverview` is a right-side partial screen opened through `PartialScreenHooks_OpenEspionage`. It has three tabs:
  - Operatives: local spies grouped visually as idle/awaiting assignment, active missions with progress bar/turns remaining/details/target district, captured spies with capturing civilization and `Ask for Trade`, and off-map travelling spies with travel progress/destination.
  - City Activity: revealed cities with a clickable city banner, complete non-wonder district icons, source-boost icon when active, and an overlaid spy marker on districts where one of the local player's spies is active. Clicking a city banner looks at the city. XP1/XP2 append city-states here.
  - Mission History: captured enemy operatives that can be traded for, plus up to 10 recent missions with spy name/rank, mission name, turns since completion, success/failure status, killed/captured status, outcome description, mission icon, and target district icon. Trade buttons create a locked `DealItemTypes.CAPTIVE` and request a diplomacy deal session.
- `EspionageEscape` is a small modal opened from notification activation through `LuaEvents.NotificationPanel_OpenEspionageEscape(...)`. It shows city, agent, loot, pursuer, and four escape-route buttons. Buttons 1-3 are disabled if the target district is not present in the city; each enabled button shows turn count and submits `PlayerOperations.SET_ESCAPE_ROUTE` with `PARAM_DISTRICT_TYPE`. Escape closes without choosing.
- `EspionageEscape.lua` registers `LuaEvents.NotificationPanel_OpenEspionageEscape.Add(OnOpen)` inside `Initialize()`, so a CAI replacement that wraps `OnOpen` after `include("EspionageEscape")` must remove the original listener and add the wrapped function. The route button callbacks can remain vanilla; CAI activation should use `ButtonN:DoLeftClick()`.
- `EspionageEscape.xml` control inventory:
  - Detail controls: `PanelHeader`, `CityHeader`, `AgentLabel`, `AgentDetails`, `LootLabel`, `LootDetails`, `PursuitLabel`, `PursuitDetails`, `ChoiceHeader`.
  - Route controls: `Button1`/`Label1`, `Button2`/`Label2`, `Button3`/`Label3`, `Button4`/`Label4`.
  - Lifecycle/animation controls: `PopupGenericBlocker`, `PopupAlphaIn`, `PopupSlideIn`, `PopupDialog`, `EscapeWindow`.
- Accessibility-shape implication: treat espionage as four surfaces, not one monolith. The chooser should be the highest-priority gameplay target because it blocks spy orders. Mirror destination rows, mission rows, and mission briefing with CAI widgets that activate live vanilla controls/functions. The overview can be a tabbed read/action panel. The completion/abort popup can be a dialog-style panel with read-only detail sections plus live buttons. The escape popup can be a small dialog with one row per route, disabled states and reasons preserved.

## City Overview Panel

- Vanilla city details are split across two UI contexts:
  - `CityPanel.lua/.xml` is the compact selected-city HUD panel anchored at the bottom right. It shows city name, civ icon/health rings, buildings-or-loyalty summary, religion followers, amenities, housing, growth meter, production card/meter, per-turn yield focus checkboxes, next/previous city buttons, and checkboxes for overview, manage citizens, purchase tile, change production, gold purchase, and faith purchase.
  - `CityPanelOverview.lua/.xml` is the left slide-out "City Details" panel. `CityPanel.Initialize()` raises `LuaEvents.CityPanel_OpenOverview()` so the context is loaded at startup, and `CityPanelOverview` stays hidden until opened.
- Base overview visuals:
  - parchment/blue left panel with city-name header, close button, rename button/edit box for owned cities, a vertical tab/icon rail, and a scrollable content area.
  - Base tabs are Citizens/Health, Buildings, and Religion when `CAPABILITY_CITY_HUD_RELIGION_TAB` is available.
  - Citizens/Health tab shows three stacked subpanels: amenities mood and effects, housing status and source breakdown, and citizen growth math.
  - Buildings tab shows district count, built districts with nested built buildings, wonder list or no-wonders message, and trading-post list or no-trading-posts message. District/building/wonder rows have tooltips from `ToolTipHelper`.
  - Religion tab shows pantheon belief, dominant religion follower count, dominant-religion beliefs with descriptions, other religions in the city, and a color-key list for founded religions. Selecting the tab activates the Religion lens.
  - Production details exist in the same base overview file: `ViewPanelProductionNow` reads current production, unit stats, and description; `ViewPanelQueue` builds numbered queue entries. These panels are hidden in `HideAll()` but are still part of the context.
- Base overview interaction:
  - `ToggleOverviewTab(tabButton)` opens the panel if needed, selects the tab if different, or closes the panel if the same tab is selected again for the same city.
  - `CityPanelOverview` listens to `LuaEvents.CityPanel_ToggleOverviewCitizens`, `CityPanel_ToggleOverviewBuildings`, and `CityPanel_ToggleOverviewReligion`.
  - Close button, Escape, or right-click closes the overview, resets the active lens to Default, and sets interface mode to `SELECTION`.
  - Base tab selection sets `CityDetails` lens for local cities and `EnemyCityDetails` plus `LuaEvents.ShowEnemyCityDetails(owner, cityId)` for enemy/espionage city views. Religion tab sets `Religion`.
  - The compact `CityPanel` summary stat buttons call older event names (`CityPanel_ShowBreakdownTab`, `CityPanel_ShowReligionTab`, `CityPanel_ShowAmenitiesTab`, `CityPanel_ShowHousingTab`, `CityPanel_ShowCitizensTab`), while the overview file registers the `CityPanel_ToggleOverview*` events. Existing CAI code already uses the registered `CityPanel_ToggleOverview*` family for direct tab hotkeys.
- Rise and Fall / XP1:
  - `CityPanel_Expansion1.lua` includes base `CityPanel` and changes the compact first stat row from Buildings to Loyalty, using `city:GetCulturalIdentity():GetLoyalty()`. It also deselects a selected city when `Events.CityLoyaltyChanged` fires for that city.
  - `CityPanelOverview_Expansion1.lua` includes base overview, overrides growth math for the XP1 rule path, adds governor amenity loss to the amenities breakdown, loads `CityPanelCulture` into `PanelDynamicTab`, and adds a Loyalty/Governor dynamic tab with icon `ICON_STAT_GOVERNOR`.
  - Selecting the XP1 dynamic tab shows `CityPanelCulture`, activates the Loyalty lens, and raises `LuaEvents.CityPanelTabRefresh()`.
  - `CityPanelCulture.lua/.xml` shows loyalty current/max/status, loyalty pressure tooltip/icon, potential transfer owner, detailed identity-source breakdown, total loyalty-per-turn line, loyalty effects, advisor text, diplomatic influence by civilization, and assigned governor identity/effects/establishment state. It listens to `CityPanelTabRefresh`, governor events, city selection, city loyalty changes, and enemy-city overview.
- Gathering Storm / XP2:
  - `CityPanel_Expansion2.lua` includes XP1 and overrides `DisplayGrowthTile()` so World Congress resolutions can suppress culture border growth display.
  - `CityPanelOverview_Expansion2.lua` includes XP1 overview and, when `CAPABILITY_LENS_POWER` exists, loads `CityPanelPower` into `PanelDynamicTab`, adds a Power dynamic tab with icon `ICON_STAT_POWER`, listens to `LuaEvents.CityPanel_ToggleOverviewPower`, activates the Power lens, and raises `LuaEvents.CityPanelTabRefresh()`.
  - `CityPanelPower.lua/.xml` shows consumed/current power, required power, power status and description, consumed/required/generated breakdown lines from `city:GetPower()`, advisor text, and a power-lens key. It listens to `CityPanelTabRefresh`, city selection, and enemy-city overview.
- Accessibility-shape implication:
  - Treat CityPanel compact actions and CityPanelOverview details as separate but linked surfaces. The compact city panel should continue to expose fast summary buckets and action hotkeys; the overview should get its own new-framework CAI mirror that follows vanilla open/close/tab/lens behavior.
  - Best first mirror is a `Panel` containing a `TabControl` with pages for Citizens, Buildings, Religion, XP1 Loyalty/Governor, and XP2 Power. Each page should be rebuilt from live vanilla city data and/or the same API calls used by the vanilla panel, with `FocusKey` rows and manager capture/restore.
  - Buildings should be a `Tree`: districts as expandable nodes, buildings as children, plus separate Wonder and Trading Post groups. Religion and Loyalty can also be trees/lists because most content is read-only structured rows. Power is a list grouped into status, consumed, required, generated, and lens key. Citizens should be grouped sections for amenities, housing, and growth math.
  - Activation should preserve vanilla. Tab activation should call the vanilla `LuaEvents.CityPanel_ToggleOverview*` event or live tab button path, not only swap CAI pages, so lenses and close-on-same-tab behavior remain in sync. Close should follow vanilla close/Escape rather than popping CAI only. Rename should mirror the live edit box or call the same `CityCommandTypes.NAME_CITY` path after committing user text.
  - Prefer live control text/tooltips when vanilla rows are visible, especially district/building/wonder tooltips, religion belief descriptions, loyalty/power status labels, and advisor text. Where vanilla content is built from data without stable controls, use the same APIs documented above and localized vanilla loc keys.

## Frontend Multiplayer UI

- Current `MainMenu.lua` exposes multiplayer through the main-menu submenu (`OnMultiPlayer -> ToggleOption`) rather than the older standalone `MultiplayerSelect` popup. The submenu rows are Play By Cloud, Internet, Unified PC/Crossplay, LAN, Hotseat, and DLC scenario matchmaking rows for Civ Royale and Pirates when available. The legacy `MultiplayerSelect.lua/.xml` still exists and offers Standard -> Internet/LAN plus Hotseat, but it is not the active option-table path.
- `LobbyTypes.lua` maps the frontend mode string to engine server/game/lobby types: Internet uses `SERVER_TYPE_INTERNET` / `GameModeTypes.INTERNET` / `LOBBY_INTERNET`; LAN uses `SERVER_TYPE_LAN`; Hotseat uses `SERVER_TYPE_HOTSEAT`; Play By Cloud uses `SERVER_TYPE_FIRAXIS_CLOUD`; Crossplay uses `SERVER_TYPE_CROSSPLAY`.
- Selecting Internet, LAN, Play By Cloud, or Crossplay raises `Lobby.lua`. Hotseat raises `HostGame.lua` directly. Civ Royale and Pirates use intro popups when not seen, then call matchmaking and show `JoiningRoom.lua`.
- `Lobby.lua/.xml` is a full-screen shell game browser with logo/header, Back and Refresh/Stop Refresh buttons, optional Play By Cloud shell tabs (`My Games`, `Completed Games` with unseen-complete variant), optional Join Code button, a sortable game list, bottom buttons (`Join Game` / `Play Game`, `Load Game`, `Create Game`), and a collapsible friends panel.
- Lobby listing rows are generated by `ListingButtonInstance` and have columns for game name, ruleset, map, game speed, official/community content icons, and player count. Rows show faded/version-mismatch coloring and row tooltips for started games, loading saves, version mismatch, current PBC turn, unseen completed games, turn owner, players, and mod ownership/download status. A row click selects it; double-click selects and joins. Bottom Join is disabled for version mismatch and changes to `Play Game` for personal Play By Cloud games.
- Lobby column headers are sort buttons (`SortbyName`, `SortbyRuleSet`, `SortbyMapName`, `SortbyGameSpeed`, `SortbyModsHosted`, `SortbyPlayers`). Play By Cloud uses offset scrolling and backend browse modes, so the UI does not locally resort those offset-scrolled results. Reaching scroll ends may request the previous/next PBC page.
- Lobby actions preserve engine flow: refresh calls `Matchmaking.RefreshGameList()`, Create Game raises `LuaEvents.Lobby_RaiseHostGame()`, Join calls `Network.JoinGame(serverID)`, Join Code opens a `PopupDialog` edit box then calls `Network.JoinGameByJoinCode(code)`, Load Game opens `LoadGameMenu` after setting server type/game mode, and Back closes dialogs, calls `Network.LeaveGame()`, and dequeues the lobby.
- `HostGame.lua/.xml` is the multiplayer setup screen. It is a full-screen shell form with the Civ VI logo at the top, a centered `LOC_MULTIPLAYER_HOST_GAME` header, Back on the header right, Restore Default on the header left, an Additional Content button above the setup panel, shell tabs, a large bordered scroll panel, and a bottom button row for Load Game, Load Config, Save Config, and Confirm Settings.
- The scroll panel is divided into four visible parameter sections backed by separate stacks: Map Options (`PrimaryParametersStack`, for `BasicGameOptions`, `GameOptions`, `BasicMapOptions`, and `MapOptions`), Game Modes (`GameModeParameterStack`), Victory Conditions (`VictoryParameterStack`), and Advanced Options (`SecondaryParametersStack`). `GameSetupLogic.lua` sorts children after each refresh with `o.Utility_SortFunction(...)` and hides empty parameter stacks/headers when possible. In HostGame XML the Game Modes header has an ID, but Victory/Advanced section headers are anonymous; accessible grouping should therefore use the known stack order/loc keys rather than only header IDs.
- Host setup uses `GameSetupLogic.lua` / `PlayerSetupLogic.lua` drivers for dynamic setup parameters. The stable widget vocabulary is boolean checkbox, text/number edit box, integer range slider with number display, pulldown, and button-driven picker. Boolean rows click to toggle and broadcast config. Edit boxes commit text/int/uint values and broadcast config. Sliders broadcast on step change and show the current number in `NumberDisplay`. Pulldowns rebuild entries from `parameter.Values`; the selected button text is the current value name and the selected button tooltip is the value description when available. Generic multi-value arrays are disabled pulldowns, but HostGame overrides array parameters into picker buttons where possible.
- HostGame overrides specific setup drivers: `CityStates` opens `CityStatePicker`; `LeaderPool1` / `LeaderPool2` open `LeaderPicker`; other array parameters open `MultiSelectWindow`. These picker buttons show summary text such as Nothing, Everything, or Custom count according to `parameter.UxHint == "InvertSelection"`, keep the parameter name in `StringName`, and use `parameter.Description` as the tooltip. Picker results return through `LuaEvents.*_SetParameterValues` / `CityStatePicker_SetParameterValue`, update `g_GameParameters`, and call `Network.BroadcastGameConfig()`.
- Sighted picker flow: `MultiSelectWindow` shows a title, description, selectable item checklist with icon/name, focused-item detail pane, Select All, Select None, Confirm, and Close/Escape. `CityStatePicker` is similar but also has a city-state count slider/number, a sort pulldown, count warning, and disables Confirm until enough city-states are selected. `LeaderPicker` is similar but shows leader/civ ability details for the focused row and has a preset pulldown for All, None, and No Wins. Clicking a row or its checkbox toggles selection; Confirm writes selected values and closes; Escape/Close cancels. CityStatePicker Close also restores the original city-state count.
- HostGame lifecycle/actions: `OnRaiseHostGame()` defaults the game config for the current multiplayer lobby mode, clears `RULESET`, and queues the screen. `OnEnsureHostGame()` queues without defaulting for an existing session. `OnShow()` rebuilds player parameters headlessly, refreshes setup parameters, hides Additional Content and Confirm when already in a network session, hides Load Game unless Hotseat and not in session, and realizes shell tabs. When in a session, shell tabs are Game Setup plus Staging Room, and the Staging Room tab raises `LuaEvents.HostGame_ShowStagingRoom()`.
- HostGame exit/confirm behavior: Back/Escape raise `LuaEvents.Multiplayer_ExitShell`; if already in a network session, Back first shows a `PopupDialog` quit warning and `CheckLeaveGame()` may call `Network.LeaveGame()` before dequeueing. Confirm ensures `GAME_NAME` is non-empty, warns with `LOC_CITY_STATE_PICKER_TOO_FEW_WARNING` if the selected/excluded city-states leave fewer available city-states than `CityStateCount`, and then calls `Network.HostGame(serverType)` through `HostGame(serverType)`.
- `UI/frontEnd/Multiplayer/HostGame.lua` CAI frontend replacement is implemented as a full vanilla-copy override with an accessibility block before `Initialize()`. The CAI shape deliberately omits shell tabs and exposes one panel with a setup-options list plus sibling action buttons. The list contains submenus for Map Options, Game Modes, Victory Conditions, and Advanced Options, populated from live `g_GameParameters.Parameters` and grouped by the same parameter groups as the vanilla stacks. Game name is not a separate XML edit box; it is the dynamic text setup parameter (`GAME_NAME`) and appears in the options list as an `EditBox`. Checkbox rows seed state from the live vanilla checkbox when available with `SetChecked(value, true)` and use `SetValueSetter(...)` to click the live vanilla checkbox only when CAI's requested value differs, preserving the vanilla toggle/broadcast path without the old `value_changed` inversion pattern. Array rows click the live picker button or raise the vanilla CityStatePicker/LeaderPicker/MultiSelectWindow fallback; sliders, dropdowns, and edit boxes write through `g_GameParameters:SetParameterValue(...)` and broadcast config. Action buttons click live Load Game, Load Config, Save Config, Restore Default, Additional Content, and Confirm Settings controls; Staging Room is exposed as an action only during an existing network session and raises `LuaEvents.HostGame_ShowStagingRoom()`.
- `JoiningRoom.lua/.xml` is a simple interstitial for joining, matchmaking, content configuration, and mod-download progress. Visually it is a shell background box with a centered shell window, header `LOC_MULTIPLAYER_JOINING_ROOM_TITLE`, one centered `JoiningLabel`, and a bottom-centered `CancelButton`. There is no game list, player list, chat, ready button, or choice set on this screen.
- `JoiningRoom` sighted interaction is minimal: click `Cancel` or press Escape to call `HandleExitRequest()`, which runs `Network.LeaveGame()` and dequeues the popup. Everything else is passive status feedback driven by network/content events.
- `JoiningRoom` status text changes: on show it says matchmaking (`LOC_MULTIPLAYER_MATCHMAKING`) when `Network.IsMatchMaking()` is true, otherwise joining room (`LOC_MULTIPLAYER_JOINING_ROOM`); `MultiplayerJoinRoomComplete` may change remote clients to joining host (`LOC_MULTIPLAYER_JOINING_HOST`); `MultiplayerJoinGameComplete` changes to configuring content (`LOC_MULTIPLAYER_CONFIGURING_CONTENT`) while waiting for content configure; `ConnectedToNetSessionHost` says connecting to players (`LOC_MULTIPLAYER_CONNECTING_TO_PLAYERS`); local `ModStatusUpdated` while downloading mods shows `LOC_MODS_SUBSCRIPTION_DOWNLOAD_PENDING` plus `[Icon_AdditionalContent]remaining/required`.
- `JoiningRoom` transitions to `StagingRoom` only after `Events.MultiplayerJoinGameComplete` and, for remote clients, successful `Events.FinishedGameplayContentConfigure`. The transition raises `LuaEvents.JoiningRoom_ShowStagingRoom()` before dequeuing the popup, so `StagingRoom` can queue itself without exposing the lobby beneath for a frame.
- `JoiningRoom` failure/abandon paths raise `LuaEvents.MultiplayerPopup(...)`, call `Network.LeaveGame()`, and dequeue the popup. Covered failures include room full, game started, too many matches, generic join failed, matchmaking failed, kicked, host lost/refused, no room, version mismatch, mod error, missing mod, and match deleted. Matchmaking mode ignores join-room-failed/abandoned events so matchmaking can continue searching.
- `UI/frontEnd/Multiplayer/JoiningRoom.lua` CAI frontend replacement is implemented as a full vanilla-copy override with an accessibility block before `Initialize()`. It builds a status `StaticText` bound to live `Controls.JoiningLabel` and a Cancel `Button` that clicks the live vanilla `CancelButton` or falls back to `HandleExitRequest()`, then assembles them with `mgr.WidgetHelpers.MakeGeneralDialog(titleFn, buttons, contentRows, defaultIndex)` like other CAI dialogs. The status line has no tooltip; it speaks from its label only. The dialog opens focused on the status text so the initial status is spoken by normal focus speech. Status-changing handlers (`OnJoinRoomComplete`, `OnJoinGameComplete`, `OnModStatusUpdated`, and `OnConnectedToNetSessionHost`) announce the status widget only when the live label differs from the previous spoken status. Exit/transition/failure/invite paths remove the CAI dialog before vanilla dequeues the context or raises follow-up UI. The replacement also installs an extended input handler so the UI manager receives frontend dialog input while Escape keeps the vanilla leave-session behavior.
- `StagingRoom.lua/.xml` is the main player lobby. The top has Back, optional Play By Cloud End Game/Quit Game buttons, title, and Game Setup/Staging Room shell tabs. The primary panel is a table-like player list with headers for Players, Team, Civ/Leader, Difficulty, Ready, and Kick. The lower right is Chat; the lower left is either Game Summary or Friends, selected by tabs.
- Staging player rows expose slot type/player identity, team pulldown, color pulldown, leader/civ pulldown with leader/civ icons and warning icon for color conflicts, difficulty pulldown, ready status, kick button, add-player button for the first closed slot when allowed, and hotseat edit button. Slot type options include open/closed/AI/human-required behavior plus swap options in non-hotseat, non-PBC, non-matchmaking sessions when allowed.
- Staging row data is not all readable from visible button text. The leader selector is a split leader/civ pulldown created by `SetupSplitLeaderPulldown(...)`; the selected spoken label that best matches Advanced Setup is `leader name, civilization name`, and the durable tooltip source is the same `GetPlayerInfo(...)`-driven leader/civ ability build used in `AdvancedSetup.lua` (`BuildLeaderTooltip`). Team and color selected states are largely icon-only in StagingRoom, so accessibility should derive them from live player state rather than `GetText()`: team from `PlayerConfigurations[playerID]:GetTeam()` plus the launched-game single-member-team-to-None special case, and color from `PlayerColorAlternate` plus `UI.GetPlayerColorValues(...)`.
- Staging color selection is not a normal parameter-values pulldown. Vanilla manually rebuilds `ColorPullDown` entries inside `UpdatePlayerEntry()` by iterating alternates `0..3`, checking `UI.GetPlayerColorValues(playerColor, j)`, setting `m_teamColors[playerID]` for collision checks, and writing `parameters:SetParameterValue(parameters.Parameters["PlayerColorAlternate"], j)`. Accessibility wrappers should mirror that manual option build instead of trusting `PlayerColorAlternate.Values`.
- Staging team pulldowns are also rebuilt manually by `SetupTeamPulldown(...)`: always add `None`, append existing non-`NO_TEAM` teams from `GetTeamCounts(teamCounts)`, then append one empty team slot with the first unused numeric ID so players can create a new team.
- Staging permissions are live: hosts can modify non-human slots and kick remote humans; players can modify themselves until ready; ready players lock their slot-type and player-value controls; in-progress games hide or disable many setup controls; matchmade games prevent slot edits; hotseat allows broader local changes and hides network-only ready/chat/kick behavior.
- Staging ready/start area is a large central banner/check button. Network games use a ready checkbox when not counting down, and a numbered launch/ready/wait countdown button during countdown. Hotseat uses it as Start Game. The Start label explains blockers such as not enough players, invalid teams, map-size slot errors, mod downloads, duplicate leaders, unfilled required humans, Play By Cloud remote-ready restrictions, or player parameter errors.
- Hotseat enters through `MainMenu.OnHotSeat()`, which sets `MPLobbyTypes.HOTSEAT` and raises `HostGame`; it does not go through the lobby browser. `HostGame` is still the same setup form, but `Load Game` is shown only for Hotseat when not already in session. After `Network.HostGame(serverType)`, the same `StagingRoom` context is reused with hotseat-specific visibility and validation.
- Hotseat staging differs from network staging mostly by hiding network surfaces and widening local slot editing. `InitializeReadyUI()` hides the ready column and countdown art, `ShowHideReadyButtons()` always shows the big `ReadyButton` container instead of the ready checkbox, `ShowHideChatPanel()` hides chat entirely, `RealizeInfoTabs()` omits the Friends tab, Kick is always hidden, and `PopulateSlotTypePulldown()` allows the hotseat-only `Human` slot type while suppressing swap.
- Hotseat player names are auto-seeded from `LOC_HOTSEAT_DEFAULT_PLAYER_NAME`, then renumbered by `UpdateAllDefaultPlayerNames()` for untouched default-name humans. Active human rows swap their normal player-card control for `HotseatEditButton`, which opens `EditHotseatPlayer`.
- Hotseat launch validation is split awkwardly. `UpdateReadyButton_Hotseat()` computes banner text and disabled state from cached `g_hotseatNumHumanPlayers`, `g_hotseatNumAIPlayers`, team validity, map-size validity, and duplicate-leader checks. But `OnReadyButton()` still calls `Network.LaunchGame()` unconditionally whenever `GameConfiguration.IsHotseat()` is true. So the button text is meant to be different in hotseat mode, but it is only advisory UI; if the cached blocker state goes stale or the button remains clickable, the click path itself does not revalidate before launching.
- `g_hotseatNumHumanPlayers` and `g_hotseatNumAIPlayers` are refreshed inside `UpdatePlayerEntry_Hotseat()` rather than at click time. That makes a stale hotseat blocker label/tooltip plausible after slot edits or rebuild timing: the Start banner can lag behind the actual launchable state even though the click path launches immediately.
- Vanilla staging-room launch-blocker hints appear in three distinct places:
  - the centered start banner (`StartLabel`) plus ready control tooltips (`ReadyButton`, `ReadyCheck`, and the local row `ReadyImage`) show the current global blocker or countdown state. For players-connecting and mods-not-ready blockers, the tooltip is expanded with one line per affected player name.
  - each player row's right-side `StatusLabel` shows per-slot readiness or slot-specific problems such as mod download state, invalid-for-map-size, empty human-required slot, unsupported player-count warning, and any `GetPlayerParameterError(playerID)` reason appended in red. Some of those rows also carry a more explicit tooltip (`LOC_INVALID_SLOT_MAP_SIZE_TT`, `LOC_INVALID_SLOT_HUMAN_REQUIRED_TT`, unsupported tooltip text).
  - individual setup selectors can also carry inline invalid markers: the leader/civ pulldown's selected caption and dropdown entries append `value.InvalidReason` in red when a choice is invalid, and generic game-setup parameter controls prepend `parameter.InvalidReason` to the control tooltip.
- Vanilla staging-room parameter-error gating is two-layered: `UpdateReadyButton()` surfaces the first game/player parameter blocker globally by repainting `StartLabel` red and disabling the ready controls, while `UpdatePlayerEntry()` also appends the specific player-parameter error text onto the affected row's `StatusLabel`. This means the player can usually see both the global "cannot start" state and which row/selector caused it.
- Slot removal in vanilla staging is state-based, not structural. The slot pulldown supports `Open`, `AI`, `Closed`, hotseat-only `Human`, and `Swap`; `OnAddPlayer()` only reopens the first closed slot. There is no dedicated "delete/remove slot" action in `StagingRoom.lua`. The only way slots disappear entirely from the room is indirectly through `g_currentMaxPlayers` / map-size changes (`MapConfiguration.GetMaxMajorPlayers()` and related events), which makes higher player IDs non-displayable or invalid for the current map size.
- Vanilla kick-button visibility is narrower than simple slot editability: `UpdatePlayerEntry()` shows Kick only when the local player is the game host, the target slot status is `SS_TAKEN` or `SS_OBSERVER`, the target is not the local player, and the session is not hotseat. Inactive/open/closed/AI rows hide Kick even if other slot controls remain visible.
- Vanilla slot-type pulldowns explicitly disable when they have zero real options (`pullDown.ItemCount < 1`), even before the broader ready/permissions disable pass runs. Any CAI mirror that keeps a placeholder entry for accessibility should still disable the dropdown itself when there are no real slot actions available.
- Staging chat is hidden for Hotseat, Play By Cloud, or when chat is unavailable. Otherwise it has a target pulldown and edit box; committing the box sends chat. `/help` is handled entirely client-side by `ParseInputChatString(...)` returning `printHelp=true`; vanilla then calls `ChatPrintHelp(...)`, which writes localized help directly to the visible chat stack without sending network chat or calling `OnChat(...)`. `ResetChat()` similarly calls `ChatPrintHelpHint(...)` to print the localized command-help hint. Friends/invite controls use `Network.GetFriends()` helpers and are hidden when invites are not allowed. Join code can be shown in the game-summary panel for PBC/Crossplay/EOS Internet and clicking the text copies it to clipboard.
- `EditHotseatPlayer.lua/.xml` is a modal for hotseat player name/password setup. It has name, password, password-verify edit boxes, mismatch status, Accept, and Cancel. Accept only enables when passwords match; it calls `LuaEvents.EditHotseatPlayer_UpdatePlayer(playerID)`.
- `EditHotseatPlayer` mutates live `PlayerConfigurations[playerID]` while the dialog is open: name changes write immediately via `SetHotseatName(...)`, password edits write immediately via `SetHotseatPassword(...)` when the two password boxes match, and a mismatch temporarily clears the stored hotseat password to `""`. Cancel restores the captured initial name/password before closing. Accept does not push a second copy of the values; it only raises `LuaEvents.EditHotseatPlayer_UpdatePlayer(playerID)` so `StagingRoom` refreshes that row.
- `UI/frontEnd/Multiplayer/EditHotseatPlayer.lua` now has a CAI frontend full replacement. The CAI mirror is a modal `MakeGeneralDialog` with three `AlwaysEdit` fields bound to the live vanilla edit boxes through `text_changed` so name/password writes stay immediate, matching vanilla's live `PlayerConfigurations` mutation. The old mismatch status label is intentionally not exposed as a separate CAI widget; when mismatch text is visible, it becomes the Accept button tooltip instead.
- `PlayerChange.lua/.xml` is the in-game hotseat player-handoff popup. It has two modes: a turn-start prompt that sets `TitleText` to the local player's name and optionally requires a hotseat password before Start Turn, and a turn-end `Please Wait` mode driven by `bPlayerChanging` where the dialog box itself is hidden and only `PlayerChangingText` remains visible. `ShowTurnControls()` is the live choke point for that state switch; it clears the password field, toggles `PasswordStack`, enables/disables `OkButton`, and calls `Controls.PasswordEntry:TakeFocus()` when a password is required.
- Vanilla hotseat handoff gives CAI two useful boundaries: `Events.LocalPlayerTurnEnd` for freezing or deferring per-player state, and `Events.LocalPlayerTurnBegin` for restoring the newly active player's state. `PlayerChange` sits between those events visually, but the CAI state swap itself should key off the player-turn events, not the popup lifecycle.
- `PlayerChange.OnOk()` raises `LuaEvents.PlayerChange_Close(Game.GetLocalPlayer())` immediately before the popup is dequeued. That is a good post-accept hook for deferred CAI speech that should wait until the handoff prompt is dismissed.
- `UI/inGame/PlayerChange_CAI.lua` now mirrors `PlayerChange` through a CAI dialog rebuilt from wrapped `ShowTurnControls()`. Prompt mode exposes Start Turn, Save Game, and Menu plus a masked `AlwaysEdit` password field when `PasswordStack` is visible; wait mode exposes the wait text and Menu. The password edit writes through `text_changed` to the live vanilla `Controls.PasswordEntry`, calls vanilla `OnPasswordEntryStringChanged(...)` for enablement parity, uses Enter commit to call vanilla `OnPasswordEntryCommit()`, and disables commit-on-focus-leave so tabbing away does not auto-start the turn. Right before the CAI dialog is pushed, it drops focus from the live `Controls.PasswordEntry` to prevent the native edit box from trapping interaction under the CAI dialog.
- `ConfirmKick.lua` uses `PopupDialog` for host kick confirmation or vote-kick reason selection (AFK, griefing, cheating, cancel). The CAI frontend replacement is a full vanilla-copy override with no CAI widget mirror; its accessibility block installs an extended input-struct handler after `Initialize()` that lets the CAI UI manager handle input first, then directly mirrors the vanilla Escape close path without delegating to the original old-signature `InputHandler`. `ConfirmExit.lua` is a simpler accept/cancel dialog for exit/kick flow. Crossplay login is a message dialog around EOS login state and raises `LuaEvents.EnterCrossPlayLobby()` when login succeeds.
- `PBCNotifyRemind.lua/.xml` is a Play By Cloud notification setup reminder with Options, Accept, and a Do Not Remind checkbox persisted to `Options.SetUserOption("Interface", "PlayByCloudNotifyRemind", ...)`.
- `UI/frontEnd/Multiplayer/PBCNotifyRemind.lua` CAI frontend replacement should mirror it as a simple dialog: title from `Controls.RemindTitle`, body from `Controls.RemindText`, a `Checkbox` bound to the live `DoNotRemindCheckbox` via `IsChecked()` + `DoLeftClick()`, and Options / OK buttons that click the live vanilla buttons. Show/hide is driven by the popup's `ShowHideHandler`, and the extended input handler should let the CAI manager handle Enter/Space/Tab while Escape still closes through `OnAccept()`.
- Civ Royale and Pirates intro popups are multi-page visual tutorials with logo, illustration, description, optional scrollable details, Previous, Next/Play, and Close. On the last page, Play starts matchmaking only if internet lobby service is available. They close automatically when `JoiningRoom` shows.
- Accessibility-shape implication: treat frontend multiplayer as four primary surfaces: MainMenu multiplayer submenu, Lobby browser, HostGame setup, and StagingRoom. Lobby should be a tab/list browser with sortable column reads, join-code dialog, friends list, and live row tooltips. HostGame can mirror the existing setup parameters with a form-like panel and picker dialogs. StagingRoom is the highest-density surface and should likely use a table or tree/list hybrid for player rows plus separate chat, game-summary, friends, and ready/start widgets, preserving all vanilla callbacks (`Network.JoinGame`, `Network.HostGame`, `Network.BroadcastPlayerInfo`, `Network.LaunchGame`, live pulldown callbacks, and modal dialogs).
- `UI/frontEnd/Multiplayer/Lobby.lua` CAI frontend replacement is implemented as a full vanilla-copy override with an accessibility block before `Initialize()`. The CAI panel exposes a games `Tree`, sort dropdown, sort-direction dropdown, refresh button, Join Code, Load, Host/Create, and a persistent friends `List`. PBC lobbies wrap the tree in a `TabControl` whose pages mirror the vanilla shell tabs and switch by clicking the vanilla tab button. Game-row focus selects the vanilla row only when it is not already selected; game-row activate selects and clicks the vanilla Join/Play button when available, so there is no separate CAI Join button. The CAI Join Code button mirrors the live vanilla Join Code button and opens the same `PopupDialog` path that commits through `Network.JoinGameByJoinCode(...)`. Disabled join reasons are included in the row tooltip, but row status such as loading-save/current-turn remains in the label only to avoid repeated speech. Rows expand to player names sourced from the live Members tooltip when available; vanilla does not create visual player rows and the only known source is `serverEntry.Players`, so some lobby types may expose only the player count. Rows also include official/community additional-content groups. Content groups with entries expand to individual mod/game-mode rows and use the group tooltip for owned/required counts; empty groups have no children and use `None` as the tooltip. Vanilla Lua only treats Play By Cloud as a true batch-update source: `IsGameListBatchUpdating()` returns true for PBC only, while Internet and Crossplay both receive trickled `MultiplayerGameListUpdated` entries. CAI therefore tracks its own refresh session from `RebuildGameList()` / `MultiplayerGameListClear` through `MultiplayerGameListComplete`, keeps the tree on a stable `Refreshing game list` placeholder for that whole window, and suppresses incremental rebuilds until the completion event. The focused empty-state row uses different `FocusKey` values for refreshing vs no-results (`empty:refreshing` / `empty:none`) so the tree manager treats `Refreshing game list` and `No games found` as distinct focus states and re-announces when the empty label changes under focus. Live add/remove updates after refresh still rebuild the tree. The persistent friends list mirrors the ChatPanel player-list shape: one always-visible `SubMenu` row per friend, with row speech including the live status and submenu children rebuilt from `BuildFriendActionList(...)`. PBC previous/next page requests are bound to panel-local `Alt+Left` / `Alt+Right` and call the vanilla backend offset refresh path.
- `UI/frontEnd/Multiplayer/StagingRoom.lua` CAI frontend replacement is implemented as a full vanilla-copy override with an accessibility block before `Initialize()`. The CAI panel is pushed from wrapped `OnShow()` only when it is not already on the manager stack, and it is removed only in wrappers around vanilla dequeue chokepoints: `OnHandleExitRequest`, `OnLeaveGameComplete`, `OnBeforeMultiplayerInviteProcessing`, and `OnGameSetupTabClicked`. The root shape is a single panel: player-slot `List`, ready/start action, writable `AlwaysEdit` chat entry that sends via `SendChat` on commit, chat-target `Dropdown`, chat-history `List` of static-text entries, read-only game-summary `EditBox`, Copy Join Code, Play By Cloud End Game and Quit Game, persistent friends `List`, and Game Setup. Player slots are editable `SubMenu` rows when any live slot control is visible/enabled; otherwise they are read-only `MenuItem` rows. Slot labels append ready status plus human/AI/observer/open/closed status, while slot tooltips now compute civ/leader, team, difficulty, and color from live player parameters and game state rather than from often-empty icon-only controls. The slot-type child dropdown uses the selected slot-type explanation as its tooltip, filters out vanilla's swap pseudo-option, and falls back to a disabled `Choose slot type` dummy option when no real slot types are available. Swap is exposed as a separate CAI button that calls vanilla `OnSwapButton(playerID)` under the same non-hotseat/non-PBC/non-matchmaking eligibility used by vanilla. The CAI copy-join-code action mirrors the live join-code text and now falls back to a CAI `Copy the join code to the clipboard.` tooltip when vanilla leaves the join-code text control without one. Real multiplayer chat delivered to the local client is recorded in the CAI chat history and spoken once, non-interrupting, from the wrapped `OnChat` path, including chat sent by the local player; vanilla lobby system chat lines for player connected, disconnected, host migrated, and kicked are also auto-spoken once. CAI also wraps `ChatPrintHelp(...)` so `/help` output is mirrored into CAI chat history as a local-only chat line and auto-spoken with multi-line `SpeakLines(...)`; the chat input tooltip falls back to `LOC_CHAT_HELP_COMMAND_HINT` when the live edit box has no tooltip. The history widget order follows the user's requested flow: chat input, chat target, then history, and the history rows are individual `StaticText` widgets rather than one read-only edit buffer. The leader child dropdown reuses the Advanced Setup `leader, civilization` labels plus leader/civ ability tooltip pattern, and the color child dropdown mirrors vanilla's manual color-option build. Submenu children preserve vanilla mechanics through `OnSlotType`, `OnTeamPull`, player parameter writes, live hotseat edit/kick/add-player callbacks, and `DoLeftClick()` where available. The persistent friends list matches the Lobby/ChatPanel submenu pattern: one always-visible `SubMenu` row per friend, with per-friend action children rebuilt from `BuildFriendActionList(...)` and refreshed on vanilla friend updates plus staging player-state rebuilds that can change invite eligibility.
- Current CAI staging-room hotseat coverage now includes the hotseat edit modal itself: the player-slot submenu still opens `EditHotseatPlayer` through the live vanilla modal path, but the modal is now mirrored by CAI and refreshes off `Realize()` so it stays in sync whether `StagingRoom_SetPlayerID` fires before or after the popup becomes visible.
- Shared UI-manager edit-box note: `EditBoxWidget` now exposes `CommitOnFocusLeave` and defaults it to `true` for writable `AlwaysEdit` parity. StagingRoom chat and `UI/inGame/ChatPanel_CAI.lua` chat both set it to `false` so leaving the input field does not auto-send or auto-commit partially typed chat; Enter remains the explicit send path.
- Additional staging-room CAI behavior: for human-target swaps, the separate Swap button now reflects the local pending handshake state as `Swap, on` / `Swap, off`, speaks that state immediately when toggled, and still uses plain `Swap` for instant non-human swaps. Successful swaps are inferred from the local player ID changing across `OnPlayerInfoChanged(...)`; CAI then speaks `Swap successful` and moves focus to the new local slot only if focus was already somewhere inside the CAI player-slot list. Ready-state changes now announce `{player} ready` / `{player} unready`. The CAI ready button keeps the action label as `Ready` / `Unready`, but when a countdown is active its tooltip prepends the live countdown number and, if the button is currently focused, countdown refresh ticks speak the number only. Friend-submenu invite activation now also speaks `Invite sent`.

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
- Base `CityBannerManager.lua` stores local-city growth and production speech data on top-level controls such as `m_Instance.CityPopulation`, `m_Instance.CityProduction`, `m_Instance.CityPopulationMeter`, and `m_Instance.CityProductionMeter`.
- Expansion 1 and Expansion 2 move those reads into stat-row instance managers instead: `m_StatPopulationIM` allocates a `CityStatPopulation` row whose tooltip lives on `FillMeter`, and `m_StatProductionIM` allocates a `CityStatProduction` row whose tooltip lives on `Button` and whose progress meter lives on `FillMeter`. CAI hotkey reads must support both layouts.
- Expansion 1 and Expansion 2 also move governor info into `m_StatGovernorIM`, with governor detail tooltips on each row `FillMeter`.
- Expansion 1 and Expansion 2 shift city-state quest / trading-post status and city effect icons into instance-manager rows: `m_DetailStatusIM` for status icons such as quests and trading posts, and `m_DetailEffectsIM` for effects such as siege, occupied, housing, amenities, and XP2 power.
- `CityBannerManager` expansion loyalty data can be rebuilt from live `city:GetCulturalIdentity()` calls without the loyalty lens. Useful methods are `GetLoyalty()`, `GetMaxLoyalty()`, `GetLoyaltyPerTurn()`, `GetPotentialTransferPlayer()`, `GetPlayerIdentitiesInCity()`, and `GetIdentitySourcesBreakdown()`.
- Expansion loyalty mini-panel control names are stable enough for CAI tree labels/tooltips: `LoyaltyInfo.LoyaltyPercentageLabel`, `PopulationTop`, `GovernorTop`, `Happiness`, `OtherTop`, `CityStateTop`, `FreeCityTop`, and `IdentityBreakdownStack`.
- GS power banner text can be mirrored from `city:GetPower()` with vanilla loc keys. Firaxis uses `GetFreePower()`, `GetTemporaryPower()`, `GetRequiredPower()`, `IsFullyPowered()`, and `IsFullyPoweredByActiveProject()` together with `LOC_CITY_BANNER_POWERED_CITY`, `LOC_CITY_BANNER_POWERED_CITY_FROM_ACTIVE_PROJECT`, and `LOC_CITY_BANNER_UNPOWERED_CITY`.
