include("CAIModSupport")
include("CAICapturedDropdown")
include("CAITradeData")
include("caiUtils")
include("TradeRouteChooser")

-- Better Trade Screen (astog) replaces this context with a different API. When it
-- is active, hand off to the mod-specific accessibility layer and skip the
-- vanilla wrappers below.
if CAIModSupport.IsBetterTradeScreenActive() then
    include("TradeRouteChooser_BetterTradeScreen_CAI")
    return
end

local mgr                 = CAI:GetUIManager()

local PANEL_ID            = "CAITradeRoute_Panel"
local FILTER_ID           = "CAITradeRoute_Filter"
local TREE_ID             = "CAITradeRoute_Tree"
local DIALOG_ID           = "CAITradeRoute_Confirm"
local HOVER_SOUND         = "Main_Menu_Mouse_Over"

local m_panel             = nil
local m_filter            = nil
local m_tree              = nil
local m_dialog            = nil
local m_catYourCities     = nil
local m_catOtherCivs      = nil
local m_catCityStates     = nil
local m_noRoutesLabel     = nil

local m_caiFilterEntries  = {}
local m_caiFilterSelected = 1
local m_caiCapturedCities = {}

-- ============================================================================
-- Helpers
-- ============================================================================

local function IsCityState(ownerID)
    local pPlayerInfluence = Players[ownerID]:GetInfluence()
    return pPlayerInfluence and pPlayerInfluence:CanReceiveInfluence()
end

local function BuildRouteLabel(city)
    local parts = {}
    local cityName = CAITradeData.DestinationName(city)
    table.insert(parts, cityName)

    local originCity = GetOriginCity()
    if originCity then
        if city:GetTrade():HasActiveTradingPost(originCity:GetOwner()) then
            table.insert(parts, Locale.Lookup("LOC_CAI_TRADE_ROUTE_HAS_TRADING_POST"))
        end
        local kOriginInfo = GetYieldsForRoute(originCity, city)
        if kOriginInfo.HasPathBonus then
            table.insert(parts, Locale.Lookup("LOC_CAI_TRADE_ROUTE_PATH_BONUS"))
        end
    end

    if CAITradeData.HasTradeQuest(city:GetOwner()) then
        table.insert(parts, Locale.Lookup("LOC_CITY_STATES_QUESTS"))
    end

    return table.concat(parts, "[NEWLINE]")
end

local function BuildRouteTooltip(city)
    local originCity = GetOriginCity()
    if not originCity then return "" end
    return CAITradeData.RouteTooltip(originCity, city,
        CAITradeData.BuildAggregateYields(GetYieldsForRoute(originCity, city)),
        CAITradeData.BuildAggregateYields(GetYieldsForRoute(originCity, city, true)))
end

-- ============================================================================
-- Confirmation Dialog
-- ============================================================================

local function CloseConfirmDialog()
    if m_dialog then
        mgr:RemoveFromStack(DIALOG_ID)
        m_dialog = nil
    end
end

local function OpenConfirmDialog(city)
    CloseConfirmDialog()

    OnTradeRouteSelected(city:GetOwner(), city:GetID())

    local summaryText = BuildRouteTooltip(city)

    local summary = mgr:CreateWidget(mgr:GenerateWidgetId("CAITradeRoute_Summary"), "StaticText", {
        Label = function() return summaryText end,
    })

    local confirmBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAITradeRoute_Confirm"), "Button", {
        Label = function()
            local text = Controls.BeginRouteLabel:GetText()
            if text and text ~= "" then return text end
            return Locale.Lookup("LOC_ROUTECHOOSER_BEGIN_ROUTE_BUTTON")
        end,
    })
    confirmBtn:SetFocusSound(HOVER_SOUND)
    confirmBtn:On("activate", function()
        CloseConfirmDialog()
        Controls.BeginRouteButton:DoLeftClick()
    end)

    local cancelBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAITradeRoute_Cancel"), "Button", {
        Label = function() return Locale.Lookup("LOC_CAI_TRADE_ROUTE_CANCEL") end,
    })
    cancelBtn:SetFocusSound(HOVER_SOUND)
    cancelBtn:On("activate", function()
        Controls.CancelButton:DoLeftClick()
        CloseConfirmDialog()
    end)

    m_dialog = mgr.WidgetHelpers.MakeGeneralDialog(
        function() return Locale.Lookup("LOC_CAI_TRADE_ROUTE_CONFIRM_TITLE") end,
        { confirmBtn, cancelBtn },
        { summary },
        1
    )
    if m_dialog then
        m_dialog.Id = DIALOG_ID
        m_dialog:AddInputBindings({
            {
                Key = Keys.VK_ESCAPE,
                MSG = KeyEvents.KeyUp,
                Description = "LOC_CAI_KB_CLOSE",
                Action = function()
                    Controls.CancelButton:DoLeftClick()
                    CloseConfirmDialog()
                    return true
                end,
            },
        })
        mgr:Push(m_dialog)
    end
end

-- ============================================================================
-- Tree population
-- ============================================================================

local function PopulateCategory(cat, cities)
    cat:ClearChildren()
    local originCity = GetOriginCity()
    for _, city in ipairs(cities) do
        local capturedCity = city
        local owner = capturedCity:GetOwner()
        local id = capturedCity:GetID()
        local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAITradeRoute_Route"), "TreeItem", {
            Label = function() return BuildRouteLabel(capturedCity) end,
            Tooltip = function() return BuildRouteTooltip(capturedCity) end,
            FocusKey = "route:" .. owner .. ":" .. id,
        })
        item:SetFocusSound(HOVER_SOUND)
        item:On("activate", function()
            OpenConfirmDialog(capturedCity)
        end)

        if originCity then
            local kOriginInfo = GetYieldsForRoute(originCity, capturedCity)
            local kDestInfo = GetYieldsForRoute(originCity, capturedCity, true)
            local originBreakdown = kOriginInfo.TooltipText
            local destBreakdown = kDestInfo.TooltipText

            if originBreakdown ~= "" then
                local originChild = mgr:CreateWidget(mgr:GenerateWidgetId("CAITradeRoute_OriginYields"), "StaticText", {
                    Label = function()
                        return Locale.Lookup("LOC_ROUTECHOOSER_RECEIVES_RESOURCE", Locale.Lookup(originCity:GetName())) ..
                        "[NEWLINE]" .. originBreakdown
                    end,
                })
                item:AddChild(originChild)
            end

            if destBreakdown ~= "" then
                local destChild = mgr:CreateWidget(mgr:GenerateWidgetId("CAITradeRoute_DestYields"), "StaticText", {
                    Label = function()
                        return Locale.Lookup("LOC_ROUTECHOOSER_RECEIVES_RESOURCE", Locale.Lookup(capturedCity:GetName())) ..
                        "[NEWLINE]" .. destBreakdown
                    end,
                })
                item:AddChild(destChild)
            end
        end

        cat:AddChild(item)
    end
end

local function RefreshTreeContent()
    if not m_tree then return end

    local capture = mgr:CaptureFocusKey(m_tree)

    local yourCities = {}
    local otherCivs = {}
    local cityStates = {}
    local localPlayerID = Game.GetLocalPlayer()

    for _, city in ipairs(m_caiCapturedCities) do
        local owner = city:GetOwner()
        if owner == localPlayerID then
            table.insert(yourCities, city)
        elseif IsCityState(owner) then
            table.insert(cityStates, city)
        else
            table.insert(otherCivs, city)
        end
    end

    PopulateCategory(m_catYourCities, yourCities)
    PopulateCategory(m_catOtherCivs, otherCivs)
    PopulateCategory(m_catCityStates, cityStates)

    local totalRoutes = #yourCities + #otherCivs + #cityStates

    m_catYourCities:SetHiddenPredicate(function() return #yourCities == 0 end)
    m_catOtherCivs:SetHiddenPredicate(function() return #otherCivs == 0 end)
    m_catCityStates:SetHiddenPredicate(function() return #cityStates == 0 end)
    m_noRoutesLabel:SetHiddenPredicate(function() return totalRoutes > 0 end)

    mgr:RestoreFocus(m_tree, capture)
end

-- ============================================================================
-- Panel
-- ============================================================================

local function BuildPanel()
    m_panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function()
            local originCity = GetOriginCity()
            if originCity then
                return Locale.Lookup("LOC_ROUTECHOOSER_TO_DESTINATION", Locale.ToUpper(originCity:GetName()))
            end
            return Locale.Lookup("LOC_CAI_TRADE_ROUTE_PANEL_TITLE_GENERIC")
        end,
    })

    m_tree = mgr:CreateWidget(TREE_ID, "Tree", {
        Label = function() return Locale.Lookup("LOC_TRADE_OVERVIEW_DESTINATION") end,
    })

    m_catYourCities = mgr:CreateWidget("CAITradeRoute_CatYour", "TreeItem", {
        Label = function() return Locale.Lookup("LOC_CAI_TRADE_ROUTE_YOUR_CITIES") end,
        FocusKey = "cat:your_cities",
    })
    m_catYourCities:SetFocusSound(HOVER_SOUND)
    m_tree:AddChild(m_catYourCities)

    m_catOtherCivs = mgr:CreateWidget("CAITradeRoute_CatOther", "TreeItem", {
        Label = function() return Locale.Lookup("LOC_CAI_TRADE_ROUTE_OTHER_CIVS") end,
        FocusKey = "cat:other_civs",
    })
    m_catOtherCivs:SetFocusSound(HOVER_SOUND)
    m_tree:AddChild(m_catOtherCivs)

    m_catCityStates = mgr:CreateWidget("CAITradeRoute_CatCS", "TreeItem", {
        Label = function() return Locale.Lookup("LOC_CAI_TRADE_ROUTE_CITY_STATES") end,
        FocusKey = "cat:city_states",
    })
    m_catCityStates:SetFocusSound(HOVER_SOUND)
    m_tree:AddChild(m_catCityStates)

    m_noRoutesLabel = mgr:CreateWidget("CAITradeRoute_NoRoutes", "StaticText", {
        Label = function() return Locale.Lookup("LOC_ROUTECHOOSER_NO_TRADE_ROUTES") end,
    })
    m_tree:AddChild(m_noRoutesLabel)

    m_panel:AddChild(m_tree)

    m_filter = mgr:CreateWidget(FILTER_ID, "Dropdown", {
        Label = function() return Locale.Lookup("LOC_ROUTECHOOSER_FILTER_SHOWROUTES") end,
    })
    m_filter:SetFocusSound(HOVER_SOUND)
    m_filter:On("value_changed", function(_, filterIndex)
        OnFilterSelected(0, filterIndex)
    end)
    m_panel:AddChild(m_filter)
end

local function PushPanel()
    BuildPanel()
    CAICapturedDropdown.Sync(m_filter, m_caiFilterEntries, m_caiFilterSelected)
    RefreshTreeContent()
    mgr:Push(m_panel, PopupPriority.Low)
end

local function PopPanel()
    CloseConfirmDialog()
    if mgr and m_panel then
        mgr:RemoveFromStack(PANEL_ID)
    end
    m_panel = nil
    m_filter = nil
    m_tree = nil
    m_catYourCities = nil
    m_catOtherCivs = nil
    m_catCityStates = nil
    m_noRoutesLabel = nil
end

-- ============================================================================
-- Vanilla function wraps to capture data
-- ============================================================================

AddFilter = WrapFunc(AddFilter, function(orig, filterName, filterFunction)
    local countBefore = #m_caiFilterEntries
    orig(filterName, filterFunction)
    CAICapturedDropdown.AddUniqueText(m_caiFilterEntries, filterName, countBefore)
end)

AddCityToDestinationStack = WrapFunc(AddCityToDestinationStack, function(orig, city)
    orig(city)
    table.insert(m_caiCapturedCities, city)
end)

-- ============================================================================
-- Lifecycle wraps
-- ============================================================================

Open = WrapFunc(Open, function(orig)
    orig()
    if mgr and not ContextPtr:IsHidden() then
        PushPanel()
    end
end)

Close = WrapFunc(Close, function(orig)
    PopPanel()
    orig()
    UI.SetInterfaceMode(InterfaceModeTypes.SELECTION)
end)

RefreshStack = WrapFunc(RefreshStack, function(orig)
    m_caiCapturedCities = {}
    orig()
    if m_tree and m_panel then
        RefreshTreeContent()
    end
end)

RefreshFilters = WrapFunc(RefreshFilters, function(orig)
    m_caiFilterEntries = {}
    orig()
    local selectedText = Controls.FilterButton:GetText()
    m_caiFilterSelected = CAICapturedDropdown.FindSelection(m_caiFilterEntries, selectedText, m_caiFilterSelected)
    if m_filter and m_panel then
        CAICapturedDropdown.Sync(m_filter, m_caiFilterEntries, m_caiFilterSelected)
    end
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, input)
    if mgr and (mgr:GetWidgetById(PANEL_ID) or mgr:GetWidgetById(DIALOG_ID)) then
        if mgr:HandleInput(input) then
            return true
        end
    end
    if IsCAIEscapeKeyUp(input) and not IsCAITutorialScreenCloseAllowed() then
        AnnounceCAITutorialScreenCloseBlocked()
        return true
    end
    return orig(input)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)

OnShutdown = WrapFunc(OnShutdown, function(orig)
    PopPanel()
    orig()
end)
ContextPtr:SetShutdown(OnShutdown)
