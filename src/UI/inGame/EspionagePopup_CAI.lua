include("CAIControl")
include("caiUtils")
include("EspionagePopup")

local mgr = CAI:GetUIManager()

local m_dialog = nil ---@type UIWidget|nil
local m_caiOutcomeLines = {}
local m_spyCanPromote = false

local function AddRow(rows, idPrefix, label, parts)
    local line = CAIText.JoinLines(parts)
    if line == "" then return end

    local fullLine = CAIText.JoinLines({ label, line })
    if fullLine == "" then return end

    table.insert(rows, mgr:CreateWidget(mgr:GenerateWidgetId(idPrefix), "StaticText", {
        Label = fullLine,
    }))
end

local function RemoveDialog()
    if not mgr or not m_dialog then return end
    mgr:RemoveFromStack(m_dialog:GetId())
    m_dialog = nil
    -- Stop advertising this popup as a "keep above me" target for the chooser.
    if ExposedMembers then CAI.EspionagePopupDialogId = nil end
end

local function MakeButton(native, idPrefix)
    local btn = mgr:CreateWidget(mgr:GenerateWidgetId(idPrefix), "Button", {
        Label = function() return CAIControl.ReadText(native) or "" end,
        HiddenPredicate = function() return native == nil or native:IsHidden() end,
        DisabledPredicate = function() return native ~= nil and native:IsDisabled() end,
    })
    btn:On("activate", function()
        if native and not native:IsHidden() and not native:IsDisabled() then
            native:DoLeftClick()
        end
    end)
    return btn
end

local function AddVisibleButton(buttons, native, idPrefix)
    if CAIControl.IsVisible(native) then
        table.insert(buttons, MakeButton(native, idPrefix))
    end
end

local function BuildObjectiveDurationRow(rows)
    local parts = {}
    if CAIControl.IsVisible(Controls.MissionObjectiveContainer) then
        table.insert(parts, CAIControl.ReadText(Controls.MissionObjectiveLabel))
    end
    if CAIControl.IsVisible(Controls.MissionDurationContainer) then
        table.insert(parts, CAIControl.ReadText(Controls.MissionDurationLabel))
    end

    AddRow(
        rows,
        "CAIEspionagePopupObjective",
        Locale.Lookup("LOC_ESPIONAGEPOPUP_MISSION_OBJECTIVE"),
        parts
    )
end

local function BuildPossibleOutcomesRow(rows)
    if not CAIControl.IsVisible(Controls.PossibleOutcomesContainer) then return end
    AddRow(
        rows,
        "CAIEspionagePopupOutcomes",
        Locale.Lookup("LOC_ESPIONAGEPOPUP_POSSIBLE_OUTCOMES"),
        m_caiOutcomeLines
    )
end

local function BuildMissionOutcomeRow(rows)
    if not CAIControl.IsVisible(Controls.MissionOutcomeContainer) then return end
    AddRow(
        rows,
        "CAIEspionagePopupOutcome",
        Locale.Lookup("LOC_ESPIONAGEPOPUP_MISSION_OUTCOME"),
        {
            CAIControl.ReadText(Controls.MissionOutcomeLabel),
            CAIControl.ReadText(Controls.MissionOutcomeDescription),
        }
    )
end

local function BuildRewardsRow(rows)
    if not CAIControl.IsVisible(Controls.MissionRewardsContainer) then return end

    local parts = {}

    if m_spyCanPromote then
        table.insert(parts, CAIText.LabelValue(CAIControl.ReadText(Controls.SpyPromotionLabel), CAIControl.ReadText(Controls.SpyPromotionDescription)))
    end

    if CAIControl.IsVisible(Controls.SpyLootGrid) then
        table.insert(parts, CAIText.LabelValue(CAIControl.ReadText(Controls.SpyLootRewardLabel), CAIControl.ReadText(Controls.SpyLootRewardDescription)))
    end

    AddRow(
        rows,
        "CAIEspionagePopupRewards",
        Locale.Lookup("LOC_ESPIONAGEPOPUP_REWARDS"),
        parts
    )
end

local function BuildConsequencesRow(rows)
    if not CAIControl.IsVisible(Controls.MissionConsequencesContainer) then return end

    local parts = {
        CAIText.LabelValue(CAIControl.ReadText(Controls.RelationshipDamageTitle), CAIControl.ReadText(Controls.RelationshipDamageDescription)),
    }

    if CAIControl.IsVisible(Controls.LostAgentGrid) then
        table.insert(parts, CAIText.LabelValue(CAIControl.ReadText(Controls.LostAgentTitle), CAIControl.ReadText(Controls.LostAgentDescription)))
    end

    AddRow(
        rows,
        "CAIEspionagePopupConsequences",
        Locale.Lookup("LOC_ESPIONAGEPOPUP_CONSEQUENCES"),
        parts
    )
end

local function BuildRenewableMissionRow(rows)
    if not CAIControl.IsVisible(Controls.RenewableMissionContainer) then return end

    local parts = {
        CAIControl.ReadText(Controls.RenewableMissionDetails),
    }

    local districtName = CAIControl.ReadText(Controls.MissionDistrictName)
    if districtName then
        table.insert(parts, Locale.Lookup("LOC_CAI_ESPIONAGE_MISSION_DISTRICT", districtName))
    end

    local turns = CAIControl.ReadText(Controls.TurnsToCompleteLabel)
    if turns then
        table.insert(parts, Locale.Lookup("LOC_CAI_ESPIONAGE_MISSION_TURNS", turns))
    end

    local probability = CAIControl.ReadText(Controls.ProbabilityLabel)
    if CAIControl.IsVisible(Controls.ProbabilityGrid) and probability then
        table.insert(parts, Locale.Lookup("LOC_CAI_ESPIONAGE_MISSION_PROBABILITY", probability))
    end

    AddRow(
        rows,
        "CAIEspionagePopupRenewable",
        Locale.Lookup("LOC_ESPIONAGEPOPUP_MISSION_DETAILS"),
        parts
    )
end

local function BuildContentRows()
    local rows = {}
    BuildObjectiveDurationRow(rows)
    BuildPossibleOutcomesRow(rows)
    BuildMissionOutcomeRow(rows)
    BuildRewardsRow(rows)
    BuildConsequencesRow(rows)
    BuildRenewableMissionRow(rows)
    return rows
end

local function BuildButtons()
    local buttons = {}
    AddVisibleButton(buttons, Controls.AcceptButton, "CAIEspionagePopupAccept")
    AddVisibleButton(buttons, Controls.RenewButton, "CAIEspionagePopupRenew")
    AddVisibleButton(buttons, Controls.AbortButton, "CAIEspionagePopupAbort")
    AddVisibleButton(buttons, Controls.CancelButton, "CAIEspionagePopupCancel")
    AddVisibleButton(buttons, Controls.MissionSucceedButton, "CAIEspionagePopupSuccess")
    AddVisibleButton(buttons, Controls.MissionFailureButton, "CAIEspionagePopupFailure")
    return buttons
end

local function BuildDialog()
    RemoveDialog()
    if not mgr then return end

    local buttons = BuildButtons()
    if #buttons == 0 then return end

    m_dialog = mgr.WidgetHelpers.MakeGeneralDialog(
        function() return CAIControl.ReadText(Controls.MissionTitle) or "" end,
        buttons,
        BuildContentRows(),
        1
    )
    if not m_dialog then return end

    mgr:Push(m_dialog, { priority = PopupPriority.Low })
    -- Advertise this popup so a later-opening EspionageChooser drops below it
    -- instead of covering it (mission-completed popup opens before the chooser).
    if ExposedMembers then CAI.EspionagePopupDialogId = m_dialog:GetId() end
end

local function IsDialogActive()
    return mgr ~= nil and m_dialog ~= nil and mgr:GetTop() == m_dialog
end

RefreshPossibleOutcomes = WrapFunc(RefreshPossibleOutcomes, function(orig, ...)
    m_caiOutcomeLines = {}
    orig(...)
end)

AddOutcomePercent = WrapFunc(AddOutcomePercent, function(orig, percent, percentLabel)
    orig(percent, percentLabel)

    local label = percentLabel and Locale.Lookup(percentLabel) or nil
    table.insert(m_caiOutcomeLines, CAIText.JoinLines({ tostring(percent) .. "%", label }))
end)

AddOutcomeLabel = WrapFunc(AddOutcomeLabel, function(orig, labelString)
    orig(labelString)

    local label = labelString and Locale.Lookup(labelString) or nil
    CAIText.AppendIfNonEmpty(m_caiOutcomeLines, label)
end)

local function FindSpyByName(playerID, spyName)
    local pPlayer = Players[playerID]
    if not pPlayer then return nil end
    local playerUnits = pPlayer:GetUnits()
    if not playerUnits then return nil end
    for i, pUnit in playerUnits:Members() do
        if GameInfo.Units[pUnit:GetUnitType()].Spy and Locale.Lookup(pUnit:GetName()) == spyName then
            return pUnit
        end
    end
    return nil
end

local function CheckSpyPromotion(playerID, mission)
    m_spyCanPromote = false
    if not mission then return end
    local spyName = mission.Name and Locale.Lookup(mission.Name) or nil
    if not spyName then return end
    local pSpy = FindSpyByName(playerID, spyName)
    if not pSpy then return end
    local canStart, tResults = UnitManager.CanStartCommand(pSpy, UnitCommandTypes.PROMOTE, true, true)
    if canStart and tResults and tResults[UnitCommandResults.PROMOTIONS] and #tResults[UnitCommandResults.PROMOTIONS] > 0 then
        m_spyCanPromote = true
    end
end

ShowMissionCompletedPopup = WrapFunc(ShowMissionCompletedPopup, function(orig, playerID, missionID)
    local pPlayer = Players[playerID]
    local mission = nil
    if pPlayer then
        local pDiplomacy = pPlayer:GetDiplomacy()
        if pDiplomacy then
            mission = pDiplomacy:GetMission(playerID, missionID)
            if mission == 0 then mission = nil end
        end
    end
    CheckSpyPromotion(playerID, mission)
    orig(playerID, missionID)
end)

OnShowMissionBriefing = WrapFunc(OnShowMissionBriefing, function(orig, ...)
    m_spyCanPromote = false
    orig(...)
end)

OnShowMissionAbort = WrapFunc(OnShowMissionAbort, function(orig, ...)
    m_spyCanPromote = false
    orig(...)
end)

Open = WrapFunc(Open, function(orig, ...)
    orig(...)
    BuildDialog()
end)

Close = WrapFunc(Close, function(orig, ...)
    RemoveDialog()
    orig(...)
end)

OnShutdown = WrapFunc(OnShutdown, function(orig, ...)
    RemoveDialog()
    orig(...)
end)
ContextPtr:SetShutdown(OnShutdown)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
    if IsDialogActive() and not ContextPtr:IsHidden() then
        local handled = mgr:HandleInput(pInputStruct)
        if handled then return handled end
    end
    return orig(pInputStruct)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)
