include("inGameHelpers_CAI")

CAIInterfaceTargets = CAIInterfaceTargets or {}

local TARGET_KIND_PLOT = "plot"
local TARGET_KIND_UNIT = "unit"

local m_targetCache = nil
local m_actionPlotCache = nil

CAIInterfaceTargets.KindUnit = TARGET_KIND_UNIT

-- ===========================================================================
-- CACHE SIGNATURE AND UTILITY HELPERS
-- ===========================================================================
local function AppendSignatureValue(parts, value)
    parts[#parts + 1] = tostring(value or "")
end

local function AddSelectedUnitSignature(parts)
    local unit = UI.GetHeadSelectedUnit()
    if unit == nil then
        AppendSignatureValue(parts, "unit:nil")
        return
    end
    AppendSignatureValue(parts, "unit")
    AppendSignatureValue(parts, unit:GetOwner())
    AppendSignatureValue(parts, unit:GetID())
    AppendSignatureValue(parts, unit:GetPlotId())
end

local function AddSelectedCitySignature(parts, city)
    city = city or UI.GetHeadSelectedCity()
    if city == nil then
        AppendSignatureValue(parts, "city:nil")
        return
    end
    AppendSignatureValue(parts, "city")
    AppendSignatureValue(parts, city.GetOwner and city:GetOwner() or nil)
    AppendSignatureValue(parts, city.GetID and city:GetID() or nil)
    AppendSignatureValue(parts, city.GetX and city:GetX() or nil)
    AppendSignatureValue(parts, city.GetY and city:GetY() or nil)
end

local function AddInterfaceParameterSignature(parts, key)
    AppendSignatureValue(parts, UI.GetInterfaceModeParameter(key))
end

local function BuildTargetCacheSignature(mode)
    local parts = { tostring(mode) }

    if mode == InterfaceModeTypes.CITY_RANGE_ATTACK then
        AddSelectedCitySignature(parts)
        AddInterfaceParameterSignature(parts, CityCommandTypes.PARAM_RANGED_ATTACK)
    elseif mode == InterfaceModeTypes.DISTRICT_RANGE_ATTACK then
        local district = UI.GetHeadSelectedDistrict()
        AddSelectedCitySignature(parts, district)
        AddInterfaceParameterSignature(parts, CityCommandTypes.PARAM_RANGED_ATTACK)
    elseif mode == InterfaceModeTypes.ICBM_STRIKE then
        AddSelectedCitySignature(parts)
        AddInterfaceParameterSignature(parts, CityCommandTypes.PARAM_WMD_TYPE)
        AddInterfaceParameterSignature(parts, CityCommandTypes.PARAM_X0)
        AddInterfaceParameterSignature(parts, CityCommandTypes.PARAM_Y0)
    elseif mode == InterfaceModeTypes.DISTRICT_PLACEMENT then
        AddSelectedCitySignature(parts)
        AddInterfaceParameterSignature(parts, CityOperationTypes.PARAM_DISTRICT_TYPE)
        AddInterfaceParameterSignature(parts, CityCommandTypes.PARAM_PLOT_PURCHASE)
    elseif mode == InterfaceModeTypes.BUILDING_PLACEMENT then
        AddSelectedCitySignature(parts)
        AddInterfaceParameterSignature(parts, CityOperationTypes.PARAM_BUILDING_TYPE)
        AddInterfaceParameterSignature(parts, CityCommandTypes.PARAM_PLOT_PURCHASE)
    else
        AddSelectedUnitSignature(parts)
        if mode == InterfaceModeTypes.WMD_STRIKE then
            AddInterfaceParameterSignature(parts, UnitOperationTypes.PARAM_WMD_TYPE)
        elseif mode == InterfaceModeTypes.TELEPORT_TO_CITY then
            AddInterfaceParameterSignature(parts, UnitOperationTypes.PARAM_OPERATION_TYPE)
        elseif mode == InterfaceModeTypes.BUILD_IMPROVEMENT_ADJACENT then
            AddInterfaceParameterSignature(parts, UnitOperationTypes.PARAM_OPERATION_TYPE)
            AddInterfaceParameterSignature(parts, UnitOperationTypes.PARAM_IMPROVEMENT_TYPE)
        end
    end

    return table.concat(parts, ":")
end

-- ===========================================================================
--  PASSIVE UNIT SELECTION ACTIONS
-- ===========================================================================
function CAIInterfaceTargets.GetSelectedUnitActionPlots()
    local mode = UI.GetInterfaceMode()
    local signature = BuildTargetCacheSignature(mode)

    if m_actionPlotCache ~= nil and m_actionPlotCache.Signature == signature then
        return m_actionPlotCache.Plots
    end

    local plots = {}
    local kUnit = UI.GetHeadSelectedUnit()
    if kUnit == nil or UI.IsGameCoreBusy() then
        m_actionPlotCache = { Signature = signature, Plots = plots }
        return plots
    end

    local playerID = kUnit:GetOwner()
    if playerID ~= Game.GetLocalPlayer() then
        m_actionPlotCache = { Signature = signature, Plots = plots }
        return plots
    end

    local sUnitType = GameInfo.Units[kUnit:GetUnitType()].UnitType
    local bCanCauseDisasters = false
    if sUnitType ~= nil and GameInfo.Units_XP2 ~= nil and GameInfo.Units_XP2[sUnitType] ~= nil and GameInfo.Units_XP2[sUnitType].CanCauseDisasters ~= nil then
        bCanCauseDisasters = GameInfo.Units_XP2[sUnitType].CanCauseDisasters
    end

    local kUnitGreatPerson = kUnit:GetGreatPerson()
    if kUnitGreatPerson ~= nil and kUnitGreatPerson:IsGreatPerson() then
        local greatPersonInfo = GameInfo.GreatPersonIndividuals[kUnitGreatPerson:GetIndividual()]
        if greatPersonInfo ~= nil and greatPersonInfo.ActionEffectTileHighlighting then
            for _, plotIndex in ipairs(kUnitGreatPerson:GetActivationHighlightPlots()) do
                table.insert(plots, { PlotIndex = plotIndex, Type = "GreatPerson" })
            end
        end
    elseif kUnit.GetArchaeology and GameInfo.Units[kUnit:GetUnitType()].ExtractsArtifacts == true then
        for _, plotIndex in ipairs(kUnit:GetArchaeology():GetActivationHighlightPlots()) do
            table.insert(plots, { PlotIndex = plotIndex, Type = "Archaeologist" })
        end
    elseif GameInfo.Units[kUnit:GetUnitType()].ParkCharges > 0 and kUnit:GetParkCharges() > 0 then
        for _, plotIndex in ipairs(Game.GetNationalParks():GetPossibleParkTiles(playerID)) do
            table.insert(plots, { PlotIndex = plotIndex, Type = "Naturalist" })
        end
    elseif kUnit.GetRockBand and sUnitType == "UNIT_ROCK_BAND" then
        for _, plotIndex in ipairs(kUnit:GetRockBand():GetActivationHighlightPlots()) do
            table.insert(plots, { PlotIndex = plotIndex, Type = "RockBand" })
        end
    elseif bCanCauseDisasters and GameClimate ~= nil and GameClimate.GetLocationsForPossibleTriggerableEvents ~= nil then
        for _, plotIndex in ipairs(GameClimate.GetLocationsForPossibleTriggerableEvents(playerID)) do
            table.insert(plots, { PlotIndex = plotIndex, Type = "DisasterTrigger" })
        end
    end

    m_actionPlotCache = {
        Signature = signature,
        Plots = plots
    }
    return plots
end

-- ===========================================================================
--  NATIVE ENGINE INTERFACE CONFIGURATIONS
-- ===========================================================================
local PLOT_TARGET_MODES = {
    [InterfaceModeTypes.RANGE_ATTACK] = { Source = "unitOperation", Type = UnitOperationTypes.RANGE_ATTACK, RequireTargetModifier = true },
    [InterfaceModeTypes.CITY_RANGE_ATTACK] = {
        Source = "cityCommand",
        Type = CityCommandTypes.RANGE_ATTACK,
        RequireTargetModifier = true,
        GetSubject = function() return UI.GetHeadSelectedCity() end,
        GetParameters = function()
            return {
                [CityCommandTypes.PARAM_RANGED_ATTACK] = UI.GetInterfaceModeParameter(
                    CityCommandTypes.PARAM_RANGED_ATTACK)
            }
        end,
    },
    [InterfaceModeTypes.DISTRICT_RANGE_ATTACK] = {
        Source = "cityCommand",
        Type = CityCommandTypes.RANGE_ATTACK,
        RequireTargetModifier = true,
        GetSubject = function() return UI.GetHeadSelectedDistrict() end,
        GetParameters = function()
            return {
                [CityCommandTypes.PARAM_RANGED_ATTACK] = UI.GetInterfaceModeParameter(
                    CityCommandTypes.PARAM_RANGED_ATTACK)
            }
        end,
    },
    [InterfaceModeTypes.AIR_ATTACK] = { Source = "unitOperation", Type = UnitOperationTypes.AIR_ATTACK, RequireTargetModifier = true },
    [InterfaceModeTypes.WMD_STRIKE] = {
        Source = "unitOperation",
        Type = UnitOperationTypes.WMD_STRIKE,
        GetParameters = function()
            return {
                [UnitOperationTypes.PARAM_WMD_TYPE] = UI.GetInterfaceModeParameter(
                    UnitOperationTypes.PARAM_WMD_TYPE)
            }
        end,
    },
    [InterfaceModeTypes.ICBM_STRIKE] = {
        Source = "cityCommand",
        Type = CityCommandTypes.WMD_STRIKE,
        GetSubject = function() return UI.GetHeadSelectedCity() end,
        GetParameters = function()
            return {
                [CityCommandTypes.PARAM_WMD_TYPE] = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_WMD_TYPE),
                [CityCommandTypes.PARAM_X0] = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_X0),
                [CityCommandTypes.PARAM_Y0] = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_Y0),
            }
        end,
    },
    [InterfaceModeTypes.COASTAL_RAID] = { Source = "unitOperation", Type = UnitOperationTypes.COASTAL_RAID },
    [InterfaceModeTypes.DEPLOY] = { Source = "unitOperation", Type = UnitOperationTypes.DEPLOY },
    [InterfaceModeTypes.REBASE] = { Source = "unitOperation", Type = UnitOperationTypes.REBASE },
    [InterfaceModeTypes.TELEPORT_TO_CITY] = {
        Source = "unitOperation",
        GetType = function()
            return UI
                .GetInterfaceModeParameter(UnitOperationTypes.PARAM_OPERATION_TYPE)
        end
    },
    [InterfaceModeTypes.BUILD_IMPROVEMENT_ADJACENT] = {
        Source = "unitOperation",
        GetType = function() return UI.GetInterfaceModeParameter(UnitOperationTypes.PARAM_OPERATION_TYPE) end,
        GetParameters = function()
            return {
                [UnitOperationTypes.PARAM_IMPROVEMENT_TYPE] = UI.GetInterfaceModeParameter(
                    UnitOperationTypes.PARAM_IMPROVEMENT_TYPE)
            }
        end,
    },
    [InterfaceModeTypes.SACRIFICE_SELECTION] = { Source = "unitOperation", Type = "UNITOPERATION_SOOTHSAYER_SACRIFICE" },
    [InterfaceModeTypes.AIRLIFT] = { Source = "unitCommand", Type = UnitCommandTypes.AIRLIFT },
    [InterfaceModeTypes.PARADROP] = { Source = "unitCommand", Type = UnitCommandTypes.PARADROP },
    [InterfaceModeTypes.PRIORITY_TARGET] = { Source = "unitCommand", Type = UnitCommandTypes.PRIORITY_TARGET, RequireTargetModifier = true },
    [InterfaceModeTypes.MOVE_JUMP] = { Source = "unitCommand", Type = UnitCommandTypes.MOVE_JUMP },
    [InterfaceModeTypes.KILL_WEAKER_UNIT] = { Source = "unitCommand", Type = UnitCommandTypes.KILL_WEAKER_UNIT },
    [InterfaceModeTypes.TRANSFORM_UNIT] = { Source = "unitCommand", Type = UnitCommandTypes.TRANSFORM_UNIT },
    [InterfaceModeTypes.RESTORE_UNIT_MOVES] = { Source = "unitCommand", Type = UnitCommandTypes.RESTORE_UNIT_MOVES },
    [InterfaceModeTypes.NAVAL_GOLD_RAID] = { Source = "unitCommand", Type = UnitCommandTypes.NAVAL_GOLD_RAID },

    -- District Placement Interface
    [InterfaceModeTypes.DISTRICT_PLACEMENT] = {
        CustomGetTargets = function()
            local out = {}
            local pSelectedCity = UI.GetHeadSelectedCity()
            if pSelectedCity == nil or UI.IsGameCoreBusy() then return out end

            local districtHash = UI.GetInterfaceModeParameter(CityOperationTypes.PARAM_DISTRICT_TYPE)
            local district = GameInfo.Districts[districtHash]
            if district == nil then return out end

            local tParameters = { [CityOperationTypes.PARAM_DISTRICT_TYPE] = districtHash }
            local tResults = CityManager.GetOperationTargets(pSelectedCity, CityOperationTypes.BUILD, tParameters)
            if tResults and tResults[CityOperationResults.PLOTS] then
                for _, plotId in ipairs(tResults[CityOperationResults.PLOTS]) do
                    out[plotId] = "Buildable"
                end
            end

            tParameters = {
                [CityCommandTypes.PARAM_PLOT_PURCHASE] = UI.GetInterfaceModeParameter(CityCommandTypes
                    .PARAM_PLOT_PURCHASE)
            }
            local tPurchaseResults = CityManager.GetCommandTargets(pSelectedCity, CityCommandTypes.PURCHASE, tParameters)
            if tPurchaseResults and tPurchaseResults[CityCommandResults.PLOTS] then
                for _, plotId in ipairs(tPurchaseResults[CityCommandResults.PLOTS]) do
                    local kPlot = Map.GetPlotByIndex(plotId)
                    if kPlot and kPlot:CanHaveDistrict(district.Index, pSelectedCity:GetOwner(), pSelectedCity:GetID()) then
                        if not out[plotId] then
                            out[plotId] = "Purchasable"
                        end
                    end
                end
            end
            return out
        end
    },

    -- Wonder / Building Placement Interface
    [InterfaceModeTypes.BUILDING_PLACEMENT] = {
        CustomGetTargets = function()
            local out = {}
            local pSelectedCity = UI.GetHeadSelectedCity()
            if pSelectedCity == nil or UI.IsGameCoreBusy() then return out end

            local buildingHash = UI.GetInterfaceModeParameter(CityOperationTypes.PARAM_BUILDING_TYPE)
            local building = GameInfo.Buildings[buildingHash]
            if building == nil then return out end

            local tParameters = { [CityOperationTypes.PARAM_BUILDING_TYPE] = buildingHash }
            local tResults = CityManager.GetOperationTargets(pSelectedCity, CityOperationTypes.BUILD, tParameters)
            if tResults and tResults[CityOperationResults.PLOTS] then
                for _, plotId in ipairs(tResults[CityOperationResults.PLOTS]) do
                    out[plotId] = "Buildable"
                end
            end

            tParameters = {
                [CityCommandTypes.PARAM_PLOT_PURCHASE] = UI.GetInterfaceModeParameter(CityCommandTypes
                    .PARAM_PLOT_PURCHASE)
            }
            local tPurchaseResults = CityManager.GetCommandTargets(pSelectedCity, CityCommandTypes.PURCHASE, tParameters)
            if tPurchaseResults and tPurchaseResults[CityCommandResults.PLOTS] then
                for _, plotId in ipairs(tPurchaseResults[CityCommandResults.PLOTS]) do
                    local kPlot = Map.GetPlotByIndex(plotId)
                    if kPlot and kPlot:CanHaveWonder(building.Index, pSelectedCity:GetOwner(), pSelectedCity:GetID()) then
                        if not out[plotId] then
                            out[plotId] = "Purchasable"
                        end
                    end
                end
            end
            return out
        end
    }
}

local UNIT_TARGET_MODES = {
    [InterfaceModeTypes.FORM_CORPS] = UnitCommandTypes.FORM_CORPS,
    [InterfaceModeTypes.FORM_ARMY] = UnitCommandTypes.FORM_ARMY,
}

-- ===========================================================================
--  INTERNAL RESOLUTION METHODS
-- ===========================================================================
local function AddTargetPlotsFromResults(out, plots, modifiers, targetModifier, requireTargetModifier)
    if plots == nil then return end
    for index, plotIndex in ipairs(plots) do
        if not requireTargetModifier or modifiers == nil or modifiers[index] == targetModifier then
            out[plotIndex] = true
        end
    end
end

local function ResolveTargetType(config)
    if config.GetType ~= nil then return config.GetType() end
    return config.Type
end

local function ResolveTargetSubject(config)
    if config.GetSubject ~= nil then return config.GetSubject() end
    return UI.GetHeadSelectedUnit()
end

local function ResolveTargetParameters(config)
    if config.GetParameters ~= nil then return config.GetParameters() end
    return nil
end

local function GetPlotTargetsForConfig(config)
    if config.CustomGetTargets ~= nil then return config.CustomGetTargets() end

    local out = {}
    local subject = ResolveTargetSubject(config)
    local targetType = ResolveTargetType(config)
    if subject == nil or targetType == nil then return out end

    local parameters = ResolveTargetParameters(config)
    if config.Source == "unitOperation" then
        local results = UnitManager.GetOperationTargets(subject, targetType, parameters)
        local modifiers = config.RequireTargetModifier == true and results and results[UnitOperationResults.MODIFIERS] or
            nil
        AddTargetPlotsFromResults(out, results and results[UnitOperationResults.PLOTS], modifiers,
            UnitOperationResults.MODIFIER_IS_TARGET, config.RequireTargetModifier == true)
    elseif config.Source == "unitCommand" then
        local results = UnitManager.GetCommandTargets(subject, targetType, parameters)
        local modifiers = config.RequireTargetModifier == true and results and results[UnitCommandResults.MODIFIERS] or
            nil
        AddTargetPlotsFromResults(out, results and results[UnitCommandResults.PLOTS], modifiers,
            UnitCommandResults.MODIFIER_IS_TARGET, config.RequireTargetModifier == true)
    elseif config.Source == "cityCommand" then
        local results = CityManager.GetCommandTargets(subject, targetType, parameters)
        local modifiers = config.RequireTargetModifier == true and results and results[CityCommandResults.MODIFIERS] or
            nil
        AddTargetPlotsFromResults(out, results and results[CityCommandResults.PLOTS], modifiers,
            CityCommandResults.MODIFIER_IS_TARGET, config.RequireTargetModifier == true)
    end

    return out
end

local function GetCommandTargetUnits(commandType)
    local out = {}
    local selectedUnit = UI.GetHeadSelectedUnit()
    if selectedUnit == nil or commandType == nil then return out end

    local ownerID = selectedUnit:GetOwner()
    local playerUnits = Players[ownerID] and Players[ownerID]:GetUnits() or nil
    if playerUnits == nil then return out end

    local results = UnitManager.GetCommandTargets(selectedUnit, commandType)
    local units = results and results[UnitCommandResults.UNITS] or nil
    if units == nil then return out end

    for _, unitComponentID in ipairs(units) do
        local unitID = unitComponentID.id
        local unit = unitID ~= nil and playerUnits:FindID(unitID) or nil
        if unit ~= nil then out[#out + 1] = unit end
    end

    return out
end

-- ===========================================================================
--  LABEL AND VALUE REFLECTION (Data-Driven Translation Bridge)
-- ===========================================================================
local PLOT_INFO_KEYS_BY_MODE = {
    [InterfaceModeTypes.RANGE_ATTACK] = { "units", "cityName", "districtTitle", "improvement", "resource", "feature", "plotName" },
    [InterfaceModeTypes.CITY_RANGE_ATTACK] = { "units", "cityName", "districtTitle", "improvement", "resource", "feature", "plotName" },
    [InterfaceModeTypes.DISTRICT_RANGE_ATTACK] = { "units", "cityName", "districtTitle", "improvement", "resource", "feature", "plotName" },
    [InterfaceModeTypes.AIR_ATTACK] = { "units", "cityName", "districtTitle", "improvement", "resource", "feature", "plotName" },
    [InterfaceModeTypes.COASTAL_RAID] = { "units", "cityName", "districtTitle", "improvement", "resource", "feature", "plotName" },
    [InterfaceModeTypes.DEPLOY] = { "cityName", "districtTitle", "improvement", "resource", "feature", "plotName" },
    [InterfaceModeTypes.REBASE] = { "cityName", "districtTitle", "plotName" },
    [InterfaceModeTypes.TELEPORT_TO_CITY] = { "cityName", "districtTitle", "plotName" },
    [InterfaceModeTypes.BUILD_IMPROVEMENT_ADJACENT] = { "cityName", "districtTitle", "improvement", "resource", "feature", "plotName" },
    [InterfaceModeTypes.SACRIFICE_SELECTION] = { "units", "cityName", "districtTitle", "improvement", "resource", "feature", "plotName" },
    [InterfaceModeTypes.AIRLIFT] = { "cityName", "districtTitle", "plotName" },
    [InterfaceModeTypes.PARADROP] = { "units", "cityName", "districtTitle", "improvement", "resource", "feature", "plotName" },
    [InterfaceModeTypes.PRIORITY_TARGET] = { "units", "cityName", "districtTitle", "improvement", "resource", "feature", "plotName" },
    [InterfaceModeTypes.MOVE_JUMP] = { "units", "cityName", "districtTitle", "improvement", "resource", "feature", "plotName" },
    [InterfaceModeTypes.KILL_WEAKER_UNIT] = { "units", "cityName", "districtTitle", "improvement", "resource", "feature", "plotName" },
    [InterfaceModeTypes.TRANSFORM_UNIT] = { "units", "cityName", "districtTitle", "improvement", "resource", "feature", "plotName" },
    [InterfaceModeTypes.RESTORE_UNIT_MOVES] = { "units", "cityName", "districtTitle", "improvement", "resource", "feature", "plotName" },
    [InterfaceModeTypes.NAVAL_GOLD_RAID] = { "units", "cityName", "districtTitle", "improvement", "resource", "feature", "plotName" },
}

local function ResolvePlotTargetLabel(mode, plotIndex)
    if not Map.IsPlot(plotIndex) then return nil end

    local plotInfo = ExposedMembers.CAIInfo
    if plotInfo == nil or plotInfo.RequestPlotInfo == nil then
        local plot = Map.GetPlotByIndex(plotIndex)
        if plot == nil then return nil end
        return Locale.Lookup("LOC_CAI_VALID_TARGET_PLOT", plot:GetX(), plot:GetY())
    end

    local requestedKeys
    if mode == InterfaceModeTypes.DISTRICT_PLACEMENT or mode == InterfaceModeTypes.BUILDING_PLACEMENT then
        requestedKeys = { "interfaceInfo" }
    elseif mode == InterfaceModeTypes.WMD_STRIKE or mode == InterfaceModeTypes.ICBM_STRIKE then
        requestedKeys = nil
    else
        requestedKeys = PLOT_INFO_KEYS_BY_MODE[mode]
    end

    local results = plotInfo:RequestPlotInfo(nil, requestedKeys, plotIndex)
    if results ~= nil and #results > 0 then return table.concat(results, ", ") end

    local plot = Map.GetPlotByIndex(plotIndex)
    if plot == nil then return nil end
    return Locale.Lookup("LOC_CAI_VALID_TARGET_PLOT", plot:GetX(), plot:GetY())
end

local function AddPlotTargetItems(out, mode, targetPlots)
    for plotIndex, targetValue in pairs(targetPlots) do
        local group = type(targetValue) == "string" and targetValue or "targetPlots"

        out[#out + 1] = {
            Id        = "validTarget:" .. tostring(plotIndex),
            Kind      = TARGET_KIND_PLOT,
            PlotIndex = plotIndex,
            LabelKey  = ResolvePlotTargetLabel(mode, plotIndex),
            GroupId   = group,
        }
    end
end

local function AddUnitTargetItems(out, units)
    local group = "units"

    for _, unit in ipairs(units) do
        local label = FormatOwnedUnitDisplayName(unit)
        if label == nil or label == "" then
            label = unit:GetName()
            if label ~= nil and label ~= "" then label = Locale.Lookup(label) end
        end
        if label == nil or label == "" then
            label = Locale.Lookup("LOC_CAI_VALID_TARGET_PLOT", unit:GetX(), unit:GetY())
        end

        out[#out + 1] = {
            Id        = "validTarget:unit:" .. tostring(unit:GetOwner()) .. ":" .. tostring(unit:GetID()),
            Kind      = TARGET_KIND_UNIT,
            PlotIndex = unit:GetPlotId(),
            UnitOwner = unit:GetOwner(),
            UnitID    = unit:GetID(),
            LabelKey  = label,
            GroupId   = group,
        }
    end
end

local function BuildTargetItems()
    local mode = UI.GetInterfaceMode()
    local out = {}

    local plotConfig = PLOT_TARGET_MODES[mode]
    if plotConfig ~= nil then
        AddPlotTargetItems(out, mode, GetPlotTargetsForConfig(plotConfig))
        return out
    end

    local commandType = UNIT_TARGET_MODES[mode]
    if commandType ~= nil then
        AddUnitTargetItems(out, GetCommandTargetUnits(commandType))
    end

    return out
end

local function BuildTargetCache()
    local mode = UI.GetInterfaceMode()
    local items = BuildTargetItems()
    local byPlotIndex = {}

    for _, item in ipairs(items) do
        if item.PlotIndex ~= nil and byPlotIndex[item.PlotIndex] == nil then
            byPlotIndex[item.PlotIndex] = item
        end
    end

    return {
        Mode = mode,
        Signature = BuildTargetCacheSignature(mode),
        Items = items,
        ByPlotIndex = byPlotIndex,
    }
end

-- ===========================================================================
--  API
-- ===========================================================================
function CAIInterfaceTargets.ClearCache()
    m_targetCache = nil
    m_actionPlotCache = nil
end

function CAIInterfaceTargets.IsSupportedMode(mode)
    mode = mode or UI.GetInterfaceMode()
    return PLOT_TARGET_MODES[mode] ~= nil or UNIT_TARGET_MODES[mode] ~= nil
end

function CAIInterfaceTargets.GetActiveTargetItems()
    local mode = UI.GetInterfaceMode()
    local signature = BuildTargetCacheSignature(mode)
    if m_targetCache == nil or m_targetCache.Mode ~= mode or m_targetCache.Signature ~= signature then
        m_targetCache = BuildTargetCache()
    end

    return m_targetCache.Items
end

function CAIInterfaceTargets.GetTargetAtPlot(plot)
    if plot == nil then return nil end

    local mode = UI.GetInterfaceMode()
    local signature = BuildTargetCacheSignature(mode)
    if m_targetCache == nil or m_targetCache.Mode ~= mode or m_targetCache.Signature ~= signature then
        m_targetCache = BuildTargetCache()
    end

    return m_targetCache.ByPlotIndex[plot:GetIndex()]
end
