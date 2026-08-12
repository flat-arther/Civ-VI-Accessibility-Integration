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

local PANEL_ID             = "CAITradeOv_Panel"
local TABS_ID              = "CAITradeOv_Tabs"
local FILTER_ID            = "CAITradeOv_Filter"
local GROUPBY_ID           = "CAITradeOv_GroupBy"
local HOVER_SOUND          = "Main_Menu_Mouse_Over"

local TAB_MY_ROUTES        = 0
local TAB_ROUTES_TO        = 1
local TAB_AVAILABLE        = 2

local m_panel              = nil
local m_tabs               = nil
local m_filter             = nil
local m_groupBy            = nil
local m_trees              = {}
local m_capturedEntries    = {}
local m_caiFilterEntries   = {}
local m_caiFilterSelected  = 1
local m_caiGroupEntries    = {}
local m_caiGroupSelected   = 1
local m_isMirroringTab     = false
local m_caiCurrentTab      = TAB_MY_ROUTES

-- ============================================================================
-- Data helpers
-- ============================================================================

local function ResolveCity(playerID, cityID)
    local player = Players[playerID]
    if not player then return nil end
    return player:GetCities():FindID(cityID)
end

local function HasTradeQuest(cityOwnerID)
    local questsManager = Game.GetQuestsManager()
    local localPlayerID = Game.GetLocalPlayer()
    if not questsManager or not localPlayerID then return false end
    local tradeQuestInfo = GameInfo.Quests["QUEST_SEND_TRADE_ROUTE"]
    if not tradeQuestInfo then return false end
    return questsManager:HasActiveQuestFromPlayer(localPlayerID, cityOwnerID, tradeQuestInfo.Index)
end

-- BTS returns per-yield value and pre-formatted tooltip arrays keyed START..END.
local function BuildYieldSummary(routeInfo, forDest)
    local yields, tooltips
    if forDest then
        yields, tooltips = GetYieldsForDestinationCity(routeInfo, true)
    else
        yields, tooltips = GetYieldsForOriginCity(routeInfo, true)
    end
    local parts = {}
    for yieldIndex = START_INDEX, END_INDEX do
        if yields[yieldIndex] and yields[yieldIndex] > 0 then
            table.insert(parts, tooltips[yieldIndex])
        end
    end
    return table.concat(parts, "[NEWLINE]")
end

local function BuildRouteLabel(routeInfo)
    local originCity = ResolveCity(routeInfo.OriginCityPlayer, routeInfo.OriginCityID)
    local destCity = ResolveCity(routeInfo.DestinationCityPlayer, routeInfo.DestinationCityID)
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

    if HasTradeQuest(routeInfo.DestinationCityPlayer) then
        table.insert(parts, Locale.Lookup("LOC_CITY_STATES_QUESTS"))
    end

    if routeInfo.TraderUnitID and IsTraderAutomated(routeInfo.TraderUnitID) then
        table.insert(parts, Locale.Lookup("LOC_CAI_TRADE_OVERVIEW_AUTOMATED"))
    end

    return table.concat(parts, "[NEWLINE]")
end

local function BuildRouteTooltip(routeInfo)
    local originCity = ResolveCity(routeInfo.OriginCityPlayer, routeInfo.OriginCityID)
    local destCity = ResolveCity(routeInfo.DestinationCityPlayer, routeInfo.DestinationCityID)
    if not originCity or not destCity then return "" end

    local parts = {}
    local dist = Map.GetPlotDistance(originCity:GetX(), originCity:GetY(), destCity:GetX(), destCity:GetY())
    table.insert(parts, Locale.Lookup("LOC_CAI_TRADE_ROUTE_DISTANCE", dist))

    local originAgg = BuildYieldSummary(routeInfo, false)
    if originAgg ~= "" then
        table.insert(parts,
            Locale.Lookup("LOC_ROUTECHOOSER_RECEIVES_RESOURCE", Locale.Lookup(originCity:GetName())) ..
            " " .. originAgg)
    end

    local destAgg = BuildYieldSummary(routeInfo, true)
    if destAgg ~= "" then
        table.insert(parts,
            Locale.Lookup("LOC_ROUTECHOOSER_RECEIVES_RESOURCE", Locale.Lookup(destCity:GetName())) ..
            " " .. destAgg)
    end

    return table.concat(parts, "[NEWLINE]")
end

local function BuildPlayerHeaderTooltip(playerID)
    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == -1 or playerID == localPlayerID then return "" end

    local player = Players[playerID]
    local hasTradeRoute = false
    for _, city in player:GetCities():Members() do
        if city:GetTrade():HasTradeRouteFrom(localPlayerID) then
            hasTradeRoute = true
            break
        end
    end

    local parts = {}

    local baseTourismMod = GlobalParameters.TOURISM_TRADE_ROUTE_BONUS
    local extraTourismMod = Players[localPlayerID]:GetCulture():GetExtraTradeRouteTourismModifier()
    local tourismPct = "+" .. Locale.ToPercent((baseTourismMod + extraTourismMod) / 100)
    if hasTradeRoute then
        parts[#parts + 1] = Locale.Lookup("LOC_TRADE_OVERVIEW_TOOLTIP_TOURISM_BONUS") .. " " .. tourismPct
    else
        parts[#parts + 1] = Locale.Lookup("LOC_TRADE_OVERVIEW_TOOLTIP_NO_TOURISM_BONUS") .. " " .. tourismPct
    end

    if hasTradeRoute then
        parts[#parts + 1] = Locale.Lookup("LOC_TRADE_OVERVIEW_TOOLTIP_DIPLOMATIC_VIS_BONUS")
    else
        parts[#parts + 1] = Locale.Lookup("LOC_TRADE_OVERVIEW_TOOLTIP_NO_DIPLOMATIC_VIS_BONUS")
    end

    return table.concat(parts, "[NEWLINE]")
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
    for _, entry in ipairs(m_caiFilterEntries) do
        if entry.text == filterName then return end
    end
    table.insert(m_caiFilterEntries, { text = filterName })
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
        elseif m_caiCurrentTab == TAB_AVAILABLE then
            local unit = FindFreeTraderInCity(originPlayerID, originCityID)
            if unit then
                SelectFreeTrader(unit, destPlayerID, destCityID)
            else
                Speak(Locale.Lookup("LOC_CAI_TRADE_OVERVIEW_NO_FREE_TRADER"))
            end
        end
    end)

    -- Cancel-automation action for automated running routes on the My Routes tab.
    if m_caiCurrentTab == TAB_MY_ROUTES and traderUnitID and IsTraderAutomated(traderUnitID) then
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
        local originCity = ResolveCity(originPlayerID, originCityID)
        item:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAITradeOv_OriginYield"), "StaticText", {
            Label = function()
                return Locale.Lookup("LOC_ROUTECHOOSER_RECEIVES_RESOURCE", Locale.Lookup(originCity:GetName())) ..
                    "[NEWLINE]" .. originAgg
            end,
        }))
    end

    local destAgg = BuildYieldSummary(routeInfo, true)
    if destAgg ~= "" then
        local destCity = ResolveCity(destPlayerID, destCityID)
        item:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAITradeOv_DestYield"), "StaticText", {
            Label = function()
                return Locale.Lookup("LOC_ROUTECHOOSER_RECEIVES_RESOURCE", Locale.Lookup(destCity:GetName())) ..
                    "[NEWLINE]" .. destAgg
            end,
        }))
    end

    return item
end

local function CreateChooseRouteRow(entry)
    local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAITradeOv_ChooseRoute"), "TreeItem", {
        Label = function() return Locale.Lookup("LOC_CAI_TRADE_OVERVIEW_CHOOSE_ROUTE") end,
        FocusKey = "choose:" .. entry.unitOwner .. ":" .. entry.unitID,
    })
    item:SetFocusSound(HOVER_SOUND)
    item:On("activate", function()
        local player = Players[entry.unitOwner]
        if player then
            local unit = player:GetUnits():FindID(entry.unitID)
            if unit then SelectUnit(unit) end
        end
    end)
    return item
end

local function CreateProduceTraderRow()
    return mgr:CreateWidget(mgr:GenerateWidgetId("CAITradeOv_ProduceTrader"), "TreeItem", {
        Label = function() return Locale.Lookup("LOC_CAI_TRADE_OVERVIEW_PRODUCE_TRADER") end,
        DisabledPredicate = function() return true end,
    })
end

local function RebuildTreeFromCapture()
    local tree = m_trees[m_caiCurrentTab + 1]
    if not tree then return end

    local capture = mgr:CaptureFocusKey(tree)
    tree:ClearChildren()

    if m_caiCurrentTab == TAB_MY_ROUTES then
        local localPlayerID = Game.GetLocalPlayer()
        if localPlayerID ~= -1 then
            local playerTrade = Players[localPlayerID]:GetTrade()
            local active = playerTrade:GetNumOutgoingRoutes()
            local capacity = playerTrade:GetOutgoingRouteCapacity()
            local summaryText = Locale.Lookup("LOC_CAI_TRADE_OVERVIEW_ACTIVE_ROUTES", active, capacity)
            tree:SetLabel(function() return summaryText end)
        end
    end

    local currentCategory = nil
    for _, entry in ipairs(m_capturedEntries) do
        if entry.kind == "header" then
            local props = {
                Label = function() return entry.text end,
                FocusKey = "cat:" .. entry.text,
            }
            if entry.playerID then
                local capturedPlayerID = entry.playerID
                props.Tooltip = function() return BuildPlayerHeaderTooltip(capturedPlayerID) end
            elseif entry.tooltip then
                local capturedTooltip = entry.tooltip
                props.Tooltip = function() return capturedTooltip end
            end
            currentCategory = mgr:CreateWidget(mgr:GenerateWidgetId("CAITradeOv_Cat"), "TreeItem", props)
            currentCategory:SetFocusSound(HOVER_SOUND)
            tree:AddChild(currentCategory)
        else
            local row
            if entry.kind == "route" then
                row = CreateRouteRow(entry)
            elseif entry.kind == "choose_route" then
                row = CreateChooseRouteRow(entry)
            elseif entry.kind == "produce_trader" then
                row = CreateProduceTraderRow()
            end
            if row then
                if currentCategory then
                    currentCategory:AddChild(row)
                else
                    tree:AddChild(row)
                end
            end
        end
    end

    mgr:RestoreFocus(tree, capture)
end

-- ============================================================================
-- Filter / Group-by dropdowns
-- ============================================================================

local function RebuildFilter()
    if not m_filter then return end
    local options = {}
    for i, entry in ipairs(m_caiFilterEntries) do
        table.insert(options, { label = entry.text, value = i })
    end
    m_filter:SetOptions(options)
    m_filter:SetSelectedIndex(m_caiFilterSelected, true)
end

local function RebuildGroupBy()
    if not m_groupBy then return end
    local options = {}
    for i, entry in ipairs(m_caiGroupEntries) do
        table.insert(options, { label = entry.text, value = i })
    end
    m_groupBy:SetOptions(options)
    m_groupBy:SetSelectedIndex(m_caiGroupSelected, true)
end

-- ============================================================================
-- Panel construction
-- ============================================================================

local function BuildPanel()
    m_panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function()
            local text = Controls.Title and Controls.Title:GetText()
            if text and text ~= "" then return text end
            return Locale.Lookup("LOC_TRADE_OVERVIEW_TITLE")
        end,
    })

    m_tabs = mgr:CreateWidget(TABS_ID, "TabControl", {})

    local page1 = m_tabs:AddPage(function() return Locale.Lookup("LOC_TRADE_OVERVIEW_MY_ROUTES") end)
    m_trees[1] = mgr:CreateWidget("CAITradeOv_Tree1", "Tree", {})
    page1:AddChild(m_trees[1])

    local page2 = m_tabs:AddPage(function() return Locale.Lookup("LOC_TRADE_OVERVIEW_ROUTES_TO_MY_CITIES") end)
    m_trees[2] = mgr:CreateWidget("CAITradeOv_Tree2", "Tree", {})
    page2:AddChild(m_trees[2])

    local page3 = m_tabs:AddPage(function() return Locale.Lookup("LOC_TRADE_OVERVIEW_AVAILABLE_ROUTES") end)
    m_trees[3] = mgr:CreateWidget("CAITradeOv_Tree3", "Tree", {})
    page3:AddChild(m_trees[3])

    m_panel:AddChild(m_tabs)

    m_filter = mgr:CreateWidget(FILTER_ID, "Dropdown", {
        Label = function() return Locale.Lookup("LOC_CAI_TRADE_OVERVIEW_FILTER") end,
    })
    m_filter:SetFocusSound(HOVER_SOUND)
    m_filter:On("value_changed", function(_, idx)
        OnFilterSelected(0, idx)
    end)
    m_panel:AddChild(m_filter)

    m_groupBy = mgr:CreateWidget(GROUPBY_ID, "Dropdown", {
        Label = function() return Locale.Lookup("LOC_CAI_TRADE_OVERVIEW_GROUP_BY") end,
    })
    m_groupBy:SetFocusSound(HOVER_SOUND)
    m_groupBy:On("value_changed", function(_, idx)
        local entry = m_caiGroupEntries[idx]
        if entry then OnGroupBySelected(0, entry.id) end
    end)
    m_panel:AddChild(m_groupBy)

    m_panel:AddInputBindings({
        {
            Key = Keys.VK_ESCAPE,
            MSG = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_CLOSE",
            Action = function()
                Close()
                return true
            end,
        },
    })

    m_tabs:On("value_changed", function(_, idx)
        if m_isMirroringTab then return end
        m_isMirroringTab = true
        m_caiCurrentTab = idx - 1
        if idx == 1 then
            Controls.MyRoutesButton:DoLeftClick()
        elseif idx == 2 then
            Controls.RoutesToCitiesButton:DoLeftClick()
        elseif idx == 3 then
            Controls.AvailableRoutesButton:DoLeftClick()
        end
        m_isMirroringTab = false
    end)
end

local function PushPanel()
    if not mgr then return end
    if not m_panel then BuildPanel() end
    RebuildTreeFromCapture()
    RebuildFilter()
    RebuildGroupBy()
    if not mgr:GetWidgetById(PANEL_ID) then
        mgr:Push(m_panel, PopupPriority.Low)
    end
end

local function PopPanel()
    if mgr and m_panel and mgr:GetWidgetById(PANEL_ID) then
        mgr:RemoveFromStack(PANEL_ID)
    end
    m_panel = nil
    m_tabs = nil
    m_filter = nil
    m_groupBy = nil
    m_trees = {}
end

-- ============================================================================
-- Tab handler wraps + re-register
-- ============================================================================

OnMyRoutesButton = WrapFunc(OnMyRoutesButton, function(orig)
    m_caiCurrentTab = TAB_MY_ROUTES
    orig()
end)
Controls.MyRoutesButton:RegisterCallback(Mouse.eLClick, OnMyRoutesButton)

OnRoutesToCitiesButton = WrapFunc(OnRoutesToCitiesButton, function(orig)
    m_caiCurrentTab = TAB_ROUTES_TO
    orig()
end)
Controls.RoutesToCitiesButton:RegisterCallback(Mouse.eLClick, OnRoutesToCitiesButton)

OnAvailableRoutesButton = WrapFunc(OnAvailableRoutesButton, function(orig)
    m_caiCurrentTab = TAB_AVAILABLE
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
    if filterText then
        for i, entry in ipairs(m_caiFilterEntries) do
            if entry.text == filterText then m_caiFilterSelected = i break end
        end
    end
    local groupText = Controls.OverviewGroupByButton and Controls.OverviewGroupByButton:GetText()
    if groupText then
        for i, entry in ipairs(m_caiGroupEntries) do
            if entry.text == groupText then m_caiGroupSelected = i break end
        end
    end

    if m_panel and not ContextPtr:IsHidden() then
        RebuildTreeFromCapture()
        RebuildFilter()
        RebuildGroupBy()
        if m_tabs and not m_isMirroringTab then
            m_tabs:SetActivePage(m_caiCurrentTab + 1, true)
        end
    end
end)

Open = WrapFunc(Open, function(orig)
    orig()
    if mgr and not ContextPtr:IsHidden() then
        PushPanel()
    end
end)

Close = WrapFunc(Close, function(orig)
    PopPanel()
    orig()
    -- BTS Close() resets to the My Routes tab and the first filter; mirror that
    -- so the CAI state does not desync on reopen.
    m_caiCurrentTab = TAB_MY_ROUTES
    m_caiFilterSelected = 1
    m_caiGroupSelected = 1
end)

OnShutdown = WrapFunc(OnShutdown, function(orig)
    PopPanel()
    orig()
end)
ContextPtr:SetShutdown(OnShutdown)

-- ============================================================================
-- Input handler
-- ============================================================================

local function HandleInput(input)
    if mgr and mgr:GetWidgetById(PANEL_ID) then
        if mgr:HandleInput(input) then
            return true
        end
    end
    return false
end
ContextPtr:SetInputHandler(HandleInput, true)
