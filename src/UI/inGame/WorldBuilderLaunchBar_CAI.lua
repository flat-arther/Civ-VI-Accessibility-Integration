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
-- identical status updates in one keypress, and queued duplicate speech would be
-- noise. WorldInput_CAI fires CAIWorldBuilderStatusBurstBegin at the start of
-- each place/delete keypress so the de-dupe resets and a repeated identical
-- result (e.g. pressing Enter twice on the same failure) still speaks each time.
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

-- F1 opens the Map Editor (the same path as the launch bar's Map Editor button),
-- but only while the World Builder map interface is the focused widget so it
-- never fires from inside a pushed CAI panel/screen. The base launch bar has no
-- input handler, so this is the only one on the context.
ContextPtr:SetInputHandler(function(pInputStruct)
	if pInputStruct:GetMessageType() == KeyEvents.KeyUp
		and pInputStruct:GetKey() == Keys.VK_F1
		and mgr ~= nil then
		local focused = mgr:GetFocusedWidget()
		if focused ~= nil and focused:GetId() == WB_INTERFACE_ID then
			OnOpenMapEditor()
			return true
		end
	end
	return false
end, true)
