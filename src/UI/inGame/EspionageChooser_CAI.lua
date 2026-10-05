include("caiUtils")
include("Civ6Common")

if IsExpansion2Active() then
    include("EspionageChooser_Expansion1")
elseif IsExpansion1Active() then
    include("EspionageChooser_Expansion1")
else
    include("EspionageChooser")
end

local mgr                    = ExposedMembers.CAI_UIManager

local PANEL_ID               = "CAIEspionageChooser_Panel"
local DEST_TREE_ID           = "CAIEspionageChooser_DestinationTree"
local SORT_ID                = "CAIEspionageChooser_DestinationSort"
local MISSION_FILTER_ID      = "CAIEspionageChooser_MissionFilter"
local MISSION_LIST_ID        = "CAIEspionageChooser_MissionList"

local m_panel                = nil ---@type UIWidget|nil
local m_destTree             = nil ---@type UIWidget|nil
local m_sort                 = nil ---@type UIWidget|nil
local m_missionFilter        = nil ---@type UIWidget|nil
local m_catYourCities        = nil ---@type UIWidget|nil
local m_catOtherCivs         = nil ---@type UIWidget|nil
local m_catCityStates        = nil ---@type UIWidget|nil
local m_missionList          = nil ---@type UIWidget|nil
local m_dialog               = nil ---@type UIWidget|nil

local m_capturedDestinations = {} ---@type table[]
local m_capturedMissions     = {} ---@type table[]

local m_caiCity              = nil
local m_caiSpy               = nil
local m_caiIsDestinationMode = true
local m_sortColumn           = nil
local m_sortAscending        = true
local m_missionFilterHash    = nil

local SORT_COLUMNS = {
    { key = "transitTime", label = "LOC_CAI_ESPIONAGE_SORT_TRAVEL" },
    { key = "establishTime", label = "LOC_CAI_ESPIONAGE_SORT_ESTABLISH" },
    { key = "missionCount", label = "LOC_CAI_ESPIONAGE_SORT_MISSIONS" },
    { key = "districtCount", label = "LOC_CAI_ESPIONAGE_SORT_DISTRICTS" },
}

-- ============================================================================
-- Helpers
-- ============================================================================

local function GetStackChildren(stack)
    if not stack then return {} end
    return stack:GetChildren() or {}
end

local function FindNewButton(stack, usedControls)
    local children = GetStackChildren(stack)
    for i = #children, 1, -1 do
        local child = children[i]
        if child and not usedControls[child] then
            usedControls[child] = true
            return child
        end
    end
    return nil
end

local function GetUsedControls(capturedRows)
    local used = {}
    for _, cap in ipairs(capturedRows) do
        if cap.button then used[cap.button] = true end
    end
    return used
end

local function ReadVanillaDestinationMode()
    if Controls.MissionPanel and not Controls.MissionPanel:IsHidden() then
        return false
    end
    if Controls.DestinationPanel and not Controls.DestinationPanel:IsHidden() then
        return true
    end
    return UI.GetInterfaceMode() == InterfaceModeTypes.SPY_TRAVEL_TO_CITY
end

local function GetActiveModeWidget()
    return m_caiIsDestinationMode and m_destTree or m_missionList
end

local function GetDistrictForPlotID(city, districtPlotID)
    local cityDistricts = city and city:GetDistricts()
    if cityDistricts then
        for _, district in cityDistricts:Members() do
            local dPlot = Map.GetPlot(district:GetX(), district:GetY())
            if dPlot and dPlot:GetIndex() == districtPlotID then
                local dInfo = GameInfo.Districts[district:GetType()]
                return dInfo, dPlot
            end
        end
    end
    return nil, nil
end

local function GetDistrictNames(city)
    local names = {}
    local cityDistricts = city:GetDistricts()
    if cityDistricts then
        for _, district in cityDistricts:Members() do
            if district:IsComplete() then
                local dInfo = GameInfo.Districts[district:GetType()]
                if dInfo and dInfo.DistrictType ~= "DISTRICT_WONDER" and dInfo.DistrictType ~= "DISTRICT_CITY_CENTER" then
                    names[#names + 1] = Locale.Lookup(dInfo.Name)
                end
            end
        end
    end
    return names
end

-- ============================================================================
-- Compute missions for a city (mirrors vanilla RefreshMissionList logic)
-- ============================================================================

local function ComputeMissionsForCity(city, spy)
    local missions = {}
    local cityPlot = Map.GetPlot(city:GetX(), city:GetY())
    if not cityPlot or not spy then return missions end

    if city:GetOwner() == Game.GetLocalPlayer() then
        for operation in GameInfo.UnitOperations() do
            if operation.OperationType == "UNITOPERATION_SPY_COUNTERSPY" then
                local canStart, results = UnitManager.CanStartOperation(spy, operation.Hash, cityPlot, false, true)
                if canStart and results and results[UnitOperationResults.PLOTS] then
                    for _, districtPlotID in ipairs(results[UnitOperationResults.PLOTS]) do
                        local districtName = nil
                        local dInfo = GetDistrictForPlotID(city, districtPlotID)
                        if dInfo then
                            districtName = Locale.Lookup(dInfo.Name)
                        end
                        missions[#missions + 1] = {
                            operation = operation,
                            missionType = "counterspy",
                            districtPlotID = districtPlotID,
                            districtName = districtName,
                            details = districtName and Locale.Lookup("LOC_ESPIONAGECHOOSER_COUNTERSPY", districtName) or
                                "",
                            disabled = false,
                        }
                    end
                end
            end
        end
    else
        for operation in GameInfo.UnitOperations() do
            if operation.CategoryInUI == "OFFENSIVESPY" then
                local canStart, results = UnitManager.CanStartOperation(spy, operation.Hash, cityPlot, false, true)
                if canStart then
                    local addedOperation = false
                    if results and results[UnitOperationResults.PLOTS] then
                        for _, districtPlotID in ipairs(results[UnitOperationResults.PLOTS]) do
                            local pTargetPlot = Map.GetPlotByIndex(districtPlotID)
                            if pTargetPlot then
                                local districtName = nil
                                local cityDistricts = city:GetDistricts()
                                if cityDistricts then
                                    for _, district in cityDistricts:Members() do
                                        local dPlot = Map.GetPlot(district:GetX(), district:GetY())
                                        if dPlot and dPlot:GetIndex() == districtPlotID then
                                            local dInfo = GameInfo.Districts[district:GetType()]
                                            if dInfo then
                                                districtName = Locale.Lookup(dInfo.Name)
                                            end
                                            break
                                        end
                                    end
                                end

                                local turnsToComplete = UnitManager.GetTimeToComplete(operation.Index, spy)
                                local probability = nil
                                if operation.Hash ~= UnitOperationTypes.SPY_COUNTERSPY then
                                    local resultProbability = UnitManager.GetResultProbability(operation.Index, spy,
                                        pTargetPlot)
                                    if resultProbability and resultProbability["ESPIONAGE_SUCCESS_UNDETECTED"] then
                                        local p = resultProbability["ESPIONAGE_SUCCESS_UNDETECTED"]
                                        if resultProbability["ESPIONAGE_SUCCESS_MUST_ESCAPE"] then
                                            p = p + resultProbability["ESPIONAGE_SUCCESS_MUST_ESCAPE"]
                                        end
                                        probability = math.floor((p * 100) + 0.5)
                                    end
                                end

                                missions[#missions + 1] = {
                                    operation = operation,
                                    missionType = "offensive",
                                    targetPlot = pTargetPlot,
                                    turnsToComplete = turnsToComplete,
                                    probability = probability,
                                    districtName = districtName,
                                    details = GetFormattedOperationDetailText(operation, spy, city),
                                    disabled = false,
                                }
                                addedOperation = true
                            end
                        end
                    end
                    if not addedOperation then
                        local turnsToComplete = UnitManager.GetTimeToComplete(operation.Index, spy)
                        missions[#missions + 1] = {
                            operation = operation,
                            missionType = "offensive",
                            targetPlot = cityPlot,
                            turnsToComplete = turnsToComplete,
                            details = GetFormattedOperationDetailText(operation, spy, city),
                            disabled = false,
                        }
                    end
                else
                    if results and results[UnitOperationResults.FAILURE_REASONS] then
                        local failureReasons = table.concat(results[UnitOperationResults.FAILURE_REASONS], "[NEWLINE]")
                        local districtName = Locale.Lookup("LOC_DISTRICT_CITY_CENTER_NAME")
                        missions[#missions + 1] = {
                            operation = operation,
                            missionType = "disabled",
                            targetPlot = cityPlot,
                            turnsToComplete = UnitManager.GetTimeToComplete(operation.Index, spy),
                            districtName = districtName,
                            failureReasons = failureReasons,
                            disabled = true,
                        }
                    end
                end
            end
        end
    end
    return missions
end

-- ============================================================================
-- Label / Tooltip builders
-- ============================================================================

local function GetCivName(playerID)
    local config = PlayerConfigurations[playerID]
    if config then
        return Locale.Lookup(config:GetCivilizationShortDescription())
    end
    return ""
end

local function BuildDestinationLabel(cap)
    local city = cap.city
    local ownerName = GetCivName(city:GetOwner())
    local cityName = Locale.Lookup(city:GetName())
    if city:IsCapital() and Players[city:GetOwner()]:IsMajor() then
        cityName = cityName .. ", " .. Locale.Lookup("LOC_CAI_CITY_STATUS_CAPITAL")
    end
    if ownerName ~= "" then
        return cityName .. ", " .. ownerName
    end
    return cityName
end

local function BuildDestinationTooltip(cap)
    local parts = {}
    local travelText = Locale.Lookup("LOC_ESPIONAGECHOOSER_TRAVEL_TIME_TOOLTIP", cap.transitTime, cap.establishTime)
    travelText = string.gsub(travelText, "%[NEWLINE%]", ", ")
    CAIText.AppendIfNonEmpty(parts, travelText)
    if cap.missionCount then
        CAIText.AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_ESPIONAGE_AVAILABLE_MISSIONS", cap.missionCount))
    end
    if #cap.districts > 0 then
        CAIText.AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_ESPIONAGE_CITY_DISTRICTS", table.concat(cap.districts, "[NEWLINE]")))
    end
    return table.concat(parts, "[NEWLINE]")
end

local function BuildMissionLabel(mis)
    local parts = {}
    CAIText.AppendIfNonEmpty(parts, Locale.Lookup(mis.operation.Description))
    if mis.districtName then
        CAIText.AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_ESPIONAGE_MISSION_DISTRICT", mis.districtName))
    end
    if mis.turnsToComplete then
        CAIText.AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_ESPIONAGE_MISSION_TURNS", tostring(mis.turnsToComplete)))
    end
    if mis.probability then
        CAIText.AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_ESPIONAGE_MISSION_PROBABILITY", mis.probability .. "%"))
    end
    return table.concat(parts, "[NEWLINE]")
end

local function BuildMissionTooltip(mis)
    if mis.details and mis.details ~= "" then return mis.details end
    if mis.failureReasons and mis.failureReasons ~= "" then return mis.failureReasons end
    return ""
end

-- ============================================================================
-- Confirmation Dialog (destination mode)
-- ============================================================================

local function CloseConfirmDialog()
    if m_dialog and mgr then
        mgr:RemoveFromStack(m_dialog:GetId())
        m_dialog = nil
    end
end

local function OpenConfirmDialog(destIndex)
    CloseConfirmDialog()

    local cap = m_capturedDestinations[destIndex]
    if not cap or not cap.button then return end

    cap.button:DoLeftClick()

    local summaryWidgets = {}
    summaryWidgets[#summaryWidgets + 1] = mgr:CreateWidget(
        mgr:GenerateWidgetId("CAIEspionage_DestSummary"),
        "StaticText",
        { Label = function() return BuildDestinationLabel(cap) .. ", " .. BuildDestinationTooltip(cap) end }
    )

    local confirmBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIEspionage_ConfirmBtn"), "Button", {
        Label = function() return Locale.Lookup("LOC_CONFIRM") end,
    })
    confirmBtn:On("activate", function()
        Controls.ConfirmButton:DoLeftClick()
    end)

    local reselectBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIEspionage_ReselectBtn"), "Button", {
        Label = function() return Locale.Lookup("LOC_CAI_ESPIONAGE_CONFIRM_CANCEL") end,
    })
    reselectBtn:On("activate", function()
        Controls.CancelButton:DoLeftClick()
    end)

    m_dialog = mgr.WidgetHelpers.MakeGeneralDialog(
        function() return Locale.Lookup("LOC_CAI_ESPIONAGE_CONFIRM_TITLE") end,
        { confirmBtn, reselectBtn },
        summaryWidgets,
        1
    )
    if not m_dialog then return end

    m_dialog:AddInputBindings({
        {
            Key = Keys.VK_ESCAPE,
            MSG = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_CLOSE",
            Action = function()
                CloseConfirmDialog()
                Controls.CancelButton:DoLeftClick()
                return true
            end,
        },
    })
    mgr:Push(m_dialog)
end

-- ============================================================================
-- Widget Building
-- ============================================================================

local function RebuildMissionFilter()
    local operations = {}
    for _, cap in ipairs(m_capturedDestinations) do
        for _, mission in ipairs(cap.missions) do
            if not mission.disabled then
                operations[mission.operation.Hash] = mission.operation
            end
        end
    end

    local sortedOperations = {}
    for _, operation in pairs(operations) do
        table.insert(sortedOperations, operation)
    end
    table.sort(sortedOperations, function(a, b)
        local comparison = Locale.Compare(Locale.Lookup(a.Description), Locale.Lookup(b.Description))
        if comparison ~= 0 then return comparison < 0 end
        return a.Hash < b.Hash
    end)

    local selectionReset = m_missionFilterHash and not operations[m_missionFilterHash]
    if selectionReset then
        m_missionFilterHash = nil
    end

    local options = {
        { label = Locale.Lookup("LOC_CAI_ESPIONAGE_FILTER_ALL_MISSIONS"), value = nil },
    }
    local selectedIndex = 1
    for _, operation in ipairs(sortedOperations) do
        table.insert(options, { label = Locale.Lookup(operation.Description), value = operation.Hash })
        if operation.Hash == m_missionFilterHash then selectedIndex = #options end
    end

    local capture = mgr:CaptureFocusKey(m_missionFilter)
    m_missionFilter:SetOptions(options)
    m_missionFilter:SetSelectedIndex(selectedIndex, true)
    if capture and selectionReset then
        capture = { key = m_missionFilter.FocusKey, path = {} }
    end
    mgr:RestoreFocus(m_missionFilter, capture)
end

local function RebuildDestinationTree(refreshGameData)
    if not mgr or not m_destTree then return end

    local capture = mgr:CaptureFocusKey(m_destTree)
    m_catYourCities:ClearChildren()
    m_catOtherCivs:ClearChildren()
    m_catCityStates:ClearChildren()

    local groups = { {}, {}, {} }
    if refreshGameData ~= false then
        for i, cap in ipairs(m_capturedDestinations) do
            cap.naturalIndex = i
            cap.missions = ComputeMissionsForCity(cap.city, m_caiSpy)
            cap.missionCount = 0
            for _, mission in ipairs(cap.missions) do
                if not mission.disabled then cap.missionCount = cap.missionCount + 1 end
            end
            cap.districtCount = #cap.districts
        end
        RebuildMissionFilter()
    end

    for _, cap in ipairs(m_capturedDestinations) do
        local matchesMission = m_missionFilterHash == nil
        if not matchesMission then
            for _, mission in ipairs(cap.missions) do
                if not mission.disabled and mission.operation.Hash == m_missionFilterHash then
                    matchesMission = true
                    break
                end
            end
        end
        if matchesMission then
            local owner = cap.city:GetOwner()
            local influence = Players[owner]:GetInfluence()
            local group = owner == Game.GetLocalPlayer() and 1
                or (influence and influence:CanReceiveInfluence()) and 3 or 2
            table.insert(groups[group], cap)
        end
    end

    local categories = { m_catYourCities, m_catOtherCivs, m_catCityStates }
    for groupIndex, category in ipairs(categories) do
        local entries = groups[groupIndex]
        if m_sortColumn then
            table.sort(entries, function(a, b)
                local av, bv = a[m_sortColumn], b[m_sortColumn]
                if av == bv then return a.naturalIndex < b.naturalIndex end
                if m_sortAscending then return av < bv end
                return av > bv
            end)
        end
        category:SetHiddenPredicate(function() return #entries == 0 end)
        for _, cap in ipairs(entries) do
            local city = cap.city
            local focusKey = "destination:" .. city:GetOwner() .. ":" .. city:GetID()

            local row = mgr:CreateWidget(mgr:GenerateWidgetId("CAIEspionage_Dest"), "TreeItem", {
                Label = function() return BuildDestinationLabel(cap) end,
                Tooltip = function() return BuildDestinationTooltip(cap) end,
                FocusKey = focusKey,
            })

            for mi, mis in ipairs(cap.missions) do
                local child = mgr:CreateWidget(mgr:GenerateWidgetId("CAIEspionage_MissionChild"), "TreeItem", {
                    Label = function() return BuildMissionLabel(mis) end,
                    Tooltip = function() return BuildMissionTooltip(mis) end,
                    FocusKey = focusKey .. ":mission:" .. tostring(mis.operation.Hash) .. ":" ..
                        tostring(mis.districtPlotID or (mis.targetPlot and mis.targetPlot:GetIndex()) or mi),
                })
                row:AddChild(child)
            end

            row:On("activate", function()
                OpenConfirmDialog(cap.naturalIndex)
            end)

            category:AddChild(row)
        end
    end

    mgr:RestoreFocus(m_destTree, capture)
end

local function RebuildMissionList()
    if not mgr or not m_missionList then return end

    local capture = mgr:CaptureFocusKey(m_missionList)
    m_missionList:ClearChildren()

    local missions = m_capturedMissions
    if #missions == 0 then
        if not m_caiCity or not m_caiSpy then
            mgr:RestoreFocus(m_missionList, capture)
            return
        end
        missions = ComputeMissionsForCity(m_caiCity, m_caiSpy)
    end
    for i, mis in ipairs(missions) do
        local focusKey
        if mis.missionType == "counterspy" then
            focusKey = "counterspy:" .. tostring(mis.districtPlotID or i)
        elseif mis.targetPlot then
            focusKey = "mission:" .. tostring(mis.operation.Hash) .. ":" .. tostring(mis.targetPlot:GetIndex())
        else
            focusKey = "mission:" .. tostring(mis.operation.Hash) .. ":" .. tostring(i)
        end

        local row = mgr:CreateWidget(mgr:GenerateWidgetId("CAIEspionage_Mission"), "Button", {
            Label = function() return BuildMissionLabel(mis) end,
            Tooltip = function() return BuildMissionTooltip(mis) end,
            DisabledPredicate = function()
                if mis.button then return mis.button:IsDisabled() end
                return true
            end,
            FocusKey = focusKey,
        })
        row:On("activate", function(w)
            if w:IsDisabled() then return end
            if mis.button and not mis.button:IsHidden() and not mis.button:IsDisabled() then
                mis.button:DoLeftClick()
            end
        end)
        m_missionList:AddChild(row)
    end

    mgr:RestoreFocus(m_missionList, capture)
end

local function RebuildWidgets()
    RebuildDestinationTree()
    RebuildMissionList()
end

-- ============================================================================
-- Panel Lifecycle
-- ============================================================================

local function GetGainSourcesText()
    if not m_caiCity then return "" end
    local player = Players[Game.GetLocalPlayer()]
    if not player then return "" end
    local playerDiplomacy = player:GetDiplomacy()
    if not playerDiplomacy then return "" end
    local turnsRemaining = playerDiplomacy:GetSourceTurnsRemaining(m_caiCity)
    if turnsRemaining > 0 then
        return Locale.Lookup("LOC_CAI_ESPIONAGE_GAIN_SOURCES_ACTIVE", turnsRemaining)
    end
    return Locale.Lookup("LOC_CAI_ESPIONAGE_GAIN_SOURCES_INACTIVE")
end

local function BuildPanelLabel()
    if m_caiIsDestinationMode then
        return Locale.Lookup("LOC_ESPIONAGECHOOSER_PANEL_HEADER")
    end

    local label = Locale.Lookup("LOC_ESPIONAGECHOOSER_CHOOSE_MISSION")
    local boostText = GetGainSourcesText()
    if boostText ~= "" then
        label = label .. ", " .. boostText
    end
    return label
end

local function BuildPanel()
    m_panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = BuildPanelLabel,
    })

    m_destTree = mgr:CreateWidget(DEST_TREE_ID, "Tree", {
        Label = function()
            return Locale.Lookup("LOC_ESPIONAGECHOOSER_PANEL_HEADER")
        end,
        HiddenPredicate = function() return not m_caiIsDestinationMode end,
    })
    m_catYourCities = mgr:CreateWidget("CAIEspionageChooser_CatYour", "TreeItem", {
        Label = function() return Locale.Lookup("LOC_CAI_TRADE_ROUTE_YOUR_CITIES") end,
        FocusKey = "cat:your_cities",
    })
    m_catOtherCivs = mgr:CreateWidget("CAIEspionageChooser_CatOther", "TreeItem", {
        Label = function() return Locale.Lookup("LOC_CAI_TRADE_ROUTE_OTHER_CIVS") end,
        FocusKey = "cat:other_civs",
    })
    m_catCityStates = mgr:CreateWidget("CAIEspionageChooser_CatCityStates", "TreeItem", {
        Label = function() return Locale.Lookup("LOC_CAI_TRADE_ROUTE_CITY_STATES") end,
        FocusKey = "cat:city_states",
    })
    m_destTree:AddChild(m_catYourCities)
    m_destTree:AddChild(m_catOtherCivs)
    m_destTree:AddChild(m_catCityStates)
    m_panel:AddChild(m_destTree)

    m_sort = mgr:CreateWidget(SORT_ID, "Dropdown", {
        Label = function() return Locale.Lookup("LOC_CAI_ESPIONAGE_ORDER_BY") end,
        FocusKey = "espionage:destination-sort",
        HiddenPredicate = function() return not m_caiIsDestinationMode end,
    })
    local options = { { label = Locale.Lookup("LOC_CAI_DATATABLE_SORT_NATURAL"),
        value = { column = nil, ascending = true } } }
    for _, column in ipairs(SORT_COLUMNS) do
        local label = Locale.Lookup(column.label)
        local isTime = column.key == "transitTime" or column.key == "establishTime"
        local ascendingDescription = isTime and "LOC_CAI_SORT_FASTEST_FIRST" or "LOC_CAI_SORT_FEWEST_FIRST"
        local descendingDescription = isTime and "LOC_CAI_SORT_SLOWEST_FIRST" or "LOC_CAI_SORT_MOST_FIRST"
        table.insert(options, { label = label .. "[NEWLINE]" .. Locale.Lookup(ascendingDescription),
            value = { column = column.key, ascending = true } })
        table.insert(options, { label = label .. "[NEWLINE]" .. Locale.Lookup(descendingDescription),
            value = { column = column.key, ascending = false } })
    end
    m_sort:SetOptions(options)
    local selectedIndex = 1
    for i, option in ipairs(options) do
        if option.value.column == m_sortColumn and
            (m_sortColumn == nil or option.value.ascending == m_sortAscending) then
            selectedIndex = i
            break
        end
    end
    m_sort:SetSelectedIndex(selectedIndex, true)
    m_sort:On("value_changed", function(_, sort)
        m_sortColumn = sort.column
        m_sortAscending = sort.ascending
        RebuildDestinationTree(false)
    end)
    m_panel:AddChild(m_sort)

    m_missionFilter = mgr:CreateWidget(MISSION_FILTER_ID, "Dropdown", {
        Label = function() return Locale.Lookup("LOC_CAI_ESPIONAGE_FILTER_BY_MISSION") end,
        FocusKey = "espionage:mission-filter",
        HiddenPredicate = function() return not m_caiIsDestinationMode end,
    })
    m_missionFilter:On("value_changed", function(_, missionHash)
        m_missionFilterHash = missionHash
        RebuildDestinationTree(false)
    end)
    m_panel:AddChild(m_missionFilter)

    m_missionList = mgr:CreateWidget(MISSION_LIST_ID, "List", {
        Label = function() return Locale.Lookup("LOC_ESPIONAGECHOOSER_CHOOSE_MISSION") end,
        HiddenPredicate = function() return m_caiIsDestinationMode end,
    })
    m_panel:AddChild(m_missionList)

    m_panel:AddInputBindings({
        {
            Key = Keys.VK_ESCAPE,
            MSG = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_CLOSE",
            Action = function()
                Close()
                return true
            end,
        },
    })

    RebuildWidgets()
end

local function PushPanel()
    BuildPanel()
    -- If a mission-completed espionage popup is already up, sit below it rather
    -- than covering it; both stay at Low priority.
    local belowId = ExposedMembers and ExposedMembers.CAI_EspionagePopupDialogId or nil
    mgr:Push(m_panel, { priority = PopupPriority.Low, below = belowId })
end

local function PopPanel()
    CloseConfirmDialog()
    if mgr and m_panel then
        mgr:RemoveFromStack(PANEL_ID)
    end
    m_panel = nil
    m_destTree = nil
    m_sort = nil
    m_missionFilter = nil
    m_catYourCities = nil
    m_catOtherCivs = nil
    m_catCityStates = nil
    m_missionList = nil
    m_capturedDestinations = {}
    m_capturedMissions = {}
end

-- ============================================================================
-- Row Capture Wraps
-- ============================================================================

RefreshDestinationList = WrapFunc(RefreshDestinationList, function(orig)
    m_capturedDestinations = {}
    orig()
end)

RefreshMissionList = WrapFunc(RefreshMissionList, function(orig)
    m_capturedMissions = {}
    orig()
end)

AddDestination = WrapFunc(AddDestination, function(orig, city)
    orig(city)
    local button = FindNewButton(Controls.DestinationStack, GetUsedControls(m_capturedDestinations))
    local transitTime = 0
    local establishTime = 0
    if m_caiSpy then
        transitTime = UnitManager.GetTravelTime(m_caiSpy, city)
        establishTime = UnitManager.GetEstablishInCityTime(m_caiSpy, city)
    end
    m_capturedDestinations[#m_capturedDestinations + 1] = {
        city = city,
        button = button,
        travelTime = transitTime + establishTime,
        transitTime = transitTime,
        establishTime = establishTime,
        districts = GetDistrictNames(city),
    }
end)

AddCounterspyOperation = WrapFunc(AddCounterspyOperation, function(orig, operation, districtPlotID)
    orig(operation, districtPlotID)

    local dInfo = GetDistrictForPlotID(m_caiCity, districtPlotID)
    local districtName = dInfo and Locale.Lookup(dInfo.Name) or nil
    local button = FindNewButton(Controls.MissionStack, GetUsedControls(m_capturedMissions))
    m_capturedMissions[#m_capturedMissions + 1] = {
        operation = operation,
        missionType = "counterspy",
        districtPlotID = districtPlotID,
        districtName = districtName,
        details = districtName and Locale.Lookup("LOC_ESPIONAGECHOOSER_COUNTERSPY", districtName) or "",
        disabled = button and button:IsDisabled() or false,
        button = button,
    }
end)

AddAvailableOffensiveOperation = WrapFunc(AddAvailableOffensiveOperation, function(orig, operation, results, targetPlot)
    orig(operation, results, targetPlot)

    local districtName = nil
    if targetPlot then
        local dInfo = GetDistrictForPlotID(m_caiCity, targetPlot:GetIndex())
        if dInfo then districtName = Locale.Lookup(dInfo.Name) end
    end

    local probability = nil
    if targetPlot and operation.Hash ~= UnitOperationTypes.SPY_COUNTERSPY then
        local resultProbability = UnitManager.GetResultProbability(operation.Index, m_caiSpy, targetPlot)
        if resultProbability and resultProbability["ESPIONAGE_SUCCESS_UNDETECTED"] then
            local p = resultProbability["ESPIONAGE_SUCCESS_UNDETECTED"]
            if resultProbability["ESPIONAGE_SUCCESS_MUST_ESCAPE"] then
                p = p + resultProbability["ESPIONAGE_SUCCESS_MUST_ESCAPE"]
            end
            probability = math.floor((p * 100) + 0.5)
        end
    end

    local button = FindNewButton(Controls.MissionStack, GetUsedControls(m_capturedMissions))
    m_capturedMissions[#m_capturedMissions + 1] = {
        operation = operation,
        missionType = "offensive",
        targetPlot = targetPlot,
        turnsToComplete = UnitManager.GetTimeToComplete(operation.Index, m_caiSpy),
        probability = probability,
        districtName = districtName,
        details = GetFormattedOperationDetailText(operation, m_caiSpy, m_caiCity),
        disabled = button and button:IsDisabled() or false,
        button = button,
    }
end)

AddDisabledOffensiveOperation = WrapFunc(AddDisabledOffensiveOperation, function(orig, operation, results, targetPlot)
    orig(operation, results, targetPlot)

    local failureReasons = ""
    if results and results[UnitOperationResults.FAILURE_REASONS] then
        failureReasons = table.concat(results[UnitOperationResults.FAILURE_REASONS], "[NEWLINE]")
    end

    local button = FindNewButton(Controls.MissionStack, GetUsedControls(m_capturedMissions))
    m_capturedMissions[#m_capturedMissions + 1] = {
        operation = operation,
        missionType = "disabled",
        targetPlot = targetPlot,
        turnsToComplete = UnitManager.GetTimeToComplete(operation.Index, m_caiSpy),
        districtName = Locale.Lookup("LOC_DISTRICT_CITY_CENTER_NAME"),
        failureReasons = failureReasons,
        disabled = true,
        button = button,
    }
end)

-- ============================================================================
-- Lifecycle Wraps
-- ============================================================================

Open = WrapFunc(Open, function(orig)
    local selectedUnit = UI.GetHeadSelectedUnit()
    if selectedUnit then
        local unitInfo = GameInfo.Units[selectedUnit:GetUnitType()]
        if unitInfo and unitInfo.Spy then
            m_caiSpy = selectedUnit
        end
    end

    if m_caiSpy then
        local spyPlot = Map.GetPlot(m_caiSpy:GetX(), m_caiSpy:GetY())
        if spyPlot then
            m_caiCity = Cities.GetPlotPurchaseCity(spyPlot)
        end
    end
    orig()
    m_caiIsDestinationMode = ReadVanillaDestinationMode()
    if mgr and not ContextPtr:IsHidden() and not mgr:GetWidgetById(PANEL_ID) then
        PushPanel()
    end
end)

OnSelectDestination = WrapFunc(OnSelectDestination, function(orig, city)
    m_caiCity = city
    orig(city)
end)

OnCancel = WrapFunc(OnCancel, function(orig)
    m_caiCity = nil
    CloseConfirmDialog()
    orig()
end)

OnConfirmPlacement = WrapFunc(OnConfirmPlacement, function(orig)
    CloseConfirmDialog()
    orig()
end)

Refresh = WrapFunc(Refresh, function(orig)
    orig()
    if mgr and m_panel and not ContextPtr:IsHidden() then
        local oldMode = m_caiIsDestinationMode
        m_caiIsDestinationMode = ReadVanillaDestinationMode()
        RebuildWidgets()
        if oldMode ~= m_caiIsDestinationMode then
            local active = GetActiveModeWidget()
            if active then mgr:SetFocus(active) end
        end
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
-- Input Handling
-- ============================================================================

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
-- Re-register wrapped callbacks (vanilla Initialize captured pre-wrap refs)
-- ============================================================================

Controls.ConfirmButton:RegisterCallback(Mouse.eLClick, OnConfirmPlacement)
Controls.CancelButton:RegisterCallback(Mouse.eLClick, OnCancel)
Controls.CloseButton:RegisterCallback(Mouse.eLClick, OnClose)
