-- ===========================================================================
--  WorldBuilderLaunchBar_CAI
--  Speaks the World Builder status line. Vanilla writes every placement result
--  ("Ocean placed", "Wonder too close", "Requires higher tech", "Undo", ...) to
--  Controls.StatusLine via OnSetPlacementStatus; that post-action reason text is
--  the only place the reason exists (PlacementValid gives a boolean, never the
--  why). We wrap that handler: run the vanilla update, then read the rendered
--  control text and speak it.
-- ===========================================================================

include("caiUtils")
include("WorldBuilderLaunchBar")

-- Collapse repeats within a single placement: a brush stroke drives many
-- identical status updates in one keypress (vanilla WorldBuilderPlacement
-- OnPlotSelected loops PlacementFunc over 7/19 ring hexes, and each PlacementFunc
-- fires WorldBuilder_SetPlacementStatus), and queued duplicate speech would be
-- noise, so identical text is spoken once until the de-dupe is reset.
--
-- CONTRACT: the de-dupe is scoped to a SINGLE user action. Any CAI code path that
-- provokes a status line for a NEW, distinct user action must fire
-- LuaEvents.CAIWorldBuilderStatusBurstBegin() first to reset m_lastStatus, or a
-- repeat of the previous line is silently swallowed. Current callers that do this:
--   * WorldInput_CAI WBEditCursorPlot  - once per place/delete keypress
--   * WorldInput_CAI WBUndoRedo         - once per Ctrl+Z / Ctrl+Y keypress
--   * WorldBuilderMapEditor_CAI edit fields - once per Enter commit (Reference
--     Map / Alpha statuses)
-- Add the reset to any future path that can re-emit an identical status line.
local m_lastStatus = nil

LuaEvents.CAIWorldBuilderStatusBurstBegin.Add(function()
	m_lastStatus = nil
end)

-- The base already registered the original OnSetPlacementStatus during its
-- Initialize() (run while including it above), so swap that listener for the
-- wrapped one: remove the original (the global still points at it here), wrap,
-- and re-add.
LuaEvents.WorldBuilder_SetPlacementStatus.Remove(OnSetPlacementStatus)

OnSetPlacementStatus = WrapFunc(OnSetPlacementStatus, function(orig, status)
	orig(status)
	local text = Controls.StatusLine:GetText()
	if text ~= nil and text ~= "" and text ~= m_lastStatus then
		m_lastStatus = text
		Speak(text)
	end
end)

LuaEvents.WorldBuilder_SetPlacementStatus.Add(OnSetPlacementStatus)

-- F1 opens the Map Editor and F2 opens the Player Editor (the same paths as the
-- launch bar's buttons). The World Builder map interface widget (WorldInput_CAI)
-- owns those key bindings and forwards the intent here through these events, so
-- the shortcuts fire only while that widget is focused and stay inert inside any
-- pushed CAI panel/screen. This context owns the vanilla editor panels/globals.
LuaEvents.CAIWorldBuilderMapEditor_Toggle.Add(OnOpenMapEditor)
LuaEvents.CAIWorldBuilderPlayerEditor_Toggle.Add(OnOpenPlayerEditor)
