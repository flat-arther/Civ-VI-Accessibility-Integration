include("MainMenu_Base")
include("caiUtils")
local mgr = ExposedMembers.CAI_UIManager
local MainPanel = nil ---@type UIWidget
local MenuList = nil ---@type UIWidget
local m_SubmenuList = nil ---@type UIWidget
local m_submenuLabel = "" ---Current submenu parent label
local m_CarouselList = nil ---@type UIWidget
local m_MotDWidget = nil ---@type UIWidget
local m_VersionWidget = nil ---@type UIWidget
local m_My2KWidget = nil ---@type UIWidget

-- Forward declarations for build functions used in BuildMenu wrap
local BuildCarouselWidgets
local BuildMotDWidget
local BuildVersionWidget
local BuildMy2KWidget

-- Wrap the 'Initialize' function so we can set the input handler
Initialize = WrapFunc(Initialize, function(orig)
	orig()
	ContextPtr:SetInputHandler(function(input)
        return mgr:HandleInput(input)
end, true)
end)

function HighlightMainOption(index)
	if not m_currentOptions then return end
    local control = m_currentOptions[index] and m_currentOptions[index].control
    control.SelectionAnimAlpha:SetToBeginning()
    control.SelectionAnimSlide:SetToBeginning()
    control.SelectionAnimAlpha:Play()
    control.SelectionAnimSlide:Play()
end

BuildMenu = WrapFunc(BuildMenu, function(orig, menuOptions)
    orig(menuOptions)
    if not m_currentOptions or #m_currentOptions == 0 then return end

    -- If submenu is on top of the stack, pop it — a menu rebuild invalidates it
    if m_SubmenuList and mgr:GetTop() == m_SubmenuList then
        mgr:Pop()
        m_SubmenuList = nil
    end

    if not MainPanel then
        MainPanel = mgr:CreateUIWidget("Panel", {
            GetLabel = function() return Locale.Lookup("LOC_CAI_MAIN_MENU") end,
            SpeechSettings = { Role = false }
        })
    end

    if not MenuList then
        MenuList = mgr:CreateUIWidget("List")
        MainPanel:AddChild(MenuList)
        BuildCarouselWidgets()
        BuildMotDWidget()
        BuildVersionWidget()
        BuildMy2KWidget()
    end
    if #MenuList.Children ~= #m_currentOptions then
        MenuList:ClearChildren()
        for i, menuOption in ipairs(m_currentOptions) do
            local dataEntry = menuOptions[i]
            local controlRef = menuOption.control

            if dataEntry then
                local widget = mgr:CreateUIWidget("MenuItem", {
                    GetLabel = function() return controlRef.ButtonLabel:GetText() end,
                    GetTooltip = function() return controlRef.Top:GetToolTipString() end,
                    IsHidden = function() return controlRef.Top:IsHidden() end,
                    OnClick = function()
                        if dataEntry.submenu then
                            dataEntry.callback(i, dataEntry.submenu)
                        else
                            dataEntry.callback()
                        end
                    end,
                    OnFocusEnter = function()
                        UI.PlaySound("Main_Menu_Mouse_Over");
                        HighlightMainOption(i)
                    end,
                    OnToggleExpanded = dataEntry.submenu and function(isExpanded)
                        dataEntry.callback(i, dataEntry.submenu)
                    end
                })
                MenuList:AddChild(widget)
            end
        end
    end
    if not mgr:HasWidget(MainPanel) then
        mgr:Push(MainPanel)
    end
end)

--#Carousel widget
BuildCarouselWidgets = function()
    if m_CarouselList then
        m_CarouselList:ClearChildren()
    end

    local entryCount = Challenges.GetCarouselEntryCount()
    if entryCount == 0 then return end

    if not m_CarouselList then
        m_CarouselList = mgr:CreateUIWidget("HorizontalList", {
            GetLabel = function() return Locale.Lookup("LOC_CAI_CAROUSEL") end,
            IsHidden = function() return Controls.ChallengeContainer:IsHidden() end,
        })
        MainPanel:AddChild(m_CarouselList)
    end

    for i = 0, entryCount - 1 do
        local entryIndex = i
        local entryNum = i + 1
        local widget = mgr:CreateUIWidget("Button", {
            GetLabel = function()
                local entryType = Challenges.GetCarouselEntryType(entryIndex)
                local typeLabel = entryType == "Clickout"
                    and Locale.Lookup("LOC_CAI_CAROUSEL_LINK")
                    or Locale.Lookup("LOC_CAI_CAROUSEL_CHALLENGE")
                return Locale.Lookup("LOC_CAI_CAROUSEL_ENTRY", typeLabel, entryNum, entryCount)
            end,
            OnClick = function()
                Challenges.PublishCarouselEntryClick(entryIndex)
                local carouselEntryType = Challenges.GetCarouselEntryType(entryIndex)
                if carouselEntryType == "Clickout" then
                    Challenges.LoadCarouselEntry(entryIndex)
                else
                    _StartChallengeEntry = entryIndex
                    LuaEvents.Raise_State_Transition("MainMenu")
                end
            end,
            OnFocusEnter = function()
                CarouselScrollToEntry(entryNum, "manual scroll")
            end,
            SpeechSettings = { Role = false },
        })
        m_CarouselList:AddChild(widget)
    end
end

UpdateChallengeCarousel = WrapFunc(UpdateChallengeCarousel, function(orig)
    orig()
    if MainPanel then
        BuildCarouselWidgets()
    end
end)

--#MotD widget
BuildMotDWidget = function()
    if m_MotDWidget then return end
    m_MotDWidget = mgr:CreateUIWidget("StaticText", {
        GetLabel = function() return Locale.Lookup("LOC_MESSAGE_OF_THE_DAY_HEADING") end,
        GetValue = function() return Controls.MotDText:GetText() or "" end,
        IsHidden = function() return Controls.MotDContainter:IsHidden() end,
    })
    MainPanel:AddChild(m_MotDWidget)
end

UpdateMotD = WrapFunc(UpdateMotD, function(orig)
    orig()
    if MainPanel and m_MotDWidget then
        m_MotDWidget:SetValue(Controls.MotDText:GetText() or "")
    end
end)

--#Version widget
BuildVersionWidget = function()
    if m_VersionWidget then return end
    m_VersionWidget = mgr:CreateUIWidget("StaticText", {
        GetLabel = function()
            return Locale.Lookup("LOC_PAUSEMENU_INFO_VERSION_TOOLTIP", UI.GetAppVersion())
        end,
    })
    MainPanel:AddChild(m_VersionWidget)
end

--#My2K widget
BuildMy2KWidget = function()
    if m_My2KWidget then return end
    m_My2KWidget = mgr:CreateUIWidget("Button", {
        GetLabel = function() return Locale.Lookup("TXT_KEY_MY2K") end,
        GetValue = function() return Controls.My2KStatus:GetText() or "" end,
        IsHidden = function() return Controls.My2KContents:IsHidden() end,
        OnClick = function() OnMy2KLogin() end,
    })
    MainPanel:AddChild(m_My2KWidget)
end

function HighlightSubmenuInstance(uiOption)
    if uiOption == nil then return end
    if uiOption.SelectedLabel and uiOption.ButtonLabel then
        uiOption.SelectedLabel:SetHide(false)
        uiOption.ButtonLabel:SetHide(true)
    end

    if uiOption.LabelAlphaAnim then
        uiOption.LabelAlphaAnim:SetToBeginning()
        uiOption.LabelAlphaAnim:Play()
    end

    if uiOption.FlagAnim then
        uiOption.FlagAnim:SetToBeginning()
        uiOption.FlagAnim:Play()
    end
end

function ClearSubmenuHighlights()
    local controls = m_subOptionIM and m_subOptionIM.m_AllocatedInstances
    for _, uiOption in ipairs(controls) do
        if uiOption.SelectedLabel and uiOption.ButtonLabel then
            uiOption.SelectedLabel:SetHide(true)
            uiOption.ButtonLabel:SetHide(false)
        end

        if uiOption.FlagAnim then uiOption.FlagAnim:SetToBeginning(); uiOption.FlagAnim:Stop() end
    end
end

ToggleOption = WrapFunc(ToggleOption, function(orig, optionIndex, submenu)
    if m_currentOptions[optionIndex] then
        m_submenuLabel = m_currentOptions[optionIndex].control.ButtonLabel:GetText()
    end
    orig(optionIndex, submenu)
end)

BuildSubMenu = WrapFunc(BuildSubMenu, function(orig, menuOptions)
    orig(menuOptions)
    local controls = m_subOptionIM and m_subOptionIM.m_AllocatedInstances
    if not controls or #controls == 0 then return end

	if not m_SubmenuList then
		m_SubmenuList = mgr:CreateUIWidget("List", {
			GetLabel = function() return m_submenuLabel end,
		})
		m_SubmenuList:AddInputBinding({Key = Keys.VK_ESCAPE, Action = function(w)
			mgr:Pop()
			for i, option in ipairs(m_currentOptions) do
        if option.isSelected then
            ToggleOption(i) 
        end
    end
	m_SubmenuList = nil
			return true
			end})
	end
	local isBuilt
	if #m_SubmenuList.Children ~= #controls then
		m_SubmenuList:ClearChildren()
	isBuilt = true
    for i, data in ipairs(menuOptions) do
        local control = controls[i]
        
        if control then
            local mainLabel = control.ButtonLabel:GetText()
            local hasHelpElement = data.helpCallback ~= nil

            if hasHelpElement then
                local helpGroup = mgr:CreateUIWidget("SubMenu", {
                    GetLabel = function() return mainLabel end,
                    OnFocusEnter = function()
                        HighlightSubmenuInstance(control)
                    end
                })

                local playButton = mgr:CreateUIWidget("MenuItem", {
                    GetLabel = function() return Locale.Lookup("LOC_CAI_PLAY_NOW") end,
                    GetTooltip = function() return control.Top:GetToolTipString() end,
                    IsHidden = function() return control.Top:IsDisabled() end,
                    IsDisabled = function() return control.OptionButton:IsDisabled() end,
                    OnClick = function() data.callback() end,
                    OnFocusEnter = function()
                        HighlightSubmenuInstance(control)
                    end
                })

                local helpButton = mgr:CreateUIWidget("MenuItem", {
                    GetLabel = function() return Locale.Lookup("LOC_CAI_HELP") end,
                    GetTooltip = function() return control.HelpButton:GetToolTipString() end,
                    IsDisabled = function() return control.HelpButton:IsDisabled() end,
                    IsHidden = function() return control.HelpButton:IsHidden() end,
                    OnClick = function()
                        if data.helpCallback then
                            data.helpCallback()
                        end
                    end
                })

                helpGroup:AddChild(playButton)
                helpGroup:AddChild(helpButton)
                m_SubmenuList:AddChild(helpGroup)
            else
                local standardButton = mgr:CreateUIWidget("MenuItem", {
                    GetLabel = function() return mainLabel end,
                    GetTooltip = function() return control.Top:GetToolTipString() end,
                    IsDisabled = function() return control.OptionButton:IsDisabled() end,
					IsHidden = function() return data.space or control.Top:IsHidden() end,
                    OnClick = function() data.callback() end,
                    OnFocusEnter = function()
                        HighlightSubmenuInstance(control)
                    end
                })
                m_SubmenuList:AddChild(standardButton)
            end
        end
    end
end
	if isBuilt then
		mgr:Push(m_SubmenuList)
	end
end)

OnShutdown = WrapFunc(OnShutdown, function() mgr:ShutDown() end)

Initialize();