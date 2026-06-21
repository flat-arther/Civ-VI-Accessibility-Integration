CAICursor = CAICursor or {
    curX = 0,
    curY = 0,
    lastOwnerZone = nil,
    lastContinentZone = nil,
    lastTerritoryZone = nil,
    lastVolcanoZone = nil,
    lastNationalParkZone = nil,
}

local HexCoordUtils = nil

local function GetHexCoordUtils()
    if HexCoordUtils == nil then
        include("hexCoordUtils_CAI")
        HexCoordUtils = CAIHexCoordUtils
    end

    return HexCoordUtils
end

local function ResolvePlotById(plotId)
    if plotId == nil or plotId < 0 or not Map.IsPlot(plotId) then
        return nil
    end

    return Map.GetPlotByIndex(plotId)
end

-- =========================================================================
-- Zone helpers (compare-and-speak-on-change)
-- =========================================================================

---@param plot Plot|nil
---@return string|nil
local function GetContinentZoneText(plot)
    if plot == nil then
        return nil
    end

    local continentIndex = plot:GetContinentType()
    if continentIndex == nil or continentIndex < 0 then
        return nil
    end

    local continent = GameInfo.Continents[continentIndex]
    if continent == nil or continent.Description == nil then
        return nil
    end

    return Locale.Lookup("LOC_CAI_NAV_CURSOR_CONTINENT_ZONE", continent.Description)
end

---@param plot Plot|nil
---@return string|nil
local function GetOwnerZoneText(plot)
    if plot == nil then
        return nil
    end

    local ownerID = plot:GetOwner()
    if ownerID == nil or ownerID < 0 then
        return Locale.Lookup("LOC_MINIMAP_UNCLAIMED_TOOLTIP")
    end

    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == nil or localPlayerID < 0 then
        return nil
    end

    local localPlayer = Players[localPlayerID]
    if localPlayer == nil then
        return nil
    end

    local diplomacy = localPlayer:GetDiplomacy()
    if diplomacy ~= nil and ownerID ~= localPlayerID and not diplomacy:HasMet(ownerID) then
        return nil
    end

    local playerConfig = PlayerConfigurations[ownerID]
    if playerConfig == nil then
        return nil
    end

    local civName = playerConfig:GetCivilizationShortDescription()
    if civName == nil or civName == "" then
        return nil
    end

    return Locale.Lookup(civName)
end

---@param plot Plot|nil
---@return string|nil
local function GetTerritoryZoneText(plot)
    if plot == nil or not IsExpansion2Active() then
        return nil
    end

    if Territories == nil or Territories.GetTerritoryAt == nil then
        return nil
    end

    local territory = Territories.GetTerritoryAt(plot:GetIndex())
    if territory == nil then
        return nil
    end

    local name = territory:GetName()
    if name == nil or name == "" then
        return nil
    end

    return Locale.Lookup("LOC_CAI_NAV_CURSOR_TERRITORY_ZONE", name)
end

---@param plot Plot|nil
---@return string|nil
local function GetVolcanoZoneText(plot)
    if plot == nil or not IsExpansion2Active() then
        return nil
    end

    if MapFeatureManager == nil or MapFeatureManager.GetVolcanoName == nil then
        return nil
    end

    local name = MapFeatureManager.GetVolcanoName(plot)
    if name == nil or name == "" then
        return nil
    end

    return Locale.Lookup("LOC_CAI_NAV_CURSOR_VOLCANO_ZONE", name)
end

---@param plot Plot|nil
---@return string|nil
local function GetNationalParkZoneText(plot)
    if plot == nil then
        return nil
    end

    local nationalParks = Game.GetNationalParks()
    if nationalParks == nil or nationalParks.IsNationalPark == nil then
        return nil
    end

    if not nationalParks:IsNationalPark(plot:GetIndex()) then
        return nil
    end

    return Locale.Lookup("LOC_CAI_NAV_CURSOR_NATIONAL_PARK_ZONE")
end

---@param plot Plot|nil
---@return boolean
local function CanUpdateZonesForPlot(plot)
    if plot == nil then
        return false
    end

    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == nil or localPlayerID < 0 then
        return false
    end

    local visibility = PlayersVisibility[localPlayerID]
    if visibility == nil then
        return false
    end

    return visibility:IsVisible(plot:GetIndex()) or visibility:IsRevealed(plot)
end

-- =========================================================================
-- Direction speech
-- =========================================================================

local function SpeakMoveDirection(fromX, fromY, toX, toY)
    local hexUtils = GetHexCoordUtils()
    if hexUtils == nil or hexUtils.directionString == nil then
        return
    end

    local directionText = hexUtils.directionString(fromX, fromY, toX, toY)
    if directionText == nil or directionText == "" then
        directionText = Locale.Lookup("LOC_CAI_HERE")
    end

    Speak(directionText)
end

-- =========================================================================
-- Core methods
-- =========================================================================

function CAICursor:UpdateZones()
    local plotId = self:GetPlotId()
    if plotId == nil or plotId < 0 then
        return
    end

    local plot = Map.GetPlotByIndex(plotId)
    if plot == nil then
        return
    end

    if not CanUpdateZonesForPlot(plot) then
        return
    end

    local continentZone = GetContinentZoneText(plot)
    if continentZone ~= nil and continentZone ~= self.lastContinentZone then
        Speak(continentZone)
    end
    self.lastContinentZone = continentZone

    local ownerZone = GetOwnerZoneText(plot)
    if ownerZone ~= nil and ownerZone ~= self.lastOwnerZone then
        Speak(ownerZone)
    end
    self.lastOwnerZone = ownerZone

    local territoryZone = GetTerritoryZoneText(plot)
    if territoryZone ~= nil and territoryZone ~= self.lastTerritoryZone then
        Speak(territoryZone)
    end
    self.lastTerritoryZone = territoryZone

    local volcanoZone = GetVolcanoZoneText(plot)
    if volcanoZone ~= nil and volcanoZone ~= self.lastVolcanoZone then
        Speak(volcanoZone)
    end
    self.lastVolcanoZone = volcanoZone

    local nationalParkZone = GetNationalParkZoneText(plot)
    if nationalParkZone ~= nil and nationalParkZone ~= self.lastNationalParkZone then
        Speak(nationalParkZone)
    end
    self.lastNationalParkZone = nationalParkZone
end

function CAICursor:SetCoords(x, y)
    if x == nil or y == nil then
        print("CAI cursor move requested with nil coordinates")
        return false
    end

    local plot = Map.GetPlot(x, y)
    if plot == nil then
        print("CAI cursor unable to resolve plot at coordinates: " .. tostring(x) .. ", " .. tostring(y))
        return false
    end

    self.curX = plot:GetX()
    self.curY = plot:GetY()
    return true
end

function CAICursor:GetPlotId()
    local plot = Map.GetPlot(self.curX, self.curY)
    if plot == nil then
        return -1
    end

    return plot:GetIndex()
end

---@param plotId integer
---@param reason string "step"|"jump"|"select"|"snap"
function CAICursor:MoveTo(plotId, reason)
    local plot = ResolvePlotById(plotId)
    if plot == nil then
        print("CAI cursor MoveTo unable to resolve plot id: " .. tostring(plotId))
        return
    end

    local fromX = self.curX
    local fromY = self.curY
    local fromPlotId = self:GetPlotId()

    local toX = plot:GetX()
    local toY = plot:GetY()

    local moved = self:SetCoords(toX, toY)
    if not moved then
        return
    end

    local hexUtils = GetHexCoordUtils()
    local distance = hexUtils.cubeDistance(fromX, fromY, toX, toY)
    local resolvedReason = reason or "jump"

    if resolvedReason == "jump" or resolvedReason == "select" then
        SpeakMoveDirection(fromX, fromY, toX, toY)
    end

    self:UpdateZones()

    LuaEvents.CAICursorMoved({
        fromPlotId = fromPlotId,
        toPlotId = plotId,
        distance = distance,
        fromX = fromX,
        fromY = fromY,
        toX = toX,
        toY = toY,
        reason = reason or "jump",
    })
end

function CAICursor:MoveDirection(dir)
    local plot = Map.GetAdjacentPlot(self.curX, self.curY, dir)
    if plot ~= nil then
        self:MoveTo(plot:GetIndex(), "step")
    end
end

-- =========================================================================
-- Public LuaEvent listeners
-- =========================================================================

LuaEvents.CAICursorMoveTo.Add(function(plotId, reason)
    CAICursor:MoveTo(plotId, reason)
end)

LuaEvents.CAICursorMoveDirection.Add(function(direction)
    CAICursor:MoveDirection(direction)
end)

ExposedMembers.CAICursor = CAICursor
