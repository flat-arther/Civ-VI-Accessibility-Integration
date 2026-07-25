-- Copyright 2019, Firaxis Games

-- ===========================================================================
-- Base File
-- ===========================================================================
include("MinimapPanel");
include("SupportFunctions");
include("CivRoyaleScenario_PropKeys");
include("CivRoyaleScenario_Announcer"); -- Included here so the announcer script can be instantiated.


-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local SAFE_ZONE_RING_PROP				:string = "SafeZoneRing";
local DANGER_ZONE_OVERLAY_NAME			:string = "DeathBorders";
local DANGER_ZONE_OVERLAY_FILL_NAME 	:string = "DeathZoneFill";
local SAFE_ZONE_OVERLAY_NAME			:string = "SafeBorders";
local SAFE_ZONE_OVERLAY_FILL_NAME		:string = "SafeZoneFill";
local SAFE_ZONE_OVERLAY_MAP_FILL_NAME	:string = "SafeZoneFillMinimap";
local SUPPLY_DROP_OVERLAY_NAME			:string = "SupplyDrop";
local SUPPLY_DROP_OVERLAY_FILL_NAME 	:string = "SupplyDropFill";
local GOODY_HUT_OVERLAY_NAME			:string = "GoodyHutBorder";
local BARB_CAMP_OVERLAY_NAME			:string = "BarbCampBorder";
local FAKE_DROP_OVERLAY_NAME			:string = "FakeSupplyDropBorder";
local PREPPER_TRAP_OVERLAY_NAME			:string = "PrepperTrapBorder";
local SAFE_ZONE_OVERLAY_CHANNEL 		:number = 0;
local DANGER_ZONE_OVERLAY_CHANNEL 		:number = 1;
local SUPPLY_DROP_OVERLAY_CHANNEL 		:number = 2;
local GOODY_HUT_OVERLAY_CHANNEL 		:number = 3;
local BARB_CAMP_OVERLAY_CHANNEL 		:number = 4;
local PIRATE_TREASURE_OVERLAY_CHANNEL 	:number = 5;
local FAKE_DROP_OVERLAY_CHANNEL 		:number = 6;
local PREPPER_TRAP_OVERLAY_CHANNEL 		:number = 7;
local MUTANT_ZONE_OVERLAY_CHANNEL 		:number = 8;
local SPRITE_GOODY_HUT              	:string = "GoodyHutOverlay"
local SPRITE_GOODY_HUT_MINIMAP      	:string = "GoodyHutOverlayMiniMap"
local SPRITE_BARB_CAMP              	:string = "BarbCampOverlay"
local SPRITE_BARB_CAMP_MINIMAP      	:string = "BarbCampOverlayMiniMap"
local SPRITE_SUPPLY_DROP            	:string = "SupplyDropOverlay"
local SPRITE_SUPPLY_DROP_MINIMAP    	:string = "SupplyDropOverlayMiniMap"
local SPRITE_PIRATE_TREASURE        	:string = "PirateTreasureOverlay"
local SPRITE_PIRATE_TREASURE_MINIMAP 	:string = "PirateTreasureOverlayMiniMap"
local SPRITE_FAKE_DROP              	:string = "FakeSupplyDropOverlay"
local SPRITE_FAKE_DROP_MINIMAP      	:string = "FakeSupplyDropOverlayMiniMap"
local SPRITE_INCOMING_FAKE_DROP     	:string = "IncomingFakeSupplyDropOverlay"
local SPRITE_INCOMING_FAKE_DROP_MINIMAP :string = "IncomingFakeSupplyDropOverlayMiniMap"
local SPRITE_PREPPER_TRAP           	:string = "PrepperTrapOverlay"
local SPRITE_PREPPER_TRAP_MINIMAP   	:string = "PrepperTrapOverlayMiniMap"
local COLOR_CLEAR						:number = UI.GetColorValueFromHexLiteral(0x00000000);
local COLOR_BLACK						:number = UI.GetColorValueFromHexLiteral(0xFF000000);
local COLOR_WHITE						:number = UI.GetColorValueFromHexLiteral(0xFFFFFFAA);
local COLOR_GREEN						:number = UI.GetColorValueFromHexLiteral(0x2800FF00);
local COLOR_MUTANT_PURPLE				:number = UI.GetColorValueFromHexLiteral(0xFF810284);
local COLOR_SUPPLY						:number = UI.GetColorValueFromHexLiteral(0xFFCC6600);
local COLOR_SUPPLY_FILL					:number = UI.GetColorValueFromHexLiteral(0x22CC6600);
local COLOR_RED							:number = UI.GetColorValueFromHexLiteral(0xFF0000FF);
local COLOR_GOODY						:number = UI.GetColorValueFromHexLiteral(0xFF00FF66);
local COLOR_GOODY_FILL					:number = UI.GetColorValueFromHexLiteral(0x2200FF66);
local COLOR_BARB						:number = UI.GetColorValueFromHexLiteral(0xFF0066FF);
local COLOR_BARB_FILL					:number = UI.GetColorValueFromHexLiteral(0x110066FF);
local COLOR_PIRATE_TREASURE				:number = UI.GetColorValueFromHexLiteral(0xFFFFFFFF);
local COLOR_FAKE_DROP					:number = UI.GetColorValueFromHexLiteral(0xFF00FFFF);
local COLOR_PREPPER_TRAP				:number = UI.GetColorValueFromHexLiteral(0xFF0b5bd1);
local COLOR_PREPPER_TRAP_2				:number = UI.GetColorValueFromHexLiteral(0xFF000000);
local m_eSupplyDropImprovement 			:number = GameInfo.Improvements["IMPROVEMENT_SUPPLY_DROP"].Index;
local m_eGoodyHutImprovement 			:number = GameInfo.Improvements["IMPROVEMENT_GOODY_HUT"].Index;
local m_eBarbarianCampImprovement 		:number = GameInfo.Improvements["IMPROVEMENT_BARBARIAN_CAMP"].Index;
local m_eTrapImprovement				:number = GameInfo.Improvements["IMPROVEMENT_IMPROVISED_TRAP"].Index;
local m_eTrapGoodyHutHash				:number = DB.MakeHash("IMPROVISED_TRAP_GOODIES");
local m_eGiftImprovement				:number = GameInfo.Improvements["IMPROVEMENT_GRIEVING_GIFT"].Index;
local m_eGiftGoodyHutHash				:number = DB.MakeHash("GRIEVING_GIFT_GOODIES");
local m_eZombieUnitIndex				:number = GameInfo.Units[ZOMBIES_ZOMBIE_COMBAT_UNIT].Index;
local m_SupplyDropsHash					:number = UILens.CreateLensLayerHash("SupplyDrops");
local m_Districts						:number = UILens.CreateLensLayerHash("Districts");
local m_Selection						:number = UILens.CreateLensLayerHash("Selection");
local NO_SAFE_ZONE_DISTANCE				:number = -1;

-- Zombie Hunger Waves
local ZOMBIE_HUNGER_WAVES_OVERLAY_NAME	:string = "ZombieSense";


-- ===========================================================================
--	VARIABLES
-- ===========================================================================
local m_overlayDataDirty				:boolean = false; -- Has the data we are overlaying been changed and needs to be refreshed?
local m_giftDataDirty					:boolean = false; -- Has our grieving gift overlay data possibly changed and needs to be refreshed?
local m_safeZoneDataDirty				:boolean = false; -- Has our safe zone overlay data possibly changed and needs to be refreshed?
local m_lastSafeZoneDistance			:number = NO_SAFE_ZONE_DISTANCE; -- The safe zone distance last displayed.

-- ===========================================================================
-- Cached Base Functions
-- NOTE:	Expansions name the cached function based on where they are
--			expected to be defined.  Since this is a MOD and its not clear
--			what function this may be saving off, it prefixes functions with
--			a MOD specific "CIVROYALE_" rather than "BASE_" or "XP2_", etc...
-- ===========================================================================
CIVROYALE_LateInitialize	 = LateInitialize;
CIVROYALE_OnShutdown = OnShutdown;


-- ===========================================================================
-- Members
-- ===========================================================================
function ResetOverlays()
	local pOverlay:object = UILens.GetOverlay(SAFE_ZONE_OVERLAY_NAME);
	local pSafeOverlayFill:object = UILens.GetOverlay(SAFE_ZONE_OVERLAY_FILL_NAME);
	local pSafeOverlayFillMinimap:object = UILens.GetOverlay(SAFE_ZONE_OVERLAY_MAP_FILL_NAME);
	if(pOverlay == nil or pSafeOverlayFill == nil or pSafeOverlayFillMinimap == nil) then
		print("Error: missing SafeZone overlay");
		return;
	end

	m_lastSafeZoneDistance = NO_SAFE_ZONE_DISTANCE;
	
	pOverlay:ClearAll();
	pOverlay:SetVisible(true);
	pOverlay:ShowBorders(true);	
	pOverlay:SetBorderColors(SAFE_ZONE_OVERLAY_CHANNEL, COLOR_WHITE, COLOR_WHITE);
	
	pSafeOverlayFill:ClearAll();
	pSafeOverlayFill:SetVisible(true);
	pSafeOverlayFill:ShowBorders(false);
	pSafeOverlayFill:ShowHighlights(true);
	pSafeOverlayFill:SetHighlightColor(SAFE_ZONE_OVERLAY_CHANNEL, COLOR_WHITE);
	
	pSafeOverlayFillMinimap:ClearAll();
	pSafeOverlayFillMinimap:SetVisible(true);
	pSafeOverlayFillMinimap:ShowBorders(false);
	pSafeOverlayFillMinimap:ShowHighlights(true);
	pSafeOverlayFillMinimap:SetHighlightColor(SAFE_ZONE_OVERLAY_CHANNEL, COLOR_WHITE);
		
	local pDangerOverlay:object = UILens.GetOverlay(DANGER_ZONE_OVERLAY_NAME);
	local pDangerOverlayFill:object = UILens.GetOverlay(DANGER_ZONE_OVERLAY_FILL_NAME);
	if(pDangerOverlay == nil or pDangerOverlayFill == nil) then
		print("Error: missing DangerZone overlay");
		return;
	end
	
	pDangerOverlay:ClearAll();
	pDangerOverlay:SetVisible(true);
	pDangerOverlay:ShowHighlights(false);
	pDangerOverlay:ShowBorders(true);
	pDangerOverlay:SetBorderColors(DANGER_ZONE_OVERLAY_CHANNEL, COLOR_RED, COLOR_RED);	
	pDangerOverlay:SetBorderColors(MUTANT_ZONE_OVERLAY_CHANNEL, COLOR_MUTANT_PURPLE, COLOR_MUTANT_PURPLE);	
	
	pDangerOverlayFill:ClearAll();
	pDangerOverlayFill:SetVisible(true);
	pDangerOverlayFill:ShowBorders(false);
	pDangerOverlayFill:ShowHighlights(true);
	pDangerOverlayFill:SetHighlightColor(DANGER_ZONE_OVERLAY_CHANNEL, COLOR_RED);
	pDangerOverlayFill:SetHighlightColor(MUTANT_ZONE_OVERLAY_CHANNEL, COLOR_MUTANT_PURPLE);
	
	local pSupplyDropOverlay:object = UILens.GetOverlay(SUPPLY_DROP_OVERLAY_NAME);
	local pSupplyDropFillOverlay:object = UILens.GetOverlay(SUPPLY_DROP_OVERLAY_FILL_NAME);
	if(pSupplyDropOverlay == nil or pSupplyDropFillOverlay == nil) then
		print("Error: missing SupplyDrop overlay");
		return;
	end	
	
	pSupplyDropOverlay:ClearAll();
	pSupplyDropOverlay:SetVisible(true);
	pSupplyDropOverlay:ShowHighlights(false);
	pSupplyDropOverlay:ShowBorders(true);
	pSupplyDropOverlay:SetBorderColors(SUPPLY_DROP_OVERLAY_CHANNEL, COLOR_SUPPLY, COLOR_SUPPLY);	
	
	pSupplyDropFillOverlay:ClearAll();
	pSupplyDropFillOverlay:SetVisible(true);
	pSupplyDropFillOverlay:ShowBorders(false);
	pSupplyDropFillOverlay:ShowHighlights(true);
	pSupplyDropFillOverlay:SetHighlightColor(SUPPLY_DROP_OVERLAY_CHANNEL, COLOR_SUPPLY_FILL);

	local pBarbCampOverlay:object = UILens.GetOverlay(BARB_CAMP_OVERLAY_NAME);	
	if(pBarbCampOverlay == nil ) then
		print("Error: missing Barbarian Camp overlay");
		return;
	end	
	
	pBarbCampOverlay:ClearAll();
	pBarbCampOverlay:SetVisible(true);
	pBarbCampOverlay:ShowHighlights(true);
	pBarbCampOverlay:ShowBorders(true);
	pBarbCampOverlay:SetBorderColors(BARB_CAMP_OVERLAY_CHANNEL, COLOR_BARB, COLOR_BARB);	
	pBarbCampOverlay:SetHighlightColor(BARB_CAMP_OVERLAY_CHANNEL, COLOR_BARB_FILL);
	
	
	local pGoodyHutOverlay:object = UILens.GetOverlay(GOODY_HUT_OVERLAY_NAME);	
	if(pGoodyHutOverlay == nil ) then
		print("Error: missing Goody Hut overlay");
		return;
	end	
	
	pGoodyHutOverlay:ClearAll();
	pGoodyHutOverlay:SetVisible(true);
	pGoodyHutOverlay:ShowHighlights(true);
	pGoodyHutOverlay:ShowBorders(true);
	pGoodyHutOverlay:SetBorderColors(GOODY_HUT_OVERLAY_CHANNEL, COLOR_GOODY, COLOR_GOODY);	
	pGoodyHutOverlay:SetHighlightColor(GOODY_HUT_OVERLAY_CHANNEL, COLOR_GOODY_FILL);	
	
	local pTrapBorderOverlay = UILens.GetOverlay(PREPPER_TRAP_OVERLAY_NAME);
	if(pTrapBorderOverlay ~= nil) then
		pTrapBorderOverlay:ClearAll();
		pTrapBorderOverlay:SetVisible(true);
		pTrapBorderOverlay:ShowBorders(true);	
		pTrapBorderOverlay:SetBorderColors(PREPPER_TRAP_OVERLAY_CHANNEL, COLOR_PREPPER_TRAP_2, COLOR_PREPPER_TRAP);	
	end
	
	local pGiftBorderOverlay = UILens.GetOverlay(FAKE_DROP_OVERLAY_NAME);
	if(pGiftBorderOverlay ~= nil) then
		pGiftBorderOverlay:ClearAll();
		pGiftBorderOverlay:SetVisible(true);
		pGiftBorderOverlay:ShowBorders(true);	
		pGiftBorderOverlay:SetBorderColors(FAKE_DROP_OVERLAY_CHANNEL, COLOR_FAKE_DROP, COLOR_BLACK);	
	end
	
	ResetSafeZoneOverlay();
	ResetDangerZoneOverlay();
	ResetSupplyDropOverlay();
	ResetGoodyHutOverlay();
	ResetBarbarianCampOverlay();
	ResetPirateTreasureOverlay();
	ResetImprovisedTrapsOverlay();
	ResetGiftsOverlay();
	ResetZombieHungerWaves();
end

function ClearScenarioOverlays()
	local pOverlay:object = UILens.GetOverlay(SAFE_ZONE_OVERLAY_NAME);
	local pOverlayFill:object = UILens.GetOverlay(SAFE_ZONE_OVERLAY_FILL_NAME);
	local pOverlayFillMinimap:object = UILens.GetOverlay(SAFE_ZONE_OVERLAY_FILL_NAME);
	if(pOverlay == nil or pOverlayFill == nil or pOverlayFillMinimap == nil) then
		print("Error: missing SafeZone overlay");
		return;
	end

	pOverlay:ClearPlotsByChannel(SAFE_ZONE_OVERLAY_CHANNEL);
	pOverlayFill:ClearPlotsByChannel(SAFE_ZONE_OVERLAY_CHANNEL);
	pOverlayFillMinimap:ClearPlotsByChannel(SAFE_ZONE_OVERLAY_CHANNEL);
	
	local pOverlay:object = UILens.GetOverlay(DANGER_ZONE_OVERLAY_NAME);
	local pOverlayFill:object = UILens.GetOverlay(DANGER_ZONE_OVERLAY_FILL_NAME);
	if(pOverlay == nil or pOverlayFill == nil) then
		print("Error: missing DangerZone overlay");
		return;
	end

	pOverlay:ClearPlotsByChannel(DANGER_ZONE_OVERLAY_CHANNEL);
	pOverlayFill:ClearPlotsByChannel(DANGER_ZONE_OVERLAY_CHANNEL);
	
	pOverlay:ClearPlotsByChannel(MUTANT_ZONE_OVERLAY_CHANNEL);
	pOverlayFill:ClearPlotsByChannel(MUTANT_ZONE_OVERLAY_CHANNEL);
	
	local pOverlay:object = UILens.GetOverlay(SUPPLY_DROP_OVERLAY_NAME);
	local pOverlayFill:object = UILens.GetOverlay(SUPPLY_DROP_OVERLAY_FILL_NAME);
	if(pOverlay == nil or pOverlayFill == nil) then
		print("Error: missing SupplyDrop overlay");
		return;
	end

	pOverlay:ClearPlotsByChannel(SUPPLY_DROP_OVERLAY_CHANNEL);
	pOverlayFill:ClearPlotsByChannel(SUPPLY_DROP_OVERLAY_CHANNEL);
	
	local pOverlay:object = UILens.GetOverlay(GOODY_HUT_OVERLAY_NAME);	
	if(pOverlay == nil ) then
		print("Error: missing Goody Hut overlay");
		return;
	end

	pOverlay:ClearPlotsByChannel(GOODY_HUT_OVERLAY_CHANNEL);
	
	local pOverlay:object = UILens.GetOverlay(BARB_CAMP_OVERLAY_NAME);	
	if(pOverlay == nil ) then
		print("Error: missing Barbarian Camp overlay");
		return;
	end

	pOverlay:ClearPlotsByChannel(BARB_CAMP_OVERLAY_CHANNEL);

	-- Prepper Trap Border
	local pTrapBorderOverlay:object = UILens.GetOverlay(PREPPER_TRAP_OVERLAY_NAME);
	if(pTrapBorderOverlay ~= nil) then
		pOverlay:ClearPlotsByChannel(PREPPER_TRAP_OVERLAY_CHANNEL);
	end

	-- Grieving Gift Border
	local pGiftBorderOverlay :object = UILens.GetOverlay(FAKE_DROP_OVERLAY_NAME);
	if(pGiftBorderOverlay ~= nil) then
		pOverlay:ClearPlotsByChannel(FAKE_DROP_OVERLAY_CHANNEL);
	end
		
	local pOverlay:object = UILens.GetOverlay(SPRITE_BARB_CAMP);
	if pOverlay ~= nil then
		pOverlay:ClearAll()	
	end
		
	local pOverlay:object = UILens.GetOverlay(SPRITE_SUPPLY_DROP);
	if pOverlay ~= nil then
		pOverlay:ClearAll()
	end
		
	local pOverlay:object = UILens.GetOverlay(SPRITE_GOODY_HUT);
	if pOverlay ~= nil then
		pOverlay:ClearAll()
	end

	local pTreasureSpriteOverlay:object = UILens.GetOverlay(SPRITE_PIRATE_TREASURE);
	if pTreasureSpriteOverlay ~= nil then
		pTreasureSpriteOverlay:ClearAll()
	end

	
	local pTrapSpriteOverlay:object = UILens.GetOverlay(SPRITE_PREPPER_TRAP);
	if pTrapSpriteOverlay ~= nil then
		pTrapSpriteOverlay:ClearAll()
	end

	-- Grieving Gift Spirites
	local pGiftSpriteOverlay:object = UILens.GetOverlay(SPRITE_FAKE_DROP);
	if pGiftSpriteOverlay ~= nil then
		pGiftSpriteOverlay:ClearAll()
	end
	local pGiftSpriteMiniMapOverlay:object = UILens.GetOverlay(SPRITE_FAKE_DROP_MINIMAP);
	if pGiftSpriteMiniMapOverlay ~= nil then
		pGiftSpriteMiniMapOverlay:ClearAll()
	end
	
	local pGiftSpriteOverlay:object = UILens.GetOverlay(SPRITE_INCOMING_FAKE_DROP);
	if pGiftSpriteOverlay ~= nil then
		pGiftSpriteOverlay:ClearAll()
	end
	local pGiftSpriteMiniMapOverlay:object = UILens.GetOverlay(SPRITE_INCOMING_FAKE_DROP_MINIMAP);
	if pGiftSpriteMiniMapOverlay ~= nil then
		pGiftSpriteMiniMapOverlay:ClearAll()
	end
end


function ResetSafeZoneOverlay()
	local safeZoneDistance	:number = Game:GetProperty(g_ObjectStateKeys.CurrentSafeZoneDistance);
	local safeZoneX			:number = Game:GetProperty(g_ObjectStateKeys.SafeZoneX);
	local safeZoneY			:number = Game:GetProperty(g_ObjectStateKeys.SafeZoneY);
	if(safeZoneX == nil or safeZoneY == nil or safeZoneDistance == nil) then
		print("Error: missing SafeZone game data")
		return;
	end 

	-- Already showing the safe zone for this safe zone distance?
	if(m_lastSafeZoneDistance == safeZoneDistance) then
		return;
	end
	m_lastSafeZoneDistance = safeZoneDistance;

	local pOverlay:object = UILens.GetOverlay(SAFE_ZONE_OVERLAY_NAME);
	local pOverlayFill:object = UILens.GetOverlay(SAFE_ZONE_OVERLAY_FILL_NAME);
	local pSafeOverlayFillMinimap:object = UILens.GetOverlay(SAFE_ZONE_OVERLAY_MAP_FILL_NAME);
	if(pOverlay == nil or pOverlayFill == nil or pSafeOverlayFillMinimap == nil) then
		print("Error: missing SafeZone overlay");
		return;
	end

	pOverlay:ClearPlotsByChannel(SAFE_ZONE_OVERLAY_CHANNEL);
	pOverlayFill:ClearPlotsByChannel(SAFE_ZONE_OVERLAY_CHANNEL);
	pSafeOverlayFillMinimap:ClearPlotsByChannel(SAFE_ZONE_OVERLAY_CHANNEL);

	-- Add safe zone hexes to overlay.
	local safeZonePlots = {};
	for dx = -safeZoneDistance, safeZoneDistance, 1 do
		for dy = -safeZoneDistance, safeZoneDistance, 1 do
			local curPlot :object = Map.GetPlotXYWithRangeCheck(safeZoneX, safeZoneY, dx, dy, safeZoneDistance);
			if(curPlot ~= nil) then
				table.insert(safeZonePlots, curPlot:GetIndex());
			end
		end
	end

	pOverlay:SetPlotChannel(safeZonePlots, SAFE_ZONE_OVERLAY_CHANNEL);
	pOverlayFill:SetPlotChannel(safeZonePlots, SAFE_ZONE_OVERLAY_CHANNEL);
	pSafeOverlayFillMinimap:SetPlotChannel(safeZonePlots, SAFE_ZONE_OVERLAY_CHANNEL);
end

function ResetDangerZoneOverlay()
	local pOverlay:object = UILens.GetOverlay(DANGER_ZONE_OVERLAY_NAME);
	local pOverlayFill:object = UILens.GetOverlay(DANGER_ZONE_OVERLAY_FILL_NAME);
	if(pOverlay == nil or pOverlayFill == nil) then
		print("Error: missing DangerZone overlay");
		return;
	end

	pOverlay:ClearPlotsByChannel(DANGER_ZONE_OVERLAY_CHANNEL);
	pOverlayFill:ClearPlotsByChannel(DANGER_ZONE_OVERLAY_CHANNEL);
	
	pOverlay:ClearPlotsByChannel(MUTANT_ZONE_OVERLAY_CHANNEL);
	pOverlayFill:ClearPlotsByChannel(MUTANT_ZONE_OVERLAY_CHANNEL);
	
	-- Mutants can see the Mutant Spread Fallout from other Mutant factions in the overlay.
	local showMutantFallout = ShowMutantFallout();
	local localPlayer = Game.GetLocalPlayer();

	local pPlayerVis;
	if (localPlayer and localPlayer >= 0) then
		pPlayerVis = PlayersVisibility[localPlayer];
	end
	if (pPlayerVis == nil) then
		return;
	end

	local dangerPlots = {};
	local mutantPlots = {};
	local pFalloutManager = Game.GetFalloutManager();
	if(pFalloutManager == nil) then
		print("Error: missing fallout manager overlay");
		return;
	end
	for iPlotIndex = 0, Map.GetPlotCount()-1, 1 do		
		if (pFalloutManager:HasFallout(iPlotIndex)) then
			local curPlot = Map.GetPlotByIndex(iPlotIndex);
			local mutantDroppedProp = curPlot:GetProperty(g_plotStateKeys.MutantDropped);
			if (mutantDroppedProp and (showMutantFallout or pPlayerVis:IsVisible(iPlotIndex))) then
				table.insert(mutantPlots, iPlotIndex);
			end
			if( mutantDroppedProp == nil 
				or mutantDroppedProp < 0) then
				table.insert(dangerPlots, iPlotIndex);
			end
		end
	end
	pOverlay:SetPlotChannel(dangerPlots, DANGER_ZONE_OVERLAY_CHANNEL);
	pOverlayFill:SetPlotChannel(dangerPlots, DANGER_ZONE_OVERLAY_CHANNEL);
	
	pOverlay:SetPlotChannel(mutantPlots, MUTANT_ZONE_OVERLAY_CHANNEL);
	pOverlayFill:SetPlotChannel(mutantPlots, MUTANT_ZONE_OVERLAY_CHANNEL);
end

function ResetSupplyDropOverlay()
	local pOverlay:object = UILens.GetOverlay(SUPPLY_DROP_OVERLAY_NAME);
	local pOverlayFill:object = UILens.GetOverlay(SUPPLY_DROP_OVERLAY_FILL_NAME);
	if(pOverlay == nil or pOverlayFill == nil) then
		print("Error: missing SupplyDrop overlay");
		return;
	end

	pOverlay:ClearPlotsByChannel(SUPPLY_DROP_OVERLAY_CHANNEL);
	pOverlayFill:ClearPlotsByChannel(SUPPLY_DROP_OVERLAY_CHANNEL);
	
	local localPlayer = Game.GetLocalPlayer();
	local pPlayerVis;
	if (localPlayer and localPlayer >= 0) then
		pPlayerVis = PlayersVisibility[localPlayer];
	end
	if (pPlayerVis == nil) then
		return;
	end

	local supplyDropPlots = {};
	local supplyDropSpritePlots = {};
	local mapCount:number = Map.GetPlotCount() - 1;
	for plotIndex = 0, mapCount, 1 do
		local pPlot:object = Map.GetPlotByIndex(plotIndex);		
		if (pPlot:GetImprovementType() == m_eSupplyDropImprovement
			-- Grieving Gifts look like normal supply drops to non-owners
			or (pPlot:GetImprovementType() == m_eGiftImprovement and pPlot:GetImprovementOwner() ~= localPlayer)) then
			table.insert(supplyDropPlots, plotIndex);
			if ( not pPlayerVis:IsVisible(plotIndex)) then
				table.insert(supplyDropSpritePlots, plotIndex);
			end
		end
	end

	pOverlay:SetPlotChannel(supplyDropPlots, SUPPLY_DROP_OVERLAY_CHANNEL);
	pOverlayFill:SetPlotChannel(supplyDropPlots, SUPPLY_DROP_OVERLAY_CHANNEL);
		
	
	-- sprite overlays
	local pOverlay:object = UILens.GetOverlay(SPRITE_SUPPLY_DROP);
	if pOverlay ~= nil then
		pOverlay:ClearAll()	
		pOverlay:CreateSprites( supplyDropSpritePlots, SPRITE_SUPPLY_DROP, 0 );
	end
	
	local pOverlay:object = UILens.GetOverlay(SPRITE_SUPPLY_DROP_MINIMAP);
	if pOverlay ~= nil then
		pOverlay:ClearAll()	
		pOverlay:CreateSprites( supplyDropPlots, SPRITE_SUPPLY_DROP_MINIMAP, 0 );
	end
end

function ResetGoodyHutOverlay()
	local pOverlay:object = UILens.GetOverlay(GOODY_HUT_OVERLAY_NAME);
	
	if(pOverlay == nil ) then
		print("Error: missing Goody Hut overlay");
		return;
	end

	pOverlay:ClearPlotsByChannel(GOODY_HUT_OVERLAY_CHANNEL);
	
	
	local localPlayer = Game.GetLocalPlayer();
	local pPlayerVis;
	if (localPlayer and localPlayer >= 0) then
		pPlayerVis = PlayersVisibility[localPlayer];
	end
	if (pPlayerVis == nil) then
		return;
	end

	local hutDropPlots = {};	
	local hutDropSpritePlots = {};
	local mapCount:number = Map.GetPlotCount() - 1;
	for plotIndex = 0, mapCount, 1 do
		local pPlot:object = Map.GetPlotByIndex(plotIndex);		
		if (pPlot:GetImprovementType() == m_eGoodyHutImprovement) then			
			if ( pPlayerVis:IsVisible(plotIndex) or pPlayerVis:IsRevealed(plotIndex)) then
				table.insert(hutDropPlots, plotIndex);
				if ( not pPlayerVis:IsVisible(plotIndex)) then
					table.insert(hutDropSpritePlots, plotIndex);
				end
			end
		end
	end
	pOverlay:SetPlotChannel(hutDropPlots, GOODY_HUT_OVERLAY_CHANNEL);		
	
	local pOverlay:object = UILens.GetOverlay(SPRITE_GOODY_HUT);
	if pOverlay ~= nil then
		pOverlay:ClearAll()	
		pOverlay:CreateSprites( hutDropSpritePlots, SPRITE_GOODY_HUT, 0 );
	end
	
	local pOverlay:object = UILens.GetOverlay(SPRITE_GOODY_HUT_MINIMAP);
	if pOverlay ~= nil then
		pOverlay:ClearAll()	
		pOverlay:CreateSprites( hutDropPlots, SPRITE_GOODY_HUT_MINIMAP, 0 );
	end
end

function ResetBarbarianCampOverlay()
	local pOverlay:object = UILens.GetOverlay(BARB_CAMP_OVERLAY_NAME);
	
	if(pOverlay == nil ) then
		print("Error: missing Barbarian Camp overlay");
		return;
	end

	pOverlay:ClearPlotsByChannel(BARB_CAMP_OVERLAY_CHANNEL);
	
	
	local localPlayer = Game.GetLocalPlayer();
	local pPlayerVis;
	if (localPlayer and localPlayer >= 0) then
		pPlayerVis = PlayersVisibility[localPlayer];
	end
	if (pPlayerVis == nil) then
		return;
	end

	local campDropPlots = {};	
	local campDropSpritePlots = {};
	local mapCount:number = Map.GetPlotCount() - 1;
	
	for plotIndex = 0, mapCount, 1 do
		local pPlot:object = Map.GetPlotByIndex(plotIndex);		
		if (pPlot:GetImprovementType() == m_eBarbarianCampImprovement) then			
			if ( pPlayerVis:IsVisible(plotIndex) or pPlayerVis:IsRevealed(plotIndex)) then
				table.insert(campDropPlots, plotIndex);
				if ( not pPlayerVis:IsVisible(plotIndex)) then
					table.insert(campDropSpritePlots, plotIndex);
				end
			end
		end
	end
	pOverlay:SetPlotChannel(campDropPlots, BARB_CAMP_OVERLAY_CHANNEL);
		
	local pOverlay:object = UILens.GetOverlay(SPRITE_BARB_CAMP);
	if pOverlay ~= nil then
		pOverlay:ClearAll()	
		pOverlay:CreateSprites( campDropSpritePlots, SPRITE_BARB_CAMP, 0 );
	end	
		
	local pOverlay:object = UILens.GetOverlay(SPRITE_BARB_CAMP_MINIMAP);
	if pOverlay ~= nil then
		pOverlay:ClearAll()	
		pOverlay:CreateSprites( campDropPlots, SPRITE_BARB_CAMP_MINIMAP, 0 );
	end
end

function ResetPirateTreasureOverlay()
	
	local localPlayer = Game.GetLocalPlayer();
	local pPlayerVis :object = nil;
	local pPlayer :object = nil;
	if (localPlayer and localPlayer >= 0) then
		pPlayer = Players[localPlayer];
		pPlayerVis = PlayersVisibility[localPlayer];
	end
	if (pPlayerVis == nil or pPlayer == nil) then
		return;
	end

	local supplyDropPlots = {};
	local supplyDropSpritePlots = {};
	local treasurePlotIndex :number = pPlayer:GetProperty(g_playerPropertyKeys.TreasurePlotIndex);
	if(treasurePlotIndex ~= nil) then
		table.insert(supplyDropPlots, treasurePlotIndex);
		table.insert(supplyDropSpritePlots, treasurePlotIndex);
	end
	
	-- sprite overlays
	local pOverlay:object = UILens.GetOverlay(SPRITE_PIRATE_TREASURE);
	if pOverlay ~= nil then
		pOverlay:ClearAll()	
		pOverlay:CreateSprites( supplyDropSpritePlots, SPRITE_PIRATE_TREASURE, 0 );
	end
	
	local pOverlay:object = UILens.GetOverlay(SPRITE_PIRATE_TREASURE_MINIMAP);
	if pOverlay ~= nil then
		pOverlay:ClearAll()	
		pOverlay:CreateSprites( supplyDropPlots, SPRITE_PIRATE_TREASURE_MINIMAP, 0 );
	end
end

function ResetImprovisedTrapsOverlay()
	local pBorderOverlay:object = UILens.GetOverlay(PREPPER_TRAP_OVERLAY_NAME);
	if(pBorderOverlay ~= nil ) then
		pBorderOverlay:ClearPlotsByChannel(PREPPER_TRAP_OVERLAY_CHANNEL);
	end

	local pSpriteOverlay:object = UILens.GetOverlay(SPRITE_PREPPER_TRAP);
	if pSpriteOverlay ~= nil then
		pSpriteOverlay:ClearAll();
	end

	local pSpriteMinimapOverlay:object = UILens.GetOverlay(SPRITE_PREPPER_TRAP_MINIMAP);
	if pSpriteMinimapOverlay ~= nil then
		pSpriteMinimapOverlay:ClearAll();
	end

	local localPlayer = Game.GetLocalPlayer();

	-- Only preppers can see Improvised Traps.
	local localPlayerConfig = PlayerConfigurations[localPlayer];
	if(localPlayerConfig == nil or localPlayerConfig:GetCivilizationTypeName() ~= g_CivTypeNames.Preppers) then
		return;
	end

	local trapPlots = {};
	local mapCount:number = Map.GetPlotCount() - 1;
	for plotIndex = 0, mapCount, 1 do
		local pPlot:object = Map.GetPlotByIndex(plotIndex);
		if(pPlot ~= nil and pPlot:GetImprovementType() == m_eTrapImprovement) then
			table.insert(trapPlots, plotIndex);
		end
	end

	if(pBorderOverlay ~= nil ) then
		pBorderOverlay:SetPlotChannel(trapPlots, PREPPER_TRAP_OVERLAY_CHANNEL);	
	end

	if pSpriteOverlay ~= nil then
		pSpriteOverlay:CreateSprites( trapPlots, SPRITE_PREPPER_TRAP, 0 );
	end

	if pSpriteMinimapOverlay ~= nil then
		pSpriteMinimapOverlay:CreateSprites( trapPlots, SPRITE_PREPPER_TRAP_MINIMAP, 0 );
	end
end

function ResetGiftsOverlay()
	local pBorderOverlay:object = UILens.GetOverlay(FAKE_DROP_OVERLAY_NAME);
	if(pBorderOverlay == nil) then
		print("Error: missing Gifts Border overlay");
		return;
	end

	pBorderOverlay:ClearPlotsByChannel(FAKE_DROP_OVERLAY_CHANNEL);
	
	local localPlayer = Game.GetLocalPlayer();
	local pPlayerVis;
	if (localPlayer and localPlayer >= 0) then
		pPlayerVis = PlayersVisibility[localPlayer];
	end
	if (pPlayerVis == nil) then
		return;
	end

	local giftPlots = {};	
	local incomingGiftSpiritesPlots = {};
	local mapCount:number = Map.GetPlotCount() - 1;
	for plotIndex = 0, mapCount, 1 do
		local pPlot:object = Map.GetPlotByIndex(plotIndex);
		local giftOwnerProp = pPlot:GetProperty(g_plotStateKeys.DeferredGiftOwner);		
		-- Placed gift
		if (pPlot:GetImprovementType() == m_eGiftImprovement and pPlot:GetImprovementOwner() == localPlayer) then			
			table.insert(giftPlots, plotIndex);				
		end
		-- Deferred gift
		if (giftOwnerProp ~= nil and giftOwnerProp == localPlayer) then		
			table.insert(incomingGiftSpiritesPlots, plotIndex);
		end	
	end

	pBorderOverlay:SetPlotChannel(giftPlots, FAKE_DROP_OVERLAY_CHANNEL);
	
	-- sprite overlays
	local pOverlay:object = UILens.GetOverlay(SPRITE_FAKE_DROP);
	if pOverlay ~= nil then
		pOverlay:ClearAll()	
		pOverlay:CreateSprites( giftPlots, SPRITE_FAKE_DROP, 0 );
	end
	
	local pOverlay:object = UILens.GetOverlay(SPRITE_FAKE_DROP_MINIMAP);
	if pOverlay ~= nil then
		pOverlay:ClearAll()	
		pOverlay:CreateSprites( giftPlots, SPRITE_FAKE_DROP_MINIMAP, 0 );
	end
	
	local pOverlay:object = UILens.GetOverlay(SPRITE_INCOMING_FAKE_DROP);
	if pOverlay ~= nil then
		pOverlay:ClearAll()	
		pOverlay:CreateSprites( incomingGiftSpiritesPlots, SPRITE_INCOMING_FAKE_DROP, 0 );
	end
	
	local pOverlay:object = UILens.GetOverlay(SPRITE_INCOMING_FAKE_DROP_MINIMAP);
	if pOverlay ~= nil then
		pOverlay:ClearAll()	
		pOverlay:CreateSprites( incomingGiftSpiritesPlots, SPRITE_INCOMING_FAKE_DROP_MINIMAP, 0 );
	end
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

-- Can the local player see Mutant Spread Fallout?
function ShowMutantFallout()
	local localPlayer = Game.GetLocalPlayer();
	if (localPlayer and localPlayer >= 0) then
		local localPlayerConfig = PlayerConfigurations[localPlayer];
		if(localPlayerConfig ~= nil and localPlayerConfig:GetCivilizationTypeName() == g_CivTypeNames.Mutants) then
			return true;
		end
	end

	return false;
end

function ResetZombieHungerWaves()
	local pWavesOverlay:object = UILens.GetOverlay(ZOMBIE_HUNGER_WAVES_OVERLAY_NAME);
	if(pWavesOverlay == nil) then
		print("Error: missing hunger waves overlay");
		return;
	end
	pWavesOverlay:ResetAllWaves();
	
	local localPlayer = Game.GetLocalPlayer();
	if (localPlayer == nil or localPlayer < 0) then
		return;
	end
	local localPlayerConfig = PlayerConfigurations[localPlayer];
	if(localPlayerConfig == nil or localPlayerConfig:GetCivilizationTypeName() ~= g_CivTypeNames.Zombies) then
		return;
	end

	local waves:table = {};
	local pLocalPlayer = Players[localPlayer];
	local pLocalUnits = pLocalPlayer:GetUnits();
	for i, pUnit in pLocalUnits:Members() do
		waves = AddZombieHungerWaves(waves, pUnit);
	end

	pWavesOverlay:CreateLinearWaves(waves);
end

function AddZombieHungerWaves(waves :table, pZombieUnit :object)
	local aPlayers = PlayerManager.GetAlive();
	local closestUnit :object = nil;
	local closestDistance :number = 8;
	local pZombieVisibility = PlayersVisibility[pZombieUnit:GetOwner()];
	local zombiePlotIndex = Map.GetPlotIndex(pZombieUnit:GetX(), pZombieUnit:GetY());

	for loop, pPlayer in ipairs(aPlayers) do
		if(pPlayer:GetID() ~= pZombieUnit:GetOwner()) then
			local pPlayerUnits :object = pPlayer:GetUnits();
			for i, pUnit in pPlayerUnits:Members() do
				if(not pZombieVisibility:IsUnitVisible(pUnit)) then
					local curDistance :number = Map.GetPlotDistance(pZombieUnit:GetX(), pZombieUnit:GetY(), pUnit:GetX(), pUnit:GetY());
					if(curDistance < closestDistance) then
						closestUnit = pUnit;
						closestDistance = curDistance;
					end
				end
			end
		end
	end

	if(closestUnit ~= nil) then
		--print("zombie=" .. tostring(pZombieUnit:GetX()) .. "," .. tostring(pZombieUnit:GetY()) .. ", closestUnit=" .. tostring(closestUnit:GetX()) .. "," .. tostring(closestUnit:GetY()) .. " distance=" .. tostring(closestDistance));
		local closestPlotIndex = Map.GetPlotIndex(closestUnit:GetX(), closestUnit:GetY());
		local newWave = {
			pos1  = closestPlotIndex;
			pos2  = zombiePlotIndex;
			color = UI.GetColorValueFromHexLiteral(0xFF037000);
			speed = 4;
			type  = "CIVILIZATION_UNKNOWN";
		};
		table.insert(waves, newWave);
	end

	return waves;
end


-- ===========================================================================
--	Scenario Minimap Tooltips
-- ===========================================================================
function ShowMinimapTooltips(inputX:number, inputY:number)
	local ePlayer : number = Game.GetLocalPlayer(); 
	local pPlayerVis:table = PlayersVisibility[ePlayer];

	local minix, miniy = GetMinimapMouseCoords( inputX, inputY );
	if (pPlayerVis ~= nil and IsMouseInMinimap(minix, miniy)) then
		local wx, wy = TranslateMinimapToWorld(minix, miniy);
		local plotX, plotY = UI.GetPlotCoordFromWorld(wx, wy);
		local pPlot = Map.GetPlot(plotX, plotY);
		if (pPlot ~= nil) then
			local plotID = Map.GetPlotIndex(plotX, plotY);
			local pFalloutManager = Game.GetFalloutManager();			
			local safeZoneFlag:number = pPlot:GetProperty(SAFE_ZONE_RING_PROP);			
			
			if(pFalloutManager == nil) then
				print("Error: missing fallout manager");
				return;
			end
			
			if pPlayerVis:IsRevealed(plotID) then
				local pTooltipString = Locale.Lookup("LOC_CIVROYALE_TERRAIN_WASTELAND_NAME");
				Controls.MinimapImage:SetToolTipString(pTooltipString);	
			else
				local pTooltipString = Locale.Lookup("LOC_MINIMAP_FOG_OF_WAR_TOOLTIP");
				Controls.MinimapImage:SetToolTipString(pTooltipString);
			end
			
			if (pFalloutManager:HasFallout(plotID)) then
				local pTooltipString = Locale.Lookup("LOC_MINIMAP_RED_DEATH_TOOLTIP");
				Controls.MinimapImage:SetToolTipString(pTooltipString);				
			elseif safeZoneFlag ~= nil and safeZoneFlag > 0 then
				local pTooltipString = Locale.Lookup("LOC_MINIMAP_SAFE_ZONE_TOOLTIP");
				Controls.MinimapImage:SetToolTipString(pTooltipString);					
			end
				
			if pPlayerVis:IsRevealed(plotID) then
				if (pPlot:GetImprovementType() == m_eGoodyHutImprovement) then	
					local pTooltipString = Locale.Lookup("LOC_CIV_ROYALE_IMPROVEMENT_GOODY_HUT_NAME");
					Controls.MinimapImage:SetToolTipString(pTooltipString);
				elseif (pPlot:GetImprovementType() == m_eBarbarianCampImprovement) then	
					local pTooltipString = Locale.Lookup("LOC_IMPROVEMENT_BARBARIAN_CAMP_NAME");
					Controls.MinimapImage:SetToolTipString(pTooltipString);				
				elseif (pPlot:GetImprovementType() == m_eSupplyDropImprovement) then
					local pTooltipString = Locale.Lookup("LOC_IMPROVEMENT_SUPPLY_DROP_NAME");
					Controls.MinimapImage:SetToolTipString(pTooltipString);				
				end	
			end
		end
	end
end

-- ===========================================================================
--	Event 
-- ===========================================================================
function OnTurnBegin(turn :number)
	-- Read custom data from Game side.
	local NextSafeZoneTurn = ReadCustomData("NextSafeZoneTurn");
	local LastSafeZoneTurn = ReadCustomData("LastSafeZoneTurn");
	local DangerRingTurn = ReadCustomData("DangerRingTurn");

	local safeZoneDistance = Game:GetProperty("CurrentSafeZoneDistance");
	local nextZoneDistance = Game:GetProperty("NextSafeZoneDistance");
	
	print("Custom Data: ",nextZoneDistance,safeZoneDistance,NextSafeZoneTurn,LastSafeZoneTurn,DangerRingTurn);
	ResetDangerZoneOverlay();
	ResetZombieHungerWaves();
end

function OnPhaseBegin()
	-- Wait until all gamecore events are played back prior to updating the safe zone overlay.
	-- The safe zone data is updated as part of the OnGameTurnStarted gamecore signal that is dispatched after the TurnBegin gamecore event.
	-- It is better to be sure the cache was properly updated before refreshing the safe zone.
	m_safeZoneDataDirty = true;
end

function OnTeamVictory(team, victoryType)
	-- Probably need to do some more checks here for hotseat games
	local localPlayer = Game.GetLocalPlayer();
	
	-- This drives the visual intensity of the fallout particle VFX
	WorldView.SetVFXImport("GodRayDisable", 1);
	
	if (localPlayer and localPlayer >= 0) then		-- Check to see if there is any local player
		local player = Players[localPlayer];
		if(player:IsAlive()) then
			
			
			local playerUnits = player:GetUnits();
			
			-- Find the first settler we can and play the victory cinematic on it
			for i, unit in playerUnits:Members() do
				local unitTypeName = UnitManager.GetTypeName(unit);
				local settlerFound = false;
				if ("UNIT_SETTLER" == unitTypeName) then					
					
					SimUnitSystem.SetVisHexHeading(unit, -2);
					local plot = Map.GetPlot(unit:GetX(), unit:GetY());	
					UI.LookAtPlot(plot:GetX(), plot:GetY(), 0, 0, true);
					
					-- Deactivating overlays
					UILens.SetActive("Cinematic");
					UI.SetInterfaceMode(InterfaceModeTypes.CINEMATIC);
					UILens.HideOverlays("MovementPath");									
					ClearScenarioOverlays();	
					
					-- Make sure to select the settler, otherwise the lander animation will not play
					UI.SelectUnit(unit);	
					
					-- The look-at needs to be instantaneous otherwise the unit animation will not play if it's out of view
					Events.PlayCameraAnimationAtHex("Camera_Land_Anim", unit:GetX(), unit:GetY(), 0.0, true);			
					UI.LookAtPlot(plot:GetX(), plot:GetY(), 0, 0, true); -- Force the look-at one more time just in case
					SimUnitSystem.SetAnimationState(unit, "ACTION_1", "ACTION_1");	
					break
					
				end
			end
		end
	end
end

-- ===========================================================================
function OnPlayerDefeat( player, defeat, eventID)
	-- We might do a little something for a player when they lose?
	-- local localPlayer = Game.GetLocalPlayer();
	-- if (localPlayer and localPlayer >= 0) then		-- Check to see if there is any local player
		-- -- Was it the local player?
		-- if (localPlayer == player) then
			
		-- end
	-- end	
end

-- ===========================================================================
function OnImprovementAddedToMap(locX :number, locY :number, eImprovementType :number, eOwner :number)
	m_overlayDataDirty = true;  -- Next step is an refresh in OnGameCoreEventPlaybackComplete
end

-- ===========================================================================
function OnImprovementRemovedFromMap( locX :number, locY :number, eOwner :number )	
	m_overlayDataDirty = true;  -- Next step is an refresh in OnGameCoreEventPlaybackComplete
end

-- ===========================================================================
function OnImprovementVisibilityChanged( locX :number, locY :number, eImprovementType :number, eVisibility :number )
	m_overlayDataDirty = true;  -- Next step is an refresh in OnGameCoreEventPlaybackComplete
end

-- ===========================================================================
-- Note, there is an OnLocalPlayerChanged in the base minimap panel and it
-- is subscribed to in the minimappanel init, which we still call, so
-- we are using a different name here, else we would just end up double-subscribing
-- to the same function.
function CivRoyale_OnLocalPlayerChanged()	
	ResetOverlays();	-- Handle hotseat players changing.
end

-- ===========================================================================
function OnGoodyHutReward( ePlayer:number, unitID:number, eRewardType:number, eRewardSubType:number )	
	local pUnit :object = UnitManager.GetUnit(ePlayer, unitID);
	if (pUnit == nil) then
		print("Error! Unit not found.");
		return;
	end
	local pPlot = Map.GetPlot(pUnit:GetX(), pUnit:GetY());	
	
	if (m_eTrapGoodyHutHash == eRewardType or m_eGiftGoodyHutHash == eRewardType) then		
		WorldView.PlayEffectAtXY("CR_TrapExplosion", pUnit:GetX(), pUnit:GetY());
	end	
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
	elseif(m_giftDataDirty) then
		m_giftDataDirty = false;
		ResetGiftsOverlay();		
	end

	-- Safe Zone overlay is refreshed separately from a context refresh.
	if(m_safeZoneDataDirty) then
		m_safeZoneDataDirty = false;
		ResetSafeZoneOverlay();
	end
end

-- ===========================================================================
--	UI Event
-- ===========================================================================
function OnRefresh()
	ResetSupplyDropOverlay();
	ResetGoodyHutOverlay();
	ResetBarbarianCampOverlay();
	ResetPirateTreasureOverlay();
	ResetImprovisedTrapsOverlay();
	ResetGiftsOverlay();
end

-- ===========================================================================
function OnWMDFalloutChanged(plotX :number, plotY :number, hasFallout :number)
	local pPlot:object = Map.GetPlot(plotX, plotY);
	if(pPlot == nil) then
		print("No plot object for " .. tostring(plotX) .. "," .. tostring(plotY));
		return;
	end

	-- Non-Mutants can only see mutant spread fallout if the plot is revealed.
	local showMutantFallout = ShowMutantFallout();
	local localPlayer = Game.GetLocalPlayer();
	local pPlayerVis;
	if (localPlayer and localPlayer >= 0) then
		pPlayerVis = PlayersVisibility[localPlayer];
	end
	if (pPlayerVis == nil) then
		return;
	end
	local mutantDroppedProp = pPlot:GetProperty(g_plotStateKeys.MutantDropped);
	if(not showMutantFallout 
		and mutantDroppedProp ~= nil 
		and mutantDroppedProp > 0 
		and not pPlayerVis:IsVisible(pPlot:GetIndex())) then
		return;
	end

	local pOverlay:object = UILens.GetOverlay(DANGER_ZONE_OVERLAY_NAME);
	local pOverlayFill:object = UILens.GetOverlay(DANGER_ZONE_OVERLAY_FILL_NAME);
	if(pOverlay == nil or pOverlayFill == nill) then
		print("Error: missing SafeZone overlay");
		return;
	end

	local dangerPlot = { pPlot:GetIndex() };
	if (mutantDroppedProp) then
		pOverlay:SetPlotChannel(dangerPlot, MUTANT_ZONE_OVERLAY_CHANNEL);
		pOverlayFill:SetPlotChannel(dangerPlot, MUTANT_ZONE_OVERLAY_CHANNEL);
	else
		pOverlay:SetPlotChannel(dangerPlot, DANGER_ZONE_OVERLAY_CHANNEL);
		pOverlayFill:SetPlotChannel(dangerPlot, DANGER_ZONE_OVERLAY_CHANNEL);
	end
end

-- ===========================================================================
function OnNotificationAdded( playerID:number, notificationID:number )
	-- Pirate Overlay needs to update if there is a new treasure location available. 
	if (playerID == Game.GetLocalPlayer())	then -- Was it for us?
		local pNotification = NotificationManager.Find( playerID, notificationID );
		if pNotification ~= nil then
			if pNotification:IsVisibleInUI() and pNotification:GetType() == NotificationTypes.USER_DEFINED_4 then
				ResetPirateTreasureOverlay();
			end
		end
	end			
end

-- ===========================================================================
function OnUnitCommandStarted(player, unitId, hCommand, iData1)
    if (hCommand == UnitCommandTypes.EXECUTE_SCRIPT) then
		m_giftDataDirty = true;
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
	local kBorderOverlays = {
		{ name = "BarbCampBorder", material = "BarbCampBorder"      },
		{ name = "DeathBorders",   material = "DeathBorderMaterial" },
		{ name = "DeathZoneFill",  material = "DeathFill"           },
		{ name = "GoodyHutBorder", material = "GoodyHutBorder"      },
		{ name = "SafeBorders",    material = "SafeBorderMaterial"  },
		{ name = "SafeZoneFill",   material = "SafeZoneFill"        },
		{ name = "SupplyDrop",     material = "SupplyDropMaterial"  },
		{ name = "SupplyDropFill", material = "SupplyDropFill"      },
	}
	
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
function ToggleMapOptionsList()	
    if Controls.MapOptionsPanel:IsHidden() then
        RefreshMinimapOptions();
    end
	Controls.MapOptionsPanel:SetHide( not Controls.MapOptionsPanel:IsHidden() );
	RealizeFlyouts(Controls.MapOptionsPanel);
	Controls.MapOptionsButton:SetSelected( not Controls.MapOptionsPanel:IsHidden() );
end

function OnShutDown()
	CIVROYALE_OnShutdown();
	local pWavesOverlay:object = UILens.GetOverlay(ZOMBIE_HUNGER_WAVES_OVERLAY_NAME);
	if(pWavesOverlay == nil) then
		print("Error: missing hunger waves overlay");
		return;
	end
	pWavesOverlay:ResetAllWaves();
end

-- ===========================================================================
function LateInitialize( isReload:boolean )
	CIVROYALE_LateInitialize( isReload );

	-- Force off any lenses that may 
	local yieldIconLens : number = UILens.CreateLensLayerHash("Yield_Icons");
	UILens.ToggleLayerOff( yieldIconLens );

	ContextPtr:SetRefreshHandler( OnRefresh );

	Events.GameCoreEventPlaybackComplete.Add(OnGameCoreEventPlaybackComplete);	
	Events.ImprovementAddedToMap.Add( OnImprovementAddedToMap );
	Events.ImprovementRemovedFromMap.Add( OnImprovementRemovedFromMap );
	Events.ImprovementVisibilityChanged.Add( OnImprovementVisibilityChanged );
	Events.LoadScreenClose.Add(OnLoadScreenClose);
	Events.LocalPlayerChanged.Add( CivRoyale_OnLocalPlayerChanged );
	Events.PlayerDefeat.Add( OnPlayerDefeat );
	Events.TeamVictory.Add( OnTeamVictory );
	Events.TurnBegin.Add( OnTurnBegin );
	Events.PhaseBegin.Add( OnPhaseBegin );
	Events.WMDFalloutChanged.Add( OnWMDFalloutChanged );
	Events.OverlaySystemInitialized.Add( InitializeOverlays );
	Events.NotificationAdded.Add( OnNotificationAdded );
	Events.UnitCommandStarted.Add( OnUnitCommandStarted );
	Events.GoodyHutReward.Add(	OnGoodyHutReward );
	if isReload then
		ResetOverlays();
	end
end
