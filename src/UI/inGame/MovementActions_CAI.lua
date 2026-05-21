MovementActions_CAI = MovementActions_CAI or {}

local m_readyForCombat = {
    unitOwner = nil,
    unitId = nil,
    targetPlotId = nil,
}

local m_pendingMovementResult = nil
local PENDING_MOVEMENT_WATCH_DELAY_FRAMES = 2

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

function MovementActions_CAI:BuildMovementResultSpeech(unit, reachedTarget, turnsToArrival)
    if unit == nil then
        return nil
    end

    if reachedTarget ~= true then
        if turnsToArrival ~= nil and turnsToArrival > 0 then
            return Locale.Lookup("LOC_CAI_MOVEMENT_RESULT_STOPPED_SHORT_TURNS", turnsToArrival)
        end

        return Locale.Lookup("LOC_CAI_MOVEMENT_RESULT_STOPPED_SHORT")
    end

    if turnsToArrival ~= nil and turnsToArrival > 0 then
        return Locale.Lookup("LOC_CAI_MOVEMENT_RESULT_STOPPED_SHORT_TURNS", turnsToArrival)
    end

    local movesLeft = unit:GetMovesRemaining()
    return Locale.Lookup("LOC_CAI_MOVEMENT_RESULT_MOVED_TO", movesLeft)
end

function MovementActions_CAI:QueuePendingMovementResult(unit, targetPlotId)
    local owner, unitId = GetUnitIdentity(unit)
    if owner == nil or unitId == nil then
        m_pendingMovementResult = nil
        return false
    end

    if targetPlotId == nil or targetPlotId == false or not Map.IsPlot(targetPlotId) then
        m_pendingMovementResult = nil
        return false
    end

    m_pendingMovementResult = {
        unitOwner = owner,
        unitId = unitId,
        startPlotId = unit:GetPlotId(),
        targetPlotId = targetPlotId,
        watchDelayFrames = PENDING_MOVEMENT_WATCH_DELAY_FRAMES,
    }
    return true
end

function MovementActions_CAI:ClearPendingMovementResult()
    m_pendingMovementResult = nil
end

function MovementActions_CAI:GetMatchingPendingMovementResult(playerID, unitID)
    local pending = m_pendingMovementResult
    if pending == nil then
        return nil
    end

    if pending.unitOwner ~= playerID or pending.unitId ~= unitID then
        return nil
    end

    return pending
end

function MovementActions_CAI:ResolvePendingMovementResult(playerID, unitID, currentPlotId)
    if playerID ~= Game.GetLocalPlayer() then
        return false
    end

    local pending = self:GetMatchingPendingMovementResult(playerID, unitID)
    if pending == nil then
        return false
    end

    local unit = UnitManager.GetUnit(playerID, unitID)
    if unit == nil then
        m_pendingMovementResult = nil
        return false
    end

    local targetPlotId = pending.targetPlotId
    local reachedTarget = currentPlotId ~= nil and currentPlotId == targetPlotId
    local turnsToArrival = nil
    local queuedToTarget = false
    if not reachedTarget and targetPlotId ~= nil and targetPlotId ~= false and Map.IsPlot(targetPlotId) then
        local queuedDestination = UnitManager.GetQueuedDestination(unit)
        if queuedDestination ~= nil and queuedDestination ~= false and queuedDestination == targetPlotId then
            queuedToTarget = true
            turnsToArrival = GetArrivalEstimate(unit, targetPlotId)
        end
    end

    if not reachedTarget and not queuedToTarget then
        return false
    end

    m_pendingMovementResult = nil

    local text = self:BuildMovementResultSpeech(unit, reachedTarget, turnsToArrival)
    if text ~= nil and text ~= "" then
        Speak(text)
    end

    return true
end

function MovementActions_CAI:OnUnitMoveComplete(playerID, unitID, x, y)
    if playerID ~= Game.GetLocalPlayer() then
        return
    end

    local unit = UnitManager.GetUnit(playerID, unitID)
    local currentPlot = Map.GetPlot(x, y) or (unit ~= nil and Map.GetPlot(unit:GetX(), unit:GetY()) or nil)
    local currentPlotId = currentPlot ~= nil and currentPlot:GetIndex() or nil
    self:ResolvePendingMovementResult(playerID, unitID, currentPlotId)
end

function MovementActions_CAI:UpdatePendingMovementResult()
    local pending = m_pendingMovementResult
    if pending == nil then
        return false
    end

    if pending.unitOwner ~= Game.GetLocalPlayer() then
        m_pendingMovementResult = nil
        return false
    end

    local unit = UnitManager.GetUnit(pending.unitOwner, pending.unitId)
    if unit == nil then
        m_pendingMovementResult = nil
        return false
    end

    if pending.watchDelayFrames ~= nil and pending.watchDelayFrames > 0 then
        pending.watchDelayFrames = pending.watchDelayFrames - 1
        return false
    end

    return self:ResolvePendingMovementResult(pending.unitOwner, pending.unitId, unit:GetPlotId())
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
        self:ClearPendingMovementResult()
        self:ClearReadyForCombat()
        SpeakText(Locale.Lookup("LOC_CAI_MOVEMENT_INVALID_PLOT"), true)
        return false
    end

    if OnMouseMoveToEnd == nil then
        self:ClearPendingMovementResult()
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

    self:QueuePendingMovementResult(unit, targetPlotId)

    local committed = OnMouseMoveToEnd()
    if not committed then
        self:ClearPendingMovementResult()
    end

    return committed
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

Events.UnitMoveComplete.Add(function(playerID, unitID, x, y)
    MovementActions_CAI:OnUnitMoveComplete(playerID, unitID, x, y)
end)
