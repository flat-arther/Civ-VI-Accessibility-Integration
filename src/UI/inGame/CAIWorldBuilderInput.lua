-- World Builder editing state and UI. WorldInput owns events and update order.
include("textProcessing")
CAIWorldBuilderInput = {}

---@param mgr UIScreenManager
---@param adapter CAIWorldBuilderInputAdapter
---@return CAIWorldBuilderInputController
function CAIWorldBuilderInput.Create(mgr, adapter)
	local m_wbMarkedPlotId = nil
	local m_wbBrushLocked = false
	local m_caiWorldBuilderWidget = nil

	local function WBPlacementSourcePlot()
		if m_wbMarkedPlotId ~= nil and Map.IsPlot(m_wbMarkedPlotId) then
			return m_wbMarkedPlotId
		end
		return adapter.GetPlotId()
	end

	-- The locked World Builder placement plot (the marked tile), or nil when no tile
	-- is locked. Only a locked tile drives the footprint listing, so the cursor can
	-- roam to inspect tiles without it following. Published on the shared CAIInfo
	-- table so cross-context consumers can read it (the plot tooltip's placement
	-- readout runs in the PlotToolTip context, not here), and kept as a global for
	-- the same-context Valid Targets scanner category.
	local function GetWorldBuilderMarkedPlot()
		if m_wbMarkedPlotId ~= nil and Map.IsPlot(m_wbMarkedPlotId) then
			return m_wbMarkedPlotId
		end
		return nil
	end

	-- Refresh the scanner's Valid Targets category so a parked view updates after the
	-- mark toggles or a placement changes tile validity. A no-op when the scanner has
	-- no active state; navigating to the category always rescans regardless.
	local function RefreshValidTargetsScanner()
		local scanner = adapter.GetScanner()
		if scanner ~= nil and scanner:GetActiveState() ~= nil then
			scanner:RebuildCategory("validTargets")
		end
	end

	-- World Builder ownership writes finish after the placement callback returns,
	-- and the editor does not reliably emit CityTileOwnershipChanged. Its localized
	-- success statuses are the stable completion signal; rebuild sight on the next
	-- update tick, when the live plot owner is queryable. This also covers native
	-- mouse use of the Owner tool because both paths publish the same status event.
	local m_wbSightRefreshPending = false
	local WB_OWNERSHIP_SET_STATUS = Locale.Lookup("LOC_WORLDBUILDER_OWNERSHIP_SET")
	local WB_OWNERSHIP_REMOVED_STATUS = Locale.Lookup("LOC_WORLDBUILDER_OWNERSHIP_REMOVED")

	local function OnWorldBuilderPlacementStatus(status)
		if WorldBuilder.IsActive()
			and (status == WB_OWNERSHIP_SET_STATUS or status == WB_OWNERSHIP_REMOVED_STATUS) then
			m_wbSightRefreshPending = true
		end
	end

	local function WBEditCursorPlot(bAdd, plotId)
		plotId = plotId or WBPlacementSourcePlot()
		if plotId == nil or plotId < 0 or not Map.IsPlot(plotId) then return false end

		-- New edit = new placement: reset the status-line speech de-dupe so a
		-- repeated identical result (e.g. the same failure) speaks again. Within this
		-- one keypress a brush's repeated identical statuses still collapse.
		LuaEvents.CAIWorldBuilderStatusBurstBegin()

		-- Set Visibility needs the operation's actual success result before its
		-- shadow snapshot changes. The generic vanilla event bridge does not return
		-- PlaceVisibility's SetRevealed result, so use the placement context's
		-- result-aware equivalent for this tool.
		local info = CAI:GetInfo()
		if info ~= nil and info.GetWorldBuilderVisibilityPlayer ~= nil
			and info.GetWorldBuilderVisibilityPlayer() ~= nil
			and info.EditWorldBuilderVisibility ~= nil then
			info.EditWorldBuilderVisibility(plotId, bAdd)
			RefreshValidTargetsScanner()
			return true
		end

		-- Rivers and Cliffs place on a plot edge. Vanilla derives the edge from the
		-- mouse position; CAI has no cursor edge, so the placement context exposes the
		-- direction chosen in the tools (its Direction parameter). Fall back to the
		-- cursor-nearest edge for any tool that does not publish a direction.
		local edge = UI.GetCursorNearestPlotEdge()
		if info ~= nil and info.GetWorldBuilderEdgeDirection ~= nil then
			local dir = info.GetWorldBuilderEdgeDirection()
			if dir ~= nil then edge = dir end
		end

		if bAdd then
			-- LButtonUp pair: start undo block + PlacementFunc(add), then close it.
			LuaEvents.WorldInput_WBSelectPlot(plotId, edge, true, false)
			LuaEvents.WorldInput_WBSelectPlot(plotId, edge, false, false)
		else
			-- RButtonDown/RButtonUp pair: PlacementFunc(remove) on the up event.
			LuaEvents.WorldInput_WBSelectPlot(plotId, edge, true, true)
			LuaEvents.WorldInput_WBSelectPlot(plotId, edge, false, true)
		end

		-- A placement can change which footprint tiles are valid; refresh the scanner
		-- so a parked Valid Targets view reflects the new state.
		RefreshValidTargetsScanner()
		return true
	end

	-- World Builder undo / redo (Ctrl+Z / Ctrl+Y). Mirrors vanilla WorldBuilder and
	-- WorldBuilderPlacement OnUndo / OnRedo: step the edit history and report the
	-- result through the placement status line, which CAI already speaks. Each
	-- keypress is a distinct action, so reset the status-line speech de-dupe first;
	-- otherwise a run of undos (all "Undo successful") would speak only once.
	local function WBUndoRedo(bRedo)
		LuaEvents.CAIWorldBuilderStatusBurstBegin()
		if bRedo then
			if WorldBuilder.CanRedo() then
				WorldBuilder.Redo()
				m_wbSightRefreshPending = true
				LuaEvents.WorldBuilder_SetPlacementStatus(Locale.Lookup("LOC_WORLDBUILDER_STATUS_REDO"))
			else
				LuaEvents.WorldBuilder_SetPlacementStatus(Locale.Lookup("LOC_WORLDBUILDER_STATUS_CANT_REDO"))
			end
		else
			if WorldBuilder.CanUndo() then
				WorldBuilder.Undo()
				m_wbSightRefreshPending = true
				LuaEvents.WorldBuilder_SetPlacementStatus(Locale.Lookup("LOC_WORLDBUILDER_STATUS_UNDO"))
			else
				LuaEvents.WorldBuilder_SetPlacementStatus(Locale.Lookup("LOC_WORLDBUILDER_STATUS_CANT_UNDO"))
			end
		end

		-- Undo/redo can change which footprint tiles are valid; refresh a parked scanner.
		RefreshValidTargetsScanner()
	end

	-- ===========================================================================
	-- World Builder: go-to-coordinates quick jump (Ctrl+G)
	-- ===========================================================================
	-- Ctrl+G pushes a single edit box; typing coordinates and pressing Enter moves
	-- the CAI cursor there. The first field is x, the second (after a space) is z;
	-- a leading space omits x and sets z alone. A field prefixed with + or - is a
	-- relative step from the current cursor, otherwise it is an absolute jump. Each
	-- field is classified independently, so "15 +2" jumps x to 15 and steps z by 2.
	-- Escape closes the box. The box uses the coordinate edit mode (digits, space,
	-- + and -); that enum lives in the edit-box widget's own context and globals do
	-- not cross contexts, so the numeric mode value is passed directly.
	local GOTO_EDIT_ID = "CAIWorldBuilderGoto_Edit"
	local EDIT_MODE_NUMERIC_SYMBOLS = 4 -- EditModes.NumericSymbols in CAIWidget_EditBox (enums do not cross contexts)
	local m_gotoEdit = nil
	local m_gotoTarget = nil

	-- Trim ASCII spaces/tabs from both ends. Never %s: it is locale-sensitive and
	-- corrupts UTF-8 under Simplified Chinese.
	-- Classify one coordinate field: "rel"/"abs" plus its numeric value, or nil for
	-- anything that is not a bare or signed integer.
	local function ClassifyGotoField(tok)
		if string.match(tok, "^[+-]%d+$") then return "rel", tonumber(tok) end
		if string.match(tok, "^%d+$") then return "abs", tonumber(tok) end
		return nil
	end

	-- Parse the entry into an absolute target (x, y) relative to the current cursor,
	-- or return nil plus a localized message explaining the accepted format.
	local function ParseGoto(text)
		local curX, curY = adapter.GetCursor():GetCoords()
		if curX == nil or curY == nil then
			return nil, Locale.Lookup("LOC_CAI_WB_GOTO_INVALID")
		end

		text = text or ""
		local xRaw, zRaw
		local sp = string.find(text, " ", 1, true)
		if sp ~= nil then
			xRaw = string.sub(text, 1, sp - 1)
			zRaw = string.sub(text, sp + 1)
		else
			xRaw = text
		end

		local xTok = CAIText.TrimHorizontal(xRaw)
		local zTok = CAIText.TrimHorizontal(zRaw)
		local xProvided = xTok ~= nil and xTok ~= ""
		local zProvided = zTok ~= nil and zTok ~= ""
		if not xProvided and not zProvided then
			return nil, Locale.Lookup("LOC_CAI_WB_GOTO_INVALID")
		end

		local targetX, targetY = curX, curY
		if xProvided then
			local kind, val = ClassifyGotoField(xTok)
			if kind == nil then return nil, Locale.Lookup("LOC_CAI_WB_GOTO_INVALID") end
			targetX = (kind == "rel") and (curX + val) or val
		end
		if zProvided then
			local kind, val = ClassifyGotoField(zTok)
			if kind == nil then return nil, Locale.Lookup("LOC_CAI_WB_GOTO_INVALID") end
			targetY = (kind == "rel") and (curY + val) or val
		end

		return targetX, targetY
	end

	local function CloseGotoEditor()
		if m_gotoEdit == nil then return end
		m_gotoEdit = nil
		m_gotoTarget = nil
		mgr:RemoveFromStack(GOTO_EDIT_ID)
	end

	local function OpenGotoEditor()
		if m_gotoEdit ~= nil or mgr == nil then return end

		local edit = mgr:CreateWidget(GOTO_EDIT_ID, "EditBox", {
			Label = function() return Locale.Lookup("LOC_CAI_WB_GOTO") end,
		})
		if edit == nil then return end
		edit:SetEditMode(EDIT_MODE_NUMERIC_SYMBOLS)
		edit:SetAlwaysEdit(true)
		-- Closing pops the box (which fires focus_leave); without this the box would
		-- commit a second time on the way out and jump twice.
		edit:SetCommitOnFocusLeave(false)
		-- Validate on Enter: a bad format or an out-of-bounds destination is spoken
		-- and blocks the commit so the user can correct it; a valid entry stashes the
		-- resolved plot for the value_changed handler to move to.
		edit:SetCommitValidator(function(text)
			local x, y = ParseGoto(text)
			if x == nil then return y end -- y is the localized error message
			local plot = Map.GetPlot(x, y)
			if plot == nil then return Locale.Lookup("LOC_CAI_WB_GOTO_OUT_OF_BOUNDS") end
			m_gotoTarget = plot:GetIndex()
			return nil
		end)
		edit:On("value_changed", function()
			local target = m_gotoTarget
			CloseGotoEditor()
			if target ~= nil then adapter.GetCursor():MoveTo(target, "jump") end
		end)
		edit:AddInputBindings({
			{
				Key = Keys.VK_ESCAPE,
				MSG = KeyEvents.KeyUp,
				Description = "LOC_CAI_KB_CLOSE",
				Action = function()
					CloseGotoEditor()
					return true
				end,
			},
		})

		m_gotoEdit = edit
		mgr:Push(edit)
	end

	-- Number-row order for the direct tool-select hotkeys: slots 1..10 use 1-9 then
	-- 0, slots 11..16 add Shift to 1-6. Keys["0".."9"] are the number-row digit key
	-- codes (see the input-help KEY_NAMES table); Keys.1 is not a valid identifier.
	local WB_TOOL_HOTKEY_DIGITS = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" }

	-- Direct tool-select bindings for the interface widget: the number row picks a
	-- Placement tool by its 1-based palette position without opening the tools
	-- panel. 1-9 and 0 select tools 1-10; Shift+1..Shift+6 select tools 11-16 (the
	-- palette has 16 tools). The placement context (WorldBuilderPlacement_CAI) owns
	-- the tool list, arms the chosen tool and speaks it; an out-of-range position is
	-- a no-op there. KeyDown matches the other World Builder interface keys.
	local function BuildToolSelectBindings()
		local bindings = {}
		for pos = 1, 16 do
			local shifted = pos > 10
			local digit = shifted and WB_TOOL_HOTKEY_DIGITS[pos - 10] or WB_TOOL_HOTKEY_DIGITS[pos]
			bindings[#bindings + 1] = {
				Key = Keys[digit],
				MSG = KeyEvents.KeyDown,
				IsShift = shifted,
				Description = "LOC_CAI_WB_SELECT_TOOL",
				Action = function()
					LuaEvents.CAIWorldBuilderSelectTool(pos)
					return true
				end,
			}
		end
		return bindings
	end

	-- World Builder runs in a single WB_SELECT_PLOT interface mode for its whole
	-- lifetime, so instead of the gameplay game-view root we push a dedicated
	-- interface-mode widget. Tab from it opens the accessible tools panel; the
	-- primary / secondary / delete keys place, edit and remove at the cursor plot;
	-- the number row selects tools directly.
	local function CreateWorldBuilderWidget()
		if not mgr then
			LogError("CAI WorldInput could not create World Builder widget because CAI:GetUIManager() is nil")
			return false
		end

		m_caiWorldBuilderWidget = mgr:CreateWidget("CAIWorldBuilderMode", "InterfaceMode", {
			Label = function() return Locale.Lookup("LOC_CAI_WB_MODE") end,
		})
		if not m_caiWorldBuilderWidget then
			LogError("CAI WorldInput failed to create World Builder interface widget")
			return false
		end

		m_caiWorldBuilderWidget:AddInputBindings({
			{
				Key = Keys.L,
				MSG = KeyEvents.KeyUp,
				Description = "LOC_CAI_WB_BRUSH_LOCK",
				Action = function()
					m_wbBrushLocked = not m_wbBrushLocked
					Speak(Locale.Lookup(m_wbBrushLocked and "LOC_CAI_WB_BRUSH_LOCK_ON" or "LOC_CAI_WB_BRUSH_LOCK_OFF"))
					return true
				end,
			},
			{
				Key = Keys.VK_TAB,
				MSG = KeyEvents.KeyDown,
				Description = "LOC_CAI_WB_OPEN_TOOLS",
				Action = function()
					LuaEvents.CAIWorldBuilderTools_Toggle()
					return true
				end,
			},
			-- Primary: place the armed tool's item at the cursor with the current brush.
			{
				Key = Keys.VK_RETURN,
				MSG = KeyEvents.KeyDown,
				Description = "LOC_CAI_WB_PLACE",
				Action = function()
					WBEditCursorPlot(true)
					return true
				end,
			},
			-- F3: open the single-tile Plot Editor for the source plot (marked tile
			-- if locked, else the cursor), alongside F1 (Map Editor) and F2 (Player
			-- Editor). The Plot Editor CAI answers by switching the vanilla Map Tools
			-- tab to the editor and pushing its list.
			{
				Key = Keys.VK_F3,
				MSG = KeyEvents.KeyDown,
				Description = "LOC_CAI_WB_EDIT_TILE",
				Action = function()
					local plotId = WBPlacementSourcePlot()
					if plotId ~= nil and plotId >= 0 and Map.IsPlot(plotId) then
						LuaEvents.CAIWorldBuilderPlotEditor_Toggle(plotId)
					end
					return true
				end,
			},
			-- F1 / F2: open the Map Editor and Player Editor (the launch-bar buttons).
			-- The launch-bar context owns those panels and listens for these events. As
			-- widget bindings they fire only while the World Builder map interface is the
			-- focused widget, so they stay inert inside any pushed CAI panel or screen.
			{
				Key = Keys.VK_F1,
				MSG = KeyEvents.KeyDown,
				Description = "LOC_CAI_WB_MAP_EDITOR",
				Action = function()
					LuaEvents.CAIWorldBuilderMapEditor_Toggle()
					return true
				end,
			},
			{
				Key = Keys.VK_F2,
				MSG = KeyEvents.KeyDown,
				Description = "LOC_CAI_WB_PLAYER_EDITOR",
				Action = function()
					LuaEvents.CAIWorldBuilderPlayerEditor_Toggle()
					return true
				end,
			},
			-- Ctrl+Z / Ctrl+Y: undo / redo the last World Builder edit. WorldBuilder_CAI
			-- replaces the vanilla WorldBuilder root context with a no-op input handler,
			-- so vanilla's own Ctrl+Z / Ctrl+Y handler never runs; this widget is the
			-- sole handler. KeyDown matches the other World Builder interface keys.
			{
				Key = Keys.Z,
				MSG = KeyEvents.KeyDown,
				IsControl = true,
				Description = "LOC_CAI_WB_UNDO",
				Action = function()
					WBUndoRedo(false)
					return true
				end,
			},
			{
				Key = Keys.Y,
				MSG = KeyEvents.KeyDown,
				IsControl = true,
				Description = "LOC_CAI_WB_REDO",
				Action = function()
					WBUndoRedo(true)
					return true
				end,
			},
			-- Escape: open the World Builder pause / in-game menu. WorldBuilder_CAI
			-- replaced the vanilla WorldBuilder context (whose own Escape handler opened
			-- the menu) with a no-op, so this fires the same LuaEvent the launch bar's
			-- Menu button raises; WorldBuilder_CAI listens and queues the menu popup.
			-- KeyUp (not KeyDown like the other WB keys) so the just-opened pause panel
			-- does not also receive this keypress's KeyUp and close itself immediately.
			{
				Key = Keys.VK_ESCAPE,
				MSG = KeyEvents.KeyUp,
				Description = "LOC_CAI_WB_PAUSE",
				Action = function()
					LuaEvents.InGame_OpenInGameOptionsMenu();
					return true
				end,
			},
			-- Lock / unlock the placement source to the current cursor tile, so the
			-- cursor can roam and inspect other tiles without moving where edits land.
			{
				Key = Keys.M,
				MSG = KeyEvents.KeyDown,
				Description = "LOC_CAI_WB_MARK",
				Action = function()
					if m_wbMarkedPlotId ~= nil then
						m_wbMarkedPlotId = nil
						Speak(Locale.Lookup("LOC_CAI_WB_UNMARKED"))
						RefreshValidTargetsScanner()
						return true
					end
					local plotId = adapter.GetPlotId()
					if plotId ~= nil and plotId >= 0 and Map.IsPlot(plotId) then
						m_wbMarkedPlotId = plotId
						Speak(Locale.Lookup("LOC_CAI_WB_MARKED"))
						RefreshValidTargetsScanner()
					end
					return true
				end,
			},
			-- Delete: remove the armed tool's item at the cursor. Map-pin deletion (the
			-- usual Delete binding) does not apply in World Builder.
			{
				Key = Keys.VK_DELETE,
				MSG = KeyEvents.KeyDown,
				Description = "LOC_CAI_WB_DELETE",
				Action = function()
					WBEditCursorPlot(false)
					return true
				end,
			},
			-- Ctrl+G: open the go-to-coordinates edit box (jump the cursor to typed
			-- coordinates, absolute or relative).
			{
				Key = Keys.G,
				MSG = KeyEvents.KeyDown,
				IsControl = true,
				Description = "LOC_CAI_WB_GOTO",
				Action = function()
					OpenGotoEditor()
					return true
				end,
			},
			-- Quick nav (arrow keys): change the current tool and its parameters
			-- without opening the tools panel. Left / Right move between parameters
			-- (parameter 1 is the tool, 2..N are its parameters), Up / Down change the
			-- focused parameter's value, and Shift jumps to the first / last parameter
			-- or list value. The parameter model, state and speech all live in the
			-- placement context (WorldBuilderPlacement_CAI), which owns the vanilla
			-- placement controls; these bindings only forward the intent. Arrow keys
			-- use KeyDown so holding a key repeats, matching cursor movement.
			{
				Key = Keys.VK_LEFT,
				MSG = KeyEvents.KeyDown,
				Description = "LOC_CAI_WB_QN_PREV_PARAM",
				Action = function()
					LuaEvents.CAIWorldBuilderQuickNav("prev_param")
					return true
				end,
			},
			{
				Key = Keys.VK_RIGHT,
				MSG = KeyEvents.KeyDown,
				Description = "LOC_CAI_WB_QN_NEXT_PARAM",
				Action = function()
					LuaEvents.CAIWorldBuilderQuickNav("next_param")
					return true
				end,
			},
			{
				Key = Keys.VK_UP,
				MSG = KeyEvents.KeyDown,
				Description = "LOC_CAI_WB_QN_VALUE_UP",
				Action = function()
					LuaEvents.CAIWorldBuilderQuickNav("value_up")
					return true
				end,
			},
			{
				Key = Keys.VK_DOWN,
				MSG = KeyEvents.KeyDown,
				Description = "LOC_CAI_WB_QN_VALUE_DOWN",
				Action = function()
					LuaEvents.CAIWorldBuilderQuickNav("value_down")
					return true
				end,
			},
			{
				Key = Keys.VK_LEFT,
				MSG = KeyEvents.KeyDown,
				IsShift = true,
				Description = "LOC_CAI_WB_QN_FIRST_PARAM",
				Action = function()
					LuaEvents.CAIWorldBuilderQuickNav("first_param")
					return true
				end,
			},
			{
				Key = Keys.VK_RIGHT,
				MSG = KeyEvents.KeyDown,
				IsShift = true,
				Description = "LOC_CAI_WB_QN_LAST_PARAM",
				Action = function()
					LuaEvents.CAIWorldBuilderQuickNav("last_param")
					return true
				end,
			},
			{
				Key = Keys.VK_UP,
				MSG = KeyEvents.KeyDown,
				IsShift = true,
				Description = "LOC_CAI_WB_QN_FIRST_VALUE",
				Action = function()
					LuaEvents.CAIWorldBuilderQuickNav("first_value")
					return true
				end,
			},
			{
				Key = Keys.VK_DOWN,
				MSG = KeyEvents.KeyDown,
				IsShift = true,
				Description = "LOC_CAI_WB_QN_LAST_VALUE",
				Action = function()
					LuaEvents.CAIWorldBuilderQuickNav("last_value")
					return true
				end,
			},
		})

		m_caiWorldBuilderWidget:AddInputBindings(BuildToolSelectBindings())

		return m_caiWorldBuilderWidget
	end

	local function OnCursorMoved(state)
		local plotId = state.toPlotId
		if m_wbBrushLocked and WorldBuilder.IsActive() and CAI.Active ~= false
			and state.fromPlotId ~= plotId then
			-- Brush lock follows the cursor even when M has marked a source tile.
			WBEditCursorPlot(true, plotId)
		end
	end

	local function Update()
		if m_wbSightRefreshPending then
			m_wbSightRefreshPending = false
			local visMgr = CAI:GetWorldBuilderVisibilityManager()
			if visMgr ~= nil and visMgr.RecomputeSight ~= nil then
				visMgr.RecomputeSight()
			end
		end
	end

	return {
		Build = CreateWorldBuilderWidget,
		GetMarkedPlot = GetWorldBuilderMarkedPlot,
		OnPlacementStatus = OnWorldBuilderPlacementStatus,
		OnCursorMoved = OnCursorMoved,
		Update = Update,
	}
end
