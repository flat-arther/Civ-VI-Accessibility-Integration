-- ===========================================================================
--  WorldClimateHistoryManager_CAI
--
--  Records the concrete, per-tile changes each natural disaster causes -- which
--  improvements/districts were pillaged or destroyed, which tiles gained/lost
--  yields, and which cities lost population -- so the Climate Screen's Event
--  History can expand a disaster row into its specifics. Units-lost stays a
--  count on the parent row (a killed unit is gone before we can inspect it).
--
--  Does NOT own the history list: vanilla records persist in
--  GameRandomEvents.GetEventsForTurn and are matched at display time by
--  StartLocation + event type. Missing detail -> the row shows only vanilla's
--  aggregate counts. See docs/game-api.md "Random-event / disaster damage
--  capture" for the probe findings behind this.
--
--  Capture model (probe-validated):
--    * Instantaneous events (floods, volcanoes, comets): RandomEventOccurred,
--      post-damage. randomEventID is always -1 in-session, so one-off footprints
--      use anchor + radius-2 ring; floods use RiverManager.
--    * Persistent events (storms, droughts): fire Occurred once at spawn but
--      apply damage each turn while active (storms move), so they are POLLED on
--      LocalPlayerTurnBegin.
--
--  The game exposes no per-tile / per-yield fertility, so we diff FULL TILE
--  STATE (improvement + pillaged flag + feature + yields) against a snapshot
--  taken each turn over the revealed at-risk tiles (floodplains + volcano rings
--  + active footprints + a radius-2 buffer around storms, which move). The full
--  state lets us tell damage apart from fertility: a pillaged/destroyed
--  improvement is damage; a yield change on a tile whose improvement is
--  unchanged is fertility (a gain always, a loss only when the feature is also
--  unchanged = desertification). The spawn turn of a storm has no before-state,
--  so its fertility falls back to the lump count from GetCurrentTurnEventAtPlot.
--
--  Only tiles the local player has revealed are detailed. Serialized per local
--  player via PlayerConfigurations:SetValue (UI-side, save-persisted, no
--  gameplay-simulation involvement -> no desync), storing ids/numbers only;
--  localized names resolve live at render. Singleton on
--  ExposedMembers.CAI_WorldClimateHistoryManager, built fresh each session,
--  initialized from WorldInput_CAI.
-- ===========================================================================

include("caiUtils")

local CONFIG_KEY = "CAI_ClimateChanges"

local CALLBACK_STORM   = "GetAffectedPlots_Storm"
local CALLBACK_DROUGHT = "GetAffectedPlots_Drought"
local NUCLEAR_ACCIDENT_TYPE = "NUCLEAR_ACCIDENT"

local KIND_IMPROVEMENT = 1
local KIND_DISTRICT    = 2
local KIND_FEATURE     = 3
local KIND_BUILDING    = 4
local KIND_RESOURCE    = 5

local WorldClimateHistoryManager = {}
WorldClimateHistoryManager.__index = WorldClimateHistoryManager

-- ---------------------------------------------------------------------------
-- small helpers
-- ---------------------------------------------------------------------------

local function GetEventCallback(eRandomEvent)
    local def = GameInfo.RandomEvents[eRandomEvent]
    if def == nil then return nil end
    local pres = GameInfo.RandomEvent_Presentation[def.RandomEventType]
    if pres == nil then return nil end
    return pres.Callback
end

local function MakeRecordKey(startPlot, eRandomEvent)
    return tostring(startPlot) .. ":" .. tostring(eRandomEvent)
end

local function AsPlot(entry)
    if type(entry) == "number" then
        return Map.GetPlotByIndex(entry)
    elseif type(entry) == "table" then
        if entry.GetIndex ~= nil or entry.GetX ~= nil then return entry end
    end
    return nil
end

local YIELD_ROWS = nil
local function EnsureYieldRows()
    if YIELD_ROWS ~= nil then return end
    YIELD_ROWS = {}
    for row in GameInfo.Yields() do
        YIELD_ROWS[#YIELD_ROWS + 1] = row.Index
    end
end

local function GetPlotYields(plot)
    EnsureYieldRows()
    local out = {}
    for _, idx in ipairs(YIELD_ROWS) do
        out[idx] = plot:GetYield(idx)
    end
    return out
end

local function GetPlotsInRange(centerPlot, range)
    local result = { centerPlot }
    local seen = { [centerPlot:GetIndex()] = true }
    local frontier = { centerPlot }
    for _ = 1, range do
        local nextFrontier = {}
        for _, p in ipairs(frontier) do
            local adj = Map.GetAdjacentPlots(p:GetX(), p:GetY())
            if adj ~= nil then
                for _, a in ipairs(adj) do
                    if a ~= nil and not seen[a:GetIndex()] then
                        seen[a:GetIndex()] = true
                        result[#result + 1] = a
                        nextFrontier[#nextFrontier + 1] = a
                    end
                end
            end
        end
        frontier = nextFrontier
    end
    return result
end

local function IsPlotRevealedToLocal(plot)
    local localID = Game.GetLocalPlayer()
    if localID == nil or localID < 0 then return false end
    local vis = PlayersVisibility[localID]
    return vis ~= nil and vis:IsRevealed(plot:GetX(), plot:GetY())
end

local function OwningCityID(plotIndex)
    local pCity = Cities.GetPlotPurchaseCity(plotIndex)
    if pCity == nil then return -1 end
    return pCity:GetID()
end

---Live pillaged state of a district on a plot: districtType, pillaged (nil when
---no district or the district object can't be resolved).
local function DistrictInfoAtPlot(plot)
    local eDist = plot:GetDistrictType()
    if eDist == nil or eDist < 0 then return -1, nil end
    local pCity = Cities.GetPlotPurchaseCity(plot:GetIndex())
    if pCity == nil then return eDist, nil end
    for _, pDistrict in pCity:GetDistricts():Members() do
        if pDistrict:GetX() == plot:GetX() and pDistrict:GetY() == plot:GetY() then
            return eDist, pDistrict:IsPillaged()
        end
    end
    return eDist, nil
end

---Units present on a plot, as {id, owner, utype, dmg}. `dmg` is damage taken
---(0 = full health) so a later diff can tell a wounded unit from a killed one.
---Returns nil when empty so a water tile with no units produces no snapshot entry.
local function CaptureUnits(plot)
    local pUnits = Units.GetUnitsInPlot(plot)
    if pUnits == nil then return nil end
    local out = nil
    for _, u in ipairs(pUnits) do
        out = out or {}
        out[#out + 1] = {
            id = u:GetID(), owner = u:GetOwner(), utype = u:GetUnitType(),
            dmg = u:GetDamage() or 0,
        }
    end
    return out
end

---Buildings on a district plot, as {idx, pill}. Disasters pillage buildings one
---at a time (the district itself only pillages once all its buildings are).
local function CaptureBuildings(plot)
    local pCity = Cities.GetPlotPurchaseCity(plot:GetIndex())
    if pCity == nil then return nil end
    local cb = pCity:GetBuildings()
    if cb == nil then return nil end
    local list = cb:GetBuildingsAtLocation(plot:GetIndex())
    if list == nil then return nil end
    local out = nil
    for _, bIdx in ipairs(list) do
        out = out or {}
        out[#out + 1] = { idx = bIdx, pill = cb:IsPillaged(bIdx) }
    end
    return out
end

---Full tile state used for before/after diffs.
local function CaptureTileState(plot)
    local eImp = plot:GetImprovementType()
    local eDist, distPill = DistrictInfoAtPlot(plot)
    local eRes = plot:GetResourceType()
    local bldg = nil
    if eDist ~= nil and eDist >= 0 then
        bldg = CaptureBuildings(plot)
    end
    return {
        y = GetPlotYields(plot),
        imp = (eImp ~= nil) and eImp or -1,
        impPill = (eImp ~= nil and eImp >= 0) and plot:IsImprovementPillaged() or false,
        feat = plot:GetFeatureType() or -1,
        res = (eRes ~= nil) and eRes or -1,
        dist = eDist,
        distPill = distPill,
        bldg = bldg,
        units = CaptureUnits(plot),
    }
end

---True when the local player can see resource `eResource` (it has been revealed
---by tech); guards resource-removal reports so we never leak a hidden resource.
local function ResourceVisibleToLocal(eResource)
    local localID = Game.GetLocalPlayer()
    if localID == nil or localID < 0 then return false end
    local pPlayer = Players[localID]
    local pRes = pPlayer and pPlayer:GetResources()
    local row = GameInfo.Resources[eResource]
    if pRes == nil or row == nil then return false end
    return pRes:IsResourceVisible(row.Hash)
end

-- ---------------------------------------------------------------------------
-- serialization  (ids/numbers only; ASCII delimiters; explicit char classes)
-- ---------------------------------------------------------------------------

local function Serialize(data)
    local recs = {}
    for _, r in pairs(data) do
        local items = { "R|" .. r.sp .. "|" .. r.ev }
        for _, d in ipairs(r.damagedTiles) do
            items[#items + 1] = table.concat(
                { "D", d.plot, d.kind, d.def, d.owner, d.city, d.turn, d.destroyed and 1 or 0 }, "|")
        end
        for _, f in ipairs(r.fertilityTiles) do
            local parts = { "F", f.plot, f.terrain, f.owner, f.city, f.turn }
            if f.deltas ~= nil and next(f.deltas) ~= nil then
                for yi, amt in pairs(f.deltas) do
                    parts[#parts + 1] = yi .. ":" .. amt
                end
            elseif f.amount ~= nil then
                parts[#parts + 1] = "L:" .. f.amount
            end
            items[#items + 1] = table.concat(parts, "|")
        end
        for _, p in ipairs(r.popLost) do
            items[#items + 1] = table.concat({ "P", p.city, p.owner, p.amount, p.turn }, "|")
        end
        for _, u in ipairs(r.unitsLost) do
            items[#items + 1] = table.concat(
                { "U", u.plot, u.owner, u.id, u.utype, u.killed and 1 or 0, u.hp or -1, u.turn }, "|")
        end
        recs[#recs + 1] = table.concat(items, ";")
    end
    return table.concat(recs, "~")
end

local function NewRecord(startPlot, eType)
    return {
        sp = startPlot,
        ev = eType,
        damagedTiles = {},
        fertilityTiles = {},
        popLost = {},
        unitsLost = {},
        _dmgSeen = {},
        _fertSeen = {},
        _popSeen = {},
        _unitEntry = {},
    }
end

---Dedupe key for a damaged tile: plot index plus a kind suffix. Buildings key
---on their own index too, since several may be pillaged on one district tile.
local function DamageKey(plotIndex, kind, def)
    local suffix = "i"
    if kind == KIND_DISTRICT then
        suffix = "d"
    elseif kind == KIND_FEATURE then
        suffix = "f"
    elseif kind == KIND_RESOURCE then
        suffix = "r"
    elseif kind == KIND_BUILDING then
        suffix = "b" .. tostring(def)
    end
    return plotIndex .. suffix
end

local function Deserialize(text)
    local data = {}
    if type(text) ~= "string" or text == "" then
        return data
    end
    for recStr in string.gmatch(text, "[^~]+") do
        local r = nil
        for itemStr in string.gmatch(recStr, "[^;]+") do
            local f = {}
            for fld in string.gmatch(itemStr, "[^|]+") do
                f[#f + 1] = fld
            end
            local t = f[1]
            if t == "R" then
                r = NewRecord(tonumber(f[2]), tonumber(f[3]))
                data[MakeRecordKey(r.sp, r.ev)] = r
            elseif t == "D" and r ~= nil then
                local d = {
                    plot = tonumber(f[2]), kind = tonumber(f[3]), def = tonumber(f[4]),
                    owner = tonumber(f[5]), city = tonumber(f[6]), turn = tonumber(f[7]),
                    destroyed = (f[8] == "1"),
                }
                r.damagedTiles[#r.damagedTiles + 1] = d
                r._dmgSeen[DamageKey(d.plot, d.kind, d.def)] = true
            elseif t == "F" and r ~= nil then
                local ft = {
                    plot = tonumber(f[2]), terrain = tonumber(f[3]), owner = tonumber(f[4]),
                    city = tonumber(f[5]), turn = tonumber(f[6]), deltas = {},
                }
                for i = 7, #f do
                    local lump = string.match(f[i], "^L:(%-?%d+)$")
                    if lump ~= nil then
                        ft.amount = tonumber(lump)
                    else
                        local yi, amt = string.match(f[i], "^(%-?%d+):(%-?%d+)$")
                        if yi ~= nil then ft.deltas[tonumber(yi)] = tonumber(amt) end
                    end
                end
                r.fertilityTiles[#r.fertilityTiles + 1] = ft
                r._fertSeen[ft.plot] = true
            elseif t == "P" and r ~= nil then
                local p = {
                    city = tonumber(f[2]), owner = tonumber(f[3]),
                    amount = tonumber(f[4]), turn = tonumber(f[5]),
                }
                r.popLost[#r.popLost + 1] = p
                r._popSeen[tostring(p.city) .. "@" .. tostring(p.turn)] = true
            elseif t == "U" and r ~= nil then
                local u = {
                    plot = tonumber(f[2]), owner = tonumber(f[3]), id = tonumber(f[4]),
                    utype = tonumber(f[5]), killed = (f[6] == "1"),
                    hp = tonumber(f[7]), turn = tonumber(f[8]),
                }
                r.unitsLost[#r.unitsLost + 1] = u
                if u.id ~= nil then r._unitEntry[u.id] = u end
            end
        end
    end
    return data
end

-- ---------------------------------------------------------------------------
-- lifecycle / persistence
-- ---------------------------------------------------------------------------

function WorldClimateHistoryManager:_LocalPlayerConfig()
    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == nil or localPlayerID < 0 then
        return nil
    end
    return PlayerConfigurations[localPlayerID]
end

function WorldClimateHistoryManager:Load()
    local config = self:_LocalPlayerConfig()
    if config ~= nil then
        self.records = Deserialize(config:GetValue(CONFIG_KEY))
    end
end

function WorldClimateHistoryManager:Save()
    local config = self:_LocalPlayerConfig()
    if config ~= nil then
        config:SetValue(CONFIG_KEY, Serialize(self.records))
    end
end

-- ---------------------------------------------------------------------------
-- public query API (consumed by ClimateScreen_CAI)
-- ---------------------------------------------------------------------------

function WorldClimateHistoryManager:GetRecord(startPlot, eRandomEvent)
    return self.records[MakeRecordKey(startPlot, eRandomEvent)]
end

-- ---------------------------------------------------------------------------
-- capture primitives
-- ---------------------------------------------------------------------------

function WorldClimateHistoryManager:_GetOrCreateRecord(startPlot, eType)
    local key = MakeRecordKey(startPlot, eType)
    local r = self.records[key]
    if r == nil then
        r = NewRecord(startPlot, eType)
        self.records[key] = r
    end
    return r
end

local function AddDamage(record, plot, kind, def, destroyed, turn)
    local idx = plot:GetIndex()
    local k = DamageKey(idx, kind, def)
    if record._dmgSeen[k] then return false end
    record._dmgSeen[k] = true
    record.damagedTiles[#record.damagedTiles + 1] = {
        plot = idx, kind = kind, def = def,
        owner = plot:GetOwner(), city = OwningCityID(idx), destroyed = destroyed, turn = turn,
    }
    return true
end

---Inspect one plot against its before-state; record damage (pillage/destroy)
---and fertility (yield deltas). Returns true if the record changed.
function WorldClimateHistoryManager:_CapturePlot(record, plot, turn, prevState)
    if not IsPlotRevealedToLocal(plot) then return false end
    local cur = CaptureTileState(plot)
    local changed = false

    -- Water tiles carry a units-only snapshot (no tile state); the tile-state
    -- diffs below need a full before-state, so fall back to nil for those.
    local prevTile = prevState
    if prevTile ~= nil and prevTile.y == nil then prevTile = nil end

    -- improvement damage
    if cur.imp >= 0 and cur.impPill then
        if prevTile == nil or prevTile.imp ~= cur.imp or not prevTile.impPill then
            if AddDamage(record, plot, KIND_IMPROVEMENT, cur.imp, false, turn) then changed = true end
        end
    elseif prevTile ~= nil and prevTile.imp >= 0 and not prevTile.impPill and cur.imp < 0 then
        -- improvement was intact, now gone -> destroyed
        if AddDamage(record, plot, KIND_IMPROVEMENT, prevTile.imp, true, turn) then changed = true end
    end

    -- district damage
    if cur.dist >= 0 and cur.distPill == true then
        if prevTile == nil or prevTile.distPill ~= true then
            if AddDamage(record, plot, KIND_DISTRICT, cur.dist, false, turn) then changed = true end
        end
    end

    -- building damage: a building newly pillaged on a district tile.
    if cur.bldg ~= nil then
        local prevPill = {}
        if prevTile ~= nil and prevTile.bldg ~= nil then
            for _, b in ipairs(prevTile.bldg) do prevPill[b.idx] = b.pill end
        end
        for _, b in ipairs(cur.bldg) do
            if b.pill and (prevTile == nil or prevPill[b.idx] ~= true) then
                if AddDamage(record, plot, KIND_BUILDING, b.idx, false, turn) then changed = true end
            end
        end
    end

    -- feature removal: a feature that was present is now gone.
    if prevTile ~= nil and prevTile.feat >= 0 and cur.feat < 0 then
        if AddDamage(record, plot, KIND_FEATURE, prevTile.feat, true, turn) then changed = true end
    end

    -- resource removal: a resource that was present (and known to us) is now gone
    -- (volcanic eruptions destroy bonus resources).
    if prevTile ~= nil and prevTile.res ~= nil and prevTile.res >= 0 and cur.res < 0
        and ResourceVisibleToLocal(prevTile.res) then
        if AddDamage(record, plot, KIND_RESOURCE, prevTile.res, true, turn) then changed = true end
    end

    -- fertility: only a yield change NOT caused by the improvement changing.
    -- Gains are always fertility; losses only count when the feature is also
    -- unchanged (pure desertification, not feature/improvement destruction).
    if prevTile ~= nil and not record._fertSeen[plot:GetIndex()] then
        local impUnchanged = (prevTile.imp == cur.imp) and (prevTile.impPill == cur.impPill)
        if impUnchanged then
            local deltas = {}
            local anyPos, anyNeg = false, false
            for yi, v in pairs(cur.y) do
                local pv = prevTile.y[yi]
                if pv == nil then pv = v end
                local d = v - pv
                if d ~= 0 then
                    deltas[yi] = d
                    if d > 0 then anyPos = true else anyNeg = true end
                end
            end
            local report = anyPos or (anyNeg and prevTile.feat == cur.feat)
            if report and next(deltas) ~= nil then
                record._fertSeen[plot:GetIndex()] = true
                local idx = plot:GetIndex()
                record.fertilityTiles[#record.fertilityTiles + 1] = {
                    plot = idx, terrain = plot:GetTerrainType(), owner = plot:GetOwner(),
                    city = OwningCityID(idx), deltas = deltas, turn = turn,
                }
                changed = true
            end
        end
    end

    return changed
end

---Record unit casualties for an event, from the before-snapshot of its affected
---plots. A snapshotted unit that no longer exists (UnitManager.GetUnit == nil)
---was killed -- a unit that merely moved still resolves to an object elsewhere,
---so existence separates the two; kills are capped at the event's own UnitsLost
---so we never report more than vanilla counts. A unit still on the same plot with
---more damage than its snapshot was wounded (military units lose HP rather than
---dying); wounds have no vanilla counter, so they are gated on the unit staying
---put. One entry per unit, updated in place so a wound that later becomes a kill
---is upgraded rather than duplicated.
function WorldClimateHistoryManager:_CaptureUnitCasualties(record, plots, killBudget, turn)
    if plots == nil then return false end
    killBudget = killBudget or 0
    local changed = false
    for _, e in ipairs(plots) do
        local p = AsPlot(e)
        if p ~= nil and IsPlotRevealedToLocal(p) then
            local prev = self.stateSnapshot[p:GetIndex()]
            if prev ~= nil and prev.units ~= nil then
                for _, u in ipairs(prev.units) do
                    local live = UnitManager.GetUnit(u.owner, u.id)
                    local entry = record._unitEntry[u.id]
                    if live == nil then
                        if entry ~= nil then
                            if not entry.killed then entry.killed = true; changed = true end
                        elseif killBudget > 0 then
                            entry = {
                                plot = p:GetIndex(), owner = u.owner, utype = u.utype,
                                id = u.id, killed = true, hp = -1, turn = turn,
                            }
                            record.unitsLost[#record.unitsLost + 1] = entry
                            record._unitEntry[u.id] = entry
                            killBudget = killBudget - 1
                            changed = true
                        end
                    elseif live:GetX() == p:GetX() and live:GetY() == p:GetY() then
                        local curDmg = live:GetDamage() or 0
                        if curDmg > (u.dmg or 0) then
                            local hp = (live:GetMaxDamage() or 100) - curDmg
                            if entry ~= nil then
                                if not entry.killed and entry.hp ~= hp then
                                    entry.hp = hp; changed = true
                                end
                            else
                                entry = {
                                    plot = p:GetIndex(), owner = u.owner, utype = u.utype,
                                    id = u.id, killed = false, hp = hp, turn = turn,
                                }
                                record.unitsLost[#record.unitsLost + 1] = entry
                                record._unitEntry[u.id] = entry
                                changed = true
                            end
                        end
                    end
                end
            end
        end
    end
    return changed
end

---Fallback fertility when the per-yield diff had no before-state (a storm's
---spawn turn): store the event's lump FertilityAdded at `plotIndex`.
function WorldClimateHistoryManager:_RecordFertilityLump(record, plotIndex, amount, turn)
    if amount == nil or amount == 0 then return false end
    local plot = Map.GetPlotByIndex(plotIndex)
    if plot == nil or not IsPlotRevealedToLocal(plot) then return false end
    if record._fertSeen[plotIndex] then return false end
    record._fertSeen[plotIndex] = true
    record.fertilityTiles[#record.fertilityTiles + 1] = {
        plot = plotIndex, terrain = plot:GetTerrainType(), owner = plot:GetOwner(),
        city = OwningCityID(plotIndex), amount = amount, turn = turn,
    }
    return true
end

function WorldClimateHistoryManager:_RecordPop(record, plotIndex, amount, turn)
    if amount == nil or amount <= 0 then return false end
    local plot = Map.GetPlotByIndex(plotIndex)
    if plot == nil or not IsPlotRevealedToLocal(plot) then return false end
    local pCity = Cities.GetPlotPurchaseCity(plotIndex)
    if pCity == nil then return false end
    local cityID = pCity:GetID()
    local key = tostring(cityID) .. "@" .. tostring(turn)
    if record._popSeen[key] then return false end
    record._popSeen[key] = true
    record.popLost[#record.popLost + 1] = {
        city = cityID, owner = pCity:GetOwner(), amount = amount, turn = turn,
    }
    return true
end

-- ---------------------------------------------------------------------------
-- before-state snapshot
--
-- We cannot predict where a storm/drought will spawn, so a buffer around known
-- footprints can never cover a fresh spawn's first turn. Instead we snapshot the
-- whole revealed map each turn; any event -- moving or newly spawned -- then has
-- last turn's before-state to diff against, so per-yield fertility never falls
-- back to a lump. Water tiles are skipped unless they carry an improvement (the
-- only thing a disaster can change there, e.g. pillaged fishing boats); fertility
-- and districts are land-only.
-- ---------------------------------------------------------------------------

function WorldClimateHistoryManager:_RefreshSnapshot()
    local snap = {}
    local localID = Game.GetLocalPlayer()
    if localID == nil or localID < 0 then
        self.stateSnapshot = snap
        return
    end
    local vis = PlayersVisibility[localID]
    if vis == nil then
        self.stateSnapshot = snap
        return
    end

    local count = Map.GetPlotCount()
    for idx = 0, count - 1 do
        local plot = Map.GetPlotByIndex(idx)
        if plot ~= nil and vis:IsRevealed(plot:GetX(), plot:GetY()) then
            if not plot:IsWater() then
                snap[idx] = CaptureTileState(plot)
            else
                -- Water tiles carry no fertility and no districts; snapshot them
                -- only for a pillaged/destroyed improvement or a lost unit
                -- (e.g. fishing boats, naval units caught by a hurricane).
                local eImp = plot:GetImprovementType()
                if eImp ~= nil and eImp >= 0 then
                    snap[idx] = CaptureTileState(plot)
                else
                    local units = CaptureUnits(plot)
                    if units ~= nil then
                        snap[idx] = { units = units }
                    end
                end
            end
        end
    end

    self.stateSnapshot = snap
end

-- ---------------------------------------------------------------------------
-- capture: instantaneous events (floods, one-offs)
-- ---------------------------------------------------------------------------

function WorldClimateHistoryManager:_ResolveInstantPlots(callback, plotx, ploty)
    local plots = {}
    if callback == "GetAffectedPlots_Flood" and RiverManager ~= nil then
        local eRiver = RiverManager.GetRiverForFloodplain(plotx, ploty)
        if eRiver ~= nil and eRiver >= 0 then
            local p = RiverManager.GetFloodplainPlots(eRiver)
            if p ~= nil then
                for _, e in ipairs(p) do
                    local pl = AsPlot(e)
                    if pl ~= nil then plots[#plots + 1] = pl end
                end
            end
        end
    end
    if #plots == 0 then
        local center = Map.GetPlot(plotx, ploty)
        if center ~= nil then
            plots = GetPlotsInRange(center, 2)
        end
    end
    return plots
end

function WorldClimateHistoryManager:_OnRandomEventOccurred(eType, severity, plotx, ploty, mitigationLevel, randomEventID)
    local def = GameInfo.RandomEvents[eType]
    if def == nil or def.EffectOperatorType == NUCLEAR_ACCIDENT_TYPE then
        return
    end
    local callback = GetEventCallback(eType)
    if callback == CALLBACK_STORM or callback == CALLBACK_DROUGHT then
        return
    end

    local turn = Game.GetCurrentGameTurn()
    local anchorIdx = Map.GetPlotIndex(plotx, ploty)
    local record = self:_GetOrCreateRecord(anchorIdx, eType)

    local changed = false
    local fertBefore = #record.fertilityTiles
    local affected = self:_ResolveInstantPlots(callback, plotx, ploty)
    for _, plot in ipairs(affected) do
        if self:_CapturePlot(record, plot, turn, self.stateSnapshot[plot:GetIndex()]) then
            changed = true
        end
    end

    local ev = GameRandomEvents.GetCurrentTurnEventAtPlot(anchorIdx)
    if ev ~= nil then
        if #record.fertilityTiles == fertBefore and ev.FertilityAdded ~= nil and ev.FertilityAdded ~= 0 then
            if self:_RecordFertilityLump(record, anchorIdx, ev.FertilityAdded, turn) then changed = true end
        end
        if ev.PopLost ~= nil and ev.PopLost > 0 then
            if self:_RecordPop(record, anchorIdx, ev.PopLost, turn) then changed = true end
        end
    end

    -- Pillaging / destruction / unit losses are applied AFTER RandomEventOccurred
    -- fires (the plots still read intact here), so re-scan these plots on the next
    -- turn-begin(s) to catch the damage. We keep each plot's own before-state so
    -- the diff is stable even after the live snapshot is refreshed. Fertility/pop
    -- are applied now and captured above.
    local baseline = {}
    local plotIdx = {}
    for _, plot in ipairs(affected) do
        local idx = plot:GetIndex()
        plotIdx[#plotIdx + 1] = idx
        baseline[idx] = self.stateSnapshot[idx]
    end
    self.pendingInstant[#self.pendingInstant + 1] = {
        record = record, plots = plotIdx, baseline = baseline, turn = turn,
        unitBudget = (ev ~= nil and ev.UnitsLost) or 0, ttl = 2,
    }

    if changed then self:Save() end
end

---Second-pass capture for instant events queued earlier: pillaging and unit
---casualties land after the event fires, so we diff the affected plots again
---against each event's stored pre-event baseline. Runs for a couple of turn-begins
---per event to be sure the damage has landed.
function WorldClimateHistoryManager:_ProcessPendingInstant()
    if #self.pendingInstant == 0 then return false end
    local changed = false
    local keep = {}
    for _, pend in ipairs(self.pendingInstant) do
        local plotObjs = {}
        for _, idx in ipairs(pend.plots) do
            local plot = Map.GetPlotByIndex(idx)
            if plot ~= nil then
                plotObjs[#plotObjs + 1] = plot
                if self:_CapturePlot(pend.record, plot, pend.turn, pend.baseline[idx]) then
                    changed = true
                end
            end
        end
        if self:_CaptureUnitCasualties(pend.record, plotObjs, pend.unitBudget, pend.turn) then
            changed = true
        end
        pend.ttl = pend.ttl - 1
        if pend.ttl > 0 then keep[#keep + 1] = pend end
    end
    self.pendingInstant = keep
    return changed
end

-- ---------------------------------------------------------------------------
-- capture: persistent events (storms, droughts) -- poll
-- ---------------------------------------------------------------------------

---Identity from the info table (StartTurn + type), stable across the event's
---life; startPlot is the first-seen CurrentLocation (= vanilla StartLocation
---when first seen at birth, which the poll always is).
function WorldClimateHistoryManager:_PollActive(activeMap, count, getInfo, getPlots, typeField, turn)
    local changed = false
    local seen = {}
    for i = 0, count - 1 do
        local info = getInfo(i)
        if info ~= nil and info.CurrentLocation ~= nil and info[typeField] ~= nil and info.StartTurn ~= nil then
            local identity = tostring(info.StartTurn) .. "_" .. tostring(info[typeField])
            seen[identity] = true
            local startPlot = activeMap[identity]
            if startPlot == nil then
                startPlot = info.CurrentLocation
                activeMap[identity] = startPlot
            end
            local record = self:_GetOrCreateRecord(startPlot, info[typeField])

            local fertBefore = #record.fertilityTiles
            local plots = getPlots(i)
            if plots ~= nil then
                -- DEBUG(remove): per-footprint-tile before/after yield dump. Disabled;
                -- uncomment to diagnose drought/storm tile-count mismatches vs vanilla.
                --[==[
                local dpfx = "CAI_CLIMATE_MGR | POLL type=" .. tostring(info[typeField])
                    .. " start=" .. tostring(info.StartTurn) .. " turn=" .. turn
                print(dpfx .. " footprint=" .. tostring(#plots))
                for _, e in ipairs(plots) do
                    local p = AsPlot(e)
                    if p ~= nil then
                        local idx = p:GetIndex()
                        local prev = self.stateSnapshot[idx]
                        local curY = GetPlotYields(p)
                        local deltas = {}
                        for _, yi in ipairs(YIELD_ROWS) do
                            local pv = (prev ~= nil and prev.y ~= nil) and prev.y[yi] or nil
                            local cv = curY[yi]
                            if pv ~= nil and cv ~= pv then
                                deltas[#deltas + 1] = tostring(yi) .. ":" .. tostring(pv) .. "->" .. tostring(cv)
                            end
                        end
                        local eImp = p:GetImprovementType()
                        local impS = (eImp ~= nil and eImp >= 0)
                            and ("imp=" .. eImp .. "/pill=" .. tostring(p:IsImprovementPillaged()))
                            or "imp=none"
                        local baseS = (prev == nil) and "NIL" or ((prev.y == nil) and "unitsonly" or "ok")
                        print(dpfx .. "   idx=" .. idx .. " (" .. p:GetX() .. "," .. p:GetY() .. ") "
                            .. impS .. " revealed=" .. tostring(IsPlotRevealedToLocal(p))
                            .. " baseline=" .. baseS .. " ydelta={" .. table.concat(deltas, ",") .. "}")
                    end
                end
                ]==]
                for _, e in ipairs(plots) do
                    local p = AsPlot(e)
                    if p ~= nil and self:_CapturePlot(record, p, turn, self.stateSnapshot[p:GetIndex()]) then
                        changed = true
                    end
                end
            end

            local ev = GameRandomEvents.GetCurrentTurnEventAtPlot(info.CurrentLocation)
            if ev ~= nil then
                if #record.fertilityTiles == fertBefore and ev.FertilityAdded ~= nil and ev.FertilityAdded ~= 0 then
                    if self:_RecordFertilityLump(record, info.CurrentLocation, ev.FertilityAdded, turn) then changed = true end
                end
                if ev.PopLost ~= nil and ev.PopLost > 0 then
                    if self:_RecordPop(record, info.CurrentLocation, ev.PopLost, turn) then changed = true end
                end
                if self:_CaptureUnitCasualties(record, plots, ev.UnitsLost or 0, turn) then changed = true end
            end
        end
    end
    for id in pairs(activeMap) do
        if not seen[id] then activeMap[id] = nil end
    end
    return changed
end

function WorldClimateHistoryManager:_OnLocalPlayerTurnBegin()
    local localID = Game.GetLocalPlayer()
    if localID == nil or localID < 0 then return end
    local turn = Game.GetCurrentGameTurn()

    local changed = false
    if GameClimate.GetNumActiveStorms ~= nil then
        if self:_PollActive(self.activeStorms, GameClimate.GetNumActiveStorms(),
            function(i) return GameClimate.GetActiveStormByIndex(i) end,
            function(i) return GameClimate.GetActiveStormPlotsByIndex(i) end,
            "StormType", turn) then
            changed = true
        end
    end
    if GameClimate.GetNumActiveDroughts ~= nil then
        if self:_PollActive(self.activeDroughts, GameClimate.GetNumActiveDroughts(),
            function(i) return GameClimate.GetActiveDroughtByIndex(i) end,
            function(i) return GameClimate.GetActiveDroughtPlotsByIndex(i) end,
            "DroughtType", turn) then
            changed = true
        end
    end

    -- Re-scan last turn's instant events for damage that lands after they fire.
    -- Must run before the snapshot is refreshed (it uses the old baseline).
    if self:_ProcessPendingInstant() then changed = true end

    self:_RefreshSnapshot()

    if changed then self:Save() end
end

-- ---------------------------------------------------------------------------
-- registration
-- ---------------------------------------------------------------------------

function WorldClimateHistoryManager:_Register()
    Events.RandomEventOccurred.Add(function(...)
        self:_OnRandomEventOccurred(...)
    end)
    Events.LocalPlayerTurnBegin.Add(function()
        self:_OnLocalPlayerTurnBegin()
    end)
    -- Bootstrap the before-state the moment the game is ready to play. Without
    -- this, loading a save and ending the turn fires a disaster against an empty
    -- snapshot: every tile has no baseline, so an already-pillaged improvement
    -- reads as fresh damage and no fertility delta can be computed. LoadScreenClose
    -- fires on new games and save loads alike, before the first end-turn.
    Events.LoadScreenClose.Add(function()
        self:_RefreshSnapshot()
    end)
end

-- ---------------------------------------------------------------------------
-- construction  (always fresh; ExposedMembers is stale across reload)
-- ---------------------------------------------------------------------------

local instance = setmetatable({}, WorldClimateHistoryManager)
instance.records = {}
instance.activeStorms = {}      -- identity -> startPlot
instance.activeDroughts = {}    -- identity -> startPlot
instance.stateSnapshot = {}     -- plotIndex -> tile state
instance.pendingInstant = {}    -- instant events awaiting a next-turn re-scan

instance:Load()
instance:_Register()

ExposedMembers.CAI_WorldClimateHistoryManager = instance

return instance
