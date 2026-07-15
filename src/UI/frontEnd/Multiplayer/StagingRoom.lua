----------------------------------------------------------------  
-- Staging Room Screen
----------------------------------------------------------------  
include( "InstanceManager" );	--InstanceManager
include( "PlayerSetupLogic" );
include( "NetworkUtilities" );
include( "ButtonUtilities" );
include( "PlayerTargetLogic" );
include( "ChatLogic" );
include( "NetConnectionIconLogic" );
include( "PopupDialog" );
include( "Civ6Common" );
include( "TeamSupport" );


----------------------------------------------------------------  
-- Constants
---------------------------------------------------------------- 
local CountdownTypes = {
	None				= "None",
	Launch				= "Launch",						-- Standard Launch Countdown
	Launch_Instant		= "Launch_Instant",				-- Instant Launch
	WaitForPlayers		= "WaitForPlayers",				-- Used by Matchmaking games after the Ready countdown to try to fill up the game with human players before starting.
	Ready_PlayByCloud	= "Ready_PlayByCloud",
	Ready_MatchMaking	= "Ready_MatchMaking",
};

local TimerTypes = {
	Script 				= "Script",						-- Timer is internally tracked in this script.
	NetworkManager 		= "NetworkManager",				-- Timer is handled by the NetworkManager.  This is synchronized across all the clients in a matchmaking game.
};


----------------------------------------------------------------  
-- Globals
----------------------------------------------------------------  
local g_PlayerEntries = {};					-- All the current player entries, indexed by playerID.
local g_PlayerRootToPlayerID = {};  -- maps the string name of a player entry's Root control to a playerID.
local g_PlayerReady = {};			-- cached player ready status, indexed by playerID.
local g_PlayerModStatus = {};		-- cached player localized mod status strings.
local g_cachedTeams = {};				-- A cached mapping of PlayerID->TeamID.

local m_playerTarget = { targetType = ChatTargetTypes.CHATTARGET_ALL, targetID = GetNoPlayerTargetID() };
local m_playerTargetEntries = {};
local m_ChatInstances		= {};
local m_infoTabsIM:table = InstanceManager:new("ShellTab", "TopControl", Controls.InfoTabs);
local m_shellTabIM:table = InstanceManager:new("ShellTab", "TopControl", Controls.ShellTabs);
local m_friendsIM = InstanceManager:new( "FriendInstance", "RootContainer", Controls.FriendsStack );
local m_playersIM = InstanceManager:new( "PlayerListEntry", "Root", Controls.PlayerListStack );
local g_GridLinesIM = InstanceManager:new( "HorizontalGridLine", "Control", Controls.GridContainer );
local m_gameSetupParameterIM = InstanceManager:new( "GameSetupParameter", "Root", nil );
local m_kPopupDialog:table;
local m_shownPBCReadyPopup = false;			-- Remote clients in a new PlayByCloud game get a ready-to-go popup when
											-- This variable indicates this popup has already been shown in this instance
											-- of the staging room.
local m_savePBCReadyChoice :boolean = false;	-- Should we save the user's PlayByCloud ready choice when they have decided?
local m_exitReadyWait :boolean = false;		-- Are we waiting on a local player ready change to propagate prior to exiting the match?
local m_numPlayers:number;
local m_teamColors = {};
local m_sessionID :number = FireWireTypes.FIREWIRE_INVALID_ID;

-- Additional Content 
local m_modsIM = InstanceManager:new("AdditionalContentInstance", "Root", Controls.AdditionalContentStack);

-- Reusable tooltip control
local m_CivTooltip:table = {};
ContextPtr:BuildInstanceForControl("CivToolTip", m_CivTooltip, Controls.TooltipContainer);
m_CivTooltip.UniqueIconIM = InstanceManager:new("IconInfoInstance",	"Top", m_CivTooltip.InfoStack);
m_CivTooltip.HeaderIconIM = InstanceManager:new("IconInstance", "Top", m_CivTooltip.InfoStack);
m_CivTooltip.CivHeaderIconIM = InstanceManager:new("CivIconInstance", "Top", m_CivTooltip.InfoStack);
m_CivTooltip.HeaderIM = InstanceManager:new("HeaderInstance", "Top", m_CivTooltip.InfoStack);

-- Game launch blockers
local m_bTeamsValid = true;						-- Are the teams valid for game start?
local g_everyoneConnected = true;				-- Is everyone network connected to the game?
local g_badPlayerForMapSize = false;			-- Are there too many active civs for this map?
local g_notEnoughPlayers = false;				-- Is there at least two players in the game?
local g_everyoneReady = false;					-- Is everyone ready to play?
local g_everyoneModReady = true;				-- Does everyone have the mods for this game?
local g_humanRequiredFilled = true;				-- Are all the human required slots filled by humans?
local g_duplicateLeaders = false;				-- Are there duplicate leaders blocking launch?
												-- Note:  This only applies if No Duplicate Leaders parameter is set.
local g_pbcNewGameCheck = true;					-- In a PlayByCloud game, only the game host can launch a new game.	
local g_pbcMinHumanCheck = true;				-- PlayByCloud matches need at least two human players. 
												-- The game and backend can not handle solo games. 
												-- NOTE: The backend will automatically end started PBC matches that end up 
												-- with a solo human due to quits/kicks. 
local g_matchMakeFullGameCheck = true;			-- In a Matchmaking game, we only game launch during the ready countdown if the game is full of human players.				
local g_viewingGameSummary = true;
local g_hotseatNumHumanPlayers = 0;
local g_hotseatNumAIPlayers = 0;
local g_isBuildingPlayerList = false;

local m_iFirstClosedSlot = -1;					-- Closed slot to show Add player line

local NO_COUNTDOWN = -1;

local m_countdownType :string				= CountdownTypes.None;	-- Which countdown type is active?
local g_fCountdownTimer :number 			= NO_COUNTDOWN;			-- Start game countdown timer.  Set to -1 when not in use.
local g_fCountdownInitialTime :number 		= NO_COUNTDOWN;			-- Initial time for the current countdown.
local g_fCountdownTickSoundTime	:number 	= NO_COUNTDOWN;			-- When was the last time we make a countdown tick sound?
local g_fCountdownReadyButtonTime :number	= NO_COUNTDOWN;			-- When was the last time we updated the ready button countdown time?

-- Defines for the different Countdown Types.
-- CountdownTime - How long does the ready up countdown last in seconds?
-- TickStartTime - How long before the end of the ready countdown time does the ticking start?
local g_CountdownData = {
	[CountdownTypes.Launch]				= { CountdownTime = 10,		TimerType = TimerTypes.Script,				TickStartTime = 10},
	[CountdownTypes.Launch_Instant]		= { CountdownTime = 0,		TimerType = TimerTypes.Script,				TickStartTime = 0},
	[CountdownTypes.WaitForPlayers]		= { CountdownTime = 180,	TimerType = TimerTypes.NetworkManager,		TickStartTime = 10},
	[CountdownTypes.Ready_PlayByCloud]	= { CountdownTime = 600,	TimerType = TimerTypes.Script,				TickStartTime = 10},
	[CountdownTypes.Ready_MatchMaking]	= { CountdownTime = 60,		TimerType = TimerTypes.Script,				TickStartTime = 10},
};

-- hotseatOnly - Only available in hotseat mode.
-- hotseatInProgress = Available for active civs (AI/HUMAN) when loading a hotseat game
-- hotseatAllowed - Allowed in hotseat mode.
local g_slotTypeData = 
{
	{ name ="LOC_SLOTTYPE_OPEN",		tooltip = "LOC_SLOTTYPE_OPEN_TT",		hotseatOnly=false,	slotStatus=SlotStatus.SS_OPEN,		hotseatInProgress = false,		hotseatAllowed=false},
	{ name ="LOC_SLOTTYPE_AI",			tooltip = "LOC_SLOTTYPE_AI_TT",			hotseatOnly=false,	slotStatus=SlotStatus.SS_COMPUTER,	hotseatInProgress = true,		hotseatAllowed=true },
	{ name ="LOC_SLOTTYPE_CLOSED",		tooltip = "LOC_SLOTTYPE_CLOSED_TT",		hotseatOnly=false,	slotStatus=SlotStatus.SS_CLOSED,	hotseatInProgress = false,		hotseatAllowed=true },		
	{ name ="LOC_SLOTTYPE_HUMAN",		tooltip = "LOC_SLOTTYPE_HUMAN_TT",		hotseatOnly=true,	slotStatus=SlotStatus.SS_TAKEN,		hotseatInProgress = true,		hotseatAllowed=true },		
	{ name ="LOC_MP_SWAP_PLAYER",		tooltip = "TXT_KEY_MP_SWAP_BUTTON_TT",	hotseatOnly=false,	slotStatus=-1,						hotseatInProgress = true,		hotseatAllowed=true },		
};

local MAX_EVER_PLAYERS : number = 12; -- hardwired max possible players in multiplayer, determined by how many players 
local MIN_EVER_PLAYERS : number = 2;  -- hardwired min possible players in multiplayer, the game does bad things if there aren't at least two players on different teams.
local MAX_SUPPORTED_PLAYERS : number = 8; -- Max number of officially supported players in multiplayer.  You can play with more than this number, but QA hasn't vetted it.
local g_currentMaxPlayers : number = MAX_EVER_PLAYERS;
local g_currentMinPlayers : number = MIN_EVER_PLAYERS;
	
local PlayerConnectedChatStr = Locale.Lookup( "LOC_MP_PLAYER_CONNECTED_CHAT" );
local PlayerDisconnectedChatStr = Locale.Lookup( "LOC_MP_PLAYER_DISCONNECTED_CHAT" );
local PlayerHostMigratedChatStr = Locale.Lookup( "LOC_MP_PLAYER_HOST_MIGRATED_CHAT" );
local PlayerKickedChatStr = Locale.Lookup( "LOC_MP_PLAYER_KICKED_CHAT" );
local BytesStr = Locale.Lookup( "LOC_BYTES" );
local KilobytesStr = Locale.Lookup( "LOC_KILOBYTES" );
local MegabytesStr = Locale.Lookup( "LOC_MEGABYTES" );
local DefaultHotseatPlayerName = Locale.Lookup( "LOC_HOTSEAT_DEFAULT_PLAYER_NAME" );
local NotReadyStatusStr = Locale.Lookup("LOC_NOT_READY");
local ReadyStatusStr = Locale.Lookup("LOC_READY_LABEL");
local BadMapSizeSlotStatusStr = Locale.Lookup("LOC_INVALID_SLOT_MAP_SIZE");
local BadMapSizeSlotStatusStrTT = Locale.Lookup("LOC_INVALID_SLOT_MAP_SIZE_TT");
local EmptyHumanRequiredSlotStatusStr :string = Locale.Lookup("LOC_INVALID_SLOT_HUMAN_REQUIRED");
local EmptyHumanRequiredSlotStatusStrTT :string = Locale.Lookup("LOC_INVALID_SLOT_HUMAN_REQUIRED_TT");
local UnsupportedText = Locale.Lookup("LOC_READY_UNSUPPORTED");
local UnsupportedTextTT = Locale.Lookup("LOC_READY_UNSUPPORTED_TT");
local downloadPendingStr = Locale.Lookup("LOC_MODS_SUBSCRIPTION_DOWNLOAD_PENDING");
local loadingSaveGameStr = Locale.Lookup("LOC_STAGING_ROOM_LOADING_SAVE");
local gameInProgressGameStr = Locale.Lookup("LOC_STAGING_ROOM_GAME_IN_PROGRESS");

local onlineIconStr = "[ICON_OnlinePip]";
local offlineIconStr = "[ICON_OfflinePip]";

local COLOR_GREEN				:number = UI.GetColorValueFromHexLiteral(0xFF00FF00);
local COLOR_RED					:number = UI.GetColorValueFromHexLiteral(0xFF0000FF);
local ColorString_ModGreen		:string = "[color:ModStatusGreen]";
local PLAYER_LIST_SIZE_DEFAULT	:number = 325;
local PLAYER_LIST_SIZE_HOTSEAT	:number = 535;
local GRID_LINE_WIDTH			:number = 1020;
local GRID_LINE_HEIGHT			:number = 51;
local NUM_COLUMNS				:number = 5;

local TEAM_ICON_SIZE			:number = 38;
local TEAM_ICON_PREFIX			:string = "ICON_TEAM_ICON_";


-------------------------------------------------
-- Localized Constants
-------------------------------------------------
local LOC_FRIENDS:string = Locale.ToUpper(Locale.Lookup("LOC_MULTIPLAYER_FRIENDS"));
local LOC_GAME_SETUP:string = Locale.Lookup("LOC_MULTIPLAYER_GAME_SETUP");
local LOC_GAME_SUMMARY:string = Locale.Lookup("LOC_MULTIPLAYER_GAME_SUMMARY");
local LOC_STAGING_ROOM:string = Locale.ToUpper(Locale.Lookup("LOC_MULTIPLAYER_STAGING_ROOM"));


-- ===========================================================================
function Close()	
    if m_kPopupDialog:IsOpen() then
		m_kPopupDialog:Close();
	end
	LuaEvents.Multiplayer_ExitShell();
end

-- ===========================================================================
--	Input Handler
-- ===========================================================================
function KeyUpHandler( key:number )
	if key == Keys.VK_ESCAPE then
		Close();
		return true;
	end
    return false;
end
function OnInputHandler( pInputStruct:table )
	local uiMsg :number = pInputStruct:GetMessageType();
	if uiMsg == KeyEvents.KeyUp then return KeyUpHandler( pInputStruct:GetKey() ); end	
	return false;
end


----------------------------------------------------------------  
-- Helper Functions
---------------------------------------------------------------- 
function SetCurrentMaxPlayers( newMaxPlayers : number )
	g_currentMaxPlayers = math.min(newMaxPlayers, MAX_EVER_PLAYERS);
end

function SetCurrentMinPlayers( newMinPlayers : number )
	g_currentMinPlayers = math.max(newMinPlayers, MIN_EVER_PLAYERS);
end

-- Could this player slot be displayed on the staging room?  The staging room ignores a lot of possible slots (city states; barbs; player slots exceeding the map size)
function IsDisplayableSlot(playerID :number)
	local pPlayerConfig = PlayerConfigurations[playerID];
	if(pPlayerConfig == nil) then
		return false;
	end

	if(playerID < g_currentMaxPlayers	-- Any slot under the current max player limit is displayable.
		-- Full Civ participants are displayable.
		or (pPlayerConfig:IsParticipant() 
			and pPlayerConfig:GetCivilizationLevelTypeID() == CivilizationLevelTypes.CIVILIZATION_LEVEL_FULL_CIV) ) then
			return true;
	end

	return false;
end

-- Is the cloud match in progress?
function IsCloudInProgress()
	if(not GameConfiguration.IsPlayByCloud()) then
		return false;
	end

	if(GameConfiguration.GetGameState() == GameStateTypes.GAMESTATE_LAUNCHED -- Saved game state is launched.
		-- Has the cloud match blocked player joins?  The game host sets this prior to launching the match.
		-- We check for this becaus the game state will only be set to GAMESTATE_LAUNCHED once the first turn is committed.
		-- We need to count as being inprogress from when the host started to launch the match thru them committing their first turn.
		or Network.IsCloudJoinsBlocked()) then
		return true;
	end

	return false;
end

-- Are we in a launched PlayByCloud match where it is not our turn?
function IsCloudInProgressAndNotTurn()
	if(not IsCloudInProgress()) then
		return false;
	end

	if(Network.IsCloudTurnPlayer()) then
		return false;
	end

	-- If the local player is dead, count as false.  This should result in the CheckForGameStart immediately autolaunching the game so the player can see the endgamemenu.
	local localPlayerID = Network.GetLocalPlayerID();
	if( localPlayerID ~= NetPlayerTypes.INVALID_PLAYERID) then
		local localPlayerConfig = PlayerConfigurations[localPlayerID];
		if(not localPlayerConfig:IsAlive()) then
			return false;
		end
	end

	-- TTP 44083 - It is always the host's turn if the match is "in progress" but the match has not been started.  
	-- This can happen if the game host disconnected from the match right as the launch countdown hit zero.
	if(Network.IsGameHost() and not Network.IsCloudMatchStarted()) then
		return false;
	end

	return true;
end

function IsLaunchCountdownActive()
	if(m_countdownType == CountdownTypes.Launch or m_countdownType == CountdownTypes.Launch_Instant) then
		return true;
	end

	return false;
end

function IsReadyCountdownActive()
	if(m_countdownType == CountdownTypes.Ready_MatchMaking 
		or m_countdownType == CountdownTypes.Ready_PlayByCloud) then
		return true;
	end

	return false;
end

function IsWaitForPlayersCountdownActive()
	if(m_countdownType == CountdownTypes.WaitForPlayers) then
		return true;
	end

	return false;
end

function IsUseReadyCountdown()
	local type = GetReadyCountdownType();
	if(type ~= CountdownTypes.None) then
		return true;
	end

	return false;
end

function GetReadyCountdownType()
	if(GameConfiguration.IsPlayByCloud()) then
		return CountdownTypes.Ready_PlayByCloud;
	elseif(GameConfiguration.IsMatchMaking()) then
		return CountdownTypes.Ready_MatchMaking;
	end
	return CountdownTypes.None;
end	

function IsUseWaitingForPlayersCountdown()
	return GameConfiguration.IsMatchMaking();
end

function GetCountdownTimeRemaining()
	local countdownData :table = g_CountdownData[m_countdownType];
	if(countdownData == nil) then
		return 0;
	end

	if(countdownData.TimerType == TimerTypes.NetworkManager) then
		local sessionTime :number = Network.GetElapsedSessionTime();
		return countdownData.CountdownTime - sessionTime;
	else
		return g_fCountdownTimer;
	end
end


----------------------------------------------------------------  
-- Event Handlers
---------------------------------------------------------------- 
function OnMapMaxMajorPlayersChanged(newMaxPlayers : number)
	if(g_currentMaxPlayers ~= newMaxPlayers) then
		SetCurrentMaxPlayers(newMaxPlayers);
		if(ContextPtr:IsHidden() == false) then
			CheckGameAutoStart();	-- game start can change based on the new max players.
			BuildPlayerList();	-- rebuild player list because several player slots will have changed.
		end
	end
end

function OnMapMinMajorPlayersChanged(newMinPlayers : number)
	if(g_currentMinPlayers ~= newMinPlayers) then
		SetCurrentMinPlayers(newMinPlayers);
		if(ContextPtr:IsHidden() == false) then
			CheckGameAutoStart();	-- game start can change based on the new min players.
		end
	end
end

-------------------------------------------------
-- OnGameConfigChanged
-------------------------------------------------
function OnGameConfigChanged()
	if(ContextPtr:IsHidden() == false) then
		RealizeGameSetup(); -- Rebuild the game settings UI.
		RebuildTeamPulldowns();	-- NoTeams setting might have changed.

		-- PLAYBYCLOUDTODO - Remove PBC special case once ready state changes have been moved to cloud player meta data.
		-- PlayByCloud uses GameConfigChanged to communicate player ready state changes, don't reset ready in that mode.
		if(not GameConfiguration.IsPlayByCloud() and not Automation.IsActive()) then
			SetLocalReady(false);  -- unready so player can acknowledge the new settings.
		end

		-- [TTP 42798] PlayByCloud Only - Ensure local player is ready if match is inprogress.  
		-- Previously players could get stuck unready if they unreadied between the host starting the launch countdown but before the game launch.
		if(IsCloudInProgress()) then
			SetLocalReady(true);
		end

		CheckGameAutoStart();  -- Toggling "No Duplicate Leaders" can affect the autostart.
	end
	OnMapMaxMajorPlayersChanged(MapConfiguration.GetMaxMajorPlayers());	
	OnMapMinMajorPlayersChanged(MapConfiguration.GetMinMajorPlayers());
end

-------------------------------------------------
-- OnPlayerInfoChanged
-------------------------------------------------
function PlayerInfoChanged_SpecificPlayer(playerID)
	-- Targeted update of another player's entry.
	local pPlayerConfig = PlayerConfigurations[playerID];
	if(g_cachedTeams[playerID] ~= pPlayerConfig:GetTeam()) then
		OnTeamChange(playerID, false);
	end

	Controls.PlayerListStack:SortChildren(SortPlayerListStack);
	UpdatePlayerEntry(playerID);
	
	Controls.PlayerListStack:CalculateSize();
	Controls.PlayersScrollPanel:CalculateSize();
end

function OnPlayerInfoChanged(playerID)
	if(ContextPtr:IsHidden() == false) then
		-- Ignore PlayerInfoChanged events for non-displayable player slots.
		if(not IsDisplayableSlot(playerID)) then
			return;
		end

		if(playerID == Network.GetLocalPlayerID()) then
			-- If we are the host and our info changed, we need to locally refresh all the player slots.
			-- We do this because the host's ready status disables/enables pulldowns on all the other player slots.
			if(Network.IsGameHost()) then
				UpdateAllPlayerEntries();
			else
				-- A remote client needs to update the disabled status of all slot type pulldowns if their data was changed.
				-- We do this because readying up disables the slot type pulldown for all players.
				UpdateAllPlayerEntries_SlotTypeDisabled();

				PlayerInfoChanged_SpecificPlayer(playerID);
			end
		else
			PlayerInfoChanged_SpecificPlayer(playerID);
		end

		CheckGameAutoStart();	-- Player might have changed their ready status.
		UpdateReadyButton();
		
		-- Update chat target pulldown.
		PlayerTarget_OnPlayerInfoChanged( playerID, Controls.ChatPull, Controls.ChatEntry, Controls.ChatIcon, m_playerTargetEntries, m_playerTarget, false);
	end
end

function OnUploadCloudPlayerConfigComplete(success :boolean)
	if(m_exitReadyWait == true) then
		m_exitReadyWait = false;
		Close();
	end
end

-------------------------------------------------
-- OnTeamChange
-------------------------------------------------
function OnTeamChange( playerID, isBatchCall )
	local pPlayerConfig = PlayerConfigurations[playerID];
	if(pPlayerConfig ~= nil) then
		local teamID = pPlayerConfig:GetTeam();
		local playerEntry = GetPlayerEntry(playerID);
		local updateOpenEmptyTeam = false;

		-- Check for situations where we might need to update the Open Empty Team slot.
		if( (g_cachedTeams[playerID] ~= nil and GameConfiguration.GetTeamPlayerCount(g_cachedTeams[playerID]) <= 0) -- was last player on old team.
			or (GameConfiguration.GetTeamPlayerCount(teamID) <= 1) ) then -- first player on new team.
			-- this player was the last player on that team.  We might need to create a new empty team.
			updateOpenEmptyTeam = true;
		end
		
		if(g_cachedTeams[playerID] ~= nil 
			and g_cachedTeams[playerID] ~= teamID
			-- Remote clients will receive team changes during the PlayByCloud game launch process if they just wait in the staging room.
			-- That should not unready the player which can mess up the autolaunch process.
			and not IsCloudInProgress()) then 
			-- Reset the player's ready status if they actually changed teams.
			SetLocalReady(false);
		end

		-- cache the player's teamID for the next OnTeamChange.
		g_cachedTeams[playerID] = teamID;
		
		if(not isBatchCall) then
			-- There's some stuff that we have to do it to maintain the player list. 
			-- We intentionally wait to do this if we're in the middle of doing a batch of these updates.
			-- If you're doing a batch of these, call UpdateTeamList(true) when you're done.
			UpdateTeamList(updateOpenEmptyTeam);
		end
	end	
end


-------------------------------------------------
-- OnMultiplayerPingTimesChanged
-------------------------------------------------
function OnMultiplayerPingTimesChanged()
	for playerID, playerEntry in pairs( g_PlayerEntries ) do
		UpdateNetConnectionIcon(playerID, playerEntry.ConnectionStatus, playerEntry.StatusLabel);
		UpdateNetConnectionLabel(playerID, playerEntry.StatusLabel);
	end
end

function OnCloudGameKilled( matchID, success )
	if(success) then
		Close();
	else
		--Show error prompt.
		m_kPopupDialog:Close();
		m_kPopupDialog:AddTitle(  Locale.ToUpper(Locale.Lookup("LOC_MULTIPLAYER_ENDING_GAME_FAIL_TITLE")));
		m_kPopupDialog:AddText(	  Locale.Lookup("LOC_MULTIPLAYER_ENDING_GAME_FAIL"));
		m_kPopupDialog:AddButton( Locale.Lookup("LOC_MULTIPLAYER_ENDING_GAME_FAIL_ACCEPT") );
		m_kPopupDialog:Open();
	end
end

function OnCloudGameQuit( matchID, success )
	if(success) then
		-- On success, close popup and exit the screen
		Close();
	else
		--Show error prompt.
		m_kPopupDialog:Close();
		m_kPopupDialog:AddTitle(  Locale.ToUpper(Locale.Lookup("LOC_MULTIPLAYER_QUITING_GAME_FAIL_TITLE")));
		m_kPopupDialog:AddText(	  Locale.Lookup("LOC_MULTIPLAYER_QUITING_GAME_FAIL"));
		m_kPopupDialog:AddButton( Locale.Lookup("LOC_MULTIPLAYER_QUITING_GAME_FAIL_ACCEPT") );
		m_kPopupDialog:Open();
	end
end

-------------------------------------------------
-- Chat
-------------------------------------------------
function OnMultiplayerChat( fromPlayer, toPlayer, text, eTargetType )
	OnChat(fromPlayer, toPlayer, text, eTargetType, true);
end

function OnChat( fromPlayer, toPlayer, text, eTargetType, playSounds :boolean )
	if(ContextPtr:IsHidden() == false) then
		local pPlayerConfig = PlayerConfigurations[fromPlayer];
		local playerName = Locale.Lookup(pPlayerConfig:GetPlayerName());

		-- Selecting chat text color based on eTargetType	
		local chatColor :string = "[color:ChatMessage_Global]";
		if(eTargetType == ChatTargetTypes.CHATTARGET_TEAM) then
			chatColor = "[color:ChatMessage_Team]";
		elseif(eTargetType == ChatTargetTypes.CHATTARGET_PLAYER) then
			chatColor = "[color:ChatMessage_Whisper]";  
		end
		
		local chatString	= "[color:ChatPlayerName]" .. playerName;

		-- When whispering, include the whisperee's name as well.
		if(eTargetType == ChatTargetTypes.CHATTARGET_PLAYER) then
			local pTargetConfig :table	= PlayerConfigurations[toPlayer];
			if(pTargetConfig ~= nil) then
				local targetName = Locale.Lookup(pTargetConfig:GetPlayerName());
				chatString = chatString .. " [" .. targetName .. "]";
			end
		end

		-- Ensure text parsed properly
		text = ParseChatText(text);

		chatString			= chatString .. ": [ENDCOLOR]" .. chatColor;
		-- Add a space before the [ENDCOLOR] tag to prevent the user from accidentally escaping it
		chatString			= chatString .. text .. " [ENDCOLOR]";

		AddChatEntry( chatString, Controls.ChatStack, m_ChatInstances, Controls.ChatScroll);

		if(playSounds and fromPlayer ~= Network.GetLocalPlayerID()) then
			UI.PlaySound("Play_MP_Chat_Message_Received");
		end
	end
end

-------------------------------------------------
-------------------------------------------------
function SendChat( text )
    if( string.len( text ) > 0 ) then
		-- Parse text for possible chat commands
		local parsedText :string;
		local chatTargetChanged :boolean = false;
		local printHelp :boolean = false;
		parsedText, chatTargetChanged, printHelp = ParseInputChatString(text, m_playerTarget);
		if(chatTargetChanged) then
			ValidatePlayerTarget(m_playerTarget);
			UpdatePlayerTargetPulldown(Controls.ChatPull, m_playerTarget);
			UpdatePlayerTargetEditBox(Controls.ChatEntry, m_playerTarget);
			UpdatePlayerTargetIcon(Controls.ChatIcon, m_playerTarget);
		end

		if(printHelp) then
			ChatPrintHelp(Controls.ChatStack, m_ChatInstances, Controls.ChatScroll);
		end

		if(parsedText ~= "") then
			-- m_playerTarget uses PlayerTargetLogic values and needs to be converted  
			local chatTarget :table ={};
			PlayerTargetToChatTarget(m_playerTarget, chatTarget);
			Network.SendChat( parsedText, chatTarget.targetType, chatTarget.targetID );
			UI.PlaySound("Play_MP_Chat_Message_Sent");
		end
    end
    Controls.ChatEntry:ClearString();
end

-------------------------------------------------
-- ParseChatText - ensures icon tags parsed properly
-------------------------------------------------
function ParseChatText(text)
	startIdx, endIdx = string.find(string.upper(text), "%[ICON_");
	if(startIdx == nil) then
		return text;
	else
		for i = endIdx + 1, string.len(text) do
			character = string.sub(text, i, i);
			if(character=="]") then
				return string.sub(text, 1, i) .. ParseChatText(string.sub(text,i + 1));
			elseif(character==" ") then
				text = string.gsub(text, " ", "]", 1);
				return string.sub(text, 1, i) .. ParseChatText(string.sub(text, i + 1));
			elseif (character=="[") then
				return string.sub(text, 1, i - 1) .. "]" .. ParseChatText(string.sub(text, i));
			end
		end
		return text.."]";
	end
	return text;
end

-------------------------------------------------
-------------------------------------------------

function OnMultplayerPlayerConnected( playerID )
	if( ContextPtr:IsHidden() == false ) then
		OnChat( playerID, -1, PlayerConnectedChatStr, false );
		UI.PlaySound("Play_MP_Player_Connect");
		UpdateFriendsList();

		-- Autoplay Host readies up as soon as the required number of network connections (human or autoplay players) have connected.
		if(Automation.IsActive() and Network.IsGameHost()) then
			local minPlayers = Automation.GetSetParameter("CurrentTest", "MinPlayers", 2);
			local connectedCount = 0;
			if(minPlayers ~= nil) then
				-- Count network connected player slots
				local player_ids = GameConfiguration.GetMultiplayerPlayerIDs();
				for i, iPlayer in ipairs(player_ids) do	
					if(Network.IsPlayerConnected(iPlayer)) then
						connectedCount = connectedCount + 1;
					end
				end

				if(connectedCount >= minPlayers) then
					Automation.Log("HostGame MinPlayers met, host readying up.  MinPlayers=" .. tostring(minPlayers) .. " ConnectedPlayers=" .. tostring(connectedCount));
					SetLocalReady(true);
				end
			end
		end
	end
end

-------------------------------------------------
-------------------------------------------------

function OnMultiplayerPrePlayerDisconnected( playerID )
	if( ContextPtr:IsHidden() == false ) then
		local playerCfg = PlayerConfigurations[playerID];
		if(playerCfg:IsHuman()) then
			if(Network.IsPlayerKicked(playerID)) then
				OnChat( playerID, -1, PlayerKickedChatStr, false );
			else
    			OnChat( playerID, -1, PlayerDisconnectedChatStr, false );
			end
			UI.PlaySound("Play_MP_Player_Disconnect");
			UpdateFriendsList();
		end
	end
end

-------------------------------------------------
-------------------------------------------------

function OnModStatusUpdated(playerID: number, modState : number, bytesDownloaded : number, bytesTotal : number,
							modsRemaining : number, modsRequired : number)
	
	if(modState == 1) then -- MOD_STATE_DOWNLOADING
		local modStatusString = downloadPendingStr;
		modStatusString = modStatusString .. "[NEWLINE][Icon_AdditionalContent]" .. tostring(modsRemaining) .. "/" .. tostring(modsRequired);
		g_PlayerModStatus[playerID] = modStatusString;
	else
		g_PlayerModStatus[playerID] = nil;
	end
	UpdatePlayerEntry(playerID);

	--[[ Prototype Mod Status Progress Bars
	local playerEntry = g_PlayerEntries[playerID];
	if(playerEntry ~= nil) then
		if(modState ~= 1) then
			playerEntry.PlayerModProgressStack:SetHide(true);
		else
			-- MOD_STATE_DOWNLOADING
			playerEntry.PlayerModProgressStack:SetHide(false);

			-- Update Progress Bar
			local progress : number = 0;
			if(bytesTotal > 0) then
				progress = bytesDownloaded / bytesTotal;
			end
			playerEntry.ModProgressBar:SetPercent(progress);

			-- Building Bytes Remaining Label
			if(bytesTotal > 0) then
				local bytesRemainingStr : string = "";
				local modSizeStr : string = BytesStr;
				local bytesDownloadedScaled : number = bytesDownloaded;
				local bytesTotalScaled : number = bytesTotal;
				if(bytesTotal > 1000000) then
					-- Megabytes
					modSizeStr = MegabytesStr;
					bytesDownloadedScaled = bytesDownloadedScaled / 1000000;
					bytesTotalScaled = bytesTotalScaled / 1000000;
				elseif(bytesTotal > 1000) then
					-- kilobytes
					modSizeStr = KilobytesStr;
					bytesDownloadedScaled = bytesDownloadedScaled / 1000;
					bytesTotalScaled = bytesTotalScaled / 1000;
				end
				bytesRemainingStr = string.format("%.02f%s/%.02f%s", bytesDownloadedScaled, modSizeStr, bytesTotalScaled, modSizeStr);
				playerEntry.BytesRemaining:SetText(bytesRemainingStr);
				playerEntry.BytesRemaining:SetHide(false);
			else
				playerEntry.BytesRemaining:SetHide(true);
			end

			-- Bulding ModProgressRemaining Label
			local modProgressStr : string = "";
			modProgressStr = modProgressStr .. " " .. tostring(modsRemaining) .. "/" .. tostring(modsRequired);
			playerEntry.ModProgressRemaining:SetText(modProgressStr);
		end
	end
	--]]
end

-------------------------------------------------
-------------------------------------------------

function OnAbandoned(eReason)
	if (not ContextPtr:IsHidden()) then

		-- We need to CheckLeaveGame before triggering the reason popup because the reason popup hides the staging room
		-- and would block the leave game incorrectly.  This fixes TTP 22192.
		CheckLeaveGame();

		if (eReason == KickReason.KICK_HOST) then
			LuaEvents.MultiplayerPopup( "LOC_GAME_ABANDONED_KICKED", "LOC_GAME_ABANDONED_KICKED_TITLE" );
		elseif (eReason == KickReason.KICK_NO_HOST) then
			LuaEvents.MultiplayerPopup( "LOC_GAME_ABANDONED_HOST_LOSTED", "LOC_GAME_ABANDONED_HOST_LOSTED_TITLE" );
		elseif (eReason == KickReason.KICK_NO_ROOM) then
			LuaEvents.MultiplayerPopup( "LOC_GAME_ABANDONED_ROOM_FULL", "LOC_GAME_ABANDONED_ROOM_FULL_TITLE" );
		elseif (eReason == KickReason.KICK_VERSION_MISMATCH) then
			LuaEvents.MultiplayerPopup( "LOC_GAME_ABANDONED_VERSION_MISMATCH", "LOC_GAME_ABANDONED_VERSION_MISMATCH_TITLE" );
		elseif (eReason == KickReason.KICK_MOD_ERROR) then
			LuaEvents.MultiplayerPopup( "LOC_GAME_ABANDONED_MOD_ERROR", "LOC_GAME_ABANDONED_MOD_ERROR_TITLE" );
		elseif (eReason == KickReason.KICK_MOD_MISSING) then
			local modMissingErrorStr = Modding.GetLastModErrorString();
			LuaEvents.MultiplayerPopup( modMissingErrorStr, "LOC_GAME_ABANDONED_MOD_MISSING_TITLE" );
		elseif (eReason == KickReason.KICK_MATCH_DELETED) then
			LuaEvents.MultiplayerPopup( "LOC_GAME_ABANDONED_MATCH_DELETED", "LOC_GAME_ABANDONED_MATCH_DELETED_TITLE" );
		else
			LuaEvents.MultiplayerPopup( "LOC_GAME_ABANDONED_CONNECTION_LOST", "LOC_GAME_ABANDONED_CONNECTION_LOST_TITLE");
		end
		Close();
	end
end

-------------------------------------------------
-------------------------------------------------

function OnMultiplayerGameLaunchFailed()
	-- Multiplayer game failed for launch for some reason.
	if(not GameConfiguration.IsPlayByCloud()) then
		SetLocalReady(false); -- Unready the local player so they can try it again.
	end

	m_kPopupDialog:Close();	-- clear out the popup incase it is already open.
	m_kPopupDialog:AddTitle(  Locale.ToUpper(Locale.Lookup("LOC_MULTIPLAYER_GAME_LAUNCH_FAILED_TITLE")));
	m_kPopupDialog:AddText(	  Locale.Lookup("LOC_MULTIPLAYER_GAME_LAUNCH_FAILED"));
	m_kPopupDialog:AddButton( Locale.Lookup("LOC_MULTIPLAYER_GAME_LAUNCH_FAILED_ACCEPT"));
	m_kPopupDialog:Open();
end

-------------------------------------------------
-------------------------------------------------

function OnLeaveGameComplete()
	-- We just left the game, we shouldn't be open anymore.
	UIManager:DequeuePopup( ContextPtr );
end

-------------------------------------------------
-------------------------------------------------

function OnBeforeMultiplayerInviteProcessing()
	-- We're about to process a game invite.  Get off the popup stack before we accidently break the invite!
	UIManager:DequeuePopup( ContextPtr );
end


-------------------------------------------------
-------------------------------------------------

function OnMultiplayerHostMigrated( newHostID : number )
	if(ContextPtr:IsHidden() == false) then
		-- If the local machine has become the host, we need to rebuild the UI so host privileges are displayed.
		local localPlayerID = Network.GetLocalPlayerID();
		if(localPlayerID == newHostID) then
			RealizeGameSetup();
			BuildPlayerList();
		end

		OnChat( newHostID, -1, PlayerHostMigratedChatStr, false );
		UI.PlaySound("Play_MP_Host_Migration");
	end
end

----------------------------------------------------------------
-- Button Handlers
----------------------------------------------------------------

-------------------------------------------------
-- OnSlotType
-------------------------------------------------
function OnSlotType( playerID, id )
	--print("playerID: " .. playerID .. " id: " .. id);
	-- NOTE:  This function assumes that the given player slot is not occupied by a player.  We
	--				assume that players having to be kicked before the slot's type can be manually changed.
	local pPlayerConfig = PlayerConfigurations[playerID];
	local pPlayerEntry = g_PlayerEntries[playerID];

	if g_slotTypeData[id].slotStatus == -1 then
		OnSwapButton(playerID);
		return;
	end

	pPlayerConfig:SetSlotStatus(g_slotTypeData[id].slotStatus);

	-- When setting the slot status to a major civ type, some additional data in the player config needs to be set.
	if(g_slotTypeData[id].slotStatus == SlotStatus.SS_TAKEN or g_slotTypeData[id].slotStatus == SlotStatus.SS_COMPUTER) then
		pPlayerConfig:SetMajorCiv();
	end

	Network.BroadcastPlayerInfo(playerID); -- Network the slot status change.
	
	Controls.PlayerListStack:SortChildren(SortPlayerListStack);
	
	m_iFirstClosedSlot = -1;
	UpdateAllPlayerEntries();

	UpdatePlayerEntry(playerID);

	CheckTeamsValid();
	CheckGameAutoStart();

	if g_slotTypeData[id].slotStatus == SlotStatus.SS_CLOSED then
		Controls.PlayerListStack:CalculateSize();
		Controls.PlayersScrollPanel:CalculateSize();
	end
end

-------------------------------------------------
-- OnSwapButton
-------------------------------------------------
function OnSwapButton(playerID)
	-- In this case, playerID is the desired playerID.
	local localPlayerID = Network.GetLocalPlayerID();
	local oldDesiredPlayerID = Network.GetChangePlayerID(localPlayerID);
	local newDesiredPlayerID = playerID;
	if(oldDesiredPlayerID == newDesiredPlayerID) then
		-- player already requested to swap to this player.  Toggle back to no player swap.
		newDesiredPlayerID = NetPlayerTypes.INVALID_PLAYERID;
	end
	Network.RequestPlayerIDChange(newDesiredPlayerID);
end

-------------------------------------------------
-- OnKickButton
-------------------------------------------------
function OnKickButton(playerID)
	-- Kick button was clicked for the given player slot.
	--print("playerID " .. playerID);
	UIManager:PushModal(Controls.ConfirmKick, true);
	local pPlayerConfig = PlayerConfigurations[playerID];
	if pPlayerConfig:GetSlotStatus() == SlotStatus.SS_COMPUTER then
		LuaEvents.SetKickPlayer(playerID, "LOC_SLOTTYPE_AI");
	else
		local playerName = pPlayerConfig:GetPlayerName();
		LuaEvents.SetKickPlayer(playerID, playerName);
	end
end

-------------------------------------------------
-- OnAddPlayer
-------------------------------------------------
function OnAddPlayer(playerID)
	-- Add Player was clicked for the given player slot.
	-- Set this slot to open	
	
	local pPlayerConfig = PlayerConfigurations[playerID];
	local playerName = pPlayerConfig:GetPlayerName();
	m_iFirstClosedSlot = -1;
	
	pPlayerConfig:SetSlotStatus(SlotStatus.SS_OPEN);
	Network.BroadcastPlayerInfo(playerID); -- Network the slot status change.

	Controls.PlayerListStack:SortChildren(SortPlayerListStack);
	UpdateAllPlayerEntries();

	CheckTeamsValid();
	CheckGameAutoStart();

	Controls.PlayerListStack:CalculateSize();
	Controls.PlayersScrollPanel:CalculateSize();
	Resize();	
end

-------------------------------------------------
-- OnPlayerEntryReady
-------------------------------------------------
function OnPlayerEntryReady(playerID)
	-- Every player entry ready button has this callback, but it only does something if this is for the local player.
	local localPlayerID = Network.GetLocalPlayerID();
	if(playerID == localPlayerID) then
		OnReadyButton();
	end
end

-------------------------------------------------
-- OnJoinTeamButton
-------------------------------------------------
function OnTeamPull( playerID :number, teamID :number)
	local playerConfig = PlayerConfigurations[playerID];

	if(playerConfig ~= nil and teamID ~= playerConfig:GetTeam()) then
		playerConfig:SetTeam(teamID);
		Network.BroadcastPlayerInfo(playerID);
		OnTeamChange(playerID, false);
	end

	UpdatePlayerEntry(playerID);
end

-------------------------------------------------
-- OnInviteButton
-------------------------------------------------
function OnInviteButton()
	local pFriends = Network.GetFriends(Network.GetTransportType());
	if pFriends ~= nil then
		pFriends:ActivateInviteOverlay();
	end
end

-------------------------------------------------
-- OnReadyButton
-------------------------------------------------
function OnReadyButton()
	local localPlayerID = Network.GetLocalPlayerID();
	local localPlayerConfig = PlayerConfigurations[localPlayerID];

	if(not IsCloudInProgress()) then -- PlayByCloud match already in progress, don't touch the local ready state.
		SetLocalReady(not localPlayerConfig:GetReady());
	end
	
	-- Clicking the ready button in some situations instant launches the game.
	if(GameConfiguration.IsHotseat() 
		-- Not our turn in an inprogress PlayByCloud match.  Immediately launch game so player can observe current game state.
		-- NOTE: We can only do this if GAMESTATE_LAUNCHED is set. This indicates that the game host has committed the first turn and
		--		GAMESTATE_LAUNCHED is baked into the save state.
		or (IsCloudInProgressAndNotTurn() and GameConfiguration.GetGameState() == GameStateTypes.GAMESTATE_LAUNCHED)) then 
		Network.LaunchGame();
	end
end

-------------------------------------------------
-- OnClickToCopy
-------------------------------------------------
function OnClickToCopy()
	local sText:string = Controls.JoinCodeText:GetText();
	UIManager:SetClipboardString(sText);
end

----------------------------------------------------------------
-- Screen Scripting
----------------------------------------------------------------
function SetLocalReady(newReady)
	local localPlayerID = Network.GetLocalPlayerID();
	local localPlayerConfig = PlayerConfigurations[localPlayerID];

	-- PlayByCloud Only - Disallow unreadying once the match has started.
	if(IsCloudInProgress() and newReady == false) then
		return;
	end

	-- When using a ready countdown, the player can not unready themselves outside of the ready countdown.
	if(IsUseReadyCountdown() 
		and newReady == false
		and not IsReadyCountdownActive()) then
		return;
	end
	
	if(newReady ~= localPlayerConfig:GetReady()) then
		
		if not GameConfiguration.IsHotseat() then
			Controls.ReadyCheck:SetSelected(newReady);
		end

		-- Show ready-to-go popup when a remote client readies up in a fresh PlayByCloud match.
		if(newReady 
			and GameConfiguration.IsPlayByCloud()
			and GameConfiguration.GetGameState() ~= GameStateTypes.GAMESTATE_LAUNCHED
			and not m_shownPBCReadyPopup
			and not m_exitReadyWait) then -- Do not show ready popup if we are exiting due to pressing the back button.
			ShowPBCReadyPopup();
		end

		localPlayerConfig:SetReady(newReady);
		Network.BroadcastPlayerInfo();
		UpdatePlayerEntry(localPlayerID);
		CheckGameAutoStart();
	end
end

function ShowPBCReadyPopup()
	m_shownPBCReadyPopup = true;
	local readyUpBehavior :number = UserConfiguration.GetPlayByCloudClientReadyBehavior();
	if(readyUpBehavior == PlayByCloudReadyBehaviorType.PBC_READY_ASK_ME) then
		m_kPopupDialog:Close();	-- clear out the popup incase it is already open.
		m_kPopupDialog:AddTitle(  Locale.ToUpper(Locale.Lookup("LOC_PLAYBYCLOUD_REMOTE_READY_POPUP_TITLE")));
		m_kPopupDialog:AddText(	  Locale.Lookup("LOC_PLAYBYCLOUD_REMOTE_READY_POPUP_TEXT"));
		m_kPopupDialog:AddCheckBox(Locale.Lookup("LOC_REMEMBER_MY_CHOICE"), false, OnPBCReadySaveChoice);
		m_kPopupDialog:AddButton( Locale.Lookup("LOC_PLAYBYCLOUD_REMOTE_READY_POPUP_OK"), OnPBCReadyOK );
		m_kPopupDialog:AddButton( Locale.Lookup("LOC_PLAYBYCLOUD_REMOTE_READY_POPUP_LOBBY_EXIT"), OnPBCReadyExitGame, nil, nil );
		m_kPopupDialog:Open();
	elseif(readyUpBehavior == PlayByCloudReadyBehaviorType.PBC_READY_EXIT_LOBBY) then
		StartExitGame();
	end

	-- Nothing needs to happen for the PlayByCloudReadyBehaviorType.PBC_READY_DO_NOTHING.  Obviously.

end

function OnPBCReadySaveChoice()
	m_savePBCReadyChoice = true;
end

function OnPBCReadyOK()
	-- OK means do nothing and remain in the staging room.
	if(m_savePBCReadyChoice == true) then
		Options.SetUserOption("Interface", "PlayByCloudClientReadyBehavior", PlayByCloudReadyBehaviorType.PBC_READY_DO_NOTHING);
		Options.SaveOptions();
	end	
end

function OnPBCReadyExitGame()
	if(m_savePBCReadyChoice == true) then
		Options.SetUserOption("Interface", "PlayByCloudClientReadyBehavior", PlayByCloudReadyBehaviorType.PBC_READY_EXIT_LOBBY);
		Options.SaveOptions();
	end	

	StartExitGame();
end

-------------------------------------------------
-- Update Teams valid status
-------------------------------------------------
function CheckTeamsValid()
	m_bTeamsValid = false;
	local noTeamPlayers : boolean = false;
	local teamTest : number = TeamTypes.NO_TEAM;
    
	-- Teams are invalid if all players are on the same team.
	local player_ids = GameConfiguration.GetParticipatingPlayerIDs();
	for i, iPlayer in ipairs(player_ids) do	
		local curPlayerConfig = PlayerConfigurations[iPlayer];
		if( curPlayerConfig:IsParticipant() 
		and curPlayerConfig:GetCivilizationLevelTypeID() == CivilizationLevelTypes.CIVILIZATION_LEVEL_FULL_CIV ) then
			local curTeam : number = curPlayerConfig:GetTeam();
			if(curTeam == TeamTypes.NO_TEAM) then
				-- If someone doesn't have a team, it means that teams are valid.
				m_bTeamsValid = true;
				return;
			elseif(teamTest == TeamTypes.NO_TEAM) then
				teamTest = curTeam;
			elseif(teamTest ~= curTeam) then
				-- people are on different teams.  Teams are valid.
				m_bTeamsValid = true;
				return;
			end
		end
	end
end

-------------------------------------------------
-- CHECK FOR GAME AUTO START
-------------------------------------------------
function CheckGameAutoStart()
	
	-- PlayByCloud Only - Autostart if we are the active turn player.
	if IsCloudInProgress() and Network.IsCloudTurnPlayer() then
		if(not IsLaunchCountdownActive()) then
			-- Reset global blocking variables so the ready button is not dirty from previous sessions.
			ResetAutoStartFlags();				
			SetLocalReady(true);
			StartLaunchCountdown();
		end
	-- Check to see if we should start/stop the multiplayer game.
	
	elseif(not Network.IsPlayerHotJoining(Network.GetLocalPlayerID())
		
		and not IsCloudInProgressAndNotTurn()
		and not Network.IsCloudLaunching()) then -- We should not autostart if we are already launching into a PlayByCloud match.
		local startCountdown = true;
				
		-- Reset global blocking variables because we're going to recalculate them.
		ResetAutoStartFlags();

		-- Count players and check to see if a human player isn't ready.
		local totalPlayers = 0;
		local totalHumans = 0;
		local noDupLeaders = GameConfiguration.GetValue("NO_DUPLICATE_LEADERS");
		local player_ids = GameConfiguration.GetMultiplayerPlayerIDs();		
		
		for i, iPlayer in ipairs(player_ids) do	
			local curPlayerConfig = PlayerConfigurations[iPlayer];
			local curSlotStatus = curPlayerConfig:GetSlotStatus();
			local curIsFullCiv = curPlayerConfig:GetCivilizationLevelTypeID() == CivilizationLevelTypes.CIVILIZATION_LEVEL_FULL_CIV;
			
			if((curSlotStatus == SlotStatus.SS_TAKEN -- Human civ
				or Network.IsPlayerConnected(iPlayer))	-- network connection on this slot, could be an multiplayer autoplay.
				and (curPlayerConfig:IsAlive() or curSlotStatus == SlotStatus.SS_OBSERVER)) then -- Dead players do not block launch countdown.  Observers count as dead but should still block launch to be consistent. 
				if(not curPlayerConfig:GetReady()) then
					print("CheckGameAutoStart: Can't start game because player ".. iPlayer .. " isn't ready");
					startCountdown = false;
					g_everyoneReady = false;
				-- Players are set to ModRrady when have they successfully downloaded and configured all the mods required for this game.
				-- See Network::Manager::OnFinishedGameplayContentConfigure()
				elseif(not curPlayerConfig:GetModReady()) then
					print("CheckGameAutoStart: Can't start game because player ".. iPlayer .. " isn't mod ready");
					startCountdown = false;
					g_everyoneModReady = false;
				end
			
			elseif(curPlayerConfig:IsHumanRequired() == true 
				and GameConfiguration.GetGameState() == GameStateTypes.GAMESTATE_PREGAME) then
				-- If this is a new game, all human required slots need to be filled by a human.  
				-- NOTE: Human required slots do not need to be filled when loading a save.
				startCountdown = false;
				g_humanRequiredFilled = false;
			end
			
			if( (curSlotStatus == SlotStatus.SS_COMPUTER or curSlotStatus == SlotStatus.SS_TAKEN) and curIsFullCiv ) then
				totalPlayers = totalPlayers + 1;
				
				if(curSlotStatus == SlotStatus.SS_TAKEN) then
					totalHumans = totalHumans + 1;
				end

				if(iPlayer >= g_currentMaxPlayers) then
					-- A player is occupying an invalid player slot for this map size.
					print("CheckGameAutoStart: Can't start game because player " .. iPlayer .. " is in an invalid slot for this map size.");
					startCountdown = false;
					g_badPlayerForMapSize = true;
				end

				-- Check for selection error (ownership rules, duplicate leaders, etc)
				local err = GetPlayerParameterError(iPlayer)
				if(err) then
					
					startCountdown = false;
					if(noDupLeaders and err.Id == "InvalidDomainValue" and err.Reason == "LOC_SETUP_ERROR_NO_DUPLICATE_LEADERS") then
						g_duplicateLeaders = true;
					end
				end
			end
		end
		
		-- Check player count
		if(totalPlayers < g_currentMinPlayers) then
			print("CheckGameAutoStart: Can't start game because there are not enough players. " .. totalPlayers .. "/" .. g_currentMinPlayers);
			startCountdown = false;
			g_notEnoughPlayers = true;
		end

		if(GameConfiguration.IsPlayByCloud() 
			and GameConfiguration.GetGameState() ~= GameStateTypes.GAMESTATE_LAUNCHED
			and totalHumans < 2) then
			print("CheckGameAutoStart: Can't start game because two human players are required for PlayByCloud. totalHumans: " .. totalHumans);
			startCountdown = false;
			g_pbcMinHumanCheck = false;
		end

		if(GameConfiguration.IsMatchMaking()
			and GameConfiguration.GetGameState() ~= GameStateTypes.GAMESTATE_LAUNCHED
			and totalHumans < totalPlayers
			and (IsReadyCountdownActive() or IsWaitForPlayersCountdownActive())) then
			print("CheckGameAutoStart: Can't start game because we are still in the Ready/Matchmaking Countdown and we do not have a full game yet. totalHumans: " .. totalHumans .. ", totalPlayers: " .. tostring(totalPlayers));
			startCountdown = false;
			g_matchMakeFullGameCheck = false;
		end

		if(not Network.IsEveryoneConnected()) then
			print("CheckGameAutoStart: Can't start game because players are joining the game.");
			startCountdown = false;
			g_everyoneConnected = false;
		end

		if(not m_bTeamsValid) then
			print("CheckGameAutoStart: Can't start game because all civs are on the same team!");
			startCountdown = false;
		end

		-- Only the host may launch a PlayByCloud match that is not already in progress.
		if(GameConfiguration.IsPlayByCloud()
			and GameConfiguration.GetGameState() ~= GameStateTypes.GAMESTATE_LAUNCHED
			and not Network.IsGameHost()) then
			print("CheckGameAutoStart: Can't start game because remote client can't launch new PlayByCloud game.");
			startCountdown = false;
			g_pbcNewGameCheck = false;
		end

	
		-- Hotseat bypasses the countdown system.
		if not GameConfiguration.IsHotseat() then
			if(startCountdown) then
				-- Everyone has readied up and we can start.
				StartLaunchCountdown();
			else
				-- We can't autostart now, stop the countdown if we started it earlier.
				if(IsLaunchCountdownActive()) then
					StopCountdown();
				end
			end
		end
	end
	UpdateReadyButton();
end

function ResetAutoStartFlags()
	g_everyoneReady = true;
	g_everyoneConnected = true;
	g_badPlayerForMapSize = false;
	g_notEnoughPlayers = false;
	g_everyoneModReady = true;
	g_duplicateLeaders = false;
	g_humanRequiredFilled = true;
	g_pbcNewGameCheck = true;
	g_pbcMinHumanCheck = true;
	g_matchMakeFullGameCheck = true;
end

-------------------------------------------------
-- Leave the Game
-------------------------------------------------
function CheckLeaveGame()
	-- Leave the network session if we're in a state where the staging room should be triggering the exit.
	if not ContextPtr:IsHidden()	-- If the screen is not visible, this exit might be part of a general UI state change (like Multiplayer_ExitShell)
									-- and should not trigger a game exit.
		and Network.IsInSession()	-- Still in a network session.
		and not Network.IsInGameStartedState() then -- Don't trigger leave game if we're being used as an ingame screen. Worldview is handling this instead.
		print("StagingRoom::CheckLeaveGame() leaving the network session.");
		Network.LeaveGame();
	end
end

-- ===========================================================================
--	LUA Event
-- ===========================================================================
function OnHandleExitRequest()
	print("Staging Room -Handle Exit Request");

	CheckLeaveGame();
	Controls.CountdownTimerAnim:ClearAnimCallback();
	
	-- Force close all popups because they are modal and will remain visible even if the screen is hidden
	for _, playerEntry:table in ipairs(g_PlayerEntries) do
		playerEntry.SlotTypePulldown:ForceClose();
		playerEntry.AlternateSlotTypePulldown:ForceClose();
		playerEntry.TeamPullDown:ForceClose();
		playerEntry.PlayerPullDown:ForceClose();
		playerEntry.HandicapPullDown:ForceClose();
	end

	-- Destroy setup parameters.
	HideGameSetup(function()
		-- Reset instances here.
		m_gameSetupParameterIM:ResetInstances();
	end);
	
	-- Destroy individual player parameters.
	ReleasePlayerParameters();

	-- Exit directly to Lobby
	ResetChat();
	UIManager:DequeuePopup( ContextPtr );
end

function GetPlayerEntry(playerID)
	local playerEntry = g_PlayerEntries[playerID];
	if(playerEntry == nil) then
		-- need to create the player entry.
		--print("creating playerEntry for player " .. tostring(playerID));
		playerEntry = m_playersIM:GetInstance();

		--SetupTeamPulldown( playerID, playerEntry.TeamPullDown );

		local civTooltipData : table = {
			InfoStack			= m_CivTooltip.InfoStack,
			InfoScrollPanel		= m_CivTooltip.InfoScrollPanel;
			CivToolTipSlide		= m_CivTooltip.CivToolTipSlide;
			CivToolTipAlpha		= m_CivTooltip.CivToolTipAlpha;
			UniqueIconIM		= m_CivTooltip.UniqueIconIM;		
			HeaderIconIM		= m_CivTooltip.HeaderIconIM;
			CivHeaderIconIM		= m_CivTooltip.CivHeaderIconIM;
			HeaderIM			= m_CivTooltip.HeaderIM;
			HasLeaderPlacard	= false;
		};

		SetupSplitLeaderPulldown(playerID, playerEntry,"PlayerPullDown",nil,nil,civTooltipData);
		SetupTeamPulldown(playerID, playerEntry.TeamPullDown);
		SetupHandicapPulldown(playerID, playerEntry.HandicapPullDown);

		--playerEntry.PlayerCard:RegisterCallback( Mouse.eLClick, OnSwapButton );
		--playerEntry.PlayerCard:SetVoid1(playerID);
		playerEntry.KickButton:RegisterCallback( Mouse.eLClick, OnKickButton );
		playerEntry.KickButton:SetVoid1(playerID);
		playerEntry.AddPlayerButton:RegisterCallback( Mouse.eLClick, OnAddPlayer );
		playerEntry.AddPlayerButton:SetVoid1(playerID);
		--[[ Prototype Mod Status Progress Bars
		playerEntry.PlayerModProgressStack:SetHide(true);
		--]]
		playerEntry.ReadyImage:RegisterCallback( Mouse.eLClick, OnPlayerEntryReady );
		playerEntry.ReadyImage:SetVoid1(playerID);

		g_PlayerEntries[playerID] = playerEntry;
		g_PlayerRootToPlayerID[tostring(playerEntry.Root)] = playerID;

		-- Remember starting ready status.
		local pPlayerConfig = PlayerConfigurations[playerID];
		g_PlayerReady[playerID] = pPlayerConfig:GetReady();

		UpdatePlayerEntry(playerID);

		Controls.PlayerListStack:SortChildren(SortPlayerListStack);
	end

	return playerEntry;
end

-------------------------------------------------
-- PopulateSlotTypePulldown
-------------------------------------------------
function PopulateSlotTypePulldown( pullDown, playerID, slotTypeOptions )
	
	local instanceManager = pullDown["InstanceManager"];
	if not instanceManager then
		instanceManager = PullDownInstanceManager:new("InstanceOne", "Button", pullDown);
		pullDown["InstanceManager"] = instanceManager;
	end
	
	
	instanceManager:ResetInstances();
	pullDown.ItemCount = 0;

	for i, pair in ipairs(slotTypeOptions) do

		local pPlayerConfig = PlayerConfigurations[playerID];
		local playerSlotStatus = pPlayerConfig:GetSlotStatus();

		-- This option is a valid swap player option.
		local showSwapButton = pair.slotStatus == -1 
			and playerSlotStatus ~= SlotStatus.SS_CLOSED -- Can't swap to closed slots.
			and not pPlayerConfig:IsLocked() -- Can't swap to locked slots.
			and not GameConfiguration.IsHotseat() -- no swap option in hotseat.
			and not GameConfiguration.IsPlayByCloud() -- no swap option in PlayByCloud.
			and not GameConfiguration.IsMatchMaking() -- or when matchmaking
			and playerID ~= Network.GetLocalPlayerID();

		-- This option is a valid slot type option.
		local showSlotButton = CheckShowSlotButton(pair, playerID);

		-- Valid state for hotseatOnly flag
		local hotseatOnlyCheck = (GameConfiguration.IsHotseat() and pair.hotseatAllowed) or (not GameConfiguration.IsHotseat() and not pair.hotseatOnly);

		if(	hotseatOnlyCheck 
			and (showSwapButton or showSlotButton))then

			pullDown.ItemCount = pullDown.ItemCount + 1;
			local instance = instanceManager:GetInstance();
			local slotDisplayName = pair.name;
			local slotToolTip = pair.tooltip;

			-- In PlayByCloud OPEN slots are autoflagged as HumanRequired., morph the display name and tooltip.
			if(GameConfiguration.IsPlayByCloud() and pair.slotStatus == SlotStatus.SS_OPEN) then
				slotDisplayName = "LOC_SLOTTYPE_HUMANREQ";
				slotToolTip = "LOC_SLOTTYPE_HUMANREQ_TT";
			end

			instance.Button:LocalizeAndSetText( slotDisplayName );

			if pair.slotStatus == -1 then
				local isHuman = (playerSlotStatus == SlotStatus.SS_TAKEN);
				instance.Button:LocalizeAndSetToolTip(isHuman and "TXT_KEY_MP_SWAP_WITH_PLAYER_BUTTON_TT" or "TXT_KEY_MP_SWAP_BUTTON_TT");
			else
				instance.Button:LocalizeAndSetToolTip( slotToolTip );
			end
			instance.Button:SetVoids( playerID, i );	
		end
	end

	pullDown:CalculateInternals();
	pullDown:RegisterSelectionCallback(OnSlotType);
	pullDown:SetDisabled(pullDown.ItemCount < 1);
end

function CheckShowSlotButton(slotData :table, playerID: number)
	local pPlayerConfig :object = PlayerConfigurations[playerID];
	local playerSlotStatus :number = pPlayerConfig:GetSlotStatus();

	if(slotData.slotStatus == -1) then
		return false;
	end

	
	-- Special conditions for changing slot types for human slots in network games.
	if(playerSlotStatus == SlotStatus.SS_TAKEN and not GameConfiguration.IsHotseat()) then
		-- You can't change human player slots outside of hotseat mode.
		return false;
	end

	-- You can't switch a civilization to open/closed if the game is at the minimum player count.
	if(slotData.slotStatus == SlotStatus.SS_CLOSED or slotData.slotStatus == SlotStatus.SS_OPEN) then
		if(playerSlotStatus == SlotStatus.SS_TAKEN or playerSlotStatus == SlotStatus.SS_COMPUTER) then -- Current SlotType is a civ
			-- In PlayByCloud OPEN slots are autoflagged as HumanRequired.
			-- We allow them to bypass the minimum player count because 
			-- a human player must occupy the slot for the game to launch. 
			if(not GameConfiguration.IsPlayByCloud() or slotData.slotStatus ~= SlotStatus.SS_OPEN) then
				if(GameConfiguration.GetParticipatingPlayerCount() <= g_currentMinPlayers)	 then
					return false;				
				end
			end
		end
	end

	-- Can't change the slot type of locked player slots.
	if(pPlayerConfig:IsLocked()) then
		return false;
	end

	-- Can't change slot type in matchmaded games. 
	if(GameConfiguration.IsMatchMaking()) then
		return false;
	end

	-- Only the host can change non-local slots.
	if(not Network.IsGameHost() and playerID ~= Network.GetLocalPlayerID()) then
		return false;
	end

	-- Can normally only change slot types before the game has started unless this is a option that can be changed mid-game in hotseat.
	if(GameConfiguration.GetGameState() ~= GameStateTypes.GAMESTATE_PREGAME) then
		if(not slotData.hotseatInProgress or not GameConfiguration.IsHotseat()) then
			return false;
		end
	end

	return true;
end

-------------------------------------------------
-- Team Scripting
-------------------------------------------------
function GetTeamCounts( teamCountTable :table )
	for playerID, teamID in pairs(g_cachedTeams) do
		if(teamCountTable[teamID] == nil) then
			teamCountTable[teamID] = 1;
		else
			teamCountTable[teamID] = teamCountTable[teamID] + 1;
		end
	end
end

function AddTeamPulldownEntry( playerID:number, pullDown:table, instanceManager:table, teamID:number, teamName:string )
	
	local instance = instanceManager:GetInstance();
	
	if teamID >= 0 then
		local teamIconName:string = TEAM_ICON_PREFIX .. tostring(teamID);
		instance.ButtonImage:SetSizeVal(TEAM_ICON_SIZE, TEAM_ICON_SIZE);
		instance.ButtonImage:SetIcon(teamIconName, TEAM_ICON_SIZE);
		instance.ButtonImage:SetColor(GetTeamColor(teamID));
	end

	instance.Button:SetVoids( playerID, teamID );
end

function SetupTeamPulldown( playerID:number, pullDown:table )

	local instanceManager = pullDown["InstanceManager"];
	if not instanceManager then
		instanceManager = PullDownInstanceManager:new("InstanceOne", "Button", pullDown);
		pullDown["InstanceManager"] = instanceManager;
	end
	instanceManager:ResetInstances();

	local teamCounts = {};
	GetTeamCounts(teamCounts);

	local pulldownEntries = {};
	local noTeams = GameConfiguration.GetValue("NO_TEAMS");

	-- Always add "None" entry
	local newPulldownEntry:table = {};
	newPulldownEntry.teamID = -1;
	newPulldownEntry.teamName = GameConfiguration.GetTeamName(-1);
	table.insert(pulldownEntries, newPulldownEntry);

	if(not noTeams) then
		for teamID, playerCount in pairs(teamCounts) do
			if teamID ~= -1 then
				newPulldownEntry = {};
				newPulldownEntry.teamID = teamID;
				newPulldownEntry.teamName = GameConfiguration.GetTeamName(teamID);
				table.insert(pulldownEntries, newPulldownEntry);
			end
		end

		-- Add an empty team slot so players can join/create a new team
		local newTeamID :number = 0;
		while(teamCounts[newTeamID] ~= nil) do
			newTeamID = newTeamID + 1;
		end
		local newTeamName : string = tostring(newTeamID);
		newPulldownEntry = {};
		newPulldownEntry.teamID = newTeamID;
		newPulldownEntry.teamName = newTeamName;
		table.insert(pulldownEntries, newPulldownEntry);
	end

	table.sort(pulldownEntries, function(a, b) return a.teamID < b.teamID; end);

	for pullID, curPulldownEntry in ipairs(pulldownEntries) do
		AddTeamPulldownEntry(playerID, pullDown, instanceManager, curPulldownEntry.teamID, curPulldownEntry.teamName);
	end

	pullDown:CalculateInternals();
	pullDown:RegisterSelectionCallback( OnTeamPull );
end

function RebuildTeamPulldowns()
	for playerID, playerEntry in pairs( g_PlayerEntries ) do
		SetupTeamPulldown(playerID, playerEntry.TeamPullDown);
	end
end

function UpdateTeamList(updateOpenEmptyTeam)
	if(updateOpenEmptyTeam) then
		-- Regenerate the team pulldowns to show at least one empty team option so players can create new teams.
		RebuildTeamPulldowns();
	end

	CheckTeamsValid(); -- Check to see if the teams are valid for game start.
	CheckGameAutoStart();

	
	
	Controls.PlayerListStack:CalculateSize();
	Controls.PlayersScrollPanel:CalculateSize();
	Controls.HotseatDeco:SetHide(not GameConfiguration.IsHotseat());
end

-------------------------------------------------
-- UpdatePlayerEntry
-------------------------------------------------
function UpdateAllPlayerEntries()
	for playerID, playerEntry in pairs( g_PlayerEntries ) do
		 UpdatePlayerEntry(playerID);
	end
end

-- Update the disabled state of the slot type pulldown for all players.
function UpdateAllPlayerEntries_SlotTypeDisabled()
	for playerID, playerEntry in pairs( g_PlayerEntries ) do
		 UpdatePlayerEntry_SlotTypeDisabled(playerID);
	end
end

-- Update the disabled state of the slot type pulldown for this player.
function UpdatePlayerEntry_SlotTypeDisabled(playerID)
	local localPlayerID = Network.GetLocalPlayerID();
	local localPlayerConfig = PlayerConfigurations[localPlayerID];
	local playerEntry = g_PlayerEntries[playerID];
	if(playerEntry ~= nil) then

		-- Disable the pulldown if there are no items in it.
		local itemCount = playerEntry.SlotTypePulldown.ItemCount or 0;

		-- The slot type pulldown handles user access permissions internally (See PopulateSlotTypePulldown()).  
		-- However, we need to disable the pulldown entirely if the local player has readied up.
		local bCanChangeSlotType:boolean = not localPlayerConfig:GetReady() 
											and itemCount > 0; -- No available slot type options.

		playerEntry.AlternateSlotTypePulldown:SetDisabled(not bCanChangeSlotType);
		playerEntry.SlotTypePulldown:SetDisabled(not bCanChangeSlotType);
	end
end

function UpdatePlayerEntry(playerID)
	local playerEntry = g_PlayerEntries[playerID];
	if(playerEntry ~= nil) then
		local localPlayerID = Network.GetLocalPlayerID();
		local localPlayerConfig = PlayerConfigurations[localPlayerID];
		local pPlayerConfig = PlayerConfigurations[playerID];
		local slotStatus = pPlayerConfig:GetSlotStatus();
		local isMinorCiv = pPlayerConfig:GetCivilizationLevelTypeID() ~= CivilizationLevelTypes.CIVILIZATION_LEVEL_FULL_CIV;
		local isAlive = pPlayerConfig:IsAlive();
		local isActiveSlot = not isMinorCiv 
			and (slotStatus ~= SlotStatus.SS_CLOSED) 
			and (slotStatus ~= SlotStatus.SS_OPEN) 
			and (slotStatus ~= SlotStatus.SS_OBSERVER)
			-- In PlayByCloud, the local player still gets an active slot even if they are dead.  We do this so that players
			--		can rejoin the match to see the end game screen,
			and (isAlive or (GameConfiguration.IsPlayByCloud() and playerID == localPlayerID));
		local isHotSeat:boolean = GameConfiguration.IsHotseat();
		
		-- Has this game aleady been started?  Hot joining or loading a save game.
		local gameInProgress:boolean = GameConfiguration.GetGameState() ~= GameStateTypes.GAMESTATE_PREGAME;

		-- NOTE: UpdatePlayerEntry() currently only has control over the team player attribute.  Everything else is controlled by 
		--		PlayerConfigurationValuesToUI() and the PlayerSetupLogic.  See CheckExternalEnabled().
		-- Can the local player change this slot's attributes (handicap; civ, etc) at this time?
		local bCanChangePlayerValues = not pPlayerConfig:GetReady()  -- Can't change a slot once that player is ready.
										and not gameInProgress -- Can't change player values once the game has been started.
										and not pPlayerConfig:IsLocked() -- Can't change the values of locked players.
										and (playerID == localPlayerID		-- You can change yourself.
											-- Game host can alter all the non-human slots if they are not ready.
											or (slotStatus ~= SlotStatus.SS_TAKEN and Network.IsGameHost() and not localPlayerConfig:GetReady())
											-- The player has permission to change everything in hotseat.
											or isHotSeat);
		

			
		local isKickable:boolean = Network.IsGameHost()			-- Only the game host may kick
			and (slotStatus == SlotStatus.SS_TAKEN or slotStatus == SlotStatus.SS_OBSERVER)
			and playerID ~= localPlayerID			-- Can't kick yourself
			and not isHotSeat;	-- Can't kick in hotseat, players use the slot type pulldowns instead.

		-- Show player card for human players only during online matches
		local hidePlayerCard:boolean = isHotSeat or slotStatus ~= SlotStatus.SS_TAKEN;
		local showHotseatEdit:boolean = isHotSeat and slotStatus == SlotStatus.SS_TAKEN;
		playerEntry.SlotTypePulldown:SetHide(hidePlayerCard);
		playerEntry.HotseatEditButton:SetHide(not showHotseatEdit);
		playerEntry.AlternateEditButton:SetHide(not hidePlayerCard);
		playerEntry.AlternateSlotTypePulldown:SetHide(not hidePlayerCard);


		local statusText:string = "";
		if slotStatus == SlotStatus.SS_TAKEN then
			local hostID:number = Network.GetGameHostPlayerID();
			statusText = Locale.Lookup(playerID == hostID and "LOC_SLOTLABEL_HOST" or "LOC_SLOTLABEL_PLAYER");
		elseif slotStatus == SlotStatus.SS_COMPUTER then
			statusText = Locale.Lookup("LOC_SLOTLABEL_COMPUTER");
		elseif slotStatus == SlotStatus.SS_OBSERVER then
			local hostID:number = Network.GetGameHostPlayerID();
			statusText = Locale.Lookup(playerID == hostID and "LOC_SLOTLABEL_OBSERVER_HOST" or "LOC_SLOTLABEL_OBSERVER");
		end
		playerEntry.PlayerStatus:SetText(statusText);
		playerEntry.AlternateStatus:SetText(statusText);

		-- Update cached ready status and play sound if player is newly ready.
		if slotStatus == SlotStatus.SS_TAKEN or slotStatus == SlotStatus.SS_OBSERVER then
			local isReady:boolean = pPlayerConfig:GetReady();
			if(isReady ~= g_PlayerReady[playerID]) then
				g_PlayerReady[playerID] = isReady;
				if(isReady == true) then
					UI.PlaySound("Play_MP_Player_Ready");
				end
			end
		end

		-- Update ready icon
		local showStatusLabel = not isHotSeat and slotStatus ~= SlotStatus.SS_OPEN;
		if not isHotSeat then
			if g_PlayerReady[playerID] or slotStatus == SlotStatus.SS_COMPUTER then
				playerEntry.ReadyImage:SetTextureOffsetVal(0,136);
			else
				playerEntry.ReadyImage:SetTextureOffsetVal(0,0);
			end

			-- Update status string
			local statusString = NotReadyStatusStr;
			local statusTTString = "";
			if(slotStatus == SlotStatus.SS_TAKEN 
				and not pPlayerConfig:GetModReady() 
				and g_PlayerModStatus[playerID] ~= nil 
				and g_PlayerModStatus[playerID] ~= "") then
				statusString = g_PlayerModStatus[playerID];
			elseif(playerID >= g_currentMaxPlayers) then
				-- Player is invalid slot for this map size.
				statusString = BadMapSizeSlotStatusStr;
				statusTTString = BadMapSizeSlotStatusStrTT;
			elseif(curSlotStatus == SlotStatus.SS_OPEN
				and pPlayerConfig:IsHumanRequired() == true 
				and GameConfiguration.GetGameState() == GameStateTypes.GAMESTATE_PREGAME) then
				-- Empty human required slot
				statusString = EmptyHumanRequiredSlotStatusStr;
				statusTTString = EmptyHumanRequiredSlotStatusStrTT;
				showStatusLabel = true;
			elseif(g_PlayerReady[playerID] or slotStatus == SlotStatus.SS_COMPUTER) then
				statusString = ReadyStatusStr;
			end

			-- Check to see if we should warning that this player is above MAX_SUPPORTED_PLAYERS.
			local playersBeforeUs = 0;
			for iLoopPlayer = 0, playerID-1, 1 do	
				local loopPlayerConfig = PlayerConfigurations[iLoopPlayer];
				local loopSlotStatus = loopPlayerConfig:GetSlotStatus();
				local loopIsFullCiv = loopPlayerConfig:GetCivilizationLevelTypeID() == CivilizationLevelTypes.CIVILIZATION_LEVEL_FULL_CIV;
				if( (loopSlotStatus == SlotStatus.SS_COMPUTER or loopSlotStatus == SlotStatus.SS_TAKEN) and loopIsFullCiv ) then
					playersBeforeUs = playersBeforeUs + 1;
				end
			end
			if playersBeforeUs >= MAX_SUPPORTED_PLAYERS then
				statusString = statusString .. "[NEWLINE][COLOR_Red]" .. UnsupportedText;
				if statusTTString ~= "" then
					statusTTString = statusTTString .. "[NEWLINE][COLOR_Red]" .. UnsupportedTextTT;
				else
					statusTTString = "[COLOR_Red]" .. UnsupportedTextTT;
				end
			end

			local err = GetPlayerParameterError(playerID)
			if(err) then
				local reason = err.Reason or "LOC_SETUP_PLAYER_PARAMETER_ERROR";
				statusString = statusString .. "[NEWLINE][COLOR_Red]" .. Locale.Lookup(reason) .. "[ENDCOLOR]";
			end

			playerEntry.StatusLabel:SetText(statusString);
			playerEntry.StatusLabel:SetToolTipString(statusTTString);
		end
		playerEntry.StatusLabel:SetHide(not showStatusLabel);

		if playerID == localPlayerID then
			playerEntry.YouIndicatorLine:SetHide(false);
		else
			playerEntry.YouIndicatorLine:SetHide(true);
		end

		playerEntry.AddPlayerButton:SetHide(true);
		-- Available actions vary if the slot has an active player in it
		if(isActiveSlot) then
			playerEntry.Root:SetHide(false);
			playerEntry.PlayerPullDown:SetHide(false);
			playerEntry.ReadyImage:SetHide(isHotSeat);
			playerEntry.TeamPullDown:SetHide(false);
			playerEntry.HandicapPullDown:SetHide(false);
			playerEntry.KickButton:SetHide(not isKickable);
		else
			if(playerID >= g_currentMaxPlayers) then
				-- inactive slot is invalid for the current map size, hide it.
				playerEntry.Root:SetHide(true);
			elseif slotStatus == SlotStatus.SS_CLOSED then
				
				if (m_iFirstClosedSlot == -1 or m_iFirstClosedSlot == playerID) 
				and Network.IsGameHost() 
				and not localPlayerConfig:GetReady()			-- Hide when the host is ready (to be consistent with the player slot behavior)
				and not gameInProgress 
				and not IsLaunchCountdownActive()				-- Don't show Add Player button while in the launch countdown.
				and not GameConfiguration.IsMatchMaking() then	-- Players can't change number of slots when matchmaking.
					m_iFirstClosedSlot = playerID;
					playerEntry.AddPlayerButton:SetHide(false);
					playerEntry.Root:SetHide(false);
				else
					playerEntry.Root:SetHide(true);
				end
			elseif slotStatus == SlotStatus.SS_OBSERVER and Network.IsPlayerConnected(playerID) then
				playerEntry.Root:SetHide(false);
				playerEntry.PlayerPullDown:SetHide(true);
				playerEntry.TeamPullDown:SetHide(true);
				playerEntry.ReadyImage:SetHide(false);
				playerEntry.HandicapPullDown:SetHide(true);
				playerEntry.KickButton:SetHide(not isKickable);
			else 
				if(gameInProgress
					-- Explicitedly always hide city states.  
					-- In PlayByCloud, the host uploads the player configuration data for city states after the gamecore resolution for new games,
					-- but this happens prior to setting the gamestate to launched in the save file during the first end turn commit.
					or (slotStatus == SlotStatus.SS_COMPUTER and isMinorCiv)) then
					-- Hide inactive slots for games in progress
					playerEntry.Root:SetHide(true);
				else
					-- Inactive slots are visible in the pregame.
					playerEntry.Root:SetHide(false);
					playerEntry.PlayerPullDown:SetHide(true);
					playerEntry.TeamPullDown:SetHide(true);
					playerEntry.ReadyImage:SetHide(true);
					playerEntry.HandicapPullDown:SetHide(true);
					playerEntry.KickButton:SetHide(true);
				end
			end
		end

		--[[ Prototype Mod Status Progress Bars
		-- Hide the player's mod progress if they are mod ready.
		-- This is how the mod progress is hidden once mod downloads are completed.
		if(pPlayerConfig:GetModReady()) then
			playerEntry.PlayerModProgressStack:SetHide(true);
		end
		--]]

		PopulateSlotTypePulldown( playerEntry.AlternateSlotTypePulldown, playerID, g_slotTypeData );
		PopulateSlotTypePulldown(playerEntry.SlotTypePulldown, playerID, g_slotTypeData);
		UpdatePlayerEntry_SlotTypeDisabled(playerID);

		if(isActiveSlot) then
			PlayerConfigurationValuesToUI(playerID); -- Update player configuration pulldown values.

            local parameters = GetPlayerParameters(playerID);
            if(parameters == nil) then
                parameters = CreatePlayerParameters(playerID);
            end

			if parameters.Parameters ~= nil then
				local parameter = parameters.Parameters["PlayerLeader"];

				local leaderType = parameter.Value.Value;
				local icons = GetPlayerIcons(parameter.Value.Domain, parameter.Value.Value);


				local playerColor = icons.PlayerColor;
				local civIcon = playerEntry["CivIcon"];
                local civIconBG = playerEntry["IconBG"];
                local colorControl = playerEntry["ColorPullDown"];
                local civWarnIcon = playerEntry["WarnIcon"];
				colorControl:SetHide(false);	

				civIconBG:SetHide(true);
                civIcon:SetHide(true);
                if (parameter.Value.Value ~= "RANDOM" and parameter.Value.Value ~= "RANDOM_POOL1" and parameter.Value.Value ~= "RANDOM_POOL2") then
                    local colorAlternate = parameters.Parameters["PlayerColorAlternate"] or 0;
        			local backColor, frontColor = UI.GetPlayerColorValues(playerColor, colorAlternate.Value);
					
					if(backColor and frontColor and backColor ~= 0 and frontColor ~= 0) then
						civIcon:SetIcon(icons.CivIcon);
        				civIcon:SetColor(frontColor);
						civIconBG:SetColor(backColor);

						civIconBG:SetHide(false);
						civIcon:SetHide(false);
	        				
						local itemCount = 0;
						if bCanChangePlayerValues then
							local colorInstanceManager = colorControl["InstanceManager"];
							if not colorInstanceManager then
								colorInstanceManager = PullDownInstanceManager:new( "InstanceOne", "Button", colorControl );
								colorControl["InstanceManager"] = colorInstanceManager;
							end

							colorInstanceManager:ResetInstances();
							for j=0, 3, 1 do					
								local backColor, frontColor = UI.GetPlayerColorValues(playerColor, j);
								if(backColor and frontColor and backColor ~= 0 and frontColor ~= 0) then
									local colorEntry = colorInstanceManager:GetInstance();
									itemCount = itemCount + 1;
	
									colorEntry.CivIcon:SetIcon(icons.CivIcon);
									colorEntry.CivIcon:SetColor(frontColor);
									colorEntry.IconBG:SetColor(backColor);
									colorEntry.Button:SetToolTipString(nil);
									colorEntry.Button:RegisterCallback(Mouse.eLClick, function()
										
										-- Update collision check color
										local primary, secondary = UI.GetPlayerColorValues(playerColor, j);
										m_teamColors[playerID] = {primary, secondary}

										local colorParameter = parameters.Parameters["PlayerColorAlternate"];
										parameters:SetParameterValue(colorParameter, j);
									end);
								end           
							end
						end

						colorControl:CalculateInternals();
						colorControl:SetDisabled(not bCanChangePlayerValues or itemCount == 0 or itemCount == 1);
					
						-- update what color we are for collision checks
						m_teamColors[playerID] = { backColor, frontColor};

						local myTeam = m_teamColors[playerID];
                        local bShowWarning = false;
						for k,v in pairs(m_teamColors) do
							if(k ~= playerID) then
								 if( myTeam and v and UI.ArePlayerColorsConflicting( v, myTeam ) ) then
                                    bShowWarning = true;
                                end
							end
						end
                        civWarnIcon:SetHide(not bShowWarning);
    					if bShowWarning == true then
    						civWarnIcon:LocalizeAndSetToolTip("LOC_SETUP_PLAYER_COLOR_COLLISION");
    					else
    						civWarnIcon:SetToolTipString(nil);
    					end
					end
                end
			end
		else
			local colorControl = playerEntry["ColorPullDown"];
			colorControl:SetHide(true);	
        end
		
		-- TeamPullDown is not controlled by PlayerConfigurationValuesToUI and is set manually.
		local noTeams = GameConfiguration.GetValue("NO_TEAMS");
		playerEntry.TeamPullDown:SetDisabled(not bCanChangePlayerValues or noTeams);
		local teamID:number = pPlayerConfig:GetTeam();
		-- If the game is in progress and this player is on a team by themselves, display it as if they are on no team.
		-- We do this to be consistent with the ingame UI.
		if(gameInProgress and GameConfiguration.GetTeamPlayerCount(teamID) <= 1) then
			teamID = TeamTypes.NO_TEAM;
		end
		if teamID >= 0 then
			-- Adjust the texture offset based on the selected team
			local teamIconName:string = TEAM_ICON_PREFIX .. tostring(teamID);
			playerEntry.ButtonSelectedTeam:SetSizeVal(TEAM_ICON_SIZE, TEAM_ICON_SIZE);
			playerEntry.ButtonSelectedTeam:SetIcon(teamIconName, TEAM_ICON_SIZE);
			playerEntry.ButtonSelectedTeam:SetColor(GetTeamColor(teamID));
			playerEntry.ButtonSelectedTeam:SetHide(false);
			playerEntry.ButtonNoTeam:SetHide(true);
		else
			playerEntry.ButtonSelectedTeam:SetHide(true);
			playerEntry.ButtonNoTeam:SetHide(false);
		end

		-- NOTE: order matters. you MUST call this after all other setup and before resize as hotseat will hide/show manipulate elements specific to that mode.
		if(isHotSeat) then
			UpdatePlayerEntry_Hotseat(playerID);		
		end

		-- Slot name toggles based on slotstatus.
		-- Update AFTER hotseat checks as hot seat checks may upate nickname.
		playerEntry.PlayerName:LocalizeAndSetText(pPlayerConfig:GetSlotName()); 
		playerEntry.AlternateName:LocalizeAndSetText(pPlayerConfig:GetSlotName()); 

		-- Update online pip status for human slots.
		if(pPlayerConfig:IsHuman()) then
			local iconStr = onlineIconStr;
			if(not Network.IsPlayerConnected(playerID)) then
				iconStr = offlineIconStr;
			end
			playerEntry.ConnectionStatus:SetText(iconStr);
		end
		
	else
		print("PlayerEntry not found for playerID(" .. tostring(playerID) .. ").");
	end
end

function UpdatePlayerEntry_Hotseat(playerID)
	if(GameConfiguration.IsHotseat()) then
		local playerEntry = g_PlayerEntries[playerID];
		if(playerEntry ~= nil) then
			local localPlayerID = Network.GetLocalPlayerID();
			local pLocalPlayerConfig = PlayerConfigurations[localPlayerID];
			local pPlayerConfig = PlayerConfigurations[playerID];
			local slotStatus = pPlayerConfig:GetSlotStatus();

			g_hotseatNumHumanPlayers = 0;
			g_hotseatNumAIPlayers = 0;
			local player_ids = GameConfiguration.GetMultiplayerPlayerIDs();
			for i, iPlayer in ipairs(player_ids) do	
				local curPlayerConfig = PlayerConfigurations[iPlayer];
				local curSlotStatus = curPlayerConfig:GetSlotStatus();
				
				print("UpdatePlayerEntry_Hotseat: playerID=" .. iPlayer .. ", SlotStatus=" .. curSlotStatus);	
				if(curSlotStatus == SlotStatus.SS_TAKEN) then 
					g_hotseatNumHumanPlayers = g_hotseatNumHumanPlayers + 1;
				elseif(curSlotStatus == SlotStatus.SS_COMPUTER) then
					g_hotseatNumAIPlayers = g_hotseatNumAIPlayers + 1;
				end
			end
			print("UpdatePlayerEntry_Hotseat: g_hotseatNumHumanPlayers=" .. g_hotseatNumHumanPlayers .. ", g_hotseatNumAIPlayers=" .. g_hotseatNumAIPlayers);	

			if(slotStatus == SlotStatus.SS_TAKEN) then
				local nickName = pPlayerConfig:GetNickName();
				if(nickName == nil or #nickName == 0) then
					pPlayerConfig:SetHotseatName(DefaultHotseatPlayerName .. " " .. g_hotseatNumHumanPlayers);
				end
			end

			if(not g_isBuildingPlayerList and GameConfiguration.IsHotseat() and (slotStatus == SlotStatus.SS_TAKEN or slotStatus == SlotStatus.SS_COMPUTER)) then
				UpdateAllDefaultPlayerNames();
			end

			playerEntry.KickButton:SetHide(true);
			--[[ Prototype Mod Status Progress Bars
			playerEntry.PlayerModProgressStack:SetHide(true);
			--]]

			playerEntry.HotseatEditButton:RegisterCallback(Mouse.eLClick, function()
				UIManager:PushModal(Controls.EditHotseatPlayer, true);
				LuaEvents.StagingRoom_SetPlayerID(playerID);
			end);
		end
	end
end

-- ===========================================================================
function UpdateAllDefaultPlayerNames()
	local humanDefaultPlayerNameConfigs :table = {};
	local humanDefaultPlayerNameEntries :table = {};
	local numHumanPlayers :number = 0;
	local kPlayerIDs :table = GameConfiguration.GetMultiplayerPlayerIDs();

	for i, iPlayer in ipairs(kPlayerIDs) do
		local pCurPlayerConfig	:object = PlayerConfigurations[iPlayer];
		local pCurPlayerEntry	:object = g_PlayerEntries[iPlayer];
		local slotStatus		:number = pCurPlayerConfig:GetSlotStatus();
		
		-- Case where multiple times on one machine it appeared a config could exist
		-- for a taken player but no player object?
		local isSafeToReferencePlayer:boolean = true;
		if pCurPlayerEntry==nil and (slotStatus == SlotStatus.SS_TAKEN) then
			isSafeToReferencePlayer = false;
			UI.DataError("Mismatch player config/entry for player #"..tostring(iPlayer)..". SlotStatus: "..tostring(slotStatus));
		end
		
		if isSafeToReferencePlayer and (slotStatus == SlotStatus.SS_TAKEN) then
			local strRegEx = "^" .. DefaultHotseatPlayerName .. " %d+$"
			print(strRegEx .. " " .. pCurPlayerConfig:GetNickName());
			local isDefaultPlayerName = string.match(pCurPlayerConfig:GetNickName(), strRegEx);
			if(isDefaultPlayerName ~= nil) then
				humanDefaultPlayerNameConfigs[#humanDefaultPlayerNameConfigs+1] = pCurPlayerConfig;
				humanDefaultPlayerNameEntries[#humanDefaultPlayerNameEntries+1] = pCurPlayerEntry;
			end
		end
	end

	for i, v in ipairs(humanDefaultPlayerNameConfigs) do
		local playerConfig = humanDefaultPlayerNameConfigs[i];
		local playerEntry = humanDefaultPlayerNameEntries[i];
		playerConfig:SetHotseatName(DefaultHotseatPlayerName .. " " .. i);
		playerEntry.PlayerName:LocalizeAndSetText(playerConfig:GetNickName()); 
		playerEntry.AlternateName:LocalizeAndSetText(playerConfig:GetNickName());
	end

end

-------------------------------------------------
-- SortPlayerListStack
-------------------------------------------------
function SortPlayerListStack(a, b)
	-- a and b are the Root controls of the PlayerListEntry we are sorting.
	local playerIDA = g_PlayerRootToPlayerID[tostring(a)];
	local playerIDB = g_PlayerRootToPlayerID[tostring(b)];
	if(playerIDA ~= nil and playerIDB ~= nil) then
		local playerConfigA = PlayerConfigurations[playerIDA];
		local playerConfigB = PlayerConfigurations[playerIDB];

		-- push closed slots to the bottom
		if(playerConfigA:GetSlotStatus() == SlotStatus.SS_CLOSED) then
			return false;
		elseif(playerConfigB:GetSlotStatus() == SlotStatus.SS_CLOSED) then
			return true;
		end

		-- Finally, sort by playerID value.
		return playerIDA < playerIDB;
	elseif (playerIDA ~= nil and playerIDB == nil) then
		-- nil entries should be at the end of the list.
		return true;
	elseif(playerIDA == nil and playerIDB ~= nil) then
		-- nil entries should be at the end of the list.
		return false;
	else
		return tostring(a) < tostring(b);				
	end	
end

function UpdateReadyButton_Hotseat()
	if(GameConfiguration.IsHotseat()) then
		if(g_hotseatNumHumanPlayers == 0) then
			Controls.StartLabel:SetText(Locale.ToUpper(Locale.Lookup("LOC_READY_BLOCKED_HOTSEAT_NO_HUMAN_PLAYERS")));
			Controls.ReadyButton:SetText("");
			Controls.ReadyButton:LocalizeAndSetToolTip("LOC_READY_BLOCKED_HOTSEAT_NO_HUMAN_PLAYERS_TT");
			Controls.ReadyButton:SetDisabled(true);
		elseif(g_hotseatNumHumanPlayers + g_hotseatNumAIPlayers < 2) then
			Controls.StartLabel:SetText(Locale.ToUpper(Locale.Lookup("LOC_READY_BLOCKED_NOT_ENOUGH_PLAYERS")));
			Controls.ReadyButton:SetText("");
			Controls.ReadyButton:LocalizeAndSetToolTip("LOC_READY_BLOCKED_NOT_ENOUGH_PLAYERS_TT");
			Controls.ReadyButton:SetDisabled(true);
		elseif(not m_bTeamsValid) then
			Controls.StartLabel:SetText(Locale.ToUpper(Locale.Lookup("LOC_READY_BLOCKED_HOTSEAT_INVALID_TEAMS")));
			Controls.ReadyButton:SetText("");
			Controls.ReadyButton:LocalizeAndSetToolTip("LOC_READY_BLOCKED_HOTSEAT_INVALID_TEAMS_TT");
			Controls.ReadyButton:SetDisabled(true);
		elseif(g_badPlayerForMapSize) then
			Controls.StartLabel:LocalizeAndSetText("LOC_READY_BLOCKED_PLAYER_MAP_SIZE");
			Controls.ReadyButton:SetText("");
			Controls.ReadyButton:LocalizeAndSetToolTip( "LOC_READY_BLOCKED_PLAYER_MAP_SIZE_TT", g_currentMaxPlayers);
			Controls.ReadyButton:SetDisabled(true);
		elseif(g_duplicateLeaders) then
			Controls.StartLabel:SetText(Locale.ToUpper(Locale.Lookup("LOC_SETUP_ERROR_NO_DUPLICATE_LEADERS")));
			Controls.ReadyButton:SetText("");
			Controls.ReadyButton:LocalizeAndSetToolTip("LOC_SETUP_ERROR_NO_DUPLICATE_LEADERS");
			Controls.ReadyButton:SetDisabled(true);
		else
			Controls.StartLabel:SetText(Locale.ToUpper(Locale.Lookup("LOC_START_GAME")));
			Controls.ReadyButton:SetText("");
			Controls.ReadyButton:LocalizeAndSetToolTip("");
			Controls.ReadyButton:SetDisabled(false);
		end
	end
end

function UpdateReadyButton()
	local localPlayerID = Network.GetLocalPlayerID();
	local localPlayerConfig = PlayerConfigurations[localPlayerID];

	if(GameConfiguration.IsHotseat()) then
		UpdateReadyButton_Hotseat();
		return;
	end

	local localPlayerEntry = GetPlayerEntry(localPlayerID);
	local localPlayerButton = localPlayerEntry.ReadyImage;
	if(m_countdownType ~= CountdownTypes.None) then
		local startLabel :string = Locale.ToUpper(Locale.Lookup("LOC_GAMESTART_COUNTDOWN_FORMAT"));  -- Defaults to COUNTDOWN_LAUNCH
		local toolTip :string = "";
		if(IsReadyCountdownActive()) then
			startLabel = Locale.ToUpper(Locale.Lookup("LOC_READY_COUNTDOWN_FORMAT"));
			toolTip = Locale.Lookup("LOC_READY_COUNTDOWN_TT");
		elseif(IsWaitForPlayersCountdownActive()) then
			startLabel = Locale.ToUpper(Locale.Lookup("LOC_WAITING_FOR_PLAYERS_COUNTDOWN_FORMAT"));
			toolTip = Locale.Lookup("LOC_WAITING_FOR_PLAYERS_COUNTDOWN_TT");
		end

		local timeRemaining :number = GetCountdownTimeRemaining();
		local intTime :number = math.floor(timeRemaining);
		Controls.StartLabel:SetText( startLabel );
		Controls.ReadyButton:LocalizeAndSetText(  intTime );
		Controls.ReadyButton:LocalizeAndSetToolTip( toolTip );
		Controls.ReadyCheck:LocalizeAndSetToolTip( toolTip );
		localPlayerButton:LocalizeAndSetToolTip( toolTip );
	elseif(IsCloudInProgressAndNotTurn()) then
		Controls.StartLabel:SetText( Locale.ToUpper(Locale.Lookup( "LOC_START_WAITING_FOR_TURN" )));
		Controls.ReadyButton:SetText("");
		Controls.ReadyButton:LocalizeAndSetToolTip( "LOC_START_WAITING_FOR_TURN_TT" );
		Controls.ReadyCheck:LocalizeAndSetToolTip( "LOC_START_WAITING_FOR_TURN_TT" );
		localPlayerButton:LocalizeAndSetToolTip( "LOC_START_WAITING_FOR_TURN_TT" );
	elseif(not g_everyoneReady) then
		-- Local player hasn't readied up yet, just show "Ready"
		Controls.StartLabel:SetText( Locale.ToUpper(Locale.Lookup( "LOC_ARE_YOU_READY" )));
		Controls.ReadyButton:SetText("");
		Controls.ReadyButton:LocalizeAndSetToolTip( "" );
		Controls.ReadyCheck:LocalizeAndSetToolTip( "" );
		localPlayerButton:LocalizeAndSetToolTip( "" );
	-- Local player is ready, show why we're not in the countdown yet!
	elseif(not g_everyoneConnected) then
		-- Waiting for a player to finish connecting to the game.
		Controls.StartLabel:SetText( Locale.ToUpper(Locale.Lookup("LOC_READY_BLOCKED_PLAYERS_CONNECTING")));

		local waitingForJoinersTooltip : string = Locale.Lookup("LOC_READY_BLOCKED_PLAYERS_CONNECTING_TT");
		local player_ids = GameConfiguration.GetMultiplayerPlayerIDs();
		for i, iPlayer in ipairs(player_ids) do	
			local curPlayerConfig = PlayerConfigurations[iPlayer];
			local curSlotStatus = curPlayerConfig:GetSlotStatus();
			if(curSlotStatus == SlotStatus.SS_TAKEN and not Network.IsPlayerConnected(playerID)) then
				waitingForJoinersTooltip = waitingForJoinersTooltip .. "[NEWLINE]" .. "(" .. Locale.Lookup(curPlayerConfig:GetPlayerName()) .. ") ";
			end
		end
		Controls.ReadyButton:SetToolTipString( waitingForJoinersTooltip );
		Controls.ReadyCheck:SetToolTipString( waitingForJoinersTooltip );
		localPlayerButton:SetToolTipString( waitingForJoinersTooltip );
	elseif(g_notEnoughPlayers) then
		Controls.StartLabel:LocalizeAndSetText("LOC_READY_BLOCKED_NOT_ENOUGH_PLAYERS");
		Controls.ReadyButton:LocalizeAndSetToolTip( "LOC_READY_BLOCKED_NOT_ENOUGH_PLAYERS_TT");
		Controls.ReadyCheck:LocalizeAndSetToolTip( "LOC_READY_BLOCKED_NOT_ENOUGH_PLAYERS_TT");
		localPlayerButton:LocalizeAndSetToolTip( "LOC_READY_BLOCKED_NOT_ENOUGH_PLAYERS_TT");
	elseif(not m_bTeamsValid) then
		Controls.StartLabel:LocalizeAndSetText("LOC_READY_BLOCKED_TEAMS_INVALID");
		Controls.ReadyButton:LocalizeAndSetToolTip( "LOC_READY_BLOCKED_TEAMS_INVALID_TT" );
		Controls.ReadyCheck:LocalizeAndSetToolTip( "LOC_READY_BLOCKED_TEAMS_INVALID_TT" );
		localPlayerButton:LocalizeAndSetToolTip( "LOC_READY_BLOCKED_TEAMS_INVALID_TT" );
	elseif(g_badPlayerForMapSize) then
		Controls.StartLabel:LocalizeAndSetText("LOC_READY_BLOCKED_PLAYER_MAP_SIZE");
		Controls.ReadyButton:LocalizeAndSetToolTip( "LOC_READY_BLOCKED_PLAYER_MAP_SIZE_TT", g_currentMaxPlayers);
		Controls.ReadyCheck:LocalizeAndSetToolTip( "LOC_READY_BLOCKED_PLAYER_MAP_SIZE_TT", g_currentMaxPlayers);
		localPlayerButton:LocalizeAndSetToolTip( "LOC_READY_BLOCKED_PLAYER_MAP_SIZE_TT", g_currentMaxPlayers);
	elseif(not g_everyoneModReady) then
		-- A player doesn't have the mods required for this game.
		Controls.StartLabel:LocalizeAndSetText("LOC_READY_BLOCKED_PLAYERS_NOT_MOD_READY");

		local waitingForModReadyTooltip : string = Locale.Lookup("LOC_READY_BLOCKED_PLAYERS_NOT_MOD_READY");
		local player_ids = GameConfiguration.GetMultiplayerPlayerIDs();
		for i, iPlayer in ipairs(player_ids) do	
			local curPlayerConfig = PlayerConfigurations[iPlayer];
			local curSlotStatus = curPlayerConfig:GetSlotStatus();
			if(curSlotStatus == SlotStatus.SS_TAKEN and not curPlayerConfig:GetModReady()) then
				waitingForModReadyTooltip = waitingForModReadyTooltip .. "[NEWLINE]" .. "(" .. Locale.Lookup(curPlayerConfig:GetPlayerName()) .. ") ";
			end
		end
		Controls.ReadyButton:SetToolTipString( waitingForModReadyTooltip );
		Controls.ReadyCheck:SetToolTipString( waitingForModReadyTooltip );
		localPlayerButton:SetToolTipString( waitingForModReadyTooltip );
	elseif(g_duplicateLeaders) then
		Controls.StartLabel:LocalizeAndSetText("LOC_SETUP_ERROR_NO_DUPLICATE_LEADERS");
		Controls.ReadyButton:LocalizeAndSetToolTip("LOC_SETUP_ERROR_NO_DUPLICATE_LEADERS");
		Controls.ReadyCheck:LocalizeAndSetToolTip( "LOC_SETUP_ERROR_NO_DUPLICATE_LEADERS");
		localPlayerButton:LocalizeAndSetToolTip( "LOC_SETUP_ERROR_NO_DUPLICATE_LEADERS");
	elseif(not g_humanRequiredFilled) then
		Controls.StartLabel:LocalizeAndSetText("LOC_SETUP_ERROR_HUMANS_REQUIRED");
		Controls.ReadyButton:LocalizeAndSetToolTip("LOC_SETUP_ERROR_HUMANS_REQUIRED_TT");
		Controls.ReadyCheck:LocalizeAndSetToolTip( "LOC_SETUP_ERROR_HUMANS_REQUIRED_TT");
		localPlayerButton:LocalizeAndSetToolTip( "LOC_SETUP_ERROR_HUMANS_REQUIRED");
	elseif(not g_pbcNewGameCheck) then
		Controls.StartLabel:LocalizeAndSetText("LOC_SETUP_ERROR_PLAYBYCLOUD_REMOTE_READY");
		Controls.ReadyButton:LocalizeAndSetToolTip("LOC_SETUP_ERROR_PLAYBYCLOUD_REMOTE_READY_TT");
		Controls.ReadyCheck:LocalizeAndSetToolTip( "LOC_SETUP_ERROR_PLAYBYCLOUD_REMOTE_READY_TT");
		localPlayerButton:LocalizeAndSetToolTip("LOC_SETUP_ERROR_PLAYBYCLOUD_REMOTE_READY");	
	elseif(not g_pbcMinHumanCheck) then
		Controls.StartLabel:LocalizeAndSetText("LOC_READY_BLOCKED_NOT_ENOUGH_HUMANS");
		Controls.ReadyButton:LocalizeAndSetToolTip("LOC_READY_BLOCKED_NOT_ENOUGH_HUMANS_TT");
		Controls.ReadyCheck:LocalizeAndSetToolTip( "LOC_READY_BLOCKED_NOT_ENOUGH_HUMANS_TT");
		localPlayerButton:LocalizeAndSetToolTip("LOC_READY_BLOCKED_NOT_ENOUGH_HUMANS");			
	end

	local errorReason;
	local game_err = GetGameParametersError();
	if(game_err) then
		errorReason = game_err.Reason or "LOC_SETUP_PARAMETER_ERROR";
	end

	local player_ids = GameConfiguration.GetMultiplayerPlayerIDs();
	for i, iPlayer in ipairs(player_ids) do	
		-- Check for selection error (ownership rules, duplicate leaders, etc)
		local err = GetPlayerParameterError(iPlayer)
		if(err) then
			errorReason = err.Reason or "LOC_SETUP_PLAYER_PARAMETER_ERROR"
		end
	end
	-- Block ready up when there is a civ ownership issue.  
	-- We have to do this because ownership is not communicated to the host.
	if(errorReason) then
		Controls.StartLabel:SetText("[COLOR_RED]" .. Locale.Lookup(errorReason) .. "[ENDCOLOR]");
		Controls.ReadyButton:SetDisabled(true)
		Controls.ReadyCheck:SetDisabled(true);
		localPlayerButton:SetDisabled(true);
	else
		Controls.ReadyButton:SetDisabled(false);
		Controls.ReadyCheck:SetDisabled(false);
		localPlayerButton:SetDisabled(false);
	end
end

-------------------------------------------------
-- Start Game Launch Countdown
-------------------------------------------------
function StartCountdown(countdownType :string)
	if(m_countdownType == countdownType) then
		return;
	end

	local countdownData = g_CountdownData[countdownType];
	if(countdownData == nil) then
		print("ERROR: missing countdownData for type " .. tostring(countdownType));
		return;
	end

	print("Starting Countdown Type " .. tostring(countdownType));
	m_countdownType = countdownType;

	if(countdownData.TimerType == TimerTypes.Script) then
		g_fCountdownTimer = countdownData.CountdownTime;
	else
		g_fCountdownTimer = NO_COUNTDOWN;
	end

	g_fCountdownTickSoundTime = countdownData.TickStartTime;
	g_fCountdownInitialTime = countdownData.CountdownTime;
	g_fCountdownReadyButtonTime = countdownData.CountdownTime;

	Controls.CountdownTimerAnim:RegisterAnimCallback( OnUpdateTimers );

	-- Update m_iFirstClosedSlot's player slot so it will hide the Add Player button if needed for this countdown type.
	if(m_iFirstClosedSlot ~= -1) then
		UpdatePlayerEntry(m_iFirstClosedSlot);
	end

	ShowHideReadyButtons();
end

function StartLaunchCountdown()
	--print("StartLaunchCountdown");
	local gameState = GameConfiguration.GetGameState();
	-- In progress PlayByCloud games and matchmaking games launch instantly.
	if((GameConfiguration.IsPlayByCloud() and gameState == GameStateTypes.GAMESTATE_LAUNCHED)
		or GameConfiguration.IsMatchMaking()) then
		-- Joining a PlayByCloud game already in progress has a much faster countdown to be less annoying.
		StartCountdown(CountdownTypes.Launch_Instant);
	else
		StartCountdown(CountdownTypes.Launch);
	end
end

function StartReadyCountdown()
	StartCountdown(GetReadyCountdownType());
end

-------------------------------------------------
-- Stop Launch Countdown
-------------------------------------------------
function StopCountdown()
	if(m_countdownType ~= CountdownTypes.None) then
		print("Stopping Countdown. m_countdownType=" .. tostring(m_countdownType));
	end

	Controls.TurnTimerMeter:SetPercent(0);
	m_countdownType = CountdownTypes.None;	
	g_fCountdownTimer = NO_COUNTDOWN;
	g_fCountdownInitialTime = NO_COUNTDOWN;
	UpdateReadyButton();

	-- Update m_iFirstClosedSlot's player slot so it will show the Add Player button.
	if(m_iFirstClosedSlot ~= -1) then
		UpdatePlayerEntry(m_iFirstClosedSlot);
	end

	ShowHideReadyButtons();

	Controls.CountdownTimerAnim:ClearAnimCallback();	
end

-------------------------------------------------
-- BuildPlayerList
-------------------------------------------------
function BuildPlayerList()
	ReleasePlayerParameters(); -- Release all the player parameters so they do not have zombie references to the entries we are now wiping.
	g_isBuildingPlayerList = true;
	-- Clear previous data.
	g_PlayerEntries = {};
	g_PlayerRootToPlayerID = {};
	g_cachedTeams = {};
	m_playersIM:ResetInstances();
	m_iFirstClosedSlot = -1;
	local numPlayers:number = 0;

	-- Create a player slot for every current participant and available player slot for the players.
	local player_ids = GameConfiguration.GetMultiplayerPlayerIDs();
	for i, iPlayer in ipairs(player_ids) do	
		local pPlayerConfig = PlayerConfigurations[iPlayer];
		if(pPlayerConfig ~= nil
			and IsDisplayableSlot(iPlayer)) then
			if(GameConfiguration.IsHotseat()) then
				local nickName = pPlayerConfig:GetNickName();
				if(nickName == nil or #nickName == 0) then
					pPlayerConfig:SetHotseatName(DefaultHotseatPlayerName .. " " .. iPlayer + 1);
				end
			end
            m_teamColors[numPlayers] = nil;
            -- Trigger a fake OnTeamChange on every active player slot to automagically create required PlayerEntry/TeamEntry
			OnTeamChange(iPlayer, true);
			numPlayers = numPlayers + 1;
            m_numPlayers = numPlayers;
		end	
	end

	UpdateTeamList(true);

	SetupGridLines(numPlayers - 1);

	g_isBuildingPlayerList = false;
end

-- ===========================================================================
-- Adjust vertical grid lines
-- ===========================================================================
function RealizeGridSize()
	Controls.PlayerListStack:CalculateSize();
	Controls.PlayersScrollPanel:CalculateSize();

	local gridLineHeight:number = math.max(Controls.PlayerListStack:GetSizeY(), Controls.PlayersScrollPanel:GetSizeY());
	for i = 1, NUM_COLUMNS do
		Controls["GridLine_" .. i]:SetEndY(gridLineHeight);
	end
	
	Controls.GridContainer:SetSizeY(gridLineHeight);
end

-------------------------------------------------
-- ResetChat
-------------------------------------------------
function ResetChat()
	m_ChatInstances = {}
	Controls.ChatStack:DestroyAllChildren();
	ChatPrintHelpHint(Controls.ChatStack, m_ChatInstances, Controls.ChatScroll);
end

-------------------------------------------------
--	Should only be ticking if there are timers active.
-------------------------------------------------
function OnUpdateTimers( uiControl:table, fProgress:number )

	local fDTime:number = UIManager:GetLastTimeDelta();

	if(m_countdownType == CountdownTypes.None) then
		Controls.CountdownTimerAnim:ClearAnimCallback();
	else
		UpdateCountdownTimeRemaining();
		local timeRemaining :number = GetCountdownTimeRemaining();
		Controls.TurnTimerMeter:SetPercent(timeRemaining / g_fCountdownInitialTime);
		if( IsLaunchCountdownActive() and not Network.IsEveryoneConnected() ) then
			-- not all players are connected anymore.  This is probably due to a player join in progress.
			StopCountdown();
		elseif( timeRemaining <= 0 ) then
			local stopCountdown = true;
			local checkForStart = false;
			if( IsLaunchCountdownActive() ) then
				-- Timer elapsed, launch the game if we're the netsession host.
				if(Network.IsNetSessionHost()) then
					Network.LaunchGame();
				end
			elseif( IsReadyCountdownActive() ) then
				-- Force ready the local player
				SetLocalReady(true);

				if(IsUseWaitingForPlayersCountdown()) then
					-- Transition to the Waiting For Players countdown.
					StartCountdown(CountdownTypes.WaitForPlayers);
					stopCountdown = false;
				end
			elseif( IsWaitForPlayersCountdownActive() ) then
				-- After stopping the countdown, recheck for start.  This should trigger the launch countdown because all players should be past their ready countdowns.
				checkForStart = true;			
			end

			if(stopCountdown == true) then
				StopCountdown();
			end

			if(checkForStart == true) then
				CheckGameAutoStart();
			end
		else
			-- Update countdown tick sound.
			if( timeRemaining < g_fCountdownTickSoundTime) then
				g_fCountdownTickSoundTime = g_fCountdownTickSoundTime-1; -- set countdown tick for next second.
				UI.PlaySound("Play_MP_Game_Launch_Timer_Beep");
			end

			-- Update countdown ready button.
			if( timeRemaining < g_fCountdownReadyButtonTime) then
				g_fCountdownReadyButtonTime = g_fCountdownReadyButtonTime-1; -- set countdown tick for next second.
				UpdateReadyButton();
			end
		end
	end
end

function UpdateCountdownTimeRemaining()
	local countdownData :table = g_CountdownData[m_countdownType];
	if(countdownData == nil) then
		print("ERROR: missing countdown data!");
		return;
	end

	if(countdownData.TimerType == TimerTypes.NetworkManager) then
		-- Network Manager timer updates itself.
		return;
	end

	local fDTime:number = UIManager:GetLastTimeDelta();
	g_fCountdownTimer = g_fCountdownTimer - fDTime;
end

-------------------------------------------------
-------------------------------------------------
function OnShow()
	-- Fetch g_currentMaxPlayers because it might be stale due to loading a save.
	g_currentMaxPlayers = math.min(MapConfiguration.GetMaxMajorPlayers(), 12);
	m_shownPBCReadyPopup = false;
	m_exitReadyWait = false;

	local networkSessionID:number = Network.GetSessionID();
	if m_sessionID ~= networkSessionID then
		-- This is a fresh session.
		m_sessionID = networkSessionID;

		StopCountdown();

		-- When using the ready countdown mode, start the ready countdown if the player is not already readied up.
		-- If the player is already readied up, we just don't allow them to unready.
		local localPlayerID :number = Network.GetLocalPlayerID();
		local localPlayerConfig :table = PlayerConfigurations[localPlayerID];
		if(IsUseReadyCountdown() 
			and localPlayerConfig ~= nil
			and localPlayerConfig:GetReady() == false) then
			StartReadyCountdown();
		end
	end

	InitializeReadyUI();
	ShowHideInviteButton();	
	ShowHideTopLeftButtons();
	RealizeGameSetup();
	BuildPlayerList();
	PopulateTargetPull(Controls.ChatPull, Controls.ChatEntry, Controls.ChatIcon, m_playerTargetEntries, m_playerTarget, false, OnChatPulldownChanged);
	ShowHideChatPanel();

	local pFriends = Network.GetFriends();
	if (pFriends ~= nil) then
		pFriends:SetRichPresence("civPresence", Network.IsGameHost() and "LOC_PRESENCE_HOSTING_GAME" or "LOC_PRESENCE_IN_STAGING_ROOM");
	end

	UpdateFriendsList();
	RealizeInfoTabs();
	RealizeGridSize();

	-- Forgive me universe!
	Controls.ReadyButton:SetOffsetY(isHotSeat and -16 or -18);

	if(Automation.IsActive()) then
		if(not Network.IsGameHost()) then
			-- Remote clients ready up immediately.
			SetLocalReady(true);
		else
			local minPlayers = Automation.GetSetParameter("CurrentTest", "MinPlayers", 2);
			if (minPlayers ~= nil) then
				-- See if we are going to be the only one in the game, set ourselves ready. 
				if (minPlayers == 1) then
					Automation.Log("HostGame MinPlayers==1, host readying up.");
					SetLocalReady(true);
				end
			end
		end
	end
end


function OnChatPulldownChanged(newTargetType :number, newTargetID :number)
	local textControl:table = Controls.ChatPull:GetButton():GetTextControl();
	local text:string = textControl:GetText();
	Controls.ChatPull:SetToolTipString(text);
end

-------------------------------------------------
-------------------------------------------------
function InitializeReadyUI()
	-- Set initial ready check state.  This might be dirty from a previous staging room.
	local localPlayerID = Network.GetLocalPlayerID();
	local localPlayerConfig = PlayerConfigurations[localPlayerID];

	if(IsCloudInProgressAndNotTurn()) then
		-- Show the ready check as unselected while in an inprogress PlayByCloud match where it is not our turn.  
		-- Clicking the ready button will instant launch the match so the player can observe the current game state.
		Controls.ReadyCheck:SetSelected(false);
	else
		Controls.ReadyCheck:SetSelected(localPlayerConfig:GetReady());
	end

	-- Hotseat doesn't use the readying mechanic (countdown; ready background elements; ready column). 
	local isHotSeat:boolean = GameConfiguration.IsHotseat();
	Controls.LargeCompassDeco:SetHide(isHotSeat);
	Controls.TurnTimerBG:SetHide(isHotSeat);
	Controls.TurnTimerMeter:SetHide(isHotSeat);
	Controls.TurnTimerHotseatBG:SetHide(not isHotSeat);
	Controls.ReadyColumnLabel:SetHide(isHotSeat);

	ShowHideReadyButtons();
end

-------------------------------------------------
-------------------------------------------------
function ShowHideInviteButton()
	local canInvite :boolean = CanInviteFriends(true);
	Controls.InviteButton:SetHide( not canInvite );
end

-------------------------------------------------
-------------------------------------------------
function ShowHideTopLeftButtons()
	local showEndGame :boolean = GameConfiguration.IsPlayByCloud() and Network.IsGameHost();
	local showQuitGame : boolean = GameConfiguration.IsPlayByCloud();

	Controls.EndGameButton:SetHide( not showEndGame);
	Controls.QuitGameButton:SetHide( not showQuitGame);

	Controls.LeftTopButtonStack:CalculateSize();	
end

-------------------------------------------------
-------------------------------------------------
function ShowHideReadyButtons()
	-- show ready button when in not in a countdown or hotseat.
	local showReadyCheck = not GameConfiguration.IsHotseat() and (m_countdownType == CountdownTypes.None);
	Controls.ReadyCheckContainer:SetHide(not showReadyCheck);
	Controls.ReadyButtonContainer:SetHide(showReadyCheck);
end

-------------------------------------------------
-------------------------------------------------
function ShowHideChatPanel()
	if(GameConfiguration.IsHotseat() or not UI.HasFeature("Chat") or GameConfiguration.IsPlayByCloud()) then
		Controls.ChatContainer:SetHide(true);
	else
		Controls.ChatContainer:SetHide(false);
	end
	--Controls.TwinPanelStack:CalculateSize();
end

-------------------------------------------------------------------------------
-- Setup Player Interface
-- This gets or creates player parameters for a given player id.
-- It then appends a driver to the setup parameter to control a visual 
-- representation of the parameter
-------------------------------------------------------------------------------
function SetupSplitLeaderPulldown(playerId:number, instance:table, pulldownControlName:string, civIconControlName, leaderIconControlName, tooltipControls:table)
	local parameters = GetPlayerParameters(playerId);
	if(parameters == nil) then
		parameters = CreatePlayerParameters(playerId);
	end

	-- Need to save our master tooltip controls so that we can update them if we hop into advanced setup and then go back to basic setup
	if (tooltipControls.HasLeaderPlacard) then
		m_tooltipControls = {};
		m_tooltipControls = tooltipControls;
	end

	-- Defaults
	if(leaderIconControlName == nil) then
		leaderIconControlName = "LeaderIcon";
	end
		
	local control = instance[pulldownControlName];
	local leaderIcon = instance[leaderIconControlName];
	local civIcon = instance["CivIcon"];
	local civIconBG = instance["IconBG"];
	local civWarnIcon = instance["WarnIcon"];
    local scrollText = instance["ScrollText"];
	local instanceManager = control["InstanceManager"];
	if not instanceManager then
		instanceManager = PullDownInstanceManager:new( "InstanceOne", "Button", control );
		control["InstanceManager"] = instanceManager;
	end

	local colorControl = instance["ColorPullDown"];
	local colorInstanceManager = colorControl["InstanceManager"];
	if not colorInstanceManager then
		colorInstanceManager = PullDownInstanceManager:new( "InstanceOne", "Button", colorControl );
		colorControl["InstanceManager"] = colorInstanceManager;
	end
    colorControl:SetDisabled(true);

	local controls = parameters.Controls["PlayerLeader"];
	if(controls == nil) then
		controls = {};
		parameters.Controls["PlayerLeader"] = controls;
	end

	m_currentInfo = {										
		CivilizationIcon = "ICON_CIVILIZATION_UNKNOWN",
		LeaderIcon = "ICON_LEADER_DEFAULT",
		CivilizationName = "LOC_RANDOM_CIVILIZATION",
		LeaderName = "LOC_RANDOM_LEADER"
	};

	civWarnIcon:SetHide(true);
	civIconBG:SetHide(true);

	table.insert(controls, {
		UpdateValue = function(v)
			local button = control:GetButton();

			if(v == nil) then
				button:LocalizeAndSetText("LOC_SETUP_ERROR_INVALID_OPTION");
				button:ClearCallback(Mouse.eMouseEnter);
				button:ClearCallback(Mouse.eMouseExit);
			else
				local caption = v.Name;
				if(v.Invalid) then
					local err = v.InvalidReason or "LOC_SETUP_ERROR_INVALID_OPTION";
					caption = caption .. "[NEWLINE][COLOR_RED](" .. Locale.Lookup(err) .. ")[ENDCOLOR]";
				end

				if(scrollText ~= nil) then
					scrollText:SetText(caption);
					button:LocalizeAndSetText("");
				else
					button:SetText(caption);
				end
				
				local icons = GetPlayerIcons(v.Domain, v.Value);
				local playerColor = icons.PlayerColor or "";
				if(leaderIcon) then
					leaderIcon:SetIcon(icons.LeaderIcon);
				end

				if(not tooltipControls.HasLeaderPlacard) then
					-- Upvalues
					local info;
					local domain = v.Domain;
					local value = v.Value;
					button:RegisterCallback( Mouse.eMouseEnter, function() 
						if(info == nil) then info = GetPlayerInfo(domain, value, playerId); end
						DisplayCivLeaderToolTip(info, tooltipControls, false); 
					end);
					
					button:RegisterCallback( Mouse.eMouseExit, function() 
						if(info == nil) then info = GetPlayerInfo(domain, value, playerId); end
						DisplayCivLeaderToolTip(info, tooltipControls, true); 
					end);
				end

				local primaryColor, secondaryColor = UI.GetPlayerColorValues(playerColor, 0);
				if v.Value == "RANDOM" or v.Value == "RANDOM_POOL1" or v.Value == "RANDOM_POOL2" or primaryColor == nil then
					civIconBG:SetHide(true);
					civIcon:SetHide(true);
					civWarnIcon:SetHide(true);
                    colorControl:SetDisabled(true);
				else

					local colorCount = 0;
					for j=0, 3, 1 do
						local backColor, frontColor = UI.GetPlayerColorValues(playerColor, j);
						if(backColor and frontColor and backColor ~= 0 and frontColor ~= 0) then
							colorCount = colorCount + 1;
						end
					end

					local notExternalEnabled = not CheckExternalEnabled(playerId, true, true, nil);
					colorControl:SetDisabled(notExternalEnabled or colorCount == 0 or colorCount == 1);

                    -- also update collision check color
                    -- Color collision checking.
					local myTeam = m_teamColors[playerId];
					local bShowWarning = false;
					for k , v in pairs(m_teamColors) do
						if(k ~= playerId) then
							if( myTeam and v and myTeam[1] == v[1] and myTeam[2] == v[2] ) then
								bShowWarning = true;
							end
						end
					end
					civWarnIcon:SetHide(not bShowWarning);
    				if bShowWarning == true then
    					civWarnIcon:LocalizeAndSetToolTip("LOC_SETUP_PLAYER_COLOR_COLLISION");
    				else
    					civWarnIcon:SetToolTipString(nil);
    				end	
                end
			end		
		end,
		UpdateValues = function(values)
			instanceManager:ResetInstances();
            local iIteratedPlayerID = 0;

			-- Avoid creating call back for each value.
			local hasPlacard = tooltipControls.HasLeaderPlacard;
			local OnMouseExit = function()
				DisplayCivLeaderToolTip(m_currentInfo, tooltipControls, not hasPlacard);
			end;

			for i,v in ipairs(values) do
				local icons = GetPlayerIcons(v.Domain, v.Value);
				local playerColor = icons.PlayerColor;

				local entry = instanceManager:GetInstance();
				
				local caption = v.Name;
				if(v.Invalid) then 
					local err = v.InvalidReason or "LOC_SETUP_ERROR_INVALID_OPTION";
					caption = caption .. "[NEWLINE][COLOR_RED](" .. Locale.Lookup(err) .. ")[ENDCOLOR]";
				end

				if(entry.ScrollText ~= nil) then
					entry.ScrollText:SetText(caption);
				else
					entry.Button:SetText(caption);
				end
				entry.LeaderIcon:SetIcon(icons.LeaderIcon);
				
				-- Upvalues
				local info;
				local domain = v.Domain;
				local value = v.Value;
				
				entry.Button:RegisterCallback( Mouse.eMouseEnter, function() 
					if(info == nil) then info = GetPlayerInfo(domain, value, playerId); end
					DisplayCivLeaderToolTip(info, tooltipControls, false);
				 end);

				entry.Button:RegisterCallback( Mouse.eMouseExit,OnMouseExit);
				entry.Button:SetToolTipString(nil);			

				entry.Button:RegisterCallback(Mouse.eLClick, function()
					if(info == nil) then info = GetPlayerInfo(domain, value); end

					--  if the user picked random, hide the civ icon again
					local primaryColor, secondaryColor = UI.GetPlayerColorValues(playerColor, 0);
					 m_teamColors[playerId] = {primaryColor, secondaryColor};

                    -- set default alternate color to the primary
					local colorParameter = parameters.Parameters["PlayerColorAlternate"]; 
					parameters:SetParameterValue(colorParameter, 0);

                    -- set the team
                    local leaderParameter = parameters.Parameters["PlayerLeader"];
					parameters:SetParameterValue(leaderParameter, v);

					if(playerId == 0) then
						m_currentInfo = info;
					end
				end);
			end
			control:CalculateInternals();
		end,
		SetEnabled = function(enabled, parameter)
			local notExternalEnabled = not CheckExternalEnabled(playerId, enabled, true, parameter);
			local singleOrEmpty = #parameter.Values <= 1;

            control:SetDisabled(notExternalEnabled or singleOrEmpty);
		end,
	--	SetVisible = function(visible)
	--		control:SetHide(not visible);
	--	end
	});
end

-- ===========================================================================
function OnGameSetupTabClicked()
	UIManager:DequeuePopup( ContextPtr );
end

-- ===========================================================================

function RealizeShellTabs()
	m_shellTabIM:ResetInstances();

	local gameSetup:table = m_shellTabIM:GetInstance();
	gameSetup.Button:SetText(LOC_GAME_SETUP);
	gameSetup.SelectedButton:SetText(LOC_GAME_SETUP);
	gameSetup.Selected:SetHide(true);
	gameSetup.Button:RegisterCallback( Mouse.eLClick, OnGameSetupTabClicked );

	AutoSizeGridButton(gameSetup.Button,250,32,10,"H");
	AutoSizeGridButton(gameSetup.SelectedButton,250,32,20,"H");
	gameSetup.TopControl:SetSizeX(gameSetup.Button:GetSizeX());

	local stagingRoom:table = m_shellTabIM:GetInstance();
	stagingRoom.Button:SetText(LOC_STAGING_ROOM);
	stagingRoom.SelectedButton:SetText(LOC_STAGING_ROOM);
	stagingRoom.Button:SetDisabled(not Network.IsInSession());
	stagingRoom.Selected:SetHide(false);

	AutoSizeGridButton(stagingRoom.Button,250,32,20,"H");
	AutoSizeGridButton(stagingRoom.SelectedButton,250,32,20,"H");
	stagingRoom.TopControl:SetSizeX(stagingRoom.Button:GetSizeX());
	
	Controls.ShellTabs:CalculateSize();
end

-- ===========================================================================
function OnGameSummaryTabClicked()
	-- TODO
end

function OnFriendsTabClicked()
	-- TODO
end

-- ===========================================================================
function BuildGameSetupParameter(o, parameter)

	local parent = GetControlStack(parameter.GroupId);
	local control;
	
	-- If there is no parent, don't visualize the control.  This is most likely a player parameter.
	if(parent == nil or not parameter.Visible) then
		return;
	end;

	
	local c = m_gameSetupParameterIM:GetInstance();		
	c.Root:ChangeParent(parent);

	-- Store the root control, NOT the instance table.
	g_SortingMap[tostring(c.Root)] = parameter;		
			
	c.Label:SetText(parameter.Name);
	c.Value:SetText(parameter.DefaultValue);
	c.Root:SetToolTipString(parameter.Description);

	control = {
		Control = c,
		UpdateValue = function(value, p)
			local t:string = type(value);
			if(p.Array) then
				local valueText;

				if (parameter.UxHint ~= nil and parameter.UxHint == "InvertSelection") then
					valueText = Locale.Lookup("LOC_SELECTION_EVERYTHING");
				else
					valueText = Locale.Lookup("LOC_SELECTION_NOTHING");
				end

				-- Remove random leaders from the Values table that is used to determine number of leaders selected
				for i = #p.Values, 1, -1 do
					local kItem:table = p.Values[i];
					if kItem.Value == "RANDOM" or kItem.Value == "RANDOM_POOL1" or kItem.Value == "RANDOM_POOL2" then
						table.remove(p.Values, i);
					end
				end

				if(t == "table") then
					local count = #value;
					if (parameter.UxHint ~= nil and parameter.UxHint == "InvertSelection") then
						if(count == 0) then
							valueText = Locale.Lookup("LOC_SELECTION_EVERYTHING");
						elseif(count == #p.Values) then
							valueText = Locale.Lookup("LOC_SELECTION_NOTHING");
						else
							valueText = Locale.Lookup("LOC_SELECTION_CUSTOM", #p.Values-count);
						end
					else
						if(count == 0) then
							valueText = Locale.Lookup("LOC_SELECTION_NOTHING");
						elseif(count == #p.Values) then
							valueText = Locale.Lookup("LOC_SELECTION_EVERYTHING");
						else
							valueText = Locale.Lookup("LOC_SELECTION_CUSTOM", count);
						end
					end
				end
				c.Value:SetText(valueText);
				c.Value:SetToolTipString(parameter.Description);
			else
				if t == "table" then
					c.Value:SetText(value.Name);
				elseif t == "boolean" then
					c.Value:SetText(Locale.Lookup(value and "LOC_MULTIPLAYER_TRUE" or "LOC_MULTIPLAYER_FALSE"));
				else
					c.Value:SetText(tostring(value));
				end
			end			
		end,
		SetVisible = function(visible)
			c.Root:SetHide(not visible);
		end,
		Destroy = function()
			g_StringParameterManager:ReleaseInstance(c);
		end,
	};

	o.Controls[parameter.ParameterId] = control;
end

function RealizeGameSetup()
	BuildGameState();

	m_gameSetupParameterIM:ResetInstances();
	BuildGameSetup(BuildGameSetupParameter);

	BuildAdditionalContent();
end


-- ===========================================================================
--	Can join codes be used in the current lobby system?
-- ===========================================================================
function ShowJoinCode()
	local pbcMode			:boolean = GameConfiguration.IsPlayByCloud() and (GameConfiguration.GetGameState() == GameStateTypes.GAMESTATE_LOAD_PREGAME or GameConfiguration.GetGameState() == GameStateTypes.GAMESTATE_PREGAME);
	local crossPlayMode		:boolean = (Network.GetTransportType() == TransportType.TRANSPORT_EOS);
	local eosAllowed		:boolean = (Network.GetNetworkPlatform() == NetworkPlatform.NETWORK_PLATFORM_EOS) and GameConfiguration.IsInternetMultiplayer();
	return pbcMode or crossPlayMode or eosAllowed;
end

-- ===========================================================================
function BuildGameState()
	-- Indicate that this game is for loading a save or already in progress.
	local gameState = GameConfiguration.GetGameState();
	if(gameState ~= GameStateTypes.GAMESTATE_PREGAME) then
		local gameModeStr : string;

		if(gameState == GameStateTypes.GAMESTATE_LOAD_PREGAME) then
			-- in the pregame for loading a save
			gameModeStr = loadingSaveGameStr;
		else
			-- standard game in progress
			gameModeStr = gameInProgressGameStr;
		end
		Controls.GameStateText:SetHide(false);
		Controls.GameStateText:SetText(gameModeStr);
	else
		Controls.GameStateText:SetHide(true);
	end

	-- A 'join code' is a short string that can be sent through the MP system
	-- to allow other players to connect to the same session of the game.
	-- Originally only for PBC but added to support other MP game types.
	local joinCode :string = Network.GetJoinCode();
	Controls.JoinCodeRoot:SetHide( ShowJoinCode()==false );
	if joinCode ~= nil and joinCode ~= "" then
		Controls.JoinCodeText:SetText(joinCode);
	else
		Controls.JoinCodeText:SetText("---");			-- Better than showing nothing?
	end

	Controls.AdditionalContentStack:CalculateSize();
	Controls.ParametersScrollPanel:CalculateSize();
end

-- ===========================================================================
function BuildAdditionalContent()
	m_modsIM:ResetInstances();

	local enabledMods = GameConfiguration.GetEnabledMods();
	for _, curMod in ipairs(enabledMods) do
		local modControl = m_modsIM:GetInstance();
		local modTitleStr : string = curMod.Title;

		-- Color unofficial mods to call them out.
		if(not curMod.Official) then
			modTitleStr = ColorString_ModGreen .. modTitleStr .. "[ENDCOLOR]";
		end
		modControl.ModTitle:SetText(modTitleStr);
	end

	Controls.AdditionalContentStack:CalculateSize();
	Controls.ParametersScrollPanel:CalculateSize();
end

-- ===========================================================================
function RealizeInfoTabs()
	m_infoTabsIM:ResetInstances();
	local friends:table;
	local gameSummary:table

	gameSummary = m_infoTabsIM:GetInstance();
	gameSummary.Button:SetText(LOC_GAME_SUMMARY);
	gameSummary.SelectedButton:SetText(LOC_GAME_SUMMARY);
	gameSummary.Selected:SetHide(not g_viewingGameSummary);

	gameSummary.Button:RegisterCallback(Mouse.eLClick, function()
		g_viewingGameSummary = true;
		Controls.Friends:SetHide(true);
		friends.Selected:SetHide(true);
		gameSummary.Selected:SetHide(false);
		Controls.ParametersScrollPanel:SetHide(false);
	end);

	AutoSizeGridButton(gameSummary.Button,200,32,10,"H");
	AutoSizeGridButton(gameSummary.SelectedButton,200,32,20,"H");
	gameSummary.TopControl:SetSizeX(gameSummary.Button:GetSizeX());

	if not GameConfiguration.IsHotseat() then
		friends = m_infoTabsIM:GetInstance();
		friends.Button:SetText(LOC_FRIENDS);
		friends.SelectedButton:SetText(LOC_FRIENDS);
		friends.Selected:SetHide(g_viewingGameSummary);
		friends.Button:SetDisabled(not Network.IsInSession());
		friends.Button:RegisterCallback( Mouse.eLClick, function()
			g_viewingGameSummary = false;
			Controls.Friends:SetHide(false);
			friends.Selected:SetHide(false);
			gameSummary.Selected:SetHide(true);
			Controls.ParametersScrollPanel:SetHide(true);
			UpdateFriendsList();
		end );

		AutoSizeGridButton(friends.Button,200,32,20,"H");
		AutoSizeGridButton(friends.SelectedButton,200,32,20,"H");
		friends.TopControl:SetSizeX(friends.Button:GetSizeX());
	end

	Controls.InfoTabs:CalculateSize();
end

-------------------------------------------------
function UpdateFriendsList()

	if ContextPtr:IsHidden() or GameConfiguration.IsHotseat() then
		Controls.InfoContainer:SetHide(true);
		return;
	end

	m_friendsIM:ResetInstances();
	Controls.InfoContainer:SetHide(false);
	local friends:table = GetFriendsList();
	local bCanInvite:boolean = CanInviteFriends(false) and Network.HasSingleFriendInvite();

	-- DEBUG
	--for i = 1, 19 do
	-- /DEBUG
	for _, friend in pairs(friends) do
		local instance:table = m_friendsIM:GetInstance();

		-- Build the dropdown for the friend list
		local friendActions:table = {};
		BuildFriendActionList(friendActions, bCanInvite and not IsFriendInGame(friend));

		-- end build
		local friendPlayingCiv:boolean = friend.PlayingCiv; -- cache value to ensure it's available in callback function

		PopulateFriendsInstance(instance, friend, friendActions, 
			function(friendID, actionType) 
				if actionType == "invite" then
					local statusText:string = friendPlayingCiv and "LOC_PRESENCE_INVITED_ONLINE" or "LOC_PRESENCE_INVITED_OFFLINE";
					instance.PlayerStatus:LocalizeAndSetText(statusText);
				end
			end
		);

	end
	-- DEBUG
	--end
	-- /DEBUG

	Controls.FriendsStack:CalculateSize();
	Controls.FriendsScrollPanel:CalculateSize();
	Controls.FriendsScrollPanel:GetScrollBar():SetAndCall(0);

	if Controls.FriendsScrollPanel:GetScrollBar():IsHidden() then
		Controls.FriendsScrollPanel:SetOffsetX(8);
	else
		Controls.FriendsScrollPanel:SetOffsetX(3);
	end

	if table.count(friends) == 0 then
		Controls.InviteButton:SetAnchor("C,C");
		Controls.InviteButton:SetOffsetY(0);
	else
		Controls.InviteButton:SetAnchor("C,B");
		Controls.InviteButton:SetOffsetY(27);
	end
end

function IsFriendInGame(friend:table)
	local player_ids = GameConfiguration.GetParticipatingPlayerIDs();
	for i, iPlayer in ipairs(player_ids) do	
		local curPlayerConfig = PlayerConfigurations[iPlayer];
		local steamID = curPlayerConfig:GetNetworkIdentifer();
		if( steamID ~= nil and steamID == friend.ID and Network.IsPlayerConnected(iPlayer) ) then
			return true;
		end
	end
	return fasle;
end

-------------------------------------------------
function SetupGridLines(numPlayers:number)
	g_GridLinesIM:ResetInstances();
	RealizeGridSize();
	local nextY:number = GRID_LINE_HEIGHT;
	local gridSize:number = Controls.GridContainer:GetSizeY();
	local numLines:number = math.max(numPlayers, gridSize / GRID_LINE_HEIGHT);
	for i:number = 1, numLines do
		g_GridLinesIM:GetInstance().Control:SetOffsetY(nextY);
		nextY = nextY + GRID_LINE_HEIGHT;
	end
end

-------------------------------------------------
-------------------------------------------------
function OnInit(isReload:boolean)
	if isReload then
		LuaEvents.GameDebug_GetValues( "StagingRoom" );
	end
end

function OnShutdown()
	-- Cache values for hotloading...
	LuaEvents.GameDebug_AddValue("StagingRoom", "isHidden", ContextPtr:IsHidden());
end

function OnGameDebugReturn( context:string, contextTable:table )
	if context == "StagingRoom" and contextTable["isHidden"] == false then
		if ContextPtr:IsHidden() then
			ContextPtr:SetHide(false);
		else
			OnShow();
		end
	end	
end

-- ===========================================================================
--	LUA Event
--	Show the screen
-- ===========================================================================
function OnRaise(resetChat:boolean)
	-- Make sure HostGame screen is on the stack
	LuaEvents.StagingRoom_EnsureHostGame();

	UIManager:QueuePopup( ContextPtr, PopupPriority.Current );
end

-- ===========================================================================
function Resize()
	local screenX, screenY:number = UIManager:GetScreenSizeVal();
	Controls.MainWindow:SetSizeY(screenY-( Controls.LogoContainer:GetSizeY()-Controls.LogoContainer:GetOffsetY() ));
	local window = Controls.MainWindow:GetSizeY() - Controls.TopPanel:GetSizeY();
	Controls.ChatContainer:SetSizeY(window/2 -80)
	Controls.PrimaryStackGrid:SetSizeY(window-Controls.ChatContainer:GetSizeY() -75 )
	Controls.InfoContainer:SetSizeY(window/2 -80)
	Controls.PrimaryPanelStack:CalculateSize()
	RealizeGridSize();
end

-- ===========================================================================
function OnUpdateUI( type:number, tag:string, iData1:number, iData2:number, strData1:string )   
  if type == SystemUpdateUI.ScreenResize then
	Resize();
  end
end

-- ===========================================================================
function StartExitGame()
	if(GetReadyCountdownType() == CountdownTypes.Ready_PlayByCloud) then
		-- If we are using the PlayByCloud ready countdown, the local player needs to be set to ready before they can leave.
		-- If we are not ready, we set ready and wait for that change to propagate to the backend.
		local localPlayerID :number = Network.GetLocalPlayerID();
		local localPlayerConfig :table = PlayerConfigurations[localPlayerID];
		if(localPlayerConfig:GetReady() == false) then
			m_exitReadyWait = true;
			SetLocalReady(true);

			-- Next step will be in OnUploadCloudPlayerConfigComplete.
			return;
		end
	end

	Close();
end

-- ===========================================================================
function OnEndGame_Start()
	Network.CloudKillGame();

	-- Show killing game popup
	m_kPopupDialog:Close(); -- clear out the popup incase it is already open.
	m_kPopupDialog:AddTitle(  Locale.ToUpper(Locale.Lookup("LOC_MULTIPLAYER_ENDING_GAME_TITLE")));
	m_kPopupDialog:AddText(	  Locale.Lookup("LOC_MULTIPLAYER_ENDING_GAME_PROMPT"));
	m_kPopupDialog:Open();

	-- Next step is in OnCloudGameKilled.
end

function OnQuitGame_Start()
	Network.CloudQuitGame();

	-- Show killing game popup
	m_kPopupDialog:Close(); -- clear out the popup incase it is already open.
	m_kPopupDialog:AddTitle(  Locale.ToUpper(Locale.Lookup("LOC_MULTIPLAYER_QUITING_GAME_TITLE")));
	m_kPopupDialog:AddText(	  Locale.Lookup("LOC_MULTIPLAYER_QUITING_GAME_PROMPT"));
	m_kPopupDialog:Open();

	-- Next step is in OnCloudGameQuit.
end

function OnExitGameAskAreYouSure()
	if(GameConfiguration.IsPlayByCloud()) then
		-- PlayByCloud immediately exits to streamline the process and avoid confusion with the popup text.
		StartExitGame();
		return;
	end

	m_kPopupDialog:Close();	-- clear out the popup incase it is already open.
	m_kPopupDialog:AddTitle(  Locale.ToUpper(Locale.Lookup("LOC_GAME_MENU_QUIT_TITLE")));
	m_kPopupDialog:AddText(	  Locale.Lookup("LOC_GAME_MENU_QUIT_WARNING"));
	m_kPopupDialog:AddButton( Locale.Lookup("LOC_COMMON_DIALOG_NO_BUTTON_CAPTION"), nil );
	m_kPopupDialog:AddButton( Locale.Lookup("LOC_COMMON_DIALOG_YES_BUTTON_CAPTION"), StartExitGame, nil, nil, "PopupButtonInstanceRed" );
	m_kPopupDialog:Open();
end

function OnEndGameAskAreYouSure()
	m_kPopupDialog:Close(); -- clear out the popup incase it is already open.
	m_kPopupDialog:AddTitle(  Locale.ToUpper(Locale.Lookup("LOC_GAME_MENU_END_GAME_TITLE")));
	m_kPopupDialog:AddText(	  Locale.Lookup("LOC_GAME_MENU_END_GAME_WARNING"));
	m_kPopupDialog:AddButton( Locale.Lookup("LOC_COMMON_DIALOG_NO_BUTTON_CAPTION"), nil );
	m_kPopupDialog:AddButton( Locale.Lookup("LOC_COMMON_DIALOG_YES_BUTTON_CAPTION"), OnEndGame_Start, nil, nil, "PopupButtonInstanceRed" );
	m_kPopupDialog:Open();
end

function OnQuitGameAskAreYouSure()
	m_kPopupDialog:Close(); -- clear out the popup incase it is already open.
	m_kPopupDialog:AddTitle(  Locale.ToUpper(Locale.Lookup("LOC_GAME_MENU_QUIT_GAME_TITLE")));
	m_kPopupDialog:AddText(	  Locale.Lookup("LOC_GAME_MENU_QUIT_GAME_WARNING"));
	m_kPopupDialog:AddButton( Locale.Lookup("LOC_COMMON_DIALOG_NO_BUTTON_CAPTION"), nil );
	m_kPopupDialog:AddButton( Locale.Lookup("LOC_COMMON_DIALOG_YES_BUTTON_CAPTION"), OnQuitGame_Start, nil, nil, "PopupButtonInstanceRed" );
	m_kPopupDialog:Open();
end


-- ===========================================================================
function GetInviteTT()
	if( Network.GetNetworkPlatform() == NetworkPlatform.NETWORK_PLATFORM_EOS ) then
		return Locale.Lookup("LOC_EPIC_INVITE_BUTTON_TT");
	end

	return Locale.Lookup("LOC_INVITE_BUTTON_TT");
end

-- ===========================================================================
--	Initialize screen
-- ===========================================================================
function Initialize()

	m_kPopupDialog = PopupDialog:new( "StagingRoom" );
	
	SetCurrentMaxPlayers(MapConfiguration.GetMaxMajorPlayers());
	SetCurrentMinPlayers(MapConfiguration.GetMinMajorPlayers());
	Events.SystemUpdateUI.Add(OnUpdateUI);
	ContextPtr:SetInitHandler(OnInit);
	ContextPtr:SetShutdown(OnShutdown);
	ContextPtr:SetInputHandler( OnInputHandler, true );
	ContextPtr:SetShowHandler(OnShow);
	Controls.BackButton:RegisterCallback( Mouse.eLClick, OnExitGameAskAreYouSure );
	Controls.BackButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.ChatEntry:RegisterCommitCallback( SendChat );
	Controls.InviteButton:RegisterCallback( Mouse.eLClick, OnInviteButton );
	Controls.InviteButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.EndGameButton:RegisterCallback( Mouse.eLClick, OnEndGameAskAreYouSure );
	Controls.EndGameButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);	
	Controls.QuitGameButton:RegisterCallback( Mouse.eLClick, OnQuitGameAskAreYouSure );
	Controls.QuitGameButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);	
	Controls.ReadyButton:RegisterCallback( Mouse.eLClick, OnReadyButton );
	Controls.ReadyButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.ReadyCheck:RegisterCallback( Mouse.eLClick, OnReadyButton );
	Controls.ReadyCheck:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.JoinCodeText:RegisterCallback( Mouse.eLClick, OnClickToCopy );

	Controls.InviteButton:SetToolTipString(GetInviteTT());

	Events.MapMaxMajorPlayersChanged.Add(OnMapMaxMajorPlayersChanged); 
	Events.MapMinMajorPlayersChanged.Add(OnMapMinMajorPlayersChanged);
	Events.MultiplayerPrePlayerDisconnected.Add( OnMultiplayerPrePlayerDisconnected );
	Events.GameConfigChanged.Add(OnGameConfigChanged);
	Events.PlayerInfoChanged.Add(OnPlayerInfoChanged);
	Events.UploadCloudPlayerConfigComplete.Add(OnUploadCloudPlayerConfigComplete);
	Events.ModStatusUpdated.Add(OnModStatusUpdated);
	Events.MultiplayerChat.Add( OnMultiplayerChat );
	Events.MultiplayerGameAbandoned.Add( OnAbandoned );
	Events.MultiplayerGameLaunchFailed.Add( OnMultiplayerGameLaunchFailed );
	Events.LeaveGameComplete.Add( OnLeaveGameComplete );
	Events.BeforeMultiplayerInviteProcessing.Add( OnBeforeMultiplayerInviteProcessing );
	Events.MultiplayerHostMigrated.Add( OnMultiplayerHostMigrated );
	Events.MultiplayerPlayerConnected.Add( OnMultplayerPlayerConnected );
	Events.MultiplayerPingTimesChanged.Add(OnMultiplayerPingTimesChanged);
	Events.SteamFriendsStatusUpdated.Add( UpdateFriendsList );
	Events.SteamFriendsPresenceUpdated.Add( UpdateFriendsList );
	Events.CloudGameKilled.Add(OnCloudGameKilled);
	Events.CloudGameQuit.Add(OnCloudGameQuit);

	LuaEvents.GameDebug_Return.Add(OnGameDebugReturn);
	LuaEvents.HostGame_ShowStagingRoom.Add( OnRaise );
	LuaEvents.JoiningRoom_ShowStagingRoom.Add( OnRaise );
	LuaEvents.EditHotseatPlayer_UpdatePlayer.Add(UpdatePlayerEntry);
	LuaEvents.Multiplayer_ExitShell.Add( OnHandleExitRequest );

	Controls.TitleLabel:SetText(Locale.ToUpper(Locale.Lookup("LOC_MULTIPLAYER_STAGING_ROOM")));
	ResizeButtonToText(Controls.BackButton);
	ResizeButtonToText(Controls.EndGameButton);
	ResizeButtonToText(Controls.QuitGameButton);
	RealizeShellTabs();
	RealizeInfoTabs();
	SetupGridLines(0);
	Resize();
	
end

--#Accessibility integration
include("caiUtils")

local mgr = ExposedMembers.CAI_UIManager

local CAI_PANEL_ID = "CAIStagingRoom_Panel"
local HOVER_SOUND = "Main_Menu_Mouse_Over"

local CAI_Panel = nil
local CAI_PlayerList = nil
local CAI_ReadyButton = nil
local CAI_ChatHistory = nil
local CAI_ChatInput = nil
local CAI_ChatTarget = nil
local CAI_GameSummary = nil
local CAI_FriendsList = nil
local CAI_ChatLines = {}
local CAI_LastReadySpeech = { label = "", tooltip = "" }
local CAI_LastKnownLocalPlayerID = nil
local CAI_PlayerListRefreshQueued = false
local CAI_ChatTargetRefreshQueued = false
local CAI_PendingSwapFocusKey = nil
local CAI_PendingSwapFocusWithinList = false
local CAI_PendingSwapFeedback = nil
local CAI_RequestPlayerListRefresh
local CAI_RebuildChatTarget

local function CAI_Lookup(text, ...)
	if text == nil then return "" end
	return Locale.Lookup(text, ...)
end

local function CAI_ControlText(control)
	if control and control.GetText then
		return control:GetText() or ""
	end
	return ""
end

local function CAI_ControlTooltip(control)
	if control and control.GetToolTipString then
		return control:GetToolTipString() or ""
	end
	return ""
end

local function CAI_IsHidden(control)
	return control and control.IsHidden and control:IsHidden()
end

local function CAI_IsDisabled(control)
	return control and control.IsDisabled and control:IsDisabled()
end

local function CAI_IsDescendantOf(widget, root)
	while widget do
		if widget == root then return true end
		widget = widget.Parent
	end
	return false
end

local function CAI_IsFocusWithin(root)
	if root == nil or mgr == nil or mgr.CurrentPath == nil then return false end
	local focused = mgr.CurrentPath[#mgr.CurrentPath]
	return CAI_IsDescendantOf(focused, root)
end

local function CAI_AddDetail(lines, labelTag, value)
	if value and value ~= "" then
		table.insert(lines, CAI_Lookup("LOC_CAI_STAGING_DETAIL", CAI_Lookup(labelTag), value))
	end
end

local function CAI_JoinLines(lines)
	return table.concat(lines, "[NEWLINE]")
end

local function CAI_SplitNewlines(text)
	local lines = {}
	if text == nil or text == "" then return lines end
	text = text .. "[NEWLINE]"
	for line in text:gmatch("(.-)%[NEWLINE%]") do
		if line ~= "" then table.insert(lines, line) end
	end
	return lines
end

local function CAI_StripFormatting(text)
	if text == nil then return "" end
	text = tostring(text)
	text = text:gsub("%[COLOR[^%]]*%]", "")
	text = text:gsub("%[ENDCOLOR%]", "")
	return text
end

local function CAI_NormalizeText(text)
	text = CAI_StripFormatting(text)
	text = text:gsub("%[NEWLINE%]", "\n")
	text = text:gsub("\r", "")
	text = text:gsub("[ \t]+", " ")
	text = text:gsub(" *\n *", "\n")
	text = text:gsub("^%s+", "")
	text = text:gsub("%s+$", "")
	return text
end

local function CAI_GetExplanationTooltip(text, ...)
	local excluded = {}
	for i = 1, select("#", ...) do
		local value = select(i, ...)
		local normalized = CAI_NormalizeText(value)
		if normalized ~= "" then
			excluded[normalized] = true
		end
	end

	local lines = {}
	local seen = {}
	for _, line in ipairs(CAI_SplitNewlines(text)) do
		local normalized = CAI_NormalizeText(line)
		if normalized ~= "" and not excluded[normalized] and not seen[normalized] then
			seen[normalized] = true
			table.insert(lines, line)
		end
	end
	return CAI_JoinLines(lines)
end

local function CAI_AppendUniqueLine(text, line)
	if line == nil or line == "" then return text or "" end
	local existing = text or ""
	local normalizedLine = CAI_NormalizeText(line)
	if normalizedLine == "" then return existing end
	local normalizedExisting = CAI_NormalizeText(existing)
	if normalizedExisting == normalizedLine then return existing end
	for _, existingLine in ipairs(CAI_SplitNewlines(existing)) do
		if CAI_NormalizeText(existingLine) == normalizedLine then
			return existing
		end
	end
	if existing == "" then return line end
	return existing .. "[NEWLINE]" .. line
end

local function CAI_FormatInvalidLabel(label, invalidReason)
	if invalidReason == "" then return label end
	return label .. " [COLOR_RED](" .. invalidReason .. ")[ENDCOLOR]"
end

local function CAI_GetParameterInvalidReason(parameter)
	if parameter == nil then return "" end
	if parameter.Invalid and parameter.InvalidReason then
		return CAI_Lookup(parameter.InvalidReason)
	end
	return ""
end

local function CAI_GetValueInvalidReason(value)
	if value == nil then return "" end
	if value.Invalid and value.InvalidReason then
		return CAI_Lookup(value.InvalidReason)
	end
	return ""
end

local function CAI_GetParameterDescription(parameter)
	if parameter == nil then return "" end
	return parameter.Description or CAI_Lookup(parameter.RawDescription) or ""
end

local function CAI_DoLeftClick(control, fallback)
	if control and control.DoLeftClick then
		control:DoLeftClick()
	elseif fallback then
		fallback()
	end
end

local function CAI_GetPlayerTypeLabel(playerID)
	local cfg = PlayerConfigurations[playerID]
	if cfg == nil then return "" end
	local slotStatus = cfg:GetSlotStatus()
	if slotStatus == SlotStatus.SS_OBSERVER then
		return CAI_Lookup("LOC_CAI_STAGING_OBSERVER")
	elseif slotStatus == SlotStatus.SS_COMPUTER then
		return CAI_Lookup("LOC_SLOTTYPE_AI")
	elseif slotStatus == SlotStatus.SS_TAKEN then
		return CAI_Lookup("LOC_SLOTTYPE_HUMAN")
	elseif slotStatus == SlotStatus.SS_OPEN then
		return CAI_Lookup("LOC_SLOTTYPE_OPEN")
	elseif slotStatus == SlotStatus.SS_CLOSED then
		return CAI_Lookup("LOC_SLOTTYPE_CLOSED")
	end
	return ""
end

local function CAI_GetRoleStatus(entry)
	local seen = {}
	local texts = {
		CAI_ControlText(entry and entry.PlayerStatus),
		CAI_ControlText(entry and entry.AlternateStatus),
	}
	for _, text in ipairs(texts) do
		if text ~= "" and not seen[text] then
			seen[text] = true
			return text
		end
	end
	return ""
end

local function CAI_GetPlayerName(playerID, entry)
	local candidates = {
		entry and entry.PlayerName,
		entry and entry.AlternateName,
	}
	for _, control in ipairs(candidates) do
		local text = CAI_ControlText(control)
		if text ~= "" and not CAI_IsHidden(control) then
			return text
		end
	end
	local cfg = PlayerConfigurations[playerID]
	return cfg and CAI_Lookup(cfg:GetPlayerName()) or CAI_Lookup("LOC_CAI_STAGING_SLOT", playerID + 1)
end

local function CAI_GetReadyStatus(playerID, entry)
	local status = CAI_ControlText(entry and entry.StatusLabel)
	if status ~= "" and not CAI_IsHidden(entry and entry.StatusLabel) then
		return status
	end
	local cfg = PlayerConfigurations[playerID]
	if cfg and cfg:GetReady() then
		return ReadyStatusStr
	end
	return NotReadyStatusStr
end

local function CAI_GetSlotLabel(playerID, entry)
	local roleStatus = CAI_GetRoleStatus(entry)
	if GameConfiguration.IsHotseat() then
		if roleStatus ~= "" then
			return CAI_Lookup("LOC_CAI_STAGING_SLOT_LABEL_WITH_ROLE", CAI_GetPlayerName(playerID, entry), CAI_GetPlayerTypeLabel(playerID), roleStatus)
		end
		return CAI_Lookup("LOC_CAI_STAGING_SLOT_LABEL_SIMPLE", CAI_GetPlayerName(playerID, entry), CAI_GetPlayerTypeLabel(playerID))
	end
	if roleStatus ~= "" then
		return CAI_Lookup("LOC_CAI_STAGING_SLOT_LABEL_WITH_STATUS", CAI_GetPlayerName(playerID, entry), CAI_GetReadyStatus(playerID, entry), CAI_GetPlayerTypeLabel(playerID), roleStatus)
	end
	return CAI_Lookup("LOC_CAI_STAGING_SLOT_LABEL", CAI_GetPlayerName(playerID, entry), CAI_GetReadyStatus(playerID, entry), CAI_GetPlayerTypeLabel(playerID))
end

local function CAI_GetPullText(pullDown)
	if pullDown and pullDown.GetButton then
		local button = pullDown:GetButton()
		if button then
			local scrollText = button.GetParent and button:GetParent()
			scrollText = scrollText and scrollText.ScrollText
			local scrolled = CAI_ControlText(scrollText)
			if scrolled ~= "" then return scrolled end
			local textControl = button.GetTextControl and button:GetTextControl()
			local text = CAI_ControlText(textControl)
			if text ~= "" then return text end
			return CAI_ControlText(button)
		end
	end
	return ""
end

local CAI_GetPlayerParameter
local CAI_SetPlayerParameter

local CAI_UniqueTypeKeys = {
	{ prefix = "ICON_UNIT_", singular = "LOC_CAI_UNIQUE_UNIT", plural = "LOC_CAI_UNIQUE_UNITS" },
	{ prefix = "ICON_BUILDING_", singular = "LOC_CAI_UNIQUE_BUILDING", plural = "LOC_CAI_UNIQUE_BUILDINGS" },
	{ prefix = "ICON_DISTRICT_", singular = "LOC_CAI_UNIQUE_DISTRICT", plural = "LOC_CAI_UNIQUE_DISTRICTS" },
	{ prefix = "ICON_IMPROVEMENT_", singular = "LOC_CAI_UNIQUE_IMPROVEMENT", plural = "LOC_CAI_UNIQUE_IMPROVEMENTS" },
}

local function CAI_GetUniqueTypeIndex(icon)
	if not icon then return nil end
	for i, entry in ipairs(CAI_UniqueTypeKeys) do
		if string.find(icon, entry.prefix) then return i end
	end
	return nil
end

local function CAI_GetLeaderTooltip(domain, leaderType)
	if not domain or not leaderType then return "" end
	if leaderType == "RANDOM" or leaderType == "RANDOM_POOL1" or leaderType == "RANDOM_POOL2" then
		return ""
	end
	local info = GetPlayerInfo(domain, leaderType)
	if not info then return "" end

	local parts = {}
	if info.CivilizationAbility then
		table.insert(parts, Locale.Lookup("LOC_CAI_ADVANCED_SETUP_CIV_ABILITY") .. ": "
			.. Locale.Lookup(info.CivilizationAbility.Name) .. ": "
			.. Locale.Lookup(info.CivilizationAbility.Description))
	end
	if info.LeaderAbility then
		table.insert(parts, Locale.Lookup("LOC_CAI_ADVANCED_SETUP_LEADER_ABILITY") .. ": "
			.. Locale.Lookup(info.LeaderAbility.Name) .. ": "
			.. Locale.Lookup(info.LeaderAbility.Description))
	end
	if info.Uniques then
		local grouped = {}
		local ungrouped = {}
		for _, unique in ipairs(info.Uniques) do
			local typeIdx = CAI_GetUniqueTypeIndex(unique.Icon)
			if typeIdx then
				if not grouped[typeIdx] then grouped[typeIdx] = {} end
				table.insert(grouped[typeIdx], unique)
			else
				table.insert(ungrouped, unique)
			end
		end
		for i, entry in ipairs(CAI_UniqueTypeKeys) do
			if grouped[i] then
				local headerKey = #grouped[i] > 1 and entry.plural or entry.singular
				local items = {}
				for _, unique in ipairs(grouped[i]) do
					table.insert(items, Locale.Lookup(unique.Name) .. ": " .. Locale.Lookup(unique.Description))
				end
				table.insert(parts, Locale.Lookup(headerKey) .. "[NEWLINE]" .. table.concat(items, "[NEWLINE]"))
			end
		end
		for _, unique in ipairs(ungrouped) do
			table.insert(parts, Locale.Lookup(unique.Name) .. ": " .. Locale.Lookup(unique.Description))
		end
	end
	return table.concat(parts, "[NEWLINE]")
end

local function CAI_GetLeaderLabel(playerID)
	local parameter = CAI_GetPlayerParameter(playerID, "PlayerLeader")
	local value = parameter and parameter.Value
	if not value then return "" end
	local label = value.Name or ""
	local info = value.Domain and value.Value and GetPlayerInfo(value.Domain, value.Value, playerID)
	if info and info.CivilizationName then
		label = label .. ", " .. Locale.Lookup(info.CivilizationName)
	end
	return label
end

local function CAI_GetTeamLabel(playerID)
	local cfg = PlayerConfigurations[playerID]
	if not cfg then return "" end
	local teamID = cfg:GetTeam()
	if teamID == nil then return "" end
	if GameConfiguration.GetGameState() == GameStateTypes.GAMESTATE_LAUNCHED and GameConfiguration.GetTeamPlayerCount(teamID) <= 1 then
		teamID = TeamTypes.NO_TEAM
	end
	if teamID == TeamTypes.NO_TEAM then
		return GameConfiguration.GetTeamName(teamID)
	end
	return Locale.Lookup("LOC_WORLD_RANKINGS_TEAM", teamID + 1)
end

local CAI_HasColorConflictForTeam
local CAI_HasColorConflict
local CAI_GetColorSelectionColors
local CAI_GetColorOptionTooltip
local CAI_GetColorTooltip

local function CAI_BuildColorOptions(playerID)
	local options = {}
	local selectedIndex = 0
	local leaderParam = CAI_GetPlayerParameter(playerID, "PlayerLeader")
	local colorParam = CAI_GetPlayerParameter(playerID, "PlayerColorAlternate")
	local leaderValue = leaderParam and leaderParam.Value
	if not leaderValue or not leaderValue.Domain or not leaderValue.Value then
		return options, selectedIndex
	end
	local icons = GetPlayerIcons(leaderValue.Domain, leaderValue.Value)
	if not icons or not icons.PlayerColor then
		return options, selectedIndex
	end
	local currentValue = colorParam and colorParam.Value or 0
	for j = 0, 3 do
		local backColor, frontColor = UI.GetPlayerColorValues(icons.PlayerColor, j)
		if backColor and frontColor and backColor ~= 0 and frontColor ~= 0 then
			table.insert(options, {
				label = Locale.Lookup("LOC_CAI_COLOR") .. " " .. tostring(j + 1),
				tooltip = CAI_GetColorOptionTooltip(playerID, j),
				value = j,
			})
			if j == currentValue then
				selectedIndex = #options
			end
		end
	end
	if selectedIndex == 0 and #options > 0 then
		selectedIndex = 1
	end
	return options, selectedIndex
end

local function CAI_GetColorLabel(playerID)
	local options, selectedIndex = CAI_BuildColorOptions(playerID)
	if selectedIndex > 0 and options[selectedIndex] then
		return options[selectedIndex].label
	end
	return ""
end

CAI_HasColorConflictForTeam = function(playerID, myTeam)
	if myTeam == nil then
		return false
	end
	for otherPlayerID, otherTeam in pairs(m_teamColors) do
		if otherPlayerID ~= playerID and otherTeam and UI.ArePlayerColorsConflicting(otherTeam, myTeam) then
			return true
		end
	end
	return false
end

CAI_HasColorConflict = function(playerID)
	return CAI_HasColorConflictForTeam(playerID, m_teamColors[playerID])
end

CAI_GetColorSelectionColors = function(playerID, value)
	local leaderParam = CAI_GetPlayerParameter(playerID, "PlayerLeader")
	local leaderValue = leaderParam and leaderParam.Value
	if not leaderValue or not leaderValue.Domain or not leaderValue.Value then
		return nil
	end
	local icons = GetPlayerIcons(leaderValue.Domain, leaderValue.Value)
	if not icons or not icons.PlayerColor then
		return nil
	end
	local primary, secondary = UI.GetPlayerColorValues(icons.PlayerColor, value)
	if primary and secondary and primary ~= 0 and secondary ~= 0 then
		return { primary, secondary }
	end
	return nil
end

CAI_GetColorOptionTooltip = function(playerID, value)
	return ""
end

CAI_GetColorTooltip = function(playerID, entry)
	local tooltip = CAI_ControlTooltip(entry and entry.ColorPullDown)
	if CAI_HasColorConflict(playerID) then
		tooltip = CAI_AppendUniqueLine(tooltip, CAI_Lookup("LOC_SETUP_PLAYER_COLOR_COLLISION"))
	end
	return tooltip
end

local function CAI_GetTeamTooltip(playerID)
	local cfg = PlayerConfigurations[playerID]
	if cfg == nil then return "" end
	return ""
end

local function CAI_GetLeaderSelectionTooltip(playerID)
	local parameter = CAI_GetPlayerParameter(playerID, "PlayerLeader")
	local value = parameter and parameter.Value
	if value == nil then return "" end
	local tooltip = CAI_GetLeaderTooltip(value.Domain, value.Value)
	return CAI_GetExplanationTooltip(tooltip, CAI_GetLeaderLabel(playerID))
end

local function CAI_GetSlotTypeTooltip(playerID)
	local cfg = PlayerConfigurations[playerID]
	if not cfg then return "" end
	local currentStatus = cfg:GetSlotStatus()
	for _, data in ipairs(g_slotTypeData) do
		if data.slotStatus == currentStatus then
			if GameConfiguration.IsPlayByCloud() and data.slotStatus == SlotStatus.SS_OPEN then
				return CAI_Lookup("LOC_SLOTTYPE_HUMANREQ_TT")
			end
			return data.tooltip and CAI_Lookup(data.tooltip) or ""
		end
	end
	return ""
end

local function CAI_CanShowSwapButton(playerID)
	local cfg = PlayerConfigurations[playerID]
	if cfg == nil then return false end
	return cfg:GetSlotStatus() ~= SlotStatus.SS_CLOSED
		and not cfg:IsLocked()
		and not GameConfiguration.IsHotseat()
		and not GameConfiguration.IsPlayByCloud()
		and not GameConfiguration.IsMatchMaking()
		and playerID ~= Network.GetLocalPlayerID()
end

local function CAI_GetSwapTooltip(playerID)
	local cfg = PlayerConfigurations[playerID]
	if cfg and cfg:GetSlotStatus() == SlotStatus.SS_TAKEN then
		return CAI_Lookup("TXT_KEY_MP_SWAP_WITH_PLAYER_BUTTON_TT")
	end
	return CAI_Lookup("TXT_KEY_MP_SWAP_BUTTON_TT")
end

local function CAI_IsHumanSwapTarget(playerID)
	local cfg = PlayerConfigurations[playerID]
	return cfg ~= nil and cfg:GetSlotStatus() == SlotStatus.SS_TAKEN
end

local function CAI_IsSwapRequestedForPlayer(playerID)
	if not CAI_IsHumanSwapTarget(playerID) then return false end
	local localPlayerID = Network.GetLocalPlayerID()
	if localPlayerID == nil or localPlayerID == NetPlayerTypes.INVALID_PLAYERID then return false end
	return Network.GetChangePlayerID(localPlayerID) == playerID
end

local function CAI_GetSwapButtonLabel(playerID)
	if not CAI_IsHumanSwapTarget(playerID) then
		return CAI_Lookup("LOC_MP_SWAP_PLAYER")
	end
	if CAI_IsSwapRequestedForPlayer(playerID) then
		return CAI_Lookup("LOC_CAI_STAGING_SWAP_ON")
	end
	return CAI_Lookup("LOC_CAI_STAGING_SWAP_OFF")
end

local function CAI_GetSlotTooltip(playerID, entry)
	local lines = {}
	CAI_AddDetail(lines, "LOC_CAI_STAGING_CIV_LEADER", CAI_GetLeaderLabel(playerID))
	CAI_AddDetail(lines, "LOC_CAI_STAGING_TEAM", CAI_GetTeamLabel(playerID))
	CAI_AddDetail(lines, "LOC_CAI_STAGING_DIFFICULTY", CAI_GetPullText(entry and entry.HandicapPullDown))
	CAI_AddDetail(lines, "LOC_CAI_COLOR", CAI_GetColorLabel(playerID))
	local details = CAI_JoinLines(lines)
	local label = CAI_GetSlotLabel(playerID, entry)
	local rowTooltip
	if GameConfiguration.IsHotseat() then
		rowTooltip = CAI_GetExplanationTooltip(CAI_ControlTooltip(entry and entry.StatusLabel), label)
	else
		local status = CAI_GetReadyStatus(playerID, entry)
		rowTooltip = CAI_GetExplanationTooltip(CAI_ControlTooltip(entry and entry.StatusLabel), label, status)
	end
	return CAI_AppendUniqueLine(details, rowTooltip)
end

local function CAI_IsSlotEditable(entry)
	if entry == nil then return false end
	local controls = {
		entry.SlotTypePulldown,
		entry.AlternateSlotTypePulldown,
		entry.TeamPullDown,
		entry.PlayerPullDown,
		entry.ColorPullDown,
		entry.HandicapPullDown,
		entry.KickButton,
		entry.HotseatEditButton,
	}
	for _, control in ipairs(controls) do
		if control and not CAI_IsHidden(control) and not CAI_IsDisabled(control) then
			return true
		end
	end
	return false
end

CAI_GetPlayerParameter = function(playerID, paramId)
	local parameters = GetPlayerParameters(playerID)
	return parameters and parameters.Parameters and parameters.Parameters[paramId]
end

CAI_SetPlayerParameter = function(playerID, paramId, value)
	local parameters = GetPlayerParameters(playerID)
	local parameter = parameters and parameters.Parameters and parameters.Parameters[paramId]
	if parameter then
		parameters:SetParameterValue(parameter, value)
		PlayerConfigurationValuesToUI(playerID)
		UpdatePlayerEntry(playerID)
		CAI_RequestPlayerListRefresh(false)
	end
end

local function CAI_ValueMatches(a, b)
	if a == b then return true end
	if type(a) ~= "table" or type(b) ~= "table" then return false end
	if a.QueryId ~= nil or b.QueryId ~= nil then
		return a.QueryId == b.QueryId and a.QueryIndex == b.QueryIndex
	end
	return a.Value == b.Value
end

local function CAI_MakeDropdown(id, labelTag, tooltipFn, hiddenFn, disabledFn, optionsFn, setterFn)
	local widget = mgr:CreateWidget(id, "Dropdown", {
		Label = function() return CAI_Lookup(labelTag) end,
		Tooltip = tooltipFn,
		HiddenPredicate = hiddenFn,
		DisabledPredicate = disabledFn,
		FocusKey = id,
	})
	widget:SetFocusSound(HOVER_SOUND)
	local function refreshOptions()
		local options, selectedIndex = optionsFn()
		widget:SetOptions(options)
		if selectedIndex and selectedIndex > 0 then
			widget:SetSelectedIndex(selectedIndex, true)
		end
	end
	refreshOptions()
	local baseOpen = widget.Open
	function widget:Open()
		refreshOptions()
		return baseOpen(self)
	end
	widget:SetValueSetter(function(_, value)
		setterFn(value)
	end)
	return widget
end

local function CAI_BuildParameterOptions(parameter)
	local options = {}
	local selectedIndex = 0
	if parameter and parameter.Values then
		for i, value in ipairs(parameter.Values) do
			local invalidReason = CAI_GetValueInvalidReason(value)
			table.insert(options, {
				label = CAI_FormatInvalidLabel(value.Name or "", invalidReason),
				tooltip = value.Description or CAI_Lookup(value.RawDescription) or "",
				value = value,
			})
			if selectedIndex == 0 and CAI_ValueMatches(value, parameter.Value) then
				selectedIndex = i
			end
		end
	end
	if selectedIndex == 0 and #options > 0 then selectedIndex = 1 end
	return options, selectedIndex
end

local function CAI_BuildLeaderOptions(playerID)
	local parameter = CAI_GetPlayerParameter(playerID, "PlayerLeader")
	local options = {}
	local selectedIndex = 0
	if parameter and parameter.Values then
		for i, value in ipairs(parameter.Values) do
			local label = value.Name or ""
			local info = value.Domain and value.Value and GetPlayerInfo(value.Domain, value.Value, playerID)
			if info and info.CivilizationName then
				label = label .. ", " .. Locale.Lookup(info.CivilizationName)
			end
			local invalidReason = CAI_GetValueInvalidReason(value)
			table.insert(options, {
				label = CAI_FormatInvalidLabel(label, invalidReason),
				tooltip = CAI_GetLeaderTooltip(value.Domain, value.Value),
				value = value,
			})
			if selectedIndex == 0 and parameter.Value and value.Value == parameter.Value.Value then
				selectedIndex = i
			end
		end
	end
	if selectedIndex == 0 and #options > 0 then selectedIndex = 1 end
	return options, selectedIndex
end

local function CAI_MakeSlotTypeDropdown(playerID, entry)
	local function buildOptions()
		local options = {}
		local selectedIndex = 0
		local cfg = PlayerConfigurations[playerID]
		for id, data in ipairs(g_slotTypeData) do
			local hotseatOnlyCheck = (GameConfiguration.IsHotseat() and data.hotseatAllowed) or (not GameConfiguration.IsHotseat() and not data.hotseatOnly)
			local show = data.slotStatus ~= -1 and hotseatOnlyCheck and CheckShowSlotButton(data, playerID)
			if show then
				table.insert(options, {
					label = CAI_Lookup(GameConfiguration.IsPlayByCloud() and data.slotStatus == SlotStatus.SS_OPEN and "LOC_SLOTTYPE_HUMANREQ" or data.name),
					tooltip = data.tooltip and CAI_Lookup(data.tooltip) or "",
					value = id,
				})
				if cfg and data.slotStatus == cfg:GetSlotStatus() then
					selectedIndex = #options
				end
			end
		end
		if #options == 0 then
			table.insert(options, {
				label = CAI_Lookup("LOC_CAI_STAGING_CHOOSE_SLOT_TYPE"),
				tooltip = "",
				value = nil,
				disabledPredicate = function() return true end,
			})
			selectedIndex = 1
		elseif selectedIndex == 0 then
			selectedIndex = 1
		end
		return options, selectedIndex
	end
	return CAI_MakeDropdown("CAIStagingRoom_SlotType_" .. playerID, "LOC_CAI_STAGING_SLOT_TYPE",
		function() return CAI_GetSlotTypeTooltip(playerID) end,
		function() return CAI_IsHidden(entry.SlotTypePulldown) and CAI_IsHidden(entry.AlternateSlotTypePulldown) end,
		function()
			local options = select(1, buildOptions())
			local hasRealOption = false
			for _, option in ipairs(options) do
				if option.value ~= nil then
					hasRealOption = true
					break
				end
			end
			return (CAI_IsDisabled(entry.SlotTypePulldown) and CAI_IsDisabled(entry.AlternateSlotTypePulldown))
				or not hasRealOption
		end,
		buildOptions,
		function(id)
			if id ~= nil then
				OnSlotType(playerID, id)
			end
		end)
end

local function CAI_MakeTeamDropdown(playerID, entry)
	return CAI_MakeDropdown("CAIStagingRoom_Team_" .. playerID, "LOC_CAI_STAGING_TEAM",
		function() return CAI_GetTeamTooltip(playerID) end,
		function() return CAI_IsHidden(entry.TeamPullDown) end,
		function() return CAI_IsDisabled(entry.TeamPullDown) end,
		function()
			local options = {}
			local selectedIndex = 0
			local cfg = PlayerConfigurations[playerID]
			local teamCounts = {}
			GetTeamCounts(teamCounts)
			local noTeams = GameConfiguration.GetValue("NO_TEAMS")

			table.insert(options, {
				label = GameConfiguration.GetTeamName(TeamTypes.NO_TEAM),
				value = TeamTypes.NO_TEAM,
			})
			if cfg and cfg:GetTeam() == TeamTypes.NO_TEAM then
				selectedIndex = 1
			end

			if not noTeams then
				local teams = {}
				for teamID, _ in pairs(teamCounts) do
					if teamID ~= TeamTypes.NO_TEAM then
						table.insert(teams, {
							teamID = teamID,
							label = Locale.Lookup("LOC_WORLD_RANKINGS_TEAM", teamID + 1),
						})
					end
				end

				local newTeamID = 0
				while teamCounts[newTeamID] ~= nil do
					newTeamID = newTeamID + 1
				end
				table.insert(teams, {
					teamID = newTeamID,
					label = Locale.Lookup("LOC_WORLD_RANKINGS_TEAM", newTeamID + 1),
				})

				table.sort(teams, function(a, b)
					return a.teamID < b.teamID
				end)

				for _, team in ipairs(teams) do
					table.insert(options, {
						label = team.label,
						value = team.teamID,
					})
					if cfg and cfg:GetTeam() == team.teamID then
						selectedIndex = #options
					end
				end
			end

			if selectedIndex == 0 and #options > 0 then
				selectedIndex = 1
			end
			return options, selectedIndex
		end,
		function(teamID)
			OnTeamPull(playerID, teamID)
		end)
end

local function CAI_MakeLeaderDropdown(playerID, entry)
	return CAI_MakeDropdown("CAIStagingRoom_PlayerLeader_" .. playerID, "LOC_CAI_STAGING_CIV_LEADER",
		function() return CAI_GetLeaderSelectionTooltip(playerID) end,
		function() return CAI_IsHidden(entry.PlayerPullDown) end,
		function() return CAI_IsDisabled(entry.PlayerPullDown) end,
		function()
			return CAI_BuildLeaderOptions(playerID)
		end,
		function(value)
			CAI_SetPlayerParameter(playerID, "PlayerLeader", value)
			local colorParam = CAI_GetPlayerParameter(playerID, "PlayerColorAlternate")
			if colorParam then
				CAI_SetPlayerParameter(playerID, "PlayerColorAlternate", 0)
			end
		end)
end

local function CAI_MakeColorDropdown(playerID, entry)
	return CAI_MakeDropdown("CAIStagingRoom_PlayerColor_" .. playerID, "LOC_CAI_COLOR",
		function() return CAI_GetColorTooltip(playerID, entry) end,
		function() return CAI_IsHidden(entry.ColorPullDown) end,
		function() return CAI_IsDisabled(entry.ColorPullDown) end,
		function()
			return CAI_BuildColorOptions(playerID)
		end,
		function(value)
			local leaderParam = CAI_GetPlayerParameter(playerID, "PlayerLeader")
			local leaderValue = leaderParam and leaderParam.Value
			local icons = leaderValue and GetPlayerIcons(leaderValue.Domain, leaderValue.Value)
			if icons and icons.PlayerColor then
				local primary, secondary = UI.GetPlayerColorValues(icons.PlayerColor, value)
				m_teamColors[playerID] = {primary, secondary}
			end
			CAI_SetPlayerParameter(playerID, "PlayerColorAlternate", value)
		end)
end

local function CAI_MakeParameterDropdown(playerID, entry, paramId, labelTag, control)
	return CAI_MakeDropdown("CAIStagingRoom_" .. paramId .. "_" .. playerID, labelTag,
		function()
			local parameter = CAI_GetPlayerParameter(playerID, paramId)
			local tooltip = CAI_GetParameterDescription(parameter)
			local value = parameter and parameter.Value and parameter.Value.Name or ""
			return CAI_GetExplanationTooltip(tooltip, value)
		end,
		function() return CAI_IsHidden(control) end,
		function() return CAI_IsDisabled(control) end,
		function()
			return CAI_BuildParameterOptions(CAI_GetPlayerParameter(playerID, paramId))
		end,
		function(value)
			CAI_SetPlayerParameter(playerID, paramId, value)
			if paramId == "PlayerLeader" then
				local colorParam = CAI_GetPlayerParameter(playerID, "PlayerColorAlternate")
				if colorParam then
					CAI_SetPlayerParameter(playerID, "PlayerColorAlternate", 0)
				end
			end
		end)
end

local function CAI_MakeSlotButton(id, labelTag, control, fallback)
	local widget = mgr:CreateWidget(id, "Button", {
		Label = function()
			local text = CAI_ControlText(control)
			if text ~= "" then return text end
			return CAI_Lookup(labelTag)
		end,
		Tooltip = function() return CAI_ControlTooltip(control) end,
		HiddenPredicate = function() return CAI_IsHidden(control) end,
		DisabledPredicate = function() return CAI_IsDisabled(control) end,
		FocusKey = id,
	})
	widget:SetFocusSound(HOVER_SOUND)
	widget:On("activate", function()
		CAI_DoLeftClick(control, fallback)
	end)
	return widget
end

local function CAI_MakeSwapButton(playerID)
	local widget = mgr:CreateWidget("CAIStagingRoom_Swap_" .. playerID, "Button", {
		Label = function() return CAI_GetSwapButtonLabel(playerID) end,
		Tooltip = function() return CAI_GetSwapTooltip(playerID) end,
		HiddenPredicate = function() return not CAI_CanShowSwapButton(playerID) end,
		FocusKey = "CAIStagingRoom_Swap_" .. playerID,
	})
	widget:SetFocusSound(HOVER_SOUND)
	widget:On("activate", function()
		local localPlayerID = Network.GetLocalPlayerID()
		local oldDesiredPlayerID = localPlayerID ~= nil and localPlayerID ~= NetPlayerTypes.INVALID_PLAYERID
			and Network.GetChangePlayerID(localPlayerID)
			or NetPlayerTypes.INVALID_PLAYERID
		local newDesiredPlayerID = playerID
		if oldDesiredPlayerID == newDesiredPlayerID then
			newDesiredPlayerID = NetPlayerTypes.INVALID_PLAYERID
		end
		OnSwapButton(playerID)
		if CAI_IsHumanSwapTarget(playerID) then
			CAI_RequestPlayerListRefresh(false)
			Speak(CAI_Lookup(newDesiredPlayerID == NetPlayerTypes.INVALID_PLAYERID and "LOC_CAI_STAGING_SWAP_OFF" or "LOC_CAI_STAGING_SWAP_ON"), false)
		end
	end)
	return widget
end

local function CAI_BuildSlotChildren(parent, playerID, entry)
	parent:AddChild(CAI_MakeSlotTypeDropdown(playerID, entry))
	parent:AddChild(CAI_MakeTeamDropdown(playerID, entry))
	parent:AddChild(CAI_MakeLeaderDropdown(playerID, entry))
	parent:AddChild(CAI_MakeParameterDropdown(playerID, entry, "PlayerDifficulty", "LOC_CAI_STAGING_DIFFICULTY", entry.HandicapPullDown))
	parent:AddChild(CAI_MakeColorDropdown(playerID, entry))
	parent:AddChild(CAI_MakeSwapButton(playerID))
	parent:AddChild(CAI_MakeSlotButton("CAIStagingRoom_HotseatEdit_" .. playerID, "LOC_CAI_STAGING_HOTSEAT_EDIT", entry.HotseatEditButton, function()
		UIManager:PushModal(Controls.EditHotseatPlayer, true)
		LuaEvents.StagingRoom_SetPlayerID(playerID)
	end))
	parent:AddChild(CAI_MakeSlotButton("CAIStagingRoom_Kick_" .. playerID, "LOC_MP_KICK_PLAYER", entry.KickButton, function() OnKickButton(playerID) end))
end

local function CAI_RebuildPlayerList()
	if not CAI_PlayerList then return end
	local capture = mgr:CaptureFocusKey(CAI_PlayerList)
	CAI_PlayerList:ClearChildren()
	local addPlayerEntry = nil
	for _, playerID in ipairs(GameConfiguration.GetMultiplayerPlayerIDs()) do
		local entry = g_PlayerEntries[playerID]
		if entry and entry.Root and not entry.Root:IsHidden() then
			if entry.AddPlayerButton and not CAI_IsHidden(entry.AddPlayerButton) then
				addPlayerEntry = { playerID = playerID, entry = entry }
			end
			if CAI_IsSlotEditable(entry) then
				local slot = mgr:CreateWidget("CAIStagingRoom_Player_" .. playerID, "SubMenu", {
					Label = function() return CAI_GetSlotLabel(playerID, entry) end,
					Tooltip = function() return CAI_GetSlotTooltip(playerID, entry) end,
					FocusKey = "slot:" .. playerID,
				})
				slot:SetFocusSound(HOVER_SOUND)
				CAI_BuildSlotChildren(slot, playerID, entry)
				CAI_PlayerList:AddChild(slot)
			else
				local item = mgr:CreateWidget("CAIStagingRoom_Player_" .. playerID, "MenuItem", {
					Label = function() return CAI_GetSlotLabel(playerID, entry) end,
					Tooltip = function() return CAI_GetSlotTooltip(playerID, entry) end,
					FocusKey = "slot:" .. playerID,
				})
				item:SetFocusSound(HOVER_SOUND)
				CAI_PlayerList:AddChild(item)
			end
		end
	end
	if addPlayerEntry then
		local playerID = addPlayerEntry.playerID
		local entry = addPlayerEntry.entry
		local addPlayer = mgr:CreateWidget("CAIStagingRoom_AddPlayerBottom", "Button", {
			Label = function()
				local text = CAI_ControlText(entry.AddPlayerButton)
				if text ~= "" then return text end
				return CAI_Lookup("LOC_CAI_STAGING_ADD_PLAYER")
			end,
			Tooltip = function()
				local tooltip = CAI_ControlTooltip(entry.AddPlayerButton)
				if tooltip ~= "" then return tooltip end
				return ""
			end,
			FocusKey = "action:addPlayer",
		})
		addPlayer:SetFocusSound(HOVER_SOUND)
		addPlayer:On("activate", function() OnAddPlayer(playerID) end)
		CAI_PlayerList:AddChild(addPlayer)
	end
	mgr:RestoreFocus(CAI_PlayerList, capture)
end

local function CAI_FlushDeferredRefresh()
	ContextPtr:ClearUpdate()
	if CAI_ChatTargetRefreshQueued then
		CAI_ChatTargetRefreshQueued = false
		if CAI_Panel then
			CAI_RebuildChatTarget()
		end
	end
	if CAI_PlayerListRefreshQueued then
		CAI_PlayerListRefreshQueued = false
		if CAI_Panel then
			CAI_RebuildPlayerList()
		end
	end
	if CAI_PendingSwapFeedback then
		local feedback = CAI_PendingSwapFeedback
		local focusKey = CAI_PendingSwapFocusKey
		local focusWithinList = CAI_PendingSwapFocusWithinList
		CAI_PendingSwapFeedback = nil
		CAI_PendingSwapFocusKey = nil
		CAI_PendingSwapFocusWithinList = false
		Speak(feedback, false)
		if focusWithinList and CAI_PlayerList and focusKey and mgr and mgr.FindByFocusKey then
			local target = mgr:FindByFocusKey(CAI_PlayerList, focusKey)
			if target then
				mgr:SetFocus(target)
			end
		end
	end
end

CAI_RequestPlayerListRefresh = function(refreshChatTarget)
	if not CAI_Panel then return end
	CAI_PlayerListRefreshQueued = true
	if refreshChatTarget then
		CAI_ChatTargetRefreshQueued = true
	end
	ContextPtr:SetUpdate(CAI_FlushDeferredRefresh)
end

local CAI_GetReadyButtonStatus

local function CAI_GetReadyButtonLabel()
	if GameConfiguration.IsHotseat() then
		return CAI_GetReadyButtonStatus()
	end
	if Controls.ReadyCheck:IsSelected() then return Locale.Lookup("LOC_CAI_STAGING_UNREADY") end
	return Locale.Lookup("LOC_READY_BUTTON")
end

CAI_GetReadyButtonStatus = function()
	local buttonText = CAI_ControlText(Controls.ReadyButton)
	if buttonText ~= "" and not CAI_IsHidden(Controls.ReadyButton) then return buttonText end
	local labelText = CAI_ControlText(Controls.StartLabel)
	if labelText ~= "" then return labelText end
	return CAI_ControlText(Controls.ReadyCheck)
end

local function CAI_GetReadyButtonTooltip()
	local status = CAI_GetReadyButtonStatus()
	local tooltip = CAI_ControlTooltip(Controls.ReadyButton)
	if tooltip ~= "" and tooltip ~= status then
		if status ~= "" and m_countdownType ~= CountdownTypes.None then
			return CAI_Lookup("LOC_CAI_STAGING_READY_TOOLTIP_WITH_STATUS", status, tooltip)
		end
		return CAI_GetExplanationTooltip(tooltip, status)
	end
	tooltip = CAI_ControlTooltip(Controls.ReadyCheck)
	if tooltip ~= "" and tooltip ~= status then
		if status ~= "" and m_countdownType ~= CountdownTypes.None then
			return CAI_Lookup("LOC_CAI_STAGING_READY_TOOLTIP_WITH_STATUS", status, tooltip)
		end
		return CAI_GetExplanationTooltip(tooltip, status)
	end
	if GameConfiguration.IsHotseat() then
		return ""
	end
	if status ~= "" and m_countdownType ~= CountdownTypes.None then
		return status
	end
	return ""
end

local function CAI_GetReadyCountdownSpeech()
	if m_countdownType == CountdownTypes.None then return "" end
	local buttonText = CAI_ControlText(Controls.ReadyButton)
	if buttonText ~= "" and not CAI_IsHidden(Controls.ReadyButton) then
		return buttonText
	end
	return ""
end

local function CAI_RefreshChatHistory()
	if CAI_ChatHistory then
		local capture = mgr:CaptureFocusKey(CAI_ChatHistory)
		CAI_ChatHistory:ClearChildren()
		for i, line in ipairs(CAI_ChatLines) do
			CAI_ChatHistory:AddChild(mgr:CreateWidget("CAIStagingRoom_ChatLine_" .. tostring(i), "StaticText", {
				Label = function() return line end,
				FocusKey = "chat:history:" .. tostring(i),
			}))
		end
		mgr:RestoreFocus(CAI_ChatHistory, capture)
	end
end

local function CAI_RecordChatLine(line)
	if line == nil or line == "" then return nil end
	table.insert(CAI_ChatLines, line)
	if #CAI_ChatLines > 100 then
		table.remove(CAI_ChatLines, 1)
	end
	return line
end

local function CAI_SpeakChatLine(line)
	local lines = CAI_SplitNewlines(line)
	if #lines > 1 then
		SpeakLines(lines, false)
	else
		Speak(line, false)
	end
end

local function CAI_RecordChat(fromPlayer, toPlayer, text, eTargetType)
	local fromConfig = PlayerConfigurations[fromPlayer]
	if not fromConfig then return end
	local playerName = CAI_Lookup(fromConfig:GetPlayerName())
	local prefix = playerName
	if eTargetType == ChatTargetTypes.CHATTARGET_PLAYER then
		local targetConfig = PlayerConfigurations[toPlayer]
		if targetConfig then
			prefix = CAI_Lookup("LOC_CAI_STAGING_CHAT_WHISPER", playerName, CAI_Lookup(targetConfig:GetPlayerName()))
		end
	elseif eTargetType == ChatTargetTypes.CHATTARGET_TEAM then
		prefix = CAI_Lookup("LOC_CAI_STAGING_CHAT_TEAM", playerName)
	end
	local line = CAI_Lookup("LOC_CAI_STAGING_CHAT_LINE", prefix, ParseChatText(text))
	return CAI_RecordChatLine(line)
end

local function CAI_RecordLocalChat(text)
	local localPlayerID = GetLocalPlayerID()
	return CAI_RecordChat(localPlayerID, GetNoPlayerTargetID(), text, ChatTargetTypes.CHATTARGET_ALL)
end

local function CAI_IsSystemChatMessage(text)
	return text == PlayerConnectedChatStr
		or text == PlayerDisconnectedChatStr
		or text == PlayerHostMigratedChatStr
		or text == PlayerKickedChatStr
end

local function CAI_GetChatInputTooltip()
	local tooltip = CAI_ControlTooltip(Controls.ChatEntry)
	if tooltip ~= "" then return tooltip end
	return CAI_Lookup("LOC_CHAT_HELP_COMMAND_HINT")
end

local function CAI_BuildChatTargetOptions()
	local options = {}
	local selectedIndex = 0
	local localPlayerID = GetLocalPlayerID()
	table.insert(options, { label = CAI_Lookup("LOC_DIPLO_TO_ALL"), tooltip = "", value = { targetType = ChatTargetTypes.CHATTARGET_ALL, targetID = GetNoPlayerTargetID() } })
	if m_playerTarget.targetType == ChatTargetTypes.CHATTARGET_ALL then selectedIndex = 1 end
	if localPlayerID ~= GetNoPlayerTargetID() then
		local localConfig = PlayerConfigurations[localPlayerID]
		local localTeam = localConfig and localConfig:GetTeam() or TeamTypes.NO_TEAM
		if localTeam ~= TeamTypes.NO_TEAM and GameConfiguration.GetTeamPlayerCount(localTeam, true) > 1 then
			table.insert(options, { label = CAI_Lookup("LOC_DIPLO_TO_TEAM"), tooltip = "", value = { targetType = ChatTargetTypes.CHATTARGET_TEAM, targetID = localTeam } })
			if m_playerTarget.targetType == ChatTargetTypes.CHATTARGET_TEAM then selectedIndex = #options end
		end
	end
	for _, playerID in ipairs(GameConfiguration.GetParticipatingPlayerIDs()) do
		local cfg = PlayerConfigurations[playerID]
		if playerID ~= localPlayerID and cfg and cfg:IsHuman() then
			table.insert(options, { label = CAI_Lookup("LOC_DIPLO_TO_PLAYER", cfg:GetPlayerName()), tooltip = "", value = { targetType = ChatTargetTypes.CHATTARGET_PLAYER, targetID = playerID } })
			if m_playerTarget.targetType == ChatTargetTypes.CHATTARGET_PLAYER and m_playerTarget.targetID == playerID then
				selectedIndex = #options
			end
		end
	end
	if selectedIndex == 0 and #options > 0 then selectedIndex = 1 end
	return options, selectedIndex
end

CAI_RebuildChatTarget = function()
	if not CAI_ChatTarget then return end
	local options, selectedIndex = CAI_BuildChatTargetOptions()
	CAI_ChatTarget:SetOptions(options)
	if selectedIndex > 0 then CAI_ChatTarget:SetSelectedIndex(selectedIndex, true) end
end

local function CAI_SyncChatTargetSelection()
	if not CAI_ChatTarget then return end

	local options, selectedIndex = CAI_BuildChatTargetOptions()
	if selectedIndex <= 0 then return end

	local currentIndex = CAI_ChatTarget:GetSelectedIndex()
	if currentIndex == selectedIndex then return end

	local currentOption = options[currentIndex]
	local currentValue = currentOption and currentOption.value or nil
	if currentValue
		and currentValue.targetType == m_playerTarget.targetType
		and currentValue.targetID == m_playerTarget.targetID then
		return
	end

	CAI_ChatTarget:SetSelectedIndex(selectedIndex, true)
end

local function CAI_RebuildGameSummary()
	if not CAI_GameSummary then return end
	local lines = {}
	CAI_AddDetail(lines, "LOC_CAI_STAGING_STATUS", CAI_ControlText(Controls.GameStateText))
	if not CAI_IsHidden(Controls.JoinCodeRoot) then
		CAI_AddDetail(lines, "LOC_STAGING_ROOM_JOIN_CODE", CAI_ControlText(Controls.JoinCodeText))
	end
	if g_GameParameters and g_GameParameters.Parameters then
		local params = {}
		for _, parameter in pairs(g_GameParameters.Parameters) do
			local control = g_GameParameters.Controls and g_GameParameters.Controls[parameter.ParameterId]
			local root = control and control.Control and control.Control.Root
			if parameter.Visible ~= false and root and not root:IsHidden() then
				table.insert(params, parameter)
			end
		end
		table.sort(params, function(a, b)
			if (a.SortIndex or 0) ~= (b.SortIndex or 0) then
				return (a.SortIndex or 0) < (b.SortIndex or 0)
			end
			return Locale.Compare(a.Name or "", b.Name or "") == -1
		end)
		for _, parameter in ipairs(params) do
			local control = g_GameParameters.Controls[parameter.ParameterId]
			local value = CAI_ControlText(control and control.Control and control.Control.Value)
			if value == "" then value = tostring(parameter.Value or parameter.DefaultValue or "") end
			local detail = value
			local invalidReason = CAI_GetParameterInvalidReason(parameter)
			local tooltip = control and control.Control and control.Control.Root and CAI_ControlTooltip(control.Control.Root) or ""
			local explanation = CAI_GetExplanationTooltip(tooltip, parameter.Name, value, invalidReason)
			if invalidReason ~= "" then
				detail = CAI_AppendUniqueLine(detail, invalidReason)
			end
			detail = CAI_AppendUniqueLine(detail, explanation)
			CAI_AddDetail(lines, parameter.Name, detail)
		end
	end
	local enabledMods = GameConfiguration.GetEnabledMods()
	if enabledMods and #enabledMods > 0 then
		for _, curMod in ipairs(enabledMods) do
			CAI_AddDetail(lines, "LOC_CAI_STAGING_ADDITIONAL_CONTENT", curMod.Title)
		end
	end
	CAI_GameSummary:SetText(CAI_JoinLines(lines), true)
end

local function CAI_MakeActionButton(id, labelTag, control, fallback, hiddenFn, opts)
	opts = opts or {}
	local labelControl = opts.LabelControl or control
	local tooltipControl = opts.TooltipControl or control
	local button = mgr:CreateWidget(id, "Button", {
		Label = function()
			local text = CAI_ControlText(labelControl)
			if text ~= "" then return text end
			return CAI_Lookup(labelTag)
		end,
		Tooltip = function()
			local tooltip = CAI_ControlTooltip(tooltipControl)
			local label = CAI_ControlText(labelControl)
			if tooltip ~= "" and tooltip ~= label then return tooltip end
			if opts.TooltipTag then
				return CAI_Lookup(opts.TooltipTag)
			end
			return ""
		end,
		HiddenPredicate = hiddenFn or function() return CAI_IsHidden(control) end,
		DisabledPredicate = function() return CAI_IsDisabled(control) end,
		FocusKey = id,
	})
	button:SetFocusSound(HOVER_SOUND)
	button:On("activate", function()
		CAI_DoLeftClick(control, fallback)
	end)
	return button
end

local function CAI_GetFriendStatusText(friend)
	local status = friend.PlayingCiv and friend.RichPresence or "LOC_PRESENCE_ONLINE"
	return CAI_Lookup(status)
end

local function CAI_BuildFriendActionWidgets(friend, submenu)
	local bCanInvite = CanInviteFriends(false) and Network.HasSingleFriendInvite()
	local actions = {}
	local count = 0

	BuildFriendActionList(actions, bCanInvite and not IsFriendInGame(friend))
	for actionIndex, action in ipairs(actions) do
		local button = mgr:CreateWidget("CAIStagingRoom_FriendAction_" .. tostring(friend.ID) .. "_" .. tostring(actionIndex), "Button", {
			Label = function() return CAI_Lookup(action.name) end,
			Tooltip = function() return CAI_Lookup(action.tooltip) end,
			FocusKey = "friend:" .. tostring(friend.ID) .. ":action:" .. tostring(actionIndex),
		})
		button:SetFocusSound(HOVER_SOUND)
		button:On("activate", function()
			OnFriendPulldownCallback(friend.ID, action.action)
			if action.action == "invite" then
				Speak(CAI_Lookup("LOC_CAI_STAGING_INVITE_SENT"), false)
				CAI_RebuildFriendsList()
			end
		end)
		submenu:AddChild(button)
		count = count + 1
	end

	if count == 0 then
		submenu:AddChild(mgr:CreateWidget("CAIStagingRoom_FriendNoActions_" .. tostring(friend.ID), "StaticText", {
			Label = function() return CAI_Lookup("LOC_CAI_LOBBY_NO_FRIEND_ACTIONS") end,
			FocusKey = "friend:" .. tostring(friend.ID) .. ":none",
		}))
	end
end

local function CAI_RebuildFriendsList()
	if CAI_FriendsList == nil then return end

	local capture = mgr:CaptureFocusKey(CAI_FriendsList)
	CAI_FriendsList:ClearChildren()

	local friends = GetFriendsList()
	if friends and table.count(friends) > 0 then
		for _, friend in pairs(friends) do
			local submenu = mgr:CreateWidget("CAIStagingRoom_Friend_" .. tostring(friend.ID), "SubMenu", {
				Label = function()
					return CAI_Lookup("LOC_CAI_LOBBY_FRIEND_ROW_LABEL", friend.PlayerName or "", CAI_GetFriendStatusText(friend))
				end,
				FocusKey = "friend:" .. tostring(friend.ID),
				HiddenPredicate = function() return GameConfiguration.IsHotseat() end,
			})
			submenu:SetFocusSound(HOVER_SOUND)
			CAI_BuildFriendActionWidgets(friend, submenu)
			CAI_FriendsList:AddChild(submenu)
		end
	else
		local empty = mgr:CreateWidget("CAIStagingRoom_NoFriends", "MenuItem", {
			Label = function() return CAI_Lookup("LOC_CAI_LOBBY_NO_FRIENDS") end,
			FocusKey = "friends:none",
			HiddenPredicate = function() return GameConfiguration.IsHotseat() end,
		})
		CAI_FriendsList:AddChild(empty)
	end

	mgr:RestoreFocus(CAI_FriendsList, capture)
end

local function CAI_BuildPanel()
	CAI_Panel = mgr:CreateWidget(CAI_PANEL_ID, "Panel", {
		Label = function() return CAI_ControlText(Controls.TitleLabel) end,
	})
	CAI_PlayerList = mgr:CreateWidget("CAIStagingRoom_PlayerList", "List", {
		Label = function() return CAI_Lookup("LOC_CAI_STAGING_PLAYER_SLOTS") end,
	})
	CAI_Panel:AddChild(CAI_PlayerList)
	CAI_RebuildPlayerList()

	CAI_ReadyButton = mgr:CreateWidget("CAIStagingRoom_Ready", "Button", {
		Label = CAI_GetReadyButtonLabel,
		Tooltip = CAI_GetReadyButtonTooltip,
		DisabledPredicate = function() return CAI_IsDisabled(Controls.ReadyButton) or CAI_IsDisabled(Controls.ReadyCheck) end,
		FocusKey = "action:ready",
	})
	CAI_ReadyButton:SetFocusSound(HOVER_SOUND)
	CAI_ReadyButton:On("activate", OnReadyButton)
	CAI_Panel:AddChild(CAI_ReadyButton)

	CAI_ChatInput = mgr:CreateWidget("CAIStagingRoom_ChatInput", "EditBox", {
		Label = function() return CAI_Lookup("LOC_CAI_ENDGAME_CHAT_INPUT") end,
		Tooltip = CAI_GetChatInputTooltip,
		AlwaysEdit = true,
		CommitOnFocusLeave = false,
		HighlightOnEdit = true,
		EnterToCommit = true,
		MaxCharacters = 250,
		HiddenPredicate = function() return CAI_IsHidden(Controls.ChatContainer) end,
		DisabledPredicate = function() return CAI_IsDisabled(Controls.ChatEntry) end,
		FocusKey = "chat:input",
	})
	CAI_ChatInput:SetValueSetter(function(widget, text)
		if text and text ~= "" then
			SendChat(text)
			widget:SetText("", true)
		end
	end)
	CAI_Panel:AddChild(CAI_ChatInput)

	CAI_ChatTarget = mgr:CreateWidget("CAIStagingRoom_ChatTarget", "Dropdown", {
		Label = function() return CAI_Lookup("LOC_CAI_STAGING_CHAT_TARGET") end,
		HiddenPredicate = function() return CAI_IsHidden(Controls.ChatContainer) end,
		FocusKey = "chat:target",
	})
	CAI_ChatTarget:SetFocusSound(HOVER_SOUND)
	CAI_ChatTarget:SetValueSetter(function(_, target)
		if target then
			m_playerTarget.targetType = target.targetType
			m_playerTarget.targetID = target.targetID
			UpdatePlayerTargetPulldown(Controls.ChatPull, m_playerTarget)
			UpdatePlayerTargetEditBox(Controls.ChatEntry, m_playerTarget)
			UpdatePlayerTargetIcon(Controls.ChatIcon, m_playerTarget)
			OnChatPulldownChanged(target.targetType, target.targetID)
		end
	end)
	CAI_Panel:AddChild(CAI_ChatTarget)
	CAI_RebuildChatTarget()

	CAI_ChatHistory = mgr:CreateWidget("CAIStagingRoom_ChatHistory", "List", {
		Label = function() return CAI_Lookup("LOC_CAI_ENDGAME_CHAT_HISTORY") end,
		HiddenPredicate = function() return CAI_IsHidden(Controls.ChatContainer) end,
		FocusKey = "chat:history",
	})
	CAI_Panel:AddChild(CAI_ChatHistory)
	CAI_RefreshChatHistory()

	CAI_GameSummary = mgr:CreateWidget("CAIStagingRoom_GameSummary", "EditBox", {
		Label = function() return CAI_Lookup("LOC_CAI_STAGING_GAME_SUMMARY") end,
		ReadOnly = true,
		AlwaysEdit = true,
		HighlightOnEdit = false,
		FocusKey = "summary",
	})
	CAI_Panel:AddChild(CAI_GameSummary)
	CAI_RebuildGameSummary()

	CAI_Panel:AddChild(CAI_MakeActionButton(
		"CAIStagingRoom_CopyJoinCode",
		"LOC_CAI_STAGING_COPY_JOIN_CODE",
		Controls.JoinCodeText,
		OnClickToCopy,
		function() return CAI_IsHidden(Controls.JoinCodeRoot) end,
		{
			TooltipControl = Controls.JoinCodeText,
			TooltipTag = "LOC_CAI_STAGING_COPY_JOIN_CODE_TT",
		}
	))
	CAI_Panel:AddChild(CAI_MakeActionButton("CAIStagingRoom_EndGame", "LOC_GAME_MENU_END_GAME_TITLE", Controls.EndGameButton, OnEndGameAskAreYouSure))
	CAI_Panel:AddChild(CAI_MakeActionButton("CAIStagingRoom_QuitGame", "LOC_GAME_MENU_QUIT_GAME_TITLE", Controls.QuitGameButton, OnQuitGameAskAreYouSure))

	CAI_FriendsList = mgr:CreateWidget("CAIStagingRoom_Friends", "List", {
		Label = function() return CAI_Lookup("LOC_MULTIPLAYER_FRIENDS") end,
		HiddenPredicate = function() return GameConfiguration.IsHotseat() end,
	})
	CAI_Panel:AddChild(CAI_FriendsList)
	CAI_RebuildFriendsList()

	local setup = mgr:CreateWidget("CAIStagingRoom_Setup", "Button", {
		Label = function() return CAI_Lookup("LOC_MULTIPLAYER_GAME_SETUP") end,
		FocusKey = "action:setup",
	})
	setup:SetFocusSound(HOVER_SOUND)
	setup:On("activate", OnGameSetupTabClicked)
	CAI_Panel:AddChild(setup)
end

local function CAI_PushPanel()
	if mgr == nil or ContextPtr:IsHidden() then return end
	if CAI_Panel == nil then
		CAI_BuildPanel()
	end
	if CAI_Panel and mgr:GetWidgetById(CAI_PANEL_ID) ~= CAI_Panel then
		mgr:Push(CAI_Panel, { priority = PopupPriority.Current, focus = CAI_PlayerList })
	end
end

local function CAI_PopPanel()
	if mgr and mgr:GetWidgetById(CAI_PANEL_ID) then
		mgr:RemoveFromStack(CAI_PANEL_ID)
	end
	if CAI_Panel then CAI_Panel:Destroy() end
	CAI_Panel = nil
	CAI_PlayerList = nil
	CAI_ReadyButton = nil
	CAI_ChatHistory = nil
	CAI_ChatInput = nil
	CAI_ChatTarget = nil
	CAI_GameSummary = nil
	CAI_FriendsList = nil
	CAI_LastReadySpeech = { label = "", tooltip = "", countdown = "" }
	CAI_LastKnownLocalPlayerID = nil
	CAI_PlayerListRefreshQueued = false
	CAI_ChatTargetRefreshQueued = false
	CAI_PendingSwapFocusKey = nil
	CAI_PendingSwapFocusWithinList = false
	CAI_PendingSwapFeedback = nil
	ContextPtr:ClearUpdate()
end

OnShow = WrapFunc(OnShow, function(orig, ...)
	orig(...)
	CAI_LastKnownLocalPlayerID = Network.GetLocalPlayerID()
	CAI_PushPanel()
end)

BuildPlayerList = WrapFunc(BuildPlayerList, function(orig, ...)
	local result = orig(...)
	CAI_RequestPlayerListRefresh(false)
	CAI_RebuildFriendsList()
	return result
end)

OnPlayerInfoChanged = WrapFunc(OnPlayerInfoChanged, function(orig, ...)
	local oldLocalPlayerID = CAI_LastKnownLocalPlayerID
	local focusWithinList = CAI_IsFocusWithin(CAI_PlayerList)
	local result = orig(...)
	local newLocalPlayerID = Network.GetLocalPlayerID()
	if oldLocalPlayerID ~= nil
		and newLocalPlayerID ~= nil
		and newLocalPlayerID ~= NetPlayerTypes.INVALID_PLAYERID
		and newLocalPlayerID ~= oldLocalPlayerID then
		CAI_PendingSwapFeedback = CAI_Lookup("LOC_CAI_STAGING_SWAP_SUCCESS")
		CAI_PendingSwapFocusKey = "slot:" .. tostring(newLocalPlayerID)
		CAI_PendingSwapFocusWithinList = focusWithinList
	end
	CAI_LastKnownLocalPlayerID = newLocalPlayerID
	CAI_RequestPlayerListRefresh(true)
	CAI_RebuildFriendsList()
	return result
end)

UpdateReadyButton = WrapFunc(UpdateReadyButton, function(orig, ...)
	local result = orig(...)
	if CAI_ReadyButton then
		local currentLabel = CAI_GetReadyButtonLabel()
		local currentTooltip = CAI_GetReadyButtonTooltip()
		local currentCountdown = CAI_GetReadyCountdownSpeech()
		local focused = mgr and mgr.CurrentPath and mgr.CurrentPath[#mgr.CurrentPath] == CAI_ReadyButton
		if focused and currentCountdown ~= "" and currentCountdown ~= CAI_LastReadySpeech.countdown then
			Speak(currentCountdown, false)
		end
		CAI_LastReadySpeech.label = currentLabel
		CAI_LastReadySpeech.tooltip = currentTooltip
		CAI_LastReadySpeech.countdown = currentCountdown
	end
	return result
end)

UpdatePlayerEntry = WrapFunc(UpdatePlayerEntry, function(orig, playerID, ...)
	local oldReady = g_PlayerReady[playerID]
	local hadReadyState = oldReady ~= nil
	local result = orig(playerID, ...)
	local cfg = PlayerConfigurations[playerID]
	if hadReadyState and cfg and ContextPtr:IsHidden() == false and not GameConfiguration.IsHotseat() then
		local slotStatus = cfg:GetSlotStatus()
		local newReady = cfg:GetReady()
		if (slotStatus == SlotStatus.SS_TAKEN or slotStatus == SlotStatus.SS_OBSERVER) and newReady ~= oldReady then
			local playerName = CAI_GetPlayerName(playerID, g_PlayerEntries[playerID])
			Speak(CAI_Lookup(newReady and "LOC_CAI_STAGING_PLAYER_READY" or "LOC_CAI_STAGING_PLAYER_UNREADY", playerName), false)
		end
	end
	return result
end)

OnModStatusUpdated = WrapFunc(OnModStatusUpdated, function(orig, ...)
	local result = orig(...)
	CAI_RequestPlayerListRefresh(false)
	return result
end)

StartCountdown = WrapFunc(StartCountdown, function(orig, ...)
	local result = orig(...)
	CAI_RequestPlayerListRefresh(false)
	return result
end)

StopCountdown = WrapFunc(StopCountdown, function(orig, ...)
	local result = orig(...)
	CAI_RequestPlayerListRefresh(false)
	return result
end)

RealizeGameSetup = WrapFunc(RealizeGameSetup, function(orig, ...)
	local result = orig(...)
	if CAI_Panel then CAI_RebuildGameSummary() end
	return result
end)

BuildGameState = WrapFunc(BuildGameState, function(orig, ...)
	local result = orig(...)
	if CAI_Panel then
		CAI_RebuildGameSummary()
		CAI_RebuildFriendsList()
	end
	return result
end)

BuildAdditionalContent = WrapFunc(BuildAdditionalContent, function(orig, ...)
	local result = orig(...)
	if CAI_Panel then CAI_RebuildGameSummary() end
	return result
end)

ChatPrintHelp = WrapFunc(ChatPrintHelp, function(orig, ...)
	local result = orig(...)
	local line = CAI_RecordLocalChat(CAI_Lookup("LOC_CHAT_HELP_COMMAND_TEXT"))
	CAI_RefreshChatHistory()
	if line and ContextPtr:IsHidden() == false then
		CAI_SpeakChatLine(line)
	end
	return result
end)

ResetChat = WrapFunc(ResetChat, function(orig, ...)
	CAI_ChatLines = {}
	local result = orig(...)
	CAI_RefreshChatHistory()
	return result
end)

OnChat = WrapFunc(OnChat, function(orig, fromPlayer, toPlayer, text, eTargetType, playSounds)
	local result = orig(fromPlayer, toPlayer, text, eTargetType, playSounds)
	local line = CAI_RecordChat(fromPlayer, toPlayer, text, eTargetType)
	CAI_RefreshChatHistory()
	if line and (playSounds or CAI_IsSystemChatMessage(text)) and ContextPtr:IsHidden() == false then
		CAI_SpeakChatLine(line)
	end
	return result
end)

SendChat = WrapFunc(SendChat, function(orig, ...)
	local oldTargetType = m_playerTarget.targetType
	local oldTargetID = m_playerTarget.targetID
	local result = orig(...)
	if CAI_ChatTarget
		and (m_playerTarget.targetType ~= oldTargetType or m_playerTarget.targetID ~= oldTargetID) then
		CAI_SyncChatTargetSelection()
	end
	return result
end)

PlayerInfoChanged_SpecificPlayer = WrapFunc(PlayerInfoChanged_SpecificPlayer, function(orig, ...)
	local result = orig(...)
	return result
end)

UpdateFriendsList = WrapFunc(UpdateFriendsList, function(orig, ...)
	local result = orig(...)
	CAI_RebuildFriendsList()
	return result
end)

OnHandleExitRequest = WrapFunc(OnHandleExitRequest, function(orig, ...)
	CAI_PopPanel()
	orig(...)
end)

OnLeaveGameComplete = WrapFunc(OnLeaveGameComplete, function(orig, ...)
	CAI_PopPanel()
	orig(...)
end)

OnBeforeMultiplayerInviteProcessing = WrapFunc(OnBeforeMultiplayerInviteProcessing, function(orig, ...)
	CAI_PopPanel()
	orig(...)
end)

OnGameSetupTabClicked = WrapFunc(OnGameSetupTabClicked, function(orig, ...)
	CAI_PopPanel()
	orig(...)
end)

Initialize = WrapFunc(Initialize, function(orig)
	orig()
	ContextPtr:SetInputHandler(function(input)
		if mgr and not ContextPtr:IsHidden() and mgr:HandleInput(input) then
			return true
		end
		return OnInputHandler(input)
	end, true)
end)
--#End of accessibility integration
Initialize();
