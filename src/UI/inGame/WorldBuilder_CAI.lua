-- ===========================================================================
--  WorldBuilder_CAI
--  Replaces the vanilla World Builder root context. Its input handler is a
--  no-op (returns false) so all World Builder input flows through
--  WorldInput_CAI into the CAI manager instead of the vanilla undo/redo/menu
--  key handling, which otherwise fought the CAI menu during the pause handoff.
--
--  Opening the pause / in-game menu still has to happen from THIS context,
--  because Controls.TopOptionsMenu (the InGameTopOptionsMenu child) lives in
--  the World Builder XML and is only reachable here. Vanilla did this in its
--  own OnOpenInGameMenu, registered on WorldBuilderLaunchBar_OpenInGameMenu;
--  since that vanilla handler is gone, re-add a listener that queues the popup.
--  Both the launch bar's Menu button and WorldInput_CAI's Escape binding raise
--  that same event, so this one listener serves both.
--
--  The Map Editor (F1 / launch-bar button) and Player Editor (F2 / button)
--  route the same way: the launch bar fires WorldBuilderLaunchBar_OpenMapEditor
--  / _OpenPlayerEditor, and vanilla WorldBuilder.lua's own OnOpen* listeners
--  translated those into WorldBuilder_ShowMapEditor / _ShowPlayerEditor (the
--  events the CAI editor panels open on). Replacing this context dropped those
--  listeners, so F1/F2 opened nothing; re-add them here, mirroring vanilla
--  (toggle off the vanilla editor control's hidden state, which CAI never shows,
--  so this always requests "show" and the CAI panel's own guard ignores repeats).
-- ===========================================================================

ContextPtr:SetInputHandler(function(pInputStruct) return false end, true)

LuaEvents.WorldBuilderLaunchBar_OpenInGameMenu.Add(function()
	UIManager:QueuePopup(Controls.TopOptionsMenu, PopupPriority.Utmost)
end)

LuaEvents.WorldBuilderLaunchBar_OpenMapEditor.Add(function()
	LuaEvents.WorldBuilder_ShowMapEditor(Controls.WorldBuilderMapEditor:IsHidden())
end)

LuaEvents.WorldBuilderLaunchBar_OpenPlayerEditor.Add(function()
	LuaEvents.WorldBuilder_ShowPlayerEditor(Controls.WorldBuilderPlayerEditor:IsHidden())
end)
