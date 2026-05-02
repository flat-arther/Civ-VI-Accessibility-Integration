include("caiUtils")
include("CityPanel")

--#State
local mgr = ExposedMembers.CAI_UIManager
local CITY_ACTION_CATEGORY = "LOC_OPTIONS_HOTKEY_CATEGORY_CITY"

info = ExposedMembers.CAIInfo or {}
ExposedMembers.CAIInfo = info

CityInfoPriority = {
    "Summary",
    "BuildingCount",
    "ReligiousFollowersCount",
    "AmenitiesSummary",
    "HousingSummary",
    "GrowthSummary",
    "ProductionSummary",
    "VisibleYields",
    "NormalFocusYields",
    "FavoredFocusYields",
    "IgnoredFocusYields",
}
--#City Info Lookup

function GetCityInfoData(city)
    if city == nil then
        return nil, nil
    end

    local data = GetCityData(city)
    if data ~= nil then
        data.X = city:GetX()
        data.Y = city:GetY()
    end

    return data, city
end

--#City Info Formatting

function AppendCityInfo(results, value)
    if value ~= nil and value ~= "" then
        table.insert(results, value)
    end
end

function JoinCityInfo(parts, separator)
    local results = {}

    for _, part in ipairs(parts) do
        if part ~= nil and part ~= "" then
            table.insert(results, part)
        end
    end

    return table.concat(results, separator or ", ")
end

function GetCityInfoName(data)
    if data == nil or data.CityName == nil then
        return nil
    end

    return (data.IsCapital and "[ICON_Capital]" or "") .. Locale.ToUpper(Locale.Lookup(data.CityName))
end

function GetCityInfoCoords(data, city)
    if city == nil and data == nil then
        return nil
    end

    local x = city and city:GetX() or data.X
    local y = city and city:GetY() or data.Y
    return Locale.Lookup("LOC_CAI_COORDS_STRING", x, y)
end

function GetCityInfoPopulation(data)
    if data == nil then
        return nil
    end

    return Locale.Lookup("LOC_CAI_CITY_POPULATION", data.Population)
end

function GetCityInfoHealth(data)
    if data == nil then
        return nil
    end

    local tooltip = Locale.Lookup("LOC_HUD_UNIT_PANEL_HEALTH_TOOLTIP", data.HitpointsCurrent, data.HitpointsTotal)
    if data.CityWallTotalHP > 0 then
        tooltip = tooltip ..
            "[NEWLINE]" ..
            Locale.Lookup("LOC_HUD_UNIT_PANEL_WALL_HEALTH_TOOLTIP", data.CityWallCurrentHP, data.CityWallTotalHP)
    end

    return tooltip
end

function GetCityInfoYieldText(value, icon)
    return icon .. toPlusMinusString(value)
end

function GetCityInfoPercentText(value)
    if value == nil then
        return nil
    end

    return tostring(math.floor((value * 100) + 0.5)) .. "%"
end

function GetCityInfoCurrentProgressText(value)
    local percentText = GetCityInfoPercentText(value)
    if percentText == nil then
        return nil
    end

    return Locale.Lookup("LOC_CAI_CURRENT_PROGRESS") .. ", " .. percentText
end

function GetCityInfoNextTurnProgressText(value)
    local percentText = GetCityInfoPercentText(value)
    if percentText == nil then
        return nil
    end

    return Locale.Lookup("LOC_CAI_NEXT_TURN_PROGRESS") .. ", " .. percentText
end

function GetCityInfoYieldState(data, yieldType)
    if data == nil or data.YieldFilters == nil then
        return nil
    end

    return data.YieldFilters[yieldType]
end

function GetCityInfoYieldEntry(data, yieldType, value, icon)
    if data == nil then
        return nil
    end

    local yieldInfo = GameInfo.Yields[yieldType]
    if yieldInfo == nil then
        return nil
    end

    return Locale.Lookup(yieldInfo.Name) .. ", " .. GetCityInfoYieldText(value, icon)
end

function GetCityInfoCultureYield(data)
    if data == nil then
        return nil
    end

    return GetCityInfoYieldText(data.CulturePerTurn, "[ICON_Culture]")
end

function GetCityInfoFoodYield(data)
    if data == nil then
        return nil
    end

    return GetCityInfoYieldText(data.FoodPerTurn, "[ICON_Food]")
end

function GetCityInfoProductionYield(data)
    if data == nil then
        return nil
    end

    return GetCityInfoYieldText(data.ProductionPerTurn, "[ICON_Production]")
end

function GetCityInfoScienceYield(data)
    if data == nil then
        return nil
    end

    return GetCityInfoYieldText(data.SciencePerTurn, "[ICON_Science]")
end

function GetCityInfoFaithYield(data)
    if data == nil then
        return nil
    end

    return GetCityInfoYieldText(data.FaithPerTurn, "[ICON_Faith]")
end

function GetCityInfoGoldYield(data)
    if data == nil then
        return nil
    end

    return GetCityInfoYieldText(data.GoldPerTurn, "[ICON_Gold]")
end

function GetCityInfoVisibleYields(data)
    local results = {}

    AppendCityInfo(results, GetCityInfoYieldEntry(data, YieldTypes.CULTURE, data.CulturePerTurn, "[ICON_Culture]"))
    AppendCityInfo(results, GetCityInfoYieldEntry(data, YieldTypes.FOOD, data.FoodPerTurn, "[ICON_Food]"))
    AppendCityInfo(results,
        GetCityInfoYieldEntry(data, YieldTypes.PRODUCTION, data.ProductionPerTurn, "[ICON_Production]"))
    AppendCityInfo(results, GetCityInfoYieldEntry(data, YieldTypes.SCIENCE, data.SciencePerTurn, "[ICON_Science]"))
    AppendCityInfo(results, GetCityInfoYieldEntry(data, YieldTypes.FAITH, data.FaithPerTurn, "[ICON_Faith]"))
    AppendCityInfo(results, GetCityInfoYieldEntry(data, YieldTypes.GOLD, data.GoldPerTurn, "[ICON_Gold]"))

    return results
end

function GetCityInfoFilteredYields(data, filterState)
    if data == nil then
        return {}
    end

    local results = {}
    local visibleYields = {
        { Type = YieldTypes.CULTURE,    Value = data.CulturePerTurn,    Icon = "[ICON_Culture]" },
        { Type = YieldTypes.FOOD,       Value = data.FoodPerTurn,       Icon = "[ICON_Food]" },
        { Type = YieldTypes.PRODUCTION, Value = data.ProductionPerTurn, Icon = "[ICON_Production]" },
        { Type = YieldTypes.SCIENCE,    Value = data.SciencePerTurn,    Icon = "[ICON_Science]" },
        { Type = YieldTypes.FAITH,      Value = data.FaithPerTurn,      Icon = "[ICON_Faith]" },
        { Type = YieldTypes.GOLD,       Value = data.GoldPerTurn,       Icon = "[ICON_Gold]" },
    }

    for _, yieldData in ipairs(visibleYields) do
        local yieldState = GetCityInfoYieldState(data, yieldData.Type)
        if filterState == nil then
            if yieldState ~= YIELD_STATE.FAVORED and yieldState ~= YIELD_STATE.IGNORED then
                AppendCityInfo(results, GetCityInfoYieldEntry(data, yieldData.Type, yieldData.Value, yieldData.Icon))
            end
        elseif yieldState == filterState then
            AppendCityInfo(results, GetCityInfoYieldEntry(data, yieldData.Type, yieldData.Value, yieldData.Icon))
        end
    end

    return results
end

function GetCityInfoBuildings(data)
    if data == nil then
        return nil
    end

    return Locale.Lookup("LOC_HUD_CITY_BUILDINGS") .. ", " .. tostring(data.BuildingsNum)
end

function GetCityInfoReligionFollowers(data)
    if data == nil then
        return nil
    end

    if not GameCapabilities.HasCapability("CAPABILITY_CITY_HUD_RELIGION_TAB") then
        return nil
    end

    return Locale.Lookup("LOC_HUD_CITY_RELIGIOUS_CITIZENS") .. ", " .. tostring(data.ReligionFollowers)
end

function GetCityInfoAmenities(data)
    if data == nil then
        return nil
    end

    local amenitiesNumText = data.AmenitiesNetAmount
    if data.AmenitiesNetAmount > 0 then
        amenitiesNumText = "+" .. amenitiesNumText
    end

    return Locale.Lookup("LOC_HUD_CITY_AMENITIES") .. ", " .. tostring(amenitiesNumText)
end

function GetCityInfoHousing(data)
    if data == nil then
        return nil
    end

    return Locale.Lookup("LOC_HUD_CITY_HOUSING") .. ", " .. tostring(data.Population) .. " of " .. tostring(data.Housing)
end

function GetCityInfoGrowth(data)
    if data == nil then
        return nil
    end

    local progressText = JoinCityInfo({
        GetCityInfoCurrentProgressText(data.CurrentFoodPercent),
        GetCityInfoNextTurnProgressText(data.FoodPercentNextTurn),
    }, ", ")

    if data.Occupied then
        return JoinCityInfo({
            tostring(math.abs(data.TurnsUntilGrowth)) ..
            " " .. Locale.ToUpper(Locale.Lookup("LOC_HUD_CITY_GROWTH_OCCUPIED")),
            progressText,
        }, ", ")
    elseif data.TurnsUntilGrowth >= 0 then
        return JoinCityInfo({
            tostring(math.abs(data.TurnsUntilGrowth)) ..
            " " .. Locale.ToUpper(Locale.Lookup("LOC_HUD_CITY_TURNS_UNTIL_GROWTH", data.TurnsUntilGrowth)),
            progressText,
        }, ", ")
    else
        return JoinCityInfo({
            tostring(math.abs(data.TurnsUntilGrowth)) ..
            " " .. Locale.ToUpper(Locale.Lookup("LOC_HUD_CITY_TURNS_UNTIL_LOSS", math.abs(data.TurnsUntilGrowth))),
            progressText,
        }, ", ")
    end
end

function GetCityInfoProduction(data)
    if data == nil then
        return nil
    end

    if data.CurrentProductionName == Locale.Lookup("LOC_HUD_CITY_PRODUCTION_NOTHING_PRODUCED")
        or data.CurrentProductionName == Locale.Lookup("LOC_HUD_CITY_NOTHING_PRODUCED")
        or (data.CurrentTurnsLeft <= 0 and (data.CurrentProductionStats == nil or data.CurrentProductionStats == "")
            and (data.CurrentProductionDescription == nil or data.CurrentProductionDescription == "")) then
        return Locale.ToUpper(Locale.Lookup("LOC_HUD_CITY_NOTHING_PRODUCED"))
    end

    return JoinCityInfo({
        data.CurrentProductionName,
        tostring(data.CurrentTurnsLeft) ..
        " " .. Locale.ToUpper(Locale.Lookup("LOC_HUD_CITY_TURNS_UNTIL_COMPLETED", data.CurrentTurnsLeft)),
        GetCityInfoCurrentProgressText(data.CurrentProdPercent),
        GetCityInfoNextTurnProgressText(data.ProdPercentNextTurn),
        data.CurrentProductionStats,
        data.CurrentProductionDescription,
    }, ", ")
end

--#City Info Registry

CityInfo = {
    Summary = function(data, city)
        return JoinCityInfo({
            GetCityInfoName(data),
            GetCityInfoCoords(data, city),
            GetCityInfoPopulation(data),
            GetCityInfoHealth(data),
            GetCityInfoCultureYield(data),
            GetCityInfoFoodYield(data),
            GetCityInfoProductionYield(data),
            GetCityInfoScienceYield(data),
            GetCityInfoFaithYield(data),
            GetCityInfoGoldYield(data),
        }, ", ")
    end,

    BuildingCount = function(data, city)
        return GetCityInfoBuildings(data)
    end,

    ReligiousFollowersCount = function(data, city)
        return GetCityInfoReligionFollowers(data)
    end,

    AmenitiesSummary = function(data, city)
        return GetCityInfoAmenities(data)
    end,

    HousingSummary = function(data, city)
        return GetCityInfoHousing(data)
    end,

    GrowthSummary = function(data, city)
        return GetCityInfoGrowth(data)
    end,

    ProductionSummary = function(data, city)
        return GetCityInfoProduction(data)
    end,

    VisibleYields = function(data, city)
        return GetCityInfoVisibleYields(data)
    end,

    NormalFocusYields = function(data, city)
        return GetCityInfoFilteredYields(data, nil)
    end,

    FavoredFocusYields = function(data, city)
        return GetCityInfoFilteredYields(data, YIELD_STATE.FAVORED)
    end,

    IgnoredFocusYields = function(data, city)
        return GetCityInfoFilteredYields(data, YIELD_STATE.IGNORED)
    end,
}

info.CityInfo = CityInfo
info.CityInfoPriority = CityInfoPriority
CityInfoActionMap = {}
CityInfoFallbacks = {
    ReligiousFollowersCount = "LOC_CAI_CITY_NO_RELIGION_INFO",
    NormalFocusYields       = "LOC_CAI_CITY_NO_NORMAL_FOCUS_YIELDS",
    FavoredFocusYields      = "LOC_CAI_CITY_NO_FAVORED_YIELDS",
    IgnoredFocusYields      = "LOC_CAI_CITY_NO_IGNORED_YIELDS",
}
CityActionMap = {}
CityActionList = nil
CityActionCategoryIds = nil
--#Action Metadata

function GetActionText(actionId, getter)
    if actionId == nil or getter == nil then
        return ""
    end

    local locKey = getter(actionId)
    if locKey == nil or locKey == "" then
        return ""
    end

    return Locale.Lookup(locKey)
end

function GetActionNameText(actionId)
    return GetActionText(actionId, Input.GetActionName)
end

function GetActionDescriptionText(actionId)
    return GetActionText(actionId, Input.GetActionDescription)
end

function IsControlAvailable(control, allowDisabled)
    if control == nil or control:IsHidden() then
        return false
    end

    if not allowDisabled and control:IsDisabled() then
        return false
    end

    return true
end

function IsCityPanelActionAvailable(control)
    return UI.GetHeadSelectedCity() ~= nil and ContextPtr:IsHidden() == false and IsControlAvailable(control, false)
end

function IsCityPanelActionVisible(control)
    return UI.GetHeadSelectedCity() ~= nil and ContextPtr:IsHidden() == false and IsControlAvailable(control, true)
end

--#City Action Menu

function ToggleCityPanelCheck(control)
    if control == nil or control:IsDisabled() or control:IsHidden() then
        return
    end

    control:SetAndCall(not control:IsChecked())
end

function CloseCityActionList()
    if CityActionList ~= nil then
        mgr:Pop()
        CityActionList = nil
    end
end

function BuildCityActionData(helper, isEnabled)
    return {
        helper = helper,
        IsEnabled = isEnabled or function()
            return true
        end,
    }
end

function GetCityCategoryActionIds()
    if CityActionCategoryIds ~= nil then
        return CityActionCategoryIds
    end

    CityActionCategoryIds = {}
    for _, actionId in ipairs(GetInputActionsByCategory(CITY_ACTION_CATEGORY)) do
        if actionId ~= Input.GetActionId("SelectionActions") and CityActionMap[actionId] ~= nil then
            table.insert(CityActionCategoryIds, actionId)
        end
    end

    return CityActionCategoryIds
end

function BuildCityActionList()
    local data, city = GetCityInfoData(UI.GetHeadSelectedCity())
    local cityName = GetCityInfoName(data) or Locale.Lookup("LOC_CAI_CITY_ACTIONS")
    local list = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICityPanelList"), "List", {
        GetLabel = function()
            return Locale.Lookup("LOC_CAI_SELECTION_ACTIONS_FOR", cityName)
        end,
    })

    list:AddInputBinding({
        Key = Keys.VK_ESCAPE,
        Action = function()
            CloseCityActionList()
            return true
        end,
    })

    for _, actionId in ipairs(GetCityCategoryActionIds()) do
        local actionData = CityActionMap[actionId]
        if actionData ~= nil and actionData.IsEnabled() then
            local currentActionId = actionId
            list:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICityPanelMenuItem"), "MenuItem", {
                GetLabel = function()
                    return GetActionNameText(currentActionId)
                end,
                GetTooltip = function()
                    return GetActionDescriptionText(currentActionId)
                end,
                OnFocusEnter = function()
                    UI.PlaySound("Main_Menu_Mouse_Over")
                end,
                OnClick = function()
                    CloseCityActionList()
                    actionData.helper()
                end,
            }))
        end
    end

    return list
end

function OpenCityActionList()
    if mgr == nil or UI.GetHeadSelectedCity() == nil or ContextPtr:IsHidden() then
        return
    end

    if CityActionList ~= nil then
        CloseCityActionList()
    end

    CityActionList = BuildCityActionList()
    if CityActionList ~= nil and CityActionList.Children ~= nil and #CityActionList.Children > 0 then
        mgr:Push(CityActionList, PopupPriority.Low)
    else
        CityActionList = nil
    end
end

--#Citizen Yield Focus

local CAI_YIELD_FOCUS_YIELDS = {
    { Type = YieldTypes.FOOD },
    { Type = YieldTypes.PRODUCTION },
    { Type = YieldTypes.GOLD },
    { Type = YieldTypes.SCIENCE },
    { Type = YieldTypes.CULTURE },
    { Type = YieldTypes.FAITH },
}

local CAI_YIELD_FOCUS_LIST_ID = "CAICityYieldFocusList"

function CAI_GetYieldStateName(state)
    if state == YIELD_STATE.FAVORED then
        return Locale.Lookup("LOC_CAI_CITY_YIELD_STATE_FAVORED")
    elseif state == YIELD_STATE.IGNORED then
        return Locale.Lookup("LOC_CAI_CITY_YIELD_STATE_IGNORED")
    else
        return Locale.Lookup("LOC_CAI_CITY_YIELD_STATE_NORMAL")
    end
end

function CAI_SetCitizenFocusTo(yieldType, targetState)
    local city = g_pCity or UI.GetHeadSelectedCity()
    if city == nil then return end
    local pCitizens = city:GetCitizens()
    local isFavored = pCitizens:IsFavoredYield(yieldType)
    local isDisfavored = pCitizens:IsDisfavoredYield(yieldType)

    if targetState == YIELD_STATE.FAVORED then
        if not isFavored then SetYieldFocus(yieldType) end
    elseif targetState == YIELD_STATE.IGNORED then
        if not isDisfavored then SetYieldIgnore(yieldType) end
    else
        if isFavored then SetYieldFocus(yieldType)
        elseif isDisfavored then SetYieldIgnore(yieldType) end
    end
end

function OpenCitizenYieldFocusList()
    if mgr == nil or UI.GetHeadSelectedCity() == nil or ContextPtr:IsHidden() then return end

    local data = GetCityInfoData(UI.GetHeadSelectedCity())
    local cityName = GetCityInfoName(data) or Locale.Lookup("LOC_CAI_CITY_ACTIONS")

    local outerList = mgr:CreateUIWidget(CAI_YIELD_FOCUS_LIST_ID, "List", {
        GetLabel = function() return Locale.Lookup("LOC_CAI_CITY_YIELD_FOCUS_LIST", cityName) end,
    })
    outerList:AddInputBinding({ Key = Keys.VK_ESCAPE, Action = function()
        mgr:RemoveFromStack(CAI_YIELD_FOCUS_LIST_ID); return true
    end })

    for _, yieldEntry in ipairs(CAI_YIELD_FOCUS_YIELDS) do
        local yieldType = yieldEntry.Type
        local yieldInfo = GameInfo.Yields[yieldType]
        if yieldInfo ~= nil then
            local yieldName = Locale.Lookup(yieldInfo.Name)
            outerList:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICityYieldFocusDropdown"), "DropdownMenu", {
                GetLabel = function() return yieldName end,
                GetValue = function()
                    local liveData = GetCityInfoData(UI.GetHeadSelectedCity())
                    return CAI_GetYieldStateName(GetCityInfoYieldState(liveData, yieldType))
                end,
                OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
                OnClick = function()
                    local subList = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICityYieldFocusSub"), "List", {
                        GetLabel = function() return Locale.Lookup("LOC_CAI_CITY_YIELD_FOCUS_OPTIONS", yieldName) end,
                    })
                    subList:AddInputBinding({ Key = Keys.VK_ESCAPE, Action = function()
                        mgr:Pop(); return true
                    end })

                    local focusStates = {
                        { State = YIELD_STATE.NORMAL,  Key = "LOC_CAI_CITY_YIELD_STATE_NORMAL" },
                        { State = YIELD_STATE.FAVORED, Key = "LOC_CAI_CITY_YIELD_STATE_FAVORED" },
                        { State = YIELD_STATE.IGNORED, Key = "LOC_CAI_CITY_YIELD_STATE_IGNORED" },
                    }
                    for _, entry in ipairs(focusStates) do
                        local targetState = entry.State
                        local stateKey = entry.Key
                        subList:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICityYieldFocusState"), "MenuItem", {
                            GetLabel = function() return Locale.Lookup(stateKey) end,
                            GetState = function()
                                local liveData = GetCityInfoData(UI.GetHeadSelectedCity())
                                local current = GetCityInfoYieldState(liveData, yieldType)
                                local isMatch = (targetState == YIELD_STATE.NORMAL
                                    and current ~= YIELD_STATE.FAVORED and current ~= YIELD_STATE.IGNORED)
                                    or current == targetState
                                return isMatch and Locale.Lookup("LOC_CAI_STATE_SELECTED") or nil
                            end,
                            OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
                            OnClick = function()
                                CAI_SetCitizenFocusTo(yieldType, targetState)
                                mgr:Pop()
                            end,
                        }))
                    end

                    mgr:Push(subList, PopupPriority.Low)
                end,
            }))
        end
    end

    mgr:Push(outerList, PopupPriority.Low)
end

--#Action Maps

function InitializeCityActionMap()
    CityActionMap = {
        [Input.GetActionId("SelectionActions")] = BuildCityActionData(
            OpenCityActionList,
            function()
                return UI.GetHeadSelectedCity() ~= nil and ContextPtr:IsHidden() == false
            end
        ),
        [Input.GetActionId("CityToggleOverview")] = BuildCityActionData(
            function()
                ToggleCityPanelCheck(Controls.ToggleOverviewPanel)
            end,
            function()
                return UI.GetHeadSelectedCity() ~= nil and ContextPtr:IsHidden() == false
            end
        ),
        [Input.GetActionId("CityOpenBuildings")] = BuildCityActionData(
            OnBreakdown,
            function()
                return UI.GetHeadSelectedCity() ~= nil and ContextPtr:IsHidden() == false
            end
        ),
        [Input.GetActionId("CityOpenReligion")] = BuildCityActionData(
            OnReligion,
            function()
                return GameCapabilities.HasCapability("CAPABILITY_CITY_HUD_RELIGION_TAB")
                    and IsCityPanelActionVisible(Controls.ReligionButton)
            end
        ),
        [Input.GetActionId("CityOpenAmenities")] = BuildCityActionData(
            OnAmenities,
            function()
                return UI.GetHeadSelectedCity() ~= nil and ContextPtr:IsHidden() == false
            end
        ),
        [Input.GetActionId("CityOpenHousing")] = BuildCityActionData(
            OnHousing,
            function()
                return UI.GetHeadSelectedCity() ~= nil and ContextPtr:IsHidden() == false
            end
        ),
        [Input.GetActionId("CityOpenCitizens")] = BuildCityActionData(
            OnCitizensGrowth,
            function()
                return UI.GetHeadSelectedCity() ~= nil and ContextPtr:IsHidden() == false
            end
        ),
        [Input.GetActionId("CityPurchaseTile")] = BuildCityActionData(
            function()
                ToggleCityPanelCheck(Controls.PurchaseTileCheck)
            end,
            function()
                return GameCapabilities.HasCapability("CAPABILITY_GOLD")
                    and IsCityPanelActionAvailable(Controls.PurchaseTileCheck)
            end
        ),
        [Input.GetActionId("CityManageCitizens")] = BuildCityActionData(
            function()
                ToggleCityPanelCheck(Controls.ManageCitizensCheck)
            end,
            function()
                return IsCityPanelActionAvailable(Controls.ManageCitizensCheck)
            end
        ),
        [Input.GetActionId("CityPurchaseWithGold")] = BuildCityActionData(
            function()
                ToggleCityPanelCheck(Controls.ProduceWithGoldCheck)
            end,
            function()
                return GameCapabilities.HasCapability("CAPABILITY_GOLD")
                    and IsCityPanelActionAvailable(Controls.ProduceWithGoldCheck)
            end
        ),
        [Input.GetActionId("CityChangeCitizenYieldFocus")] = BuildCityActionData(
            OpenCitizenYieldFocusList,
            function()
                return UI.GetHeadSelectedCity() ~= nil
                    and ContextPtr:IsHidden() == false
                    and Controls.YieldsArea ~= nil
                    and not Controls.YieldsArea:IsHidden()
                    and not Controls.YieldsArea:IsDisabled()
            end
        ),
        [Input.GetActionId("CityPurchaseWithFaith")] = BuildCityActionData(
            function()
                ToggleCityPanelCheck(Controls.ProduceWithFaithCheck)
            end,
            function()
                return IsCityPanelActionAvailable(Controls.ProduceWithFaithCheck)
            end
        ),
        [Input.GetActionId("CityChangeProduction")] = BuildCityActionData(
            function()
                ToggleCityPanelCheck(Controls.ChangeProductionCheck)
            end,
            function()
                return IsCityPanelActionAvailable(Controls.ChangeProductionCheck)
            end
        ),
    }
end

function InitializeCityInfoActionMap()
    CityInfoActionMap = {
        [Input.GetActionId("ReadSelectionSummary")] = { "Summary" },
        [Input.GetActionId("ReadSelectionInfo1")] = { "BuildingCount" },
        [Input.GetActionId("ReadSelectionInfo2")] = { "ReligiousFollowersCount" },
        [Input.GetActionId("ReadSelectionInfo3")] = { "AmenitiesSummary" },
        [Input.GetActionId("ReadSelectionInfo4")] = { "HousingSummary" },
        [Input.GetActionId("ReadSelectionInfo5")] = { "GrowthSummary" },
        [Input.GetActionId("ReadSelectionInfo6")] = { "ProductionSummary" },
        [Input.GetActionId("ReadSelectionInfo7")] = { "VisibleYields" },
        [Input.GetActionId("ReadSelectionInfo8")] = { "NormalFocusYields" },
        [Input.GetActionId("ReadSelectionInfo9")] = { "FavoredFocusYields" },
        [Input.GetActionId("ReadSelectionInfo10")] = { "IgnoredFocusYields" },
    }
end

--#Event Listeners and input handling
function OnHandleInput(inputStruct)
    if not mgr then return false end
    return mgr:HandleInput(inputStruct)
end

function OnSelectionInfoInputActionTriggered(actionId)
    if ContextPtr:IsHidden() then return end
    local requestedKeys = CityInfoActionMap[actionId]
    local city = UI.GetHeadSelectedCity()
    local results

    if requestedKeys == nil or city == nil then
        return
    end

    results = info:RequestCityInfo(nil, requestedKeys)
    if results == nil or #results == 0 then
        if #requestedKeys == 1 and requestedKeys[1] ~= "Summary" then
            local fallback = CityInfoFallbacks[requestedKeys[1]]
            if fallback ~= nil then
                Speak(Locale.Lookup(fallback))
            end
        end
        return
    end

    Speak(ProcessIcons(table.concat(results, "\n")))
end

function OnCityActionInputActionTriggered(actionId)
    local action = CityActionMap[actionId]

    if action == nil or not action.IsEnabled() then
        return
    end

    action.helper()
end

function OnCitySelectionChanged(ownerPlayerID, cityID, i, j, k, isSelected, isEditable)
    if ContextPtr:IsHidden() then return end
    if not isSelected then return end

    local results = info:RequestCityInfo(cityID, { "Summary" }, ownerPlayerID)
    if results == nil or #results == 0 then
        return
    end

    Speak(ProcessIcons(table.concat(results, "\n")))
    LuaEvents.CAICursorMove(i, j)
end

--#Public API
---Returns info about a given city, given a city id, a list of keys, and a player
---@param cityID number|nil
---@param requestedKeys string[]|nil
---@param playerID number|nil
---@return string[]
function info:RequestCityInfo(cityID, requestedKeys, playerID)
    local city = nil
    if cityID == nil then
        city = UI.GetHeadSelectedCity()
    else
        local lookupPlayerID = playerID
        if lookupPlayerID == nil or lookupPlayerID == -1 then
            lookupPlayerID = Game.GetLocalPlayer()
        end

        if lookupPlayerID ~= nil and lookupPlayerID ~= -1 then
            city = CityManager.GetCity(lookupPlayerID, cityID)
        end
    end

    local data
    data, city = GetCityInfoData(city)
    local results = {}

    if data == nil then
        return results
    end

    requestedKeys = requestedKeys or CityInfoPriority

    for _, key in ipairs(requestedKeys) do
        local helper = self.CityInfo[key]
        if helper ~= nil then
            local output = helper(data, city)
            if type(output) == "table" then
                for _, value in ipairs(output) do
                    AppendCityInfo(results, value)
                end
            else
                AppendCityInfo(results, output)
            end
        end
    end

    return results
end

--#Initialization

InitializeCityActionMap()
InitializeCityInfoActionMap()
Events.CitySelectionChanged.Add(OnCitySelectionChanged)
Events.InputActionTriggered.Add(OnCityActionInputActionTriggered)
Events.InputActionTriggered.Add(OnSelectionInfoInputActionTriggered)
ContextPtr:SetInputHandler(OnHandleInput, true)
