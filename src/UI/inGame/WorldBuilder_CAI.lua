-- ===========================================================================
--  WorldBuilder_CAI
--  The vanilla World Builder root context installs an input handler
--  (undo/redo and menu hotkeys via DefaultMessageHandler) that consumes keys
--  before they can reach the CAI manager. Wrap that handler to a no-op and
--  re-register it so all World Builder input flows through WorldInput_CAI into
--  the manager instead. (Undo/redo and the pause menu will be re-exposed
--  through CAI separately.)
--
--  Vanilla WorldBuilder.lua calls Initialize() during this include, which is
--  where it registers the original InputHandler, so we override that
--  registration afterward.
-- ===========================================================================

include("caiUtils")
include("WorldBuilder")

InputHandler = WrapFunc(InputHandler, function(orig, pInputStruct)
    return false
end)

ContextPtr:SetInputHandler(InputHandler, true)
