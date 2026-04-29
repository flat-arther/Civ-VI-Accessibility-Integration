include("caiUtils")
include("worldInfo")
include("UIScreenManager")
include("caiIngame")
include("WorldInput")

local INPUT_ACTION_STARTED = "Started"
local INPUT_ACTION_TRIGGERED = "Triggered"

local mgr = ExposedMembers.CAI_UIManager
local caiInfo = ExposedMembers.CAIInfo

local gamePanel = nil
local mainArea = nil
local gCurrentModeWidget = nil
local gCAISystemsInitialized = false

local ACTION_CURSOR_UP = Input.GetActionId("CAICursorMoveUp")
local ACTION_CURSOR_DOWN = Input.GetActionId("CAICursorMoveDown")
local ACTION_CURSOR_LEFT = Input.GetActionId("CAICursorMoveLeft")
local ACTION_CURSOR_RIGHT = Input.GetActionId("CAICursorMoveRight")
local ACTION_UNIT_PATH_INFO = Input.GetActionId("UnitPathInfo")
local ACTION_INTERFACE_PRIMARY = Input.GetActionId("InterfaceWidgetPrimaryAction")

-- ===========================================================================
-- UI overrides
-- ===========================================================================
local function GetCAICursorPlotId()
	if not CAICursor then return -1 end
	return CAICursor:GetPlotId()
end

local function GetCAICursorPlotCoord()
	local plotId = GetCAICursorPlotId()
	local plot = Map.GetPlotByIndex(plotId)
	if not plot then return -1, -1 end
	return plot:GetX(), plot:GetY()
end

local function InstallUIOverrides()
	UI = HijackTable(UI, {
		GetCursorPlotCoord = GetCAICursorPlotCoord,
		GetCursorPlotID = GetCAICursorPlotId,
	})
end

-- ===========================================================================
-- Shared input actions
-- ===========================================================================
local function MoveCursor(dx, dy)
	LuaEvents.CAICursorMoveRelative(dx, dy, true)
	return true
end

local function SpeakUnitPathInfo()
	local unit = UI.GetHeadSelectedUnit()
	if not unit then return false end

	local plot = UI.GetCursorPlotID()
	if not Map.IsPlot(plot) then return false end

	local info = caiInfo.BuildMovementPathInfo(unit, plot, true)
	if not info then return false end

	local lines = caiInfo.BuildMovementSpeech(info)
	if lines and #lines > 0 then
		Speak(table.concat(lines, ", "))
	end
	return true
end

---Input actions that are common to all interface widgets should go here.
---Action functions are passed the game view widget, then any event arguments.
---@type table<number, { Type: string, Action: fun(w:UIWidget, ...):boolean|nil }>
local SharedInputActions = {
	[ACTION_CURSOR_UP] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			return MoveCursor(0, 1)
		end,
	},
	[ACTION_CURSOR_DOWN] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			return MoveCursor(0, -1)
		end,
	},
	[ACTION_CURSOR_LEFT] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			return MoveCursor(-1, 0)
		end,
	},
	[ACTION_CURSOR_RIGHT] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			return MoveCursor(1, 0)
		end,
	},
	[ACTION_UNIT_PATH_INFO] = {
		Type = INPUT_ACTION_TRIGGERED,
		Action = function()
			return SpeakUnitPathInfo()
		end,
	},
}

-- ===========================================================================
-- Interface mode widgets
-- ===========================================================================
local interfaceWidgets = {
	[InterfaceModeTypes.MOVE_TO] = {
		Properties = {
			GetLabel = function()
				return Locale.Lookup("LOC_CAI_MOVEMENT_MODE")
			end,
			OnDestroy = function()
				Speak(Locale.Lookup("LOC_CAI_EXITED_MOVEMENT_MODE"))
			end,
			RegisterInputs = {
				{
					Key = Keys.VK_ESCAPE,
					MSG = KeyEvents.KeyUp,
					Action = function()
						OnMouseMoveToCancel()
						return true
					end,
				},
			},
		},
		InputActions = {
			[ACTION_INTERFACE_PRIMARY] = {
				Type = INPUT_ACTION_TRIGGERED,
				Action = function()
					OnMouseMoveToEnd()
					return true
				end,
			},
		},
	},
}

local function GetInterfaceWidgetData()
	return interfaceWidgets[UI.GetInterfaceMode()]
end

local function OnInterfaceChanged(oldMode, newMode)
	if not gamePanel or not mainArea then
		print("Error: CAI game view widget is nil")
		return
	end

	if gCurrentModeWidget then
		gCurrentModeWidget:Destroy()
		gCurrentModeWidget = nil
	end

	local newData = interfaceWidgets[newMode]
	if not newData then return end

	local mode = mgr:CreateUIWidget(
		mgr:GenerateWidgetId("CAIWorldInputInterfaceMode"),
		"InterfaceMode",
		newData.Properties
	)
	if not mode then return end

	gCurrentModeWidget = mode
	mainArea:AddChild(mode, true)
end

-- ===========================================================================
-- Input action dispatch
-- ===========================================================================
local function GetInputAction(actionId)
	local data = GetInterfaceWidgetData()
	if data and data.InputActions and data.InputActions[actionId] then
		return data.InputActions[actionId]
	end
	return SharedInputActions[actionId]
end

local function DispatchInputAction(actionId, actionType, ...)
	if not mainArea then return false end

	local action = GetInputAction(actionId)
	if not action or action.Type ~= actionType then return false end

	return action.Action(mainArea, ...)
end

local function OnCAIInputActionStarted(actionId, x, y)
	return DispatchInputAction(actionId, INPUT_ACTION_STARTED, x, y)
end

local function OnCAIInputActionTriggered(actionId)
	return DispatchInputAction(actionId, INPUT_ACTION_TRIGGERED)
end

-- ===========================================================================
-- Game view lifecycle
-- ===========================================================================
local function CreateGameViewWidgets()
	if not mgr then
		print("Error: ExposedMembers.CAI_UIManager is nil")
		return false
	end

	gamePanel = mgr:CreateUIWidget(
		mgr:GenerateWidgetId("CAIWorldInputPanel"),
		"Panel",
		{
			GetLabel = function()
				return Locale.Lookup("LOC_CAI_GAME_CONTAINER")
			end,
		}
	)
	if not gamePanel then
		print("Failed to create main game panel")
		return false
	end

	mainArea = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIWorldInputGameView"), "GameView")
	if not mainArea then
		print("Failed to create gameview widget")
		return false
	end

	gamePanel:AddChild(mainArea)
	ExposedMembers.CAI_MainGamePanel = gamePanel
	return true
end

local function SnapCursorToInitialSelection()
	local unit = UI.GetHeadSelectedUnit()
	if unit then
		LuaEvents.CAICursorSnapToUnit(unit)
	end
end

local function OnCAICursorMoved(x, y, plot)
	if plot then
		UI.LookAtPlot(plot)
	end
end

local function RegisterCAIEvents()
	Events.InterfaceModeChanged.Add(OnInterfaceChanged)
	Events.InputActionStarted.Add(OnCAIInputActionStarted)
	Events.InputActionTriggered.Add(OnCAIInputActionTriggered)
	LuaEvents.CAICursorMoved.Add(OnCAICursorMoved)
end

local function UnregisterCAIEvents()
	Events.InterfaceModeChanged.Remove(OnInterfaceChanged)
	Events.InputActionStarted.Remove(OnCAIInputActionStarted)
	Events.InputActionTriggered.Remove(OnCAIInputActionTriggered)
	LuaEvents.CAICursorMoved.Remove(OnCAICursorMoved)
end

local function InitializeCAIGameView()
	if gCAISystemsInitialized then return end
	if not CreateGameViewWidgets() then return end

	gCAISystemsInitialized = true
	mgr:Push(gamePanel)
	RegisterCAIEvents()
	SnapCursorToInitialSelection()
end

-- Vanilla subscribes this function to Events.LoadScreenClose. Keep using that
-- boundary so the world game view is not focused while the load screen is active.
OnLoadScreenClose = WrapFunc(OnLoadScreenClose, function(orig)
	orig()
	InitializeCAIGameView()
end)

-- ===========================================================================
-- Context hooks
-- ===========================================================================
OnInputHandler = WrapFunc(OnInputHandler, function(orig, inputStruct)
	if mgr then
		local handled = mgr:HandleInput(inputStruct)
		if handled then return handled end
	end
	return orig(inputStruct)
end)

OnShutdown = WrapFunc(OnShutdown, function(orig)
	UnregisterCAIEvents()
	if mgr then
		mgr:ShutDown()
	end
	orig()
end)

InstallUIOverrides()
ContextPtr:SetShutdown(OnShutdown)
ContextPtr:SetInputHandler(OnInputHandler, true)
