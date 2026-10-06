include("CAIWorldInputModes")
include("CAIWorldBuilderInput")
include("CAIPlotInteractions")
include("caiUtils")
include("Civ6Common")
include("InputSupport")
include("hexCoordUtils_CAI")
include("CAIUIScreenManager")
include("cursor_CAI")
include("cursorAudio_CAI")
include("inGameHelpers_CAI")
include("UnitWaypoints_CAI")
include("interfaceInfoHelpers_CAI")
include("RecommendationLogic_CAI")
include("WorldScanner_CAI")
include("Surveyor_CAI")
include("WorldBuilderVisManager_CAI")
include("RevealAnnouncements_CAI")
include("CAIUnitNumbers")
if IsExpansion2Active() then
	include("WorldClimateHistoryManager_CAI")
end
include("MessageBuffer_CAI")
include("UnitMoveLog_CAI")
include("EventSubs_CAI")
include("Civ6Common")

local mgr = CAI:GetUIManager()
local function GetWorldInputIncludeName()
	if GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_PIRATES" then
		return "WorldInput_PiratesScenario"
	end
	if GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_CIV_ROYALE" then
		return "WorldInput_CivRoyaleScenario"
	end
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
local CURSOR_LONG_JUMP_HEXES = 5
local CAMERA_WHOOSH_SOUND = "Camera_Whoosh"

local m_caiGameViewWidget = nil
local m_caiCurrentInterfaceWidget = nil
local m_caiWorldBuilderWidget = nil



local ACTION_MESSAGE_BUFFER_MOVETO = SafeActionId("MessageBufferMoveTo")
local ACTION_MESSAGE_BUFFER_PREVIOUS = SafeActionId("MessageBufferPrevious")
local ACTION_MESSAGE_BUFFER_NEXT = SafeActionId("MessageBufferNext")
local ACTION_MESSAGE_BUFFER_FIRST = SafeActionId("MessageBufferFirst")
local ACTION_MESSAGE_BUFFER_LAST = SafeActionId("MessageBufferLast")
local ACTION_MESSAGE_BUFFER_PREV_CATEGORY = SafeActionId("MessageBufferPreviousCategory")
local ACTION_MESSAGE_BUFFER_NEXT_CATEGORY = SafeActionId("MessageBufferNextCategory")
local ACTION_CURSOR_NORTHWEST = SafeActionId("CAICursorMoveNorthWest")
local ACTION_CURSOR_NORTHEAST = SafeActionId("CAICursorMoveNorthEast")
local ACTION_CURSOR_WEST = SafeActionId("CAICursorMoveWest")
local ACTION_CURSOR_EAST = SafeActionId("CAICursorMoveEast")
local ACTION_CURSOR_SOUTHWEST = SafeActionId("CAICursorMoveSouthWest")
local ACTION_CURSOR_SOUTHEAST = SafeActionId("CAICursorMoveSouthEast")
local ACTION_CURSOR_JUMP_TO_SELECTION = SafeActionId("CAICursorJumpToSelection")
local ACTION_CURSOR_JUMP_TO_CAPITAL = SafeActionId("CAICursorJumpToCapital")
local ACTION_QUICK_MOVE_NORTHWEST = SafeActionId("QuickMoveNorthWest")
local ACTION_QUICK_MOVE_NORTHEAST = SafeActionId("QuickMoveNorthEast")
local ACTION_QUICK_MOVE_WEST = SafeActionId("QuickMoveWest")
local ACTION_QUICK_MOVE_EAST = SafeActionId("QuickMoveEast")
local ACTION_QUICK_MOVE_SOUTHWEST = SafeActionId("QuickMoveSouthWest")
local ACTION_QUICK_MOVE_SOUTHEAST = SafeActionId("QuickMoveSouthEast")
local ACTION_INTERFACE_INFO = SafeActionId("InterfaceInfo")
local ACTION_INTERFACE_PRIMARY = SafeActionId("InterfaceWidgetPrimaryAction")
local ACTION_INTERFACE_SECONDARY = SafeActionId("InterfaceWidgetSecondaryAction")
local ACTION_SCANNER_PREV_CATEGORY = SafeActionId("WorldScannerPrevCategory")
local ACTION_SCANNER_NEXT_CATEGORY = SafeActionId("WorldScannerNextCategory")
local ACTION_SCANNER_PREV_SUBCATEGORY = SafeActionId("WorldScannerPrevSubCategory")
local ACTION_SCANNER_NEXT_SUBCATEGORY = SafeActionId("WorldScannerNextSubCategory")
local ACTION_SCANNER_PREV_GROUP = SafeActionId("WorldScannerPrevGroup")
local ACTION_SCANNER_NEXT_GROUP = SafeActionId("WorldScannerNextGroup")
local ACTION_SCANNER_PREV_ITEM = SafeActionId("WorldScannerPrevItem")
local ACTION_SCANNER_NEXT_ITEM = SafeActionId("WorldScannerNextItem")
local ACTION_SCANNER_JUMP = SafeActionId("WorldScannerJumpToCurrent")
local ACTION_SCANNER_RETURN = SafeActionId("WorldScannerReturnFromJump")
local ACTION_SCANNER_SPEAK_DIRECTION = SafeActionId("WorldScannerSpeakCurrentDirection")
local ACTION_SCANNER_SEARCH = SafeActionId("WorldScannerSearch")
local ACTION_SCANNER_SLOT1_ASSIGN = SafeActionId("WorldScannerSlot1Assign")
local ACTION_SCANNER_SLOT1_NEXT = SafeActionId("WorldScannerSlot1Next")
local ACTION_SCANNER_SLOT1_PREV = SafeActionId("WorldScannerSlot1Prev")
local ACTION_SCANNER_SLOT2_ASSIGN = SafeActionId("WorldScannerSlot2Assign")
local ACTION_SCANNER_SLOT2_NEXT = SafeActionId("WorldScannerSlot2Next")
local ACTION_SCANNER_SLOT2_PREV = SafeActionId("WorldScannerSlot2Prev")
local ACTION_SCANNER_SLOT3_ASSIGN = SafeActionId("WorldScannerSlot3Assign")
local ACTION_SCANNER_SLOT3_NEXT = SafeActionId("WorldScannerSlot3Next")
local ACTION_SCANNER_SLOT3_PREV = SafeActionId("WorldScannerSlot3Prev")
local ACTION_SCANNER_SLOT4_ASSIGN = SafeActionId("WorldScannerSlot4Assign")
local ACTION_SCANNER_SLOT4_NEXT = SafeActionId("WorldScannerSlot4Next")
local ACTION_SCANNER_SLOT4_PREV = SafeActionId("WorldScannerSlot4Prev")
local ACTION_SCANNER_SLOT5_ASSIGN = SafeActionId("WorldScannerSlot5Assign")
local ACTION_SCANNER_SLOT5_NEXT = SafeActionId("WorldScannerSlot5Next")
local ACTION_SCANNER_SLOT5_PREV = SafeActionId("WorldScannerSlot5Prev")
local ACTION_SURVEYOR_GROW_RADIUS = SafeActionId("SurveyorGrowRadius")
local ACTION_SURVEYOR_SHRINK_RADIUS = SafeActionId("SurveyorShrinkRadius")
local ACTION_SURVEYOR_READ_YIELDS = SafeActionId("SurveyorReadYields")
local ACTION_SURVEYOR_READ_RESOURCES = SafeActionId("SurveyorReadResources")
local ACTION_SURVEYOR_READ_TERRAIN = SafeActionId("SurveyorReadTerrain")
local ACTION_SURVEYOR_READ_OWN_UNITS = SafeActionId("SurveyorReadOwnUnits")
local ACTION_SURVEYOR_READ_ENEMY_UNITS = SafeActionId("SurveyorReadEnemyUnits")
local ACTION_SURVEYOR_READ_CITIES = SafeActionId("SurveyorReadCities")
local ACTION_SURVEYOR_READ_IMPROVEMENTS = SafeActionId("SurveyorReadImprovements")
local ACTION_SURVEYOR_READ_NEUTRAL_UNITS = SafeActionId("SurveyorReadNeutralUnits")
local ACTION_SURVEYOR_READ_OWNERSHIP = SafeActionId("SurveyorReadOwnership")
local ACTION_SURVEYOR_READ_DISTRICTS = SafeActionId("SurveyorReadDistricts")
local ACTION_SURVEYOR_READ_APPEAL = SafeActionId("SurveyorReadAppeal")
local ACTION_WORLD_SELECT_PREVIOUS_CITY = SafeActionId("WorldSelectPreviousCity_CAI")
local ACTION_WORLD_SELECT_NEXT_CITY = SafeActionId("WorldSelectNextCity_CAI")
local ACTION_WORLD_SELECT_CAPITAL_CITY = SafeActionId("WorldSelectCapitalCity_CAI")
local ACTION_PREV_UNIT_SELECTION = SafeActionId("PrevUnitSelection")
local ACTION_NEXT_UNIT_SELECTION = SafeActionId("NextUnitSelection")
local ACTION_PREV_READY_UNIT_SELECTION = SafeActionId("PrevReadyUnitSelection")
local ACTION_NEXT_READY_UNIT_SELECTION = SafeActionId("NextReadyUnitSelection")
-- ===========================================================================
-- Shared input actions
-- ===========================================================================
local function MoveCursor(direction)
	LuaEvents.CAICursorMoveDirection(direction)
	return true
end

local function GetObjectPlotIndex(object)
	if object == nil then return nil end

	local plot = Map.GetPlot(object:GetX(), object:GetY())
	if plot ~= nil then
		return plot:GetIndex()
	end

	return nil
end

local function JumpCursorToSelection()
	local unitPlotId = GetObjectPlotIndex(UI.GetHeadSelectedUnit())
	if unitPlotId ~= nil then
		LuaEvents.CAICursorMoveTo(unitPlotId, "jump")
		return true
	end

	local cityPlotId = GetObjectPlotIndex(UI.GetHeadSelectedCity())
	if cityPlotId ~= nil then
		LuaEvents.CAICursorMoveTo(cityPlotId, "jump")
		return true
	end

	return false
end

local function JumpCursorToCapital()
	local playerID = Game.GetLocalPlayer()
	if playerID == nil or playerID < 0 then return false end

	local player = Players[playerID]
	local cities = player ~= nil and player:GetCities() or nil
	local capital = cities ~= nil and cities:GetCapitalCity() or nil
	local capitalPlotId = GetObjectPlotIndex(capital)
	if capitalPlotId == nil then return false end

	LuaEvents.CAICursorMoveTo(capitalPlotId, "jump")
	return true
end

local function SelectCapitalCity()
	local playerID = Game.GetLocalPlayer()
	if playerID == nil or playerID < 0 then return false end

	local player = Players[playerID]
	local cities = player ~= nil and player:GetCities() or nil
	local capital = cities ~= nil and cities:GetCapitalCity() or nil
	if capital == nil then return false end

	UI.SelectCity(capital)
	UI.PlaySound("Play_UI_Click")
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

-- ===========================================================================
-- Plot interaction (Enter / Ctrl+Enter in SELECTION mode)
-- ===========================================================================
local plotInteractions = CAIPlotInteractions.Create(mgr, {
	GetPlotId = GetCurrentCAICursorPlotId,
	HasInterfaceWidget = function() return m_caiCurrentInterfaceWidget ~= nil end,
	IsPlotSelectionAllowed = function(plotId) return IsCAITutorialPlotSelectionAllowed(plotId) end,
	FormatUnitName = function(unit) return FormatOwnedUnitDisplayName(unit) end,
	SetAlwaysReceiveInput = function(enabled)
		if enabled then UITutorialManager:AddControlToAlwaysReceiveInput(ContextPtr)
		else UITutorialManager:RemoveControlToAlwaysReceiveInput(ContextPtr) end
	end,
})

local function SetCAIMapZoom(zoom)
	UI.SetMapZoom(zoom, 0.0, 0.0)
	local plotId = UI.GetCursorPlotID()
	local plot = plotId and Map.GetPlotByIndex(plotId)
	if plot == nil then
		LogWarn("CAI cannot recenter after zoom: cursor plot is unavailable")
		return
	end
	-- Snap to the current cursor tile to refresh positioned audio; zero preserves zoom.
	UI.LookAtPlot(plot:GetX(), plot:GetY(), 0, 0, true)
end

local function ChangeCAIMapZoom(delta)
	-- Native zoom increases away from the map; report closeness as a percentage.
	local zoom = math.max(0, math.min(1, UI.GetMapZoom() + delta))
	SetCAIMapZoom(zoom)
	UI.PlaySound("Play_UI_Click")
	-- The camera readback still reports the previous level immediately after setting it.
	Speak(Locale.Lookup("LOC_CAI_ZOOM_LEVEL", math.floor((1 - zoom) * 100 + 0.5)), true)
end

---Input actions that are common to all interface widgets should go here.
---Action functions are passed the game view widget, then any event arguments.
---@type table<number, { Type: string, Action: fun(w:UIWidget, ...):boolean|nil }>
local SharedInputActions = {
	[SafeActionId("CAIZoomIn")] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			ChangeCAIMapZoom(-0.05)
		end,
	},
	[SafeActionId("CAIZoomOut")] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			ChangeCAIMapZoom(0.05)
		end,
	},
	[ACTION_MESSAGE_BUFFER_MOVETO] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			local m_messageBuffer = MessageBuffer.GetActive()
			if not m_messageBuffer then return end
			m_messageBuffer:JumpToEntryLocation()
			return true
		end,
	},
	[ACTION_MESSAGE_BUFFER_PREVIOUS] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			local m_messageBuffer = MessageBuffer.GetActive()
			if not m_messageBuffer then return end
			m_messageBuffer:Previous()
			m_messageBuffer:SpeakEntry()
			return true
		end,
	},

	[ACTION_MESSAGE_BUFFER_NEXT] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			local m_messageBuffer = MessageBuffer.GetActive()
			if not m_messageBuffer then return end
			m_messageBuffer:Next()
			m_messageBuffer:SpeakEntry()
			return true
		end,
	},

	[ACTION_MESSAGE_BUFFER_FIRST] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			local m_messageBuffer = MessageBuffer.GetActive()
			if not m_messageBuffer then return end
			m_messageBuffer:JumpFirst()
			m_messageBuffer:SpeakEntry()
			return true
		end,
	},

	[ACTION_MESSAGE_BUFFER_LAST] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			local m_messageBuffer = MessageBuffer.GetActive()
			if not m_messageBuffer then return end
			m_messageBuffer:JumpLast()
			m_messageBuffer:SpeakEntry()
			return true
		end,
	},

	[ACTION_MESSAGE_BUFFER_PREV_CATEGORY] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			local m_messageBuffer = MessageBuffer.GetActive()
			if not m_messageBuffer then return end
			m_messageBuffer:CycleFilterBackward()
			m_messageBuffer:SpeakFilter()
			m_messageBuffer:SpeakEntry()
			return true
		end,
	},

	[ACTION_MESSAGE_BUFFER_NEXT_CATEGORY] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			local m_messageBuffer = MessageBuffer.GetActive()
			if not m_messageBuffer then return end
			m_messageBuffer:CycleFilterForward()
			m_messageBuffer:SpeakFilter()
			m_messageBuffer:SpeakEntry()
			return true
		end,
	},
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
	[ACTION_CURSOR_JUMP_TO_SELECTION] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			return JumpCursorToSelection()
		end,
	},
	[ACTION_CURSOR_JUMP_TO_CAPITAL] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			return JumpCursorToCapital()
		end,
	},
	[ACTION_WORLD_SELECT_PREVIOUS_CITY] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			LuaEvents.CAICycleSelectedCity(-1)
			return true
		end,
	},
	[ACTION_WORLD_SELECT_NEXT_CITY] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			LuaEvents.CAICycleSelectedCity(1)
			return true
		end,
	},
	[ACTION_WORLD_SELECT_CAPITAL_CITY] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			return SelectCapitalCity()
		end,
	},
	-- Unit cycling is owned by UnitPanel_CAI, which walks the unit list's
	-- remembered sort order. WorldInput only forwards the input actions.
	[ACTION_PREV_READY_UNIT_SELECTION] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			LuaEvents.CAICycleSelectedUnit(-1, true)
			return true
		end,
	},
	[ACTION_NEXT_READY_UNIT_SELECTION] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			LuaEvents.CAICycleSelectedUnit(1, true)
			return true
		end,
	},
	[ACTION_PREV_UNIT_SELECTION] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			LuaEvents.CAICycleSelectedUnit(-1, false)
			return true
		end,
	},
	[ACTION_NEXT_UNIT_SELECTION] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			LuaEvents.CAICycleSelectedUnit(1, false)
			return true
		end,
	},
	[ACTION_QUICK_MOVE_NORTHWEST] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			return MovementActions_CAI:TryQuickMoveDirection(DirectionTypes.DIRECTION_NORTHWEST)
		end,
	},
	[ACTION_QUICK_MOVE_NORTHEAST] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			return MovementActions_CAI:TryQuickMoveDirection(DirectionTypes.DIRECTION_NORTHEAST)
		end,
	},
	[ACTION_QUICK_MOVE_WEST] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			return MovementActions_CAI:TryQuickMoveDirection(DirectionTypes.DIRECTION_WEST)
		end,
	},
	[ACTION_QUICK_MOVE_EAST] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			return MovementActions_CAI:TryQuickMoveDirection(DirectionTypes.DIRECTION_EAST)
		end,
	},
	[ACTION_QUICK_MOVE_SOUTHWEST] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			return MovementActions_CAI:TryQuickMoveDirection(DirectionTypes.DIRECTION_SOUTHWEST)
		end,
	},
	[ACTION_QUICK_MOVE_SOUTHEAST] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			return MovementActions_CAI:TryQuickMoveDirection(DirectionTypes.DIRECTION_SOUTHEAST)
		end,
	},
	[ACTION_INTERFACE_INFO] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			return SpeakActiveInterfacePlotInfo()
		end,
	},
	[ACTION_INTERFACE_PRIMARY] = {
		Type = INPUT_ACTION_TRIGGERED,
		Action = function()
			if RaiseCurrentInterfaceWidgetAction(LuaEvents.CAIInterfaceWidgetPrimaryAction) then
				return true
			end
			return plotInteractions.Primary()
		end,
	},
	[ACTION_INTERFACE_SECONDARY] = {
		Type = INPUT_ACTION_TRIGGERED,
		Action = function()
			if RaiseCurrentInterfaceWidgetAction(LuaEvents.CAIInterfaceWidgetSecondaryAction) then
				return true
			end
			return plotInteractions.Secondary()
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
		Type = INPUT_ACTION_STARTED,
		Action = function()
			CAIWorldScanner:JumpToCurrent()
		end,
	},
	[ACTION_SCANNER_RETURN] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			CAIWorldScanner:ReturnFromJump()
		end,
	},
	[ACTION_SCANNER_SPEAK_DIRECTION] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			CAIWorldScanner:SpeakCurrentDirection()
		end,
	},
	[ACTION_SCANNER_SEARCH] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			CAIWorldScanner:OpenSearch()
		end,
	},
	[ACTION_SCANNER_SLOT1_ASSIGN] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			CAIWorldScanner:AssignSlot(1)
		end,
	},
	[ACTION_SCANNER_SLOT1_NEXT] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			CAIWorldScanner:CycleSlot(1, 1)
		end,
	},
	[ACTION_SCANNER_SLOT1_PREV] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			CAIWorldScanner:CycleSlot(1, -1)
		end,
	},
	[ACTION_SCANNER_SLOT2_ASSIGN] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			CAIWorldScanner:AssignSlot(2)
		end,
	},
	[ACTION_SCANNER_SLOT2_NEXT] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			CAIWorldScanner:CycleSlot(2, 1)
		end,
	},
	[ACTION_SCANNER_SLOT2_PREV] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			CAIWorldScanner:CycleSlot(2, -1)
		end,
	},
	[ACTION_SCANNER_SLOT3_ASSIGN] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			CAIWorldScanner:AssignSlot(3)
		end,
	},
	[ACTION_SCANNER_SLOT3_NEXT] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			CAIWorldScanner:CycleSlot(3, 1)
		end,
	},
	[ACTION_SCANNER_SLOT3_PREV] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			CAIWorldScanner:CycleSlot(3, -1)
		end,
	},
	[ACTION_SCANNER_SLOT4_ASSIGN] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			CAIWorldScanner:AssignSlot(4)
		end,
	},
	[ACTION_SCANNER_SLOT4_NEXT] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			CAIWorldScanner:CycleSlot(4, 1)
		end,
	},
	[ACTION_SCANNER_SLOT4_PREV] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			CAIWorldScanner:CycleSlot(4, -1)
		end,
	},
	[ACTION_SCANNER_SLOT5_ASSIGN] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			CAIWorldScanner:AssignSlot(5)
		end,
	},
	[ACTION_SCANNER_SLOT5_NEXT] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			CAIWorldScanner:CycleSlot(5, 1)
		end,
	},
	[ACTION_SCANNER_SLOT5_PREV] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			CAIWorldScanner:CycleSlot(5, -1)
		end,
	},
	-- Map-pin / minimap-list hotkeys (place pin, lens list, map-pin list) are
	-- owned by the map-tacks UI (MapPinListPanel_CAI), not WorldInput, so they can
	-- be gated off in World Builder and not collide with the WB cursor keys.
	[ACTION_SURVEYOR_GROW_RADIUS] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			return CAISurveyor.SpeakResult(CAISurveyor.GrowRadius)
		end,
	},
	[ACTION_SURVEYOR_SHRINK_RADIUS] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			return CAISurveyor.SpeakResult(CAISurveyor.ShrinkRadius)
		end,
	},
	[ACTION_SURVEYOR_READ_YIELDS] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			return CAISurveyor.SpeakResult(CAISurveyor.ReadYields)
		end,
	},
	[ACTION_SURVEYOR_READ_RESOURCES] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			return CAISurveyor.SpeakResult(CAISurveyor.ReadResources)
		end,
	},
	[ACTION_SURVEYOR_READ_TERRAIN] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			return CAISurveyor.SpeakResult(CAISurveyor.ReadTerrain)
		end,
	},
	[ACTION_SURVEYOR_READ_OWN_UNITS] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			return CAISurveyor.SpeakResult(CAISurveyor.ReadOwnUnits)
		end,
	},
	[ACTION_SURVEYOR_READ_ENEMY_UNITS] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			return CAISurveyor.SpeakResult(CAISurveyor.ReadEnemyUnits)
		end,
	},
	[ACTION_SURVEYOR_READ_CITIES] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			return CAISurveyor.SpeakResult(CAISurveyor.ReadCities)
		end,
	},
	[ACTION_SURVEYOR_READ_IMPROVEMENTS] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			return CAISurveyor.SpeakResult(CAISurveyor.ReadImprovements)
		end,
	},
	[ACTION_SURVEYOR_READ_NEUTRAL_UNITS] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			return CAISurveyor.SpeakResult(CAISurveyor.ReadNeutralUnits)
		end,
	},
	[ACTION_SURVEYOR_READ_OWNERSHIP] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			return CAISurveyor.SpeakResult(CAISurveyor.ReadOwnership)
		end,
	},
	[ACTION_SURVEYOR_READ_DISTRICTS] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			return CAISurveyor.SpeakResult(CAISurveyor.ReadDistricts)
		end,
	},
	[ACTION_SURVEYOR_READ_APPEAL] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			return CAISurveyor.SpeakResult(CAISurveyor.ReadAppeal)
		end,
	},
}

-- ===========================================================================
-- Interface mode widgets
-- ===========================================================================
local interfaceModes = CAIWorldInputModes.Create(mgr, {
	ACTION_INTERFACE_PRIMARY = ACTION_INTERFACE_PRIMARY,
	INPUT_ACTION_TRIGGERED = INPUT_ACTION_TRIGGERED,
	CITY_MANAGEMENT_WIDGET_ID = CITY_MANAGEMENT_WIDGET_ID,
	ActivateCurrentMoveTarget = ActivateCurrentMoveTarget,
	OnPlacementKeyUp = OnPlacementKeyUp,
	OnMouseMoveToCancel = OnMouseMoveToCancel,
	OnMouseUnitRangeAttack = OnMouseUnitRangeAttack,
	CityRangeAttack = CityRangeAttack,
	DistrictRangeAttack = DistrictRangeAttack,
	UnitAirAttack = UnitAirAttack,
	OnWMDStrikeEnd = OnWMDStrikeEnd,
	OnICBMStrikeEnd = OnICBMStrikeEnd,
	CoastalRaid = CoastalRaid,
	AirUnitDeploy = AirUnitDeploy,
	AirUnitReBase = AirUnitReBase,
	FormCorps = FormCorps,
	FormArmy = FormArmy,
	UnitAirlift = UnitAirlift,
	UnitParadrop = UnitParadrop,
	PriorityTarget = PriorityTarget,
	DOSacrificeSelection = DOSacrificeSelection,
	PerformKillWeakerUnit = PerformKillWeakerUnit,
	PerformTransformUnit = PerformTransformUnit,
	PerformRestoreUnitMoves = PerformRestoreUnitMoves,
	PerformNavalGoldRaid = PerformNavalGoldRaid,
	BuildImprovementAdjacent = BuildImprovementAdjacent,
	MoveJump = MoveJump,
	OnMouseDistrictPlacementCancel = OnMouseDistrictPlacementCancel,
	OnMouseDistrictPlacementEnd = OnMouseDistrictPlacementEnd,
	OnMouseBuildingPlacementCancel = OnMouseBuildingPlacementCancel,
	OnMouseBuildingPlacementEnd = OnMouseBuildingPlacementEnd,
	IsSelectionAllowedAt = IsSelectionAllowedAt,
	IsTargetPlot = IsTargetPlot,
	INTERFACEMODE_CAPTURE_BOAT = INTERFACEMODE_CAPTURE_BOAT,
	INTERFACEMODE_SHORE_PARTY = INTERFACEMODE_SHORE_PARTY,
	INTERFACEMODE_SHORE_PARTY_EMBARK = INTERFACEMODE_SHORE_PARTY_EMBARK,
	INTERFACEMODE_DREAD_PIRATE_ACTIVE = INTERFACEMODE_DREAD_PIRATE_ACTIVE,
	INTERFACEMODE_PRIVATEER_ACTIVE = INTERFACEMODE_PRIVATEER_ACTIVE,
	INTERFACEMODE_HOARDER_ACTIVE = INTERFACEMODE_HOARDER_ACTIVE,
	g_unitCommandSubTypeNames = g_unitCommandSubTypeNames,
})

local function GetInterfaceWidgetData()
	return interfaceModes.GetData(UI.GetInterfaceMode())
end

local function OnInterfaceChanged(oldMode, newMode)
	-- World Builder stays in WB_SELECT_PLOT and uses its own root widget; none of
	-- the gameplay targeting interface widgets apply.
	if m_caiWorldBuilderWidget then return end
	if not m_caiGameViewWidget then
		LogError("CAI WorldInput interface change failed because game view widget is nil")
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

	CAICursor:InvalidateCityScope()

	local mode = interfaceModes.Build(newMode)
	if not mode then return end

	m_caiCurrentInterfaceWidget = mode
	mgr:Push(mode)
	CAICursor:EnsureCityScopePosition()
end

local function OnCityScopeStateChanged()
	CAICursor:InvalidateCityScope()
	CAICursor:EnsureCityScopePosition()
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
	local root = m_caiGameViewWidget or m_caiWorldBuilderWidget
	if not root then return false end

	local action = GetInputAction(actionId)
	if not action or action.Type ~= actionType then return false end

	action.Action(root, ...)
	return true
end

local function OnCAIInputActionStarted(actionId, x, y)
	-- Suspended: CAI world actions stop reacting so the key falls to vanilla.
	if CAI.Active == false then return false end
	if CAI then CAI.Silence() end
	return DispatchInputAction(actionId, INPUT_ACTION_STARTED, x, y)
end

function OnInputActionTriggered(actionId)
	if CAI.Active == false then return end
	DispatchInputAction(actionId, INPUT_ACTION_TRIGGERED)
end

-- ===========================================================================
-- Game view lifecycle
-- ===========================================================================
local function CreateGameViewWidget()
	if not mgr then
		LogError("CAI WorldInput could not create game view widget because CAI:GetUIManager() is nil")
		return false
	end

	m_caiGameViewWidget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWorldInputGameView"), "GameView")
	if not m_caiGameViewWidget then
		LogError("CAI WorldInput failed to create game view widget")
		return false
	end

	return true
end

-- ===========================================================================
-- World Builder plot editing at the CAI cursor
-- ===========================================================================
-- Vanilla WorldBuilderPlacement.OnPlotSelected is a mouse-drag state machine
-- whose (plotID, edge, lbutton, rbutton) args are really drag-state flags, not
-- literal buttons. Replaying the exact LButton / RButton event sequences the
-- vanilla WorldInput fires performs one clean, undo-consistent edit at the
-- cursor plot. Brush size is read inside OnPlotSelected from placement's own
-- state (driven by the CAI tools panel via the brush buttons), so a place
-- honours the current brush automatically.
-- The plot edits act on: the locked mark when set, otherwise the live cursor.
local worldBuilderInput = CAIWorldBuilderInput.Create(mgr, {
	GetPlotId = GetCurrentCAICursorPlotId,
	GetCursor = function() return CAICursor end,
	GetScanner = function() return CAIWorldScanner end,
})

-- Keep cross-context and same-context readers bound to this load's controller.
function CAIWorldBuilderScannerSourcePlot()
	return worldBuilderInput.GetMarkedPlot()
end
CAI.Info = CAI:GetInfo() or {}
CAI:GetInfo().GetWorldBuilderMarkedPlot = worldBuilderInput.GetMarkedPlot

local function FindInitialPlotId()
	local playerID = Game.GetLocalPlayer()
	if playerID == nil or playerID < 0 then
		local fallback = Map.GetPlot(0, 0)
		return fallback and fallback:GetIndex() or nil
	end

	local unit = UI.GetHeadSelectedUnit()
	if unit then
		local plot = Map.GetPlot(unit:GetX(), unit:GetY())
		if plot then return plot:GetIndex() end
	end

	local city = UI.GetHeadSelectedCity()
	if city then
		local plot = Map.GetPlot(city:GetX(), city:GetY())
		if plot then return plot:GetIndex() end
	end

	local player = Players[playerID]
	if player then
		local cities = player:GetCities()
		if cities then
			local capital = cities:GetCapitalCity()
			if capital then
				local plot = Map.GetPlot(capital:GetX(), capital:GetY())
				if plot then return plot:GetIndex() end
			end
		end
	end

	local fallback = Map.GetPlot(0, 0)
	return fallback and fallback:GetIndex() or nil
end

local function SnapCursorToInitialPosition()
	local plotId = FindInitialPlotId()
	if plotId ~= nil then
		CAICursor:MoveTo(plotId, "snap")
	end
end

local function OnCAICursorMoved(state)
	local plotId = state.toPlotId
	if plotId == nil or plotId < 0 or not Map.IsPlot(plotId) then
		LogWarn("CAI WorldInput received invalid cursor plot id: " .. tostring(plotId))
		return
	end

	local plot = Map.GetPlotByIndex(plotId)
	if plot == nil then
		LogWarn("CAI WorldInput could not resolve cursor plot id: " .. tostring(plotId))
		return
	end

	worldBuilderInput.OnCursorMoved(state)

	-- Keep every cursor move instantaneous so jumps behave like directional steps.
	UI.LookAtPlot(plot:GetX(), plot:GetY(), 0, 0, true)
	if state.distance > CURSOR_LONG_JUMP_HEXES then
		UI.PlaySound(CAMERA_WHOOSH_SOUND)
	end
end

local function OnUnitSelectionChanged(playerID, unitID, hexI, hexJ, hexK, isSelected, isEditable)
	MovementActions_CAI:ClearReadyForCombat()
end

local function OnLocalPlayerTurnBegin()
	MovementActions_CAI:ClearReadyForCombat()
	MovementActions_CAI:ClearPendingMovementResult()
	CAIWorldScanner:OnLocalPlayerTurnBegin()
end

local function CheckInput()
	local focused = mgr:GetFocusedWidget()
	if focused == m_caiCurrentInterfaceWidget or focused == m_caiGameViewWidget or focused == m_caiWorldBuilderWidget then
		if Input.GetActiveContext() ~= InputContext.World then mgr:SetInputContext(InputContext.World) end
	end
end

local function OnUpdate()
	worldBuilderInput.Update()
	MovementActions_CAI:UpdatePendingMovementResult()
	UnitMoveLog_CAI.Update()
	RevealAnnouncements_CAI.UpdateVisibility()
	CheckInput()
	if mgr ~= nil then
		mgr:OnUpdate()
	end
end

local MESSAGE_BUFFER_SPEECH_SETTINGS = {
	notification = "SpeakMessageBufferNotifications",
	tutorial = "SpeakMessageBufferTutorials",
	reveal = "SpeakMessageBufferReveals",
	combat = "SpeakMessageBufferCombat",
	movement = "SpeakMessageBufferMovement",
	chat = "SpeakMessageBufferChat",
	gossip = "SpeakMessageBufferGossip",
}

local function OnCAIAppendToMessageBuffer(text, category, location, shouldSpeak)
	local m_messageBuffer = MessageBuffer.GetActive()
	if not m_messageBuffer then return end
	m_messageBuffer:Append(text, category, location)
	if shouldSpeak == false then return end
	local settingId = MESSAGE_BUFFER_SPEECH_SETTINGS[category]
	if settingId ~= nil and not CAISettings.GetBool(settingId) then
		return
	end
	Speak(text)
end

local function OnCAITutorialWorldAnchorChanged()
	CAIWorldScanner:RebuildCategory("tutorial")
end

local function RegisterCAIEvents()
	Events.InterfaceModeChanged.Add(OnInterfaceChanged)
	Events.CitySelectionChanged.Add(OnCityScopeStateChanged)
	Events.CityWorkerChanged.Add(OnCityScopeStateChanged)
	Events.CityMadePurchase.Add(OnCityScopeStateChanged)
	Events.CityTileOwnershipChanged.Add(OnCityScopeStateChanged)
	Events.LocalPlayerChanged.Add(OnCityScopeStateChanged)
	Events.InputActionStarted.Add(OnCAIInputActionStarted)
	Events.LocalPlayerTurnBegin.Add(OnLocalPlayerTurnBegin)
	Events.UnitSelectionChanged.Add(OnUnitSelectionChanged)
	LuaEvents.CAICursorMoved.Add(OnCAICursorMoved)
	LuaEvents.CAIAppendToMessageBuffer.Add(OnCAIAppendToMessageBuffer)
	LuaEvents.CAI_TutorialWorldAnchorChanged.Add(OnCAITutorialWorldAnchorChanged)
	LuaEvents.WorldBuilder_SetPlacementStatus.Add(worldBuilderInput.OnPlacementStatus)
	-- PlaceMapPin is a vanilla WorldInput global that only exists in this context;
	-- the map-tacks UI requests it across the context boundary via this LuaEvent.
	LuaEvents.CAIRequestPlaceMapPin.Add(PlaceMapPin)
	UnitMoveLog_CAI.Initialize()
	CAICursorAudio.Initialize()
	CAIRecommendationLogic.Initialize()
end

local function UnregisterCAIEvents()
	Events.InterfaceModeChanged.Remove(OnInterfaceChanged)
	Events.CitySelectionChanged.Remove(OnCityScopeStateChanged)
	Events.CityWorkerChanged.Remove(OnCityScopeStateChanged)
	Events.CityMadePurchase.Remove(OnCityScopeStateChanged)
	Events.CityTileOwnershipChanged.Remove(OnCityScopeStateChanged)
	Events.LocalPlayerChanged.Remove(OnCityScopeStateChanged)
	Events.InputActionStarted.Remove(OnCAIInputActionStarted)
	Events.InputActionTriggered.Remove(OnInputActionTriggered)
	Events.LocalPlayerTurnBegin.Remove(OnLocalPlayerTurnBegin)
	Events.UnitSelectionChanged.Remove(OnUnitSelectionChanged)
	LuaEvents.CAICursorMoved.Remove(OnCAICursorMoved)
	LuaEvents.CAIAppendToMessageBuffer.Remove(OnCAIAppendToMessageBuffer)
	LuaEvents.CAI_TutorialWorldAnchorChanged.Remove(OnCAITutorialWorldAnchorChanged)
	LuaEvents.WorldBuilder_SetPlacementStatus.Remove(worldBuilderInput.OnPlacementStatus)
	LuaEvents.CAIRequestPlaceMapPin.Remove(PlaceMapPin)
	UnitMoveLog_CAI.Shutdown()
	CAICursorAudio.Shutdown()
end



local function InitializeCAIGameView()
	if m_caiWorldBuilderWidget and mgr:GetWidgetById(m_caiWorldBuilderWidget:GetId()) then return end
	if m_caiGameViewWidget and mgr:GetWidgetById(m_caiGameViewWidget:GetId()) then return end

	-- this needs to sit below everything else. Priority must be low
	if WorldBuilder.IsActive() then
		m_caiWorldBuilderWidget = worldBuilderInput.Build()
		if not m_caiWorldBuilderWidget then return end
		mgr:Push(m_caiWorldBuilderWidget, PopupPriority.Low)
	else
		if not CreateGameViewWidget() then return end
		mgr:Push(m_caiGameViewWidget, PopupPriority.Low)
	end

	RegisterCAIEvents()
	SnapCursorToInitialPosition()
	CAIWorldScanner:Initialize()
	RevealAnnouncements_CAI.Initialize()
end

-- Vanilla subscribes this function to Events.LoadScreenClose. Keep using that
-- boundary so the world game view is not focused while the load screen is active.
OnLoadScreenClose = WrapFunc(OnLoadScreenClose, function(orig)
	orig()
	-- If this session loaded a World Builder map, LoadGameMenu injected CAI's
	-- ModDependencies row into that .Civ6Map so the session kept accessibility.
	-- The engine has now consumed the mod set, so strip the row back out to keep
	-- the on-disk map loadable by players without CAI. WBMapDepStrip lives in
	-- LoadSaveHelpers_CAI, which is not loaded in this context, so reach it
	-- through the SQLite bridge directly.
	local injectedPath = CAI.WorldBuilderInjectedMapPath
	if injectedPath then
		CAI.WorldBuilderInjectedMapPath = nil
		local api = CAI
		if api and api.OpenDatabase and api.Query and api.CloseDatabase then
			local ok, err = pcall(function()
				local handle, openErr = api.OpenDatabase(injectedPath)
				if not handle then
					print("CAI WBMapDep: could not open '" .. tostring(injectedPath) .. "': " .. tostring(openErr))
					return
				end
				local result = api.Query(handle,
					"DELETE FROM ModDependencies WHERE ID = ?",
					{ "9f4b5c2e-1a2b-4c3d-8e9f-123456789abc" })
				local changed = result and result.changed
				print("CAI WBMapDep: stripped loaded map '" .. tostring(injectedPath) ..
					"' (rows removed: " .. tostring(changed) .. ")")
				api.CloseDatabase(handle)
			end)
			if not ok then
				print("CAI WBMapDep: strip-on-load exception: " .. tostring(err))
			end
		end
	end
	-- Seed the World Builder visibility model from the freshly loaded map. The
	-- map's RevealedPlots table is only on disk (injectedPath), so read it here;
	-- a nil path (fresh map / uncaptured path) seeds an empty reveal set and
	-- relies on the Set Visibility tool + placed-unit sight instead. Also picks
	-- up any units/cities already on the loaded map for the sight computation.
	if WorldBuilder.IsActive() and CAI:GetWorldBuilderVisibilityManager() then
		CAI:GetWorldBuilderVisibilityManager().Seed(injectedPath)
	end
	InitializeCAIGameView()
	if CAI.Active ~= false then
		SetCAIMapZoom(0.0)
	end
end)

-- ===========================================================================
-- Context hooks
-- ===========================================================================
OnInputHandler = WrapFunc(OnInputHandler, function(orig, inputStruct)
	if ContextPtr:IsHidden() then return false end
	if mgr then
		local handled = mgr:HandleInput(inputStruct)
		if handled then return handled end
	end
	--if Input.GetActiveContext() ~= InputContext.World then return true end
	return orig(inputStruct)
end)

OnAppRegainedFocusHandler = WrapFunc(OnAppRegainedFocusHandler, function(orig)
	orig()
	mgr:TouchAppRegainedFocusTimer()
end)

OnShutdown = WrapFunc(OnShutdown, function(orig)
	UnregisterCAIEvents()
	MovementActions_CAI:ClearReadyForCombat()
	MovementActions_CAI:ClearPendingMovementResult()
	if CAIUnitWaypoints ~= nil and CAIUnitWaypoints.Shutdown ~= nil then
		CAIUnitWaypoints:Shutdown()
	end
	CAIRecommendationLogic.Shutdown()
	CAIWorldScanner:ClearScanner()
	RevealAnnouncements_CAI.Shutdown()
	if CAI:GetWorldBuilderVisibilityManager() ~= nil then
		CAI:GetWorldBuilderVisibilityManager().Reset()
	end
	if mgr then
		mgr:ShutDown()
	end
	orig()
end)

InstallUIOverrides()
ContextPtr:SetShutdown(OnShutdown)
ContextPtr:SetInputHandler(OnInputHandler, true)
ContextPtr:SetUpdate(OnUpdate)
ContextPtr:SetAppRegainedFocusHandler(OnAppRegainedFocusHandler);
