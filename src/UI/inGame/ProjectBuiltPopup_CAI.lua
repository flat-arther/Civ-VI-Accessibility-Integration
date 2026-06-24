include("caiUtils")
include("ProjectBuiltPopup")
local mgr = ExposedMembers.CAI_UIManager

local m_dialog = nil ---@type UIWidget|nil

local function RemoveProjectBuiltDialog()
	if not mgr or not m_dialog then return end
	mgr:RemoveFromStack(m_dialog:GetId())
	m_dialog = nil
end

local function BuildProjectBuiltDialog()
	RemoveProjectBuiltDialog()
	if not mgr then return end

	local contentRows = {}

	local nameRow = mgr:CreateWidget(mgr:GenerateWidgetId("CAIProjectBuiltName"), "StaticText", {
		Label = function()
			local name = Controls.ProjectName:GetText() or ""
			local desc = (not Controls.ProjectQuoteContainer:IsHidden() and Controls.ProjectQuote:GetText()) or ""
			if desc ~= "" then
				return name .. ", " .. desc
			end
			return name
		end,
	})
	table.insert(contentRows, nameRow)


	local buttons = {}
	local closeBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIProjectBuiltClose"), "Button", {
		Label = function() return Locale.Lookup("LOC_CONTINUE") end,
	})
	closeBtn:On("activate", function() Controls.Close:DoLeftClick() end)
	table.insert(buttons, closeBtn)

	m_dialog = mgr.WidgetHelpers.MakeGeneralDialog(
		function() return Controls.ProjectCompletedHeader:GetText() or "" end,
		buttons,
		contentRows,
		1
	)

	if not m_dialog then return end
	mgr:Push(m_dialog, { priority = PopupPriority.High })
end


ShowPopup = WrapFunc(ShowPopup, function(orig, kData)
	orig(kData)
	if not mgr then return end
	BuildProjectBuiltDialog()
end)

Close = WrapFunc(Close, function(orig)
	RemoveProjectBuiltDialog()
	orig()
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
	if mgr and m_dialog and mgr:GetTop() == m_dialog and not ContextPtr:IsHidden() then
		local handled = mgr:HandleInput(pInputStruct)
		if handled then return handled end
	end
	return orig(pInputStruct)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)
