-- ===========================================================================
-- FiraxisLive / My2k
-- ===========================================================================

include("InstanceManager");



-- ===========================================================================
--	DEFINES
-- ===========================================================================

local SIZE_DIALOG_ART_SPACE_Y    = 128 + 30 + 30; -- For resizing based on contents

local DIALOG_MAIN_MENU           = 1;
local DIALOG_LOGIN               = 2;
local DIALOG_NEW_USER            = 3; -- email
local DIALOG_USER_NAME           = 4;
local DIALOG_LEGAL               = 6;
local DIALOG_LEGAL_ITEM          = 7;
local DIALOG_LOGOUT              = 8;
-- all Dialogs below here must be message only dialogs
local DIALOG_MESSAGE             = 9;
local DIALOG_LOGGED_OUT          = 10;
local DIALOG_UNLINK_CONFIRMATION = 11;


-- ===========================================================================
--	MEMBERS
--	TODO:	Consider making the managers local to an Initialize and keeping
--			the dialogs themselves.
-- ===========================================================================
local m_2KMainMenuManager         = InstanceManager:new("2KMainMenuInstance", "Dialog", Controls.My2KBG);
local m_unlinkConfirmationManager = InstanceManager:new("UnlinkConfirmationInstance", "Dialog", Controls.My2KBG);
local m_LoginDialogManager        = InstanceManager:new("LoginDialogInstance", "Dialog", Controls.My2KBG);
local m_NewUserDialogManager      = InstanceManager:new("NewUserDialogInstance", "Dialog", Controls.My2KBG);
local m_UserNameDialogManager     = InstanceManager:new("UserNameDialogInstance", "Dialog", Controls.My2KBG);
local m_LegalDialogManager        = InstanceManager:new("LegalDialogInstance", "Dialog", Controls.My2KBG);
local m_LegalItemDialogManager    = InstanceManager:new("LegalItemDialogInstance", "Dialog", Controls.My2KBG);
local m_MessageDialogManager      = InstanceManager:new("MessageDialogInstance", "Dialog", Controls.My2KBG);
local m_LogoutDialogManager       = InstanceManager:new("LogoutDialogInstance", "Dialog", Controls.My2KBG);

local m_currentDialogID           = DIALOG_MAIN_MENU;
local m_currentDialog             = nil;
local m_currentDialogData         = nil;
local m_legalItemIndex            = -1;

local m_bESCEnabled               = true;
local m_CancelFunction            = nil;

-- ===========================================================================
--  Helper functions
-- ===========================================================================

function FixupText(text)
	-- Replace tabs with spaces
	text = string.gsub(text, "\t", "    ");
	-- Replace Newlines with [NEWLINE]
	text = string.gsub(text, "\n", "[NEWLINE]");

	return text;
end

-- ===========================================================================
--	Leave My2K popup dialog
-- ===========================================================================
function OnReturn()
	UIManager:DequeuePopup(ContextPtr);

	-- Clear any prior dialogs:
	DestroyDialogIfExists(m_2KMainMenuManager);
	DestroyDialogIfExists(m_LoginDialogManager);
	DestroyDialogIfExists(m_NewUserDialogManager);
	DestroyDialogIfExists(m_UserNameDialogManager);
	DestroyDialogIfExists(m_LegalDialogManager);
	DestroyDialogIfExists(m_LegalItemDialogManager);
	DestroyDialogIfExists(m_MessageDialogManager);
	DestroyDialogIfExists(m_LogoutDialogManager);
	DestroyDialogIfExists(m_unlinkConfirmationManager);

	local m_previousDialogData = m_currentDialogData;

	m_currentDialog            = nil;
	m_currentDialogData        = nil;

	m_legalItemIndex           = -1;

	m_bESCEnabled              = true;
	m_cancelFunction           = nil;

	return m_previousDialogData;
end

LuaEvents.CloseAnyQueuedMy2KPopup.Add(OnReturn);

-- ===========================================================================
-- ===========================================================================
function InputHandler(uiMsg, wParam, lParam)
	if uiMsg == KeyEvents.KeyUp
	then
		if (wParam == Keys.VK_ESCAPE and m_bESCEnabled == true) then
			if (m_cancelFunction ~= nil) then
				m_cancelFunction();
			else
				OnReturn();
			end
		end
	end
	return true;
end

ContextPtr:SetInputHandler(InputHandler);


-- ===========================================================================
-- ===========================================================================
function DestroyDialogIfExists(dialogManager)
	if (dialogManager) then
		dialogManager:ResetInstances();
	end
end

-- ===========================================================================
-- ===========================================================================
function ShowHideHandler(bIsHide, bIsInit)
	if (bIsHide) then
		return;
	end

	if (gCurrentDialogID == nil) then
		gCurrentDialogID = DIALOG_MAIN_MENU;
	end

	--m_currentDialogID = DIALOG_LOGIN; --debug

	if (m_currentDialogID == DIALOG_MAIN_MENU) then Create2KMainMenu(); end
	if (m_currentDialogID == DIALOG_LOGIN) then CreateLoginDialog(); end
	if (m_currentDialogID == DIALOG_NEW_USER) then CreateNewUserDialog(); end
	if (m_currentDialogID == DIALOG_USER_NAME) then CreateUserNameDialog(); end
	if (m_currentDialogID == DIALOG_LEGAL) then CreateLegalDialog(); end
	if (m_currentDialogID == DIALOG_LEGAL_ITEM) then CreateLegalItemDialog(); end
	if (m_currentDialogID == DIALOG_MESSAGE) then CreateMessageDialog(); end
	if (m_currentDialogID == DIALOG_LOGOUT) then CreateLogoutDialog(); end
	if (m_currentDialogID == DIALOG_UNLINK_CONFIRMATION) then CreateUnlinkConfirmationDialog(); end
end

ContextPtr:SetShowHideHandler(ShowHideHandler);

-- ===========================================================================
-- ===========================================================================

function ResizeInstance(instance)
	if (instance ~= nil) then
		instance.WindowData:CalculateSize();
		local contentSizeY = instance.WindowData:GetSizeY();
		instance.Dialog:SetSizeY(contentSizeY + SIZE_DIALOG_ART_SPACE_Y);
		instance.WindowBacking:SetSizeY(contentSizeY + SIZE_DIALOG_ART_SPACE_Y);
		--instance.WindowOutline:SetSizeY( contentSizeY + SIZE_DIALOG_ART_SPACE_Y );
	end
end

-- ===========================================================================
-- ===========================================================================
function IsValidEmail(email)
	if (email == nil) then
		return false
	end

	local _, numAts = email:gsub('@', '@'); -- Counts the number of '@' symbol

	if (numAts > 1 or numAts == 0 or email:len() > 254 or email:find('%s')) then
		return false;
	end

	local atPos = string.find(email, '@');
	local localPart = string.sub(email, 0, atPos - 1); -- Gets the substring before '@' symbol
	local domainPart = string.sub(email, atPos + 1); -- Gets the substring after '@' symbol

	-- if there is no local or domain, then invalid email.
	if (not localPart or not domainPart) then
		return false;
	end

	-- Check the local for validity
	if (not localPart:match("[%w!#%$%%&'%*%+%-/=%?^_`{|}~]+") or (localPart:len() > 64)) then
		return false;
	end
	if (localPart:match('^%.+') or localPart:match('%.+$') or localPart:find('%.%.+')) then
		return false;
	end

	-- Check the domain for validity
	if (not domainPart:match('[%w%-_]+%.%a%a+$') or domainPart:len() > 253) then
		return false;
	end
	local fDomain = string.sub(domainPart, 0, string.find(domainPart, '%.') - 1); -- Gets the substring in the domain-part before the last (dot) character
	if (fDomain:match('^[_%-%.]+') or fDomain:match('[_%-%.]+$') or fDomain:find('%.%.+')) then
		return false;
	end

	return true;
end

-- ===========================================================================
function GetUnlinkedTooltip()
	if (Network.IsAgeRestricted()) then
		return Locale.Lookup("TXT_KEY_MY2K_MODE_AGE_RESTRICTED_TOOLTIP");
	end

	if (Network.GetNetworkPlatform() == NetworkPlatform.NETWORK_PLATFORM_EOS) then
		return Locale.Lookup("TXT_KEY_EPIC_MY2K_MODE_UNLINKED_TOOLTIP");
	end

	return Locale.Lookup("TXT_KEY_MY2K_MODE_UNLINKED_TOOLTIP");
end

-- ===========================================================================
-- ===========================================================================

function ChangeMy2KTexture(control, labelControl, my2KLinked)
	if (control ~= nil and control.SetTexture ~= nil) then
		if (my2KLinked) then
			control:SetTexture("My2KLogoButtonLoggedIn");
			control:SetToolTipString(Locale.Lookup("TXT_KEY_MY2K_MODE_LINKED_TOOLTIP"));
			if (labelControl ~= nil and labelControl.LocalizeAndSetText ~= nil) then
				labelControl:LocalizeAndSetText("TXT_KEY_MY2K_ADDITION_UNLINK_ACCOUNT_TITLE");
			end
		else
			control:SetTexture("My2KLogoButton");
			control:SetToolTipString(GetUnlinkedTooltip());
			if (labelControl ~= nil and labelControl.LocalizeAndSetText ~= nil) then
				labelControl:LocalizeAndSetText("TXT_KEY_MY2K_ADDITION_LINK_ACCOUNT_TITLE");
			end
		end
	end
end

function LoggedIn()
	local my2KLinked = FiraxisLive.IsMy2KAccountLinked();
	local kandoConnected = FiraxisLive.IsKandoConnected();
	-- If we have already determined we are age restricted, we are offline
	if (Network.IsAgeRestricted()) then
		kandoConnected = false;
	end

	local control = ContextPtr:LookUpControl("/FrontEnd/MainMenu/My2KLogin");
	local labelControl = ContextPtr:LookUpControl("/FrontEnd/MainMenu/My2KStatus");
	if (control ~= nil) then
		-- TODO(asherburne): Find another method to determine if my2k is logged in but offline.
		if (kandoConnected) then
			control:SetDisabled(false);
			ChangeMy2KTexture(control, labelControl, my2KLinked);
		else
			ChangeMy2KTexture(control, labelControl, false);
			control:SetDisabled(true);
			labelControl:LocalizeAndSetText("TXT_KEY_MY2K_MODE_ANONYMOUS");
		end
	end
end

function LoggedOut()
	LoggedIn()
end

function ClosePreviousMenu()
	if m_currentDialog ~= nil then
		OnReturn();
	end
end

-- ===========================================================================
-- ===========================================================================

function Create2KMainMenu()
	local instance = m_2KMainMenuManager:GetInstance();

	instance.LoginButton:SetDisabled(false);
	instance.LoginButton:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	instance.LoginButton:RegisterCallback(Mouse.eLClick,
		function()
			if (FiraxisLive.My2KBeginLogin()) then
				UI.PlaySound("Play_MP_Player_Connect");
				instance.LoginButton:SetDisabled(true);
				if (instance.NewUserButton ~= nil) then
					instance.NewUserButton:SetDisabled(true);
				end
				instance.CancelButton:SetDisabled(true);
			end
		end);

	if (instance.NewUserButton ~= nil) then
		instance.NewUserButton:SetDisabled(false);
		instance.NewUserButton:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
		instance.NewUserButton:RegisterCallback(Mouse.eLClick,
			function()
				if (FiraxisLive.My2KCreateNewUser()) then
					UI.PlaySound("Confirm_Bed_Positive");
					instance.LoginButton:SetDisabled(true);
					instance.NewUserButton:SetDisabled(true);
					instance.CancelButton:SetDisabled(true);
				end
			end);
	end

	m_bESCEnabled = true;
	m_cancelFunction = function()
		UI.PlaySound("Play_UI_Click");
		OnReturn();
	end;
	instance.CancelButton:SetDisabled(false);
	instance.CancelButton:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	instance.CancelButton:RegisterCallback(Mouse.eLClick, m_cancelFunction);

	ResizeInstance(instance);

	m_currentDialog = instance;
end

-- ===========================================================================
function Show2KMainMenu()
	ClosePreviousMenu();

	m_currentDialogID = DIALOG_MAIN_MENU;
	m_currentDialogData = {};

	local My2KPanel = ContextPtr:LookUpControl("/FrontEnd/MainMenu/My2K");
	if (My2KPanel ~= nil) then
		UIManager:QueuePopup(My2KPanel, PopupPriority.Current);
	end
end

function CreateUnlinkConfirmationDialog()
	local instance = m_unlinkConfirmationManager:GetInstance();
	instance.OkButton:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	instance.OkButton:RegisterCallback(Mouse.eLClick,
		function()
			if (FiraxisLive.My2KUnlinkAccount()) then
				UI.PlaySound("Play_MP_Player_Disconnect");
				instance.OkButton:SetDisabled(true);
				instance.CancelButton:SetDisabled(true);
			end
		end);

	m_cancelFunction = function()
		UI.PlaySound("Play_UI_Click");
		OnReturn();
	end;

	instance.OkButton:SetDisabled(false);
	instance.CancelButton:SetDisabled(false);
	instance.CancelButton:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	instance.CancelButton:RegisterCallback(Mouse.eLClick, m_cancelFunction);

	ResizeInstance(instance);

	m_currentDialog = instance;
end

function ShowUnlinkConfirmationWindow()
	ClosePreviousMenu()
	m_currentDialogID = DIALOG_UNLINK_CONFIRMATION
	m_currentDialogData = {}

	local my2KPanel = ContextPtr:LookUpControl("/FrontEnd/MainMenu/My2K")

	if my2KPanel ~= nil then
		UIManager:QueuePopup(my2KPanel, PopupPriority.Current)
	end
end

-- ===========================================================================
-- ===========================================================================
function ValidateLoginButtons(instance)
	if instance.Email:GetText() ~= nil and IsValidEmail(instance.Email:GetText()) then
		if instance.Password:GetText() ~= nil and instance.Password:GetText():len() > 0 then
			instance.LoginButton:SetDisabled(false);
		else
			instance.LoginButton:SetDisabled(true);
		end
	else
		instance.LoginButton:SetDisabled(true);
	end
end

-- ===========================================================================
function CreateLoginDialog()
	local instance = m_LoginDialogManager:GetInstance();

	instance.Title:SetText(m_currentDialogData.title);
	instance.Message:SetText(m_currentDialogData.message);
	instance.EMailTitle:SetText(m_currentDialogData.emailTitle);
	instance.PasswordTitle:SetText(m_currentDialogData.passwordTitle);

	instance.Email:SetText("");
	instance.Email:TakeFocus();
	instance.Email:RegisterStringChangedCallback(
		function()
			ValidateLoginButtons(instance);
		end
	);

	instance.Password:SetText("");
	instance.Password:RegisterStringChangedCallback(
		function()
			ValidateLoginButtons(instance);
		end
	);

	m_bESCEnabled = true;
	m_cancelFunction =
		function()
			UI.PlaySound("Play_UI_Click");
			FiraxisLive.My2KLoginUser("", "", false);
			OnReturn()
		end;

	instance.CancelText:SetText(m_currentDialogData.cancel);
	instance.CancelButton:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	instance.CancelButton:RegisterCallback(Mouse.eLClick, m_cancelFunction);
	instance.CreateButton:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	instance.CreateText:SetText(m_currentDialogData.create);
	instance.CreateButton:RegisterCallback(Mouse.eLClick,
		function()
			local email = instance.Email:GetText();
			UI.PlaySound("Play_UI_Click");
			if email == nil or email == "" then
				email = " ";
			end

			local password = instance.Password:GetText();

			if password == nil then
				password = "";
			end

			FiraxisLive.My2KLoginUser(email, password, true);
		end);

	instance.LoginText:SetText(m_currentDialogData.login);
	instance.LoginButton:SetDisabled(true);
	instance.LoginButton:RegisterCallback(Mouse.eLClick,
		function()
			if (instance.Email:GetText() ~= nil and IsValidEmail(instance.Email:GetText())) then
				local password = instance.Password:GetText();
				if password == nil then
					password = "";
				end
				FiraxisLive.My2KLoginUser(instance.Email:GetText(), password, false);
			end
		end);

	ResizeInstance(instance);

	m_currentDialog = instance;

	ValidateLoginButtons(instance);
end

-- ===========================================================================
function ShowLoginDialog(dialogData)
	ClosePreviousMenu();

	m_currentDialogID = DIALOG_LOGIN;
	m_currentDialogData = dialogData;

	local My2KPanel = ContextPtr:LookUpControl("/FrontEnd/MainMenu/My2K");
	if (My2KPanel ~= nil) then
		UIManager:QueuePopup(My2KPanel, PopupPriority.Current);
	end
end

-- ===========================================================================
-- ===========================================================================

-- ===========================================================================
function RealizeOkForNewUserDialog(instance)
	local bEmailValid = false;

	if (instance.Email:GetText() ~= nil and IsValidEmail(instance.Email:GetText())) then
		bEmailValid = true;
	end

	instance.NewUserButton:SetDisabled(bEmailValid ~= true);
end

-- ===========================================================================
function CreateNewUserDialog()
	local instance = m_NewUserDialogManager:GetInstance();

	instance.Title:SetText(m_currentDialogData.title);
	instance.Message:SetText(m_currentDialogData.message);
	instance.EMailTitle:SetText(m_currentDialogData.emailTitle);

	instance.Email:SetDisabled(false);
	instance.Email:SetText("");
	instance.Email:TakeFocus();
	instance.Email:RegisterStringChangedCallback(
		function()
			RealizeOkForNewUserDialog(instance);
		end
	);

	m_bESCEnabled = true;
	m_cancelFunction =
		function()
			UI.PlaySound("Play_UI_Click");
			FiraxisLive.My2KNewUserResponseCancel()
			OnReturn();
		end;

	--instance.CancelText:SetText(m_currentDialogData.cancel);
	instance.CancelButton:SetDisabled(false);
	instance.CancelButton:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	instance.CancelButton:RegisterCallback(Mouse.eLClick, m_cancelFunction);

	--instance.NewUserText:SetText(m_currentDialogData.newuser);
	instance.NewUserButton:SetDisabled(true);
	instance.NewUserButton:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	instance.NewUserButton:RegisterCallback(Mouse.eLClick,
		function()
			if (instance.Email:GetText() ~= nil and IsValidEmail(instance.Email:GetText())) then
				-- Disable all the things!
				UI.PlaySound("Play_UI_Click");

				m_bESCEnabled = false;
				instance.Email:SetDisabled(true);
				instance.CancelButton:SetDisabled(true);
				instance.NewUserButton:SetDisabled(true);

				FiraxisLive.My2KNewUserResponse(instance.Email:GetText());
			end
		end);

	ResizeInstance(instance);

	m_currentDialog = instance;

	RealizeOkForNewUserDialog(instance);
end

-- ===========================================================================
function ShowNewUserDialog(dialogData)
	ClosePreviousMenu();

	m_currentDialogID = DIALOG_NEW_USER;
	m_currentDialogData = dialogData;

	local My2KPanel = ContextPtr:LookUpControl("/FrontEnd/MainMenu/My2K");
	if (My2KPanel ~= nil) then
		UIManager:QueuePopup(My2KPanel, PopupPriority.Current);
	end
end

-- ===========================================================================
-- ===========================================================================

-- ===========================================================================
function RealizeOkForUserNameDialog(instance)
	if (instance.Email:GetText() ~= nil and IsValidEmail(instance.Email:GetText())) then
		instance.OkButton:SetDisabled(false);
	else
		instance.OkButton:SetDisabled(true);
	end
end

-- ===========================================================================
function CreateUserNameDialog()
	local instance = m_UserNameDialogManager:GetInstance();

	instance.Title:SetText(m_currentDialogData.title);
	instance.Message:SetText(m_currentDialogData.message);
	instance.EMailTitle:SetText(m_currentDialogData.emailTitle);

	instance.Email:TakeFocus();
	instance.Email:RegisterCharCallback(
		function()
			RealizeOkForUserNameDialog(instance);
		end
	);


	m_bESCEnabled = true;
	m_cancelFunction =
		function()
			UI.PlaySound("Play_UI_Click");
			FiraxisLive.My2KEmailResponse("", false);
			ShowNewUserDialog();
		end;

	instance.CancelText:SetText(m_currentDialogData.cancel);
	instance.CancelButton:SetDisabled(false);
	instance.CancelButton:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	instance.CancelButton:RegisterCallback(Mouse.eLClick, m_cancelFunction);

	instance.OkText:SetText(m_currentDialogData.ok);
	instance.OkButton:SetDisabled(true);
	instance.OkButton:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	instance.OkButton:RegisterCallback(Mouse.eLClick,
		function()
			if (instance.Email:GetText() ~= nil and IsValidEmail(instance.Email:GetText())) then
				UI.PlaySound("Play_UI_Click");
				m_bESCEnabled = false;
				instance.OkButton:SetDisabled(true);
				instance.CancelButton:SetDisabled(true);
				FiraxisLive.My2KEmailResponse(instance.Email:GetText(), true);
			end
		end);

	ResizeInstance(instance);

	m_currentDialog = instance;

	RealizeOkForUserNameDialog(instance);
end

-- ===========================================================================
function ShowUserNameDialog(dialogData)
	ClosePreviousMenu();

	m_currentDialogID = DIALOG_USER_NAME;
	m_currentDialogData = dialogData;

	local My2KPanel = ContextPtr:LookUpControl("/FrontEnd/MainMenu/My2K");
	if (My2KPanel ~= nil) then
		UIManager:QueuePopup(My2KPanel, PopupPriority.Current);
	end
end

-- ===========================================================================
-- ===========================================================================

function CreateLegalDialog()
	local instance         = m_LegalDialogManager:GetInstance();

	local LegalItemManager = InstanceManager:new("LegalItemInstance", "Group", instance.ContentStack);

	instance.ContentStack:DestroyAllChildren();

	m_bESCEnabled = false; -- No cancelling the Legal screen

	instance.Title:SetText(m_currentDialogData.title);
	instance.Message:SetText(m_currentDialogData.message);

	-- Create a button for each document
	local docInstance;
	for i, document in ipairs(m_currentDialogData.documents) do
		docInstance = LegalItemManager:GetInstance();
		-- Change all tabs into 4 spaces
		docInstance.ReadText:SetText(FixupText(document.Name));
		docInstance.ReadButton:SetSizeY(docInstance.ReadText:GetSizeY() + 24);
		docInstance.ReadButton:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
		docInstance.ReadButton:RegisterCallback(Mouse.eLClick,
			function()
				UI.PlaySound("Play_UI_Click");
				ShowLegalItemDialog(m_currentDialogData, i);
			end);
	end

	-- Set buttons
	instance.DisagreeAllText:SetText(m_currentDialogData.disagree);
	instance.DisagreeAllButton:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	instance.DisagreeAllButton:RegisterCallback(Mouse.eLClick,
		function()
			UI.PlaySound("Play_UI_Click");
			local agreeList = {};
			agreeList["AgreeCount"] = 0;

			if (FiraxisLive.My2KLegalResponse(agreeList)) then
				OnReturn();
			end
		end);

	instance.AgreeAllText:SetText(m_currentDialogData.agree);
	instance.AgreeAllButton:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	instance.AgreeAllButton:RegisterCallback(Mouse.eLClick,
		function()
			UI.PlaySound("Play_UI_Click");
			local agreeList = {};

			agreeList["AgreeCount"] = #m_currentDialogData.documents;
			for i, document in ipairs(m_currentDialogData.documents) do
				agreeList[i] = document.ID;
			end

			if (FiraxisLive.My2KLegalResponse(agreeList)) then
				OnReturn();
			end
		end);

	instance.ContentStack:CalculateSize();
	instance.ContentArea:CalculateInternalSize();

	instance.ContentArea:SetScrollValue(0);

	ResizeInstance(instance);

	m_currentDialog = instance;
end

-- ===========================================================================
function ShowLegalDialog(dialogData)
	ClosePreviousMenu();

	m_currentDialogID = DIALOG_LEGAL;
	m_currentDialogData = dialogData;

	local My2KPanel = ContextPtr:LookUpControl("/FrontEnd/MainMenu/My2K");
	if (My2KPanel ~= nil) then
		UIManager:QueuePopup(My2KPanel, PopupPriority.Current);
	end
end

-- ===========================================================================
-- ===========================================================================

function CreateLegalItemDialog()
	local instance         = m_LegalItemDialogManager:GetInstance();

	local LegalTextManager = InstanceManager:new("LegalTextInstance", "LegalText", instance.ContentStack);

	instance.ContentStack:DestroyAllChildren();

	instance.Title:SetText(m_currentDialogData.title);

	-- Split EULA into individual paragraphs based on \n
	local textAreas = {};
	for para in string.gmatch(m_currentDialogData.documents[m_legalItemIndex].Text .. "\n", "(.-)\n") do
		table.insert(textAreas, FixupText(para))
	end

	-- Create a text area for each paragraph.
	local textArea;
	for iArea = 1, #textAreas, 1 do
		textArea = LegalTextManager:GetInstance();
		textArea.LegalText:SetText(textAreas[iArea]);
	end

	-- Set buttons

	m_bESCEnabled = true;
	m_cancelFunction =
		function()
			UI.PlaySound("Play_UI_Click");
			ShowLegalDialog(m_currentDialogData);
		end

	instance.OkButton:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	instance.OkButton:RegisterCallback(Mouse.eLClick, m_cancelFunction);

	instance.ContentStack:CalculateSize();
	instance.ContentArea:CalculateInternalSize();

	instance.ContentArea:SetScrollValue(0);

	-- Grab one of the callbacks (doesn't matter which) and if enough scrollage has
	-- occurred, enabled the okay button.
	--instance.ContentArea:RegisterDownEndCallback(
	--function( control )
	--local scrollAmount = instance.ContentArea:GetScrollValue();
	--if scrollAmount > 0.95 then
	--instance.OkButton:SetDisabled( false );
	--end
	--end		
	--);

	m_currentDialog = instance;
end

-- ===========================================================================
function ShowLegalItemDialog(dialogData, documentIndex)
	ClosePreviousMenu();

	m_currentDialogID = DIALOG_LEGAL_ITEM;
	m_currentDialogData = dialogData;
	m_legalItemIndex = documentIndex;

	local My2KPanel = ContextPtr:LookUpControl("/FrontEnd/MainMenu/My2K");
	if (My2KPanel ~= nil) then
		UIManager:QueuePopup(My2KPanel, PopupPriority.Current);
	end
end

-- ===========================================================================
-- ===========================================================================
function CreateMessageDialog()
	local instance = m_MessageDialogManager:GetInstance();

	instance.Title:SetText(m_currentDialogData.title);
	instance.Message:SetText(m_currentDialogData.message);
	instance.OkText:SetText(m_currentDialogData.ok);
	instance.My2KLogo:SetHide(not m_currentDialogData.showMy2kLogo);

	m_bESCEnabled = true;
	m_cancelFunction =
		function()
			UI.PlaySound("Play_UI_Click");
			FiraxisLive.My2KMessageResponse(m_currentDialogData.dialogID, true);
			OnReturn();
		end

	instance.OkButton:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	instance.OkButton:RegisterCallback(Mouse.eLClick, m_cancelFunction);

	ResizeInstance(instance);

	m_currentDialog = instance;
end

-- ===========================================================================
function ShowMessageDialog(dialogData)
	ClosePreviousMenu();

	m_currentDialogID = DIALOG_MESSAGE;
	m_currentDialogData = dialogData;
	local My2KPanel = ContextPtr:LookUpControl("/FrontEnd/MainMenu/My2K");
	if (My2KPanel ~= nil) then
		UIManager:QueuePopup(My2KPanel, PopupPriority.Utmost);
	end
end

-- ===========================================================================
-- ===========================================================================
function CreateLogoutDialog()
	local instance = m_LogoutDialogManager:GetInstance();

	instance.Title:SetText(m_currentDialogData.title);
	instance.Message:SetText(m_currentDialogData.message);


	m_bESCEnabled = true;
	m_cancelFunction =
		function()
			FiraxisLive.My2KMessageResponse(m_currentDialogID, false);
			OnReturn();
		end;

	instance.CancelText:SetText(m_currentDialogData.cancel);
	instance.CancelButton:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	instance.CancelButton:RegisterCallback(Mouse.eLClick, m_cancelFunction);

	instance.OkText:SetText(m_currentDialogData.ok);
	instance.OkButton:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	instance.OkButton:RegisterCallback(Mouse.eLClick,
		function()
			FiraxisLive.My2KMessageResponse(m_currentDialogID, true);
			OnReturn();
		end);

	ResizeInstance(instance);

	m_currentDialog = instance;
end

-- ===========================================================================
function ShowLogOutDialog(dialogData)
	ClosePreviousMenu();

	m_currentDialogID = DIALOG_LOGOUT;
	m_currentDialogData = dialogData;

	local My2KPanel = ContextPtr:LookUpControl("/FrontEnd/MainMenu/My2K");
	if (My2KPanel ~= nil) then
		UIManager:QueuePopup(My2KPanel, PopupPriority.Current);
	end
end

-- ===========================================================================
function OnMy2KActivate(bActive)
	LoggedIn();
	if (not ContextPtr:IsHidden()) then
		OnReturn();
	end
end

Events.My2KActivate.Add(OnMy2KActivate);

-- ===========================================================================
function OnMy2KLinkAccountResult(bSuccess)
	LoggedIn();
	-- If successful, exit. If it was an error, the dialog state will be handled by the error.
	if (bSuccess == true) then
		if (not ContextPtr:IsHidden()) then
			OnReturn();
		end
	end
end

Events.My2KLinkAccountResult.Add(OnMy2KLinkAccountResult);

-- ===========================================================================
function OnFiraxisLiveActivate(bActive)
	LoggedIn();
end

Events.FiraxisLiveActivate.Add(OnFiraxisLiveActivate);

-- ===========================================================================
function OnUpdateFiraxisLiveState()
	LoggedIn();
end

LuaEvents.UpdateFiraxisLiveState.Add(OnUpdateFiraxisLiveState);


--#Accessibility integration
include("caiUtils")
local mgr = ExposedMembers.CAI_UIManager
local CAI_My2KDialog ---@type UIWidget

local function RemoveCurrentDialog()
	if not mgr then return end
	mgr:RemoveFromStack(CAI_My2KDialog:GetId())
end

local function PushDialog(dialog)
	if CAI_My2KDialog then
		RemoveCurrentDialog()
	end
	CAI_My2KDialog = dialog
	if mgr then
		mgr:Push(dialog, PopupPriority.Current)
	end
end

local function CreateStaticText(msgControl)
	if mgr == nil then return nil end
	local msg = msgControl:GetText() or ""
	if msg ~= "" then
		return mgr:CreateWidget(mgr:GenerateWidgetId("CAIMy2KStaticText"), "StaticText", {
			Label = function() return msg end
		})
	end
	return nil
end

local function CreateReadOnlyText(text)
	if mgr == nil then return nil end
	local edit = mgr:CreateWidget(mgr:GenerateWidgetId("CAIMy2KEdit"), "EditBox")
	edit:SetText(text, true)
	edit:SetReadOnly(true)
	edit:SetAlwaysEdit(true)
	edit:SetHighlightOnEdit(false)
	return edit
end


local function CreateEdit(labelControl, editControl, setTextOnBufferChange, commitFun)
	if mgr == nil then return nil end
	local edit = mgr:CreateWidget(mgr:GenerateWidgetId("CAIMy2KEdit"), "EditBox", {
		Label = function() return labelControl:GetText() or "" end,
		DisabledPredicate = function()
			return editControl ~= nil and editControl:IsDisabled()
		end,
	})
	edit:SetAlwaysEdit(true)
	edit:SetHighlightOnEdit(true)
	if setTextOnBufferChange then
		edit:On("text_changed", function(w, b)
			editControl:SetText(b)
		end)
	end
	edit:On("value_changed", function(w, v)
		if not editControl then return end
		if commitFun then
			editControl:SetText(v)
			commitFun()
		end
	end)
	edit:SetText(editControl ~= nil and editControl:GetText() or "")
	edit:SetMaxCharacters(64)

	return edit
end

local function MakeButton(actionCtrl, labelCtrl)
	if not mgr then return end
	local btn = mgr:CreateWidget(mgr:GenerateWidgetId("CAI_My2k_BTN"), "Button", {
		Label = function() return labelCtrl:GetText() or "" end,
		DisabledPredicate = function() return actionCtrl:IsDisabled() end
	})
	btn:On("activate", function(w) actionCtrl:DoLeftClick() end)
	btn:SetFocusSound("Main_Menu_Mouse_Over")
	return btn
end

local function GetTitle() return m_currentDialog.Title:GetText() end

Create2KMainMenu = WrapFunc(Create2KMainMenu, function(orig)
	orig()
	if not mgr or not m_currentDialog then return end
	local loginBtn = MakeButton(m_currentDialog.LoginButton, m_currentDialog.LoginText)
	local newUserBtn = MakeButton(m_currentDialog.NewUserButton, m_currentDialog.NewUserText)
	local cancelBtn = MakeButton(m_currentDialog.CancelButton, m_currentDialog.CancelText)
	local dlg = mgr.WidgetHelpers.MakeGeneralDialog(GetTitle, { cancelBtn }, { loginBtn, newUserBtn })
	PushDialog(dlg)
end)

CreateLoginDialog = WrapFunc(CreateLoginDialog, function(orig)
	orig()
	if not mgr or not m_currentDialog then return end
	local emailEdit = CreateEdit(m_currentDialog.EMailTitle, m_currentDialog.Email, true)
	emailEdit:SetTooltip(function() return m_currentDialog.Message:GetText() or "" end)
	local passwordEdit = CreateEdit(m_currentDialog.PasswordTitle, m_currentDialog.Password, true)
	passwordEdit:SetPasswordMask(true)
	local loginBtn = MakeButton(m_currentDialog.LoginButton, m_currentDialog.LoginText)
	local createBtn = MakeButton(m_currentDialog.CreateButton, m_currentDialog.CreateText)
	local cancelBtn = MakeButton(m_currentDialog.CancelButton, m_currentDialog.CancelText)
	m_currentDialog.Email:DropFocus()
	local dlg = mgr.WidgetHelpers.MakeGeneralDialog(GetTitle, { loginBtn, createBtn, cancelBtn },
		{ emailEdit, passwordEdit })
	PushDialog(dlg)
end)

CreateNewUserDialog = WrapFunc(CreateNewUserDialog, function(orig)
	orig()
	Speak("Opening create new user	")
	if not mgr or not m_currentDialog then return end
	local emailEdit = CreateEdit(m_currentDialog.EMailTitle, m_currentDialog.Email, true)
	emailEdit:SetTooltip(function() return m_currentDialog.Message:GetText() or "" end)
	local newUserBtn = MakeButton(m_currentDialog.NewUserButton, m_currentDialog.NewUserText)
	local cancelBtn = MakeButton(m_currentDialog.CancelButton, m_currentDialog.CancelText)
	m_currentDialog.Email:DropFocus()
	local dlg = mgr.WidgetHelpers.MakeGeneralDialog(GetTitle, { newUserBtn, createBtn, cancelBtn }, { emailEdit, })
	PushDialog(dlg)
end)

CreateUserNameDialog = WrapFunc(CreateUserNameDialog, function(orig)
	orig()
	if not mgr or not m_currentDialog then return end
	local emailEdit = CreateEdit(m_currentDialog.EMailTitle, m_currentDialog.Email, true)
	emailEdit:SetTooltip(function() return m_currentDialog.Message:GetText() or "" end)
	local okBtn = MakeButton(m_currentDialog.OkButton, m_currentDialog.OkText)
	local cancelBtn = MakeButton(m_currentDialog.CancelButton, m_currentDialog.CancelText)
	m_currentDialog.Email:DropFocus()
	local dlg = mgr.WidgetHelpers.MakeGeneralDialog(GetTitle, { okBtn, createBtn, cancelBtn }, { emailEdit, })
	PushDialog(dlg)
end)

CreateMessageDialog = WrapFunc(CreateMessageDialog, function(orig)
	orig()
	if not mgr or not m_currentDialog then return end
	local msg = CreateStaticText(m_currentDialog.Message)
	local okBtn = MakeButton(m_currentDialog.OkButton, m_currentDialog.OkText)
	local cancelBtn = MakeButton(m_currentDialog.CancelButton, m_currentDialog.CancelText)
	local dlg = mgr.WidgetHelpers.MakeGeneralDialog(GetTitle, { okBtn, cancelBtn }, { msg })
	PushDialog(dlg)
end)

CreateUnlinkConfirmationDialog = WrapFunc(CreateUnlinkConfirmationDialog, function(orig)
	orig()
	if not mgr then return end
	if not m_currentDialog then return end
	local msg = CreateStaticText(m_currentDialog.Message)
	local okBtn = MakeButton(m_currentDialog.OkButton, m_currentDialog.OkText)
	local cancelBtn = MakeButton(m_currentDialog.CancelButton, m_currentDialog.CancelText)
	local dlg = mgr.WidgetHelpers.MakeGeneralDialog(GetTitle, { okBtn, cancelBtn }, { msg })
	PushDialog(dlg)
end)

CreateLegalDialog = WrapFunc(CreateLegalDialog, function(orig)
	-- Temporarily monkey-patch InstanceManager to capture the local instances
	local capturedInstances = {}
	local oldGetInstance = InstanceManager.GetInstance
	InstanceManager.GetInstance = function(self)
		local inst = oldGetInstance(self)
		table.insert(capturedInstances, inst)
		return inst
	end

	orig()

	InstanceManager.GetInstance = oldGetInstance

	if not mgr or not m_currentDialog then return end
	local content = { CreateStaticText(m_currentDialog.Message) }
	for _, inst in ipairs(capturedInstances) do
		if inst.ReadButton and inst.ReadText then
			local btn = MakeButton(inst.ReadButton, inst.ReadText)
			if btn then
				table.insert(content, btn)
			end
		end
	end
	local agreeBtn = MakeButton(m_currentDialog.AgreeAllButton, m_currentDialog.AgreeAllText)
	local disagreeBtn = MakeButton(m_currentDialog.DisagreeAllButton, m_currentDialog.DisagreeAllText)
	local dlg = mgr.WidgetHelpers.MakeGeneralDialog(GetTitle, { agreeBtn, disagreeBtn }, content)
	PushDialog(dlg)
end)

CreateLegalItemDialog = WrapFunc(CreateLegalItemDialog, function(orig)
	local capturedInstances = {}
	local oldGetInstance = InstanceManager.GetInstance
	InstanceManager.GetInstance = function(self)
		local inst = oldGetInstance(self)
		table.insert(capturedInstances, inst)
		return inst
	end

	orig()

	InstanceManager.GetInstance = oldGetInstance

	if not mgr or not m_currentDialog then return end

	local parts = {}
	local fullText = ""
	for _, inst in ipairs(capturedInstances) do
		if inst.LegalText then
			local txt = inst.LegalText:GetText() or ""
			if txt ~= "" then table.insert(parts, txt) end
		end
	end
	if #parts > 0 then
		fullText = table.concat(parts, "[NEWLINE]")
	end
	local edit = CreateReadOnlyText(fullText)
	local okBtn = MakeButton(m_currentDialog.OkButton, m_currentDialog.OkText)
	local dlg = mgr.WidgetHelpers.MakeGeneralDialog(GetTitle, { okBtn }, { edit })
	PushDialog(dlg)
end)

OnReturn = WrapFunc(OnReturn, function(orig)
	RemoveCurrentDialog()
	return orig()
end)

function OnHandleInput(pInputStruct)
	if mgr then
		if mgr:HandleInput(pInputStruct) then return true end
	end
	local uiMsg = pInputStruct:GetMessageType()
	if uiMsg == KeyEvents.KeyUp then
		if (pInputStruct:GetKey() == Keys.VK_ESCAPE and m_bESCEnabled == true) then
			if (m_cancelFunction ~= nil) then
				m_cancelFunction();
			else
				OnReturn();
			end
		end
	end
	return true
end

function forceLegalDialog()
	local testDialogData = {
		title     = "Accessibility Test: Legal Agreements",                                    -- instance.Title
		message   = "Please review the following terms.",                                      -- instance.Message
		disagree  = "Decline All",                                                             -- instance.DisagreeAllText[cite: 1]
		agree     = "Accept All",                                                              -- instance.AgreeAllText[cite: 1]
		documents = {                                                                          -- m_currentDialogData.documents[cite: 1]
			{
				ID = "TEST_DOC_EULA",                                                          -- Passed back in the agree list[cite: 1]
				Name = "End User License Agreement",                                           -- docInstance.ReadText[cite: 1]
				Text =
				"Section 1: Accessibility Testing.\nSection 2: Testing screen reader speech output queue." -- Parsed by \n[cite: 1]
			},
			{
				ID = "TEST_DOC_PRIVACY",
				Name = "Privacy Policy",
				Text = "This is the second test document.\nConfirming layout flow works."
			}
		}
	}
	ShowLegalDialog(testDialogData)
end

ContextPtr:SetInputHandler(OnHandleInput, true)
--#End of accessibility integration

FiraxisLive.SetUIReady()
