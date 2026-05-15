include("caiUtils")
include("navCursor")
include("interfaceInfoHelpers_CAI")
include("UIScreenManager")
include("WorldScanner_CAI")
include("RevealAnnouncements_CAI")
include("WorldInput")

local INPUT_ACTION_STARTED = "Started"
local INPUT_ACTION_TRIGGERED = "Triggered"

local mgr = ExposedMembers.CAI_UIManager
local m_caiGameViewWidget = nil
local m_caiCurrentInterfaceWidget = nil

local ACTION_CURSOR_NORTHWEST = Input.GetActionId("CAICursorMoveNorthWest")
local ACTION_CURSOR_NORTHEAST = Input.GetActionId("CAICursorMoveNorthEast")
local ACTION_CURSOR_WEST = Input.GetActionId("CAICursorMoveWest")
local ACTION_CURSOR_EAST = Input.GetActionId("CAICursorMoveEast")
local ACTION_CURSOR_SOUTHWEST = Input.GetActionId("CAICursorMoveSouthWest")
local ACTION_CURSOR_SOUTHEAST = Input.GetActionId("CAICursorMoveSouthEast")
local ACTION_INTERFACE_PRIMARY = Input.GetActionId("InterfaceWidgetPrimaryAction")
local ACTION_SCANNER_PREV_CATEGORY = Input.GetActionId("WorldScannerPrevCategory")
local ACTION_SCANNER_NEXT_CATEGORY = Input.GetActionId("WorldScannerNextCategory")
local ACTION_SCANNER_PREV_SUBCATEGORY = Input.GetActionId("WorldScannerPrevSubCategory")
local ACTION_SCANNER_NEXT_SUBCATEGORY = Input.GetActionId("WorldScannerNextSubCategory")
local ACTION_SCANNER_PREV_GROUP = Input.GetActionId("WorldScannerPrevGroup")
local ACTION_SCANNER_NEXT_GROUP = Input.GetActionId("WorldScannerNextGroup")
local ACTION_SCANNER_PREV_ITEM = Input.GetActionId("WorldScannerPrevItem")
local ACTION_SCANNER_NEXT_ITEM = Input.GetActionId("WorldScannerNextItem")
local ACTION_SCANNER_JUMP = Input.GetActionId("WorldScannerJumpToCurrent")
local ACTION_SCANNER_RETURN = Input.GetActionId("WorldScannerReturnFromJump")
local ACTION_SCANNER_SPEAK_DIRECTION = Input.GetActionId("WorldScannerSpeakCurrentDirection")
local ACTION_MINIMAP_LENS_LIST = Input.GetActionId("CAIMinimapOpenLensList")

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
local function MoveCursor(direction)
	LuaEvents.CAICursorMoveDirection(direction)
	return true
end

---Input actions that are common to all interface widgets should go here.
---Action functions are passed the game view widget, then any event arguments.
---@type table<number, { Type: string, Action: fun(w:UIWidget, ...):boolean|nil }>
local SharedInputActions = {
	[ACTION_CURSOR_NORTHWEST] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			return MoveCursor(DirectionTypes.DIRECTION_NORTHWEST)
		end,
	},
	[ACTION_CURSOR_NORTHEAST] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			return MoveCursor(DirectionTypes.DIRECTION_NORTHEAST)
		end,
	},
	[ACTION_CURSOR_WEST] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			return MoveCursor(DirectionTypes.DIRECTION_WEST)
		end,
	},
	[ACTION_CURSOR_EAST] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			return MoveCursor(DirectionTypes.DIRECTION_EAST)
		end,
	},
	[ACTION_CURSOR_SOUTHWEST] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			return MoveCursor(DirectionTypes.DIRECTION_SOUTHWEST)
		end,
	},
	[ACTION_CURSOR_SOUTHEAST] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			return MoveCursor(DirectionTypes.DIRECTION_SOUTHEAST)
		end,
	},
	[ACTION_SCANNER_PREV_CATEGORY] = {
		Type = INPUT_ACTION_TRIGGERED,
		Action = function()
			CAIWorldScanner:CycleCategory(-1)
		end,
	},
	[ACTION_SCANNER_NEXT_CATEGORY] = {
		Type = INPUT_ACTION_TRIGGERED,
		Action = function()
			CAIWorldScanner:CycleCategory(1)
		end,
	},
	[ACTION_SCANNER_PREV_SUBCATEGORY] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			CAIWorldScanner:CycleSubCategory(-1)
		end,
	},
	[ACTION_SCANNER_NEXT_SUBCATEGORY] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			CAIWorldScanner:CycleSubCategory(1)
		end,
	},
	[ACTION_SCANNER_PREV_GROUP] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			CAIWorldScanner:CycleGroup(-1)
		end,
	},
	[ACTION_SCANNER_NEXT_GROUP] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			CAIWorldScanner:CycleGroup(1)
		end,
	},
	[ACTION_SCANNER_PREV_ITEM] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			CAIWorldScanner:CycleItem(-1)
		end,
	},
	[ACTION_SCANNER_NEXT_ITEM] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			CAIWorldScanner:CycleItem(1)
		end,
	},
	[ACTION_SCANNER_JUMP] = {
		Type = INPUT_ACTION_TRIGGERED,
		Action = function()
			CAIWorldScanner:JumpToCurrent()
		end,
	},
	[ACTION_SCANNER_RETURN] = {
		Type = INPUT_ACTION_TRIGGERED,
		Action = function()
			CAIWorldScanner:ReturnFromJump()
		end,
	},
	[ACTION_SCANNER_SPEAK_DIRECTION] = {
		Type = INPUT_ACTION_TRIGGERED,
		Action = function()
			CAIWorldScanner:SpeakCurrentDirection()
		end,
	},
	[ACTION_MINIMAP_LENS_LIST] = {
		Type = INPUT_ACTION_TRIGGERED,
		Action = function()
			LuaEvents.CAIMinimapLensListToggle()
			return true
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
	[InterfaceModeTypes.DISTRICT_PLACEMENT] = {
		Properties = {
			GetLabel = function()
				return Locale.Lookup("LOC_CAI_DISTRICT_PLACEMENT_MODE")
			end,
			OnDestroy = function()
				Speak(Locale.Lookup("LOC_CAI_EXITED_DISTRICT_PLACEMENT_MODE"))
			end,
			RegisterInputs = {
				{
					Key = Keys.VK_ESCAPE,
					MSG = KeyEvents.KeyUp,
					Action = function()
						OnMouseDistrictPlacementCancel()
						return true
					end,
				},
			},
		},
		InputActions = {
			[ACTION_INTERFACE_PRIMARY] = {
				Type = INPUT_ACTION_TRIGGERED,
				Action = function()
					OnMouseDistrictPlacementEnd()
					return true
				end,
			},
		},
	},
	[InterfaceModeTypes.BUILDING_PLACEMENT] = {
		Properties = {
			GetLabel = function()
				return Locale.Lookup("LOC_CAI_WONDER_PLACEMENT_MODE")
			end,
			OnDestroy = function()
				Speak(Locale.Lookup("LOC_CAI_EXITED_WONDER_PLACEMENT_MODE"))
			end,
			RegisterInputs = {
				{
					Key = Keys.VK_ESCAPE,
					MSG = KeyEvents.KeyUp,
					Action = function()
						OnMouseBuildingPlacementCancel()
						return true
					end,
				},
			},
		},
		InputActions = {
			[ACTION_INTERFACE_PRIMARY] = {
				Type = INPUT_ACTION_TRIGGERED,
				Action = function()
					OnMouseBuildingPlacementEnd()
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
	if not m_caiGameViewWidget then
		print("Error: CAI game view widget is nil")
		return
	end

	if m_caiCurrentInterfaceWidget then
		-- We explicitly remove the widget by id just in case interface mode resets while we are in some other popup
		mgr:RemoveFromStack(m_caiCurrentInterfaceWidget:GetId())
		m_caiCurrentInterfaceWidget:Destroy()
		m_caiCurrentInterfaceWidget = nil
	end

	local newData = interfaceWidgets[newMode]
	if not newData then return end

	local mode = mgr:CreateUIWidget("CAIWorldInputInterfaceMode", "InterfaceMode", newData.Properties)
	if not mode then return end

	m_caiCurrentInterfaceWidget = mode
	mgr:Push(mode, PopupPriority.Medium)
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
	if not m_caiGameViewWidget then return false end

	local action = GetInputAction(actionId)
	if not action or action.Type ~= actionType then return false end

	action.Action(m_caiGameViewWidget, ...)
	return true
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
local function CreateGameViewWidget()
	if not mgr then
		print("Error: ExposedMembers.CAI_UIManager is nil")
		return false
	end

	m_caiGameViewWidget = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIWorldInputGameView"), "GameView")
	if not m_caiGameViewWidget then
		print("Failed to create gameview widget")
		return false
	end

	return true
end

local function SnapCursorToInitialCameraPosition()
	local worldX, worldY = UI.GetMapLookAtWorldTarget()
	if worldX == nil or worldY == nil then
		print("CAI cursor unable to read initial camera position")
		LuaEvents.CAICursorSnapToStartPlot()
		return
	end

	local plotX, plotY = UI.GetPlotCoordFromWorld(worldX, worldY)
	if plotX == nil or plotY == nil or plotX < 0 or plotY < 0 then
		print("CAI cursor unable to resolve initial camera plot: " .. tostring(worldX) .. ", " .. tostring(worldY))
		LuaEvents.CAICursorSnapToStartPlot()
		return
	end

	local plot = Map.GetPlot(plotX, plotY)
	if not plot then
		print("CAI cursor unable to resolve initial camera plot coordinates: " ..
			tostring(plotX) .. ", " .. tostring(plotY))
		LuaEvents.CAICursorSnapToStartPlot()
		return
	end

	LuaEvents.CAICursorSnapToPlot(plot)
end

local function OnCAICursorMoved(x, y, plot)
	if plot then
		UI.LookAtPlot(plot)
	end
end

local function OnLocalPlayerTurnBegin()
	CAIWorldScanner:OnLocalPlayerTurnBegin()
end

local function OnUpdate()
	RevealAnnouncements_CAI.UpdateVisibility()
end

local function RegisterCAIEvents()
	Events.InterfaceModeChanged.Add(OnInterfaceChanged)
	Events.InputActionStarted.Add(OnCAIInputActionStarted)
	Events.InputActionTriggered.Add(OnCAIInputActionTriggered)
	Events.LocalPlayerTurnBegin.Add(OnLocalPlayerTurnBegin)
	LuaEvents.CAICursorMoved.Add(OnCAICursorMoved)
end

local function UnregisterCAIEvents()
	Events.InterfaceModeChanged.Remove(OnInterfaceChanged)
	Events.InputActionStarted.Remove(OnCAIInputActionStarted)
	Events.InputActionTriggered.Remove(OnCAIInputActionTriggered)
	Events.LocalPlayerTurnBegin.Remove(OnLocalPlayerTurnBegin)
	LuaEvents.CAICursorMoved.Remove(OnCAICursorMoved)
end

local function InitializeCAIGameView()
	if not CreateGameViewWidget() then return end
	mgr:Push(m_caiGameViewWidget)
	RegisterCAIEvents()
	SnapCursorToInitialCameraPosition()
	CAIWorldScanner:Initialize()
	RevealAnnouncements_CAI.Initialize()
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
	CAIWorldScanner:ClearScanner()
	RevealAnnouncements_CAI.Shutdown()
	if mgr then
		mgr:ShutDown()
	end
	orig()
end)

InstallUIOverrides()
ContextPtr:SetShutdown(OnShutdown)
ContextPtr:SetInputHandler(OnInputHandler, true)
ContextPtr:SetUpdate(OnUpdate)
