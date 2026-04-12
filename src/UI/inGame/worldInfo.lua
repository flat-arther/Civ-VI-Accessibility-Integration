local info = {}

--# Plot info
-- Default used to sort plot info when 'RequestPlotInfo' is called
local INFO_PRIORITY = {
    "plotName",
    "TileType",
    "Feature",
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
    "Geography"
}

--- The following functions and variables are copied streight out of the game's native 'PlotToolTip.lua'. They deal with fetching and compiling info on a given plot, and there is no need for me to reinvent the wheel when it comes to that. 
--- We cannot use the original tooltip functionality either; as such, replacing that file is unnecessary for the moment.

--# Copied variables
-- This is horrible, i'm sorry.
--- Yep, it sure is
local TerrainTypeMap :table = {};
do
	for row in GameInfo.Terrains() do
		TerrainTypeMap[row.Index] = row.TerrainType;
	end
end

local FeatureTypeMap :table = {};
do
	for row in GameInfo.Features() do
		FeatureTypeMap[row.Index] = row.FeatureType;
	end
end

local ImprovementTypeMap :table = {};
do
	for row in GameInfo.Improvements() do
		ImprovementTypeMap[row.Index] = row.ImprovementType;
	end
end

local ResourceTypeMap :table = {};
do
	for row in GameInfo.Resources() do
		ResourceTypeMap[row.Index] = row.ResourceType;
	end
end

local UnitTypeMap :table = {};
do
	for row in GameInfo.Units() do
		UnitTypeMap[row.Index] = row.UnitType;
	end
end

local BuildingTypeMap :table = {};
do
	for row in GameInfo.Buildings() do
		BuildingTypeMap[row.Index] = row.BuildingType;
	end
end

local DistrictTypeMap :table = {};
do
	for row in GameInfo.Districts() do
		DistrictTypeMap[row.Index] = row.DistrictType;
	end
end

local ContinentTypeMap :table = {};
do
	for row in GameInfo.Continents() do
		ContinentTypeMap[row.Index] = row.ContinentType;
	end
end

--# Copied functions
-- ===========================================================================
-- Collect plot data and return it as a table
-- ===========================================================================
function FetchData( plot:table )

	local kFalloutManager = Game.GetFalloutManager();

	return {
		X		= plot:GetX(),
		Y		= plot:GetY(),
		Index	= plot:GetIndex(),
		Appeal				= plot:GetAppeal(),
		Continent			= ContinentTypeMap[plot:GetContinentType()] or nil,
		DefenseModifier		= plot:GetDefenseModifier(),
		DistrictID			= plot:GetDistrictID(),
		DistrictComplete	= false,
		DistrictPillaged	= false,
		DistrictType		= DistrictTypeMap[plot:GetDistrictType()],
		Fallout				= kFalloutManager:GetFalloutTurnsRemaining(plot:GetIndex());
		FeatureType			= FeatureTypeMap[plot:GetFeatureType()],
		FeatureAdded		= plot:HasFeatureBeenAdded();
		Impassable			= plot:IsImpassable();
		ImprovementType		= ImprovementTypeMap[plot:GetImprovementType()],
		ImprovementPillaged = plot:IsImprovementPillaged(),
		IsCity				= plot:IsCity(),
		IsLake				= plot:IsLake(),
		IsRiver				= plot:IsRiver(),				
		IsRoute				= plot:IsRoute(),
		IsWater				= plot:IsWater(),
		MovementCost		= plot:GetMovementCost(),
		Owner				= (plot:GetOwner() ~= -1) and plot:GetOwner() or nil,
		OwnerCity			= Cities.GetPlotPurchaseCity(plot);
		ResourceCount		= plot:GetResourceCount(),
		ResourceType		= ResourceTypeMap[plot:GetResourceType()],
		RoutePillaged		= plot:IsRoutePillaged(),
		RouteType			= plot:GetRouteType(),
		TerrainType			= TerrainTypeMap[plot:GetTerrainType()],
		TerrainTypeName		= (TerrainTypeMap[plot:GetTerrainType()] ~= nil) and GameInfo.Terrains[TerrainTypeMap[plot:GetTerrainType()]].Name or " ",
		WonderComplete		= false,
		WonderType			= BuildingTypeMap[plot:GetWonderType()],
		Workers				= plot:GetWorkerCount();
	
		-- Remove these once we have a visualization of cliffs
		IsNWOfCliff			= plot:IsNWOfCliff(),  
		IsWOfCliff			= plot:IsWOfCliff(),
		IsNEOfCliff			= plot:IsNEOfCliff(),
		---- END REMOVE
	
		BuildingNames		= {},
		BuildingsPillaged	= {},
		BuildingTypes		= {},
		Constructions		= {},
		Yields				= {},
		DistrictYields		= {},
	};
end

-- ===========================================================================
-- TODO: Fix this up as it's a bit aribtrary as to what is "data" and what is "additional data"
-- ===========================================================================
function FetchAdditionalData( pPlot:table, kPlotData:table )

	if pPlot:IsNationalPark() then
		kPlotData.NationalPark = pPlot:GetNationalParkName();
	else
		kPlotData.NationalPark = "";
	end
				
	local plotId = pPlot:GetIndex();

	if (kPlotData.OwnerCity) then
		kPlotData.OwningCityName = kPlotData.OwnerCity:GetName();

		local eDistrictType = pPlot:GetDistrictType();
		if (eDistrictType) then
			local cityDistricts = kPlotData.OwnerCity:GetDistricts();
			if (cityDistricts) then
				if (cityDistricts:IsPillaged(eDistrictType, plotId)) then
					kPlotData.DistrictPillaged = true;
				end
				if (cityDistricts:IsComplete(eDistrictType, plotId)) then
					kPlotData.DistrictComplete = true;
				end
			end
		end

		local cityBuildings = kPlotData.OwnerCity:GetBuildings();
		if (cityBuildings) then
			local buildingTypes = cityBuildings:GetBuildingsAtLocation(plotId);
			for _, type in ipairs(buildingTypes) do
				local building = GameInfo.Buildings[type];
				table.insert(kPlotData.BuildingTypes, type);
				local name = building.Name;
				if (cityBuildings.GetBuildingNameOverride ~= nil) then
					local overrideName = cityBuildings:GetBuildingNameOverride(building.Index)
					name = overrideName or name;
				end
				table.insert(kPlotData.BuildingNames, name);
				local bPillaged = cityBuildings:IsPillaged(type);
				table.insert(kPlotData.BuildingsPillaged, bPillaged);
			end
			if (cityBuildings:HasBuilding(pPlot:GetWonderType())) then
				kPlotData.WonderComplete = true;
			end
		end

		local cityBuildQueue = kPlotData.OwnerCity:GetBuildQueue();
		if (cityBuildQueue) then
			local constructionTypes = cityBuildQueue:GetConstructionsAtLocation(plotId);
			for _, type in ipairs(constructionTypes) do
				local construction = GameInfo.Buildings[type];
				local name = GameInfo.Buildings[construction.BuildingType].Name;
				table.insert(kPlotData.Constructions, name);
			end
		end
	end

	-- Plot yields
	if GameCapabilities.HasCapability("CAPABILITY_DISPLAY_PLOT_YIELDS") then
		if (kPlotData.IsCity == true or kPlotData.DistrictID == -1) then
			for row in GameInfo.Yields() do
				local yield = pPlot:GetYield(row.Index);
				if (yield > 0) then
					kPlotData.Yields[row.YieldType] = yield;
				end
			end	
		else
			local plotOwner = pPlot:GetOwner();
			local plotPlayer = Players[plotOwner];
			local district = plotPlayer:GetDistricts():FindID(kPlotData.DistrictID);
			if district ~= nil then
				for row in GameInfo.Yields() do
					local yield = pPlot:GetYield(row.Index);
					local workers = pPlot:GetWorkerCount();
					if (yield > 0 and workers > 0) then
						yield = yield * workers;
						kPlotData.Yields[row.YieldType] = yield;
					end

					local districtYield = district:GetYield(row.Index);
					if (districtYield > 0) then
						kPlotData.DistrictYields[row.YieldType] = districtYield;
					end

				end
			end
		end
	end
end


--# Plot info helpers: this is a redo of the original GetDetails function from 'plotToolTip.lua'. It allows us to request specific info without having to dump the entire table
---@type table<string, fun(data:table):string[]|string|nil>
info.PlotInfoHelpers = {
    plotName = function(data)
        if data.IsLake then
            return Locale.Lookup("LOC_TOOLTIP_LAKE")
        end
        if data.TerrainTypeName == "LOC_TERRAIN_COAST_NAME" then
            return Locale.Lookup("LOC_TOOLTIP_COAST")
        end
        return Locale.Lookup(data.TerrainTypeName)
    end,

Owner = function(data)
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
    if data.NationalPark ~= "" then
        return data.NationalPark
    end
    return nil
end,

Resources = function(data)
    if data.ResourceType == nil then
        return ""
    end
    local resourceType = data.ResourceType
    local resource = GameInfo.Resources[resourceType]
    if resource == nil then
        return nil
    end

    local resourceHash = GameInfo.Resources[resourceType].Hash;
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
    local results = {}

    if not data.Impassable and data.MovementCost > 0 then
        table.insert(results, Locale.Lookup("LOC_TOOLTIP_MOVEMENT_COST", data.MovementCost))
    end

    if data.IsRoute then
        local routeInfo = GameInfo.Routes[data.RouteType]
        if routeInfo ~= nil and routeInfo.MovementCost ~= nil and routeInfo.Name ~= nil then
            if data.RoutePillaged then
                table.insert(results, Locale.Lookup("LOC_TOOLTIP_ROUTE_MOVEMENT_PILLAGED", routeInfo.MovementCost, routeInfo.Name))
            else
                table.insert(results, Locale.Lookup("LOC_TOOLTIP_ROUTE_MOVEMENT", routeInfo.MovementCost, routeInfo.Name))
            end
        end
    end

    return #results > 0 and results or nil
end,

Defense = function(data)
    if data.DefenseModifier ~= 0 then
        return Locale.Lookup("LOC_TOOLTIP_DEFENSE_MODIFIER", data.DefenseModifier)
    end
    return nil
end,

Appeal = function(data)
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
    if data.Continent ~= nil then
        return Locale.Lookup("LOC_TOOLTIP_CONTINENT", GameInfo.Continents[data.Continent].Description)
    end
    return nil
end,

TileType = function(data)
    local results = {}

    if data.WonderType ~= nil then
        if data.WonderComplete then
            table.insert(results, Locale.Lookup(GameInfo.Buildings[data.WonderType].Name))
        else
            table.insert(results, Locale.Lookup(GameInfo.Buildings[data.WonderType].Name) .. " " .. Locale.Lookup("LOC_TOOLTIP_PLOT_CONSTRUCTION_TEXT"))
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
    if data.FeatureType ~= nil then
        local feature = GameInfo.Features[data.FeatureType]
        if feature ~= nil and feature.NaturalWonder then
            return Locale.Lookup(feature.Description)
        end
    end
    return nil
end,

Buildings = function(data)
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
                table.insert(results, "- " .. Locale.Lookup(v) .. " " .. Locale.Lookup("LOC_TOOLTIP_PLOT_PILLAGED_TEXT"))
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
    local results = {}

    if data.Owner == Game.GetLocalPlayer() and data.Workers > 0 then
        table.insert(results, Locale.Lookup("LOC_TOOLTIP_PLOT_WORKED_TEXT", data.Workers))
    end

    if data.Fallout > 0 then
        table.insert(results, Locale.Lookup("LOC_TOOLTIP_PLOT_CONTAMINATED_TEXT", data.Fallout))
    end

    return #results > 0 and results or nil
end
}
--# New functions
--- Checks whether or not a plot is visible to the local player
---@param plot Plot
---@return boolean
function info.IsPlotVisible(plot)
    if not plot then 
        return false;
        end
    local observer = Game.GetLocalObserver();
   if observer == PlayerTypes.OBSERVER then
    return true
   else
    local vis = PlayersVisibility[observer];
    if not vis then
        return false;
    else
        return vis:IsRevealed(plot:GetIndex());
    end
    end
end

---@param plot Plot
---@param requestedKeys PlotInfoType[]|nil Array of strings: {"plotName", "Resources", etc}. Set to all info by default
---@return table Array of localized strings
function info:RequestPlotInfo(plot, requestedKeys)
    if not plot then return {"No plot"} end
    if not self.IsPlotVisible(plot) then return {"Unexplored"} end
requestedKeys = requestedKeys or INFO_PRIORITY
    local data = FetchData(plot)
    FetchAdditionalData(plot, data)
    local results = {}
    for _, key in ipairs(requestedKeys) do
        local helper = self.PlotInfoHelpers[key]
        if helper then
            local output = helper(data)
print("Key: " .. key .. " Type: " .. type(output)) 
            if type(output) == "table" then
                if #output > 0 then
    for _, s in ipairs(output) do
        if s and s ~= "" then
            table.insert(results, s)
        end
    end
end
elseif type(output) == "string" and output ~= "" then
    table.insert(results, output)
end
        end
    end
    return results
end

-- Expose this table so it can be used anywhere if needed
ExposedMembers.CAIPlotInfo = info
