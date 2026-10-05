-- Score victory presentation; native capture and screen lifecycle stay in WorldRankings.
CAIRankingsScore = {}

---@param mgr UIScreenManager
---@param context CAIRankingsScoreContext
---@return CAIRankingsScorePresenter
function CAIRankingsScore.Create(mgr, context)
    local MakeTreeItem = context.MakeTreeItem
    local MakeStaticText = context.MakeStaticText
    local AddLeaf = context.AddLeaf
    local AddAdvisorLeaf = context.AddAdvisorLeaf
    local GetRankingsPlayerLabel = context.GetRankingsPlayerLabel
    local GetRankingsTeamLabel = context.GetRankingsTeamLabel
    local GatherScoreData = context.GatherScoreData
    local FormatContribution = context.FormatContribution
    local MakeCompetitorColumn = context.MakeCompetitorColumn
    local ConfigureRankingTable = context.ConfigureRankingTable

    local function CreateScorePlayerRow(playerData, parentFocusPrefix)
        local playerID = playerData.PlayerID
        local fk = (parentFocusPrefix or "") .. "player:" .. playerID
        local rowFactory = (#playerData.Categories > 0) and MakeTreeItem or MakeStaticText

        local item = rowFactory({
            Label = function()
                return CAIText.JoinLines({
                    GetRankingsPlayerLabel(playerID),
                    tostring(playerData.PlayerScore),
                })
            end,
            FocusKey = fk,
        })

        for _, cat in ipairs(playerData.Categories) do
            local catInfo = GameInfo.ScoringCategories[cat.CategoryID]
            if catInfo then
                local capturedCatID = cat.CategoryID
                local capturedScore = cat.CategoryScore
                AddLeaf(item, fk .. ":cat:" .. capturedCatID, function()
                    return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_SCORE_CATEGORY",
                        Locale.Lookup(catInfo.Name), capturedScore)
                end)
            end
        end

        return item
    end

    local function RebuildScoreTree(tree)
        local capturedRows = context.GetCapturedRows()
        local capture = mgr:CaptureFocusKey(tree)
        tree:ClearChildren()

        if capturedRows then
            for _, record in ipairs(capturedRows) do
                if record.Kind == "team" then
                    local teamData = record.TeamData
                    local teamItem = MakeTreeItem({
                        Label = function()
                            return CAIText.JoinLines({
                                GetRankingsTeamLabel(teamData.TeamID),
                                tostring(teamData.TeamScore),
                            })
                        end,
                        FocusKey = "team:" .. teamData.TeamID,
                    })
                    if #record.Children > 0 then
                        for _, child in ipairs(record.Children) do
                            teamItem:AddChild(CreateScorePlayerRow(child.PlayerData,
                                "team:" .. teamData.TeamID .. ":"))
                        end
                    else
                        for _, playerData in ipairs(teamData.PlayerData) do
                            teamItem:AddChild(CreateScorePlayerRow(playerData,
                                "team:" .. teamData.TeamID .. ":"))
                        end
                    end
                    tree:AddChild(teamItem)
                else
                    tree:AddChild(CreateScorePlayerRow(record.PlayerData, ""))
                end
            end
        else
            local scoreData = GatherScoreData()
            table.sort(scoreData, function(a, b) return a.TeamScore > b.TeamScore end)

            for _, teamData in ipairs(scoreData) do
                if #teamData.PlayerData > 1 then
                    table.sort(teamData.PlayerData, function(a, b) return a.PlayerScore > b.PlayerScore end)
                    local teamItem = MakeTreeItem({
                        Label = function()
                            return CAIText.JoinLines({
                                GetRankingsTeamLabel(teamData.TeamID),
                                tostring(teamData.TeamScore),
                            })
                        end,
                        FocusKey = "team:" .. teamData.TeamID,
                    })
                    for _, pd in ipairs(teamData.PlayerData) do
                        local row = CreateScorePlayerRow(pd, "team:" .. teamData.TeamID .. ":")
                        teamItem:AddChild(row)
                    end
                    tree:AddChild(teamItem)
                elseif #teamData.PlayerData > 0 then
                    tree:AddChild(CreateScorePlayerRow(teamData.PlayerData[1], ""))
                end
            end
        end

        AddAdvisorLeaf(tree, CAIText.JoinLines({
            Locale.Lookup("LOC_WORLD_RANKINGS_SCORE_DETAILS"),
            Locale.Lookup("LOC_WORLD_RANKINGS_SCORE_CONDITION", Game.GetMaxGameTurns())
        }))

        mgr:RestoreFocus(tree, capture)
    end

    local function GatherScoreTableRows()
        local capturedRows = context.GetCapturedRows()
        local rows = {}
        local scoreData = {}
        if capturedRows then
            for _, record in ipairs(capturedRows) do
                if record.Kind == "team" then
                    local playerData = {}
                    for _, child in ipairs(record.Children) do
                        table.insert(playerData, child.PlayerData)
                    end
                    table.insert(scoreData, {
                        TeamID = record.TeamData.TeamID,
                        TeamScore = record.TeamData.TeamScore,
                        PlayerData = #playerData > 0 and playerData or record.TeamData.PlayerData,
                    })
                else
                    local playerData = record.PlayerData
                    table.insert(scoreData, {
                        TeamID = Players[playerData.PlayerID]:GetTeam(),
                        TeamScore = playerData.PlayerScore,
                        PlayerData = { playerData },
                    })
                end
            end
        else
            scoreData = GatherScoreData()
        end

        for _, teamData in ipairs(scoreData) do
            local playerIDs = {}
            local categoryTotals = {}
            for _, playerData in ipairs(teamData.PlayerData) do
                table.insert(playerIDs, playerData.PlayerID)
                for _, category in ipairs(playerData.Categories) do
                    categoryTotals[category.CategoryID] =
                        (categoryTotals[category.CategoryID] or 0) + category.CategoryScore
                end
            end
            if #playerIDs > 0 then
                table.insert(rows, {
                    TeamID = teamData.TeamID,
                    PlayerIDs = playerIDs,
                    PlayerData = teamData.PlayerData,
                    TeamScore = teamData.TeamScore,
                    CategoryTotals = categoryTotals,
                })
            end
        end
        return rows
    end

    local function GetScoreContributionTooltip(competitor, categoryID)
        if #competitor.PlayerData <= 1 then return nil end
        local lines = {}
        for _, playerData in ipairs(competitor.PlayerData) do
            local value = playerData.PlayerScore
            if categoryID ~= nil then
                value = 0
                for _, category in ipairs(playerData.Categories) do
                    if category.CategoryID == categoryID then
                        value = category.CategoryScore
                        break
                    end
                end
            end
            table.insert(lines, FormatContribution(playerData.PlayerID, value))
        end
        return CAIText.JoinLines(lines)
    end

    local function RebuildScoreTable(tableView)
        local rows = GatherScoreTableRows()
        local columns = {
            MakeCompetitorColumn(),
            {
                key = "total",
                header = function() return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_TOTAL_SCORE") end,
                getCell = function(row) return tostring(row.TeamScore) end,
                getTooltip = function(row) return GetScoreContributionTooltip(row, nil) end,
                sortKey = function(row) return row.TeamScore end,
                sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST",
                sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST",
            },
        }

        local categoryIDs = {}
        for _, row in ipairs(rows) do
            for categoryID, _ in pairs(row.CategoryTotals) do categoryIDs[categoryID] = true end
        end
        for categoryInfo in GameInfo.ScoringCategories() do
            if categoryIDs[categoryInfo.Index] then
                local categoryID = categoryInfo.Index
                table.insert(columns, {
                    key = "category:" .. categoryID,
                    header = function() return Locale.Lookup(GameInfo.ScoringCategories[categoryID].Name) end,
                    getCell = function(row) return tostring(row.CategoryTotals[categoryID] or 0) end,
                    getTooltip = function(row) return GetScoreContributionTooltip(row, categoryID) end,
                    sortKey = function(row) return row.CategoryTotals[categoryID] or 0 end,
                    sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST",
                    sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST",
                })
            end
        end
        ConfigureRankingTable(tableView, columns, rows, { column = "total", ascending = false })
    end

        return { RebuildTree = RebuildScoreTree, RebuildTable = RebuildScoreTable }
end
