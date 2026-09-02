-- ===========================================================================
--  WorldBuilderToolsPalette_CAI
--  The vanilla tools palette installs an input handler that maps the number/
--  letter keys (1-0, B, U, R, S, O, V) to tool selection and drives the
--  Basic/Advanced confirm popup. Those hotkeys collide with normal typing and
--  navigation in the CAI tools panel (e.g. typing a resource amount would also
--  trigger a tool hotkey on key-up). Wrap that handler to a no-op and
--  re-register it so the palette no longer consumes keys; CAI drives tool
--  changes directly through OnToolSelectMode.
--
--  Vanilla WorldBuilderToolsPalette.lua calls Initialize() during this include,
--  which registers the original OnInputHandler, so we override it afterward.
--
--  CAI firm decision: always run World Builder in Advanced mode. Basic/Advanced
--  is pure UI gating and Advanced is a strict superset, so forcing it gives one
--  code path with every tool present. Crucially it also fixes the improvements
--  tool: in Basic mode that slot IS the Goody Huts tool (PlacementFunc =
--  PlaceGoodyHut), so any "improvement" chosen would place a tribal village.
--  Vanilla Initialize() ran SetAdvancedMode(false) during the include above, so
--  we flip it to Advanced afterward; SetAdvancedMode fires WorldBuilder_ModeChanged
--  so the placement/plot-editor contexts repopulate with the full lists.
-- ===========================================================================

include("caiUtils")
include("WorldBuilderToolsPalette")

OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
    return false
end)

ContextPtr:SetInputHandler(OnInputHandler, true)

if not WorldBuilder.GetWBAdvancedMode() then
    SetAdvancedMode(true)
end
