-- CAIWidget_Table.lua
-- Row-major table. Cells (widgets, possibly nil) live in self._rows[r][c]; the
-- non-nil cells are also added to .Children so they integrate with the focus
-- tree. Arrow keys move between cells: empty (nil) and hidden cells are
-- skipped in the direction of travel — a Down press from (2, 3) lands on the
-- first navigable cell at (r > 2, c = 3), not on a blank.

---@class TableColumn
---@field header string|fun():string
---@field width? integer

---@class TableWidget : ContainerWidget
---@field _columns TableColumn[]
---@field _rows table<integer, table<integer, UIWidget|nil>>
TableWidget = setmetatable({}, { __index = ContainerWidget })
TableWidget.__index = TableWidget

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
    w._columns = {}
    w._rows = {}
    w.WrapAround = false
    w:AddInputBindings({
        { Key = Keys.VK_LEFT,  MSG = KeyEvents.KeyDown,                  Action = function(self) return self:_NavigateGrid(0, -1) end },
        { Key = Keys.VK_RIGHT, MSG = KeyEvents.KeyDown,                  Action = function(self) return self:_NavigateGrid(0,  1) end },
        { Key = Keys.VK_UP,    MSG = KeyEvents.KeyDown,                  Action = function(self) return self:_NavigateGrid(-1, 0) end },
        { Key = Keys.VK_DOWN,  MSG = KeyEvents.KeyDown,                  Action = function(self) return self:_NavigateGrid( 1, 0) end },
        { Key = Keys.VK_HOME,  MSG = KeyEvents.KeyDown,                  Action = function(self) return self:_NavigateRowEdge(-1) end },
        { Key = Keys.VK_END,   MSG = KeyEvents.KeyDown,                  Action = function(self) return self:_NavigateRowEdge( 1) end },
        { Key = Keys.VK_HOME,  MSG = KeyEvents.KeyDown, IsControl = true, Action = function(self) return self:_NavigateTableEdge(-1) end },
        { Key = Keys.VK_END,   MSG = KeyEvents.KeyDown, IsControl = true, Action = function(self) return self:_NavigateTableEdge( 1) end },
    })
    CAIWidgetRegistry.ApplyProps(w, props)
    return w
end

--#region Schema

---@param col TableColumn
---@return integer columnIndex
function TableWidget:AddColumn(col)
    table.insert(self._columns, col or {})
    return #self._columns
end

---@return integer
function TableWidget:GetColumnCount() return #self._columns end

---@param i integer
---@return TableColumn|nil
function TableWidget:GetColumn(i) return self._columns[i] end

---@param cells (UIWidget|nil)[]
---@return integer rowIndex
function TableWidget:AddRow(cells)
    local r = #self._rows + 1
    self._rows[r] = {}
    if cells then
        for c = 1, #self._columns do
            local widget = cells[c]
            self._rows[r][c] = widget
            if widget then self:AddChild(widget) end
        end
    end
    return r
end

---@param row integer
---@param col integer
---@param widget UIWidget|nil
function TableWidget:SetCell(row, col, widget)
    self._rows[row] = self._rows[row] or {}
    local existing = self._rows[row][col]
    if existing then
        existing:Destroy()
    end
    self._rows[row][col] = widget
    if widget then self:AddChild(widget) end
end

---@param row integer
---@param col integer
---@return UIWidget|nil
function TableWidget:GetCell(row, col)
    local r = self._rows[row]
    return r and r[col] or nil
end

---@return integer
function TableWidget:GetRowCount() return #self._rows end

---@param row integer
function TableWidget:RemoveRow(row)
    local r = self._rows[row]
    if not r then return end
    for _, widget in pairs(r) do
        if widget then widget:Destroy() end
    end
    table.remove(self._rows, row)
end

function TableWidget:ClearRows()
    for r = #self._rows, 1, -1 do self:RemoveRow(r) end
    self._rows = {}
end

--#endregion

--#region Navigation

---@param widget UIWidget
---@return integer|nil row, integer|nil col
function TableWidget:_FindCellPos(widget)
    for r, row in ipairs(self._rows) do
        for c = 1, #self._columns do
            if row[c] == widget then return r, c end
        end
    end
    return nil, nil
end

---@param r integer
---@param c integer
---@return boolean
function TableWidget:_IsCellNavigable(r, c)
    local row = self._rows[r]
    local cell = row and row[c]
    return cell ~= nil and not cell:IsHidden()
end

---Walk in (dr, dc) from the focused cell until we find a navigable cell or
---fall off the grid. Empty (nil) and hidden cells are skipped, never landed on.
---@param dr integer
---@param dc integer
---@return boolean
function TableWidget:_NavigateGrid(dr, dc)
    local focused = self:GetFocusedChild()
    if not focused then return false end
    local r, c = self:_FindCellPos(focused)
    if not r then return false end
    local nRows = #self._rows
    local nCols = #self._columns
    while true do
        r = r + dr
        c = c + dc
        if r < 1 or r > nRows or c < 1 or c > nCols then return false end
        if self:_IsCellNavigable(r, c) then
            local dirHint = (dr + dc) >= 0 and 1 or -1
            self.Manager:SetFocus(self._rows[r][c], { direction = dirHint })
            return true
        end
    end
end

---Home / End within the current row. Stops at the outermost navigable cell.
---@param dir 1|-1 -1 = home (leftmost), 1 = end (rightmost)
---@return boolean
function TableWidget:_NavigateRowEdge(dir)
    local focused = self:GetFocusedChild()
    if not focused then return false end
    local r, c = self:_FindCellPos(focused)
    if not r then return false end
    local nCols = #self._columns
    local target
    if dir < 0 then
        for col = 1, nCols do
            if self:_IsCellNavigable(r, col) then target = col; break end
        end
    else
        for col = nCols, 1, -1 do
            if self:_IsCellNavigable(r, col) then target = col; break end
        end
    end
    if not target or target == c then return false end
    self.Manager:SetFocus(self._rows[r][target], { direction = dir })
    return true
end

---Ctrl+Home / Ctrl+End: jump to the table-wide first / last navigable cell.
---@param dir 1|-1
---@return boolean
function TableWidget:_NavigateTableEdge(dir)
    local nRows = #self._rows
    local nCols = #self._columns
    if dir < 0 then
        for r = 1, nRows do
            for c = 1, nCols do
                if self:_IsCellNavigable(r, c) then
                    self.Manager:SetFocus(self._rows[r][c], { direction = -1 })
                    return true
                end
            end
        end
    else
        for r = nRows, 1, -1 do
            for c = nCols, 1, -1 do
                if self:_IsCellNavigable(r, c) then
                    self.Manager:SetFocus(self._rows[r][c], { direction = 1 })
                    return true
                end
            end
        end
    end
    return false
end

--#endregion

CAIWidgetRegistry.Register("Table", TableWidget.Create)
