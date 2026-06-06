include("caiUtils")
include("WorldCongressPopup")

local mgr                  = ExposedMembers.CAI_UIManager

-- =========================================================================
-- Constants
-- =========================================================================
local PANEL_ID             = "CAIWorldCongress"
local LEADERS_ID           = "CAIWorldCongress_Leaders"
local BODY_ID              = "CAIWorldCongress_Body"
local HOVER_SOUND          = "Main_Menu_Mouse_Over"

local CAI_TAB_RESULTS      = DB.MakeHash("REVIEW_TAB_RESULTS")
local CAI_TAB_EFFECTS      = DB.MakeHash("REVIEW_TAB_CURRENT_EFFECTS")
local CAI_TAB_PROPOSALS    = DB.MakeHash("REVIEW_TAB_AVAILABLE_PROPOSALS")

-- =========================================================================
-- State
-- =========================================================================
local m_panel              = nil ---@type UIWidget|nil
local m_leadersList        = nil ---@type UIWidget|nil
local m_body               = nil ---@type UIWidget|nil
local m_caiStage           = 0
local m_caiPhase           = 0
local m_phase1Capture      = nil
local m_capturedChoices    = {}
local m_confirmDialog      = nil ---@type UIWidget|nil
local m_isBuilding         = false
local m_activeSection      = 0   -- 1=results, 2=effects, 3=proposals
local m_resultsItem        = nil ---@type UIWidget|nil
local m_effectsItem        = nil ---@type UIWidget|nil

-- =========================================================================
-- Utility: find a named child control by ID (shallow)
-- =========================================================================
local function FindChild(root, id)
    if not root or not root.GetChildren then return nil end
    for _, child in ipairs(root:GetChildren()) do
        if child:GetID() == id then return child end
    end
    return nil
end

local function FindChildDeep(root, id)
    if not root or not root.GetChildren then return nil end
    for _, child in ipairs(root:GetChildren()) do
        if child:GetID() == id then return child end
        local found = FindChildDeep(child, id)
        if found then return found end
    end
    return nil
end

-- =========================================================================
-- Check whether a vanilla control has the IsNew icon visible
-- =========================================================================
local function IsNewVisible(instanceRoot)
    local iconNew = FindChildDeep(instanceRoot, "IconNew")
    return iconNew and not iconNew:IsHidden()
end

-- =========================================================================
-- Collect text lines from a CrisisDetailsStack or RewardsDetailsStack
-- =========================================================================
local function CollectCrisisText(stackCtrl)
    if not stackCtrl then return "" end
    local parts = {}
    for _, child in ipairs(stackCtrl:GetChildren() or {}) do
        local lbl = FindChild(child, "String") or FindChild(child, "Label")
        if not lbl then
            if child.GetText then lbl = child end
        end
        if not lbl then
            for _, sub in ipairs(child:GetChildren() or {}) do
                if sub.GetText then
                    local t = sub:GetText()
                    if t and t ~= "" then table.insert(parts, t) end
                end
            end
        else
            local t = lbl:GetText()
            if t and t ~= "" then table.insert(parts, t) end
        end
    end
    return table.concat(parts, ", ")
end

-- =========================================================================
-- Dismiss the confirmation dialog if it's on the stack
-- =========================================================================
local function DismissConfirmDialog()
    if m_confirmDialog then
        mgr:RemoveFromStack(m_confirmDialog:GetId())
        m_confirmDialog = nil
    end
end

-- =========================================================================
-- Remove the CAI panel from the manager stack
-- =========================================================================
local function RemovePanel()
    if not mgr then return end
    DismissConfirmDialog()
    if not m_panel then return end
    mgr:RemoveFromStack(PANEL_ID)
    m_panel = nil
    m_leadersList = nil
    m_body = nil
    m_capturedChoices = {}
    m_activeSection = 0
    m_resultsItem = nil
    m_effectsItem = nil
end

-- =========================================================================
-- Remove just the dynamic body widget (keeps shell)
-- =========================================================================
local function ClearBody()
    DismissConfirmDialog()
    if m_body then
        m_body:RemoveFromParent()
    end
    m_body = nil
    m_resultsItem = nil
    m_effectsItem = nil
    m_activeSection = 0
end

-- =========================================================================
-- Build the leaders list from vanilla LeaderStack
-- =========================================================================
local function BuildLeaders()
    if not m_panel then return end

    local oldList = m_leadersList
    local capture
    if oldList then
        capture = mgr:CaptureFocusKey(oldList)
        oldList:RemoveFromParent()
    end

    m_leadersList = mgr:CreateWidget(LEADERS_ID, "List", {
        Label = function() return Locale.Lookup("LOC_WORLD_CONGRESS_MEMBERS") end,
    })

    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID < 0 then return end
    local pDiplomacy = Players[localPlayerID]:GetDiplomacy()
    local aPlayers = PlayerManager.GetAliveMajors()
    local inSession = m_caiStage == 1 or m_caiStage == 2

    for _, pPlayer in ipairs(aPlayers) do
        local playerID = pPlayer:GetID()
        local pConfig = PlayerConfigurations[playerID]
        local isLocal = playerID == localPlayerID
        local hasMet = isLocal or pDiplomacy:HasMet(playerID)

        local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWC_L"), "MenuItem", {
            Label = function()
                if hasMet then
                    return Locale.Lookup(pConfig:GetLeaderName())
                end
                return Locale.Lookup("LOC_DIPLO_UNKNOWN_LEADER")
            end,
            Tooltip = function()
                if not hasMet then return "" end
                local parts = {}
                local favor
                if inSession then
                    favor = pPlayer:GetFavorEnteringCongress()
                else
                    favor = pPlayer:GetFavor()
                end
                if isLocal then
                    table.insert(parts, Locale.Lookup("LOC_WORLD_CONGRESS_TT_PLAYER_FAVOR", favor))
                else
                    table.insert(parts, Locale.Lookup("LOC_WORLD_CONGRESS_TT_LEADER_FAVOR", favor))
                end
                local grievances = pDiplomacy:GetGrievancesAgainst(playerID)
                if grievances > 0 then
                    table.insert(parts, Locale.Lookup("LOC_WORLD_CONGRESS_GRIEVANCE_DEFINITION", grievances))
                end
                return table.concat(parts, ", ")
            end,
        })
        item.FocusKey = "leader:" .. playerID
        item:SetFocusSound(HOVER_SOUND)
        if hasMet then
            item:On("activate", function() OpenDiplomacyLiteMode(playerID) end)
        end
        m_leadersList:AddChild(item)
    end

    m_panel:AddChild(m_leadersList)

    if capture then
        mgr:RestoreFocus(m_leadersList, capture)
    end
end

-- =========================================================================
-- Create a button widget mirroring a vanilla control
-- =========================================================================
local function MakeBtn(id, vanillaCtrl, activateFn)
    local btn = mgr:CreateWidget(id, "Button", {
        Label = function() return vanillaCtrl:GetText() or "" end,
        Tooltip = function() return vanillaCtrl:GetToolTipString() or "" end,
    })
    btn:SetHiddenPredicate(function() return vanillaCtrl:IsHidden() end)
    btn:SetDisabledPredicate(function() return vanillaCtrl:IsDisabled() end)
    btn:On("activate", activateFn)
    btn:SetFocusSound(HOVER_SOUND)
    return btn
end

-- =========================================================================
-- Build the bottom action buttons as direct panel children
-- =========================================================================
local function BuildButtons()
    if not m_panel then return end

    m_panel:AddChild(MakeBtn("CAIWC_Prev", Controls.PrevButton, function() Controls.PrevButton:DoLeftClick() end))
    m_panel:AddChild(MakeBtn("CAIWC_Next", Controls.NextButton, function() Controls.NextButton:DoLeftClick() end))
    if m_caiStage ~= 4 then
        m_panel:AddChild(MakeBtn("CAIWC_Accept", Controls.AcceptButton, function() Controls.AcceptButton:DoLeftClick() end))
        m_panel:AddChild(MakeBtn("CAIWC_Pass", Controls.PassButton, function() Controls.PassButton:DoLeftClick() end))
    end
    m_panel:AddChild(MakeBtn("CAIWC_Return", Controls.ReturnButton, function() Controls.ReturnButton:DoLeftClick() end))
end

-- =========================================================================
-- Insert body as the first child of the panel
-- =========================================================================
local function InsertBody()
    if not m_panel or not m_body then return end
    m_panel:InsertChild(1, m_body)
end

-- =========================================================================
-- Directly update the vanilla target selection without opening the pulldown
-- =========================================================================
local function ApplyTargetSelection(instanceRoot, outcome, resHash, gameIndex, displayText)
    if outcome == 0 or not gameIndex or gameIndex <= 0 then return end

    local kChoice = m_capturedChoices[resHash]
    if not kChoice then return end

    kChoice.target = gameIndex

    local choiceId = outcome == 1 and "Choice1" or "Choice2"
    local choiceRoot = FindChildDeep(instanceRoot, choiceId)
    if choiceRoot then
        local pulldown = FindChildDeep(choiceRoot, "Pulldown")
        local playerPulldown = FindChildDeep(choiceRoot, "PlayerPulldown")
        local activePulldown = pulldown and not pulldown:IsHidden()
            and pulldown or playerPulldown
        if activePulldown then
            activePulldown:GetButton():SetText(displayText or "")
            activePulldown:GetButton():SetToolTipString("")
        end
    end

    UpdateResolutionChoice(kChoice)
    UpdateNavButtons()
end

-- =========================================================================
-- Build target dropdown options from API resolution data
-- =========================================================================
local function BuildTargetOptions(kResolutionData)
    local options = {
        { label = Locale.Lookup("LOC_WORLD_CONGRESS_SELECT_TARGET"), value = 0 },
    }
    if not kResolutionData or not kResolutionData.PossibleTargets then
        return options
    end
    if kResolutionData.TargetType == "PlayerType" then
        for i, v in pairs(kResolutionData.PossibleTargets) do
            local pid = tonumber(v)
            if pid then
                table.insert(options, {
                    label = GetVisiblePlayerName(pid),
                    value = i,
                })
            end
        end
    else
        for i, targetName in ipairs(kResolutionData.PossibleTargets) do
            table.insert(options, {
                label = Locale.Lookup(targetName),
                value = i,
            })
        end
    end
    return options
end

-- =========================================================================
-- Build a favored/disfavored tooltip string from a vanilla container
-- =========================================================================
local function BuildFavorTooltip(container)
    if not container or container:IsHidden() then return nil end
    local tt = container:GetToolTipString() or ""
    if tt ~= "" then return tt end
    return nil
end

-- =========================================================================
-- Build a single tooltip string from emergency crisis details and rewards
-- =========================================================================
local function BuildEmergencyTooltipText(instanceRoot)
    local emergencyContainer = FindChildDeep(instanceRoot, "EmergencyContainer")
    if not emergencyContainer or emergencyContainer:IsHidden() then return "" end

    local emergencyRoot = FindChildDeep(instanceRoot, "Emergency")
    if not emergencyRoot then return "" end

    local crisisStack = FindChildDeep(emergencyRoot, "CrisisDetailsStack")
    local rewardsStack = FindChildDeep(emergencyRoot, "RewardsDetailsStack")
    local parts = {}

    local crisisText = CollectCrisisText(crisisStack)
    if crisisText ~= "" then
        table.insert(parts, Locale.Lookup("LOC_CAI_WC_CRISIS_DETAILS") .. ": " .. crisisText)
    end

    local rewardsText = CollectCrisisText(rewardsStack)
    if rewardsText ~= "" then
        table.insert(parts, Locale.Lookup("LOC_CAI_WC_REWARDS") .. ": " .. rewardsText)
    end

    return table.concat(parts, ", ")
end

-- =========================================================================
-- Phase 1: Build voting body from vanilla-populated ResolutionStack
-- =========================================================================
local function BuildVotingBody()
    ClearBody()
    if not m_panel then return end

    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID < 0 then return end

    local m_categoryTitle = nil
    local m_categoryCost = nil
    m_body = mgr:CreateWidget(BODY_ID, "Tree", {
        Label = function()
            local title = m_categoryTitle and m_categoryTitle:GetText()
                or Locale.Lookup("LOC_CAI_WC_RESOLUTIONS")
            local cost = m_categoryCost and m_categoryCost:GetText() or ""
            if cost ~= "" then return title .. ", " .. cost end
            return title
        end,
    })

    local favorStatus = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWC_FavorSt"), "StaticText", {
        Label = function()
            local text = Controls.WorkingFavor:GetText() or ""
            local amount = text:match("%d+") or "0"
            return Locale.Lookup("LOC_CAI_WC_FAVOR_REMAINING", amount)
        end,
        Tooltip = function() return Controls.Description:GetText() or "" end,
    })
    favorStatus:SetFocusSound(HOVER_SOUND)
    m_body:AddChild(favorStatus)

    local pWorldCongress = Game.GetWorldCongress()
    local kAllResolutions = pWorldCongress:GetResolutions(localPlayerID)
    local apiResList = {}
    for i, v in pairs(kAllResolutions) do
        if type(i) == "number" then
            apiResList[i] = v
        end
    end

    local resolutionChildren = Controls.ResolutionStack:GetChildren()
    if not resolutionChildren then
        InsertBody()
        return
    end

    local apiResIdx = 0

    for _, instanceRoot in ipairs(resolutionChildren) do
        if not instanceRoot:IsHidden() then
            local titleCtrl = FindChildDeep(instanceRoot, "Title")
            local effectCtrl1 = FindChildDeep(instanceRoot, "Effect1")
            local effectCtrl2 = FindChildDeep(instanceRoot, "Effect2")
            local vote1Root = FindChildDeep(instanceRoot, "Vote1")
            local vote2Root = FindChildDeep(instanceRoot, "Vote2")
            local choice1Root = FindChildDeep(instanceRoot, "Choice1")
            local choice2Root = FindChildDeep(instanceRoot, "Choice2")
            local descriptionCtrl = FindChildDeep(instanceRoot, "Description")
            local moreInfoCtrl = FindChildDeep(instanceRoot, "MoreInfoButton")
            local favoredContainer = FindChildDeep(instanceRoot, "FavoredContainer")
            local disfavoredContainer = FindChildDeep(instanceRoot, "DisfavoredContainer")

            if titleCtrl and vote1Root then
                apiResIdx = apiResIdx + 1
                local kResolutionData = apiResList[apiResIdx]
                local kResolution = kResolutionData
                    and GameInfo.Resolutions[kResolutionData.Type]
                local resHash = kResolution and kResolution.Hash or 0

                local vote1Label = FindChildDeep(vote1Root, "Label")
                local vote1UpBtn = FindChildDeep(vote1Root, "UpButton")
                local vote1DownBtn = FindChildDeep(vote1Root, "DownButton")
                local vote2Label = FindChildDeep(vote2Root, "Label")
                local vote2UpBtn = FindChildDeep(vote2Root, "UpButton")
                local vote2DownBtn = FindChildDeep(vote2Root, "DownButton")

                local resItem = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWC_Res"), "TreeItem", {
                    Label = function() return titleCtrl:GetText() or "" end,
                    Tooltip = function()
                        local parts = {}
                        if descriptionCtrl then
                            local d = descriptionCtrl:GetText()
                            if d and d ~= "" then table.insert(parts, d) end
                        end
                        if moreInfoCtrl and not moreInfoCtrl:IsHidden() then
                            local tip = moreInfoCtrl:GetToolTipString()
                            if tip and tip ~= "" then table.insert(parts, tip) end
                        end
                        return table.concat(parts, ", ")
                    end,
                })
                resItem.FocusKey = "res:" .. instanceRoot:GetID()
                resItem:SetFocusSound(HOVER_SOUND)

                local selectedOutcome = 0

                local aVoteText = vote1Label and vote1Label:GetText() or ""
                local bVoteText = vote2Label and vote2Label:GetText() or ""
                local aVotes = tonumber(aVoteText:match("%d+")) or 0
                local bVotes = tonumber(bVoteText:match("%d+")) or 0
                if aVotes > 0 then
                    selectedOutcome = 1
                elseif bVotes > 0 then
                    selectedOutcome = 2
                end

                local favoredTip = BuildFavorTooltip(favoredContainer)
                local disfavoredTip = BuildFavorTooltip(disfavoredContainer)

                local effectA = effectCtrl1 and effectCtrl1:GetText() or ""
                local effectB = effectCtrl2 and effectCtrl2:GetText() or ""
                local outcomeDropdown = mgr:CreateWidget(
                    mgr:GenerateWidgetId("CAIWC_ResOut"), "Dropdown", {
                        Label = function()
                            return Locale.Lookup("LOC_CAI_WC_OUTCOME_LABEL")
                        end,
                    })
                outcomeDropdown:SetOptions({
                    {
                        label = Locale.Lookup("LOC_WORLD_CONGRESS_SELECT_AN_OUTCOME"),
                        value = 0,
                    },
                    {
                        label = Locale.Lookup("LOC_CAI_WC_OPTION_A") .. ": " .. effectA,
                        value = 1,
                        tooltip = favoredTip,
                    },
                    {
                        label = Locale.Lookup("LOC_CAI_WC_OPTION_B") .. ": " .. effectB,
                        value = 2,
                        tooltip = disfavoredTip,
                    },
                })
                if selectedOutcome == 1 then
                    outcomeDropdown:SetSelectedIndex(2, true)
                elseif selectedOutcome == 2 then
                    outcomeDropdown:SetSelectedIndex(3, true)
                else
                    outcomeDropdown:SetSelectedIndex(1, true)
                end
                outcomeDropdown:SetFocusSound(HOVER_SOUND)
                outcomeDropdown:On("value_changed", function(_, value)
                    selectedOutcome = value
                    if mgr then mgr:Refocus() end
                end)
                resItem:AddChild(outcomeDropdown)

                local function GetResVoteState()
                    local lbl = selectedOutcome == 1 and vote1Label
                        or selectedOutcome == 2 and vote2Label or nil
                    local text = lbl and lbl:GetText() or "0"
                    local votes = tonumber(text:match("%d+")) or 0
                    local costLbl = selectedOutcome == 1 and FindChildDeep(vote1Root, "Cost")
                        or selectedOutcome == 2 and FindChildDeep(vote2Root, "Cost") or nil
                    local costText = costLbl and costLbl:GetText() or ""
                    local cost = tonumber(costText:match("%d+")) or 0
                    return votes, cost
                end

                local function BuildResVoteTooltip(vanillaBtn)
                    local parts = {}
                    local tip = vanillaBtn and vanillaBtn:GetToolTipString() or ""
                    if tip ~= "" then table.insert(parts, tip) end
                    local votes, cost = GetResVoteState()
                    if votes > 0 then
                        table.insert(parts, Locale.Lookup("LOC_CAI_WC_CURRENT_VOTES", votes, cost))
                    end
                    return table.concat(parts, ", ")
                end

                local addVoteBtn = mgr:CreateWidget(
                    mgr:GenerateWidgetId("CAIWC_ResAdd"), "Button", {
                        Label = function()
                            if selectedOutcome == 1 then
                                return Locale.Lookup("LOC_CAI_WC_ADD_VOTE_A")
                            end
                            if selectedOutcome == 2 then
                                return Locale.Lookup("LOC_CAI_WC_ADD_VOTE_B")
                            end
                            return Locale.Lookup("LOC_CAI_WC_ADD_VOTE")
                        end,
                        Tooltip = function()
                            if selectedOutcome == 1 then
                                return BuildResVoteTooltip(vote1UpBtn)
                            end
                            if selectedOutcome == 2 then
                                return BuildResVoteTooltip(vote2UpBtn)
                            end
                            return ""
                        end,
                    })
                addVoteBtn:SetDisabledPredicate(function()
                    if selectedOutcome == 1 then
                        return vote1UpBtn and vote1UpBtn:IsDisabled()
                    end
                    if selectedOutcome == 2 then
                        return vote2UpBtn and vote2UpBtn:IsDisabled()
                    end
                    return true
                end)
                addVoteBtn:SetFocusSound(HOVER_SOUND)
                addVoteBtn:On("activate", function()
                    local _, prevCost = GetResVoteState()
                    local upBtn
                    if selectedOutcome == 1 then
                        upBtn = vote1UpBtn
                    elseif selectedOutcome == 2 then
                        upBtn = vote2UpBtn
                    end
                    if upBtn then upBtn:DoLeftClick() end
                    local _, newCost = GetResVoteState()
                    Speak(Locale.Lookup("LOC_CAI_WC_VOTE_ADDED", newCost - prevCost))
                end)
                resItem:AddChild(addVoteBtn)

                local removeVoteBtn = mgr:CreateWidget(
                    mgr:GenerateWidgetId("CAIWC_ResRem"), "Button", {
                        Label = function()
                            if selectedOutcome == 1 then
                                return Locale.Lookup("LOC_CAI_WC_REMOVE_VOTE_A")
                            end
                            if selectedOutcome == 2 then
                                return Locale.Lookup("LOC_CAI_WC_REMOVE_VOTE_B")
                            end
                            return Locale.Lookup("LOC_CAI_WC_REMOVE_VOTE")
                        end,
                        Tooltip = function()
                            if selectedOutcome == 1 then
                                return BuildResVoteTooltip(vote1DownBtn)
                            end
                            if selectedOutcome == 2 then
                                return BuildResVoteTooltip(vote2DownBtn)
                            end
                            return ""
                        end,
                    })
                removeVoteBtn:SetDisabledPredicate(function()
                    if selectedOutcome == 1 then
                        return vote1DownBtn and vote1DownBtn:IsDisabled()
                    end
                    if selectedOutcome == 2 then
                        return vote2DownBtn and vote2DownBtn:IsDisabled()
                    end
                    return true
                end)
                removeVoteBtn:SetFocusSound(HOVER_SOUND)
                removeVoteBtn:On("activate", function()
                    local _, prevCost = GetResVoteState()
                    local downBtn
                    if selectedOutcome == 1 then
                        downBtn = vote1DownBtn
                    elseif selectedOutcome == 2 then
                        downBtn = vote2DownBtn
                    end
                    if downBtn then downBtn:DoLeftClick() end
                    local _, newCost = GetResVoteState()
                    Speak(Locale.Lookup("LOC_CAI_WC_VOTE_REMOVED", prevCost - newCost))
                end)
                resItem:AddChild(removeVoteBtn)

                local targetOptions = BuildTargetOptions(kResolutionData)
                local targetDropdown = mgr:CreateWidget(
                    mgr:GenerateWidgetId("CAIWC_ResTgt"), "Dropdown", {
                        Label = function()
                            return Locale.Lookup("LOC_CAI_WC_TARGET_LABEL")
                        end,
                    })
                targetDropdown:SetFocusSound(HOVER_SOUND)
                targetDropdown:SetOptions(targetOptions)

                local initialTargetIdx = 1
                if selectedOutcome > 0 then
                    local choiceId = selectedOutcome == 1 and "Choice1" or "Choice2"
                    local choiceRoot = FindChildDeep(instanceRoot, choiceId)
                    if choiceRoot then
                        local pd = FindChildDeep(choiceRoot, "Pulldown")
                        local ppd = FindChildDeep(choiceRoot, "PlayerPulldown")
                        local activePd = pd and not pd:IsHidden() and pd or ppd
                        if activePd then
                            local btnText = activePd:GetButton():GetText() or ""
                            for i, opt in ipairs(targetOptions) do
                                if opt.label == btnText then
                                    initialTargetIdx = i
                                    break
                                end
                            end
                        end
                    end
                end
                targetDropdown:SetSelectedIndex(initialTargetIdx, true)

                local function HasResVotes()
                    local aText = vote1Label and vote1Label:GetText() or ""
                    local bText = vote2Label and vote2Label:GetText() or ""
                    local a = tonumber(aText:match("%d+")) or 0
                    local b = tonumber(bText:match("%d+")) or 0
                    return (a + b) > 0
                end
                targetDropdown:SetTooltip(function()
                    if not HasResVotes() then
                        return Locale.Lookup("LOC_CAI_WC_TARGET_VOTE_FIRST")
                    end
                    return ""
                end)
                targetDropdown:SetHiddenPredicate(function()
                    return selectedOutcome == 0 or #targetOptions <= 1
                end)
                targetDropdown:SetDisabledPredicate(function()
                    return not HasResVotes()
                end)
                targetDropdown:On("value_changed", function(_, value)
                    if value > 0 then
                        local idx = targetDropdown:GetSelectedIndex()
                        local opt = targetOptions[idx]
                        if opt then
                            ApplyTargetSelection(
                                instanceRoot, selectedOutcome, resHash,
                                opt.value, opt.label)
                        end
                    end
                    if mgr then mgr:Refocus() end
                end)
                resItem:AddChild(targetDropdown)

                m_body:AddChild(resItem)
            elseif titleCtrl and not vote1Root then
                local voteRoot = FindChildDeep(instanceRoot, "Vote")
                local selectBox = FindChildDeep(instanceRoot, "SelectBox")
                local descriptionCtrl = FindChildDeep(instanceRoot, "Description")

                if voteRoot then
                    local voteLabel = FindChildDeep(voteRoot, "Label")
                    local voteUpBtn = FindChildDeep(voteRoot, "UpButton")
                    local voteDownBtn = FindChildDeep(voteRoot, "DownButton")
                    local voteCostCtrl = FindChildDeep(voteRoot, "Cost")
                    local emergencyTip = BuildEmergencyTooltipText(instanceRoot)

                    local propItem = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWC_Prop"), "TreeItem", {
                        Label = function() return titleCtrl:GetText() or "" end,
                        Tooltip = function()
                            local parts = {}
                            local d = descriptionCtrl and descriptionCtrl:GetText() or ""
                            if d ~= "" then table.insert(parts, d) end
                            if emergencyTip ~= "" then table.insert(parts, emergencyTip) end
                            return table.concat(parts, ", ")
                        end,
                    })
                    propItem.FocusKey = "prop:" .. instanceRoot:GetID()
                    propItem:SetFocusSound(HOVER_SOUND)

                    local DIRECTION_SUPPORT = 1
                    local DIRECTION_OPPOSE = -1

                    local function GetPropVoteState()
                        local text = voteLabel and voteLabel:GetText() or "0"
                        local votes = tonumber(text:match("%d+")) or 0
                        local costText = voteCostCtrl and voteCostCtrl:GetText() or ""
                        local cost = tonumber(costText:match("%d+")) or 0
                        local direction = 0
                        if votes > 0 then
                            if text:find("ICON_VOTE_DOWN") then
                                direction = DIRECTION_OPPOSE
                            else
                                direction = DIRECTION_SUPPORT
                            end
                        end
                        return votes, cost, direction
                    end

                    if voteUpBtn then
                        local support = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWC_PropUp"), "Button", {
                            Label = function()
                                local _, _, dir = GetPropVoteState()
                                if dir == DIRECTION_OPPOSE then
                                    return Locale.Lookup("LOC_CAI_WC_REMOVE_VOTE")
                                end
                                return Locale.Lookup("LOC_CAI_WC_SUPPORT")
                            end,
                            Tooltip = function()
                                local parts = {}
                                local tip = voteUpBtn:GetToolTipString() or ""
                                if tip ~= "" then table.insert(parts, tip) end
                                local votes, cost, dir = GetPropVoteState()
                                if dir == DIRECTION_SUPPORT and votes > 0 then
                                    table.insert(parts, Locale.Lookup("LOC_CAI_WC_CURRENT_VOTES", votes, cost))
                                end
                                return table.concat(parts, ", ")
                            end,
                        })
                        support:SetFocusSound(HOVER_SOUND)
                        support:SetDisabledPredicate(function() return voteUpBtn:IsDisabled() end)
                        support:On("activate", function()
                            local prevVotes, prevCost = GetPropVoteState()
                            voteUpBtn:DoLeftClick()
                            local newVotes, newCost = GetPropVoteState()
                            if newVotes > prevVotes then
                                Speak(Locale.Lookup("LOC_CAI_WC_VOTE_ADDED", newCost - prevCost))
                            elseif newVotes < prevVotes then
                                Speak(Locale.Lookup("LOC_CAI_WC_VOTE_REMOVED", prevCost - newCost))
                            end
                        end)
                        propItem:AddChild(support)
                    end

                    if voteDownBtn then
                        local oppose = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWC_PropDn"), "Button", {
                            Label = function()
                                local _, _, dir = GetPropVoteState()
                                if dir == DIRECTION_SUPPORT then
                                    return Locale.Lookup("LOC_CAI_WC_REMOVE_VOTE")
                                end
                                return Locale.Lookup("LOC_CAI_WC_OPPOSE")
                            end,
                            Tooltip = function()
                                local parts = {}
                                local tip = voteDownBtn:GetToolTipString() or ""
                                if tip ~= "" then table.insert(parts, tip) end
                                local votes, cost, dir = GetPropVoteState()
                                if dir == DIRECTION_OPPOSE and votes > 0 then
                                    table.insert(parts, Locale.Lookup("LOC_CAI_WC_CURRENT_VOTES", votes, cost))
                                end
                                return table.concat(parts, ", ")
                            end,
                        })
                        oppose:SetFocusSound(HOVER_SOUND)
                        oppose:SetDisabledPredicate(function() return voteDownBtn:IsDisabled() end)
                        oppose:On("activate", function()
                            local prevVotes, prevCost = GetPropVoteState()
                            voteDownBtn:DoLeftClick()
                            local newVotes, newCost = GetPropVoteState()
                            if newVotes > prevVotes then
                                Speak(Locale.Lookup("LOC_CAI_WC_VOTE_ADDED", newCost - prevCost))
                            elseif newVotes < prevVotes then
                                Speak(Locale.Lookup("LOC_CAI_WC_VOTE_REMOVED", prevCost - newCost))
                            end
                        end)
                        propItem:AddChild(oppose)
                    end

                    local turnsLeftCtrl = FindChildDeep(instanceRoot, "TurnsLeft")
                    if turnsLeftCtrl then
                        local tl = turnsLeftCtrl:GetText()
                        if tl and tl ~= "" then
                            local tlWidget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWC_TL"), "StaticText", {
                                Label = function() return turnsLeftCtrl:GetText() or "" end,
                                Tooltip = function() return turnsLeftCtrl:GetToolTipString() or "" end,
                            })
                            tlWidget:SetFocusSound(HOVER_SOUND)
                            propItem:AddChild(tlWidget)
                        end
                    end

                    m_body:AddChild(propItem)
                elseif selectBox then
                    local emergencyTip = BuildEmergencyTooltipText(instanceRoot)
                    local propItem = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWC_EProp"), "Checkbox", {
                        Label = function()
                            local title = titleCtrl:GetText() or ""
                            local desc = descriptionCtrl and descriptionCtrl:GetText() or ""
                            if desc ~= "" then return title .. ": " .. desc end
                            return title
                        end,
                        Tooltip = function()
                            local parts = {}
                            local stip = selectBox:GetToolTipString() or ""
                            if stip ~= "" then table.insert(parts, stip) end
                            if emergencyTip ~= "" then table.insert(parts, emergencyTip) end
                            return table.concat(parts, ", ")
                        end,
                    })
                    propItem:SetValueGetter(function() return selectBox:IsSelected() end)
                    propItem:SetDisabledPredicate(function() return selectBox:IsDisabled() end)
                    propItem:On("value_changed", function()
                        selectBox:DoLeftClick()
                        if mgr then mgr:Refocus() end
                    end)
                    propItem.FocusKey = "emergency:" .. instanceRoot:GetID()
                    propItem:SetFocusSound(HOVER_SOUND)
                    m_body:AddChild(propItem)
                else
                    m_categoryTitle = titleCtrl
                    m_categoryCost = FindChildDeep(instanceRoot, "Cost")
                end
            end
        end
    end

    InsertBody()
end

-- =========================================================================
-- Phase 2: Build confirmation dialog pushed on top of the main panel
-- =========================================================================
local function BuildConfirmationDialog()
    DismissConfirmDialog()

    local contentRows = {}

    local resStack = Controls.ReviewResolutionStack
    if resStack then
        for _, instanceRoot in ipairs(resStack:GetChildren() or {}) do
            if not instanceRoot:IsHidden() then
                local titleCtrl = FindChildDeep(instanceRoot, "Title")
                local choiceLabel = FindChildDeep(instanceRoot, "ChoiceLabel")
                local chosenThing = FindChildDeep(instanceRoot, "ChosenThing")
                local targetLabel = FindChildDeep(instanceRoot, "TargetLabel")
                local costCtrl = FindChildDeep(instanceRoot, "Cost")
                local descCtrl = FindChildDeep(instanceRoot, "Description")

                if titleCtrl then
                    local row = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWC_ConfRes"), "StaticText", {
                        Label = function()
                            local parts = { titleCtrl:GetText() or "" }
                            if choiceLabel and choiceLabel:GetText() ~= "" then
                                table.insert(parts, choiceLabel:GetText())
                            end
                            if chosenThing and chosenThing:GetText() ~= "" then
                                local tl = targetLabel and targetLabel:GetText() or ""
                                if tl ~= "" then
                                    table.insert(parts, tl .. " " .. chosenThing:GetText())
                                else
                                    table.insert(parts, chosenThing:GetText())
                                end
                            end
                            if costCtrl and costCtrl:GetText() ~= "" then
                                table.insert(parts, Locale.Lookup("LOC_CAI_WC_COST_LABEL")
                                    .. " " .. costCtrl:GetText())
                            end
                            return table.concat(parts, ", ")
                        end,
                        Tooltip = function()
                            return descCtrl and descCtrl:GetText() or ""
                        end,
                    })
                    row:SetFocusSound(HOVER_SOUND)
                    table.insert(contentRows, row)
                end
            end
        end
    end

    local propStack = Controls.ReviewProposalStack
    if propStack then
        for _, instanceRoot in ipairs(propStack:GetChildren() or {}) do
            if not instanceRoot:IsHidden() then
                local titleCtrl = FindChildDeep(instanceRoot, "Title")
                local isCategoryTitle = titleCtrl
                    and not FindChildDeep(instanceRoot, "SelectBox")
                    and not FindChildDeep(instanceRoot, "UpVoteStack")
                    and not FindChildDeep(instanceRoot, "DownVoteStack")
                    and not FindChildDeep(instanceRoot, "ExpandButton")
                if titleCtrl and not isCategoryTitle then
                    local descCtrl = FindChildDeep(instanceRoot, "Description")
                    local costCtrl = FindChildDeep(instanceRoot, "Cost")
                    local upVoteStack = FindChildDeep(instanceRoot, "UpVoteStack")
                    local downVoteStack = FindChildDeep(instanceRoot, "DownVoteStack")
                    local upVoteLabel = FindChildDeep(instanceRoot, "UpVoteLabel")
                    local downVoteLabel = FindChildDeep(instanceRoot, "DownVoteLabel")

                    local row = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWC_ConfProp"), "StaticText", {
                        Label = function()
                            local parts = { titleCtrl:GetText() or "" }
                            if upVoteStack and not upVoteStack:IsHidden() then
                                local count = upVoteLabel and upVoteLabel:GetText() or ""
                                table.insert(parts, Locale.Lookup("LOC_CAI_WC_SUPPORT_VOTES", count))
                            elseif downVoteStack and not downVoteStack:IsHidden() then
                                local count = downVoteLabel and downVoteLabel:GetText() or ""
                                table.insert(parts, Locale.Lookup("LOC_CAI_WC_OPPOSE_VOTES", count))
                            end
                            if costCtrl and costCtrl:GetText() ~= "" then
                                table.insert(parts, Locale.Lookup("LOC_CAI_WC_COST_LABEL")
                                    .. " " .. costCtrl:GetText())
                            end
                            return table.concat(parts, ", ")
                        end,
                        Tooltip = function()
                            return descCtrl and descCtrl:GetText() or ""
                        end,
                    })
                    row:SetFocusSound(HOVER_SOUND)
                    table.insert(contentRows, row)
                end
            end
        end
    end

    local prevBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWC_ConfPrev"), "Button", {
        Label = function() return Controls.PrevButton:GetText() or "" end,
    })
    prevBtn:SetFocusSound(HOVER_SOUND)
    prevBtn:On("activate", function() Controls.PrevButton:DoLeftClick() end)

    local submitBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWC_ConfSubmit"), "Button", {
        Label = function() return Controls.AcceptButton:GetText() or "" end,
        Tooltip = function() return Controls.AcceptButton:GetToolTipString() or "" end,
    })
    submitBtn:SetFocusSound(HOVER_SOUND)
    submitBtn:SetDisabledPredicate(function() return Controls.AcceptButton:IsDisabled() end)
    submitBtn:On("activate", function() Controls.AcceptButton:DoLeftClick() end)

    m_confirmDialog = mgr.WidgetHelpers.MakeGeneralDialog(
        function() return Controls.Description:GetText() or "" end,
        { prevBtn, submitBtn },
        contentRows,
        2
    )

    if m_confirmDialog then
        mgr:Push(m_confirmDialog, { priority = PopupPriority.Current })
    end
end

-- =========================================================================
-- Build a lookup table of review resolution data keyed by uppercased name
-- =========================================================================
local function BuildReviewResolutionLookup()
    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID < 0 then return {} end
    local ok, kReviewData = pcall(function()
        return Game.GetWorldCongress():GetReview(localPlayerID)
    end)
    if not ok or not kReviewData or not kReviewData.Resolutions then return {} end
    local lookup = {}
    for _, v in pairs(kReviewData.Resolutions) do
        if type(v) == "table" and v.Type then
            local kRes = GameInfo.Resolutions[v.Type]
            if kRes then
                local name = Locale.ToUpper(Locale.Lookup(kRes.Name))
                lookup[name] = v
            end
        end
    end
    return lookup
end

-- =========================================================================
-- Resolve a voter's target to a display string
-- =========================================================================
local function ResolveVoterTarget(targetType, rawTarget)
    if not rawTarget then return "" end
    if targetType == "PlayerType" then
        local pid = tonumber(rawTarget)
        if pid and pid ~= -1 then
            return GetVisiblePlayerName(pid)
        end
        return ""
    end
    return Locale.Lookup(rawTarget)
end

-- =========================================================================
-- Walk ReviewResolutionStack and build TreeItem children from live controls
-- =========================================================================
local function PopulateReviewResolutions(parent)
    local resStack = Controls.ReviewResolutionStack
    if not resStack then return end

    local reviewLookup = BuildReviewResolutionLookup()

    for _, instanceRoot in ipairs(resStack:GetChildren() or {}) do
        if not instanceRoot:IsHidden() then
            local titleCtrl = FindChildDeep(instanceRoot, "Title")
            if titleCtrl then
                local statusCtrl = FindChildDeep(instanceRoot, "Status")
                local choiceLabel = FindChildDeep(instanceRoot, "ChoiceLabel")
                local descCtrl = FindChildDeep(instanceRoot, "Description")
                local targetLabel = FindChildDeep(instanceRoot, "TargetLabel")
                local chosenThing = FindChildDeep(instanceRoot, "ChosenThing")
                local costCtrl = FindChildDeep(instanceRoot, "Cost")
                local turnsLeftCtrl = FindChildDeep(instanceRoot, "TurnsLeft")
                local expandButton = FindChildDeep(instanceRoot, "ExpandButton")
                local isNew = IsNewVisible(instanceRoot)
                local turnsText = turnsLeftCtrl and turnsLeftCtrl:GetText() or ""
                local isActiveEffect = turnsText ~= ""

                if isActiveEffect then
                    local turns = tonumber(turnsText:match("%d+")) or 0
                    local effectWidget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWC_RevRes"), "StaticText", {
                        Label = function()
                            local prefix = isNew and Locale.Lookup("LOC_CAI_WC_NEW") or ""
                            local title = titleCtrl:GetText() or ""
                            local expiry = Locale.Lookup("LOC_CAI_WC_EXPIRES_TURNS", turns)
                            return prefix .. title .. ", " .. expiry
                        end,
                        Tooltip = function()
                            local parts = {}
                            local cl = choiceLabel and choiceLabel:GetText() or ""
                            if cl ~= "" then table.insert(parts, cl) end
                            local tgt = chosenThing and chosenThing:GetText() or ""
                            if tgt ~= "" then
                                local tl = targetLabel and targetLabel:GetText() or ""
                                table.insert(parts, tl .. " " .. tgt)
                            end
                            local desc = descCtrl and descCtrl:GetText() or ""
                            if desc ~= "" then table.insert(parts, desc) end
                            return table.concat(parts, ", ")
                        end,
                    })
                    effectWidget:SetFocusSound(HOVER_SOUND)
                    parent:AddChild(effectWidget)
                else
                    local resItem = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWC_RevRes"), "TreeItem", {
                        Label = function()
                            local prefix = isNew and Locale.Lookup("LOC_CAI_WC_NEW") or ""
                            local title = titleCtrl:GetText() or ""
                            local status = statusCtrl and statusCtrl:GetText() or ""
                            if status ~= "" then return prefix .. title .. ", " .. status end
                            return prefix .. title
                        end,
                        Tooltip = function() return statusCtrl and statusCtrl:GetToolTipString() or "" end,
                    })
                    resItem.FocusKey = "revres:" .. instanceRoot:GetID()
                    resItem:SetFocusSound(HOVER_SOUND)

                    if choiceLabel then
                        local cl = choiceLabel:GetText()
                        if cl and cl ~= "" then
                            local outWidget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWC_RevOut"), "StaticText", {
                                Label = function() return choiceLabel:GetText() or "" end,
                                Tooltip = function() return descCtrl and descCtrl:GetText() or "" end,
                            })
                            outWidget:SetFocusSound(HOVER_SOUND)
                            resItem:AddChild(outWidget)
                        end
                    end

                    if chosenThing then
                        local ct = chosenThing:GetText()
                        if ct and ct ~= "" then
                            local tgtWidget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWC_RevTgt"), "StaticText", {
                                Label = function()
                                    return (targetLabel and targetLabel:GetText() or "") ..
                                        " " .. (chosenThing:GetText() or "")
                                end,
                            })
                            tgtWidget:SetFocusSound(HOVER_SOUND)
                            resItem:AddChild(tgtWidget)
                        end
                    end

                    local titleText = titleCtrl:GetText() or ""
                    local kResData = reviewLookup[titleText]
                    if kResData and kResData.RejectedLabel then
                        local rejWidget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWC_Rej"), "StaticText", {
                            Label = function()
                                return Locale.Lookup("LOC_WORLD_CONGRESS_REVIEW_PROPOSAL_REJECTED_OUTCOME",
                                    kResData.RejectedLabel)
                            end,
                            Tooltip = function()
                                return kResData.RejectedOption
                                    and Locale.Lookup(kResData.RejectedOption) or ""
                            end,
                        })
                        rejWidget:SetFocusSound(HOVER_SOUND)
                        resItem:AddChild(rejWidget)
                    end

                    local upVoteStack = FindChildDeep(instanceRoot, "UpVoteStack")
                    local downVoteStack = FindChildDeep(instanceRoot, "DownVoteStack")
                    local upVoteIcon = FindChildDeep(instanceRoot, "UpVoteIcon")
                    local downVoteIcon = FindChildDeep(instanceRoot, "DownVoteIcon")
                    local hasUp = upVoteStack and not upVoteStack:IsHidden()
                    local hasDown = downVoteStack and not downVoteStack:IsHidden()
                    if hasUp or hasDown then
                        local votesNode = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWC_RevVotes"), "TreeItem", {
                            Label = function()
                                local parts = {}
                                if hasDown and downVoteIcon then
                                    local t = downVoteIcon:GetToolTipString()
                                    if t and t ~= "" then table.insert(parts, t) end
                                end
                                if hasUp and upVoteIcon then
                                    local t = upVoteIcon:GetToolTipString()
                                    if t and t ~= "" then table.insert(parts, t) end
                                end
                                return table.concat(parts, " ")
                            end,
                        })
                        votesNode:SetFocusSound(HOVER_SOUND)

                        if kResData and kResData.PlayerSelections then
                            for _, kData in pairs(kResData.PlayerSelections) do
                                local playerID = tonumber(kData.PlayerID)
                                local playerName = GetVisiblePlayerName(playerID)
                                local optionChosen = kData.OptionChosen
                                local votes = kData.Votes or 0
                                local targetText = ResolveVoterTarget(
                                    kResData.TargetType, kData.ResolutionTarget)
                                local voterWidget = mgr:CreateWidget(
                                    mgr:GenerateWidgetId("CAIWC_Voter"), "StaticText", {
                                        Label = function()
                                            local parts = {}
                                            if optionChosen == 1 then
                                                table.insert(parts, Locale.Lookup(
                                                    "LOC_WORLD_CONGRESS_REVIEW_A_VOTES_PLAYER_TT",
                                                    playerName, votes))
                                            else
                                                table.insert(parts, Locale.Lookup(
                                                    "LOC_WORLD_CONGRESS_REVIEW_B_VOTES_PLAYER_TT",
                                                    playerName, votes))
                                            end
                                            if targetText ~= "" then
                                                table.insert(parts, targetText)
                                            end
                                            return table.concat(parts, " ")
                                        end,
                                    })
                                voterWidget:SetFocusSound(HOVER_SOUND)
                                votesNode:AddChild(voterWidget)
                            end
                        end

                        resItem:AddChild(votesNode)
                    end

                    if costCtrl and (costCtrl:GetText() or "") ~= "" then
                        local costWidget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWC_RevCost"), "StaticText", {
                            Label = function() return costCtrl:GetText() or "" end,
                            Tooltip = function() return costCtrl:GetToolTipString() or "" end,
                        })
                        costWidget:SetFocusSound(HOVER_SOUND)
                        resItem:AddChild(costWidget)
                    end

                    parent:AddChild(resItem)
                end
            end
        end
    end
end

-- =========================================================================
-- Walk ReviewProposalStack and build children from live controls.
-- When m_activeSection == 2 (active effects), renders flat StaticText.
-- Otherwise renders TreeItems with per-player vote breakdown.
-- =========================================================================
local function PopulateReviewProposals(parent)
    local propStack = Controls.ReviewProposalStack
    if not propStack then return end

    local isEffects = m_activeSection == 2
    local currentCategoryName = ""

    for _, instanceRoot in ipairs(propStack:GetChildren() or {}) do
        if not instanceRoot:IsHidden() then
            local titleCtrl = FindChildDeep(instanceRoot, "Title")
            if titleCtrl then
                local expandButton = FindChildDeep(instanceRoot, "ExpandButton")
                local upVoteStack = FindChildDeep(instanceRoot, "UpVoteStack")
                local downVoteStack = FindChildDeep(instanceRoot, "DownVoteStack")
                local isCategoryTitle = not FindChildDeep(instanceRoot, "SelectBox")
                    and not upVoteStack and not downVoteStack and not expandButton

                if isCategoryTitle then
                    currentCategoryName = titleCtrl:GetText() or ""
                else
                    local myCategoryName = currentCategoryName
                    local statusCtrl = FindChildDeep(instanceRoot, "Status")
                    local descCtrl = FindChildDeep(instanceRoot, "Description")
                    local isNew = IsNewVisible(instanceRoot)
                    local emergencyTip = BuildEmergencyTooltipText(instanceRoot)

                    if isEffects then
                        local turnsLeftCtrl = FindChildDeep(instanceRoot, "TurnsLeft")
                        local turns = 0
                        if turnsLeftCtrl then
                            turns = tonumber((turnsLeftCtrl:GetText() or ""):match("%d+")) or 0
                        end
                        local effPropWidget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWC_RevProp"), "StaticText", {
                            Label = function()
                                local prefix = isNew and Locale.Lookup("LOC_CAI_WC_NEW") or ""
                                local catPrefix = myCategoryName ~= "" and (myCategoryName .. ": ") or ""
                                local title = titleCtrl:GetText() or ""
                                local label = prefix .. catPrefix .. title
                                if turns > 0 then
                                    label = label .. ", " .. Locale.Lookup("LOC_CAI_WC_EXPIRES_TURNS", turns)
                                end
                                return label
                            end,
                            Tooltip = function()
                                local parts = {}
                                local desc = descCtrl and descCtrl:GetText() or ""
                                if desc ~= "" then table.insert(parts, desc) end
                                if emergencyTip ~= "" then table.insert(parts, emergencyTip) end
                                return table.concat(parts, ", ")
                            end,
                        })
                        effPropWidget:SetFocusSound(HOVER_SOUND)
                        parent:AddChild(effPropWidget)
                    else
                        local upVoteIcon = FindChildDeep(instanceRoot, "UpVoteIcon")
                        local downVoteIcon = FindChildDeep(instanceRoot, "DownVoteIcon")
                        local hasUp = upVoteStack and not upVoteStack:IsHidden()
                        local hasDown = downVoteStack and not downVoteStack:IsHidden()

                        local propItem = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWC_RevProp"), "TreeItem", {
                            Label = function()
                                local prefix = isNew and Locale.Lookup("LOC_CAI_WC_NEW") or ""
                                local catPrefix = myCategoryName ~= "" and (myCategoryName .. ": ") or ""
                                local title = titleCtrl:GetText() or ""
                                local status = statusCtrl and statusCtrl:GetText() or ""
                                local label = prefix .. catPrefix .. title
                                if status ~= "" then label = label .. ", " .. status end
                                return label
                            end,
                            Tooltip = function()
                                local parts = {}
                                local desc = descCtrl and descCtrl:GetText() or ""
                                if desc ~= "" then table.insert(parts, desc) end
                                if emergencyTip ~= "" then table.insert(parts, emergencyTip) end
                                return table.concat(parts, ", ")
                            end,
                        })
                        propItem.FocusKey = "revprop:" .. instanceRoot:GetID()
                        propItem:SetFocusSound(HOVER_SOUND)

                        if hasUp or hasDown then
                            local votesNode = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWC_RPVotes"), "TreeItem", {
                                Label = function()
                                    local parts = {}
                                    if hasUp and upVoteIcon then
                                        local t = upVoteIcon:GetToolTipString()
                                        if t and t ~= "" then table.insert(parts, t) end
                                    end
                                    if hasDown and downVoteIcon then
                                        local t = downVoteIcon:GetToolTipString()
                                        if t and t ~= "" then table.insert(parts, t) end
                                    end
                                    return table.concat(parts, " ")
                                end,
                            })
                            votesNode:SetFocusSound(HOVER_SOUND)

                            if expandButton and not expandButton:IsHidden() then
                                local voterStack = FindChildDeep(instanceRoot, "VoterStack")
                                if voterStack then
                                    for _, voterRoot in ipairs(voterStack:GetChildren() or {}) do
                                        if not voterRoot:IsHidden() then
                                            local vTitle = FindChild(voterRoot, "Title")
                                            if vTitle then
                                                local vReason = FindChild(voterRoot, "Reason")
                                                local vUpVoteIcon = FindChildDeep(voterRoot, "UpVoteIcon")
                                                local vDownVoteIcon = FindChildDeep(voterRoot, "DownVoteIcon")
                                                local vUpVoteStack = FindChildDeep(voterRoot, "UpVoteStack")
                                                local vDownVoteStack = FindChildDeep(voterRoot, "DownVoteStack")
                                                local pVoterWidget = mgr:CreateWidget(
                                                    mgr:GenerateWidgetId("CAIWC_PVoter"),
                                                    "StaticText", {
                                                    Label = function()
                                                        local parts = {}
                                                        if vUpVoteStack and not vUpVoteStack:IsHidden() and vUpVoteIcon then
                                                            local t = vUpVoteIcon:GetToolTipString()
                                                            if t and t ~= "" then table.insert(parts, t) end
                                                        end
                                                        if vDownVoteStack and not vDownVoteStack:IsHidden() and vDownVoteIcon then
                                                            local t = vDownVoteIcon:GetToolTipString()
                                                            if t and t ~= "" then table.insert(parts, t) end
                                                        end
                                                        if vReason then
                                                            local r = vReason:GetText()
                                                            if r and r ~= "" then table.insert(parts, r) end
                                                        end
                                                        return table.concat(parts, ", ")
                                                    end,
                                                })
                                                pVoterWidget:SetFocusSound(HOVER_SOUND)
                                                votesNode:AddChild(pVoterWidget)
                                            end
                                        end
                                    end
                                end
                            end

                            propItem:AddChild(votesNode)
                        end

                        parent:AddChild(propItem)
                    end
                end
            end
        end
    end
end

-- =========================================================================
-- Rebuild children of a review section from live vanilla controls
-- =========================================================================
local function RebuildSectionChildren(sectionItem)
    if not sectionItem then return end
    sectionItem:ClearChildren()
    PopulateReviewResolutions(sectionItem)
    PopulateReviewProposals(sectionItem)
end

-- =========================================================================
-- Switch review tab: tell vanilla to repopulate, then rebuild CAI children.
-- The m_isBuilding flag prevents wraps from re-entering BuildAndPush or
-- RebuildBody while OnWorldCongressResults runs SetStage(4) + ShowPopup.
-- =========================================================================
local function SwitchReviewTab(section)
    if m_activeSection == section then return end
    m_activeSection = section

    UI.PlaySound("WC_Exit")

    m_isBuilding = true
    if section == 1 then
        OnWorldCongressResults(CAI_TAB_RESULTS)
    elseif section == 2 then
        OnWorldCongressResults(CAI_TAB_EFFECTS)
    elseif section == 3 then
        OnWorldCongressResults(CAI_TAB_PROPOSALS)
    end
    m_isBuilding = false

    local sectionItem = section == 1 and m_resultsItem
        or section == 2 and m_effectsItem or nil
    if sectionItem and #sectionItem.Children == 0 then
        RebuildSectionChildren(sectionItem)
    end
end

-- =========================================================================
-- Build emergency proposals page from live controls
-- =========================================================================
local function BuildProposalsPage(page)
    page:ClearChildren()

    local proposalsList = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWC_ProposalsList"), "List", {
        Label = function() return Locale.Lookup("LOC_WORLD_CONGRESS_AVAILABLE_PROPOSALS") end,
    })

    local currentCategoryName = ""
    local propStack = Controls.ReviewProposalStack
    if propStack then
        for _, instanceRoot in ipairs(propStack:GetChildren() or {}) do
            if not instanceRoot:IsHidden() then
                local titleCtrl = FindChildDeep(instanceRoot, "Title")
                if titleCtrl then
                    local selectBox = FindChildDeep(instanceRoot, "SelectBox")
                    if selectBox then
                        local myCat = currentCategoryName
                        local descCtrl = FindChildDeep(instanceRoot, "Description")
                        local emergencyTip = BuildEmergencyTooltipText(instanceRoot)
                        local epItem = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWC_EPropTab"), "Checkbox", {
                            Label = function()
                                local title = titleCtrl:GetText() or ""
                                local catPrefix = myCat ~= "" and (myCat .. ": ") or ""
                                return catPrefix .. title
                            end,
                            Tooltip = function()
                                local parts = {}
                                local desc = descCtrl and descCtrl:GetText() or ""
                                if desc ~= "" then table.insert(parts, desc) end
                                if emergencyTip ~= "" then table.insert(parts, emergencyTip) end
                                local stip = selectBox:GetToolTipString() or ""
                                if stip ~= "" then table.insert(parts, stip) end
                                return table.concat(parts, ", ")
                            end,
                        })
                        epItem:SetValueGetter(function() return selectBox:IsSelected() end)
                        epItem:SetDisabledPredicate(function() return selectBox:IsDisabled() end)
                        epItem:On("value_changed", function()
                            selectBox:DoLeftClick()
                            if mgr then mgr:Refocus() end
                        end)
                        epItem.FocusKey = "emergency:" .. instanceRoot:GetID()
                        epItem:SetFocusSound(HOVER_SOUND)
                        proposalsList:AddChild(epItem)
                    else
                        currentCategoryName = titleCtrl:GetText() or ""
                    end
                end
            end
        end
    end

    page:AddChild(proposalsList)
    page:AddChild(MakeBtn(mgr:GenerateWidgetId("CAIWC_Accept"), Controls.AcceptButton, function() Controls.AcceptButton:DoLeftClick() end))
    page:AddChild(MakeBtn(mgr:GenerateWidgetId("CAIWC_Pass"), Controls.PassButton, function() Controls.PassButton:DoLeftClick() end))
end

-- =========================================================================
-- Detect which vanilla review tab is currently active
-- =========================================================================
local function DetectActiveTab()
    if not Controls.AvailableProposalsSelected:IsHidden() then return 3 end
    if not Controls.CurrentEffectsSelected:IsHidden() then return 2 end
    return 1
end

-- =========================================================================
-- Stage 4: Build review body. Always a TabControl; page 1 is the review
-- tree (Results + Effects sections), page 2 (proposals) added only when
-- emergency proposals exist. Vanilla has already populated the stacks for
-- the initial tab inside SetStage(4), so we read directly.
-- =========================================================================
local function BuildReviewBody()
    ClearBody()
    if not m_panel then return end

    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID < 0 then return end

    local hasProposals = HasEmergencyProposals()
    local initialTab = DetectActiveTab()

    m_body = mgr:CreateWidget(BODY_ID, "TabControl", {
        Label = function() return Controls.Title:GetText() or "" end,
    })

    -- Page 1: Review (Results + Effects)
    local reviewPage = m_body:AddPage(function()
        return Locale.Lookup("LOC_CAI_WC_REVIEW")
    end)

    local reviewTree = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWC_RevTree"), "Tree", {
        Label = function() return Controls.Title:GetText() or "" end,
    })

    local emptyLabel = Controls.EmptyLabel
    if emptyLabel and not emptyLabel:IsHidden() then
        local turnsInfo = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWC_TurnsInfo"), "StaticText", {
            Label = function() return emptyLabel:GetText() or "" end,
        })
        turnsInfo:SetFocusSound(HOVER_SOUND)
        reviewTree:AddChild(turnsInfo)
    end

    m_resultsItem = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWC_Results"), "TreeItem", {
        Label = function() return Locale.Lookup("LOC_WORLD_CONGRESS_LAST_SESSION_RESULTS") end,
        Tooltip = function()
            if m_activeSection == 1 then
                return Controls.Description and Controls.Description:GetText() or ""
            end
            return ""
        end,
    })
    m_resultsItem.FocusKey = "review:results"
    m_resultsItem:SetFocusSound(HOVER_SOUND)
    m_resultsItem:On("focus_enter", function() SwitchReviewTab(1) end)
    reviewTree:AddChild(m_resultsItem)

    m_effectsItem = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWC_Effects"), "TreeItem", {
        Label = function() return Locale.Lookup("LOC_WORLD_CONGRESS_ACTIVE_EFFECTS") end,
        Tooltip = function()
            if m_activeSection == 2 then
                return Controls.Description and Controls.Description:GetText() or ""
            end
            return ""
        end,
    })
    m_effectsItem.FocusKey = "review:effects"
    m_effectsItem:SetFocusSound(HOVER_SOUND)
    m_effectsItem:On("focus_enter", function() SwitchReviewTab(2) end)
    reviewTree:AddChild(m_effectsItem)

    reviewPage:AddChild(reviewTree)

    -- Page 2: Proposals (only when emergencies exist)
    local proposalsPage = nil
    if hasProposals then
        proposalsPage = m_body:AddPage(function()
            return Locale.Lookup("LOC_WORLD_CONGRESS_AVAILABLE_PROPOSALS")
        end)
    end

    m_body:On("value_changed", function(_, pageIndex)
        if m_isBuilding then return end
        if pageIndex == 1 then
            m_activeSection = 0
            SwitchReviewTab(1)
        elseif pageIndex == 2 and proposalsPage then
            SwitchReviewTab(3)
            BuildProposalsPage(proposalsPage)
        end
    end)

    if initialTab == 3 and proposalsPage then
        m_activeSection = 3
        BuildProposalsPage(proposalsPage)
        m_body:SetActivePage(2, true)
    else
        m_activeSection = initialTab == 2 and 2 or 1
        local sectionItem = m_activeSection == 2 and m_effectsItem or m_resultsItem
        RebuildSectionChildren(sectionItem)
    end

    InsertBody()
end

-- =========================================================================
-- Build the persistent shell panel
-- =========================================================================
local function BuildShell()
    if not mgr then return end
    RemovePanel()

    m_panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function() return Controls.Title:GetText() or "" end,
    })
end

-- =========================================================================
-- Build the full CAI widget tree and push
-- =========================================================================
local function BuildAndPush(stage, phase)
    m_isBuilding = true

    BuildShell()
    if not m_panel then
        m_isBuilding = false
        return
    end

    m_caiStage = stage
    m_caiPhase = phase

    if stage == 4 then
        BuildReviewBody()
    else
        BuildVotingBody()
    end

    BuildButtons()
    BuildLeaders()

    local diploBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWC_Diplo"), "Button", {
        Label = function() return Locale.Lookup("LOC_CAI_WC_OPEN_DIPLOMACY") end,
    })
    diploBtn:SetFocusSound(HOVER_SOUND)
    diploBtn:On("activate", function() Controls.DiploButton:DoLeftClick() end)
    m_panel:AddChild(diploBtn)

    if phase == 2 then
        BuildConfirmationDialog()
    end
    mgr:Push(m_panel, { priority = PopupPriority.WorldCongressPopup })

    m_isBuilding = false
end

-- =========================================================================
-- Rebuild the body section for stage/phase changes
-- =========================================================================
local function RebuildBody(stage, phase)
    if not m_panel then return end

    if phase == 2 then
        BuildConfirmationDialog()
        return
    end

    DismissConfirmDialog()
    local capture = m_body and mgr:CaptureFocusKey(m_body) or nil

    if stage == 4 then
        BuildReviewBody()
    else
        BuildVotingBody()
    end

    if capture and m_body then
        mgr:RestoreFocus(m_body, capture)
    end
end

-- =========================================================================
-- Wraps
-- =========================================================================
PopulateChoicePulldown = WrapFunc(PopulateChoicePulldown, function(orig, kResolutionChoice, kVoteData)
    orig(kResolutionChoice, kVoteData)
    if kResolutionChoice and kResolutionChoice.hash then
        m_capturedChoices[kResolutionChoice.hash] = kResolutionChoice
    end
end)

OnAccept = WrapFunc(OnAccept, function(orig)
    orig()
    m_caiStage = 0
    m_caiPhase = 0
end)

ShowPopup = WrapFunc(ShowPopup, function(orig, delayShow, fromHotLoad)
    if m_isBuilding then
        orig(delayShow, fromHotLoad)
        return
    end
    orig(delayShow, fromHotLoad)
    if not m_panel then
        BuildAndPush(m_caiStage, m_caiPhase)
    end
end)

ClosePopup = WrapFunc(ClosePopup, function(orig)
    RemovePanel()
    orig()
end)

SetPhase = WrapFunc(SetPhase, function(orig, phaseNum)
    if not m_isBuilding and phaseNum == 2 and m_body and m_caiPhase == 1 then
        m_phase1Capture = mgr:CaptureFocusKey(m_body)
    end

    local result = orig(phaseNum)

    if m_isBuilding then return result end

    if result ~= false then
        m_caiPhase = phaseNum
        if m_panel then
            RebuildBody(m_caiStage, phaseNum)
            if phaseNum == 1 and m_phase1Capture and m_body then
                mgr:RestoreFocus(m_body, m_phase1Capture)
                m_phase1Capture = nil
            end
        end
    end

    return result
end)

SetStage = WrapFunc(SetStage, function(orig, stageNum, beginCongress)
    local result = orig(stageNum, beginCongress)

    if m_isBuilding then return result end

    if result ~= false then
        m_caiStage = stageNum
        if stageNum == 4 then
            m_caiPhase = 0
        end
        if m_panel then
            RebuildBody(stageNum, m_caiPhase)
        end
    end

    return result
end)

PopulateLeaderStack = WrapFunc(PopulateLeaderStack, function(orig)
    orig()
    if m_panel and not m_isBuilding then
        BuildLeaders()
    end
end)

OnResumeCongress = WrapFunc(OnResumeCongress, function(orig)
    orig()
    if not ContextPtr:IsHidden() and not m_panel then
        BuildAndPush(m_caiStage, m_caiPhase)
    end
end)

UpdateWorkingFavor = WrapFunc(UpdateWorkingFavor, function(orig)
    orig()
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
    if mgr and m_panel and not ContextPtr:IsHidden() then
        local top = mgr:GetTop()
        if top == m_panel or top == m_confirmDialog then
            local handled = mgr:HandleInput(pInputStruct)
            if handled then return handled end
        end
    end
    return orig(pInputStruct)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)
