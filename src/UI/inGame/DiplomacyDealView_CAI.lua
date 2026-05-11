include("caiUtils")
include("DiplomacyDealView")

local mgr = ExposedMembers.CAI_UIManager

local SIDE_LOCAL = "local"
local SIDE_OTHER = "other"

-- Vanilla constants that are file-local in DiplomacyDealView.lua and therefore
-- unreachable from this wrapper.
local DEFAULT_ONE_TIME_GOLD = 100
local DEFAULT_MULTI_TURN_GOLD = 10
local DEFAULT_MULTI_TURN_GOLD_DURATION = 30

local m_ui = {
    root = nil,
    tabBar = nil,
    tabMe = nil,
    tabThem = nil,
    offersTree = nil,
    inventoryTree = nil,
    actionsList = nil,
    leaderLine = nil,
}

local m_state = {
    activeSide = SIDE_LOCAL,
    built = false,
    isDemand = false,
    initiatedByLocal = false,
    hiddenOfferSide = nil,
    editWidget = nil,
}

local m_players = {
    local_ = nil,
    other = nil,
}

-- ============================================================================
-- Control helpers
-- ============================================================================

local function PlayHover()
    UI.PlaySound("Main_Menu_Mouse_Over")
end

local function ControlIsHidden(control)
    return control and control.IsHidden and control:IsHidden() or false
end

local function ControlIsDisabled(control)
    return control and control.IsDisabled and control:IsDisabled() or false
end

local function ControlText(control)
    if not control or not control.GetText then return "" end
    return control:GetText() or ""
end

local function ControlTooltip(control)
    if not control or not control.GetToolTipString then return "" end
    return control:GetToolTipString() or ""
end

local function JoinNonEmpty(parts, sep)
    local out = {}
    for _, part in ipairs(parts) do
        if part and part ~= "" then table.insert(out, part) end
    end
    return table.concat(out, sep)
end

-- ============================================================================
-- Side accessors
-- ============================================================================

local function GetSidePlayer(side)
    if side == SIDE_LOCAL then return m_players.local_ end
    return m_players.other
end

local function GetSideOtherPlayer(side)
    if side == SIDE_LOCAL then return m_players.other end
    return m_players.local_
end

local function GetActivePlayer()
    return GetSidePlayer(m_state.activeSide)
end

local function GetWorkingDeal()
    if not m_players.local_ or not m_players.other then return nil end
    return DealManager.GetWorkingDeal(DealDirection.OUTGOING,
        m_players.local_:GetID(), m_players.other:GetID())
end

local function IsDemandFromOther()
    return m_state.isDemand and not m_state.initiatedByLocal
end

local function CaptureSessionInfo()
    m_state.isDemand = ms_bIsDemand == true
    m_state.initiatedByLocal = false
    m_state.hiddenOfferSide = nil

    if not m_players.other then return end
    local sessionID = DiplomacyManager.FindOpenSessionID(
        Game.GetLocalPlayer(), m_players.other:GetID())
    if sessionID then
        local info = DiplomacyManager.GetSessionInfo(sessionID)
        if info and info.FromPlayer == Game.GetLocalPlayer() then
            m_state.initiatedByLocal = true
        end
    end

    if m_state.isDemand then
        if m_state.initiatedByLocal then
            m_state.hiddenOfferSide = SIDE_LOCAL
        else
            m_state.hiddenOfferSide = SIDE_OTHER
        end
    end
end

-- ============================================================================
-- Item label helpers
-- ============================================================================

-- Vanilla uses pDealItem:GetSubTypeNameID() as the agreement title (see
-- DiplomacyDealView.lua:2370); GetValueTypeNameID() is only the secondary
-- parameter (alliance subtype, war target, ...) and is nil for most agreements.
local function GetAgreementDisplayName(pDealItem)
    local subName = pDealItem.GetSubTypeNameID and pDealItem:GetSubTypeNameID()
    if subName and subName ~= "" then return Locale.Lookup(subName) end
    local valueName = pDealItem:GetValueTypeNameID()
    if valueName and valueName ~= "" then return Locale.Lookup(valueName) end
    return ""
end

local function GetDealItemLabel(pDealItem)
    local itemType = pDealItem:GetType()
    local amount = pDealItem:GetAmount()
    local duration = pDealItem:GetDuration()

    local label = ""
    if itemType == DealItemTypes.GOLD then
        if duration == 0 then
            label = Locale.Lookup("LOC_DIPLOMACY_DEAL_ONE_TIME") .. ": "
                .. Locale.Lookup("LOC_YIELD_GOLD_NAME") .. " " .. tostring(amount)
        else
            label = Locale.Lookup("LOC_DIPLOMACY_DEAL_GOLD_PER_TURN") .. " " .. tostring(amount)
        end
    elseif itemType == DealItemTypes.RESOURCES then
        local desc = GameInfo.Resources[pDealItem:GetValueType()]
        local resName = desc and Locale.Lookup(desc.Name) or ""
        if duration == 0 then
            label = resName .. " x" .. tostring(amount)
        else
            label = resName .. " x" .. tostring(amount) .. " ("
                .. Locale.Lookup("LOC_DIPLOMACY_DEAL_FOR_30_TURNS") .. ")"
        end
    elseif itemType == DealItemTypes.AGREEMENTS then
        local name = GetAgreementDisplayName(pDealItem)
        if duration > 0 and name ~= "" then
            label = name .. " (" .. tostring(duration) .. ")"
        else
            label = name
        end
        local valueName = pDealItem:GetValueTypeNameID()
        if valueName and valueName ~= "" then
            local secondary = Locale.Lookup(valueName)
            if secondary ~= "" and secondary ~= name then
                label = JoinNonEmpty({ label, secondary }, " - ")
            end
        end
    else
        local typeName = pDealItem:GetValueTypeNameID()
        label = typeName and Locale.Lookup(typeName) or ""
    end

    if pDealItem:IsUnacceptable() then
        label = label .. " (" .. Locale.Lookup("LOC_DIPLOMACY_DEAL_UNACCEPTABLE") .. ")"
    end
    return label
end

-- ============================================================================
-- Offer-edit widgets (pushed directly to the stack, no wrapping Dialog)
-- ============================================================================

local function CloseEditWidget()
    if not m_state.editWidget then return end
    if mgr and mgr:HasWidget(m_state.editWidget) then
        mgr:RemoveFromStack(m_state.editWidget:GetId())
    else
        m_state.editWidget:Destroy()
    end
    m_state.editWidget = nil
end

local function ClipAmount(value, maxAmount)
    if value < 1 then return 1 end
    if maxAmount and value > maxAmount then return maxAmount end
    return value
end

local function GetAmountHeader(pDealItem)
    local itemType = pDealItem:GetType()
    if itemType == DealItemTypes.GOLD then
        return Locale.Lookup("LOC_YIELD_GOLD_NAME")
    elseif itemType == DealItemTypes.RESOURCES then
        local desc = GameInfo.Resources[pDealItem:GetValueType()]
        return desc and Locale.Lookup(desc.Name) or ""
    end
    local typeName = pDealItem:GetValueTypeNameID()
    return typeName and Locale.Lookup(typeName) or ""
end

local function PushAmountEditor(pDealItem)
    CloseEditWidget()

    local dealItemID = pDealItem:GetID()
    local maxAmount = pDealItem:GetMaxAmount()
    local startValue = tostring(pDealItem:GetAmount())
    local header = GetAmountHeader(pDealItem) ..
        " — " .. Locale.Lookup("LOC_DIPLOMACY_DEAL_HOW_MANY") ..
        " (1-" .. tostring(maxAmount) .. ")"

    local edit
    edit = mgr:CreateUIWidget(
        mgr:GenerateWidgetId("CAIDiplomacyDealAmountEdit"), "Edit", {
            GetLabel = function() return header end,
            GetValue = function()
                return (edit and edit.EditBuffer) or startValue
            end,
            EditBuffer = startValue,
            AlwaysEdit = true,
            HighlightOnEdit = true,
            OnCommit = function(w, text)
                local newAmount = tonumber(text) or 0
                newAmount = ClipAmount(newAmount, maxAmount)
                if Controls.ValueAmountEditBox then
                    Controls.ValueAmountEditBox:SetText(tostring(newAmount))
                end
                OnValueEditButton(dealItemID)
                CloseEditWidget()
            end,
        })
    edit:AddInputBindings({
        {
            Key = Keys.VK_ESCAPE,
            MSG = KeyEvents.KeyDown,
            Action = function()
                CloseEditWidget(); return true
            end,
        },
    })

    m_state.editWidget = edit
    mgr:Push(edit)
end

local function GetAgreementHeaderText(agreementType)
    if agreementType == DealAgreementTypes.RESEARCH_AGREEMENT then
        return Locale.Lookup("LOC_DIPLOMACY_DEAL_SELECT_TECH")
    elseif agreementType == DealAgreementTypes.ALLIANCE then
        return Locale.Lookup("LOC_DIPLOMACY_DEAL_SELECT_ALLIANCE")
    end
    return Locale.Lookup("LOC_DIPLOMACY_DEAL_SELECT_TARGET")
end

local function FormatAgreementOptionLabel(entry, agreementType)
    local itemName = entry.ForTypeDisplayName
        and Locale.Lookup(entry.ForTypeDisplayName) or ""

    if entry.SubType == DealAgreementTypes.RESEARCH_AGREEMENT
        or agreementType == DealAgreementTypes.RESEARCH_AGREEMENT then
        local techDef = GameInfo.Technologies[entry.ForType]
        if techDef and m_players.local_ and m_players.other then
            local turns = m_players.local_:GetDiplomacy()
                :ComputeResearchAgreementTurns(m_players.other, techDef.Index)
            return Locale.Lookup("LOC_DIPLOMACY_DEAL_PARAMETER_WITH_TURNS",
                itemName, turns)
        end
        return itemName
    end

    if entry.SubType == DealAgreementTypes.JOINT_WAR
        or entry.SubType == DealAgreementTypes.THIRD_PARTY_WAR then
        if entry.Parameters and entry.Parameters.WarType then
            local warDef = GameInfo.Wars[entry.Parameters.WarType]
            if warDef then
                return itemName .. " - " .. Locale.Lookup(warDef.Name)
            end
        end
    end

    return itemName
end

local function GetAgreementOptionTooltip(entry, agreementType)
    if agreementType ~= DealAgreementTypes.ALLIANCE then return "" end
    if not m_players.local_ or not m_players.other then return "" end
    local allianceData = GameInfo.Alliances[entry.ForTypeName]
    if not allianceData then return "" end
    local level = m_players.local_:GetDiplomacy():GetAllianceLevel(m_players.other)
    return Game.GetGameDiplomacy():GetAllianceBenefitsString(
        allianceData.Index, level, true) or ""
end

local function PushAgreementSelector(pDealItem)
    CloseEditWidget()

    local fromPlayerID = pDealItem:GetFromPlayerID()
    local agreementType = pDealItem:GetSubType()
    local agreementTurns = pDealItem:GetDuration()
    local toPlayerID = (m_players.local_ and m_players.local_:GetID() == fromPlayerID)
        and m_players.other:GetID() or m_players.local_:GetID()

    local pForDeal = GetWorkingDeal()
    local entries = DealManager.GetPossibleDealItems(
        fromPlayerID, toPlayerID, DealItemTypes.AGREEMENTS, agreementType, pForDeal)
    if not entries or #entries == 0 then return end

    local headerText = GetAgreementHeaderText(agreementType)

    local list = mgr:CreateUIWidget(
        mgr:GenerateWidgetId("CAIDiplomacyDealAgreementList"), "List", {
            GetLabel = function() return headerText end,
        })

    for _, entry in ipairs(entries) do
        local rowEntry = entry
        local label = FormatAgreementOptionLabel(rowEntry, agreementType)
        local tooltip = GetAgreementOptionTooltip(rowEntry, agreementType)
        list:AddChild(mgr:CreateUIWidget(
            mgr:GenerateWidgetId("CAIDiplomacyDealAgreementOption"), "Button", {
                GetLabel = function() return label end,
                GetTooltip = function() return tooltip end,
                OnFocusEnter = PlayHover,
                OnClick = function()
                    OnSelectAgreementOption(agreementType, agreementTurns,
                        rowEntry.ForType, rowEntry.Parameters, fromPlayerID)
                    CloseEditWidget()
                    return true
                end,
            }))
    end

    list:AddInputBindings({
        {
            Key = Keys.VK_ESCAPE,
            MSG = KeyEvents.KeyDown,
            Action = function()
                CloseEditWidget(); return true
            end,
        },
    })

    m_state.editWidget = list
    mgr:Push(list)
end

local function DispatchOfferEdit(dealItemID)
    if IsDemandFromOther() then return end
    local pDeal = GetWorkingDeal()
    if not pDeal then return end
    local pItem = pDeal:FindItemByID(dealItemID)
    if not pItem or pItem:IsLocked() then return end

    if pItem:HasPossibleAmounts() then
        PushAmountEditor(pItem)
    elseif pItem:HasPossibleValues() then
        PushAgreementSelector(pItem)
    end
end

-- ============================================================================
-- Offers tree
-- ============================================================================

local function BuildCityChildItem(pChildDealItem)
    local childType = pChildDealItem:GetType()
    local label
    if childType == DealItemTypes.RESOURCES then
        local desc = GameInfo.Resources[pChildDealItem:GetValueType()]
        local resName = desc and Locale.Lookup(desc.Name) or ""
        label = resName .. " x" .. tostring(pChildDealItem:GetAmount())
    else
        local typeName = pChildDealItem:GetValueTypeNameID()
        label = typeName and Locale.Lookup(typeName) or ""
    end

    return mgr:CreateUIWidget(
        mgr:GenerateWidgetId("CAIDiplomacyDealCityChild"), "TreeviewItem", {
            GetLabel = function() return label end,
        })
end

local function CreateOfferItem(pDealItem)
    local sidePlayer = GetActivePlayer()
    local otherPlayer = GetSideOtherPlayer(m_state.activeSide)
    local dealItemID = pDealItem:GetID()
    local itemType = pDealItem:GetType()
    local label = GetDealItemLabel(pDealItem)
    local isCity = (itemType == DealItemTypes.CITIES)

    local item = mgr:CreateUIWidget(
        mgr:GenerateWidgetId("CAIDiplomacyDealOfferItem"), "TreeviewItem", {
            GetLabel = function() return label end,
            OnFocusEnter = PlayHover,
            OnClick = function()
                DispatchOfferEdit(dealItemID)
                return true
            end,
        })
    item.CAI_DealItemID = dealItemID
    item.CAI_OnRemove = function()
        if IsDemandFromOther() then return end
        local pDeal = GetWorkingDeal()
        if not pDeal or not sidePlayer then return end
        local pItem = pDeal:FindItemByID(dealItemID)
        if not pItem or pItem:IsLocked() then return end
        if isCity then
            local typeName = pItem:GetValueTypeNameID() or ""
            OnRemoveDealCity(typeName, sidePlayer, dealItemID, nil)
        else
            OnRemoveDealItem(sidePlayer, dealItemID, nil)
        end
    end
    item.CAI_OnStopAsking = function()
        if IsDemandFromOther() then return end
        local pDeal = GetWorkingDeal()
        if not pDeal or not sidePlayer or not otherPlayer then return end
        local pItem = pDeal:FindItemByID(dealItemID)
        if not pItem then return end
        if not otherPlayer:IsHuman()
            and pItem:GetFromPlayerID() == m_players.local_:GetID()
            and not pItem:IsUnacceptable() then
            OnSetDealItemUnacceptable(dealItemID)
        end
    end

    if isCity then
        local pDeal = GetWorkingDeal()
        if pDeal then
            for pChild in pDeal:Items() do
                if pDeal:GetItemParent(pChild) == pDealItem then
                    item:AddChild(BuildCityChildItem(pChild))
                end
            end
        end
    end

    return item
end

local function RefreshOffersTree()
    if not m_ui.offersTree then return end
    local prevIndex = m_ui.offersTree:GetFocusedChildIndex()
    m_ui.offersTree:ClearChildren()

    local pDeal = GetWorkingDeal()
    if pDeal then
        local sidePlayer = GetActivePlayer()
        if sidePlayer then
            local sidePlayerID = sidePlayer:GetID()
            for pDealItem in pDeal:Items() do
                if pDealItem:GetFromPlayerID() == sidePlayerID
                    and pDeal:GetItemParent(pDealItem) == nil then
                    m_ui.offersTree:AddChild(CreateOfferItem(pDealItem))
                end
            end
        end
    end

    if prevIndex then
        m_ui.offersTree:SetFocusedChild(prevIndex)
    end
end

-- ============================================================================
-- Inventory tree
-- ============================================================================

local function CreateCategoryNode(idHint, label)
    return mgr:CreateUIWidget(
        mgr:GenerateWidgetId(idHint), "TreeviewItem", {
            GetLabel = function() return label end,
        })
end

local function CreateInventoryItem(idHint, label, tooltip, isDisabled, onClick)
    return mgr:CreateUIWidget(
        mgr:GenerateWidgetId(idHint), "TreeviewItem", {
            GetLabel = function() return label end,
            GetTooltip = function() return tooltip or "" end,
            IsDisabled = function() return isDisabled and true or false end,
            OnFocusEnter = PlayHover,
            OnClick = function(w)
                if w.IsDisabled and w:IsDisabled() then return true end
                onClick()
                return true
            end,
        })
end

local function PopulateGoldCategory(node, sidePlayer, otherPlayer)
    local pForDeal = GetWorkingDeal()
    local entries = DealManager.GetPossibleDealItems(
        sidePlayer:GetID(), otherPlayer:GetID(), DealItemTypes.GOLD, pForDeal)
    if not entries then return end
    for _, entry in ipairs(entries) do
        if entry.Duration == 0 then
            local goldBalance = math.floor(sidePlayer:GetTreasury():GetGoldBalance())
            local label = Locale.Lookup("LOC_DIPLOMACY_DEAL_ONE_TIME") .. ": "
                .. Locale.Lookup("LOC_YIELD_GOLD_NAME") .. " " .. tostring(goldBalance)
            node:AddChild(CreateInventoryItem("CAIDiplomacyDealInvGold",
                label, "", false,
                function() OnClickAvailableOneTimeGold(sidePlayer, DEFAULT_ONE_TIME_GOLD) end))
        else
            local label = Locale.Lookup("LOC_DIPLOMACY_DEAL_GOLD_PER_TURN")
            node:AddChild(CreateInventoryItem("CAIDiplomacyDealInvGoldTurn",
                label, "", false,
                function()
                    OnClickAvailableMultiTurnGold(sidePlayer,
                        DEFAULT_MULTI_TURN_GOLD, DEFAULT_MULTI_TURN_GOLD_DURATION)
                end))
        end
    end
end

local function PopulateResourceCategory(node, sidePlayer, otherPlayer, className)
    local pForDeal = GetWorkingDeal()
    local entries = DealManager.GetPossibleDealItems(
        sidePlayer:GetID(), otherPlayer:GetID(), DealItemTypes.RESOURCES, pForDeal)
    if not entries then return end
    for _, entry in ipairs(entries) do
        local desc = GameInfo.Resources[entry.ForType]
        if desc and entry.MaxAmount > 0 and desc.ResourceClassType == className then
            local resourceType = entry.ForType
            local label = Locale.Lookup(desc.Name) .. " x" .. tostring(entry.MaxAmount)
            local tooltip = Locale.Lookup(desc.Name)
            node:AddChild(CreateInventoryItem("CAIDiplomacyDealInvResource",
                label, tooltip, not entry.IsValid,
                function() OnClickAvailableResource(sidePlayer, resourceType) end))
        end
    end
end

local function PopulateAgreementsCategory(node, sidePlayer, otherPlayer)
    local pForDeal = GetWorkingDeal()
    local entries = DealManager.GetPossibleDealItems(
        sidePlayer:GetID(), otherPlayer:GetID(), DealItemTypes.AGREEMENTS, pForDeal)
    if not entries then return end
    for _, entry in ipairs(entries) do
        local agreementType = entry.SubType
        local agreementDuration = entry.Duration
        local label = entry.SubTypeName and Locale.Lookup(entry.SubTypeName) or ""
        local tooltip = label
        if entry.Duration > 0 then
            tooltip = Locale.Lookup("LOC_DIPLOMACY_DEAL_PARAMETER_WITH_TURNS",
                entry.SubTypeName, entry.Duration)
        end
        local invalid = (not entry.IsValid)
            and entry.ValidationResult ~= DealValidationResult.MISSING_DEPENDENCY
        node:AddChild(CreateInventoryItem("CAIDiplomacyDealInvAgreement",
            label, tooltip, invalid,
            function() OnClickAvailableAgreement(sidePlayer, agreementType, agreementDuration) end))
    end
end

local function PopulateCitiesCategory(node, sidePlayer, otherPlayer)
    local pForDeal = GetWorkingDeal()
    local entries = DealManager.GetPossibleDealItems(
        sidePlayer:GetID(), otherPlayer:GetID(), DealItemTypes.CITIES, pForDeal)
    if not entries then return end
    for _, entry in ipairs(entries) do
        local cityType = entry.ForType
        local subType = entry.SubType
        local label = entry.ForTypeName and Locale.Lookup(entry.ForTypeName) or ""
        local owner = (entry.SubType == 1) and otherPlayer or sidePlayer
        local tooltip = MakeCityToolTip(owner, cityType)
        local invalid = (not entry.IsValid)
            and entry.ValidationResult ~= DealValidationResult.MISSING_DEPENDENCY
        node:AddChild(CreateInventoryItem("CAIDiplomacyDealInvCity",
            label, tooltip, invalid,
            function() OnClickAvailableCity(sidePlayer, cityType, subType) end))
    end
end

local function PopulateGreatWorksCategory(node, sidePlayer, otherPlayer)
    local pForDeal = GetWorkingDeal()
    local entries = DealManager.GetPossibleDealItems(
        sidePlayer:GetID(), otherPlayer:GetID(), DealItemTypes.GREATWORK, pForDeal)
    if not entries then return end
    for _, entry in ipairs(entries) do
        local desc = GameInfo.GreatWorks[entry.ForTypeDescriptionID]
        if desc then
            local greatWorkType = entry.ForType
            local descID = entry.ForTypeDescriptionID
            local label = entry.ForTypeName and Locale.Lookup(entry.ForTypeName) or ""
            local tooltip = GreatWorksSupport_GetBasicTooltip(entry.ForType, false) or ""
            local invalid = (not entry.IsValid)
                and entry.ValidationResult ~= DealValidationResult.MISSING_DEPENDENCY
            node:AddChild(CreateInventoryItem("CAIDiplomacyDealInvGreatWork",
                label, Locale.Lookup(tooltip), invalid,
                function() OnClickAvailableGreatWork(sidePlayer, greatWorkType, descID) end))
        end
    end
end

local function PopulateCaptivesCategory(node, sidePlayer, otherPlayer)
    local pForDeal = GetWorkingDeal()
    local entries = DealManager.GetPossibleDealItems(
        sidePlayer:GetID(), otherPlayer:GetID(), DealItemTypes.CAPTIVE, pForDeal)
    if not entries then return end
    for _, entry in ipairs(entries) do
        local captiveType = entry.ForType
        local label = entry.ForTypeName and Locale.Lookup(entry.ForTypeName) or ""
        local invalid = (not entry.IsValid)
            and entry.ValidationResult ~= DealValidationResult.MISSING_DEPENDENCY
        node:AddChild(CreateInventoryItem("CAIDiplomacyDealInvCaptive",
            label, label, invalid,
            function() OnClickAvailableCaptive(sidePlayer, captiveType) end))
    end
end

local function RefreshInventoryTree()
    if not m_ui.inventoryTree then return end
    m_ui.inventoryTree:ClearChildren()

    local sidePlayer = GetActivePlayer()
    local otherPlayer = GetSideOtherPlayer(m_state.activeSide)
    if not sidePlayer or not otherPlayer then return end

    local function addCategoryIfNonEmpty(node)
        if node.Children and #node.Children > 0 then
            m_ui.inventoryTree:AddChild(node)
        end
    end

    local goldNode = CreateCategoryNode("CAIDiplomacyDealInvGoldCat",
        Locale.Lookup("LOC_YIELD_GOLD_NAME"))
    PopulateGoldCategory(goldNode, sidePlayer, otherPlayer)
    addCategoryIfNonEmpty(goldNode)

    local luxuryNode = CreateCategoryNode("CAIDiplomacyDealInvLuxuryCat",
        Locale.Lookup("LOC_DIPLOMACY_DEAL_LUXURY_RESOURCES"))
    PopulateResourceCategory(luxuryNode, sidePlayer, otherPlayer, "RESOURCECLASS_LUXURY")
    addCategoryIfNonEmpty(luxuryNode)

    local strategicNode = CreateCategoryNode("CAIDiplomacyDealInvStrategicCat",
        Locale.Lookup("LOC_DIPLOMACY_DEAL_STRATEGIC_RESOURCES"))
    PopulateResourceCategory(strategicNode, sidePlayer, otherPlayer, "RESOURCECLASS_STRATEGIC")
    addCategoryIfNonEmpty(strategicNode)

    local agreementsNode = CreateCategoryNode("CAIDiplomacyDealInvAgreementsCat",
        Locale.Lookup("LOC_DIPLOMACY_DEAL_AGREEMENTS"))
    PopulateAgreementsCategory(agreementsNode, sidePlayer, otherPlayer)
    addCategoryIfNonEmpty(agreementsNode)

    local citiesNode = CreateCategoryNode("CAIDiplomacyDealInvCitiesCat",
        Locale.Lookup("LOC_DIPLOMACY_DEAL_CITIES"))
    PopulateCitiesCategory(citiesNode, sidePlayer, otherPlayer)
    addCategoryIfNonEmpty(citiesNode)

    local greatWorksNode = CreateCategoryNode("CAIDiplomacyDealInvGreatWorksCat",
        Locale.Lookup("LOC_DIPLOMACY_DEAL_GREAT_WORKS"))
    PopulateGreatWorksCategory(greatWorksNode, sidePlayer, otherPlayer)
    addCategoryIfNonEmpty(greatWorksNode)

    local captivesNode = CreateCategoryNode("CAIDiplomacyDealInvCaptivesCat",
        Locale.Lookup("LOC_DIPLOMACY_DEAL_CAPTIVES"))
    PopulateCaptivesCategory(captivesNode, sidePlayer, otherPlayer)
    addCategoryIfNonEmpty(captivesNode)
end

-- ============================================================================
-- Actions list
-- ============================================================================

local function GetLeaderLineText()
    local dialog = ControlText(Controls.LeaderDialog)
    local effect = ControlText(Controls.LeaderEffect)
    return JoinNonEmpty({ dialog, effect }, " ")
end

local function CreateActionButton(idHint, control, vanillaCall)
    return mgr:CreateUIWidget(mgr:GenerateWidgetId(idHint), "Button", {
        GetLabel = function() return ControlText(control) end,
        GetTooltip = function() return ControlTooltip(control) end,
        IsHidden = function() return ControlIsHidden(control) end,
        IsDisabled = function() return ControlIsDisabled(control) end,
        OnFocusEnter = PlayHover,
        OnClick = function()
            vanillaCall()
            return true
        end,
    })
end

local function RebuildActionsList()
    if not m_ui.actionsList then return end
    m_ui.actionsList:ClearChildren()

    m_ui.leaderLine = mgr:CreateUIWidget("CAIDiplomacyDealLeaderLine", "Button", {
        GetLabel = function() return GetLeaderLineText() end,
        IsDisabled = function() return true end,
        OnFocusEnter = PlayHover,
    })
    m_ui.actionsList:AddChild(m_ui.leaderLine)

    m_ui.actionsList:AddChild(CreateActionButton("CAIDiplomacyDealAccept",
        Controls.AcceptDeal, OnProposeOrAcceptDeal))
    m_ui.actionsList:AddChild(CreateActionButton("CAIDiplomacyDealDemand",
        Controls.DemandDeal, OnProposeOrAcceptDeal))
    m_ui.actionsList:AddChild(CreateActionButton("CAIDiplomacyDealEqualize",
        Controls.EqualizeDeal, OnEqualizeDeal))
    m_ui.actionsList:AddChild(CreateActionButton("CAIDiplomacyDealRefuse",
        Controls.RefuseDeal, function() OnRefuseDeal() end))
    m_ui.actionsList:AddChild(CreateActionButton("CAIDiplomacyDealResume",
        Controls.ResumeGame, OnResumeGame))
end

-- ============================================================================
-- Tabs
-- ============================================================================

local function SwitchSide(newSide)
    if m_state.activeSide == newSide then return end
    m_state.activeSide = newSide
    RefreshOffersTree()
    RefreshInventoryTree()
end

local function CreateTab(idHint, label, side)
    return mgr:CreateUIWidget(mgr:GenerateWidgetId(idHint), "Tab", {
        GetLabel = function() return label end,
        OnFocusEnter = function()
            PlayHover()
            SwitchSide(side)
            return true
        end,
        OnClick = function()
            SwitchSide(side)
            return true
        end,
    })
end

-- ============================================================================
-- Build / lifecycle
-- ============================================================================

local function EnsureRootBuilt()
    if m_state.built then return end

    m_ui.root = mgr:CreateUIWidget("CAIDiplomacyDealRoot", "Panel", {
        GetLabel = function()
            if not m_players.other then return "" end
            local config = PlayerConfigurations[m_players.other:GetID()]
            if not config then return "" end
            return Locale.Lookup("LOC_DIPLOMACY_DEAL_PLAYER_PANEL_TITLE",
                config:GetLeaderName(), config:GetCivilizationDescription())
        end,
    })

    m_ui.tabBar = mgr:CreateUIWidget("CAIDiplomacyDealTabBar", "TabBar", {})
    m_ui.tabMe = CreateTab("CAIDiplomacyDealTabMe",
        Locale.Lookup("LOC_DIPLOMACY_DEAL_MY_OFFER"), SIDE_LOCAL)
    m_ui.tabThem = CreateTab("CAIDiplomacyDealTabThem",
        Locale.Lookup("LOC_DIPLOMACY_DEAL_THEIR_OFFER"), SIDE_OTHER)
    m_ui.tabBar:AddChild(m_ui.tabMe)
    m_ui.tabBar:AddChild(m_ui.tabThem)

    m_ui.offersTree = mgr:CreateUIWidget("CAIDiplomacyDealOffers", "Treeview", {
        GetLabel = function() return Locale.Lookup("LOC_CAI_DIPLOMACYDEAL_OFFERS") end,
        IsHidden = function()
            return m_state.hiddenOfferSide == m_state.activeSide
        end,
    })
    m_ui.offersTree:AddInputBindings({
        {
            Key = Keys.VK_DELETE,
            MSG = KeyEvents.KeyDown,
            Action = function(w)
                local focused = w.Manager:GetFocusedWidget()
                if focused and focused.CAI_OnRemove then
                    focused.CAI_OnRemove()
                    return true
                end
                return false
            end,
        },
        {
            Key = Keys.VK_RETURN,
            MSG = KeyEvents.KeyDown,
            IsControl = true,
            Action = function(w)
                local focused = w.Manager:GetFocusedWidget()
                if focused and focused.CAI_OnStopAsking then
                    focused.CAI_OnStopAsking()
                    return true
                end
                return false
            end,
        },
    })

    m_ui.inventoryTree = mgr:CreateUIWidget("CAIDiplomacyDealInventory", "Treeview", {
        GetLabel = function() return Locale.Lookup("LOC_CAI_DIPLOMACYDEAL_INVENTORY") end,
    })

    m_ui.actionsList = mgr:CreateUIWidget("CAIDiplomacyDealActions", "List", {
        GetLabel = function() return Locale.Lookup("LOC_CAI_DIPLOMACY_ACTIONS") end,
    })

    m_ui.root:AddChild(m_ui.tabBar)
    m_ui.root:AddChild(m_ui.offersTree)
    m_ui.root:AddChild(m_ui.inventoryTree)
    m_ui.root:AddChild(m_ui.actionsList)

    m_state.built = true
end

local function DestroyRoot()
    CloseEditWidget()
    if m_ui.root and mgr then
        if mgr:HasWidget(m_ui.root) then
            mgr:RemoveFromStack(m_ui.root:GetId())
        else
            m_ui.root:Destroy()
        end
    end
    m_ui = {
        root = nil,
        tabBar = nil,
        tabMe = nil,
        tabThem = nil,
        offersTree = nil,
        inventoryTree = nil,
        actionsList = nil,
        leaderLine = nil,
    }
    m_state.built = false
    m_state.activeSide = SIDE_LOCAL
    m_state.isDemand = false
    m_state.initiatedByLocal = false
    m_state.hiddenOfferSide = nil
    m_state.editWidget = nil
    m_players.local_ = nil
    m_players.other = nil
end

local function PushRoot()
    if not mgr or not m_ui.root then return end
    if not mgr:HasWidget(m_ui.root) then
        mgr:Push(m_ui.root)
    end
end

local function SeedActiveSide()
    if m_state.isDemand and m_state.initiatedByLocal then
        m_state.activeSide = SIDE_OTHER
    else
        m_state.activeSide = SIDE_LOCAL
    end
    if m_ui.tabBar then
        local idx = (m_state.activeSide == SIDE_OTHER) and 2 or 1
        m_ui.tabBar:SetFocusedChild(idx)
    end
end

local function RefreshAll()
    EnsureRootBuilt()
    CaptureSessionInfo()
    SeedActiveSide()
    RefreshOffersTree()
    RefreshInventoryTree()
    RebuildActionsList()
end

-- ============================================================================
-- Vanilla wraps
-- ============================================================================

PopulatePlayerAvailablePanel = WrapFunc(PopulatePlayerAvailablePanel,
    function(orig, rootControl, player)
        local result = orig(rootControl, player)
        if player then
            if player:GetID() == Game.GetLocalPlayer() then
                m_players.local_ = player
            else
                m_players.other = player
            end
        end
        if m_state.built then RefreshInventoryTree() end
        return result
    end)

PopulatePlayerDealPanel = WrapFunc(PopulatePlayerDealPanel,
    function(orig, rootControl, player)
        orig(rootControl, player)
        if m_state.built then RefreshOffersTree() end
    end)

UpdateDealStatus = WrapFunc(UpdateDealStatus, function(orig, ...)
    orig(...)
    if m_state.built then RebuildActionsList() end
end)

OnShow = WrapFunc(OnShow, function(orig)
    orig()
    if Game.GetLocalPlayer() == -1 then return end
    if not m_players.local_ then
        m_players.local_ = Players[Game.GetLocalPlayer()]
    end
    RefreshAll()
    PushRoot()
end)
ContextPtr:SetShowHandler(OnShow)

OnHide = WrapFunc(OnHide, function(orig)
    DestroyRoot()
    orig()
end)
ContextPtr:SetHideHandler(OnHide)

OnShutdown = WrapFunc(OnShutdown, function(orig)
    DestroyRoot()
    orig()
end)
ContextPtr:SetShutdown(OnShutdown)

InputHandler = WrapFunc(InputHandler, function(orig, input)
    local handled = mgr and mgr:HandleInput(input) or false
    if handled then return true end
    return orig(input)
end)
ContextPtr:SetInputHandler(InputHandler, true)
