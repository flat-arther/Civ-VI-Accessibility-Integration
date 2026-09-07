-- ===========================================================================
--  WorldBuilderVisManager_CAI.lua
--  World Builder per-player visibility model.
--
--  The World Builder is a static map-data editor. Its SQLite tables (including
--  RevealedPlots) exist only on disk inside the .Civ6Map and are written on
--  save, so there is no live table read while editing. This manager keeps the
--  visibility state in memory instead:
--
--    * base  -- persistent "revealed" set per player: seeded from the loaded
--               map's RevealedPlots table at load, then updated live as the Set
--               Visibility tool reveals/hides plots (those edits do not reach
--               disk until the next save).
--    * sight -- plots currently seen by placed units and cities, recomputed
--               from live placements with full line-of-sight whenever a unit or
--               city is added/removed/moved.
--
--  A plot is "revealed" for a player when it is in base OR sight. The manager is
--  published as ExposedMembers.CAI_WBVisManager and consumed by the cursor,
--  surveyor, world scanner, and plot tooltip through the shared reveal gate in
--  caiUtils (GetWorldBuilderRevealGate), which activates only while the Set
--  Visibility tool is armed on a player.
--
--  Sight model (from the game database, Base/Assets/Gameplay/Data):
--    * base range          = Units.BaseSightRange (WB units carry no promotions,
--                            so no promotion/leader sight bonuses apply here).
--    * standing/vantage     = Terrains.SightModifier (Hills 1, Mountain 2) plus
--                            +1 for a City Center / Encampment on the tile.
--    * obstruction (blocks  = SightThroughModifier on the terrain AND the
--      sight passing across)  feature, summed (Hills 1, Mountain 2, Woods/
--                            Jungle 1 -> Hills+Woods 2), plus +1 for a City
--                            Center / Encampment. This numeric height is exactly
--                            the wiki's elevation levels.
--  Line of sight: a target is visible if there is a hex line from the viewer on
--  which every intervening tile's obstruction height is below max(targetHeight,
--  viewerHeight + 1). Because a hex more than one tile away is fronted by two
--  neighbours, the target is hidden only when BOTH candidate lines are blocked
--  (the "half-hidden is still visible" rule).
--  Rules: https://civilization.fandom.com/wiki/Sight_(Civ6)
-- ===========================================================================

local VisManager = {}

-- Per-player revealed / sighted sets: table[playerID][plotIndex] = true.
-- Rebuilt fresh each session (never guarded on a stale ExposedMembers value).
local m_base = {}
local m_sight = {}

-- Cities have no unit sight row; give the city centre a fixed reveal radius.
local CITY_SIGHT_RANGE = 3

-- ---------------------------------------------------------------------------
-- Static sight data
-- ---------------------------------------------------------------------------

-- District indices that add a height level (City Center / Encampment). Built
-- lazily from GameInfo the first time it is needed.
local m_tallDistricts = nil
local function IsTallDistrict(districtIndex)
    if districtIndex == nil or districtIndex < 0 then return false end
    if m_tallDistricts == nil then
        m_tallDistricts = {}
        for row in GameInfo.Districts() do
            if row.DistrictType == "DISTRICT_CITY_CENTER"
                or row.DistrictType == "DISTRICT_ENCAMPMENT" then
                m_tallDistricts[row.Index] = true
            end
        end
    end
    return m_tallDistricts[districtIndex] == true
end

local function DistrictHeight(plot)
    return IsTallDistrict(plot:GetDistrictType()) and 1 or 0
end

-- How much a tile blocks sight passing across it.
local function ObstructHeight(plot)
    local h = 0
    local terrain = GameInfo.Terrains[plot:GetTerrainType()]
    if terrain ~= nil and terrain.SightThroughModifier ~= nil then
        h = h + terrain.SightThroughModifier
    end
    local featureType = plot:GetFeatureType()
    if featureType ~= nil and featureType >= 0 then
        local feature = GameInfo.Features[featureType]
        if feature ~= nil and feature.SightThroughModifier ~= nil then
            h = h + feature.SightThroughModifier
        end
    end
    return h + DistrictHeight(plot)
end

-- Vantage height of a unit standing on a tile.
local function ViewerHeight(plot)
    local terrain = GameInfo.Terrains[plot:GetTerrainType()]
    local h = (terrain ~= nil and terrain.SightModifier) or 0
    return h + DistrictHeight(plot)
end

-- Base sight radius for a placed unit. WB units have no promotions.
local function UnitSightRange(unit)
    local row = GameInfo.Units[unit:GetUnitType()]
    local r = row and row.BaseSightRange
    if r == nil or r < 1 then r = 2 end
    return r
end

-- ---------------------------------------------------------------------------
-- Hex geometry (cube coordinates; matches hexCoordUtils_CAI, kept local so the
-- manager is self-contained and can run before that module is available)
-- ---------------------------------------------------------------------------

local floor = math.floor
local abs = math.abs

local function OffsetToCube(col, row)
    local q = col - (row - (row % 2)) / 2
    return q, -q - row, row
end

local function CubeToOffset(x, z)
    local row = z
    return x + (row - (row % 2)) / 2, row
end

local function CubeRound(x, y, z)
    local rx, ry, rz = floor(x + 0.5), floor(y + 0.5), floor(z + 0.5)
    local xd, yd, zd = abs(rx - x), abs(ry - y), abs(rz - z)
    if xd > yd and xd > zd then
        rx = -ry - rz
    elseif yd > zd then
        ry = -rx - rz
    else
        rz = -rx - ry
    end
    return rx, ry, rz
end

-- Nearest unwrapped copy of (toX,toY) relative to (fromX,fromY) on an X-wrapping
-- map, so a straight line can be traced across the seam.
local function NearestWrappedTo(fromX, fromY, toX, toY)
    local dx = toX - fromX
    if Map.IsWrapX() then
        local width = Map.GetGridSize()
        local half = width / 2
        if dx > half then
            dx = dx - width
        elseif dx < -half then
            dx = dx + width
        end
    end
    return fromX + dx, toY
end

-- True when every intervening tile on one candidate hex line from the viewer to
-- the target is clear. epsSign (+1/-1) selects which of the two fronting tiles a
-- diagonal step rounds toward, so callers can test both lines.
local function LineClear(vx, vy, tx, ty, clearThreshold, epsSign)
    local wx, wy = NearestWrappedTo(vx, vy, tx, ty)
    local ax, ay, az = OffsetToCube(vx, vy)
    local bx, by, bz = OffsetToCube(wx, wy)
    local n = (abs(ax - bx) + abs(ay - by) + abs(az - bz)) / 2
    if n <= 1 then return true end
    local eps = 1e-6 * epsSign
    for i = 1, n - 1 do
        local t = i / n
        local cx = ax + (bx - ax) * t + eps
        local cy = ay + (by - ay) * t - eps
        local cz = az + (bz - az) * t
        local rx, _, rz = CubeRound(cx, cy, cz)
        local col, row = CubeToOffset(rx, rz)
        local plot = Map.GetPlot(col, row)
        if plot ~= nil and ObstructHeight(plot) >= clearThreshold then
            return false
        end
    end
    return true
end

-- Whether the viewer (height hV, at vx/vy) can see the target plot (height hT).
local function HasLineOfSight(vx, vy, hV, tp, hT)
    local clearThreshold = math.max(hT, hV + 1)
    -- Half-hidden: visible if either candidate line is clear.
    return LineClear(vx, vy, tp:GetX(), tp:GetY(), clearThreshold, 1)
        or LineClear(vx, vy, tp:GetX(), tp:GetY(), clearThreshold, -1)
end

-- ---------------------------------------------------------------------------
-- Sight computation
-- ---------------------------------------------------------------------------

local function EnsurePlayer(store, player)
    local set = store[player]
    if set == nil then
        set = {}
        store[player] = set
    end
    return set
end

-- Mark every plot the viewer at `plot` sees (radius `range`) into m_sight[player].
local function AddSightFrom(plot, range, player)
    local set = EnsurePlayer(m_sight, player)
    set[plot:GetIndex()] = true

    local vx, vy = plot:GetX(), plot:GetY()
    local hV = ViewerHeight(plot)
    local ccx, _, ccz = OffsetToCube(vx, vy)

    -- Scan one ring beyond `range` too: a taller feature (Hill/Mountain) one tile
    -- past the sight radius is still visible when it rises above the tile in front.
    local scanMax = range + 1
    for dx = -scanMax, scanMax do
        local dyMin = math.max(-scanMax, -dx - scanMax)
        local dyMax = math.min(scanMax, -dx + scanMax)
        for dy = dyMin, dyMax do
            local dz = -dx - dy
            local dist = (abs(dx) + abs(dy) + abs(dz)) / 2
            if dist >= 1 then
                local col, row = CubeToOffset(ccx + dx, ccz + dz)
                local tp = Map.GetPlot(col, row)
                if tp ~= nil then
                    if dist == 1 then
                        -- Always see immediately adjacent tiles.
                        set[tp:GetIndex()] = true
                    else
                        local hT = ObstructHeight(tp)
                        -- The extra ring only reveals tiles that stand above ground.
                        if dist <= range or hT >= 1 then
                            if HasLineOfSight(vx, vy, hV, tp, hT) then
                                set[tp:GetIndex()] = true
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Rebuild m_sight from every unit and city currently on the map.
local function RecomputeAllSight()
    m_sight = {}
    if Map == nil or Map.GetPlotCount == nil then return end

    local count = Map.GetPlotCount()
    for i = 0, count - 1 do
        local plot = Map.GetPlotByIndex(i)
        if plot ~= nil then
            local units = Units.GetUnitsInPlot(plot)
            if units ~= nil then
                for _, unit in ipairs(units) do
                    local owner = unit:GetOwner()
                    if owner ~= nil and owner >= 0 then
                        AddSightFrom(plot, UnitSightRange(unit), owner)
                    end
                end
            end
            if plot:IsCity() then
                local owner = plot:GetOwner()
                if owner ~= nil and owner >= 0 then
                    AddSightFrom(plot, CITY_SIGHT_RANGE, owner)
                end
            end
        end
    end
end

-- Only touch state while the World Builder is active.
local function WBActive()
    return WorldBuilder ~= nil and WorldBuilder.IsActive()
end

-- ---------------------------------------------------------------------------
-- Public API (dot-style; called cross-context via ExposedMembers)
-- ---------------------------------------------------------------------------

-- Seed the persistent revealed set from the loaded .Civ6Map's RevealedPlots
-- table, then compute sight from current placements. path may be nil (a fresh
-- map, or a map whose path was not captured) -- the base set is then empty and
-- reveal comes purely from the Set Visibility tool and placed-unit sight.
function VisManager.Seed(path)
    m_base = {}
    m_tallDistricts = nil

    if path ~= nil and path ~= "" then
        local api = ExposedMembers.CAI
        if api and api.OpenDatabase and api.Query and api.CloseDatabase then
            local seeded = 0
            local ok, err = pcall(function()
                local handle, openErr = api.OpenDatabase(path)
                if not handle then
                    print("CAI WBVis: could not open '" .. tostring(path) .. "': " .. tostring(openErr))
                    return
                end
                local result = api.Query(handle, "SELECT ID, Player FROM RevealedPlots", {})
                api.CloseDatabase(handle)
                -- The DLL returns the rows in the result's array part, one table
                -- per row keyed by column name (ID, Player). ipairs walks only the
                -- rows; the columns/changed/lastInsertRowId fields are string keys.
                if type(result) == "table" then
                    for _, row in ipairs(result) do
                        local id = row.ID
                        local player = row.Player
                        if id ~= nil and player ~= nil then
                            EnsurePlayer(m_base, player)[id] = true
                            seeded = seeded + 1
                        end
                    end
                end
            end)
            if ok then
                print("CAI WBVis: seeded " .. tostring(seeded) .. " revealed rows from '" .. tostring(path) .. "'")
            else
                print("CAI WBVis: seed exception on '" .. tostring(path) .. "': " .. tostring(err))
            end
        else
            print("CAI WBVis: SQLite bridge unavailable (DLL too old); reveal snapshot empty")
        end
    end

    RecomputeAllSight()
end

-- Clear all state (session teardown).
function VisManager.Reset()
    m_base = {}
    m_sight = {}
    m_tallDistricts = nil
end

-- True when the plot is revealed for the player (seeded/manual base OR sighted).
function VisManager.IsRevealed(player, plotIndex)
    if player == nil or plotIndex == nil then return false end
    local base = m_base[player]
    if base ~= nil and base[plotIndex] then return true end
    local sight = m_sight[player]
    return sight ~= nil and sight[plotIndex] == true
end

-- True when the plot is currently sighted by one of the player's placements. In
-- the World Builder there is no fog memory, so consumers treat revealed and
-- visible alike; this is exposed for completeness.
function VisManager.IsVisible(player, plotIndex)
    if player == nil or plotIndex == nil then return false end
    local sight = m_sight[player]
    return sight ~= nil and sight[plotIndex] == true
end

-- Set (or clear) a single plot's manual reveal for a player. Mirrors the Set
-- Visibility tool's add (reveal) / remove (hide) on the cursor or locked tile.
function VisManager.SetRevealed(player, plotIndex, revealed)
    if player == nil or plotIndex == nil then return end
    local base = EnsurePlayer(m_base, player)
    base[plotIndex] = revealed and true or nil
end

-- Reveal (or hide) the whole map for a player. Mirrors the Reveal All button.
function VisManager.SetRevealedAll(player, revealed)
    if player == nil then return end
    if not revealed then
        m_base[player] = {}
        return
    end
    local base = EnsurePlayer(m_base, player)
    local count = Map.GetPlotCount()
    for i = 0, count - 1 do
        base[i] = true
    end
end

-- Force a sight recompute (exposed for callers that change placements outside
-- the map events, e.g. the player editor's add/remove city).
function VisManager.RecomputeSight()
    if not WBActive() then return end
    RecomputeAllSight()
end

-- ---------------------------------------------------------------------------
-- Live placement tracking: recompute sight when units/cities change.
-- ---------------------------------------------------------------------------

local function OnPlacementChanged()
    if not WBActive() then return end
    RecomputeAllSight()
end

Events.UnitAddedToMap.Add(OnPlacementChanged)
Events.UnitRemovedFromMap.Add(OnPlacementChanged)
Events.UnitMoved.Add(OnPlacementChanged)
Events.UnitTeleported.Add(OnPlacementChanged)
Events.CityAddedToMap.Add(OnPlacementChanged)
Events.CityRemovedFromMap.Add(OnPlacementChanged)

-- Publish fresh each session per the ExposedMembers reload-staleness rule.
ExposedMembers.CAI_WBVisManager = VisManager

return VisManager
