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

local mgr = ExposedMembers.CAI_UIManager

-- Static id of the World Builder map interface widget (created in WorldInput_CAI).
-- F1 opens the Map Editor only while that widget is the focused one, so the
-- shortcut is inert whenever focus is inside any pushed CAI screen/panel.
local WB_INTERFACE_ID = "CAIWorldBuilderMode"

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
-- launch bar's buttons), but only while the World Builder map interface is the
-- focused widget so neither fires from inside a pushed CAI panel/screen. The base
-- launch bar has no input handler, so this is the only one on the context.
ContextPtr:SetInputHandler(function(pInputStruct)
	if pInputStruct:GetMessageType() == KeyEvents.KeyUp and mgr ~= nil then
		local key = pInputStruct:GetKey()
		if key == Keys.VK_F1 or key == Keys.VK_F2 then
			local focused = mgr:GetFocusedWidget()
			if focused ~= nil and focused:GetId() == WB_INTERFACE_ID then
				if key == Keys.VK_F1 then
					OnOpenMapEditor()
				else
					OnOpenPlayerEditor()
				end
				return true
			end
		end
	end
	return false
end, true)
