include("caiUtils")
include("DedicationPopup")
local mgr = ExposedMembers.CAI_UIManager

local m_dialog = nil ---@type UIWidget|nil
local m_caiEntries = {} ---@type table[] -- { cb: CheckboxWidget, selectCheck: control }

local function RemoveDialog()
    if not mgr or not m_dialog then return end
    mgr:RemoveFromStack(m_dialog:GetId())
    m_dialog = nil
    m_caiEntries = {}
end

local function SyncCheckboxStates()
    for _, entry in ipairs(m_caiEntries) do
        entry.cb:SetChecked(entry.selectCheck:IsSelected(), true)
    end
end

local function BuildDialog()
    RemoveDialog()
    if not mgr then return end

    local children = Controls.CommemorationsStack:GetChildren()
    if not children or #children == 0 then return end

    local ageRow = mgr:CreateWidget(mgr:GenerateWidgetId("CAIDedicationAge"), "StaticText", {
        Label = function() return Controls.AgeAchieved:GetText() or "" end,
    })

    local contentRows = { ageRow }
    m_caiEntries = {}

    for _, selectCheck in ipairs(children) do
        local selectCheckChildren = selectCheck:GetChildren()
        -- SelectCheck children: [1] Image (icon frame), [2] Stack (category + bonuses)
        local detailStack = selectCheckChildren and selectCheckChildren[2]
        local labels = detailStack and detailStack:GetChildren()
        local categoryCtrl = labels and labels[1]
        local bonusCtrl = labels and labels[2]

        local cb = mgr:CreateWidget(mgr:GenerateWidgetId("CAIDedicationChoice"), "Checkbox", {
            Label = function()
                local cat = categoryCtrl and categoryCtrl:GetText() or ""
                local bonus = bonusCtrl and bonusCtrl:GetText() or ""
                if cat ~= "" and bonus ~= "" then
                    return cat .. ": " .. bonus
                end
                return cat .. bonus
            end,
            ValueGetter = function()
                return selectCheck:IsSelected()
                    and Locale.Lookup("LOC_OPTIONS_ENABLED")
                    or Locale.Lookup("LOC_OPTIONS_DISABLED")
            end,
        })
        cb:On("value_changed", function()
            selectCheck:DoLeftClick()
            SyncCheckboxStates()
            mgr:Refocus()
        end)
        table.insert(m_caiEntries, { cb = cb, selectCheck = selectCheck })
        table.insert(contentRows, cb)
    end

    local confirmBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIDedicationConfirm"), "Button", {
        Label = function() return Controls.Confirm:GetText() or Locale.Lookup("LOC_CONFIRM") end,
        DisabledPredicate = function() return Controls.Confirm:IsDisabled() end,
    })
    confirmBtn:On("activate", function() Controls.Confirm:DoLeftClick() end)

    local closeBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIDedicationClose"), "Button", {
        Label = function() return Locale.Lookup("LOC_CAI_DEDICATION_CLOSE") end,
    })
    closeBtn:On("activate", function() Controls.CloseButton:DoLeftClick() end)

    m_dialog = mgr.WidgetHelpers.MakeGeneralDialog(
        function() return Controls.Title:GetText() or "" end,
        { confirmBtn, closeBtn },
        contentRows,
        1
    )
    if not m_dialog then return end

    mgr:Push(m_dialog, { priority = PopupPriority.MediumHigh })
end

LuaEvents.EraReviewPopup_MakeDedication.Remove(OnGameEraChanged);
OnGameEraChanged = WrapFunc(OnGameEraChanged, function(orig, ...)
    orig(...)
    Speak("Pushing dialog")
    BuildDialog()
end)
LuaEvents.EraReviewPopup_MakeDedication.Add(OnGameEraChanged);

OnClose = WrapFunc(OnClose, function(orig)
    RemoveDialog()
    orig()
end)

OnConfirm = WrapFunc(OnConfirm, function(orig)
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
Controls.CloseButton:RegisterCallback(Mouse.eLClick, OnClose);
Controls.Confirm:RegisterCallback(Mouse.eLClick, OnConfirm);
