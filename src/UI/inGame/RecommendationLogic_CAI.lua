CAIRecommendationLogic = CAIRecommendationLogic or {}

local info = ExposedMembers.CAIInfo or {}
ExposedMembers.CAIInfo = info

local m_cachedImprovementRecommendations = {}
local m_cachedSettlementRecommendations = {}

local function CacheRecommendationsForUnit(pSelectedUnit)
    m_cachedImprovementRecommendations = {}
    m_cachedSettlementRecommendations = {}

    if pSelectedUnit == nil then
        return
    end

    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == -1 or localPlayerID == 1000 then
        return
    end

    if pSelectedUnit:GetBuildCharges() > 0 then
        local pPlot = Map.GetPlotIndex(pSelectedUnit:GetX(), pSelectedUnit:GetY())
        local pCity = Cities.GetPlotPurchaseCity(pPlot)
        if pCity and pCity:GetOwner() == localPlayerID then
            local pCityAI = pCity:GetCityAI()
            if pCityAI then
                local recommendList = pCityAI:GetImprovementRecommendationsForBuilder(pSelectedUnit:GetComponentID())
                for _, value in pairs(recommendList) do
                    local pImprovementInfo = GameInfo.Improvements[value.ImprovementHash]
                    if pImprovementInfo then
                        m_cachedImprovementRecommendations[value.ImprovementLocation] = {
                            Label = Locale.Lookup("LOC_TOOLTIP_IMPROVEMENT_RECOMMENDATION", pImprovementInfo.Name),
                            GroupId = "improvement:" .. pImprovementInfo.ImprovementType,
                            GroupLabel = pImprovementInfo.Name,
                        }
                    end
                end
            end
        end
    elseif GameInfo.Units[pSelectedUnit:GetUnitType()].FoundCity then
        local pLocalPlayer = Players[localPlayerID]
        if pLocalPlayer then
            local pGrandAI = pLocalPlayer:GetGrandStrategicAI()
            if pGrandAI then
                local pSettlementRecommendations = pGrandAI:GetSettlementRecommendations(5)
                for _, kRecommendation in pairs(pSettlementRecommendations) do
                    local reasons = {}
                    local numReasons = kRecommendation.NumReasons
                    if kRecommendation.SettlingTooltip then
                        table.insert(reasons, kRecommendation.SettlingTooltip)
                    elseif numReasons > 0 then
                        for i = 0, numReasons - 1 do
                            local details = kRecommendation["SettleExplanation" .. tostring(i)]
                            if details then
                                table.insert(reasons, Locale.Lookup(details))
                            end
                        end
                    end
                    local text = Locale.Lookup("LOC_TOOLTIP_SETTLEMENT_RECOMMENDATION")
                    if #reasons > 0 then
                        text = text .. ": " .. table.concat(reasons, ", ")
                    end
                    m_cachedSettlementRecommendations[kRecommendation.SettlingLocation] = {
                        Label = text,
                    }
                end
            end
        end
    end
end

local function OnUnitSelectionChanged(player, unitId, locationX, locationY, locationZ, isSelected, isEditable)
    if isSelected then
        CacheRecommendationsForUnit(UI.GetHeadSelectedUnit())
    else
        m_cachedImprovementRecommendations = {}
        m_cachedSettlementRecommendations = {}
    end
end

function CAIRecommendationLogic.Initialize()
    Events.UnitSelectionChanged.Add(OnUnitSelectionChanged)
end

function CAIRecommendationLogic.Shutdown()
    Events.UnitSelectionChanged.Remove(OnUnitSelectionChanged)
    m_cachedImprovementRecommendations = {}
    m_cachedSettlementRecommendations = {}
end

function CAIRecommendationLogic.GetImprovementRecommendations()
    return m_cachedImprovementRecommendations
end

function CAIRecommendationLogic.GetSettlementRecommendations()
    return m_cachedSettlementRecommendations
end

function CAIRecommendationLogic.GetRecommendationForPlot(plotIndex)
    local imp = m_cachedImprovementRecommendations[plotIndex]
    if imp then
        return imp.Label
    end

    local settle = m_cachedSettlementRecommendations[plotIndex]
    if settle then
        return settle.Label
    end

    return nil
end

function CAIRecommendationLogic.HasRecommendations()
    return next(m_cachedImprovementRecommendations) ~= nil
        or next(m_cachedSettlementRecommendations) ~= nil
end

info.GetRecommendationForPlot = CAIRecommendationLogic.GetRecommendationForPlot
info.HasRecommendations = CAIRecommendationLogic.HasRecommendations
info.GetImprovementRecommendations = CAIRecommendationLogic.GetImprovementRecommendations
info.GetSettlementRecommendations = CAIRecommendationLogic.GetSettlementRecommendations
