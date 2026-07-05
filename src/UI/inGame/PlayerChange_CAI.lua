include("caiUtils")
include("PlayerChange")

local mgr = ExposedMembers.CAI_UIManager

local m_dialog = nil ---@type UIWidget|nil
local m_passwordEdit = nil ---@type UIWidget|nil

local function GetControlText(control)
    if control and control.GetText then
        return control:GetText() or ""
    end
    return ""
end

local function GetControlTooltip(control)
    if control and control.GetToolTipString then
        return control:GetToolTipString() or ""
    end
    return ""
end

local function RemoveDialog()
    if mgr and m_dialog and mgr:GetWidgetById(m_dialog:GetId()) then
        mgr:RemoveFromStack(m_dialog:GetId())
    end
    m_dialog = nil
    m_passwordEdit = nil
end

local function IsWaitMode()
    return not Controls.PlayerChangingText:IsHidden()
end

local function IsPasswordMode()
    return not Controls.PasswordStack:IsHidden()
end

local function GetDialogTitle()
    if IsWaitMode() then
        return GetControlText(Controls.PlayerChangingText)
    end
    return GetControlText(Controls.TitleText)
end

local function MakePasswordEdit()
    local edit = mgr:CreateWidget("CAIPlayerChangePassword", "EditBox", {
        Label = function()
            return GetControlText(Controls.PasswordText)
        end,
        DisabledPredicate = function()
            return Controls.PasswordEntry:IsDisabled()
        end,
        FocusKey = "playerchange:password",
    })
    edit:SetAlwaysEdit(true)
    edit:SetHighlightOnEdit(true)
    edit:SetPasswordMask(true)
    edit:SetMaxCharacters(32)
    edit:SetCommitOnFocusLeave(false)
    edit:On("text_changed", function(_, text)
        Controls.PasswordEntry:SetText(text)
        OnPasswordEntryStringChanged(Controls.PasswordEntry)
    end)
    edit:On("value_changed", function()
        OnPasswordEntryCommit()
    end)
    edit:SetText(GetControlText(Controls.PasswordEntry), true)
    return edit
end

local function MakeButton(id, native, focusKey, onActivate)
    local button = mgr:CreateWidget(id, "Button", {
        Label = function()
            return GetControlText(native)
        end,
        Tooltip = function()
            return GetControlTooltip(native)
        end,
        HiddenPredicate = function()
            return native and native.IsHidden and native:IsHidden() or false
        end,
        DisabledPredicate = function()
            return native and native.IsDisabled and native:IsDisabled() or false
        end,
        FocusKey = focusKey,
    })
    button:SetFocusSound("Main_Menu_Mouse_Over")
    button:On("activate", onActivate)
    return button
end

local function BuildContentRows()
    local rows = {}
    if IsWaitMode() then
        return rows
    end

    if IsPasswordMode() then
        m_passwordEdit = MakePasswordEdit()
        table.insert(rows, m_passwordEdit)
    end

    return rows
end

local function BuildButtons()
    local buttons = {}
    local defaultIndex = 1

    if not IsWaitMode() then
        local okButton = MakeButton(
            "CAIPlayerChange_OK",
            Controls.OkButton,
            "playerchange:ok",
            function()
                Controls.OkButton:DoLeftClick()
            end
        )
        table.insert(buttons, okButton)
        defaultIndex = #buttons

        local saveButton = MakeButton(
            "CAIPlayerChange_Save",
            Controls.SaveButton,
            "playerchange:save",
            function()
                Controls.SaveButton:DoLeftClick()
            end
        )
        table.insert(buttons, saveButton)
    end

    local menuButton = mgr:CreateWidget("CAIPlayerChange_Menu", "Button", {
        Label = function()
            return GetControlTooltip(Controls.MenuButton)
        end,
        HiddenPredicate = function()
            return Controls.MenuButton:IsHidden()
        end,
        DisabledPredicate = function()
            return Controls.MenuButton:IsDisabled()
        end,
        FocusKey = "playerchange:menu",
    })
    menuButton:SetFocusSound("Main_Menu_Mouse_Over")
    menuButton:On("activate", function()
        Controls.MenuButton:DoLeftClick()
    end)
    table.insert(buttons, menuButton)

    return buttons, defaultIndex
end

local function BuildDialog()
    RemoveDialog()
    if not mgr or ContextPtr:IsHidden() then return end

    local contentRows = BuildContentRows()
    local buttons, defaultIndex = BuildButtons()
    m_dialog = mgr.WidgetHelpers.MakeGeneralDialog(GetDialogTitle, buttons, contentRows, defaultIndex)
    if not m_dialog then return end

    if IsPasswordMode() then
        Controls.PasswordEntry:DropFocus()
    end

    local pushOpts = { priority = PopupPriority.PlayerChange }
    if m_passwordEdit then
        pushOpts.focus = m_passwordEdit
    end
    mgr:Push(m_dialog, pushOpts)
end

ShowTurnControls = WrapFunc(ShowTurnControls, function(orig, ...)
    local result = orig(...)
    if not ContextPtr:IsHidden() then
        BuildDialog()
    end
    return result
end)

OnOk = WrapFunc(OnOk, function(orig, ...)
    RemoveDialog()
    return orig(...)
end)

ContextPtr:SetHideHandler(function()
    RemoveDialog()
end)

function OnInputHandler(pInputStruct)
    if mgr and m_dialog and mgr:GetTop() == m_dialog and not ContextPtr:IsHidden() then
        local handled = mgr:HandleInput(pInputStruct)
        if handled then return handled end
    end
    local uiMsg = pInputStruct:GetMessageType()
    local wParam = pInputStruct:GetKey()
    if uiMsg == KeyEvents.KeyUp then
        if wParam == Keys.VK_RETURN then
            OnKeyUp_Return()
        elseif wParam == Keys.VK_ESCAPE then
            OnMenu()
        end
    end
    return false
end

ContextPtr:SetInputHandler(OnInputHandler, true)
