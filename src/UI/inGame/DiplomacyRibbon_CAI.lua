include("caiUtils")
include("Civ6Common")
local info             = ExposedMembers.CAIInfo or {}
ExposedMembers.CAIInfo = info

if GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_PIRATES" then
    include("DiplomacyRibbon_PiratesScenario")
elseif GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_CIV_ROYALE" then
    include("DiplomacyRibbon_CivRoyaleScenario_CAIBase")
elseif IsExpansion2Active() then
    include("DiplomacyRibbon_Expansion2")
elseif IsExpansion1Active() then
    include("DiplomacyRibbon_Expansion1")
else
    include("DiplomacyRibbon")
end

local mgr = ExposedMembers.CAI_UIManager
local IS_PIRATES_SCENARIO = GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_PIRATES"
-- The Pirates scenario replaces leaders with custom score categories that do not
-- map onto the diplomacy columns, so it keeps the flat list-only presentation.
local SCENARIO_LIST_ONLY = IS_PIRATES_SCENARIO
local PIRATES_SCORE_CATEGORIES = {}
if IS_PIRATES_SCENARIO then
    local scoreCategories = GameInfo.ScoringCategories
    for i = 0, #scoreCategories - 1 do
        local category = scoreCategories[i]
        if category.PrimaryKey == "CATEGORY_SCENARIO1"
            or category.PrimaryKey == "CATEGORY_SCENARIO2"
            or category.PrimaryKey == "CATEGORY_SCENARIO3" then
            PIRATES_SCORE_CATEGORIES[#PIRATES_SCORE_CATEGORIES + 1] = {
                Index = i,
                Name = category.Name,
            }
        end
    end
end

local PANEL_ID    = "CAIDiploRibbon_Panel"
local TABLE_ID    = "CAIDiploRibbon_Table"
local LIST_ID     = "CAIDiploRibbon_List"
local SORT_ID     = "CAIDiploRibbon_Sort"
local CONGRESS_ID = "CAIDiploRibbon_Congress"
local SWITCH_ID   = "CAIDiploRibbon_Switch"

local ACTION_OPEN_LIST = Input.GetActionId("UI_DiplomacyRibbonOpenList")
local ACTION_OPEN_CONGRESS = Input.GetActionId("UI_DiplomacyRibbonOpenWorldCongress")
local ACTION_SPEAK_CONGRESS_INFO = Input.GetActionId("UI_DiplomacyRibbonSpeakWorldCongressInfo")

-- Alliances are the highest form of relationship, so they rank above every
-- diplomatic state. Everything else mirrors the friendliness order the
-- diplomacy action view uses.
local FOREIGN_REL_RANK = {
    DIPLO_STATE_ALLIED          = 6,
    DIPLO_STATE_DECLARED_FRIEND = 5,
    DIPLO_STATE_FRIENDLY        = 4,
    DIPLO_STATE_NEUTRAL         = 3,
    DIPLO_STATE_UNFRIENDLY      = 2,
    DIPLO_STATE_DENOUNCED       = 1,
    DIPLO_STATE_WAR             = 0,
    DIPLO_STATE_DECLARED_WAR    = 0,
}

local m_panel = nil
local m_table = nil
local m_list = nil
local m_sort = nil
local m_pushed = false
local m_viewMode = SCENARIO_LIST_ONLY and "list" or "table"
local m_sortColumn = nil
local m_sortAscending = false
local m_players = {}
local m_columns = {}
local m_sortOptions = {}


local function GetLocalPlayer()
    local playerID = Game.GetLocalPlayer()
    if playerID == nil or playerID < 0 then return nil, nil end
    return playerID, Players[playerID]
end

local function FormatValuePerTurn(value)
    if value == 0 then
        return Locale.ToNumber(value)
    else
        return Locale.Lookup("{1: number +#,###.#;-#,###.#}", value)
    end
end

local function FormatBalance(value)
    return Locale.ToNumber(value, "#,###.#")
end

local function FormatRatePerTurn(value)
    return Locale.Lookup("LOC_HUD_REPORTS_PER_TURN", value)
end

local function JoinNonEmpty(parts, separator)
    local result = {}
    for _, v in ipairs(parts) do
        if v and v ~= "" then
            table.insert(result, v)
        end
    end
    return table.concat(result, separator)
end

local function HasCongressButton()
    if not IsExpansion2Active() then return false end
    if not GameCapabilities.HasCapability("CAPABILITY_WORLD_CONGRESS") then return false end
    if Game.GetEras():GetCurrentEra() < GlobalParameters.WORLD_CONGRESS_INITIAL_ERA then return false end
    return true
end

local function GetCongressUnavailableReason()
    if not IsExpansion2Active()
        or not GameCapabilities.HasCapability("CAPABILITY_WORLD_CONGRESS") then
        return Locale.Lookup("LOC_CAI_UI_WORLD_CONGRESS_UNAVAILABLE")
    end

    local initialEra = GlobalParameters.WORLD_CONGRESS_INITIAL_ERA
    if Game.GetEras():GetCurrentEra() < initialEra then
        local era = GameInfo.Eras[initialEra]
        local eraName = era and Locale.Lookup(era.Name) or tostring(initialEra)
        return Locale.Lookup("LOC_CAI_UI_WORLD_CONGRESS_START_ERA", eraName)
    end
    return nil
end

local function IsCongressInSession()
    local WORLD_CONGRESS_STAGE_1 = DB.MakeHash("TURNSEG_WORLDCONGRESS_1")
    local WORLD_CONGRESS_STAGE_2 = DB.MakeHash("TURNSEG_WORLDCONGRESS_2")
    local WORLD_CONGRESS_RESOLUTION = DB.MakeHash("TURNSEG_WORLDCONGRESS_RESOLUTION")
    local seg = Game.GetCurrentTurnSegment()
    return seg == WORLD_CONGRESS_STAGE_1 or seg == WORLD_CONGRESS_STAGE_2 or seg == WORLD_CONGRESS_RESOLUTION
end

local function GetCongressTooltip()
    local parts = {}
    local _, player = GetLocalPlayer()
    if not player then return end

    if not IsExpansion2Active() then return end
    local playerFavor = player:GetFavor()
    local favorPerTurn = player:GetFavorPerTurn()
    table.insert(parts, Locale.Lookup("LOC_CAI_TOP_PANEL_FAVOR") .. ": "
        .. Locale.Lookup("LOC_CAI_TOP_PANEL_BALANCE_AND_RATE",
            FormatBalance(playerFavor),
            FormatRatePerTurn(FormatValuePerTurn(favorPerTurn))))

    if HasCongressButton() then
        if IsCongressInSession() then
            table.insert(parts, Locale.Lookup("LOC_WORLD_CONGRESS_IS_CURRENTLY_IN_SESSION"))
            if info and info.GetCongressStatus then
                local betweenTurnStatus = info.GetCongressStatus()
                if betweenTurnStatus then table.insert(parts, betweenTurnStatus) end
            end
        else
            local pData = Game.GetWorldCongress():GetMeetingStatus()
            local turnsLeft = pData.TurnsLeft + 1
            table.insert(parts, Locale.Lookup("LOC_WORLD_CONGRESS_HUD_BAR_TIME_UNTIL_NEXT_SESSION", turnsLeft))
        end
    end
    return JoinNonEmpty(parts, "[NEWLINE]")
end

local function ActivateCongress()
    if IsCongressInSession() then
        LuaEvents.CongressButton_ResumeCongress()
    else
        LuaEvents.CongressButton_ShowCongressResults()
    end
end

local function IsMaskedPlayer(playerID, localPlayerID)
    if not GameConfiguration.IsAnyMultiplayer() then return false end
    if playerID == localPlayerID then return false end
    local pConfig = PlayerConfigurations[playerID]
    if not pConfig:IsHuman() then return false end
    return not Players[localPlayerID]:GetDiplomacy():HasMet(playerID)
end

local function GetTeamLabel(playerID, localPlayerID)
    local isMet = (playerID == localPlayerID) or Players[localPlayerID]:GetDiplomacy():HasMet(playerID)
    if not isMet then return nil end
    local teamID = PlayerConfigurations[playerID]:GetTeam()
    if #Teams[teamID] <= 1 then return nil end
    return Locale.Lookup("LOC_WORLD_RANKINGS_TEAM", teamID + 1)
end

local function GetRelationshipLabel(playerID, localPlayerID)
    if playerID == localPlayerID then return nil end
    if localPlayerID == PlayerTypes.NONE or localPlayerID == PlayerTypes.OBSERVER then return nil end
    if not GameCapabilities.HasCapability("CAPABILITY_DISPLAY_HUD_RIBBON_RELATIONSHIPS") then return nil end

    local pPlayer = Players[playerID]
    local pConfig = PlayerConfigurations[playerID]
    local isHuman = pConfig:IsHuman()
    local localDiplomacy = Players[localPlayerID]:GetDiplomacy()
    local eRelationship = pPlayer:GetDiplomaticAI():GetDiplomaticStateIndex(localPlayerID)
    local relationType = GameInfo.DiplomaticStates[eRelationship].StateType
    local isValid = (isHuman and Relationship.IsValidWithHuman(relationType))
        or (not isHuman and Relationship.IsValidWithAI(relationType))
    if not isValid then return nil end

    if IsExpansion1Active() or IsExpansion2Active() then
        local allianceType = localDiplomacy:GetAllianceType(playerID)
        if allianceType ~= -1 then
            local allianceName = Locale.Lookup(GameInfo.Alliances[allianceType].Name)
            local allianceLevel = localDiplomacy:GetAllianceLevel(playerID)
            return Locale.Lookup("LOC_DIPLOMACY_ALLIANCE_FLAG_TT", allianceName, allianceLevel)
        end
    end

    return Locale.Lookup(GameInfo.DiplomaticStates[eRelationship].Name)
end

-- includeRelationship defaults to true. The table view shows relationship in its
-- own column, so it passes false to keep the leader label to identity only.
local function GetLeaderLabel(playerID, localPlayerID, includeRelationship)
    if includeRelationship == nil then includeRelationship = true end
    local pConfig = PlayerConfigurations[playerID]
    if not pConfig then return "?" end

    if IS_PIRATES_SCENARIO then
        local parts = {
            Locale.Lookup(pConfig:GetPlayerName()),
            Locale.Lookup(pConfig:GetCivilizationShortDescription()),
        }
        if playerID == localPlayerID then
            table.insert(parts, Locale.Lookup("LOC_HUD_CITY_YOU"))
        end
        if Players[playerID]:IsTurnActive() then
            table.insert(parts, Locale.Lookup("LOC_CAI_DIPLO_RIBBON_ACTIVE_TURN"))
        end
        return JoinNonEmpty(parts, ", ")
    end

    local parts = {}
    if not IsMaskedPlayer(playerID, localPlayerID) then
        local name = Locale.Lookup(pConfig:GetLeaderName())
        local civName = Locale.Lookup(pConfig:GetCivilizationShortDescription())
        parts = { name, civName }

        if playerID == localPlayerID then
            table.insert(parts, Locale.Lookup("LOC_HUD_CITY_YOU"))
        end

        if includeRelationship then
            local rel = GetRelationshipLabel(playerID, localPlayerID)
            if rel then
                table.insert(parts, rel)
            end
        end

        local team = GetTeamLabel(playerID, localPlayerID)
        if team then
            table.insert(parts, team)
        end
    else
        parts = { Locale.Lookup("LOC_DIPLOPANEL_UNMET_PLAYER") .. " (" .. pConfig:GetPlayerName() .. ")" }
    end

    if Players[playerID]:IsTurnActive() then
        table.insert(parts, Locale.Lookup("LOC_CAI_DIPLO_RIBBON_ACTIVE_TURN"))
    end
    if GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_CIV_ROYALE"
        and not pConfig:IsAlive() then
        table.insert(parts, Locale.Lookup("LOC_HUD_RIBBON_REDDEATH_ELIMINATED"))
    end

    return JoinNonEmpty(parts, ", ")
end

local function GetLeaderTooltip(playerID, localPlayerID)
    if IS_PIRATES_SCENARIO then
        local pPlayer = Players[playerID]
        if not pPlayer then return "" end

        local parts = {}
        for _, category in ipairs(PIRATES_SCORE_CATEGORIES) do
            table.insert(parts, Locale.Lookup("LOC_CAI_PIRATES_SCORE_CATEGORY",
                Locale.Lookup(category.Name), pPlayer:GetCategoryScore(category.Index)))
        end
        table.insert(parts, Locale.Lookup("LOC_CAI_DIPLO_RIBBON_SCORE", Round(pPlayer:GetScore())))
        return JoinNonEmpty(parts, "[NEWLINE]")
    end

    if IsMaskedPlayer(playerID, localPlayerID) then return "" end

    local pPlayer = Players[playerID]
    if not pPlayer then return "" end

    local parts = {}

    local pCities = pPlayer:GetCities()
    local pCapital = pCities and pCities:GetCapitalCity()
    if pCapital then
        table.insert(parts, Locale.Lookup("LOC_CAI_DIPLO_RIBBON_CAPITAL", Locale.Lookup(pCapital:GetName())))
    end

    if Game.IsVictoryEnabled("VICTORY_SCORE") and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_SCORE") then
        table.insert(parts, Locale.Lookup("LOC_CAI_DIPLO_RIBBON_SCORE", Round(pPlayer:GetScore())))
    end

    if IsExpansion2Active() and Game.IsVictoryEnabled("VICTORY_DIPLOMATIC") then
        table.insert(parts, Locale.Lookup("LOC_CAI_DIPLO_RIBBON_FAVOR", Round(pPlayer:GetFavor())))
    end

    if Game.IsVictoryEnabled("VICTORY_CONQUEST") and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
        table.insert(parts,
            Locale.Lookup("LOC_CAI_DIPLO_RIBBON_MILITARY", Round(pPlayer:GetStats():GetMilitaryStrengthWithoutTreasury())))
    end

    if GameCapabilities.HasCapability("CAPABILITY_SCIENCE") and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
        table.insert(parts, Locale.Lookup("LOC_CAI_DIPLO_RIBBON_SCIENCE", Round(pPlayer:GetTechs():GetScienceYield())))
    end

    if GameCapabilities.HasCapability("CAPABILITY_CULTURE") and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
        table.insert(parts, Locale.Lookup("LOC_CAI_DIPLO_RIBBON_CULTURE", Round(pPlayer:GetCulture():GetCultureYield())))
    end

    if GameCapabilities.HasCapability("CAPABILITY_GOLD") and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
        table.insert(parts,
            Locale.Lookup("LOC_CAI_DIPLO_RIBBON_GOLD", math.floor(pPlayer:GetTreasury():GetGoldBalance())))
    end

    if GameCapabilities.HasCapability("CAPABILITY_RELIGION") and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
        table.insert(parts, Locale.Lookup("LOC_CAI_DIPLO_RIBBON_FAITH", Round(pPlayer:GetReligion():GetFaithBalance())))
    end

    return JoinNonEmpty(parts, "[NEWLINE]")
end

-- ============================================================================
-- Table cell / sort helpers
-- ============================================================================

local function GetLeaderSortName(playerID, localPlayerID)
    if IsMaskedPlayer(playerID, localPlayerID) then
        return Locale.Lookup("LOC_DIPLOPANEL_UNMET_PLAYER")
    end
    local pConfig = PlayerConfigurations[playerID]
    return pConfig and Locale.Lookup(pConfig:GetLeaderName()) or ""
end

local function GetCapitalName(playerID, localPlayerID)
    if IsMaskedPlayer(playerID, localPlayerID) then return nil end
    local pPlayer = Players[playerID]
    if not pPlayer then return nil end
    local pCities = pPlayer:GetCities()
    local pCapital = pCities and pCities:GetCapitalCity()
    return pCapital and Locale.Lookup(pCapital:GetName()) or nil
end

local function RelationshipSortKey(playerID, localPlayerID)
    if playerID == localPlayerID then return nil end
    if IsMaskedPlayer(playerID, localPlayerID) then return nil end
    if not GameCapabilities.HasCapability("CAPABILITY_DISPLAY_HUD_RIBBON_RELATIONSHIPS") then return nil end

    local pPlayer = Players[playerID]
    local eRelationship = pPlayer:GetDiplomaticAI():GetDiplomaticStateIndex(localPlayerID)
    local stateType = GameInfo.DiplomaticStates[eRelationship].StateType
    local rank = FOREIGN_REL_RANK[stateType] or 3

    if IsExpansion1Active() or IsExpansion2Active() then
        local localDiplomacy = Players[localPlayerID]:GetDiplomacy()
        local allianceType = localDiplomacy:GetAllianceType(playerID)
        if allianceType ~= -1 then
            -- Alliance always outranks any plain diplomatic state; a higher
            -- alliance level outranks a lower one.
            rank = 7 + (localDiplomacy:GetAllianceLevel(playerID) or 0)
        end
    end
    return rank
end

local function CompareSortValues(a, b)
    if a == b then return 0 end
    if a == nil then return 1 end
    if b == nil then return -1 end
    if type(a) == "number" and type(b) == "number" then return a < b and -1 or 1 end
    if type(a) == "boolean" and type(b) == "boolean" then return a and 1 or -1 end
    return Locale.Compare(tostring(a), tostring(b))
end

-- ============================================================================
-- Player ordering
-- ============================================================================

-- Natural order: the local player first, then everyone else by the turn they
-- were met (the vanilla ribbon ordering). Masked/unmet players are filtered to
-- match the list the old ribbon showed.
local function BuildNaturalPlayers()
    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == -1 then return {} end

    local localPlayer = Players[localPlayerID]
    local localDiplomacy = IS_PIRATES_SCENARIO and nil or localPlayer:GetDiplomacy()

    local kPlayers = GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_CIV_ROYALE"
        and PlayerManager.GetWasEverAliveMajors()
        or PlayerManager.GetAliveMajors()
    if IS_PIRATES_SCENARIO then
        table.sort(kPlayers, function(a, b) return a:GetID() < b:GetID() end)
    else
        table.sort(kPlayers,
            function(a, b) return localDiplomacy:GetMetTurn(a:GetID()) < localDiplomacy:GetMetTurn(b:GetID()) end)
    end

    local ordered = { localPlayerID }
    for _, pPlayer in ipairs(kPlayers) do
        local playerID = pPlayer:GetID()
        if playerID ~= localPlayerID and (not IS_PIRATES_SCENARIO or IsPiratePlayer(playerID)) then
            if IS_PIRATES_SCENARIO then
                table.insert(ordered, playerID)
            else
                local isMet = localDiplomacy:HasMet(playerID)
                local pConfig = PlayerConfigurations[playerID]
                local isHumanMP = GameConfiguration.IsAnyMultiplayer() and pConfig:IsHuman()
                if isMet or isHumanMP
                    or (GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_CIV_ROYALE"
                        and not pConfig:IsAlive()) then
                    table.insert(ordered, playerID)
                end
            end
        end
    end
    return ordered
end

-- ============================================================================
-- Columns
-- ============================================================================

local function BuildColumns()
    local columns = {
        {
            key = "leader",
            header = function() return Locale.Lookup("LOC_CAI_DIPLOMACY_LEADERS") end,
            getCell = function(playerID)
                return GetLeaderLabel(playerID, Game.GetLocalPlayer(), false)
            end,
            sortKey = function(playerID)
                return GetLeaderSortName(playerID, Game.GetLocalPlayer())
            end,
            sortAscendingDescription = "LOC_CAI_SORT_A_TO_Z",
            sortDescendingDescription = "LOC_CAI_SORT_Z_TO_A",
        },
        {
            key = "relationship",
            header = function() return Locale.Lookup("LOC_DIPLOMACY_OVERVIEW_OUR_RELATIONSHIP") end,
            getCell = function(playerID)
                return GetRelationshipLabel(playerID, Game.GetLocalPlayer()) or ""
            end,
            sortKey = function(playerID)
                return RelationshipSortKey(playerID, Game.GetLocalPlayer())
            end,
            sortAscendingDescription = "LOC_CAI_SORT_MOST_HOSTILE_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_FRIENDLIEST_FIRST",
        },
        {
            key = "capital",
            header = function() return Locale.Lookup("LOC_CAI_DIPLO_RIBBON_COL_CAPITAL") end,
            getCell = function(playerID)
                return GetCapitalName(playerID, Game.GetLocalPlayer()) or ""
            end,
            sortKey = function(playerID)
                return GetCapitalName(playerID, Game.GetLocalPlayer())
            end,
            sortAscendingDescription = "LOC_CAI_SORT_A_TO_Z",
            sortDescendingDescription = "LOC_CAI_SORT_Z_TO_A",
        },
    }

    local function AddValueColumn(key, headerTag, valueFn)
        table.insert(columns, {
            key = key,
            header = function() return Locale.Lookup(headerTag) end,
            getCell = function(playerID)
                local localPlayerID = Game.GetLocalPlayer()
                if IsMaskedPlayer(playerID, localPlayerID) then return "" end
                local pPlayer = Players[playerID]
                if not pPlayer then return "" end
                return Locale.ToNumber(valueFn(pPlayer))
            end,
            sortKey = function(playerID)
                local localPlayerID = Game.GetLocalPlayer()
                if IsMaskedPlayer(playerID, localPlayerID) then return nil end
                local pPlayer = Players[playerID]
                if not pPlayer then return nil end
                return valueFn(pPlayer)
            end,
            sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST",
        })
    end

    if Game.IsVictoryEnabled("VICTORY_SCORE") and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_SCORE") then
        AddValueColumn("score", "LOC_CAI_DIPLO_RIBBON_COL_SCORE",
            function(p) return Round(p:GetScore()) end)
    end

    if IsExpansion2Active() and Game.IsVictoryEnabled("VICTORY_DIPLOMATIC") then
        AddValueColumn("favor", "LOC_CAI_DIPLO_RIBBON_COL_FAVOR",
            function(p) return Round(p:GetFavor()) end)
    end

    if Game.IsVictoryEnabled("VICTORY_CONQUEST") and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
        AddValueColumn("military", "LOC_CAI_DIPLO_RIBBON_COL_MILITARY",
            function(p) return Round(p:GetStats():GetMilitaryStrengthWithoutTreasury()) end)
    end

    if GameCapabilities.HasCapability("CAPABILITY_SCIENCE") and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
        AddValueColumn("science", "LOC_CAI_DIPLO_RIBBON_COL_SCIENCE",
            function(p) return Round(p:GetTechs():GetScienceYield()) end)
    end

    if GameCapabilities.HasCapability("CAPABILITY_CULTURE") and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
        AddValueColumn("culture", "LOC_CAI_DIPLO_RIBBON_COL_CULTURE",
            function(p) return Round(p:GetCulture():GetCultureYield()) end)
    end

    if GameCapabilities.HasCapability("CAPABILITY_GOLD") and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
        AddValueColumn("gold", "LOC_CAI_DIPLO_RIBBON_COL_GOLD",
            function(p) return math.floor(p:GetTreasury():GetGoldBalance()) end)
    end

    if GameCapabilities.HasCapability("CAPABILITY_RELIGION") and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
        AddValueColumn("faith", "LOC_CAI_DIPLO_RIBBON_COL_FAITH",
            function(p) return Round(p:GetReligion():GetFaithBalance()) end)
    end

    return columns
end

-- Apply the current sort selection to the natural order for the list view. The
-- table sorts itself; this keeps the list consistent with the shared sort.
local function GetOrderedListPlayers()
    local ordered = {}
    for _, playerID in ipairs(m_players) do
        table.insert(ordered, playerID)
    end
    if not m_sortColumn then return ordered end

    local sortColumn = nil
    for _, column in ipairs(m_columns) do
        if column.key == m_sortColumn then
            sortColumn = column
            break
        end
    end
    if not sortColumn or not sortColumn.sortKey then return ordered end

    local keys = {}
    for _, playerID in ipairs(ordered) do
        keys[playerID] = sortColumn.sortKey(playerID)
    end
    -- Stable sort: fall back to natural index for equal values.
    local naturalIndex = {}
    for index, playerID in ipairs(ordered) do
        naturalIndex[playerID] = index
    end
    table.sort(ordered, function(a, b)
        local cmp = CompareSortValues(keys[a], keys[b])
        if not m_sortAscending then cmp = -cmp end
        if cmp ~= 0 then return cmp < 0 end
        return naturalIndex[a] < naturalIndex[b]
    end)
    return ordered
end

-- ============================================================================
-- Sort dropdown
-- ============================================================================

local function BuildSortOptions(columns)
    local options = {
        {
            label = Locale.Lookup("LOC_CAI_DATATABLE_SORT_NATURAL"),
            value = { column = nil, ascending = false },
        },
    }
    for _, column in ipairs(columns) do
        if column.sortKey then
            local header = type(column.header) == "function" and column.header() or column.header or ""
            table.insert(options, {
                label = header .. "[NEWLINE]" .. Locale.Lookup(column.sortAscendingDescription),
                value = { column = column.key, ascending = true },
            })
            table.insert(options, {
                label = header .. "[NEWLINE]" .. Locale.Lookup(column.sortDescendingDescription),
                value = { column = column.key, ascending = false },
            })
        end
    end
    return options
end

local function SyncSortDropdown()
    if not m_sort then return end
    for index, option in ipairs(m_sortOptions) do
        local sort = option.value
        if sort.column == m_sortColumn and
            (sort.column == nil or sort.ascending == m_sortAscending) then
            m_sort:SetSelectedIndex(index, true)
            return
        end
    end
end

-- ============================================================================
-- List population
-- ============================================================================

local function PopulateList(list)
    list:ClearChildren()
    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == -1 then return end

    for _, playerID in ipairs(GetOrderedListPlayers()) do
        local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAIDiploRibbon_L"), "MenuItem", {
            Label = function() return GetLeaderLabel(playerID, localPlayerID) end,
            Tooltip = function() return GetLeaderTooltip(playerID, localPlayerID) end,
        })
        item.FocusKey = "leader:" .. playerID
        if not IS_PIRATES_SCENARIO then
            item:On("activate", function()
                local uiLeader = GetUILeadersByID()[playerID]
                if uiLeader then
                    uiLeader.SelectButton:DoLeftClick()
                end
            end)
        end
        list:AddChild(item)
    end
end

-- ============================================================================
-- View mode
-- ============================================================================

local function GetActiveView()
    return m_viewMode == "list" and m_list or m_table
end

local function SetViewMode(viewMode)
    if SCENARIO_LIST_ONLY then return false end
    if viewMode ~= "table" and viewMode ~= "list" then return false end
    m_viewMode = viewMode
    local activeView = GetActiveView()
    if activeView then
        mgr:SetFocus(activeView)
    end
    return true
end

local function ToggleViewMode()
    return SetViewMode(m_viewMode == "table" and "list" or "table")
end

-- ============================================================================
-- Rebuild
-- ============================================================================

local function RebuildListView()
    if not m_list then return end
    local capture = mgr:CaptureFocusKey(m_list)
    PopulateList(m_list)
    if capture then mgr:RestoreFocus(m_list, capture) end
end

-- ============================================================================
-- Panel construction
-- ============================================================================

local function ClosePanel()
    if mgr and m_panel then
        m_pushed = false
        mgr:RemoveFromStack(PANEL_ID)
    end
end

local function EnsurePanelBuilt()
    m_panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function() return Locale.Lookup("LOC_CAI_DIPLO_RIBBON_LABEL") end,
    })
    m_panel:On("focus_leave", function() ClosePanel() end)
    m_panel:AddInputBinding({
        Key         = Keys.VK_ESCAPE,
        MSG         = KeyEvents.KeyUp,
        Description = "LOC_CAI_KB_CLOSE",
        Action      = function()
            ClosePanel()
            return true
        end,
    })
    if not SCENARIO_LIST_ONLY then
        m_panel:AddInputBindings({
            {
                Key = Keys["1"],
                IsAlt = true,
                MSG = KeyEvents.KeyDown,
                Description = "LOC_CAI_REPORTS_SWITCH_TO_TABLE",
                Action = function() return SetViewMode("table") end,
            },
            {
                Key = Keys["2"],
                IsAlt = true,
                MSG = KeyEvents.KeyDown,
                Description = "LOC_CAI_REPORTS_SWITCH_TO_LIST",
                Action = function() return SetViewMode("list") end,
            },
        })
    end

    if not SCENARIO_LIST_ONLY then
        m_sort = mgr:CreateWidget(SORT_ID, "Dropdown", {
            Label = function() return Locale.Lookup("LOC_CAI_DIPLO_RIBBON_ORDER_BY") end,
            FocusKey = "diplo-ribbon:sort",
            HiddenPredicate = function() return m_viewMode ~= "list" end,
        })
        m_sort:SetOptions(m_sortOptions)
        m_sort:On("value_changed", function(_, sort)
            m_sortColumn = sort.column
            m_sortAscending = sort.ascending == true
            if m_table then
                m_table:SetDefaultSort(sort.column
                    and { column = sort.column, ascending = sort.ascending }
                    or nil)
                m_table:Rebuild()
            end
            RebuildListView()
        end)
        m_panel:AddChild(m_sort)

        m_table = mgr:CreateWidget(TABLE_ID, "DataTable", {
            Label = function() return Locale.Lookup("LOC_CAI_DIPLOMACY_LEADERS") end,
            HiddenPredicate = function() return m_viewMode ~= "table" end,
        })
        m_table:SetRowsProvider(function() return m_players end)
        m_table:SetRowKeyGetter(function(playerID) return playerID end)
        m_table:SetRowLabelGetter(function(playerID)
            return GetLeaderLabel(playerID, Game.GetLocalPlayer(), false)
        end)
        m_table:On("row_activate", function(_, playerID)
            local uiLeader = GetUILeadersByID()[playerID]
            if uiLeader then
                uiLeader.SelectButton:DoLeftClick()
            end
        end)
        m_table:On("sort_changed", function(_, columnKey, ascending)
            m_sortColumn = columnKey
            m_sortAscending = ascending == true
            SyncSortDropdown()
            RebuildListView()
        end)
        m_panel:AddChild(m_table)
    end

    m_list = mgr:CreateWidget(LIST_ID, "List", {
        Label = function() return Locale.Lookup("LOC_CAI_DIPLOMACY_LEADERS") end,
        HiddenPredicate = function() return m_viewMode ~= "list" end,
    })
    m_panel:AddChild(m_list)

    local congress = mgr:CreateWidget(CONGRESS_ID, "Button", {
        Label = function() return Locale.Lookup("LOC_CAI_DIPLO_RIBBON_CONGRESS") end,
        Tooltip = function() return GetCongressTooltip() end,
        HiddenPredicate = function() return not HasCongressButton() end,
    })
    congress.FocusKey = "congress"
    congress:On("activate", function() ActivateCongress() end)
    m_panel:AddChild(congress)

    if not SCENARIO_LIST_ONLY then
        local switchView = mgr:CreateWidget(SWITCH_ID, "Button", {
            Label = function()
                return Locale.Lookup(m_viewMode == "table"
                    and "LOC_CAI_REPORTS_SWITCH_TO_LIST"
                    or "LOC_CAI_REPORTS_SWITCH_TO_TABLE")
            end,
        })
        switchView.FocusKey = "switch-view"
        switchView:On("activate", function() ToggleViewMode() end)
        m_panel:AddChild(switchView)
    end
end

local function CAI_RebuildViews()
    if not m_panel then return end
    if ContextPtr:IsHidden() then return end

    local capture = mgr:CaptureFocusKey(m_panel)

    m_players = BuildNaturalPlayers()

    if not SCENARIO_LIST_ONLY and m_table then
        m_columns = BuildColumns()
        m_table:SetColumns(m_columns)
        local sortColumn, sortAscending = m_table:GetSort()
        if sortColumn and not m_table:GetColumnIndex(sortColumn) then
            m_table:SetDefaultSort(nil)
            sortColumn = nil
            sortAscending = false
        end
        m_sortColumn = sortColumn
        m_sortAscending = sortAscending == true
        m_sortOptions = BuildSortOptions(m_columns)
        if m_sort then
            m_sort:SetOptions(m_sortOptions)
            SyncSortDropdown()
        end
        m_table:Rebuild()
    end

    PopulateList(m_list)

    if capture then mgr:RestoreFocus(m_panel, capture) end
end

-- ============================================================================
-- Lifecycle
-- ============================================================================

local function OpenPanel()
    if not mgr then return end
    local _, player = GetLocalPlayer()
    if not player then
        Speak(Locale.Lookup("LOC_CAI_UI_DIPLOMACY_UNAVAILABLE"))
        return
    end

    ClosePanel()
    EnsurePanelBuilt()
    CAI_RebuildViews()
    m_pushed = true
    mgr:Push(m_panel, { focus = GetActiveView() })
end

local function RebuildIfPushed()
    if not m_pushed or not m_panel then return end
    CAI_RebuildViews()
end

UpdateLeaders = WrapFunc(UpdateLeaders, function(orig)
    orig()
    RebuildIfPushed()
end)

local function OnInputActionStarted(actionId)
    if ContextPtr:IsHidden() then return end
    if actionId == ACTION_OPEN_LIST then
        OpenPanel()
    elseif actionId == ACTION_OPEN_CONGRESS then
        if HasCongressButton() then
            ActivateCongress()
        else
            Speak(GetCongressUnavailableReason())
        end
    elseif actionId == ACTION_SPEAK_CONGRESS_INFO then
        local tt = GetCongressTooltip()
        if tt then
            Speak(tt)
        end
    end
end

Events.InputActionStarted.Add(OnInputActionStarted)
LuaEvents.CAILaunchBarOpen_DiploRibbonList.Remove(OpenPanel)
LuaEvents.CAILaunchBarOpen_DiploRibbonList.Add(OpenPanel)

OnShutdown = WrapFunc(OnShutdown, function(orig)
    Events.InputActionStarted.Remove(OnInputActionStarted)
    LuaEvents.CAILaunchBarOpen_DiploRibbonList.Remove(OpenPanel)
    ClosePanel()
    orig()
end)

ContextPtr:SetShutdown(OnShutdown)
