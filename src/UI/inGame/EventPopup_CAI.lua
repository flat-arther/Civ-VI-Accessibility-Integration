include("caiUtils")
include("EventPopup")

local mgr = ExposedMembers.CAI_UIManager

local m_dialog = nil ---@type DialogWidget|nil
local m_isCapturingUnlocks = false
local m_unlocks = {
	Default = {},
	ChoiceA = {},
	ChoiceB = {},
}

local function RemoveEventDialog()
	if not mgr or not m_dialog then return end
	mgr:RemoveFromStack(m_dialog:GetId())
	m_dialog = nil
end

local function ResetCapturedUnlocks()
	m_unlocks = {
		Default = {},
		ChoiceA = {},
		ChoiceB = {},
	}
end

local function CaptureUnlock(uiParent, tooltip)
	if not m_isCapturingUnlocks or not tooltip or tooltip == "" then return end

	if uiParent == Controls.UnlocksStack then
		table.insert(m_unlocks.Default, tooltip)
	elseif uiParent == Controls.ChoiceAEffects.UnlocksStack then
		table.insert(m_unlocks.ChoiceA, tooltip)
	elseif uiParent == Controls.ChoiceBEffects.UnlocksStack then
		table.insert(m_unlocks.ChoiceB, tooltip)
	end
end

local function AddStaticRow(contentRows, idPrefix, labelFn, hiddenPredicate)
	local row = mgr:CreateWidget(mgr:GenerateWidgetId(idPrefix), "StaticText", {
		Label = labelFn,
		HiddenPredicate = hiddenPredicate,
	})
	table.insert(contentRows, row)
end

local function BuildUnlockText(titleControl, unlocks)
	if #unlocks == 0 then return "" end

	local lines = {}
	local title = titleControl:GetText() or ""
	if title ~= "" then table.insert(lines, title) end
	for _, tooltip in ipairs(unlocks) do
		table.insert(lines, tooltip)
	end
	return table.concat(lines, "[NEWLINE]")
end

local function IsValidPopupData(kPopupData)
	if not kPopupData or not kPopupData.EventKey then return false end
	if kPopupData.ForPlayer ~= nil and kPopupData.ForPlayer ~= Game.GetLocalPlayer() then return false end

	local kEventData = GameInfo.EventPopupData[kPopupData.EventKey]
	return kEventData ~= nil and (kPopupData.EventEffect ~= nil or kEventData.Effects ~= nil)
end

local function BuildEventDialog(kPopupData)
	RemoveEventDialog()
	if not mgr or not IsValidPopupData(kPopupData) then return end

	local contentRows = {}
	AddStaticRow(contentRows, "CAIEventDescription",
		function() return Controls.Description:GetText() or "" end,
		function() return Controls.Description:IsHidden() end)
	AddStaticRow(contentRows, "CAIEventImageText",
		function() return Controls.ImageText:GetText() or "" end,
		function() return Controls.ImageText:IsHidden() end)
	AddStaticRow(contentRows, "CAIEventEffects",
		function() return Controls.Effects:GetText() or "" end)

	local hasChoices = kPopupData.ChoiceAText ~= nil and kPopupData.ChoiceBText ~= nil
	if not hasChoices and #m_unlocks.Default > 0 then
		AddStaticRow(contentRows, "CAIEventUnlocksTitle",
			function() return Controls.UnlocksTitle:GetText() or "" end)
		for _, tooltip in ipairs(m_unlocks.Default) do
			local unlockText = tooltip
			AddStaticRow(contentRows, "CAIEventUnlock", function() return unlockText end)
		end
	end

	local buttons = {}
	if hasChoices then
		local choiceATooltip = BuildUnlockText(Controls.ChoiceAEffects.UnlocksTitle, m_unlocks.ChoiceA)
		local choiceA = mgr:CreateWidget(mgr:GenerateWidgetId("CAIEventChoiceA"), "Button", {
			Label = function() return Controls.ChoiceA:GetText() or "" end,
			Tooltip = function() return choiceATooltip end,
			HiddenPredicate = function() return Controls.ChoiceA:IsHidden() end,
			DisabledPredicate = function() return Controls.ChoiceA:IsDisabled() end,
		})
		choiceA:On("activate", function()
			RemoveEventDialog()
			Controls.ChoiceA:DoLeftClick()
		end)
		table.insert(buttons, choiceA)

		local choiceBTooltip = BuildUnlockText(Controls.ChoiceBEffects.UnlocksTitle, m_unlocks.ChoiceB)
		local choiceB = mgr:CreateWidget(mgr:GenerateWidgetId("CAIEventChoiceB"), "Button", {
			Label = function() return Controls.ChoiceB:GetText() or "" end,
			Tooltip = function() return choiceBTooltip end,
			HiddenPredicate = function() return Controls.ChoiceB:IsHidden() end,
			DisabledPredicate = function() return Controls.ChoiceB:IsDisabled() end,
		})
		choiceB:On("activate", function()
			RemoveEventDialog()
			Controls.ChoiceB:DoLeftClick()
		end)
		table.insert(buttons, choiceB)
	else
		local continueButton = mgr:CreateWidget(mgr:GenerateWidgetId("CAIEventContinue"), "Button", {
			Label = function() return Controls.Continue:GetText() or "" end,
			HiddenPredicate = function() return Controls.Continue:IsHidden() end,
			DisabledPredicate = function() return Controls.Continue:IsDisabled() end,
		})
		continueButton:On("activate", function()
			RemoveEventDialog()
			Controls.Continue:DoLeftClick()
		end)
		table.insert(buttons, continueButton)
	end

	m_dialog = mgr.WidgetHelpers.MakeGeneralDialog(
		function() return Controls.Title:GetText() or "" end,
		buttons,
		contentRows,
		1
	)
	if not m_dialog then return end

	if hasChoices then
		-- Vanilla deliberately ignores Enter unless a choice button has focus.
		m_dialog:SetDefaultActionWidget(nil)
	end
	mgr:Push(m_dialog, { priority = PopupPriority.Medium })
end

AddUnlockIcon = WrapFunc(AddUnlockIcon, function(orig, uiParent, icon, tooltip)
	local instance = orig(uiParent, icon, tooltip)
	CaptureUnlock(uiParent, tooltip)
	return instance
end)

ShowCompletedPopup = WrapFunc(ShowCompletedPopup, function(orig, kPopupData)
	ResetCapturedUnlocks()
	m_isCapturingUnlocks = true
	orig(kPopupData)
	m_isCapturingUnlocks = false
	BuildEventDialog(kPopupData)
end)

ShowNextQueuedPopup = WrapFunc(ShowNextQueuedPopup, function(orig)
	RemoveEventDialog()
	orig()
end)

OnClose = WrapFunc(OnClose, function(orig)
	RemoveEventDialog()
	orig()
end)

OnShutdown = WrapFunc(OnShutdown, function(orig)
	RemoveEventDialog()
	orig()
end)
ContextPtr:SetShutdown(OnShutdown)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
	if mgr and m_dialog and mgr:GetTop() == m_dialog and not ContextPtr:IsHidden() then
		local handled = mgr:HandleInput(pInputStruct)
		if handled then return handled end
	end
	return orig(pInputStruct)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)
