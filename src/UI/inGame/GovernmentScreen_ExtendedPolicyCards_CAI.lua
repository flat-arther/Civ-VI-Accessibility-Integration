-- ===========================================================================
-- GovernmentScreen accessibility variant for the Extended Policy Cards mod
-- (Aristos). Pulled by include() from GovernmentScreen_CAI.lua only when the mod
-- is active, so it is registered under <ImportFiles> in CivViAccess.modinfo the
-- same way as the Better Report / Better Trade variant files.
--
-- Extended Policy Cards shows each policy card's computed gameplay effect (via
-- Better Report Screen's ExposedMembers.RMA). CAI wins the GovernmentScreen
-- context and re-surfaces that effect itself; this file replaces the plain policy
-- picker/viewer tree with a table+tree panel so the effect reads as its own
-- Impact column and the browsing experience matches the reports policy tab.
--
-- The host screen hands us a context table (see BuildPickerContext in
-- GovernmentScreen_CAI.lua) rather than exposing its locals, because Civ VI Lua
-- does not share included locals. We expose a single global builder table.
-- ===========================================================================

local mgr = ExposedMembers.CAI_UIManager

local VIEW_SETTING_ID = "GovPolicyPickerViewMode"

local function LoadViewMode()
    local stored = tostring(CAI.GetConfigValue("UI", VIEW_SETTING_ID, "table")):lower()
    return stored == "tree" and "tree" or "table"
end

-- ---------------------------------------------------------------------------
-- Shared column definitions: Name, Slot, Impact. No status column -- every
-- policy shown on the Government screen is available/active, unlike the reports
-- policy tab, so status would be noise. Impact is free-form effect text from RMA
-- and has no meaningful order, so only Name and Slot are sortable.
-- ---------------------------------------------------------------------------
local function BuildColumns(ctx)
    return {
        {
            key = "name",
            header = function() return Locale.Lookup("LOC_CAI_REPORTS_SORT_NAME") end,
            getCell = function(pt)
                local name = ctx.GetPolicyName(pt)
                if ctx.IsNewThisTurn(pt) then
                    return name .. ", " .. Locale.Lookup("LOC_CAI_GOVERNMENT_NEW_POLICY")
                end
                return name
            end,
            -- Impact has its own column here, so keep it out of the row tooltip.
            getTooltip = function(pt) return ctx.GetPolicyTooltipBody(pt) end,
            sortKey = function(pt) return ctx.GetPolicyName(pt) end,
            sortAscendingDescription = "LOC_CAI_SORT_A_TO_Z",
            sortDescendingDescription = "LOC_CAI_SORT_Z_TO_A",
        },
        {
            key = "slot",
            header = function() return Locale.Lookup("LOC_CAI_GOVERNMENT_POLICY_SLOT_HEADER") end,
            getCell = function(pt) return ctx.GetPolicySlotLabel(pt) end,
            sortKey = function(pt) return ctx.GetPolicySlotLabel(pt) end,
            sortAscendingDescription = "LOC_CAI_SORT_A_TO_Z",
            sortDescendingDescription = "LOC_CAI_SORT_Z_TO_A",
        },
        {
            key = "impact",
            header = function() return Locale.Lookup("LOC_CAI_REPORTS_COL_IMPACT") end,
            getCell = function(pt) return ctx.GetPolicyEffect(pt) end,
            sortKey = function(pt) return ctx.GetPolicyImpactTotal(pt) end,
            sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST",
        },
    }
end

-- Sort dropdown offers only the sortable columns whose order the tree does not
-- already imply. The tree groups by slot, so "sort by slot" is dropped, leaving
-- Name ascending/descending.
local function BuildSortOptions(columns)
    local options = {}
    for _, column in ipairs(columns) do
        if column.sortKey and column.key ~= "slot" then
            local header = column.header()
            options[#options + 1] = {
                label = header .. ", " .. Locale.Lookup(column.sortAscendingDescription),
                value = { column = column.key, ascending = true },
            }
            options[#options + 1] = {
                label = header .. ", " .. Locale.Lookup(column.sortDescendingDescription),
                value = { column = column.key, ascending = false },
            }
        end
    end
    return options
end

-- ---------------------------------------------------------------------------
-- Panel builder shared by the slot picker and the read-only viewer.
--   opts.id        stack id (ctx.PICKER_ID or ctx.ALL_POLICIES_ID)
--   opts.title     localized panel label getter
--   opts.rowIndex  slot row to fill; nil means "all policies" (viewer)
--   opts.action    fn(policyType) run on activate; nil means read-only
--   opts.close     fn() that tears this panel down (host owns m_ui tracking)
--   opts.emptyLoc  localization tag when no policy qualifies
-- ---------------------------------------------------------------------------
local function BuildPanel(ctx, opts)
    local columns = BuildColumns(ctx)
    local viewMode = LoadViewMode()
    local sort = { column = "name", ascending = true }

    local panel = mgr:CreateWidget(opts.id, "Panel", { Label = opts.title })

    -- Live list of policy types this panel shows, ordered by the shared sort.
    local function GetRows()
        local rows = {}
        for _, pt in ipairs(ctx.GetAllPolicyTypes()) do
            if not opts.rowIndex or ctx.IsAssignableToRow(pt, opts.rowIndex) then
                rows[#rows + 1] = pt
            end
        end
        return rows
    end

    local function FindColumn(key)
        for _, column in ipairs(columns) do
            if column.key == key then return column end
        end
        return columns[1]
    end

    -- Category (slot) index for a policy, used to group tree items.
    local function CategoryIndex(pt)
        local data = ctx.GetPolicyData(pt)
        return data and ctx.GetRowIndexForSlotType(data.SlotType) or nil
    end

    local function OpenCivilopedia(pt)
        if IsTutorialRunning and IsTutorialRunning() then return true end
        LuaEvents.OpenCivilopedia(pt)
        return true
    end

    -- --- Table view ---------------------------------------------------------
    -- Named dataTable, not table, to avoid shadowing Lua's table library.
    local dataTable = mgr:CreateWidget(opts.id .. "_Table", "DataTable", {
        Label = opts.title,
        HiddenPredicate = function() return viewMode ~= "table" end,
    })
    dataTable:SetColumns(columns)
    dataTable:SetRowsProvider(GetRows)
    dataTable:SetRowKeyGetter(function(pt) return tostring(pt) end)
    dataTable:SetRowLabelGetter(function(pt) return ctx.GetPolicyName(pt) end)
    dataTable:SetDefaultSort({ column = sort.column, ascending = sort.ascending })
    dataTable:On("sort_changed", function(_, columnKey, ascending)
        sort = { column = columnKey or "name", ascending = ascending == true }
    end)
    if opts.action then
        dataTable:On("row_activate", function(_, pt) opts.action(pt) end)
    end
    dataTable:AddInputBindings({
        {
            Key = Keys.VK_RETURN, IsShift = true, MSG = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_OPEN_CIVILOPEDIA",
            Action = function()
                local pt = dataTable:GetFocusedRow()
                if pt then return OpenCivilopedia(pt) end
                return true
            end,
        },
    })
    dataTable:Rebuild()
    panel:AddChild(dataTable)

    -- --- Tree view ----------------------------------------------------------
    local tree = mgr:CreateWidget(opts.id .. "_Tree", "Tree", {
        Label = opts.title,
        HiddenPredicate = function() return viewMode ~= "tree" end,
    })

    local function AddLeaf(parent, pt)
        local leaf = mgr:CreateWidget(mgr:GenerateWidgetId("CAIGovEPCPolicy"), "TreeItem", {
            Label = function()
                local name = ctx.GetPolicyName(pt)
                if ctx.IsNewThisTurn(pt) then
                    return name .. ", " .. Locale.Lookup("LOC_CAI_GOVERNMENT_NEW_POLICY")
                end
                return name
            end,
            Tooltip = function() return ctx.GetPolicyTooltip(pt) end,
            FocusKey = "epcpol:" .. tostring(pt),
        })
        leaf:SetFocusSound("Main_Menu_Mouse_Over")
        if opts.action then
            leaf:On("activate", function(w)
                if w:IsDisabled() then return end
                opts.action(pt)
            end)
        end
        leaf:AddInputBindings({
            {
                Key = Keys.VK_RETURN, IsShift = true, MSG = KeyEvents.KeyUp,
                Description = "LOC_CAI_KB_OPEN_CIVILOPEDIA",
                Action = function() return OpenCivilopedia(pt) end,
            },
        })
        parent:AddChild(leaf)
    end

    local function RebuildTree()
        local capture = mgr:CaptureFocusKey(tree)
        tree:ClearChildren()

        local column = FindColumn(sort.column)
        local ascending = sort.ascending
        local function SortPolicies(list)
            table.sort(list, function(a, b)
                local av, bv = column.sortKey(a), column.sortKey(b)
                if av == bv then return Locale.Compare(ctx.GetPolicyName(a), ctx.GetPolicyName(b)) < 0 end
                if type(av) == "string" then
                    local cmp = Locale.Compare(av, bv)
                    if ascending then return cmp < 0 else return cmp > 0 end
                end
                if ascending then return av < bv else return av > bv end
            end)
        end

        local rows = GetRows()
        local anyShown = false
        for _, row in ipairs(ctx.CAI_ROW_ORDER) do
            if not opts.rowIndex or row.Index == opts.rowIndex then
                local inCategory = {}
                for _, pt in ipairs(rows) do
                    if CategoryIndex(pt) == row.Index then inCategory[#inCategory + 1] = pt end
                end
                SortPolicies(inCategory)

                local category = mgr:CreateWidget(mgr:GenerateWidgetId("CAIGovEPCCategory"), "TreeItem", {
                    Label = function() return ctx.GetRowName(row.Index) end,
                    FocusKey = "epccat:" .. tostring(row.Index),
                })
                for _, pt in ipairs(inCategory) do
                    AddLeaf(category, pt)
                    anyShown = true
                end
                if #inCategory == 0 then
                    category:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAIGovEPCStatic"), "TreeItem", {
                        Label = function() return Locale.Lookup("LOC_CAI_GOVERNMENT_NO_AVAILABLE_POLICIES") end,
                    }))
                end
                tree:AddChild(category)
                category:Expand(true)
            end
        end

        if not anyShown and opts.emptyLoc then
            tree:ClearChildren()
            tree:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAIGovEPCStatic"), "StaticText", {
                Label = function() return Locale.Lookup(opts.emptyLoc) end,
            }))
        end

        mgr:RestoreFocus(tree, capture)
    end

    RebuildTree()
    panel:AddChild(tree)

    -- --- Sort dropdown (tree only) -----------------------------------------
    local sortDropdown = mgr:CreateWidget(opts.id .. "_Sort", "Dropdown", {
        Label = function() return Locale.Lookup("LOC_CAI_REPORTS_SORT_BY") end,
        FocusKey = "epc:sort",
        HiddenPredicate = function() return viewMode ~= "tree" end,
    })
    local sortOptions = BuildSortOptions(columns)
    sortDropdown:SetOptions(sortOptions)
    for i, opt in ipairs(sortOptions) do
        if opt.value.column == sort.column and opt.value.ascending == sort.ascending then
            sortDropdown:SetSelectedIndex(i, true)
            break
        end
    end
    sortDropdown:On("value_changed", function(_, value)
        sort = { column = value.column, ascending = value.ascending }
        dataTable:SetDefaultSort({ column = value.column, ascending = value.ascending })
        RebuildTree()
    end)
    panel:AddChild(sortDropdown)

    -- --- View switch --------------------------------------------------------
    local function SetViewMode(mode)
        if mode ~= "tree" and mode ~= "table" then return false end
        if viewMode ~= mode then
            viewMode = mode
            CAI.SetConfigValue("UI", VIEW_SETTING_ID, mode)
        end
        mgr:SetFocus(mode == "table" and dataTable or tree)
        return true
    end

    local switchButton = mgr:CreateWidget(opts.id .. "_Switch", "Button", {
        Label = function()
            return Locale.Lookup(viewMode == "tree"
                and "LOC_CAI_TREE_SWITCH_TO_TABLE" or "LOC_CAI_TREE_SWITCH_TO_TREE")
        end,
        FocusKey = "epc:switch-view",
    })
    switchButton:On("activate", function()
        return SetViewMode(viewMode == "tree" and "table" or "tree")
    end)
    panel:AddChild(switchButton)

    panel:AddInputBindings({
        {
            Key = Keys.VK_ESCAPE, MSG = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_CLOSE",
            Action = function()
                opts.close()
                return true
            end,
        },
        {
            Key = Keys["1"], IsAlt = true, MSG = KeyEvents.KeyDown,
            Description = "LOC_CAI_TREE_SWITCH_TO_TABLE",
            Action = function() return SetViewMode("table") end,
        },
        {
            Key = Keys["2"], IsAlt = true, MSG = KeyEvents.KeyDown,
            Description = "LOC_CAI_TREE_SWITCH_TO_TREE",
            Action = function() return SetViewMode("tree") end,
        },
    })

    return panel
end

-- ===========================================================================
-- Public builder table consumed by GovernmentScreen_CAI.lua.
-- ===========================================================================
CAIGovPolicyPickerEPC = {}

-- Actionable picker for one policy slot: rows are the policies legal in rowIndex,
-- activation assigns and closes.
function CAIGovPolicyPickerEPC.BuildSlotPicker(ctx, slotIndex, rowIndex)
    return BuildPanel(ctx, {
        id       = ctx.PICKER_ID,
        title    = function() return Locale.Lookup("LOC_CAI_GOVERNMENT_CHOOSE_POLICY", ctx.GetRowName(rowIndex)) end,
        rowIndex = rowIndex,
        emptyLoc = "LOC_CAI_GOVERNMENT_NO_AVAILABLE_POLICIES",
        close    = function() ctx.ClosePicker(true) end,
        action   = function(pt)
            if ctx.AssignPolicyToSlot(slotIndex, rowIndex, pt) then
                ctx.ClosePicker(true)
            end
        end,
    })
end

-- Read-only viewer for every available policy, grouped by slot category.
function CAIGovPolicyPickerEPC.BuildAllPolicies(ctx)
    return BuildPanel(ctx, {
        id       = ctx.ALL_POLICIES_ID,
        title    = function() return Locale.Lookup("LOC_CAI_GOVERNMENT_VIEW_ALL_POLICIES") end,
        rowIndex = nil,
        emptyLoc = "LOC_CAI_GOVERNMENT_NO_AVAILABLE_POLICIES",
        close    = function() ctx.CloseAllPolicies() end,
        action   = nil,
    })
end
