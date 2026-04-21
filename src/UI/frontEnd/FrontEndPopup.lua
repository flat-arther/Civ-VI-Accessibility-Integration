include("FrontEndPopup_Base")
include ("caiUtils")
local mgr = ExposedMembers.CAI_UIManager
---Mainly here to set the input handler for frontend popups, since popup dialogs don't necessarily have their own context. 
---Note that the original input handler has been updated to use the newer InputStruct system. See 'InputHandler' in the base file
Initialize = WrapFunc(Initialize, function(orig)
	orig()
	ContextPtr:SetInputHandler(function(input)
		local handled = mgr:HandleInput(input)
		if not handled then
			return InputHandler(input)
		end
		return handled
	end, true)
end)

-- We wrap this one as well since for some reason they call it instead of simply using the regular ClosePopup
OnPopupClose = WrapFunc(OnPopupClose, function(orig)
	orig()
        mgr:Pop()
end)
Initialize();