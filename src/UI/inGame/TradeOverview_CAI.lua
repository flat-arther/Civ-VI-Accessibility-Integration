include("caiUtils")
if GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_INDONESIA_KHMER" then
    include("TradeOverview_Indonesia_KhmerScenario")
else
    include("TradeOverview")
end

ContextPtr.SetInputHandler = origSetInputHandler

local mgr                  = ExposedMembers.CAI_UIManager

local PANEL_ID             = "CAITradeOv_Panel"
local TABS_ID              = "CAITradeOv_Tabs"
local HOVER_SOUND          = "Main_Menu_Mouse_Over"

local TAB_MY_ROUTES        = 0
local TAB_ROUTES_TO        = 1
local TAB_AVAILABLE        = 2

local m_panel              = nil
local m_tabs               = nil
local m_trees              = {}
local m_capturedEntries    = {}
local m_isMirroringTab     = false
local m_caiCurrentTab      = TAB_MY_ROUTES

-- ============================================================================
-- Helpers
-- ============================================================================

local function BuildAggregateYields(kRouteInfo)
    local yields = {}
    for yieldIndex = 1, #kRouteInfo.kYieldValues do
        local val = kRouteInfo.kYieldValues[yieldIndex]
        if val ~= 0 then
            local yInfo = GameInfo.Yields[yieldIndex - 1]
            if yInfo then
                local sign = val >= 0 and "+" or ""
                table.insert(yields, sign .. Round(val, 1) .. " " .. Locale.Lookup(yInfo.Name))
            end
        end
    end
    if kRouteInfo.MajorityReligion > 0 and kRouteInfo.ReligionPressure > 0 then
        local relInfo = GameInfo.Religions[kRouteInfo.MajorityReligion]
        if relInfo then
            local relName = Game.GetReligion():GetName(relInfo.Index)
            table.insert(yields,
                Locale.Lookup("LOC_CAI_TRADE_ROUTE_RELIGION_PRESSURE", kRouteInfo.ReligionPressure, relName))
        end
    end
    return table.concat(yields, "[NEWLINE]")
end

local function ResolveCity(playerID, cityID)
    local player = Players[playerID]
    if not player then return nil end
    return player:GetCities():FindID(cityID)
end

local function BuildRouteLabelFromCache(entry)
    local originCity = ResolveCity(entry.originPlayerID, entry.originCityID)
    local destCity = ResolveCity(entry.destPlayerID, entry.destCityID)
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

    return table.concat(parts, ", ")
end

local function BuildRouteTooltip(entry)
    local originCity = ResolveCity(entry.originPlayerID, entry.originCityID)
    local destCity = ResolveCity(entry.destPlayerID, entry.destCityID)
    if not originCity or not destCity then return "" end

    local parts = {}

    local dist = Map.GetPlotDistance(originCity:GetX(), originCity:GetY(), destCity:GetX(), destCity:GetY())
    parts[#parts + 1] = Locale.Lookup("LOC_CAI_TRADE_ROUTE_DISTANCE", dist)

    if entry.originInfo then
        local originAgg = BuildAggregateYields(entry.originInfo)
        if originAgg ~= "" then
            parts[#parts + 1] = Locale.Lookup("LOC_ROUTECHOOSER_RECEIVES_RESOURCE",
                Locale.Lookup(originCity:GetName())) .. " " .. originAgg
        end
    end

    if entry.destInfo then
        local destAgg = BuildAggregateYields(entry.destInfo)
        if destAgg ~= "" then
            parts[#parts + 1] = Locale.Lookup("LOC_ROUTECHOOSER_RECEIVES_RESOURCE",
                Locale.Lookup(destCity:GetName())) .. " " .. destAgg
        end
    end

    return table.concat(parts, "[NEWLINE]")
end

-- ============================================================================
-- Data Capture Wraps
-- ============================================================================

local function BuildPlayerHeaderTooltip(playerID)
    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == -1 or playerID == localPlayerID then return "" end

    local player = Players[playerID]
    local hasTradeRoute = false
    local playerCities = player:GetCities()
    for _, city in playerCities:Members() do
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

    local visibilityIndex = Players[localPlayerID]:GetDiplomacy():GetVisibilityOn(player)
    if hasTradeRoute then
        parts[#parts + 1] = Locale.Lookup("LOC_TRADE_OVERVIEW_TOOLTIP_DIPLOMATIC_VIS_BONUS")
    else
        parts[#parts + 1] = Locale.Lookup("LOC_TRADE_OVERVIEW_TOOLTIP_NO_DIPLOMATIC_VIS_BONUS")
    end

    return table.concat(parts, "[NEWLINE]")
end

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
                if m_caiCurrentTab == TAB_AVAILABLE then
                    LuaEvents.TradeOverview_SelectRouteFromOverview(entry.destPlayerID, entry.destCityID)
                end
            end
        end)
    end

    local originCity = ResolveCity(entry.originPlayerID, entry.originCityID)
    local destCity = ResolveCity(entry.destPlayerID, entry.destCityID)
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
            if unit then
                SelectUnit(unit)
            end
        end
    end)
    return item
end

local function CreateProduceTraderRow()
    local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAITradeOv_ProduceTrader"), "TreeItem", {
        Label = function() return Locale.Lookup("LOC_CAI_TRADE_OVERVIEW_PRODUCE_TRADER") end,
        DisabledPredicate = function() return true end,
    })
    return item
end

local function RebuildTreeFromCapture()
    local tabIdx = m_caiCurrentTab + 1
    local tree = m_trees[tabIdx]
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
        if entry.kind == "player_header" or entry.kind == "citystate_header" or entry.kind == "unused_header" then
            local catKey = entry.kind .. ":" .. (entry.playerID and tostring(entry.playerID) or "")
            local props = {
                Label = function() return entry.text end,
                FocusKey = "cat:" .. catKey,
            }
            if entry.kind == "player_header" and entry.playerID then
                local capturedPlayerID = entry.playerID
                props.Tooltip = function() return BuildPlayerHeaderTooltip(capturedPlayerID) end
            end
            currentCategory = mgr:CreateWidget(mgr:GenerateWidgetId("CAITradeOv_Cat"), "TreeItem", props)
            currentCategory:SetFocusSound(HOVER_SOUND)
            tree:AddChild(currentCategory)
        elseif entry.kind == "route" then
            local row = CreateRouteRow(entry)
            if currentCategory then
                currentCategory:AddChild(row)
            else
                tree:AddChild(row)
            end
        elseif entry.kind == "choose_route" then
            local row = CreateChooseRouteRow(entry)
            if currentCategory then
                currentCategory:AddChild(row)
            else
                tree:AddChild(row)
            end
        elseif entry.kind == "produce_trader" then
            local row = CreateProduceTraderRow()
            if currentCategory then
                currentCategory:AddChild(row)
            else
                tree:AddChild(row)
            end
        end
    end

    mgr:RestoreFocus(tree, capture)
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

local function BuildPanel()
    m_panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function()
            local text = Controls.Title:GetText()
            if text and text ~= "" then return text end
            return Locale.Lookup("LOC_TRADE_OVERVIEW_TITLE")
        end,
    })

    m_tabs = mgr:CreateWidget(TABS_ID, "TabControl", {})

    local page1 = m_tabs:AddPage(GetTabLabel(
        Controls.MyRoutesTabLabel, Controls.MyRoutesTabSelectedLabel, "LOC_TRADE_OVERVIEW_MY_ROUTES"))
    m_trees[1] = mgr:CreateWidget("CAITradeOv_Tree1", "Tree", {})
    page1:AddChild(m_trees[1])

    local page2 = m_tabs:AddPage(GetTabLabel(
        Controls.RoutesToCitiesTabLabel, Controls.RoutesToCitiesTabSelectedLabel,
        "LOC_TRADE_OVERVIEW_ROUTES_TO_MY_CITIES"))
    m_trees[2] = mgr:CreateWidget("CAITradeOv_Tree2", "Tree", {})
    page2:AddChild(m_trees[2])

    local page3 = m_tabs:AddPage(GetTabLabel(
        Controls.AvailableRoutesTabLabel, Controls.AvailableRoutesTabSelectedLabel, "LOC_TRADE_OVERVIEW_AVAILABLE_ROUTES"))
    m_trees[3] = mgr:CreateWidget("CAITradeOv_Tree3", "Tree", {})
    page3:AddChild(m_trees[3])

    m_panel:AddChild(m_tabs)

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
-- Lifecycle Wraps
-- ============================================================================

Refresh = WrapFunc(Refresh, function(orig)
    m_capturedEntries = {}
    orig()
    if m_panel and not ContextPtr:IsHidden() then
        RebuildTreeFromCapture()
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
end)

OnShutdown = WrapFunc(OnShutdown, function(orig)
    PopPanel()
    orig()
end)
ContextPtr:SetShutdown(OnShutdown)

-- ============================================================================
-- Input Handler
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
