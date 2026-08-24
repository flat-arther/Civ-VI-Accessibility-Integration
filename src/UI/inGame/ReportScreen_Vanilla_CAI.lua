-- Vanilla-path accessibility layer for the base game Report Screen. Included by
-- ReportScreen_CAI.lua (the shared builder infrastructure) when the Better Report
-- Screen mod is NOT active. Owns the panel/tab layout and lifecycle wraps for the
-- three or four vanilla report tabs (Yields, Resources, City Status, Gossip) and
-- drives the shared builders (RebuildYieldsTree/RebuildResourcesTree/
-- RebuildCityStatusTab/RebuildGossipTab) which live in the shared file.
--
-- The shared file exposes as globals: RefreshCAIData, GatherGossip, FilterCAIGossip,
-- and the four Rebuild* tab builders. City cycling and the gossip data helpers are
-- registered/owned by the shared file.

local mgr                  = ExposedMembers.CAI_UIManager

local PANEL_ID             = "CAIReports_Panel"
local TABS_ID              = "CAIReports_Tabs"

local function MakeId(prefix)
    return mgr:GenerateWidgetId(prefix)
end

-- Panel/tab state owned by this variant (the shared file no longer references it).
local m_panel              = nil
local m_tabs               = nil
local m_trees              = {}
local m_isMirroringTab     = false
local m_activeTab          = 1
local m_pendingOpenFocusKey = nil

local m_capturedTabs = {}

local TAB_LABELS = {
    [1] = "LOC_HUD_REPORTS_TAB_YIELDS",
    [2] = "LOC_HUD_REPORTS_TAB_RESOURCES",
    [3] = "LOC_HUD_REPORTS_TAB_CITY_STATUS",
    [4] = "LOC_HUD_REPORTS_TAB_GOSSIP",
}

local function DetectActiveTab()
    return m_activeTab or 1
end

local function BuildPanel()
    if m_panel then return end

    m_localPlayerID = Game.GetLocalPlayer()
    if m_localPlayerID == -1 then return end

    m_panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function() return Locale.Lookup("LOC_HUD_REPORTS_TITLE") end,
    })

    m_tabs = mgr:CreateWidget(TABS_ID, "TabControl", {
        FocusKey = "reports:tabs",
    })
    m_panel:AddChild(m_tabs)

    local tabCount = 3
    if GameCapabilities.HasCapability("CAPABILITY_GOSSIP_REPORT") then
        tabCount = 4
    end

    for i = 1, tabCount do
        local capturedI = i

        local tree
        if capturedI == 3 then
            tree = mgr:CreateWidget(MakeId("CAIRPT_"), "List", {
                FocusKey = "reports:tab:" .. capturedI .. ":list",
                HiddenPredicate = function() return not CAIReports_IsCityStatusListMode() end,
            })
        elseif capturedI == 4 then
            tree = mgr:CreateWidget(MakeId("CAIRPT_"), "List", {
                FocusKey = "reports:tab:" .. capturedI .. ":list",
            })
        else
            tree = mgr:CreateWidget(MakeId("CAIRPT_"), "Tree", { FocusKey = "reports:tab:" .. capturedI .. ":tree" })
        end

        m_tabs:AddPage(function()
            return Locale.Lookup(TAB_LABELS[capturedI])
        end)

        local page = m_tabs:GetPage(capturedI)
        if page then
            page:AddChild(tree)
        end

        m_trees[capturedI] = {
            tree = tree,
            page = page,
            tabIndex = capturedI,
        }
    end

    m_tabs:On("value_changed", function(w, pageIndex)
        if m_isMirroringTab then return end
        m_isMirroringTab = true

        local btn = m_capturedTabs[pageIndex]
        if btn then
            btn:DoLeftClick()
        end

        m_isMirroringTab = false
    end)
end

local function RebuildActiveTab()
    local activeTab = DetectActiveTab()
    local entry = m_trees[activeTab]
    if not entry then return end

    if activeTab == 1 then
        RebuildYieldsTree(entry.tree)
    elseif activeTab == 2 then
        RebuildResourcesTree(entry.tree)
    elseif activeTab == 3 then
        RebuildCityStatusTab(entry)
    elseif activeTab == 4 then
        RebuildGossipTab(entry)
    end
end

local function PushPanel()
    BuildPanel()
    if not m_panel then return end
    local activeTab = DetectActiveTab()

    m_isMirroringTab = true
    if m_tabs then
        m_tabs:SetActivePage(activeTab)
    end
    m_isMirroringTab = false

    RebuildActiveTab()
    local options = { priority = PopupPriority.Medium }
    if m_pendingOpenFocusKey ~= nil then
        options.focus = m_pendingOpenFocusKey
    end
    m_pendingOpenFocusKey = nil
    mgr:Push(m_panel, options)
end

local function PopPanel()
    if mgr and m_panel and mgr:GetWidgetById(PANEL_ID) then
        mgr:RemoveFromStack(PANEL_ID)
    end
    m_panel = nil
    m_tabs = nil
    m_trees = {}
    -- The gossip filter dropdowns are owned by the shared file and are recreated
    -- on the next open (entry.filtersBuilt resets with m_trees), so nothing to
    -- clear here.
end


-- ============================================================================
-- View*Page Wraps
-- ============================================================================
ViewYieldsPage = WrapFunc(ViewYieldsPage, function(orig)
    orig()
    m_activeTab = 1
    if not mgr or ContextPtr:IsHidden() then return end
    if not m_isMirroringTab and m_tabs then
        m_isMirroringTab = true
        m_tabs:SetActivePage(1)
        m_isMirroringTab = false
    end
    local entry = m_trees[1]
    if entry then
        RebuildYieldsTree(entry.tree)
    end
end)

ViewResourcesPage = WrapFunc(ViewResourcesPage, function(orig)
    orig()
    m_activeTab = 2
    if not mgr or ContextPtr:IsHidden() then return end
    if not m_isMirroringTab and m_tabs then
        m_isMirroringTab = true
        m_tabs:SetActivePage(2)
        m_isMirroringTab = false
    end
    local entry = m_trees[2]
    if entry then
        RebuildResourcesTree(entry.tree)
    end
end)

ViewCityStatusPage = WrapFunc(ViewCityStatusPage, function(orig)
    orig()
    m_activeTab = 3
    if not mgr or ContextPtr:IsHidden() then return end
    if not m_isMirroringTab and m_tabs then
        m_isMirroringTab = true
        m_tabs:SetActivePage(3)
        m_isMirroringTab = false
    end
    local entry = m_trees[3]
    if entry then
        RebuildCityStatusTab(entry)
    end
end)

ViewGossipPage = WrapFunc(ViewGossipPage, function(orig)
    orig()
    m_activeTab = 4
    if not mgr or ContextPtr:IsHidden() then return end
    if not m_isMirroringTab and m_tabs then
        m_isMirroringTab = true
        m_tabs:SetActivePage(4)
        m_isMirroringTab = false
    end
    local entry = m_trees[4]
    if entry then
        RebuildGossipTab(entry)
    end
end)

AddTabSection = WrapFunc(AddTabSection, function(orig, name, populateCallback)
    orig(name, populateCallback)
    local children = Controls.TabContainer:GetChildren()
    local lastChild = children[#children]
    if lastChild then
        table.insert(m_capturedTabs, lastChild)
    end
end)

RefreshGossip = WrapFunc(RefreshGossip, function(orig)
    orig()
    if not mgr or ContextPtr:IsHidden() then return end
    GatherGossip()
    FilterCAIGossip()
    local entry = m_trees[4]
    if entry then
        RebuildGossipTab(entry)
    end
end)


-- ============================================================================
-- Lifecycle
-- ============================================================================
Open = WrapFunc(Open, function(orig, tabToOpen)
    mgr = assert(ExposedMembers.CAI_UIManager,
        "CAI Report Screen opened before the accessibility UI manager was available")

    local reportsRequest = ExposedMembers.CAIReports
    if not IsCAITutorialControlAllowed("LaunchBar_Hook_Reports") then
        if reportsRequest then reportsRequest.PendingFocusKey = nil end
        return
    end
    if reportsRequest and reportsRequest.PendingFocusKey then
        m_pendingOpenFocusKey = reportsRequest.PendingFocusKey
        reportsRequest.PendingFocusKey = nil
    end

    orig(tabToOpen)
    RefreshCAIData()
    GatherGossip()
    FilterCAIGossip()
    PushPanel()
end)

Close = WrapFunc(Close, function(orig)
    PopPanel()
    orig()
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
    if mgr and m_panel and mgr:GetWidgetById(PANEL_ID) and mgr:GetTop() == m_panel then
        if mgr:HandleInput(pInputStruct) then
            return true
        end
    end
    return orig(pInputStruct)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)

OnShutdown = WrapFunc(OnShutdown, function(orig)
    PopPanel()
    orig()
end)
