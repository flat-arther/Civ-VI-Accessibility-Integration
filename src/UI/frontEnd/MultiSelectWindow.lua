
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

-- ---------------------------------------------------------------------------
-- Rebuild the accessible item list from vanilla's m_ItemList
-- ---------------------------------------------------------------------------
local function RebuildItemList()
	if not CAI_ItemList then return end
	CAI_ItemList:ClearChildren()

	if not m_ItemList then return end
	for idx, node in ipairs(m_ItemList) do
		local item = node["item"]
		local checkBox = node["checkbox"]

		local child = mgr:CreateUIWidget("Checkbox", {
			GetLabel = function() return item.Name end,
			GetTooltip = function()
				-- Sync the visual focus panel then read its text
				OnItemFocus(item)
				return Controls.FocusedItemDescription:GetText() or ""
			end,
			GetValue = function()
				return checkBox:IsChecked()
					and Locale.Lookup("LOC_OPTIONS_ENABLED")
					or Locale.Lookup("LOC_OPTIONS_DISABLED")
			end,
			Toggle = function()
				OnItemSelect(item, checkBox)
			end,
			OnFocusEnter = function()
				UI.PlaySound("Main_Menu_Mouse_Over")
				OnItemFocus(item)
			end,
		})
		CAI_ItemList:AddChild(child)
	end
end

-- ---------------------------------------------------------------------------
-- Build the accessible widget hierarchy
-- ---------------------------------------------------------------------------
local function BuildPanel()
	CAI_Panel = mgr:CreateUIWidget("Dialog", {
		GetLabel = function() return Controls.WindowTitle:GetText() end,
		SpeechSettings = { Role = false },
	})
	CAI_Panel:AddInputBinding({Key = Keys.VK_ESCAPE, Action = function()
		Close()
		return true
	end})

	-- Item list
	CAI_ItemList = mgr:CreateUIWidget("List")
	CAI_Panel:AddChild(CAI_ItemList)

	-- Action buttons
	CAI_Panel:AddChild(mgr:CreateUIWidget("Button", {
		GetLabel     = function() return Controls.SelectAllButton:GetText() end,
		OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
		OnClick      = function() OnSelectAll() end,
	}))
	CAI_Panel:AddChild(mgr:CreateUIWidget("Button", {
		GetLabel     = function() return Controls.SelectNoneButton:GetText() end,
		OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
		OnClick      = function() OnSelectNone() end,
	}))
	CAI_Panel:AddChild(mgr:CreateUIWidget("Button", {
		GetLabel     = function() return Controls.ConfirmButton:GetText() end,
		OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
		OnClick      = function() OnConfirmChanges() end,
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

-- Wrap ParameterInitialize to rebuild accessible list after vanilla populates
ParameterInitialize = WrapFunc(ParameterInitialize, function(orig, parameter)
	orig(parameter)
	RebuildItemList()
end)

-- Wrap SetAllItems to speak confirmation
SetAllItems = WrapFunc(SetAllItems, function(orig, bState)
	orig(bState)
	if bState then
		Speak(Locale.Lookup("LOC_CAI_ALL_SELECTED"))
	else
		Speak(Locale.Lookup("LOC_CAI_ALL_DESELECTED"))
	end
end)

-- Show/hide handlers for push/pop lifecycle
ContextPtr:SetShowHandler(function()
	-- Clean up stale panel if still on stack
	if CAI_Panel and mgr:HasWidget(CAI_Panel) then
		mgr:Pop()
	end
	-- Rebuild fresh each show
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
