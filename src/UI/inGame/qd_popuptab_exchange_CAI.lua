-- qd_popuptab_exchange_CAI.lua
--
-- Accessibility data provider for the Quick Deals Exchange tab (swap one-time gold
-- for 30-turn gold, or vice versa, with each AI at their accepted ratio). CAI wins
-- this context, includes the Quick Deals base, wraps its populate functions, and
-- publishes a live model + action closures into ExposedMembers.CAIQuickDeals.exchange.
--
-- The table columns read the AI's offered gold (one-time or 30-turn) plus the
-- ratio; the "items" text says what you give. The editable amount and the
-- increase/decrease actions drive Quick Deals' own OnUpdateMultiTurnGold with the
-- per-row player/ratio flags, matching the base tab's arrows and value editor.

include("caiUtils")
include("qd_utils")
include("qd_popuptab_exchange")

ExposedMembers.CAIQuickDeals = ExposedMembers.CAIQuickDeals or {}
local QD = ExposedMembers.CAIQuickDeals
QD.exchange = QD.exchange or { offers = {} }

local m_capturing = false

-- CAI-owned gold-type selection, for the same reason as the Purchase tab: the base
-- keeps m_GoldType as a local we can't reach, and its post-accept path reads that
-- stale default (always One-time). We remember the live choice and refetch with it.
local m_currentIsMTG = false

-- ===========================================================================
--  Filter model (which gold you give)
-- ===========================================================================
local function DoFetch(isPlayerMTG)
    m_currentIsMTG = isPlayerMTG
    local pid = Game.GetLocalPlayer()
    if pid == -1 then return end
    local aiPlayers = GetAIPlayersToCheck(Players[pid])
    ResetAIOfferPanel()
    UpdateFetchStatus(true, false)
    LuaEvents.QD_StartAIGoldExchange(pid, aiPlayers, isPlayerMTG)
end

local function BuildFilters()
    local options = {}
    for _, o in ipairs(GOLD_TYPE_OPTIONS) do
        table.insert(options, { label = o[1], value = o[2] })
    end
    local filter = {
        id = "goldtype",
        label = "LOC_CAI_QD_FILTER_GOLD_TYPE",
        options = options,
        currentValue = GOLD_TYPE.ONE_TIME,
        set = function(value) DoFetch(value ~= GOLD_TYPE.ONE_TIME) end,
    }
    return { filter }
end

-- ===========================================================================
--  AI offer records
-- ===========================================================================
local function BuildRecord(offer, control)
    local leader = Locale.Lookup(PlayerConfigurations[offer.PlayerId]:GetLeaderName())
    local aiItem = offer.OfferedItems[1]
    if aiItem == nil then
        return { playerId = offer.PlayerId, leader = leader,
            goldBalance = math.floor(Players[offer.PlayerId]:GetTreasury():GetGoldBalance()),
            oneTime = offer.OneTimeGold, multiTurn = offer.MultiTurnGold }
    end
    local playerGivesMTG = (aiItem.Duration == 0)
    local ratio
    if aiItem.Duration == 0 then
        ratio = (offer.MultiTurnGold ~= 0) and (aiItem.Amount / offer.MultiTurnGold) or 0
    else
        ratio = (aiItem.Amount ~= 0) and (offer.OneTimeGold / aiItem.Amount) or 0
    end
    local editableAmount = playerGivesMTG and offer.MultiTurnGold or aiItem.Amount

    local pid = Game.GetLocalPlayer()
    local deal = DealManager.GetWorkingDeal(DealDirection.OUTGOING, pid, offer.PlayerId)
    local mtgPlayer = (aiItem.Duration > 0) and offer.PlayerId or pid
    local maxAmount = editableAmount
    if deal then
        local details = GetPlayerGoldInDeal(deal, mtgPlayer)
        if details and details.MaxMultiTurnGold and details.MaxMultiTurnGold > 0 then
            maxAmount = details.MaxMultiTurnGold
        end
    end

    local youGive = playerGivesMTG
        and Locale.Lookup("LOC_CAI_QD_YOU_GIVE_MTG", editableAmount)
        or Locale.Lookup("LOC_CAI_QD_YOU_GIVE_OTG", editableAmount)

    local record = {
        playerId = offer.PlayerId, leader = leader,
        goldBalance = math.floor(Players[offer.PlayerId]:GetTreasury():GetGoldBalance()),
        oneTime = (aiItem.Duration == 0) and aiItem.Amount or 0,
        multiTurn = (aiItem.Duration > 0) and aiItem.Amount or 0,
        perUnit = ratio, total = offer.Total,
        itemsText = youGive,
        amount = editableAmount, maxAmount = maxAmount,
        accept = function() OnAcceptDeal(offer.PlayerId) end,
        editAmount = function(newAmount)
            local delta = newAmount - editableAmount
            if delta ~= 0 then
                OnUpdateMultiTurnGold(offer.PlayerId, delta, control, playerGivesMTG, ratio)
            end
        end,
    }
    if editableAmount < maxAmount then
        record.incMTG = function()
            OnUpdateMultiTurnGold(offer.PlayerId, 1, control, playerGivesMTG, ratio)
        end
    end
    if editableAmount > 1 then
        record.decMTG = function()
            OnUpdateMultiTurnGold(offer.PlayerId, -1, control, playerGivesMTG, ratio)
        end
    end
    return record
end

-- ===========================================================================
--  Wraps
-- ===========================================================================
PopulateAIOfferPanel = WrapFunc(PopulateAIOfferPanel, function(orig)
    QD.exchange.offers = {}
    m_capturing = true
    orig()
    m_capturing = false
    LuaEvents.CAIQD_Changed("exchange", "offers")
end)

PopulateAIOffer = WrapFunc(PopulateAIOffer, function(orig, offer, offerControl)
    orig(offer, offerControl)
    local record = BuildRecord(offer, offerControl)
    if m_capturing then
        table.insert(QD.exchange.offers, record)
    else
        for i, r in ipairs(QD.exchange.offers) do
            if r.playerId == offer.PlayerId then QD.exchange.offers[i] = record; break end
        end
        LuaEvents.CAIQD_Changed("exchange", "offerrow")
    end
end)

UpdateFetchStatus = WrapFunc(UpdateFetchStatus, function(orig, isFetching, hasOffers)
    orig(isFetching, hasOffers)
    QD.exchange.fetching = isFetching
    QD.exchange.hasOffers = hasOffers
    LuaEvents.CAIQD_Changed("exchange", "fetch")
end)

-- Replace the base accept-completion handler so the refetch honors the CAI gold
-- type (the base's UpdateAIOffersAfterAccept / UpdateAIDeals read its stale
-- m_GoldType). See the matching note in the Purchase provider.
LuaEvents.QD_EndAIOfferAccept.Remove(OnEndAIOfferAccept)
LuaEvents.QD_EndAIOfferAccept.Add(function()
    if ContextPtr:IsHidden() then return end
    UI.PlaySound("Confirm_Bed_Positive")
    DoFetch(m_currentIsMTG)
end)

-- Announce the offer count only on a genuine fetch completion. Exchange completes
-- through QD_EndAIGoldExchange, not QD_EndAIOfferFetch.
LuaEvents.QD_EndAIGoldExchange.Add(function()
    if ContextPtr:IsHidden() then return end
    LuaEvents.CAIQD_Changed("exchange", "fetchresult")
end)

-- Re-entering the tab makes the base OnShowTab refetch its default (One-time gold).
-- If the CAI dropdown still holds Multi-turn, re-issue the fetch for it so the list
-- matches the dropdown (only when it differs; the pending-job queue supersedes).
LuaEvents.QD_PopupShowTab.Add(function(tabType)
    if tabType == TAB_TYPE.EXCHANGE and m_currentIsMTG then
        DoFetch(m_currentIsMTG)
    end
end)

QD.exchange.filters = BuildFilters()
