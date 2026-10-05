-- Operations on Lua collections; no game-state or UI dependencies.
CAICollection = {}

-- Count all keys, including sparse numeric and dictionary keys.
-- An absent optional collection has no entries.
function CAICollection.CountEntries(values)
    local count = 0
    if not values then return count end
    for _ in pairs(values) do count = count + 1 end
    return count
end

-- Missing values sort last; nonnumeric values use the display locale.
function CAICollection.CompareValues(a, b)
    if a == b then return 0 end
    if a == nil then return 1 end
    if b == nil then return -1 end
    if type(a) == "number" and type(b) == "number" then return a < b and -1 or 1 end
    return Locale.Compare(tostring(a), tostring(b))
end

function CAICollection.CompareTypedValues(a, b)
    if a == b then return 0 end
    if type(a) == "boolean" and type(b) == "boolean" then return a and 1 or -1 end
    return CAICollection.CompareValues(a, b)
end

function CAICollection.Keys(tbl)
    if not tbl then return {} end
    local list = {}
    for k in pairs(tbl) do
        table.insert(list, k)
    end
    return list
end

function CAICollection.Invert(tbl)
    local swapped = {}
    for k, v in pairs(tbl) do
        swapped[v] = k
    end
    return swapped
end
