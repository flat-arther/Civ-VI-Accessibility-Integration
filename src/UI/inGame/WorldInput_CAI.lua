include("caiUtils")
include("navCursor")
include("inGameHelpers_CAI")
include("UnitWaypoints_CAI")
include("interfaceInfoHelpers_CAI")
include("UIScreenManager")
include("WorldScanner_CAI")
include("Surveyor_CAI")
include("RevealAnnouncements_CAI")
include("EventSubs_CAI")
include("Civ6Common")

local function GetWorldInputIncludeName()
	if IsExpansion2Active ~= nil and IsExpansion2Active() then
		return "WorldInput_Expansion2"
	end

	if IsExpansion1Active ~= nil and IsExpansion1Active() then
		return "WorldInput_Expansion1"
	end

	return "WorldInput"
end

include(GetWorldInputIncludeName())
include("MovementActions_CAI")

local INPUT_ACTION_STARTED = "Started"
local INPUT_ACTION_TRIGGERED = "Triggered"
local CITY_MANAGEMENT_WIDGET_ID = "CAIWorldInputCityManagement"

local mgr = ExposedMembers.CAI_UIManager
local m_caiGameViewWidget = nil
local m_caiCurrentInterfaceWidget = nil

local ACTION_CURSOR_NORTHWEST = Input.GetActionId("CAICursorMoveNorthWest")
local ACTION_CURSOR_NORTHEAST = Input.GetActionId("CAICursorMoveNorthEast")
local ACTION_CURSOR_WEST = Input.GetActionId("CAICursorMoveWest")
local ACTION_CURSOR_EAST = Input.GetActionId("CAICursorMoveEast")
local ACTION_CURSOR_SOUTHWEST = Input.GetActionId("CAICursorMoveSouthWest")
local ACTION_CURSOR_SOUTHEAST = Input.GetActionId("CAICursorMoveSouthEast")
local ACTION_QUICK_MOVE_NORTHWEST = Input.GetActionId("QuickMoveNorthWest")
local ACTION_QUICK_MOVE_NORTHEAST = Input.GetActionId("QuickMoveNorthEast")
local ACTION_QUICK_MOVE_WEST = Input.GetActionId("QuickMoveWest")
local ACTION_QUICK_MOVE_EAST = Input.GetActionId("QuickMoveEast")
local ACTION_QUICK_MOVE_SOUTHWEST = Input.GetActionId("QuickMoveSouthWest")
local ACTION_QUICK_MOVE_SOUTHEAST = Input.GetActionId("QuickMoveSouthEast")
local ACTION_INTERFACE_INFO = Input.GetActionId("InterfaceInfo")
local ACTION_INTERFACE_PRIMARY = Input.GetActionId("InterfaceWidgetPrimaryAction")
local ACTION_INTERFACE_SECONDARY = Input.GetActionId("InterfaceWidgetSecondaryAction")
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
local ACTION_SURVEYOR_GROW_RADIUS = Input.GetActionId("SurveyorGrowRadius")
local ACTION_SURVEYOR_SHRINK_RADIUS = Input.GetActionId("SurveyorShrinkRadius")
local ACTION_SURVEYOR_READ_YIELDS = Input.GetActionId("SurveyorReadYields")
local ACTION_SURVEYOR_READ_RESOURCES = Input.GetActionId("SurveyorReadResources")
local ACTION_SURVEYOR_READ_TERRAIN = Input.GetActionId("SurveyorReadTerrain")
local ACTION_SURVEYOR_READ_OWN_UNITS = Input.GetActionId("SurveyorReadOwnUnits")
local ACTION_SURVEYOR_READ_ENEMY_UNITS = Input.GetActionId("SurveyorReadEnemyUnits")
local ACTION_SURVEYOR_READ_CITIES = Input.GetActionId("SurveyorReadCities")
-- ===========================================================================
-- Shared input actions
-- ===========================================================================
local function MoveCursor(direction)
	LuaEvents.CAICursorMoveDirection(direction)
	return true
end

local function ActivateCurrentMoveTarget()
	local unit = UI.GetHeadSelectedUnit()
	local targetPlotId = UI.GetCursorPlotID()
	return MovementActions_CAI:TryActivateMoveTarget(unit, targetPlotId)
end

local function GetCurrentCAICursorPlotId()
	if CAICursor ~= nil and CAICursor.GetPlotId ~= nil then
		local plotId = CAICursor:GetPlotId()
		if plotId ~= nil then
			return plotId
		end
	end

	return UI.GetCursorPlotID()
end

local function RaiseCurrentInterfaceWidgetAction(luaEvent)
	if luaEvent == nil or m_caiCurrentInterfaceWidget == nil then
		return false
	end

	luaEvent(m_caiCurrentInterfaceWidget:GetId(), GetCurrentCAICursorPlotId())
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
	[ACTION_QUICK_MOVE_NORTHWEST] = {
		Type = INPUT_ACTION_TRIGGERED,
		Action = function()
			return MovementActions_CAI:TryQuickMoveDirection(DirectionTypes.DIRECTION_NORTHWEST)
		end,
	},
	[ACTION_QUICK_MOVE_NORTHEAST] = {
		Type = INPUT_ACTION_TRIGGERED,
		Action = function()
			return MovementActions_CAI:TryQuickMoveDirection(DirectionTypes.DIRECTION_NORTHEAST)
		end,
	},
	[ACTION_QUICK_MOVE_WEST] = {
		Type = INPUT_ACTION_TRIGGERED,
		Action = function()
			return MovementActions_CAI:TryQuickMoveDirection(DirectionTypes.DIRECTION_WEST)
		end,
	},
	[ACTION_QUICK_MOVE_EAST] = {
		Type = INPUT_ACTION_TRIGGERED,
		Action = function()
			return MovementActions_CAI:TryQuickMoveDirection(DirectionTypes.DIRECTION_EAST)
		end,
	},
	[ACTION_QUICK_MOVE_SOUTHWEST] = {
		Type = INPUT_ACTION_TRIGGERED,
		Action = function()
			return MovementActions_CAI:TryQuickMoveDirection(DirectionTypes.DIRECTION_SOUTHWEST)
		end,
	},
	[ACTION_QUICK_MOVE_SOUTHEAST] = {
		Type = INPUT_ACTION_TRIGGERED,
		Action = function()
			return MovementActions_CAI:TryQuickMoveDirection(DirectionTypes.DIRECTION_SOUTHEAST)
		end,
	},
	[ACTION_INTERFACE_INFO] = {
		Type = INPUT_ACTION_TRIGGERED,
		Action = function()
			return SpeakActiveInterfacePlotInfo()
		end,
	},
	[ACTION_INTERFACE_PRIMARY] = {
		Type = INPUT_ACTION_TRIGGERED,
		Action = function()
			return RaiseCurrentInterfaceWidgetAction(LuaEvents.CAIInterfaceWidgetPrimaryAction)
		end,
	},
	[ACTION_INTERFACE_SECONDARY] = {
		Type = INPUT_ACTION_TRIGGERED,
		Action = function()
			return RaiseCurrentInterfaceWidgetAction(LuaEvents.CAIInterfaceWidgetSecondaryAction)
		end,
	},
	[ACTION_SCANNER_PREV_CATEGORY] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			CAIWorldScanner:CycleCategory(-1)
		end,
	},
	[ACTION_SCANNER_NEXT_CATEGORY] = {
		Type = INPUT_ACTION_STARTED,
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
	[ACTION_SURVEYOR_GROW_RADIUS] = {
		Type = INPUT_ACTION_TRIGGERED,
		Action = function()
			return CAISurveyor.SpeakResult(CAISurveyor.GrowRadius)
		end,
	},
	[ACTION_SURVEYOR_SHRINK_RADIUS] = {
		Type = INPUT_ACTION_TRIGGERED,
		Action = function()
			return CAISurveyor.SpeakResult(CAISurveyor.ShrinkRadius)
		end,
	},
	[ACTION_SURVEYOR_READ_YIELDS] = {
		Type = INPUT_ACTION_TRIGGERED,
		Action = function()
			return CAISurveyor.SpeakResult(CAISurveyor.ReadYields)
		end,
	},
	[ACTION_SURVEYOR_READ_RESOURCES] = {
		Type = INPUT_ACTION_TRIGGERED,
		Action = function()
			return CAISurveyor.SpeakResult(CAISurveyor.ReadResources)
		end,
	},
	[ACTION_SURVEYOR_READ_TERRAIN] = {
		Type = INPUT_ACTION_TRIGGERED,
		Action = function()
			return CAISurveyor.SpeakResult(CAISurveyor.ReadTerrain)
		end,
	},
	[ACTION_SURVEYOR_READ_OWN_UNITS] = {
		Type = INPUT_ACTION_TRIGGERED,
		Action = function()
			return CAISurveyor.SpeakResult(CAISurveyor.ReadOwnUnits)
		end,
	},
	[ACTION_SURVEYOR_READ_ENEMY_UNITS] = {
		Type = INPUT_ACTION_TRIGGERED,
		Action = function()
			return CAISurveyor.SpeakResult(CAISurveyor.ReadEnemyUnits)
		end,
	},
	[ACTION_SURVEYOR_READ_CITIES] = {
		Type = INPUT_ACTION_TRIGGERED,
		Action = function()
			return CAISurveyor.SpeakResult(CAISurveyor.ReadCities)
		end,
	},
}

-- ===========================================================================
-- Interface mode widgets
-- ===========================================================================
local function RunVanillaPlacementCancel()
	OnPlacementKeyUp({
		GetKey = function()
			return Keys.VK_ESCAPE
		end,
	})
end

local function CreateTargetingWidgetData(labelKey, primaryAction, cancelAction)
	return {
		WidgetId = "CAIWorldInputTargetingMode",
		Properties = {
			GetLabel = function()
				return Locale.Lookup(labelKey)
			end,
			OnDestroy = function()
				Speak(Locale.Lookup("LOC_CAI_EXITED_TARGETING_MODE"))
			end,
			RegisterInputs = {
				{
					Key = Keys.VK_ESCAPE,
					MSG = KeyEvents.KeyUp,
					Action = function()
						if cancelAction ~= nil then
							cancelAction()
						else
							RunVanillaPlacementCancel()
						end
						return true
					end,
				},
			},
		},
		InputActions = {
			[ACTION_INTERFACE_PRIMARY] = {
				Type = INPUT_ACTION_TRIGGERED,
				Action = function()
					primaryAction()
					return true
				end,
			},
		},
	}
end

local interfaceWidgets = {
	[InterfaceModeTypes.MOVE_TO] = {
		WidgetId = "CAIWorldInputMoveToMode",
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
						MovementActions_CAI:ClearReadyForCombat()
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
					return ActivateCurrentMoveTarget()
				end,
			},
		},
	},
	[InterfaceModeTypes.RANGE_ATTACK] = CreateTargetingWidgetData("LOC_CAI_RANGE_ATTACK_MODE", function()
		OnMouseUnitRangeAttack()
	end),
	[InterfaceModeTypes.CITY_RANGE_ATTACK] = CreateTargetingWidgetData("LOC_CAI_CITY_RANGE_ATTACK_MODE", function()
		CityRangeAttack()
	end),
	[InterfaceModeTypes.DISTRICT_RANGE_ATTACK] = CreateTargetingWidgetData("LOC_CAI_DISTRICT_RANGE_ATTACK_MODE",
		function()
			DistrictRangeAttack()
		end),
	[InterfaceModeTypes.AIR_ATTACK] = CreateTargetingWidgetData("LOC_CAI_AIR_ATTACK_MODE", function()
		UnitAirAttack()
	end),
	[InterfaceModeTypes.WMD_STRIKE] = CreateTargetingWidgetData("LOC_CAI_WMD_STRIKE_MODE", function()
		OnWMDStrikeEnd()
	end),
	[InterfaceModeTypes.ICBM_STRIKE] = CreateTargetingWidgetData("LOC_CAI_ICBM_STRIKE_MODE", function()
		OnICBMStrikeEnd()
	end),
	[InterfaceModeTypes.COASTAL_RAID] = CreateTargetingWidgetData("LOC_CAI_COASTAL_RAID_MODE", function()
		CoastalRaid()
	end),
	[InterfaceModeTypes.DEPLOY] = CreateTargetingWidgetData("LOC_CAI_DEPLOY_MODE", function()
		AirUnitDeploy()
	end),
	[InterfaceModeTypes.REBASE] = CreateTargetingWidgetData("LOC_CAI_REBASE_MODE", function()
		AirUnitReBase()
	end),
	[InterfaceModeTypes.TELEPORT_TO_CITY] = CreateTargetingWidgetData("LOC_CAI_TELEPORT_TO_CITY_MODE", function()
		TeleportToCity()
	end),
	[InterfaceModeTypes.FORM_CORPS] = CreateTargetingWidgetData("LOC_CAI_FORM_CORPS_MODE", function()
		FormCorps()
	end),
	[InterfaceModeTypes.FORM_ARMY] = CreateTargetingWidgetData("LOC_CAI_FORM_ARMY_MODE", function()
		FormArmy()
	end),
	[InterfaceModeTypes.AIRLIFT] = CreateTargetingWidgetData("LOC_CAI_AIRLIFT_MODE", function()
		UnitAirlift()
	end),
	[InterfaceModeTypes.PARADROP] = CreateTargetingWidgetData("LOC_CAI_PARADROP_MODE", function()
		UnitParadrop()
	end),
	[InterfaceModeTypes.PRIORITY_TARGET] = CreateTargetingWidgetData("LOC_CAI_PRIORITY_TARGET_MODE", function()
		PriorityTarget()
	end),
	[InterfaceModeTypes.SACRIFICE_SELECTION] = CreateTargetingWidgetData("LOC_CAI_SACRIFICE_SELECTION_MODE", function()
		DOSacrificeSelection()
	end),
	[InterfaceModeTypes.KILL_WEAKER_UNIT] = CreateTargetingWidgetData("LOC_CAI_KILL_WEAKER_UNIT_MODE", function()
		PerformKillWeakerUnit()
	end),
	[InterfaceModeTypes.TRANSFORM_UNIT] = CreateTargetingWidgetData("LOC_CAI_TRANSFORM_UNIT_MODE", function()
		PerformTransformUnit()
	end),
	[InterfaceModeTypes.RESTORE_UNIT_MOVES] = CreateTargetingWidgetData("LOC_CAI_RESTORE_UNIT_MOVES_MODE", function()
		PerformRestoreUnitMoves()
	end),
	[InterfaceModeTypes.NAVAL_GOLD_RAID] = CreateTargetingWidgetData("LOC_CAI_NAVAL_GOLD_RAID_MODE", function()
		PerformNavalGoldRaid()
	end),
	[InterfaceModeTypes.BUILD_IMPROVEMENT_ADJACENT] = CreateTargetingWidgetData(
		"LOC_CAI_BUILD_IMPROVEMENT_ADJACENT_MODE",
		function()
			BuildImprovementAdjacent()
		end),
	[InterfaceModeTypes.MOVE_JUMP] = CreateTargetingWidgetData("LOC_CAI_MOVE_JUMP_MODE", function()
		MoveJump()
	end),
	[InterfaceModeTypes.CITY_MANAGEMENT] = {
		WidgetId = CITY_MANAGEMENT_WIDGET_ID,
		Properties = {
			GetLabel = function()
				return Locale.Lookup("LOC_HUD_CITY_MANAGE_CITIZENS")
			end,
			OnDestroy = function()
				Speak(Locale.Lookup("LOC_CAI_EXITED_TARGETING_MODE"))
			end,
			RegisterInputs = {
				{
					Key = Keys.VK_ESCAPE,
					MSG = KeyEvents.KeyUp,
					Action = function()
						RunVanillaPlacementCancel()
						return true
					end,
				},
			},
		},
	},
	[InterfaceModeTypes.DISTRICT_PLACEMENT] = {
		WidgetId = "CAIWorldInputDistrictPlacementMode",
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
		WidgetId = "CAIWorldInputBuildingPlacementMode",
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

	if oldMode == InterfaceModeTypes.MOVE_TO then
		MovementActions_CAI:ClearReadyForCombat()
	end

	if m_caiCurrentInterfaceWidget then
		-- We explicitly remove the widget by id just in case interface mode resets while we are in some other popup
		mgr:RemoveFromStack(m_caiCurrentInterfaceWidget:GetId())
		m_caiCurrentInterfaceWidget:Destroy()
		m_caiCurrentInterfaceWidget = nil
	end

	local newData = interfaceWidgets[newMode]
	if not newData then return end

	local widgetId = newData.WidgetId or "CAIWorldInputInterfaceMode"
	local mode = mgr:CreateUIWidget(widgetId, "InterfaceMode", newData.Properties)
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

	LuaEvents.CAICursorSnapToPlot(plot:GetIndex())
end

local function OnCAICursorMoved(x, y, plotId)
	if plotId == nil or plotId < 0 or not Map.IsPlot(plotId) then
		print("CAI WorldInput received invalid cursor plot id: " .. tostring(plotId))
		return
	end

	local plot = Map.GetPlotByIndex(plotId)
	if plot == nil then
		print("CAI WorldInput could not resolve cursor plot id: " .. tostring(plotId))
		return
	end

	UI.LookAtPlot(plot)
end

local function OnUnitSelectionChanged(playerID, unitID, hexI, hexJ, hexK, isSelected, isEditable)
	MovementActions_CAI:ClearReadyForCombat()
end

local function OnLocalPlayerTurnBegin()
	MovementActions_CAI:ClearReadyForCombat()
	MovementActions_CAI:ClearPendingMovementResult()
	CAIWorldScanner:OnLocalPlayerTurnBegin()
end

local function OnUpdate()
	MovementActions_CAI:UpdatePendingMovementResult()
	RevealAnnouncements_CAI.UpdateVisibility()
end

local function RegisterCAIEvents()
	Events.InterfaceModeChanged.Add(OnInterfaceChanged)
	Events.InputActionStarted.Add(OnCAIInputActionStarted)
	Events.InputActionTriggered.Add(OnCAIInputActionTriggered)
	Events.LocalPlayerTurnBegin.Add(OnLocalPlayerTurnBegin)
	Events.UnitSelectionChanged.Add(OnUnitSelectionChanged)
	LuaEvents.CAICursorMoved.Add(OnCAICursorMoved)
end

local function UnregisterCAIEvents()
	Events.InterfaceModeChanged.Remove(OnInterfaceChanged)
	Events.InputActionStarted.Remove(OnCAIInputActionStarted)
	Events.InputActionTriggered.Remove(OnCAIInputActionTriggered)
	Events.LocalPlayerTurnBegin.Remove(OnLocalPlayerTurnBegin)
	Events.UnitSelectionChanged.Remove(OnUnitSelectionChanged)
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
	MovementActions_CAI:ClearReadyForCombat()
	MovementActions_CAI:ClearPendingMovementResult()
	if CAIUnitWaypoints ~= nil and CAIUnitWaypoints.Shutdown ~= nil then
		CAIUnitWaypoints:Shutdown()
	end
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
