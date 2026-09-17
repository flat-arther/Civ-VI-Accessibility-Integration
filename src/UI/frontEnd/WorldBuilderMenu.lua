
-- ===========================================================================
-- Button Handlers
-- ===========================================================================
function OnImportWorldBuilderMap()
	UIManager:DequeuePopup( ContextPtr );	-- make Back from the load screen go directly to the main menu

	GameConfiguration.SetToDefaults();
	GameConfiguration.SetWorldBuilderEditor(true);
	MapConfiguration.SetScript("WBImport.lua");
	local advancedSetup = ContextPtr:LookUpControl( "/FrontEnd/MainMenu/AdvancedSetup" );
	UIManager:QueuePopup(advancedSetup, PopupPriority.Current);
	Controls.SwitchPopup:SetHide(true);
end
Controls.WBAConfirmButton:RegisterCallback( Mouse.eLClick, OnImportWorldBuilderMap ); 
Controls.WBAConfirmButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);

function OnCancelImport()
	Controls.SwitchPopup:SetHide(true);

	GameConfiguration.SetWorldBuilderEditor(false);
	UIManager:DequeuePopup( ContextPtr );
end

Controls.WBACancelButton:RegisterCallback( Mouse.eLClick, OnCancelImport );
Controls.WBACancelButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);

-------------------------------------------------
-- Input Handler
-------------------------------------------------
function InputHandler( uiMsg, wParam, lParam )
	if uiMsg == KeyEvents.KeyUp then
		if wParam == Keys.VK_ESCAPE then
			OnCancelImport();
		end
	end
	return true;
end
ContextPtr:SetInputHandler( InputHandler );

-- ===========================================================================
function OnShow()
	Controls.SwitchPopup:SetHide(false);
end

ContextPtr:SetShowHandler( OnShow );
Controls.SwitchPopup:SetHide(false);

--#Accessibility integration
include("caiUtils")

local mgr = ExposedMembers.CAI_UIManager
local m_CAI_Dialog ---@type DialogWidget

local function CAI_RemoveDialog()
	if mgr and m_CAI_Dialog then
		mgr:RemoveFromStack(m_CAI_Dialog:GetId())
	end
	m_CAI_Dialog = nil
end

local function CAI_MakeButton(control, focusKey)
	local button = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWorldBuilderMenuButton"), "Button", {
		Label = function() return control:GetText() or "" end,
		Tooltip = function() return control:GetToolTipString() or "" end,
		DisabledPredicate = function() return control:IsDisabled() end,
		FocusKey = focusKey,
	})
	button:SetFocusSound("Main_Menu_Mouse_Over")
	button:On("activate", function()
		control:DoLeftClick()
	end)
	return button
end

local function CAI_PushDialog()
	if not mgr then return end
	CAI_RemoveDialog()

	local message = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWorldBuilderMenuMessage"), "StaticText", {
		Label = function() return Locale.Lookup("LOC_WORLDBUILDER_IMPORT_UNSUPPORTED_TEXT") end,
		FocusKey = "world-builder-import:message",
	})
	local continueButton = CAI_MakeButton(Controls.WBAConfirmButton, "world-builder-import:continue")
	local cancelButton = CAI_MakeButton(Controls.WBACancelButton, "world-builder-import:cancel")

	m_CAI_Dialog = mgr.WidgetHelpers.MakeGeneralDialog(
		function() return Controls.ModalScreenTitle:GetText() or "" end,
		{ continueButton, cancelButton },
		{ message },
		1
	)
	if m_CAI_Dialog then
		mgr:Push(m_CAI_Dialog, {
			priority = PopupPriority.Current,
			focus = message,
		})
	end
end

OnImportWorldBuilderMap = WrapFunc(OnImportWorldBuilderMap, function(orig)
	CAI_RemoveDialog()
	return orig()
end)

OnCancelImport = WrapFunc(OnCancelImport, function(orig)
	CAI_RemoveDialog()
	return orig()
end)

OnShow = WrapFunc(OnShow, function(orig)
	orig()
	CAI_PushDialog()
end)

Controls.WBAConfirmButton:RegisterCallback(Mouse.eLClick, OnImportWorldBuilderMap)
Controls.WBACancelButton:RegisterCallback(Mouse.eLClick, OnCancelImport)
ContextPtr:SetShowHandler(OnShow)
ContextPtr:SetInputHandler(function(input)
	if mgr and m_CAI_Dialog and mgr:GetTop() == m_CAI_Dialog and mgr:HandleInput(input) then
		return true
	end
	return InputHandler(input:GetMessageType(), input:GetKey(), nil)
end, true)
--#End of accessibility integration
