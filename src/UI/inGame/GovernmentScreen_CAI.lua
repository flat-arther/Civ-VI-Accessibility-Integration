include("caiUtils")
include("GovernmentScreen")

local mgr                   = ExposedMembers.CAI_UIManager

local CAI_TAB_GOVERNMENTS   = 1
local CAI_TAB_POLICIES      = 2
local CAI_EMPTY_POLICY_TYPE = EMPTY_POLICY_TYPE or "empty"

local CAI_ROW_ORDER         = {
    { Index = ROW_INDEX and ROW_INDEX.MILITARY or 1, SlotType = "SLOT_MILITARY",   LabelControl = "LabelMilitary",   Tooltip = "LOC_GOVT_POLICY_TYPE_MILITARY",   Empty = "LOC_GOVT_NO_MILITARY_SLOTS" },
    { Index = ROW_INDEX and ROW_INDEX.ECONOMIC or 2, SlotType = "SLOT_ECONOMIC",   LabelControl = "LabelEconomic",   Tooltip = "LOC_GOVT_POLICY_TYPE_ECONOMIC",   Empty = "LOC_GOVT_NO_ECONOMIC_SLOTS" },
    { Index = ROW_INDEX and ROW_INDEX.DIPLOMAT or 3, SlotType = "SLOT_DIPLOMATIC", LabelControl = "LabelDiplomatic", Tooltip = "LOC_GOVT_POLICY_TYPE_DIPLOMATIC", Empty = "LOC_GOVT_NO_DIPLOMACY_SLOTS" },
    { Index = ROW_INDEX and ROW_INDEX.WILDCARD or 4, SlotType = "SLOT_WILDCARD",   LabelControl = "LabelWildcard",   Tooltip = "LOC_GOVT_POLICY_TYPE_WILDCARD",   Empty = "LOC_GOVT_NO_WILDCARD_SLOTS" },
}

local m_state               = {
    activeTab = CAI_TAB_GOVERNMENTS,
    slotPolicyTypes = {},
    isInternalVanillaRefresh = false,
    userSwitchedTab = false,
}

local m_ui                  = {
    panel = nil,
    tabBar = nil,
    tabs = {},
    policiesTree = nil,
    governmentsTree = nil,
    policyRows = {},
    policyRowLayouts = {},
    policySlotWidgets = {},
    policiesEditable = nil,
    picker = nil,
    allPoliciesTree = nil,
}

local function ControlText(control)
    if control and control.GetText then
        local text = control:GetText()
        if text and text ~= "" then return text end
    end
    if control and control.GetTextControl then
        local textControl = control:GetTextControl()
        if textControl and textControl.GetText then
            local text = textControl:GetText()
            if text and text ~= "" then return text end
        end
    end
    if control and control.GetTextButton then
        local textButton = control:GetTextButton()
        if textButton and textButton.GetText then
            local text = textButton:GetText()
            if text and text ~= "" then return text end
        end
    end
    if control and control.GetToolTipString then
        local text = control:GetToolTipString()
        if text and text ~= "" then return text end
    end
    return ""
end

local function JoinNonEmpty(parts, separator)
    local out = {}
    for _, part in ipairs(parts) do
        if part and part ~= "" then
            table.insert(out, part)
        end
    end
    return table.concat(out, separator)
end

local function ControlIsHidden(control)
    return control and control.IsHidden and control:IsHidden() or false
end

local function ControlIsDisabled(control)
    return control and control.IsDisabled and control:IsDisabled() or false
end

local function PlayGovernmentHoverSound()
    UI.PlaySound("Main_Menu_Mouse_Over")
end

local function GetLocalPlayerCulture()
    local playerID = Game and Game.GetLocalPlayer and Game.GetLocalPlayer() or -1
    if playerID == -1 then return nil end
    local player = Players[playerID]
    if not player or not player.GetCulture then return nil end
    return player:GetCulture()
end

local function GetRowInfo(rowIndex)
    for _, row in ipairs(CAI_ROW_ORDER) do
        if row.Index == rowIndex then return row end
    end
    return nil
end

local function GetRowIndexForSlotType(slotType)
    if slotType == "SLOT_GREAT_PERSON" then slotType = "SLOT_WILDCARD" end
    for _, row in ipairs(CAI_ROW_ORDER) do
        if row.SlotType == slotType then return row.Index end
    end
    return nil
end

local function GetRowName(rowIndex)
    local row = GetRowInfo(rowIndex)
    if not row then return "" end
    local label = ControlText(Controls[row.LabelControl])
    if label ~= "" then return label end
    return Locale.Lookup(row.Tooltip)
end

local function GetEmptyRowText(rowIndex)
    local row = GetRowInfo(rowIndex)
    if not row then return "" end
    return Locale.Lookup(row.Empty)
end

local function GetPolicyData(policyType)
    return policyType and GetPolicyFromCatalog(policyType) or nil
end

local function GetPolicyName(policyType)
    local policy = GetPolicyData(policyType)
    return policy and policy.Name or policyType or ""
end

local function GetPolicyDescription(policyType)
    local policy = GetPolicyData(policyType)
    return policy and policy.Description or ""
end

local function GetPolicySlotLabel(policyType)
    local policy = GetPolicyData(policyType)
    if not policy or not policy.SlotType then return "" end
    local rowIndex = GetRowIndexForSlotType(policy.SlotType)
    if rowIndex then return GetRowName(rowIndex) end
    return Locale.Lookup(policy.SlotType)
end

local function GetPolicyTooltip(policyType)
    return JoinNonEmpty({
        Locale.Lookup("LOC_CAI_GOVERNMENT_POLICY_TYPE", GetPolicySlotLabel(policyType)),
        Locale.Lookup("LOC_CAI_GOVERNMENT_DESCRIPTION", GetPolicyDescription(policyType)),
    }, "[NEWLINE]")
end

local function IsPolicyAvailableForPlayer(policyType)
    local policy = GetPolicyData(policyType)
    if not policy then return false end
    local culture = GetLocalPlayerCulture()
    if not culture then return false end
    if IsPolicyAvailable then
        return IsPolicyAvailable(culture, policy.PolicyHash)
    end
    return culture:IsPolicyUnlocked(policy.PolicyHash) and not culture:IsPolicyObsolete(policy.PolicyHash)
end

local function IsPolicyAssignableToRow(policyType, rowIndex)
    if not policyType or not rowIndex then return false end
    if IsPolicyTypeActive(policyType) then return false end
    return IsPolicyTypeLegalInRow(rowIndex, policyType)
end

local function SortPolicyTypes(a, b)
    local policyA = GetPolicyData(a)
    local policyB = GetPolicyData(b)
    local nameA = policyA and policyA.Name or a or ""
    local nameB = policyB and policyB.Name or b or ""
    return Locale.Compare(nameA, nameB) == -1
end

local function GetAllAvailablePolicyTypes()
    local policies = {}
    for row in GameInfo.Policies() do
        local policyType = row.PolicyType
        if policyType and GetPolicyData(policyType) and IsPolicyAvailableForPlayer(policyType) then
            table.insert(policies, policyType)
        end
    end
    table.sort(policies, SortPolicyTypes)
    return policies
end

local function SyncSlotPolicyTypesFromLive()
    m_state.slotPolicyTypes = {}

    local culture = GetLocalPlayerCulture()
    if not culture then return end

    local numSlots = culture:GetNumPolicySlots()
    for slotIndex = 0, numSlots - 1, 1 do
        local slotTypeIndex = culture:GetSlotType(slotIndex)
        local slotInfo = GameInfo.GovernmentSlots[slotTypeIndex]
        local rowIndex = slotInfo and GetRowIndexForSlotType(slotInfo.GovernmentSlotType) or nil
        if rowIndex then
            local policyType = CAI_EMPTY_POLICY_TYPE
            local policyID = culture:GetSlotPolicy(slotIndex)
            if policyID and policyID ~= -1 and GameInfo.Policies[policyID] then
                policyType = GameInfo.Policies[policyID].PolicyType
            end
            m_state.slotPolicyTypes[slotIndex] = policyType
        end
    end
end

local function GetPolicyTypeForSlot(slotIndex)
    if slotIndex == nil then return CAI_EMPTY_POLICY_TYPE end
    local policyType = m_state.slotPolicyTypes[slotIndex]
    if policyType ~= nil then return policyType end

    local culture = GetLocalPlayerCulture()
    if not culture then return CAI_EMPTY_POLICY_TYPE end
    local policyID = culture:GetSlotPolicy(slotIndex)
    if policyID and policyID ~= -1 and GameInfo.Policies[policyID] then
        return GameInfo.Policies[policyID].PolicyType
    end
    return CAI_EMPTY_POLICY_TYPE
end

local function GetLiveSlotDataForRow(rowIndex)
    local slots = {}
    local culture = GetLocalPlayerCulture()
    if not culture then return slots end

    local numSlots = culture:GetNumPolicySlots()
    for slotIndex = 0, numSlots - 1, 1 do
        local slotTypeIndex = culture:GetSlotType(slotIndex)
        local slotInfo = GameInfo.GovernmentSlots[slotTypeIndex]
        local slotRowIndex = slotInfo and GetRowIndexForSlotType(slotInfo.GovernmentSlotType) or nil
        if slotRowIndex == rowIndex then
            table.insert(slots, {
                SlotIndex = slotIndex,
                RowIndex = rowIndex,
            })
        end
    end

    return slots
end

local function GetPolicyRowSummaryFromSlots(slots)
    local used = 0
    local names = {}

    for _, slot in ipairs(slots) do
        if slot.PolicyType ~= CAI_EMPTY_POLICY_TYPE then
            used = used + 1
            table.insert(names, GetPolicyName(slot.PolicyType))
        end
    end

    local parts = {
        Locale.Lookup("LOC_CAI_GOVERNMENT_SLOTS_USED", used, #slots),
    }
    for _, name in ipairs(names) do
        table.insert(parts, name)
    end
    return table.concat(parts, ", ")
end

local function GetPolicyRowSummary(rowIndex)
    local slots = {}
    for slotOrdinal, slotData in ipairs(GetLiveSlotDataForRow(rowIndex)) do
        local policyType = GetPolicyTypeForSlot(slotData.SlotIndex)
        table.insert(slots, {
            SlotOrdinal = slotOrdinal,
            SlotIndex = slotData.SlotIndex,
            PolicyType = policyType,
        })
    end
    return GetPolicyRowSummaryFromSlots(slots)
end

local function GetPolicySlotWidgetBySlotIndex(slotIndex)
    if slotIndex == nil then return nil end
    return m_ui.policySlotWidgets and m_ui.policySlotWidgets[slotIndex] or nil
end

local function BuildPoliciesViewModel()
    local rows = {}

    for _, row in ipairs(CAI_ROW_ORDER) do
        local rowSlots = {}
        for slotOrdinal, slotData in ipairs(GetLiveSlotDataForRow(row.Index)) do
            local policyType = GetPolicyTypeForSlot(slotData.SlotIndex)
            table.insert(rowSlots, {
                SlotIndex = slotData.SlotIndex,
                RowIndex = row.Index,
                SlotOrdinal = slotOrdinal,
                PolicyType = policyType,
                Label = policyType == CAI_EMPTY_POLICY_TYPE and
                    Locale.Lookup("LOC_CAI_GOVERNMENT_EMPTY_SLOT", slotOrdinal) or
                    GetPolicyName(policyType),
                Tooltip = policyType == CAI_EMPTY_POLICY_TYPE and
                    Locale.Lookup("LOC_CAI_GOVERNMENT_EMPTY_SLOT", slotOrdinal) or
                    GetPolicyTooltip(policyType),
            })
        end

        table.insert(rows, {
            RowIndex = row.Index,
            Label = GetRowName(row.Index),
            Tooltip = GetPolicyRowSummaryFromSlots(rowSlots),
            EmptyText = GetEmptyRowText(row.Index),
            Slots = rowSlots,
        })
    end

    return rows
end

local function GetGovernmentSlotSummary(government)
    if not government then return "" end
    local parts = {}
    if government.NumSlotMilitary and government.NumSlotMilitary > 0 then
        table.insert(parts, tostring(government.NumSlotMilitary) .. " " .. ControlText(Controls.LabelMilitary))
    end
    if government.NumSlotEconomic and government.NumSlotEconomic > 0 then
        table.insert(parts, tostring(government.NumSlotEconomic) .. " " .. ControlText(Controls.LabelEconomic))
    end
    if government.NumSlotDiplomatic and government.NumSlotDiplomatic > 0 then
        table.insert(parts, tostring(government.NumSlotDiplomatic) .. " " .. ControlText(Controls.LabelDiplomatic))
    end
    if government.NumSlotWildcard and government.NumSlotWildcard > 0 then
        table.insert(parts, tostring(government.NumSlotWildcard) .. " " .. ControlText(Controls.LabelWildcard))
    end
    return table.concat(parts, ", ")
end

local function IsGovernmentUnlockedForPlayer(governmentType)
    local culture = GetLocalPlayerCulture()
    local government = g_kGovernments and g_kGovernments[governmentType] or nil
    if not culture or not government then return false end
    return culture:IsGovernmentUnlocked(government.Hash)
end

local function GetGovernmentStatusLine(governmentType)
    if IsGovernmentSelected(governmentType) then
        return Locale.Lookup("LOC_CAI_STATE_SELECTED")
    elseif not IsGovernmentUnlockedForPlayer(governmentType) then
        return Locale.Lookup("LOC_CAI_STATE_DISABLED")
    end
    return ""
end

local function GetGovernmentBonusIndex(governmentType)
    local govRow = GameInfo.Governments[governmentType]
    local bonusName = govRow and govRow.BonusType or nil
    if not bonusName or bonusName == "NO_GOVERNMENTBONUS" then return nil end
    local bonusRow = GameInfo.GovernmentBonusNames[bonusName]
    return bonusRow and bonusRow.Index or nil
end

local function GetCurrentGovernmentHeritageParts(governmentType)
    local parts = {}
    local culture = GetLocalPlayerCulture()
    if not culture then return parts end

    local bonusIndex = GetGovernmentBonusIndex(governmentType)
    if not bonusIndex then return parts end

    local government = g_kGovernments and g_kGovernments[governmentType] or nil
    local flat = culture:GetFlatBonus(bonusIndex)
    local accumulated = culture:GetIncrementingBonus(bonusIndex)
    local increment = culture:GetIncrementingBonusIncrement(bonusIndex)
    local turnsTillNext = culture:GetIncrementingBonusTurnsUntilNext(bonusIndex)

    if flat and flat > 0 then
        table.insert(parts, Locale.Lookup("LOC_CAI_GOVERNMENT_FLAT_BONUS", flat))
    end
    if accumulated and accumulated > 0 then
        table.insert(parts, Locale.Lookup("LOC_CAI_GOVERNMENT_LEGACY_BONUS", accumulated))
    end
    if increment and increment > 0 and government then
        local nextDesc = Locale.Lookup("LOC_GOVT_HERITAGE_BONUS_NEXT", turnsTillNext or 0,
            Locale.Lookup(government.Name))
        table.insert(parts, "+" .. tostring(increment) .. " " .. nextDesc)
    end

    return parts
end

local function GetCarryoverBonusParts(currentGovernmentType)
    local parts = {}
    local culture = GetLocalPlayerCulture()
    if not culture then return parts end

    for governmentType, government in pairs(g_kGovernments or {}) do
        if governmentType ~= currentGovernmentType then
            local bonusIndex = GetGovernmentBonusIndex(governmentType)
            if bonusIndex then
                local stored = culture:GetIncrementingBonus(bonusIndex)
                if stored and stored > 0 then
                    table.insert(parts,
                        "+" .. tostring(stored) .. " " ..
                        Locale.Lookup("LOC_GOVT_HERITAGE_BONUS_PREV", Locale.Lookup(government.Name)))
                end
            end
        end
    end

    return parts
end

local function GetGovernmentDetailParts(governmentType)
    local government = g_kGovernments and g_kGovernments[governmentType] or nil
    if not government then return {} end

    local parts = {}
    local slots = GetGovernmentSlotSummary(government)

    if slots ~= "" then
        table.insert(parts, Locale.Lookup("LOC_CAI_GOVERNMENT_SLOTS", slots))
    end
    if government.BonusInherentText and government.BonusInherentText ~= "" then
        table.insert(parts,
            Locale.Lookup("LOC_CAI_GOVERNMENT_INHERENT_BONUS", Locale.Lookup(government.BonusInherentText)))
    end
    if government.BonusAccumulatedText and government.BonusAccumulatedText ~= "" then
        table.insert(parts,
            Locale.Lookup("LOC_CAI_GOVERNMENT_LEGACY_BONUS", Locale.Lookup(government.BonusAccumulatedText)))
    end
    if government.StatsTooltip and government.StatsTooltip ~= "" then
        table.insert(parts, Locale.Lookup("LOC_CAI_GOVERNMENT_STATS", government.StatsTooltip))
    elseif government.StatsText and government.StatsText ~= "" then
        table.insert(parts, Locale.Lookup("LOC_CAI_GOVERNMENT_STATS", government.StatsText))
    end

    if not IsGovernmentUnlockedForPlayer(governmentType) then
        local prereqCivic = GameInfo.Governments[governmentType] and GameInfo.Governments[governmentType].PrereqCivic or
            nil
        if prereqCivic and GameInfo.Civics[prereqCivic] then
            table.insert(parts,
                Locale.Lookup("LOC_GOVT_CIVIC_REQUIRED", Locale.Lookup(GameInfo.Civics[prereqCivic].Name)))
        end
    end

    return parts
end

local function SortGovernmentsBySlotsThenName(a, b)
    local govA = g_kGovernments[a]
    local govB = g_kGovernments[b]
    local totalA = (govA.NumSlotMilitary or 0) + (govA.NumSlotEconomic or 0) + (govA.NumSlotDiplomatic or 0) +
        (govA.NumSlotWildcard or 0)
    local totalB = (govB.NumSlotMilitary or 0) + (govB.NumSlotEconomic or 0) + (govB.NumSlotDiplomatic or 0) +
        (govB.NumSlotWildcard or 0)
    if totalA ~= totalB then return totalA < totalB end
    return Locale.Compare(Locale.Lookup(govA.Name), Locale.Lookup(govB.Name)) == -1
end

local function BuildGovernmentsViewModel()
    local governments = {}

    for governmentType in pairs(g_kGovernments or {}) do
        table.insert(governments, governmentType)
    end
    table.sort(governments, SortGovernmentsBySlotsThenName)

    local items = {}
    for _, governmentType in ipairs(governments) do
        local government = g_kGovernments[governmentType]
        local details = GetGovernmentDetailParts(governmentType)
        local selected = IsGovernmentSelected(governmentType)
        local carryover = selected and GetCarryoverBonusParts(governmentType) or {}

        table.insert(items, {
            GovernmentType = governmentType,
            Label = Locale.Lookup(government.Name),
            Tooltip = JoinNonEmpty({
                GetGovernmentStatusLine(governmentType),
                table.concat(details, "[NEWLINE]"),
            }, "[NEWLINE]"),
            Disabled = not IsGovernmentUnlockedForPlayer(governmentType),
            Details = details,
            Heritage = selected and GetCurrentGovernmentHeritageParts(governmentType) or {},
            Carryover = carryover,
            ShowNoCarryover = selected and #carryover == 0,
            Selected = selected,
        })
    end

    return items
end

local function BeginInternalVanillaRefresh()
    if m_state.isInternalVanillaRefresh then return false end
    m_state.isInternalVanillaRefresh = true
    return true
end

local function EndInternalVanillaRefresh()
    m_state.isInternalVanillaRefresh = false
end

local function RefreshVanillaPolicyControlsOnly()
    if not BeginInternalVanillaRefresh() then return end
    RealizePolicyCatalog()
    RealizeActivePoliciesRows()
    EndInternalVanillaRefresh()
end

local BuildPolicyCategoryTree

local function CreatePolicyPicker(slotIndex, rowIndex)
    if m_ui.picker and mgr and mgr:HasWidget(m_ui.picker) then
        mgr:RemoveFromStack(m_ui.picker:GetId())
        m_ui.picker = nil
    end

    m_ui.picker = mgr:CreateUIWidget("CAIGovernmentPolicyPicker", "Treeview", {
        GetLabel = function()
            return Locale.Lookup("LOC_CAI_GOVERNMENT_CHOOSE_POLICY", GetRowName(rowIndex))
        end,
    })
    m_ui.picker:AddInputBinding({
        Key = Keys.VK_ESCAPE,
        Action = function()
            if mgr and m_ui.picker then mgr:RemoveFromStack(m_ui.picker:GetId()) end
            m_ui.picker = nil
            return true
        end,
    })

    local function OnPolicyChosen(policyType)
        if not IsPolicyAssignableToRow(policyType, rowIndex) then
            Speak(Locale.Lookup("LOC_CAI_GOVERNMENT_NO_LEGAL_SLOT", GetPolicyName(policyType)))
            return true
        end

        SetActivePolicyAtSlotIndex(slotIndex, policyType)
        m_state.slotPolicyTypes[slotIndex] = policyType
        Speak(Locale.Lookup("LOC_CAI_GOVERNMENT_POLICY_ASSIGNED", GetPolicyName(policyType), GetRowName(rowIndex)))
        RefreshVanillaPolicyControlsOnly()
        local slotWidget = GetPolicySlotWidgetBySlotIndex(slotIndex)
        if slotWidget then
            AddPolicySlotDetails(slotWidget)
        end
        if mgr and m_ui.picker then mgr:RemoveFromStack(m_ui.picker:GetId()) end
        m_ui.picker = nil
        return true
    end

    BuildPolicyCategoryTree(m_ui.picker, {
        RowIndex = rowIndex,
        StartExpanded = true,
        Action = OnPolicyChosen,
    })

    mgr:Push(m_ui.picker)
    return true
end

local function CreatePolicySlotWidget(slotIndex, rowIndex, slotOrdinal)
    local widget = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentPolicySlot"), "TreeviewItem", {
        GetLabel = function()
            local policyType = GetPolicyTypeForSlot(slotIndex)
            if policyType == CAI_EMPTY_POLICY_TYPE then
                return Locale.Lookup("LOC_CAI_GOVERNMENT_EMPTY_SLOT", slotOrdinal)
            end
            return GetPolicyName(policyType)
        end,
        GetTooltip = function()
            local policyType = GetPolicyTypeForSlot(slotIndex)
            if policyType == CAI_EMPTY_POLICY_TYPE then
                return Locale.Lookup("LOC_CAI_GOVERNMENT_EMPTY_SLOT", slotOrdinal)
            end
            return GetPolicyTooltip(policyType)
        end,
        OnFocusEnter = PlayGovernmentHoverSound,
    })

    widget.CAI_SlotIndex = slotIndex
    widget.CAI_RowIndex = rowIndex
    widget.CAI_SlotOrdinal = slotOrdinal
    m_ui.policySlotWidgets[slotIndex] = widget

    AddPolicySlotDetails(widget)
    if IsAbleToChangePolicies() then
        widget.OnClick = function()
            if not IsAbleToChangePolicies() then
                Speak(Locale.Lookup("LOC_CAI_GOVERNMENT_POLICIES_LOCKED"))
                return true
            end
            return CreatePolicyPicker(slotIndex, rowIndex)
        end

        widget:AddInputBinding({
            Key = Keys.VK_DELETE,
            Action = function(w)
                local currentPolicyType = GetPolicyTypeForSlot(slotIndex)
                if currentPolicyType == CAI_EMPTY_POLICY_TYPE then return true end
                if not IsAbleToChangePolicies() then
                    Speak(Locale.Lookup("LOC_CAI_GOVERNMENT_POLICIES_LOCKED"))
                    return true
                end

                RemoveActivePolicyAtSlotIndex(slotIndex)
                m_state.slotPolicyTypes[slotIndex] = CAI_EMPTY_POLICY_TYPE
                Speak(Locale.Lookup("LOC_CAI_GOVERNMENT_POLICY_REMOVED", GetPolicyName(currentPolicyType)))
                RefreshVanillaPolicyControlsOnly()
                AddPolicySlotDetails(w)
                return true
            end,
        })
    end

    widget:AddInputBinding({
        Key = Keys.VK_RETURN,
        IsShift = true,
        Action = function()
            local policyType = GetPolicyTypeForSlot(slotIndex)
            if policyType == CAI_EMPTY_POLICY_TYPE then return true end
            if IsTutorialRunning and IsTutorialRunning() then return true end
            LuaEvents.OpenCivilopedia(policyType)
            return true
        end,
    })

    return widget
end

function AddPolicySlotDetails(widget)
    if not widget then return end
    local slotIndex = widget.CAI_SlotIndex
    if slotIndex == nil then return end
    if #widget.Children > 0 then widget:ClearChildren() end
    widget:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentPolicyDetail"), "TreeviewItem", {
        GetLabel = function()
            local policyType = GetPolicyTypeForSlot(slotIndex)
            return Locale.Lookup("LOC_CAI_GOVERNMENT_POLICY_TYPE", GetPolicySlotLabel(policyType))
        end,
        IsHidden = function()
            local policyType = GetPolicyTypeForSlot(slotIndex)
            return policyType == CAI_EMPTY_POLICY_TYPE or GetPolicySlotLabel(policyType) == ""
        end,
    }))
    widget:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentPolicyDetail"), "TreeviewItem", {
        GetLabel = function()
            local policyType = GetPolicyTypeForSlot(slotIndex)
            return Locale.Lookup("LOC_CAI_GOVERNMENT_DESCRIPTION", GetPolicyDescription(policyType))
        end,
        IsHidden = function()
            local policyType = GetPolicyTypeForSlot(slotIndex)
            return policyType == CAI_EMPTY_POLICY_TYPE or GetPolicyDescription(policyType) == ""
        end,
    }))
end

local function RefreshVisibleTab()
    if not m_ui.panel or ContextPtr:IsHidden() then return end
    if m_state.activeTab == CAI_TAB_GOVERNMENTS then
        if m_ui.governmentsTree then
            local items = BuildGovernmentsViewModel()
            m_ui.governmentsTree:ClearChildren()
            for _, itemModel in ipairs(items) do
                local item = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentGovernmentItem"), "TreeviewItem", {
                    GetLabel = function() return itemModel.Label end,
                    GetTooltip = function() return itemModel.Tooltip end,
                    IsDisabled = function() return itemModel.Disabled end,
                    OnFocusEnter = PlayGovernmentHoverSound,
                    OnClick = function(w)
                        if w and w.IsDisabled and w:IsDisabled() then return end
                        OnGovernmentSelected(itemModel.GovernmentType)
                    end,
                })

                for _, detailText in ipairs(itemModel.Details) do
                    item:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentGovernmentDetail"),
                        "TreeviewItem", {
                            GetLabel = function() return detailText end,
                        }))
                end

                if itemModel.Selected then
                    for _, detailText in ipairs(itemModel.Heritage) do
                        item:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentHeritageDetail"),
                            "TreeviewItem", {
                                GetLabel = function() return detailText end,
                            }))
                    end

                    if #itemModel.Carryover > 0 then
                        for _, detailText in ipairs(itemModel.Carryover) do
                            item:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentCarryoverDetail"),
                                "TreeviewItem", {
                                    GetLabel = function() return detailText end,
                                }))
                        end
                    elseif itemModel.ShowNoCarryover then
                        item:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentCarryoverDetail"),
                            "TreeviewItem", {
                                GetLabel = function() return Locale.Lookup("LOC_GOVT_NO_LEGACY_BONUS") end,
                            }))
                    end
                end

                m_ui.governmentsTree:AddChild(item)
            end
        end
        return
    end

    if not m_ui.policiesTree then return end
    for _, row in ipairs(CAI_ROW_ORDER) do
        local rowIndex = row.Index
        local rowWidget = m_ui.policyRows[rowIndex]
        if rowWidget then
            local liveSlots = GetLiveSlotDataForRow(rowIndex)
            local layoutChanged = false
            local previousLayout = m_ui.policyRowLayouts[rowIndex] or {}
            local isEditable = IsAbleToChangePolicies()

            if #previousLayout ~= #liveSlots then
                layoutChanged = true
            else
                for i, slotData in ipairs(liveSlots) do
                    if previousLayout[i] ~= slotData.SlotIndex then
                        layoutChanged = true
                        break
                    end
                end
            end

            if m_ui.policiesEditable ~= isEditable then
                layoutChanged = true
            end

            if layoutChanged or #rowWidget.Children == 0 then
                for _, mappedSlotIndex in ipairs(previousLayout) do
                    m_ui.policySlotWidgets[mappedSlotIndex] = nil
                end
                rowWidget:ClearChildren()
                m_ui.policyRowLayouts[rowIndex] = {}

                if #liveSlots > 0 then
                    for slotOrdinal, slotData in ipairs(liveSlots) do
                        table.insert(m_ui.policyRowLayouts[rowIndex], slotData.SlotIndex)
                        rowWidget:AddChild(CreatePolicySlotWidget(slotData.SlotIndex, rowIndex, slotOrdinal))
                    end
                else
                    rowWidget:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentStaticText"), "TreeviewItem",
                        {
                            GetLabel = function() return GetEmptyRowText(rowIndex) end,
                        }))
                end
            end
        end
    end
    m_ui.policiesEditable = IsAbleToChangePolicies()
end

local function RefreshPoliciesTree()
    if m_ui.policiesTree then
        local previousTab = m_state.activeTab
        m_state.activeTab = CAI_TAB_POLICIES
        RefreshVisibleTab()
        m_state.activeTab = previousTab
    end
end

local function RefreshGovernmentsTree()
    if m_ui.governmentsTree then
        local previousTab = m_state.activeTab
        m_state.activeTab = CAI_TAB_GOVERNMENTS
        RefreshVisibleTab()
        m_state.activeTab = previousTab
    end
end

local function FocusVisibleTab()
    if not mgr or not m_ui.panel or ContextPtr:IsHidden() then return end
    local target = m_state.activeTab == CAI_TAB_GOVERNMENTS and m_ui.governmentsTree or m_ui.policiesTree
    if target then
        mgr:SetFocus(target)
    end
end

local function RequestRefresh(reason)
    if reason ~= "local-policy-edit" then
        SyncSlotPolicyTypesFromLive()
    end
    RefreshVisibleTab()
end

local function SetActiveTab(selectedTab)
    m_state.activeTab = selectedTab or CAI_TAB_GOVERNMENTS
    if not m_ui.tabBar then return end
    m_ui.tabBar:SetDefaultIndex(m_state.activeTab)
    m_ui.tabBar:SetFocusedChild(m_state.activeTab)
end

local function CreatePolicyRowWidget(rowIndex)
    return mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentPolicyRow"), "TreeviewItem", {
        GetLabel = function() return GetRowName(rowIndex) end,
        GetTooltip = function() return GetPolicyRowSummary(rowIndex) end,
    })
end

local function BuildPoliciesBody()
    local tree = mgr:CreateUIWidget("CAIGovernmentPoliciesTree", "Treeview", {
        GetLabel = function() return ControlText(Controls.ButtonPolicies) end,
        IsHidden = function() return m_state.activeTab ~= CAI_TAB_POLICIES end,
    })

    m_ui.policyRows = {}
    m_ui.policyRowLayouts = {}
    for _, row in ipairs(CAI_ROW_ORDER) do
        local rowWidget = CreatePolicyRowWidget(row.Index)
        m_ui.policyRows[row.Index] = rowWidget
        tree:AddChild(rowWidget)
    end

    return tree
end

local function BuildGovernmentsBody()
    return mgr:CreateUIWidget("CAIGovernmentGovernmentsTree", "Treeview", {
        GetLabel = function() return ControlText(Controls.ButtonGovernments) end,
        IsHidden = function() return m_state.activeTab ~= CAI_TAB_GOVERNMENTS end,
    })
end

local function CreatePolicyTreeItem(policyType, action)
    local item = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentPolicyItem"), "TreeviewItem", {
        GetLabel = function() return GetPolicyName(policyType) end,
        GetTooltip = function() return GetPolicyTooltip(policyType) end,
        OnFocusEnter = PlayGovernmentHoverSound,
    })

    local slotLabel = GetPolicySlotLabel(policyType)
    local description = GetPolicyDescription(policyType)
    if slotLabel ~= "" then
        item:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentPolicyDetail"), "TreeviewItem", {
            GetLabel = function() return Locale.Lookup("LOC_CAI_GOVERNMENT_POLICY_TYPE", slotLabel) end,
        }))
    end
    if description ~= "" then
        item:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentPolicyDetail"), "TreeviewItem", {
            GetLabel = function() return Locale.Lookup("LOC_CAI_GOVERNMENT_DESCRIPTION", description) end,
        }))
    end

    if action then
        item.OnClick = function(w)
            if w and w.IsDisabled and w:IsDisabled() then return end
            action(policyType)
        end
    end

    item:AddInputBinding({
        Key = Keys.VK_RETURN,
        IsShift = true,
        Action = function()
            if IsTutorialRunning and IsTutorialRunning() then return true end
            LuaEvents.OpenCivilopedia(policyType)
            return true
        end,
    })

    return item
end

BuildPolicyCategoryTree = function(parent, options)
    options = options or {}
    local allowedRowIndex = options.RowIndex
    local action = options.Action
    local includeActive = options.IncludeActive or false
    local startExpanded = options.StartExpanded or false

    for _, row in ipairs(CAI_ROW_ORDER) do
        if not allowedRowIndex or row.Index == allowedRowIndex then
            local rowIndex = row.Index
            local category = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentPolicyCategory"), "TreeviewItem", {
                GetLabel = function() return GetRowName(rowIndex) end,
            })
            category.IsExpanded = startExpanded

            for _, policyType in ipairs(GetAllAvailablePolicyTypes()) do
                local policy = GetPolicyData(policyType)
                local policyRowIndex = policy and GetRowIndexForSlotType(policy.SlotType) or nil
                local belongsInCategory = policyRowIndex == rowIndex
                local isAssignable = allowedRowIndex and IsPolicyAssignableToRow(policyType, allowedRowIndex)
                if (allowedRowIndex and isAssignable) or
                    (not allowedRowIndex and belongsInCategory and (includeActive or not IsPolicyTypeActive(policyType))) then
                    category:AddChild(CreatePolicyTreeItem(policyType, action))
                end
            end

            if #category.Children == 0 then
                category:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentStaticText"), "TreeviewItem", {
                    GetLabel = function() return Locale.Lookup("LOC_CAI_GOVERNMENT_NO_AVAILABLE_POLICIES") end,
                }))
            end

            parent:AddChild(category)
        end
    end
end

local function OpenAllPoliciesTree()
    if m_ui.allPoliciesTree and mgr and mgr:HasWidget(m_ui.allPoliciesTree) then
        mgr:RemoveFromStack(m_ui.allPoliciesTree:GetId())
    end

    m_ui.allPoliciesTree = mgr:CreateUIWidget("CAIGovernmentAllPoliciesTree", "Treeview", {
        GetLabel = function() return Locale.Lookup("LOC_CAI_GOVERNMENT_VIEW_ALL_POLICIES") end,
    })
    m_ui.allPoliciesTree:AddInputBinding({
        Key = Keys.VK_ESCAPE,
        Action = function()
            if mgr and m_ui.allPoliciesTree then mgr:RemoveFromStack(m_ui.allPoliciesTree:GetId()) end
            m_ui.allPoliciesTree = nil
            return true
        end,
    })

    BuildPolicyCategoryTree(m_ui.allPoliciesTree, { IncludeActive = true })
    mgr:Push(m_ui.allPoliciesTree)
    return true
end

local function CreateTabWidget(tab, control, switchFunc)
    return mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentTab"), "Tab", {
        GetLabel = function() return ControlText(control) end,
        IsHidden = function() return ControlIsHidden(control) end,
        IsDisabled = function() return ControlIsDisabled(control) end,
        OnFocusEnter = function()
            PlayGovernmentHoverSound()
            if m_state.activeTab == tab then return true end
            m_state.userSwitchedTab = true
            switchFunc()
            return true
        end,
        OnClick = function()
            if m_state.activeTab == tab then return true end
            m_state.userSwitchedTab = true
            switchFunc()
            return true
        end,
    })
end

local function BuildPanel()
    if not mgr then return end

    m_ui.panel = mgr:CreateUIWidget("CAIGovernmentScreenPanel", "Panel", {
        GetLabel = function() return ControlText(Controls.ModalScreenTitle) end,
    })

    m_ui.tabBar = mgr:CreateUIWidget("CAIGovernmentScreenTabBar", "TabBar", {
        GetLabel = function() return ControlText(Controls.ModalScreenTitle) end,
    })
    m_ui.panel:AddChild(m_ui.tabBar)

    m_ui.tabs[CAI_TAB_GOVERNMENTS] = CreateTabWidget(CAI_TAB_GOVERNMENTS, Controls.ButtonGovernments,
        SwitchTabToGovernments)
    m_ui.tabs[CAI_TAB_POLICIES] = CreateTabWidget(CAI_TAB_POLICIES, Controls.ButtonPolicies, SwitchTabToPolicies)

    m_ui.tabBar:AddChild(m_ui.tabs[CAI_TAB_GOVERNMENTS])
    m_ui.tabBar:AddChild(m_ui.tabs[CAI_TAB_POLICIES])

    m_ui.governmentsTree = BuildGovernmentsBody()
    m_ui.policiesTree = BuildPoliciesBody()
    m_ui.panel:AddChild(m_ui.governmentsTree)
    m_ui.panel:AddChild(m_ui.policiesTree)

    m_ui.panel:AddChild(mgr:CreateUIWidget("CAIGovernmentConfirmButton", "Button", {
        GetLabel = function() return ControlText(Controls.ConfirmPolicies) end,
        IsHidden = function() return m_state.activeTab ~= CAI_TAB_POLICIES or ControlIsHidden(Controls.ConfirmPolicies) end,
        IsDisabled = function() return ControlIsDisabled(Controls.ConfirmPolicies) end,
        OnFocusEnter = PlayGovernmentHoverSound,
        OnClick = function()
            OnConfirmPolicies()
            return true
        end,
    }))
    m_ui.panel:AddChild(mgr:CreateUIWidget("CAIGovernmentViewAllPoliciesButton", "Button", {
        GetLabel = function() return Locale.Lookup("LOC_CAI_GOVERNMENT_VIEW_ALL_POLICIES") end,
        IsHidden = function() return m_state.activeTab ~= CAI_TAB_POLICIES end,
        OnFocusEnter = PlayGovernmentHoverSound,
        OnClick = OpenAllPoliciesTree,
    }))
    m_ui.panel:AddChild(mgr:CreateUIWidget("CAIGovernmentUnlockPoliciesButton", "Button", {
        GetLabel = function() return ControlText(Controls.UnlockPolicies) end,
        IsHidden = function() return m_state.activeTab ~= CAI_TAB_POLICIES or ControlIsHidden(Controls.UnlockPolicies) end,
        IsDisabled = function() return ControlIsDisabled(Controls.UnlockPolicies) end,
        OnFocusEnter = PlayGovernmentHoverSound,
        OnClick = function()
            OnUnlockPolicies()
            return true
        end,
    }))
    m_ui.panel:AddChild(mgr:CreateUIWidget("CAIGovernmentUnlockGovernmentsButton", "Button", {
        GetLabel = function() return ControlText(Controls.UnlockGovernments) end,
        IsHidden = function()
            return m_state.activeTab ~= CAI_TAB_GOVERNMENTS or ControlIsHidden(Controls.UnlockGovernmentsContainer)
        end,
        IsDisabled = function() return ControlIsDisabled(Controls.UnlockGovernments) end,
        OnFocusEnter = PlayGovernmentHoverSound,
        OnClick = function()
            OnUnlockGovernments()
            return true
        end,
    }))

    SetActiveTab(m_state.activeTab)
end

local function PushPanel()
    if not mgr then return end
    if not m_ui.panel then BuildPanel() end
    if not m_ui.panel then return end
    if not mgr:HasWidget(m_ui.panel) then
        mgr:Push(m_ui.panel, PopupPriority.Low)
    end
end

local function PopPanel()
    if m_ui.panel and mgr and mgr:HasWidget(m_ui.panel) then
        mgr:RemoveFromStack(m_ui.panel:GetId())
    elseif m_ui.panel then
        m_ui.panel:Destroy()
    end

    m_ui = {
        panel = nil,
        tabBar = nil,
        tabs = {},
        policiesTree = nil,
        governmentsTree = nil,
        policyRows = {},
        policyRowLayouts = {},
        policySlotWidgets = {},
        policiesEditable = nil,
        picker = nil,
        allPoliciesTree = nil,
    }

    m_state.activeTab = CAI_TAB_GOVERNMENTS
    m_state.slotPolicyTypes = {}
    m_state.isInternalVanillaRefresh = false
    m_state.userSwitchedTab = false
end

OnOpenGovernmentScreen = WrapFunc(OnOpenGovernmentScreen, function(orig, screenEnum)
    if not m_ui.panel then BuildPanel() end
    orig(screenEnum)
    PushPanel()
    RequestRefresh("open")
    FocusVisibleTab()
end)

Close = WrapFunc(Close, function(orig)
    orig()
    if ContextPtr:IsHidden() then
        PopPanel()
    end
end)

SwitchTabToPolicies = WrapFunc(SwitchTabToPolicies, function(orig)
    orig()
    SetActiveTab(CAI_TAB_POLICIES)
    RequestRefresh("tab-switch")
    if not m_state.userSwitchedTab then FocusVisibleTab() end
    m_state.userSwitchedTab = false
end)

SwitchTabToGovernments = WrapFunc(SwitchTabToGovernments, function(orig)
    orig()
    SetActiveTab(CAI_TAB_GOVERNMENTS)
    RequestRefresh("tab-switch")
    if not m_state.userSwitchedTab then FocusVisibleTab() end
    m_state.userSwitchedTab = false
end)

SwitchTabToMyGovernment = WrapFunc(SwitchTabToMyGovernment, function(orig)
    orig()
    m_state.userSwitchedTab = true
    SwitchTabToGovernments()
end)

RealizeGovernmentsPage = WrapFunc(RealizeGovernmentsPage, function(orig)
    orig()
    if m_ui.panel and not ContextPtr:IsHidden() and m_state.activeTab == CAI_TAB_GOVERNMENTS then
        RefreshGovernmentsTree()
    end
end)

RealizeActivePoliciesRows = WrapFunc(RealizeActivePoliciesRows, function(orig)
    orig()
    if not m_state.isInternalVanillaRefresh then
        SyncSlotPolicyTypesFromLive()
        if m_ui.panel and not ContextPtr:IsHidden() and m_state.activeTab == CAI_TAB_POLICIES then
            RefreshPoliciesTree()
        end
    end
end)

PopulateLivePlayerData = WrapFunc(PopulateLivePlayerData, function(orig, ePlayer)
    orig(ePlayer)
    SyncSlotPolicyTypesFromLive()
end)

RefreshAllData = WrapFunc(RefreshAllData, function(orig)
    orig()
    RequestRefresh("vanilla-refresh")
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, input)
    local top = mgr and mgr:GetTop()
    if top ~= m_ui.panel and top ~= m_ui.picker and top ~= m_ui.allPoliciesTree then return false end
    local handled = (mgr and mgr:HandleInput(input)) or false
    if handled then return true end
    return orig(input)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)

OnShutdown = WrapFunc(OnShutdown, function(orig)
    PopPanel()
    orig()
end)
ContextPtr:SetShutdown(OnShutdown)
