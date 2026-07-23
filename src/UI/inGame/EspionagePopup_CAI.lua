include("caiUtils")
include("EspionagePopup")

local mgr = ExposedMembers.CAI_UIManager

local m_dialog = nil ---@type UIWidget|nil
local m_caiOutcomeLines = {}
local m_spyCanPromote = false

local function Visible(control)
    return control ~= nil and (not control.IsHidden or not control:IsHidden())
end

local function Text(control)
    if control and control.GetText then
        local value = control:GetText()
        if value and value ~= "" then
            return value
        end
    end
    return nil
end

local function JoinNonEmpty(parts)
    local out = {}
    for _, part in ipairs(parts or {}) do
        if part and part ~= "" then
            table.insert(out, part)
        end
    end
    return table.concat(out, ", ")
end

local function LabelValue(label, value)
    if label and label ~= "" and value and value ~= "" then
        return label .. ": " .. value
    end
    return label or value
end

local function AddRow(rows, idPrefix, label, parts)
    local line = JoinNonEmpty(parts)
    if line == "" then return end

    local fullLine = JoinNonEmpty({ label, line })
    if fullLine == "" then return end

    table.insert(rows, mgr:CreateWidget(mgr:GenerateWidgetId(idPrefix), "StaticText", {
        Label = fullLine,
    }))
end

local function RemoveDialog()
    if not mgr or not m_dialog then return end
    mgr:RemoveFromStack(m_dialog:GetId())
    m_dialog = nil
end

local function MakeButton(native, idPrefix)
    local btn = mgr:CreateWidget(mgr:GenerateWidgetId(idPrefix), "Button", {
        Label = function() return Text(native) or "" end,
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
    if Visible(native) then
        table.insert(buttons, MakeButton(native, idPrefix))
    end
end

local function BuildObjectiveDurationRow(rows)
    local parts = {}
    if Visible(Controls.MissionObjectiveContainer) then
        table.insert(parts, Text(Controls.MissionObjectiveLabel))
    end
    if Visible(Controls.MissionDurationContainer) then
        table.insert(parts, Text(Controls.MissionDurationLabel))
    end

    AddRow(
        rows,
        "CAIEspionagePopupObjective",
        Locale.Lookup("LOC_ESPIONAGEPOPUP_MISSION_OBJECTIVE"),
        parts
    )
end

local function BuildPossibleOutcomesRow(rows)
    if not Visible(Controls.PossibleOutcomesContainer) then return end
    AddRow(
        rows,
        "CAIEspionagePopupOutcomes",
        Locale.Lookup("LOC_ESPIONAGEPOPUP_POSSIBLE_OUTCOMES"),
        m_caiOutcomeLines
    )
end

local function BuildMissionOutcomeRow(rows)
    if not Visible(Controls.MissionOutcomeContainer) then return end
    AddRow(
        rows,
        "CAIEspionagePopupOutcome",
        Locale.Lookup("LOC_ESPIONAGEPOPUP_MISSION_OUTCOME"),
        {
            Text(Controls.MissionOutcomeLabel),
            Text(Controls.MissionOutcomeDescription),
        }
    )
end

local function BuildRewardsRow(rows)
    if not Visible(Controls.MissionRewardsContainer) then return end

    local parts = {}

    if m_spyCanPromote then
        table.insert(parts, LabelValue(Text(Controls.SpyPromotionLabel), Text(Controls.SpyPromotionDescription)))
    end

    if Visible(Controls.SpyLootGrid) then
        table.insert(parts, LabelValue(Text(Controls.SpyLootRewardLabel), Text(Controls.SpyLootRewardDescription)))
    end

    AddRow(
        rows,
        "CAIEspionagePopupRewards",
        Locale.Lookup("LOC_ESPIONAGEPOPUP_REWARDS"),
        parts
    )
end

local function BuildConsequencesRow(rows)
    if not Visible(Controls.MissionConsequencesContainer) then return end

    local parts = {
        LabelValue(Text(Controls.RelationshipDamageTitle), Text(Controls.RelationshipDamageDescription)),
    }

    if Visible(Controls.LostAgentGrid) then
        table.insert(parts, LabelValue(Text(Controls.LostAgentTitle), Text(Controls.LostAgentDescription)))
    end

    AddRow(
        rows,
        "CAIEspionagePopupConsequences",
        Locale.Lookup("LOC_ESPIONAGEPOPUP_CONSEQUENCES"),
        parts
    )
end

local function BuildRenewableMissionRow(rows)
    if not Visible(Controls.RenewableMissionContainer) then return end

    local parts = {
        Text(Controls.RenewableMissionDetails),
    }

    local districtName = Text(Controls.MissionDistrictName)
    if districtName then
        table.insert(parts, Locale.Lookup("LOC_CAI_ESPIONAGE_MISSION_DISTRICT", districtName))
    end

    local turns = Text(Controls.TurnsToCompleteLabel)
    if turns then
        table.insert(parts, Locale.Lookup("LOC_CAI_ESPIONAGE_MISSION_TURNS", turns))
    end

    local probability = Text(Controls.ProbabilityLabel)
    if Visible(Controls.ProbabilityGrid) and probability then
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
    if not mgr or ContextPtr:IsHidden() then return end

    local buttons = BuildButtons()
    if #buttons == 0 then return end

    m_dialog = mgr.WidgetHelpers.MakeGeneralDialog(
        function() return Text(Controls.MissionTitle) or "" end,
        buttons,
        BuildContentRows(),
        1
    )
    if not m_dialog then return end

    mgr:Push(m_dialog, { priority = PopupPriority.Low })
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
    table.insert(m_caiOutcomeLines, JoinNonEmpty({ tostring(percent) .. "%", label }))
end)

AddOutcomeLabel = WrapFunc(AddOutcomeLabel, function(orig, labelString)
    orig(labelString)

    local label = labelString and Locale.Lookup(labelString) or nil
    if label and label ~= "" then
        table.insert(m_caiOutcomeLines, label)
    end
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
