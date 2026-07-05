-------------------------------------------------
-- Confirm Player Kick
-------------------------------------------------

local g_playerID = -1;
local g_initialName:string = "";
local g_initialPassword:string = "";

local HotseatPasswordsMatch = Locale.Lookup( "LOC_MULTIPLAYER_HOTSEAT_PASSWORDS_MATCH" );
local HotseatPasswordsDontMatch = Locale.Lookup( "LOC_MULTIPLAYER_HOTSEAT_PASSWORDS_DONT_MATCH" );
-------------------------------------------------
-------------------------------------------------
function OnCancel()
	local pPlayerConfig = PlayerConfigurations[g_playerID];
	pPlayerConfig:SetHotseatName(g_initialName);
	pPlayerConfig:SetHotseatPassword(g_initialPassword);

    UIManager:PopModal( ContextPtr );
    ContextPtr:CallParentShowHideHandler( true );
    ContextPtr:SetHide( true );
end

-------------------------------------------------
-------------------------------------------------
function OnAccept()
	local passwordString = "";
	local passwordVerifyString = "";
	if(Controls.HotseatPasswordEntry:GetText() ~= nil) then 
		passwordString = Controls.HotseatPasswordEntry:GetText();
	end
	if(Controls.HotseatPasswordVerifyEntry:GetText() ~= nil) then
		passwordVerifyString = Controls.HotseatPasswordVerifyEntry:GetText();
	end
	
	if(passwordString == passwordVerifyString) then
		LuaEvents.EditHotseatPlayer_UpdatePlayer(g_playerID);
		UIManager:PopModal( ContextPtr );
		ContextPtr:CallParentShowHideHandler( true );
		ContextPtr:SetHide( true );
	end
end

function ValidateData()
	local bValid:boolean = true;
	local passwordString = "";
	local passwordVerifyString = "";

	if(Controls.HotseatPasswordEntry:GetText() ~= nil) then 
		passwordString = Controls.HotseatPasswordEntry:GetText();
	end
	if(Controls.HotseatPasswordVerifyEntry:GetText() ~= nil) then
		passwordVerifyString = Controls.HotseatPasswordVerifyEntry:GetText();
	end

	if(passwordString ~= passwordVerifyString) then
		bValid = false;
	end

	local pPlayerConfig = PlayerConfigurations[g_playerID];
	if(pPlayerConfig:GetNickName() == nil or pPlayerConfig:GetNickName() == "") then
		bValid = false;
	end

	Controls.AcceptButton:SetDisabled(not bValid);
end
-------------------------------------------------
-------------------------------------------------
function UpdateHotseatPassword()
	local pPlayerConfig = PlayerConfigurations[g_playerID];
	local passwordString = "";
	local passwordVerifyString = "";
	local localPlayerID = Network.GetLocalPlayerID();
	local localPlayerConfig = PlayerConfigurations[localPlayerID];

	if(GameConfiguration.IsHotseat()) then
		if(Controls.HotseatPasswordEntry:GetText() ~= nil) then 
			passwordString = Controls.HotseatPasswordEntry:GetText();
		end
		if(Controls.HotseatPasswordVerifyEntry:GetText() ~= nil) then
			passwordVerifyString = Controls.HotseatPasswordVerifyEntry:GetText();
		end
		
		if(passwordString == passwordVerifyString) then
			pPlayerConfig:SetHotseatPassword(passwordString);
			--Controls.HotseatPasswordsMatchLabel:SetText(HotseatPasswordsMatch);
			Controls.HotseatPasswordsMatchLabel:SetHide(true);
			Controls.HotseatPasswordsMatchLabel:SetColor(COLOR_GREEN, 0);
		else
			pPlayerConfig:SetHotseatPassword("");
			Controls.HotseatPasswordsMatchLabel:SetText(HotseatPasswordsDontMatch);
			Controls.HotseatPasswordsMatchLabel:SetHide(false);
			Controls.HotseatPasswordsMatchLabel:SetColor(COLOR_RED, 0);
		end

		ValidateData();
	end
end

-------------------------------------------------
-------------------------------------------------
function Realize()
	local pPlayerConfig:table = PlayerConfigurations[g_playerID];
	Controls.HotseatPlayerNameEntry:SetText(pPlayerConfig:GetNickName());
	
	local passwordString = pPlayerConfig:GetHotseatPassword();
	if(passwordString == nil) then
		passwordString = "";
	end
	Controls.HotseatPasswordEntry:SetText(passwordString);
	Controls.HotseatPasswordVerifyEntry:SetText(passwordString);
end
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function OnPlayerNameChanged(playerNameEntry)
	local pPlayerConfig = PlayerConfigurations[g_playerID];
	local playerName = "";
	if(playerNameEntry:GetText() ~= nil) then
		playerName = playerNameEntry:GetText();
	end
	pPlayerConfig:SetHotseatName(playerName);
	ValidateData();
end
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function OnShutdown()
	-- Cache values for hotloading...
	LuaEvents.GameDebug_AddValue("EditHotseatPlayer", "isHidden", ContextPtr:IsHidden());
	LuaEvents.GameDebug_AddValue("EditHotseatPlayer", "g_playerID", g_playerID);
end

function OnGameDebugReturn( context:string, contextTable:table )
	if context == "EditHotseatPlayer" and contextTable["isHidden"] == false then
		g_playerID = contextTable["g_playerID"];
		Realize();
	end
end

function OnShow()
	Controls.PopupAlphaIn:SetToBeginning();
	Controls.PopupAlphaIn:Play();
	Controls.PopupSlideIn:SetToBeginning();
	Controls.PopupSlideIn:Play();
	Controls.HotseatPlayerNameEntry:TakeFocus();
end

function OnInputHandler( uiMsg, wParam, lParam )
    if uiMsg == KeyEvents.KeyUp then
        if wParam == Keys.VK_ESCAPE then
            OnCancel();  
        end
    end
    return true;
end
-- ===========================================================================
--	Initialize screen
-- ===========================================================================
function Initialize()

	ContextPtr:SetShowHandler(OnShow);
	ContextPtr:SetShutdown(OnShutdown);
	ContextPtr:SetInputHandler(OnInputHandler);

	Controls.AcceptButton:RegisterCallback(Mouse.eLClick, OnAccept);
	Controls.CancelButton:RegisterCallback(Mouse.eLClick, OnCancel);
	local canChangeName = UI.HasFeature("TextEntry");
	Controls.HotseatPlayerNameEntry:SetEnabled(canChangeName);
	if canChangeName then
		Controls.HotseatPlayerNameEntry:RegisterStringChangedCallback(OnPlayerNameChanged);
	end
	Controls.HotseatPasswordEntry:RegisterStringChangedCallback(UpdateHotseatPassword);
	Controls.HotseatPasswordVerifyEntry:RegisterStringChangedCallback(UpdateHotseatPassword);

	LuaEvents.GameDebug_Return.Add(OnGameDebugReturn);



	LuaEvents.StagingRoom_SetPlayerID.Add(function(playerID)
		local pPlayerConfig = PlayerConfigurations[playerID];
		g_playerID = playerID;
		g_initialName = pPlayerConfig:GetNickName();
		g_initialPassword = pPlayerConfig:GetHotseatPassword();
		Realize();
	end);
end
--#Accessibility integration
include("caiUtils")

local mgr = ExposedMembers.CAI_UIManager
local m_CAI_Dialog ---@type UIWidget|nil
local m_CAI_NameEdit ---@type EditBoxWidget|nil
local m_CAI_PasswordEdit ---@type EditBoxWidget|nil
local m_CAI_PasswordVerifyEdit ---@type EditBoxWidget|nil
local m_CAI_AcceptButton ---@type UIWidget|nil
local m_CAI_HasValidData:boolean = false

local function CAI_GetControlText(control)
	if control and control.GetText then
		return control:GetText() or ""
	end
	return ""
end

local function CAI_GetControlTooltip(control)
	if control and control.GetToolTipString then
		return control:GetToolTipString() or ""
	end
	return ""
end

local function CAI_JoinLines(lines)
	if #lines == 0 then
		return ""
	end
	return table.concat(lines, "[NEWLINE]")
end

local function CAI_ClearDialogRefs()
	m_CAI_Dialog = nil
	m_CAI_NameEdit = nil
	m_CAI_PasswordEdit = nil
	m_CAI_PasswordVerifyEdit = nil
	m_CAI_AcceptButton = nil
end

local function CAI_RemoveDialog()
	if mgr and m_CAI_Dialog and mgr:GetWidgetById(m_CAI_Dialog:GetId()) then
		mgr:RemoveFromStack(m_CAI_Dialog:GetId())
	end
	CAI_ClearDialogRefs()
end

local function CAI_GetAcceptTooltip()
	local lines = {}
	local mismatch = ""
	if not Controls.HotseatPasswordsMatchLabel:IsHidden() then
		mismatch = CAI_GetControlText(Controls.HotseatPasswordsMatchLabel)
		if mismatch ~= "" then
			table.insert(lines, mismatch)
		end
	end
	local tooltip = CAI_GetControlTooltip(Controls.AcceptButton)
	if tooltip ~= "" and tooltip ~= mismatch then
		table.insert(lines, tooltip)
	end
	return CAI_JoinLines(lines)
end

local function CAI_MakeEdit(id, labelControl, editControl, onTextChanged, isPassword)
	local edit = mgr:CreateWidget(id, "EditBox", {
		Label = function()
			return CAI_GetControlText(labelControl)
		end,
		DisabledPredicate = function()
			return editControl ~= nil and editControl:IsDisabled()
		end,
		FocusKey = id,
	})
	edit:SetAlwaysEdit(true)
	edit:SetHighlightOnEdit(true)
	edit:SetMaxCharacters(32)
	if isPassword then
		edit:SetPasswordMask(true)
	end
	edit:On("text_changed", function(_, text)
		editControl:SetText(text)
		onTextChanged(editControl)
	end)
	return edit
end

local function CAI_SyncDialogFromControls()
	if m_CAI_NameEdit then
		m_CAI_NameEdit:SetText(CAI_GetControlText(Controls.HotseatPlayerNameEntry), true)
	end
	if m_CAI_PasswordEdit then
		m_CAI_PasswordEdit:SetText(CAI_GetControlText(Controls.HotseatPasswordEntry), true)
	end
	if m_CAI_PasswordVerifyEdit then
		m_CAI_PasswordVerifyEdit:SetText(CAI_GetControlText(Controls.HotseatPasswordVerifyEntry), true)
	end
end

local function CAI_PushDialog()
	if not mgr or ContextPtr:IsHidden() or not m_CAI_HasValidData then
		return
	end

	CAI_RemoveDialog()

	m_CAI_NameEdit = CAI_MakeEdit(
		"CAIEditHotseatPlayer_Name",
		Controls.HotseatPlayerNameLabel,
		Controls.HotseatPlayerNameEntry,
		OnPlayerNameChanged,
		false
	)
	m_CAI_PasswordEdit = CAI_MakeEdit(
		"CAIEditHotseatPlayer_Password",
		Controls.HotseatPasswordLabel,
		Controls.HotseatPasswordEntry,
		function()
			UpdateHotseatPassword()
		end,
		true
	)
	m_CAI_PasswordVerifyEdit = CAI_MakeEdit(
		"CAIEditHotseatPlayer_PasswordVerify",
		Controls.HotseatPasswordVerifyLabel,
		Controls.HotseatPasswordVerifyEntry,
		function()
			UpdateHotseatPassword()
		end,
		true
	)
	CAI_SyncDialogFromControls()

	local cancelButton = mgr:CreateWidget("CAIEditHotseatPlayer_Cancel", "Button", {
		Label = function()
			return CAI_GetControlText(Controls.CancelButton)
		end,
		Tooltip = function()
			return CAI_GetControlTooltip(Controls.CancelButton)
		end,
		FocusKey = "action:cancel",
	})
	cancelButton:SetFocusSound("Main_Menu_Mouse_Over")
	cancelButton:On("activate", function()
		Controls.CancelButton:DoLeftClick()
	end)

	m_CAI_AcceptButton = mgr:CreateWidget("CAIEditHotseatPlayer_Accept", "Button", {
		Label = function()
			return CAI_GetControlText(Controls.AcceptButton)
		end,
		Tooltip = CAI_GetAcceptTooltip,
		DisabledPredicate = function()
			return Controls.AcceptButton:IsDisabled()
		end,
		FocusKey = "action:accept",
	})
	m_CAI_AcceptButton:SetFocusSound("Main_Menu_Mouse_Over")
	m_CAI_AcceptButton:On("activate", function()
		Controls.AcceptButton:DoLeftClick()
	end)

	m_CAI_Dialog = mgr.WidgetHelpers.MakeGeneralDialog(
		function()
			return CAI_GetControlText(Controls.DialogTitle)
		end,
		{ cancelButton, m_CAI_AcceptButton },
		{ m_CAI_NameEdit, m_CAI_PasswordEdit, m_CAI_PasswordVerifyEdit },
		2
	)
	Controls.HotseatPlayerNameEntry:DropFocus()
	mgr:Push(m_CAI_Dialog, { priority = PopupPriority.Current, focus = m_CAI_NameEdit })
end

Realize = WrapFunc(Realize, function(orig, ...)
	local result = orig(...)
	m_CAI_HasValidData = g_playerID ~= -1
	if not ContextPtr:IsHidden() and m_CAI_HasValidData then
		if m_CAI_Dialog then
			CAI_SyncDialogFromControls()
		else
			CAI_PushDialog()
		end
	end
	return result
end)

Initialize = WrapFunc(Initialize, function(orig)
	orig()
	ContextPtr:SetShowHideHandler(function(bIsHide, bIsInit)
		if bIsHide then
			CAI_RemoveDialog()
		end
	end)
	ContextPtr:SetInputHandler(function(input)
		if mgr and m_CAI_Dialog and mgr:GetTop() == m_CAI_Dialog and mgr:HandleInput(input) then
			return true
		end
		return OnInputHandler(input:GetMessageType(), input:GetKey(), nil)
	end, true)
end)
--#End of accessibility integration
Initialize();
