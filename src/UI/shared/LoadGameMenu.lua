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
	if key == Keys.VK_UP or key == Keys.VK_DOWN then
		if #g_FileList > 0 then
			local newIndex = g_iSelectedFileEntry;
			if g_iSelectedFileEntry == -1 then
				newIndex = 1;
			elseif key == Keys.VK_UP then
				newIndex = newIndex - 1;
				if newIndex < 1 then
					newIndex = #g_FileList;
				end
			elseif key == Keys.VK_DOWN then
				newIndex = newIndex + 1;
				if newIndex > #g_FileList then
					newIndex = 1;
				end
			end
			if newIndex ~= g_iSelectedFileEntry then
				SetSelected(newIndex);
			end
		end
		return true;
	end
	if key == Keys.VK_DELETE then
		if g_iSelectedFileEntry ~= -1 then
			OnDelete();
		end
		return true;
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
--#Accessibility integration
include("caiUtils")
local mgr = ExposedMembers.CAI_UIManager

local CAI_Panel = nil
local CAI_FileList = nil
local CAI_InspectorList = nil

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function SafeText(ctrl)
	if ctrl and ctrl.GetText then
		return ctrl:GetText() or ""
	end
	return ""
end

local function SafeTooltip(ctrl)
	if ctrl and ctrl.GetToolTipString then
		return ctrl:GetToolTipString() or ""
	end
	return ""
end

local function LookupBundleOrText(value)
	if value then
		local text = Locale.LookupBundle(value)
		if text == nil or text == "" then
			text = Locale.Lookup(value)
		end
		return text or ""
	end
	return ""
end

local function JoinParts(parts)
	local out = {}
	for _, part in ipairs(parts) do
		if part and part ~= "" then
			table.insert(out, part)
		end
	end
	return table.concat(out, ", ")
end

local function GetSelectedFileInfo()
	if g_FileList and g_iSelectedFileEntry and g_iSelectedFileEntry > 0 then
		return g_FileList[g_iSelectedFileEntry]
	end
	return nil
end

local function GetCurrentSortLabel()
	local button = Controls.SortByPullDown and Controls.SortByPullDown:GetButton()
	return button and button:GetText() or ""
end

local function GetCurrentDirectoryLabel()
	local button = Controls.DirectoryPullDown and Controls.DirectoryPullDown:GetButton()
	return button and button:GetText() or ""
end

local function GetEntryControl(idx)
	return g_FileEntryInstanceList and g_FileEntryInstanceList[idx] or nil
end

local function GetEntryLabel(idx, entry)
	local instance = GetEntryControl(idx)
	if instance and instance.ButtonText and instance.ButtonText.GetText then
		local text = instance.ButtonText:GetText()
		if text and text ~= "" then
			return text
		end
	end

	if entry and entry.DisplayName and entry.DisplayName ~= "" then
		return entry.DisplayName
	end

	if entry then
		return GetDisplayName(entry)
	end

	return ""
end

local function GetShortEntrySummary()
	return JoinParts({
		SafeText(Controls.SelectedCurrentTurnLabel),
		SafeText(Controls.SelectedTimeLabel),
		SafeText(Controls.SelectedHostEraLabel),
	})
end

local function ClosePanel()
	if CAI_Panel and mgr:HasWidget(CAI_Panel) then
		mgr:Pop()
	end
end

local function AddInspectorRow(label, value)
	if not CAI_InspectorList then return end
	if not value or value == "" then return end

	local text = label and label ~= "" and (label .. ", " .. value) or value
	CAI_InspectorList:AddChild(mgr:CreateUIWidget("MenuItem", {
		GetLabel = function()
			return text
		end,
	}))
end

local function RebuildInspectorAccessibility()
	if not CAI_InspectorList then return end
	CAI_InspectorList:ClearChildren()

	local fileInfo = GetSelectedFileInfo()
	if not fileInfo or fileInfo.IsDirectory then
		return
	end

	local function AddHeader(text)
		if not text or text == "" then return end
		CAI_InspectorList:AddChild(mgr:CreateUIWidget("MenuItem", {
			GetLabel = function()
				return text
			end,
		}))
	end

	AddInspectorRow(Locale.Lookup("LOC_CAI_LABEL_FILE_NAME"), SafeText(Controls.FileName))
	AddInspectorRow(nil, SafeText(Controls.SelectedCurrentTurnLabel))
	AddInspectorRow(Locale.Lookup("LOC_CAI_LABEL_SAVE_TIME"), SafeText(Controls.SelectedTimeLabel))
	AddInspectorRow(Locale.Lookup("LOC_CAI_LABEL_ERA"), SafeText(Controls.SelectedHostEraLabel))
	AddInspectorRow(Locale.Lookup("LOC_CAI_LABEL_CIV"), SafeTooltip(Controls.CivIcon))
	AddInspectorRow(Locale.Lookup("LOC_CAI_LABEL_LEADER"), SafeTooltip(Controls.LeaderIcon))
	AddInspectorRow(Locale.Lookup("LOC_AD_SETUP_DIFFICULTY"), SafeTooltip(Controls.GameDifficulty))
	AddInspectorRow(Locale.Lookup("LOC_GAME_SPEED"), SafeTooltip(Controls.GameSpeed))

	-- Game options section
	AddHeader(Locale.Lookup("LOC_LOADSAVE_GAME_OPTIONS_HEADER_TITLE"))

	local rulesetName = LookupBundleOrText(fileInfo.RulesetName)
	AddInspectorRow(Locale.Lookup("LOC_LOADSAVE_GAME_OPTIONS_RULESET_TYPE_TITLE"), rulesetName)

	if fileInfo.EnabledGameModes then
		local modeNames = {}
		local enabledModes = Modding.GetGameModesFromConfigurationString(fileInfo.EnabledGameModes)
		for _, v in ipairs(enabledModes) do
			if v and v.Name and v.Name ~= "" then
				table.insert(modeNames, v.Name)
			end
		end
		if #modeNames > 0 then
			AddInspectorRow(Locale.Lookup("LOC_MULTIPLAYER_LOBBY_GAMEMODES_OFFICIAL"), table.concat(modeNames, ", "))
		end
	end

	local mapScriptName = LookupBundleOrText(fileInfo.MapScriptName)
	AddInspectorRow(Locale.Lookup("LOC_LOADSAVE_GAME_OPTIONS_MAP_TYPE_TITLE"), mapScriptName)

	local mapSizeName = LookupBundleOrText(fileInfo.MapSizeName)
	AddInspectorRow(Locale.Lookup("LOC_LOADSAVE_GAME_OPTIONS_MAP_SIZE_TITLE"), mapSizeName)

	if fileInfo.SavedByVersion and fileInfo.SavedByVersion ~= "" then
		AddInspectorRow(Locale.Lookup("LOC_LOADSAVE_SAVED_BY_VERSION_TITLE"), fileInfo.SavedByVersion)
	end

	if fileInfo.TunerActive == true then
		AddInspectorRow(Locale.Lookup("LOC_LOADSAVE_TUNER_ACTIVE_TITLE"), Locale.Lookup("LOC_YES_BUTTON"))
	end

	-- Additional content / mods section
	local mods
	if g_FileType == SaveFileTypes.GAME_CONFIGURATION then
		mods = fileInfo.EnabledMods or {}
	else
		mods = fileInfo.RequiredMods or {}
	end

	if #mods > 0 then
		AddHeader(Locale.Lookup("LOC_MAIN_MENU_ADDITIONAL_CONTENT"))

		local modErrors = Modding.CheckRequirements(mods, g_GameType)
		if not Challenges.IsNullChallengeUuid(fileInfo.GameChallengeUuid) then
			for _, v in ipairs(mods) do
				if modErrors and modErrors[v.Id] == "NotAllowed" then
					modErrors[v.Id] = nil
				end
			end
		end

		local modTitles = {}
		for _, v in ipairs(mods) do
			local title = nil
			local modHandle = Modding.GetModHandle(v.Id)
			if modHandle then
				local modInfo = Modding.GetModInfo(modHandle)
				if modInfo and modInfo.Name then
					title = Locale.Lookup(modInfo.Name)
				end
			end
			if not title or title == "" then
				title = LookupBundleOrText(v.Title)
			end

			if title and title ~= "" then
				if modErrors and modErrors[v.Id] then
					table.insert(modTitles, title .. ", " .. Locale.Lookup("LOC_GAME_START_ERROR_TITLE"))
				else
					table.insert(modTitles, title)
				end
			end
		end

		table.sort(modTitles, function(a, b) return Locale.Compare(a, b) == -1 end)

		for _, title in ipairs(modTitles) do
			AddInspectorRow(nil, title)
		end
	end
end

-- ---------------------------------------------------------------------------
-- Accessible pulldown overlays
-- ---------------------------------------------------------------------------
local function OpenSortDropdown()
	local optList = mgr:CreateUIWidget("List", {
		GetLabel = function()
			return Controls.WindowHeader:GetText()
		end,
	})

	optList:AddInputBinding({
		Key = Keys.VK_ESCAPE,
		Action = function()
			mgr:Pop()
			return true
		end
	})

	local options = {
		{ "LOC_SORTBY_LASTMODIFIED", SortByLastModified, 1 },
		{ "LOC_SORTBY_NAME", SortByName, 2 },
	}

	local selectedChild = nil
	for _, v in ipairs(options) do
		local labelKey = v[1]
		local sortFunc = v[2]
		local sortIndex = v[3]

		local child = mgr:CreateUIWidget("MenuItem", {
			GetLabel = function()
				return Locale.Lookup(labelKey)
			end,
			OnFocusEnter = function()
				UI.PlaySound("Main_Menu_Mouse_Over")
			end,
			OnClick = function()
				Controls.SortByPullDown:GetButton():LocalizeAndSetText(labelKey)
				g_CurrentSort = sortFunc

				if g_GameType == SaveTypes.WORLDBUILDER_MAP then
					Options.SetUserOption("Interface", "WorldBuilderMapBrowseSortDefault", sortIndex)
				else
					Options.SetUserOption("Interface", "SaveGameBrowseSortDefault", sortIndex)
				end
				Options.SaveOptions()

				RebuildFileList()
				mgr:Pop()
			end,
		})

		optList:AddChild(child)

		if GetCurrentSortLabel() == Locale.Lookup(labelKey) then
			selectedChild = child
		end
	end

	if selectedChild then
		optList.FocusedChild = selectedChild
	end

	mgr:Push(optList)
end

local function OpenDirectoryDropdown()
	if Controls.DirectoryPullDown:IsHidden() then
		return
	end

	local optList = mgr:CreateUIWidget("List", {
		GetLabel = function()
			return Controls.WindowHeader:GetText()
		end,
	})

	optList:AddInputBinding({
		Key = Keys.VK_ESCAPE,
		Action = function()
			mgr:Pop()
			return true
		end
	})

	local selectedChild = nil
	local usingVolumeName = nil

	if g_CurrentDirectorySegments then
		for i = #g_CurrentDirectorySegments, 1, -1 do
			local v = g_CurrentDirectorySegments[i]
			local displayName = (v.DisplayName ~= nil and v.DisplayName ~= "") and v.DisplayName or v.SegmentName

			local child = mgr:CreateUIWidget("MenuItem", {
				GetLabel = function()
					return displayName
				end,
				OnFocusEnter = function()
					UI.PlaySound("Main_Menu_Mouse_Over")
				end,
				OnClick = function()
					ChangeDirectoryLevelTo(i)
					mgr:Pop()
				end,
			})

			optList:AddChild(child)

			if displayName == GetCurrentDirectoryLabel() then
				selectedChild = child
			end

			if i == 1 then
				usingVolumeName = v.SegmentName
			end
		end
	end

	if g_VolumeList == nil then
		g_VolumeList = UI.GetVolumes(SaveLocations.LOCAL_STORAGE)
	end

	if g_VolumeList then
		for _, v in ipairs(g_VolumeList) do
			if usingVolumeName == nil or usingVolumeName ~= v.VolumeName then
				local displayName = (v.DisplayName ~= nil and v.DisplayName ~= "") and v.DisplayName or v.VolumeName
				local volumeName = v.VolumeName

				local child = mgr:CreateUIWidget("MenuItem", {
					GetLabel = function()
						return displayName
					end,
					OnFocusEnter = function()
						UI.PlaySound("Main_Menu_Mouse_Over")
					end,
					OnClick = function()
						ChangeVolumeTo(volumeName)
						mgr:Pop()
					end,
				})

				optList:AddChild(child)
			end
		end
	end

	if selectedChild then
		optList.FocusedChild = selectedChild
	end

	mgr:Push(optList)
end

-- ---------------------------------------------------------------------------
-- Rebuild the accessible file list
-- ---------------------------------------------------------------------------
local function RebuildFileListAccessibility()
	if not CAI_FileList then return end
	CAI_FileList:ClearChildren()

	if not g_FileList or #g_FileList == 0 then
		local emptyChild = mgr:CreateUIWidget("MenuItem", {
			GetLabel = function()
				return Controls.NoGames:GetText() or ""
			end,
		})
		CAI_FileList:AddChild(emptyChild)
		CAI_FileList.FocusedChild = emptyChild
		return
	end

	local focusIdx = g_iSelectedFileEntry
	if not focusIdx or focusIdx < 1 or focusIdx > #g_FileList then
		focusIdx = 1
	end

	local focusedChild = nil

	for idx, entry in ipairs(g_FileList) do
		local child = mgr:CreateUIWidget("MenuItem", {
			GetLabel = function()
				return GetEntryLabel(idx, entry)
			end,
			GetTooltip = function()
				return GetShortEntrySummary()
			end,
			GetValue = function()
				return (g_iSelectedFileEntry == idx)
					and Locale.Lookup("LOC_OPTIONS_ENABLED")
					or ""
			end,
			OnFocusEnter = function()
				UI.PlaySound("Main_Menu_Mouse_Over")
				if g_iSelectedFileEntry ~= idx then
					SetSelected(idx)
					RebuildInspectorAccessibility()
				end
			end,
			OnClick = function()
				OnActionButton()
			end,
		})

		child:AddInputBinding({
			Key = Keys.VK_DELETE,
			Action = function()
				if not Controls.Delete:IsHidden() then
					OnDelete()
					return true
				end
				return false
			end
		})

		CAI_FileList:AddChild(child)

		if idx == focusIdx then
			focusedChild = child
		end
	end

	if focusedChild then
		CAI_FileList.FocusedChild = focusedChild
	end
end

-- ---------------------------------------------------------------------------
-- Build panel
-- ---------------------------------------------------------------------------
local function BuildPanel()
	CAI_Panel = mgr:CreateUIWidget("Dialog", {
		GetLabel = function()
			return Controls.WindowHeader:GetText()
		end,
		SpeechSettings = { Role = false },
	})

	CAI_Panel:AddInputBinding({
		Key = Keys.VK_ESCAPE,
		Action = function()
			OnBack()
			return true
		end
	})

	CAI_Panel:AddChild(mgr:CreateUIWidget("Button", {
		GetLabel = function()
			return Controls.BackButton:GetText()
		end,
		OnFocusEnter = function()
			UI.PlaySound("Main_Menu_Mouse_Over")
		end,
		OnClick = function()
			OnBack()
		end,
	}))

	local autoSaveCheckbox = mgr:CreateUIWidget("Checkbox", {
		GetLabel = function()
			return Controls.AutoCheck:GetText()
		end,
		GetValue = function()
			return Controls.AutoCheck:IsSelected()
				and Locale.Lookup("LOC_OPTIONS_ENABLED")
				or Locale.Lookup("LOC_OPTIONS_DISABLED")
		end,
		IsHidden = function()
			return Controls.AutoCheck:IsHidden()
		end,
		Toggle = function()
			OnAutoCheck()
		end,
		OnFocusEnter = function()
			UI.PlaySound("Main_Menu_Mouse_Over")
		end,
	})
	CAI_Panel:AddChild(autoSaveCheckbox)

	CAI_Panel:AddChild(mgr:CreateUIWidget("Checkbox", {
		GetLabel = function()
			local base
			if not Controls.CloudDummy:IsHidden() then
				base = Controls.CloudDummy:GetText()
			else
				base = Controls.CloudCheck:GetText()
			end

			local isNew = (not Controls.CheckNewIndicator:IsHidden()) or (not Controls.DummyNewIndicator:IsHidden())
			if isNew then
				-- TODO: localize
				return base .. ", new"
			end

			return base
		end,
		GetTooltip = function()
			if not Controls.CloudDummy:IsHidden() then
				return SafeTooltip(Controls.CloudDummy)
			end
			return SafeTooltip(Controls.CloudCheck)
		end,
		GetValue = function()
			return Controls.CloudCheck:IsSelected()
				and Locale.Lookup("LOC_OPTIONS_ENABLED")
				or Locale.Lookup("LOC_OPTIONS_DISABLED")
		end,
		IsHidden = function()
			return Controls.CloudCheck:IsHidden() and Controls.CloudDummy:IsHidden()
		end,
		IsDisabled = function()
			if not Controls.CloudDummy:IsHidden() then
				return Controls.CloudDummy:IsDisabled()
			end
			return Controls.CloudCheck:IsDisabled()
		end,
		Toggle = function()
			if not Controls.CloudCheck:IsDisabled() then
				OnCloudCheck()
			end
		end,
		OnFocusEnter = function()
			UI.PlaySound("Main_Menu_Mouse_Over")
		end,
	}))

	CAI_Panel:AddChild(mgr:CreateUIWidget("DropdownMenu", {
		GetLabel = function()
			return Locale.Lookup("LOC_SORTBY_NAME")
		end,
		GetValue = function()
			return GetCurrentSortLabel()
		end,
		IsHidden = function()
			return Controls.SortByPullDown:IsHidden()
		end,
		OnFocusEnter = function()
			UI.PlaySound("Main_Menu_Mouse_Over")
		end,
		OnClick = function()
			OpenSortDropdown()
		end,
	}))

	CAI_Panel:AddChild(mgr:CreateUIWidget("DropdownMenu", {
		GetLabel = function()
			return GetCurrentDirectoryLabel()
		end,
		IsHidden = function()
			return Controls.DirectoryPullDown:IsHidden()
		end,
		OnFocusEnter = function()
			UI.PlaySound("Main_Menu_Mouse_Over")
		end,
		OnClick = function()
			OpenDirectoryDropdown()
		end,
	}))

	CAI_FileList = mgr:CreateUIWidget("List", {
		GetLabel = function()
			return Controls.WindowHeader:GetText()
		end,
	})
	CAI_Panel:AddChild(CAI_FileList)

	CAI_InspectorList = mgr:CreateUIWidget("List", {
		GetLabel = function()
			local name = SafeText(Controls.FileName)
			-- TODO: localize this with arguments
			return name ~= "" and ("Details, " .. name) or "Details"
		end,
		IsHidden = function()
			return Controls.SelectedFile:IsHidden()
		end,
	})
	CAI_Panel:AddChild(CAI_InspectorList)

	CAI_Panel:AddChild(mgr:CreateUIWidget("Button", {
		GetLabel = function()
			return Controls.ActionButton:GetText()
		end,
		GetTooltip = function()
			return SafeTooltip(Controls.ActionButton)
		end,
		IsDisabled = function()
			return Controls.ActionButton:IsDisabled()
		end,
		IsHidden = function()
			return Controls.ActionButton:IsHidden()
		end,
		OnFocusEnter = function()
			UI.PlaySound("Main_Menu_Mouse_Over")
		end,
		OnClick = function()
			OnActionButton()
		end,
	}))

	CAI_Panel:AddChild(mgr:CreateUIWidget("Button", {
		GetLabel = function()
			return Controls.Delete:GetText()
		end,
		IsHidden = function()
			return Controls.Delete:IsHidden()
		end,
		IsDisabled = function()
			return Controls.Delete and Controls.Delete:IsDisabled()
		end,
		OnFocusEnter = function()
			UI.PlaySound("Main_Menu_Mouse_Over")
		end,
		OnClick = function()
			OnDelete()
		end,
	}))

	CAI_Panel.FocusedChild = autoSaveCheckbox
end

-- ---------------------------------------------------------------------------
-- Wrapped show/hide only
-- ---------------------------------------------------------------------------
OnShow = WrapFunc(OnShow, function(orig, ...)
	orig(...)

	if CAI_Panel and mgr:HasWidget(CAI_Panel) then
		mgr:Pop()
	end

	CAI_Panel = nil
	CAI_FileList = nil
	CAI_InspectorList = nil

	BuildPanel()

	ContextPtr:SetInputHandler(function(input)
		if mgr:HandleInput(input) then return true end
		return OnInputHandler(input)
	end, true)

	LuaEvents.FileListQueryComplete.Remove(RebuildFileListAccessibility)
	LuaEvents.FileListQueryComplete.Add(RebuildFileListAccessibility)
	mgr:Push(CAI_Panel)
end)

OnHide = WrapFunc(OnHide, function(orig, ...)
	LuaEvents.FileListQueryComplete.Remove(RebuildFileListAccessibility)

	orig(...)

	ClosePanel()
end)

-- ---------------------------------------------------------------------------
-- Re-register wrapped handlers
-- ---------------------------------------------------------------------------
ContextPtr:SetShowHandler(OnShow)
ContextPtr:SetHideHandler(OnHide)
ContextPtr:SetInputHandler(function(input)
	if mgr:HandleInput(input) then return true end
	return OnInputHandler(input)
end, true)
--#End of accessibility integration
Initialize();

