
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

local function MakeButton(idPrefix, labelCtrl, onClick, disabledCtrl)
	local b = mgr:CreateWidget(mgr:GenerateWidgetId(idPrefix), "Button", {
		Label = function() return labelCtrl:GetText() end,
	})
	if disabledCtrl then
		b:SetDisabledPredicate(function() return disabledCtrl:IsDisabled() end)
	end
	b:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
	b:On("activate", onClick)
	return b
end

function RebuildItemList()
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
			Label = function() return Controls.FocusedItemName:GetText() end,
			Tooltip = function() return Controls.FocusedItemDescription:GetText() end,
			ValueGetter = function()
				return checkBox:IsChecked()
					and Locale.Lookup("LOC_OPTIONS_ENABLED")
					or Locale.Lookup("LOC_OPTIONS_DISABLED")
			end,
			FocusKey = "csp:item:" .. tostring(idx),
		})
		child:On("value_changed", function() OnItemSelect(item, checkBox) end)
		child:On("focus_enter", function()
			UI.PlaySound("Main_Menu_Mouse_Over")
			OnItemFocus(item)
		end)
		CAI_ItemList:AddChild(child)
	end
	mgr:RestoreFocus(CAI_ItemList, capture)
end

function OpenSortByDropdown()
	local pulldown = Controls.SortByPulldown
	local optList = mgr:CreateWidget(mgr:GenerateWidgetId("CAICityStatePickerList"), "List", {
		Label = function() return Controls.StringName:GetText() end,
	})
	optList:AddInputBinding({Key = Keys.VK_ESCAPE, Action = function()
		mgr:RemoveFromStack(optList:GetId())
		return true
	end})

	local function AddSort(labelKey, sortFn)
		local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAICityStatePickerMenuItem"), "MenuItem", {
			Label = function() return Locale.Lookup(labelKey) end,
		})
		item:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
		item:On("activate", function()
			pulldown:GetButton():SetText(Locale.Lookup(labelKey))
			RefreshList(sortFn)
			mgr:RemoveFromStack(optList:GetId())
		end)
		optList:AddChild(item)
	end

	AddSort("LOC_CITY_STATE_PICKER_SORT_NAME", SortByName)
	AddSort("LOC_CITY_STATE_PICKER_SORT_TYPE", SortByType)

	mgr:Push(optList)
end

function BuildPanel()
	local pulldown = Controls.SortByPulldown
	CAI_Panel = mgr:CreateWidget(mgr:GenerateWidgetId("CAICityStatePickerDialog"), "Dialog", {
		Label = function() return Controls.WindowTitle:GetText() end,
		Tooltip = function() return Controls.TopDescription:GetText() end,
		SpeechSettings = { Role = false },
	})
	CAI_Panel:AddInputBinding({Key = Keys.VK_ESCAPE, Action = function()
		Close()
		return true
	end})

	local sortBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAICityStatePickerSortBtn"), "Button", {
		Label = function() return Controls.StringName:GetText() end,
		ValueGetter = function() return pulldown:GetButton():GetText() end,
	})
	sortBtn:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
	sortBtn:On("activate", function() OpenSortByDropdown() end)
	CAI_Panel:AddChild(sortBtn)

	CAI_Panel:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAICityStatePickerStaticText"), "StaticText", {
		Label = function() return Controls.CountWarning:GetText() or "" end,
		HiddenPredicate = function()
			local text = Controls.CountWarning:GetText()
			return not text or text == ""
		end,
	}))

	CAI_ItemList = mgr:CreateWidget(mgr:GenerateWidgetId("CAICityStatePickerList"), "List")
	CAI_Panel:AddChild(CAI_ItemList)

	CAI_Panel:AddChild(MakeButton("CAICityStatePickerButton", Controls.SelectAllButton,  function() OnSelectAll() end))
	CAI_Panel:AddChild(MakeButton("CAICityStatePickerButton", Controls.SelectNoneButton, function() OnSelectNone() end))
	CAI_Panel:AddChild(MakeButton("CAICityStatePickerButton", Controls.ConfirmButton,    function() OnConfirmChanges() end, Controls.ConfirmButton))
	CAI_Panel:AddChild(MakeButton("CAICityStatePickerButton", Controls.CloseButton,      function() Close() end))
end

function ClosePanel()
	if CAI_Panel then
		mgr:RemoveFromStack(CAI_Panel:GetId())
	end
	CAI_Panel = nil
	CAI_ItemList = nil
end

ParameterInitialize = WrapFunc(ParameterInitialize, function(orig, kParameter, pGameParameters)
	Speak("initializing parems")
	orig(kParameter, pGameParameters)
end)

RefreshList = WrapFunc(RefreshList, function(orig, sortByFunc)
	Speak("Refreshing list")
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
