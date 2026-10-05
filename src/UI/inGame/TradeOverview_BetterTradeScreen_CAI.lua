include("CAICapturedDropdown")
include("CAITradeOverview")
include("CAITradeData")
-- Accessibility layer for the Trade Overview screen as rewritten by the Better
-- Trade Screen mod (astog). Included by TradeOverview_CAI.lua when that mod is
-- active. The base context script (BTS TradeOverview) and its TradeSupport data
-- layer are already included by the dispatcher.
--
-- BTS emits headers and rows through differently named functions than vanilla
-- (CreatePlayerHeader stays, but routes come through AddRouteInstanceFromRouteInfo
-- and buttons through *Instance functions) and adds group-by/filter pulldowns.
-- We capture that emit sequence and rebuild a per-tab tree, plus expose the
-- filter and group-by dropdowns and the cancel-automation action.

local mgr                  = ExposedMembers.CAI_UIManager
local overview

local FILTER_ID            = "CAITradeOv_Filter"
local GROUPBY_ID           = "CAITradeOv_GroupBy"
local HOVER_SOUND          = "Main_Menu_Mouse_Over"

local TAB_MY_ROUTES        = 0
local TAB_ROUTES_TO        = 1
local TAB_AVAILABLE        = 2

local m_filter             = nil
local m_groupBy            = nil
local m_capturedEntries    = {}
local m_caiFilterEntries   = {}
local m_caiFilterSelected  = 1
local m_caiGroupEntries    = {}
local m_caiGroupSelected   = 1

-- ============================================================================
-- Data helpers
-- ============================================================================

-- BTS returns per-yield value and pre-formatted tooltip arrays keyed START..END.
local BuildYieldSummary = CAITradeData.CreateYieldSummary(
    GetYieldsForOriginCity, GetYieldsForDestinationCity, START_INDEX, END_INDEX)

local function BuildRouteLabel(routeInfo)
    local originCity = CAITradeData.ResolveCity(routeInfo.OriginCityPlayer, routeInfo.OriginCityID)
    local destCity = CAITradeData.ResolveCity(routeInfo.DestinationCityPlayer, routeInfo.DestinationCityID)
    if not originCity or not destCity then return "?" end

    local parts = {
        Locale.Lookup(originCity:GetName()) .. " " ..
        Locale.Lookup("LOC_TRADE_OVERVIEW_TO") .. " " ..
        Locale.Lookup(destCity:GetName())
    }

    local _, _, turnsToComplete = GetAdvancedRouteInfo(routeInfo)
    if turnsToComplete then
        table.insert(parts, Locale.Lookup("LOC_CAI_TRADE_ROUTE_TURNS_TO_COMPLETE", turnsToComplete))
    end

    if GetRouteHasTradingPost(routeInfo) then
        table.insert(parts, Locale.Lookup("LOC_CAI_TRADE_ROUTE_HAS_TRADING_POST"))
    end

    if CAITradeData.HasTradeQuest(routeInfo.DestinationCityPlayer) then
        table.insert(parts, Locale.Lookup("LOC_CITY_STATES_QUESTS"))
    end

    if routeInfo.TraderUnitID and IsTraderAutomated(routeInfo.TraderUnitID) then
        table.insert(parts, Locale.Lookup("LOC_CAI_TRADE_OVERVIEW_AUTOMATED"))
    end

    return table.concat(parts, "[NEWLINE]")
end

local function BuildRouteTooltip(routeInfo)
    local originCity = CAITradeData.ResolveCity(routeInfo.OriginCityPlayer, routeInfo.OriginCityID)
    local destCity = CAITradeData.ResolveCity(routeInfo.DestinationCityPlayer, routeInfo.DestinationCityID)
    if not originCity or not destCity then return "" end
    return CAITradeData.RouteTooltip(originCity, destCity,
        BuildYieldSummary(routeInfo, false), BuildYieldSummary(routeInfo, true))
end

-- Best-effort match of BTS's "free trade unit present in the origin city": a
-- local trade unit sitting in the origin city that is awake with moves left.
local function FindFreeTraderInCity(originPlayerID, originCityID)
    local player = Players[originPlayerID]
    if not player then return nil end
    local city = player:GetCities():FindID(originCityID)
    if not city then return nil end

    local cx, cy = city:GetX(), city:GetY()
    for _, unit in player:GetUnits():Members() do
        local info = GameInfo.Units[unit:GetUnitType()]
        if info and info.MakeTradeRoute and unit:GetX() == cx and unit:GetY() == cy then
            local activity = UnitManager.GetActivityType(unit)
            if activity == ActivityTypes.ACTIVITY_AWAKE and unit:GetMovesRemaining() > 0 then
                return unit
            end
        end
    end
    return nil
end

-- ============================================================================
-- Data capture wraps
-- ============================================================================

CreatePlayerHeader = WrapFunc(CreatePlayerHeader, function(orig, player)
    orig(player)
    local pConfig = PlayerConfigurations[player:GetID()]
    table.insert(m_capturedEntries, {
        kind = "header",
        playerID = player:GetID(),
        text = Locale.ToUpper(pConfig:GetPlayerName()),
    })
end)

CreateCityStateHeader = WrapFunc(CreateCityStateHeader, function(orig)
    orig()
    table.insert(m_capturedEntries, {
        kind = "header",
        text = Locale.ToUpper(Locale.Lookup("LOC_TRADE_OVERVIEW_CITY_STATES")),
    })
end)

CreateUnusedRoutesHeader = WrapFunc(CreateUnusedRoutesHeader, function(orig)
    orig()
    table.insert(m_capturedEntries, {
        kind = "header",
        text = Locale.ToUpper(Locale.Lookup("LOC_TRADE_OVERVIEW_UNUSED_ROUTES")),
    })
end)

CreateCityHeader = WrapFunc(CreateCityHeader, function(orig, city, currentRouteShowCount, totalRoutes, tooltipString)
    orig(city, currentRouteShowCount, totalRoutes, tooltipString)
    table.insert(m_capturedEntries, {
        kind = "header",
        text = Locale.ToUpper(city:GetName()),
        tooltip = tooltipString,
    })
end)

AddRouteInstanceFromRouteInfo = WrapFunc(AddRouteInstanceFromRouteInfo, function(orig, routeInfo)
    orig(routeInfo)
    table.insert(m_capturedEntries, {
        kind = "route",
        info = routeInfo,
    })
end)

AddChooseRouteButtonInstance = WrapFunc(AddChooseRouteButtonInstance, function(orig, tradeUnit)
    orig(tradeUnit)
    table.insert(m_capturedEntries, {
        kind = "choose_route",
        unitOwner = tradeUnit:GetOwner(),
        unitID = tradeUnit:GetID(),
    })
end)

AddProduceTradeUnitButtonInstance = WrapFunc(AddProduceTradeUnitButtonInstance, function(orig)
    orig()
    table.insert(m_capturedEntries, {
        kind = "produce_trader",
    })
end)

AddFilter = WrapFunc(AddFilter, function(orig, filterName, filterFunction)
    orig(filterName, filterFunction)
    CAICapturedDropdown.AddUniqueText(m_caiFilterEntries, filterName)
end)

AddGroupByEntry = WrapFunc(AddGroupByEntry, function(orig, text, id)
    orig(text, id)
    table.insert(m_caiGroupEntries, { text = text, id = id })
end)

-- ============================================================================
-- Tree population
-- ============================================================================

local function CreateRouteRow(entry)
    local routeInfo = entry.info
    local originPlayerID = routeInfo.OriginCityPlayer
    local originCityID = routeInfo.OriginCityID
    local destPlayerID = routeInfo.DestinationCityPlayer
    local destCityID = routeInfo.DestinationCityID
    local traderUnitID = routeInfo.TraderUnitID

    local focusKey = "route:" .. originPlayerID .. ":" .. originCityID .. ":"
        .. destPlayerID .. ":" .. destCityID .. ":" .. (traderUnitID or -1)

    local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAITradeOv_Route"), "TreeItem", {
        Label = function() return BuildRouteLabel(routeInfo) end,
        Tooltip = function() return BuildRouteTooltip(routeInfo) end,
        FocusKey = focusKey,
    })
    item:SetFocusSound(HOVER_SOUND)

    item:On("activate", function()
        if traderUnitID then
            local unit = Players[originPlayerID]:GetUnits():FindID(traderUnitID)
            if unit then SelectUnit(unit) end
        elseif overview.GetCurrentTab() == TAB_AVAILABLE then
            local unit = FindFreeTraderInCity(originPlayerID, originCityID)
            if unit then
                SelectFreeTrader(unit, destPlayerID, destCityID)
            else
                Speak(Locale.Lookup("LOC_CAI_TRADE_OVERVIEW_NO_FREE_TRADER"))
            end
        end
    end)

    -- Cancel-automation action for automated running routes on the My Routes tab.
    if overview.GetCurrentTab() == TAB_MY_ROUTES and traderUnitID and IsTraderAutomated(traderUnitID) then
        local cancel = mgr:CreateWidget(mgr:GenerateWidgetId("CAITradeOv_CancelAuto"), "TreeItem", {
            Label = function() return Locale.Lookup("LOC_CAI_TRADE_OVERVIEW_CANCEL_AUTOMATION") end,
        })
        cancel:SetFocusSound(HOVER_SOUND)
        cancel:On("activate", function()
            CancelAutomatedTrader(traderUnitID)
            Refresh()
        end)
        item:AddChild(cancel)
    end

    local originAgg = BuildYieldSummary(routeInfo, false)
    if originAgg ~= "" then
        local originCity = CAITradeData.ResolveCity(originPlayerID, originCityID)
        item:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAITradeOv_OriginYield"), "StaticText", {
            Label = function()
                return Locale.Lookup("LOC_ROUTECHOOSER_RECEIVES_RESOURCE", Locale.Lookup(originCity:GetName())) ..
                    "[NEWLINE]" .. originAgg
            end,
        }))
    end

    local destAgg = BuildYieldSummary(routeInfo, true)
    if destAgg ~= "" then
        local destCity = CAITradeData.ResolveCity(destPlayerID, destCityID)
        item:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAITradeOv_DestYield"), "StaticText", {
            Label = function()
                return Locale.Lookup("LOC_ROUTECHOOSER_RECEIVES_RESOURCE", Locale.Lookup(destCity:GetName())) ..
                    "[NEWLINE]" .. destAgg
            end,
        }))
    end

    return item
end

-- ============================================================================
-- Panel construction
-- ============================================================================

overview = CAITradeOverview.Create(mgr, {
    GetEntries = function() return m_capturedEntries end,
    CreateRouteRow = CreateRouteRow,
    SelectUnit = function(unit) SelectUnit(unit) end,
    IsHidden = function() return ContextPtr:IsHidden() end,
    CloseScreen = function() Close() end,
    GetTitle = function()
        local text = Controls.Title and Controls.Title:GetText()
        if text and text ~= "" then return text end
        return Locale.Lookup("LOC_TRADE_OVERVIEW_TITLE")
    end,
    TabLabels = {
        function() return Locale.Lookup("LOC_TRADE_OVERVIEW_MY_ROUTES") end,
        function() return Locale.Lookup("LOC_TRADE_OVERVIEW_ROUTES_TO_MY_CITIES") end,
        function() return Locale.Lookup("LOC_TRADE_OVERVIEW_AVAILABLE_ROUTES") end,
    },
    ClickTab = function(index)
        if index == 1 then Controls.MyRoutesButton:DoLeftClick()
        elseif index == 2 then Controls.RoutesToCitiesButton:DoLeftClick()
        elseif index == 3 then Controls.AvailableRoutesButton:DoLeftClick() end
    end,
    HeaderProps = function(entry)
        if entry.kind ~= "header" then return nil end
        local props = { Label = function() return entry.text end, FocusKey = "cat:" .. entry.text }
        if entry.playerID then
            local playerID = entry.playerID
            props.Tooltip = function() return CAITradeData.BuildPlayerHeaderTooltip(playerID) end
        elseif entry.tooltip then
            local tooltip = entry.tooltip
            props.Tooltip = function() return tooltip end
        end
        return props
    end,
    AddExtras = function(panel)
        m_filter = mgr:CreateWidget(FILTER_ID, "Dropdown", {
            Label = function() return Locale.Lookup("LOC_CAI_TRADE_OVERVIEW_FILTER") end,
        })
        m_filter:SetFocusSound(HOVER_SOUND)
        m_filter:On("value_changed", function(_, idx)
            OnFilterSelected(0, idx)
        end)
        panel:AddChild(m_filter)

        m_groupBy = mgr:CreateWidget(GROUPBY_ID, "Dropdown", {
            Label = function() return Locale.Lookup("LOC_CAI_TRADE_OVERVIEW_GROUP_BY") end,
        })
        m_groupBy:SetFocusSound(HOVER_SOUND)
        m_groupBy:On("value_changed", function(_, idx)
            local entry = m_caiGroupEntries[idx]
            if entry then OnGroupBySelected(0, entry.id) end
        end)
        panel:AddChild(m_groupBy)
    end,
    RefreshExtras = function()
        CAICapturedDropdown.Sync(m_filter, m_caiFilterEntries, m_caiFilterSelected)
        CAICapturedDropdown.Sync(m_groupBy, m_caiGroupEntries, m_caiGroupSelected)
    end,
    ClearExtras = function() m_filter, m_groupBy = nil, nil end,
})

-- ============================================================================
-- Tab handler wraps + re-register
-- ============================================================================

OnMyRoutesButton = WrapFunc(OnMyRoutesButton, function(orig)
    overview.SetCurrentTab(TAB_MY_ROUTES)
    orig()
end)
Controls.MyRoutesButton:RegisterCallback(Mouse.eLClick, OnMyRoutesButton)

OnRoutesToCitiesButton = WrapFunc(OnRoutesToCitiesButton, function(orig)
    overview.SetCurrentTab(TAB_ROUTES_TO)
    orig()
end)
Controls.RoutesToCitiesButton:RegisterCallback(Mouse.eLClick, OnRoutesToCitiesButton)

OnAvailableRoutesButton = WrapFunc(OnAvailableRoutesButton, function(orig)
    overview.SetCurrentTab(TAB_AVAILABLE)
    orig()
end)
Controls.AvailableRoutesButton:RegisterCallback(Mouse.eLClick, OnAvailableRoutesButton)

-- ============================================================================
-- Lifecycle wraps
-- ============================================================================

Refresh = WrapFunc(Refresh, function(orig)
    m_capturedEntries = {}
    m_caiFilterEntries = {}
    m_caiGroupEntries = {}
    orig()

    -- Sync selected filter/group from the live BTS buttons.
    local filterText = Controls.OverviewFilterButton and Controls.OverviewFilterButton:GetText()
    m_caiFilterSelected = CAICapturedDropdown.FindSelection(m_caiFilterEntries, filterText, m_caiFilterSelected)
    local groupText = Controls.OverviewGroupByButton and Controls.OverviewGroupByButton:GetText()
    m_caiGroupSelected = CAICapturedDropdown.FindSelection(m_caiGroupEntries, groupText, m_caiGroupSelected)

    overview.Refresh()
end)

Open = WrapFunc(Open, function(orig)
    orig()
    if mgr and not ContextPtr:IsHidden() then
        overview.Open()
    end
end)

Close = WrapFunc(Close, function(orig)
    overview.Close()
    orig()
    -- BTS Close() resets to the My Routes tab and the first filter; mirror that
    -- so the CAI state does not desync on reopen.
    overview.SetCurrentTab(TAB_MY_ROUTES)
    m_caiFilterSelected = 1
    m_caiGroupSelected = 1
end)

OnShutdown = WrapFunc(OnShutdown, function(orig)
    overview.Close()
    orig()
end)
ContextPtr:SetShutdown(OnShutdown)

-- ============================================================================
-- Input handler
-- ============================================================================

ContextPtr:SetInputHandler(overview.HandleInput, true)
