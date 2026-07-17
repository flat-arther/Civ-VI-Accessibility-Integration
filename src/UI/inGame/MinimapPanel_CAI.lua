include("caiUtils")
include("Civ6Common")
if GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_BLACKDEATH" then
    include("MinimapPanel_BlackDeathScenario")
elseif IsExpansion2Active() then
    include("MinimapPanel_Expansion2")
elseif IsExpansion1Active() then
    include("MinimapPanel_Expansion1")
else
    include("MinimapPanel")
end

local mgr = ExposedMembers.CAI_UIManager

local LENS_LIST_WIDGET_ID = "CAIMinimapLensList"
local m_caiLensList = nil ---@type UIWidget|nil
local m_isBlackDeathScenario = GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_BLACKDEATH"

ExposedMembers.CAIPlagueLensActive = false

local function PublishPlagueLensState(isActive)
    if ExposedMembers.CAIPlagueLensActive == isActive then
        return
    end

    ExposedMembers.CAIPlagueLensActive = isActive
    LuaEvents.CAIPlagueLensChanged(isActive)
end

if m_isBlackDeathScenario then
    RefreshInterfaceMode = WrapFunc(RefreshInterfaceMode, function(orig, ...)
        orig(...)
        PublishPlagueLensState(UILens.IsLensActive("Plague"))
    end)

    TurnPlagueLensOn = WrapFunc(TurnPlagueLensOn, function(orig, ...)
        orig(...)
        PublishPlagueLensState(true)
    end)

    TurnPlagueLensOff = WrapFunc(TurnPlagueLensOff, function(orig, ...)
        orig(...)
        PublishPlagueLensState(false)
    end)
end

local function ControlIsHidden(control)
    return control == nil or (control.IsHidden ~= nil and control:IsHidden())
end

local function ControlIsDisabled(control)
    return control ~= nil and control.IsDisabled ~= nil and control:IsDisabled()
end

local function ControlText(control)
    if control == nil then
        return ""
    end

    if control.GetText ~= nil then
        local text = control:GetText()
        if text ~= nil and text ~= "" then
            return text
        end
    end

    if control.GetTextButton ~= nil then
        local textButton = control:GetTextButton()
        if textButton ~= nil and textButton.GetText ~= nil then
            local text = textButton:GetText()
            if text ~= nil and text ~= "" then
                return text
            end
        end
    end

    return ""
end

local function ControlTooltip(control)
    if control ~= nil and control.GetToolTipString ~= nil then
        local tooltip = control:GetToolTipString()
        if tooltip ~= nil and tooltip ~= "" then
            return tooltip
        end
    end

    return ""
end

local function CloseLensListWidget()
    if mgr ~= nil then
        mgr:RemoveFromStack(LENS_LIST_WIDGET_ID)
    end
    m_caiLensList = nil
end

local function IsLensListAvailable()
    return mgr ~= nil
        and Game.GetLocalPlayer() ~= -1
        and UI.GetInterfaceMode() ~= InterfaceModeTypes.DISTRICT_PLACEMENT
        and not GameConfiguration.IsWorldBuilderEditor()
        and GameCapabilities.HasCapability("CAPABILITY_LENS_TOGGLING_UI")
        and not ControlIsHidden(Controls.LensButton)
end

local lensEntries = {
    {
        Id = "Religion",
        GetControl = function() return Controls.ReligionLensButton end,
        Toggle = function()
            LensPanelHotkeyControl(Controls.ReligionLensButton); ToggleReligionLens(); UI.PlaySound("Play_UI_Click");
        end,
    },
    {
        Id = "Continent",
        GetControl = function() return Controls.ContinentLensButton end,
        Toggle = function()
            LensPanelHotkeyControl(Controls.ContinentLensButton); ToggleContinentLens(); UI.PlaySound("Play_UI_Click");
        end,
    },
    {
        Id = "Appeal",
        GetControl = function() return Controls.AppealLensButton end,
        Toggle = function()
            LensPanelHotkeyControl(Controls.AppealLensButton); ToggleAppealLens(); UI.PlaySound("Play_UI_Click");
        end,
    },
    {
        Id = "Water",
        GetControl = function() return Controls.WaterLensButton end,
        Toggle = function()
            LensPanelHotkeyControl(Controls.WaterLensButton); ToggleWaterLens(); UI.PlaySound("Play_UI_Click");
        end,
    },
    {
        Id = "Government",
        GetControl = function() return Controls.GovernmentLensButton end,
        Toggle = function()
            LensPanelHotkeyControl(Controls.GovernmentLensButton); ToggleGovernmentLens(); UI.PlaySound("Play_UI_Click");
        end,
    },
    {
        Id = "Owner",
        GetControl = function() return Controls.OwnerLensButton end,
        Toggle = function()
            LensPanelHotkeyControl(Controls.OwnerLensButton); ToggleOwnerLens(); UI.PlaySound("Play_UI_Click");
        end,
    },
    {
        Id = "Tourism",
        GetControl = function() return Controls.TourismLensButton end,
        Toggle = function()
            LensPanelHotkeyControl(Controls.TourismLensButton); ToggleTourismLens(); UI.PlaySound("Play_UI_Click");
        end,
    },
}

if IsExpansion1Active() and Controls.LoyaltyLensButton ~= nil then
    table.insert(lensEntries, {
        Id = "Loyalty",
        GetControl = function() return Controls.LoyaltyLensButton end,
        Toggle = function()
            LensPanelHotkeyControl(Controls.LoyaltyLensButton); ToggleLoyaltyLens(); UI.PlaySound("Play_UI_Click");
        end,
    })
end

if IsExpansion2Active() and Controls.PowerLensButton ~= nil then
    table.insert(lensEntries, {
        Id = "Power",
        GetControl = function() return Controls.PowerLensButton end,
        Toggle = function()
            LensPanelHotkeyControl(Controls.PowerLensButton); TogglePowerLens(); UI.PlaySound("Play_UI_Click");
        end,
    })
end

if m_isBlackDeathScenario then
    table.insert(lensEntries, {
        Id = "Plague",
        GetControl = function()
            return GetBlackDeathPlagueLensButton()
        end,
        Toggle = function()
            LuaEvents.OnViewPlagueLens()
        end,
    })
end

local function GetLensEntryLabel(entry)
    local control = entry.GetControl()
    local text = ControlText(control)
    if text ~= "" then
        return text
    end

    local tooltip = ControlTooltip(control)
    if tooltip ~= "" then
        return tooltip
    end

    return entry.Id
end

local function OpenLensListWidget()
    if not IsLensListAvailable() then
        return false
    end

    if m_caiLensList ~= nil and mgr ~= nil and mgr:HasWidget(m_caiLensList) then
        return true
    end

    local list = mgr:CreateWidget(LENS_LIST_WIDGET_ID, "List", {
        Label = function()
            return Locale.Lookup("LOC_CAI_MINIMAP_LENS_LIST")
        end,
    })
    list:AddInputBindings({
        {
            Key = Keys.VK_ESCAPE,
            Description = "LOC_CAI_KB_CLOSE",
            Action = function()
                CloseLensListWidget()
                return true
            end
        },
    })

    for _, entry in ipairs(lensEntries) do
        local capturedEntry = entry
        local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAIMinimapLensItem"), "MenuItem", {
            Label = function()
                return GetLensEntryLabel(capturedEntry)
            end,
            Tooltip = function()
                return ControlTooltip(capturedEntry.GetControl())
            end,
            State = function()
                local control = capturedEntry.GetControl()
                if ControlIsDisabled(control) then
                    return Locale.Lookup("LOC_CAI_STATE_DISABLED")
                end
                if control ~= nil and control.IsChecked ~= nil and control:IsChecked() then
                    return Locale.Lookup("LOC_CAI_STATE_SELECTED")
                end
                return nil
            end,
            IsHidden = function()
                return not IsLensListAvailable() or ControlIsHidden(capturedEntry.GetControl())
            end,
            IsDisabled = function()
                return ControlIsDisabled(capturedEntry.GetControl())
            end,
        })
        item:SetFocusSound("Main_Menu_Mouse_Over")
        item:On("activate", function()
            if ControlIsHidden(capturedEntry.GetControl()) or ControlIsDisabled(capturedEntry.GetControl()) then
                return
            end
            capturedEntry.Toggle()
            CloseLensListWidget()
        end)
        list:AddChild(item)
    end

    if #list:GetVisibleChildren() > 0 then
        m_caiLensList = list
        mgr:Push(list, { priority = PopupPriority.Low })
        return true
    end

    CloseLensListWidget()
    return false
end

local function ToggleAccessibleLensList()
    if not IsLensListAvailable() then
        if UI.GetInterfaceMode() == InterfaceModeTypes.DISTRICT_PLACEMENT then
            Speak(Locale.Lookup("LOC_CAI_UI_LENSES_DISTRICT_PLACEMENT"))
        elseif GameConfiguration.IsWorldBuilderEditor()
            or not GameCapabilities.HasCapability("CAPABILITY_LENS_TOGGLING_UI") then
            Speak(Locale.Lookup("LOC_CAI_UI_LENSES_UNAVAILABLE"))
        else
            Speak(Locale.Lookup("LOC_CAI_UI_LENSES_UNAVAILABLE_NOW"))
        end
        return false
    end

    if m_caiLensList ~= nil and mgr ~= nil and mgr:HasWidget(m_caiLensList) then
        CloseLensListWidget()
        return true
    end

    return OpenLensListWidget()
end

local m_caiOpenMapSearchId = Input.GetActionId("UI_CAIOpenMapSearch")



local function CloseVanillaMapSearch()
    if not Controls.MapSearchPanel:IsHidden() then
        ToggleMapSearchPanel()
    end
end

OnInputActionStarted = WrapFunc(OnInputActionTriggered, function(orig, actionId)
    if m_caiOpenMapSearchId ~= nil and actionId == m_caiOpenMapSearchId then
        if Game.GetLocalPlayer() == -1 then
            Speak(Locale.Lookup("LOC_CAI_UI_MAP_SEARCH_UNAVAILABLE"))
        elseif UI.GetInterfaceMode() == InterfaceModeTypes.DISTRICT_PLACEMENT then
            Speak(Locale.Lookup("LOC_CAI_UI_MAP_SEARCH_DISTRICT_PLACEMENT"))
        elseif GameConfiguration.IsWorldBuilderEditor() then
            Speak(Locale.Lookup("LOC_CAI_UI_MAP_SEARCH_WORLD_BUILDER"))
        else
            orig(Input.GetActionId("OpenMapSearch"))
        end
        return
    end

    orig(actionId)
end)
Events.InputActionStarted.Add(OnInputActionStarted)

LateInitialize = WrapFunc(LateInitialize, function(orig, ...)
    orig(...)
    Events.InputActionTriggered.Remove(OnInputActionTriggered)
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
    if mgr ~= nil then
        local handled = mgr:HandleInput(pInputStruct)
        if handled then
            return handled
        end
    end

    return orig(pInputStruct)
end)

ToggleMapPinMode = WrapFunc(ToggleMapPinMode, function(orig)
    orig()
    local isVisible = not Controls.MapPinListPanel:IsHidden()
    LuaEvents.CAIMapPinList_VisibilityChanged(isVisible)
end)
Controls.MapPinListButton:RegisterCallback(Mouse.eLClick, ToggleMapPinMode)

local function CloseMapPinList()
    if Controls.MapPinListPanel:IsHidden() then return end
    ToggleMapPinMode()
end

local function ToggleAccessibleMapPinList()
    if mgr == nil or Game.GetLocalPlayer() == -1 then
        Speak(Locale.Lookup("LOC_CAI_UI_MAP_PINS_UNAVAILABLE"))
        return false
    end
    if UI.GetInterfaceMode() == InterfaceModeTypes.DISTRICT_PLACEMENT then
        Speak(Locale.Lookup("LOC_CAI_UI_MAP_PINS_DISTRICT_PLACEMENT"))
        return false
    end
    if GameConfiguration.IsWorldBuilderEditor() then
        Speak(Locale.Lookup("LOC_CAI_UI_MAP_PINS_WORLD_BUILDER"))
        return false
    end
    if ControlIsHidden(Controls.MapPinListButton) or ControlIsDisabled(Controls.MapPinListButton) then
        Speak(Locale.Lookup("LOC_CAI_UI_MAP_PINS_UNAVAILABLE"))
        return false
    end
    ToggleMapPinMode()
    return true
end

OnShutdown = WrapFunc(OnShutdown, function(orig)
    Events.InputActionStarted.Remove(OnInputActionStarted)
    PublishPlagueLensState(false)
    LuaEvents.CAIMinimapLensListToggle.Remove(ToggleAccessibleLensList)
    LuaEvents.CAIMinimapMapPinListToggle.Remove(ToggleAccessibleMapPinList)
    LuaEvents.CAIMapPinList_RequestClose.Remove(CloseMapPinList)
    LuaEvents.CAIMapSearch_RequestClose.Remove(CloseVanillaMapSearch)
    CloseLensListWidget()
    orig()
end)

LuaEvents.CAIMinimapLensListToggle.Remove(ToggleAccessibleLensList)
LuaEvents.CAIMinimapLensListToggle.Add(ToggleAccessibleLensList)
LuaEvents.CAIMinimapMapPinListToggle.Remove(ToggleAccessibleMapPinList)
LuaEvents.CAIMinimapMapPinListToggle.Add(ToggleAccessibleMapPinList)
LuaEvents.CAIMapPinList_RequestClose.Remove(CloseMapPinList)
LuaEvents.CAIMapPinList_RequestClose.Add(CloseMapPinList)
LuaEvents.CAIMapSearch_RequestClose.Remove(CloseVanillaMapSearch)
LuaEvents.CAIMapSearch_RequestClose.Add(CloseVanillaMapSearch)
ContextPtr:SetShutdown(OnShutdown)
ContextPtr:SetInputHandler(OnInputHandler, true)
