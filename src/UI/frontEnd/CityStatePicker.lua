include("CityStatePicker_Base")
include("caiUtils")
local mgr = ExposedMembers.CAI_UIManager
local CAI_Panel = nil
local CAI_ItemList = nil

function RebuildItemList()
	if not CAI_ItemList then return end
	CAI_ItemList:ClearChildren()

	if not m_kItemList then return end
	for idx, node in ipairs(m_kItemList) do
		local item = node["item"]
		local checkBox = node["checkbox"]

		local child = mgr:CreateUIWidget("Checkbox", {
			GetLabel = function()
				return Controls.FocusedItemName:GetText()
			end,
			GetTooltip = function()
				return Controls.FocusedItemDescription:GetText()
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

function OpenSortByDropdown()
	local pulldown = Controls.SortByPulldown
	local optList = mgr:CreateUIWidget("List", {
		GetLabel = function() return Controls.StringName:GetText() end,
	})
	optList:AddInputBinding({Key = Keys.VK_ESCAPE, Action = function()
		mgr:Pop()
		return true
	end})



	optList:AddChild(mgr:CreateUIWidget("MenuItem", {
		GetLabel = function()
			return Locale.Lookup("LOC_CITY_STATE_PICKER_SORT_NAME")
		end,
		OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
		OnClick = function()
			pulldown:GetButton():SetText(Locale.Lookup("LOC_CITY_STATE_PICKER_SORT_NAME"))
			RefreshList(SortByName)
			mgr:Pop()
		end,
	}))

	optList:AddChild(mgr:CreateUIWidget("MenuItem", {
		GetLabel = function()
			return Locale.Lookup("LOC_CITY_STATE_PICKER_SORT_TYPE")
		end,
		OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
		OnClick = function()
			pulldown:GetButton():SetText(Locale.Lookup("LOC_CITY_STATE_PICKER_SORT_TYPE"))
			RefreshList(SortByType);
			mgr:Pop()
		end,
	}))

	mgr:Push(optList)
end

function BuildPanel()
	local pulldown = Controls.SortByPulldown
	CAI_Panel = mgr:CreateUIWidget("Dialog", {
		GetLabel = function() return Controls.WindowTitle:GetText() end,
		GetTooltip = function() return Controls.TopDescription:GetText() end,
		SpeechSettings = { Role = false },
	})
	CAI_Panel:AddInputBinding({Key = Keys.VK_ESCAPE, Action = function()
		Close()
		return true
	end})


	CAI_Panel:AddChild(mgr:CreateUIWidget("DropdownMenu", {
		GetLabel = function() return Controls.StringName:GetText() end,
		GetValue     = function() return pulldown:GetButton():GetText() end,
		OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
		OnClick      = function() OpenSortByDropdown() end,
	}))

	CAI_Panel:AddChild(mgr:CreateUIWidget("StaticText", {
		GetLabel = function() return Controls.CountWarning:GetText() or "" end,
		IsHidden = function()
			local text = Controls.CountWarning:GetText()
			return not text or text == ""
		end,
	}))

	CAI_ItemList = mgr:CreateUIWidget("List")
	CAI_Panel:AddChild(CAI_ItemList)

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
		IsDisabled   = function() return Controls.ConfirmButton:IsDisabled() end,
		OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
		OnClick      = function() OnConfirmChanges() end,
	}))
	CAI_Panel:AddChild(mgr:CreateUIWidget("Button", {
		GetLabel     = function() return Controls.CloseButton:GetText() end,
		OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
		OnClick      = function() Close() end,
	}))
end

function ClosePanel()
	if CAI_Panel and mgr:HasWidget(CAI_Panel) then
		mgr:Pop()
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
	if CAI_Panel and mgr:HasWidget(CAI_Panel) then
		mgr:Pop()
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
