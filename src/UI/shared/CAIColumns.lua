include("textProcessing")

-- Column metadata utilities. Screens own records, sorting and widget state.
CAIColumns = {}

-- Refresh an existing sort dropdown without firing its user-change callback.
-- Natural order uses a nil column and ignores the remembered direction.
---@param dropdown DropdownWidget|nil Absent while the screen is not built.
---@param options table[] Existing dropdown options; this does not replace them.
---@param columnKey string|nil
---@param ascending boolean
function CAIColumns.SyncSortSelection(dropdown, options, columnKey, ascending)
    if not dropdown then return end
    for index, option in ipairs(options) do
        local sort = option.value
        if sort.column == columnKey and (sort.column == nil or sort.ascending == ascending) then
            dropdown:SetSelectedIndex(index, true)
            return
        end
    end
end

---@param columns DataTableColumn[]
---@param key string|nil
---@return DataTableColumn|nil
function CAIColumns.Find(columns, key)
    for _, column in ipairs(columns) do
        if column.key == key then return column end
    end
    return nil
end

---@param columns DataTableColumn[]
---@param policy CAIColumnSortPolicy
---@return table[]
function CAIColumns.BuildSortOptions(columns, policy)
    local options = {}
    if policy.natural then
        options[1] = {
            label = Locale.Lookup("LOC_CAI_DATATABLE_SORT_NATURAL"),
            value = { column = policy.natural.column, ascending = policy.natural.ascending },
        }
    end
    for _, column in ipairs(columns) do
        local included
        if policy.includeColumn then included = policy.includeColumn(column)
        else included = column.sortKey end
        if included then
            local label = column.header
            if policy.preferSortLabel then label = column.sortLabel or label end
            local header = CAIText.ResolveLabel(label)
            local function AddDirection(ascending)
                local tag
                if ascending then tag = column.sortAscendingDescription
                else tag = column.sortDescendingDescription end
                options[#options + 1] = {
                    label = header .. policy.separator .. Locale.Lookup(tag),
                    value = { column = column.key, ascending = ascending },
                }
            end
            AddDirection(not policy.descendingFirst)
            AddDirection(policy.descendingFirst == true)
        end
    end
    return options
end
