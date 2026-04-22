include("PopupDialog");

m_kPopupDialog = PopupDialog:new("FrontEndPopup");

-------------------------------------------------
-- Event Handler: FrontEndPopup
-------------------------------------------------
function OnFrontEndPopup(popupText :string, popupTitle :string)
	UIManager:QueuePopup( ContextPtr, PopupPriority.Current );
	
	m_kPopupDialog:Close();
	m_kPopupDialog:AddTitle(Locale.Lookup(popupTitle));
	m_kPopupDialog:AddText(Locale.Lookup(popupText));
	m_kPopupDialog:AddButton(Locale.Lookup("LOC_CLOSE"), OnPopupClose);
	m_kPopupDialog:Open();
	Speak("Multiplayer popup")
end

-- ===========================================================================
function OnUserRequestClose()
	UIManager:QueuePopup( ContextPtr, PopupPriority.Current );

	m_kPopupDialog:Close();
	m_kPopupDialog:AddText(Locale.Lookup("LOC_CONFIRM_EXIT_TXT"));
	m_kPopupDialog:AddTitle(Locale.ToUpper(Locale.Lookup("LOC_MAIN_MENU_EXIT_TO_DESKTOP")));
	m_kPopupDialog:AddButton(Locale.Lookup("LOC_OK_BUTTON"), ExitOK, nil, nil, "PopupButtonInstanceRed"); 
	m_kPopupDialog:AddButton(Locale.Lookup("LOC_CANCEL_BUTTON"), OnPopupClose);
	m_kPopupDialog:Open();
end

-- ===========================================================================
function OnLaunchError(error:string)
	UIManager:QueuePopup( ContextPtr, PopupPriority.Current );

	m_kPopupDialog:Close();
	m_kPopupDialog:AddText(error);
	m_kPopupDialog:AddTitle(Locale.ToUpper(Locale.Lookup("LOC_GAME_START_ERROR_TITLE")));
	m_kPopupDialog:AddButton(Locale.Lookup("LOC_GAME_START_VIEW_MODS"), OnDisableMods, nil, nil, "PopupButtonInstanceGreen" );
	m_kPopupDialog:AddButton(Locale.Lookup("LOC_CLOSE"), OnPopupClose);
	m_kPopupDialog:Open();
end


-- ===========================================================================
function OnDisableMods()
	OnPopupClose();
	LuaEvents.MainMenu_ShowAdditionalContent();
end

-- ===========================================================================
function OnPopupClose()
	UIManager:DequeuePopup( ContextPtr );
	LuaEvents.FrontEndPopup_CloseConfirmationWithoutAction();
end

-- ===========================================================================
function ExitOK()
	OnPopupClose();

	local pFriends = Network.GetFriends();
	if pFriends ~= nil then
		pFriends:ClearRichPresence();
	end

	Events.UserConfirmedClose();
end

-- ===========================================================================
-- ESC handler
-- ===========================================================================
function InputHandler( uiMsg, wParam, lParam )
	if uiMsg == KeyEvents.KeyUp then
		if wParam == Keys.VK_ESCAPE then
			if(m_kPopupDialog and m_kPopupDialog:IsOpen()) then
				OnPopupClose();
			end
		end
		return true;
	end
end

-- ===========================================================================
function Initialize()
	ContextPtr:SetInputHandler( InputHandler );

	-- Events.FrontEndPopup has 256 character limit for popupText and popupTitle.
	-- LuaEvents.MultiplayerPopup should have unlimited character size.
	Events.FrontEndPopup.Add( OnFrontEndPopup );
	LuaEvents.MultiplayerPopup.Add( OnFrontEndPopup );
	LuaEvents.MainMenu_LaunchError.Add( OnLaunchError );
	LuaEvents.MainMenu_UserRequestClose.Add( OnUserRequestClose );
end
--#Accessibility integration
include ("caiUtils")
local mgr = ExposedMembers.CAI_UIManager
---Mainly here to set the input handler for frontend popups, since popup dialogs don't necessarily have their own context. 
---Note that the original input handler has been updated to use the newer InputStruct system. See 'InputHandler' in the base file
Initialize = WrapFunc(Initialize, function(orig)
	orig()
	ContextPtr:SetInputHandler(function(input)
		local handled = mgr:HandleInput(input)
		if not handled then
			return InputHandler(input)
		end
		return handled
	end, true)
end)

-- We wrap this one as well since for some reason they call it instead of simply using the regular ClosePopup
OnPopupClose = WrapFunc(OnPopupClose, function(orig)
	orig()
        mgr:Pop()
end)
--#End of accessibility integration
Initialize();
