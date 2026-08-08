include("caiUtils")
include("Civ6Common")
include("GameCapabilities")

if GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_INDONESIA_KHMER" then
    include("CityStates_Indonesia_KhmerScenario")
elseif IsExpansion2Active() then
    include("CityStates_Expansion2")
elseif IsExpansion1Active() then
    include("CityStates_Expansion1")
else
    include("CityStates")
end

local mgr                = ExposedMembers.CAI_UIManager

local MODE               = {
    Overview      = "Overview",
    SendEnvoys    = "SendEnvoys",
    EnvoySent     = "EnvoySent",
    InfluencedBy  = "InfluencedBy",
    Quests        = "Quests",
    Relationships = "Relationships",
}

local DIPLO_PIP_INFO     = {
    ["DIPLO_STATE_PROTECTOR"]       = { Tooltip = "LOC_CITY_STATES_DIPLO_SUZERAIN", Short = "LOC_CAI_CITYSTATES_REL_SUZERAIN", Sort = 4 },
    ["DIPLO_STATE_PATRON"]          = { Tooltip = "LOC_CITY_STATES_DIPLO_GOOD", Short = "LOC_CAI_CITYSTATES_REL_PATRON", Sort = 3 },
    ["DIPLO_STATE_AWARE"]           = { Tooltip = "LOC_CITY_STATES_DIPLO_AWARE", Short = "LOC_CAI_CITYSTATES_REL_AWARE", Sort = 2 },
    ["DIPLO_STATE_WAR_WITH_MAJOR"]  = { Tooltip = "LOC_CITY_STATES_DIPLO_WAR", Short = "LOC_CAI_CITYSTATES_REL_AT_WAR", Sort = 1 },
    ["DIPLO_STATE_WAR_WITH_MINOR"]  = { Tooltip = "LOC_CITY_STATES_DIPLO_WAR", Short = "LOC_CAI_CITYSTATES_REL_AT_WAR", Sort = 1 },
    ["DIPLO_STATE_MINOR_MINOR_WAR"] = { Tooltip = "LOC_CITY_STATES_DIPLO_WAR", Short = "LOC_CAI_CITYSTATES_REL_AT_WAR", Sort = 1 },
}

local PANEL_ID           = "CAICityStates_Panel"
local OVERVIEW_TABLE_ID  = "CAICityStates_OverviewTable"
local TREE_SORT_ID       = "CAICityStates_TreeSort"
local TREE_VIEW_ID       = "CAICityStates_TreeView"
local SWITCH_VIEW_ID     = "CAICityStates_SwitchView"
local ENVOY_SLIDER_ID    = "CAICityStates_EnvoySlider"
local CONFIRM_ENVOY_ID   = "CAICityStates_ConfirmEnvoy"
local LOOK_AT_ID         = "CAICityStates_LookAt"
local WAR_PEACE_ID       = "CAICityStates_WarPeace"
local LEVY_ID            = "CAICityStates_Levy"
local VIEW_SETTING_SECTION = "UI"
local VIEW_SETTING_ID      = "CityStatesViewMode"

local m_ui               = {
    panel        = nil,
    overview     = nil,
    treeSort     = nil,
    treeView     = nil,
    switchView   = nil,
    envoySlider  = nil,
    confirmEnvoy = nil,
    lookAt       = nil,
    warPeace     = nil,
    levy         = nil,
}

local function LoadViewModeSetting()
    local stored = tostring(CAI.GetConfigValue(
        VIEW_SETTING_SECTION, VIEW_SETTING_ID, "table")):lower()
    if stored == "tree" then return "tree" end
    if stored ~= "table" then
        LogWarn("City-States ignored invalid saved view mode " .. tostring(stored))
    end
    return "table"
end

local function SaveViewModeSetting(viewMode)
    if not CAI.SetConfigValue(VIEW_SETTING_SECTION, VIEW_SETTING_ID, viewMode) then
        LogError("City-States failed to save view mode " .. tostring(viewMode))
    end
end

local m_selectedPlayerID = -1
local m_overviewPlayerIDs = {}
local m_treePlayerEntries = {}
local m_treeColumns       = {}
local m_treeSortOptions   = {}
local m_treeSortColumn    = nil
local m_treeSortAscending = false
local m_viewMode          = LoadViewModeSetting()
local m_hasGovernors     = (IsExpansion1Active() or IsExpansion2Active())
local m_caiEnvoyChanges  = {}
local m_caiMode          = MODE.Overview
local m_caiIsLocalTurn   = true

-- ============================================================================
-- Helpers
-- ============================================================================

local function NormalizeText(text)
    if not text then return "" end
    text = tostring(text)
    text = string.gsub(text, "%[ENDCOLOR%]", "")
    text = string.gsub(text, "%[COLOR_[^%]]+%]", "")
    text = string.gsub(text, "%[COLOR:[ \t\r\n]*[^%]]+%]", "")
    text = string.gsub(text, "%[NEWLINE%]", ", ")
    text = string.gsub(text, "%[ICON_[^%]]+%]", "")
    text = string.gsub(text, "[ \t\r\n,]+,", ",")
    text = string.gsub(text, "^[ \t\r\n,]+", "")
    text = string.gsub(text, "[ \t\r\n,]+$", "")
    return text
end

local function JoinNonEmpty(parts, separator)
    local out = {}
    for _, part in ipairs(parts) do
        if part and part ~= "" then
            table.insert(out, part)
        end
    end
    return table.concat(out, separator)
end

local function CountTable(t)
    local n = 0
    if not t then return n end
    for _ in pairs(t) do n = n + 1 end
    return n
end

local function IsSendEnvoysMode()
    return m_caiMode == MODE.SendEnvoys
end

local function HasMilitary()
    return GameCapabilities.HasCapability("CAPABILITY_MILITARY")
end

local function SumCaiEnvoyChanges()
    local sum = 0
    for _, v in pairs(m_caiEnvoyChanges) do sum = sum + v end
    return sum
end

local function GetEnvoysAvailable()
    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == -1 then return 0 end
    local pInfluence = Players[localPlayerID]:GetInfluence()
    if not pInfluence then return 0 end
    return pInfluence:GetTokensToGive()
end

local function GetEnvoysRemaining()
    return GetEnvoysAvailable() - SumCaiEnvoyChanges()
end

local function GetPendingForPlayer(playerID)
    return m_caiEnvoyChanges[playerID] or 0
end

local function GetCityStateFocusKey(playerID)
    return OVERVIEW_TABLE_ID .. ":row:" .. tostring(playerID) .. ":name"
end

local function GetTreeCityStateFocusKey(playerID)
    return "tree:cs:" .. tostring(playerID)
end

-- ============================================================================
-- Live game-state readers
-- ============================================================================

local function GetRelationshipsWithPlayerIDs(cityStatePlayerID)
    local relationships = GetRelationships(cityStatePlayerID)

    local function AttachPlayerIDs(entries, playerIDs)
        local entryIndex = 1
        for _, playerID in ipairs(playerIDs) do
            local diplomaticAI = Players[playerID]:GetDiplomaticAI()
            if diplomaticAI:GetDiplomaticStateIndex(cityStatePlayerID) ~= -1 then
                entries[entryIndex].PlayerID = playerID
                entryIndex = entryIndex + 1
            end
        end
    end

    AttachPlayerIDs(relationships.CivRelationships, PlayerManager.GetAliveMajorIDs())
    AttachPlayerIDs(relationships.CityStateRelationships, PlayerManager.GetAliveMinorIDs())
    return relationships
end

local function GetCityStateData(playerID)
    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == -1 then return nil end

    local pLocalPlayer = Players[localPlayerID]
    local pPlayer = Players[playerID]
    if not pPlayer or not pPlayer:IsAlive() then return nil end

    local pLocalDiplomacy = pLocalPlayer:GetDiplomacy()
    local pLocalInfluence = pLocalPlayer:GetInfluence()
    local pPlayerInfluence = pPlayer:GetInfluence()
    if not pPlayerInfluence then return nil end

    local pConfig = PlayerConfigurations[playerID]
    local tokens = pPlayerInfluence:GetTokensReceived(localPlayerID)
    local suzerainID = pPlayerInfluence:GetSuzerain()

    local suzerainName = Locale.Lookup("LOC_CITY_STATES_NONE")
    if suzerainID ~= -1 then
        if suzerainID == localPlayerID then
            suzerainName = Locale.Lookup("LOC_CITY_STATES_YOU")
        elseif pLocalDiplomacy:HasMet(suzerainID) then
            suzerainName = Locale.Lookup(PlayerConfigurations[suzerainID]:GetPlayerName())
        else
            suzerainName = Locale.Lookup("LOC_LOYALTY_PANEL_UNMET_CIV")
        end
    end

    local cityStateType = GetCityStateType(playerID)
    local iPlayerDiploState = pPlayer:GetDiplomaticAI():GetDiplomaticStateIndex(localPlayerID)
    local diplomaticState = nil
    if iPlayerDiploState ~= -1 then
        diplomaticState = GameInfo.DiplomaticStates[iPlayerDiploState].StateType
    end

    local influence = {}
    for _, iInfluencePlayer in ipairs(PlayerManager.GetAliveMajorIDs()) do
        local received = pPlayerInfluence:GetTokensReceived(iInfluencePlayer)
        if received > 0 then
            influence[iInfluencePlayer] = received
        end
    end

    return {
        iPlayer               = playerID,
        Name                  = pConfig:GetCivilizationShortDescription(),
        Type                  = cityStateType,
        Tokens                = tokens,
        Influence             = influence,
        SuzerainID            = suzerainID,
        SuzerainName          = suzerainName,
        SuzerainTokensNeeded  = pPlayerInfluence:GetMostTokensReceived(),
        isAlive               = pPlayer:IsAlive(),
        isHasMet              = pLocalDiplomacy:HasMet(playerID),
        isAtWar               = pLocalDiplomacy:IsAtWarWith(playerID),
        isBonus1              = (tokens >= 1),
        isBonus3              = (tokens >= 3),
        isBonus6              = (tokens >= 6),
        isBonusSuzerain       = (suzerainID == localPlayerID),
        IsLocalPlayerSuzerain = (suzerainID == localPlayerID),
        CanDeclareWarOn       = pLocalDiplomacy:CanDeclareWarOn(playerID),
        CanMakePeaceWith      = pLocalDiplomacy:CanMakePeaceWith(playerID),
        CanLevyMilitary       = pLocalInfluence:CanLevyMilitary(playerID),
        CanReceiveTokensFrom  = pLocalInfluence:CanGiveTokensToPlayer(playerID),
        LevyMilitaryCost      = pLocalInfluence:GetLevyMilitaryCost(playerID),
        LevyMilitaryTurnLimit = pPlayer:GetInfluence():GetLevyTurnLimit(),
        HasLevyActive         = (pPlayer:GetInfluence():GetLevyTurnCounter() >= 0),
        iTurnChanged          = pLocalDiplomacy:GetAtWarChangeTurn(playerID),
        DiplomaticState       = diplomaticState,
        Quests                = GetQuests(playerID),
        Relationships         = GetRelationshipsWithPlayerIDs(playerID),
        Bonuses               = {},
        CivType               = pConfig:GetCivilizationTypeName(),
    }
end

local function FillBonuses(kCS)
    local title, details = GetBonusText(kCS.iPlayer, 1)
    kCS.Bonuses[1] = { Title = title, Details = details }
    title, details = GetBonusText(kCS.iPlayer, 3)
    kCS.Bonuses[3] = { Title = title, Details = details }
    title, details = GetBonusText(kCS.iPlayer, 6)
    kCS.Bonuses[6] = { Title = title, Details = details }
    details = GetSuzerainBonusText(kCS.iPlayer)
    kCS.Bonuses["Suzerain"] = {
        Title = Locale.Lookup("LOC_CITY_STATES_SUZERAIN_ENVOYS"),
        Details = details,
    }
end

local function GetAllCityStatesData()
    local data = {}
    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == -1 then return data end

    for _, pPlayer in ipairs(PlayerManager.GetAliveMinors()) do
        local playerID = pPlayer:GetID()
        if playerID ~= localPlayerID then
            local pInfluence = pPlayer:GetInfluence()
            if pInfluence and pInfluence:CanReceiveInfluence() then
                local kCS = GetCityStateData(playerID)
                if kCS and kCS.isHasMet then
                    FillBonuses(kCS)
                    data[playerID] = kCS
                end
            end
        end
    end
    return data
end

local function GetSelectedCityState()
    if m_selectedPlayerID == -1 then return nil end
    return GetCityStateData(m_selectedPlayerID)
end

local function GetDiploShort(kCityState)
    if not kCityState.DiplomaticState then return "" end
    local info = DIPLO_PIP_INFO[kCityState.DiplomaticState]
    if info then return Locale.Lookup(info.Short) end
    return ""
end

local function GetDiploLong(kCityState)
    if not kCityState.DiplomaticState then return "" end
    local info = DIPLO_PIP_INFO[kCityState.DiplomaticState]
    if info then return NormalizeText(Locale.Lookup(info.Tooltip)) end
    return ""
end

local function GetSuzerainUniqueBonusAndResources(playerID)
    local leader = PlayerConfigurations[playerID]:GetLeaderTypeName()
    local leaderInfo = GameInfo.Leaders[leader]
    if not leaderInfo then return "" end

    local parts = {}
    for leaderTraitPairInfo in GameInfo.LeaderTraits() do
        if leader == leaderTraitPairInfo.LeaderType then
            local traitInfo = GameInfo.Traits[leaderTraitPairInfo.TraitType]
            if traitInfo then
                local name = PlayerConfigurations[playerID]:GetCivilizationShortDescription()
                local entry = Locale.Lookup("LOC_CITY_STATES_SUZERAIN_UNIQUE_BONUS", name)
                if traitInfo.Description then
                    entry = entry .. " " .. Locale.Lookup(traitInfo.Description)
                end
                if IsExpansion2Active() then
                    local pPlayer = Players[playerID]
                    if pPlayer and pPlayer:GetInfluence():IsSuzerainUniqueBonusDisabled() then
                        entry = entry .. " " .. Locale.Lookup("LOC_CITY_STATE_PANEL_UNIQUE_SUZERAIN_BONUS_DISABLED")
                    end
                end
                table.insert(parts, NormalizeText(entry))
            end
        end
    end

    local pPlayer = Players[playerID]
    if pPlayer then
        local resList = {}
        for resourceInfo in GameInfo.Resources() do
            local resource = resourceInfo.Index
            local pRes = pPlayer:GetResources()
            local hasRes = pRes:HasResource(resource) or pRes:HasExportedResource(resource)
            if IsExpansion2Active() then
                hasRes = hasRes or pRes:GetResourceAccumulationPerTurn(resource) > 0
            end
            if hasRes then
                local amount
                if IsExpansion2Active() then
                    amount = pRes:GetResourceAccumulationPerTurn(resource)
                    if amount == 0 then
                        amount = pRes:GetResourceAmount(resource) + pRes:GetExportedResourceAmount(resource)
                    end
                else
                    amount = pRes:GetResourceAmount(resource) + pRes:GetExportedResourceAmount(resource)
                end
                table.insert(resList, amount .. " " .. Locale.Lookup(resourceInfo.Name))
            end
        end
        if #resList > 0 then
            table.insert(parts, Locale.Lookup("LOC_CAI_CITYSTATES_RESOURCES", table.concat(resList, "[NEWLINE]")))
        else
            table.insert(parts, Locale.Lookup("LOC_CITY_STATES_SUZERAIN_NO_RESOURCES_AVAILABLE"))
        end
    end

    return table.concat(parts, "[NEWLINE]")
end

local function GetBonusBreakdownParts(kCS)
    FillBonuses(kCS)
    local parts = {}
    for _, tier in ipairs({ 1, 3, 6 }) do
        local bonus = kCS.Bonuses[tier]
        if bonus then
            local active = (tier == 1 and kCS.isBonus1) or
                (tier == 3 and kCS.isBonus3) or
                (tier == 6 and kCS.isBonus6)
            local label = Locale.Lookup("LOC_CAI_CITYSTATES_ENVOYS_TIER", tier)
            if active then
                label = label .. " (" .. Locale.Lookup("LOC_CAI_CITYSTATES_BONUS_ACTIVE") .. ")"
            end
            table.insert(parts, label .. "[NEWLINE]" .. NormalizeText(bonus.Details))
        end
    end

    local suzerainBonus = kCS.Bonuses["Suzerain"]
    if suzerainBonus then
        local label = Locale.Lookup("LOC_CITY_STATES_SUZERAIN")
        if kCS.isBonusSuzerain then
            label = label .. " (" .. Locale.Lookup("LOC_CAI_CITYSTATES_BONUS_ACTIVE") .. ")"
        end
        local details = NormalizeText(suzerainBonus.Details)
        table.insert(parts, JoinNonEmpty({ label, details }, "[NEWLINE]"))
    end
    return parts
end

local function GetQuestEntryLabel(kQuest)
    local reward = kQuest.Reward and kQuest.Reward ~= "" and
        (Locale.Lookup("LOC_CITY_STATES_REWARD") .. " " .. NormalizeText(kQuest.Reward)) or ""
    return JoinNonEmpty({ kQuest.Name, NormalizeText(kQuest.Description), reward }, "[NEWLINE]")
end

local function GetRelationshipEntryLabel(entry)
    local name = Locale.Lookup(entry.PlayerName)
    local pipInfo = DIPLO_PIP_INFO[entry.DiploState]
    local statusText = pipInfo and Locale.Lookup(pipInfo.Short) or ""
    return JoinNonEmpty({ name, statusText }, "[NEWLINE]")
end

local function ShouldIncludeRelationshipEntry(entry, cityStatePlayerID, isCityStateRelationship)
    if not entry or not entry.HasMet then return false end
    if isCityStateRelationship and entry.PlayerID == cityStatePlayerID then
        return false
    end
    return true
end

local function IsWarRelationship(entry)
    return entry.DiploState == "DIPLO_STATE_WAR_WITH_MAJOR" or
        entry.DiploState == "DIPLO_STATE_WAR_WITH_MINOR" or
        entry.DiploState == "DIPLO_STATE_MINOR_MINOR_WAR"
end

local function GetVisibleRelationshipEntries(kCS, excludeLocalPlayer)
    local entries = {}
    if not kCS or not kCS.Relationships then return entries end

    local function AddEntries(source, isCityStateRelationship)
        for _, entry in ipairs(source or {}) do
            if ShouldIncludeRelationshipEntry(entry, kCS.iPlayer, isCityStateRelationship) and
                (not excludeLocalPlayer or entry.PlayerID ~= Game.GetLocalPlayer()) then
                table.insert(entries, {
                    label = GetRelationshipEntryLabel(entry),
                    name = Locale.Lookup(entry.PlayerName),
                    atWar = IsWarRelationship(entry),
                })
            end
        end
    end

    AddEntries(kCS.Relationships.CivRelationships, false)
    AddEntries(kCS.Relationships.CityStateRelationships, true)
    table.sort(entries, function(a, b)
        if a.atWar ~= b.atWar then return a.atWar end
        local comparison = Locale.Compare(a.name, b.name)
        if comparison ~= 0 then return comparison < 0 end
        return Locale.Compare(a.label, b.label) < 0
    end)
    return entries
end

local function GetVisibleRelationshipCount(kCS)
    return #GetVisibleRelationshipEntries(kCS, false)
end

local function GetForeignRelationshipsCell(playerID)
    local entries = GetVisibleRelationshipEntries(GetCityStateData(playerID), true)
    if #entries == 0 then return Locale.Lookup("LOC_CITY_STATES_NONE") end
    local parts = {}
    for _, entry in ipairs(entries) do table.insert(parts, entry.label) end
    return JoinNonEmpty(parts, "; ")
end

local function GetAmbassadorForPlayer(cityStatePlayerID, majorPlayerID)
    if not m_hasGovernors then return nil end
    local pCityState = Players[cityStatePlayerID]
    if not pCityState then return nil end
    local pMajorGovernors = Players[majorPlayerID] and Players[majorPlayerID].GetGovernors and
        Players[majorPlayerID]:GetGovernors()
    if not pMajorGovernors then return nil end

    for _, pCity in pCityState:GetCities():Members() do
        local pGov = pMajorGovernors:GetAssignedGovernor(pCity)
        if pGov then return pGov end
    end
    return nil
end

-- ============================================================================
-- Overview table data
-- ============================================================================

local function GetGovernorName(cityStatePlayerID, majorPlayerID)
    local governor = GetAmbassadorForPlayer(cityStatePlayerID, majorPlayerID)
    if not governor then return "" end
    local definition = GameInfo.Governors[governor:GetType()]
    if definition and definition.Name then return Locale.Lookup(definition.Name) end
    return Locale.Lookup("LOC_CAI_CITYSTATES_AMBASSADOR")
end

local function GetEnvoyCell(playerID)
    local kCS = GetCityStateData(playerID)
    if not kCS then return "" end

    local parts = {}
    if kCS.isBonusSuzerain then
        table.insert(parts, Locale.Lookup("LOC_CAI_CITYSTATES_ENVOYS", kCS.Tokens))
    else
        local needed = math.max(3, kCS.SuzerainTokensNeeded)
        if kCS.SuzerainID ~= -1 then needed = needed + 1 end
        table.insert(parts, Locale.Lookup("LOC_CAI_CITYSTATES_ENVOYS_OF", kCS.Tokens, needed))
    end

    for _, bonus in ipairs(GetBonusBreakdownParts(kCS)) do
        table.insert(parts, bonus)
    end

    local pending = GetPendingForPlayer(playerID)
    if pending > 0 then
        table.insert(parts, Locale.Lookup("LOC_CAI_CITYSTATES_PENDING", pending))
    end

    local governorName = GetGovernorName(playerID, Game.GetLocalPlayer())
    if governorName ~= "" then
        table.insert(parts, Locale.Lookup("LOC_CAI_CITYSTATES_AMBASSADOR_ASSIGNED", governorName))
    end
    return JoinNonEmpty(parts, "[NEWLINE]")
end

local function GetInfluenceCell(playerID, majorPlayerID)
    local kCS = GetCityStateData(playerID)
    if not kCS then return "" end
    local influence = kCS.Influence[majorPlayerID] or 0
    local governorName = GetGovernorName(playerID, majorPlayerID)
    return JoinNonEmpty({ Locale.Lookup("LOC_CAI_CITYSTATES_ENVOYS", influence), governorName }, "[NEWLINE]")
end

local function GetUnmetInfluence(playerID)
    local kCS = GetCityStateData(playerID)
    local localPlayerID = Game.GetLocalPlayer()
    if not kCS or localPlayerID == -1 then return {}, 0 end
    local diplomacy = Players[localPlayerID]:GetDiplomacy()
    local values = {}
    local total = 0
    for majorPlayerID, influence in pairs(kCS.Influence) do
        if majorPlayerID ~= localPlayerID and not diplomacy:HasMet(majorPlayerID) then
            table.insert(values, influence)
            total = total + influence
        end
    end
    table.sort(values, function(a, b) return a > b end)
    return values, total
end

local function GetUnmetInfluenceCell(playerID)
    local values = GetUnmetInfluence(playerID)
    if #values == 0 then return Locale.Lookup("LOC_CAI_CITYSTATES_ENVOYS", 0) end
    local parts = {}
    for _, influence in ipairs(values) do
        table.insert(parts, Locale.Lookup("LOC_CAI_CITYSTATES_ENVOYS", influence))
    end
    return table.concat(parts, "[NEWLINE]")
end

local function BuildOverviewColumns(allData)
    local columns = {
        {
            key = "name",
            header = function() return Locale.Lookup("LOC_CAI_CITYSTATES_COLUMN_CITY_STATE") end,
            getCell = function(playerID)
                local kCS = GetCityStateData(playerID)
                return kCS and Locale.Lookup(kCS.Name) or ""
            end,
            sortKey = function(playerID)
                local kCS = GetCityStateData(playerID)
                return kCS and Locale.Lookup(kCS.Name) or nil
            end,
            sortAscendingDescription = "LOC_CAI_SORT_A_TO_Z",
            sortDescendingDescription = "LOC_CAI_SORT_Z_TO_A",
        },
        {
            key = "type",
            header = function() return Locale.Lookup("LOC_CITY_STATES_TYPE") end,
            getCell = function(playerID)
                local kCS = GetCityStateData(playerID)
                return kCS and GetTypeName(kCS) or ""
            end,
            sortKey = function(playerID)
                local kCS = GetCityStateData(playerID)
                return kCS and GetTypeName(kCS) or nil
            end,
            sortAscendingDescription = "LOC_CAI_SORT_A_TO_Z",
            sortDescendingDescription = "LOC_CAI_SORT_Z_TO_A",
        },
        {
            key = "relationship",
            header = function() return Locale.Lookup("LOC_CAI_CITYSTATES_COLUMN_YOUR_RELATIONSHIP") end,
            getCell = function(playerID)
                local kCS = GetCityStateData(playerID)
                return kCS and GetDiploShort(kCS) or ""
            end,
            getTooltip = function(playerID)
                local kCS = GetCityStateData(playerID)
                return kCS and GetDiploLong(kCS) or ""
            end,
            sortKey = function(playerID)
                local kCS = GetCityStateData(playerID)
                local info = kCS and DIPLO_PIP_INFO[kCS.DiplomaticState] or nil
                return info and info.Sort or 0
            end,
            sortAscendingDescription = "LOC_CAI_SORT_AT_WAR_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_SUZERAIN_FIRST",
        },
        {
            key = "envoys",
            header = function() return Locale.Lookup("LOC_CITY_STATES_ENVOYS") end,
            getCell = function(playerID) return GetEnvoyCell(playerID) end,
            sortKey = function(playerID)
                local kCS = GetCityStateData(playerID)
                return kCS and (kCS.Tokens + GetPendingForPlayer(playerID)) or nil
            end,
            sortAscendingDescription = "LOC_CAI_SORT_FEWEST_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_MOST_FIRST",
        },
        {
            key = "suzerain",
            header = function() return Locale.Lookup("LOC_CITY_STATES_SUZERAIN") end,
            getCell = function(playerID)
                local kCS = GetCityStateData(playerID)
                return kCS and kCS.SuzerainName or ""
            end,
            sortKey = function(playerID)
                local kCS = GetCityStateData(playerID)
                return kCS and kCS.SuzerainName or nil
            end,
            sortAscendingDescription = "LOC_CAI_SORT_A_TO_Z",
            sortDescendingDescription = "LOC_CAI_SORT_Z_TO_A",
        },
        {
            key = "quests",
            header = function() return Locale.Lookup("LOC_CAI_CITYSTATES_COLUMN_ACTIVE_QUESTS") end,
            getCell = function(playerID)
                local kCS = GetCityStateData(playerID)
                if not kCS then return "" end
                local parts = { Locale.Lookup("LOC_CAI_CITYSTATES_ACTIVE", CountTable(kCS.Quests)) }
                local quests = {}
                for _, kQuest in pairs(kCS.Quests) do
                    table.insert(quests, NormalizeText(kQuest.Description))
                end
                table.sort(quests, function(a, b) return Locale.Compare(a, b) < 0 end)
                for _, quest in ipairs(quests) do table.insert(parts, quest) end
                return JoinNonEmpty(parts, "; ")
            end,
            sortKey = function(playerID)
                local kCS = GetCityStateData(playerID)
                return kCS and CountTable(kCS.Quests) or nil
            end,
            sortAscendingDescription = "LOC_CAI_SORT_FEWEST_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_MOST_FIRST",
        },
        {
            key = "foreign-relationships",
            header = function() return Locale.Lookup("LOC_CAI_CITYSTATES_COLUMN_FOREIGN_RELATIONSHIPS") end,
            getCell = function(playerID) return GetForeignRelationshipsCell(playerID) end,
            sortKey = function(playerID)
                return #GetVisibleRelationshipEntries(GetCityStateData(playerID), true)
            end,
            sortAscendingDescription = "LOC_CAI_SORT_FEWEST_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_MOST_FIRST",
        },
    }

    local localPlayerID = Game.GetLocalPlayer()
    local diplomacy = Players[localPlayerID]:GetDiplomacy()
    local knownMajors = {}
    local hasUnmetInfluence = false
    for _, kCS in pairs(allData) do
        for majorPlayerID in pairs(kCS.Influence) do
            if majorPlayerID ~= localPlayerID then
                if diplomacy:HasMet(majorPlayerID) then
                    knownMajors[majorPlayerID] = true
                else
                    hasUnmetInfluence = true
                end
            end
        end
    end

    local sortedMajors = {}
    for majorPlayerID in pairs(knownMajors) do table.insert(sortedMajors, majorPlayerID) end
    table.sort(sortedMajors, function(a, b)
        local aName = Locale.Lookup(PlayerConfigurations[a]:GetPlayerName())
        local bName = Locale.Lookup(PlayerConfigurations[b]:GetPlayerName())
        return Locale.Compare(aName, bName) < 0
    end)

    for _, id in ipairs(sortedMajors) do
        local majorPlayerID = id
        table.insert(columns, {
            key = "influence:" .. tostring(majorPlayerID),
            header = function()
                local name = Locale.Lookup(PlayerConfigurations[majorPlayerID]:GetPlayerName())
                return Locale.Lookup("LOC_CAI_CITYSTATES_INFLUENCE_COLUMN", name)
            end,
            getCell = function(playerID) return GetInfluenceCell(playerID, majorPlayerID) end,
            sortKey = function(playerID)
                local kCS = GetCityStateData(playerID)
                return kCS and (kCS.Influence[majorPlayerID] or 0) or nil
            end,
            sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST",
        })
    end

    if hasUnmetInfluence then
        table.insert(columns, {
            key = "influence:unmet",
            header = function() return Locale.Lookup("LOC_CAI_CITYSTATES_UNMET_INFLUENCE_COLUMN") end,
            getCell = function(playerID) return GetUnmetInfluenceCell(playerID) end,
            sortKey = function(playerID)
                local _, total = GetUnmetInfluence(playerID)
                return total
            end,
            sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST",
        })
    end
    return columns
end

local function ResolveColumnHeader(column)
    return type(column.header) == "function" and column.header() or column.header or ""
end

local function BuildTreeSortOptions(columns)
    local options = {
        {
            label = Locale.Lookup("LOC_CAI_DATATABLE_SORT_NATURAL"),
            value = { column = nil, ascending = false },
        },
    }
    for _, column in ipairs(columns) do
        if column.sortKey then
            local header = ResolveColumnHeader(column)
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

local function SyncTreeSortDropdown()
    if not m_ui.treeSort then return end
    for index, option in ipairs(m_treeSortOptions) do
        local sort = option.value
        if sort.column == m_treeSortColumn and
            (sort.column == nil or sort.ascending == m_treeSortAscending) then
            m_ui.treeSort:SetSelectedIndex(index, true)
            return
        end
    end
end

local function CompareTreeSortValues(a, b)
    if a == b then return 0 end
    if a == nil then return 1 end
    if b == nil then return -1 end
    if type(a) == "number" and type(b) == "number" then return a < b and -1 or 1 end
    if type(a) == "boolean" and type(b) == "boolean" then return a and 1 or -1 end
    return Locale.Compare(tostring(a), tostring(b))
end

local function GetOrderedTreePlayers()
    local ordered = {}
    for _, entry in ipairs(m_treePlayerEntries) do
        table.insert(ordered, entry)
    end
    if not m_treeSortColumn then return ordered end

    local sortColumn = nil
    for _, column in ipairs(m_treeColumns) do
        if column.key == m_treeSortColumn then
            sortColumn = column
            break
        end
    end
    if not sortColumn or not sortColumn.sortKey then return ordered end

    local decorated = {}
    for naturalIndex, entry in ipairs(ordered) do
        table.insert(decorated, {
            entry = entry,
            naturalIndex = naturalIndex,
            value = sortColumn.sortKey(entry.id),
        })
    end
    table.sort(decorated, function(a, b)
        if a.value == nil or b.value == nil then
            if a.value == b.value then return a.naturalIndex < b.naturalIndex end
            return a.value ~= nil
        end
        local comparison = CompareTreeSortValues(a.value, b.value)
        if comparison == 0 then return a.naturalIndex < b.naturalIndex end
        if m_treeSortAscending then return comparison < 0 end
        return comparison > 0
    end)

    ordered = {}
    for _, decoratedEntry in ipairs(decorated) do
        table.insert(ordered, decoratedEntry.entry)
    end
    return ordered
end

local function FormatTreeRowLabel(playerID)
    local kCS = GetCityStateData(playerID)
    if not kCS then return "" end

    local parts = { Locale.Lookup(kCS.Name), GetTypeName(kCS), GetDiploShort(kCS) }
    if kCS.isBonusSuzerain then
        table.insert(parts, Locale.Lookup("LOC_CAI_CITYSTATES_ENVOYS", kCS.Tokens))
        table.insert(parts, Locale.Lookup("LOC_CITY_STATES_SUZERAIN"))
    else
        local needed = math.max(3, kCS.SuzerainTokensNeeded)
        if kCS.SuzerainID ~= -1 then needed = needed + 1 end
        table.insert(parts, Locale.Lookup("LOC_CAI_CITYSTATES_ENVOYS_OF", kCS.Tokens, needed))
    end

    local pending = GetPendingForPlayer(playerID)
    if pending > 0 then
        table.insert(parts, Locale.Lookup("LOC_CAI_CITYSTATES_PENDING", pending))
    end
    if not kCS.isBonusSuzerain and kCS.SuzerainID ~= -1 then
        table.insert(parts, Locale.Lookup("LOC_CAI_CITYSTATES_CURRENT_SUZERAIN", kCS.SuzerainName))
    end

    local governorName = GetGovernorName(playerID, Game.GetLocalPlayer())
    if governorName ~= "" then
        table.insert(parts, Locale.Lookup("LOC_CAI_CITYSTATES_AMBASSADOR_ASSIGNED", governorName))
    end
    if CountTable(kCS.Quests) > 0 then
        table.insert(parts, Locale.Lookup("LOC_CAI_CITYSTATES_QUEST_AVAILABLE"))
    end
    return JoinNonEmpty(parts, "[NEWLINE]")
end

local function FormatTreeRowTooltip(playerID)
    local kCS = GetCityStateData(playerID)
    if not kCS then return "" end
    FillBonuses(kCS)
    local parts = {}
    for _, tier in ipairs({ 1, 3, 6 }) do
        local bonus = kCS.Bonuses[tier]
        if bonus then
            table.insert(parts,
                Locale.Lookup("LOC_CAI_CITYSTATES_ENVOYS_TIER", tier) .. "[NEWLINE]" .. NormalizeText(bonus.Details))
        end
    end
    local uniqueBonusAndResources = GetSuzerainUniqueBonusAndResources(playerID)
    if uniqueBonusAndResources ~= "" then
        table.insert(parts, Locale.Lookup("LOC_CITY_STATES_SUZERAIN") .. "[NEWLINE]" .. uniqueBonusAndResources)
    end
    return JoinNonEmpty(parts, "[NEWLINE]")
end

-- ============================================================================
-- Detail section builders (lazy, called on expand)
-- ============================================================================

local function BuildBonusesSection(parent, playerID)
    local kCS = GetCityStateData(playerID)
    if not kCS then return end
    FillBonuses(kCS)

    local tiers = { 1, 3, 6 }
    for _, tier in ipairs(tiers) do
        local bonus = kCS.Bonuses[tier]
        if bonus then
            local active = (tier == 1 and kCS.isBonus1) or (tier == 3 and kCS.isBonus3) or (tier == 6 and kCS.isBonus6)
            local label = Locale.Lookup("LOC_CAI_CITYSTATES_ENVOYS_TIER", tier)
            if active then
                label = label .. " (" .. Locale.Lookup("LOC_CAI_CITYSTATES_BONUS_ACTIVE") .. ")"
            end
            local tooltip = Locale.Lookup("LOC_CAI_CITYSTATES_REQUIRES_ENVOYS", tier) ..
                "[NEWLINE]" .. NormalizeText(bonus.Details)
            parent:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAICityStates_Bonus"), "StaticText", {
                Label   = function() return label end,
                Tooltip = function() return tooltip end,
            }))
        end
    end

    local suzerainBonus = kCS.Bonuses["Suzerain"]
    if suzerainBonus then
        local active = kCS.isBonusSuzerain
        local label = Locale.Lookup("LOC_CITY_STATES_SUZERAIN")
        if active then
            label = label .. " (" .. Locale.Lookup("LOC_CAI_CITYSTATES_BONUS_ACTIVE") .. ")"
        end
        local tooltip = Locale.Lookup("LOC_CAI_CITYSTATES_REQUIRES_SUZERAIN") ..
            "[NEWLINE]" .. NormalizeText(suzerainBonus.Details)
        local uniqueBonusAndResources = GetSuzerainUniqueBonusAndResources(playerID)
        if uniqueBonusAndResources ~= "" then
            tooltip = tooltip .. "[NEWLINE]" .. uniqueBonusAndResources
        end
        parent:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAICityStates_BonusSuz"), "StaticText", {
            Label   = function() return label end,
            Tooltip = function() return tooltip end,
        }))
    end
end

local function BuildInfluenceSection(parent, playerID)
    local kCS = GetCityStateData(playerID)
    if not kCS then return end

    local localPlayerID = Game.GetLocalPlayer()
    local diplomacy = Players[localPlayerID]:GetDiplomacy()
    local sorted = {}
    for majorPlayerID, influence in pairs(kCS.Influence) do
        table.insert(sorted, { playerID = majorPlayerID, influence = influence })
    end
    table.sort(sorted, function(a, b) return a.influence > b.influence end)

    for _, entry in ipairs(sorted) do
        local civName
        if entry.playerID == localPlayerID then
            civName = Locale.Lookup(PlayerConfigurations[entry.playerID]:GetPlayerName()) ..
                " (" .. Locale.Lookup("LOC_CITY_STATES_YOU") .. ")"
        elseif diplomacy:HasMet(entry.playerID) then
            civName = Locale.Lookup(PlayerConfigurations[entry.playerID]:GetPlayerName())
        else
            civName = Locale.Lookup("LOC_LOYALTY_PANEL_UNMET_CIV")
        end

        local label = civName .. ": " .. Locale.Lookup("LOC_CAI_CITYSTATES_ENVOYS", entry.influence)
        if entry.playerID == localPlayerID or diplomacy:HasMet(entry.playerID) then
            local governorName = GetGovernorName(playerID, entry.playerID)
            if governorName ~= "" then label = label .. "[NEWLINE]" .. governorName end
        end
        parent:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAICityStates_Inf"), "StaticText", {
            Label = function() return label end,
        }))
    end
end

local function BuildQuestsSection(parent, playerID)
    local kCS = GetCityStateData(playerID)
    if not kCS then return end

    for _, kQuest in pairs(kCS.Quests) do
        local label = GetQuestEntryLabel(kQuest)
        parent:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAICityStates_Quest"), "StaticText", {
            Label = function() return label end,
        }))
    end
end

local function BuildRelationshipEntry(parent, entry, idPrefix)
    parent:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId(idPrefix), "StaticText", {
        Label = function() return GetRelationshipEntryLabel(entry) end,
    }))
end

local function BuildRelationshipsSection(parent, playerID)
    local kCS = GetCityStateData(playerID)
    if not kCS or not kCS.Relationships then return end

    for _, entry in ipairs(kCS.Relationships.CivRelationships or {}) do
        if ShouldIncludeRelationshipEntry(entry, playerID, false) then
            BuildRelationshipEntry(parent, entry, "CAICityStates_Rel")
        end
    end

    for _, entry in ipairs(kCS.Relationships.CityStateRelationships or {}) do
        if ShouldIncludeRelationshipEntry(entry, playerID, true) then
            BuildRelationshipEntry(parent, entry, "CAICityStates_RelCS")
        end
    end
end

-- ============================================================================
-- Sync vanilla controls for the selected city-state.
-- Replicates the button-setup portion of ViewCityState without calling it
-- directly, because ViewCityState clears m_uiCityStateRows which breaks the
-- envoy add/remove flow.
-- ============================================================================

local function SyncVanillaControlsForCityState(playerID)
    local kCS = GetCityStateData(playerID)
    if not kCS then return end

    local localPlayerID = Game.GetLocalPlayer()
    local pLocalDiplomacy = Players[localPlayerID]:GetDiplomacy()

    if HasMilitary() then
        Controls.PeaceWarButton:SetHide(false)
        local warPeaceTooltip = ""
        if kCS.isAtWar then
            Controls.PeaceWarButton:SetText(Locale.Lookup("LOC_CITY_STATES_MAKE_PEACE"))
            Controls.PeaceWarButton:SetDisabled(not kCS.CanMakePeaceWith)
            if not kCS.CanMakePeaceWith then
                if GlobalParameters.DIPLOMACY_WAR_LAST_FOREVER == 1
                    or GlobalParameters.DIPLOMACY_WAR_LAST_FOREVER == true then
                    warPeaceTooltip = Locale.Lookup("LOC_CITY_STATES_TURNS_WAR_NO_PEACE")
                elseif kCS.SuzerainID ~= -1 and pLocalDiplomacy:IsAtWarWith(kCS.SuzerainID) then
                    warPeaceTooltip = Locale.Lookup("LOC_CITY_STATES_SUZERAIN_WAR_NO_PEACE")
                else
                    warPeaceTooltip = Locale.Lookup("LOC_CITY_STATES_TURNS_WAR",
                        Game.GetGameDiplomacy():GetMinPeaceDuration() + kCS.iTurnChanged - Game.GetCurrentGameTurn())
                end
            end
        else
            Controls.PeaceWarButton:SetText(Locale.Lookup("LOC_CITY_STATES_DECLARE_WAR_BUTTON"))
            Controls.PeaceWarButton:SetDisabled(not kCS.CanDeclareWarOn)
            warPeaceTooltip = Locale.Lookup("LOC_CITY_STATES_DECLARE_WAR_DETAILS")
            if not kCS.CanDeclareWarOn then
                if HasTrait("TRAIT_CIVILIZATION_FACES_OF_PEACE", localPlayerID) then
                    warPeaceTooltip = Locale.Lookup("LOC_CIVILIZATION_NOT_ABLE_TO_DECLARE_SURPRISE_WAR")
                else
                    warPeaceTooltip = warPeaceTooltip .. " " .. Locale.Lookup("LOC_CITY_STATES_TURNS_PEACE",
                        Game.GetGameDiplomacy():GetMinPeaceDuration() + kCS.iTurnChanged - Game.GetCurrentGameTurn())
                end
            end
        end
        Controls.PeaceWarButton:SetToolTipString(warPeaceTooltip)
        Controls.PeaceWarButton:RegisterCallback(Mouse.eLClick, function() OnChangeWarPeaceStatus(kCS) end)

        Controls.LevyMilitaryButton:SetHide(false)
        Controls.LevyMilitaryButton:SetDisabled(not kCS.CanLevyMilitary)
        if kCS.HasLevyActive and kCS.IsLocalPlayerSuzerain then
            Controls.LevyMilitaryButton:SetToolTipString(Locale.Lookup("LOC_CITY_STATES_MILITARY_ALREADY_LEVIED"))
        else
            Controls.LevyMilitaryButton:SetToolTipString(
                Locale.Lookup("LOC_CITY_STATES_LEVY_MILITARY_DETAILS", kCS.LevyMilitaryCost, kCS.LevyMilitaryTurnLimit))
        end
        Controls.LevyMilitaryButton:RegisterCallback(Mouse.eLClick, function() OnLevyMilitary(kCS) end)
    else
        Controls.PeaceWarButton:SetHide(true)
        Controls.LevyMilitaryButton:SetHide(true)
    end
end

local function SyncEnvoySlider()
    if not m_ui.envoySlider then return end
    local pending = GetPendingForPlayer(m_selectedPlayerID)
    local maxVal = pending + GetEnvoysRemaining()
    m_ui.envoySlider:SetMax(maxVal)
    m_ui.envoySlider:SetValue(pending, true)
end

local function SpeakPendingEnvoys(playerID)
    Speak(Locale.Lookup("LOC_CAI_CITYSTATES_ENVOYS", GetPendingForPlayer(playerID)))
end

local CAI_RebuildViews

local function TryAdjustEnvoysForPlayer(playerID, delta)
    if delta == 0 then return false end
    if not IsSendEnvoysMode() or not m_caiIsLocalTurn then return true end

    local kCS = GetCityStateData(playerID)
    if not kCS or not kCS.CanReceiveTokensFrom then
        return true
    end

    if delta > 0 then
        if GetEnvoysRemaining() <= 0 then return true end
        OnMoreEnvoyTokens(playerID)
    else
        if GetPendingForPlayer(playerID) <= 0 then return true end
        OnLessEnvoyTokens(playerID)
    end

    SyncEnvoySlider()
    CAI_RebuildViews()
    SpeakPendingEnvoys(playerID)
    return true
end

local function TryConfirmEnvoys()
    if not m_ui.confirmEnvoy or m_ui.confirmEnvoy:IsHidden() or m_ui.confirmEnvoy:IsDisabled() then
        return true
    end
    m_ui.confirmEnvoy:Emit("activate")
    return true
end

-- ============================================================================
-- Selected city-state and alternate tree
-- ============================================================================

local function GetRelationshipDetailLabel(playerID)
    local kCS = GetCityStateData(playerID)
    if not kCS then return "" end
    local short = GetDiploShort(kCS)
    local long = GetDiploLong(kCS)
    if short == "" then return "" end
    return long ~= "" and Locale.Lookup("LOC_CAI_CITYSTATES_RELATIONSHIP", short, long) or short
end

local function SelectCityState(playerID)
    if not playerID or playerID == m_selectedPlayerID then return end
    m_selectedPlayerID = playerID
    SyncVanillaControlsForCityState(playerID)
    SyncEnvoySlider()
end

local function AddLazyTreeSection(parent, label, focusKey, buildChildren)
    local section = mgr:CreateWidget(mgr:GenerateWidgetId("CAICityStates_TreeSection"), "TreeItem", {
        Label = label,
        FocusKey = focusKey,
    })
    section._csBuilt = false
    section:On("focus_enter", function(w)
        if not w._csBuilt then
            w._csBuilt = true
            buildChildren(w)
        end
    end)
    parent:AddChild(section)
end

local function CreateTreeViewCityStateRow(playerID)
    local row = mgr:CreateWidget(mgr:GenerateWidgetId("CAICityStates_TreeRow"), "TreeItem", {
        Label = function() return FormatTreeRowLabel(playerID) end,
        Tooltip = function() return FormatTreeRowTooltip(playerID) end,
        FocusKey = GetTreeCityStateFocusKey(playerID),
    })
    row:SetFocusSound("Main_Menu_Mouse_Over")
    row:On("focus_enter", function(w)
        if w:IsFocused() then SelectCityState(playerID) end
    end)
    row:AddInputBindings({
        {
            Key = Keys.VK_LEFT,
            IsShift = true,
            MSG = KeyEvents.KeyDown,
            Description = "LOC_CAI_KB_REMOVE_CITYSTATE_ENVOY",
            Action = function() return TryAdjustEnvoysForPlayer(playerID, -1) end,
        },
        {
            Key = Keys.VK_RIGHT,
            IsShift = true,
            MSG = KeyEvents.KeyDown,
            Description = "LOC_CAI_KB_ADD_CITYSTATE_ENVOY",
            Action = function() return TryAdjustEnvoysForPlayer(playerID, 1) end,
        },
        {
            Key = Keys.VK_RETURN,
            IsControl = true,
            MSG = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_CONFIRM_CITYSTATE_ENVOYS",
            Action = function() return TryConfirmEnvoys() end,
        },
    })

    row:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAICityStates_RelDetail"), "StaticText", {
        Label = function() return GetRelationshipDetailLabel(playerID) end,
    }))

    local prefix = "tree:cs:" .. tostring(playerID)
    AddLazyTreeSection(row, function()
        local kCS = GetCityStateData(playerID)
        if not kCS then return Locale.Lookup("LOC_CITY_STATES_BONUSES", "") end
        local count = 0
        if kCS.isBonus1 then count = count + 1 end
        if kCS.isBonus3 then count = count + 1 end
        if kCS.isBonus6 then count = count + 1 end
        if kCS.isBonusSuzerain then count = count + 1 end
        return Locale.Lookup("LOC_CITY_STATES_BONUSES", Locale.Lookup(kCS.Name)) ..
            "[NEWLINE]" .. Locale.Lookup("LOC_CAI_CITYSTATES_BONUS_COUNT", count, 4)
    end, prefix .. ":bonuses", function(parent)
        BuildBonusesSection(parent, playerID)
    end)

    AddLazyTreeSection(row, function()
        local kCS = GetCityStateData(playerID)
        return Locale.Lookup("LOC_CITY_STATES_INFLUENCED_BY") .. "[NEWLINE]" ..
            Locale.Lookup("LOC_CITY_STATES_CIVILIZATIONS", kCS and CountTable(kCS.Influence) or 0)
    end, prefix .. ":influence", function(parent)
        BuildInfluenceSection(parent, playerID)
    end)

    AddLazyTreeSection(row, function()
        local kCS = GetCityStateData(playerID)
        return Locale.Lookup("LOC_CITY_STATES_QUESTS") .. "[NEWLINE]" ..
            Locale.Lookup("LOC_CAI_CITYSTATES_ACTIVE", kCS and CountTable(kCS.Quests) or 0)
    end, prefix .. ":quests", function(parent)
        BuildQuestsSection(parent, playerID)
    end)

    AddLazyTreeSection(row, function()
        local kCS = GetCityStateData(playerID)
        return Locale.Lookup("LOC_CITY_STATES_RELATIONSHIPS") .. "[NEWLINE]" ..
            Locale.Lookup("LOC_CITY_STATES_CIVILIZATIONS", GetVisibleRelationshipCount(kCS))
    end, prefix .. ":relationships", function(parent)
        BuildRelationshipsSection(parent, playerID)
    end)
    return row
end

-- ============================================================================
-- Info box content
-- ============================================================================

local function GetInfoBoxLines()
    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == -1 then return {} end

    local pLocalPlayer = Players[localPlayerID]
    local pInfluence = pLocalPlayer:GetInfluence()
    if not pInfluence then return {} end

    local balance = math.floor(pInfluence:GetPointsEarned() + 0.5)
    local threshold = pInfluence:GetPointsThreshold()
    local rate = math.floor(pInfluence:GetPointsPerTurn() * 10 + 0.5) / 10
    local envoysPerThreshold = pInfluence:GetTokensPerThreshold()
    local available = pInfluence:GetTokensToGive()

    local lines = {}
    table.insert(lines, Locale.Lookup("LOC_CAI_CITYSTATES_INFO_ENVOYS_AVAILABLE", available))
    table.insert(lines,
        NormalizeText(Locale.Lookup("LOC_CAI_CITYSTATES_INFO_INFLUENCE", balance, threshold, rate, envoysPerThreshold)))
    return lines
end

-- ============================================================================
-- Rebuild
-- ============================================================================

local function RebuildTreeView(sortedPlayers)
    local capture = mgr:CaptureFocusKey(m_ui.treeView)
    m_ui.treeView:ClearChildren()
    for _, entry in ipairs(sortedPlayers) do
        m_ui.treeView:AddChild(CreateTreeViewCityStateRow(entry.id))
    end
    if #sortedPlayers == 0 then
        m_ui.treeView:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAICityStates_NoneMet"), "StaticText", {
            Label = function() return Locale.Lookup("LOC_CITY_STATES_NONE_MET") end,
        }))
    elseif not capture and m_selectedPlayerID ~= -1 then
        mgr:PrepareFocus(m_ui.treeView, GetTreeCityStateFocusKey(m_selectedPlayerID))
    end
    mgr:RestoreFocus(m_ui.treeView, capture)
end

CAI_RebuildViews = function(preferredPlayerID)
    if not m_ui.overview or not m_ui.treeView then return end
    if ContextPtr:IsHidden() then return end

    local allData = GetAllCityStatesData()
    local sortedPlayers = {}
    for playerID, kCS in pairs(allData) do
        table.insert(sortedPlayers, { id = playerID, name = Locale.Lookup(kCS.Name) })
    end
    table.sort(sortedPlayers, function(a, b) return Locale.Compare(a.name, b.name) < 0 end)
    m_treePlayerEntries = sortedPlayers

    m_overviewPlayerIDs = {}
    for _, entry in ipairs(sortedPlayers) do
        table.insert(m_overviewPlayerIDs, entry.id)
    end

    local selectedPlayerID = preferredPlayerID or m_selectedPlayerID
    if not allData[selectedPlayerID] then
        selectedPlayerID = m_overviewPlayerIDs[1] or -1
    end
    m_selectedPlayerID = selectedPlayerID

    local capture = mgr:CaptureFocusKey(m_ui.overview)
    local columns = BuildOverviewColumns(allData)
    m_treeColumns = columns
    m_ui.overview:SetColumns(columns)
    local sortColumn, sortAscending = m_ui.overview:GetSort()
    local resetSort = false
    if sortColumn and not m_ui.overview:GetColumnIndex(sortColumn) then
        m_ui.overview:SetDefaultSort(nil)
        sortColumn = nil
        sortAscending = false
        resetSort = true
    end
    m_treeSortColumn = sortColumn
    m_treeSortAscending = sortAscending == true
    m_treeSortOptions = BuildTreeSortOptions(columns)
    if m_ui.treeSort then
        local dropdownCapture = mgr:CaptureFocusKey(m_ui.treeSort)
        m_ui.treeSort:SetOptions(m_treeSortOptions)
        SyncTreeSortDropdown()
        if dropdownCapture then
            if resetSort then
                dropdownCapture = { key = m_ui.treeSort.FocusKey, path = {} }
            end
            mgr:RestoreFocus(m_ui.treeSort, dropdownCapture)
        end
    end
    m_ui.overview:Rebuild()

    if m_selectedPlayerID ~= -1 then
        SyncVanillaControlsForCityState(m_selectedPlayerID)
        SyncEnvoySlider()
        if not capture then
            mgr:PrepareFocus(m_ui.overview, GetCityStateFocusKey(m_selectedPlayerID))
        end
    end
    RebuildTreeView(GetOrderedTreePlayers())
end

-- ============================================================================
-- Panel construction
-- ============================================================================

local function GetActiveView()
    return m_viewMode == "tree" and m_ui.treeView or m_ui.overview
end

local function SetViewMode(viewMode)
    if viewMode ~= "table" and viewMode ~= "tree" then
        LogError("City-States received invalid view mode " .. tostring(viewMode))
        return false
    end
    if m_viewMode ~= viewMode then
        m_viewMode = viewMode
        SaveViewModeSetting(viewMode)
    end
    local activeView = GetActiveView()
    if activeView then
        if m_selectedPlayerID ~= -1 then
            local focusKey = viewMode == "tree"
                and GetTreeCityStateFocusKey(m_selectedPlayerID)
                or GetCityStateFocusKey(m_selectedPlayerID)
            mgr:PrepareFocus(activeView, focusKey)
        end
        mgr:SetFocus(activeView)
    end
    return true
end

local function ToggleViewMode()
    return SetViewMode(m_viewMode == "table" and "tree" or "table")
end

local function EnsurePanelBuilt()
    if m_ui.panel then
        m_ui.panel = nil
    end

    m_ui.panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function()
            local title = Locale.Lookup("LOC_CITY_STATES_TITLE")
            if IsSendEnvoysMode() then
                return title .. ", " .. Locale.Lookup("LOC_CITY_STATES_SEND_ENVOYS", GetEnvoysRemaining())
            end
            return title .. ", " .. Locale.Lookup("LOC_CITY_STATES_OVERVIEW")
        end,
    })
    m_ui.panel:AddInputBindings({
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
    })

    m_ui.overview = mgr:CreateWidget(OVERVIEW_TABLE_ID, "DataTable", {
        Label = function()
            local lines = GetInfoBoxLines()
            if #m_overviewPlayerIDs == 0 then
                table.insert(lines, Locale.Lookup("LOC_CITY_STATES_NONE_MET"))
            end
            return JoinNonEmpty(lines, ", ")
        end,
        HiddenPredicate = function() return m_viewMode ~= "table" end,
    })
    m_ui.overview:SetRowsProvider(function() return m_overviewPlayerIDs end)
    m_ui.overview:SetRowKeyGetter(function(playerID) return playerID end)
    m_ui.overview:SetRowLabelGetter(function(playerID)
        local kCS = GetCityStateData(playerID)
        return kCS and Locale.Lookup(kCS.Name) or ""
    end)
    m_ui.overview:SetDefaultSort(m_treeSortColumn
        and { column = m_treeSortColumn, ascending = m_treeSortAscending }
        or nil)
    m_ui.overview:On("row_focus_enter", function(_, playerID, rowIndex)
        if rowIndex > 0 then SelectCityState(playerID) end
    end)
    m_ui.overview:On("sort_changed", function(_, columnKey, ascending)
        m_treeSortColumn = columnKey
        m_treeSortAscending = ascending == true
        SyncTreeSortDropdown()
        RebuildTreeView(GetOrderedTreePlayers())
    end)
    m_ui.overview:AddInputBindings({
        {
            Key         = Keys.VK_LEFT,
            IsShift     = true,
            MSG         = KeyEvents.KeyDown,
            Description = "LOC_CAI_KB_REMOVE_CITYSTATE_ENVOY",
            Action      = function(w)
                local playerID = w:GetFocusedRow()
                if not playerID then return false end
                return TryAdjustEnvoysForPlayer(playerID, -1)
            end,
        },
        {
            Key         = Keys.VK_RIGHT,
            IsShift     = true,
            MSG         = KeyEvents.KeyDown,
            Description = "LOC_CAI_KB_ADD_CITYSTATE_ENVOY",
            Action      = function(w)
                local playerID = w:GetFocusedRow()
                if not playerID then return false end
                return TryAdjustEnvoysForPlayer(playerID, 1)
            end,
        },
        {
            Key         = Keys.VK_RETURN,
            IsControl   = true,
            MSG         = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_CONFIRM_CITYSTATE_ENVOYS",
            Action      = function() return TryConfirmEnvoys() end,
        },
    })
    m_ui.panel:AddChild(m_ui.overview)

    m_ui.treeSort = mgr:CreateWidget(TREE_SORT_ID, "Dropdown", {
        Label = function() return Locale.Lookup("LOC_CAI_CITYSTATES_ORDER_BY") end,
        FocusKey = "city-states:tree-sort",
        HiddenPredicate = function() return m_viewMode ~= "tree" end,
    })
    m_ui.treeSort:SetOptions(m_treeSortOptions)
    SyncTreeSortDropdown()
    m_ui.treeSort:On("value_changed", function(_, sort)
        m_treeSortColumn = sort.column
        m_treeSortAscending = sort.ascending == true
        m_ui.overview:SetDefaultSort(sort.column
            and { column = sort.column, ascending = sort.ascending }
            or nil)
        m_ui.overview:Rebuild()
        RebuildTreeView(GetOrderedTreePlayers())
    end)
    m_ui.panel:AddChild(m_ui.treeSort)

    m_ui.treeView = mgr:CreateWidget(TREE_VIEW_ID, "Tree", {
        Label = function() return JoinNonEmpty(GetInfoBoxLines(), ", ") end,
        HiddenPredicate = function() return m_viewMode ~= "tree" end,
    })
    m_ui.panel:AddChild(m_ui.treeView)

    m_ui.envoySlider = mgr:CreateWidget(ENVOY_SLIDER_ID, "Slider", {
        Label = function()
            return Locale.Lookup("LOC_CAI_CITYSTATES_ENVOYS_TO_SEND", GetEnvoysRemaining())
        end,
        Tooltip = function()
            local kCS = GetSelectedCityState()
            if not kCS then return "" end
            if not kCS.isAlive then
                return NormalizeText(Locale.Lookup("LOC_CITY_STATES_DESTROYED_LONG"))
            end
            if kCS.isAtWar and not kCS.CanReceiveTokensFrom then
                return NormalizeText(Locale.Lookup("LOC_CITY_STATES_CURRENTLY_AT_WAR"))
            end
            return ""
        end,
        HiddenPredicate = function()
            return not IsSendEnvoysMode() or m_selectedPlayerID == -1
        end,
        DisabledPredicate = function()
            if not m_caiIsLocalTurn then return true end
            local kCS = GetSelectedCityState()
            if not kCS then return true end
            return not kCS.CanReceiveTokensFrom
        end,
    })
    m_ui.envoySlider:SetMin(0)
    m_ui.envoySlider:SetStepSize(1)
    m_ui.envoySlider:SetValueSetter(function(w, newVal)
        if m_selectedPlayerID == -1 then return end
        local currentPending = GetPendingForPlayer(m_selectedPlayerID)
        local delta = newVal - currentPending
        if delta > 0 then
            for _ = 1, delta do OnMoreEnvoyTokens(m_selectedPlayerID) end
        elseif delta < 0 then
            for _ = 1, -delta do OnLessEnvoyTokens(m_selectedPlayerID) end
        end
        SyncEnvoySlider()
        CAI_RebuildViews()
    end)
    m_ui.panel:AddChild(m_ui.envoySlider)

    m_ui.confirmEnvoy = mgr:CreateWidget(CONFIRM_ENVOY_ID, "Button", {
        Label = function() return Locale.Lookup("LOC_CITY_STATES_CONFIRM_PLACEMENT") end,
        HiddenPredicate = function() return not IsSendEnvoysMode() end,
        DisabledPredicate = function()
            if not m_caiIsLocalTurn then return true end
            return Controls.ConfirmButton:IsDisabled()
        end,
    })
    m_ui.confirmEnvoy:On("activate", function()
        local total = SumCaiEnvoyChanges()
        Controls.ConfirmButton:DoLeftClick()
        Speak(Locale.Lookup("LOC_CAI_ENVOYS_SENT", total))
    end)
    m_ui.panel:AddChild(m_ui.confirmEnvoy)

    m_ui.lookAt = mgr:CreateWidget(LOOK_AT_ID, "Button", {
        Label = function() return Locale.Lookup("LOC_CITY_STATES_LOOK_AT") end,
        HiddenPredicate = function() return m_selectedPlayerID == -1 end,
    })
    m_ui.lookAt:On("activate", function()
        if m_selectedPlayerID ~= -1 then
            LookAtCityState(m_selectedPlayerID)
            local pPlayer = Players[m_selectedPlayerID]
            if pPlayer then
                for _, pCity in pPlayer:GetCities():Members() do
                    local plot = Map.GetPlot(pCity:GetX(), pCity:GetY())
                    if plot then
                        LuaEvents.CAICursorMoveTo(plot:GetIndex(), "jump")
                    end
                    break
                end
            end
        end
    end)
    m_ui.panel:AddChild(m_ui.lookAt)

    m_ui.warPeace = mgr:CreateWidget(WAR_PEACE_ID, "Button", {
        Label = function()
            if m_selectedPlayerID == -1 then return "" end
            return Controls.PeaceWarButton:GetText() or ""
        end,
        Tooltip = function()
            if m_selectedPlayerID == -1 then return "" end
            return NormalizeText(Controls.PeaceWarButton:GetToolTipString() or "")
        end,
        HiddenPredicate = function()
            if m_selectedPlayerID == -1 then return true end
            return Controls.PeaceWarButton:IsHidden()
        end,
        DisabledPredicate = function()
            if m_selectedPlayerID == -1 then return true end
            return Controls.PeaceWarButton:IsDisabled()
        end,
    })
    m_ui.warPeace:On("activate", function()
        Controls.PeaceWarButton:DoLeftClick()
    end)
    m_ui.panel:AddChild(m_ui.warPeace)

    m_ui.levy = mgr:CreateWidget(LEVY_ID, "Button", {
        Label = function()
            if m_selectedPlayerID == -1 then
                return Locale.Lookup("LOC_CITY_STATES_LEVY_MILITARY_BUTTON")
            end
            local kCS = GetSelectedCityState()
            if not kCS then return Locale.Lookup("LOC_CITY_STATES_LEVY_MILITARY_BUTTON") end
            if kCS.HasLevyActive and kCS.IsLocalPlayerSuzerain then
                return Locale.Lookup("LOC_CITY_STATES_LEVY_MILITARY_BUTTON") ..
                    " (" .. Locale.Lookup("LOC_CITY_STATES_MILITARY_ALREADY_LEVIED") .. ")"
            end
            return Locale.Lookup("LOC_CITY_STATES_LEVY_MILITARY_BUTTON") ..
                " (" .. Locale.Lookup("LOC_CAI_CITYSTATES_LEVY_COST", kCS.LevyMilitaryCost) .. ")"
        end,
        Tooltip = function()
            if m_selectedPlayerID == -1 then return "" end
            return NormalizeText(Controls.LevyMilitaryButton:GetToolTipString() or "")
        end,
        HiddenPredicate = function()
            if m_selectedPlayerID == -1 then return true end
            return Controls.LevyMilitaryButton:IsHidden()
        end,
        DisabledPredicate = function()
            if m_selectedPlayerID == -1 then return true end
            return Controls.LevyMilitaryButton:IsDisabled()
        end,
    })
    m_ui.levy:On("activate", function()
        Controls.LevyMilitaryButton:DoLeftClick()
    end)
    m_ui.panel:AddChild(m_ui.levy)

    m_ui.switchView = mgr:CreateWidget(SWITCH_VIEW_ID, "Button", {
        Label = function()
            return Locale.Lookup(m_viewMode == "table"
                and "LOC_CAI_TREE_SWITCH_TO_TREE"
                or "LOC_CAI_TREE_SWITCH_TO_TABLE")
        end,
    })
    m_ui.switchView:On("activate", function() ToggleViewMode() end)
    m_ui.panel:AddChild(m_ui.switchView)

end

-- ============================================================================
-- Lifecycle
-- ============================================================================

local function PushPanel(focusPlayerID)
    EnsurePanelBuilt()
    CAI_RebuildViews(focusPlayerID)
    if focusPlayerID and focusPlayerID ~= -1 then
        local focusKey = m_viewMode == "tree"
            and GetTreeCityStateFocusKey(focusPlayerID)
            or GetCityStateFocusKey(focusPlayerID)
        mgr:Push(m_ui.panel, { focus = focusKey })
    else
        mgr:Push(m_ui.panel, { focus = GetActiveView() })
    end
end

local function PopPanel()
    if mgr and m_ui.panel then
        mgr:RemoveFromStack(PANEL_ID)
    end
end

-- ============================================================================
-- Wraps
-- ============================================================================

Close = WrapFunc(Close, function(orig)
    m_caiEnvoyChanges = {}
    m_selectedPlayerID = -1
    PopPanel()
    orig()
end)

ViewList = WrapFunc(ViewList, function(orig)
    local numMet = GetCityStatesMetNum()
    local available = GetEnvoysAvailable()
    if available > 0 and numMet > 0 then
        m_caiMode = MODE.SendEnvoys
    else
        m_caiMode = MODE.Overview
    end
    orig()
end)

Refresh = WrapFunc(Refresh, function(orig)
    m_caiEnvoyChanges = {}
    orig()
    if mgr:GetWidgetById(PANEL_ID) then
        CAI_RebuildViews()
        SyncEnvoySlider()
    end
end)

OnMoreEnvoyTokens = WrapFunc(OnMoreEnvoyTokens, function(orig, iPlayer)
    orig(iPlayer)
    local amount = m_caiEnvoyChanges[iPlayer] or 0
    m_caiEnvoyChanges[iPlayer] = amount + 1
end)

OnLessEnvoyTokens = WrapFunc(OnLessEnvoyTokens, function(orig, iPlayer)
    orig(iPlayer)
    local amount = m_caiEnvoyChanges[iPlayer] or 0
    amount = amount - 1
    if amount <= 0 then
        m_caiEnvoyChanges[iPlayer] = nil
    else
        m_caiEnvoyChanges[iPlayer] = amount
    end
end)

OnConfirmPlacement = WrapFunc(OnConfirmPlacement, function(orig)
    orig()
    m_caiEnvoyChanges = {}
end)

OnLocalPlayerTurnBegin = WrapFunc(OnLocalPlayerTurnBegin, function(orig)
    m_caiIsLocalTurn = true
    orig()
end)

OnLocalPlayerTurnEnd = WrapFunc(OnLocalPlayerTurnEnd, function(orig)
    m_caiIsLocalTurn = false
    orig()
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, input)
    if mgr and mgr:GetWidgetById(PANEL_ID) then
        if mgr:HandleInput(input) then
            return true
        end
    end
    return orig(input)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)

-- ============================================================================
-- Open/Close event wraps
-- ============================================================================

local baseOnOpenCityStates = OnOpenCityStates
LuaEvents.PartialScreenHooks_OpenCityStates.Remove(baseOnOpenCityStates)
local function CAI_OnOpenCityStates()
    baseOnOpenCityStates()
    PushPanel()
end
LuaEvents.PartialScreenHooks_OpenCityStates.Add(CAI_OnOpenCityStates)

local baseOnOpenSendEnvoys = OnOpenSendEnvoys
LuaEvents.NotificationPanel_OpenCityStatesSendEnvoys.Remove(baseOnOpenSendEnvoys)
local function CAI_OnOpenSendEnvoys(iPlayer)
    baseOnOpenSendEnvoys(iPlayer)
    PushPanel(iPlayer)
end
LuaEvents.NotificationPanel_OpenCityStatesSendEnvoys.Add(CAI_OnOpenSendEnvoys)

local baseOnRaiseMinorCivicsPanel = OnRaiseMinorCivicsPanel
LuaEvents.CityBannerManager_RaiseMinorCivPanel.Remove(baseOnRaiseMinorCivicsPanel)
local function CAI_OnRaiseMinorCivicsPanel(playerID)
    baseOnOpenCityStates()
    PushPanel(playerID)
end
LuaEvents.CityBannerManager_RaiseMinorCivPanel.Add(CAI_OnRaiseMinorCivicsPanel)
