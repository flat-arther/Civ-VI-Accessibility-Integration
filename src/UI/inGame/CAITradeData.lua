-- Shared trade queries. Vanilla and BTS yield contracts stay distinct.
CAITradeData = {}

function CAITradeData.HasTradeQuest(cityOwnerID)
    local questsManager = Game.GetQuestsManager()
    local localPlayerID = Game.GetLocalPlayer()
    if not questsManager or not localPlayerID then return false end
    local tradeQuestInfo = GameInfo.Quests["QUEST_SEND_TRADE_ROUTE"]
    if not tradeQuestInfo then return false end
    return questsManager:HasActiveQuestFromPlayer(localPlayerID, cityOwnerID, tradeQuestInfo.Index)
end

function CAITradeData.ResolveCity(playerID, cityID)
    local player = Players[playerID]
    if not player then return nil end
    return player:GetCities():FindID(cityID)
end

function CAITradeData.BuildPlayerHeaderTooltip(playerID)
    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == -1 or playerID == localPlayerID then return "" end

    local player = Players[playerID]
    local hasTradeRoute = false
    for _, city in player:GetCities():Members() do
        if city:GetTrade():HasTradeRouteFrom(localPlayerID) then
            hasTradeRoute = true
            break
        end
    end

    local parts = {}

    local baseTourismMod = GlobalParameters.TOURISM_TRADE_ROUTE_BONUS
    local extraTourismMod = Players[localPlayerID]:GetCulture():GetExtraTradeRouteTourismModifier()
    local tourismPct = "+" .. Locale.ToPercent((baseTourismMod + extraTourismMod) / 100)
    if hasTradeRoute then
        parts[#parts + 1] = Locale.Lookup("LOC_TRADE_OVERVIEW_TOOLTIP_TOURISM_BONUS") .. " " .. tourismPct
    else
        parts[#parts + 1] = Locale.Lookup("LOC_TRADE_OVERVIEW_TOOLTIP_NO_TOURISM_BONUS") .. " " .. tourismPct
    end

    if hasTradeRoute then
        parts[#parts + 1] = Locale.Lookup("LOC_TRADE_OVERVIEW_TOOLTIP_DIPLOMATIC_VIS_BONUS")
    else
        parts[#parts + 1] = Locale.Lookup("LOC_TRADE_OVERVIEW_TOOLTIP_NO_DIPLOMATIC_VIS_BONUS")
    end

    return table.concat(parts, "[NEWLINE]")
end

function CAITradeData.BuildAggregateYields(kRouteInfo)
    local yields = {}
    for yieldIndex = 1, #kRouteInfo.kYieldValues do
        local val = kRouteInfo.kYieldValues[yieldIndex]
        if val ~= 0 then
            local yInfo = GameInfo.Yields[yieldIndex - 1]
            if yInfo then
                local sign = val >= 0 and "+" or ""
                table.insert(yields, sign .. Round(val, 1) .. " " .. Locale.Lookup(yInfo.Name))
            end
        end
    end
    if kRouteInfo.MajorityReligion > 0 and kRouteInfo.ReligionPressure > 0 then
        local relInfo = GameInfo.Religions[kRouteInfo.MajorityReligion]
        if relInfo then
            local relName = Game.GetReligion():GetName(relInfo.Index)
            table.insert(yields,
                Locale.Lookup("LOC_CAI_TRADE_ROUTE_RELIGION_PRESSURE", kRouteInfo.ReligionPressure, relName))
        end
    end
    return table.concat(yields, "[NEWLINE]")
end

-- Bind only the BTS API at the screen boundary, after its TradeSupport include.
function CAITradeData.CreateYieldSummary(getOrigin, getDestination, firstIndex, lastIndex)
    return function(routeInfo, forDestination)
        local values, tooltips
        if forDestination then
            values, tooltips = getDestination(routeInfo, true)
        else
            values, tooltips = getOrigin(routeInfo, true)
        end
        local parts = {}
        for index = firstIndex, lastIndex do
            if values[index] and values[index] > 0 then
                table.insert(parts, tooltips[index])
            end
        end
        return table.concat(parts, "[NEWLINE]")
    end
end

function CAITradeData.DestinationName(city)
    local name = Locale.ToUpper(city:GetName())
    if city:IsCapital() and Players[city:GetOwner()]:IsMajor() then
        name = name .. ", " .. Locale.Lookup("LOC_CAI_CITY_STATUS_CAPITAL")
    end
    return name
end

function CAITradeData.RouteTooltip(origin, destination, originSummary, destinationSummary)
    local distance = Map.GetPlotDistance(origin:GetX(), origin:GetY(), destination:GetX(), destination:GetY())
    local parts = { Locale.Lookup("LOC_CAI_TRADE_ROUTE_DISTANCE", distance) }
    if originSummary ~= "" then
        parts[#parts + 1] = Locale.Lookup("LOC_ROUTECHOOSER_RECEIVES_RESOURCE",
            Locale.Lookup(origin:GetName())) .. " " .. originSummary
    end
    if destinationSummary ~= "" then
        parts[#parts + 1] = Locale.Lookup("LOC_ROUTECHOOSER_RECEIVES_RESOURCE",
            Locale.Lookup(destination:GetName())) .. " " .. destinationSummary
    end
    return table.concat(parts, "[NEWLINE]")
end
