include("InstanceManager");
include("LobbyTypes"); --MPLobbyMode

include("PlayerSetupLogic"); -- For PlayNow

include("PopupDialog");

-- ===========================================================================
--	Members
-- ===========================================================================
local m_mainOptionIM :	table = InstanceManager:new( "MenuOption", "Top", Controls.MainMenuOptionStack );
local m_subOptionIM :	table = InstanceManager:new( "MenuOption", "Top", Controls.SubMenuOptionStack );
local m_carouselEntryIM : table = InstanceManager:new( "CarouselEntry", "Top", Controls.ChallengeStack );
local m_carouselIndicatorIM : table = InstanceManager:new( "CarouselEntryIndicator", "Top", Controls.ChallengeIndicatorStack );
local m_currentCarouselEntry = 1;
local m_carouselDisplayDurationMS = 8000;
local m_carouselCurrentSlideDurationMS = 0;
local m_carouselSlideAnimationDurationMS = 500;
local m_carouselAnimation = {active = false, time = 0, startValue = 0, destinationValue = 0, destinationIndex = 0, scrollType = ""};
local m_carouselAutoscrollEnabled = true;
local m_preSaveMainMenuOptions:	table = {};
local m_defaultMainMenuOptions:	table = {};
local m_singlePlayerListOptions:table = {};
local m_hasSaves:boolean = false;
local m_cloudNotify:number = CloudNotifyTypes.CLOUDNOTIFY_NONE;
local m_hasCloudUnseenComplete:boolean = false; -- Do we have completed PlayByCloud games that we haven't seen yet?
local m_checkedCloudNotify:boolean = false;	-- Have we checked for cloud notifications?
local m_currentOptions:table = {};		--Track which main menu options are being displayed and selected. Indices follow the format of {optionControl:table, isSelected:boolean}
local m_initialPause = 1.5;				--How long to wait before building the main menu options when the game first loads
local m_internetButton:table = nil;		--Cache internet button so it can be updated when online status events fire
local m_crossPlayButton:table = nil;	--Cache crossplay button so it can be updated when online status events fire
local m_multiplayerButton:table = nil;	--Cache multiplayer button so it can be updated if a new cloud turn comes in.
local m_cloudGamesButton:table = nil;	--Cache cloud games button so it can be updated if a new cloud turn comes in.
local m_resumeButton:table = nil;		--Cache resume button so it can be updated when FileListQueryResults event fires
local m_scenariosButton:table = nil;	--Cache scenarios button so it can be updated later.
local m_matchRoyaleButton:table = nil;	--Cache CivRoyale matchmaking button so it can be updated later.
local m_howToRoyaleControl:table = nil;	--Cache CivRoyale how-to button so that it can be updated later.
local m_matchPiratesButton:table = nil;	--Cache Pirates matchmaking button so it can be updated later.
local m_howToPiratesControl:table = nil;--Cache Pirates how-to button so that it can be updated later.
local m_isQuitting :boolean = false;	-- Is the application shutting down (after user approval.)

g_LogoTexture = nil;	-- Custom Logo texture override.
g_LogoMovie = nil;		-- Custom Logo movie override.

g_PopupDialog = PopupDialog:new("MainMenuPopupDialog");

-- ===========================================================================
--	Constants
-- ===========================================================================
local PAUSE_INCREMENT				:number = .18;			--How long to wait (in seconds) between main menu flyouts - length of the menu cascade
local TRACK_PADDING					:number = 40;			--The amount of Y pixels to add to the track on top of the list height
local OPTION_SEEN_CIVROYALE_INTRO	:string = "HasSeenCivRoyaleIntro";	-- Option key for having seen the CivRoyale How to Play screen.
local OPTION_SEEN_PIRATES_INTRO		:string = "HasSeenPiratesIntro";	-- Option key for having seen the Pirates How to Play screen.
local MOD_CIVROYALE_GUID			:string = "F264EE10-F21B-4A9A-BBCD-D534E9843E90";
local MOD_PIRATES_GUID				:string = "A55FAFB4-9070-4597-9453-B28A99910CDA";

-- ===========================================================================
--	Globals
-- ===========================================================================
g_LastFileQueryRequestID = nil;			-- The file list ID used to determine whether the call-back is for us or not.
g_MostRecentSave = nil;					-- The most recent single player save a user has (locally)


-- ===========================================================================
-- Button Handlers
-- ===========================================================================
function OnResumeGame()
	if(g_MostRecentSave) then
		local serverType : number = ServerType.SERVER_TYPE_NONE;
		print("MainMenu::OnResumeGame() leaving the network session.");
		Network.LeaveGame();
		Network.LoadGame(g_MostRecentSave, serverType);
	end
end

function UpdateResumeGame(resumeButton)
	if (resumeButton ~= nil) then
		m_resumeButton = resumeButton;
	end
	if(m_resumeButton ~= nil) then
		if(g_MostRecentSave ~= nil) then

			local mods = g_MostRecentSave.RequiredMods or {};
	
			-- Test for errors.
			-- Will return a combination array/map of any errors regarding this combination of mods.
			-- Array messages are generalized error codes regarding the set.
			-- Map messages are error codes specific to the mod Id.
			local errors = Modding.CheckRequirements(mods, SaveTypes.SINGLE_PLAYER);
			local success = (errors == nil or errors.Success);

			m_resumeButton.Top:SetHide(not success);
		else
			m_resumeButton.Top:SetHide(true);
		end
	end
end

function UpdateScenariosButton(button)
	if(button) then 
		m_scenariosButton = button; 
	end

	if(button) then
		button.Top:SetHide(true);
		local query = "SELECT 1 from Rulesets where IsScenario = 1 and SupportsSinglePlayer = 1 LIMIT 1";
		local results = DB.ConfigurationQuery(query);
		if(results and #results > 0) then
			button.Top:SetHide(false);
		end
	end
end


-- ===========================================================================
--	Starting game
--	Step 1 of 2: Stop extra clicks and signal to raise loading screen
-- ===========================================================================
function OnPlayCiv6()	
	-- Avoid double clicks.
	if(_ClickedPlayNow) then 
		return;
	end
	_ClickedPlayNow = true;
	
	LuaEvents.Raise_State_Transition("MainMenu");	-- Will raise screen
end

-- ===========================================================================
--	Starting game
--	Step 2 of 2: State transition has raised a loading screen, kick off
--	potentially expensive operations to start loading.
--	It's the loadingscreen's responsibility to lower the state transition.
-- ===========================================================================
function OnStateTransition( who:string )
	if (who ~= "MainMenu") then
		return;	-- Meant for someone else
	end
	
	local save = Options.GetAppOption("Debug", "PlayNowSave");
	if(save ~= nil) then
		print("MainMenu::OnPlayCiv6() PlayNowSave leaving the network session.");
		Network.LeaveGame();

		local serverType : number = ServerType.SERVER_TYPE_NONE;
		Network.LoadGame(save, serverType);
	else

		-- Reset the game configuration.
		GameConfiguration.SetToDefaults();
		-- Kludge:  SetToDefaults assigns the ruleset to be standard.
		-- Clear this value so that the setup parameters code can guess the best 
		-- default.
		GameConfiguration.SetValue("RULESET", nil);

		if (_StartChallengeEntry == nil) then
			if (_ClickedPlayNow) then
				Events.SetGameEntryMethod("Play Now");
			else
				Events.SetGameEntryMethod("Unknown");
			end
			-- Many game setup values are driven by Lua-implemented parameter logic.
			BuildHeadlessGameSetup();
			RebuildPlayerParameters(true);
			GameSetup_RefreshParameters();

			-- Cleanup
			ReleasePlayerParameters();
			HideGameSetup();

			Network.HostGame(ServerType.SERVER_TYPE_NONE);
		else
			Events.SetGameEntryMethod("GoTM");

			Challenges.LoadCarouselEntry(_StartChallengeEntry);
			_StartChallengeEntry = nil;
		end
	end
end

-- ===========================================================================
function OnAdvancedSetup()
	GameConfiguration.SetToDefaults();
	-- Kludge:  SetToDefaults assigns the ruleset to be standard.
	-- Clear this value so that the setup parameters code can guess the best 
	-- default.
	GameConfiguration.SetValue("RULESET", nil);
	-- Reset the load game server type, in case a configuration is loaded.
	LuaEvents.MainMenu_SetLoadGameServerType(ServerType.SERVER_TYPE_NONE);
	UIManager:QueuePopup(Controls.AdvancedSetup, PopupPriority.Current);
end

-- ===========================================================================
function OnScenarioSetup()
	GameConfiguration.SetToDefaults();
	-- Kludge:  SetToDefaults assigns the ruleset to be standard.
	-- Clear this value so that the setup parameters code can guess the best 
	-- default.
	GameConfiguration.SetValue("RULESET", nil);
	-- Reset the load game server type, in case a configuration is loaded.
	LuaEvents.MainMenu_SetLoadGameServerType(ServerType.SERVER_TYPE_NONE);
	UIManager:QueuePopup(Controls.ScenarioSetup, PopupPriority.Current);
end

-- ===========================================================================
function OnLoadSinglePlayer()
	GameConfiguration.SetToDefaults();
	LuaEvents.MainMenu_SetLoadGameServerType(ServerType.SERVER_TYPE_NONE);
	UIManager:QueuePopup(Controls.LoadGameMenu, PopupPriority.Current);		
	Close();
end

-- ===========================================================================
function OnOptions()
	UIManager:QueuePopup(Controls.Options, PopupPriority.Current);
	Close();
end

-- ===========================================================================
function OnMods()
	GameConfiguration.SetToDefaults();
	UIManager:QueuePopup(Controls.ModsContext, PopupPriority.Current);
	Close();
end

function OnHallofFame()
	UIManager:QueuePopup(Controls.HallofFame, PopupPriority.Current);
	Close();
end

-- ===========================================================================
function OnPlayMultiplayer()
	UIManager:QueuePopup(Controls.MultiplayerSelect, PopupPriority.Current);
	Close();
end

-- ===========================================================================
function OnMy2KLogin()
	Events.Begin2KLoginProcess();
	Close();
end

-- Allow for cycling through the MotD text languages.  For previewing only.
local ms_MotDIndex = nil;

-- ===========================================================================
function UpdateMotD()
	
	local bShow = false;
	-- Have a MotD that the user has not dismissed (its still open)?
	local MotDData = UI.GetPushData("MotD", 0, PushDataSearchOptions.IsOpen, ms_MotDIndex);

	if ms_MotDIndex ~= nil and MotDData.Message == "" then
		ms_MotDIndex = nil;
		MotDData = UI.GetPushData("MotD", 0, PushDataSearchOptions.IsOpen, ms_MotDIndex);
	end

	if MotDData ~= nil and MotDData.Message ~= nil then
		Controls.MotDText:SetText(MotDData.Message);
		Controls.MotDText:DoAutoSize();
		bShow = true;
	end
			
	Controls.MotDContainter:SetShow( bShow );
end

-- ===========================================================================
function OnMarketingPushDataUpdated()
	UpdateMotD();
end

-- ===========================================================================
--	Engine Event
-- ===========================================================================
function OnUserRequestClose()
    LuaEvents.MainMenu_UserRequestClose();
end

-- ===========================================================================
--	EVENT
--	Application has been confirmed to close.
-- ===========================================================================
function OnUserConfirmedClose()
	m_isQuitting = true;
	Controls.SubMenuSlide:SetAlpha( 0 ); -- Don't toggle visibility so surrounding stack doesn't collapse.
end

    -- ===========================================================================
function OnGraphicsBenchmark()
	Benchmark.RunGraphicsBenchmark("GraphicsBenchmark.Civ6Save");
end

function OnExp2GraphicsBenchmark()
	Benchmark.RunExp2GraphicsBenchmark("XP2Benchmark.Civ6Save", SaveDirectories.BENCHMARK, "Automation_StandardTests.lua; Automation_BenchmarkCamera_Capitals.lua");
end

function OnAIBenchmark()
	Benchmark.RunAIBenchmark("AIBenchmark.Civ6Save");
end

function OnExp2AIBenchmark()
	Benchmark.RunExp2AIBenchmark("XP2Benchmark.Civ6Save");
end

-- ===========================================================================
function OnCredits()
	UIManager:QueuePopup( Controls.CreditsScreen, PopupPriority.Current );
	Close();
end

-- ===========================================================================
function OnCloudTurnCheckComplete(notifyType :number, turnGameName :string, inGames :boolean)
	m_cloudNotify = notifyType;
	if (not ContextPtr:IsHidden()) then
		UpdateCloudGamesButton();
		UpdateMultiplayerButton();
	end
end

-- ===========================================================================
function OnCloudUnseenCompleteCheckComplete(haveCompletedGame :boolean, gameName :string, matchID :number)
	m_hasCloudUnseenComplete = haveCompletedGame;
	if (not ContextPtr:IsHidden()) then
		UpdateCloudGamesButton();
		UpdateMultiplayerButton();
	end
end

-- ===========================================================================
function GetCivRoyaleOfflineTT()
	if (Network.IsAgeRestricted()) then
		return Locale.Lookup("LOC_MULTIPLAYER_INTERNET_GAME_OFFLINE_AGE_TT");
	end

	if( Network.GetNetworkPlatform() == NetworkPlatform.NETWORK_PLATFORM_EOS ) then
		return Locale.Lookup("LOC_EPIC_MULTIPLAYER_MATCHMAKE_CIVROYALE_OFFLINE_TT");
	end

	return Locale.Lookup("LOC_MULTIPLAYER_MATCHMAKE_CIVROYALE_OFFLINE_TT");
end

-- ===========================================================================
function GetPiratesOfflineTT()
	if (Network.IsAgeRestricted()) then
		return Locale.Lookup("LOC_MULTIPLAYER_INTERNET_GAME_OFFLINE_AGE_TT");
	end

	if( Network.GetNetworkPlatform() == NetworkPlatform.NETWORK_PLATFORM_EOS ) then
		return Locale.Lookup("LOC_EPIC_MULTIPLAYER_MATCHMAKE_PIRATES_OFFLINE_TT");
	end

	return Locale.Lookup("LOC_MULTIPLAYER_MATCHMAKE_PIRATES_OFFLINE_TT");
end

-- ===========================================================================
function GetInternetGameOfflineTT()
	if (Network.IsAgeRestricted()) then
		return Locale.Lookup("LOC_MULTIPLAYER_INTERNET_GAME_OFFLINE_AGE_TT");
	end

	if( Network.GetNetworkPlatform() == NetworkPlatform.NETWORK_PLATFORM_EOS ) then
		return Locale.Lookup("LOC_EPIC_MULTIPLAYER_INTERNET_GAME_OFFLINE_TT");
	end

	return Locale.Lookup("LOC_MULTIPLAYER_INTERNET_GAME_OFFLINE_TT");
end

-- ===========================================================================
-- Multiplayer Select Screen
-- ===========================================================================
local InternetButtonOnlineStr : string = Locale.Lookup("LOC_MULTIPLAYER_INTERNET_GAME_TT");
local InternetButtonOfflineStr : string = GetInternetGameOfflineTT();
local CloudButtonTTStr : string = Locale.Lookup("LOC_MULTIPLAYER_CLOUD_GAME_TT");
local CloudNotLoggedInTTStr : string = Locale.Lookup("LOC_MULTIPLAYER_CLOUD_GAME_NO_LOGIN_TT");
local CloudNotAgeRestrictedTTStr : string = Locale.Lookup("LOC_MULTIPLAYER_CLOUD_GAME_NO_LOGIN_AGE_TT");
local CloudButtonUnseenCompleteGameTTStr : string = Locale.Lookup("LOC_MULTIPLAYER_CLOUD_UNSEEN_COMPLETE_GAME_TT");
local CloudButtonHaveTurnTTStr : string = Locale.Lookup("LOC_MULTIPLAYER_CLOUD_GAME_HAVE_TURN_TT");
local CloudButtonGameReadyTTStr: string = Locale.Lookup("LOC_MULTIPLAYER_CLOUD_GAME_GAME_READY_TT");
local CrossplayButtonNewMPModeTTStr : string = Locale.Lookup("LOC_MULTIPLAYER_CROSSPLAY_GAME_NEW_MODE_TT");
local MultiplayerButtonTTStr : string = Locale.Lookup("LOC_MAINMENU_MULTIPLAYER_BASE_TT");
local MultiplayerButtonHaveTurnTTStr : string = Locale.Lookup("LOC_MAINMENU_MULTIPLAYER_HAVE_CLOUD_TURN_TT");
local MultiplayerButtonGameReadyTTStr : string = Locale.Lookup("LOC_MAINMENU_MULTIPLAYER_GAME_READY_TT");
local MultiplayerButtonUnseenCompleteTTStr : string = Locale.Lookup("LOC_MAINMENU_MULTIPLAYER_UNSEEN_COMPLETE_GAME_TT");
local MultiplayerButtonNewMPModeTTStr : string = Locale.Lookup("LOC_MAINMENU_MULTIPLAYER_NEW_MP_MODE_TT");


-- ===========================================================================
function OnInternet()
	LuaEvents.ChangeMPLobbyMode(MPLobbyTypes.STANDARD_INTERNET);
	UIManager:QueuePopup( Controls.Lobby, PopupPriority.Current );
	Close();	
end

-- ===========================================================================
function OnCrossPlay()
	LuaEvents.StartCrossPlay();
end

-- ===========================================================================
function OnEnterCrossPlayLobby()
	GameConfiguration.SetToDefaults(GameModeTypes.CROSSPLAY);
	LuaEvents.ChangeMPLobbyMode(MPLobbyTypes.CROSSPLAY_INTERNET);
	UIManager:QueuePopup( Controls.Lobby, PopupPriority.Current );
	Close();

	-- Toggle SeenCrossPlayMultiplayer user option flag
	local oldSeenXPM = Options.GetUserOption("Interface", "SeenCrossPlayMultiplayer");
	if (oldSeenXPM == nil or oldSeenXPM == 0) then
		Options.SetUserOption("Interface", "SeenCrossPlayMultiplayer", 1);
		Options.SaveOptions(OptionFileTypes.User);
	end
end
LuaEvents.EnterCrossPlayLobby.Add(OnEnterCrossPlayLobby);

-- ===========================================================================
function GetOnMatchMakeFunction(sentOption :string, startMatchMakeFunction, showHowToEvent)
	function CustomOnMatchMakeFunction()
		local skipIntroScreen =  Options.GetUserOption("Tutorial", sentOption) == 1;
		if(skipIntroScreen) then
			startMatchMakeFunction();
		else
			showHowToEvent();
		end
	end
	return CustomOnMatchMakeFunction;
end

-- ===========================================================================
function OnCivRoyaleHowToPlay()
	LuaEvents.MainMenu_ShowCivRoyaleIntro();
end

function OnPiratesHowToPlay()
	LuaEvents.MainMenu_ShowPiratesIntro();
end

-- ===========================================================================
function StartPiratesMatchMaking()
	StartMatchMaking(MOD_PIRATES_GUID, "RULESET_SCENARIO_PIRATES");
end

function StartRoyaleMatchMaking()
	StartMatchMaking(MOD_CIVROYALE_GUID, "RULESET_SCENARIO_CIV_ROYALE");
end

function StartMatchMaking(modGUID :string, rulesetName :string)
	GameConfiguration.SetToDefaults(GameModeTypes.INTERNET);	
	GameConfiguration.ClearEnabledMods();
	GameConfiguration.AddEnabledMods( modGUID );
	GameConfiguration.SetRuleSet(rulesetName);

	-- Many game setup values are driven by Lua-implemented parameter logic.
	do
		-- Generate setup parameters that lack any sort of UI.
		BuildHeadlessGameSetup();
		RebuildPlayerParameters(true);

		-- Trigger a refresh.
		GameSetup_RefreshParameters();

		-- Cleanup.
		ReleasePlayerParameters();
		HideGameSetup();
	end

	GameConfiguration.SetMatchMaking(true);
	GameConfiguration.SetKickVoting(true);
	Network.MatchMake();
end

-- ===========================================================================
--	WB: This callback is complicated by these events which can happen at any time.
--	Because few other buttons in the shell function in this way, using a special 
--	variable to save this control (instead of a more general solution).
-- ===========================================================================
function UpdateAIBenchmark(buttonControl)
	if (buttonControl ~= nil) then
		m_aiButton = buttonControl;
	end
	
	if(m_aiButton ~= nil) then

		--Requires Montezuma DLC
		local allowed = false;
		local modId = "02A8BDDE-67EA-4D38-9540-26E685E3156E";
		local modHandle = Modding.GetModHandle(modId);
		if(modHandle ~= nil) then
			local modInfo = Modding.GetModInfo(modHandle);
			if(modInfo.Allowance ~= false) then
				allowed = true;
			end
		end

		local aiButtonTooltip = Locale.Lookup("LOC_BENCHMARK_AI_TT");

		if(allowed) then
			m_aiButton.OptionButton:SetDisabled(false);
			m_aiButton.Top:SetToolTipString(aiButtonTooltip);
			m_aiButton.ButtonLabel:SetColorByName( "ButtonCS" );
		else
			aiButtonTooltip = aiButtonTooltip .. "[NEWLINE]" .. Locale.Lookup("LOC_BENCHMARK_AI_TT_ERROR");
			m_aiButton.OptionButton:SetDisabled(true);
			m_aiButton.Top:SetToolTipString(aiButtonTooltip);
			m_aiButton.ButtonLabel:SetColorByName( "ButtonDisabledCS" );
		end
	end
end

function UpdateExp2AIBenchmark(buttonControl)
	if (buttonControl ~= nil) then
		m_aiButton = buttonControl;
	end
	
	if(m_aiButton ~= nil) then

		--Requires expansion 2
		local allowed = false;
		local modId = "4873eb62-8ccc-4574-b784-dda455e74e68";
		local modHandle = Modding.GetModHandle(modId);
		if(modHandle ~= nil) then
			local modInfo = Modding.GetModInfo(modHandle);
			if(modInfo.Allowance ~= false) then
				allowed = true;
			end
		end

		local aiButtonTooltip = Locale.Lookup("LOC_BENCHMARK_EXP2_AI_TT");

		if(allowed) then
			m_aiButton.OptionButton:SetDisabled(false);
			m_aiButton.Top:SetToolTipString(aiButtonTooltip);
			m_aiButton.ButtonLabel:SetColorByName( "ButtonCS" );
		else
			aiButtonTooltip = aiButtonTooltip .. "[NEWLINE]" .. Locale.Lookup("LOC_BENCHMARK_EXP2_AI_TT_ERROR");
			m_aiButton.OptionButton:SetDisabled(true);
			m_aiButton.Top:SetToolTipString(aiButtonTooltip);
			m_aiButton.ButtonLabel:SetColorByName( "ButtonDisabledCS" );
		end
	end
end

function UpdateExp2GraphicsBenchmark(buttonControl)
	if (buttonControl ~= nil) then
		m_aiButton = buttonControl;
	end
	
	if(m_aiButton ~= nil) then

		--Requires expansion 2
		local allowed = false;
		local modId = "4873eb62-8ccc-4574-b784-dda455e74e68";
		local modHandle = Modding.GetModHandle(modId);
		if(modHandle ~= nil) then
			local modInfo = Modding.GetModInfo(modHandle);
			if(modInfo.Allowance ~= false) then
				allowed = true;
			end
		end

		local aiButtonTooltip = Locale.Lookup("LOC_BENCHMARK_EXP2_GRAPHICS_TT");

		if(allowed) then
			m_aiButton.OptionButton:SetDisabled(false);
			m_aiButton.Top:SetToolTipString(aiButtonTooltip);
			m_aiButton.ButtonLabel:SetColorByName( "ButtonCS" );
		else
			aiButtonTooltip = aiButtonTooltip .. "[NEWLINE]" .. Locale.Lookup("LOC_BENCHMARK_EXP2_GRAPHICS_TT_ERROR");
			m_aiButton.OptionButton:SetDisabled(true);
			m_aiButton.Top:SetToolTipString(aiButtonTooltip);
			m_aiButton.ButtonLabel:SetColorByName( "ButtonDisabledCS" );
		end
	end
end

function UpdateInternetControls()
	UpdateInternetButton();
	UpdateCrossPlayButton();

	UpdateCivRoyaleButton();
	UpdatePiratesButton();
end

function UpdateCivRoyaleButton()
	updateRoyaleButtonFunc = GetMatchMakeButtonUpdateFunction(m_matchRoyaleButton, MOD_CIVROYALE_GUID, "LOC_MULTIPLAYER_MATCHMAKE_CIVROYALE", "LOC_MULTIPLAYER_MATCHMAKE_CIVROYALE_TT", "LOC_MULTIPLAYER_MATCHMAKE_CIVROYALE_OFFLINE", GetCivRoyaleOfflineTT());
	updateRoyaleButtonFunc(nil);
end

function UpdatePiratesButton()
	updatePiratesButtonFunc = GetMatchMakeButtonUpdateFunction(m_matchPiratesButton, MOD_PIRATES_GUID, "LOC_MULTIPLAYER_MATCHMAKE_PIRATES", "LOC_MULTIPLAYER_MATCHMAKE_PIRATES_TT", "LOC_MULTIPLAYER_MATCHMAKE_PIRATES_OFFLINE", GetPiratesOfflineTT());
	updatePiratesButtonFunc(nil);
end

function UpdateInternetButton(buttonControl: table)
	if (buttonControl ~=nil) then
		m_internetButton = buttonControl;
	end
	-- Internet available?
	if(m_internetButton ~= nil) then
		if (Network.IsInternetLobbyServiceAvailable()) then
			m_internetButton.OptionButton:SetDisabled(false);
			m_internetButton.Top:SetToolTipString(InternetButtonOnlineStr);
			m_internetButton.ButtonLabel:SetText(Locale.Lookup("LOC_MULTIPLAYER_INTERNET_GAME"));
			m_internetButton.ButtonLabel:SetColorByName( "ButtonCS" );
		else
			m_internetButton.OptionButton:SetDisabled(true);
			m_internetButton.Top:SetToolTipString(InternetButtonOfflineStr);
			m_internetButton.ButtonLabel:SetText(Locale.Lookup("LOC_MULTIPLAYER_INTERNET_GAME_OFFLINE"));
			m_internetButton.ButtonLabel:SetColorByName( "ButtonDisabledCS" );
		end
	end
end

function UpdateCrossPlayButton(buttonControl: table)
	if (buttonControl ~=nil) then
		m_crossPlayButton = buttonControl;
	end
	-- Internet available?
	if(m_crossPlayButton ~= nil) then
		local seenXPM = Options.GetUserOption("Interface", "SeenCrossPlayMultiplayer");
		local isAllowCrossplayButton :boolean = true;
		if (Network.HasSeparateCrossPlayLobbyService() and isAllowCrossplayButton) then
			if (Network.IsCrossPlayLobbyServiceAvailable() and Network.IsInternetLobbyServiceAvailable()) then
				m_crossPlayButton.OptionButton:SetDisabled(false);
				if (seenXPM == nil or seenXPM == 0) then
					m_crossPlayButton.Top:SetToolTipString(Locale.Lookup("LOC_MULTIPLAYER_CROSSPLAY_NEW_GAME_TT"));
					m_crossPlayButton.ButtonLabel:SetText(Locale.Lookup("LOC_MULTIPLAYER_CROSSPLAY_NEW_GAME"));
				else
					m_crossPlayButton.Top:SetToolTipString(Locale.Lookup("LOC_MULTIPLAYER_CROSSPLAY_GAME_TT"));
					m_crossPlayButton.ButtonLabel:SetText(Locale.Lookup("LOC_MULTIPLAYER_CROSSPLAY_GAME"));
				end
				m_crossPlayButton.ButtonLabel:SetColorByName( "ButtonCS" );
			else
				m_crossPlayButton.OptionButton:SetDisabled(true);
				if (seenXPM == nil or seenXPM == 0) then
					if (Network.IsAgeRestricted()) then
						m_crossPlayButton.Top:SetToolTipString(Locale.Lookup("LOC_MULTIPLAYER_INTERNET_GAME_OFFLINE_AGE_TT"));
					else
						m_crossPlayButton.Top:SetToolTipString(Locale.Lookup("LOC_MULTIPLAYER_CROSSPLAY_NEW_GAME_OFFLINE_TT"));
					end
					m_crossPlayButton.ButtonLabel:SetText(Locale.Lookup("LOC_MULTIPLAYER_CROSSPLAY_NEW_GAME_OFFLINE"));
				else
					if (Network.IsAgeRestricted()) then
						m_crossPlayButton.Top:SetToolTipString(Locale.Lookup("LOC_MULTIPLAYER_INTERNET_GAME_OFFLINE_AGE_TT"));
					else
						m_crossPlayButton.Top:SetToolTipString(Locale.Lookup("LOC_MULTIPLAYER_CROSSPLAY_GAME_OFFLINE_TT"));
					end
					m_crossPlayButton.ButtonLabel:SetText(Locale.Lookup("LOC_MULTIPLAYER_CROSSPLAY_GAME_OFFLINE"));
				end
				m_crossPlayButton.ButtonLabel:SetColorByName( "ButtonDisabledCS" );
			end
		else
			m_crossPlayButton.Top:SetHide(true);
		end
	end
end

function GetMatchMakeButtonUpdateFunction(cacheButtonControl :table, modGUIDStr :string, onlineTitleStr :string, onlineTTStr :string, offlineTitleStr :string, offlineTTStr :string)
	function CustomMatchUpdateFunction(buttonControl: table)
		if (buttonControl ~=nil) then
			cacheButtonControl = buttonControl;
		end
	
		if(cacheButtonControl ~= nil) then
			if(Modding.IsModEnabled( modGUIDStr )) then
				cacheButtonControl.Top:SetHide(false);

				-- Internet available?
				if (Network.IsInternetLobbyServiceAvailable()) then
					cacheButtonControl.OptionButton:SetDisabled(false);
					cacheButtonControl.Top:SetToolTipString(Locale.Lookup(onlineTitleStr));
					cacheButtonControl.ButtonLabel:SetText(Locale.Lookup(onlineTitleStr));
					cacheButtonControl.ButtonLabel:SetColorByName( "ButtonCS" );
				else
					cacheButtonControl.OptionButton:SetDisabled(true);
					cacheButtonControl.Top:SetToolTipString(Locale.Lookup(offlineTTStr));
					cacheButtonControl.ButtonLabel:SetText(Locale.Lookup(offlineTitleStr));
					cacheButtonControl.ButtonLabel:SetColorByName( "ButtonDisabledCS" );
				end
			else
				cacheButtonControl.Top:SetHide(true);
			end
		end
	end
	return CustomMatchUpdateFunction;
end

function GetHowToButtonUpdateFunction(cacheButtonControl :table, modGUIDStr :string)
-- This updates the state of the entire menu selection, the help button is just a sub-part of the control that is input
	function CustomHowToUpdateFunction(buttonControl: table)
		if (buttonControl ~=nil) then
			cacheButtonControl = buttonControl;
		end
	
		if(cacheButtonControl ~= nil) then
			-- Is the custom scenario (CivRoyale or Pirates) enabled?
			local enabled = Modding.IsModEnabled( modGUIDStr );
			cacheButtonControl.Top:SetHide(not enabled);
			cacheButtonControl.HelpButton:SetHide(not enabled);

			-- Might want to pass through the tooltip strings so we change change them based on the state of the internet service
			-- like we do for the other menu options
			if (enabled) then
				if (Network.IsAgeRestricted()) then
					-- We are going to set the text here, because we never change from age restricted to not
					cacheButtonControl.Top:SetToolTipString(Locale.Lookup("LOC_MULTIPLAYER_INTERNET_GAME_OFFLINE_AGE_TT"));
				end

				if (Network.IsInternetLobbyServiceAvailable()) then
					-- Should we also disable the help button?
					cacheButtonControl.OptionButton:SetDisabled(false);
				else
					cacheButtonControl.OptionButton:SetDisabled(true);
				end
			end
		end
	end
	return CustomHowToUpdateFunction;
end

function UpdateCloudGamesButton(buttonControl: table)
	if (buttonControl ~=nil) then
		m_cloudGamesButton = buttonControl;
	end
	
	-- Your turn in a cloud game?
	if(m_cloudGamesButton ~= nil) then
		if (Network.IsAgeRestricted()) then
			m_cloudGamesButton.OptionButton:SetDisabled(true);
			m_cloudGamesButton.Top:SetToolTipString(CloudNotAgeRestrictedTTStr);
			m_cloudGamesButton.ButtonLabel:SetColorByName( "ButtonDisabledCS" );
		else
			local isFullyLoggedIn = FiraxisLive.IsFullyLoggedIn() and FiraxisLive.IsPlatformOrFullAccount();
			if(not isFullyLoggedIn) then
				m_cloudGamesButton.OptionButton:SetDisabled(true);
				m_cloudGamesButton.Top:SetToolTipString(CloudNotLoggedInTTStr);
				m_cloudGamesButton.ButtonLabel:SetColorByName( "ButtonDisabledCS" );
			elseif (m_cloudNotify ~= CloudNotifyTypes.CLOUDNOTIFY_NONE and m_cloudNotify ~= CloudNotifyTypes.CLOUDNOTIFY_ERROR) then
				m_cloudGamesButton.OptionButton:SetDisabled(false);
				local CloudTTStr = GetCloudButtonTTForNotify(m_cloudNotify);
				m_cloudGamesButton.Top:SetToolTipString(CloudTTStr);
				m_cloudGamesButton.ButtonLabel:SetText(Locale.Lookup("LOC_MULTIPLAYER_CLOUD_GAME_HAVE_CLOUD_NOTIFY"));
				m_cloudGamesButton.ButtonLabel:SetColorByName( "ButtonCS" );
			elseif (m_hasCloudUnseenComplete) then
				m_cloudGamesButton.OptionButton:SetDisabled(false);
				m_cloudGamesButton.Top:SetToolTipString(CloudButtonUnseenCompleteGameTTStr .. "[NEWLINE][NEWLINE]" .. CloudButtonTTStr);
				m_cloudGamesButton.ButtonLabel:SetText(Locale.Lookup("LOC_MULTIPLAYER_CLOUD_UNSEEN_COMPLETE_GAME"));
				m_cloudGamesButton.ButtonLabel:SetColorByName( "ButtonCS" );
			else
				m_cloudGamesButton.OptionButton:SetDisabled(false);
				m_cloudGamesButton.Top:SetToolTipString(CloudButtonTTStr);
				m_cloudGamesButton.ButtonLabel:SetText(Locale.Lookup("LOC_MULTIPLAYER_CLOUD_GAME"));
				m_cloudGamesButton.ButtonLabel:SetColorByName( "ButtonCS" );
			end
		end
	end
end

function GetCloudButtonTTForNotify(cloudNotifyType :number)
	local cloudTTStr :string;
	if(cloudNotifyType == CloudNotifyTypes.CLOUDNOTIFY_YOURTURN) then
		cloudTTStr = CloudButtonHaveTurnTTStr;
	elseif(cloudNotifyType == CloudNotifyTypes.CLOUDNOTIFY_GAMEREADY) then
		cloudTTStr = CloudButtonGameReadyTTStr;
	else
		-- unhandled type.  just show the default text.
		return CloudButtonTTStr;
	end

	cloudTTStr = cloudTTStr .. "[NEWLINE][NEWLINE]" .. CloudButtonTTStr;
	return cloudTTStr;
end

function UpdateMultiplayerButton(buttonControl: table)
	if (buttonControl ~=nil) then
		m_multiplayerButton = buttonControl;
	end

	local seenXPM = Options.GetUserOption("Interface", "SeenCrossPlayMultiplayer");

	-- Your turn in a cloud game?
	if(m_multiplayerButton ~= nil) then
		if (seenXPM == nil or seenXPM == 0) then
			m_multiplayerButton.Top:SetToolTipString(MultiplayerButtonNewMPModeTTStr .. "[NEWLINE][NEWLINE]" .. MultiplayerButtonTTStr);
			m_multiplayerButton.ButtonLabel:SetText(Locale.Lookup("LOC_PLAY_MULTIPLAYER_NEW_MP_MODE"));
		elseif (m_cloudNotify ~= CloudNotifyTypes.CLOUDNOTIFY_NONE and m_cloudNotify ~= CloudNotifyTypes.CLOUDNOTIFY_ERROR) then
			local cloudTTStr = GetMPButtonTTForNotify(m_cloudNotify);
			m_multiplayerButton.Top:SetToolTipString(cloudTTStr);
			m_multiplayerButton.ButtonLabel:SetText(Locale.Lookup("LOC_PLAY_MULTIPLAYER_HAVE_CLOUD_NOTIFY"));
		elseif (m_hasCloudUnseenComplete) then
			m_multiplayerButton.Top:SetToolTipString(MultiplayerButtonUnseenCompleteTTStr .. "[NEWLINE][NEWLINE]" .. MultiplayerButtonTTStr);
			m_multiplayerButton.ButtonLabel:SetText(Locale.Lookup("LOC_PLAY_MULTIPLAYER_UNSEEN_COMPLETE_GAME"));
		else
			m_multiplayerButton.Top:SetToolTipString(MultiplayerButtonTTStr);
			m_multiplayerButton.ButtonLabel:SetText(Locale.Lookup("LOC_PLAY_MULTIPLAYER"));
		end

		m_multiplayerButton.OptionButton:SetEnabled(UI.HasFeature("Multiplayer"));
	end
end

function GetMPButtonTTForNotify(cloudNotifyType :number)
	local cloudTTStr :string;
	if(cloudNotifyType == CloudNotifyTypes.CLOUDNOTIFY_YOURTURN) then
		cloudTTStr = MultiplayerButtonHaveTurnTTStr;
	elseif(cloudNotifyType == CloudNotifyTypes.CLOUDNOTIFY_GAMEREADY) then
		cloudTTStr = MultiplayerButtonGameReadyTTStr;
	else
		-- unhandled type.  just show the default text.
		return MultiplayerButtonTTStr;
	end

	cloudTTStr = cloudTTStr  .. "[NEWLINE][NEWLINE]" .. MultiplayerButtonTTStr;
	return cloudTTStr;
end

-- ===========================================================================
function OnLANGame()
	LuaEvents.ChangeMPLobbyMode(MPLobbyTypes.STANDARD_LAN);
	UIManager:QueuePopup( Controls.Lobby, PopupPriority.Current );
	Close();
end

-- ===========================================================================
function OnHotSeat()
	LuaEvents.ChangeMPLobbyMode(MPLobbyTypes.HOTSEAT);
	LuaEvents.MainMenu_RaiseHostGame();
	Close();
end

-- ===========================================================================
function OnPlayByCloud()
	LuaEvents.ChangeMPLobbyMode(MPLobbyTypes.PLAYBYCLOUD);
	UIManager:QueuePopup( Controls.Lobby, PopupPriority.Current );
	Close();
end

-- ===========================================================================
function OnCloud()
	UIManager:QueuePopup( Controls.CloudGameScreen, PopupPriority.Current );
	Close();
end

-- ===========================================================================
function OnGameLaunched()	
end

-- ===========================================================================
function Close()
	-- Set pause to 0 so it loads in right away when returning from any screen.
	m_initialPause = 0;
end

-- ===========================================================================
function RealizeTooltipBehavior()
	local toolTipBehavior:number = Options.GetAppOption("UI", "TooltipBehavior");
	if toolTipBehavior == TooltipBehavior.AlwaysShowing then		
		TTManager:SetToolTipDelay( 0.0 );
	elseif toolTipBehavior == TooltipBehavior.ShowAfterDelay then	
		TTManager:SetToolTipDelay( 2.0 );	-- seconds to delay before showing
	elseif toolTipBehavior == TooltipBehavior.ShowOnButton then
		TTManager:SetToolTipDelay( 0.0 );	-- no delay (but require button.)
	end
end

-- ===========================================================================
function OnUpdateUI( type, tag, iData1, iData2, strData1 )
    if (type == SystemUpdateUI.TouchTipBehaviorChanged) then
		RealizeTooltipBehavior();
    end
end

-- ===========================================================================
--	ToggleOption - called from button handlers
-- ===========================================================================
--	Toggles the specified index within the main menu
--	ARG0: optionIndex - the index of the button control to deselect
--	ARG1: submenu - if the specified index has a submenu, then build that menu
-- ===========================================================================
function ToggleOption(optionIndex, submenu)
	if (not Controls.SubMenuSlide:IsStopped()) then
		return;
	end
	local optionControl = m_currentOptions[optionIndex].control;
	if(m_currentOptions[optionIndex].isSelected) then
		-- If the thing I selected was already selected, then toggle it off
		UI.PlaySound("Main_Main_Panel_Collapse"); 
		Controls.SubMenuContainer:SetHide(true);
		Controls.SubMenuAlpha:Reverse();
		Controls.SubMenuSlide:Reverse();
		SetCarouselEnabled(true);
		DeselectOption(optionIndex);
	else
		-- OTHERWISE - I am selecting a new thing
		-- Was anything else OTHER than the optionIndex selected?  If so, we should hide its selection fanciness and turn it off
		-- Let's also check to see if the submenu was already open
		local subMenuClosed = true;
		for i=1, table.count(m_currentOptions) do
			if (i ~= optionIndex) then
				if(m_currentOptions[i].isSelected) then
					subMenuClosed = false;
					DeselectOption(i);
				end
			end
		end
		
		if(subMenuClosed) then
			--If the submenu wasn't opened yet, then let's slide it out
			Controls.SubMenuAlpha:SetToBeginning();
			Controls.SubMenuAlpha:Play();
			Controls.SubMenuSlide:SetToBeginning();
			Controls.SubMenuSlide:Play();
			Controls.SubMenuContainer:SetHide(false);
			SetCarouselEnabled(false);
		end
		-- Now show the selector around the new thing 
		optionControl.SelectionAnimAlpha:SetToBeginning();
		optionControl.SelectionAnimSlide:SetToBeginning();
		optionControl.SelectionAnimAlpha:Play();
		optionControl.SelectionAnimSlide:Play();
		optionControl.LabelAlphaAnim:SetPauseTime(0);
		optionControl.LabelAlphaAnim:SetSpeed(6);
		optionControl.LabelAlphaAnim:Reverse();
		if (submenu ~= nil) then
			BuildSubMenu(submenu);
		end
		m_currentOptions[optionIndex].isSelected = true;
	end
end

-- ===========================================================================
--	Called from ToggleOption
--	Visually deselects the specified index and tracks within m_currentOptions
--	ARG0:	index - the index of the button control to deselect
-- ===========================================================================
function DeselectOption(index:number)
	local control:table = m_currentOptions[index].control;
	control.LabelAlphaAnim:SetSpeed(1);
	control.LabelAlphaAnim:SetPauseTime(.4);
	control.SelectionAnimAlpha:Reverse();
	control.SelectionAnimSlide:Reverse();
	control.LabelAlphaAnim:SetToBeginning();
	control.LabelAlphaAnim:Play();
	m_currentOptions[index].isSelected = false;
end

-- ===========================================================================
function OnTutorial()
	GameConfiguration.SetToDefaults();
	UIManager:QueuePopup(Controls.TutorialSetup, PopupPriority.Current);
end


-- ===========================================================================
--	Callbacks for the main menu options which have submenus
--	ARG0:	optionIndex - which index of the current options to toggle
--	ARG1:	submenu - the submenu table to draw in
-- ===========================================================================
function OnSinglePlayer( optionIndex:number, submenu:table )	
	ToggleOption(optionIndex, submenu);
end

function OnMultiPlayer( optionIndex:number, submenu:table )	
	ToggleOption(optionIndex, submenu);
end

function OnAdditionalContent( optionIndex:number, submenu:table )	
	ToggleOption(optionIndex, submenu);
end

function OnBenchmark( optionIndex:number, submenu:table )	
	ToggleOption(optionIndex, submenu);
end

function OnWorldBuilder( optionIndex:number, submenu:table )
	ToggleOption(optionIndex, submenu);
end


function OnNewWorldBuilderMap()
	GameConfiguration.SetToDefaults();
	GameConfiguration.SetWorldBuilderEditor(true);
	local advancedSetup = ContextPtr:LookUpControl( "/FrontEnd/MainMenu/AdvancedSetup" );
	UIManager:QueuePopup(advancedSetup, PopupPriority.Current);
end

function OnLoadWorldBuilderMap()
	GameConfiguration.SetToDefaults();
	LuaEvents.MainMenu_SetLoadGameServerType(ServerType.SERVER_TYPE_NONE);
	GameConfiguration.SetWorldBuilderEditor(true);
	local loadGameMenu = ContextPtr:LookUpControl( "/FrontEnd/MainMenu/LoadGameMenu" );
	UIManager:QueuePopup(loadGameMenu, PopupPriority.Current);
end

function OnImportWorldBuilderMap()
	UIManager:QueuePopup(Controls.WorldBuilder, PopupPriority.Current);
end

-- *******************************************************************************
--	MENUS need to be defined here as the callbacks reference functions which
--	are defined above.
-- *******************************************************************************


-- ===============================================================================
-- Sub Menu Option Tables
--	--------------------------------------------------------------------------
--	label - the text string for the button (un-localized)
--	callback - the function to call from this button
--	tooltip - the tooltip for this button
--	buttonState - a function to call which will update the buttonstate and tooltip
-- ===============================================================================
local m_SinglePlayerSubMenu :table = {
								{label = "LOC_MAIN_MENU_RESUME_GAME",		callback = OnResumeGame,	tooltip = "LOC_MAINMENU_RESUME_GAME_TT", buttonState = UpdateResumeGame},
								{label = "LOC_LOAD_GAME",					callback = OnLoadSinglePlayer,	tooltip = "LOC_MAINMENU_LOAD_GAME_TT",},
								{label = "LOC_SETUP_CREATE_GAME",			callback = OnAdvancedSetup,	tooltip = "LOC_MAINMENU_CREATE_GAME_TT"},
								{label = "LOC_SETUP_SCENARIOS",				callback = OnScenarioSetup,	tooltip = "LOC_MAINMENU_SCENARIOS_TT", buttonState = UpdateScenariosButton},
								{label = "LOC_PLAY_CIVILIZATION_6",			callback = OnPlayCiv6,	tooltip = "LOC_MAINMENU_PLAY_NOW_TT"},
							

							};

local m_MultiPlayerSubMenu :table = {
								{label = "LOC_MULTIPLAYER_CLOUD_GAME",			callback = OnPlayByCloud,			tooltip = "LOC_MULTIPLAYER_CLOUD_GAME_TT", buttonState = UpdateCloudGamesButton},
								{label = "LOC_MULTIPLAYER_INTERNET_GAME",		callback = OnInternet,				tooltip = "LOC_MULTIPLAYER_INTERNET_GAME_TT", buttonState = UpdateInternetButton},
								{label = "LOC_MULTIPLAYER_CROSSPLAY_GAME",		callback = OnCrossPlay,				tooltip = "LOC_MULTIPLAYER_CROSSPLAY_GAME_TT", buttonState = UpdateCrossPlayButton},
								{label = "LOC_MULTIPLAYER_LAN_GAME",			callback = OnLANGame,				tooltip = "LOC_MULTIPLAYER_LAN_GAME_TT"},
								{label = "LOC_MULTIPLAYER_HOTSEAT_GAME",		callback = OnHotSeat,				tooltip = "LOC_MULTIPLAYER_HOTSEAT_GAME_TT"},
								{space = true},
								{label = "LOC_MULTIPLAYER_MATCHMAKE_CIVROYALE",	callback = GetOnMatchMakeFunction(OPTION_SEEN_CIVROYALE_INTRO, StartRoyaleMatchMaking, LuaEvents.MainMenu_ShowCivRoyaleIntro),	tooltip = "LOC_MULTIPLAYER_MATCHMAKE_CIVROYALE_TT", colorName = "RoyaleButtonCS",  helpCallback = OnCivRoyaleHowToPlay, helpTooltip = "LOC_MULTIPLAYER_HOWTOPLAY_CIVROYALE_TT", buttonState = GetHowToButtonUpdateFunction(m_howToRoyaleControl, MOD_CIVROYALE_GUID)},
								{label = "LOC_MULTIPLAYER_MATCHMAKE_PIRATES",	callback = GetOnMatchMakeFunction(OPTION_SEEN_PIRATES_INTRO, StartPiratesMatchMaking, LuaEvents.MainMenu_ShowPiratesIntro),	tooltip = "LOC_MULTIPLAYER_MATCHMAKE_PIRATES_TT", colorName = "PiratesButtonCS",  helpCallback = OnPiratesHowToPlay, helpTooltip = "LOC_MULTIPLAYER_HOWTOPLAY_PIRATES_TT", buttonState = GetHowToButtonUpdateFunction(m_howToPiratesControl, MOD_PIRATES_GUID)}
							};

local m_AdditionalSubMenu :table = {
								{label = "LOC_MAIN_MENU_MODS",					callback = OnMods,					tooltip = "LOC_MAIN_MENU_MODS_AND_DLC_TT"},
								{label = "LOC_MAIN_MENU_HALL_OF_FAME",			callback = OnHallofFame,			tooltip = "LOC_MAIN_MENU_HALL_OF_FAME_TT"},
								{label = "LOC_MAIN_MENU_CREDITS",				callback = OnCredits,				tooltip = "LOC_MAINMENU_CREDITS_TT"},
							};

local m_BenchmarkSubMenu :table = {
								{label = "LOC_BENCHMARK_GRAPHICS",			callback = OnGraphicsBenchmark,		tooltip = "LOC_BENCHMARK_GRAPHICS_TT"},
								{label = "LOC_BENCHMARK_AI",				callback = OnAIBenchmark,			tooltip = "LOC_BENCHMARK_AI_TT", buttonState = UpdateAIBenchmark},
								{label = "LOC_BENCHMARK_EXP2_GRAPHICS",		callback = OnExp2GraphicsBenchmark,	tooltip = "LOC_BENCHMARK_EXP2_GRAPHICS_TT", buttonState = UpdateExp2GraphicsBenchmark},
								{label = "LOC_BENCHMARK_EXP2_AI",			callback = OnExp2AIBenchmark,		tooltip = "LOC_BENCHMARK_EXP2_AI_TT", buttonState = UpdateExp2AIBenchmark},
							};

local m_WorldBuilderSubMenu :table = {
								{label = "LOC_WORLD_BUILDER_START_NEW",			callback = OnNewWorldBuilderMap,   	tooltip = "LOC_WORLD_BUILDER_START_NEW_TOOLTIP"},
								{label = "LOC_WORLD_BUILDER_LOAD",				callback = OnLoadWorldBuilderMap, 	tooltip = "LOC_WORLD_BUILDER_LOAD_TOOLTIP"},
								{label = "LOC_WORLD_BUILDER_IMPORT",		    callback = OnImportWorldBuilderMap,	tooltip = "LOC_WORLD_BUILDER_IMPORT_TOOLTIP"},
							};

-- ===========================================================================
--	Main Menu Option Tables
--	--------------------------------------------------------------------------
--	label - the text string for the button (un-localized)
--	callback - the function to call from this button
--	submenu - the submenu table to open for this button (defined above)
--	buttonState - a function to call which will update the buttonstate and tooltip
-- ===========================================================================
local m_preSaveMainMenuOptions :table = {	{label = "LOC_PLAY_CIVILIZATION_6",			callback = OnPlayCiv6}};  
local m_defaultMainMenuOptions :table = {	
								{label = "LOC_SINGLE_PLAYER",				callback = OnSinglePlayer,		tooltip = "LOC_MAINMENU_SINGLE_PLAYER_TT",			submenu = m_SinglePlayerSubMenu}, 
								{label = "LOC_PLAY_MULTIPLAYER",			callback = OnMultiPlayer,		tooltip = "LOC_MAINMENU_MULTIPLAYER_TT",			submenu = m_MultiPlayerSubMenu, buttonState = UpdateMultiplayerButton},
								{label = "LOC_MAIN_MENU_OPTIONS",			callback = OnOptions,			tooltip = "LOC_MAINMENU_GAME_OPTIONS_TT"},
								{label = "LOC_MAIN_MENU_ADDITIONAL_CONTENT",callback = OnAdditionalContent,	tooltip = "LOC_MAIN_MENU_ADDITIONAL_CONTENT_TT",	submenu = m_AdditionalSubMenu},
								{label = "LOC_MAIN_MENU_TUTORIAL",			callback = OnTutorial,			tooltip = "LOC_MAINMENU_TUTORIAL_TT"},
								{label = "LOC_MAIN_MENU_BENCH",				callback = OnBenchmark,			tooltip = "LOC_MAINMENU_BENCHMARK_TT",				submenu = m_BenchmarkSubMenu},
								{label = "LOC_WORLDBUILDER_TITLE",		    callback = OnWorldBuilder,		tooltip = "LOC_MAINMENU_WORLDBUILDER_TT", 			submenu = m_WorldBuilderSubMenu},								
								{label = "LOC_MAIN_MENU_EXIT_TO_DESKTOP",	callback = OnUserRequestClose,	tooltip = "LOC_MAINMENU_EXIT_GAME_TT"}
							};


-- ===========================================================================
--	Animation callback for top-menu option controls.
-- ===========================================================================
function TopMenuOptionAnimationCallback(control, progress)
	local progress :number = control:GetProgress();
													
	-- Only if the animation has just begun, play its sound
	if(not control:IsReversing() and progress <.1) then 
		UI.PlaySound("Main_Menu_Expand_Notch");				
	elseif(not control:IsReversing() and progress >.65) then 
		control:SetSpeed(.9);	-- As the flag is nearing the top of its bounce, slow it down
	end													
													
	-- After the flag animation has bounced, stop it at the correct position													
	if(control:IsReversing() and progress > .2) then
		control:SetProgress( 0.2 );
		control:Stop();																									
	elseif(control:IsReversing() and progress < .03) then
		control:SetSpeed(.4);	-- Right after the flag animation has bounced, slow it down dramatically
	end
end

-- ===========================================================================
--	Animation callback for sub-menu option controls.
-- ===========================================================================
function SubMenuOptionAnimationCallback(control, progress) 
	if(not control:IsReversing() and progress <.1) then 
		UI.PlaySound("Main_Menu_Panel_Expand_Short"); 
	elseif(not control:IsReversing() and progress >.65) then 
		control:SetSpeed(2);
	end
	if(control:IsReversing() and progress > .2) then
		control:SetProgress( 0.2 );
		control:Stop();														
	elseif(control:IsReversing() and progress < .03) then
		control:SetSpeed(1);
	end
end


function MenuOptionMouseEnterCallback()
	UI.PlaySound("Main_Menu_Mouse_Over"); 
end

-- ===========================================================================
--	Animates the main menu options in
--	ARG0:	menuOptions - Expects the table of options that is to appear on 
--			the topmost level - either [m_preSave/m_default]MainMenuOptions
-- ===========================================================================
function BuildMenu(menuOptions:table)
	m_mainOptionIM:ResetInstances();
	UI.PlaySound("Main_Menu_Panel_Expand_Top_Level");	
	local pauseAccumulator = m_initialPause + PAUSE_INCREMENT;
	for i, menuOption in ipairs(menuOptions) do

		-- Add the instances to the table and play the animations and add the sounds
		local option = m_mainOptionIM:GetInstance();
		option.ButtonLabel:LocalizeAndSetText(menuOption.label);
		option.SelectedLabel:LocalizeAndSetText(menuOption.label);
		option.LabelAlphaAnim:SetToBeginning();
		option.LabelAlphaAnim:Play();
		-- The label begin its alpha animation slightly after the flag begins to fly out
		option.LabelAlphaAnim:SetPauseTime(pauseAccumulator + .2);
		option.OptionButton:RegisterCallback( Mouse.eLClick, function() 
																--If a submenu exists, specify the index and pass the submenu along to the callback
																if (menuOption.submenu ~= nil) then 
																	menuOption.callback(i, menuOption.submenu);
																else  
																	menuOption.callback();
																end
															end);
		option.OptionButton:RegisterCallback( Mouse.eMouseEnter, MenuOptionMouseEnterCallback);

		-- Define a custom animation curve and sounds for the button flag - this function is called for every frame
		option.FlagAnim:RegisterAnimCallback(TopMenuOptionAnimationCallback);
		-- Will not be called due to "Bounce" cycle being used: option.FlagAnim:RegisterEndCallback( function() print("done!"); end ); 
		option.FlagAnim:SetPauseTime(pauseAccumulator);
		option.FlagAnim:SetSpeed(4);
		option.FlagAnim:SetToBeginning();
		option.FlagAnim:Play();

		
		option.Top:LocalizeAndSetToolTip(menuOption.tooltip);

		-- Use special button update function if it exists for this menu option.
		if (menuOption.buttonState ~= nil) then
			menuOption.buttonState(option); 
		end	
		
		-- Accumulate a pause so that the flags appear one at a time
		pauseAccumulator = pauseAccumulator + PAUSE_INCREMENT;
		-- Track which options are being displayed and preserve the selection state so that we can rebuild a submenu
		m_currentOptions[i] = {control = option, isSelected = false};
	end
	Controls.MainMenuOptionStack:CalculateSize();


	local trackHeight = Controls.MainMenuOptionStack:GetSizeY() + TRACK_PADDING;
	-- Make sure the vertical div line is correctly sized for the number of options and draw it in
	Controls.MainButtonTrack:SetSizeY(trackHeight);
	Controls.MainButtonTrackAnim:SetBeginVal(0,-trackHeight);
	Controls.MainButtonTrackAnim:Play();
	Controls.MainMenuClip:SetSizeY(trackHeight);
end

-- ===========================================================================
--	Builds the table of submenu options
--	ARG0:	menuOptions - Expects the table specified in the 'submenu' field 
--			of the m_defaultMainMenuOptions table	
--
--	WB: While this function shares a fair amount of code with BuildMenu, 
--	I have decided to keep them separate as I continue differentiate behavior
--	and tweak the animations. 
-- ===========================================================================
function BuildSubMenu(menuOptions:table)
	m_subOptionIM:ResetInstances();
	for i, kMenuOption in ipairs(menuOptions) do

		local uiOption = m_subOptionIM:GetInstance();
		if kMenuOption.space then
			-- Do nothing, animate nothing.
			uiOption.FlagAnim:SetToBeginning();
			uiOption.FlagAnim:Stop();
			uiOption.OptionButton:SetHide(true);
			uiOption.Top:LocalizeAndSetToolTip("");		-- Clear any prior tooltip
		else
			-- Add the instances to the table and play the animations and add the sounds
			-- * Submenu options animate in all at once, instead of one at at a time	
			
			uiOption.ButtonLabel:LocalizeAndSetText(kMenuOption.label);
			uiOption.SelectedLabel:LocalizeAndSetText(kMenuOption.label);			
			uiOption.LabelAlphaAnim:SetToBeginning();
			uiOption.LabelAlphaAnim:Play();
			uiOption.LabelAlphaAnim:SetPauseTime(0);
			uiOption.OptionButton:RegisterCallback( Mouse.eLClick, kMenuOption.callback);
			uiOption.OptionButton:RegisterCallback( Mouse.eMouseEnter, MenuOptionMouseEnterCallback);
			uiOption.OptionButton:SetHide(false);

			-- * Submenu options have a slightly different animation curve as well as a different animation sound
			uiOption.FlagAnim:RegisterAnimCallback(SubMenuOptionAnimationCallback);

			-- Will not be called due to "Bounce" cycle being used: option.FlagAnim:RegisterEndCallback( function() print("done!"); end ); 
			uiOption.FlagAnim:SetSpeed(4);
			uiOption.FlagAnim:SetToBeginning();
			uiOption.FlagAnim:Play();

			uiOption.Top:LocalizeAndSetToolTip(kMenuOption.tooltip);
		
			-- Set a special disabled state for buttons (right now, only the Internet button has this function)
			if (kMenuOption.buttonState ~= nil) then
				kMenuOption.buttonState(uiOption); 
			else
				--ATTN:TRON For some reason my instances are not being completely reset when I rebuild the my list here
				-- So I have to reset my tooltip string and button state.
				uiOption.OptionButton:SetDisabled(false);
				uiOption.ButtonLabel:SetColorByName( "ButtonCS" );
			end
			if kMenuOption.colorName then
				uiOption.ButtonLabel:SetColorByName( kMenuOption.colorName );
			end

			if (kMenuOption.helpCallback ~= nil) then
				uiOption.HelpButton:LocalizeAndSetToolTip(kMenuOption.helpTooltip);
				uiOption.HelpButton:RegisterCallback( Mouse.eLClick, kMenuOption.helpCallback);
			end

		end		
	end

	Controls.SubMenuOptionStack:CalculateSize();
	local trackHeight = Controls.SubMenuOptionStack:GetSizeY() + TRACK_PADDING;
	Controls.SubButtonTrack:SetSizeY(trackHeight);
	Controls.SubButtonTrackAnim:SetBeginVal(0,-trackHeight);
	-- * The track line for the submenu also draws in more quickly since all the options are feeding in at once
	Controls.SubButtonTrackAnim:SetSpeed(5);
	Controls.SubButtonTrackAnim:SetToBeginning();
	Controls.SubButtonTrackAnim:Play();
	Controls.SubMenuClip:SetSizeY(trackHeight);
	Controls.SubMenuAlpha:SetSizeY(trackHeight);
	Controls.SubButtonClip:SetSizeY(trackHeight);
	Controls.SubMenuContainer:SetSizeY(Controls.MainMenuClip:GetSizeY());
end


-- =============================================================================
--	Searches the menu table for a value which contains a matching [label]. If 
--	found, that index is removed
--	ARG0:	menu - the parent menu table.  Expects options to have a name 
--			string in the [label] field to compare against
--	ARG1:	option - the table containing both the [label] and [callback] 
--			for the submenu option
-- =============================================================================
function RemoveOptionFromMenu(menu:table, option:table)
	for i=1, table.count(menu) do
		if(menu[i] ~= nil) then
			if(menu[i].label == option.label) then
				table.remove(menu,i);
			end
		end
	end
end

-- =============================================================================
--	Searches the menu table for a value which contains a matching [label]. If 
--	that value is NOT found, the submenu option is inserted at the first index
--	ARG0:	menu - the parent menu table.  Expects options to have a name 
--			string in the [label] field to compare against
--	ARG1:	option - the table containing both the [label] and [callback] 
--			for the submenu option
--	ARG2:	(OPTIONAL) index - the index of the submenu where the option should
--			be inserted.
-- =============================================================================
function AddOptionToMenu(menu:table, option:table, index:number)
	local hasOption = false;
	if (index == nil) then
		index = 1;
	end
	for i=1, table.count(menu) do
		if(menu[i].label == option) then
			hasOption = true;
		end
	end
	if (not hasOption) then
		table.insert(menu,submenu,1);
	end
end

-- =============================================================================
--	Called from the ESC handler and also when we show the screen
--	Rebuilds the menu taking into account any submenus that were already open
-- =============================================================================
function BuildAllMenus()

	if m_isQuitting then 
		return; 
	end

	-- Reset cached buttons to make sure we don't reference reused instances
	m_resumeButton = nil;
	m_internetButton = nil;
	m_scenariosButton = nil;
	m_multiplayerButton = nil;
	m_cloudGamesButton = nil;
	m_matchRoyaleButton = nil;
	m_howToRoyaleControl = nil;
	m_matchPiratesButton = nil;
	m_howToPiratesControl = nil;

	-- WISHLIST: When we rebuild the menus, let's check to see if there are ANY saved games whatsoever.  
	-- If none exist, then do not display the option in the submenu. (See: OnFileListQueryResults)
	local selectedIndex = -1;
	for i=1, table.count(m_currentOptions) do
		if(m_currentOptions[i].isSelected) then
			selectedIndex = i;
		end
	end
	if(selectedIndex ~= -1) then
		if(m_defaultMainMenuOptions[selectedIndex].submenu ~= nil) then
			BuildSubMenu(m_defaultMainMenuOptions[selectedIndex].submenu);
		else
			BuildMenu(m_defaultMainMenuOptions);
		end
	else
		BuildMenu(m_defaultMainMenuOptions);
	end
end

function SetCarouselEnabled(enabled)
	Controls.ChallengeLButton:SetEnabled(enabled);
	Controls.ChallengeRButton:SetEnabled(enabled);
	local children = Controls.ChallengeStack:GetChildren();
	for i=1, #children do
		children[i]:GetChildren()[1]:SetEnabled(enabled);
	end

	m_carouselAutoscrollEnabled = enabled;
end

function CarouselSetSelectedEntry(index, scrollType)
	m_currentCarouselEntry = index;

	Challenges.PublishCarouselEntryImpression(m_currentCarouselEntry - 1, scrollType);

	m_carouselIndicatorIM:ResetInstances();
	local entryCount = Challenges.GetCarouselEntryCount();
	for i=1, entryCount do
		local instance = m_carouselIndicatorIM:GetInstance();

		if i == m_currentCarouselEntry then
			instance.CarouselIndicatorImage:SetTextureOffsetVal(0,14);
		else
			instance.CarouselIndicatorImage:SetTextureOffsetVal(0,0);
		end
	end
end

function CarouselGetOffsetValue(index)
	local svWidth = Controls.ChallengeStack:GetSizeX();

	local dummyInstance = Controls.ChallengeStack:GetChildren()[1];
	local entryWidth = dummyInstance:GetSizeX();

	local offset = (entryWidth * index) / (Controls.ChallengeStack:GetSizeX() - entryWidth);

	return offset;
end

function UpdateChallengeCarousel()
	if not FiraxisLive.IsCOPPALocked() then
		local entryCount = Challenges.GetCarouselEntryCount();
		m_carouselDisplayDurationMS = Challenges.GetCarouselDisplayDurationMS();
		if m_carouselDisplayDurationMS < 1000 then
			m_carouselDisplayDurationMS = 1000
		end
		m_carouselAnimationDurationMS = Challenges.GetCarouselAnimationDurationMS();
		if m_carouselAnimationDurationMS <= 100 then
			m_carouselAnimationDurationMS = 100
		end

		m_carouselEntryIM:ResetInstances();

		if entryCount == 0 then
			Controls.ChallengeContainer:SetShow(false);
			m_currentCarouselEntry = 0;
			return;
		end

		-- To make scrolling past the ends look nice, add an extra entry to either end.
		for i=0,(entryCount + 1) do
			local entryIndex = i - 1;
			if entryIndex == -1 then
				entryIndex = entryCount - 1;
			elseif entryIndex == entryCount then
				entryIndex = 0;
			end

			local instance = m_carouselEntryIM:GetInstance();
			
			instance.CarouselEntryButton:RegisterCallback( Mouse.eLClick, 
				function(selected)
					Challenges.PublishCarouselEntryClick(selected);

					local carouselEntryType = Challenges.GetCarouselEntryType(selected);
					if carouselEntryType == "Clickout" then
						Challenges.LoadCarouselEntry(selected);
					else -- Challenge entry
						-- Let Lua do transition and load challenge once that is done.
						_StartChallengeEntry = selected;
						LuaEvents.Raise_State_Transition("MainMenu");
					end
				end
			);

			Challenges.BindCarouselEntryImageToButtonControl(entryIndex, instance.CarouselEntryButton);
			instance.CarouselEntryButton:SetVoid1(entryIndex);
		end

		if entryCount <= 1 then
			-- Don't bother showing arrows and page indicator if there is only one entry.
			Controls.ChallengeLButton:SetHide(true);
			Controls.ChallengeRButton:SetHide(true);
			Controls.ChallengeIndicatorStack:SetHide(true);
		else
			Controls.ChallengeLButton:SetHide(false);
			Controls.ChallengeRButton:SetHide(false);
			Controls.ChallengeIndicatorStack:SetHide(false);
		end

		Controls.ChallengeStack:CalculateSize();
		Controls.ChallengeScroll:CalculateSize();

		CarouselSetSelectedEntry(1, "initial");
		Controls.ChallengeContainer:SetShow(true);
		Controls.ChallengeScroll:SetScrollValue(CarouselGetOffsetValue(1));
	else
		Controls.ChallengeLButton:SetHide(true);
		Controls.ChallengeRButton:SetHide(true);
		Controls.ChallengeIndicatorStack:SetHide(true);

		Controls.ChallengeContainer:SetShow(false);
	end
end

function CarouselScrollToEntry(index, scrollType)
	if index == m_currentCarouselEntry then return end;

	m_carouselAnimation.active = true;
	m_carouselAnimation.time = 0;
	m_carouselAnimation.startValue = Controls.ChallengeScroll:GetScrollValue();
	m_carouselAnimation.destinationValue = CarouselGetOffsetValue(index);
	m_carouselAnimation.destinationIndex = index;
	m_carouselAnimation.scrollType = scrollType;

	Controls.ChallengeLButton:SetEnabled(false);
	Controls.ChallengeRButton:SetEnabled(false);
end

function CarouselFinishedScrollingToEntry(index, scrollType)
	local entryCount = Challenges.GetCarouselEntryCount();
	if index == (entryCount + 1) then
		index = 1;
	elseif index == 0 then
		local oldIndex = index;
		index = entryCount;
		local newValue = CarouselGetOffsetValue(index);
	end

	Controls.ChallengeScroll:SetScrollValue(CarouselGetOffsetValue(index));

	CarouselSetSelectedEntry(index, scrollType);
	m_carouselCurrentSlideDurationMS = 0;

	m_carouselAnimation.active = false;
	m_carouselAnimation.time = 0;
	m_carouselAnimation.startValue = 0;
	m_carouselAnimation.destinationValue = 0;
	m_carouselAnimation.destinationIndex = 0;
	m_carouselAnimation.scrollType = "";

	Controls.ChallengeLButton:SetEnabled(true);
	Controls.ChallengeRButton:SetEnabled(true);
end

function OnCarouselButtonLClicked()
	local newEntry = m_currentCarouselEntry - 1;
	CarouselScrollToEntry(newEntry, "manual scroll");
end

function CarouselScrollRight(scrollType)
	local newEntry = m_currentCarouselEntry + 1;
	CarouselScrollToEntry(newEntry, scrollType);
end

function OnCarouselButtonRClicked(scrollType)
	CarouselScrollRight("manual scroll")
end

function OnChallengePackageUpdated()
	print("OnChallengePackageUpdated");
	UpdateChallengeCarousel()
end

function ShowNewChallengeAvailablePopup()
	if (Challenges.ShouldShowNewPackageAvailablePopup()) then
		local popupText = Challenges.GetLocalizedNewChallengePackagePopupText();
		g_PopupDialog:ShowOkDialog(popupText, function() end); 
	end
end

-- ===========================================================================
--	UI Callback
--	Restart animation on show
-- ===========================================================================
function OnShow()

	-- Re-enable the play now button.
	_ClickedPlayNow = nil;

	local save = Options.GetAppOption("Debug", "PlayNowSave");
	if (save ~= nil) then
		--If we have a save specified in AppOptions, then only display the play button
		BuildMenu(m_preSaveMainMenuOptions);
	else
		BuildAllMenus();
	end
	GameConfiguration.SetToDefaults();
	UI.SetSoundStateValue("Game_Views", "Main_Menu");
	LuaEvents.UpdateFiraxisLiveState();

	local pFriends = Network.GetFriends();
	if (pFriends ~= nil) then
		pFriends:SetRichPresence("civPresence", "LOC_PRESENCE_IN_SHELL");
	end

	local gameType = SaveTypes.SINGLE_PLAYER;
	local saveLocation = SaveLocations.LOCAL_STORAGE;

	g_MostRecentSave = nil;
	g_LastFileQueryRequestID = nil;
	local options = SaveLocationOptions.NORMAL + SaveLocationOptions.AUTOSAVE + SaveLocationOptions.QUICKSAVE + SaveLocationOptions.MOST_RECENT_ONLY + SaveLocationOptions.LOAD_METADATA ;
	g_LastFileQueryRequestID = UI.QuerySaveGameList( saveLocation, gameType, options );

	local error = Modding.GetLastLoadError();
	if (not m_bHasShownError and error ~= nil) then
		m_bHasShownError = true;

		if error == DB.MakeHash("CHALLENGE_FAILURE") then
			-- The "multiplayer" popup actually shows a generic frontend popup, so that's why
			-- we use it here.
			LuaEvents.MultiplayerPopup(Locale.Lookup("LOC_CHALLENGE_GAME_START_ERROR"), "LOC_GAME_START_ERROR_TITLE");
		else
			local reasonString;
			if error == DB.MakeHash("UNKNOWN_VERSION") then
				reasonString = "LOC_GAME_START_ERROR_UNKNOWN_VERSION";
			elseif error == DB.MakeHash("MOD_CONTENT") then
				reasonString = "LOC_GAME_START_ERROR_MOD_CONTENT";
			elseif error == DB.MakeHash("MOD_CONFIG") then
				reasonString = "LOC_GAME_START_ERROR_MOD_CONFIG";
			elseif error == DB.MakeHash("MOD_OWNERSHIP") then
				reasonString = "LOC_GAME_START_ERROR_MOD_OWNERSHIP";
			elseif error == DB.MakeHash("SCRIPT_PROCESSING") then
				reasonString = "LOC_GAME_START_ERROR_SCRIPT_PROCESSING";
			else
				reasonString = string.format("%X", error);
			end

			local error_string = Locale.Lookup("LOC_GAME_START_ERROR_DESC") .. "[NEWLINE][NEWLINE]" .. Locale.Lookup("LOC_GAME_START_ERROR_CODE", reasonString);
			LuaEvents.MainMenu_LaunchError(error_string);
		end
	end

	m_checkedCloudNotify = false;
	UpdateCheckCloudNotify();
	RealizeTooltipBehavior();
	UpdateChallengeCarousel();

	ShowNewChallengeAvailablePopup();

	ContextPtr:SetUpdate( OnUpdate );
end

function OnHide()
	-- Set the pause to 0 as soon as we hide the main menu, so it loads in right 
	-- away when we return from any screen.
	m_bHasShownError = nil;
	m_initialPause = 0;

	ContextPtr:ClearUpdate();
end

-- Call-back for when the list of files have been updated.
function OnFileListQueryResults( fileList, queryID )
	if g_LastFileQueryRequestID ~= nil then
		if (g_LastFileQueryRequestID == queryID) then
			g_MostRecentSave = nil;
			if (fileList ~= nil) then
				for i, v in ipairs(fileList) do
					g_MostRecentSave = v;		-- There really should only be one or 
				end
			
				UpdateResumeGame();
			end

			UI.CloseFileListQuery(g_LastFileQueryRequestID);
			g_LastFileQueryRequestID = nil;
		end
	end
	
end

-- ===========================================================================
function OnCycleMotD()
	if (ms_MotDIndex == nil) then
		ms_MotDIndex = 0;
	else
		ms_MotDIndex = ms_MotDIndex + 1;
	end

	UpdateMotD();
end

-- ===========================================================================
function OnFiraxisLiveActivate(bActive)
	UpdateCheckCloudNotify();
end

function UpdateCheckCloudNotify()
	if(not m_checkedCloudNotify) then
		local kandoConnected = FiraxisLive.IsFiraxisLiveLoggedIn();
		if(kandoConnected) then
			m_checkedCloudNotify = true;
		end
	end
end

-- ===========================================================================
--	Realize the design of the "Civilization" logo and the background movie
--	to play, based on the (lack of) expansion loaded.
-- ===========================================================================
function RealizeLogoAndMovie()
	local logos :table = DB.ConfigurationQuery("SELECT LogoTexture, LogoMovie from Logos ORDER BY Priority DESC LIMIT 1");
	if(logos and #logos > 0) then
		local logo:table = logos[1];
		if(logo and g_LogoTexture ~= logo.LogoTexture and g_LogoMovie ~= logo.LogoMovie) then
			g_LogoTexture = logo.LogoTexture
			g_LogoMovie = logo.LogoMovie

			-- change texture
			Controls.Logo:SetTexture(g_LogoTexture);				

			-- change movie
			local movieControl:table = ContextPtr:LookUpControl("/FrontEnd/BackgroundMovie");
			if(movieControl ~= nil) then
				movieControl:SetMovie(g_LogoMovie, true);

				-- Save some bandwidth if playing via remote desktop.
				local iMovieDisabled: boolean = (Options.GetAppOption("UI", "EnablePausedShellMovies") == 1);
				if iMovieDisabled then
					-- Pause needs to occur one frame later so create lambda via refresh handler.
					ContextPtr:SetRefreshHandler( 
						function()
							movieControl:Pause();
							ContextPtr:ClearRefreshHandler();
						end
					);			
					ContextPtr:RequestRefresh();	
				end
			end
		end
	end
end


-- ===========================================================================
function OnMy2KLinkAccountResult(bSuccess)
	-- account link status changes can toggle the cloud games button.
	UpdateCloudGamesButton();
end

-- ===========================================================================
function OnGameplayContentChanged( kEvent )
	if(kEvent.Success and kEvent.ConfigurationChanged) then
		RealizeLogoAndMovie();
	end
end

-- ===========================================================================
function OnShutdown()
	if Controls.Logo:IsTextureLoaded() then
		Controls.Logo:UnloadTexture();
	end	
end

-- ===========================================================================
function CarouselTween(a, b, t)
	return a + (b - a) * t;
end

-- ===========================================================================
function OnUpdate( fDeltaTime )
	if not FiraxisLive.IsCOPPALocked() then
		if (Challenges.ShouldShowRestartToGetNewPackagePopup(g_PopupDialog:IsOpen())) then
			g_PopupDialog:ShowOkDialog(Locale.Lookup("LOC_NEW_PACKAGE_ON_SERVER"));
		end

		if m_carouselAnimation.active then
			local newTime = m_carouselAnimation.time + fDeltaTime * 1000;

			if newTime >= m_carouselSlideAnimationDurationMS then
				Controls.ChallengeScroll:SetScrollValue(m_carouselAnimation.destinationValue);
				CarouselFinishedScrollingToEntry(m_carouselAnimation.destinationIndex, m_carouselAnimation.scrollType);
			else
				local newValue = CarouselTween(m_carouselAnimation.startValue, m_carouselAnimation.destinationValue, newTime / m_carouselSlideAnimationDurationMS);
				Controls.ChallengeScroll:SetScrollValue(newValue);
				m_carouselAnimation.time = newTime;
			end
		else
			if m_carouselAutoscrollEnabled then
				m_carouselCurrentSlideDurationMS = m_carouselCurrentSlideDurationMS + fDeltaTime * 1000;
			else
				m_carouselCurrentSlideDurationMS = 0 -- always reset when disabled
			end
			if m_carouselCurrentSlideDurationMS >= m_carouselDisplayDurationMS then
				-- Note that we do not reset the current slide displayed duration here because it 
				-- is reset every time the carousel is scrolled, whether automatically or not, and
				-- we don't want it to autoscroll right after the user has manually scrolled it.
				CarouselScrollRight("auto scroll");
			end
		end
	else
		Controls.ChallengeLButton:SetHide(true);
		Controls.ChallengeRButton:SetHide(true);
		Controls.ChallengeIndicatorStack:SetHide(true);

		Controls.ChallengeContainer:SetShow(false);
	end

	if mgr ~= nil then
		mgr:OnUpdate()
	end
end

-- ===========================================================================
function Initialize()

	UI.CheckUserSetup();
	UIManager:DisablePopupQueue( false );	-- If coming back from a (PBC) game, it is possible this may have been left on; ensure popups work or the main menu won't show.	

	-- Remove the Play By Cloud option if it is not available
	if(not Network.HasCapability("CloudGame")) then
		local l_CloudGame : table = { label = "LOC_MULTIPLAYER_CLOUD_GAME" };
		RemoveOptionFromMenu(m_MultiPlayerSubMenu, l_CloudGame);
	end

	if(not Network.HasCapability("FiraxisLiveSupport")) then
		Controls.My2KContents:SetShow(false);
	end

	ContextPtr:SetShowHandler( OnShow );
	ContextPtr:SetShutdown( OnShutdown );
	
	Controls.VersionLabel:SetText( UI.GetAppVersion() );
	Controls.My2KLogin:RegisterCallback( Mouse.eLClick, OnMy2KLogin );
	Controls.My2KLogin:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);

	if (not UI.IsFinalRelease()) then
		Controls.MotDLogo:RegisterCallback( Mouse.eLClick, OnCycleMotD );
	end

	if not FiraxisLive.IsCOPPALocked() then
		Controls.ChallengeLButton:RegisterCallback( Mouse.eLClick, OnCarouselButtonLClicked );
		Controls.ChallengeRButton:RegisterCallback( Mouse.eLClick, OnCarouselButtonRClicked );
	end

	-- Game Events
	Events.SteamServersConnected.Add( UpdateInternetControls );
	Events.SteamServersDisconnected.Add( UpdateInternetControls );
	Events.CrossPlayServersDisconnected.Add( UpdateInternetControls );
	Events.CrossPlayServersConnected.Add( UpdateInternetControls );
	Events.MultiplayerGameLaunched.Add( OnGameLaunched );
    Events.UserRequestClose.Add( OnUserRequestClose );
	Events.UserConfirmedClose.Add( OnUserConfirmedClose );
	Events.CloudTurnCheckComplete.Add( OnCloudTurnCheckComplete );
	Events.CloudUnseenCompleteCheckComplete.Add( OnCloudUnseenCompleteCheckComplete );
	Events.FiraxisLiveActivate.Add( OnFiraxisLiveActivate );
	Events.My2KLinkAccountResult.Add( OnMy2KLinkAccountResult );
	Events.MarketingPushDataUpdated.Add( OnMarketingPushDataUpdated );
	Events.FinishedGameplayContentConfigure.Add( OnGameplayContentChanged );
	Events.SystemUpdateUI.Add( OnUpdateUI );

	-- LUA Events
	LuaEvents.FileListQueryResults.Add( OnFileListQueryResults );
	LuaEvents.MainMenu_ShowAdditionalContent.Add(OnMods);
	LuaEvents.CivRoyaleIntro_StartMatchMaking.Add(StartRoyaleMatchMaking);
	LuaEvents.PiratesIntro_StartMatchMaking.Add(StartPiratesMatchMaking);
	LuaEvents.StateTransition_SignalRaised.Add( OnStateTransition );
	LuaEvents.ChallengePackageUpdated.Add( OnChallengePackageUpdated );

	BuildAllMenus();
	UpdateMotD();
	RealizeLogoAndMovie();
end
--#Accessibility integration
include("caiUtils")
local mgr = ExposedMembers.CAI_UIManager

local MAIN_PANEL_ID    = "CAIMainMenu_Panel"
local MENU_LIST_ID     = "CAIMainMenu_MenuList"
-- local CAROUSEL_ID      = "CAIMainMenu_Carousel"
local MOTD_ID          = "CAIMainMenu_MotD"
local VERSION_ID       = "CAIMainMenu_Version"
local MY2K_ID          = "CAIMainMenu_My2K"
local SUBMENU_LIST_ID  = "CAIMainMenu_SubmenuList"

local m_MainPanel       ---@type UIWidget|nil
local m_MenuList        ---@type UIWidget|nil
-- local m_CarouselList    ---@type UIWidget|nil
local m_MotDWidget      ---@type UIWidget|nil
local m_VersionWidget   ---@type UIWidget|nil
local m_My2KWidget      ---@type UIWidget|nil
local m_SubmenuList     ---@type UIWidget|nil
local m_SubmenuParent   = nil       -- vanilla optionIndex of the mounted submenu's parent
local m_PendingParent   = nil       -- optionIndex captured in ToggleOption pre-orig, consumed by BuildSubMenu wrap
local m_LastMotDText    = ""        -- prior MotD text, for change-driven Announce
local m_CloudRowIdx     = nil       -- vanilla index of the Cloud Games row inside the current submenu
local m_MultiplayerIdx  = nil       -- vanilla optionIndex of the top-level Multiplayer row

local m_animGateUntil = 0
local function IsAnimating() return Automation.GetTime() < m_animGateUntil end

local EXCLUDED_MAIN_CALLBACKS = {
    [OnTutorial] = true,
    [OnBenchmark] = true,
    [OnWorldBuilder] = true,
}
local EXCLUDED_SUB_CALLBACKS = {
    [OnScenarioSetup] = true,
}

-- Vanilla highlight reuse: mirrors what mouse hover does in vanilla so the
-- sighted-mirror UI looks right while a CAI row is focused. Trigger from
-- focus_enter / focus_leave so highlights track focus rather than activation.
local function HighlightMainOption(idx)
    if not m_currentOptions or not m_currentOptions[idx] then return end
    local ctrl = m_currentOptions[idx].control
    if not ctrl then return end
    ctrl.SelectionAnimAlpha:SetToBeginning(); ctrl.SelectionAnimAlpha:Play()
    ctrl.SelectionAnimSlide:SetToBeginning(); ctrl.SelectionAnimSlide:Play()
end

local function HighlightSubmenuInstance(uiOption)
    if not uiOption then return end
    if uiOption.SelectedLabel and uiOption.ButtonLabel then
        uiOption.SelectedLabel:SetHide(false)
        uiOption.ButtonLabel:SetHide(true)
    end
    if uiOption.LabelAlphaAnim then
        uiOption.LabelAlphaAnim:SetToBeginning(); uiOption.LabelAlphaAnim:Play()
    end
    if uiOption.FlagAnim then
        uiOption.FlagAnim:SetToBeginning(); uiOption.FlagAnim:Play()
    end
end

local function ClearSubmenuHighlight(uiOption)
    if not uiOption then return end
    if uiOption.SelectedLabel and uiOption.ButtonLabel then
        uiOption.SelectedLabel:SetHide(true)
        uiOption.ButtonLabel:SetHide(false)
    end
    if uiOption.FlagAnim then
        uiOption.FlagAnim:SetToBeginning(); uiOption.FlagAnim:Stop()
    end
end

local function RemoveSubmenuWidget()
    if not m_SubmenuList then return end
    mgr:RemoveFromStack(SUBMENU_LIST_ID)
    m_SubmenuList = nil
    m_SubmenuParent = nil
    m_CloudRowIdx = nil
end

-- Carousel commented out: entries have no text labels, useless for screen readers.
-- local function BuildCarouselRows()
--     if not m_CarouselList then return end
--     local capture = mgr:CaptureFocusKey(m_CarouselList)
--     m_CarouselList:ClearChildren()
--     local entryCount = Challenges.GetCarouselEntryCount()
--     for i = 0, entryCount - 1 do
--         local entryIndex = i
--         local entryNum = i + 1
--         local btn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIMainMenu_CarouselBtn"), "Button", {
--             Label = function()
--                 local entryType = Challenges.GetCarouselEntryType(entryIndex)
--                 local typeLabel = entryType == "Clickout"
--                     and Locale.Lookup("LOC_CAI_CAROUSEL_LINK")
--                     or Locale.Lookup("LOC_CAI_CAROUSEL_CHALLENGE")
--                 return Locale.Lookup("LOC_CAI_CAROUSEL_ENTRY", typeLabel, entryNum, entryCount)
--             end,
--             FocusKey = "carousel:" .. tostring(entryIndex),
--             SpeechSettings = { Role = false },
--         })
--         btn:On("activate", function()
--             Challenges.PublishCarouselEntryClick(entryIndex)
--             local t = Challenges.GetCarouselEntryType(entryIndex)
--             if t == "Clickout" then
--                 Challenges.LoadCarouselEntry(entryIndex)
--             else
--                 _StartChallengeEntry = entryIndex
--                 LuaEvents.Raise_State_Transition("MainMenu")
--             end
--         end)
--         btn:On("focus_enter", function()
--             CarouselScrollToEntry(entryNum, "manual scroll")
--         end)
--         m_CarouselList:AddChild(btn)
--     end
--     mgr:RestoreFocus(m_CarouselList, capture)
-- end

local function BuildMainPanelOnce()
    if m_MainPanel then return end

    m_MainPanel = mgr:CreateWidget(MAIN_PANEL_ID, "Panel", {
        Label = function() return Locale.Lookup("LOC_CAI_MAIN_MENU") end,
        SpeechSettings = { Role = false },
    })

    m_MenuList = mgr:CreateWidget(MENU_LIST_ID, "List")
    m_MainPanel:AddChild(m_MenuList)

    -- Carousel commented out: entries have no text labels.
    -- m_CarouselList = mgr:CreateWidget(CAROUSEL_ID, "HorizontalList", {
    --     Label = function() return Locale.Lookup("LOC_CAI_CAROUSEL") end,
    --     HiddenPredicate = function() return Controls.ChallengeContainer:IsHidden() end,
    -- })
    -- m_CarouselList:On("focus_enter", function() SetCarouselEnabled(false) end)
    -- m_CarouselList:On("focus_leave", function() SetCarouselEnabled(true) end)
    -- m_MainPanel:AddChild(m_CarouselList)

    m_MotDWidget = mgr:CreateWidget(MOTD_ID, "StaticText", {
        Label = function() return Locale.Lookup("LOC_MESSAGE_OF_THE_DAY_HEADING").."[NEWLINE]"..Controls.MotDText:GetText() or "" end,
        HiddenPredicate = function() return Controls.MotDContainter:IsHidden() end,
    })
    m_MainPanel:AddChild(m_MotDWidget)

    m_VersionWidget = mgr:CreateWidget(VERSION_ID, "StaticText", {
        Label = function()
            return Locale.Lookup("LOC_PAUSEMENU_INFO_VERSION_TOOLTIP", UI.GetAppVersion())
        end,
    })
    m_MainPanel:AddChild(m_VersionWidget)

    m_My2KWidget = mgr:CreateWidget(MY2K_ID, "Button", {
        Label = function() return Locale.Lookup("TXT_KEY_MY2K") end,
        ValueGetter = function() return Controls.My2KStatus:GetText() or "" end,
        HiddenPredicate = function() return Controls.My2KContents:IsHidden() end,
    })
    m_My2KWidget:On("activate", function() Controls.My2KLogin:DoLeftClick() end)
    m_MainPanel:AddChild(m_My2KWidget)
end

local function RebuildMenuRows(menuOptions)
    if not m_MenuList then return end
    local capture = mgr:CaptureFocusKey(m_MenuList)
    m_MenuList:ClearChildren()
    m_MultiplayerIdx = nil

    for i, menuOption in ipairs(m_currentOptions) do
        local dataEntry = menuOptions[i]
        local controlRef = menuOption.control
        if dataEntry and controlRef and not EXCLUDED_MAIN_CALLBACKS[dataEntry.callback] then
            if dataEntry.callback == OnMultiPlayer then m_MultiplayerIdx = i end

            local row = mgr:CreateWidget(mgr:GenerateWidgetId("CAIMainMenu_MenuItem"), "MenuItem", {
                Label = function() return controlRef.ButtonLabel:GetText() end,
                Tooltip = function() return controlRef.Top:GetToolTipString() end,
                HiddenPredicate = function() return controlRef.Top:IsHidden() end,
                FocusKey = "main:" .. tostring(i),
            })
            row:On("activate", function()
                if IsAnimating() then return end
                controlRef.OptionButton:DoLeftClick()
            end)
            row:On("focus_enter", function()
                UI.PlaySound("Main_Menu_Mouse_Over")
                HighlightMainOption(i)
            end)
            m_MenuList:AddChild(row)
        end
    end

    mgr:RestoreFocus(m_MenuList, capture)
end

-- Hook the input handler onto the screen.
Initialize = WrapFunc(Initialize, function(orig)
    orig()
    ContextPtr:SetInputHandler(function(input)
        return mgr:HandleInput(input)
    end, true)
end)

-- BuildMenu fires on first paint AND on rebuilds (preSave -> default after the
-- save-file query, network loss reverting the menu, etc.). Any rebuild
-- invalidates an open submenu, so explicitly remove it via the manager.
BuildMenu = WrapFunc(BuildMenu, function(orig, menuOptions)
    orig(menuOptions)
    if not m_currentOptions or #m_currentOptions == 0 then return end

    m_animGateUntil = Automation.GetTime() + 0.3

    RemoveSubmenuWidget()
    BuildMainPanelOnce()
    RebuildMenuRows(menuOptions)
    -- BuildCarouselRows()

    -- Push exactly once. Subsequent BuildMenu rebuilds reuse the mounted panel.
    if mgr:GetWidgetById(MAIN_PANEL_ID) ~= m_MainPanel then
        mgr:Push(m_MainPanel)
    end
end)

-- ToggleOption is vanilla's single entry point for selecting/deselecting a
-- main-menu parent. Wrap it to:
--   pre-orig:  capture optionIndex into m_PendingParent so BuildSubMenu (which
--              fires inside orig before isSelected is set) knows which parent
--              this submenu belongs to.
--   post-orig: if the mounted submenu's parent is no longer selected (vanilla
--              just collapsed it), tear our widget down to match.
-- Invariant: do not call ToggleOption recursively from inside this wrap or
-- from a handler reached by orig — m_PendingParent would clobber.
ToggleOption = WrapFunc(ToggleOption, function(orig, optionIndex, submenu)
    m_PendingParent = optionIndex
    orig(optionIndex, submenu)
    if m_SubmenuParent and m_currentOptions
        and m_currentOptions[m_SubmenuParent]
        and not m_currentOptions[m_SubmenuParent].isSelected then
        RemoveSubmenuWidget()
    end
end)

BuildSubMenu = WrapFunc(BuildSubMenu, function(orig, menuOptions)
    orig(menuOptions)
    local controls = m_subOptionIM and m_subOptionIM.m_AllocatedInstances
    if not controls or #controls == 0 then return end

    -- Same parent re-fired BuildSubMenu (defensive — vanilla doesn't do this
    -- organically): leave the mounted widget alone.
    if m_SubmenuList and m_SubmenuParent == m_PendingParent then return end
    if m_SubmenuList then RemoveSubmenuWidget() end

    m_SubmenuParent = m_PendingParent
    m_SubmenuList = mgr:CreateWidget(SUBMENU_LIST_ID, "List", {
        Label = function()
            if m_SubmenuParent and m_currentOptions[m_SubmenuParent] then
                return m_currentOptions[m_SubmenuParent].control.ButtonLabel:GetText()
            end
            return ""
        end,
    })
    m_CloudRowIdx = nil
    -- Vanilla MainMenu has no Escape handler for submenus; forward the key
    -- through ToggleOption so the normal collapse path runs. The ToggleOption
    -- wrap removes our widget when vanilla flips isSelected to false. Vanilla's
    -- own IsStopped guard implicitly handles the "animation in progress" case
    -- by no-opping the call, matching mouse-click behavior.
    m_SubmenuList:AddInputBinding({
        Key = Keys.VK_ESCAPE,
        Description = "LOC_CAI_KB_CLOSE",
        Action = function()
            if m_SubmenuParent then ToggleOption(m_SubmenuParent) end
            return true
        end,
    })

    for i, data in ipairs(menuOptions) do
            local control = controls[i]
            if control and not EXCLUDED_SUB_CALLBACKS[data.callback] then
                if data.callback == OnPlayByCloud then m_CloudRowIdx = i end
                local labelText = control.ButtonLabel:GetText()
                if data.helpCallback ~= nil then
                    local group = mgr:CreateWidget(mgr:GenerateWidgetId("CAIMainMenu_SubMenu"), "SubMenu", {
                        Label = function() return labelText end,
                        HiddenPredicate = function() return control.Top:IsHidden() end,
                        FocusKey = "sub:" .. tostring(i),
                    })
                    group:On("focus_enter", function() HighlightSubmenuInstance(control) end)
                    group:On("focus_leave", function() ClearSubmenuHighlight(control) end)

                    local playBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIMainMenu_PlayBtn"), "MenuItem", {
                        Label = function() return Locale.Lookup("LOC_PLAY_CIVILIZATION_6") end,
                        Tooltip = function() return control.Top:GetToolTipString() end,
                        DisabledPredicate = function() return control.OptionButton:IsDisabled() end,
                    })
                    playBtn:On("activate", function() control.OptionButton:DoLeftClick() end)
                    playBtn:On("focus_enter", function() HighlightSubmenuInstance(control) end)
                    group:AddChild(playBtn)

                    local helpBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIMainMenu_HelpBtn"), "MenuItem", {
                        Label = function() return Locale.Lookup("LOC_CAI_HELP") end,
                        Tooltip = function() return control.HelpButton:GetToolTipString() end,
                        DisabledPredicate = function() return control.HelpButton:IsDisabled() end,
                        HiddenPredicate = function() return control.HelpButton:IsHidden() end,
                    })
                    helpBtn:On("activate", function()
                        control.HelpButton:DoLeftClick()
                    end)
                    group:AddChild(helpBtn)

                    m_SubmenuList:AddChild(group)
                else
                    local row = mgr:CreateWidget(mgr:GenerateWidgetId("CAIMainMenu_SubItem"), "MenuItem", {
                        Label = function() return labelText end,
                        Tooltip = function() return control.Top:GetToolTipString() end,
                        DisabledPredicate = function() return control.OptionButton:IsDisabled() end,
                        HiddenPredicate = function() return data.space or control.Top:IsHidden() end,
                        FocusKey = "sub:" .. tostring(i),
                    })
                    row:On("activate", function() control.OptionButton:DoLeftClick() end)
                    row:On("focus_enter", function() HighlightSubmenuInstance(control) end)
                    row:On("focus_leave", function() ClearSubmenuHighlight(control) end)
                    m_SubmenuList:AddChild(row)
                end
            end
    end

    mgr:Push(m_SubmenuList)
end)

-- UpdateChallengeCarousel = WrapFunc(UpdateChallengeCarousel, function(orig)
--     orig()
--     if m_CarouselList then BuildCarouselRows() end
-- end)

-- MotD updates fire while the menu is open (UI.GetPushData polling); only
-- re-announce when the text actually changed and the widget is focused.
UpdateMotD = WrapFunc(UpdateMotD, function(orig)
    orig()
    if not m_MotDWidget then return end
    local text = Controls.MotDText:GetText() or ""
    if text == m_LastMotDText then return end
    m_LastMotDText = text
        m_MotDWidget:Announce({ "label" })
end)

-- Cloud / MP labels mutate on incoming notifications. If the matching row is
-- focused, Refocus re-speaks the new label without changing the focus path.
UpdateMultiplayerButton = WrapFunc(UpdateMultiplayerButton, function(orig, btn)
    orig(btn)
    if not (m_MenuList and m_MultiplayerIdx) then return end
    local row = mgr:FindByFocusKey(m_MenuList, "main:" .. tostring(m_MultiplayerIdx))
    if row and mgr:GetFocusedWidget() == row then mgr:Refocus() end
end)

UpdateCloudGamesButton = WrapFunc(UpdateCloudGamesButton, function(orig, btn)
    orig(btn)
    if not (m_SubmenuList and m_CloudRowIdx) then return end
    local row = mgr:FindByFocusKey(m_SubmenuList, "sub:" .. tostring(m_CloudRowIdx))
    if row and mgr:GetFocusedWidget() == row then mgr:Refocus() end
end)

function OnAppRegainedFocusHandler()
	mgr:TouchAppRegainedFocusTimer()
end

OnShutdown = WrapFunc(OnShutdown, function(orig, ...) orig(...) mgr:ShutDown() end)
ContextPtr:SetShutdown(OnShutdown)
ContextPtr:SetAppRegainedFocusHandler( OnAppRegainedFocusHandler );
--#End of accessibility integration
Initialize()
