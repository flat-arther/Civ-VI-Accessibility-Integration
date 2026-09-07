include("caiUtils")
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
include("WorldClimateHistoryManager_CAI")
include("MessageBuffer_CAI")
include("UnitMoveLog_CAI")
include("EventSubs_CAI")
include("Civ6Common")

local mgr = ExposedMembers.CAI_UIManager
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

local m_caiGameViewWidget = nil
local m_caiCurrentInterfaceWidget = nil
local m_caiWorldBuilderWidget = nil

-- World Builder: an optional locked placement source. When set, place/edit/remove
-- act on this plot instead of the live cursor, so the cursor can roam to inspect
-- other tiles (e.g. read placement validity) without moving where edits land.
local m_wbMarkedPlotId = nil


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

local function IsCityCenterDistrict(district)
	return district ~= nil and district:GetType() == GameInfo.Districts["DISTRICT_CITY_CENTER"].Index
end

-- Mirrors the missile silo (WMD) city banner: a nuclear strike action per WMD type
-- the local player has stockpiled and can currently fire from this silo. See vanilla
-- CityBanner:UpdateWMDBanner / OnICBMStrikeButtonClick in CityBannerManager.lua.
local function CollectMissileSiloInteractions(results, plot, plotX, plotY, localPlayerID)
	local improvementIndex = plot:GetImprovementType()
	if improvementIndex == nil or improvementIndex < 0 then return end
	local improvementInfo = GameInfo.Improvements[improvementIndex]
	if improvementInfo == nil or improvementInfo.WeaponSlots == nil or improvementInfo.WeaponSlots == 0 then
		return
	end

	local pCity = Cities.GetPlotPurchaseCity(plotX, plotY)
	if pCity == nil or pCity:GetOwner() ~= localPlayerID then return end

	local improvementName = improvementInfo.Name ~= nil and Locale.Lookup(improvementInfo.Name) or
		Locale.Lookup("LOC_CAI_TILE_INTERACT_MISSILE_SILO")

	local pLocalPlayer = Players[localPlayerID]
	if pLocalPlayer == nil then return end
	local playerWMDs = pLocalPlayer:GetWMDs()
	if playerWMDs == nil then return end

	local strikeLabels = {
		WMD_NUCLEAR_DEVICE = "LOC_CAI_TILE_INTERACT_NUCLEAR_STRIKE",
		WMD_THERMONUCLEAR_DEVICE = "LOC_CAI_TILE_INTERACT_THERMONUCLEAR_STRIKE",
	}

	for entry in GameInfo.WMDs() do
		local labelTag = strikeLabels[entry.WeaponType]
		if labelTag ~= nil and playerWMDs:GetWeaponCount(entry.Index) > 0 then
			local tParameters = {}
			tParameters[CityCommandTypes.PARAM_WMD_TYPE] = entry.Index
			tParameters[CityCommandTypes.PARAM_X0] = plotX
			tParameters[CityCommandTypes.PARAM_Y0] = plotY
			local tResults = CityManager.GetCommandTargets(pCity, CityCommandTypes.WMD_STRIKE, tParameters)
			if tResults ~= nil and tResults[CityCommandResults.PLOTS] ~= nil then
				local eWMD = entry.Index
				table.insert(results, {
					Label = Locale.Lookup(labelTag, improvementName),
					Action = function()
						-- Force recalculation of reachable area if we're already in strike mode.
						if UI.GetInterfaceMode() == InterfaceModeTypes.ICBM_STRIKE then
							UI.SetInterfaceMode(InterfaceModeTypes.SELECTION)
						end
						UI.SelectCity(pCity)
						UILens.SetActive("Default")
						local tStrikeParameters = {}
						tStrikeParameters[CityCommandTypes.PARAM_WMD_TYPE] = eWMD
						tStrikeParameters[CityCommandTypes.PARAM_X0] = plotX
						tStrikeParameters[CityCommandTypes.PARAM_Y0] = plotY
						UI.SetInterfaceMode(InterfaceModeTypes.ICBM_STRIKE, tStrikeParameters)
					end,
				})
			end
		end
	end
end

local function CollectPlotInteractions(plotId)
	local results = {}
	if plotId == nil or plotId < 0 then return results end

	local plot = Map.GetPlotByIndex(plotId)
	if plot == nil then return results end
	if not IsCAITutorialPlotSelectionAllowed(plotId) then return results end

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

		if CityManager.CanStartCommand(city, CityCommandTypes.RANGE_ATTACK) then
			table.insert(results, {
				Label = Locale.Lookup("LOC_CAI_TILE_INTERACT_DISTRICT_STRIKE", cityName),
				Action = function()
					UI.SelectCity(city)
					UI.SetInterfaceMode(InterfaceModeTypes.CITY_RANGE_ATTACK)
				end,
			})
		end
	end

	if GameConfiguration.GetValue("GAMEMODE_BARBARIAN_CLANS") then
		local improvementIndex = plot:GetImprovementType()
		local improvementInfo = improvementIndex ~= nil and GameInfo.Improvements[improvementIndex]

		if improvementInfo ~= nil and improvementInfo.ImprovementType == "IMPROVEMENT_BARBARIAN_CAMP" then
			local observer = Game.GetLocalObserver()
			local vis = PlayersVisibility[observer]

			if observer == PlayerTypes.OBSERVER or (vis and vis:IsRevealed(plot)) then
				local barbManager = Game.GetBarbarianManager()

				if barbManager ~= nil then
					local tribeIndex = barbManager:GetTribeIndexAtLocation(plot:GetX(), plot:GetY())

					if tribeIndex >= 0 then
						local tribeNameType = barbManager:GetTribeNameType(tribeIndex)
						local tribeInfo = GameInfo.BarbarianTribeNames[tribeNameType]

						if tribeInfo ~= nil then
							table.insert(results, {
								Label = Locale.Lookup(
									"LOC_TRIBE_BANNER_TREAT_WITH_TRIBE_TT", Locale.Lookup(tribeInfo.TribeDisplayName)
								),
								Action = function()
									LuaEvents.CityBannerManager_OpenTreatWithTribePopup(plot:GetIndex())
								end,
							})
						end
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
				if district ~= nil and not IsCityCenterDistrict(district) then
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

	CollectMissileSiloInteractions(results, plot, plotX, plotY, localPlayerID)

	return results
end

local function ExecutePlotInteraction(interaction)
	if interaction ~= nil and interaction.Action ~= nil then
		UI.PlaySound("Play_UI_Click")
		interaction.Action()
	end
end

local g_plotInteractSuspendToken = nil

local function DismissPlotInteractList()
	mgr:UnregisterSuspendCloser(g_plotInteractSuspendToken)
	g_plotInteractSuspendToken = nil
	mgr:RemoveFromStack(PLOT_INTERACT_LIST_ID)
	UITutorialManager:RemoveControlToAlwaysReceiveInput(ContextPtr)
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
	UITutorialManager:AddControlToAlwaysReceiveInput(ContextPtr)
	mgr:Push(list)
	g_plotInteractSuspendToken = mgr:RegisterSuspendCloser(DismissPlotInteractList)
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
				if type(labelKey) == "function" then return labelKey() end
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

if GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_CIV_ROYALE" then
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

if GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_PIRATES" then
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

local function GetInterfaceWidgetData()
	return interfaceWidgets[UI.GetInterfaceMode()]
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

	local newData = interfaceWidgets[newMode]
	if not newData then return end

	local widgetId = newData.WidgetId or "CAIWorldInputInterfaceMode"
	local mode = mgr:CreateWidget(widgetId, "InterfaceMode", newData.Properties)
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
	if ExposedMembers.CAI_Active == false then return false end
	if CAI then CAI.Silence() end
	return DispatchInputAction(actionId, INPUT_ACTION_STARTED, x, y)
end

function OnInputActionTriggered(actionId)
	if ExposedMembers.CAI_Active == false then return end
	DispatchInputAction(actionId, INPUT_ACTION_TRIGGERED)
end

-- ===========================================================================
-- Game view lifecycle
-- ===========================================================================
local function CreateGameViewWidget()
	if not mgr then
		LogError("CAI WorldInput could not create game view widget because ExposedMembers.CAI_UIManager is nil")
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
local function WBPlacementSourcePlot()
	if m_wbMarkedPlotId ~= nil and Map.IsPlot(m_wbMarkedPlotId) then
		return m_wbMarkedPlotId
	end
	return GetCurrentCAICursorPlotId()
end

-- The locked World Builder placement plot (the marked tile), or nil when no tile
-- is locked. Only a locked tile drives the footprint listing, so the cursor can
-- roam to inspect tiles without it following. Published on the shared CAIInfo
-- table so cross-context consumers can read it (the plot tooltip's placement
-- readout runs in the PlotToolTip context, not here), and kept as a global for
-- the same-context Valid Targets scanner category.
local function GetWorldBuilderMarkedPlot()
	if m_wbMarkedPlotId ~= nil and Map.IsPlot(m_wbMarkedPlotId) then
		return m_wbMarkedPlotId
	end
	return nil
end

function CAIWorldBuilderScannerSourcePlot()
	return GetWorldBuilderMarkedPlot()
end

-- Reassigned fresh each load (never guarded on nil) per the ExposedMembers
-- reload-staleness rule, so the closure always sees this session's mark.
ExposedMembers.CAIInfo = ExposedMembers.CAIInfo or {}
ExposedMembers.CAIInfo.GetWorldBuilderMarkedPlot = GetWorldBuilderMarkedPlot

-- Refresh the scanner's Valid Targets category so a parked view updates after the
-- mark toggles or a placement changes tile validity. A no-op when the scanner has
-- no active state; navigating to the category always rescans regardless.
local function RefreshValidTargetsScanner()
	if CAIWorldScanner ~= nil and CAIWorldScanner:GetActiveState() ~= nil then
		CAIWorldScanner:RebuildCategory("validTargets")
	end
end

local function WBEditCursorPlot(bAdd)
	local plotId = WBPlacementSourcePlot()
	if plotId == nil or plotId < 0 or not Map.IsPlot(plotId) then return false end

	-- New keypress = new placement: reset the status-line speech de-dupe so a
	-- repeated identical result (e.g. the same failure) speaks again. Within this
	-- one keypress a brush's repeated identical statuses still collapse.
	LuaEvents.CAIWorldBuilderStatusBurstBegin()

	-- Rivers and Cliffs place on a plot edge. Vanilla derives the edge from the
	-- mouse position; CAI has no cursor edge, so the placement context exposes the
	-- direction chosen in the tools (its Direction parameter). Fall back to the
	-- cursor-nearest edge for any tool that does not publish a direction.
	local edge = UI.GetCursorNearestPlotEdge()
	local info = ExposedMembers.CAIInfo
	if info ~= nil and info.GetWorldBuilderEdgeDirection ~= nil then
		local dir = info.GetWorldBuilderEdgeDirection()
		if dir ~= nil then edge = dir end
	end

	if bAdd then
		-- LButtonUp pair: start undo block + PlacementFunc(add), then close it.
		LuaEvents.WorldInput_WBSelectPlot(plotId, edge, true, false)
		LuaEvents.WorldInput_WBSelectPlot(plotId, edge, false, false)
	else
		-- RButtonDown/RButtonUp pair: PlacementFunc(remove) on the up event.
		LuaEvents.WorldInput_WBSelectPlot(plotId, edge, true, true)
		LuaEvents.WorldInput_WBSelectPlot(plotId, edge, false, true)
	end

	-- The Set Visibility tool reveals (add) / hides (remove) this plot for its
	-- selected player through the vanilla placement path above. That edit only
	-- reaches the map database on save, so mirror it into the in-memory
	-- visibility model now (add = reveal, remove = hide) for live readout.
	local visMgr = ExposedMembers.CAI_WBVisManager
	local caiInfo = ExposedMembers.CAIInfo
	if visMgr ~= nil and caiInfo ~= nil and caiInfo.GetWorldBuilderVisibilityPlayer ~= nil then
		local visPlayer = caiInfo.GetWorldBuilderVisibilityPlayer()
		if visPlayer ~= nil then
			visMgr.SetRevealed(visPlayer, plotId, bAdd)
		end
	end

	-- A placement can change which footprint tiles are valid; refresh the scanner
	-- so a parked Valid Targets view reflects the new state.
	RefreshValidTargetsScanner()
	return true
end

-- World Builder undo / redo (Ctrl+Z / Ctrl+Y). Mirrors vanilla WorldBuilder and
-- WorldBuilderPlacement OnUndo / OnRedo: step the edit history and report the
-- result through the placement status line, which CAI already speaks. Each
-- keypress is a distinct action, so reset the status-line speech de-dupe first;
-- otherwise a run of undos (all "Undo successful") would speak only once.
local function WBUndoRedo(bRedo)
	LuaEvents.CAIWorldBuilderStatusBurstBegin()
	if bRedo then
		if WorldBuilder.CanRedo() then
			WorldBuilder.Redo()
			LuaEvents.WorldBuilder_SetPlacementStatus(Locale.Lookup("LOC_WORLDBUILDER_STATUS_REDO"))
		else
			LuaEvents.WorldBuilder_SetPlacementStatus(Locale.Lookup("LOC_WORLDBUILDER_STATUS_CANT_REDO"))
		end
	else
		if WorldBuilder.CanUndo() then
			WorldBuilder.Undo()
			LuaEvents.WorldBuilder_SetPlacementStatus(Locale.Lookup("LOC_WORLDBUILDER_STATUS_UNDO"))
		else
			LuaEvents.WorldBuilder_SetPlacementStatus(Locale.Lookup("LOC_WORLDBUILDER_STATUS_CANT_UNDO"))
		end
	end

	-- Undo/redo can change which footprint tiles are valid; refresh a parked scanner.
	RefreshValidTargetsScanner()
end

-- ===========================================================================
-- World Builder: go-to-coordinates quick jump (Ctrl+G)
-- ===========================================================================
-- Ctrl+G pushes a single edit box; typing coordinates and pressing Enter moves
-- the CAI cursor there. The first field is x, the second (after a space) is z;
-- a leading space omits x and sets z alone. A field prefixed with + or - is a
-- relative step from the current cursor, otherwise it is an absolute jump. Each
-- field is classified independently, so "15 +2" jumps x to 15 and steps z by 2.
-- Escape closes the box. The box uses the coordinate edit mode (digits, space,
-- + and -); that enum lives in the edit-box widget's own context and globals do
-- not cross contexts, so the numeric mode value is passed directly.
local GOTO_EDIT_ID = "CAIWorldBuilderGoto_Edit"
local EDIT_MODE_NUMERIC_SYMBOLS = 4 -- EditModes.NumericSymbols in CAIWidget_EditBox (enums do not cross contexts)
local m_gotoEdit = nil
local m_gotoTarget = nil

-- Trim ASCII spaces/tabs from both ends. Never %s: it is locale-sensitive and
-- corrupts UTF-8 under Simplified Chinese.
local function TrimAscii(s)
	if s == nil then return nil end
	s = string.gsub(s, "^[ \t]+", "")
	s = string.gsub(s, "[ \t]+$", "")
	return s
end

-- Classify one coordinate field: "rel"/"abs" plus its numeric value, or nil for
-- anything that is not a bare or signed integer.
local function ClassifyGotoField(tok)
	if string.match(tok, "^[+-]%d+$") then return "rel", tonumber(tok) end
	if string.match(tok, "^%d+$") then return "abs", tonumber(tok) end
	return nil
end

-- Parse the entry into an absolute target (x, y) relative to the current cursor,
-- or return nil plus a localized message explaining the accepted format.
local function ParseGoto(text)
	local curX, curY = CAICursor:GetCoords()
	if curX == nil or curY == nil then
		return nil, Locale.Lookup("LOC_CAI_WB_GOTO_INVALID")
	end

	text = text or ""
	local xRaw, zRaw
	local sp = string.find(text, " ", 1, true)
	if sp ~= nil then
		xRaw = string.sub(text, 1, sp - 1)
		zRaw = string.sub(text, sp + 1)
	else
		xRaw = text
	end

	local xTok = TrimAscii(xRaw)
	local zTok = TrimAscii(zRaw)
	local xProvided = xTok ~= nil and xTok ~= ""
	local zProvided = zTok ~= nil and zTok ~= ""
	if not xProvided and not zProvided then
		return nil, Locale.Lookup("LOC_CAI_WB_GOTO_INVALID")
	end

	local targetX, targetY = curX, curY
	if xProvided then
		local kind, val = ClassifyGotoField(xTok)
		if kind == nil then return nil, Locale.Lookup("LOC_CAI_WB_GOTO_INVALID") end
		targetX = (kind == "rel") and (curX + val) or val
	end
	if zProvided then
		local kind, val = ClassifyGotoField(zTok)
		if kind == nil then return nil, Locale.Lookup("LOC_CAI_WB_GOTO_INVALID") end
		targetY = (kind == "rel") and (curY + val) or val
	end

	return targetX, targetY
end

local function CloseGotoEditor()
	if m_gotoEdit == nil then return end
	m_gotoEdit = nil
	m_gotoTarget = nil
	mgr:RemoveFromStack(GOTO_EDIT_ID)
end

local function OpenGotoEditor()
	if m_gotoEdit ~= nil or mgr == nil then return end

	local edit = mgr:CreateWidget(GOTO_EDIT_ID, "EditBox", {
		Label = function() return Locale.Lookup("LOC_CAI_WB_GOTO") end,
	})
	if edit == nil then return end
	edit:SetEditMode(EDIT_MODE_NUMERIC_SYMBOLS)
	edit:SetAlwaysEdit(true)
	-- Closing pops the box (which fires focus_leave); without this the box would
	-- commit a second time on the way out and jump twice.
	edit:SetCommitOnFocusLeave(false)
	-- Validate on Enter: a bad format or an out-of-bounds destination is spoken
	-- and blocks the commit so the user can correct it; a valid entry stashes the
	-- resolved plot for the value_changed handler to move to.
	edit:SetCommitValidator(function(text)
		local x, y = ParseGoto(text)
		if x == nil then return y end -- y is the localized error message
		local plot = Map.GetPlot(x, y)
		if plot == nil then return Locale.Lookup("LOC_CAI_WB_GOTO_OUT_OF_BOUNDS") end
		m_gotoTarget = plot:GetIndex()
		return nil
	end)
	edit:On("value_changed", function()
		local target = m_gotoTarget
		CloseGotoEditor()
		if target ~= nil then CAICursor:MoveTo(target, "jump") end
	end)
	edit:AddInputBindings({
		{
			Key = Keys.VK_ESCAPE,
			MSG = KeyEvents.KeyUp,
			Description = "LOC_CAI_KB_CLOSE",
			Action = function()
				CloseGotoEditor()
				return true
			end,
		},
	})

	m_gotoEdit = edit
	mgr:Push(edit)
end

-- Number-row order for the direct tool-select hotkeys: slots 1..10 use 1-9 then
-- 0, slots 11..16 add Shift to 1-6. Keys["0".."9"] are the number-row digit key
-- codes (see the input-help KEY_NAMES table); Keys.1 is not a valid identifier.
local WB_TOOL_HOTKEY_DIGITS = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" }

-- Direct tool-select bindings for the interface widget: the number row picks a
-- Placement tool by its 1-based palette position without opening the tools
-- panel. 1-9 and 0 select tools 1-10; Shift+1..Shift+6 select tools 11-16 (the
-- palette has 16 tools). The placement context (WorldBuilderPlacement_CAI) owns
-- the tool list, arms the chosen tool and speaks it; an out-of-range position is
-- a no-op there. KeyDown matches the other World Builder interface keys.
local function BuildToolSelectBindings()
	local bindings = {}
	for pos = 1, 16 do
		local shifted = pos > 10
		local digit = shifted and WB_TOOL_HOTKEY_DIGITS[pos - 10] or WB_TOOL_HOTKEY_DIGITS[pos]
		bindings[#bindings + 1] = {
			Key = Keys[digit],
			MSG = KeyEvents.KeyDown,
			IsShift = shifted,
			Description = "LOC_CAI_WB_SELECT_TOOL",
			Action = function()
				LuaEvents.CAIWorldBuilderSelectTool(pos)
				return true
			end,
		}
	end
	return bindings
end

-- World Builder runs in a single WB_SELECT_PLOT interface mode for its whole
-- lifetime, so instead of the gameplay game-view root we push a dedicated
-- interface-mode widget. Tab from it opens the accessible tools panel; the
-- primary / secondary / delete keys place, edit and remove at the cursor plot;
-- the number row selects tools directly.
local function CreateWorldBuilderWidget()
	if not mgr then
		LogError("CAI WorldInput could not create World Builder widget because ExposedMembers.CAI_UIManager is nil")
		return false
	end

	m_caiWorldBuilderWidget = mgr:CreateWidget("CAIWorldBuilderMode", "InterfaceMode", {
		Label = function() return Locale.Lookup("LOC_CAI_WB_MODE") end,
	})
	if not m_caiWorldBuilderWidget then
		LogError("CAI WorldInput failed to create World Builder interface widget")
		return false
	end

	m_caiWorldBuilderWidget:AddInputBindings({
		{
			Key = Keys.VK_TAB,
			MSG = KeyEvents.KeyDown,
			Description = "LOC_CAI_WB_OPEN_TOOLS",
			Action = function()
				LuaEvents.CAIWorldBuilderTools_Toggle()
				return true
			end,
		},
		-- Primary: place the armed tool's item at the cursor with the current brush.
		{
			Key = Keys.VK_RETURN,
			MSG = KeyEvents.KeyDown,
			Description = "LOC_CAI_WB_PLACE",
			Action = function()
				WBEditCursorPlot(true)
				return true
			end,
		},
		-- F3: open the single-tile Plot Editor for the source plot (marked tile
		-- if locked, else the cursor), alongside F1 (Map Editor) and F2 (Player
		-- Editor). The Plot Editor CAI answers by switching the vanilla Map Tools
		-- tab to the editor and pushing its list.
		{
			Key = Keys.VK_F3,
			MSG = KeyEvents.KeyDown,
			Description = "LOC_CAI_WB_EDIT_TILE",
			Action = function()
				local plotId = WBPlacementSourcePlot()
				if plotId ~= nil and plotId >= 0 and Map.IsPlot(plotId) then
					LuaEvents.CAIWorldBuilderPlotEditor_Toggle(plotId)
				end
				return true
			end,
		},
		-- F1 / F2: open the Map Editor and Player Editor (the launch-bar buttons).
		-- The launch-bar context owns those panels and listens for these events. As
		-- widget bindings they fire only while the World Builder map interface is the
		-- focused widget, so they stay inert inside any pushed CAI panel or screen.
		{
			Key = Keys.VK_F1,
			MSG = KeyEvents.KeyDown,
			Description = "LOC_CAI_WB_MAP_EDITOR",
			Action = function()
				LuaEvents.CAIWorldBuilderMapEditor_Toggle()
				return true
			end,
		},
		{
			Key = Keys.VK_F2,
			MSG = KeyEvents.KeyDown,
			Description = "LOC_CAI_WB_PLAYER_EDITOR",
			Action = function()
				LuaEvents.CAIWorldBuilderPlayerEditor_Toggle()
				return true
			end,
		},
		-- Ctrl+Z / Ctrl+Y: undo / redo the last World Builder edit. WorldBuilder_CAI
		-- replaces the vanilla WorldBuilder root context with a no-op input handler,
		-- so vanilla's own Ctrl+Z / Ctrl+Y handler never runs; this widget is the
		-- sole handler. KeyDown matches the other World Builder interface keys.
		{
			Key = Keys.Z,
			MSG = KeyEvents.KeyDown,
			IsControl = true,
			Description = "LOC_CAI_WB_UNDO",
			Action = function()
				WBUndoRedo(false)
				return true
			end,
		},
		{
			Key = Keys.Y,
			MSG = KeyEvents.KeyDown,
			IsControl = true,
			Description = "LOC_CAI_WB_REDO",
			Action = function()
				WBUndoRedo(true)
				return true
			end,
		},
		-- Escape: open the World Builder pause / in-game menu. WorldBuilder_CAI
		-- replaced the vanilla WorldBuilder context (whose own Escape handler opened
		-- the menu) with a no-op, so this fires the same LuaEvent the launch bar's
		-- Menu button raises; WorldBuilder_CAI listens and queues the menu popup.
		-- KeyUp (not KeyDown like the other WB keys) so the just-opened pause panel
		-- does not also receive this keypress's KeyUp and close itself immediately.
		{
			Key = Keys.VK_ESCAPE,
			MSG = KeyEvents.KeyUp,
			Description = "LOC_CAI_WB_PAUSE",
			Action = function()
				LuaEvents.InGame_OpenInGameOptionsMenu();
				return true
			end,
		},
		-- Lock / unlock the placement source to the current cursor tile, so the
		-- cursor can roam and inspect other tiles without moving where edits land.
		{
			Key = Keys.M,
			MSG = KeyEvents.KeyDown,
			Description = "LOC_CAI_WB_MARK",
			Action = function()
				if m_wbMarkedPlotId ~= nil then
					m_wbMarkedPlotId = nil
					Speak(Locale.Lookup("LOC_CAI_WB_UNMARKED"))
					RefreshValidTargetsScanner()
					return true
				end
				local plotId = GetCurrentCAICursorPlotId()
				if plotId ~= nil and plotId >= 0 and Map.IsPlot(plotId) then
					m_wbMarkedPlotId = plotId
					Speak(Locale.Lookup("LOC_CAI_WB_MARKED"))
					RefreshValidTargetsScanner()
				end
				return true
			end,
		},
		-- Delete: remove the armed tool's item at the cursor. Map-pin deletion (the
		-- usual Delete binding) does not apply in World Builder.
		{
			Key = Keys.VK_DELETE,
			MSG = KeyEvents.KeyDown,
			Description = "LOC_CAI_WB_DELETE",
			Action = function()
				WBEditCursorPlot(false)
				return true
			end,
		},
		-- Ctrl+G: open the go-to-coordinates edit box (jump the cursor to typed
		-- coordinates, absolute or relative).
		{
			Key = Keys.G,
			MSG = KeyEvents.KeyDown,
			IsControl = true,
			Description = "LOC_CAI_WB_GOTO",
			Action = function()
				OpenGotoEditor()
				return true
			end,
		},
		-- Quick nav (arrow keys): change the current tool and its parameters
		-- without opening the tools panel. Left / Right move between parameters
		-- (parameter 1 is the tool, 2..N are its parameters), Up / Down change the
		-- focused parameter's value, and Shift jumps to the first / last parameter
		-- or list value. The parameter model, state and speech all live in the
		-- placement context (WorldBuilderPlacement_CAI), which owns the vanilla
		-- placement controls; these bindings only forward the intent. Arrow keys
		-- use KeyDown so holding a key repeats, matching cursor movement.
		{
			Key = Keys.VK_LEFT,
			MSG = KeyEvents.KeyDown,
			Description = "LOC_CAI_WB_QN_PREV_PARAM",
			Action = function()
				LuaEvents.CAIWorldBuilderQuickNav("prev_param")
				return true
			end,
		},
		{
			Key = Keys.VK_RIGHT,
			MSG = KeyEvents.KeyDown,
			Description = "LOC_CAI_WB_QN_NEXT_PARAM",
			Action = function()
				LuaEvents.CAIWorldBuilderQuickNav("next_param")
				return true
			end,
		},
		{
			Key = Keys.VK_UP,
			MSG = KeyEvents.KeyDown,
			Description = "LOC_CAI_WB_QN_VALUE_UP",
			Action = function()
				LuaEvents.CAIWorldBuilderQuickNav("value_up")
				return true
			end,
		},
		{
			Key = Keys.VK_DOWN,
			MSG = KeyEvents.KeyDown,
			Description = "LOC_CAI_WB_QN_VALUE_DOWN",
			Action = function()
				LuaEvents.CAIWorldBuilderQuickNav("value_down")
				return true
			end,
		},
		{
			Key = Keys.VK_LEFT,
			MSG = KeyEvents.KeyDown,
			IsShift = true,
			Description = "LOC_CAI_WB_QN_FIRST_PARAM",
			Action = function()
				LuaEvents.CAIWorldBuilderQuickNav("first_param")
				return true
			end,
		},
		{
			Key = Keys.VK_RIGHT,
			MSG = KeyEvents.KeyDown,
			IsShift = true,
			Description = "LOC_CAI_WB_QN_LAST_PARAM",
			Action = function()
				LuaEvents.CAIWorldBuilderQuickNav("last_param")
				return true
			end,
		},
		{
			Key = Keys.VK_UP,
			MSG = KeyEvents.KeyDown,
			IsShift = true,
			Description = "LOC_CAI_WB_QN_FIRST_VALUE",
			Action = function()
				LuaEvents.CAIWorldBuilderQuickNav("first_value")
				return true
			end,
		},
		{
			Key = Keys.VK_DOWN,
			MSG = KeyEvents.KeyDown,
			IsShift = true,
			Description = "LOC_CAI_WB_QN_LAST_VALUE",
			Action = function()
				LuaEvents.CAIWorldBuilderQuickNav("last_value")
				return true
			end,
		},
	})

	m_caiWorldBuilderWidget:AddInputBindings(BuildToolSelectBindings())

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
		LogWarn("CAI WorldInput received invalid cursor plot id: " .. tostring(plotId))
		return
	end

	local plot = Map.GetPlotByIndex(plotId)
	if plot == nil then
		LogWarn("CAI WorldInput could not resolve cursor plot id: " .. tostring(plotId))
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

local function CheckInput()
	local focused = mgr:GetFocusedWidget()
	if focused == m_caiCurrentInterfaceWidget or focused == m_caiGameViewWidget or focused == m_caiWorldBuilderWidget then
		if Input.GetActiveContext() ~= InputContext.World then mgr:SetInputContext(InputContext.World) end
	end
end

local function OnUpdate()
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
	LuaEvents.CAIRequestPlaceMapPin.Remove(PlaceMapPin)
	UnitMoveLog_CAI.Shutdown()
	CAICursorAudio.Shutdown()
end



local function InitializeCAIGameView()
	if m_caiWorldBuilderWidget and mgr:GetWidgetById(m_caiWorldBuilderWidget:GetId()) then return end
	if m_caiGameViewWidget and mgr:GetWidgetById(m_caiGameViewWidget:GetId()) then return end

	-- this needs to sit below everything else. Priority must be low
	if WorldBuilder.IsActive() then
		if not CreateWorldBuilderWidget() then return end
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
	local injectedPath = ExposedMembers.CAI_WBInjectedMapPath
	if injectedPath then
		ExposedMembers.CAI_WBInjectedMapPath = nil
		local api = ExposedMembers.CAI
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
	if WorldBuilder.IsActive() and ExposedMembers.CAI_WBVisManager then
		ExposedMembers.CAI_WBVisManager.Seed(injectedPath)
	end
	InitializeCAIGameView()
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
	if ExposedMembers.CAI_WBVisManager ~= nil then
		ExposedMembers.CAI_WBVisManager.Reset()
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
