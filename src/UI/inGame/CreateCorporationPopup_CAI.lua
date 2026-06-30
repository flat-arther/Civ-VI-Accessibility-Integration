include("caiUtils")
include("CreateCorporationPopup")

local mgr = ExposedMembers.CAI_UIManager
local m_dialog = nil ---@type DialogWidget|nil

-- ===========================================================================
--	Accessibility Helpers
-- ===========================================================================
local function RemoveDialog()
    if not m_dialog then return end
    mgr:RemoveFromStack(m_dialog:GetId())
    m_dialog = nil
end

local function PushDialog()
    if not mgr then return end
    if m_dialog then
        mgr:Push(m_dialog)
    end
end

local function BuildDialog()
    if not mgr then return end

    local editBox = mgr:CreateWidget(mgr:GenerateWidgetId("CAI_CorpNameEdit"), "EditBox", {
        Label = function() return Locale.Lookup("LOC_NAME_CORPORATION_TITLE") end
    })
    editBox:SetAlwaysEdit(true)
    editBox:SetMaxCharacters(40)
    editBox:SetEnterToCommit(false)

    editBox:SetText(Controls.NameEdit:GetText() or "", true)
    editBox:On("text_changed", function(w, text)
        Controls.NameEdit:SetText(text)
    end)

    local confirmBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAI_CorpConfirmBtn"), "Button", {
        Label = function() return Controls.CorpConfirmButton:GetText() or "" end,
    })
    confirmBtn:On("activate", function(w)
        Controls.CorpConfirmButton:DoLeftClick()
    end)

    local genBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAI_CorpGenerateBtn"), "Button", {
        Label = function() return Controls.CorpGenerateButton:GetText() or "" end,
    })
    genBtn:On("activate", function(w)
        Controls.CorpGenerateButton:DoLeftClick()
        if editBox then
            editBox:SetText(Controls.NameEdit:GetText() or "", false)
        end
    end)

    m_dialog = mgr.WidgetHelpers.MakeGeneralDialog(
        function() return Controls.ModalScreenTitle:GetText() or "" end,
        { genBtn, confirmBtn },
        { editBox },
        1
    )
end

-- ===========================================================================
--	Lifecycle
-- ===========================================================================
StartCorporationShow = WrapFunc(StartCorporationShow, function(orig)
    orig()
    RemoveDialog()
    BuildDialog()
    PushDialog()
end)

Close = WrapFunc(Close, function(orig)
    RemoveDialog()
    orig()
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
    if mgr and m_dialog and mgr:GetTop() == m_dialog and not ContextPtr:IsHidden() then
        local handled = mgr:HandleInput(pInputStruct)
        if handled then return handled end
    end
    return orig(pInputStruct)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)
