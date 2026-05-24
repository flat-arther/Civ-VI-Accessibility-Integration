include("caiUtils")

CAICityManagementInterface = CAICityManagementInterface or {}

local CityManagement = CAICityManagementInterface
local LENS_CITIZEN_MANAGEMENT = UILens.CreateLensLayerHash("Citizen_Management")
local LENS_PURCHASE_PLOT = UILens.CreateLensLayerHash("Purchase_Plot")

local function IsCityManagementMode()
    return UI.GetInterfaceMode() == InterfaceModeTypes.CITY_MANAGEMENT and UI.GetHeadSelectedCity() ~= nil
end

function CityManagement.IsCitizenManagementActive()
    return IsCityManagementMode() and UILens.IsLayerOn(LENS_CITIZEN_MANAGEMENT)
end

function CityManagement.IsPurchaseActive()
    return IsCityManagementMode() and UILens.IsLayerOn(LENS_PURCHASE_PLOT)
end

function CityManagement.IsActive()
    return IsCityManagementMode() and (CityManagement.IsCitizenManagementActive() or CityManagement.IsPurchaseActive())
end

local function GetSelectedCity()
    if not IsCityManagementMode() then
        return nil
    end

    return UI.GetHeadSelectedCity()
end

function CityManagement.GetStateData()
    local city = GetSelectedCity()
    if city == nil then
        return nil
    end

    local out = {
        City = city,
        CitizenPlots = {},
        PurchasePlots = {},
        ActivePlots = {},
    }

    if CityManagement.IsCitizenManagementActive() then
        local manageParameters = {}
        manageParameters[CityCommandTypes.PARAM_MANAGE_CITIZEN] =
            UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_MANAGE_CITIZEN)

        local manageResults = CityManager.GetCommandTargets(city, CityCommandTypes.MANAGE, manageParameters)
        local citizenPlots = manageResults and manageResults[CityCommandResults.PLOTS] or nil
        local citizens = manageResults and manageResults[CityCommandResults.CITIZENS] or nil
        local maxCitizens = manageResults and manageResults[CityCommandResults.MAX_CITIZENS] or nil
        local lockedCitizens = manageResults and manageResults[CityCommandResults.LOCKED_CITIZENS] or nil

        if citizenPlots ~= nil then
            for i, plotId in pairs(citizenPlots) do
                local entry = {
                    PlotId = plotId,
                    Citizens = tonumber(citizens and citizens[i]) or 0,
                    MaxCitizens = tonumber(maxCitizens and maxCitizens[i]) or 0,
                    Locked = (tonumber(lockedCitizens and lockedCitizens[i]) or 0) > 0,
                }
                out.CitizenPlots[plotId] = entry
                out.ActivePlots[plotId] = true
            end
        end

        local swapParameters = {}
        swapParameters[CityCommandTypes.PARAM_SWAP_TILE_OWNER] =
            UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_SWAP_TILE_OWNER)

        local swapResults = CityManager.GetCommandTargets(city, CityCommandTypes.SWAP_TILE_OWNER, swapParameters)
        local swapPlots = swapResults and swapResults[CityCommandResults.PLOTS] or nil
        if swapPlots ~= nil then
            for _, plotId in pairs(swapPlots) do
                local entry = out.CitizenPlots[plotId] or { PlotId = plotId, Citizens = 0, MaxCitizens = 0, Locked = false }
                entry.CanSwap = true
                out.CitizenPlots[plotId] = entry
                out.ActivePlots[plotId] = true
            end
        end
    end

    if CityManagement.IsPurchaseActive() then
        local purchaseParameters = {}
        purchaseParameters[CityCommandTypes.PARAM_PLOT_PURCHASE] =
            UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_PLOT_PURCHASE)

        local purchaseResults = CityManager.GetCommandTargets(city, CityCommandTypes.PURCHASE, purchaseParameters)
        local purchasePlots = purchaseResults and purchaseResults[CityCommandResults.PLOTS] or nil
        local playerTreasury = Players[Game.GetLocalPlayer()] and Players[Game.GetLocalPlayer()]:GetTreasury() or nil
        local playerGold = playerTreasury and playerTreasury:GetGoldBalance() or 0
        local cityGold = city:GetGold()

        if purchasePlots ~= nil and cityGold ~= nil then
            for _, plotId in pairs(purchasePlots) do
                local cost = cityGold:GetPlotPurchaseCost(plotId)
                local missingGold = cost > playerGold and (cost - math.floor(playerGold)) or 0
                out.PurchasePlots[plotId] = {
                    PlotId = plotId,
                    Cost = cost,
                    Affordable = cost <= playerGold,
                    MissingGold = missingGold,
                }
                out.ActivePlots[plotId] = true
            end
        end
    end

    return out
end

function CityManagement.GetPlotState(plotOrPlotId, stateData)
    local plotId = plotOrPlotId
    if type(plotOrPlotId) == "table" then
        plotId = plotOrPlotId:GetIndex()
    end

    if plotId == nil then
        return nil
    end

    local resolvedStateData = stateData or CityManagement.GetStateData()
    if resolvedStateData == nil or resolvedStateData.ActivePlots[plotId] ~= true then
        return nil
    end

    return {
        PlotId = plotId,
        Citizen = resolvedStateData.CitizenPlots[plotId],
        Purchase = resolvedStateData.PurchasePlots[plotId],
    }
end

function CityManagement.BuildSpeechParts(plotOrPlotId, stateData)
    local state = CityManagement.GetPlotState(plotOrPlotId, stateData)
    if state == nil then
        return nil
    end

    return CityManagement.BuildSpeechPartsFromState(state)
end

function CityManagement.BuildSpeechPartsFromState(state)
    if state == nil then
        return nil
    end

    local parts = {}

    local citizen = state.Citizen
    if citizen ~= nil then
        if citizen.Locked then
            parts[#parts + 1] = Locale.Lookup("LOC_CAI_CITY_MANAGEMENT_LOCKED")
        end

        if citizen.MaxCitizens > 1 then
            parts[#parts + 1] = Locale.Lookup(
                "LOC_CAI_CITY_MANAGEMENT_SPECIALISTS_SHORT",
                citizen.Citizens,
                citizen.MaxCitizens
            )
        elseif citizen.Citizens > 0 then
            parts[#parts + 1] = ProcessIcons(Locale.Lookup(
                "LOC_TOOLTIP_PLOT_WORKED_TEXT",
                citizen.Citizens
            ))
        else
            parts[#parts + 1] = Locale.Lookup("LOC_CAI_CITY_MANAGEMENT_UNWORKED")
        end

        if citizen.CanSwap then
            parts[#parts + 1] = Locale.Lookup("LOC_CAI_CITY_MANAGEMENT_SWAPPABLE")
        end
    end

    local purchase = state.Purchase
    if purchase ~= nil then
        local purchaseText = ProcessIcons(
            Locale.Lookup("LOC_HUD_CITY_PURCHASE_NEW_PLOT") .. Locale.ToNumber(purchase.Cost)
        )
        parts[#parts + 1] = purchaseText

        if not purchase.Affordable then
            parts[#parts + 1] = ProcessIcons(Locale.Lookup(
                "LOC_PLOTINFO_YOU_NEED_MORE_GOLD_TO_PURCHASE",
                purchase.MissingGold
            ))
        end
    end

    return parts
end

function CityManagement.BuildSpeechText(plotOrPlotId, stateData)
    local parts = CityManagement.BuildSpeechParts(plotOrPlotId, stateData)
    if parts == nil or #parts == 0 then
        return nil
    end

    return table.concat(parts, ", ")
end

function CityManagement.BuildSpeechTextFromResults(plotId, results, stateData)
    if results ~= nil then
        local plots = results[CityCommandResults.PLOTS]
        if plots ~= nil then
            for i, resultPlotId in pairs(plots) do
                if resultPlotId == plotId then
                    local state = {
                        PlotId = plotId,
                    }

                    local citizens = results[CityCommandResults.CITIZENS]
                    local maxCitizens = results[CityCommandResults.MAX_CITIZENS]
                    local lockedCitizens = results[CityCommandResults.LOCKED_CITIZENS]

                    if citizens ~= nil or maxCitizens ~= nil or lockedCitizens ~= nil then
                        state.Citizen = {
                            PlotId = plotId,
                            Citizens = tonumber(citizens and citizens[i]) or 0,
                            MaxCitizens = tonumber(maxCitizens and maxCitizens[i]) or 0,
                            Locked = (tonumber(lockedCitizens and lockedCitizens[i]) or 0) > 0,
                        }
                    end

                    local parts = CityManagement.BuildSpeechPartsFromState(state)
                    if parts ~= nil and #parts > 0 then
                        return table.concat(parts, ", ")
                    end
                end
            end
        end
    end

    return CityManagement.BuildSpeechTextOrInvalid(plotId, stateData)
end

function CityManagement.BuildSpeechTextOrInvalid(plotOrPlotId, stateData)
    local text = CityManagement.BuildSpeechText(plotOrPlotId, stateData)
    if text ~= nil and text ~= "" then
        return text
    end

    return Locale.Lookup("LOC_CAI_PLOT_INTERFACE_INVALID_TARGET")
end

function CityManagement.GetScannerSubCategoryId(plotOrPlotId, stateData)
    local state = CityManagement.GetPlotState(plotOrPlotId, stateData)
    if state == nil then
        return nil
    end

    local citizen = state.Citizen
    if citizen ~= nil then
        if citizen.Locked then
            return "locked"
        end
        if citizen.MaxCitizens > 1 then
            return "specialists"
        end
        if citizen.Citizens > 0 then
            return "worked"
        end
        if citizen.CanSwap then
            return "swappable"
        end
        return "available"
    end

    local purchase = state.Purchase
    if purchase ~= nil then
        if purchase.Affordable then
            return "purchasable"
        end
        return "tooExpensive"
    end

    return nil
end

function CityManagement.ResolvePrimaryAction(plotOrPlotId, stateData)
    local state = CityManagement.GetPlotState(plotOrPlotId, stateData)
    if state == nil then
        return nil
    end

    if CityManagement.IsPurchaseActive() and state.Purchase ~= nil and state.Purchase.Affordable then
        return "purchase"
    end

    if CityManagement.IsCitizenManagementActive() and state.Citizen ~= nil then
        return "manage"
    end

    if state.Purchase ~= nil and state.Purchase.Affordable then
        return "purchase"
    end

    if state.Citizen ~= nil then
        return "manage"
    end

    return nil
end

function CityManagement.ResolveSecondaryAction(plotOrPlotId, stateData)
    local state = CityManagement.GetPlotState(plotOrPlotId, stateData)
    if state == nil then
        return nil
    end

    if state.Citizen ~= nil and state.Citizen.CanSwap then
        return "swap"
    end

    return nil
end
