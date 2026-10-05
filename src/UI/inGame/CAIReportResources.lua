-- Shared Resources report section. The screen supplies its live data and widget factories.
CAIReportResources = {}

---@param mgr UIScreenManager
---@param context CAIReportResourcesContext
---@return CAIReportResourcesController
function CAIReportResources.Create(mgr, context)
    local MakeTreeItem = context.MakeTreeItem
    local MakeStaticText = context.MakeStaticText
    local AddLeaf = context.AddLeaf
    local toPlusMinus = context.FormatSigned

    local function GetXP2ResourceFlowData(eResourceType)
        local localPlayer = Players[context.GetLocalPlayerID()]
        if not localPlayer then return nil end
        local pResources = localPlayer:GetResources()
        if not pResources then return nil end
        local kResource = GameInfo.Resources[eResourceType]
        if not kResource then return nil end

        local resourceType = kResource.ResourceType
        local extracted = pResources:GetResourceAccumulationPerTurn(resourceType)
        local imports = pResources:GetResourceImportPerTurn(resourceType)
        local bonus = pResources:GetBonusResourcePerTurn(resourceType)
        local unitCost = pResources:GetUnitResourceDemandPerTurn(resourceType)
        local powerCost = pResources:GetPowerResourceDemandPerTurn(resourceType)
        local reserved = pResources:GetReservedResourceAmount(resourceType)
        local accumulation = extracted + imports + bonus
        local consumption = unitCost + powerCost

        return {
            Accumulation = accumulation,
            Extracted = extracted,
            Imports = imports,
            Bonus = bonus,
            UnitCost = unitCost,
            PowerCost = powerCost,
            Consumption = consumption,
            Reserved = reserved,
            Delta = accumulation - consumption,
        }
    end

    local function FormatResourceEntryLabel(kEntry)
        local source = Locale.Lookup(kEntry.EntryText)
        local control = kEntry.ControlText ~= "-" and Locale.Lookup(kEntry.ControlText) or nil
        local parts = { source }
        CAIText.AppendIfNonEmpty(parts, control)
        table.insert(parts, toPlusMinus(kEntry.Amount))
        return table.concat(parts, "[NEWLINE]")
    end

    local function BuildResourceItem(parent, eResourceType, kSingleResourceData)
        local capturedResType = eResourceType
        local capturedResData = kSingleResourceData
        local kResource = GameInfo.Resources[capturedResType]
        local flow = context.IsExpansion2 and capturedResData.IsStrategic and GetXP2ResourceFlowData(capturedResType) or nil
        local extractionEntries = {}
        local cityStateEntries = {}
        local fallbackEntries = {}
        local namedExtractionTotal = 0
        local namedCityStateTotal = 0

        if flow then
            for ei, kEntry in ipairs(capturedResData.EntryList or {}) do
                local classifiedEntry = { Entry = kEntry, Index = ei }
                if kEntry.ControlText == "LOC_HUD_REPORTS_TRADE_OWNED" then
                    table.insert(extractionEntries, classifiedEntry)
                    namedExtractionTotal = namedExtractionTotal + kEntry.Amount
                elseif kEntry.ControlText == "LOC_CITY_STATES_SUZERAIN" then
                    table.insert(cityStateEntries, classifiedEntry)
                    namedCityStateTotal = namedCityStateTotal + kEntry.Amount
                elseif kEntry.EntryText ~= "LOC_PRODUCTION_PANEL_UNITS_TOOLTIP"
                    and kEntry.EntryText ~= "LOC_UI_PEDIA_POWER_COST"
                    and kEntry.EntryText ~= "LOC_RESOURCE_REPORTS_ITEM_IN_RESERVE"
                    and kEntry.EntryText ~= "LOC_RESOURCE_REPORTS_CITY_STATES"
                    and kEntry.EntryText ~= "LOC_HUD_REPORTS_MISC_RESOURCE_SOURCE"
                    and not (kEntry.EntryText == "" and kEntry.ControlText == "" and kEntry.Amount == 0) then
                    table.insert(fallbackEntries, classifiedEntry)
                end
            end
        end

        local resItem = MakeTreeItem({
            Label = function()
                local name = Locale.Lookup(kResource.Name)
                if context.IsExpansion2 and capturedResData.IsStrategic and capturedResData.Stockpile then
                    local text = Locale.Lookup("LOC_CAI_REPORTS_RESOURCE_STOCKPILE",
                        name, capturedResData.Stockpile, capturedResData.Maximum or 0)
                    if flow then
                        text = CAIText.JoinLines({ text, Locale.Lookup("LOC_HUD_REPORTS_PER_TURN", toPlusMinus(flow.Delta)) })
                    end
                    return text
                else
                    return Locale.Lookup("LOC_CAI_REPORTS_RESOURCE_TOTAL", name, capturedResData.Total)
                end
            end,
            Tooltip = function()
                local localPlayer = Players[context.GetLocalPlayerID()]
                if localPlayer then
                    local citiesProvidedTo = localPlayer:GetResources():GetResourceAllocationCities(kResource.Index)
                    local numCities = table.count(citiesProvidedTo)
                    if numCities > 0 then
                        local cityNames = {}
                        local playerCities = localPlayer:GetCities()
                        for _, city in ipairs(citiesProvidedTo) do
                            local pCity = playerCities:FindID(city.CityID)
                            if pCity then
                                table.insert(cityNames, Locale.Lookup(pCity:GetName()))
                            end
                        end
                        return CAIText.JoinLines({
                            Locale.Lookup("LOC_CAI_REPORTS_AMENITIES_PROVIDED", numCities),
                            table.concat(cityNames, "[NEWLINE]")
                        })
                    end
                end
                return nil
            end,
            FocusKey = "res:" .. tostring(capturedResType),
        })
        local resourceHasChildren = #(capturedResData.EntryList or {}) > 0 or flow ~= nil
        if resourceHasChildren then
            parent:AddChild(resItem)

            if flow then
                if flow.Reserved > 0 then
                    AddLeaf(resItem, "res:" .. tostring(capturedResType) .. ":reserved", function()
                        return "-" .. flow.Reserved .. " " .. Locale.Lookup("LOC_RESOURCE_ITEM_IN_RESERVE")
                    end)
                end

                local hasAccumulationDetails = flow.Extracted > 0 or flow.Imports > 0 or flow.Bonus > 0
                if hasAccumulationDetails then
                    local accumulationNode = MakeTreeItem({
                        Label = function()
                            return Locale.Lookup("LOC_RESOURCE_ACCUMULATION_PER_TURN", flow.Accumulation)
                        end,
                        FocusKey = "res:" .. tostring(capturedResType) .. ":accumulation",
                    })
                    resItem:AddChild(accumulationNode)
                    if flow.Extracted > 0 then
                        local miscellaneousExtraction = math.max(0, flow.Extracted - namedExtractionTotal)
                        if #extractionEntries > 0 or miscellaneousExtraction > 0 then
                            local extractionNode = MakeTreeItem({
                                Label = function()
                                    return Locale.Lookup("LOC_RESOURCE_ACCUMULATION_PER_TURN_EXTRACTED", flow.Extracted)
                                end,
                                FocusKey = "res:" .. tostring(capturedResType) .. ":accumulation:extracted",
                            })
                            accumulationNode:AddChild(extractionNode)
                            for _, classifiedEntry in ipairs(extractionEntries) do
                                local capturedEntry = classifiedEntry.Entry
                                local capturedEI = classifiedEntry.Index
                                AddLeaf(extractionNode,
                                    "res:" .. tostring(capturedResType) .. ":entry:" .. capturedEI,
                                    function() return FormatResourceEntryLabel(capturedEntry) end)
                            end
                            if miscellaneousExtraction > 0 then
                                AddLeaf(extractionNode,
                                    "res:" .. tostring(capturedResType) .. ":accumulation:extracted:misc",
                                    function()
                                        return Locale.Lookup("LOC_HUD_REPORTS_MISC_RESOURCE_SOURCE")
                                            .. "[NEWLINE]" .. toPlusMinus(miscellaneousExtraction)
                                    end)
                            end
                        else
                            AddLeaf(accumulationNode,
                                "res:" .. tostring(capturedResType) .. ":accumulation:extracted",
                                function()
                                    return Locale.Lookup("LOC_RESOURCE_ACCUMULATION_PER_TURN_EXTRACTED", flow.Extracted)
                                end)
                        end
                    end
                    if flow.Imports > 0 then
                        local miscellaneousCityStates = math.max(0, flow.Imports - namedCityStateTotal)
                        if #cityStateEntries > 0 then
                            local cityStateNode = MakeTreeItem({
                                Label = function()
                                    return Locale.Lookup("LOC_RESOURCE_ACCUMULATION_PER_TURN_FROM_CITY_STATES", flow.Imports)
                                end,
                                FocusKey = "res:" .. tostring(capturedResType) .. ":accumulation:imports",
                            })
                            accumulationNode:AddChild(cityStateNode)
                            for _, classifiedEntry in ipairs(cityStateEntries) do
                                local capturedEntry = classifiedEntry.Entry
                                local capturedEI = classifiedEntry.Index
                                AddLeaf(cityStateNode,
                                    "res:" .. tostring(capturedResType) .. ":entry:" .. capturedEI,
                                    function() return FormatResourceEntryLabel(capturedEntry) end)
                            end
                            if miscellaneousCityStates > 0 then
                                AddLeaf(cityStateNode,
                                    "res:" .. tostring(capturedResType) .. ":accumulation:imports:misc",
                                    function()
                                        return Locale.Lookup("LOC_HUD_REPORTS_MISC_RESOURCE_SOURCE")
                                            .. "[NEWLINE]" .. toPlusMinus(miscellaneousCityStates)
                                    end)
                            end
                        else
                            AddLeaf(accumulationNode,
                                "res:" .. tostring(capturedResType) .. ":accumulation:imports",
                                function()
                                    return Locale.Lookup("LOC_RESOURCE_ACCUMULATION_PER_TURN_FROM_CITY_STATES", flow.Imports)
                                end)
                        end
                    end
                    if flow.Bonus > 0 then
                        AddLeaf(accumulationNode, "res:" .. tostring(capturedResType) .. ":accumulation:bonus",
                            function()
                                return Locale.Lookup("LOC_RESOURCE_ACCUMULATION_PER_TURN_FROM_BONUS_SOURCES", flow.Bonus)
                            end)
                    end
                else
                    AddLeaf(resItem, "res:" .. tostring(capturedResType) .. ":accumulation", function()
                        return Locale.Lookup("LOC_RESOURCE_ACCUMULATION_PER_TURN", flow.Accumulation)
                    end)
                end

                if flow.Consumption > 0 then
                    local consumptionNode = MakeTreeItem({
                        Label = function() return Locale.Lookup("LOC_RESOURCE_CONSUMPTION", flow.Consumption) end,
                        FocusKey = "res:" .. tostring(capturedResType) .. ":consumption",
                    })
                    resItem:AddChild(consumptionNode)
                    if flow.UnitCost > 0 then
                        AddLeaf(consumptionNode, "res:" .. tostring(capturedResType) .. ":consumption:units",
                            function()
                                return Locale.Lookup("LOC_RESOURCE_UNIT_CONSUMPTION_PER_TURN", flow.UnitCost)
                            end)
                    end
                    if flow.PowerCost > 0 then
                        AddLeaf(consumptionNode, "res:" .. tostring(capturedResType) .. ":consumption:power",
                            function()
                                return Locale.Lookup("LOC_RESOURCE_POWER_CONSUMPTION_PER_TURN", flow.PowerCost)
                            end)
                    end
                end
            end

            local detailEntries = flow and fallbackEntries or capturedResData.EntryList or {}
            if #detailEntries > 0 then
                local detailsNode = MakeTreeItem({
                    Label = function() return Locale.Lookup("LOC_CAI_REPORTS_RESOURCE_DETAILS") end,
                    FocusKey = "res:" .. tostring(capturedResType) .. ":details",
                })
                resItem:AddChild(detailsNode)

                for ei, detailEntry in ipairs(detailEntries) do
                    local capturedEntry = flow and detailEntry.Entry or detailEntry
                    local capturedEI = flow and detailEntry.Index or ei
                    local detail = MakeStaticText({
                        Label = function() return FormatResourceEntryLabel(capturedEntry) end,
                        FocusKey = "res:" .. tostring(capturedResType) .. ":entry:" .. capturedEI,
                    })
                    detailsNode:AddChild(detail)
                end
            end
        else
            local leafLabel = function()
                local baseLabel = resItem:GetLabel()
                local tooltip = resItem:GetTooltip()
                if tooltip ~= nil and tooltip ~= "" then
                    return CAIText.JoinLines({ baseLabel, tooltip })
                end
                return baseLabel
            end
            parent:AddChild(MakeStaticText({
                Label = leafLabel,
                FocusKey = "res:" .. tostring(capturedResType),
            }))
        end
    end

    local function Rebuild(tree)
        local capture = mgr:CaptureFocusKey(tree)
        tree:ClearChildren()

        local strategic = {}
        local luxury = {}
        local bonus = {}

        local includedResourceTypes = {}
        for eResourceType, kSingleResourceData in pairs(context.GetResourceData()) do
            local flow = context.IsExpansion2 and kSingleResourceData.IsStrategic and GetXP2ResourceFlowData(eResourceType) or nil
            local hasStrategicFlow = flow ~= nil
                and (flow.Accumulation ~= 0 or flow.Consumption ~= 0 or flow.Reserved ~= 0)
            if next(kSingleResourceData.EntryList) or
                (context.IsExpansion2 and kSingleResourceData.IsStrategic
                    and ((kSingleResourceData.Stockpile and kSingleResourceData.Stockpile > 0) or hasStrategicFlow)) then
                includedResourceTypes[eResourceType] = true
                if kSingleResourceData.IsStrategic then
                    table.insert(strategic, { type = eResourceType, data = kSingleResourceData })
                elseif kSingleResourceData.IsLuxury then
                    table.insert(luxury, { type = eResourceType, data = kSingleResourceData })
                else
                    table.insert(bonus, { type = eResourceType, data = kSingleResourceData })
                end
            end
        end

        if context.IsExpansion2 then
            local localPlayer = Players[context.GetLocalPlayerID()]
            local playerResources = localPlayer and localPlayer:GetResources() or nil
            if playerResources then
                for resource in GameInfo.Resources() do
                    if resource.ResourceClassType == "RESOURCECLASS_STRATEGIC"
                        and not includedResourceTypes[resource.Index] then
                        local flow = GetXP2ResourceFlowData(resource.Index)
                        local stockpile = playerResources:GetResourceAmount(resource.ResourceType)
                        if stockpile > 0 or (flow and (flow.Accumulation ~= 0 or flow.Consumption ~= 0
                            or flow.Reserved ~= 0)) then
                            table.insert(strategic, {
                                type = resource.Index,
                                data = {
                                    EntryList = {},
                                    IsStrategic = true,
                                    IsLuxury = false,
                                    IsBonus = false,
                                    Total = flow and flow.Delta or 0,
                                    Maximum = playerResources:GetResourceStockpileCap(resource.ResourceType),
                                    Stockpile = stockpile,
                                },
                            })
                        end
                    end
                end
            end
        end

        local function sortByName(a, b)
            return Locale.Lookup(GameInfo.Resources[a.type].Name) < Locale.Lookup(GameInfo.Resources[b.type].Name)
        end
        table.sort(strategic, sortByName)
        table.sort(luxury, sortByName)
        table.sort(bonus, sortByName)

        local categories = {
            { key = "strategic", label = "LOC_RESOURCECLASS_STRATEGIC_NAME", items = strategic },
            { key = "luxury",    label = "LOC_RESOURCECLASS_LUXURY_NAME",    items = luxury },
            { key = "bonus",     label = "LOC_RESOURCECLASS_BONUS_NAME",     items = bonus },
        }

        for _, cat in ipairs(categories) do
            if #cat.items > 0 then
                local capturedCat = cat
                local catGroup = MakeTreeItem({
                    Label = function()
                        return CAIText.JoinLines({
                            Locale.Lookup(capturedCat.label),
                            Locale.Lookup("LOC_CAI_REPORTS_RESOURCE_COUNT", #capturedCat.items)
                        })
                    end,
                    FocusKey = "res:group:" .. capturedCat.key,
                })
                tree:AddChild(catGroup)

                for _, entry in ipairs(capturedCat.items) do
                    BuildResourceItem(catGroup, entry.type, entry.data)
                end
            end
        end

        mgr:RestoreFocus(tree, capture)
    end


    return { Rebuild = Rebuild }
end
