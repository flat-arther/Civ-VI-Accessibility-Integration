include("caiUtils")
include("CivicsTree")
include("civicHelpers")

local mgr                 = ExposedMembers.CAI_UIManager

local UNLOCKS_INLINE      = 2

-- ===========================================================================
-- MODULE STATE
-- ===========================================================================
local m_caiPanel          = nil ---@type UIWidget|nil
local m_caiFilterList ---@type UIWidget|nil
local m_caiQueueTree      = nil ---@type UIWidget|nil
local m_caiMainTree       = nil ---@type UIWidget|nil
local m_caiFilterDropdown = nil ---@type UIWidget|nil
local m_caiGovEdit        = nil ---@type UIWidget|nil

local m_caiCivicsByType   = {} ---@type table<string, UIWidget>
local m_leadsToByType     = {} ---@type table<string, table>
local m_civicIndexToType  = {} ---@type table<integer, string>

local m_caiFilterEntries  = nil ---@type table|nil
local m_activeFilterEntry = nil ---@type table|nil
local m_activeFilterFunc  = nil ---@type function|nil
local m_lastPlayerData    = nil ---@type table|nil

-- Stack of source civic widget IDs the user navigated away from via reference
-- links. Backspace inside the main tree pops the last one and re-focuses it.
local m_breadcrumbs       = {} ---@type string[]

-- ===========================================================================
-- LIVE-CONTROL ACCESSORS
-- ===========================================================================

local function GetLocalPlayerCulture()
    local ePlayer = Game.GetLocalPlayer()
    if ePlayer == PlayerTypes.NONE then return nil, -1 end
    local kPlayer = Players[ePlayer]
    if not kPlayer then return nil, -1 end
    return kPlayer:GetCulture(), ePlayer
end

local function GetUiNode(civicType)
    return g_uiNodes and g_uiNodes[civicType] or nil
end

local function ControlText(ctrl)
    if ctrl and ctrl.GetText then
        local t = ctrl:GetText()
        if t and t ~= "" then return t end
    end
    return ""
end

local function ControlTooltip(ctrl)
    if ctrl and ctrl.GetToolTipString then
        local t = ctrl:GetToolTipString()
        if t and t ~= "" then return t end
    end
    return ""
end

local function ControlIsHidden(ctrl)
    return ctrl and ctrl.IsHidden and ctrl:IsHidden() or false
end

local function GetLiveData(civicType)
    if not m_lastPlayerData then return nil end
    local liveTable = m_lastPlayerData[DATA_FIELD_LIVEDATA]
    return liveTable and liveTable[civicType] or nil
end

-- ===========================================================================
-- ROW LABEL / TOOLTIP (live controls)
-- ===========================================================================

local function GetCivicName(civicType)
    local node = GetUiNode(civicType)
    return ControlText(node and node.NodeName)
end

local function GetCivicTooltipText(civicType)
    local node = GetUiNode(civicType)
    return ControlTooltip(node and node.NodeButton)
end

local function GetCivicTurnsText(civicType)
    local node = GetUiNode(civicType)
    if not node or ControlIsHidden(node.Turns) then return nil end
    local t = ControlText(node.Turns)
    if t == "" then return nil end
    return t
end

local function GetCivicBoostFirstLine(civicType)
    local kStatic = g_kItemDefaults[civicType]
    if not kStatic or not kStatic.IsBoostable then return nil end
    local kLive = GetLiveData(civicType)
    local prefix
    if kLive and kLive.IsBoosted then
        prefix = Locale.Lookup("LOC_TECH_HAS_BEEN_BOOSTED")
    else
        prefix = Locale.Lookup("LOC_TECH_CAN_BE_BOOSTED")
    end
    local boostText = kStatic.BoostText or ""
    if boostText == "" then return prefix end
    return prefix .. ": " .. boostText
end

local function GetCivicStatusLabel(kLive)
    if not kLive then return nil end
    local status = kLive.IsRevealed and kLive.Status or ITEM_STATUS.UNREVEALED
    if status == ITEM_STATUS.RESEARCHED then
        return Locale.Lookup("LOC_CAI_CIVIC_STATUS_RESEARCHED")
    elseif status == ITEM_STATUS.CURRENT then
        return Locale.Lookup("LOC_CAI_CIVIC_STATUS_CURRENT")
    elseif status == ITEM_STATUS.BLOCKED then
        return Locale.Lookup("LOC_CAI_CIVIC_STATUS_BLOCKED")
    elseif status == ITEM_STATUS.UNREVEALED then
        return Locale.Lookup("LOC_CAI_CIVIC_STATUS_UNREVEALED")
    end
    -- READY is the default available state; no announcement needed.
    return nil
end

local function FormatRowLabel(civicType)
    local parts = {}
    AppendIfNonEmpty(parts, GetCivicName(civicType))
    local kLive = GetLiveData(civicType)
    AppendIfNonEmpty(parts, GetCivicStatusLabel(kLive))
    if kLive and kLive.IsRecommended then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_TECH_FILTER_RECOMMENDED"))
    end
    return table.concat(parts, ", ")
end

local function GetFirstNNames(names, n)
    local head = {}
    for i, name in ipairs(names or {}) do
        if i <= n then table.insert(head, name) else break end
    end
    return head
end

local function GetCivicQueuePosition(civicType)
    local row = GameInfo.Civics[civicType]
    if not row then return nil end
    local playerCulture = GetLocalPlayerCulture()
    if not playerCulture then return nil end
    local queue = playerCulture:GetCivicQueue()
    if not queue then return nil end
    for i, id in ipairs(queue) do
        if id == row.Index then return i end
    end
    return nil
end

local function FormatRowTooltip(civicType)
    local parts = {}

    AppendIfNonEmpty(parts, GetCivicTurnsText(civicType))

    local tooltipLines = SplitTooltipLinesWithoutSpecialLists(GetCivicTooltipText(civicType))
    AppendIfNonEmpty(parts, tooltipLines[2])

    AppendIfNonEmpty(parts, GetCivicBoostFirstLine(civicType))

    local kData = { CivicType = civicType, Type = civicType }
    local unlockNames = GetUnlockNames(kData)
    local obsoleteNames = GetObsoletePolicyNames(kData)

    for _, name in ipairs(GetFirstNNames(unlockNames, UNLOCKS_INLINE)) do
        AppendIfNonEmpty(parts, name)
    end

    local obsoletePreview = table.concat(GetFirstNNames(obsoleteNames, UNLOCKS_INLINE), ", ")
    if obsoletePreview ~= "" then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_CIVIC_MAKES_OBSOLETE_PREVIEW", obsoletePreview))
    end

    local queuePosition = GetCivicQueuePosition(civicType)
    if queuePosition then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_CIVIC_QUEUE_POSITION", queuePosition))
    end

    return table.concat(parts, "[NEWLINE]")
end

-- ===========================================================================
-- FILTER
-- ===========================================================================

local function EnsureFilterEntries()
    if m_caiFilterEntries then return end
    m_caiFilterEntries = {
        {
            Label        = Locale.Lookup("LOC_TECH_FILTER_NONE"),
            Func         = nil,
            VanillaEntry = { Func = nil, Description = "LOC_TECH_FILTER_NONE" },
        },
    }
    if not g_TechFilters then return end
    local defs = {
        { "TECHFILTER_FOOD",         "LOC_TECH_FILTER_FOOD" },
        { "TECHFILTER_SCIENCE",      "LOC_TECH_FILTER_SCIENCE" },
        { "TECHFILTER_PRODUCTION",   "LOC_TECH_FILTER_PRODUCTION" },
        { "TECHFILTER_CULTURE",      "LOC_TECH_FILTER_CULTURE" },
        { "TECHFILTER_GOLD",         "LOC_TECH_FILTER_GOLD" },
        { "TECHFILTER_UNITS",        "LOC_TECH_FILTER_UNITS" },
        { "TECHFILTER_IMPROVEMENTS", "LOC_TECH_FILTER_IMPROVEMENTS" },
        { "TECHFILTER_WONDERS",      "LOC_TECH_FILTER_WONDERS" },
    }
    for _, pair in ipairs(defs) do
        local fn = g_TechFilters[pair[1]]
        if fn then
            table.insert(m_caiFilterEntries, {
                Label        = Locale.Lookup(pair[2]),
                Func         = fn,
                VanillaEntry = { Func = fn, Description = pair[2] },
            })
        end
    end
end

local function FilterMatchesCivic(civicType)
    if not m_activeFilterFunc then return true end
    return m_activeFilterFunc(civicType) == true
end

-- ===========================================================================
-- STATIC DATA (leads-to and Index<->Type lookups)
-- ===========================================================================

local function BuildStaticMaps()
    m_leadsToByType    = {}
    m_civicIndexToType = {}
    for civicType, kEntry in pairs(g_kItemDefaults) do
        local row = GameInfo.Civics[civicType]
        if row then m_civicIndexToType[row.Index] = civicType end
        for _, prereqType in ipairs(kEntry.Prereqs or {}) do
            if prereqType ~= PREREQ_ID_TREE_START then
                m_leadsToByType[prereqType] = m_leadsToByType[prereqType] or {}
                table.insert(m_leadsToByType[prereqType], civicType)
            end
        end
    end
end

-- ===========================================================================
-- CIVIC ACTIONS (set current vs. append to queue)
-- ===========================================================================

local function RequestProgressCivic(civicType, append)
    local kStatic = g_kItemDefaults[civicType]
    local playerCulture, ePlayer = GetLocalPlayerCulture()
    if not kStatic or not playerCulture or ePlayer == -1 then return end

    local pathToCivic                               = playerCulture:GetCivicPath(kStatic.Hash)
    local tParameters                               = {}
    tParameters[PlayerOperations.PARAM_CIVIC_TYPE]  = pathToCivic
    tParameters[PlayerOperations.PARAM_INSERT_MODE] = append
        and PlayerOperations.VALUE_APPEND
        or PlayerOperations.VALUE_EXCLUSIVE
    UI.RequestPlayerOperation(ePlayer, PlayerOperations.PROGRESS_CIVIC, tParameters)
    UI.PlaySound("Confirm_Civic_CivicsTree")

    -- BLOCKED civics queue the whole prereq chain; READY civics queue just one.
    -- The announcement is the same for set-current and append: count and total
    -- culture cost summed from live data for each step in the path.
    local count, totalCost = 0, 0
    for _, idx in ipairs(pathToCivic or {}) do
        count = count + 1
        local ct = m_civicIndexToType[idx]
        local kLive = ct and GetLiveData(ct) or nil
        if kLive and kLive.Cost then
            totalCost = totalCost + kLive.Cost
        end
    end
    Speak(Locale.Lookup("LOC_CAI_CIVIC_QUEUE_ADDED", count, totalCost))
end

-- Vanilla wires the click callback to both NodeButton and OtherStates, so
-- clicking is functional for any revealed civic. BLOCKED is intentionally
-- clickable: GetCivicPath returns the prereq chain, queueing the whole path.
-- RESEARCHED / CURRENT have no useful path (already done / in progress) and
-- UNREVEALED isn't a valid target.
local function CanResearch(civicType)
    local kLive = GetLiveData(civicType)
    if not kLive or not kLive.IsRevealed then return false end
    return kLive.Status == ITEM_STATUS.READY
        or kLive.Status == ITEM_STATUS.BLOCKED
end

-- ===========================================================================
-- REFERENCE LINKS (jump to civic node) and DETAIL CHILDREN
-- ===========================================================================

local function IsCivicRevealed(civicType)
    local kLive = GetLiveData(civicType)
    return kLive ~= nil and kLive.IsRevealed == true
end

local function CreateRefLink(parentWidget, civicType, sourceCivicId)
    local capturedType = civicType
    local capturedSourceId = sourceCivicId
    local item = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICivicsTreeRef"), "TreeviewItem", {
        GetLabel   = function() return GetCivicName(capturedType) end,
        IsHidden   = function() return m_caiCivicsByType[capturedType] == nil end,
        IsDisabled = function() return not IsCivicRevealed(capturedType) end,
        OnClick    = function(w)
            if w.IsDisabled and w:IsDisabled() then return end
            local target = m_caiCivicsByType[capturedType]
            if target then
                if capturedSourceId then
                    table.insert(m_breadcrumbs, capturedSourceId)
                end
                mgr:SetFocus(target)
            end
        end,
    })
    item:AddInputBinding({
        Key = Keys.VK_RETURN,
        IsShift = true,
        Action = function(w)
            if w.IsDisabled and w:IsDisabled() then return true end
            if IsTutorialRunning and IsTutorialRunning() then return true end
            LuaEvents.OpenCivilopedia(capturedType)
            return true
        end,
    })
    parentWidget:AddChild(item)
    return item
end

local function AddCivicDetailChildren(civicItem, civicType, sourceCivicId)
    local kStatic = g_kItemDefaults[civicType]
    if not kStatic then return end

    -- Description body lines from the live tooltip; the unlocks/obsolete
    -- bullet lists are dropped here and rebuilt as collapsed nodes below.
    for _, line in ipairs(SplitTooltipLinesWithoutSpecialLists(GetCivicTooltipText(civicType))) do
        AddTextDetailNode(mgr, civicItem, line)
    end

    AddTextDetailNode(mgr, civicItem, GetCivicBoostFirstLine(civicType))

    local kData = { CivicType = civicType, Type = civicType }
    AddUnlocksNode(mgr, civicItem, GetUnlockNames(kData))
    AddMakesObsoleteNode(mgr, civicItem, GetObsoletePolicyNames(kData))

    local prereqTypes = {}
    for _, pt in ipairs(kStatic.Prereqs or {}) do
        if pt ~= PREREQ_ID_TREE_START then table.insert(prereqTypes, pt) end
    end
    if #prereqTypes > 0 then
        local node = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICivicsTreePrereqs"), "TreeviewItem", {
            GetLabel = function() return Locale.Lookup("LOC_CAI_CIVICS_TREE_PREREQS") end,
        })
        for _, pt in ipairs(prereqTypes) do CreateRefLink(node, pt, sourceCivicId) end
        civicItem:AddChild(node)
    end

    local leadsTo = m_leadsToByType[civicType]
    if leadsTo and #leadsTo > 0 then
        local node = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICivicsTreeLeadsTo"), "TreeviewItem", {
            GetLabel = function() return Locale.Lookup("LOC_CAI_CIVICS_TREE_LEADS_TO") end,
        })
        for _, lt in ipairs(leadsTo) do CreateRefLink(node, lt, sourceCivicId) end
        civicItem:AddChild(node)
    end

    if CanResearch(civicType) then
        local playerCulture = GetLocalPlayerCulture()
        local path = playerCulture and playerCulture:GetCivicPath(kStatic.Hash) or nil
        if path and #path > 1 then
            local node = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICivicsTreePath"), "TreeviewItem", {
                GetLabel = function() return Locale.Lookup("LOC_CAI_CIVICS_TREE_PATH_IF_SELECTED") end,
            })
            for i = 1, #path - 1 do
                local ct = m_civicIndexToType[path[i]]
                if ct then CreateRefLink(node, ct, sourceCivicId) end
            end
            civicItem:AddChild(node)
        end
    end
end

-- ===========================================================================
-- CIVIC NODE FACTORY
-- ===========================================================================

local function BuildCivicNode(civicType)
    local capturedType = civicType
    local civicId = mgr:GenerateWidgetId("CAICivicsTreeCivic")
    local civicItem = mgr:CreateUIWidget(civicId, "TreeviewItem", {
        GetLabel     = function() return FormatRowLabel(capturedType) end,
        GetTooltip   = function() return FormatRowTooltip(capturedType) end,
        IsDisabled   = function()
            local node = GetUiNode(capturedType)
            if node and node.Top:IsDisabled() then return true end
            return not CanResearch(capturedType)
        end,
        OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
        OnClick      = function()
            if not CanResearch(capturedType) then return end
            RequestProgressCivic(capturedType, false)
        end,
    })

    civicItem:AddInputBinding({
        Key = Keys.VK_RETURN,
        IsControl = true,
        Action = function()
            if not CanResearch(capturedType) then return true end
            RequestProgressCivic(capturedType, true)
            return true
        end,
    })
    civicItem:AddInputBinding({
        Key = Keys.VK_RETURN,
        IsShift = true,
        Action = function()
            if IsTutorialRunning and IsTutorialRunning() then return true end
            LuaEvents.OpenCivilopedia(capturedType)
            return true
        end,
    })

    AddCivicDetailChildren(civicItem, civicType, civicId)
    return civicItem
end

-- ===========================================================================
-- MAIN TREE REBUILD (era-grouped, filter is a structural exclusion)
-- ===========================================================================

local function CaptureFocusedCivicType()
    if not mgr.GetFocusedWidget then return nil end
    local focused = mgr:GetFocusedWidget()
    if not focused then return nil end
    for ct, widget in pairs(m_caiCivicsByType) do
        if widget == focused then return ct end
    end
    return nil
end

local function RebuildMainTree()
    if not m_caiMainTree then return end

    local focusedType = CaptureFocusedCivicType()
    m_caiMainTree:ClearChildren()
    m_caiCivicsByType = {}
    -- Old civic widget ids are gone; previously-recorded breadcrumbs would
    -- never resolve through GetChildById, so drop them.
    m_breadcrumbs = {}

    for _, era in ipairs(g_kEras) do
        local eraCivics = {}
        for civicType, kEntry in pairs(g_kItemDefaults) do
            if kEntry.EraType == era.EraType and FilterMatchesCivic(civicType) then
                table.insert(eraCivics, { civicType = civicType, row = kEntry.UITreeRow or 0 })
            end
        end
        if #eraCivics > 0 then
            table.sort(eraCivics, function(a, b) return a.row < b.row end)

            local capturedDescription = era.Description
            local eraItem = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICivicsTreeEra"), "TreeviewItem", {
                GetLabel = function() return capturedDescription end,
            })

            for _, entry in ipairs(eraCivics) do
                local widget = BuildCivicNode(entry.civicType)
                if widget then
                    m_caiCivicsByType[entry.civicType] = widget
                    eraItem:AddChild(widget)
                end
            end
            m_caiMainTree:AddChild(eraItem)
        end
    end

    if focusedType and m_caiCivicsByType[focusedType] and m_caiPanel and mgr:HasWidget(m_caiPanel) then
        mgr:SetFocus(m_caiCivicsByType[focusedType])
    end
end

-- ===========================================================================
-- QUEUE TREE REBUILD (current civic + queued civics)
-- ===========================================================================

local function CreateQueueRow(civicType, prefix)
    local capturedType = civicType
    local row = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICivicsTreeQueueRow"), "TreeviewItem", {
        GetLabel = function()
            local label = FormatRowLabel(capturedType)
            if prefix then return prefix .. ": " .. label end
            return label
        end,
        GetTooltip = function() return FormatRowTooltip(capturedType) end,
        OnClick = function()
            local target = m_caiCivicsByType[capturedType]
            if target then mgr:SetFocus(target) end
        end,
    })
    row:AddInputBinding({
        Key = Keys.VK_RETURN,
        IsShift = true,
        Action = function()
            if IsTutorialRunning and IsTutorialRunning() then return true end
            LuaEvents.OpenCivilopedia(capturedType)
            return true
        end,
    })
    return row
end

local function RebuildQueueTree()
    if not m_caiQueueTree then return end

    local focusPath = mgr:CaptureFocusIndexPath(m_caiQueueTree)
    m_caiQueueTree:ClearChildren()

    local playerCulture = GetLocalPlayerCulture()
    if playerCulture then
        local queue = playerCulture:GetCivicQueue()
        if queue then
            for _, civicID in ipairs(queue) do
                local civicType = m_civicIndexToType[civicID]
                if civicType then
                    m_caiQueueTree:AddChild(CreateQueueRow(civicType, nil))
                end
            end
        end
    end

    if focusPath and m_caiPanel and mgr:HasWidget(m_caiPanel) then
        mgr:SetFocusIndexPath(m_caiQueueTree, focusPath)
    end
end

-- ===========================================================================
-- FILTER DROPDOWN (single DropdownMenu; OnClick pushes a List of MenuItems)
-- ===========================================================================

local function OnFilterChosen(entry)
    m_activeFilterEntry = entry
    m_activeFilterFunc  = entry.Func
    if OnFilterClicked then OnFilterClicked(entry.VanillaEntry) end
    RebuildMainTree()
    if m_caiMainTree and m_caiPanel and mgr:HasWidget(m_caiPanel) then
        mgr:SetFocus(m_caiMainTree)
    end
end

local function OpenFilterList()
    EnsureFilterEntries()
    if not m_caiFilterEntries then return end

    m_caiFilterList = mgr:CreateUIWidget("CAICivicsTreeFilterList", "List", {
        GetLabel = function() return Locale.Lookup("LOC_CAI_CIVICS_TREE_FILTER") end,
    })
    m_caiFilterList:AddInputBinding({
        Key = Keys.VK_ESCAPE,
        Action = function()
            mgr:Pop(); return true
        end,
    })

    for _, entry in ipairs(m_caiFilterEntries) do
        local capturedEntry = entry
        m_caiFilterList:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICivicsTreeFilterItem"), "MenuItem", {
            GetLabel = function() return capturedEntry.Label end,
            GetState = function()
                return m_activeFilterEntry == capturedEntry
                    and Locale.Lookup("LOC_CAI_STATE_SELECTED") or nil
            end,
            OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
            OnClick = function()
                OnFilterChosen(capturedEntry)
                mgr:Pop()
            end,
        }))
    end

    mgr:Push(m_caiFilterList)
end

-- ===========================================================================
-- GOVERNMENT SUMMARY (read-only edit, fed by live controls + live policy data)
-- ===========================================================================

local function BuildGovernmentText()
    local function Count(ctrl) return tonumber(ControlText(ctrl)) or 0 end
    local parts = {}
    table.insert(parts, Locale.Lookup("LOC_CAI_GOVERNMENT_SUMMARY",
        ControlText(Controls.GovernmentTitle),
        Count(Controls.DiplomaticIconCount),
        Count(Controls.EconomicIconCount),
        Count(Controls.MilitaryIconCount),
        Count(Controls.WildcardIconCount)))

    if m_lastPlayerData and m_lastPlayerData[DATA_FIELD_GOVERNMENT] then
        local kGov = m_lastPlayerData[DATA_FIELD_GOVERNMENT]
        local function AddPolicies(ids, slotLabel)
            for _, policyId in ipairs(ids or {}) do
                if policyId ~= -1 then
                    local row = GameInfo.Policies[policyId]
                    if row then
                        table.insert(parts, slotLabel .. ": " .. Locale.Lookup(row.Name))
                    end
                end
            end
        end
        AddPolicies(kGov["DIPLOMATICPOLICIES"], Locale.Lookup("LOC_CAI_POLICY_SLOT_DIPLOMATIC"))
        AddPolicies(kGov["ECONOMICPOLICIES"], Locale.Lookup("LOC_CAI_POLICY_SLOT_ECONOMIC"))
        AddPolicies(kGov["MILITARYPOLICIES"], Locale.Lookup("LOC_CAI_POLICY_SLOT_MILITARY"))
        AddPolicies(kGov["WILDCARDPOLICIES"], Locale.Lookup("LOC_CAI_POLICY_SLOT_WILDCARD"))
    end

    return table.concat(parts, ". ")
end

local function RefreshGovernmentEdit()
    if not m_caiGovEdit then return end
    mgr.WidgetTemplateHelpers:SetEditBoxText(m_caiGovEdit, BuildGovernmentText())
end

-- ===========================================================================
-- PANEL LIFECYCLE
-- ===========================================================================

local function EnsurePanelBuilt()
    if m_caiPanel or not mgr then return end

    BuildStaticMaps()
    EnsureFilterEntries()

    m_caiPanel = mgr:CreateUIWidget("CAICivicsTreePanel", "Panel", {
        GetLabel = function() return ControlText(Controls.ModalScreenTitle) end,
    })

    m_caiQueueTree = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICivicsTreeQueue"), "Treeview", {
        GetLabel    = function() return Locale.Lookup("LOC_CAI_CIVICS_TREE_QUEUE_LIST") end,
        IsHidden    = function(w) return not w.Children or #w.Children == 0 end,
        SearchDepth = 0,
    })
    m_caiPanel:AddChild(m_caiQueueTree)

    m_caiMainTree = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICivicsTreeMain"), "Treeview", {
        GetLabel    = function() return Locale.Lookup("LOC_CAI_CIVICS_TREE_MAIN_LIST") end,
        SearchDepth = 2,
    })
    m_caiMainTree:AddInputBinding({
        Key = Keys.VK_BACK,
        Action = function()
            local id = table.remove(m_breadcrumbs)
            if not id then return false end
            local widget = m_caiMainTree:GetChildById(id, true)
            if widget then mgr:SetFocus(widget) end
            return true
        end,
    })
    m_caiPanel:AddChild(m_caiMainTree)

    m_caiFilterDropdown = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICivicsTreeFilter"), "DropdownMenu", {
        GetLabel     = function() return Locale.Lookup("LOC_CAI_CIVICS_TREE_FILTER") end,
        GetValue     = function()
            return (m_activeFilterEntry and m_activeFilterEntry.Label)
                or Locale.Lookup("LOC_TECH_FILTER_NONE")
        end,
        OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
        OnClick      = OpenFilterList,
    })
    m_caiPanel:AddChild(m_caiFilterDropdown)

    m_caiGovEdit = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICivicsTreeGovEdit"), "Edit", {
        GetLabel        = function() return Locale.Lookup("LOC_CAI_CIVICS_TREE_GOVERNMENT") end,
        GetValue        = function() return m_caiGovEdit and m_caiGovEdit.EditBuffer or "" end,
        AlwaysEdit      = true,
        EditReadOnly    = true,
        HighlightOnEdit = false,
        EditBuffer      = "",
    })
    m_caiPanel:AddChild(m_caiGovEdit)

    RebuildMainTree()
    RebuildQueueTree()
    RefreshGovernmentEdit()
end

local function PushPanel()
    if not mgr then return end
    EnsurePanelBuilt()
    if not m_caiPanel or mgr:HasWidget(m_caiPanel) then return end

    local playerCulture = GetLocalPlayerCulture()
    local hasCurrent = playerCulture and playerCulture:GetProgressingCivic() ~= -1
    -- Index 1 = queue, 2 = main tree, 3 = filter, 4 = government edit
    m_caiPanel:SetDefaultIndex(hasCurrent and 1 or 2)
    mgr:Push(m_caiPanel)
end

local function OnPanelClosedCAI()
    if m_caiPanel and mgr and mgr:HasWidget(m_caiPanel) then
        mgr:Pop()
    end
    m_caiPanel          = nil
    m_caiQueueTree      = nil
    m_caiMainTree       = nil
    m_caiFilterDropdown = nil
    m_caiGovEdit        = nil
    m_caiCivicsByType   = {}
    m_leadsToByType     = {}
    m_civicIndexToType  = {}
    m_lastPlayerData    = nil
    m_caiFilterEntries  = nil
    m_activeFilterEntry = nil
    m_activeFilterFunc  = nil
    m_breadcrumbs       = {}
end

local function IsPanelOnStack()
    return m_caiPanel and mgr and mgr:HasWidget(m_caiPanel)
end

-- ===========================================================================
-- WRAPS
-- ===========================================================================

View = WrapFunc(View, function(orig, playerData)
    m_lastPlayerData = playerData
    orig(playerData)
    if m_caiPanel then
        RebuildQueueTree()
        RefreshGovernmentEdit()
    end
end)


-- Vanilla Initialize subscribed the original OnOpen reference to the open
-- LuaEvents before this file loaded; rewrap-and-reswap so the wrapped version
-- is what actually fires.
local _origOnOpen = OnOpen
OnOpen = WrapFunc(OnOpen, function(orig)
    orig()
    PushPanel()
end)
LuaEvents.CivicsChooser_RaiseCivicsTree.Remove(_origOnOpen)
LuaEvents.LaunchBar_RaiseCivicsTree.Remove(_origOnOpen)
LuaEvents.CivicsChooser_RaiseCivicsTree.Add(OnOpen)
LuaEvents.LaunchBar_RaiseCivicsTree.Add(OnOpen)

-- KeyUpHandler ESC and OnClose both call Close() by global name, so wrapping
-- Close catches every vanilla close path including LaunchBar_CloseCivicsTree.
Close = WrapFunc(Close, function(orig)
    orig()
    OnPanelClosedCAI()
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
    local top = mgr:GetTop()
    if top ~= m_caiPanel and top ~= m_caiFilterList then return false end
    if mgr:HandleInput(pInputStruct) then
        return true
    end
    return orig(pInputStruct)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)

-- ===========================================================================
-- EVENTS
-- ===========================================================================

local function RebuildQueueIfOpen()
    if IsPanelOnStack() then RebuildQueueTree() end
end

local function RefreshGovIfOpen()
    if IsPanelOnStack() then
        Speak(BuildGovernmentText())
        RefreshGovernmentEdit()
    end
end

Events.CivicChanged.Add(function(ePlayer)
    if ePlayer == Game.GetLocalPlayer() then RebuildQueueIfOpen() end
end)

Events.CivicQueueChanged.Add(function(ePlayer)
    if ePlayer == Game.GetLocalPlayer() then RebuildQueueIfOpen() end
end)

Events.CivicCompleted.Add(function(ePlayer)
    if ePlayer ~= Game.GetLocalPlayer() or not IsPanelOnStack() then return end
    if not m_lastPlayerData then return end
    local focusedType = CaptureFocusedCivicType()
    RebuildMainTree()
    RebuildQueueTree()
    if focusedType and m_caiCivicsByType[focusedType] then
        mgr:SetFocus(m_caiCivicsByType[focusedType])
    end
end)

Events.GovernmentChanged.Add(function(ePlayer)
    if ePlayer == Game.GetLocalPlayer() then RefreshGovIfOpen() end
end)

Events.GovernmentPolicyChanged.Add(function(ePlayer)
    if ePlayer == Game.GetLocalPlayer() then RefreshGovIfOpen() end
end)

Events.GovernmentPolicyObsoleted.Add(function(ePlayer)
    if ePlayer == Game.GetLocalPlayer() then RefreshGovIfOpen() end
end)

Events.LocalPlayerTurnBegin.Add(function(ePlayer)
    if ePlayer == Game.GetLocalPlayer() then RebuildQueueIfOpen() end
end)

Events.LocalPlayerChanged.Add(function() OnPanelClosedCAI() end)
