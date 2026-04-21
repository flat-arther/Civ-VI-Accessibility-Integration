include("MapSelect_Base")
include("caiUtils")
local mgr = ExposedMembers.CAI_UIManager

local CAI_Panel = nil
local CAI_MapList = nil
local CAI_TabBar = nil
local m_intentionalClose = false

local kSortTabs = {
	{ 0, "LOC_SETUP_MAP_ALL_MAPS",            function() return Controls.AllMapsSelector end },
	{ 1, "LOC_SETUP_MAP_OFFICIAL_MAPS",        function() return Controls.OfficialMapsSelector end },
	{ 2, "LOC_SETUP_MAP_WORLD_BUILDER_MAPS",   function() return Controls.WorldBuilderMapsSelector end },
}

local function RebuildMapList()
	if not CAI_MapList then return end
	CAI_MapList:ClearChildren()

	if not m_kAllMaps then return end
	for k, v in pairs(m_kAllMaps) do
		local include = false
		if m_sortType == 0 then
			include = true
		elseif m_sortType == 1 and v.IsOfficial then
			include = true
		elseif m_sortType == 2 and v.IsWorldBuilder then
			include = true
		end

		if include then
			local mapData = v
			local isSelected = (m_selectedMapValue == mapData.Value)
				or (m_lastSetMapValue == mapData.Value and m_selectedMapValue == nil)
				or (m_selectedMap == nil and m_lastSetMapValue == nil and mapData.RawName == DEFAULT_MAP_RAWNAME)

			local child = mgr:CreateUIWidget("MenuItem", {
				GetLabel     = function() return Locale.Lookup(mapData.RawName) end,
				GetTooltip   = function() return Locale.Lookup(mapData.RawDescription) end,
				OnFocusEnter = function()
					UI.PlaySound("Main_Menu_Mouse_Over")
					-- Sync visual selection
					local instances = m_mapSelectorIM and m_mapSelectorIM.m_AllocatedInstances
					if instances then
						for _, inst in ipairs(instances) do
							if inst.MapName:GetText() == Locale.Lookup(mapData.RawName) then
								OnMapButton(mapData, inst.MapButton)
								break
							end
						end
					end
				end,
				OnClick      = function()
					m_selectedMapValue = mapData.Value
					OnSelectMapButton()
				end,
			})
			CAI_MapList:AddChild(child)

			if isSelected then
				CAI_MapList.FocusedChild = child
			end
		end
	end
end

local function BuildPanel()
	CAI_Panel = mgr:CreateUIWidget("Dialog", {
		GetLabel = function() return Controls.WindowTitle:GetText() end,
		SpeechSettings = { Role = false },
	})
	CAI_Panel:AddInputBinding({Key = Keys.VK_ESCAPE, Action = function()
		Close()
		return true
	end})

	-- Sort tab bar (first child of panel, like Options)
	CAI_TabBar = mgr:CreateUIWidget("TabBar")
	CAI_Panel:AddChild(CAI_TabBar)

	for _, spec in ipairs(kSortTabs) do
		local sortNum = spec[1]
		local locKey = spec[2]
		local getSelector = spec[3]
		CAI_TabBar:AddChild(mgr:CreateUIWidget("Tab", {
			GetLabel     = function() return Locale.Lookup(locKey) end,
			OnFocusEnter = function()
				UI.PlaySound("Main_Menu_Mouse_Over")
				if m_sortType ~= sortNum then
					OnSortButton(sortNum, getSelector())
					RebuildMapList()
				end
			end,
			OnClick      = function()
				OnSortButton(sortNum, getSelector())
				RebuildMapList()
			end,
		}))
	end

	-- Map list
	CAI_MapList = mgr:CreateUIWidget("List")
	CAI_Panel:AddChild(CAI_MapList)

	-- Action buttons
	CAI_Panel:AddChild(mgr:CreateUIWidget("Button", {
		GetLabel     = function() return Controls.MapSelectionButton:GetText() end,
		OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
		OnClick      = function() OnSelectMapButton() end,
	}))
	CAI_Panel:AddChild(mgr:CreateUIWidget("Button", {
		GetLabel     = function() return Controls.CloseButton:GetText() end,
		OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
		OnClick      = function() Close() end,
	}))
end

local function ClosePanel()
	if CAI_Panel and mgr:HasWidget(CAI_Panel) then
		mgr:Pop()
	end
end

-- Wrap Close to track intentional closes
Close = WrapFunc(Close, function(orig)
	m_intentionalClose = true
	orig()
end)

-- Wrap LoadMaps to rebuild accessible list when maps are populated
LoadMaps = WrapFunc(LoadMaps, function(orig, k)
	orig(k)
	if not CAI_Panel then BuildPanel() end
	RebuildMapList()
end)

-- Wrap PopulateMapSelectPanel to rebuild on sort changes
PopulateMapSelectPanel = WrapFunc(PopulateMapSelectPanel, function(orig)
	orig()
	RebuildMapList()
end)

-- Use show/hide handlers for push/pop
ContextPtr:SetShowHandler(function()
	-- Clean up stale panel if still on stack (e.g. after a non-intentional hide)
	if CAI_Panel and mgr:HasWidget(CAI_Panel) then
		mgr:Pop()
	end
	-- Rebuild fresh each show
	CAI_Panel = nil
	CAI_MapList = nil
	CAI_TabBar = nil
	m_intentionalClose = false
	BuildPanel()
	RebuildMapList()
	ContextPtr:SetInputHandler(function(input)
		if mgr:HandleInput(input) then return true end
		local uiMsg = input:GetMessageType()
		if uiMsg == KeyEvents.KeyUp and input:GetKey() == Keys.VK_ESCAPE then
			Close()
		end
		return true
	end, true)
	mgr:Push(CAI_Panel)
end)

ContextPtr:SetHideHandler(function()
	if m_intentionalClose then
		ClosePanel()
		m_intentionalClose = false
	end
end)