include("MultiSelectWindow_Base")
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
