include("caiUtils")
include("Civ6Common")
if GameConfiguration.GetValue("GAMEMODE_MONOPOLIES") then
    include("GlobalResourcePopup_KublaiKhanVietnam_MODE")
else
    include("GlobalResourcePopup")
end

local mgr                 = ExposedMembers.CAI_UIManager

-- ============================================================================
-- Constants
-- ============================================================================
local PANEL_ID            = "CAIGlobalRes_Panel"
local TREE_ID             = "CAIGlobalRes_Tree"
local HOVER_SOUND         = "Main_Menu_Mouse_Over"

local SORT_OPTIONS        = {
    { nameKey = "LOC_REPORTS_SORT_SCARCITY", sortFn = SortScarcity },
    { nameKey = "LOC_REPORTS_SORT_NAME",     sortFn = SortName },
}

local ORDER_OPTIONS       = {
    { nameKey = "LOC_REPORTS_ORDER_AMOUNT",      sortFn = SortOrderAmount },
    { nameKey = "LOC_REPORTS_ORDER_PLAYER",      sortFn = SortOrderPlayer },
    { nameKey = "LOC_REPORTS_ORDER_PLAYER_SLOT", sortFn = SortOrderSlot },
}

-- ============================================================================
-- State
-- ============================================================================
local m_panel             = nil
local m_tree              = nil
local m_sortDropdown      = nil
local m_orderDropdown     = nil
local m_currentSortIndex  = 1
local m_currentOrderIndex = 1
local m_caiData           = nil

local m_isDLCMonopoly     = false

-- ============================================================================
-- Helpers
-- ============================================================================
local function MakeId(prefix)
    return mgr:GenerateWidgetId(prefix)
end

local function MakeTreeItem(props)
    local item = mgr:CreateWidget(MakeId("CAIGR_"), "TreeItem", props)
    item:SetFocusSound(HOVER_SOUND)
    return item
end

local function AddLeaf(parent, focusKey, labelFn)
    local item = MakeTreeItem({
        Label = labelFn,
        FocusKey = focusKey,
    })
    parent:AddChild(item)
    return item
end

local function GetLeaderDisplayName(playerID)
    local localPlayerID = Game.GetLocalPlayer()
    if playerID == localPlayerID then
        return Locale.Lookup("LOC_HUD_CITY_YOU")
    end
    local pDiplomacy = Players[localPlayerID]:GetDiplomacy()
    if pDiplomacy and pDiplomacy:HasMet(playerID) then
        local leaderTypeName = PlayerConfigurations[playerID]:GetLeaderTypeName()
        local leaderInfo = GameInfo.Leaders[leaderTypeName]
        if leaderInfo then
            return Locale.Lookup(leaderInfo.Name)
        end
        return Locale.Lookup(PlayerConfigurations[playerID]:GetLeaderName())
    end
    return Locale.Lookup("LOC_WORLD_RANKING_UNMET_PLAYER")
end

local function CheckDLCMonopoly()
    if Game.GetEconomicManager then
        local pEcon = Game.GetEconomicManager()
        if pEcon and pEcon.GetResourceMonopolyPlayer and pEcon.GetMapResources then
            m_isDLCMonopoly = true
            return
        end
    end
    m_isDLCMonopoly = false
end

local function HasMercantilism()
    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID < 0 then return false end
    local playerCulture = Players[localPlayerID]:GetCulture()
    for row in GameInfo.Civics() do
        if row.CivicType == "CIVIC_MERCANTILISM" then
            return playerCulture:HasCivic(row.Index)
        end
    end
    return false
end

local function GetResourceIndex(resourceType)
    local info = GameInfo.Resources[resourceType]
    if info then return info.Index end
    return nil
end

local function GetCivLabel(kPlayerEntry, kResourceData)
    local name = GetLeaderDisplayName(kPlayerEntry.playerID)
    local amount = kPlayerEntry.amount

    if m_isDLCMonopoly and kResourceData.class == "RESOURCECLASS_LUXURY" and HasMercantilism() then
        local resIndex = GetResourceIndex(kResourceData.type)
        if resIndex then
            local pEcon = Game.GetEconomicManager()
            local kMapResources = pEcon:GetMapResources()
            local totalOnMap = kMapResources[resIndex] or 0
            if totalOnMap > 0 then
                local monopolyID = pEcon:GetResourceMonopolyPlayer(resIndex)
                if monopolyID == kPlayerEntry.playerID then
                    return name .. ": " .. amount .. "/" .. totalOnMap
                        .. ", " .. Locale.Lookup("LOC_RESREPORT_MONOPOLY_NAME")
                else
                    local percent = amount / totalOnMap
                    return name .. ": " .. amount .. "/" .. totalOnMap
                        .. ", " .. Locale.ToPercent(percent) .. " " .. Locale.Lookup("LOC_RESREPORT_CONTROL")
                end
            end
        end
    end

    return name .. ": " .. amount
end

-- ============================================================================
-- Tree building
-- ============================================================================
local function BuildTree(kData)
    local capture = m_tree and mgr:CaptureFocusKey(m_tree) or nil
    if m_tree then
        m_tree:ClearChildren()
    else
        m_tree = mgr:CreateWidget(TREE_ID, "Tree", {
            Label = function() return Locale.Lookup("LOC_GLOBAL_RESOURCES_TITLE") end,
        })
    end

    local strategic = {}
    local luxury = {}

    for _, kResourceData in ipairs(kData) do
        if kResourceData.isPossessed and kResourceData.kOwnerList and #kResourceData.kOwnerList > 0 then
            if kResourceData.class == "RESOURCECLASS_STRATEGIC" then
                table.insert(strategic, kResourceData)
            elseif kResourceData.class == "RESOURCECLASS_LUXURY" then
                table.insert(luxury, kResourceData)
            end
        end
    end

    local sections = {
        {
            key = "strategic",
            label = "LOC_REPORTS_STRATEGIC_RESOURCES",
            emptyLabel = "LOC_REPORTS_CIVS_NO_STRATEGIC_RESOURCES",
            items = strategic,
        },
        {
            key = "luxury",
            label = "LOC_REPORTS_LUXURY_RESOURCES",
            emptyLabel = "LOC_REPORTS_CIVS_NO_LUXURY_RESOURCES",
            items = luxury,
        },
    }

    for _, section in ipairs(sections) do
        local capturedSection = section
        local groupItem = MakeTreeItem({
            Label = function()
                return Locale.Lookup(capturedSection.label) .. ", "
                    .. Locale.Lookup("LOC_CAI_REPORTS_RESOURCE_COUNT", #capturedSection.items)
            end,
            FocusKey = "grp:" .. capturedSection.key,
        })
        m_tree:AddChild(groupItem)

        if #capturedSection.items == 0 then
            AddLeaf(groupItem, "grp:" .. capturedSection.key .. ":empty", function()
                return Locale.Lookup(capturedSection.emptyLabel)
            end)
        else
            for _, kResourceData in ipairs(capturedSection.items) do
                local capturedRes = kResourceData
                local resItem = MakeTreeItem({
                    Label = function()
                        return Locale.Lookup("LOC_CAI_REPORTS_RESOURCE_TOTAL",
                            Locale.Lookup(capturedRes.name), capturedRes.total)
                    end,
                    FocusKey = "res:" .. capturedRes.type,
                })
                groupItem:AddChild(resItem)

                for _, kPlayerEntry in ipairs(capturedRes.kOwnerList) do
                    local capturedPlayer = kPlayerEntry
                    if capturedPlayer.isMet or capturedPlayer.isSelf then
                        local leaf = AddLeaf(resItem,
                            "res:" .. capturedRes.type .. ":civ:" .. capturedPlayer.playerID,
                            function()
                                return GetCivLabel(capturedPlayer, capturedRes)
                            end)
                        leaf:On("activate", function()
                            OnLeaderClicked(capturedPlayer.playerID)
                        end)
                    end
                end
            end
        end
    end

    if capture then
        mgr:RestoreFocus(m_tree, capture)
    end
end

-- ============================================================================
-- Dropdowns
-- ============================================================================
local function ApplySortAndOrder()
    local sortOpt = SORT_OPTIONS[m_currentSortIndex]
    table.sort(m_caiData, sortOpt.sortFn)

    local orderOpt = ORDER_OPTIONS[m_currentOrderIndex]
    g_isAddingSpaceForEmptyCivs = (orderOpt.nameKey == "LOC_REPORTS_ORDER_PLAYER_SLOT")
    for _, kResourceData in pairs(m_caiData) do
        table.sort(kResourceData.kOwnerList, orderOpt.sortFn)
    end
end

local function RebuildFromState()
    ApplySortAndOrder()
    BuildTree(m_caiData)
end

local function CreateSortDropdown()
    local options = {}
    for i, opt in ipairs(SORT_OPTIONS) do
        table.insert(options, { label = Locale.Lookup(opt.nameKey), value = i })
    end
    m_sortDropdown = mgr:CreateWidget(MakeId("CAIGR_Sort"), "Dropdown", {
        Label = function() return Locale.Lookup("LOC_REPORTS_SORT_BY") end,
    })
    m_sortDropdown:SetOptions(options)
    m_sortDropdown:SetSelectedIndex(m_currentSortIndex, true)
    m_sortDropdown:On("value_changed", function(_, newValue)
        m_currentSortIndex = newValue
        RebuildFromState()
    end)
    return m_sortDropdown
end

local function CreateOrderDropdown()
    local options = {}
    for i, opt in ipairs(ORDER_OPTIONS) do
        table.insert(options, { label = Locale.Lookup(opt.nameKey), value = i })
    end
    m_orderDropdown = mgr:CreateWidget(MakeId("CAIGR_Order"), "Dropdown", {
        Label = function() return Locale.Lookup("LOC_REPORTS_ORDER_CIVS_BY") end,
    })
    m_orderDropdown:SetOptions(options)
    m_orderDropdown:SetSelectedIndex(m_currentOrderIndex, true)
    m_orderDropdown:On("value_changed", function(_, newValue)
        m_currentOrderIndex = newValue
        RebuildFromState()
    end)
    return m_orderDropdown
end

-- ============================================================================
-- Panel lifecycle
-- ============================================================================
local function PushPanel()
    CheckDLCMonopoly()

    m_caiData = PopulateData()
    if not m_caiData then return end


    ApplySortAndOrder()

    m_panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function() return Locale.Lookup("LOC_GLOBAL_RESOURCES_TITLE") end,
    })

    m_tree = nil
    BuildTree(m_caiData)
    m_panel:AddChild(m_tree)

    local sortDD = CreateSortDropdown()
    m_panel:AddChild(sortDD)
    Speak("Pushing panel")
    local orderDD = CreateOrderDropdown()
    m_panel:AddChild(orderDD)

    m_panel:AddInputBinding({
        Key = Keys.VK_ESCAPE,
        Description = "LOC_CAI_KB_CLOSE",
        Action = function()
            Close()
            return true
        end,
    })
    mgr:Push(m_panel, { priority = PopupPriority.Medium })
end

local function PopPanel()
    if mgr and m_panel and mgr:GetWidgetById(PANEL_ID) then
        mgr:RemoveFromStack(PANEL_ID)
    end
    m_panel = nil
    m_tree = nil
    m_sortDropdown = nil
    m_orderDropdown = nil
    m_caiData = nil
end

-- ============================================================================
-- Vanilla wraps
-- ============================================================================
Open = WrapFunc(Open, function(orig)
    m_currentSortIndex = 1
    m_currentOrderIndex = 1
    orig()
    PushPanel()
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
-- Input handler
-- ============================================================================
local function CAIInputHandler(pInputStruct)
    if mgr then
        local panelWasOnStack = m_panel and mgr:GetWidgetById(PANEL_ID)
        if mgr:HandleInput(pInputStruct) then
            if panelWasOnStack and not mgr:GetWidgetById(PANEL_ID) then
                Close()
            end
            return true
        end
    end
    local uiMsg = pInputStruct:GetMessageType()
    if uiMsg == KeyEvents.KeyUp and pInputStruct:GetKey() == Keys.VK_ESCAPE then
        Close()
        return true
    end
    return false
end
ContextPtr:SetInputHandler(CAIInputHandler, true)
