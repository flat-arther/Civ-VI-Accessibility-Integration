---------------------------------------------------------------- 
-- Globals
----------------------------------------------------------------  
local PADDING:number = 60;
local MIN_SIZE_X:number = 250;
local MIN_SIZE_Y:number = 200;
local g_waitingForJoinGameComplete : boolean = true;
local g_waitingForContentConfigure : boolean = true;

local downloadPendingStr = Locale.Lookup("LOC_MODS_SUBSCRIPTION_DOWNLOAD_PENDING");

----------------------------------------------------------------        
-- Input Handler
----------------------------------------------------------------        
function OnInputHandler( uiMsg, wParam, lParam )
	if uiMsg == KeyEvents.KeyUp then
		if wParam == Keys.VK_ESCAPE then
			HandleExitRequest();
		end
	end
	return true;
end

-------------------------------------------------
-- Leave the game we're trying to join.
-------------------------------------------------
function HandleExitRequest()
	print("JoiningRoom::HandleExitRequest() leaving the network session.");
	Network.LeaveGame();
	UIManager:DequeuePopup( ContextPtr );
end


-------------------------------------------------
-- Trigger transition to the staging room.
-------------------------------------------------
function DoTransitionToStagingRoom()
	-- Staging room must be notified before this is dequeued
	-- or the screen below will be shown (for a frame) and
	-- that lobby screen will attempt to disconnect.
	LuaEvents.JoiningRoom_ShowStagingRoom();	
	UIManager:DequeuePopup( ContextPtr );	
end


-------------------------------------------------
-- Event Handler: MultiplayerJoinRoomComplete
-------------------------------------------------
function OnJoinRoomComplete()
	if (not ContextPtr:IsHidden()) then
		if(not Network.IsNetSessionHost()) then
			Controls.JoiningLabel:SetText(Locale.ToUpper(Locale.Lookup("LOC_MULTIPLAYER_JOINING_HOST")));
		end
	end
end

-------------------------------------------------
-- Event Handler: MultiplayerJoinRoomFailed
-------------------------------------------------
function OnJoinRoomFailed( iExtendedError)
	if (not ContextPtr:IsHidden()) then
		if(Network.IsMatchMaking()) then
			-- If we abandon the game while matchmaking, we should remain on the matchmaking screen while the network session finds another game.		
			print("Ignoring JoinRoomFailed because we are matchmaking.");
		else
			if iExtendedError == JoinGameErrorType.JOINGAME_ROOM_FULL then
				LuaEvents.MultiplayerPopup( "LOC_MP_ROOM_FULL", "LOC_MP_ROOM_FULL_TITLE" );
			elseif iExtendedError == JoinGameErrorType.JOINGAME_GAME_STARTED then
				LuaEvents.MultiplayerPopup( "LOC_MP_ROOM_GAME_STARTED", "LOC_MP_ROOM_GAME_STARTED_TITLE" );
			elseif iExtendedError == JoinGameErrorType.JOINGAME_TOO_MANY_MATCHES then
				LuaEvents.MultiplayerPopup( "LOC_MP_ROOM_TOO_MANY_MATCHES", "LOC_MP_ROOM_TOO_MANY_MATCHES_TITLE" );
			else
				LuaEvents.MultiplayerPopup( "LOC_MP_JOIN_FAILED", "LOC_MP_JOIN_FAILED_TITLE" );
			end
			print("JoiningRoom::OnJoinRoomFailed() leaving the network session.");
			Network.LeaveGame();
			UIManager:DequeuePopup( ContextPtr );
		end
	end
end

-------------------------------------------------
-- Event Handler: MultiplayerJoinGameComplete
-------------------------------------------------
function OnJoinGameComplete()
	print("OnJoinGameComplete()");
	-- This event triggers when the game has finished joining the multiplayer.  
	if (not ContextPtr:IsHidden()) then
		g_waitingForJoinGameComplete = false;
		CheckTransitionToStagingRoom();

		-- Remote clients might still be waiting for FinishedGameplayContentConfigure.  
		-- It is possible that FinishedGameplayContentConfigure happened before JoinGameComplete.
		-- Updating the joining phase for that case.
		Controls.JoiningLabel:SetText(Locale.ToUpper(Locale.Lookup("LOC_MULTIPLAYER_CONFIGURING_CONTENT")));
	end
end

-- Transition to staging room if the conditions are right.
function CheckTransitionToStagingRoom()
	print("CheckTransitionToStagingRoom()");

	-- Waiting for JoinGameComplete
	if(g_waitingForJoinGameComplete) then
		return;
	end

	-- Remote clients need to wait for FinishedGameplayContentConfigure
	if(not Network.IsNetSessionHost() and g_waitingForContentConfigure) then
		return;
	end

	DoTransitionToStagingRoom();
end

function OnMultiplayerMatchmakingFailed()
	if (not ContextPtr:IsHidden()) then
		-- Just show the generic error message for now.  We do not have new text for a dedicated error message yet.
		LuaEvents.MultiplayerPopup( "LOC_MP_JOIN_FAILED", "LOC_MP_JOIN_FAILED_TITLE" );
		print("JoiningRoom::OnMultiplayerMatchmakingFailed() leaving the network session.");
		Network.LeaveGame();
		UIManager:DequeuePopup( ContextPtr );
	end
end

-------------------------------------------------
-- Event Handler: FinishedGameplayContentConfigure
-------------------------------------------------
function OnFinishedGameplayContentConfigure( kEvent )
	print("OnFinishedGameplayContentConfigure() g_waitingForContentConfigure=" .. tostring(g_waitingForContentConfigure));
	-- This event triggers when the game has finished content configuration.
	-- For remote clients, this might be the last prereq before transitioning to the staging room.
	-- Game hosts don't perform a content configuration so they will definitely transition in OnJoinGameComplete.

	-- If FinishedGameplayContentConfigure failed, we do nothing and the NetworkManager will abandon the game for us.
	if (not ContextPtr:IsHidden() 
		and kEvent.Success == true) then
		g_waitingForContentConfigure = false;
		CheckTransitionToStagingRoom();
	end 
end

-------------------------------------------------
-- Event Handler: MultiplayerGameAbandoned
-------------------------------------------------
function OnMultiplayerGameAbandoned(eReason)
	if (not ContextPtr:IsHidden()) then
		if(Network.IsMatchMaking()) then
			-- If we abandon the game while matchmaking, we should remain on the matchmaking screen while the network session finds another game.		
			print("Ignoring JoinRoomFailed because we are matchmaking.");
		else
			if (eReason == KickReason.KICK_HOST) then
				LuaEvents.MultiplayerPopup( "LOC_GAME_ABANDONED_KICKED", "LOC_GAME_ABANDONED_KICKED_TITLE" );
			elseif (eReason == KickReason.KICK_NO_HOST) then
				-- This can happen if the host refuses the client's connection.
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
				LuaEvents.MultiplayerPopup( "LOC_GAME_ABANDONED_JOIN_FAILED", "LOC_GAME_ABANDONED_JOIN_FAILED_TITLE" );
			end

			print("JoiningRoom::OnMultiplayerGameAbandoned() leaving the network session.");
			Network.LeaveGame();
			UIManager:DequeuePopup( ContextPtr );	
		end
	end
end

-- ===========================================================================
-- Event Handler: BeforeMultiplayerInviteProcessing
-- ===========================================================================
function OnBeforeMultiplayerInviteProcessing()
	-- We're about to process a game invite.  Get off the popup stack before we accidently break the invite!
	UIManager:DequeuePopup( ContextPtr );
end

-- ===========================================================================
-- Event Handler: ModStatusUpdated
-- ===========================================================================
function OnModStatusUpdated(playerID: number, modState : number, bytesDownloaded : number, bytesTotal : number,
							modsRemaining : number, modsRequired : number)
	-- If we're getting a mod status update for ourself, use it to update the joining label.
	if (not ContextPtr:IsHidden() and playerID == Network.GetLocalPlayerID()) then	
		if(modState == 1) then -- MOD_STATE_DOWNLOADING
			local modStatusString = downloadPendingStr;
			modStatusString = modStatusString .. "[NEWLINE][Icon_AdditionalContent]" .. tostring(modsRemaining) .. "/" .. tostring(modsRequired);
			Controls.JoiningLabel:SetText(modStatusString);
		end
	end
end

-------------------------------------------------
-- Event Handler: ConnectedToNetSessionHost
-------------------------------------------------
function OnConnectedToNetSessionHost()
	if (not ContextPtr:IsHidden()) then
		Controls.JoiningLabel:SetText(Locale.ToUpper(Locale.Lookup("LOC_MULTIPLAYER_CONNECTING_TO_PLAYERS")));
	end
end

-- APPNETTODO - Implement these events for better join game status reporting
--[[
-------------------------------------------------
-- Event Handler: MultiplayerConnectionFailed
-------------------------------------------------
function OnMultiplayerConnectionFailed()
	if (not ContextPtr:IsHidden()) then
		-- We should only get this if we couldn't complete the connection to the host of the room	
		LuaEvents.MultiplayerPopup( "LOC_MP_JOIN_FAILED" );
		print("JoiningRoom::OnMultiplayerConnectionFailed() leaving the network session.");
		Network.LeaveGame();
		UIManager:DequeuePopup( ContextPtr );
	end
end
Events.MultiplayerConnectionFailed.Add( OnMultiplayerConnectionFailed );

-------------------------------------------------
-- Event Handler: MultiplayerNetRegistered
-------------------------------------------------
function OnNetRegistered()
	if (not ContextPtr:IsHidden()) then
		Controls.JoiningLabel:SetText( Locale.ConvertTextKey("LOC_MULTIPLAYER_JOINING_GAMESTATE" ));    
	end
end
Events.MultiplayerNetRegistered.Add( OnNetRegistered );  

-------------------------------------------------
-- Event Handler: PlayerVersionMismatchEvent
-------------------------------------------------
function OnVersionMismatch( iPlayerID, playerName, bIsHost )
	if (not ContextPtr:IsHidden()) then
    if( bIsHost ) then
        LuaEvents.MultiplayerPopup( Locale.ConvertTextKey( "LOC_MP_VERSION_MISMATCH_FOR_HOST", playerName ) );
    	Matchmaking.KickPlayer( iPlayerID );
    else
        LuaEvents.MultiplayerPopup( Locale.ConvertTextKey( "LOC_MP_VERSION_MISMATCH_FOR_PLAYER" ) );
        HandleExitRequest();
    end
	end
end
Events.PlayerVersionMismatchEvent.Add( OnVersionMismatch );
--]]


-- ===========================================================================
--	UI Event
--	Screen is now shown....
-- ===========================================================================
function OnShow()
	-- APPNETTODO - implement DLC handling.
	--[[
	-- Activate only the DLC allowed for this MP game.  Mods will also deactivated/activate too.
	if (not ContextPtr:IsHotLoad()) then 
		local prevCursor = UIManager:SetUICursor( 1 );
		local bChanged = Modding.ActivateAllowedDLC();
		UIManager:SetUICursor( prevCursor );
				
		-- Send out an event to continue on, as the ActivateDLC may have swapped out the UI	
		Events.SystemUpdateUI( SystemUpdateUI.RestoreUI, "JoiningRoom" );
	end
	--]]

	-- In the specific case of a user joinging a game from an invite, while they are
	-- in the the tutorial; be sure the tutorial guards are all off.
	UITutorialManager:SetActiveAlways( false );
	UITutorialManager:EnableOverlay( false );
	UITutorialManager:HideAll();
	UITutorialManager:ClearPersistantInputControls();	

	-- Reset wait flags
	g_waitingForJoinGameComplete = true;
	g_waitingForContentConfigure = true;
	
	if(Network.IsMatchMaking()) then
		Controls.JoiningLabel:SetText(Locale.ToUpper(Locale.Lookup("LOC_MULTIPLAYER_MATCHMAKING")));
	else
		Controls.JoiningLabel:SetText(Locale.ToUpper(Locale.Lookup("LOC_MULTIPLAYER_JOINING_ROOM")));
	end
	
	LuaEvents.JoiningRoom_Showing();
end


-------------------------------------------------
function AdjustScreenSize()
	local screenX, screenY:number = UIManager:GetScreenSizeVal();
	local hideLogo = true;
	if(screenY >= Controls.MainWindow:GetSizeY() + Controls.LogoContainer:GetSizeY()+ Controls.LogoContainer:GetOffsetY()) then
		hideLogo = false;
	end
	Controls.LogoContainer:SetHide(hideLogo);
	Controls.MainGrid:ReprocessAnchoring();
end

-------------------------------------------------
function OnUpdateUI( type, tag, iData1, iData2, strData1)
	if( type == SystemUpdateUI.ScreenResize ) then
		AdjustScreenSize();
	-- APPNETTODO - Need RestoreUI system for game invites.
	--[[
	elseif (type == SystemUpdateUI.RestoreUI and tag == "JoiningRoom") then
		if (ContextPtr:IsHidden()) then
			UIManager:QueuePopup(ContextPtr, PopupPriority.JoiningScreen );    
		end
	--]]
	end
end


-- ===========================================================================
--	Initialize screen
-- ===========================================================================
function Initialize()

	ContextPtr:SetShowHandler( OnShow );
	ContextPtr:SetInputHandler( OnInputHandler );

	Events.MultiplayerJoinRoomComplete.Add( OnJoinRoomComplete );
	Events.MultiplayerJoinRoomFailed.Add( OnJoinRoomFailed );
	Events.MultiplayerJoinGameComplete.Add( OnJoinGameComplete);
	Events.MultiplayerMatchmakingFailed.Add( OnMultiplayerMatchmakingFailed);
	Events.FinishedGameplayContentConfigure.Add(OnFinishedGameplayContentConfigure);
	Events.MultiplayerGameAbandoned.Add( OnMultiplayerGameAbandoned );
	Events.SystemUpdateUI.Add( OnUpdateUI );
	Events.BeforeMultiplayerInviteProcessing.Add( OnBeforeMultiplayerInviteProcessing );
	Events.ModStatusUpdated.Add( OnModStatusUpdated );
	Events.ConnectedToNetSessionHost.Add ( OnConnectedToNetSessionHost );

	Controls.CancelButton:RegisterCallback(Mouse.eLClick, HandleExitRequest);
	AdjustScreenSize();
end
--#Accessibility integration
include("caiUtils")

local mgr = ExposedMembers.CAI_UIManager
local caiId = "9f4b5c2e-1a2b-4c3d-8e9f-123456789abc"

local m_CAI_Dialog = nil
local m_CAI_StatusText = nil
local m_CAI_LastStatusText = nil
local m_CAI_RecoveryPending = false
local m_CAI_WaitingForRecoveryConfigure = false
local m_CAI_PendingFailurePopup = nil

local function CAI_RecoverAccessibilityMod(phase)
	local caiHandle = Modding.GetModHandle(caiId)
	if caiHandle == nil then
		print("CAI JoiningRoom recovery failed: accessibility mod handle is unavailable.")
		return
	end

	-- Joining a remote configuration can disable CAI before the engine reports
	-- why the join failed. Restore it after leaving that failed configuration;
	-- the failure popup remains deferred until content configuration completes.
	local wasEnabled = Modding.IsModEnabled(caiId)
	Modding.EnableMod(caiHandle, true)
	local isEnabled = Modding.IsModEnabled(caiId)
	print("CAI JoiningRoom recovery phase=" .. tostring(phase)
		.. ", wasEnabled=" .. tostring(wasEnabled)
		.. ", isEnabled=" .. tostring(isEnabled))
end

local function CAI_OnLeaveGameComplete()
	if not m_CAI_RecoveryPending then return end
	m_CAI_RecoveryPending = false

	-- Network.LeaveGame rolls the failed remote content configuration back after
	-- the failure event. Reapply CAI only after that rollback, then synchronize
	-- the current game configuration with the enabled mod set. UpdateEnabledMods
	-- completes asynchronously through FinishedGameplayContentConfigure.
	CAI_RecoverAccessibilityMod("after_leave_complete")
	m_CAI_WaitingForRecoveryConfigure = true
	GameConfiguration.UpdateEnabledMods()
	print("CAI JoiningRoom recovery synchronized game configuration, isEnabled="
		.. tostring(Modding.IsModEnabled(caiId)))
end

local function CAI_ShowPendingFailurePopup()
	local popup = m_CAI_PendingFailurePopup
	m_CAI_PendingFailurePopup = nil
	m_CAI_WaitingForRecoveryConfigure = false
	if popup == nil then return end

	print("CAI JoiningRoom recovery complete: raising deferred failure popup.")
	LuaEvents.MultiplayerPopup(popup.Text, popup.Title)
end

local function CAI_GetJoinRoomFailurePopup(iExtendedError)
	if iExtendedError == JoinGameErrorType.JOINGAME_ROOM_FULL then
		return "LOC_MP_ROOM_FULL", "LOC_MP_ROOM_FULL_TITLE"
	elseif iExtendedError == JoinGameErrorType.JOINGAME_GAME_STARTED then
		return "LOC_MP_ROOM_GAME_STARTED", "LOC_MP_ROOM_GAME_STARTED_TITLE"
	elseif iExtendedError == JoinGameErrorType.JOINGAME_TOO_MANY_MATCHES then
		return "LOC_MP_ROOM_TOO_MANY_MATCHES", "LOC_MP_ROOM_TOO_MANY_MATCHES_TITLE"
	end
	return "LOC_MP_JOIN_FAILED", "LOC_MP_JOIN_FAILED_TITLE"
end

local function CAI_GetAbandonedFailurePopup(eReason)
	if eReason == KickReason.KICK_HOST then
		return "LOC_GAME_ABANDONED_KICKED", "LOC_GAME_ABANDONED_KICKED_TITLE"
	elseif eReason == KickReason.KICK_NO_HOST then
		return "LOC_GAME_ABANDONED_HOST_LOSTED", "LOC_GAME_ABANDONED_HOST_LOSTED_TITLE"
	elseif eReason == KickReason.KICK_NO_ROOM then
		return "LOC_GAME_ABANDONED_ROOM_FULL", "LOC_GAME_ABANDONED_ROOM_FULL_TITLE"
	elseif eReason == KickReason.KICK_VERSION_MISMATCH then
		return "LOC_GAME_ABANDONED_VERSION_MISMATCH", "LOC_GAME_ABANDONED_VERSION_MISMATCH_TITLE"
	elseif eReason == KickReason.KICK_MOD_ERROR then
		return "LOC_GAME_ABANDONED_MOD_ERROR", "LOC_GAME_ABANDONED_MOD_ERROR_TITLE"
	elseif eReason == KickReason.KICK_MOD_MISSING then
		return Modding.GetLastModErrorString(), "LOC_GAME_ABANDONED_MOD_MISSING_TITLE"
	elseif eReason == KickReason.KICK_MATCH_DELETED then
		return "LOC_GAME_ABANDONED_MATCH_DELETED", "LOC_GAME_ABANDONED_MATCH_DELETED_TITLE"
	end
	return "LOC_GAME_ABANDONED_JOIN_FAILED", "LOC_GAME_ABANDONED_JOIN_FAILED_TITLE"
end

local function CAI_GetControlText(control)
	if control and control.GetText then
		return control:GetText() or ""
	end
	return ""
end

local function CAI_BuildDialog()
	m_CAI_StatusText = mgr:CreateWidget(mgr:GenerateWidgetId("CAIJoiningRoomStatus"), "StaticText", {
		Label = function() return CAI_GetControlText(Controls.JoiningLabel) end,
		FocusKey = "status",
	})

	local cancelButton = mgr:CreateWidget(mgr:GenerateWidgetId("CAIJoiningRoomCancel"), "Button", {
		Label = function() return CAI_GetControlText(Controls.CancelButton) end,
		FocusKey = "cancel",
	})
	cancelButton:On("activate", function()
		if Controls.CancelButton and Controls.CancelButton.DoLeftClick then
			Controls.CancelButton:DoLeftClick()
		else
			HandleExitRequest()
		end
	end)

	m_CAI_Dialog = mgr.WidgetHelpers.MakeGeneralDialog(
		function() return CAI_GetControlText(Controls.TitleLabel) end,
		{ cancelButton },
		{ m_CAI_StatusText },
		1
	)
end

local function CAI_PopDialog()
	if m_CAI_Dialog then
		mgr:RemoveFromStack(m_CAI_Dialog:GetId())
	end
	m_CAI_Dialog = nil
	m_CAI_StatusText = nil
	m_CAI_LastStatusText = nil
end

local function CAI_DeferFailurePopup(popupText, popupTitle)
	m_CAI_RecoveryPending = true
	m_CAI_PendingFailurePopup = {
		Text = popupText,
		Title = popupTitle,
	}

	-- Do not raise MultiplayerPopup yet. The failed remote configuration still
	-- owns the active settings database, so FrontEndPopup would be pushed before
	-- CAI's speech settings (including SpeakRole) exist again.
	CAI_PopDialog()
	UIManager:DequeuePopup(ContextPtr)
	Network.LeaveGame()
end

local function CAI_PushDialog()
	CAI_PopDialog()
	CAI_BuildDialog()
	if not m_CAI_Dialog then return end
	mgr:Push(m_CAI_Dialog, { priority = PopupPriority.JoiningScreen})
	m_CAI_LastStatusText = CAI_GetControlText(Controls.JoiningLabel)
end

local function CAI_SpeakStatusIfChanged()
	if ContextPtr:IsHidden() then return end
	if not m_CAI_Dialog or not m_CAI_StatusText then return end
	if not mgr:GetWidgetById(m_CAI_Dialog:GetId()) then return end
	local statusText = CAI_GetControlText(Controls.JoiningLabel)
	if statusText ~= "" and statusText ~= m_CAI_LastStatusText then
		m_CAI_LastStatusText = statusText
		m_CAI_StatusText:Announce({ "label" })
	end
end

OnShow = WrapFunc(OnShow, function(orig)
	orig()
	CAI_PushDialog()
end)

HandleExitRequest = WrapFunc(HandleExitRequest, function(orig)
	CAI_PopDialog()
	orig()
end)

DoTransitionToStagingRoom = WrapFunc(DoTransitionToStagingRoom, function(orig)
	CAI_PopDialog()
	orig()
end)

OnJoinRoomComplete = WrapFunc(OnJoinRoomComplete, function(orig, ...)
	orig(...)
	CAI_SpeakStatusIfChanged()
end)

OnJoinGameComplete = WrapFunc(OnJoinGameComplete, function(orig, ...)
	orig(...)
	CAI_SpeakStatusIfChanged()
end)

OnFinishedGameplayContentConfigure = WrapFunc(OnFinishedGameplayContentConfigure, function(orig, kEvent)
	orig(kEvent)
	if m_CAI_WaitingForRecoveryConfigure and kEvent.Success == true then
		CAI_ShowPendingFailurePopup()
	end
end)

OnModStatusUpdated = WrapFunc(OnModStatusUpdated, function(orig, ...)
	orig(...)
	CAI_SpeakStatusIfChanged()
end)

OnConnectedToNetSessionHost = WrapFunc(OnConnectedToNetSessionHost, function(orig, ...)
	orig(...)
	CAI_SpeakStatusIfChanged()
end)

OnJoinRoomFailed = WrapFunc(OnJoinRoomFailed, function(orig, ...)
	local iExtendedError = ...
	if ContextPtr:IsHidden() or Network.IsMatchMaking() then
		orig(...)
		return
	end

	local popupText, popupTitle = CAI_GetJoinRoomFailurePopup(iExtendedError)
	print("JoiningRoom::OnJoinRoomFailed() deferring popup until CAI recovery completes.")
	CAI_DeferFailurePopup(popupText, popupTitle)
end)

OnMultiplayerMatchmakingFailed = WrapFunc(OnMultiplayerMatchmakingFailed, function(orig, ...)
	if ContextPtr:IsHidden() then
		orig(...)
		return
	end

	print("JoiningRoom::OnMultiplayerMatchmakingFailed() deferring popup until CAI recovery completes.")
	CAI_DeferFailurePopup("LOC_MP_JOIN_FAILED", "LOC_MP_JOIN_FAILED_TITLE")
end)

OnMultiplayerGameAbandoned = WrapFunc(OnMultiplayerGameAbandoned, function(orig, ...)
	local eReason = ...
	if ContextPtr:IsHidden() or Network.IsMatchMaking() then
		orig(...)
		return
	end

	local popupText, popupTitle = CAI_GetAbandonedFailurePopup(eReason)
	print("JoiningRoom::OnMultiplayerGameAbandoned() deferring popup until CAI recovery completes.")
	CAI_DeferFailurePopup(popupText, popupTitle)
end)

OnBeforeMultiplayerInviteProcessing = WrapFunc(OnBeforeMultiplayerInviteProcessing, function(orig, ...)
	CAI_PopDialog()
	orig(...)
end)

Initialize = WrapFunc(Initialize, function(orig)
	orig()
	Events.LeaveGameComplete.Add(CAI_OnLeaveGameComplete)
	ContextPtr:SetInputHandler(function(input)
		if mgr:HandleInput(input) then
			return true
		end
		if input:GetMessageType() == KeyEvents.KeyUp and input:GetKey() == Keys.VK_ESCAPE then
			HandleExitRequest()
			return true
		end
		return true
	end, true)
end)
--#End of accessibility integration
Initialize();
