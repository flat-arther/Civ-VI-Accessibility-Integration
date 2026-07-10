-- CityPanelOverview_CAI.lua
--
-- Accessibility layer for the City Details overview panel.
-- Replaces the vanilla CityPanelOverview LuaContext. Re-includes the correct
-- expansion version, then wraps lifecycle to overlay a single CAI browsing
-- surface: one Tree (with tab sections) plus a city rename EditBox.

include("caiUtils")
include("Civ6Common")

if IsExpansion2Active() then
    include("CityPanelOverview_Expansion2")
elseif IsExpansion1Active() then
    include("CityPanelOverview_Expansion1")
else
    include("CityPanelOverview")
end

local mgr = ExposedMembers.CAI_UIManager
if not mgr then return end

-- ===========================================================================
-- Constants
-- ===========================================================================

local PANEL_ID          = "CAICityOverview_Panel"
local TREE_ID           = "CAICityOverview_Tree"
local RENAME_ID         = "CAICityOverview_Rename"
local RENAME_EDIT_ID    = "CAICityOverview_RenameEdit"
local HOVER_SOUND       = "Main_Menu_Mouse_Over"

-- ===========================================================================
-- State
-- ===========================================================================

local m_ui              = { panel = nil, tree = nil, rename = nil }
local m_caiShowing      = false
local m_caiSelectedTab  = nil
local m_caiEspionageVM  = EspionageViewManager:CreateManager()

-- ===========================================================================
-- Tab switch guard
-- ===========================================================================

local m_caiSwitchingTab = false

-- ===========================================================================
-- Helpers
-- ===========================================================================

local function GetCurrentCity()
    local city = UI.GetHeadSelectedCity()
    if not city then
        city = m_caiEspionageVM:GetEspionageViewCity()
    end
    return city
end

local function IsEspionageView()
    return m_caiEspionageVM:IsEspionageView()
end

local function IsOwnedCity(city)
    return city and city:GetOwner() == Game.GetLocalPlayer()
end

local function MakeTreeItem(props)
    local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAICityOV_"), "TreeItem", props)
    item:SetFocusSound(HOVER_SOUND)
    return item
end

local function MakeStaticText(props)
    local text = mgr:CreateWidget(mgr:GenerateWidgetId("CAICityOV_"), "StaticText", props)
    text:SetFocusSound(HOVER_SOUND)
    return text
end

local function AddLeaf(parent, focusKey, labelFn, tooltipFn)
    local item = MakeStaticText({
        Label = labelFn,
        Tooltip = tooltipFn,
        FocusKey = focusKey,
    })
    parent:AddChild(item)
    return item
end

local function FlattenNewlines(text)
    if not text or text == "" then return "" end
    text = text:gsub("%[NEWLINE%]", "[NEWLINE]")
    text = text:gsub("\n", "[NEWLINE]")
    return text
end

local function StripTooltipHeader(tip)
    if not tip or tip == "" then return "" end
    local _, pos = tip:find("^.-%[NEWLINE%].-%[NEWLINE%]")
    if pos then
        tip = tip:sub(pos + 1)
    end
    return FlattenNewlines(tip)
end

local function FormatSourceLine(locKey, value)
    return Locale.Lookup(locKey) .. ": " .. Locale.ToNumber(value)
end

local function FormatNegativeSourceLine(locKey, value)
    if value == 0 then
        return Locale.Lookup(locKey) .. ": " .. Locale.ToNumber(value)
    end
    return Locale.Lookup(locKey) .. ": " .. Locale.ToNumber(-value)
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

-- ===========================================================================
-- Citizens and Growth tab
-- ===========================================================================

local function BuildCitizensTab(data, city)
    local tabItem = MakeTreeItem({
        Label = function()
            return Locale.Lookup("LOC_CAI_CITY_ACTION_CITIZENS_GROWTH")
        end,
        Tooltip = function()
            return JoinLines({
                Locale.Lookup("LOC_CAI_CITY_OV_CITIZENS_OF_HOUSING", data.Population, math.floor(data.Housing)),
                toPlusMinusString(data.FoodPerTurn) .. " " .. Locale.Lookup("LOC_HUD_CITY_FOOD_PER_TURN"),
                Locale.ToNumber(data.GrowthThreshold, "#,###.#") .. " " ..
                    Locale.Lookup("LOC_HUD_CITY_FOOD_NEEDED_FOR_GROWTH"),
            })
        end,
        FocusKey = "tab:citizens",
    })
    tabItem:On("focus_enter", function()
        if m_caiSelectedTab == "tab:citizens" then return end
        m_caiSelectedTab = "tab:citizens"
        m_caiSwitchingTab = true
        OnSelectHealthTab()
        m_caiSwitchingTab = false
    end)

    -- Food details (expandable for growth modifiers)
    local foodItem = MakeTreeItem({
        Label = function()
            local consumption = toPlusMinusString(-(data.FoodPerTurn - data.FoodSurplus))
            local netFood = toPlusMinusString(data.FoodSurplus)
            local growth
            if data.Occupied then
                growth = Locale.Lookup("LOC_HUD_CITY_GROWTH_OCCUPIED")
            elseif data.TurnsUntilGrowth >= 0 then
                growth = Locale.Lookup("LOC_HUD_CITY_TURNS_UNTIL_CITIZEN_BORN", data.TurnsUntilGrowth)
            else
                growth = Locale.Lookup("LOC_HUD_CITY_TURNS_UNTIL_CITIZEN_LOST", math.abs(data.TurnsUntilGrowth))
            end
            return JoinLines({
                Locale.Lookup("LOC_CAI_CITY_OV_FOOD_CONSUMPTION") .. ": " .. consumption,
                Locale.Lookup("LOC_CAI_CITY_OV_NET_FOOD") .. ": " .. netFood,
                growth,
            })
        end,
        FocusKey = "citizens:food",
    })

    AddLeaf(foodItem, "citizens:food:happiness", function()
        local iHappinessPercent = data.HappinessGrowthModifier
        return Locale.Lookup("LOC_HUD_CITY_HAPPINESS_GROWTH_BONUS") ..
            ": " .. toPlusMinusString(Round(iHappinessPercent, 0)) .. "%"
    end)
    AddLeaf(foodItem, "citizens:food:othergrowth", function()
        local iOtherPercent = data.OtherGrowthModifiers * 100
        return Locale.Lookup("LOC_HUD_CITY_OTHER_GROWTH_BONUSES") ..
            ": " .. toPlusMinusString(Round(iOtherPercent, 0)) .. "%"
    end)
    AddLeaf(foodItem, "citizens:food:housingmult", function()
        return Locale.Lookup("LOC_HUD_CITY_HOUSING_MULTIPLIER") .. ": " .. Locale.ToNumber(data.HousingMultiplier)
    end)
    if IsExpansion1Active() or IsExpansion2Active() then
        AddLeaf(foodItem, "citizens:food:loyalty", function()
            local pCity = GetCurrentCity()
            if pCity then
                local pCityGrowth = pCity:GetGrowth()
                local loyaltyModifier = (pCityGrowth:GetLoyaltyGrowthModifier() * 100) - 100
                local cityIdentity = pCity:GetCulturalIdentity()
                local loyaltyLevel = cityIdentity:GetLoyaltyLevel()
                local loyaltyLevelName = GameInfo.LoyaltyLevels[loyaltyLevel].Name
                if Round(loyaltyModifier, 0) ~= 0 then
                    return Locale.Lookup(loyaltyLevelName) .. ": " .. toPlusMinusString(Round(loyaltyModifier, 0)) .. "%"
                else
                    return Locale.Lookup(loyaltyLevelName) ..
                        ": " .. Locale.Lookup("LOC_CULTURAL_IDENTITY_LOYALTY_NO_GROWTH_PENALTY")
                end
            end
            return Locale.Lookup("LOC_HUD_CITY_OCCUPATION_MULTIPLIER") ..
                ": " .. Locale.ToNumber(data.OccupationMultiplier)
        end)
    else
        AddLeaf(foodItem, "citizens:food:occupation", function()
            if data.Occupied then
                local iOccupationPercent = data.OccupationMultiplier * 100
                return Locale.Lookup("LOC_HUD_CITY_OCCUPATION_MULTIPLIER") ..
                    ": " .. Locale.ToNumber(iOccupationPercent) .. "%"
            else
                return Locale.Lookup("LOC_HUD_CITY_OCCUPATION_MULTIPLIER") ..
                    ": " .. Locale.Lookup("LOC_HUD_CITY_NOT_APPLICABLE")
            end
        end)
    end
    AddLeaf(foodItem, "citizens:food:totalfood", function()
        if data.TurnsUntilGrowth > -1 then
            local growthModifier = math.max(1 + (data.HappinessGrowthModifier / 100) + data.OtherGrowthModifiers, 0)
            local iModifiedFood = Round(data.FoodSurplus * growthModifier, 2)
            local total = iModifiedFood * data.HousingMultiplier
            if data.Occupied then
                total = iModifiedFood * data.OccupationMultiplier
            end
            return Locale.Lookup("LOC_HUD_CITY_TOTAL_FOOD_SURPLUS") .. ": " .. toPlusMinusString(total)
        else
            return Locale.Lookup("LOC_HUD_CITY_TOTAL_FOOD_DEFICIT") .. ": " .. toPlusMinusString(data.FoodSurplus)
        end
    end)

    tabItem:AddChild(foodItem)

    -- Amenities subcategory
    local amenitiesItem = MakeTreeItem({
        Label = function()
            local mood = Locale.Lookup(GameInfo.Happinesses[data.Happiness].Name)
            return JoinLines({
                Locale.Lookup("LOC_HUD_CITY_AMENITIES") .. ": " .. mood,
                tostring(data.AmenitiesNum) .. "/" .. tostring(data.AmenitiesRequiredNum),
            })
        end,
        FocusKey = "citizens:amenities",
    })

    AddLeaf(amenitiesItem, "amenity:luxuries", function()
        return FormatSourceLine("LOC_HUD_CITY_AMENITIES_FROM_LUXURIES", data.AmenitiesFromLuxuries)
    end)
    if GameCapabilities.HasCapability("CAPABILITY_CITY_HUD_AMENITIES_CIVICS") then
        AddLeaf(amenitiesItem, "amenity:civics", function()
            return FormatSourceLine("LOC_HUD_CITY_AMENITIES_FROM_CIVICS", data.AmenitiesFromCivics)
        end)
    end
    AddLeaf(amenitiesItem, "amenity:entertainment", function()
        return FormatSourceLine("LOC_HUD_CITY_AMENITIES_FROM_ENTERTAINMENT", data.AmenitiesFromEntertainment)
    end)
    if GameCapabilities.HasCapability("CAPABILITY_CITY_HUD_AMENITIES_GREAT_PEOPLE") then
        AddLeaf(amenitiesItem, "amenity:greatpeople", function()
            return FormatSourceLine("LOC_HUD_CITY_AMENITIES_FROM_GREAT_PEOPLE", data.AmenitiesFromGreatPeople)
        end)
    end
    if GameCapabilities.HasCapability("CAPABILITY_CITY_HUD_AMENITIES_CITY_STATES") then
        AddLeaf(amenitiesItem, "amenity:citystates", function()
            return FormatSourceLine("LOC_HUD_CITY_AMENITIES_FROM_CITY_STATES", data.AmenitiesFromCityStates)
        end)
    end
    if GameCapabilities.HasCapability("CAPABILITY_CITY_HUD_AMENITIES_RELIGION") then
        AddLeaf(amenitiesItem, "amenity:religion", function()
            return FormatSourceLine("LOC_HUD_CITY_AMENITIES_FROM_RELIGION", data.AmenitiesFromReligion)
        end)
    end
    if GameCapabilities.HasCapability("CAPABILITY_CITY_HUD_AMENITIES_NATIONAL_PARKS") then
        AddLeaf(amenitiesItem, "amenity:nationalparks", function()
            return FormatSourceLine("LOC_HUD_CITY_AMENITIES_FROM_NATIONAL_PARKS", data.AmenitiesFromNationalParks)
        end)
    end
    if (data.AmenitiesFromStartingEra or 0) > 0 then
        AddLeaf(amenitiesItem, "amenity:startingera", function()
            return FormatSourceLine("LOC_HUD_CITY_AMENITIES_FROM_STARTING_ERA", data.AmenitiesFromStartingEra)
        end)
    end
    if (data.AmenitiesFromImprovements or 0) > 0 then
        AddLeaf(amenitiesItem, "amenity:improvements", function()
            return FormatSourceLine("LOC_HUD_CITY_AMENITIES_FROM_IMPROVEMENTS", data.AmenitiesFromImprovements)
        end)
    end
    if GameCapabilities.HasCapability("CAPABILITY_CITY_HUD_AMENITIES_WAR_WEARINESS") then
        AddLeaf(amenitiesItem, "amenity:warweariness", function()
            return FormatNegativeSourceLine("LOC_HUD_CITY_AMENITIES_LOST_FROM_WAR_WEARINESS",
                data.AmenitiesLostFromWarWeariness)
        end)
    end
    if GameCapabilities.HasCapability("CAPABILITY_CITY_HUD_AMENITIES_BANKRUPTCY") then
        AddLeaf(amenitiesItem, "amenity:bankruptcy", function()
            return FormatNegativeSourceLine("LOC_HUD_CITY_AMENITIES_LOST_FROM_BANKRUPTCY",
                data.AmenitiesLostFromBankruptcy)
        end)
    end
    if (data.AmenitiesFromDistricts or 0) > 0 then
        AddLeaf(amenitiesItem, "amenity:districts", function()
            return FormatSourceLine("LOC_HUD_CITY_AMENITIES_FROM_DISTRICTS", data.AmenitiesFromDistricts)
        end)
    end
    if (data.AmenitiesFromNaturalWonders or 0) > 0 then
        AddLeaf(amenitiesItem, "amenity:naturalwonders", function()
            return FormatSourceLine("LOC_HUD_CITY_AMENITIES_FROM_NATURAL_WONDERS", data.AmenitiesFromNaturalWonders)
        end)
    end
    if (data.AmenitiesFromTraits or 0) > 0 then
        AddLeaf(amenitiesItem, "amenity:traits", function()
            return FormatSourceLine("LOC_HUD_CITY_AMENITIES_FROM_TRAITS", data.AmenitiesFromTraits)
        end)
    end
    if IsExpansion1Active() or IsExpansion2Active() then
        AddLeaf(amenitiesItem, "amenity:governors", function()
            return FormatSourceLine("LOC_HUD_CITY_AMENITIES_LOST_FROM_GOVERNORS", data.AmenitiesFromGovernors or 0)
        end)
    end
    if not IsEspionageView() and data.AmenityAdvice and data.AmenityAdvice ~= "" then
        AddLeaf(amenitiesItem, "amenity:advice", function()
            return FlattenNewlines(data.AmenityAdvice)
        end)
    end

    tabItem:AddChild(amenitiesItem)

    -- Housing subcategory
    local housingItem = MakeTreeItem({
        Label = function()
            local status
            if data.HousingMultiplier == 0 then
                status = Locale.Lookup("LOC_HUD_CITY_POPULATION_GROWTH_HALTED")
            elseif data.HousingMultiplier <= 0.5 then
                local iPercent = (1 - data.HousingMultiplier) * 100
                status = Locale.Lookup("LOC_HUD_CITY_POPULATION_GROWTH_SLOWED", iPercent)
            else
                status = Locale.Lookup("LOC_HUD_CITY_POPULATION_GROWTH_NORMAL")
            end
            return JoinLines({
                Locale.Lookup("LOC_HUD_CITY_HOUSING") .. ": " .. tostring(data.Housing),
                status,
            })
        end,
        FocusKey = "citizens:housing",
    })

    AddLeaf(housingItem, "housing:buildings", function()
        return FormatSourceLine("LOC_HUD_CITY_HOUSING_FROM_BUILDINGS", data.HousingFromBuildings)
    end)
    AddLeaf(housingItem, "housing:civics", function()
        return FormatSourceLine("LOC_HUD_CITY_HOUSING_FROM_CIVICS", data.HousingFromCivics)
    end)
    if GameCapabilities.HasCapability("CAPABILITY_CITY_HUD_HOUSING_DISTRICTS") then
        AddLeaf(housingItem, "housing:districts", function()
            return FormatSourceLine("LOC_HUD_CITY_HOUSING_FROM_DISTRICTS", data.HousingFromDistricts)
        end)
    end
    AddLeaf(housingItem, "housing:improvements", function()
        return FormatSourceLine("LOC_HUD_CITY_HOUSING_FROM_IMPROVEMENTS", data.HousingFromImprovements)
    end)
    AddLeaf(housingItem, "housing:water", function()
        return FormatSourceLine("LOC_HUD_CITY_HOUSING_FROM_WATER", data.HousingFromWater)
    end)
    if GameCapabilities.HasCapability("CAPABILITY_CITY_HUD_HOUSING_GREAT_PEOPLE") then
        AddLeaf(housingItem, "housing:greatpeople", function()
            return FormatSourceLine("LOC_HUD_CITY_HOUSING_FROM_GREAT_PEOPLE", data.HousingFromGreatPeople)
        end)
    end
    if (data.HousingFromStartingEra or 0) > 0 then
        AddLeaf(housingItem, "housing:startingera", function()
            return FormatSourceLine("LOC_HUD_CITY_HOUSING_FROM_STARTING_ERA", data.HousingFromStartingEra)
        end)
    end
    if (data.HousingFromGreatWorks or 0) > 0 then
        AddLeaf(housingItem, "housing:greatworks", function()
            return FormatSourceLine("LOC_HUD_CITY_HOUSING_FROM_GREATWORKS", data.HousingFromGreatWorks)
        end)
    end
    if not IsEspionageView() and data.HousingAdvice and data.HousingAdvice ~= "" then
        AddLeaf(housingItem, "housing:advice", function()
            return FlattenNewlines(data.HousingAdvice)
        end)
    end

    tabItem:AddChild(housingItem)
    m_ui.tree:AddChild(tabItem)
end

-- ===========================================================================
-- Buildings tab
-- ===========================================================================

local function BuildBuildingsTab(data, city)
    local tabItem = MakeTreeItem({
        Label = function()
            return Locale.Lookup("LOC_CAI_CITY_SECTION_BUILDINGS")
        end,
        Tooltip = function()
            local parts = {}
            local builtCount = 0
            for _, district in ipairs(data.BuildingsAndDistricts) do
                if district.isBuilt then builtCount = builtCount + 1 end
            end
            table.insert(parts, Locale.Lookup("LOC_CAI_CITY_OV_DISTRICTS_BUILT", builtCount))
            if GameCapabilities.HasCapability("CAPABILITY_CITY_HUD_WONDERS") then
                table.insert(parts, Locale.Lookup("LOC_CAI_CITY_OV_WONDERS") .. ": " .. tostring(#data.Wonders))
            end
            if GameCapabilities.HasCapability("CAPABILITY_CITY_HUD_TRADING_POSTS") then
                table.insert(parts,
                    Locale.Lookup("LOC_CAI_CITY_OV_TRADING_POSTS") .. ": " .. tostring(#data.TradingPosts))
            end
            return table.concat(parts, "[NEWLINE]")
        end,
        FocusKey = "tab:buildings",
    })
    tabItem:On("focus_enter", function()
        if m_caiSelectedTab == "tab:buildings" then return end
        m_caiSelectedTab = "tab:buildings"
        m_caiSwitchingTab = true
        OnSelectBuildingsTab()
        m_caiSwitchingTab = false
    end)

    local playerID = Game.GetLocalPlayer()

    -- Districts and buildings
    local builtDistrictCount = 0
    for _, district in ipairs(data.BuildingsAndDistricts) do
        if district.isBuilt then builtDistrictCount = builtDistrictCount + 1 end
    end

    local districtEntries = {}
    for _, district in ipairs(data.BuildingsAndDistricts) do
        if district.isBuilt then
            table.insert(districtEntries, district)
        end
    end

    local districtsFactory = (#districtEntries > 0) and MakeTreeItem or MakeStaticText
    local districtsItem = districtsFactory({
        Label = function()
            return Locale.Lookup("LOC_CAI_CITY_OV_DISTRICTS_BUILT", builtDistrictCount)
        end,
        Tooltip = function()
            return Locale.Lookup("LOC_CAI_CITY_OV_SPECIALTY_DISTRICTS", data.DistrictsNum, data.DistrictsPossibleNum)
        end,
        FocusKey = "buildings:districts",
    })

    for _, district in ipairs(districtEntries) do
        local dType = district.Type or "unknown"
        local buildingEntries = {}
        for _, building in ipairs(district.Buildings) do
            if building.isBuilt then
                table.insert(buildingEntries, building)
            end
        end

        local districtFactory = (#buildingEntries > 0) and MakeTreeItem or MakeStaticText
        local districtItem = districtFactory({
            Label = function()
                local name = district.Name
                if district.isPillaged then
                    name = name .. " (" .. Locale.Lookup("LOC_CAI_CITY_OV_PILLAGED") .. ")"
                end
                return name
            end,
            Tooltip = function()
                return StripTooltipHeader(ToolTipHelper.GetToolTip(dType, playerID))
            end,
            FocusKey = "district:" .. dType,
        })

        for _, building in ipairs(buildingEntries) do
            local bType = building.Type or "unknown"
            AddLeaf(districtItem, "building:" .. bType .. ":" .. dType, function()
                local name = building.Name
                if building.isPillaged then
                    name = name .. " (" .. Locale.Lookup("LOC_CAI_CITY_OV_PILLAGED") .. ")"
                end
                return name
            end, function()
                local pRow = GameInfo.Buildings[bType]
                if pRow then
                    return StripTooltipHeader(ToolTipHelper.GetBuildingToolTip(pRow.Hash, playerID, city))
                end
                return ""
            end)
        end

        districtsItem:AddChild(districtItem)
    end
    tabItem:AddChild(districtsItem)

    -- Wonders
    if GameCapabilities.HasCapability("CAPABILITY_CITY_HUD_WONDERS") then
        if #data.Wonders > 0 then
            local wondersItem = MakeTreeItem({
                Label = function()
                    return Locale.Lookup("LOC_CAI_CITY_OV_WONDERS") .. ": " .. tostring(#data.Wonders)
                end,
                FocusKey = "buildings:wonders",
            })
            for _, wonder in ipairs(data.Wonders) do
                local wType = wonder.Type or "unknown"
                AddLeaf(wondersItem, "wonder:" .. wType, function()
                    return wonder.Name
                end, function()
                    local pRow = GameInfo.Buildings[wType]
                    if pRow then
                        return StripTooltipHeader(ToolTipHelper.GetBuildingToolTip(pRow.Hash, playerID, city))
                    end
                    return ""
                end)
            end
            tabItem:AddChild(wondersItem)
        else
            AddLeaf(tabItem, "buildings:no_wonders", function()
                return Locale.Lookup("LOC_CAI_CITY_OV_NO_WONDERS")
            end)
        end
    end

    -- Trading posts
    if GameCapabilities.HasCapability("CAPABILITY_CITY_HUD_TRADING_POSTS") then
        AddLeaf(tabItem, "buildings:tradingposts", function()
            if #data.TradingPosts == 0 then
                return Locale.Lookup("LOC_CAI_CITY_OV_NO_TRADING_POSTS")
            end
            local localPlayerID = Game.GetLocalPlayer()
            local names = {}
            for _, tradePostPlayerId in ipairs(data.TradingPosts) do
                local pConfig = PlayerConfigurations[tradePostPlayerId]
                local name = Locale.Lookup(pConfig:GetPlayerName())
                if tradePostPlayerId == localPlayerID then
                    name = name .. " (" .. Locale.Lookup("LOC_HUD_CITY_YOU") .. ")"
                end
                table.insert(names, name)
            end
            local parts = { Locale.Lookup("LOC_CAI_CITY_OV_TRADING_POSTS") }
            for _, name in ipairs(names) do
                table.insert(parts, name)
            end
            return JoinLines(parts)
        end)
    end

    m_ui.tree:AddChild(tabItem)
end

-- ===========================================================================
-- Religion tab
-- ===========================================================================

local function BuildReligionTab(data)
    local tabItem = MakeTreeItem({
        Label = function()
            return Locale.Lookup("LOC_CAI_CITY_SECTION_RELIGION")
        end,
        Tooltip = function()
            local parts = {}
            local dominantReligion = data.Religions and data.Religions["_DOMINANTRELIGION"]
            if dominantReligion then
                table.insert(parts,
                    Game.GetReligion():GetName(dominantReligion.ID) .. ": " .. tostring(dominantReligion.Followers))
            end
            if data.PantheonBelief > -1 then
                local kBelief = GameInfo.Beliefs[data.PantheonBelief]
                if kBelief then
                    table.insert(parts,
                        Locale.Lookup("LOC_BELIEF_CLASS_PANTHEON_NAME") .. ": " .. Locale.Lookup(kBelief.Name))
                end
            end
            if #parts == 0 then
                return Locale.Lookup("LOC_CAI_CITY_OV_NO_RELIGION")
            end
            return table.concat(parts, "[NEWLINE]")
        end,
        FocusKey = "tab:religion",
    })
    tabItem:On("focus_enter", function()
        if m_caiSelectedTab == "tab:religion" then return end
        m_caiSelectedTab = "tab:religion"
        m_caiSwitchingTab = true
        OnSelectReligionTab()
        m_caiSwitchingTab = false
    end)

    local isHasReligion = (table.count(data.Religions) > 0) or (data.PantheonBelief > -1)

    if not isHasReligion then
        AddLeaf(tabItem, "religion:none", function()
            return Locale.Lookup("LOC_CAI_CITY_OV_NO_RELIGION")
        end)
        m_ui.tree:AddChild(tabItem)
        return
    end

    -- Pantheon
    if data.PantheonBelief > -1 then
        local kBelief = GameInfo.Beliefs[data.PantheonBelief]
        if kBelief then
            AddLeaf(tabItem, "religion:pantheon", function()
                return Locale.Lookup(kBelief.Name) .. ": " .. Locale.Lookup("LOC_BELIEF_CLASS_PANTHEON_NAME")
            end, function()
                return Locale.Lookup(kBelief.Description)
            end)
        end
    end

    -- Dominant religion
    local dominantReligion = data.Religions and data.Religions["_DOMINANTRELIGION"]
    if dominantReligion then
        local religionName = Game.GetReligion():GetName(dominantReligion.ID)
        local hasBelief = data.BeliefsOfDominantReligion and #data.BeliefsOfDominantReligion > 0

        if hasBelief then
            local domItem = MakeTreeItem({
                Label = function()
                    return Locale.Lookup("LOC_HUD_CITY_RELIGIOUS_CITIZENS_NUMBER", dominantReligion.Followers,
                        religionName)
                end,
                FocusKey = "religion:" .. (dominantReligion.ReligionType or "dominant"),
            })
            for _, beliefIndex in ipairs(data.BeliefsOfDominantReligion) do
                local kBelief = GameInfo.Beliefs[beliefIndex]
                if kBelief then
                    local beliefClass = Locale.Lookup("LOC_" .. kBelief.BeliefClassType .. "_NAME")
                    AddLeaf(domItem, "belief:" .. tostring(beliefIndex), function()
                        return Locale.Lookup(kBelief.Name) .. ": " .. beliefClass
                    end, function()
                        return Locale.Lookup(kBelief.Description)
                    end)
                end
            end
            tabItem:AddChild(domItem)
        else
            AddLeaf(tabItem, "religion:" .. (dominantReligion.ReligionType or "dominant"), function()
                return Locale.Lookup("LOC_HUD_CITY_RELIGIOUS_CITIZENS_NUMBER", dominantReligion.Followers, religionName)
            end)
        end
    end

    -- Other religions
    for _, religion in ipairs(data.Religions) do
        if religion.ReligionType ~= "RELIGION_PANTHEON"
            and (not dominantReligion or religion.ReligionType ~= dominantReligion.ReligionType) then
            local rName = Game.GetReligion():GetName(religion.ID)
            AddLeaf(tabItem, "religion:" .. (religion.ReligionType or "other"), function()
                return Locale.Lookup("LOC_HUD_CITY_RELIGIOUS_CITIZENS_NUMBER", religion.Followers, rName)
            end)
        end
    end

    m_ui.tree:AddChild(tabItem)
end

-- ===========================================================================
-- Loyalty tab (XP1+)
-- ===========================================================================

local function BuildGovernorStatusLine(city)
    local pGovernor = city:GetAssignedGovernor()
    if not pGovernor then
        return Locale.Lookup("LOC_CAI_CITY_OV_NO_GOVERNOR")
    end
    local name = Locale.Lookup(pGovernor:GetName())
    local status
    if pGovernor:IsEstablished() then
        status = Locale.Lookup("LOC_HUD_CITY_GOVERNOR_ESTABLISHED")
    else
        local turnsLeft = pGovernor:GetTurnsToEstablish() - pGovernor:GetTurnsOnSite()
        status = Locale.Lookup("LOC_HUD_CITY_GOVERNOR_TURNS", turnsLeft)
    end
    return Locale.Lookup("LOC_CAI_CITY_OV_GOVERNOR_STATUS", name, status)
end

local function BuildLoyaltyTab(data, city)
    if not city then return end

    local tabItem = MakeTreeItem({
        Label = function()
            return Locale.Lookup("LOC_CAI_CITY_OV_LOYALTY_AND_GOVERNORS")
        end,
        Tooltip = function()
            local pCulturalIdentity = city:GetCulturalIdentity()
            if not pCulturalIdentity then return "" end
            local parts = {}
            local loyalty = Round(pCulturalIdentity:GetLoyalty(), 1)
            local maxLoyalty = pCulturalIdentity:GetMaxLoyalty()
            table.insert(parts, Locale.Lookup("LOC_CAI_CITY_OV_LOYALTY_OF", loyalty, maxLoyalty))
            local loyaltyLevel = pCulturalIdentity:GetLoyaltyLevel()
            local loyaltyLevelInfo = GameInfo.LoyaltyLevels[loyaltyLevel]
            if loyaltyLevelInfo then
                table.insert(parts, Locale.Lookup(loyaltyLevelInfo.Name))
            end
            table.insert(parts,
                Locale.Lookup("LOC_CAI_CITY_OV_LOYALTY_PER_TURN",
                    toPlusMinusString(Round(pCulturalIdentity:GetLoyaltyPerTurn(), 1))))
            table.insert(parts, BuildGovernorStatusLine(city))
            return table.concat(parts, "[NEWLINE]")
        end,
        FocusKey = "tab:loyalty",
    })
    tabItem:On("focus_enter", function()
        if m_caiSelectedTab == "tab:loyalty" then return end
        m_caiSelectedTab = "tab:loyalty"
        m_caiSwitchingTab = true
        OnSelectCultureTab()
        m_caiSwitchingTab = false
    end)

    local pCulturalIdentity = city:GetCulturalIdentity()
    if not pCulturalIdentity then
        m_ui.tree:AddChild(tabItem)
        return
    end

    -- Governor (first)
    local pGovernor = city:GetAssignedGovernor()
    if pGovernor then
        local eType = pGovernor:GetType()
        local govDef = GameInfo.Governors[eType]
        AddLeaf(tabItem, "loyalty:governor", function()
            local name = Locale.Lookup(pGovernor:GetName())
            local title = govDef and Locale.Lookup(govDef.Title) or ""
            local status
            if pGovernor:IsEstablished() then
                status = Locale.Lookup("LOC_HUD_CITY_GOVERNOR_ESTABLISHED")
            else
                local turnsLeft = pGovernor:GetTurnsToEstablish() - pGovernor:GetTurnsOnSite()
                status = Locale.Lookup("LOC_HUD_CITY_GOVERNOR_TURNS", turnsLeft)
            end
            return JoinLines({ name, title, status })
        end, function()
            if govDef then
                return Locale.Lookup(govDef.Description)
            end
            return ""
        end)
    else
        AddLeaf(tabItem, "loyalty:governor", function()
            return Locale.Lookup("LOC_CAI_CITY_OV_NO_GOVERNOR")
        end)
    end

    -- Identity sources (second, sorted highest to lowest)
    local pressureBreakdown = pCulturalIdentity:GetIdentitySourcesDetailedBreakdown()
    if pressureBreakdown and #pressureBreakdown > 0 then
        if #pressureBreakdown > 1 then
            local sourcesItem = MakeTreeItem({
                Label = function()
                    return Locale.Lookup("LOC_CAI_CITY_OV_IDENTITY_SOURCES")
                end,
                FocusKey = "loyalty:sources",
            })
            for i, innerTable in ipairs(pressureBreakdown) do
                local scoreSource, scoreValue = next(innerTable)
                if scoreSource then
                    AddLeaf(sourcesItem, "loyalty:source:" .. tostring(i), function()
                        return scoreSource .. ": " .. toPlusMinusString(Round(scoreValue, 1))
                    end)
                end
            end
            tabItem:AddChild(sourcesItem)
        else
            local scoreSource, scoreValue = next(pressureBreakdown[1])
            if scoreSource then
                AddLeaf(tabItem, "loyalty:source:1", function()
                    return scoreSource .. ": " .. toPlusMinusString(Round(scoreValue, 1))
                end)
            end
        end
    end

    -- Diplomatic influence (third)
    local identitiesInCity = pCulturalIdentity:GetPlayerIdentitiesInCity()
    if identitiesInCity and #identitiesInCity > 0 then
        table.sort(identitiesInCity, function(left, right)
            return left.IdentityTotal > right.IdentityTotal
        end)

        if #identitiesInCity > 1 then
            local influenceItem = MakeTreeItem({
                Label = function()
                    return Locale.Lookup("LOC_CAI_CITY_OV_DIPLOMATIC_INFLUENCE")
                end,
                FocusKey = "loyalty:influence",
            })
            for _, playerPresence in ipairs(identitiesInCity) do
                local pConfig = PlayerConfigurations[playerPresence.Player]
                AddLeaf(influenceItem, "loyalty:influence:" .. tostring(playerPresence.Player), function()
                    local civName = Locale.Lookup(pConfig:GetCivilizationDescription())
                    return civName .. ": " .. tostring(playerPresence.IdentityTotal)
                end)
            end
            tabItem:AddChild(influenceItem)
        else
            local pConfig = PlayerConfigurations[identitiesInCity[1].Player]
            AddLeaf(tabItem, "loyalty:influence:single", function()
                local civName = Locale.Lookup(pConfig:GetCivilizationDescription())
                return civName .. ": " .. tostring(identitiesInCity[1].IdentityTotal)
            end)
        end
    end

    -- Loyalty advice
    if not IsEspionageView() and city.GetLoyaltyAdvice then
        local advice = city:GetLoyaltyAdvice()
        if advice and advice ~= "" then
            AddLeaf(tabItem, "loyalty:advice", function()
                return FlattenNewlines(advice)
            end)
        end
    end

    m_ui.tree:AddChild(tabItem)
end

-- ===========================================================================
-- Power tab (XP2)
-- ===========================================================================

local function BuildPowerTab(data, city)
    if not city then return end

    local tabItem = MakeTreeItem({
        Label = function()
            return Locale.Lookup("LOC_CAI_CITY_OV_POWER")
        end,
        Tooltip = function()
            local pPower = city:GetPower()
            if not pPower then return "" end
            local requiredPower = pPower:GetRequiredPower()
            local parts = {}
            if requiredPower == 0 then
                table.insert(parts, Locale.Lookup("LOC_POWER_STATUS_NO_POWER_NEEDED_NAME"))
            elseif not pPower:IsFullyPowered() then
                table.insert(parts, Locale.Lookup("LOC_POWER_STATUS_UNPOWERED_NAME"))
            else
                table.insert(parts, Locale.Lookup("LOC_POWER_STATUS_POWERED_NAME"))
            end
            local consumed = pPower:GetFreePower() + pPower:GetTemporaryPower()
            table.insert(parts, Locale.Lookup("LOC_POWER_PANEL_CONSUMED", Round(consumed, 1)))
            table.insert(parts, Locale.Lookup("LOC_POWER_PANEL_REQUIRED", Round(requiredPower, 1)))
            if requiredPower == 0 then
                table.insert(parts, Locale.Lookup("LOC_POWER_STATUS_NO_POWER_NEEDED_DESCRIPTION"))
            elseif not pPower:IsFullyPowered() then
                table.insert(parts, Locale.Lookup("LOC_POWER_STATUS_UNPOWERED_DESCRIPTION"))
            else
                table.insert(parts, Locale.Lookup("LOC_POWER_STATUS_POWERED_DESCRIPTION"))
            end
            return table.concat(parts, "[NEWLINE]")
        end,
        FocusKey = "tab:power",
    })
    tabItem:On("focus_enter", function()
        if m_caiSelectedTab == "tab:power" then return end
        m_caiSelectedTab = "tab:power"
        m_caiSwitchingTab = true
        OnSelectPowerTab()
        m_caiSwitchingTab = false
    end)

    local pPower = city:GetPower()
    if not pPower then
        m_ui.tree:AddChild(tabItem)
        return
    end

    local function BuildPowerBreakdown(focusPrefix, labelKey, sources)
        if not sources or #sources == 0 then return end
        if #sources > 1 then
            local breakdownItem = MakeTreeItem({
                Label = function() return Locale.Lookup(labelKey) end,
                FocusKey = focusPrefix,
            })
            for i, innerTable in ipairs(sources) do
                local scoreSource, scoreValue = next(innerTable)
                if scoreSource then
                    AddLeaf(breakdownItem, focusPrefix .. ":" .. tostring(i), function()
                        return scoreSource .. ": " .. Round(scoreValue, 1)
                    end)
                end
            end
            tabItem:AddChild(breakdownItem)
        else
            local scoreSource, scoreValue = next(sources[1])
            if scoreSource then
                AddLeaf(tabItem, focusPrefix .. ":1", function()
                    return Locale.Lookup(labelKey) .. ": " .. scoreSource .. " " .. Round(scoreValue, 1)
                end)
            end
        end
    end

    -- Merge free and temporary power sources for "consumed" breakdown
    local consumedSources = {}
    for _, t in ipairs(pPower:GetFreePowerSources() or {}) do
        table.insert(consumedSources, t)
    end
    for _, t in ipairs(pPower:GetTemporaryPowerSources() or {}) do
        table.insert(consumedSources, t)
    end
    BuildPowerBreakdown("power:consumed_src", "LOC_CAI_CITY_OV_POWER_SOURCES", consumedSources)

    BuildPowerBreakdown("power:required_src", "LOC_CAI_CITY_OV_POWER_REQUIRED_BY",
        pPower:GetRequiredPowerSources())

    BuildPowerBreakdown("power:generated_src", "LOC_CAI_CITY_OV_POWER_GENERATED_BY",
        pPower:GetGeneratedPowerSources())

    -- Power advice
    if not IsEspionageView() and city.GetPowerAdvice then
        local advice = city:GetPowerAdvice()
        if advice and advice ~= "" then
            AddLeaf(tabItem, "power:advice", function()
                return FlattenNewlines(advice)
            end)
        end
    end

    m_ui.tree:AddChild(tabItem)
end

-- ===========================================================================
-- Rename widget
-- ===========================================================================

local function PopRenameEdit()
    mgr:RemoveFromStack(RENAME_EDIT_ID)
end

local function PushRenameEdit()
    local city = GetCurrentCity()
    if not city then return end

    local edit = mgr:CreateWidget(RENAME_EDIT_ID, "EditBox", {
        Label = function() return Locale.Lookup("LOC_CAI_CITY_OV_RENAME") end,
    })
    edit:SetFocusSound(HOVER_SOUND)
    edit:SetAlwaysEdit(true)
    edit:SetHighlightOnEdit(true)
    edit:SetMaxCharacters(32)
    edit:SetText(Locale.Lookup(city:GetName()), true)
    edit:SetValueSetter(function(_, text)
        local c = GetCurrentCity()
        if c and text and text ~= "" then
            RenameCity(c, text)
        end
        PopRenameEdit()
    end)
    edit:AddInputBindings({
        {
            Key = Keys.VK_ESCAPE,
            Description = "LOC_CAI_KB_CLOSE",
            Action = function()
                PopRenameEdit(); return true
            end
        },
    })
    mgr:Push(edit)
end

local function BuildRenameWidget()
    m_ui.rename = mgr:CreateWidget(RENAME_ID, "Button", {
        Label = function()
            local city = GetCurrentCity()
            if city then
                return Locale.Lookup("LOC_CAI_CITY_OV_RENAME") .. ": " .. Locale.Lookup(city:GetName())
            end
            return Locale.Lookup("LOC_CAI_CITY_OV_RENAME")
        end,
        HiddenPredicate = function()
            if not m_caiShowing then return true end
            local city = GetCurrentCity()
            if not city then return true end
            if not GameCapabilities.HasCapability("CAPABILITY_RENAME") then return true end
            if IsEspionageView() then return true end
            if not IsOwnedCity(city) then return true end
            return false
        end,
        FocusKey = "rename",
    })
    m_ui.rename:SetFocusSound(HOVER_SOUND)
    m_ui.rename:On("activate", function() PushRenameEdit() end)
end

-- ===========================================================================
-- Tree building
-- ===========================================================================

local function BuildTree()
    if not m_ui.tree then return end

    local city = GetCurrentCity()
    if not city then return end

    local data = GetCityData(city)
    if not data then return end

    local capture = mgr:CaptureFocusKey(m_ui.tree)
    m_ui.tree:ClearChildren()

    BuildCitizensTab(data, city)
    BuildBuildingsTab(data, city)

    if GameCapabilities.HasCapability("CAPABILITY_CITY_HUD_RELIGION_TAB") then
        BuildReligionTab(data)
    end

    if IsExpansion1Active() or IsExpansion2Active() then
        BuildLoyaltyTab(data, city)
    end

    if IsExpansion2Active() and GameCapabilities.HasCapability("CAPABILITY_LENS_POWER") then
        BuildPowerTab(data, city)
    end

    mgr:RestoreFocus(m_ui.tree, capture)
end

-- ===========================================================================
-- Panel construction and lifecycle
-- ===========================================================================

local function BuildPanel()
    if not mgr then return end

    m_ui.panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function()
            local city = GetCurrentCity()
            if city then
                return Locale.Lookup("LOC_CAI_CITY_OV_PANEL_TITLE", Locale.Lookup(city:GetName()))
            end
            return Locale.Lookup("LOC_HUD_CITY_DETAILS")
        end,
    })

    m_ui.tree = mgr:CreateWidget(TREE_ID, "Tree", {
        Label = function()
            return Locale.Lookup("LOC_HUD_CITY_DETAILS")
        end,
    })
    m_ui.panel:AddChild(m_ui.tree)

    BuildRenameWidget()
    if m_ui.rename then
        m_ui.panel:AddChild(m_ui.rename)
    end
end

local function PushPanel()
    if not mgr then return end
    if not m_ui.panel then BuildPanel() end
    if not m_ui.panel then return end

    BuildTree()

    if not mgr:GetWidgetById(PANEL_ID) then
        mgr:Push(m_ui.panel, { focus = m_caiSelectedTab })
    end
end

local function PopPanel()
    if mgr and m_ui.panel then
        mgr:RemoveFromStack(PANEL_ID)
    end
    m_ui = { panel = nil, tree = nil, rename = nil }
    m_caiSelectedTab = nil
end

-- ===========================================================================
-- Vanilla function wraps
-- ===========================================================================

-- Mirror the espionage view city onto our instance so GetCurrentCity() works.
if OnShowEnemyCityOverview then
    OnShowEnemyCityOverview = WrapFunc(OnShowEnemyCityOverview, function(orig, ownerID, cityID)
        m_caiEspionageVM:SetEspionageViewCity(ownerID, cityID)
        orig(ownerID, cityID)
    end)
end

-- Capture pre-wrap references so we can swap them out of event listeners.
local orig_OnShowOverviewPanel = OnShowOverviewPanel
OnShowOverviewPanel = WrapFunc(OnShowOverviewPanel, function(orig, isShowing)
    orig(isShowing)
    if isShowing then
        m_caiShowing = true
        local city = GetCurrentCity()
        if city then
            PushPanel()
        end
    else
        m_caiShowing = false
        PopPanel()
    end
end)

Close = WrapFunc(Close, function(orig)
    m_caiShowing = false
    m_caiEspionageVM:ClearEspionageViewCity()
    PopPanel()
    orig()
end)

Refresh = WrapFunc(Refresh, function(orig)
    orig()
    if mgr and mgr:GetWidgetById(PANEL_ID) and m_caiShowing then
        BuildTree()
    end
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, input)
    if mgr and mgr:GetWidgetById(PANEL_ID) then
        if mgr:HandleInput(input) then return true end
    end
    return orig(input)
end)

OnShutdown = WrapFunc(OnShutdown, function(orig)
    PopPanel()
    orig()
end)

-- Wrap vanilla tab selectors to track selected tab and sync CAI focus
-- when vanilla switches tabs programmatically (not from our focus_enter).
local function WrapTabSelect(origFn, tabKey)
    if not origFn then return nil end
    return WrapFunc(origFn, function(orig, ...)
        orig(...)
        m_caiSelectedTab = tabKey
        if not m_caiSwitchingTab and m_caiShowing and mgr and m_ui.tree then
            local target = mgr:FindByFocusKey(m_ui.tree, tabKey)
            if target then
                mgr:SetFocus(target, { announce = false })
            end
        end
    end)
end

OnSelectHealthTab    = WrapTabSelect(OnSelectHealthTab, "tab:citizens")
OnSelectBuildingsTab = WrapTabSelect(OnSelectBuildingsTab, "tab:buildings")
OnSelectReligionTab  = WrapTabSelect(OnSelectReligionTab, "tab:religion")
OnSelectCultureTab   = WrapTabSelect(OnSelectCultureTab, "tab:loyalty")
OnSelectPowerTab     = WrapTabSelect(OnSelectPowerTab, "tab:power")

-- Vanilla Initialize() ran during include and captured old function
-- references for SetInitHandler/SetInputHandler/SetShutdown. It also
-- called LateInitialize which registered event listeners with the
-- pre-wrap globals. Re-register everything with our wrapped versions.
ContextPtr:SetInputHandler(OnInputHandler, true)
ContextPtr:SetShutdown(OnShutdown)

LuaEvents.CityPanel_ShowOverviewPanel.Remove(orig_OnShowOverviewPanel)
LuaEvents.CityPanel_ShowOverviewPanel.Add(OnShowOverviewPanel)
