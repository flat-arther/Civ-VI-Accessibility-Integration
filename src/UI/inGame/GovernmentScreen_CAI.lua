include("caiUtils")
include("GovernmentScreen")

local mgr                   = ExposedMembers.CAI_UIManager

local PANEL_ID              = "CAIGovernmentScreen_Panel"
local TABS_ID               = "CAIGovernmentScreen_Tabs"
local GOV_TREE_ID           = "CAIGovernmentScreen_GovernmentsTree"
local POL_TREE_ID           = "CAIGovernmentScreen_PoliciesTree"
local PICKER_ID             = "CAIGovernmentScreen_PolicyPicker"
local ALL_POLICIES_ID       = "CAIGovernmentScreen_AllPoliciesTree"

local CAI_EMPTY_POLICY_TYPE = EMPTY_POLICY_TYPE or "empty"

local CAI_ROW_ORDER         = {
    { Index = ROW_INDEX and ROW_INDEX.MILITARY or 1, SlotType = "SLOT_MILITARY",   LabelControl = "LabelMilitary",   Tooltip = "LOC_GOVT_POLICY_TYPE_MILITARY",   Empty = "LOC_GOVT_NO_MILITARY_SLOTS" },
    { Index = ROW_INDEX and ROW_INDEX.ECONOMIC or 2, SlotType = "SLOT_ECONOMIC",   LabelControl = "LabelEconomic",   Tooltip = "LOC_GOVT_POLICY_TYPE_ECONOMIC",   Empty = "LOC_GOVT_NO_ECONOMIC_SLOTS" },
    { Index = ROW_INDEX and ROW_INDEX.DIPLOMAT or 3, SlotType = "SLOT_DIPLOMATIC", LabelControl = "LabelDiplomatic", Tooltip = "LOC_GOVT_POLICY_TYPE_DIPLOMATIC", Empty = "LOC_GOVT_NO_DIPLOMACY_SLOTS" },
    { Index = ROW_INDEX and ROW_INDEX.WILDCARD or 4, SlotType = "SLOT_WILDCARD",   LabelControl = "LabelWildcard",   Tooltip = "LOC_GOVT_POLICY_TYPE_WILDCARD",   Empty = "LOC_GOVT_NO_WILDCARD_SLOTS" },
}

local m_state               = {
    slotPolicyTypes = {},
    isInternalVanillaRefresh = false,
    isMirroringTab = false,
    activeTab = 1,
}

local m_ui                  = {
    panel = nil,
    tabs = nil,
    govPage = nil,
    polPage = nil,
    govTree = nil,
    polTree = nil,
    polRows = {},
    picker = nil,
    allPolicies = nil,
}

-- ---------------------------------------------------------------------------
-- Utility helpers
-- ---------------------------------------------------------------------------

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
        if part and part ~= "" then table.insert(out, part) end
    end
    return table.concat(out, separator)
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

-- ---------------------------------------------------------------------------
-- Policy data
-- ---------------------------------------------------------------------------

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
    }, ", ")
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

-- ---------------------------------------------------------------------------
-- Slot policy types: local cache, synchronized from culture
-- ---------------------------------------------------------------------------

local function SyncSlotPolicyTypesFromLive()
    m_state.slotPolicyTypes = {}
    local culture = GetLocalPlayerCulture()
    if not culture then return end

    local numSlots = culture:GetNumPolicySlots()
    for slotIndex = 0, numSlots - 1 do
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
    for slotIndex = 0, numSlots - 1 do
        local slotTypeIndex = culture:GetSlotType(slotIndex)
        local slotInfo = GameInfo.GovernmentSlots[slotTypeIndex]
        local slotRowIndex = slotInfo and GetRowIndexForSlotType(slotInfo.GovernmentSlotType) or nil
        if slotRowIndex == rowIndex then
            table.insert(slots, { SlotIndex = slotIndex, RowIndex = rowIndex })
        end
    end
    return slots
end

local function GetPolicyRowSummary(rowIndex)
    local liveSlots = GetLiveSlotDataForRow(rowIndex)
    local used, names = 0, {}
    for _, slotData in ipairs(liveSlots) do
        local policyType = GetPolicyTypeForSlot(slotData.SlotIndex)
        if policyType ~= CAI_EMPTY_POLICY_TYPE then
            used = used + 1
            table.insert(names, GetPolicyName(policyType))
        end
    end
    local parts = { Locale.Lookup("LOC_CAI_GOVERNMENT_SLOTS_USED", used, #liveSlots) }
    for _, name in ipairs(names) do table.insert(parts, name) end
    return table.concat(parts, ", ")
end

-- ---------------------------------------------------------------------------
-- Government view model
-- ---------------------------------------------------------------------------

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

-- ---------------------------------------------------------------------------
-- Vanilla refresh helper used after CAI assigns/removes a policy
-- ---------------------------------------------------------------------------

local function RefreshVanillaPolicyControlsOnly()
    if m_state.isInternalVanillaRefresh then return end
    m_state.isInternalVanillaRefresh = true
    RealizePolicyCatalog()
    RealizeActivePoliciesRows()
    m_state.isInternalVanillaRefresh = false
end

-- ---------------------------------------------------------------------------
-- Policy picker tree (transient push)
-- ---------------------------------------------------------------------------

local BuildPolicyCategoryTree

local function ClosePicker()
    if mgr and m_ui.picker then mgr:RemoveFromStack(PICKER_ID) end
    m_ui.picker = nil
end

local function CloseAllPolicies()
    if mgr and m_ui.allPolicies then mgr:RemoveFromStack(ALL_POLICIES_ID) end
    m_ui.allPolicies = nil
end

local function CreatePolicyTreeItem(policyType, action)
    local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAIGovScreenPolicyItem"), "TreeItem", {
        Label   = function() return GetPolicyName(policyType) end,
        Tooltip = function() return GetPolicyTooltip(policyType) end,
    })
    item:SetFocusSound("Main_Menu_Mouse_Over")
    item.FocusKey = "pol:" .. tostring(policyType)

    if action then
        item:On("activate", function(w)
            if w:IsDisabled() then return end
            action(policyType)
        end)
    end

    item:AddInputBindings({
        {
            Key      = Keys.VK_RETURN,
            IsShift  = true,
            MSG      = KeyEvents.KeyUp,
            Action   = function()
                if IsTutorialRunning and IsTutorialRunning() then return true end
                LuaEvents.OpenCivilopedia(policyType)
                return true
            end,
        },
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
            local category = mgr:CreateWidget(mgr:GenerateWidgetId("CAIGovScreenPolicyCategory"), "TreeItem", {
                Label = function() return GetRowName(rowIndex) end,
            })

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
                category:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAIGovScreenStatic"), "TreeItem", {
                    Label = function() return Locale.Lookup("LOC_CAI_GOVERNMENT_NO_AVAILABLE_POLICIES") end,
                }))
            end

            parent:AddChild(category)
            if startExpanded then category:Expand() end
        end
    end
end

local function CreatePolicyPicker(slotIndex, rowIndex)
    ClosePicker()

    m_ui.picker = mgr:CreateWidget(PICKER_ID, "Tree", {
        Label = function() return Locale.Lookup("LOC_CAI_GOVERNMENT_CHOOSE_POLICY", GetRowName(rowIndex)) end,
    })
    m_ui.picker:AddInputBindings({
        {
            Key    = Keys.VK_ESCAPE,
            MSG    = KeyEvents.KeyUp,
            Action = function() ClosePicker() return true end,
        },
    })

    BuildPolicyCategoryTree(m_ui.picker, {
        RowIndex = rowIndex,
        StartExpanded = true,
        Action = function(policyType)
            if not IsPolicyAssignableToRow(policyType, rowIndex) then
                Speak(Locale.Lookup("LOC_CAI_GOVERNMENT_NO_LEGAL_SLOT", GetPolicyName(policyType)))
                return
            end
            SetActivePolicyAtSlotIndex(slotIndex, policyType)
            m_state.slotPolicyTypes[slotIndex] = policyType
            Speak(Locale.Lookup("LOC_CAI_GOVERNMENT_POLICY_ASSIGNED", GetPolicyName(policyType), GetRowName(rowIndex)))
            RefreshVanillaPolicyControlsOnly()
            ClosePicker()
        end,
    })

    mgr:Push(m_ui.picker, PopupPriority.Current)
    return true
end

local function OpenAllPoliciesTree()
    CloseAllPolicies()

    m_ui.allPolicies = mgr:CreateWidget(ALL_POLICIES_ID, "Tree", {
        Label = function() return Locale.Lookup("LOC_CAI_GOVERNMENT_VIEW_ALL_POLICIES") end,
    })
    m_ui.allPolicies:AddInputBindings({
        {
            Key    = Keys.VK_ESCAPE,
            MSG    = KeyEvents.KeyUp,
            Action = function() CloseAllPolicies() return true end,
        },
    })

    BuildPolicyCategoryTree(m_ui.allPolicies, { IncludeActive = true })
    mgr:Push(m_ui.allPolicies, PopupPriority.Current)
    return true
end

-- ---------------------------------------------------------------------------
-- Policy slot widgets
-- ---------------------------------------------------------------------------

local function CreatePolicySlotWidget(slotIndex, rowIndex, slotOrdinal)
    local widget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIGovScreenPolicySlot"), "TreeItem", {
        Label   = function()
            local policyType = GetPolicyTypeForSlot(slotIndex)
            if policyType == CAI_EMPTY_POLICY_TYPE then
                return Locale.Lookup("LOC_CAI_GOVERNMENT_EMPTY_SLOT", slotOrdinal)
            end
            return GetPolicyName(policyType)
        end,
        Tooltip = function()
            local policyType = GetPolicyTypeForSlot(slotIndex)
            if policyType == CAI_EMPTY_POLICY_TYPE then
                return Locale.Lookup("LOC_CAI_GOVERNMENT_EMPTY_SLOT", slotOrdinal)
            end
            return GetPolicyTooltip(policyType)
        end,
        FocusKey = "slot:" .. tostring(slotIndex),
    })
    widget:SetFocusSound("Main_Menu_Mouse_Over")

    widget:On("activate", function()
        if not IsAbleToChangePolicies() then
            Speak(Locale.Lookup("LOC_CAI_GOVERNMENT_POLICIES_LOCKED"))
            return
        end
        CreatePolicyPicker(slotIndex, rowIndex)
    end)

    widget:AddInputBindings({
        {
            Key    = Keys.VK_DELETE,
            MSG    = KeyEvents.KeyUp,
            Action = function()
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
                return true
            end,
        },
        {
            Key     = Keys.VK_RETURN,
            IsShift = true,
            MSG     = KeyEvents.KeyUp,
            Action  = function()
                local policyType = GetPolicyTypeForSlot(slotIndex)
                if policyType == CAI_EMPTY_POLICY_TYPE then return true end
                if IsTutorialRunning and IsTutorialRunning() then return true end
                LuaEvents.OpenCivilopedia(policyType)
                return true
            end,
        },
    })

    return widget
end

-- ---------------------------------------------------------------------------
-- Body builders
-- ---------------------------------------------------------------------------

local function BuildPoliciesTreeContent(tree)
    m_ui.polRows = {}
    for _, row in ipairs(CAI_ROW_ORDER) do
        local rowIndex = row.Index
        local rowWidget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIGovScreenPolicyRow"), "TreeItem", {
            Label    = function() return GetRowName(rowIndex) end,
            Tooltip  = function() return GetPolicyRowSummary(rowIndex) end,
            FocusKey = "polrow:" .. tostring(rowIndex),
        })

        local liveSlots = GetLiveSlotDataForRow(rowIndex)
        if #liveSlots > 0 then
            for slotOrdinal, slotData in ipairs(liveSlots) do
                rowWidget:AddChild(CreatePolicySlotWidget(slotData.SlotIndex, rowIndex, slotOrdinal))
            end
        else
            rowWidget:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAIGovScreenStatic"), "TreeItem", {
                Label = function() return GetEmptyRowText(rowIndex) end,
            }))
        end

        m_ui.polRows[rowIndex] = rowWidget
        tree:AddChild(rowWidget)
    end
end

local function BuildGovernmentsTreeContent(tree)
    local governments = {}
    for governmentType in pairs(g_kGovernments or {}) do
        table.insert(governments, governmentType)
    end
    table.sort(governments, SortGovernmentsBySlotsThenName)

    for _, governmentType in ipairs(governments) do
        local government = g_kGovernments[governmentType]
        local selected = IsGovernmentSelected(governmentType)
        local govType = governmentType

        local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAIGovScreenGovernmentItem"), "TreeItem", {
            Label             = function()
                local name = Locale.Lookup(government.Name)
                if IsGovernmentSelected(govType) then
                    return Locale.Lookup("LOC_CAI_GOVERNMENT_ACTIVE") .. ", " .. name
                end
                return name
            end,
            Tooltip           = function()
                return table.concat(GetGovernmentDetailParts(govType), ", ")
            end,
            DisabledPredicate = function() return not IsGovernmentUnlockedForPlayer(govType) end,
            FocusKey          = "gov:" .. tostring(governmentType),
        })
        item:SetFocusSound("Main_Menu_Mouse_Over")

        item:On("activate", function(w)
            if w:IsDisabled() then return end
            OnGovernmentSelected(govType)
        end)

        for _, detailText in ipairs(GetGovernmentDetailParts(governmentType)) do
            item:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAIGovScreenGovDetail"), "TreeItem", {
                Label = function() return detailText end,
            }))
        end

        if selected then
            for _, detailText in ipairs(GetCurrentGovernmentHeritageParts(governmentType)) do
                item:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAIGovScreenHeritage"), "TreeItem", {
                    Label = function() return detailText end,
                }))
            end
            local carryover = GetCarryoverBonusParts(governmentType)
            if #carryover > 0 then
                for _, detailText in ipairs(carryover) do
                    item:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAIGovScreenCarryover"), "TreeItem", {
                        Label = function() return detailText end,
                    }))
                end
            else
                item:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAIGovScreenCarryover"), "TreeItem", {
                    Label = function() return Locale.Lookup("LOC_GOVT_NO_LEGACY_BONUS") end,
                }))
            end
        end

        tree:AddChild(item)
    end
end

-- ---------------------------------------------------------------------------
-- Refresh
-- ---------------------------------------------------------------------------

local function RefreshGovernmentsTree()
    if not m_ui.govTree then return end
    local capture = mgr:CaptureFocusKey(m_ui.govTree)
    m_ui.govTree:ClearChildren()
    BuildGovernmentsTreeContent(m_ui.govTree)
    mgr:RestoreFocus(m_ui.govTree, capture)
end

local function RefreshPoliciesTree()
    if not m_ui.polTree then return end
    local capture = mgr:CaptureFocusKey(m_ui.polTree)
    m_ui.polTree:ClearChildren()
    BuildPoliciesTreeContent(m_ui.polTree)
    mgr:RestoreFocus(m_ui.polTree, capture)
end

-- ---------------------------------------------------------------------------
-- Panel build
-- ---------------------------------------------------------------------------

local function BuildPolicyFooter(page)
    local confirm = mgr:CreateWidget("CAIGovScreenConfirm", "Button", {
        Label             = function() return Locale.Lookup("LOC_CAI_GOVERNMENT_CONFIRM_POLICIES") end,
        Tooltip           = function() return Controls.ConfirmPolicies:GetToolTipString() or "" end,
        HiddenPredicate   = function() return Controls.ConfirmPolicies:IsHidden() end,
        DisabledPredicate = function() return Controls.ConfirmPolicies:IsDisabled() end,
    })
    confirm:SetFocusSound("Main_Menu_Mouse_Over")
    confirm:On("activate", function()
        Controls.ConfirmPolicies:DoLeftClick()
        if m_ui.polTree and not ContextPtr:IsHidden() then mgr:SetFocus(m_ui.polTree) end
    end)
    page:AddChild(confirm)

    local viewAll = mgr:CreateWidget("CAIGovScreenViewAllPolicies", "Button", {
        Label = function() return Locale.Lookup("LOC_CAI_GOVERNMENT_VIEW_ALL_POLICIES") end,
    })
    viewAll:SetFocusSound("Main_Menu_Mouse_Over")
    viewAll:On("activate", function() OpenAllPoliciesTree() end)
    page:AddChild(viewAll)

    local unlock = mgr:CreateWidget("CAIGovScreenUnlockPolicies", "Button", {
        Label             = function() return ControlText(Controls.UnlockPolicies) end,
        Tooltip           = function() return Controls.UnlockPolicies:GetToolTipString() or "" end,
        HiddenPredicate   = function() return Controls.UnlockPolicies:IsHidden() end,
        DisabledPredicate = function() return Controls.UnlockPolicies:IsDisabled() end,
    })
    unlock:SetFocusSound("Main_Menu_Mouse_Over")
    unlock:On("activate", function()
        Controls.UnlockPolicies:DoLeftClick()
        if m_ui.polTree then mgr:SetFocus(m_ui.polTree) end
    end)
    page:AddChild(unlock)
end

local function BuildGovernmentFooter(page)
    local unlock = mgr:CreateWidget("CAIGovScreenUnlockGovernments", "Button", {
        Label             = function() return ControlText(Controls.UnlockGovernments) end,
        Tooltip           = function() return Controls.UnlockGovernments:GetToolTipString() or "" end,
        HiddenPredicate   = function() return Controls.UnlockGovernmentsContainer:IsHidden() end,
        DisabledPredicate = function() return Controls.UnlockGovernments:IsDisabled() end,
    })
    unlock:SetFocusSound("Main_Menu_Mouse_Over")
    unlock:On("activate", function()
        Controls.UnlockGovernments:DoLeftClick()
        if m_ui.govTree then mgr:SetFocus(m_ui.govTree) end
    end)
    page:AddChild(unlock)
end

local function BuildPanel()
    if not mgr then return end

    m_ui.panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function() return ControlText(Controls.ModalScreenTitle) end,
    })

    m_ui.tabs = mgr:CreateWidget(TABS_ID, "TabControl", {})
    m_ui.panel:AddChild(m_ui.tabs)

    m_ui.govPage = m_ui.tabs:AddPage(function() return ControlText(Controls.ButtonGovernments) end)
    m_ui.polPage = m_ui.tabs:AddPage(function() return ControlText(Controls.ButtonPolicies) end)

    m_ui.govTree = mgr:CreateWidget(GOV_TREE_ID, "Tree", {
        Label = function() return ControlText(Controls.ButtonGovernments) end,
    })
    m_ui.govPage:AddChild(m_ui.govTree)
    BuildGovernmentFooter(m_ui.govPage)

    m_ui.polTree = mgr:CreateWidget(POL_TREE_ID, "Tree", {
        Label = function() return ControlText(Controls.ButtonPolicies) end,
    })
    m_ui.polPage:AddChild(m_ui.polTree)
    BuildPolicyFooter(m_ui.polPage)

    BuildGovernmentsTreeContent(m_ui.govTree)
    BuildPoliciesTreeContent(m_ui.polTree)

    m_ui.tabs:On("value_changed", function(_, idx)
        if m_state.isMirroringTab then return end
        if idx == 1 then
            Controls.ButtonGovernments:DoLeftClick()
        elseif idx == 2 then
            Controls.ButtonPolicies:DoLeftClick()
        end
    end)
end

local function MirrorActiveTabToCAI()
    if not m_ui.tabs then return end
    if m_ui.tabs:GetActivePageIndex() == m_state.activeTab then return end
    m_state.isMirroringTab = true
    m_ui.tabs:SetActivePage(m_state.activeTab, true)
    m_state.isMirroringTab = false
end

-- ---------------------------------------------------------------------------
-- Lifecycle
-- ---------------------------------------------------------------------------

local function PushPanel()
    if not mgr then return end
    if not m_ui.panel then BuildPanel() end
    if not m_ui.panel then return end
    if not mgr:GetWidgetById(PANEL_ID) then
        mgr:Push(m_ui.panel, PopupPriority.Low)
    end
end

local function PopPanel()
    ClosePicker()
    CloseAllPolicies()
    if mgr and m_ui.panel then
        mgr:RemoveFromStack(PANEL_ID)
    end
    m_ui = {
        panel = nil, tabs = nil,
        govPage = nil, polPage = nil,
        govTree = nil, polTree = nil,
        polRows = {},
        picker = nil, allPolicies = nil,
    }
    m_state.slotPolicyTypes = {}
    m_state.isInternalVanillaRefresh = false
    m_state.isMirroringTab = false
    m_state.activeTab = 1
end

-- ---------------------------------------------------------------------------
-- Vanilla wraps
-- ---------------------------------------------------------------------------

OnOpenGovernmentScreen = WrapFunc(OnOpenGovernmentScreen, function(orig, screenEnum)
    orig(screenEnum)
    SyncSlotPolicyTypesFromLive()
    if not m_ui.panel then BuildPanel() end
    PushPanel()
    MirrorActiveTabToCAI()
end)

Close = WrapFunc(Close, function(orig)
    orig()
    if ContextPtr:IsHidden() then PopPanel() end
end)

SwitchTabToPolicies = WrapFunc(SwitchTabToPolicies, function(orig)
    orig()
    m_state.activeTab = 2
    if m_ui.tabs and not m_state.isMirroringTab then
        m_state.isMirroringTab = true
        m_ui.tabs:SetActivePage(2, true)
        m_state.isMirroringTab = false
    end
end)

SwitchTabToGovernments = WrapFunc(SwitchTabToGovernments, function(orig)
    orig()
    m_state.activeTab = 1
    if m_ui.tabs and not m_state.isMirroringTab then
        m_state.isMirroringTab = true
        m_ui.tabs:SetActivePage(1, true)
        m_state.isMirroringTab = false
    end
end)

if SwitchTabToMyGovernment then
    SwitchTabToMyGovernment = WrapFunc(SwitchTabToMyGovernment, function(orig)
        orig()
        if SwitchTabToGovernments then SwitchTabToGovernments() end
    end)
end

RealizeGovernmentsPage = WrapFunc(RealizeGovernmentsPage, function(orig)
    orig()
    if m_ui.panel and not ContextPtr:IsHidden() then
        RefreshGovernmentsTree()
    end
end)

RealizeActivePoliciesRows = WrapFunc(RealizeActivePoliciesRows, function(orig)
    orig()
    if m_state.isInternalVanillaRefresh then return end
    if m_ui.panel and not ContextPtr:IsHidden() then
        SyncSlotPolicyTypesFromLive()
        RefreshPoliciesTree()
    end
end)

PopulateLivePlayerData = WrapFunc(PopulateLivePlayerData, function(orig, ePlayer)
    orig(ePlayer)
    SyncSlotPolicyTypesFromLive()
end)

RefreshAllData = WrapFunc(RefreshAllData, function(orig)
    orig()
    if m_ui.panel and not ContextPtr:IsHidden() then
        SyncSlotPolicyTypesFromLive()
        RefreshGovernmentsTree()
        RefreshPoliciesTree()
        MirrorActiveTabToCAI()
    end
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, input)
    if mgr then
        local top = mgr:GetTop()
        if top == m_ui.panel or top == m_ui.picker or top == m_ui.allPolicies then
            if mgr:HandleInput(input) then return true end
        end
    end
    return orig(input)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)

OnShutdown = WrapFunc(OnShutdown, function(orig)
    PopPanel()
    orig()
end)
ContextPtr:SetShutdown(OnShutdown)
