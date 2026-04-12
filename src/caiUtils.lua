---Utility wrapper for 'CAI.output'
---@param text string -- the text to speak
---@param interrupt boolean -- whether to interrupt any currently speaking text. False by default
function Speak(text, interrupt)
    --print("Speaking "..text)
    if CAI and CAI.output then CAI.output(tostring(text), interrupt) end
end

---Prints a table to the lua log. Do not use with recursives
---@param tbl table -- the table to print
---@param indent number -- the current indentation level (used for recursive calls, should probably not be set manually)
function PrintTable(tbl, indent)
    if not indent then indent = 0 end
    for k, v in pairs(tbl) do
        local formatting = string.rep("  ", indent) .. tostring(k) .. ": "
        if type(v) == "table" then
            print(formatting)
            PrintTable(v, indent + 1)
        else
            print(formatting .. tostring(v))
        end
    end
end

---Utility helper to wrap a function
---@param orig function -- the original function to wrap
---@param wrapper function -- the wrapper function that takes the original function as the first argument, followed by the original arguments
---@return function -- the wrapped function
function WrapFunc(orig, wrapper)
    return function(...)
        return wrapper(orig, ...)
    end
end

---Civ VI's tables are read only, meaning that you cannot overright their pairs. This is a workaround by using a proxy for the native table
---@param originalTable table
---@param overrides table
---@return table
function HijackTable(originalTable, overrides)
    if not originalTable then 
        print("Error: originalTable cannot be nil")
        return originalTable
    end

    local base = originalTable

    local proxy = setmetatable({}, {
        __index = function(_, key)
            if overrides[key] ~= nil then
                return overrides[key]
            end
            return base[key]
        end
    })

    return proxy
end

---Returns an array of keys from the table arg
---@param tbl table
---@return any[]
function GetKeys(tbl)
    if not tbl then return {} end
    local list = {}
    for k in pairs(tbl) do
        table.insert(list, k)
    end
    return list
end

