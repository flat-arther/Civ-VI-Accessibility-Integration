include("IntroScreen_Base")
include ("caiUtils")
include("UIScreenManager")
local mgr             = ExposedMembers.CAI_UIManager

-- This context does not have a vanilla 'OnShutdown' function, so we add one to kill the UI manager
function OnShutdown()
	mgr:ShutDown()
end
ContextPtr:SetShutdown( OnShutdown );
AcceptEULA();
