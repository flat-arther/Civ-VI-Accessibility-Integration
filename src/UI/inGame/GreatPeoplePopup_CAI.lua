-- GreatPeoplePopup_CAI.lua
--
-- Accessibility layer for the Great People popup.
--
-- GreatPeoplePopup.lua ends with include("GreatPeoplePopup_", true) — a wildcard
-- host that pulls in every loaded GreatPeoplePopup_* file, with Initialize()
-- called *after* it. So this file rides that wildcard (registered as an InGame
-- ImportFile, NOT a LuaReplace), must NOT include("GreatPeoplePopup"), and only
-- reassigns globals — vanilla's later Initialize() registers them as the context
-- handlers.

include("caiUtils")

local mgr                 = ExposedMembers.CAI_UIManager

-- ===========================================================================
-- Constants
-- ===========================================================================

local PANEL_ID            = "CAIGreatPeople_Panel"
local TABS_ID             = "CAIGreatPeople_Tabs"
local GP_TREE_ID          = "CAIGreatPeople_Tree"
local GP_BIO_ID           = "CAIGreatPeople_Bio"
local GP_RECRUIT_BTN_ID   = "CAIGreatPeople_RecruitBtn"
local GP_REJECT_BTN_ID    = "CAIGreatPeople_RejectBtn"
local GP_GOLD_BTN_ID      = "CAIGreatPeople_GoldBtn"
local GP_FAITH_BTN_ID     = "CAIGreatPeople_FaithBtn"
local PAST_LIST_ID        = "CAIGreatPeople_PastList"
local HEROES_LIST_ID      = "CAIGreatPeople_HeroesList"
local HERO_RECALL_BTN_ID  = "CAIGreatPeople_HeroRecallBtn"

local HOVER_SOUND         = "Main_Menu_Mouse_Over"

local m_hasBabylon        = false

-- ===========================================================================
-- State
-- ===========================================================================

local m_ui                = {
    panel         = nil,
    tabs          = nil,
    gpPage        = nil,
    gpTree        = nil,
    bioEdit       = nil,
    recruitBtn    = nil,
    rejectBtn     = nil,
    goldBtn       = nil,
    faithBtn      = nil,
    pastPage      = nil,
    pastList      = nil,
    heroPage      = nil,
    heroList      = nil,
    heroRecallBtn = nil,
}

local m_cachedPersons     = {}
local m_cachedData        = nil
local m_focusedPersonID   = nil
local m_focusedHero       = nil
local m_FocusRecruitable  = nil
local m_FocusHero         = nil
local m_isMirroringTab    = false
local m_vanillaTabButtons = {}
local m_vanillaTabCount   = 0

-- ===========================================================================
-- Control helpers
-- ===========================================================================

local function JoinNonEmpty(parts, sep)
    local out = {}
    for _, part in ipairs(parts) do
        if part and part ~= "" then out[#out + 1] = part end
    end
    return table.concat(out, sep)
end

-- ===========================================================================
-- Tab 1: Great People — label/tooltip helpers
-- ===========================================================================

local function FormatPersonLabel(kPerson)
    if not kPerson or not kPerson.IndividualID then
        local className = ""
        if kPerson and kPerson.ClassID then
            className = Locale.Lookup(GameInfo.GreatPersonClasses[kPerson.ClassID].Name)
        end
        return Locale.Lookup("LOC_CAI_GP_PERSON_LABEL", Locale.Lookup("LOC_GREAT_PEOPLE_NONE_AVAILABLE"), className)
            .. ", " .. Locale.Lookup("LOC_GREAT_PEOPLE_ALL_POSSIBLE_CHOSEN")
    end
    local name = kPerson.Name or ""
    local className = ""
    if kPerson.ClassID then
        className = Locale.Lookup(GameInfo.GreatPersonClasses[kPerson.ClassID].Name)
    end

    if kPerson.EarnConditions and kPerson.EarnConditions ~= "" then
        return Locale.Lookup("LOC_CAI_GP_PERSON_LABEL_EARN_BLOCKED", name, className, kPerson.EarnConditions)
    end

    if kPerson.CanRecruit then
        return Locale.Lookup("LOC_CAI_GP_PERSON_LABEL_RECRUITABLE", name, className)
    end

    return Locale.Lookup("LOC_CAI_GP_PERSON_LABEL", name, className)
end

local function FormatPersonTooltip(kPerson)
    if not kPerson or not kPerson.IndividualID then return "" end
    local parts = {}

    if kPerson.EraID then
        parts[#parts + 1] = Locale.Lookup(GameInfo.Eras[kPerson.EraID].Name)
    end

    if m_cachedData and kPerson.ClassID then
        local pointsByClass = m_cachedData.PointsByClass[kPerson.ClassID]
        if pointsByClass then
            local localPlayerID = Game.GetLocalPlayer()
            for _, kPlayerPoints in ipairs(pointsByClass) do
                if kPlayerPoints.PlayerID == localPlayerID then
                    parts[#parts + 1] = Locale.Lookup("LOC_CAI_GP_LOCAL_PROGRESS",
                        tostring(Round(kPlayerPoints.PointsTotal, 1)),
                        tostring(kPerson.RecruitCost),
                        tostring(Round(kPlayerPoints.PointsPerTurn, 1)))
                    break
                end
            end
        end
    end

    if kPerson.PassiveNameText and kPerson.PassiveNameText ~= "" then
        parts[#parts + 1] = kPerson.PassiveNameText .. ": " .. kPerson.PassiveEffectText
    end

    if kPerson.ActionNameText and kPerson.ActionNameText ~= "" then
        local actionText = kPerson.ActionNameText
        if kPerson.ActionCharges and kPerson.ActionCharges > 0 then
            actionText = actionText ..
                " (" .. Locale.Lookup("LOC_GREATPERSON_ACTION_CHARGES", kPerson.ActionCharges) .. ")"
        end
        if kPerson.ActionUsageText and kPerson.ActionUsageText ~= "" then
            actionText = actionText .. ", " .. kPerson.ActionUsageText
        end
        actionText = actionText .. ": " .. kPerson.ActionEffectText
        parts[#parts + 1] = actionText
    end

    if kPerson.EarnConditions and kPerson.EarnConditions ~= "" then
        parts[#parts + 1] = kPerson.EarnConditions
    end

    return JoinNonEmpty(parts, "[NEWLINE]")
end

local function FormatProgressLabel(kPlayerPoints, recruitCost)
    return Locale.Lookup("LOC_CAI_GP_CIV_PROGRESS",
        kPlayerPoints.PlayerName,
        tostring(Round(kPlayerPoints.PointsTotal, 1)),
        tostring(recruitCost),
        tostring(Round(kPlayerPoints.PointsPerTurn, 1)))
end

local function GetLocalProgressText(kPerson)
    if not kPerson or not kPerson.ClassID or not m_cachedData or not m_cachedData.PointsByClass then
        return ""
    end

    local pointsByClass = m_cachedData.PointsByClass[kPerson.ClassID]
    if not pointsByClass then return "" end

    local localPlayerID = Game.GetLocalPlayer()
    for _, kPlayerPoints in ipairs(pointsByClass) do
        if kPlayerPoints.PlayerID == localPlayerID then
            return FormatProgressLabel(kPlayerPoints, kPerson.RecruitCost)
        end
    end
    return ""
end

local function IsRecruitActionAvailable(kPerson)
    return kPerson
        and HasCapability("CAPABILITY_GREAT_PEOPLE_CAN_RECRUIT")
        and kPerson.CanRecruit
        and kPerson.RecruitCost
        and not IsReadOnly()
end

local function IsPassActionAvailable(kPerson)
    return kPerson
        and HasCapability("CAPABILITY_GREAT_PEOPLE_CAN_REJECT")
        and kPerson.CanReject
        and kPerson.RejectCost
        and not IsReadOnly()
end

local function GetBiographyText(kPerson)
    if not kPerson or not kPerson.BiographyTextTable then
        return Locale.Lookup("LOC_CAI_GP_NO_BIOGRAPHY")
    end
    local text = table.concat(kPerson.BiographyTextTable, "[NEWLINE][NEWLINE]")
    if text == "" then return Locale.Lookup("LOC_CAI_GP_NO_BIOGRAPHY") end
    return text
end

-- ===========================================================================
-- Tab 1: Build GP tree
-- ===========================================================================

local function UpdateBiographyAndButtons()
    local kPerson = m_cachedPersons[m_focusedPersonID]
    if m_ui.bioEdit then
        m_ui.bioEdit:SetText(GetBiographyText(kPerson), true)
    end
end

local function BuildGPTree()
    if not mgr or not m_ui.gpTree then return end
    local capture = mgr:CaptureFocusKey(m_ui.gpTree)
    m_ui.gpTree:ClearChildren()

    if not m_cachedData or not m_cachedData.Timeline then
        mgr:RestoreFocus(m_ui.gpTree, capture)
        return
    end

    local firstRecruitableKey = nil
    for _, kPerson in ipairs(m_cachedData.Timeline) do
        local personID = kPerson.IndividualID
        local item = mgr:CreateWidget(
            mgr:GenerateWidgetId("CAIGP_Person"), "TreeItem", {
                Label    = function() return FormatPersonLabel(kPerson) end,
                Tooltip  = function() return FormatPersonTooltip(kPerson) end,
                FocusKey = personID and ("gp:" .. tostring(personID)) or nil,
            })
        item:SetFocusSound(HOVER_SOUND)

        if personID then
            if not firstRecruitableKey and kPerson.CanRecruit then
                firstRecruitableKey = "gp:" .. tostring(personID)
            end

            item:On("focus_enter", function()
                m_focusedPersonID = personID
                UpdateBiographyAndButtons()
            end)

            item:On("activate", function()
                if IsRecruitActionAvailable(kPerson) then
                    OnRecruitButtonClick(personID)
                else
                    local progressText = GetLocalProgressText(kPerson)
                    if progressText ~= "" then Speak(progressText) end
                end
            end)

            item:AddInputBindings({
                {
                    Key = Keys.VK_DELETE,
                    MSG = KeyEvents.KeyUp,
                    Description = "LOC_GREAT_PEOPLE_PASS",
                    Action = function()
                        if IsPassActionAvailable(kPerson) then
                            OnRejectButtonClick(personID)
                        end
                        return true
                    end,
                },
            })

            if m_cachedData.PointsByClass and kPerson.ClassID then
                local pointsByClass = m_cachedData.PointsByClass[kPerson.ClassID]
                if pointsByClass then
                    local recruitTable = {}
                    for _, kPlayerPoints in ipairs(pointsByClass) do
                        table.insert(recruitTable, kPlayerPoints)
                    end
                    table.sort(recruitTable, function(a, b)
                        if a.PointsTotal == b.PointsTotal then
                            return a.PlayerID < b.PlayerID
                        end
                        return a.PointsTotal > b.PointsTotal
                    end)

                    for _, kPlayerPoints in ipairs(recruitTable) do
                        local leaf = mgr:CreateWidget(
                            mgr:GenerateWidgetId("CAIGP_Progress"), "TreeItem", {
                                Label = function()
                                    return FormatProgressLabel(kPlayerPoints, kPerson.RecruitCost)
                                end,
                                FocusKey = "gpprog:" .. tostring(personID) .. ":" .. tostring(kPlayerPoints.PlayerID),
                            })
                        leaf:SetFocusSound(HOVER_SOUND)
                        item:AddChild(leaf)
                    end
                end
            end
        end

        m_ui.gpTree:AddChild(item)
    end

    if firstRecruitableKey then
        m_FocusRecruitable = firstRecruitableKey
    end
    mgr:RestoreFocus(m_ui.gpTree, capture)
end

-- ===========================================================================
-- Tab 2: Previously Recruited table
-- ===========================================================================

local function FormatPastRecruiter(kPerson)
    local localPlayerID = Game.GetLocalPlayer()
    if kPerson.ClaimantID == nil then return "" end
    if kPerson.ClaimantID == localPlayerID then
        return Locale.Lookup("LOC_GREAT_PEOPLE_RECRUITED_BY_YOU")
    end

    local localPlayer = Players[localPlayerID]
    if Game.GetLocalObserver() == PlayerTypes.OBSERVER
        or (localPlayer and localPlayer:GetDiplomacy() and localPlayer:GetDiplomacy():HasMet(kPerson.ClaimantID)) then
        local config = PlayerConfigurations[kPerson.ClaimantID]
        if config then return Locale.Lookup(config:GetPlayerName()) end
    end

    return Locale.Lookup("LOC_GREAT_PEOPLE_RECRUITED_BY_UNKNOWN")
end

local function FormatPastAbilities(kPerson)
    local parts = {}
    if kPerson.PassiveNameText and kPerson.PassiveNameText ~= "" then
        parts[#parts + 1] = kPerson.PassiveNameText .. ": " .. kPerson.PassiveEffectText
    end
    if kPerson.ActionNameText and kPerson.ActionNameText ~= "" then
        local actionText = kPerson.ActionNameText
        if kPerson.ActionCharges and kPerson.ActionCharges > 0 then
            actionText = actionText ..
                " (" .. Locale.Lookup("LOC_GREATPERSON_ACTION_CHARGES", kPerson.ActionCharges) .. ")"
        end
        if kPerson.ActionUsageText and kPerson.ActionUsageText ~= "" then
            actionText = actionText .. ", " .. kPerson.ActionUsageText
        end
        actionText = actionText .. ": " .. kPerson.ActionEffectText
        parts[#parts + 1] = actionText
    end
    return JoinNonEmpty(parts, "[NEWLINE]")
end

local function BuildPastList(data)
    if not mgr or not m_ui.pastList then return end
    local capture = mgr:CaptureFocusKey(m_ui.pastList)
    m_ui.pastList:ClearChildren()

    if not data or not data.Timeline then
        mgr:RestoreFocus(m_ui.pastList, capture)
        return
    end

    for _, kPerson in ipairs(data.Timeline) do
        local parts = {}

        if kPerson.TurnGranted then
            parts[#parts + 1] = Calendar.MakeYearStr(kPerson.TurnGranted)
        end

        if kPerson.ClassID then
            parts[#parts + 1] = Locale.Lookup(GameInfo.GreatPersonClasses[kPerson.ClassID].Name)
        end

        if kPerson.Name and kPerson.Name ~= "" then
            parts[#parts + 1] = kPerson.Name
        end

        local recruiter = FormatPastRecruiter(kPerson)
        if recruiter ~= "" then
            parts[#parts + 1] = recruiter
        end

        local abilities = FormatPastAbilities(kPerson)
        if abilities ~= "" then
            parts[#parts + 1] = abilities
        end

        local label = table.concat(parts, ", ")
        local focusKey = kPerson.IndividualID and ("past:" .. tostring(kPerson.IndividualID)) or nil
        local row = mgr:CreateWidget(mgr:GenerateWidgetId("CAIGP_PastRow"), "StaticText", {
            Label = function() return label end,
            FocusKey = focusKey,
        })
        row:SetFocusSound(HOVER_SOUND)
        m_ui.pastList:AddChild(row)
    end

    mgr:RestoreFocus(m_ui.pastList, capture)
end

-- ===========================================================================
-- Tab 3: Heroes (Babylon DLC)
-- ===========================================================================

local function GetHeroData(pGameHeroes, kHeroDef)
    local localPlayerID = Game.GetLocalPlayer()
    local claimedByPlayer = pGameHeroes:GetHeroClaimPlayer(kHeroDef.Index)

    local data = {
        heroDef         = kHeroDef,
        claimedByPlayer = claimedByPlayer,
        isAlive         = false,
        heroUnit        = nil,
        heroCity        = nil,
        recallInfo      = nil,
    }

    if claimedByPlayer ~= -1 then
        local pPlayer = Players[claimedByPlayer]
        if pPlayer then
            local pPlayerUnits = pPlayer:GetUnits()
            for _, pUnit in pPlayerUnits:Members() do
                if GameInfo.Units[pUnit:GetType()].UnitType == kHeroDef.UnitType then
                    data.isAlive = true
                    data.heroUnit = pUnit
                end
            end
        end
        if claimedByPlayer == localPlayerID and not data.heroUnit then
            local kCityID = pGameHeroes:GetHeroOriginCityID(kHeroDef.Index)
            local pPlayerCities = Players[claimedByPlayer]:GetCities()
            data.heroCity = pPlayerCities:FindID(kCityID.id)

            if not data.isAlive and data.heroCity then
                local kHeroUnitDef = GameInfo.Units[kHeroDef.UnitType]
                local kYieldDef = GameInfo.Yields["YIELD_FAITH"]
                local tParameters = {}
                tParameters[CityCommandTypes.PARAM_UNIT_TYPE] = kHeroUnitDef.Hash
                tParameters[CityCommandTypes.PARAM_YIELD_TYPE] = kYieldDef.Index
                if CityManager.CanStartCommand(data.heroCity, CityCommandTypes.PURCHASE, true, tParameters, false) then
                    local isCanStart, results = CityManager.CanStartCommand(data.heroCity, CityCommandTypes.PURCHASE,
                        false, tParameters, true)
                    local pCityGold = data.heroCity:GetGold()
                    local faithCost = pCityGold:GetPurchaseCost(kYieldDef.Index, kHeroUnitDef.Hash,
                        MilitaryFormationTypes.STANDARD_MILITARY_FORMATION)
                    local sToolTip = Locale.Lookup("LOC_GREAT_PEOPLE_HEROES_FAITH_RECALL_TT", faithCost)
                    if not isCanStart and results and results[CityCommandResults.FAILURE_REASONS] then
                        for _, v in ipairs(results[CityCommandResults.FAILURE_REASONS]) do
                            sToolTip = sToolTip .. ", " .. Locale.Lookup(v)
                        end
                        local pPlayerReligion = Players[data.heroCity:GetOwner()]:GetReligion()
                        if pPlayerReligion and not pPlayerReligion:CanAfford(data.heroCity:GetID(), kHeroUnitDef.Hash) then
                            sToolTip = sToolTip .. ", " .. Locale.Lookup("LOC_GREAT_PEOPLE_HEROES_INSUFFICIENT_FAITH_TT")
                        end
                    end
                    data.recallInfo = {
                        faithCost = faithCost,
                        canRecall = isCanStart,
                        tooltip   = sToolTip,
                        heroClass = kHeroDef.Index,
                    }
                end
            end
        end
    end

    return data
end

local function FormatHeroLabel(pGameHeroes, kHeroDef)
    local heroName = Locale.ToUpper(kHeroDef.Name)
    local claimedByPlayer = pGameHeroes:GetHeroClaimPlayer(kHeroDef.Index)

    if claimedByPlayer == -1 then
        return Locale.Lookup("LOC_CAI_GP_HERO_LABEL_DISCOVERED", heroName)
    end

    local civName
    local localPlayerID = Game.GetLocalPlayer()
    if claimedByPlayer == localPlayerID then
        civName = Locale.Lookup("LOC_GREAT_PEOPLE_RECRUITED_BY_YOU")
    else
        local localPlayer = Players[localPlayerID]
        if Game.GetLocalObserver() == PlayerTypes.OBSERVER
            or (localPlayer and localPlayer:GetDiplomacy() and localPlayer:GetDiplomacy():HasMet(claimedByPlayer)) then
            local config = PlayerConfigurations[claimedByPlayer]
            civName = config and Locale.Lookup(config:GetPlayerName()) or
                Locale.Lookup("LOC_GREAT_PEOPLE_RECRUITED_BY_UNKNOWN")
        else
            civName = Locale.Lookup("LOC_GREAT_PEOPLE_RECRUITED_BY_UNKNOWN")
        end
    end

    local bIsAlive = false
    local pPlayer = Players[claimedByPlayer]
    if pPlayer then
        for _, pUnit in pPlayer:GetUnits():Members() do
            if GameInfo.Units[pUnit:GetType()].UnitType == kHeroDef.UnitType then
                bIsAlive = true
            end
        end
    end

    if bIsAlive then
        return Locale.Lookup("LOC_CAI_GP_HERO_LABEL_RECRUITED", heroName, civName)
    else
        return Locale.Lookup("LOC_CAI_GP_HERO_LABEL_DECEASED", heroName, civName)
    end
end

local function FormatHeroTooltip(kHeroDef)
    local parts = {}

    local kStats = GetHeroUnitStats(kHeroDef.Index)
    local statParts = {}
    if kStats.Lifespan then
        statParts[#statParts + 1] = Locale.Lookup("LOC_HUD_UNIT_PANEL_LIFESPAN") .. ": " .. tostring(kStats.Lifespan)
    end
    if kStats.BaseMoves and kStats.BaseMoves > 0 then
        statParts[#statParts + 1] = Locale.Lookup("LOC_HUD_UNIT_PANEL_MOVEMENT") .. ": " .. tostring(kStats.BaseMoves)
    end
    if kStats.Combat and kStats.Combat > 0 then
        statParts[#statParts + 1] = Locale.Lookup("LOC_HUD_UNIT_PANEL_STRENGTH") .. ": " .. tostring(kStats.Combat)
    end
    if kStats.RangedCombat and kStats.RangedCombat > 0 then
        statParts[#statParts + 1] = Locale.Lookup("LOC_HUD_UNIT_PANEL_RANGED_STRENGTH") ..
            ": " .. tostring(kStats.RangedCombat)
    end
    if kStats.Range and kStats.Range > 0 then
        statParts[#statParts + 1] = Locale.Lookup("LOC_HUD_UNIT_PANEL_ATTACK_RANGE") .. ": " .. tostring(kStats.Range)
    end
    if kStats.Charges and kStats.Charges > 0 then
        statParts[#statParts + 1] = Locale.Lookup("LOC_HUD_UNIT_PANEL_CHARGES") .. ": " .. tostring(kStats.Charges)
    end
    if #statParts > 0 then
        parts[#parts + 1] = JoinNonEmpty(statParts, "[NEWLINE]")
    end

    local kAbilities = GetHeroClassUnitAbilities(kHeroDef.Index)
    if #kAbilities > 0 then
        table.insert(parts, Locale.Lookup("LOC_CAI_GP_HEROES_PASSIVES"))
        for _, kAbility in ipairs(kAbilities) do
            local t = Locale.Lookup(kAbility.Name)
            if kAbility.Description and kAbility.Description ~= "" then
                t = t .. ": " .. Locale.Lookup(kAbility.Description)
            end
            parts[#parts + 1] = t
        end
    end

    local kCommands = GetHeroClassUnitCommands(kHeroDef.Index)
    if #kCommands > 0 then
        table.insert(parts, Locale.Lookup("LOC_CAI_GP_HEROES_COMMANDS"))
        for _, kCommand in ipairs(kCommands) do
            local t = Locale.Lookup(kCommand.Name)
            if kCommand.Description and kCommand.Description ~= "" then
                t = t .. ": " .. kCommand.Description
            end
            parts[#parts + 1] = t
        end
    end

    return JoinNonEmpty(parts, "[NEWLINE]")
end

local function GetFocusedHero()
    return m_focusedHero
end

local function BuildHeroesList()
    if not mgr or not m_ui.heroList then return end
    local pGameHeroes = Game.GetHeroesManager()
    if not pGameHeroes then return end

    local capture = mgr:CaptureFocusKey(m_ui.heroList)
    m_ui.heroList:ClearChildren()

    local localPlayerID = Game.GetLocalPlayer()

    for row in GameInfo.HeroClasses() do
        if pGameHeroes:IsHeroDiscovered(localPlayerID, row.Index) then
            local heroRow = row
            local item = mgr:CreateWidget(
                mgr:GenerateWidgetId("CAIGP_Hero"), "MenuItem", {
                    Label = function() return FormatHeroLabel(pGameHeroes, heroRow) end,
                    Tooltip = function() return FormatHeroTooltip(heroRow) end,
                    FocusKey = "hero:" .. heroRow.HeroClassType,
                })
            item:SetFocusSound(HOVER_SOUND)
            item:On("focus_enter", function()
                m_focusedHero = GetHeroData(pGameHeroes, heroRow)
            end)
            item:On("activate", function()
                local h = GetHeroData(pGameHeroes, heroRow)
                if not h or h.claimedByPlayer ~= Game.GetLocalPlayer() then return end
                if h.heroUnit then
                    LuaEvents.GreatPeopleHeroPanel_Close()
                    UI.LookAtPlotScreenPosition(h.heroUnit:GetX(), h.heroUnit:GetY(), 0.5, 0.5)
                    UI.SelectUnit(h.heroUnit)
                elseif h.heroCity then
                    LuaEvents.GreatPeopleHeroPanel_Close()
                    UI.LookAtPlotScreenPosition(h.heroCity:GetX(), h.heroCity:GetY(), 0.5, 0.5)
                    UI.SelectCity(h.heroCity)
                end
            end)
            if GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_CIVPEDIA") then
                item:AddInputBindings({
                    {
                        Key = Keys.VK_RETURN,
                        MSG = KeyEvents.KeyUp,
                        IsShift = true,
                        Description = "LOC_CAI_KB_OPEN_CIVILOPEDIA",
                        Action = function()
                            LuaEvents.GreatPeopleHeroPanel_Close()
                            LuaEvents.OpenCivilopedia(heroRow.UnitType)
                            return true
                        end
                    },
                })
            end
            m_ui.heroList:AddChild(item)
        end
    end

    mgr:RestoreFocus(m_ui.heroList, capture)
end

-- ===========================================================================
-- Panel builder
-- ===========================================================================

local function GetFocusedPerson()
    return m_cachedPersons[m_focusedPersonID]
end

local function BuildPanel()
    if not mgr then return end

    m_ui.panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function() return Locale.Lookup("LOC_GREAT_PEOPLE_TITLE") end,
    })

    m_ui.tabs = mgr:CreateWidget(TABS_ID, "TabControl", {})

    -- Tab 1: Great People
    m_ui.gpPage = m_ui.tabs:AddPage(function()
        return Locale.Lookup("LOC_GREAT_PEOPLE_TAB_GREAT_PEOPLE")
    end)

    m_ui.gpTree = mgr:CreateWidget(GP_TREE_ID, "Tree")
    m_ui.gpPage:AddChild(m_ui.gpTree)

    m_ui.bioEdit = mgr:CreateWidget(GP_BIO_ID, "EditBox", {
        Label = function() return Locale.Lookup("LOC_GREAT_PEOPLE_BIOGRAPHY") end,
    })
    m_ui.bioEdit:SetReadOnly(true)
    m_ui.bioEdit:SetAlwaysEdit(true)
    m_ui.bioEdit:SetFocusSound(HOVER_SOUND)

    -- Action buttons — call vanilla global callbacks directly with individualID
    m_ui.recruitBtn = mgr:CreateWidget(GP_RECRUIT_BTN_ID, "Button", {
        Label = function()
            local p = GetFocusedPerson()
            if p and p.RecruitCost then
                return Locale.Lookup("LOC_CAI_GP_RECRUIT_LABEL", p.RecruitCost)
            end
            return Locale.Lookup("LOC_GREAT_PEOPLE_RECRUIT")
        end,
        Tooltip = function()
            return Locale.Lookup("LOC_GREAT_PEOPLE_RECRUIT_DETAILS", (GetFocusedPerson() or {}).RecruitCost or 0)
        end,
        HiddenPredicate = function()
            local p = GetFocusedPerson()
            if not p then return true end
            return not (HasCapability("CAPABILITY_GREAT_PEOPLE_CAN_RECRUIT") and p.CanRecruit and p.RecruitCost)
        end,
        DisabledPredicate = function() return IsReadOnly() end,
    })
    m_ui.recruitBtn:SetFocusSound(HOVER_SOUND)
    m_ui.recruitBtn:On("activate", function()
        if m_focusedPersonID then OnRecruitButtonClick(m_focusedPersonID) end
    end)
    m_ui.gpPage:AddChild(m_ui.recruitBtn)

    m_ui.rejectBtn = mgr:CreateWidget(GP_REJECT_BTN_ID, "Button", {
        Label = function()
            local p = GetFocusedPerson()
            if p and p.RejectCost then
                return Locale.Lookup("LOC_CAI_GP_REJECT_LABEL", p.RejectCost)
            end
            return Locale.Lookup("LOC_GREAT_PEOPLE_PASS")
        end,
        Tooltip = function()
            return Locale.Lookup("LOC_GREAT_PEOPLE_PASS_DETAILS", (GetFocusedPerson() or {}).RejectCost or 0)
        end,
        HiddenPredicate = function()
            local p = GetFocusedPerson()
            if not p then return true end
            return not (HasCapability("CAPABILITY_GREAT_PEOPLE_CAN_REJECT") and p.CanReject and p.RejectCost)
        end,
        DisabledPredicate = function() return IsReadOnly() end,
    })
    m_ui.rejectBtn:SetFocusSound(HOVER_SOUND)
    m_ui.rejectBtn:On("activate", function()
        if m_focusedPersonID then OnRejectButtonClick(m_focusedPersonID) end
    end)
    m_ui.gpPage:AddChild(m_ui.rejectBtn)

    m_ui.goldBtn = mgr:CreateWidget(GP_GOLD_BTN_ID, "Button", {
        Label = function()
            local p = GetFocusedPerson()
            if p and p.PatronizeWithGoldCost then
                return Locale.Lookup("LOC_CAI_GP_PATRONIZE_GOLD_LABEL", p.PatronizeWithGoldCost)
            end
            return ""
        end,
        Tooltip = function()
            local p = GetFocusedPerson()
            if not p then return "" end
            return GetPatronizeWithGoldTT(p)
        end,
        HiddenPredicate = function()
            local p = GetFocusedPerson()
            if not p then return true end
            if not HasCapability("CAPABILITY_GREAT_PEOPLE_RECRUIT_WITH_GOLD") then return true end
            if p.CanRecruit or p.CanReject then return true end
            return not (p.PatronizeWithGoldCost and p.PatronizeWithGoldCost < 1000000)
        end,
        DisabledPredicate = function()
            local p = GetFocusedPerson()
            if not p then return true end
            return (not p.CanPatronizeWithGold) or IsReadOnly()
        end,
    })
    m_ui.goldBtn:SetFocusSound(HOVER_SOUND)
    m_ui.goldBtn:On("activate", function()
        if m_focusedPersonID then OnGoldButtonClick(m_focusedPersonID) end
    end)
    m_ui.gpPage:AddChild(m_ui.goldBtn)

    m_ui.faithBtn = mgr:CreateWidget(GP_FAITH_BTN_ID, "Button", {
        Label = function()
            local p = GetFocusedPerson()
            if p and p.PatronizeWithFaithCost then
                return Locale.Lookup("LOC_CAI_GP_PATRONIZE_FAITH_LABEL", p.PatronizeWithFaithCost)
            end
            return ""
        end,
        Tooltip = function()
            local p = GetFocusedPerson()
            if not p then return "" end
            return GetPatronizeWithFaithTT(p)
        end,
        HiddenPredicate = function()
            local p = GetFocusedPerson()
            if not p then return true end
            if not HasCapability("CAPABILITY_GREAT_PEOPLE_RECRUIT_WITH_FAITH") then return true end
            if p.CanRecruit or p.CanReject then return true end
            return not (p.PatronizeWithFaithCost and p.PatronizeWithFaithCost < 1000000)
        end,
        DisabledPredicate = function()
            local p = GetFocusedPerson()
            if not p then return true end
            return (not p.CanPatronizeWithFaith) or IsReadOnly()
        end,
    })
    m_ui.faithBtn:SetFocusSound(HOVER_SOUND)
    m_ui.faithBtn:On("activate", function()
        if m_focusedPersonID then OnFaithButtonClick(m_focusedPersonID) end
    end)
    m_ui.gpPage:AddChild(m_ui.faithBtn)

    -- Keep biography after all contextual actions in the tab order.
    m_ui.gpPage:AddChild(m_ui.bioEdit)

    -- Tab 2: Previously Recruited
    m_ui.pastPage = m_ui.tabs:AddPage(function()
        return Locale.Lookup("LOC_GREAT_PEOPLE_TAB_PREVIOUSLY_RECRUITED")
    end)

    m_ui.pastList = mgr:CreateWidget(PAST_LIST_ID, "List", {
        Label = function() return Locale.Lookup("LOC_GREAT_PEOPLE_RECRUITMENT_HISTORY") end,
    })
    m_ui.pastPage:AddChild(m_ui.pastList)

    -- Tab 3: Heroes (Babylon DLC)
    if m_hasBabylon then
        m_ui.heroPage = m_ui.tabs:AddPage(function()
            return Locale.Lookup("LOC_GREAT_PEOPLE_TAB_HEROES")
        end)

        m_ui.heroList = mgr:CreateWidget(HEROES_LIST_ID, "List", {
            Label = function() return Locale.Lookup("LOC_CAI_GP_HEROES_LIST") end,
        })
        m_ui.heroPage:AddChild(m_ui.heroList)

        m_ui.heroRecallBtn = mgr:CreateWidget(HERO_RECALL_BTN_ID, "Button", {
            Label = function()
                local h = GetFocusedHero()
                if not h or not h.recallInfo then return "" end
                return Locale.Lookup("LOC_CAI_GP_RECALL_WITH_FAITH_LABEL", h.recallInfo.faithCost)
            end,
            Tooltip = function()
                local h = GetFocusedHero()
                if not h or not h.recallInfo then return "" end
                return h.recallInfo.tooltip
            end,
            HiddenPredicate = function()
                local h = GetFocusedHero()
                if not h then return true end
                if h.claimedByPlayer ~= Game.GetLocalPlayer() then return true end
                return h.isAlive or not h.recallInfo
            end,
            DisabledPredicate = function()
                local h = GetFocusedHero()
                if not h or not h.recallInfo then return true end
                return not h.recallInfo.canRecall
            end,
        })
        m_ui.heroRecallBtn:SetFocusSound(HOVER_SOUND)
        m_ui.heroRecallBtn:On("activate", function()
            local h = GetFocusedHero()
            if h and h.recallInfo then RecallHero(h.recallInfo.heroClass) end
        end)
        m_ui.heroPage:AddChild(m_ui.heroRecallBtn)
    end

    m_ui.tabs:On("value_changed", function(_, idx)
        if m_isMirroringTab then return end
        local btn = m_vanillaTabButtons[idx]
        if btn then
            m_isMirroringTab = true
            btn:DoLeftClick()
            m_isMirroringTab = false
        end
    end)

    m_ui.panel:AddChild(m_ui.tabs)
end

-- ===========================================================================
-- Lifecycle helpers
-- ===========================================================================

local function PushPanel()
    if not mgr then return end
    if not m_ui.panel then BuildPanel() end
    if not m_ui.panel then return end
    if not mgr:GetWidgetById(PANEL_ID) then
        mgr:Push(m_ui.panel, { priority = PopupPriority.Low, focus = m_FocusHero or m_FocusRecruitable })
    end
end

local function PopPanel()
    if mgr and m_ui.panel then
        mgr:RemoveFromStack(PANEL_ID)
    end
    m_ui = {
        panel = nil,
        tabs = nil,
        gpPage = nil,
        gpTree = nil,
        bioEdit = nil,
        recruitBtn = nil,
        rejectBtn = nil,
        goldBtn = nil,
        faithBtn = nil,
        pastPage = nil,
        pastList = nil,
        heroPage = nil,
        heroList = nil,
        heroRecallBtn = nil,
    }
    m_cachedPersons = {}
    m_cachedData = nil
    m_focusedPersonID = nil
    m_focusedHero = nil
    m_FocusRecruitable = nil
    m_isMirroringTab = false
end

-- ===========================================================================
-- Vanilla function wraps
-- ===========================================================================

AddRecruit = WrapFunc(AddRecruit, function(orig, kData, kPerson)
    orig(kData, kPerson)
    if kPerson and kPerson.IndividualID then
        m_cachedPersons[kPerson.IndividualID] = kPerson
    end
end)

local function SyncCAITab(idx)
    if m_ui.tabs and not m_isMirroringTab then
        m_isMirroringTab = true
        m_ui.tabs:SetActivePage(idx, true)
        m_isMirroringTab = false
    end
end

ViewCurrent = WrapFunc(ViewCurrent, function(orig, data)
    m_cachedPersons = {}
    m_cachedData = nil
    orig(data)
    m_cachedData = data
    BuildGPTree()
    SyncCAITab(1)
end)

ViewPast = WrapFunc(ViewPast, function(orig, data)
    orig(data)
    BuildPastList(data)
    SyncCAITab(2)
end)

Open = WrapFunc(Open, function(orig)
    if not m_ui.panel then BuildPanel() end
    orig()
    if not ContextPtr:IsHidden() then
        PushPanel()
    end
end)

Close = WrapFunc(Close, function(orig)
    orig()
    if ContextPtr:IsHidden() then
        PopPanel()
    end
end)

AddTabInstance = WrapFunc(AddTabInstance, function(orig, buttonText, callbackFunc)
    local kInstance = orig(buttonText, callbackFunc)
    m_vanillaTabCount = m_vanillaTabCount + 1
    m_vanillaTabButtons[m_vanillaTabCount] = kInstance.Button
    return kInstance
end)

-- Babylon-specific wraps are deferred to LateInitialize because the Babylon
-- override files may load after this CAI file in the wildcard batch; by the time
-- LateInitialize runs (called from Initialize()), all wildcard files have loaded.
local BASE_CAI_LateInitialize = LateInitialize
function LateInitialize()
    if BASE_CAI_LateInitialize then BASE_CAI_LateInitialize() end

    m_hasBabylon = (OnHeroesClick ~= nil) and (Game.GetHeroesManager ~= nil)

    if m_hasBabylon then
        include("HeroesSupport")

        RefreshHeroesPanel = WrapFunc(RefreshHeroesPanel, function(orig)
            orig()
            BuildHeroesList()
            SyncCAITab(3)
        end)
    end
end

function OnCAI_UpdateHeroPanelOpenFocus(key)
    if key then m_FocusHero = key end
end

LuaEvents.CAI_UpdateHeroPanelOpenFocus.Add(OnCAI_UpdateHeroPanelOpenFocus)

function OnCAI_ClearHeroPanelOpenFocus()
    m_FocusHero = nil
end

LuaEvents.CAI_ClearHeroPanelOpenFocus.Add(OnCAI_ClearHeroPanelOpenFocus)

-- Vanilla Initialize() calls ContextPtr:SetInputHandler(OnInputHandler, true) after
-- all wildcard includes, so reassigning the global here is enough.
OnInputHandler = WrapFunc(OnInputHandler, function(orig, input)
    if mgr then
        local top = mgr:GetTop()
        if top == m_ui.panel then
            if mgr:HandleInput(input) then return true end
        end
    end
    return orig(input)
end)

OnShutdown = WrapFunc(OnShutdown, function(orig)
    PopPanel()
    orig()
    LuaEvents.CAI_ClearHeroPanelOpenFocus.Remove(OnCAI_ClearHeroPanelOpenFocus)
    LuaEvents.CAI_UpdateHeroPanelOpenFocus.Remove(OnCAI_UpdateHeroPanelOpenFocus)
end)
