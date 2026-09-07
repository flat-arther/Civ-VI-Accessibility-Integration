-- ===========================================================================
--  WorldBuilderMapTools_CAI
--  The Map Tools host holds the two-tab engine Tab (Placement / Plot Editor).
--  Only this context can reach the SelectTab_* buttons, so it exposes a tiny
--  cross-context bridge: the Plot Editor CAI raises CAIWorldBuilderSelectTab to
--  switch tabs (F3 -> Plot Editor, Escape -> Placement). Clicking the tab button
--  drives the engine Tab exactly as a mouse click would, firing the target
--  context's show/hide handlers (which the Plot Editor CAI hangs its open/close
--  on). The base Initialize() runs during this include; adding the listener
--  afterward is all that is needed.
-- ===========================================================================

include("caiUtils")
include("WorldBuilderMapTools")

LuaEvents.CAIWorldBuilderSelectTab.Add(function(which)
    if which == "PlotEditor" then
        Controls.SelectTab_WorldBuilderPlotEditor:DoLeftClick()
    else
        Controls.SelectTab_WorldBuilderPlacement:DoLeftClick()
    end
end)
