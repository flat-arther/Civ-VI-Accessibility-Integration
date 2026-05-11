include("caiUtils")
include("TechCivicCompletedPopup")
local mgr = ExposedMembers.CAI_UIManager

local m_dialog = nil ---@type UIWidget|nil

local function PopExisting()
    if mgr and m_dialog and mgr:GetTop() == m_dialog then
        mgr:Pop()
    end
    m_dialog = nil
end

local function BuildDialog()
    local content = {}
    local function addText(idSuffix, getText)
        table.insert(content, mgr:CreateUIWidget(
            mgr:GenerateWidgetId("CAITechCivicPopup" .. idSuffix),
            "StaticText",
            { GetValue = getText }))
    end

    addText("Name", function() return Controls.ResearchName:GetText() end)
    addText("CivicMsg", function()
        if Controls.CivicMsgLabel:IsHidden() then return "" end
        return Controls.CivicMsgLabel:GetText()
    end)
    addText("Unlocks", function() return Controls.UnlockCountLabel:GetText() end)
    addText("Quote", function()
        if Controls.QuoteButton:IsHidden() then return "" end
        return Controls.QuoteLabel:GetText()
    end)

    local buttonRow = {}
    if not Controls.ChangeGovernmentButton:IsHidden() then
        table.insert(buttonRow, mgr:CreateUIWidget(
            mgr:GenerateWidgetId("CAITechCivicPopupGovt"), "Button", {
                GetLabel = function() return Controls.ChangeGovernmentButton:GetText() end,
                OnClick = function()
                    local btnText = Controls.ChangeGovernmentButton:GetText() or ""
                    PopExisting()
                    if btnText == Locale.Lookup("LOC_GOVT_GOVERNMENT_UNLOCKED") then
                        OnChangeGovernment()
                    else
                        OnChangePolicy()
                    end
                end,
            }))
    end
    table.insert(buttonRow, mgr:CreateUIWidget(
        mgr:GenerateWidgetId("CAITechCivicPopupClose"), "Button", {
            GetLabel = function() return Locale.Lookup("LOC_CLOSE") end,
            OnClick = function() TryClose() end,
        }))

    local function GetTitle() return Controls.HeaderLabel:GetText() end
    m_dialog = mgr.WidgetTemplateHelpers:MakeGeneralDialog(GetTitle, buttonRow, content)
    if not m_dialog then return end
    m_dialog.SpeechSettings = { Role = false, Label = false }
    mgr:Push(m_dialog, PopupPriority.Tutorial)
end


ShowTechCompletedPopup = WrapFunc(ShowTechCompletedPopup, function(orig, ...)
    orig(...)
    if not mgr then return end
    PopExisting()
    BuildDialog()
end)

ShowCivicCompletedPopup = WrapFunc(ShowCivicCompletedPopup, function(orig, ...)
    orig(...)
    if not mgr then return end
    PopExisting()
    BuildDialog()
end)

TryClose = WrapFunc(TryClose, function(orig)
    PopExisting()
    orig()
end)

Close = WrapFunc(Close, function(orig)
    PopExisting()
    orig()
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
    if mgr and mgr:GetTop() ~= m_dialog then return false end
    if ContextPtr:IsHidden() then return false end
    local handled = mgr:HandleInput(pInputStruct)
    if handled then return handled end
    return orig(pInputStruct)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)
