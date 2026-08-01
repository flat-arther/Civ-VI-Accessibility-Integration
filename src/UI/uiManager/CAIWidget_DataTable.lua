-- CAIWidget_DataTable.lua
-- Sortable data grid with explicit row-label and column-header speech.
-- Unlike GridWidget, DataTable owns homogeneous rows and columns.

---@class DataTableColumn
---@field key string Stable column identity.
---@field header string|fun():string Live localized column header.
---@field getCell fun(row:any):string Live displayed value.
---@field getTooltip? fun(row:any):string
---@field getState? fun(row:any):string
---@field isDisabled? fun(row:any):boolean
---@field sortKey? fun(row:any):any Presence makes the header sortable.
---@field activatable? boolean Whether data cells emit `cell_activate`.
---@field role? string Optional localized widget role for data cells.

---@class DataTableSort
---@field column string Stable DataTableColumn key.
---@field ascending? boolean

---@class DataTableCellWidget : UIWidget
---@field Table DataTableWidget
---@field Column DataTableColumn
---@field ColumnIndex integer
---@field Row any|nil Nil for a header cell.
---@field RowIndex integer Zero for a header cell.
---@field RowKey any|nil
DataTableCellWidget = setmetatable({}, { __index = UIWidget })
DataTableCellWidget.__index = DataTableCellWidget

---@class DataTableWidget : ContainerWidget
---@field Columns DataTableColumn[]
---@field RowsProvider? fun():any[]
---@field RowKeyGetter? fun(row:any):any
---@field RowLabelGetter? fun(row:any):string
---@field DefaultSort? DataTableSort
DataTableWidget = setmetatable({}, { __index = ContainerWidget })
DataTableWidget.__index = DataTableWidget

local HEADER_ROW_KEY = "__header__"
local Search = CAIWidgetHelpers_Search

local function resolve(value, ...)
    if type(value) == "function" then return value(...) end
    return value
end

local function addUnique(parts, value)
    if value == nil or value == "" then return end
    for _, existing in ipairs(parts) do
        if existing == value then return end
    end
    parts[#parts + 1] = value
end

local function includesLabel(elements)
    if not elements or #elements == 0 then return true end
    for _, element in ipairs(elements) do
        if element == "label" then return true end
    end
    return false
end

local function check(condition, message)
    if condition then return end
    LogError("DataTable: " .. message)
    error(message, 2)
end

---@param tableWidget DataTableWidget
---@param row any|nil
---@param rowIndex integer
---@param rowKey any|nil
---@param column DataTableColumn
---@param columnIndex integer
---@return DataTableCellWidget
local function makeCell(tableWidget, row, rowIndex, rowKey, column, columnIndex)
    local cell = UIWidget.New(DataTableCellWidget)
    cell.Id = tableWidget.Manager:GenerateWidgetId("CAIDataTableCell")
    cell.Type = "DataTableCell"
    cell.Manager = tableWidget.Manager
    cell.Table = tableWidget
    cell.Column = column
    cell.ColumnIndex = columnIndex
    cell.Row = row
    cell.RowIndex = rowIndex
    cell.RowKey = rowKey
    cell.Role = "TableCell"
    cell.SpeechSettings = { Role = false }

    if rowIndex == 0 then
        if column.sortKey then
            cell.Role = "Button"
            cell.SpeechSettings = {}
        end
        cell.FocusKey = tostring(tableWidget.Id) .. ":header:" .. column.key
        cell:SetLabel(function()
            local label = resolve(column.header) or ""
            if tableWidget.SortColumnKey == column.key then
                local state = tableWidget.SortAscending
                    and Locale.Lookup("LOC_CAI_DATATABLE_SORT_ASCENDING")
                    or Locale.Lookup("LOC_CAI_DATATABLE_SORT_DESCENDING")
                return label .. ", " .. state
            end
            if tableWidget._sortFeedbackColumnKey == column.key then
                return label .. ", " .. Locale.Lookup("LOC_CAI_DATATABLE_SORT_NATURAL")
            end
            return label
        end)
        if column.sortKey then
            cell:SetTooltip(function() return Locale.Lookup("LOC_CAI_DATATABLE_SORT_HELP") end)
        end
    else
        if column.role then
            cell.Role = column.role
            cell.SpeechSettings = {}
        elseif column.activatable then
            cell.Role = "Button"
            cell.SpeechSettings = {}
        end
        cell.FocusKey = tostring(tableWidget.Id) .. ":row:" .. tostring(rowKey) .. ":" .. column.key
        cell:SetLabel(function() return column.getCell(row) or "" end)
        if column.getTooltip then
            cell:SetTooltip(function() return column.getTooltip(row) or "" end)
        end
        if column.getState then
            cell:SetStateGetter(function() return column.getState(row) or "" end)
        end
        if column.isDisabled then
            cell:SetDisabledPredicate(function() return column.isDisabled(row) == true end)
        end
    end

    if (rowIndex == 0 and column.sortKey) or (rowIndex > 0 and column.activatable) then
        cell:AddInputBindings({
            { Key = Keys.VK_RETURN, MSG = KeyEvents.KeyUp, Description = "LOC_CAI_KB_ACTIVATE", Action = function(self) return self:Activate() end },
            { Key = Keys.VK_SPACE, Description = "LOC_CAI_KB_ACTIVATE", Action = function(self) return self:Activate() end },
        })
    end
    cell:On("focus_enter", function(self)
        local owner = self.Table
        local focusRowKey = self.RowIndex == 0 and HEADER_ROW_KEY or self.RowKey
        if owner._lastFocusedRowKey ~= focusRowKey then
            owner._lastFocusedRowKey = focusRowKey
            owner:Emit("row_focus_enter", self.Row, self.RowIndex, self)
        end
        if self.Manager then owner:Emit("cell_focus_enter", self.Row, self.Column, self) end
    end)
    return cell
end

---@return boolean
function DataTableCellWidget:Activate()
    if self:IsDisabled() then return true end
    self:Emit("activate", self.Row, self.Column)
    if not self.Manager then return true end
    if self.RowIndex == 0 then
        if self.Column.sortKey then self.Table:CycleSort(self.Column.key) end
        return true
    end
    if self.Column.activatable then
        self.Table:Emit("cell_activate", self.Row, self.Column, self)
    end
    return true
end

---@return table
function DataTableCellWidget:GetInfoStrings()
    local info = UIWidget.GetInfoStrings(self)
    local owner = self.Table
    local columnKey = self.Column.key

    if self.RowIndex == 0 then
        info.position = Locale.Lookup("LOC_CAI_DATATABLE_HEADER_POSITION", self.ColumnIndex, #owner.Columns)
        return info
    end

    local rowKey = self.RowKey
    local force = not self:IsFocused()
        or owner._lastSpokenRowKey == nil
        or owner._lastSpokenColumnKey == nil
    local parts = {}
    if force or owner._lastSpokenRowKey ~= rowKey then
        addUnique(parts, owner.RowLabelGetter(self.Row))
    end
    if force or owner._lastSpokenColumnKey ~= columnKey then
        addUnique(parts, resolve(self.Column.header))
    end
    addUnique(parts, self:GetLabel())
    info.label = #parts > 0 and table.concat(parts, ", ") or nil
    info.position = Locale.Lookup(
        "LOC_CAI_DATATABLE_CELL_POSITION",
        self.RowIndex,
        owner:GetRowCount(),
        self.ColumnIndex,
        #owner.Columns
    )
    return info
end

---@param elements? string[]
---@return string|nil
function DataTableCellWidget:BuildSpeech(elements)
    local speech = UIWidget.BuildSpeech(self, elements)
    if self:IsFocused() and includesLabel(elements) then
        self.Table._lastSpokenRowKey = self.RowIndex == 0 and HEADER_ROW_KEY or self.RowKey
        self.Table._lastSpokenColumnKey = self.Column.key
    end
    return speech
end

---@param mgr UIScreenManager
---@param id string
---@param props? table
---@return DataTableWidget
function DataTableWidget.Create(mgr, id, props)
    local w = ContainerWidget.New(DataTableWidget)
    w.Id = id
    w.Type = "DataTable"
    w.Role = "Table"
    w.Manager = mgr
    w.WrapAround = false
    w.Columns = {}
    w.RowsProvider = nil
    w.RowKeyGetter = nil
    w.RowLabelGetter = nil
    w.DefaultSort = nil
    w.SortColumnKey = nil
    w.SortAscending = false
    w._lastSpokenRowKey = nil
    w._lastSpokenColumnKey = nil
    w._lastFocusedRowKey = nil
    w._sortFeedbackColumnKey = nil
    w:AddInputBindings({
        { Key = Keys.VK_UP, MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_MOVE_UP", Action = function(self) return Search.NavigateResults(self, -1) or self:_NavigateVertical(-1) end },
        { Key = Keys.VK_DOWN, MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_MOVE_DOWN", Action = function(self) return Search.NavigateResults(self, 1) or self:_NavigateVertical(1) end },
        { Key = Keys.VK_LEFT, MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_MOVE_LEFT", Action = function(self) return self:_NavigateHorizontal(-1) end },
        { Key = Keys.VK_RIGHT, MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_MOVE_RIGHT", Action = function(self) return self:_NavigateHorizontal(1) end },
        { Key = Keys.VK_HOME, MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_MOVE_TO_ROW_START", Action = function(self) return self:_NavigateDataEdge(-1) end },
        { Key = Keys.VK_END, MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_MOVE_TO_ROW_END", Action = function(self) return self:_NavigateDataEdge(1) end },
        { Key = Keys.VK_HOME, MSG = KeyEvents.KeyDown, IsControl = true, Description = "LOC_CAI_KB_MOVE_TO_TABLE_START", Action = function(self) return self:_NavigateTableEdge(-1) end },
        { Key = Keys.VK_END, MSG = KeyEvents.KeyDown, IsControl = true, Description = "LOC_CAI_KB_MOVE_TO_TABLE_END", Action = function(self) return self:_NavigateTableEdge(1) end },
        { Key = Keys.VK_LEFT, MSG = KeyEvents.KeyDown, IsControl = true, Description = "LOC_CAI_KB_PREVIOUS_COLUMN", Action = function(self) return self:_NavigateHeaderColumn(-1) end },
        { Key = Keys.VK_RIGHT, MSG = KeyEvents.KeyDown, IsControl = true, Description = "LOC_CAI_KB_NEXT_COLUMN", Action = function(self) return self:_NavigateHeaderColumn(1) end },
    })
    w:On("focus_enter", function(self)
        self._lastSpokenRowKey = nil
        self._lastSpokenColumnKey = nil
        self._lastFocusedRowKey = nil
    end)
    CAIWidgetRegistry.ApplyProps(w, props)
    return w
end

---Search one candidate per data row using only its row label. Results retain
---the currently focused column so type-to-find does not change table context.
---@param includeTooltips boolean Unused: data-table searches never inspect tooltips.
---@return SearchCandidate[]
function DataTableWidget:GetTypeToFindCandidates(includeTooltips)
    local candidates = {}
    local focused = self:_FocusedCell()
    local columnIndex = focused and focused.ColumnIndex or 1
    for rowIndex = 1, self:GetRowCount() do
        local target = self:GetCell(rowIndex, columnIndex)
        if target and not target:IsHidden() then
            local label = self.RowLabelGetter(target.Row) or ""
            if label ~= "" then
                candidates[#candidates + 1] = Search.MakeSearchCandidate(target, label, rowIndex)
            end
        end
    end
    return candidates
end

---@param char string
---@return boolean
function DataTableWidget:OnCharInput(char)
    return Search.HandleChar(self, char)
end

---@return boolean
function DataTableWidget:OnSearchBackspace()
    return Search.HandleBackspace(self)
end

---@param columns DataTableColumn[]
function DataTableWidget:SetColumns(columns)
    check(type(columns) == "table" and #columns > 0, "columns must be a non-empty array")
    local keys = {}
    for i, column in ipairs(columns) do
        check(type(column) == "table", "column " .. tostring(i) .. " must be a table")
        check(type(column.key) == "string" and column.key ~= "", "column key is required")
        check(not keys[column.key], "duplicate column key: " .. column.key)
        check(type(column.header) == "string" or type(column.header) == "function", "column header is required")
        check(type(column.getCell) == "function", "column getCell is required")
        check(column.getTooltip == nil or type(column.getTooltip) == "function", "column getTooltip must be a function")
        check(column.getState == nil or type(column.getState) == "function", "column getState must be a function")
        check(column.isDisabled == nil or type(column.isDisabled) == "function", "column isDisabled must be a function")
        check(column.sortKey == nil or type(column.sortKey) == "function", "column sortKey must be a function")
        check(column.activatable == nil or type(column.activatable) == "boolean", "column activatable must be a boolean")
        check(column.role == nil or type(column.role) == "string", "column role must be a string")
        keys[column.key] = true
    end
    self.Columns = columns
end

---@param provider fun():any[]
function DataTableWidget:SetRowsProvider(provider)
    check(type(provider) == "function", "rows provider must be a function")
    self.RowsProvider = provider
end

---@param getter fun(row:any):any
function DataTableWidget:SetRowKeyGetter(getter)
    check(type(getter) == "function", "row key getter must be a function")
    self.RowKeyGetter = getter
end

---@param getter fun(row:any):string
function DataTableWidget:SetRowLabelGetter(getter)
    check(type(getter) == "function", "row label getter must be a function")
    self.RowLabelGetter = getter
end

---@param sort DataTableSort|nil
function DataTableWidget:SetDefaultSort(sort)
    check(sort == nil or type(sort) == "table", "default sort must be a table")
    check(sort == nil or type(sort.column) == "string", "default sort column must be a string")
    check(sort == nil or sort.ascending == nil or type(sort.ascending) == "boolean", "default sort ascending must be a boolean")
    self.DefaultSort = sort
    self.SortColumnKey = nil
    self.SortAscending = false
    if sort then
        self.SortColumnKey = sort.column
        self.SortAscending = sort.ascending == true
    end
end

---@return integer
function DataTableWidget:GetColumnCount() return #self.Columns end

---@return integer
function DataTableWidget:GetRowCount() return math.max(0, #self.Children - 1) end

---@param column string|integer
---@return integer|nil
function DataTableWidget:GetColumnIndex(column)
    if type(column) == "number" then
        return column >= 1 and column <= #self.Columns and column or nil
    end
    for i, definition in ipairs(self.Columns) do
        if definition.key == column then return i end
    end
    return nil
end

---@return string|nil columnKey, boolean ascending
function DataTableWidget:GetSort()
    return self.SortColumnKey, self.SortAscending
end

---@param rowIndex integer One-based data row index.
---@param column string|integer
---@return DataTableCellWidget|nil
function DataTableWidget:GetCell(rowIndex, column)
    local columnIndex = self:GetColumnIndex(column)
    local row = self.Children[rowIndex + 1]
    return row and columnIndex and row.Children[columnIndex] or nil
end

---@param column string|integer
---@return DataTableCellWidget|nil
function DataTableWidget:GetHeader(column)
    local columnIndex = self:GetColumnIndex(column)
    local row = self.Children[1]
    return row and columnIndex and row.Children[columnIndex] or nil
end

---@return any|nil row, any|nil rowKey, integer|nil rowIndex
function DataTableWidget:GetFocusedRow()
    local cell = self:_FocusedCell()
    if not cell or cell.RowIndex == 0 then return nil, nil, nil end
    return cell.Row, cell.RowKey, cell.RowIndex
end

---@return DataTableColumn|nil column, integer|nil columnIndex
function DataTableWidget:GetFocusedColumn()
    local cell = self:_FocusedCell()
    return cell and cell.Column or nil, cell and cell.ColumnIndex or nil
end

---@return DataTableCellWidget|nil
function DataTableWidget:_FocusedCell()
    local focused = self.Manager and self.Manager:GetFocusedWidget()
    if focused and focused.Table == self then return focused end
    return nil
end

local function compareValues(a, b)
    if a == b then return 0 end
    if a == nil then return 1 end
    if b == nil then return -1 end
    if type(a) == "number" and type(b) == "number" then return a < b and -1 or 1 end
    if type(a) == "boolean" and type(b) == "boolean" then return a and 1 or -1 end
    return Locale.Compare(tostring(a), tostring(b))
end

---@param rows any[]
---@return any[]
function DataTableWidget:_SortRows(rows)
    local columnIndex = self:GetColumnIndex(self.SortColumnKey)
    local column = columnIndex and self.Columns[columnIndex] or nil
    if not column or not column.sortKey then return rows end

    local decorated = {}
    for naturalIndex, row in ipairs(rows) do
        decorated[#decorated + 1] = {
            row = row,
            naturalIndex = naturalIndex,
            value = column.sortKey(row),
        }
    end
    local ascending = self.SortAscending
    table.sort(decorated, function(a, b)
        if a.value == nil or b.value == nil then
            if a.value == b.value then return a.naturalIndex < b.naturalIndex end
            return a.value ~= nil
        end
        local comparison = compareValues(a.value, b.value)
        if comparison == 0 then return a.naturalIndex < b.naturalIndex end
        return ascending and comparison < 0 or comparison > 0
    end)
    local sorted = {}
    for _, entry in ipairs(decorated) do sorted[#sorted + 1] = entry.row end
    return sorted
end

local function makeRow(tableWidget)
    local row = ContainerWidget.New(ContainerWidget)
    row.Manager = tableWidget.Manager
    row.Type = "DataTableRow"
    row.Transparent = true
    row.UseDirectionalEntry = false
    row.WrapAround = false
    return row
end

function DataTableWidget:Rebuild()
    check(#self.Columns > 0, "columns must be configured before Rebuild")
    check(type(self.RowsProvider) == "function", "rows provider must be configured before Rebuild")
    check(type(self.RowKeyGetter) == "function", "row key getter must be configured before Rebuild")
    check(type(self.RowLabelGetter) == "function", "row label getter must be configured before Rebuild")

    if self.SortColumnKey then
        local sortIndex = self:GetColumnIndex(self.SortColumnKey)
        check(sortIndex and self.Columns[sortIndex].sortKey, "sort column must be sortable")
    end

    local capture = self.Manager:CaptureFocusKey(self)
    self:ClearChildren()

    local headerRow = makeRow(self)
    for columnIndex, column in ipairs(self.Columns) do
        headerRow:AddChild(makeCell(self, nil, 0, nil, column, columnIndex))
    end
    self:AddChild(headerRow)

    local rows = self.RowsProvider() or {}
    check(type(rows) == "table", "rows provider must return an array")
    rows = self:_SortRows(rows)
    local rowKeys = {}
    for rowIndex, rowData in ipairs(rows) do
        local rowKey = self.RowKeyGetter(rowData)
        check(rowKey ~= nil, "row key cannot be nil")
        local rowKeyString = tostring(rowKey)
        check(not rowKeys[rowKeyString], "duplicate row key: " .. rowKeyString)
        rowKeys[rowKeyString] = true

        local rowWidget = makeRow(self)
        for columnIndex, column in ipairs(self.Columns) do
            rowWidget:AddChild(makeCell(self, rowData, rowIndex, rowKey, column, columnIndex))
        end
        self:AddChild(rowWidget)
    end

    self.DefaultIndex = #rows > 0 and 2 or 1
    self.Manager:RestoreFocus(self, capture)
    self:Emit("rebuilt", #rows)
end

---@param columnKey string
function DataTableWidget:CycleSort(columnKey)
    local columnIndex = self:GetColumnIndex(columnKey)
    local column = columnIndex and self.Columns[columnIndex] or nil
    if not column or not column.sortKey then return end

    if self.SortColumnKey ~= columnKey then
        self.SortColumnKey = columnKey
        self.SortAscending = false
    elseif not self.SortAscending then
        self.SortAscending = true
    else
        self.SortColumnKey = nil
        self.SortAscending = false
        self._sortFeedbackColumnKey = columnKey
    end
    self:Rebuild()
    if self:_FocusedCell() then self.Manager:Refocus() end
    self._sortFeedbackColumnKey = nil
    self:Emit("sort_changed", self.SortColumnKey, self.SortAscending)
end

---@param rowChildIndex integer Header is 1; data begins at 2.
---@param columnIndex integer
---@return DataTableCellWidget|nil
function DataTableWidget:_CellAt(rowChildIndex, columnIndex)
    local row = self.Children[rowChildIndex]
    local cell = row and row.Children[columnIndex] or nil
    return cell and not cell:IsHidden() and cell or nil
end

---@param direction 1|-1
---@return boolean
function DataTableWidget:_NavigateVertical(direction)
    local cell = self:_FocusedCell()
    if not cell then return false end
    local rowChildIndex = cell.RowIndex + 1 + direction
    while rowChildIndex >= 1 and rowChildIndex <= #self.Children do
        local target = self:_CellAt(rowChildIndex, cell.ColumnIndex)
        if target then
            self.Manager:SetFocus(target, { direction = direction })
            return true
        end
        rowChildIndex = rowChildIndex + direction
    end
    return false
end

---@param direction 1|-1
---@return boolean
function DataTableWidget:_NavigateHorizontal(direction)
    local cell = self:_FocusedCell()
    if not cell then return false end
    local columnIndex = cell.ColumnIndex + direction
    local rowChildIndex = cell.RowIndex + 1
    while columnIndex >= 1 and columnIndex <= #self.Columns do
        local target = self:_CellAt(rowChildIndex, columnIndex)
        if target then
            self.Manager:SetFocus(target, { direction = direction })
            return true
        end
        columnIndex = columnIndex + direction
    end
    return false
end

---@param direction 1|-1
---@return boolean
function DataTableWidget:_NavigateDataEdge(direction)
    local cell = self:_FocusedCell()
    if not cell or self:GetRowCount() == 0 then return false end
    local rowChildIndex = direction < 0 and 2 or #self.Children
    local target = self:_CellAt(rowChildIndex, cell.ColumnIndex)
    if target and target ~= cell then
        self.Manager:SetFocus(target, { direction = direction })
        return true
    end
    return false
end

---@param direction 1|-1
---@return boolean
function DataTableWidget:_NavigateTableEdge(direction)
    local cell = self:_FocusedCell()
    if not cell then return false end
    local rowChildIndex = direction < 0 and 1 or #self.Children
    local columnIndex = direction < 0 and 1 or #self.Columns
    local target = self:_CellAt(rowChildIndex, columnIndex)
    if target and target ~= cell then
        self.Manager:SetFocus(target, { direction = direction })
        return true
    end
    return false
end

---@param direction 1|-1
---@return boolean
function DataTableWidget:_NavigateHeaderColumn(direction)
    local cell = self:_FocusedCell()
    if not cell then return false end
    local columnIndex = cell.ColumnIndex + direction
    while columnIndex >= 1 and columnIndex <= #self.Columns do
        local target = self:_CellAt(1, columnIndex)
        if target then
            self.Manager:SetFocus(target, { direction = direction })
            return true
        end
        columnIndex = columnIndex + direction
    end
    return false
end

CAIWidgetRegistry.Register("DataTable", DataTableWidget.Create)
