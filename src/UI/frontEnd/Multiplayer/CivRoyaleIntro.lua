-- Copyright 2019, Firaxis Games

-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local OPTIONS_SEEN_KEY	:string = "HasSeenCivRoyaleIntro";

local INTRO_ILLUSTRATIONS:table = {
	"CivRoyaleIntro_Diagram_1",
	"CivRoyaleIntro_Diagram_2",
	"CivRoyaleIntro_Diagram_3",
};

local NUM_PAGES = #INTRO_ILLUSTRATIONS;

local INTRO_DESCRIPTIONS:table = {
	"LOC_TUTORIAL_CIVROYALE_INTRO_BODY",
	"LOC_TUTORIAL_CIVROYALE_RED_DEATH_BODY",
	"LOC_TUTORIAL_CIVROYALE_UNITS_BODY",
};

local INTRO_DESCRIPTIONS_DETAILS:table = {
	"LOC_TUTORIAL_CIVROYALE_INTRO_DETAILS",
	"LOC_TUTORIAL_CIVROYALE_RED_DEATH_DETAILS",
	"LOC_TUTORIAL_CIVROYALE_UNITS_DETAILS",
};

local NEXT_BUTTON_TEXT = Locale.Lookup("LOC_CIVROYALE_INTRO_NEXT");
local PLAY_BUTTON_TEXT = Locale.Lookup("LOC_CIVROYALE_INTRO_PLAY");


-- ===========================================================================
--	MEMBERS
-- ===========================================================================
local m_PageIndex:number = 1;


-- ===========================================================================
function Realize()
	Controls.Illustration:SetTexture(INTRO_ILLUSTRATIONS[m_PageIndex]);
	Controls.Description:SetText(Locale.Lookup(INTRO_DESCRIPTIONS[m_PageIndex]));

	-- Show detail screens or hide box if we don't have any for this page
	if INTRO_DESCRIPTIONS_DETAILS[m_PageIndex] ~= "" then
		Controls.FrameDeco:SetHide(false);
		Controls.Description2:SetText(Locale.Lookup(INTRO_DESCRIPTIONS_DETAILS[m_PageIndex]));
	else
		Controls.FrameDeco:SetHide(true);
	end

	Controls.Next:SetText(m_PageIndex == NUM_PAGES and PLAY_BUTTON_TEXT or NEXT_BUTTON_TEXT);
	if (m_PageIndex == NUM_PAGES) then
		if (Network.IsInternetLobbyServiceAvailable()) then
			Controls.Next:SetDisabled(false);
			Controls.Next:SetToolTipString("");
		else
			Controls.Next:SetDisabled(true);
			if (Network.IsAgeRestricted()) then
				Controls.Next:SetToolTipString(Locale.Lookup("LOC_MULTIPLAYER_INTERNET_GAME_OFFLINE_AGE_TT"));
			else
				Controls.Next:SetToolTipString(Locale.Lookup("LOC_MULTIPLAYER_INTERNET_GAME_OFFLINE_TT"));
			end
		end
	else
		Controls.Next:SetDisabled(false);
		Controls.Next:SetToolTipString("");
	end

	Controls.Previous:SetHide(m_PageIndex == 1);
	Controls.ButtonStack:CalculateSize();
end


-- ===========================================================================
function OnShowFromMenu()

	-- Set CivRoyale specific textures in LUA (rather than XML) so they are not
	-- loaded if this fails to initialize due to the MOD being disabled.
	-- Other textures aren't an issue as they are either in the base game assets
	-- or are loaded dynamically by navigating to them.
	-- This must be done on every show as the player may have turned on/off the
	-- CivRoyale mod and if it started off, this will ensure the title is loaded.
	if IsCivRoyaleActive() then
		Controls.Logo:SetTexture("CivRoyaleIntro_Logo");
	end

	m_PageIndex = 1;
	Realize();
	UIManager:QueuePopup(ContextPtr, PopupPriority.Current);
end

-- ===========================================================================
function OnJoiningRoom_Showing()
	OnClose();
end

-- ===========================================================================
function OnClose()
	UIManager:DequeuePopup(ContextPtr);
	Options.SetUserOption("Tutorial", OPTIONS_SEEN_KEY, 1);
	Options.SaveOptions();
end

-- ===========================================================================
function OnNext()
	if m_PageIndex >= NUM_PAGES then
		if (Network.IsInternetLobbyServiceAvailable()) then
			LuaEvents.CivRoyaleIntro_StartMatchMaking();
		end

		-- Main Menu is going to start the match making process and then display the joining room screen.
		-- Next step is in OnJoiningRoom_Showing
	else
		m_PageIndex = math.min(m_PageIndex + 1, NUM_PAGES);
		Realize();
	end
end

-- ===========================================================================
function OnPrevious()
	m_PageIndex = math.max(1, m_PageIndex - 1);
	Realize();
end

-- ===========================================================================
function OnInput( pInputStruct:table )
	local key = pInputStruct:GetKey();
	local type = pInputStruct:GetMessageType();
	if type == KeyEvents.KeyUp and key == Keys.VK_ESCAPE then
		HideIfVisible();
	end
	return true; -- consume all input
end

-- ===========================================================================
function HideIfVisible()
	if ContextPtr:IsVisible() then
		OnClose();
	end
end

-- ===========================================================================
--	If the CivRoyale scenario active.
-- ===========================================================================
function IsCivRoyaleActive()
	local isActive:boolean  = Modding.IsModEnabled("F264EE10-F21B-4A9A-BBCD-D534E9843E90");
	return isActive;
end

-- ===========================================================================
function Initialize()

	ContextPtr:SetInputHandler( OnInput, true );

	Controls.Close:RegisterCallback(Mouse.eLClick, OnClose);
	Controls.Next:RegisterCallback(Mouse.eLClick, OnNext);
	Controls.Previous:RegisterCallback(Mouse.eLClick, OnPrevious);

	LuaEvents.MainMenu_ShowCivRoyaleIntro.Add(OnShowFromMenu);
	LuaEvents.JoiningRoom_Showing.Add(OnJoiningRoom_Showing);
	LuaEvents.InGameTopOptionsMenu_ShowExpansionIntro.Add( OnShowFromMenu );
	LuaEvents.DiplomacyActionView_HideIngameUI.Add( HideIfVisible );
end

--#Accessibility integration
include("caiUtils")

local mgr = ExposedMembers.CAI_UIManager
local m_CAI_Dialog = nil

local function CAI_RemoveDialog()
	if not mgr or not m_CAI_Dialog then return end
	mgr:RemoveFromStack(m_CAI_Dialog:GetId())
	m_CAI_Dialog = nil
end

local function CAI_MakeText(control)
	return mgr:CreateWidget(mgr:GenerateWidgetId("CAICivRoyaleIntroText"), "StaticText", {
		Label = function() return control:GetText() or "" end,
	})
end

local function CAI_MakeButton(control, focusKey)
	local button = mgr:CreateWidget(mgr:GenerateWidgetId("CAICivRoyaleIntroButton"), "Button", {
		Label = function() return control:GetText() or "" end,
		Tooltip = function() return control:GetToolTipString() or "" end,
		HiddenPredicate = function() return control:IsHidden() end,
		DisabledPredicate = function() return control:IsDisabled() end,
		FocusKey = focusKey,
	})
	button:SetFocusSound("Main_Menu_Mouse_Over")
	button:On("activate", function()
		control:DoLeftClick()
	end)
	return button
end

local function CAI_BuildDialog()
	if not mgr then return end
	CAI_RemoveDialog()

	local description = CAI_MakeText(Controls.Description)
	local details = CAI_MakeText(Controls.Description2)
	details:SetHiddenPredicate(function() return Controls.FrameDeco:IsHidden() end)

	local previous = CAI_MakeButton(Controls.Previous, "civRoyaleIntro:previous")
	local nextButton = CAI_MakeButton(Controls.Next, "civRoyaleIntro:next")
	m_CAI_Dialog = mgr.WidgetHelpers.MakeGeneralDialog(
		function() return Locale.Lookup("LOC_MULTIPLAYER_MATCHMAKE_CIVROYALE") end,
		{ previous, nextButton },
		{ description, details },
		2
	)
	if m_CAI_Dialog then
		mgr:Push(m_CAI_Dialog, { priority = PopupPriority.Current })
	end
end

Realize = WrapFunc(Realize, function(orig)
	orig()
	if mgr and m_CAI_Dialog and mgr:GetTop() == m_CAI_Dialog then
		local content = m_CAI_Dialog:GetContent()
		if content and #content > 0 then
			mgr:SetFocus(content[1])
		end
	end
end)

OnShowFromMenu = WrapFunc(OnShowFromMenu, function(orig)
	orig()
	CAI_BuildDialog()
end)

OnClose = WrapFunc(OnClose, function(orig)
	orig()
	CAI_RemoveDialog()
end)

OnInput = WrapFunc(OnInput, function(orig, input)
	if mgr and m_CAI_Dialog and mgr:GetTop() == m_CAI_Dialog and mgr:HandleInput(input) then
		return true
	end
	return orig(input)
end)
--#End of accessibility integration
Initialize();
