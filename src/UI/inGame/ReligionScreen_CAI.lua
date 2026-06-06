include("caiUtils")
include("ReligionScreen")

local mgr = ExposedMembers.CAI_UIManager

local PANEL_ID         = "CAIReligion_Panel"
local TREE_ID          = "CAIReligion_Tree"
local SETUP_PANEL_ID   = "CAIReligion_SetupPanel"

local m_ui = {
    panel       = nil,
    tree        = nil,
    setupPanel  = nil,
    nameEdit    = nil,
    beliefList  = nil,
    dialog      = nil,
}

local m_selectedReligionType = -1
local m_selectedIsMyReligion = false

local HOVER_SOUND = "Main_Menu_Mouse_Over"

local CAI_CITIES_FILTER = { FOLLOWING_RELIGION = 1, RELIGION_PRESENT = 2 }
local cai_citiesFilter = CAI_CITIES_FILTER.FOLLOWING_RELIGION

local CAI_UNIT_TOOLTIPS = {
    ["UNIT_MISSIONARY"]  = { canProduce = "LOC_UI_RELIGION_MISSIONARY_TT", cannotProduce = "LOC_UI_RELIGION_HOW_TO_MAKE_MISSIONARY_TT" },
    ["UNIT_APOSTLE"]     = { canProduce = "LOC_UI_RELIGION_APOSTLE_TT", cannotProduce = "LOC_UI_RELIGION_HOW_TO_MAKE_APOSTLE_TT" },
    ["UNIT_INQUISITOR"]  = { canProduce = "LOC_UI_RELIGION_INQUISITOR_TT", cannotProduce = "LOC_UI_RELIGION_HOW_TO_MAKE_INQUISITOR_TT" },
    ["UNIT_GURU"]        = { canProduce = "LOC_UI_RELIGION_GURU_TT", cannotProduce = "LOC_UI_RELIGION_HOW_TO_MAKE_GURU_TT" },
}

-- ============================================================================
-- CAI-local state (read from game API, not vanilla's inaccessible locals)
-- ============================================================================

local cai = {
    pantheonBelief     = -1,
    canCreatePantheon  = false,
    playerReligionType = -1,
    numBeliefsEarned   = 0,
    numBeliefsEquipped = 0,
    isHasProphet       = false,
    turnBlockingType   = -1,
}

local m_pendingIconRow    = nil
local m_pendingCustomName = nil
local m_pendingBeliefs    = {}   -- { [slotIndex] = beliefIndex }

local m_beliefPickerActiveSlot = nil

local function ResetPendingSelections()
    m_pendingIconRow    = nil
    m_pendingCustomName = nil
    m_pendingBeliefs    = {}
    m_beliefPickerActiveSlot = nil
end

local function PopBeliefPicker()
    if m_ui.beliefList then
        mgr:RemoveFromStack(m_ui.beliefList.Id)
    end
    m_beliefPickerActiveSlot = nil
end

local function IsClassTakenByPending(classType, excludeSlot)
    for slot, beliefIndex in pairs(m_pendingBeliefs) do
        if slot ~= excludeSlot then
            local b = GameInfo.Beliefs[beliefIndex]
            if b and b.BeliefClassType == classType then
                return true
            end
        end
    end
    return false
end

local function GetPendingBeliefCount()
    local count = 0
    for _, _ in pairs(m_pendingBeliefs) do count = count + 1 end
    return count
end

local function GetSelectedBeliefIndices()
    local indices = {}
    for _, idx in pairs(m_pendingBeliefs) do
        table.insert(indices, idx)
    end
    return indices
end

local function CAI_UpdatePlayerData()
    local displayPlayerID = GetDisplayPlayerID()
    if displayPlayerID == -1 then return end

    local pPlayer = Players[displayPlayerID]
    local pPlayerReligion = pPlayer:GetReligion()
    local pGameReligion = Game.GetReligion()

    cai.pantheonBelief     = pPlayerReligion:GetPantheon()
    cai.canCreatePantheon  = pPlayerReligion:CanCreatePantheon()
    cai.playerReligionType = pPlayerReligion:GetReligionTypeCreated()
    cai.numBeliefsEarned   = pPlayerReligion:GetNumBeliefsEarned()
    cai.isHasProphet       = pPlayerReligion:HasReligiousFoundingUnit()
    cai.turnBlockingType   = NotificationManager.GetFirstEndTurnBlocking(displayPlayerID)

    cai.numBeliefsEquipped = 0
    for _, religion in ipairs(pGameReligion:GetReligions()) do
        if religion.Founder == displayPlayerID then
            cai.numBeliefsEquipped = table.count(religion.Beliefs)
            break
        end
    end
end

-- ============================================================================
-- Tab button capture (AddTab is global in vanilla ReligionScreen.lua)
-- ============================================================================

local m_tabButtons = {}
local m_tabCallIndex = 0

AddTab = WrapFunc(AddTab, function(orig, label, religionData, onClickCallback)
    local btn = orig(label, religionData, onClickCallback)
    m_tabCallIndex = m_tabCallIndex + 1
    if religionData and religionData.Index then
        m_tabButtons[religionData.Index] = btn
    elseif m_tabCallIndex == 1 then
        m_tabButtons["my"] = btn
    else
        m_tabButtons["all"] = btn
    end
    return btn
end)

local function DoTabSwitch(key)
    local btn = m_tabButtons[key]
    if btn then
        btn:DoLeftClick()
    end
end

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

local function IsObserverMode()
    return Game.GetLocalObserver() == PlayerTypes.OBSERVER
end

local function GetSetupState()
    if cai.pantheonBelief < 0 and cai.canCreatePantheon then
        return "PANTHEON"
    elseif cai.pantheonBelief >= 0 and cai.numBeliefsEarned > 0 and cai.playerReligionType < 0 then
        return "RELIGION"
    elseif cai.playerReligionType >= 0 and cai.numBeliefsEarned > cai.numBeliefsEquipped then
        return "ADD_BELIEFS"
    end
    return nil
end

local function IsSetupPending()
    if IsObserverMode() then return false end
    if GetDisplayPlayerID() ~= Game.GetLocalPlayer() then return false end
    return GetSetupState() ~= nil
end

local function GetFoundedReligions()
    local religions = {}
    local displayPlayerID = GetDisplayPlayerID()
    local allReligions = Game.GetReligion():GetReligions()

    for _, religionInfo in ipairs(allReligions) do
        local religionData = GameInfo.Religions[religionInfo.Religion]
        if religionData.Pantheon == false and Game.GetReligion():HasBeenFounded(religionInfo.Religion) then
            if religionInfo.Religion ~= cai.playerReligionType then
                table.insert(religions, religionInfo)
            end
        end
    end

    return religions
end

local function GetReligionName(religionType)
    return Locale.Lookup(Game.GetReligion():GetName(religionType))
end

local function GetFounderInfo(religion, displayPlayerID)
    local localDiplomacy = Players[displayPlayerID]:GetDiplomacy()
    local civID = PlayerConfigurations[religion.Founder]:GetCivilizationTypeID()

    if religion.Founder == displayPlayerID or localDiplomacy:HasMet(religion.Founder) or IsObserverMode() then
        return Locale.Lookup(GameInfo.Civilizations[civID].Name)
    end
    return Locale.Lookup("LOC_DIPLOPANEL_UNMET_PLAYER")
end

local function GetHolyCityInfo(religion, displayPlayerID)
    local localDiplomacy = Players[displayPlayerID]:GetDiplomacy()
    local ownerPlayer = Players[religion.Founder]
    local playerReligion = ownerPlayer:GetReligion()
    local holyCity = CityManager.GetCity(playerReligion:GetHolyCityID())

    if religion.Founder == displayPlayerID or localDiplomacy:HasMet(religion.Founder) or IsObserverMode() then
        if holyCity then
            return holyCity:GetName()
        end
        return Locale.Lookup("LOC_UI_RELIGION_HOLY_CITY_NONE")
    end
    return Locale.Lookup("LOC_UI_RELIGION_UNKNOWN_CITY")
end

local function CountDominantCities(religionType)
    local count = 0
    for _, player in ipairs(PlayerManager.GetAlive()) do
        for _, city in player:GetCities():Members() do
            if city:GetReligion():GetMajorityReligion() == religionType then
                count = count + 1
            end
        end
    end
    return count
end

local function GetCitiesForFilter(religionType, filter)
    local cities = {}
    local displayPlayerID = GetDisplayPlayerID()
    local localDiplomacy = Players[displayPlayerID]:GetDiplomacy()

    local allReligions = Game.GetReligion():GetReligions()
    local foundedReligions = {}
    for _, ri in ipairs(allReligions) do
        local rd = GameInfo.Religions[ri.Religion]
        if rd.Pantheon == false and Game.GetReligion():HasBeenFounded(ri.Religion) then
            table.insert(foundedReligions, ri)
        end
    end

    for _, player in ipairs(PlayerManager.GetAlive()) do
        local playerID = player:GetID()
        local playerReligion = player:GetReligion()
        for _, city in player:GetCities():Members() do
            local bInclude = false
            local cityReligion = city:GetReligion()
            local religionsInCity = cityReligion:GetReligionsInCity()

            if cityReligion:GetMajorityReligion() == religionType then
                if filter == CAI_CITIES_FILTER.FOLLOWING_RELIGION then
                    bInclude = true
                end
            end

            local followersByReligion = {}
            for _, crd in ipairs(religionsInCity) do
                for _, fr in ipairs(foundedReligions) do
                    if crd.Religion == fr.Religion then
                        followersByReligion[crd.Religion] = crd.Followers
                        if filter == CAI_CITIES_FILTER.RELIGION_PRESENT and crd.Religion == religionType then
                            bInclude = true
                        end
                        break
                    end
                end
            end

            if bInclude then
                local cityName
                local cityOwner = city:GetOwner()
                local civID = PlayerConfigurations[cityOwner]:GetCivilizationTypeID()
                local civName = Locale.Lookup(GameInfo.Civilizations[civID].Name)
                if cityOwner == displayPlayerID or localDiplomacy:HasMet(cityOwner) or IsObserverMode() then
                    cityName = Locale.Lookup("LOC_UI_RELIGION_CITY_NAME", city:GetName(), civName)
                else
                    cityName = Locale.Lookup("LOC_UI_RELIGION_UNKNOWN_CITY")
                end

                table.insert(cities, {
                    cityObj          = city,
                    cityID           = city:GetID(),
                    ownerID          = cityOwner,
                    cityName         = cityName,
                    pantheon         = cityReligion:GetActivePantheon(),
                    majority         = cityReligion:GetMajorityReligion(),
                    followers        = followersByReligion,
                    foundedReligions = foundedReligions,
                })
            end
        end
    end

    table.sort(cities, function(a, b)
        return SortCitiesByFollowers(a.cityObj:GetReligion(), b.cityObj:GetReligion(), religionType)
    end)

    return cities
end

local function GetAvailableBeliefs(beliefType, selectedBeliefs)
    local beliefs = {}
    for row in GameInfo.Beliefs() do
        local alreadySelected = false
        for _, bid in ipairs(selectedBeliefs) do
            if row.BeliefClassType == GameInfo.Beliefs[bid].BeliefClassType then
                alreadySelected = true
                break
            end
        end

        if not alreadySelected
            and not Game.GetReligion():IsInSomePantheon(row.Index)
            and not Game.GetReligion():IsInSomeReligion(row.Index)
            and not Game.GetReligion():IsTooManyForReligion(row.Index, cai.playerReligionType)
            and ((beliefType ~= nil and row.BeliefClassType == beliefType)
                or (beliefType == nil and row.BeliefClassType ~= "BELIEF_CLASS_PANTHEON")) then
            table.insert(beliefs, row)
        end
    end

    table.sort(beliefs, function(a, b) return a.BeliefClassType > b.BeliefClassType end)
    return beliefs
end

local function GetEquippedBeliefClasses()
    local equipped = {}
    local displayPlayerID = GetDisplayPlayerID()
    for _, religion in ipairs(Game.GetReligion():GetReligions()) do
        if religion.Founder == displayPlayerID then
            for _, beliefIndex in ipairs(religion.Beliefs) do
                local belief = GameInfo.Beliefs[beliefIndex]
                if belief then
                    equipped[belief.BeliefClassType] = beliefIndex
                end
            end
            break
        end
    end
    return equipped
end

-- ============================================================================
-- Beliefs category builder
-- ============================================================================

local function BuildBeliefsSection(parent, religion, religionType)
    for _, beliefIndex in ipairs(religion.Beliefs) do
        local belief = GameInfo.Beliefs[beliefIndex]
        if belief then
            local bName = Locale.Lookup(belief.Name)
            local bClass = Locale.Lookup("LOC_" .. belief.BeliefClassType .. "_NAME")
            local bDesc = NormalizeText(Locale.Lookup(belief.Description))
            parent:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAIRel_Belief"), "StaticText", {
                Label   = function() return bName .. ": " .. bClass end,
                Tooltip = function() return bDesc end,
                FocusKey = "rel:" .. religionType .. ":beliefs:" .. tostring(beliefIndex),
            }))
        end
    end

    local isOwnReligion = religion.Founder == Game.GetLocalPlayer()
    local maxBeliefs = 4
    local locked = maxBeliefs - #religion.Beliefs
    for i = 1, locked do
        parent:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAIRel_LockedBelief"), "StaticText", {
            Label   = function() return Locale.Lookup("LOC_CAI_RELIGION_LOCKED_BELIEF") end,
            Tooltip = isOwnReligion
                and function() return Locale.Lookup("LOC_UI_RELIGION_LOCKED_BELIEF_DESCRIPTION") end
                or nil,
        }))
    end
end

-- ============================================================================
-- Cities category builder
-- ============================================================================

local function BuildCityRows(parent, religionType, filter)
    parent:ClearChildren()
    local cities = GetCitiesForFilter(religionType, filter)

    for _, cityData in ipairs(cities) do
        local cityRow = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRel_City"), "TreeItem", {
            Label = function() return cityData.cityName end,
            Tooltip = function()
                local parts = {}
                local selFollowers = cityData.followers[religionType]
                if selFollowers then
                    table.insert(parts, Locale.Lookup("LOC_CAI_RELIGION_CITY_FOLLOWERS",
                        GetReligionName(religionType), selFollowers))
                end
                if cityData.majority >= 0 then
                    table.insert(parts, Locale.Lookup("LOC_CAI_RELIGION_MAJORITY", GetReligionName(cityData.majority)))
                end
                if cityData.pantheon >= 0 then
                    local pantheonBelief = GameInfo.Beliefs[cityData.pantheon]
                    if pantheonBelief then
                        table.insert(parts, NormalizeText(Locale.Lookup(pantheonBelief.Description)))
                    end
                else
                    table.insert(parts, Locale.Lookup("LOC_UI_RELIGION_NO_PANTHEON_BELIEF"))
                end
                return table.concat(parts, ", ")
            end,
            FocusKey = "rel:" .. religionType .. ":city:" .. tostring(cityData.cityID),
        })
        cityRow:SetFocusSound(HOVER_SOUND)

        for _, fr in ipairs(cityData.foundedReligions) do
            local rType = fr.Religion
            local rName = GetReligionName(rType)
            local count = cityData.followers[rType] or 0
            cityRow:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAIRel_CityRel"), "StaticText", {
                Label = function()
                    return Locale.Lookup("LOC_CAI_RELIGION_CITY_FOLLOWERS", rName, count)
                end,
            }))
        end

        parent:AddChild(cityRow)
    end

    if #cities == 0 then
        parent:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAIRel_NoCities"), "StaticText", {
            Label = function() return Locale.Lookup("LOC_CAI_RELIGION_NO_CITIES") end,
        }))
    end
end

local function CreateFilterNode(religionType, filterType, filterKey, locKey)
    local node = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRel_Filter"), "TreeItem", {
        Label = function()
            local count = #GetCitiesForFilter(religionType, filterType)
            return Locale.Lookup(locKey) .. ", " .. tostring(count) .. " " ..
                (count == 1 and Locale.Lookup("LOC_UI_RELIGION_CITIES"):lower()
                    or Locale.Lookup("LOC_UI_RELIGION_CITIES"):lower())
        end,
        FocusKey = "rel:" .. religionType .. ":cities:" .. filterKey,
    })
    node:SetFocusSound(HOVER_SOUND)
    node._citiesBuilt = false
    node:On("focus_enter", function(w)
        if not w._citiesBuilt then
            w._citiesBuilt = true
            BuildCityRows(w, religionType, filterType)
            if filterType ~= cai_citiesFilter then
                cai_citiesFilter = filterType
            end
        end
    end)
    return node
end

-- ============================================================================
-- Units category builder
-- ============================================================================

local function BuildUnitsSection(parent, religion, religionType)
    local localPlayerID = GetDisplayPlayerID()
    local localPlayer = Players[localPlayerID]
    if not localPlayer then return end

    local typesAdded = {}
    for _, city in localPlayer:GetCities():Members() do
        local buildQueue = city:GetBuildQueue()
        for row in GameInfo.Units() do
            if row.ReligiousStrength > 0 and not typesAdded[row.UnitType] then
                typesAdded[row.UnitType] = true

                local howMany = 0
                for _, pUnit in localPlayer:GetUnits():Members() do
                    if row.Index == pUnit:GetType() then
                        howMany = howMany + 1
                    end
                end

                local canProduce = buildQueue:CanProduce(row.UnitType, false, true)
                local unitName = Locale.Lookup(row.Name)
                local label = Locale.Lookup("LOC_CAI_RELIGION_UNIT_ENTRY", unitName, howMany)
                local ttip
                if canProduce then
                    ttip = Locale.Lookup("LOC_CAI_RELIGION_UNIT_CAN_PRODUCE")
                    if CAI_UNIT_TOOLTIPS and CAI_UNIT_TOOLTIPS[row.UnitType] and CAI_UNIT_TOOLTIPS[row.UnitType].canProduce then
                        ttip = ttip .. ", " .. NormalizeText(Locale.Lookup(CAI_UNIT_TOOLTIPS[row.UnitType].canProduce))
                    end
                else
                    ttip = Locale.Lookup("LOC_CAI_RELIGION_UNIT_CANNOT_PRODUCE")
                    if CAI_UNIT_TOOLTIPS and CAI_UNIT_TOOLTIPS[row.UnitType] and CAI_UNIT_TOOLTIPS[row.UnitType].cannotProduce then
                        ttip = ttip .. ", " .. NormalizeText(Locale.Lookup(CAI_UNIT_TOOLTIPS[row.UnitType].cannotProduce))
                    end
                end

                parent:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAIRel_Unit"), "StaticText", {
                    Label   = function() return label end,
                    Tooltip = function() return ttip end,
                }))
            end
        end
    end
end

-- ============================================================================
-- Pantheon line builder
-- ============================================================================

local function CreatePantheonLine(religion, religionType)
    local ownerPlayer = Players[religion.Founder]
    local playerReligion = ownerPlayer:GetReligion()
    local pantheonIndex = playerReligion:GetPantheon()

    if pantheonIndex >= 0 then
        local belief = GameInfo.Beliefs[pantheonIndex]
        if belief then
            return mgr:CreateWidget(mgr:GenerateWidgetId("CAIRel_Pan"), "StaticText", {
                Label = function()
                    return Locale.Lookup("LOC_CAI_RELIGION_PANTHEON_LINE", Locale.Lookup(belief.Name))
                end,
                Tooltip = function() return NormalizeText(Locale.Lookup(belief.Description)) end,
                FocusKey = "rel:" .. religionType .. ":pantheon",
            })
        end
    end

    return mgr:CreateWidget(mgr:GenerateWidgetId("CAIRel_NoPan"), "StaticText", {
        Label = function() return Locale.Lookup("LOC_CAI_RELIGION_NO_PANTHEON") end,
        FocusKey = "rel:" .. religionType .. ":pantheon",
    })
end

-- ============================================================================
-- Religion row creation (for non-player religions)
-- ============================================================================

local function CreateReligionRow(religionInfo)
    local religionType = religionInfo.Religion
    local displayPlayerID = GetDisplayPlayerID()
    local row = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRel_Row"), "TreeItem", {
        Label    = function() return GetReligionName(religionType) end,
        Tooltip  = function()
            local parts = {}
            table.insert(parts, Locale.Lookup("LOC_UI_RELIGION_FOUNDER_NAME", GetFounderInfo(religionInfo, displayPlayerID)))
            table.insert(parts, Locale.Lookup("LOC_UI_RELIGION_HOLY_CITY", GetHolyCityInfo(religionInfo, displayPlayerID)))
            local dominantCount = CountDominantCities(religionType)
            if dominantCount == 1 then
                table.insert(parts, Locale.Lookup("LOC_UI_RELIGION_RELIGION_DOMINANCE", dominantCount))
            else
                table.insert(parts, Locale.Lookup("LOC_UI_RELIGION_RELIGION_DOMINANCE_PLURAL", dominantCount))
            end
            return table.concat(parts, ", ")
        end,
        FocusKey = "rel:" .. religionType,
    })
    row:SetFocusSound(HOVER_SOUND)

    row:On("focus_enter", function(w)
        if w:IsFocused() and (m_selectedIsMyReligion or religionType ~= m_selectedReligionType) then
            m_selectedIsMyReligion = false
            m_selectedReligionType = religionType
            DoTabSwitch(religionType)
        end
    end)

    -- 1. Pantheon (flat line at top)
    row:AddChild(CreatePantheonLine(religionInfo, religionType))

    -- 2. Beliefs
    local beliefsSection = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRel_Beliefs"), "TreeItem", {
        Label = function()
            return Locale.Lookup("LOC_CAI_RELIGION_BELIEFS_COUNT", #religionInfo.Beliefs, 4)
        end,
        FocusKey = "rel:" .. religionType .. ":beliefs",
    })
    beliefsSection:SetFocusSound(HOVER_SOUND)
    beliefsSection._built = false
    beliefsSection:On("focus_enter", function(w)
        if not w._built then
            w._built = true
            BuildBeliefsSection(w, religionInfo, religionType)
        end
    end)
    row:AddChild(beliefsSection)

    -- 3. Cities
    local citiesSection = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRel_Cities"), "TreeItem", {
        Label    = function() return Locale.Lookup("LOC_UI_RELIGION_CITIES") end,
        FocusKey = "rel:" .. religionType .. ":cities",
    })
    citiesSection:SetFocusSound(HOVER_SOUND)
    citiesSection:AddChild(CreateFilterNode(religionType, CAI_CITIES_FILTER.FOLLOWING_RELIGION, "following", "LOC_CAI_RELIGION_FILTER_FOLLOWING"))
    citiesSection:AddChild(CreateFilterNode(religionType, CAI_CITIES_FILTER.RELIGION_PRESENT, "present", "LOC_CAI_RELIGION_FILTER_PRESENT"))
    row:AddChild(citiesSection)

    -- 4. Units (hidden for non-player religions)
    local unitsSection = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRel_Units"), "TreeItem", {
        Label            = function() return Locale.Lookup("LOC_CAI_RELIGION_UNITS_SECTION") end,
        FocusKey         = "rel:" .. religionType .. ":units",
        HiddenPredicate  = function() return religionInfo.Founder ~= displayPlayerID end,
    })
    unitsSection:SetFocusSound(HOVER_SOUND)
    unitsSection._built = false
    unitsSection:On("focus_enter", function(w)
        if not w._built then
            w._built = true
            BuildUnitsSection(w, religionInfo, religionType)
        end
    end)
    row:AddChild(unitsSection)

    return row
end

-- ============================================================================
-- "My Religion" tree item
-- ============================================================================

local function GetMyReligionLabel()
    if cai.playerReligionType >= 0 then
        return Locale.Lookup("LOC_CAI_RELIGION_MY_RELIGION") .. ": " .. GetReligionName(cai.playerReligionType)
    end
    if cai.pantheonBelief >= 0 then
        local belief = GameInfo.Beliefs[cai.pantheonBelief]
        if belief then
            return Locale.Lookup("LOC_CAI_RELIGION_MY_PANTHEON") .. ": " .. Locale.Lookup(belief.Name)
        end
    end
    return Locale.Lookup("LOC_CAI_RELIGION_MY_PANTHEON")
end

local function GetMyReligionTooltip()
    local parts = {}

    if cai.pantheonBelief >= 0 then
        local belief = GameInfo.Beliefs[cai.pantheonBelief]
        if belief then
            table.insert(parts, NormalizeText(Locale.Lookup(belief.Description)))
        end
    end

    if cai.playerReligionType >= 0 then
        local displayPlayerID = GetDisplayPlayerID()
        for _, religion in ipairs(Game.GetReligion():GetReligions()) do
            if religion.Founder == displayPlayerID then
                table.insert(parts, Locale.Lookup("LOC_UI_RELIGION_FOUNDER_NAME", GetFounderInfo(religion, displayPlayerID)))
                table.insert(parts, Locale.Lookup("LOC_UI_RELIGION_HOLY_CITY", GetHolyCityInfo(religion, displayPlayerID)))
                local dominantCount = CountDominantCities(cai.playerReligionType)
                if dominantCount == 1 then
                    table.insert(parts, Locale.Lookup("LOC_UI_RELIGION_RELIGION_DOMINANCE", dominantCount))
                else
                    table.insert(parts, Locale.Lookup("LOC_UI_RELIGION_RELIGION_DOMINANCE_PLURAL", dominantCount))
                end
                break
            end
        end
    elseif cai.pantheonBelief >= 0 then
        table.insert(parts, Locale.Lookup("LOC_UI_RELIGION_WORKING_TOWARDS_RELIGION"))
        if cai.isHasProphet then
            table.insert(parts, Locale.Lookup("LOC_RELIGIONPANEL_NEXT_STEP_USE_PROPHET"))
        else
            table.insert(parts, Locale.Lookup("LOC_RELIGIONPANEL_NEXT_STEP_EARN_PROPHET"))
        end
    elseif cai.canCreatePantheon then
        table.insert(parts, Locale.Lookup("LOC_UI_RELIGION_CHOOSING_PANTHEON"))
    else
        local faithNeeded = Game.GetReligion():GetMinimumFaithNextPantheon()
        table.insert(parts, Locale.Lookup("LOC_UI_RELIGION_WORKING_TOWARDS_PANTHEON"))
        table.insert(parts, Locale.Lookup("LOC_RELIGIONPANEL_NEXT_STEP_FOUND_PANTHEON", faithNeeded))
    end

    return table.concat(parts, ", ")
end

local function GetPlayerReligionInfo()
    local displayPlayerID = GetDisplayPlayerID()
    for _, religion in ipairs(Game.GetReligion():GetReligions()) do
        if religion.Founder == displayPlayerID then
            return religion
        end
    end
    return nil
end

local function CreateMyReligionRow()
    local displayPlayerID = GetDisplayPlayerID()

    local row = mgr:CreateWidget("CAIRel_MyReligion", "TreeItem", {
        Label   = function() return GetMyReligionLabel() end,
        Tooltip = function() return GetMyReligionTooltip() end,
        FocusKey = "rel:my",
    })
    row:SetFocusSound(HOVER_SOUND)

    row:On("focus_enter", function(w)
        if w:IsFocused() and (not m_selectedIsMyReligion or cai.playerReligionType ~= m_selectedReligionType) then
            m_selectedIsMyReligion = true
            m_selectedReligionType = cai.playerReligionType
            DoTabSwitch("my")
        end
    end)

    local religionInfo = GetPlayerReligionInfo()
    if not religionInfo then return row end

    local religionType = religionInfo.Religion

    -- Pantheon (flat line at top)
    row:AddChild(CreatePantheonLine(religionInfo, "my"))

    -- Beliefs
    local beliefsSection = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRel_MyBeliefs"), "TreeItem", {
        Label = function()
            return Locale.Lookup("LOC_CAI_RELIGION_BELIEFS_COUNT", #religionInfo.Beliefs, 4)
        end,
        FocusKey = "rel:my:beliefs",
    })
    beliefsSection:SetFocusSound(HOVER_SOUND)
    beliefsSection._built = false
    beliefsSection:On("focus_enter", function(w)
        if not w._built then
            w._built = true
            BuildBeliefsSection(w, religionInfo, religionType)
        end
    end)
    row:AddChild(beliefsSection)

    -- Cities
    local citiesSection = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRel_MyCities"), "TreeItem", {
        Label    = function() return Locale.Lookup("LOC_UI_RELIGION_CITIES") end,
        FocusKey = "rel:my:cities",
    })
    citiesSection:SetFocusSound(HOVER_SOUND)
    citiesSection:AddChild(CreateFilterNode(religionType, CAI_CITIES_FILTER.FOLLOWING_RELIGION, "following", "LOC_CAI_RELIGION_FILTER_FOLLOWING"))
    citiesSection:AddChild(CreateFilterNode(religionType, CAI_CITIES_FILTER.RELIGION_PRESENT, "present", "LOC_CAI_RELIGION_FILTER_PRESENT"))
    row:AddChild(citiesSection)

    -- Units
    local unitsSection = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRel_MyUnits"), "TreeItem", {
        Label    = function() return Locale.Lookup("LOC_CAI_RELIGION_UNITS_SECTION") end,
        FocusKey = "rel:my:units",
    })
    unitsSection:SetFocusSound(HOVER_SOUND)
    unitsSection._built = false
    unitsSection:On("focus_enter", function(w)
        if not w._built then
            w._built = true
            BuildUnitsSection(w, religionInfo, religionType)
        end
    end)
    row:AddChild(unitsSection)

    return row
end

-- ============================================================================
-- Setup panel: validation
-- ============================================================================

local function AreAllSelectionsComplete()
    local state = GetSetupState()
    if not state then return false end

    if state == "PANTHEON" then
        return m_pendingBeliefs[1] ~= nil
    elseif state == "RELIGION" then
        if not m_pendingIconRow then return false end
        if m_pendingIconRow.RequiresCustomName
            and GameCapabilities.HasCapability("CAPABILITY_RENAME")
            and not IsReligionNameValid(m_pendingCustomName) then
            return false
        end
        local needed = cai.numBeliefsEarned - cai.numBeliefsEquipped
        return GetPendingBeliefCount() >= needed
    elseif state == "ADD_BELIEFS" then
        local needed = cai.numBeliefsEarned - cai.numBeliefsEquipped
        return GetPendingBeliefCount() >= needed
    end
    return false
end

-- ============================================================================
-- Setup panel: confirmation dialog
-- ============================================================================

local function CloseConfirmDialog()
    if m_ui.dialog then
        mgr:RemoveFromStack(m_ui.dialog.Id)
        m_ui.dialog = nil
    end
end

local function ExecuteCommit()
    local state = GetSetupState()
    if not state then return end

    if state == "PANTHEON" then
        local beliefIndex = m_pendingBeliefs[1]
        if beliefIndex then
            local tParameters = {}
            tParameters[PlayerOperations.PARAM_BELIEF_TYPE] = GameInfo.Beliefs[beliefIndex].Hash
            tParameters[PlayerOperations.PARAM_INSERT_MODE] = PlayerOperations.VALUE_EXCLUSIVE
            UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.FOUND_PANTHEON, tParameters)
        end
    elseif state == "RELIGION" then
        if m_pendingIconRow then
            local tParameters = {}
            tParameters[PlayerOperations.PARAM_INSERT_MODE] = PlayerOperations.VALUE_EXCLUSIVE
            tParameters[PlayerOperations.PARAM_RELIGION_TYPE] = m_pendingIconRow.Hash
            if m_pendingIconRow.RequiresCustomName
                and GameCapabilities.HasCapability("CAPABILITY_RENAME")
                and m_pendingCustomName then
                tParameters[PlayerOperations.PARAM_RELIGION_CUSTOM_NAME] = m_pendingCustomName
            end
            UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.FOUND_RELIGION, tParameters)
        end
        -- Submit beliefs in slot order (slot 1 is always Follower per vanilla)
        local numSlots = cai.numBeliefsEarned
        for slot = 1, numSlots do
            local beliefIndex = m_pendingBeliefs[slot]
            if beliefIndex then
                local tParameters = {}
                tParameters[PlayerOperations.PARAM_BELIEF_TYPE] = GameInfo.Beliefs[beliefIndex].Hash
                tParameters[PlayerOperations.PARAM_INSERT_MODE] = PlayerOperations.VALUE_EXCLUSIVE
                UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.ADD_BELIEF, tParameters)
            end
        end
    elseif state == "ADD_BELIEFS" then
        local numSlots = cai.numBeliefsEarned - cai.numBeliefsEquipped
        for slot = 1, numSlots do
            local beliefIndex = m_pendingBeliefs[slot]
            if beliefIndex then
                local tParameters = {}
                tParameters[PlayerOperations.PARAM_BELIEF_TYPE] = GameInfo.Beliefs[beliefIndex].Hash
                tParameters[PlayerOperations.PARAM_INSERT_MODE] = PlayerOperations.VALUE_EXCLUSIVE
                UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.ADD_BELIEF, tParameters)
            end
        end
    end

    UI.PlaySound("Confirm_Religion")
    ResetPendingSelections()
end

local function CommitSetup()
    CloseConfirmDialog()

    local state = GetSetupState()
    if not state then return end

    local summaryRows = {}

    if state == "RELIGION" and m_pendingIconRow then
        local iconName = Locale.Lookup(m_pendingIconRow.Name)
        table.insert(summaryRows, mgr:CreateWidget(mgr:GenerateWidgetId("CAIRel_SumIcon"), "StaticText", {
            Label = function() return Locale.Lookup("LOC_CAI_RELIGION_SUMMARY_ICON", iconName) end,
        }))
        if m_pendingIconRow.RequiresCustomName and m_pendingCustomName then
            table.insert(summaryRows, mgr:CreateWidget(mgr:GenerateWidgetId("CAIRel_SumName"), "StaticText", {
                Label = function() return Locale.Lookup("LOC_CAI_RELIGION_SUMMARY_NAME", m_pendingCustomName) end,
            }))
        end
    end

    local numSlots = state == "PANTHEON" and 1
        or (state == "RELIGION" and cai.numBeliefsEarned
        or (cai.numBeliefsEarned - cai.numBeliefsEquipped))
    for slot = 1, numSlots do
        local beliefIndex = m_pendingBeliefs[slot]
        if beliefIndex then
            local belief = GameInfo.Beliefs[beliefIndex]
            if belief then
                local className = Locale.Lookup("LOC_" .. belief.BeliefClassType .. "_NAME")
                local beliefName = Locale.Lookup(belief.Name)
                table.insert(summaryRows, mgr:CreateWidget(mgr:GenerateWidgetId("CAIRel_SumBelief"), "StaticText", {
                    Label   = function() return Locale.Lookup("LOC_CAI_RELIGION_SUMMARY_BELIEF", className, beliefName) end,
                    Tooltip = function() return NormalizeText(Locale.Lookup(belief.Description)) end,
                }))
            end
        end
    end

    local confirmBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRel_DlgYes"), "Button", {
        Label = function() return Locale.Lookup("LOC_YES") end,
    })
    confirmBtn:SetFocusSound(HOVER_SOUND)
    confirmBtn:On("activate", function()
        ExecuteCommit()
        CloseConfirmDialog()
    end)

    local cancelBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRel_DlgNo"), "Button", {
        Label = function() return Locale.Lookup("LOC_NO") end,
    })
    cancelBtn:SetFocusSound(HOVER_SOUND)
    cancelBtn:On("activate", function()
        CloseConfirmDialog()
    end)

    m_ui.dialog = mgr.WidgetHelpers.MakeGeneralDialog(
        function() return Locale.Lookup("LOC_CAI_RELIGION_CONFIRM_SUMMARY") end,
        { confirmBtn, cancelBtn },
        summaryRows,
        1
    )
    if m_ui.dialog then
        mgr:Push(m_ui.dialog, PopupPriority.Current)
    end
end

-- ============================================================================
-- Setup panel: build
-- ============================================================================

local function RebuildSetupPanel()
    if not m_ui.setupPanel then return end

    local capture = mgr:CaptureFocusKey(m_ui.setupPanel)
    m_ui.setupPanel:ClearChildren()

    local state = GetSetupState()
    local hasReligion = cai.playerReligionType >= 0
    local hasPantheon = cai.pantheonBelief >= 0
    local equippedClasses = GetEquippedBeliefClasses()

    -- Parameter list container (List widget, not Panel)
    local paramList = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRel_ParamList"), "List", {
        Label = function() return Locale.Lookup("LOC_CAI_RELIGION_SETUP_PANEL") end,
        WrapAround = false,
    })

    -- 1. Icon dropdown (hidden during PANTHEON, visible otherwise if has pantheon or founding)
    if state ~= "PANTHEON" and (hasReligion or state == "RELIGION") then
        local iconDD = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRel_IconDD"), "Dropdown", {
            Label = function() return Locale.Lookup("LOC_CAI_RELIGION_CHOOSE_ICON") end,
            FocusKey = "rel:setup:icon",
        })
        iconDD:SetValueGetter(function(self)
            local opt = self._options[self._selectedIndex]
            return opt and opt.label or Locale.Lookup("LOC_CAI_RELIGION_BELIEF_NONE")
        end)

        if hasReligion then
            iconDD:SetOptions({ { label = GetReligionName(cai.playerReligionType), value = cai.playerReligionType } })
            iconDD:SetSelectedIndex(1, true)
            iconDD:SetDisabledPredicate(function() return true end)
        else
            local options = {}
            for row in GameInfo.Religions() do
                if row.Pantheon == false and not Game.GetReligion():HasBeenFounded(row.Index) then
                    table.insert(options, { label = Locale.Lookup(row.Name), value = row })
                end
            end
            iconDD:SetOptions(options)
            if m_pendingIconRow then
                for i, opt in ipairs(options) do
                    if opt.value.Index == m_pendingIconRow.Index then
                        iconDD:SetSelectedIndex(i, true)
                        break
                    end
                end
            end
            iconDD:On("value_changed", function(w)
                m_pendingIconRow = w:GetRawValue()
                if not m_pendingIconRow then return end
                local canChangeName = GameCapabilities.HasCapability("CAPABILITY_RENAME")
                if m_pendingIconRow.RequiresCustomName and canChangeName then
                    m_pendingCustomName = nil
                    if m_ui.nameEdit then
                        m_ui.nameEdit:SetReadOnly(false)
                        m_ui.nameEdit:SetText("", true)
                        m_ui.nameEdit:BeginEdit(true)
                    end
                else
                    m_pendingCustomName = Locale.Lookup(m_pendingIconRow.Name)
                    if m_ui.nameEdit then
                        m_ui.nameEdit:SetText(m_pendingCustomName, true)
                        m_ui.nameEdit:SetReadOnly(true)
                        m_ui.nameEdit:BeginEdit(true)
                    end
                end
            end)
        end

        iconDD:SetFocusSound(HOVER_SOUND)
        paramList:AddChild(iconDD)
    end

    -- Equipped belief order (non-pantheon beliefs already in the religion)
    local equippedOrder = {}
    if cai.playerReligionType >= 0 then
        for _, religion in ipairs(Game.GetReligion():GetReligions()) do
            if religion.Religion == cai.playerReligionType then
                for _, beliefIndex in ipairs(religion.Beliefs) do
                    local bel = GameInfo.Beliefs[beliefIndex]
                    if bel and bel.BeliefClassType ~= "BELIEF_CLASS_PANTHEON" then
                        table.insert(equippedOrder, beliefIndex)
                    end
                end
                break
            end
        end
    end

    -- 2. Belief slots (MenuItems that push a belief picker List)
    if state == "PANTHEON" then
        -- Single pantheon slot
        local function GetSlotValueLabel(slot)
            if m_pendingBeliefs[slot] then
                local b = GameInfo.Beliefs[m_pendingBeliefs[slot]]
                if b then
                    return Locale.Lookup(b.Name) .. ", " .. Locale.Lookup("LOC_BELIEF_CLASS_PANTHEON_NAME")
                end
            end
            return Locale.Lookup("LOC_CAI_RELIGION_BELIEF_NONE")
        end

        local pantheonSlot = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRel_PanSlot"), "MenuItem", {
            Label = function()
                return Locale.Lookup("LOC_CAI_RELIGION_BELIEF_SLOT", 1) .. ": " .. GetSlotValueLabel(1)
            end,
            Tooltip = function()
                if m_pendingBeliefs[1] then
                    local b = GameInfo.Beliefs[m_pendingBeliefs[1]]
                    if b then return NormalizeText(Locale.Lookup(b.Description)) end
                end
                return ""
            end,
            FocusKey = "rel:setup:slot:1",
        })
        pantheonSlot:SetFocusSound(HOVER_SOUND)
        pantheonSlot:On("activate", function()
            m_beliefPickerActiveSlot = 1
            -- Build and push the belief picker
            PopBeliefPicker()
            m_ui.beliefList = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRel_BeliefPicker"), "List", {
                Label = function() return Locale.Lookup("LOC_BELIEF_CLASS_PANTHEON_NAME") end,
            })
            local available = GetAvailableBeliefs("BELIEF_CLASS_PANTHEON", {})
            for _, belief in ipairs(available) do
                local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRel_BPick"), "MenuItem", {
                    Label = function()
                        return Locale.Lookup(belief.Name) .. ", " .. Locale.Lookup("LOC_BELIEF_CLASS_PANTHEON_NAME")
                    end,
                    Tooltip = function() return NormalizeText(Locale.Lookup(belief.Description)) end,
                })
                item:SetFocusSound(HOVER_SOUND)
                item:On("activate", function()
                    m_pendingBeliefs[1] = belief.Index
                    PopBeliefPicker()
                end)
                m_ui.beliefList:AddChild(item)
            end
            m_ui.beliefList:AddInputBindings({
                { Key = Keys.VK_ESCAPE, Action = function() PopBeliefPicker(); return true end },
            })
            mgr:Push(m_ui.beliefList, PopupPriority.Current)
        end)
        pantheonSlot:AddInputBindings({
            { Key = Keys.VK_DELETE, Action = function()
                if m_pendingBeliefs[1] then
                    m_pendingBeliefs[1] = nil
                    Speak(Locale.Lookup("LOC_CAI_RELIGION_SLOT_CLEARED",
                        Locale.Lookup("LOC_CAI_RELIGION_BELIEF_SLOT", 1)))
                end
                return true
            end },
        })
        paramList:AddChild(pantheonSlot)

    else
        -- Show pantheon belief as read-only review item if it exists
        if hasPantheon then
            local belief = GameInfo.Beliefs[cai.pantheonBelief]
            if belief then
                local panReview = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRel_PanReview"), "MenuItem", {
                    Label = function()
                        return Locale.Lookup("LOC_BELIEF_CLASS_PANTHEON_NAME") .. ": "
                            .. Locale.Lookup(belief.Name)
                    end,
                    Tooltip = function() return NormalizeText(Locale.Lookup(belief.Description)) end,
                    FocusKey = "rel:setup:belief:pantheon",
                })
                panReview:SetFocusSound(HOVER_SOUND)
                panReview:SetDisabledPredicate(function() return true end)
                paramList:AddChild(panReview)
            end
        end

        -- Equipped belief slots (disabled review items, skip pantheon class)
        for i, beliefIndex in ipairs(equippedOrder) do
            local belief = GameInfo.Beliefs[beliefIndex]
            if belief then
                local className = Locale.Lookup("LOC_" .. belief.BeliefClassType .. "_NAME")
                local eqSlot = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRel_EqSlot_" .. i), "MenuItem", {
                    Label = function()
                        return Locale.Lookup("LOC_CAI_RELIGION_BELIEF_SLOT", i) .. ": "
                            .. Locale.Lookup(belief.Name) .. ", " .. className
                    end,
                    Tooltip = function() return NormalizeText(Locale.Lookup(belief.Description)) end,
                    FocusKey = "rel:setup:eq:" .. i,
                })
                eqSlot:SetFocusSound(HOVER_SOUND)
                eqSlot:SetDisabledPredicate(function() return true end)
                paramList:AddChild(eqSlot)
            end
        end

        -- Pending belief slots (activatable MenuItems)
        local numPendingSlots = cai.numBeliefsEarned - cai.numBeliefsEquipped

        for slot = 1, numPendingSlots do
            local capturedSlot = slot
            local slotNum = #equippedOrder + slot
            local isFollowerSlot = (slot == 1) and not equippedClasses["BELIEF_CLASS_FOLLOWER"]

            local function GetPendingSlotLabel()
                local prefix
                if isFollowerSlot then
                    prefix = Locale.Lookup("LOC_CAI_RELIGION_FOLLOWER_BELIEF") .. ": "
                else
                    prefix = Locale.Lookup("LOC_CAI_RELIGION_BELIEF_SLOT", slotNum) .. ": "
                end
                if m_pendingBeliefs[capturedSlot] then
                    local b = GameInfo.Beliefs[m_pendingBeliefs[capturedSlot]]
                    if b then
                        local className = Locale.Lookup("LOC_" .. b.BeliefClassType .. "_NAME")
                        return prefix .. Locale.Lookup(b.Name) .. ", " .. className
                    end
                end
                return prefix .. Locale.Lookup("LOC_CAI_RELIGION_BELIEF_NONE")
            end

            local slotItem = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRel_PendSlot_" .. slot), "MenuItem", {
                Label = function() return GetPendingSlotLabel() end,
                Tooltip = function()
                    if m_pendingBeliefs[capturedSlot] then
                        local b = GameInfo.Beliefs[m_pendingBeliefs[capturedSlot]]
                        if b then return NormalizeText(Locale.Lookup(b.Description)) end
                    end
                    return ""
                end,
                FocusKey = "rel:setup:slot:" .. slot,
            })
            slotItem:SetFocusSound(HOVER_SOUND)

            slotItem:On("activate", function()
                m_beliefPickerActiveSlot = capturedSlot
                PopBeliefPicker()

                m_ui.beliefList = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRel_BeliefPicker"), "Tree", {
                    Label = function()
                        if isFollowerSlot then
                            return Locale.Lookup("LOC_CAI_RELIGION_FOLLOWER_BELIEF")
                        end
                        return Locale.Lookup("LOC_UI_RELIGION_CHOOSE_RELIGION_BELIEF")
                    end,
                })

                local classBuckets = {}
                local classOrder = {}
                for row in GameInfo.Beliefs() do
                    if row.BeliefClassType ~= "BELIEF_CLASS_PANTHEON"
                        and not Game.GetReligion():IsInSomePantheon(row.Index)
                        and not Game.GetReligion():IsInSomeReligion(row.Index)
                        and not Game.GetReligion():IsTooManyForReligion(row.Index, cai.playerReligionType)
                        and (not isFollowerSlot or row.BeliefClassType == "BELIEF_CLASS_FOLLOWER") then
                        local cls = row.BeliefClassType
                        if not classBuckets[cls] then
                            classBuckets[cls] = {}
                            table.insert(classOrder, cls)
                        end
                        table.insert(classBuckets[cls], row)
                    end
                end
                table.sort(classOrder)

                for _, cls in ipairs(classOrder) do
                    local capturedCls = cls
                    local className = Locale.Lookup("LOC_" .. cls .. "_NAME")
                    local category = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRel_BPCat"), "TreeItem", {
                        Label = function() return className end,
                        HiddenPredicate = function()
                            return IsClassTakenByPending(capturedCls, capturedSlot)
                                or equippedClasses[capturedCls] ~= nil
                        end,
                    })

                    category:SetFocusSound(HOVER_SOUND)

                    for _, belief in ipairs(classBuckets[cls]) do
                        local beliefIndex = belief.Index
                        local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRel_BPick"), "TreeItem", {
                            Label = function() return Locale.Lookup(belief.Name) end,
                            Tooltip = function() return NormalizeText(Locale.Lookup(belief.Description)) end,
                        })
                        item:SetFocusSound(HOVER_SOUND)
                        item:On("activate", function()
                            m_pendingBeliefs[capturedSlot] = beliefIndex
                            PopBeliefPicker()
                        end)
                        category:AddChild(item)
                    end

                    m_ui.beliefList:AddChild(category)
                    category:Expand(true)
                end

                m_ui.beliefList:AddInputBindings({
                    { Key = Keys.VK_ESCAPE, MSG = KeyEvents.KeyUp, Action = function() PopBeliefPicker(); return true end },
                })
                mgr:Push(m_ui.beliefList, PopupPriority.Current)
            end)

            slotItem:AddInputBindings({
                { Key = Keys.VK_DELETE, Action = function()
                    if m_pendingBeliefs[capturedSlot] then
                        m_pendingBeliefs[capturedSlot] = nil
                        local slotName = isFollowerSlot
                            and Locale.Lookup("LOC_CAI_RELIGION_FOLLOWER_BELIEF")
                            or Locale.Lookup("LOC_CAI_RELIGION_BELIEF_SLOT", slotNum)
                        Speak(Locale.Lookup("LOC_CAI_RELIGION_SLOT_CLEARED", slotName))
                    end
                    return true
                end },
            })

            paramList:AddChild(slotItem)
        end
    end

    m_ui.setupPanel:AddChild(paramList)

    -- 3. Religion name edit box (hidden during PANTHEON)
    m_ui.nameEdit = nil
    if state ~= "PANTHEON" and (hasReligion or state == "RELIGION") then
        local nameEdit = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRel_NameEdit"), "EditBox", {
            Label = function() return Locale.Lookup("LOC_UI_RELIGION_CHOOSE_RELIGION_NAME") end,
            FocusKey = "rel:setup:name",
        })
        nameEdit:SetFocusSound(HOVER_SOUND)
        nameEdit:SetAlwaysEdit(true)
        nameEdit:SetMaxCharacters(32)

        if hasReligion then
            nameEdit:SetText(GetReligionName(cai.playerReligionType), true)
            nameEdit:SetReadOnly(true)
        else
            local canChangeName = GameCapabilities.HasCapability("CAPABILITY_RENAME")
            if m_pendingIconRow then
                if m_pendingIconRow.RequiresCustomName and canChangeName then
                    nameEdit:SetText(m_pendingCustomName or "", true)
                else
                    nameEdit:SetText(Locale.Lookup(m_pendingIconRow.Name), true)
                    nameEdit:SetReadOnly(true)
                end
            else
                nameEdit:SetReadOnly(true)
            end
            nameEdit:SetValueSetter(function(_, text)
                m_pendingCustomName = text
            end)
        end

        m_ui.nameEdit = nameEdit
        m_ui.setupPanel:AddChild(nameEdit)
    end

    -- 4. Confirm button (only when setup is pending)
    if state then
        local confirmBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRel_Confirm"), "Button", {
            Label = function()
                if state == "PANTHEON" then
                    return Locale.Lookup("LOC_UI_RELIGION_FOUND_PANTHEON")
                elseif state == "RELIGION" then
                    return Locale.Lookup("LOC_UI_RELIGION_FOUND_RELIGION")
                end
                return Locale.Lookup("LOC_CAI_RELIGION_CONFIRM_CHANGES")
            end,
            Tooltip = function()
                if AreAllSelectionsComplete() then return "" end
                local blockers = {}
                if state == "PANTHEON" then
                    if not m_pendingBeliefs[1] then
                        table.insert(blockers, Locale.Lookup("LOC_CAI_RELIGION_BLOCKER_PANTHEON"))
                    end
                else
                    if state == "RELIGION" and not m_pendingIconRow then
                        table.insert(blockers, Locale.Lookup("LOC_CAI_RELIGION_BLOCKER_ICON"))
                    end
                    if state == "RELIGION" and m_pendingIconRow
                        and m_pendingIconRow.RequiresCustomName
                        and GameCapabilities.HasCapability("CAPABILITY_RENAME")
                        and not IsReligionNameValid(m_pendingCustomName) then
                        table.insert(blockers, Locale.Lookup("LOC_CAI_RELIGION_BLOCKER_NAME"))
                    end
                    local numPendingSlots = cai.numBeliefsEarned - cai.numBeliefsEquipped
                    local isFollowerSlot = not equippedClasses["BELIEF_CLASS_FOLLOWER"]
                    for slot = 1, numPendingSlots do
                        if not m_pendingBeliefs[slot] then
                            if slot == 1 and isFollowerSlot then
                                table.insert(blockers, Locale.Lookup("LOC_CAI_RELIGION_BLOCKER_FOLLOWER"))
                            else
                                local slotNum = #equippedOrder + slot
                                table.insert(blockers, Locale.Lookup("LOC_CAI_RELIGION_BLOCKER_SLOT", slotNum))
                            end
                        end
                    end
                end
                return table.concat(blockers, ", ")
            end,
            FocusKey = "rel:setup:confirm",
        })
        confirmBtn:SetFocusSound(HOVER_SOUND)
        confirmBtn:SetDisabledPredicate(function() return not AreAllSelectionsComplete() end)
        confirmBtn:On("activate", function()
            CommitSetup()
        end)
        m_ui.setupPanel:AddChild(confirmBtn)
    end

    mgr:RestoreFocus(m_ui.setupPanel, capture)
end

-- ============================================================================
-- Rebuild
-- ============================================================================

local function CAI_RebuildTree()
    if not m_ui.tree then return end
    if ContextPtr:IsHidden() then return end

    CAI_UpdatePlayerData()

    local capture = mgr:CaptureFocusKey(m_ui.tree)
    m_ui.tree:ClearChildren()

    -- Always add "My Religion" as first child
    m_ui.tree:AddChild(CreateMyReligionRow())

    -- Other founded religions (player's religion excluded)
    local religions = GetFoundedReligions()
    for _, religionInfo in ipairs(religions) do
        m_ui.tree:AddChild(CreateReligionRow(religionInfo))
    end

    mgr:RestoreFocus(m_ui.tree, capture)

    -- Rebuild the setup panel
    RebuildSetupPanel()
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
            return Locale.Lookup("LOC_UI_RELIGION_TITLE")
        end,
    })

    m_ui.tree = mgr:CreateWidget(TREE_ID, "Tree", {
        Label = function()
            local count = 0
            for _, ri in ipairs(Game.GetReligion():GetReligions()) do
                local rd = GameInfo.Religions[ri.Religion]
                if rd.Pantheon == false and Game.GetReligion():HasBeenFounded(ri.Religion) then
                    count = count + 1
                end
            end
            local maxReligions = 0
            local mapSizeIndex = Map.GetMapSize()
            local mapSize = GameInfo.Maps[mapSizeIndex]
            if mapSize then
                for row in GameInfo.Map_GreatPersonClasses() do
                    if row.MapSizeType == mapSize.MapSizeType
                        and row.GreatPersonClassType == "GREAT_PERSON_CLASS_PROPHET" then
                        maxReligions = row.MaxWorldInstances
                    end
                end
            end
            return Locale.Lookup("LOC_UI_RELIGION_ALL_RELIGIONS", count .. "/" .. maxReligions)
        end,
    })
    m_ui.panel:AddChild(m_ui.tree)

    m_ui.setupPanel = mgr:CreateWidget(SETUP_PANEL_ID, "Panel", {
        Label = function() return Locale.Lookup("LOC_CAI_RELIGION_SETUP_PANEL") end,
        HiddenPredicate = function()
            if IsObserverMode() then return true end
            if GetDisplayPlayerID() ~= Game.GetLocalPlayer() then return true end
            if not IsSetupPending() then return true end
            return not m_selectedIsMyReligion
        end,
        WrapAround = false,
    })
    m_ui.panel:AddChild(m_ui.setupPanel)
end

-- ============================================================================
-- Lifecycle
-- ============================================================================

local function PushPanel()
    EnsurePanelBuilt()
    ResetPendingSelections()
    CAI_RebuildTree()
    local focusTarget = IsSetupPending() and m_ui.setupPanel or nil
    mgr:Push(m_ui.panel, { priority = PopupPriority.Low, focus = focusTarget })
end

local function PopPanel()
    PopBeliefPicker()
    CloseConfirmDialog()
    ResetPendingSelections()
    if mgr and m_ui.panel then
        mgr:RemoveFromStack(PANEL_ID)
    end
    m_ui = { panel = nil, tree = nil, setupPanel = nil, nameEdit = nil, beliefList = nil, dialog = nil }
end

-- ============================================================================
-- Wraps
-- ============================================================================

Open = WrapFunc(Open, function(orig)
    orig()
    if mgr and not ContextPtr:IsHidden() then
        PushPanel()
    end
end)

Close = WrapFunc(Close, function(orig)
    PopPanel()
    orig()
end)

UpdateData = WrapFunc(UpdateData, function(orig)
    m_tabButtons = {}
    m_tabCallIndex = 0
    orig()
    if mgr and mgr:GetWidgetById(PANEL_ID) and not ContextPtr:IsHidden() then
        ResetPendingSelections()
        CAI_RebuildTree()
    end
end)

ViewMyReligion = WrapFunc(ViewMyReligion, function(orig)
    orig()
    m_selectedReligionType = cai.playerReligionType
    m_selectedIsMyReligion = true
end)

ViewReligion = WrapFunc(ViewReligion, function(orig, religionType)
    orig(religionType)
    m_selectedReligionType = religionType
    m_selectedIsMyReligion = false
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

local baseOnShutdown = OnShutdown
ContextPtr:SetShutdown(function()
    PopPanel()
    baseOnShutdown()
end)
