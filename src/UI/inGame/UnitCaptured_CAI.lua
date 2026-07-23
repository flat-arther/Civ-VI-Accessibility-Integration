include("caiUtils")
include("UnitCaptured")

local mgr = ExposedMembers.CAI_UIManager

local function OnInputHandler(input)
    if mgr and mgr:HandleInput(input) then
        return true
    end
    return false
end

ContextPtr:SetInputHandler(OnInputHandler, true)

local function OnLocalPlayerCapturedUnit(currentUnitOwner, _unitID, _owningPlayer, capturingPlayer)
    local localPlayerID = Game.GetLocalPlayer()
    if capturingPlayer ~= localPlayerID or currentUnitOwner == localPlayerID then return end

    local previousOwnerConfig = PlayerConfigurations[currentUnitOwner]
    if previousOwnerConfig == nil then
        LogWarn("UnitCaptured: missing player configuration for previous owner " .. tostring(currentUnitOwner))
        return
    end

    local previousOwnerName = previousOwnerConfig:GetCivilizationShortDescription()
    local message = Locale.Lookup("LOC_CAPTURE_UNIT", previousOwnerName)
    LuaEvents.CAIAppendToMessageBuffer(message, "notification")
end

if GameConfiguration.IsAnyMultiplayer() then
    Events.UnitCaptured.Add(OnLocalPlayerCapturedUnit)
end
