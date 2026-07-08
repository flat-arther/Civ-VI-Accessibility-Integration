-- global access to the 'CAI' table, lives on 'ExposedMembers' and created by the dll
CAI = ExposedMembers.CAI

include("iconsProcessing")
include("CAISettings")


---Utility wrapper for 'CAI.output'
---@param text string -- the text to speak
---@param interrupt? boolean -- whether to interrupt any currently speaking text. False by default
---@param processTokens? boolean -- run ProcessIcons on text before speaking. True by default
function Speak(text, interrupt, processTokens)
    if CAI and CAI.Output then
        local out = tostring(text)
        if processTokens ~= false then out = ProcessIcons(out) end
        CAI.Output(out, interrupt)
    end
end

---Speak each line in turn. If interrupt is true, only the first line interrupts
---ongoing speech; the rest are queued so they don't cut each other off. Used
---by the manager so focus changes interrupt prior speech without breaking the
---one-line-per-widget Windows screen-reader model.
---@param lines string[]
---@param interrupt? boolean
---@param processTokens? boolean
function SpeakLines(lines, interrupt, processTokens)
    if not lines or #lines == 0 then return end
    for i, line in ipairs(lines) do
        if line and line ~= "" then
            Speak(line, interrupt and i == 1, processTokens)
        end
    end
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

---Returns a list of input action ids given a category string
---@param cat string
---@return number[]
function GetInputActionsByCategory(cat)
    local count = Input.GetActionCount()
    local actions = {}
    for i = 0, count - 1, 1 do
        local action = Input.GetActionId(i);
        local category = Input.GetActionCategory(action)
        if category == cat and Input then
            table.insert(actions, action)
        end
    end
    return actions
end

function SwapPairs(tbl)
    local swapped = {}
    for k, v in pairs(tbl) do
        swapped[v] = k
    end
    return swapped
end
