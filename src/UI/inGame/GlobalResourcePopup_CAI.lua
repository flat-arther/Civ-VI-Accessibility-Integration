include("caiUtils")
include("Civ6Common")
if GameConfiguration.GetValue("GAMEMODE_MONOPOLIES") then
    include("GlobalResourcePopup_KublaiKhanVietnam_MODE")
else
    include("GlobalResourcePopup")
end

local mgr = ExposedMembers.CAI_UIManager

-- ============================================================================
-- Constants
-- ============================================================================
local PANEL_ID            = "CAIGlobalRes_Panel"
local TABLE_ID            = "CAIGlobalRes_Table"
local TREE_SORT_ID        = "CAIGlobalRes_TreeSort"
local TREE_ID             = "CAIGlobalRes_Tree"
local SWITCH_VIEW_ID      = "CAIGlobalRes_SwitchView"
local VIEW_SETTING_SECTION = "UI"
local VIEW_SETTING_ID      = "GlobalResourcePopupViewMode"
local HOVER_SOUND         = "Main_Menu_Mouse_Over"

local RESOURCE_CLASS_LABELS = {
    RESOURCECLASS_STRATEGIC = "LOC_RESOURCECLASS_STRATEGIC_NAME",
    RESOURCECLASS_LUXURY    = "LOC_RESOURCECLASS_LUXURY_NAME",
}

-- ============================================================================
-- State
-- ============================================================================
local m_panel             = nil
local m_table             = nil
local m_treeSort          = nil
local m_tree              = nil
local m_switchView        = nil
local m_caiData           = nil
local m_visibleResources  = {}
local m_playerIDs         = {}
local m_tableColumns      = {}
local m_treeSortOptions   = {}
local m_tableSortColumn   = "resource"
local m_tableSortAscending = true
local m_treeSortColumn    = "resource"
local m_treeSortAscending = true
local m_focusedResourceType = nil
local m_isDLCMonopoly     = false

local function LoadViewModeSetting()
    local stored = tostring(CAI.GetConfigValue(
        VIEW_SETTING_SECTION, VIEW_SETTING_ID, "table")):lower()
    if stored == "tree" then return "tree" end
    if stored ~= "table" then
        LogWarn("Global Resources ignored invalid saved view mode " .. tostring(stored))
    end
    return "table"
end

local function SaveViewModeSetting(viewMode)
    if not CAI.SetConfigValue(VIEW_SETTING_SECTION, VIEW_SETTING_ID, viewMode) then
        LogError("Global Resources failed to save view mode " .. tostring(viewMode))
    end
end

local m_viewMode = LoadViewModeSetting()

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

local function GetResourceClassLabel(resourceClassType)
    local labelTag = RESOURCE_CLASS_LABELS[resourceClassType]
    return labelTag and Locale.Lookup(labelTag) or tostring(resourceClassType or "")
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
    return info and info.Index or nil
end

local function GetOwnerEntry(kResourceData, playerID)
    for _, kPlayerEntry in ipairs(kResourceData.kOwnerList) do
        if kPlayerEntry.playerID == playerID then return kPlayerEntry end
    end
    return nil
end

local function GetPlayerAmount(kResourceData, playerID)
    local kPlayerEntry = GetOwnerEntry(kResourceData, playerID)
    return kPlayerEntry and kPlayerEntry.amount or 0
end

local function GetMonopolyDetails(kPlayerEntry, kResourceData)
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
                    return amount .. "/" .. totalOnMap
                        .. ", " .. Locale.Lookup("LOC_RESREPORT_MONOPOLY_NAME")
                end
                local percent = amount / totalOnMap
                return amount .. "/" .. totalOnMap
                    .. ", " .. Locale.ToPercent(percent) .. " " .. Locale.Lookup("LOC_RESREPORT_CONTROL")
            end
        end
    end

    return ""
end

local function GetCivLabel(kPlayerEntry, kResourceData)
    local details = GetMonopolyDetails(kPlayerEntry, kResourceData)
    return GetLeaderDisplayName(kPlayerEntry.playerID) .. ": "
        .. (details ~= "" and details or tostring(kPlayerEntry.amount))
end

local function BuildVisibleData(kData)
    m_visibleResources = {}
    for _, kResourceData in ipairs(kData) do
        if kResourceData.isPossessed and kResourceData.kOwnerList and #kResourceData.kOwnerList > 0
            and (kResourceData.class == "RESOURCECLASS_STRATEGIC"
                or kResourceData.class == "RESOURCECLASS_LUXURY") then
            m_visibleResources[#m_visibleResources + 1] = kResourceData
        end
    end

    m_playerIDs = {}
    local localPlayerID = Game.GetLocalPlayer()
    local pDiplomacy = Players[localPlayerID]:GetDiplomacy()
    for _, playerID in ipairs(PlayerManager.GetAliveIDs()) do
        local pPlayer = Players[playerID]
        if ShouldPlayerBeAdded(pPlayer)
            and (playerID == localPlayerID or pDiplomacy:HasMet(playerID)) then
            m_playerIDs[#m_playerIDs + 1] = playerID
        end
    end
    table.sort(m_playerIDs, function(a, b)
        if a == localPlayerID then return true end
        if b == localPlayerID then return false end
        local comparison = Locale.Compare(GetLeaderDisplayName(a), GetLeaderDisplayName(b))
        if comparison == 0 then return a < b end
        return comparison < 0
    end)
end

local function BuildTableColumns()
    local columns = {
        {
            key = "resource",
            header = function() return Locale.Lookup("LOC_CAI_GLOBAL_RES_RESOURCE_COLUMN") end,
            getCell = function(kResourceData) return Locale.Lookup(kResourceData.name) end,
            sortKey = function(kResourceData) return Locale.Lookup(kResourceData.name) end,
            sortAscendingDescription = "LOC_CAI_SORT_A_TO_Z",
            sortDescendingDescription = "LOC_CAI_SORT_Z_TO_A",
        },
        {
            key = "class",
            header = function() return Locale.Lookup("LOC_CAI_GLOBAL_RES_CLASS_COLUMN") end,
            getCell = function(kResourceData) return GetResourceClassLabel(kResourceData.class) end,
            sortKey = function(kResourceData) return GetResourceClassLabel(kResourceData.class) end,
            sortAscendingDescription = "LOC_CAI_SORT_A_TO_Z",
            sortDescendingDescription = "LOC_CAI_SORT_Z_TO_A",
        },
        {
            key = "amount",
            header = function() return Locale.Lookup("LOC_CAI_GLOBAL_RES_TOTAL_AMOUNT") end,
            getCell = function(kResourceData) return tostring(kResourceData.total or 0) end,
            sortKey = function(kResourceData) return kResourceData.total or 0 end,
            sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST",
        },
    }

    for _, playerID in ipairs(m_playerIDs) do
        local capturedPlayerID = playerID
        columns[#columns + 1] = {
            key = "player:" .. tostring(capturedPlayerID),
            header = function() return GetLeaderDisplayName(capturedPlayerID) end,
            getCell = function(kResourceData)
                return tostring(GetPlayerAmount(kResourceData, capturedPlayerID))
            end,
            getTooltip = function(kResourceData)
                local kPlayerEntry = GetOwnerEntry(kResourceData, capturedPlayerID)
                return kPlayerEntry and GetMonopolyDetails(kPlayerEntry, kResourceData) or ""
            end,
            sortKey = function(kResourceData)
                return GetPlayerAmount(kResourceData, capturedPlayerID)
            end,
            sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST",
            PlayerID = capturedPlayerID,
        }
    end
    return columns
end

local function CompareSortValues(a, b)
    if a == b then return 0 end
    if a == nil then return 1 end
    if b == nil then return -1 end
    if type(a) == "number" and type(b) == "number" then return a < b and -1 or 1 end
    return Locale.Compare(tostring(a), tostring(b))
end

local function GetColumn(columnKey)
    for _, column in ipairs(m_tableColumns) do
        if column.key == columnKey then return column end
    end
    return nil
end

local function GetOrderedTreeResources()
    local ordered = {}
    for _, kResourceData in ipairs(m_visibleResources) do ordered[#ordered + 1] = kResourceData end
    local column = GetColumn(m_treeSortColumn)
    if not column or not column.sortKey then return ordered end

    local decorated = {}
    for naturalIndex, kResourceData in ipairs(ordered) do
        decorated[#decorated + 1] = {
            resource = kResourceData,
            naturalIndex = naturalIndex,
            value = column.sortKey(kResourceData),
        }
    end
    table.sort(decorated, function(a, b)
        local comparison = CompareSortValues(a.value, b.value)
        if comparison == 0 then return a.naturalIndex < b.naturalIndex end
        if m_treeSortAscending then return comparison < 0 end
        return comparison > 0
    end)

    ordered = {}
    for _, entry in ipairs(decorated) do ordered[#ordered + 1] = entry.resource end
    return ordered
end

-- ============================================================================
-- Tree building and sorting
-- ============================================================================
local function BuildTree()
    if not m_tree then return end
    local capture = mgr:CaptureFocusKey(m_tree)
    m_tree:ClearChildren()

    local strategic = {}
    local luxury = {}
    for _, kResourceData in ipairs(GetOrderedTreeResources()) do
        if kResourceData.class == "RESOURCECLASS_STRATEGIC" then
            strategic[#strategic + 1] = kResourceData
        elseif kResourceData.class == "RESOURCECLASS_LUXURY" then
            luxury[#luxury + 1] = kResourceData
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
                resItem:On("focus_enter", function()
                    m_focusedResourceType = capturedRes.type
                end)
                groupItem:AddChild(resItem)

                for _, kPlayerEntry in ipairs(capturedRes.kOwnerList) do
                    local capturedPlayer = kPlayerEntry
                    if capturedPlayer.isMet or capturedPlayer.isSelf then
                        local leaf = AddLeaf(resItem,
                            "res:" .. capturedRes.type .. ":civ:" .. capturedPlayer.playerID,
                            function() return GetCivLabel(capturedPlayer, capturedRes) end)
                        leaf:On("focus_enter", function()
                            m_focusedResourceType = capturedRes.type
                        end)
                        leaf:On("activate", function()
                            OnLeaderClicked(capturedPlayer.playerID)
                        end)
                    end
                end
            end
        end
    end

    mgr:RestoreFocus(m_tree, capture)
end

local function BuildTreeSortOptions()
    local options = {
        {
            label = Locale.Lookup("LOC_CAI_DATATABLE_SORT_NATURAL"),
            value = { column = nil, ascending = false },
        },
    }

    local sortableColumns = { m_tableColumns[1], m_tableColumns[3] }
    for index = 4, #m_tableColumns do sortableColumns[#sortableColumns + 1] = m_tableColumns[index] end
    for _, column in ipairs(sortableColumns) do
        local label = column.sortLabel or column.header
        local header = type(label) == "function" and label() or label or ""
        options[#options + 1] = {
            label = header .. ", " .. Locale.Lookup(column.sortAscendingDescription),
            value = { column = column.key, ascending = true },
        }
        options[#options + 1] = {
            label = header .. ", " .. Locale.Lookup(column.sortDescendingDescription),
            value = { column = column.key, ascending = false },
        }
    end
    return options
end

local function SyncTreeSortDropdown()
    if not m_treeSort then return end
    for index, option in ipairs(m_treeSortOptions) do
        local sort = option.value
        if sort.column == m_treeSortColumn
            and (sort.column == nil or sort.ascending == m_treeSortAscending) then
            m_treeSort:SetSelectedIndex(index, true)
            return
        end
    end
end

-- ============================================================================
-- Panel lifecycle
-- ============================================================================
local function GetTableResourceFocusKey(resourceType)
    return TABLE_ID .. ":row:" .. tostring(resourceType) .. ":resource"
end

local function GetActiveView()
    return m_viewMode == "tree" and m_tree or m_table
end

local function SetViewMode(viewMode)
    if viewMode ~= "table" and viewMode ~= "tree" then
        LogError("Global Resources received invalid view mode " .. tostring(viewMode))
        return false
    end
    if m_viewMode ~= viewMode then
        m_viewMode = viewMode
        SaveViewModeSetting(viewMode)
    end

    local activeView = GetActiveView()
    if not activeView then return false end
    if m_focusedResourceType then
        mgr:PrepareFocus(activeView, viewMode == "tree"
            and "res:" .. m_focusedResourceType
            or GetTableResourceFocusKey(m_focusedResourceType))
    end
    mgr:SetFocus(activeView)
    return true
end

local function ActivateFocusedTablePlayer()
    if not m_table then return false end
    local column = m_table:GetFocusedColumn()
    if not column or column.PlayerID == nil then return false end
    OnLeaderClicked(column.PlayerID)
    return true
end

local function BuildPanel()
    m_panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function() return Locale.Lookup("LOC_GLOBAL_RESOURCES_TITLE") end,
    })
    m_panel:AddInputBindings({
        {
            Key = Keys["1"],
            IsAlt = true,
            MSG = KeyEvents.KeyDown,
            Description = "LOC_CAI_TREE_SWITCH_TO_TABLE",
            Action = function() return SetViewMode("table") end,
        },
        {
            Key = Keys["2"],
            IsAlt = true,
            MSG = KeyEvents.KeyDown,
            Description = "LOC_CAI_TREE_SWITCH_TO_TREE",
            Action = function() return SetViewMode("tree") end,
        },
        {
            Key = Keys.VK_ESCAPE,
            Description = "LOC_CAI_KB_CLOSE",
            Action = function()
                Close()
                return true
            end,
        },
    })

    m_tableColumns = BuildTableColumns()
    m_treeSortOptions = BuildTreeSortOptions()

    m_table = mgr:CreateWidget(TABLE_ID, "DataTable", {
        Label = function() return Locale.Lookup("LOC_GLOBAL_RESOURCES_TITLE") end,
        HiddenPredicate = function() return m_viewMode ~= "table" end,
    })
    m_table:SetColumns(m_tableColumns)
    m_table:SetRowsProvider(function() return m_visibleResources end)
    m_table:SetRowKeyGetter(function(kResourceData) return kResourceData.type end)
    m_table:SetRowLabelGetter(function(kResourceData) return Locale.Lookup(kResourceData.name) end)
    m_table:SetDefaultSort({ column = m_tableSortColumn, ascending = m_tableSortAscending })
    m_table:On("row_focus_enter", function(_, kResourceData, rowIndex)
        if rowIndex > 0 then m_focusedResourceType = kResourceData.type end
    end)
    m_table:On("sort_changed", function(_, columnKey, ascending)
        m_tableSortColumn = columnKey
        m_tableSortAscending = ascending == true
        if columnKey == nil or columnKey == "resource" or columnKey == "amount"
            or string.find(columnKey, "player:", 1, true) == 1 then
            m_treeSortColumn = columnKey
            m_treeSortAscending = ascending == true
            SyncTreeSortDropdown()
            BuildTree()
        end
    end)
    m_table:AddInputBindings({
        {
            Key = Keys.VK_RETURN,
            MSG = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_ACTIVATE",
            Action = ActivateFocusedTablePlayer,
        },
        {
            Key = Keys.VK_SPACE,
            Description = "LOC_CAI_KB_ACTIVATE",
            Action = ActivateFocusedTablePlayer,
        },
    })
    m_table:Rebuild()
    m_panel:AddChild(m_table)

    m_treeSort = mgr:CreateWidget(TREE_SORT_ID, "Dropdown", {
        Label = function() return Locale.Lookup("LOC_CAI_GLOBAL_RES_ORDER_BY") end,
        FocusKey = "global-resources:tree-sort",
        HiddenPredicate = function() return m_viewMode ~= "tree" end,
    })
    m_treeSort:SetOptions(m_treeSortOptions)
    SyncTreeSortDropdown()
    m_treeSort:On("value_changed", function(_, sort)
        m_treeSortColumn = sort.column
        m_treeSortAscending = sort.ascending == true
        m_tableSortColumn = sort.column
        m_tableSortAscending = sort.ascending == true
        m_table:SetDefaultSort(sort.column
            and { column = sort.column, ascending = sort.ascending }
            or nil)
        m_table:Rebuild()
        BuildTree()
    end)
    m_panel:AddChild(m_treeSort)

    m_tree = mgr:CreateWidget(TREE_ID, "Tree", {
        Label = function() return Locale.Lookup("LOC_GLOBAL_RESOURCES_TITLE") end,
        HiddenPredicate = function() return m_viewMode ~= "tree" end,
    })
    m_panel:AddChild(m_tree)
    BuildTree()

    m_switchView = mgr:CreateWidget(SWITCH_VIEW_ID, "Button", {
        Label = function()
            return Locale.Lookup(m_viewMode == "table"
                and "LOC_CAI_TREE_SWITCH_TO_TREE"
                or "LOC_CAI_TREE_SWITCH_TO_TABLE")
        end,
    })
    m_switchView:On("activate", function()
        return SetViewMode(m_viewMode == "table" and "tree" or "table")
    end)
    m_panel:AddChild(m_switchView)
end

local function PushPanel()
    CheckDLCMonopoly()
    m_caiData = PopulateData()
    if not m_caiData then return end

    m_tableSortColumn = "resource"
    m_tableSortAscending = true
    m_treeSortColumn = "resource"
    m_treeSortAscending = true
    m_focusedResourceType = nil
    BuildVisibleData(m_caiData)
    BuildPanel()
    mgr:Push(m_panel, { priority = PopupPriority.Medium, focus = GetActiveView() })
end

local function PopPanel()
    if mgr and m_panel and mgr:GetWidgetById(PANEL_ID) then
        mgr:RemoveFromStack(PANEL_ID)
    end
    m_panel = nil
    m_table = nil
    m_treeSort = nil
    m_tree = nil
    m_switchView = nil
    m_caiData = nil
    m_visibleResources = {}
    m_playerIDs = {}
    m_tableColumns = {}
    m_treeSortOptions = {}
end

-- ============================================================================
-- Vanilla wraps
-- ============================================================================
Open = WrapFunc(Open, function(orig)
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
