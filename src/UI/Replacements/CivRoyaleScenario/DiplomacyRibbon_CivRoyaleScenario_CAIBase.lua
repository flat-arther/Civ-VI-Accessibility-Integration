-- Copyright 2018-2019, Firaxis Games.

include("DiplomacyRibbon.lua");
include("LeaderIcon_CivRoyaleScenario");
include("Civ6Common.lua");


-- ===========================================================================

BASE_AddLeader = AddLeader;
BASE_LateInitialize = LateInitialize;
BASE_UpdateLeaders = UpdateLeaders;
BASE_OnTurnBegin = OnTurnBegin;

local m_ribbonStats	:number = -1;
local m_kEverAlivePlayers : table = {};

-- ===========================================================================
--	OVERRIDE
--	Add a leader (from right to left)
--	iconName,	What icon to draw for the leader portrait
--	playerID,	gamecore's player ID
--	kProps,		(optional) properties about the leader
--					isUnique, no other leaders are like this one
--					isMasked, even if stats are show, hide their values.
-- ===========================================================================
function AddLeader(iconName : string, playerID : number, kProps: table)
	local oLeaderIcon :object = GetLeaderIcon();
	local pPlayerConfig :table	= PlayerConfigurations[playerID];
	local civType		:string = pPlayerConfig:GetCivilizationTypeName();
	local CivUniqueAbilities, _, _ = GetCivilizationUniqueTraits( civType );

	local isUnique:boolean = false;
	if kProps == nil then 
		kProps = {};
		kProps.isUnique = false;
		kProps.isMasked = false; 
	end
	if kProps.isUnqiue then	isUnqiue=kProps.isUnqiue; end
	m_leadersMet = GetLeadersMet();
	m_leadersMet = m_leadersMet + 1;

	-- Create a new leader instance
	local uiPortraitButton :table = oLeaderIcon.Controls.SelectButton;
	m_uiLeadersByID = GetUILeadersByID()
	m_uiLeadersByPortrait = GetUILeadersByPortrait();
	m_uiLeadersByID[playerID] = oLeaderIcon;
	m_uiLeadersByPortrait[uiPortraitButton] = oLeaderIcon;

	oLeaderIcon:UpdateIcon(iconName, playerID, isUnqiue);
	oLeaderIcon:RegisterCallback(Mouse.eLClick, function() OnLeaderClicked(playerID); end);

	-- If using focus, setup mouse in/out callbacks... otherwise clear them.
	if 	m_ribbonStats == RibbonHUDStats.FOCUS then
		uiPortraitButton:RegisterMouseEnterCallback( 
			function( uiControl:table )
				ShowStats( oLeaderIcon );
			end
		);
		uiPortraitButton:RegisterMouseExitCallback( 
			function( uiControl:table )
				HideStats( oLeaderIcon );
			end	
		);
	else
		uiPortraitButton:ClearMouseEnterCallback(); 
		uiPortraitButton:ClearMouseExitCallback();
	end

	oLeaderIcon.LeaderContainer:RegisterSizeChanged( 
		function( uiControl ) 
			OnLeaderSizeChanged( oLeaderIcon );
		end
	);
	local tt:string = "";
	for _, item in ipairs(CivUniqueAbilities) do
		if (item.Name ~= nil and item.Name ~= "NONE") then
			if(_ > 1)then
				tt = tt .. "[NEWLINE][NEWLINE]";
			end
			tt = tt..tostring( Locale.Lookup( item.Description ) );
		end
	end
	if tt ~= "" then tt = "[NEWLINE]"..tt; end	-- If info is added, add an extra line.

	--Show dead players with an X over their icon
	if(not pPlayerConfig:IsAlive()) then
		local eliminatedToolTip	:string = Locale.Lookup("LOC_HUD_RIBBON_REDDEATH_ELIMINATED");
		oLeaderIcon:AppendTooltip(eliminatedToolTip);
		oLeaderIcon.RedDeathX:ChangeParent(oLeaderIcon.Portrait);
		oLeaderIcon.RedDeathX:SetHide(false);
		m_ribbonStats = Options.GetUserOption("Interface", "RibbonStats");	
		oLeaderIcon.ChatIndicatorFade:SetHide(true);
		if(m_ribbonStats == RibbonHUDStats.SHOW) then
			oLeaderIcon.Eliminated:SetHide(false);
		end
	else
		oLeaderIcon.ChatIndicatorFade:SetHide(false);
		oLeaderIcon:AppendTooltip( tt );
		oLeaderIcon.RedDeathX:SetHide(true);
	end
	FinishAddingLeader( playerID, oLeaderIcon, kProps );

	-- Returning so mods can override them and modify the icons

	return oLeaderIcon;
end

-- ===========================================================================
--	OVERRIDE
-- ===========================================================================
function UpdateLeaders()
	BASE_UpdateLeaders();
	local localPlayerID : number = Game.GetLocalPlayer();

	for i, pPlayer in ipairs(m_kEverAlivePlayers) do
		local playerID : number = pPlayer:GetID();
		if(not pPlayer:IsAlive() and (playerID ~= localPlayerID)) then
			local iconName	:string = "ICON_"..PlayerConfigurations[playerID]:GetLeaderTypeName();
			AddLeader(iconName, playerID, { isMasked=false, isUnique=false } );
		end
	end
end

-- ===========================================================================
--	OVERRIDE
-- ===========================================================================
function OnTurnBegin( playerID:number )
	local pPlayerConfig :table	= PlayerConfigurations[playerID];
	if(pPlayerConfig:IsAlive())then
		BASE_OnTurnBegin(playerID);
	else
		StopRibbonAnimation(playerID);
	end
end

-- ===========================================================================

function LateInitialize()
	BASE_LateInitialize();
	m_kEverAlivePlayers = PlayerManager.GetWasEverAliveMajors();
end
