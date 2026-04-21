include("FrontEnd_Base")
include("caiUtils")
local mgr = ExposedMembers.CAI_UIManager


	ContextPtr:SetInputHandler(function(input)
        return mgr:HandleInput(input)
end, true)