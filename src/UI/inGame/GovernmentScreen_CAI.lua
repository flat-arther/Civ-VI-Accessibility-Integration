include("caiUtils")
include("GovernmentScreen")

local mgr = ExposedMembers.CAI_UIManager

local CAI_TAB_POLICIES = 1
local CAI_TAB_GOVERNMENTS = 2
local CAI_SCREEN_GOVERNMENTS = 2
local CAI_SCREEN_POLICIES = 3
local CAI_EMPTY_POLICY_TYPE = EMPTY_POLICY_TYPE or "empty"

local CAI_ROW_ORDER = {
    { Index = ROW_INDEX and ROW_INDEX.MILITARY or 1, SlotType = "SLOT_MILITARY",   LabelControl = "LabelMilitary",   Tooltip = "LOC_GOVT_POLICY_TYPE_MILITARY",   Empty = "LOC_GOVT_NO_MILITARY_SLOTS" },
    { Index = ROW_INDEX and ROW_INDEX.ECONOMIC or 2, SlotType = "SLOT_ECONOMIC",   LabelControl = "LabelEconomic",   Tooltip = "LOC_GOVT_POLICY_TYPE_ECONOMIC",   Empty = "LOC_GOVT_NO_ECONOMIC_SLOTS" },
    { Index = ROW_INDEX and ROW_INDEX.DIPLOMAT or 3, SlotType = "SLOT_DIPLOMATIC", LabelControl = "LabelDiplomatic", Tooltip = "LOC_GOVT_POLICY_TYPE_DIPLOMATIC", Empty = "LOC_GOVT_NO_DIPLOMACY_SLOTS" },
    { Index = ROW_INDEX and ROW_INDEX.WILDCARD or 4, SlotType = "SLOT_WILDCARD",   LabelControl = "LabelWildcard",   Tooltip = "LOC_GOVT_POLICY_TYPE_WILDCARD",   Empty = "LOC_GOVT_NO_WILDCARD_SLOTS" },
}

local m_caiPanel = nil
local m_caiTabBar = nil
local m_caiBody = nil
local m_caiActionButtons = {}
local m_caiTabs = {}
local m_caiTab = CAI_TAB_POLICIES
local m_caiRebuilding = false
local m_caiSyncingTab = false
local m_caiCaptureMode = nil
local m_caiCatalogCards = {}
local m_caiActiveRows = {}
local m_caiSlotPolicyTypes = {}
local m_caiGovernmentInstances = {}
local m_caiSuppressRebuild = false

local CAI_KEY_POLICY_SLOT = "PolicySlot"
local CAI_KEY_ROW_ID = "RowNum"

local function ResetCapturedActiveRows()
    m_caiActiveRows = {}
    for _, row in ipairs(CAI_ROW_ORDER) do
        m_caiActiveRows[row.Index] = { SlotArray = {} }
    end
end

ResetCapturedActiveRows()

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

local function RefreshCapturedActiveRowsFromLivePlayer()
    ResetCapturedActiveRows()
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
            table.insert(m_caiActiveRows[rowIndex].SlotArray, {
                GC_PolicyType = policyType,
                GC_SlotIndex = slotIndex,
                UI_RowIndex = rowIndex,
            })
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
    })
    AddPolicyDetailChildren(item, policyType)

    if action then
        item:AddInputBinding({
            Key = Keys.VK_RETURN,
            Action = function(w)
                if w and w.IsDisabled and w:IsDisabled() then return true end
                return action(policyType)
            end,
        })
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

    local picker = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentPolicyPicker"), "Treeview", {
        GetLabel = function()
            return Locale.Lookup("LOC_CAI_GOVERNMENT_CHOOSE_POLICY", GetRowName(rowIndex))
        end,
    })
    picker:AddInputBinding({
        Key = Keys.VK_ESCAPE,
        Action = function()
            if mgr then mgr:RemoveFromStack(picker:GetId()) end
            return true
        end,
    })

    BuildPolicyCategoryTree(picker, {
        RowIndex = rowIndex,
        StartExpanded = true,
        Action = function(policyType)
            local handled = AssignPolicyToSlot(policyType, slotIndex, rowIndex)
            if mgr then mgr:RemoveFromStack(picker:GetId()) end
            return handled
        end,
    })

    mgr:Push(picker)
    return true
end

local function OpenAllPoliciesTree()
    local tree = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentAllPoliciesTree"), "Treeview", {
        GetLabel = function() return Locale.Lookup("LOC_CAI_GOVERNMENT_VIEW_ALL_POLICIES") end,
    })
    tree:AddInputBinding({
        Key = Keys.VK_ESCAPE,
        Action = function()
            if mgr then mgr:RemoveFromStack(tree:GetId()) end
            return true
        end,
    })

    BuildPolicyCategoryTree(tree, { IncludeActive = true })

    mgr:Push(tree)
    return true
end

local function AddPolicySlotDetailChildren(widget, slotIndex)
    widget:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentPolicyDetail"), "TreeviewItem", {
        GetLabel = function()
            local policyType = GetPolicyTypeForSlot(slotIndex)
            return Locale.Lookup("LOC_CAI_GOVERNMENT_POLICY_TYPE", GetPolicySlotLabel(policyType))
        end,
        IsHidden = function()
            return GetPolicyTypeForSlot(slotIndex) == CAI_EMPTY_POLICY_TYPE
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
    })

    AddPolicySlotDetailChildren(widget, slotIndex)

    if IsAbleToChangePolicies() then
        widget:AddInputBindings({
            {
                Key = Keys.VK_RETURN,
                Action = function()
                    return OpenPolicyPickerForSlot(slotIndex, rowIndex)
                end,
            },
            {
                Key = Keys.VK_DELETE,
                Action = function()
                    return RemovePolicyFromSlot(slotIndex, GetPolicyTypeForSlot(slotIndex))
                end,
            },
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
    local rowData = m_caiActiveRows[rowIndex]
    local slots = rowData and rowData.SlotArray or {}
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

local function AddPolicyRows(parent)
    RefreshCapturedActiveRowsFromLivePlayer()
    for _, row in ipairs(CAI_ROW_ORDER) do
        local rowIndex = row.Index
        local rowNode = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentPolicyRow"), "TreeviewItem", {
            GetLabel = function() return GetRowName(rowIndex) end,
            GetTooltip = function() return GetPolicyRowSummary(rowIndex) end,
        })

        local rowData = m_caiActiveRows[rowIndex]
        if rowData and rowData.SlotArray and #rowData.SlotArray > 0 then
            for slotOrdinal, slotData in ipairs(rowData.SlotArray) do
                rowNode:AddChild(CreatePolicySlotWidget(slotData, slotOrdinal))
            end
        else
            rowNode:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentStaticText"), "TreeviewItem", {
                GetLabel = function() return GetEmptyRowText(rowIndex) end,
            }))
        end

        parent:AddChild(rowNode)
    end
end

function BuildPoliciesBody()
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

local function IsCapturedGovernmentUnlocked(governmentType)
    local inst = m_caiGovernmentInstances[governmentType]
    if not inst then return false end
    if inst.Disabled and inst.Disabled.IsHidden then
        return inst.Disabled:IsHidden()
    end
    return not ControlIsDisabled(inst.Top)
end

local function GetGovernmentDetailParts(governmentType)
    local government = g_kGovernments and g_kGovernments[governmentType] or nil
    if not government then return {} end

    local parts = {}
    if IsGovernmentSelected(governmentType) then
        table.insert(parts, Locale.Lookup("LOC_CAI_STATE_SELECTED"))
    elseif not IsCapturedGovernmentUnlocked(governmentType) then
        table.insert(parts, Locale.Lookup("LOC_CAI_STATE_DISABLED"))
    end

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

    if not IsCapturedGovernmentUnlocked(governmentType) then
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
            GetTooltip = function() return table.concat(GetGovernmentDetailParts(governmentTypeForItem), "[NEWLINE]") end,
            IsDisabled = function()
                return not IsCapturedGovernmentUnlocked(governmentTypeForItem)
            end,
        })
        item:AddInputBinding({
            Key = Keys.VK_RETURN,
            Action = function(w)
                if w and w.IsDisabled and w:IsDisabled() then return true end
                m_caiSuppressRebuild = true
                OnGovernmentSelected(governmentTypeForItem)
                m_caiSuppressRebuild = false
                return true
            end,
        })

        for _, part in ipairs(GetGovernmentDetailParts(governmentTypeForItem)) do
            local detailText = part
            item:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentGovernmentDetail"), "TreeviewItem", {
                GetLabel = function() return detailText end,
            }))
        end

        tree:AddChild(item)
    end

    return tree
end

local function GetSelectedCAITab()
    return m_caiTab == CAI_TAB_GOVERNMENTS and CAI_TAB_GOVERNMENTS or CAI_TAB_POLICIES
end

local function SyncTabBarSelection()
    if not m_caiTabBar then return end
    local selectedTab = GetSelectedCAITab()
    local selectedWidget = m_caiTabs[selectedTab]
    if not selectedWidget then return end

    for index, tab in ipairs(m_caiTabBar.Children or {}) do
        if tab == selectedWidget then
            m_caiTabBar.DefaultIndex = index
            m_caiTabBar.FocusedChild = selectedWidget
            return
        end
    end
end

function RebuildBody(selectedTab)
    if not m_caiPanel then return end

    if m_caiBody then
        m_caiBody:Destroy()
        m_caiBody = nil
    end
    for _, button in ipairs(m_caiActionButtons) do
        button:Destroy()
    end
    m_caiActionButtons = {}

    m_caiTab = selectedTab or GetSelectedCAITab()
    SyncTabBarSelection()

    if m_caiTab == CAI_TAB_GOVERNMENTS then
        m_caiBody = BuildGovernmentsBody()
    else
        m_caiTab = CAI_TAB_POLICIES
        m_caiBody = BuildPoliciesBody()
    end

    if m_caiBody then
        local closeButton = m_caiPanel.CloseButton
        if closeButton then
            closeButton:RemoveFromParent()
        end
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
                mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentUnlockButton"), "Button", {
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
                mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentUnlockButton"), "Button", {
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
        if closeButton then
            m_caiPanel:AddChild(closeButton)
        end
    end
end

local function ActivateVanillaTab(control, fallback)
    if control and control.CallbackFunc then
        control.CallbackFunc()
    elseif fallback then
        fallback()
    end
end

local function SelectVanillaTabFromCAI(tab)
    if m_caiSyncingTab then return true end

    m_caiSyncingTab = true
    if tab == CAI_TAB_GOVERNMENTS then
        ActivateVanillaTab(Controls.ButtonGovernments, SwitchTabToGovernments)
    else
        ActivateVanillaTab(Controls.ButtonPolicies, SwitchTabToPolicies)
    end
    m_caiSyncingTab = false
    m_caiTab = tab
    RebuildBody(tab)
    return true
end

local function CreateTabWidget(tab, control)
    return mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentTab"), "Tab", {
        GetLabel = function() return ControlText(control) end,
        IsHidden = function() return ControlIsHidden(control) end,
        IsDisabled = function() return ControlIsDisabled(control) end,
        OnFocusEnter = function()
            PlayGovernmentHoverSound()
            return SelectVanillaTabFromCAI(tab)
        end,
        OnClick = function()
            return SelectVanillaTabFromCAI(tab)
        end,
    })
end

local function GetSelectedTabDefaultIndex()
    local selectedTab = GetSelectedCAITab()
    for index, tab in ipairs(m_caiTabBar.Children or {}) do
        if tab == m_caiTabs[selectedTab] then
            return index
        end
    end
    return 1
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

    m_caiTabs[CAI_TAB_POLICIES] = CreateTabWidget(CAI_TAB_POLICIES, Controls.ButtonPolicies)
    m_caiTabs[CAI_TAB_GOVERNMENTS] = CreateTabWidget(CAI_TAB_GOVERNMENTS, Controls.ButtonGovernments)

    m_caiTabBar:AddChild(m_caiTabs[CAI_TAB_POLICIES])
    m_caiTabBar:AddChild(m_caiTabs[CAI_TAB_GOVERNMENTS])
    m_caiTabBar.DefaultIndex = GetSelectedTabDefaultIndex()

    m_caiPanel.CloseButton = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIGovernmentCloseButton"), "Button", {
        GetLabel = function() return ControlText(Controls.ModalScreenClose) end,
        OnClick = function()
            OnClose()
            return true
        end,
    })
    m_caiPanel:AddChild(m_caiPanel.CloseButton)

    RebuildBody()
end

local function PushPanel()
    if not mgr then return end
    if not m_caiPanel then BuildPanel() end
    if not m_caiPanel then return end
    if m_caiTabBar then
        SyncTabBarSelection()
    end
    RebuildBody()
    if not mgr:HasWidget(m_caiPanel) then
        mgr:Push(m_caiPanel)
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
end

OnOpenGovernmentScreen = WrapFunc(OnOpenGovernmentScreen, function(orig, screenEnum)
    if screenEnum == CAI_SCREEN_GOVERNMENTS then
        m_caiTab = CAI_TAB_GOVERNMENTS
    else
        m_caiTab = CAI_TAB_POLICIES
    end
    orig(screenEnum)
    PushPanel()
end)

Close = WrapFunc(Close, function(orig)
    orig()
    if ContextPtr:IsHidden() then
        PopPanel()
    end
end)

SwitchTabToMyGovernment = WrapFunc(SwitchTabToMyGovernment, function(orig)
    orig()
    m_caiTab = CAI_TAB_POLICIES
    if m_caiPanel and not m_caiSyncingTab then RebuildBody(CAI_TAB_POLICIES) end
end)

SwitchTabToPolicies = WrapFunc(SwitchTabToPolicies, function(orig)
    orig()
    m_caiTab = CAI_TAB_POLICIES
    if m_caiPanel and not m_caiSyncingTab then RebuildBody(CAI_TAB_POLICIES) end
end)

SwitchTabToGovernments = WrapFunc(SwitchTabToGovernments, function(orig)
    orig()
    m_caiTab = CAI_TAB_GOVERNMENTS
    if m_caiPanel and not m_caiSyncingTab then RebuildBody(CAI_TAB_GOVERNMENTS) end
end)

OnAcceptGovernmentChange = WrapFunc(OnAcceptGovernmentChange, function(orig)
    orig()
    if m_caiPanel and not ContextPtr:IsHidden() then
        m_caiTab = CAI_TAB_POLICIES
        SyncTabBarSelection()
        RebuildBody(CAI_TAB_POLICIES)
    end
end)

RealizeGovernmentInstance = WrapFunc(RealizeGovernmentInstance,
    function(orig, governmentType, inst, isCivilopediaAvailable)
        local result = orig(governmentType, inst, isCivilopediaAvailable)
        if governmentType and inst then
            m_caiGovernmentInstances[governmentType] = inst
        end
        return result
    end)

RealizePolicyCard = WrapFunc(RealizePolicyCard, function(orig, cardInstance, policyType)
    orig(cardInstance, policyType)
    if not cardInstance or not policyType then return end

    if m_caiCaptureMode == "catalog" then
        table.insert(m_caiCatalogCards, {
            PolicyType = policyType,
            Instance = cardInstance,
        })
    elseif m_caiCaptureMode == "active" then
        local rowIndex = cardInstance[CAI_KEY_ROW_ID]
        local slotIndex = cardInstance[CAI_KEY_POLICY_SLOT]
        if rowIndex and slotIndex then
            if not m_caiActiveRows[rowIndex] then
                m_caiActiveRows[rowIndex] = { SlotArray = {} }
            end
            table.insert(m_caiActiveRows[rowIndex].SlotArray, {
                GC_PolicyType = policyType,
                GC_SlotIndex = slotIndex,
                UI_RowIndex = rowIndex,
                Instance = cardInstance,
            })
        end
    end
end)

RealizePolicyCatalog = WrapFunc(RealizePolicyCatalog, function(orig)
    m_caiCatalogCards = {}
    m_caiCaptureMode = "catalog"
    orig()
    m_caiCaptureMode = nil
    if m_caiSuppressRebuild then return end
    if m_caiPanel and m_caiTab == CAI_TAB_POLICIES and not m_caiRebuilding and not m_caiSyncingTab then
        RebuildBody(
            CAI_TAB_POLICIES)
    end
end)

RealizeActivePoliciesRows = WrapFunc(RealizeActivePoliciesRows, function(orig)
    ResetCapturedActiveRows()
    m_caiCaptureMode = "active"
    orig()
    m_caiCaptureMode = nil
    if not m_caiSuppressRebuild then
        RefreshCapturedActiveRowsFromLivePlayer()
    end
    if m_caiSuppressRebuild then return end
    if m_caiPanel and m_caiTab == CAI_TAB_POLICIES and not m_caiRebuilding and not m_caiSyncingTab then
        RebuildBody(
            CAI_TAB_POLICIES)
    end
end)

RealizeMyGovernmentPage = WrapFunc(RealizeMyGovernmentPage, function(orig)
    orig()
    if m_caiSuppressRebuild then return end
    if m_caiPanel and m_caiTab == CAI_TAB_POLICIES and not m_caiSyncingTab then RebuildBody(CAI_TAB_POLICIES) end
end)

RealizeGovernmentsPage = WrapFunc(RealizeGovernmentsPage, function(orig)
    orig()
end)

RealizePoliciesPage = WrapFunc(RealizePoliciesPage, function(orig)
    orig()
    if m_caiSuppressRebuild then return end
    if m_caiPanel and m_caiTab == CAI_TAB_POLICIES and not m_caiSyncingTab then RebuildBody(CAI_TAB_POLICIES) end
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, input)
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
