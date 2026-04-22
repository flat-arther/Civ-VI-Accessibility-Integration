include("InstanceManager");

-- ===========================================================================
--	PopupDialog
--
--	Allows for a "Are You Sure" or other confirmation dialog.
--	This logic can be used with a custom dialog
--
--  PopupDialog creates a dialog inline to your context
--  PopupDialogInGame creates a dialog within the context of InGame
--  The following two examples use PopupDialog, but the same logic applies for PopupDialogInGame  
--
--	Example 1:
--		-- Standard Ok/Cancel dialog
--		local m_kPopupDialog = PopupDialog:new( "MyOwnPopupDialog" )
--		m_kPopupDialog:ShowOkCancelDialog("This will just dismiss", OnOkay, OnCancel);
--
--	Example 2:
--		-- Build a super custom styled dialog
--		local kDialog:table = PopupDialog:new( "MyCustomPopupDialog" );
--		kDialog:AddTitle("Sexy Dialog Title");
--		kDialog:AddText("Press something?");
--		kDialog:AddButton("Something", function() print("Something pressed"); end, "String To Trigger This From Lua" );
--		kDialog:Open();
--
-- ===========================================================================

-- ===========================================================================
--	Class Table
-- ===========================================================================
-- Manages PopupDialog controls defined in PopupDialog.xml
PopupDialog = {
	ID				= "",
	Controls		= nil,
	AnimsOnOpen		= {},
	PopupControls	= {}
}

-- Helper class to interface with InGamePopup context
PopupDialogInGame = {
	ID			= "",
	m_options	= {}
}


-- ===========================================================================
--	Class Constants
-- ===========================================================================
PopupDialog.TOP_CONTROL_ROW				= "Row";
PopupDialog.TOP_CONTROL_TEXT			= "Text";
PopupDialog.TOP_CONTROL_BUTTON			= "Button";
PopupDialog.TOP_CONTROL_COUNTDOWN		= "Anim";
PopupDialog.TOP_CONTROL_CHECK			= "Check";
PopupDialog.TOP_CONTROL_EDITBOX			= "EditBoxRoot";

PopupDialog.DEFAULT_INSTANCE_ROW		= "PopupRowInstance";
PopupDialog.DEFAULT_INSTANCE_TEXT		= "PopupTextInstance";
PopupDialog.DEFAULT_INSTANCE_BUTTON		= "PopupButtonInstance";
PopupDialog.DEFAULT_INSTANCE_COUNTDOWN	= "PopupCountDownInstance";
PopupDialog.DEFAULT_INSTANCE_CHECK		= "PopupCheckboxInstance";
PopupDialog.DEFAULT_INSTANCE_EDITBOX	= "PopupEditboxInstance";

-- Strings for doing PopupDialog:ActivateCommand on default popups
PopupDialog.COMMAND_CANCEL				= "_CMD_CANCEL";
PopupDialog.COMMAND_CONFIRM				= "_CMD_CONFIRM";
PopupDialog.COMMAND_DEFAULT				= "_CMD_DEFAULT";

-- ===========================================================================
--	PopupDialog Constructor
--
--	ARGS:	id							Idenitifer of the popup dialog
--			myControls (optional)		A table containing at PopupRoot, PopupStack, PopupTitle, and other popup related controls
--
--	RETURNS: PopupDialog object
-- ===========================================================================
function PopupDialog:new( id:string, myControls:table )
	
	self.ID				= id;
	self.Controls		= myControls or Controls;
	self.AnimsOnOpen	= {};
	self.PopupControls	= {};

	-- Set default size, instance names and animation behavior
	self:SetInstanceNames();
	self:SetOpenAnimationControls(Controls.PopupAlphaIn, Controls.PopupSlideIn);
	self:SetSize(400,200);
	
	return self;
end

-- ===========================================================================
--	Utility Helper
--	Create a dialog with an "OK" button.
-- ===========================================================================
function PopupDialog:ShowOkDialog( text:string, callbackOk:ifunction )
	self:Reset();
	self:AddTitle( "" );
	self:AddText( text );
	self:AddButton( Locale.Lookup("LOC_OK"), callbackOk, PopupDialog.COMMAND_CONFIRM );
	self:Open();
end

-- ===========================================================================
--	Utility Helper
--	Create a dialog with an "OK" and "Cancel" buttons.
-- ===========================================================================
function PopupDialog:ShowOkCancelDialog( text:string, callbackOk:ifunction, callbackCancel:ifunction )
	self:Reset();
	self:AddText( text );
	self:AddButton( Locale.Lookup("LOC_OK"), callbackOk, PopupDialog.COMMAND_CONFIRM );
	self:AddButton( Locale.Lookup("LOC_CANCEL"), callbackCancel, PopupDialog.COMMAND_CANCEL );
	self:Open();
end

-- ===========================================================================
--	Utility Helper
--	Create a dialog with an "Yes" and "No" buttons.
-- ===========================================================================
function PopupDialog:ShowYesNoDialog( text:string, callbackOk:ifunction, callbackCancel:ifunction )
	self:Reset();
	self:AddText( text );
	self:AddButton( Locale.Lookup("LOC_YES"), callbackOk, PopupDialog.COMMAND_CONFIRM );
	self:AddButton( Locale.Lookup("LOC_NO"), callbackCancel, PopupDialog.COMMAND_CANCEL );
	self:Open();
end

-- ===========================================================================
--	Add a title to the dialog box
--		ARGS:	title - the pre-localized string to assign to the title control
--				optionalTitleControl - if the user did not already set up the 
--					initially in the constructor, it can be specified here.
-- ===========================================================================
function PopupDialog:AddTitle(title:string)
	
	if self:IsOpen() then
		UI.DataError("Called AddTitle on an already opened PopupDialog: " .. self.ID);
	end

	if optionalTitleControl then
		self.Controls.PopupTitle = optionalTitleControl;
	end

	if self.Controls.PopupTitle then
		self.Controls.PopupTitle:SetText( title );
	else
		UI.DataError("A title was set without first having a control specified.  Try including the title control as a 2nd argument to AddTitle");
	end
end

-- ===========================================================================
--	The prompt displayed
-- ===========================================================================
function PopupDialog:AddText( text:string )
	
	if self:IsOpen() then
		UI.DataError("Called AddText on an already opened PopupDialog: " .. self.ID);
	end

	self.RowInstance = nil;	-- Reset for first/new row of buttons later on.

	local pTextControl:table = self.TextIM:GetInstance().GetTopControl();
	pTextControl:SetText( text );

	-- Add to ordered list for later layout (type, actual instance)
	table.insert(self.PopupControls, { Type = "Text", Control = pTextControl });
end

-- ===========================================================================
--	Create a button
--	self						this popup dialog object
--	label						String to print on button
--	callback					function to call when pressed (or NIL to just close)
--	optionalActivatedCommand	some string that when matched will "virtually" press button
--	optionalToolTip				tooltip
--	optionalButtonInstanceName	instance name for the button control
-- ===========================================================================
function PopupDialog:AddButton( label:string, callback:ifunction, optionalActivateCommand:string, optionalToolTip:string, optionalButtonInstanceName: string )
	
	if self:IsOpen() then
		UI.DataError("Called AddButton on an already opened PopupDialog: " .. self.ID);
	end
			
	-- Build row instance manager if one doesn't exist.
	local pTopControl:table;
	if self.RowInstance then
		pTopControl = self.RowInstance[self.RowTopControlName];
	else
		self.RowInstance = self.RowStackIM:GetInstance();
		pTopControl = self.RowInstance[self.RowTopControlName];
		table.insert(self.PopupControls, { Type = "Row", Control = pTopControl }); -- Add to ordered list for later (type, actual instance)
	end

	local pInstance:table = {};
	local buttonInstanceName:string = optionalButtonInstanceName and optionalButtonInstanceName or PopupDialog.DEFAULT_INSTANCE_BUTTON;
	ContextPtr:BuildInstanceForControl(buttonInstanceName, pInstance, pTopControl);

	-- Ensure this is some type of button that can send callbacks.
	local pButtonControl:table = pInstance[self.ButtonTopControlName];
	if not pButtonControl.RegisterCallback then
		UI.DataError("Unable to AddButon("..label.." ...) because top item in instance isn't a Button, ColorBoxButton, or a GridButton type!");
		ContextPtr:DestroyChild(pInstance);
		return;
	end

	-- Set button label and callback with an injected "Close()"
	pButtonControl:SetText(label);

	-- Set button tooltip (if any)
	if not optionalToolTip then optionalToolTip = ""; end
	pButtonControl:SetToolTipString( optionalToolTip );

	-- Set the same mouseover button sound for all popup buttons
	pButtonControl:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);

	-- Wrap callback in local function so we can close the popup before trigerring the callback
	local closeAndCallback:ifunction = function() self:Close(); if callback then callback(); end end
	pButtonControl:RegisterCallback(Mouse.eLClick, closeAndCallback);

	-- Add button to popup controls table so we can match activate commands to button callbacks
	table.insert(self.PopupControls, { Type = "Button", Control = pButtonControl, Callback = closeAndCallback, Command = optionalActivateCommand });

	-- Recalculate size of button container
	pTopControl:CalculateSize();
end

-- ===========================================================================
--	Assumes instance has a top level control of <Anim> with a <Label> inside. 
function PopupDialog:AddCountDown(  startValue:number, callback:ifunction  )
	
	if self:IsOpen() then
		UI.DataError("Called AddCountDown on an already opened PopupDialog, ID: " .. self.ID);
	end

	self.RowInstance = nil;	-- Reset for first/new row of buttons later on.
	local pInstance:table = self.CountDownIM:GetInstance();

	-- If no callback; create an empty one; then ensure close is called.
	local closeAndCallback:ifunction = function() self:Close(); if callback then callback(); end end

	pInstance.Text:SetText( tostring(startValue) );
	pInstance.Anim:RegisterEndCallback( 
		function()
			local value:number = tonumber( pInstance.Text:GetText() );
			value = value - 1;
			if value < 0 then
                pInstance.Anim:ClearEndCallback();
				closeAndCallback();
			else
				pInstance.Text:SetText( tostring(value) );
				pInstance.Anim:SetToBeginning();
				pInstance.Anim:Play();
			end
		end
	);

	table.insert(self.PopupControls, { Type = "Count", Control = pInstance.Anim, Callback = closeAndCallback });
	pInstance.Anim:Play();	-- To be super correct, have open() scan controls and if anim exists THEN kick off playing.
end

-- ===========================================================================
--	Assumes instance has a top level control of <Anim> with a <Label> inside. 
function PopupDialog:AddCheckBox( label, checked, callback  )
	
	if self:IsOpen() then
		UI.DataError("Called AddCheckBox on an already opened PopupDialog, ID: " .. self.ID);
	end

	self.RowInstance = nil;	-- Reset for first/new row of buttons later on.
	local pInstance = self.CheckBoxIM:GetInstance();
	if(pInstance.Check.GetTextButton) then
		pInstance.Check:GetTextButton():SetText( label );
	elseif(pInstance.Check.SetText) then
		pInstance.Check:SetText( label );
	end

	pInstance.Check:SetCheck(checked == true);
	
	if(callback) then
		-- Use custom wrapper function to include checked state in function arguments.
		pInstance.Check:RegisterCallback(Mouse.eLClick, function() callback(pInstance.Check:IsChecked()); end); 
	else
		pInstance.Check:ClearCallback(Mouse.eLClick);
	end
	
	table.insert(self.PopupControls, { Type = "Check", Control = pInstance.Check, Callback = callback });
end

-- ===========================================================================
--	Assumes instance has a root control called "EditBoxRoot", <Label> named "EditLabel", and a <EditBox> named "EditBox".
--	optionalActivatedCommand	A string that when matched will "virtually" call the editbox commit callback.
function PopupDialog:AddEditBox( label:string, commitCallback:ifunction, stringChangedCallback:ifunction, optionalActivateCommand:string )
	
	if self:IsOpen() then
		UI.DataError("Called AddEditBox on an already opened PopupDialog, ID: " .. self.ID);
	end

	self.RowInstance = nil;	-- Reset for first/new row of buttons later on.
	local pInstance = self.EditBoxIM:GetInstance();
	if(pInstance.EditLabel) then
		pInstance.EditLabel:SetText( label );
	end

	pInstance.EditBox:ClearString();

	if(commitCallback) then
		-- Use custom wrapper function to include editbox string in function arguments.
		pInstance.EditBox:RegisterCommitCallback(commitCallback); 
	end

	if(stringChangedCallback) then
		pInstance.EditBox:RegisterStringChangedCallback(stringChangedCallback); 
	end
	
	table.insert(self.PopupControls, { Type = "EditBox", Control = pInstance.EditBox, Command = optionalActivateCommand });
end

-- ===========================================================================
-- Returns the edit box text for the first edit box found associated with the command string.
function PopupDialog:GetEditBoxText( command:string )
	for _,uiControl in ipairs(self.PopupControls) do
		if(uiControl.Type == "EditBox" and uiControl.Command == command) then
			return uiControl.Control.GetText();
		end
	end
	return nil;
end

-- ===========================================================================
function PopupDialog:SetSize( width:number, height:number )
	if self:IsOpen() then
		UI.DataError("Called SetSize on an already opened PopupDialog, ID: " .. self.ID);
	end
	self.Controls.PopupStack:SetSizeVal(width,height);
end

-- ===========================================================================
function PopupDialog:Open( optionalID:string )
	
	if self:IsOpen() then
		local ID:string = optionalID and optionalID or self.ID;
		UI.DataError("Attempt to open a popup dialog that is already open. ID: '" .. ID .. "'");
	end
	
	self.Controls.PopupRoot:SetHide(false);

	-- If animation controls are set to play on open, now is the time...
	for _,pAnimationControl in ipairs( self.AnimsOnOpen ) do
		pAnimationControl:SetToBeginning();
		pAnimationControl:Play();
	end

	self.Controls.PopupStack:CalculateSize();
end

-- ===========================================================================
function PopupDialog:Close()
	self.Controls.PopupRoot:SetHide(true);
	self:Reset();
end

-- ===========================================================================
function PopupDialog:Reset()
	
	if self.Controls.PopupTitle then
		self.Controls.PopupTitle:SetText(Locale.ToUpper(Locale.Lookup("LOC_CONFIRM_CHOICE")));
	end

	for _,value in ipairs(self.PopupControls) do
		local type:string = value.Type;
		if value.Type == "Row" then
			value.Control:DestroyAllChildren();
		end
		if value.Type == "Count" then
			value.Control:Stop();
			value.Control:SetToBeginning();
		end
	end

	self.TextIM:ResetInstances();
	self.RowStackIM:ResetInstances();
	if self.CountDownIM then
		self.CountDownIM:ResetInstances();
	end

	if(self.CheckBoxIM) then
		self.CheckBoxIM:ResetInstances();
	end

	if(self.EditBoxIM) then
		self.EditBoxIM:ResetInstances();
	end

	self.Controls.PopupStack:CalculateSize();

	self.RowInstance = nil;
	self.PopupControls = {};
end

-- ===========================================================================
function PopupDialog:IsOpen()
	return self.Controls.PopupRoot:IsVisible();
end

-- ===========================================================================
function PopupDialog:ActivateCommand( command:string )
	for _,uiControl in ipairs(self.PopupControls) do
		if uiControl.Type == "Button" and uiControl.Command == command then
			uiControl.Callback();
			return true;
		end
	end
	return false;
end

-- ===========================================================================
-- These next functions allow us to alter look and animation of Popup Dialogs.
-- ===========================================================================

-- ===========================================================================
--	Sets the name of the instance objects to be used when constructing pieces
--	for a popup dialog.
--
--	ARGS:	buttonInstanceName		Name of the instance to create for buttons.
--			buttonTopControlName	Name of the top control in the button instance.
--			textInstanceName		Name of the instance to create for text.
--			textTopControlName		Name of the top control in the text instance.
--			rowInstanceName			Name of the instance to create a row for buttons
--			rowTopControlName		Name of the top control in the row instance.
--			editboxInstanceName		Name of the instance to create for editboxes.
-- ===========================================================================
function PopupDialog:SetInstanceNames( buttonInstanceName:string, buttonTopControlName:string, textInstanceName:string, textTopControlName:string, rowInstanceName:string, rowTopControlName:string, countDownInstanceName:string, countDownTopControlName:string, checkboxInstanceName:string, editboxInstanceName:string)
	
	-- Look for default named items if explicit ones aren't passed in.
	self.RowTopControlName = rowTopControlName and rowTopControlName or PopupDialog.TOP_CONTROL_ROW;
	self.ButtonTopControlName = buttonTopControlName and buttonTopControlName or PopupDialog.TOP_CONTROL_BUTTON;

	-- We don't need to access these later, so it's ok to override the function parameters with default values.
	textTopControlName = textTopControlName and textTopControlName or PopupDialog.TOP_CONTROL_TEXT;
	countDownTopControlName = countDownTopControlName and countDownTopControlName or PopupDialog.TOP_CONTROL_COUNTDOWN;

	-- Setup instance managers with the newly updated instance names.
	self.TextIM = InstanceManager:new(textInstanceName and textInstanceName or PopupDialog.DEFAULT_INSTANCE_TEXT, textTopControlName, self.Controls.PopupStack);
	self.RowStackIM = InstanceManager:new(rowInstanceName and rowInstanceName or PopupDialog.DEFAULT_INSTANCE_ROW, self.RowTopControlName, self.Controls.PopupStack);
	self.CountDownIM = InstanceManager:new(countDownInstanceName and countDownInstanceName or PopupDialog.DEFAULT_INSTANCE_COUNTDOWN, countDownTopControlName, self.Controls.PopupStack);
	self.CheckBoxIM = InstanceManager:new(checkboxInstanceName and checkboxInstanceName or PopupDialog.DEFAULT_INSTANCE_CHECK, PopupDialog.TOP_CONTROL_CHECK, self.Controls.PopupStack);
	self.EditBoxIM = InstanceManager:new(editboxInstanceName and editboxInstanceName or PopupDialog.DEFAULT_INSTANCE_EDITBOX, PopupDialog.TOP_CONTROL_EDITBOX, self.Controls.PopupStack);
end

-- ===========================================================================
--	Animation controls to play when a dialog is opened.
--	ARGS:	N# of animation controls to play.
-- ===========================================================================
function PopupDialog:SetOpenAnimationControls( ... )
	for i,pControl in ipairs(arg) do
		if pControl and pControl.Play then
			table.insert(self.AnimsOnOpen, pControl );
		elseif pControl then
			UI.DataError("Cannot add control '"..tostring(pControl:GetID()).."' to play animation on generic dialog open; no play() function.");
		end
	end
end




-- ===========================================================================
--	Interfaces with the LUA context that is part of Ingame.
--
--	It is essentially a helper that:
--		1) builds the layout of the popup; storing details in table
--		2) sends daya to InGamePopup.lua via a LuaEvent
--
--	For customized popups, create them in XML and use PopupDialog instead.
--
-- ===========================================================================
function PopupDialogInGame:new( id:string )	
	self.ID			= id;
	self.m_options	= {};
	return self;
end

-- ===========================================================================
function PopupDialogInGame:AddText( message:string )
	table.insert(self.m_options, { Type = "Text", Content = message });
end

-- ===========================================================================
--	 Can only be one of these; if more than one is set, last one wins.
-- ===========================================================================
function PopupDialogInGame:AddTitle( message:string )
	table.insert(self.m_options, { Type = "Title", Content = message });
end

-- ===========================================================================
-- Adds a button whose callback will only be triggered by the button being clicked.
-- ===========================================================================
function PopupDialogInGame:AddCustomButton( label:string, callback:ifunction )
	table.insert(self.m_options, {Type="Button", Content=label, Callback=callback});
end
-- ===========================================================================
-- Adds a button whose callback can be triggered by click or by pressing 'escape'
-- ===========================================================================
function PopupDialogInGame:AddCancelButton( label:string, callback:ifunction )
	table.insert(self.m_options, {Type="Button", Content=label, Callback=callback, CommandString=PopupDialog.COMMAND_CANCEL});
end
-- ===========================================================================
-- Adds a button whose callback can be triggered by click or by pressing 'enter'
-- ===========================================================================
function PopupDialogInGame:AddConfirmButton( label:string, callback:ifunction )
	table.insert(self.m_options, {Type="Button", Content=label, Callback=callback, CommandString=PopupDialog.COMMAND_CONFIRM});
end
-- ===========================================================================
-- Adds a button whose callback can be triggered by click or by pressing 'enter' or 'escape'.
-- Will only be triggered by keypress if there isn't a more specific button to handle it.
-- ===========================================================================
function PopupDialogInGame:AddDefaultButton( label:string, callback:ifunction )
	table.insert(self.m_options, {Type="Button", Content=label, Callback=callback, CommandString=PopupDialog.COMMAND_DEFAULT});
end
-- ===========================================================================
function PopupDialogInGame:AddCountDown( startValue:number, callback:ifunction )
	table.insert(self.m_options, { Type = "Count", Content = startValue, Callback = callback });
end

-- ===========================================================================
function PopupDialogInGame:Open()
	LuaEvents.OnRaisePopupInGame(self.ID, self.m_options);
	self.m_options = {};
end

-- ===========================================================================
--	Utility Helper
--	Create a dialog with an "OK" button.
-- ===========================================================================
function PopupDialogInGame:ShowOkDialog( text:string, callbackOk:ifunction )
	self.m_options = {};
	self:AddTitle( "" );
	self:AddText( text );
	 -- ifunction is an acknowledgement of player seeing this, thus the callback should be hit on esc and enter.
	self:AddDefaultButton( Locale.Lookup("LOC_OK"), callbackOk );
	self:Open( self.ID );
end

-- ===========================================================================
--	Utility Helper
--	Create a dialog with an "OK" and "Cancel" buttons.
-- ===========================================================================
function PopupDialogInGame:ShowOkCancelDialog( text:string, callbackOk:ifunction, callbackCancel:ifunction )
	self.m_options = {};
	self:AddText( text );
	self:AddConfirmButton( Locale.Lookup("LOC_OK"), callbackOk );
	self:AddCancelButton( Locale.Lookup("LOC_CANCEL"), callbackCancel );
	self:Open( self.ID );
end

-- ===========================================================================
--	Utility Helper
--	Create a dialog with an "Yes" and "No" buttons.
-- ===========================================================================
function PopupDialogInGame:ShowYesNoDialog( text:string, callbackOk:ifunction, callbackCancel:ifunction )
	self.m_options = {};
	self:AddText( text );
	self:AddConfirmButton( Locale.Lookup("LOC_YES"), callbackOk );
	self:AddCancelButton( Locale.Lookup("LOC_NO"), callbackCancel );
	self:Open( self.ID );
end
--#Accessibility integration
include ("caiUtils")
local DialogWidget = nil ---@type UIWidget|nil
local mgr = ExposedMembers.CAI_UIManager
PopupDialog.Open = WrapFunc(PopupDialog.Open, function(orig, self, optionalID)
    orig(self, optionalID)
	if ContextPtr:IsHidden() then return end
    DialogWidget = nil
        DialogWidget = mgr.WidgetTemplateHelpers:CreatePopupDialog(self)
		if not DialogWidget then return end
    if not mgr:HasWidget(DialogWidget) then
        mgr:Push(DialogWidget)
    end
end)


PopupDialog.Close = WrapFunc(PopupDialog.Close, function(orig, self)
    orig(self)
    if mgr:GetTop() == DialogWidget then
        mgr:Pop()
    end
end)
--#End of accessibility integration
