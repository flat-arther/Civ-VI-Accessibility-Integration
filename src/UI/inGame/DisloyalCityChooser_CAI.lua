include("caiUtils")
include("DisloyalCityChooser")
local mgr = ExposedMembers.CAI_UIManager

local m_dialog = nil ---@type UIWidget|nil

local function RemoveDialog()
    if not mgr or not m_dialog then return end
    mgr:RemoveFromStack(m_dialog:GetId())
    m_dialog = nil
end

local function BuildDialog()
    RemoveDialog()
    if not mgr or ContextPtr:IsHidden() then return end

    local cityRow = mgr:CreateWidget(mgr:GenerateWidgetId("CAIDisloyalCityName"), "StaticText", {
        Label = function()
            return (Controls.CityHeader:GetText() or "") .. " " .. (Controls.CityName:GetText() or "")
        end,
    })
    local popRow = mgr:CreateWidget(mgr:GenerateWidgetId("CAIDisloyalCityPop"), "StaticText", {
        Label = function()
            return (Controls.CityPopulation:GetText() or "") .. " " .. (Controls.NumPeople:GetText() or "")
        end,
    })
    local distRow = mgr:CreateWidget(mgr:GenerateWidgetId("CAIDisloyalCityDist"), "StaticText", {
        Label = function()
            return (Controls.CityDistricts:GetText() or "") .. " " .. (Controls.NumDistricts:GetText() or "")
        end,
    })

    local keepBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIDisloyalCityKeep"), "Button", {
        Label = function() return Controls.KeepButton:GetText() or "" end,
        Tooltip = function() return Controls.KeepButton:GetToolTipString() or "" end,
    })
    keepBtn:On("activate", function() Controls.KeepButton:DoLeftClick() end)

    local rejectBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIDisloyalCityReject"), "Button", {
        Label = function() return Controls.RejectButton:GetText() or "" end,
        Tooltip = function() return Controls.RejectButton:GetToolTipString() or "" end,
    })
    rejectBtn:On("activate", function() Controls.RejectButton:DoLeftClick() end)

    m_dialog = mgr.WidgetHelpers.MakeGeneralDialog(
        function() return Controls.PanelHeader:GetText() or "" end,
        { keepBtn, rejectBtn },
        { cityRow, popRow, distRow },
        1
    )
    if not m_dialog then return end

    mgr:Push(m_dialog, { priority = PopupPriority.Medium })
end

LuaEvents.NotificationPanel_OpenDisloyalCityChooser.Remove(OnOpen)
OnOpen = WrapFunc(OnOpen, function(orig)
    orig()
    BuildDialog()
end)
LuaEvents.NotificationPanel_OpenDisloyalCityChooser.Add(OnOpen)

OnClose = WrapFunc(OnClose, function(orig)
    RemoveDialog()
    orig()
end)

OnKeepButton = WrapFunc(OnKeepButton, function(orig)
    RemoveDialog()
    orig()
end)

OnRejectButton = WrapFunc(OnRejectButton, function(orig)
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
Controls.KeepButton:RegisterCallback(Mouse.eLClick, OnKeepButton)
Controls.RejectButton:RegisterCallback(Mouse.eLClick, OnRejectButton)
Controls.ModalScreenClose:RegisterCallback(Mouse.eLClick, OnClose)
