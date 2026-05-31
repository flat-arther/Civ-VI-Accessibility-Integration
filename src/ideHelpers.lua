---@meta

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



---@class CAICursor
---@field curX integer The current X coordinate of the cursor.
---@field curY integer The current Y coordinate of the cursor.
---@field settings table<string, boolean> Configuration flags for cursor behavior.
CAICursor = {}

---Sets cursor coordinates to a given x and y.
---Triggers LuaEvents.CAICursorMoved.
---@param x integer
---@param y integer
function CAICursor:SetCoords(x, y) end

---Sets cursor coordinates from a plot id.
---@param plotId integer
function CAICursor:SetPlotId(plotId) end

---Moves to the next plot in the specified hex direction.
---@param dir DirectionTypes The direction index (0-5).
function CAICursor:MoveToNextPlot(dir) end

---Moves the cursor with jump semantics and direction speech.
---@param plotId integer
function CAICursor:JumpToPlotId(plotId) end

---Snaps the cursor coordinates to a specific unit's location.
---@param playerID integer
---@param unitID integer
function CAICursor:SnapToUnit(playerID, unitID) end

---Snaps the cursor coordinates to a specific plot id.
---@param plotId integer
function CAICursor:SnapToPlot(plotId) end

---Returns the unique Index of the plot currently under the cursor.
---@return integer # The plot index, or -1 if the plot is invalid.
function CAICursor:GetPlotId() end


---Public move API: call LuaEvents.CAICursorMove(x, y) to move the cursor.
---The cursor object remains local to the cursor API and should not be reached through ExposedMembers.

-- =============================================================================
-- CAI UI Manager — class and method annotations
-- =============================================================================

---Speak a string through the TTS pipeline.
---@param text string
---@param interrupt? boolean Interrupt any speech in flight. Default false.
function Speak(text, interrupt) end

---Speak each line in turn. When interrupt is true only the first line cuts
---ongoing speech; the rest queue so per-widget lines don't trample each other.
---@param lines string[]
---@param interrupt? boolean
function SpeakLines(lines, interrupt) end

---Names of events emitted by widgets via UIWidget:Emit(name, ...).
---@alias CAIWidgetEvent
---| "focus_enter"     # widget or a descendant became part of the current focus path
---| "focus_leave"     # widget left the focus path
---| "activate"        # button / menu item / tree-leaf activation
---| "value_changed"   # ValueWidget value changed (Toggle, Increment, EditBox Commit, SetValue without silent)
---| "expanded"        # TreeItem or SubMenu was expanded
---| "collapsed"       # TreeItem or SubMenu was collapsed
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

---One option in a Dropdown.
---@class DropdownOption
---@field label string
---@field value any

---One column in a TableWidget. `width` is the number of side-by-side tiers
---the column holds (default 1).
---@class TableColumn
---@field header string|fun():string
---@field width? integer

---Opaque value returned by Manager:CaptureFocusKey and consumed by RestoreFocus.
---@class FocusCapture
---@field key? string
---@field path integer[]

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
---("label","role","value","position","state","tooltip") to limit output.
---@param elements? string[]
---@return string|nil
function UIWidget:BuildSpeech(elements) end

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
---@class ContainerWidget : UIWidget
---@field WrapAround boolean
---@field PageSize integer
ContainerWidget = {}

---@param b boolean
function ContainerWidget:SetWrapAround(b) end

---@param n integer  set to 0 to disable PgUp/PgDn behavior on this container
function ContainerWidget:SetPageSize(n) end

---Default child for re-entry / programmatic focus. Resolution:
---  1. _lastFocusedKey (by FocusKey)  2. _lastFocusedChild (widget ref)
---  3. DefaultIndex  4. First visible
---@return UIWidget|nil
function ContainerWidget:GetDefaultChild() end

---Direction-aware entry: 1=first visible, -1=last visible, nil/0=default.
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
---@param n number
function SliderWidget:SetMin(n) end
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
---Normalizes [NEWLINE]/\r\n, runs ProcessIcons, then SetValue.
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
---@param b boolean
function EditBoxWidget:SetPasswordMask(b) end
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

---Three-level table: Table -> Column -> Tier -> item cell. A column speaks
---only its header label (role/position muted) and owns its cells through
---tiers, so the column header is announced when focus crosses into it.
---@class TableWidget : ContainerWidget
TableWidget = {}
---Append a column holding `width` side-by-side tiers. Returns the column widget.
---@param col TableColumn
---@return ContainerWidget column
function TableWidget:AddColumn(col) end
---@return integer
function TableWidget:GetColumnCount() end
---@param i integer
---@return ContainerWidget|nil
function TableWidget:GetColumnWidget(i) end
---@param column ContainerWidget|integer
---@param tierIndex? integer
---@return ContainerWidget|nil
function TableWidget:GetTier(column, tierIndex) end
---Append an item cell to a column's tier (vertical stack).
---@param column ContainerWidget|integer
---@param tierIndex integer|nil
---@param widget UIWidget
---@return integer itemIndex
function TableWidget:AddItem(column, tierIndex, widget) end
---Grid convenience: one cell into each column's first tier, in column order.
---@param cells (UIWidget|nil)[]
---@return integer rowIndex
function TableWidget:AddRow(cells) end
---@param row integer
---@param col integer
---@param widget UIWidget|nil
function TableWidget:SetCell(row, col, widget) end
---@param row integer
---@param col integer
---@return UIWidget|nil
function TableWidget:GetCell(row, col) end
---@return integer
function TableWidget:GetRowCount() end
---@param row integer
function TableWidget:RemoveRow(row) end
function TableWidget:ClearRows() end

---@class GameViewWidget : ContainerWidget
GameViewWidget = {}

---@class InterfaceModeWidget : ContainerWidget
InterfaceModeWidget = {}

-- -----------------------------------------------------------------------------
-- UIScreenManager
-- -----------------------------------------------------------------------------

---Manager singleton. Lives at ExposedMembers.CAI_UIManager.
---@class UIScreenManager
---@field Stack UIWidget[]
---@field CurrentPath UIWidget[]
---@field CAISettings table<string, any>
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

---Remove a specific widget root by id.
---@param id string
---@return UIWidget|nil
function UIScreenManager:RemoveFromStack(id) end

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

---@return string
function UIScreenManager:GetSearchBuffer() end

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
