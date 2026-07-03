include("caiUtils")
include("ExpansionIntro")
local mgr               = ExposedMembers.CAI_UIManager
local m_CAI_DIALOG      = nil ---@ type UIWidget
local m_CurrentPriority = PopupPriority.TutorialHigh
local OPTIONS_HIDE_KEY  = "HideXP2FeaturesScreen";
local m_IsGameStarted   = false

local function RemoveDialog()
	if not mgr or not m_CAI_DIALOG then return end
	mgr:RemoveFromStack(m_CAI_DIALOG:GetId())
	m_CAI_DIALOG = nil
end

local function MakeButton(ctrl)
	if not mgr then return end
	local btn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIExpIntroBTN"), "Button", {
		Label = function() return ctrl:GetText() or "" end,
		HiddenPredicate = function() return ctrl:IsHidden() end
	})
	btn:On("activate", function(w) ctrl:DoLeftClick() end)
	btn:SetFocusSound("Main_Menu_Mouse_Over")
	return btn
end

local function MakeText(ctrl)
	if not mgr then return end
	local text = mgr:CreateWidget(mgr:GenerateWidgetId("CAIExpIntroText"), "StaticText", {
		Label = function() return ctrl:GetText() or "" end,
	})
	text:SetFocusSound("Main_Menu_Mouse_Over")
	return text
end

local function BuildDialog()
	if not m_IsGameStarted then return end
	if not mgr then return end
	local function GetTitle() return Locale.Lookup("LOC_MAIN_MENU_TUTORIAL") end

	local desc = MakeText(Controls.Description)
	local desc2 = MakeText(Controls.Description2)
	desc2:SetHiddenPredicate(function() return Controls.FrameDeco:IsHidden() end)
	local prevBtn = MakeButton(Controls.Previous)
	local nextBtn = MakeButton(Controls.Next)
	local checkbox = mgr:CreateWidget("CAIExpIntroCheck", "Checkbox", {
		Label = function() return Locale.Lookup("LOC_XP_INTRO_HIDETHIS") end,
	})
	checkbox:SetChecked(Options.GetUserOption("Tutorial", OPTIONS_HIDE_KEY) == 1, true)
	checkbox:SetValueSetter(function(val) return Controls.DontShowAgain:DoLeftClick() end)
	checkbox:SetFocusSound("Main_Menu_Mouse_Over")
	m_CAI_DIALOG = mgr.WidgetHelpers.MakeGeneralDialog(GetTitle, { prevBtn, nextBtn }, { desc, desc2, checkbox }, 2)
	if m_CAI_DIALOG then
		if not mgr:GetWidgetById(m_CAI_DIALOG:GetId(), false) then
			mgr:Push(m_CAI_DIALOG, m_CurrentPriority)
		end
	end
end

Realize = WrapFunc(Realize, function(orig)
	orig()
	if mgr:GetTop() == m_CAI_DIALOG then
		local content = m_CAI_DIALOG:GetContent()
		if not content or #content == 0 then return end
		mgr:SetFocus(content[1])
	end
end)

Events.LoadGameViewStateDone.Remove(OnLoadGameViewStateDone);
OnShow = WrapFunc(OnShow, function(orig)
	m_CurrentPriority = PopupPriority.TutorialHigh
	orig()
	BuildDialog()
end)

LuaEvents.InGameTopOptionsMenu_ShowExpansionIntro.Remove(OnShowFromMenu);
OnShowFromMenu = WrapFunc(OnShowFromMenu, function(orig)
	m_CurrentPriority = PopupPriority.Current
	orig()
	BuildDialog()
end)

OnClose = WrapFunc(OnClose, function(orig)
	orig()
	RemoveDialog()
end)

OnInput = WrapFunc(OnInput, function(orig, pInputStruct)
	if mgr and mgr:GetTop() == m_CAI_DIALOG then
		if mgr:HandleInput(pInputStruct) then return true end
	end
	return orig(pInputStruct)
end)

function OnLoadScreenClose()
	if not m_IsGameStarted then
		m_IsGameStarted = true
		if not ContextPtr:IsHidden() then
			BuildDialog()
		end
	end
end

Events.LoadScreenClose.Add(OnLoadScreenClose)
ContextPtr:SetInputHandler(OnInput, true)
Controls.Next:RegisterCallback(Mouse.eLClick, OnNext);
Controls.Previous:RegisterCallback(Mouse.eLClick, OnPrevious);

LuaEvents.InGameTopOptionsMenu_ShowExpansionIntro.Add(OnShowFromMenu);
Events.LoadGameViewStateDone.Add(OnLoadGameViewStateDone);
