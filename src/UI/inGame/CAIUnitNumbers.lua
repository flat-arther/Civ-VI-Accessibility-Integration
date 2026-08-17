-- ===========================================================================
--  CAIUnitNumbers
--
--  UI-side registry that gives same-typed units a stable per-owner number
--  (e.g. "Warrior 1", "Warrior 2") so a screen-reader user can tell them apart.
--
--  Design:
--    * Entirely in the UI layer -- no gameplay script and no unit properties.
--    * A unit is numbered the lowest slot not held by that owner's other living
--      KNOWN units of the same type, so a lost unit's number is reused
--      (gap-filling) while surviving units keep their number.
--    * "Known" means observed by the local player: own units are numbered when
--      created, other players' units only when first seen. Numbering another
--      player's units at creation would leak how many they have (a visible
--      "Apostle 1" and "Apostle 3" with no "2" reveals a unit never seen).
--    * The whole registry is serialized into the local player's configuration,
--      so numbers persist across save/load. Keying by the local player also
--      keeps hotseat players' views separate (each sees their own numbers).
--
--  Shared singleton on ExposedMembers.CAIUnitNumbers; created once and reused by
--  every screen that speaks a unit name (see inGameHelpers_CAI.lua).
-- ===========================================================================

local CONFIG_KEY = "CAI_UnitNumbers"

local CAIUnitNumbers = {}
CAIUnitNumbers.__index = CAIUnitNumbers

-- ---------------------------------------------------------------------------
-- Serialization: data[ownerID][unitID] = number  <->  "o:u:n|o:u:n|..."
-- ---------------------------------------------------------------------------
local function Serialize(data)
    local parts = {}
    for ownerID, byUnit in pairs(data) do
        for unitID, number in pairs(byUnit) do
            parts[#parts + 1] = string.format("%d:%d:%d", ownerID, unitID, number)
        end
    end
    return table.concat(parts, "|")
end

local function Deserialize(text)
    local data = {}
    if type(text) ~= "string" or text == "" then
        return data
    end

    for entry in string.gmatch(text, "[^|]+") do
        local ownerID, unitID, number = string.match(entry, "^(%-?%d+):(%-?%d+):(%-?%d+)$")
        if ownerID ~= nil then
            ownerID = tonumber(ownerID)
            unitID = tonumber(unitID)
            number = tonumber(number)
            local byUnit = data[ownerID]
            if byUnit == nil then
                byUnit = {}
                data[ownerID] = byUnit
            end
            byUnit[unitID] = number
        end
    end
    return data
end

-- ---------------------------------------------------------------------------
-- Persistence (per local player, saved with the game)
-- ---------------------------------------------------------------------------
function CAIUnitNumbers:_LocalPlayerConfig()
    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == nil or localPlayerID < 0 then
        return nil
    end
    return PlayerConfigurations[localPlayerID]
end

function CAIUnitNumbers:Load()
    self.data = {}
    local config = self:_LocalPlayerConfig()
    if config ~= nil then
        self.data = Deserialize(config:GetValue(CONFIG_KEY))
    end
end

function CAIUnitNumbers:Save()
    local config = self:_LocalPlayerConfig()
    if config ~= nil then
        config:SetValue(CONFIG_KEY, Serialize(self.data))
    end
end

-- ---------------------------------------------------------------------------
-- Core queries
-- ---------------------------------------------------------------------------

---Returns the stored number for a unit, or nil if it has none.
function CAIUnitNumbers:Get(ownerID, unitID)
    local byUnit = self.data[ownerID]
    return byUnit ~= nil and byUnit[unitID] or nil
end

---Walks the owner's known units of a type+formation, returning the set of numbers
---still in use by living units and how many living known units there are.
---Formation is part of the key so a "Tank Corps" is numbered among tank corps, not
---among plain tanks.
---@return table used, number count
function CAIUnitNumbers:_LivingUsage(ownerID, typeKey, formation)
    local used = {}
    local count = 0
    local byUnit = self.data[ownerID]
    if byUnit ~= nil then
        for unitID, number in pairs(byUnit) do
            local unit = UnitManager.GetUnit(ownerID, unitID)
            if unit ~= nil and unit:GetUnitType() == typeKey and unit:GetMilitaryFormation() == formation then
                used[number] = true
                count = count + 1
            end
        end
    end
    return used, count
end

---Number of the owner's still-living known units of a type+formation.
function CAIUnitNumbers:CountKnownOfType(ownerID, typeKey, formation)
    local _, count = self:_LivingUsage(ownerID, typeKey, formation)
    return count
end

-- ---------------------------------------------------------------------------
-- Assignment
-- ---------------------------------------------------------------------------

---Assigns the lowest free slot number to a unit if it does not already have one.
---Returns true when a new number was assigned.
function CAIUnitNumbers:Assign(unit)
    if unit == nil then
        return false
    end

    local ownerID = unit:GetOwner()
    local unitID = unit:GetID()

    local byUnit = self.data[ownerID]
    if byUnit ~= nil and byUnit[unitID] ~= nil then
        return false
    end

    local used = self:_LivingUsage(ownerID, unit:GetUnitType(), unit:GetMilitaryFormation())
    local number = 1
    while used[number] do
        number = number + 1
    end

    if byUnit == nil then
        byUnit = {}
        self.data[ownerID] = byUnit
    end
    byUnit[unitID] = number
    return true
end

---Reassigns an already-tracked unit's number for its current type+formation. Used
---when a unit forms a corps/army so it is renumbered among its new group (and can't
---collide with a corps that already holds its old number). Units that are not yet
---tracked are left alone -- creation/visibility owns first numbering.
function CAIUnitNumbers:Reassign(unit)
    if unit == nil then
        return false
    end

    local ownerID = unit:GetOwner()
    local byUnit = self.data[ownerID]
    if byUnit == nil or byUnit[unit:GetID()] == nil then
        return false
    end

    byUnit[unit:GetID()] = nil
    return self:Assign(unit)
end

---Numbers all of the local player's current units in unit-id (creation) order.
---Used after load / a local-player change to catch units that predate this
---session's events. Existing numbers are preserved; only missing ones are added.
function CAIUnitNumbers:BackfillLocalUnits()
    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == nil or localPlayerID < 0 then
        return
    end

    local pPlayer = Players[localPlayerID]
    if pPlayer == nil then
        return
    end

    local units = {}
    for _, unit in pPlayer:GetUnits():Members() do
        units[#units + 1] = unit
    end
    table.sort(units, function(a, b) return a:GetID() < b:GetID() end)

    local changed = false
    for _, unit in ipairs(units) do
        if self:Assign(unit) then
            changed = true
        end
    end
    if changed then
        self:Save()
    end
end

-- ---------------------------------------------------------------------------
-- Event handlers
-- ---------------------------------------------------------------------------
function CAIUnitNumbers:_OnUnitAddedToMap(playerID, unitID)
    if playerID ~= Game.GetLocalPlayer() then
        return
    end
    local unit = UnitManager.GetUnit(playerID, unitID)
    if unit ~= nil and self:Assign(unit) then
        self:Save()
    end
end

function CAIUnitNumbers:_OnUnitVisibilityChanged(playerID, unitID, eVisibility)
    if playerID == nil or playerID < 0 or playerID == Game.GetLocalPlayer() then
        return
    end
    if eVisibility ~= RevealedState.VISIBLE then
        return
    end
    local unit = UnitManager.GetUnit(playerID, unitID)
    if unit ~= nil and self:Assign(unit) then
        self:Save()
    end
end

function CAIUnitNumbers:_OnUnitRemovedFromMap(playerID, unitID)
    -- Prune the entry only when the unit is truly gone, not merely fogged.
    -- UnitManager.GetUnit returns the object for any unit that still exists
    -- regardless of the local player's visibility, and nil once it is destroyed
    -- or merged (e.g. consumed into a corps). This keeps the saved registry lean
    -- without disturbing a fogged-but-alive unit's number.
    if UnitManager.GetUnit(playerID, unitID) ~= nil then
        return
    end

    local byUnit = self.data[playerID]
    if byUnit ~= nil and byUnit[unitID] ~= nil then
        byUnit[unitID] = nil
        self:Save()
    end
end

function CAIUnitNumbers:_OnUnitEnterFormation(playerID1, unitID1, playerID2, unitID2)
    local changed = false
    local u1 = UnitManager.GetUnit(playerID1, unitID1)
    if u1 ~= nil and self:Reassign(u1) then
        changed = true
    end
    local u2 = UnitManager.GetUnit(playerID2, unitID2)
    if u2 ~= nil and self:Reassign(u2) then
        changed = true
    end
    if changed then
        self:Save()
    end
end

function CAIUnitNumbers:_OnGameLoaded()
    self:Load()
    self:BackfillLocalUnits()
end

function CAIUnitNumbers:_Register()
    Events.UnitAddedToMap.Add(function(playerID, unitID) self:_OnUnitAddedToMap(playerID, unitID) end)
    Events.UnitVisibilityChanged.Add(function(playerID, unitID, eVis) self:_OnUnitVisibilityChanged(playerID, unitID, eVis) end)
    Events.UnitEnterFormation.Add(function(p1, u1, p2, u2) self:_OnUnitEnterFormation(p1, u1, p2, u2) end)
    Events.UnitRemovedFromMap.Add(function(playerID, unitID) self:_OnUnitRemovedFromMap(playerID, unitID) end)
    Events.LoadScreenClose.Add(function() self:_OnGameLoaded() end)
    -- Hotseat / observer: the local player changing swaps whose numbers we show.
    Events.LocalPlayerChanged.Add(function() self:_OnGameLoaded() end)
end

-- ---------------------------------------------------------------------------
-- Shared singleton
-- ---------------------------------------------------------------------------
-- Always build a fresh instance owned by the current (live) context. ExposedMembers
-- is NOT cleared on game reload, so a stale instance left there would carry closures
-- bound to a destroyed Lua environment (UnitManager etc. would resolve to nil). This
-- file is included only by the long-lived WorldInput context, so it loads exactly
-- once per session and replacing the reference here is correct.
local instance = setmetatable({ data = {} }, CAIUnitNumbers)
instance:Load()
-- Capture units that already exist now (a loaded save, or a new game whose units
-- are placed by the time this context initializes). LoadScreenClose and
-- LocalPlayerChanged handle later loads and hotseat swaps. All idempotent.
instance:BackfillLocalUnits()
instance:_Register()
ExposedMembers.CAIUnitNumbers = instance
