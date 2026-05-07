include("caiUtils")
include("GovernmentScreen")

local mgr                                   = ExposedMembers.CAI_UIManager

local CAI_TAB_GOVERNMENTS                   = 1
local CAI_TAB_POLICIES                      = 2
local CAI_EMPTY_POLICY_TYPE                 = EMPTY_POLICY_TYPE or "empty"

local CAI_ROW_ORDER                         = {
    { Index = ROW_INDEX and ROW_INDEX.MILITARY or 1, SlotType = "SLOT_MILITARY",   LabelControl = "LabelMilitary",   Tooltip = "LOC_GOVT_POLICY_TYPE_MILITARY",   Empty = "LOC_GOVT_NO_MILITARY_SLOTS" },
    { Index = ROW_INDEX and ROW_INDEX.ECONOMIC or 2, SlotType = "SLOT_ECONOMIC",   LabelControl = "LabelEconomic",   Tooltip = "LOC_GOVT_POLICY_TYPE_ECONOMIC",   Empty = "LOC_GOVT_NO_ECONOMIC_SLOTS" },
    { Index = ROW_INDEX and ROW_INDEX.DIPLOMAT or 3, SlotType = "SLOT_DIPLOMATIC", LabelControl = "LabelDiplomatic", Tooltip = "LOC_GOVT_POLICY_TYPE_DIPLOMATIC", Empty = "LOC_GOVT_NO_DIPLOMACY_SLOTS" },
    { Index = ROW_INDEX and ROW_INDEX.WILDCARD or 4, SlotType = "SLOT_WILDCARD",   LabelControl = "LabelWildcard",   Tooltip = "LOC_GOVT_POLICY_TYPE_WILDCARD",   Empty = "LOC_GOVT_NO_WILDCARD_SLOTS" },
}

local m_caiPanel                            = nil
local m_caiPicker                           = nil
local m_caiPoliciesTree                     = nil
local m_caiTabBar                           = nil
local m_caiBody                             = nil
local m_caiActionButtons                    = {}
local m_caiTabs                             = {}
local m_caiTab                              = nil
local m_caiSlotPolicyTypes                  = {}
local m_caiRebuilding                       = false
local m_caiUserSwitchedTab                  = false
local m_caiSuppressRebuild                  = false
local m_caiPendingGovernmentPoliciesRefresh = false

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

local function RefreshSlotPolicyTypesFromLivePlayer()
    m_caiSlotPolicyTypes = {}

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
            m_caiSlotPolicyTypes[slotIndex] = policyType
        end
    end
end

local function GetPolicyTypeForSlot(slotIndex)
    if slotIndex == nil then return CAI_EMPTY_POLICY_TYPE end
    local policyType = m_caiSlotPolicyTypes[slotIndex]
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
                GC_SlotIndex = slotIndex,
                UI_RowIndex = rowIndex,
            })
        end
    end

    return slots
end

local function RefreshVanillaPolicyControlsOnly()
    if m_caiRebuilding then return end
    m_caiRebuilding = true
    m_caiSuppressRebuild = true
    RealizePolicyCatalog()
    RealizeActivePoliciesRows()
    m_caiSuppressRebuild = false
    m_caiRebuilding = false
end

local function AssignPolicyToSlot(policyType, slotIndex, rowIndex)
    if not IsAbleToChangePolicies() then
        Speak(Locale.Lookup("LOC_CAI_GOVERNMENT_POLICIES_LOCKED"))
        return true
    end
    if not IsPolicyAssignableToRow(policyType, rowIndex) then
        Speak(Locale.Lookup("LOC_CAI_GOVERNMENT_NO_LEGAL_SLOT", GetPolicyName(policyType)))
        return true
    end

    SetActivePolicyAtSlotIndex(slotIndex, policyType)
    m_caiSlotPolicyTypes[slotIndex] = policyType
    Speak(Locale.Lookup("LOC_CAI_GOVERNMENT_POLICY_ASSIGNED", GetPolicyName(policyType), GetRowName(rowIndex)))
    RefreshVanillaPolicyControlsOnly()
    return true
end

local function RemovePolicyFromSlot(slotIndex, policyType)
    if not IsAbleToChangePolicies() then
        Speak(Locale.Lookup("LOC_CAI_GOVERNMENT_POLICIES_LOCKED"))
        return true
    end
    local currentPolicyType = GetPolicyTypeForSlot(slotIndex)
    if currentPolicyType == CAI_EMPTY_POLICY_TYPE then return true end
    RemoveActivePolicyAtSlotIndex(slotIndex)
    m_caiSlotPolicyTypes[slotIndex] = CAI_EMPTY_POLICY_TYPE
    Speak(Locale.Lookup("LOC_CAI_GOVERNMENT_POLICY_REMOVED", GetPolicyName(currentPolicyType or policyType)))
    RefreshVanillaPolicyControlsOnly()
    return true
end

local function OpenCivilopediaForPolicy(policyType)
    if IsTutorialRunning and IsTutorialRunning() then return true end
    if policyType then
        LuaEvents.OpenCivilopedia(policyType)
    end
    return true
end

local function AddPolicyDetailChildren(policyItem, policyType)
    local slotLabel = GetPolicySlotLabel(policyType)
    local description = GetPolicyDescription(policyType)

    if slotLabel ~= "" then
        policyItem:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentPolicyDetail"), "TreeviewItem", {
            GetLabel = function() return Locale.Lookup("LOC_CAI_GOVERNMENT_POLICY_TYPE", slotLabel) end,
        }))
    end
    if description ~= "" then
        policyItem:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentPolicyDetail"), "TreeviewItem", {
            GetLabel = function() return Locale.Lookup("LOC_CAI_GOVERNMENT_DESCRIPTION", description) end,
        }))
    end
end

local function CreatePolicyTreeItem(policyType, action)
    local item = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentPolicyItem"), "TreeviewItem", {
        GetLabel = function() return GetPolicyName(policyType) end,
        GetTooltip = function() return GetPolicyTooltip(policyType) end,
        OnFocusEnter = PlayGovernmentHoverSound,
    })
    AddPolicyDetailChildren(item, policyType)

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
            return OpenCivilopediaForPolicy(policyType)
        end,
    })
    return item
end

local function BuildPolicyCategoryTree(parent, options)
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
                local policyTypeForItem = policyType
                local policy = GetPolicyData(policyType)
                local policyRowIndex = policy and GetRowIndexForSlotType(policy.SlotType) or nil
                local belongsInCategory = policyRowIndex == rowIndex
                local isAssignable = allowedRowIndex and IsPolicyAssignableToRow(policyType, allowedRowIndex)
                if (allowedRowIndex and isAssignable) or (not allowedRowIndex and belongsInCategory and (includeActive or not IsPolicyTypeActive(policyType))) then
                    category:AddChild(CreatePolicyTreeItem(policyTypeForItem, action))
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

local function OpenPolicyPickerForSlot(slotIndex, rowIndex)
    if not IsAbleToChangePolicies() then
        Speak(Locale.Lookup("LOC_CAI_GOVERNMENT_POLICIES_LOCKED"))
        return true
    end

    m_caiPicker = mgr:CreateUIWidget("CAIGovernmentPolicyPicker", "Treeview", {
        GetLabel = function()
            return Locale.Lookup("LOC_CAI_GOVERNMENT_CHOOSE_POLICY", GetRowName(rowIndex))
        end,
    })
    m_caiPicker:AddInputBinding({
        Key = Keys.VK_ESCAPE,
        Action = function()
            if mgr then mgr:RemoveFromStack(m_caiPicker:GetId()) end
            m_caiPicker = nil
            return true
        end,
    })

    BuildPolicyCategoryTree(m_caiPicker, {
        RowIndex = rowIndex,
        StartExpanded = true,
        Action = function(policyType)
            local handled = AssignPolicyToSlot(policyType, slotIndex, rowIndex)
            if mgr then mgr:RemoveFromStack(m_caiPicker:GetId()) end
            return handled
        end,
    })

    mgr:Push(m_caiPicker)
    return true
end

local function OpenAllPoliciesTree()
    m_caiPoliciesTree = mgr:CreateUIWidget("CAIGovernmentAllPoliciesTree", "Treeview", {
        GetLabel = function() return Locale.Lookup("LOC_CAI_GOVERNMENT_VIEW_ALL_POLICIES") end,
    })
    m_caiPoliciesTree:AddInputBinding({
        Key = Keys.VK_ESCAPE,
        Action = function()
            if mgr then mgr:RemoveFromStack(m_caiPoliciesTree:GetId()) end
            m_caiPoliciesTree = nil
            return true
        end,
    })

    BuildPolicyCategoryTree(m_caiPoliciesTree, { IncludeActive = true })

    mgr:Push(m_caiPoliciesTree)
    return true
end

local function AddPolicySlotDetailChildren(widget, slotIndex)
    widget:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentPolicyDetail"), "TreeviewItem", {
        GetLabel = function()
            local policyType = GetPolicyTypeForSlot(slotIndex)
            return Locale.Lookup("LOC_CAI_GOVERNMENT_POLICY_TYPE", GetPolicySlotLabel(policyType))
        end,
        --IsHidden = function()
        --return GetPolicyTypeForSlot(slotIndex) == CAI_EMPTY_POLICY_TYPE
        --end,
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

local function CreatePolicySlotWidget(slotData, slotOrdinal)
    local rowIndex = slotData and slotData.UI_RowIndex or nil
    local slotIndex = slotData and slotData.GC_SlotIndex or nil

    local widget = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentPolicySlot"), "TreeviewItem", {
        GetLabel = function()
            local policyType = GetPolicyTypeForSlot(slotIndex)
            local isEmpty = policyType == CAI_EMPTY_POLICY_TYPE
            if isEmpty then
                return Locale.Lookup("LOC_CAI_GOVERNMENT_EMPTY_SLOT", slotOrdinal)
            end
            return GetPolicyName(policyType)
        end,
        GetTooltip = function()
            local policyType = GetPolicyTypeForSlot(slotIndex)
            local isEmpty = policyType == CAI_EMPTY_POLICY_TYPE
            if isEmpty then return Locale.Lookup("LOC_CAI_GOVERNMENT_EMPTY_SLOT", slotOrdinal) end
            return GetPolicyTooltip(policyType)
        end,
        OnFocusEnter = PlayGovernmentHoverSound,
    })

    AddPolicySlotDetailChildren(widget, slotIndex)

    if IsAbleToChangePolicies() then
        widget.OnClick = function()
            OpenPolicyPickerForSlot(slotIndex, rowIndex)
        end
        widget:AddInputBinding({
            Key = Keys.VK_DELETE,
            Action = function()
                return RemovePolicyFromSlot(slotIndex, GetPolicyTypeForSlot(slotIndex))
            end,
        })
    end

    widget:AddInputBinding({
        Key = Keys.VK_RETURN,
        IsShift = true,
        Action = function()
            local policyType = GetPolicyTypeForSlot(slotIndex)
            if policyType == CAI_EMPTY_POLICY_TYPE then return true end
            return OpenCivilopediaForPolicy(policyType)
        end,
    })

    return widget
end

local function GetPolicyRowSummary(rowIndex)
    local slots = GetLiveSlotDataForRow(rowIndex)
    local used = 0
    local names = {}
    for _, slotData in ipairs(slots) do
        local policyType = GetPolicyTypeForSlot(slotData.GC_SlotIndex)
        if policyType ~= CAI_EMPTY_POLICY_TYPE then
            used = used + 1
            table.insert(names, GetPolicyName(policyType))
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

local function CreatePolicyRowPlaceholder()
    return mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentPolicyRowPlaceholder"), "TreeviewItem", {
        GetLabel = function() return "" end,
        IsHidden = function() return true end,
    })
end

local function RebuildPolicyRowChildren(rowWidget, rowIndex)
    if not rowWidget then return end
    rowWidget:ClearChildren()

    local slots = GetLiveSlotDataForRow(rowIndex)
    if #slots > 0 then
        for slotOrdinal, slotData in ipairs(slots) do
            rowWidget:AddChild(CreatePolicySlotWidget(slotData, slotOrdinal))
        end
    else
        rowWidget:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentStaticText"), "TreeviewItem", {
            GetLabel = function() return GetEmptyRowText(rowIndex) end,
        }))
    end
end

local function AddPolicyRows(parent)
    for _, row in ipairs(CAI_ROW_ORDER) do
        local rowIndex = row.Index
        local rowNode = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentPolicyRow"), "TreeviewItem", {
            GetLabel = function() return GetRowName(rowIndex) end,
            GetTooltip = function() return GetPolicyRowSummary(rowIndex) end,
            OnToggleExpanded = function(w, isExpanded)
                if isExpanded then
                    RebuildPolicyRowChildren(w, rowIndex)
                elseif not w.Children or #w.Children == 0 then
                    w:AddChild(CreatePolicyRowPlaceholder())
                end
            end,
        })
        rowNode:AddChild(CreatePolicyRowPlaceholder())
        parent:AddChild(rowNode)
    end
end

function BuildPoliciesBody()
    if m_caiPendingGovernmentPoliciesRefresh and not m_caiSuppressRebuild then
        m_caiPendingGovernmentPoliciesRefresh = false
        RefreshAllData()
        RefreshSlotPolicyTypesFromLivePlayer()
    end
    local tree = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentPoliciesTree"), "Treeview", {
        GetLabel = function() return ControlText(Controls.ButtonPolicies) end,
    })
    AddPolicyRows(tree)

    return tree
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
    if slots ~= "" then table.insert(parts, Locale.Lookup("LOC_CAI_GOVERNMENT_SLOTS", slots)) end

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

function BuildGovernmentsBody()
    local tree = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentGovernmentsTree"), "Treeview", {
        GetLabel = function() return ControlText(Controls.ButtonGovernments) end,
    })

    local governments = {}
    for governmentType in pairs(g_kGovernments or {}) do
        table.insert(governments, governmentType)
    end
    table.sort(governments, SortGovernmentsBySlotsThenName)

    for _, governmentType in ipairs(governments) do
        local governmentTypeForItem = governmentType
        local government = g_kGovernments[governmentTypeForItem]
        local item = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentGovernmentItem"), "TreeviewItem", {
            GetLabel = function() return Locale.Lookup(government.Name) end,
            GetTooltip = function()
                return JoinNonEmpty({
                    GetGovernmentStatusLine(governmentTypeForItem),
                    table.concat(GetGovernmentDetailParts(governmentTypeForItem), "[NEWLINE]"),
                }, "[NEWLINE]")
            end,
            IsDisabled = function()
                return not IsGovernmentUnlockedForPlayer(governmentTypeForItem)
            end,
            OnFocusEnter = PlayGovernmentHoverSound,
            OnClick = function(w)
                if w and w.IsDisabled and w:IsDisabled() then return end
                OnGovernmentSelected(governmentTypeForItem)
            end,
        })

        for _, part in ipairs(GetGovernmentDetailParts(governmentTypeForItem)) do
            local detailText = part
            item:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentGovernmentDetail"), "TreeviewItem", {
                GetLabel = function() return detailText end,
            }))
        end

        if IsGovernmentSelected(governmentTypeForItem) then
            for _, part in ipairs(GetCurrentGovernmentHeritageParts(governmentTypeForItem)) do
                local detailText = part
                item:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentHeritageDetail"), "TreeviewItem", {
                    GetLabel = function() return detailText end,
                }))
            end

            local carryover = GetCarryoverBonusParts(governmentTypeForItem)
            if #carryover > 0 then
                for _, part in ipairs(carryover) do
                    local detailText = part
                    item:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentCarryoverDetail"), "TreeviewItem",
                        {
                            GetLabel = function() return detailText end,
                        }))
                end
            else
                item:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentCarryoverDetail"), "TreeviewItem", {
                    GetLabel = function() return Locale.Lookup("LOC_GOVT_NO_LEGACY_BONUS") end,
                }))
            end
        end

        tree:AddChild(item)
    end

    return tree
end

local function SetCAITab(selectedTab)
    m_caiTab = selectedTab
    if not m_caiTabBar then return end
    m_caiTabBar:SetDefaultIndex(selectedTab)
    m_caiTabBar:SetFocusedChild(selectedTab)
end

function RebuildBody(selectedTab, focusBody)
    if not m_caiPanel then return end
    if m_caiBody then
        m_caiBody:Destroy()
        m_caiBody = nil
    end
    for _, button in ipairs(m_caiActionButtons) do
        button:Destroy()
    end
    m_caiActionButtons = {}

    SetCAITab(selectedTab or m_caiTab or CAI_TAB_GOVERNMENTS)

    if m_caiTab == CAI_TAB_GOVERNMENTS then
        m_caiBody = BuildGovernmentsBody()
    else
        m_caiTab = CAI_TAB_POLICIES
        m_caiBody = BuildPoliciesBody()
    end

    if m_caiBody then
        m_caiPanel:AddChild(m_caiBody)
        if m_caiTab == CAI_TAB_POLICIES then
            table.insert(m_caiActionButtons,
                mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentConfirmButton"), "Button", {
                    GetLabel = function() return ControlText(Controls.ConfirmPolicies) end,
                    IsHidden = function() return ControlIsHidden(Controls.ConfirmPolicies) end,
                    IsDisabled = function() return ControlIsDisabled(Controls.ConfirmPolicies) end,
                    OnFocusEnter = PlayGovernmentHoverSound,
                    OnClick = function()
                        OnConfirmPolicies()
                        return true
                    end,
                }))
            table.insert(m_caiActionButtons,
                mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentViewAllPoliciesButton"), "Button", {
                    GetLabel = function() return Locale.Lookup("LOC_CAI_GOVERNMENT_VIEW_ALL_POLICIES") end,
                    OnFocusEnter = PlayGovernmentHoverSound,
                    OnClick = OpenAllPoliciesTree,
                }))
            table.insert(m_caiActionButtons,
                mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentUnlockPoliciesButton"), "Button", {
                    GetLabel = function() return ControlText(Controls.UnlockPolicies) end,
                    IsHidden = function() return ControlIsHidden(Controls.UnlockPolicies) end,
                    IsDisabled = function() return ControlIsDisabled(Controls.UnlockPolicies) end,
                    OnFocusEnter = PlayGovernmentHoverSound,
                    OnClick = function()
                        OnUnlockPolicies()
                        return true
                    end,
                }))
        elseif m_caiTab == CAI_TAB_GOVERNMENTS then
            table.insert(m_caiActionButtons,
                mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentUnlockGovernmentsButton"), "Button", {
                    GetLabel = function() return ControlText(Controls.UnlockGovernments) end,
                    IsHidden = function() return ControlIsHidden(Controls.UnlockGovernmentsContainer) end,
                    IsDisabled = function() return ControlIsDisabled(Controls.UnlockGovernments) end,
                    OnFocusEnter = PlayGovernmentHoverSound,
                    OnClick = function()
                        OnUnlockGovernments()
                        return true
                    end,
                }))
        end
        for _, button in ipairs(m_caiActionButtons) do
            m_caiPanel:AddChild(button)
        end
    end

    if focusBody and not m_caiUserSwitchedTab and m_caiBody and m_caiBody.Children and m_caiBody.Children[2] then
        mgr:SetFocus(m_caiBody.Children[2])
    end
end

local function CreateTabWidget(tab, control, switchFunc)
    return mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentTab"), "Tab", {
        GetLabel = function() return ControlText(control) end,
        IsHidden = function() return ControlIsHidden(control) end,
        IsDisabled = function() return ControlIsDisabled(control) end,
        OnFocusEnter = function()
            PlayGovernmentHoverSound()
            if (m_caiTab or CAI_TAB_GOVERNMENTS) == tab then return true end
            m_caiUserSwitchedTab = true
            switchFunc()
            return true
        end,
        OnClick = function()
            if (m_caiTab or CAI_TAB_GOVERNMENTS) == tab then return true end
            m_caiUserSwitchedTab = true
            switchFunc()
            return true
        end,
    })
end

local function BuildPanel()
    if not mgr then return end

    m_caiPanel = mgr:CreateUIWidget("CAIGovernmentScreenPanel", "Panel", {
        GetLabel = function() return ControlText(Controls.ModalScreenTitle) end,
    })

    m_caiTabBar = mgr:CreateUIWidget("CAIGovernmentScreenTabBar", "TabBar", {
        GetLabel = function() return ControlText(Controls.ModalScreenTitle) end,
    })
    m_caiPanel:AddChild(m_caiTabBar)

    m_caiTabs[CAI_TAB_GOVERNMENTS] = CreateTabWidget(CAI_TAB_GOVERNMENTS, Controls.ButtonGovernments,
        SwitchTabToGovernments)
    m_caiTabs[CAI_TAB_POLICIES] = CreateTabWidget(CAI_TAB_POLICIES, Controls.ButtonPolicies, SwitchTabToPolicies)

    m_caiTabBar:AddChild(m_caiTabs[CAI_TAB_GOVERNMENTS])
    m_caiTabBar:AddChild(m_caiTabs[CAI_TAB_POLICIES])
end

local function PushPanel()
    if not mgr then return end
    if not m_caiPanel then BuildPanel() end
    if not m_caiPanel then return end
    if not mgr:HasWidget(m_caiPanel) then
        mgr:Push(m_caiPanel, PopupPriority.Low)
    end
end

local function PopPanel()
    if m_caiPanel and mgr and mgr:HasWidget(m_caiPanel) then
        mgr:RemoveFromStack(m_caiPanel:GetId())
    elseif m_caiPanel then
        m_caiPanel:Destroy()
    end
    m_caiPanel = nil
    m_caiTabBar = nil
    m_caiBody = nil
    m_caiActionButtons = {}
    m_caiTabs = {}
    m_caiTab = nil
end

OnOpenGovernmentScreen = WrapFunc(OnOpenGovernmentScreen, function(orig, screenEnum)
    if not m_caiPanel then BuildPanel() end
    orig(screenEnum)
    PushPanel()
    if not m_caiBody then
        RebuildBody(m_caiTab or CAI_TAB_GOVERNMENTS, true)
    end
end)

Close = WrapFunc(Close, function(orig)
    orig()
    if ContextPtr:IsHidden() then
        PopPanel()
    end
end)


SwitchTabToPolicies = WrapFunc(SwitchTabToPolicies, function(orig)
    orig()
    SetCAITab(CAI_TAB_POLICIES)
    RebuildBody(CAI_TAB_POLICIES, not m_caiUserSwitchedTab)
    m_caiUserSwitchedTab = false
end)

SwitchTabToGovernments = WrapFunc(SwitchTabToGovernments, function(orig)
    orig()
    SetCAITab(CAI_TAB_GOVERNMENTS)
    RebuildBody(CAI_TAB_GOVERNMENTS, not m_caiUserSwitchedTab)
    m_caiUserSwitchedTab = false
end)

SwitchTabToMyGovernment = WrapFunc(SwitchTabToMyGovernment, function(orig)
    orig()
    m_caiUserSwitchedTab = true
    SwitchTabToGovernments()
end)

OnUnlockPolicies = WrapFunc(OnUnlockPolicies, function(orig)
    orig()
    RebuildBody(m_caiTab or CAI_TAB_GOVERNMENTS, false)
end)

OnUnlockGovernments = WrapFunc(OnUnlockGovernments, function(orig)
    orig()
    RebuildBody(m_caiTab or CAI_TAB_GOVERNMENTS, false)
end)

RealizeActivePoliciesRows = WrapFunc(RealizeActivePoliciesRows, function(orig)
    orig()

    if not m_caiSuppressRebuild then
        RefreshSlotPolicyTypesFromLivePlayer()
    end
end)

PopulateLivePlayerData = WrapFunc(PopulateLivePlayerData, function(orig, ePlayer)
    orig(ePlayer)
    RefreshSlotPolicyTypesFromLivePlayer()
end)

RefreshAllData = WrapFunc(RefreshAllData, function(orig)
    orig()
    RefreshSlotPolicyTypesFromLivePlayer()
end)

OnAcceptGovernmentChange = WrapFunc(OnAcceptGovernmentChange, function(orig)
    RefreshAllData()
    orig()
    if m_caiPanel and not ContextPtr:IsHidden() then
        m_caiPendingGovernmentPoliciesRefresh = true
    end
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, input)
    local top = mgr and mgr:GetTop()
    if top ~= m_caiPanel and top ~= m_caiPicker and top ~= m_caiPoliciesTree then return false end
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
