include("CAIControl")

-- Shared technology/civic data contracts. Readers resolve the current context
-- on demand; the API does not retain live records or displayed strings.
CAIResearchData = {}

function CAIResearchData.CostText(cost, tag)
    if cost and cost > 0 then return Locale.Lookup(tag, cost) end
    return nil
end

-- Chooser progress is already a ratio; tree live data supplies progress/cost.
function CAIResearchData.ProgressText(progress, tag)
    if not progress then return nil end
    local percent = math.floor(progress * 100 + 0.5)
    if percent <= 0 then return nil end
    return Locale.Lookup(tag, percent)
end

function CAIResearchData.DescriptionText(row)
    local description = row and row.Description
    if description and description ~= "" then
        local text = Locale.Lookup(description)
        if text and text ~= "" then return text end
    end
    return nil
end

-- Cache only database identities/topology. Column policy belongs to the adapter:
-- technology computes prerequisite depth; civics reads vanilla Column.
function CAIResearchData.BuildMaps(entries, getRow, getColumn, prereqStart)
    local leadsTo, indexToType, tierByType, eraColumns = {}, {}, {}, {}
    for itemType, entry in pairs(entries) do
        local row = getRow(itemType)
        if row then indexToType[row.Index] = itemType end
        for _, prerequisite in ipairs(entry.Prereqs or {}) do
            if prerequisite ~= prereqStart then
                leadsTo[prerequisite] = leadsTo[prerequisite] or {}
                table.insert(leadsTo[prerequisite], itemType)
            end
        end
        if entry.EraType then
            eraColumns[entry.EraType] = eraColumns[entry.EraType] or {}
            eraColumns[entry.EraType][getColumn(itemType, entry)] = true
        end
    end
    local ranks = {}
    for eraType, columnSet in pairs(eraColumns) do
        local columns = {}
        for column in pairs(columnSet) do columns[#columns + 1] = column end
        table.sort(columns)
        ranks[eraType] = {}
        for rank, column in ipairs(columns) do ranks[eraType][column] = rank end
    end
    for itemType, entry in pairs(entries) do
        local rank = entry.EraType and ranks[entry.EraType]
        tierByType[itemType] = rank and rank[getColumn(itemType, entry)] or nil
    end
    return leadsTo, indexToType, tierByType
end

---@param adapter CAIResearchDataAdapter
function CAIResearchData.Create(adapter)
    local function Name(itemType)
        local kLive = adapter.GetLiveData(itemType)
        if kLive and not kLive.IsRevealed then
            return Locale.Lookup(adapter.Text.Unrevealed)
        end
        local node = adapter.GetUiNode(itemType)
        local name = CAIControl.Text(node and node.NodeName)
        if name ~= "" then return name end
        local row = adapter.GetRow(itemType)
        if row and row.Name then return Locale.Lookup(row.Name) end
        return itemType
    end

    local function Cost(itemType)
        local live = adapter.GetLiveData(itemType)
        return CAIResearchData.CostText(live and live.Cost, adapter.Text.Cost)
    end

    local function Turns(itemType)
        local node = adapter.GetUiNode(itemType)
        if node and not CAIControl.IsHidden(node.Turns) then
            local raw = CAIControl.Text(node.Turns)
            local n = string.match(raw, "%[ICON_Turn%](%d+)")
            if n then return Locale.Lookup(adapter.Text.Turns, tonumber(n)) end
            if raw ~= "" then return raw end
        end
        local kLive = adapter.GetLiveData(itemType)
        if kLive and kLive.TurnsLeft and kLive.TurnsLeft >= 0 then
            return Locale.Lookup(adapter.Text.Turns, kLive.TurnsLeft)
        end
        return nil
    end

    local function Progress(itemType)
        local live = adapter.GetLiveData(itemType)
        if not live or not live.Progress or not live.Cost or live.Cost <= 0 then return nil end
        return CAIResearchData.ProgressText(live.Progress / live.Cost, adapter.Text.Progress)
    end

    local function Description(itemType)
        return CAIResearchData.DescriptionText(adapter.GetRow(itemType))
    end

    local function Boost(itemType)
        local kStatic = adapter.GetStatic(itemType)
        if not kStatic or not kStatic.IsBoostable then return nil end
        local kLive = adapter.GetLiveData(itemType)
        local prefix = Locale.Lookup((kLive and kLive.IsBoosted)
            and "LOC_BOOST_BOOSTED" or "LOC_BOOST_TO_BOOST")
        local trigger = kStatic.BoostText or ""
        if trigger == "" then return prefix end
        return prefix .. " " .. trigger
    end

    local function Status(kLive)
        if not kLive then return nil end
        local status = kLive.IsRevealed and kLive.Status or adapter.Statuses.UNREVEALED
        if status == adapter.Statuses.RESEARCHED then
            return Locale.Lookup(adapter.Text.Researched)
        elseif status == adapter.Statuses.CURRENT then
            return Locale.Lookup(adapter.Text.Current)
        elseif status == adapter.Statuses.BLOCKED then
            return Locale.Lookup(adapter.Text.Blocked)
        elseif status == adapter.Statuses.UNREVEALED then
            return Locale.Lookup(adapter.Text.HiddenStatus)
        end
        return nil
    end

    local function QueuePosition(itemType)
        local row = adapter.GetRow(itemType)
        if not row then return nil end
        local queue = adapter.GetQueue()
        if not queue then return nil end
        for i, id in ipairs(queue) do
            if id == row.Index then return i end
        end
        return nil
    end

    local function IsHidden(itemType)
        local kLive = adapter.GetLiveData(itemType)
        return kLive ~= nil and kLive.IsRevealed == false
    end

    local function LocationPrefix(itemType, currentEraType)
        local parts = {}
        local kEntry = adapter.GetStatic(itemType)
        if kEntry and kEntry.EraType and kEntry.EraType ~= currentEraType then
            local era = adapter.GetEra(kEntry.EraType)
            if era and era.Description then table.insert(parts, Locale.Lookup(era.Description)) end
        end
        local tier = adapter.GetTier(itemType)
        if tier then table.insert(parts, Locale.Lookup("LOC_CAI_TREE_TIER", tier)) end
        return parts
    end

    local function RelatedLabel(itemType, currentEraType)
        if not IsHidden(itemType) then return Name(itemType) end
        local prefix = LocationPrefix(itemType, currentEraType)
        local notRevealed = Locale.Lookup(adapter.Text.Unrevealed)
        if #prefix > 0 then return table.concat(prefix, "[NEWLINE]") .. " " .. notRevealed end
        return notRevealed
    end

    local function RelatedNames(itemTypes, currentEraType)
        local out, groupOrder, groups = {}, {}, {}
        for _, tt in ipairs(itemTypes) do
            if not IsHidden(tt) then
                table.insert(out, Name(tt))
            else
                local prefix = LocationPrefix(tt, currentEraType)
                local key = table.concat(prefix, "|")
                local g = groups[key]
                if not g then
                    g = { prefix = prefix, count = 0 }
                    groups[key] = g
                    table.insert(groupOrder, g)
                end
                g.count = g.count + 1
            end
        end
        local notRevealed = Locale.Lookup(adapter.Text.Unrevealed)
        for _, g in ipairs(groupOrder) do
            local prefixStr = table.concat(g.prefix, "[NEWLINE]")
            if g.count == 1 then
                table.insert(out, prefixStr ~= "" and (prefixStr .. " " .. notRevealed) or notRevealed)
            else
                local items = {}
                for _ = 1, g.count do table.insert(items, notRevealed) end
                local joined = table.concat(items, "[NEWLINE]")
                table.insert(out, prefixStr ~= "" and (prefixStr .. ": " .. joined) or joined)
            end
        end
        return out
    end

    local function CanResearch(itemType)
        local kLive = adapter.GetLiveData(itemType)
        if not kLive or not kLive.IsRevealed then return false end
        return kLive.Status == adapter.Statuses.READY
            or kLive.Status == adapter.Statuses.BLOCKED
    end

    local function IsRevealed(itemType)
        local kLive = adapter.GetLiveData(itemType)
        return kLive ~= nil and kLive.IsRevealed == true
    end

    return {
        Name = Name,
        Cost = Cost,
        Turns = Turns,
        Progress = Progress,
        Description = Description,
        Boost = Boost,
        Status = Status,
        QueuePosition = QueuePosition,
        IsHidden = IsHidden,
        LocationPrefix = LocationPrefix,
        RelatedLabel = RelatedLabel,
        RelatedNames = RelatedNames,
        CanResearch = CanResearch,
        IsRevealed = IsRevealed,
    }
end
