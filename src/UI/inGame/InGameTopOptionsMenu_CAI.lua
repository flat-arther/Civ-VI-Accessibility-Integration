include ("caiUtils")
include("InGameTopOptionsMenu")
local mgr = ExposedMembers.CAI_UIManager
OnInput = WrapFunc(OnInput, function(orig, input)
	if mgr then
		mgr:HandleInput(input)
	end
	return orig(input)
end)
-- reset input handler
ContextPtr:SetInputHandler(OnInput, true)