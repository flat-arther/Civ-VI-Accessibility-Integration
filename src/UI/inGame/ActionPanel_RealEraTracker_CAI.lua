-- Optional Real Era Tracker extension, included after ActionPanel's reader.
GetEraScoreDetailsLines = WrapFunc(GetEraScoreDetailsLines, function(orig)
    local lines = orig()
    if #lines == 0 then return lines end
    local tracker = ExposedMembers.CAIRealEraTracker
    if tracker == nil then
        LogWarn("Real Era Tracker readout provider is not initialized")
        return lines
    end
    for _, line in ipairs(tracker.GetFavoredLines(Game.GetLocalPlayer())) do
        lines[#lines + 1] = line
    end
    return lines
end)
