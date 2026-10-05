-- Expand ordered, conditional key descriptions without reading game state.
CAIDescriptors = {}

---@param results table Existing output array; duplicates and order are preserved.
---@param context any Passed unchanged to conditions and named group readers.
---@param definitions table|nil An absent optional definition contributes no keys.
---@param groups? table<string,fun(context:any):table|nil> Optional named dynamic groups.
---@return table
function CAIDescriptors.AppendKeys(results, context, definitions, groups)
    if definitions == nil then return results end
    for _, entry in ipairs(definitions) do
        if type(entry) == "string" then
            table.insert(results, entry)
        elseif type(entry) == "table" then
            local include = entry.when == nil or entry.when(context)
            if include then
                if entry.key ~= nil then
                    table.insert(results, entry.key)
                elseif entry.keys ~= nil then
                    CAIDescriptors.AppendKeys(results, context, entry.keys, groups)
                elseif entry.bucket ~= nil and groups ~= nil then
                    local reader = groups[entry.bucket]
                    if reader ~= nil then
                        CAIDescriptors.AppendKeys(results, context, reader(context), groups)
                    end
                end
            end
        end
    end
    return results
end
