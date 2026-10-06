include("CAIGameState")
include("caiUtils")
include("WorldCrisisPopup")

local mgr          = CAI:GetUIManager()
local DIALOG_ID    = "CAICrisisPopup_Dialog"
local HOVER_SOUND  = "Main_Menu_Mouse_Over"
local m_dialog     = nil
local m_cachedKData = nil

local function RemoveDialog()
    if not mgr or not m_dialog then return end
    mgr:RemoveFromStack(DIALOG_ID)
    m_dialog = nil
end

local function BuildDetailLines(detailsTable)
    if not detailsTable then return {} end
    local lines = {}
    local currentHeader = nil
    local currentItems = {}

    local function FlushGroup()
        if currentHeader then
            local groupParts = { currentHeader }
            if #currentItems > 0 then
                table.insert(groupParts, table.concat(currentItems, "[NEWLINE]"))
            end
            table.insert(lines, table.concat(groupParts, " "))
        elseif #currentItems > 0 then
            table.insert(lines, table.concat(currentItems, "[NEWLINE]"))
        end
        currentHeader = nil
        currentItems = {}
    end

    for _, line in ipairs(detailsTable) do
        local text = CAIText.PlainInlineText(line.string)
        if text ~= "" then
            if line.align == "center" or line.align == "large" or line.align == "solo" then
                FlushGroup()
                currentHeader = text
            else
                table.insert(currentItems, text)
            end
        end
    end
    FlushGroup()
    return lines
end

local function BuildParticipantsText(kData)
    if not kData.participantPlayers then return "" end
    local names = {}
    for _, playerID in ipairs(kData.participantPlayers) do
        if playerID ~= -1 then
            local pName = CAIGameState.GetKnownPlayerName(playerID)
            if kData.participantScores and kData.participantScores[playerID] then
                pName = pName .. " (" .. tostring(kData.participantScores[playerID]) .. ")"
            end
            table.insert(names, pName)
        end
    end
    return table.concat(names, "[NEWLINE]")
end

local function BuildDialog()
    RemoveDialog()
    if not mgr or not m_cachedKData then return end

    local kData = m_cachedKData
    local localPlayerID = Game.GetLocalPlayer()

    m_dialog = mgr:CreateWidget(DIALOG_ID, "Dialog", {
        Label = CAIText.PlainInlineText(Locale.Lookup(kData.titleString)),
        _focusSound = HOVER_SOUND,
    })

    local rowIndex = 0
    local function AddRow(widgetType, props)
        rowIndex = rowIndex + 1
        local w = mgr:CreateWidget("cpopup_row:" .. rowIndex, widgetType, props)
        m_dialog:AddChild(w)
        return w
    end

    local placeParts = {}
    if kData.placeString and kData.placeString ~= "" then
        table.insert(placeParts, CAIText.PlainInlineText(kData.placeString))
    end
    local participants = BuildParticipantsText(kData)
    if participants ~= "" then
        table.insert(placeParts, Locale.Lookup("LOC_CAI_CRISIS_PARTICIPANTS") .. " " .. participants)
    end
    local placeRow = CAIText.JoinLines(placeParts, ", ")
    if placeRow ~= "" then
        AddRow("StaticText", { Label = placeRow })
    end

    local targetParts = {}
    local targetTitle = CAIText.PlainInlineText(kData.crisisTargetTitle)
    CAIText.AppendIfNonEmpty(targetParts, targetTitle)
    local cityName = CAIText.PlainInlineText(kData.targetCityName)
    CAIText.AppendIfNonEmpty(targetParts, cityName)
    local trinket = CAIText.PlainInlineText(kData.trinketString)
    CAIText.AppendIfNonEmpty(targetParts, trinket)
    local targetRow = CAIText.JoinLines(targetParts, ", ")
    if targetRow ~= "" then
        AddRow("StaticText", { Label = targetRow })
    end

    local detailParts = {}
    local goalTitle = CAIText.PlainInlineText(kData.crisisTrinketTitle)
    CAIText.AppendIfNonEmpty(detailParts, goalTitle)
    if kData.timeRemaining then
        if kData.timeRemaining >= 0 then
            if kData.timeRemaining == 1 then
                table.insert(detailParts, Locale.Lookup("LOC_EMERGENCY_NO_TURNS_REMAINING"))
            else
                table.insert(detailParts, Locale.Lookup("LOC_EMERGENCY_TURNS_REMAINING", kData.timeRemaining))
            end
        else
            table.insert(detailParts, Locale.Lookup("LOC_EMERGENCY_TURNS_OVER"))
        end
    end

    if kData.timeRemaining and kData.timeRemaining < 0 then
        local victorTitle = CAIText.PlainInlineText(Controls.VictorTitle and Controls.VictorTitle:GetText() or "")
        local victorTier = CAIText.PlainInlineText(Controls.VictorTier and Controls.VictorTier:GetText() or "")
        CAIText.AppendIfNonEmpty(detailParts, victorTitle)
        CAIText.AppendIfNonEmpty(detailParts, victorTier)
    end

    local detailLines = BuildDetailLines(kData.crisisDetails)
    for _, line in ipairs(detailLines) do
        table.insert(detailParts, line)
    end

    local detailRow = CAIText.JoinLines(detailParts, ", ")
    if detailRow ~= "" then
        AddRow("StaticText", { Label = detailRow })
    end

    local rewardParts = {}
    local rewardLines = BuildDetailLines(kData.rewardsDetails)
    for _, line in ipairs(rewardLines) do
        table.insert(rewardParts, line)
    end
    local rewardRow = CAIText.JoinLines(rewardParts, ", ")
    if rewardRow ~= "" then
        AddRow("StaticText", { Label = rewardRow })
    end

    local buttons = {}
    if kData.inputRequired then
        local joinBtn = mgr:CreateWidget("cpopup_join", "Button", {
            Label = Locale.Lookup("LOC_EMERGENCY_JOIN"),
            _focusSound = HOVER_SOUND,
        })
        joinBtn:On("activate", function() Controls.JoinButton:DoLeftClick() end)
        table.insert(buttons, joinBtn)

        local rejectBtn = mgr:CreateWidget("cpopup_reject", "Button", {
            Label = Locale.Lookup("LOC_EMERGENCY_REJECT"),
            _focusSound = HOVER_SOUND,
        })
        rejectBtn:On("activate", function() Controls.RejectButton:DoLeftClick() end)
        table.insert(buttons, rejectBtn)
    else
        local okBtn = mgr:CreateWidget("cpopup_ok", "Button", {
            Label = Locale.Lookup("LOC_OK"),
            _focusSound = HOVER_SOUND,
        })
        okBtn:On("activate", function() Controls.OKButton:DoLeftClick() end)
        table.insert(buttons, okBtn)
    end
    m_dialog:SetButtons(buttons, 1)

    mgr:Push(m_dialog, PopupPriority.Low)
end

local origShowEmergency = ShowEmergency
ShowEmergency = function(kData)
    if kData then
        m_cachedKData = kData
    end
    origShowEmergency(kData)
end

local origClose = Close
Close = function()
    RemoveDialog()
    m_cachedKData = nil
    origClose()
end

local origOnShow = OnShow
ContextPtr:SetShowHandler(function()
    if origOnShow then origOnShow() end
    BuildDialog()
end)

local origOnInputHandler = OnInputHandler
OnInputHandler = function(pInputStruct)
    if ContextPtr:IsHidden() then return end
    if m_dialog and mgr then
        local consumed = mgr:HandleInput(pInputStruct)
        if consumed then return true end
    end
    return origOnInputHandler(pInputStruct)
end
ContextPtr:SetInputHandler(OnInputHandler, true)

ContextPtr:SetHideHandler(function(isHide)
    if isHide then
        RemoveDialog()
        m_cachedKData = nil
    end
end)
