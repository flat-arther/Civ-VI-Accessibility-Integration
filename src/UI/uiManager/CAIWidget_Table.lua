-- CAIWidget_Table.lua
-- Three-level table: Table -> Column -> Tier -> item cell.
--
--   Column = a labeled group (e.g. a civics-tree era). Speaks only its header
--            label; role and position are muted. Holds one or more tiers.
--   Tier   = a side-by-side sub-column inside a column, navigated Left/Right.
--            A Transparent grouping that says nothing of its own.
--   Item   = an arbitrary cell widget stacked vertically inside a tier,
--            navigated Up/Down.
--
-- A plain data grid is the degenerate case: every column has exactly one tier,
-- so Left/Right walks columns and Up/Down walks rows. Because the column owns
-- its cells through the tier, the manager's focus-divergence machinery speaks
-- the column header automatically when (and only when) focus crosses into a
-- new column.

local Nav = CAIWidgetHelpers_Navigation

---@class TableColumn
---@field header string|fun():string
---@field width? integer Number of side-by-side tiers (default 1).

---@class TableWidget : ContainerWidget
TableWidget = setmetatable({}, { __index = ContainerWidget })
TableWidget.__index = TableWidget

---Internal container for a tier (a vertical stack of cells). Transparent so it
---contributes nothing to speech; navigation is driven entirely by the table.
---@param mgr UIScreenManager
---@return ContainerWidget
local function makeTier(mgr)
    local tier = ContainerWidget.New(ContainerWidget)
    tier.Manager = mgr
    tier.Type = "TableTier"
    tier.WrapAround = false
    tier.Transparent = true
    tier.UseDirectionalEntry = false
    return tier
end

---Internal container for a column. Speaks only its header label (role and
---position muted, per the table convention). Owns `width` tiers up front.
---@param mgr UIScreenManager
---@param col TableColumn
---@return ContainerWidget
local function makeColumn(mgr, col)
    local c = ContainerWidget.New(ContainerWidget)
    c.Manager = mgr
    c.Type = "TableColumn"
    c.Role = "TableColumn"
    c.WrapAround = false
    c:SetLabel(col.header)
    c.SpeechSettings = { Role = false, Position = false }
    c._width = math.max(1, col.width or 1)
    c._tiers = {}
    for i = 1, c._width do
        local tier = makeTier(mgr)
        c._tiers[i] = tier
        c:AddChild(tier)
    end
    return c
end

---@param mgr UIScreenManager
---@param id string
---@param props? table
---@return TableWidget
function TableWidget.Create(mgr, id, props)
    local w = ContainerWidget.New(TableWidget)
    w.Id = id
    w.Type = "Table"
    w.Role = "Table"
    w.Manager = mgr
    w.WrapAround = false
    w:AddInputBindings({
        { Key = Keys.VK_UP,    MSG = KeyEvents.KeyDown,                   Description = "LOC_CAI_KB_MOVE_UP",             Action = function(self) return self:_NavigateVertical(-1) end },
        { Key = Keys.VK_DOWN,  MSG = KeyEvents.KeyDown,                   Description = "LOC_CAI_KB_MOVE_DOWN",           Action = function(self) return self:_NavigateVertical( 1) end },
        { Key = Keys.VK_LEFT,  MSG = KeyEvents.KeyDown,                   Description = "LOC_CAI_KB_MOVE_LEFT",           Action = function(self) return self:_NavigateHorizontal(-1) end },
        { Key = Keys.VK_RIGHT, MSG = KeyEvents.KeyDown,                   Description = "LOC_CAI_KB_MOVE_RIGHT",          Action = function(self) return self:_NavigateHorizontal( 1) end },
        { Key = Keys.VK_HOME,  MSG = KeyEvents.KeyDown,                   Description = "LOC_CAI_KB_MOVE_TO_ROW_START",   Action = function(self) return self:_NavigateTierEdge(-1) end },
        { Key = Keys.VK_END,   MSG = KeyEvents.KeyDown,                   Description = "LOC_CAI_KB_MOVE_TO_ROW_END",     Action = function(self) return self:_NavigateTierEdge( 1) end },
        { Key = Keys.VK_HOME,  MSG = KeyEvents.KeyDown, IsControl = true, Description = "LOC_CAI_KB_MOVE_TO_TABLE_START", Action = function(self) return self:_NavigateTableEdge(-1) end },
        { Key = Keys.VK_END,   MSG = KeyEvents.KeyDown, IsControl = true, Description = "LOC_CAI_KB_MOVE_TO_TABLE_END",   Action = function(self) return self:_NavigateTableEdge( 1) end },
        { Key = Keys.VK_LEFT,  MSG = KeyEvents.KeyDown, IsControl = true, Description = "LOC_CAI_KB_PREVIOUS_COLUMN",     Action = function(self) return self:_NavigateColumn(-1) end },
        { Key = Keys.VK_RIGHT, MSG = KeyEvents.KeyDown, IsControl = true, Description = "LOC_CAI_KB_NEXT_COLUMN",         Action = function(self) return self:_NavigateColumn( 1) end },
    })
    CAIWidgetRegistry.ApplyProps(w, props)
    return w
end

--#region Schema

---Append a column. `width` is the number of side-by-side tiers it holds.
---@param col TableColumn
---@return ContainerWidget column
function TableWidget:AddColumn(col)
    local column = makeColumn(self.Manager, col or {})
    self:AddChild(column)
    return column
end

---@return integer
function TableWidget:GetColumnCount() return #self.Children end

---@param i integer
---@return ContainerWidget|nil
function TableWidget:GetColumnWidget(i) return self.Children[i] end

---@param column ContainerWidget|integer
---@param tierIndex? integer 1-based; defaults to 1.
---@return ContainerWidget|nil
function TableWidget:GetTier(column, tierIndex)
    local c = type(column) == "number" and self.Children[column] or column
    return c and c._tiers and c._tiers[tierIndex or 1] or nil
end

---Append an item cell to a column's tier (vertical stack).
---@param column ContainerWidget|integer
---@param tierIndex integer|nil 1-based; defaults to 1.
---@param widget UIWidget
---@return integer itemIndex
function TableWidget:AddItem(column, tierIndex, widget)
    local tier = self:GetTier(column, tierIndex)
    if not tier then return 0 end
    if widget then tier:AddChild(widget) end
    return tier:GetChildIndex(widget)
end

---Grid convenience: one cell into each column's first tier, in column order.
---@param cells (UIWidget|nil)[]
---@return integer rowIndex
function TableWidget:AddRow(cells)
    if cells then
        for c = 1, #self.Children do
            local widget = cells[c]
            if widget then self:AddItem(self.Children[c], 1, widget) end
        end
    end
    return self:GetRowCount()
end

---Grid row count: the longest first-tier stack across columns.
---@return integer
function TableWidget:GetRowCount()
    local n = 0
    for _, column in ipairs(self.Children) do
        local tier = column._tiers and column._tiers[1]
        if tier then n = math.max(n, #tier.Children) end
    end
    return n
end

---Grid cell accessor: item `row` in column `col`'s first tier.
---@param row integer
---@param col integer
---@return UIWidget|nil
function TableWidget:GetCell(row, col)
    local tier = self:GetTier(col, 1)
    return tier and tier.Children[row] or nil
end

---Replace (or append at `row`) a grid cell in a column's first tier.
---@param row integer
---@param col integer
---@param widget UIWidget|nil
function TableWidget:SetCell(row, col, widget)
    local tier = self:GetTier(col, 1)
    if not tier then return end
    local existing = tier.Children[row]
    if existing then existing:Destroy() end
    if widget then
        if row <= #tier.Children then
            tier:InsertChild(row, widget)
        else
            tier:AddChild(widget)
        end
    end
end

---Remove a grid row: the `row`-th item from every column's first tier.
---@param row integer
function TableWidget:RemoveRow(row)
    for _, column in ipairs(self.Children) do
        local tier = column._tiers and column._tiers[1]
        if tier and tier.Children[row] then tier.Children[row]:Destroy() end
    end
end

---Destroy every item cell, keeping the column/tier structure intact.
function TableWidget:ClearRows()
    for _, column in ipairs(self.Children) do
        if column._tiers then
            for _, tier in ipairs(column._tiers) do tier:ClearChildren() end
        end
    end
end

--#endregion

--#region Navigation

---Flatten every tier across all columns, in document order.
---@return ContainerWidget[]
function TableWidget:_AllTiers()
    local out = {}
    for _, column in ipairs(self.Children) do
        if column._tiers then
            for _, tier in ipairs(column._tiers) do out[#out + 1] = tier end
        end
    end
    return out
end

---The currently focused item cell and its tier, or nil if focus isn't on one.
---@return UIWidget|nil cell, ContainerWidget|nil tier
function TableWidget:_FocusedCell()
    local cell = self.Manager and self.Manager:GetFocusedWidget()
    if not cell then return nil, nil end
    return cell, cell.Parent
end

---Find the nearest non-hidden cell to raw child index `idx` in a tier.
---Searches outward from `idx` (checking idx first, then idx±1, idx±2, …).
---@param tier ContainerWidget
---@param idx integer 1-based raw child index
---@return UIWidget|nil
local function nearestVisibleAt(tier, idx)
    local children = tier.Children
    if not children or #children == 0 then return nil end
    local n = #children
    if idx < 1 then idx = 1 end
    if idx > n then idx = n end
    for offset = 0, n - 1 do
        local lo, hi = idx - offset, idx + offset
        if lo >= 1 then
            local c = children[lo]
            if not c:IsHidden() then return c end
        end
        if hi ~= lo and hi <= n then
            local c = children[hi]
            if not c:IsHidden() then return c end
        end
    end
    return nil
end

---Up/Down within the focused cell's tier. No wrap.
---@param dir 1|-1
---@return boolean
function TableWidget:_NavigateVertical(dir)
    local cell, tier = self:_FocusedCell()
    if not tier then return false end
    local idx = tier:GetChildIndex(cell)
    local target = Nav.FindVisible(tier, idx, dir, false)
    if target then
        self.Manager:SetFocus(target, { direction = dir })
        return true
    end
    return false
end

---Left/Right across the flattened tier list, preserving spatial row position.
---Uses raw child index so hidden spacers keep tiers aligned.
---@param dir 1|-1
---@return boolean
function TableWidget:_NavigateHorizontal(dir)
    local cell, tier = self:_FocusedCell()
    if not tier then return false end
    local tiers = self:_AllTiers()
    local ti
    for i, t in ipairs(tiers) do
        if t == tier then ti = i; break end
    end
    if not ti then return false end
    local rawIdx = tier:GetChildIndex(cell)
    local j = ti + dir
    while j >= 1 and j <= #tiers do
        local target = nearestVisibleAt(tiers[j], rawIdx)
        if target then
            self.Manager:SetFocus(target, { direction = dir })
            return true
        end
        j = j + dir
    end
    return false
end

---Home / End: first / last visible cell in the focused tier.
---@param dir 1|-1 -1 = first (top), 1 = last (bottom)
---@return boolean
function TableWidget:_NavigateTierEdge(dir)
    local cell, tier = self:_FocusedCell()
    if not tier then return false end
    local target = dir < 0 and Nav.First(tier) or Nav.Last(tier)
    if target and target ~= cell then
        self.Manager:SetFocus(target, { direction = dir })
        return true
    end
    return false
end

---Ctrl+Home / Ctrl+End: table-wide first / last navigable cell.
---@param dir 1|-1
---@return boolean
function TableWidget:_NavigateTableEdge(dir)
    local tiers = self:_AllTiers()
    if dir < 0 then
        for i = 1, #tiers do
            local target = Nav.First(tiers[i])
            if target then self.Manager:SetFocus(target, { direction = -1 }); return true end
        end
    else
        for i = #tiers, 1, -1 do
            local target = Nav.Last(tiers[i])
            if target then self.Manager:SetFocus(target, { direction = 1 }); return true end
        end
    end
    return false
end

---Ctrl+Left / Ctrl+Right: jump to the first cell of the prev / next column.
---@param dir 1|-1
---@return boolean
function TableWidget:_NavigateColumn(dir)
    local _, tier = self:_FocusedCell()
    if not tier then return false end
    local column = tier.Parent
    local ci = self:GetChildIndex(column)
    if ci == 0 then return false end
    local j = ci + dir
    while j >= 1 and j <= #self.Children do
        local target = self:_FirstCellInColumn(self.Children[j])
        if target then
            self.Manager:SetFocus(target, { direction = dir })
            return true
        end
        j = j + dir
    end
    return false
end

---First visible cell of a column, scanning its tiers in order.
---@param column ContainerWidget
---@return UIWidget|nil
function TableWidget:_FirstCellInColumn(column)
    if column:IsHidden() or not column._tiers then return nil end
    for _, t in ipairs(column._tiers) do
        local cell = Nav.First(t)
        if cell then return cell end
    end
    return nil
end

--#endregion

CAIWidgetRegistry.Register("Table", TableWidget.Create)
