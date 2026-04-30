include("InGamePopup")

local mgr = ExposedMembers.CAI_UIManager

InputHandler = WrapFunc(InputHandler, function(orig, input)
    if mgr and mgr:HandleInput(input) then
        return true
    end

    return orig(input:GetMessageType(), input:GetKey(), nil)
end)

ContextPtr:SetInputHandler(InputHandler, true)
