include("caiUtils")
include("PBCNotificationPopup")
local mgr = ExposedMembers.CAI_UIManager
-- Not needed for any UI accessibility integration, that is already handled by popup dialog. However, we still need to set an input handler

function OnInputHandler(pInputStruct)
    if mgr and not ContextPtr:IsHidden() then
        if mgr:HandleInput(pInputStruct) then return true end
    end
    return false
end

ContextPtr:SetInputHandler(OnInputHandler, true)
