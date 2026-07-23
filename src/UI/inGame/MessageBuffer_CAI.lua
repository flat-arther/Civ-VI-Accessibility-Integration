include("caiUtils")
include("hexCoordUtils_CAI")
include("PlayerStateManager_CAI")
---@class MessageBuffer
---@field _entries MessageBufferEntry[]
---@field _filter MessageCategory|"all"
---@field _position integer
---@field _nextEntryId integer
MessageBuffer = {}
MessageBuffer.__index = MessageBuffer

local VALID_CATEGORIES = {
    notification = true,
    reveal = true,
    combat = true,
    movement = true,
    chat = true,
    gossip = true
}

---@class MessageBufferEntry
---@field id integer
---@field turn integer
---@field text string
---@field category string
---@field location? table<string, number>|nil
--#region Core

---@return MessageBuffer
function MessageBuffer.Create()
    local self = setmetatable({}, MessageBuffer)

    self._entries = {}
    self._filter = "all"
    self._position = 0
    self._nextEntryId = 1

    return self
end

local function GetCapacity()
    local limit = CAISettings.GetNumber("MessageBufferLimit")
    if limit < 1 then
        LogWarn("MessageBuffer: invalid capacity setting " .. tostring(limit) .. "; clamping to 1")
        return 1
    end

    return math.floor(limit)
end

function MessageBuffer:Append(text, category, location)
    if text == nil or text == "" then
        return
    end

    if not VALID_CATEGORIES[category] then
        LogWarn("MessageBuffer: unknown category '" .. tostring(category) .. "'")
        return
    end

    table.insert(self._entries, {
        id = self._nextEntryId,
        turn = Game.GetCurrentGameTurn(),
        text = text,
        category = category,
        location = location
    })
    self._nextEntryId = self._nextEntryId + 1

    local capacity = GetCapacity()
    while #self._entries > capacity do
        table.remove(self._entries, 1)
    end

    self._position = 0
end

function MessageBuffer:Clear()
    self._entries = {}
    self._filter = "all"
    self._position = 0
end

function MessageBuffer:Count()
    return #self._entries
end

---@return MessageBufferEntry?
function MessageBuffer:GetCurrentEntry()
    return self:_CurrentEntry()
end

--#endregion

--#region Navigation

local FILTER_CYCLE = {
    "all",
    "notification",
    "reveal",
    "combat",
    "gossip",
    "movement",
    "chat",
}

local function MatchesFilter(entry, filter)
    return filter == "all" or entry.category == filter
end

---@return string[]
function MessageBuffer.GetCategories()
    local categories = {}
    for i, category in ipairs(FILTER_CYCLE) do
        categories[i] = category
    end
    return categories
end

---@param filter MessageCategory|"all"|nil
---@return MessageBufferEntry[]
function MessageBuffer:GetEntries(filter)
    filter = filter or self._filter
    local entries = {}
    for _, entry in ipairs(self._entries) do
        if MatchesFilter(entry, filter) then
            table.insert(entries, entry)
        end
    end
    return entries
end

---@param index integer
---@return MessageBufferEntry
function MessageBuffer:_MoveTo(index)
    self._position = index
    return self._entries[index]
end

---@param direction integer -- 1 or -1
---@param filter MessageCategory|"all"|nil
function MessageBuffer:_FindMatching(fromIndex, direction, filter)
    filter = filter or self._filter
    local index = fromIndex + direction

    while index >= 1 and index <= #self._entries do
        if MatchesFilter(self._entries[index], filter) then
            return index
        end

        index = index + direction
    end

    return nil
end

---@param filter MessageCategory|"all"|nil
function MessageBuffer:_NewestMatching(filter)
    filter = filter or self._filter
    return self:_FindMatching(#self._entries + 1, -1, filter)
end

---@param filter MessageCategory|"all"|nil
function MessageBuffer:_OldestMatching(filter)
    filter = filter or self._filter
    return self:_FindMatching(0, 1, filter)
end

function MessageBuffer:_CurrentEntry()
    if self._position == 0 then
        local newest = self:_NewestMatching()
        if newest == nil then
            return nil
        end

        return self:_MoveTo(newest)
    end

    return self._entries[self._position]
end

---@param direction integer -- -1 or 1
---@return MessageBufferEntry?
function MessageBuffer:_Move(direction)
    local entry = self:_CurrentEntry()
    if entry == nil then
        return nil
    end

    local index = self:_FindMatching(self._position, direction)
    if index ~= nil then
        entry = self:_MoveTo(index)
    end

    return entry
end

function MessageBuffer:Next()
    return self:_Move(1)
end

function MessageBuffer:Previous()
    return self:_Move(-1)
end

function MessageBuffer:JumpFirst()
    local index = self:_OldestMatching()
    if index == nil then
        return nil
    end


    return self:_MoveTo(index)
end

function MessageBuffer:JumpLast()
    local index = self:_NewestMatching()
    if index == nil then
        return nil
    end

    return self:_MoveTo(index)
end

--#endregion

--#region Filtering

---@return MessageCategory|"all"
function MessageBuffer:GetFilter()
    return self._filter
end

---@param filter MessageCategory|"all"
---@return MessageBufferEntry?
function MessageBuffer:SetFilter(filter)
    if filter ~= "all" and not VALID_CATEGORIES[filter] then
        LogWarn("MessageBuffer: unknown filter '" .. tostring(filter) .. "'")
        return nil
    end

    self._filter = filter
    self._position = 0
    return self:GetCurrentEntry()
end

function MessageBuffer:_RotateFilter(direction)
    local count = #FILTER_CYCLE

    local current = 1
    for i, filter in ipairs(FILTER_CYCLE) do
        if filter == self._filter then
            current = i
            break
        end
    end

    for step = 1, count do
        local index = ((current - 1 + step * direction) % count) + 1

        local filter = FILTER_CYCLE[index]
        local newest = self:_NewestMatching(filter)

        if newest ~= nil then
            self._filter = filter

            return self:_MoveTo(newest)
        end
    end

    return nil
end

function MessageBuffer:CycleFilterForward()
    return self:_RotateFilter(1)
end

function MessageBuffer:CycleFilterBackward()
    return self:_RotateFilter(-1)
end

--#endregion

--#region entryInteraction
---@param entry MessageBufferEntry
---@return string?
function MessageBuffer:GetEntryLocationText(entry)
    local loc = entry.location
    if not loc or loc.x == nil or loc.y == nil then
        return nil
    end

    local cursor = ExposedMembers.CAICursor
    if not cursor or not cursor.GetCoords then
        LogError("MessageBuffer: CAI cursor is unavailable while resolving an entry location")
        return nil
    end

    local cursorX, cursorY = cursor:GetCoords()
    if cursorX == nil or cursorY == nil then
        LogWarn("MessageBuffer: CAI cursor has no coordinates while resolving an entry location")
        return nil
    end

    return CAIHexCoordUtils.directionString(cursorX, cursorY, loc.x, loc.y)
end

function MessageBuffer:SpeakEntry()
    local entry = self:GetCurrentEntry()

    if entry == nil then
        Speak(Locale.Lookup("LOC_CAI_MESSAGE_BUFFER_EMPTY"))
        return
    end

    local locationText = self:GetEntryLocationText(entry)
    if locationText and locationText ~= "" then
        Speak(Locale.Lookup("LOC_CAI_MESSAGE_BUFFER_MESSAGE_WITH_LOCATION", entry.text, locationText))
    else
        Speak(entry.text)
    end
end

function MessageBuffer:SpeakFilter()
    local category = Locale.Lookup(
        "LOC_CAI_MESSAGE_BUFFER_CAT_" .. string.upper(self:GetFilter())
    )

    Speak(category)
end

---@param entry? MessageBufferEntry
function MessageBuffer:JumpToEntryLocation(entry)
    entry = entry or self:GetCurrentEntry()
    if not entry then
        LogWarn("MessageBuffer: JumpToEntryLocation called with no current entry")
        return
    end
    local loc = entry.location
    if not loc or not loc.x or not loc.y then
        Speak(Locale.Lookup("LOC_CAI_MESSAGE_BUFFER_EMPTY_LOCATION"))
        LogWarn("MessageBuffer: current entry has no jump location")
        return
    end

    local plot = Map.GetPlot(loc.x, loc.y)
    if not plot then
        LogWarn("CAI message buffer could not find location plot for " .. tostring(loc.x) .. ", " .. tostring(loc.y))
        return
    end
    LuaEvents.CAICursorMoveTo(plot:GetIndex(), "jump")
end

--#endregion


--#region State init
local m_PlayerState = PlayerStateManager.Init(function(playerID)
    return {
        Buffer = MessageBuffer.Create(),
    }
end, function(playerID, state)
    if state == nil or state.Buffer == nil then
        LogError("MessageBuffer: failed to initialize player state for player " .. tostring(playerID))
        return
    end

    LogMessage("MessageBuffer: initialized player buffer for player " .. tostring(playerID))
end)

function MessageBuffer.GetActive()
    local state = m_PlayerState:GetActive()
    if state == nil then
        LogWarn("MessageBuffer: no active player state is available")
        return nil
    end

    if state.Buffer == nil then
        LogError("MessageBuffer: active player state is missing its buffer")
        return nil
    end

    return state.Buffer
end

function MessageBuffer.GetForPlayer(playerID)
    local state = m_PlayerState:Get(playerID)
    if state == nil then
        LogWarn("MessageBuffer: no player state is available for player " .. tostring(playerID))
        return nil
    end

    if state.Buffer == nil then
        LogError("MessageBuffer: player state is missing its buffer for player " .. tostring(playerID))
        return nil
    end

    return state.Buffer
end

function MessageBuffer.ClearActive()
    local buffer = MessageBuffer.GetActive()
    if buffer ~= nil then
        buffer:Clear()
        LogMessage("MessageBuffer: cleared active player buffer")
    else
        LogWarn("MessageBuffer: ClearActive called without an active buffer")
    end
end

ExposedMembers.CAI.GetMessageBuffer = MessageBuffer.GetActive
