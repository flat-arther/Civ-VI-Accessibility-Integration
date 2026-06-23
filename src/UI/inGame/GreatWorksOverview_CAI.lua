-- GreatWorksOverview_CAI.lua
-- Accessibility overlay for the Great Works Overview screen.
-- Rides the wildcard include("GreatWorksOverview_", true) from the base file.

include("caiUtils")

local mgr = ExposedMembers.CAI_UIManager

local PANEL_ID  = "CAIGreatWorksOverview_Panel"
local TREE_ID   = "CAIGreatWorksOverview_Tree"
local PICKER_ID = "CAIGreatWorksOverview_Picker"

local m_ui = { panel = nil, tree = nil, picker = nil }

local m_caiIsLocalPlayerTurn = true
local m_lastFocusedWork      = nil

local GREAT_WORK_ARTIFACT_TYPE = "GREATWORKOBJECT_ARTIFACT"
local DEFAULT_LOCK_TURNS       = 10
local ART_OBJECT_TYPES = {
    GREATWORKOBJECT_SCULPTURE = true,
    GREATWORKOBJECT_LANDSCAPE = true,
    GREATWORKOBJECT_PORTRAIT  = true,
    GREATWORKOBJECT_RELIGIOUS = true,
}

-- ---------------------------------------------------------------------------
-- Data helpers
-- ---------------------------------------------------------------------------

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

local function GetGreatWorkLabel(pCityBldgs, greatWorkIndex)
    local gwType  = pCityBldgs:GetGreatWorkTypeFromIndex(greatWorkIndex)
    local gwInfo  = GameInfo.GreatWorks[gwType]
    local name    = Locale.Lookup(gwInfo.Name)
    local creator = Locale.Lookup(pCityBldgs:GetCreatorNameFromIndex(greatWorkIndex))
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
        local iTurnCreated   = pCityBldgs:GetTurnFromIndex(gwIdx)
        local iCurrentTurn   = Game.GetCurrentGameTurn()
        local iTurnsBeforeMove = GlobalParameters.GREATWORK_ART_LOCK_TIME or DEFAULT_LOCK_TURNS
        local iTurnsToWait   = iTurnCreated + iTurnsBeforeMove - iCurrentTurn
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

    local firstGWTypeID    = pCityBldgs:GetGreatWorkTypeFromIndex(firstGW)
    local firstGWObjType   = GameInfo.GreatWorks[firstGWTypeID].GreatWorkObjectType

    local gwType  = pCityBldgs:GetGreatWorkTypeFromIndex(greatWorkIndex)
    local gwInfo  = GameInfo.GreatWorks[gwType]

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

    return table.concat(parts, ", ")
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
    return table.concat(parts, ", ")
end

local function GetBuildingLabel(buildingInfo, pCityBldgs)
    local label        = Locale.Lookup(buildingInfo.Name)
    local buildingIndex = buildingInfo.Index

    local themeDesc = GetThemeDescription(buildingInfo.BuildingType)
    if themeDesc then
        if pCityBldgs:IsBuildingThemedCorrectly(buildingIndex) then
            label = label .. ", " .. Locale.Lookup("LOC_GREAT_WORKS_THEMED_BONUS")
        else
            local numSlots  = pCityBldgs:GetNumGreatWorkSlots(buildingIndex)

            local localPlayer = Players[Game.GetLocalPlayer()]
            local bAutoTheme = localPlayer
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
    return table.concat(parts, ", ")
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

    local parts = {}
    for yieldType, value in pairs(yields) do
        local yi = GameInfo.Yields[yieldType]
        if yi then table.insert(parts, value .. " " .. Locale.Lookup(yi.Name)) end
    end
    if tourism > 0 then
        table.insert(parts, tourism .. " " .. Locale.Lookup("LOC_GREAT_WORKS_TOURISM"))
    end
    return table.concat(parts, ", ")
end

-- ---------------------------------------------------------------------------
-- Move helper
-- ---------------------------------------------------------------------------

local function ExecuteMove(srcCityID, srcBuildingID, srcGWIndex,
                           dstCityID, dstBuildingID, dstSlotIndex)
    local t = {}
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

local function ClosePicker()
    if mgr and m_ui.picker then mgr:RemoveFromStack(PICKER_ID) end
    m_ui.picker = nil
end

local function OpenPicker(dstCityBldgs, dstBuildingIndex, dstSlotIndex)
    ClosePicker()

    local dstCityID   = dstCityBldgs:GetCity():GetID()
    local dstSlotType = dstCityBldgs:GetGreatWorkSlotType(dstBuildingIndex, dstSlotIndex)
    local dstSlotStr  = GameInfo.GreatWorkSlotTypes[dstSlotType].GreatWorkSlotType
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
        { Key = Keys.VK_ESCAPE, MSG = KeyEvents.KeyUp,
          Description = "LOC_CAI_KB_CLOSE",
          Action = function() ClosePicker() return true end },
    })

    local localPlayer = Players[Game.GetLocalPlayer()]
    local hasItems    = false

    for _, pCity in localPlayer:GetCities():Members() do
        if pCity and pCity:GetOwner() == Game.GetLocalPlayer() then
            local bldgs = pCity:GetBuildings()
            local cityNode = nil

            for bi in GameInfo.Buildings() do
                if bldgs:HasBuilding(bi.Index) then
                    local ns = bldgs:GetNumGreatWorkSlots(bi.Index)
                    if ns and ns > 0 then
                        local bldgNode = nil
                        for si = 0, ns - 1 do
                            local gwIdx = bldgs:GetGreatWorkInSlot(bi.Index, si)
                            if gwIdx ~= -1
                               and not (bldgs == dstCityBldgs
                                        and bi.Index == dstBuildingIndex
                                        and si == dstSlotIndex)
                               and CanMoveWorkAtAll(bldgs, bi.Index, si)
                               and CanMoveGreatWork(bldgs, bi.Index, si,
                                                    dstCityBldgs, dstBuildingIndex,
                                                    dstSlotIndex)
                            then
                                if not cityNode then
                                    local cCityName = Locale.Lookup(pCity:GetName())
                                    cityNode = mgr:CreateWidget(
                                        mgr:GenerateWidgetId("CAIGWPicker_City"),
                                        "TreeItem",
                                        { Label = function() return cCityName end })
                                    m_ui.picker:AddChild(cityNode)
                                    cityNode:Expand(true)
                                end

                                if not bldgNode then
                                    local bldgName = Locale.Lookup(bi.Name)
                                    bldgNode = mgr:CreateWidget(
                                        mgr:GenerateWidgetId("CAIGWPicker_Bldg"),
                                        "TreeItem",
                                        { Label = function() return bldgName end })
                                    cityNode:AddChild(bldgNode)
                                    bldgNode:Expand(true)
                                end

                                local cGW    = gwIdx
                                local cBI    = bi.Index
                                local cBldgs = bldgs
                                local cCityID = pCity:GetID()
                                local cBInfo = bi

                                local item = mgr:CreateWidget(
                                    mgr:GenerateWidgetId("CAIGWPicker_Item"),
                                    "TreeItem", {
                                    Label   = function()
                                        return GetGreatWorkLabel(cBldgs, cGW)
                                    end,
                                    Tooltip = function()
                                        return GetGreatWorkDetail(cBldgs, cGW, cBInfo)
                                    end,
                                    FocusKey = "gw:" .. tostring(cGW),
                                })
                                item:SetFocusSound("Main_Menu_Mouse_Over")
                                item:On("activate", function()
                                    ClosePicker()
                                    ExecuteMove(cCityID, cBI, cGW,
                                                dstCityID, dstBuildingIndex,
                                                dstSlotIndex)
                                end)
                                bldgNode:AddChild(item)
                                hasItems = true
                            end
                        end
                    end
                end
            end
        end
    end

    if not hasItems then
        m_ui.picker:AddChild(mgr:CreateWidget(
            mgr:GenerateWidgetId("CAIGWPicker_Empty"), "TreeItem",
            { Label = function()
                return Locale.Lookup("LOC_CAI_GREAT_WORKS_NO_COMPATIBLE")
            end }))
    end

    mgr:Push(m_ui.picker, PopupPriority.Current)
end

-- ---------------------------------------------------------------------------
-- Tree content
-- ---------------------------------------------------------------------------

local function BuildTreeContent(tree)
    local localPlayer = Players[Game.GetLocalPlayer()]
    if not localPlayer then return end

    for _, pCity in localPlayer:GetCities():Members() do
        if pCity and pCity:GetOwner() == Game.GetLocalPlayer() then
            local bldgs = pCity:GetBuildings()
            local cityItem = nil

            for bi in GameInfo.Buildings() do
                if bldgs:HasBuilding(bi.Index) then
                    local ns = bldgs:GetNumGreatWorkSlots(bi.Index)
                    if ns and ns > 0 then
                        if not cityItem then
                            local cCity = pCity
                            cityItem = mgr:CreateWidget(
                                mgr:GenerateWidgetId("CAIGW_City"), "TreeItem", {
                                Label    = function()
                                    return Locale.Lookup(cCity:GetName())
                                end,
                                FocusKey = "city:" .. tostring(pCity:GetID()),
                            })
                        end

                        local cCity  = pCity
                        local cBldgs = bldgs
                        local cBI    = bi
                        local cBIdx  = bi.Index

                        local bldgItem = mgr:CreateWidget(
                            mgr:GenerateWidgetId("CAIGW_Building"), "TreeItem", {
                            Label    = function()
                                return GetBuildingLabel(cBI, cBldgs)
                            end,
                            Tooltip  = function()
                                return GetBuildingTooltip(cBldgs, cBI)
                            end,
                            FocusKey = "bldg:" .. tostring(cCity:GetID())
                                .. ":" .. tostring(cBIdx),
                        })

                        for si = 0, ns - 1 do
                            local cSI      = si
                            local slotType = bldgs:GetGreatWorkSlotType(cBIdx, si)
                            local slotStr  = GameInfo.GreatWorkSlotTypes[slotType]
                                                 .GreatWorkSlotType

                            local slotItem = mgr:CreateWidget(
                                mgr:GenerateWidgetId("CAIGW_Slot"), "TreeItem", {
                                Label = function()
                                    local gw = cBldgs:GetGreatWorkInSlot(cBIdx, cSI)
                                    if gw == -1 then
                                        return Locale.Lookup(
                                            "LOC_CAI_GREAT_WORKS_EMPTY_SLOT",
                                            GetSlotTypeName(slotStr))
                                    end
                                    return GetGreatWorkLabel(cBldgs, gw)
                                end,
                                Tooltip = function()
                                    local gw = cBldgs:GetGreatWorkInSlot(cBIdx, cSI)
                                    if gw == -1 then return "" end
                                    return GetGreatWorkDetail(cBldgs, gw, cBI)
                                end,
                                DisabledPredicate = function()
                                    return not m_caiIsLocalPlayerTurn
                                end,
                                FocusKey = "slot:" .. tostring(cCity:GetID())
                                    .. ":" .. tostring(cBIdx)
                                    .. ":" .. tostring(cSI),
                            })
                            slotItem:SetFocusSound("Main_Menu_Mouse_Over")

                            slotItem:On("focus_enter", function()
                                local gw = cBldgs:GetGreatWorkInSlot(cBIdx, cSI)
                                if gw ~= -1 then
                                    m_lastFocusedWork = {
                                        Index    = gw,
                                        Building = cBIdx,
                                        CityBldgs = cBldgs,
                                    }
                                end
                            end)

                            slotItem:On("activate", function()
                                OpenPicker(cBldgs, cBIdx, cSI)
                            end)

                            slotItem:AddInputBindings({
                                {
                                    Key       = Keys.VK_RETURN,
                                    IsControl = true,
                                    MSG       = KeyEvents.KeyUp,
                                    Description = "LOC_CAI_KB_VIEW_GREAT_WORK",
                                    Action = function()
                                        local gw = cBldgs:GetGreatWorkInSlot(
                                            cBIdx, cSI)
                                        if gw ~= -1 then
                                            ViewGreatWork({
                                                Index     = gw,
                                                Building  = cBIdx,
                                                CityBldgs = cBldgs,
                                            })
                                            UI.PlaySound(
                                                "Play_GreatWorks_Gallery_Ambience")
                                        end
                                        return true
                                    end,
                                },
                            })

                            bldgItem:AddChild(slotItem)
                        end

                        cityItem:AddChild(bldgItem)
                    end
                end
            end

            if cityItem then
                tree:AddChild(cityItem)
            end
        end
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
            local numGW     = Controls.NumGreatWorks:GetText()    or "0"
            local numSpaces = Controls.NumDisplaySpaces:GetText() or "0"
            local label = Locale.Lookup("LOC_CAI_GREAT_WORKS_SUMMARY",
                numGW, numSpaces)
            local yields = GetYieldsSummary()
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
    if mgr and m_ui.panel then mgr:RemoveFromStack(PANEL_ID) end
    m_ui = { panel = nil, tree = nil, picker = nil }
end

-- ---------------------------------------------------------------------------
-- Vanilla wraps
-- ---------------------------------------------------------------------------

Open = WrapFunc(Open, function(orig)
    orig()
    if not m_ui.panel then BuildPanel() end
    RefreshTree()
    PushPanel()
end)

Close = WrapFunc(Close, function(orig)
    orig()
    PopPanel()
end)

OnGreatWorkMoved = WrapFunc(OnGreatWorkMoved, function(orig, ...)
    orig(...)
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
