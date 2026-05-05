include("InGamePopup")
include("Civ6Common")

local mgr = ExposedMembers.CAI_UIManager

OnPopupOpen = WrapFunc(OnPopupOpen, function(orig, uniqueStringName, options)
    orig(uniqueStringName, options)
    if IsTutorialRunning() then
        UITutorialManager:AddControlToAlwaysReceiveInput(ContextPtr)
    end
end)

OnClosePopup = WrapFunc(OnClosePopup, function(orig)
    orig()
    if IsTutorialRunning() then
        UITutorialManager:RemoveControlToAlwaysReceiveInput(ContextPtr)
    end
end)
InputHandler = WrapFunc(InputHandler, function(orig, input)
    if mgr and mgr:HandleInput(input) then
        return true
    end

    return orig(input:GetMessageType(), input:GetKey(), nil)
end)

ContextPtr:SetInputHandler(InputHandler, true)
