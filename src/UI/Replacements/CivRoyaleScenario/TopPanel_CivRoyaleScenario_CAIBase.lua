--	Copyright 2019, Firaxis Games

include( "InstanceManager" );
include( "SupportFunctions" ); 
include( "CivRoyaleScenario_PropKeys" );


-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local DANGER_ZONE_INTERVAL	:number = -1;	-- Value set by game script
local DANGER_ZONE_SPEED		:number = -1;	-- Value set by game script
local DANGER_ZONE_DELAY		:number = -1;	-- Value set by game script
local MAX_PARTICLES			:number = 300;
local INVALID_TURNS			:number = -1;	-- This is the value used by "NextSafeZoneTurn" before initialization or when the safe zone will no longer shrink due to being at minimum size.
local START_TURN			:number = 208;


-- ===========================================================================
--	MEMBERS
-- ===========================================================================
local m_kBracketIM :table = InstanceManager:new( "BracketInstance", "BracketTop", Controls.RingStack );


-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function OnLocalPlayerChanged( playerID:number , prevLocalPlayerID:number )	
	RefreshAll();
end

-- ===========================================================================
function OnTurnBegin()
	-- Only want this update to occur when observing because it may run before
	-- the game has a chance to update it's values (may be 1 off).
	local localPlayerID :number = Game.GetLocalPlayer();
	if localPlayerID == PlayerTypes.OBSERVER  or localPlayerID == PlayerTypes.NONE then 
		RefreshAll();
	end
end

-- ===========================================================================
function OnMenu()
	LuaEvents.InGame_OpenInGameOptionsMenu();
end


-- ===========================================================================
function RefreshTime()
	local format = UserConfiguration.GetClockFormat();
	
	local strTime;
	
	if(format == 1) then
		strTime = os.date("%H:%M");
	else
		strTime = os.date("%I:%M %p");

		-- Remove the leading zero (if any) from 12-hour clock format
		if(string.sub(strTime, 1, 1) == "0") then
			strTime = string.sub(strTime, 2);
		end
	end

	Controls.Time:SetText( strTime );
	local d = Locale.Lookup("{1_Time : datetime full}", os.time());
	Controls.Time:SetToolTipString(d);
end


-- ===========================================================================
--	Use an animation control to occasionally (not per frame!) callback for
--	an update on the current time.
-- ===========================================================================
function OnRefreshTimeTick()
	RefreshTime();
	Controls.TimeCallback:SetToBeginning();
	Controls.TimeCallback:Play();
end

-- ===========================================================================
function RefreshTurnsRemaining()

	local endTurn = Game.GetGameEndTurn();		-- This EXCLUSIVE, i.e. the turn AFTER the last playable turn.
	local turn = Game.GetCurrentGameTurn();

	if GameCapabilities.HasCapability("CAPABILITY_DISPLAY_NORMALIZED_TURN") then
		turn = (turn - GameConfiguration.GetStartTurn()) + 1; -- Keep turns starting at 1.
		if endTurn > 0 then
			endTurn = endTurn - GameConfiguration.GetStartTurn();
		end
	end

	if endTurn > 0 then
		-- We have a hard turn limit
		Controls.Turns:SetText(tostring(turn) .. "/" .. tostring(endTurn - 1));
	else
		Controls.Turns:SetText(tostring(turn));
	end

	local strDate = Calendar.MakeYearStr(turn);
	Controls.CurrentDate:SetText(Locale.Lookup("LOC_CAI_CIV_ROYALE_DATE"));
end

-- ===========================================================================
function RefreshRoyaleUnit()
	local localPlayerID :number = Game.GetLocalPlayer();
	if localPlayerID == PlayerTypes.OBSERVER  or localPlayerID == PlayerTypes.NONE then 
		return;
	end

	local pPlayer:table = Players[localPlayerID];
	local pPlayerConfig:table = PlayerConfigurations[localPlayerID];
	local pPlayerUnits:table = pPlayer:GetUnits();
	local isHidingFalloutWarning:boolean = true;
	local pUnitInFallout:table = nil;

	for i, pUnit in pPlayerUnits:Members() do
		local unitTypeName = UnitManager.GetTypeName(pUnit)
		if (unitTypeName == "UNIT_SETTLER") then
			local pUnitPlot = Map.GetPlot(pUnit:GetX(),pUnit:GetY());
			if(not CheckUnitFalloutStatus(pUnitPlot, pPlayerConfig)) then
				pUnitInFallout = pUnit;
				isHidingFalloutWarning = false;
				break;
			end
		end
	end

	Controls.RunningUnit:SetHide(isHidingFalloutWarning);
	if(not isHidingFalloutWarning) then
		Controls.RunningUnit:RegisterCallback(Mouse.eLClick, function ()
			UI.SelectUnit(pUnitInFallout);
			local plot : table = Map.GetPlot( pUnitInFallout:GetX(), pUnitInFallout:GetY() );
			UI.LookAtPlot( plot );
		end);
	end
end

function CheckUnitFalloutStatus(pUnitPlot :object, localPlayerConfig :object)
	-- Check for not being in fallout
	local pFalloutManager:table = Game.GetFalloutManager();
	if (not pFalloutManager:HasFallout(pUnitPlot:GetIndex()) ) then
		return true;
	end

	-- We are in fallout, are we a mutant sitting in mutant spread fallout?
	if(localPlayerConfig ~= nil and localPlayerConfig:GetCivilizationTypeName() == g_CivTypeNames.Mutants) then	
		local mutantDropProp = pUnitPlot:GetProperty(g_plotStateKeys.MutantDropped);
		if(mutantDropProp ~= nil and mutantDropProp > 0) then
			return true;
		end
	end

	-- We are in "bad" fallout that we should show the Red Death unit warning.
	return false;
end

-- ===========================================================================
function RefreshAll()
	RefreshRoyaleRing();
	RefreshTurnsRemaining();
	RefreshTime();		
	RefreshRoyaleUnit();
	RealizeNukes();
end

-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function OnLocalPlayerTurnBegin()	
	RefreshAll();
end

-- ===========================================================================
function OnPlayerChangeClose()
	RefreshAll();
end

-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function OnUpdateUI( type:number, tag:string, iData1:number, iData2:number, strData1:string)
	if type == SystemUpdateUI.ScreenResize then
	end
end

-- ===========================================================================
function OnRefresh()
	ContextPtr:ClearRequestRefresh();
	--RefreshAll();
end



-- ===========================================================================
--	Game Engine Event
--	Wait until the game engine is done loading before the initial refresh,
--	otherwise there is a chance the load of the LUA threads (UI & core) will 
--  clash and then we'll all have a bad time. :(
-- ===========================================================================
function OnLoadGameViewStateDone()
	RefreshAll();
end


-- ===========================================================================
function lerp(a:number, b:number, t:number)
	return a * (1-t) + (b*t);
end

-- ===========================================================================
function RefreshRoyaleRing()
	
	local turn		:number = Game.GetCurrentGameTurn();
	local turnsLeft	:number = Game:GetProperty("NextSafeZoneTurn");
	local turnsStart:number	= Game:GetProperty("StartSafeZoneTurn");
	local safeZonePhase:number = Game:GetProperty("SafeZonePhase");

	local pFalloutManager = Game.GetFalloutManager();
	local falloutDamage :number = pFalloutManager:GetFalloutDamageOverride();

	if(falloutDamage == FalloutDamages.USE_FALLOUT_DEFAULT or falloutDamage == nil) then 
		falloutDamage = 0;
	end
	-- This drives the visual intensity of the fallout particle VFX
	WorldView.SetVFXImport("FalloutDamage", falloutDamage);
	
	if(turnsLeft == INVALID_TURNS) then
		Controls.RingTurns:SetHide(true);
		Controls.RingTurnsLabel:SetHide(true);
	else
		Controls.RingTurns:SetHide(false);
		Controls.RingTurnsLabel:SetHide(false);
		Controls.RingTurns:SetText( turnsLeft - turn);

		Controls.RingTurnsLabel:SetText( Locale.ToUpper( Locale.Lookup("LOC_CIV_ROYALE_HUD_TURNS",turnsLeft-turn)));
		Controls.RingTurnsLabel:SetToolTipString( tostring(turnsLeft-turn) .. " " .. Locale.Lookup("LOC_CIV_ROYALE_HUD_TURNS_UNTIL_RING_SHRINKS"));
	end
	
	local tt:string = Locale.Lookup("LOC_CIV_ROYALE_HUD_CATEGORY_TOOLTIP",falloutDamage,safeZonePhase);
	Controls.RingIcon:SetToolTipString(tt);
	Controls.RingDamage:SetToolTipString(tt);
	Controls.RingDamage:SetText( tostring(falloutDamage) );
	
	--Reset instances and get animation progress with a temporary instance
	m_kBracketIM:ResetInstances();
	local uiBracket:table = m_kBracketIM:GetInstance();
	local progress :number = uiBracket.Flasher:GetProgress();
	m_kBracketIM:ReleaseInstance(uiBracket); 

	if(turnsLeft == INVALID_TURNS) then
		-- Safe Zone is not shrinking anymore.
		local num		:number = turnsStart;
		local flasherToolTipString :string = Locale.Lookup("LOC_CIV_ROYALE_HUD_TURNS_UNTIL_RING_SHRINKS_MIN_SIZE_C");
		for i=1,num,1 do
			uiBracket = m_kBracketIM:GetInstance();
			uiBracket.Flasher:SetToBeginning();
			uiBracket.Flasher:SetProgress(progress);
			uiBracket.Flasher:Play();
			uiBracket.Flasher:SetToolTipString(flasherToolTipString);
		end

		Controls.RightFlasher:SetToBeginning();
		Controls.RightFlasher:SetProgress(uiBracket.Flasher:GetProgress());
		Controls.RightFlasher:Play();

		-- Spark on the turn the safe zone shrunk to minimum.
		
		local lastSafeZoneTurn :number = Game:GetProperty("LastSafeZoneTurn");
		if(lastSafeZoneTurn ~= nil and lastSafeZoneTurn == Game.GetCurrentGameTurn()) then
			Spark();
		end
	else
		-- Safe Zone will continue to shrink.
		local MIN_FLASH_SPEED:number = 0.4;
		local MAX_FLASH_SPEED:number = 5;								-- Fastest flashing
		local num		:number = turnsStart;
		local percent	:number = 1 - ((turnsLeft - turn) / turnsStart);	-- % to 0 turns left	218,210,10 / 218,209,10 ... 228,219,10
		local speed		:number = lerp(MIN_FLASH_SPEED, MAX_FLASH_SPEED, percent); 
	
		for i=1,num,1 do
			uiBracket = m_kBracketIM:GetInstance();
			if (i >= (turnsLeft - turn)) then
				uiBracket.Flasher:SetToBeginning();
				uiBracket.Flasher:SetProgress(progress);
				uiBracket.Flasher:Play();
			else
				uiBracket.Flasher:SetToBeginning();
				uiBracket.Flasher:Stop();
			end
		
			uiBracket.Flasher:SetToolTipString( tostring(turnsLeft-turn) .. " " .. Locale.Lookup("LOC_CIV_ROYALE_HUD_TURNS_UNTIL_RING_SHRINKS"));
		end
		if((turnsLeft - turn) == 1) then
			Controls.RightFlasher:SetToBeginning();
			Controls.RightFlasher:SetProgress(uiBracket.Flasher:GetProgress());
			Controls.RightFlasher:Play();
		else
			Controls.RightFlasher:SetToBeginning();
			Controls.RightFlasher:Stop();
		end	

		if( turnsStart - (turnsLeft - turn) == 0) then
			Spark();
		end
		if(turn == START_TURN)then
			-- For fun, spark when screen first starts
			Spark();
		end
	end
end


-- ===========================================================================
--	Show # of nukes owned by the local player.
-- ===========================================================================
function RealizeNukes()
	local localPlayer	:number = Game.GetLocalPlayer();
	if localPlayer==PlayerTypes.NONE or localPlayer==PlayerTypes.OBSERVER then
		return;
	end		

	local pPlayer		:table = Players[localPlayer];
	local pPlayerWMDs	:table = pPlayer:GetWMDs();
	local numNuclear	:number = 0;
	local numThermo		:number = 0;
	local numHailMary	:number = 0;

	-- Step 1 total
	for pEntry in GameInfo.WMDs() do
		local count :number = pPlayerWMDs:GetWeaponCount(pEntry.Index);
		if (pEntry.WeaponType == "WMD_NUCLEAR_DEVICE") then				
			if (count > 0) then
				numNuclear = numNuclear + count;
			end
		elseif (pEntry.WeaponType == "WMD_THERMONUCLEAR_DEVICE") then
			if (count > 0) then
				numThermo = numThermo + count;
			end
		elseif (pEntry.WeaponType == "WMD_HAIL_MARY") then
			if (count > 0) then
				numHailMary = numHailMary + count;
			end
		end
	end

	-- Step 2 show/hide each depending on count
	if numNuclear > 0 then
		Controls.NuclearDeviceCount:SetText(numNuclear);
		if Controls.NuclearDevices:IsHidden() then
			Controls.NuclearDevices:SetHide( false );
		end
	else
		if Controls.NuclearDevices:IsVisible() then
			Controls.NuclearDevices:SetHide( true );
		end
	end

	if numThermo > 0 then		
		Controls.ThermoNuclearDeviceCount:SetText(numThermo);
		if Controls.ThermoNuclearDevices:IsHidden() then
			Controls.ThermoNuclearDevices:SetHide( false );
		end
	else
		if Controls.ThermoNuclearDevices:IsVisible() then
			Controls.ThermoNuclearDevices:SetHide( true );
		end
	end

	if numHailMary > 0 then		
		Controls.HailMaryDeviceCount:SetText(numHailMary);
		if Controls.HailMaryDevices:IsHidden() then
			Controls.HailMaryDevices:SetHide( false );
		end
	else
		if Controls.HailMaryDevices:IsVisible() then
			Controls.HailMaryDevices:SetHide( true );
		end
	end
end


-- ===========================================================================
--	Event
--	Change in nukes owned by a player.
-- ===========================================================================
function OnWMDUpdate( owner:number, WMDtype:number )
	local localPlayer :number = Game.GetLocalPlayer();
	if ( owner == localPlayer ) then
		RealizeNukes();
	end
end

-- ===========================================================================
function Spark()
	local uiEndGameMenu :object = ContextPtr:LookUpControl( "/InGame/EndGame/EndGameMenu" );
	if(uiEndGameMenu ~= nil and not uiEndGameMenu:IsHidden())then return; end
	EffectsManager:PlayEffectOneTime(Controls.RingStackAndTurns, "FireFX_CounterSpark");
end

-- ===========================================================================
function OnUnitMoveComplete(player, unitId, x, y)
	RefreshRoyaleUnit();
end

-- ===========================================================================
function OnObserverModeTurnBegin()
	RefreshAll();
end

-- ===========================================================================
function OnShutdown()
	Events.LoadGameViewStateDone.Remove(OnLoadGameViewStateDone );	
	Events.LocalPlayerChanged.Remove(	OnLocalPlayerChanged );
	Events.LocalPlayerTurnBegin.Remove(	OnLocalPlayerTurnBegin );
	Events.SystemUpdateUI.Remove(		OnUpdateUI );
	Events.TurnBegin.Remove(			OnTurnBegin );
	Events.UnitMoveComplete.Remove(		OnUnitMoveComplete );
	Events.VisualStateRestored.Remove(	OnLocalPlayerTurnBegin );
	Events.WMDCountChanged.Remove(		OnWMDUpdate );	
end

-- ===========================================================================
function LateInitialize()	

	-- Read values set by game script.
	DANGER_ZONE_INTERVAL = Game:GetProperty("DANGER_ZONE_INTERVAL");
	DANGER_ZONE_SPEED = Game:GetProperty("DANGER_ZONE_SPEED");
	DANGER_ZONE_DELAY = Game:GetProperty("DANGER_ZONE_DELAY");		

	Controls.MenuButton:RegisterCallback( Mouse.eLClick, OnMenu );
	Controls.MenuButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.TimeCallback:RegisterEndCallback( OnRefreshTimeTick );

	-- Game Events
	Events.LocalPlayerChanged.Add(		OnLocalPlayerChanged );
	Events.SystemUpdateUI.Add(			OnUpdateUI );
	Events.TurnBegin.Add(				OnTurnBegin );
	Events.UnitMoveComplete.Add(		OnUnitMoveComplete );
	Events.WMDCountChanged.Add(			OnWMDUpdate );
	
	if(GameConfiguration.IsHotseat())then
		LuaEvents.PlayerChange_Close.Add( OnPlayerChangeClose );
	else
		Events.LocalPlayerTurnBegin.Add(	OnLocalPlayerTurnBegin );
		Events.LoadGameViewStateDone.Add(	OnLoadGameViewStateDone );
		Events.VisualStateRestored.Add(		OnLocalPlayerTurnBegin );
	end	

	LuaEvents.ActionPanel_ObserverModeTurnBegin.Add(OnObserverModeTurnBegin);
end

-- ===========================================================================
function OnInit( isReload:boolean )
	LateInitialize();
end

-- ===========================================================================
function Initialize()	
	-- UI Callbacks	
	ContextPtr:SetInitHandler( OnInit );	
	ContextPtr:SetRefreshHandler( OnRefresh );	
	ContextPtr:SetShutdown( OnShutdown );	
end
Initialize();
