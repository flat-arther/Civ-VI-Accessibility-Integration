include("caiUtils")
include("Civ6Common")
include("hexCoordUtils_CAI")
include("inGameHelpers_CAI")
if IsExpansion2Active() then
    include("ReportScreen_Expansion2")
elseif IsExpansion1Active() then
    include("ReportScreen_Expansion1")
else
    include("ReportScreen")
end

local mgr                  = ExposedMembers.CAI_UIManager
local CAICursor            = ExposedMembers.CAICursor
local HexCoordUtils        = CAIHexCoordUtils

local PANEL_ID             = "CAIReports_Panel"
local TABS_ID              = "CAIReports_Tabs"
local HOVER_SOUND          = "Main_Menu_Mouse_Over"
local BLACK_DEATH_PAPAL_SLOT_INDEX = 2
local BLACK_DEATH_PAPAL_SLOT_UPKEEP = 4

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
local m_pendingOpenFocusKey = nil

local function GetRelativePlotLocation(plotIndex)
    if plotIndex == nil then return "" end
    local plot = Map.GetPlotByIndex(plotIndex)
    if plot == nil then return "" end
    CAICursor = CAICursor or ExposedMembers.CAICursor
    if CAICursor == nil then return "" end
    local cursorX, cursorY = CAICursor:GetCoords()
    if cursorX == nil or cursorY == nil then return "" end
    return HexCoordUtils.directionString(cursorX, cursorY, plot:GetX(), plot:GetY())
end

local function AppendRelativePlotLocation(label, plotIndex)
    local location = GetRelativePlotLocation(plotIndex)
    if location == "" then return label end
    return label .. ", " .. location
end

local function IndexCityComponentPlots(cityData)
    local city = cityData.City
    local cityPlot = Map.GetPlot(city:GetX(), city:GetY())
    cityData.CAIPlotIndex = cityPlot and cityPlot:GetIndex() or nil
    cityData.CAIBuildingPlotIndices = {}

    local districtPlotIndices = {}
    for _, district in city:GetDistricts():Members() do
        local districtInfo = GameInfo.Districts[district:GetType()]
        local districtPlot = Map.GetPlot(district:GetX(), district:GetY())
        if districtInfo and districtPlot then
            districtPlotIndices[districtInfo.DistrictType] = districtPlot:GetIndex()
        end
    end

    for _, districtData in ipairs(cityData.BuildingsAndDistricts or {}) do
        districtData.CAIPlotIndex = districtPlotIndices[districtData.Type]
    end

    local purchasedPlots = Map.GetCityPlots():GetPurchasedPlots(city)
    if purchasedPlots then
        local cityBuildings = city:GetBuildings()
        for _, plotIndex in pairs(purchasedPlots) do
            for _, buildingIndex in ipairs(cityBuildings:GetBuildingsAtLocation(plotIndex)) do
                local buildingInfo = GameInfo.Buildings[buildingIndex]
                if buildingInfo then
                    cityData.CAIBuildingPlotIndices[buildingInfo.BuildingType] = plotIndex
                end
            end
        end
    end

    for _, districtData in ipairs(cityData.BuildingsAndDistricts or {}) do
        for _, buildingData in ipairs(districtData.Buildings or {}) do
            buildingData.CAIPlotIndex = cityData.CAIBuildingPlotIndices[buildingData.Type]
        end
    end
    for _, wonderData in ipairs(cityData.Wonders or {}) do
        wonderData.CAIPlotIndex = cityData.CAIBuildingPlotIndices[wonderData.Type]
    end
end

local function RefreshCAIData()
    m_localPlayerID = Game.GetLocalPlayer()
    if m_localPlayerID == -1 then return end
    m_caiCityData, m_caiCityTotalData, m_caiResourceData, m_caiUnitData, m_caiDealData = GetData()
    table.sort(m_caiCityData, function(a, b) return a.Order < b.Order end)
    for _, cityData in ipairs(m_caiCityData) do
        IndexCityComponentPlots(cityData)
    end
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

local function MakeStaticText(props)
    local text = mgr:CreateWidget(MakeId("CAIRPT_"), "StaticText", props)
    text:SetFocusSound(HOVER_SOUND)
    return text
end

local function AddLeaf(parent, focusKey, labelFn, tooltipFn, activateFn)
    local factory = activateFn and MakeTreeItem or MakeStaticText
    local item = factory({
        Label = labelFn,
        Tooltip = tooltipFn,
        FocusKey = focusKey,
    })
    if activateFn then item:On("activate", activateFn) end
    parent:AddChild(item)
    return item
end

local function JoinLines(parts)
    local filtered = {}
    for _, part in ipairs(parts) do
        if part ~= nil and part ~= "" then
            table.insert(filtered, part)
        end
    end
    return table.concat(filtered, "[NEWLINE]")
end

local function FormatBalance(value)
    return Locale.ToNumber(value, "#,###.#")
end

local function FormatValuePerTurn(value)
    if value == 0 then
        return Locale.ToNumber(value)
    end
    return Locale.Lookup("{1: number +#,###.#;-#,###.#}", value)
end

local function FormatRatePerTurn(value)
    return Locale.Lookup("LOC_HUD_REPORTS_PER_TURN", value)
end

local function NormalizeTooltipNewlines(tooltip)
    if tooltip == nil or tooltip == "" then return "" end
    tooltip = string.gsub(tooltip, "%[NEWLINE%]", "\n")
    tooltip = string.gsub(tooltip, "\r\n", "\n")
    return string.gsub(tooltip, "\r", "\n")
end

local function SplitTooltipLines(tooltip)
    local lines = {}
    tooltip = NormalizeTooltipNewlines(tooltip)
    if tooltip == "" then return lines end

    for line in string.gmatch(tooltip .. "\n", "(.-)\n") do
        if line ~= "" then
            table.insert(lines, line)
        end
    end
    return lines
end

local function TrimLeadingWhitespace(text)
    if text == nil then return "" end
    return string.gsub(text, "^%s+", "")
end

local function AddBreakdownRows(parent, lines, focusKeyPrefix, enhancers)
    local roots = {}
    local stack = {}
    for _, line in ipairs(lines) do
        local whitespace = string.match(line, "^%s*") or ""
        local normalizedWhitespace = string.gsub(whitespace, "\t", "    ")
        local row = {
            label = TrimLeadingWhitespace(line),
            indent = string.len(normalizedWhitespace),
            children = {},
        }
        while #stack > 0 and stack[#stack].indent >= row.indent do
            table.remove(stack)
        end
        if #stack > 0 then
            row.parent = stack[#stack]
            table.insert(stack[#stack].children, row)
        else
            table.insert(roots, row)
        end
        table.insert(stack, row)
    end

    local appliedEnhancers = {}
    local function ResolveEnhancer(label)
        local exactEnhancer = enhancers and enhancers[label] or nil
        if exactEnhancer ~= nil then return exactEnhancer, label end
        for _, matcher in ipairs((enhancers and enhancers.Matchers) or {}) do
            if matcher.Matches(label) then
                return matcher.Enhance, matcher.Key
            end
        end
        return nil, nil
    end
    local function ResolveDecorator(row)
        for _, decorator in ipairs((enhancers and enhancers.Decorators) or {}) do
            if decorator.Matches(row.label, row) then return decorator.Decorate end
        end
        return nil
    end
    local function AddRows(rowParent, rows, rowPrefix)
        for rowIndex, row in ipairs(rows) do
            local rowKey = rowPrefix .. ":row:" .. rowIndex
            local enhancer, enhancerKey = ResolveEnhancer(row.label)
            local decorator = ResolveDecorator(row)
            if #row.children == 0 and enhancer == nil and decorator == nil then
                local rowLabel = row.label
                AddLeaf(rowParent, rowKey, function() return rowLabel end)
            else
                local rowLabel = row.label
                local rowNode = MakeTreeItem({
                    Label = function() return rowLabel end,
                    FocusKey = rowKey,
                })
                rowParent:AddChild(rowNode)
                if decorator then decorator(rowNode, rowLabel) end
                if enhancer then
                    enhancer(rowNode)
                    appliedEnhancers[row.label] = true
                    if enhancerKey ~= nil then appliedEnhancers[enhancerKey] = true end
                else
                    AddRows(rowNode, row.children, rowKey)
                end
            end
        end
    end

    AddRows(parent, roots, focusKeyPrefix)
    return appliedEnhancers
end

local function AddBreakdownNode(parent, focusKey, label, detailText, tooltipFn, enhancers)
    local lines = SplitTooltipLines(detailText)
    if #lines == 0 and enhancers == nil then
        return AddLeaf(parent, focusKey, function() return label end, tooltipFn), {}
    end

    local node = MakeTreeItem({
        Label = function() return label end,
        Tooltip = tooltipFn,
        FocusKey = focusKey,
    })
    parent:AddChild(node)
    local appliedEnhancers = AddBreakdownRows(node, lines, focusKey, enhancers)
    return node, appliedEnhancers
end

local function LookupNamedValue(tag, value)
    return Locale.Lookup(tag, { Name = "Value", Value = value })
end

local function MakeNamedValueMatcher(tag)
    local first = LookupNamedValue(tag, 123456.7)
    local second = LookupNamedValue(tag, 89012.3)
    local prefixLength = 0
    local maxPrefix = math.min(string.len(first), string.len(second))
    while prefixLength < maxPrefix
        and string.sub(first, prefixLength + 1, prefixLength + 1)
            == string.sub(second, prefixLength + 1, prefixLength + 1) do
        prefixLength = prefixLength + 1
    end

    local suffixLength = 0
    local maxSuffix = math.min(string.len(first), string.len(second)) - prefixLength
    while suffixLength < maxSuffix
        and string.sub(first, -suffixLength - 1, -suffixLength - 1)
            == string.sub(second, -suffixLength - 1, -suffixLength - 1) do
        suffixLength = suffixLength + 1
    end

    local prefix = string.sub(first, 1, prefixLength)
    local suffix = suffixLength > 0 and string.sub(first, -suffixLength) or ""
    local usePrefix = string.len(prefix) >= 3
    local useSuffix = string.len(suffix) >= 3
    return function(label)
        if not usePrefix and not useSuffix then return false end
        return (not usePrefix or string.sub(label, 1, string.len(prefix)) == prefix)
            and (not useSuffix or string.sub(label, -string.len(suffix)) == suffix)
    end
end

local ActivatePlot
local ActivateCity

local function BuildCityComponentDecorators(cityData)
    local decorators = {}
    local buildingSummaryMatcher = MakeNamedValueMatcher(
        "LOC_CITY_YIELD_FROM_BUILDINGS_SUMMARY_TOOLTIP")
    local districtSummaryMatcher = MakeNamedValueMatcher(
        "LOC_CITY_YIELD_FROM_DISTRICTS_SUMMARY_TOOLTIP")

    local function HasMatchingAncestor(row, matcher)
        local ancestor = row.parent
        while ancestor ~= nil do
            if matcher(ancestor.label) then return true end
            ancestor = ancestor.parent
        end
        return false
    end

    local function AddComponent(name, plotIndex, summaryMatcher)
        local localizedName = Locale.Lookup(name)
        if localizedName == "" or plotIndex == nil then return end
        table.insert(decorators, {
            NameLength = string.len(localizedName),
            Matches = function(label, row)
                return HasMatchingAncestor(row, summaryMatcher)
                    and string.find(label, localizedName, 1, true) ~= nil
            end,
            Decorate = function(node, label)
                node:SetLabel(function()
                    return AppendRelativePlotLocation(label, plotIndex)
                end)
                node:On("activate", function() ActivatePlot(plotIndex) end)
            end,
        })
    end

    for _, district in ipairs(cityData.BuildingsAndDistricts or {}) do
        AddComponent(district.Name, district.CAIPlotIndex, districtSummaryMatcher)
        for _, building in ipairs(district.Buildings or {}) do
            AddComponent(building.Name, building.CAIPlotIndex, buildingSummaryMatcher)
        end
    end
    for _, wonder in ipairs(cityData.Wonders or {}) do
        AddComponent(wonder.Name, wonder.CAIPlotIndex, buildingSummaryMatcher)
    end
    table.sort(decorators, function(a, b) return a.NameLength > b.NameLength end)
    return decorators
end

local function AddCityYieldRows(parent, focusPrefix, amountField, tooltipField)
    for _, cityData in ipairs(m_caiCityData) do
        local amount = cityData[amountField] or 0
        if amount ~= 0 then
            local capturedCity = cityData
            local cityID = capturedCity.City:GetID()
            local cityFocusKey = focusPrefix .. ":city:" .. cityID
            local tooltipLines = tooltipField and SplitTooltipLines(capturedCity[tooltipField]) or {}
            local cityNode = MakeTreeItem({
                Label = function()
                    local label = Locale.Lookup("LOC_CAI_REPORTS_YIELD_FROM_CITY",
                        FormatValuePerTurn(capturedCity[amountField] or 0),
                        Locale.Lookup(capturedCity.CityName))
                    return AppendRelativePlotLocation(label, capturedCity.CAIPlotIndex)
                end,
                FocusKey = cityFocusKey,
            })
            cityNode:On("activate", function() ActivateCity(capturedCity.City) end)
            parent:AddChild(cityNode)
            if #tooltipLines > 0 then
                AddBreakdownRows(cityNode, tooltipLines, cityFocusKey, {
                    Decorators = BuildCityComponentDecorators(capturedCity),
                })
            end
        end
    end
end

local function AddYieldWithCityBreakdown(parent, focusKey, label, detailText,
    cityGroupTag, cityTotal, amountField, tooltipField)
    local cityLabel = LookupNamedValue(cityGroupTag, cityTotal)
    local enhancers = {
        [cityLabel] = function(cityNode)
            AddCityYieldRows(cityNode, focusKey .. ":cities", amountField, tooltipField)
        end,
    }
    local yieldNode, applied = AddBreakdownNode(parent, focusKey, label, detailText, nil, enhancers)
    if not applied[cityLabel] then
        local cityNode = MakeTreeItem({
            Label = function() return cityLabel end,
            FocusKey = focusKey .. ":cities",
        })
        yieldNode:AddChild(cityNode)
        AddCityYieldRows(cityNode, focusKey .. ":cities", amountField, tooltipField)
    end
    return yieldNode
end

local function GetDisplayedFaithYield(localPlayer)
    local faithYield = localPlayer:GetReligion():GetFaithYield()
    if GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_BLACKDEATH" then
        local playerConfig = PlayerConfigurations[m_localPlayerID]
        local isFrance = playerConfig ~= nil
            and playerConfig:GetCivilizationTypeName() == "CIVILIZATION_BLACKDEATH_SCENARIO_FRANCE"
        local playerCulture = localPlayer:GetCulture()
        if isFrance and playerCulture
            and playerCulture:GetSlotPolicy(BLACK_DEATH_PAPAL_SLOT_INDEX) >= 0 then
            faithYield = faithYield - BLACK_DEATH_PAPAL_SLOT_UPKEEP
        end
    end
    return faithYield
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
    return table.concat(parts, "[NEWLINE]")
end

local function toPlusMinus(val)
    if val == nil or val == 0 then return "0" end
    if val > 0 then return "+" .. tostring(val) end
    return tostring(val)
end

local function HasNonZeroYieldData(production, food, gold, faith, science, culture, tourism)
    return (production ~= nil and production ~= 0)
        or (food ~= nil and food ~= 0)
        or (gold ~= nil and gold ~= 0)
        or (faith ~= nil and faith ~= 0)
        or (science ~= nil and science ~= 0)
        or (culture ~= nil and culture ~= 0)
        or (tourism ~= nil and tourism ~= 0)
end

local function HasAdjacencyChildren(adjacencyBonus)
    if adjacencyBonus == nil then return false end
    return HasNonZeroYieldData(
        adjacencyBonus.Production,
        adjacencyBonus.Food,
        adjacencyBonus.Gold,
        adjacencyBonus.Faith,
        adjacencyBonus.Science,
        adjacencyBonus.Culture,
        adjacencyBonus.Tourism
    )
end

local function NewYieldTotals()
    return {
        Production = 0,
        Food = 0,
        Gold = 0,
        Faith = 0,
        Science = 0,
        Culture = 0,
        Tourism = 0,
    }
end

local function AddYieldTypeAmount(totals, yieldType, amount)
    if amount == nil or amount == 0 then return end
    if yieldType == "YIELD_PRODUCTION" then
        totals.Production = totals.Production + amount
    elseif yieldType == "YIELD_FOOD" then
        totals.Food = totals.Food + amount
    elseif yieldType == "YIELD_GOLD" then
        totals.Gold = totals.Gold + amount
    elseif yieldType == "YIELD_FAITH" then
        totals.Faith = totals.Faith + amount
    elseif yieldType == "YIELD_SCIENCE" then
        totals.Science = totals.Science + amount
    elseif yieldType == "YIELD_CULTURE" then
        totals.Culture = totals.Culture + amount
    elseif yieldType == "YIELD_TOURISM" or yieldType == "TOURISM" then
        totals.Tourism = totals.Tourism + amount
    end
end

local function AddYieldFields(totals, source)
    if source == nil then return end
    totals.Production = totals.Production + (source.Production or source.ProductionPerTurn or 0)
    totals.Food = totals.Food + (source.Food or source.FoodPerTurn or 0)
    totals.Gold = totals.Gold + (source.Gold or source.GoldPerTurn or 0)
    totals.Faith = totals.Faith + (source.Faith or source.FaithPerTurn or 0)
    totals.Science = totals.Science + (source.Science or source.SciencePerTurn or 0)
    totals.Culture = totals.Culture + (source.Culture or source.CulturePerTurn or 0)
    totals.Tourism = totals.Tourism + (source.Tourism or source.TourismPerTurn or 0)
end

local function BuildDistrictTotalTooltip(district, greatWorks)
    local totals = NewYieldTotals()
    AddYieldFields(totals, district)
    AddYieldFields(totals, district.AdjacencyBonus)

    for _, building in ipairs(district.Buildings or {}) do
        AddYieldFields(totals, building)

        local buildingGreatWorks = greatWorks[building.Type]
        if buildingGreatWorks ~= nil then
            for _, greatWork in ipairs(buildingGreatWorks) do
                for _, yield in ipairs(greatWork.YieldChanges or {}) do
                    AddYieldTypeAmount(totals, yield.YieldType, yield.YieldChange)
                end
            end
        end
    end

    return FormatYields(
        totals.Production,
        totals.Food,
        totals.Gold,
        totals.Faith,
        totals.Science,
        totals.Culture,
        totals.Tourism
    )
end

ActivatePlot = function(plotIndex)
    if plotIndex == nil then return end
    Close()
    LuaEvents.CAICursorMoveTo(plotIndex, "jump")
end

ActivateCity = function(pCity)
    if pCity == nil then return end
    local plot = Map.GetPlot(pCity:GetX(), pCity:GetY())
    if plot then ActivatePlot(plot:GetIndex()) end
end

local function GetUnitPlotIndex(playerID, unitID)
    local player = Players[playerID]
    local unit = player and player:GetUnits():FindID(unitID) or nil
    if unit == nil then return nil end
    local plot = Map.GetPlot(unit:GetX(), unit:GetY())
    return plot and plot:GetIndex() or nil
end

local function ActivateUnit(playerID, unitID)
    ActivatePlot(GetUnitPlotIndex(playerID, unitID))
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
                local parts = { Locale.Lookup(capturedCity.CityName) }
                if capturedCity.IsCapital then
                    table.insert(parts, Locale.Lookup("LOC_CAI_CITY_STATUS_CAPITAL"))
                end
                local kProd = capturedCity.ProductionQueue[1]
                if kProd then
                    table.insert(parts, Locale.Lookup("LOC_CAI_REPORTS_PRODUCING", Locale.Lookup(kProd.Name)))
                    if capturedCity.CurrentTurnsLeft and capturedCity.CurrentTurnsLeft > 0 then
                        table.insert(parts, Locale.Lookup("LOC_CAI_PRODUCTION_TURNS", capturedCity.CurrentTurnsLeft))
                    end
                end
                return AppendRelativePlotLocation(JoinLines(parts), capturedCity.CAIPlotIndex)
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
            local districtHasChildren = HasAdjacencyChildren(capturedDistrict.AdjacencyBonus)
                or #(capturedDistrict.Buildings or {}) > 0

            local districtItem = MakeTreeItem({
                Label = function()
                    local parts = { Locale.Lookup(capturedDistrict.Name) }
                    local yieldStr = FormatYields(
                        capturedDistrict.Production, capturedDistrict.Food,
                        capturedDistrict.Gold, capturedDistrict.Faith,
                        capturedDistrict.Science, capturedDistrict.Culture, nil)
                    if yieldStr ~= "" then
                        table.insert(parts, yieldStr)
                    end
                    return AppendRelativePlotLocation(JoinLines(parts), capturedDistrict.CAIPlotIndex)
                end,
                Tooltip = districtHasChildren and function()
                    return BuildDistrictTotalTooltip(capturedDistrict, greatWorks)
                end or nil,
                FocusKey = "yield:city:" .. cityID .. ":dist:" .. tostring(capturedDistrict.Type),
            })
            districtItem:On("activate", function()
                ActivatePlot(capturedDistrict.CAIPlotIndex)
            end)
            cityItem:AddChild(districtItem)

            if districtHasChildren then
                if HasAdjacencyChildren(capturedDistrict.AdjacencyBonus) then
                    local capturedAdj = capturedDistrict.AdjacencyBonus
                    AddLeaf(districtItem,
                        "yield:city:" .. cityID .. ":dist:" .. tostring(capturedDistrict.Type) .. ":adj",
                        function()
                            return JoinLines({
                                Locale.Lookup("LOC_HUD_REPORTS_ADJACENCY_BONUS"),
                                FormatYields(
                                    capturedAdj.Production, capturedAdj.Food,
                                    capturedAdj.Gold, capturedAdj.Faith,
                                    capturedAdj.Science, capturedAdj.Culture, nil)
                            })
                        end)
                end

                for _, kBuilding in ipairs(capturedDistrict.Buildings) do
                    local capturedBuilding = kBuilding
                    AddLeaf(districtItem,
                        "yield:city:" .. cityID .. ":bldg:" .. tostring(capturedBuilding.Type),
                        function()
                            local parts = { Locale.Lookup(capturedBuilding.Name) }
                            local yieldStr = FormatYields(
                                capturedBuilding.ProductionPerTurn, capturedBuilding.FoodPerTurn,
                                capturedBuilding.GoldPerTurn, capturedBuilding.FaithPerTurn,
                                capturedBuilding.SciencePerTurn, capturedBuilding.CulturePerTurn, nil)
                            if yieldStr ~= "" then
                                table.insert(parts, yieldStr)
                            end
                            return AppendRelativePlotLocation(
                                JoinLines(parts), capturedBuilding.CAIPlotIndex)
                        end,
                        nil,
                        function() ActivatePlot(capturedBuilding.CAIPlotIndex) end)

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
                                        text = JoinLines({ text, table.concat(gwYields, "[NEWLINE]") })
                                    end
                                    return text
                                end)
                        end
                    end
                end
            end
        end

        if capturedCity.Wonders then
            for _, wonder in ipairs(capturedCity.Wonders) do
                local capturedWonder = wonder
                if capturedWonder.Yields[1] or (greatWorks[capturedWonder.Type]) then
                    local wonderHasChildren = greatWorks[capturedWonder.Type] ~= nil and
                        #greatWorks[capturedWonder.Type] > 0
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
                                text = JoinLines({ text, table.concat(parts, "[NEWLINE]") })
                            end
                            return AppendRelativePlotLocation(text, capturedWonder.CAIPlotIndex)
                        end,
                        FocusKey = "yield:city:" .. cityID .. ":wonder:" .. tostring(capturedWonder.Type),
                    })
                    wonderItem:On("activate", function()
                        ActivatePlot(capturedWonder.CAIPlotIndex)
                    end)
                    cityItem:AddChild(wonderItem)

                    if wonderHasChildren then
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
                                        text = JoinLines({ text, table.concat(gwYields, "[NEWLINE]") })
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
                                text = JoinLines({ text, table.concat(routeYields, "[NEWLINE]") })
                            end
                            return text
                        end)
                end
            end
        end

        AddLeaf(cityItem,
            "yield:city:" .. cityID .. ":worked",
            function()
                return JoinLines({
                    Locale.Lookup("LOC_HUD_REPORTS_WORKED_TILES"),
                    FormatYields(
                        capturedCity.WorkedTileYields["YIELD_PRODUCTION"],
                        capturedCity.WorkedTileYields["YIELD_FOOD"],
                        capturedCity.WorkedTileYields["YIELD_GOLD"],
                        capturedCity.WorkedTileYields["YIELD_FAITH"],
                        capturedCity.WorkedTileYields["YIELD_SCIENCE"],
                        capturedCity.WorkedTileYields["YIELD_CULTURE"],
                        nil)
                })
            end)

        if capturedCity.City:GetGrowth() ~= nil and capturedCity.City:GetGrowth():GetHappiness() ~= 4 then
            local capturedCityForAmenity = capturedCity
            local amenityMod = capturedCityForAmenity.HappinessNonFoodYieldModifier
            if amenityMod and amenityMod ~= 0 then
                AddLeaf(cityItem,
                    "yield:city:" .. cityID .. ":amenity",
                    function()
                        local iYieldPercent = (Round(1 + (amenityMod / 100), 2) * .1)
                        return JoinLines({
                            Locale.Lookup("LOC_HUD_REPORTS_HEADER_AMENITIES"),
                            FormatYields(
                                capturedCityForAmenity.WorkedTileYields["YIELD_PRODUCTION"] * iYieldPercent,
                                nil,
                                capturedCityForAmenity.WorkedTileYields["YIELD_GOLD"] * iYieldPercent,
                                capturedCityForAmenity.WorkedTileYields["YIELD_FAITH"] * iYieldPercent,
                                capturedCityForAmenity.WorkedTileYields["YIELD_SCIENCE"] * iYieldPercent,
                                capturedCityForAmenity.WorkedTileYields["YIELD_CULTURE"] * iYieldPercent,
                                nil)
                        })
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
                    return JoinLines({
                        Locale.Lookup("LOC_HUD_CITY_POPULATION"),
                        Locale.Lookup("LOC_CAI_REPORTS_YIELD_CULTURE", Round(popCulture, 1))
                    })
                end)
        end
    end

    -- Preserve Reports instance detail for the authoritative maintenance tree below.
    local buildingMaintenanceDetail = { Total = 0, ByType = {} }
    local districtMaintenanceDetail = { Total = 0, ByType = {} }
    local cityYieldTotals = { Science = 0, Culture = 0, Gold = 0, Faith = 0, Tourism = 0 }
    for _, kCityData in ipairs(m_caiCityData) do
        kCityData.CAIScienceYield = kCityData.City:GetYield(YieldTypes.SCIENCE)
        kCityData.CAICultureYield = kCityData.City:GetYield(YieldTypes.CULTURE)
        kCityData.CAIGoldYield = kCityData.City:GetYield(YieldTypes.GOLD)
        kCityData.CAIFaithYield = kCityData.City:GetYield(YieldTypes.FAITH)
        kCityData.CAITourismYield = kCityData.WorkedTileYields["TOURISM"] or 0
        cityYieldTotals.Science = cityYieldTotals.Science + kCityData.CAIScienceYield
        cityYieldTotals.Culture = cityYieldTotals.Culture + kCityData.CAICultureYield
        cityYieldTotals.Gold = cityYieldTotals.Gold + kCityData.CAIGoldYield
        cityYieldTotals.Faith = cityYieldTotals.Faith + kCityData.CAIFaithYield
        cityYieldTotals.Tourism = cityYieldTotals.Tourism + kCityData.CAITourismYield
        local cityName = kCityData.CityName
        local cityBuildings = kCityData.City:GetBuildings()
        for buildingInfo in GameInfo.Buildings() do
            if buildingInfo.Maintenance > 0
                and cityBuildings:HasBuilding(buildingInfo.Index)
                and cityBuildings:IsPillaged(buildingInfo.Index) == false then
                local key = buildingInfo.BuildingType
                local detail = buildingMaintenanceDetail.ByType[key]
                if detail == nil then
                    detail = { Name = buildingInfo.Name, Total = 0, Entries = {} }
                    buildingMaintenanceDetail.ByType[key] = detail
                end
                detail.Total = detail.Total + buildingInfo.Maintenance
                table.insert(detail.Entries, {
                    CityName = cityName,
                    Maintenance = buildingInfo.Maintenance,
                    PlotIndex = kCityData.CAIBuildingPlotIndices[buildingInfo.BuildingType],
                })
                buildingMaintenanceDetail.Total = buildingMaintenanceDetail.Total + buildingInfo.Maintenance
            end
        end
        for _, kDistrict in ipairs(kCityData.BuildingsAndDistricts) do
            if kDistrict.Maintenance > 0 and kDistrict.isPillaged == false and kDistrict.isBuilt == true then
                local key = tostring(kDistrict.Type)
                local detail = districtMaintenanceDetail.ByType[key]
                if detail == nil then
                    detail = { Name = kDistrict.Name, Total = 0, Entries = {} }
                    districtMaintenanceDetail.ByType[key] = detail
                end
                detail.Total = detail.Total + kDistrict.Maintenance
                table.insert(detail.Entries, {
                    CityName = cityName,
                    Maintenance = kDistrict.Maintenance,
                    PlotIndex = kDistrict.CAIPlotIndex,
                })
                districtMaintenanceDetail.Total = districtMaintenanceDetail.Total + kDistrict.Maintenance
            end
        end
    end

    local sortedUnits = {}
    local detailedUnitMaintenance = 0
    if GameCapabilities.HasCapability("CAPABILITY_REPORTS_UNIT_EXPENSES") then
        for unitType, kUnitData in pairs(m_caiUnitData) do
            table.insert(sortedUnits, { type = unitType, data = kUnitData })
            detailedUnitMaintenance = detailedUnitMaintenance + kUnitData.Maintenance
        end
        table.sort(sortedUnits, function(a, b) return a.data.Maintenance > b.data.Maintenance end)
    end

    -- Empire Economy
    local localPlayer = Players[m_localPlayerID]
    if localPlayer then
        local economyGroup = MakeTreeItem({
            Label = function() return Locale.Lookup("LOC_CAI_REPORTS_EMPIRE_ECONOMY") end,
            Tooltip = function()
                local parts = {}
                if GameCapabilities.HasCapability("CAPABILITY_GOLD")
                    and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
                    local treasury = localPlayer:GetTreasury()
                    local goldNet = treasury:GetGoldYield() - treasury:GetTotalMaintenance()
                    table.insert(parts, Locale.Lookup("LOC_CAI_REPORTS_YIELD_GOLD",
                        toPlusMinus(Round(goldNet, 1))))
                end
                if GameCapabilities.HasCapability("CAPABILITY_FAITH")
                    and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
                    table.insert(parts, Locale.Lookup("LOC_CAI_REPORTS_YIELD_FAITH",
                        toPlusMinus(Round(GetDisplayedFaithYield(localPlayer), 1))))
                end
                if GameCapabilities.HasCapability("CAPABILITY_SCIENCE")
                    and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
                    table.insert(parts, Locale.Lookup("LOC_CAI_REPORTS_YIELD_SCIENCE",
                        toPlusMinus(Round(localPlayer:GetTechs():GetScienceYield(), 1))))
                end
                if GameCapabilities.HasCapability("CAPABILITY_CULTURE")
                    and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
                    table.insert(parts, Locale.Lookup("LOC_CAI_REPORTS_YIELD_CULTURE",
                        toPlusMinus(Round(localPlayer:GetCulture():GetCultureYield(), 1))))
                end
                if GameCapabilities.HasCapability("CAPABILITY_TOURISM")
                    and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
                    table.insert(parts, Locale.Lookup("LOC_CAI_REPORTS_YIELD_TOURISM",
                        toPlusMinus(Round(localPlayer:GetStats():GetTourism(), 1))))
                end
                if m_isExp2 then
                    table.insert(parts, Locale.Lookup("LOC_CAI_REPORTS_YIELD_FAVOR",
                        Round(localPlayer:GetFavor(), 1)))
                end
                if GameCapabilities.HasCapability("CAPABILITY_TOP_PANEL_ENVOYS") then
                    local influence = localPlayer:GetInfluence()
                    table.insert(parts, Locale.Lookup("LOC_CAI_REPORTS_YIELD_ENVOYS",
                        influence:GetTokensToGive()))
                end
                if GameCapabilities.HasCapability("CAPABILITY_TRADE") then
                    local trade = localPlayer:GetTrade()
                    local capacity = trade:GetOutgoingRouteCapacity()
                    if capacity > 0 then
                        table.insert(parts, Locale.Lookup("LOC_CAI_REPORTS_YIELD_TRADE_ROUTES",
                            trade:GetNumOutgoingRoutes(), capacity))
                    end
                end
                return JoinLines(parts)
            end,
            FocusKey = "yield:economy",
        })
        tree:AddChild(economyGroup)

        if GameCapabilities.HasCapability("CAPABILITY_SCIENCE")
            and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
            local techs = localPlayer:GetTechs()
            local scienceYield = techs:GetScienceYield()
            local scienceTooltip = techs:GetScienceYieldToolTip()
            local scienceLabel = Locale.Lookup("LOC_TOP_PANEL_SCIENCE") .. ": "
                .. FormatRatePerTurn(FormatValuePerTurn(Round(scienceYield, 1)))
            AddYieldWithCityBreakdown(economyGroup, "yield:economy:science", scienceLabel, scienceTooltip,
                "LOC_PLAYER_YIELD_SCIENCE_FROM_CITIES",
                cityYieldTotals.Science,
                "CAIScienceYield", "SciencePerTurnToolTip")
        end

        if GameCapabilities.HasCapability("CAPABILITY_CULTURE")
            and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
            local culture = localPlayer:GetCulture()
            AddYieldWithCityBreakdown(economyGroup, "yield:economy:culture",
                Locale.Lookup("LOC_TOP_PANEL_CULTURE") .. ": "
                    .. FormatRatePerTurn(FormatValuePerTurn(Round(culture:GetCultureYield(), 1))),
                culture:GetCultureYieldToolTip(),
                "LOC_PLAYER_YIELD_CULTURE_FROM_CITIES",
                cityYieldTotals.Culture,
                "CAICultureYield", "CulturePerTurnToolTip")
        end

        if GameCapabilities.HasCapability("CAPABILITY_GOLD")
            and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
            local treasury = localPlayer:GetTreasury()
            local goldYield = treasury:GetGoldYield() - treasury:GetTotalMaintenance()
            local goldValue = Locale.Lookup("LOC_CAI_TOP_PANEL_BALANCE_AND_RATE",
                FormatBalance(math.floor(treasury:GetGoldBalance())),
                FormatRatePerTurn(FormatValuePerTurn(Round(goldYield, 1))))
            local goldNode = MakeTreeItem({
                Label = function() return Locale.Lookup("LOC_TOP_PANEL_GOLD") .. ": " .. goldValue end,
                FocusKey = "yield:economy:gold",
            })
            economyGroup:AddChild(goldNode)

            local goldIncomeFocusKey = "yield:economy:gold:income"
            local goldCityTotal = cityYieldTotals.Gold
            local goldCityLabel = LookupNamedValue("LOC_PLAYER_YIELD_GOLD_FROM_CITIES", goldCityTotal)
            local incomingDealTotal = 0
            local outgoingDealTotal = 0
            local canReportDeals = GameCapabilities.HasCapability("CAPABILITY_REPORTS_DIPLOMATIC_DEALS")
            if canReportDeals then
                for _, deal in ipairs(m_caiDealData) do
                    if deal.Type == DealItemTypes.GOLD then
                        if deal.IsOutgoing then
                            outgoingDealTotal = outgoingDealTotal + deal.Amount
                        else
                            incomingDealTotal = incomingDealTotal + deal.Amount
                        end
                    end
                end
            end
            local incomingDealsLabel = LookupNamedValue("LOC_PLAYER_YIELD_GOLD_FROM_DEALS", incomingDealTotal)
            local outgoingDealsLabel = LookupNamedValue("LOC_PLAYER_GOLD_COST_FROM_DEALS", outgoingDealTotal)

            local function AddDealRows(parent, focusPrefix, isOutgoing)
                for dealIndex, deal in ipairs(m_caiDealData) do
                    if deal.Type == DealItemTypes.GOLD and deal.IsOutgoing == isOutgoing then
                        local capturedDeal = deal
                        local capturedDealIndex = dealIndex
                        AddLeaf(parent, focusPrefix .. ":" .. capturedDealIndex, function()
                            local amount = capturedDeal.IsOutgoing and -capturedDeal.Amount or capturedDeal.Amount
                            return JoinLines({
                                capturedDeal.Name,
                                Locale.Lookup("LOC_REPORTS_NUMBER_OF_TURNS", capturedDeal.Duration),
                                Locale.Lookup("LOC_CAI_REPORTS_YIELD_GOLD", amount)
                            })
                        end)
                    end
                end
            end

            local incomeEnhancers = {
                [goldCityLabel] = function(cityNode)
                    AddCityYieldRows(cityNode, goldIncomeFocusKey .. ":cities",
                        "CAIGoldYield", "GoldPerTurnToolTip")
                end,
            }
            if incomingDealTotal ~= 0 then
                incomeEnhancers[incomingDealsLabel] = function(dealsNode)
                    AddDealRows(dealsNode, goldIncomeFocusKey .. ":deals:incoming", false)
                end
            end
            if outgoingDealTotal ~= 0 then
                incomeEnhancers[outgoingDealsLabel] = function(dealsNode)
                    AddDealRows(dealsNode, goldIncomeFocusKey .. ":deals:outgoing", true)
                end
            end

            local incomeNode, appliedIncomeEnhancers = AddBreakdownNode(goldNode, goldIncomeFocusKey,
                Locale.Lookup("LOC_TOP_PANEL_GOLD_INCOME", treasury:GetGoldYield()),
                treasury:GetGoldYieldToolTip(), nil, incomeEnhancers)
            if not appliedIncomeEnhancers[goldCityLabel] then
                local cityNode = MakeTreeItem({
                    Label = function() return goldCityLabel end,
                    FocusKey = goldIncomeFocusKey .. ":cities",
                })
                incomeNode:AddChild(cityNode)
                AddCityYieldRows(cityNode, goldIncomeFocusKey .. ":cities",
                    "CAIGoldYield", "GoldPerTurnToolTip")
            end
            if incomingDealTotal ~= 0 and not appliedIncomeEnhancers[incomingDealsLabel] then
                local dealsNode = MakeTreeItem({
                    Label = function() return incomingDealsLabel end,
                    FocusKey = goldIncomeFocusKey .. ":deals:incoming",
                })
                incomeNode:AddChild(dealsNode)
                AddDealRows(dealsNode, goldIncomeFocusKey .. ":deals:incoming", false)
            end
            if outgoingDealTotal ~= 0 and not appliedIncomeEnhancers[outgoingDealsLabel] then
                local dealsNode = MakeTreeItem({
                    Label = function() return outgoingDealsLabel end,
                    FocusKey = goldIncomeFocusKey .. ":deals:outgoing",
                })
                incomeNode:AddChild(dealsNode)
                AddDealRows(dealsNode, goldIncomeFocusKey .. ":deals:outgoing", true)
            end

            local function AddMaintenanceTypes(parent, focusPrefix, detail)
                local sortedTypes = {}
                for key, data in pairs(detail.ByType) do
                    table.insert(sortedTypes, { key = key, data = data })
                end
                table.sort(sortedTypes, function(a, b)
                    if a.data.Total ~= b.data.Total then return a.data.Total > b.data.Total end
                    return Locale.Lookup(a.data.Name) < Locale.Lookup(b.data.Name)
                end)

                for _, typeEntry in ipairs(sortedTypes) do
                    local capturedData = typeEntry.data
                    local capturedKey = typeEntry.key
                    local typeItem = MakeTreeItem({
                        Label = function()
                            return JoinLines({
                                Locale.Lookup(capturedData.Name),
                                Locale.Lookup("LOC_CAI_REPORTS_YIELD_GOLD", -capturedData.Total)
                            })
                        end,
                        FocusKey = focusPrefix .. ":type:" .. capturedKey,
                    })
                    parent:AddChild(typeItem)

                    for entryIndex, entry in ipairs(capturedData.Entries) do
                        local capturedEntry = entry
                        local capturedEntryIndex = entryIndex
                        AddLeaf(typeItem,
                            focusPrefix .. ":type:" .. capturedKey .. ":city:" .. capturedEntryIndex,
                            function()
                                local label = JoinLines({
                                    Locale.Lookup(capturedEntry.CityName),
                                    Locale.Lookup("LOC_CAI_REPORTS_YIELD_GOLD", -capturedEntry.Maintenance)
                                })
                                return AppendRelativePlotLocation(label, capturedEntry.PlotIndex)
                            end,
                            nil,
                            function() ActivatePlot(capturedEntry.PlotIndex) end)
                    end
                end
            end

            local unitInstancesByType = {}
            if GameCapabilities.HasCapability("CAPABILITY_REPORTS_UNIT_EXPENSES") then
                for _, unit in localPlayer:GetUnits():Members() do
                    local unitInfo = GameInfo.Units[unit:GetUnitType()]
                    local unitTypeKey = unitInfo.UnitType .. unit:GetMilitaryFormation()
                    if m_caiUnitData[unitTypeKey] ~= nil then
                        local instances = unitInstancesByType[unitTypeKey]
                        if instances == nil then
                            instances = {}
                            unitInstancesByType[unitTypeKey] = instances
                        end
                        table.insert(instances, {
                            PlayerID = m_localPlayerID,
                            UnitID = unit:GetID(),
                            Name = FormatOwnedName(nil, Locale.Lookup(unit:GetName()),
                                GetUnitFormationSuffix(unit)) or Locale.Lookup(unit:GetName()),
                        })
                    end
                end
                for _, instances in pairs(unitInstancesByType) do
                    table.sort(instances, function(a, b)
                        local aName = a.Name
                        local bName = b.Name
                        if aName ~= bName then return aName < bName end
                        return a.UnitID < b.UnitID
                    end)
                end
            end

            local detailedWMDMaintenance = 0
            local wmdRows = {}
            local playerWMDs = localPlayer:GetWMDs()
            for wmd in GameInfo.WMDs() do
                local count = playerWMDs:GetWeaponCount(wmd.Index)
                local maintenance = (wmd.Maintenance or 0) * count
                if count > 0 and maintenance > 0 then
                    detailedWMDMaintenance = detailedWMDMaintenance + maintenance
                    table.insert(wmdRows, { WMD = wmd, Count = count, Maintenance = maintenance })
                end
            end
            local expenseEnhancers = {}
            if districtMaintenanceDetail.Total ~= 0 or buildingMaintenanceDetail.Total ~= 0 then
                local function EnhanceCitiesMaintenance(citiesNode)
                    if districtMaintenanceDetail.Total ~= 0 then
                        local districtsNode = MakeTreeItem({
                            Label = function()
                                return LookupNamedValue("LOC_PLAYER_YIELD_GOLD_MAINTENANCE_FROM_DISTRICTS",
                                    districtMaintenanceDetail.Total)
                            end,
                            FocusKey = "yield:economy:gold:expense:cities:districts",
                        })
                        citiesNode:AddChild(districtsNode)
                        AddMaintenanceTypes(districtsNode,
                            "yield:economy:gold:expense:cities:districts", districtMaintenanceDetail)
                    end
                    if buildingMaintenanceDetail.Total ~= 0 then
                        local buildingsNode = MakeTreeItem({
                            Label = function()
                                return LookupNamedValue("LOC_PLAYER_YIELD_GOLD_MAINTENANCE_FROM_BUILDINGS",
                                    buildingMaintenanceDetail.Total)
                            end,
                            FocusKey = "yield:economy:gold:expense:cities:buildings",
                        })
                        citiesNode:AddChild(buildingsNode)
                        AddMaintenanceTypes(buildingsNode,
                            "yield:economy:gold:expense:cities:buildings", buildingMaintenanceDetail)
                    end
                end
                expenseEnhancers.Matchers = expenseEnhancers.Matchers or {}
                table.insert(expenseEnhancers.Matchers, {
                    Key = "expense:cities",
                    Matches = MakeNamedValueMatcher("LOC_PLAYER_YIELD_GOLD_MAINTENANCE_FROM_CITIES"),
                    Enhance = EnhanceCitiesMaintenance,
                })
            end
            if detailedUnitMaintenance ~= 0 then
                local function EnhanceUnitMaintenance(unitsNode)
                    for _, unitEntry in ipairs(sortedUnits) do
                        local capturedUnit = unitEntry.data
                        local capturedType = unitEntry.type
                        local instances = unitInstancesByType[capturedType] or {}
                        local unitTypeNode = MakeTreeItem({
                            Label = function()
                                return JoinLines({
                                    Locale.Lookup(capturedUnit.Name),
                                    Locale.Lookup("LOC_CAI_REPORTS_UNIT_COUNT", capturedUnit.Count),
                                    Locale.Lookup("LOC_CAI_REPORTS_YIELD_GOLD", -capturedUnit.Maintenance)
                                })
                            end,
                            FocusKey = "yield:economy:gold:expense:units:type:" .. capturedType,
                        })
                        unitsNode:AddChild(unitTypeNode)

                        local instanceMaintenance = capturedUnit.Maintenance / capturedUnit.Count
                        for _, unitInstance in ipairs(instances) do
                            local capturedInstance = unitInstance
                            AddLeaf(unitTypeNode,
                                "yield:economy:gold:expense:units:type:" .. capturedType
                                    .. ":unit:" .. capturedInstance.UnitID,
                                function()
                                    local label = JoinLines({
                                        capturedInstance.Name,
                                        Locale.Lookup("LOC_CAI_REPORTS_YIELD_GOLD", -instanceMaintenance)
                                    })
                                    return AppendRelativePlotLocation(label,
                                        GetUnitPlotIndex(capturedInstance.PlayerID, capturedInstance.UnitID))
                                end,
                                nil,
                                function()
                                    ActivateUnit(capturedInstance.PlayerID, capturedInstance.UnitID)
                                end)
                        end
                    end
                end
                expenseEnhancers.Matchers = expenseEnhancers.Matchers or {}
                table.insert(expenseEnhancers.Matchers, {
                    Key = "expense:units",
                    Matches = MakeNamedValueMatcher("LOC_PLAYER_YIELD_GOLD_MAINTENANCE_FROM_UNITS"),
                    Enhance = EnhanceUnitMaintenance,
                })
            end
            if detailedWMDMaintenance ~= 0 then
                local function EnhanceWMDMaintenance(wmdNode)
                    for _, wmdRow in ipairs(wmdRows) do
                        local capturedRow = wmdRow
                        AddLeaf(wmdNode,
                            "yield:economy:gold:expense:wmd:type:" .. capturedRow.WMD.WeaponType,
                            function()
                                return Locale.Lookup("LOC_CAI_REPORTS_WMD_MAINTENANCE",
                                    Locale.Lookup(capturedRow.WMD.Name), capturedRow.Count,
                                    -capturedRow.Maintenance)
                            end)
                    end
                end
                expenseEnhancers.Matchers = expenseEnhancers.Matchers or {}
                table.insert(expenseEnhancers.Matchers, {
                    Key = "expense:wmds",
                    Matches = MakeNamedValueMatcher("LOC_PLAYER_YIELD_GOLD_MAINTENANCE_FROM_WMDS"),
                    Enhance = EnhanceWMDMaintenance,
                })
            end

            AddBreakdownNode(goldNode, "yield:economy:gold:expense",
                Locale.Lookup("LOC_TOP_PANEL_GOLD_EXPENSE", -treasury:GetTotalMaintenance()),
                treasury:GetTotalMaintenanceToolTip(), nil, expenseEnhancers)
        end

        if GameCapabilities.HasCapability("CAPABILITY_FAITH")
            and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
            local religion = localPlayer:GetReligion()
            local faithValue = Locale.Lookup("LOC_CAI_TOP_PANEL_BALANCE_AND_RATE",
                FormatBalance(religion:GetFaithBalance()),
                FormatRatePerTurn(FormatValuePerTurn(Round(GetDisplayedFaithYield(localPlayer), 1))))
            local faithDetails = religion:GetFaithYieldToolTip()
            if GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_BLACKDEATH"
                and GetDisplayedFaithYield(localPlayer) ~= religion:GetFaithYield() then
                faithDetails = JoinLines({ faithDetails,
                    Locale.Lookup("LOC_GOVT_PAPAL_SLOT_FAITH_TT", -BLACK_DEATH_PAPAL_SLOT_UPKEEP) })
            end
            AddYieldWithCityBreakdown(economyGroup, "yield:economy:faith",
                Locale.Lookup("LOC_TOP_PANEL_FAITH") .. ": " .. faithValue, faithDetails,
                "LOC_PLAYER_YIELD_FAITH_FROM_CITIES",
                cityYieldTotals.Faith,
                "CAIFaithYield", "FaithPerTurnToolTip")
        end

        if GameCapabilities.HasCapability("CAPABILITY_TOURISM")
            and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
            local tourismRate = Round(localPlayer:GetStats():GetTourism(), 1)
            if tourismRate > 0 then
                local tourismCityTotal = cityYieldTotals.Tourism
                local tourismCityLabel = LookupNamedValue(
                    "LOC_PLAYER_YIELD_CULTURE_FROM_CITIES", tourismRate)
                local tourismEnhancers = {
                    [tourismCityLabel] = function(tourismCities)
                        AddCityYieldRows(tourismCities, "yield:economy:tourism:cities",
                            "CAITourismYield", nil)
                        local otherCityTourism = tourismRate - tourismCityTotal
                        if math.abs(otherCityTourism) >= 0.05 then
                            AddLeaf(tourismCities, "yield:economy:tourism:cities:other", function()
                                return Locale.Lookup("LOC_CAI_REPORTS_OTHER_CITY_YIELD",
                                    FormatValuePerTurn(otherCityTourism))
                            end)
                        end
                    end,
                }
                AddBreakdownNode(economyGroup, "yield:economy:tourism",
                    Locale.Lookup("LOC_TOP_PANEL_TOURISM") .. ": "
                        .. FormatRatePerTurn(FormatBalance(tourismRate)),
                    localPlayer:GetStats():GetTourismToolTip(), nil, tourismEnhancers)
            end
        end

        if m_isExp2 then
            local favorValue = Locale.Lookup("LOC_CAI_TOP_PANEL_BALANCE_AND_RATE",
                FormatBalance(localPlayer:GetFavor()),
                FormatRatePerTurn(FormatValuePerTurn(localPlayer:GetFavorPerTurn())))
            AddBreakdownNode(economyGroup, "yield:economy:favor",
                Locale.Lookup("LOC_CAI_TOP_PANEL_FAVOR") .. ": " .. favorValue,
                localPlayer:GetFavorPerTurnToolTip(), function()
                    return Locale.Lookup("LOC_WORLD_CONGRESS_TOP_PANEL_FAVOR_TOOLTIP")
                end)
        end

        if GameCapabilities.HasCapability("CAPABILITY_TOP_PANEL_ENVOYS") then
            local influence = localPlayer:GetInfluence()
            local envoyNode = MakeTreeItem({
                Label = function()
                    return Locale.Lookup("LOC_CAI_TOP_PANEL_ENVOYS_SUMMARY",
                        influence:GetTokensToGive(), Round(influence:GetPointsEarned(), 1),
                        influence:GetPointsThreshold())
                end,
                Tooltip = function()
                    return Locale.Lookup("LOC_TOP_PANEL_INFLUENCE_TOOLTIP_SOURCES_HELP")
                end,
                FocusKey = "yield:economy:envoys",
            })
            economyGroup:AddChild(envoyNode)
            AddLeaf(envoyNode, "yield:economy:envoys:rate", function()
                return Locale.Lookup("LOC_TOP_PANEL_INFLUENCE_TOOLTIP_POINTS_RATE",
                    Round(influence:GetPointsPerTurn(), 1))
            end)
            AddLeaf(envoyNode, "yield:economy:envoys:threshold", function()
                return Locale.Lookup("LOC_TOP_PANEL_INFLUENCE_TOOLTIP_POINTS_THRESHOLD",
                    influence:GetTokensPerThreshold(), influence:GetPointsThreshold())
            end)
        end

        local playerWMDs = localPlayer:GetWMDs()
        for entry in GameInfo.WMDs() do
            if entry.WeaponType == "WMD_NUCLEAR_DEVICE" then
                local count = playerWMDs:GetWeaponCount(entry.Index)
                if count > 0 then
                    AddLeaf(economyGroup, "yield:economy:wmd:nuclear", function()
                        return Locale.Lookup("LOC_CAI_TOP_PANEL_NUCLEAR_DEVICES", count)
                    end)
                end
            elseif entry.WeaponType == "WMD_THERMONUCLEAR_DEVICE" then
                local count = playerWMDs:GetWeaponCount(entry.Index)
                if count > 0 then
                    AddLeaf(economyGroup, "yield:economy:wmd:thermonuclear", function()
                        return Locale.Lookup("LOC_CAI_TOP_PANEL_THERMONUCLEAR_DEVICES", count)
                    end)
                end
            end
        end

        if GameCapabilities.HasCapability("CAPABILITY_TRADE") then
            local trade = localPlayer:GetTrade()
            local capacity = trade:GetOutgoingRouteCapacity()
            if capacity > 0 then
                AddLeaf(economyGroup, "yield:economy:trade", function()
                    return Locale.Lookup("LOC_CAI_TOP_PANEL_TRADE_ROUTES",
                        trade:GetNumOutgoingRoutes(), capacity)
                end, function()
                    return Locale.Lookup("LOC_TOP_PANEL_TRADE_ROUTES_TOOLTIP_SOURCES_HELP")
                end)
            end
        end
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

    local resourceType = kResource.ResourceType
    local extracted = pResources:GetResourceAccumulationPerTurn(resourceType)
    local imports = pResources:GetResourceImportPerTurn(resourceType)
    local bonus = pResources:GetBonusResourcePerTurn(resourceType)
    local unitCost = pResources:GetUnitResourceDemandPerTurn(resourceType)
    local powerCost = pResources:GetPowerResourceDemandPerTurn(resourceType)
    local reserved = pResources:GetReservedResourceAmount(resourceType)
    local accumulation = extracted + imports + bonus
    local consumption = unitCost + powerCost

    return {
        Accumulation = accumulation,
        Extracted = extracted,
        Imports = imports,
        Bonus = bonus,
        UnitCost = unitCost,
        PowerCost = powerCost,
        Consumption = consumption,
        Reserved = reserved,
        Delta = accumulation - consumption,
    }
end

local function FormatResourceEntryLabel(kEntry)
    local source = Locale.Lookup(kEntry.EntryText)
    local control = kEntry.ControlText ~= "-" and Locale.Lookup(kEntry.ControlText) or nil
    local parts = { source }
    if control ~= nil and control ~= "" then
        table.insert(parts, control)
    end
    table.insert(parts, toPlusMinus(kEntry.Amount))
    return table.concat(parts, ", ")
end

local function BuildResourceItem(parent, eResourceType, kSingleResourceData)
    local capturedResType = eResourceType
    local capturedResData = kSingleResourceData
    local kResource = GameInfo.Resources[capturedResType]
    local flow = m_isExp2 and capturedResData.IsStrategic and GetXP2ResourceFlowData(capturedResType) or nil
    local extractionEntries = {}
    local cityStateEntries = {}
    local fallbackEntries = {}
    local namedExtractionTotal = 0
    local namedCityStateTotal = 0

    if flow then
        for ei, kEntry in ipairs(capturedResData.EntryList or {}) do
            local classifiedEntry = { Entry = kEntry, Index = ei }
            if kEntry.ControlText == "LOC_HUD_REPORTS_TRADE_OWNED" then
                table.insert(extractionEntries, classifiedEntry)
                namedExtractionTotal = namedExtractionTotal + kEntry.Amount
            elseif kEntry.ControlText == "LOC_CITY_STATES_SUZERAIN" then
                table.insert(cityStateEntries, classifiedEntry)
                namedCityStateTotal = namedCityStateTotal + kEntry.Amount
            elseif kEntry.EntryText ~= "LOC_PRODUCTION_PANEL_UNITS_TOOLTIP"
                and kEntry.EntryText ~= "LOC_UI_PEDIA_POWER_COST"
                and kEntry.EntryText ~= "LOC_RESOURCE_REPORTS_ITEM_IN_RESERVE"
                and kEntry.EntryText ~= "LOC_RESOURCE_REPORTS_CITY_STATES"
                and kEntry.EntryText ~= "LOC_HUD_REPORTS_MISC_RESOURCE_SOURCE"
                and not (kEntry.EntryText == "" and kEntry.ControlText == "" and kEntry.Amount == 0) then
                table.insert(fallbackEntries, classifiedEntry)
            end
        end
    end

    local resItem = MakeTreeItem({
        Label = function()
            local name = Locale.Lookup(kResource.Name)
            if m_isExp2 and capturedResData.IsStrategic and capturedResData.Stockpile then
                local text = Locale.Lookup("LOC_CAI_REPORTS_RESOURCE_STOCKPILE",
                    name, capturedResData.Stockpile, capturedResData.Maximum or 0)
                if flow then
                    text = JoinLines({ text, Locale.Lookup("LOC_HUD_REPORTS_PER_TURN", toPlusMinus(flow.Delta)) })
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
                    return JoinLines({
                        Locale.Lookup("LOC_CAI_REPORTS_AMENITIES_PROVIDED", numCities),
                        table.concat(cityNames, "[NEWLINE]")
                    })
                end
            end
            return nil
        end,
        FocusKey = "res:" .. tostring(capturedResType),
    })
    local resourceHasChildren = #(capturedResData.EntryList or {}) > 0 or flow ~= nil
    if resourceHasChildren then
        parent:AddChild(resItem)

        if flow then
            if flow.Reserved > 0 then
                AddLeaf(resItem, "res:" .. tostring(capturedResType) .. ":reserved", function()
                    return "-" .. flow.Reserved .. " " .. Locale.Lookup("LOC_RESOURCE_ITEM_IN_RESERVE")
                end)
            end

            local hasAccumulationDetails = flow.Extracted > 0 or flow.Imports > 0 or flow.Bonus > 0
            if hasAccumulationDetails then
                local accumulationNode = MakeTreeItem({
                    Label = function()
                        return Locale.Lookup("LOC_RESOURCE_ACCUMULATION_PER_TURN", flow.Accumulation)
                    end,
                    FocusKey = "res:" .. tostring(capturedResType) .. ":accumulation",
                })
                resItem:AddChild(accumulationNode)
                if flow.Extracted > 0 then
                    local miscellaneousExtraction = math.max(0, flow.Extracted - namedExtractionTotal)
                    if #extractionEntries > 0 or miscellaneousExtraction > 0 then
                        local extractionNode = MakeTreeItem({
                            Label = function()
                                return Locale.Lookup("LOC_RESOURCE_ACCUMULATION_PER_TURN_EXTRACTED", flow.Extracted)
                            end,
                            FocusKey = "res:" .. tostring(capturedResType) .. ":accumulation:extracted",
                        })
                        accumulationNode:AddChild(extractionNode)
                        for _, classifiedEntry in ipairs(extractionEntries) do
                            local capturedEntry = classifiedEntry.Entry
                            local capturedEI = classifiedEntry.Index
                            AddLeaf(extractionNode,
                                "res:" .. tostring(capturedResType) .. ":entry:" .. capturedEI,
                                function() return FormatResourceEntryLabel(capturedEntry) end)
                        end
                        if miscellaneousExtraction > 0 then
                            AddLeaf(extractionNode,
                                "res:" .. tostring(capturedResType) .. ":accumulation:extracted:misc",
                                function()
                                    return Locale.Lookup("LOC_HUD_REPORTS_MISC_RESOURCE_SOURCE")
                                        .. ", " .. toPlusMinus(miscellaneousExtraction)
                                end)
                        end
                    else
                        AddLeaf(accumulationNode,
                            "res:" .. tostring(capturedResType) .. ":accumulation:extracted",
                            function()
                                return Locale.Lookup("LOC_RESOURCE_ACCUMULATION_PER_TURN_EXTRACTED", flow.Extracted)
                            end)
                    end
                end
                if flow.Imports > 0 then
                    local miscellaneousCityStates = math.max(0, flow.Imports - namedCityStateTotal)
                    if #cityStateEntries > 0 then
                        local cityStateNode = MakeTreeItem({
                            Label = function()
                                return Locale.Lookup("LOC_RESOURCE_ACCUMULATION_PER_TURN_FROM_CITY_STATES", flow.Imports)
                            end,
                            FocusKey = "res:" .. tostring(capturedResType) .. ":accumulation:imports",
                        })
                        accumulationNode:AddChild(cityStateNode)
                        for _, classifiedEntry in ipairs(cityStateEntries) do
                            local capturedEntry = classifiedEntry.Entry
                            local capturedEI = classifiedEntry.Index
                            AddLeaf(cityStateNode,
                                "res:" .. tostring(capturedResType) .. ":entry:" .. capturedEI,
                                function() return FormatResourceEntryLabel(capturedEntry) end)
                        end
                        if miscellaneousCityStates > 0 then
                            AddLeaf(cityStateNode,
                                "res:" .. tostring(capturedResType) .. ":accumulation:imports:misc",
                                function()
                                    return Locale.Lookup("LOC_HUD_REPORTS_MISC_RESOURCE_SOURCE")
                                        .. ", " .. toPlusMinus(miscellaneousCityStates)
                                end)
                        end
                    else
                        AddLeaf(accumulationNode,
                            "res:" .. tostring(capturedResType) .. ":accumulation:imports",
                            function()
                                return Locale.Lookup("LOC_RESOURCE_ACCUMULATION_PER_TURN_FROM_CITY_STATES", flow.Imports)
                            end)
                    end
                end
                if flow.Bonus > 0 then
                    AddLeaf(accumulationNode, "res:" .. tostring(capturedResType) .. ":accumulation:bonus",
                        function()
                            return Locale.Lookup("LOC_RESOURCE_ACCUMULATION_PER_TURN_FROM_BONUS_SOURCES", flow.Bonus)
                        end)
                end
            else
                AddLeaf(resItem, "res:" .. tostring(capturedResType) .. ":accumulation", function()
                    return Locale.Lookup("LOC_RESOURCE_ACCUMULATION_PER_TURN", flow.Accumulation)
                end)
            end

            if flow.Consumption > 0 then
                local consumptionNode = MakeTreeItem({
                    Label = function() return Locale.Lookup("LOC_RESOURCE_CONSUMPTION", flow.Consumption) end,
                    FocusKey = "res:" .. tostring(capturedResType) .. ":consumption",
                })
                resItem:AddChild(consumptionNode)
                if flow.UnitCost > 0 then
                    AddLeaf(consumptionNode, "res:" .. tostring(capturedResType) .. ":consumption:units",
                        function()
                            return Locale.Lookup("LOC_RESOURCE_UNIT_CONSUMPTION_PER_TURN", flow.UnitCost)
                        end)
                end
                if flow.PowerCost > 0 then
                    AddLeaf(consumptionNode, "res:" .. tostring(capturedResType) .. ":consumption:power",
                        function()
                            return Locale.Lookup("LOC_RESOURCE_POWER_CONSUMPTION_PER_TURN", flow.PowerCost)
                        end)
                end
            end
        end

        local detailEntries = flow and fallbackEntries or capturedResData.EntryList or {}
        if #detailEntries > 0 then
            local detailsNode = MakeTreeItem({
                Label = function() return Locale.Lookup("LOC_CAI_REPORTS_RESOURCE_DETAILS") end,
                FocusKey = "res:" .. tostring(capturedResType) .. ":details",
            })
            resItem:AddChild(detailsNode)

            for ei, detailEntry in ipairs(detailEntries) do
                local capturedEntry = flow and detailEntry.Entry or detailEntry
                local capturedEI = flow and detailEntry.Index or ei
                local detail = MakeStaticText({
                    Label = function() return FormatResourceEntryLabel(capturedEntry) end,
                    FocusKey = "res:" .. tostring(capturedResType) .. ":entry:" .. capturedEI,
                })
                detailsNode:AddChild(detail)
            end
        end
    else
        local leafLabel = function()
            local baseLabel = resItem:GetLabel()
            local tooltip = resItem:GetTooltip()
            if tooltip ~= nil and tooltip ~= "" then
                return JoinLines({ baseLabel, tooltip })
            end
            return baseLabel
        end
        parent:AddChild(MakeStaticText({
            Label = leafLabel,
            FocusKey = "res:" .. tostring(capturedResType),
        }))
    end
end

local function RebuildResourcesTree(tree)
    local capture = mgr:CaptureFocusKey(tree)
    tree:ClearChildren()

    local strategic = {}
    local luxury = {}
    local bonus = {}

    local includedResourceTypes = {}
    for eResourceType, kSingleResourceData in pairs(m_caiResourceData) do
        local flow = m_isExp2 and kSingleResourceData.IsStrategic and GetXP2ResourceFlowData(eResourceType) or nil
        local hasStrategicFlow = flow ~= nil
            and (flow.Accumulation ~= 0 or flow.Consumption ~= 0 or flow.Reserved ~= 0)
        if next(kSingleResourceData.EntryList) or
            (m_isExp2 and kSingleResourceData.IsStrategic
                and ((kSingleResourceData.Stockpile and kSingleResourceData.Stockpile > 0) or hasStrategicFlow)) then
            includedResourceTypes[eResourceType] = true
            if kSingleResourceData.IsStrategic then
                table.insert(strategic, { type = eResourceType, data = kSingleResourceData })
            elseif kSingleResourceData.IsLuxury then
                table.insert(luxury, { type = eResourceType, data = kSingleResourceData })
            else
                table.insert(bonus, { type = eResourceType, data = kSingleResourceData })
            end
        end
    end

    if m_isExp2 then
        local localPlayer = Players[m_localPlayerID]
        local playerResources = localPlayer and localPlayer:GetResources() or nil
        if playerResources then
            for resource in GameInfo.Resources() do
                if resource.ResourceClassType == "RESOURCECLASS_STRATEGIC"
                    and not includedResourceTypes[resource.Index] then
                    local flow = GetXP2ResourceFlowData(resource.Index)
                    local stockpile = playerResources:GetResourceAmount(resource.ResourceType)
                    if stockpile > 0 or (flow and (flow.Accumulation ~= 0 or flow.Consumption ~= 0
                        or flow.Reserved ~= 0)) then
                        table.insert(strategic, {
                            type = resource.Index,
                            data = {
                                EntryList = {},
                                IsStrategic = true,
                                IsLuxury = false,
                                IsBonus = false,
                                Total = flow and flow.Delta or 0,
                                Maximum = playerResources:GetResourceStockpileCap(resource.ResourceType),
                                Stockpile = stockpile,
                            },
                        })
                    end
                end
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
                    return JoinLines({
                        Locale.Lookup(capturedCat.label),
                        Locale.Lookup("LOC_CAI_REPORTS_RESOURCE_COUNT", #capturedCat.items)
                    })
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
                local parts = { Locale.Lookup(capturedCity.CityName) }
                if capturedCity.IsCapital then
                    table.insert(parts, Locale.Lookup("LOC_CAI_CITY_STATUS_CAPITAL"))
                end
                return AppendRelativePlotLocation(JoinLines(parts), capturedCity.CAIPlotIndex)
            end,
            Tooltip = function()
                local parts = {}
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

                return table.concat(parts, "[NEWLINE]")
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
        { label = Locale.Lookup("LOC_CAI_REPORTS_SORT_NAME"),         value = "name" },
        { label = Locale.Lookup("LOC_HUD_REPORTS_HEADER_POPULATION"), value = "population" },
        { label = Locale.Lookup("LOC_CAI_REPORTS_SORT_DEFENSE"),      value = "defense" },
        { label = Locale.Lookup("LOC_CAI_REPORTS_SORT_HAPPINESS"),    value = "happiness" },
        { label = Locale.Lookup("LOC_CAI_REPORTS_SORT_GROWTH"),       value = "growth" },
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
                return Locale.Lookup("LOC_CAI_REPORTS_GOSSIP_ENTRY", turn, leaderName, description)
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
    local options = { priority = PopupPriority.Medium }
    if m_pendingOpenFocusKey ~= nil then
        options.focus = m_pendingOpenFocusKey
    end
    m_pendingOpenFocusKey = nil
    mgr:Push(m_panel, options)
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
    mgr = assert(ExposedMembers.CAI_UIManager,
        "CAI Report Screen opened before the accessibility UI manager was available")

    local reportsRequest = ExposedMembers.CAIReports
    if reportsRequest and reportsRequest.PendingFocusKey then
        m_pendingOpenFocusKey = reportsRequest.PendingFocusKey
        reportsRequest.PendingFocusKey = nil
    end

    orig(tabToOpen)
    RefreshCAIData()
    GatherGossip()
    FilterCAIGossip()
    PushPanel()
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
