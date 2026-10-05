include("CAIControl")

-- Shared chooser mechanics. Context state and vanilla callbacks stay in each screen.
CAIResearchChooser = {}

-- Readers are required because vanilla replaces the instance map and header
-- controls during refresh/close. A row can legitimately have no instance yet.
function CAIResearchChooser.CreateControls(readInstances, readCurrentControl)
    local function InstanceFor(data)
        if not data or not data.Hash then return nil end
        return readInstances()[data.Hash]
    end
    return {
        InstanceFor = InstanceFor,
        DisplayControl = function(data)
            local instance = InstanceFor(data)
            if instance then return instance end
            if data and data.IsCurrent then return readCurrentControl() end
            return nil
        end,
        RowIsHidden = function(data)
            local instance = InstanceFor(data)
            if not instance then return false end
            return CAIControl.IsHidden(instance.TopContainer) or CAIControl.IsHidden(instance.Top)
        end,
        RowIsDisabled = function(data)
            local instance = InstanceFor(data)
            if not instance then return false end
            return CAIControl.IsDisabled(instance.Top)
        end,
    }
end

function CAIResearchChooser.HasQueuePosition(kData)
    if not kData or kData.IsCurrent then return false end
    local p = kData.ResearchQueuePosition
    return p ~= nil and p ~= -1 and p ~= 99
end

function CAIResearchChooser.IsQueuedOrCurrent(kData)
    return kData.IsCurrent or CAIResearchChooser.HasQueuePosition(kData)
end

function CAIResearchChooser.IsJustCompleted(kData)
    return kData and kData.IsLastCompleted and not kData.IsCurrent or false
end

function CAIResearchChooser.GetBoostText(kData)
    if not kData or not kData.Boostable then return nil end
    local trigger = kData.TriggerDesc and Locale.Lookup(kData.TriggerDesc) or ""
    local prefix = Locale.Lookup(kData.BoostTriggered and "LOC_BOOST_BOOSTED" or "LOC_BOOST_TO_BOOST")
    if trigger == "" then return prefix end
    return prefix .. " " .. trigger
end

-- Readers resolve current screen state on every call; no controls or displayed values are cached.
---@param getCurrentTurnsLeft fun():number|nil
---@param displayControl fun(data:table):table|nil
function CAIResearchChooser.GetTurnsText(kData, getCurrentTurnsLeft, displayControl)
    -- A just-completed item has no remaining turns; reporting a count reads as
    -- a still-pending queue item.
    if CAIResearchChooser.IsJustCompleted(kData) then return nil end
    if kData.IsCurrent then
        local n = getCurrentTurnsLeft()
        if n and n >= 0 then return Locale.Lookup("LOC_CAI_RESEARCH_TURNS", n) end
    end
    local inst = displayControl(kData)
    if inst then
        local t = CAIControl.Text(inst.TurnsLeft)
        local n = string.match(t, "%[ICON_Turn%](%d+)")
        if n then return Locale.Lookup("LOC_CAI_RESEARCH_TURNS", tonumber(n)) end
        if t ~= "" then return t end
    end
    if kData.TurnsLeft and kData.TurnsLeft >= 0 then
        return Locale.Lookup("LOC_CAI_RESEARCH_TURNS", kData.TurnsLeft)
    end
    return nil
end

---@param mgr UIScreenManager
---@param tree UIWidget|nil
---@param rows table[]
---@param interactive boolean
---@param createRow fun(data:table, interactive:boolean):UIWidget
function CAIResearchChooser.RebuildTree(mgr, tree, rows, interactive, createRow)
    if not tree then return end
    local capture = mgr:CaptureFocusKey(tree)
    tree:ClearChildren()
    for _, kData in ipairs(rows) do
        tree:AddChild(createRow(kData, interactive))
    end
    mgr:RestoreFocus(tree, capture)
end

-- Header data can be absent from available rows, including just-completed research.
function CAIResearchChooser.PartitionRows(rows, currentData)
    local queueRows = {}
    local availableRows = {}
    for _, kData in ipairs(rows) do
        if CAIResearchChooser.IsQueuedOrCurrent(kData) then
            table.insert(queueRows, kData)
        else
            table.insert(availableRows, kData)
        end
    end
    table.sort(queueRows, function(a, b)
        if a.IsCurrent ~= b.IsCurrent then return a.IsCurrent == true end
        return (a.ResearchQueuePosition or 0) < (b.ResearchQueuePosition or 0)
    end)
    if currentData then
        local already = false
        for _, r in ipairs(queueRows) do
            if r.Hash == currentData.Hash then
                already = true
                break
            end
        end
        if not already then table.insert(queueRows, 1, currentData) end
    end

    return queueRows, availableRows
end
