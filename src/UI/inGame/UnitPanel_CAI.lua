include("caiUtils")
include("inGameHelpers_CAI")
include("interfaceInfoHelpers_CAI")
include("Civ6Common")

if IsExpansion2Active ~= nil and IsExpansion2Active() then
    include("UnitPanel_Expansion2")
else
    include("UnitPanel")
end

local mgr = ExposedMembers.CAI_UIManager
local m_IsGameStarted = false
local HexCoordUtils = CAIHexCoordUtils

local UNIT_ACTION_LIST_ID = "CAIUnitPanelActionList"
local UNIT_LIST_ID = "CAIUnitPanelUnitList"
local UNIT_ABILITIES_LIST_ID = "CAIUnitAbilitiesList"
local UNIT_ABILITY_INFO_LIMIT = 10
local UNIT_BUILD_IMPROVEMENTS_SUBMENU_ID = "CAIUnitBuildImprovementsSubMenu"
local UNIT_SIMPLE_PROMOTION_LIST_ID = "CAIUnitPanelSimplePromotionList"
local UNIT_NAME_PANEL_ID = "CAIUnitPanelNamePanel"
local UNIT_NAME_EDIT_ID = "CAIUnitPanelNameEdit"

local prevUnitAction = Input.GetActionId("PrevUnitSelection")
local nextUnitAction = Input.GetActionId("NextUnitSelection")
local prevReadyUnitAction = Input.GetActionId("PrevReadyUnitSelection")
local nextReadyUnitAction = Input.GetActionId("NextReadyUnitSelection")
local openUnitListAction = Input.GetActionId("UI_UnitPanelOpenUnitList")
local unitViewAbilitiesAction = Input.GetActionId("UnitViewAbilities")
local selectionActionsAction = Input.GetActionId("SelectionActions")
local caiDeleteUnitAction = Input.GetActionId("CAIDeleteUnit")
local promoteActionHash = GameInfo.UnitCommands["UNITCOMMAND_PROMOTE"] ~= nil and
    GameInfo.UnitCommands["UNITCOMMAND_PROMOTE"].Hash or
    UnitCommandTypes.PROMOTE
local upgradeActionHash = GameInfo.UnitCommands["UNITCOMMAND_UPGRADE"] ~= nil and
    GameInfo.UnitCommands["UNITCOMMAND_UPGRADE"].Hash or
    UnitCommandTypes.UPGRADE
local deleteActionHash = GameInfo.UnitCommands["UNITCOMMAND_DELETE"] ~= nil and
    GameInfo.UnitCommands["UNITCOMMAND_DELETE"].Hash or
    UnitCommandTypes.DELETE

local UnitCategories = {
    {
        Name = "LOC_CAI_UNIT_CAT_ALL",
        Prev = UI.SelectPrevUnit,
        Next = UI.SelectNextUnit
    },
    {
        Name = "LOC_CAI_UNIT_CAT_READY",
        Prev = UI.SelectPrevReadyUnit,
        Next = UI.SelectNextReadyUnit
    }
}

local activeCategoryIdx = 1
local UnitActionList = nil
local UnitList = nil
local SimplePromotionList = nil
local UnitNamePanel = nil
local UnitNameEdit = nil

info = ExposedMembers.CAIInfo or {}
ExposedMembers.CAIInfo = info

UnitInfoPriority = {
    "Summary",
    "Promotions",
    "Abilities",
    "Stats",
    "SpecialInfo",
    "QueuedPath",
}

UnitInfoActionMap = {}
UnitInfoFallbacks = {
    Stats         = "LOC_CAI_UNIT_NO_STATS",
    Charges       = "LOC_CAI_UNIT_NO_CHARGES",
    Promotions    = "LOC_CAI_UNIT_NO_PROMOTIONS",
    Abilities     = "LOC_CAI_UNIT_NO_ABILITIES",
    SpecialInfo   = "LOC_CAI_UNIT_NO_SPECIAL_INFO",
    QueuedPath    = "LOC_CAI_UNIT_NO_QUEUED_PATH",
    Activity      = "LOC_CAI_UNIT_NO_ACTIVITY",
    CombatPreview = "LOC_CAI_UNIT_NO_COMBAT",
}

local UnitSummaryRequestedKeys = {
    "UnitName",
    "Activity",
    "NextWaypoint",
    "Health",
    "Moves",
    "Charges",
    "UpgradeHint",
    "Promotions",
    "BuilderRecommendation",
    "Abilities",
}

local function AppendUnitInfo(results, value)
    if value ~= nil and value ~= "" then
        table.insert(results, value)
    end
end

local function JoinUnitInfo(parts, separator)
    local results = {}
    for _, part in ipairs(parts) do
        if part ~= nil and part ~= "" then
            table.insert(results, part)
        end
    end
    return table.concat(results, separator or ", ")
end

local function GetFirstUnitInfoLine(value)
    if value == nil then
        return nil
    end

    local newlinePos = string.find(value, "%[NEWLINE%]", 1)
    if newlinePos ~= nil then
        local firstLine = string.sub(value, 1, newlinePos - 1)
        if firstLine ~= nil and firstLine ~= "" then
            return firstLine
        end
    end

    return value
end

local function GetSelectedUnit()
    return UI.GetHeadSelectedUnit()
end

local CloseUnitList            -- forward declaration; assigned below
local CloseSimplePromotionList -- forward declaration; assigned below
local CloseUnitNamePanel       -- forward declaration; assigned below

local function ReadCurrentUnitData()
    local data = GetSubjectData ~= nil and GetSubjectData() or nil
    if data == nil then
        local unit = GetSelectedUnit()
        if unit ~= nil and ReadUnitData ~= nil then
            data = ReadUnitData(unit)
        end
    end
    return data
end

local function UnitFocusKey(owner, unitID)
    return "unit:list:" .. tostring(owner) .. ":" .. tostring(unitID)
end

local function BindCivilopediaShortcut(item, getUnitID)
    item:AddInputBinding({
        Key = Keys.VK_RETURN,
        IsShift = true,
        Description = "LOC_CAI_KB_OPEN_CIVILOPEDIA",
        Action = function()
            local unitID = getUnitID()
            local resolved = Players[Game.GetLocalPlayer()]:GetUnits():FindID(unitID)
            if resolved == nil then
                return true
            end

            local unitInfo = GameInfo.Units[resolved:GetUnitType()]
            if unitInfo ~= nil then
                CloseUnitList()
                LuaEvents.OpenCivilopedia(unitInfo.UnitType)
            end
            return true
        end,
    })
end

local GetUnitActionEntries
local GetUnitActionLabel
local GetUnitActionTooltip
local GetControlText
local GetControlTooltip
local UnitActionHotkeyIds = nil

local function ResolveUnit(unitID, playerID)
    if unitID == nil then
        return GetSelectedUnit()
    end

    local lookupPlayerID = playerID
    if lookupPlayerID == nil or lookupPlayerID == -1 then
        lookupPlayerID = Game.GetLocalPlayer()
    end

    local player = Players[lookupPlayerID]
    if player == nil then
        return nil
    end

    return player:GetUnits():FindID(unitID)
end

local function ResolveUnitData(unitID, playerID)
    local unit = ResolveUnit(unitID, playerID)
    if unit == nil then
        return nil, nil
    end

    local selectedUnit = GetSelectedUnit()
    local data = nil

    if selectedUnit ~= nil
        and selectedUnit:GetOwner() == unit:GetOwner()
        and selectedUnit:GetID() == unit:GetID()
        and GetSubjectData ~= nil then
        data = GetSubjectData()
    end

    if data == nil and ReadUnitData ~= nil then
        data = ReadUnitData(unit)
    end

    return data, unit
end

local function GetUnitInfoName(data, unit)
    if unit ~= nil then
        return FormatOwnedUnitDisplayName(unit)
    end

    if data == nil then
        return nil
    end

    local unitInfo = data.UnitType ~= nil and GameInfo.Units[data.UnitType] or nil
    if unitInfo == nil or unitInfo.Name == nil then
        return nil
    end

    return FormatOwnedName(nil, Locale.Lookup(unitInfo.Name), GetUnitDataFormationSuffix(data))
end

local function GetUnitListName(unit)
    if unit == nil then
        return nil
    end

    local unitName = unit:GetName()
    local localizedName = unitName ~= nil and unitName ~= "" and Locale.Lookup(unitName) or nil
    if localizedName == nil or localizedName == "" then
        local unitInfo = GameInfo.Units[unit:GetUnitType()]
        if unitInfo ~= nil and unitInfo.Name ~= nil and unitInfo.Name ~= "" then
            localizedName = Locale.Lookup(unitInfo.Name)
        end
    end

    return FormatOwnedName(nil, localizedName, GetUnitFormationSuffix(unit))
end

local function GetUnitTypeDetail(data, unit)
    if data == nil then
        return nil
    end

    local unitInfo = data.UnitType ~= nil and GameInfo.Units[data.UnitType] or nil
    if unitInfo == nil or unitInfo.Name == nil then
        return nil
    end

    local unitTypeName = Locale.Lookup(unitInfo.Name)
    local unitName = unit ~= nil and Locale.Lookup(unit:GetName()) or Locale.Lookup(data.Name or unitInfo.Name)

    if unitName ~= unitTypeName then
        return Locale.Lookup("LOC_UNIT_UNIT_TYPE_NAME_SUFFIX", unitTypeName)
    end

    return nil
end

local function GetUnitInfoLifespan(data)
    if data == nil or data.Lifespan == nil or data.Lifespan < 0 then
        return nil
    end

    return Locale.Lookup("LOC_HUD_UNIT_PANEL_LIFESPAN") .. ", " .. tostring(data.Lifespan)
end

local function GetUnitInfoHealth(data)
    if data == nil or data.MaxDamage == nil or data.MaxDamage <= 0 then
        return nil
    end

    return JoinUnitInfo({
        Locale.Lookup("LOC_HUD_UNIT_PANEL_HEALTH_TOOLTIP", data.MaxDamage - data.Damage, data.MaxDamage),
        GetUnitInfoLifespan(data),
    }, ", ")
end

local function GetUnitInfoMovement(data)
    if data == nil then
        return nil
    end

    return {
        Locale.Lookup("LOC_CAI_UNIT_MOVES", data.MovementMoves or data.Moves or 0, data.MaxMoves),
    }
end

local function IsSelectedUnit(unit)
    local selectedUnit = GetSelectedUnit()
    return selectedUnit ~= nil
        and unit ~= nil
        and selectedUnit:GetOwner() == unit:GetOwner()
        and selectedUnit:GetID() == unit:GetID()
end

local function GetUnitInfoStats(data)
    if data == nil then
        return nil
    end

    local results = {}
    if data.IsSpy then
        return results
    end

    if data.IsTradeUnit then
        AppendUnitInfo(results, data.TradeRouteName)
        AppendUnitInfo(results,
            Locale.Lookup("LOC_HUD_UNIT_PANEL_LAND_ROUTE_RANGE") .. ", " .. tostring(data.TradeLandRange or 0))
        AppendUnitInfo(results,
            Locale.Lookup("LOC_HUD_UNIT_PANEL_SEA_ROUTE_RANGE") .. ", " .. tostring(data.TradeSeaRange or 0))
        return results
    end

    AppendUnitInfo(results,
        (data.Combat or 0) > 0 and Locale.Lookup("LOC_HUD_UNIT_PANEL_STRENGTH") .. ", " .. tostring(data.Combat) or nil)
    AppendUnitInfo(results,
        (data.RangedCombat or 0) > 0 and
        Locale.Lookup("LOC_HUD_UNIT_PANEL_RANGED_STRENGTH") .. ", " .. tostring(data.RangedCombat) or nil)
    AppendUnitInfo(results,
        (data.BombardCombat or 0) > 0 and
        Locale.Lookup("LOC_HUD_UNIT_PANEL_BOMBARD_STRENGTH") .. ", " .. tostring(data.BombardCombat) or nil)
    AppendUnitInfo(results,
        (data.ReligiousStrength or 0) > 0 and
        Locale.Lookup("LOC_HUD_UNIT_PANEL_RELIGIOUS_STRENGTH") .. ", " .. tostring(data.ReligiousStrength) or nil)
    AppendUnitInfo(results,
        (data.AntiAirCombat or 0) > 0 and
        Locale.Lookup("LOC_HUD_UNIT_PANEL_ANTI_AIR_STRENGTH") .. ", " .. tostring(data.AntiAirCombat) or nil)
    AppendUnitInfo(results,
        (data.Range or 0) > 0 and Locale.Lookup("LOC_HUD_UNIT_PANEL_ATTACK_RANGE") .. ", " .. tostring(data.Range) or nil)

    return results
end

local function GetParkCharges(unit)
    if unit == nil then
        return nil
    end

    local unitInfo = GameInfo.Units[unit:GetUnitType()]
    if unitInfo == nil or (unitInfo.ParkCharges or 0) <= 0 then
        return nil
    end

    return unit:GetParkCharges()
end

local function GetUnitInfoCharges(data, unit)
    if data == nil then
        return nil
    end

    local results = {}
    AppendUnitInfo(results,
        (data.BuildCharges or 0) > 0 and
        Locale.Lookup("LOC_HUD_UNIT_PANEL_BUILDS") .. ", " .. tostring(data.BuildCharges) or nil)
    AppendUnitInfo(results,
        (data.DisasterCharges or 0) > 0 and
        Locale.Lookup("LOC_HUD_UNIT_PANEL_CHARGES") .. ", " .. tostring(data.DisasterCharges) or nil)
    AppendUnitInfo(results,
        (data.SpreadCharges or 0) > 0 and
        Locale.Lookup("LOC_HUD_UNIT_PANEL_SPREADS") .. ", " .. tostring(data.SpreadCharges) or nil)
    AppendUnitInfo(results,
        (data.HealCharges or 0) > 0 and Locale.Lookup("LOC_HUD_UNIT_PANEL_HEALS") .. ", " .. tostring(data.HealCharges) or
        nil)
    AppendUnitInfo(results,
        (data.ActionCharges or 0) > 0 and
        Locale.Lookup("LOC_HUD_UNIT_PANEL_CHARGES") .. ", " .. tostring(data.ActionCharges) or nil)
    AppendUnitInfo(results,
        (data.GreatPersonActionCharges or 0) > 0 and
        Locale.Lookup("LOC_HUD_UNIT_PANEL_GREAT_PERSON_ACTIONS") .. ", " .. tostring(data.GreatPersonActionCharges) or
        nil)

    local parkCharges = GetParkCharges(unit)
    AppendUnitInfo(results,
        parkCharges ~= nil and parkCharges > 0 and
        Locale.Lookup("LOC_HUD_UNIT_PANEL_PARK_CHARGES") .. ", " .. tostring(parkCharges) or nil)

    return results
end

local function GetSpyOperationDescription(data)
    if data == nil or not data.IsSpy or data.SpyOperation == nil or data.SpyOperation == -1 then
        return nil
    end

    local operationInfo = GameInfo.UnitOperations[data.SpyOperation]
    if operationInfo == nil or operationInfo.Description == nil then
        return nil
    end

    return Locale.Lookup(operationInfo.Description)
end

local function GetTradeStatusText(unit)
    if Controls == nil or Controls.TradeUnitStatusLabel == nil or Controls.TradeUnitStatusLabel.GetText == nil then
        return nil
    end

    local selectedUnit = GetSelectedUnit()
    if selectedUnit == nil or unit == nil then
        return nil
    end
    if selectedUnit:GetOwner() ~= unit:GetOwner() or selectedUnit:GetID() ~= unit:GetID() then
        return nil
    end

    local text = Controls.TradeUnitStatusLabel:GetText()
    if text == nil or text == "" then
        return nil
    end

    return text
end

local function GetTradeYieldTexts(unit)
    if not IsSelectedUnit(unit)
        or Controls == nil
        or Controls.TradeYieldGrid == nil
        or Controls.TradeYieldGrid.IsHidden == nil
        or Controls.TradeYieldGrid:IsHidden()
        or Controls.TradeResourceList == nil
        or Controls.TradeResourceList.GetChildren == nil then
        return nil
    end

    local function collectTexts(control, results)
        if control == nil or (control.IsHidden ~= nil and control:IsHidden()) then
            return
        end

        local text = GetControlText(control)
        if text ~= nil and text ~= "" then
            table.insert(results, text)
        end

        local children = control.GetChildren ~= nil and control:GetChildren() or nil
        if children ~= nil then
            for _, child in ipairs(children) do
                collectTexts(child, results)
            end
        end
    end

    local results = {}
    for _, child in ipairs(Controls.TradeResourceList:GetChildren() or {}) do
        local entryParts = {}
        collectTexts(child, entryParts)
        if #entryParts > 0 then
            AppendUnitInfo(results, JoinUnitInfo(entryParts, " "))
        end
    end

    return #results > 0 and results or nil
end

local function IsBuilderTypeUnit(data, unit)
    if unit == nil then
        return false
    end

    local unitInfo = GameInfo.Units[unit:GetUnitType()]
    if unitInfo ~= nil and (unitInfo.BuildCharges or 0) > 0 then
        return true
    end

    return data ~= nil and (data.BuildCharges or 0) > 0
end

local function GetRecommendedBuilderActionText(data, unit)
    if not IsSelectedUnit(unit)
        or not IsBuilderTypeUnit(data, unit)
        or Controls == nil
        or Controls.RecommendedActionButton == nil
        or Controls.RecommendedActionButton.IsHidden == nil
        or Controls.RecommendedActionButton:IsHidden() then
        return nil
    end

    local action = GetControlTooltip(Controls.RecommendedActionButton)
    if action == nil or action == "" then
        return nil
    end

    return action ~= "" and action or nil
end

local function GetUpgradeAction(data)
    for _, action in ipairs(GetUnitActionEntries(data)) do
        if action ~= nil and action.userTag == upgradeActionHash then
            return action
        end
    end

    return nil
end

local function GetUpgradeHintText(data)
    local upgradeAction = GetUpgradeAction(data)
    if upgradeAction == nil then
        return nil
    end

    local tooltip = GetUnitActionTooltip(upgradeAction)
    if tooltip ~= nil and tooltip ~= "" then
        return tooltip
    end

    return GetUnitActionLabel(upgradeAction)
end

local function GetUnitInfoActivity(data, unit)
    if data == nil or unit == nil then
        return nil
    end

    local results = {}

    local activityType = UnitManager.GetActivityType(unit)
    if activityType == ActivityTypes.ACTIVITY_SLEEP then
        AppendUnitInfo(results, Locale.Lookup("LOC_CAI_UNIT_ACTIVITY_SLEEP"))
    elseif activityType == ActivityTypes.ACTIVITY_HOLD then
        AppendUnitInfo(results, Locale.Lookup("LOC_CAI_UNIT_ACTIVITY_SKIP"))
    elseif activityType ~= ActivityTypes.ACTIVITY_AWAKE and unit:GetFortifyTurns() > 0 then
        AppendUnitInfo(results, Locale.Lookup("LOC_CAI_UNIT_ACTIVITY_FORTIFIED"))
    elseif activityType == ActivityTypes.ACTIVITY_OPERATION and not data.IsSpy and not data.IsTradeUnit then
        AppendUnitInfo(results, Locale.Lookup("LOC_CAI_UNIT_ACTIVITY_OPERATION"))
    end

    if unit:IsReadyToMove() then
        AppendUnitInfo(results, Locale.Lookup("LOC_CAI_UNIT_ACTIVITY_READY"))
    else
        AppendUnitInfo(results, Locale.Lookup("LOC_CAI_UNIT_ACTIVITY_NOT_READY"))
    end

    return results
end

local function GetUnitInfoNextWaypoint(unit)
    if unit == nil or info == nil or info.GetNextUnitWaypoint == nil then
        return nil
    end

    local waypointPlotId = info:GetNextUnitWaypoint()
    if waypointPlotId == nil or waypointPlotId == false or not Map.IsPlot(waypointPlotId) then
        return nil
    end

    local waypointPlot = Map.GetPlotByIndex(waypointPlotId)
    if waypointPlot == nil then
        return nil
    end

    local direction = HexCoordUtils.directionString(unit:GetX(), unit:GetY(), waypointPlot:GetX(), waypointPlot:GetY())
    if direction == nil or direction == "" then
        direction = Locale.Lookup("LOC_CAI_HERE")
    end

    return Locale.Lookup("LOC_CAI_UNIT_NEXT_WAYPOINT", direction)
end

local function GetCachedQueuedPathPlotIds(entries)
    local plotIds = {}
    for _, entry in ipairs(entries or {}) do
        local plotId = entry ~= nil and entry.PlotId or nil
        if plotId ~= nil and plotId ~= false and Map.IsPlot(plotId) then
            plotIds[#plotIds + 1] = plotId
        end
    end
    return plotIds
end

local function CachedPlotIdsToPathNodes(plotIds, startIndex, endIndex)
    local nodes = {}
    if plotIds == nil then
        return nodes
    end

    startIndex = startIndex or 1
    endIndex = endIndex or #plotIds
    for i = startIndex, endIndex do
        local plot = Map.GetPlotByIndex(plotIds[i])
        if plot ~= nil then
            nodes[#nodes + 1] = { x = plot:GetX(), y = plot:GetY() }
        end
    end

    return nodes
end

local function GetUnitActionFailureReasonCount(action)
    if action == nil or action.helpString == nil or action.helpString == "" then
        return 0
    end

    local count = 0
    local startIndex = 1
    while true do
        local matchStart, matchEnd = string.find(action.helpString, "%[COLOR:Red%]", startIndex)
        if matchStart == nil then
            break
        end

        count = count + 1
        startIndex = matchEnd + 1
    end

    return count
end

local function ActionHasFailureReason(action)
    return GetUnitActionFailureReasonCount(action) > 0
end

local function ShouldHideDisabledBuildAction(action)
    return action ~= nil and action.Disabled == true and not ActionHasFailureReason(action)
end

local function FilterBuildActionsForDisplay(data)
    if data == nil or data.Actions == nil or data.Actions["BUILD"] == nil then
        return
    end

    local filteredActions = {}
    for _, action in ipairs(data.Actions["BUILD"]) do
        if not ShouldHideDisabledBuildAction(action) then
            table.insert(filteredActions, action)
        end
    end

    data.Actions["BUILD"] = filteredActions
end

local function BuildQueuedPathSegmentedText(entries, plotIds, endIndex)
    if entries == nil or plotIds == nil then
        return nil
    end

    endIndex = math.min(endIndex or #plotIds, #plotIds, #entries)
    if endIndex < 2 then
        return nil
    end

    local segments = {}
    local segmentStart = 1
    for i = 2, endIndex do
        local previousEntry = entries[i - 1]
        if previousEntry ~= nil and previousEntry.IsWaypoint then
            if segmentStart < i - 1 then
                local segmentNodes = CachedPlotIdsToPathNodes(plotIds, segmentStart, i - 1)
                local segmentText = HexCoordUtils.stepListFromPath(segmentNodes)
                if segmentText ~= "" then
                    segments[#segments + 1] = segmentText
                end
            end
            segmentStart = i - 1
        end
    end

    local finalNodes = CachedPlotIdsToPathNodes(plotIds, segmentStart, endIndex)
    local finalText = HexCoordUtils.stepListFromPath(finalNodes)
    if finalText ~= "" then
        segments[#segments + 1] = finalText
    end

    local text = HexCoordUtils.joinStepSegments(segments)
    if text == "" then
        return nil
    end

    return text
end

local function GetCachedQueuedPathVisibleText(entries, plotIds)
    if entries == nil or plotIds == nil or #plotIds < 2 then
        return nil, false, false
    end

    local entersFog = false
    local entersUnrevealed = false
    local revealedEndIndex = #plotIds
    local visibility = PlayersVisibility[Game.GetLocalPlayer()]
    if visibility ~= nil then
        for i, plotId in ipairs(plotIds) do
            if not visibility:IsRevealed(plotId) then
                entersUnrevealed = true
                revealedEndIndex = math.max(1, i - 1)
                break
            elseif not visibility:IsVisible(plotId) then
                entersFog = true
            end
        end
    end

    local steps = nil
    if revealedEndIndex >= 2 then
        steps = BuildQueuedPathSegmentedText(entries, plotIds, revealedEndIndex)
    end

    return steps, entersFog, entersUnrevealed
end

local function FormatCachedQueuedPathArrivalTurn(arrivalTurn)
    arrivalTurn = tonumber(arrivalTurn) or 1
    if arrivalTurn <= 1 then
        return Locale.Lookup("LOC_CAI_MOVEMENT_THIS_TURN")
    end
    return Locale.Lookup("LOC_CAI_MOVEMENT_TURNS", arrivalTurn)
end

local function GetQueuedPathInfo()
    if info == nil or info.GetQueuedPath == nil then
        return nil
    end

    local entries = info:GetQueuedPath()
    if entries == nil or #entries < 2 then
        return nil
    end

    return {
        Entries = entries,
        PlotIds = GetCachedQueuedPathPlotIds(entries),
        ArrivalTurn = info.GetQueuedPathArrivalTurn ~= nil and info:GetQueuedPathArrivalTurn() or nil,
    }
end

local function GetUnitInfoQueuedPath(unit)
    local queuedPath = GetQueuedPathInfo()
    if queuedPath == nil then
        return nil
    end

    local results = {}
    AppendUnitInfo(results, Locale.Lookup("LOC_CAI_MOVEMENT_QUEUED"))
    AppendUnitInfo(results, FormatCachedQueuedPathArrivalTurn(queuedPath.ArrivalTurn))

    local steps, entersFog, entersUnrevealed = GetCachedQueuedPathVisibleText(queuedPath.Entries, queuedPath.PlotIds)
    if entersUnrevealed then
        AppendUnitInfo(results, Locale.Lookup("LOC_CAI_MOVEMENT_PATH_UNEXPLORED"))
    elseif entersFog then
        AppendUnitInfo(results, Locale.Lookup("LOC_CAI_MOVEMENT_PATH_FOG"))
    end

    if steps ~= nil then
        AppendUnitInfo(results, Locale.Lookup("LOC_CAI_MOVEMENT_PATH_STEPS", steps))
    end

    if entersUnrevealed then
        AppendUnitInfo(results, Locale.Lookup("LOC_CAI_MOVEMENT_THEN_UNEXPLORED"))
    end

    return #results > 0 and results or nil
end

local function HasPromoteActionInData(data)
    if data == nil or data.Actions == nil then
        return false
    end

    for categoryName, categoryTable in pairs(data.Actions) do
        if categoryName ~= "displayOrder" and type(categoryTable) == "table" then
            for _, action in ipairs(categoryTable) do
                if action ~= nil and action.userTag == promoteActionHash and not action.Disabled then
                    return true
                end
            end
        end
    end

    return false
end

local function GetAvailablePromotionChoices(unit)
    if unit == nil then
        return nil
    end

    local canStart, results = UnitManager.CanStartCommand(unit, UnitCommandTypes.PROMOTE, true, true)
    if not canStart or results == nil then
        return nil
    end

    local promotions = results[UnitCommandResults.PROMOTIONS]
    if promotions ~= nil and #promotions > 0 then
        return promotions
    end

    return nil
end

local function CanUnitPromoteNow(data, unit)
    if HasPromoteActionInData(data) then
        return true
    end

    return GetAvailablePromotionChoices(unit) ~= nil
end

local function GetUnitInfoPromotions(data, unit)
    if data == nil then
        return nil
    end

    local results = {
        Locale.Lookup("LOC_HUD_UNIT_PANEL_LEVEL_ABBREVIATION") .. " " .. tostring(data.UnitLevel),
    }

    if (data.MaxExperience or 0) > 0 then
        AppendUnitInfo(results,
            Locale.Lookup("LOC_HUD_UNIT_PANEL_XP_TT", data.UnitExperience or 0, data.MaxExperience,
                (data.UnitLevel or 0) + 1))
    end

    if data.CurrentPromotions ~= nil and #data.CurrentPromotions > 0 then
        for _, promotion in ipairs(data.CurrentPromotions) do
            local name = Locale.Lookup(promotion.Name)
            local desc = Locale.Lookup(promotion.Desc)
            if desc ~= nil and desc ~= "" then
                AppendUnitInfo(results, Locale.Lookup("LOC_CAI_UNIT_PROMOTION_NAME_DESC", name, desc))
            else
                AppendUnitInfo(results, name)
            end
        end
    end

    if CanUnitPromoteNow(data, unit) then
        AppendUnitInfo(results, Locale.Lookup("LOC_HUD_UNIT_CHOOSE_PROMOTION_TEXT"))
    end

    return results
end

local function GetUnitInfoAbilities(data)
    if data == nil or data.Ability == nil or #data.Ability == 0 then
        return nil
    end

    local results = {}
    for idx, ability in ipairs(data.Ability) do
        if idx > UNIT_ABILITY_INFO_LIMIT then
            break
        end

        local abilityText = GetUnitAbilityDescription(ability)
        if abilityText ~= nil and abilityText ~= "" then
            AppendUnitInfo(results, abilityText)
        end
    end

    local remainingCount = #data.Ability - UNIT_ABILITY_INFO_LIMIT
    if remainingCount > 0 then
        AppendUnitInfo(results, Locale.Lookup("LOC_CAI_UNIT_MORE_ABILITIES", remainingCount))
    end

    return results
end

local function GetUnitInfoSpecialState(data)
    if data == nil then
        return nil
    end

    local results = {}

    return #results > 0 and results or nil
end

local function GetUnitInfoSpecialInfo(data, unit)
    if data == nil or unit == nil then
        return nil
    end

    local results = {}

    if data.GreatPersonPassiveText ~= nil and data.GreatPersonPassiveText ~= "" then
        AppendUnitInfo(results,
            Locale.Lookup("LOC_HUD_UNIT_PANEL_GREAT_PERSON_PASSIVE_ABILITY_TOOLTIP", data.GreatPersonPassiveName,
                data.GreatPersonPassiveText))
    end

    if data.IsSpy then
        local operationDesc = GetSpyOperationDescription(data)
        if operationDesc ~= nil then
            AppendUnitInfo(results, Locale.Lookup("LOC_CAI_UNIT_ACTIVITY_SPY_MISSION", operationDesc))
            AppendUnitInfo(results, data.SpyTargetCityName)
            AppendUnitInfo(results,
                (data.SpyRemainingTurns or 0) > 0
                and Locale.Lookup("LOC_UNITPANEL_ESPIONAGE_MORE_TURNS", data.SpyRemainingTurns)
                or nil)
        else
            AppendUnitInfo(results, Locale.Lookup("LOC_CAI_UNIT_ACTIVITY_SPY_IDLE"))
        end
    elseif data.IsTradeUnit then
        if data.TradeRouteName ~= nil and data.TradeRouteName ~= "" then
            AppendUnitInfo(results, Locale.Lookup("LOC_CAI_UNIT_ACTIVITY_TRADE_ROUTE", data.TradeRouteName))
        else
            AppendUnitInfo(results, GetTradeStatusText(unit) or Locale.Lookup("LOC_CAI_UNIT_ACTIVITY_TRADE_IDLE"))
        end

        local tradeYieldTexts = GetTradeYieldTexts(unit)
        if tradeYieldTexts ~= nil then
            for _, text in ipairs(tradeYieldTexts) do
                AppendUnitInfo(results, text)
            end
        end
    end

    if data.IsRockbandUnit then
        AppendUnitInfo(results,
            (data.RockBandLevel or -1) >= 0 and
            Locale.Lookup("LOC_HUD_UNIT_PANEL_ROCK_BAND_LEVEL") .. ", " .. tostring(data.RockBandLevel) or nil)
        AppendUnitInfo(results,
            (data.AlbumSales or 0) > 0 and
            Locale.Lookup("LOC_HUD_UNIT_PANEL_ROCK_BAND_ALBUM_SALES") .. ", " .. tostring(data.AlbumSales) or nil)
    end

    local hostedAircraftData = GetHostedAircraftData(unit)
    if hostedAircraftData ~= nil then
        AppendUnitInfo(results,
            Locale.Lookup("LOC_CAI_UNIT_CARRIER_AIRCRAFT_CAPACITY", hostedAircraftData.CurrentCount,
                hostedAircraftData.MaxSlots))

        local hostedAircraftNames = GetHostedAircraftUnitNames(unit)
        if hostedAircraftNames ~= nil and #hostedAircraftNames > 0 then
            AppendUnitInfo(results,
                Locale.Lookup("LOC_CAI_UNIT_CARRIER_STATIONED_AIRCRAFT", JoinUnitInfo(hostedAircraftNames, ", ")))
        end
    end

    return #results > 0 and results or nil
end

GetControlText = function(control)
    if control ~= nil and control.GetText ~= nil then
        local text = control:GetText()
        if text ~= nil and text ~= "" then
            return text
        end
    end

    return nil
end

GetControlTooltip = function(control)
    if control ~= nil and control.GetToolTipString ~= nil then
        local tooltip = control:GetToolTipString()
        if tooltip ~= nil and tooltip ~= "" then
            return tooltip
        end
    end

    return nil
end

local function GetControlChildren(control)
    if control ~= nil and control.GetChildren ~= nil then
        return control:GetChildren() or {}
    end

    return {}
end

local function CollectControlTextsRecursive(control, results)
    if control == nil then
        return
    end

    if control.IsHidden == nil or not control:IsHidden() then
        local text = GetControlText(control)
        if text ~= nil and text ~= "" then
            table.insert(results, text)
        end

        for _, child in ipairs(GetControlChildren(control)) do
            CollectControlTextsRecursive(child, results)
        end
    end
end

local function AppendStackTexts(results, stack)
    if stack == nil or (stack.IsHidden ~= nil and stack:IsHidden()) then
        return
    end

    local stackTexts = {}
    for _, child in ipairs(GetControlChildren(stack)) do
        CollectControlTextsRecursive(child, stackTexts)
    end

    for _, text in ipairs(stackTexts) do
        AppendUnitInfo(results, text)
    end
end

local function BuildLabeledText(labelTag, text)
    if text == nil or text == "" then
        return nil
    end

    return Locale.Lookup(labelTag, text)
end

local function GetSubjectCombatStatLabel()
    local combatType = GetCombatPreviewResults()[CombatResultParameters.COMBAT_TYPE]
    if combatType == CombatTypes.RANGED then
        return Locale.Lookup("LOC_HUD_UNIT_PANEL_RANGED_STRENGTH")
    elseif combatType == CombatTypes.BOMBARD then
        return Locale.Lookup("LOC_HUD_UNIT_PANEL_BOMBARD_STRENGTH")
    elseif combatType == CombatTypes.AIR then
        return Locale.Lookup("LOC_HUD_UNIT_PANEL_ANTI_AIR_STRENGTH")
    elseif combatType == CombatTypes.RELIGIOUS then
        return Locale.Lookup("LOC_HUD_UNIT_PANEL_RELIGIOUS_STRENGTH")
    end

    return Locale.Lookup("LOC_HUD_UNIT_PANEL_STRENGTH")
end

local function GetTargetCombatStatLabel()
    local combatType = GetCombatPreviewResults()[CombatResultParameters.COMBAT_TYPE]
    if combatType == CombatTypes.RELIGIOUS then
        return Locale.Lookup("LOC_HUD_UNIT_PANEL_RELIGIOUS_STRENGTH")
    end

    return Locale.Lookup("LOC_HUD_UNIT_PANEL_STRENGTH")
end

local function BuildStrengthText(control, statLabel)
    return JoinUnitInfo({ GetControlText(control), statLabel }, " ")
end

local function GetCombatPreviewActorName(control)
    local text = GetControlText(control)
    if text == nil or text == "" then
        return nil
    end

    return text
end

local function GetCombatPreviewSummaryText()
    local attackerName = GetCombatPreviewActorName(Controls.CombatPreviewUnitName)
    local targetName = GetCombatPreviewActorName(Controls.TargetUnitName)
    local assessment = GetControlText(Controls.CombatAssessmentText)
    if attackerName == nil or targetName == nil or assessment == nil or assessment == "" then
        return nil
    end

    return Locale.Lookup("LOC_CAI_COMBAT_PREVIEW_SUMMARY", attackerName, targetName, assessment)
end

local function GetCombatPreviewTargetName()
    return GetCombatPreviewActorName(Controls.TargetUnitName)
end

local function AppendLabeledStrengthText(results, labelTag, control, statLabel)
    AppendUnitInfo(results, BuildLabeledText(labelTag, BuildStrengthText(control, statLabel)))
end

local function AppendLabeledText(results, labelTag, text)
    AppendUnitInfo(results, BuildLabeledText(labelTag, text))
end

local function AppendModifierTexts(results, labelTag, stack)
    local modifierTexts = {}
    AppendStackTexts(modifierTexts, stack)
    if #modifierTexts > 0 then
        AppendLabeledText(results, labelTag, JoinUnitInfo(modifierTexts, ", "))
    end
end

local function GetPreviewDamageText(damage)
    if damage <= 0 then
        return Locale.Lookup("LOC_CAI_COMBAT_PREVIEW_NO_DAMAGE")
    end

    return tostring(damage)
end

local function GetSubjectPreviewDamageText()
    local combatResults = GetCombatPreviewResults()
    return GetPreviewDamageText(combatResults[CombatResultParameters.ATTACKER][CombatResultParameters.DAMAGE_TO])
end

local function GetTargetPreviewDamageText()
    local combatResults = GetCombatPreviewResults()
    local defender = combatResults[CombatResultParameters.DEFENDER]
    local cityDamage = defender[CombatResultParameters.DAMAGE_TO] or 0
    local wallDamage = defender[CombatResultParameters.DEFENSE_DAMAGE_TO] or 0
    local maxWallHitPoints = defender[CombatResultParameters.MAX_DEFENSE_HIT_POINTS] or 0
    local finalWallDamage = defender[CombatResultParameters.FINAL_DEFENSE_DAMAGE_TO] or 0
    local destroysWalls = maxWallHitPoints > 0 and wallDamage > 0 and finalWallDamage >= maxWallHitPoints

    if not Controls.TargetCityHealthMeters:IsHidden() then
        if cityDamage > 0 and wallDamage > 0 then
            return GetPreviewDamageText(cityDamage) .. ", "
                .. Locale.Lookup(destroysWalls and "LOC_CAI_COMBAT_PREVIEW_WALLS_DESTROYED_SUFFIX"
                    or "LOC_CAI_COMBAT_PREVIEW_WALL_DAMAGE_SUFFIX", GetPreviewDamageText(wallDamage))
        end

        if wallDamage > 0 then
            return Locale.Lookup(destroysWalls and "LOC_CAI_COMBAT_PREVIEW_WALLS_DESTROYED_SUFFIX"
                or "LOC_CAI_COMBAT_PREVIEW_WALL_DAMAGE_SUFFIX", GetPreviewDamageText(wallDamage))
        end

        return GetPreviewDamageText(cityDamage)
    end

    return GetPreviewDamageText(cityDamage)
end

local function GetInterceptorPreviewDamageText()
    local combatResults = GetCombatPreviewResults()
    return GetPreviewDamageText(combatResults[CombatResultParameters.INTERCEPTOR][CombatResultParameters.DAMAGE_TO])
end

local function GetLocalPlayerVisibility()
    local localPlayer = Game.GetLocalPlayer()
    if localPlayer == nil or localPlayer == -1 then
        return nil
    end

    return PlayerVisibilityManager.GetPlayerVisibility(localPlayer)
end

local function IsCombatLocationVisibleToLocalPlayer(results)
    local visibility = GetLocalPlayerVisibility()
    local location = results ~= nil and results[CombatResultParameters.LOCATION] or nil
    if visibility == nil or location == nil or location.x == nil or location.y == nil then
        return false
    end

    return visibility:IsVisible(location.x, location.y)
end

local function DoesCombatComponentBelongToLocalPlayer(componentData)
    local localPlayer = Game.GetLocalPlayer()
    if localPlayer == nil or localPlayer == -1 or componentData == nil then
        return false
    end

    local componentId = componentData[CombatResultParameters.ID]
    return componentId ~= nil and componentId.player == localPlayer
end

local function IsCombatVisibleToLocalPlayer(results)
    if results == nil then
        return false
    end

    if DoesCombatComponentBelongToLocalPlayer(results[CombatResultParameters.ATTACKER])
        or DoesCombatComponentBelongToLocalPlayer(results[CombatResultParameters.DEFENDER])
        or DoesCombatComponentBelongToLocalPlayer(results[CombatResultParameters.INTERCEPTOR])
        or DoesCombatComponentBelongToLocalPlayer(results[CombatResultParameters.ANTI_AIR]) then
        return true
    end

    return IsCombatLocationVisibleToLocalPlayer(results)
end

local function IsWMDCombatResult(results)
    if results == nil then
        return false
    end

    local wmdType = results[CombatResultParameters.WMD_TYPE]
    if wmdType ~= nil and wmdType ~= -1 then
        return true
    end

    local wmdStatus = results[CombatResultParameters.WMD_STATUS]
    if wmdStatus ~= nil and wmdStatus ~= WMDStatus.WMD_NONE then
        return true
    end

    return false
end

local function ResolveCombatCityName(playerID, city)
    if city == nil then
        return nil
    end

    local cityName = city:GetName()
    if cityName == nil or cityName == "" then
        return nil
    end

    return Locale.Lookup(cityName)
end

local function ResolveCombatDistrictName(playerID, district)
    if district == nil then
        return nil
    end

    local districtInfo = GameInfo.Districts[district:GetType()]
    local city = district:GetCity()
    if districtInfo ~= nil and districtInfo.CityCenter and city ~= nil then
        return ResolveCombatCityName(playerID, city)
    end

    if districtInfo ~= nil and districtInfo.Name ~= nil and districtInfo.Name ~= "" then
        return Locale.Lookup(districtInfo.Name)
    end

    if city ~= nil then
        return ResolveCombatCityName(playerID, city)
    end

    return nil
end

local function ResolveCombatPlotTargetInfo(location)
    local info = {
        Name = nil,
        HasImprovementOrDistrict = false,
        IsCityCenter = false,
    }

    if location == nil or location.x == nil or location.y == nil then
        return info
    end

    local plot = Map.GetPlot(location.x, location.y)
    if plot == nil or not plot:IsOwned() then
        return info
    end

    local improvementType = plot:GetImprovementType()
    if improvementType ~= -1 then
        local improvementInfo = GameInfo.Improvements[improvementType]
        if improvementInfo ~= nil and improvementInfo.Name ~= nil and improvementInfo.Name ~= "" then
            info.Name = Locale.Lookup(improvementInfo.Name)
            info.HasImprovementOrDistrict = true
            return info
        end
    end

    local districtType = plot:GetDistrictType()
    if districtType ~= -1 then
        local districtInfo = GameInfo.Districts[districtType]
        if districtInfo ~= nil then
            if not districtInfo.CityCenter then
                if districtInfo.Name ~= nil and districtInfo.Name ~= "" then
                    info.Name = Locale.Lookup(districtInfo.Name)
                end
            else
                local city = CityManager.GetCityAt(location.x, location.y)
                if city ~= nil then
                    info.Name = ResolveCombatCityName(city:GetOwner(), city)
                    info.IsCityCenter = true
                end
            end

            info.HasImprovementOrDistrict = true
        end
    end

    return info
end

local function ResolveCombatComponentName(componentData)
    if componentData == nil then
        return nil
    end

    local componentId = componentData[CombatResultParameters.ID]
    if componentId == nil then
        return nil
    end

    if componentId.type == ComponentType.UNIT then
        local unit = UnitManager.GetUnit(componentId.player, componentId.id)
        if unit ~= nil then
            return FormatOwnedUnitDisplayName(unit)
        end
    elseif componentId.type == ComponentType.DISTRICT then
        local player = Players[componentId.player]
        if player ~= nil then
            local district = player:GetDistricts():FindID(componentId.id)
            if district ~= nil then
                return ResolveCombatDistrictName(componentId.player, district)
            end
        end
    elseif componentId.type == ComponentType.CITY then
        local player = Players[componentId.player]
        if player ~= nil and player.GetCities ~= nil then
            local city = player:GetCities():FindID(componentId.id)
            if city ~= nil then
                return ResolveCombatCityName(componentId.player, city)
            end
        end
    end

    return nil
end

local function IsCombatCityTarget(componentData, plotTargetInfo)
    if componentData ~= nil then
        local componentId = componentData[CombatResultParameters.ID]
        if componentId ~= nil then
            if componentId.type == ComponentType.CITY then
                return true
            end

            if componentId.type == ComponentType.DISTRICT then
                local player = Players[componentId.player]
                if player ~= nil then
                    local district = player:GetDistricts():FindID(componentId.id)
                    if district ~= nil then
                        local districtInfo = GameInfo.Districts[district:GetType()]
                        if districtInfo ~= nil and districtInfo.CityCenter then
                            return true
                        end
                    end
                end
            end
        end
    end

    return plotTargetInfo ~= nil and plotTargetInfo.IsCityCenter or false
end

local function ResolveCombatSupportUnitName(componentData)
    if componentData == nil then
        return nil
    end

    local componentId = componentData[CombatResultParameters.ID]
    if componentId == nil or componentId.type ~= ComponentType.UNIT then
        return nil
    end

    local unit = UnitManager.GetUnit(componentId.player, componentId.id)
    if unit == nil then
        return nil
    end

    return FormatOwnedUnitDisplayName(unit)
end

local function AreCombatComponentIdsEqual(leftData, rightData)
    local leftId = leftData ~= nil and leftData[CombatResultParameters.ID] or nil
    local rightId = rightData ~= nil and rightData[CombatResultParameters.ID] or nil
    if leftId == nil or rightId == nil then
        return false
    end

    return leftId.player == rightId.player
        and leftId.id == rightId.id
        and leftId.type == rightId.type
end

local function GetCombatDamageValue(componentData)
    if componentData == nil then
        return 0
    end

    return componentData[CombatResultParameters.DAMAGE_TO] or 0
end

local function GetCombatFinalDamageValue(componentData)
    if componentData == nil then
        return 0
    end

    return componentData[CombatResultParameters.FINAL_DAMAGE_TO] or 0
end

local function GetCombatMaxHitPoints(componentData)
    if componentData == nil then
        return 0
    end

    return componentData[CombatResultParameters.MAX_HIT_POINTS] or 0
end

local function IsCombatComponentKilled(componentData)
    local maxHitPoints = GetCombatMaxHitPoints(componentData)
    return maxHitPoints > 0 and GetCombatFinalDamageValue(componentData) >= maxHitPoints
end

local function GetCombatWallDamageValue(componentData)
    if componentData == nil then
        return 0
    end

    return componentData[CombatResultParameters.DEFENSE_DAMAGE_TO] or 0
end

local function ShouldSpeakCombatWallDamage(componentData)
    if componentData == nil then
        return false
    end

    local maxWallHitPoints = componentData[CombatResultParameters.MAX_DEFENSE_HIT_POINTS] or 0
    if maxWallHitPoints <= 0 then
        return false
    end

    local finalWallDamage = componentData[CombatResultParameters.FINAL_DEFENSE_DAMAGE_TO] or 0
    local wallDamage = componentData[CombatResultParameters.DEFENSE_DAMAGE_TO] or 0
    local priorWallDamage = finalWallDamage - wallDamage
    return priorWallDamage < maxWallHitPoints
end

local function DidCombatWallsGetDestroyed(componentData)
    if componentData == nil then
        return false
    end

    local maxWallHitPoints = componentData[CombatResultParameters.MAX_DEFENSE_HIT_POINTS] or 0
    if maxWallHitPoints <= 0 then
        return false
    end

    if not ShouldSpeakCombatWallDamage(componentData) then
        return false
    end

    local finalWallDamage = componentData[CombatResultParameters.FINAL_DEFENSE_DAMAGE_TO] or 0
    return finalWallDamage >= maxWallHitPoints
end

local function AppendCombatResultClause(results, value)
    if value ~= nil and value ~= "" then
        table.insert(results, value)
    end
end

local function BuildCombatDamageClause(name, damage)
    if name == nil or name == "" then
        return nil
    end

    if damage > 0 then
        return Locale.Lookup("LOC_CAI_COMBAT_RESULT_TOOK_DAMAGE", name, damage)
    end

    return Locale.Lookup("LOC_CAI_COMBAT_RESULT_UNHARMED", name)
end

local function BuildCombatWallDamageClause(name, damage)
    if name == nil or name == "" or damage <= 0 then
        return nil
    end

    return Locale.Lookup("LOC_CAI_COMBAT_RESULT_WALLS_TOOK_DAMAGE", name, damage)
end

local function BuildCombatSupportClause(name, damage, withDamageTag, withoutDamageTag)
    if name == nil or name == "" then
        return nil
    end

    if damage ~= nil and damage > 0 then
        return Locale.Lookup(withDamageTag, name, damage)
    end

    return Locale.Lookup(withoutDamageTag, name)
end

local function BuildCombatOutcomeClause(name, locTag)
    if name == nil or name == "" then
        return nil
    end

    return Locale.Lookup(locTag, name)
end

local function BuildCombatResultIntroClause(attackerName, defenderName)
    if attackerName == nil or attackerName == "" or defenderName == nil or defenderName == "" then
        return nil
    end

    local text = Locale.Lookup("LOC_CAI_COMBAT_PREVIEW_SUMMARY", attackerName, defenderName, "")
    if text == nil or text == "" then
        return nil
    end

    text = string.gsub(text, ":%s*%.$", ".")
    text = string.gsub(text, "%s+", " ")
    text = string.gsub(text, "^%s*(.-)%s*$", "%1")
    return text
end

local function BuildCombatResultText(results)
    if results == nil or IsWMDCombatResult(results) or not IsCombatVisibleToLocalPlayer(results) then
        return nil
    end

    local location = results[CombatResultParameters.LOCATION]
    local attackerData = results[CombatResultParameters.ATTACKER]
    local defenderData = results[CombatResultParameters.DEFENDER]
    local interceptorData = results[CombatResultParameters.INTERCEPTOR]
    local antiAirData = results[CombatResultParameters.ANTI_AIR]

    local attackerName = ResolveCombatComponentName(attackerData)
    local defenderName = ResolveCombatComponentName(defenderData)
    local plotTargetInfo = nil
    if defenderName == nil then
        plotTargetInfo = ResolveCombatPlotTargetInfo(location)
        defenderName = plotTargetInfo.Name
    end
    local isCityTarget = IsCombatCityTarget(defenderData, plotTargetInfo)

    local parts = {}
    AppendCombatResultClause(parts, BuildCombatResultIntroClause(attackerName, defenderName))
    AppendCombatResultClause(parts, BuildCombatDamageClause(attackerName, GetCombatDamageValue(attackerData)))

    local defenderDamage = GetCombatDamageValue(defenderData)
    local defenderWallDamage = GetCombatWallDamageValue(defenderData)
    local defenderMaxWallHitPoints = defenderData ~= nil and defenderData[CombatResultParameters.MAX_DEFENSE_HIT_POINTS] or
        0
    local defenderFinalWallDamage = defenderData ~= nil and defenderData[CombatResultParameters.FINAL_DEFENSE_DAMAGE_TO] or
        0
    if defenderWallDamage > 0 and ShouldSpeakCombatWallDamage(defenderData) then
        AppendCombatResultClause(parts, BuildCombatWallDamageClause(defenderName, defenderWallDamage))
    end
    if defenderDamage > 0 then
        AppendCombatResultClause(parts, BuildCombatDamageClause(defenderName, defenderDamage))
    elseif defenderName ~= nil and defenderName ~= "" then
        AppendCombatResultClause(parts, BuildCombatDamageClause(defenderName, 0))
    end

    if interceptorData ~= nil and not AreCombatComponentIdsEqual(interceptorData, defenderData) then
        local interceptorName = ResolveCombatSupportUnitName(interceptorData)
        if interceptorName ~= nil and interceptorName ~= "" then
            AppendCombatResultClause(parts,
                BuildCombatSupportClause(interceptorName, GetCombatDamageValue(interceptorData),
                    "LOC_CAI_COMBAT_RESULT_INTERCEPTED_BY_DAMAGE", "LOC_CAI_COMBAT_RESULT_INTERCEPTED_BY"))
        end
    end

    if antiAirData ~= nil and not AreCombatComponentIdsEqual(antiAirData, defenderData) then
        local antiAirName = ResolveCombatSupportUnitName(antiAirData)
        if antiAirName ~= nil and antiAirName ~= "" then
            AppendCombatResultClause(parts,
                BuildCombatSupportClause(antiAirName, GetCombatDamageValue(antiAirData),
                    "LOC_CAI_COMBAT_RESULT_ANTI_AIR_FROM_DAMAGE", "LOC_CAI_COMBAT_RESULT_ANTI_AIR_FROM"))
        end
    end

    if DidCombatWallsGetDestroyed(defenderData) then
        AppendCombatResultClause(parts, BuildCombatOutcomeClause(defenderName, "LOC_CAI_COMBAT_RESULT_WALLS_DESTROYED"))
    end

    if IsCombatComponentKilled(attackerData) then
        AppendCombatResultClause(parts, BuildCombatOutcomeClause(attackerName, "LOC_CAI_COMBAT_RESULT_KILLED"))
    end

    if results[CombatResultParameters.DEFENDER_CAPTURED] or (isCityTarget and IsCombatComponentKilled(defenderData)) then
        AppendCombatResultClause(parts, BuildCombatOutcomeClause(defenderName, "LOC_CAI_COMBAT_RESULT_CAPTURED"))
    elseif IsCombatComponentKilled(defenderData) then
        AppendCombatResultClause(parts, BuildCombatOutcomeClause(defenderName, "LOC_CAI_COMBAT_RESULT_KILLED"))
    end

    local hasImprovementOrDistrict = plotTargetInfo ~= nil and plotTargetInfo.HasImprovementOrDistrict or false
    if hasImprovementOrDistrict then
        if results[CombatResultParameters.LOCATION_PILLAGED] then
            AppendCombatResultClause(parts, Locale.Lookup("LOC_CAI_COMBAT_RESULT_PILLAGED"))
        else
            AppendCombatResultClause(parts, Locale.Lookup("LOC_CAI_COMBAT_RESULT_PILLAGE_FAILED"))
        end
    elseif results[CombatResultParameters.LOCATION_PILLAGED] then
        AppendCombatResultClause(parts, Locale.Lookup("LOC_CAI_COMBAT_RESULT_PILLAGED"))
    end

    if #parts == 0 then
        return nil
    end

    return JoinUnitInfo(parts, ", ")
end

local function GetUnitInfoCombatPreview()
    if Controls == nil or Controls.EnemyUnitPanel == nil or Controls.EnemyUnitPanel:IsHidden() then
        return nil
    end

    local results = {}
    local targetName = GetCombatPreviewTargetName()

    AppendUnitInfo(results, GetCombatPreviewSummaryText())

    if not Controls.InterceptorGrid:IsHidden() then
        AppendUnitInfo(results,
            Locale.Lookup("LOC_CAI_COMBAT_PREVIEW_INTERCEPTED_BY", GetControlText(Controls.InterceptorName)))
    end

    if not Controls.AAGrid:IsHidden() then
        AppendUnitInfo(results, Locale.Lookup("LOC_CAI_COMBAT_PREVIEW_ANTI_AIR_FROM", GetControlText(Controls.AAName)))
    end

    AppendLabeledText(results, "LOC_CAI_COMBAT_PREVIEW_MY_DAMAGE", GetSubjectPreviewDamageText())
    if targetName ~= nil then
        AppendUnitInfo(results, Locale.Lookup("LOC_CAI_COMBAT_PREVIEW_THEIR_DAMAGE_TARGET", targetName,
            GetTargetPreviewDamageText()))
    else
        AppendLabeledText(results, "LOC_CAI_COMBAT_PREVIEW_THEIR_DAMAGE", GetTargetPreviewDamageText())
    end

    if not Controls.InterceptorGrid:IsHidden() then
        AppendLabeledText(results, "LOC_CAI_COMBAT_PREVIEW_INTERCEPTOR_DAMAGE", GetInterceptorPreviewDamageText())
    end

    AppendLabeledStrengthText(results, "LOC_CAI_COMBAT_PREVIEW_MY_STRENGTH",
        Controls.CombatPreview_CombatStatStrength, GetSubjectCombatStatLabel())
    if not Controls.CombatPreview_CombatStatFoeStrength:IsHidden() then
        AppendLabeledStrengthText(results, "LOC_CAI_COMBAT_PREVIEW_THEIR_STRENGTH",
            Controls.CombatPreview_CombatStatFoeStrength, GetTargetCombatStatLabel())
    end

    if not Controls.InterceptorGrid:IsHidden() then
        AppendLabeledStrengthText(results, "LOC_CAI_COMBAT_PREVIEW_INTERCEPTOR_STRENGTH",
            Controls.InterceptorStrength, Locale.Lookup("LOC_HUD_UNIT_PANEL_ANTI_AIR_STRENGTH"))
    end

    if not Controls.AAGrid:IsHidden() then
        AppendLabeledStrengthText(results, "LOC_CAI_COMBAT_PREVIEW_ANTI_AIR_STRENGTH",
            Controls.AAStrength, Locale.Lookup("LOC_HUD_UNIT_PANEL_ANTI_AIR_STRENGTH"))
    end

    AppendModifierTexts(results, "LOC_CAI_COMBAT_PREVIEW_MY_MODIFIERS", Controls.SubjectModifierStack)
    AppendModifierTexts(results, "LOC_CAI_COMBAT_PREVIEW_THEIR_MODIFIERS", Controls.TargetModifierStack)
    AppendModifierTexts(results, "LOC_CAI_COMBAT_PREVIEW_INTERCEPTOR_MODIFIERS", Controls.InterceptorModifierStack)
    AppendModifierTexts(results, "LOC_CAI_COMBAT_PREVIEW_ANTI_AIR_MODIFIERS", Controls.AntiAirModifierStack)

    return #results > 0 and JoinUnitInfo(results, ", ") or nil
end

UnitInfo = {
    Summary = function(data, unit)
        return info:RequestUnitInfo(unit:GetID(), UnitSummaryRequestedKeys, unit:GetOwner())
    end,

    UnitName = function(data, unit)
        return GetUnitInfoName(data, unit)
    end,

    Identity = function(data, unit)
        return JoinUnitInfo({
            GetUnitInfoName(data, unit),
            GetUnitTypeDetail(data, unit),
        }, ", ")
    end,

    Health = function(data, unit)
        return GetUnitInfoHealth(data)
    end,

    Movement = function(data, unit)
        return GetUnitInfoMovement(data)
    end,

    Moves = function(data, unit)
        return GetUnitInfoMovement(data)
    end,

    Activity = function(data, unit)
        return GetUnitInfoActivity(data, unit)
    end,

    NextWaypoint = function(data, unit)
        return GetUnitInfoNextWaypoint(unit)
    end,

    Stats = function(data, unit)
        return GetUnitInfoStats(data)
    end,

    Charges = function(data, unit)
        return GetUnitInfoCharges(data, unit)
    end,

    Promotions = function(data, unit)
        return GetUnitInfoPromotions(data, unit)
    end,

    Abilities = function(data, unit)
        return GetUnitInfoAbilities(data)
    end,

    SpecialInfo = function(data, unit)
        return GetUnitInfoSpecialInfo(data, unit)
    end,

    SpecialState = function(data, unit)
        return GetUnitInfoSpecialState(data)
    end,

    CombatPreview = function(data, unit)
        return GetUnitInfoCombatPreview()
    end,

    QueuedPath = function(data, unit)
        local results = {}
        AppendUnitInfo(results, GetUnitInfoNextWaypoint(unit))
        local queuedPathInfo = GetUnitInfoQueuedPath(unit)
        if type(queuedPathInfo) == "table" then
            for _, value in ipairs(queuedPathInfo) do
                AppendUnitInfo(results, value)
            end
        else
            AppendUnitInfo(results, queuedPathInfo)
        end
        return #results > 0 and results or nil
    end,

    BuilderRecommendation = function(data, unit)
        return GetRecommendedBuilderActionText(data, unit)
    end,

    UpgradeHint = function(data, unit)
        return GetUpgradeHintText(data)
    end,
}

info.UnitInfo = UnitInfo
info.UnitInfoPriority = UnitInfoPriority

GetUnitActionLabel = function(action)
    if action == nil then
        return nil
    end

    if action.userTag == promoteActionHash then
        return Locale.Lookup("LOC_HUD_UNIT_CHOOSE_PROMOTION_TEXT")
    end

    local label = GetFirstUnitInfoLine(action.helpString)
    if label ~= nil and label ~= "" and not string.match(label, "^%[ICON_[^%]]+%]$") then
        return label
    end

    if action.userTag == upgradeActionHash then
        return Locale.Lookup("LOC_UNITCOMMAND_UPGRADE_DESCRIPTION")
    end

    return Locale.Lookup("LOC_OPTIONS_HOTKEY_CATEGORY_UNIT")
end

GetUnitActionTooltip = function(action)
    if action == nil then
        return ""
    end

    local tooltip = action.helpString or ""
    local label = GetUnitActionLabel(action) or ""
    if tooltip == label then
        return ""
    end

    return tooltip
end

local function BuildUnitActionHotkeyIds()
    local hotkeyIds = {}

    for row in GameInfo.UnitOperations() do
        if row.Hash ~= nil and row.HotkeyId ~= nil and row.HotkeyId ~= "" then
            hotkeyIds[row.Hash] = row.HotkeyId
        end
    end

    for row in GameInfo.UnitCommands() do
        if row.Hash ~= nil and row.HotkeyId ~= nil and row.HotkeyId ~= "" then
            hotkeyIds[row.Hash] = row.HotkeyId
        end
    end

    hotkeyIds[deleteActionHash] = "CAIDeleteUnit"
    return hotkeyIds
end

local function GetUnitActionInputActionId(action)
    if action == nil or action.userTag == nil then
        return nil
    end

    if UnitActionHotkeyIds == nil then
        UnitActionHotkeyIds = BuildUnitActionHotkeyIds()
    end

    local hotkeyId = UnitActionHotkeyIds[action.userTag]
    if hotkeyId == nil or hotkeyId == "" then
        return nil
    end

    return Input.GetActionId(hotkeyId)
end

local function GetInputActionBindingText(actionId)
    if actionId == nil then
        return nil
    end

    local bindings = {}
    local g1 = Input.GetGestureDisplayString(actionId, 0)
    local g2 = Input.GetGestureDisplayString(actionId, 1)
    if g1 ~= nil and g1 ~= "" then
        table.insert(bindings, g1)
    end
    if g2 ~= nil and g2 ~= "" then
        table.insert(bindings, g2)
    end

    if #bindings == 0 then
        return nil
    end

    return table.concat(bindings, ", ")
end

local function GetUnitActionLabelWithBinding(action)
    local label = GetUnitActionLabel(action) or ""
    local binding = GetInputActionBindingText(GetUnitActionInputActionId(action))
    if binding == nil then
        return label
    end

    return label .. ": " .. binding
end

GetUnitActionEntries = function(data)
    if data == nil or data.Actions == nil then
        return {}
    end

    local results = {}
    local actionOrder = {}

    if data.Actions.displayOrder ~= nil then
        for _, categoryName in ipairs(data.Actions.displayOrder.primaryArea or {}) do
            table.insert(actionOrder, categoryName)
        end
        for _, categoryName in ipairs(data.Actions.displayOrder.secondaryArea or {}) do
            table.insert(actionOrder, categoryName)
        end
    end

    local seenCategories = {}
    for _, categoryName in ipairs(actionOrder) do
        if not seenCategories[categoryName] then
            seenCategories[categoryName] = true
            local categoryTable = data.Actions[categoryName]
            if categoryTable ~= nil then
                for _, action in ipairs(categoryTable) do
                    table.insert(results, action)
                end
            end
        end
    end

    return results
end

local function AddSyntheticPromoteActionIfNeeded(actions, data)
    if HasPromoteActionInData(data) then
        return
    end

    local promotions = GetAvailablePromotionChoices(GetSelectedUnit())
    if promotions == nil then
        return
    end

    actions[#actions + 1] = {
        Disabled = false,
        helpString = Locale.Lookup("LOC_UNITCOMMAND_PROMOTE_DESCRIPTION"),
        userTag = promoteActionHash,
        CallbackFunc = function()
            ShowPromotionsList(promotions)
        end,
    }
end

local function GetBuildUnitActionEntries(data)
    if data == nil or data.Actions == nil or data.Actions["BUILD"] == nil then
        return {}
    end

    return data.Actions["BUILD"]
end

local function CreateUnitActionMenuItem(currentAction)
    local w = mgr:CreateWidget(mgr:GenerateWidgetId("CAIUnitPanelMenuItem"), "MenuItem", {
        GetLabel = function()
            return GetUnitActionLabelWithBinding(currentAction)
        end,
        GetTooltip = function()
            return GetUnitActionTooltip(currentAction)
        end,
        DisabledPredicate = function()
            return currentAction.Disabled == true
        end,
    })
    w:SetFocusSound("Main_Menu_Mouse_Over")
    w:On("activate", function()
        if currentAction.Disabled then
            local tooltip = GetUnitActionTooltip(currentAction)
            if tooltip ~= "" then
                Speak(tooltip)
            end
            return
        end

        UI.PlaySound("Play_UI_Click")
        if currentAction.Sound ~= nil and currentAction.Sound ~= "" then
            UI.PlaySound(currentAction.Sound)
        end
        currentAction.CallbackFunc(currentAction.CallbackVoid1, currentAction.CallbackVoid2)
        CloseUnitActionList()
    end)
    return w
end

local function CreateBuildImprovementsSubMenu(data)
    local buildActions = GetBuildUnitActionEntries(data)
    if buildActions == nil or #buildActions == 0 then
        return nil
    end

    local submenu = mgr:CreateWidget(UNIT_BUILD_IMPROVEMENTS_SUBMENU_ID, "SubMenu", {
        GetLabel = function()
            return Locale.Lookup("LOC_CAI_UNIT_BUILD_IMPROVEMENTS_SUBMENU")
        end,
        GetTooltip = function()
            return Locale.Lookup("LOC_CAI_UNIT_BUILD_IMPROVEMENTS_SUBMENU_TOOLTIP")
        end,
    })
    submenu:SetFocusSound("Main_Menu_Mouse_Over")
    for _, action in ipairs(buildActions) do
        submenu:AddChild(CreateUnitActionMenuItem(action))
    end

    return submenu
end

CloseSimplePromotionList = function()
    if SimplePromotionList ~= nil then
        mgr:RemoveFromStack(UNIT_SIMPLE_PROMOTION_LIST_ID)
        SimplePromotionList = nil
    end
end

local function ShouldOpenSimplePromotionList()
    if mgr == nil or ContextPtr:IsHidden() then
        return false
    end

    if Controls.PromotionPanel == nil
        or Controls.PromotionPanel.IsHidden == nil
        or Controls.PromotionPanel:IsHidden() then
        return false
    end

    local unit = GetSelectedUnit()
    if unit == nil then
        return false
    end

    local unitInfo = GameInfo.Units[unit:GetUnitType()]
    return unitInfo ~= nil and (unitInfo.NumRandomChoices or 0) > 0
end

local function FindChildById(control, id)
    if control == nil then
        return nil
    end

    if control.GetID ~= nil and control:GetID() == id then
        return control
    end

    for _, child in ipairs(GetControlChildren(control)) do
        local result = FindChildById(child, id)
        if result ~= nil then
            return result
        end
    end

    return nil
end

local function GetSimplePromotionChoiceLabel(row)
    local tier = GetControlText(row.Tier)
    local name = GetControlText(row.Name)

    return JoinUnitInfo({ tier, name }, ", ")
end

local function GetSimplePromotionChoiceTooltip(row)
    return GetControlText(row.Description) or GetControlTooltip(row.Slot) or ""
end

local function CreateSimplePromotionChoice(row)
    if row == nil or row.Slot == nil then
        return nil
    end

    local capturedRow = row
    local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAIUnitSimplePromotionChoice"), "MenuItem", {
        GetLabel = function()
            return GetSimplePromotionChoiceLabel(capturedRow)
        end,
        GetTooltip = function()
            return GetSimplePromotionChoiceTooltip(capturedRow)
        end,
        FocusKey = "simple-promotion:" .. tostring(capturedRow.Index),
    })
    item:SetFocusSound("Main_Menu_Mouse_Over")
    item:On("activate", function()
        CloseSimplePromotionList()
        capturedRow.Slot:DoLeftClick()
    end)
    return item
end

local function GetVanillaSimplePromotionRows()
    local rows = {}
    if Controls.PromotionList == nil then
        return rows
    end

    for index, root in ipairs(GetControlChildren(Controls.PromotionList)) do
        if root.IsHidden == nil or not root:IsHidden() then
            local slot = FindChildById(root, "PromotionSlot")
            if slot ~= nil then
                rows[#rows + 1] = {
                    Index = index,
                    Root = root,
                    Slot = slot,
                    Tier = FindChildById(root, "PromotionTier"),
                    Name = FindChildById(root, "PromotionName"),
                    Description = FindChildById(root, "PromotionDescription"),
                }
            end
        end
    end

    return rows
end

local function OpenSimplePromotionList()
    if not ShouldOpenSimplePromotionList() then
        CloseSimplePromotionList()
        return
    end

    local rows = GetVanillaSimplePromotionRows()
    if #rows == 0 then
        CloseSimplePromotionList()
        return
    end

    CloseSimplePromotionList()

    local list = mgr:CreateWidget(UNIT_SIMPLE_PROMOTION_LIST_ID, "List", {
        GetLabel = function()
            return Locale.Lookup("LOC_HUD_UNIT_CHOOSE_PROMOTION_TEXT")
        end,
    })
    list:AddInputBinding({
        Key = Keys.VK_ESCAPE,
        Description = "LOC_CAI_KB_CLOSE",
        Action = function()
            CloseSimplePromotionList()
            HidePromotionPanel()
            return true
        end,
    })

    for _, row in ipairs(rows) do
        local item = CreateSimplePromotionChoice(row)
        if item ~= nil then
            list:AddChild(item)
        end
    end

    if list.Children ~= nil and #list.Children > 0 then
        SimplePromotionList = list
        mgr:Push(SimplePromotionList, PopupPriority.Low)
    end
end

CloseUnitNamePanel = function()
    if UnitNamePanel ~= nil then
        mgr:RemoveFromStack(UNIT_NAME_PANEL_ID)
        UnitNamePanel = nil
        UnitNameEdit = nil
    end
end

local function ShouldOpenUnitNamePanel()
    if mgr == nil or ContextPtr:IsHidden() then
        return false
    end

    if Controls.VeteranNamePanel == nil
        or Controls.VeteranNamePanel.IsHidden == nil
        or Controls.VeteranNamePanel:IsHidden() then
        return false
    end

    return GetSelectedUnit() ~= nil
end

local function GetVeteranNameFieldText()
    if Controls.VeteranNameField ~= nil and Controls.VeteranNameField.GetText ~= nil then
        return Controls.VeteranNameField:GetText() or ""
    end

    return ""
end

local function SyncUnitNameEditFromVanilla(silent)
    if UnitNameEdit ~= nil then
        UnitNameEdit:SetText(GetVeteranNameFieldText(), silent == true)
    end
end

local function CommitUnitNameToVanilla(text)
    if Controls.VeteranNameField == nil then
        return
    end

    Controls.VeteranNameField:SetText(text or "")
    if OnEditCustomVeteranName ~= nil then
        OnEditCustomVeteranName()
    end
end

local function CommitUnitNameEdit()
    if UnitNameEdit ~= nil then
        UnitNameEdit:Commit()
    end
end

local function ClickConfirmVeteranName()
    if Controls.ConfirmVeteranName ~= nil then
        Controls.ConfirmVeteranName:DoLeftClick()
    end
end

local function CreateUnitNameButton(id, vanillaControl, activate)
    if vanillaControl == nil then
        return nil
    end

    local control = vanillaControl
    local button = mgr:CreateWidget(id, "Button", {
        GetLabel = function()
            return GetControlText(control) or ""
        end,
        GetTooltip = function()
            return GetControlTooltip(control) or ""
        end,
        HiddenPredicate = function()
            return Controls.VeteranNamePanel == nil
                or Controls.VeteranNamePanel:IsHidden()
                or (control.IsHidden ~= nil and control:IsHidden())
        end,
        DisabledPredicate = function()
            return control.IsDisabled ~= nil and control:IsDisabled()
        end,
    })
    button:SetFocusSound("Main_Menu_Mouse_Over")
    button:On("activate", function()
        if control.IsDisabled ~= nil and control:IsDisabled() then
            return
        end

        activate(control)
    end)
    return button
end

local function OpenUnitNamePanel()
    if not ShouldOpenUnitNamePanel() then
        CloseUnitNamePanel()
        return
    end

    CloseUnitNamePanel()

    local panel = mgr:CreateWidget(UNIT_NAME_PANEL_ID, "Panel", {
        GetLabel = function()
            return Locale.Lookup("LOC_UNITNAME_CHOOSE_NAME")
        end,
    })
    panel:AddInputBinding({
        Key = Keys.VK_ESCAPE,
        Description = "LOC_CAI_KB_CLOSE",
        Action = function()
            Controls.VeteranNamingCancelButton:DoLeftClick()
            return true
        end,
    })
    panel:AddInputBinding({
        Key = Keys.VK_RETURN,
        Description = "LOC_CAI_KB_CONFIRM_UNIT_NAME",
        Action = function()
            ClickConfirmVeteranName()
            return true
        end,
    })

    local edit = mgr:CreateWidget(UNIT_NAME_EDIT_ID, "EditBox", {
        GetLabel = function()
            return Locale.Lookup("LOC_UNITNAME_CHOOSE_NAME")
        end,
        HiddenPredicate = function()
            return Controls.VeteranNamePanel == nil
                or Controls.VeteranNamePanel:IsHidden()
                or Controls.VeteranNameField == nil
                or (Controls.VeteranNameField.IsHidden ~= nil and Controls.VeteranNameField:IsHidden())
        end,
    })
    edit:SetAlwaysEdit(true)
    edit:SetHighlightOnEdit(true)
    edit:SetMaxCharacters(48)
    edit:SetText(GetVeteranNameFieldText(), true)
    edit:SetValueSetter(function(_, text)
        CommitUnitNameToVanilla(text)
    end)
    panel:AddChild(edit)

    local randomizeButton = CreateUnitNameButton(
        mgr:GenerateWidgetId("CAIUnitNameRandomize"),
        Controls.RandomNameButton,
        function(control)
            control:DoLeftClick()
            SyncUnitNameEditFromVanilla(true)
            if UnitNameEdit ~= nil then
                UnitNameEdit:Announce({ "value" })
            end
        end
    )
    if randomizeButton ~= nil then
        panel:AddChild(randomizeButton)
    end

    local confirmButton = CreateUnitNameButton(
        mgr:GenerateWidgetId("CAIUnitNameConfirm"),
        Controls.ConfirmVeteranName,
        function(control)
            control:DoLeftClick()
        end
    )
    if confirmButton ~= nil then
        panel:AddChild(confirmButton)
    end

    UnitNamePanel = panel
    UnitNameEdit = edit
    mgr:Push(UnitNamePanel, { priority = PopupPriority.Low, focus = UnitNameEdit })
end

function CloseUnitActionList()
    if UnitActionList ~= nil then
        mgr:RemoveFromStack(UNIT_ACTION_LIST_ID)
        UnitActionList = nil
    end
end

CloseUnitList = function()
    if UnitList ~= nil then
        mgr:RemoveFromStack(UNIT_LIST_ID)
        UnitList = nil
    end
end

local function BuildUnitActionList(data)
    local selectedUnit = GetSelectedUnit()
    local unitName = GetUnitInfoName(data, selectedUnit) or Locale.Lookup("LOC_OPTIONS_HOTKEY_CATEGORY_UNIT")
    local list = mgr:CreateWidget(UNIT_ACTION_LIST_ID, "List", {
        GetLabel = function()
            return Locale.Lookup("LOC_CAI_SELECTION_ACTIONS_FOR", unitName)
        end,
    })

    list:AddInputBinding({
        Key = Keys.VK_ESCAPE,
        Description = "LOC_CAI_KB_CLOSE",
        Action = function()
            CloseUnitActionList()
            return true
        end,
    })

    local buildSubMenu = CreateBuildImprovementsSubMenu(data)
    if buildSubMenu ~= nil then
        list:AddChild(buildSubMenu)
    end

    local actions = GetUnitActionEntries(data)
    AddSyntheticPromoteActionIfNeeded(actions, data)

    for _, action in ipairs(actions) do
        list:AddChild(CreateUnitActionMenuItem(action))
    end

    if data ~= nil and data.Ability ~= nil and #data.Ability > 0 then
        local abilities = mgr:CreateWidget(mgr:GenerateWidgetId("CAIUnitViewAbilities"), "MenuItem", {
            GetLabel = function()
                local label = Locale.Lookup("LOC_CAI_UNIT_VIEW_ABILITIES")
                local binding = GetInputActionBindingText(unitViewAbilitiesAction)
                if binding ~= nil then
                    return label .. ": " .. binding
                end
                return label
            end,
            GetTooltip = function() return Locale.Lookup("LOC_CAI_UNIT_VIEW_ABILITIES_TOOLTIP") end,
        })
        abilities:SetFocusSound("Main_Menu_Mouse_Over")
        abilities:On("activate", function(w, ...)
            UI.PlaySound("Play_UI_Click")
            CloseUnitActionList()
            OnUnitPanelSelectionActionInputTriggered(unitViewAbilitiesAction)
        end)
        list:AddChild(abilities)
    end

    return list
end

local function OpenUnitActionList()
    if mgr == nil or ContextPtr:IsHidden() or GetSelectedUnit() == nil then
        return
    end

    if UnitActionList ~= nil then
        CloseUnitActionList()
    end

    local data = ReadCurrentUnitData()
    FilterBuildActionsForDisplay(data)

    UnitActionList = BuildUnitActionList(data)
    if UnitActionList ~= nil and UnitActionList.Children ~= nil and #UnitActionList.Children > 0 then
        mgr:Push(UnitActionList, PopupPriority.Low)
    else
        UnitActionList = nil
    end
end


local function CreateUnitListItem(unit)
    local data = ReadUnitData ~= nil and ReadUnitData(unit) or nil
    local unitName = GetUnitListName(unit)
    local selectedUnit = GetSelectedUnit()
    local isSelected = selectedUnit ~= nil
        and selectedUnit:GetOwner() == unit:GetOwner()
        and selectedUnit:GetID() == unit:GetID()
    local value = isSelected and Locale.Lookup("LOC_CAI_STATE_SELECTED") or ""
    local tooltip = JoinUnitInfo(GetUnitInfoActivity(data, unit) or {}, ", ")
    local unitID = unit:GetID()

    local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAIUnitListItem"), "TreeItem", {
        FocusKey = UnitFocusKey(unit:GetOwner(), unitID),
        GetLabel = function()
            return unitName
        end,
        GetValue = function()
            return value
        end,
        GetTooltip = function()
            return tooltip
        end,
    })
    item:On("activate", function()
        local resolved = Players[Game.GetLocalPlayer()]:GetUnits():FindID(unitID)
        if resolved == nil then
            return
        end

        CloseUnitList()
        UI.SelectUnit(resolved)
    end)
    BindCivilopediaShortcut(item, function() return unitID end)

    return item
end

local UnitListDomains = {
    { Key = "military", Label = "LOC_CAI_UNIT_DOMAIN_MILITARY" },
    { Key = "naval",    Label = "LOC_CAI_UNIT_DOMAIN_NAVAL" },
    { Key = "air",      Label = "LOC_CAI_UNIT_DOMAIN_AIR" },
    { Key = "support",  Label = "LOC_CAI_UNIT_DOMAIN_SUPPORT" },
    { Key = "civilian", Label = "LOC_CAI_UNIT_DOMAIN_CIVILIAN" },
    { Key = "trade",    Label = "LOC_CAI_UNIT_DOMAIN_TRADE" },
}

local function ClassifyPlayerUnits(player)
    local buckets = {
        military = {}, naval = {}, air = {}, support = {}, civilian = {}, trade = {},
    }

    for _, unit in player:GetUnits():Members() do
        local unitInfo = GameInfo.Units[unit:GetUnitType()]
        if unitInfo.MakeTradeRoute == true then
            table.insert(buckets.trade, unit)
        elseif unit:GetCombat() == 0 and unit:GetRangedCombat() == 0 then
            table.insert(buckets.civilian, unit)
        elseif unitInfo.Domain == "DOMAIN_LAND" then
            table.insert(buckets.military, unit)
        elseif unitInfo.Domain == "DOMAIN_SEA" then
            table.insert(buckets.naval, unit)
        elseif unitInfo.Domain == "DOMAIN_AIR" then
            table.insert(buckets.air, unit)
        else
            table.insert(buckets.support, unit)
        end
    end

    local function sortFunc(a, b)
        return GameInfo.Units[a:GetUnitType()].UnitType < GameInfo.Units[b:GetUnitType()].UnitType
    end
    for _, units in pairs(buckets) do
        table.sort(units, sortFunc)
    end

    return buckets
end

local function BuildUnitList()
    local playerID = Game.GetLocalPlayer()
    if playerID == nil or playerID < 0 then
        return nil
    end

    local player = Players[playerID]
    if player == nil then
        return nil
    end

    local tree = mgr:CreateWidget(UNIT_LIST_ID, "Tree", {
        GetLabel = function()
            return Locale.Lookup("LOC_CAI_UNIT_LIST")
        end,
    })

    tree:AddInputBinding({
        Key = Keys.VK_ESCAPE,
        Description = "LOC_CAI_KB_CLOSE",
        Action = function()
            CloseUnitList()
            return true
        end,
    })

    local buckets = ClassifyPlayerUnits(player)
    local total = 0

    for _, domain in ipairs(UnitListDomains) do
        local units = buckets[domain.Key]
        if #units > 0 then
            local domainNode = mgr:CreateWidget(
                mgr:GenerateWidgetId("CAIUnitListDomain_" .. domain.Key),
                "TreeItem",
                {
                    GetLabel = function()
                        return Locale.Lookup(domain.Label)
                    end,
                }
            )
            for _, unit in ipairs(units) do
                domainNode:AddChild(CreateUnitListItem(unit))
                total = total + 1
            end
            -- Start expanded without triggering Expand()'s speech, since the
            -- push will speak the focused leaf and any expand chatter would
            -- just be interrupted.
            domainNode.IsExpanded = true
            tree:AddChild(domainNode)
        end
    end

    if total == 0 then
        return nil
    end

    return tree
end

local function OpenUnitList()
    if mgr == nil then
        return
    end

    if UnitList ~= nil then
        CloseUnitList()
    end

    UnitList = BuildUnitList()
    if UnitList == nil then
        Speak(Locale.Lookup("LOC_CAI_UNIT_NO_UNITS"))
        return
    end

    local selectedUnit = GetSelectedUnit()
    local focusHint = nil
    if selectedUnit ~= nil and selectedUnit:GetOwner() == Game.GetLocalPlayer() then
        focusHint = UnitFocusKey(selectedUnit:GetOwner(), selectedUnit:GetID())
    end

    mgr:Push(UnitList, { priority = PopupPriority.Low, focus = focusHint })
end

function OnHandleInput(inputStruct)
    if not mgr then return false end
    return mgr:HandleInput(inputStruct)
end

function InitializeUnitInfoActionMap()
    UnitInfoActionMap = {
        [Input.GetActionId("ReadSelectionSummary")] = { "Summary" },
        [Input.GetActionId("ReadSelectionInfo1")] = { "Identity", "Health" },
        [Input.GetActionId("ReadSelectionInfo2")] = { "Movement" },
        [Input.GetActionId("ReadSelectionInfo3")] = { "Activity" },
        [Input.GetActionId("ReadSelectionInfo4")] = { "Charges" },
        [Input.GetActionId("ReadSelectionInfo5")] = { "Promotions" },
        [Input.GetActionId("ReadSelectionInfo6")] = { "Stats" },
        [Input.GetActionId("ReadSelectionInfo7")] = { "Abilities" },
        [Input.GetActionId("ReadSelectionInfo8")] = { "SpecialInfo" },
        [Input.GetActionId("ReadSelectionInfo9")] = { "QueuedPath" },
    }
end

function OnUnitPanelSelectionInfoInputActionTriggered(actionId)
    if ContextPtr:IsHidden() or GetSelectedUnit() == nil then
        return
    end

    local requestedKeys = UnitInfoActionMap[actionId]
    if requestedKeys == nil then
        return
    end

    local results = info:RequestUnitInfo(nil, requestedKeys)
    if results == nil or #results == 0 then
        if #requestedKeys == 1 then
            local fallback = UnitInfoFallbacks[requestedKeys[1]]
            if fallback ~= nil then
                Speak(Locale.Lookup(fallback))
            end
        end
        return
    end

    Speak(table.concat(results, ", "))
end

function OnUnitPanelSelectionActionInputTriggered(actionId)
    if actionId == prevUnitAction then
        UI.SelectPrevUnit()
        UI.PlaySound("Play_UI_Click");
        return
    elseif actionId == nextUnitAction then
        UI.SelectNextUnit()
        UI.PlaySound("Play_UI_Click");
        return
    end
    if actionId == prevReadyUnitAction then
        UI.SelectPrevReadyUnit()
        UI.PlaySound("Play_UI_Click");
        return
    elseif actionId == nextReadyUnitAction then
        UI.SelectNextReadyUnit()
        UI.PlaySound("Play_UI_Click");
        return
    end

    if actionId == selectionActionsAction then
        OpenUnitActionList()
        return
    end

    if actionId == caiDeleteUnitAction then
        if ContextPtr:IsHidden() or GetSelectedUnit() == nil then return end

        UI.PlaySound("Play_UI_Click")
        OnPromptToDeleteUnit()
        return
    end

    if actionId == openUnitListAction then
        OpenUnitList()
        UI.PlaySound("Play_UI_Click");
        return
    end

    if actionId == unitViewAbilitiesAction then
        if ContextPtr:IsHidden() or GetSelectedUnit() == nil then return end

        local data = ReadCurrentUnitData()
        if data == nil or data.Ability == nil or #data.Ability == 0 then
            Speak(Locale.Lookup("LOC_CAI_UNIT_NO_ABILITIES"))
            return
        end
        UI.PlaySound("Play_UI_Click");
        local list = mgr:CreateWidget(UNIT_ABILITIES_LIST_ID, "List", {
            GetLabel = function() return Locale.Lookup("LOC_CAI_UNIT_ABILITIES_LIST") end,
        })
        list:AddInputBinding({
            Key = Keys.VK_ESCAPE,
            Description = "LOC_CAI_KB_CLOSE",
            Action = function()
                mgr:RemoveFromStack(UNIT_ABILITIES_LIST_ID)
                return true
            end
        })

        for _, ability in ipairs(data.Ability) do
            local abilityText = GetUnitAbilityDescription(ability)
            if abilityText ~= nil and abilityText ~= "" then
                local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAIUnitAbilityItem"), "MenuItem", {
                    GetLabel = function() return abilityText end,
                })
                item:SetFocusSound("Main_Menu_Mouse_Over")
                item:On("activate", function()
                    mgr:RemoveFromStack(UNIT_ABILITIES_LIST_ID)
                end)
                list:AddChild(item)
            end
        end

        if list.Children ~= nil and #list.Children > 0 then
            mgr:Push(list, PopupPriority.Low)
        end
    end
end

function OnLoadScreenClose()
    m_IsGameStarted = true
end

function OnCAIUnitSelectionChanged(player, unitId, locationX, locationY, locationZ, isSelected, isEditable)
    if ContextPtr:IsHidden() or not isSelected then
        return
    end
    CloseSimplePromotionList()
    CloseUnitNamePanel()

    local plot = Map.GetPlot(locationX, locationY)
    if plot == nil then
        print("CAI UnitPanel could not resolve selected unit plot: " ..
            tostring(locationX) .. ", " .. tostring(locationY))
        return
    end
    if not m_IsGameStarted then return end
    LuaEvents.CAICursorMoveTo(plot:GetIndex(), "select")
    local focused = mgr:GetFocusedWidget()
    local isInWorld = focused and (focused.Type == "GameView" or focused.Type == "InterfaceMode")
    if isInWorld then
        local results = info:RequestUnitInfo(unitId, { "Summary" }, player)
        if results == nil or #results == 0 then
            return
        end

        Speak(table.concat(results, ", "))
    end
end

View = WrapFunc(View, function(orig, data)
    FilterBuildActionsForDisplay(data)
    return orig(data)
end)

ShowPromotionsList = WrapFunc(ShowPromotionsList, function(orig, promotions)
    orig(promotions)
    OpenSimplePromotionList()
end)

HidePromotionPanel = WrapFunc(HidePromotionPanel, function(orig)
    CloseSimplePromotionList()
    orig()
end)

ShowNameUnitPanel = WrapFunc(ShowNameUnitPanel, function(orig)
    orig()
    OpenUnitNamePanel()
end)

HideNameUnitPanel = WrapFunc(HideNameUnitPanel, function(orig)
    CloseUnitNamePanel()
    orig()
end)

OnConfirmVeteranName = WrapFunc(OnConfirmVeteranName, function(orig)
    CommitUnitNameEdit()
    orig()
end)
Controls.ConfirmVeteranName:RegisterCallback(Mouse.eLClick, OnConfirmVeteranName)

RandomizeName = WrapFunc(RandomizeName, function(orig)
    orig()
    SyncUnitNameEditFromVanilla(true)
end)
Controls.RandomNameButton:RegisterCallback(Mouse.eLClick, RandomizeName)

local function OnCAICursorMoved(state)
    InspectWhatsBelowTheCursor()
end

local function SpeakCurrentCombatPreview()
    local results = GetUnitInfoCombatPreview()
    if results == nil or results == "" then
        Speak(Locale.Lookup("LOC_CAI_UNIT_NO_COMBAT"))
        return
    end

    Speak(results)
end

local function OnCAISpeakCombatPreview()
    SpeakCurrentCombatPreview()
end

local function InspectCombatPreviewAtPlotId(plotId)
    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == nil or localPlayerID == -1 then
        return false
    end

    local playerVisibility = PlayersVisibility[localPlayerID]
    if playerVisibility == nil then
        return false
    end

    local selectedPlayerUnit = UI.GetHeadSelectedUnit()
    if selectedPlayerUnit ~= nil then
        if selectedPlayerUnit:GetCombat() == 0 and selectedPlayerUnit:GetReligiousStrength() == 0 then
            return false
        end
    end

    if plotId == nil or not Map.IsPlot(plotId) then
        OnShowCombat(false)
        return false
    end

    local plot = Map.GetPlotByIndex(plotId)
    if plot == nil then
        OnShowCombat(false)
        return false
    end

    if not playerVisibility:IsVisible(plotId) then
        OnShowCombat(false)
        return false
    end

    m_plotId = plotId
    InspectPlot(plot)
    return true
end

local function OnCAISpeakCombatPreviewForPlot(plotId)
    if not InspectCombatPreviewAtPlotId(plotId) then
        Speak(Locale.Lookup("LOC_CAI_UNIT_NO_COMBAT"))
        return
    end

    SpeakCurrentCombatPreview()
end

local resultStrings = SwapPairs(CombatResultParameters)
local function OnCombatResolved(results)
    local text = BuildCombatResultText(results)
    if text == nil or text == "" then
        return
    end

    LuaEvents.CAIAppendToMessageBuffer(text, "combat")
end

function info:RequestUnitInfo(unitID, requestedKeys, playerID)
    local data, unit = ResolveUnitData(unitID, playerID)
    local results = {}

    if data == nil or unit == nil then
        return results
    end

    requestedKeys = requestedKeys or UnitInfoPriority

    for _, key in ipairs(requestedKeys) do
        local helper = self.UnitInfo[key]
        if helper ~= nil then
            local output = helper(data, unit)
            if type(output) == "table" then
                for _, value in ipairs(output) do
                    AppendUnitInfo(results, value)
                end
            else
                AppendUnitInfo(results, output)
            end
        end
    end

    return results
end

InitializeUnitInfoActionMap()
Events.InputActionTriggered.Add(OnUnitPanelSelectionInfoInputActionTriggered)
Events.InputActionTriggered.Add(OnUnitPanelSelectionActionInputTriggered)
Events.LoadScreenClose.Add(OnLoadScreenClose)
Events.UnitSelectionChanged.Add(OnCAIUnitSelectionChanged)
Events.Combat.Add(OnCombatResolved)
LuaEvents.CAICursorMoved.Add(OnCAICursorMoved)
LuaEvents.CAISpeakCombatPreview.Add(OnCAISpeakCombatPreview)
LuaEvents.CAISpeakCombatPreviewForPlot.Add(OnCAISpeakCombatPreviewForPlot)
ContextPtr:SetInputHandler(OnHandleInput, true)
InstallUIOverrides()
