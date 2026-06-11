include("caiUtils")
include("Civ6Common")

if IsExpansion2Active() then
    include("EspionageOverview_Expansion1")
elseif IsExpansion1Active() then
    include("EspionageOverview_Expansion1")
else
    include("EspionageOverview")
end

local mgr = ExposedMembers.CAI_UIManager

local PANEL_ID       = "CAIEspOv_Panel"
local TABS_ID        = "CAIEspOv_Tabs"
local OP_TREE        = "CAIEspOv_OpTree"
local MH_TREE        = "CAIEspOv_MHTree"
local VIEW_CITY_ID   = "CAIEspOv_ViewCity"
local HOVER_SOUND    = "Main_Menu_Mouse_Over"

local TAB_OPERATIVES     = 1
local TAB_MISSION_HISTORY = 2

local m_panel        = nil
local m_tabs         = nil
local m_opTree       = nil
local m_mhTree       = nil
local m_viewCityBtn  = nil
local m_isMirroringTab = false
local m_focusedCityOwner = nil
local m_focusedCityID    = nil

local m_cachedOperatives   = {}
local m_cachedOffMap       = {}
local m_cachedCapturedOwn  = {}
local m_cachedCapturedEnemy = {}
local m_cachedMissions     = {}

-- ============================================================================
-- Helpers
-- ============================================================================

local function AppendIfNonEmpty(parts, value)
    if value and value ~= "" then
        parts[#parts + 1] = value
    end
end

local function JoinNonEmpty(parts, sep)
    local out = {}
    for _, part in ipairs(parts) do
        if part and part ~= "" then out[#out + 1] = part end
    end
    return table.concat(out, sep)
end

local function GetCityForSpy(spy)
    local spyPlot = Map.GetPlot(spy:GetX(), spy:GetY())
    if spyPlot then
        return Cities.GetPlotPurchaseCity(spyPlot)
    end
    return nil
end

local function GetDistrictNameForSpy(spy)
    local spyPlot = Map.GetPlot(spy:GetX(), spy:GetY())
    if not spyPlot then return nil end
    local districtType = spyPlot:GetDistrictType()
    if districtType and districtType >= 0 then
        local dInfo = GameInfo.Districts[districtType]
        if dInfo then return Locale.Lookup(dInfo.Name) end
    end
    return nil
end

local function IsCounterspyOperation(operationType)
    local opInfo = GameInfo.UnitOperations[operationType]
    return opInfo and opInfo.Hash == UnitOperationTypes.SPY_COUNTERSPY
end

local function GetNonWonderDistricts(city)
    local names = {}
    local cityDistricts = city:GetDistricts()
    if not cityDistricts then return names end
    for _, district in cityDistricts:Members() do
        if district:IsComplete() then
            local dInfo = GameInfo.Districts[district:GetType()]
            if dInfo and dInfo.DistrictType ~= "DISTRICT_WONDER" then
                names[#names + 1] = Locale.Lookup(dInfo.Name)
            end
        end
    end
    return names
end

-- ============================================================================
-- Data Capture Wraps
-- ============================================================================

AddOperative = WrapFunc(AddOperative, function(orig, spy)
    orig(spy)
    local city = GetCityForSpy(spy)
    local operationType = spy:GetSpyOperation()
    local operationInfo = nil
    if operationType ~= -1 then
        operationInfo = GameInfo.UnitOperations[operationType]
    end

    table.insert(m_cachedOperatives, {
        unitID = spy:GetID(),
        name = Locale.Lookup(spy:GetName()),
        level = spy:GetExperience():GetLevel(),
        ownerCityID = city and city:GetID() or nil,
        ownerCityOwnerID = city and city:GetOwner() or nil,
        operationType = operationType,
        operationInfo = operationInfo,
        districtName = GetDistrictNameForSpy(spy),
        spy = spy,
        city = city,
    })
end)

AddOffMapOperative = WrapFunc(AddOffMapOperative, function(orig, spy)
    orig(spy)
    local spyPlot = Map.GetPlot(spy.XLocation, spy.YLocation)
    local targetCity = spyPlot and Cities.GetPlotPurchaseCity(spyPlot) or nil

    table.insert(m_cachedOffMap, {
        name = Locale.Lookup(spy.Name),
        level = spy.Level,
        returnTurn = spy.ReturnTurn,
        targetCityName = targetCity and Locale.Lookup(targetCity:GetName()) or nil,
    })
end)

AddCapturedOperative = WrapFunc(AddCapturedOperative, function(orig, spy, playerCapturedBy)
    orig(spy, playerCapturedBy)

    local capturingConfig = PlayerConfigurations[playerCapturedBy]
    local localPlayerID = Game.GetLocalPlayer()
    local atWar = Players[localPlayerID]:GetDiplomacy():IsAtWarWith(playerCapturedBy)
    local pendingDeal = DealManager.HasPendingDeal(localPlayerID, playerCapturedBy)

    local disabledReason = nil
    if atWar then
        disabledReason = Locale.Lookup("LOC_DIPLOPANEL_AT_WAR")
    elseif pendingDeal then
        disabledReason = Locale.Lookup("LOC_DIPLOMACY_ANOTHER_DEAL_WITH_PLAYER_PENDING")
    end

    table.insert(m_cachedCapturedOwn, {
        name = Locale.Lookup(spy.Name),
        level = spy.Level,
        nameIndex = spy.NameIndex,
        capturingPlayerID = playerCapturedBy,
        capturingPlayerName = capturingConfig and Locale.Lookup(capturingConfig:GetPlayerName()) or "",
        capturingCivName = capturingConfig and Locale.Lookup(capturingConfig:GetCivilizationDescription()) or "",
        tradeDisabled = (atWar or pendingDeal),
        disabledReason = disabledReason,
    })
end)

AddCapturedEnemyOperative = WrapFunc(AddCapturedEnemyOperative, function(orig, spyInfo)
    orig(spyInfo)
    local owningConfig = PlayerConfigurations[spyInfo.OwningPlayer]
    local localDiplo = Players[Game.GetLocalPlayer()]:GetDiplomacy()
    local atWar = localDiplo and localDiplo:IsAtWarWith(spyInfo.OwningPlayer) or false

    table.insert(m_cachedCapturedEnemy, {
        name = Locale.Lookup(spyInfo.Name),
        nameIndex = spyInfo.NameIndex,
        owningPlayerID = spyInfo.OwningPlayer,
        owningCivName = owningConfig and Locale.Lookup(owningConfig:GetCivilizationDescription()) or "",
        tradeDisabled = atWar,
        disabledReason = atWar and Locale.Lookup("LOC_ESPIONAGE_SPY_TRADE_DISABLED_AT_WAR",
            Locale.ToUpper(spyInfo.Name),
            owningConfig and Locale.Lookup(owningConfig:GetCivilizationShortDescription()) or "") or nil,
    })
end)

AddMissionHistoryInstance = WrapFunc(AddMissionHistoryInstance, function(orig, mission)
    if mission.InitialResult == EspionageResultTypes.SUCCESS_MUST_ESCAPE or
       mission.InitialResult == EspionageResultTypes.FAIL_MUST_ESCAPE then
        if mission.EscapeResult == EspionageResultTypes.NO_RESULT then
            orig(mission)
            return
        end
    end

    orig(mission)

    local operationInfo = GameInfo.UnitOperations[mission.Operation]
    local outcomeDetails = GetMissionOutcomeDetails(mission)
    local turnsSince = Game.GetCurrentGameTurn() - mission.CompletionTurn

    table.insert(m_cachedMissions, {
        name = Locale.Lookup(mission.Name),
        levelAfter = mission.LevelAfter,
        operationInfo = operationInfo,
        turnsSince = turnsSince,
        outcome = outcomeDetails,
        mission = mission,
        index = #m_cachedMissions + 1,
    })
end)

-- ============================================================================
-- Operatives Label/Tooltip Builders
-- ============================================================================

local function BuildSpyLabel(entry)
    local parts = {}
    parts[#parts + 1] = entry.name
    parts[#parts + 1] = Locale.Lookup(GetSpyRankNameByLevel(entry.level))

    if entry.operationType == -1 then
        parts[#parts + 1] = Locale.Lookup("LOC_ESPIONAGEOVERVIEW_AWAITING_ASSIGNMENT")
    elseif entry.operationInfo then
        parts[#parts + 1] = Locale.Lookup(entry.operationInfo.Description)
    end

    return table.concat(parts, ", ")
end

local function BuildSpyTooltip(entry)
    local parts = {}
    local spy = entry.spy
    if not spy then return "" end

    if entry.operationType ~= -1 and entry.operationInfo then
        if entry.city then
            if IsCounterspyOperation(entry.operationType) then
                AppendIfNonEmpty(parts, Locale.Lookup("LOC_ESPIONAGECHOOSER_COUNTERSPY", entry.districtName or ""))
            else
                AppendIfNonEmpty(parts, GetFormattedOperationDetailText(entry.operationInfo, spy, entry.city))
            end
        end

        if entry.districtName then
            AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_ESPIONAGE_MISSION_DISTRICT", entry.districtName))
        end

        local turnsRemaining = spy:GetSpyOperationEndTurn() - Game.GetCurrentGameTurn()
        if turnsRemaining < 0 then turnsRemaining = 0 end
        parts[#parts + 1] = Locale.Lookup("LOC_CAI_ESPIONAGE_MISSION_TURNS", turnsRemaining)

        local totalTurns = UnitManager.GetTimeToComplete(entry.operationType, spy)
        if totalTurns > 0 then
            local pct = math.floor(((totalTurns - turnsRemaining) / totalTurns) * 100 + 0.5)
            parts[#parts + 1] = pct .. "%"
        end
    end

    return JoinNonEmpty(parts, ", ")
end

local function BuildOffMapLabel(entry)
    local parts = {}
    parts[#parts + 1] = entry.name
    parts[#parts + 1] = Locale.Lookup(GetSpyRankNameByLevel(entry.level))
    if entry.targetCityName then
        parts[#parts + 1] = Locale.Lookup("LOC_ESPIONAGEOVERVIEW_TRANSIT_TO", entry.targetCityName)
    end
    return table.concat(parts, ", ")
end

local function BuildOffMapTooltip(entry)
    local turnsRemaining = entry.returnTurn - Game.GetCurrentGameTurn()
    if turnsRemaining < 0 then turnsRemaining = 0 end
    return Locale.Lookup("LOC_CAI_ESPIONAGE_MISSION_TURNS", turnsRemaining)
end

local function BuildCapturedOwnLabel(entry)
    local parts = {}
    parts[#parts + 1] = entry.name
    parts[#parts + 1] = Locale.Lookup(GetSpyRankNameByLevel(entry.level))
    parts[#parts + 1] = Locale.Lookup("LOC_ESPIONAGEOVERVIEW_SPYCAUGHT")
    parts[#parts + 1] = entry.capturingPlayerName
    return table.concat(parts, ", ")
end

local function BuildCapturedOwnTooltip(entry)
    local parts = {}
    AppendIfNonEmpty(parts, entry.capturingCivName)
    if entry.tradeDisabled then
        AppendIfNonEmpty(parts, entry.disabledReason)
    else
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_ESPIONAGEOVERVIEW_ASK_FOR_TRADE"))
    end
    return JoinNonEmpty(parts, ", ")
end

local function BuildCapturedEnemyLabel(entry)
    local parts = {}
    parts[#parts + 1] = entry.name
    parts[#parts + 1] = entry.owningCivName
    return table.concat(parts, ", ")
end

local function BuildCapturedEnemyTooltip(entry)
    if entry.tradeDisabled and entry.disabledReason then
        return entry.disabledReason
    end
    return Locale.Lookup("LOC_ESPIONAGEOVERVIEW_OFFER_TRADE")
end

local function BuildMissionLabel(entry)
    local parts = {}
    parts[#parts + 1] = entry.name
    parts[#parts + 1] = Locale.Lookup(GetSpyRankNameByLevel(entry.levelAfter))
    if entry.operationInfo then
        parts[#parts + 1] = Locale.Lookup(entry.operationInfo.Description)
    end
    if entry.outcome then
        if entry.outcome.Success then
            parts[#parts + 1] = Locale.Lookup("LOC_ESPIONAGEOVERVIEW_SUCCESS")
        else
            parts[#parts + 1] = Locale.Lookup("LOC_ESPIONAGEOVERVIEW_FAILURE")
        end
    end
    parts[#parts + 1] = Locale.Lookup("LOC_ESPIONAGEOVERVIEW_TURNS_AGO", entry.turnsSince)
    return table.concat(parts, ", ")
end

local function BuildMissionTooltip(entry)
    local parts = {}
    if entry.outcome then
        AppendIfNonEmpty(parts, entry.outcome.Description)
        if entry.outcome.SpyStatus ~= "" then
            AppendIfNonEmpty(parts, entry.outcome.SpyStatus)
        end
    end
    return JoinNonEmpty(parts, ", ")
end

-- ============================================================================
-- City Category Helpers
-- ============================================================================

local function BuildCityKey(ownerID, cityID)
    return ownerID .. ":" .. cityID
end

local function GroupOperativesByCity()
    local cityGroups = {}
    local cityOrder = {}

    for _, entry in ipairs(m_cachedOperatives) do
        if entry.ownerCityID and entry.ownerCityOwnerID then
            local key = BuildCityKey(entry.ownerCityOwnerID, entry.ownerCityID)
            if not cityGroups[key] then
                cityGroups[key] = {
                    ownerID = entry.ownerCityOwnerID,
                    cityID = entry.ownerCityID,
                    city = entry.city,
                    entries = {},
                }
                cityOrder[#cityOrder + 1] = key
            end
            table.insert(cityGroups[key].entries, entry)
        end
    end

    return cityGroups, cityOrder
end

local function BuildCityCategoryLabel(group)
    local city = group.city
    if not city then return "?" end

    local parts = {}
    parts[#parts + 1] = Locale.Lookup(city:GetName())

    local ownerConfig = PlayerConfigurations[group.ownerID]
    if ownerConfig then
        parts[#parts + 1] = Locale.Lookup(ownerConfig:GetCivilizationShortDescription())
    end

    if city:IsCapital() and Players[group.ownerID]:IsMajor() then
        parts[#parts + 1] = Locale.Lookup("LOC_CAI_CITY_STATUS_CAPITAL")
    end

    local localDiplo = Players[Game.GetLocalPlayer()]:GetDiplomacy()
    if localDiplo then
        local boosted = localDiplo:GetSourceTurnsRemaining(city)
        if boosted > 0 then
            parts[#parts + 1] = Locale.Lookup("LOC_CAI_ESPIONAGE_SOURCES")
        end
    end

    local hasCounterspy = false
    for _, entry in ipairs(group.entries) do
        if entry.operationType ~= -1 and IsCounterspyOperation(entry.operationType) then
            hasCounterspy = true
            break
        end
    end
    if hasCounterspy then
        parts[#parts + 1] = Locale.Lookup("LOC_UNITOPERATION_SPY_COUNTERSPY_DESCRIPTION")
    end

    local count = #group.entries
    if count > 0 then
        parts[#parts + 1] = Locale.Lookup("LOC_CAI_ESPIONAGE_OPERATIVE_COUNT", count)
    end

    return table.concat(parts, ", ")
end

local function BuildCityCategoryTooltip(group)
    local city = group.city
    if not city then return "" end
    local parts = {}

    local localDiplo = Players[Game.GetLocalPlayer()]:GetDiplomacy()
    if localDiplo then
        local boosted = localDiplo:GetSourceTurnsRemaining(city)
        if boosted > 0 then
            parts[#parts + 1] = Locale.Lookup("LOC_CAI_ESPIONAGE_SOURCES_DETAIL", boosted)
        end
    end

    local spyDistricts = {}
    for _, entry in ipairs(group.entries) do
        if entry.operationType ~= -1 and entry.districtName then
            local operationName = ""
            if entry.operationInfo then
                operationName = Locale.Lookup(entry.operationInfo.Description)
            end
            spyDistricts[entry.districtName] = {
                spyName = entry.name,
                operation = operationName,
            }
        end
    end

    local districtsWithOps = {}
    local otherDistricts = {}
    local allDistricts = GetNonWonderDistricts(city)

    for _, dName in ipairs(allDistricts) do
        if spyDistricts[dName] then
            local info = spyDistricts[dName]
            districtsWithOps[#districtsWithOps + 1] = dName .. " (" .. info.spyName .. ", " .. info.operation .. ")"
        else
            otherDistricts[#otherDistricts + 1] = dName
        end
    end

    if #districtsWithOps > 0 then
        parts[#parts + 1] = Locale.Lookup("LOC_CAI_ESPIONAGE_DISTRICTS_WITH_OPERATIVES") ..
            " " .. table.concat(districtsWithOps, ", ")
    end

    if #otherDistricts > 0 then
        parts[#parts + 1] = Locale.Lookup("LOC_CAI_ESPIONAGE_OTHER_DISTRICTS") ..
            " " .. table.concat(otherDistricts, ", ")
    end

    return JoinNonEmpty(parts, ". ")
end

-- ============================================================================
-- View City Details
-- ============================================================================

local function HasEspionageView(ownerID, cityID)
    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == -1 then return false end
    local pLocalPlayer = Players[localPlayerID]
    if not pLocalPlayer then return false end
    local pDiplo = pLocalPlayer:GetDiplomacy()
    if not pDiplo then return false end
    local eVisibility = pDiplo:GetVisibilityOn(ownerID)
    local kVisDef = GameInfo.Visibilities_XP2[eVisibility]
    if kVisDef then
        if kVisDef.EspionageViewAll == true then return true end
        if kVisDef.EspionageViewCapital == true then
            local pOwner = Players[ownerID]
            if pOwner then
                local pCity = pOwner:GetCities():FindID(cityID)
                if pCity and pCity:IsCapital() then return true end
            end
        end
    end
    return false
end

local function GetFocusedCityName()
    if not m_focusedCityOwner or not m_focusedCityID then return nil end
    local pOwner = Players[m_focusedCityOwner]
    if not pOwner then return nil end
    local pCity = pOwner:GetCities():FindID(m_focusedCityID)
    if not pCity then return nil end
    return Locale.Lookup(pCity:GetName())
end

local function BuildViewCityButton()
    m_viewCityBtn = mgr:CreateWidget(VIEW_CITY_ID, "Button", {
        Label = function()
            local name = GetFocusedCityName()
            if name then
                return Locale.Lookup("LOC_CAI_ESPIONAGE_VIEW_CITY_DETAILS", name)
            end
            return ""
        end,
        Tooltip = function()
            if not m_focusedCityOwner or not m_focusedCityID then return end
            if m_focusedCityOwner == Game.GetLocalPlayer() then return end
            if not HasEspionageView(m_focusedCityOwner, m_focusedCityID) then
                return Locale.Lookup("LOC_ESPIONAGE_VIEW_DISABLED_TT")
            end
        end,
        HiddenPredicate = function()
            return not m_focusedCityOwner or not m_focusedCityID
        end,
        DisabledPredicate = function()
            if not m_focusedCityOwner or not m_focusedCityID then return true end
            if m_focusedCityOwner == Game.GetLocalPlayer() then return false end
            return not HasEspionageView(m_focusedCityOwner, m_focusedCityID)
        end,
    })
    m_viewCityBtn:SetFocusSound(HOVER_SOUND)
    m_viewCityBtn:On("activate", function()
        if not m_focusedCityOwner or not m_focusedCityID then return end
        LuaEvents.CAIOpenOverviewForEnemyCity(m_focusedCityOwner, m_focusedCityID)
    end)
end

local function OpenFocusedCityDetails()
    if not m_focusedCityOwner or not m_focusedCityID then return false end
    if m_focusedCityOwner ~= Game.GetLocalPlayer()
        and not HasEspionageView(m_focusedCityOwner, m_focusedCityID) then
        return false
    end
    LuaEvents.CAIOpenOverviewForEnemyCity(m_focusedCityOwner, m_focusedCityID)
    return true
end

local CITY_DETAILS_BINDING = {
    Key = Keys.VK_RETURN, IsControl = true,
    Action = function() return OpenFocusedCityDetails() end,
}

-- ============================================================================
-- Tree Population
-- ============================================================================

local function RebuildOperativesTree()
    if not m_opTree then return end
    local capture = mgr:CaptureFocusKey(m_opTree)
    m_opTree:ClearChildren()

    if #m_cachedOffMap > 0 then
        local travelCat = mgr:CreateWidget(mgr:GenerateWidgetId("CAIEspOv_TravelCat"), "TreeItem", {
            Label = function() return Locale.Lookup("LOC_CAI_ESPIONAGE_CATEGORY_TRAVELING") end,
            FocusKey = "cat:traveling",
        })
        travelCat:SetFocusSound(HOVER_SOUND)
        travelCat:On("focus_enter", function()
            m_focusedCityOwner = nil
            m_focusedCityID = nil
        end)

        for idx, entry in ipairs(m_cachedOffMap) do
            local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAIEspOv_OffMap"), "TreeItem", {
                Label = function() return BuildOffMapLabel(entry) end,
                Tooltip = function() return BuildOffMapTooltip(entry) end,
                FocusKey = "spy:offmap:" .. idx,
            })
            item:SetFocusSound(HOVER_SOUND)
            travelCat:AddChild(item)
        end

        m_opTree:AddChild(travelCat)
    end

    if #m_cachedCapturedOwn > 0 then
        local capCat = mgr:CreateWidget(mgr:GenerateWidgetId("CAIEspOv_CapCat"), "TreeItem", {
            Label = function() return Locale.Lookup("LOC_CAI_ESPIONAGE_CATEGORY_CAPTURED") end,
            FocusKey = "cat:captured",
        })
        capCat:SetFocusSound(HOVER_SOUND)
        capCat:On("focus_enter", function()
            m_focusedCityOwner = nil
            m_focusedCityID = nil
        end)

        for _, entry in ipairs(m_cachedCapturedOwn) do
            local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAIEspOv_CapOwn"), "TreeItem", {
                Label = function() return BuildCapturedOwnLabel(entry) end,
                Tooltip = function() return BuildCapturedOwnTooltip(entry) end,
                FocusKey = "spycap:" .. entry.nameIndex .. ":" .. entry.capturingPlayerID,
                DisabledPredicate = function() return entry.tradeDisabled end,
            })
            item:SetFocusSound(HOVER_SOUND)
            item:On("activate", function()
                if not entry.tradeDisabled then
                    OnAskForOperativeTradeClicked(entry.capturingPlayerID, entry.nameIndex)
                end
            end)
            capCat:AddChild(item)
        end

        m_opTree:AddChild(capCat)
    end

    local cityGroups, cityOrder = GroupOperativesByCity()
    for _, key in ipairs(cityOrder) do
        local group = cityGroups[key]
        local cityCat = mgr:CreateWidget(mgr:GenerateWidgetId("CAIEspOv_City"), "TreeItem", {
            Label = function() return BuildCityCategoryLabel(group) end,
            Tooltip = function() return BuildCityCategoryTooltip(group) end,
            FocusKey = "city:" .. key,
        })
        cityCat:SetFocusSound(HOVER_SOUND)
        cityCat:AddInputBinding(CITY_DETAILS_BINDING)
        cityCat:On("focus_enter", function()
            m_focusedCityOwner = group.ownerID
            m_focusedCityID = group.cityID
        end)
        cityCat:On("activate", function()
            LookAtCity(group.ownerID, group.cityID)
        end)

        for _, entry in ipairs(group.entries) do
            local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAIEspOv_Spy"), "TreeItem", {
                Label = function() return BuildSpyLabel(entry) end,
                Tooltip = function() return BuildSpyTooltip(entry) end,
                FocusKey = "spy:" .. entry.unitID,
            })
            item:SetFocusSound(HOVER_SOUND)
            item:AddInputBinding(CITY_DETAILS_BINDING)
            item:On("focus_enter", function()
                m_focusedCityOwner = group.ownerID
                m_focusedCityID = group.cityID
            end)
            cityCat:AddChild(item)
        end

        m_opTree:AddChild(cityCat)
    end

    mgr:RestoreFocus(m_opTree, capture)
end

local function RebuildMissionHistoryTree()
    if not m_mhTree then return end
    local capture = mgr:CaptureFocusKey(m_mhTree)
    m_mhTree:ClearChildren()

    if #m_cachedCapturedEnemy > 0 then
        local capCat = mgr:CreateWidget(mgr:GenerateWidgetId("CAIEspOv_EnemyCapCat"), "TreeItem", {
            Label = function() return Locale.Lookup("LOC_CAI_ESPIONAGE_CATEGORY_CAPTURED") end,
            FocusKey = "cat:captured_enemy",
        })
        capCat:SetFocusSound(HOVER_SOUND)

        for _, entry in ipairs(m_cachedCapturedEnemy) do
            local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAIEspOv_EnemyCap"), "TreeItem", {
                Label = function() return BuildCapturedEnemyLabel(entry) end,
                Tooltip = function() return BuildCapturedEnemyTooltip(entry) end,
                FocusKey = "enemycap:" .. entry.nameIndex .. ":" .. entry.owningPlayerID,
                DisabledPredicate = function() return entry.tradeDisabled end,
            })
            item:SetFocusSound(HOVER_SOUND)
            item:On("activate", function()
                if not entry.tradeDisabled then
                    OnAskForEnemyOperativeTradeClicked(entry.owningPlayerID, entry.nameIndex)
                end
            end)
            capCat:AddChild(item)
        end

        m_mhTree:AddChild(capCat)
    end

    if #m_cachedMissions > 0 then
        local mhCat = mgr:CreateWidget(mgr:GenerateWidgetId("CAIEspOv_MHCat"), "TreeItem", {
            Label = function() return Locale.Lookup("LOC_CAI_ESPIONAGE_TAB_MISSION_HISTORY") end,
            FocusKey = "cat:mission_history",
        })
        mhCat:SetFocusSound(HOVER_SOUND)

        for _, entry in ipairs(m_cachedMissions) do
            local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAIEspOv_Mission"), "TreeItem", {
                Label = function() return BuildMissionLabel(entry) end,
                Tooltip = function() return BuildMissionTooltip(entry) end,
                FocusKey = "mission:" .. entry.index,
            })
            item:SetFocusSound(HOVER_SOUND)
            mhCat:AddChild(item)
        end

        m_mhTree:AddChild(mhCat)
    end

    mgr:RestoreFocus(m_mhTree, capture)
end

-- ============================================================================
-- Panel Construction
-- ============================================================================

local function BuildPanel()
    m_panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function()
            local text = Controls.Title:GetText()
            if text and text ~= "" then return text end
            return Locale.Lookup("LOC_ESPIONAGE_TITLE")
        end,
    })

    m_tabs = mgr:CreateWidget(TABS_ID, "TabControl", {})

    local opPage = m_tabs:AddPage(function()
        local label = Locale.Lookup("LOC_CAI_ESPIONAGE_TAB_OPERATIVES")
        local localPlayer = Players[Game.GetLocalPlayer()]
        if localPlayer then
            local playerDiplomacy = localPlayer:GetDiplomacy()
            if playerDiplomacy then
                local count = #m_cachedOperatives + #m_cachedOffMap + #m_cachedCapturedOwn
                local capacity = playerDiplomacy:GetSpyCapacity()
                label = label .. ", " .. Locale.Lookup("LOC_CAI_ESPIONAGE_OPERATIVE_CAPACITY", count, capacity)
            end
        end
        return label
    end)
    m_opTree = mgr:CreateWidget(OP_TREE, "Tree", {})
    opPage:AddChild(m_opTree)

    if IsExpansion2Active() then
        BuildViewCityButton()
        opPage:AddChild(m_viewCityBtn)
    end

    local mhPage = m_tabs:AddPage(function()
        return Locale.Lookup("LOC_CAI_ESPIONAGE_TAB_MISSION_HISTORY")
    end)
    m_mhTree = mgr:CreateWidget(MH_TREE, "Tree", {})
    mhPage:AddChild(m_mhTree)

    m_panel:AddChild(m_tabs)

    m_panel:AddInputBindings({
        {
            Key = Keys.VK_ESCAPE,
            MSG = KeyEvents.KeyUp,
            Action = function()
                Close()
                return true
            end,
        },
    })

    m_tabs:On("value_changed", function(_, idx)
        if m_isMirroringTab then return end
        m_isMirroringTab = true
        if idx == TAB_OPERATIVES then
            Controls.OperativesTabButton:DoLeftClick()
        elseif idx == TAB_MISSION_HISTORY then
            Controls.MissionHistoryTabButton:DoLeftClick()
        end
        m_isMirroringTab = false
    end)
end

local function PushPanel()
    if not mgr then return end
    if not m_panel then BuildPanel() end
    if not mgr:GetWidgetById(PANEL_ID) then
        mgr:Push(m_panel, PopupPriority.Low)
    end
end

local function PopPanel()
    if mgr and m_panel and mgr:GetWidgetById(PANEL_ID) then
        mgr:RemoveFromStack(PANEL_ID)
    end
    m_panel = nil
    m_tabs = nil
    m_opTree = nil
    m_mhTree = nil
    m_viewCityBtn = nil
    m_focusedCityOwner = nil
    m_focusedCityID = nil
end

-- ============================================================================
-- Tab Sync (vanilla → CAI)
-- ============================================================================

OnSelectOperativesTab = WrapFunc(OnSelectOperativesTab, function(orig)
    orig()
    if m_tabs and not m_isMirroringTab then
        m_isMirroringTab = true
        m_tabs:SetActivePage(TAB_OPERATIVES, true)
        m_isMirroringTab = false
    end
end)

OnSelectMissionHistoryTab = WrapFunc(OnSelectMissionHistoryTab, function(orig)
    orig()
    if m_tabs and not m_isMirroringTab then
        m_isMirroringTab = true
        m_tabs:SetActivePage(TAB_MISSION_HISTORY, true)
        m_isMirroringTab = false
    end
end)

-- ============================================================================
-- Refresh Wraps
-- ============================================================================

RefreshOperatives = WrapFunc(RefreshOperatives, function(orig)
    m_cachedOperatives = {}
    m_cachedOffMap = {}
    m_cachedCapturedOwn = {}
    orig()
    if m_panel and not ContextPtr:IsHidden() then
        RebuildOperativesTree()
    end
end)

RefreshMissionHistory = WrapFunc(RefreshMissionHistory, function(orig)
    m_cachedCapturedEnemy = {}
    m_cachedMissions = {}
    orig()
    if m_panel and not ContextPtr:IsHidden() then
        RebuildMissionHistoryTree()
    end
end)

-- ============================================================================
-- Lifecycle Wraps
-- ============================================================================

Open = WrapFunc(Open, function(orig, forceTabIndex)
    if not m_panel then BuildPanel() end
    orig(forceTabIndex)
    if not ContextPtr:IsHidden() then
        PushPanel()
    end
end)

Close = WrapFunc(Close, function(orig)
    PopPanel()
    orig()
end)

OnShutdown = WrapFunc(OnShutdown, function(orig)
    PopPanel()
    orig()
end)
ContextPtr:SetShutdown(OnShutdown)

-- ============================================================================
-- Input Handler (replaces vanilla entirely)
-- ============================================================================

local function CAI_InputHandler(input)
    if mgr and mgr:GetWidgetById(PANEL_ID) then
        if mgr:HandleInput(input) then return true end
    end
    return false
end
ContextPtr:SetInputHandler(CAI_InputHandler, true)
