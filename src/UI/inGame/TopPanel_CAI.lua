include("caiUtils")
include("TopPanel")

local mgr = ExposedMembers.CAI_UIManager
local m_caiTopPanelList = nil

local ACTION_SPEAK_TURN_TIME_DATE = Input.GetActionId("TopPanelSpeakTurnTimeDate")
local ACTION_SPEAK_YIELDS = Input.GetActionId("TopPanelSpeakYields")
local ACTION_OPEN_YIELD_LIST = Input.GetActionId("TopPanelYieldInfoList")
local ACTION_OPEN_RESOURCE_LIST = Input.GetActionId("TopPanelResourceInfoList")

local TOP_PANEL_YIELD_INFO_ID = "CAITopPanelYieldInfoTree"
local TOP_PANEL_RESOURCE_INFO_ID = "CAITopPanelResourceInfoList"

local function GetLocalPlayer()
    local playerID = Game.GetLocalPlayer()
    if playerID == nil or playerID < 0 then return nil, nil end
    return playerID, Players[playerID]
end

local function FormatBalance(value)
    return Locale.ToNumber(value, "#,###.#")
end

local function FormatRatePerTurn(value)
    return Locale.Lookup("LOC_HUD_REPORTS_PER_TURN", value)
end

local function GetRateYieldData()
    local _, player = GetLocalPlayer()
    if not player then return {} end

    local entries = {}

    if GameCapabilities.HasCapability("CAPABILITY_SCIENCE")
        and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
        local techs = player:GetTechs()
        table.insert(entries, {
            Label = Locale.Lookup("LOC_TOP_PANEL_SCIENCE"),
            Value = FormatRatePerTurn(FormatValuePerTurn(techs:GetScienceYield())),
            Tooltip = GetScienceTooltip(),
        })
    end

    if GameCapabilities.HasCapability("CAPABILITY_CULTURE")
        and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
        local culture = player:GetCulture()
        table.insert(entries, {
            Label = Locale.Lookup("LOC_TOP_PANEL_CULTURE"),
            Value = FormatRatePerTurn(FormatValuePerTurn(culture:GetCultureYield())),
            Tooltip = GetCultureTooltip(),
        })
    end

    if GameCapabilities.HasCapability("CAPABILITY_TOURISM")
        and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
        local tourismRate = Round(player:GetStats():GetTourism(), 1)
        local tourismTooltip = Locale.Lookup("LOC_WORLD_RANKINGS_OVERVIEW_CULTURE_TOURISM_RATE", tourismRate)
        local tourismBreakdown = player:GetStats():GetTourismToolTip()
        if tourismBreakdown and #tourismBreakdown > 0 then
            tourismTooltip = tourismTooltip .. "[NEWLINE][NEWLINE]" .. tourismBreakdown
        end
        if tourismRate > 0 then
            table.insert(entries, {
                Label = Locale.Lookup("LOC_TOP_PANEL_TOURISM"),
                Value = FormatRatePerTurn(FormatBalance(tourismRate)),
                Tooltip = tourismTooltip,
            })
        end
    end

    return entries
end

local function GetBalanceYieldData()
    local _, player = GetLocalPlayer()
    if not player then return {} end

    local entries = {}

    if GameCapabilities.HasCapability("CAPABILITY_GOLD")
        and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
        local treasury = player:GetTreasury()
        local goldYield = treasury:GetGoldYield() - treasury:GetTotalMaintenance()
        local goldBalance = math.floor(treasury:GetGoldBalance())
        table.insert(entries, {
            Type = "Gold",
            Label = Locale.Lookup("LOC_TOP_PANEL_GOLD"),
            Balance = FormatBalance(goldBalance),
            PerTurn = FormatRatePerTurn(FormatValuePerTurn(goldYield)),
            Income = treasury:GetGoldYield(),
            Expense = -treasury:GetTotalMaintenance(),
            IncomeTooltip = treasury:GetGoldYieldToolTip(),
            ExpenseTooltip = treasury:GetTotalMaintenanceToolTip(),
            Tooltip = GetGoldTooltip(),
        })
    end

    if GameCapabilities.HasCapability("CAPABILITY_FAITH")
        and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
        local religion = player:GetReligion()
        table.insert(entries, {
            Label = Locale.Lookup("LOC_TOP_PANEL_FAITH"),
            Balance = FormatBalance(religion:GetFaithBalance()),
            PerTurn = FormatRatePerTurn(FormatValuePerTurn(religion:GetFaithYield())),
            Value = Locale.Lookup("LOC_CAI_TOP_PANEL_BALANCE_AND_RATE",
                FormatBalance(religion:GetFaithBalance()),
                FormatRatePerTurn(FormatValuePerTurn(religion:GetFaithYield()))),
            Tooltip = GetFaithTooltip(),
        })
    end

    return entries
end

local function GetResourceData()
    local playerID, player = GetLocalPlayer()
    if not playerID or not player then return {} end
    if not GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_RESOURCES") then return {} end

    local playerResources = player:GetResources()
    local entries = {}
    for resource in GameInfo.Resources() do
        if resource.ResourceClassType ~= nil
            and resource.ResourceClassType ~= "RESOURCECLASS_BONUS"
            and resource.ResourceClassType ~= "RESOURCECLASS_LUXURY"
            and resource.ResourceClassType ~= "RESOURCECLASS_ARTIFACT" then
            local amount = playerResources:GetResourceAmount(resource.ResourceType)
            if amount > 0 then
                table.insert(entries, {
                    Label = Locale.Lookup(resource.Name),
                    Value = Locale.ToNumber(amount),
                    Tooltip = Locale.Lookup(resource.Name) ..
                    "[NEWLINE]" .. Locale.Lookup("LOC_TOOLTIP_STRATEGIC_RESOURCE"),
                })
            end
        end
    end
    return entries
end

local function SpeakLines(lines)
    if lines == nil or #lines == 0 then return end
    Speak(table.concat(lines, "[NEWLINE]"))
end

local function SpeakTurnTimeDate()
    RefreshTurnsRemaining()
    RefreshTime()

    local turnLabel = Locale.Lookup("LOC_TOP_PANEL_CURRENT_TURN")
    local turnText = Controls.Turns:GetText()
    local dateText = Controls.CurrentDate:GetText()
    local timeText = Controls.Time:GetText()
    local timeTooltip = Controls.Time:GetToolTipString()

    SpeakLines({
        turnLabel .. " " .. turnText,
        dateText,
        timeText,
        timeTooltip,
    })
end

local function SpeakYieldSummary()
    local lines = {}
    for _, entry in ipairs(GetRateYieldData()) do
        table.insert(lines, entry.Label .. ": " .. entry.Value)
    end
    for _, entry in ipairs(GetBalanceYieldData()) do
        table.insert(lines, entry.Label .. ": " .. entry.Balance .. ", " .. entry.PerTurn)
    end
    SpeakLines(lines)
end

local function CloseTopPanelList(id)
    local list = m_caiTopPanelList
    if not list then return end

    local listId = id
    if not listId and list.GetId then
        listId = list:GetId()
    end
    if not listId or listId == "" then
        m_caiTopPanelList = nil
        return
    end

    m_caiTopPanelList = nil
    if mgr then
        mgr:RemoveFromStack(listId)
    end
end

local function AddListEscapeBinding(list)
    list:AddInputBinding({
        Key = Keys.VK_ESCAPE,
        Action = function()
            CloseTopPanelList()
            return true
        end,
    })
end

local function AddTransientFocusLeave(list, id)
    list.OnFocusLeave = function()
        CloseTopPanelList(id)
    end
end

local function AddStaticListItem(list, label, value, tooltip)
    list:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAITopPanelStaticText"), "StaticText", {
        GetLabel = function()
            return label
        end,
        GetValue = function()
            return value or ""
        end,
        GetTooltip = function()
            return tooltip or ""
        end,
    }))
end

local function NormalizeTooltipNewlines(tooltip)
    if tooltip == nil or tooltip == "" then return "" end
    tooltip = string.gsub(tooltip, "%[NEWLINE%]", "\n")
    tooltip = string.gsub(tooltip, "\r\n", "\n")
    tooltip = string.gsub(tooltip, "\r", "\n")
    return tooltip
end

local function SplitTooltipLines(tooltip)
    local lines = {}
    if tooltip == nil or tooltip == "" then return lines end

    tooltip = NormalizeTooltipNewlines(tooltip) .. "\n"
    for line in string.gmatch(tooltip, "(.-)\n") do
        if line ~= "" then
            table.insert(lines, line)
        end
    end
    return lines
end

local function SplitTooltipSections(tooltip)
    local sections = {}
    local currentSection = {}

    tooltip = NormalizeTooltipNewlines(tooltip) .. "\n"
    for line in string.gmatch(tooltip, "(.-)\n") do
        if line == "" then
            if #currentSection > 0 then
                table.insert(sections, currentSection)
                currentSection = {}
            end
        else
            table.insert(currentSection, line)
        end
    end
    if #currentSection > 0 then
        table.insert(sections, currentSection)
    end

    return sections
end

local function GetTooltipDetailLines(tooltip)
    local lines = {}
    local sections = SplitTooltipSections(tooltip)
    for sectionIndex, section in ipairs(sections) do
        if sectionIndex > 1 then
            for _, line in ipairs(section) do
                table.insert(lines, line)
            end
        end
    end
    return lines
end

local function MakeTreeItem(label, tooltip)
    return mgr:CreateUIWidget(mgr:GenerateWidgetId("CAITopPanelTreeviewItem"), "TreeviewItem", {
        GetLabel = function()
            return label
        end,
        GetTooltip = function()
            return tooltip or ""
        end,
    })
end

local function TrimLeadingWhitespace(text)
    if text == nil then return "" end
    return string.gsub(text, "^%s+", "")
end

local function IsIndentedTooltipLine(text)
    return text ~= nil and string.match(text, "^%s") ~= nil
end

local function AddBreakdownTree(parent, lines)
    local currentCategory = nil
    for _, line in ipairs(lines) do
        local childLine = TrimLeadingWhitespace(line)
        if IsIndentedTooltipLine(line) and currentCategory ~= nil then
            currentCategory:AddChild(MakeTreeItem(childLine, nil))
        else
            currentCategory = MakeTreeItem(childLine, nil)
            parent:AddChild(currentCategory)
        end
    end
end

local function FormatNodeLabel(label, value)
    local nodeLabel = label or ""
    if value and value ~= "" then
        nodeLabel = nodeLabel .. ": " .. value
    end
    return nodeLabel
end

local function AddGenericYieldTreeNode(tree, entry)
    local node = MakeTreeItem(FormatNodeLabel(entry.Label, entry.Value), nil)

    local detailLines = GetTooltipDetailLines(entry.Tooltip)
    AddBreakdownTree(node, detailLines)
    tree:AddChild(node)
end

local function AddGoldYieldTreeNode(tree, entry)
    local value = Locale.Lookup("LOC_CAI_TOP_PANEL_BALANCE_AND_RATE", entry.Balance, entry.PerTurn)
    local node = MakeTreeItem(FormatNodeLabel(entry.Label, value), nil)

    local income = MakeTreeItem(Locale.Lookup("LOC_TOP_PANEL_GOLD_INCOME", entry.Income), nil)
    AddBreakdownTree(income, SplitTooltipLines(entry.IncomeTooltip))
    node:AddChild(income)

    local expense = MakeTreeItem(Locale.Lookup("LOC_TOP_PANEL_GOLD_EXPENSE", entry.Expense), nil)
    AddBreakdownTree(expense, SplitTooltipLines(entry.ExpenseTooltip))
    node:AddChild(expense)

    tree:AddChild(node)
end

local function OpenYieldInfoList()
    CloseTopPanelList()

    local tree = mgr:CreateUIWidget(TOP_PANEL_YIELD_INFO_ID, "Treeview", {
        GetLabel = function()
            return Locale.Lookup("LOC_CAI_TOP_PANEL_YIELD_INFO")
        end,
    })
    AddListEscapeBinding(tree)
    AddTransientFocusLeave(tree, TOP_PANEL_YIELD_INFO_ID)

    for _, entry in ipairs(GetRateYieldData()) do
        AddGenericYieldTreeNode(tree, entry)
    end

    for _, entry in ipairs(GetBalanceYieldData()) do
        if entry.Type == "Gold" then
            AddGoldYieldTreeNode(tree, entry)
        else
            AddGenericYieldTreeNode(tree, entry)
        end
    end

    if tree.Children and #tree.Children > 0 then
        m_caiTopPanelList = tree
        mgr:Push(m_caiTopPanelList, PopupPriority.Low)
    end
end

local function OpenResourceInfoList()
    CloseTopPanelList()

    local list = mgr:CreateUIWidget(TOP_PANEL_RESOURCE_INFO_ID, "List", {
        GetLabel = function()
            return Locale.Lookup("LOC_CAI_TOP_PANEL_RESOURCE_INFO")
        end,
    })
    AddListEscapeBinding(list)
    AddTransientFocusLeave(list, TOP_PANEL_RESOURCE_INFO_ID)

    local resources = GetResourceData()
    if #resources == 0 then
        AddStaticListItem(list, Locale.Lookup("LOC_CAI_TOP_PANEL_NO_STRATEGIC_RESOURCES"), nil, nil)
    else
        for _, entry in ipairs(resources) do
            AddStaticListItem(list, entry.Label, entry.Value, entry.Tooltip)
        end
    end

    m_caiTopPanelList = list
    mgr:Push(m_caiTopPanelList, PopupPriority.Low)
end

local function OnCAITopPanelInputAction(actionId)
    if ContextPtr:IsHidden() then return end
    if actionId == ACTION_SPEAK_TURN_TIME_DATE then
        SpeakTurnTimeDate()
        return
    elseif actionId == ACTION_SPEAK_YIELDS then
        SpeakYieldSummary()
        return
    elseif actionId == ACTION_OPEN_YIELD_LIST then
        OpenYieldInfoList()
        return
    elseif actionId == ACTION_OPEN_RESOURCE_LIST then
        OpenResourceInfoList()
        return
    end
end

function OnShutdown()
    Events.InputActionTriggered.Remove(OnCAITopPanelInputAction)
    CloseTopPanelList()
end

ContextPtr:SetShutdown(OnShutdown)

Events.InputActionTriggered.Add(OnCAITopPanelInputAction)
