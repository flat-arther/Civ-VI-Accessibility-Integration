-- GreatWorksOverview_CAI.lua
-- Accessibility overlay for the Great Works Overview screen.
-- Rides the wildcard include("GreatWorksOverview_", true) from the base file.

include("caiUtils")
include("hexCoordUtils_CAI")

local mgr                      = ExposedMembers.CAI_UIManager
local CAICursor                = ExposedMembers.CAICursor
local HexCoordUtils            = CAIHexCoordUtils

local PANEL_ID                 = "CAIGreatWorksOverview_Panel"
local TREE_ID                  = "CAIGreatWorksOverview_Tree"
local PICKER_ID                = "CAIGreatWorksOverview_Picker"
local GROUP_SETTING_SECTION    = "UI"
local GROUP_SETTING_ID         = "GreatWorksGroupByBuildings"

local m_ui                     = { panel = nil, tree = nil, picker = nil, grouping = nil }

local m_caiIsLocalPlayerTurn   = true
local m_lastFocusedWork        = nil
local m_pendingMoveDestination = nil
local m_usePendingDestination  = false
local m_groupByBuildings       = true

local GREAT_WORK_ARTIFACT_TYPE = "GREATWORKOBJECT_ARTIFACT"
local GREAT_WORK_PRODUCT_TYPE  = "GREATWORKOBJECT_PRODUCT"
local DEFAULT_LOCK_TURNS       = 10
local ART_OBJECT_TYPES         = {
    GREATWORKOBJECT_SCULPTURE = true,
    GREATWORKOBJECT_LANDSCAPE = true,
    GREATWORKOBJECT_PORTRAIT  = true,
    GREATWORKOBJECT_RELIGIOUS = true,
}

local function LoadGroupByBuildingsSetting()
    if CAI == nil or CAI.GetConfigValue == nil then return true end
    local stored = CAI.GetConfigValue(
        GROUP_SETTING_SECTION, GROUP_SETTING_ID, "true")
    if stored == nil then return true end
    local normalized = tostring(stored):lower()
    if normalized == "false" or normalized == "0"
        or normalized == "no" or normalized == "off" then
        return false
    end
    return true
end

local function SaveGroupByBuildingsSetting(value)
    m_groupByBuildings = value and true or false
    if CAI ~= nil and CAI.SetConfigValue ~= nil then
        CAI.SetConfigValue(GROUP_SETTING_SECTION, GROUP_SETTING_ID,
            m_groupByBuildings and "true" or "false")
    end
end

m_groupByBuildings = LoadGroupByBuildingsSetting()

-- ---------------------------------------------------------------------------
-- Data helpers
-- ---------------------------------------------------------------------------

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

local function IndexBuildingPlots(pCity)
    local plotIndices = {}
    local purchasedPlots = Map.GetCityPlots():GetPurchasedPlots(pCity)
    if purchasedPlots == nil then
        LogWarn("Great Works cannot index building plots for city "
            .. tostring(pCity:GetID()))
        return plotIndices
    end

    local cityBuildings = pCity:GetBuildings()
    for _, plotIndex in pairs(purchasedPlots) do
        for _, buildingIndex in ipairs(cityBuildings:GetBuildingsAtLocation(plotIndex)) do
            plotIndices[buildingIndex] = plotIndex
        end
    end
    return plotIndices
end

local function MoveCursorToBuilding(plotIndex, cityID, buildingIndex)
    if plotIndex == nil then
        LogWarn("Great Works cannot move cursor: no plot for city "
            .. tostring(cityID) .. ", building " .. tostring(buildingIndex))
        return
    end
    LuaEvents.CAICursorMoveTo(plotIndex, "jump")
end

local function GetIndexedBuildingPlot(buildingPlotsByCity, cityID, buildingIndex)
    local cityPlots = buildingPlotsByCity[cityID]
    local plotIndex = cityPlots and cityPlots[buildingIndex] or nil
    if plotIndex == nil then
        LogWarn("Great Works found no plot for city " .. tostring(cityID)
            .. ", building " .. tostring(buildingIndex))
    end
    return plotIndex
end

local function GetSlotTypeName(slotTypeString)
    local names = {}
    for row in GameInfo.GreatWork_ValidSubTypes() do
        if row.GreatWorkSlotType == slotTypeString then
            table.insert(names, Locale.Lookup("LOC_" .. row.GreatWorkObjectType))
        end
    end
    if #names == 0 then return slotTypeString end
    return table.concat(names, " / ")
end

local function GetProductCorporationName(gwInfo)
    local productType = gwInfo.GreatWorkType:gsub("GREATWORK_PRODUCT_", "")
    local resourceType = "RESOURCE_" .. productType:sub(1, #productType - 2)
    local resourceInfo = GameInfo.Resources[resourceType]
    local corporationName = resourceInfo and Game.GetEconomicManager()
        :GetCorporationName(Game.GetLocalPlayer(), resourceInfo.Index) or nil
    if corporationName == nil or corporationName == "" then
        corporationName = Locale.Lookup("LOC_IMPROVEMENT_CORPORATION_NAME",
            Locale.Lookup("LOC_" .. resourceType .. "_NAME"))
    end
    return corporationName
end

local function GetGreatWorkLabel(pCityBldgs, greatWorkIndex)
    local gwType  = pCityBldgs:GetGreatWorkTypeFromIndex(greatWorkIndex)
    local gwInfo  = GameInfo.GreatWorks[gwType]
    local name    = Locale.Lookup(gwInfo.Name)
    local creator
    if gwInfo.GreatWorkObjectType == GREAT_WORK_PRODUCT_TYPE then
        creator = GetProductCorporationName(gwInfo)
    else
        creator = Locale.Lookup(pCityBldgs:GetCreatorNameFromIndex(greatWorkIndex))
    end
    return name .. ", " .. creator
end

local function GetMoveBlockedReason(pCityBldgs, buildingIndex, slotIndex)
    local gwIdx = pCityBldgs:GetGreatWorkInSlot(buildingIndex, slotIndex)
    if gwIdx == -1 then return nil end

    local gwType = pCityBldgs:GetGreatWorkTypeFromIndex(gwIdx)
    local gwInfo = GameInfo.GreatWorks[gwType]
    local objType = gwInfo.GreatWorkObjectType

    if objType == GREAT_WORK_ARTIFACT_TYPE then
        local numSlots = pCityBldgs:GetNumGreatWorkSlots(buildingIndex)
        local full = true
        for i = 0, numSlots - 1 do
            if pCityBldgs:GetGreatWorkInSlot(buildingIndex, i) == -1 then
                full = false
                break
            end
        end
        if not full then
            return Locale.Lookup("LOC_GREAT_WORKS_ARTIFACT_LOCKED_FROM_MOVE")
        end
    end

    if ART_OBJECT_TYPES[objType] then
        local iTurnCreated     = pCityBldgs:GetTurnFromIndex(gwIdx)
        local iCurrentTurn     = Game.GetCurrentGameTurn()
        local iTurnsBeforeMove = GlobalParameters.GREATWORK_ART_LOCK_TIME or DEFAULT_LOCK_TURNS
        local iTurnsToWait     = iTurnCreated + iTurnsBeforeMove - iCurrentTurn
        if iTurnsToWait > 0 then
            return Locale.Lookup("LOC_GREAT_WORKS_LOCKED_FROM_MOVE", iTurnsToWait)
        end
    end

    return nil
end

local function GetGreatWorkThemeFit(pCityBldgs, buildingInfo, greatWorkIndex)
    local themeDesc = GetThemeDescription(buildingInfo.BuildingType)
    if not themeDesc then return nil end

    local buildingIndex = buildingInfo.Index
    local buildingName  = Locale.Lookup(buildingInfo.Name)

    if pCityBldgs:IsBuildingThemedCorrectly(buildingIndex) then
        return Locale.Lookup("LOC_GREAT_WORKS_ART_MATCHED_THEME", buildingName)
    end

    local firstGW = GetFirstGreatWorkInBuilding(pCityBldgs, buildingInfo)
    if firstGW < 0 then return nil end

    local firstGWTypeID  = pCityBldgs:GetGreatWorkTypeFromIndex(firstGW)
    local firstGWObjType = GameInfo.GreatWorks[firstGWTypeID].GreatWorkObjectType

    local gwType         = pCityBldgs:GetGreatWorkTypeFromIndex(greatWorkIndex)
    local gwInfo         = GameInfo.GreatWorks[gwType]

    if buildingInfo.BuildingType == "BUILDING_MUSEUM_ART" then
        if firstGW == greatWorkIndex then
            return Locale.Lookup("LOC_GREAT_WORKS_ART_THEME_SINGLE",
                Locale.Lookup("LOC_" .. firstGWObjType))
        elseif not IsFirstGreatWorkByArtist(greatWorkIndex, pCityBldgs, buildingInfo) then
            return Locale.Lookup("LOC_GREAT_WORKS_ART_THEME_DUPLICATE_ARTIST")
        elseif firstGWObjType == gwInfo.GreatWorkObjectType then
            return Locale.Lookup("LOC_GREAT_WORKS_ART_THEME_DUAL",
                Locale.Lookup("LOC_" .. firstGWObjType))
        else
            return Locale.Lookup("LOC_GREAT_WORKS_MISMATCHED_THEME",
                Locale.Lookup("LOC_" .. gwInfo.GreatWorkObjectType),
                Locale.Lookup("LOC_" .. firstGWObjType .. "_PLURAL"))
        end
    elseif buildingInfo.BuildingType == "BUILDING_MUSEUM_ARTIFACT" then
        if firstGW == greatWorkIndex then
            local typeName
            if gwInfo.EraType then
                typeName = Locale.Lookup("LOC_" .. gwInfo.GreatWorkObjectType .. "_" .. gwInfo.EraType)
            else
                typeName = Locale.Lookup("LOC_" .. gwInfo.GreatWorkObjectType)
            end
            return Locale.Lookup("LOC_GREAT_WORKS_ART_THEME_SINGLE", typeName)
        else
            local firstEra = GameInfo.GreatWorks[firstGWTypeID].EraType
            if gwInfo.EraType ~= firstEra then
                local typeName
                if gwInfo.EraType then
                    typeName = Locale.Lookup("LOC_" .. gwInfo.GreatWorkObjectType .. "_" .. gwInfo.EraType)
                else
                    typeName = Locale.Lookup("LOC_" .. gwInfo.GreatWorkObjectType)
                end
                local firstEraPlural = Locale.Lookup("LOC_" .. firstGWObjType .. "_" .. firstEra .. "_PLURAL")
                return Locale.Lookup("LOC_GREAT_WORKS_MISMATCHED_ERA", typeName, firstEraPlural)
            else
                local greatWorks = GetGreatWorksInBuilding(pCityBldgs, buildingInfo)
                local hash = {}
                local duplicates = {}
                for _, idx in ipairs(greatWorks) do
                    local gwPlayer = Game.GetGreatWorkPlayer(idx)
                    if not hash[gwPlayer] then
                        hash[gwPlayer] = true
                    else
                        table.insert(duplicates, gwPlayer)
                    end
                end
                if #duplicates > 0 then
                    local firstEraPlural = Locale.Lookup("LOC_" .. firstGWObjType .. "_" .. firstEra .. "_PLURAL")
                    return Locale.Lookup("LOC_GREAT_WORKS_DUPLICATE_ARTIFACT_CIVS",
                        PlayerConfigurations[duplicates[1]]:GetCivilizationShortDescription(),
                        firstEraPlural)
                end
            end
        end
    end

    return nil
end

local function FindSlotForGreatWork(pCityBldgs, buildingIndex, greatWorkIndex)
    local numSlots = pCityBldgs:GetNumGreatWorkSlots(buildingIndex)
    for i = 0, numSlots - 1 do
        if pCityBldgs:GetGreatWorkInSlot(buildingIndex, i) == greatWorkIndex then
            return i
        end
    end
    return -1
end

local function GetGreatWorkDetail(pCityBldgs, greatWorkIndex, buildingInfo)
    local gwType = pCityBldgs:GetGreatWorkTypeFromIndex(greatWorkIndex)
    local gwInfo = GameInfo.GreatWorks[gwType]

    if gwInfo.GreatWorkObjectType == GREAT_WORK_PRODUCT_TYPE then
        local parts = {
            GetGreatWorkTooltip(pCityBldgs, greatWorkIndex, gwType, buildingInfo),
        }
        local moveBlocked = GetMoveBlockedReason(pCityBldgs, buildingInfo.Index,
            FindSlotForGreatWork(pCityBldgs, buildingInfo.Index, greatWorkIndex))
        if moveBlocked then table.insert(parts, moveBlocked) end
        return table.concat(parts, "[NEWLINE]")
    end

    local typeName
    if gwInfo.EraType then
        typeName = Locale.Lookup("LOC_" .. gwInfo.GreatWorkObjectType .. "_" .. gwInfo.EraType)
    else
        typeName = Locale.Lookup("LOC_" .. gwInfo.GreatWorkObjectType)
    end

    local parts = { typeName }

    for row in GameInfo.GreatWork_YieldChanges() do
        if row.GreatWorkType == gwInfo.GreatWorkType then
            local yieldInfo = GameInfo.Yields[row.YieldType]
            if yieldInfo then
                table.insert(parts, "+" .. row.YieldChange .. " " .. Locale.Lookup(yieldInfo.Name))
            end
        end
    end
    if gwInfo.Tourism and gwInfo.Tourism > 0 then
        table.insert(parts, "+" .. gwInfo.Tourism .. " " .. Locale.Lookup("LOC_GREAT_WORKS_TOURISM"))
    end

    local turnCreated = pCityBldgs:GetTurnFromIndex(greatWorkIndex)
    local dateStr = Calendar.MakeDateStr(
        turnCreated, GameConfiguration.GetCalendarType(),
        GameConfiguration.GetGameSpeedType(), false)
    table.insert(parts, dateStr)

    local themeFit = GetGreatWorkThemeFit(pCityBldgs, buildingInfo, greatWorkIndex)
    if themeFit then
        table.insert(parts, themeFit)
    end

    local moveBlocked = GetMoveBlockedReason(pCityBldgs, buildingInfo.Index,
        FindSlotForGreatWork(pCityBldgs, buildingInfo.Index, greatWorkIndex))
    if moveBlocked then
        table.insert(parts, moveBlocked)
    end

    return table.concat(parts, "[NEWLINE]")
end

local function GetBuildingYieldsText(pCityBldgs, buildingIndex)
    local parts = {}
    for row in GameInfo.Yields() do
        local v = pCityBldgs:GetBuildingYieldFromGreatWorks(row.Index, buildingIndex)
        if v > 0 then
            table.insert(parts, v .. " " .. Locale.Lookup(row.Name))
        end
    end
    local regularTourism  = pCityBldgs:GetBuildingTourismFromGreatWorks(false, buildingIndex)
    local religionTourism = pCityBldgs:GetBuildingTourismFromGreatWorks(true, buildingIndex)
    local totalTourism    = regularTourism + religionTourism
    if totalTourism > 0 then
        table.insert(parts, totalTourism .. " " .. Locale.Lookup("LOC_GREAT_WORKS_TOURISM"))
    end
    if #parts == 0 then return "" end
    return table.concat(parts, "[NEWLINE]")
end

local function GetBuildingLabel(buildingInfo, pCityBldgs)
    local label         = Locale.Lookup(buildingInfo.Name)
    local buildingIndex = buildingInfo.Index

    local themeDesc     = GetThemeDescription(buildingInfo.BuildingType)
    if themeDesc then
        if pCityBldgs:IsBuildingThemedCorrectly(buildingIndex) then
            label = label .. ", " .. Locale.Lookup("LOC_GREAT_WORKS_THEMED_BONUS")
        else
            local numSlots    = pCityBldgs:GetNumGreatWorkSlots(buildingIndex)

            local localPlayer = Players[Game.GetLocalPlayer()]
            local bAutoTheme  = localPlayer
                and localPlayer:GetCulture()
                and localPlayer:GetCulture().IsAutoThemedEligible
                and localPlayer:GetCulture():IsAutoThemedEligible()

            local numProgress = 0
            if bAutoTheme then
                for i = 0, numSlots - 1 do
                    if pCityBldgs:GetGreatWorkInSlot(buildingIndex, i) ~= -1 then
                        numProgress = numProgress + 1
                    end
                end
            else
                for i = 0, numSlots - 1 do
                    local gwIdx = pCityBldgs:GetGreatWorkInSlot(buildingIndex, i)
                    if gwIdx ~= -1 then
                        local gwType = pCityBldgs:GetGreatWorkTypeFromIndex(gwIdx)
                        local gwInfo = GameInfo.GreatWorks[gwType]
                        if gwInfo and GreatWorkFitsTheme(pCityBldgs, buildingInfo, gwIdx, gwInfo) then
                            numProgress = numProgress + 1
                        end
                    end
                end
            end

            if numSlots > 1 then
                label = label .. ", " ..
                    Locale.Lookup("LOC_GREAT_WORKS_THEME_BONUS_PROGRESS", numProgress, numSlots)
            end
        end
    end

    return label
end

local function GetBuildingStatusText(buildingInfo, pCityBldgs)
    local buildingName = Locale.Lookup(buildingInfo.Name)
    local label = GetBuildingLabel(buildingInfo, pCityBldgs)
    if label == buildingName then return "" end

    local prefix = buildingName .. ", "
    if label:sub(1, #prefix) == prefix then
        return label:sub(#prefix + 1)
    end
    return label
end

local function GetBuildingTooltip(pCityBldgs, buildingInfo)
    local parts = {}

    local themeDesc = GetThemeDescription(buildingInfo.BuildingType)
    if themeDesc then
        table.insert(parts, themeDesc)
    end

    local yieldsText = GetBuildingYieldsText(pCityBldgs, buildingInfo.Index)
    if yieldsText ~= "" then
        table.insert(parts, Locale.Lookup("LOC_GREAT_WORKS_PROVIDING") .. " " .. yieldsText)
    end

    if #parts == 0 then return "" end
    return table.concat(parts, "[NEWLINE]")
end

local function GetYieldsSummary()
    local localPlayer = Players[Game.GetLocalPlayer()]
    if not localPlayer then return "" end

    local yields  = {}
    local tourism = 0

    for _, pCity in localPlayer:GetCities():Members() do
        if pCity and pCity:GetOwner() == Game.GetLocalPlayer() then
            local bldgs = pCity:GetBuildings()
            for bi in GameInfo.Buildings() do
                if bldgs:HasBuilding(bi.Index) then
                    local ns = bldgs:GetNumGreatWorkSlots(bi.Index)
                    if ns and ns > 0 then
                        for row in GameInfo.Yields() do
                            local v = bldgs:GetBuildingYieldFromGreatWorks(row.Index, bi.Index)
                            if v > 0 then
                                yields[row.YieldType] = (yields[row.YieldType] or 0) + v
                            end
                        end
                        tourism = tourism
                            + bldgs:GetBuildingTourismFromGreatWorks(false, bi.Index)
                            + bldgs:GetBuildingTourismFromGreatWorks(true, bi.Index)
                    end
                end
            end
        end
    end

    local summaries = {}
    for yieldType, value in pairs(yields) do
        local yi = GameInfo.Yields[yieldType]
        if yi then
            local name = Locale.Lookup(yi.Name)
            table.insert(summaries, { Name = name, Text = value .. " " .. name })
        end
    end
    if tourism > 0 then
        local name = Locale.Lookup("LOC_GREAT_WORKS_TOURISM")
        table.insert(summaries, { Name = name, Text = tourism .. " " .. name })
    end
    table.sort(summaries, function(a, b) return a.Name < b.Name end)

    local parts = {}
    for _, summary in ipairs(summaries) do table.insert(parts, summary.Text) end
    return table.concat(parts, "[NEWLINE]")
end

-- ---------------------------------------------------------------------------
-- Move helper
-- ---------------------------------------------------------------------------

local function ExecuteMove(srcCityID, srcBuildingID, srcGWIndex,
                           dstCityID, dstBuildingID, dstSlotIndex)
    m_pendingMoveDestination = {
        SourceCity = srcCityID,
        City = dstCityID,
        Building = dstBuildingID,
    }
    local t                                    = {}
    t[PlayerOperations.PARAM_PLAYER_ONE]       = Game.GetLocalPlayer()
    t[PlayerOperations.PARAM_CITY_SRC]         = srcCityID
    t[PlayerOperations.PARAM_CITY_DEST]        = dstCityID
    t[PlayerOperations.PARAM_BUILDING_SRC]     = srcBuildingID
    t[PlayerOperations.PARAM_BUILDING_DEST]    = dstBuildingID
    t[PlayerOperations.PARAM_GREAT_WORK_INDEX] = srcGWIndex
    t[PlayerOperations.PARAM_SLOT]             = dstSlotIndex
    UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.MOVE_GREAT_WORK, t)
    UI.PlaySound("UI_GreatWorks_Put_Down")
end

-- ---------------------------------------------------------------------------
-- Picker
-- ---------------------------------------------------------------------------

local function GetValidSlotIndices(pCityBldgs, buildingIndex)
    local slots = {}
    local numSlots = pCityBldgs:GetNumGreatWorkSlots(buildingIndex) or 0
    for slotIndex = 0, numSlots - 1 do
        local slotType = pCityBldgs:GetGreatWorkSlotType(buildingIndex, slotIndex)
        if slotType >= 0 and GameInfo.GreatWorkSlotTypes[slotType] then
            table.insert(slots, slotIndex)
        end
    end
    return slots
end

local function ClosePicker()
    if mgr and m_ui.picker then mgr:RemoveFromStack(PICKER_ID) end
    m_ui.picker = nil
end

local function OpenPicker(dstCityBldgs, dstBuildingIndex, dstSlotIndex)
    ClosePicker()

    local dstCityID   = dstCityBldgs:GetCity():GetID()
    local dstSlotType = dstCityBldgs:GetGreatWorkSlotType(dstBuildingIndex, dstSlotIndex)
    local dstSlotInfo = dstSlotType >= 0 and GameInfo.GreatWorkSlotTypes[dstSlotType] or nil
    if dstSlotInfo == nil then
        LogError("Great Works picker cannot open for invalid destination slot type")
        return
    end
    local dstSlotStr  = dstSlotInfo.GreatWorkSlotType
    local dstGWIndex  = dstCityBldgs:GetGreatWorkInSlot(dstBuildingIndex, dstSlotIndex)

    local pickerLabel
    if dstGWIndex ~= -1 then
        pickerLabel = Locale.Lookup("LOC_CAI_GREAT_WORKS_SWAP_PICKER",
            GetGreatWorkLabel(dstCityBldgs, dstGWIndex))
    else
        pickerLabel = Locale.Lookup("LOC_CAI_GREAT_WORKS_MOVE_PICKER",
            GetSlotTypeName(dstSlotStr))
    end

    m_ui.picker = mgr:CreateWidget(PICKER_ID, "Tree", {
        Label = function() return pickerLabel end,
    })
    m_ui.picker:AddInputBindings({
        {
            Key = Keys.VK_ESCAPE,
            MSG = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_CLOSE",
            Action = function()
                ClosePicker()
                return true
            end
        },
    })

    local localPlayer = Players[Game.GetLocalPlayer()]
    local cityGroups = {}
    local cityOrder = {}
    local buildingGroups = {}
    local buildingOrder = {}
    local candidateCount = 0

    for _, pCity in localPlayer:GetCities():Members() do
        if pCity and pCity:GetOwner() == Game.GetLocalPlayer() then
            local pCityBldgs = pCity:GetBuildings()
            for buildingInfo in GameInfo.Buildings() do
                if pCityBldgs:HasBuilding(buildingInfo.Index) then
                    for _, slotIndex in ipairs(GetValidSlotIndices(
                            pCityBldgs, buildingInfo.Index)) do
                        local greatWorkIndex = pCityBldgs:GetGreatWorkInSlot(
                            buildingInfo.Index, slotIndex)
                        if greatWorkIndex ~= -1
                            and not (pCity:GetID() == dstCityID
                                and buildingInfo.Index == dstBuildingIndex
                                and slotIndex == dstSlotIndex)
                            and CanMoveWorkAtAll(pCityBldgs, buildingInfo.Index, slotIndex)
                            and CanMoveGreatWork(pCityBldgs, buildingInfo.Index, slotIndex,
                                dstCityBldgs, dstBuildingIndex, dstSlotIndex)
                        then
                            local candidate = {
                                City = pCity,
                                CityBldgs = pCityBldgs,
                                BuildingInfo = buildingInfo,
                                GreatWorkIndex = greatWorkIndex,
                            }
                            candidateCount = candidateCount + 1

                            local cityID = pCity:GetID()
                            local cityGroup = cityGroups[cityID]
                            if not cityGroup then
                                cityGroup = {
                                    City = pCity,
                                    Buildings = {},
                                    BuildingOrder = {},
                                }
                                cityGroups[cityID] = cityGroup
                                table.insert(cityOrder, cityID)
                            end
                            local cityBuilding = cityGroup.Buildings[buildingInfo.Index]
                            if not cityBuilding then
                                cityBuilding = { Info = buildingInfo, Items = {} }
                                cityGroup.Buildings[buildingInfo.Index] = cityBuilding
                                table.insert(cityGroup.BuildingOrder, buildingInfo.Index)
                            end
                            table.insert(cityBuilding.Items, candidate)

                            local buildingGroup = buildingGroups[buildingInfo.Index]
                            if not buildingGroup then
                                buildingGroup = {
                                    Info = buildingInfo,
                                    Cities = {},
                                    CityOrder = {},
                                }
                                buildingGroups[buildingInfo.Index] = buildingGroup
                                table.insert(buildingOrder, buildingInfo.Index)
                            end
                            local buildingCity = buildingGroup.Cities[cityID]
                            if not buildingCity then
                                buildingCity = { City = pCity, Items = {} }
                                buildingGroup.Cities[cityID] = buildingCity
                                table.insert(buildingGroup.CityOrder, cityID)
                            end
                            table.insert(buildingCity.Items, candidate)
                        end
                    end
                end
            end
        end
    end

    table.sort(buildingOrder)

    local function AddCandidate(parent, candidate)
        local item = mgr:CreateWidget(
            mgr:GenerateWidgetId("CAIGWPicker_Item"), "TreeItem", {
                Label = function()
                    return GetGreatWorkLabel(candidate.CityBldgs,
                        candidate.GreatWorkIndex)
                end,
                Tooltip = function()
                    return GetGreatWorkDetail(candidate.CityBldgs,
                        candidate.GreatWorkIndex, candidate.BuildingInfo)
                end,
                FocusKey = "gw:" .. tostring(candidate.GreatWorkIndex),
            })
        item:SetFocusSound("Main_Menu_Mouse_Over")
        item:On("activate", function()
            ClosePicker()
            ExecuteMove(candidate.City:GetID(), candidate.BuildingInfo.Index,
                candidate.GreatWorkIndex, dstCityID, dstBuildingIndex,
                dstSlotIndex)
        end)
        parent:AddChild(item)
    end

    if m_groupByBuildings then
        for _, buildingIndex in ipairs(buildingOrder) do
            local buildingGroup = buildingGroups[buildingIndex]
            local buildingName = Locale.Lookup(buildingGroup.Info.Name)
            local buildingNode = mgr:CreateWidget(
                mgr:GenerateWidgetId("CAIGWPicker_Bldg"), "TreeItem", {
                    Label = function() return buildingName end,
                })
            m_ui.picker:AddChild(buildingNode)
            buildingNode:Expand(true)

            for _, cityID in ipairs(buildingGroup.CityOrder) do
                local cityGroup = buildingGroup.Cities[cityID]
                local cityName = Locale.Lookup(cityGroup.City:GetName())
                local cityNode = mgr:CreateWidget(
                    mgr:GenerateWidgetId("CAIGWPicker_City"), "TreeItem", {
                        Label = function() return cityName end,
                    })
                buildingNode:AddChild(cityNode)
                cityNode:Expand(true)
                for _, candidate in ipairs(cityGroup.Items) do
                    AddCandidate(cityNode, candidate)
                end
            end
        end
    else
        for _, cityID in ipairs(cityOrder) do
            local cityGroup = cityGroups[cityID]
            local cityName = Locale.Lookup(cityGroup.City:GetName())
            local cityNode = mgr:CreateWidget(
                mgr:GenerateWidgetId("CAIGWPicker_City"), "TreeItem", {
                    Label = function() return cityName end,
                })
            m_ui.picker:AddChild(cityNode)
            cityNode:Expand(true)

            for _, buildingIndex in ipairs(cityGroup.BuildingOrder) do
                local buildingGroup = cityGroup.Buildings[buildingIndex]
                local buildingName = Locale.Lookup(buildingGroup.Info.Name)
                local buildingNode = mgr:CreateWidget(
                    mgr:GenerateWidgetId("CAIGWPicker_Bldg"), "TreeItem", {
                        Label = function() return buildingName end,
                    })
                cityNode:AddChild(buildingNode)
                buildingNode:Expand(true)
                for _, candidate in ipairs(buildingGroup.Items) do
                    AddCandidate(buildingNode, candidate)
                end
            end
        end
    end

    if candidateCount == 0 then
        m_ui.picker:AddChild(mgr:CreateWidget(
            mgr:GenerateWidgetId("CAIGWPicker_Empty"), "TreeItem",
            {
                Label = function()
                    return Locale.Lookup("LOC_CAI_GREAT_WORKS_NO_COMPATIBLE")
                end
            }))
    end

    mgr:Push(m_ui.picker, PopupPriority.Current)
end

-- ---------------------------------------------------------------------------
-- Tree content
-- ---------------------------------------------------------------------------

local function CreateSlotItem(pCity, pCityBldgs, buildingInfo, slotIndex)
    local buildingIndex = buildingInfo.Index
    local slotType = pCityBldgs:GetGreatWorkSlotType(buildingIndex, slotIndex)
    local slotTypeString = GameInfo.GreatWorkSlotTypes[slotType].GreatWorkSlotType

    local slotItem = mgr:CreateWidget(
        mgr:GenerateWidgetId("CAIGW_Slot"), "TreeItem", {
            Label = function()
                local greatWorkIndex = pCityBldgs:GetGreatWorkInSlot(buildingIndex, slotIndex)
                if greatWorkIndex == -1 then
                    return Locale.Lookup("LOC_CAI_GREAT_WORKS_EMPTY_SLOT",
                        GetSlotTypeName(slotTypeString))
                end
                return GetGreatWorkLabel(pCityBldgs, greatWorkIndex)
            end,
            Tooltip = function()
                local greatWorkIndex = pCityBldgs:GetGreatWorkInSlot(buildingIndex, slotIndex)
                if greatWorkIndex == -1 then return "" end
                return GetGreatWorkDetail(pCityBldgs, greatWorkIndex, buildingInfo)
            end,
            DisabledPredicate = function() return not m_caiIsLocalPlayerTurn end,
            FocusKey = "slot:" .. tostring(pCity:GetID())
                .. ":" .. tostring(buildingIndex)
                .. ":" .. tostring(slotIndex),
        })
    slotItem:SetFocusSound("Main_Menu_Mouse_Over")

    slotItem:On("focus_enter", function()
        local greatWorkIndex = pCityBldgs:GetGreatWorkInSlot(buildingIndex, slotIndex)
        if greatWorkIndex ~= -1 then
            m_lastFocusedWork = {
                Index = greatWorkIndex,
                Building = buildingIndex,
                CityBldgs = pCityBldgs,
            }
        end
    end)

    slotItem:On("activate", function()
        OpenPicker(pCityBldgs, buildingIndex, slotIndex)
    end)

    slotItem:AddInputBindings({
        {
            Key = Keys.VK_RETURN,
            IsControl = true,
            MSG = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_VIEW_GREAT_WORK",
            Action = function()
                local greatWorkIndex = pCityBldgs:GetGreatWorkInSlot(buildingIndex, slotIndex)
                if greatWorkIndex ~= -1 then
                    ViewGreatWork({
                        Index = greatWorkIndex,
                        Building = buildingIndex,
                        CityBldgs = pCityBldgs,
                    })
                    UI.PlaySound("Play_GreatWorks_Gallery_Ambience")
                end
                return true
            end,
        },
    })

    return slotItem
end

local function AddSlots(parent, pCity, pCityBldgs, buildingInfo, slotIndices)
    for _, slotIndex in ipairs(slotIndices) do
        parent:AddChild(CreateSlotItem(pCity, pCityBldgs, buildingInfo, slotIndex))
    end
end

local function BuildCityFirstTree(tree, localPlayer, buildingPlotsByCity)
    for _, pCity in localPlayer:GetCities():Members() do
        if pCity and pCity:GetOwner() == Game.GetLocalPlayer() then
            local pCityBldgs = pCity:GetBuildings()
            local cityItem = nil

            for buildingInfo in GameInfo.Buildings() do
                if pCityBldgs:HasBuilding(buildingInfo.Index) then
                    local slots = GetValidSlotIndices(pCityBldgs, buildingInfo.Index)
                    if #slots > 0 then
                        if not cityItem then
                            local city = pCity
                            cityItem = mgr:CreateWidget(
                                mgr:GenerateWidgetId("CAIGW_City"), "TreeItem", {
                                    Label = function() return Locale.Lookup(city:GetName()) end,
                                    FocusKey = "city:" .. tostring(city:GetID()),
                                })
                            tree:AddChild(cityItem)
                        end

                        local city = pCity
                        local cityBuildings = pCityBldgs
                        local cityBuildingInfo = buildingInfo
                        local buildingPlotIndex = GetIndexedBuildingPlot(
                            buildingPlotsByCity, city:GetID(), cityBuildingInfo.Index)
                        local buildingItem = mgr:CreateWidget(
                            mgr:GenerateWidgetId("CAIGW_Building"), "TreeItem", {
                                Label = function()
                                    return AppendRelativePlotLocation(
                                        GetBuildingLabel(cityBuildingInfo, cityBuildings),
                                        buildingPlotIndex)
                                end,
                                Tooltip = function()
                                    return GetBuildingTooltip(cityBuildings, cityBuildingInfo)
                                end,
                                FocusKey = "bldg:" .. tostring(city:GetID())
                                    .. ":" .. tostring(cityBuildingInfo.Index),
                            })
                        buildingItem:On("activate", function()
                            MoveCursorToBuilding(buildingPlotIndex, city:GetID(),
                                cityBuildingInfo.Index)
                        end)
                        AddSlots(buildingItem, pCity, pCityBldgs, buildingInfo, slots)
                        cityItem:AddChild(buildingItem)
                    end
                end
            end
        end
    end
end

local function BuildBuildingFirstTree(tree, localPlayer, buildingPlotsByCity)
    for buildingInfo in GameInfo.Buildings() do
        local buildingItem = nil

        for _, pCity in localPlayer:GetCities():Members() do
            if pCity and pCity:GetOwner() == Game.GetLocalPlayer() then
                local pCityBldgs = pCity:GetBuildings()
                if pCityBldgs:HasBuilding(buildingInfo.Index) then
                    local slots = GetValidSlotIndices(pCityBldgs, buildingInfo.Index)
                    if #slots > 0 then
                        if not buildingItem then
                            local groupBuildingInfo = buildingInfo
                            buildingItem = mgr:CreateWidget(
                                mgr:GenerateWidgetId("CAIGW_BuildingGroup"), "TreeItem", {
                                    Label = function()
                                        return Locale.Lookup(groupBuildingInfo.Name)
                                    end,
                                    FocusKey = "building-type:" .. tostring(groupBuildingInfo.Index),
                                })
                            tree:AddChild(buildingItem)
                        end

                        local city = pCity
                        local cityBuildings = pCityBldgs
                        local cityBuildingInfo = buildingInfo
                        local buildingPlotIndex = GetIndexedBuildingPlot(
                            buildingPlotsByCity, city:GetID(), cityBuildingInfo.Index)
                        local cityItem = mgr:CreateWidget(
                            mgr:GenerateWidgetId("CAIGW_BuildingCity"), "TreeItem", {
                                Label = function()
                                    return AppendRelativePlotLocation(
                                        Locale.Lookup(city:GetName()), buildingPlotIndex)
                                end,
                                Tooltip = function()
                                    local details = GetBuildingTooltip(cityBuildings, cityBuildingInfo)
                                    local status = GetBuildingStatusText(
                                        cityBuildingInfo, cityBuildings)
                                    if status == "" then return details end
                                    if details == "" then return status end
                                    return status .. "[NEWLINE]" .. details
                                end,
                                FocusKey = "building-city:" .. tostring(cityBuildingInfo.Index)
                                    .. ":" .. tostring(city:GetID()),
                            })
                        cityItem:On("activate", function()
                            MoveCursorToBuilding(buildingPlotIndex, city:GetID(),
                                cityBuildingInfo.Index)
                        end)
                        AddSlots(cityItem, pCity, pCityBldgs, buildingInfo, slots)
                        buildingItem:AddChild(cityItem)
                    end
                end
            end
        end
    end
end

local function BuildTreeContent(tree)
    local localPlayer = Players[Game.GetLocalPlayer()]
    if not localPlayer then return end

    local buildingPlotsByCity = {}
    for _, pCity in localPlayer:GetCities():Members() do
        if pCity and pCity:GetOwner() == Game.GetLocalPlayer() then
            buildingPlotsByCity[pCity:GetID()] = IndexBuildingPlots(pCity)
        end
    end

    if m_groupByBuildings then
        BuildBuildingFirstTree(tree, localPlayer, buildingPlotsByCity)
    else
        BuildCityFirstTree(tree, localPlayer, buildingPlotsByCity)
    end
end

local function RefreshTree()
    if not m_ui.tree then return end
    m_lastFocusedWork = nil
    local capture = mgr:CaptureFocusKey(m_ui.tree)
    m_ui.tree:ClearChildren()
    BuildTreeContent(m_ui.tree)
    mgr:RestoreFocus(m_ui.tree, capture)
end

-- ---------------------------------------------------------------------------
-- Panel
-- ---------------------------------------------------------------------------

local function BuildPanel()
    if not mgr then return end

    m_ui.panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function()
            return Locale.Lookup("LOC_GREAT_WORKS_SCREEN_TITLE")
        end,
    })

    m_ui.tree = mgr:CreateWidget(TREE_ID, "Tree", {
        Label = function()
            local numGW     = Controls.NumGreatWorks:GetText() or "0"
            local numSpaces = Controls.NumDisplaySpaces:GetText() or "0"
            local label     = Locale.Lookup("LOC_CAI_GREAT_WORKS_SUMMARY",
                numGW, numSpaces)
            local yields    = GetYieldsSummary()
            if yields ~= "" then
                label = label .. ", " .. yields
            end
            return label
        end,
    })
    m_ui.panel:AddChild(m_ui.tree)

    BuildTreeContent(m_ui.tree)

    local viewBtn = mgr:CreateWidget("CAIGW_ViewWork", "Button", {
        Label = function()
            if m_lastFocusedWork then
                local gwType = m_lastFocusedWork.CityBldgs
                    :GetGreatWorkTypeFromIndex(m_lastFocusedWork.Index)
                local name = Locale.Lookup(GameInfo.GreatWorks[gwType].Name)
                return Locale.Lookup("LOC_GREAT_WORKS_VIEW_GREAT_WORK")
                    .. ": " .. name
            end
            return Locale.Lookup("LOC_GREAT_WORKS_VIEW_GREAT_WORK")
        end,
        HiddenPredicate = function() return m_lastFocusedWork == nil end,
    })
    viewBtn:SetFocusSound("Main_Menu_Mouse_Over")
    viewBtn:On("activate", function()
        ViewGreatWork(m_lastFocusedWork)
        UI.PlaySound("Play_GreatWorks_Gallery_Ambience")
    end)
    m_ui.panel:AddChild(viewBtn)

    local gallery = mgr:CreateWidget("CAIGW_ViewGallery", "Button", {
        Label           = function()
            return Locale.Lookup("LOC_GREAT_WORKS_VIEW_GALLERY")
        end,
        HiddenPredicate = function()
            return Controls.ViewGallery:IsHidden()
        end,
    })
    gallery:SetFocusSound("Main_Menu_Mouse_Over")
    gallery:On("activate", function() Controls.ViewGallery:DoLeftClick() end)
    m_ui.panel:AddChild(gallery)

    m_ui.grouping = mgr:CreateWidget("CAIGW_GroupByBuildings", "Checkbox", {
        Label = function()
            return Locale.Lookup("LOC_CAI_GREAT_WORKS_GROUP_BY_BUILDINGS")
        end,
        Tooltip = function()
            return Locale.Lookup("LOC_CAI_GREAT_WORKS_GROUP_BY_BUILDINGS_TOOLTIP")
        end,
    })
    m_ui.grouping:SetValueSetter(function(_, value)
        SaveGroupByBuildingsSetting(value)
        RefreshTree()
    end)
    m_ui.grouping:SetChecked(m_groupByBuildings, true)
    m_ui.grouping:SetFocusSound("Main_Menu_Mouse_Over")
    m_ui.panel:AddChild(m_ui.grouping)
end

local function PushPanel()
    if not mgr or not m_ui.panel then return end
    if not mgr:GetWidgetById(PANEL_ID) then
        mgr:Push(m_ui.panel, PopupPriority.Low)
    end
end

local function PopPanel()
    ClosePicker()
    m_lastFocusedWork = nil
    m_pendingMoveDestination = nil
    m_usePendingDestination = false
    if mgr and m_ui.panel then mgr:RemoveFromStack(PANEL_ID) end
    m_ui = { panel = nil, tree = nil, picker = nil, grouping = nil }
end

-- ---------------------------------------------------------------------------
-- Vanilla wraps
-- ---------------------------------------------------------------------------

Open = WrapFunc(Open, function(orig)
    orig()
    if Game.GetLocalPlayer() == -1 or ContextPtr:IsHidden() then return end
    if not m_ui.panel then BuildPanel() end
    RefreshTree()
    PushPanel()
end)

Close = WrapFunc(Close, function(orig)
    orig()
    PopPanel()
end)

GetDestBuilding = WrapFunc(GetDestBuilding, function(orig)
    if m_usePendingDestination and m_pendingMoveDestination then
        return m_pendingMoveDestination.Building
    end
    return orig()
end)

GetDestCity = WrapFunc(GetDestCity, function(orig)
    if m_usePendingDestination and m_pendingMoveDestination then
        return m_pendingMoveDestination.City
    end
    return orig()
end)

OnGreatWorkMoved = WrapFunc(OnGreatWorkMoved, function(orig,
        fromCityOwner, fromCityID, toCityOwner, toCityID, buildingID, greatWorkType)
    local pending = m_pendingMoveDestination
    local isPendingMove = pending ~= nil
        and fromCityOwner == Game.GetLocalPlayer()
        and toCityOwner == Game.GetLocalPlayer()
        and fromCityID == pending.SourceCity
        and toCityID == pending.City
    m_usePendingDestination = isPendingMove
    orig(fromCityOwner, fromCityID, toCityOwner, toCityID, buildingID, greatWorkType)
    m_usePendingDestination = false
    if isPendingMove then m_pendingMoveDestination = nil end
    if not ContextPtr:IsHidden() and m_ui.tree then
        RefreshTree()
    end
end)

OnLocalPlayerTurnBegin = WrapFunc(OnLocalPlayerTurnBegin, function(orig)
    orig()
    m_caiIsLocalPlayerTurn = true
end)

OnLocalPlayerTurnEnd = WrapFunc(OnLocalPlayerTurnEnd, function(orig)
    orig()
    m_caiIsLocalPlayerTurn = false
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, input)
    if mgr then
        local top = mgr:GetTop()
        if top == m_ui.panel or top == m_ui.picker then
            if mgr:HandleInput(input) then return true end
        end
    end
    return orig(input)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)

OnShutdown = WrapFunc(OnShutdown, function(orig)
    PopPanel()
    orig()
end)
ContextPtr:SetShutdown(OnShutdown)
