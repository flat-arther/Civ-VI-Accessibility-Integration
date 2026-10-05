-- Generic/custom victory trees preserve native presentation and explicit data adapters.
CAIRankingsGeneric = {}

---@param mgr UIScreenManager
---@param context CAIRankingsGenericContext
---@return CAIRankingsGenericPresenter
function CAIRankingsGeneric.Create(mgr, context)
    local REQUIREMENT_CONTEXT = "VictoryProgress"
    local m_isExp2 = context.IsExpansion2
    local m_isBBG = context.IsBBG
    local BBG_TRAD_DOM_VICTORY = context.TraditionalDominationVictory
    local MakeTreeItem = context.MakeTreeItem
    local MakeStaticText = context.MakeStaticText
    local AddLeaf = context.AddLeaf
    local AddAdvisorLeaf = context.AddAdvisorLeaf
    local GetRankingsPlayerLabel = context.GetRankingsPlayerLabel
    local GetRankingsTeamLabel = context.GetRankingsTeamLabel
    local GetGenericVictoryRows = context.GetGenericVictoryRows
    local GatherGenericData = context.GatherGenericData

    local function CreateGenericPlayerRow(playerData, victoryType, parentFocusPrefix, presentation)
        local playerID = playerData.PlayerID
        local fk = (parentFocusPrefix or "") .. "player:" .. playerID

        local capturedVictoryType = victoryType
        local diploLines = {}
        if capturedVictoryType == "VICTORY_DIPLOMATIC" and m_isExp2 then
            local pPlayer = Players[playerID]
            if pPlayer and pPlayer:IsAlive() then
                local pStats = pPlayer:GetStats()
                if pStats and pStats.GetDiplomaticVictoryPointsTooltip then
                    local tt = pStats:GetDiplomaticVictoryPointsTooltip()
                    if tt and tt ~= "" then
                        for segment in (tt .. "[NEWLINE]"):gmatch("(.-)%[NEWLINE%]") do
                            local trimmed = segment:match("^%s*(.-)%s*$")
                            CAIText.AppendIfNonEmpty(diploLines, trimmed)
                        end
                    end
                end
            end
        end

        -- BBG's Traditional Domination rows already merge the domination progress
        -- percentage with the requirement text in their captured Details. Re-deriving
        -- requirement lines here would drop that percentage and duplicate the
        -- requirement text, so defer entirely to the captured details for that victory.
        local requirementLines = {}
        if not (m_isBBG and capturedVictoryType == BBG_TRAD_DOM_VICTORY) then
            local pTeamID = Players[playerID]:GetTeam()
            local requirementSetID = Game.GetVictoryRequirements(pTeamID, capturedVictoryType)
            if requirementSetID and requirementSetID ~= -1 then
                local innerReqs = GameEffects.GetRequirementSetInnerRequirements(requirementSetID)
                if innerReqs then
                    for _, reqID in ipairs(innerReqs) do
                        local reqKey = GameEffects.GetRequirementTextKey(reqID, REQUIREMENT_CONTEXT)
                        if reqKey then
                            local reqText = GameEffects.GetRequirementText(reqID, reqKey)
                            if reqText and reqText ~= "" then
                                table.insert(requirementLines, { ReqID = reqID, Text = reqText })
                            end
                        end
                    end
                end
            end
        end

        local capturedDetails = presentation and presentation.Details or {}
        local hasCapturedDetails = #requirementLines == 0 and #capturedDetails > 0
        local rowFactory = (#diploLines > 0 or #requirementLines > 0 or hasCapturedDetails)
            and MakeTreeItem or MakeStaticText

        local item = rowFactory({
            Label = function()
                local parts = { GetRankingsPlayerLabel(playerID) }
                if presentation and #presentation.Values > 0 then
                    for _, value in ipairs(presentation.Values) do
                        table.insert(parts, value)
                    end
                elseif playerData.PlayerScore ~= nil then
                    table.insert(parts, tostring(playerData.PlayerScore))
                end
                if capturedVictoryType == "VICTORY_DIPLOMATIC" and m_isExp2 then
                    local pPlayer = Players[playerID]
                    if pPlayer and pPlayer:IsAlive() then
                        local current = pPlayer:GetStats():GetDiplomaticVictoryPoints()
                        local total = GlobalParameters.DIPLOMATIC_VICTORY_POINTS_REQUIRED
                        table.insert(parts, Locale.Lookup("LOC_CAI_WORLD_RANKINGS_DIPLO_POINTS", current, total))
                    end
                end
                return CAIText.JoinLines(parts)
            end,
            Tooltip = presentation and #presentation.Tooltips > 0
                and function() return CAIText.JoinLines(presentation.Tooltips) end or nil,
            FocusKey = fk,
        })

        for li, line in ipairs(diploLines) do
            AddLeaf(item, fk .. ":diplo:" .. li, function() return line end)
        end

        for ri, reqEntry in ipairs(requirementLines) do
            local capturedReqID = reqEntry.ReqID
            local capturedReqText = reqEntry.Text
            AddLeaf(item, fk .. ":req:" .. ri, function()
                local state = GameEffects.GetRequirementState(capturedReqID)
                local isMet = (state == "Met" or state == "AlwaysMet")
                if isMet then
                    return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_COMPLETE_REQ", capturedReqText)
                else
                    return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_INCOMPLETE_REQ", capturedReqText)
                end
            end)
        end

        if hasCapturedDetails then
            for di, detail in ipairs(capturedDetails) do
                local capturedDetail = detail
                AddLeaf(item, fk .. ":detail:" .. di, function() return capturedDetail end)
            end
        end

        return item
    end

    local function CreateCapturedGenericRecord(record, victoryType, parentFocusPrefix)
        if record.Kind == "player" then
            return CreateGenericPlayerRow(record.PlayerData, victoryType,
                parentFocusPrefix, record.Presentation)
        end

        local teamData = record.TeamData
        local fk = "team:" .. teamData.TeamID
        local presentation = record.Presentation
        local teamItem = MakeTreeItem({
            Label = function()
                local parts = {
                    GetRankingsTeamLabel(teamData.TeamID),
                }
                if presentation and #presentation.Values > 0 then
                    for _, value in ipairs(presentation.Values) do
                        table.insert(parts, value)
                    end
                elseif teamData.TeamScore ~= nil then
                    table.insert(parts, tostring(teamData.TeamScore))
                end
                return CAIText.JoinLines(parts)
            end,
            Tooltip = presentation and #presentation.Tooltips > 0
                and function() return CAIText.JoinLines(presentation.Tooltips) end or nil,
            FocusKey = fk,
        })

        if #record.Children > 0 then
            for _, child in ipairs(record.Children) do
                teamItem:AddChild(CreateCapturedGenericRecord(child, victoryType, fk .. ":"))
            end
        else
            for _, playerData in ipairs(teamData.PlayerData) do
                teamItem:AddChild(CreateGenericPlayerRow(playerData, victoryType, fk .. ":"))
            end
        end

        if presentation then
            for di, detail in ipairs(presentation.Details) do
                local capturedDetail = detail
                AddLeaf(teamItem, fk .. ":detail:" .. di, function() return capturedDetail end)
            end
        end

        return teamItem
    end

    local function GetBestDiploScore(teamData)
        local best = 0
        for _, pd in ipairs(teamData.PlayerData) do
            local pPlayer = Players[pd.PlayerID]
            if pPlayer and pPlayer:IsAlive() then
                local pts = pPlayer:GetStats():GetDiplomaticVictoryPoints()
                if pts > best then best = pts end
            end
        end
        return best
    end

    local function RebuildGenericTree(tree, victoryType)
        local capture = mgr:CaptureFocusKey(tree)
        tree:ClearChildren()

        local capturedRows = GetGenericVictoryRows(victoryType)
        if capturedRows then
            for _, record in ipairs(capturedRows) do
                tree:AddChild(CreateCapturedGenericRecord(record, victoryType, ""))
            end
        else
            local genericData = GatherGenericData()

            if victoryType == "VICTORY_DIPLOMATIC" and m_isExp2 then
                for _, td in ipairs(genericData) do
                    td.DiplomaticScore = GetBestDiploScore(td)
                end
                table.sort(genericData, function(a, b) return a.DiplomaticScore > b.DiplomaticScore end)
            end

            for _, teamData in ipairs(genericData) do
                if #teamData.PlayerData > 1 then
                    local teamItem = MakeTreeItem({
                        Label = function()
                            return GetRankingsTeamLabel(teamData.TeamID)
                        end,
                        FocusKey = "team:" .. teamData.TeamID,
                    })
                    for _, pd in ipairs(teamData.PlayerData) do
                        teamItem:AddChild(CreateGenericPlayerRow(pd, victoryType,
                            "team:" .. teamData.TeamID .. ":"))
                    end
                    tree:AddChild(teamItem)
                elseif #teamData.PlayerData > 0 then
                    tree:AddChild(CreateGenericPlayerRow(teamData.PlayerData[1], victoryType, ""))
                end
            end
        end

        local victoryInfo = GameInfo.Victories[victoryType]
        if victoryInfo and victoryInfo.Description then
            local advisorText = Locale.Lookup(victoryInfo.Description)
            if m_isBBG and victoryType == BBG_TRAD_DOM_VICTORY then
                -- Mirror BBG's header, which appends the required domination threshold.
                advisorText = advisorText
                    .. Locale.Lookup("LOC_WORLD_RANKINGS_TRADITIONAL_DOMINATION_DESC_LAST")
                    .. " [COLOR_RED]" .. tostring(GameConfiguration.GetValue("TRADITIONAL_DOMINATION_LEVEL"))
                    .. " %[ENDCOLOR]"
            end
            AddAdvisorLeaf(tree, advisorText)
        end

        mgr:RestoreFocus(tree, capture)
    end

        return { RebuildTree = RebuildGenericTree }
end
