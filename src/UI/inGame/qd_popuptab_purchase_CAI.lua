-- qd_popuptab_purchase_CAI.lua
--
-- Accessibility data provider for the Quick Deals Purchase tab (each AI's asking
-- price to sell you a chosen item type). CAI wins this context, includes the
-- Quick Deals base, wraps its populate functions, and publishes a live model +
-- action closures into ExposedMembers.CAIQuickDeals.purchase for the shell.
--
-- CAI owns the filter state instead of Quick Deals' base-file locals: the item
-- type (and strategic/great-work subtype) is chosen through one dropdown here,
-- and the fetch is driven with the same public LuaEvents.QD_StartAIOfferFetch the
-- base uses, so the async offer pipeline returns through the normal path.

include("caiUtils")
include("qd_utils")
include("qd_popuptab_purchase")

ExposedMembers.CAIQuickDeals = ExposedMembers.CAIQuickDeals or {}
local QD = ExposedMembers.CAIQuickDeals
QD.purchase = QD.purchase or { offers = {} }

local m_capturing = false

-- CAI-owned filter selection. The base tab keeps its own m_ItemType/m_SubType
-- locals we can't reach, and its post-accept refetch (OnEndAIOfferAccept ->
-- UpdateAIDeals) reads those stale defaults (always Luxury), which would leave the
-- list showing Luxury while our dropdown still reads the chosen type. We remember
-- the live selection here and refetch with it after an accept (see below).
local m_currentType, m_currentSub = ITEM_TYPE.LUXURY_RESOURCES, nil

-- ===========================================================================
--  Filter model (one dropdown: type, with strategic/great-work subtypes inline)
-- ===========================================================================
local function DoFetch(itemType, subType)
    m_currentType, m_currentSub = itemType, subType
    local pid = Game.GetLocalPlayer()
    if pid == -1 then return end
    local aiPlayers = GetAIPlayersToCheck(Players[pid])
    ResetAIOfferPanel()
    UpdateFetchStatus(true, false)
    LuaEvents.QD_StartAIOfferFetch(pid, aiPlayers, {}, itemType, subType)
end

local function BuildFilters()
    local options = {}
    table.insert(options, { label = "LOC_REPORTS_LUXURY_RESOURCES",
        value = { type = ITEM_TYPE.LUXURY_RESOURCES } })
    for _, o in ipairs(STRATEGIC_RESOURCES_OPTIONS) do
        table.insert(options, { label = o[1], value = { type = ITEM_TYPE.STRATEGIC_RESOURCES, sub = o[2] } })
    end
    for _, o in ipairs(GREAT_WORK_OPTIONS) do
        table.insert(options, { label = o[1], value = { type = ITEM_TYPE.GREAT_WORKS, sub = o[2] } })
    end
    if g_IsXP2Active and ITEM_TYPE.FAVOR then
        table.insert(options, { label = "LOC_DIPLOMATIC_FAVOR_NAME", value = { type = ITEM_TYPE.FAVOR } })
    end
    local filter = {
        id = "itemtype",
        label = "LOC_CAI_QD_FILTER_ITEM_TYPE",
        options = options,
        currentValue = options[1].value,
        set = function(value) DoFetch(value.type, value.sub) end,
    }
    return { filter }
end

-- ===========================================================================
--  AI offer records
-- ===========================================================================
local function OfferedItemName(item)
    if item.Type == DealItemTypes.RESOURCES then
        return Locale.Lookup(GameInfo.Resources[item.Id].Name)
    elseif item.Type == DealItemTypes.FAVOR then
        return Locale.Lookup("LOC_DIPLOMATIC_FAVOR_NAME")
    elseif item.Type == DealItemTypes.GREATWORK then
        return Locale.Lookup(GameInfo.GreatWorks[item.DescId].Name)
    end
    return Locale.Lookup("LOC_CAI_QD_ITEMS_NONE")
end

local function OfferItemsText(offer)
    local parts = {}
    for _, item in ipairs(offer.OfferedItems) do
        local name = OfferedItemName(item)
        if item.Type == DealItemTypes.GREATWORK then
            table.insert(parts, name)
        else
            table.insert(parts, Locale.Lookup("LOC_CAI_QD_OFFER_ITEM", name, item.Amount))
        end
    end
    if offer.Equalized == false then
        table.insert(parts, Locale.Lookup("LOC_QD_ALL_GOLD_HINT"))
    end
    return table.concat(parts, ", ")
end

local function BuildRecord(offer, control)
    local leader = Locale.Lookup(PlayerConfigurations[offer.PlayerId]:GetLeaderName())
    local count = 0
    for _, item in ipairs(offer.OfferedItems) do count = count + (item.Amount or 1) end
    local perUnit = count > 0 and (offer.Total / count) or offer.Total
    local record = {
        playerId = offer.PlayerId, leader = leader,
        oneTime = offer.OneTimeGold, multiTurn = offer.MultiTurnGold,
        perUnit = perUnit, total = offer.Total,
        itemCount = #offer.OfferedItems,
        itemsText = OfferItemsText(offer),
    }
    if offer.HasNonGoldItem then
        record.viewDeal = function() OnShowDealDetails(offer.PlayerId) end
    else
        record.accept = function() OnAcceptDeal(offer.PlayerId) end
    end
    if offer.OneTimeGold > 0 then
        record.incMTG = function() OnUpdateMultiTurnGold(offer.PlayerId, 1, control) end
        record.convertAll = function()
            OnUpdateMultiTurnGold(offer.PlayerId, math.floor(offer.OneTimeGold / GOLD_RATIO), control)
        end
    end
    if offer.MultiTurnGold > 0 then
        record.decMTG = function() OnUpdateMultiTurnGold(offer.PlayerId, -1, control) end
    end
    return record
end

-- ===========================================================================
--  Wraps
-- ===========================================================================
PopulateAIOfferPanel = WrapFunc(PopulateAIOfferPanel, function(orig)
    QD.purchase.offers = {}
    m_capturing = true
    orig()
    m_capturing = false
    LuaEvents.CAIQD_Changed("purchase", "offers")
end)

PopulateAIOffer = WrapFunc(PopulateAIOffer, function(orig, offer, offerControl)
    orig(offer, offerControl)
    local record = BuildRecord(offer, offerControl)
    if m_capturing then
        table.insert(QD.purchase.offers, record)
    else
        for i, r in ipairs(QD.purchase.offers) do
            if r.playerId == offer.PlayerId then QD.purchase.offers[i] = record; break end
        end
        LuaEvents.CAIQD_Changed("purchase", "offerrow")
    end
end)

UpdateFetchStatus = WrapFunc(UpdateFetchStatus, function(orig, isFetching, hasOffers)
    orig(isFetching, hasOffers)
    QD.purchase.fetching = isFetching
    QD.purchase.hasOffers = hasOffers
    LuaEvents.CAIQD_Changed("purchase", "fetch")
end)

-- Replace the base accept-completion handler so the refetch honors the CAI filter
-- selection instead of the base's stale Luxury default. The base registered its
-- own OnEndAIOfferAccept as a LuaEvents callback (capturing the original function
-- reference), so wrapping the global would not affect it; we drop that listener
-- and install our own. Guard on the tab being visible so it only acts when active.
LuaEvents.QD_EndAIOfferAccept.Remove(OnEndAIOfferAccept)
LuaEvents.QD_EndAIOfferAccept.Add(function()
    if ContextPtr:IsHidden() then return end
    UI.PlaySound("Confirm_Bed_Positive")
    DoFetch(m_currentType, m_currentSub)
end)

-- Announce the offer count only on a genuine fetch completion (not the interim
-- resets that also run UpdateFetchStatus).
LuaEvents.QD_EndAIOfferFetch.Add(function()
    if ContextPtr:IsHidden() then return end
    LuaEvents.CAIQD_Changed("purchase", "fetchresult")
end)

-- Re-entering the tab makes the base OnShowTab refetch its default (Luxury). If the
-- CAI dropdown still holds a different selection, re-issue the fetch for it so the
-- list matches the dropdown. Only when it actually differs, to avoid a double fetch
-- (the automator's pending-job queue lets the later request supersede the base one).
LuaEvents.QD_PopupShowTab.Add(function(tabType)
    if tabType == TAB_TYPE.PURCHASE and m_currentType ~= ITEM_TYPE.LUXURY_RESOURCES then
        DoFetch(m_currentType, m_currentSub)
    end
end)

-- Publish the filter model once (options are static per game).
QD.purchase.filters = BuildFilters()
