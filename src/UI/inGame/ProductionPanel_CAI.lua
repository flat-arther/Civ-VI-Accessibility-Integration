include("caiUtils")
include("ProductionPanel")
local mgr                              = ExposedMembers.CAI_UIManager

local LISTMODE                         = { PRODUCTION = 1, PURCHASE_GOLD = 2, PURCHASE_FAITH = 3, PROD_QUEUE = 4 }

local TAB_PRODUCTION                   = 1
local TAB_PURCHASE_GOLD                = 2
local TAB_PURCHASE_FAITH               = 3
local TAB_QUEUE                        = 4

local MAX_QUEUE_SIZE                   = 7

local m_caiPanel                       = nil ---@type UIWidget|nil
local m_caiTabBar                      = nil ---@type UIWidget|nil
local m_caiTabs                        = {} ---@type table<number, UIWidget>
local m_caiTree                        = nil ---@type UIWidget|nil
local m_caiQueueList                   = nil ---@type UIWidget|nil
local m_caiCurrentNode                 = nil ---@type UIWidget|nil
local m_caiQueueNode                   = nil ---@type UIWidget|nil
local m_caiCatDistricts                = nil ---@type UIWidget|nil
local m_caiCatWonders                  = nil ---@type UIWidget|nil
local m_caiCatBuildings                = nil ---@type UIWidget|nil
local m_caiCatUnits                    = nil ---@type UIWidget|nil
local m_caiCatProjects                 = nil ---@type UIWidget|nil
local m_caiDetailEdit                  = nil ---@type UIWidget|nil
local m_caiCloseBtn                    = nil ---@type UIWidget|nil

local m_caiData                        = nil ---@type table|nil
local m_caiTab                         = TAB_PRODUCTION
local m_caiOpenPending                 = false
local m_caiRecommended                 = {} ---@type table<number, boolean>
local m_caiQueueActionActive           = false
local m_caiQueueFocusIndexAfterRebuild = nil ---@type integer|nil
local m_caiLastBuiltTab                = nil ---@type integer|nil
local m_caiLastBuiltCityID             = nil ---@type integer|nil
local m_caiLastBuiltPlayerID           = nil ---@type integer|nil
local m_caiLastDetailFocusKey          = nil ---@type string|nil

local m_caiInstanceByHash              = {} ---@type table<number, table>
local m_caiInstancesByModeHash         = {} ---@type table<number, table<number, table>>
local m_caiWonderList                  = nil ---@type table|nil
local m_caiProjectList                 = nil ---@type table|nil
local m_caiDistrictList                = nil ---@type table|nil
local m_caiBuildingList                = nil ---@type table|nil
local m_caiUnitList                    = nil ---@type table|nil
local m_caiCaptureListMode             = nil ---@type integer|nil

function PlayMenuHover()
    UI.PlaySound("Main_Menu_Mouse_Over")
end

function SetDetailText(text)
    if m_caiDetailEdit then
        mgr.WidgetTemplateHelpers:SetEditBoxText(m_caiDetailEdit, text or "")
    end
end

function SetFocusedDetailText(focusKey, text)
    if not focusKey then
        SetDetailText(text)
        return
    end
    if m_caiLastDetailFocusKey == focusKey then return end
    m_caiLastDetailFocusKey = focusKey
    SetDetailText(text)
end

function WithFormationSuffix(name, formation)
    if formation == "corps" then
        return name .. " " .. Locale.Lookup("LOC_UNITFLAG_CORPS_SUFFIX")
    elseif formation == "army" then
        return name .. " " .. Locale.Lookup("LOC_UNITFLAG_ARMY_SUFFIX")
    end
    return name
end

function GetListModeForTab(tab)
    if tab == TAB_PRODUCTION then return LISTMODE.PRODUCTION end
    if tab == TAB_PURCHASE_GOLD then return LISTMODE.PURCHASE_GOLD end
    if tab == TAB_PURCHASE_FAITH then return LISTMODE.PURCHASE_FAITH end
    if NormalizeCAITab(tab) == TAB_QUEUE then return LISTMODE.PROD_QUEUE end
    return nil
end

function GetProductionItemClass(item)
    if not item then return nil end
    if item.Type and GameInfo.Units[item.Type] then return "unit" end
    if item.Type and GameInfo.Buildings[item.Type] then return "building" end
    if item.Type and GameInfo.Districts[item.Type] then return "district" end
    if item.Type and GameInfo.Projects[item.Type] then return "project" end
    if item.Kind == "KIND_UNIT" then return "unit" end
    if item.Kind == "KIND_BUILDING" then return "building" end
    if item.Kind == "KIND_DISTRICT" then return "district" end
    if item.Kind == "KIND_PROJECT" then return "project" end
    return nil
end

function GetInstanceForItem(item, tab)
    if not item or not item.Hash then return nil end
    local listMode = GetListModeForTab(tab)
    local byMode = listMode and m_caiInstancesByModeHash[listMode] or nil
    if byMode and byMode[item.Hash] then
        return byMode[item.Hash]
    end
    return m_caiInstanceByHash[item.Hash]
end

function GetActiveProductionCity()
    local city = UI.GetHeadSelectedCity and UI.GetHeadSelectedCity() or nil
    if city then return city end
    if m_caiData and m_caiData.City then return m_caiData.City end
    return nil
end

function GetYieldIndex(yieldType)
    local yieldInfo = yieldType and GameInfo.Yields[yieldType] or nil
    return yieldInfo and yieldInfo.Index or nil
end

function RequestPurchaseUnit(city, item, formationType)
    if not city or not item or not item.Hash then return false end
    local yieldIndex = GetYieldIndex(item.Yield)
    if yieldIndex == nil then return false end

    local tParameters = {}
    tParameters[CityCommandTypes.PARAM_UNIT_TYPE] = item.Hash
    tParameters[CityCommandTypes.PARAM_MILITARY_FORMATION_TYPE] = formationType
    tParameters[CityCommandTypes.PARAM_YIELD_TYPE] = yieldIndex

    if item.Yield == "YIELD_GOLD" then
        UI.PlaySound("Purchase_With_Gold")
    else
        UI.PlaySound("Purchase_With_Faith")
    end

    CityManager.RequestCommand(city, CityCommandTypes.PURCHASE, tParameters)
    return true
end

function RequestPurchaseBuilding(city, item)
    if not city or not item or not item.Hash then return false end
    local yieldIndex = GetYieldIndex(item.Yield)
    if yieldIndex == nil then return false end

    local tParameters = {}
    tParameters[CityCommandTypes.PARAM_BUILDING_TYPE] = item.Hash
    tParameters[CityCommandTypes.PARAM_YIELD_TYPE] = yieldIndex

    if item.Yield == "YIELD_GOLD" then
        UI.PlaySound("Purchase_With_Gold")
    else
        UI.PlaySound("Purchase_With_Faith")
    end

    CityManager.RequestCommand(city, CityCommandTypes.PURCHASE, tParameters)
    return true
end

function RequestPurchaseDistrict(city, item)
    if not city or not item or not item.Hash or not item.Type then return false end
    local district = GameInfo.Districts[item.Type]
    local yieldIndex = GetYieldIndex(item.Yield)
    local pBuildQueue = city.GetBuildQueue and city:GetBuildQueue() or nil
    if not district or yieldIndex == nil or not pBuildQueue then return false end

    local bNeedsPlacement = district.RequiresPlacement
    if pBuildQueue.HasBeenPlaced and pBuildQueue:HasBeenPlaced(item.Hash) then
        bNeedsPlacement = false
    end

    local tParameters = {}
    tParameters[CityOperationTypes.PARAM_DISTRICT_TYPE] = item.Hash
    tParameters[CityCommandTypes.PARAM_YIELD_TYPE] = yieldIndex

    if bNeedsPlacement then
        UI.SetInterfaceMode(InterfaceModeTypes.DISTRICT_PLACEMENT, tParameters)
    else
        CityManager.RequestCommand(city, CityCommandTypes.PURCHASE, tParameters)
        if item.Yield == "YIELD_GOLD" then
            UI.PlaySound("Purchase_With_Gold")
        else
            UI.PlaySound("Purchase_With_Faith")
        end
    end

    return true
end

function CurrentTabSupportsQueue()
    return not m_isTutorialRunning and not m_tutorialTestMode
end

function ReadRowLabel(item, formation)
    local kInstance = GetInstanceForItem(item, m_caiTab)
    if not kInstance then
        return WithFormationSuffix(Locale.Lookup(item.Name or ""), formation)
    end

    local labelCtrl = kInstance.LabelText
    local costCtrl = kInstance.CostText
    if formation == "corps" then
        costCtrl = kInstance.CorpsCostText or costCtrl
    elseif formation == "army" then
        costCtrl = kInstance.ArmyCostText or costCtrl
    end

    local parts = {}
    if labelCtrl and labelCtrl.GetText then
        local t = labelCtrl:GetText() or ""
        if t ~= "" then table.insert(parts, WithFormationSuffix(t, formation)) end
    end
    if m_caiRecommended[item.Hash] and not formation then
        table.insert(parts, Locale.Lookup("LOC_RECOMMENDED"))
    end
    if costCtrl and costCtrl.GetText then
        local t = costCtrl:GetText() or ""
        if t ~= "" then table.insert(parts, t) end
    end
    return table.concat(parts, ", ")
end

function ReadRowTooltip(item, formation)
    local kInstance = GetInstanceForItem(item, m_caiTab)
    if not kInstance then return "" end
    local btn = kInstance.Button
    if formation == "corps" then btn = kInstance.TrainCorpsButton or btn end
    if formation == "army" then btn = kInstance.TrainArmyButton or btn end
    if btn and btn.GetToolTipString then
        return btn:GetToolTipString() or ""
    end
    return ""
end

function ComposeDetail(item, formation)
    local kInstance = GetInstanceForItem(item, m_caiTab)
    if not kInstance then return Locale.Lookup(item.Name or "") end
    local btn = kInstance.Button
    if formation == "corps" then btn = kInstance.TrainCorpsButton or btn end
    if formation == "army" then btn = kInstance.TrainArmyButton or btn end
    if btn and btn.GetToolTipString then
        local tip = btn:GetToolTipString() or ""
        if tip ~= "" then return tip end
    end
    return Locale.Lookup(item.Name or "")
end

function ReadControlText(control)
    if not control or not control.GetText then return "" end
    return control:GetText() or ""
end

function ReadCurrentProductionLabel()
    local name = ReadControlText(Controls.CurrentProductionName)
    if name == "" then
        return Locale.Lookup("LOC_PRODUCTION_MANAGER_NO_CURRENT_PRODUCTION")
    end

    local parts = { Locale.Lookup("LOC_CAI_PRODUCTION_CURRENT", name) }
    local status = ReadControlText(Controls.CurrentProductionStatus)
    local progress = ReadControlText(Controls.CurrentProductionProgressString)
    local cost = ReadControlText(Controls.CurrentProductionCost)

    if status ~= "" then table.insert(parts, status) end
    if progress ~= "" then table.insert(parts, progress) end
    if cost ~= "" then table.insert(parts, cost) end
    return table.concat(parts, ", ")
end

function ReadCurrentProductionTooltip()
    if Controls.ProductionIcon and type(Controls.ProductionIcon.GetToolTipString) == "function" then
        return Controls.ProductionIcon:GetToolTipString() or ""
    end
    return ""
end

function InvokeRightClickPedia(item)
    if m_isTutorialRunning or not item or not item.Type then return false end
    RightClickProductionItem(item.Type)
    return true
end

function BuildItemLeftAction(item, tab, formation)
    return function()
        local city = GetActiveProductionCity()

        if not city then return end
        local itemClass = GetProductionItemClass(item)

        if tab == TAB_PURCHASE_GOLD or tab == TAB_PURCHASE_FAITH then
            if itemClass == "unit" then
                local spokenName = Locale.Lookup(item.Name or "")
                if formation == "corps" then
                    RequestPurchaseUnit(city, item, MilitaryFormationTypes.CORPS_MILITARY_FORMATION)
                    spokenName = WithFormationSuffix(spokenName, "corps")
                elseif formation == "army" then
                    RequestPurchaseUnit(city, item, MilitaryFormationTypes.ARMY_MILITARY_FORMATION)
                    spokenName = WithFormationSuffix(spokenName, "army")
                else
                    RequestPurchaseUnit(city, item, MilitaryFormationTypes.STANDARD_MILITARY_FORMATION)
                end
                if spokenName ~= "" then
                    Speak(Locale.Lookup("LOC_CAI_PRODUCTION_PURCHASED", spokenName))
                end
                Close()
            elseif itemClass == "building" then
                RequestPurchaseBuilding(city, item)
                if item.Name then
                    Speak(Locale.Lookup("LOC_CAI_PRODUCTION_PURCHASED", Locale.Lookup(item.Name)))
                end
                Close()
            elseif itemClass == "district" then
                RequestPurchaseDistrict(city, item)
                if item.Name then
                    Speak(Locale.Lookup("LOC_CAI_PRODUCTION_PURCHASED", Locale.Lookup(item.Name)))
                end
                Close()
            end
            return
        end

        if itemClass == "unit" then
            if formation == "corps" then
                BuildUnitCorps(city, item)
            elseif formation == "army" then
                BuildUnitArmy(city, item)
            else
                BuildUnit(city, item)
            end
            CloseAfterNewProduction()
        elseif itemClass == "building" then
            BuildBuilding(city, item)
        elseif itemClass == "district" then
            ZoneDistrict(city, item)
        elseif itemClass == "project" then
            AdvanceProject(city, item)
            CloseAfterNewProduction()
        end
    end
end

function SpeakQueuedProduction(item, formation)
    if not item or not item.Name then return end

    local spokenName = Locale.Lookup(item.Name)
    if formation == "corps" then
        spokenName = WithFormationSuffix(spokenName, "corps")
    elseif formation == "army" then
        spokenName = WithFormationSuffix(spokenName, "army")
    end

    if spokenName ~= "" then
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_QUEUED", spokenName))
    end
end

function BuildItemQueueAction(item, tab, formation)
    local leftAction = BuildItemLeftAction(item, tab, formation)

    return function()
        if tab ~= TAB_PRODUCTION then return false end

        local restoreManager = false
        if type(CloseManager) == "function" then
            CloseManager()
        end
        if type(OpenQueue) == "function" then
            OpenQueue()
        else
            return false
        end

        m_caiQueueActionActive = true
        leftAction()
        m_caiQueueActionActive = false

        if type(CloseQueue) == "function" then
            CloseQueue()
        end
        if restoreManager and type(OpenManager) == "function" then
            OpenManager()
        end

        SpeakQueuedProduction(item, formation)
        return true
    end
end

function GetItemsForTab(tab)
    local out = {}
    if not m_caiData then return out end

    if tab == TAB_PRODUCTION then
        out.Districts = m_caiData.DistrictItems or {}
        out.Buildings = {}
        out.Wonders = {}
        for _, b in ipairs(m_caiData.BuildingItems or {}) do
            if b.IsWonder then
                table.insert(out.Wonders, b)
            else
                table.insert(out.Buildings, b)
            end
        end
        out.Units = m_caiData.UnitItems or {}
        out.Projects = m_caiData.ProjectItems or {}
    elseif tab == TAB_PURCHASE_GOLD or tab == TAB_PURCHASE_FAITH then
        local yield = tab == TAB_PURCHASE_GOLD and "YIELD_GOLD" or "YIELD_FAITH"
        out.Districts = {}
        out.Buildings = {}
        out.Units = {}
        for _, d in ipairs(m_caiData.DistrictPurchases or {}) do
            if d.Yield == yield then table.insert(out.Districts, d) end
        end
        for _, b in ipairs(m_caiData.BuildingPurchases or {}) do
            if b.Yield == yield then table.insert(out.Buildings, b) end
        end
        for _, u in ipairs(m_caiData.UnitPurchases or {}) do
            if u.Yield == yield then table.insert(out.Units, u) end
        end
    end

    return out
end

function CreateActionNode(props)
    local node = mgr:CreateUIWidget("TreeviewItem", {
        GetLabel = props.GetLabel,
        GetTooltip = props.GetTooltip,
        IsDisabled = props.IsDisabled,
        IsHidden = props.IsHidden,
        IsExpanded = props.IsExpanded,
        OnToggleExpanded = props.OnToggleExpanded,
        OnFocusEnter = function(w)
            if props.FocusAction then props.FocusAction(w) end
        end,
    })
    node._caiFocusKey = props.FocusKey

    node:AddInputBinding({
        Key = Keys.VK_RETURN,
        Action = function(w)
            return InvokePrimaryAction(w, props.LeftAction)
        end,
    })
    if props.RightAction then
        node:AddInputBinding({
            Key = Keys.VK_RETURN,
            IsShift = true,
            Action = function(w)
                if w.IsDisabled and w:IsDisabled() then return true end
                return props.RightAction(w) ~= false
            end,
        })
    end
    if props.ControlAction then
        node:AddInputBinding({
            Key = Keys.VK_RETURN,
            IsControl = true,
            Action = function(w)
                if w.IsDisabled and w:IsDisabled() then return true end
                return props.ControlAction(w) ~= false
            end,
        })
    end

    return node
end

function CreateItemRow(item, tab, formation)
    local focusKey = string.format("item:%d:%s:%d", tab, formation or "base", item.Hash or -1)
    return CreateActionNode({
        FocusKey = focusKey,
        GetLabel = function() return ReadRowLabel(item, formation) end,
        GetTooltip = function() return ReadRowTooltip(item, formation) end,
        IsDisabled = function()
            if formation == "corps" then return item.CorpsDisabled end
            if formation == "army" then return item.ArmyDisabled end
            return item.Disabled
        end,
        LeftAction = BuildItemLeftAction(item, tab, formation),
        ControlAction = tab == TAB_PRODUCTION and BuildItemQueueAction(item, tab, formation) or nil,
        RightAction = function() return InvokeRightClickPedia(item) end,
        FocusAction = function(w)
            PlayMenuHover()
            SetFocusedDetailText((w and w._caiFocusKey) or focusKey, ComposeDetail(item, formation))
        end,
    })
end

function AddUnitEntry(parent, unit, tab)
    local hasCorps = unit.Corps and unit.CorpsCost and unit.CorpsCost > 0
    local hasArmy = unit.Army and unit.ArmyCost and unit.ArmyCost > 0
    if not hasCorps and not hasArmy then
        parent:AddChild(CreateItemRow(unit, tab, nil))
        return
    end

    local kInstance = GetInstanceForItem(unit, tab)
    local unitNode = CreateActionNode({
        FocusKey = string.format("unit-group:%d:%d", tab, unit.Hash or -1),
        GetLabel = function()
            local inst = GetInstanceForItem(unit, tab)
            if inst and inst.LabelText and inst.LabelText.GetText then
                local t = inst.LabelText:GetText() or ""
                if t ~= "" then return t end
            end
            return Locale.Lookup(unit.Name or "")
        end,
        IsExpanded = kInstance and kInstance.CorpsArmyArrow and kInstance.CorpsArmyArrow:IsSelected() or false,
        OnToggleExpanded = function(expanded)
            local inst = GetInstanceForItem(unit, tab)
            if inst and inst.CorpsArmyArrow and inst.CorpsArmyArrow:IsSelected() ~= expanded then
                OnCorpsToggle(m_caiUnitList, inst)
            end
        end,
        RightAction = function() return InvokeRightClickPedia(unit) end,
        FocusAction = function(w)
            PlayMenuHover()
            SetFocusedDetailText((w and w._caiFocusKey) or string.format("unit-group:%d:%d", tab, unit.Hash or -1),
                ComposeDetail(unit, nil))
        end,
    })

    unitNode:AddChild(CreateItemRow(unit, tab, nil))

    if unit.Corps and unit.CorpsCost and unit.CorpsCost > 0 then
        local corpsItem = setmetatable({
            Cost = unit.CorpsCost,
            TurnsLeft = unit.CorpsTurnsLeft,
            Progress = unit.CorpsProgress,
            Disabled = unit.CorpsDisabled,
        }, { __index = unit })
        unitNode:AddChild(CreateItemRow(corpsItem, tab, "corps"))
    end

    if unit.Army and unit.ArmyCost and unit.ArmyCost > 0 then
        local armyItem = setmetatable({
            Cost = unit.ArmyCost,
            TurnsLeft = unit.ArmyTurnsLeft,
            Progress = unit.ArmyProgress,
            Disabled = unit.ArmyDisabled,
        }, { __index = unit })
        unitNode:AddChild(CreateItemRow(armyItem, tab, "army"))
    end

    parent:AddChild(unitNode)
end

function FillCategoryNode(node, items, tab, isUnits)
    if not node then return end
    node:ClearChildren()
    for _, item in ipairs(items or {}) do
        if isUnits then
            AddUnitEntry(node, item, tab)
        else
            node:AddChild(CreateItemRow(item, tab, nil))
        end
    end
end

function FillProductionDistrictsNode(node, districtItems, buildingItems)
    if not node then return end
    node:ClearChildren()
    for _, item in ipairs(districtItems or {}) do
        node:AddChild(CreateItemRow(item, TAB_PRODUCTION, nil))
    end
    for _, item in ipairs(buildingItems or {}) do
        node:AddChild(CreateItemRow(item, TAB_PRODUCTION, nil))
    end
end

function MakeQueueEntryDescription(entry)
    if not entry then return "" end
    if entry.Directive == CityProductionDirectives.TRAIN and entry.UnitType then
        local def = GameInfo.Units[entry.UnitType]
        if def then return Locale.Lookup(def.Name) end
    elseif entry.Directive == CityProductionDirectives.CONSTRUCT and entry.BuildingType then
        local def = GameInfo.Buildings[entry.BuildingType]
        if def then return Locale.Lookup(def.Name) end
    elseif entry.Directive == CityProductionDirectives.ZONE and entry.DistrictType then
        local def = GameInfo.Districts[entry.DistrictType]
        if def then return Locale.Lookup(def.Name) end
    elseif entry.Directive == CityProductionDirectives.PROJECT and entry.ProjectType then
        local def = GameInfo.Projects[entry.ProjectType]
        if def then return Locale.Lookup(def.Name) end
    end
    return ""
end

function NormalizeCAITab(tab)
    -- Older CAI code used a separate manager tab at index 5; map it to queue.
    if tab == 5 then
        return TAB_QUEUE
    end

    return tab
end

function IsQueueModeTab(tab)
    return NormalizeCAITab(tab) == TAB_QUEUE
end

function GetQueueEntryName(queueIndex)
    if not m_caiData or not m_caiData.City then return "" end

    local pBuildQueue = m_caiData.City:GetBuildQueue()
    if not pBuildQueue then return "" end

    return MakeQueueEntryDescription(pBuildQueue:GetAt(queueIndex))
end

function GetQueueRowCount()
    local count = 0
    if not m_caiData or not m_caiData.City then return count end

    local pBuildQueue = m_caiData.City:GetBuildQueue()
    if not pBuildQueue then return count end

    for i = 1, MAX_QUEUE_SIZE do
        if pBuildQueue:GetAt(i) ~= nil then
            count = i
        end
    end

    return count
end

function GetQueueInstance(queueIndex)
    if not queueIndex or not m_QueueInstanceIM or not m_QueueInstanceIM.GetAllocatedInstance then
        return nil
    end
    return m_QueueInstanceIM:GetAllocatedInstance(queueIndex)
end

function GetFocusedQueueRow()
    local focused = mgr and mgr.GetFocusedWidget and mgr:GetFocusedWidget() or nil
    if focused and focused._caiQueueIndex then
        return focused
    end
    return nil
end

function GetFocusedQueueListIndex()
    if not m_caiQueueList or not m_caiQueueList.Children or not mgr or not mgr.GetFocusedWidget then
        return nil
    end

    local focused = mgr:GetFocusedWidget()
    if not focused then return nil end

    for idx, child in ipairs(m_caiQueueList.Children) do
        if child == focused then
            return idx
        end
    end

    return nil
end

function GetCurrentProductionName()
    if Controls.CurrentProductionName and Controls.CurrentProductionName.GetText then
        return Controls.CurrentProductionName:GetText() or ""
    end
    return ""
end

function RemoveQueueIndex(queueIndex, name)
    if queueIndex == nil or queueIndex < 0 then return true end

    m_caiQueueFocusIndexAfterRebuild = GetFocusedQueueListIndex()
    UI.PlaySound("Play_UI_Click")
    Speak(Locale.Lookup("LOC_CAI_PRODUCTION_QUEUE_REMOVED", name))
    RemoveQueueItem(queueIndex)
    return true
end

function RemoveFocusedQueueItem()
    local row = GetFocusedQueueRow()
    if row and row._caiQueueIndex and row._caiQueueName then
        return RemoveQueueIndex(row._caiQueueIndex, row._caiQueueName)
    end

    return false
end

function MoveQueueSelection(direction)
    local row = GetFocusedQueueRow()
    local queueIndex = row and row._caiQueueIndex or -1
    local rowName = row and row._caiQueueName or ""

    if queueIndex == -1 then return false end

    local targetIndex = queueIndex + direction
    if targetIndex < 1 or targetIndex > GetQueueRowCount() then
        if rowName ~= "" then
            if direction < 0 then
                Speak(Locale.Lookup("LOC_CAI_PRODUCTION_QUEUE_ALREADY_FIRST", rowName))
            else
                Speak(Locale.Lookup("LOC_CAI_PRODUCTION_QUEUE_ALREADY_LAST", rowName))
            end
        end
        return true
    end

    m_caiQueueFocusIndexAfterRebuild = targetIndex + 1
    SwapQueueItem(queueIndex, targetIndex)
    if rowName ~= "" then
        if direction < 0 then
            Speak(Locale.Lookup("LOC_CAI_PRODUCTION_QUEUE_MOVED_UP", rowName))
        else
            Speak(Locale.Lookup("LOC_CAI_PRODUCTION_QUEUE_MOVED_DOWN", rowName))
        end
    end
    return true
end

function RemoveCurrentProductionFromQueue()
    local name = GetCurrentProductionName()
    if name == "" then return true end

    m_caiQueueFocusIndexAfterRebuild = GetFocusedQueueListIndex()
    UI.PlaySound("Play_UI_Click")
    Speak(Locale.Lookup("LOC_CAI_PRODUCTION_CURRENT_REMOVED", name))
    RemoveQueueItem(0)
    return true
end

function CreateQueueRowWidget(queueIndex, name)
    local row = mgr:CreateUIWidget("Button", {
        GetLabel = function() return name end,
        OnClick = function() return true end,
        OnFocusEnter = function(w)
            PlayMenuHover()
        end,
    })

    row._caiFocusKey = "queue:" .. tostring(queueIndex)
    row._caiQueueIndex = queueIndex
    row._caiQueueName = name

    row:AddInputBindings({
        {
            Key = Keys.VK_DELETE,
            Action = function()
                return RemoveFocusedQueueItem()
            end,
        },
        {
            Key = Keys.VK_UP,
            MSG = KeyEvents.KeyDown,
            IsShift = true,
            Action = function()
                return MoveQueueSelection(-1)
            end,
        },
        {
            Key = Keys.VK_DOWN,
            MSG = KeyEvents.KeyDown,
            IsShift = true,
            Action = function()
                return MoveQueueSelection(1)
            end,
        },
    })

    return row
end

function CreateQueueCurrentWidget()
    local row = mgr:CreateUIWidget("Button", {
        GetLabel = ReadCurrentProductionLabel,
        GetTooltip = ReadCurrentProductionTooltip,
        OnClick = function() return true end,
        OnFocusEnter = function()
            PlayMenuHover()
            SetFocusedDetailText("current", ReadCurrentProductionTooltip())
        end,
    })

    row._caiFocusKey = "current"

    row:AddInputBindings({
        {
            Key = Keys.VK_DELETE,
            Action = function()
                return RemoveCurrentProductionFromQueue()
            end,
        },
    })

    return row
end

function RebuildQueueList()
    if not m_caiQueueList then return end

    local focusIndex = m_caiQueueFocusIndexAfterRebuild or GetFocusedQueueListIndex()
    m_caiQueueList:ClearChildren()

    m_caiQueueList:AddChild(CreateQueueCurrentWidget())

    if m_caiData and m_caiData.City then
        local pBuildQueue = m_caiData.City:GetBuildQueue()
        if pBuildQueue then
            for i = 1, MAX_QUEUE_SIZE do
                local entry = pBuildQueue:GetAt(i)
                if entry then
                    local desc = MakeQueueEntryDescription(entry)
                    if desc ~= "" then
                        m_caiQueueList:AddChild(CreateQueueRowWidget(i, desc))
                    end
                end
            end
        end
    end

    if focusIndex and mgr and m_caiPanel and mgr:HasWidget(m_caiPanel) then
        m_caiQueueList:SetFocusedChild(focusIndex)
    end
    m_caiQueueFocusIndexAfterRebuild = nil
end

function FillQueueNode()
    if not m_caiQueueNode then return end
    m_caiQueueNode:ClearChildren()
    if not m_caiData or not m_caiData.City then return end

    local pBuildQueue = m_caiData.City:GetBuildQueue()
    if not pBuildQueue then return end

    for i = 1, MAX_QUEUE_SIZE do
        local entry = pBuildQueue:GetAt(i)
        if entry then
            local desc = MakeQueueEntryDescription(entry)
            if desc ~= "" then
                m_caiQueueNode:AddChild(CreateQueueRowWidget(i, desc))
            end
        end
    end
end

function ApplyTabVisibility(tab)
    tab = NormalizeCAITab(tab)
    local isProduction = tab == TAB_PRODUCTION
    local isPurchase = tab == TAB_PURCHASE_GOLD or tab == TAB_PURCHASE_FAITH
    local isQueue = tab == TAB_QUEUE

    if m_caiTree then m_caiTree._caiHidden = isQueue end
    if m_caiQueueList then m_caiQueueList._caiHidden = not isQueue end
    if m_caiCurrentNode then m_caiCurrentNode._caiHidden = not (isProduction or isQueue) end
    if m_caiQueueNode then m_caiQueueNode._caiHidden = not isQueue end
    if m_caiCatDistricts then m_caiCatDistricts._caiHidden = not (isProduction or isPurchase) end
    if m_caiCatWonders then m_caiCatWonders._caiHidden = not isProduction end
    if m_caiCatBuildings then m_caiCatBuildings._caiHidden = not isPurchase end
    if m_caiCatUnits then m_caiCatUnits._caiHidden = not (isProduction or isPurchase) end
    if m_caiCatProjects then m_caiCatProjects._caiHidden = not isProduction end
end

function GetFocusedTreeItem()
    if not m_caiTree then return nil end
    return mgr.WidgetTemplateHelpers:GetFocusedTreeItem(m_caiTree)
end

function InvokePrimaryAction(node, leftAction)
    if not node then return false end
    if node.IsDisabled and node:IsDisabled() then return true end
    if leftAction then
        leftAction(node)
        return true
    end
    if not node.IsLeaf or (type(node.IsLeaf) == "function" and not node:IsLeaf()) then
        return mgr.WidgetTemplateHelpers:ToggleTreeItem(node)
    end
    return false
end

function OnTreeExpandOrDescend()
    local item = GetFocusedTreeItem()
    if not item then return false end
    if type(item.IsLeaf) == "function" and item:IsLeaf() then return false end
    if mgr.WidgetTemplateHelpers:ExpandTreeItem(item) then
        return true
    end
    return mgr.WidgetTemplateHelpers:FocusTreeFirstChild(item)
end

function OnTreeCollapseOrAscend()
    local item = GetFocusedTreeItem()
    if not item then return false end
    if mgr.WidgetTemplateHelpers:CollapseTreeItem(item) then
        return true
    end
    return mgr.WidgetTemplateHelpers:FocusParentTreeItem(m_caiTree, item)
end

function RebuildBody(preserveTreeFocus)
    if not m_caiPanel then return end

    local activeTab = NormalizeCAITab(m_caiTab)
    if activeTab == TAB_QUEUE then
        RebuildQueueList()
        ApplyTabVisibility(activeTab)
        m_caiLastBuiltTab = activeTab
        m_caiLastBuiltCityID = m_caiData and m_caiData.City and m_caiData.City:GetID() or nil
        m_caiLastBuiltPlayerID = m_caiData and m_caiData.Owner or nil
        m_caiLastDetailFocusKey = nil
        SetDetailText("")
        return
    end

    local focusPath = nil
    if preserveTreeFocus ~= false then
        focusPath = mgr:CaptureFocusIndexPath(m_caiTree)
    end
    local items = GetItemsForTab(activeTab)
    if activeTab == TAB_PRODUCTION then
        FillProductionDistrictsNode(m_caiCatDistricts, items.Districts, items.Buildings)
        FillCategoryNode(m_caiCatBuildings, nil, activeTab, false)
    else
        FillCategoryNode(m_caiCatDistricts, items.Districts, activeTab, false)
        FillCategoryNode(m_caiCatBuildings, items.Buildings, activeTab, false)
    end
    FillCategoryNode(m_caiCatWonders, items.Wonders, activeTab, false)
    FillCategoryNode(m_caiCatUnits, items.Units, activeTab, true)
    FillCategoryNode(m_caiCatProjects, items.Projects, activeTab, false)
    FillQueueNode()
    ApplyTabVisibility(activeTab)

    m_caiLastBuiltTab = activeTab
    m_caiLastBuiltCityID = m_caiData and m_caiData.City and m_caiData.City:GetID() or nil
    m_caiLastBuiltPlayerID = m_caiData and m_caiData.Owner or nil
    m_caiLastDetailFocusKey = nil
    SetDetailText("")

    if focusPath and m_caiPanel and mgr and mgr:HasWidget(m_caiPanel) then
        mgr:SetFocusIndexPath(m_caiTree, focusPath)
    end
end

function CreateTabWidget(index, vanillaTabControl, vanillaHandler)
    return mgr:CreateUIWidget("Tab", {
        GetLabel = function()
            if vanillaTabControl and vanillaTabControl.GetText then
                return vanillaTabControl:GetText() or ""
            end
            return ""
        end,
        OnFocusEnter = function()
            PlayMenuHover()
            local nextTab = NormalizeCAITab(index)
            if vanillaHandler then vanillaHandler() end
            if m_caiTab ~= nextTab then
                m_caiTab = nextTab
                m_caiLastDetailFocusKey = nil
                RebuildBody(false)
            else
                m_caiTab = nextTab
            end
        end,
    })
end

function MakeCategoryLabel(getListRef, fallback)
    return function()
        local list = getListRef and getListRef() or nil
        if list and list.Header and list.Header.GetText then
            local t = list.Header:GetText()
            if t and t ~= "" then return t end
        end
        if type(fallback) == "function" then return fallback() end
        if fallback == nil then return "" end
        return Locale.Lookup(fallback)
    end
end

function GetSelectedTabDefaultIndex()
    local defaultIndex = 1

    for index, tab in ipairs(m_caiTabBar.Children or {}) do
        if tab == m_caiTabs[m_caiTab] then
            defaultIndex = index
            break
        end
    end

    return defaultIndex
end

function CreateCategoryNode(focusKey, getLabel, getListRef, hidable)
    return CreateActionNode({
        FocusKey = focusKey,
        GetLabel = getLabel,
        IsExpanded = true,
        IsHidden = function(w)
            if hidable and w._caiHidden then return true end
            return not w.Children or #w.Children == 0
        end,
        OnToggleExpanded = function(expanded)
            local list = getListRef and getListRef() or nil
            if not list then return end
            if expanded then OnExpand(list) else OnCollapse(list) end
        end,
        FocusAction = function(w)
            PlayMenuHover()
            SetFocusedDetailText((w and w._caiFocusKey) or focusKey, getLabel())
        end,
    })
end

function RefreshRecommendations()
    m_caiRecommended = {}
    if not m_caiData or not m_caiData.City then return end
    local cityAI = m_caiData.City.GetCityAI and m_caiData.City:GetCityAI() or nil
    if not cityAI then return end
    local recs = cityAI.GetBuildRecommendations and cityAI:GetBuildRecommendations() or nil
    if not recs then return end
    for _, kItem in ipairs(recs) do
        m_caiRecommended[kItem.BuildItemHash] = true
    end
end

function EnsurePanelBuilt()
    if m_caiPanel then return end

    m_caiPanel = mgr:CreateUIWidget("Panel", {
        GetLabel = function() return Locale.Lookup("LOC_HUD_CHOOSE_PRODUCTION") end,
    })

    m_caiTabBar = mgr:CreateUIWidget("TabBar", {
        GetLabel = function() return Locale.Lookup("LOC_HUD_CHOOSE_PRODUCTION") end,
    })
    m_caiPanel:AddChild(m_caiTabBar)

    m_caiTabs[TAB_PRODUCTION] = CreateTabWidget(TAB_PRODUCTION, Controls.ProductionTab, OnTabChangeProduction)
    m_caiTabs[TAB_PURCHASE_GOLD] = CreateTabWidget(TAB_PURCHASE_GOLD, Controls.PurchaseTab, OnTabChangePurchase)
    m_caiTabs[TAB_PURCHASE_FAITH] = CreateTabWidget(TAB_PURCHASE_FAITH, Controls.PurchaseFaithTab,
        OnTabChangePurchaseFaith)
    m_caiTabs[TAB_QUEUE] = CreateTabWidget(TAB_QUEUE, Controls.QueueTab, OnTabChangeQueue)

    m_caiTabBar:AddChild(m_caiTabs[TAB_PRODUCTION])
    if GameCapabilities.HasCapability("CAPABILITY_GOLD") then
        m_caiTabBar:AddChild(m_caiTabs[TAB_PURCHASE_GOLD])
    end
    if GameCapabilities.HasCapability("CAPABILITY_FAITH") then
        m_caiTabBar:AddChild(m_caiTabs[TAB_PURCHASE_FAITH])
    end
    if CurrentTabSupportsQueue() then
        m_caiTabBar:AddChild(m_caiTabs[TAB_QUEUE])
    end
    m_caiTabBar.DefaultIndex = GetSelectedTabDefaultIndex()

    m_caiTree = mgr:CreateUIWidget("Treeview", {
        GetLabel = function() return Locale.Lookup("LOC_HUD_CHOOSE_PRODUCTION") end,
        IsHidden = function(w) return w._caiHidden end,
    })
    m_caiTree:AddInputBindings({
        {
            Key = Keys.VK_RIGHT,
            MSG = KeyEvents.KeyDown,
            Action = function()
                return
                    OnTreeExpandOrDescend()
            end
        },
        {
            Key = Keys.VK_LEFT,
            MSG = KeyEvents.KeyDown,
            Action = function()
                return
                    OnTreeCollapseOrAscend()
            end
        },
        {
            Key = Keys.VK_DELETE,
            Action = function()
                local focused = GetFocusedTreeItem()
                if focused == m_caiCurrentNode then
                    return RemoveCurrentProductionFromQueue()
                end
                if not IsQueueModeTab(m_caiTab) then return false end
                return RemoveFocusedQueueItem()
            end,
        },
        {
            Key = Keys.VK_UP,
            MSG = KeyEvents.KeyDown,
            IsShift = true,
            Action = function()
                if not IsQueueModeTab(m_caiTab) then return false end
                return MoveQueueSelection(-1)
            end,
        },
        {
            Key = Keys.VK_DOWN,
            MSG = KeyEvents.KeyDown,
            IsShift = true,
            Action = function()
                if not IsQueueModeTab(m_caiTab) then return false end
                return MoveQueueSelection(1)
            end,
        },
    })
    m_caiPanel:AddChild(m_caiTree)

    m_caiQueueList = mgr:CreateUIWidget("List", {
        GetLabel = function() return Locale.Lookup("LOC_CAI_PRODUCTION_QUEUE_LIST") end,
        IsHidden = function(w) return w._caiHidden end,
    })
    m_caiPanel:AddChild(m_caiQueueList)

    m_caiCurrentNode = mgr:CreateUIWidget("TreeviewItem", {
        GetLabel = ReadCurrentProductionLabel,
        GetTooltip = ReadCurrentProductionTooltip,
        IsHidden = function(w) return w._caiHidden end,
        OnFocusEnter = function()
            PlayMenuHover()
            SetFocusedDetailText("current-tree", ReadCurrentProductionTooltip())
        end,
    })
    m_caiCurrentNode._caiFocusKey = "current"
    m_caiCurrentNode:AddInputBinding({
        Key = Keys.VK_RETURN,
        Action = function()
            if Controls.CurrentProductionButton and Controls.CurrentProductionButton.IsDisabled and Controls.CurrentProductionButton:IsDisabled() then
                return true
            end
            OnItemClicked(Controls, Controls.CurrentProductionButton)
            return true
        end,
    })
    m_caiCurrentNode:AddInputBinding({
        Key = Keys.VK_DELETE,
        Action = function()
            return RemoveCurrentProductionFromQueue()
        end,
    })
    m_caiTree:AddChild(m_caiCurrentNode)

    m_caiQueueNode = CreateActionNode({
        FocusKey = "queue-root",
        GetLabel = function() return Locale.Lookup("LOC_CAI_PRODUCTION_QUEUE_LIST") end,
        IsExpanded = true,
        IsHidden = function(w)
            if w._caiHidden then return true end
            return not w.Children or #w.Children == 0
        end,
        FocusAction = function(w)
            PlayMenuHover()
            SetFocusedDetailText((w and w._caiFocusKey) or "queue-root", Locale.Lookup("LOC_CAI_PRODUCTION_QUEUE_LIST"))
        end,
    })
    m_caiTree:AddChild(m_caiQueueNode)

    m_caiCatDistricts = CreateCategoryNode(
        "cat:districts",
        MakeCategoryLabel(function() return m_caiDistrictList end, function()
            if NormalizeCAITab(m_caiTab) == TAB_PRODUCTION then
                return Locale.Lookup("LOC_HUD_DISTRICTS_BUILDINGS")
            end
            return Locale.Lookup("LOC_HUD_DISTRICTS")
        end),
        function() return m_caiDistrictList end,
        false
    )
    m_caiTree:AddChild(m_caiCatDistricts)

    m_caiCatWonders = CreateCategoryNode(
        "cat:wonders",
        MakeCategoryLabel(function() return m_caiWonderList end, "LOC_HUD_CITY_WONDERS"),
        function() return m_caiWonderList end,
        true
    )
    m_caiTree:AddChild(m_caiCatWonders)

    m_caiCatBuildings = CreateCategoryNode(
        "cat:buildings",
        MakeCategoryLabel(function() return m_caiBuildingList end, "LOC_HUD_BUILDINGS"),
        function() return m_caiBuildingList end,
        false
    )
    m_caiTree:AddChild(m_caiCatBuildings)

    m_caiCatUnits = CreateCategoryNode(
        "cat:units",
        MakeCategoryLabel(function() return m_caiUnitList end, "LOC_TECH_FILTER_UNITS"),
        function() return m_caiUnitList end,
        false
    )
    m_caiTree:AddChild(m_caiCatUnits)

    m_caiCatProjects = CreateCategoryNode(
        "cat:projects",
        MakeCategoryLabel(function() return m_caiProjectList end, "LOC_HUD_PROJECTS"),
        function() return m_caiProjectList end,
        true
    )
    m_caiTree:AddChild(m_caiCatProjects)

    m_caiDetailEdit = mgr:CreateUIWidget("Edit", {
        GetLabel = function() return Locale.Lookup("LOC_CAI_PRODUCTION_DETAIL_LABEL") end,
        GetValue = function() return m_caiDetailEdit and m_caiDetailEdit.EditBuffer or "" end,
        AlwaysEdit = true,
        EditReadOnly = true,
        HighlightOnEdit = false,
        EditBuffer = "",
    })
    m_caiPanel:AddChild(m_caiDetailEdit)

    m_caiCloseBtn = mgr:CreateUIWidget("Button", {
        GetLabel = function()
            if Controls.CloseButton and type(Controls.CloseButton.GetToolTipString) == "function" then
                local tip = Controls.CloseButton:GetToolTipString()
                if tip and tip ~= "" then return tip end
            end
            return Locale.Lookup("LOC_HUD_CLOSE")
        end,
        OnClick = function() Close() end,
        OnFocusEnter = function() PlayMenuHover() end,
    })
    m_caiPanel:AddChild(m_caiCloseBtn)

    ApplyTabVisibility(NormalizeCAITab(m_caiTab))
end

function OnPanelOpenedCAI()
    if m_CurrentListMode == LISTMODE.PROD_QUEUE then
        m_caiTab = TAB_QUEUE
    else
        m_caiTab = NormalizeCAITab(m_caiTab)
    end
    EnsurePanelBuilt()
    if m_caiTabBar then
        m_caiTabBar.DefaultIndex = GetSelectedTabDefaultIndex()
    end
    if mgr:HasWidget(m_caiPanel) then return end
    m_caiOpenPending = true
end

function OnPanelClosedCAI()
    if m_caiPanel and mgr:HasWidget(m_caiPanel) then
        mgr:Pop()
    end
    m_caiPanel = nil
    m_caiTabBar = nil
    m_caiTabs = {}
    m_caiTree = nil
    m_caiQueueList = nil
    m_caiCurrentNode = nil
    m_caiQueueNode = nil
    m_caiCatDistricts = nil
    m_caiCatWonders = nil
    m_caiCatBuildings = nil
    m_caiCatUnits = nil
    m_caiCatProjects = nil
    m_caiDetailEdit = nil
    m_caiCloseBtn = nil
    m_caiData = nil
    m_caiRecommended = {}
    m_caiInstanceByHash = {}
    m_caiWonderList = nil
    m_caiProjectList = nil
    m_caiDistrictList = nil
    m_caiBuildingList = nil
    m_caiUnitList = nil
    m_caiInstancesByModeHash = {}
    m_caiCaptureListMode = nil
    m_caiOpenPending = false
    m_caiLastBuiltTab = nil
    m_caiLastBuiltCityID = nil
    m_caiLastBuiltPlayerID = nil
    m_caiLastDetailFocusKey = nil
end

PopulateGenericItemData = WrapFunc(PopulateGenericItemData, function(orig, kInstance, kItem)
    orig(kInstance, kItem)
    if kItem and kItem.Hash then
        m_caiInstanceByHash[kItem.Hash] = kInstance
        if m_caiCaptureListMode then
            if not m_caiInstancesByModeHash[m_caiCaptureListMode] then
                m_caiInstancesByModeHash[m_caiCaptureListMode] = {}
            end
            m_caiInstancesByModeHash[m_caiCaptureListMode][kItem.Hash] = kInstance
        end
    end
end)

PopulateList = WrapFunc(PopulateList, function(orig, data, listMode, listIM)
    m_caiCaptureListMode = listMode
    local result = orig(data, listMode, listIM)
    m_caiCaptureListMode = nil
    return result
end)

function WrapPopulateCapture(origFunc, captureFn)
    return WrapFunc(origFunc, function(orig, data, listMode, listIM)
        local before = listIM and listIM.m_iAllocatedInstances or 0
        orig(data, listMode, listIM)
        local after = listIM and listIM.m_iAllocatedInstances or 0
        for i = before + 1, after do
            local inst = listIM.m_AllocatedInstances and listIM.m_AllocatedInstances[i]
            if inst then captureFn(inst, i - before) end
        end
    end)
end

PopulateWonders = WrapPopulateCapture(PopulateWonders, function(inst)
    m_caiWonderList = inst
end)

PopulateProjects = WrapPopulateCapture(PopulateProjects, function(inst)
    m_caiProjectList = inst
end)

PopulateUnits = WrapPopulateCapture(PopulateUnits, function(inst)
    m_caiUnitList = inst
end)

PopulateDistrictsWithNestedBuildings = WrapPopulateCapture(PopulateDistrictsWithNestedBuildings, function(inst)
    m_caiDistrictList = inst
end)

PopulateDistrictsWithoutNestedBuildings = WrapPopulateCapture(PopulateDistrictsWithoutNestedBuildings,
    function(inst, idx)
        if idx == 1 then
            m_caiDistrictList = inst
        else
            m_caiBuildingList = inst
        end
    end)

View = WrapFunc(View, function(orig, data)
    m_caiInstanceByHash = {}
    m_caiInstancesByModeHash = {}
    m_caiWonderList = nil
    m_caiProjectList = nil
    m_caiDistrictList = nil
    m_caiBuildingList = nil
    m_caiUnitList = nil
    m_caiCaptureListMode = nil

    m_caiData = data
    orig(data)
    RefreshRecommendations()
    EnsurePanelBuilt()
    local activeTab = NormalizeCAITab(m_caiTab)
    local cityID = data and data.City and data.City:GetID() or nil
    local ownerID = data and data.Owner or nil
    local shouldRebuild = activeTab == TAB_QUEUE
        or m_caiLastBuiltTab ~= activeTab
        or m_caiLastBuiltCityID ~= cityID
        or m_caiLastBuiltPlayerID ~= ownerID

    if shouldRebuild then
        RebuildBody()
    end

    if m_caiOpenPending and m_caiPanel and mgr and not mgr:HasWidget(m_caiPanel) then
        m_caiOpenPending = false
        mgr:Push(m_caiPanel, PopupPriority.Low)
    end
end)

RefreshQueue = WrapFunc(RefreshQueue, function(orig, playerID, cityID)
    orig(playerID, cityID)
end)

OnManagerSelectedIndexChanged = WrapFunc(OnManagerSelectedIndexChanged, function(orig, newIndex)
    orig(newIndex)
end)

SwapQueueItem = WrapFunc(SwapQueueItem, function(orig, fromIndex, toIndex)
    return orig(fromIndex, toIndex)
end)

RemoveQueueItem = WrapFunc(RemoveQueueItem, function(orig, queueIndex)
    return orig(queueIndex)
end)

OnCorpsToggle = WrapFunc(OnCorpsToggle, function(orig, unitList, unitListing)
    orig(unitList, unitListing)
    if m_caiPanel and mgr and mgr:HasWidget(m_caiPanel) and (m_caiTab == TAB_PRODUCTION or m_caiTab == TAB_PURCHASE_GOLD or m_caiTab == TAB_PURCHASE_FAITH) then
        RebuildBody()
    end
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
    local handled = (mgr and mgr:HandleInput(pInputStruct)) or false
    if handled then
        return true
    end
    return orig(pInputStruct)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)

BuildBuilding = WrapFunc(BuildBuilding, function(orig, city, entry)
    if not m_caiQueueActionActive and entry and entry.Name then
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_CHOSEN", Locale.Lookup(entry.Name)))
    end
    return orig(city, entry)
end)

ZoneDistrict = WrapFunc(ZoneDistrict, function(orig, city, entry)
    if not m_caiQueueActionActive and entry and entry.Name then
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_CHOSEN", Locale.Lookup(entry.Name)))
    end
    return orig(city, entry)
end)

BuildUnit = WrapFunc(BuildUnit, function(orig, city, entry)
    if not m_caiQueueActionActive and entry and entry.Name then
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_CHOSEN", Locale.Lookup(entry.Name)))
    end
    return orig(city, entry)
end)

BuildUnitCorps = WrapFunc(BuildUnitCorps, function(orig, city, entry)
    if not m_caiQueueActionActive and entry and entry.Name then
        local n = WithFormationSuffix(Locale.Lookup(entry.Name), "corps")
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_CHOSEN", n))
    end
    return orig(city, entry)
end)

BuildUnitArmy = WrapFunc(BuildUnitArmy, function(orig, city, entry)
    if not m_caiQueueActionActive and entry and entry.Name then
        local n = WithFormationSuffix(Locale.Lookup(entry.Name), "army")
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_CHOSEN", n))
    end
    return orig(city, entry)
end)

AdvanceProject = WrapFunc(AdvanceProject, function(orig, city, entry)
    if not m_caiQueueActionActive and entry and entry.Name then
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_CHOSEN", Locale.Lookup(entry.Name)))
    end
    return orig(city, entry)
end)

PurchaseUnit = WrapFunc(PurchaseUnit, function(orig, city, entry)
    if entry and entry.Name then
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_PURCHASED", Locale.Lookup(entry.Name)))
    end
    return orig(city, entry)
end)

PurchaseUnitCorps = WrapFunc(PurchaseUnitCorps, function(orig, city, entry)
    if entry and entry.Name then
        local n = WithFormationSuffix(Locale.Lookup(entry.Name), "corps")
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_PURCHASED", n))
    end
    return orig(city, entry)
end)

PurchaseUnitArmy = WrapFunc(PurchaseUnitArmy, function(orig, city, entry)
    if entry and entry.Name then
        local n = WithFormationSuffix(Locale.Lookup(entry.Name), "army")
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_PURCHASED", n))
    end
    return orig(city, entry)
end)

PurchaseBuilding = WrapFunc(PurchaseBuilding, function(orig, city, entry)
    if entry and entry.Name then
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_PURCHASED", Locale.Lookup(entry.Name)))
    end
    return orig(city, entry)
end)

PurchaseDistrict = WrapFunc(PurchaseDistrict, function(orig, city, entry)
    if entry and entry.Name then
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_PURCHASED", Locale.Lookup(entry.Name)))
    end
    return orig(city, entry)
end)

LuaEvents.ProductionPanel_Open.Add(OnPanelOpenedCAI)
LuaEvents.ProductionPanel_Close.Add(OnPanelClosedCAI)

function RefreshIfOpen()
    if m_caiPanel and mgr and mgr:HasWidget(m_caiPanel) and RefreshView then
        RefreshView()
    end
end

if Events then
    if Events.CityProductionChanged then Events.CityProductionChanged.Add(RefreshIfOpen) end
    if Events.CityProductionUpdated then Events.CityProductionUpdated.Add(RefreshIfOpen) end
    if Events.CityWorkersChanged then Events.CityWorkersChanged.Add(RefreshIfOpen) end
end
