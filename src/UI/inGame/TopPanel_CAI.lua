include("caiUtils")
include("Civ6Common")

if IsExpansion2Active() then
    include("TopPanel_Expansion2")
elseif IsExpansion1Active() then
    include("TopPanel_Expansion1")
else
    include("TopPanel")
end

local mgr = ExposedMembers.CAI_UIManager
local m_caiTopPanelList = nil

local ACTION_SPEAK_TURN_TIME_DATE = Input.GetActionId("TopPanelSpeakTurnTimeDate")
local ACTION_SPEAK_GOLD = Input.GetActionId("TopPanelSpeakGold")
local ACTION_SPEAK_FAITH = Input.GetActionId("TopPanelSpeakFaith")
local ACTION_SPEAK_TOURISM = Input.GetActionId("TopPanelSpeakTourism")
local ACTION_SPEAK_FAVOR = Input.GetActionId("TopPanelSpeakFavor")
local ACTION_SPEAK_NUKES = Input.GetActionId("TopPanelSpeakNukes")
local ACTION_OPEN_YIELD_LIST = Input.GetActionId("TopPanelYieldInfoList")
local ACTION_OPEN_DIPLOMACY = Input.GetActionId("TopPanelOpenDiplomacy")
local ACTION_OPEN_REPORTS = Input.GetActionId("TopPanelOpenReports")
local ACTION_OPEN_REPORTS_RESOURCES = Input.GetActionId("TopPanelOpenReportsResources")
local ACTION_OPEN_REPORTS_CITY_STATUS = Input.GetActionId("TopPanelOpenReportsCityStatus")
local ACTION_OPEN_REPORTS_GOSSIP = Input.GetActionId("TopPanelOpenReportsGossip")
local ACTION_OPEN_RESOURCE_LIST = Input.GetActionId("TopPanelResourceInfoList")
local ACTION_OPEN_GLOBAL_RESOURCES = Input.GetActionId("OpenGlobalResourcePopup")

local TOP_PANEL_YIELD_INFO_ID = "CAITopPanelYieldInfoTree"
local TOP_PANEL_RESOURCE_INFO_ID = "CAITopPanelResourceInfoTree"

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

-- ===========================================================================
-- Individual yield speech
-- ===========================================================================
local function SpeakGold()
    local _, player = GetLocalPlayer()
    if not player then return end
    if not GameCapabilities.HasCapability("CAPABILITY_GOLD")
        or not GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then return end

    local parts = {}
    local treasury = player:GetTreasury()
    local goldYield = treasury:GetGoldYield() - treasury:GetTotalMaintenance()
    local goldBalance = math.floor(treasury:GetGoldBalance())
    table.insert(parts, Locale.Lookup("LOC_TOP_PANEL_GOLD") .. ": "
        .. Locale.Lookup("LOC_CAI_TOP_PANEL_BALANCE_AND_RATE",
            FormatBalance(goldBalance),
            FormatRatePerTurn(FormatValuePerTurn(goldYield))))

    if GameCapabilities.HasCapability("CAPABILITY_TRADE") then
        local playerTrade = player:GetTrade()
        local routesActive = playerTrade:GetNumOutgoingRoutes()
        local routesCapacity = playerTrade:GetOutgoingRouteCapacity()
        if routesCapacity > 0 then
            table.insert(parts, Locale.Lookup("LOC_CAI_TOP_PANEL_TRADE_ROUTES",
                routesActive, routesCapacity))
        end
    end

    Speak(table.concat(parts, ", "))
end

local function SpeakFaith()
    local _, player = GetLocalPlayer()
    if not player then return end
    if not GameCapabilities.HasCapability("CAPABILITY_FAITH")
        or not GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then return end

    local religion = player:GetReligion()
    local value = Locale.Lookup("LOC_CAI_TOP_PANEL_BALANCE_AND_RATE",
        FormatBalance(religion:GetFaithBalance()),
        FormatRatePerTurn(FormatValuePerTurn(religion:GetFaithYield())))
    Speak(Locale.Lookup("LOC_TOP_PANEL_FAITH") .. ": " .. value)
end

local function SpeakTourism()
    local _, player = GetLocalPlayer()
    if not player then return end
    if not GameCapabilities.HasCapability("CAPABILITY_TOURISM")
        or not GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then return end

    local tourismRate = Round(player:GetStats():GetTourism(), 1)
    if tourismRate > 0 then
        Speak(Locale.Lookup("LOC_TOP_PANEL_TOURISM") .. ": "
            .. FormatRatePerTurn(FormatBalance(tourismRate)))
    else
        Speak(Locale.Lookup("LOC_TOP_PANEL_TOURISM") .. ": 0")
    end
end

local function SpeakFavor()
    if not IsExpansion2Active() then return end
    local _, player = GetLocalPlayer()
    if not player then return end

    local parts = {}

    local playerFavor = player:GetFavor()
    local favorPerTurn = player:GetFavorPerTurn()
    table.insert(parts, Locale.Lookup("LOC_CAI_TOP_PANEL_FAVOR") .. ": "
        .. Locale.Lookup("LOC_CAI_TOP_PANEL_BALANCE_AND_RATE",
            FormatBalance(playerFavor),
            FormatRatePerTurn(FormatValuePerTurn(favorPerTurn))))

    if GameCapabilities.HasCapability("CAPABILITY_TOP_PANEL_ENVOYS") then
        local playerInfluence = player:GetInfluence()
        local currentEnvoys = playerInfluence:GetTokensToGive()
        local influenceBalance = Round(playerInfluence:GetPointsEarned(), 1)
        local influenceThreshold = playerInfluence:GetPointsThreshold()
        table.insert(parts, Locale.Lookup("LOC_CAI_TOP_PANEL_ENVOYS_SUMMARY",
            currentEnvoys, influenceBalance, influenceThreshold))
    end

    Speak(table.concat(parts, ", "))
end

local function SpeakNukes()
    local playerID, player = GetLocalPlayer()
    if not player then return end

    local playerWMDs = player:GetWMDs()
    local parts = {}
    for entry in GameInfo.WMDs() do
        if entry.WeaponType == "WMD_NUCLEAR_DEVICE" then
            local count = playerWMDs:GetWeaponCount(entry.Index)
            if count > 0 then
                table.insert(parts, Locale.Lookup("LOC_CAI_TOP_PANEL_NUCLEAR_DEVICES", count))
            end
        elseif entry.WeaponType == "WMD_THERMONUCLEAR_DEVICE" then
            local count = playerWMDs:GetWeaponCount(entry.Index)
            if count > 0 then
                table.insert(parts, Locale.Lookup("LOC_CAI_TOP_PANEL_THERMONUCLEAR_DEVICES", count))
            end
        end
    end

    if #parts == 0 then
        Speak(Locale.Lookup("LOC_CAI_TOP_PANEL_NO_NUKES"))
    else
        Speak(table.concat(parts, ", "))
    end
end

local function GetCurrentEraName()
    local playerID, player = GetLocalPlayer()
    if not player then return nil end
    local eraIndex = player:GetEra() + 1
    for row in GameInfo.Eras() do
        if row.ChronologyIndex == eraIndex then
            return Locale.Lookup(row.Name)
        end
    end
    return nil
end

local function GetCurrentAgeName()
    if not (IsExpansion1Active() or IsExpansion2Active()) then return nil end
    local playerID = Game.GetLocalPlayer()
    if playerID == nil or playerID < 0 then return nil end
    local kEras = Game.GetEras()
    if kEras:HasHeroicGoldenAge(playerID) then
        return Locale.Lookup("LOC_ERA_PROGRESS_HEROIC_AGE")
    elseif kEras:HasGoldenAge(playerID) then
        return Locale.Lookup("LOC_ERA_PROGRESS_GOLDEN_AGE")
    elseif kEras:HasDarkAge(playerID) then
        return Locale.Lookup("LOC_ERA_PROGRESS_DARK_AGE")
    end
    return Locale.Lookup("LOC_ERA_PROGRESS_NORMAL_AGE")
end

local function SpeakTurnTimeDate()
    RefreshTurnsRemaining()
    RefreshTime()

    local parts = {}
    table.insert(parts, Locale.Lookup("LOC_TOP_PANEL_CURRENT_TURN") .. " " .. Controls.Turns:GetText())

    local eraName = GetCurrentEraName()
    if eraName then
        table.insert(parts, eraName)
    end

    local ageName = GetCurrentAgeName()
    if ageName then
        table.insert(parts, ageName)
    end

    table.insert(parts, Controls.CurrentDate:GetText())
    table.insert(parts, Controls.Time:GetText())

    Speak(table.concat(parts, ", "))
end

-- ===========================================================================
-- Yield breakdown tree (Ctrl+Y)
-- ===========================================================================
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
    return mgr:CreateWidget(mgr:GenerateWidgetId("CAITopPanelTreeItem"), "TreeItem", {
        Label = function() return label end,
        Tooltip = function() return tooltip or "" end,
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

local function CloseTopPanelList(id)
    local list = m_caiTopPanelList
    if not list then return end

    local listId = id or list.Id
    if not listId or listId == "" then
        m_caiTopPanelList = nil
        return
    end

    m_caiTopPanelList = nil
    mgr:RemoveFromStack(listId)
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
    list:On("focus_leave", function()
        CloseTopPanelList(id)
    end)
end

local function AddGenericYieldTreeNode(tree, label, value, tooltip)
    local node = MakeTreeItem(FormatNodeLabel(label, value), nil)
    local detailLines = GetTooltipDetailLines(tooltip)
    AddBreakdownTree(node, detailLines)
    tree:AddChild(node)
end

local function AddGoldYieldTreeNode(tree)
    local _, player = GetLocalPlayer()
    if not player then return end
    if not GameCapabilities.HasCapability("CAPABILITY_GOLD")
        or not GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then return end

    local treasury = player:GetTreasury()
    local goldYield = treasury:GetGoldYield() - treasury:GetTotalMaintenance()
    local goldBalance = math.floor(treasury:GetGoldBalance())
    local value = Locale.Lookup("LOC_CAI_TOP_PANEL_BALANCE_AND_RATE",
        FormatBalance(goldBalance),
        FormatRatePerTurn(FormatValuePerTurn(goldYield)))
    local node = MakeTreeItem(FormatNodeLabel(Locale.Lookup("LOC_TOP_PANEL_GOLD"), value), nil)

    local income = MakeTreeItem(Locale.Lookup("LOC_TOP_PANEL_GOLD_INCOME", treasury:GetGoldYield()), nil)
    AddBreakdownTree(income, SplitTooltipLines(treasury:GetGoldYieldToolTip()))
    node:AddChild(income)

    local expense = MakeTreeItem(Locale.Lookup("LOC_TOP_PANEL_GOLD_EXPENSE", -treasury:GetTotalMaintenance()), nil)
    AddBreakdownTree(expense, SplitTooltipLines(treasury:GetTotalMaintenanceToolTip()))
    node:AddChild(expense)

    tree:AddChild(node)
end

local function AddTradeRouteTreeNode(tree)
    local _, player = GetLocalPlayer()
    if not player then return end
    if not GameCapabilities.HasCapability("CAPABILITY_TRADE") then return end

    local playerTrade = player:GetTrade()
    local routesActive = playerTrade:GetNumOutgoingRoutes()
    local routesCapacity = playerTrade:GetOutgoingRouteCapacity()
    if routesCapacity > 0 then
        local node = MakeTreeItem(Locale.Lookup("LOC_CAI_TOP_PANEL_TRADE_ROUTES",
            routesActive, routesCapacity), nil)
        tree:AddChild(node)
    end
end

local function AddEnvoyTreeNode(tree)
    local _, player = GetLocalPlayer()
    if not player then return end
    if not GameCapabilities.HasCapability("CAPABILITY_TOP_PANEL_ENVOYS") then return end

    local playerInfluence = player:GetInfluence()
    local currentEnvoys = playerInfluence:GetTokensToGive()
    local influenceBalance = Round(playerInfluence:GetPointsEarned(), 1)
    local influenceRate = Round(playerInfluence:GetPointsPerTurn(), 1)
    local influenceThreshold = playerInfluence:GetPointsThreshold()
    local envoysPerThreshold = playerInfluence:GetTokensPerThreshold()

    local node = MakeTreeItem(Locale.Lookup("LOC_CAI_TOP_PANEL_ENVOYS_SUMMARY",
        currentEnvoys, influenceBalance, influenceThreshold), nil)

    node:AddChild(MakeTreeItem(Locale.Lookup("LOC_TOP_PANEL_INFLUENCE_TOOLTIP_POINTS_RATE", influenceRate), nil))
    node:AddChild(MakeTreeItem(Locale.Lookup("LOC_TOP_PANEL_INFLUENCE_TOOLTIP_POINTS_THRESHOLD", envoysPerThreshold, influenceThreshold), nil))

    tree:AddChild(node)
end

local function AddFavorTreeNode(tree)
    if not IsExpansion2Active() then return end
    local _, player = GetLocalPlayer()
    if not player then return end

    local playerFavor = player:GetFavor()
    local favorPerTurn = player:GetFavorPerTurn()
    local value = Locale.Lookup("LOC_CAI_TOP_PANEL_BALANCE_AND_RATE",
        FormatBalance(playerFavor),
        FormatRatePerTurn(FormatValuePerTurn(favorPerTurn)))
    local node = MakeTreeItem(FormatNodeLabel(Locale.Lookup("LOC_CAI_TOP_PANEL_FAVOR"), value), nil)

    local details = player:GetFavorPerTurnToolTip()
    if details and #details > 0 then
        AddBreakdownTree(node, SplitTooltipLines(details))
    end

    tree:AddChild(node)
end

local function AddWMDTreeNode(tree)
    local _, player = GetLocalPlayer()
    if not player then return end

    local playerWMDs = player:GetWMDs()
    local hasAny = false
    for entry in GameInfo.WMDs() do
        if entry.WeaponType == "WMD_NUCLEAR_DEVICE" then
            local count = playerWMDs:GetWeaponCount(entry.Index)
            if count > 0 then
                tree:AddChild(MakeTreeItem(Locale.Lookup("LOC_CAI_TOP_PANEL_NUCLEAR_DEVICES", count), nil))
                hasAny = true
            end
        elseif entry.WeaponType == "WMD_THERMONUCLEAR_DEVICE" then
            local count = playerWMDs:GetWeaponCount(entry.Index)
            if count > 0 then
                tree:AddChild(MakeTreeItem(Locale.Lookup("LOC_CAI_TOP_PANEL_THERMONUCLEAR_DEVICES", count), nil))
                hasAny = true
            end
        end
    end
end

local function OpenYieldInfoList()
    CloseTopPanelList()

    local tree = mgr:CreateWidget(TOP_PANEL_YIELD_INFO_ID, "Tree", {
        Label = function() return Locale.Lookup("LOC_CAI_TOP_PANEL_YIELD_INFO") end,
    })
    AddListEscapeBinding(tree)
    AddTransientFocusLeave(tree, TOP_PANEL_YIELD_INFO_ID)

    local _, player = GetLocalPlayer()
    if player then
        if GameCapabilities.HasCapability("CAPABILITY_SCIENCE")
            and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
            local techs = player:GetTechs()
            AddGenericYieldTreeNode(tree,
                Locale.Lookup("LOC_TOP_PANEL_SCIENCE"),
                FormatRatePerTurn(FormatValuePerTurn(techs:GetScienceYield())),
                GetScienceTooltip())
        end

        if GameCapabilities.HasCapability("CAPABILITY_CULTURE")
            and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
            local culture = player:GetCulture()
            AddGenericYieldTreeNode(tree,
                Locale.Lookup("LOC_TOP_PANEL_CULTURE"),
                FormatRatePerTurn(FormatValuePerTurn(culture:GetCultureYield())),
                GetCultureTooltip())
        end

        AddGoldYieldTreeNode(tree)
        AddTradeRouteTreeNode(tree)

        if GameCapabilities.HasCapability("CAPABILITY_FAITH")
            and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
            local religion = player:GetReligion()
            AddGenericYieldTreeNode(tree,
                Locale.Lookup("LOC_TOP_PANEL_FAITH"),
                Locale.Lookup("LOC_CAI_TOP_PANEL_BALANCE_AND_RATE",
                    FormatBalance(religion:GetFaithBalance()),
                    FormatRatePerTurn(FormatValuePerTurn(religion:GetFaithYield()))),
                GetFaithTooltip())
        end

        if GameCapabilities.HasCapability("CAPABILITY_TOURISM")
            and GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS") then
            local tourismRate = Round(player:GetStats():GetTourism(), 1)
            if tourismRate > 0 then
                local tourismTooltip = Locale.Lookup("LOC_WORLD_RANKINGS_OVERVIEW_CULTURE_TOURISM_RATE", tourismRate)
                local tourismBreakdown = player:GetStats():GetTourismToolTip()
                if tourismBreakdown and #tourismBreakdown > 0 then
                    tourismTooltip = tourismTooltip .. "[NEWLINE][NEWLINE]" .. tourismBreakdown
                end
                AddGenericYieldTreeNode(tree,
                    Locale.Lookup("LOC_TOP_PANEL_TOURISM"),
                    FormatRatePerTurn(FormatBalance(tourismRate)),
                    tourismTooltip)
            end
        end

        AddFavorTreeNode(tree)
        AddEnvoyTreeNode(tree)
        AddWMDTreeNode(tree)
    end

    if tree.Children and #tree.Children > 0 then
        m_caiTopPanelList = tree
        mgr:Push(m_caiTopPanelList, { priority = PopupPriority.Low })
    end
end

-- ===========================================================================
-- Strategic resource tree (Ctrl+Q)
-- ===========================================================================
local function OpenResourceInfoTree()
    CloseTopPanelList()

    local tree = mgr:CreateWidget(TOP_PANEL_RESOURCE_INFO_ID, "Tree", {
        Label = function() return Locale.Lookup("LOC_CAI_TOP_PANEL_RESOURCE_INFO") end,
    })
    AddListEscapeBinding(tree)
    AddTransientFocusLeave(tree, TOP_PANEL_RESOURCE_INFO_ID)

    local _, player = GetLocalPlayer()
    if player then
        local pResources = player:GetResources()
        local isXP2 = IsExpansion2Active()

        for resource in GameInfo.Resources() do
            if resource.ResourceClassType ~= nil
                and resource.ResourceClassType ~= "RESOURCECLASS_BONUS"
                and resource.ResourceClassType ~= "RESOURCECLASS_LUXURY"
                and resource.ResourceClassType ~= "RESOURCECLASS_ARTIFACT" then

                local resType = resource.ResourceType
                local stockpileAmount = pResources:GetResourceAmount(resType)

                if isXP2 then
                    local stockpileCap = pResources:GetResourceStockpileCap(resType)
                    local reservedAmount = pResources:GetReservedResourceAmount(resType)
                    local accumulationPerTurn = pResources:GetResourceAccumulationPerTurn(resType)
                    local importPerTurn = pResources:GetResourceImportPerTurn(resType)
                    local bonusPerTurn = pResources:GetBonusResourcePerTurn(resType)
                    local unitConsumptionPerTurn = pResources:GetUnitResourceDemandPerTurn(resType)
                    local powerConsumptionPerTurn = pResources:GetPowerResourceDemandPerTurn(resType)
                    local totalAccumulationPerTurn = accumulationPerTurn + importPerTurn + bonusPerTurn
                    local totalConsumptionPerTurn = unitConsumptionPerTurn + powerConsumptionPerTurn

                    if stockpileAmount > 0 or totalAccumulationPerTurn > 0 or totalConsumptionPerTurn > 0 then
                        local resName = Locale.Lookup(resource.Name)
                        local nodeLabel = resName .. ": " .. stockpileAmount .. "/" .. stockpileCap
                            .. " " .. Locale.Lookup("LOC_RESOURCE_ITEM_IN_STOCKPILE")
                        local tooltipParts = {}
                        table.insert(tooltipParts, Locale.Lookup("LOC_RESOURCE_ACCUMULATION_PER_TURN", totalAccumulationPerTurn))
                        if totalConsumptionPerTurn > 0 then
                            table.insert(tooltipParts, Locale.Lookup("LOC_RESOURCE_CONSUMPTION", totalConsumptionPerTurn))
                        end
                        local node = MakeTreeItem(nodeLabel, table.concat(tooltipParts, ", "))

                        if reservedAmount > 0 then
                            node:AddChild(MakeTreeItem(
                                "-" .. reservedAmount .. " " .. Locale.Lookup("LOC_RESOURCE_ITEM_IN_RESERVE"), nil))
                        end

                        local accNode = MakeTreeItem(
                            Locale.Lookup("LOC_RESOURCE_ACCUMULATION_PER_TURN", totalAccumulationPerTurn), nil)
                        if accumulationPerTurn > 0 then
                            accNode:AddChild(MakeTreeItem(
                                Locale.Lookup("LOC_RESOURCE_ACCUMULATION_PER_TURN_EXTRACTED", accumulationPerTurn), nil))
                        end
                        if importPerTurn > 0 then
                            accNode:AddChild(MakeTreeItem(
                                Locale.Lookup("LOC_RESOURCE_ACCUMULATION_PER_TURN_FROM_CITY_STATES", importPerTurn), nil))
                        end
                        if bonusPerTurn > 0 then
                            accNode:AddChild(MakeTreeItem(
                                Locale.Lookup("LOC_RESOURCE_ACCUMULATION_PER_TURN_FROM_BONUS_SOURCES", bonusPerTurn), nil))
                        end
                        node:AddChild(accNode)

                        if totalConsumptionPerTurn > 0 then
                            local conNode = MakeTreeItem(
                                Locale.Lookup("LOC_RESOURCE_CONSUMPTION", totalConsumptionPerTurn), nil)
                            if unitConsumptionPerTurn > 0 then
                                conNode:AddChild(MakeTreeItem(
                                    Locale.Lookup("LOC_RESOURCE_UNIT_CONSUMPTION_PER_TURN", unitConsumptionPerTurn), nil))
                            end
                            if powerConsumptionPerTurn > 0 then
                                conNode:AddChild(MakeTreeItem(
                                    Locale.Lookup("LOC_RESOURCE_POWER_CONSUMPTION_PER_TURN", powerConsumptionPerTurn), nil))
                            end
                            node:AddChild(conNode)
                        end

                        tree:AddChild(node)
                    end
                else
                    if stockpileAmount > 0 then
                        local resName = Locale.Lookup(resource.Name)
                        tree:AddChild(MakeTreeItem(resName .. ": " .. stockpileAmount, nil))
                    end
                end
            end
        end
    end

    if tree.Children and #tree.Children > 0 then
        m_caiTopPanelList = tree
        mgr:Push(m_caiTopPanelList, { priority = PopupPriority.Low })
    else
        Speak(Locale.Lookup("LOC_CAI_TOP_PANEL_NO_STRATEGIC_RESOURCES"))
    end
end

-- ===========================================================================
-- Input handler
-- ===========================================================================
local function OnCAITopPanelInputAction(actionId)
    if ContextPtr:IsHidden() then return end
    if actionId == ACTION_SPEAK_TURN_TIME_DATE then
        SpeakTurnTimeDate()
    elseif actionId == ACTION_SPEAK_GOLD then
        SpeakGold()
    elseif actionId == ACTION_SPEAK_FAITH then
        SpeakFaith()
    elseif actionId == ACTION_SPEAK_TOURISM then
        SpeakTourism()
    elseif actionId == ACTION_SPEAK_FAVOR then
        SpeakFavor()
    elseif actionId == ACTION_SPEAK_NUKES then
        SpeakNukes()
    elseif actionId == ACTION_OPEN_YIELD_LIST then
        OpenYieldInfoList()
    elseif actionId == ACTION_OPEN_RESOURCE_LIST then
        OpenResourceInfoTree()
    elseif actionId == ACTION_OPEN_DIPLOMACY then
        if GameCapabilities.HasCapability("CAPABILITY_DIPLOMACY") then
            LuaEvents.TopPanel_OpenDiplomacyActionView()
        end
    elseif actionId == ACTION_OPEN_REPORTS then
        LuaEvents.TopPanel_OpenReportsScreen()
    elseif actionId == ACTION_OPEN_REPORTS_RESOURCES then
        LuaEvents.ReportsList_OpenResources()
    elseif actionId == ACTION_OPEN_REPORTS_CITY_STATUS then
        LuaEvents.ReportsList_OpenCityStatus()
    elseif actionId == ACTION_OPEN_REPORTS_GOSSIP then
        if GameCapabilities.HasCapability("CAPABILITY_GOSSIP_REPORT") then
            LuaEvents.ReportsList_OpenGossip()
        end
    elseif actionId == ACTION_OPEN_GLOBAL_RESOURCES then
        if GameCapabilities.HasCapability("CAPABILITY_DIPLOMACY_DEALS") then
            LuaEvents.GlobalReportsList_OpenResources()
        end
    end
end

function OnShutdown()
    Events.InputActionTriggered.Remove(OnCAITopPanelInputAction)
    CloseTopPanelList()
end

ContextPtr:SetShutdown(OnShutdown)

Events.InputActionTriggered.Add(OnCAITopPanelInputAction)
