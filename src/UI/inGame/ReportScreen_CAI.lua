include("caiUtils")
include("Civ6Common")
if IsExpansion2Active() then
    include("ReportScreen_Expansion2")
elseif IsExpansion1Active() then
    include("ReportScreen_Expansion1")
else
    include("ReportScreen")
end

local mgr                  = ExposedMembers.CAI_UIManager

local PANEL_ID             = "CAIReports_Panel"
local TABS_ID              = "CAIReports_Tabs"
local HOVER_SOUND          = "Main_Menu_Mouse_Over"

local m_panel              = nil
local m_tabs               = nil
local m_trees              = {}
local m_isExp1             = (IsExpansion1Active ~= nil and IsExpansion1Active())
local m_isExp2             = (IsExpansion2Active ~= nil and IsExpansion2Active())
local m_localPlayerID      = nil

local m_capturedTabs       = {}
local m_isMirroringTab     = false
local m_activeTab          = 1

local m_gossipPlayerFilter = nil
local m_gossipGroupFilter  = nil

local m_caiCityData        = {}
local m_caiCityTotalData   = {}
local m_caiResourceData    = {}
local m_caiUnitData        = {}
local m_caiDealData        = {}
local m_caiGossipLog       = {}
local m_caiGossipFiltered  = {}
local m_caiLeaderFilter    = -1
local m_caiGroupFilter     = "ALL"
local m_cityStatusSort     = "name"

local function RefreshCAIData()
    m_localPlayerID = Game.GetLocalPlayer()
    if m_localPlayerID == -1 then return end
    m_caiCityData, m_caiCityTotalData, m_caiResourceData, m_caiUnitData, m_caiDealData = GetData()
    table.sort(m_caiCityData, function(a, b) return a.Order < b.Order end)
end

local function GatherGossip()
    m_caiGossipLog = {}
    local playerID = m_localPlayerID
    if playerID == nil or playerID == -1 then return end
    local pLocalPlayerDiplomacy = Players[playerID]:GetDiplomacy()
    if pLocalPlayerDiplomacy == nil then return end

    for targetID, kPlayer in pairs(Players) do
        if targetID ~= playerID and kPlayer:IsMajor() and pLocalPlayerDiplomacy:HasMet(targetID) then
            local kAppendTable = Game.GetGossipManager():GetRecentVisibleGossipStrings(0, playerID, targetID)
            for _, entry in pairs(kAppendTable) do
                table.insert(m_caiGossipLog, entry)
            end
        end
    end

    table.sort(m_caiGossipLog, function(a, b) return a[2] > b[2] end)
end

local function FilterCAIGossip()
    m_caiGossipFiltered = {}
    for _, kEntry in ipairs(m_caiGossipLog) do
        local kGossipData = GameInfo.Gossips[kEntry[3]]
        if kGossipData then
            local passLeader = (m_caiLeaderFilter == -1 or kEntry[4] == m_caiLeaderFilter)
            local passGroup = (m_caiGroupFilter == "ALL" or m_caiGroupFilter == kGossipData.GroupType)
            if passLeader and passGroup then
                table.insert(m_caiGossipFiltered, kEntry)
            end
        end
    end
end


local function MakeId(prefix)
    return mgr:GenerateWidgetId(prefix)
end

local function MakeTreeItem(props)
    local item = mgr:CreateWidget(MakeId("CAIRPT_"), "TreeItem", props)
    item:SetFocusSound(HOVER_SOUND)
    return item
end

local function MakeButton(props)
    local btn = mgr:CreateWidget(MakeId("CAIRPT_"), "Button", props)
    btn:SetFocusSound(HOVER_SOUND)
    return btn
end

local function AddLeaf(parent, focusKey, labelFn, tooltipFn)
    local item = MakeTreeItem({
        Label = labelFn,
        Tooltip = tooltipFn,
        FocusKey = focusKey,
    })
    parent:AddChild(item)
    return item
end

local function FormatYields(production, food, gold, faith, science, culture, tourism)
    local parts = {}
    if production and production ~= 0 then
        table.insert(parts, Locale.Lookup("LOC_CAI_REPORTS_YIELD_PRODUCTION", production))
    end
    if food and food ~= 0 then
        table.insert(parts, Locale.Lookup("LOC_CAI_REPORTS_YIELD_FOOD", food))
    end
    if gold and gold ~= 0 then
        table.insert(parts, Locale.Lookup("LOC_CAI_REPORTS_YIELD_GOLD", gold))
    end
    if faith and faith ~= 0 then
        table.insert(parts, Locale.Lookup("LOC_CAI_REPORTS_YIELD_FAITH", faith))
    end
    if science and science ~= 0 then
        table.insert(parts, Locale.Lookup("LOC_CAI_REPORTS_YIELD_SCIENCE", science))
    end
    if culture and culture ~= 0 then
        table.insert(parts, Locale.Lookup("LOC_CAI_REPORTS_YIELD_CULTURE", culture))
    end
    if tourism and tourism ~= 0 then
        table.insert(parts, Locale.Lookup("LOC_CAI_REPORTS_YIELD_TOURISM", tourism))
    end
    if #parts == 0 then return "" end
    return table.concat(parts, ", ")
end

local function toPlusMinus(val)
    if val == nil or val == 0 then return "0" end
    if val > 0 then return "+" .. tostring(val) end
    return tostring(val)
end

local function ActivateCity(pCity)
    if pCity == nil then return end
    local ownerID = pCity:GetOwner()
    if ownerID == m_localPlayerID then
        UI.SelectCity(pCity)
        Close()
    else
        UI.LookAtPlot(pCity:GetX(), pCity:GetY())
        Close()
    end
end

local function GetGrowthStatus(kCityData)
    if kCityData.HousingMultiplier == 0 or kCityData.Occupied then
        return Locale.Lookup("LOC_HUD_REPORTS_STATUS_HALTED")
    elseif kCityData.HousingMultiplier <= 0.5 then
        return Locale.Lookup("LOC_HUD_REPORTS_STATUS_SLOWED")
    else
        if kCityData.HappinessGrowthModifier > 0 then
            return Locale.Lookup("LOC_HUD_REPORTS_STATUS_ACCELERATED")
        else
            return Locale.Lookup("LOC_HUD_REPORTS_STATUS_NORMAL")
        end
    end
end


-- ============================================================================
-- Yields Tab
-- ============================================================================
local function RebuildYieldsTree(tree)
    local capture = mgr:CaptureFocusKey(tree)
    tree:ClearChildren()

    -- City Income group
    local cityIncomeGroup = MakeTreeItem({
        Label = function() return Locale.Lookup("LOC_HUD_REPORTS_ROW_CITY_INCOME") end,
        FocusKey = "yield:group:cityincome",
    })
    tree:AddChild(cityIncomeGroup)

    for _, kCityData in ipairs(m_caiCityData) do
        local capturedCity = kCityData
        local cityID = capturedCity.City:GetID()

        local cityItem = MakeTreeItem({
            Label = function()
                local name = Locale.Lookup(capturedCity.CityName)
                if capturedCity.IsCapital then
                    name = name .. ", " .. Locale.Lookup("LOC_CAI_CITY_STATUS_CAPITAL")
                end
                local kProd = capturedCity.ProductionQueue[1]
                if kProd then
                    name = name .. ", " .. Locale.Lookup("LOC_CAI_REPORTS_PRODUCING", Locale.Lookup(kProd.Name))
                    if capturedCity.CurrentTurnsLeft and capturedCity.CurrentTurnsLeft > 0 then
                        name = name .. ", " .. Locale.Lookup("LOC_CAI_PRODUCTION_TURNS", capturedCity.CurrentTurnsLeft)
                    end
                end
                return name
            end,
            Tooltip = function()
                return FormatYields(
                    capturedCity.ProductionPerTurn,
                    capturedCity.FoodPerTurn,
                    capturedCity.GoldPerTurn,
                    capturedCity.FaithPerTurn,
                    capturedCity.SciencePerTurn,
                    capturedCity.CulturePerTurn,
                    capturedCity.WorkedTileYields["TOURISM"]
                )
            end,
            FocusKey = "yield:city:" .. cityID,
        })
        cityItem:On("activate", function()
            ActivateCity(capturedCity.City)
        end)
        cityIncomeGroup:AddChild(cityItem)

        local greatWorks = GetGreatWorksForCity(capturedCity.City)

        for _, kDistrict in ipairs(capturedCity.BuildingsAndDistricts) do
            local capturedDistrict = kDistrict
            local districtItem = MakeTreeItem({
                Label = function()
                    local yieldStr = FormatYields(
                        capturedDistrict.Production, capturedDistrict.Food,
                        capturedDistrict.Gold, capturedDistrict.Faith,
                        capturedDistrict.Science, capturedDistrict.Culture, nil)
                    if yieldStr ~= "" then
                        return Locale.Lookup(capturedDistrict.Name) .. ", " .. yieldStr
                    end
                    return Locale.Lookup(capturedDistrict.Name)
                end,
                FocusKey = "yield:city:" .. cityID .. ":dist:" .. tostring(capturedDistrict.Type),
            })
            cityItem:AddChild(districtItem)

            if capturedDistrict.AdjacencyBonus then
                local hasAdj = false
                for _, val in pairs(capturedDistrict.AdjacencyBonus) do
                    if val ~= 0 then
                        hasAdj = true; break
                    end
                end
                if hasAdj then
                    local capturedAdj = capturedDistrict.AdjacencyBonus
                    AddLeaf(districtItem,
                        "yield:city:" .. cityID .. ":dist:" .. tostring(capturedDistrict.Type) .. ":adj",
                        function()
                            return Locale.Lookup("LOC_HUD_REPORTS_ADJACENCY_BONUS") .. ", " ..
                                FormatYields(
                                    capturedAdj.Production, capturedAdj.Food,
                                    capturedAdj.Gold, capturedAdj.Faith,
                                    capturedAdj.Science, capturedAdj.Culture, nil)
                        end)
                end
            end

            for _, kBuilding in ipairs(capturedDistrict.Buildings) do
                local capturedBuilding = kBuilding
                AddLeaf(districtItem,
                    "yield:city:" .. cityID .. ":bldg:" .. tostring(capturedBuilding.Type),
                    function()
                        local yieldStr = FormatYields(
                            capturedBuilding.ProductionPerTurn, capturedBuilding.FoodPerTurn,
                            capturedBuilding.GoldPerTurn, capturedBuilding.FaithPerTurn,
                            capturedBuilding.SciencePerTurn, capturedBuilding.CulturePerTurn, nil)
                        if yieldStr ~= "" then
                            return Locale.Lookup(capturedBuilding.Name) .. ", " .. yieldStr
                        end
                        return Locale.Lookup(capturedBuilding.Name)
                    end)

                if greatWorks[capturedBuilding.Type] then
                    for gwIdx, kGreatWork in ipairs(greatWorks[capturedBuilding.Type]) do
                        local capturedGW = kGreatWork
                        local capturedGWIdx = gwIdx
                        AddLeaf(districtItem,
                            "yield:city:" ..
                            cityID .. ":bldg:" .. tostring(capturedBuilding.Type) .. ":gw:" .. capturedGWIdx,
                            function()
                                local gwYields = {}
                                for _, yield in ipairs(capturedGW.YieldChanges) do
                                    if yield.YieldChange ~= 0 then
                                        local yieldInfo = GameInfo.Yields[yield.YieldType]
                                        if yieldInfo then
                                            table.insert(gwYields,
                                                Locale.Lookup(yieldInfo.Name) .. " " .. toPlusMinus(yield.YieldChange))
                                        end
                                    end
                                end
                                local text = Locale.Lookup(capturedGW.Name)
                                if #gwYields > 0 then
                                    text = text .. ", " .. table.concat(gwYields, ", ")
                                end
                                return text
                            end)
                    end
                end
            end
        end

        if capturedCity.Wonders then
            for _, wonder in ipairs(capturedCity.Wonders) do
                local capturedWonder = wonder
                if capturedWonder.Yields[1] or (greatWorks[capturedWonder.Type]) then
                    local wonderItem = MakeTreeItem({
                        Label = function()
                            local parts = {}
                            for _, yield in ipairs(capturedWonder.Yields) do
                                if yield.YieldChange ~= 0 then
                                    local yieldInfo = GameInfo.Yields[yield.YieldType]
                                    if yieldInfo then
                                        table.insert(parts,
                                            Locale.Lookup(yieldInfo.Name) .. " " .. toPlusMinus(yield.YieldChange))
                                    end
                                end
                            end
                            local text = Locale.Lookup(capturedWonder.Name)
                            if #parts > 0 then
                                text = text .. ", " .. table.concat(parts, ", ")
                            end
                            return text
                        end,
                        FocusKey = "yield:city:" .. cityID .. ":wonder:" .. tostring(capturedWonder.Type),
                    })
                    cityItem:AddChild(wonderItem)

                    if greatWorks[capturedWonder.Type] then
                        for gwIdx, kGreatWork in ipairs(greatWorks[capturedWonder.Type]) do
                            local capturedGW = kGreatWork
                            local capturedGWIdx = gwIdx
                            AddLeaf(wonderItem,
                                "yield:city:" ..
                                cityID .. ":wonder:" .. tostring(capturedWonder.Type) .. ":gw:" .. capturedGWIdx,
                                function()
                                    local gwYields = {}
                                    for _, yield in ipairs(capturedGW.YieldChanges) do
                                        if yield.YieldChange ~= 0 then
                                            local yieldInfo = GameInfo.Yields[yield.YieldType]
                                            if yieldInfo then
                                                table.insert(gwYields,
                                                    Locale.Lookup(yieldInfo.Name) ..
                                                    " " .. toPlusMinus(yield.YieldChange))
                                            end
                                        end
                                    end
                                    local text = Locale.Lookup(capturedGW.Name)
                                    if #gwYields > 0 then
                                        text = text .. ", " .. table.concat(gwYields, ", ")
                                    end
                                    return text
                                end)
                        end
                    end
                end
            end
        end

        if capturedCity.OutgoingRoutes then
            for ri, route in ipairs(capturedCity.OutgoingRoutes) do
                if route and route.OriginYields then
                    local capturedRoute = route
                    local capturedRI = ri
                    AddLeaf(cityItem,
                        "yield:city:" .. cityID .. ":route:" .. capturedRI,
                        function()
                            local pDestPlayer = Players[capturedRoute.DestinationCityPlayer]
                            local pDestPlayerCities = pDestPlayer:GetCities()
                            local pDestCity = pDestPlayerCities:FindID(capturedRoute.DestinationCityID)
                            local destName = pDestCity and Locale.Lookup(pDestCity:GetName()) or "?"
                            local routeYields = {}
                            for _, yield in ipairs(capturedRoute.OriginYields) do
                                local yieldInfo = GameInfo.Yields[yield.YieldIndex]
                                if yieldInfo and yield.Amount ~= 0 then
                                    table.insert(routeYields,
                                        Locale.Lookup(yieldInfo.Name) .. " " .. toPlusMinus(yield.Amount))
                                end
                            end
                            local text = Locale.Lookup("LOC_HUD_REPORTS_TRADE_WITH", destName)
                            if #routeYields > 0 then
                                text = text .. ", " .. table.concat(routeYields, ", ")
                            end
                            return text
                        end)
                end
            end
        end

        AddLeaf(cityItem,
            "yield:city:" .. cityID .. ":worked",
            function()
                return Locale.Lookup("LOC_HUD_REPORTS_WORKED_TILES") .. ", " ..
                    FormatYields(
                        capturedCity.WorkedTileYields["YIELD_PRODUCTION"],
                        capturedCity.WorkedTileYields["YIELD_FOOD"],
                        capturedCity.WorkedTileYields["YIELD_GOLD"],
                        capturedCity.WorkedTileYields["YIELD_FAITH"],
                        capturedCity.WorkedTileYields["YIELD_SCIENCE"],
                        capturedCity.WorkedTileYields["YIELD_CULTURE"],
                        nil)
            end)

        if capturedCity.City:GetGrowth() ~= nil and capturedCity.City:GetGrowth():GetHappiness() ~= 4 then
            local capturedCityForAmenity = capturedCity
            local amenityMod = capturedCityForAmenity.HappinessNonFoodYieldModifier
            if amenityMod and amenityMod ~= 0 then
                AddLeaf(cityItem,
                    "yield:city:" .. cityID .. ":amenity",
                    function()
                        local iYieldPercent = (Round(1 + (amenityMod / 100), 2) * .1)
                        return Locale.Lookup("LOC_HUD_REPORTS_HEADER_AMENITIES") .. ", " ..
                            FormatYields(
                                capturedCityForAmenity.WorkedTileYields["YIELD_PRODUCTION"] * iYieldPercent,
                                nil,
                                capturedCityForAmenity.WorkedTileYields["YIELD_GOLD"] * iYieldPercent,
                                capturedCityForAmenity.WorkedTileYields["YIELD_FAITH"] * iYieldPercent,
                                capturedCityForAmenity.WorkedTileYields["YIELD_SCIENCE"] * iYieldPercent,
                                capturedCityForAmenity.WorkedTileYields["YIELD_CULTURE"] * iYieldPercent,
                                nil)
                    end)
            end
        end

        local populationToCultureScale = GameInfo.GlobalParameters["CULTURE_PERCENTAGE_YIELD_PER_POP"].Value / 100
        local capturedCityForPop = capturedCity
        local popCulture = capturedCityForPop.Population * populationToCultureScale
        if popCulture > 0 then
            AddLeaf(cityItem,
                "yield:city:" .. cityID .. ":popculture",
                function()
                    return Locale.Lookup("LOC_HUD_CITY_POPULATION") .. ", " ..
                        Locale.Lookup("LOC_CAI_REPORTS_YIELD_CULTURE", Round(popCulture, 1))
                end)
        end
    end

    -- Building Expenses group — compute total first so the label can show it
    local iTotalBuildingMaintenance = 0
    for _, kCityData in ipairs(m_caiCityData) do
        for _, kBuilding in ipairs(kCityData.Buildings) do
            if kBuilding.Maintenance > 0 and kBuilding.isPillaged == false then
                iTotalBuildingMaintenance = iTotalBuildingMaintenance + kBuilding.Maintenance
            end
        end
        for _, kDistrict in ipairs(kCityData.BuildingsAndDistricts) do
            if kDistrict.Maintenance > 0 and kDistrict.isPillaged == false and kDistrict.isBuilt == true then
                iTotalBuildingMaintenance = iTotalBuildingMaintenance + kDistrict.Maintenance
            end
        end
    end

    local buildingExpGroup = MakeTreeItem({
        Label = function()
            return Locale.Lookup("LOC_HUD_REPORTS_ROW_BUILDING_EXPENSES") .. ", " ..
                Locale.Lookup("LOC_CAI_REPORTS_YIELD_GOLD", -iTotalBuildingMaintenance)
        end,
        FocusKey = "yield:group:buildingexp",
    })
    tree:AddChild(buildingExpGroup)

    local expByType = {}
    for _, kCityData in ipairs(m_caiCityData) do
        local cityName = kCityData.CityName
        for _, kBuilding in ipairs(kCityData.Buildings) do
            if kBuilding.Maintenance > 0 and kBuilding.isPillaged == false then
                local key = tostring(kBuilding.Type)
                if not expByType[key] then
                    expByType[key] = { Name = kBuilding.Name, Total = 0, Entries = {} }
                end
                expByType[key].Total = expByType[key].Total + kBuilding.Maintenance
                table.insert(expByType[key].Entries, { CityName = cityName, Maintenance = kBuilding.Maintenance })
            end
        end
        for _, kDistrict in ipairs(kCityData.BuildingsAndDistricts) do
            if kDistrict.Maintenance > 0 and kDistrict.isPillaged == false and kDistrict.isBuilt == true then
                local key = tostring(kDistrict.Type)
                if not expByType[key] then
                    expByType[key] = { Name = kDistrict.Name, Total = 0, Entries = {} }
                end
                expByType[key].Total = expByType[key].Total + kDistrict.Maintenance
                table.insert(expByType[key].Entries, { CityName = cityName, Maintenance = kDistrict.Maintenance })
            end
        end
    end

    local sortedExpTypes = {}
    for key, data in pairs(expByType) do
        table.insert(sortedExpTypes, { key = key, data = data })
    end
    table.sort(sortedExpTypes, function(a, b)
        return a.data.Total > b.data.Total
    end)

    for _, typeEntry in ipairs(sortedExpTypes) do
        local capturedData = typeEntry.data
        local capturedKey = typeEntry.key
        local typeItem = MakeTreeItem({
            Label = function()
                return Locale.Lookup(capturedData.Name) .. ", " ..
                    Locale.Lookup("LOC_CAI_REPORTS_YIELD_GOLD", -capturedData.Total)
            end,
            FocusKey = "yield:bldgexp:type:" .. capturedKey,
        })
        buildingExpGroup:AddChild(typeItem)

        for ei, entry in ipairs(capturedData.Entries) do
            local capturedEntry = entry
            local capturedEI = ei
            AddLeaf(typeItem,
                "yield:bldgexp:type:" .. capturedKey .. ":city:" .. capturedEI,
                function()
                    return Locale.Lookup(capturedEntry.CityName) .. ", " ..
                        Locale.Lookup("LOC_CAI_REPORTS_YIELD_GOLD", -capturedEntry.Maintenance)
                end)
        end
    end

    -- Unit Expenses group
    if GameCapabilities.HasCapability("CAPABILITY_REPORTS_UNIT_EXPENSES") then
        local unitExpGroup = MakeTreeItem({
            Label = function()
                local total = 0
                for _, kUnitData in pairs(m_caiUnitData) do
                    total = total + kUnitData.Maintenance
                end
                return Locale.Lookup("LOC_HUD_REPORTS_ROW_UNIT_EXPENSES") .. ", " ..
                    Locale.Lookup("LOC_CAI_REPORTS_YIELD_GOLD", -total)
            end,
            FocusKey = "yield:group:unitexp",
        })
        tree:AddChild(unitExpGroup)

        local sortedUnits = {}
        for unitType, kUnitData in pairs(m_caiUnitData) do
            table.insert(sortedUnits, { type = unitType, data = kUnitData })
        end
        table.sort(sortedUnits, function(a, b) return a.data.Maintenance > b.data.Maintenance end)

        for _, unitEntry in ipairs(sortedUnits) do
            local capturedUnit = unitEntry.data
            local capturedType = unitEntry.type
            AddLeaf(unitExpGroup,
                "yield:unitexp:" .. capturedType,
                function()
                    return Locale.Lookup(capturedUnit.Name) .. ", " ..
                        Locale.Lookup("LOC_CAI_REPORTS_UNIT_COUNT", capturedUnit.Count) .. ", " ..
                        Locale.Lookup("LOC_CAI_REPORTS_YIELD_GOLD", -capturedUnit.Maintenance)
                end)
        end
    end

    -- Diplomatic Deals group
    if GameCapabilities.HasCapability("CAPABILITY_REPORTS_DIPLOMATIC_DEALS") then
        local dealGroup = MakeTreeItem({
            Label = function() return Locale.Lookup("LOC_HUD_REPORTS_ROW_DIPLOMATIC_DEALS") end,
            FocusKey = "yield:group:deals",
        })
        tree:AddChild(dealGroup)

        for di, kDeal in ipairs(m_caiDealData) do
            if kDeal.Type == DealItemTypes.GOLD then
                local capturedDeal = kDeal
                local capturedDI = di
                AddLeaf(dealGroup,
                    "yield:deal:" .. capturedDI,
                    function()
                        local amtStr
                        if capturedDeal.IsOutgoing then
                            amtStr = Locale.Lookup("LOC_CAI_REPORTS_YIELD_GOLD", -capturedDeal.Amount)
                        else
                            amtStr = Locale.Lookup("LOC_CAI_REPORTS_YIELD_GOLD", capturedDeal.Amount)
                        end
                        return capturedDeal.Name .. ", " ..
                            Locale.Lookup("LOC_REPORTS_NUMBER_OF_TURNS", capturedDeal.Duration) .. ", " ..
                            amtStr
                    end)
            end
        end
    end

    -- Empire Economy
    local localPlayer = Players[m_localPlayerID]
    if localPlayer then
        local economyGroup = MakeTreeItem({
            Label = function() return Locale.Lookup("LOC_CAI_REPORTS_EMPIRE_ECONOMY") end,
            Tooltip = function()
                local playerTreasury = localPlayer:GetTreasury()
                local playerReligion = localPlayer:GetReligion()
                local playerTechs = localPlayer:GetTechs()
                local playerCulture = localPlayer:GetCulture()
                local goldNet = playerTreasury:GetGoldYield() - playerTreasury:GetTotalMaintenance()
                local parts = {}
                table.insert(parts, Locale.Lookup("LOC_CAI_REPORTS_YIELD_GOLD", toPlusMinus(Round(goldNet, 1))))
                table.insert(parts, Locale.Lookup("LOC_CAI_REPORTS_YIELD_FAITH",
                    toPlusMinus(Round(playerReligion:GetFaithYield(), 1))))
                table.insert(parts, Locale.Lookup("LOC_CAI_REPORTS_YIELD_SCIENCE",
                    toPlusMinus(Round(playerTechs:GetScienceYield(), 1))))
                table.insert(parts, Locale.Lookup("LOC_CAI_REPORTS_YIELD_CULTURE",
                    toPlusMinus(Round(playerCulture:GetCultureYield(), 1))))
                table.insert(parts, Locale.Lookup("LOC_CAI_REPORTS_YIELD_TOURISM",
                    toPlusMinus(Round(m_caiCityTotalData.Income["TOURISM"] or 0, 1))))
                return table.concat(parts, ", ")
            end,
            FocusKey = "yield:economy",
        })
        tree:AddChild(economyGroup)

        AddLeaf(economyGroup, "yield:economy:gold",
            function()
                local playerTreasury = localPlayer:GetTreasury()
                local goldIncome = playerTreasury:GetGoldYield()
                local goldExpense = playerTreasury:GetTotalMaintenance()
                local goldNet = goldIncome - goldExpense
                return Locale.Lookup("LOC_CAI_REPORTS_GOLD_BREAKDOWN",
                    toPlusMinus(Round(goldIncome, 1)),
                    toPlusMinus(Round(-goldExpense, 1)),
                    toPlusMinus(Round(goldNet, 1)),
                    Round(m_caiCityTotalData.Treasury[YieldTypes.GOLD] or 0, 1))
            end)

        AddLeaf(economyGroup, "yield:economy:faith",
            function()
                local playerReligion = localPlayer:GetReligion()
                return Locale.Lookup("LOC_CAI_REPORTS_FAITH_BREAKDOWN",
                    toPlusMinus(Round(playerReligion:GetFaithYield(), 1)),
                    Round(m_caiCityTotalData.Treasury[YieldTypes.FAITH] or 0, 1))
            end)

        AddLeaf(economyGroup, "yield:economy:science",
            function()
                local playerTechs = localPlayer:GetTechs()
                return Locale.Lookup("LOC_CAI_REPORTS_SCIENCE_INCOME",
                    toPlusMinus(Round(playerTechs:GetScienceYield(), 1)))
            end)

        AddLeaf(economyGroup, "yield:economy:culture",
            function()
                local playerCulture = localPlayer:GetCulture()
                return Locale.Lookup("LOC_CAI_REPORTS_CULTURE_INCOME",
                    toPlusMinus(Round(playerCulture:GetCultureYield(), 1)))
            end)

        AddLeaf(economyGroup, "yield:economy:tourism",
            function()
                return Locale.Lookup("LOC_CAI_REPORTS_TOURISM_INCOME",
                    toPlusMinus(Round(m_caiCityTotalData.Income["TOURISM"] or 0, 1)))
            end)
    end

    mgr:RestoreFocus(tree, capture)
end


-- ============================================================================
-- Resources Tab
-- ============================================================================
local function GetXP2ResourceFlowData(eResourceType)
    local localPlayer = Players[m_localPlayerID]
    if not localPlayer then return nil end
    local pResources = localPlayer:GetResources()
    if not pResources then return nil end
    local kResource = GameInfo.Resources[eResourceType]
    if not kResource then return nil end

    local accumulation = pResources:GetResourceAccumulationPerTurn(kResource.ResourceType)
    local unitCost = pResources:GetUnitResourceDemandPerTurn(kResource.Hash)
    local powerCost = pResources:GetPowerResourceDemandPerTurn(kResource.Hash)
    local reserved = pResources:GetReservedResourceAmount(kResource.Hash)
    local imports = pResources:GetResourceImportPerTurn(kResource.Hash)
    local delta = accumulation - unitCost - powerCost

    return {
        Accumulation = accumulation,
        UnitCost = unitCost,
        PowerCost = powerCost,
        Reserved = reserved,
        Imports = imports,
        Delta = delta,
    }
end

local function BuildResourceItem(parent, eResourceType, kSingleResourceData)
    local capturedResType = eResourceType
    local capturedResData = kSingleResourceData
    local kResource = GameInfo.Resources[capturedResType]

    local resItem = MakeTreeItem({
        Label = function()
            local name = Locale.Lookup(kResource.Name)
            if m_isExp2 and capturedResData.IsStrategic and capturedResData.Stockpile then
                local text = Locale.Lookup("LOC_CAI_REPORTS_RESOURCE_STOCKPILE",
                    name, capturedResData.Stockpile, capturedResData.Maximum or 0)
                local flow = GetXP2ResourceFlowData(capturedResType)
                if flow then
                    text = text .. ", " .. Locale.Lookup("LOC_HUD_REPORTS_PER_TURN", toPlusMinus(flow.Delta))
                end
                return text
            else
                return Locale.Lookup("LOC_CAI_REPORTS_RESOURCE_TOTAL", name, capturedResData.Total)
            end
        end,
        Tooltip = function()
            local localPlayer = Players[m_localPlayerID]
            if localPlayer then
                local citiesProvidedTo = localPlayer:GetResources():GetResourceAllocationCities(kResource.Index)
                local numCities = table.count(citiesProvidedTo)
                if numCities > 0 then
                    local cityNames = {}
                    local playerCities = localPlayer:GetCities()
                    for _, city in ipairs(citiesProvidedTo) do
                        local pCity = playerCities:FindID(city.CityID)
                        if pCity then
                            table.insert(cityNames, Locale.Lookup(pCity:GetName()))
                        end
                    end
                    return Locale.Lookup("LOC_CAI_REPORTS_AMENITIES_PROVIDED", numCities)
                        .. ": " .. table.concat(cityNames, ", ")
                end
            end
            return nil
        end,
        FocusKey = "res:" .. tostring(capturedResType),
    })
    parent:AddChild(resItem)

    for ei, kEntry in ipairs(capturedResData.EntryList) do
        local capturedEntry = kEntry
        local capturedEI = ei
        AddLeaf(resItem,
            "res:" .. tostring(capturedResType) .. ":entry:" .. capturedEI,
            function()
                local source = Locale.Lookup(capturedEntry.EntryText)
                local amt = capturedEntry.Amount
                local amtStr = (amt <= 0) and tostring(amt) or ("+" .. tostring(amt))
                return source .. ", " .. amtStr
            end)
    end
end

local function RebuildResourcesTree(tree)
    local capture = mgr:CaptureFocusKey(tree)
    tree:ClearChildren()

    local strategic = {}
    local luxury = {}
    local bonus = {}

    for eResourceType, kSingleResourceData in pairs(m_caiResourceData) do
        if next(kSingleResourceData.EntryList) or
            (m_isExp2 and kSingleResourceData.IsStrategic and kSingleResourceData.Stockpile and kSingleResourceData.Stockpile > 0) then
            if kSingleResourceData.IsStrategic then
                table.insert(strategic, { type = eResourceType, data = kSingleResourceData })
            elseif kSingleResourceData.IsLuxury then
                table.insert(luxury, { type = eResourceType, data = kSingleResourceData })
            else
                table.insert(bonus, { type = eResourceType, data = kSingleResourceData })
            end
        end
    end

    local function sortByName(a, b)
        return Locale.Lookup(GameInfo.Resources[a.type].Name) < Locale.Lookup(GameInfo.Resources[b.type].Name)
    end
    table.sort(strategic, sortByName)
    table.sort(luxury, sortByName)
    table.sort(bonus, sortByName)

    local categories = {
        { key = "strategic", label = "LOC_RESOURCECLASS_STRATEGIC_NAME", items = strategic },
        { key = "luxury",    label = "LOC_RESOURCECLASS_LUXURY_NAME",    items = luxury },
        { key = "bonus",     label = "LOC_RESOURCECLASS_BONUS_NAME",     items = bonus },
    }

    for _, cat in ipairs(categories) do
        if #cat.items > 0 then
            local capturedCat = cat
            local catGroup = MakeTreeItem({
                Label = function()
                    return Locale.Lookup(capturedCat.label) .. ", " ..
                        Locale.Lookup("LOC_CAI_REPORTS_RESOURCE_COUNT", #capturedCat.items)
                end,
                FocusKey = "res:group:" .. capturedCat.key,
            })
            tree:AddChild(catGroup)

            for _, entry in ipairs(capturedCat.items) do
                BuildResourceItem(catGroup, entry.type, entry.data)
            end
        end
    end

    mgr:RestoreFocus(tree, capture)
end


-- ============================================================================
-- City Status Tab
-- ============================================================================
local function GetCityLoyalty(kCityData)
    if not (m_isExp1 or m_isExp2) then return 0 end
    local pCulturalIdentity = kCityData.City:GetCulturalIdentity()
    if pCulturalIdentity then return pCulturalIdentity:GetLoyalty() end
    return 0
end

local function GetSortedCityData()
    local sorted = {}
    for _, kCityData in ipairs(m_caiCityData) do
        table.insert(sorted, kCityData)
    end
    if m_cityStatusSort == "population" then
        table.sort(sorted, function(a, b) return a.Population > b.Population end)
    elseif m_cityStatusSort == "defense" then
        table.sort(sorted, function(a, b) return a.Defense > b.Defense end)
    elseif m_cityStatusSort == "happiness" then
        table.sort(sorted, function(a, b) return a.Happiness > b.Happiness end)
    elseif m_cityStatusSort == "growth" then
        table.sort(sorted, function(a, b) return a.HousingMultiplier > b.HousingMultiplier end)
    elseif m_cityStatusSort == "loyalty" then
        table.sort(sorted, function(a, b) return GetCityLoyalty(a) > GetCityLoyalty(b) end)
    else
        table.sort(sorted, function(a, b)
            return Locale.Lookup(a.CityName) < Locale.Lookup(b.CityName)
        end)
    end
    return sorted
end

local function RebuildCityStatusList(list)
    local capture = mgr:CaptureFocusKey(list)
    list:ClearChildren()

    local sortedCities = GetSortedCityData()

    for _, kCityData in ipairs(sortedCities) do
        local capturedCity = kCityData

        local btn = MakeButton({
            Label = function()
                local parts = {}
                local cityLabel = Locale.Lookup(capturedCity.CityName)
                if capturedCity.IsCapital then
                    cityLabel = cityLabel .. ", " .. Locale.Lookup("LOC_CAI_CITY_STATUS_CAPITAL")
                end
                table.insert(parts, cityLabel)
                table.insert(parts,
                    Locale.Lookup("LOC_CAI_REPORTS_POPULATION", capturedCity.Population, capturedCity.Housing))

                local growthStatus = GetGrowthStatus(capturedCity)
                table.insert(parts, Locale.Lookup("LOC_CAI_REPORTS_GROWTH", growthStatus))

                table.insert(parts, Locale.Lookup("LOC_CAI_REPORTS_AMENITIES",
                    capturedCity.AmenitiesNum, capturedCity.AmenitiesRequiredNum))

                local happinessText = Locale.Lookup(GameInfo.Happinesses[capturedCity.Happiness].Name)
                table.insert(parts, happinessText)

                local warWeary = capturedCity.AmenitiesLostFromWarWeariness
                if warWeary > 0 then
                    table.insert(parts, Locale.Lookup("LOC_CAI_REPORTS_WAR_WEARINESS", warWeary))
                end

                table.insert(parts, Locale.Lookup("LOC_CAI_REPORTS_DEFENSE", capturedCity.Defense))

                local damage
                if m_isExp1 or m_isExp2 then
                    damage = capturedCity.HitpointsTotal - capturedCity.HitpointsCurrent
                else
                    damage = capturedCity.Damage
                end
                if damage and damage > 0 then
                    table.insert(parts, Locale.Lookup("LOC_CAI_REPORTS_DAMAGE", damage))
                end

                if capturedCity.IsUnderSiege then
                    table.insert(parts, Locale.Lookup("LOC_HUD_REPORTS_STATUS_UNDER_SEIGE"))
                end

                if m_isExp1 or m_isExp2 then
                    local pCulturalIdentity = capturedCity.City:GetCulturalIdentity()
                    if pCulturalIdentity then
                        local currentLoyalty = pCulturalIdentity:GetLoyalty()
                        local maxLoyalty = pCulturalIdentity:GetMaxLoyalty()
                        local loyaltyPerTurn = pCulturalIdentity:GetLoyaltyPerTurn()
                        local trend
                        if loyaltyPerTurn > 0 then
                            trend = Locale.Lookup("LOC_CAI_REPORTS_LOYALTY_RISING")
                        elseif loyaltyPerTurn < 0 then
                            trend = Locale.Lookup("LOC_CAI_REPORTS_LOYALTY_FALLING")
                        else
                            trend = Locale.Lookup("LOC_CAI_REPORTS_LOYALTY_STABLE")
                        end
                        table.insert(parts, Locale.Lookup("LOC_CAI_REPORTS_LOYALTY",
                            Round(currentLoyalty, 1), maxLoyalty, trend))
                    end

                    local pAssignedGovernor = capturedCity.City:GetAssignedGovernor()
                    if pAssignedGovernor then
                        local eGovernorType = pAssignedGovernor:GetType()
                        local governorDef = GameInfo.Governors[eGovernorType]
                        local govName = Locale.Lookup(governorDef.Name)
                        local established = pAssignedGovernor:IsEstablished()
                        if established then
                            table.insert(parts, Locale.Lookup("LOC_CAI_REPORTS_GOVERNOR_ASSIGNED", govName))
                        else
                            table.insert(parts, Locale.Lookup("LOC_CAI_REPORTS_GOVERNOR_TRAVELING", govName))
                        end
                    else
                        table.insert(parts, Locale.Lookup("LOC_CAI_REPORTS_NO_GOVERNOR"))
                    end
                end

                return table.concat(parts, ", ")
            end,
            FocusKey = "status:city:" .. capturedCity.City:GetID(),
        })
        btn:On("activate", function()
            ActivateCity(capturedCity.City)
        end)
        list:AddChild(btn)
    end

    mgr:RestoreFocus(list, capture)
end

local function RebuildCityStatusTab(entry)
    RebuildCityStatusList(entry.tree)

    local page = entry.page
    if not page then return end

    if entry.sortDropdown then return end

    local sortOptions = {
        { label = Locale.Lookup("LOC_CAI_REPORTS_SORT_NAME"),       value = "name" },
        { label = Locale.Lookup("LOC_HUD_REPORTS_HEADER_POPULATION"), value = "population" },
        { label = Locale.Lookup("LOC_CAI_REPORTS_SORT_DEFENSE"),    value = "defense" },
        { label = Locale.Lookup("LOC_CAI_REPORTS_SORT_HAPPINESS"),  value = "happiness" },
        { label = Locale.Lookup("LOC_CAI_REPORTS_SORT_GROWTH"),     value = "growth" },
    }
    if m_isExp1 or m_isExp2 then
        table.insert(sortOptions,
            { label = Locale.Lookup("LOC_REPORTS_LOYALTY"), value = "loyalty" })
    end

    local sortDropdown = mgr:CreateWidget(MakeId("CAIRPT_"), "Dropdown", {
        Label = function() return Locale.Lookup("LOC_CAI_REPORTS_SORT_BY") end,
        FocusKey = "status:sort",
    })
    sortDropdown:SetOptions(sortOptions)
    for si, opt in ipairs(sortOptions) do
        if opt.value == m_cityStatusSort then
            sortDropdown:SetSelectedIndex(si, true); break
        end
    end
    sortDropdown:On("value_changed", function(w, val)
        m_cityStatusSort = val
        RebuildCityStatusList(entry.tree)
    end)
    page:AddChild(sortDropdown)
    entry.sortDropdown = sortDropdown
end


-- ============================================================================
-- Gossip Tab
-- ============================================================================
local function RebuildGossipList(list)
    local capture = mgr:CaptureFocusKey(list)
    list:ClearChildren()

    if m_caiGossipFiltered == nil then return end

    for gi, kGossipEntry in ipairs(m_caiGossipFiltered) do
        local capturedEntry = kGossipEntry
        local capturedGI = gi
        local entryWidget = mgr:CreateWidget(MakeId("CAIRPT_"), "StaticText", {
            Label = function()
                local description = capturedEntry[1]
                local turn = capturedEntry[2]
                local targetPlayerID = capturedEntry[4]
                local leaderName = ""
                if targetPlayerID and PlayerConfigurations[targetPlayerID] then
                    leaderName = Locale.Lookup(PlayerConfigurations[targetPlayerID]:GetLeaderName())
                end
                return Locale.Lookup("LOC_CAI_REPORTS_GOSSIP_ENTRY", turn, leaderName, ProcessIcons(description))
            end,
            FocusKey = "gossip:" .. capturedGI,
        })
        list:AddChild(entryWidget)
    end

    mgr:RestoreFocus(list, capture)
end

local function RefreshGossipListFromFilters()
    local entry = m_trees[4]
    if entry and entry.tree then
        FilterCAIGossip()
        RebuildGossipList(entry.tree)
    end
end

local function BuildGossipFilters(page, entry)
    -- Player filter dropdown
    local playerOptions = {}
    table.insert(playerOptions, { Label = Locale.Lookup("LOC_HUD_REPORTS_PLAYER_FILTER_ALL"), Value = -1 })

    local pLocalPlayerDiplomacy = Players[m_localPlayerID]:GetDiplomacy()
    if pLocalPlayerDiplomacy then
        for targetID, kPlayer in pairs(Players) do
            if targetID ~= m_localPlayerID and kPlayer:IsMajor() and pLocalPlayerDiplomacy:HasMet(targetID) then
                table.insert(playerOptions, {
                    Label = Locale.Lookup(PlayerConfigurations[targetID]:GetLeaderName()),
                    Value = targetID,
                })
            end
        end
    end

    local playerDropdownOptions = {}
    for _, opt in ipairs(playerOptions) do
        table.insert(playerDropdownOptions, { label = opt.Label, value = opt.Value })
    end

    m_gossipPlayerFilter = mgr:CreateWidget(MakeId("CAIRPT_"), "Dropdown", {
        Label = function() return Locale.Lookup("LOC_CAI_REPORTS_FILTER_PLAYER") end,
        FocusKey = "gossip:filter:player",
    })
    m_gossipPlayerFilter:SetOptions(playerDropdownOptions)
    for si, opt in ipairs(playerDropdownOptions) do
        if opt.value == m_caiLeaderFilter then
            m_gossipPlayerFilter:SetSelectedIndex(si, true); break
        end
    end
    m_gossipPlayerFilter:On("value_changed", function(w, val)
        m_caiLeaderFilter = val
        RefreshGossipListFromFilters()
    end)
    page:AddChild(m_gossipPlayerFilter)

    -- Group filter dropdown
    local groupOptions = {}
    table.insert(groupOptions, { Label = Locale.Lookup("LOC_HUD_REPORTS_FILTER_ALL"), Value = "ALL" })

    local seenGroups = {}
    for _, kEntry in ipairs(m_caiGossipLog) do
        local kGossipData = GameInfo.Gossips[kEntry[3]]
        if kGossipData and not seenGroups[kGossipData.GroupType] then
            seenGroups[kGossipData.GroupType] = true
            table.insert(groupOptions, {
                Label = Locale.Lookup("LOC_HUD_REPORTS_FILTER_" .. kGossipData.GroupType),
                Value = kGossipData.GroupType,
            })
        end
    end

    local groupDropdownOptions = {}
    for _, opt in ipairs(groupOptions) do
        table.insert(groupDropdownOptions, { label = opt.Label, value = opt.Value })
    end

    m_gossipGroupFilter = mgr:CreateWidget(MakeId("CAIRPT_"), "Dropdown", {
        Label = function() return Locale.Lookup("LOC_CAI_REPORTS_FILTER_TYPE") end,
        FocusKey = "gossip:filter:type",
    })
    m_gossipGroupFilter:SetOptions(groupDropdownOptions)
    for si, opt in ipairs(groupDropdownOptions) do
        if opt.value == m_caiGroupFilter then
            m_gossipGroupFilter:SetSelectedIndex(si, true); break
        end
    end
    m_gossipGroupFilter:On("value_changed", function(w, val)
        m_caiGroupFilter = val
        RefreshGossipListFromFilters()
    end)
    page:AddChild(m_gossipGroupFilter)
end


-- ============================================================================
-- Tab Capture and Switching
-- ============================================================================
local m_capturedTabs = {}

local TAB_LABELS = {
    [1] = "LOC_HUD_REPORTS_TAB_YIELDS",
    [2] = "LOC_HUD_REPORTS_TAB_RESOURCES",
    [3] = "LOC_HUD_REPORTS_TAB_CITY_STATUS",
    [4] = "LOC_HUD_REPORTS_TAB_GOSSIP",
}

local function DetectActiveTab()
    return m_activeTab or 1
end

local function BuildPanel()
    if m_panel then return end

    m_localPlayerID = Game.GetLocalPlayer()
    if m_localPlayerID == -1 then return end

    m_panel = mgr:CreateWidget(MakeId("CAIRPT_"), "Panel", {
        Id = PANEL_ID,
        Label = function() return Locale.Lookup("LOC_HUD_REPORTS_TITLE") end,
    })

    m_tabs = mgr:CreateWidget(MakeId("CAIRPT_"), "TabControl", {
        Id = TABS_ID,
        FocusKey = "reports:tabs",
    })
    m_panel:AddChild(m_tabs)

    local tabCount = 3
    if GameCapabilities.HasCapability("CAPABILITY_GOSSIP_REPORT") then
        tabCount = 4
    end

    for i = 1, tabCount do
        local capturedI = i

        local tree
        if capturedI == 3 then
            tree = mgr:CreateWidget(MakeId("CAIRPT_"), "List", { FocusKey = "reports:tab:" .. capturedI .. ":list" })
        elseif capturedI == 4 then
            tree = mgr:CreateWidget(MakeId("CAIRPT_"), "List", {
                FocusKey = "reports:tab:" .. capturedI .. ":list",
            })
        else
            tree = mgr:CreateWidget(MakeId("CAIRPT_"), "Tree", { FocusKey = "reports:tab:" .. capturedI .. ":tree" })
        end

        m_tabs:AddPage(function()
            return Locale.Lookup(TAB_LABELS[capturedI])
        end)

        local page = m_tabs:GetPage(capturedI)
        if page then
            page:AddChild(tree)
        end

        m_trees[capturedI] = {
            tree = tree,
            page = page,
            tabIndex = capturedI,
        }
    end

    m_tabs:On("value_changed", function(w, pageIndex)
        if m_isMirroringTab then return end
        m_isMirroringTab = true

        local btn = m_capturedTabs[pageIndex]
        if btn then
            btn:DoLeftClick()
        end

        m_isMirroringTab = false
    end)
end

local function RebuildGossipTab(entry)
    RebuildGossipList(entry.tree)

    local page = entry.page
    if not page then return end

    if not entry.filtersBuilt then
        BuildGossipFilters(page, entry)
        entry.filtersBuilt = true
    end
end

local function RebuildActiveTab()
    local activeTab = DetectActiveTab()
    local entry = m_trees[activeTab]
    if not entry then return end

    if activeTab == 1 then
        RebuildYieldsTree(entry.tree)
    elseif activeTab == 2 then
        RebuildResourcesTree(entry.tree)
    elseif activeTab == 3 then
        RebuildCityStatusTab(entry)
    elseif activeTab == 4 then
        RebuildGossipTab(entry)
    end
end

local function PushPanel()
    BuildPanel()
    if not m_panel then return end
    local activeTab = DetectActiveTab()

    m_isMirroringTab = true
    if m_tabs then
        m_tabs:SetActivePage(activeTab)
    end
    m_isMirroringTab = false

    RebuildActiveTab()
    mgr:Push(m_panel, PopupPriority.Medium)
end

local function PopPanel()
    if mgr and m_panel and mgr:GetWidgetById(PANEL_ID) then
        mgr:RemoveFromStack(PANEL_ID)
    end
    m_panel = nil
    m_tabs = nil
    m_trees = {}
    m_gossipPlayerFilter = nil
    m_gossipGroupFilter = nil
end


-- ============================================================================
-- View*Page Wraps
-- ============================================================================
ViewYieldsPage = WrapFunc(ViewYieldsPage, function(orig)
    orig()
    m_activeTab = 1
    if not mgr or ContextPtr:IsHidden() then return end
    if not m_isMirroringTab and m_tabs then
        m_isMirroringTab = true
        m_tabs:SetActivePage(1)
        m_isMirroringTab = false
    end
    local entry = m_trees[1]
    if entry then
        RebuildYieldsTree(entry.tree)
    end
end)

ViewResourcesPage = WrapFunc(ViewResourcesPage, function(orig)
    orig()
    m_activeTab = 2
    if not mgr or ContextPtr:IsHidden() then return end
    if not m_isMirroringTab and m_tabs then
        m_isMirroringTab = true
        m_tabs:SetActivePage(2)
        m_isMirroringTab = false
    end
    local entry = m_trees[2]
    if entry then
        RebuildResourcesTree(entry.tree)
    end
end)

ViewCityStatusPage = WrapFunc(ViewCityStatusPage, function(orig)
    orig()
    m_activeTab = 3
    if not mgr or ContextPtr:IsHidden() then return end
    if not m_isMirroringTab and m_tabs then
        m_isMirroringTab = true
        m_tabs:SetActivePage(3)
        m_isMirroringTab = false
    end
    local entry = m_trees[3]
    if entry then
        RebuildCityStatusTab(entry)
    end
end)

ViewGossipPage = WrapFunc(ViewGossipPage, function(orig)
    orig()
    m_activeTab = 4
    if not mgr or ContextPtr:IsHidden() then return end
    if not m_isMirroringTab and m_tabs then
        m_isMirroringTab = true
        m_tabs:SetActivePage(4)
        m_isMirroringTab = false
    end
    local entry = m_trees[4]
    if entry then
        RebuildGossipTab(entry)
    end
end)

AddTabSection = WrapFunc(AddTabSection, function(orig, name, populateCallback)
    orig(name, populateCallback)
    local children = Controls.TabContainer:GetChildren()
    local lastChild = children[#children]
    if lastChild then
        table.insert(m_capturedTabs, lastChild)
    end
end)

RefreshGossip = WrapFunc(RefreshGossip, function(orig)
    orig()
    if not mgr or ContextPtr:IsHidden() then return end
    GatherGossip()
    FilterCAIGossip()
    local entry = m_trees[4]
    if entry then
        RebuildGossipTab(entry)
    end
end)


-- ============================================================================
-- Lifecycle
-- ============================================================================
Open = WrapFunc(Open, function(orig, tabToOpen)
    orig(tabToOpen)
    if mgr then
        RefreshCAIData()
        GatherGossip()
        FilterCAIGossip()
        PushPanel()
    end
end)

Close = WrapFunc(Close, function(orig)
    PopPanel()
    orig()
end)

local origOnInputHandler = OnInputHandler
OnInputHandler = function(pInputStruct)
    if mgr and m_panel and mgr:GetWidgetById(PANEL_ID) then
        if mgr:GetTop() == m_panel then
            local consumed = mgr:HandleInput(pInputStruct)
            if consumed then
                return true
            end
        end
    end
    return origOnInputHandler(pInputStruct)
end
ContextPtr:SetInputHandler(OnInputHandler, true)

OnShutdown = WrapFunc(OnShutdown, function(orig)
    PopPanel()
    orig()
end)
