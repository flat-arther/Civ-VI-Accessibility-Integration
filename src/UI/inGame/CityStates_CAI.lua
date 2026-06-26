include("caiUtils")
include("Civ6Common")
include("GameCapabilities")

if IsExpansion2Active() then
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
    ["DIPLO_STATE_PROTECTOR"]       = { Tooltip = "LOC_CITY_STATES_DIPLO_SUZERAIN", Short = "LOC_CAI_CITYSTATES_REL_SUZERAIN" },
    ["DIPLO_STATE_PATRON"]          = { Tooltip = "LOC_CITY_STATES_DIPLO_GOOD", Short = "LOC_CAI_CITYSTATES_REL_PATRON" },
    ["DIPLO_STATE_AWARE"]           = { Tooltip = "LOC_CITY_STATES_DIPLO_AWARE", Short = "LOC_CAI_CITYSTATES_REL_AWARE" },
    ["DIPLO_STATE_WAR_WITH_MAJOR"]  = { Tooltip = "LOC_CITY_STATES_DIPLO_WAR", Short = "LOC_CAI_CITYSTATES_REL_AT_WAR" },
    ["DIPLO_STATE_WAR_WITH_MINOR"]  = { Tooltip = "LOC_CITY_STATES_DIPLO_WAR", Short = "LOC_CAI_CITYSTATES_REL_AT_WAR" },
    ["DIPLO_STATE_MINOR_MINOR_WAR"] = { Tooltip = "LOC_CITY_STATES_DIPLO_WAR", Short = "LOC_CAI_CITYSTATES_REL_AT_WAR" },
}

local PANEL_ID           = "CAICityStates_Panel"
local TREE_ID            = "CAICityStates_Tree"
local ENVOY_SLIDER_ID    = "CAICityStates_EnvoySlider"
local CONFIRM_ENVOY_ID   = "CAICityStates_ConfirmEnvoy"
local LOOK_AT_ID         = "CAICityStates_LookAt"
local WAR_PEACE_ID       = "CAICityStates_WarPeace"
local LEVY_ID            = "CAICityStates_Levy"
local INFO_BOX_ID        = "CAICityStates_InfoBox"

local m_ui               = {
    panel        = nil,
    tree         = nil,
    envoySlider  = nil,
    confirmEnvoy = nil,
    lookAt       = nil,
    warPeace     = nil,
    levy         = nil,
    infoBox      = nil,
}

local m_selectedPlayerID = -1
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
    text = string.gsub(text, "%[COLOR:%s*[^%]]+%]", "")
    text = string.gsub(text, "%[NEWLINE%]", ", ")
    text = string.gsub(text, "%[ICON_[^%]]+%]", "")
    text = string.gsub(text, "[,%s]+,", ",")
    text = string.gsub(text, "^[,%s]+", "")
    text = string.gsub(text, "[,%s]+$", "")
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

-- ============================================================================
-- Live game-state readers
-- ============================================================================

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
        Relationships         = GetRelationships(playerID),
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
            table.insert(parts, Locale.Lookup("LOC_CAI_CITYSTATES_RESOURCES", table.concat(resList, ", ")))
        else
            table.insert(parts, Locale.Lookup("LOC_CITY_STATES_SUZERAIN_NO_RESOURCES_AVAILABLE"))
        end
    end

    return table.concat(parts, "[NEWLINE]")
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
-- Row label and tooltip
-- ============================================================================

local function HasActiveQuests(playerID)
    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == -1 then return false end
    local questsManager = Game.GetQuestsManager()
    if not questsManager then return false end
    for questInfo in GameInfo.Quests() do
        if questsManager:HasActiveQuestFromPlayer(localPlayerID, playerID, questInfo.Index) then
            return true
        end
    end
    return false
end

local function FormatRowLabel(playerID)
    local kCS = GetCityStateData(playerID)
    if not kCS then return "" end

    local parts = {}
    table.insert(parts, Locale.Lookup(kCS.Name))
    if not kCS.isAlive then
        table.insert(parts, Locale.Lookup("LOC_CITY_STATES_DESTROYED"))
    end
    table.insert(parts, GetTypeName(kCS))

    local diploShort = GetDiploShort(kCS)
    if diploShort ~= "" then
        table.insert(parts, diploShort)
    end

    if kCS.isBonusSuzerain then
        table.insert(parts, Locale.Lookup("LOC_CAI_CITYSTATES_ENVOYS", kCS.Tokens))
        table.insert(parts, Locale.Lookup("LOC_CITY_STATES_SUZERAIN"))
    else
        local needed = kCS.SuzerainTokensNeeded
        if needed < 3 then needed = 3 end
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

    if m_hasGovernors then
        local localPlayerID = Game.GetLocalPlayer()
        if localPlayerID ~= -1 then
            local pGov = GetAmbassadorForPlayer(playerID, localPlayerID)
            if pGov then
                local govDef = GameInfo.Governors[pGov:GetType()]
                local govName = (govDef and govDef.Name) and Locale.Lookup(govDef.Name)
                    or Locale.Lookup("LOC_CAI_CITYSTATES_AMBASSADOR")
                table.insert(parts, Locale.Lookup("LOC_CAI_CITYSTATES_AMBASSADOR_ASSIGNED", govName))
            end
        end
    end

    if HasActiveQuests(playerID) then
        table.insert(parts, Locale.Lookup("LOC_CAI_CITYSTATES_QUEST_AVAILABLE"))
    end

    return JoinNonEmpty(parts, ", ")
end

local function FormatRowTooltip(playerID)
    local kCS = GetCityStateData(playerID)
    if not kCS then return "" end
    FillBonuses(kCS)
    local parts = {}

    local tiers = { 1, 3, 6 }
    for _, tier in ipairs(tiers) do
        local bonus = kCS.Bonuses[tier]
        if bonus then
            table.insert(parts,
                Locale.Lookup("LOC_CAI_CITYSTATES_ENVOYS_TIER", tier) .. ", " .. NormalizeText(bonus.Details))
        end
    end

    local suzerainUniqueAndRes = GetSuzerainUniqueBonusAndResources(kCS.iPlayer)
    if suzerainUniqueAndRes ~= "" then
        table.insert(parts, Locale.Lookup("LOC_CITY_STATES_SUZERAIN") .. ", " .. suzerainUniqueAndRes)
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
                ", " .. NormalizeText(bonus.Details)
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
            ", " .. NormalizeText(suzerainBonus.Details)
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
    local pLocalDiplomacy = Players[localPlayerID]:GetDiplomacy()

    local sorted = {}
    for otherPlayerID, influence in pairs(kCS.Influence) do
        table.insert(sorted, { playerID = otherPlayerID, influence = influence })
    end
    table.sort(sorted, function(a, b) return a.influence > b.influence end)

    for _, entry in ipairs(sorted) do
        local pConfig = PlayerConfigurations[entry.playerID]
        local civName
        if entry.playerID == localPlayerID then
            civName = Locale.Lookup(pConfig:GetPlayerName()) .. " (" .. Locale.Lookup("LOC_CITY_STATES_YOU") .. ")"
        elseif pLocalDiplomacy:HasMet(entry.playerID) then
            civName = Locale.Lookup(pConfig:GetPlayerName())
        else
            civName = Locale.Lookup("LOC_LOYALTY_PANEL_UNMET_CIV")
        end

        local label = civName .. ": " .. Locale.Lookup("LOC_CAI_CITYSTATES_ENVOYS", entry.influence)

        local pGov = GetAmbassadorForPlayer(playerID, entry.playerID)
        if pGov then
            local eType = pGov:GetType()
            local govDef = GameInfo.Governors[eType]
            if govDef and govDef.Name then
                label = label .. ", " .. Locale.Lookup(govDef.Name)
            else
                label = label .. ", " .. Locale.Lookup("LOC_CAI_CITYSTATES_AMBASSADOR")
            end
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
        local reward = kQuest.Reward and kQuest.Reward ~= "" and
            (Locale.Lookup("LOC_CITY_STATES_REWARD") .. " " .. NormalizeText(kQuest.Reward)) or ""
        local label = JoinNonEmpty({ kQuest.Name, NormalizeText(kQuest.Description), reward }, ", ")
        parent:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAICityStates_Quest"), "StaticText", {
            Label = function() return label end,
        }))
    end
end

local function BuildRelationshipEntry(parent, entry, idPrefix)
    local name
    Speak(entry.DiploTooltip)
    if entry.HasMet then
        name = Locale.Lookup(entry.PlayerName)
    else
        name = Locale.Lookup("LOC_LOYALTY_PANEL_UNMET_CIV")
    end
    local pipInfo = DIPLO_PIP_INFO[entry.DiploState]
    local statusText = pipInfo and Locale.Lookup(pipInfo.Short) or ""
    Speak(statusText)
    local label = JoinNonEmpty({ name, statusText }, ", ")
    parent:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId(idPrefix), "StaticText", {
        Label = function() return label end,
    }))
end

local function BuildRelationshipsSection(parent, playerID)
    local kCS = GetCityStateData(playerID)
    if not kCS or not kCS.Relationships then return end
    local selfIcon = "ICON_" .. kCS.CivType

    for _, entry in ipairs(kCS.Relationships.CivRelationships or {}) do
        BuildRelationshipEntry(parent, entry, "CAICityStates_Rel")
    end

    for _, entry in ipairs(kCS.Relationships.CityStateRelationships or {}) do
        if entry.PlayerIcon ~= selfIcon then
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

-- ============================================================================
-- Tree row creation
-- ============================================================================

local function CreateCityStateRow(playerID)
    local row = mgr:CreateWidget(mgr:GenerateWidgetId("CAICityStates_Row"), "TreeItem", {
        Label    = function() return FormatRowLabel(playerID) end,
        Tooltip  = function() return FormatRowTooltip(playerID) end,
        FocusKey = "cs:" .. tostring(playerID),
    })
    row:SetFocusSound("Main_Menu_Mouse_Over")

    row:On("focus_enter", function(w)
        if w:IsFocused() and playerID ~= m_selectedPlayerID then
            m_selectedPlayerID = playerID
            SyncVanillaControlsForCityState(playerID)
            SyncEnvoySlider()
        end
    end)

    local relDetailWidget = mgr:CreateWidget(mgr:GenerateWidgetId("CAICityStates_RelDetail"), "StaticText", {
        Label = function()
            local kCS = GetCityStateData(playerID)
            if not kCS then return "" end
            local short = GetDiploShort(kCS)
            local long = GetDiploLong(kCS)
            if short == "" then return "" end
            if long ~= "" then
                return Locale.Lookup("LOC_CAI_CITYSTATES_RELATIONSHIP", short, long)
            end
            return short
        end,
    })
    row:AddChild(relDetailWidget)

    local bonusesSection = mgr:CreateWidget(mgr:GenerateWidgetId("CAICityStates_BonusSec"), "TreeItem", {
        Label = function()
            local kCS = GetCityStateData(playerID)
            if not kCS then return Locale.Lookup("LOC_CITY_STATES_BONUSES", "") end
            local count = 0
            if kCS.isBonus1 then count = count + 1 end
            if kCS.isBonus3 then count = count + 1 end
            if kCS.isBonus6 then count = count + 1 end
            if kCS.isBonusSuzerain then count = count + 1 end
            return Locale.Lookup("LOC_CITY_STATES_BONUSES", Locale.Lookup(kCS.Name)) ..
                ", " .. Locale.Lookup("LOC_CAI_CITYSTATES_BONUS_COUNT", count, 4)
        end,
        FocusKey = "cs:" .. tostring(playerID) .. ":bonuses",
    })
    bonusesSection._csBuilt = false
    bonusesSection:On("focus_enter", function(w)
        if not w._csBuilt then
            w._csBuilt = true
            BuildBonusesSection(w, playerID)
        end
    end)
    row:AddChild(bonusesSection)

    local influenceSection = mgr:CreateWidget(mgr:GenerateWidgetId("CAICityStates_InfSec"), "TreeItem", {
        Label = function()
            local kCS = GetCityStateData(playerID)
            local count = kCS and CountTable(kCS.Influence) or 0
            return Locale.Lookup("LOC_CITY_STATES_INFLUENCED_BY") ..
                ", " .. Locale.Lookup("LOC_CITY_STATES_CIVILIZATIONS", count)
        end,
        FocusKey = "cs:" .. tostring(playerID) .. ":influence",
    })
    influenceSection._csBuilt = false
    influenceSection:On("focus_enter", function(w)
        if not w._csBuilt then
            w._csBuilt = true
            BuildInfluenceSection(w, playerID)
        end
    end)
    row:AddChild(influenceSection)

    local questsSection = mgr:CreateWidget(mgr:GenerateWidgetId("CAICityStates_QuestSec"), "TreeItem", {
        Label = function()
            local kCS = GetCityStateData(playerID)
            local count = kCS and CountTable(kCS.Quests) or 0
            return Locale.Lookup("LOC_CITY_STATES_QUESTS") .. ", " .. Locale.Lookup("LOC_CAI_CITYSTATES_ACTIVE", count)
        end,
        FocusKey = "cs:" .. tostring(playerID) .. ":quests",
    })
    questsSection._csBuilt = false
    questsSection:On("focus_enter", function(w)
        if not w._csBuilt then
            w._csBuilt = true
            BuildQuestsSection(w, playerID)
        end
    end)
    row:AddChild(questsSection)

    local relSection = mgr:CreateWidget(mgr:GenerateWidgetId("CAICityStates_RelSec"), "TreeItem", {
        Label = function()
            local kCS = GetCityStateData(playerID)
            local count = 0
            if kCS and kCS.Relationships then
                count = #(kCS.Relationships.CivRelationships or {}) + #(kCS.Relationships.CityStateRelationships or {})
            end
            return Locale.Lookup("LOC_CITY_STATES_RELATIONSHIPS") ..
                ", " .. Locale.Lookup("LOC_CITY_STATES_CIVILIZATIONS", count)
        end,
        FocusKey = "cs:" .. tostring(playerID) .. ":relationships",
    })
    relSection._csBuilt = false
    relSection:On("focus_enter", function(w)
        if not w._csBuilt then
            w._csBuilt = true
            BuildRelationshipsSection(w, playerID)
        end
    end)
    row:AddChild(relSection)

    return row
end

-- ============================================================================
-- Info box content
-- ============================================================================

local function GetInfoBoxText()
    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == -1 then return "" end

    local pLocalPlayer = Players[localPlayerID]
    local pInfluence = pLocalPlayer:GetInfluence()
    if not pInfluence then return "" end

    local balance = math.floor(pInfluence:GetPointsEarned() + 0.5)
    local threshold = pInfluence:GetPointsThreshold()
    local rate = math.floor(pInfluence:GetPointsPerTurn() * 10 + 0.5) / 10
    local envoysPerThreshold = pInfluence:GetTokensPerThreshold()
    local available = pInfluence:GetTokensToGive()

    local lines = {}
    table.insert(lines, Locale.Lookup("LOC_CAI_CITYSTATES_INFO_ENVOYS_AVAILABLE", available))
    table.insert(lines,
        NormalizeText(Locale.Lookup("LOC_CAI_CITYSTATES_INFO_INFLUENCE", balance, threshold, rate, envoysPerThreshold)))
    table.insert(lines, NormalizeText(Locale.Lookup("LOC_TOP_PANEL_INFLUENCE_TOOLTIP_SOURCES_HELP")))
    return table.concat(lines, "\n")
end

-- ============================================================================
-- Rebuild
-- ============================================================================

local function CAI_RebuildTree()
    if not m_ui.tree then return end
    if ContextPtr:IsHidden() then return end

    m_selectedPlayerID = -1

    local capture = mgr:CaptureFocusKey(m_ui.tree)
    m_ui.tree:ClearChildren()

    local allData = GetAllCityStatesData()
    local sortedPlayers = {}
    for playerID, kCS in pairs(allData) do
        table.insert(sortedPlayers, { id = playerID, name = Locale.Lookup(kCS.Name) })
    end
    table.sort(sortedPlayers, function(a, b) return a.name < b.name end)

    for _, entry in ipairs(sortedPlayers) do
        m_ui.tree:AddChild(CreateCityStateRow(entry.id))
    end

    if #sortedPlayers == 0 then
        m_ui.tree:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAICityStates_NoneMet"), "StaticText", {
            Label = function() return Locale.Lookup("LOC_CITY_STATES_NONE_MET") end,
        }))
    end

    if m_ui.infoBox then
        m_ui.infoBox:SetText(GetInfoBoxText(), true)
    end

    mgr:RestoreFocus(m_ui.tree, capture)
end

-- ============================================================================
-- Panel construction
-- ============================================================================

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

    m_ui.tree = mgr:CreateWidget(TREE_ID, "Tree", {
        Label = function()
            local count = 0
            local localPlayerID = Game.GetLocalPlayer()
            if localPlayerID ~= -1 then
                for _, pPlayer in ipairs(PlayerManager.GetAliveMinors()) do
                    local pInfluence = pPlayer:GetInfluence()
                    if pInfluence and pInfluence:CanReceiveInfluence()
                        and Players[localPlayerID]:GetDiplomacy():HasMet(pPlayer:GetID()) then
                        count = count + 1
                    end
                end
            end
            return Locale.Lookup("LOC_CITY_STATES_TITLE") .. ", " .. Locale.Lookup("LOC_CAI_CITYSTATES_MET_COUNT", count)
        end,
    })
    m_ui.panel:AddChild(m_ui.tree)

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

    m_ui.infoBox = mgr:CreateWidget(INFO_BOX_ID, "EditBox", {
        Label           = function() return Locale.Lookup("LOC_CAI_CITYSTATES_INFO") end,
        ReadOnly        = true,
        AlwaysEdit      = true,
        HighlightOnEdit = false,
    })
    m_ui.infoBox:SetText(GetInfoBoxText(), true)
    m_ui.panel:AddChild(m_ui.infoBox)
end

-- ============================================================================
-- Lifecycle
-- ============================================================================

local function PushPanel(focusPlayerID)
    EnsurePanelBuilt()
    CAI_RebuildTree()
    if focusPlayerID and focusPlayerID ~= -1 then
        mgr:Push(m_ui.panel, { focus = "cs:" .. tostring(focusPlayerID) })
    else
        mgr:Push(m_ui.panel)
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
        CAI_RebuildTree()
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
