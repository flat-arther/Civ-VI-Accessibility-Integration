include("caiUtils")
include("Civ6Common")

-- Better Balanced Game (BBG) also replaces the WorldRankings context with its own
-- wrapper (worldrankings_bbg.lua) that adds a Traditional Domination victory tab.
-- Only one ReplaceUIScript wins per context, so when BBG is active we chain-include
-- its file instead of vanilla and layer CAI accessibility on top of it. BBG has
-- shipped under three historical mod IDs.
local BBG_MOD_IDS = {
    "cb84075d-5007-4207-b662-c35a5f7be240", -- iElden (current)
    "cb84075d-5007-4207-b662-c35a5f7be217", -- codenaugh
    "cb84075d-5007-4207-b662-c35a5f7be231", -- beta
}
local function IsBBGActive()
    for _, id in ipairs(BBG_MOD_IDS) do
        if Modding.IsModActive(id) then return true end
    end
    return false
end

if GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_WARMACHINE" then
    include("WorldRankings_WarMachineScenario")
elseif GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_VIKINGS" then
    include("WorldRankings_VikingsScenario")
elseif GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_POLAND" then
    include("WorldRankings_PolandScenario")
elseif GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_INDONESIA_KHMER" then
    include("WorldRankings_Indonesia_KhmerScenario")
elseif GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_BLACKDEATH" then
    include("WorldRankings_BlackDeathScenario")
elseif GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_AUSTRALIA" then
    include("WorldRankings_AustraliaScenario")
elseif GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_ALEXANDER" then
    include("WorldRankings_AlexanderScenario")
elseif GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_NUBIA" then
    include("WorldRankings_NubiaScenario")
elseif IsBBGActive() then
    -- BBG registers worldrankings_bbg.lua only in <Files> and a losing
    -- <ReplaceUIScript>, never in <ImportFiles>, so a runtime include() cannot
    -- resolve BBG's own copy. We instead include CAI's vendored verbatim copy
    -- (registered in CAI's <Files> + <ImportFiles>). It internally includes
    -- WorldRankings_Expansion2 or vanilla WorldRankings just like BBG's original.
    include("WorldRankings_BetterBalancedGame_CAIBase")
elseif IsExpansion2Active() then
    include("WorldRankings_Expansion2")
elseif IsExpansion1Active() then
    include("WorldRankings_Expansion1")
else
    include("WorldRankings")
end

local mgr                         = ExposedMembers.CAI_UIManager
local CAI_TAB_SCORE               = TAB_SCORE or Locale.Lookup("LOC_WORLD_RANKINGS_SCORE_TAB")
local CAI_TAB_OVERALL             = TAB_OVERALL or Locale.Lookup("LOC_WORLD_RANKINGS_OVERALL_TAB")
local CAI_TAB_SCIENCE             = TAB_SCIENCE or Locale.Lookup("LOC_WORLD_RANKINGS_SCIENCE_TAB")
local CAI_TAB_CULTURE             = TAB_CULTURE or Locale.Lookup("LOC_WORLD_RANKINGS_CULTURE_TAB")
local CAI_TAB_RELIGION            = TAB_RELIGION or Locale.Lookup("LOC_WORLD_RANKINGS_RELIGION_TAB")
local CAI_TAB_DOMINATION          = TAB_DOMINATION or Locale.Lookup("LOC_WORLD_RANKINGS_DOMINATION_TAB")

-- ============================================================================
-- Constants
-- ============================================================================
local PANEL_ID                    = "CAIWorldRank_Panel"
local TABS_ID                     = "CAIWorldRank_Tabs"
local SWITCH_VIEW_ID              = "CAIWorldRank_SwitchView"
local VIEW_SETTING_SECTION        = "UI"
local VIEW_SETTING_ID             = "WorldRankingsViewMode"
local HOVER_SOUND                 = "Main_Menu_Mouse_Over"

local REQUIREMENT_CONTEXT         = "VictoryProgress"

-- ============================================================================
-- State
-- ============================================================================
local m_panel                     = nil
local m_tabs                      = nil
local m_trees                     = {}
local m_switchView                = nil
local m_capturedTabs              = {}
local m_isMirroringTab            = false
local m_currentGenericVictoryType = nil
local m_pendingVictoryType        = nil
local m_genericCapture            = nil
local m_genericCapturedRows       = {}
local m_scoreCapture              = nil
local m_scoreCapturedRows         = nil
local m_genericVictoryAdapters    = {}

local function LoadViewModeSetting()
    local stored = tostring(CAI.GetConfigValue(
        VIEW_SETTING_SECTION, VIEW_SETTING_ID, "table")):lower()
    if stored == "tree" then return "tree" end
    if stored ~= "table" then
        LogWarn("World Rankings ignored invalid saved view mode " .. tostring(stored))
    end
    return "table"
end

local function SaveViewModeSetting(viewMode)
    if not CAI.SetConfigValue(VIEW_SETTING_SECTION, VIEW_SETTING_ID, viewMode) then
        LogError("World Rankings failed to save view mode " .. tostring(viewMode))
    end
end

local m_viewMode                  = LoadViewModeSetting()

local m_isExp2                    = (IsExpansion2Active ~= nil and IsExpansion2Active())
local m_isBBG                     = IsBBGActive()

-- BBG's Traditional Domination custom victory. Its tab label is the button tooltip
-- string (not the victory Name), so it needs bespoke matching like diplomatic does.
local BBG_TRAD_DOM_VICTORY        = "VICTORY_TRADITIONAL_DOMINATION"
local BBG_TRAD_DOM_BUTTON_KEY     = "LOC_TOOLTIP_TRADITIONAL_DOMINATION_BUTTON"

-- ============================================================================
-- Helpers
-- ============================================================================
local function MakeId(prefix)
    return mgr:GenerateWidgetId(prefix)
end

local function MakeTreeItem(props)
    local item = mgr:CreateWidget(MakeId("CAIWR_"), "TreeItem", props)
    item:SetFocusSound(HOVER_SOUND)
    return item
end

local function MakeStaticText(props)
    local item = mgr:CreateWidget(MakeId("CAIWR_"), "StaticText", props)
    item:SetFocusSound(HOVER_SOUND)
    return item
end

local function AddLeaf(parent, focusKey, labelFn)
    local item = MakeStaticText({
        Label = labelFn,
        FocusKey = focusKey,
    })
    parent:AddChild(item)
    return item
end

local function AddAdvisorLeaf(tree, text)
    AddLeaf(tree, "advisor", function() return text end)
end

local function JoinLines(parts)
    local filtered = {}
    for _, part in ipairs(parts) do
        if part and part ~= "" then
            table.insert(filtered, part)
        end
    end
    return table.concat(filtered, "[NEWLINE]")
end

local function AddUniqueText(target, seen, text)
    if text and text ~= "" and not seen[text] then
        seen[text] = true
        table.insert(target, text)
    end
end

local function ReadVisibleControlText(control)
    if not control or not control.IsHidden or not control.GetText or control:IsHidden() then
        return nil
    end
    return control:GetText()
end

local function ReadVisibleControlTooltip(control)
    if not control or not control.IsHidden or not control.GetToolTipString or control:IsHidden() then
        return nil
    end
    return control:GetToolTipString()
end

local PRESENTATION_IGNORED_KEYS = {
    CivilizationIcon = true,
    CivName = true,
    TeamName = true,
    CivIcon = true,
    CivIconBacking = true,
    LeaderIcon = true,
    TeamIcon = true,
}

local PRESENTATION_DETAIL_KEYS = {
    Details = true,
    Description = true,
    Requirement = true,
    Requirements = true,
}

local function CaptureInstancePresentation(instance)
    local presentation = { Values = {}, Details = {}, Tooltips = {} }
    local seenValues = {}
    local seenDetails = {}
    local seenTooltips = {}
    local visited = {}

    local function Visit(value, key, depth)
        if type(value) ~= "table" or visited[value] or depth > 4 then return end
        visited[value] = true

        if value.IsHidden and value.GetText then
            local text = ReadVisibleControlText(value)
            if PRESENTATION_DETAIL_KEYS[key] then
                AddUniqueText(presentation.Details, seenDetails, text)
            else
                AddUniqueText(presentation.Values, seenValues, text)
            end
            AddUniqueText(presentation.Tooltips, seenTooltips, ReadVisibleControlTooltip(value))
            return
        end

        for childKey, child in pairs(value) do
            local isInstanceManager = type(childKey) == "string" and string.sub(childKey, -2) == "IM"
            if not PRESENTATION_IGNORED_KEYS[childKey] and not isInstanceManager then
                Visit(child, childKey, depth + 1)
            end
        end
    end

    Visit(instance, nil, 0)
    return presentation
end

local function GetCaptureTarget(capture)
    local parent = capture.ParentStack[#capture.ParentStack]
    return parent or capture.Rows
end

local function BeginGenericCapture(victoryType)
    m_genericCapture = {
        VictoryType = victoryType,
        Rows = {},
        ParentStack = {},
    }
end

local function EndGenericCapture(victoryType)
    local capture = m_genericCapture
    m_genericCapture = nil
    if capture and capture.VictoryType == victoryType and #capture.Rows > 0 then
        m_genericCapturedRows[victoryType] = capture.Rows
    else
        m_genericCapturedRows[victoryType] = nil
    end
end

local function BeginScoreCapture()
    m_scoreCapture = { Rows = {}, ParentStack = {} }
end

local function EndScoreCapture()
    local capture = m_scoreCapture
    m_scoreCapture = nil
    if capture and #capture.Rows > 0 then
        m_scoreCapturedRows = capture.Rows
    else
        m_scoreCapturedRows = nil
    end
end

local function RegisterGenericVictoryAdapter(victoryType, adapter)
    if type(victoryType) ~= "string" or type(adapter) ~= "table"
        or type(adapter.GetRows) ~= "function" then
        print("CAI WorldRankings: invalid generic victory adapter registration")
        return false
    end
    m_genericVictoryAdapters[victoryType] = adapter
    return true
end

local function GetGenericVictoryRows(victoryType)
    local capturedRows = m_genericCapturedRows[victoryType]
    local adapter = m_genericVictoryAdapters[victoryType]
    if not adapter then return capturedRows end

    local ok, rows = pcall(adapter.GetRows, victoryType, capturedRows)
    if not ok then
        print("CAI WorldRankings: generic victory adapter failed for "
            .. victoryType .. ": " .. tostring(rows))
        return capturedRows
    end
    if rows ~= nil and type(rows) ~= "table" then
        print("CAI WorldRankings: generic victory adapter returned invalid rows for " .. victoryType)
        return capturedRows
    end
    return rows
end

ExposedMembers.CAIWorldRankings = ExposedMembers.CAIWorldRankings or {}
ExposedMembers.CAIWorldRankings.RegisterGenericVictoryAdapter = RegisterGenericVictoryAdapter

PopulateGenericInstance = WrapFunc(PopulateGenericInstance,
    function(orig, instance, playerData, victoryType, showTeamDetails)
        orig(instance, playerData, victoryType, showTeamDetails)
        if m_genericCapture then
            table.insert(GetCaptureTarget(m_genericCapture), {
                Kind = "player",
                PlayerData = playerData,
                Presentation = CaptureInstancePresentation(instance),
            })
        end
    end)

PopulateGenericTeamInstance = WrapFunc(PopulateGenericTeamInstance,
    function(orig, instance, teamData, victoryType)
        if not m_genericCapture then
            orig(instance, teamData, victoryType)
            return
        end

        local record = {
            Kind = "team",
            TeamData = teamData,
            Children = {},
        }
        table.insert(GetCaptureTarget(m_genericCapture), record)
        table.insert(m_genericCapture.ParentStack, record.Children)
        orig(instance, teamData, victoryType)
        table.remove(m_genericCapture.ParentStack)
        record.Presentation = CaptureInstancePresentation(instance)
    end)

PopulateScoreInstance = WrapFunc(PopulateScoreInstance,
    function(orig, instance, playerData)
        orig(instance, playerData)
        if m_scoreCapture then
            table.insert(GetCaptureTarget(m_scoreCapture), {
                Kind = "player",
                PlayerData = playerData,
                Presentation = CaptureInstancePresentation(instance),
            })
        end
    end)

PopulateScoreTeamInstance = WrapFunc(PopulateScoreTeamInstance,
    function(orig, instance, teamData)
        if not m_scoreCapture then
            orig(instance, teamData)
            return
        end

        local record = {
            Kind = "team",
            TeamData = teamData,
            Children = {},
        }
        table.insert(GetCaptureTarget(m_scoreCapture), record)
        table.insert(m_scoreCapture.ParentStack, record.Children)
        orig(instance, teamData)
        table.remove(m_scoreCapture.ParentStack)
        record.Presentation = CaptureInstancePresentation(instance)
    end)

-- BBG renders Traditional Domination rows through its own populators rather than
-- the vanilla generic ones wrapped above, so those capture wraps never fire for
-- that tab. Mirror them onto BBG's functions so the per-row domination progress
-- text and tile-count tooltip reach the reader. Guarded because these globals only
-- exist when BBG is loaded.
if PopulateTradDomInstance then
    PopulateTradDomInstance = WrapFunc(PopulateTradDomInstance,
        function(orig, instance, playerData, victoryType, showTeamDetails)
            orig(instance, playerData, victoryType, showTeamDetails)
            if m_genericCapture then
                table.insert(GetCaptureTarget(m_genericCapture), {
                    Kind = "player",
                    PlayerData = playerData,
                    Presentation = CaptureInstancePresentation(instance),
                })
            end
        end)
end

if PopulateTradDomTeamInstance then
    PopulateTradDomTeamInstance = WrapFunc(PopulateTradDomTeamInstance,
        function(orig, instance, teamData, victoryType)
            if not m_genericCapture then
                orig(instance, teamData, victoryType)
                return
            end
            local record = {
                Kind = "team",
                TeamData = teamData,
                Children = {},
            }
            table.insert(GetCaptureTarget(m_genericCapture), record)
            table.insert(m_genericCapture.ParentStack, record.Children)
            orig(instance, teamData, victoryType)
            table.remove(m_genericCapture.ParentStack)
            record.Presentation = CaptureInstancePresentation(instance)
        end)
end

local VIEW_CONTROL_TO_TAB = {
    { control = "OverallView",    label = CAI_TAB_OVERALL },
    { control = "ScoreView",      label = CAI_TAB_SCORE },
    { control = "ScienceView",    label = CAI_TAB_SCIENCE },
    { control = "CultureView",    label = CAI_TAB_CULTURE },
    { control = "DominationView", label = CAI_TAB_DOMINATION },
    { control = "ReligionView",   label = CAI_TAB_RELIGION },
}

local function DetectActiveTab()
    for _, mapping in ipairs(VIEW_CONTROL_TO_TAB) do
        local ctrl = Controls[mapping.control]
        if ctrl and not ctrl:IsHidden() then
            for i, tabDef in ipairs(m_capturedTabs) do
                if tabDef.label == mapping.label then
                    return i, tabDef.victoryType
                end
            end
        end
    end
    if Controls.GenericView and not Controls.GenericView:IsHidden() then
        if m_currentGenericVictoryType then
            for i, tabDef in ipairs(m_capturedTabs) do
                if tabDef.victoryType == m_currentGenericVictoryType then
                    return i, tabDef.victoryType
                end
            end
        end
    end
    return 1, nil
end

local function IsPlayerKnownToLocal(playerID)
    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == -1 or playerID == localPlayerID then
        return true
    end

    local playerConfig = PlayerConfigurations[playerID]
    if not playerConfig then
        return false
    end

    if playerConfig:IsHuman() and GameConfiguration.IsAnyMultiplayer() then
        return true
    end

    local localPlayer = Players[localPlayerID]
    if not localPlayer then
        return false
    end

    local diplomacy = localPlayer:GetDiplomacy()
    return diplomacy and diplomacy:HasMet(playerID)
end

local function GetPlayerLabel(playerID)
    local playerConfig = PlayerConfigurations[playerID]
    if not playerConfig then
        return ""
    end

    if not IsPlayerKnownToLocal(playerID) then
        return Locale.Lookup("LOC_DIPLOPANEL_UNMET_PLAYER")
    end

    return Locale.Lookup("LOC_DIPLOMACY_DEAL_PLAYER_PANEL_TITLE",
        playerConfig:GetLeaderName(),
        playerConfig:GetCivilizationDescription())
end

local function IsLocalPlayerOnTeam(teamID)
    for _, playerID in ipairs(Teams[teamID]) do
        if playerID == g_LocalPlayerID then return true end
    end
    return false
end

local function GetRankingsPlayerLabel(playerID)
    local parts = { GetPlayerLabel(playerID) }
    if IsPlayerKnownToLocal(playerID) then
        local playerConfig = PlayerConfigurations[playerID]
        if GameConfiguration.IsAnyMultiplayer() and playerConfig:IsHuman() then
            table.insert(parts, Locale.Lookup("LOC_CAI_WORLD_RANKINGS_HUMAN_PLAYER_NAME",
                Locale.Lookup(playerConfig:GetPlayerName())))
        end
        if playerID == g_LocalPlayerID then
            table.insert(parts, Locale.Lookup("LOC_CAI_WORLD_RANKINGS_LOCAL_PLAYER"))
        end
    end
    return JoinLines(parts)
end

local function GetRankingsTeamLabel(teamID)
    return JoinLines({
        Locale.Lookup("LOC_WORLD_RANKINGS_TEAM", teamID + 1),
        IsLocalPlayerOnTeam(teamID) and Locale.Lookup("LOC_CAI_WORLD_RANKINGS_YOUR_TEAM") or nil,
    })
end

local function GetCompetitorKey(competitor)
    return "team:" .. competitor.TeamID
end

local function GetCompetitorLabel(competitor)
    if #competitor.PlayerIDs == 1 then
        return GetRankingsPlayerLabel(competitor.PlayerIDs[1])
    end
    return GetRankingsTeamLabel(competitor.TeamID)
end

local function GetCompetitorTooltip(competitor)
    if #competitor.PlayerIDs <= 1 then return nil end
    local names = {}
    for _, playerID in ipairs(competitor.PlayerIDs) do
        table.insert(names, GetRankingsPlayerLabel(playerID))
    end
    return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_TEAM_MEMBERS", JoinLines(names))
end

local function GetAliveCompetitors()
    local competitors = {}
    for _, teamID in ipairs(GetAliveMajorTeamIDs()) do
        local playerIDs = {}
        for _, playerID in ipairs(Teams[teamID]) do
            if IsAliveAndMajor(playerID) then
                table.insert(playerIDs, playerID)
            end
        end
        if #playerIDs > 0 then
            table.insert(competitors, { TeamID = teamID, PlayerIDs = playerIDs })
        end
    end
    return competitors
end

local function FindCompetitor(competitors, teamID)
    for _, competitor in ipairs(competitors) do
        if competitor.TeamID == teamID then return competitor end
    end
    return nil
end

local function FormatContribution(playerID, value)
    return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_CONTRIBUTION",
        GetRankingsPlayerLabel(playerID), tostring(value))
end

local function FormatPercent(value)
    return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_PERCENT", Round(value, 1))
end

local function MakeCompetitorColumn()
    return {
        key = "competitor",
        header = function() return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_COMPETITOR") end,
        getCell = GetCompetitorLabel,
        getTooltip = GetCompetitorTooltip,
        sortKey = GetCompetitorLabel,
        sortAscendingDescription = "LOC_CAI_SORT_A_TO_Z",
        sortDescendingDescription = "LOC_CAI_SORT_Z_TO_A",
    }
end

local function ConfigureRankingTable(tableView, columns, rows, defaultSort)
    local previousColumn, previousAscending = tableView:GetSort()
    local hasPreviousColumn = false
    for _, column in ipairs(columns) do
        if column.key == previousColumn and column.sortKey then
            hasPreviousColumn = true
            break
        end
    end

    tableView:SetColumns(columns)
    tableView:SetRowsProvider(function() return rows end)
    tableView:SetRowKeyGetter(GetCompetitorKey)
    tableView:SetRowLabelGetter(GetCompetitorLabel)
    if hasPreviousColumn then
        tableView:SetDefaultSort({ column = previousColumn, ascending = previousAscending })
    else
        tableView:SetDefaultSort(defaultSort)
    end
    tableView:Rebuild()
end

-- ============================================================================
-- Overall Tab
-- ============================================================================
local function GetAlexanderCityCounts()
    local enemyCities = 0
    local ownedCities = 0

    for _, player in ipairs(PlayerManager.GetAlive()) do
        for _, city in player:GetCities():Members() do
            if player:GetID() > 0 then
                enemyCities = enemyCities + 1
            else
                ownedCities = ownedCities + 1
            end
        end
    end

    return enemyCities, ownedCities
end

local AUSTRALIA_VICTORY_THRESHOLDS = { 200, 300, 400, 500, 600, 700, 800, 900 }

local function GetAustraliaDifficultyScore(difficultyIndex)
    local difficulty = GameInfo.Difficulties[difficultyIndex]
    return Locale.Lookup(difficulty.Name) .. ", "
        .. Locale.Lookup("LOC_SCENARIO_AUSTRALIA_SINGLE_PLAYER_SCORE",
            AUSTRALIA_VICTORY_THRESHOLDS[difficultyIndex + 1])
end

local function RebuildOverallTree(tree)
    local capture = mgr:CaptureFocusKey(tree)
    tree:ClearChildren()

    if GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_WARMACHINE" then
        AddLeaf(tree, "war-machine:description", function()
            return Locale.Lookup("LOC_WARMACHINE_SCENARIO_ERA_INDUSTRIAL_DESCRIPTION")
        end)

        AddLeaf(tree, "war-machine:objective", function()
            return Locale.Lookup("LOC_VICTORY_WARMACHINE_SCENARIO_TT")
        end)

        mgr:RestoreFocus(tree, capture)
        return
    end

    if GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_VIKINGS" then
        AddLeaf(tree, "vikings:description", function()
            return Locale.Lookup("LOC_VIKING_SCENARIO_DESCRIPTION")
        end)

        AddLeaf(tree, "vikings:religion", function()
            return Locale.Lookup("LOC_VIKING_SCENARIO_RELIGION_DESCRIPTION")
        end)

        AddLeaf(tree, "vikings:scoring", function()
            return JoinLines({
                Locale.Lookup("LOC_VIKING_SCENARIO_SCORING_DESCRIPTION1", 25, 10, 50, 25, 10),
                Locale.Lookup("LOC_VIKING_SCENARIO_SCORING_DESCRIPTION2", 1000, 500, 300, 100),
                Locale.Lookup("LOC_VIKING_SCENARIO_SCORING_DESCRIPTION3", 50, 50, 1, 10, 1, 5),
            })
        end)

        mgr:RestoreFocus(tree, capture)
        return
    end

    if GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_POLAND" then
        AddLeaf(tree, "poland:overall", function()
            return JoinLines({
                Locale.Lookup("LOC_PEDIA_CITYSTATES_PAGE_CIVILIZATION_VIENNA_CHAPTER_HISTORY_PARA_1"),
                Locale.Lookup("LOC_PEDIA_CITYSTATES_PAGE_CIVILIZATION_VIENNA_CHAPTER_HISTORY_PARA_2"),
                Locale.Lookup("LOC_PEDIA_UNITS_PAGE_UNIT_OTTOMAN_JANISSARY_CHAPTER_HISTORY_PARA_1"),
                Locale.Lookup("LOC_PEDIA_UNITS_PAGE_UNIT_OTTOMAN_JANISSARY_CHAPTER_HISTORY_PARA_2"),
            })
        end)

        mgr:RestoreFocus(tree, capture)
        return
    end

    if GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_INDONESIA_KHMER" then
        AddLeaf(tree, "indonesia-khmer:rules", function()
            return JoinLines({
                Locale.Lookup("LOC_INDONESIAKHMER_SCENARIO_WORLD_RANKING_1"),
                Locale.Lookup("LOC_INDONESIAKHMER_SCENARIO_WORLD_RANKING_2"),
                Locale.Lookup("LOC_INDONESIAKHMER_SCENARIO_WORLD_RANKING_3"),
                Locale.Lookup("LOC_INDONESIAKHMER_SCENARIO_WORLD_RANKING_4"),
                Locale.Lookup("LOC_INDONESIAKHMER_SCENARIO_WORLD_RANKING_10"),
                Locale.Lookup("LOC_INDONESIAKHMER_SCENARIO_WORLD_RANKING_5"),
            })
        end)
        AddLeaf(tree, "indonesia-khmer:scoring", function()
            return JoinLines({
                Locale.Lookup("LOC_INDONESIAKHMER_SCENARIO_WORLD_RANKING_6"),
                Locale.Lookup("LOC_INDONESIAKHMER_SCENARIO_WORLD_RANKING_7", 1, 1),
                Locale.Lookup("LOC_INDONESIAKHMER_SCENARIO_WORLD_RANKING_8", 20, 20),
                Locale.Lookup("LOC_INDONESIAKHMER_SCENARIO_WORLD_RANKING_9", 1, 1),
            })
        end)

        mgr:RestoreFocus(tree, capture)
        return
    end

    if GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_AUSTRALIA" then
        AddLeaf(tree, "australia:description", function()
            return Locale.Lookup("LOC_AUSTRALIA_SCENARIO_DESCRIPTION")
        end)

        AddLeaf(tree, "australia:outback", function()
            return JoinLines({
                Locale.Lookup("LOC_SCENARIO_AUSTRALIA_OUTBACK_TITLE"),
                Locale.Lookup("LOC_SCENARIO_AUSTRALIA_OUTBACK_EFFECTS"),
            })
        end)

        if not GameConfiguration.IsAnyMultiplayer() then
            local currentGame = MakeTreeItem({
                Label = function()
                    local playerConfig = PlayerConfigurations[Game.GetLocalPlayer()]
                    local difficulty = GameInfo.Difficulties[playerConfig:GetHandicapTypeID()]
                    return JoinLines({
                        Locale.Lookup("LOC_SCENARIO_AUSTRALIA_CURRENT_GAME_DIFFICULTY",
                            Locale.Lookup(difficulty.Name)),
                        Locale.Lookup("LOC_SCENARIO_AUSTRALIA_SINGLE_PLAYER_SCORE",
                            AUSTRALIA_VICTORY_THRESHOLDS[difficulty.Index + 1]),
                    })
                end,
                FocusKey = "australia:current",
            })

            for index = 7, 0, -1 do
                local difficultyIndex = index
                AddLeaf(currentGame, "australia:difficulty:" .. difficultyIndex, function()
                    return GetAustraliaDifficultyScore(difficultyIndex)
                end)
            end

            tree:AddChild(currentGame)
        end

        mgr:RestoreFocus(tree, capture)
        return
    end

    if GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_ALEXANDER" then
        AddLeaf(tree, "alexander:rules", function()
            return JoinLines({
                Locale.Lookup("LOC_ALEXANDER_SCENARIO_WORLD_RANKING_1"),
                Locale.Lookup("LOC_ALEXANDER_SCENARIO_WORLD_RANKING_2"),
                Locale.Lookup("LOC_ALEXANDER_SCENARIO_WORLD_RANKING_3"),
            })
        end)

        AddLeaf(tree, "alexander:rewards", function()
            return JoinLines({
                Locale.Lookup("LOC_ALEXANDER_SCENARIO_WORLD_RANKING_4"),
                Locale.Lookup("LOC_ALEXANDER_SCENARIO_WORLD_RANKING_5"),
            })
        end)

        AddLeaf(tree, "alexander:progress", function()
            local enemyCities, ownedCities = GetAlexanderCityCounts()
            return JoinLines({
                Locale.Lookup("LOC_ALEXANDER_SCENARIO_WORLD_RANKING_6", enemyCities),
                Locale.Lookup("LOC_ALEXANDER_SCENARIO_WORLD_RANKING_8", ownedCities * 5),
                Locale.Lookup("LOC_ALEXANDER_ENDGAME_RANKING_LEADER_QUOTE"),
            })
        end)

        mgr:RestoreFocus(tree, capture)
        return
    end

    local function GatherOverallVictoryData(victoryType)
        local victoryData = g_victoryData[victoryType]
        local firstTiebreaker = victoryData.Primary or victoryData
        local secondTiebreaker = victoryData.Secondary or victoryData
        local results = {}

        for _, teamID in ipairs(GetAliveMajorTeamIDs()) do
            local progress = Game.GetVictoryProgressForTeam(victoryType, teamID)
            if progress ~= nil then
                local entry = {
                    TeamID = teamID,
                    Progress = progress,
                    GenericScore = 0,
                    FirstTeamScore = 0,
                    SecondTeamScore = 0,
                    PlayerData = {},
                    LocalInTeam = false,
                }

                for _, playerID in ipairs(Teams[teamID]) do
                    if IsAliveAndMajor(playerID) then
                        local player = Players[playerID]
                        local firstScore = firstTiebreaker.GetScore(player)
                        local secondScore = secondTiebreaker.GetScore(player)
                        local additionalSummary = victoryData.AdditionalSummary
                            and victoryData.AdditionalSummary(player) or ""
                        local playerData = {
                            PlayerID = playerID,
                            GenericScore = player:GetScore(),
                            FirstScore = firstScore,
                            SecondScore = secondScore,
                            FirstSummary = Locale.Lookup(firstTiebreaker.GetText(player), Round(firstScore, 1)),
                            SecondSummary = Locale.Lookup(secondTiebreaker.GetText(player), Round(secondScore, 1)),
                            AdditionalSummary = Locale.Lookup(additionalSummary),
                        }
                        table.insert(entry.PlayerData, playerData)
                        entry.GenericScore = math.max(entry.GenericScore, playerData.GenericScore)
                        entry.FirstTeamScore = entry.FirstTeamScore + firstScore
                        entry.SecondTeamScore = entry.SecondTeamScore + secondScore
                        if playerID == g_LocalPlayerID then entry.LocalInTeam = true end
                    end
                end

                local playerCount = #entry.PlayerData
                entry.PlayerCount = playerCount
                entry.FirstTeamScore = entry.FirstTeamScore / playerCount
                entry.SecondTeamScore = entry.SecondTeamScore / playerCount
                table.sort(entry.PlayerData, function(a, b)
                    if a.FirstScore ~= b.FirstScore then return a.FirstScore > b.FirstScore end
                    if a.SecondScore ~= b.SecondScore then return a.SecondScore > b.SecondScore end
                    if a.GenericScore ~= b.GenericScore then return a.GenericScore > b.GenericScore end
                    return a.PlayerID < b.PlayerID
                end)
                table.insert(results, entry)
            end
        end

        table.sort(results, function(a, b)
            if a.Progress ~= b.Progress then return a.Progress > b.Progress end
            if a.FirstTeamScore ~= b.FirstTeamScore then
                return a.FirstTeamScore > b.FirstTeamScore
            end
            if a.SecondTeamScore ~= b.SecondTeamScore then
                return a.SecondTeamScore > b.SecondTeamScore
            end
            if a.GenericScore ~= b.GenericScore then return a.GenericScore > b.GenericScore end
            return a.TeamID < b.TeamID
        end)
        return results
    end

    local function FindOverallTeam(victoryType, teamID)
        for rank, entry in ipairs(GatherOverallVictoryData(victoryType)) do
            if entry.TeamID == teamID then return entry, rank end
        end
        return nil, nil
    end

    local function GetOverallPlayerDetails(victoryType, playerID)
        if not IsPlayerKnownToLocal(playerID) then return nil end
        local teamID = Players[playerID]:GetTeam()
        local teamData = FindOverallTeam(victoryType, teamID)
        if not teamData then return nil end

        for _, playerData in ipairs(teamData.PlayerData) do
            if playerData.PlayerID == playerID then
                return JoinLines({
                    playerData.FirstSummary,
                    playerData.SecondSummary ~= playerData.FirstSummary
                    and playerData.SecondSummary or nil,
                    playerData.AdditionalSummary,
                })
            end
        end
        return nil
    end

    local function GetOverallPlace(rank)
        local place = Locale.Lookup("LOC_WORLD_RANKINGS_" .. rank .. "_PLACE")
        return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_PLACE", place)
    end

    local function GetOverallProgress(progress)
        local percent = Round(math.max(0, math.min(progress, 1)) * 100, 1)
        return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_VICTORY_PROGRESS", percent)
    end

    local function GetOverallPlayerLabel(playerID)
        return GetRankingsPlayerLabel(playerID)
    end

    local function AddOverallVictory(victoryType, displayName)
        if not Game.IsVictoryEnabled(victoryType) then return end
        if not g_victoryData[victoryType] then return end

        local teamData = GatherOverallVictoryData(victoryType)
        local fk = "overall:" .. victoryType
        if #teamData == 0 then
            tree:AddChild(MakeStaticText({
                Label = function()
                    return JoinLines({
                        displayName,
                        Locale.Lookup("LOC_WORLD_RANKINGS_VICTORY_DISABLED"),
                    })
                end,
                FocusKey = fk,
            }))
            return
        end

        local victoryItem = MakeTreeItem({
            Label = function()
                local currentData = GatherOverallVictoryData(victoryType)
                if #currentData == 0 then
                    return JoinLines({
                        displayName,
                        Locale.Lookup("LOC_WORLD_RANKINGS_VICTORY_DISABLED"),
                    })
                end
                local leader = currentData[1]
                local parts = { displayName }
                if leader.LocalInTeam then
                    table.insert(parts, Locale.Lookup(leader.PlayerCount > 1
                        and "LOC_WORLD_RANKINGS_FIRST_PLACE_TEAM_SIMPLE"
                        or "LOC_WORLD_RANKINGS_FIRST_PLACE_YOU_SIMPLE"))
                else
                    local topName = leader.PlayerCount > 1
                        and Locale.Lookup("LOC_WORLD_RANKINGS_TEAM", leader.TeamID + 1)
                        or GetPlayerLabel(leader.PlayerData[1].PlayerID)
                    table.insert(parts, Locale.Lookup("LOC_WORLD_RANKINGS_FIRST_PLACE_OTHER_SIMPLE", topName))
                    for rank, entry in ipairs(currentData) do
                        if entry.LocalInTeam then
                            local posText = Locale.Lookup("LOC_WORLD_RANKINGS_" .. rank .. "_PLACE")
                            table.insert(parts, Locale.Lookup(entry.PlayerCount > 1
                                and "LOC_WORLD_RANKINGS_OTHER_PLACE_TEAM_SIMPLE"
                                or "LOC_WORLD_RANKINGS_OTHER_PLACE_SIMPLE", posText))
                            break
                        end
                    end
                end
                return JoinLines(parts)
            end,
            FocusKey = fk,
        })

        for rank, entry in ipairs(teamData) do
            local capturedTeamID = entry.TeamID
            local capturedRank = rank
            if entry.PlayerCount > 1 then
                local teamItem = MakeTreeItem({
                    Label = function()
                        local liveEntry, liveRank = FindOverallTeam(victoryType, capturedTeamID)
                        return JoinLines({
                            GetRankingsTeamLabel(capturedTeamID),
                            GetOverallPlace(liveRank or capturedRank),
                            liveEntry and GetOverallProgress(liveEntry.Progress) or nil,
                        })
                    end,
                    FocusKey = fk .. ":team:" .. capturedTeamID,
                })
                for _, playerData in ipairs(entry.PlayerData) do
                    local capturedPlayerID = playerData.PlayerID
                    teamItem:AddChild(MakeStaticText({
                        Label = function() return GetOverallPlayerLabel(capturedPlayerID) end,
                        Tooltip = function()
                            return GetOverallPlayerDetails(victoryType, capturedPlayerID)
                        end,
                        FocusKey = fk .. ":team:" .. capturedTeamID
                            .. ":player:" .. capturedPlayerID,
                    }))
                end
                victoryItem:AddChild(teamItem)
            else
                local capturedPlayerID = entry.PlayerData[1].PlayerID
                victoryItem:AddChild(MakeStaticText({
                    Label = function()
                        local liveEntry, liveRank = FindOverallTeam(victoryType, capturedTeamID)
                        return JoinLines({
                            GetOverallPlayerLabel(capturedPlayerID),
                            GetOverallPlace(liveRank or capturedRank),
                            liveEntry and GetOverallProgress(liveEntry.Progress) or nil,
                        })
                    end,
                    Tooltip = function()
                        return GetOverallPlayerDetails(victoryType, capturedPlayerID)
                    end,
                    FocusKey = fk .. ":player:" .. capturedPlayerID,
                }))
            end
        end

        tree:AddChild(victoryItem)
    end

    AddOverallVictory("VICTORY_TECHNOLOGY", Locale.Lookup("LOC_WORLD_RANKINGS_SCIENCE_VICTORY"))
    AddOverallVictory("VICTORY_CULTURE", Locale.Lookup("LOC_WORLD_RANKINGS_CULTURE_VICTORY"))
    AddOverallVictory("VICTORY_CONQUEST", Locale.Lookup("LOC_WORLD_RANKINGS_DOMINATION_VICTORY"))
    AddOverallVictory("VICTORY_RELIGIOUS", Locale.Lookup("LOC_WORLD_RANKINGS_RELIGION_VICTORY"))

    for row in GameInfo.Victories() do
        if IsCustomVictoryType(row.VictoryType) and Game.IsVictoryEnabled(row.VictoryType) then
            AddOverallVictory(row.VictoryType, Locale.Lookup(row.Name))
        end
    end

    mgr:RestoreFocus(tree, capture)
end

-- ============================================================================
-- Score Tab
-- ============================================================================
local function CreateScorePlayerRow(playerData, parentFocusPrefix)
    local playerID = playerData.PlayerID
    local fk = (parentFocusPrefix or "") .. "player:" .. playerID
    local rowFactory = (#playerData.Categories > 0) and MakeTreeItem or MakeStaticText

    local item = rowFactory({
        Label = function()
            return JoinLines({
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
    local capture = mgr:CaptureFocusKey(tree)
    tree:ClearChildren()

    if m_scoreCapturedRows then
        for _, record in ipairs(m_scoreCapturedRows) do
            if record.Kind == "team" then
                local teamData = record.TeamData
                local teamItem = MakeTreeItem({
                    Label = function()
                        return JoinLines({
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
                        return JoinLines({
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

    AddAdvisorLeaf(tree, JoinLines({
        Locale.Lookup("LOC_WORLD_RANKINGS_SCORE_DETAILS"),
        Locale.Lookup("LOC_WORLD_RANKINGS_SCORE_CONDITION", Game.GetMaxGameTurns())
    }))

    mgr:RestoreFocus(tree, capture)
end

-- ============================================================================
-- Science Tab
-- ============================================================================
local function GetScienceNextStep(pPlayer, projectSets, bHasSpaceport, finishedProjects)
    local SPACE_PORT_INFO = GameInfo.Districts["DISTRICT_SPACEPORT"]
    if not bHasSpaceport then
        return Locale.Lookup("LOC_WORLD_RANKINGS_SCIENCE_NEXT_STEP_BUILD", Locale.Lookup(SPACE_PORT_INFO.Name))
    end

    local playerTech = pPlayer:GetTechs()
    for mi, projGroup in ipairs(projectSets) do
        local projectCompletion = finishedProjects[mi]
        local hasUnfinishedProject = false
        for pi, _ in ipairs(projGroup) do
            if not projectCompletion[pi] then
                hasUnfinishedProject = true
                break
            end
        end
        if hasUnfinishedProject then
            for _, projInfo in ipairs(projGroup) do
                if projInfo and projInfo.PrereqTech then
                    local tech = GameInfo.Technologies[projInfo.PrereqTech]
                    if tech and not playerTech:HasTech(tech.Index) then
                        return Locale.Lookup("LOC_WORLD_RANKINGS_SCIENCE_NEXT_STEP_RESEARCH", Locale.Lookup(tech.Name))
                    end
                end
            end
            for pi, projInfo in ipairs(projGroup) do
                if projInfo and not projectCompletion[pi] then
                    return Locale.Lookup(projInfo.Name)
                end
            end
        end
    end
    return nil
end

local function GatherSciencePlayerData(pPlayer)
    local playerID = pPlayer:GetID()
    local SPACE_PORT_INFO = GameInfo.Districts["DISTRICT_SPACEPORT"]

    local bHasSpaceport = false
    for _, district in pPlayer:GetDistricts():Members() do
        if district and district:IsComplete() and district:GetType() == SPACE_PORT_INFO.Index then
            bHasSpaceport = true
            break
        end
    end

    local projectSets
    local milestoneNames
    if m_isExp2 then
        projectSets = {
            { GameInfo.Projects["PROJECT_LAUNCH_EARTH_SATELLITE"] },
            { GameInfo.Projects["PROJECT_LAUNCH_MOON_LANDING"] },
            { GameInfo.Projects["PROJECT_LAUNCH_MARS_BASE"] },
            { GameInfo.Projects["PROJECT_LAUNCH_EXOPLANET_EXPEDITION"] },
        }
        milestoneNames = {
            Locale.Lookup("LOC_WORLD_RANKINGS_SCIENCE_REQUIREMENT_1"),
            Locale.Lookup("LOC_WORLD_RANKINGS_SCIENCE_REQUIREMENT_2"),
            Locale.Lookup("LOC_WORLD_RANKINGS_SCIENCE_REQUIREMENT_3"),
            Locale.Lookup("LOC_WORLD_RANKINGS_SCIENCE_REQUIREMENT_4"),
        }
    else
        projectSets = {
            { GameInfo.Projects["PROJECT_LAUNCH_EARTH_SATELLITE"] },
            { GameInfo.Projects["PROJECT_LAUNCH_MOON_LANDING"] },
            {
                GameInfo.Projects["PROJECT_LAUNCH_MARS_REACTOR"],
                GameInfo.Projects["PROJECT_LAUNCH_MARS_HABITATION"],
                GameInfo.Projects["PROJECT_LAUNCH_MARS_HYDROPONICS"],
            },
        }
        milestoneNames = {
            Locale.Lookup("LOC_WORLD_RANKINGS_SCIENCE_REQUIREMENT_1"),
            Locale.Lookup("LOC_WORLD_RANKINGS_SCIENCE_REQUIREMENT_2"),
            Locale.Lookup("LOC_WORLD_RANKINGS_SCIENCE_REQUIREMENT_3"),
        }
    end

    local pStats = pPlayer:GetStats()
    local milestones = {}
    local completedCount = 0
    local milestoneComplete = {}
    local finishedProjects = {}

    for mi, projGroup in ipairs(projectSets) do
        local totalCost = 0
        local totalProgress = 0
        finishedProjects[mi] = {}
        for pi, _ in ipairs(projGroup) do
            finishedProjects[mi][pi] = false
        end
        for _, city in pPlayer:GetCities():Members() do
            local bq = city:GetBuildQueue()
            for pi, projInfo in ipairs(projGroup) do
                if projInfo then
                    local cost = bq:GetProjectCost(projInfo.Index)
                    local progress = cost
                    if pStats:GetNumProjectsAdvanced(projInfo.Index) == 0 then
                        progress = bq:GetProjectProgress(projInfo.Index)
                    end
                    -- Vanilla omits idle-city costs for the first two stages, but
                    -- includes every city cost for the later Mars/Exoplanet stages.
                    if mi <= 2 then
                        if progress ~= 0 then
                            totalCost = totalCost + cost
                            totalProgress = totalProgress + progress
                        end
                    else
                        totalCost = totalCost + cost
                        if progress ~= 0 then
                            totalProgress = totalProgress + progress
                        end
                    end
                    if progress ~= 0 and progress == cost then
                        finishedProjects[mi][pi] = true
                    end
                end
            end
        end

        local pct = 0
        local isComplete = false
        if totalCost > 0 then
            pct = math.floor((totalProgress / totalCost) * 100 + 0.5)
            isComplete = (totalProgress >= totalCost)
        end
        if isComplete then completedCount = completedCount + 1 end
        milestoneComplete[mi] = isComplete

        table.insert(milestones, {
            Name = milestoneNames[mi],
            Percent = pct,
            ProgressRatio = totalCost > 0 and totalProgress / totalCost or 0,
            IsComplete = isComplete,
            ProjectInfos = projGroup,
            FinishedProjects = finishedProjects[mi],
            IncludeSpaceport = (mi == 1),
        })
    end

    local lightYears = nil
    local lightYearsTotal = nil
    local lightYearsRate = nil
    if m_isExp2 then
        lightYears = pStats:GetScienceVictoryPoints()
        lightYearsTotal = pStats:GetScienceVictoryPointsTotalNeeded()
        lightYearsRate = pStats:GetScienceVictoryPointsPerTurn()
    end

    local nextStep = nil
    if playerID == g_LocalPlayerID then
        nextStep = GetScienceNextStep(pPlayer, projectSets, bHasSpaceport, finishedProjects)
    end

    return {
        PlayerID = playerID,
        HasSpaceport = bHasSpaceport,
        Milestones = milestones,
        CompletedCount = completedCount,
        TotalMilestones = #projectSets,
        LightYears = lightYears,
        LightYearsTotal = lightYearsTotal,
        LightYearsRate = lightYearsRate,
        HasLaunchedExpedition = m_isExp2 and milestoneComplete[4] or false,
        NextStep = nextStep,
    }
end

local function CreateSciencePlayerRow(sciData, parentFocusPrefix)
    local playerID = sciData.PlayerID
    local fk = (parentFocusPrefix or "") .. "player:" .. playerID

    local tooltipFn = nil
    if playerID == g_LocalPlayerID then
        tooltipFn = function()
            local parts = {}
            if sciData.HasSpaceport then
                table.insert(parts, Locale.Lookup("LOC_CAI_WORLD_RANKINGS_SPACEPORT_BUILT"))
            else
                table.insert(parts, Locale.Lookup("LOC_CAI_WORLD_RANKINGS_SPACEPORT_NOT_BUILT"))
            end
            if sciData.NextStep then
                table.insert(parts, Locale.Lookup("LOC_CAI_WORLD_RANKINGS_NEXT_STEP", sciData.NextStep))
            end
            return table.concat(parts, "[NEWLINE]")
        end
    end

    local item = MakeTreeItem({
        Label = function()
            return JoinLines({
                GetRankingsPlayerLabel(playerID),
                Locale.Lookup("LOC_CAI_WORLD_RANKINGS_MILESTONES_DONE",
                    sciData.CompletedCount, sciData.TotalMilestones),
            })
        end,
        Tooltip = tooltipFn,
        FocusKey = fk,
    })

    for mi, ms in ipairs(sciData.Milestones) do
        local capturedMs = ms
        local capturedMi = mi
        item:AddChild(MakeStaticText({
            Label = function()
                if capturedMs.IsComplete then
                    return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_MILESTONE_COMPLETE", capturedMs.Name)
                elseif capturedMs.Percent > 0 then
                    return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_MILESTONE_PROGRESS", capturedMs.Name, capturedMs
                    .Percent)
                else
                    return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_MILESTONE_NONE", capturedMs.Name)
                end
            end,
            Tooltip = function()
                return GetTooltipForScienceProject(Players[playerID], capturedMs.ProjectInfos,
                    capturedMs.IncludeSpaceport and sciData.HasSpaceport or nil,
                    capturedMs.FinishedProjects)
            end,
            FocusKey = fk .. ":ms:" .. capturedMi,
        }))
    end

    if m_isExp2 and sciData.HasLaunchedExpedition then
        AddLeaf(item, fk .. ":lightyears", function()
            local ly = sciData.LightYears
            local lyTotal = sciData.LightYearsTotal
            if ly > lyTotal then ly = lyTotal end
            local parts = { Locale.Lookup("LOC_CAI_WORLD_RANKINGS_LIGHT_YEARS", ly, lyTotal) }
            if sciData.LightYearsRate and sciData.LightYearsRate > 0 then
                table.insert(parts, Locale.Lookup("LOC_CAI_WORLD_RANKINGS_LIGHT_YEARS_RATE", sciData.LightYearsRate))
            end
            return JoinLines(parts)
        end)
    end

    return item
end

local function RebuildScienceTree(tree)
    local capture = mgr:CaptureFocusKey(tree)
    tree:ClearChildren()

    local teamIDs = GetAliveMajorTeamIDs()
    for _, teamID in ipairs(teamIDs) do
        local team = Teams[teamID]
        if team then
            if #team > 1 then
                local teamItem = MakeTreeItem({
                    Label = function()
                        return GetRankingsTeamLabel(teamID)
                    end,
                    FocusKey = "team:" .. teamID,
                })
                for _, playerID in ipairs(team) do
                    if IsAliveAndMajor(playerID) then
                        local sciData = GatherSciencePlayerData(Players[playerID])
                        teamItem:AddChild(CreateSciencePlayerRow(sciData, "team:" .. teamID .. ":"))
                    end
                end
                tree:AddChild(teamItem)
            else
                local playerID = team[1]
                if IsAliveAndMajor(playerID) then
                    local sciData = GatherSciencePlayerData(Players[playerID])
                    tree:AddChild(CreateSciencePlayerRow(sciData, ""))
                end
            end
        end
    end

    local milestoneCount = m_isExp2 and 4 or 3
    local detailsKey = m_isExp2 and "LOC_WORLD_RANKINGS_SCIENCE_DETAILS_EXP2" or "LOC_WORLD_RANKINGS_SCIENCE_DETAILS"
    local parts = { Locale.Lookup(detailsKey) }
    for i = 1, milestoneCount do
        table.insert(parts, Locale.Lookup("LOC_WORLD_RANKINGS_SCIENCE_REQUIREMENT_" .. i))
    end
    if m_isExp2 and g_LocalPlayer then
        table.insert(parts, Locale.Lookup("LOC_WORLD_RANKINGS_SCIENCE_REQUIREMENT_FINAL",
            g_LocalPlayer:GetStats():GetScienceVictoryPointsTotalNeeded()))
    end
    AddAdvisorLeaf(tree, table.concat(parts, "[NEWLINE]"))

    mgr:RestoreFocus(tree, capture)
end

-- ============================================================================
-- Culture Tab
-- ============================================================================
local function RebuildCultureTree(tree)
    local capture = mgr:CaptureFocusKey(tree)
    tree:ClearChildren()

    local cultureData = GatherCultureData()
    local playerData = {}
    for _, teamData in ipairs(cultureData) do
        for _, data in ipairs(teamData.PlayerData) do
            table.insert(playerData, data)
        end
    end
    table.sort(playerData, function(a, b)
        local aScore = a.NumVisitingUs / math.max(a.NumRequiredTourists, 1)
        local bScore = b.NumVisitingUs / math.max(b.NumRequiredTourists, 1)
        if aScore ~= bScore then return aScore > bScore end
        if a.NumRequiredTourists ~= b.NumRequiredTourists then
            return a.NumRequiredTourists > b.NumRequiredTourists
        end
        return a.PlayerID < b.PlayerID
    end)

    table.sort(cultureData, function(a, b)
        local aScore = a.BestNumVisitingUs / math.max(a.BestNumRequiredTourists, 1)
        local bScore = b.BestNumVisitingUs / math.max(b.BestNumRequiredTourists, 1)
        if aScore ~= bScore then return aScore > bScore end
        if a.BestNumRequiredTourists ~= b.BestNumRequiredTourists then
            return a.BestNumRequiredTourists > b.BestNumRequiredTourists
        end
        return a.TeamID < b.TeamID
    end)

    for _, teamData in ipairs(cultureData) do
        table.sort(teamData.PlayerData, function(a, b)
            local aScore = a.NumVisitingUs / math.max(a.NumRequiredTourists, 1)
            local bScore = b.NumVisitingUs / math.max(b.NumRequiredTourists, 1)
            if aScore ~= bScore then return aScore > bScore end
            if a.NumRequiredTourists ~= b.NumRequiredTourists then
                return a.NumRequiredTourists > b.NumRequiredTourists
            end
            return a.PlayerID < b.PlayerID
        end)

        if #teamData.PlayerData > 1 then
            local capturedTeamID = teamData.TeamID
            local teamItem = MakeTreeItem({
                Label = function()
                    local liveTeamData = CAIGetCultureTeamData(capturedTeamID)
                    return JoinLines({
                        GetRankingsTeamLabel(capturedTeamID),
                        Locale.Lookup("LOC_CAI_WORLD_RANKINGS_TOURISTS",
                            liveTeamData.BestNumVisitingUs, liveTeamData.BestNumRequiredTourists),
                    })
                end,
                FocusKey = "team:" .. capturedTeamID,
            })
            for _, data in ipairs(teamData.PlayerData) do
                teamItem:AddChild(CreateCulturePlayerRow(data, playerData,
                    "team:" .. capturedTeamID .. ":"))
            end
            tree:AddChild(teamItem)
        else
            tree:AddChild(CreateCulturePlayerRow(teamData.PlayerData[1], playerData, ""))
        end
    end

    AddAdvisorLeaf(tree, JoinLines({
        Locale.Lookup("LOC_WORLD_RANKINGS_CULTURE_VICTORY_DETAILS"),
        Locale.Lookup("LOC_WORLD_RANKINGS_CULTURE_DETAILS_DOMESTIC_TOURISTS"),
        Locale.Lookup("LOC_WORLD_RANKINGS_CULTURE_DETAILS_VISITING_TOURISTS"),
    }))

    mgr:RestoreFocus(tree, capture)
end

function CAIGetCulturePlayerData(playerID)
    local player = Players[playerID]
    local culture = player:GetCulture()
    local requiredTourists = 0
    local teamID = player:GetTeam()

    for otherID, otherPlayer in ipairs(Players) do
        if otherID ~= playerID and IsAliveAndMajor(otherID) and otherPlayer:GetTeam() ~= teamID then
            requiredTourists = math.max(requiredTourists, otherPlayer:GetCulture():GetStaycationers() + 1)
        end
    end

    return {
        PlayerID = playerID,
        NumRequiredTourists = requiredTourists,
        NumStaycationers = culture:GetStaycationers(),
        NumVisitingUs = culture:GetTouristsTo(),
        TurnsTillCulturalVictory = culture.GetTurnsUntilVictory and culture:GetTurnsUntilVictory() or -1,
    }
end

function CAIGetCultureTeamData(teamID)
    local bestVisiting = 0
    local bestRequired = 1

    for _, playerID in ipairs(Teams[teamID]) do
        if IsAliveAndMajor(playerID) then
            local data = CAIGetCulturePlayerData(playerID)
            local bestScore = bestVisiting / math.max(bestRequired, 1)
            local playerScore = data.NumVisitingUs / math.max(data.NumRequiredTourists, 1)
            if playerScore > bestScore
                or (playerScore == bestScore and data.NumRequiredTourists > bestRequired) then
                bestVisiting = data.NumVisitingUs
                bestRequired = data.NumRequiredTourists
            end
        end
    end

    return {
        BestNumVisitingUs = bestVisiting,
        BestNumRequiredTourists = bestRequired,
    }
end

function CreateCulturePlayerRow(playerData, allPlayerData, parentFocusPrefix)
    local playerID = playerData.PlayerID
    local fk = (parentFocusPrefix or "") .. "player:" .. playerID

    local capturedPlayerID = playerID
    local props = {
        Label = function()
            local liveData = CAIGetCulturePlayerData(capturedPlayerID)
            return JoinLines({
                GetRankingsPlayerLabel(capturedPlayerID),
                Locale.Lookup("LOC_CAI_WORLD_RANKINGS_TOURISTS",
                    liveData.NumVisitingUs, liveData.NumRequiredTourists),
            })
        end,
        Tooltip = function()
            local liveData = CAIGetCulturePlayerData(capturedPlayerID)
            local parts = {
                Locale.Lookup("LOC_CAI_WORLD_RANKINGS_DOMESTIC", liveData.NumStaycationers),
            }
            if liveData.TurnsTillCulturalVictory > 0 then
                table.insert(parts, Locale.Lookup("LOC_CAI_WORLD_RANKINGS_TURNS_VICTORY",
                    liveData.TurnsTillCulturalVictory))
            end
            return JoinLines(parts)
        end,
        FocusKey = fk,
    }

    if playerID ~= g_LocalPlayerID or not g_LocalPlayer then
        return MakeStaticText(props)
    end

    local item = MakeTreeItem(props)
    for _, sourceData in ipairs(allPlayerData) do
        if sourceData.PlayerID ~= g_LocalPlayerID then
            local capturedSourceID = sourceData.PlayerID
            local visitLeaf = MakeStaticText({
                Label = function()
                    local pCulture = g_LocalPlayer:GetCulture()
                    return JoinLines({
                        GetPlayerLabel(capturedSourceID),
                        Locale.Lookup("LOC_CAI_WORLD_RANKINGS_VISITING_US",
                            pCulture:GetTouristsFrom(capturedSourceID)),
                    })
                end,
                Tooltip = function()
                    local pCulture = g_LocalPlayer:GetCulture()
                    local tt = pCulture:GetTouristsFromTooltip(capturedSourceID)
                    if not tt then return nil end
                    local lines = {}
                    for segment in (tt .. "[NEWLINE]"):gmatch("(.-)%[NEWLINE%]") do
                        local trimmed = segment:match("^%s*(.-)%s*$")
                        if trimmed and trimmed ~= "" then
                            table.insert(lines, trimmed)
                        end
                    end
                    if #lines >= 2 then
                        local current = lines[1]:match("[%d,%.]+")
                        local lifetime = lines[2]:match("[%d,%.]+")
                        if current then
                            lines[1] = Locale.Lookup("LOC_CAI_WORLD_RANKINGS_TOURISM_CURRENT", current)
                        end
                        if lifetime then
                            lines[2] = Locale.Lookup("LOC_CAI_WORLD_RANKINGS_TOURISM_LIFETIME", lifetime)
                        end
                    end
                    return table.concat(lines, "[NEWLINE]")
                end,
                FocusKey = fk .. ":source:" .. capturedSourceID,
            })
            item:AddChild(visitLeaf)
        end
    end

    return item
end

-- ============================================================================
-- Domination Tab
-- ============================================================================
local function GatherDominationData()
    local data = {}
    local teamIDs = GetAliveMajorTeamIDs()

    for _, teamID in ipairs(teamIDs) do
        local team = Teams[teamID]
        if team then
            local teamEntry = { TeamID = teamID, TotalCapturedCapitals = 0, PlayerData = {} }

            for _, playerID in ipairs(team) do
                if IsAliveAndMajor(playerID) then
                    local pPlayer = Players[playerID]
                    local pCities = pPlayer:GetCities()
                    local pCapital = pCities:GetCapitalCity()
                    if pCapital then
                        local pd = {
                            PlayerID = playerID,
                            HasOriginalCapital = false,
                            CapturedCapitals = {},
                        }
                        for _, city in pCities:Members() do
                            local origOwner = city:GetOriginalOwner()
                            local pOrigOwner = Players[origOwner]
                            if playerID ~= origOwner and pOrigOwner:IsMajor() and city:IsOriginalCapital() then
                                table.insert(pd.CapturedCapitals, origOwner)
                                teamEntry.TotalCapturedCapitals = teamEntry.TotalCapturedCapitals + 1
                            elseif playerID == origOwner and pOrigOwner:IsMajor() and city:IsOriginalCapital() then
                                pd.HasOriginalCapital = true
                            end
                        end
                        table.insert(teamEntry.PlayerData, pd)
                    end
                end
            end

            if #teamEntry.PlayerData > 0 then
                table.insert(data, teamEntry)
            end
        end
    end

    for _, td in ipairs(data) do
        table.sort(td.PlayerData, function(a, b) return #a.CapturedCapitals > #b.CapturedCapitals end)
    end
    table.sort(data, function(a, b) return a.TotalCapturedCapitals > b.TotalCapturedCapitals end)

    return data
end

local function CreateDominationPlayerRow(playerData, parentFocusPrefix)
    local playerID = playerData.PlayerID
    local fk = (parentFocusPrefix or "") .. "player:" .. playerID
    local rowFactory = (#playerData.CapturedCapitals > 0) and MakeTreeItem or MakeStaticText

    local item = rowFactory({
        Label = function()
            local parts = {
                GetRankingsPlayerLabel(playerID),
                Locale.Lookup("LOC_CAI_WORLD_RANKINGS_CAPITALS_CAPTURED", #playerData.CapturedCapitals),
            }
            if playerData.HasOriginalCapital then
                table.insert(parts, Locale.Lookup("LOC_CAI_WORLD_RANKINGS_HAS_CAPITAL"))
            else
                table.insert(parts, Locale.Lookup("LOC_CAI_WORLD_RANKINGS_LOST_CAPITAL"))
            end
            return JoinLines(parts)
        end,
        FocusKey = fk,
    })

    for _, capturedFromID in ipairs(playerData.CapturedCapitals) do
        local captID = capturedFromID
        AddLeaf(item, fk .. ":cap:" .. captID, function()
            return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_CAPTURED_FROM", GetPlayerLabel(captID))
        end)
    end

    return item
end

local function RebuildDominationTree(tree)
    local capture = mgr:CaptureFocusKey(tree)
    tree:ClearChildren()

    local domData = GatherDominationData()

    for _, teamData in ipairs(domData) do
        if #teamData.PlayerData > 1 then
            local teamItem = MakeTreeItem({
                Label = function()
                    return JoinLines({
                        GetRankingsTeamLabel(teamData.TeamID),
                        Locale.Lookup("LOC_CAI_WORLD_RANKINGS_CAPITALS_CAPTURED", teamData.TotalCapturedCapitals),
                    })
                end,
                FocusKey = "team:" .. teamData.TeamID,
            })
            for _, pd in ipairs(teamData.PlayerData) do
                teamItem:AddChild(CreateDominationPlayerRow(pd, "team:" .. teamData.TeamID .. ":"))
            end
            tree:AddChild(teamItem)
        elseif #teamData.PlayerData > 0 then
            tree:AddChild(CreateDominationPlayerRow(teamData.PlayerData[1], ""))
        end
    end

    AddAdvisorLeaf(tree, Locale.Lookup("LOC_WORLD_RANKINGS_DOMINATION_DETAILS"))

    mgr:RestoreFocus(tree, capture)
end

-- ============================================================================
-- Religion Tab
-- ============================================================================
local function CreateReligionPlayerRow(playerData, totalCivs, parentFocusPrefix)
    local playerID = playerData.PlayerID
    local fk = (parentFocusPrefix or "") .. "player:" .. playerID

    local religionName = Game.GetReligion():GetName(playerData.ReligionType)
    local rowFactory = (#playerData.ConvertedCivs > 0) and MakeTreeItem or MakeStaticText

    local item = rowFactory({
        Label = function()
            return JoinLines({
                GetRankingsPlayerLabel(playerID),
                Locale.Lookup("LOC_WORLD_RANKINGS_RELIGION_CONVERT_SUMMARY",
                    #playerData.ConvertedCivs .. "/" .. totalCivs, religionName),
            })
        end,
        FocusKey = fk,
    })

    for _, convertedID in ipairs(playerData.ConvertedCivs) do
        local captConvID = convertedID
        AddLeaf(item, fk .. ":conv:" .. captConvID, function()
            return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_CONVERTED", GetPlayerLabel(captConvID))
        end)
    end

    return item
end

local function RebuildReligionTree(tree)
    local capture = mgr:CaptureFocusKey(tree)
    tree:ClearChildren()

    local religionData, totalCivs = GatherReligionData()

    local filtered = {}
    for _, teamData in ipairs(religionData) do
        local hasReligion = false
        for _, pd in ipairs(teamData.PlayerData) do
            if pd.ReligionType > 0 then
                hasReligion = true
                break
            end
        end
        if hasReligion then
            table.insert(filtered, teamData)
        end
    end

    table.sort(filtered, function(a, b) return #a.ConvertedCivs > #b.ConvertedCivs end)

    for _, teamData in ipairs(filtered) do
        if #teamData.PlayerData > 1 then
            local religionPlayers = {}
            for _, pd in ipairs(teamData.PlayerData) do
                if pd.ReligionType > 0 then
                    table.insert(religionPlayers, pd)
                end
            end
            table.sort(religionPlayers, function(a, b) return #a.ConvertedCivs > #b.ConvertedCivs end)

            local teamItem = MakeTreeItem({
                Label = function()
                    return JoinLines({
                        GetRankingsTeamLabel(teamData.TeamID),
                        Locale.Lookup("LOC_WORLD_RANKINGS_RELIGION_CONVERT_SUMMARY",
                            #teamData.ConvertedCivs .. "/" .. totalCivs,
                            "LOC_WORLD_RANKINGS_RELIGION_TEAMS_RELIGIONS"),
                    })
                end,
                FocusKey = "team:" .. teamData.TeamID,
            })
            for _, pd in ipairs(religionPlayers) do
                teamItem:AddChild(CreateReligionPlayerRow(pd, totalCivs, "team:" .. teamData.TeamID .. ":"))
            end
            tree:AddChild(teamItem)
        elseif #teamData.PlayerData > 0 then
            if teamData.PlayerData[1].ReligionType > 0 then
                tree:AddChild(CreateReligionPlayerRow(teamData.PlayerData[1], totalCivs, ""))
            end
        end
    end

    AddAdvisorLeaf(tree, Locale.Lookup("LOC_WORLD_RANKINGS_RELIGION_DETAILS"))

    mgr:RestoreFocus(tree, capture)
end

-- ============================================================================
-- Generic / Diplomatic Tab
-- ============================================================================
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
                        if trimmed and trimmed ~= "" then
                            table.insert(diploLines, trimmed)
                        end
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
            return JoinLines(parts)
        end,
        Tooltip = presentation and #presentation.Tooltips > 0
            and function() return JoinLines(presentation.Tooltips) end or nil,
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
            return JoinLines(parts)
        end,
        Tooltip = presentation and #presentation.Tooltips > 0
            and function() return JoinLines(presentation.Tooltips) end or nil,
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

-- ============================================================================
-- Comparison Tables
-- ============================================================================
local function GatherOverallTableVictoryData(victoryType)
    local victoryData = g_victoryData[victoryType]
    if not victoryData then return {} end
    local firstTiebreaker = victoryData.Primary or victoryData
    local secondTiebreaker = victoryData.Secondary or victoryData
    local results = {}

    for _, competitor in ipairs(GetAliveCompetitors()) do
        local progress = Game.GetVictoryProgressForTeam(victoryType, competitor.TeamID)
        if progress ~= nil then
            local entry = {
                TeamID = competitor.TeamID,
                Progress = progress,
                GenericScore = 0,
                FirstTeamScore = 0,
                SecondTeamScore = 0,
                PlayerData = {},
            }
            for _, playerID in ipairs(competitor.PlayerIDs) do
                local player = Players[playerID]
                local firstScore = firstTiebreaker.GetScore(player)
                local secondScore = secondTiebreaker.GetScore(player)
                local additionalSummary = victoryData.AdditionalSummary
                    and victoryData.AdditionalSummary(player) or ""
                table.insert(entry.PlayerData, {
                    PlayerID = playerID,
                    GenericScore = player:GetScore(),
                    FirstScore = firstScore,
                    SecondScore = secondScore,
                    FirstSummary = Locale.Lookup(firstTiebreaker.GetText(player), Round(firstScore, 1)),
                    SecondSummary = Locale.Lookup(secondTiebreaker.GetText(player), Round(secondScore, 1)),
                    AdditionalSummary = Locale.Lookup(additionalSummary),
                })
                entry.GenericScore = math.max(entry.GenericScore, player:GetScore())
                entry.FirstTeamScore = entry.FirstTeamScore + firstScore
                entry.SecondTeamScore = entry.SecondTeamScore + secondScore
            end
            local playerCount = #entry.PlayerData
            entry.FirstTeamScore = entry.FirstTeamScore / playerCount
            entry.SecondTeamScore = entry.SecondTeamScore / playerCount
            table.insert(results, entry)
        end
    end

    table.sort(results, function(a, b)
        if a.Progress ~= b.Progress then return a.Progress > b.Progress end
        if a.FirstTeamScore ~= b.FirstTeamScore then return a.FirstTeamScore > b.FirstTeamScore end
        if a.SecondTeamScore ~= b.SecondTeamScore then return a.SecondTeamScore > b.SecondTeamScore end
        if a.GenericScore ~= b.GenericScore then return a.GenericScore > b.GenericScore end
        return a.TeamID < b.TeamID
    end)
    return results
end

local function GetOverallTableVictoryTypes()
    local result = {}
    local seen = {}
    local function Add(victoryType, label)
        if not seen[victoryType] and Game.IsVictoryEnabled(victoryType)
            and g_victoryData[victoryType] then
            seen[victoryType] = true
            table.insert(result, { VictoryType = victoryType, Label = label })
        end
    end
    Add("VICTORY_TECHNOLOGY", Locale.Lookup("LOC_WORLD_RANKINGS_SCIENCE_VICTORY"))
    Add("VICTORY_CULTURE", Locale.Lookup("LOC_WORLD_RANKINGS_CULTURE_VICTORY"))
    Add("VICTORY_CONQUEST", Locale.Lookup("LOC_WORLD_RANKINGS_DOMINATION_VICTORY"))
    Add("VICTORY_RELIGIOUS", Locale.Lookup("LOC_WORLD_RANKINGS_RELIGION_VICTORY"))
    for row in GameInfo.Victories() do
        if IsCustomVictoryType(row.VictoryType) then
            Add(row.VictoryType, Locale.Lookup(row.Name))
        end
    end
    return result
end

local function RebuildOverallTable(tableView)
    local rows = GetAliveCompetitors()
    local columns = { MakeCompetitorColumn() }
    local victoryTypes = GetOverallTableVictoryTypes()

    for _, victory in ipairs(victoryTypes) do
        local ranked = GatherOverallTableVictoryData(victory.VictoryType)
        local byTeam = {}
        for rank, entry in ipairs(ranked) do
            entry.Rank = rank
            byTeam[entry.TeamID] = entry
        end
        for _, competitor in ipairs(rows) do
            competitor.Overall = competitor.Overall or {}
            competitor.Overall[victory.VictoryType] = byTeam[competitor.TeamID]
        end

        local capturedVictoryType = victory.VictoryType
        table.insert(columns, {
            key = "victory:" .. capturedVictoryType,
            header = victory.Label,
            getCell = function(competitor)
                local entry = competitor.Overall[capturedVictoryType]
                if not entry then return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_NOT_AVAILABLE") end
                local place = Locale.Lookup("LOC_WORLD_RANKINGS_" .. entry.Rank .. "_PLACE")
                return JoinLines({
                    Locale.Lookup("LOC_CAI_WORLD_RANKINGS_PLACE", place),
                    Locale.Lookup("LOC_CAI_WORLD_RANKINGS_VICTORY_PROGRESS",
                        Round(math.max(0, math.min(entry.Progress, 1)) * 100, 1)),
                })
            end,
            getTooltip = function(competitor)
                local entry = competitor.Overall[capturedVictoryType]
                if not entry then return nil end
                if #competitor.PlayerIDs <= 1 then
                    local pd = entry.PlayerData[1]
                    if not pd or not IsPlayerKnownToLocal(pd.PlayerID) then return nil end
                    return JoinLines({
                        pd.FirstSummary,
                        pd.SecondSummary ~= pd.FirstSummary and pd.SecondSummary or nil,
                        pd.AdditionalSummary,
                    })
                end
                local lines = {}
                for _, playerData in ipairs(entry.PlayerData) do
                    if IsPlayerKnownToLocal(playerData.PlayerID) then
                        local details = JoinLines({
                            playerData.FirstSummary,
                            playerData.SecondSummary ~= playerData.FirstSummary
                                and playerData.SecondSummary or nil,
                            playerData.AdditionalSummary,
                        })
                        table.insert(lines, FormatContribution(playerData.PlayerID, details))
                    end
                end
                return JoinLines(lines)
            end,
            sortKey = function(competitor)
                local entry = competitor.Overall[capturedVictoryType]
                return entry and entry.Rank or nil
            end,
            sortAscendingDescription = "LOC_CAI_SORT_CLOSEST_TO_VICTORY_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_FARTHEST_FROM_VICTORY_FIRST",
        })
    end

    local defaultSort = #victoryTypes > 0
        and { column = "victory:" .. victoryTypes[1].VictoryType, ascending = true }
        or { column = "competitor", ascending = true }
    ConfigureRankingTable(tableView, columns, rows, defaultSort)
end

local function GatherScoreTableRows()
    local rows = {}
    local scoreData = {}
    if m_scoreCapturedRows then
        for _, record in ipairs(m_scoreCapturedRows) do
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
    return JoinLines(lines)
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

local function IsScienceDataAhead(a, b)
    for index = 1, math.min(3, #a.Milestones, #b.Milestones) do
        local aProgress = a.Milestones[index].ProgressRatio
        local bProgress = b.Milestones[index].ProgressRatio
        if aProgress ~= bProgress then return aProgress > bProgress end
    end
    return a.PlayerID < b.PlayerID
end

local function GatherScienceTableRows()
    local rows = GetAliveCompetitors()
    for _, competitor in ipairs(rows) do
        competitor.SciencePlayers = {}
        for _, playerID in ipairs(competitor.PlayerIDs) do
            table.insert(competitor.SciencePlayers, GatherSciencePlayerData(Players[playerID]))
        end
        table.sort(competitor.SciencePlayers, IsScienceDataAhead)
        competitor.ScienceLeader = competitor.SciencePlayers[1]
    end
    local ranked = {}
    for _, competitor in ipairs(rows) do table.insert(ranked, competitor) end
    table.sort(ranked, function(a, b)
        if IsScienceDataAhead(a.ScienceLeader, b.ScienceLeader) then return true end
        if IsScienceDataAhead(b.ScienceLeader, a.ScienceLeader) then return false end
        return a.TeamID < b.TeamID
    end)
    for rank, competitor in ipairs(ranked) do competitor.ScienceRank = rank end
    return rows
end

local function GetScienceProgressText(scienceData)
    return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_MILESTONES_DONE",
        scienceData.CompletedCount, scienceData.TotalMilestones)
end

local function GetScienceMilestoneText(milestone)
    if milestone.IsComplete then return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_COMPLETE") end
    if milestone.Percent > 0 then return FormatPercent(milestone.Percent) end
    return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_NOT_STARTED")
end

local function GetScienceContributionTooltip(row, getter)
    local lines = {}
    for _, scienceData in ipairs(row.SciencePlayers) do
        table.insert(lines, FormatContribution(scienceData.PlayerID, getter(scienceData)))
    end
    return #row.SciencePlayers > 1 and JoinLines(lines) or nil
end

local function RebuildScienceTable(tableView)
    local rows = GatherScienceTableRows()
    local columns = {
        MakeCompetitorColumn(),
        {
            key = "progress",
            header = function() return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_SCIENCE_PROGRESS") end,
            getCell = function(row) return GetScienceProgressText(row.ScienceLeader) end,
            getTooltip = function(row)
                local leader = row.ScienceLeader
                return JoinLines({
                    GetScienceContributionTooltip(row, GetScienceProgressText),
                    leader.PlayerID == g_LocalPlayerID and leader.NextStep
                        and Locale.Lookup("LOC_CAI_WORLD_RANKINGS_NEXT_STEP", leader.NextStep) or nil,
                })
            end,
            sortKey = function(row) return row.ScienceRank end,
            sortAscendingDescription = "LOC_CAI_SORT_CLOSEST_TO_VICTORY_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_FARTHEST_FROM_VICTORY_FIRST",
        },
        {
            key = "spaceport",
            header = function() return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_SPACEPORT") end,
            getCell = function(row)
                return Locale.Lookup(row.ScienceLeader.HasSpaceport
                    and "LOC_CAI_WORLD_RANKINGS_BUILT"
                    or "LOC_CAI_WORLD_RANKINGS_NOT_BUILT")
            end,
            getTooltip = function(row)
                return GetScienceContributionTooltip(row, function(data)
                    return Locale.Lookup(data.HasSpaceport
                        and "LOC_CAI_WORLD_RANKINGS_SPACEPORT_BUILT"
                        or "LOC_CAI_WORLD_RANKINGS_SPACEPORT_NOT_BUILT")
                end)
            end,
            sortKey = function(row) return row.ScienceLeader.HasSpaceport and 1 or 0 end,
            sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST",
        },
    }

    local milestoneCount = m_isExp2 and 4 or 3
    for milestoneIndex = 1, milestoneCount do
        local capturedIndex = milestoneIndex
        local header = rows[1] and rows[1].ScienceLeader.Milestones[capturedIndex].Name
            or Locale.Lookup("LOC_WORLD_RANKINGS_SCIENCE_REQUIREMENT_" .. capturedIndex)
        table.insert(columns, {
            key = "milestone:" .. capturedIndex,
            header = header,
            getCell = function(row)
                return GetScienceMilestoneText(row.ScienceLeader.Milestones[capturedIndex])
            end,
            getTooltip = function(row)
                if #row.SciencePlayers <= 1 then
                    local milestone = row.ScienceLeader.Milestones[capturedIndex]
                    return GetTooltipForScienceProject(Players[row.ScienceLeader.PlayerID],
                        milestone.ProjectInfos,
                        milestone.IncludeSpaceport and row.ScienceLeader.HasSpaceport or nil,
                        milestone.FinishedProjects)
                end
                local lines = {}
                for _, scienceData in ipairs(row.SciencePlayers) do
                    local milestone = scienceData.Milestones[capturedIndex]
                    local contribution = FormatContribution(scienceData.PlayerID,
                        GetScienceMilestoneText(milestone))
                    local details = GetTooltipForScienceProject(Players[scienceData.PlayerID],
                        milestone.ProjectInfos,
                        milestone.IncludeSpaceport and scienceData.HasSpaceport or nil,
                        milestone.FinishedProjects)
                    table.insert(lines, JoinLines({ contribution, details }))
                end
                return JoinLines(lines)
            end,
            sortKey = function(row) return row.ScienceLeader.Milestones[capturedIndex].Percent end,
            sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST",
        })
    end

    if m_isExp2 then
        table.insert(columns, {
            key = "distance",
            header = function() return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_DISTANCE_TRAVELED") end,
            getCell = function(row)
                local data = row.ScienceLeader
                if not data.HasLaunchedExpedition then
                    return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_NOT_STARTED")
                end
                return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_LIGHT_YEARS",
                    math.min(data.LightYears, data.LightYearsTotal), data.LightYearsTotal)
            end,
            getTooltip = function(row)
                return GetScienceContributionTooltip(row, function(data)
                    if not data.HasLaunchedExpedition then
                        return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_NOT_STARTED")
                    end
                    return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_LIGHT_YEARS",
                        math.min(data.LightYears, data.LightYearsTotal), data.LightYearsTotal)
                end)
            end,
            sortKey = function(row)
                return row.ScienceLeader.HasLaunchedExpedition and row.ScienceLeader.LightYears or nil
            end,
            sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST",
        })
        table.insert(columns, {
            key = "speed",
            header = function() return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_SPEED_PER_TURN") end,
            getCell = function(row)
                local data = row.ScienceLeader
                return data.HasLaunchedExpedition and tostring(data.LightYearsRate or 0)
                    or Locale.Lookup("LOC_CAI_WORLD_RANKINGS_NOT_STARTED")
            end,
            getTooltip = function(row)
                return GetScienceContributionTooltip(row, function(data)
                    return data.HasLaunchedExpedition and tostring(data.LightYearsRate or 0)
                        or Locale.Lookup("LOC_CAI_WORLD_RANKINGS_NOT_STARTED")
                end)
            end,
            sortKey = function(row)
                return row.ScienceLeader.HasLaunchedExpedition and row.ScienceLeader.LightYearsRate or nil
            end,
            sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST",
        })
    end
    ConfigureRankingTable(tableView, columns, rows, { column = "progress", ascending = true })
end

local function GatherCultureTableRows()
    local rows = {}
    for _, teamData in ipairs(GatherCultureData()) do
        local playerIDs = {}
        local bestData = nil
        for _, playerData in ipairs(teamData.PlayerData) do
            table.insert(playerIDs, playerData.PlayerID)
            local score = playerData.NumVisitingUs / math.max(playerData.NumRequiredTourists, 1)
            local bestScore = bestData
                and bestData.NumVisitingUs / math.max(bestData.NumRequiredTourists, 1) or -1
            if not bestData or score > bestScore
                or (score == bestScore
                    and playerData.NumRequiredTourists > bestData.NumRequiredTourists) then
                bestData = playerData
            end
        end
        if bestData then
            table.insert(rows, {
                TeamID = teamData.TeamID,
                PlayerIDs = playerIDs,
                PlayerData = teamData.PlayerData,
                CultureLeader = bestData,
            })
        end
    end
    return rows
end

local function GetCultureContributionTooltip(row, getter)
    local lines = {}
    for _, playerData in ipairs(row.PlayerData) do
        table.insert(lines, FormatContribution(playerData.PlayerID, getter(playerData)))
    end
    return #row.PlayerData > 1 and JoinLines(lines) or nil
end

local function RebuildCultureTable(tableView)
    local rows = GatherCultureTableRows()
    local allPlayerData = {}
    for _, row in ipairs(rows) do
        for _, playerData in ipairs(row.PlayerData) do table.insert(allPlayerData, playerData) end
    end
    local columns = {
        MakeCompetitorColumn(),
        {
            key = "progress",
            header = function() return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_VICTORY_PROGRESS_HEADER") end,
            getCell = function(row)
                return FormatPercent(row.CultureLeader.NumVisitingUs
                    / math.max(row.CultureLeader.NumRequiredTourists, 1) * 100)
            end,
            getTooltip = function(row)
                return GetCultureContributionTooltip(row, function(data)
                    return FormatPercent(data.NumVisitingUs
                        / math.max(data.NumRequiredTourists, 1) * 100)
                end)
            end,
            sortKey = function(row)
                return row.CultureLeader.NumVisitingUs
                    / math.max(row.CultureLeader.NumRequiredTourists, 1)
            end,
            sortAscendingDescription = "LOC_CAI_SORT_FARTHEST_FROM_VICTORY_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_CLOSEST_TO_VICTORY_FIRST",
        },
        {
            key = "visiting",
            header = function() return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_VISITING_TOURISTS") end,
            getCell = function(row) return tostring(row.CultureLeader.NumVisitingUs) end,
            getTooltip = function(row)
                local parts = {
                    GetCultureContributionTooltip(row,
                        function(data) return tostring(data.NumVisitingUs) end),
                }
                local containsLocalPlayer = false
                for _, playerID in ipairs(row.PlayerIDs) do
                    if playerID == g_LocalPlayerID then containsLocalPlayer = true; break end
                end
                if containsLocalPlayer and g_LocalPlayer then
                    local culture = g_LocalPlayer:GetCulture()
                    local sourceLines = {}
                    for _, sourceData in ipairs(allPlayerData) do
                        if sourceData.PlayerID ~= g_LocalPlayerID then
                            table.insert(sourceLines, FormatContribution(sourceData.PlayerID, JoinLines({
                                Locale.Lookup("LOC_CAI_WORLD_RANKINGS_VISITING_US",
                                    culture:GetTouristsFrom(sourceData.PlayerID)),
                                culture:GetTouristsFromTooltip(sourceData.PlayerID),
                            })))
                        end
                    end
                    table.insert(parts, JoinLines(sourceLines))
                end
                return JoinLines(parts)
            end,
            sortKey = function(row) return row.CultureLeader.NumVisitingUs end,
            sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST",
        },
        {
            key = "required",
            header = function() return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_TOURISTS_REQUIRED") end,
            getCell = function(row) return tostring(row.CultureLeader.NumRequiredTourists) end,
            getTooltip = function(row)
                return GetCultureContributionTooltip(row,
                    function(data) return tostring(data.NumRequiredTourists) end)
            end,
            sortKey = function(row) return row.CultureLeader.NumRequiredTourists end,
            sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST",
        },
        {
            key = "domestic",
            header = function() return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_DOMESTIC_TOURISTS") end,
            getCell = function(row) return tostring(row.CultureLeader.NumStaycationers) end,
            getTooltip = function(row)
                return GetCultureContributionTooltip(row,
                    function(data) return tostring(data.NumStaycationers) end)
            end,
            sortKey = function(row) return row.CultureLeader.NumStaycationers end,
            sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST",
        },
        {
            key = "turns",
            header = function() return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_TURNS_TO_VICTORY") end,
            getCell = function(row)
                local turns = row.CultureLeader.TurnsTillCulturalVictory
                return turns and turns > 0 and tostring(turns)
                    or Locale.Lookup("LOC_CAI_WORLD_RANKINGS_NOT_AVAILABLE")
            end,
            getTooltip = function(row)
                return GetCultureContributionTooltip(row, function(data)
                    return data.TurnsTillCulturalVictory and data.TurnsTillCulturalVictory > 0
                        and tostring(data.TurnsTillCulturalVictory)
                        or Locale.Lookup("LOC_CAI_WORLD_RANKINGS_NOT_AVAILABLE")
                end)
            end,
            sortKey = function(row)
                local turns = row.CultureLeader.TurnsTillCulturalVictory
                return turns and turns > 0 and turns or nil
            end,
            sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST",
        },
    }
    ConfigureRankingTable(tableView, columns, rows, { column = "progress", ascending = false })
end

local function GetDominationCapturedTooltip(row)
    local captured = {}
    for _, playerData in ipairs(row.PlayerData) do
        for _, playerID in ipairs(playerData.CapturedCapitals) do
            table.insert(captured, GetPlayerLabel(playerID))
        end
    end
    if #captured == 0 then return nil end
    if #row.PlayerData <= 1 then return JoinLines(captured) end
    local lines = {}
    for _, playerData in ipairs(row.PlayerData) do
        local playerCaptured = {}
        for _, playerID in ipairs(playerData.CapturedCapitals) do
            table.insert(playerCaptured, GetPlayerLabel(playerID))
        end
        local value = tostring(#playerData.CapturedCapitals)
        if #playerCaptured > 0 then value = JoinLines({ value, JoinLines(playerCaptured) }) end
        table.insert(lines, FormatContribution(playerData.PlayerID, value))
    end
    return JoinLines(lines)
end

local function GetDominationContributionTooltip(row)
    if #row.PlayerData <= 1 then return nil end
    local lines = {}
    for _, playerData in ipairs(row.PlayerData) do
        local value = Locale.Lookup(playerData.HasOriginalCapital
            and "LOC_CAI_WORLD_RANKINGS_HAS_CAPITAL"
            or "LOC_CAI_WORLD_RANKINGS_LOST_CAPITAL")
        table.insert(lines, FormatContribution(playerData.PlayerID, value))
    end
    return JoinLines(lines)
end

local function RebuildDominationTable(tableView)
    local rows = GatherDominationData()
    local competitors = GetAliveCompetitors()
    for _, row in ipairs(rows) do
        local competitor = FindCompetitor(competitors, row.TeamID)
        row.PlayerIDs = competitor and competitor.PlayerIDs or {}
        row.OriginalCapitalsHeld = 0
        for _, playerData in ipairs(row.PlayerData) do
            if playerData.HasOriginalCapital then
                row.OriginalCapitalsHeld = row.OriginalCapitalsHeld + 1
            end
        end
        row.Progress = Game.GetVictoryProgressForTeam("VICTORY_CONQUEST", row.TeamID)
    end
    local columns = {
        MakeCompetitorColumn(),
        {
            key = "progress",
            header = function() return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_VICTORY_PROGRESS_HEADER") end,
            getCell = function(row)
                return row.Progress ~= nil and FormatPercent(row.Progress * 100)
                    or Locale.Lookup("LOC_CAI_WORLD_RANKINGS_NOT_AVAILABLE")
            end,
            getTooltip = function(row)
                if #row.PlayerData <= 1 then return nil end
                return JoinLines({
                    GetDominationContributionTooltip(row),
                    GetDominationCapturedTooltip(row),
                })
            end,
            sortKey = function(row) return row.Progress end,
            sortAscendingDescription = "LOC_CAI_SORT_FARTHEST_FROM_VICTORY_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_CLOSEST_TO_VICTORY_FIRST",
        },
        {
            key = "originals",
            header = function() return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_ORIGINAL_CAPITALS_HELD") end,
            getCell = function(row)
                return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_VALUE_OF_TOTAL",
                    row.OriginalCapitalsHeld, #row.PlayerData)
            end,
            getTooltip = function(row) return GetDominationContributionTooltip(row) end,
            sortKey = function(row) return row.OriginalCapitalsHeld end,
            sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST",
        },
        {
            key = "captured",
            header = function() return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_CAPITALS_CAPTURED_HEADER") end,
            getCell = function(row) return tostring(row.TotalCapturedCapitals) end,
            getTooltip = function(row) return GetDominationCapturedTooltip(row) end,
            sortKey = function(row) return row.TotalCapturedCapitals end,
            sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST",
        },
    }
    ConfigureRankingTable(tableView, columns, rows, { column = "progress", ascending = false })
end

local function GetReligionNames(row)
    local names = {}
    for _, religionType in ipairs(row.ReligionTypes) do
        table.insert(names, Game.GetReligion():GetName(religionType))
    end
    return JoinLines(names)
end

local function GetReligionTooltip(row)
    if #row.PlayerData <= 1 then return nil end
    local lines = {}
    for _, playerData in ipairs(row.PlayerData) do
        if playerData.ReligionType and playerData.ReligionType > 0 then
            table.insert(lines, FormatContribution(playerData.PlayerID,
                Game.GetReligion():GetName(playerData.ReligionType)))
        end
    end
    return JoinLines(lines)
end

local function GetReligionConversionTooltip(row)
    if #row.PlayerData <= 1 then
        local pd = row.PlayerData[1]
        if not pd or not pd.ConvertedCivs or #pd.ConvertedCivs == 0 then return nil end
        local converted = {}
        for _, playerID in ipairs(pd.ConvertedCivs) do
            table.insert(converted, GetPlayerLabel(playerID))
        end
        return JoinLines(converted)
    end
    local lines = {}
    for _, playerData in ipairs(row.PlayerData) do
        if playerData.ReligionType and playerData.ReligionType > 0 then
            local converted = {}
            for _, playerID in ipairs(playerData.ConvertedCivs) do
                table.insert(converted, GetPlayerLabel(playerID))
            end
            table.insert(lines, FormatContribution(playerData.PlayerID,
                JoinLines({ tostring(#playerData.ConvertedCivs), JoinLines(converted) })))
        end
    end
    return JoinLines(lines)
end

local function RebuildReligionTable(tableView)
    local religionData, totalCivs = GatherReligionData()
    local rows = {}
    for _, row in ipairs(religionData) do
        if #row.ReligionTypes > 0 then
            row.PlayerIDs = {}
            for _, playerData in ipairs(row.PlayerData) do
                table.insert(row.PlayerIDs, playerData.PlayerID)
            end
            row.TotalCivs = totalCivs
            table.insert(rows, row)
        end
    end
    local columns = {
        MakeCompetitorColumn(),
        {
            key = "progress",
            header = function() return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_VICTORY_PROGRESS_HEADER") end,
            getCell = function(row) return FormatPercent(#row.ConvertedCivs / math.max(row.TotalCivs, 1) * 100) end,
            getTooltip = GetReligionConversionTooltip,
            sortKey = function(row) return #row.ConvertedCivs / math.max(row.TotalCivs, 1) end,
            sortAscendingDescription = "LOC_CAI_SORT_FARTHEST_FROM_VICTORY_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_CLOSEST_TO_VICTORY_FIRST",
        },
        {
            key = "religion",
            header = function() return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_RELIGION") end,
            getCell = GetReligionNames,
            getTooltip = GetReligionTooltip,
            sortKey = GetReligionNames,
            sortAscendingDescription = "LOC_CAI_SORT_A_TO_Z",
            sortDescendingDescription = "LOC_CAI_SORT_Z_TO_A",
        },
        {
            key = "converted",
            header = function() return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_CIVILIZATIONS_CONVERTED") end,
            getCell = function(row)
                return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_VALUE_OF_TOTAL",
                    #row.ConvertedCivs, row.TotalCivs)
            end,
            getTooltip = GetReligionConversionTooltip,
            sortKey = function(row) return #row.ConvertedCivs end,
            sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST",
        },
    }
    ConfigureRankingTable(tableView, columns, rows, { column = "progress", ascending = false })
end

local function RebuildDiplomaticTable(tableView, victoryType)
    local rows = {}
    local total = GlobalParameters.DIPLOMATIC_VICTORY_POINTS_REQUIRED
    for _, teamData in ipairs(GatherGenericData()) do
        local playerIDs = {}
        local bestPlayerID = nil
        local bestPoints = -1
        local points = {}
        for _, playerData in ipairs(teamData.PlayerData) do
            local playerID = playerData.PlayerID
            local value = Players[playerID]:GetStats():GetDiplomaticVictoryPoints()
            table.insert(playerIDs, playerID)
            points[playerID] = value
            if value > bestPoints or (value == bestPoints
                and (bestPlayerID == nil or playerID < bestPlayerID)) then
                bestPoints = value
                bestPlayerID = playerID
            end
        end
        if #playerIDs > 0 then
            table.insert(rows, {
                TeamID = teamData.TeamID,
                PlayerIDs = playerIDs,
                Points = points,
                BestPoints = bestPoints,
                BestPlayerID = bestPlayerID,
                TotalPoints = total,
                Progress = Game.GetVictoryProgressForTeam(victoryType, teamData.TeamID),
            })
        end
    end
    local function GetDiploBreakdown(playerID)
        local pPlayer = Players[playerID]
        if not pPlayer or not pPlayer:IsAlive() then return nil end
        local pStats = pPlayer:GetStats()
        if not pStats or not pStats.GetDiplomaticVictoryPointsTooltip then return nil end
        local tt = pStats:GetDiplomaticVictoryPointsTooltip()
        if not tt or tt == "" then return nil end
        local lines = {}
        for segment in (tt .. "[NEWLINE]"):gmatch("(.-)%[NEWLINE%]") do
            local trimmed = segment:match("^%s*(.-)%s*$")
            if trimmed and trimmed ~= "" then
                table.insert(lines, trimmed)
            end
        end
        return #lines > 0 and JoinLines(lines) or nil
    end
    local columns = {
        MakeCompetitorColumn(),
        {
            key = "progress",
            header = function() return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_VICTORY_PROGRESS_HEADER") end,
            getCell = function(row)
                return row.Progress ~= nil and FormatPercent(row.Progress * 100)
                    or Locale.Lookup("LOC_CAI_WORLD_RANKINGS_NOT_AVAILABLE")
            end,
            getTooltip = function(row)
                if #row.PlayerIDs <= 1 then return nil end
                local lines = {}
                for _, playerID in ipairs(row.PlayerIDs) do
                    table.insert(lines, FormatContribution(playerID, row.Points[playerID]))
                end
                return JoinLines(lines)
            end,
            sortKey = function(row) return row.Progress end,
            sortAscendingDescription = "LOC_CAI_SORT_FARTHEST_FROM_VICTORY_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_CLOSEST_TO_VICTORY_FIRST",
        },
        {
            key = "points",
            header = function() return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_DIPLOMATIC_POINTS") end,
            getCell = function(row)
                return Locale.Lookup("LOC_CAI_WORLD_RANKINGS_VALUE_OF_TOTAL",
                    row.BestPoints, row.TotalPoints)
            end,
            getTooltip = function(row)
                if #row.PlayerIDs <= 1 then
                    return GetDiploBreakdown(row.BestPlayerID)
                end
                local lines = {}
                for _, playerID in ipairs(row.PlayerIDs) do
                    local breakdown = GetDiploBreakdown(playerID)
                    table.insert(lines, FormatContribution(playerID,
                        JoinLines({ tostring(row.Points[playerID]), breakdown })))
                end
                return JoinLines(lines)
            end,
            sortKey = function(row) return row.BestPoints end,
            sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST",
        },
    }
    ConfigureRankingTable(tableView, columns, rows, { column = "points", ascending = false })
end

local function GetTableKind(tabDef)
    if tabDef.label == CAI_TAB_OVERALL then
        local ruleset = GameConfiguration.GetRuleSet()
        if ruleset == "RULESET_SCENARIO_WARMACHINE"
            or ruleset == "RULESET_SCENARIO_VIKINGS"
            or ruleset == "RULESET_SCENARIO_POLAND"
            or ruleset == "RULESET_SCENARIO_INDONESIA_KHMER"
            or ruleset == "RULESET_SCENARIO_AUSTRALIA"
            or ruleset == "RULESET_SCENARIO_ALEXANDER" then
            return nil
        end
        return "overall"
    elseif tabDef.label == CAI_TAB_SCORE then return "score"
    elseif tabDef.label == CAI_TAB_SCIENCE then return "science"
    elseif tabDef.label == CAI_TAB_CULTURE then return "culture"
    elseif tabDef.label == CAI_TAB_DOMINATION then return "domination"
    elseif tabDef.label == CAI_TAB_RELIGION then return "religion"
    elseif tabDef.victoryType == "VICTORY_DIPLOMATIC" and m_isExp2 then return "diplomatic"
    end
    return nil
end

local function RebuildTable(entry, victoryType)
    if entry.tableKind == "overall" then RebuildOverallTable(entry.dataTable)
    elseif entry.tableKind == "score" then RebuildScoreTable(entry.dataTable)
    elseif entry.tableKind == "science" then RebuildScienceTable(entry.dataTable)
    elseif entry.tableKind == "culture" then RebuildCultureTable(entry.dataTable)
    elseif entry.tableKind == "domination" then RebuildDominationTable(entry.dataTable)
    elseif entry.tableKind == "religion" then RebuildReligionTable(entry.dataTable)
    elseif entry.tableKind == "diplomatic" then
        RebuildDiplomaticTable(entry.dataTable, victoryType or entry.victoryType)
    end
end

local function GetTableAdvisorText(entry)
    if entry.tableKind == "score" then
        return JoinLines({
            Locale.Lookup("LOC_WORLD_RANKINGS_SCORE_DETAILS"),
            Locale.Lookup("LOC_WORLD_RANKINGS_SCORE_CONDITION", Game.GetMaxGameTurns()),
        })
    elseif entry.tableKind == "science" then
        local count = m_isExp2 and 4 or 3
        local detailsKey = m_isExp2
            and "LOC_WORLD_RANKINGS_SCIENCE_DETAILS_EXP2"
            or "LOC_WORLD_RANKINGS_SCIENCE_DETAILS"
        local parts = { Locale.Lookup(detailsKey) }
        for index = 1, count do
            table.insert(parts, Locale.Lookup("LOC_WORLD_RANKINGS_SCIENCE_REQUIREMENT_" .. index))
        end
        if m_isExp2 and g_LocalPlayer then
            table.insert(parts, Locale.Lookup("LOC_WORLD_RANKINGS_SCIENCE_REQUIREMENT_FINAL",
                g_LocalPlayer:GetStats():GetScienceVictoryPointsTotalNeeded()))
        end
        return JoinLines(parts)
    elseif entry.tableKind == "culture" then
        return JoinLines({
            Locale.Lookup("LOC_WORLD_RANKINGS_CULTURE_VICTORY_DETAILS"),
            Locale.Lookup("LOC_WORLD_RANKINGS_CULTURE_DETAILS_DOMESTIC_TOURISTS"),
            Locale.Lookup("LOC_WORLD_RANKINGS_CULTURE_DETAILS_VISITING_TOURISTS"),
        })
    elseif entry.tableKind == "domination" then
        return Locale.Lookup("LOC_WORLD_RANKINGS_DOMINATION_DETAILS")
    elseif entry.tableKind == "religion" then
        return Locale.Lookup("LOC_WORLD_RANKINGS_RELIGION_DETAILS")
    elseif entry.tableKind == "diplomatic" then
        local info = GameInfo.Victories[entry.victoryType]
        return info and info.Description and Locale.Lookup(info.Description) or nil
    end
    return nil
end

local function RebuildActiveEntry(entry, victoryType)
    local resolvedVictoryType = victoryType or entry.victoryType
    if m_viewMode == "table" and entry.dataTable then
        RebuildTable(entry, resolvedVictoryType)
    else
        entry.rebuildFn(entry.tree, resolvedVictoryType)
    end
end

local function GetFocusedCompetitorTeamID(entry)
    if m_viewMode == "table" and entry and entry.dataTable then
        local row = entry.dataTable:GetFocusedRow()
        local column = entry.dataTable:GetFocusedColumn()
        if column and column.key then
            entry.focusedVictoryType = column.key:match("^victory:(.+)$")
                or entry.focusedVictoryType
        end
        if row and row.TeamID ~= nil then
            entry.focusedTeamID = row.TeamID
            return row.TeamID
        end
    end
    local focused = mgr:GetFocusedWidget()
    local focusKey = focused and focused.FocusKey and tostring(focused.FocusKey) or ""
    if entry and entry.tableKind == "overall" then
        entry.focusedVictoryType = focusKey:match("^overall:([^:]+)")
            or entry.focusedVictoryType
    end
    local teamID = tonumber(focusKey:match("team:(%d+)"))
    if teamID ~= nil then
        entry.focusedTeamID = teamID
        return teamID
    end
    local playerID = tonumber(focusKey:match("player:(%d+)"))
    local player = playerID ~= nil and Players[playerID] or nil
    if player then
        entry.focusedTeamID = player:GetTeam()
        return entry.focusedTeamID
    end
    return entry and entry.focusedTeamID or nil
end

local function PrepareCompetitorFocus(entry, teamID)
    if teamID == nil then return end
    if m_viewMode == "table" and entry.dataTable then
        local columnKey = entry.tableKind == "overall" and entry.focusedVictoryType
            and "victory:" .. entry.focusedVictoryType or "competitor"
        mgr:PrepareFocus(entry.dataTable, entry.dataTable.Id
            .. ":row:team:" .. teamID .. ":" .. columnKey)
        return
    end

    local alivePlayerIDs = {}
    for _, playerID in ipairs(Teams[teamID]) do
        if IsAliveAndMajor(playerID) then table.insert(alivePlayerIDs, playerID) end
    end
    local focusKey = #alivePlayerIDs > 1 and "team:" .. teamID
        or (#alivePlayerIDs == 1 and "player:" .. alivePlayerIDs[1] or nil)
    if entry.tableKind == "overall" and entry.focusedVictoryType and focusKey then
        focusKey = "overall:" .. entry.focusedVictoryType .. ":" .. focusKey
    end
    if focusKey then mgr:PrepareFocus(entry.tree, focusKey) end
end

local function SetViewMode(viewMode)
    if viewMode ~= "table" and viewMode ~= "tree" then
        LogError("World Rankings received invalid view mode " .. tostring(viewMode))
        return false
    end
    local index = m_tabs and m_tabs:GetActivePageIndex() or 0
    local entry = m_trees[index]
    local teamID = GetFocusedCompetitorTeamID(entry)
    if m_viewMode ~= viewMode then
        m_viewMode = viewMode
        SaveViewModeSetting(viewMode)
    end
    if entry then
        RebuildActiveEntry(entry, entry.victoryType)
        PrepareCompetitorFocus(entry, teamID)
        local activeView = m_viewMode == "table" and entry.dataTable or entry.tree
        if not activeView then activeView = entry.tree end
        mgr:SetFocus(activeView)
    end
    return true
end

local function ToggleViewMode()
    return SetViewMode(m_viewMode == "table" and "tree" or "table")
end

-- ============================================================================
-- Panel Build
-- ============================================================================
local function BuildPanel()
    m_panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function()
            return Controls.Title:GetText() or Locale.Lookup("LOC_WORLD_RANKINGS_TITLE")
        end,
    })

    m_tabs = mgr:CreateWidget(TABS_ID, "TabControl", {})
    m_trees = {}

    for i, tabDef in ipairs(m_capturedTabs) do
        local page = m_tabs:AddPage(function() return tabDef.label end)
        local entry = {
            rebuildFn = tabDef.rebuildFn,
            victoryType = tabDef.victoryType,
            tableKind = GetTableKind(tabDef),
        }
        local treeId = "CAIWorldRank_Tree" .. i
        entry.tree = mgr:CreateWidget(treeId, "Tree", {
            Label = function()
                return JoinLines({
                    tabDef.label,
                    entry.tableKind == nil and m_viewMode == "table"
                        and Locale.Lookup("LOC_CAI_WORLD_RANKINGS_TABLE_UNAVAILABLE") or nil,
                })
            end,
            HiddenPredicate = function()
                return entry.tableKind ~= nil and m_viewMode == "table"
            end,
        })
        if entry.tableKind then
            entry.dataTable = mgr:CreateWidget("CAIWorldRank_Table" .. i, "DataTable", {
                Label = function() return tabDef.label end,
                HiddenPredicate = function() return m_viewMode ~= "table" end,
            })
            entry.dataTable:On("row_focus_enter", function(_, row)
                if row then entry.focusedTeamID = row.TeamID end
            end)
            entry.dataTable:On("cell_focus_enter", function(_, _, column)
                if column and column.key then
                    entry.focusedVictoryType = column.key:match("^victory:(.+)$")
                        or entry.focusedVictoryType
                end
            end)
            page:AddChild(entry.dataTable)
        end
        page:AddChild(entry.tree)
        if entry.tableKind and entry.tableKind ~= "overall" then
            entry.advisor = mgr:CreateWidget("CAIWorldRank_TableAdvisor" .. i, "StaticText", {
                Label = function() return GetTableAdvisorText(entry) end,
                HiddenPredicate = function() return m_viewMode ~= "table" end,
            })
            page:AddChild(entry.advisor)
        end
        m_trees[i] = entry
    end

    m_panel:AddChild(m_tabs)

    m_switchView = mgr:CreateWidget(SWITCH_VIEW_ID, "Button", {
        Label = function()
            return Locale.Lookup(m_viewMode == "table"
                and "LOC_CAI_WORLD_RANKINGS_SWITCH_ALL_TO_TREE"
                or "LOC_CAI_WORLD_RANKINGS_SWITCH_SUPPORTED_TO_TABLE")
        end,
    })
    m_switchView:On("activate", function() ToggleViewMode() end)
    m_panel:AddChild(m_switchView)

    m_panel:AddInputBindings({
        {
            Key = Keys["1"],
            IsAlt = true,
            MSG = KeyEvents.KeyDown,
            Description = "LOC_CAI_TREE_SWITCH_TO_TABLE",
            Action = function() return SetViewMode("table") end,
        },
        {
            Key = Keys["2"],
            IsAlt = true,
            MSG = KeyEvents.KeyDown,
            Description = "LOC_CAI_TREE_SWITCH_TO_TREE",
            Action = function() return SetViewMode("tree") end,
        },
        {
            Key = Keys.VK_ESCAPE,
            MSG = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_CLOSE",
            Action = function()
                if not IsCAITutorialScreenCloseAllowed() then
                    AnnounceCAITutorialScreenCloseBlocked()
                    return true
                end
                Close()
                return true
            end,
        },
    })

    m_tabs:On("value_changed", function(_, idx)
        if m_isMirroringTab then return end
        m_isMirroringTab = true
        local tabDef = m_capturedTabs[idx]
        if tabDef and tabDef.callback then
            tabDef.callback()
        end
        m_isMirroringTab = false
    end)
end

-- ============================================================================
-- Push / Pop
-- ============================================================================
local function PushPanel()
    if not mgr then return end
    if not m_panel then BuildPanel() end

    local idx, vt = DetectActiveTab()
    if m_pendingVictoryType then vt = m_pendingVictoryType end
    m_pendingVictoryType = nil

    if m_trees[idx] then
        m_isMirroringTab = true
        m_tabs:SetActivePage(idx, true)
        m_isMirroringTab = false
        local entry = m_trees[idx]
        RebuildActiveEntry(entry, vt or entry.victoryType)
    end

    mgr:Push(m_panel, PopupPriority.Low)
end

local function PopPanel()
    if mgr and m_panel and mgr:GetWidgetById(PANEL_ID) then
        mgr:RemoveFromStack(PANEL_ID)
    end
    m_panel = nil
    m_tabs = nil
    m_trees = {}
    m_switchView = nil
end

-- ============================================================================
-- Tab Capture Wraps
-- ============================================================================
AddTab = WrapFunc(AddTab, function(orig, label, callback)
    orig(label, callback)
    table.insert(m_capturedTabs, {
        label = label,
        callback = callback,
    })
end)

if AddExtraTab then
    AddExtraTab = WrapFunc(AddExtraTab, function(orig, label, callback)
        orig(label, callback)
        table.insert(m_capturedTabs, {
            label = label,
            callback = callback,
        })
    end)
end

if BASE_AddTab then
    BASE_AddTab = WrapFunc(BASE_AddTab, function(orig, label, callback)
        orig(label, callback)
        table.insert(m_capturedTabs, {
            label = label,
            callback = callback,
        })
    end)
end

-- ============================================================================
-- Resolve tab rebuild functions after capture
-- ============================================================================
local function ResolveTabRebuilds()
    for i, tabDef in ipairs(m_capturedTabs) do
        tabDef.rebuildFn = nil
        tabDef.victoryType = nil

        if tabDef.label == CAI_TAB_OVERALL then
            tabDef.rebuildFn = RebuildOverallTree
        elseif tabDef.label == CAI_TAB_SCORE then
            tabDef.rebuildFn = RebuildScoreTree
        elseif tabDef.label == CAI_TAB_SCIENCE then
            tabDef.rebuildFn = RebuildScienceTree
        elseif tabDef.label == CAI_TAB_CULTURE then
            tabDef.rebuildFn = RebuildCultureTree
        elseif tabDef.label == CAI_TAB_DOMINATION then
            tabDef.rebuildFn = RebuildDominationTree
        elseif tabDef.label == CAI_TAB_RELIGION then
            tabDef.rebuildFn = RebuildReligionTree
        else
            tabDef.rebuildFn = RebuildGenericTree
        end
    end
end

PopulateTabs = WrapFunc(PopulateTabs, function(orig)
    m_capturedTabs = {}
    orig()
    ResolveTabRebuilds()
end)

-- ============================================================================
-- Identify generic/diplomatic victory type from closure callbacks
-- ============================================================================
-- After PopulateTabs wraps capture the tabs, we need to know which victoryType
-- each generic tab is for. The vanilla callbacks are closures over victoryType.
-- We identify them by matching the label or by wrapping ViewGeneric/ViewDiplomatic.

local function IdentifyGenericVictoryTypes()
    for i, tabDef in ipairs(m_capturedTabs) do
        if tabDef.rebuildFn == RebuildGenericTree and not tabDef.victoryType then
            for row in GameInfo.Victories() do
                local vt = row.VictoryType
                if IsCustomVictoryType(vt) and Game.IsVictoryEnabled(vt) then
                    if vt == "VICTORY_DIPLOMATIC" and m_isExp2 then
                        if tabDef.label == Locale.Lookup("LOC_TOOLTIP_DIPLOMACY_CONGRESS_BUTTON") then
                            tabDef.victoryType = vt
                            break
                        end
                    elseif m_isBBG and vt == BBG_TRAD_DOM_VICTORY then
                        -- BBG labels this tab with the button tooltip string, not row.Name.
                        if tabDef.label == Locale.Lookup(BBG_TRAD_DOM_BUTTON_KEY) then
                            tabDef.victoryType = vt
                            break
                        end
                    else
                        if tabDef.label == Locale.Lookup(row.Name) then
                            tabDef.victoryType = vt
                            break
                        end
                    end
                end
            end
        end
    end
end

-- ============================================================================
-- View Function Wraps
-- ============================================================================
local function ViewSync(tabIdx, victoryType)
    m_pendingVictoryType = victoryType

    if not m_panel or not m_trees[tabIdx] then return end

    m_isMirroringTab = true
    m_tabs:SetActivePage(tabIdx, true)
    m_isMirroringTab = false
    local entry = m_trees[tabIdx]
    entry.victoryType = victoryType or entry.victoryType
    RebuildActiveEntry(entry, entry.victoryType)
end

local function FindTabIndex(label)
    for i, tabDef in ipairs(m_capturedTabs) do
        if tabDef.label == label then return i end
    end
    return nil
end

ViewOverall = WrapFunc(ViewOverall, function(orig)
    orig()
    local idx = FindTabIndex(CAI_TAB_OVERALL)
    if idx then ViewSync(idx) end
end)

ViewScore = WrapFunc(ViewScore, function(orig)
    BeginScoreCapture()
    orig()
    EndScoreCapture()
    local idx = FindTabIndex(CAI_TAB_SCORE)
    if idx then ViewSync(idx) end
end)

ViewScience = WrapFunc(ViewScience, function(orig)
    orig()
    local idx = FindTabIndex(CAI_TAB_SCIENCE)
    if idx then ViewSync(idx) end
end)

ViewCulture = WrapFunc(ViewCulture, function(orig)
    orig()
    local idx = FindTabIndex(CAI_TAB_CULTURE)
    if idx then ViewSync(idx) end
end)

ViewDomination = WrapFunc(ViewDomination, function(orig)
    orig()
    local idx = FindTabIndex(CAI_TAB_DOMINATION)
    if idx then ViewSync(idx) end
end)

ViewReligion = WrapFunc(ViewReligion, function(orig)
    orig()
    local idx = FindTabIndex(CAI_TAB_RELIGION)
    if idx then ViewSync(idx) end
end)

local origViewGeneric = ViewGeneric
ViewGeneric = function(victoryType)
    m_currentGenericVictoryType = victoryType
    BeginGenericCapture(victoryType)
    origViewGeneric(victoryType)
    EndGenericCapture(victoryType)
    for i, tabDef in ipairs(m_capturedTabs) do
        if tabDef.victoryType == victoryType then
            ViewSync(i, victoryType)
            break
        end
    end
end

if ViewDiplomatic then
    local origViewDiplomatic = ViewDiplomatic
    ViewDiplomatic = function(victoryType)
        m_currentGenericVictoryType = victoryType
        origViewDiplomatic(victoryType)
        for i, tabDef in ipairs(m_capturedTabs) do
            if tabDef.victoryType == victoryType then
                ViewSync(i, victoryType)
                break
            end
        end
    end
end

-- BBG's Traditional Domination tab renders through ViewTraditionalDomination
-- (not ViewGeneric), so drive the same capture + tab-sync path for it.
if ViewTraditionalDomination then
    local origViewTraditionalDomination = ViewTraditionalDomination
    ViewTraditionalDomination = function(victoryType)
        m_currentGenericVictoryType = victoryType
        BeginGenericCapture(victoryType)
        origViewTraditionalDomination(victoryType)
        EndGenericCapture(victoryType)
        for i, tabDef in ipairs(m_capturedTabs) do
            if tabDef.victoryType == victoryType then
                ViewSync(i, victoryType)
                break
            end
        end
    end
end

-- ============================================================================
-- Lifecycle Wraps
-- ============================================================================
Open = WrapFunc(Open, function(orig)
    orig()
    if mgr and not ContextPtr:IsHidden() then
        IdentifyGenericVictoryTypes()
        PushPanel()
    end
end)

Close = WrapFunc(Close, function(orig)
    PopPanel()
    orig()
end)

OpenCulture = WrapFunc(OpenCulture, function(orig)
    orig()
end)

OnShutdown = WrapFunc(OnShutdown, function(orig)
    PopPanel()
    orig()
end)
ContextPtr:SetShutdown(OnShutdown)

-- ============================================================================
-- Input Handler
-- ============================================================================
local function HandleInput(input)
    if mgr and mgr:GetWidgetById(PANEL_ID) then
        if mgr:HandleInput(input) then
            return true
        end
    end
    return false
end

LateInitialize = WrapFunc(LateInitialize, function(orig)
    orig()
    ContextPtr:SetInputHandler(HandleInput, true)
end)
