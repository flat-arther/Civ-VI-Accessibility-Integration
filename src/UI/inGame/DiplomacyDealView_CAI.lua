-- DiplomacyDealView_CAI.lua
--
-- Accessibility layer for the diplomacy deal/demand screen.
--
-- DiplomacyDealView.lua ends with include("DiplomacyDealView_", true) -- a
-- wildcard host that pulls in every loaded DiplomacyDealView_* file, with
-- Initialize() called *after* it. So this file rides that wildcard (registered
-- as an InGame ImportFile, NOT a LuaReplace), must NOT include("DiplomacyDealView"),
-- and only reassigns globals -- vanilla's later Initialize() registers them as
-- the context handlers. This preserves every vanilla/DLC DiplomacyDealView_*
-- override (e.g. KublaiKhan_Vietnam _MODE).

include("caiUtils")

local mgr = ExposedMembers.CAI_UIManager

local SIDE_LOCAL = "local"
local SIDE_OTHER = "other"

-- Vanilla constants that are file-local in DiplomacyDealView.lua and therefore
-- unreachable from this wrapper.
local DEFAULT_ONE_TIME_GOLD = 100
local DEFAULT_MULTI_TURN_GOLD = 10
local DEFAULT_MULTI_TURN_GOLD_DURATION = 30
-- Diplomatic Favor (Gathering Storm only) is always a lump sum; vanilla's
-- ms_DefaultOneTimeFavorAmount is a file-local in the XP2 rider, so mirror it here.
local DEFAULT_ONE_TIME_FAVOR = 1

local ROOT_ID = "CAIDiplomacyDealRoot"
local TABS_ID = "CAIDiplomacyDealTabs"

local m_ui = {
    root = nil,
    tabs = nil,
    -- sides[SIDE_LOCAL] = { page=, offers=, inventory=, actions= }
    sides = {},
}

local m_state = {
    built = false,
    isDemand = false,
    initiatedByLocal = false,
    hiddenOfferSide = nil,
    editWidget = nil,
    -- Deferred announcement queue. Vanilla updates the deal across several
    -- rapid passes (optimistic pre-propose, then the AI's settled response), so
    -- we coalesce all leader-line and offer add/remove changes and flush once on
    -- the next quiet frame -- speaking the value vanilla finally settled on.
    pendingLeaderText = nil,
    lastSpokenLeaderText = "",
    addedQueue = {},          -- [side] = { label, ... }
    removedQueue = {},        -- [side] = { label, ... }
    changedQueue = {},        -- [side] = { label, ... }
    offerSnapshot = {},       -- [side] = { [dealItemID] = label }
    flushArmed = false,
    flushDirty = false,
    -- Suppresses offer-diff announcements during the initial build so the deal's
    -- pre-existing items (e.g. an incoming demand) aren't read out as "added".
    dealReady = false,
}

local m_players = {
    local_ = nil,
    other = nil,
}

-- ============================================================================
-- Control helpers
-- ============================================================================

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

local function IsFocusInside(widget)
    if not widget or not mgr then return false end
    local node = mgr:GetFocusedWidget()
    while node do
        if node == widget then return true end
        node = node.Parent
    end
    return false
end

-- ============================================================================
-- Deferred announcement queue
--
-- Vanilla mutates the working deal in bursts (an optimistic pass when items
-- change, then the AI's settled response a frame or two later). Announcing on
-- every pass is noisy and contradictory, so leader-line text and offer
-- add/remove changes are queued and flushed once the dust settles: the flush
-- runs on the first frame in which no further change arrived, so it always
-- speaks the value vanilla settled on.
-- ============================================================================

local SIDE_ADD_LOC = {
    [SIDE_LOCAL] = "LOC_CAI_DIPLOMACYDEAL_ADDED_YOUR_SIDE",
    [SIDE_OTHER] = "LOC_CAI_DIPLOMACYDEAL_ADDED_THEIR_SIDE",
}
local SIDE_REMOVE_LOC = {
    [SIDE_LOCAL] = "LOC_CAI_DIPLOMACYDEAL_REMOVED_YOUR_SIDE",
    [SIDE_OTHER] = "LOC_CAI_DIPLOMACYDEAL_REMOVED_THEIR_SIDE",
}
local SIDE_CHANGED_LOC = {
    [SIDE_LOCAL] = "LOC_CAI_DIPLOMACYDEAL_CHANGED_YOUR_SIDE",
    [SIDE_OTHER] = "LOC_CAI_DIPLOMACYDEAL_CHANGED_THEIR_SIDE",
}

local function BuildSideLine(locTag, labels)
    if not labels or #labels == 0 then return nil end
    return Locale.Lookup(locTag) .. ": " .. table.concat(labels, ", ")
end

-- Side text: the per-side add/remove offer changes. Spoken as its own
-- announcement, queued (never interrupts), so it always lands before the
-- leader's reaction.
local function FlushSideText()
    local lines = {}
    for _, side in ipairs({ SIDE_LOCAL, SIDE_OTHER }) do
        local remLine = BuildSideLine(SIDE_REMOVE_LOC[side], m_state.removedQueue[side])
        if remLine then table.insert(lines, remLine) end
        local addLine = BuildSideLine(SIDE_ADD_LOC[side], m_state.addedQueue[side])
        if addLine then table.insert(lines, addLine) end
        local changeLine = BuildSideLine(SIDE_CHANGED_LOC[side], m_state.changedQueue[side])
        if changeLine then table.insert(lines, changeLine) end
        m_state.addedQueue[side] = {}
        m_state.removedQueue[side] = {}
        m_state.changedQueue[side] = {}
    end

    if #lines > 0 then SpeakLines(lines, false) end
end

-- Leader response: the leader's deal feedback (LeaderDialog + LeaderEffect),
-- spoken separately from the side text and deduped against what was last spoken
-- so an unchanged status (e.g. a tab switch) doesn't repeat. Queued, so it
-- follows the side text without interrupting it.
local function FlushLeaderResponse()
    local text = m_state.pendingLeaderText
    m_state.pendingLeaderText = nil
    if text and text ~= "" and text ~= m_state.lastSpokenLeaderText then
        m_state.lastSpokenLeaderText = text
        SpeakLines({ text }, false)
    end
end

-- Flush side text first, then the leader response. The two are handled by
-- separate functions and emitted as separate, queued announcements: nothing
-- interrupts, and the user hears the deal changes followed by the leader's
-- reaction.
local function FlushAnnouncements()
    FlushSideText()
    FlushLeaderResponse()
end

-- Fires every frame while armed. We wait for one quiet frame (no new change
-- since the last tick) before flushing, which coalesces the multi-frame
-- optimistic->settled burst.
local function OnFlushUpdate()
    if m_state.flushDirty then
        m_state.flushDirty = false
        return
    end
    ContextPtr:ClearUpdate()
    m_state.flushArmed = false
    FlushAnnouncements()
end

local function ArmFlush()
    m_state.flushDirty = true
    if not m_state.flushArmed then
        m_state.flushArmed = true
        ContextPtr:SetUpdate(OnFlushUpdate)
    end
end

local function QueueLeaderText(text)
    m_state.pendingLeaderText = text
    ArmFlush()
end

local function QueueOfferAdd(side, label)
    m_state.addedQueue[side] = m_state.addedQueue[side] or {}
    table.insert(m_state.addedQueue[side], label)
    ArmFlush()
end

local function QueueOfferRemove(side, label)
    m_state.removedQueue[side] = m_state.removedQueue[side] or {}
    table.insert(m_state.removedQueue[side], label)
    ArmFlush()
end

local function QueueOfferChange(side, oldLabel, newLabel)
    m_state.changedQueue[side] = m_state.changedQueue[side] or {}
    table.insert(m_state.changedQueue[side],
        Locale.Lookup("LOC_CAI_DIPLOMACYDEAL_CHANGED_ITEM", oldLabel, newLabel))
    ArmFlush()
end

local function CancelFlush()
    if m_state.flushArmed then
        ContextPtr:ClearUpdate()
        m_state.flushArmed = false
    end
    m_state.flushDirty = false
    m_state.pendingLeaderText = nil
    m_state.addedQueue = {}
    m_state.removedQueue = {}
    m_state.changedQueue = {}
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

local function SideForPlayer(player)
    if not player then return nil end
    if player:GetID() == Game.GetLocalPlayer() then return SIDE_LOCAL end
    return SIDE_OTHER
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
    elseif DealItemTypes.FAVOR and itemType == DealItemTypes.FAVOR then
        -- Favor is a bare amount like gold (no value-type name), so the generic
        -- else branch below would read it as blank. Name + amount, always lump-sum.
        label = Locale.Lookup("LOC_DIPLOMATIC_FAVOR_NAME") .. " " .. tostring(amount)
    else
        local typeName = pDealItem:GetValueTypeNameID()
        label = typeName and Locale.Lookup(typeName) or ""
    end

    if pDealItem:IsUnacceptable() then
        label = label .. " (" .. Locale.Lookup("LOC_DIPLO_DEAL_UNACCEPTABLE_ITEM_TOOLTIP") .. ")"
    end
    return label
end

local function SuppressDuplicateTooltip(label, tooltip)
    if not tooltip or tooltip == "" then return "" end
    if tooltip == label then return "" end
    if label and label ~= "" and string.sub(label, 1, #tooltip) == tooltip then
        local nextChar = string.sub(label, #tooltip + 1, #tooltip + 1)
        if nextChar == " " or nextChar == "x" then
            return ""
        end
    end
    return tooltip
end

-- ============================================================================
-- Offer-edit widgets (pushed directly to the stack, no wrapping Dialog)
-- ============================================================================

local function CloseEditWidget()
    if not m_state.editWidget then return end
    if mgr and mgr:GetWidgetById(m_state.editWidget:GetId()) then
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
    elseif DealItemTypes.FAVOR and itemType == DealItemTypes.FAVOR then
        return Locale.Lookup("LOC_DIPLOMATIC_FAVOR_NAME")
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

    -- Host the EditBox in a thin wrapper so Escape has somewhere to bubble: the
    -- EditBox's own Escape binding returns false for AlwaysEdit boxes and
    -- OnHandleInput stops at that first match, so a sibling/own Esc binding never
    -- runs. With a parent, mgr:HandleInput bubbles the unconsumed Esc up to the
    -- wrapper, which closes the editor instead of Esc reaching the deal view.
    local wrapper = mgr:CreateWidget(
        mgr:GenerateWidgetId("CAIDiplomacyDealAmountEditHost"), "Panel", {
            Transparent = true,
        })
    wrapper:AddInputBindings({
        {
            Key    = Keys.VK_ESCAPE,
            MSG    = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_CLOSE",
            Action = function() CloseEditWidget(); return true end,
        },
    })

    local edit = mgr:CreateWidget(
        mgr:GenerateWidgetId("CAIDiplomacyDealAmountEdit"), "EditBox", {
            Label           = function() return header end,
            AlwaysEdit      = true,
            HighlightOnEdit = true,
        })
    edit:SetText(startValue, true)
    edit:On("value_changed", function(_, text)
        local newAmount = ClipAmount(tonumber(text) or 0, maxAmount)
        if Controls.ValueAmountEditBox then
            Controls.ValueAmountEditBox:SetText(tostring(newAmount))
        end
        OnValueEditButton(dealItemID)
        CloseEditWidget()
    end)
    wrapper:AddChild(edit)

    m_state.editWidget = wrapper
    mgr:Push(wrapper)
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

-- Agreements whose value must be chosen (joint-war target + war type, third-party
-- war, research-agreement tech). Vanilla resolves these through its inaccessible
-- ShowAgreementOptionPopup *before* the item is added, so the CAI must push its own
-- option list at click time. Other agreements (open borders, defensive pact, …) and
-- ALLIANCE add directly and, where they carry a value, expose it via the offer-item
-- edit path. Mirrors the branch in vanilla OnClickAvailableAgreement.
local function AgreementNeedsOptionList(agreementType)
    return agreementType == DealAgreementTypes.JOINT_WAR
        or agreementType == DealAgreementTypes.THIRD_PARTY_WAR
        or agreementType == DealAgreementTypes.RESEARCH_AGREEMENT
end

-- Build and push the accessible option list for a parameterized agreement. Shared
-- by the offer-item edit path (PushAgreementSelector, item already in the deal) and
-- the inventory click for the AgreementNeedsOptionList types (no item yet). On
-- selection, OnSelectAgreementOption adds/updates the deal item with the choice.
local function PushAgreementOptionList(agreementType, agreementTurns, fromPlayerID)
    CloseEditWidget()

    local toPlayerID = (m_players.local_ and m_players.local_:GetID() == fromPlayerID)
        and m_players.other:GetID() or m_players.local_:GetID()

    local pForDeal = GetWorkingDeal()
    local entries = DealManager.GetPossibleDealItems(
        fromPlayerID, toPlayerID, DealItemTypes.AGREEMENTS, agreementType, pForDeal)
    if not entries or #entries == 0 then return end

    local headerText = GetAgreementHeaderText(agreementType)

    -- The List is the parent of the option buttons, so an unconsumed Escape on a
    -- button bubbles to the List's Esc binding and closes the selector.
    local list = mgr:CreateWidget(
        mgr:GenerateWidgetId("CAIDiplomacyDealAgreementList"), "List", {
            Label = function() return headerText end,
        })

    for _, entry in ipairs(entries) do
        local rowEntry = entry
        local label = FormatAgreementOptionLabel(rowEntry, agreementType)
        local tooltip = GetAgreementOptionTooltip(rowEntry, agreementType)
        local option = mgr:CreateWidget(
            mgr:GenerateWidgetId("CAIDiplomacyDealAgreementOption"), "Button", {
                Label   = function() return label end,
                Tooltip = function() return tooltip end,
            })
        option:SetFocusSound("Main_Menu_Mouse_Over")
        option:On("activate", function()
            OnSelectAgreementOption(agreementType, agreementTurns,
                rowEntry.ForType, rowEntry.Parameters, fromPlayerID)
            CloseEditWidget()
        end)
        list:AddChild(option)
    end

    list:AddInputBindings({
        {
            Key    = Keys.VK_ESCAPE,
            MSG    = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_CLOSE",
            Action = function() CloseEditWidget(); return true end,
        },
    })

    m_state.editWidget = list
    mgr:Push(list)
end

local function PushAgreementSelector(pDealItem)
    PushAgreementOptionList(pDealItem:GetSubType(), pDealItem:GetDuration(),
        pDealItem:GetFromPlayerID())
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
-- Offers tree (per side)
-- ============================================================================

local function BuildCityChildItem(pChildDealItem)
    local childType = pChildDealItem:GetType()
    local label
    local tooltip = ""
    if childType == DealItemTypes.RESOURCES then
        local desc = GameInfo.Resources[pChildDealItem:GetValueType()]
        local resName = desc and Locale.Lookup(desc.Name) or ""
        label = resName .. " x" .. tostring(pChildDealItem:GetAmount())
        tooltip = resName
    elseif childType == DealItemTypes.GREATWORK then
        local typeName = pChildDealItem:GetValueTypeNameID()
        label = typeName and Locale.Lookup(typeName) or ""
        tooltip = Locale.Lookup(GreatWorksSupport_GetBasicTooltip(
            pChildDealItem:GetValueType(), false))
    else
        local typeName = pChildDealItem:GetValueTypeNameID()
        label = typeName and Locale.Lookup(typeName) or ""
    end

    return mgr:CreateWidget(
        mgr:GenerateWidgetId("CAIDiplomacyDealCityChild"), "TreeItem", {
            Label = function() return label end,
            Tooltip = function() return tooltip end,
        })
end

-- "Stop asking" (mark item unacceptable) is available, mirroring vanilla's
-- StopAskingButton show-condition, only when: the other player initiated the
-- session, the item is one they're asking from us, the opponent is AI, and the
-- item isn't already flagged unacceptable. Vanilla gates on
-- ms_InitiatedByPlayerID ~= localPlayer -- i.e. not initiated by us -- so we use
-- m_state.initiatedByLocal, NOT IsDemandFromOther.
local function CanStopAsking(dealItemID)
    if m_state.initiatedByLocal then return false end
    local pDeal = GetWorkingDeal()
    if not pDeal or not m_players.local_ or not m_players.other then return false end
    local pItem = pDeal:FindItemByID(dealItemID)
    if not pItem then return false end
    return not m_players.other:IsHuman()
        and pItem:GetFromPlayerID() == m_players.local_:GetID()
        and not pItem:IsUnacceptable()
end

local function GetOfferItemBaseTooltip(sidePlayer, pDealItem)
    local pDeal = GetWorkingDeal()
    if not pDeal then return "" end

    local itemType = pDealItem:GetType()
    if itemType == DealItemTypes.RESOURCES then
        local desc = GameInfo.Resources[pDealItem:GetValueType()]
        local tooltip = desc and Locale.Lookup(desc.Name) or ""
        local parentDealItem = pDeal:GetItemParent(pDealItem)
        if parentDealItem then
            tooltip = tooltip .. GetParentItemTransferToolTip(parentDealItem)
        end
        return tooltip
    end

    if itemType == DealItemTypes.AGREEMENTS then
        local info = GameInfo.DiplomaticActions[pDealItem:GetSubType()]
        if info and info.DiplomaticActionType == "DIPLOACTION_JOINT_WAR"
            and m_players.other
            and pDealItem:GetFromPlayerID() == m_players.other:GetID() then
            return Locale.Lookup("LOC_JOINT_WAR_CANNOT_EDIT_THEIRS_TOOLTIP")
        end
        return ""
    end

    if itemType == DealItemTypes.GREATWORK then
        local greatWorkDesc = GameInfo.GreatWorks[pDealItem:GetSubType()]
        local tooltip = ""
        local typeName = pDealItem:GetValueTypeNameID()
        if typeName then
            tooltip = Locale.Lookup(GreatWorksSupport_GetBasicTooltip(
                pDealItem:GetValueType(), false))
        end
        local parentDealItem = pDeal:GetItemParent(pDealItem)
        if parentDealItem then
            tooltip = tooltip .. GetParentItemTransferToolTip(parentDealItem)
        end
        if greatWorkDesc then
            return GetGreatWorkTooltip(greatWorkDesc, tooltip) or ""
        end
        return tooltip
    end

    if itemType == DealItemTypes.CITIES then
        return sidePlayer and MakeCityToolTip(sidePlayer, pDealItem:GetValueType()) or ""
    end

    if itemType == DealItemTypes.CAPTIVE then
        return ""
    end

    return ""
end

local function CreateOfferItem(side, pDealItem)
    local sidePlayer = GetSidePlayer(side)
    local dealItemID = pDealItem:GetID()
    local itemType = pDealItem:GetType()
    local label = GetDealItemLabel(pDealItem)
    local isCity = (itemType == DealItemTypes.CITIES)
    local offerTooltip = GetOfferItemBaseTooltip(sidePlayer, pDealItem)

    local item = mgr:CreateWidget(
        mgr:GenerateWidgetId("CAIDiplomacyDealOfferItem"), "TreeItem", {
            Label    = function() return label end,
            -- Surface that this item can be flagged "stop asking", but only while
            -- that's actually available, so the hint tracks live state. The key
            -- itself is intentionally left out of the text.
            Tooltip  = function()
                local parts = {}
                if offerTooltip ~= "" then
                    table.insert(parts, offerTooltip)
                end
                if CanStopAsking(dealItemID) then
                    table.insert(parts, Locale.Lookup("LOC_DIPLO_DEAL_MARK_UNACCEPTABLE"))
                end
                return table.concat(parts, "[NEWLINE]")
            end,
            FocusKey = "diplo:offer:" .. side .. ":" .. tostring(dealItemID),
        })
    item:SetFocusSound("Main_Menu_Mouse_Over")
    item:On("activate", function() DispatchOfferEdit(dealItemID) end)

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
        if CanStopAsking(dealItemID) then
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

local function RefreshOffersTree(side)
    local sideUI = m_ui.sides[side]
    if not sideUI or not sideUI.offers then return end
    local tree = sideUI.offers

    local capture = mgr:CaptureFocusKey(tree)
    tree:ClearChildren()

    local newSnap = {}
    local pDeal = GetWorkingDeal()
    if pDeal then
        local sidePlayer = GetSidePlayer(side)
        if sidePlayer then
            local sidePlayerID = sidePlayer:GetID()
            for pDealItem in pDeal:Items() do
                if pDealItem:GetFromPlayerID() == sidePlayerID
                    and pDeal:GetItemParent(pDealItem) == nil then
                    tree:AddChild(CreateOfferItem(side, pDealItem))
                    newSnap[pDealItem:GetID()] = GetDealItemLabel(pDealItem)
                end
            end
        end
    end

    mgr:RestoreFocus(tree, capture)

    -- Diff against the previous snapshot so user- and AI-driven adds/removes are
    -- announced. Suppressed until the deal has finished its initial build so
    -- pre-existing items aren't reported.
    local oldSnap = m_state.offerSnapshot[side] or {}
    if m_state.dealReady then
        for id, label in pairs(oldSnap) do
            if newSnap[id] == nil then QueueOfferRemove(side, label) end
        end
        for id, newLabel in pairs(newSnap) do
            local oldLabel = oldSnap[id]
            if oldLabel ~= nil and oldLabel ~= newLabel then
                QueueOfferChange(side, oldLabel, newLabel)
            elseif oldLabel == nil then
                QueueOfferAdd(side, newLabel)
            end
        end
    end
    m_state.offerSnapshot[side] = newSnap
end

-- ============================================================================
-- Inventory tree (per side)
-- ============================================================================

local function CreateCategoryNode(idHint, label)
    return mgr:CreateWidget(
        mgr:GenerateWidgetId(idHint), "TreeItem", {
            Label = function() return label end,
        })
end

local function CreateInventoryItem(idHint, label, tooltip, isDisabled, onClick)
    -- A side whose offer is read-only (your side on a demand you make, or either
    -- side on an incoming demand) keeps its inventory readable but non-actionable.
    -- Folding it into the disabled state means the activate guard below (and
    -- Button:Activate's own disabled no-op) handles it with no extra wiring.
    local readOnly = m_state.inventoryReadOnly
    local item = mgr:CreateWidget(
        mgr:GenerateWidgetId(idHint), "TreeItem", {
            Label             = function() return label end,
            Tooltip           = function() return tooltip or "" end,
            DisabledPredicate = function() return readOnly or (isDisabled and true) or false end,
        })
    item:SetFocusSound("Main_Menu_Mouse_Over")
    item:On("activate", function(w)
        if w:IsDisabled() then return end
        onClick()
    end)
    return item
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

-- Diplomatic Favor (Gathering Storm only). Mirrors the XP2 rider's
-- PopulateAvailableFavor: shown only off non-demand deals (favor is not
-- demandable) when the side has favor to give; activates the same global
-- OnClickAvailableOneTimeFavor that vanilla wires, so the lump-sum add behaves
-- identically. Guarded by DealItemTypes.FAVOR so base/XP1 rulesets add nothing.
local function PopulateFavorCategory(node, sidePlayer, otherPlayer)
    if not DealItemTypes.FAVOR then return end
    if m_state.isDemand then return end
    if sidePlayer:GetFavor() <= 0 then return end
    local pForDeal = GetWorkingDeal()
    local entries = DealManager.GetPossibleDealItems(
        sidePlayer:GetID(), otherPlayer:GetID(), DealItemTypes.FAVOR, pForDeal)
    if not entries then return end
    for _ in ipairs(entries) do
        local label = Locale.Lookup("LOC_DIPLOMATIC_FAVOR_NAME")
            .. " " .. tostring(sidePlayer:GetFavor())
        node:AddChild(CreateInventoryItem("CAIDiplomacyDealInvFavor",
            label, "", false,
            function() OnClickAvailableOneTimeFavor(sidePlayer, DEFAULT_ONE_TIME_FAVOR) end))
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
            local tooltip
            local invalid = not entry.IsValid
                and entry.ValidationResult ~= DealValidationResult.MISSING_DEPENDENCY
            if invalid then
                local noCapKey = (sidePlayer ~= m_players.local_)
                    and "LOC_DEAL_PLAYER_HAS_NO_CAP_ROOM"
                    or "LOC_DEAL_AI_HAS_NO_CAP_ROOM"
                tooltip = Locale.Lookup(desc.Name) .. "[NEWLINE][COLOR_RED]"
                    .. Locale.Lookup(noCapKey)
            else
                tooltip = SuppressDuplicateTooltip(label, Locale.Lookup(desc.Name))
            end
            node:AddChild(CreateInventoryItem("CAIDiplomacyDealInvResource",
                label, tooltip, invalid,
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
        local tooltip = ""
        if entry.Duration > 0 then
            tooltip = Locale.Lookup("LOC_DIPLOMACY_DEAL_PARAMETER_WITH_TURNS",
                entry.SubTypeName, entry.Duration)
        end
        local invalid = (not entry.IsValid)
            and entry.ValidationResult ~= DealValidationResult.MISSING_DEPENDENCY
        node:AddChild(CreateInventoryItem("CAIDiplomacyDealInvAgreement",
            label, tooltip, invalid,
            function()
                if AgreementNeedsOptionList(agreementType) then
                    PushAgreementOptionList(agreementType, agreementDuration, sidePlayer:GetID())
                else
                    OnClickAvailableAgreement(sidePlayer, agreementType, agreementDuration)
                end
            end))
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
            local tooltip = GetGreatWorkTooltip(desc,
                GreatWorksSupport_GetBasicTooltip(entry.ForType, false)) or ""
            local invalid = (not entry.IsValid)
                and entry.ValidationResult ~= DealValidationResult.MISSING_DEPENDENCY
            node:AddChild(CreateInventoryItem("CAIDiplomacyDealInvGreatWork",
                label, tooltip, invalid,
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
            label, "", invalid,
            function() OnClickAvailableCaptive(sidePlayer, captiveType) end))
    end
end

local function RefreshInventoryTree(side)
    local sideUI = m_ui.sides[side]
    if not sideUI or not sideUI.inventory then return end
    local tree = sideUI.inventory

    local sidePlayer = GetSidePlayer(side)
    local otherPlayer = GetSideOtherPlayer(side)

    local capture = mgr:CaptureFocusKey(tree)
    tree:ClearChildren()
    if not sidePlayer or not otherPlayer then
        mgr:RestoreFocus(tree, capture)
        return
    end

    -- Lock the side that gives nothing: your inventory on a demand you make, and
    -- both sides on an incoming demand (which is accept/refuse only, mirroring
    -- the offer-edit guards). The other player's inventory stays editable on a
    -- demand you make so you can still choose what to demand. CreateInventoryItem
    -- captures this flag at build time; cleared before we return.
    m_state.inventoryReadOnly = IsDemandFromOther() or (m_state.hiddenOfferSide == side)

    local function addCategoryIfNonEmpty(node)
        if node.Children and #node.Children > 0 then
            tree:AddChild(node)
        end
    end

    local goldNode = CreateCategoryNode("CAIDiplomacyDealInvGoldCat",
        Locale.Lookup("LOC_YIELD_GOLD_NAME"))
    PopulateGoldCategory(goldNode, sidePlayer, otherPlayer)
    addCategoryIfNonEmpty(goldNode)

    local favorNode = CreateCategoryNode("CAIDiplomacyDealInvFavorCat",
        Locale.Lookup("LOC_DIPLOMATIC_FAVOR_NAME"))
    PopulateFavorCategory(favorNode, sidePlayer, otherPlayer)
    addCategoryIfNonEmpty(favorNode)

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

    m_state.inventoryReadOnly = false
    mgr:RestoreFocus(tree, capture)
end

local function RefreshSide(side)
    RefreshOffersTree(side)
    RefreshInventoryTree(side)
end

-- ============================================================================
-- Actions list (deal-wide, shared)
-- ============================================================================

local function GetLeaderLineText()
    local dialog = ControlText(Controls.LeaderDialog)
    local effect = ControlText(Controls.LeaderEffect)
    return JoinNonEmpty({ dialog, effect }, " ")
end

local function CreateActionButton(focusKey, idHint, control)
    local btn = mgr:CreateWidget(mgr:GenerateWidgetId(idHint), "Button", {
        Label             = function() return ControlText(control) end,
        Tooltip           = function() return ControlTooltip(control) end,
        HiddenPredicate   = function() return ControlIsHidden(control) end,
        DisabledPredicate = function() return ControlIsDisabled(control) end,
        FocusKey          = focusKey,
    })
    btn:SetFocusSound("Main_Menu_Mouse_Over")
    -- Fire the vanilla button's own registered left-click handler rather than a
    -- captured callback, so we stay in lockstep with whatever vanilla wired.
    btn:On("activate", function() control:DoLeftClick() end)
    return btn
end

-- Populate one side's actions list in place. The first child is the "text"
-- item: a read-only line carrying the leader's current deal feedback
-- (LeaderDialog + LeaderEffect); the rest mirror the deal-wide vanilla buttons.
local function RebuildActionsListForSide(side)
    local sideUI = m_ui.sides[side]
    if not sideUI or not sideUI.actions then return end
    local list = sideUI.actions

    list:ClearChildren()

    list:AddChild(mgr:CreateWidget(
        mgr:GenerateWidgetId("CAIDiplomacyDealLeaderLine"), "Button", {
            Label             = function() return GetLeaderLineText() end,
            DisabledPredicate = function() return true end,
            FocusKey          = "diplo:deal:action:leaderline:" .. side,
        }))

    list:AddChild(CreateActionButton("diplo:deal:action:accept:" .. side,
        "CAIDiplomacyDealAccept", Controls.AcceptDeal))
    list:AddChild(CreateActionButton("diplo:deal:action:demand:" .. side,
        "CAIDiplomacyDealDemand", Controls.DemandDeal))
    list:AddChild(CreateActionButton("diplo:deal:action:equalize:" .. side,
        "CAIDiplomacyDealEqualize", Controls.EqualizeDeal))
    list:AddChild(CreateActionButton("diplo:deal:action:refuse:" .. side,
        "CAIDiplomacyDealRefuse", Controls.RefuseDeal))
    list:AddChild(CreateActionButton("diplo:deal:action:resume:" .. side,
        "CAIDiplomacyDealResume", Controls.ResumeGame))
end

local function RebuildActionsList()
    -- Only the active (mounted) page's list can hold focus, but check both.
    local focusedList = nil
    for _, side in ipairs({ SIDE_LOCAL, SIDE_OTHER }) do
        local sideUI = m_ui.sides[side]
        if sideUI and sideUI.actions and IsFocusInside(sideUI.actions) then
            focusedList = sideUI.actions
        end
    end

    RebuildActionsListForSide(SIDE_LOCAL)
    RebuildActionsListForSide(SIDE_OTHER)

    if focusedList then
        -- Keep the cursor on the text item after the rebuild. The move is silent
        -- because the leader line is spoken by the queued flush (deduped), so a
        -- rapid optimistic->settled burst isn't double-spoken.
        local textItem = focusedList.Children and focusedList.Children[1]
        if textItem then mgr:SetFocus(textItem, { announce = false }) end
    end

    -- Queue the leader feedback; the flush speaks the settled value once.
    QueueLeaderText(GetLeaderLineText())
end

-- ============================================================================
-- Tabs (My offer / Their offer)
-- ============================================================================

local function SwitchSide(newSide)
    RefreshSide(newSide)
end

local function MakeSidePage(side, labelKey)
    local page = m_ui.tabs:AddPage(function() return Locale.Lookup(labelKey) end)

    local offers = mgr:CreateWidget(
        mgr:GenerateWidgetId("CAIDiplomacyDealOffers"), "Tree", {
            Label           = function() return Locale.Lookup("LOC_CAI_DIPLOMACYDEAL_OFFERS") end,
            HiddenPredicate = function() return m_state.hiddenOfferSide == side end,
        })
    offers:AddInputBindings({
        {
            Key    = Keys.VK_DELETE,
            MSG    = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_REMOVE_DEAL_ITEM",
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
            Key     = Keys.VK_DELETE,
            MSG     = KeyEvents.KeyUp,
            IsShift = true,
            Description = "LOC_CAI_KB_STOP_ASKING",
            Action  = function(w)
                local focused = w.Manager:GetFocusedWidget()
                if focused and focused.CAI_OnStopAsking then
                    focused.CAI_OnStopAsking()
                    return true
                end
                return false
            end,
        },
    })

    local inventory = mgr:CreateWidget(
        mgr:GenerateWidgetId("CAIDiplomacyDealInventory"), "Tree", {
            Label = function() return Locale.Lookup("LOC_CAI_DIPLOMACYDEAL_INVENTORY") end,
        })

    -- Deal actions live inside each page (after offers + inventory) so a plain
    -- Tab from the inventory tree lands on them via ordinary in-page navigation.
    -- The actions are deal-wide, so each side's list mirrors the same vanilla
    -- controls; both are rebuilt together by RebuildActionsList.
    local actions = mgr:CreateWidget(
        mgr:GenerateWidgetId("CAIDiplomacyDealActions"), "List", {
            Label = function() return Locale.Lookup("LOC_CAI_DIPLOMACY_ACTIONS") end,
        })

    page:AddChild(offers)
    page:AddChild(inventory)
    page:AddChild(actions)

    m_ui.sides[side] = { page = page, offers = offers, inventory = inventory, actions = actions }
end

-- ============================================================================
-- Build / lifecycle
-- ============================================================================

local function EnsureRootBuilt()
    if m_state.built then return end

    m_ui.root = mgr:CreateWidget(ROOT_ID, "Panel", {
        Label = function()
            if not m_players.other then return "" end
            local config = PlayerConfigurations[m_players.other:GetID()]
            if not config then return "" end
            return Locale.Lookup("LOC_DIPLOMACY_DEAL_PLAYER_PANEL_TITLE",
                config:GetLeaderName(), config:GetCivilizationDescription())
        end,
    })

    m_ui.tabs = mgr:CreateWidget(TABS_ID, "TabControl", {})
    MakeSidePage(SIDE_LOCAL, "LOC_DIPLOMACY_DEAL_MY_OFFER")
    MakeSidePage(SIDE_OTHER, "LOC_DIPLOMACY_DEAL_THEIR_OFFER")
    -- Re-derive the active side's trees whenever the user switches tabs.
    m_ui.tabs:On("value_changed", function(_, idx)
        SwitchSide(idx == 2 and SIDE_OTHER or SIDE_LOCAL)
    end)

    m_ui.root:AddChild(m_ui.tabs)

    m_state.built = true
end

local function ResetState()
    m_ui = { root = nil, tabs = nil, sides = {} }
    m_state.built = false
    m_state.isDemand = false
    m_state.initiatedByLocal = false
    m_state.hiddenOfferSide = nil
    m_state.inventoryReadOnly = false
    m_state.editWidget = nil
    m_state.pendingLeaderText = nil
    m_state.lastSpokenLeaderText = ""
    m_state.addedQueue = {}
    m_state.removedQueue = {}
    m_state.changedQueue = {}
    m_state.offerSnapshot = {}
    m_state.flushArmed = false
    m_state.flushDirty = false
    m_state.dealReady = false
    m_players.local_ = nil
    m_players.other = nil
end

local function DestroyRoot()
    CancelFlush()
    CloseEditWidget()
    if m_ui.root and mgr then
        if mgr:GetWidgetById(ROOT_ID) then
            mgr:RemoveFromStack(ROOT_ID)
        else
            m_ui.root:Destroy()
        end
    end
    ResetState()
end

local function PushRoot()
    if not mgr or not m_ui.root then return end
    if not mgr:GetWidgetById(ROOT_ID) then
        mgr:Push(m_ui.root, PopupPriority.Current)
    end
end

local function SeedActiveSide()
    -- On a demand we initiated, the interesting side is the other player's
    -- (what they must give up); otherwise default to our own offer.
    local idx = (m_state.isDemand and m_state.initiatedByLocal) and 2 or 1
    if m_ui.tabs then m_ui.tabs:SetActivePage(idx, true) end
end

local function RefreshAll()
    EnsureRootBuilt()
    -- Snapshot the deal's starting items without announcing them; offer-diff
    -- reporting turns on only once the initial build is complete.
    m_state.dealReady = false
    m_state.offerSnapshot = {}
    CaptureSessionInfo()
    SeedActiveSide()
    RefreshSide(SIDE_LOCAL)
    RefreshSide(SIDE_OTHER)
    RebuildActionsList()
    m_state.dealReady = true
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
        if m_state.built then
            local side = SideForPlayer(player)
            if side then RefreshInventoryTree(side) end
        end
        return result
    end)

PopulatePlayerDealPanel = WrapFunc(PopulatePlayerDealPanel,
    function(orig, rootControl, player)
        orig(rootControl, player)
        if m_state.built then
            local side = SideForPlayer(player)
            if side then RefreshOffersTree(side) end
        end
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

OnHide = WrapFunc(OnHide, function(orig)
    DestroyRoot()
    orig()
end)

OnShutdown = WrapFunc(OnShutdown, function(orig)
    DestroyRoot()
    orig()
end)

-- Honor the input-handler contract: when the manager consumes the key we must
-- return true so the wrapped vanilla handler doesn't also act on it.
InputHandler = WrapFunc(InputHandler, function(orig, input)
    local handled = mgr and mgr:HandleInput(input) or false
    if handled then return true end
    return orig(input)
end)
