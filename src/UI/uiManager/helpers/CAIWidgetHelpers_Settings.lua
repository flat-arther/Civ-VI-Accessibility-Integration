-- ===========================================================================
-- CAIWidgetHelpers_Settings.lua
-- Builds the CAI settings UI from CAI_Settings / CAI_SettingOptions metadata.
-- Requires CAISettings from caiUtils.
-- ===========================================================================

CAIWidgetHelpers_Settings = {}
local S = CAIWidgetHelpers_Settings

local g_settingsOpen = false
local SETTINGS_PANEL_ID = "CAISettingsPanel"
local SETTINGS_TREE_ID = "CAISettingsTree"
local EDITBOX_EDIT_MODES = {
    Normal = 0,
    LettersOnly = 1,
    NumbersOnly = 2,
    AlphanumericOnly = 3,
}

-- ===========================================================================
-- Small helpers
-- ===========================================================================

local function SafeId(s)
    return tostring(s or ""):gsub("[^%w_]", "_")
end

local function Lookup(tag)
    if tag == nil or tag == "" then return "" end
    return Locale.Lookup(tag)
end

local function SettingLabel(row)
    return function()
        return Lookup(row.Label)
    end
end

local function SettingTooltip(row)
    if row.Tooltip == nil or row.Tooltip == "" then
        return nil
    end

    return function()
        return Lookup(row.Tooltip)
    end
end

local function CategoryLabel(section)
    local loc = "LOC_CAI_SETTING_SECTION_" .. string.upper(tostring(section or ""))
    return function()
        return Locale.Lookup(loc)
    end
end

local function GetRows()
    return CAISettings.GetDefinitions()
end

local function GetOptions(settingId)
    return CAISettings.GetOptions(settingId)
end

-- ===========================================================================
-- Widget builders
-- ===========================================================================

local function CreateCheckbox(mgr, row)
    local w = mgr:CreateWidget("CAISetting_" .. SafeId(row.SettingId), "Checkbox", {
        Label = SettingLabel(row),
        Tooltip = SettingTooltip(row),
        FocusKey = "setting:" .. row.SettingId,
    })

    w:SetChecked(CAISettings.GetBool(row.SettingId), true)

    w:SetValueSetter(function(_, value)
        CAISettings.SetBool(row.SettingId, value)
    end)

    return w
end

local function CreateSlider(mgr, row)
    local w = mgr:CreateWidget("CAISetting_" .. SafeId(row.SettingId), "Slider", {
        Label = SettingLabel(row),
        Tooltip = SettingTooltip(row),
        FocusKey = "setting:" .. row.SettingId,
    })

    w:SetMin(tonumber(row.MinValue) or 0)
    w:SetMax(tonumber(row.MaxValue) or 100)
    w:SetStepSize(tonumber(row.StepValue) or 1)
    w:SetPageStep(tonumber(row.PageStepValue) or 10)

    w:SetValue(CAISettings.GetNumber(row.SettingId), true)

    w:SetValueSetter(function(_, value)
        CAISettings.SetNumber(row.SettingId, value)
    end)

    return w
end

local function CreateDropdown(mgr, row)
    local w = mgr:CreateWidget("CAISetting_" .. SafeId(row.SettingId), "Dropdown", {
        Label = SettingLabel(row),
        Tooltip = SettingTooltip(row),
        FocusKey = "setting:" .. row.SettingId,
    })

    local options = {}
    for _, opt in ipairs(GetOptions(row.SettingId)) do
        table.insert(options, {
            value = opt.Value,
            label = Lookup(opt.Label),
            tooltip = opt.Tooltip and Lookup(opt.Tooltip) or nil,
        })
    end

    w:SetOptions(options)

    local currentValue = CAISettings.GetString(row.SettingId)
    local selectedIndex = 1
    local foundCurrentValue = false

    for i, opt in ipairs(options) do
        if tostring(opt.value) == tostring(currentValue) then
            selectedIndex = i
            foundCurrentValue = true
            break
        end
    end

    if not foundCurrentValue then
        local defaultValue = CAISettings.GetDefault(row.SettingId)
        for i, opt in ipairs(options) do
            if tostring(opt.value) == tostring(defaultValue) then
                selectedIndex = i
                break
            end
        end
    end

    if #options > 0 then
        w:SetSelectedIndex(selectedIndex, true)
    end

    w:SetValueSetter(function(_, value)
        CAISettings.SetString(row.SettingId, value)
    end)

    return w
end

local function CreateText(mgr, row)
    local w = mgr:CreateWidget("CAISetting_" .. SafeId(row.SettingId), "EditBox", {
        Label = SettingLabel(row),
        Tooltip = SettingTooltip(row),
        FocusKey = "setting:" .. row.SettingId,
    })
    local editMode = EDITBOX_EDIT_MODES[tostring(row.EditMode)]
    if editMode then w:SetEditMode(editMode) end

    w:SetText(CAISettings.GetString(row.SettingId), true)


    w:SetValueSetter(function(_, value)
        CAISettings.SetString(row.SettingId, value)
    end)

    return w
end

local function IsInGame()
    return Game ~= nil and Game.GetLocalPlayer ~= nil and Game.GetLocalPlayer() >= 0
end

local function CreateButton(mgr, row)
    local w = mgr:CreateWidget("CAISetting_" .. SafeId(row.SettingId), "Button", {
        Label = SettingLabel(row),
        Tooltip = SettingTooltip(row),
        FocusKey = "setting:" .. row.SettingId,
    })

    if row.DisplayContext == "InGame" then
        w:SetHiddenPredicate(function() return not IsInGame() end)
    end

    w:On("activate", function()
        CAISettings.Invoke(row.SettingId, row.ActionValue)
    end)
    return w
end

local function CreateSettingWidget(mgr, row)
    if row.UIType == "checkbox" then
        return CreateCheckbox(mgr, row)
    end

    if row.UIType == "slider" then
        return CreateSlider(mgr, row)
    end

    if row.UIType == "dropdown" then
        return CreateDropdown(mgr, row)
    end

    if row.UIType == "text" or row.UIType == "editbox" then
        return CreateText(mgr, row)
    end

    if row.UIType == "button" then
        return CreateButton(mgr, row)
    end

    LogWarn("Settings helper unsupported UIType " .. tostring(row.UIType) .. " for " .. tostring(row.SettingId))
    return nil
end

local function ClosePanel(mgr, panel, restoreOwnerFocus)
    if panel == nil then return end
    local ownerRoot = panel.Parent
    local previousFocus = panel._settingsPreviousFocus
    panel:Destroy()
    if ownerRoot ~= nil and mgr:GetTop() == ownerRoot then
        if restoreOwnerFocus ~= false and previousFocus ~= nil then
            mgr:SetFocus(previousFocus)
        else
            mgr:SetFocus(ownerRoot)
        end
    end
    LogMessage("Settings helper closed settings tree")
end

-- ===========================================================================
-- Public
-- ===========================================================================

function S.BuildSettingsTree(mgr)
    if not mgr then
        LogWarn("Settings helper BuildSettingsTree called with nil manager")
        return nil
    end
    local tree = mgr:CreateWidget(SETTINGS_TREE_ID, "Tree", {
        Label = function()
            return Locale.Lookup("LOC_CAI_SETTINGS_TITLE")
        end,
        FocusKey = "cai_settings_root",
    })
    if not tree then
        LogError("Settings helper failed to create settings tree widget")
        return nil
    end

    local categories = {}
    local rowCount = 0
    local widgetCount = 0

    for _, row in ipairs(GetRows()) do
        rowCount = rowCount + 1
        local section = row.Section or "General"
        local category = categories[section]

        if category == nil then
            category = mgr:CreateWidget("CAISettingsCategory_" .. SafeId(section), "TreeItem", {
                Label = CategoryLabel(section),
                FocusKey = "setting_section:" .. section,
            })

            category:Expand(true)
            tree:AddChild(category)
            categories[section] = category
        end

        local settingWidget = CreateSettingWidget(mgr, row)
        if settingWidget ~= nil then
            settingWidget:SetFocusSound("Main_Menu_Mouse_Over")
            category:AddChild(settingWidget)
            widgetCount = widgetCount + 1
        end
    end

    LogMessage("Settings helper built settings tree, rows="
        .. tostring(rowCount) .. ", widgets=" .. tostring(widgetCount)
        .. ", sections=" .. tostring(GetKeys(categories) and #GetKeys(categories) or 0))
    return tree
end

function S.GetSettingsOwnerRoot(mgr)
    if mgr == nil then return nil end
    local panel = mgr:GetWidgetById(SETTINGS_PANEL_ID, true)
    return panel and panel.Parent or nil
end

function S.GetSettingsReturnFocus(mgr)
    if mgr == nil then return nil end
    local panel = mgr:GetWidgetById(SETTINGS_PANEL_ID, true)
    if panel == nil then return nil end
    return {
        PreviousFocus = panel._settingsPreviousFocus,
    }
end

function S.CloseSettings(mgr, restoreOwnerFocus)
    if mgr == nil then return false end
    local panel = mgr:GetWidgetById(SETTINGS_PANEL_ID, true)
    if panel == nil then return false end
    ClosePanel(mgr, panel, restoreOwnerFocus)
    return true
end

function S.OpenSettings(mgr)
    if g_settingsOpen then
        LogWarn("Settings helper OpenSettings ignored because settings UI is already open")
        return false
    end
    local ownerRoot = mgr and mgr:GetTop() or nil
    if ownerRoot == nil then
        LogError("Settings helper OpenSettings failed because there is no active root")
        return false
    end
    local previousFocus = mgr:GetFocusedWidget()
    local tree = S.BuildSettingsTree(mgr)
    if not tree then
        LogError("Settings helper OpenSettings failed because tree creation returned nil")
        return false
    end

    local panel = mgr:CreateWidget(SETTINGS_PANEL_ID, "Panel", {
        Transparent = true,
        WrapAround = true,
        TrapInput = true,
    })
    panel._settingsPreviousFocus = previousFocus
    panel:On("focus_enter", function() Input.SetActiveContext(InputContext.Shell) end)
    panel:On("destroy", function()
        g_settingsOpen = false
        LogMessage("Settings helper settings panel destroyed")
    end)
    panel:AddChild(tree)
    panel:AddInputBindings({ {
        Key = Keys.VK_ESCAPE,
        Description = "LOC_CAI_KB_CLOSE",
        Action = function()
            ClosePanel(mgr, panel)
            return true
        end,
    } })

    g_settingsOpen = true
    ownerRoot:AddChild(panel)
    mgr:SetFocus(tree)
    LogMessage("Settings helper opened settings UI")

    return true
end
