-- Copyright 2020, Firaxis Games

include("InstanceManager");
include("PlayerSetupLogic");
include("Civ6Common");

-- ===========================================================================
-- Members
-- ===========================================================================

local m_pItemIM:table = InstanceManager:new("ItemInstance",	"Button", Controls.ItemsPanel);
local m_pUniqueAbilityIM:table = InstanceManager:new("UniqueAbilityInstance", "Top", Controls.UniqueAbilityStack);

local m_kParameter:table = nil		-- Reference to the parameter being used. 
local m_kSelectedValues:table = nil	-- Table of string->boolean that represents checked off items.
local m_kItemList:table = nil;		-- Table of controls for select all/none

local m_bInvertSelection:boolean = false;

local m_numSelected:number = 0;
local m_minSelected:number = 2;

-- ===========================================================================
function Close()	
	-- Clear any temporary global variables.
	m_kParameter = nil;
	m_kSelectedValues = nil;

	ContextPtr:SetHide(true);
end

-- ===========================================================================
function IsItemSelected(item: table) 
	return m_kSelectedValues[item.Value] == true;
end

-- ===========================================================================
function OnBackButton()
	Close();
end

-- ===========================================================================
function OnConfirmChanges()
	-- Generate sorted list from selected values.
	local values = {}
	for k,v in pairs(m_kSelectedValues) do
		if(v) then
			table.insert(values, k);
		end
	end

	LuaEvents.LeaderPicker_SetParameterValues(m_kParameter.ParameterId, values);
	Close();
end

-- ===========================================================================
function OnItemSelect(item :table, checkBox :table)
	local value = item.Value;
	local selected:boolean = not m_kSelectedValues[value];

	m_kSelectedValues[item.Value] = selected;
	if m_bInvertSelection then
		checkBox:SetCheck(not selected);
	else
		checkBox:SetCheck(selected);
	end

	RefreshCountWarning();
end

-- ===========================================================================
function OnItemFocus(item :table)
	if(item) then
		local kPlayerInfo:table = GetPlayerInfo(item.Domain, item.Value);
		if kPlayerInfo then
			local backColor, frontColor = UI.GetPlayerColorValues(kPlayerInfo.PlayerColor);

			-- Icons
			Controls.FocusedCivIcon:SetIcon(kPlayerInfo.CivilizationIcon);
			Controls.FocusedCivIcon:SetColor(frontColor);
			Controls.FocusedCivIconBacking:SetColor(backColor);
			Controls.FocusedLeaderIcon:SetIcon(kPlayerInfo.LeaderIcon);

			-- Description
			Controls.FocusedLeaderName:SetText(Locale.ToUpper(kPlayerInfo.LeaderName));
			if kPlayerInfo.LeaderAbility then
				Controls.FocusedLeaderAbilityName:SetText(Locale.ToUpper(kPlayerInfo.LeaderAbility.Name));
				Controls.FocusedLeaderAbilityDesc:SetText(Locale.Lookup(kPlayerInfo.LeaderAbility.Description));
			end

			Controls.FocusedCivName:SetText(Locale.ToUpper(kPlayerInfo.CivilizationName));
			if kPlayerInfo.CivilizationAbility then
				Controls.FocusedCivAbilityName:SetText(Locale.ToUpper(kPlayerInfo.CivilizationAbility.Name));
				Controls.FocusedCivAbilityDesc:SetText(Locale.Lookup(kPlayerInfo.CivilizationAbility.Description));
			end

			m_pUniqueAbilityIM:ResetInstances();
			if kPlayerInfo.Uniques then
				for i, kAbility in ipairs(kPlayerInfo.Uniques) do
					local pInst:table = m_pUniqueAbilityIM:GetInstance();
					pInst.Icon:SetIcon(kAbility.Icon);
					pInst.Name:SetText(Locale.ToUpper(kAbility.Name));
					pInst.Description:SetText(Locale.Lookup(kAbility.Description));
				end
			end
		end
	end
end

-- ===========================================================================
function SetAllItems(bState: boolean)
	for _, node in ipairs(m_kItemList) do
		local item:table = node["item"];
		local checkBox:table = node["checkbox"];

		checkBox:SetCheck(bState);
		if m_bInvertSelection then
			m_kSelectedValues[item.Value] = not bState;
		else
			m_kSelectedValues[item.Value] = bState;
		end
	end
end

-- ===========================================================================
function OnSelectAll()
	SetAllItems(true);
	RefreshCountWarning();
end

-- ===========================================================================
function OnSelectNone()
	SetAllItems(false);
	RefreshCountWarning();
end

-- ===========================================================================
function SelectLeadersWithNoWins()
	local kLeaderProgress:table = HallofFame.GetLeaderProgress(GameConfiguration.GetRuleSet())

	for _, kNode in ipairs(m_kItemList) do
		local kItem:table = kNode["item"];
		local uiCheckBox:table = kNode["checkbox"];

		local shouldSelect:boolean = false;

		local kLeaderEntry:table = kLeaderProgress[kItem.Value];
		if kLeaderEntry and kLeaderEntry.MostRecentVictoryType == nil then
			shouldSelect = true;
		end

		uiCheckBox:SetCheck(shouldSelect);
		if m_bInvertSelection then
			m_kSelectedValues[kItem.Value] = not shouldSelect;
		else
			m_kSelectedValues[kItem.Value] = shouldSelect;
		end
	end

	RefreshCountWarning();
end

-- ===========================================================================
function RemoveRandomLeadersFromParameter( kParameter:table )
	for i = #kParameter.AllValues, 1, -1 do
		local kItem:table = kParameter.AllValues[i];
		if kItem.Value == "RANDOM" or kItem.Value == "RANDOM_POOL1" or kItem.Value == "RANDOM_POOL2" then
			table.remove(kParameter.AllValues, i);
		end
	end

	for i = #kParameter.Values, 1, -1 do
		local kItem:table = kParameter.Values[i];
		if kItem.Value == "RANDOM" or kItem.Value == "RANDOM_POOL1" or kItem.Value == "RANDOM_POOL2" then
			table.remove(kParameter.Values, i);
		end
	end
end

-- ===========================================================================
function ParameterInitialize( kParameter:table, pGameParameters:table )

	RemoveRandomLeadersFromParameter(kParameter);

	m_kParameter = kParameter;
	m_kSelectedValues = {};

	if (kParameter.UxHint ~= nil and kParameter.UxHint == "InvertSelection") then
		m_bInvertSelection = true;
	else
		m_bInvertSelection = false;
	end

	if (kParameter.Value) then
		for i,v in ipairs(kParameter.Value) do
			m_kSelectedValues[v.Value] = true;
		end
	end

	Controls.TopDescription:SetText(kParameter.Description);
	Controls.WindowTitle:SetText(kParameter.Name);
	m_pItemIM:ResetInstances();

	RefreshList();

    InitPresets();

	OnItemFocus(kParameter.Values[1]);
end

-- ===========================================================================
function RefreshList( sortByFunc )

	m_numSelected = 0;
	m_kItemList = {};

	-- Sort list
	table.sort(m_kParameter.Values, sortByFunc ~= nil and sortByFunc or SortByName);

	-- Update UI
	m_pItemIM:ResetInstances();
	for i, v in ipairs(m_kParameter.Values) do
		InitializeItem(v);
	end
end

-- ===========================================================================
function RefreshCountWarning()
	local numSelected:number = 0;

	for i, v in ipairs(m_kParameter.Values) do
		if not IsItemSelected(v) then
			numSelected = numSelected + 1;
		end
	end

	if numSelected < m_minSelected then
		Controls.ConfirmButton:SetDisabled(true);
		Controls.CountWarning:SetText(Locale.ToUpper(Locale.Lookup("LOC_LEADER_POOL_COUNTER_WARNING", m_minSelected)));
	else
		Controls.ConfirmButton:SetDisabled(false);
		Controls.CountWarning:SetText("");
	end
end

-- ===========================================================================
function SortByName(kItemA:table, kItemB:table)
	return Locale.Compare(kItemA.Name, kItemB.Name) == -1;
end

-- ===========================================================================
function InitPresets()

	local uiButton:object = Controls.PresetPulldown:GetButton();
	uiButton:SetText(Locale.Lookup("LOC_LEADER_PICK_PRESET_ALL"));

	Controls.PresetPulldown:ClearEntries();

	local pNameEntryInst:object = {};
	Controls.PresetPulldown:BuildEntry( "InstanceOne", pNameEntryInst );
	pNameEntryInst.Button:SetText(Locale.Lookup("LOC_LEADER_PICK_PRESET_ALL"));
	pNameEntryInst.Button:RegisterCallback( Mouse.eLClick, 
		function() 
			Controls.PresetPulldown:GetButton():SetText(Locale.Lookup("LOC_LEADER_PICK_PRESET_ALL"));
			OnSelectAll();
		end );

	local pTypeEntryInst:object = {};
	Controls.PresetPulldown:BuildEntry( "InstanceOne", pTypeEntryInst );
	pTypeEntryInst.Button:SetText(Locale.Lookup("LOC_LEADER_PICK_PRESET_NONE"));
	pTypeEntryInst.Button:RegisterCallback( Mouse.eLClick, 
		function() 
			Controls.PresetPulldown:GetButton():SetText(Locale.Lookup("LOC_LEADER_PICK_PRESET_NONE"));
			OnSelectNone();
		end );

	local pTypeEntryInst:object = {};
	Controls.PresetPulldown:BuildEntry( "InstanceOne", pTypeEntryInst );
	pTypeEntryInst.Button:SetText(Locale.Lookup("LOC_LEADER_PICK_PRESET_NO_WINS"));
	pTypeEntryInst.Button:RegisterCallback( Mouse.eLClick, 
		function() 
			Controls.PresetPulldown:GetButton():SetText(Locale.Lookup("LOC_LEADER_PICK_PRESET_NO_WINS"));
			SelectLeadersWithNoWins();
		end );

	Controls.PresetPulldown:CalculateInternals();
end

-- ===========================================================================
function InitializeItem(item:table)

	local c: table = m_pItemIM:GetInstance();
	c.Name:SetText(item.Name);

	local kPlayerInfo:table = GetPlayerInfo(item.Domain, item.Value);
	if kPlayerInfo then
		c.LeaderIcon:SetIcon(kPlayerInfo.LeaderIcon);
	end

	c.Button:RegisterCallback( Mouse.eMouseEnter, function() OnItemFocus(item); end );
	c.Button:RegisterCallback( Mouse.eLClick, function() OnItemSelect(item, c.Selected, c.Button); end );
	c.Selected:RegisterCallback( Mouse.eLClick, function() OnItemSelect(item, c.Selected, c.Button); end );
	if m_bInvertSelection then
		c.Selected:SetCheck(not IsItemSelected(item));
	else
		c.Selected:SetCheck(IsItemSelected(item));
		m_numSelected = m_numSelected + 1;
	end

	local listItem:table = {};
	listItem["item"] = item;
	listItem["checkbox"] = c.Selected;
	table.insert(m_kItemList, listItem);
end

-- ===========================================================================
function OnShutdown()
	Close();
	m_pItemIM:DestroyInstances();
	LuaEvents.LeaderPicker_Initialize.Remove( ParameterInitialize );
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
	ContextPtr:SetShutdown( OnShutdown );
	ContextPtr:SetInputHandler( OnInputHandler, true );

	local OnMouseEnter = function() UI.PlaySound("Main_Menu_Mouse_Over"); end;

	Controls.CloseButton:RegisterCallback( Mouse.eLClick, OnBackButton );
	Controls.CloseButton:RegisterCallback( Mouse.eMouseEnter, OnMouseEnter);
	Controls.ConfirmButton:RegisterCallback( Mouse.eLClick, OnConfirmChanges );
	Controls.ConfirmButton:RegisterCallback( Mouse.eMouseEnter, OnMouseEnter);

	LuaEvents.LeaderPicker_Initialize.Add( ParameterInitialize );
end
--#Accessibility integration
include("caiUtils")
local mgr = ExposedMembers.CAI_UIManager

local CAI_Panel = nil
local CAI_ItemList = nil
local m_intentionalClose = false

-- ---------------------------------------------------------------------------
-- Rebuild the accessible item list from vanilla's m_kItemList
-- ---------------------------------------------------------------------------
local function MakeButton(labelCtrl, onClick, disabledCtrl)
	local b = mgr:CreateWidget(mgr:GenerateWidgetId("CAILeaderPickerButton"), "Button", {
		Label = function() return labelCtrl:GetText() end,
	})
	if disabledCtrl then
		b:SetDisabledPredicate(function() return disabledCtrl:IsDisabled() end)
	end
	b:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
	b:On("activate", onClick)
	return b
end

local function RebuildItemList()
	if not CAI_ItemList then return end
	local capture = mgr:CaptureFocusKey(CAI_ItemList)
	CAI_ItemList:ClearChildren()

	if m_kItemList then
		for idx, node in ipairs(m_kItemList) do
			local item = node["item"]
			local checkBox = node["checkbox"]

			local child = mgr:CreateWidget(mgr:GenerateWidgetId("CAILeaderPickerCheckbox"), "Checkbox", {
				Label = function() return item.Name end,
				Tooltip = function()
					OnItemFocus(item)
					local leader = Controls.FocusedLeaderName:GetText() or ""
					local civ = Controls.FocusedCivName:GetText() or ""
					if civ ~= "" then return leader .. ", " .. civ end
					return leader
				end,
				ValueGetter = function()
					return checkBox:IsChecked()
						and Locale.Lookup("LOC_OPTIONS_ENABLED")
						or Locale.Lookup("LOC_OPTIONS_DISABLED")
				end,
				FocusKey = "lp:item:" .. tostring(idx),
			})
			child:On("value_changed", function() OnItemSelect(item, checkBox) end)
			child:On("focus_enter", function()
				UI.PlaySound("Main_Menu_Mouse_Over")
				OnItemFocus(item)
			end)
			CAI_ItemList:AddChild(child)
		end
	end
	mgr:RestoreFocus(CAI_ItemList, capture)
end

local function OpenPresetDropdown()
	local optList = mgr:CreateWidget(mgr:GenerateWidgetId("CAILeaderPickerList"), "List", {
		Label = function() return Controls.StringName:GetText() end,
	})
	optList:AddInputBinding({Key = Keys.VK_ESCAPE, Action = function()
		mgr:RemoveFromStack(optList:GetId())
		return true
	end})

	local pulldown = Controls.PresetPulldown
	local function AddPreset(labelKey, action)
		local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAILeaderPickerMenuItem"), "MenuItem", {
			Label = function() return Locale.Lookup(labelKey) end,
		})
		item:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
		item:On("activate", function()
			pulldown:GetButton():SetText(Locale.Lookup(labelKey))
			action()
			RebuildItemList()
			mgr:RemoveFromStack(optList:GetId())
		end)
		optList:AddChild(item)
	end

	AddPreset("LOC_LEADER_PICK_PRESET_ALL",     function() OnSelectAll() end)
	AddPreset("LOC_LEADER_PICK_PRESET_NONE",    function() OnSelectNone() end)
	AddPreset("LOC_LEADER_PICK_PRESET_NO_WINS", function() SelectLeadersWithNoWins() end)

	mgr:Push(optList)
end

local function BuildPanel()
	CAI_Panel = mgr:CreateWidget(mgr:GenerateWidgetId("CAILeaderPickerDialog"), "Dialog", {
		Label = function() return Controls.WindowTitle:GetText() end,
		SpeechSettings = { Role = false },
	})
	CAI_Panel:AddInputBinding({Key = Keys.VK_ESCAPE, Action = function()
		Close()
		return true
	end})

	local presetBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAILeaderPickerPresetBtn"), "Button", {
		Label = function() return Controls.StringName:GetText() end,
		ValueGetter = function() return Controls.PresetPulldown:GetButton():GetText() end,
	})
	presetBtn:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
	presetBtn:On("activate", function() OpenPresetDropdown() end)
	CAI_Panel:AddChild(presetBtn)

	CAI_Panel:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAILeaderPickerStaticText"), "StaticText", {
		Label = function() return Controls.CountWarning:GetText() or "" end,
		HiddenPredicate = function()
			local text = Controls.CountWarning:GetText()
			return not text or text == ""
		end,
	}))

	CAI_ItemList = mgr:CreateWidget(mgr:GenerateWidgetId("CAILeaderPickerList"), "List")
	CAI_Panel:AddChild(CAI_ItemList)

	CAI_Panel:AddChild(MakeButton(Controls.ConfirmButton, function() OnConfirmChanges() end, Controls.ConfirmButton))
	CAI_Panel:AddChild(MakeButton(Controls.CloseButton,   function() Close() end))
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

-- Wrap ParameterInitialize to rebuild accessible list
ParameterInitialize = WrapFunc(ParameterInitialize, function(orig, kParameter, pGameParameters)
	orig(kParameter, pGameParameters)
	RebuildItemList()
end)

-- Wrap RefreshList to rebuild accessible list after sort
RefreshList = WrapFunc(RefreshList, function(orig, sortByFunc)
	orig(sortByFunc)
	RebuildItemList()
end)

-- Wrap RefreshCountWarning to speak warning text
RefreshCountWarning = WrapFunc(RefreshCountWarning, function(orig)
	orig()
	local warningText = Controls.CountWarning:GetText()
	if warningText and warningText ~= "" then
		Speak(warningText)
	end
end)

-- Wrap SelectLeadersWithNoWins to rebuild list after
SelectLeadersWithNoWins = WrapFunc(SelectLeadersWithNoWins, function(orig)
	orig()
	RebuildItemList()
end)

-- Show/hide handlers for push/pop lifecycle
ContextPtr:SetShowHandler(function()
	if CAI_Panel then
		mgr:RemoveFromStack(CAI_Panel:GetId())
	end
	CAI_Panel = nil
	CAI_ItemList = nil
	m_intentionalClose = false
	BuildPanel()
	RebuildItemList()
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
