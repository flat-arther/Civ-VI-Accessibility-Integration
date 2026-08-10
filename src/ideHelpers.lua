---@meta

---@alias SoundHandle integer
---@alias AttenuationModel
---| 0 # None
---| 1 # Inverse
---| 2 # Linear
---| 3 # Exponential

---@class CAIAttenuationModel
---@field None 0
---@field Inverse 1
---@field Linear 2
---@field Exponential 3

---@class CAI
---@field AttenuationModel CAIAttenuationModel
CAI = {}

---@param section string
---@param key string
---@param defaultValue string
---@return string|nil
function CAI.GetConfigValue(section, key, defaultValue) end

---@param section string
---@param key string
---@param value string
function CAI.SetConfigValue(section, key, value) end

---@param filePath string
---@return SoundHandle|nil
function CAI.LoadSound(filePath) end

---@param handle SoundHandle
---@return boolean
function CAI.DestroySound(handle) end

---@param handle SoundHandle
function CAI.PlaySound(handle) end

---@param handle SoundHandle
function CAI.PauseSound(handle) end

---@param handle SoundHandle
function CAI.StopSound(handle) end

---@param handle SoundHandle
---@param volume number
function CAI.SetSoundVolume(handle, volume) end

---@param handle SoundHandle
---@return number
function CAI.GetSoundVolume(handle) end

---@param handle SoundHandle
---@param looping boolean
function CAI.SetSoundLooping(handle, looping) end

---@param handle SoundHandle
---@return boolean
function CAI.IsSoundLooping(handle) end

---@param handle SoundHandle
---@return boolean
function CAI.IsSoundPlaying(handle) end

---@param handle SoundHandle
---@param pitch number
function CAI.SetSoundPitch(handle, pitch) end

---@param handle SoundHandle
---@return number
function CAI.GetSoundPitch(handle) end

---@param handle SoundHandle
---@param pan number
function CAI.SetSoundPan(handle, pan) end

---@param handle SoundHandle
---@return number
function CAI.GetSoundPan(handle) end

---@param handle SoundHandle
---@param x number
---@param y number
---@param z number
function CAI.SetSoundPosition(handle, x, y, z) end

---@param handle SoundHandle
---@return number x
---@return number y
---@return number z
function CAI.GetSoundPosition(handle) end

---@param handle SoundHandle
---@param x number
---@param y number
---@param z number
function CAI.SetSoundDirection(handle, x, y, z) end

---@param handle SoundHandle
---@param x number
---@param y number
---@param z number
function CAI.SetSoundVelocity(handle, x, y, z) end

---@param handle SoundHandle
---@param enabled boolean
function CAI.SetSoundSpatializationEnabled(handle, enabled) end

---@param handle SoundHandle
---@return boolean
function CAI.IsSoundSpatializationEnabled(handle) end

---@param handle SoundHandle
---@param distance number
function CAI.SetSoundMinDistance(handle, distance) end

---@param handle SoundHandle
---@param distance number
function CAI.SetSoundMaxDistance(handle, distance) end

---@param handle SoundHandle
---@param model AttenuationModel
function CAI.SetSoundAttenuationModel(handle, model) end

---@param x number
---@param y number
---@param z number
function CAI.SetListenerPosition(x, y, z) end

---@param x number
---@param y number
---@param z number
function CAI.SetListenerDirection(x, y, z) end

---@param x number
---@param y number
---@param z number
function CAI.SetListenerUp(x, y, z) end

---@param x number
---@param y number
---@param z number
function CAI.SetListenerVelocity(x, y, z) end

---@alias PlotInfoType
---|"plotName"
---| "Owner"
---| "Feature"
---| "NationalPark"
---| "Resources"
---| "Geography"
---| "Movement"
---| "Defense"
---| "Appeal"
---| "Continent"
---| "TileType"
---| "NaturalWonder"
---| "Buildings"
---| "Status"



---@class CAICursorMoveState
---@field fromPlotId integer Plot index before the move.
---@field toPlotId integer Plot index after the move.
---@field distance number Hex distance between from and to.
---@field fromX integer X coordinate before the move.
---@field fromY integer Y coordinate before the move.
---@field toX integer X coordinate after the move.
---@field toY integer Y coordinate after the move.
---@field reason "step"|"jump"|"select"|"snap"|"scope" Why the cursor moved.

---@class CAICursor
---@field curX integer The current X coordinate of the cursor.
---@field curY integer The current Y coordinate of the cursor.
---@field lastOwnerZone string|nil Last spoken owner zone text.
---@field lastContinentZone string|nil Last spoken continent zone text.
---@field lastTerritoryZone string|nil Last spoken territory zone text (XP2: deserts, mountains, seas, lakes, oceans).
---@field lastVolcanoZone string|nil Last spoken volcano zone text (XP2).
---@field lastNationalParkZone string|nil Last spoken national park zone text.
CAICursor = {}

---Sets cursor coordinates. Updates zone tracking and announces zone changes.
---@param x integer
---@param y integer
---@return boolean moved True if coordinates were set successfully.
function CAICursor:SetCoords(x, y) end

---Unified move entry point. Resolves plotId, enforces an active city-interface scope,
---updates coordinates and zones, speaks direction on "jump" and "select" reasons,
---and fires LuaEvents.CAICursorMoved(state).
---@param plotId integer Target plot index.
---@param reason "step"|"jump"|"select"|"snap"|"scope" Why the cursor is moving.
function CAICursor:MoveTo(plotId, reason) end

---Clears the cached city-management cursor scope.
function CAICursor:InvalidateCityScope() end

---Moves the cursor to the selected city center when it is outside the active city-interface scope.
function CAICursor:EnsureCityScopePosition() end

---Moves to the adjacent plot in the given hex direction. Calls MoveTo with reason "step".
---@param dir DirectionTypes The direction index (0-5).
function CAICursor:MoveDirection(dir) end

---Returns the unique Index of the plot currently under the cursor.
---@return integer # The plot index, or -1 if the plot is invalid.
function CAICursor:GetPlotId() end

---Updates zone tracking (continent, owner, territory, volcano, natural wonder, national park).
function CAICursor:UpdateZones() end

---Public move API: call LuaEvents.CAICursorMoveTo(plotId, reason) to move the cursor.
---Direction-based stepping: call LuaEvents.CAICursorMoveDirection(direction).
---Output event: LuaEvents.CAICursorMoved(state) fires after every move with a CAICursorMoveState table.

-- =============================================================================
-- CAI UI Manager — class and method annotations
-- =============================================================================

---Speak a string through the TTS pipeline.
---@param text string
---@param interrupt? boolean Interrupt any speech in flight. Default false.
---@param processTokens? boolean Run ProcessText on text before speaking. Default true.
function Speak(text, interrupt, processTokens) end

---Speak each line in turn. When interrupt is true only the first line cuts
---ongoing speech; the rest queue so per-widget lines don't trample each other.
---@param lines string[]
---@param interrupt? boolean
---@param processTokens? boolean
function SpeakLines(lines, interrupt, processTokens) end

---Split text into natural spoken lines by combining complete sentences up to
---the requested character length. Oversized sentences remain intact.
---@param text any
---@param maxLength? integer Defaults to the configured token split length.
---@return string[]
function SplitTextIntoLines(text, maxLength) end

---Names of events emitted by widgets via UIWidget:Emit(name, ...).
---@alias CAIWidgetEvent
---| "focus_enter"     # widget or a descendant became part of the current focus path
---| "focus_leave"     # widget left the focus path
---| "activate"        # button / menu item / tree-leaf activation
---| "value_changed"   # ValueWidget value changed (Toggle, Increment, EditBox Commit, SetValue without silent)
---| "text_changed"    # EditBox buffer changed; emitted after the edit is spoken
---| "expanded"        # TreeItem or SubMenu was expanded
---| "collapsed"       # TreeItem or SubMenu was collapsed
---| "row_focus_enter" # DataTable focus entered a different logical row
---| "cell_focus_enter" # DataTable focus entered a cell
---| "row_activate"    # DataTable actionable row activated from one of its cells
---| "sort_changed"    # DataTable sort column or direction changed
---| "rebuilt"         # DataTable completed a rebuild
---| "navigation_wrap" # navigation crossed a wrapping container or tab-control boundary; extra arg is direction (+1/-1)
---| "destroy"         # widget is being destroyed; clean up subscriptions

---Edit modes constraining character input on EditBoxWidget.
---@class EditModesEnum
---@field Normal integer
---@field LettersOnly integer
---@field NumbersOnly integer
---@field AlphanumericOnly integer
EditModes = {}

---A single key binding installed on a widget's InputMap.
---@class InputBinding
---@field Key Keys
---@field Action fun(w:UIWidget):boolean
---@field MSG? KeyEvents  defaults to KeyEvents.KeyUp
---@field IsShift? boolean
---@field IsControl? boolean
---@field IsAlt? boolean
---@field Description? string  LOC tag describing the binding for the input help overlay
---@field Common? boolean  Runs even when the widget is disabled
---@field BubbleWhenDisabled? boolean  Lets a matching non-common binding bubble instead of being consumed while disabled

---One option in a Dropdown.
---@class DropdownOption
---@field label string
---@field value any
---@field tooltip? string|fun(...):string
---@field extraEvents? table<string,fun(UIWidget, ...):string>

---One column in a GridWidget. `width` is the number of side-by-side tiers
---the column holds (default 1).
---@class GridColumn
---@field header string|fun():string
---@field width? integer

---@class GraphGroup
---@field key string|number Stable group identity.
---@field label string|fun():string Live localized group label.

---@class GraphNodeOptions
---@field group? string|number Optional GraphGroup key.

---Opaque value returned by Manager:CaptureFocusKey and consumed by RestoreFocus.
---@class FocusCapture
---@field key? string
---@field path integer[]

---@class CAIAudioPlayOptions
---@field SkipIfPlaying? boolean Suppress playback when the sound handle is already playing.
---@field ListenerPlot? integer|table Explicit listener plot id or Plot; defaults to the current CAI cursor.
---@field MaxDistance? number Audible hex distance for positional falloff; defaults to 30.

---@class CAIAudioDefinitionRow
---@field SoundId string
---@field RelativePath string
---@field Tag string
---@field IsPositional boolean

---@class CAIAudioPlotState
---@field SourcePlotId integer
---@field ListenerPlotId? integer
---@field MaxDistance number

---@class CAIAudioRecord
---@field SoundId string
---@field RelativePath string
---@field FullPath string
---@field Tag string
---@field Handle SoundHandle
---@field IsPositional boolean
---@field BaseGain number
---@field PlotGain number
---@field PlotState? CAIAudioPlotState

---@class CAIAudioQueueItem
---@field SoundId string
---@field SourcePlotId? integer
---@field DueTime number
---@field Options? CAIAudioPlayOptions

---@class CAIAudioManager
---@field MasterVolumeScalar number|nil
---@field Owner any
---@field ModRoot string|nil
---@field IsInitialized boolean
---@field SettingsHooked boolean
---@field SettingsChangedListener fun(settingId:string)|nil
---@field DefinitionsById table<string, CAIAudioDefinitionRow>
---@field LoadedSoundsById table<string, CAIAudioRecord>
---@field SoundsByTag table<string, CAIAudioRecord[]>
---@field Queue CAIAudioQueueItem[]
CAIAudioManager = {}

---@param owner? any
---@return CAIAudioManager
function CAIAudioManager:New(owner) end

---@return number
function CAIAudioManager:GetMasterVolumeScalar() end

---@return boolean changed
function CAIAudioManager:SyncMasterVolume() end

---@return string|nil
function CAIAudioManager:ResolveModRoot() end

---@param relativePath string
---@return string|nil
function CAIAudioManager:BuildFullPath(relativePath) end

---@return CAIAudioDefinitionRow[]
function CAIAudioManager:GetDefinitionRows() end

function CAIAudioManager:LoadDefinitions() end

---@param record CAIAudioRecord|nil
function CAIAudioManager:ApplyTagVolume(record) end

function CAIAudioManager:UnloadSounds() end

function CAIAudioManager:LoadSounds() end

---@param soundId string
---@return CAIAudioRecord|nil
function CAIAudioManager:GetSound(soundId) end

---@param tag string
---@return CAIAudioRecord[]
function CAIAudioManager:GetSoundsByTag(tag) end

---@param prefix string
---@param tag string
---@return string|nil
function CAIAudioManager:FindTagSettingId(prefix, tag) end

---@param tag string
---@return string|nil
function CAIAudioManager:GetTagEnabledSettingId(tag) end

---@param tag string
---@return string|nil
function CAIAudioManager:GetTagVolumeSettingId(tag) end

---@param tag string
---@return boolean
function CAIAudioManager:IsTagEnabled(tag) end

---@param tag string
---@return number
function CAIAudioManager:GetTagVolumeScalar(tag) end

---@param soundId string
function CAIAudioManager:ClearQueuedSound(soundId) end

---@param tag string
function CAIAudioManager:ClearQueuedTag(tag) end

---@param record CAIAudioRecord|nil
---@param options? CAIAudioPlayOptions
---@return boolean
function CAIAudioManager:ShouldSkipPlay(record, options) end

---@param plotOrId integer|table
---@return table|nil plot
---@return integer|nil plotId
function CAIAudioManager:ResolvePlot(plotOrId) end

---@return table|nil plot
---@return integer|nil plotId
function CAIAudioManager:GetDefaultListenerPlot() end

---@param record CAIAudioRecord
---@return boolean
function CAIAudioManager:ApplyPlotAudioParameters(record) end

---@param soundId string
---@param options? CAIAudioPlayOptions
---@return boolean played True when playback was started.
function CAIAudioManager:Play(soundId, options) end

---@param soundId string
---@param sourcePlotOrId integer|table
---@param options? CAIAudioPlayOptions
---@return boolean played
function CAIAudioManager:PlayAtPlot(soundId, sourcePlotOrId, options) end

---@param soundId string
---@param delaySeconds? number
---@param options? CAIAudioPlayOptions
---@return boolean queued True when the sound was accepted into the queue.
function CAIAudioManager:QueueSound(soundId, delaySeconds, options) end

---@param soundId string
---@param sourcePlotOrId integer|table
---@param delaySeconds? number
---@param options? CAIAudioPlayOptions
---@return boolean queued
function CAIAudioManager:QueueSoundAtPlot(soundId, sourcePlotOrId, delaySeconds, options) end

---@param soundId string
---@return boolean
function CAIAudioManager:StopSound(soundId) end

---@param soundId string
---@return boolean
function CAIAudioManager:PauseSound(soundId) end

---@param soundId string
---@param volume number
---@return boolean
function CAIAudioManager:SetSoundVolume(soundId, volume) end

---@param tag string
---@param volume number
---@return boolean
function CAIAudioManager:SetTagVolume(tag, volume) end

---@param tag string
---@return boolean
function CAIAudioManager:StopTag(tag) end

---@param tag string
---@return boolean
function CAIAudioManager:PauseTag(tag) end

function CAIAudioManager:ApplySettings() end

---@param settingId string
function CAIAudioManager:OnSettingsChanged(settingId) end

function CAIAudioManager:HookSettingsChanged() end

function CAIAudioManager:UnhookSettingsChanged() end

function CAIAudioManager:Update() end

---@param owner? any
function CAIAudioManager:Initialize(owner) end

function CAIAudioManager:Shutdown() end

-- -----------------------------------------------------------------------------
-- CAIUITutorialManager
-- -----------------------------------------------------------------------------

---@alias CAITutorialLocalizedText string|fun(context:any, item:CAITutorialItemDefinition):string

---@class CAITutorialItemDefinition
---@field Id string Stable persistence identifier.
---@field RaiseEvents string[] Named events which may raise this item.
---@field Title CAITutorialLocalizedText Localization tag or live localized-text getter.
---@field Content CAITutorialLocalizedText[] Ordered static-text rows.
---@field Order? number Lower values are evaluated first.
---@field Queueable? boolean Whether the item may wait behind another tutorial.
---@field Prerequisites? string[] Item ids which must already be seen.
---@field CanRaise? fun(context:any, item:CAITutorialItemDefinition):boolean
---@field OnOpen? fun(context:any, item:CAITutorialItemDefinition)
---@field OnContinue? fun(context:any, item:CAITutorialItemDefinition)
---@field private _registrationOrder? integer

---@class CAITutorialQueueItem
---@field Item CAITutorialItemDefinition
---@field Owner UIWidget
---@field Context? any

---@class CAITutorialActiveState : CAITutorialQueueItem
---@field Host PanelWidget
---@field Dialog DialogWidget
---@field PreviousFocus? UIWidget

---@class CAIUITutorialManager
---@field Manager? UIScreenManager
---@field Items table<string, CAITutorialItemDefinition>
---@field Listeners table<string, CAITutorialItemDefinition[]>
---@field Queue CAITutorialQueueItem[]
---@field Active? CAITutorialActiveState
---@field NextRegistrationOrder integer
---@field IsClosing boolean
---@field SettingsChangedListener? fun(settingId:string, value:any)
---@field SettingsHooked boolean
CAIUITutorialManager = {}

---@param mgr UIScreenManager
---@return CAIUITutorialManager
function CAIUITutorialManager:New(mgr) end

---@param item CAITutorialItemDefinition
---@return boolean
function CAIUITutorialManager:RegisterItem(item) end

---@param items CAITutorialItemDefinition[]
---@return boolean
function CAIUITutorialManager:RegisterItems(items) end

---@param eventName string
---@param owner UIWidget
---@param context? any
---@return boolean opened
function CAIUITutorialManager:Check(eventName, owner, context) end

---@param itemId string
---@return boolean
function CAIUITutorialManager:IsSeen(itemId) end

---@param itemId string
---@return boolean
function CAIUITutorialManager:MarkSeen(itemId) end

---@param itemId string
---@return boolean
function CAIUITutorialManager:ResetSeen(itemId) end

---@return boolean
function CAIUITutorialManager:ResetAllSeen() end

---@return integer
function CAIUITutorialManager:GetResetGeneration() end

---@return boolean
function CAIUITutorialManager:AreTutorialsEnabled() end

---@return boolean
function CAIUITutorialManager:IsActive() end

---@return boolean
function CAIUITutorialManager:Continue() end

function CAIUITutorialManager:ClearQueue() end

---@param settingId string
---@param value? any
function CAIUITutorialManager:OnSettingsChanged(settingId, value) end

function CAIUITutorialManager:HookSettingsChanged() end

function CAIUITutorialManager:UnhookSettingsChanged() end

---@return boolean opened
function CAIUITutorialManager:OnRouteChanged() end

function CAIUITutorialManager:Shutdown() end

---@class CAIUITutorialCatalog
---@field Manager UIScreenManager
---@field ByRoot table[]
CAIUITutorialCatalog = {}

---@param mgr UIScreenManager
---@return CAIUITutorialCatalog
function CAIUITutorialCatalog:New(mgr) end

---@param root UIWidget
function CAIUITutorialCatalog:OnRootPushed(root) end

-- -----------------------------------------------------------------------------
-- UIWidget — base class
-- -----------------------------------------------------------------------------

---Base widget class. Owns identity, tree ops, predicate getters/setters,
---event listeners, input bindings, and speech assembly.
---@class UIWidget
---@field Id? string
---@field Type? string
---@field Role? string
---@field Parent? UIWidget
---@field Children UIWidget[]
---@field Manager? UIScreenManager
---@field InputMap InputBinding[]
---@field SpeechSettings table<string, boolean>
---@field FocusKey? string             stable identifier that survives rebuilds
---@field Transparent boolean          when true, skipped by BuildAnnouncement
---@field UseDirectionalEntry? boolean Transparent containers use directional first/last entry unless this is false.
---@field DefaultIndex? integer
UIWidget = {}

---@param child UIWidget
---@param focus? boolean Focus the child immediately after adding
function UIWidget:AddChild(child, focus) end

---@param children UIWidget[]
---@param focusIndex? integer
function UIWidget:AddChildren(children, focusIndex) end

---@param index integer
---@param child UIWidget
function UIWidget:InsertChild(index, child) end

---@param index integer
function UIWidget:RemoveChild(index) end

function UIWidget:RemoveFromParent() end

function UIWidget:ClearChildren() end

---Destroy this widget, its descendants, and detach from parent. Emits "destroy"
---before tearing down. Calls Manager:NotifyDestroy so the focus path prunes.
function UIWidget:Destroy() end

---@return integer
function UIWidget:GetIndexInParent() end

---@param child UIWidget
---@return integer
function UIWidget:GetChildIndex(child) end

---@param id string
---@param recurse? boolean
---@return UIWidget|nil
function UIWidget:GetChildById(id, recurse) end

---@return UIWidget[]
function UIWidget:GetVisibleChildren() end

---@return integer|nil visibleIndex, integer visibleTotal
function UIWidget:GetVisiblePosition() end

---Localized spoken position supplied only by an ordered navigation container.
---Returns nil for widgets under ordinary layout parents.
---@return string|nil
function UIWidget:GetPositionString() end

---Manager-derived: the child currently in this widget's segment of CurrentPath,
---or the cached _lastFocusedChild hint when the widget is off-path.
---@return UIWidget|nil
function UIWidget:GetFocusedChild() end

---@return boolean
function UIWidget:IsFocused() end

---@param idx integer
function UIWidget:SetDefaultIndex(idx) end

---Set a label literal or getter function. Resolved at speech time.
---@param arg string|fun(w:UIWidget):string|nil
function UIWidget:SetLabel(arg) end

---@param arg string|fun(w:UIWidget):string|nil
function UIWidget:SetTooltip(arg) end

---@param fn fun(w:UIWidget):any
function UIWidget:SetValueGetter(fn) end

---@param fn fun(w:UIWidget):string
function UIWidget:SetStateGetter(fn) end

---@param fn fun(w:UIWidget):boolean
function UIWidget:SetHiddenPredicate(fn) end

---@param fn fun(w:UIWidget):boolean
function UIWidget:SetDisabledPredicate(fn) end

---@param role string
function UIWidget:SetRole(role) end

---@param key string|nil
function UIWidget:SetFocusKey(key) end

---@param b boolean
function UIWidget:SetTransparent(b) end

---Sound to play on focus_enter (passed to UI.PlaySound). nil disables.
---@param soundName string|nil
function UIWidget:SetFocusSound(soundName) end

---@return string
function UIWidget:GetLabel() end

---@return string
function UIWidget:GetTooltip() end

---@return any
function UIWidget:GetValue() end

---@return string
function UIWidget:GetState() end

---@return boolean
function UIWidget:IsHidden() end

---@return boolean
function UIWidget:IsDisabled() end

---Register a listener for a widget event. Returns an opaque token consumed by Off.
---@param event CAIWidgetEvent
---@param fn fun(w:UIWidget, ...)
---@return table token
function UIWidget:On(event, fn) end

---@param event CAIWidgetEvent
---@param token table
function UIWidget:Off(event, token) end

---Dispatch an event. Iterates a snapshot of listeners so handlers can add/remove
---during dispatch without iteration glitches.
---@param event CAIWidgetEvent
function UIWidget:Emit(event, ...) end

---@param binding InputBinding
function UIWidget:AddInputBinding(binding) end

---@param bindings InputBinding[]
function UIWidget:AddInputBindings(bindings) end

---Base input handler. Walks InputMap; returns true to consume.
---@param input InputStruct
---@return boolean
function UIWidget:OnHandleInput(input) end

---Set the popup priority used by the manager's stack sort. Root widgets only.
---@param priority PopupPriority
function UIWidget:SetPriority(priority) end

---Build the spoken description for this widget. Pass an explicit subset of keys
---("label","role","state","value","tooltip","position") to limit output.
---@param elements? string[]
---@return string|nil
function UIWidget:BuildSpeech(elements) end

---@return string[]
function UIWidget:GetSpeechOrder() end

---Speak this widget's info on demand. Used by screens after a value updates
---outside the focus path.
---@param elements? string[]
function UIWidget:Announce(elements) end

---Legacy alias for Announce.
---@param elements? string[]
function UIWidget:SpeakElements(elements) end

---@return table<string, string|nil>
function UIWidget:GetInfoStrings() end

-- -----------------------------------------------------------------------------
-- ContainerWidget — navigable parent
-- -----------------------------------------------------------------------------

---ContainerWidget adds sibling navigation + default-child resolution. The base
---class for Panel, Dialog, List, HorizontalList, Tree, TabPage, SubMenu.
---Containers also own the Ctrl+F search integration: set AllowSearch = true
---(or call EnableSearch / SetSearchQueryHandler) to let the user open a
---SearchPanel overlay via Ctrl+F. Lists and Trees enable search by default.
---@class ContainerWidget : UIWidget
---@field WrapAround boolean
---@field PageSize integer
---@field AllowSearch boolean
---@field _searchQueryMode "terms"|"raw"
ContainerWidget = {}

---@param b boolean
function ContainerWidget:SetWrapAround(b) end

---@param n integer  set to 0 to disable PgUp/PgDn behavior on this container
function ContainerWidget:SetPageSize(n) end

---@param b boolean
function ContainerWidget:SetAllowSearch(b) end

function ContainerWidget:EnableSearch() end

function ContainerWidget:DisableSearch() end

---Set a custom query handler for Ctrl+F search on this container.
---Implicitly enables search. The handler receives (query, maxResults)
---and must return a list of {key, label, onActivate?, widget?, tooltip?}.
---In the default "terms" mode, multi-term AND and "--term" exclusion are
---handled by the SearchPanel and the handler is called once per term. In
---"raw" mode, the handler receives the complete edit-box query once.
---@param handler fun(query:string, maxResults:integer):table[]
function ContainerWidget:SetSearchQueryHandler(handler) end

---@return fun(query:string, maxResults:integer):table[]|nil
function ContainerWidget:GetSearchQueryHandler() end

---Choose how Ctrl+F passes text to the query handler. "terms" is the default;
---"raw" passes the complete query once without CAI term/exclusion parsing.
---@param mode "terms"|"raw"
function ContainerWidget:SetSearchQueryMode(mode) end

---@return "terms"|"raw"
function ContainerWidget:GetSearchQueryMode() end

---Set the history context name for search on this container. Defaults to
---the container's Id. Containers sharing a context name share history.
---@param context string
function ContainerWidget:SetSearchHistoryContext(context) end

---@return string|nil
function ContainerWidget:GetSearchHistoryContext() end

---Forward results to the SearchPanel if it is currently open on this container.
---@param results table[]
function ContainerWidget:SetSearchResults(results) end

---Return the SearchPanel if it is currently open and targeting this container.
---@return SearchPanelWidget|nil
function ContainerWidget:GetSearchPanel() end

---Default child for re-entry / programmatic focus. Resolution:
---  1. _lastFocusedKey (by FocusKey)  2. _lastFocusedChild (widget ref)
---  3. DefaultIndex  4. First visible
---@return UIWidget|nil
function ContainerWidget:GetDefaultChild() end

---Direction-aware entry: 1=first visible, -1=last visible, nil/0=default.
---Transparent containers only use directional first/last entry when
---UseDirectionalEntry ~= false; otherwise they restore their default child.
---@param direction 1|-1|0|nil
---@return UIWidget|nil
function ContainerWidget:GetEntryChild(direction) end

---@param direction 1|-1
---@return boolean
function ContainerWidget:Navigate(direction) end

---@return boolean
function ContainerWidget:NavigateNext() end

---@return boolean
function ContainerWidget:NavigatePrev() end

---@return boolean
function ContainerWidget:NavigateToFirst() end

---@return boolean
function ContainerWidget:NavigateToLast() end

---Jump PageSize visible siblings forward (1) or backward (-1).
---@param direction 1|-1
---@return boolean
function ContainerWidget:NavigatePage(direction) end

-- -----------------------------------------------------------------------------
-- ValueWidget — stateful widget base
-- -----------------------------------------------------------------------------

---ValueWidget owns a mutable value with bound setter and optional commit phase.
---Base for Dropdown, Checkbox, Slider, EditBox.
---@class ValueWidget : UIWidget
ValueWidget = {}

---@param fn fun(w:ValueWidget, value:any)
function ValueWidget:SetValueSetter(fn) end

---Update value, invoke setter, emit "value_changed", and speak. silent=true
---updates internal state only (used for programmatic refresh).
---@param value any
---@param silent? boolean
function ValueWidget:SetValue(value, silent) end

---@return any
function ValueWidget:GetValue() end

-- -----------------------------------------------------------------------------
-- Concrete widgets
-- -----------------------------------------------------------------------------

---@class ButtonWidget : UIWidget
ButtonWidget = {}
---Emits "activate" unless the widget is currently disabled.
---@return boolean
function ButtonWidget:Activate() end

---@class MenuItemWidget : UIWidget
MenuItemWidget = {}
---@return boolean
function MenuItemWidget:Activate() end

---@class StaticTextWidget : UIWidget
StaticTextWidget = {}

---@class PanelWidget : ContainerWidget
PanelWidget = {}

---@class DialogWidget : ContainerWidget
DialogWidget = {}
---@param child UIWidget
function DialogWidget:SetDefaultActionWidget(child) end

---Create (or replace) the action button row. The row is Transparent so focus
---speech announces the button directly. Returns the row container.
---@param buttons ButtonWidget[]
---@param defaultIndex? integer
---@return ContainerWidget
function DialogWidget:SetButtons(buttons, defaultIndex) end

---@return UIWidget[]
function DialogWidget:GetActionButtons() end

---@return UIWidget[]
function DialogWidget:GetContent() end

---@class DropdownWidget : ContainerWidget
DropdownWidget = {}
---@param options DropdownOption[]
function DropdownWidget:SetOptions(options) end

---@param index integer
---@param silent? boolean
function DropdownWidget:SetSelectedIndex(index, silent) end

---@param index integer
---@param silent? boolean
function DropdownWidget:Commit(index, silent) end

---@return integer committed selection
function DropdownWidget:GetSelectedIndex() end

function DropdownWidget:Open() end

---@param silent? boolean
function DropdownWidget:Close(silent) end

---@return boolean
function DropdownWidget:IsOpen() end

---Open silently while the manager prepares focus for a descendant.
function DropdownWidget:OpenForDescendantFocus() end

---@param fn fun(w:DropdownWidget, value:any)
function DropdownWidget:SetValueSetter(fn) end

---@param value any
---@param silent? boolean
function DropdownWidget:SetValue(value, silent) end

---@return any
function DropdownWidget:GetRawValue() end

---@class ListWidget : ContainerWidget
---@field SearchDepth integer
ListWidget = {}
---@param char string
---@return boolean
function ListWidget:OnCharInput(char) end

---@class HorizontalListWidget : ContainerWidget
HorizontalListWidget = {}

---@class SubMenuWidget : ContainerWidget
---@field IsExpanded boolean
SubMenuWidget = {}
---Expand the submenu (state only; the caller moves focus). `silent` suppresses
---the `expanded` event.
---@param silent? boolean
---@return boolean
function SubMenuWidget:Expand(silent) end

---Collapse the submenu and (always silently) every descendant. `silent`
---suppresses this node's `collapsed` event.
---@param silent? boolean
---@return boolean
function SubMenuWidget:Collapse(silent) end

---@class TreeWidget : ContainerWidget
---@field SearchDepth integer
TreeWidget = {}
---@param char string
---@return boolean
function TreeWidget:OnCharInput(char) end

---@class TreeItemWidget : ContainerWidget
---@field IsExpanded boolean
---@field IsTreeItem boolean
TreeItemWidget = {}
---@return boolean
function TreeItemWidget:IsLeaf() end

---Expand this node. `silent` suppresses the `expanded` event and speech.
---@param silent? boolean
---@return boolean
function TreeItemWidget:Expand(silent) end

---Collapse this node and (always silently) every descendant. `silent`
---suppresses this node's `collapsed` event and speech.
---@param silent? boolean
---@return boolean
function TreeItemWidget:Collapse(silent) end

---@class CheckboxWidget : ValueWidget
CheckboxWidget = {}
---@param b boolean
---@param silent? boolean
function CheckboxWidget:SetChecked(b, silent) end

---@return boolean
function CheckboxWidget:IsChecked() end

function CheckboxWidget:Toggle() end

---@class SliderWidget : ValueWidget
SliderWidget = {}
---Configure the minimum; any resulting clamp is silent.
---@param n number
function SliderWidget:SetMin(n) end

---Configure the maximum; any resulting clamp is silent.
---@param n number
function SliderWidget:SetMax(n) end

---@param n number
function SliderWidget:SetStepSize(n) end

---@param n number
function SliderWidget:SetPageStep(n) end

---@param n? integer
---@return boolean
function SliderWidget:Increment(n) end

---@param n? integer
---@return boolean
function SliderWidget:Decrement(n) end

---@return boolean
function SliderWidget:PageIncrement() end

---@return boolean
function SliderWidget:PageDecrement() end

---@class EditBoxWidget : ValueWidget
EditBoxWidget = {}
---Normalizes [NEWLINE]/\r\n, updates the edit buffer, and emits text_changed
---after any non-silent value announcement.
---@param text string
---@param silent? boolean
function EditBoxWidget:SetText(text, silent) end

---@return string
function EditBoxWidget:GetText() end

---@param b boolean
function EditBoxWidget:SetReadOnly(b) end

---@param b boolean
function EditBoxWidget:SetAlwaysEdit(b) end

---@param b boolean
function EditBoxWidget:SetHighlightOnEdit(b) end

---@param n integer|nil
function EditBoxWidget:SetMaxCharacters(n) end

---Per-keystroke / paste guard. Receives the proposed full buffer; return false to reject.
---@param fn fun(text:string):boolean
function EditBoxWidget:SetValidator(fn) end

---Commit-time guard. Return nil to allow commit, or a string (spoken to the user) to block.
---@param fn fun(text:string):string|nil
function EditBoxWidget:SetCommitValidator(fn) end

---@param b boolean  when false, Enter bubbles instead of committing (default true)
function EditBoxWidget:SetEnterToCommit(b) end

---@param b boolean
function EditBoxWidget:SetPasswordMask(b) end

---When true, _value is kept in sync with _buffer on every change, so
---GetText() always returns the live content without needing an explicit Commit.
---@param b boolean
function EditBoxWidget:SetCommitOnBufferChanged(b) end

---@param b boolean  when false, AlwaysEdit writable boxes do not auto-commit on focus leave (default true)
function EditBoxWidget:SetCommitOnFocusLeave(b) end

---@param mode integer  one of EditModes.*
function EditBoxWidget:SetEditMode(mode) end

---@param silent? boolean  silent=true flips state without speaking; used for focus-driven activation
function EditBoxWidget:BeginEdit(silent) end

function EditBoxWidget:Commit() end

function EditBoxWidget:Cancel() end

---@class TabControlWidget : ContainerWidget
TabControlWidget = {}
---@param labelOrFn string|fun():string
---@return TabPageWidget
function TabControlWidget:AddPage(labelOrFn) end

---@return integer
function TabControlWidget:GetPageCount() end

---@param i integer
---@return TabPageWidget|nil
function TabControlWidget:GetPage(i) end

---@param id string
---@return TabPageWidget|nil
function TabControlWidget:GetPageById(id) end

---@return TabPageWidget|nil
function TabControlWidget:GetActivePage() end

---@return integer
function TabControlWidget:GetActivePageIndex() end

---@param i integer
---@param silent? boolean
function TabControlWidget:SetActivePage(i, silent) end

---@param id string
---@param silent? boolean
function TabControlWidget:SetActivePageById(id, silent) end

---@param silent? boolean
---@return boolean
function TabControlWidget:NextPage(silent) end

---@param silent? boolean
---@return boolean
function TabControlWidget:PreviousPage(silent) end

---@class TabWidget : UIWidget
TabWidget = {}

---@class TabPageWidget : ContainerWidget
TabPageWidget = {}

---Three-level grid: Grid -> Column -> Tier -> item cell. A column speaks
---only its header label (role/position muted) and owns its cells through
---tiers, so the column header is announced when focus crosses into it.
---@class GridWidget : ContainerWidget
GridWidget = {}
---Append a column holding `width` side-by-side tiers. Returns the column widget.
---@param col GridColumn
---@return ContainerWidget column
function GridWidget:AddColumn(col) end

---@return integer
function GridWidget:GetColumnCount() end

---@param i integer
---@return ContainerWidget|nil
function GridWidget:GetColumnWidget(i) end

---@param column ContainerWidget|integer
---@param tierIndex? integer
---@return ContainerWidget|nil
function GridWidget:GetTier(column, tierIndex) end

---Append an item cell to a column's tier (vertical stack).
---@param column ContainerWidget|integer
---@param tierIndex integer|nil
---@param widget UIWidget
---@return integer itemIndex
function GridWidget:AddItem(column, tierIndex, widget) end

---Grid convenience: one cell into each column's first tier, in column order.
---@param cells (UIWidget|nil)[]
---@return integer rowIndex
function GridWidget:AddRow(cells) end

---@param row integer
---@param col integer
---@param widget UIWidget|nil
function GridWidget:SetCell(row, col, widget) end

---@param row integer
---@param col integer
---@return UIWidget|nil
function GridWidget:GetCell(row, col) end

---@return integer
function GridWidget:GetRowCount() end

---Table-style row/column position for a direct grid cell. Every visible tier
---counts as one column.
---@param widget UIWidget
---@return string|nil
function GridWidget:GetCellPositionString(widget) end

---@param row integer
function GridWidget:RemoveRow(row) end

function GridWidget:ClearRows() end

---Type-to-find candidates are every visible item cell across all tiers.
---@param includeTooltips boolean
---@return SearchCandidate[]
function GridWidget:GetTypeToFindCandidates(includeTooltips) end

---Directed relationship graph containing arbitrary node widgets. The manager's
---focus path owns the focused node; Graph caches only the alternatives created
---by the last incoming/outgoing traversal.
---@class GraphWidget : ContainerWidget
GraphWidget = {}

---@param group GraphGroup
---@return ContainerWidget groupWidget
function GraphWidget:AddGroup(group) end

---@param key string|number
---@param widget UIWidget
---@param options? GraphNodeOptions
---@return UIWidget
function GraphWidget:AddNode(key, widget, options) end

---@param fromKey string|number
---@param toKey string|number
function GraphWidget:AddEdge(fromKey, toKey) end

---@param key string|number
---@return UIWidget|nil
function GraphWidget:GetNode(key) end

---@return string|number|nil
function GraphWidget:GetFocusedNodeKey() end

---@param key string|number
function GraphWidget:SetDefaultNode(key) end

---@param key string|number
---@param options? boolean|{ direction?: 1|-1, announce?: boolean }
---@return boolean
function GraphWidget:FocusNode(key, options) end

---@param key string|number
---@return (string|number)[]
function GraphWidget:GetIncoming(key) end

---@param key string|number
---@return (string|number)[]
function GraphWidget:GetOutgoing(key) end

---@return (string|number)[]
function GraphWidget:GetRoots() end

---Position of a registered node in the live Up/Down alternative set.
---@param widget UIWidget
---@return string|nil
function GraphWidget:GetNodePositionString(widget) end

function GraphWidget:ClearGraph() end

---@param includeTooltips boolean
---@return SearchCandidate[]
function GraphWidget:GetTypeToFindCandidates(includeTooltips) end

---@class DataTableColumn
---@field key string Stable column identity.
---@field header string|fun():string Live localized column header.
---@field getCell fun(row:any):string Live displayed value.
---@field getTooltip? fun(row:any):string
---@field getState? fun(row:any):string
---@field isDisabled? fun(row:any):boolean
---@field sortKey? fun(row:any):any Presence makes the header sortable.
---@field sortAscendingDescription? string Localization tag describing ascending order.
---@field sortDescendingDescription? string Localization tag describing descending order.

---@class DataTableSort
---@field column string Stable DataTableColumn key.
---@field ascending? boolean

---@class DataTableCellWidget : UIWidget
---@field Table DataTableWidget
---@field Column DataTableColumn
---@field ColumnIndex integer
---@field Row any|nil Nil for a header cell.
---@field RowIndex integer Zero for a header cell.
---@field RowKey any|nil
DataTableCellWidget = {}

---Sortable homogeneous-row table. Its player-facing role remains `Table`;
---transparent row containers use `TableRow` and focusable cells use `TableCell`.
---Register `row_activate` before Rebuild to make Enter or Space on any cell
---activate its owning row.
---@class DataTableWidget : ContainerWidget
DataTableWidget = {}

---@param columns DataTableColumn[]
function DataTableWidget:SetColumns(columns) end

---@param provider fun():any[]
function DataTableWidget:SetRowsProvider(provider) end

---@param getter fun(row:any):any
function DataTableWidget:SetRowKeyGetter(getter) end

---@param getter fun(row:any):string
function DataTableWidget:SetRowLabelGetter(getter) end

---@param sort DataTableSort|nil
function DataTableWidget:SetDefaultSort(sort) end

---Re-read, sort, and rebuild the table while preserving a stable focused cell.
function DataTableWidget:Rebuild() end

---@return integer
function DataTableWidget:GetColumnCount() end

---@return integer
function DataTableWidget:GetRowCount() end

---@param column string|integer
---@return integer|nil
function DataTableWidget:GetColumnIndex(column) end

---@return string|nil columnKey, boolean ascending
function DataTableWidget:GetSort() end

---@param rowIndex integer One-based data row index.
---@param column string|integer
---@return DataTableCellWidget|nil
function DataTableWidget:GetCell(rowIndex, column) end

---@param column string|integer
---@return DataTableCellWidget|nil
function DataTableWidget:GetHeader(column) end

---@return any|nil row, any|nil rowKey, integer|nil rowIndex
function DataTableWidget:GetFocusedRow() end

---@return DataTableColumn|nil column, integer|nil columnIndex
function DataTableWidget:GetFocusedColumn() end

---@param columnKey string
function DataTableWidget:CycleSort(columnKey) end

---Type-to-find candidates are row labels only, targeted at the active column.
---@param includeTooltips boolean
---@return SearchCandidate[]
function DataTableWidget:GetTypeToFindCandidates(includeTooltips) end

---@class GameViewWidget : ContainerWidget
GameViewWidget = {}

---@class InterfaceModeWidget : ContainerWidget
InterfaceModeWidget = {}

-- -----------------------------------------------------------------------------
-- SearchPanelWidget — Ctrl+F overlay
-- -----------------------------------------------------------------------------

---Overlay search panel. Opened via Ctrl+F on a container with AllowSearch=true.
---Indexes the container's descendants (or uses a custom query handler) through
---the game's Search.* API, presents results as a navigable list, and jumps to
---the selected widget (or fires onActivate) on Enter.
---The default "terms" mode supports multi-term AND queries and "--term"
---exclusion syntax. "raw" mode sends the complete query to the handler or
---Search.Search once, which is useful for full-text indexes.
---Per-context search history is navigable with PageUp/PageDown in the edit box.
---Emits "search_open", "search_close", and "search_text_changed" events.
---@class SearchPanelWidget : PanelWidget
---@field _editBox EditBoxWidget
---@field _resultList ListWidget
---@field _targetContainer ContainerWidget
---@field _queryHandler? fun(query:string, maxResults:integer):table[]
---@field _queryMode "terms"|"raw"
---@field _contextReady boolean
---@field _historyContext string
---@field _historyIndex integer
SearchPanelWidget = {}

---@param container ContainerWidget
function SearchPanelWidget:Open(container) end

---@param skipFocusRestore? boolean
function SearchPanelWidget:Close(skipFocusRestore) end

---@param handler fun(query:string, maxResults:integer):table[]
function SearchPanelWidget:SetQueryHandler(handler) end

---@param mode "terms"|"raw"
function SearchPanelWidget:SetQueryMode(mode) end

---@param context string
function SearchPanelWidget:SetHistoryContext(context) end

---@param results table[]
function SearchPanelWidget:SetResults(results) end

-- -----------------------------------------------------------------------------
-- UIScreenManager
-- -----------------------------------------------------------------------------

---Manager singleton. Lives at ExposedMembers.CAI_UIManager.
---@class UIScreenManager
---@field Stack UIWidget[]
---@field CurrentPath UIWidget[]
---@field EnterKeyIsDown boolean Whether the manager has observed an unmatched Enter key-down.
---@field EnterKeyDownOwner? UIWidget Focused leaf that received the current Enter key-down.
---@field FocusRestoreKeyOverride? string Temporary logical target used during a synchronous action-driven rebuild.
---@field TypeToFindTarget? UIWidget Container that owns the persistent type-to-find session.
---@field CAISettings table<string, any>
---@field AudioManager CAIAudioManager|nil
---@field TutorialManager CAIUITutorialManager|nil
---@field TutorialCatalog CAIUITutorialCatalog|nil
---@field WidgetHelpers CAIWidgetHelpers Manager-bound quick widget helpers (dialog builders, etc.).
UIScreenManager = {}

---Manager-bound quick widget helpers. Populated at init by helper modules
---calling their Install(mgr). All entries are closures over the owning manager,
---so screens never need to thread `mgr` into builder calls.
---@class CAIWidgetHelpers
---@field MakeGeneralDialog fun(titleFn: fun():string, actionButtons: ButtonWidget[], contentRows?: UIWidget[], defaultActionIndex?: integer): DialogWidget|nil
---@field CreatePopupDialog fun(popup: table): DialogWidget|nil
CAIWidgetHelpers = {}

---Generate a unique widget id. Optional prefix; defaults to "CAIWidget".
---@param prefix? string
---@return string
function UIScreenManager:GenerateWidgetId(prefix) end

---Construct a widget via the registry.
---@param id string
---@param type string
---@param props? table
---@return UIWidget|nil
function UIScreenManager:CreateWidget(id, type, props) end

---Push a widget root onto the stack. opts.focus may be a widget or a FocusKey
---string; only applied when the pushed widget becomes the new top.
---@param w UIWidget
---@param opts? { priority?: PopupPriority, focus?: UIWidget|string }|PopupPriority
function UIScreenManager:Push(w, opts) end

---Pop the top of the stack.
---@return UIWidget|nil
function UIScreenManager:Pop() end

---Remove a specific widget root by id. Pass announce=false when a synchronous
---parent refresh will choose and announce the final return focus.
---@param id string
---@param announce? boolean
---@return UIWidget|nil
function UIScreenManager:RemoveFromStack(id, announce) end

---@return UIWidget|nil
function UIScreenManager:GetTop() end

---@return boolean
function UIScreenManager:IsEmpty() end

function UIScreenManager:Clear() end

---@return UIWidget|nil
function UIScreenManager:GetFocusedWidget() end

---Focus a widget. opts.direction (1 forward, -1 backward) controls container
---entry per Windows tab-stop convention. Omit direction for re-entry /
---programmatic focus, which uses the cached default child.
---@param widget UIWidget
---@param opts? boolean|{ direction?: 1|-1, announce?: boolean }
---@return boolean
function UIScreenManager:SetFocus(widget, opts) end

---Re-speak the current focus leaf without re-firing focus_enter/leave.
function UIScreenManager:Refocus() end

---@param root UIWidget
---@param key string
---@return UIWidget|nil
function UIScreenManager:FindByFocusKey(root, key) end

---Capture the current focus position under root for later restoration.
---@param root UIWidget
---@return FocusCapture|nil
function UIScreenManager:CaptureFocusKey(root) end

---Restore focus inside root from a capture token. Tries FocusKey, then index
---path, then first visible child.
---@param root UIWidget
---@param capture FocusCapture|nil
---@return boolean
function UIScreenManager:RestoreFocus(root, capture) end

---Called by UIWidget:Destroy; prunes CurrentPath silently.
---@param w UIWidget
function UIScreenManager:NotifyDestroy(w) end

---Clears any unmatched Enter key-down and its focus owner.
function UIScreenManager:CancelEnterKeyOwnership() end

---Clears Enter ownership when its recorded focus leaf is absent from path.
---@param path UIWidget[]
function UIScreenManager:CancelEnterKeyOwnershipOutsidePath(path) end

---@param input InputStruct
---@return boolean
function UIScreenManager:HandleInput(input) end

---@param char string
---@return boolean
function UIScreenManager:HandleCharInput(char) end

---@param id string
---@param recurse? boolean
---@return UIWidget|nil
function UIScreenManager:GetWidgetById(id, recurse) end

---@param c string
function UIScreenManager:AppendSearchChar(c) end

---@param target UIWidget
function UIScreenManager:BeginTypeToFind(target) end

---@return string
function UIScreenManager:GetSearchBuffer() end

---Open the Ctrl+F search overlay on a container. Applies the container's
---query handler and query mode to the shared SearchPanel before opening.
---@param container ContainerWidget
function UIScreenManager:OpenSearch(container) end

---@return SearchPanelWidget|nil
function UIScreenManager:GetSearchPanel() end

---@return CAIAudioManager|nil
function UIScreenManager:GetAudioManager() end

---@return CAIUITutorialManager|nil
function UIScreenManager:GetTutorialManager() end

function UIScreenManager:InitializeTutorialManager() end

function UIScreenManager:ShutdownTutorialManager() end

---@param source? table
---@param direction? integer
function UIScreenManager:HandleNavigationWrap(source, direction) end

-- -----------------------------------------------------------------------------
-- Widget registry
-- -----------------------------------------------------------------------------

---@class CAIWidgetRegistry
CAIWidgetRegistry = {}

---@param typeName string
---@param ctor fun(mgr:UIScreenManager, id:string, props?:table):UIWidget
function CAIWidgetRegistry.Register(typeName, ctor) end

---@param typeName string
---@return fun(mgr:UIScreenManager, id:string, props?:table):UIWidget|nil
function CAIWidgetRegistry.GetCtor(typeName) end

---Apply per-instance prop overrides; props with Set<Name> setters route through
---the setter, others assign directly.
---@param w UIWidget
---@param props table
function CAIWidgetRegistry.ApplyProps(w, props) end

-- -----------------------------------------------------------------------------
-- Dialog builder helper
-- -----------------------------------------------------------------------------

---Dialog builder module. Functions take the owning manager explicitly;
---screens should prefer the manager-bound versions on `mgr.WidgetHelpers`
---(installed by Install(mgr) at init).
---@class CAIWidgetHelpers_DialogBuilder
CAIWidgetHelpers_DialogBuilder = {}

---Bind dialog builder methods onto `mgr.WidgetHelpers`.
---@param mgr UIScreenManager
function CAIWidgetHelpers_DialogBuilder.Install(mgr) end

---@param mgr UIScreenManager
---@param titleFn fun():string
---@param actionButtons ButtonWidget[]
---@param contentRows? UIWidget[]
---@param defaultActionIndex? integer
---@return DialogWidget|nil
function CAIWidgetHelpers_DialogBuilder.MakeGeneralDialog(mgr, titleFn, actionButtons, contentRows, defaultActionIndex) end

---Wrap a vanilla PopupDialog instance, walking PopupControls to build matching
---CAI widgets.
---@param mgr UIScreenManager
---@param popup table
---@return DialogWidget|nil
function CAIWidgetHelpers_DialogBuilder.CreatePopupDialog(mgr, popup) end

--Candidate for type to find search
---@class SearchCandidate
---@field Widget UIWidget
---@field Label string
---@field LabelLower string
---@field Tooltip string
---@field TooltipLower string
---@field BFSIndex integer

---@class SearchWord
---@field Text string
---@field StartPos integer

---@class SearchResult
---@field Candidate SearchCandidate
---@field Tier integer
---@field SourceRank integer 0 for a label match, 1 for a tooltip-only match.
---@field MatchPosition integer
---@field LabelLength integer

---Lowercase ASCII A-Z only, leaving bytes >= 0x80 untouched. Locale-safe fold
---for type-to-find so multi-byte UTF-8 (e.g. CJK) is never corrupted.
---@param s string
---@return string
function CAIWidgetHelpers_Search.AsciiLower(s) end

---Classify one label against a query using the shared type-to-find tiers.
---@param label string
---@param query string
---@return SearchResult|nil
function CAIWidgetHelpers_Search.MatchSearchText(label, query) end

---Build a normalized candidate for a custom type-to-find candidate source.
---@param widget UIWidget
---@param label string
---@param bfsIndex integer
---@param tooltip? string
---@return SearchCandidate
function CAIWidgetHelpers_Search.MakeSearchCandidate(widget, label, bfsIndex, tooltip) end
