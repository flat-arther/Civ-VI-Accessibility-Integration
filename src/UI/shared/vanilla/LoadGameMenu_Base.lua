include( "InstanceManager" );
include( "SupportFunctions" );
include( "Civ6Common" );
include( "LoadSaveMenu_Shared" );	-- Shared code between the LoadGameMenu and the SaveGameMenu
include( "PopupDialog" );
include( "LocalPlayerActionSupport" );


local RELOAD_CACHE_ID: string = "LoadGameMenu";		-- hotloading

local MIN_SCREEN_Y       :number = 768;
local SCREEN_OFFSET_Y    :number = 63;
local MIN_SCREEN_OFFSET_Y:number = -53;

-------------------------------------------------
-- Globals
-------------------------------------------------
local serverType : number = ServerType.SERVER_TYPE_NONE;
local m_thisLoadFile;
local m_QuickloadId;
local m_isActionButtonDisabled:boolean = false;	-- Action button state before yes/no prompt
g_IsDeletingFile = false;

g_QuickLoadQueryRequestID = nil;

----------------------------------------------------------------        
----------------------------------------------------------------        
function OnLoadNo()
	m_kPopupDialog:Close();
end

function OnLoadConfirmModCompatibility()

	-- Disallow loading challenge games in multiplayers	
	if(serverType ~= ServerType.SERVER_TYPE_NONE and 
	   not Challenges.IsNullChallengeUuid(m_thisLoadFile.GameChallengeUuid)) then
		m_kPopupDialog:AddText(Locale.Lookup("LOC_CHALLENGE_MP_SAVEGAME_START_ERROR"));
		m_kPopupDialog:AddTitle(Locale.ToUpper(Locale.Lookup("LOC_GAME_START_ERROR_TITLE")));
		m_kPopupDialog:AddButton(Locale.Lookup("LOC_OK_BUTTON"), OnLoadNo);
		m_kPopupDialog:Open();

		return;
	end


	if(Modding.ShouldShowCompatibilityWarnings() and m_thisLoadFile) then

		local installedMods = Modding.GetInstalledMods();
		local enabledModsByHandle = {};

		for i,v in ipairs(installedMods) do
			enabledModsByHandle[v.Handle] = v.Enabled;
		end

		local incompatibleMods = {};
		local mods = m_thisLoadFile.RequiredMods or {};
		for i,v in ipairs(mods) do
			local mod = Modding.GetModHandle(v.Id);
			local isCompatible = Modding.IsModCompatible(mod);
			if(not isCompatible and enabledModsByHandle[mod] == false) then
				table.insert(incompatibleMods, mod);
			end
		end

		if(#incompatibleMods > 0) then

			local whitelistMods = false;

			function OnYes()
				if(whitelistMods) then
					for i,v in ipairs(incompatibleMods) do
						Modding.SetIgnoreCompatibilityWarnings(v, true);
					end
				end

				OnLoadYes();
			end
			
			m_kPopupDialog:AddText(Locale.Lookup("LOC_MODS_ENABLE_WARNING_NOT_COMPATIBLE_MANY"));
			m_kPopupDialog:AddTitle(Locale.ToUpper(Locale.Lookup("LOC_CONFIRM_TITLE_LOAD_TXT")));
			m_kPopupDialog:AddButton(Locale.Lookup("LOC_YES_BUTTON"), OnYes, nil, nil, "PopupButtonInstanceGreen"); 
			m_kPopupDialog:AddButton(Locale.Lookup("LOC_NO_BUTTON"), OnLoadNo);
			m_kPopupDialog:AddCheckBox(Locale.Lookup("LOC_MODS_WARNING_WHITELIST_MANY"), false, function(checked) whitelistMods = checked; end);
			m_kPopupDialog:Open();
		else
			OnLoadYes();
		end

	else
		OnLoadYes();
	end
	
end
----------------------------------------------------------------        
----------------------------------------------------------------        
function OnLoadYes()
	UITutorialManager:EnableOverlay( false );	
	UITutorialManager:HideAll();
	m_kPopupDialog:Close();

	-- Leave your current game if this is not a game configuration load.
	-- Game Configuration should keep the game in the current state (hostgame/advanced setup).
	if(g_FileType ~= SaveFileTypes.GAME_CONFIGURATION) then
		print("LoadGameMenu::OnLoadYes() leaving the network session.");
		Network.LeaveGame();
	end

    Network.LoadGame(m_thisLoadFile, serverType);
    Controls.ActionButton:SetDisabled( true );

    -- Don't DequeuePopup here.  
    -- In singleplayer, the entire lua context gets blasted once we transition to the LoadGameViewState.
    -- In multiplayer, the join room screen will send a JoiningRoom_Showing() to let us know it's safe to DequeuePopup.  See OnJoiningRoom_Showing().
end

----------------------------------------------------------------        
----------------------------------------------------------------        
function OnActionButton()
	if(not Controls.ActionButton:IsHidden() and not Controls.ActionButton:IsDisabled()) then
		UIManager:SetUICursor( 1 );
		m_thisLoadFile = g_FileList[ g_iSelectedFileEntry ];

		if (m_thisLoadFile) then
			if m_thisLoadFile.IsDirectory then
				-- Open the directory
				ChangeDirectoryTo(m_thisLoadFile.Path);
			else
    			local isInGame = false;
    			if(GameConfiguration ~= nil) then
    				isInGame = GameConfiguration.GetGameState() ~= GameStateTypes.GAMESTATE_PREGAME;
    			end

				if isInGame then
		   			if ( not m_kPopupDialog:IsOpen()) then
						m_kPopupDialog:AddText(Locale.Lookup("LOC_CONFIRM_LOAD_TXT"));
						m_kPopupDialog:AddTitle(Locale.ToUpper(Locale.Lookup("LOC_CONFIRM_TITLE_LOAD_TXT")));
						m_kPopupDialog:AddButton(Locale.Lookup("LOC_YES_BUTTON"), OnLoadConfirmModCompatibility, nil, nil, "PopupButtonInstanceGreen"); 
						m_kPopupDialog:AddButton(Locale.Lookup("LOC_NO_BUTTON"), OnLoadNo);
						m_kPopupDialog:Open();
					end
				else
					if (g_GameType ~= SaveTypes.TILED_MAP) then
						OnLoadConfirmModCompatibility();
					end
    			end

				if (g_GameType == SaveTypes.TILED_MAP) then
					MapConfiguration.SetImportFilename(m_thisLoadFile.Path);
					UI.SetWorldRenderView( WorldRenderView.VIEW_2D );
					Events.SetGameEntryMethod("Load Saved Game");
					Network.HostGame(ServerType.SERVER_TYPE_NONE);
				end
			end
        end
	end	
end

----------------------------------------------------------------        
----------------------------------------------------------------        
function OnBack()
	if m_kPopupDialog:IsOpen() then
		UI.DataError("Popup confirmation was open when closing the load game menu; it will be forced closed but it shouldn't be possible to close the load screen while this prompt is up.");
		m_kPopupDialog:Close();
	end

    UIManager:DequeuePopup( ContextPtr );
end

---------------------------------------------------------------- 
-- Show/Hide Handlers
---------------------------------------------------------------- 
function OnShow()
	LoadSaveMenu_OnShow();

	g_MenuType = LOAD_GAME;
	UpdateGameType();
	Controls.ActionButton:SetHide( false );
	Controls.ActionButton:SetDisabled( false );
	Controls.ActionButton:SetToolTipString(nil);
	m_isActionButtonDisabled = false;

	g_ShowCloudSaves = false;
	g_ShowAutoSaves = false;

	Controls.AutoCheck:SetSelected(false);
	Controls.CloudCheck:SetSelected(false);

	local cloudEnabled = UI.AreCloudSavesEnabled() and not GameConfiguration.IsAnyMultiplayer() and g_FileType ~= SaveFileTypes.GAME_CONFIGURATION and g_GameType ~= SaveTypes.WORLDBUILDER_MAP and g_GameType ~= SaveTypes.TILED_MAP;
	local cloudServicesEnabled,cloudServicesResult = UI.AreCloudSavesEnabled("LOAD");

	-- we want to show this in all cases
	Controls.CloudCheck:SetHide(false);
	
	local isNew = Options.GetAppOption("Misc", "UserSawCloudNew");
	Controls.CheckNewIndicator:SetHide(true);
	Controls.DummyNewIndicator:SetHide(true);
		
	if cloudEnabled then
		if UI.Is2KCloudAvailable() then
			Controls.CloudCheck:SetToolTipString(Locale.Lookup("LOC_2K_CLOUD_SAVES_HELP"));
			Controls.CloudCheck:SetText(Locale.Lookup("LOC_2K_CLOUD"));
			Controls.CloudDummy:SetHide(true);
			if (isNew == 0) then
				Controls.CheckNewIndicator:SetHide(false);
			end
		else
			Controls.CloudDummy:SetHide(false);
			Controls.CloudDummy:SetDisabled(true);
			Controls.CloudDummy:SetToolTipString(Locale.Lookup("LOC_2K_CLOUD_SAVES_HELP"));
			Controls.CloudCheck:SetToolTipString(Locale.Lookup("LOC_STANDARD_CLOUD_SAVES_HELP"));
			Controls.CloudCheck:SetText(Locale.Lookup("LOC_STEAMCLOUD"));
			if (isNew == 0) then
				Controls.DummyNewIndicator:SetHide(false);
			end
		end
	else
		Controls.CloudDummy:SetHide(true);
		if (isNew == 0) then
			Controls.CheckNewIndicator:SetHide(false);
		end

		if cloudServicesResult ~= nil then
			if cloudServicesResult == DB.MakeHash("REQUIRES_LINKED_ACCOUNT") then
				Controls.CloudCheck:LocalizeAndSetToolTip("LOC_CLOUD_SAVES_REQUIRE_LINKED_ACCOUNT");
			else
				Controls.CloudCheck:LocalizeAndSetToolTip("LOC_CLOUD_SAVES_SERVICE_NOT_CONNECTED");
			end
			Controls.CloudCheck:SetDisabled(true);
		end

		if g_GameType == SaveTypes.WORLDBUILDER_MAP or g_GameType == SaveTypes.TILED_MAP or g_FileType == SaveFileTypes.GAME_CONFIGURATION then
			Controls.CloudCheck:SetHide(true);
		else
			Controls.CloudCheck:SetHide(false);
		end
	end
		
	if (isNew == 0) then
		Options.SetAppOption("Misc", "UserSawCloudNew", 1);
	end
			
	local autoSavesDisabled = ((g_GameType == SaveTypes.WORLDBUILDER_MAP) or (g_GameType == SaveTypes.TILED_MAP));
	Controls.AutoCheck:SetHide(autoSavesDisabled);	

	RefreshSortPulldown();
	InitializeDirectoryBrowsing();
	SetupDirectoryBrowsePulldown();

	local autoSavesVisible = Controls.AutoCheck:IsVisible();
	local cloudSavesVisible = Controls.CloudCheck:IsVisible();
	local sortByVisible = Controls.SortByPullDown:IsVisible();
	local directoryVisible = Controls.DirectoryPullDown:IsVisible();
    local dummyCloudVisible = Controls.CloudDummy:IsVisible();

	local count:number = 0;
	if(autoSavesVisible) then
		count = count + 1;
	end
	if(cloudSavesVisible) then
		count = count + 1;
	end
	if(sortByVisible) then
		count = count + 1;
	end
	if(directoryVisible) then
		count = count + 1;
	end
	if(dummyCloudVisible) then
		count = count + 1;
	end
	
	local decoSize:number = Controls.InspectorArea:GetSizeY();
	
	Controls.DecoContainer:SetSizeY(decoSize - (count * 25) - count);	

	SetupFileList();
end

function OnHide()
	LoadSaveMenu_OnHide();
end


----------------------------------------------------------------        
----------------------------------------------------------------
function OnDelete()
	m_isActionButtonDisabled = Controls.ActionButton:IsDisabled();
	Controls.ActionButton:SetDisabled(true);
	if ( not m_kPopupDialog:IsOpen()) then
		m_kPopupDialog:AddText(Locale.Lookup("LOC_CONFIRM_TXT"));
		m_kPopupDialog:AddTitle(Locale.ToUpper(Locale.Lookup("LOC_CONFIRM_DELETE_TITLE_TXT")));
		m_kPopupDialog:AddButton(Locale.Lookup("LOC_YES_BUTTON"), OnDeleteYes, nil, nil, "PopupButtonInstanceRed"); 
		m_kPopupDialog:AddButton(Locale.Lookup("LOC_NO_BUTTON"), OnDeleteNo);
		m_kPopupDialog:Open();
	end
end

----------------------------------------------------------------        
----------------------------------------------------------------
function OnDeleteYes()
	m_kPopupDialog:Close();
	if (g_iSelectedFileEntry ~= -1) then
		local kSelectedFile = g_FileList[ g_iSelectedFileEntry ];		
		UI.DeleteSavedGame( kSelectedFile );
	end
	
	Controls.ActionButton:SetDisabled(m_isActionButtonDisabled);
	SetupFileList();
end

----------------------------------------------------------------        
----------------------------------------------------------------
function OnDeleteNo( )
	Controls.ActionButton:SetDisabled(m_isActionButtonDisabled);
	m_kPopupDialog:Close();
end

----------------------------------------------------------------        
----------------------------------------------------------------
function OnAutoCheck( )
	-- print("Auto Saves - " .. tostring(g_ShowAutoSaves));
	g_ShowAutoSaves = not g_ShowAutoSaves;
	Controls.AutoCheck:SetSelected(g_ShowAutoSaves);

	-- Mutually exclusive with other locations.
	if(g_ShowAutoSaves) then
		g_ShowCloudSaves = false;
		Controls.CloudCheck:SetSelected(g_ShowCloudSaves);
	end

	SetupFileList();
end

----------------------------------------------------------------        
----------------------------------------------------------------
function OnCloudCheck( )
	-- print("Cloud Saves - " .. tostring(g_ShowCloudSaves));

	local bWantShowCloudSaves = not g_ShowCloudSaves;

	if (bWantShowCloudSaves) then
		-- Make sure we can switch to it.
		if (not CanShowCloudSaves()) then
			return;
		end
	end

	g_ShowCloudSaves = bWantShowCloudSaves;

	Controls.CloudCheck:SetSelected(g_ShowCloudSaves);

	-- Mutually exclusive with other locations.
	if(g_ShowCloudSaves) then
		g_ShowAutoSaves = false;
		Controls.AutoCheck:SetSelected(g_ShowAutoSaves);
	end

	SetupDirectoryBrowsePulldown();
	SetupFileList();
	UpdateActionButtonState();
end


---------------------------------------------------------------- 
-- Event Handler: ChangeMPLobbyMode
---------------------------------------------------------------- 
function OnSetLoadGameServerType(newServerType)
	serverType = newServerType;
end

-- ===========================================================================
--	Input Processing
-- ===========================================================================
function KeyHandler( key:number )
	if key == Keys.VK_ESCAPE then
		if(m_kPopupDialog:IsOpen()) then
			m_kPopupDialog:Close();
		else
			OnBack();
		end		
		return true;
	end	
	if key == Keys.VK_RETURN then
        if(not Controls.ActionButton:IsHidden() and not Controls.ActionButton:IsDisabled()) then
            OnActionButton();
            return true;
        end
	end
	return false;
end
function OnInputHandler( pInputStruct:table )
	local uiMsg = pInputStruct:GetMessageType();
	if uiMsg == KeyEvents.KeyUp then KeyHandler( pInputStruct:GetKey() ); end;
    return true;
end

-- ===========================================================================
function OnInit(isReload:boolean)
	if isReload then
		LuaEvents.GameDebug_GetValues( RELOAD_CACHE_ID );
	end
end

-- ===========================================================================
function OnShutdown()
	-- Cache values for hotloading...
	LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "isHidden", ContextPtr:IsHidden());
end

-- ===========================================================================
function OnGameDebugReturn( context:string, contextTable:table )
	if context == RELOAD_CACHE_ID and contextTable["isHidden"] == false then
		UIManager:QueuePopup(ContextPtr, PopupPriority.Current);
	end	
end

-- ===========================================================================
function OnJoiningRoom_Showing()
	-- Remove ourself if the joining room screen is showing.
	UIManager:DequeuePopup( ContextPtr );
end

-- Call-back for when the list of files have been updated.
function OnQuickLoadQueryResults( fileList, queryID )
	if g_QuickLoadQueryRequestID ~= nil then
		if (g_QuickLoadQueryRequestID == queryID) then
			if (fileList ~= nil and #fileList > 0) then
				local save = fileList[1];
			
				local mods = save.RequiredMods or {};
	
				-- Test for errors.
				-- Will return a combination array/map of any errors regarding this combination of mods.
				-- Array messages are generalized error codes regarding the set.
				-- Map messages are error codes specific to the mod Id.
				local errors = Modding.CheckRequirements(mods, SaveTypes.SINGLE_PLAYER);
				local success = (errors == nil or errors.Success);

				if(success) then
					Network.LoadGame(save, serverType);
				end
			end

			UI.CloseFileListQuery(g_QuickLoadQueryRequestID);
			g_QuickLoadQueryRequestID = nil;
		end
	end
end

-- ===========================================================================
--	Hotkey Event
-- ===========================================================================
function OnInputActionTriggered( actionId )
    if actionId == m_QuickloadId then
        -- Quick load
        if CanLocalPlayerLoadGame() then
			g_QuickLoadQueryRequestID = nil;
			local options = SaveLocationOptions.QUICKSAVE + SaveLocationOptions.LOAD_METADATA ;
			g_QuickLoadQueryRequestID = UI.QuerySaveGameList( SaveLocations.LOCAL_STORAGE, SaveTypes.SINGLE_PLAYER, options );
        end
    end
end

-- ===========================================================================
--	Handle Window Sizing
-- ===========================================================================

function Resize()
	local screenX, screenY:number  = UIManager:GetScreenSizeVal();
	local hideLogo        :boolean = true;
	
	if(screenY >= MIN_SCREEN_Y + (Controls.LogoContainer:GetSizeY()+ Controls.LogoContainer:GetOffsetY() * 2)) then
		Controls.MainWindow:SetSizeY(screenY-(Controls.LogoContainer:GetSizeY() + Controls.LogoContainer:GetOffsetY() * 2));
		hideLogo = false;
	else
		Controls.MainWindow:SetSizeY(screenY);
	end
	
	Controls.LogoContainer:SetHide(hideLogo);
end

-- ===========================================================================
function OnUpdateUI( type:number, tag:string, iData1:number, iData2:number, strData1:string )   
	if type == SystemUpdateUI.ScreenResize then
		Resize();
	end
end

-- ===========================================================================
function OnFileListQueryComplete()
	UpdateActionButtonState();
end

-- ===========================================================================
function OnRefresh()
	SetupDirectoryBrowsePulldown();
	SetupFileList();
end

-- ===========================================================================
function OnLoadComplete(eResult, eType, eOptions, eFileType )

	-- Did a configuration load?
	if eFileType == SaveFileTypes.GAME_CONFIGURATION then

		if ContextPtr:IsVisible() then

			-- Doing this code inside the IsVisible if, because there are multiple instances of the LoadGameMenu

			-- Make sure the Game State is pre-game.  If the user loaded a auto-save of the configuration, or 
			-- got the configuration out of a save, it will be in a state where they can't edit some values.
			if (GameConfiguration ~= nil) then
				GameConfiguration.SetToPreGame();

				--Reset the seeds and leader selection when loading a config so that configs are more usable
				GameConfiguration.RegenerateSeeds();
				local playerIDs : table = GameConfiguration.GetParticipatingPlayerIDs();
				for k,v in ipairs(playerIDs)do
					local kPlayerConfig : table = PlayerConfigurations[v];
					local leaderTypeName : string = kPlayerConfig:GetLeaderTypeName();
					if(leaderTypeName ~= nil)then
						kPlayerConfig:SetLeaderTypeName(nil);
						kPlayerConfig:SetCivilizationTypeName(nil);
					end
				end
			end

			UIManager:DequeuePopup( ContextPtr );

		end
	end

end

-- ===========================================================================
function OnSelectedFileStackSizeChanged()
	ResizeGameInfoScrollPanel();
end

-- ===========================================================================
function Initialize()
	m_kPopupDialog = PopupDialog:new( "LoadGameMenu" );

	AutoSizeGridButton(Controls.BackButton,133,36);
	SetupSortPulldown();
	InitializeDirectoryBrowsing();
	Resize();

	LuaEvents.FileListQueryComplete.Add( OnFileListQueryComplete );

	-- UI Events
	ContextPtr:SetInputHandler( OnInputHandler, true );
	ContextPtr:SetShowHandler(OnShow);
	ContextPtr:SetHideHandler(OnHide);
	ContextPtr:SetInitHandler(OnInit);
	ContextPtr:SetRefreshHandler( OnRefresh );
	ContextPtr:SetShutdown(OnShutdown);
	LuaEvents.GameDebug_Return.Add(OnGameDebugReturn);
	LuaEvents.JoiningRoom_Showing.Add(OnJoiningRoom_Showing);

	-- UI Callbacks
	Controls.ActionButton:RegisterCallback( Mouse.eLClick, OnActionButton );
	Controls.ActionButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.AutoCheck:RegisterCallback( Mouse.eLClick, OnAutoCheck );
	Controls.BackButton:RegisterCallback( Mouse.eLClick, OnBack );
	Controls.BackButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.CloudCheck:RegisterCallback( Mouse.eLClick, OnCloudCheck );
	Controls.Delete:RegisterCallback( Mouse.eLClick, OnDelete );
	Controls.Delete:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.SelectedFileStack:RegisterSizeChanged( OnSelectedFileStackSizeChanged );

	-- LUA Events
	LuaEvents.HostGame_SetLoadGameServerType.Add( OnSetLoadGameServerType );
	LuaEvents.MainMenu_SetLoadGameServerType.Add( OnSetLoadGameServerType );
	LuaEvents.InGameTopOptionsMenu_SetLoadGameServerType.Add( OnSetLoadGameServerType );

	LuaEvents.FileListQueryResults.Add( OnQuickLoadQueryResults );

	Events.SystemUpdateUI.Add( OnUpdateUI );

    m_QuickloadId = Input.GetActionId("QuickLoad");
    Events.InputActionTriggered.Add( OnInputActionTriggered );
    Events.LoadComplete.Add( OnLoadComplete );
end
Initialize();