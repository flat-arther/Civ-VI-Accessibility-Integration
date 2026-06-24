include("caiUtils")
include("WonderBuiltPopup")
local mgr = ExposedMembers.CAI_UIManager

local m_dialog = nil ---@type UIWidget|nil

local function RemoveWonderBuiltDialog()
	if not mgr or not m_dialog then return end
	mgr:RemoveFromStack(m_dialog:GetId())
	m_dialog = nil
end

local function BuildWonderBuiltDialog()
	RemoveWonderBuiltDialog()
	if not mgr then return end

	local contentRows = {}

	local nameRow = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWonderBuiltName"), "StaticText", {
		Label = function()
			local name = Controls.WonderName:GetText() or ""
			local desc = Controls.WonderIcon:GetToolTipString() or ""
			return name .. ", " .. desc
		end,
	})
	table.insert(contentRows, nameRow)

	local quoteRow = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWonderBuiltQuote"), "StaticText", {
		Label = function() return Controls.WonderQuote:GetText() or "" end,
		HiddenPredicate = function() return Controls.WonderQuoteContainer:IsHidden() end
	})
	table.insert(contentRows, quoteRow)

	local buttons = {}

	local replayBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWonderBuiltReplay"), "Button", {
		Label = function() return Locale.Lookup("LOC_UI_ENDGAME_REPLAY_MOVIE") end,
		HiddenPredicate = function() return Controls.ReplayButton:IsHidden() end
	})
	replayBtn:On("activate", function() Controls.ReplayButton:DoLeftClick() end)
	table.insert(buttons, replayBtn)

	local closeBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWonderBuiltClose"), "Button", {
		Label = function() return Locale.Lookup("LOC_CONTINUE") end,
	})
	closeBtn:On("activate", function() Controls.Close:DoLeftClick() end)
	table.insert(buttons, closeBtn)

	m_dialog = mgr.WidgetHelpers.MakeGeneralDialog(
		function() return Controls.WonderCompletedHeader:GetText() or "" end,
		buttons,
		contentRows,
		2
	)

	if not m_dialog then return end
	mgr:Push(m_dialog, { priority = PopupPriority.High })
end

ShowPopup = WrapFunc(ShowPopup, function(orig, kData)
	orig(kData)
	if not mgr then return end
	BuildWonderBuiltDialog()
end)

Close = WrapFunc(Close, function(orig)
	RemoveWonderBuiltDialog()
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
