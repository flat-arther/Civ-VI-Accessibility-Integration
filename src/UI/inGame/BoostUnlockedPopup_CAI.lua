include("caiUtils")
include("BoostUnlockedPopup")
local mgr = ExposedMembers.CAI_UIManager

local m_dialog = nil ---@type UIWidget|nil

local function RemoveBoostDialog()
	if not mgr or not m_dialog then return end
	mgr:RemoveFromStack(m_dialog:GetId())
	m_dialog = nil
end

local function GetBoostProgressPair(entry)
	if not entry then return 0.0, 0.0, false end

	local localPlayer = Players[Game.GetLocalPlayer()]
	if localPlayer == nil then return 0.0, 0.0, false end

	local startPercent = 0.0
	local endPercent = 0.0
	local isComplete = false

	if entry.techIndex ~= nil then
		local playerTechs = localPlayer:GetTechs()
		local totalCost = playerTechs:GetResearchCost(entry.techIndex)
		local totalProgress = playerTechs:GetResearchProgress(entry.techIndex)
		isComplete = playerTechs:HasTech(entry.techIndex)

		if totalCost > 0 then
			startPercent = math.min(1.0, math.max(0.0, entry.iTechProgress / totalCost))
			endPercent = isComplete and 1.0 or math.min(1.0, totalProgress / totalCost)
		end
	else
		local playerCulture = localPlayer:GetCulture()
		local totalCost = playerCulture:GetCultureCost(entry.civicIndex)
		local totalProgress = playerCulture:GetCulturalProgress(entry.civicIndex)
		isComplete = playerCulture:HasCivic(entry.civicIndex)

		if totalCost > 0 then
			startPercent = math.min(1.0, math.max(0.0, entry.iCivicProgress / totalCost))
			endPercent = isComplete and 1.0 or math.min(1.0, totalProgress / totalCost)
		end
	end

	return startPercent, endPercent, isComplete
end

local function SetCompletedBoostDescription(entry)
	if entry.techIndex ~= nil then
		local tech = GameInfo.Technologies[entry.techIndex]
		Controls.BoostDescString:SetText(Locale.Lookup("LOC_TECH_BOOST_COMPLETE", tech.Name))
	else
		local civic = GameInfo.Civics[entry.civicIndex]
		Controls.BoostDescString:SetText(Locale.Lookup("LOC_CIVIC_BOOST_COMPLETE", Locale.Lookup(civic.Name)))
	end
end

local function BuildBoostDialog(entry)
	RemoveBoostDialog()
	local startProgress, endProgress, isComplete = GetBoostProgressPair(entry)
	if isComplete then
		-- Completed items may already report zero live progress because the game
		-- has advanced to the next research selection.
		SetCompletedBoostDescription(entry)
		Controls.ProgressBar:SetPercent(1.0)
		Controls.BoostBar:SetPercent(1.0)
	end
	if not mgr then return end
	local startInt = math.floor(startProgress * 100 + 0.5)
	local endInt = math.floor(endProgress * 100 + 0.5)


	local progLabel = Locale.Lookup("LOC_CAI_TECH_CIVIC_BOOST_PROGRESS", startInt, endInt)
	local contentRows = {}

	local descRow = mgr:CreateWidget(mgr:GenerateWidgetId("CAIBoostDesc"), "StaticText", {
		Label = function()
			local descStr = Controls.BoostDescString:GetText() or ""
			return descStr .. " " .. progLabel
		end,
	})
	local causeRow = mgr:CreateWidget(mgr:GenerateWidgetId("CAIBoostCause"), "StaticText", {
		Label = function() return Controls.BoostCauseString:GetText() or "" end,
	})

	table.insert(contentRows, descRow)
	table.insert(contentRows, causeRow)


	local buttons = {}
	local closeBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIBoostClose"), "Button", {
		Label = function() return Locale.Lookup("LOC_CONTINUE") end,
	})
	closeBtn:On("activate", function() Controls.ContinueButton:DoLeftClick() end)
	table.insert(buttons, closeBtn)

	m_dialog = mgr.WidgetHelpers.MakeGeneralDialog(
		function() return Controls.HeaderLabel:GetText() or "" end,
		buttons,
		contentRows,
		1
	)

	if not m_dialog then return end
	mgr:Push(m_dialog, { priority = PopupPriority.Low })
end

ShowBoost = WrapFunc(ShowBoost, function(orig, queueEntry)
	orig(queueEntry)
	if not mgr then return end
	BuildBoostDialog(queueEntry)
end)

OnClose = WrapFunc(OnClose, function(orig)
	RemoveBoostDialog()
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
Controls.ContinueButton:RegisterCallback(Mouse.eLClick, OnClose);
