
include("InstanceManager");

-- ===========================================================================
-- Members
-- ===========================================================================
m_ItemIM = InstanceManager:new("ItemInstance",	"Button", Controls.ItemsPanel);

m_Parameter = nil		-- Reference to the parameter being used. 
m_SelectedValues = nil	-- Table of string->boolean that represents checked off items.
m_ItemList = nil;		-- Table of controls for select all/none

local m_bInvertSelection:boolean = false;

-- ===========================================================================
function Close()	
	-- Clear any temporary global variables.
	m_Parameter = nil;
	m_SelectedValues = nil;

	ContextPtr:SetHide(true);
end

-- ===========================================================================
function IsItemSelected(item: table) 
	return m_SelectedValues[item.Value] == true;
end

-- ===========================================================================
function OnBackButton()
	Close();
end

-- ===========================================================================
function OnConfirmChanges()
	-- Generate sorted list from selected values.
	local values = {}
	for k,v in pairs(m_SelectedValues) do
		if(v) then
			table.insert(values, k);
		end
	end

	LuaEvents.MultiSelectWindow_SetParameterValues(m_Parameter.ParameterId, values);
	Close();
end

-- ===========================================================================
function OnItemSelect(item :table, checkBox :table)
	local value = item.Value;
	local selected = not m_SelectedValues[value];

	m_SelectedValues[item.Value] = selected;
	if m_bInvertSelection then
		checkBox:SetCheck(not selected);
	else
		checkBox:SetCheck(selected);
	end
end

-- ===========================================================================
function OnItemFocus(item :table)
	if(item) then
		Controls.FocusedItemName:SetText(item.Name);
		Controls.FocusedItemDescription:LocalizeAndSetText(item.RawDescription);

		if((item.Icon and Controls.FocusedItemIcon:SetIcon(item.Icon)) or Controls.FocusedItemIcon:SetIcon("ICON_" .. item.Value)) then
			Controls.FocusedItemIcon:SetHide(false);
		else
			Controls.FocusedItemIcon:SetHide(true);
		end
	end
end

-- ===========================================================================
function SetAllItems(bState: boolean)
	for _, node in ipairs(m_ItemList) do
		local item:table = node["item"];
		local checkBox:table = node["checkbox"];

		checkBox:SetCheck(bState);
		if m_bInvertSelection then
			m_SelectedValues[item.Value] = not bState;
		else
			m_SelectedValues[item.Value] = bState;
		end
	end
end

-- ===========================================================================
function OnSelectAll()
	SetAllItems(true);
end

-- ===========================================================================
function OnSelectNone()
	SetAllItems(false);
end

-- ===========================================================================
function ParameterInitialize(parameter : table)
	m_Parameter = parameter;
	m_SelectedValues = {};

	if (parameter.UxHint ~= nil and parameter.UxHint == "InvertSelection") then
		m_bInvertSelection = true;
	else
		m_bInvertSelection = false;
	end

	if(parameter.Value) then
		for i,v in ipairs(parameter.Value) do
			m_SelectedValues[v.Value] = true;
		end
	end

	Controls.TopDescription:SetText(parameter.Description);
	Controls.WindowTitle:SetText(parameter.Name);
	m_ItemIM:ResetInstances();

	m_ItemList = {};
	for i, v in ipairs(parameter.Values) do
		InitializeItem(v);
	end

	OnItemFocus(parameter.Values[1]);
end

-- ===========================================================================
function InitializeItem(item:table)
	local c: table = m_ItemIM:GetInstance();
	c.Name:SetText(item.Name);
	if not item.Icon or not c.Icon:SetIcon(item.Icon) then
		c.Icon:SetIcon("ICON_" .. item.Value);
	end
	c.Button:RegisterCallback( Mouse.eMouseEnter, function() OnItemFocus(item); end );
	c.Button:RegisterCallback( Mouse.eLClick, function() OnItemSelect(item, c.Selected); end );
	c.Selected:RegisterCallback( Mouse.eLClick, function() OnItemSelect(item, c.Selected); end );
	if m_bInvertSelection then
		c.Selected:SetCheck(not IsItemSelected(item));
	else
		c.Selected:SetCheck(IsItemSelected(item));
	end

	local listItem:table = {};
	listItem["item"] = item;
	listItem["checkbox"] = c.Selected;
	table.insert(m_ItemList, listItem);
end

-- ===========================================================================
function OnShutdown()
	Close();
	m_ItemIM:DestroyInstances();
	LuaEvents.MultiSelectWindow_Initialize.Remove( ParameterInitialize );
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
	Controls.SelectAllButton:RegisterCallback( Mouse.eLClick, OnSelectAll);
	Controls.SelectAllButton:RegisterCallback( Mouse.eMouseEnter, OnMouseEnter);
	Controls.SelectNoneButton:RegisterCallback( Mouse.eLClick, OnSelectNone);
	Controls.SelectNoneButton:RegisterCallback( Mouse.eMouseEnter, OnMouseEnter);

	LuaEvents.MultiSelectWindow_Initialize.Add( ParameterInitialize );
end
--#Accessibility integration
include("caiUtils")
local mgr = ExposedMembers.CAI_UIManager

local CAI_Panel = nil
local CAI_ItemList = nil
local m_intentionalClose = false

local function RebuildItemList()
	if not CAI_ItemList then return end
	local capture = mgr:CaptureFocusKey(CAI_ItemList)
	CAI_ItemList:ClearChildren()

	if m_ItemList then
		for idx, node in ipairs(m_ItemList) do
			local item = node["item"]
			local checkBox = node["checkbox"]

			local child = mgr:CreateWidget(mgr:GenerateWidgetId("CAIMultiSelectWindowCheckbox"), "Checkbox", {
				Label = function() return item.Name end,
				Tooltip = function()
					OnItemFocus(item)
					return Controls.FocusedItemDescription:GetText() or ""
				end,
				FocusKey = "msw:item:" .. tostring(idx),
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
	end
	mgr:RestoreFocus(CAI_ItemList, capture)
end

local function BuildPanel()
	CAI_Panel = mgr:CreateWidget(mgr:GenerateWidgetId("CAIMultiSelectWindowPanel"), "Panel", {
		Label = function() return Controls.WindowTitle:GetText() end,
	})
	CAI_Panel:AddInputBinding({Key = Keys.VK_ESCAPE, Description = "LOC_CAI_KB_CLOSE", Action = function()
		Close()
		return true
	end})

	CAI_ItemList = mgr:CreateWidget(mgr:GenerateWidgetId("CAIMultiSelectWindowList"), "List")
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

	local selectAllBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIMultiSelectWindowSelectAllBtn"), "Button", {
		Label = function() return Controls.SelectAllButton:GetText() end,
	})
	selectAllBtn:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
	selectAllBtn:On("activate", function() Controls.SelectAllButton:DoLeftClick() end)
	CAI_Panel:AddChild(selectAllBtn)

	local selectNoneBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIMultiSelectWindowSelectNoneBtn"), "Button", {
		Label = function() return Controls.SelectNoneButton:GetText() end,
	})
	selectNoneBtn:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
	selectNoneBtn:On("activate", function() Controls.SelectNoneButton:DoLeftClick() end)
	CAI_Panel:AddChild(selectNoneBtn)

	local confirmBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIMultiSelectWindowConfirmBtn"), "Button", {
		Label = function() return Controls.ConfirmButton:GetText() end,
	})
	confirmBtn:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
	confirmBtn:On("activate", function() Controls.ConfirmButton:DoLeftClick() end)
	CAI_Panel:AddChild(confirmBtn)
end

local function ClosePanel()
	if CAI_Panel then
		mgr:RemoveFromStack(CAI_Panel:GetId())
	end
end

Close = WrapFunc(Close, function(orig)
	m_intentionalClose = true
	orig()
end)

ParameterInitialize = WrapFunc(ParameterInitialize, function(orig, parameter)
	orig(parameter)
	RebuildItemList()
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
