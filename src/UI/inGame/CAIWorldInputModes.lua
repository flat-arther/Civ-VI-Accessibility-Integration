include("CAIModSupport")
-- Interface-mode descriptors and construction with explicit native context dependencies.
CAIWorldInputModes = {}

function CAIWorldInputModes.Create(mgr, context)
	local ACTION_INTERFACE_PRIMARY = context.ACTION_INTERFACE_PRIMARY
	local INPUT_ACTION_TRIGGERED = context.INPUT_ACTION_TRIGGERED
	local CITY_MANAGEMENT_WIDGET_ID = context.CITY_MANAGEMENT_WIDGET_ID
	local ActivateCurrentMoveTarget = context.ActivateCurrentMoveTarget
	local OnPlacementKeyUp = context.OnPlacementKeyUp
	local OnMouseMoveToCancel = context.OnMouseMoveToCancel
	local OnMouseUnitRangeAttack = context.OnMouseUnitRangeAttack
	local CityRangeAttack = context.CityRangeAttack
	local DistrictRangeAttack = context.DistrictRangeAttack
	local UnitAirAttack = context.UnitAirAttack
	local OnWMDStrikeEnd = context.OnWMDStrikeEnd
	local OnICBMStrikeEnd = context.OnICBMStrikeEnd
	local CoastalRaid = context.CoastalRaid
	local AirUnitDeploy = context.AirUnitDeploy
	local AirUnitReBase = context.AirUnitReBase
	local FormCorps = context.FormCorps
	local FormArmy = context.FormArmy
	local UnitAirlift = context.UnitAirlift
	local UnitParadrop = context.UnitParadrop
	local PriorityTarget = context.PriorityTarget
	local DOSacrificeSelection = context.DOSacrificeSelection
	local PerformKillWeakerUnit = context.PerformKillWeakerUnit
	local PerformTransformUnit = context.PerformTransformUnit
	local PerformRestoreUnitMoves = context.PerformRestoreUnitMoves
	local PerformNavalGoldRaid = context.PerformNavalGoldRaid
	local BuildImprovementAdjacent = context.BuildImprovementAdjacent
	local MoveJump = context.MoveJump
	local OnMouseDistrictPlacementCancel = context.OnMouseDistrictPlacementCancel
	local OnMouseDistrictPlacementEnd = context.OnMouseDistrictPlacementEnd
	local OnMouseBuildingPlacementCancel = context.OnMouseBuildingPlacementCancel
	local OnMouseBuildingPlacementEnd = context.OnMouseBuildingPlacementEnd
	local IsSelectionAllowedAt = context.IsSelectionAllowedAt
	local IsTargetPlot = context.IsTargetPlot
	local INTERFACEMODE_CAPTURE_BOAT = context.INTERFACEMODE_CAPTURE_BOAT
	local INTERFACEMODE_SHORE_PARTY = context.INTERFACEMODE_SHORE_PARTY
	local INTERFACEMODE_SHORE_PARTY_EMBARK = context.INTERFACEMODE_SHORE_PARTY_EMBARK
	local INTERFACEMODE_DREAD_PIRATE_ACTIVE = context.INTERFACEMODE_DREAD_PIRATE_ACTIVE
	local INTERFACEMODE_PRIVATEER_ACTIVE = context.INTERFACEMODE_PRIVATEER_ACTIVE
	local INTERFACEMODE_HOARDER_ACTIVE = context.INTERFACEMODE_HOARDER_ACTIVE
	local g_unitCommandSubTypeNames = context.g_unitCommandSubTypeNames

	local function RunVanillaPlacementCancel()
		OnPlacementKeyUp({
			GetKey = function()
				return Keys.VK_ESCAPE
			end,
		})
	end

	local function CreateModeWidgetData(config)
		return {
			WidgetId = config.WidgetId or "CAIWorldInputTargetingMode",
			Properties = {
				GetLabel = function()
					if type(config.Label) == "function" then return config.Label() end
					return Locale.Lookup(config.Label)
				end,
				OnDestroy = function()
					Speak(Locale.Lookup(config.ExitLabel or "LOC_CAI_EXITED_TARGETING_MODE"))
				end,
				RegisterInputs = {
					{
						Key = Keys.VK_ESCAPE,
						MSG = KeyEvents.KeyUp,
						Description = config.CancelDescription or "LOC_CAI_KB_CANCEL_TARGETING",
						Action = function()
							if config.Cancel ~= nil then
								config.Cancel()
							else
								RunVanillaPlacementCancel()
							end
							return true
						end,
					},
				},
			},
			InputActions = config.Activate ~= nil and {
				[ACTION_INTERFACE_PRIMARY] = {
					Type = INPUT_ACTION_TRIGGERED,
					Action = function()
						local plotId = CAICursor:GetPlotId()
						local plot = Map.IsPlot(plotId) and Map.GetPlotByIndex(plotId) or nil
						local target = plot ~= nil and CAIInterfaceTargets.GetTargetAtPlot(plot, true) or nil
						if target == nil or (config.CanActivate ~= nil and not config.CanActivate(plot)) then
							Speak(Locale.Lookup("LOC_CAI_PLOT_INTERFACE_INVALID_TARGET"))
							return true
						end
						config.Activate()
						return true
					end,
				},
			} or nil,
		}
	end

	local function CreateTargetingWidgetData(labelKey, primaryAction, cancelAction)
		return CreateModeWidgetData({ Label = labelKey, Activate = primaryAction, Cancel = cancelAction })
	end

	local function CanUnitRangeAttack(plot)
		local unit = UI.GetHeadSelectedUnit()
		if unit == nil then return false end
		return UnitManager.CanStartOperation(unit, UnitOperationTypes.RANGE_ATTACK, nil, {
			[UnitOperationTypes.PARAM_X] = plot:GetX(),
			[UnitOperationTypes.PARAM_Y] = plot:GetY(),
		})
	end

	local function CanCityRangeAttack(subject, plot)
		if subject == nil then return false end
		return CityManager.CanStartCommand(subject, CityCommandTypes.RANGE_ATTACK, {
			[UnitOperationTypes.PARAM_X] = plot:GetX(),
			[UnitOperationTypes.PARAM_Y] = plot:GetY(),
		})
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
						Description = "LOC_CAI_KB_CANCEL_MOVEMENT",
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
		[InterfaceModeTypes.RANGE_ATTACK] = CreateModeWidgetData({
			Label = "LOC_CAI_RANGE_ATTACK_MODE", Activate = OnMouseUnitRangeAttack, CanActivate = CanUnitRangeAttack,
		}),
		[InterfaceModeTypes.CITY_RANGE_ATTACK] = CreateModeWidgetData({
			Label = "LOC_CAI_CITY_RANGE_ATTACK_MODE", Activate = CityRangeAttack,
			CanActivate = function(plot) return CanCityRangeAttack(UI.GetHeadSelectedCity(), plot) end,
		}),
		[InterfaceModeTypes.DISTRICT_RANGE_ATTACK] = CreateModeWidgetData({
			Label = "LOC_CAI_DISTRICT_RANGE_ATTACK_MODE", Activate = DistrictRangeAttack,
			CanActivate = function(plot) return CanCityRangeAttack(UI.GetHeadSelectedDistrict(), plot) end,
		}),
		[InterfaceModeTypes.AIR_ATTACK] = CreateTargetingWidgetData("LOC_CAI_AIR_ATTACK_MODE", UnitAirAttack),
		[InterfaceModeTypes.WMD_STRIKE] = CreateTargetingWidgetData("LOC_CAI_WMD_STRIKE_MODE", OnWMDStrikeEnd),
		[InterfaceModeTypes.ICBM_STRIKE] = CreateTargetingWidgetData("LOC_CAI_ICBM_STRIKE_MODE", OnICBMStrikeEnd),
		[InterfaceModeTypes.COASTAL_RAID] = CreateTargetingWidgetData("LOC_CAI_COASTAL_RAID_MODE", CoastalRaid),
		[InterfaceModeTypes.DEPLOY] = CreateTargetingWidgetData("LOC_CAI_DEPLOY_MODE", AirUnitDeploy),
		[InterfaceModeTypes.REBASE] = CreateTargetingWidgetData("LOC_CAI_REBASE_MODE", AirUnitReBase),
		[InterfaceModeTypes.FORM_CORPS] = CreateTargetingWidgetData("LOC_CAI_FORM_CORPS_MODE", FormCorps),
		[InterfaceModeTypes.FORM_ARMY] = CreateTargetingWidgetData("LOC_CAI_FORM_ARMY_MODE", FormArmy),
		[InterfaceModeTypes.AIRLIFT] = CreateTargetingWidgetData("LOC_CAI_AIRLIFT_MODE", UnitAirlift),
		[InterfaceModeTypes.PARADROP] = CreateTargetingWidgetData("LOC_CAI_PARADROP_MODE", UnitParadrop),
		[InterfaceModeTypes.PRIORITY_TARGET] = CreateTargetingWidgetData("LOC_CAI_PRIORITY_TARGET_MODE", PriorityTarget),
		[InterfaceModeTypes.SACRIFICE_SELECTION] = CreateTargetingWidgetData("LOC_CAI_SACRIFICE_SELECTION_MODE", DOSacrificeSelection),
		[InterfaceModeTypes.KILL_WEAKER_UNIT] = CreateTargetingWidgetData("LOC_CAI_KILL_WEAKER_UNIT_MODE", PerformKillWeakerUnit),
		[InterfaceModeTypes.TRANSFORM_UNIT] = CreateTargetingWidgetData("LOC_CAI_TRANSFORM_UNIT_MODE", PerformTransformUnit),
		[InterfaceModeTypes.RESTORE_UNIT_MOVES] = CreateTargetingWidgetData("LOC_CAI_RESTORE_UNIT_MOVES_MODE", PerformRestoreUnitMoves),
		[InterfaceModeTypes.NAVAL_GOLD_RAID] = CreateTargetingWidgetData("LOC_CAI_NAVAL_GOLD_RAID_MODE", PerformNavalGoldRaid),
		[InterfaceModeTypes.BUILD_IMPROVEMENT_ADJACENT] = CreateTargetingWidgetData(
			"LOC_CAI_BUILD_IMPROVEMENT_ADJACENT_MODE",
			BuildImprovementAdjacent),
		[InterfaceModeTypes.MOVE_JUMP] = CreateTargetingWidgetData("LOC_CAI_MOVE_JUMP_MODE", MoveJump),
		[InterfaceModeTypes.CITY_MANAGEMENT] = CreateModeWidgetData({
			WidgetId = CITY_MANAGEMENT_WIDGET_ID, Label = "LOC_HUD_CITY_MANAGE_CITIZENS",
		}),
		[InterfaceModeTypes.DISTRICT_PLACEMENT] = CreateModeWidgetData({
			WidgetId = "CAIWorldInputDistrictPlacementMode",
			Label = "LOC_CAI_DISTRICT_PLACEMENT_MODE",
			ExitLabel = "LOC_CAI_EXITED_DISTRICT_PLACEMENT_MODE",
			CancelDescription = "LOC_CAI_KB_CANCEL_PLACEMENT",
			Cancel = OnMouseDistrictPlacementCancel,
			Activate = OnMouseDistrictPlacementEnd,
			CanActivate = function(plot) return IsSelectionAllowedAt(plot:GetIndex()) end,
		}),
		[InterfaceModeTypes.BUILDING_PLACEMENT] = CreateModeWidgetData({
			WidgetId = "CAIWorldInputBuildingPlacementMode",
			Label = "LOC_CAI_WONDER_PLACEMENT_MODE",
			ExitLabel = "LOC_CAI_EXITED_WONDER_PLACEMENT_MODE",
			CancelDescription = "LOC_CAI_KB_CANCEL_PLACEMENT",
			Cancel = OnMouseBuildingPlacementCancel,
			Activate = OnMouseBuildingPlacementEnd,
			CanActivate = function(plot) return IsSelectionAllowedAt(plot:GetIndex()) end,
		}),
	}

	if CAIModSupport.IsCivRoyaleScenarioActive() then
		interfaceWidgets[InterfaceModeTypes.GRIEVING_GIFT] =
			CreateTargetingWidgetData("LOC_GRIEVING_GIFT_NAME", function()
				local plotId = CAICursor:GetPlotId()
				if not IsSelectionAllowedAt(plotId) then
					Speak(Locale.Lookup("LOC_CAI_PLOT_INTERFACE_INVALID_TARGET"))
					return
				end

				local plot = Map.GetPlotByIndex(plotId)
				local unit = UI.GetHeadSelectedUnit()
				if plot == nil or unit == nil then
					Speak(Locale.Lookup("LOC_CAI_PLOT_INTERFACE_INVALID_TARGET"))
					return
				end

				local parameters = {
					[UnitCommandTypes.PARAM_X] = plot:GetX(),
					[UnitCommandTypes.PARAM_Y] = plot:GetY(),
					[UnitCommandTypes.PARAM_NAME] = "ScenarioCommand_GrievingGift",
					CommandSubType = "GrievingGift",
				}
				UnitManager.RequestCommand(unit, UnitCommandTypes.EXECUTE_SCRIPT, parameters)
				UI.SetInterfaceMode(InterfaceModeTypes.SELECTION)
			end)
	end

	if CAIModSupport.IsPiratesScenarioActive() then
		local function GetPiratesModeLabel(tag)
			local tooltip = Locale.Lookup(tag)
			return tooltip:match("^(.-)%[NEWLINE%]") or tooltip
		end

		local function ActivatePiratesTarget(eventName, commandSubType)
			local plotId = CAICursor:GetPlotId()
			if not Map.IsPlot(plotId)
				or not IsSelectionAllowedAt(plotId)
				or not IsTargetPlot(plotId) then
				Speak(Locale.Lookup("LOC_CAI_PLOT_INTERFACE_INVALID_TARGET"))
				return
			end

			local plot = Map.GetPlotByIndex(plotId)
			local unit = UI.GetHeadSelectedUnit()
			if plot == nil or unit == nil then
				Speak(Locale.Lookup("LOC_CAI_PLOT_INTERFACE_INVALID_TARGET"))
				return
			end

			local parameters = {
				[UnitCommandTypes.PARAM_X] = plot:GetX(),
				[UnitCommandTypes.PARAM_Y] = plot:GetY(),
				[UnitCommandTypes.PARAM_NAME] = eventName,
				CommandSubType = commandSubType,
			}
			UnitManager.RequestCommand(unit, UnitCommandTypes.EXECUTE_SCRIPT, parameters)
			UI.SetInterfaceMode(InterfaceModeTypes.SELECTION)
		end

		local piratesModes = {
			{
				Mode = INTERFACEMODE_CAPTURE_BOAT,
				Label = "LOC_CAPTURE_BOAT_TOOLTIP",
				Event = "ScenarioCommand_CaptureBoat",
				SubType = g_unitCommandSubTypeNames.CAPTURE_BOAT,
			},
			{
				Mode = INTERFACEMODE_SHORE_PARTY,
				Label = "LOC_SHORE_PARTY_TOOLTIP",
				Event = "ScenarioCommand_ShoreParty",
				SubType = g_unitCommandSubTypeNames.SHORE_PARTY,
			},
			{
				Mode = INTERFACEMODE_SHORE_PARTY_EMBARK,
				Label = "LOC_SHORE_PARTY_EMBARK_TOOLTIP",
				Event = "ScenarioCommand_ShorePartyEmbark",
				SubType = g_unitCommandSubTypeNames.SHORE_PARTY_EMBARK,
			},
			{
				Mode = INTERFACEMODE_DREAD_PIRATE_ACTIVE,
				Label = "LOC_DREAD_PIRATE_UNIT_ACTIVE_TOOLTIP",
				Event = "ScenarioCommand_DreadPirateActive",
				SubType = g_unitCommandSubTypeNames.DREAD_PIRATE_ACTIVE,
			},
			{
				Mode = INTERFACEMODE_PRIVATEER_ACTIVE,
				Label = "LOC_PRIVATEER_UNIT_ACTIVE_TOOLTIP",
				Event = "ScenarioCommand_PrivateerActive",
				SubType = g_unitCommandSubTypeNames.PRIVATEER_ACTIVE,
			},
			{
				Mode = INTERFACEMODE_HOARDER_ACTIVE,
				Label = "LOC_HOARDER_UNIT_ACTIVE_TOOLTIP",
				Event = "ScenarioCommand_HoarderActive",
				SubType = g_unitCommandSubTypeNames.HOARDER_ACTIVE,
			},
		}

		for _, config in ipairs(piratesModes) do
			local current = config
			interfaceWidgets[current.Mode] = CreateTargetingWidgetData(
				function() return GetPiratesModeLabel(current.Label) end,
				function() ActivatePiratesTarget(current.Event, current.SubType) end)
		end
	end


	return {
		GetData = function(mode) return interfaceWidgets[mode] end,
		Build = function(mode)
			local data = interfaceWidgets[mode]
			if not data then return end
			return mgr:CreateWidget(data.WidgetId or "CAIWorldInputInterfaceMode", "InterfaceMode", data.Properties)
		end,
	}
end
