-- qd_popuptab_sale_CAI.lua
--
-- Accessibility data provider for the Quick Deals Sale tab. CAI wins this context
-- and includes the Quick Deals base, then wraps its populate functions to publish
-- a live model (inventory groups, staged offer, AI offers) plus action closures
-- into ExposedMembers.CAIQuickDeals.sale. The shell (qd_dealpopup_CAI) renders it.
-- Every closure here runs in this context, so it drives Quick Deals' own state.

include("caiUtils")
include("qd_utils")           -- GOLD_RATIO, g_IsXP2Active, HasExtraResource, etc.
include("qd_popuptab_sale")   -- base tab (also pulls qd_dealmanager)

local BULK_ADD = 10

ExposedMembers.CAIQuickDeals = ExposedMembers.CAIQuickDeals or {}
local QD = ExposedMembers.CAIQuickDeals
QD.sale = QD.sale or { offers = {} }

local m_capturing = false

local function LocalPlayer()
    return Players[Game.GetLocalPlayer()]
end

-- ===========================================================================
--  Inventory model (mirrors PopulateAvailable*; data only)
-- ===========================================================================
local function ItemLabel(name, amount)
    if amount and amount ~= "" then
        return Locale.Lookup("LOC_CAI_QD_INVENTORY_ITEM", name, amount)
    end
    return name
end

local function AddResourceActions(item, resourceIndex, addMax, bulk)
    local player = LocalPlayer()
    item.addOne = function()
        if AddResourceToOffer(player, resourceIndex, addMax, 1) then
            UI.PlaySound("UI_GreatWorks_Put_Down")
            UpdateDealPanel()
        end
    end
    if bulk then
        item.addTen = function()
            if AddResourceToOffer(player, resourceIndex, addMax, BULK_ADD) then
                UI.PlaySound("UI_GreatWorks_Put_Down")
                UpdateDealPanel()
            end
        end
    end
end

local function BuildLuxuryGroups()
    local extra = { title = Locale.Lookup("LOC_DIPLOMACY_DEAL_LUXURY_RESOURCES")
        .. " (" .. Locale.Lookup("LOC_GAMESUMMARY_CATEGORY_EXTRA") .. ")", items = {} }
    local normal = { title = Locale.Lookup("LOC_DIPLOMACY_DEAL_LUXURY_RESOURCES"), items = {} }
    local pid = LocalPlayer():GetID()
    local possible = GetPossibleResources(pid, "RESOURCECLASS_LUXURY")
    for resourceIndex, entry in pairs(possible) do
        local resourceDesc = GameInfo.Resources[entry.ForType]
        if resourceDesc then
            local name = Locale.Lookup(resourceDesc.Name)
            local addMax = entry.MaxAmount
            if HasExtraResource(pid, resourceIndex, entry.MaxAmount) then
                local extraAmount = entry.MaxAmount > 1 and (entry.MaxAmount - 1) or 1
                local item = { key = "lux-extra-" .. resourceIndex,
                    label = ItemLabel(name, extraAmount), tooltip = name }
                AddResourceActions(item, resourceIndex, addMax, false)
                table.insert(extra.items, item)
                if entry.MaxAmount > 1 then
                    local single = { key = "lux-" .. resourceIndex, label = name, tooltip = name }
                    AddResourceActions(single, resourceIndex, addMax, false)
                    table.insert(normal.items, single)
                end
            elseif entry.MaxAmount > 0 then
                local item = { key = "lux-" .. resourceIndex,
                    label = ItemLabel(name, entry.MaxAmount), tooltip = name }
                AddResourceActions(item, resourceIndex, addMax, false)
                table.insert(normal.items, item)
            end
        end
    end
    return extra, normal
end

local function BuildStrategicGroup()
    local group = { title = Locale.Lookup("LOC_DIPLOMACY_DEAL_STRATEGIC_RESOURCES"), items = {} }
    local pid = LocalPlayer():GetID()
    local possible = GetPossibleResources(pid, "RESOURCECLASS_STRATEGIC")
    for resourceIndex, entry in pairs(possible) do
        if entry.MaxAmount > 0 then
            local resourceDesc = GameInfo.Resources[entry.ForType]
            local name = Locale.Lookup(resourceDesc.Name)
            local item = { key = "str-" .. resourceIndex,
                label = ItemLabel(name, entry.MaxAmount), tooltip = name }
            AddResourceActions(item, resourceIndex, entry.MaxAmount, true)
            table.insert(group.items, item)
        end
    end
    return group
end

local function BuildFavorGroup()
    local group = { title = Locale.Lookup("LOC_DIPLOMATIC_FAVOR_NAME"), items = {} }
    if not g_IsXP2Active then return group end
    local player = LocalPlayer()
    local favor = player:GetFavor()
    if favor > 0 then
        local name = Locale.Lookup("LOC_DIPLOMATIC_FAVOR_NAME")
        local item = { key = "favor", label = ItemLabel(name, favor), tooltip = name }
        item.addOne = function()
            if AddFavorToOffer(player, favor, 1) then
                UI.PlaySound("UI_GreatWorks_Put_Down"); UpdateDealPanel()
            end
        end
        item.addTen = function()
            if AddFavorToOffer(player, favor, BULK_ADD) then
                UI.PlaySound("UI_GreatWorks_Put_Down"); UpdateDealPanel()
            end
        end
        table.insert(group.items, item)
    end
    return group
end

local function BuildAgreementGroup()
    local group = { title = Locale.Lookup("LOC_DIPLOMACY_DEAL_AGREEMENTS"), items = {} }
    local player = LocalPlayer()
    if CanPlayerOpenBorder(player:GetID()) then
        local actionName = GetDiploActionName(DealAgreementTypes.OPEN_BORDERS)
        if actionName and GameInfo.DiplomaticActions[actionName] then
            local name = Locale.Lookup(GameInfo.DiplomaticActions[actionName].Name)
            local item = { key = "agr-openborders", label = name, tooltip = name }
            item.addOne = function()
                if AddAgreementToOffer(player, DealAgreementTypes.OPEN_BORDERS) then
                    UI.PlaySound("UI_GreatWorks_Put_Down"); UpdateDealPanel()
                end
            end
            table.insert(group.items, item)
        end
    end
    return group
end

local function BuildGreatWorkGroup()
    local group = { title = Locale.Lookup("LOC_DIPLOMACY_DEAL_GREAT_WORKS"), items = {} }
    local player = LocalPlayer()
    local possible = GetPossibleGreatWorks(player:GetID())
    for id, entry in pairs(possible) do
        local gwDesc = GameInfo.GreatWorks[entry.ForTypeDescriptionID]
        if gwDesc then
            local name = Locale.Lookup(gwDesc.Name)
            local descId = entry.ForTypeDescriptionID
            local item = { key = "gw-" .. id, label = name, tooltip = name }
            item.addOne = function()
                if AddGreatWorkToOffer(player, id, descId) then
                    UI.PlaySound("UI_GreatWorks_Put_Down"); UpdateDealPanel()
                end
            end
            table.insert(group.items, item)
        end
    end
    return group
end

local function BuildInventory()
    local groups = {}
    local extra, normal = BuildLuxuryGroups()
    table.insert(groups, extra)
    table.insert(groups, normal)
    table.insert(groups, BuildStrategicGroup())
    if g_IsXP2Active then table.insert(groups, BuildFavorGroup()) end
    table.insert(groups, BuildAgreementGroup())
    table.insert(groups, BuildGreatWorkGroup())
    return groups
end

-- ===========================================================================
--  Staged-offer model (your items in the offer)
-- ===========================================================================
local function OfferedItemName(item)
    if item.Type == DealItemTypes.RESOURCES then
        return Locale.Lookup(GameInfo.Resources[item.Id].Name)
    elseif item.Type == DealItemTypes.FAVOR then
        return Locale.Lookup("LOC_DIPLOMATIC_FAVOR_NAME")
    elseif item.Type == DealItemTypes.GREATWORK then
        return Locale.Lookup(GameInfo.GreatWorks[item.DescId].Name)
    elseif item.Type == DealItemTypes.AGREEMENTS then
        local actionName = GetDiploActionName(item.Id)
        if actionName and GameInfo.DiplomaticActions[actionName] then
            return Locale.Lookup(GameInfo.DiplomaticActions[actionName].Name)
        end
    end
    return Locale.Lookup("LOC_CAI_QD_ITEMS_NONE")
end

local function BuildStaged()
    local entries = {}
    local player = LocalPlayer()
    local offered = GetOfferedItems()
    for dealType, items in pairs(offered) do
        for id, item in pairs(items) do
            local capturedItem = item
            local name = OfferedItemName(item)
            local editable = (item.Type == DealItemTypes.RESOURCES
                or item.Type == DealItemTypes.FAVOR)
            local label = name
            if editable then label = Locale.Lookup("LOC_CAI_QD_OFFER_ITEM", name, item.Amount) end
            local entry = {
                key = tostring(dealType) .. "-" .. tostring(id),
                label = label, tooltip = name,
                amount = item.Amount, maxAmount = item.MaxAmount, editable = editable,
                remove = function() OnRemoveDealItem(id, dealType) end,
            }
            if editable then
                entry.edit = function(newAmount)
                    local delta = newAmount - capturedItem.Amount
                    if delta ~= 0 then
                        if capturedItem.Type == DealItemTypes.RESOURCES then
                            AddResourceToOffer(player, capturedItem.Id, capturedItem.MaxAmount, delta)
                        elseif capturedItem.Type == DealItemTypes.FAVOR then
                            AddFavorToOffer(player, capturedItem.MaxAmount, delta)
                        end
                        UpdateDealPanel()
                    end
                end
            end
            table.insert(entries, entry)
        end
    end
    return entries
end

-- ===========================================================================
--  AI offer records
-- ===========================================================================
local function OfferItemsText(offer)
    local parts = {}
    for _, item in ipairs(offer.OfferedItems) do
        local name = OfferedItemName(item)
        if item.Type == DealItemTypes.GREATWORK or item.Type == DealItemTypes.AGREEMENTS then
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
        goldBalance = math.floor(Players[offer.PlayerId]:GetTreasury():GetGoldBalance()),
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
--  Item-type filter (recommended-offer preview)
--
--  Before you stage any item, Quick Deals previews *recommended* offers and lets
--  you switch which item type is previewed (vanilla's ItemTypeFilter). That state
--  lives in base-file locals CAI can't reach, so CAI owns its own selection and
--  drives the same recommended fetch directly. It only applies with an empty
--  offer; once items are staged the offer list reflects them and this is a no-op.
-- ===========================================================================
local m_recType, m_recSub = ITEM_TYPE.LUXURY_RESOURCES, nil

local function FetchRecommended(itemType, subType)
    m_recType, m_recSub = itemType, subType
    local pid = Game.GetLocalPlayer()
    if pid == -1 then return end
    if GetOfferedItemCount() > 0 then
        -- Items already staged: recommendations don't apply, keep live offers.
        UpdateDealPanel()
        return
    end
    ResetAIOfferPanel()
    local recommended = GetRecommendedItems(pid, itemType, subType)
    local hasRecommended = false
    for _, items in pairs(recommended) do
        if table.count(items) > 0 then hasRecommended = true; break end
    end
    if hasRecommended then
        UpdateFetchStatus(true, false)
        LuaEvents.QD_StartAIOfferFetch(pid, GetAIPlayersToCheck(Players[pid]), recommended)
    else
        UpdateFetchStatus(false, false)
    end
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
        id = "recitemtype",
        label = "LOC_CAI_QD_FILTER_RECOMMENDED_TYPE",
        options = options,
        currentValue = options[1].value,
        set = function(value) FetchRecommended(value.type, value.sub) end,
    }
    return { filter }
end

QD.sale.filters = BuildFilters()

-- ===========================================================================
--  Wraps
-- ===========================================================================
PopulatePlayerAvailablePanel = WrapFunc(PopulatePlayerAvailablePanel, function(orig)
    orig()
    QD.sale.inventory = BuildInventory()
    LuaEvents.CAIQD_Changed("sale", "inventory")
end)

PopulatePlayerDealPanel = WrapFunc(PopulatePlayerDealPanel, function(orig)
    orig()
    QD.sale.offer = BuildStaged()
    LuaEvents.CAIQD_Changed("sale", "offer")
end)

PopulateAIOfferPanel = WrapFunc(PopulateAIOfferPanel, function(orig)
    QD.sale.offers = {}
    m_capturing = true
    orig()
    m_capturing = false
    LuaEvents.CAIQD_Changed("sale", "offers")
end)

PopulateAIOffer = WrapFunc(PopulateAIOffer, function(orig, offer, offerControl)
    orig(offer, offerControl)
    local record = BuildRecord(offer, offerControl)
    if m_capturing then
        table.insert(QD.sale.offers, record)
    else
        for i, r in ipairs(QD.sale.offers) do
            if r.playerId == offer.PlayerId then QD.sale.offers[i] = record; break end
        end
        LuaEvents.CAIQD_Changed("sale", "offerrow")
    end
end)

UpdateFetchStatus = WrapFunc(UpdateFetchStatus, function(orig, isFetching, hasOffers)
    orig(isFetching, hasOffers)
    QD.sale.fetching = isFetching
    QD.sale.hasOffers = hasOffers
    LuaEvents.CAIQD_Changed("sale", "fetch")
end)

-- When the offer empties, the base re-previews recommendations using its own
-- (Luxury) item-type local, which CAI can't read. Reset the CAI preview selection
-- to the default so the dropdown matches what's shown instead of desyncing.
UpdateProposedWorkingDeal = WrapFunc(UpdateProposedWorkingDeal, function(orig, hasItems)
    orig(hasItems)
    if not hasItems then
        m_recType, m_recSub = ITEM_TYPE.LUXURY_RESOURCES, nil
        local f = QD.sale.filters and QD.sale.filters[1]
        if f then f.currentValue = f.options[1].value end
        LuaEvents.CAIQD_Changed("sale", "resetfilter")
    end
end)

-- Announce the offer count only on a genuine fetch completion. QD_EndAIOfferFetch
-- fires once per completed fetch (staged-item or recommended), never on the interim
-- panel resets, so this avoids speaking placeholder "checking"/"no offers" states.
LuaEvents.QD_EndAIOfferFetch.Add(function()
    if ContextPtr:IsHidden() then return end
    LuaEvents.CAIQD_Changed("sale", "fetchresult")
end)
