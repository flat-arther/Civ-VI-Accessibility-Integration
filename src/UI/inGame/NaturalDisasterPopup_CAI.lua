include("caiUtils")
include("NaturalDisasterPopup")

local mgr = ExposedMembers.CAI_UIManager

local NUCLEAR_OPERATOR_TYPE = "NUCLEAR_ACCIDENT"

local m_dialog = nil

local function RemoveDialog()
    if not mgr or not m_dialog then return end
    mgr:RemoveFromStack(m_dialog:GetId())
    m_dialog = nil
end

local function BuildDialog()
    RemoveDialog()
    if not mgr then return end

    local parts = {}

    local name = Controls.DisasterName:GetText()
    if name and name ~= "" then
        table.insert(parts, name)
    end

    if not Controls.DisasterDescriptionContainer:IsHidden() then
        local desc = Controls.DisasterDescription:GetText()
        if desc and desc ~= "" then
            table.insert(parts, desc)
        end
    end

    if not Controls.MitigatedLabel:IsHidden() then
        table.insert(parts, Locale.Lookup("LOC_CLIMATE_MITIGATED"))
    end

    if not Controls.PlotLostFertileContainer:IsHidden() then
        local val = tonumber(Controls.PlotLostFertileLabel:GetText()) or 0
        if val > 0 then
            table.insert(parts, Locale.Lookup("LOC_CAI_CLIMATE_LOST_FERTILE_TILES", val))
        end
    end

    if not Controls.PlotFertileContainer:IsHidden() then
        local val = tonumber(Controls.PlotFertileLabel:GetText()) or 0
        if val > 0 then
            table.insert(parts, Locale.Lookup("LOC_CAI_CLIMATE_FERTILE_TILES", val))
        end
    end

    if not Controls.PlotDamagedContainer:IsHidden() then
        local val = tonumber(Controls.PlotDamagedLabel:GetText()) or 0
        if val > 0 then
            table.insert(parts, Locale.Lookup("LOC_CAI_CLIMATE_DAMAGED_TILES", val))
        end
    end

    if not Controls.UnitsLostContainer:IsHidden() then
        local val = tonumber(Controls.UnitsLostLabel:GetText()) or 0
        if val > 0 then
            table.insert(parts, Locale.Lookup("LOC_CAI_CLIMATE_UNITS_LOST", val))
        end
    end

    if not Controls.PopLostContainer:IsHidden() then
        local val = tonumber(Controls.PopLostLabel:GetText()) or 0
        if val > 0 then
            table.insert(parts, Locale.Lookup("LOC_CAI_CLIMATE_POP_LOST", val))
        end
    end

    local contentLabel = table.concat(parts, ", ")

    local contentRow = mgr:CreateWidget(mgr:GenerateWidgetId("CAIDisaster_Content"), "StaticText", {
        Label = contentLabel,
    })

    local closeBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIDisaster_Close"), "Button", {
        Label = function() return Locale.Lookup("LOC_CLOSE") end,
    })
    closeBtn:On("activate", function() Controls.Close:DoLeftClick() end)

    m_dialog = mgr.WidgetHelpers.MakeGeneralDialog(
        function() return Controls.HeaderTitle:GetText() or "" end,
        { closeBtn },
        { contentRow },
        1
    )
    if not m_dialog then return end

    mgr:Push(m_dialog, { priority = PopupPriority.Medium })
end

ShowPopup = WrapFunc(ShowPopup, function(orig, kData)
    orig(kData)
    BuildDialog()
end)

Close = WrapFunc(Close, function(orig)
    RemoveDialog()
    orig()
end)

OnInputHander = WrapFunc(OnInputHander, function(orig, pInputStruct)
    if mgr and m_dialog and mgr:GetTop() == m_dialog then
        local handled = mgr:HandleInput(pInputStruct)
        if handled then return handled end
    end
    return orig(pInputStruct)
end)
ContextPtr:SetInputHandler(OnInputHander, true)
