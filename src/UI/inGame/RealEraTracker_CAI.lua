include("caiUtils")
include("Civ6Common")
include("RealEraTracker_CAIBase")

local mgr = CAI:GetUIManager()
local PANEL_ID = "CAIRealEraTracker_Panel"
local TABLE_ID = "CAIRealEraTracker_Table"
local TREE_ID = "CAIRealEraTracker_Tree"
local CATEGORY_TAGS = { "LOC_RET_WORLD", "LOC_HUD_REPORTS_HEADER_CIVILIZATION", "LOC_RET_REPEATABLE" }
local STATUS_TAGS = {
    [0] = "LOC_CAI_RET_NOT_EARNED", [1] = "LOC_CAI_RET_EARNED", [-1] = "LOC_CAI_RET_UNAVAILABLE",
}
local m_ui = {}
local m_keysByMoment = {}
local m_rows = {}
local m_playerID = nil
local m_selectedKey = nil
local m_capturing = false
local m_building = false
local m_sortColumn = nil
local m_sortAscending = false
local m_columns = {}
local m_sortOptions = {}
local m_scoreFilter = 0
local storedView = CAI.GetConfigValue("UI", "RealEraTrackerViewMode", "table")
local m_viewMode = storedView == "tree" and "tree" or "table"
local RefreshViews, SetViewMode

local function Moment(key)
    return m_kMoments[key]
end

local function TracksOthers()
    return tonumber(GlobalParameters.RET_OPTION_INCLUDE_OTHERS) == 1
end

local function Category(key)
    return Locale.Lookup(CATEGORY_TAGS[Moment(key).Category])
end

local function Status(key)
    if Moment(key).EarnedAsWorldFirst then return Locale.Lookup("LOC_CAI_RET_EARNED_WORLD_FIRST") end
    return Locale.Lookup(STATUS_TAGS[Moment(key).Status])
end

local function HistoryRecord(id)
    return Game.GetHistoryManager():GetMomentData(id)
end

local function HistoryLabel(id)
    local record = HistoryRecord(id)
    return Locale.Lookup("LOC_CAI_RET_TURN", record.Turn) .. ": " .. record.InstanceDescription
end

local function HistoryTooltip(key)
    local lines = {}
    for _, id in ipairs(Moment(key).History) do lines[#lines + 1] = HistoryLabel(id) end
    return table.concat(lines, "[NEWLINE]")
end

local function WorldMoment(key)
    local moment = Moment(key)
    return moment.Category == 1 and moment
        or m_kMoments[key .. "_IN_WORLD"] or m_kMoments[key .. "_FIRST_IN_WORLD"]
end

UpdateMomentsData = WrapFunc(UpdateMomentsData, function(orig, ...)
    orig(...)
    for key, moment in pairs(m_kMoments) do
        local ids, seen = {}, {}
        for _, id in ipairs(moment.History) do
            if not seen[id] then ids[#ids + 1] = id; seen[id] = true end
        end
        table.sort(ids, function(a, b)
            local left, right = HistoryRecord(a), HistoryRecord(b)
            if left.Turn ~= right.Turn then return left.Turn > right.Turn end
            return a > b
        end)
        moment.History = ids
        moment.EarnedAsWorldFirst = false
        if moment.Status == -1 and moment.Category == 2 then
            local world = WorldMoment(key)
            if world and world.Status == 1 then
                for _, id in ipairs(ids) do
                    local record = HistoryRecord(id)
                    if record.ActingPlayer == Game.GetLocalPlayer()
                        and GameInfo.Moments[record.Type].MomentType == world.MomentType then
                        moment.EarnedAsWorldFirst = true
                        moment.Status = 1
                        break
                    end
                end
            end
        end
        if #ids > 0 then
            moment.Turn = HistoryRecord(ids[1]).Turn
            moment.Count = #ids
        end
    end
end)

local function Score(key)
    local score = Moment(key).EraScore
    local taj = GameInfo.Buildings.BUILDING_TAJ_MAHAL
    if score >= 2 and taj and Players[Game.GetLocalPlayer()]:GetStats():GetNumBuildingsOfType(taj.Index) > 0 then
        score = score + 1
    end
    return score
end

local function AvailableEras(key)
    local moment = Moment(key)
    if moment.MinEra and moment.MaxEra then
        return Locale.Lookup("LOC_CAI_RET_ERA_RANGE", Locale.Lookup(GameInfo.Eras[moment.MinEra].Name),
            Locale.Lookup(GameInfo.Eras[moment.MaxEra].Name))
    elseif moment.MinEra then
        return Locale.Lookup("LOC_CAI_RET_ERA_FROM", Locale.Lookup(GameInfo.Eras[moment.MinEra].Name))
    elseif moment.MaxEra then
        return Locale.Lookup("LOC_CAI_RET_ERA_UNTIL", Locale.Lookup(GameInfo.Eras[moment.MaxEra].Name))
    end
    return Locale.Lookup("LOC_CAI_RET_ANY_ERA")
end

local function WorldFirst(key)
    local moment = Moment(key)
    local first = WorldMoment(key)
    if first == nil then return "" end -- Some moments have no world-first counterpart.
    if first.Status == 0 then return Locale.Lookup("LOC_CAI_RET_NOT_EARNED") end
    return first.Player ~= "" and first.Player or Locale.Lookup("LOC_MULTIPLAYER_UNKNOWN")
end

local function TableName(key)
    local moment = Moment(key)
    return moment.Favored and (Locale.Lookup("LOC_RET_FAVORED") .. ", " .. moment.Description) or moment.Description
end

local function TreeLabel(key)
    local moment = Moment(key)
    local parts = { moment.Description }
    if moment.Favored then parts[#parts + 1] = Locale.Lookup("LOC_RET_FAVORED") end
    parts[#parts + 1] = Locale.Lookup("LOC_CAI_RET_SCORE", Score(key))
    parts[#parts + 1] = Status(key)
    if moment.Status == 1 then
        parts[#parts + 1] = Locale.Lookup("LOC_CAI_RET_TURN", moment.Turn)
        parts[#parts + 1] = Locale.Lookup("LOC_CAI_RET_TIMES", moment.Count)
    end
    return table.concat(parts, ", ")
end

local function TreeTooltip(key)
    local moment = Moment(key)
    local parts = {}
    if TracksOthers() then
        local first = WorldFirst(key)
        if first ~= "" then parts[#parts + 1] = Locale.Lookup("LOC_CAI_RET_WORLD_FIRST_DETAIL", first) end
    end
    parts[#parts + 1] = moment.LongDesc
    if moment.Object ~= "" then parts[#parts + 1] = Locale.Lookup("LOC_CAI_RET_APPLIES_DETAIL", moment.Object) end
    parts[#parts + 1] = Locale.Lookup("LOC_CAI_RET_ERAS_DETAIL", AvailableEras(key))
    return table.concat(parts, "[NEWLINE]")
end

local function SyncLocalPlayer()
    local playerID = Game.GetLocalPlayer()
    if playerID == nil or playerID < 0 then return false end
    if playerID == m_playerID then return true end
    for _, moment in pairs(m_kMoments) do moment.Favored = false end
    local saved = LoadDataFromPlayerSlot(playerID, "RETFavoredMoments")
    for _, key in ipairs(saved or {}) do
        local moment = m_kMoments[key]
        if moment then moment.Favored = true end -- Saves can refer to removed mod content.
    end
    m_playerID = playerID
    m_selectedKey = nil
    return true
end

local function NaturalLess(a, b)
    local left, right = Moment(a), Moment(b)
    if left.Favored ~= right.Favored then return left.Favored end
    if left.EraScore ~= right.EraScore then return left.EraScore > right.EraScore end
    local comparison = Locale.Compare(left.Description, right.Description)
    if comparison ~= 0 then return comparison < 0 end
    comparison = Locale.Compare(left.Object, right.Object)
    if comparison ~= 0 then return comparison < 0 end
    return a < b
end

local function OrderedRows()
    local ordered = {}
    for _, key in ipairs(m_rows) do ordered[#ordered + 1] = key end
    local column
    for _, candidate in ipairs(m_columns) do
        if candidate.key == m_sortColumn then column = candidate; break end
    end
    if not column then return ordered end
    local decorated = {}
    for index, key in ipairs(ordered) do
        decorated[#decorated + 1] = { key = key, index = index, value = column.sortKey(key) }
    end
    table.sort(decorated, function(a, b)
        if a.value == nil or b.value == nil then
            if a.value == b.value then return a.index < b.index end
            return a.value ~= nil
        end
        local comparison
        if type(a.value) == "number" and type(b.value) == "number" then
            comparison = a.value == b.value and 0 or (a.value < b.value and -1 or 1)
        else
            comparison = Locale.Compare(tostring(a.value), tostring(b.value))
        end
        if comparison == 0 then return a.index < b.index end
        if m_sortAscending then return comparison < 0 end
        return comparison > 0
    end)
    for index, row in ipairs(decorated) do ordered[index] = row.key end
    return ordered
end

local function BuildColumns()
    local function Column(key, tag, getCell, sortKey, ascending, descending, tooltip)
        return {
            key = key, header = function() return Locale.Lookup(tag) end,
            getCell = getCell, sortKey = sortKey, getTooltip = tooltip,
            sortAscendingDescription = ascending or "LOC_CAI_SORT_A_TO_Z",
            sortDescendingDescription = descending or "LOC_CAI_SORT_Z_TO_A",
        }
    end
    local columns = {
        Column("moment", "LOC_CAI_RET_MOMENT", TableName, function(key) return Moment(key).Description end,
            nil, nil, function(key) return Moment(key).LongDesc end),
        Column("category", "LOC_CAI_RET_CATEGORY", Category, Category),
        Column("status", "LOC_HUD_REPORTS_HEADER_STATUS", Status, Status, nil, nil,
            HistoryTooltip),
        Column("score", "LOC_ERA_PROGRESS_ERA_SCORE", function(key) return tostring(Score(key)) end, Score,
            "LOC_CAI_SORT_LOWEST_FIRST", "LOC_CAI_SORT_HIGHEST_FIRST"),
        Column("eras", "LOC_CAI_RET_ERAS", AvailableEras, function(key)
            local moment = Moment(key)
            local first = moment.MinEra and GameInfo.Eras[moment.MinEra].Index or 0
            local last = moment.MaxEra and GameInfo.Eras[moment.MaxEra].Index or (#GameInfo.Eras - 1)
            return first * #GameInfo.Eras + last
        end, "LOC_CAI_RET_EARLIEST_FIRST", "LOC_CAI_RET_LATEST_FIRST"),
        Column("turn", "LOC_CAI_RET_TURN_EARNED", function(key)
            return Moment(key).Status == 1 and tostring(Moment(key).Turn) or ""
        end, function(key) return Moment(key).Status == 1 and Moment(key).Turn or nil end,
            "LOC_CAI_RET_EARLIEST_FIRST", "LOC_CAI_RET_LATEST_FIRST"),
        Column("count", "LOC_CAI_RET_TIMES_EARNED", function(key)
            return tostring(Moment(key).Status == 1 and Moment(key).Count or 0)
        end, function(key) return Moment(key).Status == 1 and Moment(key).Count or 0 end,
            "LOC_CAI_SORT_FEWEST_FIRST", "LOC_CAI_SORT_MOST_FIRST"),
        Column("object", "LOC_UI_PEDIA_APPLIES_TO", function(key) return Moment(key).Object end,
            function(key) return Moment(key).Object ~= "" and Moment(key).Object or nil end),
    }
    if TracksOthers() then
        columns[#columns + 1] = Column("world", "LOC_CAI_RET_WORLD_FIRST", WorldFirst,
            function(key) local first = WorldFirst(key); return first ~= "" and first or nil end)
    end
    return columns
end

local function SyncSortDropdown()
    for index, option in ipairs(m_sortOptions) do
        if option.value.column == m_sortColumn and
            (m_sortColumn == nil or option.value.ascending == m_sortAscending) then
            m_ui.sort:SetSelectedIndex(index, true)
            return
        end
    end
end

local function ToggleFavored(key)
    local moment = Moment(key)
    moment.Favored = not moment.Favored
    m_selectedKey = key
    ViewMomentsPage()
    Speak(Locale.Lookup(moment.Favored and "LOC_CAI_RET_FAVORED_CONFIRM" or "LOC_CAI_RET_UNFAVORED_CONFIRM",
        moment.Description), true)
end

local function RebuildTree()
    local capture = mgr:CaptureFocusKey(m_ui.tree)
    local expanded = {}
    for _, group in ipairs(m_ui.tree.Children) do
        expanded[group.FocusKey] = group.IsExpanded
        for _, moment in ipairs(group.Children) do expanded[moment.FocusKey] = moment.IsExpanded end
    end
    m_ui.tree:ClearChildren()
    local groups = {}
    for _, key in ipairs(OrderedRows()) do
        local category = Moment(key).Category
        groups[category] = groups[category] or {}
        groups[category][#groups[category] + 1] = key
    end
    local categories = { 1, 2, 3 }
    if m_sortColumn == "category" then
        table.sort(categories, function(a, b)
            local comparison = Locale.Compare(Locale.Lookup(CATEGORY_TAGS[a]), Locale.Lookup(CATEGORY_TAGS[b]))
            if m_sortAscending then return comparison < 0 end
            return comparison > 0
        end)
    end
    for _, category in ipairs(categories) do
        if groups[category] then
            local focusKey = "ret:category:" .. category
            local group = mgr:CreateWidget(mgr:GenerateWidgetId("RETCategory"), "TreeItem", {
                Label = function() return Locale.Lookup(CATEGORY_TAGS[category]) end, FocusKey = focusKey,
            })
            for _, key in ipairs(groups[category]) do
                local leaf = mgr:CreateWidget(mgr:GenerateWidgetId("RETMoment"), "TreeItem", {
                    Label = function() return TreeLabel(key) end,
                    Tooltip = function() return TreeTooltip(key) end, FocusKey = "ret:moment:" .. key,
                })
                leaf:On("focus_enter", function() m_selectedKey = key end)
                leaf:On("activate", function() ToggleFavored(key) end)
                if Moment(key).Status == 1 then
                    for _, id in ipairs(Moment(key).History) do
                        local occurrence = mgr:CreateWidget(mgr:GenerateWidgetId("RETHistory"), "TreeItem", {
                            Label = function() return HistoryLabel(id) end,
                            FocusKey = "ret:moment:" .. key .. ":history:" .. id,
                        })
                        occurrence:On("focus_enter", function() m_selectedKey = key end)
                        leaf:AddChild(occurrence)
                    end
                end
                if expanded[leaf.FocusKey] then leaf:Expand(true) end
                group:AddChild(leaf)
            end
            if expanded[focusKey] then group:Expand(true) end
            m_ui.tree:AddChild(group)
        end
    end
    mgr:RestoreFocus(m_ui.tree, capture)
end

local function SyncFilters()
    for _, entry in ipairs(m_ui.checks) do entry.widget:SetChecked(entry.control:IsSelected(), true) end
end

RefreshViews = function()
    if not m_ui.panel or m_building then return end
    m_ui.table:Rebuild()
    RebuildTree()
    SyncFilters()
end

LateInitialize = WrapFunc(LateInitialize, function(orig, ...)
    orig(...)
    m_keysByMoment = {}
    for key, moment in pairs(m_kMoments) do m_keysByMoment[moment] = key end
    m_playerID = nil
    SyncLocalPlayer()
end)

ShowMoment = WrapFunc(ShowMoment, function(orig, moment, instance)
    orig(moment, instance)
    if m_capturing then m_rows[#m_rows + 1] = m_keysByMoment[moment] end
end)

ViewMomentsPage = WrapFunc(ViewMomentsPage, function(orig)
    m_rows = {}
    m_capturing = true
    orig(0) -- The vendored bridge retains upstream filtering, but combines categories.
    m_capturing = false
    table.sort(m_rows, NaturalLess)
    RefreshViews()
end)

SetViewMode = function(mode)
    m_viewMode = mode
    CAI.SetConfigValue("UI", "RealEraTrackerViewMode", mode)
    local view = mode == "table" and m_ui.table or m_ui.tree
    if m_selectedKey then
        local key = mode == "table" and TABLE_ID .. ":row:" .. m_selectedKey or "ret:moment:" .. m_selectedKey
        mgr:PrepareFocus(view, key)
    end
    mgr:SetFocus(view)
    return true
end

local function BuildPanel()
    m_building = true
    m_ui = {}
    m_ui.panel = mgr:CreateWidget(PANEL_ID, "Panel", { Label = function() return Locale.Lookup("LOC_RET_WINDOW_TITLE") end })
    m_ui.panel:AddInputBindings({
        { Key = Keys["1"], IsAlt = true, MSG = KeyEvents.KeyDown, Description = "LOC_CAI_TREE_SWITCH_TO_TABLE",
            Action = function() return SetViewMode("table") end },
        { Key = Keys["2"], IsAlt = true, MSG = KeyEvents.KeyDown, Description = "LOC_CAI_TREE_SWITCH_TO_TREE",
            Action = function() return SetViewMode("tree") end },
        { Key = Keys.VK_ESCAPE, MSG = KeyEvents.KeyUp, Description = "LOC_CAI_KB_CLOSE",
            Action = function() Close(); return true end },
    })
    m_columns = BuildColumns()
    m_ui.table = mgr:CreateWidget(TABLE_ID, "DataTable", {
        HiddenPredicate = function() return m_viewMode ~= "table" end,
    })
    m_ui.table:SetColumns(m_columns)
    m_ui.table:SetRowsProvider(function() return m_rows end)
    m_ui.table:SetRowKeyGetter(function(key) return key end)
    m_ui.table:SetRowLabelGetter(TableName)
    m_ui.table:SetDefaultSort(m_sortColumn and { column = m_sortColumn, ascending = m_sortAscending } or nil)
    m_ui.table:On("row_focus_enter", function(_, key) if key then m_selectedKey = key end end)
    m_ui.table:On("row_activate", function(_, key) ToggleFavored(key) end)
    m_ui.table:On("sort_changed", function(_, column, ascending)
        m_sortColumn, m_sortAscending = column, ascending == true
        SyncSortDropdown()
        RebuildTree()
    end)
    m_ui.panel:AddChild(m_ui.table)
    m_ui.tree = mgr:CreateWidget(TREE_ID, "Tree", { HiddenPredicate = function() return m_viewMode ~= "tree" end })
    m_ui.panel:AddChild(m_ui.tree)
    m_sortOptions = { { label = Locale.Lookup("LOC_CAI_DATATABLE_SORT_NATURAL"), value = { column = nil, ascending = false } } }
    for _, column in ipairs(m_columns) do
        for _, ascending in ipairs({ true, false }) do
            m_sortOptions[#m_sortOptions + 1] = {
                label = column.header() .. "[NEWLINE]" .. Locale.Lookup(ascending and column.sortAscendingDescription or column.sortDescendingDescription),
                value = { column = column.key, ascending = ascending },
            }
        end
    end
    m_ui.sort = mgr:CreateWidget("CAIRET_Sort", "Dropdown", {
        Label = function() return Locale.Lookup("LOC_CAI_REPORTS_SORT_BY") end,
        FocusKey = "ret:sort", HiddenPredicate = function() return m_viewMode ~= "tree" end,
    })
    m_ui.sort:SetOptions(m_sortOptions)
    SyncSortDropdown()
    m_ui.sort:SetValueSetter(function(_, sort)
        m_sortColumn, m_sortAscending = sort.column, sort.ascending
        m_ui.table:SetDefaultSort(sort.column and sort or nil)
        RefreshViews()
    end)
    m_ui.panel:AddChild(m_ui.sort)
    local scoreControls = { Controls.EraScore1Checkbox, Controls.EraScore2Checkbox, Controls.EraScore3Checkbox, Controls.EraScore4Checkbox }
    local scoreOptions = { { label = Locale.Lookup("LOC_CAI_RET_ALL_SCORES"), value = 0 } }
    for index, control in ipairs(scoreControls) do
        scoreOptions[#scoreOptions + 1] = { label = control:GetText(), value = index }
    end
    m_ui.score = mgr:CreateWidget("CAIRET_ScoreFilter", "Dropdown", {
        Label = function() return Locale.Lookup("LOC_CAI_RET_SCORE_FILTER") end, FocusKey = "ret:score-filter",
    })
    m_ui.score:SetOptions(scoreOptions)
    m_ui.score:SetSelectedIndex(m_scoreFilter + 1, true)
    m_ui.score:SetValueSetter(function(_, value)
        m_scoreFilter = value
        for index, control in ipairs(scoreControls) do control:SetSelected(value == 0 or value == index) end
        ViewMomentsPage()
    end)
    m_ui.panel:AddChild(m_ui.score)
    m_ui.checks = {}
    for _, def in ipairs({
        { control = Controls.HideNotActiveCheckbox, tag = "LOC_RET_CHECKBOX_HIDE_NOT_ACTIVE", callback = OnToggleHideNotActiveCheckbox },
        { control = Controls.ShowOnlyEarnedCheckbox, tag = "LOC_RET_CHECKBOX_SHOW_ONLY_EARNED", callback = OnToggleShowOnlyEarnedCheckbox },
        { control = Controls.HideNotAvailableCheckbox, tag = "LOC_RET_CHECKBOX_HIDE_NOT_AVAILABLE", callback = OnToggleHideNotAvailableCheckbox },
    }) do
        local check = mgr:CreateWidget(mgr:GenerateWidgetId("RETFilter"), "Checkbox", {
            Label = function() return def.control:GetText() end, FocusKey = "ret:filter:" .. def.tag,
        })
        check:SetValueSetter(function(_, value)
            if def.control:IsSelected() ~= value then def.callback() end
        end)
        m_ui.checks[#m_ui.checks + 1] = { widget = check, control = def.control }
        m_ui.panel:AddChild(check)
    end
    local switch = mgr:CreateWidget("CAIRET_SwitchView", "Button", {
        Label = function() return Locale.Lookup(m_viewMode == "table" and "LOC_CAI_TREE_SWITCH_TO_TREE" or "LOC_CAI_TREE_SWITCH_TO_TABLE") end,
    })
    switch:On("activate", function() SetViewMode(m_viewMode == "table" and "tree" or "table") end)
    m_ui.panel:AddChild(switch)
    m_building = false
    RefreshViews()
end

Open = WrapFunc(Open, function(orig, ...)
    if not SyncLocalPlayer() then
        Speak(Locale.Lookup("LOC_CAI_UI_UNAVAILABLE_WHILE_OBSERVING"))
        return
    end
    orig(...)
    ViewMomentsPage() -- Original Open updates its Taj Mahal flag after its first render.
    if not IsCAIActive() or m_ui.panel then return end
    BuildPanel()
    mgr:Push(m_ui.panel, { priority = PopupPriority.Medium })
end)

Close = WrapFunc(Close, function(orig, ...)
    orig(...)
    if m_ui.panel then
        mgr:RemoveFromStack(PANEL_ID)
        m_ui = {}
    end
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, input)
    if IsCAIActive() and m_ui.panel and mgr:GetTop() == m_ui.panel and mgr:HandleInput(input) then return true end
    return orig(input)
end)

CAI.RealEraTracker = {
    GetFavoredLines = function(playerID)
        if playerID ~= Game.GetLocalPlayer() or not SyncLocalPlayer() then
            LogWarn("Real Era Tracker cannot read favorites without the current local player")
            return {}
        end
        UpdateMomentsData()
        local keys, lines = {}, {}
        for key, moment in pairs(m_kMoments) do
            if moment.Favored then keys[#keys + 1] = key end
        end
        table.sort(keys, NaturalLess)
        for _, key in ipairs(keys) do
            local moment = Moment(key)
            lines[#lines + 1] = moment.Description .. ", " .. moment.LongDesc
        end
        return lines
    end,
}

local function RegisterLaunchAction()
    if not (IsExpansion1Active() or IsExpansion2Active()) then return end
    LuaEvents.CAILaunchBar_RegisterAction({
        id = "real_era_tracker", title = "LOC_RET_BUTTON_LABEL", desc = "LOC_CAI_RET_LAUNCH_TOOLTIP",
        reason = function()
            local playerID = Game.GetLocalPlayer()
            if playerID == nil or playerID < 0 then return Locale.Lookup("LOC_CAI_UI_UNAVAILABLE_WHILE_OBSERVING") end
        end,
        open = function() LuaEvents.ReportsList_OpenEraTracker() end,
    })
end

LuaEvents.CAILaunchBar_RequestRegistrations.Add(RegisterLaunchAction)
RegisterLaunchAction()
ContextPtr:SetInputHandler(OnInputHandler, true)
