include("caiUtils")
include("PlayerStateManager_CAI")
include("MessageBuffer_CAI")
include("inGameHelpers_CAI")
include("hexCoordUtils_CAI")

UnitMoveLog_CAI = UnitMoveLog_CAI or {}

local Log = UnitMoveLog_CAI
local m_initialized = false

local BUCKET_SETTINGS = {
    own = "AnnounceUnitMovesOwn",
    teammate = "AnnounceUnitMovesTeammate",
    hostile = "AnnounceUnitMovesHostile",
    neutral = "AnnounceUnitMovesNeutral",
    cityState = "AnnounceUnitMovesCityState",
    barbarian = "AnnounceUnitMovesBarbarian",
}

local m_playerState = PlayerStateManager.Init(function()
    return {
        positions = {},
        visibility = {},
        operationOrigins = {},
        pendingMoves = {},
        completedMoves = {},
        pendingTeleports = {},
        playerActions = {},
        pendingSpeech = {},
        turnStartReady = false,
    }
end)

local function UnitKey(playerID, unitID)
    return tostring(playerID) .. ":" .. tostring(unitID)
end

local function GetObserverID()
    local observerID = Game.GetLocalObserver()
    if observerID == nil or observerID == PlayerTypes.OBSERVER then
        observerID = Game.GetLocalPlayer()
    end

    if observerID == nil or observerID < 0 then
        return nil
    end

    return observerID
end

local function GetUnit(playerID, unitID)
    if playerID == nil or unitID == nil then
        return nil
    end

    return UnitManager.GetUnit(playerID, unitID)
end

local function GetUnitLabel(unit)
    if unit == nil then
        return nil
    end

    return FormatOwnedUnitDisplayName(unit)
end

local function IsTradeUnit(unit)
    if unit == nil then
        return false
    end

    local unitInfo = GameInfo.Units[unit:GetUnitType()]
    return unitInfo ~= nil and unitInfo.MakeTradeRoute == true
end

local function IsPlotVisible(observerID, x, y)
    local plot = Map.GetPlot(x, y)
    if plot == nil then
        return false
    end

    local visibility = PlayersVisibility[observerID]
    return visibility ~= nil and visibility:IsVisible(plot:GetIndex())
end

local function ClassifyOwner(observerID, ownerID)
    if ownerID == observerID then
        return "own"
    end

    local owner = Players[ownerID]
    if owner == nil or not owner:IsAlive() then
        return nil
    end

    local observer = Players[observerID]
    if observer ~= nil and owner:GetTeam() == observer:GetTeam() then
        return "teammate"
    end

    if owner:IsBarbarian() then
        return "barbarian"
    end

    if owner:IsMinor() then
        return "cityState"
    end

    local diplomacy = observer ~= nil and observer:GetDiplomacy() or nil
    if diplomacy ~= nil and diplomacy:IsAtWarWith(ownerID) then
        return "hostile"
    end

    return "neutral"
end

local function GetUnitCategory(unit)
    if unit ~= nil and (unit:GetCombat() > 0 or unit:GetRangedCombat() > 0) then
        return "military"
    end

    return "civilian"
end

local function GetAnnouncementMode(settingID)
    local mode = CAISettings.GetString(settingID)
    if mode == "military" or mode == "civilian" or mode == "both" or mode == "none" then
        return mode
    end

    return CAISettings.GetDefault(settingID)
end

local function ShouldAnnounce(bucket, unitCategory)
    local settingID = BUCKET_SETTINGS[bucket]
    if settingID == nil or not CAISettings.GetBool("SpeakMessageBufferMovement") then
        return false
    end

    local mode = GetAnnouncementMode(settingID)
    if mode == "both" then
        return true
    elseif type(unitCategory) == "table" then
        return unitCategory[mode] == true
    end

    return mode == unitCategory
end

local function AppendEntry(observerID, state, text, bucket, unitCategory, x, y, suppressSpeech)
    if text == nil or text == "" or bucket == nil then
        return
    end

    local buffer = MessageBuffer.GetForPlayer(observerID)
    if buffer == nil then
        LogWarn("Unit move log could not get the message buffer for observer " .. tostring(observerID))
        return
    end

    buffer:Append(text, "movement", { x = x, y = y })

    if suppressSpeech then
        return
    elseif GameConfiguration.IsHotseat() then
        state.pendingSpeech[#state.pendingSpeech + 1] = {
            text = text,
            bucket = bucket,
            unitCategory = unitCategory,
        }
    elseif ShouldAnnounce(bucket, unitCategory) then
        Speak(text)
    end
end

local function FlushHotseatSpeech(playerID)
    local state = m_playerState:Get(playerID)
    if state == nil or not state.turnStartReady then
        return
    end

    state.turnStartReady = false
    local pending = state.pendingSpeech
    state.pendingSpeech = {}

    local lines = {}
    for _, entry in ipairs(pending) do
        if ShouldAnnounce(entry.bucket, entry.unitCategory) then
            lines[#lines + 1] = entry.text
        end
    end

    SpeakLines(lines, true)
end

local function BuildPathText(pending)
    local segments = {}
    for _, directions in ipairs(pending.segments) do
        local text = CAIHexCoordUtils.stepListString(directions)
        if text ~= "" then
            segments[#segments + 1] = text
        end
    end

    return CAIHexCoordUtils.joinStepSegments(segments)
end

local function BuildMovementText(pending, label)
    label = label or pending.label
    local pathText = BuildPathText(pending)
    if pending.isRelocation or pending.hasVisibilityGap or pathText == "" then
        local displacement = CAIHexCoordUtils.directionString(
            pending.startX, pending.startY, pending.lastKnownX, pending.lastKnownY)
        if displacement ~= "" then
            return Locale.Lookup("LOC_CAI_UNIT_MOVE_LOG_PATH", label, displacement)
        elseif pending.startX ~= nil and pending.startY ~= nil
            and pending.startX == pending.lastKnownX and pending.startY == pending.lastKnownY then
            return nil
        elseif pending.isRelocation then
            return Locale.Lookup("LOC_CAI_UNIT_MOVE_LOG_RELOCATED", label)
        end

        return Locale.Lookup("LOC_CAI_UNIT_MOVE_LOG_GENERIC", label)
    end

    return Locale.Lookup("LOC_CAI_UNIT_MOVE_LOG_PATH", label, pathText)
end

local function FormatUnitList(labels)
    if #labels <= 1 then
        return table.concat(labels)
    elseif #labels == 2 then
        return labels[1] .. " " .. Locale.Lookup("LOC_CAI_AND") .. " " .. labels[2]
    end

    return table.concat(labels, ", ", 1, #labels - 1)
        .. ", " .. Locale.Lookup("LOC_CAI_AND") .. " " .. labels[#labels]
end

local function GetMovementGroupKey(pending, completionIndex)
    if pending.formationID == nil then
        return "unit:" .. UnitKey(pending.ownerID, pending.unitID) .. ":" .. tostring(completionIndex)
    end

    return table.concat({
        "formation",
        tostring(pending.ownerID),
        tostring(pending.formationID),
        tostring(pending.startX),
        tostring(pending.startY),
        tostring(pending.lastKnownX),
        tostring(pending.lastKnownY),
        tostring(pending.isRelocation),
        tostring(pending.hasVisibilityGap),
        BuildPathText(pending),
    }, ":")
end

local function FlushCompletedMoves(observerID, state)
    local completed = state.completedMoves
    state.completedMoves = {}

    local groups = {}
    local orderedGroups = {}
    for completionIndex, pending in ipairs(completed) do
        local groupKey = GetMovementGroupKey(pending, completionIndex)
        local group = groups[groupKey]
        if group == nil then
            group = {
                pending = pending,
                labels = {},
                unitCategories = {},
                suppressSpeech = false,
            }
            groups[groupKey] = group
            orderedGroups[#orderedGroups + 1] = group
        end

        group.labels[#group.labels + 1] = pending.label
        group.unitCategories[pending.unitCategory] = true
        group.suppressSpeech = group.suppressSpeech or pending.isPlayerAction
    end

    for _, group in ipairs(orderedGroups) do
        local pending = group.pending
        local label = FormatUnitList(group.labels)
        AppendEntry(observerID, state, BuildMovementText(pending, label), pending.bucket,
            group.unitCategories, pending.lastKnownX, pending.lastKnownY, group.suppressSpeech)
    end
end

local function AppendDirection(pending, direction)
    local segment = pending.currentSegment
    if segment == nil then
        segment = {}
        pending.segments[#pending.segments + 1] = segment
        pending.currentSegment = segment
    end

    segment[#segment + 1] = direction
end

local function IsInteractiveCAIMove(playerID, unitID)
    return MovementActions_CAI ~= nil
        and MovementActions_CAI.GetMatchingPendingMovementResult ~= nil
        and MovementActions_CAI:GetMatchingPendingMovementResult(playerID, unitID) ~= nil
end

local function IsSelectedOwnedUnit(observerID, playerID, unitID)
    if playerID ~= observerID then
        return false
    end

    local player = Players[playerID]
    if player == nil or not player:IsTurnActive() then
        return false
    end

    local selected = UI.GetHeadSelectedUnit()
    return selected ~= nil
        and selected:GetOwner() == playerID
        and selected:GetID() == unitID
end

local function IsDirectPathMovementOperation(operationID)
    return operationID == UnitOperationTypes.MOVE_TO
        or operationID == UnitOperationTypes.SWAP_UNITS
end

local function MarkPlayerAction(observerID, playerID, unitID)
    local state = m_playerState:Get(observerID)
    state.playerActions[UnitKey(playerID, unitID)] = true

    local unit = GetUnit(playerID, unitID)
    for _, member in ipairs(GetFormationUnitsOnPlot(unit)) do
        state.playerActions[UnitKey(member:GetOwner(), member:GetID())] = true
    end
end

local function IsUnitVisibleToObserver(observerID, unit)
    if unit:GetOwner() == observerID then
        return true
    end

    local visibility = PlayersVisibility[observerID]
    return visibility ~= nil and visibility:IsUnitVisible(unit)
end

local function CaptureOperationOrigin(observerID, state, unit)
    if unit == nil or not IsUnitVisibleToObserver(observerID, unit) then
        return
    end

    local key = UnitKey(unit:GetOwner(), unit:GetID())
    local x, y = unit:GetX(), unit:GetY()
    state.operationOrigins[key] = { x = x, y = y }
    state.positions[key] = { x = x, y = y }
    state.visibility[key] = true
end

local function OnUnitOperationStarted(playerID, unitID, operationID)
    local observerID = GetObserverID()
    if observerID == nil then
        return
    end

    local state = m_playerState:Get(observerID)
    local unit = GetUnit(playerID, unitID)
    CaptureOperationOrigin(observerID, state, unit)

    for _, member in ipairs(GetFormationUnitsOnPlot(unit)) do
        CaptureOperationOrigin(observerID, state, member)
    end

    if IsDirectPathMovementOperation(operationID)
        and IsSelectedOwnedUnit(observerID, playerID, unitID) then
        MarkPlayerAction(observerID, playerID, unitID)
    end
end

local function OnUnitOperationStopped(playerID, unitID)
    local observerID = GetObserverID()
    if observerID == nil then
        return
    end

    local state = m_playerState:Get(observerID)
    state.playerActions[UnitKey(playerID, unitID)] = nil
    local unit = GetUnit(playerID, unitID)
    for _, member in ipairs(GetFormationUnitsOnPlot(unit)) do
        state.playerActions[UnitKey(member:GetOwner(), member:GetID())] = nil
    end
end

local function OnUnitMoved(playerID, unitID, x, y, locallyVisible)
    local observerID = GetObserverID()
    if observerID == nil then
        return
    end

    local state = m_playerState:Get(observerID)
    local key = UnitKey(playerID, unitID)
    state.pendingTeleports[key] = nil
    local unit = GetUnit(playerID, unitID)
    if IsTradeUnit(unit) then
        state.pendingMoves[key] = nil
        state.operationOrigins[key] = nil
        if locallyVisible == true then
            state.positions[key] = { x = x, y = y }
            state.visibility[key] = true
        else
            state.visibility[key] = false
        end
        return
    end

    local pending = state.pendingMoves[key]
    if pending == nil then
        local position = state.positions[key]
        local previouslyVisible = state.visibility[key] == true
        local origin = state.operationOrigins[key]
        if origin == nil and previouslyVisible then
            origin = position
        end
        pending = {
            ownerID = playerID,
            unitID = unitID,
            label = GetUnitLabel(unit),
            formationID = unit ~= nil and unit:GetFormationUnitCount() > 1
                and unit:GetFormationID() or nil,
            bucket = ClassifyOwner(observerID, playerID),
            unitCategory = GetUnitCategory(unit),
            segments = {},
            currentSegment = nil,
            startX = origin ~= nil and origin.x or nil,
            startY = origin ~= nil and origin.y or nil,
            lastEventX = origin ~= nil and origin.x or nil,
            lastEventY = origin ~= nil and origin.y or nil,
            lastEventVisible = origin ~= nil,
            lastKnownX = origin ~= nil and origin.x or nil,
            lastKnownY = origin ~= nil and origin.y or nil,
            visibleEventCount = 0,
            hasVisibilityGap = false,
            isRelocation = false,
            isPlayerAction = false,
            hasExistingFeedback = false,
        }
        state.pendingMoves[key] = pending
        state.operationOrigins[key] = nil
    end

    local hasExistingFeedback = IsInteractiveCAIMove(playerID, unitID)
    pending.hasExistingFeedback = pending.hasExistingFeedback or hasExistingFeedback
    pending.isPlayerAction = pending.isPlayerAction
        or state.playerActions[key] == true
        or hasExistingFeedback
    state.playerActions[key] = nil

    if locallyVisible ~= true then
        pending.hasVisibilityGap = true
        pending.currentSegment = nil
        pending.lastEventX = nil
        pending.lastEventY = nil
        pending.lastEventVisible = false
        state.visibility[key] = false
        return
    end

    if pending.label == nil then
        pending.label = GetUnitLabel(unit)
        pending.unitCategory = GetUnitCategory(unit)
    end

    if pending.lastEventVisible then
        local direction = CAIHexCoordUtils.stepDirection(pending.lastEventX, pending.lastEventY, x, y)
        if direction ~= nil then
            AppendDirection(pending, direction)
        elseif pending.lastEventX ~= x or pending.lastEventY ~= y then
            pending.isRelocation = true
            pending.segments = {}
            pending.currentSegment = nil
        end
    elseif pending.visibleEventCount > 0 then
        pending.hasVisibilityGap = true
    end

    pending.visibleEventCount = pending.visibleEventCount + 1
    pending.lastEventX = x
    pending.lastEventY = y
    pending.lastEventVisible = true
    pending.lastKnownX = x
    pending.lastKnownY = y
    state.positions[key] = { x = x, y = y }
    state.visibility[key] = true
end

local function OnUnitMoveComplete(playerID, unitID)
    local observerID = GetObserverID()
    if observerID == nil then
        return
    end

    local state = m_playerState:Get(observerID)
    local key = UnitKey(playerID, unitID)
    local pending = state.pendingMoves[key]
    state.pendingMoves[key] = nil

    if pending == nil
        or pending.visibleEventCount == 0
        or pending.label == nil
        or pending.bucket == nil
        or pending.hasExistingFeedback then
        return
    end

    state.completedMoves[#state.completedMoves + 1] = pending
end

local function AppendTeleport(observerID, state, playerID, unitID, fromX, fromY, x, y, suppressSpeech)
    local key = UnitKey(playerID, unitID)
    local unit = GetUnit(playerID, unitID)
    local label = GetUnitLabel(unit)
    local bucket = ClassifyOwner(observerID, playerID)
    local unitCategory = GetUnitCategory(unit)
    if label == nil or bucket == nil then
        return
    end

    state.positions[key] = { x = x, y = y }
    state.visibility[key] = true
    state.pendingTeleports[key] = nil
    local displacement = CAIHexCoordUtils.directionString(fromX, fromY, x, y)
    local text
    if displacement ~= "" then
        text = Locale.Lookup("LOC_CAI_UNIT_MOVE_LOG_PATH", label, displacement)
    elseif fromX ~= nil and fromY ~= nil and fromX == x and fromY == y then
        return
    else
        text = Locale.Lookup("LOC_CAI_UNIT_MOVE_LOG_RELOCATED", label)
    end
    AppendEntry(observerID, state, text, bucket, unitCategory, x, y, suppressSpeech)
end

local function OnUnitTeleported(playerID, unitID, x, y)
    local observerID = GetObserverID()
    if observerID == nil then
        return
    end

    local state = m_playerState:Get(observerID)
    local key = UnitKey(playerID, unitID)
    local origin = state.operationOrigins[key]
    if origin == nil and state.visibility[key] == true then
        origin = state.positions[key]
    end
    state.pendingTeleports[key] = {
        playerID = playerID,
        unitID = unitID,
        fromX = origin ~= nil and origin.x or nil,
        fromY = origin ~= nil and origin.y or nil,
        x = x,
        y = y,
    }
    state.operationOrigins[key] = nil
    state.playerActions[key] = nil
end

local function OnUnitVisibilityChanged(playerID, unitID, visibility)
    local observerID = GetObserverID()
    if observerID == nil then
        return
    end

    local state = m_playerState:Get(observerID)
    local key = UnitKey(playerID, unitID)
    local isVisible = visibility == RevealedState.VISIBLE
    state.visibility[key] = isVisible

    if not isVisible then
        return
    end

    local unit = GetUnit(playerID, unitID)
    if unit == nil then
        return
    end

    local x, y = unit:GetX(), unit:GetY()
    state.positions[key] = { x = x, y = y }
end

local function OnUnitAddedToMap(playerID, unitID, x, y)
    local observerID = GetObserverID()
    if observerID == nil or playerID ~= observerID then
        return
    end

    local state = m_playerState:Get(observerID)
    local key = UnitKey(playerID, unitID)
    state.positions[key] = { x = x, y = y }
    state.visibility[key] = true
end

local function OnUnitRemovedFromMap(playerID, unitID)
    local observerID = GetObserverID()
    if observerID == nil then
        return
    end

    local state = m_playerState:Get(observerID)
    local key = UnitKey(playerID, unitID)
    state.positions[key] = nil
    state.visibility[key] = nil
    state.operationOrigins[key] = nil
    state.pendingMoves[key] = nil
    state.pendingTeleports[key] = nil
    state.playerActions[key] = nil
end

local function SeedVisibleUnitPositions(observerID)
    local state = m_playerState:Get(observerID)
    local players = {}
    local seenPlayers = {}

    local function AddPlayer(player)
        local playerID = player ~= nil and player:GetID() or nil
        if playerID ~= nil and not seenPlayers[playerID] then
            seenPlayers[playerID] = true
            players[#players + 1] = player
        end
    end

    for _, player in ipairs(PlayerManager.GetAlive() or {}) do
        AddPlayer(player)
    end

    for _, player in ipairs(Players) do
        if player ~= nil and player:IsBarbarian() then
            AddPlayer(player)
        end
    end

    for _, player in ipairs(players) do
        local units = player:GetUnits()
        if units ~= nil then
            for _, unit in units:Members() do
                local key = UnitKey(unit:GetOwner(), unit:GetID())
                if IsUnitVisibleToObserver(observerID, unit) then
                    state.positions[key] = { x = unit:GetX(), y = unit:GetY() }
                    state.visibility[key] = true
                else
                    state.visibility[key] = false
                end
            end
        end
    end
end

local function OnLocalPlayerTurnBegin()
    local playerID = Game.GetLocalPlayer()
    if playerID == nil or playerID < 0 then
        return
    end

    SeedVisibleUnitPositions(playerID)
    if GameConfiguration.IsHotseat() then
        m_playerState:Get(playerID).turnStartReady = true
    end
end

local function OnPlayerChangeClose(playerID)
    if GameConfiguration.IsHotseat() and playerID ~= nil and playerID >= 0 then
        FlushHotseatSpeech(playerID)
    end
end

function Log.Initialize()
    if m_initialized then
        return
    end

    m_initialized = true
    local observerID = GetObserverID()
    if observerID ~= nil then
        SeedVisibleUnitPositions(observerID)
    end

    Events.UnitMoved.Add(OnUnitMoved)
    Events.UnitMoveComplete.Add(OnUnitMoveComplete)
    Events.UnitTeleported.Add(OnUnitTeleported)
    Events.UnitOperationStarted.Add(OnUnitOperationStarted)
    Events.UnitOperationDeactivated.Add(OnUnitOperationStopped)
    Events.UnitOperationsCleared.Add(OnUnitOperationStopped)
    Events.UnitVisibilityChanged.Add(OnUnitVisibilityChanged)
    Events.UnitAddedToMap.Add(OnUnitAddedToMap)
    Events.UnitRemovedFromMap.Add(OnUnitRemovedFromMap)
    Events.LocalPlayerTurnBegin.Add(OnLocalPlayerTurnBegin)
    LuaEvents.PlayerChange_Close.Add(OnPlayerChangeClose)
end

function Log.Update()
    if not m_initialized then
        return
    end

    local observerID = GetObserverID()
    if observerID == nil then
        return
    end

    local state = m_playerState:Get(observerID)
    FlushCompletedMoves(observerID, state)

    local pending = state.pendingTeleports
    state.pendingTeleports = {}

    for key, teleport in pairs(pending) do
        local visible = teleport.playerID == observerID
            or (state.visibility[key] == true and IsPlotVisible(observerID, teleport.x, teleport.y))
        if visible then
            AppendTeleport(observerID, state, teleport.playerID, teleport.unitID,
                teleport.fromX, teleport.fromY, teleport.x, teleport.y, false)
        end
    end
end

function Log.Shutdown()
    if not m_initialized then
        return
    end

    m_initialized = false
    Events.UnitMoved.Remove(OnUnitMoved)
    Events.UnitMoveComplete.Remove(OnUnitMoveComplete)
    Events.UnitTeleported.Remove(OnUnitTeleported)
    Events.UnitOperationStarted.Remove(OnUnitOperationStarted)
    Events.UnitOperationDeactivated.Remove(OnUnitOperationStopped)
    Events.UnitOperationsCleared.Remove(OnUnitOperationStopped)
    Events.UnitVisibilityChanged.Remove(OnUnitVisibilityChanged)
    Events.UnitAddedToMap.Remove(OnUnitAddedToMap)
    Events.UnitRemovedFromMap.Remove(OnUnitRemovedFromMap)
    Events.LocalPlayerTurnBegin.Remove(OnLocalPlayerTurnBegin)
    LuaEvents.PlayerChange_Close.Remove(OnPlayerChangeClose)
end
