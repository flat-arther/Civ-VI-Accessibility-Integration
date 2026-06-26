include("caiUtils")
if GameConfiguration.GetValue("GAMEMODE_APOCALYPSE") then
    include("ClimateScreen_GranColombia_Maya")
else
    include("ClimateScreen")
end

local mgr              = ExposedMembers.CAI_UIManager

local PANEL_ID         = "CAIClimate_Panel"
local HOVER_SOUND      = "Main_Menu_Mouse_Over"

local m_panel          = nil
local m_tabControl     = nil
local m_isMirroringTab = false

local function NormalizeText(text)
    if not text then return "" end
    text = tostring(text)
    text = string.gsub(text, "%[ENDCOLOR%]", "")
    text = string.gsub(text, "%[COLOR_[^%]]+%]", "")
    text = string.gsub(text, "%[COLOR:%s*[^%]]+%]", "")
    text = string.gsub(text, "%[NEWLINE%]", ", ")
    text = string.gsub(text, "%[ICON_[^%]]+%]", "")
    text = string.gsub(text, "[,%s]+,", ",")
    text = string.gsub(text, "^[,%s]+", "")
    text = string.gsub(text, "[,%s]+$", "")
    return text
end

local function JoinNonEmpty(parts, sep)
    local out = {}
    for _, p in ipairs(parts) do
        if p and p ~= "" then
            table.insert(out, p)
        end
    end
    return table.concat(out, sep)
end

local function MakeId(prefix)
    return mgr:GenerateWidgetId(prefix)
end

local function MakeLeaf(focusKey, labelFn, tooltipFn)
    local props = {
        FocusKey = focusKey,
        Label = labelFn,
    }
    if tooltipFn then
        props.Tooltip = tooltipFn
    end
    local w = mgr:CreateWidget(MakeId("CAIClm_"), "StaticText", props)
    w:SetFocusSound(HOVER_SOUND)
    return w
end

local function MakeNode(focusKey, labelFn, tooltipFn)
    local props = {
        FocusKey = focusKey,
        Label = labelFn,
    }
    if tooltipFn then
        props.Tooltip = tooltipFn
    end
    local w = mgr:CreateWidget(MakeId("CAIClm_"), "TreeItem", props)
    w:SetFocusSound(HOVER_SOUND)
    return w
end

-- =========================================================================
-- OVERVIEW TAB
-- =========================================================================
local function BuildOverviewTree()
    local tree = mgr:CreateWidget(MakeId("CAIClm_"), "Tree", {})

    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID < 0 then return tree end

    -- Gather climate change events data
    local firstSeaLevelEvent = -1
    local currentSeaLevelEvent = -1
    local currentSeaLevelPhase = 0
    local iCurrentClimateChangePoints = GameClimate.GetClimateChangeForLastSeaLevelEvent()
    for row in GameInfo.RandomEvents() do
        if row.EffectOperatorType == "SEA_LEVEL" then
            if firstSeaLevelEvent == -1 then
                firstSeaLevelEvent = row.Index
            end
            if row.ClimateChangePoints == iCurrentClimateChangePoints then
                currentSeaLevelEvent = row.Index
                currentSeaLevelPhase = currentSeaLevelEvent - firstSeaLevelEvent + 1
            end
        end
    end

    -- 1. Current Weather Event
    local kCurrentEvent = GameRandomEvents.GetCurrentTurnEvent()
    if kCurrentEvent then
        local kCurrentEventDef = GameInfo.RandomEvents[kCurrentEvent.RandomEvent]
        if kCurrentEventDef and kCurrentEventDef.EffectOperatorType ~= "SEA_LEVEL"
            and kCurrentEventDef.EffectOperatorType ~= "NUCLEAR_ACCIDENT" then
            local pCurrentPlot = Map.GetPlotByIndex(kCurrentEvent.CurrentLocation)
            local bIsEventVisible = false
            if pCurrentPlot then
                local pLocalPlayerVis = PlayersVisibility[localPlayerID]
                if pLocalPlayerVis and pLocalPlayerVis:IsRevealed(pCurrentPlot:GetX(), pCurrentPlot:GetY()) then
                    bIsEventVisible = true
                end
            end

            local eventLeaf = MakeLeaf("climate:current_event", function()
                local parts = {}
                table.insert(parts, Locale.Lookup(kCurrentEventDef.Name))

                if kCurrentEvent.Name and bIsEventVisible then
                    table.insert(parts, Locale.Lookup(kCurrentEvent.Name))
                end

                -- Location and direction
                if kCurrentEventDef.Global then
                    table.insert(parts,
                        Locale.Lookup("LOC_CLIMATE_SCREEN_LOCATION", Locale.Lookup("LOC_CLIMATE_SCREEN_GLOBAL")))
                elseif not bIsEventVisible then
                    table.insert(parts,
                        Locale.Lookup("LOC_CLIMATE_SCREEN_LOCATION", Locale.Lookup("LOC_CIVICS_TREE_NOT_REVEALED_CIVIC")))
                elseif pCurrentPlot then
                    local location = ""
                    local eContinentType = pCurrentPlot:GetContinentType()
                    if eContinentType and eContinentType ~= -1 then
                        local kContinentDef = GameInfo.Continents[eContinentType]
                        location = Locale.Lookup(kContinentDef.Description)
                    else
                        local pTerritory = Territories.GetTerritoryAt(kCurrentEvent.CurrentLocation)
                        if pTerritory then
                            location = pTerritory:GetName()
                        else
                            location = Locale.Lookup("LOC_CLIMATE_SCREEN_WATER")
                        end
                    end

                    local dirText = GetDirectionText(kCurrentEvent.CurrentDirection)
                    if dirText and dirText ~= "" then
                        table.insert(parts,
                            NormalizeText(Locale.Lookup("LOC_CLIMATE_SCREEN_LOCATION_DIRECTION", location,
                                Locale.Lookup(dirText))))
                    else
                        table.insert(parts, NormalizeText(Locale.Lookup("LOC_CLIMATE_SCREEN_LOCATION", location)))
                    end
                end

                return JoinNonEmpty(parts, ", ")
            end, function()
                local parts = {}
                if kCurrentEventDef.EffectString then
                    table.insert(parts, Locale.Lookup(kCurrentEventDef.EffectString))
                end

                if bIsEventVisible then
                    local isCometStrike = kCurrentEventDef.RandomEventType == "RANDOM_EVENT_COMET_STRIKE"
                    if kCurrentEvent.FertilityAdded and kCurrentEvent.FertilityAdded > 0 then
                        if isCometStrike then
                            table.insert(parts,
                                Locale.Lookup("LOC_CAI_CLIMATE_DAMAGED_TILES", kCurrentEvent.FertilityAdded))
                        else
                            table.insert(parts,
                                Locale.Lookup("LOC_CAI_CLIMATE_FERTILE_TILES", kCurrentEvent.FertilityAdded))
                        end
                    end
                    if kCurrentEvent.FertilityAdded and kCurrentEvent.FertilityAdded < 0 then
                        table.insert(parts,
                            Locale.Lookup("LOC_CAI_CLIMATE_LOST_FERTILE_TILES", math.abs(kCurrentEvent.FertilityAdded)))
                    end
                    if kCurrentEvent.TilesDamaged and kCurrentEvent.TilesDamaged > 0 then
                        table.insert(parts, Locale.Lookup("LOC_CAI_CLIMATE_DAMAGED_TILES", kCurrentEvent.TilesDamaged))
                    end
                    if kCurrentEvent.UnitsLost and kCurrentEvent.UnitsLost > 0 then
                        table.insert(parts, Locale.Lookup("LOC_CAI_CLIMATE_UNITS_LOST", kCurrentEvent.UnitsLost))
                    end
                    if kCurrentEvent.PopLost and kCurrentEvent.PopLost > 0 then
                        table.insert(parts, Locale.Lookup("LOC_CAI_CLIMATE_POP_LOST", kCurrentEvent.PopLost))
                    end
                end

                -- Affected cities
                local kCities = GameRandomEvents.GetCurrentAffectedCities()
                if kCities and #kCities > 0 and bIsEventVisible then
                    local cityNames = {}
                    local pLocalPlayerDiplo = Players[localPlayerID]:GetDiplomacy()
                    for _, ac in ipairs(kCities) do
                        local pOwner = Players[ac.CityOwner]
                        if pOwner and pLocalPlayerDiplo:HasMet(ac.CityOwner) then
                            local pCity = pOwner:GetCities():FindID(ac.CityID)
                            if pCity then
                                table.insert(cityNames, Locale.Lookup(pCity:GetName()))
                            end
                        end
                    end
                    if #cityNames > 0 then
                        table.insert(parts,
                            Locale.Lookup("LOC_CAI_CLIMATE_AFFECTED_CITIES", table.concat(cityNames, ", ")))
                    end
                end

                return JoinNonEmpty(parts, "[NEWLINE]")
            end)
            tree:AddChild(eventLeaf)
        end
    end

    -- 2. Climate Phase summary
    local climateName
    if currentSeaLevelEvent < 0 then
        climateName = Locale.Lookup("LOC_CLIMATE_CLIMATE_CHANGE_PHASE_0")
    else
        climateName = Locale.Lookup(GameInfo.RandomEvents[currentSeaLevelEvent].Name)
    end

    local phaseNode = MakeNode("climate:phase", function()
        return climateName
    end, function()
        local currentPts = GameClimate.GetClimateChangeLevel()
        local nextDef = GameInfo.RandomEvents[firstSeaLevelEvent + currentSeaLevelPhase]
        if nextDef then
            return Locale.Lookup("LOC_CAI_CLIMATE_PHASE_POINTS", currentPts, nextDef.ClimateChangePoints)
        end
        return Locale.Lookup("LOC_CAI_CLIMATE_PHASE_POINTS_MAX", currentPts)
    end)

    -- Phase detail children (I-VII)
    for i = 1, 7 do
        local kEventDef = GameInfo.RandomEvents[firstSeaLevelEvent + i - 1]
        if kEventDef then
            local capturedI = i
            local capturedDef = kEventDef
            local child = MakeLeaf("climate:phase:" .. i, function()
                return Locale.Lookup(capturedDef.Name)
            end, function()
                local parts = {}
                table.insert(parts, Locale.Lookup("LOC_CLIMATE_CLIMATE_CHANGE_POINTS_TOOLTIP",
                    GameClimate.GetClimateChangeLevel(), capturedDef.ClimateChangePoints))
                table.insert(parts, Locale.Lookup("LOC_CLIMATE_FROM_WORLD_REALISM_NUM_TOOLTIP",
                    GameClimate.GetClimateChangeFromRealism()))
                table.insert(parts, Locale.Lookup("LOC_CLIMATE_FROM_GLOBAL_TEMPERATURE_NUM_TOOLTIP",
                    GameClimate.GetClimateChangeFromTemperature()))

                local szSeaLevelRise = capturedDef.Description
                table.insert(parts, Locale.Lookup("LOC_CLIMATE_SEA_LEVEL_RISES_NUM_TOOLTIP", szSeaLevelRise))
                table.insert(parts, Locale.Lookup("LOC_CLIMATE_POLAR_ICE_MELT_TOOLTIP", capturedDef.IceLoss))

                local szPhaseType = capturedDef.RandomEventType
                for row in GameInfo.CoastalLowlands() do
                    if row.FloodedEvent == szPhaseType then
                        table.insert(parts, Locale.Lookup("LOC_CLIMATE_TILES_AT_OR_BELOW_FLOOD_TOOLTIP", row.Name))
                        break
                    elseif row.SubmergedEvent == szPhaseType then
                        table.insert(parts, Locale.Lookup("LOC_CLIMATE_TILES_AT_OR_BELOW_SUBMERGE_TOOLTIP", row.Name))
                        break
                    end
                end

                if capturedDef.LongDescription and capturedDef.LongDescription ~= "" then
                    table.insert(parts, Locale.Lookup(capturedDef.LongDescription))
                end

                return JoinNonEmpty(parts, "[NEWLINE]")
            end)
            phaseNode:AddChild(child)
        end
    end
    tree:AddChild(phaseNode)

    -- 3. Contributing Factors node
    local contributingNode = MakeNode("climate:contributing", function()
        return Locale.Lookup("LOC_CLIMATE_CONTRIBUTING_TO_CLIMATE_CHANGE")
    end)

    -- CO2 Levels
    local CO2Total = GameClimate.GetTotalCO2Footprint()
    local CO2Player = GameClimate.GetPlayerCO2Footprint(localPlayerID, false)
    local CO2Modifier = GameClimate.GetCO2FootprintModifier()
    local CO2TopPlayer = GetWorstCO2PlayerID()
    local topContributorName = Locale.Lookup("LOC_CLIMATE_NO_ONE")
    if CO2TopPlayer ~= -1 then
        topContributorName = PlayerConfigurations[CO2TopPlayer]:GetPlayerName()
    end

    local co2Leaf = MakeLeaf("climate:co2", function()
        return Locale.Lookup("LOC_CLIMATE_CO2_LEVELS") .. ", " ..
            NormalizeText(Locale.Lookup("LOC_CLIMATE_TOTAL_NUM", CO2Total))
    end, function()
        return JoinNonEmpty({
            NormalizeText(Locale.Lookup("LOC_CLIMATE_TOP_CONTRIBUTOR_NUM", topContributorName)),
            NormalizeText(Locale.Lookup("LOC_CLIMATE_MY_CONTRIBUTION_NUM", CO2Player)),
            NormalizeText(Locale.Lookup("LOC_CLIMATE_CO2_TOTAL_TOOLTIP", CO2Modifier)),
        }, "[NEWLINE]")
    end)
    contributingNode:AddChild(co2Leaf)

    -- Temperature
    local tempIncrease = GameClimate.GetTemperatureChange()
    local tempText = tostring(Locale.ToNumber(tempIncrease, "#.#"))
    local deforestationType = GameClimate.GetDeforestationType()
    local co2Mod = GameClimate.GetCO2FootprintModifier()

    local tempLeaf = MakeLeaf("climate:temp", function()
        return Locale.Lookup("LOC_CLIMATE_GLOBAL_TEMPERATURE") .. ", " ..
            Locale.Lookup("LOC_CAI_CLIMATE_TEMP_VALUE", tempText)
    end, function()
        if deforestationType >= 0 then
            local kDef = GameInfo.DeforestationLevels[deforestationType]
            return NormalizeText(Locale.Lookup("LOC_CLIMATE_TEMPERATURE_TOOLTIP", kDef.Name, kDef.Description, co2Mod))
        end
        return ""
    end)
    contributingNode:AddChild(tempLeaf)

    -- World Settings
    local worldAgeNum = MapConfiguration.GetValue("world_age")
    local worldAgeName = nil
    if worldAgeNum then
        local query = "SELECT * FROM DomainValues where Domain = 'WorldAge' and Value = ? LIMIT 1"
        local pResults = DB.ConfigurationQuery(query, worldAgeNum)
        if pResults and pResults[1] then
            worldAgeName = Locale.Lookup(pResults[1].Name)
        end
    end

    local realismLevel = GameConfiguration.GetValue("GAME_REALISM")
    local realismName = nil
    if realismLevel then
        local query = "SELECT * FROM RealismSettings ORDER BY rowid"
        local pResults = DB.Query(query)
        if pResults and pResults[realismLevel + 1] then
            realismName = Locale.Lookup(pResults[realismLevel + 1].Name)
        end
    end

    local settingsLeaf = MakeLeaf("climate:settings", function()
        return Locale.Lookup("LOC_CLIMATE_WORLD_SETTINGS")
    end, function()
        local parts = {}
        if worldAgeName then
            table.insert(parts, NormalizeText(Locale.Lookup("LOC_CLIMATE_WORLD_AGE", worldAgeName)))
        end
        if realismName then
            table.insert(parts, NormalizeText(Locale.Lookup("LOC_CLIMATE_REALISM", realismName)))
        end
        return JoinNonEmpty(parts, "[NEWLINE]")
    end)
    contributingNode:AddChild(settingsLeaf)

    tree:AddChild(contributingNode)

    -- 4. Forecast node
    local forecastNode = MakeNode("climate:forecast", function()
        return Locale.Lookup("LOC_CLIMATE_FORECAST")
    end)

    -- Storms
    local stormChance = GameClimate.GetStormPercentChance()
    local stormIncrease = GameClimate.GetStormClimateIncreasedChance()
    forecastNode:AddChild(MakeLeaf("climate:forecast:storm", function()
        return Locale.Lookup("LOC_CLIMATE_CHANCE_OF_STORMS") .. ", " ..
            NormalizeText(Locale.Lookup("LOC_CLIMATE_PERCENT_CHANCE", stormChance))
    end, function()
        return JoinNonEmpty({
            NormalizeText(Locale.Lookup("LOC_CLIMATE_AMOUNT_FROM_CLIMATE_CHANGE", stormIncrease)),
            NormalizeText(Locale.Lookup("LOC_CLIMATE_STORM_EVENT_DESCRIPTION_TOOLTIP")),
        }, "[NEWLINE]")
    end))

    -- River Floods
    local floodChance = GameClimate.GetFloodPercentChance()
    local floodIncrease = GameClimate.GetFloodClimateIncreasedChance()
    forecastNode:AddChild(MakeLeaf("climate:forecast:flood", function()
        return Locale.Lookup("LOC_CLIMATE_CHANCE_OF_RIVER_FLOOD") .. ", " ..
            NormalizeText(Locale.Lookup("LOC_CLIMATE_PERCENT_CHANCE", floodChance))
    end, function()
        return JoinNonEmpty({
            NormalizeText(Locale.Lookup("LOC_CLIMATE_AMOUNT_FROM_CLIMATE_CHANGE", floodIncrease)),
            NormalizeText(Locale.Lookup("LOC_CLIMATE_RIVER_FLOOD_EVENT_DESCRIPTION_TOOLTIP")),
        }, "[NEWLINE]")
    end))

    -- Droughts
    local droughtChance = GameClimate.GetDroughtPercentChance()
    local droughtIncrease = GameClimate.GetDroughtClimateIncreasedChance()
    forecastNode:AddChild(MakeLeaf("climate:forecast:drought", function()
        return Locale.Lookup("LOC_CLIMATE_DROUGHTS") .. ", " ..
            NormalizeText(Locale.Lookup("LOC_CLIMATE_PERCENT_CHANCE", droughtChance))
    end, function()
        return JoinNonEmpty({
            NormalizeText(Locale.Lookup("LOC_CLIMATE_AMOUNT_FROM_CLIMATE_CHANGE", droughtIncrease)),
            NormalizeText(Locale.Lookup("LOC_CLIMATE_DROUGHT_EVENT_DESCRIPTION_TOOLTIP")),
        }, "[NEWLINE]")
    end))

    -- Volcanoes
    local volcanoEruptChance = GameClimate.GetEruptionPercentChance()
    local volcanoActiveNum = MapFeatureManager.GetNumActiveVolcanoes()
    local volcanoTotalNum = MapFeatureManager.GetNumNormalVolcanoes()
    local volcanoEruptionsNum = MapFeatureManager.GetNumEruptions()
    local volcanoNaturalWonder = MapFeatureManager.GetNumNaturalWonderVolcanoes()
    forecastNode:AddChild(MakeLeaf("climate:forecast:volcano", function()
        return Locale.Lookup("LOC_CLIMATE_VOLCANIC_ACTIVITY") .. ", " ..
            NormalizeText(Locale.Lookup("LOC_CLIMATE_PERCENT_CHANCE", volcanoEruptChance))
    end, function()
        return JoinNonEmpty({
            NormalizeText(Locale.Lookup("LOC_CLIMATE_VOLCANO_ACTIVE_NUM", volcanoActiveNum)),
            NormalizeText(Locale.Lookup("LOC_CLIMATE_VOLCANO_INACTIVE_NUM", volcanoTotalNum - volcanoActiveNum)),
            NormalizeText(Locale.Lookup("LOC_CLIMATE_VOLCANO_ERUPTED_NUM", volcanoEruptionsNum)),
            NormalizeText(Locale.Lookup("LOC_CLIMATE_VOLCANO_VOLATILE_NUM", volcanoNaturalWonder)),
            NormalizeText(Locale.Lookup("LOC_CLIMATE_VOLCANO_EVENT_DESCRIPTION_TOOLTIP")),
        }, "[NEWLINE]")
    end))

    -- Forest Fires (Gran Colombia/Maya mode)
    if GameClimate.GetFirePercentChance and GameInfo.RandomEvents["RANDOM_EVENT_FOREST_FIRE_TRIGGERED"] then
        local fireChance = GameClimate.GetFirePercentChance()
        local fireIncrease = GameClimate.GetFireClimateIncreasedChance()
        forecastNode:AddChild(MakeLeaf("climate:forecast:fire", function()
            return Locale.Lookup("LOC_CLIMATE_FOREST_FIRE") .. ", " ..
                NormalizeText(Locale.Lookup("LOC_CLIMATE_PERCENT_CHANCE", fireChance))
        end, function()
            return JoinNonEmpty({
                NormalizeText(Locale.Lookup("LOC_CLIMATE_AMOUNT_FROM_CLIMATE_CHANGE", fireIncrease)),
                NormalizeText(Locale.Lookup("LOC_CLIMATE_FOREST_FIRE_EVENT_DESCRIPTION_TOOLTIP")),
            }, "[NEWLINE]")
        end))
    end

    tree:AddChild(forecastNode)

    -- 5. Polar Ice
    local iIceLoss = 0
    if currentSeaLevelEvent > -1 then
        iIceLoss = GameInfo.RandomEvents[currentSeaLevelEvent].IceLoss
    end
    local nextIceLostTurns = GameClimate.GetNextIceLossTurns()

    tree:AddChild(MakeLeaf("climate:ice", function()
        return Locale.Lookup("LOC_CLIMATE_POLAR_ICE") .. ", " ..
            NormalizeText(Locale.Lookup("LOC_CLIMATE_LOST", iIceLoss))
    end, function()
        local parts = {}
        if nextIceLostTurns > 0 and currentSeaLevelPhase < 7 then
            table.insert(parts, NormalizeText(Locale.Lookup("LOC_CLIMATE_POLAR_ICE_MELT_X_TURNS", nextIceLostTurns)))
        end
        table.insert(parts, NormalizeText(Locale.Lookup("LOC_CLIMATE_POLAR_ICE_MELT_DESCRIPTION_TOOLTIP")))
        return JoinNonEmpty(parts, "[NEWLINE]")
    end))

    -- 6. Sea Level
    local tilesFlooded = GameClimate.GetTilesFlooded()
    local tilesSubmerged = GameClimate.GetTilesSubmerged()
    local nextSeaRiseTurns = GameClimate.GetNextSeaLevelRiseTurns()
    local szSeaLevel = "0"
    if currentSeaLevelEvent > -1 then
        szSeaLevel = GameInfo.RandomEvents[currentSeaLevelEvent].Description
    end

    tree:AddChild(MakeLeaf("climate:sea", function()
        return Locale.Lookup("LOC_CLIMATE_SEA_LEVEL") .. ", " ..
            NormalizeText(Locale.Lookup("LOC_CLIMATE_SEA_LEVEL_RISE", Locale.Lookup(szSeaLevel)))
    end, function()
        local parts = {
            NormalizeText(Locale.Lookup("LOC_CLIMATE_COASTAL_TILES_FLOODED_NUM", tilesFlooded)),
            NormalizeText(Locale.Lookup("LOC_CLIMATE_COASTAL_TILES_SUBMERGED_NUM", tilesSubmerged)),
        }
        if nextSeaRiseTurns > 0 and currentSeaLevelPhase < 7 then
            table.insert(parts, NormalizeText(Locale.Lookup("LOC_CLIMATE_SEA_LEVEL_RISE_X_TURNS", nextSeaRiseTurns)))
        end
        table.insert(parts, NormalizeText(Locale.Lookup("LOC_CLIMATE_SEA_LEVEL_RISE_DESCRIPTION_TOOLTIP", szSeaLevel)))
        return JoinNonEmpty(parts, "[NEWLINE]")
    end))

    return tree
end

-- =========================================================================
-- CO2 LEVELS TAB
-- =========================================================================
local function BuildCO2Tree()
    local tree = mgr:CreateWidget(MakeId("CAIClm_"), "Tree", {})

    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID < 0 then return tree end

    local CO2Total = GameClimate.GetTotalCO2Footprint()
    local CO2Player = GameClimate.GetPlayerCO2Footprint(localPlayerID, false)
    local CO2Modifier = GameClimate.GetCO2FootprintModifier()

    -- 1. Global Contributions - By Civilization
    local globalByCivNode = MakeNode("co2:global:civ", function()
        local sTotal
        if CO2Modifier ~= 0 then
            sTotal = NormalizeText(Locale.Lookup("LOC_CLIMATE_TOTAL_NUM_W_MOD", CO2Total, CO2Modifier))
        else
            sTotal = NormalizeText(Locale.Lookup("LOC_CLIMATE_TOTAL_NUM", CO2Total))
        end
        return Locale.Lookup("LOC_CLIMATE_TAB_CO2_BY_CIVILIZATION") .. ", " .. sTotal
    end, function()
        if CO2Modifier ~= 0 then
            return NormalizeText(Locale.Lookup("LOC_CLIMATE_CO2_TOTAL_TOOLTIP", CO2Modifier))
        end
        return ""
    end)

    local pLocalPlayer = Players[localPlayerID]
    local pPlayerDiplomacy = pLocalPlayer:GetDiplomacy()

    -- Your contribution first (expandable, with per-resource breakdown)
    local yourNode = MakeNode("co2:yours", function()
        return Locale.Lookup("LOC_CLIMATE_YOUR_CO2_CONTRIBUTION") .. ", " ..
            NormalizeText(Locale.Lookup("LOC_CLIMATE_TOTAL_NUM", CO2Player))
    end)
    local pResources = pLocalPlayer:GetResources()
    for kResourceInfo in GameInfo.Resources() do
        local kConsumption = GameInfo.Resource_Consumption[kResourceInfo.ResourceType]
        if kConsumption and kConsumption.CO2perkWh and kConsumption.CO2perkWh > 0 then
            local amount = GameClimate.GetPlayerResourceCO2Footprint(localPlayerID, kResourceInfo.Index, false)
            if amount > 0 then
                local capturedName = Locale.Lookup(kResourceInfo.Name)
                local capturedAmount = amount
                local amountLastTurn = GameClimate.GetPlayerResourceCO2Footprint(localPlayerID, kResourceInfo.Index, true)
                local resourceLastTurn = GameClimate.GetPlayerRawResourceConsumption(localPlayerID, kResourceInfo.Index,
                    true)
                local capturedResLT = resourceLastTurn
                local capturedAmtLT = amountLastTurn
                yourNode:AddChild(MakeLeaf("co2:yours:" .. kResourceInfo.ResourceType, function()
                    return capturedName .. ", " .. capturedAmount
                end, function()
                    return NormalizeText(Locale.Lookup("LOC_CLIMATE_RESOURCE_CONSUMED_LAST_TURN",
                        capturedResLT, capturedName, capturedAmtLT))
                end))
            end
        end
    end
    globalByCivNode:AddChild(yourNode)

    for _, pPlayer in ipairs(PlayerManager.GetWasEverAliveMajors()) do
        local playerID = pPlayer:GetID()
        if playerID ~= localPlayerID then
            local footprint = GameClimate.GetPlayerCO2Footprint(playerID, false)
            local pPlayerConfig = PlayerConfigurations[playerID]
            local civName
            if not pPlayerDiplomacy:HasMet(playerID) then
                civName = Locale.Lookup("LOC_WORLD_RANKING_UNMET_PLAYER")
            else
                civName = Locale.Lookup(pPlayerConfig:GetCivilizationDescription())
            end
            local capturedName = civName
            local capturedFootprint = footprint
            globalByCivNode:AddChild(MakeLeaf("co2:civ:" .. playerID, function()
                return capturedName .. ", " .. capturedFootprint
            end))
        end
    end
    tree:AddChild(globalByCivNode)

    -- 2. Global Contributions - By Resource
    local globalByResNode = MakeNode("co2:global:res", function()
        local sTotal
        if CO2Modifier ~= 0 then
            sTotal = NormalizeText(Locale.Lookup("LOC_CLIMATE_TOTAL_NUM_W_MOD", CO2Total, CO2Modifier))
        else
            sTotal = NormalizeText(Locale.Lookup("LOC_CLIMATE_TOTAL_NUM", CO2Total))
        end
        return Locale.Lookup("LOC_CLIMATE_TAB_CO2_BY_RESOURCE") .. ", " .. sTotal
    end, function()
        if CO2Modifier ~= 0 then
            return NormalizeText(Locale.Lookup("LOC_CLIMATE_CO2_TOTAL_TOOLTIP", CO2Modifier))
        end
        return ""
    end)

    local aliveMajorIDList = PlayerManager.GetAliveMajorIDs()
    for kResourceInfo in GameInfo.Resources() do
        local kConsumption = GameInfo.Resource_Consumption[kResourceInfo.ResourceType]
        if kConsumption and kConsumption.CO2perkWh and kConsumption.CO2perkWh > 0 then
            local amount = 0
            for _, pPlayer in ipairs(PlayerManager.GetAliveMajors()) do
                amount = amount + GameClimate.GetPlayerResourceCO2Footprint(pPlayer:GetID(), kResourceInfo.Index, false)
            end
            if amount > 0 then
                local capturedName = Locale.Lookup(kResourceInfo.Name)
                local capturedAmount = amount

                local totalAmountLastTurn = 0
                local totalResourceLastTurn = 0
                for _, v in ipairs(aliveMajorIDList) do
                    totalAmountLastTurn = totalAmountLastTurn +
                        GameClimate.GetPlayerResourceCO2Footprint(v, kResourceInfo.Index, true)
                    totalResourceLastTurn = totalResourceLastTurn +
                        GameClimate.GetPlayerRawResourceConsumption(v, kResourceInfo.Index, true)
                end
                local capturedResLT = totalResourceLastTurn
                local capturedAmtLT = totalAmountLastTurn

                globalByResNode:AddChild(MakeLeaf("co2:res:" .. kResourceInfo.ResourceType, function()
                    return capturedName .. ", " .. capturedAmount
                end, function()
                    return NormalizeText(Locale.Lookup("LOC_CLIMATE_RESOURCE_CONSUMED_LAST_TURN_GLOBAL",
                        capturedResLT, capturedName, capturedAmtLT))
                end))
            end
        end
    end
    tree:AddChild(globalByResNode)

    return tree
end

-- =========================================================================
-- EVENT HISTORY TAB
-- =========================================================================
local function BuildEventHistoryList()
    local list = mgr:CreateWidget(MakeId("CAIClm_"), "List", {})

    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID < 0 then return list end

    local iCurrentTurn = Game.GetCurrentGameTurn()
    for i = iCurrentTurn, 0, -1 do
        local kEvent = GameRandomEvents.GetEventsForTurn(i)
        if kEvent then
            local kEventDef = GameInfo.RandomEvents[kEvent.RandomEvent]
            if kEventDef and kEventDef.EffectOperatorType ~= "NUCLEAR_ACCIDENT" then
                local isClimateChange = kEventDef.ClimateChangePoints > 0
                local pEventPlot = Map.GetPlotByIndex(kEvent.StartLocation)
                local isVisible = kEventDef.Global
                if not isVisible and pEventPlot then
                    local pLocalPlayerVis = PlayersVisibility[localPlayerID]
                    if pLocalPlayerVis and pLocalPlayerVis:IsRevealed(pEventPlot:GetX(), pEventPlot:GetY()) then
                        isVisible = true
                    end
                end

                if isClimateChange or isVisible then
                    local capturedEvent = kEvent
                    local capturedDef = kEventDef
                    local capturedTurn = i
                    local capturedCC = isClimateChange

                    local strDate = Calendar.MakeYearStr(capturedTurn)

                    local eventWidget = MakeLeaf("climate:event:" .. capturedTurn, function()
                        local parts = {}
                        table.insert(parts, Locale.Lookup("LOC_CAI_CLIMATE_TURN", capturedTurn, strDate))
                        table.insert(parts, Locale.Lookup(capturedDef.Name))

                        if not capturedCC and capturedEvent.Name then
                            table.insert(parts, Locale.Lookup(capturedEvent.Name))
                        end

                        -- Location for non-climate-change events
                        if not capturedCC then
                            local pPlot = Map.GetPlotByIndex(capturedEvent.StartLocation)
                            if pPlot then
                                local eContinentType = pPlot:GetContinentType()
                                if eContinentType and eContinentType ~= -1 then
                                    local kContinentDef = GameInfo.Continents[eContinentType]
                                    table.insert(parts, Locale.Lookup(kContinentDef.Description))
                                else
                                    local pTerritory = Territories.GetTerritoryAt(capturedEvent.StartLocation)
                                    if pTerritory then
                                        table.insert(parts, pTerritory:GetName())
                                    else
                                        table.insert(parts, Locale.Lookup("LOC_CLIMATE_SCREEN_WATER"))
                                    end
                                end
                            end
                        end

                        return JoinNonEmpty(parts, "[NEWLINE]")
                    end, function()
                        if capturedCC then return "" end

                        local parts = {}
                        if capturedDef.EffectString then
                            table.insert(parts, Locale.Lookup(capturedDef.EffectString))
                        end
                        local isCometStrike = capturedDef.RandomEventType == "RANDOM_EVENT_COMET_STRIKE"
                        if capturedEvent.FertilityAdded and capturedEvent.FertilityAdded > 0 then
                            if isCometStrike then
                                table.insert(parts,
                                    Locale.Lookup("LOC_CAI_CLIMATE_DAMAGED_TILES", capturedEvent.FertilityAdded))
                            else
                                table.insert(parts,
                                    Locale.Lookup("LOC_CAI_CLIMATE_FERTILE_TILES", capturedEvent.FertilityAdded))
                            end
                        end
                        if capturedEvent.FertilityAdded and capturedEvent.FertilityAdded < 0 then
                            table.insert(parts,
                                Locale.Lookup("LOC_CAI_CLIMATE_LOST_FERTILE_TILES",
                                    math.abs(capturedEvent.FertilityAdded)))
                        end
                        if capturedEvent.TilesDamaged and capturedEvent.TilesDamaged > 0 then
                            table.insert(parts,
                                Locale.Lookup("LOC_CAI_CLIMATE_DAMAGED_TILES", capturedEvent.TilesDamaged))
                        end
                        if capturedEvent.UnitsLost and capturedEvent.UnitsLost > 0 then
                            table.insert(parts, Locale.Lookup("LOC_CAI_CLIMATE_UNITS_LOST", capturedEvent.UnitsLost))
                        end
                        if capturedEvent.PopLost and capturedEvent.PopLost > 0 then
                            table.insert(parts, Locale.Lookup("LOC_CAI_CLIMATE_POP_LOST", capturedEvent.PopLost))
                        end
                        return JoinNonEmpty(parts, "[NEWLINE]")
                    end)
                    list:AddChild(eventWidget)
                end
            end
        end
    end

    return list
end

-- =========================================================================
-- PANEL BUILD / LIFECYCLE
-- =========================================================================
local function PopPanel()
    if mgr and m_panel and mgr:GetWidgetById(PANEL_ID) then
        mgr:RemoveFromStack(PANEL_ID)
    end
    m_panel = nil
    m_tabControl = nil
end

local function BuildPanel()
    if not mgr then return end
    PopPanel()

    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == nil or localPlayerID < 0 then return end

    m_panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function()
            return Controls.ModalScreenTitle:GetText() or Locale.Lookup("LOC_CLIMATE_TITLE")
        end,
    })

    m_tabControl = mgr:CreateWidget(MakeId("CAIClm_"), "TabControl", {})

    -- Overview tab
    m_tabControl:AddPage(function() return Locale.Lookup("LOC_CLIMATE_TAB_OVERVIEW") end)
        :AddChild(BuildOverviewTree())

    -- CO2 Levels tab
    m_tabControl:AddPage(function() return Locale.Lookup("LOC_CLIMATE_TAB_CO2_LEVELS") end)
        :AddChild(BuildCO2Tree())

    -- Event History tab
    m_tabControl:AddPage(function() return Locale.Lookup("LOC_CLIMATE_TAB_EVENT_HISTORY") end)
        :AddChild(BuildEventHistoryList())

    m_panel:AddChild(m_tabControl)

    local vanillaTabButtons = {
        Controls.ButtonOverview,
        Controls.ButtonCO2Levels,
        Controls.ButtonEventHistory,
    }
    m_tabControl:On("value_changed", function(_, pageIndex)
        if m_isMirroringTab then return end
        m_isMirroringTab = true
        local btn = vanillaTabButtons[pageIndex]
        if btn then btn:DoLeftClick() end
        m_isMirroringTab = false
    end)

    m_panel:AddInputBindings({
        {
            Key = Keys.VK_ESCAPE,
            MSG = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_CLOSE",
            Action = function()
                Close()
                return true
            end,
        },
    })

    mgr:Push(m_panel)
end

-- Wrap Open
local BASE_Open = Open
function Open(selectedTabName)
    BASE_Open(selectedTabName)
    if not ContextPtr:IsHidden() then
        BuildPanel()
        if m_tabControl then
            if selectedTabName == "CO2Levels" then
                m_tabControl:SetActivePageByIndex(2)
            elseif selectedTabName == "EventHistory" then
                m_tabControl:SetActivePageByIndex(3)
            else
                m_tabControl:SetActivePageByIndex(1)
            end
        end
    end
end

-- Wrap Close
local BASE_Close = Close
function Close()
    PopPanel()
    BASE_Close()
end

-- Vanilla -> CAI tab sync
TabSelectOverview = WrapFunc(TabSelectOverview, function(orig)
    orig()
    if not m_isMirroringTab and m_tabControl then
        m_isMirroringTab = true
        m_tabControl:SetActivePageByIndex(1)
        m_isMirroringTab = false
    end
end)

TabSelectCO2Levels = WrapFunc(TabSelectCO2Levels, function(orig)
    orig()
    if not m_isMirroringTab and m_tabControl then
        m_isMirroringTab = true
        m_tabControl:SetActivePageByIndex(2)
        m_isMirroringTab = false
    end
end)

TabSelectEventHistory = WrapFunc(TabSelectEventHistory, function(orig)
    orig()
    if not m_isMirroringTab and m_tabControl then
        m_isMirroringTab = true
        m_tabControl:SetActivePageByIndex(3)
        m_isMirroringTab = false
    end
end)

-- Rebuild on turn activation while open
local BASE_OnPlayerTurnActivated = OnPlayerTurnActivated
function OnPlayerTurnActivated(ePlayer, isFirstTime)
    if ContextPtr:IsHidden() == false and ePlayer == Game.GetLocalPlayer() then
        PopPanel()
    end
    BASE_OnPlayerTurnActivated(ePlayer, isFirstTime)
end

-- Input handler wrap
local BASE_OnInputHandler = OnInputHandler
function OnInputHandler(pInputStruct)
    if not ContextPtr:IsHidden() and mgr and m_panel then
        if mgr:HandleInput(pInputStruct) then
            return true
        end
    end
    return BASE_OnInputHandler(pInputStruct)
end

ContextPtr:SetInputHandler(OnInputHandler, true)
