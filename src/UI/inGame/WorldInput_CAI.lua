include("caiUtils")
include ("worldInfo")
include("UIScreenManager")
include ("caiIngame");
include("WorldInput")
local mgr = ExposedMembers.CAI_UIManager
local gamePanel           = nil
local mainArea            = nil
local cursor              = nil
local caiInfo = ExposedMembers.CAIInfo

--# Global input actions
--- Input actions that are common to all interface widgets should go here. Action functions are passed the game view widget. You can use that to decide when the action should execute, or when to restrict certain actions
--- Most actions should only execute when the game view widget is focused; however, there might be exceptions
---@type table<number, fun(w:UIWidget)>
local SharedInputActions = {
	[Input.GetActionId("SharedEndTurn")] = function(w)
		LuaEvents.CAIEndTurn()
	end,
	[Input.GetActionId("UnitPathInfo")] = function(w)
		local unit = UI.GetHeadSelectedUnit()
		if not unit then return end
		local plot = cursor:GetPlotId()
		if not Map.IsPlot(plot) then return end
		local info = caiInfo.BuildMovementPathInfo(unit, plot, true)
		if not info then return end
		local lines = caiInfo.BuildMovementSpeech(info)
		local str
		if lines and #lines > 0 then str = table.concat(lines, ", ") end
		Speak(str)
	end,
}



--# Interface mode widgets
local gCurrentModeWidget = nil
interfaceWidgets = {
	[InterfaceModeTypes.MOVE_TO] = {
		Properties = {
			GetLabel = function() return Locale.Lookup("LOC_CAI_MOVEMENT_MODE") end,
			OnDestroy = function(w) Speak(Locale.Lookup("LOC_CAI_EXITED_MOVEMENT_MODE")) end,
			RegisterInputs = {
				{ Key = Keys.VK_ESCAPE, Action = function(w)
					OnMouseMoveToCancel()
					return true
				end, MSG = KeyEvents.KeyUp }
			},
		},
		InputActions = {
			[Input.GetActionId("InterfaceWidgetPrimaryAction")] = function(w)
				OnMouseMoveToEnd()
				return true
			end
		}
	}
}
--# Interface widget event listeners
function OnInterfaceChanged(old, new)
	if not gamePanel or not mainArea then
		print("Error: CAI game view widget is nil")
		return
	end
	if gCurrentModeWidget then
		gCurrentModeWidget:Destroy()
		gCurrentModeWidget = nil
	end
	local newData = interfaceWidgets[new]
	if newData then
		local mode = mgr:CreateUIWidget("InterfaceMode", newData.Properties)
		if mode then
			gCurrentModeWidget = mode
			mainArea:AddChild(mode, true)
		end
	end
end

function OnInputAction(actionId)
	if not mainArea then return false end
	local interface = UI.GetInterfaceMode()
	local data = interfaceWidgets[interface]
	local action = SharedInputActions[actionId]
	if data and data.InputActions then
		action = data.InputActions[actionId]
	end
	if action then
		return action(mainArea)
	end
	return false
end

function InitGameview()
	ContextPtr:SetInputHandler(function(input)
		return mgr:HandleInput(input, true)
	end, true)
	cursor = ExposedMembers.CAICursor
	if not cursor then
		print("CAI failed to init nav cursor")
		return
	end
	-- May decide to move these later, but for now we initialize this table here so it can be used across different contexts
	local cursorOverrides = {
		GetCursorPlotCoord = function()
			if not cursor then return -1, -1 end
			local plot = Map.GetPlotByIndex(cursor:GetPlotId())
			return plot:GetX(), plot:GetY()
		end,

		GetCursorPlotID = function()
			if not cursor then return -1 end
			return cursor:GetPlotId()
		end
	}
	ExposedMembers.CAICursorOverrides = cursorOverrides

	if not mgr then
		print("Error: ExposedMembers.CAI_UIManager is nil")
		return
	end
	gamePanel = mgr:CreateUIWidget("Panel",
		{
			GetLabel = function() return Locale.Lookup("LOC_CAI_GAME_CONTAINER") end
		})
	if not gamePanel then
		print("Failed to create main game panel")
	end
	mainArea = mgr:CreateUIWidget("GameView")
	if not mainArea then
		print("Failed to create gameview widget")
		return
	end
	gamePanel:AddChild(mainArea)
	mgr:Push(gamePanel)
	UI = HijackTable(UI, cursorOverrides)
end

OnLoadScreenClose = WrapFunc(OnLoadScreenClose, function(orig)
	orig()
	Events.InterfaceModeChanged.Add(OnInterfaceChanged)
	Events.InputActionTriggered.Add(OnInputAction)
	InitGameview()
	local unit = UI.GetHeadSelectedUnit()
	if not cursor then
		print("Cai failed to initialize cursor")
		return
	end
	if unit then
		cursor:SnapToUnit(unit)
	end
end)
