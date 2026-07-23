-- Accessible scanner category management UI.

CAIWorldScannerCategoryManager = {}
local M = CAIWorldScannerCategoryManager
local Config = CAIWorldScannerCategoryConfig

local ROOT_ID = "CAIWorldScannerCategoryManager"
local m_mgr = nil
local m_root = nil
local m_list = nil
local m_parentRoot = nil
local m_parentPreviousFocus = nil
local m_parentLastFocusedKey = nil
local m_parentLastFocusedChild = nil
local m_deleteDialog = nil
local m_deletePreviousFocus = nil
local m_resetDialog = nil
local m_resetPreviousFocus = nil
local m_changedCallback = nil
local m_dirty = false

local RebuildUI
local RebuildListForDialog

local function SafeId(value)
    return tostring(value or ""):gsub("[^%w_]", "_")
end

local function NotifyChanged()
    m_dirty = true
end

local function FlushChanged()
    if not m_dirty then return end
    m_dirty = false
    if m_changedCallback ~= nil then m_changedCallback() end
end

function M.SetChangedCallback(callback)
    m_changedCallback = callback
end

local function CloseResetDialog()
    local dialog = m_resetDialog
    local previousFocus = m_resetPreviousFocus
    m_resetDialog = nil
    m_resetPreviousFocus = nil
    if dialog ~= nil and dialog.Parent ~= nil then dialog:Destroy() end
    if m_mgr == nil or m_root == nil or m_parentRoot == nil
        or m_mgr:GetTop() ~= m_parentRoot then return end
    if previousFocus ~= nil and previousFocus.Parent ~= nil then
        m_mgr:SetFocus(previousFocus)
    else
        m_mgr:SetFocus(m_root)
    end
end

local function AddEscapeBinding(widget, closeFn)
    widget:AddInputBinding({
        Key = Keys.VK_ESCAPE,
        MSG = KeyEvents.KeyUp,
        Description = "LOC_CAI_KB_CLOSE",
        Action = function()
            closeFn()
            return true
        end,
    })
end

local function CreateSettingCheckbox(settingId)
    local checkbox = m_mgr:CreateWidget(
        m_mgr:GenerateWidgetId("CAIScannerCategorySetting_" .. SafeId(settingId)),
        "Checkbox",
        {
            Label = function() return CAISettings.GetLabel(settingId) end,
            Tooltip = function() return CAISettings.GetTooltip(settingId) end,
            FocusKey = "category-setting:" .. settingId,
        }
    )
    checkbox:SetChecked(CAISettings.GetBool(settingId), true)
    checkbox:SetValueSetter(function(_, value)
        CAISettings.SetBool(settingId, value)
    end)
    return checkbox
end

local function CreateEnabledCheckbox(entry)
    local checkbox = m_mgr:CreateWidget(
        m_mgr:GenerateWidgetId("CAIScannerCategoryEnabled_" .. SafeId(entry.Id)),
        "Checkbox",
        {
            Label = function() return Locale.Lookup("LOC_CAI_WORLD_SCANNER_CATEGORY_ENABLED") end,
            Tooltip = function() return Locale.Lookup("LOC_CAI_WORLD_SCANNER_CATEGORY_ENABLED_TOOLTIP") end,
            FocusKey = "category-enabled:" .. entry.Id,
        }
    )
    checkbox:SetChecked(Config.IsEnabled(entry.Id), true)
    checkbox:SetValueSetter(function(_, value)
        Config.SetEnabled(entry.Id, value)
        NotifyChanged()
    end)
    return checkbox
end

local function CreateTermEditor(entry, kind)
    local custom = entry.Custom
    local keyPrefix = "category-term:" .. custom.Id .. ":" .. kind
    local submenu = m_mgr:CreateWidget(
        m_mgr:GenerateWidgetId("CAIScannerCategoryTerms_" .. SafeId(custom.Id .. kind)),
        "SubMenu",
        {
            Label = function()
                return Locale.Lookup(kind == "Include"
                    and "LOC_CAI_WORLD_SCANNER_CUSTOM_INCLUDE_NAMES"
                    or "LOC_CAI_WORLD_SCANNER_CUSTOM_EXCLUDE_NAMES")
            end,
            FocusKey = keyPrefix,
        }
    )
    local function AddRemoveButton(index, term)
        local capturedIndex = index
        local capturedTerm = term
        local remove = m_mgr:CreateWidget(
            m_mgr:GenerateWidgetId("CAIScannerCategoryRemoveTerm_" .. SafeId(custom.Id .. kind)),
            "Button",
            {
                Label = function()
                    return Locale.Lookup("LOC_CAI_WORLD_SCANNER_CUSTOM_REMOVE_TERM", capturedTerm)
                end,
                FocusKey = keyPrefix .. ":term:" .. tostring(index),
            }
        )
        remove:On("activate", function()
            if Config.RemoveTerm(custom.Id, kind, capturedIndex) then
                NotifyChanged()
                local remainingCount = #custom[kind]
                local targetIndex = math.min(capturedIndex, remainingCount)
                local focusKey = targetIndex > 0
                    and keyPrefix .. ":term:" .. tostring(targetIndex)
                    or keyPrefix .. ":add"
                RebuildUI(focusKey)
            end
        end)
        submenu:AddChild(remove)
    end

    local edit = m_mgr:CreateWidget(
        m_mgr:GenerateWidgetId("CAIScannerCategoryAddTerm_" .. SafeId(custom.Id .. kind)),
        "EditBox",
        {
            Label = function() return Locale.Lookup("LOC_CAI_WORLD_SCANNER_CUSTOM_ADD_TERM") end,
            Tooltip = function() return Locale.Lookup("LOC_CAI_WORLD_SCANNER_CUSTOM_ADD_TERM_TOOLTIP") end,
            FocusKey = keyPrefix .. ":add",
        }
    )
    edit:SetText("", true)
    edit:SetCommitValidator(function(text)
        local valid, reason = Config.ValidateTerm(custom.Id, kind, text)
        if valid then return nil end
        if reason == "duplicate" then
            return Locale.Lookup("LOC_CAI_WORLD_SCANNER_CUSTOM_TERM_DUPLICATE")
        else
            return Locale.Lookup("LOC_CAI_WORLD_SCANNER_CUSTOM_TERM_EMPTY")
        end
    end)
    edit:SetValueSetter(function(_, value)
        if Config.AddTerm(custom.Id, kind, value) then
            NotifyChanged()
            local index = #custom[kind]
            AddRemoveButton(index, custom[kind][index])
            edit:SetText("", true)
        end
    end)
    submenu:AddChild(edit)

    for index, term in ipairs(custom[kind]) do
        AddRemoveButton(index, term)
    end
    return submenu
end

local function CreateSourceSelector(entry, definition)
    local custom = entry.Custom
    local categoryId = definition.Id
    local keyPrefix = "category-source:" .. custom.Id .. ":" .. categoryId
    local submenu = m_mgr:CreateWidget(
        m_mgr:GenerateWidgetId("CAIScannerCategorySource_" .. SafeId(custom.Id .. categoryId)),
        "SubMenu",
        {
            Label = function()
                return Locale.Lookup("LOC_CAI_WORLD_SCANNER_CATEGORY_ROW",
                    Locale.Lookup(definition.LabelKey), Config.GetTypeLabel(categoryId))
            end,
            Tooltip = function() return Config.GetTooltip(categoryId) end,
            FocusKey = keyPrefix,
        }
    )

    local allCheckbox = m_mgr:CreateWidget(
        m_mgr:GenerateWidgetId("CAIScannerCategorySourceAll_" .. SafeId(custom.Id .. categoryId)),
        "Checkbox",
        {
            Label = function() return Locale.Lookup("LOC_CAI_WORLD_SCANNER_SUBCATEGORY_ALL") end,
            FocusKey = keyPrefix .. ":__all",
        }
    )
    local subCheckboxes = {}
    local function RefreshChecks()
        allCheckbox:SetChecked(Config.IsAllSelected(custom.Id, categoryId), true)
        for subCategoryId, checkbox in pairs(subCheckboxes) do
            checkbox:SetChecked(Config.IsSubSelected(custom.Id, categoryId, subCategoryId), true)
        end
    end
    allCheckbox:SetValueSetter(function(_, value)
        if Config.SetAllSelected(custom.Id, categoryId, value) then
            RefreshChecks()
            NotifyChanged()
        end
    end)
    submenu:AddChild(allCheckbox)

    for _, subCategoryId in ipairs(definition.SubCategoryOrder or {}) do
        local capturedSubCategoryId = subCategoryId
        local checkbox = m_mgr:CreateWidget(
            m_mgr:GenerateWidgetId("CAIScannerCategorySourceSub_" .. SafeId(custom.Id .. categoryId)),
            "Checkbox",
            {
                Label = function()
                    return Locale.Lookup(definition.SubCategoryLabels[capturedSubCategoryId]
                        or "LOC_CAI_WORLD_SCANNER_UNKNOWN")
                end,
                FocusKey = keyPrefix .. ":" .. capturedSubCategoryId,
            }
        )
        checkbox:SetValueSetter(function(_, value)
            if Config.SetSubSelected(custom.Id, categoryId, capturedSubCategoryId, value) then
                RefreshChecks()
                NotifyChanged()
            end
        end)
        subCheckboxes[capturedSubCategoryId] = checkbox
        submenu:AddChild(checkbox)
    end
    RefreshChecks()
    return submenu
end

local function CloseDeleteDialog(focusKey)
    local dialog = m_deleteDialog
    local previousFocus = m_deletePreviousFocus
    m_deleteDialog = nil
    m_deletePreviousFocus = nil
    if dialog ~= nil and dialog.Parent ~= nil then dialog:Destroy() end
    if m_mgr == nil or m_root == nil or m_parentRoot == nil
        or m_mgr:GetTop() ~= m_parentRoot then return end
    local target = focusKey and m_mgr:FindByFocusKey(m_root, focusKey) or nil
    if target ~= nil then
        m_mgr:SetFocus(target)
    elseif previousFocus ~= nil and previousFocus.Parent ~= nil then
        m_mgr:SetFocus(previousFocus)
    else
        m_mgr:SetFocus(m_root)
    end
end

local function ShowDeleteConfirmation(entry)
    if m_deleteDialog ~= nil and m_deleteDialog.Parent ~= nil then return end
    m_deletePreviousFocus = m_mgr:GetFocusedWidget()
    local customId = entry.Id
    local categoryName = Config.GetLabel(entry)
    local entries = Config.GetEntries()
    local neighborFocusKey = nil
    for index, categoryEntry in ipairs(entries) do
        if categoryEntry.Id == customId then
            local neighbor = entries[index + 1] or entries[index - 1]
            neighborFocusKey = neighbor ~= nil and "category:" .. neighbor.Id or nil
            break
        end
    end
    local message = m_mgr:CreateWidget(m_mgr:GenerateWidgetId("CAIScannerCategoryDeleteMessage"), "StaticText", {
        Label = function()
            return Locale.Lookup("LOC_CAI_WORLD_SCANNER_CUSTOM_DELETE_CONFIRMATION_BODY", categoryName)
        end,
    })
    local yesButton = m_mgr:CreateWidget(m_mgr:GenerateWidgetId("CAIScannerCategoryDeleteYes"), "Button", {
        Label = function() return Locale.Lookup("LOC_YES") end,
    })
    yesButton:On("activate", function()
        local focusKey = nil
        if Config.DeleteCustom(customId) then
            NotifyChanged()
            RebuildListForDialog(neighborFocusKey)
            focusKey = neighborFocusKey
        end
        CloseDeleteDialog(focusKey)
    end)
    local noButton = m_mgr:CreateWidget(m_mgr:GenerateWidgetId("CAIScannerCategoryDeleteNo"), "Button", {
        Label = function() return Locale.Lookup("LOC_NO") end,
    })
    noButton:On("activate", function() CloseDeleteDialog() end)
    m_deleteDialog = m_mgr.WidgetHelpers.MakeGeneralDialog(
        function() return Locale.Lookup("LOC_CAI_WORLD_SCANNER_CUSTOM_DELETE_CONFIRMATION_TITLE") end,
        { yesButton, noButton }, { message }, 1)
    if m_deleteDialog == nil then
        m_deletePreviousFocus = nil
        return
    end
    m_deleteDialog.TrapInput = true
    AddEscapeBinding(m_deleteDialog, CloseDeleteDialog)
    m_parentRoot:AddChild(m_deleteDialog)
    m_mgr:SetFocus(m_deleteDialog)
end

local function CreateCustomChildren(entry, row)
    local custom = entry.Custom
    local nameEdit = m_mgr:CreateWidget(
        m_mgr:GenerateWidgetId("CAIScannerCategoryName_" .. SafeId(custom.Id)),
        "EditBox",
        {
            Label = function() return Locale.Lookup("LOC_CAI_WORLD_SCANNER_CUSTOM_NAME") end,
            FocusKey = "category-name:" .. custom.Id,
        }
    )
    nameEdit:SetText(custom.Name, true)
    nameEdit:SetCommitValidator(function(text)
        if tostring(text or ""):match("^%s*$") then
            return Locale.Lookup("LOC_CAI_WORLD_SCANNER_CUSTOM_NAME_EMPTY")
        end
        return nil
    end)
    nameEdit:SetValueSetter(function(_, value)
        if Config.RenameCustom(custom.Id, value) then NotifyChanged() end
    end)
    row:AddChild(nameEdit)

    local sources = m_mgr:CreateWidget(
        m_mgr:GenerateWidgetId("CAIScannerCategorySources_" .. SafeId(custom.Id)),
        "SubMenu",
        {
            Label = function() return Locale.Lookup("LOC_CAI_WORLD_SCANNER_CUSTOM_SOURCES") end,
            FocusKey = "category-sources:" .. custom.Id,
        }
    )
    for _, definition in ipairs(Config.GetDefinitions()) do
        sources:AddChild(CreateSourceSelector(entry, definition))
    end
    row:AddChild(sources)
    row:AddChild(CreateTermEditor(entry, "Include"))
    row:AddChild(CreateTermEditor(entry, "Exclude"))

    local deleteButton = m_mgr:CreateWidget(
        m_mgr:GenerateWidgetId("CAIScannerCategoryDelete_" .. SafeId(custom.Id)),
        "Button",
        {
            Label = function() return Locale.Lookup("LOC_CAI_WORLD_SCANNER_CUSTOM_DELETE") end,
            FocusKey = "category-delete:" .. custom.Id,
        }
    )
    deleteButton:On("activate", function() ShowDeleteConfirmation(entry) end)
    row:AddChild(deleteButton)
end

local function CreateBuiltInChildren(entry, row)
    local definition = entry.Definition
    for _, settingId in ipairs(definition.ManagementSettings or {}) do
        row:AddChild(CreateSettingCheckbox(settingId))
    end

    local duplicate = m_mgr:CreateWidget(
        m_mgr:GenerateWidgetId("CAIScannerCategoryDuplicate_" .. SafeId(entry.Id)),
        "Button",
        {
            Label = function() return Locale.Lookup("LOC_CAI_WORLD_SCANNER_CREATE_CUSTOM_FROM_CATEGORY") end,
            FocusKey = "category-duplicate:" .. entry.Id,
        }
    )
    duplicate:On("activate", function()
        local custom = Config.CreateCustom(entry.Id)
        NotifyChanged()
        RebuildUI("category-name:" .. custom.Id)
    end)
    row:AddChild(duplicate)

    local moveDefault = m_mgr:CreateWidget(
        m_mgr:GenerateWidgetId("CAIScannerCategoryMoveDefault_" .. SafeId(entry.Id)),
        "Button",
        {
            Label = function() return Locale.Lookup("LOC_CAI_WORLD_SCANNER_MOVE_DEFAULT_POSITION") end,
            FocusKey = "category-default-position:" .. entry.Id,
        }
    )
    moveDefault:On("activate", function()
        if Config.MoveToDefaultPosition(entry.Id) then
            NotifyChanged()
            RebuildUI("category:" .. entry.Id)
        end
    end)
    row:AddChild(moveDefault)
end

local function CreateCategoryRow(entry)
    local row = m_mgr:CreateWidget(
        m_mgr:GenerateWidgetId("CAIScannerCategoryRow_" .. SafeId(entry.Id)),
        "SubMenu",
        {
            Label = function()
                local state = Locale.Lookup(Config.IsEnabled(entry.Id)
                    and "LOC_CAI_WORLD_SCANNER_CATEGORY_STATE_ENABLED"
                    or "LOC_CAI_WORLD_SCANNER_CATEGORY_STATE_DISABLED")
                return Locale.Lookup("LOC_CAI_WORLD_SCANNER_MANAGEMENT_CATEGORY_ROW",
                    Config.GetLabel(entry), Config.GetTypeLabel(entry), state)
            end,
            Tooltip = function() return Config.GetTooltip(entry) end,
            FocusKey = "category:" .. entry.Id,
        }
    )
    row:AddInputBindings({
        {
            Key = Keys.VK_UP,
            MSG = KeyEvents.KeyDown,
            IsShift = true,
            Description = "LOC_CAI_KB_MOVE_CATEGORY_UP",
            Action = function()
                if m_mgr:GetFocusedWidget() ~= row then return false end
                if Config.Move(entry.Id, -1) then
                    NotifyChanged()
                    RebuildUI("category:" .. entry.Id)
                end
                return true
            end,
        },
        {
            Key = Keys.VK_DOWN,
            MSG = KeyEvents.KeyDown,
            IsShift = true,
            Description = "LOC_CAI_KB_MOVE_CATEGORY_DOWN",
            Action = function()
                if m_mgr:GetFocusedWidget() ~= row then return false end
                if Config.Move(entry.Id, 1) then
                    NotifyChanged()
                    RebuildUI("category:" .. entry.Id)
                end
                return true
            end,
        },
    })
    if entry.IsCustom then
        row:AddInputBinding({
            Key = Keys.VK_DELETE,
            MSG = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_DELETE_SCANNER_CATEGORY",
            Action = function()
                if m_mgr:GetFocusedWidget() ~= row then return false end
                ShowDeleteConfirmation(entry)
                return true
            end,
        })
    end
    row:AddChild(CreateEnabledCheckbox(entry))
    if entry.IsCustom then
        CreateCustomChildren(entry, row)
    else
        CreateBuiltInChildren(entry, row)
    end
    return row
end

local function ShowResetConfirmation()
    if m_resetDialog ~= nil and m_resetDialog.Parent ~= nil then return end
    m_resetPreviousFocus = m_mgr:GetFocusedWidget()
    local message = m_mgr:CreateWidget(m_mgr:GenerateWidgetId("CAIScannerCategoryResetMessage"), "StaticText", {
        Label = function() return Locale.Lookup("LOC_CAI_WORLD_SCANNER_RESET_CONFIRMATION_BODY") end,
    })
    local yesButton = m_mgr:CreateWidget(m_mgr:GenerateWidgetId("CAIScannerCategoryResetYes"), "Button", {
        Label = function() return Locale.Lookup("LOC_YES") end,
    })
    yesButton:On("activate", function()
        Config.ResetBuiltInLayout()
        NotifyChanged()
        RebuildListForDialog()
        CloseResetDialog()
    end)
    local noButton = m_mgr:CreateWidget(m_mgr:GenerateWidgetId("CAIScannerCategoryResetNo"), "Button", {
        Label = function() return Locale.Lookup("LOC_NO") end,
    })
    noButton:On("activate", CloseResetDialog)
    m_resetDialog = m_mgr.WidgetHelpers.MakeGeneralDialog(
        function() return Locale.Lookup("LOC_CAI_WORLD_SCANNER_RESET_CONFIRMATION_TITLE") end,
        { yesButton, noButton }, { message }, 1)
    if m_resetDialog == nil then
        m_resetPreviousFocus = nil
        return
    end
    m_resetDialog.TrapInput = true
    AddEscapeBinding(m_resetDialog, CloseResetDialog)
    m_parentRoot:AddChild(m_resetDialog)
    m_mgr:SetFocus(m_resetDialog)
end

local function PopulateCategoryList()
    for _, entry in ipairs(Config.GetEntries()) do
        m_list:AddChild(CreateCategoryRow(entry))
    end
end

RebuildListForDialog = function(focusKey)
    if m_list == nil then return end
    m_list:ClearChildren()
    PopulateCategoryList()
    if focusKey ~= nil then
        m_mgr:PrepareFocus(m_list, focusKey)
    end
end

local function CreateRootChildren()
    m_list = m_mgr:CreateWidget(m_mgr:GenerateWidgetId("CAIScannerCategoryList"), "List", {
        Label = function() return Locale.Lookup("LOC_CAI_WORLD_SCANNER_CATEGORY_LIST") end,
        FocusKey = "category-list",
    })
    PopulateCategoryList()
    m_root:AddChild(m_list)

    local addButton = m_mgr:CreateWidget(m_mgr:GenerateWidgetId("CAIScannerCategoryAdd"), "Button", {
        Label = function() return Locale.Lookup("LOC_CAI_WORLD_SCANNER_CUSTOM_ADD") end,
        FocusKey = "category-action:add",
    })
    addButton:On("activate", function()
        local custom = Config.CreateCustom(nil)
        NotifyChanged()
        RebuildUI("category-name:" .. custom.Id)
    end)
    m_root:AddChild(addButton)

    local resetButton = m_mgr:CreateWidget(m_mgr:GenerateWidgetId("CAIScannerCategoryReset"), "Button", {
        Label = function() return Locale.Lookup("LOC_CAI_WORLD_SCANNER_RESET_BUILT_INS") end,
        Tooltip = function() return Locale.Lookup("LOC_CAI_WORLD_SCANNER_RESET_BUILT_INS_TOOLTIP") end,
        FocusKey = "category-action:reset",
    })
    resetButton:On("activate", ShowResetConfirmation)
    m_root:AddChild(resetButton)
end

RebuildUI = function(focusKey)
    if m_root == nil or m_list == nil then return end
    local capture = focusKey == nil and m_mgr:CaptureFocusKey(m_root) or nil
    m_list:ClearChildren()
    PopulateCategoryList()
    if focusKey ~= nil then
        m_mgr:PrepareFocus(m_root, focusKey)
        local target = m_mgr:FindByFocusKey(m_root, focusKey)
        if target ~= nil then m_mgr:SetFocus(target) end
    else
        m_mgr:RestoreFocus(m_root, capture)
    end
end

function M.Close()
    FlushChanged()
    local manager = m_mgr
    local parentRoot = m_parentRoot
    local previousFocus = m_parentPreviousFocus
    local lastFocusedKey = m_parentLastFocusedKey
    local lastFocusedChild = m_parentLastFocusedChild
    if m_deleteDialog ~= nil and m_deleteDialog.Parent ~= nil then
        m_deleteDialog:Destroy()
    end
    m_deleteDialog = nil
    m_deletePreviousFocus = nil
    if m_resetDialog ~= nil and m_resetDialog.Parent ~= nil then
        m_resetDialog:Destroy()
    end
    m_resetDialog = nil
    m_resetPreviousFocus = nil
    if m_root ~= nil and m_root.Parent ~= nil then
        m_root:Destroy()
    end
    if manager ~= nil and parentRoot ~= nil and manager:GetTop() == parentRoot then
        if previousFocus ~= nil then
            manager:SetFocus(previousFocus)
        else
            parentRoot._lastFocusedKey = lastFocusedKey
            parentRoot._lastFocusedChild = lastFocusedChild
            manager:SetFocus(parentRoot)
        end
    end
end

function M.Open(manager, parentRoot, returnFocus)
    if manager == nil or parentRoot == nil or not Config.IsConfigured() then return false end
    if m_root ~= nil and m_root.Parent ~= nil then return true end
    m_mgr = manager
    m_parentRoot = parentRoot
    m_parentPreviousFocus = returnFocus and returnFocus.PreviousFocus or nil
    if returnFocus ~= nil and returnFocus.PreviousFocus == nil then
        m_parentLastFocusedKey = returnFocus.LastFocusedKey
        m_parentLastFocusedChild = returnFocus.LastFocusedChild
    else
        m_parentLastFocusedKey = parentRoot._lastFocusedKey
        m_parentLastFocusedChild = parentRoot._lastFocusedChild
    end
    m_root = m_mgr:CreateWidget(ROOT_ID, "Panel", {
        Label = function() return Locale.Lookup("LOC_CAI_WORLD_SCANNER_CATEGORY_MANAGER") end,
        FocusKey = "scanner-category-manager",
        WrapAround = true,
        TrapInput = true,
    })
    m_root:On("focus_enter", function() Input.SetActiveContext(InputContext.Shell) end)
    AddEscapeBinding(m_root, M.Close)
    m_root:On("destroy", function()
        FlushChanged()
        m_root = nil
        m_list = nil
        m_parentRoot = nil
        m_parentPreviousFocus = nil
        m_parentLastFocusedKey = nil
        m_parentLastFocusedChild = nil
        m_deleteDialog = nil
        m_deletePreviousFocus = nil
        m_resetDialog = nil
        m_resetPreviousFocus = nil
        m_mgr = nil
    end)
    CreateRootChildren()
    local entries = Config.GetEntries()
    local initialFocus = entries[1] and "category:" .. entries[1].Id or "category-action:add"
    parentRoot:AddChild(m_root)
    m_mgr:PrepareFocus(parentRoot, initialFocus)
    return true
end
