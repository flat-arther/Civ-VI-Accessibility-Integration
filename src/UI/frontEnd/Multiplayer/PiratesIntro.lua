-- Copyright 2020, Firaxis Games

-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local OPTIONS_SEEN_KEY	:string = "HasSeenPiratesIntro";

--TODO: actually get these images
local INTRO_ILLUSTRATIONS:table = {
	"PiratesIntro_Diagram_1",
	"PiratesIntro_Diagram_2",
	"PiratesIntro_Diagram_3",
	"PiratesIntro_Diagram_4",
};

local NUM_PAGES = #INTRO_ILLUSTRATIONS;

local INTRO_DESCRIPTIONS:table = {
	"LOC_TUTORIAL_PIRATES_INTRO_BODY",
	"LOC_TUTORIAL_PIRATES_CREW_BODY",
	"LOC_TUTORIAL_PIRATES_TREASURE_BODY",
	"LOC_TUTORIAL_PIRATES_SCORING_BODY",
};

local INTRO_DESCRIPTIONS_DETAILS:table = {
	"LOC_TUTORIAL_PIRATES_INTRO_DETAILS",
	"LOC_TUTORIAL_PIRATES_CREW_DETAILS",
	"LOC_TUTORIAL_PIRATES_TREASURE_DETAILS",
	"",
};

local NEXT_BUTTON_TEXT = Locale.Lookup("LOC_PIRATES_INTRO_NEXT");
local FINAL_BUTTON_TEXT = Locale.Lookup("LOC_CLOSE");

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

	Controls.Next:SetText(m_PageIndex == NUM_PAGES and FINAL_BUTTON_TEXT or NEXT_BUTTON_TEXT);
	if (m_PageIndex == NUM_PAGES) then
		Controls.Next:SetDisabled(false);
		Controls.Next:SetToolTipString("");
	else
		Controls.Next:SetDisabled(false);
		Controls.Next:SetToolTipString("");
	end
	Controls.Previous:SetHide(m_PageIndex == 1 or m_PageIndex == NUM_PAGES);
	Controls.ButtonStack:CalculateSize();
end

-- ===========================================================================
function OnShow()
	m_PageIndex = 1;
	Realize();
	UIManager:QueuePopup(ContextPtr, PopupPriority.TutorialHigh);
end

-- ===========================================================================
function OnShowFromMenu()
	m_PageIndex = 1;
	Realize();
	UIManager:QueuePopup(ContextPtr, PopupPriority.Current);
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
		OnClose();
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
function OnShutdown()
	LuaEvents.MainMenu_ShowPiratesIntro.Remove(OnShowFromMenu);
	LuaEvents.InGameTopOptionsMenu_ShowExpansionIntro.Remove( OnShowFromMenu );
	LuaEvents.DiplomacyActionView_HideIngameUI.Remove( HideIfVisible );
end

-- ===========================================================================
function Initialize()
	ContextPtr:SetInputHandler( OnInput, true );
	ContextPtr:SetShutdown( OnShutdown );

	Controls.Close:RegisterCallback(Mouse.eLClick, OnClose);
	Controls.Next:RegisterCallback(Mouse.eLClick, OnNext);
	Controls.Previous:RegisterCallback(Mouse.eLClick, OnPrevious);

	LuaEvents.InGameTopOptionsMenu_ShowExpansionIntro.Add( OnShowFromMenu );
	LuaEvents.DiplomacyActionView_HideIngameUI.Add( HideIfVisible );
	LuaEvents.MainMenu_ShowPiratesIntro.Add(OnShowFromMenu);

	Events.UserRequestClose.Add( HideIfVisible );
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
	return mgr:CreateWidget(mgr:GenerateWidgetId("CAIPiratesIntroText"), "StaticText", {
		Label = function() return control:GetText() or "" end,
	})
end

local function CAI_MakeButton(control, focusKey)
	local button = mgr:CreateWidget(mgr:GenerateWidgetId("CAIPiratesIntroButton"), "Button", {
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

	local previous = CAI_MakeButton(Controls.Previous, "piratesIntro:previous")
	local nextButton = CAI_MakeButton(Controls.Next, "piratesIntro:next")
	m_CAI_Dialog = mgr.WidgetHelpers.MakeGeneralDialog(
		function() return Locale.Lookup("LOC_MULTIPLAYER_MATCHMAKE_PIRATES") end,
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

OnShutdown = WrapFunc(OnShutdown, function(orig)
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
