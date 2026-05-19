include("caiUtils")
include("interfaceInfoHelpers_CAI")

local function IsPlotObject(plot)
    return plot ~= nil and plot ~= false and plot.GetX ~= nil and plot.GetY ~= nil
end

local function GetArrivalEstimate(unit, targetPlotId)
    if unit == nil or targetPlotId == nil or targetPlotId == false or not Map.IsPlot(targetPlotId) then
        return nil
    end

    if unit:GetPlotId() == targetPlotId then
        return 0
    end

    local pathInfo = UnitManager.GetMoveToPathEx(unit, targetPlotId)
    local turns = pathInfo ~= nil and pathInfo.turns or nil
    return turns ~= nil and #turns > 0 and turns[#turns] or nil
end

local function OnUnitMoveComplete(playerID, unitID, x, y)
    if playerID ~= Game.GetLocalPlayer() then
        return
    end

    local unit = UnitManager.GetUnit(playerID, unitID)
    if unit == nil then
        return
    end

    local targetPlotId = UnitManager.GetQueuedDestination(unit)
    local targetPlot = nil
    if targetPlotId ~= nil and targetPlotId ~= false and Map.IsPlot(targetPlotId) then
        targetPlot = Map.GetPlotByIndex(targetPlotId)
    end

    if not IsPlotObject(targetPlot) then
        targetPlot = Map.GetPlot(x, y)
        if not IsPlotObject(targetPlot) then
            targetPlot = Map.GetPlot(unit:GetX(), unit:GetY())
        end
        targetPlotId = IsPlotObject(targetPlot) and targetPlot:GetIndex() or nil
    end

    if not IsPlotObject(targetPlot) then
        return
    end

    local text = BuildMovementResultSpeech(unit, targetPlot:GetX(), targetPlot:GetY(),
        GetArrivalEstimate(unit, targetPlotId))
    if text ~= nil and text ~= "" then
        Speak(text)
    end
end

--# Add event listeners: includes overrides for tutorial lua events
Events.UnitMoveComplete.Add(OnUnitMoveComplete)
LuaEvents.Tutorial_AddUnitMoveRestriction.Add(OnTutorial_AddUnitMoveRestriction)
LuaEvents.Tutorial_RemoveUnitMoveRestrictions.Add(OnTutorial_RemoveUnitMoveRestrictions)
LuaEvents.Tutorial_ConstrainMovement.Add(OnTutorial_ConstrainMovement)
LuaEvents.Tutorial_AddUnitHexRestriction.Add(OnTutorial_AddUnitHexRestriction)
LuaEvents.Tutorial_RemoveUnitHexRestriction.Add(OnTutorial_RemoveUnitHexRestriction)
LuaEvents.Tutorial_ClearAllHexMoveRestrictions.Add(OnTutorial_ClearAllUnitHexRestrictions)
