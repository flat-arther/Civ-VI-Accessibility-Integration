-- Accessibility layer for the Make Trade Route screen as rewritten by the
-- Better Trade Screen mod (astog). Included by TradeRouteChooser_CAI.lua when
-- that mod is active. The base context script (BTS TradeRouteChooser) and its
-- TradeSupport data layer are already included by the dispatcher.
--
-- BTS keeps its sort state in a file-local table we cannot reach, so instead of
-- driving the visual sort bar we own a CAI sort-settings table, mutate it with
-- the global InsertSortEntry/RemoveSortEntry, and sort our captured route list
-- with the global SortTradeRoutes. The route list is presented flat and sorted;
-- priority is the position of each checked key in the sort list.

local mgr                = ExposedMembers.CAI_UIManager

local PANEL_ID           = "CAITradeRoute_Panel"
local FILTER_ID          = "CAITradeRoute_Filter"
local TREE_ID            = "CAITradeRoute_Tree"
local SORT_LIST_ID       = "CAITradeRoute_SortList"
local DIR_BTN_ID         = "CAITradeRoute_SortDir"
local DIALOG_ID          = "CAITradeRoute_Confirm"
local HOVER_SOUND        = "Main_Menu_Mouse_Over"

local m_panel            = nil
local m_filter           = nil
local m_tree             = nil
local m_sortList         = nil
local m_dirButton        = nil
local m_bestSortedBtn    = nil
local m_dialog           = nil

local m_caiFilterEntries = {}
local m_caiFilterSelected = 1
local m_caiCaptured      = {} -- routeInfos captured from AddRouteToDestinationStack
local m_caiSorted        = {} -- captured routes after applying the CAI sort
local m_caiSortKeys      = nil -- ordered list of { id, checked, label }
local m_caiSortDir       = SORT_DESCENDING

-- Forward declarations (the sort/tree helpers reference each other).
local ApplySort
local RefreshRouteTree
local CreateRouteItem
local OpenConfirmDialog
local RebuildSortList
local CreateSortCheckbox
local MovePriority

-- ============================================================================
-- Data helpers
-- ============================================================================

local function HasTradeQuest(cityOwnerID)
    local questsManager = Game.GetQuestsManager()
    local localPlayerID = Game.GetLocalPlayer()
    if not questsManager or not localPlayerID then return false end
    local tradeQuestInfo = GameInfo.Quests["QUEST_SEND_TRADE_ROUTE"]
    if not tradeQuestInfo then return false end
    return questsManager:HasActiveQuestFromPlayer(localPlayerID, cityOwnerID, tradeQuestInfo.Index)
end

local function ResolveOriginCity(routeInfo)
    local player = Players[routeInfo.OriginCityPlayer]
    return player and player:GetCities():FindID(routeInfo.OriginCityID) or nil
end

local function ResolveDestCity(routeInfo)
    local player = Players[routeInfo.DestinationCityPlayer]
    return player and player:GetCities():FindID(routeInfo.DestinationCityID) or nil
end

local function YieldName(yieldType)
    local yieldInfo = GameInfo.Yields[yieldType]
    return yieldInfo and Locale.Lookup(yieldInfo.Name) or yieldType
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
    local destCity = ResolveDestCity(routeInfo)
    if not destCity then return "?" end

    local parts = { Locale.ToUpper(destCity:GetName()) }

    -- Turns to complete is Better Trade Screen's headline improvement over the
    -- vanilla distance readout, so lead the destination with it.
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

    return table.concat(parts, "[NEWLINE]")
end

local function BuildRouteTooltip(routeInfo)
    local originCity = ResolveOriginCity(routeInfo)
    local destCity = ResolveDestCity(routeInfo)
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

-- ============================================================================
-- Sort model
-- ============================================================================

local function DefaultSortKeys()
    return {
        { id = SORT_BY_ID.FOOD,             checked = false, label = function() return YieldName("YIELD_FOOD") end },
        { id = SORT_BY_ID.PRODUCTION,       checked = false, label = function() return YieldName("YIELD_PRODUCTION") end },
        { id = SORT_BY_ID.GOLD,             checked = false, label = function() return YieldName("YIELD_GOLD") end },
        { id = SORT_BY_ID.SCIENCE,          checked = false, label = function() return YieldName("YIELD_SCIENCE") end },
        { id = SORT_BY_ID.CULTURE,          checked = false, label = function() return YieldName("YIELD_CULTURE") end },
        { id = SORT_BY_ID.FAITH,            checked = false, label = function() return YieldName("YIELD_FAITH") end },
        { id = SORT_BY_ID.TURNS_TO_COMPLETE, checked = false, label = function() return Locale.Lookup("LOC_CAI_TRADE_SORT_TURNS") end },
        { id = SORT_BY_ID.DESTINATION_NAME, checked = false, label = function() return Locale.Lookup("LOC_TRADE_OVERVIEW_DESTINATION") end },
    }
end

-- Priority is the position of a checked key among the checked keys, in list order.
local function PriorityOf(key)
    local n = 0
    for _, k in ipairs(m_caiSortKeys) do
        if k.checked then
            n = n + 1
            if k == key then return n end
        end
    end
    return n
end

local function IndexOfKey(key)
    for i, k in ipairs(m_caiSortKeys) do
        if k == key then return i end
    end
    return -1
end

-- Build a BTS sort-settings table from the current checkbox selection, in list
-- (priority) order. Used both to sort the route list and to feed AutomateTrader
-- so "repeat the best route" honors the CAI sort rather than BTS's visual bar.
local function BuildCaiSortSettings()
    local settings = {}
    for _, key in ipairs(m_caiSortKeys) do
        if key.checked then
            InsertSortEntry(key.id, m_caiSortDir, settings)
        end
    end
    return settings
end

-- ============================================================================
-- Confirmation dialog
-- ============================================================================

local function CloseConfirmDialog()
    if m_dialog then
        mgr:RemoveFromStack(DIALOG_ID)
        m_dialog = nil
    end
end

-- bestSorted is true when the dialog was opened from the "repeat the best route"
-- button: that flow always automates from the top of the CAI sort, so it skips
-- the per-route repeat checkbox and drives top-sort automation on confirm.
function OpenConfirmDialog(routeInfo, bestSorted)
    CloseConfirmDialog()

    -- Mirror the vanilla selection so RequestTradeRoute has a destination.
    OnTradeRouteSelected(routeInfo.DestinationCityPlayer, routeInfo.DestinationCityID)

    local summaryText = BuildRouteTooltip(routeInfo)
    local summary = mgr:CreateWidget(mgr:GenerateWidgetId("CAITradeRoute_Summary"), "StaticText", {
        Label = function() return summaryText end,
    })

    local content = { summary }

    -- "Repeat this route" automation lives inside the dialog for a normal route
    -- pick. The best-sorted flow is itself an automation choice, so it omits it.
    local repeatCb = nil
    if not bestSorted then
        repeatCb = mgr:CreateWidget(mgr:GenerateWidgetId("CAITradeRoute_RepeatCb"), "Checkbox", {
            Label = function() return Locale.Lookup("LOC_CAI_TRADE_REPEAT_ROUTE") end,
        })
        repeatCb:SetFocusSound(HOVER_SOUND)
        repeatCb:SetChecked(false, true)
        table.insert(content, repeatCb)
    end

    local confirmBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAITradeRoute_Confirm"), "Button", {
        Label = function() return Locale.Lookup("LOC_ROUTECHOOSER_BEGIN_ROUTE_BUTTON") end,
    })
    confirmBtn:SetFocusSound(HOVER_SOUND)
    confirmBtn:On("activate", function()
        local repeatChecked = repeatCb and repeatCb:IsChecked()

        -- Capture the trader before RequestTradeRoute deselects it.
        local traderUnit = UI.GetHeadSelectedUnit()
        local traderID = traderUnit and traderUnit:GetID() or nil

        CloseConfirmDialog()

        -- Drive automation ourselves so "repeat best route" uses the CAI sort,
        -- not BTS's visual sort bar. Clear the vanilla checkboxes so
        -- RequestTradeRoute does not also apply its own automation.
        if Controls.RepeatRouteCheckbox then Controls.RepeatRouteCheckbox:SetCheck(false) end
        if Controls.FromTopSortEntryCheckbox then Controls.FromTopSortEntryCheckbox:SetCheck(false) end

        RequestTradeRoute()

        if traderID then
            if bestSorted then
                AutomateTrader(traderID, true, BuildCaiSortSettings())
            elseif repeatChecked then
                AutomateTrader(traderID, true)
            end
        end
    end)

    local cancelBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAITradeRoute_Cancel"), "Button", {
        Label = function() return Locale.Lookup("LOC_CAI_TRADE_ROUTE_CANCEL") end,
    })
    cancelBtn:SetFocusSound(HOVER_SOUND)
    cancelBtn:On("activate", function()
        CloseConfirmDialog()
    end)

    m_dialog = mgr.WidgetHelpers.MakeGeneralDialog(
        function() return Locale.Lookup("LOC_CAI_TRADE_ROUTE_CONFIRM_TITLE") end,
        { confirmBtn, cancelBtn },
        content,
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
                    CloseConfirmDialog()
                    return true
                end,
            },
        })
        mgr:Push(m_dialog)
    end
end

-- ============================================================================
-- Route tree
-- ============================================================================

function CreateRouteItem(routeInfo)
    local capturedInfo = routeInfo
    local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAITradeRoute_Route"), "TreeItem", {
        Label = function() return BuildRouteLabel(capturedInfo) end,
        Tooltip = function() return BuildRouteTooltip(capturedInfo) end,
        FocusKey = "route:" .. capturedInfo.DestinationCityPlayer .. ":" .. capturedInfo.DestinationCityID,
    })
    item:SetFocusSound(HOVER_SOUND)
    item:On("activate", function()
        OpenConfirmDialog(capturedInfo)
    end)

    local originAgg = BuildYieldSummary(capturedInfo, false)
    if originAgg ~= "" then
        local originCity = ResolveOriginCity(capturedInfo)
        item:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAITradeRoute_OriginYields"), "StaticText", {
            Label = function()
                return Locale.Lookup("LOC_ROUTECHOOSER_RECEIVES_RESOURCE", Locale.Lookup(originCity:GetName())) ..
                    "[NEWLINE]" .. originAgg
            end,
        }))
    end

    local destAgg = BuildYieldSummary(capturedInfo, true)
    if destAgg ~= "" then
        local destCity = ResolveDestCity(capturedInfo)
        item:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAITradeRoute_DestYields"), "StaticText", {
            Label = function()
                return Locale.Lookup("LOC_ROUTECHOOSER_RECEIVES_RESOURCE", Locale.Lookup(destCity:GetName())) ..
                    "[NEWLINE]" .. destAgg
            end,
        }))
    end

    return item
end

function RefreshRouteTree()
    if not m_tree then return end

    local capture = mgr:CaptureFocusKey(m_tree)
    m_tree:ClearChildren()

    if #m_caiSorted == 0 then
        m_tree:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAITradeRoute_NoRoutes"), "StaticText", {
            Label = function() return Locale.Lookup("LOC_ROUTECHOOSER_NO_TRADE_ROUTES") end,
        }))
    else
        for _, routeInfo in ipairs(m_caiSorted) do
            m_tree:AddChild(CreateRouteItem(routeInfo))
        end
    end

    mgr:RestoreFocus(m_tree, capture)
end

function ApplySort()
    m_caiSorted = SortTradeRoutes(m_caiCaptured, BuildCaiSortSettings())
    RefreshRouteTree()
end

-- ============================================================================
-- Sort list (checkbox per key) + direction button
-- ============================================================================

function CreateSortCheckbox(key)
    local cb = mgr:CreateWidget(mgr:GenerateWidgetId("CAITradeSort_Key"), "Checkbox", {
        Label = function()
            local base = key.label()
            if key.checked then
                base = base .. ", " .. Locale.Lookup("LOC_CAI_TRADE_SORT_PRIORITY", PriorityOf(key))
            end
            return base
        end,
        FocusKey = "sortkey:" .. key.id,
    })
    cb:SetFocusSound(HOVER_SOUND)
    cb:SetChecked(key.checked, true)
    cb:On("value_changed", function(_, checked)
        key.checked = checked
        ApplySort()
    end)
    cb:AddInputBindings({
        {
            Key = Keys.VK_UP,
            IsShift = true,
            MSG = KeyEvents.KeyDown,
            Description = "LOC_CAI_KB_MOVE_PRIORITY_UP",
            Action = function() return MovePriority(key, -1) end,
        },
        {
            Key = Keys.VK_DOWN,
            IsShift = true,
            MSG = KeyEvents.KeyDown,
            Description = "LOC_CAI_KB_MOVE_PRIORITY_DOWN",
            Action = function() return MovePriority(key, 1) end,
        },
    })
    return cb
end

function RebuildSortList()
    if not m_sortList then return end
    local capture = mgr:CaptureFocusKey(m_sortList)
    m_sortList:ClearChildren()
    for _, key in ipairs(m_caiSortKeys) do
        m_sortList:AddChild(CreateSortCheckbox(key))
    end
    mgr:RestoreFocus(m_sortList, capture)
end

function MovePriority(key, direction)
    local idx = IndexOfKey(key)
    if idx == -1 then return true end

    local target = idx + direction
    if target < 1 or target > #m_caiSortKeys then
        -- Already at the boundary; re-speak current state.
        mgr:Refocus()
        return true
    end

    m_caiSortKeys[idx], m_caiSortKeys[target] = m_caiSortKeys[target], m_caiSortKeys[idx]
    RebuildSortList()
    ApplySort()
    mgr:Refocus()
    return true
end

local function BuildDirectionButton()
    m_dirButton = mgr:CreateWidget(DIR_BTN_ID, "Button", {
        Label = function()
            local tag = (m_caiSortDir == SORT_DESCENDING)
                and "LOC_CAI_TRADE_SORT_DIR_DESCENDING"
                or "LOC_CAI_TRADE_SORT_DIR_ASCENDING"
            return Locale.Lookup(tag)
        end,
        FocusKey = "sortdir",
    })
    m_dirButton:SetFocusSound(HOVER_SOUND)
    m_dirButton:On("activate", function()
        m_caiSortDir = (m_caiSortDir == SORT_DESCENDING) and SORT_ASCENDING or SORT_DESCENDING
        ApplySort()
        mgr:Refocus()
    end)
end

-- ============================================================================
-- Filter dropdown
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

-- ============================================================================
-- Panel
-- ============================================================================

local function BuildPanel()
    m_caiSortKeys = DefaultSortKeys()

    m_panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function()
            local originCity = m_caiCaptured[1] and ResolveOriginCity(m_caiCaptured[1]) or nil
            if originCity then
                return Locale.Lookup("LOC_ROUTECHOOSER_TO_DESTINATION", Locale.ToUpper(originCity:GetName()))
            end
            return Locale.Lookup("LOC_CAI_TRADE_ROUTE_PANEL_TITLE_GENERIC")
        end,
    })

    m_tree = mgr:CreateWidget(TREE_ID, "Tree", {
        Label = function() return Locale.Lookup("LOC_TRADE_OVERVIEW_DESTINATION") end,
    })
    m_panel:AddChild(m_tree)

    m_filter = mgr:CreateWidget(FILTER_ID, "Dropdown", {
        Label = function() return Locale.Lookup("LOC_ROUTECHOOSER_FILTER_SHOWROUTES") end,
    })
    m_filter:SetFocusSound(HOVER_SOUND)
    m_filter:On("value_changed", function(_, filterIndex)
        OnFilterSelected(0, filterIndex)
    end)
    m_panel:AddChild(m_filter)

    m_sortList = mgr:CreateWidget(SORT_LIST_ID, "List", {
        Label = function() return Locale.Lookup("LOC_CAI_TRADE_SORT_LIST") end,
    })
    m_panel:AddChild(m_sortList)
    RebuildSortList()

    BuildDirectionButton()
    m_panel:AddChild(m_dirButton)

    -- Automate the single best route by the current CAI sort. Opens the same
    -- confirmation dialog for the route that would be chosen.
    m_bestSortedBtn = mgr:CreateWidget("CAITradeRoute_BestSortedBtn", "Button", {
        Label = function() return Locale.Lookup("LOC_CAI_TRADE_REPEAT_TOP") end,
    })
    m_bestSortedBtn:SetFocusSound(HOVER_SOUND)
    m_bestSortedBtn:On("activate", function()
        local topRoute = m_caiSorted[1]
        if not topRoute then
            -- No valid routes to automate; keep the user on the button.
            Speak(Locale.Lookup("LOC_ROUTECHOOSER_NO_TRADE_ROUTES"))
            return
        end
        OpenConfirmDialog(topRoute, true)
    end)
    m_panel:AddChild(m_bestSortedBtn)
end

local function PushPanel()
    BuildPanel()
    RebuildFilter()
    ApplySort()
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
    m_sortList = nil
    m_dirButton = nil
    m_bestSortedBtn = nil
end

-- ============================================================================
-- Data capture wraps
-- ============================================================================

AddFilter = WrapFunc(AddFilter, function(orig, filterName, filterFunction)
    local countBefore = #m_caiFilterEntries
    orig(filterName, filterFunction)
    for i = 1, countBefore do
        if m_caiFilterEntries[i].text == filterName then
            return
        end
    end
    table.insert(m_caiFilterEntries, { text = filterName })
end)

AddRouteToDestinationStack = WrapFunc(AddRouteToDestinationStack, function(orig, routeInfo)
    orig(routeInfo)
    table.insert(m_caiCaptured, routeInfo)
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
end)

RefreshStack = WrapFunc(RefreshStack, function(orig)
    m_caiCaptured = {}
    orig()
    if m_panel and m_tree then
        ApplySort()
    end
end)

RefreshFilters = WrapFunc(RefreshFilters, function(orig)
    m_caiFilterEntries = {}
    orig()
    local selectedText = Controls.FilterButton:GetText()
    if selectedText then
        for i, entry in ipairs(m_caiFilterEntries) do
            if entry.text == selectedText then
                m_caiFilterSelected = i
                break
            end
        end
    end
    if m_filter and m_panel then
        RebuildFilter()
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
