include("AdvancedSetup_Base")
include("caiUtils")
local mgr = ExposedMembers.CAI_UIManager

local CAI_Panel = nil ---@type UIWidget
local CAI_SettingsList = nil ---@type UIWidget
local CAI_TabBar = nil ---@type UIWidget
local m_simpleParamWidgets = {} -- parameterId → UIWidget
local m_intentionalClose = false
local m_activeTab = "basic" -- "basic" or "advanced"

-- Advanced view state
local m_basicChildren = {}        -- snapshot of basic view children
local m_advancedSections = {}     -- GroupId → List widget
local m_advancedParamWidgets = {} -- parameterId → widget
local m_advancedPlayersSection = nil ---@type UIWidget
local m_aiPlayerWidgets = {}      -- ordered array of {playerId, submenu}
local SwitchToTab                 -- forward declaration (defined after BuildPanel)
local RemoveAdvancedSections      -- forward declaration

-- ---------------------------------------------------------------------------
-- Static pulldown spec: { parameterId, pulldownCtrl, containerCtrl }
-- Leader pulldown handled separately (uses scroll text, not button text).
-- ---------------------------------------------------------------------------
local kStaticPulldowns = {
	{ "Ruleset",        function() return Controls.CreateGame_GameRuleset end,     function() return Controls.CreateGame_RulesetContainer end,         "LOC_SETUP_CHOOSE_RULESET" },
	{ "GameDifficulty", function() return Controls.CreateGame_GameDifficulty end,  function() return Controls.CreateGame_GameDifficultyContainer end,  "LOC_SETUP_DIFFICULTY" },
	{ "GameSpeeds",     function() return Controls.CreateGame_SpeedPulldown end,   function() return Controls.CreateGame_SpeedPulldownContainer end,   "LOC_SETUP_SPEED" },
	{ "MapSize",        function() return Controls.CreateGame_MapSize end,         function() return Controls.CreateGame_MapSizeContainer end,         "LOC_SETUP_MAP_SIZE" },
}

-- ---------------------------------------------------------------------------
-- Helper: build an accessible option list for a game-parameter pulldown.
-- Reads parameter.Values from g_GameParameters at the time the user opens it.
-- ---------------------------------------------------------------------------
local function OpenParamDropdown(parameterId)
	local param = g_GameParameters and g_GameParameters.Parameters
		and g_GameParameters.Parameters[parameterId]
	if not param or not param.Values then return end

	local optList = mgr:CreateUIWidget("List")
	optList:AddInputBinding({Key = Keys.VK_ESCAPE, Action = function()
		mgr:Pop()
		return true
	end})

	local currentVal = param.Value
	local selectedChild = nil
	for _, v in ipairs(param.Values) do
		local val = v -- capture
		local child = mgr:CreateUIWidget("MenuItem", {
			GetLabel     = function() return val.Name end,
			GetTooltip   = function() return val.Description or "" end,
			OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
			OnClick      = function()
				g_GameParameters:SetParameterValue(param, val)
				Network.BroadcastGameConfig()
				mgr:Pop()
			end,
		})
		optList:AddChild(child)
		if not selectedChild and currentVal and val.QueryId == currentVal.QueryId
				and val.QueryIndex == currentVal.QueryIndex then
			selectedChild = child
		end
	end
	if selectedChild then optList.FocusedChild = selectedChild end
	mgr:Push(optList)
end

-- ---------------------------------------------------------------------------
-- Helper: build numbered info sections from a leader's GetPlayerInfo data.
-- Returns an array of {label, text} pairs and corresponding number key bindings.
-- ---------------------------------------------------------------------------
local kNumberKeys = {
	Keys["1"], Keys["2"], Keys["3"], Keys["4"], Keys["5"],
	Keys["6"], Keys["7"], Keys["8"], Keys["9"], Keys["0"],
}

local function BuildLeaderInfoSections(domain, leaderType)
	local sections = {}
	if not domain or not leaderType then return sections end
	if leaderType == "RANDOM" or leaderType == "RANDOM_POOL1" or leaderType == "RANDOM_POOL2" then
		return sections
	end

	local info = GetPlayerInfo(domain, leaderType)
	if not info then return sections end

	-- 1: Leader + Civilization name
	local names = Locale.Lookup(info.LeaderName or "")
	if info.CivilizationName then
		names = names .. ", " .. Locale.Lookup(info.CivilizationName)
	end
	table.insert(sections, { label = Locale.Lookup(info.LeaderName or ""), text = names })

	-- 2: Civilization Ability
	if info.CivilizationAbility then
		local ab = info.CivilizationAbility
		table.insert(sections, {
			label = Locale.Lookup(ab.Name),
			text = Locale.Lookup(ab.Name) .. ": " .. Locale.Lookup(ab.Description),
		})
	end

	-- 3: Leader Ability
	if info.LeaderAbility then
		local ab = info.LeaderAbility
		table.insert(sections, {
			label = Locale.Lookup(ab.Name),
			text = Locale.Lookup(ab.Name) .. ": " .. Locale.Lookup(ab.Description),
		})
	end

	-- 4+: Uniques
	if info.Uniques then
		for _, u in ipairs(info.Uniques) do
			table.insert(sections, {
				label = Locale.Lookup(u.Name),
				text = Locale.Lookup(u.Name) .. ": " .. Locale.Lookup(u.Description),
			})
		end
	end

	return sections
end

-- ---------------------------------------------------------------------------
-- Helper: build an option list for the leader pulldown.
-- Leader uses PlayerLeader parameter inside the player's own parameter set.
-- Each leader entry gets number key bindings (1-0) to speak info sections.
-- ---------------------------------------------------------------------------
local function OpenLeaderDropdown()
	local parameters = GetPlayerParameters(m_singlePlayerID)
	if not parameters then return end
	local param = parameters.Parameters and parameters.Parameters["PlayerLeader"]
	if not param or not param.Values then return end

	local optList = mgr:CreateUIWidget("List")
	optList:AddInputBinding({Key = Keys.VK_ESCAPE, Action = function()
		mgr:Pop()
		return true
	end})

	local currentVal = param.Value
	local selectedChild = nil
	for _, v in ipairs(param.Values) do
		local val = v
		local sections = BuildLeaderInfoSections(val.Domain, val.Value)

		local child = mgr:CreateUIWidget("MenuItem", {
			GetLabel     = function() return val.Name end,
			OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
			OnClick      = function()
				parameters:SetParameterValue(param, val)
				Network.BroadcastGameConfig()
				mgr:Pop()
			end,
		})

		-- Bind number keys to speak each info section
		for i, section in ipairs(sections) do
			if i <= #kNumberKeys then
				local text = section.text
				child:AddInputBinding({
					Key = kNumberKeys[i],
					Action = function()
						Speak(text, true)
						return true
					end,
				})
			end
		end

		optList:AddChild(child)
		if not selectedChild and currentVal and val.Value == currentVal.Value then
			selectedChild = child
		end
	end
	if selectedChild then optList.FocusedChild = selectedChild end
	mgr:Push(optList)
end

-- ---------------------------------------------------------------------------
-- Build the panel + settings list + action buttons (called once).
-- ---------------------------------------------------------------------------
local function BuildPanel()
	CAI_Panel = mgr:CreateUIWidget("Dialog", {
		GetLabel = function() return Controls.WindowTitle:GetText() end,
		SpeechSettings = { Role = false },
	})
	CAI_Panel:AddInputBinding({Key = Keys.VK_ESCAPE, Action = function()
		OnBackButton()
		return true
	end})
	CAI_Panel.GetDefaultChild = function(w)
		if m_activeTab == "advanced" then
			return m_advancedPlayersSection or w.Children[2]
		end
		return CAI_SettingsList or w.Children[2]
	end

	-- Tab bar: Basic / Advanced
	CAI_TabBar = mgr:CreateUIWidget("TabBar")
	CAI_TabBar:AddChild(mgr:CreateUIWidget("Tab", {
		GetLabel = function() return Controls.WindowTitle:GetText() end,
		GetState = function() return m_activeTab == "basic" and Locale.Lookup("LOC_CAI_STATE_SELECTED") or nil end,
		OnFocusEnter = function() SwitchToTab("basic") end,
		OnClick      = function() SwitchToTab("basic") end,
	}))
	CAI_TabBar:AddChild(mgr:CreateUIWidget("Tab", {
		GetLabel = function() return Controls.AdvancedSetupButton:GetText() end,
		GetState = function() return m_activeTab == "advanced" and Locale.Lookup("LOC_CAI_STATE_SELECTED") or nil end,
		OnFocusEnter = function() SwitchToTab("advanced") end,
		OnClick      = function() SwitchToTab("advanced") end,
	}))
	CAI_Panel:AddChild(CAI_TabBar)

	CAI_SettingsList = mgr:CreateUIWidget("List")
	CAI_Panel:AddChild(CAI_SettingsList)

	-- Ruleset pulldown (first in visual order)
	local rulesetSpec = kStaticPulldowns[1]
	CAI_SettingsList:AddChild(mgr:CreateUIWidget("DropdownMenu", {
		GetLabel     = function() return Locale.Lookup(rulesetSpec[4]) end,
		GetValue     = function() local c = rulesetSpec[2](); return c and c:GetButton():GetText() or "" end,
		GetTooltip   = function() local c = rulesetSpec[2](); return c and c:GetButton():GetToolTipString() or "" end,
		IsDisabled   = function() local c = rulesetSpec[2](); return c and c:IsDisabled() end,
		IsHidden     = function() local ct = rulesetSpec[3](); return ct and ct:IsHidden() end,
		OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
		OnClick      = function() OpenParamDropdown(rulesetSpec[1]) end,
	}))

	-- Leader pulldown (second in visual order)
	CAI_SettingsList:AddChild(mgr:CreateUIWidget("DropdownMenu", {
		GetLabel     = function() return Locale.Lookup("LOC_SETUP_CIVILIZATION") end,
		GetValue     = function()
			local scrollText = Controls.Basic_LocalPlayerScrollText
			if scrollText then return scrollText:GetText() or "" end
			return Controls.Basic_LocalPlayerPulldown:GetButton():GetText() or ""
		end,
		IsHidden     = function() return Controls.CreateGame_LocalPlayerContainer:IsHidden() end,
		OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
		OnClick      = function() OpenLeaderDropdown() end,
	}))

	-- Remaining static pulldowns (Difficulty, Speed, MapSize)
	for i = 2, #kStaticPulldowns do
		local spec = kStaticPulldowns[i]
		local paramId = spec[1]
		local getCtrl = spec[2]
		local getContainer = spec[3]
		local locKey = spec[4]
		CAI_SettingsList:AddChild(mgr:CreateUIWidget("DropdownMenu", {
			GetLabel     = function() return Locale.Lookup(locKey) end,
			GetValue     = function() local c = getCtrl(); return c and c:GetButton():GetText() or "" end,
			GetTooltip   = function() local c = getCtrl(); return c and c:GetButton():GetToolTipString() or "" end,
			IsDisabled   = function() local c = getCtrl(); return c and c:IsDisabled() end,
			IsHidden     = function() local ct = getContainer(); return ct and ct:IsHidden() end,
			OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
			OnClick      = function() OpenParamDropdown(paramId) end,
		}))
	end

	-- Map select button — label is "Map Type", value is the current map name
	CAI_SettingsList:AddChild(mgr:CreateUIWidget("Button", {
		GetLabel     = function() return Locale.Lookup("LOC_SETUP_MAP_TYPE") end,
		GetValue     = function() return Controls.MapSelectButton:GetText() or "" end,
		GetTooltip   = function() return Controls.MapSelectButton:GetToolTipString() or "" end,
		OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
		OnClick      = function() OnMapSelect() end,
	}))

	-- Action buttons as direct panel children
	-- LoadConfig and SaveConfig are only visible in advanced mode
	CAI_Panel:AddChild(mgr:CreateUIWidget("Button", {
		GetLabel     = function() return Controls.LoadConfig:GetText() end,
		IsHidden     = function() return Controls.LoadConfig:IsHidden() end,
		OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
		OnClick      = function() OnLoadConfig() end,
	}))
	CAI_Panel:AddChild(mgr:CreateUIWidget("Button", {
		GetLabel     = function() return Controls.SaveConfig:GetText() end,
		IsHidden     = function() return Controls.SaveConfig:IsHidden() end,
		OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
		OnClick      = function() OnSaveConfig() end,
	}))

	local kActionButtons = {
		{ function() return Controls.StartButton end,   function() OnStartButton() end },
		{ function() return Controls.DefaultButton end,  function() OnDefaultButton() end },
		{ function() return Controls.CloseButton end,    function() OnBackButton() end },
	}
	for _, btn in ipairs(kActionButtons) do
		local getCtrl = btn[1]
		local onClick = btn[2]
		CAI_Panel:AddChild(mgr:CreateUIWidget("Button", {
			GetLabel     = function() return getCtrl():GetText() end,
			IsHidden     = function() return getCtrl():IsHidden() end,
			OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
			OnClick      = onClick,
		}))
	end
end

-- ---------------------------------------------------------------------------
-- Dynamic parameter widgets: wrap CreateSimpleParameterDriver to create
-- accessible widgets for game modes, booleans, pulldowns, sliders, edits.
-- ---------------------------------------------------------------------------
CreateSimpleParameterDriver = WrapFunc(CreateSimpleParameterDriver, function(orig, o, parameter, parent)
	local control = orig(o, parameter, parent)
	if not control or not CAI_SettingsList then return control end

	local paramId = parameter.ParameterId
	if m_simpleParamWidgets[paramId] then return control end -- already created

	local widget = nil

	if parameter.GroupId == "GameModes" or parameter.Domain == "bool" then
		-- Checkbox
		widget = mgr:CreateUIWidget("Checkbox", {
			GetLabel   = function() return parameter.Name end,
			GetTooltip = function() return parameter.Description or "" end,
			GetValue   = function()
				local p = g_GameParameters and g_GameParameters.Parameters
					and g_GameParameters.Parameters[paramId]
				if p then
					return p.Value and Locale.Lookup("LOC_OPTIONS_ENABLED")
						or Locale.Lookup("LOC_OPTIONS_DISABLED")
				end
				return ""
			end,
			IsHidden   = function()
				local ctrl = control.Control
				if parameter.GroupId == "GameModes" then
					return ctrl and ctrl.Top and ctrl.Top:IsHidden()
				else
					return ctrl and ctrl.CheckBox and ctrl.CheckBox:IsHidden()
				end
			end,
			IsDisabled = function()
				local ctrl = control.Control
				if parameter.GroupId == "GameModes" then
					return ctrl and ctrl.CheckBox and ctrl.CheckBox:IsDisabled()
				else
					return ctrl and ctrl.CheckBox and ctrl.CheckBox:IsDisabled()
				end
			end,
			Toggle     = function()
				local p = g_GameParameters and g_GameParameters.Parameters
					and g_GameParameters.Parameters[paramId]
				if p then
					o:SetParameterValue(parameter, not p.Value)
					Network.BroadcastGameConfig()
				end
			end,
		})
	elseif parameter.Values and parameter.Values.Type == "IntRange" then
		-- Slider
		local minVal = parameter.Values.MinimumValue
		local maxVal = parameter.Values.MaximumValue
		widget = mgr:CreateUIWidget("Slider", {
			GetLabel   = function() return parameter.Name end,
			GetTooltip = function() return parameter.Description or "" end,
			GetValue   = function()
				local p = g_GameParameters and g_GameParameters.Parameters
					and g_GameParameters.Parameters[paramId]
				return p and tostring(p.Value) or ""
			end,
			IsHidden   = function()
				return control.Control and control.Control.Root and control.Control.Root:IsHidden()
			end,
			Increment  = function()
				local p = g_GameParameters and g_GameParameters.Parameters
					and g_GameParameters.Parameters[paramId]
				if p and p.Value and p.Value < maxVal then
					o:SetParameterValue(parameter, p.Value + 1)
					Network.BroadcastGameConfig()
				end
			end,
			Decrement  = function()
				local p = g_GameParameters and g_GameParameters.Parameters
					and g_GameParameters.Parameters[paramId]
				if p and p.Value and p.Value > minVal then
					o:SetParameterValue(parameter, p.Value - 1)
					Network.BroadcastGameConfig()
				end
			end,
		})
	elseif parameter.Values then
		-- MultiValue pulldown
		widget = mgr:CreateUIWidget("DropdownMenu", {
			GetLabel     = function() return parameter.Name end,
			GetTooltip   = function() return parameter.Description or "" end,
			GetValue     = function()
				local ctrl = control.Control
				return ctrl and ctrl.PullDown and ctrl.PullDown:GetButton():GetText() or ""
			end,
			IsHidden     = function()
				return control.Control and control.Control.Root and control.Control.Root:IsHidden()
			end,
			IsDisabled   = function()
				local ctrl = control.Control
				return ctrl and ctrl.PullDown and ctrl.PullDown:IsDisabled()
			end,
			OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
			OnClick      = function() OpenParamDropdown(paramId) end,
		})
	elseif parameter.Domain == "int" or parameter.Domain == "uint" or parameter.Domain == "text" then
		-- Edit/string
		local domain = parameter.Domain
		widget = mgr:CreateUIWidget("Edit", {
			GetLabel   = function() return parameter.Name end,
			GetValue   = function()
				local ctrl = control.Control
				return ctrl and ctrl.StringEdit and ctrl.StringEdit:GetText() or ""
			end,
			IsHidden   = function()
				return control.Control and control.Control.Root and control.Control.Root:IsHidden()
			end,
			OnSetText  = function(w, text)
				local ctrl = control.Control
				if ctrl and ctrl.StringEdit then ctrl.StringEdit:SetText(text) end
			end,
			OnCommit   = function(w, text)
				local value = text
				if domain == "int" then
					value = tonumber(text) or 0
				elseif domain == "uint" then
					value = math.max(tonumber(text) or 0, 0)
				end
				o:SetParameterValue(parameter, value)
				Network.BroadcastGameConfig()
			end,
		})
	end

	if widget then
		CAI_SettingsList:AddChild(widget)
		m_simpleParamWidgets[paramId] = widget
	end

	return control
end)

-- ---------------------------------------------------------------------------
-- Advanced view: open leader dropdown for any player (local or AI)
-- ---------------------------------------------------------------------------
local function OpenLeaderDropdownForPlayer(playerId)
	local parameters = GetPlayerParameters(playerId)
	if not parameters then return end
	local param = parameters.Parameters and parameters.Parameters["PlayerLeader"]
	if not param or not param.Values then return end

	local optList = mgr:CreateUIWidget("List")
	optList:AddInputBinding({Key = Keys.VK_ESCAPE, Action = function()
		mgr:Pop()
		return true
	end})

	local currentVal = param.Value
	local selectedChild = nil
	for _, v in ipairs(param.Values) do
		local val = v
		local sections = (playerId == m_singlePlayerID)
			and BuildLeaderInfoSections(val.Domain, val.Value) or {}

		local child = mgr:CreateUIWidget("MenuItem", {
			GetLabel     = function() return val.Name end,
			OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
			OnClick      = function()
				parameters:SetParameterValue(param, val)
				-- Reset color on leader change
				local colorParam = parameters.Parameters["PlayerColorAlternate"]
				if colorParam then
					parameters:SetParameterValue(colorParam, 0)
				end
				Network.BroadcastGameConfig()
				mgr:Pop()
			end,
		})

		-- Number key bindings for local player info sections
		for i, section in ipairs(sections) do
			if i <= #kNumberKeys then
				local text = section.text
				child:AddInputBinding({
					Key = kNumberKeys[i],
					Action = function()
						Speak(text, true)
						return true
					end,
				})
			end
		end

		optList:AddChild(child)
		if not selectedChild and currentVal and val.Value == currentVal.Value then
			selectedChild = child
		end
	end
	if selectedChild then optList.FocusedChild = selectedChild end
	mgr:Push(optList)
end

-- ---------------------------------------------------------------------------
-- Advanced view: open color dropdown for local player
-- ---------------------------------------------------------------------------
local function OpenColorDropdown()
	local parameters = GetPlayerParameters(m_singlePlayerID)
	if not parameters then return end
	local param = parameters.Parameters and parameters.Parameters["PlayerColorAlternate"]
	if not param then return end
	local leaderParam = parameters.Parameters["PlayerLeader"]
	if not leaderParam or not leaderParam.Value then return end

	local icons = GetPlayerIcons(leaderParam.Value.Domain, leaderParam.Value.Value)
	if not icons then return end

	local optList = mgr:CreateUIWidget("List")
	optList:AddInputBinding({Key = Keys.VK_ESCAPE, Action = function()
		mgr:Pop()
		return true
	end})

	local currentVal = param.Value or 0
	local selectedChild = nil
	for j = 0, 3 do
		local backColor, frontColor = UI.GetPlayerColorValues(icons.PlayerColor, j)
		if backColor and frontColor and backColor ~= 0 and frontColor ~= 0 then
			local colorIdx = j
			local child = mgr:CreateUIWidget("MenuItem", {
				GetLabel     = function() return Locale.Lookup("LOC_CAI_COLOR") .. " " .. (colorIdx + 1) end,
				OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
				OnClick      = function()
					parameters:SetParameterValue(param, colorIdx)
					Network.BroadcastGameConfig()
					mgr:Pop()
				end,
			})
			optList:AddChild(child)
			if not selectedChild and colorIdx == currentVal then
				selectedChild = child
			end
		end
	end
	if selectedChild then optList.FocusedChild = selectedChild end
	mgr:Push(optList)
end

-- ---------------------------------------------------------------------------
-- Advanced view: get the section list widget for a parameter group
-- ---------------------------------------------------------------------------
local kGroupToSection = {
	BasicGameOptions = "Primary",
	GameOptions      = "Primary",
	BasicMapOptions  = "Primary",
	MapOptions       = "Primary",
	GameModes        = "GameModes",
	Victories        = "Victories",
	AdvancedOptions  = "Advanced",
}

local function GetAdvancedSection(groupId)
	local sectionKey = kGroupToSection[groupId]
	if sectionKey then
		return m_advancedSections[sectionKey]
	end
	-- Default to Advanced for unknown groups
	return m_advancedSections["Advanced"]
end

-- ---------------------------------------------------------------------------
-- Advanced view: build player section widgets
-- ---------------------------------------------------------------------------
local function BuildPlayerSection()
	if not m_advancedPlayersSection then return end
	m_advancedPlayersSection:ClearChildren()
	m_aiPlayerWidgets = {}

	-- Local player leader
	m_advancedPlayersSection:AddChild(mgr:CreateUIWidget("DropdownMenu", {
		GetLabel     = function() return Locale.Lookup("LOC_SETUP_CIVILIZATION") end,
		GetValue     = function()
			local scrollText = Controls.Advanced_LocalPlayerScrollText
			if scrollText then return scrollText:GetText() or "" end
			return Controls.Advanced_LocalPlayerPulldown:GetButton():GetText() or ""
		end,
		IsHidden     = function() return Controls.CreateGame_LocalPlayerContainer:IsHidden() end,
		OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
		OnClick      = function() OpenLeaderDropdownForPlayer(m_singlePlayerID) end,
	}))

	-- Local player color
	m_advancedPlayersSection:AddChild(mgr:CreateUIWidget("DropdownMenu", {
		GetLabel     = function() return Locale.Lookup("LOC_CAI_COLOR") end,
		GetValue     = function()
			local ctrl = Controls.Advanced_LocalColorPullDown
			if ctrl then
				return ctrl:GetButton():GetText() or ""
			end
			return ""
		end,
		IsHidden     = function()
			local ctrl = Controls.Advanced_LocalColorPullDown
			return ctrl and ctrl:IsDisabled()
		end,
		OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
		OnClick      = function() OpenColorDropdown() end,
	}))

	-- AI player slots
	local player_ids = GameConfiguration.GetParticipatingPlayerIDs()
	local minPlayers = MapConfiguration.GetMinMajorPlayers() or 2
	local can_remove = #player_ids > minPlayers

	local aiIndex = 0
	for _, player_id in ipairs(player_ids) do
		if player_id ~= m_singlePlayerID then
			aiIndex = aiIndex + 1
			local pid = player_id
			local playerNum = aiIndex + 1 -- capture for closure
			local playerConfig = PlayerConfigurations[pid]

			local aiSubmenu = mgr:CreateUIWidget("SubMenu", {
				GetLabel = function()
					local params = GetPlayerParameters(pid)
					local leaderParam = params and params.Parameters and params.Parameters["PlayerLeader"]
					local leaderName = leaderParam and leaderParam.Value and leaderParam.Value.Name or "?"
					return Locale.Lookup("LOC_CAI_PLAYER") .. " " .. playerNum .. ": " .. leaderName
				end,
			})

			-- Leader dropdown
			aiSubmenu:AddChild(mgr:CreateUIWidget("DropdownMenu", {
				GetLabel     = function() return Locale.Lookup("LOC_SETUP_CIVILIZATION") end,
				GetValue     = function()
					local params = GetPlayerParameters(pid)
					local leaderParam = params and params.Parameters and params.Parameters["PlayerLeader"]
					return leaderParam and leaderParam.Value and leaderParam.Value.Name or ""
				end,
				OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
				OnClick      = function() OpenLeaderDropdownForPlayer(pid) end,
			}))

			-- Remove button
			if can_remove then
				aiSubmenu:AddChild(mgr:CreateUIWidget("Button", {
					GetLabel = function() return Locale.Lookup("LOC_DELETE_AI") end,
					OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
					OnClick = function()
						playerConfig:SetLeaderTypeName(nil)
						GameConfiguration.RemovePlayer(pid)
						GameSetup_PlayerCountChanged()
					end,
				}))
			end

			m_advancedPlayersSection:AddChild(aiSubmenu)
			table.insert(m_aiPlayerWidgets, {playerId = pid, submenu = aiSubmenu})
		end
	end

	-- Add AI button
	m_advancedPlayersSection:AddChild(mgr:CreateUIWidget("Button", {
		GetLabel     = function() return Controls.AddAIButton:GetText() end,
		IsHidden     = function() return Controls.AddAIButton:IsHidden() end,
		OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
		OnClick      = function() OnAddAIButton() end,
	}))
end

-- ---------------------------------------------------------------------------
-- Advanced view: build all children for the advanced settings list
-- ---------------------------------------------------------------------------
local function BuildAdvancedChildren()
	m_advancedSections = {}
	m_advancedParamWidgets = {}

	-- Create section lists
	local sectionDefs = {
		{ key = "Primary",   label = "LOC_OPTIONS" },
		{ key = "GameModes", label = "LOC_SETUP_GAME_MODES" },
		{ key = "Victories", label = "LOC_SETUP_VICTORY_CONDITIONS" },
		{ key = "Advanced",  label = "LOC_ADVANCED_OPTIONS" },
	}
	for _, def in ipairs(sectionDefs) do
		m_advancedSections[def.key] = mgr:CreateUIWidget("List", {
			GetLabel = function() return Locale.Lookup(def.label) end,
		})
	end

	-- Players section
	m_advancedPlayersSection = mgr:CreateUIWidget("List", {
		GetLabel = function() return Locale.Lookup("LOC_PLAYERS") end,
	})
	BuildPlayerSection()
end

-- ---------------------------------------------------------------------------
-- Detach all children from a widget without destroying them
-- ---------------------------------------------------------------------------
local function DetachChildren(widget)
	if not widget or not widget.Children then return end
	for _, child in ipairs(widget.Children) do
		child.Parent = nil
	end
	widget.Children = {}
	widget.FocusedChild = nil
end

-- ---------------------------------------------------------------------------
-- Remove advanced sections from the panel
-- ---------------------------------------------------------------------------
RemoveAdvancedSections = function()
	if m_advancedPlayersSection and m_advancedPlayersSection.Parent == CAI_Panel then
		m_advancedPlayersSection:RemoveFromParent()
	end
	for _, section in pairs(m_advancedSections) do
		if section.Parent == CAI_Panel then
			section:RemoveFromParent()
		end
	end
end

-- ---------------------------------------------------------------------------
-- Swap settings list children between basic and advanced views
-- ---------------------------------------------------------------------------
local function PopulateBasicView()
	if not CAI_SettingsList then return end

	-- Remove advanced sections from panel
	RemoveAdvancedSections()

	-- Re-add the basic settings list after TabBar if not already there
	if not CAI_Panel:GetChildIndex(CAI_SettingsList) then
		CAI_Panel:InsertChild(2, CAI_SettingsList)
	end

	-- Repopulate basic children
	DetachChildren(CAI_SettingsList)
	for _, child in ipairs(m_basicChildren) do
		CAI_SettingsList:AddChild(child)
	end
end

local function PopulateAdvancedView()
	if not CAI_Panel then return end

	-- Build advanced children fresh (params may have changed)
	BuildAdvancedChildren()

	-- Populate advanced param widgets from current game parameters
	if g_GameParameters and g_GameParameters.Parameters then
		for paramId, param in pairs(g_GameParameters.Parameters) do
			if not m_advancedParamWidgets[paramId] then
				local section = GetAdvancedSection(param.GroupId)
				if section then
					CreateAdvancedParamWidget(param, section)
				end
			end
		end
	end

	-- Remove the basic settings list from the panel
	if CAI_Panel:GetChildIndex(CAI_SettingsList) then
		CAI_SettingsList:RemoveFromParent()
	end

	-- Add sections directly to panel (after TabBar, before action buttons)
	local insertIdx = 2
	CAI_Panel:InsertChild(insertIdx, m_advancedPlayersSection)
	insertIdx = insertIdx + 1

	local sectionOrder = { "Primary", "GameModes", "Victories", "Advanced" }
	for _, key in ipairs(sectionOrder) do
		local section = m_advancedSections[key]
		if section then
			CAI_Panel:InsertChild(insertIdx, section)
			insertIdx = insertIdx + 1
		end
	end
end

-- ---------------------------------------------------------------------------
-- Switch between basic and advanced tabs
-- ---------------------------------------------------------------------------
SwitchToTab = function(tabName)
	if tabName == m_activeTab then return end
	m_activeTab = tabName
	if tabName == "advanced" then
		Controls.CreateGameWindow:SetHide(true)
		Controls.AdvancedOptionsWindow:SetHide(false)
		Controls.LoadConfig:SetHide(GameConfiguration.IsWorldBuilderEditor())
		Controls.SaveConfig:SetHide(GameConfiguration.IsWorldBuilderEditor())
		Controls.ButtonStack:CalculateSize()
		m_AdvancedMode = true
		PopulateAdvancedView()
	else
		Controls.CreateGameWindow:SetHide(false)
		Controls.AdvancedOptionsWindow:SetHide(true)
		Controls.LoadConfig:SetHide(true)
		Controls.SaveConfig:SetHide(true)
		Controls.ButtonStack:CalculateSize()
		m_AdvancedMode = false
		PopulateBasicView()
	end
end

-- ---------------------------------------------------------------------------
-- Create an accessible widget for an advanced-view parameter
-- ---------------------------------------------------------------------------
function CreateAdvancedParamWidget(parameter, section)
	if not section then return end
	local paramId = parameter.ParameterId
	if m_advancedParamWidgets[paramId] then return end

	local widget = nil

	-- Skip player parameters (no parent stack) and already-handled special params
	if not kGroupToSection[parameter.GroupId] and parameter.GroupId ~= nil then
		return
	end

	if parameter.Array then
		-- Array parameters are pickers (CityStates, LeaderPool, MultiSelect)
		-- These are handled by the special driver wraps when they fire during refresh
		-- But if we're populating after the fact, create a simple button
		local paramId_inner = parameter.ParameterId
		widget = mgr:CreateUIWidget("Button", {
			GetLabel     = function() return parameter.Name end,
			GetTooltip   = function() return parameter.Description or "" end,
			GetValue     = function()
				local p = g_GameParameters and g_GameParameters.Parameters
					and g_GameParameters.Parameters[paramId_inner]
				if p and p.Value then
					if type(p.Value) == "table" then
						local count = #p.Value
						if count == 0 then return Locale.Lookup("LOC_SELECTION_NOTHING") end
						if p.AllValues and count == #p.AllValues then return Locale.Lookup("LOC_SELECTION_EVERYTHING") end
						return Locale.Lookup("LOC_SELECTION_CUSTOM", count)
					end
					return p.Value.Name or ""
				end
				return ""
			end,
			OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
			OnClick      = function()
				-- Try to open the appropriate picker
				if paramId_inner == "CityStates" then
					LuaEvents.CityStatePicker_Initialize(g_GameParameters.Parameters[paramId_inner], g_GameParameters)
					Controls.CityStatePicker:SetHide(false)
				elseif paramId_inner == "LeaderPool1" or paramId_inner == "LeaderPool2" then
					LuaEvents.LeaderPicker_Initialize(g_GameParameters.Parameters[paramId_inner], g_GameParameters)
					Controls.LeaderPicker:SetHide(false)
				else
					LuaEvents.MultiSelectWindow_Initialize(g_GameParameters.Parameters[paramId_inner])
					Controls.MultiSelectWindow:SetHide(false)
				end
			end,
		})
	elseif parameter.Domain == "bool" then
		widget = mgr:CreateUIWidget("Checkbox", {
			GetLabel   = function() return parameter.Name end,
			GetTooltip = function() return parameter.Description or "" end,
			GetValue   = function()
				local p = g_GameParameters and g_GameParameters.Parameters
					and g_GameParameters.Parameters[paramId]
				if p then
					return p.Value and Locale.Lookup("LOC_OPTIONS_ENABLED")
						or Locale.Lookup("LOC_OPTIONS_DISABLED")
				end
				return ""
			end,
			Toggle     = function()
				local p = g_GameParameters and g_GameParameters.Parameters
					and g_GameParameters.Parameters[paramId]
				if p then
					g_GameParameters:SetParameterValue(p, not p.Value)
					BroadcastGameConfigChanges()
				end
			end,
		})
	elseif parameter.Values and parameter.Values.Type == "IntRange" then
		local minVal = parameter.Values.MinimumValue
		local maxVal = parameter.Values.MaximumValue
		widget = mgr:CreateUIWidget("Slider", {
			GetLabel   = function() return parameter.Name end,
			GetTooltip = function() return parameter.Description or "" end,
			GetValue   = function()
				local p = g_GameParameters and g_GameParameters.Parameters
					and g_GameParameters.Parameters[paramId]
				return p and tostring(p.Value) or ""
			end,
			Increment  = function()
				local p = g_GameParameters and g_GameParameters.Parameters
					and g_GameParameters.Parameters[paramId]
				if p and p.Value and p.Value < maxVal then
					g_GameParameters:SetParameterValue(p, p.Value + 1)
					BroadcastGameConfigChanges()
				end
			end,
			Decrement  = function()
				local p = g_GameParameters and g_GameParameters.Parameters
					and g_GameParameters.Parameters[paramId]
				if p and p.Value and p.Value > minVal then
					g_GameParameters:SetParameterValue(p, p.Value - 1)
					BroadcastGameConfigChanges()
				end
			end,
		})
	elseif parameter.Values then
		widget = mgr:CreateUIWidget("DropdownMenu", {
			GetLabel     = function() return parameter.Name end,
			GetTooltip   = function() return parameter.Description or "" end,
			GetValue     = function()
				local p = g_GameParameters and g_GameParameters.Parameters
					and g_GameParameters.Parameters[paramId]
				return p and p.Value and p.Value.Name or ""
			end,
			OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
			OnClick      = function() OpenParamDropdown(paramId) end,
		})
	elseif parameter.Domain == "int" or parameter.Domain == "uint" or parameter.Domain == "text" then
		local domain = parameter.Domain
		widget = mgr:CreateUIWidget("Edit", {
			GetLabel = function() return parameter.Name end,
			GetValue = function()
				local p = g_GameParameters and g_GameParameters.Parameters
					and g_GameParameters.Parameters[paramId]
				return p and p.Value and tostring(p.Value) or ""
			end,
			OnCommit = function(w, text)
				local value = text
				if domain == "int" then
					value = tonumber(text) or 0
				elseif domain == "uint" then
					value = math.max(tonumber(text) or 0, 0)
				end
				local p = g_GameParameters and g_GameParameters.Parameters
					and g_GameParameters.Parameters[paramId]
				if p then
					g_GameParameters:SetParameterValue(p, value)
					BroadcastGameConfigChanges()
				end
			end,
		})
	end

	if widget then
		section:AddChild(widget)
		m_advancedParamWidgets[paramId] = widget
	end
end

-- ---------------------------------------------------------------------------
-- Wrap special button-popup drivers to create accessible widgets
-- ---------------------------------------------------------------------------
CreateButtonPopupDriver = WrapFunc(CreateButtonPopupDriver, function(orig, o, parameter, activateFunc, parent)
	local driver = orig(o, parameter, activateFunc, parent)
	if not m_AdvancedMode or not driver then return driver end

	local paramId = parameter.ParameterId
	if m_advancedParamWidgets[paramId] then return driver end

	local section = GetAdvancedSection(parameter.GroupId)
	if not section then return driver end

	local widget = mgr:CreateUIWidget("Button", {
		GetLabel     = function() return parameter.Name end,
		GetValue     = function()
			local c = driver.Cache
			return c and c.ValueText or ""
		end,
		GetTooltip   = function() return parameter.Description or "" end,
		OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
		OnClick      = function()
			if activateFunc then activateFunc() end
		end,
	})
	section:AddChild(widget)
	m_advancedParamWidgets[paramId] = widget
	return driver
end)

CreateMultiSelectWindowDriver = WrapFunc(CreateMultiSelectWindowDriver, function(orig, o, parameter, parent)
	local driver = orig(o, parameter, parent)
	if not m_AdvancedMode or not driver then return driver end

	local paramId = parameter.ParameterId
	if m_advancedParamWidgets[paramId] then return driver end

	local section = GetAdvancedSection(parameter.GroupId)
	if not section then return driver end

	local widget = mgr:CreateUIWidget("Button", {
		GetLabel     = function() return parameter.Name end,
		GetValue     = function()
			local c = driver.Cache
			return c and c.ValueText and Locale.Lookup(c.ValueText, c.ValueAmount or 0) or ""
		end,
		GetTooltip   = function() return parameter.Description or "" end,
		OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
		OnClick      = function()
			LuaEvents.MultiSelectWindow_Initialize(o.Parameters[paramId])
			Controls.MultiSelectWindow:SetHide(false)
		end,
	})
	section:AddChild(widget)
	m_advancedParamWidgets[paramId] = widget
	return driver
end)

CreateCityStatePickerDriver = WrapFunc(CreateCityStatePickerDriver, function(orig, o, parameter, parent)
	local driver = orig(o, parameter, parent)
	if not m_AdvancedMode or not driver then return driver end

	local paramId = parameter.ParameterId
	if m_advancedParamWidgets[paramId] then return driver end

	local section = GetAdvancedSection(parameter.GroupId)
	if not section then return driver end

	local widget = mgr:CreateUIWidget("Button", {
		GetLabel     = function() return parameter.Name end,
		GetValue     = function()
			local c = driver.Cache
			return c and c.ValueText and Locale.Lookup(c.ValueText, c.ValueAmount or 0) or ""
		end,
		GetTooltip   = function() return parameter.Description or "" end,
		OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
		OnClick      = function()
			LuaEvents.CityStatePicker_Initialize(o.Parameters[paramId], g_GameParameters)
			Controls.CityStatePicker:SetHide(false)
		end,
	})
	section:AddChild(widget)
	m_advancedParamWidgets[paramId] = widget
	return driver
end)

CreateLeaderPickerDriver = WrapFunc(CreateLeaderPickerDriver, function(orig, o, parameter, parent)
	local driver = orig(o, parameter, parent)
	if not m_AdvancedMode or not driver then return driver end

	local paramId = parameter.ParameterId
	if m_advancedParamWidgets[paramId] then return driver end

	local section = GetAdvancedSection(parameter.GroupId)
	if not section then return driver end

	local widget = mgr:CreateUIWidget("Button", {
		GetLabel     = function() return parameter.Name end,
		GetValue     = function()
			local c = driver.Cache
			return c and c.ValueText and Locale.Lookup(c.ValueText, c.ValueAmount or 0) or ""
		end,
		GetTooltip   = function() return parameter.Description or "" end,
		OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
		OnClick      = function()
			LuaEvents.LeaderPicker_Initialize(o.Parameters[paramId], g_GameParameters)
			Controls.LeaderPicker:SetHide(false)
		end,
	})
	section:AddChild(widget)
	m_advancedParamWidgets[paramId] = widget
	return driver
end)

-- ---------------------------------------------------------------------------
-- Wrap RefreshPlayerSlots to rebuild player widgets when in advanced mode
-- ---------------------------------------------------------------------------
RefreshPlayerSlots = WrapFunc(RefreshPlayerSlots, function(orig)
	orig()
	if m_AdvancedMode and m_advancedPlayersSection then
		BuildPlayerSection()
	end
end)

-- ---------------------------------------------------------------------------
-- Close: pop panel from stack
-- ---------------------------------------------------------------------------
local function ClosePanel()
	if mgr:HasWidget(CAI_Panel) then
		mgr:Pop()
	end
end

-- ---------------------------------------------------------------------------
-- Lifecycle hooks
-- ---------------------------------------------------------------------------
OnShow = WrapFunc(OnShow, function(orig)
	-- Clean up stale panel if still on stack (e.g. after a non-intentional hide)
	if CAI_Panel and mgr:HasWidget(CAI_Panel) then
		mgr:Pop()
	end
	-- Rebuild fresh each show — game recreates parameter controls between visits
	CAI_Panel = nil
	CAI_SettingsList = nil
	m_simpleParamWidgets = {}
	m_advancedParamWidgets = {}
	m_advancedSections = {}
	m_advancedPlayersSection = nil
	m_aiPlayerWidgets = {}
	m_basicChildren = {}
	m_activeTab = "basic"
	CAI_TabBar = nil
	m_intentionalClose = false
	BuildPanel()
	-- Snapshot basic children so we can restore them after leaving advanced view
	if CAI_SettingsList then
		for _, child in ipairs(CAI_SettingsList.Children) do
			table.insert(m_basicChildren, child)
		end
	end
	orig()
	ContextPtr:SetInputHandler(function(input)
		if mgr:HandleInput(input) then return true end
		-- Fallback: original input handler consumed all input
		local uiMsg = input:GetMessageType()
		if uiMsg == KeyEvents.KeyUp then
			local key = input:GetKey()
			if key == Keys.VK_ESCAPE then
				OnBackButton()
			end
		end
		return true
	end, true)
	mgr:Push(CAI_Panel)
end)

OnBackButton = WrapFunc(OnBackButton, function(orig)
	-- Always close the screen, regardless of which tab is active
	m_intentionalClose = true
	ClosePanel()
	-- Reset to basic mode so orig() takes the full-close path
	if m_AdvancedMode then
		Controls.CreateGameWindow:SetHide(false)
		Controls.AdvancedOptionsWindow:SetHide(true)
		Controls.LoadConfig:SetHide(true)
		Controls.SaveConfig:SetHide(true)
		m_AdvancedMode = false
	end
	orig()
end)

OnHide = WrapFunc(OnHide, function(orig)
	-- Only pop if we intentionally closed (not on connection resets or temp hides)
	if m_intentionalClose then
		ClosePanel()
		m_intentionalClose = false
	end
	orig()
end)
ContextPtr:SetShowHandler( OnShow );
	ContextPtr:SetHideHandler( OnHide );