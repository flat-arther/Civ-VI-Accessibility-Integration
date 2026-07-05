-------------------------------------------------
-- Multiplayer Host Game Screen
-------------------------------------------------
include("LobbyTypes");		--MPLobbyTypes
include("ButtonUtilities");
include("InstanceManager");
include("PlayerSetupLogic");
include("PopupDialog");
include("Civ6Common");


-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local LOC_GAME_SETUP		:string = Locale.Lookup("LOC_MULTIPLAYER_GAME_SETUP");
local LOC_STAGING_ROOM		:string = Locale.ToUpper(Locale.Lookup("LOC_MULTIPLAYER_STAGING_ROOM"));
local RELOAD_CACHE_ID		:string = "HostGame";

local MIN_SCREEN_Y			:number = 768;
local SCREEN_OFFSET_Y		:number = 20;
local MIN_SCREEN_OFFSET_Y	:number = -93;
--local SCROLL_SIZE_DEFAULT	:number = 620;
--local SCROLL_SIZE_IN_SESSION:number = 662;

-- ===========================================================================
--	Globals
-- ===========================================================================
local m_lobbyModeName:string = MPLobbyTypes.STANDARD_INTERNET;
local m_shellTabIM:table = InstanceManager:new("ShellTab", "TopControl", Controls.ShellTabs);
local m_kPopupDialog:table;
local m_pCityStateWarningPopup:table = PopupDialog:new("CityStateWarningPopup");


function OnSetParameterValues(pid: string, values: table)
	local indexed_values = {};
	if(values) then
		for i,v in ipairs(values) do
			indexed_values[v] = true;
		end
	end

	if(g_GameParameters) then
		local parameter = g_GameParameters.Parameters and g_GameParameters.Parameters[pid] or nil;
		if(parameter and parameter.Values ~= nil) then
			local resolved_values = {};
			for i,v in ipairs(parameter.Values) do
				if(indexed_values[v.Value]) then
					table.insert(resolved_values, v);
				end
			end		
			g_GameParameters:SetParameterValue(parameter, resolved_values);
			Network.BroadcastGameConfig();	
		end
	end	
end

-- ===========================================================================
function OnSetParameterValue(pid: string, value: number)
	if(g_GameParameters) then
		local kParameter: table = g_GameParameters.Parameters and g_GameParameters.Parameters[pid] or nil;
		if(kParameter and kParameter.Value ~= nil) then	
            g_GameParameters:SetParameterValue(kParameter, value);
			Network.BroadcastGameConfig();	
		end
	end	
end

-- ===========================================================================
-- This driver is for launching a multi-select option in a separate window.
-- ===========================================================================
function CreateMultiSelectWindowDriver(o, parameter, parent)

	if(parent == nil) then
		parent = GetControlStack(parameter.GroupId);
	end
			
	-- Get the UI instance
	local c :object = g_ButtonParameterManager:GetInstance();	

	local parameterId = parameter.ParameterId;
	local button = c.Button;
	button:RegisterCallback( Mouse.eLClick, function()
		LuaEvents.MultiSelectWindow_Initialize(o.Parameters[parameterId]);
		Controls.MultiSelectWindow:SetHide(false);
	end);

	-- Store the root control, NOT the instance table.
	g_SortingMap[tostring(c.ButtonRoot)] = parameter;

	c.ButtonRoot:ChangeParent(parent);
	if c.StringName ~= nil then
		c.StringName:SetText(parameter.Name);
	end

	local cache = {};

	local kDriver :table = {
		Control = c,
		Cache = cache,
		UpdateValue = function(value, p)
			local valueText = value and value.Name or nil;
			local valueAmount :number = 0;
		
			if(valueText == nil) then
				if(value == nil) then
					if (parameter.UxHint ~= nil and parameter.UxHint == "InvertSelection") then
						valueText = "LOC_SELECTION_EVERYTHING";
					else
						valueText = "LOC_SELECTION_NOTHING";
					end
				elseif(type(value) == "table") then
					local count = #value;
					if (parameter.UxHint ~= nil and parameter.UxHint == "InvertSelection") then
						if(count == 0) then
							valueText = "LOC_SELECTION_EVERYTHING";
						elseif(count == #p.Values) then
							valueText = "LOC_SELECTION_NOTHING";
						else
							valueText = "LOC_SELECTION_CUSTOM";
							valueAmount = #p.Values - count;
						end
					else
						if(count == 0) then
							valueText = "LOC_SELECTION_NOTHING";
						elseif(count == #p.Values) then
							valueText = "LOC_SELECTION_EVERYTHING";
						else
							valueText = "LOC_SELECTION_CUSTOM";
							valueAmount = count;
						end
					end
				end
			end				

			c.Button:SetToolTipString(parameter.Description);

			if(cache.ValueText ~= valueText) or (cache.ValueAmount ~= valueAmount) then
				local button = c.Button;			
				button:LocalizeAndSetText(valueText, valueAmount);
				cache.ValueText = valueText;
				cache.ValueAmount = valueAmount;
			end
		end,
		UpdateValues = function(values, p) 
			-- Values are refreshed when the window is open.
		end,
		SetEnabled = function(enabled, p)
			c.Button:SetDisabled(not enabled or #p.Values <= 1);
		end,
		SetVisible = function(visible)
			c.ButtonRoot:SetHide(not visible);
		end,
		Destroy = function()
			g_ButtonParameterManager:ReleaseInstance(c);
		end,
	};	

	return kDriver;
end

-- ===========================================================================
-- This driver is for launching the city-state picker in a separate window.
-- ===========================================================================
function CreateCityStatePickerDriver(o, parameter, parent)

	if(parent == nil) then
		parent = GetControlStack(parameter.GroupId);
	end
			
	-- Get the UI instance
	local c :object = g_ButtonParameterManager:GetInstance();	

	local parameterId = parameter.ParameterId;
	local button = c.Button;
	button:RegisterCallback( Mouse.eLClick, function()
		LuaEvents.CityStatePicker_Initialize(o.Parameters[parameterId], g_GameParameters);
		Controls.CityStatePicker:SetHide(false);
	end);

	-- Store the root control, NOT the instance table.
	g_SortingMap[tostring(c.ButtonRoot)] = parameter;

	c.ButtonRoot:ChangeParent(parent);
	if c.StringName ~= nil then
		c.StringName:SetText(parameter.Name);
	end

	local cache = {};

	local kDriver :table = {
		Control = c,
		Cache = cache,
		UpdateValue = function(value, p)
			local valueText = value and value.Name or nil;
			local valueAmount :number = 0;
		
			if(valueText == nil) then
				if(value == nil) then
					if (parameter.UxHint ~= nil and parameter.UxHint == "InvertSelection") then
						valueText = "LOC_SELECTION_EVERYTHING";
					else
						valueText = "LOC_SELECTION_NOTHING";
					end
				elseif(type(value) == "table") then
					local count = #value;
					if (parameter.UxHint ~= nil and parameter.UxHint == "InvertSelection") then
						if(count == 0) then
							valueText = "LOC_SELECTION_EVERYTHING";
						elseif(count == #p.Values) then
							valueText = "LOC_SELECTION_NOTHING";
						else
							valueText = "LOC_SELECTION_CUSTOM";
							valueAmount = #p.Values - count;
						end
					else
						if(count == 0) then
							valueText = "LOC_SELECTION_NOTHING";
						elseif(count == #p.Values) then
							valueText = "LOC_SELECTION_EVERYTHING";
						else
							valueText = "LOC_SELECTION_CUSTOM";
							valueAmount = count;
						end
					end
				end
			end				

			c.Button:SetToolTipString(parameter.Description);

			if(cache.ValueText ~= valueText) or (cache.ValueAmount ~= valueAmount) then
				local button = c.Button;			
				button:LocalizeAndSetText(valueText, valueAmount);
				cache.ValueText = valueText;
				cache.ValueAmount = valueAmount;
			end
		end,
		UpdateValues = function(values, p) 
			-- Values are refreshed when the window is open.
		end,
		SetEnabled = function(enabled, p)
			c.Button:SetDisabled(not enabled or #p.Values <= 1);
		end,
		SetVisible = function(visible)
			c.ButtonRoot:SetHide(not visible);
		end,
		Destroy = function()
			g_ButtonParameterManager:ReleaseInstance(c);
		end,
	};	

	return kDriver;
end

-- ===========================================================================
-- This driver is for launching the leader picker in a separate window.
-- ===========================================================================
function CreateLeaderPickerDriver(o, parameter, parent)

	if(parent == nil) then
		parent = GetControlStack(parameter.GroupId);
	end
			
	-- Get the UI instance
	local c :object = g_ButtonParameterManager:GetInstance();	

	local parameterId:string = parameter.ParameterId;
	local button:table = c.Button;
	button:RegisterCallback( Mouse.eLClick, function()
		LuaEvents.LeaderPicker_Initialize(o.Parameters[parameterId], g_GameParameters);
		Controls.LeaderPicker:SetHide(false);
	end);
	button:SetToolTipString(parameter.Description);

	-- Store the root control, NOT the instance table.
	g_SortingMap[tostring(c.ButtonRoot)] = parameter;

	c.ButtonRoot:ChangeParent(parent);
	if c.StringName ~= nil then
		c.StringName:SetText(parameter.Name);
	end

	local cache:table = {};

	local kDriver :table = {
		Control = c,
		Cache = cache,
		UpdateValue = function(value, p)
			local valueText = value and value.Name or nil;
			local valueAmount :number = 0;

			-- Remove random leaders from the Values table that is used to determine number of leaders selected
			for i = #p.Values, 1, -1 do
				local kItem:table = p.Values[i];
				if kItem.Value == "RANDOM" or kItem.Value == "RANDOM_POOL1" or kItem.Value == "RANDOM_POOL2" then
					table.remove(p.Values, i);
				end
			end
		
			if(valueText == nil) then
				if(value == nil) then
					if (parameter.UxHint ~= nil and parameter.UxHint == "InvertSelection") then
						valueText = "LOC_SELECTION_EVERYTHING";
					else
						valueText = "LOC_SELECTION_NOTHING";
					end
				elseif(type(value) == "table") then
					local count = #value;
					if (parameter.UxHint ~= nil and parameter.UxHint == "InvertSelection") then
						if(count == 0) then
							valueText = "LOC_SELECTION_EVERYTHING";
						elseif(count == #p.Values) then
							valueText = "LOC_SELECTION_NOTHING";
						else
							valueText = "LOC_SELECTION_CUSTOM";
							valueAmount = #p.Values - count;
						end
					else
						if(count == 0) then
							valueText = "LOC_SELECTION_NOTHING";
						elseif(count == #p.Values) then
							valueText = "LOC_SELECTION_EVERYTHING";
						else
							valueText = "LOC_SELECTION_CUSTOM";
							valueAmount = count;
						end
					end
				end
			end				

			if(cache.ValueText ~= valueText) or (cache.ValueAmount ~= valueAmount) then
				local button:table = c.Button;			
				button:LocalizeAndSetText(valueText, valueAmount);
				cache.ValueText = valueText;
				cache.ValueAmount = valueAmount;
			end
		end,
		UpdateValues = function(values, p) 
			-- Values are refreshed when the window is open.
		end,
		SetEnabled = function(enabled, p)
			c.Button:SetDisabled(not enabled or #p.Values <= 1);
		end,
		SetVisible = function(visible)
			c.ButtonRoot:SetHide(not visible);
		end,
		Destroy = function()
			g_ButtonParameterManager:ReleaseInstance(c);
		end,
	};	

	return kDriver;
end

function GameParameters_UI_CreateParameterDriver(o, parameter, parent, ...)
	if(parameter.ParameterId == "CityStates") then
		return CreateCityStatePickerDriver(o, parameter);
	elseif(parameter.ParameterId == "LeaderPool1" or parameter.ParameterId == "LeaderPool2") then
		return CreateLeaderPickerDriver(o, parameter);
	elseif(parameter.Array) then
		return CreateMultiSelectWindowDriver(o, parameter);
	else
		return GameParameters_UI_DefaultCreateParameterDriver(o, parameter, parent, ...);
	end
end

-- The method used to create a UI control associated with the parameter.
-- Returns either a control or table that will be used in other parameter view related hooks.
function GameParameters_UI_CreateParameter(o, parameter)
	local func = g_ParameterFactories[parameter.ParameterId];

	local control;
	if(func)  then
		control = func(o, parameter);
	else
		control = GameParameters_UI_CreateParameterDriver(o, parameter);
	end

	o.Controls[parameter.ParameterId] = control;
end


-- ===========================================================================
-- Perform validation on setup parameters.
-- ===========================================================================
function UI_PostRefreshParameters()
	-- Most of the options self-heal due to the setup parameter logic.
	-- However, player options are allowed to be in an 'invalid' state for UI
	-- This way, instead of hiding/preventing the user from selecting an invalid player
	-- we can allow it, but display an error message explaining why it's invalid.

	-- This is ily used to present ownership errors and custom constraint errors.
	Controls.SaveConfigButton:SetDisabled(false);
	Controls.ConfirmButton:SetDisabled(false);
	Controls.ConfirmButton:SetToolTipString(nil);

	local game_err = GetGameParametersError();
	if(game_err) then
		Controls.SaveConfigButton:SetDisabled(true);
		Controls.ConfirmButton:SetDisabled(true);
		Controls.ConfirmButton:LocalizeAndSetToolTip("LOC_SETUP_PARAMETER_ERROR");

	end
end

-- ===========================================================================
--	Input Handler
-- ===========================================================================
function OnInputHandler( uiMsg, wParam, lParam )
	if uiMsg == KeyEvents.KeyUp then
		if wParam == Keys.VK_ESCAPE then
			LuaEvents.Multiplayer_ExitShell();
		end
	end
	return true;
end

-- ===========================================================================
function OnShow()
	
	RebuildPlayerParameters(true);
	GameSetup_RefreshParameters();
	


	-- Hide buttons if we're already in a game
	local isInSession:boolean = Network.IsInSession();
	Controls.ModsButton:SetHide(isInSession);
	Controls.ConfirmButton:SetHide(isInSession);
	
	ShowDefaultButton();
	ShowLoadConfigButton();
	Controls.LoadButton:SetHide(not GameConfiguration.IsHotseat() or isInSession);

	--[[
	local sizeY:number = isInSession and SCROLL_SIZE_IN_SESSION or SCROLL_SIZE_DEFAULT;
	Controls.DecoGrid:SetSizeY(sizeY);
	Controls.DecoBorder:SetSizeY(sizeY + 6);
	Controls.ParametersScrollPanel:SetSizeY(sizeY - 2);
	--]]

	RealizeShellTabs();
end

-- ===========================================================================
function ShowDefaultButton()
	local showDefaultButton = not GameConfiguration.IsSavedGame()
								and not Network.IsInSession();

	Controls.DefaultButton:SetHide(not showDefaultButton);
end

function ShowLoadConfigButton()
	local showLoadConfig = not GameConfiguration.IsSavedGame()
								and not Network.IsInSession();

	Controls.LoadConfigButton:SetHide(not showLoadConfig);
end

-- ===========================================================================
function OnHide( isHide, isInit )
	ReleasePlayerParameters();
	HideGameSetup();
end

-------------------------------------------------
-- Restore Default Settings Button Handler
-------------------------------------------------
function OnDefaultButton()
	print("Resetting Setup Parameters");

	-- Get the game name since we wish to persist this.
	local gameMode = GameModeTypeForMPLobbyType(m_lobbyModeName);
	local gameName = GameConfiguration.GetValue("GAME_NAME");
	GameConfiguration.SetToDefaults(gameMode);
	GameConfiguration.RegenerateSeeds();

	-- Kludge:  SetToDefaults assigns the ruleset to be standard.
	-- Clear this value so that the setup parameters code can guess the best 
	-- default.
	GameConfiguration.SetValue("RULESET", nil);
	
	-- Only assign GAME_NAME if the value is valid.
	if(gameName and #gameName > 0) then
		GameConfiguration.SetValue("GAME_NAME", gameName);
	end
	return GameSetup_RefreshParameters();
end

-------------------------------------------------------------------------------
-- Event Listeners
-------------------------------------------------------------------------------
Events.FinishedGameplayContentConfigure.Add(function(result)
	if(ContextPtr and not ContextPtr:IsHidden() and result.Success) then
		GameSetup_RefreshParameters();
	end
end);

-------------------------------------------------
-- Mods Setting Button Handler
-- TODO: Remove this, and place contents mods screen into the ParametersStack (in the SecondaryParametersStack, or in its own ModsStack)
-------------------------------------------------
function ModsButtonClick()
	UIManager:QueuePopup(Controls.ModsMenu, PopupPriority.Current);	
end


-- ===========================================================================
--	Host Game Button Handler
-- ===========================================================================
function OnConfirmClick()
	-- UINETTODO - Need to be able to support coming straight to this screen as a dedicated server
	--SERVER_TYPE_STEAM_DEDICATED,	// Steam Game Server, host does not play.

	local serverType = ServerTypeForMPLobbyType(m_lobbyModeName);
	print("OnConfirmClick() m_lobbyModeName: " .. tostring(m_lobbyModeName) .. " serverType: " .. tostring(serverType));
	
	-- GAME_NAME must not be empty.
	local gameName = GameConfiguration.GetValue("GAME_NAME");	
	if(gameName == nil or #gameName == 0) then
		GameConfiguration.SetToDefaultGameName();
	end
	
	if AreNoCityStatesInGame() or AreAllCityStateSlotsUsed() then
		HostGame(serverType);
	else
		m_pCityStateWarningPopup:ShowOkCancelDialog(Locale.Lookup("LOC_CITY_STATE_PICKER_TOO_FEW_WARNING"), function() HostGame(serverType); end);
	end
end

-- ===========================================================================
function HostGame(serverType:number)
	Events.SetGameEntryMethod("Host Multiplayer");
	Network.HostGame(serverType);
end

-- ===========================================================================
function AreNoCityStatesInGame()
	local kParameters:table = g_GameParameters["Parameters"];
	return (kParameters["CityStates"] == nil);
end

-- ===========================================================================
function AreAllCityStateSlotsUsed()
	
	local kParameters		:table = g_GameParameters["Parameters"];
	local cityStateSlots	:number = kParameters["CityStateCount"].Value;
	local totalCityStates	:number = #kParameters["CityStates"].AllValues;
	local excludedCityStates:number = kParameters["CityStates"].Value ~= nil and #kParameters["CityStates"].Value or 0;

	if (totalCityStates - excludedCityStates) < cityStateSlots then
		return false;
	end

	return true;
end

-------------------------------------------------
-- Load Configuration Button Handler
-------------------------------------------------
function OnLoadConfig()
	local serverType = ServerTypeForMPLobbyType(m_lobbyModeName);
	LuaEvents.HostGame_SetLoadGameServerType(serverType);
	local kParameters = {};
	kParameters.FileType = SaveFileTypes.GAME_CONFIGURATION;
	UIManager:QueuePopup(Controls.LoadGameMenu, PopupPriority.Current, kParameters);
end

-------------------------------------------------
-- Load Configuration Button Handler
-------------------------------------------------
function OnSaveConfig()
	local kParameters = {};
	kParameters.FileType = SaveFileTypes.GAME_CONFIGURATION;
	UIManager:QueuePopup(Controls.SaveGameMenu, PopupPriority.Current, kParameters);
end

function OnAbandoned(eReason)
	if (not ContextPtr:IsHidden()) then

		-- We need to CheckLeaveGame before triggering the reason popup because the reason popup hides the host game screen.
		-- and would block the leave game incorrectly.  This fixes TTP 22192.  See CheckLeaveGame() in stagingroom.lua.
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
		LuaEvents.Multiplayer_ExitShell();
	end
end

function CheckLeaveGame()
	-- Leave the network session if we're in a state where the host game should be triggering the exit.
	if not ContextPtr:IsHidden()	-- If the screen is not visible, this exit might be part of a general UI state change (like Multiplayer_ExitShell)
									-- and should not trigger a game exit.
		and Network.IsInSession()	-- Still in a network session.
		and not Network.IsInGameStartedState() then -- Don't trigger leave game if we're being used as an ingame screen. Worldview is handling this instead.
		print("HostGame::CheckLeaveGame() leaving the network session.");
		Network.LeaveGame();
	end
end

-- ===========================================================================
-- Event Handler: LeaveGameComplete
-- ===========================================================================
function OnLeaveGameComplete()
	-- We just left the game, we shouldn't be open anymore.
	UIManager:DequeuePopup( ContextPtr );
end

-- ===========================================================================
-- Event Handler: BeforeMultiplayerInviteProcessing
-- ===========================================================================
function OnBeforeMultiplayerInviteProcessing()
	-- We're about to process a game invite.  Get off the popup stack before we accidently break the invite!
	UIManager:DequeuePopup( ContextPtr );
end

-- ===========================================================================
-- Event Handler: ChangeMPLobbyMode
-- ===========================================================================
function OnChangeMPLobbyMode(newLobbyMode)
	m_lobbyModeName = newLobbyMode;
end

-- ===========================================================================
function RealizeShellTabs()
	m_shellTabIM:ResetInstances();

	local gameSetup:table = m_shellTabIM:GetInstance();
	gameSetup.Button:SetText(LOC_GAME_SETUP);
	gameSetup.SelectedButton:SetText(LOC_GAME_SETUP);
	gameSetup.Selected:SetHide(false);

	AutoSizeGridButton(gameSetup.Button,250,32,10,"H");
	AutoSizeGridButton(gameSetup.SelectedButton,250,32,20,"H");
	gameSetup.TopControl:SetSizeX(gameSetup.Button:GetSizeX());

	if Network.IsInSession() then
		local stagingRoom:table = m_shellTabIM:GetInstance();
		stagingRoom.Button:SetText(LOC_STAGING_ROOM);
		stagingRoom.SelectedButton:SetText(LOC_STAGING_ROOM);
		stagingRoom.Button:RegisterCallback( Mouse.eLClick, function() LuaEvents.HostGame_ShowStagingRoom() end );
		stagingRoom.Selected:SetHide(true);

		AutoSizeGridButton(stagingRoom.Button,250,32,20,"H");
		AutoSizeGridButton(stagingRoom.SelectedButton,250,32,20,"H");
		stagingRoom.TopControl:SetSizeX(stagingRoom.Button:GetSizeX());
	end

	Controls.ShellTabs:CalculateSize();
	Controls.ShellTabs:ReprocessAnchoring();
end

-------------------------------------------------
-- Leave the screen
-------------------------------------------------
function HandleExitRequest()
	-- Check to see if the screen needs to also leave the network session.
	CheckLeaveGame();

	UIManager:DequeuePopup( ContextPtr );
end

-- ===========================================================================
function OnRaiseHostGame()
	-- "Raise" means the host game screen is being shown for a fresh game.  Game configuration need to be defaulted.
	local gameMode = GameModeTypeForMPLobbyType(m_lobbyModeName);
	GameConfiguration.SetToDefaults(gameMode);

	-- Kludge:  SetToDefaults assigns the ruleset to be standard.
	-- Clear this value so that the setup parameters code can guess the best 
	-- default.
	GameConfiguration.SetValue("RULESET", nil);

	UIManager:QueuePopup( ContextPtr, PopupPriority.Current );
end

-- ===========================================================================
function OnEnsureHostGame()
	-- "Ensure" means the host game screen needs to be shown for a game in progress (don't default game configuration).
	if ContextPtr:IsHidden() then
		UIManager:QueuePopup( ContextPtr, PopupPriority.Current );
	end
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
	LuaEvents.MultiSelectWindow_SetParameterValues.Remove(OnSetParameterValues);
	LuaEvents.CityStatePicker_SetParameterValues.Remove(OnSetParameterValues);
	LuaEvents.CityStatePicker_SetParameterValue.Remove(OnSetParameterValue);
	LuaEvents.LeaderPicker_SetParameterValues.Remove(OnSetParameterValues);
end

-- ===========================================================================
function OnGameDebugReturn( context:string, contextTable:table )
	if context == RELOAD_CACHE_ID and contextTable["isHidden"] == false then
		UIManager:QueuePopup( ContextPtr, PopupPriority.Current );
	end	
end

-- ===========================================================================
-- Load Game Button Handler
-- ===========================================================================
function LoadButtonClick()
	local serverType = ServerTypeForMPLobbyType(m_lobbyModeName);
	LuaEvents.HostGame_SetLoadGameServerType(serverType);
	UIManager:QueuePopup(Controls.LoadGameMenu, PopupPriority.Current);	
end

-- ===========================================================================
function Resize()
	local screenX, screenY:number = UIManager:GetScreenSizeVal();
	if(screenY >= MIN_SCREEN_Y + (Controls.LogoContainer:GetSizeY()+ Controls.LogoContainer:GetOffsetY() * 2)) then
		Controls.MainWindow:SetSizeY(screenY-(Controls.LogoContainer:GetSizeY() + Controls.LogoContainer:GetOffsetY() * 2));
		Controls.DecoBorder:SetSizeY(SCREEN_OFFSET_Y + Controls.MainWindow:GetSizeY()-(Controls.BottomButtonStack:GetSizeY() + Controls.LogoContainer:GetSizeY()));
	else
		Controls.MainWindow:SetSizeY(screenY);
		Controls.DecoBorder:SetSizeY(MIN_SCREEN_OFFSET_Y + Controls.MainWindow:GetSizeY()-(Controls.BottomButtonStack:GetSizeY()));
	end
	Controls.MainGrid:ReprocessAnchoring();
end

-- ===========================================================================
function OnUpdateUI( type:number, tag:string, iData1:number, iData2:number, strData1:string )   
  if type == SystemUpdateUI.ScreenResize then
	Resize();
  end
end

-- ===========================================================================
function OnExitGame()
	LuaEvents.Multiplayer_ExitShell();
end

-- ===========================================================================
function OnExitGameAskAreYouSure()
	if Network.IsInSession() then
		if (not m_kPopupDialog:IsOpen()) then
			m_kPopupDialog:AddText(	  Locale.Lookup("LOC_GAME_MENU_QUIT_WARNING"));
			m_kPopupDialog:AddButton( Locale.Lookup("LOC_COMMON_DIALOG_NO_BUTTON_CAPTION"), nil );
			m_kPopupDialog:AddButton( Locale.Lookup("LOC_COMMON_DIALOG_YES_BUTTON_CAPTION"), OnExitGame, nil, nil, "PopupButtonInstanceRed" );
			m_kPopupDialog:Open();
		end
	else
		OnExitGame();
	end
end

-- ===========================================================================
function Initialize()
	
	Events.SystemUpdateUI.Add(OnUpdateUI);

	ContextPtr:SetInitHandler(OnInit);
	ContextPtr:SetShutdown(OnShutdown);
	ContextPtr:SetInputHandler(OnInputHandler);
	ContextPtr:SetShowHandler(OnShow);
	ContextPtr:SetHideHandler(OnHide);

	Controls.DefaultButton:RegisterCallback( Mouse.eLClick, OnDefaultButton);
	Controls.LoadConfigButton:RegisterCallback( Mouse.eLClick, OnLoadConfig);
	Controls.SaveConfigButton:RegisterCallback( Mouse.eLClick, OnSaveConfig);
	Controls.ConfirmButton:RegisterCallback( Mouse.eLClick, OnConfirmClick );
	Controls.ModsButton:RegisterCallback( Mouse.eLClick, ModsButtonClick );

	Events.MultiplayerGameAbandoned.Add( OnAbandoned );
	Events.LeaveGameComplete.Add( OnLeaveGameComplete );
	Events.BeforeMultiplayerInviteProcessing.Add( OnBeforeMultiplayerInviteProcessing );
	
	LuaEvents.ChangeMPLobbyMode.Add( OnChangeMPLobbyMode );
	LuaEvents.GameDebug_Return.Add(OnGameDebugReturn);
	LuaEvents.Lobby_RaiseHostGame.Add( OnRaiseHostGame );
	LuaEvents.MainMenu_RaiseHostGame.Add( OnRaiseHostGame );
	LuaEvents.Multiplayer_ExitShell.Add( HandleExitRequest );
	LuaEvents.StagingRoom_EnsureHostGame.Add( OnEnsureHostGame );
	LuaEvents.Mods_UpdateHostGameSettings.Add(GameSetup_RefreshParameters);		-- TODO: Remove when mods are managed by this screen

	LuaEvents.MultiSelectWindow_SetParameterValues.Add(OnSetParameterValues);
	LuaEvents.CityStatePicker_SetParameterValues.Add(OnSetParameterValues);
	LuaEvents.CityStatePicker_SetParameterValue.Add(OnSetParameterValue);
	LuaEvents.LeaderPicker_SetParameterValues.Add(OnSetParameterValues);

	Controls.BackButton:RegisterCallback( Mouse.eLClick, OnExitGameAskAreYouSure);
	Controls.LoadButton:RegisterCallback( Mouse.eLClick, LoadButtonClick );

	ResizeButtonToText( Controls.DefaultButton );
	ResizeButtonToText( Controls.BackButton );
	Resize();

	-- Custom popup setup	
	m_kPopupDialog = PopupDialog:new( "InGameTopOptionsMenu" );
end
--#Accessibility integration
include("caiUtils")

local mgr = ExposedMembers.CAI_UIManager

local CAI_PANEL_ID = "CAIHostGame_Panel"
local HOVER_SOUND = "Main_Menu_Mouse_Over"

local CAI_Panel = nil
local CAI_OptionsList = nil
local CAI_ActionRow = nil
local CAI_Sections = {}

local kSectionDefs = {
	{ key = "MapOptions", label = "LOC_MAP_OPTIONS" },
	{ key = "GameModes", label = "LOC_SETUP_GAME_MODES" },
	{ key = "Victories", label = "LOC_SETUP_VICTORY_CONDITIONS" },
	{ key = "AdvancedOptions", label = "LOC_ADVANCED_OPTIONS" },
}

local kGroupToSection = {
	BasicGameOptions = "MapOptions",
	GameOptions = "MapOptions",
	BasicMapOptions = "MapOptions",
	MapOptions = "MapOptions",
	GameModes = "GameModes",
	Victories = "Victories",
	AdvancedOptions = "AdvancedOptions",
}

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

local function CAI_Lookup(text, ...)
	if text == nil then return "" end
	return Locale.Lookup(text, ...)
end

local function CAI_SortParams(a, b)
	if (a.SortIndex or 0) ~= (b.SortIndex or 0) then
		return (a.SortIndex or 0) < (b.SortIndex or 0)
	end
	return Locale.Compare(a.Name or "", b.Name or "") == -1
end

local function CAI_GetParameter(paramId)
	return g_GameParameters and g_GameParameters.Parameters and g_GameParameters.Parameters[paramId]
end

local function CAI_GetParameterControl(paramId)
	return g_GameParameters and g_GameParameters.Controls and g_GameParameters.Controls[paramId]
end

local function CAI_GetControlRoot(control)
	local c = control and control.Control
	if not c then return nil end
	return c.CheckBox or c.StringRoot or c.Root or c.ButtonRoot or c.Button
end

local function CAI_IsControlHidden(control)
	local root = CAI_GetControlRoot(control)
	return root and root.IsHidden and root:IsHidden()
end

local function CAI_IsControlDisabled(control)
	local c = control and control.Control
	if not c then return false end
	local button = c.CheckBox or c.Button or c.PullDown or c.OptionSlider or c.StringRoot
	return button and button.IsDisabled and button:IsDisabled()
end

local function CAI_BroadcastConfig()
	if Network and Network.BroadcastGameConfig then
		Network.BroadcastGameConfig()
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

local function CAI_BuildDropdownOptions(paramId)
	local param = CAI_GetParameter(paramId)
	if not param or not param.Values then return {}, 0 end

	local options = {}
	local selectedIndex = 0
	for i, value in ipairs(param.Values) do
		table.insert(options, {
			label = value.Name or "",
			tooltip = value.Description or CAI_Lookup(value.RawDescription) or "",
			value = value,
		})
		if selectedIndex == 0 and CAI_ValueMatches(value, param.Value) then
			selectedIndex = i
		end
	end
	if selectedIndex == 0 and #options > 0 then selectedIndex = 1 end
	return options, selectedIndex
end

local function CAI_GetArraySummary(parameter)
	if not parameter then return "" end
	local value = parameter.Value
	local invert = parameter.UxHint == "InvertSelection"
	if type(value) == "table" then
		local count = #value
		local total = parameter.Values and #parameter.Values or 0
		if invert then
			if count == 0 then return CAI_Lookup("LOC_SELECTION_EVERYTHING") end
			if count == total then return CAI_Lookup("LOC_SELECTION_NOTHING") end
			return CAI_Lookup("LOC_SELECTION_CUSTOM", total - count)
		end
		if count == 0 then return CAI_Lookup("LOC_SELECTION_NOTHING") end
		if count == total then return CAI_Lookup("LOC_SELECTION_EVERYTHING") end
		return CAI_Lookup("LOC_SELECTION_CUSTOM", count)
	elseif value and value.Name then
		return value.Name
	end
	return invert and CAI_Lookup("LOC_SELECTION_EVERYTHING") or CAI_Lookup("LOC_SELECTION_NOTHING")
end

local function CAI_MakeActionButton(id, control)
	local button = mgr:CreateWidget(id, "Button", {
		Label = function() return CAI_ControlText(control) end,
		Tooltip = function() return CAI_ControlTooltip(control) end,
		HiddenPredicate = function() return control and control.IsHidden and control:IsHidden() end,
		DisabledPredicate = function() return control and control.IsDisabled and control:IsDisabled() end,
		FocusKey = id,
	})
	button:SetFocusSound(HOVER_SOUND)
	button:On("activate", function()
		if control then
			control:DoLeftClick()
		end
	end)
	return button
end

local function CAI_MakeParameterWidget(parameter)
	local paramId = parameter.ParameterId
	local control = CAI_GetParameterControl(paramId)
	local widget = nil

	if parameter.Array then
		widget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIHostParamButton"), "Button", {
			Label = function() return parameter.Name or "" end,
			Tooltip = function() return parameter.Description or "" end,
			ValueGetter = function() return CAI_GetArraySummary(CAI_GetParameter(paramId) or parameter) end,
			HiddenPredicate = function() return CAI_IsControlHidden(CAI_GetParameterControl(paramId)) end,
			DisabledPredicate = function() return CAI_IsControlDisabled(CAI_GetParameterControl(paramId)) end,
			FocusKey = "param:" .. tostring(paramId),
		})
		widget:On("activate", function()
			local liveControl = CAI_GetParameterControl(paramId)
			local liveButton = liveControl and liveControl.Control and liveControl.Control.Button
			if liveButton then
				liveButton:DoLeftClick()
				return
			end
			local liveParam = CAI_GetParameter(paramId)
			if not liveParam then return end
			if paramId == "CityStates" then
				LuaEvents.CityStatePicker_Initialize(liveParam, g_GameParameters)
				Controls.CityStatePicker:SetHide(false)
			elseif paramId == "LeaderPool1" or paramId == "LeaderPool2" then
				LuaEvents.LeaderPicker_Initialize(liveParam, g_GameParameters)
				Controls.LeaderPicker:SetHide(false)
			else
				LuaEvents.MultiSelectWindow_Initialize(liveParam)
				Controls.MultiSelectWindow:SetHide(false)
			end
		end)
	elseif parameter.GroupId == "GameModes" or parameter.Domain == "bool" then
		widget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIHostParamCheckbox"), "Checkbox", {
			Label = function() return parameter.Name or "" end,
			Tooltip = function() return parameter.Description or "" end,
			HiddenPredicate = function() return CAI_IsControlHidden(CAI_GetParameterControl(paramId)) end,
			DisabledPredicate = function() return CAI_IsControlDisabled(CAI_GetParameterControl(paramId)) end,
			FocusKey = "param:" .. tostring(paramId),
		})
		local liveControl = control and control.Control and control.Control.CheckBox
		local checked = parameter.Value
		if liveControl and liveControl.IsSelected then
			checked = liveControl:IsSelected()
		end
		widget:SetChecked(checked, true)
		widget:SetValueSetter(function(_, newValue)
			local live = CAI_GetParameterControl(paramId)
			local checkBox = live and live.Control and live.Control.CheckBox
			if checkBox and checkBox.IsSelected and checkBox:IsSelected() ~= newValue then
				checkBox:DoLeftClick()
				return
			end
			local liveParam = CAI_GetParameter(paramId)
			if liveParam then
				g_GameParameters:SetParameterValue(liveParam, newValue)
				CAI_BroadcastConfig()
			end
		end)
	elseif parameter.Values and parameter.Values.Type == "IntRange" then
		local minVal = parameter.Values.MinimumValue
		local maxVal = parameter.Values.MaximumValue
		widget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIHostParamSlider"), "Slider", {
			Label = function() return parameter.Name or "" end,
			Tooltip = function() return parameter.Description or "" end,
			ValueGetter = function()
				local p = CAI_GetParameter(paramId)
				return p and tostring(p.Value) or ""
			end,
			HiddenPredicate = function() return CAI_IsControlHidden(CAI_GetParameterControl(paramId)) end,
			DisabledPredicate = function() return CAI_IsControlDisabled(CAI_GetParameterControl(paramId)) end,
			FocusKey = "param:" .. tostring(paramId),
		})
		widget:SetMin(minVal)
		widget:SetMax(maxVal)
		widget:SetValue(parameter.Value or minVal, true)
		widget:SetValueSetter(function(_, newValue)
			local liveParam = CAI_GetParameter(paramId)
			if liveParam and liveParam.Value ~= newValue then
				g_GameParameters:SetParameterValue(liveParam, newValue)
				CAI_BroadcastConfig()
			end
		end)
	elseif parameter.Values then
		widget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIHostParamDropdown"), "Dropdown", {
			Label = function() return parameter.Name or "" end,
			Tooltip = function()
				local p = CAI_GetParameter(paramId)
				if p and p.Value and p.Value.Description then return p.Value.Description end
				if p and p.Value and p.Value.RawDescription then return CAI_Lookup(p.Value.RawDescription) end
				return parameter.Description or ""
			end,
			HiddenPredicate = function() return CAI_IsControlHidden(CAI_GetParameterControl(paramId)) end,
			DisabledPredicate = function() return CAI_IsControlDisabled(CAI_GetParameterControl(paramId)) end,
			FocusKey = "param:" .. tostring(paramId),
		})
		local options, selectedIndex = CAI_BuildDropdownOptions(paramId)
		widget:SetOptions(options)
		if selectedIndex > 0 then widget:SetSelectedIndex(selectedIndex, true) end
		widget:SetValueSetter(function(_, value)
			local liveParam = CAI_GetParameter(paramId)
			if liveParam then
				g_GameParameters:SetParameterValue(liveParam, value)
				CAI_BroadcastConfig()
			end
		end)
	elseif parameter.Domain == "int" or parameter.Domain == "uint" or parameter.Domain == "text" then
		local domain = parameter.Domain
		widget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIHostParamEdit"), "EditBox", {
			Label = function() return parameter.Name or "" end,
			Tooltip = function() return parameter.Description or "" end,
			HiddenPredicate = function() return CAI_IsControlHidden(CAI_GetParameterControl(paramId)) end,
			DisabledPredicate = function() return CAI_IsControlDisabled(CAI_GetParameterControl(paramId)) end,
			FocusKey = "param:" .. tostring(paramId),
			HighlightOnEdit = true,
		})
		local liveEdit = control and control.Control and control.Control.StringEdit
		local initial = liveEdit and liveEdit.GetText and liveEdit:GetText() or tostring(parameter.Value or "")
		if domain == "int" or domain == "uint" then
			widget:SetEditMode(2)
			widget:SetMaxCharacters(16)
		else
			widget:SetMaxCharacters(64)
		end
		widget:SetText(initial, true)
		widget:SetValueSetter(function(_, text)
			local liveControl = CAI_GetParameterControl(paramId)
			local edit = liveControl and liveControl.Control and liveControl.Control.StringEdit
			if edit and edit.SetText then edit:SetText(text) end
			local value = text
			if domain == "int" then
				value = tonumber(text) or 0
			elseif domain == "uint" then
				value = math.max(tonumber(text) or 0, 0)
			end
			local liveParam = CAI_GetParameter(paramId)
			if liveParam then
				g_GameParameters:SetParameterValue(liveParam, value)
				CAI_BroadcastConfig()
			end
		end)
	end

	if widget then
		widget:SetFocusSound(HOVER_SOUND)
	end
	return widget
end

local function CAI_RebuildOptions()
	if not CAI_OptionsList then return end
	local capture = mgr:CaptureFocusKey(CAI_OptionsList)

	for _, section in pairs(CAI_Sections) do
		section:ClearChildren()
	end

	local params = {}
	if g_GameParameters and g_GameParameters.Parameters then
		for _, parameter in pairs(g_GameParameters.Parameters) do
			table.insert(params, parameter)
		end
	end
	table.sort(params, CAI_SortParams)

	for _, parameter in ipairs(params) do
		local sectionKey = kGroupToSection[parameter.GroupId]
		local section = sectionKey and CAI_Sections[sectionKey]
		if section and parameter.Visible ~= false then
			local widget = CAI_MakeParameterWidget(parameter)
			if widget then
				section:AddChild(widget)
			end
		end
	end

	mgr:RestoreFocus(CAI_OptionsList, capture)
end

local function CAI_BuildPanel()
	CAI_Panel = mgr:CreateWidget(CAI_PANEL_ID, "Panel", {
		Label = function() return CAI_ControlText(Controls.TitleLabel) end,
	})

	CAI_OptionsList = mgr:CreateWidget("CAIHostGame_Options", "List", {
		Label = function() return CAI_ControlText(Controls.TitleLabel) end,
	})
	CAI_Panel:AddChild(CAI_OptionsList)

	CAI_Sections = {}
	for _, def in ipairs(kSectionDefs) do
		local section = mgr:CreateWidget("CAIHostGame_" .. def.key, "SubMenu", {
			Label = function() return CAI_Lookup(def.label) end,
			FocusKey = "section:" .. def.key,
		})
		section:SetFocusSound(HOVER_SOUND)
		CAI_Sections[def.key] = section
		CAI_OptionsList:AddChild(section)
	end

	CAI_Panel:AddChild(CAI_MakeActionButton("CAIHostGame_LoadGame", Controls.LoadButton))
	CAI_Panel:AddChild(CAI_MakeActionButton("CAIHostGame_LoadConfig", Controls.LoadConfigButton))
	CAI_Panel:AddChild(CAI_MakeActionButton("CAIHostGame_SaveConfig", Controls.SaveConfigButton))
	CAI_Panel:AddChild(CAI_MakeActionButton("CAIHostGame_Defaults", Controls.DefaultButton))
	CAI_Panel:AddChild(CAI_MakeActionButton("CAIHostGame_Confirm", Controls.ConfirmButton))

	local stagingButton = mgr:CreateWidget("CAIHostGame_StagingRoom", "Button", {
		Label = function() return LOC_STAGING_ROOM end,
		HiddenPredicate = function() return not Network.IsInSession() end,
		FocusKey = "action:staging",
	})
	stagingButton:SetFocusSound(HOVER_SOUND)
	stagingButton:On("activate", function() LuaEvents.HostGame_ShowStagingRoom() end)
	CAI_Panel:AddChild(stagingButton)

	CAI_Panel:AddChild(CAI_MakeActionButton("CAIHostGame_Mods", Controls.ModsButton))

	CAI_RebuildOptions()
end

local function CAI_PushPanel(ignoreFocus)
	if mgr == nil then return end
	if CAI_Panel == nil then
		CAI_BuildPanel()
	end
	if CAI_Panel and mgr:GetWidgetById(CAI_PANEL_ID) ~= CAI_Panel then
		mgr:Push(CAI_Panel, { priority = PopupPriority.Current, ignoreFocus = ignoreFocus})
	end
end

local function CAI_PopPanel()
	if mgr and mgr:GetWidgetById(CAI_PANEL_ID) then
		mgr:RemoveFromStack(CAI_PANEL_ID)
	end
	CAI_Panel = nil
	CAI_OptionsList = nil
	CAI_ActionRow = nil
	CAI_Sections = {}
end

OnRaiseHostGame = WrapFunc(OnRaiseHostGame, function(orig, ...)
	orig(...)
	CAI_PushPanel()
end)

OnEnsureHostGame = WrapFunc(OnEnsureHostGame, function(orig, ...)
	orig(...)
	CAI_PushPanel(true)
end)

OnShutdown = WrapFunc(OnShutdown, function(orig, ...)
	CAI_PopPanel()
	orig(...)
end)

GameSetup_RefreshParameters = WrapFunc(GameSetup_RefreshParameters, function(orig, ...)
	local result = orig(...)
	if CAI_Panel then
		CAI_RebuildOptions()
	end
	return result
end)

OnSetParameterValues = WrapFunc(OnSetParameterValues, function(orig, ...)
	local result = orig(...)
	if CAI_Panel then
		CAI_RebuildOptions()
	end
	return result
end)

OnSetParameterValue = WrapFunc(OnSetParameterValue, function(orig, ...)
	local result = orig(...)
	if CAI_Panel then
		CAI_RebuildOptions()
	end
	return result
end)

HandleExitRequest = WrapFunc(HandleExitRequest, function(orig, ...)
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

Initialize = WrapFunc(Initialize, function(orig)
	orig()
	ContextPtr:SetInputHandler(function(input)
		if mgr and not ContextPtr:IsHidden() and mgr:HandleInput(input) then
			return true
		end
		if input:GetMessageType() == KeyEvents.KeyUp and input:GetKey() == Keys.VK_ESCAPE then
			LuaEvents.Multiplayer_ExitShell()
			return true
		end
		return true
	end, true)
end)
--#End of accessibility integration
Initialize();
