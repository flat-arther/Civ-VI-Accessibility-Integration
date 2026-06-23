-- ===========================================================================
--	Copyright 2020, Firaxis Games
--	Screen used when transitioning between App states, initially created to
--	immediately raise a message when player clicks the "play now" button.
-- ===========================================================================


local m_who:string = "nobody";		-- Who raised the transition w/ default.


-- ===========================================================================
--	UI Callback
--	Occurs when state has been raised.
-- ===========================================================================
function OnRefresh_SignalRaised()
	ContextPtr:ClearRefreshHandler()
	LuaEvents.StateTransition_SignalRaised( m_who );
end

-- ===========================================================================
--	Raise up the state transition, 
--	who		Some ID, like the context name, that identifies who raised the transition.
--	message (optional) A localized message to display (if nil, shows default pause message)
-- ===========================================================================
function OnRaise( who:string, message:string )
	if UIManager:IsModal(ContextPtr) then
		UI.DataError("Attempt to raise StateTransition by '" .. who .. "' but already raised by '" .. m_who.."'");
		return;
	end
	
	m_who = who;	-- track last context to raise
	if message == nil or message == "" then
		message = Locale.ToUpper(Locale.Lookup("LOC_LOADING_PLEASE_WAIT"));
	end
	Controls.Message:SetText( message );
	UIManager:PushModal( ContextPtr );
	TTManager:ClearCurrent();
	
	ContextPtr:RequestRefresh();
end

-- ===========================================================================
--	who, is requesting the state transition to be lowered
-- ===========================================================================
function OnLower( who:string )
	if UIManager:IsModal(ContextPtr)==false then
		UI.DataError("Attempt to lower statetransition by '" .. who .. "' but already lowered by '"..m_who.."'");
		return;
	end
	m_who = who;	-- track last context to lower
	ContextPtr:SetHide( true );
	UIManager:PopModal( ContextPtr );
end


-- ===========================================================================
function OnShutdown()
	LuaEvents.MainMenu_PlayCiv6Started.Remove( OnRaise );
	LuaEvents.Lower_State_Transition.Remove( OnLower );
end

-- ===========================================================================
function Initialize()
	ContextPtr:SetRefreshHandler( OnRefresh_SignalRaised );
	ContextPtr:SetShutdown( OnShutdown );
	LuaEvents.Raise_State_Transition.Add( OnRaise );
	LuaEvents.Lower_State_Transition.Add( OnLower );
end
--#Accessibility integration
include("caiUtils")
OnRaise = WrapFunc(OnRaise, function(orig, who, message)
	orig(who, message)
	local txt = Controls.Message:GetText()
	if txt then Speak(txt) end
end)
--#End of accessibility integration
Initialize();
