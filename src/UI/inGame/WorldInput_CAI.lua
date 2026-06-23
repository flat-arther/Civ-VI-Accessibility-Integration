include("caiUtils")
include("CAIUIScreenManager")
include("navCursor")
include("inGameHelpers_CAI")
include("UnitWaypoints_CAI")
include("interfaceInfoHelpers_CAI")
include("RecommendationLogic_CAI")
include("WorldScanner_CAI")
include("Surveyor_CAI")
include("RevealAnnouncements_CAI")
include("EventSubs_CAI")
include("Civ6Common")

local mgr = ExposedMembers.CAI_UIManager
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
local ACTION_SCANNER_SEARCH = Input.GetActionId("WorldScannerSearch")
local ACTION_MINIMAP_LENS_LIST = Input.GetActionId("CAIMinimapOpenLensList")
local ACTION_MINIMAP_MAP_PIN_LIST = Input.GetActionId("CAIMinimapOpenMapPinList")
local ACTION_PLACE_MAP_PIN = Input.GetActionId("CAIPlaceMapPin")
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

-- ===========================================================================
-- Plot interaction (Enter / Ctrl+Enter in SELECTION mode)
-- ===========================================================================
local PLOT_INTERACT_LIST_ID = "CAIWorldInputPlotInteractList"

local function IsMinorCivPlayer(playerID)
	local config = PlayerConfigurations[playerID]
	if config == nil then return false end
	return config:GetCivilizationLevelTypeID() ~= CivilizationLevelTypes.CIVILIZATION_LEVEL_FULL_CIV
end

local function HasEspionageViewOnCity(ownerID, cityID)
	if not IsExpansion2Active() then return false end
	local localPlayerID = Game.GetLocalPlayer()
	if localPlayerID == nil or localPlayerID < 0 then return false end
	local pLocalPlayer = Players[localPlayerID]
	if pLocalPlayer == nil then return false end
	local pDiplo = pLocalPlayer:GetDiplomacy()
	if pDiplo == nil then return false end
	local eVisibility = pDiplo:GetVisibilityOn(ownerID)
	local kVisDef = GameInfo.Visibilities_XP2 and GameInfo.Visibilities_XP2[eVisibility] or nil
	if kVisDef == nil then return false end
	if kVisDef.EspionageViewAll == true then return true end
	if kVisDef.EspionageViewCapital == true then
		local pOwner = Players[ownerID]
		if pOwner ~= nil then
			local pCity = pOwner:GetCities():FindID(cityID)
			if pCity ~= nil and pCity:IsCapital() then return true end
		end
	end
	return false
end

local function CollectPlotInteractions(plotId)
	local results = {}
	if plotId == nil or plotId < 0 then return results end

	local plot = Map.GetPlotByIndex(plotId)
	if plot == nil then return results end

	local localPlayerID = Game.GetLocalPlayer()
	if localPlayerID == nil or localPlayerID < 0 then return results end

	local plotX = plot:GetX()
	local plotY = plot:GetY()

	local units = Units.GetUnitsInPlotLayerID(plotX, plotY, MapLayers.ANY)
	if units ~= nil then
		for _, unit in ipairs(units) do
			local ownerID = unit:GetOwner()
			if ownerID == localPlayerID then
				local unitName = FormatOwnedUnitDisplayName(unit) or Locale.Lookup("LOC_CAI_TILE_INTERACT_UNIT")
				table.insert(results, {
					Label = Locale.Lookup("LOC_CAI_TILE_INTERACT_SELECT_UNIT", unitName),
					Action = function()
						UI.DeselectAllUnits()
						UI.DeselectAllCities()
						UI.SelectUnit(unit)
					end,
				})
			end
		end
	end

	local city = CityManager.GetCityAt(plotX, plotY)
	if city ~= nil then
		local cityOwnerID = city:GetOwner()
		local cityID = city:GetID()
		local cityName = city:GetName()
		local displayName = cityName ~= nil and cityName ~= "" and Locale.Lookup(cityName) or
			Locale.Lookup("LOC_CAI_TILE_INTERACT_CITY")

		if cityOwnerID == localPlayerID then
			table.insert(results, {
				Label = Locale.Lookup("LOC_CAI_TILE_INTERACT_SELECT_CITY", displayName),
				Action = function()
					UI.SelectCity(city)
				end,
			})
		else
			local hasMet = false
			local pLocalPlayer = Players[localPlayerID]
			if pLocalPlayer ~= nil then
				local pDiplo = pLocalPlayer:GetDiplomacy()
				if pDiplo ~= nil then
					hasMet = pDiplo:HasMet(cityOwnerID)
				end
			end

			if hasMet then
				if IsMinorCivPlayer(cityOwnerID) then
					table.insert(results, {
						Label = Locale.Lookup("LOC_CAI_TILE_INTERACT_CITY_STATE", displayName),
						Action = function()
							LuaEvents.CityBannerManager_RaiseMinorCivPanel(cityOwnerID)
						end,
					})
					if HasEspionageViewOnCity(cityOwnerID, cityID) then
						table.insert(results, {
							Label = Locale.Lookup("LOC_CAI_TILE_INTERACT_VIEW_CITY", displayName),
							IsViewCity = true,
							Action = function()
								LuaEvents.CAIOpenOverviewForEnemyCity(cityOwnerID, cityID)
							end,
						})
					end
				else
					table.insert(results, {
						Label = Locale.Lookup("LOC_CAI_TILE_INTERACT_DIPLOMACY", displayName),
						Action = function()
							LuaEvents.CityBannerManager_TalkToLeader(cityOwnerID)
						end,
					})
					if HasEspionageViewOnCity(cityOwnerID, cityID) then
						table.insert(results, {
							Label = Locale.Lookup("LOC_CAI_TILE_INTERACT_VIEW_CITY", displayName),
							IsViewCity = true,
							Action = function()
								LuaEvents.CAIOpenOverviewForEnemyCity(cityOwnerID, cityID)
							end,
						})
					end
				end
			end
		end
	end

	local pLocalPlayer = Players[localPlayerID]
	if pLocalPlayer ~= nil then
		local districts = pLocalPlayer:GetDistricts()
		if districts ~= nil and districts.Members ~= nil then
			for _, district in districts:Members() do
				if district ~= nil then
					local dPlot = Map.GetPlot(district:GetX(), district:GetY())
					if dPlot ~= nil and dPlot:GetIndex() == plotId then
						if CityManager.CanStartCommand(district, CityCommandTypes.RANGE_ATTACK) then
							local districtDef = GameInfo.Districts[district:GetType()]
							local dName = districtDef ~= nil and districtDef.Name ~= nil and
								Locale.Lookup(districtDef.Name) or Locale.Lookup("LOC_CAI_TILE_INTERACT_DISTRICT")
							table.insert(results, {
								Label = Locale.Lookup("LOC_CAI_TILE_INTERACT_DISTRICT_STRIKE", dName),
								Action = function()
									UI.DeselectAll()
									UI.SelectDistrict(district)
									UI.SetInterfaceMode(InterfaceModeTypes.DISTRICT_RANGE_ATTACK)
								end,
							})
						end
					end
				end
			end
		end
	end

	return results
end

local function ExecutePlotInteraction(interaction)
	if interaction ~= nil and interaction.Action ~= nil then
		interaction.Action()
	end
end

local function DismissPlotInteractList()
	mgr:RemoveFromStack(PLOT_INTERACT_LIST_ID)
end

local function PushPlotInteractList(interactions)
	DismissPlotInteractList()

	local list = mgr:CreateWidget(PLOT_INTERACT_LIST_ID, "List", {
		GetLabel = function()
			return Locale.Lookup("LOC_CAI_TILE_INTERACT_LIST_TITLE")
		end,
	})
	if list == nil then return end

	list:AddInputBinding({
		Key = Keys.VK_ESCAPE,
		MSG = KeyEvents.KeyUp,
		Description = "LOC_CAI_KB_CLOSE",
		Action = function()
			DismissPlotInteractList()
			return true
		end,
	})

	for _, interaction in ipairs(interactions) do
		local btn = mgr:CreateWidget(mgr:GenerateWidgetId("TileInteract"), "Button", {
			Label = function() return interaction.Label end,
		})
		btn:On("activate", function()
			DismissPlotInteractList()
			ExecutePlotInteraction(interaction)
		end)
		list:AddChild(btn)
	end

	mgr:Push(list)
end

local function OnPlotPrimaryAction()
	if UI.GetInterfaceMode() ~= InterfaceModeTypes.SELECTION then return false end
	if m_caiCurrentInterfaceWidget ~= nil then return false end

	local plotId = GetCurrentCAICursorPlotId()
	local interactions = CollectPlotInteractions(plotId)
	if #interactions == 0 then
		Speak(Locale.Lookup("LOC_CAI_TILE_INTERACT_NO_ACTIONS"))
		return true
	end

	if #interactions == 1 then
		ExecutePlotInteraction(interactions[1])
	else
		PushPlotInteractList(interactions)
	end

	return true
end

local function FindViewCityInteraction(interactions)
	for _, interaction in ipairs(interactions) do
		if interaction.IsViewCity then
			return interaction
		end
	end
	return nil
end

local function OnPlotSecondaryAction()
	if UI.GetInterfaceMode() ~= InterfaceModeTypes.SELECTION then return false end
	if m_caiCurrentInterfaceWidget ~= nil then return false end

	local plotId = GetCurrentCAICursorPlotId()
	local interactions = CollectPlotInteractions(plotId)
	local viewCity = FindViewCityInteraction(interactions)
	if viewCity ~= nil then
		ExecutePlotInteraction(viewCity)
		return true
	end

	return false
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
			if RaiseCurrentInterfaceWidgetAction(LuaEvents.CAIInterfaceWidgetPrimaryAction) then
				return true
			end
			return OnPlotPrimaryAction()
		end,
	},
	[ACTION_INTERFACE_SECONDARY] = {
		Type = INPUT_ACTION_TRIGGERED,
		Action = function()
			if RaiseCurrentInterfaceWidgetAction(LuaEvents.CAIInterfaceWidgetSecondaryAction) then
				return true
			end
			return OnPlotSecondaryAction()
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
	[ACTION_SCANNER_SEARCH] = {
		Type = INPUT_ACTION_STARTED,
		Action = function()
			CAIWorldScanner:OpenSearch()
		end,
	},
	[ACTION_MINIMAP_LENS_LIST] = {
		Type = INPUT_ACTION_TRIGGERED,
		Action = function()
			LuaEvents.CAIMinimapLensListToggle()
			return true
		end,
	},
	[ACTION_MINIMAP_MAP_PIN_LIST] = {
		Type = INPUT_ACTION_TRIGGERED,
		Action = function()
			LuaEvents.CAIMinimapMapPinListToggle()
			return true
		end,
	},
	[ACTION_PLACE_MAP_PIN] = {
		Type = INPUT_ACTION_TRIGGERED,
		Action = function()
			PlaceMapPin()
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
					Description = "LOC_CAI_KB_CANCEL_TARGETING",
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
					Description = "LOC_CAI_KB_CANCEL_TARGETING",
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
					Description = "LOC_CAI_KB_CANCEL_PLACEMENT",
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
					Description = "LOC_CAI_KB_CANCEL_PLACEMENT",
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
	local mode = mgr:CreateWidget(widgetId, "InterfaceMode", newData.Properties)
	if not mode then return end

	m_caiCurrentInterfaceWidget = mode
	mgr:Push(mode)
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

	m_caiGameViewWidget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWorldInputGameView"), "GameView")
	if not m_caiGameViewWidget then
		print("Failed to create gameview widget")
		return false
	end

	return true
end

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
		print("CAI WorldInput received invalid cursor plot id: " .. tostring(plotId))
		return
	end

	local plot = Map.GetPlotByIndex(plotId)
	if plot == nil then
		print("CAI WorldInput could not resolve cursor plot id: " .. tostring(plotId))
		return
	end

	if state.reason == "step" then
		UI.LookAtPlot(plot:GetX(), plot:GetY(), 0, 0, true)
	else
		UI.LookAtPlot(plot)
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
	CAIRecommendationLogic.Initialize()
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
	SnapCursorToInitialPosition()
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
	CAIRecommendationLogic.Shutdown()
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
