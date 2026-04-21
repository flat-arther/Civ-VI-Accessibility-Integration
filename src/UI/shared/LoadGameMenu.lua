include("LoadGameMenu_Base")
include("caiUtils")
local mgr = ExposedMembers.CAI_UIManager

local CAI_Panel = nil
local CAI_FileList = nil
local CAI_InspectorList = nil

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function SafeText(ctrl)
	if ctrl and ctrl.GetText then
		return ctrl:GetText() or ""
	end
	return ""
end

local function SafeTooltip(ctrl)
	if ctrl and ctrl.GetToolTipString then
		return ctrl:GetToolTipString() or ""
	end
	return ""
end

local function LookupBundleOrText(value)
	if value then
		local text = Locale.LookupBundle(value)
		if text == nil or text == "" then
			text = Locale.Lookup(value)
		end
		return text or ""
	end
	return ""
end

local function JoinParts(parts)
	local out = {}
	for _, part in ipairs(parts) do
		if part and part ~= "" then
			table.insert(out, part)
		end
	end
	return table.concat(out, ", ")
end

local function GetSelectedFileInfo()
	if g_FileList and g_iSelectedFileEntry and g_iSelectedFileEntry > 0 then
		return g_FileList[g_iSelectedFileEntry]
	end
	return nil
end

local function GetCurrentSortLabel()
	local button = Controls.SortByPullDown and Controls.SortByPullDown:GetButton()
	return button and button:GetText() or ""
end

local function GetCurrentDirectoryLabel()
	local button = Controls.DirectoryPullDown and Controls.DirectoryPullDown:GetButton()
	return button and button:GetText() or ""
end

local function GetEntryControl(idx)
	return g_FileEntryInstanceList and g_FileEntryInstanceList[idx] or nil
end

local function GetEntryLabel(idx, entry)
	local instance = GetEntryControl(idx)
	if instance and instance.ButtonText and instance.ButtonText.GetText then
		local text = instance.ButtonText:GetText()
		if text and text ~= "" then
			return text
		end
	end

	if entry and entry.DisplayName and entry.DisplayName ~= "" then
		return entry.DisplayName
	end

	if entry then
		return GetDisplayName(entry)
	end

	return ""
end

local function GetShortEntrySummary()
	return JoinParts({
		SafeText(Controls.SelectedCurrentTurnLabel),
		SafeText(Controls.SelectedTimeLabel),
		SafeText(Controls.SelectedHostEraLabel),
	})
end

local function ClosePanel()
	if CAI_Panel and mgr:HasWidget(CAI_Panel) then
		mgr:Pop()
	end
end

local function AddInspectorRow(label, value)
	if not CAI_InspectorList then return end
	if not value or value == "" then return end

	local text = label and label ~= "" and (label .. ", " .. value) or value
	CAI_InspectorList:AddChild(mgr:CreateUIWidget("MenuItem", {
		GetLabel = function()
			return text
		end,
	}))
end

local function RebuildInspectorAccessibility()
	if not CAI_InspectorList then return end
	CAI_InspectorList:ClearChildren()

	local fileInfo = GetSelectedFileInfo()
	if not fileInfo or fileInfo.IsDirectory then
		return
	end

	local function AddHeader(text)
		if not text or text == "" then return end
		CAI_InspectorList:AddChild(mgr:CreateUIWidget("MenuItem", {
			GetLabel = function()
				return text
			end,
		}))
	end

	AddInspectorRow(Locale.Lookup("LOC_CAI_LABEL_FILE_NAME"), SafeText(Controls.FileName))
	AddInspectorRow(nil, SafeText(Controls.SelectedCurrentTurnLabel))
	AddInspectorRow(Locale.Lookup("LOC_CAI_LABEL_SAVE_TIME"), SafeText(Controls.SelectedTimeLabel))
	AddInspectorRow(Locale.Lookup("LOC_CAI_LABEL_ERA"), SafeText(Controls.SelectedHostEraLabel))
	AddInspectorRow(Locale.Lookup("LOC_CAI_LABEL_CIV"), SafeTooltip(Controls.CivIcon))
	AddInspectorRow(Locale.Lookup("LOC_CAI_LABEL_LEADER"), SafeTooltip(Controls.LeaderIcon))
	AddInspectorRow(Locale.Lookup("LOC_AD_SETUP_DIFFICULTY"), SafeTooltip(Controls.GameDifficulty))
	AddInspectorRow(Locale.Lookup("LOC_GAME_SPEED"), SafeTooltip(Controls.GameSpeed))

	-- Game options section
	AddHeader(Locale.Lookup("LOC_LOADSAVE_GAME_OPTIONS_HEADER_TITLE"))

	local rulesetName = LookupBundleOrText(fileInfo.RulesetName)
	AddInspectorRow(Locale.Lookup("LOC_LOADSAVE_GAME_OPTIONS_RULESET_TYPE_TITLE"), rulesetName)

	if fileInfo.EnabledGameModes then
		local modeNames = {}
		local enabledModes = Modding.GetGameModesFromConfigurationString(fileInfo.EnabledGameModes)
		for _, v in ipairs(enabledModes) do
			if v and v.Name and v.Name ~= "" then
				table.insert(modeNames, v.Name)
			end
		end
		if #modeNames > 0 then
			AddInspectorRow(Locale.Lookup("LOC_MULTIPLAYER_LOBBY_GAMEMODES_OFFICIAL"), table.concat(modeNames, ", "))
		end
	end

	local mapScriptName = LookupBundleOrText(fileInfo.MapScriptName)
	AddInspectorRow(Locale.Lookup("LOC_LOADSAVE_GAME_OPTIONS_MAP_TYPE_TITLE"), mapScriptName)

	local mapSizeName = LookupBundleOrText(fileInfo.MapSizeName)
	AddInspectorRow(Locale.Lookup("LOC_LOADSAVE_GAME_OPTIONS_MAP_SIZE_TITLE"), mapSizeName)

	if fileInfo.SavedByVersion and fileInfo.SavedByVersion ~= "" then
		AddInspectorRow(Locale.Lookup("LOC_LOADSAVE_SAVED_BY_VERSION_TITLE"), fileInfo.SavedByVersion)
	end

	if fileInfo.TunerActive == true then
		AddInspectorRow(Locale.Lookup("LOC_LOADSAVE_TUNER_ACTIVE_TITLE"), Locale.Lookup("LOC_YES_BUTTON"))
	end

	-- Additional content / mods section
	local mods
	if g_FileType == SaveFileTypes.GAME_CONFIGURATION then
		mods = fileInfo.EnabledMods or {}
	else
		mods = fileInfo.RequiredMods or {}
	end

	if #mods > 0 then
		AddHeader(Locale.Lookup("LOC_MAIN_MENU_ADDITIONAL_CONTENT"))

		local modErrors = Modding.CheckRequirements(mods, g_GameType)
		if not Challenges.IsNullChallengeUuid(fileInfo.GameChallengeUuid) then
			for _, v in ipairs(mods) do
				if modErrors and modErrors[v.Id] == "NotAllowed" then
					modErrors[v.Id] = nil
				end
			end
		end

		local modTitles = {}
		for _, v in ipairs(mods) do
			local title = nil
			local modHandle = Modding.GetModHandle(v.Id)
			if modHandle then
				local modInfo = Modding.GetModInfo(modHandle)
				if modInfo and modInfo.Name then
					title = Locale.Lookup(modInfo.Name)
				end
			end
			if not title or title == "" then
				title = LookupBundleOrText(v.Title)
			end

			if title and title ~= "" then
				if modErrors and modErrors[v.Id] then
					table.insert(modTitles, title .. ", " .. Locale.Lookup("LOC_GAME_START_ERROR_TITLE"))
				else
					table.insert(modTitles, title)
				end
			end
		end

		table.sort(modTitles, function(a, b) return Locale.Compare(a, b) == -1 end)

		for _, title in ipairs(modTitles) do
			AddInspectorRow(nil, title)
		end
	end
end

-- ---------------------------------------------------------------------------
-- Accessible pulldown overlays
-- ---------------------------------------------------------------------------
local function OpenSortDropdown()
	local optList = mgr:CreateUIWidget("List", {
		GetLabel = function()
			return Controls.WindowHeader:GetText()
		end,
	})

	optList:AddInputBinding({
		Key = Keys.VK_ESCAPE,
		Action = function()
			mgr:Pop()
			return true
		end
	})

	local options = {
		{ "LOC_SORTBY_LASTMODIFIED", SortByLastModified, 1 },
		{ "LOC_SORTBY_NAME", SortByName, 2 },
	}

	local selectedChild = nil
	for _, v in ipairs(options) do
		local labelKey = v[1]
		local sortFunc = v[2]
		local sortIndex = v[3]

		local child = mgr:CreateUIWidget("MenuItem", {
			GetLabel = function()
				return Locale.Lookup(labelKey)
			end,
			OnFocusEnter = function()
				UI.PlaySound("Main_Menu_Mouse_Over")
			end,
			OnClick = function()
				Controls.SortByPullDown:GetButton():LocalizeAndSetText(labelKey)
				g_CurrentSort = sortFunc

				if g_GameType == SaveTypes.WORLDBUILDER_MAP then
					Options.SetUserOption("Interface", "WorldBuilderMapBrowseSortDefault", sortIndex)
				else
					Options.SetUserOption("Interface", "SaveGameBrowseSortDefault", sortIndex)
				end
				Options.SaveOptions()

				RebuildFileList()
				mgr:Pop()
			end,
		})

		optList:AddChild(child)

		if GetCurrentSortLabel() == Locale.Lookup(labelKey) then
			selectedChild = child
		end
	end

	if selectedChild then
		optList.FocusedChild = selectedChild
	end

	mgr:Push(optList)
end

local function OpenDirectoryDropdown()
	if Controls.DirectoryPullDown:IsHidden() then
		return
	end

	local optList = mgr:CreateUIWidget("List", {
		GetLabel = function()
			return Controls.WindowHeader:GetText()
		end,
	})

	optList:AddInputBinding({
		Key = Keys.VK_ESCAPE,
		Action = function()
			mgr:Pop()
			return true
		end
	})

	local selectedChild = nil
	local usingVolumeName = nil

	if g_CurrentDirectorySegments then
		for i = #g_CurrentDirectorySegments, 1, -1 do
			local v = g_CurrentDirectorySegments[i]
			local displayName = (v.DisplayName ~= nil and v.DisplayName ~= "") and v.DisplayName or v.SegmentName

			local child = mgr:CreateUIWidget("MenuItem", {
				GetLabel = function()
					return displayName
				end,
				OnFocusEnter = function()
					UI.PlaySound("Main_Menu_Mouse_Over")
				end,
				OnClick = function()
					ChangeDirectoryLevelTo(i)
					mgr:Pop()
				end,
			})

			optList:AddChild(child)

			if displayName == GetCurrentDirectoryLabel() then
				selectedChild = child
			end

			if i == 1 then
				usingVolumeName = v.SegmentName
			end
		end
	end

	if g_VolumeList == nil then
		g_VolumeList = UI.GetVolumes(SaveLocations.LOCAL_STORAGE)
	end

	if g_VolumeList then
		for _, v in ipairs(g_VolumeList) do
			if usingVolumeName == nil or usingVolumeName ~= v.VolumeName then
				local displayName = (v.DisplayName ~= nil and v.DisplayName ~= "") and v.DisplayName or v.VolumeName
				local volumeName = v.VolumeName

				local child = mgr:CreateUIWidget("MenuItem", {
					GetLabel = function()
						return displayName
					end,
					OnFocusEnter = function()
						UI.PlaySound("Main_Menu_Mouse_Over")
					end,
					OnClick = function()
						ChangeVolumeTo(volumeName)
						mgr:Pop()
					end,
				})

				optList:AddChild(child)
			end
		end
	end

	if selectedChild then
		optList.FocusedChild = selectedChild
	end

	mgr:Push(optList)
end

-- ---------------------------------------------------------------------------
-- Rebuild the accessible file list
-- ---------------------------------------------------------------------------
local function RebuildFileListAccessibility()
	if not CAI_FileList then return end
	CAI_FileList:ClearChildren()

	if not g_FileList or #g_FileList == 0 then
		local emptyChild = mgr:CreateUIWidget("MenuItem", {
			GetLabel = function()
				return Controls.NoGames:GetText() or ""
			end,
		})
		CAI_FileList:AddChild(emptyChild)
		CAI_FileList.FocusedChild = emptyChild
		return
	end

	local focusIdx = g_iSelectedFileEntry
	if not focusIdx or focusIdx < 1 or focusIdx > #g_FileList then
		focusIdx = 1
	end

	local focusedChild = nil

	for idx, entry in ipairs(g_FileList) do
		local child = mgr:CreateUIWidget("MenuItem", {
			GetLabel = function()
				return GetEntryLabel(idx, entry)
			end,
			GetTooltip = function()
				return GetShortEntrySummary()
			end,
			GetValue = function()
				return (g_iSelectedFileEntry == idx)
					and Locale.Lookup("LOC_OPTIONS_ENABLED")
					or ""
			end,
			OnFocusEnter = function()
				UI.PlaySound("Main_Menu_Mouse_Over")
				if g_iSelectedFileEntry ~= idx then
					SetSelected(idx)
					RebuildInspectorAccessibility()
				end
			end,
			OnClick = function()
				OnActionButton()
			end,
		})

		child:AddInputBinding({
			Key = Keys.VK_DELETE,
			Action = function()
				if not Controls.Delete:IsHidden() then
					OnDelete()
					return true
				end
				return false
			end
		})

		CAI_FileList:AddChild(child)

		if idx == focusIdx then
			focusedChild = child
		end
	end

	if focusedChild then
		CAI_FileList.FocusedChild = focusedChild
	end
end

-- ---------------------------------------------------------------------------
-- Build panel
-- ---------------------------------------------------------------------------
local function BuildPanel()
	CAI_Panel = mgr:CreateUIWidget("Dialog", {
		GetLabel = function()
			return Controls.WindowHeader:GetText()
		end,
		SpeechSettings = { Role = false },
	})

	CAI_Panel:AddInputBinding({
		Key = Keys.VK_ESCAPE,
		Action = function()
			OnBack()
			return true
		end
	})

	CAI_Panel:AddChild(mgr:CreateUIWidget("Button", {
		GetLabel = function()
			return Controls.BackButton:GetText()
		end,
		OnFocusEnter = function()
			UI.PlaySound("Main_Menu_Mouse_Over")
		end,
		OnClick = function()
			OnBack()
		end,
	}))

	local autoSaveCheckbox = mgr:CreateUIWidget("Checkbox", {
		GetLabel = function()
			return Controls.AutoCheck:GetText()
		end,
		GetValue = function()
			return Controls.AutoCheck:IsSelected()
				and Locale.Lookup("LOC_OPTIONS_ENABLED")
				or Locale.Lookup("LOC_OPTIONS_DISABLED")
		end,
		IsHidden = function()
			return Controls.AutoCheck:IsHidden()
		end,
		Toggle = function()
			OnAutoCheck()
		end,
		OnFocusEnter = function()
			UI.PlaySound("Main_Menu_Mouse_Over")
		end,
	})
	CAI_Panel:AddChild(autoSaveCheckbox)

	CAI_Panel:AddChild(mgr:CreateUIWidget("Checkbox", {
		GetLabel = function()
			local base
			if not Controls.CloudDummy:IsHidden() then
				base = Controls.CloudDummy:GetText()
			else
				base = Controls.CloudCheck:GetText()
			end

			local isNew = (not Controls.CheckNewIndicator:IsHidden()) or (not Controls.DummyNewIndicator:IsHidden())
			if isNew then
				-- TODO: localize
				return base .. ", new"
			end

			return base
		end,
		GetTooltip = function()
			if not Controls.CloudDummy:IsHidden() then
				return SafeTooltip(Controls.CloudDummy)
			end
			return SafeTooltip(Controls.CloudCheck)
		end,
		GetValue = function()
			return Controls.CloudCheck:IsSelected()
				and Locale.Lookup("LOC_OPTIONS_ENABLED")
				or Locale.Lookup("LOC_OPTIONS_DISABLED")
		end,
		IsHidden = function()
			return Controls.CloudCheck:IsHidden() and Controls.CloudDummy:IsHidden()
		end,
		IsDisabled = function()
			if not Controls.CloudDummy:IsHidden() then
				return Controls.CloudDummy:IsDisabled()
			end
			return Controls.CloudCheck:IsDisabled()
		end,
		Toggle = function()
			if not Controls.CloudCheck:IsDisabled() then
				OnCloudCheck()
			end
		end,
		OnFocusEnter = function()
			UI.PlaySound("Main_Menu_Mouse_Over")
		end,
	}))

	CAI_Panel:AddChild(mgr:CreateUIWidget("DropdownMenu", {
		GetLabel = function()
			return Locale.Lookup("LOC_SORTBY_NAME")
		end,
		GetValue = function()
			return GetCurrentSortLabel()
		end,
		IsHidden = function()
			return Controls.SortByPullDown:IsHidden()
		end,
		OnFocusEnter = function()
			UI.PlaySound("Main_Menu_Mouse_Over")
		end,
		OnClick = function()
			OpenSortDropdown()
		end,
	}))

	CAI_Panel:AddChild(mgr:CreateUIWidget("DropdownMenu", {
		GetLabel = function()
			return GetCurrentDirectoryLabel()
		end,
		IsHidden = function()
			return Controls.DirectoryPullDown:IsHidden()
		end,
		OnFocusEnter = function()
			UI.PlaySound("Main_Menu_Mouse_Over")
		end,
		OnClick = function()
			OpenDirectoryDropdown()
		end,
	}))

	CAI_FileList = mgr:CreateUIWidget("List", {
		GetLabel = function()
			return Controls.WindowHeader:GetText()
		end,
	})
	CAI_Panel:AddChild(CAI_FileList)

	CAI_InspectorList = mgr:CreateUIWidget("List", {
		GetLabel = function()
			local name = SafeText(Controls.FileName)
			-- TODO: localize this with arguments
			return name ~= "" and ("Details, " .. name) or "Details"
		end,
		IsHidden = function()
			return Controls.SelectedFile:IsHidden()
		end,
	})
	CAI_Panel:AddChild(CAI_InspectorList)

	CAI_Panel:AddChild(mgr:CreateUIWidget("Button", {
		GetLabel = function()
			return Controls.ActionButton:GetText()
		end,
		GetTooltip = function()
			return SafeTooltip(Controls.ActionButton)
		end,
		IsDisabled = function()
			return Controls.ActionButton:IsDisabled()
		end,
		IsHidden = function()
			return Controls.ActionButton:IsHidden()
		end,
		OnFocusEnter = function()
			UI.PlaySound("Main_Menu_Mouse_Over")
		end,
		OnClick = function()
			OnActionButton()
		end,
	}))

	CAI_Panel:AddChild(mgr:CreateUIWidget("Button", {
		GetLabel = function()
			return Controls.Delete:GetText()
		end,
		IsHidden = function()
			return Controls.Delete:IsHidden()
		end,
		IsDisabled = function()
			return Controls.Delete and Controls.Delete:IsDisabled()
		end,
		OnFocusEnter = function()
			UI.PlaySound("Main_Menu_Mouse_Over")
		end,
		OnClick = function()
			OnDelete()
		end,
	}))

	CAI_Panel.FocusedChild = autoSaveCheckbox
end

-- ---------------------------------------------------------------------------
-- Wrapped show/hide only
-- ---------------------------------------------------------------------------
OnShow = WrapFunc(OnShow, function(orig, ...)
	orig(...)

	if CAI_Panel and mgr:HasWidget(CAI_Panel) then
		mgr:Pop()
	end

	CAI_Panel = nil
	CAI_FileList = nil
	CAI_InspectorList = nil

	BuildPanel()

	ContextPtr:SetInputHandler(function(input)
		if mgr:HandleInput(input) then return true end
		return OnInputHandler(input)
	end, true)

	LuaEvents.FileListQueryComplete.Remove(RebuildFileListAccessibility)
	LuaEvents.FileListQueryComplete.Add(RebuildFileListAccessibility)
	mgr:Push(CAI_Panel)
end)

OnHide = WrapFunc(OnHide, function(orig, ...)
	LuaEvents.FileListQueryComplete.Remove(RebuildFileListAccessibility)

	orig(...)

	ClosePanel()
end)

-- ---------------------------------------------------------------------------
-- Re-register wrapped handlers
-- ---------------------------------------------------------------------------
ContextPtr:SetShowHandler(OnShow)
ContextPtr:SetHideHandler(OnHide)
ContextPtr:SetInputHandler(function(input)
	if mgr:HandleInput(input) then return true end
	return OnInputHandler(input)
end, true)
