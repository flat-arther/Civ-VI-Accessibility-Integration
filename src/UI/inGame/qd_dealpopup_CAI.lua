-- qd_dealpopup_CAI.lua
--
-- Accessibility shell for the Quick Deals mod (wltk). Quick Deals replaces the
-- vanilla per-AI deal grind with one popup that queries every met AI at once and
-- shows who pays the most for your items. Its UI is entirely custom and has no
-- accessibility, so CAI wins the four Quick Deals contexts (this shell plus the
-- three tab contexts) and rebuilds them on the CAI widget framework.
--
-- Architecture: this shell owns ALL widgets (one context => one input handler,
-- one manager panel, no cross-context widget trees). The three tab contexts
-- (qd_popuptab_sale/purchase/exchange_CAI) are pure providers: each includes its
-- Quick Deals base, wraps that context's populate functions, and publishes a live
-- model plus action closures into ExposedMembers.CAIQuickDeals[tabKey], then fires
-- LuaEvents.CAIQD_Changed(tabKey, kind). The shell renders that model. Action
-- closures are invoked from here but carry their home context, so they mutate the
-- correct Quick Deals state. Reference passing across contexts is exactly what
-- Quick Deals itself relies on (it threads control instances through its own
-- LuaEvents), so the model/closure bridge is safe.

include("caiUtils")
include("qd_utils")     -- TAB_TYPE, GOLD_RATIO, option tables, IsNotificationOptedOut
include("qd_dealpopup") -- base shell: Open/Close/CloseSilently/OnInputHandler + tab bar

local mgr = ExposedMembers.CAI_UIManager

-- ===========================================================================
--  Shared state
-- ===========================================================================
local PANEL_ID  = "CAIQuickDeals_Panel"
local VIEW_SETTING_SECTION = "UI"
local VIEW_SETTING_ID      = "QuickDealsViewMode"

ExposedMembers.CAIQuickDeals = ExposedMembers.CAIQuickDeals or {}
local QD = ExposedMembers.CAIQuickDeals
QD.sale     = QD.sale     or { offers = {} }
QD.purchase = QD.purchase or { offers = {} }
QD.exchange = QD.exchange or { offers = {} }

local TAB_DEFS = {
    { key = "sale",     qd = TAB_TYPE.SALE,     label = "LOC_QD_SALE" },
    { key = "purchase", qd = TAB_TYPE.PURCHASE, label = "LOC_HUD_PURCHASE" },
    { key = "exchange", qd = TAB_TYPE.EXCHANGE, label = "LOC_QD_EXCHANGE" },
}

local m_panel        = nil
local m_tabs         = nil
local m_pages        = {}   -- [tabKey] = { page, table, list, sortDropdown, ... }
local m_activeTab    = "sale"
local m_focusedRow   = {}   -- [tabKey] = offer record last focused
local m_editWidget   = nil
local m_isMirroring   = false

-- ===========================================================================
--  View mode (shared table/list preference, persisted; Reports pattern)
-- ===========================================================================
local function LoadViewMode()
    local stored = tostring(CAI.GetConfigValue(VIEW_SETTING_SECTION, VIEW_SETTING_ID, "table")):lower()
    if stored == "list" then return "list" end
    return "table"
end

local m_viewMode = LoadViewMode()

local function SaveViewMode(mode)
    CAI.SetConfigValue(VIEW_SETTING_SECTION, VIEW_SETTING_ID, mode)
end

-- ===========================================================================
--  Small formatting helpers
-- ===========================================================================
local function Model(tabKey) return QD[tabKey] end

local function GoldText(n)
    return Locale.Lookup("LOC_CAI_QD_GOLD_AMOUNT", n or 0)
end

local function PerUnitText(n)
    if n == nil then return "" end
    return string.format("%.1f", n)
end

local function GetFocused()
    return m_focusedRow[m_activeTab]
end

-- Detail lines for a list row: everything except the leader, one entry per line.
-- The leader is the row label; these go in the tooltip joined by [NEWLINE], so the
-- list reads as "leader" with the numbers on demand. Per-tab wording mirrors the
-- table headers so each figure's meaning (who pays, who gives, the ratio) is clear.
local function OfferDetailLines(r, tabKey)
    local lines = {}
    if r.goldBalance then
        table.insert(lines, Locale.Lookup("LOC_CAI_QD_OFFER_BALANCE", r.goldBalance))
    end
    table.insert(lines, Locale.Lookup("LOC_CAI_QD_OFFER_ONE_TIME", r.oneTime or 0))
    table.insert(lines, Locale.Lookup("LOC_CAI_QD_OFFER_MULTI_TURN", r.multiTurn or 0))
    if tabKey ~= "exchange" and r.total then
        table.insert(lines, Locale.Lookup("LOC_CAI_QD_OFFER_TOTAL", r.total))
    end
    if r.perUnit and r.perUnit > 0 then
        local perKey = (tabKey == "exchange") and "LOC_CAI_QD_OFFER_RATIO"
            or "LOC_CAI_QD_OFFER_PER_UNIT"
        table.insert(lines, Locale.Lookup(perKey, PerUnitText(r.perUnit)))
    end
    if r.itemsText and r.itemsText ~= "" then
        table.insert(lines, r.itemsText)
    end
    return lines
end

-- ===========================================================================
--  Offer table (DataTable) columns
-- ===========================================================================
-- Column meaning differs per tab (Sale = the AI pays you, Purchase = you pay the
-- AI, Exchange = the AI gives one gold form for the other at a ratio), so the
-- headers are tab-specific to keep every number self-describing. Vanilla shows
-- the AI's treasury balance on Sale and Exchange but not Purchase, so the balance
-- column follows the same rule. Exchange has no meaningful combined total.
local function BuildOfferColumns(tabKey)
    local oneTimeHeader, multiHeader, eachHeader, itemsHeader
    if tabKey == "purchase" then
        oneTimeHeader, multiHeader = "LOC_CAI_QD_COL_YOU_PAY_NOW", "LOC_CAI_QD_COL_YOU_PAY_TURNS"
        eachHeader, itemsHeader    = "LOC_CAI_QD_COL_GOLD_EACH", "LOC_CAI_QD_COL_YOU_RECEIVE"
    elseif tabKey == "exchange" then
        oneTimeHeader, multiHeader = "LOC_CAI_QD_COL_AI_GIVES_NOW", "LOC_CAI_QD_COL_AI_GIVES_TURNS"
        eachHeader, itemsHeader    = "LOC_CAI_QD_COL_RATIO", "LOC_CAI_QD_COL_YOU_GIVE"
    else -- sale
        oneTimeHeader, multiHeader = "LOC_CAI_QD_COL_AI_PAYS_NOW", "LOC_CAI_QD_COL_AI_PAYS_TURNS"
        eachHeader, itemsHeader    = "LOC_CAI_QD_COL_GOLD_EACH", "LOC_CAI_QD_COL_YOU_SELL"
    end
    local showBalance = (tabKey == "sale" or tabKey == "exchange")
    local showTotal   = (tabKey ~= "exchange")

    local columns = {}
    table.insert(columns, {
        key = "leader",
        header = function() return Locale.Lookup("LOC_CAI_QD_COL_LEADER") end,
        getCell = function(r) return r.leader end,
        sortKey = function(r) return r.leader end,
        sortAscendingDescription = "LOC_CAI_SORT_A_TO_Z",
        sortDescendingDescription = "LOC_CAI_SORT_Z_TO_A",
    })
    if showBalance then
        table.insert(columns, {
            key = "balance",
            header = function() return Locale.Lookup("LOC_CAI_QD_COL_AI_GOLD") end,
            getCell = function(r) return GoldText(r.goldBalance) end,
            sortKey = function(r) return r.goldBalance or 0 end,
            sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST",
        })
    end
    table.insert(columns, {
        key = "onetime",
        header = function() return Locale.Lookup(oneTimeHeader) end,
        getCell = function(r) return GoldText(r.oneTime) end,
        sortKey = function(r) return r.oneTime or 0 end,
        sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST",
        sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST",
    })
    table.insert(columns, {
        key = "multiturn",
        header = function() return Locale.Lookup(multiHeader) end,
        getCell = function(r) return GoldText(r.multiTurn) end,
        sortKey = function(r) return r.multiTurn or 0 end,
        sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST",
        sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST",
    })
    if showTotal then
        table.insert(columns, {
            key = "total",
            header = function() return Locale.Lookup("LOC_CAI_QD_COL_TOTAL") end,
            getCell = function(r) return GoldText(r.total) end,
            sortKey = function(r) return r.total or 0 end,
            sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST",
        })
    end
    table.insert(columns, {
        key = "perunit",
        header = function() return Locale.Lookup(eachHeader) end,
        getCell = function(r) return PerUnitText(r.perUnit) end,
        sortKey = function(r) return r.perUnit or 0 end,
        sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST",
        sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST",
    })
    local itemsColumn = {
        key = "items",
        header = function() return Locale.Lookup(itemsHeader) end,
        getCell = function(r) return (r.itemsText and r.itemsText ~= "") and r.itemsText
            or Locale.Lookup("LOC_CAI_QD_ITEMS_NONE") end,
    }
    -- Sort by how many items are in the offer. Meaningless on Exchange, where each
    -- offer is a single gold item, so it stays unsortable there.
    if tabKey ~= "exchange" then
        itemsColumn.sortKey = function(r) return r.itemCount or 0 end
        itemsColumn.sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST"
        itemsColumn.sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST"
    end
    table.insert(columns, itemsColumn)
    return columns
end

-- Sort dropdown options mirror the sortable columns (Reports pattern).
local function BuildSortOptions(tabKey)
    local options = {
        { label = Locale.Lookup("LOC_CAI_DATATABLE_SORT_NATURAL"),
          value = { column = "natural", ascending = true } },
    }
    for _, column in ipairs(BuildOfferColumns(tabKey)) do
        if column.sortKey then
            local header = column.header()
            table.insert(options, {
                label = header .. ", " .. Locale.Lookup(column.sortAscendingDescription),
                value = { column = column.key, ascending = true },
            })
            table.insert(options, {
                label = header .. ", " .. Locale.Lookup(column.sortDescendingDescription),
                value = { column = column.key, ascending = false },
            })
        end
    end
    return options
end

-- ===========================================================================
--  Inline amount editor (Sale offer edit / Exchange amount edit)
-- ===========================================================================
local function CloseEditWidget()
    if not m_editWidget then return end
    if mgr and mgr:GetWidgetById(m_editWidget:GetId()) then
        mgr:RemoveFromStack(m_editWidget:GetId())
    end
    m_editWidget:Destroy()
    m_editWidget = nil
end

local function PushAmountEditor(headerText, startValue, maxAmount, commit)
    CloseEditWidget()
    local wrapper = mgr:CreateWidget(mgr:GenerateWidgetId("CAIQD_AmountEditHost"), "Panel", {
        Transparent = true,
    })
    wrapper:AddInputBindings({
        {
            Key = Keys.VK_ESCAPE, MSG = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_CLOSE",
            Action = function() CloseEditWidget(); return true end,
        },
    })
    local edit = mgr:CreateWidget(mgr:GenerateWidgetId("CAIQD_AmountEdit"), "EditBox", {
        Label = function() return headerText end,
        AlwaysEdit = true,
        HighlightOnEdit = true,
    })
    edit:SetText(tostring(startValue), true)
    edit:On("value_changed", function(_, text)
        local newAmount = tonumber(text) or 0
        newAmount = math.max(1, math.min(newAmount, maxAmount))
        commit(newAmount)
        CloseEditWidget()
    end)
    wrapper:AddChild(edit)
    m_editWidget = wrapper
    mgr:Push(wrapper)
end

-- ===========================================================================
--  Rendering: offer table + list for one tab
-- ===========================================================================
local COLUMN_FIELD = {
    leader = "leader", balance = "goldBalance", onetime = "oneTime",
    multiturn = "multiTurn", total = "total", perunit = "perUnit", items = "itemCount",
}

-- Return offers ordered to match the sort dropdown (the table sorts itself; the
-- list is a separate view so it sorts a copy here).
local function OrderedOffers(model)
    local ordered = {}
    for _, r in ipairs(model.offers) do table.insert(ordered, r) end
    local sort = model.listSort
    if sort and sort.column ~= "natural" then
        local field = COLUMN_FIELD[sort.column]
        if field then
            table.sort(ordered, function(a, b)
                local av, bv = a[field], b[field]
                if type(av) == "string" then
                    local cmp = Locale.Compare(av or "", bv or "")
                    if sort.ascending then return cmp < 0 else return cmp > 0 end
                end
                av, bv = av or 0, bv or 0
                if sort.ascending then return av < bv else return av > bv end
            end)
        end
    end
    return ordered
end

local function RebuildOfferList(tabKey)
    local ui = m_pages[tabKey]
    if not ui or not ui.list then return end
    local capture = mgr:CaptureFocusKey(ui.list)
    ui.list:ClearChildren()
    local model = Model(tabKey)
    for i, r in ipairs(OrderedOffers(model)) do
        local captured = r
        local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAIQD_OfferRow"), "Button", {
            Label = function() return captured.leader end,
            Tooltip = function()
                return table.concat(OfferDetailLines(captured, tabKey), "[NEWLINE]")
            end,
            FocusKey = tabKey .. ":offer:" .. tostring(r.playerId),
        })
        item:On("focus_enter", function(w)
            if w:IsFocused() then m_focusedRow[tabKey] = captured end
        end)
        item:On("activate", function()
            if captured.accept then captured.accept()
            elseif captured.viewDeal then captured.viewDeal() end
        end)
        ui.list:AddChild(item)
    end
    mgr:RestoreFocus(ui.list, capture)
end

local function RebuildOfferTable(tabKey)
    local ui = m_pages[tabKey]
    if not ui or not ui.table then return end
    ui.table:Rebuild()
end

local function RebuildOffers(tabKey)
    RebuildOfferTable(tabKey)
    RebuildOfferList(tabKey)
end

-- ===========================================================================
--  Rendering: Sale inventory tree + offer list
-- ===========================================================================
local function RebuildInventory()
    local ui = m_pages.sale
    if not ui or not ui.inventory then return end
    local capture = mgr:CaptureFocusKey(ui.inventory)
    ui.inventory:ClearChildren()
    local groups = Model("sale").inventory or {}
    local any = false
    for _, group in ipairs(groups) do
        if #group.items > 0 then
            any = true
            local branch = mgr:CreateWidget(mgr:GenerateWidgetId("CAIQD_InvGroup"), "TreeItem", {
                Label = function() return group.title end,
                FocusKey = "sale:invgroup:" .. group.title,
            })
            for _, entry in ipairs(group.items) do
                local captured = entry
                local leaf = mgr:CreateWidget(mgr:GenerateWidgetId("CAIQD_InvItem"), "TreeItem", {
                    Label = function() return captured.label end,
                    Tooltip = function() return captured.tooltip or "" end,
                    FocusKey = "sale:inv:" .. captured.key,
                })
                leaf:On("activate", function()
                    if captured.addOne then captured.addOne() end
                end)
                leaf:AddInputBindings({
                    {
                        Key = Keys.VK_RETURN, IsControl = true, MSG = KeyEvents.KeyUp,
                        Description = "LOC_CAI_QD_KB_BULK_ADD",
                        Action = function()
                            if captured.addTen then captured.addTen(); return true end
                            return false
                        end,
                    },
                })
                branch:AddChild(leaf)
            end
            ui.inventory:AddChild(branch)
        end
    end
    if not any then
        ui.inventory:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAIQD_InvEmpty"), "StaticText", {
            Label = function() return Locale.Lookup("LOC_CAI_QD_EMPTY_INVENTORY") end,
        }))
    end
    mgr:RestoreFocus(ui.inventory, capture)
end

local function RebuildStagedOffer()
    local ui = m_pages.sale
    if not ui or not ui.staged then return end
    local capture = mgr:CaptureFocusKey(ui.staged)
    ui.staged:ClearChildren()
    local entries = Model("sale").offer or {}
    if #entries == 0 then
        ui.staged:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAIQD_StagedEmpty"), "StaticText", {
            Label = function() return Locale.Lookup("LOC_CAI_QD_NO_OFFER_ITEMS") end,
        }))
    else
        for _, entry in ipairs(entries) do
            local captured = entry
            local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAIQD_StagedItem"), "Button", {
                Label = function() return captured.label end,
                Tooltip = function() return captured.tooltip or "" end,
                FocusKey = "sale:staged:" .. captured.key,
            })
            item:On("activate", function()
                if captured.editable and captured.edit then
                    local header = Locale.Lookup("LOC_CAI_QD_EDIT_AMOUNT_HEADER",
                        captured.maxAmount or 1)
                    PushAmountEditor(header, captured.amount or 1, captured.maxAmount or 1,
                        function(newAmount) captured.edit(newAmount) end)
                end
            end)
            item:AddInputBindings({
                {
                    Key = Keys.VK_DELETE, MSG = KeyEvents.KeyUp,
                    Description = "LOC_CAI_QD_KB_REMOVE",
                    Action = function()
                        if captured.remove then captured.remove(); return true end
                        return false
                    end,
                },
            })
            ui.staged:AddChild(item)
        end
    end
    mgr:RestoreFocus(ui.staged, capture)
end

-- ===========================================================================
--  Page construction
-- ===========================================================================
local function SetViewMode(tabKey, mode)
    if mode ~= "table" and mode ~= "list" then return false end
    if m_viewMode ~= mode then
        m_viewMode = mode
        SaveViewMode(mode)
    end
    local ui = m_pages[tabKey]
    if not ui then return true end
    local active = mode == "table" and ui.table or ui.list
    if active then
        local r = m_focusedRow[tabKey]
        if r then
            local key = mode == "table"
                and (ui.tableId .. ":row:" .. tostring(r.playerId) .. ":leader")
                or (tabKey .. ":offer:" .. tostring(r.playerId))
            mgr:PrepareFocus(active, key)
        end
        mgr:SetFocus(active)
    end
    return true
end

local function BuildFilters(page, tabKey)
    local model = Model(tabKey)
    if not model.filters then return end
    local ui = m_pages[tabKey]
    ui.filters = ui.filters or {}
    for _, filter in ipairs(model.filters) do
        local capturedFilter = filter
        local dropdown = mgr:CreateWidget(mgr:GenerateWidgetId("CAIQD_Filter"), "Dropdown", {
            Label = function() return Locale.Lookup(capturedFilter.label) end,
            FocusKey = tabKey .. ":filter:" .. capturedFilter.id,
        })
        local options = {}
        for _, opt in ipairs(capturedFilter.options) do
            table.insert(options, { label = Locale.Lookup(opt.label), value = opt.value })
        end
        dropdown:SetOptions(options)
        for si, opt in ipairs(options) do
            if opt.value == capturedFilter.currentValue then
                dropdown:SetSelectedIndex(si, true); break
            end
        end
        dropdown:On("value_changed", function(_, value)
            capturedFilter.currentValue = value
            if capturedFilter.set then capturedFilter.set(value) end
        end)
        ui.filters[capturedFilter.id] = dropdown
        page:AddChild(dropdown)
    end
end

local function BuildOfferSection(page, tabKey)
    local ui = m_pages[tabKey]
    ui.tableId = "CAIQuickDeals_Table_" .. tabKey

    ui.table = mgr:CreateWidget(ui.tableId, "DataTable", {
        Label = function() return Locale.Lookup("LOC_CAI_QD_AI_OFFERS") end,
        HiddenPredicate = function() return m_viewMode ~= "table" end,
    })
    ui.table:SetColumns(BuildOfferColumns(tabKey))
    ui.table:SetRowsProvider(function() return Model(tabKey).offers end)
    ui.table:SetRowKeyGetter(function(r) return r.playerId end)
    ui.table:SetRowLabelGetter(function(r) return r.leader end)
    ui.table:On("row_focus_enter", function(_, r, rowIndex)
        if rowIndex > 0 then m_focusedRow[tabKey] = r end
    end)
    ui.table:On("row_activate", function(_, r)
        if r.accept then r.accept()
        elseif r.viewDeal then r.viewDeal() end
    end)
    page:AddChild(ui.table)

    ui.list = mgr:CreateWidget(mgr:GenerateWidgetId("CAIQD_List"), "List", {
        Label = function() return Locale.Lookup("LOC_CAI_QD_AI_OFFERS") end,
        HiddenPredicate = function() return m_viewMode ~= "list" end,
    })
    page:AddChild(ui.list)

    ui.sortDropdown = mgr:CreateWidget(mgr:GenerateWidgetId("CAIQD_Sort"), "Dropdown", {
        Label = function() return Locale.Lookup("LOC_CAI_REPORTS_SORT_BY") end,
        FocusKey = tabKey .. ":sort",
        HiddenPredicate = function() return m_viewMode ~= "list" end,
    })
    local sortOptions = BuildSortOptions(tabKey)
    ui.sortDropdown:SetOptions(sortOptions)
    -- Start on Natural order (option 1) so the dropdown isn't blank; natural is the
    -- order Quick Deals already sorts offers into (its default per-unit ranking).
    ui.sortDropdown:SetSelectedIndex(1, true)
    ui.sortDropdown:On("value_changed", function(_, value)
        ui.table:SetDefaultSort(value.column ~= "natural"
            and { column = value.column, ascending = value.ascending } or nil)
        -- Keep the list in the same order as the table sort.
        Model(tabKey).listSort = value
        RebuildOfferList(tabKey)
    end)
    page:AddChild(ui.sortDropdown)

    -- Row-focused extra actions AFTER the table (CityStates pattern): they act on
    -- the last-focused offer row of this tab, and hide when that row can't do it.
    -- Tooltips explain the gold mechanic, which the labels alone don't convey and
    -- which Quick Deals leaves untooltipped on its own arrow buttons. On Sale and
    -- Purchase the arrows convert one-time gold to/from gold-per-turn at 21:1; on
    -- Exchange they step the amount of gold being exchanged.
    -- On Exchange the arrows step the amount of gold being exchanged, not a gold-for-
    -- 30-turns conversion, so the labels differ from Sale/Purchase.
    local incLabel = (tabKey == "exchange")
        and "LOC_CAI_QD_ACTION_INCREASE_AMOUNT" or "LOC_CAI_QD_ACTION_INCREASE_MTG"
    local decLabel = (tabKey == "exchange")
        and "LOC_CAI_QD_ACTION_DECREASE_AMOUNT" or "LOC_CAI_QD_ACTION_DECREASE_MTG"
    local incTip = (tabKey == "exchange")
        and "LOC_CAI_QD_TT_EXCHANGE_INCREASE" or "LOC_CAI_QD_TT_INCREASE_MTG"
    local decTip = (tabKey == "exchange")
        and "LOC_CAI_QD_TT_EXCHANGE_DECREASE" or "LOC_CAI_QD_TT_DECREASE_MTG"

    local function focusedCan(field)
        local r = GetFocused()
        return r ~= nil and r[field] ~= nil
    end
    local function runFocused(field, ...)
        local r = GetFocused()
        if r and r[field] then r[field](...) end
    end

    -- The gold-adjust buttons stay visible whenever an offer row is focused and go
    -- DISABLED when the focused row can't take that action (e.g. no one-time gold to
    -- convert), rather than appearing and vanishing. Convert-all only applies to
    -- Sale/Purchase; the amount editor only to Exchange, so those hide on the tabs
    -- where they don't apply.
    local hasConvert = (tabKey ~= "exchange")
    local hasEdit    = (tabKey == "exchange")

    ui.incMTG = mgr:CreateWidget(mgr:GenerateWidgetId("CAIQD_IncMTG"), "Button", {
        Label = function() return Locale.Lookup(incLabel) end,
        Tooltip = function() return Locale.Lookup(incTip) end,
        FocusKey = tabKey .. ":action:inc",
        HiddenPredicate = function() return GetFocused() == nil end,
        DisabledPredicate = function() return not focusedCan("incMTG") end,
    })
    ui.incMTG:On("activate", function() runFocused("incMTG") end)
    page:AddChild(ui.incMTG)

    ui.decMTG = mgr:CreateWidget(mgr:GenerateWidgetId("CAIQD_DecMTG"), "Button", {
        Label = function() return Locale.Lookup(decLabel) end,
        Tooltip = function() return Locale.Lookup(decTip) end,
        FocusKey = tabKey .. ":action:dec",
        HiddenPredicate = function() return GetFocused() == nil end,
        DisabledPredicate = function() return not focusedCan("decMTG") end,
    })
    ui.decMTG:On("activate", function() runFocused("decMTG") end)
    page:AddChild(ui.decMTG)

    ui.convert = mgr:CreateWidget(mgr:GenerateWidgetId("CAIQD_Convert"), "Button", {
        Label = function() return Locale.Lookup("LOC_CAI_QD_ACTION_CONVERT_ALL") end,
        Tooltip = function() return Locale.Lookup("LOC_CAI_QD_TT_CONVERT_ALL") end,
        FocusKey = tabKey .. ":action:convert",
        HiddenPredicate = function() return (not hasConvert) or GetFocused() == nil end,
        DisabledPredicate = function() return not focusedCan("convertAll") end,
    })
    ui.convert:On("activate", function() runFocused("convertAll") end)
    page:AddChild(ui.convert)

    ui.editAmount = mgr:CreateWidget(mgr:GenerateWidgetId("CAIQD_EditAmt"), "Button", {
        Label = function() return Locale.Lookup("LOC_CAI_QD_ACTION_EDIT_AMOUNT") end,
        Tooltip = function() return Locale.Lookup("LOC_CAI_QD_TT_EDIT_AMOUNT") end,
        FocusKey = tabKey .. ":action:edit",
        HiddenPredicate = function() return (not hasEdit) or GetFocused() == nil end,
        DisabledPredicate = function() return not focusedCan("editAmount") end,
    })
    ui.editAmount:On("activate", function()
        local r = GetFocused()
        if r and r.editAmount then
            local header = Locale.Lookup("LOC_CAI_QD_EDIT_AMOUNT_HEADER", r.maxAmount or 1)
            PushAmountEditor(header, r.amount or 1, r.maxAmount or 1,
                function(newAmount) r.editAmount(newAmount) end)
        end
    end)
    page:AddChild(ui.editAmount)

    -- View toggle sits AFTER the row actions so the increase/decrease/convert
    -- buttons stay next to the offer table they act on.
    ui.switchView = mgr:CreateWidget(mgr:GenerateWidgetId("CAIQD_SwitchView"), "Button", {
        Label = function()
            return Locale.Lookup(m_viewMode == "table"
                and "LOC_CAI_QD_SWITCH_TO_LIST" or "LOC_CAI_QD_SWITCH_TO_TABLE")
        end,
        FocusKey = tabKey .. ":switch-view",
    })
    ui.switchView:On("activate", function()
        return SetViewMode(tabKey, m_viewMode == "table" and "list" or "table")
    end)
    page:AddChild(ui.switchView)

    -- Alt+1 / Alt+2 view switching, scoped to this page.
    page:AddInputBindings({
        {
            Key = Keys["1"], IsAlt = true, MSG = KeyEvents.KeyDown,
            Description = "LOC_CAI_QD_SWITCH_TO_TABLE",
            Action = function() return SetViewMode(tabKey, "table") end,
        },
        {
            Key = Keys["2"], IsAlt = true, MSG = KeyEvents.KeyDown,
            Description = "LOC_CAI_QD_SWITCH_TO_LIST",
            Action = function() return SetViewMode(tabKey, "list") end,
        },
    })
end

local function BuildPanel()
    if m_panel then return end
    m_panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function() return Locale.Lookup("LOC_QD_NAME") end,
    })

    m_tabs = mgr:CreateWidget(mgr:GenerateWidgetId("CAIQD_Tabs"), "TabControl", {
        FocusKey = "tabs",
    })
    m_panel:AddChild(m_tabs)

    for i, def in ipairs(TAB_DEFS) do
        local capturedDef = def
        m_tabs:AddPage(function() return Locale.Lookup(capturedDef.label) end)
        local page = m_tabs:GetPage(i)
        m_pages[def.key] = { page = page }
        if def.key == "sale" then
            m_pages.sale.inventory = mgr:CreateWidget(mgr:GenerateWidgetId("CAIQD_Inventory"), "Tree", {
                Label = function() return Locale.Lookup("LOC_CAI_QD_INVENTORY") end,
                FocusKey = "sale:inventory",
            })
            page:AddChild(m_pages.sale.inventory)
            m_pages.sale.staged = mgr:CreateWidget(mgr:GenerateWidgetId("CAIQD_Staged"), "List", {
                Label = function() return Locale.Lookup("LOC_CAI_QD_YOUR_OFFER") end,
                FocusKey = "sale:staged",
            })
            page:AddChild(m_pages.sale.staged)
        end
        -- Every tab can carry filters now: Sale exposes the item-type preview
        -- filter (recommended offers), Purchase/Exchange their type/gold filters.
        BuildFilters(page, def.key)
        BuildOfferSection(page, def.key)
    end

    m_tabs:On("value_changed", function(_, pageIndex)
        if m_isMirroring then return end
        local def = TAB_DEFS[pageIndex]
        if not def then return end
        m_activeTab = def.key
        LuaEvents.QD_PopupShowTab(def.qd)
        RebuildTab(def.key)
    end)

    -- Turn-notification toggle (disabled in multiplayer, matching Quick Deals).
    -- Placed last, after the tab control, so it doesn't sit between the panel and
    -- the tabs the player came here to use.
    local notify = mgr:CreateWidget(mgr:GenerateWidgetId("CAIQD_Notify"), "Checkbox", {
        Label = function() return Locale.Lookup("LOC_OPTIONS_NOTIFICATIONS") end,
        FocusKey = "notify",
        DisabledPredicate = function() return GameConfiguration.IsAnyMultiplayer() end,
    })
    notify:SetValueSetter(function(_, value)
        if not GameConfiguration.IsAnyMultiplayer() then
            ToggleNotificationOptedOut()
        end
    end)
    notify:SetChecked(not IsNotificationOptedOut(), true)
    m_panel:AddChild(notify)
end

-- ===========================================================================
--  Rebuild dispatch
-- ===========================================================================
function RebuildTab(tabKey)
    if tabKey == "sale" then
        RebuildInventory()
        RebuildStagedOffer()
    end
    RebuildOffers(tabKey)
end

-- Announce only the outcome of a completed fetch, never the interim placeholder
-- states. UpdateFetchStatus flips through "reset" (no offers) then "fetching" on
-- its way to a real result, so speaking those would say "no offers, checking".
-- Providers fire "fetchresult" solely from the true completion events.
local function AnnounceFetchResult(tabKey)
    local count = #Model(tabKey).offers
    if count <= 0 then
        Speak(Locale.Lookup("LOC_CAI_QD_NO_OFFERS"))
    elseif count == 1 then
        Speak(Locale.Lookup("LOC_CAI_QD_OFFERS_AVAILABLE_ONE"))
    else
        Speak(Locale.Lookup("LOC_CAI_QD_OFFERS_AVAILABLE", count))
    end
end

-- After an increase/decrease/convert on a focused offer row, the update returns
-- asynchronously and focus is on the button, not the row. Speak the row's new gold
-- so the button press has audible feedback (Refocus would just re-read the button).
local function AnnounceRowGold(tabKey)
    local prev = m_focusedRow[tabKey]
    if not prev then return end
    local fresh
    for _, rec in ipairs(Model(tabKey).offers) do
        if rec.playerId == prev.playerId then fresh = rec; break end
    end
    if not fresh then return end
    m_focusedRow[tabKey] = fresh
    local lines = {}
    if tabKey == "exchange" then
        if fresh.itemsText and fresh.itemsText ~= "" then
            table.insert(lines, fresh.itemsText)
        end
        if (fresh.oneTime or 0) > 0 then
            table.insert(lines, Locale.Lookup("LOC_CAI_QD_OFFER_ONE_TIME", fresh.oneTime))
        end
        if (fresh.multiTurn or 0) > 0 then
            table.insert(lines, Locale.Lookup("LOC_CAI_QD_OFFER_MULTI_TURN", fresh.multiTurn))
        end
    else
        table.insert(lines, Locale.Lookup("LOC_CAI_QD_OFFER_ONE_TIME", fresh.oneTime or 0))
        table.insert(lines, Locale.Lookup("LOC_CAI_QD_OFFER_MULTI_TURN", fresh.multiTurn or 0))
    end
    SpeakLines(lines)
end

local function OnDataChanged(tabKey, kind)
    if not mgr:GetWidgetById(PANEL_ID) then return end
    if tabKey ~= m_activeTab then return end
    if kind == "inventory" then
        RebuildInventory()
    elseif kind == "offer" then
        RebuildStagedOffer()
    elseif kind == "offers" then
        RebuildOffers(tabKey)
    elseif kind == "offerrow" then
        RebuildOffers(tabKey)
        AnnounceRowGold(tabKey)
    elseif kind == "fetchresult" then
        AnnounceFetchResult(tabKey)
    elseif kind == "resetfilter" then
        -- The provider reset its preview selection to default; sync the dropdown so
        -- it doesn't read a stale item type against the offers now shown.
        local ui = m_pages[tabKey]
        if ui and ui.filters then
            for _, dd in pairs(ui.filters) do dd:SetSelectedIndex(1, true) end
        end
    end
    -- "fetch" is intentionally not handled: it carries interim placeholder states.
end
LuaEvents.CAIQD_Changed.Add(OnDataChanged)

-- ===========================================================================
--  Lifecycle
-- ===========================================================================
local function PushPanel()
    BuildPanel()
    -- Quick Deals' Open() selects the Sale tab, so land there.
    m_activeTab = "sale"
    m_isMirroring = true
    m_tabs:SetActivePage(1)
    m_isMirroring = false
    RebuildTab("sale")
    if mgr:GetWidgetById(PANEL_ID) then
        mgr:SetFocus(m_tabs)
    else
        mgr:Push(m_panel, { focus = m_tabs })
    end
end

local function PopPanel()
    CloseEditWidget()
    if mgr and m_panel and mgr:GetWidgetById(PANEL_ID) then
        mgr:RemoveFromStack(PANEL_ID)
    end
    -- RemoveFromStack destroys the panel (and its whole widget tree), so the cached
    -- references are now dead. Clear them: BuildPanel() short-circuits when m_panel
    -- is set, so leaving a destroyed panel here made the next Open push a dead
    -- widget and the popup never reappeared. Nulling out rebuilds fresh next time.
    m_panel = nil
    m_tabs = nil
    m_pages = {}
    m_editWidget = nil
end

-- ===========================================================================
--  Wraps on the Quick Deals shell
-- ===========================================================================
Open = WrapFunc(Open, function(orig)
    orig()
    -- Open() no-ops when it can't open (not player's turn, already queued); only
    -- push when Quick Deals actually put its popup in the queue.
    if not ContextPtr:IsHidden() or UIManager:IsInPopupQueue(ContextPtr) then
        PushPanel()
    end
end)

Close = WrapFunc(Close, function(orig)
    PopPanel()
    orig()
end)

CloseSilently = WrapFunc(CloseSilently, function(orig)
    PopPanel()
    orig()
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, input)
    if mgr and mgr:GetWidgetById(PANEL_ID) then
        if mgr:HandleInput(input) then
            return true
        end
    end
    return orig(input)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)
