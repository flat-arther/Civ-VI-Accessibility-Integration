include("CAITradeOverview")
include("CAITradeData")
include("CAIModSupport")
include("caiUtils")

-- Better Balanced Game (BBG) also replaces the TradeOverview context with its own
-- wrapper (tradeoverview_bbg.lua) that overrides ViewAvailableRoutes() to regroup
-- the Available Routes tab (city-states vs. civs by influence eligibility). Only
-- one ReplaceUIScript wins per context, so when BBG is active we chain-include a
-- vendored verbatim copy instead of vanilla and layer CAI accessibility on top of
-- it. CAI wraps CreatePlayerHeader/CreateCityStateHeader/AddRoute, which BBG's
-- ViewAvailableRoutes calls, so the accessibility layer captures BBG's grouping.
if GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_INDONESIA_KHMER" then
    include("TradeOverview_Indonesia_KhmerScenario")
elseif CAIModSupport.IsBBGActive() then
    include("TradeOverview_BetterBalancedGame_CAIBase")
else
    include("TradeOverview")
end

-- Better Trade Screen (astog) replaces this context with a different API
-- (routes come through AddRouteInstanceFromRouteInfo, plus group-by/filter).
-- Hand off to the mod-specific accessibility layer when it is active. The
-- AddRouteInstanceFromRouteInfo guard keeps the vanilla path for the rare case
-- where a scenario ruleset base was included instead of BTS's rewrite.
if IsBetterTradeScreenActive() and AddRouteInstanceFromRouteInfo ~= nil then
    include("TradeOverview_BetterTradeScreen_CAI")
    return
end

ContextPtr.SetInputHandler = origSetInputHandler

local mgr                  = ExposedMembers.CAI_UIManager
local overview

local HOVER_SOUND          = "Main_Menu_Mouse_Over"

local TAB_MY_ROUTES        = 0
local TAB_ROUTES_TO        = 1
local TAB_AVAILABLE        = 2

local m_capturedEntries    = {}

-- ============================================================================
-- Helpers
-- ============================================================================

local function BuildRouteLabelFromCache(entry)
    local originCity = CAITradeData.ResolveCity(entry.originPlayerID, entry.originCityID)
    local destCity = CAITradeData.ResolveCity(entry.destPlayerID, entry.destCityID)
    if not originCity or not destCity then return "?" end

    local parts = {}
    table.insert(parts, Locale.Lookup(originCity:GetName()) .. " " ..
        Locale.Lookup("LOC_TRADE_OVERVIEW_TO") .. " " .. Locale.Lookup(destCity:GetName()))

    if destCity:GetTrade():HasActiveTradingPost(entry.originPlayerID) then
        table.insert(parts, Locale.Lookup("LOC_CAI_TRADE_ROUTE_HAS_TRADING_POST"))
    end

    if entry.originInfo and entry.originInfo.HasPathBonus then
        table.insert(parts, Locale.Lookup("LOC_CAI_TRADE_ROUTE_PATH_BONUS"))
    end

    return table.concat(parts, "[NEWLINE]")
end

local function BuildRouteTooltip(entry)
    local originCity = CAITradeData.ResolveCity(entry.originPlayerID, entry.originCityID)
    local destCity = CAITradeData.ResolveCity(entry.destPlayerID, entry.destCityID)
    if not originCity or not destCity then return "" end
    return CAITradeData.RouteTooltip(originCity, destCity,
        entry.originInfo and CAITradeData.BuildAggregateYields(entry.originInfo) or "",
        entry.destInfo and CAITradeData.BuildAggregateYields(entry.destInfo) or "")
end

-- ============================================================================
-- Data Capture Wraps
-- ============================================================================

CreatePlayerHeader = WrapFunc(CreatePlayerHeader, function(orig, player)
    orig(player)
    local pConfig = PlayerConfigurations[player:GetID()]
    table.insert(m_capturedEntries, {
        kind = "player_header",
        playerID = player:GetID(),
        text = Locale.ToUpper(pConfig:GetPlayerName()),
    })
end)

CreateCityStateHeader = WrapFunc(CreateCityStateHeader, function(orig)
    orig()
    table.insert(m_capturedEntries, {
        kind = "citystate_header",
        text = Locale.ToUpper(Locale.Lookup("LOC_TRADE_OVERVIEW_CITY_STATES")),
    })
end)

CreateUnusedRoutesHeader = WrapFunc(CreateUnusedRoutesHeader, function(orig)
    orig()
    table.insert(m_capturedEntries, {
        kind = "unused_header",
        text = Locale.ToUpper(Locale.Lookup("LOC_TRADE_OVERVIEW_UNUSED_ROUTES")),
    })
end)

AddRoute = WrapFunc(AddRoute, function(orig, originPlayer, originCity, destinationPlayer, destinationCity, traderUnitID)
    orig(originPlayer, originCity, destinationPlayer, destinationCity, traderUnitID)
    table.insert(m_capturedEntries, {
        kind = "route",
        originPlayerID = originPlayer:GetID(),
        originCityID = originCity:GetID(),
        destPlayerID = destinationPlayer:GetID(),
        destCityID = destinationCity:GetID(),
        traderUnitID = traderUnitID,
        originInfo = GetYieldsForRoute(originCity, destinationCity),
        destInfo = GetYieldsForRoute(originCity, destinationCity, true),
    })
end)

AddChooseRouteButton = WrapFunc(AddChooseRouteButton, function(orig, tradeUnit)
    orig(tradeUnit)
    table.insert(m_capturedEntries, {
        kind = "choose_route",
        unitOwner = tradeUnit:GetOwner(),
        unitID = tradeUnit:GetID(),
    })
end)

AddProduceTradeUnitButton = WrapFunc(AddProduceTradeUnitButton, function(orig)
    orig()
    table.insert(m_capturedEntries, {
        kind = "produce_trader",
    })
end)

-- ============================================================================
-- Tree Population
-- ============================================================================

local function CreateRouteRow(entry)
    local focusKey = "route:" .. entry.originPlayerID .. ":" .. entry.originCityID .. ":"
        .. entry.destPlayerID .. ":" .. entry.destCityID .. ":" .. (entry.traderUnitID or -1)

    local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAITradeOv_Route"), "TreeItem", {
        Label = function() return BuildRouteLabelFromCache(entry) end,
        Tooltip = function() return BuildRouteTooltip(entry) end,
        FocusKey = focusKey,
    })
    item:SetFocusSound(HOVER_SOUND)

    if entry.traderUnitID and entry.traderUnitID ~= -1 then
        item:On("activate", function()
            local unit = Players[entry.originPlayerID]:GetUnits():FindID(entry.traderUnitID)
            if unit then
                SelectUnit(unit)
                if entry.originPlayerID ~= Game.GetLocalPlayer() then
                    local plot = Map.GetPlot(unit:GetX(), unit:GetY())
                    if plot then
                        LuaEvents.CAICursorMoveTo(plot:GetIndex(), "jump")
                    end
                end
                if overview.GetCurrentTab() == TAB_AVAILABLE then
                    LuaEvents.TradeOverview_SelectRouteFromOverview(entry.destPlayerID, entry.destCityID)
                end
            end
        end)
    end

    local originCity = CAITradeData.ResolveCity(entry.originPlayerID, entry.originCityID)
    local destCity = CAITradeData.ResolveCity(entry.destPlayerID, entry.destCityID)
    if originCity and destCity then
        if entry.originInfo and entry.originInfo.TooltipText ~= "" then
            local tooltipText = entry.originInfo.TooltipText
            local child = mgr:CreateWidget(mgr:GenerateWidgetId("CAITradeOv_OriginYield"), "StaticText", {
                Label = function()
                    return Locale.Lookup("LOC_ROUTECHOOSER_RECEIVES_RESOURCE", Locale.Lookup(originCity:GetName())) ..
                    "[NEWLINE]" .. tooltipText
                end,
            })
            item:AddChild(child)
        end

        if entry.destInfo and entry.destInfo.TooltipText ~= "" then
            local tooltipText = entry.destInfo.TooltipText
            local child = mgr:CreateWidget(mgr:GenerateWidgetId("CAITradeOv_DestYield"), "StaticText", {
                Label = function()
                    return Locale.Lookup("LOC_ROUTECHOOSER_RECEIVES_RESOURCE", Locale.Lookup(destCity:GetName())) ..
                    "[NEWLINE]" .. tooltipText
                end,
            })
            item:AddChild(child)
        end
    end

    return item
end

-- ============================================================================
-- Panel Construction
-- ============================================================================

local function GetTabLabel(tabLabel, tabSelectedLabel, fallbackTag)
    return function()
        local text = tabLabel:GetText()
        if text and text ~= "" then return text end
        text = tabSelectedLabel:GetText()
        if text and text ~= "" then return text end
        return Locale.Lookup(fallbackTag)
    end
end

overview = CAITradeOverview.Create(mgr, {
    GetEntries = function() return m_capturedEntries end,
    CreateRouteRow = CreateRouteRow,
    SelectUnit = function(unit) SelectUnit(unit) end,
    IsHidden = function() return ContextPtr:IsHidden() end,
    CloseScreen = function() Close() end,
    GetTitle = function()
        local text = Controls.Title:GetText()
        if text and text ~= "" then return text end
        return Locale.Lookup("LOC_TRADE_OVERVIEW_TITLE")
    end,
    TabLabels = {
        GetTabLabel(Controls.MyRoutesTabLabel, Controls.MyRoutesTabSelectedLabel, "LOC_TRADE_OVERVIEW_MY_ROUTES"),
        GetTabLabel(Controls.RoutesToCitiesTabLabel, Controls.RoutesToCitiesTabSelectedLabel, "LOC_TRADE_OVERVIEW_ROUTES_TO_MY_CITIES"),
        GetTabLabel(Controls.AvailableRoutesTabLabel, Controls.AvailableRoutesTabSelectedLabel, "LOC_TRADE_OVERVIEW_AVAILABLE_ROUTES"),
    },
    ClickTab = function(index)
        if index == 1 then Controls.MyRoutesButton:DoLeftClick()
        elseif index == 2 then Controls.RoutesToCitiesButton:DoLeftClick()
        elseif index == 3 then Controls.AvailableRoutesButton:DoLeftClick() end
    end,
    HeaderProps = function(entry)
        if entry.kind ~= "player_header" and entry.kind ~= "citystate_header" and entry.kind ~= "unused_header" then return nil end
        local key = entry.kind .. ":" .. (entry.playerID and tostring(entry.playerID) or "")
        local props = { Label = function() return entry.text end, FocusKey = "cat:" .. key }
        if entry.kind == "player_header" and entry.playerID then
            local playerID = entry.playerID
            props.Tooltip = function() return CAITradeData.BuildPlayerHeaderTooltip(playerID) end
        end
        return props
    end,
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
-- Lifecycle Wraps
-- ============================================================================

Refresh = WrapFunc(Refresh, function(orig)
    m_capturedEntries = {}
    orig()
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
end)

OnShutdown = WrapFunc(OnShutdown, function(orig)
    overview.Close()
    orig()
end)
ContextPtr:SetShutdown(OnShutdown)

-- ============================================================================
-- Input Handler
-- ============================================================================

ContextPtr:SetInputHandler(overview.HandleInput, true)
