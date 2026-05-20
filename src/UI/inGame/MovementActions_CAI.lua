MovementActions_CAI = MovementActions_CAI or {}

local m_readyForCombat = {
    unitOwner = nil,
    unitId = nil,
    targetPlotId = nil,
}

local function SpeakText(text, interrupt)
    if text == nil or text == "" then
        return false
    end

    Speak(ProcessIcons(text), interrupt)
    return true
end

local function SpeakLines(lines, interrupt)
    if lines == nil then
        return false
    end

    if type(lines) == "string" then
        return SpeakText(lines, interrupt)
    end

    if #lines > 0 then
        return SpeakText(table.concat(lines, ", "), interrupt)
    end

    return false
end

local function GetUnitIdentity(unit)
    if unit == nil then
        return nil, nil
    end

    return unit:GetOwner(), unit:GetID()
end

local function IsImmediateMoveCombat(pathInfo)
    return pathInfo ~= nil
        and pathInfo.kind ~= "attack"
        and pathInfo.combatAtEnd == true
        and pathInfo.isQueued ~= true
end

function MovementActions_CAI:ClearReadyForCombat()
    m_readyForCombat.unitOwner = nil
    m_readyForCombat.unitId = nil
    m_readyForCombat.targetPlotId = nil
end

function MovementActions_CAI:ArmReadyForCombat(unit, targetPlotId)
    local owner, unitId = GetUnitIdentity(unit)
    m_readyForCombat.unitOwner = owner
    m_readyForCombat.unitId = unitId
    m_readyForCombat.targetPlotId = targetPlotId
end

function MovementActions_CAI:IsReadyForCombat(unit, targetPlotId)
    local owner, unitId = GetUnitIdentity(unit)
    return owner ~= nil
        and unitId ~= nil
        and m_readyForCombat.unitOwner == owner
        and m_readyForCombat.unitId == unitId
        and m_readyForCombat.targetPlotId == targetPlotId
end

function MovementActions_CAI:CommitMoveTarget(unit, targetPlotId)
    if unit == nil or not Map.IsPlot(targetPlotId) then
        self:ClearReadyForCombat()
        SpeakText(Locale.Lookup("LOC_CAI_MOVEMENT_INVALID_PLOT"), true)
        return false
    end

    if OnMouseMoveToEnd == nil then
        print("MovementActions_CAI could not access OnMouseMoveToEnd for move commit")
        return false
    end

    local currentPlotId = UI.GetCursorPlotID()
    if currentPlotId ~= targetPlotId then
        if LuaEvents == nil or LuaEvents.CAICursorJump == nil then
            print("MovementActions_CAI could not jump CAI cursor before move commit")
            return false
        end

        LuaEvents.CAICursorJump(targetPlotId, true)
    end

    return OnMouseMoveToEnd()
end

function MovementActions_CAI:TryActivateMoveTarget(unit, targetPlotId, useCursorCombatPreview)
    if unit == nil then
        self:ClearReadyForCombat()
        SpeakText(Locale.Lookup("LOC_CAI_QUICK_MOVE_NO_UNIT"), true)
        return false
    end

    if useCursorCombatPreview == nil then
        useCursorCombatPreview = true
    end

    local wasArmedForSameTarget = self:IsReadyForCombat(unit, targetPlotId)
    if not wasArmedForSameTarget then
        self:ClearReadyForCombat()
    end

    if not Map.IsPlot(targetPlotId) then
        SpeakText(Locale.Lookup("LOC_CAI_MOVEMENT_INVALID_PLOT"), true)
        return false
    end

    local pathInfo = BuildMovementPathInfo(unit, targetPlotId, false, true)
    if pathInfo == nil then
        SpeakText(Locale.Lookup("LOC_CAI_MOVEMENT_INVALID_PLOT"), true)
        return false
    end

    if pathInfo.kind == "bad" then
        self:ClearReadyForCombat()
        if not SpeakLines(BuildMovementSpeech(pathInfo, false), true) then
            SpeakText(Locale.Lookup("LOC_CAI_MOVEMENT_CANNOT_MOVE"), true)
        end
        return false
    end

    if IsImmediateMoveCombat(pathInfo) then
        if wasArmedForSameTarget then
            self:ClearReadyForCombat()
            return self:CommitMoveTarget(unit, targetPlotId)
        end

        self:ArmReadyForCombat(unit, targetPlotId)
        if useCursorCombatPreview then
            LuaEvents.CAISpeakCombatPreview()
        else
            LuaEvents.CAISpeakCombatPreviewForPlot(targetPlotId)
        end
        SpeakText(Locale.Lookup("LOC_CAI_MOVEMENT_COMBAT_CONFIRM"), false)
        return true
    end

    self:ClearReadyForCombat()
    return self:CommitMoveTarget(unit, targetPlotId)
end

function MovementActions_CAI:TryQuickMoveDirection(direction)
    local interfaceMode = UI.GetInterfaceMode()
    if interfaceMode ~= InterfaceModeTypes.SELECTION and interfaceMode ~= InterfaceModeTypes.MOVE_TO then
        return false
    end

    local unit = UI.GetHeadSelectedUnit()
    if unit == nil then
        self:ClearReadyForCombat()
        SpeakText(Locale.Lookup("LOC_CAI_QUICK_MOVE_NO_UNIT"), true)
        return false
    end

    local unitPlot = Map.GetPlotByIndex(unit:GetPlotId())
    if unitPlot == nil then
        self:ClearReadyForCombat()
        SpeakText(Locale.Lookup("LOC_CAI_MOVEMENT_INVALID_PLOT"), true)
        return false
    end

    local targetPlot = Map.GetAdjacentPlot(unitPlot:GetX(), unitPlot:GetY(), direction)
    if targetPlot == nil then
        self:ClearReadyForCombat()
        SpeakText(Locale.Lookup("LOC_CAI_MOVEMENT_INVALID_PLOT"), true)
        return false
    end

    return self:TryActivateMoveTarget(unit, targetPlot:GetIndex(), false)
end
