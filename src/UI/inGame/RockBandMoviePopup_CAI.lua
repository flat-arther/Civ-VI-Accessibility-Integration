include("caiUtils")
include("RockBandMoviePopup")
local mgr = ExposedMembers.CAI_UIManager

local m_dialog = nil ---@type UIWidget|nil

local function RemoveRockBandMovieDialog()
    if not mgr or not m_dialog then return end
    mgr:RemoveFromStack(m_dialog:GetId())
    m_dialog = nil
end

local function BuildRockBandMovieDialog()
    RemoveRockBandMovieDialog()
    if not mgr then return end

    local contentRows = {}

    local bandInfoRow = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRockBandInfo"), "StaticText", {
        Label = function()
            local name = Controls.RockBandName:GetText() or ""
            local level = Controls.RockBandLevel:GetText() or ""
            if level ~= "" then
                return name .. ", " .. Locale.Lookup("LOC_HUD_UNIT_PANEL_ROCK_BAND_LEVEL") .. ": " .. level
            end
            return name
        end,
    })
    table.insert(contentRows, bandInfoRow)

    local buttons = {}
    local closeBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRockBandClose"), "Button", {
        Label = function() return Locale.Lookup("LOC_CONTINUE") end,
    })
    closeBtn:On("activate", function() Controls.Close:DoLeftClick() end)
    table.insert(buttons, closeBtn)

    m_dialog = mgr.WidgetHelpers.MakeGeneralDialog(
        function() return Controls.RockBandHeader:GetText() or "" end,
        buttons,
        contentRows,
        1
    )

    if not m_dialog then return end
    mgr:Push(m_dialog, { priority = PopupPriority.High })
end

ShowPopup = WrapFunc(ShowPopup, function(orig, kData)
    orig(kData)
    if not mgr then return end
    BuildRockBandMovieDialog()
end)

Close = WrapFunc(Close, function(orig)
    RemoveRockBandMovieDialog()
    orig()
end)

-- Overriding the input handler using Firaxis' exact 'OnInputHander' typo from the source code
OnInputHander = WrapFunc(OnInputHander, function(orig, pInputStruct)
    if mgr and m_dialog and mgr:GetTop() == m_dialog and not ContextPtr:IsHidden() then
        local handled = mgr:HandleInput(pInputStruct)
        if handled then return handled end
    end
    return orig(pInputStruct)
end)
ContextPtr:SetInputHandler(OnInputHander, true)
