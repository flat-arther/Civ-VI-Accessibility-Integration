include("InputSupport");

-- ===========================================================================
--	Action Hotkeys
-- ===========================================================================

local m_actionHotkeyAccept		:number = Input.GetActionId("Accept");
local m_actionHotkeyAcceptAlt	:number = Input.GetActionId("AcceptAlt");

local NO_ACCEPT_TIMER			:number = -1;									-- accept timer not running value.
local ACCEPT_DELAY				:number = UI.IsFinalRelease() and 5 or 0.1;		-- Delay times (release and debug) before accept button is visible and auto-accept is checked.
local m_acceptDelayTimer		:number = NO_ACCEPT_TIMER;						-- Time remaining before accept button should be shown.


-- ===========================================================================
--	Accept EULA
-- ===========================================================================
-- savedAccept (optional) - Is this accept action because the player accepted this version previously?  Assumes false if nil.
function AcceptEULA( savedAccept : boolean )
	Controls.CopyrightAccept:SetHide( true );
	Events.UserAcceptsEULA();	

	if(savedAccept == nil or not savedAccept) then
		-- We just accepted the copyright notice for the first time for this version.
		local currentVersion = UI.GetAppVersion();
		Options.SetUserOption("Interface", "CopyrightAccept", currentVersion);
		Options.SaveOptions();
	end
end


-- ===========================================================================
--	Context Functions
-- ===========================================================================
function OnShow()
	-- Wait a small amount of time before presenting.  This is a legal requirement for our third party software logos.
	Controls.CopyrightAccept:SetHide( true );

	m_acceptDelayTimer = ACCEPT_DELAY;
	ContextPtr:SetUpdate( OnUpdateDelay );
end

-- ===========================================================================
function OnUpdateDelay(fDTime)
	if mgr ~= nil then
		mgr:OnUpdate()
	end

	if(m_acceptDelayTimer ~= NO_ACCEPT_TIMER) then
		m_acceptDelayTimer = m_acceptDelayTimer - fDTime;
		if(m_acceptDelayTimer < 0) then
			m_acceptDelayTimer = NO_ACCEPT_TIMER;

			Controls.CopyrightAccept:SetHide( false );
			local currentVersion = UI.GetAppVersion();
			local acceptedVersion = Options.GetUserOption("Interface", "CopyrightAccept");
			if(currentVersion == acceptedVersion and currentVersion ~= "") then
				AcceptEULA(true);
			end
		end
	end
end


-- ===========================================================================
--	Hotkey
-- ===========================================================================
function OnInputActionTriggered( actionId:number )
	if	actionId == m_actionHotkeyAccept or 
		actionId == m_actionHotkeyAcceptAlt then		
			AcceptEULA();
	end
end

-- ===========================================================================
--	UI Callback
-- ===========================================================================
function OnAccept()
	AcceptEULA();    
end

-- ===========================================================================
function OnRequestClose()
    Events.UserConfirmedClose();
end

-- ===========================================================================
function Startup()
	Input.SetActiveContext( InputContext.Startup );

    Controls.CopyrightAccept:RegisterCallback( Mouse.eLClick, OnAccept );
    Controls.CopyrightAccept:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);

	Controls.CopyrightAccept:SetHide( Automation.IsActive() );
    Controls.CopyrightText:SetHide(false);

	Events.InputActionTriggered.Add( OnInputActionTriggered );
    Events.UserRequestClose.Add( OnRequestClose );


end
--#Accessibility integration
include ("caiUtils")
include("CAIUIScreenManager")
local mgr             = ExposedMembers.CAI_UIManager

local m_eulaPanel = nil

local function BuildEulaPanel()
	if m_eulaPanel then return end

	m_eulaPanel = mgr:CreateWidget("CAIIntro_EulaPanel", "Panel", {
		Label = function() return Locale.Lookup("LOC_CAI_EULA_PANEL") end,
	})

	local edit = mgr:CreateWidget("CAIIntro_EulaText", "EditBox", {
		Label    = function() return Locale.Lookup("LOC_CAI_EULA_TEXT") end,
		ReadOnly = true,
		AlwaysEdit = true,
		HighlightOnEdit = false,
	})
	edit:SetText(Controls.CopyrightText:GetText():gsub("%.%s", "[NEWLINE]"), true)
	m_eulaPanel:AddChild(edit)

	local acceptBtn = mgr:CreateWidget("CAIIntro_AcceptBtn", "Button", {
		Label = function() return Controls.CopyrightAccept:GetText() end,
	})
	acceptBtn:SetFocusSound("Main_Menu_Mouse_Over")
	acceptBtn:On("activate", function()
		OnAccept()
	end)
	m_eulaPanel:AddChild(acceptBtn)

	m_eulaPanel:AddInputBinding({
		Key = Keys.VK_RETURN,
		MSG = KeyEvents.KeyUp,
		Description = "LOC_CAI_KB_ACCEPT",
		Action = function()
			OnAccept()
			return true
		end,
	})
end


OnShow = WrapFunc(OnShow, function(orig)
	orig()
	BuildEulaPanel()
	mgr:Push(m_eulaPanel)
end)

function OnHandleInput(pInputStruct)
	if mgr then
		return mgr:HandleInput(pInputStruct)
	end
end
-- This context does not have a vanilla 'OnShutdown' function, so we add one to kill the UI manager
function OnShutdown()
	mgr:ShutDown(false, true)
end
ContextPtr:SetShutdown( OnShutdown );
ContextPtr:SetInputHandler(OnHandleInput, true)

--#End of accessibility integration
	-- Manually call OnShow because SetActiveContext does not appear to call it normally.
	OnShow();
