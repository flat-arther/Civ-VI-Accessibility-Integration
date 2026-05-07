include("caiUtils")
include("interfaceInfoHelpers_CAI")
include("UnitPanel")

local mgr = ExposedMembers.CAI_UIManager
local UNIT_ACTION_LIST_ID = "CAIUnitPanelActionList"
local prevUnitCatAction = Input.GetActionId("PrevUnitSelectionCategory")
local nextUnitCatAction = Input.GetActionId("NextUnitSelectionCategory")
local prevUnitAction = Input.GetActionId("PrevUnitSelection")
local nextUnitAction = Input.GetActionId("NextUnitSelection")
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
--#Category functions
function ChangeUnitSelectionCategory(dir)
    activeCategoryIdx = ((activeCategoryIdx - 1 + dir) % #UnitCategories) + 1
    Speak(Locale.Lookup(UnitCategories[activeCategoryIdx].Name))
end

function ChangeUnitSelection(dir)
    local sel = UnitCategories[activeCategoryIdx]
    if dir == -1 and sel.Prev then
        sel.Prev()
    elseif dir == 1 and sel.Next then
        sel.Next()
    end
end

info = ExposedMembers.CAIInfo or {}
ExposedMembers.CAIInfo = info

UnitInfoPriority = {
    "Summary",
    "Health",
    "Movement",
    "Combat",
    "Charges",
    "Promotions",
    "Formation",
    "Abilities",
    "SpecialState",
    "Actions",
    "QueuedPath",
}

UnitInfoActionMap = {}
UnitInfoFallbacks = {
    Combat       = "LOC_CAI_UNIT_NO_COMBAT",
    Charges      = "LOC_CAI_UNIT_NO_CHARGES",
    Promotions   = "LOC_CAI_UNIT_NO_PROMOTIONS",
    Formation    = "LOC_CAI_UNIT_NOT_IN_FORMATION",
    Abilities    = "LOC_CAI_UNIT_NO_ABILITIES",
    SpecialState = "LOC_CAI_UNIT_NO_SPECIAL_STATE",
    Actions      = "LOC_CAI_UNIT_NO_ACTIONS",
    QueuedPath   = "LOC_CAI_UNIT_NO_QUEUED_PATH",
}
UnitActionList = nil

--# General formatting

function AppendUnitInfo(results, value)
    if value ~= nil and value ~= "" then
        table.insert(results, value)
    end
end

function JoinUnitInfo(parts, separator)
    local results = {}

    for _, part in ipairs(parts) do
        if part ~= nil and part ~= "" then
            table.insert(results, part)
        end
    end

    return table.concat(results, separator or ", ")
end

function GetFirstUnitInfoLine(value)
    if value == nil then
        return nil
    end

    local firstLine = string.match(value, "([^[]*)%[NEWLINE%]")
    if firstLine ~= nil and firstLine ~= "" then
        return firstLine
    end

    return value
end

--# Unit lookup

function GetSelectedUnit()
    return UI.GetHeadSelectedUnit()
end

function ResolveUnit(unitID, playerID)
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

function ResolveUnitData(unitID, playerID)
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

--# Unit info helpers

function GetUnitOwnershipPrefix(unit)
    if unit == nil then
        return nil
    end

    local playerID = unit:GetOwner()
    local playerConfig = PlayerConfigurations[playerID]
    if playerConfig ~= nil then
        local civName = playerConfig:GetCivilizationShortDescription()
        if civName ~= nil and civName ~= "" then
            local adjective = civName:gsub("_NAME", "_ADJECTIVE")
            if adjective ~= nil and adjective ~= "" then
                return Locale.Lookup(adjective)
            end
        end
    end

    return Locale.Lookup("LOC_TOOLTIP_PLAYER_ID", playerID)
end

function GetUnitFormationSuffix(data)
    if data == nil or data.UnitType == nil or data.UnitType == -1 then
        return nil
    end

    local unitInfo = GameInfo.Units[data.UnitType]
    if unitInfo == nil then
        return nil
    end

    if data.MilitaryFormation == MilitaryFormationTypes.CORPS_FORMATION then
        if unitInfo.Domain == "DOMAIN_SEA" then
            return Locale.Lookup("LOC_HUD_UNIT_PANEL_FLEET_SUFFIX")
        end
        return Locale.Lookup("LOC_HUD_UNIT_PANEL_CORPS_SUFFIX")
    elseif data.MilitaryFormation == MilitaryFormationTypes.ARMY_FORMATION then
        if unitInfo.Domain == "DOMAIN_SEA" then
            return Locale.Lookup("LOC_HUD_UNIT_PANEL_ARMADA_SUFFIX")
        end
        return Locale.Lookup("LOC_HUD_UNIT_PANEL_ARMY_SUFFIX")
    end

    return nil
end

function GetUnitInfoName(data, unit)
    if data == nil then
        return nil
    end

    local unitName = Locale.Lookup(data.Name)
    local formationSuffix = GetUnitFormationSuffix(data)
    if formationSuffix ~= nil then
        unitName = unitName .. " " .. formationSuffix
    end

    return JoinUnitInfo({
        GetUnitOwnershipPrefix(unit),
        unitName,
    }, " ")
end

function GetUnitInfoCoords(unit)
    if unit == nil then
        return nil
    end

    return Locale.Lookup("LOC_CAI_COORDS_STRING", unit:GetX(), unit:GetY())
end

function GetUnitInfoHealth(data)
    if data == nil or data.MaxDamage == nil or data.MaxDamage <= 0 then
        return nil
    end

    return Locale.Lookup("LOC_HUD_UNIT_PANEL_HEALTH_TOOLTIP", data.MaxDamage - data.Damage, data.MaxDamage)
end

function GetUnitInfoMovement(data)
    if data == nil then
        return nil
    end

    local moves = data.MovementMoves or data.Moves or 0
    return Locale.Lookup("LOC_CAI_UNIT_MOVES", moves, data.MaxMoves)
end

function GetUnitInfoCombat(data)
    if data == nil then
        return nil
    end

    local results = {}
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

function GetUnitInfoCharges(data)
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

    return results
end

function GetUnitInfoPromotions(data)
    if data == nil then
        return nil
    end

    local results = {
        Locale.Lookup("LOC_HUD_UNIT_PANEL_LEVEL_ABBREVIATION") .. " " .. tostring(data.UnitLevel),
        Locale.Lookup("LOC_HUD_UNIT_PANEL_XP_TT", data.UnitExperience, data.MaxExperience, data.UnitLevel + 1),
    }

    if data.CurrentPromotions ~= nil and #data.CurrentPromotions > 0 then
        for _, promotion in ipairs(data.CurrentPromotions) do
            AppendUnitInfo(results, Locale.Lookup(promotion.Name))
        end
    elseif GetPromotionBannerVisibility ~= nil and GetPromotionBannerVisibility() then
        AppendUnitInfo(results, Locale.Lookup("LOC_HUD_UNIT_CHOOSE_PROMOTION_TEXT"))
    end

    return results
end

function GetUnitInfoFormation(data)
    if data == nil or not data.InFormation then
        return nil
    end

    return JoinUnitInfo({
        GetUnitFormationSuffix(data),
        Locale.Lookup("LOC_HUD_UNIT_PANEL_MOVEMENT") ..
        ", " ..
        tostring(data.FormationMoves or 0) ..
        " / " ..
        tostring(data.FormationMaxMoves or 0),
    }, ", ")
end

function GetUnitInfoAbilities(data)
    if data == nil or data.Ability == nil or #data.Ability == 0 then
        return nil
    end

    local results = {}
    for _, ability in ipairs(data.Ability) do
        local description = GetUnitAbilityDescription(ability)
        if description ~= nil and description ~= "" then
            AppendUnitInfo(results, Locale.Lookup(description))
        end
    end

    return results
end

function GetUnitInfoSpecialState(data)
    if data == nil then
        return nil
    end

    local results = {}
    AppendUnitInfo(results,
        data.GreatPersonPassiveText ~= nil and data.GreatPersonPassiveText ~= "" and
        Locale.Lookup("LOC_HUD_UNIT_PANEL_GREAT_PERSON_PASSIVE_ABILITY_TOOLTIP", data.GreatPersonPassiveName,
            data.GreatPersonPassiveText) or nil)
    AppendUnitInfo(results, data.IsTradeUnit and JoinUnitInfo({
        data.TradeRouteName,
        Locale.Lookup("LOC_HUD_UNIT_PANEL_LAND_ROUTE_RANGE") .. ", " .. tostring(data.TradeLandRange),
        Locale.Lookup("LOC_HUD_UNIT_PANEL_SEA_ROUTE_RANGE") .. ", " .. tostring(data.TradeSeaRange),
    }, ", ") or nil)
    AppendUnitInfo(results, data.IsSpy and JoinUnitInfo({
        data.SpyTargetCityName,
        (data.SpyRemainingTurns or 0) > 0 and Locale.Lookup("LOC_UNITPANEL_ESPIONAGE_MORE_TURNS", data.SpyRemainingTurns) or
        nil,
    }, ", ") or nil)

    return results
end

function GetUnitInfoActions(data)
    local actions = GetUnitActionEntries(data)
    local results = {}

    for _, action in ipairs(actions) do
        AppendUnitInfo(results, GetUnitActionLabel(action))
    end

    return results
end

UnitInfo = {
    Summary = function(data, unit)
        return JoinUnitInfo({
            GetUnitInfoName(data, unit),
            GetUnitInfoCoords(unit),
            GetUnitInfoHealth(data),
            GetUnitInfoMovement(data),
            JoinUnitInfo(GetUnitInfoCombat(data) or {}, ", "),
            JoinUnitInfo(GetUnitInfoCharges(data) or {}, ", "),
        }, ", ")
    end,

    Name = function(data, unit)
        return GetUnitInfoName(data, unit)
    end,

    Health = function(data, unit)
        return GetUnitInfoHealth(data)
    end,

    Movement = function(data, unit)
        return GetUnitInfoMovement(data)
    end,

    Combat = function(data, unit)
        return GetUnitInfoCombat(data)
    end,

    Charges = function(data, unit)
        return GetUnitInfoCharges(data)
    end,

    Promotions = function(data, unit)
        return GetUnitInfoPromotions(data)
    end,

    Formation = function(data, unit)
        return GetUnitInfoFormation(data)
    end,

    Abilities = function(data, unit)
        return GetUnitInfoAbilities(data)
    end,

    SpecialState = function(data, unit)
        return GetUnitInfoSpecialState(data)
    end,

    Actions = function(data, unit)
        return GetUnitInfoActions(data)
    end,

    QueuedPath = function(data, unit)
        if unit == nil then return nil end
        local queued = UnitManager.GetQueuedDestination(unit)
        if not queued then return nil end
        return BuildMovementSpeech(BuildMovementPathInfo(unit, queued, true, true))
    end,
}

info.UnitInfo = UnitInfo
info.UnitInfoPriority = UnitInfoPriority

--# Action list

function GetUnitActionLabel(action)
    if action == nil then
        return nil
    end

    return GetFirstUnitInfoLine(action.helpString) or Locale.Lookup("LOC_OPTIONS_HOTKEY_CATEGORY_UNIT")
end

function GetUnitActionEntries(data)
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
    table.insert(actionOrder, "BUILD")

    local seenCategories = {}
    for _, categoryName in ipairs(actionOrder) do
        if not seenCategories[categoryName] then
            seenCategories[categoryName] = true
            local categoryTable = data.Actions[categoryName]
            if categoryTable ~= nil then
                for _, action in ipairs(categoryTable) do
                    if not action.Disabled then
                        table.insert(results, action)
                    end
                end
            end
        end
    end

    return results
end

function CloseUnitActionList()
    if UnitActionList ~= nil then
        mgr:RemoveFromStack(UNIT_ACTION_LIST_ID)
        UnitActionList = nil
    end
end

function BuildUnitActionList(data)
    local selectedUnit = GetSelectedUnit()
    local unitName = GetUnitInfoName(data, selectedUnit) or Locale.Lookup("LOC_OPTIONS_HOTKEY_CATEGORY_UNIT")
    local list = mgr:CreateUIWidget(UNIT_ACTION_LIST_ID, "List", {
        GetLabel = function()
            return Locale.Lookup("LOC_CAI_SELECTION_ACTIONS_FOR", unitName)
        end,
    })

    list:AddInputBinding({
        Key = Keys.VK_ESCAPE,
        Action = function()
            CloseUnitActionList()
            return true
        end,
    })

    for _, action in ipairs(GetUnitActionEntries(data)) do
        local currentAction = action
        list:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIUnitPanelMenuItem"), "MenuItem", {
            GetLabel = function()
                return GetUnitActionLabel(currentAction)
            end,
            GetTooltip = function()
                return currentAction.helpString
            end,
            OnFocusEnter = function()
                UI.PlaySound("Main_Menu_Mouse_Over")
            end,
            OnClick = function()
                if currentAction.Disabled then
                    if currentAction.helpString ~= nil and currentAction.helpString ~= "" then
                        Speak(ProcessIcons(currentAction.helpString))
                    end
                    return
                end

                CloseUnitActionList()
                UI.PlaySound("Play_UI_Click")
                if currentAction.Sound ~= nil and currentAction.Sound ~= "" then
                    UI.PlaySound(currentAction.Sound)
                end
                currentAction.CallbackFunc(currentAction.CallbackVoid1, currentAction.CallbackVoid2)
            end,
        }))
    end

    if data ~= nil and data.Ability ~= nil and #data.Ability > 0 then
        local abilitiesActionId = Input.GetActionId("UnitViewAbilities")
        list:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIUnitViewAbilities"), "MenuItem", {
            GetLabel     = function() return Locale.Lookup("LOC_CAI_UNIT_VIEW_ABILITIES") end,
            GetTooltip   = function() return Locale.Lookup("LOC_CAI_UNIT_VIEW_ABILITIES_TOOLTIP") end,
            OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
            OnClick      = function()
                CloseUnitActionList()
                OnUnitPanelSelectionActionInputTriggered(abilitiesActionId)
            end,
        }))
    end

    return list
end

function OpenUnitActionList()
    if mgr == nil or ContextPtr:IsHidden() or GetSelectedUnit() == nil then
        return
    end

    if UnitActionList ~= nil then
        CloseUnitActionList()
    end

    local data = GetSubjectData ~= nil and GetSubjectData() or nil
    if data == nil then
        local unit = GetSelectedUnit()
        if unit ~= nil and ReadUnitData ~= nil then
            data = ReadUnitData(unit)
        end
    end

    UnitActionList = BuildUnitActionList(data)
    if UnitActionList ~= nil and UnitActionList.Children ~= nil and #UnitActionList.Children > 0 then
        mgr:Push(UnitActionList, PopupPriority.Low)
    else
        UnitActionList = nil
    end
end

--# Input handling

function OnHandleInput(inputStruct)
    if not mgr then return false end
    return mgr:HandleInput(inputStruct)
end

function InitializeUnitInfoActionMap()
    UnitInfoActionMap = {
        [Input.GetActionId("ReadSelectionSummary")] = { "Summary" },
        [Input.GetActionId("ReadSelectionInfo1")] = { "Health" },
        [Input.GetActionId("ReadSelectionInfo2")] = { "Movement" },
        [Input.GetActionId("ReadSelectionInfo3")] = { "Combat" },
        [Input.GetActionId("ReadSelectionInfo4")] = { "Charges" },
        [Input.GetActionId("ReadSelectionInfo5")] = { "Promotions" },
        [Input.GetActionId("ReadSelectionInfo6")] = { "Formation" },
        [Input.GetActionId("ReadSelectionInfo7")] = { "SpecialState" },
        [Input.GetActionId("ReadSelectionInfo8")] = { "Actions" },
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

    Speak(ProcessIcons(table.concat(results, "\n")))
end

function OnUnitPanelSelectionActionInputTriggered(actionId)
    if actionId == prevUnitCatAction then
        ChangeUnitSelectionCategory(-1)
    elseif actionId == nextUnitCatAction then
        ChangeUnitSelectionCategory(1)
    elseif actionId == prevUnitAction then
        ChangeUnitSelection(-1)
    elseif actionId == nextUnitAction then
        ChangeUnitSelection(1)
    end
    if actionId == Input.GetActionId("SelectionActions") then
        OpenUnitActionList()
    end
    if actionId == Input.GetActionId("UnitViewAbilities") then
        if ContextPtr:IsHidden() or GetSelectedUnit() == nil then return end

        local data = GetSubjectData ~= nil and GetSubjectData() or nil
        if data == nil then
            local unit = GetSelectedUnit()
            if unit ~= nil and ReadUnitData ~= nil then data = ReadUnitData(unit) end
        end

        if data == nil or data.Ability == nil or #data.Ability == 0 then
            Speak(Locale.Lookup("LOC_CAI_UNIT_NO_ABILITIES"))
            return
        end

        local UNIT_ABILITIES_LIST_ID = "CAIUnitAbilitiesList"
        local list = mgr:CreateUIWidget(UNIT_ABILITIES_LIST_ID, "List", {
            GetLabel = function() return Locale.Lookup("LOC_CAI_UNIT_ABILITIES_LIST") end,
        })
        list:AddInputBinding({ Key = Keys.VK_ESCAPE, Action = function()
            mgr:RemoveFromStack(UNIT_ABILITIES_LIST_ID); return true
        end })

        for _, ability in ipairs(data.Ability) do
            local desc = GetUnitAbilityDescription(ability)
            if desc ~= nil and desc ~= "" then
                local locDesc = Locale.Lookup(desc)
                list:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIUnitAbilityItem"), "MenuItem", {
                    GetLabel     = function() return locDesc end,
                    OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
                    OnClick      = function() mgr:RemoveFromStack(UNIT_ABILITIES_LIST_ID) end,
                }))
            end
        end

        if list.Children ~= nil and #list.Children > 0 then
            mgr:Push(list, PopupPriority.Low)
        end
    end
end

function OnCAIUnitSelectionChanged(player, unitId, locationX, locationY, locationZ, isSelected, isEditable)
    if ContextPtr:IsHidden() or not isSelected then
        return
    end

    local results = info:RequestUnitInfo(unitId, { "Summary" }, player)
    if results == nil or #results == 0 then
        return
    end

    Speak(ProcessIcons(table.concat(results, "\n")))
    LuaEvents.CAICursorMove(locationX, locationY)
end

--# Public API

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
Events.UnitSelectionChanged.Add(OnCAIUnitSelectionChanged)

-- Init input handler
ContextPtr:SetInputHandler(OnHandleInput, true)
