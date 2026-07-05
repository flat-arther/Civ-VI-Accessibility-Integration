include("caiUtils")
include("Civ6Common")

if IsExpansion2Active() then
    include("DiplomacyRibbon_Expansion2")
elseif IsExpansion1Active() then
    include("DiplomacyRibbon_Expansion1")
else
    include("DiplomacyRibbon")
end

local mgr = ExposedMembers.CAI_UIManager

local LIST_ID = "CAIDiploRibbon_List"

local ACTION_OPEN_LIST = Input.GetActionId("UI_DiplomacyRibbonOpenList")
local ACTION_OPEN_CONGRESS = Input.GetActionId("UI_DiplomacyRibbonOpenWorldCongress")

local m_list = nil

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

local function IsCongressInSession()
    local WORLD_CONGRESS_STAGE_1 = DB.MakeHash("TURNSEG_WORLDCONGRESS_1")
    local WORLD_CONGRESS_STAGE_2 = DB.MakeHash("TURNSEG_WORLDCONGRESS_2")
    local WORLD_CONGRESS_RESOLUTION = DB.MakeHash("TURNSEG_WORLDCONGRESS_RESOLUTION")
    local seg = Game.GetCurrentTurnSegment()
    return seg == WORLD_CONGRESS_STAGE_1 or seg == WORLD_CONGRESS_STAGE_2 or seg == WORLD_CONGRESS_RESOLUTION
end

local function GetCongressTooltip()
    if IsCongressInSession() then
        return Locale.Lookup("LOC_WORLD_CONGRESS_IS_CURRENTLY_IN_SESSION")
    end
    local pData = Game.GetWorldCongress():GetMeetingStatus()
    local turnsLeft = pData.TurnsLeft + 1
    return Locale.Lookup("LOC_WORLD_CONGRESS_HUD_BAR_TIME_UNTIL_NEXT_SESSION", turnsLeft)
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
    return Locale.Lookup("LOC_CAI_DIPLO_RIBBON_TEAM", teamID + 1)
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

local function GetLeaderLabel(playerID, localPlayerID)
    local pConfig = PlayerConfigurations[playerID]
    if not pConfig then return "?" end

    local parts = {}
    if not IsMaskedPlayer(playerID, localPlayerID) then
        local name = Locale.Lookup(pConfig:GetLeaderName())
        local civName = Locale.Lookup(pConfig:GetCivilizationShortDescription())
        parts = { name, civName }

        if playerID == localPlayerID then
            table.insert(parts, Locale.Lookup("LOC_HUD_CITY_YOU"))
        end

        local rel = GetRelationshipLabel(playerID, localPlayerID)
        if rel then
            table.insert(parts, rel)
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

    return JoinNonEmpty(parts, ", ")
end

local function GetLeaderTooltip(playerID, localPlayerID)
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

local function CloseList()
    if mgr and m_list then
        mgr:RemoveFromStack(LIST_ID)
        m_list = nil
    end
end

local function PopulateList(list)
    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == -1 then return nil end

    local localPlayer = Players[localPlayerID]
    local localDiplomacy = localPlayer:GetDiplomacy()

    local kPlayers = PlayerManager.GetAliveMajors()
    table.sort(kPlayers,
        function(a, b) return localDiplomacy:GetMetTurn(a:GetID()) < localDiplomacy:GetMetTurn(b:GetID()) end)

    local function AddLeaderItem(playerID)
        local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAIDiploRibbon_L"), "MenuItem", {
            Label = function() return GetLeaderLabel(playerID, localPlayerID) end,
            Tooltip = function() return GetLeaderTooltip(playerID, localPlayerID) end,
        })
        item.FocusKey = "leader:" .. playerID
        item:On("activate", function()
            local uiLeader = GetUILeadersByID()[playerID]
            if uiLeader then
                uiLeader.SelectButton:DoLeftClick()
            end
        end)
        list:AddChild(item)
    end

    AddLeaderItem(localPlayerID)

    for _, pPlayer in ipairs(kPlayers) do
        local playerID = pPlayer:GetID()
        if playerID ~= localPlayerID then
            local isMet = localDiplomacy:HasMet(playerID)
            local pConfig = PlayerConfigurations[playerID]
            local isHumanMP = GameConfiguration.IsAnyMultiplayer() and pConfig:IsHuman()
            if isMet or isHumanMP then
                AddLeaderItem(playerID)
            end
        end
    end

    if HasCongressButton() then
        local congressItem = mgr:CreateWidget("CAIDiploRibbon_Congress", "MenuItem", {
            Label = function() return Locale.Lookup("LOC_CAI_DIPLO_RIBBON_CONGRESS") end,
            Tooltip = function() return GetCongressTooltip() end,
        })
        congressItem.FocusKey = "congress"
        congressItem:On("activate", function()
            ActivateCongress()
        end)
        list:AddChild(congressItem)
    end
end

local function BuildList()
    if not mgr then return nil end

    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == -1 then return nil end

    local list = mgr:CreateWidget(LIST_ID, "List", {
        Label = function() return Locale.Lookup("LOC_CAI_DIPLO_RIBBON_LABEL") end,
    })
    list:On("focus_leave", function() CloseList() end)
    list:AddInputBinding({
        Key         = Keys.VK_ESCAPE,
        MSG         = KeyEvents.KeyUp,
        Description = "LOC_CAI_KB_CLOSE",
        Action      = function()
            CloseList()
            return true
        end,
    })

    PopulateList(list)

    m_list = list
end

local function RebuildIfPushed()
    if not m_list or not mgr then return end
    local capture = m_list and mgr:CaptureFocusKey(m_list) or nil
    PopulateList(m_list)

    if capture then
        mgr:RestoreFocus(m_list, capture)
    end
end

local function OpenList()
    if not mgr then return end
    CloseList()
    BuildList()
    if m_list then
        mgr:Push(m_list)
    end
end

UpdateLeaders = WrapFunc(UpdateLeaders, function(orig)
    orig()
    RebuildIfPushed()
end)

local function OnInputActionTriggered(actionId)
    if ContextPtr:IsHidden() then return end
    if actionId == ACTION_OPEN_LIST then
        OpenList()
    elseif actionId == ACTION_OPEN_CONGRESS then
        if HasCongressButton() then
            ActivateCongress()
        end
    end
end

Events.InputActionTriggered.Add(OnInputActionTriggered)

OnShutdown = WrapFunc(OnShutdown, function(orig)
    Events.InputActionTriggered.Remove(OnInputActionTriggered)
    CloseList()
    orig()
end)

ContextPtr:SetShutdown(OnShutdown)
