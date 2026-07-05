-------------------------------------------------
-- PlayByCloud Notification Setup Reminder
-------------------------------------------------

-------------------------------------------------
-------------------------------------------------
function OnOptions()
	LuaEvents.PBCNotifyRemind_ShowOptions();
	ContextPtr:SetHide(true);
end

-------------------------------------------------
-------------------------------------------------
function OnAccept()
	ContextPtr:SetHide(true);
end

-------------------------------------------------
-------------------------------------------------
function OnDoNotRemindToggled()
	local newCheckState = Controls.DoNotRemindCheckbox:IsChecked();
	-- Checked means do not show the reminder popup in the future.
	if (newCheckState) then
		Options.SetUserOption("Interface", "PlayByCloudNotifyRemind", 0);
	else
		Options.SetUserOption("Interface", "PlayByCloudNotifyRemind", 1);
	end
	Options.SaveOptions();
end

----------------------------------------------------------------
-- Input processing
----------------------------------------------------------------
function InputHandler(uiMsg, wParam, lParam)
	if uiMsg == KeyEvents.KeyUp then
		if wParam == Keys.VK_ESCAPE then
			OnAccept();
		end
		if wParam == Keys.VK_RETURN then
			OnAccept();
		end
	end
	return true;
end

-------------------------------------------------
-------------------------------------------------
function ShowHideHandler(bIsHide, bIsInit)
	if (not bIsHide) then
	end
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function GetPBCRemindText()
	if (Network.GetNetworkPlatform() == NetworkPlatform.NETWORK_PLATFORM_EOS) then
		return Locale.Lookup("LOC_EPIC_PBC_OVERVIEW_DESC");
	end

	return Locale.Lookup("LOC_PBC_OVERVIEW_DESC");
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function Initialize()
	ContextPtr:SetInputHandler(InputHandler);
	ContextPtr:SetShowHideHandler(ShowHideHandler);

	Controls.AcceptButton:RegisterCallback(Mouse.eLClick, OnAccept);
	Controls.OptionsButton:RegisterCallback(Mouse.eLClick, OnOptions);
	Controls.DoNotRemindCheckbox:RegisterCheckHandler(OnDoNotRemindToggled);

	Controls.RemindText:SetText(GetPBCRemindText());
end

--#Accessibility integration
include("caiUtils")

local mgr = ExposedMembers.CAI_UIManager

local m_CAI_Dialog = nil

local function CAI_GetControlText(control)
	if control and control.GetText then
		return control:GetText() or ""
	end
	return ""
end

local function CAI_RemoveDialog()
	if not mgr or not m_CAI_Dialog then
		return
	end
	mgr:RemoveFromStack(m_CAI_Dialog:GetId())
	m_CAI_Dialog = nil
end

local function CAI_BuildDialog()
	local remindText = mgr:CreateWidget(mgr:GenerateWidgetId("CAIPBCNotifyRemindText"), "StaticText", {
		Label = function()
			return CAI_GetControlText(Controls.RemindText)
		end,
		FocusKey = "remind:text",
	})

	local doNotRemind = mgr:CreateWidget(mgr:GenerateWidgetId("CAIPBCNotifyRemindCheckbox"), "Checkbox", {
		Label = function()
			return Controls.DoNotRemindCheckbox:GetToolTipString() or ""
		end,
		FocusKey = "remind:checkbox",
	})
	doNotRemind:SetChecked(Controls.DoNotRemindCheckbox:IsChecked(), true)
	doNotRemind:SetValueSetter(function(_, value)
		if Controls.DoNotRemindCheckbox:IsChecked() ~= value then
			Controls.DoNotRemindCheckbox:DoLeftClick()
		end
	end)

	local optionsButton = mgr:CreateWidget(mgr:GenerateWidgetId("CAIPBCNotifyRemindOptions"), "Button", {
		Label = function()
			return CAI_GetControlText(Controls.OptionsButton)
		end,
		FocusKey = "remind:options",
	})
	optionsButton:On("activate", function()
		Controls.OptionsButton:DoLeftClick()
	end)

	local acceptButton = mgr:CreateWidget(mgr:GenerateWidgetId("CAIPBCNotifyRemindAccept"), "Button", {
		Label = function()
			return CAI_GetControlText(Controls.AcceptButton)
		end,
		FocusKey = "remind:accept",
	})
	acceptButton:On("activate", function()
		Controls.AcceptButton:DoLeftClick()
	end)

	m_CAI_Dialog = mgr.WidgetHelpers.MakeGeneralDialog(
		function()
			return CAI_GetControlText(Controls.RemindTitle)
		end,
		{ optionsButton, acceptButton },
		{ remindText, doNotRemind },
		2
	)
end

local function CAI_PushDialog()
	if not mgr or ContextPtr:IsHidden() then
		return
	end
	CAI_RemoveDialog()
	CAI_BuildDialog()
	if not m_CAI_Dialog then
		return
	end
	mgr:Push(m_CAI_Dialog, { priority = PopupPriority.Default })
end

ShowHideHandler = WrapFunc(ShowHideHandler, function(orig, bIsHide, bIsInit)
	orig(bIsHide, bIsInit)
	if bIsHide then
		CAI_RemoveDialog()
	else
		CAI_PushDialog()
	end
end)

Initialize = WrapFunc(Initialize, function(orig)
	orig()
	ContextPtr:SetInputHandler(function(input)
		if mgr and m_CAI_Dialog and mgr:GetTop() == m_CAI_Dialog and mgr:HandleInput(input) then
			return true
		end
		if input:GetMessageType() == KeyEvents.KeyUp then
			if input:GetKey() == Keys.VK_ESCAPE then
				OnAccept()
				return true
			end
			if input:GetKey() == Keys.VK_RETURN then
				OnAccept()
				return true
			end
		end
		return true
	end, true)
end)
--#End of accessibility integration
Initialize();
