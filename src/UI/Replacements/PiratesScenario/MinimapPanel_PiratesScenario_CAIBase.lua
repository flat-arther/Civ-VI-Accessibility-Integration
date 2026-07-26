-- Copyright 2019, Firaxis Games

-- ===========================================================================
-- Base File
-- ===========================================================================
include("MinimapPanel");
include("SupportFunctions");
include("PiratesScenario_PropKeys");
include("PiratesScenario_Shared_Script");


-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local PIRATE_TREASURE_OVERLAY_NAME			:string = "TreasureAreaBorderOverlay";
local INFAMOUS_PIRATE_OVERLAY_NAME			:string = "InfamousPirateZoneOverlay";
local ENGLISH_POINTER_WAVES_OVERLAY_NAME	:string = "EnglishPointerWavesOverlay";
local DOWSING_ROD_WAVES_OVERLAY_NAME		:string = "DowsingRodWavesOverlay";
local PIRATE_TREASURE_OVERLAY_CHANNEL 	:number = 0;
local INFAMOUS_PIRATE_OVERLAY_CHANNEL 	:number = 1;
local SPRITE_PIRATE_TREASURE			:string = "PirateTreasureOverlay"
local SPRITE_PIRATE_TREASURE_MINIMAP	:string = "PirateTreasureOverlayMiniMap"
local COLOR_PIRATE_TREASURE				:number = UI.GetColorValueFromHexLiteral(0xAA00BBFF);
local COLOR_PIRATE_TREASURE_FILL		:number = UI.GetColorValueFromHexLiteral(0xBB00FFFF);
local COLOR_PIRATE_TREASURE_ALT			:number = UI.GetColorValueFromHexLiteral(0xFF00FFFF);
local COLOR_INFAMOUS_PIRATE_ZONE		:number = UI.GetColorValueFromHexLiteral(0x220000FF);
local COLOR_INFAMOUS_PIRATE_ZONE_ALT	:number = UI.GetColorValueFromHexLiteral(0x22000000);
local ms_BuriedTreasureIndex			:number = GameInfo.Improvements["IMPROVEMENT_BURIED_TREASURE"].Index;
local ms_FloatingTreasureIndex			:number = GameInfo.Improvements["IMPROVEMENT_FLOATING_TREASURE"].Index;
local ms_DowsingRodPolicy				:number	= GameInfo.Policies["POLICY_RELIC_DOWSING_ROD"].Index;
local ms_EnglishPointerPolicy			:number	= GameInfo.Policies["POLICY_RELIC_ENGLISH_POINTER"].Index;
local NO_PLOT 							:number = -1;
local m_eBarbGoodyHutHash				:number = DB.MakeHash("BARB_GOODIES");


-- ===========================================================================
--	Variables
-- ===========================================================================
local m_overlayDataDirty			:boolean = false; -- Has the data we are overlaying been changed and needs to be refreshed?
local m_unitWaveDataDirty			:boolean = false; -- Has the data we use for the unit waves changed and needs to be refreshed?
local m_treasureSearchZone			:boolean = false; -- Are we currently displaying an overlay for a treasure search zone?
local m_infamousPirateSearchZone	:boolean = false; -- Are we currently displaying an overlay for an infamous pirate search zone?


-- ===========================================================================
-- Cached Base Functions
-- NOTE:	Expansions name the cached function based on where they are
--			expected to be defined.  Since this is a MOD and its not clear
--			what function this may be saving off, it prefixes functions with
--			a MOD specific "CIVROYALE_" rather than "BASE_" or "XP2_", etc...
-- ===========================================================================
PIRATES_LateInitialize = LateInitialize;
PIRATES_OnShutdown = OnShutdown;


-- ===========================================================================
-- Members
-- ===========================================================================
function ResetOverlays()
	local pTreasureBorderOverlay = UILens.GetOverlay(PIRATE_TREASURE_OVERLAY_NAME);
	if(pTreasureBorderOverlay ~= nil) then
		pTreasureBorderOverlay:ClearAll();
		pTreasureBorderOverlay:SetVisible(true);
		pTreasureBorderOverlay:ShowBorders(true);	
		pTreasureBorderOverlay:ShowHighlights(true);
		pTreasureBorderOverlay:SetBorderColors(PIRATE_TREASURE_OVERLAY_CHANNEL, COLOR_PIRATE_TREASURE, COLOR_PIRATE_TREASURE_ALT);	
		pTreasureBorderOverlay:SetHighlightColor(PIRATE_TREASURE_OVERLAY_CHANNEL, COLOR_PIRATE_TREASURE_FILL);	
	end
	
	local pInfamousPirateBorderOverlay = UILens.GetOverlay(INFAMOUS_PIRATE_OVERLAY_NAME);
	if(pInfamousPirateBorderOverlay ~= nil) then
		pInfamousPirateBorderOverlay:ClearAll();
		pInfamousPirateBorderOverlay:SetVisible(true);
		pInfamousPirateBorderOverlay:ShowBorders(true);	
		pInfamousPirateBorderOverlay:ShowHighlights(true);
		pInfamousPirateBorderOverlay:SetBorderColors(INFAMOUS_PIRATE_OVERLAY_CHANNEL, COLOR_INFAMOUS_PIRATE_ZONE, COLOR_INFAMOUS_PIRATE_ZONE_ALT);	
		pInfamousPirateBorderOverlay:SetHighlightColor(INFAMOUS_PIRATE_OVERLAY_CHANNEL, COLOR_INFAMOUS_PIRATE_ZONE);	
	end
	
	ResetPirateTreasureOverlay();
	ResetAllUnitWaves();
end

function ClearScenarioOverlays()
	local pTreasureSpriteOverlay:object = UILens.GetOverlay(SPRITE_PIRATE_TREASURE);
	if pTreasureSpriteOverlay ~= nil then
		pTreasureSpriteOverlay:ClearAll()
	end
end

function ResetPirateTreasureOverlay()
	m_treasureSearchZone = false;
	m_infamousPirateSearchZone = false;
	local pBorderOverlay:object = UILens.GetOverlay(PIRATE_TREASURE_OVERLAY_NAME);
	if(pBorderOverlay ~= nil ) then
		pBorderOverlay:ClearPlotsByChannel(PIRATE_TREASURE_OVERLAY_CHANNEL);
	end
	local pInfamousPirateBorderOverlay:object = UILens.GetOverlay(INFAMOUS_PIRATE_OVERLAY_NAME);
	if(pInfamousPirateBorderOverlay ~= nil) then
		pInfamousPirateBorderOverlay:ClearPlotsByChannel(INFAMOUS_PIRATE_OVERLAY_CHANNEL);
	end
	
	local localPlayer = Game.GetLocalPlayer();
	local pLocalPlayer :object = Players[localPlayer];
	if(pLocalPlayer == nil) then
		print("local player missing!");
		return;
	end

	local pPlayerVis;
	if (localPlayer and localPlayer >= 0) then
		pPlayerVis = PlayersVisibility[localPlayer];
	end
	if (pPlayerVis == nil) then
		return;
	end
	
	local borderPlots = {};
	local pirateBorderPlots = {};
	local spritePlots = {};
	-- Add the treasure search zones to the border plots.
	local treasureMaps :table = pLocalPlayer:GetProperty(g_playerPropertyKeys.TreasureMaps);
	if(treasureMaps ~= nil) then
		for loop, curTreasureMap in ipairs(treasureMaps) do
			m_treasureSearchZone = true;
			local curSearchCenterPlot :object = Map.GetPlotByIndex(curTreasureMap.SearchCenterIndex);
			local searchPlots :table = Map.GetNeighborPlots(curSearchCenterPlot:GetX(), curSearchCenterPlot:GetY(), curTreasureMap.ZoneSize);
			for loop, searchPlot in ipairs(searchPlots) do
				table.insert(borderPlots, searchPlot:GetIndex());
				table.insert(spritePlots, searchPlot:GetIndex());
			end
		end
	end

	-- Add the Infamous Pirate search zones to the border plots.
	local searchZones = Game:GetProperty(g_gamePropertyKeys.InfamousPirateSearchZones);
	if(searchZones ~= nil) then
		for loop, curSearchZone in ipairs(searchZones) do
			m_infamousPirateSearchZone = true;
			local curSearchZonePlot :object = Map.GetPlotByIndex(curSearchZone.CenterPlotIndex);
			if(curSearchZonePlot ~= nil) then
				local searchPlots :table = Map.GetNeighborPlots(curSearchZonePlot:GetX(), curSearchZonePlot:GetY(), INFAMOUS_PIRATE_SEARCH_ZONE_SIZE);
				for plotLoop, searchPlot in ipairs(searchPlots) do
					table.insert(pirateBorderPlots, searchPlot:GetIndex());
				end
			end
		end
	end

	borderPlots = AddTreasureFleetRoutes(borderPlots);

	if(pBorderOverlay ~= nil ) then
		pBorderOverlay:SetPlotChannel(borderPlots, PIRATE_TREASURE_OVERLAY_CHANNEL);	
	end

	if(pInfamousPirateBorderOverlay ~= nil ) then
		pInfamousPirateBorderOverlay:SetPlotChannel(pirateBorderPlots, INFAMOUS_PIRATE_OVERLAY_CHANNEL);	
	end
	
	-- sprite overlays
	local pOverlay:object = UILens.GetOverlay(SPRITE_PIRATE_TREASURE);
	if pOverlay ~= nil then
		pOverlay:ClearAll()	
		pOverlay:CreateSprites( spritePlots, SPRITE_PIRATE_TREASURE, 0 );
	end
	
	local pOverlay:object = UILens.GetOverlay(SPRITE_PIRATE_TREASURE_MINIMAP);
	if pOverlay ~= nil then
		pOverlay:ClearAll()	
		pOverlay:CreateSprites( spritePlots, SPRITE_PIRATE_TREASURE_MINIMAP, 0 );
	end
end

function AddTreasureFleetRoutes(borderPlots :table)
	-- Add Treasure Fleet exit plot to Infamous Pirate search zone for visibility.
	local treasureFleetPlotIndex = Game:GetProperty(g_gamePropertyKeys.TreasureFleetPlotIndex);
	if(treasureFleetPlotIndex == nil) then
		return borderPlots;
	end

	table.insert(borderPlots, treasureFleetPlotIndex);

	local treasureFleetPaths = Game:GetProperty(g_gamePropertyKeys.TreasureFleetPaths);
	if(treasureFleetPaths ~= nil and #treasureFleetPaths > 0) then
		for pathIndex, curPath in ipairs(treasureFleetPaths) do
			for plotIndex, curPathIndex in ipairs(curPath.PathData) do
				if(curPathIndex ~= nil) then
					table.insert(borderPlots, curPathIndex);
				end
			end
		end
	end

	return borderPlots;
end

function ReadCustomData( key:string )
	local pParameters	:table = UI.GetGameParameters():Get(key);
	local kReturn		:table = {};
	if pParameters ~= nil then
		local count:number = pParameters:GetCount();
		if count == 0 then
			return nil;
		end
		for i = 1, count, 1 do
			local value = pParameters:GetValueAt(i-1);
			table.insert(kReturn, value);
		end
	else
		return nil;
	end
	return unpack(kReturn);
end

-- Only naval ships have unit waves.
function ResetUnitWaves(overlayName :string, policyIndex :number, waveColor :number, findTargetPlotFunc)
	local pWavesOverlay:object = UILens.GetOverlay(overlayName);
	if(pWavesOverlay == nil) then
		print("Error: missing waves overlay. Name=" .. tostring(overlayName));
		return;
	end
	pWavesOverlay:ResetAllWaves();
	
	local localPlayerID :number = Game.GetLocalPlayer();
	if (localPlayerID == nil or localPlayerID < 0) then
		return;
	end

	local pLocalPlayer :object = Players[localPlayerID];
	local pLocalCulture :object = pLocalPlayer:GetCulture();
	if(not pLocalCulture:IsPolicyActive(policyIndex)) then
		return;
	end

	local waves:table = {};
	local pLocalUnits = pLocalPlayer:GetUnits();
	for i, pUnit in pLocalUnits:Members() do
		-- Only naval ships have unit waves.
		if(GameInfo.Units[pUnit:GetType()].Domain == "DOMAIN_SEA") then
			waves = AddUnitWaves(waves, pUnit, waveColor, findTargetPlotFunc);
		end
	end

	pWavesOverlay:CreateLinearWaves(waves);
end

function AddUnitWaves(waves :table, pUnit :object, waveColor :number, findTargetPlotFunc)
	local targetPlotIndex :number = findTargetPlotFunc(pUnit);
	local unitPlotIndex :number = Map.GetPlotIndex(pUnit:GetX(), pUnit:GetY());

	if(targetPlotIndex ~= NO_PLOT) then
		--print("zombie=" .. tostring(pUnit:GetX()) .. "," .. tostring(pUnit:GetY()) .. ", closestUnit=" .. tostring(closestUnit:GetX()) .. "," .. tostring(closestUnit:GetY()) .. " distance=" .. tostring(closestDistance));
		local newWave = {
			pos1  = targetPlotIndex;
			pos2  = unitPlotIndex;
			color = waveColor;
			speed = 1;
			type  = "CIVILIZATION_UNKNOWN";
		};
		table.insert(waves, newWave);
	end

	return waves;
end

function ResetAllUnitWaves()
	ResetUnitWaves(ENGLISH_POINTER_WAVES_OVERLAY_NAME, ms_EnglishPointerPolicy, UI.GetColorValueFromHexLiteral(0xFFFFFFFF), FindClosestUnseenEnemyUnitPlot);
	ResetUnitWaves(DOWSING_ROD_WAVES_OVERLAY_NAME, ms_DowsingRodPolicy, UI.GetColorValueFromHexLiteral(0xFFFFFFFF), FindClosestTreasurePlot);
end

-- Currently hard coded for the English Pointer Relic's range.
function FindClosestUnseenEnemyUnitPlot(pUnit :object)
	local retPlotIndex :number = NO_PLOT;
	local aPlayers = PlayerManager.GetAlive();
	local closestUnit :object = nil;
	local closestDistance :number = RELIC_ENGLISH_POINTER_RANGE;
	local pOwnerVisibility = PlayersVisibility[pUnit:GetOwner()];

	for loop, pPlayer in ipairs(aPlayers) do
		if(pPlayer:GetID() ~= pUnit:GetOwner()) then
			local pPlayerUnits :object = pPlayer:GetUnits();
			for i, pLoopUnit in pPlayerUnits:Members() do
				if(not pOwnerVisibility:IsUnitVisible(pLoopUnit)) then
					local curDistance :number = Map.GetPlotDistance(pUnit:GetX(), pUnit:GetY(), pLoopUnit:GetX(), pLoopUnit:GetY());
					if(curDistance < closestDistance) then
						closestUnit = pLoopUnit;
						closestDistance = curDistance;
					end
				end
			end
		end
	end

	if(closestUnit ~= nil) then
		retPlotIndex = Map.GetPlotIndex(closestUnit:GetX(), closestUnit:GetY());
	end
	return retPlotIndex;
end

-- Currently hard coded for the Dowsing Rod Relic's range.
function FindClosestTreasurePlot(pUnit :object)
	local closestPlotIndex :number = NO_PLOT;
	local scanDistance :number = RELIC_DOWSING_ROD_RANGE;
	local closestDistance :number = scanDistance;
	local unitX :number = pUnit:GetX();
	local unitY :number = pUnit:GetY();
	local ownerID :number = pUnit:GetOwner();
	local unitPlotIndex :number = Map.GetPlotIndex(unitX, unitY);
	for dx = -scanDistance, scanDistance, 1 do
		for dy = -scanDistance, scanDistance, 1 do
			local scanPlot :object = Map.GetPlotXYWithRangeCheck(unitX, unitY, dx, dy, scanDistance);
			if(scanPlot ~= nil 
				and (scanPlot:GetImprovementType() == ms_BuriedTreasureIndex or scanPlot:GetImprovementType() == ms_FloatingTreasureIndex)
				and scanPlot:GetImprovementOwner() ~= ownerID
				and not scanPlot:IsImprovementPillaged()) then
				local curDistance :number = Map.GetPlotDistance(scanPlot:GetIndex(), unitPlotIndex);
				if(closestPlotIndex == NO_PLOT or curDistance < closestDistance) then
					closestPlotIndex = scanPlot:GetIndex();
					closestDistance = curDistance;
				end
			end
		end
	end

	return closestPlotIndex;
end


-- ===========================================================================
--	Event 
-- ===========================================================================
-- ===========================================================================
function OnLocalPlayerChanged()
	m_overlayDataDirty = true;  -- Next step is an refresh in OnGameCoreEventPlaybackComplete
	m_unitWaveDataDirty = true;
end

-- ===========================================================================
function OnLocalPlayerTurnBegin()
	ResetPirateTreasureOverlay();
end

-- ===========================================================================
--	EVENT
--	Gamecore is done processing events; this may fire multiple times as a
--	turn begins, as well as after player actions.
-- ===========================================================================
function OnGameCoreEventPlaybackComplete()	
	if m_overlayDataDirty then
		m_overlayDataDirty = false;
		ContextPtr:RequestRefresh();
	elseif(m_unitWaveDataDirty == true) then
		m_unitWaveDataDirty = false;
		ResetAllUnitWaves();
	end
end

-- ===========================================================================
function OnTurnBegin(turn :number)
	local localPlayer = Game.GetLocalPlayer();
	local pLocalPlayer :object = Players[localPlayer];
	if(pLocalPlayer == nil) then
		print("local player missing!");
		return;
	end

	m_unitWaveDataDirty = true;
end

-- ===========================================================================
function OnRemotePlayerTurnEnd( iPlayerID :number )
	-- Refresh infamous pirate search zones after their turn.
	if(iPlayerID == INFAMOUS_PIRATES_PLAYERID and m_infamousPirateSearchZone == true) then
		m_overlayDataDirty = true;
	end
end

-- ===========================================================================
function OnUnitRemovedFromMap( iPlayerID: number, iUnitID : number )	
	-- Refresh infamous pirate search zones if a barb unit died.  The unit instance is gone at this point so we just have to assume they could have been an infamous pirate.
	if(iPlayerID == INFAMOUS_PIRATES_PLAYERID and m_infamousPirateSearchZone == true) then
		m_overlayDataDirty = true;
	end
end

-- ===========================================================================
function OnImprovementChanged(locationX, locationY, improvementType, improvementOwner, resource, isPillaged, isWorked)
	if (isPillaged) then
		WorldView.PlayEffectAtXY("PIRATE_TREASURE_PILLAGED", locationX, locationY);

		-- Refresh treasure map overlay whenever a treasure is pillaged.
		if (m_treasureSearchZone == true 
			and (improvementType == ms_BuriedTreasureIndex or improvementType == ms_FloatingTreasureIndex)) then
			m_overlayDataDirty = true;
		end
	end
end

-- ===========================================================================
function OnImprovementAddedToMap(locX :number, locY :number, eImprovementType :number, eOwner :number)
	if (eImprovementType == ms_BuriedTreasureIndex) then
		WorldView.PlayEffectAtXY("PIRATE_TREASURE_BURIED", locX, locY);
	end
end

function OnUnitCaptured( currentUnitOwner, unitID, owningPlayer, capturingPlayer )
	
end

function OnUnitKilledInCombat( targetUnit )
	
end

function OnUnitCommandStarted(player, unitId, hCommand, iData1)
    if (hCommand == UnitCommandTypes.PLUNDER_TRADE_ROUTE) then
		local pPlayer	:table = Players[player];		
		for i, unit in pPlayer:GetUnits():Members() do
			if (unit:GetID() == unitId) then
				WorldView.PlayEffectAtXY("PIRATE_PLUNDER_TRADE_ROUTE", unit:GetX(), unit:GetY());
				return;
			end			
		end;		
	end
end

function OnGoodyHutReward( ePlayer:number, unitID:number, eRewardType:number, eRewardSubType:number )	
	local pUnit :object = UnitManager.GetUnit(ePlayer, unitID);
	if (pUnit == nil) then
		print("Error! Unit not found.");
		return;
	end
	local pPlot = Map.GetPlot(pUnit:GetX(), pUnit:GetY());	
	
	if (m_eBarbGoodyHutHash == eRewardType) then		
		WorldView.PlayEffectAtXY("PIRATE_PLUNDER_TRADE_ROUTE", pUnit:GetX(), pUnit:GetY());
	end	
end
-- ===========================================================================
--	UI Event
-- ===========================================================================
function OnRefresh()
	ResetPirateTreasureOverlay();
	ResetAllUnitWaves();
end

-- ===========================================================================
function OnNotificationAdded( playerID:number, notificationID:number )
	-- Pirate Overlay needs to update if there is a new buried treasure map; treasure location; or treasure fleet. 
	if (playerID == Game.GetLocalPlayer())	then -- Was it for us?
		local pNotification = NotificationManager.Find( playerID, notificationID );
		if pNotification ~= nil then
			if pNotification:IsVisibleInUI() 
				and (pNotification:GetType() == NotificationTypes.USER_DEFINED_1
					or pNotification:GetType() == NotificationTypes.USER_DEFINED_2
					or pNotification:GetType() == NotificationTypes.USER_DEFINED_3
					or pNotification:GetType() == NotificationTypes.USER_DEFINED_4)  then
				ResetPirateTreasureOverlay();
			end
		end
	end			
end

-- ===========================================================================
function OnLoadScreenClose()
	ResetOverlays();
end

-- ===========================================================================
function InitializeOverlays()
	-- This is to work around a crash that could happen if this game mode
	-- had been unloaded once, then reloaded again. The internal border
	-- styles might no longer be valid, this will be fixed in a future
	-- patch and this workaround function will no longer be necessary
	
	-- This should match the list of all BorderOverlay layers in Overlay.artdef
	local kBorderOverlays = {}
	
	for _,layer in pairs(kBorderOverlays) do
		local pOverlay = UILens.GetOverlay(layer.name);
		if (pOverlay == nil) then
			print("Error: missing overlay " .. layer.name);
		else
			local nMaterialHash = UILens.CreateLensLayerHash(layer.material);
			pOverlay:InitializeStyles(1, nMaterialHash);
		end
	end

end

-- ===========================================================================
-- OVERRIDE BASE
-- ===========================================================================

function OnShutdown()
	PIRATES_OnShutdown();
	local pEnglishPointerWavesOverlay:object = UILens.GetOverlay(ENGLISH_POINTER_WAVES_OVERLAY_NAME);
	if(pEnglishPointerWavesOverlay == nil) then
		print("Error: missing hunger waves overlay");
		return;
	end
	pEnglishPointerWavesOverlay:ResetAllWaves();

	local pDowsingRodWavesOverlay:object = UILens.GetOverlay(DOWSING_ROD_WAVES_OVERLAY_NAME);
	if(pDowsingRodWavesOverlay == nil) then
		print("Error: missing hunger waves overlay");
		return;
	end
	pDowsingRodWavesOverlay:ResetAllWaves();
end

-- ===========================================================================
function LateInitialize( isReload:boolean )
	PIRATES_LateInitialize( isReload );

	local yieldIconLens : number = UILens.CreateLensLayerHash("Yield_Icons");
	UILens.ToggleLayerOff( yieldIconLens );

	ContextPtr:SetRefreshHandler( OnRefresh );

	Events.GameCoreEventPlaybackComplete.Add(OnGameCoreEventPlaybackComplete);
	Events.ImprovementAddedToMap.Add( OnImprovementAddedToMap );
	Events.ImprovementChanged.Remove( OnImprovementChanged );
	Events.LoadScreenClose.Add(OnLoadScreenClose);
	Events.LocalPlayerChanged.Add( OnLocalPlayerChanged );
	Events.LocalPlayerTurnBegin.Add( OnLocalPlayerTurnBegin );
	Events.ImprovementChanged.Add(		OnImprovementChanged );
	Events.NotificationAdded.Add( OnNotificationAdded );
	Events.TurnBegin.Add( OnTurnBegin );
	Events.RemotePlayerTurnEnd.Remove( OnRemotePlayerTurnEnd );
	Events.UnitRemovedFromMap.Add(OnUnitRemovedFromMap);
	Events.UnitCaptured.Add(OnUnitCaptured);
	Events.UnitKilledInCombat.Add(		OnUnitKilledInCombat );	
	Events.UnitCommandStarted.Add(	OnUnitCommandStarted);
	Events.GoodyHutReward.Add(	OnGoodyHutReward );

	if isReload then
		ResetOverlays();
	end
end
