-- Selection-mode plot actions. WorldInput owns input dispatch and live context readers.
CAIPlotInteractions = {}

---@param mgr UIScreenManager
---@param adapter CAIPlotInteractionsAdapter
---@return CAIPlotInteractionsController
function CAIPlotInteractions.Create(mgr, adapter)
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
		if not adapter.IsPlotSelectionAllowed(plotId) then return results end

		local localPlayerID = Game.GetLocalPlayer()
		if localPlayerID == nil or localPlayerID < 0 then return results end

		local plotX = plot:GetX()
		local plotY = plot:GetY()

		local units = Units.GetUnitsInPlotLayerID(plotX, plotY, MapLayers.ANY)
		if units ~= nil then
			for _, unit in ipairs(units) do
				local ownerID = unit:GetOwner()
				if ownerID == localPlayerID then
					local unitName = adapter.FormatUnitName(unit) or Locale.Lookup("LOC_CAI_TILE_INTERACT_UNIT")
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
		adapter.SetAlwaysReceiveInput(false)
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
		adapter.SetAlwaysReceiveInput(true)
		mgr:Push(list)
		g_plotInteractSuspendToken = mgr:RegisterSuspendCloser(DismissPlotInteractList)
	end

	local function OnPlotPrimaryAction()
		if UI.GetInterfaceMode() ~= InterfaceModeTypes.SELECTION then return false end
		if adapter.HasInterfaceWidget() then return false end

		local plotId = adapter.GetPlotId()
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
		if adapter.HasInterfaceWidget() then return false end

		local plotId = adapter.GetPlotId()
		local interactions = CollectPlotInteractions(plotId)
		local viewCity = FindViewCityInteraction(interactions)
		if viewCity ~= nil then
			ExecutePlotInteraction(viewCity)
			return true
		end

		return false
	end

	return { Primary = OnPlotPrimaryAction, Secondary = OnPlotSecondaryAction }
end
