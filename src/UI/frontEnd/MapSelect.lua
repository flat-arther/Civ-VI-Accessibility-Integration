
include("InstanceManager");

-- ===========================================================================
-- Members
-- ===========================================================================
m_mapSelectorIM	=	InstanceManager:new("MapPreviewInstance",	"MapButton", Controls.MapSelectPanel);
m_mapInfoIM =		InstanceManager:new("MapInfoInstance", "MapContainer", Controls.MapInfoPanel);

local m_uiMapInfo		:table = {};
local m_kAllMaps		:table;
local m_selectedMapValue :string;
local m_lastSetMapValue	:string;
local m_selectedMap		:table;

local m_sortType :number = 0;
local m_lastSelectedSort :table;

local DEFAULT_MAP_RAWNAME = "LOC_MAP_CONTINENTS";

-- ===========================================================================
function Close()
	ContextPtr:SetHide(true);
end

-- ===========================================================================
function OnBackButton()
	Close();
end

-- ===========================================================================
function OnSelectMapButton()
	m_lastSetMapValue = m_selectedMapValue;
	LuaEvents.MapSelect_SetMapByValue( m_selectedMapValue );
	Close();
end

-- ===========================================================================
function OnSortButton( num:number, button:table )
	button:SetCheck(true);
	if(m_lastSelectedSort == button)then
		return;
	end
	m_lastSelectedSort = button;
	m_sortType = num;
	PopulateMapSelectPanel();
end

-- ===========================================================================
function OnMapButton(kMapData :table, c :table)
	
	m_uiMapInfo.MapName:SetText(Locale.Lookup(kMapData.RawName));
	m_uiMapInfo.MapDescription:SetText(Locale.Lookup(kMapData.RawDescription));
	m_uiMapInfo.MapImagePreview:SetTexture(kMapData.Texture);
	m_selectedMapValue = kMapData.Value;	

	c:SetSelected(true);

	if(m_selectedMap == c) then return; end

	if(m_selectedMap ~= nil) then
		m_selectedMap:SetSelected(false);
	end
	m_selectedMap = c;
end

-- ===========================================================================
function LoadMaps(k:table)
	m_kAllMaps = k;
	m_selectedMap = nil;
	m_selectedMapValue = nil;
	PopulateMapSelectPanel();
end

-- ===========================================================================
function PopulateMapSelectPanel()

	if(m_mapSelectorIM ~= nil) then
		m_mapSelectorIM:ResetInstances();
	end
	
	for k, v in pairs(m_kAllMaps) do
		if(m_sortType == 1 and v.IsOfficial) then
			PopulateMapButton(m_kAllMaps[k]);
		elseif(m_sortType == 2 and v.IsWorldBuilder) then
			PopulateMapButton(m_kAllMaps[k]);
		elseif(m_sortType == 0) then
			PopulateMapButton(m_kAllMaps[k]);
		end
	end
end

-- ===========================================================================
function PopulateMapButton(kMapData:table)
	if(kMapData.Texture == nil) then
		kMapData.Texture = "Map_Community";
	end

	local uiMap :table = m_mapSelectorIM:GetInstance();
	uiMap.MapImagePreview:SetTexture(kMapData.Texture);
	uiMap.MapName:SetText(Locale.Lookup(kMapData.RawName));
	uiMap.MapButton:SetToolTipString(Locale.Lookup(kMapData.RawDescription));
	uiMap.MapButton:RegisterCallback( Mouse.eLClick, function() OnMapButton(kMapData, uiMap.MapButton); end );
	uiMap.MapButton:RegisterCallback( Mouse.eLDblClick,function() m_selectedMapValue = kMapData.Value; OnSelectMapButton(); end);
	uiMap.MapButton:SetSelected(false);

	if(m_selectedMapValue == kMapData.Value)then
		OnMapButton(kMapData, uiMap.MapButton);
	elseif(m_lastSetMapValue == kMapData.Value and m_selectedMapValue == nil) then
		OnMapButton(kMapData, uiMap.MapButton);

	--This will only hit true the first time the screen is opened
	elseif(m_selectedMap == nil and m_lastSetMapValue == nil) then
		if(kMapData.RawName == DEFAULT_MAP_RAWNAME) then
			OnMapButton(kMapData, uiMap.MapButton);
		end
	end
end

-- ===========================================================================
function ClearMapData()
	m_lastSetMapValue = nil;
end

-- ===========================================================================
function OnInputHandler( pInputStruct:table )
	local uiMsg = pInputStruct:GetMessageType();
	if uiMsg == KeyEvents.KeyUp then
		local key:number = pInputStruct:GetKey();
		if key == Keys.VK_ESCAPE then
			Close();
		end
	end
	return true;
end

-- ===========================================================================
function Initialize()
	ContextPtr:SetInputHandler( OnInputHandler, true );

	Controls.CloseButton:RegisterCallback( Mouse.eLClick, OnBackButton );
	Controls.CloseButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.MapSelectionButton:RegisterCallback( Mouse.eLClick, OnSelectMapButton );
	Controls.MapSelectionButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.AllMapsSelector:RegisterCallback( Mouse.eLClick, function() OnSortButton(0, Controls.AllMapsSelector); end );
	Controls.AllMapsButton:RegisterCallback( Mouse.eLClick, function() OnSortButton(0, Controls.AllMapsSelector); end );
	Controls.AllMapsSelector:SetCheck(true);
	Controls.OfficialMapsSelector:RegisterCallback( Mouse.eLClick, function() OnSortButton(1, Controls.OfficialMapsSelector); end );
	Controls.OfficialMapsButton:RegisterCallback( Mouse.eLClick, function() OnSortButton(1, Controls.OfficialMapsSelector); end );
	Controls.WorldBuilderMapsSelector:RegisterCallback( Mouse.eLClick, function() OnSortButton(2, Controls.WorldBuilderMapsSelector); end );
	Controls.WorldBuilderMapsButton:RegisterCallback( Mouse.eLClick, function() OnSortButton(2, Controls.WorldBuilderMapsSelector); end );

	LuaEvents.MapSelect_PopulatedMaps.Add( LoadMaps );
	LuaEvents.MapSelect_ClearMapData.Add( ClearMapData );

	m_uiMapInfo = m_mapInfoIM:GetInstance();
end
--#Accessibility integration
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

local function MakeButton(labelCtrl, onClick)
	local b = mgr:CreateWidget(mgr:GenerateWidgetId("CAIMapSelectButton"), "Button", {
		Label = function() return labelCtrl:GetText() end,
	})
	b:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
	b:On("activate", onClick)
	return b
end

local function RebuildMapList()
	if not CAI_MapList then return end
	local capture = mgr:CaptureFocusKey(CAI_MapList)
	CAI_MapList:ClearChildren()

	if not m_kAllMaps then
		mgr:RestoreFocus(CAI_MapList, capture)
		return
	end
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

			local child = mgr:CreateWidget(mgr:GenerateWidgetId("CAIMapSelectMenuItem"), "MenuItem", {
				Label = function() return Locale.Lookup(mapData.RawName) end,
				Tooltip = function() return Locale.Lookup(mapData.RawDescription) end,
				FocusKey = "map:" .. tostring(mapData.Value),
			})
			child:On("focus_enter", function()
				UI.PlaySound("Main_Menu_Mouse_Over")
				local instances = m_mapSelectorIM and m_mapSelectorIM.m_AllocatedInstances
				if instances then
					for _, inst in ipairs(instances) do
						if inst.MapName:GetText() == Locale.Lookup(mapData.RawName) then
							OnMapButton(mapData, inst.MapButton)
							break
						end
					end
				end
			end)
			child:On("activate", function()
				m_selectedMapValue = mapData.Value
				OnSelectMapButton()
			end)
			CAI_MapList:AddChild(child)

			if isSelected then
				CAI_MapList:SetDefaultIndex(#CAI_MapList.Children)
			end
		end
	end
	mgr:RestoreFocus(CAI_MapList, capture)
end

local function BuildPanel()
	CAI_Panel = mgr:CreateWidget(mgr:GenerateWidgetId("CAIMapSelectDialog"), "Dialog", {
		Label = function() return Controls.WindowTitle:GetText() end,
		SpeechSettings = { Role = false },
	})
	CAI_Panel:AddInputBinding({Key = Keys.VK_ESCAPE, Action = function()
		Close()
		return true
	end})

	-- Sort selector as a horizontal list of buttons (tabs of the old TabBar).
	CAI_TabBar = mgr:CreateWidget(mgr:GenerateWidgetId("CAIMapSelectTabBar"), "HorizontalList")
	CAI_Panel:AddChild(CAI_TabBar)

	for _, spec in ipairs(kSortTabs) do
		local sortNum = spec[1]
		local locKey = spec[2]
		local getSelector = spec[3]
		local tab = mgr:CreateWidget(mgr:GenerateWidgetId("CAIMapSelectTab"), "Button", {
			Label = function() return Locale.Lookup(locKey) end,
		})
		tab:On("focus_enter", function()
			UI.PlaySound("Main_Menu_Mouse_Over")
			if m_sortType ~= sortNum then
				OnSortButton(sortNum, getSelector())
				RebuildMapList()
			end
		end)
		tab:On("activate", function()
			OnSortButton(sortNum, getSelector())
			RebuildMapList()
		end)
		CAI_TabBar:AddChild(tab)
	end

	CAI_MapList = mgr:CreateWidget(mgr:GenerateWidgetId("CAIMapSelectList"), "List")
	CAI_Panel:AddChild(CAI_MapList)

	CAI_Panel:AddChild(MakeButton(Controls.MapSelectionButton, function() OnSelectMapButton() end))
	CAI_Panel:AddChild(MakeButton(Controls.CloseButton,        function() Close() end))
end

local function ClosePanel()
	if CAI_Panel then
		mgr:RemoveFromStack(CAI_Panel:GetId())
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
	if CAI_Panel then
		mgr:RemoveFromStack(CAI_Panel:GetId())
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
--#End of accessibility integration
Initialize();
