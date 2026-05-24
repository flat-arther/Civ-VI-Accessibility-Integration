CAICursor = CAICursor or {
    curX = 0,
    curY = 0,
    lastOwnerZone = nil,
    lastContinentZone = nil
}

local HexCoordUtils = nil

local function GetHexCoordUtils()
    if HexCoordUtils == nil then
        include("hexCoordUtils_CAI")
        HexCoordUtils = CAIHexCoordUtils
    end

    return HexCoordUtils
end

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

local function ResolvePlotById(plotId)
    if plotId == nil or plotId < 0 or not Map.IsPlot(plotId) then
        return nil
    end

    return Map.GetPlotByIndex(plotId)
end

local function SpeakJumpDirection(fromX, fromY, targetPlot)
    if fromX == nil or fromY == nil or targetPlot == nil then
        return
    end

    local hexUtils = GetHexCoordUtils()
    if hexUtils == nil or hexUtils.directionString == nil then
        return
    end

    local directionText = hexUtils.directionString(fromX, fromY, targetPlot:GetX(), targetPlot:GetY())
    if directionText == nil or directionText == "" then
        directionText = Locale.Lookup("LOC_CAI_HERE")
    end

    Speak(directionText)
end

--# Methods
function CAICursor:UpdateZones()
    local plotId = self:GetPlotId()
    if plotId == nil or plotId < 0 then
        return
    end

    local plot = Map.GetPlotByIndex(plotId)
    if plot == nil then
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
    self:UpdateZones()
    return true
end

function CAICursor:SetPlotId(plotId)
    local plot = ResolvePlotById(plotId)
    if plot == nil then
        print("CAI cursor unable to resolve plot id: " .. tostring(plotId))
        return
    end

    self:SetCoords(plot:GetX(), plot:GetY())
end

function CAICursor:MoveToNextPlot(dir)
    local plot = Map.GetAdjacentPlot(self.curX, self.curY, dir)
    if plot ~= nil then
        local moved = self:SetCoords(plot:GetX(), plot:GetY())
        if moved then
            LuaEvents.CAICursorMoved(self.curX, self.curY, plot:GetIndex())
        end
    end
end

function CAICursor:JumpToPlotId(plotId, suppressEvent)
    local plot = ResolvePlotById(plotId)
    if plot == nil then
        print("CAI cursor jump unable to resolve plot id: " .. tostring(plotId))
        return
    end

    local fromX = self.curX
    local fromY = self.curY
    SpeakJumpDirection(fromX, fromY, plot)

    local moved = self:SetCoords(plot:GetX(), plot:GetY())
    if moved and not suppressEvent then
        LuaEvents.CAICursorMoved(self.curX, self.curY, plot:GetIndex())
    end
end

function CAICursor:SnapToStartPlot()
    local playerID = Game.GetLocalPlayer()
    if playerID == nil or playerID < 0 then
        print("CAI cursor unable to find local player")
        return
    end

    local playerConfig = PlayerConfigurations[playerID]
    local location = playerConfig ~= nil and playerConfig:GetStartingPosition() or nil
    if location ~= nil then
        self:SetCoords(location.x, location.y)
    end
end

function CAICursor:SnapToPlot(plotId)
    self:SetPlotId(plotId)
end

function CAICursor:GetPlotId()
    local plot = Map.GetPlot(self.curX, self.curY)
    if plot == nil then
        return -1
    end

    return plot:GetIndex()
end

LuaEvents.CAICursorMove.Add(function(x, y)
    local moved = CAICursor:SetCoords(x, y)
    if moved then
        LuaEvents.CAICursorMoved(CAICursor.curX, CAICursor.curY, CAICursor:GetPlotId())
    end
end)

LuaEvents.CAICursorMoveDirection.Add(function(direction)
    CAICursor:MoveToNextPlot(direction)
end)

LuaEvents.CAICursorJump.Add(function(plotId, suppressEvent)
    CAICursor:JumpToPlotId(plotId, suppressEvent)
end)

LuaEvents.CAICursorSnapToStartPlot.Add(function()
    CAICursor:SnapToStartPlot()
end)

ExposedMembers.CAICursor = CAICursor
