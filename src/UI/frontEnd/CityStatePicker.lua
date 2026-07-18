
include("InstanceManager");
include("PlayerSetupLogic");
include("Civ6Common");

-- ===========================================================================
-- CONSTANTS
-- ===========================================================================

local XP2_RULESETUP:string = "RULESET_EXPANSION_2";
local XP1_RULESETUP:string = "RULESET_EXPANSION_1";

-- ===========================================================================
-- Members
-- ===========================================================================

local m_pItemIM:table = InstanceManager:new("ItemInstance",	"Button", Controls.ItemsPanel);

local m_kParameter:table = nil		-- Reference to the parameter being used. 
local m_kSelectedValues:table = nil	-- Table of string->boolean that represents checked off items.
local m_kItemList:table = nil;		-- Table of controls for select all/none

local m_bInvertSelection:boolean = false;

local m_kCityStateDataCache:table = {};

local m_kCityStateCountParam:table = nil;

local m_RulesetType:string = "";

local m_numSelected:number = 0;

-- Track the number of city-states to spawn when opening the picker
-- Used to revert to that number in case the user modifies the parameter then backs out of the picker
local m_OriginalCityStateCount:number = 0;

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
	LuaEvents.CityStatePicker_SetParameterValue(m_kCityStateCountParam.ParameterId, m_OriginalCityStateCount);
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

	LuaEvents.CityStatePicker_SetParameterValues(m_kParameter.ParameterId, values);
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
		Controls.FocusedItemName:SetText(item.Name);

		local backColor:number, frontColor:number = UI.GetPlayerColorValues(item.Value, 0);
		local kCityStateData:table = GetCityStateData(item.Value);

		local description:string = Locale.ToUpper("LOC_CITY_STATES_SUZERAIN_BONUSES");

        if kCityStateData ~= nil then
            if kCityStateData.Bonus_XP2 ~= nil and m_RulesetType == XP2_RULESETUP and IsExpansion2Enabled() then
                description = description .. "[NEWLINE]" .. Locale.Lookup(kCityStateData.Bonus_XP2);
            elseif kCityStateData.Bonus_XP1 ~= nil and (m_RulesetType == XP1_RULESETUP or m_RulesetType == XP2_RULESETUP) and IsExpansion1Enabled() then
                description = description .. "[NEWLINE]" .. Locale.Lookup(kCityStateData.Bonus_XP1);
            elseif kCityStateData ~= nil then
                description = description .. "[NEWLINE]" .. Locale.Lookup(kCityStateData.Bonus);
            end
        end

		Controls.FocusedItemDescription:LocalizeAndSetText(description);

		-- Icon
		Controls.FocusedItemIcon:SetIcon(item.Icon);
		Controls.FocusedItemIcon:SetHide(false);
		Controls.FocusedItemIcon:SetColor(frontColor);
	end
end

-- ===========================================================================
function GetCityStateData( civType:string )
	-- Refresh the cache if needed
	if m_kCityStateDataCache[civType] == nil then

		m_kCityStateDataCache[civType] = {};

		local query:string = "SELECT CityStateCategory, Bonus, Bonus_XP1, Bonus_XP2 from CityStates where CivilizationType = ?";
		local kResults:table = DB.ConfigurationQuery(query, civType);
		if(kResults) then
			for i,v in ipairs(kResults) do
				for name, value in pairs(v) do
					m_kCityStateDataCache[civType][name] = value;
				end
			end
		end
	end

	return m_kCityStateDataCache[civType];
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
function ParameterInitialize(parameter : table, pGameParameters:table)
	m_kParameter = parameter;
	m_kSelectedValues = {};

	m_kCityStateCountParam = pGameParameters.Parameters["CityStateCount"];
	m_OriginalCityStateCount = m_kCityStateCountParam.Value;

	local kRulesetParam = pGameParameters.Parameters["Ruleset"];
	m_RulesetType = kRulesetParam.Value.Value;

	if (parameter.UxHint ~= nil and parameter.UxHint == "InvertSelection") then
		m_bInvertSelection = true;
	else
		m_bInvertSelection = false;
	end

	if(parameter.Value) then
		for i,v in ipairs(parameter.Value) do
			m_kSelectedValues[v.Value] = true;
		end
	end

	Controls.TopDescription:SetText(parameter.Description);
	Controls.WindowTitle:SetText(parameter.Name);
	m_pItemIM:ResetInstances();

	RefreshList();
	RefreshCountWarning()

	InitCityStateCountSlider(pGameParameters);
	InitSortByFilter();

	OnItemFocus(parameter.Values[1]);
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
	if m_kParameter ~= nil then
		local numSelected:number = 0;

		for i, v in ipairs(m_kParameter.Values) do
			if not IsItemSelected(v) then
				numSelected = numSelected + 1;
			end
		end

		if numSelected < m_kCityStateCountParam.Value then
			Controls.ConfirmButton:SetDisabled(true);
			Controls.CountWarning:SetText(Locale.ToUpper(Locale.Lookup("LOC_CITY_STATE_PICKER_COUNT_WARNING", m_kCityStateCountParam.Value, m_kCityStateCountParam.Value - numSelected)));
		else
			Controls.ConfirmButton:SetDisabled(false);
			Controls.CountWarning:SetText("");
		end
	end
end

-- ===========================================================================
function SortByName(kItemA:table, kItemB:table)
	return Locale.Compare(kItemA.Name, kItemB.Name) == -1;
end

-- ===========================================================================
function SortByType(kItemA:table, kItemB:table)
	local kItemDataA:table = GetCityStateData(kItemA.Value);
	local kItemDataB:table = GetCityStateData(kItemB.Value);

	if kItemDataA.CityStateCategory ~= nil and kItemDataB.CityStateCategory ~= nil then
		return Locale.Compare(kItemDataA.CityStateCategory, kItemDataB.CityStateCategory) == -1;
	else
		return false;
	end
end

-- ===========================================================================
function InitCityStateCountSlider( pGameParameters:table )

	local kValues:table = m_kCityStateCountParam.Values;

	Controls.CityStateCountNumber:SetText(m_kCityStateCountParam.Value);
	Controls.CityStateCountSlider:SetNumSteps(kValues.MaximumValue - kValues.MinimumValue);
	Controls.CityStateCountSlider:SetStep(m_kCityStateCountParam.Value - kValues.MinimumValue);

	Controls.CityStateCountSlider:RegisterSliderCallback(function()
		local stepNum:number = Controls.CityStateCountSlider:GetStep();
		local value:number = m_kCityStateCountParam.Values.MinimumValue + stepNum;
			
		-- This method can get called pretty frequently, try and throttle it.
		if(m_kCityStateCountParam.Value ~= value) then
			pGameParameters:SetParameterValue(m_kCityStateCountParam, value);
			Controls.CityStateCountNumber:SetText(value);
			Network.BroadcastGameConfig();
			RefreshCountWarning();
		end
	end);

end

-- ===========================================================================
function InitSortByFilter()

	local uiButton:object = Controls.SortByPulldown:GetButton();
	uiButton:SetText(Locale.Lookup("LOC_CITY_STATE_PICKER_SORT_NAME"));

	Controls.SortByPulldown:ClearEntries();

	local pNameEntryInst:object = {};
	Controls.SortByPulldown:BuildEntry( "InstanceOne", pNameEntryInst );
	pNameEntryInst.Button:SetText(Locale.Lookup("LOC_CITY_STATE_PICKER_SORT_NAME"));
	pNameEntryInst.Button:RegisterCallback( Mouse.eLClick, 
		function() 
			Controls.SortByPulldown:GetButton():SetText(Locale.Lookup("LOC_CITY_STATE_PICKER_SORT_NAME"));
			RefreshList(SortByName);
		end );

	local pTypeEntryInst:object = {};
	Controls.SortByPulldown:BuildEntry( "InstanceOne", pTypeEntryInst );
	pTypeEntryInst.Button:SetText(Locale.Lookup("LOC_CITY_STATE_PICKER_SORT_TYPE"));
	pTypeEntryInst.Button:RegisterCallback( Mouse.eLClick, 
		function() 
			Controls.SortByPulldown:GetButton():SetText(Locale.Lookup("LOC_CITY_STATE_PICKER_SORT_TYPE"));
			RefreshList(SortByType);
		end );

	Controls.SortByPulldown:CalculateInternals();
end

-- ===========================================================================
function InitializeItem(item:table)
	local c: table = m_pItemIM:GetInstance();
	c.Name:SetText(item.Name);

	local backColor, frontColor = UI.GetPlayerColorValues(item.Value, 0);

	c.Icon:SetIcon(item.Icon);
	c.Icon:SetColor(frontColor);
	c.IconBacking:SetColor(backColor);

	c.Button:RegisterCallback( Mouse.eMouseEnter, function() OnItemFocus(item); end );
	c.Button:RegisterCallback( Mouse.eLClick, function() OnItemSelect(item, c.Selected); end );
	c.Selected:RegisterCallback( Mouse.eLClick, function() OnItemSelect(item, c.Selected); end );
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
	LuaEvents.CityStatePicker_Initialize.Remove( ParameterInitialize );
end

-- ===========================================================================
function OnInputHandler( pInputStruct:table )
	local uiMsg = pInputStruct:GetMessageType();
	if uiMsg == KeyEvents.KeyUp then
		local key:number = pInputStruct:GetKey();
		if key == Keys.VK_ESCAPE then
			OnBackButton();
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
	Controls.SelectAllButton:RegisterCallback( Mouse.eLClick, OnSelectAll);
	Controls.SelectAllButton:RegisterCallback( Mouse.eMouseEnter, OnMouseEnter);
	Controls.SelectNoneButton:RegisterCallback( Mouse.eLClick, OnSelectNone);
	Controls.SelectNoneButton:RegisterCallback( Mouse.eMouseEnter, OnMouseEnter);

	LuaEvents.CityStatePicker_Initialize.Add( ParameterInitialize );
end
--#Accessibility integration
include("caiUtils")
local mgr = ExposedMembers.CAI_UIManager
local CAI_Panel = nil
local CAI_ItemList = nil
local CAI_SortDD = nil
local CAI_Slider = nil
local m_cachedGameParameters = nil

local function SyncCityStateCountSlider()
	if not CAI_Slider or not m_kCityStateCountParam then return end
	local kValues = m_kCityStateCountParam.Values
	local range = kValues.MaximumValue - kValues.MinimumValue
	CAI_Slider:SetMin(kValues.MinimumValue)
	CAI_Slider:SetMax(kValues.MaximumValue)
	CAI_Slider:SetStepSize(1)
	CAI_Slider:SetPageStep(math.max(1, math.floor(range / 10)))
	CAI_Slider:SetValue(m_kCityStateCountParam.Value, true)
end

local function BuildSortDropdownOptions()
	local options = {
		{ label = Locale.Lookup("LOC_CITY_STATE_PICKER_SORT_NAME"), value = "name" },
		{ label = Locale.Lookup("LOC_CITY_STATE_PICKER_SORT_TYPE"), value = "type" },
	}
	local current = Controls.SortByPulldown:GetButton():GetText()
	local selectedIdx = 1
	for i, opt in ipairs(options) do
		if opt.label == current then selectedIdx = i end
	end
	return options, selectedIdx
end

local function RebuildItemList()
	if not CAI_ItemList then return end
	local capture = mgr:CaptureFocusKey(CAI_ItemList)
	CAI_ItemList:ClearChildren()

	if not m_kItemList then
		mgr:RestoreFocus(CAI_ItemList, capture)
		return
	end
	for idx, node in ipairs(m_kItemList) do
		local item = node["item"]
		local checkBox = node["checkbox"]

		local child = mgr:CreateWidget(mgr:GenerateWidgetId("CAICityStatePickerCheckbox"), "Checkbox", {
			Label = function() return item.Name end,
			Tooltip = function()
				OnItemFocus(item)
				return Controls.FocusedItemDescription:GetText() or ""
			end,
			FocusKey = "csp:item:" .. tostring(idx),
		})
		child:SetChecked(checkBox:IsChecked(), true)
		child:SetValueSetter(function(_, value)
			if checkBox:IsChecked() ~= value then
				checkBox:DoLeftClick()
			end
		end)
		child:On("focus_enter", function()
			UI.PlaySound("Main_Menu_Mouse_Over")
			OnItemFocus(item)
		end)
		CAI_ItemList:AddChild(child)
	end
	mgr:RestoreFocus(CAI_ItemList, capture)
end

local function BuildPanel()
	CAI_Panel = mgr:CreateWidget(mgr:GenerateWidgetId("CAICityStatePickerPanel"), "Panel", {
		Label = function() return Controls.WindowTitle:GetText() end,
		Tooltip = function() return Controls.TopDescription:GetText() end,
	})
	CAI_Panel:AddInputBinding({Key = Keys.VK_ESCAPE, Description = "LOC_CAI_KB_CLOSE", Action = function()
		Close()
		return true
	end})

	CAI_SortDD = mgr:CreateWidget(mgr:GenerateWidgetId("CAICityStatePickerSortDD"), "Dropdown", {
		Label = function() return Controls.StringName:GetText() end,
	})
	local options, idx = BuildSortDropdownOptions()
	CAI_SortDD:SetOptions(options)
	if idx > 0 then CAI_SortDD:SetSelectedIndex(idx, true) end
	CAI_SortDD:SetFocusSound("Main_Menu_Mouse_Over")
	CAI_SortDD:SetValueSetter(function(_, val)
		local pulldown = Controls.SortByPulldown
		if val == "name" then
			pulldown:GetButton():SetText(Locale.Lookup("LOC_CITY_STATE_PICKER_SORT_NAME"))
			RefreshList(SortByName)
		elseif val == "type" then
			pulldown:GetButton():SetText(Locale.Lookup("LOC_CITY_STATE_PICKER_SORT_TYPE"))
			RefreshList(SortByType)
		end
	end)
	CAI_Panel:AddChild(CAI_SortDD)

	CAI_Slider = mgr:CreateWidget(mgr:GenerateWidgetId("CAICityStatePickerSlider"), "Slider", {
		Label = function() return m_kCityStateCountParam and m_kCityStateCountParam.Name or "" end,
	})
	SyncCityStateCountSlider()
	CAI_Slider:SetValueSetter(function(_, newVal)
		if m_kCityStateCountParam and m_cachedGameParameters then
			local kValues = m_kCityStateCountParam.Values
			if m_kCityStateCountParam.Value ~= newVal then
				m_cachedGameParameters:SetParameterValue(m_kCityStateCountParam, newVal)
				Controls.CityStateCountNumber:SetText(newVal)
				Controls.CityStateCountSlider:SetStep(newVal - kValues.MinimumValue)
				Network.BroadcastGameConfig()
				RefreshCountWarning()
			end
		end
	end)
	CAI_Panel:AddChild(CAI_Slider)

	CAI_ItemList = mgr:CreateWidget(mgr:GenerateWidgetId("CAICityStatePickerList"), "List")
	CAI_ItemList:AddInputBinding({Key = Keys.A, IsControl = true, Description = "LOC_CAI_KB_SELECT_ALL", Action = function()
		Controls.SelectAllButton:DoLeftClick()
		RebuildItemList()
		return true
	end})
	CAI_ItemList:AddInputBinding({Key = Keys.A, IsControl = true, IsShift = true, Description = "LOC_CAI_KB_DESELECT_ALL", Action = function()
		Controls.SelectNoneButton:DoLeftClick()
		RebuildItemList()
		return true
	end})
	CAI_Panel:AddChild(CAI_ItemList)

	local selectAllBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAICityStatePickerSelectAllBtn"), "Button", {
		Label = function() return Controls.SelectAllButton:GetText() end,
	})
	selectAllBtn:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
	selectAllBtn:On("activate", function() Controls.SelectAllButton:DoLeftClick() end)
	CAI_Panel:AddChild(selectAllBtn)

	local selectNoneBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAICityStatePickerSelectNoneBtn"), "Button", {
		Label = function() return Controls.SelectNoneButton:GetText() end,
	})
	selectNoneBtn:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
	selectNoneBtn:On("activate", function() Controls.SelectNoneButton:DoLeftClick() end)
	CAI_Panel:AddChild(selectNoneBtn)

	local confirmBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAICityStatePickerConfirmBtn"), "Button", {
		Label = function() return Controls.ConfirmButton:GetText() end,
		Tooltip = function() return Controls.CountWarning:GetText() or "" end,
	})
	confirmBtn:SetDisabledPredicate(function() return Controls.ConfirmButton:IsDisabled() end)
	confirmBtn:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
	confirmBtn:On("activate", function() Controls.ConfirmButton:DoLeftClick() end)
	CAI_Panel:AddChild(confirmBtn)
end

local function ClosePanel()
	if CAI_Panel then
		mgr:RemoveFromStack(CAI_Panel:GetId())
	end
	CAI_Panel = nil
	CAI_ItemList = nil
	CAI_SortDD = nil
	CAI_Slider = nil
end

ParameterInitialize = WrapFunc(ParameterInitialize, function(orig, kParameter, pGameParameters)
	orig(kParameter, pGameParameters)
	m_cachedGameParameters = pGameParameters
	if CAI_SortDD then
		local options, idx = BuildSortDropdownOptions()
		CAI_SortDD:SetOptions(options)
		if idx > 0 then CAI_SortDD:SetSelectedIndex(idx, true) end
	end
	if CAI_Slider and m_kCityStateCountParam then
		SyncCityStateCountSlider()
	end
	RebuildItemList()
end)

RefreshList = WrapFunc(RefreshList, function(orig, sortByFunc)
	orig(sortByFunc)
	RebuildItemList()
end)

RefreshCountWarning = WrapFunc(RefreshCountWarning, function(orig)
	orig()
	local warningText = Controls.CountWarning:GetText()
	if warningText and warningText ~= "" then
		Speak(warningText)
	end
end)

SetAllItems = WrapFunc(SetAllItems, function(orig, bState)
	orig(bState)
	if bState then
		Speak(Locale.Lookup("LOC_CAI_ALL_SELECTED"))
	else
		Speak(Locale.Lookup("LOC_CAI_ALL_DESELECTED"))
	end
end)

ContextPtr:SetShowHandler(function()
	if CAI_Panel then
		mgr:RemoveFromStack(CAI_Panel:GetId())
	end
	CAI_Panel = nil
	CAI_ItemList = nil
	CAI_SortDD = nil
	CAI_Slider = nil
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
	ClosePanel()
end)
--#End of accessibility integration
Initialize();
