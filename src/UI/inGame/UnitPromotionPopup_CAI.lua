include("caiUtils")
include("UnitPromotionPopup")

local mgr               = ExposedMembers.CAI_UIManager

local PANEL_ID          = "CAIUnitPromotionPopup_Panel"
local TABLE_ID          = "CAIUnitPromotionPopup_Table"
local TREE_ID           = "CAIUnitPromotionPopup_Tree"
local CHANGE_VIEW_ID    = "CAIUnitPromotionPopup_ChangeView"

local HOVER_SOUND       = "Main_Menu_Mouse_Over"

local m_panel           = nil
local m_tableView       = nil
local m_treeView        = nil
local m_changeViewBtn   = nil
local m_viewMode        = "table"

local m_model           = nil
local m_tablePromotions = {}
local m_treePromotions  = {}

local function JoinNonEmpty(parts, sep)
    local out = {}
    for _, part in ipairs(parts) do
        if part ~= nil and part ~= "" then out[#out + 1] = part end
    end
    return table.concat(out, sep)
end

local function BuildSet(values)
    local set = {}
    if values then
        for _, value in pairs(values) do set[value] = true end
    end
    return set
end

local function GetPromotionLevel(promo)
    return promo and tonumber(promo.Level) or 0
end

local function GetPromotionColumn(promo)
    return promo and tonumber(promo.Column) or 1
end

local function GetPromotionName(promo)
    if not promo then return "" end
    return Locale.Lookup(promo.Name)
end

local function GetPromotionStatus(promo)
    if not m_model or not promo then return "" end
    if m_model.earned[promo.Index] then
        return Locale.Lookup("LOC_CAI_UNIT_PROMOTION_STATUS_EARNED")
    elseif m_model.available[promo.Index] then
        return Locale.Lookup("LOC_CAI_UNIT_PROMOTION_STATUS_AVAILABLE")
    end
    return Locale.Lookup("LOC_CAI_UNIT_PROMOTION_STATUS_LOCKED")
end

local function GetPromotionLabel(promo)
    return Locale.Lookup("LOC_CAI_UNIT_PROMOTION_LABEL", GetPromotionName(promo), GetPromotionStatus(promo))
end

local function FormatPromotionPrereqs(types)
    local names = {}
    if types then
        for _, promotionType in ipairs(types) do
            local promo = m_model and m_model.byType[promotionType]
            if promo then names[#names + 1] = GetPromotionName(promo) end
        end
    end
    return table.concat(names, ", or ")
end

local function FormatPromotionLeadTos(types)
    local names = {}
    if types then
        for _, promotionType in ipairs(types) do
            local promo = m_model and m_model.byType[promotionType]
            if promo then names[#names + 1] = GetPromotionName(promo) end
        end
    end
    return table.concat(names, ", and ")
end

local function GetPromotionTooltip(promo, includeLinks)
    if not promo then return "" end

    local parts = {}
    parts[#parts + 1] = Locale.Lookup(promo.Description)

    if includeLinks ~= false and m_model then
        local prereqText = FormatPromotionPrereqs(m_model.prereqs[promo.UnitPromotionType])
        if prereqText ~= "" then
            parts[#parts + 1] = Locale.Lookup("LOC_CAI_UNIT_PROMOTION_PREREQS_HEADER", prereqText)
        end

        local leadsToText = FormatPromotionLeadTos(m_model.leadsTo[promo.UnitPromotionType])
        if leadsToText ~= "" then
            parts[#parts + 1] = Locale.Lookup("LOC_CAI_UNIT_PROMOTION_LEADS_TO_HEADER", leadsToText)
        end
    end

    return JoinNonEmpty(parts, "[NEWLINE]")
end

local function SortPromotionTypesByLayout(types, model)
    local promotionModel = model or m_model
    table.sort(types, function(a, b)
        local pa = promotionModel and promotionModel.byType[a]
        local pb = promotionModel and promotionModel.byType[b]
        if not pa or not pb then return tostring(a) < tostring(b) end
        local levelA = GetPromotionLevel(pa)
        local levelB = GetPromotionLevel(pb)
        if levelA ~= levelB then return levelA < levelB end
        local columnA = GetPromotionColumn(pa)
        local columnB = GetPromotionColumn(pb)
        if columnA ~= columnB then return columnA < columnB end
        return Locale.Compare(GetPromotionName(pa), GetPromotionName(pb)) < 0
    end)
end

local function BuildPromotionModel()
    local unit = UI.GetHeadSelectedUnit()
    if not unit then return nil end

    local unitDef = GameInfo.Units[unit:GetUnitType()]
    if not unitDef or not unitDef.PromotionClass then return nil end

    local canStart, results = UnitManager.CanStartCommand(unit, UnitCommandTypes.PROMOTE, true, true)
    local availableList = (canStart and results) and results[UnitCommandResults.PROMOTIONS] or {}

    local unitExperience = unit:GetExperience()
    local earnedList = unitExperience and unitExperience:GetPromotions() or {}

    local model = {
        unitId = unit:GetID(),
        promotionClass = unitDef.PromotionClass,
        promotions = {},
        byType = {},
        byLevel = {},
        levels = {},
        available = BuildSet(availableList),
        earned = BuildSet(earnedList),
        prereqs = {},
        leadsTo = {},
    }

    for promo in GameInfo.UnitPromotions() do
        if promo.PromotionClass == model.promotionClass then
            local level = GetPromotionLevel(promo)
            model.promotions[#model.promotions + 1] = promo
            model.byType[promo.UnitPromotionType] = promo
            if not model.byLevel[level] then
                model.byLevel[level] = {}
                model.levels[#model.levels + 1] = level
            end
            model.byLevel[level][#model.byLevel[level] + 1] = promo
        end
    end

    table.sort(model.levels)
    table.sort(model.promotions, function(a, b)
        local levelA = GetPromotionLevel(a)
        local levelB = GetPromotionLevel(b)
        if levelA ~= levelB then return levelA < levelB end
        local columnA = GetPromotionColumn(a)
        local columnB = GetPromotionColumn(b)
        if columnA ~= columnB then return columnA < columnB end
        return Locale.Compare(GetPromotionName(a), GetPromotionName(b)) < 0
    end)

    for _, level in ipairs(model.levels) do
        table.sort(model.byLevel[level], function(a, b)
            local columnA = GetPromotionColumn(a)
            local columnB = GetPromotionColumn(b)
            if columnA ~= columnB then return columnA < columnB end
            return Locale.Compare(GetPromotionName(a), GetPromotionName(b)) < 0
        end)
    end

    for prereq in GameInfo.UnitPromotionPrereqs() do
        if model.byType[prereq.UnitPromotion] and model.byType[prereq.PrereqUnitPromotion] then
            local target = prereq.UnitPromotion
            local source = prereq.PrereqUnitPromotion

            if not model.prereqs[target] then model.prereqs[target] = {} end
            model.prereqs[target][#model.prereqs[target] + 1] = source

            if not model.leadsTo[source] then model.leadsTo[source] = {} end
            model.leadsTo[source][#model.leadsTo[source] + 1] = target
        end
    end

    for _, list in pairs(model.prereqs) do SortPromotionTypesByLayout(list, model) end
    for _, list in pairs(model.leadsTo) do SortPromotionTypesByLayout(list, model) end

    return model
end

local function IsPromotionAvailable(promo)
    return m_model ~= nil and promo ~= nil and m_model.available[promo.Index] == true
end

local function RequestPromotion(promo)
    if not IsPromotionAvailable(promo) then return end

    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == -1 or localPlayerID == PlayerTypes.NONE then return end

    local pPlayer = Players[localPlayerID]
    local pUnit = pPlayer and pPlayer:GetUnits():FindID(m_model.unitId)
    if not pUnit then return end

    local params = {}
    params[UnitCommandTypes.PARAM_PROMOTION_TYPE] = promo.Index
    UnitManager.RequestCommand(pUnit, UnitCommandTypes.PROMOTE, params)
end

local function GetFocusedPromotionType()
    local path = mgr and mgr.CurrentPath or nil
    if not path then return nil end

    for i = #path, 1, -1 do
        local key = path[i] and path[i].FocusKey or nil
        if key and string.sub(key, 1, 6) == "promo:" then
            return string.sub(key, 7)
        end
    end

    return nil
end

local function GetActivePromotionWidget(promotionType)
    if m_viewMode == "table" then return m_tablePromotions[promotionType] end
    return m_treePromotions[promotionType]
end

local function FocusPromotionInActiveView(promotionType)
    if not promotionType then return false end
    local target = GetActivePromotionWidget(promotionType)
    if target then
        mgr:SetFocus(target)
        return true
    end
    return false
end

local function ToggleViewMode()
    local focusedType = GetFocusedPromotionType()
    m_viewMode = (m_viewMode == "tree") and "table" or "tree"

    if FocusPromotionInActiveView(focusedType) then return end

    local active = (m_viewMode == "table") and m_tableView or m_treeView
    if active then mgr:SetFocus(active) end
end

local function CreatePromotionButton(promo)
    local captured = promo
    local button = mgr:CreateWidget(mgr:GenerateWidgetId("CAIUnitPromotionCell"), "Button", {
        Label = function() return GetPromotionLabel(captured) end,
        Tooltip = function() return GetPromotionTooltip(captured, true) end,
        DisabledPredicate = function() return not IsPromotionAvailable(captured) end,
        FocusKey = "promo:" .. captured.UnitPromotionType,
    })
    if not button then return nil end
    button:SetFocusSound(HOVER_SOUND)
    button:On("activate", function() RequestPromotion(captured) end)
    return button
end

local function CreatePromotionTreeItem(promo)
    local captured = promo
    local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAIUnitPromotionTreeItem"), "TreeItem", {
        Label = function() return GetPromotionLabel(captured) end,
        Tooltip = function() return GetPromotionTooltip(captured, false) end,
        FocusKey = "promo:" .. captured.UnitPromotionType,
    })
    if not item then return nil end
    item:SetFocusSound(HOVER_SOUND)
    if IsPromotionAvailable(captured) then
        item:On("activate", function() RequestPromotion(captured) end)
    end
    return item
end

local function MakeSpacer()
    return mgr:CreateWidget(mgr:GenerateWidgetId("CAIUnitPromotionSpacer"), "StaticText", {
        HiddenPredicate = function() return true end,
    })
end

local function BuildTableView()
    if not m_tableView or not m_model then return end

    m_tableView:ClearChildren()
    m_tablePromotions = {}

    for _, level in ipairs(m_model.levels) do
        local capturedLevel = level
        local column = m_tableView:AddColumn({
            header = function() return Locale.Lookup("LOC_CAI_TREE_TIER", capturedLevel) end,
        })

        local rows = m_model.byLevel[level] or {}
        local byColumn = {}
        local maxRow = 0
        for _, promo in ipairs(rows) do
            local rowIndex = GetPromotionColumn(promo)
            byColumn[rowIndex] = promo
            if rowIndex > maxRow then maxRow = rowIndex end
        end

        for rowIndex = 1, maxRow do
            local promo = byColumn[rowIndex]
            if promo then
                local cell = CreatePromotionButton(promo)
                if cell then
                    m_tablePromotions[promo.UnitPromotionType] = cell
                    m_tableView:AddItem(column, 1, cell)
                end
            else
                m_tableView:AddItem(column, 1, MakeSpacer())
            end
        end
    end
end

local function CreateRefLink(parentWidget, targetType)
    local capturedType = targetType
    local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAIUnitPromotionRef"), "TreeItem", {
        Label = function()
            local target = m_model and m_model.byType[capturedType]
            return target and GetPromotionName(target) or tostring(capturedType)
        end,
        HiddenPredicate = function()
            return not m_model or not m_model.byType[capturedType] or not m_treePromotions[capturedType]
        end,
        FocusKey = "ref:" .. tostring(capturedType),
    })
    if not item then return end
    item:SetFocusSound(HOVER_SOUND)
    item:On("activate", function()
        local target = m_treeView and mgr:FindByFocusKey(m_treeView, "promo:" .. tostring(capturedType))
        if target then mgr:SetFocus(target) end
    end)
    parentWidget:AddChild(item)
end

local function AddRelationshipNode(parent, locKey, types)
    local node = mgr:CreateWidget(mgr:GenerateWidgetId("CAIUnitPromotionRelationship"), "TreeItem", {
        Label = function() return Locale.Lookup(locKey) end,
    })
    if not node then return end

    for _, promotionType in ipairs(types or {}) do
        CreateRefLink(node, promotionType)
    end

    parent:AddChild(node)
end

local function BuildTreeView()
    if not m_treeView or not m_model then return end

    m_treeView:ClearChildren()
    m_treePromotions = {}

    for _, level in ipairs(m_model.levels) do
        local capturedLevel = level
        local tier = mgr:CreateWidget(mgr:GenerateWidgetId("CAIUnitPromotionTier"), "TreeItem", {
            Label = function() return Locale.Lookup("LOC_CAI_TREE_TIER", capturedLevel) end,
            FocusKey = "tier:" .. tostring(capturedLevel),
        })
        if not tier then return end

        for _, promo in ipairs(m_model.byLevel[level] or {}) do
            local item = CreatePromotionTreeItem(promo)
            if item then
                m_treePromotions[promo.UnitPromotionType] = item
                AddRelationshipNode(item, "LOC_CAI_UNIT_PROMOTION_PREREQS", m_model.prereqs[promo.UnitPromotionType])
                AddRelationshipNode(item, "LOC_CAI_UNIT_PROMOTION_LEADS_TO", m_model.leadsTo[promo.UnitPromotionType])
                tier:AddChild(item)
            end
        end

        tier:Expand(true)
        m_treeView:AddChild(tier)
    end
end

local function BuildViews()
    BuildTableView()
    BuildTreeView()
end

local function BuildPanel()
    if not mgr then return end

    m_panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function() return Locale.Lookup("LOC_HUD_UNIT_CHOOSE_PROMOTION_TEXT") end,
    })
    if not m_panel then return end

    m_tableView = mgr:CreateWidget(TABLE_ID, "Table", {
        Label = function() return Locale.Lookup("LOC_HUD_UNIT_CHOOSE_PROMOTION_TEXT") end,
        HiddenPredicate = function() return m_viewMode ~= "table" end,
    })
    if not m_tableView then return end
    m_panel:AddChild(m_tableView)

    m_treeView = mgr:CreateWidget(TREE_ID, "Tree", {
        Label = function() return Locale.Lookup("LOC_HUD_UNIT_CHOOSE_PROMOTION_TEXT") end,
        HiddenPredicate = function() return m_viewMode ~= "tree" end,
        SearchDepth = 3,
    })
    if not m_treeView then return end
    m_panel:AddChild(m_treeView)

    m_changeViewBtn = mgr:CreateWidget(CHANGE_VIEW_ID, "Button", {
        Label = function()
            return Locale.Lookup(m_viewMode == "table"
                and "LOC_CAI_TREE_SWITCH_TO_TREE"
                or "LOC_CAI_TREE_SWITCH_TO_TABLE")
        end,
    })
    if not m_changeViewBtn then return end
    m_changeViewBtn:On("activate", function() ToggleViewMode() end)
    m_panel:AddChild(m_changeViewBtn)

    BuildViews()
end

local function RemovePanel()
    if mgr then mgr:RemoveFromStack(PANEL_ID) end
    m_panel = nil
    m_tableView = nil
    m_treeView = nil
    m_changeViewBtn = nil
    m_viewMode = "table"
    m_model = nil
    m_tablePromotions = {}
    m_treePromotions = {}
end

local function PushPanel()
    if not mgr then return end
    RemovePanel()
    m_model = BuildPromotionModel()
    if not m_model or #m_model.promotions == 0 then return end
    BuildPanel()
    if not m_panel then return end

    mgr:Push(m_panel)
end

OnPromoteUnitPopup = WrapFunc(OnPromoteUnitPopup, function(orig)
    orig()
    PushPanel()
end)

Close = WrapFunc(Close, function(orig)
    RemovePanel()
    orig()
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
    if mgr and mgr:GetWidgetById(PANEL_ID) and mgr:HandleInput(pInputStruct) then
        return true
    end
    return orig(pInputStruct)
end)

ContextPtr:SetInputHandler(OnInputHandler, true)

OnShutdown = WrapFunc(OnShutdown, function(orig)
    RemovePanel()
    orig()
end)

ContextPtr:SetShutdown(OnShutdown)
