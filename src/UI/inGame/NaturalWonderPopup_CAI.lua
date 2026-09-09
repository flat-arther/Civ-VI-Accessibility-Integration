include("caiUtils")
include("NaturalWonderPopup")
local mgr = ExposedMembers.CAI_UIManager

local m_dialog = nil ---@type UIWidget|nil
local m_currentFeatureType = nil ---@type string|nil -- FeatureType of the wonder on display

-- Speaks the accessibility description of the discovery movie (F2), keyed by
-- FeatureType (LOC_CAI_WONDERDESC_<FeatureType>, docs/wonder-descriptions.md).
-- Missing tags Lookup back to their tag, so "result == tag" means no description.
local function SpeakWonderDescription()
	if not m_currentFeatureType then return end
	local tag = "LOC_CAI_WONDERDESC_" .. m_currentFeatureType
	local desc = Locale.Lookup(tag)
	if desc ~= nil and desc ~= "" and desc ~= tag then
		Speak(desc)
	else
		Speak(Locale.Lookup("LOC_CAI_WONDERDESC_NONE"))
	end
end

local function RemoveWonderDialog()
	if not mgr or not m_dialog then return end
	mgr:RemoveFromStack(m_dialog:GetId())
	m_dialog = nil
end

local function BuildWonderDialog()
	RemoveWonderDialog()
	if not mgr then return end

	local contentRows = {}

	local nameRow = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWonderName"), "StaticText", {
		Label = function()
			local name = Controls.WonderName:GetText() or ""
			local desc = Controls.WonderIcon:GetToolTipString() or ""
			return name .. ", " .. desc
		end,
	})
	table.insert(contentRows, nameRow)

	local quoteRow = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWonderQuote"), "StaticText", {
		Label = function() return Controls.WonderQuote:GetText() or "" end,
		HiddenPredicate = function() return Controls.WonderQuoteContainer:IsHidden() end
	})
	table.insert(contentRows, quoteRow)

	local buttons = {}
	local closeBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWonderClose"), "Button", {
		Label = function() return Locale.Lookup("LOC_CONTINUE") end,
	})
	closeBtn:On("activate", function() Controls.Close:DoLeftClick() end)
	table.insert(buttons, closeBtn)

	m_dialog = mgr.WidgetHelpers.MakeGeneralDialog(
		function() return Controls.WonderRevealedHeader:GetText() or "" end,
		buttons,
		contentRows,
		1
	)

	if not m_dialog then return end
	m_dialog:AddInputBindings({ {
		Key = Keys.VK_F2,
		Description = "LOC_CAI_KB_WONDER_DESCRIPTION",
		Action = function()
			SpeakWonderDescription()
			return true
		end,
	} })
	mgr:Push(m_dialog, { priority = PopupPriority.High })
end


ShowPopup = WrapFunc(ShowPopup, function(orig, kData)
	orig(kData)
	m_currentFeatureType = kData and kData.TypeName or nil
	if not mgr then return end
	BuildWonderDialog()
end)

Close = WrapFunc(Close, function(orig)
	RemoveWonderDialog()
	orig()
end)


OnInputHander = WrapFunc(OnInputHander, function(orig, pInputStruct)
	if mgr and m_dialog and mgr:GetTop() == m_dialog and not ContextPtr:IsHidden() then
		local handled = mgr:HandleInput(pInputStruct)
		if handled then return handled end
	end
	return orig(pInputStruct)
end)
ContextPtr:SetInputHandler(OnInputHander, true)
