-- Shared overview shell. Captured record schemas and route actions are adapters;
-- native tab callbacks remain registered by each screen after its base include.
CAITradeOverview = {}

---@param mgr UIScreenManager
---@param adapter CAITradeOverviewAdapter
---@return CAITradeOverviewController
function CAITradeOverview.Create(mgr, adapter)
    local panel, tabs
    local trees = {}
    local currentTab, mirroring = 0, false
    local panelID = "CAITradeOv_Panel"
    local hoverSound = "Main_Menu_Mouse_Over"

    local function CreateChooseRouteRow(entry)
        local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAITradeOv_ChooseRoute"), "TreeItem", {
            Label = function() return Locale.Lookup("LOC_CAI_TRADE_OVERVIEW_CHOOSE_ROUTE") end,
            FocusKey = "choose:" .. entry.unitOwner .. ":" .. entry.unitID,
        })
        item:SetFocusSound(hoverSound)
        item:On("activate", function()
            local player = Players[entry.unitOwner]
            if player then
                local unit = player:GetUnits():FindID(entry.unitID)
                if unit then adapter.SelectUnit(unit) end
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

    local function RebuildTree()
        local tree = trees[currentTab + 1]
        if not tree then return end -- Native Refresh also runs before Open.
        local capture = mgr:CaptureFocusKey(tree)
        tree:ClearChildren()
        if currentTab == 0 then
            local playerID = Game.GetLocalPlayer()
            if playerID ~= -1 then
                local trade = Players[playerID]:GetTrade()
                local summary = Locale.Lookup("LOC_CAI_TRADE_OVERVIEW_ACTIVE_ROUTES",
                    trade:GetNumOutgoingRoutes(), trade:GetOutgoingRouteCapacity())
                tree:SetLabel(function() return summary end)
            end
        end
        local category
        for _, entry in ipairs(adapter.GetEntries()) do
            local props = adapter.HeaderProps(entry)
            if props then
                category = mgr:CreateWidget(mgr:GenerateWidgetId("CAITradeOv_Cat"), "TreeItem", props)
                category:SetFocusSound(hoverSound)
                tree:AddChild(category)
            else
                local row
                if entry.kind == "route" then
                    row = adapter.CreateRouteRow(entry)
                elseif entry.kind == "choose_route" then
                    row = CreateChooseRouteRow(entry)
                elseif entry.kind == "produce_trader" then
                    row = CreateProduceTraderRow()
                end
                if row then (category or tree):AddChild(row) end
            end
        end
        mgr:RestoreFocus(tree, capture)
    end

    local function BuildPanel()
        panel = mgr:CreateWidget(panelID, "Panel", { Label = adapter.GetTitle })
        tabs = mgr:CreateWidget("CAITradeOv_Tabs", "TabControl", {})
        for index, label in ipairs(adapter.TabLabels) do
            local page = tabs:AddPage(label)
            trees[index] = mgr:CreateWidget("CAITradeOv_Tree" .. index, "Tree", {})
            page:AddChild(trees[index])
        end
        panel:AddChild(tabs)
        if adapter.AddExtras then adapter.AddExtras(panel) end
        panel:AddInputBindings({ {
            Key = Keys.VK_ESCAPE, MSG = KeyEvents.KeyUp, Description = "LOC_CAI_KB_CLOSE",
            Action = function() adapter.CloseScreen(); return true end,
        } })
        tabs:On("value_changed", function(_, index)
            if mirroring then return end
            mirroring = true
            currentTab = index - 1
            adapter.ClickTab(index)
            mirroring = false
        end)
    end

    return {
        GetCurrentTab = function() return currentTab end,
        SetCurrentTab = function(index) currentTab = index end,
        Refresh = function()
            if panel and not adapter.IsHidden() then
                RebuildTree()
                if adapter.RefreshExtras then adapter.RefreshExtras() end
                if not mirroring then tabs:SetActivePage(currentTab + 1, true) end
            end
        end,
        Open = function()
            if not mgr then return end
            if not panel then BuildPanel() end
            RebuildTree()
            if adapter.RefreshExtras then adapter.RefreshExtras() end
            if not mgr:GetWidgetById(panelID) then mgr:Push(panel, { priority = PopupPriority.Low }) end
        end,
        Close = function()
            if mgr and panel and mgr:GetWidgetById(panelID) then mgr:RemoveFromStack(panelID) end
            panel, tabs, trees = nil, nil, {}
            if adapter.ClearExtras then adapter.ClearExtras() end
        end,
        HandleInput = function(input)
            if mgr and mgr:GetWidgetById(panelID) and mgr:HandleInput(input) then return true end
            return false
        end,
    }
end
