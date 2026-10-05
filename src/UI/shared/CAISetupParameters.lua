-- Matching configuration-parameter contracts used by frontend setup screens.
CAISetupParameters = {}

function CAISetupParameters.Compare(a, b)
    if (a.SortIndex or 0) ~= (b.SortIndex or 0) then
        return (a.SortIndex or 0) < (b.SortIndex or 0)
    end
    return Locale.Compare(a.Name or "", b.Name or "") == -1
end

function CAISetupParameters.ValueMatches(a, b)
    if a == b then return true end
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    if a.QueryId ~= nil or b.QueryId ~= nil then
        return a.QueryId == b.QueryId and a.QueryIndex == b.QueryIndex
    end
    return a.Value == b.Value
end

function CAISetupParameters.InvalidReason(value)
    if not value or not value.Invalid then return "" end
    local reason = value.InvalidReason or "LOC_SETUP_ERROR_INVALID_OPTION"
    if reason == "" then return "" end
    return Locale.Lookup(reason)
end
