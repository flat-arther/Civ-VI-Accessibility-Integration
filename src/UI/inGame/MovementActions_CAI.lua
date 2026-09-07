include("caiUtils")

MovementActions_CAI = MovementActions_CAI or {}

local m_readyForCombat = {
    unitOwner = nil,
    unitId = nil,
    targetPlotId = nil,
}

local m_pendingMovementResult = nil
local PENDING_MOVEMENT_WATCH_DELAY_FRAMES = 2
-- Fallback ceiling (in active frames) for how long the "moved to" line waits for
-- GetMovesRemaining to change from the pre-move value before it gives up and reads it
-- live. The value normally changes far sooner; this only covers a zero-cost move where it
-- never changes.
local MOVEMENT_SETTLE_TIMEOUT_FRAMES = 120
-- Once GetMovesRemaining has changed, wait this many active frames before speaking, and
-- restart the wait whenever it changes again. Some moves commit movement in two steps --
-- disembark shows the new land form's max, then drops to zero because disembarking ends
-- the unit's turn -- so this lets the value settle before the last one is reported.
local MOVEMENT_SETTLE_HOLD_FRAMES = 8
-- When a move leaves the unit on its start plot, wait this many active frames before
-- concluding it truly stayed put -- a "movement queued" result (unit could not reach even
-- its first tile this turn). A real move announces immediately: UnitMoveComplete fires (or
-- the plot changes) within a frame or two, resolving it before this window elapses. This
-- window only needs to outlast that race, so it is kept short -- a genuinely stationary unit
-- is the only thing that ever consumes it, and a long delay there both feels wrong and lets
-- later speech cut off the announcement.
local MOVEMENT_QUEUE_SETTLE_FRAMES = 12

local function ParameterContainsValue(parameter, expectedValue)
    if parameter == nil then return false end
    for index = 0, parameter:GetCount() - 1 do
        if parameter:GetValueAt(index) == expectedValue then return true end
    end
    return false
end

local function IsMoveToDisabledByTutorial(unit)
    if unit == nil then return false end
    local gameParameters = UI.GetGameParameters()
    local restrictions = gameParameters ~= nil and gameParameters:Get("UnitActionRestrictions") or nil
    if restrictions == nil then return false end
    if ParameterContainsValue(restrictions:Get("_ALL"), "UNITOPERATION_MOVE_TO") then return true end

    local unitInfo = GameInfo.Units[unit:GetUnitType()]
    return unitInfo ~= nil
        and ParameterContainsValue(restrictions:Get(unitInfo.UnitType), "UNITOPERATION_MOVE_TO")
end

local function SpeakText(text, interrupt)
    if text == nil or text == "" then
        return false
    end

    Speak(text, interrupt)
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
    local arrivalTurn = turns ~= nil and #turns > 0 and tonumber(turns[#turns]) or nil
    return arrivalTurn ~= nil and math.max(0, arrivalTurn - 1) or nil
end

function MovementActions_CAI:BuildMovementResultSpeech(unit, reachedTarget, turnsToArrival, movesLeft, movedAny)
    if unit == nil then
        return nil
    end

    if reachedTarget ~= true then
        -- The unit never left its start plot but has a queued path: it could not move at
        -- all this turn (e.g. out of movement) and will travel over the coming turns.
        -- Distinguish this from having moved and stopped part way.
        if movedAny == false then
            if turnsToArrival ~= nil and turnsToArrival > 0 then
                return Locale.Lookup("LOC_CAI_MOVEMENT_RESULT_QUEUED_TURNS", turnsToArrival)
            end

            return Locale.Lookup("LOC_CAI_MOVEMENT_RESULT_QUEUED")
        end

        if turnsToArrival ~= nil and turnsToArrival > 0 then
            return Locale.Lookup("LOC_CAI_MOVEMENT_RESULT_STOPPED_SHORT_TURNS", turnsToArrival)
        end

        return Locale.Lookup("LOC_CAI_MOVEMENT_RESULT_STOPPED_SHORT")
    end

    if turnsToArrival ~= nil and turnsToArrival > 0 then
        return Locale.Lookup("LOC_CAI_MOVEMENT_RESULT_STOPPED_SHORT_TURNS", turnsToArrival)
    end

    if movesLeft == nil then
        movesLeft = unit:GetMovesRemaining()
    end
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
        startMovesRemaining = unit:GetMovesRemaining(),
        targetPlotId = targetPlotId,
        watchDelayFrames = PENDING_MOVEMENT_WATCH_DELAY_FRAMES,
        settleTimeoutFrames = MOVEMENT_SETTLE_TIMEOUT_FRAMES,
        queueSettleFrames = MOVEMENT_QUEUE_SETTLE_FRAMES,
        settleHoldFrames = nil,
        movesSettled = false,
        lastMovesSeen = nil,
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
            -- Cache the queued observation. This result may not resolve until the queue-settle
            -- window below elapses, and the live queued destination can clear before then (the
            -- unit is deselected/auto-cycled after issuing the order), which would otherwise
            -- lose the "movement queued" result entirely.
            pending.sawQueuedToTarget = true
            pending.cachedTurnsToArrival = turnsToArrival
        end
    end

    -- Fall back to the earlier queued observation if the live order has since cleared.
    if not reachedTarget and not queuedToTarget and pending.sawQueuedToTarget then
        queuedToTarget = true
        turnsToArrival = pending.cachedTurnsToArrival
    end

    if not reachedTarget and not queuedToTarget then
        return false
    end

    -- Did the unit actually leave its start plot this turn, or only queue a path? This is the
    -- plain comparison: a move that advances at least one tile is "stopped short"; a move that
    -- cannot reach even its first tile this turn (it costs more movement than the unit has and
    -- is not eligible for the free-first-tile rule) stays put and is "movement queued".
    local movedAny = currentPlotId ~= nil
        and pending.startPlotId ~= nil
        and currentPlotId ~= pending.startPlotId

    -- A not-reached result still sitting on the start plot is ambiguous at this instant: it
    -- may be a genuine queued order (no movement this turn) or a real move whose new position
    -- has not committed yet, because the frame poll can run before the engine updates the
    -- unit's plot. Wait out the queue-settle window before concluding it stayed put. A move
    -- that does leave the start plot changes currentPlotId (or arrives via UnitMoveComplete)
    -- and resolves immediately without waiting.
    if not reachedTarget and not movedAny then
        if pending.queueSettleFrames ~= nil and pending.queueSettleFrames > 0 then
            return false
        end
    end

    -- Only the "moved to, X movement left" line reports remaining movement. After a move
    -- that triggers a blocking animation or popup (goody hut, natural wonder, embark or
    -- disembark), the engine commits the movement-cost deduction only once the animation
    -- settles, so a synchronous read here can return the stale pre-move value. The frame
    -- poll (UpdatePendingMovementResult) watches GetMovesRemaining directly -- the same
    -- value the unit panel shows -- and marks the result settled once it changes, holding
    -- briefly so a multi-step commit lands on its final value. The value is always read
    -- live at emit; movement-points events are not used because disembark fires one for
    -- the land-form max without ever announcing the subsequent zeroing.
    local reportsMovesRemaining = reachedTarget and (turnsToArrival == nil or turnsToArrival <= 0)
    local movesLeft = nil
    if reportsMovesRemaining then
        local settled = pending.movesSettled
            and (pending.settleHoldFrames == nil or pending.settleHoldFrames <= 0)
        local timedOut = pending.settleTimeoutFrames ~= nil and pending.settleTimeoutFrames <= 0
        if not settled and not timedOut then
            return false
        end
        movesLeft = unit:GetMovesRemaining()
    end

    m_pendingMovementResult = nil
    local plot = Map.GetPlotByIndex(targetPlotId)
    local text = self:BuildMovementResultSpeech(unit, reachedTarget, turnsToArrival, movesLeft, movedAny)
    if text ~= nil and text ~= "" then
        LuaEvents.CAIAppendToMessageBuffer(text, "movement", { x = plot:GetX(), y = plot:GetY() })
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

    -- Count down the queue-settle window while the unit is still on its start plot. Once it
    -- reaches zero, a still-unmoved unit is treated as a genuine queued order; a unit that
    -- leaves the start plot before then resolves as a move instead.
    if pending.queueSettleFrames ~= nil and pending.queueSettleFrames > 0
        and unit:GetPlotId() == pending.startPlotId then
        pending.queueSettleFrames = pending.queueSettleFrames - 1
    end

    -- Watch GetMovesRemaining directly (the value the unit panel shows). It stays at the
    -- pre-move value while a blocking animation/popup defers the deduction, so wait for it
    -- to change, then hold briefly -- restarted whenever it changes again -- so a
    -- multi-step commit (e.g. disembark: land-form max, then zeroed as the turn ends)
    -- settles on its final value before we speak.
    local liveMoves = unit:GetMovesRemaining()
    if not pending.movesSettled then
        if pending.startMovesRemaining == nil or liveMoves ~= pending.startMovesRemaining then
            pending.movesSettled = true
            pending.lastMovesSeen = liveMoves
            pending.settleHoldFrames = MOVEMENT_SETTLE_HOLD_FRAMES
        elseif pending.settleTimeoutFrames ~= nil and pending.settleTimeoutFrames > 0 then
            pending.settleTimeoutFrames = pending.settleTimeoutFrames - 1
        end
    elseif liveMoves ~= pending.lastMovesSeen then
        pending.lastMovesSeen = liveMoves
        pending.settleHoldFrames = MOVEMENT_SETTLE_HOLD_FRAMES
    elseif pending.settleHoldFrames ~= nil and pending.settleHoldFrames > 0 then
        pending.settleHoldFrames = pending.settleHoldFrames - 1
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
        LogError("MovementActions_CAI could not access OnMouseMoveToEnd for move commit")
        return false
    end

    local currentPlotId = UI.GetCursorPlotID()
    if currentPlotId ~= targetPlotId then
        if LuaEvents == nil or LuaEvents.CAICursorMoveTo == nil then
            LogWarn("MovementActions_CAI could not move CAI cursor before move commit")
            return false
        end

        LuaEvents.CAICursorMoveTo(targetPlotId, "select")
    end

    self:QueuePendingMovementResult(unit, targetPlotId)

    local committed = OnMouseMoveToEnd()
    if not committed then
        self:ClearPendingMovementResult()
    end

    return committed
end

function MovementActions_CAI:TryActivateMoveTarget(unit, targetPlotId, useCursorCombatPreview, requireArrivalThisTurn)
    if IsMoveToDisabledByTutorial(unit) then
        self:ClearReadyForCombat()
        return false
    end

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

    if requireArrivalThisTurn == true and pathInfo.arrivalTurn > 1 then
        self:ClearReadyForCombat()
        SpeakText(Locale.Lookup("LOC_CAI_MOVEMENT_NOT_ENOUGH_MOVEMENT"), true)
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

    return self:TryActivateMoveTarget(unit, targetPlot:GetIndex(), false, true)
end

Events.UnitMoveComplete.Add(function(playerID, unitID, x, y)
    MovementActions_CAI:OnUnitMoveComplete(playerID, unitID, x, y)
end)
