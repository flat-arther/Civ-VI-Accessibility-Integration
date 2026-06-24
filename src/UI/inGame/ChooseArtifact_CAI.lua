include("caiUtils")
include("ChooseArtifact")
local mgr = ExposedMembers.CAI_UIManager

local m_dialog = nil ---@type UIWidget|nil

local function RemoveArtifactDialog()
	if not mgr or not m_dialog then return end
	mgr:RemoveFromStack(m_dialog:GetId())
	m_dialog = nil
end

local function BuildArtifactDialog()
	RemoveArtifactDialog()
	if not mgr then return end

	local contentRows = {}

	local infoRow = mgr:CreateWidget(mgr:GenerateWidgetId("CAIArtifactInfo"), "StaticText", {
		Label = function()
			local explanation = Controls.Explanation:GetText() or ""
			local era = Controls.EraString:GetText() or ""
			local choice = Controls.ChoiceHeader:GetText() or ""
			return explanation .. " " .. era .. " " .. choice
		end,
	})
	table.insert(contentRows, infoRow)

	local buttons = {}

	local option1Btn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIArtifactOption1"), "Button", {
		Label = function() return Controls.Button1:GetText() or "" end,
	})
	option1Btn:On("activate", function() Controls.Button1:DoLeftClick() end)
	table.insert(buttons, option1Btn)

	local option2Btn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIArtifactOption2"), "Button", {
		Label = function() return Controls.Button2:GetText() or "" end,
		HiddenPredicate = function() return Controls.Button2:IsHidden() end
	})
	option2Btn:On("activate", function() Controls.Button2:DoLeftClick() end)
	table.insert(buttons, option2Btn)

	m_dialog = mgr.WidgetHelpers.MakeGeneralDialog(
		function() return Controls.PanelHeader:GetText() or "" end,
		buttons,
		contentRows,
		1
	)

	if not m_dialog then return end
	mgr:Push(m_dialog, { priority = PopupPriority.High })
end
LuaEvents.NotificationPanel_OpenArtifactPanel.Remove(OnOpen);
OnOpen = WrapFunc(OnOpen, function(orig)
	orig()
	if not mgr then return end
	BuildArtifactDialog()
end)

function OnHide()
	RemoveArtifactDialog()
end

OnInputHandler = function(pInputStruct)
	if mgr and m_dialog and mgr:GetTop() == m_dialog and not ContextPtr:IsHidden() then
		local handled = mgr:HandleInput(pInputStruct)
		if handled then return handled end
	end
	return false
end
ContextPtr:SetInputHandler(OnInputHandler, true)
ContextPtr:SetHideHandler(OnHide)
LuaEvents.NotificationPanel_OpenArtifactPanel.Add(OnOpen);
