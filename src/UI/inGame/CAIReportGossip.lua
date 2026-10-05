-- Shared Gossip report section; owns collection, filter state and list construction.
CAIReportGossip = {}

---@param mgr UIScreenManager
---@param context CAIReportGossipContext
---@return CAIReportGossipController
function CAIReportGossip.Create(mgr, context)
    local m_caiGossipLog = {}
    local m_caiGossipFiltered = {}
    local m_caiLeaderFilter = -1
    local m_caiGroupFilter = "ALL"
    local m_gossipPlayerFilter = nil
    local m_gossipGroupFilter = nil

    local function GatherGossip()
        m_caiGossipLog = {}
        local playerID = context.GetLocalPlayerID()
        if playerID == nil or playerID == -1 then return end
        local pLocalPlayerDiplomacy = Players[playerID]:GetDiplomacy()
        if pLocalPlayerDiplomacy == nil then return end

        for targetID, kPlayer in pairs(Players) do
            if targetID ~= playerID and kPlayer:IsMajor() and pLocalPlayerDiplomacy:HasMet(targetID) then
                local kAppendTable = Game.GetGossipManager():GetRecentVisibleGossipStrings(0, playerID, targetID)
                for _, entry in pairs(kAppendTable) do
                    table.insert(m_caiGossipLog, entry)
                end
            end
        end

        table.sort(m_caiGossipLog, function(a, b) return a[2] > b[2] end)
    end

    local function FilterCAIGossip()
        m_caiGossipFiltered = {}
        for _, kEntry in ipairs(m_caiGossipLog) do
            local kGossipData = GameInfo.Gossips[kEntry[3]]
            if kGossipData then
                local passLeader = (m_caiLeaderFilter == -1 or kEntry[4] == m_caiLeaderFilter)
                local passGroup = (m_caiGroupFilter == "ALL" or m_caiGroupFilter == kGossipData.GroupType)
                if passLeader and passGroup then
                    table.insert(m_caiGossipFiltered, kEntry)
                end
            end
        end
    end


    local function RebuildGossipList(list)
        local capture = mgr:CaptureFocusKey(list)
        list:ClearChildren()

        if m_caiGossipFiltered == nil then return end

        for gi, kGossipEntry in ipairs(m_caiGossipFiltered) do
            local capturedEntry = kGossipEntry
            local capturedGI = gi
            local entryWidget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRPT_"), "StaticText", {
                Label = function()
                    local description = capturedEntry[1]
                    local turn = capturedEntry[2]
                    local targetPlayerID = capturedEntry[4]
                    local leaderName = ""
                    if targetPlayerID and PlayerConfigurations[targetPlayerID] then
                        leaderName = Locale.Lookup(PlayerConfigurations[targetPlayerID]:GetLeaderName())
                    end
                    return Locale.Lookup("LOC_CAI_REPORTS_GOSSIP_ENTRY", turn, leaderName, description)
                end,
                FocusKey = "gossip:" .. capturedGI,
            })
            list:AddChild(entryWidget)
        end

        mgr:RestoreFocus(list, capture)
    end

    -- Set by RebuildGossipTab so the gossip filter dropdowns can refresh their list
    -- without reaching into the variant-owned tab table.
    local m_sharedGossipTree = nil

    local function RefreshGossipListFromFilters()
        if m_sharedGossipTree then
            FilterCAIGossip()
            RebuildGossipList(m_sharedGossipTree)
        end
    end

    local function BuildGossipFilters(page, entry)
        -- Player filter dropdown
        local playerOptions = {}
        table.insert(playerOptions, { Label = Locale.Lookup("LOC_HUD_REPORTS_PLAYER_FILTER_ALL"), Value = -1 })

        local pLocalPlayerDiplomacy = Players[context.GetLocalPlayerID()]:GetDiplomacy()
        if pLocalPlayerDiplomacy then
            for targetID, kPlayer in pairs(Players) do
                if targetID ~= context.GetLocalPlayerID() and kPlayer:IsMajor() and pLocalPlayerDiplomacy:HasMet(targetID) then
                    table.insert(playerOptions, {
                        Label = Locale.Lookup(PlayerConfigurations[targetID]:GetLeaderName()),
                        Value = targetID,
                    })
                end
            end
        end

        local playerDropdownOptions = {}
        for _, opt in ipairs(playerOptions) do
            table.insert(playerDropdownOptions, { label = opt.Label, value = opt.Value })
        end

        m_gossipPlayerFilter = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRPT_"), "Dropdown", {
            Label = function() return Locale.Lookup("LOC_CAI_REPORTS_FILTER_PLAYER") end,
            FocusKey = "gossip:filter:player",
        })
        m_gossipPlayerFilter:SetOptions(playerDropdownOptions)
        for si, opt in ipairs(playerDropdownOptions) do
            if opt.value == m_caiLeaderFilter then
                m_gossipPlayerFilter:SetSelectedIndex(si, true); break
            end
        end
        m_gossipPlayerFilter:On("value_changed", function(w, val)
            m_caiLeaderFilter = val
            RefreshGossipListFromFilters()
        end)
        page:AddChild(m_gossipPlayerFilter)

        -- Group filter dropdown
        local groupOptions = {}
        table.insert(groupOptions, { Label = Locale.Lookup("LOC_HUD_REPORTS_FILTER_ALL"), Value = "ALL" })

        local seenGroups = {}
        for _, kEntry in ipairs(m_caiGossipLog) do
            local kGossipData = GameInfo.Gossips[kEntry[3]]
            if kGossipData and not seenGroups[kGossipData.GroupType] then
                seenGroups[kGossipData.GroupType] = true
                table.insert(groupOptions, {
                    Label = Locale.Lookup("LOC_HUD_REPORTS_FILTER_" .. kGossipData.GroupType),
                    Value = kGossipData.GroupType,
                })
            end
        end

        local groupDropdownOptions = {}
        for _, opt in ipairs(groupOptions) do
            table.insert(groupDropdownOptions, { label = opt.Label, value = opt.Value })
        end

        m_gossipGroupFilter = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRPT_"), "Dropdown", {
            Label = function() return Locale.Lookup("LOC_CAI_REPORTS_FILTER_TYPE") end,
            FocusKey = "gossip:filter:type",
        })
        m_gossipGroupFilter:SetOptions(groupDropdownOptions)
        for si, opt in ipairs(groupDropdownOptions) do
            if opt.value == m_caiGroupFilter then
                m_gossipGroupFilter:SetSelectedIndex(si, true); break
            end
        end
        m_gossipGroupFilter:On("value_changed", function(w, val)
            m_caiGroupFilter = val
            RefreshGossipListFromFilters()
        end)
        page:AddChild(m_gossipGroupFilter)
    end


    -- ============================================================================
    -- Shared Gossip Tab builder (used by both report variants)
    -- ============================================================================
    -- Records the current gossip tree so the filter dropdowns can refresh the list
    -- without reaching into a variant-owned tab table, then (re)builds the list and
    -- the filter widgets.
    local function RebuildGossipTab(entry)
        m_sharedGossipTree = entry.tree
        RebuildGossipList(entry.tree)

        local page = entry.page
        if not page then return end

        if not entry.filtersBuilt then
            BuildGossipFilters(page, entry)
            entry.filtersBuilt = true
        end
    end

    return { Gather = GatherGossip, Filter = FilterCAIGossip, Rebuild = RebuildGossipTab }
end
