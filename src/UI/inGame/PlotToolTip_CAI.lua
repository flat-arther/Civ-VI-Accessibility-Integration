include("caiUtils")
include("unitHelpers_CAI")
include("PlotToolTip")

local currentPlot = -1
local info = ExposedMembers.CAIInfo or {}
ExposedMembers.CAIInfo = info

--# Constants

local INFO_PRIORITY = {
    "plotName",
    "TileType",
    "Feature",
    "Units",
    "MovementInfo",
    "NaturalWonder",
    "Resources",
    "Buildings",
    "Owner",
    "NationalPark",
    "Movement",
    "Defense",
    "Continent",
    "Appeal",
    "Status",
    "Geography",
}

PlotInfoActionPriority = {
    "Summary",
    "TileType",
    "FeatureInfo",
    "Units",
    "MovementInfo",
    "Resources",
    "Buildings",
    "Owner",
    "PhysicalInfo",
    "AmbientInfo",
}

PlotInfoActionMap = {}

--# Local utilities

local function GetCurrentCursorPlot()
    return Map.GetPlotByIndex(currentPlot)
end

local function GetPlotInfoCoords(plot)
    if not plot then return nil end
    return tostring(plot:GetX()) .. ", " .. tostring(plot:GetY())
end

local function AppendPlotInfo(results, value)
    if type(value) == "table" then
        for _, s in ipairs(value) do
            if s and s ~= "" then table.insert(results, s) end
        end
    elseif value and value ~= "" then
        table.insert(results, value)
    end
end

local function RequestWithFallback(plot, rawKeys, visibleFallback)
    local r = info:RequestPlotInfo(plot, rawKeys)
    if #r > 0 then return r end
    if not info.IsPlotVisible(plot:GetIndex()) then
        return { Locale.Lookup("LOC_MINIMAP_FOG_OF_WAR_TOOLTIP") }
    end
    return { Locale.Lookup(visibleFallback) }
end

local function GetPlotUnitFormationSuffix(unit)
    if unit == nil then return nil end

    local unitInfo = GameInfo.Units[unit:GetUnitType()]
    if unitInfo == nil then return nil end

    local formation = unit:GetMilitaryFormation()
    if formation == MilitaryFormationTypes.CORPS_FORMATION then
        if unitInfo.Domain == "DOMAIN_SEA" then
            return Locale.Lookup("LOC_HUD_UNIT_PANEL_FLEET_SUFFIX")
        end
        return Locale.Lookup("LOC_HUD_UNIT_PANEL_CORPS_SUFFIX")
    elseif formation == MilitaryFormationTypes.ARMY_FORMATION then
        if unitInfo.Domain == "DOMAIN_SEA" then
            return Locale.Lookup("LOC_HUD_UNIT_PANEL_ARMADA_SUFFIX")
        end
        return Locale.Lookup("LOC_HUD_UNIT_PANEL_ARMY_SUFFIX")
    end

    return nil
end

local function GetPlotUnitDisplayName(unit)
    if unit == nil then return nil end

    local name = Locale.Lookup(unit:GetName())
    local formationSuffix = GetPlotUnitFormationSuffix(unit)
    if formationSuffix ~= nil then
        name = name .. " " .. formationSuffix
    end

    return name
end

--# Visibility

function info.IsPlotVisible(plot)
    if not plot then return false end
    local observer = Game.GetLocalObserver()
    if observer == PlayerTypes.OBSERVER then return true end
    local vis = PlayersVisibility[observer]
    if not vis then return false end
    return vis:IsRevealed(plot)
end

--# Raw plot info helpers

---@type table<string, fun(data:table):string[]|string|nil>
info.PlotInfoHelpers = {
    plotName = function(data)
        if not data.IsVisible then
            return Locale.Lookup("LOC_MINIMAP_FOG_OF_WAR_TOOLTIP")
        end
        if data.IsLake then
            return Locale.Lookup("LOC_TOOLTIP_LAKE")
        end
        if data.TerrainTypeName == "LOC_TERRAIN_COAST_NAME" then
            return Locale.Lookup("LOC_TOOLTIP_COAST")
        end
        return Locale.Lookup(data.TerrainTypeName)
    end,

    MovementInfo = function(data)
        if UI.GetInterfaceMode() ~= InterfaceModeTypes.MOVE_TO then return end
        local unit = UI.GetHeadSelectedUnit()
        if not unit then return end
        return BuildMovementSpeech(BuildMovementPathInfo(unit, data.Index, false, false))
    end,

    Units = function(data)
        local units = data.Units
        if not units or #units == 0 then return nil end

        local summary = {}
        local appearanceOrder = {}
        for _, unit in ipairs(units) do
            local displayName = GetPlotUnitDisplayName(unit)
            if summary[displayName] == nil then
                summary[displayName] = 1
                table.insert(appearanceOrder, displayName)
            else
                summary[displayName] = summary[displayName] + 1
            end
        end

        local finalStrings = {}
        for _, name in ipairs(appearanceOrder) do
            table.insert(finalStrings, summary[name] .. " " .. name)
        end

        return table.concat(finalStrings, ", ")
    end,

    Owner = function(data)
        if not data.IsVisible then return nil end
        if data.Owner == nil then return nil end

        local szOwnerString
        local pPlayerConfig = PlayerConfigurations[data.Owner]

        if pPlayerConfig ~= nil then
            szOwnerString = Locale.Lookup(pPlayerConfig:GetCivilizationShortDescription())
        end

        if szOwnerString == nil or string.len(szOwnerString) == 0 then
            szOwnerString = Locale.Lookup("LOC_TOOLTIP_PLAYER_ID", data.Owner)
        end

        local pPlayer = Players[data.Owner]
        if GameConfiguration:IsAnyMultiplayer() and pPlayer ~= nil and pPlayer:IsHuman() then
            szOwnerString = szOwnerString .. " (" .. Locale.Lookup(pPlayerConfig:GetPlayerName()) .. ")"
        end

        return Locale.Lookup("LOC_TOOLTIP_CITY_OWNER", szOwnerString, data.OwningCityName)
    end,

    Feature = function(data)
        if not data.IsVisible then return nil end
        if data.FeatureType == nil then return nil end

        local szFeatureString = Locale.Lookup(GameInfo.Features[data.FeatureType].Name)
        local localPlayer = Players[Game.GetLocalPlayer()]
        local addCivicName = GameInfo.Features[data.FeatureType].AddCivic

        if localPlayer ~= nil and addCivicName ~= nil then
            local civicIndex = GameInfo.Civics[addCivicName].Index
            if localPlayer:GetCulture():HasCivic(civicIndex) then
                local szAdditionalString
                if not data.FeatureAdded then
                    szAdditionalString = Locale.Lookup("LOC_TOOLTIP_PLOT_WOODS_OLD_GROWTH")
                else
                    szAdditionalString = Locale.Lookup("LOC_TOOLTIP_PLOT_WOODS_SECONDARY")
                end
                szFeatureString = szFeatureString .. " " .. szAdditionalString
            end
        end

        return szFeatureString
    end,

    NationalPark = function(data)
        if not data.IsVisible then return nil end
        if data.NationalPark ~= "" then
            return data.NationalPark
        end
        return nil
    end,

    Resources = function(data)
        if not data.IsVisible then return nil end
        if data.ResourceType == nil then return "" end

        local resourceType = data.ResourceType
        local resource = GameInfo.Resources[resourceType]
        if resource == nil then return nil end

        local resourceHash = GameInfo.Resources[resourceType].Hash
        local resourceString = Locale.Lookup(resource.Name)
        local terrainType = data.TerrainType
        local featureType = data.FeatureType
        local resourceTechType = nil

        local valid_feature = false
        local valid_terrain = false
        local valid_resources = false

        for row in GameInfo.Improvement_ValidResources() do
            if row.ResourceType == resourceType then
                local improvementType = row.ImprovementType
                local improvement = GameInfo.Improvements[improvementType]

                if improvement ~= nil then
                    local has_feature = false
                    for inner_row in GameInfo.Improvement_ValidFeatures() do
                        if inner_row.ImprovementType == improvementType then
                            has_feature = true
                            if inner_row.FeatureType == featureType then
                                valid_feature = true
                            end
                        end
                    end
                    if not has_feature then
                        valid_feature = true
                    end

                    local has_terrain = false
                    for inner_row in GameInfo.Improvement_ValidTerrains() do
                        if inner_row.ImprovementType == improvementType then
                            has_terrain = true
                            if inner_row.TerrainType == terrainType then
                                valid_terrain = true
                            end
                        end
                    end
                    if not has_terrain then
                        valid_terrain = true
                    end

                    for inner_row in GameInfo.Improvement_ValidResources() do
                        if inner_row.ImprovementType == improvementType then
                            if inner_row.ResourceType == resourceType then
                                valid_resources = true
                                break
                            end
                        end
                    end

                    if terrainType ~= nil and GameInfo.Terrains[terrainType] ~= nil then
                        if GameInfo.Terrains[terrainType].TerrainType == "TERRAIN_COAST" then
                            if improvement.Domain == "DOMAIN_SEA" then
                                valid_terrain = true
                            elseif improvement.Domain == "DOMAIN_LAND" then
                                valid_terrain = false
                            end
                        else
                            if improvement.Domain == "DOMAIN_SEA" then
                                valid_terrain = false
                            elseif improvement.Domain == "DOMAIN_LAND" then
                                valid_terrain = true
                            end
                        end
                    end

                    if (valid_feature and valid_terrain) or valid_resources then
                        resourceTechType = improvement.PrereqTech
                        break
                    end
                end
            end
        end

        local localPlayer = Players[Game.GetLocalPlayer()]
        if localPlayer ~= nil then
            local playerResources = localPlayer:GetResources()
            if playerResources:IsResourceVisible(resourceHash) then
                if resourceTechType ~= nil and ((valid_feature and valid_terrain) or valid_resources) then
                    local playerTechs = localPlayer:GetTechs()
                    local techType = GameInfo.Technologies[resourceTechType]

                    if techType ~= nil and not playerTechs:HasTech(techType.Index) then
                        resourceString =
                            resourceString ..
                            "[COLOR:Civ6Red]  ( " ..
                            Locale.Lookup("LOC_TOOLTIP_REQUIRES") .. " " ..
                            Locale.Lookup(techType.Name) ..
                            ")[ENDCOLOR]"
                    end
                end

                return resourceString
            end
        elseif GameConfiguration.IsWorldBuilderEditor() then
            if resourceTechType ~= nil and ((valid_feature and valid_terrain) or valid_resources) then
                local techType = GameInfo.Technologies[resourceTechType]
                if techType ~= nil then
                    resourceString =
                        resourceString ..
                        "( " ..
                        Locale.Lookup("LOC_TOOLTIP_REQUIRES") .. " " ..
                        Locale.Lookup(techType.Name) ..
                        ")[ENDCOLOR]"
                end
            end

            return resourceString
        end

        return nil
    end,

    Geography = function(data)
        if not data.IsVisible then return nil end
        local results = {}

        if data.IsRiver then
            table.insert(results, Locale.Lookup("LOC_TOOLTIP_RIVER"))
        end

        if data.IsNWOfCliff or data.IsWOfCliff or data.IsNEOfCliff then
            table.insert(results, Locale.Lookup("LOC_TOOLTIP_CLIFF"))
        end

        return #results > 0 and results or nil
    end,

    Movement = function(data)
        if not data.IsVisible then return nil end
        local results = {}

        if not data.Impassable and data.MovementCost > 0 then
            table.insert(results, Locale.Lookup("LOC_TOOLTIP_MOVEMENT_COST", data.MovementCost))
        end

        if data.IsRoute then
            local routeInfo = GameInfo.Routes[data.RouteType]
            if routeInfo ~= nil and routeInfo.MovementCost ~= nil and routeInfo.Name ~= nil then
                if data.RoutePillaged then
                    table.insert(results,
                        Locale.Lookup("LOC_TOOLTIP_ROUTE_MOVEMENT_PILLAGED", routeInfo.MovementCost, routeInfo.Name))
                else
                    table.insert(results,
                        Locale.Lookup("LOC_TOOLTIP_ROUTE_MOVEMENT", routeInfo.MovementCost, routeInfo.Name))
                end
            end
        end

        return #results > 0 and results or nil
    end,

    Defense = function(data)
        if not data.IsVisible then return nil end
        if data.DefenseModifier ~= 0 then
            return Locale.Lookup("LOC_TOOLTIP_DEFENSE_MODIFIER", data.DefenseModifier)
        end
        return nil
    end,

    Appeal = function(data)
        if not data.IsVisible then return nil end
        local feature = nil
        if data.FeatureType ~= nil then
            feature = GameInfo.Features[data.FeatureType]
        end

        if GameCapabilities.HasCapability("CAPABILITY_LENS_APPEAL") then
            if ((data.FeatureType ~= nil and feature ~= nil and feature.NaturalWonder) or not data.IsWater) then
                for row in GameInfo.AppealHousingChanges() do
                    if data.Appeal >= row.MinimumValue then
                        return Locale.Lookup("LOC_TOOLTIP_APPEAL", Locale.Lookup(row.Description), data.Appeal)
                    end
                end
            end
        end

        return nil
    end,

    Continent = function(data)
        if not data.IsVisible then return nil end
        if data.Continent ~= nil then
            return Locale.Lookup("LOC_TOOLTIP_CONTINENT", GameInfo.Continents[data.Continent].Description)
        end
        return nil
    end,

    TileType = function(data)
        if not data.IsVisible then return nil end
        local results = {}

        if data.WonderType ~= nil then
            if data.WonderComplete then
                table.insert(results, Locale.Lookup(GameInfo.Buildings[data.WonderType].Name))
            else
                table.insert(results,
                    Locale.Lookup(GameInfo.Buildings[data.WonderType].Name) ..
                    " " .. Locale.Lookup("LOC_TOOLTIP_PLOT_CONSTRUCTION_TEXT"))
            end
            return results
        end

        if data.IsCity == true and data.DistrictType ~= nil then
            table.insert(results, Locale.Lookup(GameInfo.Districts[data.DistrictType].Name))
            for yieldType, v in pairs(data.Yields) do
                local yield = GameInfo.Yields[yieldType]
                table.insert(results, tostring(v) .. Locale.Lookup(yield.IconString) .. Locale.Lookup(yield.Name))
            end
            return results
        end

        if data.DistrictID ~= -1 and data.DistrictType ~= nil then
            if not GameInfo.Districts[data.DistrictType].InternalOnly then
                if data.Owner ~= nil and data.Owner == Game.GetLocalPlayer() and data.Yields ~= nil then
                    if table.count(data.Yields) > 0 then
                        table.insert(results, Locale.Lookup("LOC_PEDIA_CONCEPTS_PAGE_CITIES_9_CHAPTER_CONTENT_TITLE"))
                    end
                    for yieldType, v in pairs(data.Yields) do
                        local yield = GameInfo.Yields[yieldType]
                        table.insert(results, tostring(v) .. Locale.Lookup(yield.IconString) .. Locale.Lookup(yield.Name))
                    end
                end

                local name = Locale.Lookup(GameInfo.Districts[data.DistrictType].Name)
                if data.DistrictPillaged then
                    name = name .. " " .. Locale.Lookup("LOC_TOOLTIP_PLOT_PILLAGED_TEXT")
                elseif not data.DistrictComplete then
                    name = name .. " " .. Locale.Lookup("LOC_TOOLTIP_PLOT_CONSTRUCTION_TEXT")
                end

                table.insert(results, name)

                if data.DistrictYields ~= nil then
                    for yieldType, v in pairs(data.DistrictYields) do
                        local yield = GameInfo.Yields[yieldType]
                        table.insert(results, tostring(v) .. Locale.Lookup(yield.IconString) .. Locale.Lookup(yield.Name))
                    end
                end
            end
            return results
        end

        if data.Impassable then
            return { Locale.Lookup("LOC_TOOLTIP_PLOT_IMPASSABLE_TEXT") }
        end

        if data.ImprovementType ~= nil then
            local name = Locale.Lookup(GameInfo.Improvements[data.ImprovementType].Name)
            if data.ImprovementPillaged then
                name = name .. " " .. Locale.Lookup("LOC_TOOLTIP_PLOT_PILLAGED_TEXT")
            end
            table.insert(results, name)
        end

        for yieldType, v in pairs(data.Yields) do
            local yield = GameInfo.Yields[yieldType]
            table.insert(results, tostring(v) .. Locale.Lookup(yield.IconString) .. Locale.Lookup(yield.Name))
        end

        return results
    end,

    NaturalWonder = function(data)
        if not data.IsVisible then return nil end
        if data.FeatureType ~= nil then
            local feature = GameInfo.Features[data.FeatureType]
            if feature ~= nil and feature.NaturalWonder then
                return Locale.Lookup(feature.Description)
            end
        end
        return nil
    end,

    Buildings = function(data)
        if not data.IsVisible then return nil end
        if not (data.IsCity or data.WonderType ~= nil or data.DistrictID ~= -1) then return nil end
        if data.BuildingNames == nil or table.count(data.BuildingNames) == 0 then return nil end

        local results = {}
        local cityBuildings = data.OwnerCity:GetBuildings()
        local greatWorksSection = {}

        if data.WonderType == nil then
            table.insert(results, Locale.Lookup("LOC_TOOLTIP_PLOT_BUILDINGS_TEXT"))
        end

        for i, v in ipairs(data.BuildingNames) do
            if data.WonderType == nil then
                if data.BuildingsPillaged[i] then
                    table.insert(results,
                        "- " .. Locale.Lookup(v) .. " " .. Locale.Lookup("LOC_TOOLTIP_PLOT_PILLAGED_TEXT"))
                else
                    table.insert(results, "- " .. Locale.Lookup(v))
                end
            end

            local slots = cityBuildings:GetNumGreatWorkSlots(data.BuildingTypes[i])
            for j = 0, slots - 1 do
                local idx = cityBuildings:GetGreatWorkInSlot(data.BuildingTypes[i], j)
                if idx ~= -1 then
                    local gwType = cityBuildings:GetGreatWorkTypeFromIndex(idx)
                    table.insert(greatWorksSection, "- " .. Locale.Lookup(GameInfo.GreatWorks[gwType].Name))
                end
            end
        end

        if #greatWorksSection > 0 then
            table.insert(results, Locale.Lookup("LOC_GREAT_WORKS") .. ":")
            for _, v in ipairs(greatWorksSection) do
                table.insert(results, v)
            end
        end

        return results
    end,

    Status = function(data)
        if not data.IsVisible then return nil end
        local results = {}

        if data.Owner == Game.GetLocalPlayer() and data.Workers > 0 then
            table.insert(results, Locale.Lookup("LOC_TOOLTIP_PLOT_WORKED_TEXT", data.Workers))
        end

        if data.Fallout > 0 then
            table.insert(results, Locale.Lookup("LOC_TOOLTIP_PLOT_CONTAMINATED_TEXT", data.Fallout))
        end

        return #results > 0 and results or nil
    end,
}

--# Plot info request

---@param plot Plot
---@param requestedKeys string[]|nil
---@return string[]
function info:RequestPlotInfo(plot, requestedKeys)
    if not plot then return { "No plot" } end
    requestedKeys = requestedKeys or INFO_PRIORITY

    local vis = self.IsPlotVisible(plot:GetIndex())
    local units = Units.GetUnitsInPlotLayerID(plot:GetX(), plot:GetY(), MapLayers.ANY)
    local data = FetchData(plot)
    FetchAdditionalData(plot, data)
    data.IsVisible = vis
    data.Units = units

    local results = {}
    for _, key in ipairs(requestedKeys) do
        local helper = self.PlotInfoHelpers[key]
        if helper then
            local output = helper(data)
            if type(output) == "table" then
                for _, s in ipairs(output) do
                    if s and s ~= "" then table.insert(results, s) end
                end
            elseif type(output) == "string" and output ~= "" then
                table.insert(results, output)
            end
        end
    end
    return results
end

--# Bucket helpers (10 collapsed slots for keyboard access)

info.PlotInfo = {
    Summary      = function(plot)
        local r = { GetPlotInfoCoords(plot) }
        AppendPlotInfo(r, info:RequestPlotInfo(plot, { "plotName" }))
        return r
    end,

    TileType     = function(plot) return RequestWithFallback(plot, { "TileType" }, "LOC_CAI_PLOT_NO_TILE_INFO") end,
    FeatureInfo  = function(plot)
        return RequestWithFallback(plot, { "Feature", "NaturalWonder" },
            "LOC_CAI_PLOT_NO_FEATURES")
    end,
    Units        = function(plot) return RequestWithFallback(plot, { "Units" }, "LOC_CAI_PLOT_NO_UNITS") end,
    MovementInfo = function(plot) return RequestWithFallback(plot, { "MovementInfo" }, "LOC_CAI_PLOT_NO_MOVEMENT_PREVIEW") end,
    Resources    = function(plot) return RequestWithFallback(plot, { "Resources" }, "LOC_CAI_PLOT_NO_RESOURCES") end,
    Buildings    = function(plot) return RequestWithFallback(plot, { "Buildings" }, "LOC_CAI_PLOT_NO_BUILDINGS") end,
    Owner        = function(plot) return RequestWithFallback(plot, { "Owner" }, "LOC_CAI_PLOT_UNOWNED") end,
    PhysicalInfo = function(plot)
        return RequestWithFallback(plot, { "Movement", "Defense", "Geography" },
            "LOC_CAI_PLOT_NO_PHYSICAL_INFO")
    end,
    AmbientInfo  = function(plot)
        return RequestWithFallback(plot, { "Continent", "Appeal", "Status", "NationalPark" },
            "LOC_CAI_PLOT_NO_AMBIENT_INFO")
    end,
}

info.PlotInfoActionPriority = PlotInfoActionPriority

--# Action map

function InitializePlotInfoActionMap()
    PlotInfoActionMap = {
        [Input.GetActionId("PlotInfo1")]  = { "Summary" },
        [Input.GetActionId("PlotInfo2")]  = { "TileType" },
        [Input.GetActionId("PlotInfo3")]  = { "FeatureInfo" },
        [Input.GetActionId("PlotInfo4")]  = { "Units" },
        [Input.GetActionId("PlotInfo5")]  = { "MovementInfo" },
        [Input.GetActionId("PlotInfo6")]  = { "Resources" },
        [Input.GetActionId("PlotInfo7")]  = { "Buildings" },
        [Input.GetActionId("PlotInfo8")]  = { "Owner" },
        [Input.GetActionId("PlotInfo9")]  = { "PhysicalInfo" },
        [Input.GetActionId("PlotInfo10")] = { "AmbientInfo" },
    }
end

--# Input handler

function OnPlotInfoInputActionTriggered(actionId)
    local bucketKeys = PlotInfoActionMap[actionId]
    if not bucketKeys then return end
    local plot = GetCurrentCursorPlot()
    if not plot then return end
    local results = {}
    for _, key in ipairs(bucketKeys) do
        local helper = info.PlotInfo[key]
        if helper then AppendPlotInfo(results, helper(plot)) end
    end
    if #results > 0 then Speak(ProcessIcons(table.concat(results, "\n"))) end
end

--# Cursor move handler

function OnCAICursorMove(x, y, plot, cursor)
    if plot then currentPlot = plot:GetIndex() end
    local results = {}
    AppendPlotInfo(results, GetPlotInfoCoords(plot))
    AppendPlotInfo(results, info:RequestPlotInfo(plot))
    if #results > 0 then Speak(ProcessIcons(table.concat(results, "\n"))) end
end

--# Init

InitializePlotInfoActionMap()
Events.InputActionTriggered.Add(OnPlotInfoInputActionTriggered)
LuaEvents.CAICursorMoved.Add(OnCAICursorMove)
