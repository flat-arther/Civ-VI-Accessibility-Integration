include("caiUtils")
include("Civ6Common")
if IsExpansion2Active() then
    include("RazeCity_Expansion2")
else
    include("RazeCity")
end
local mgr = ExposedMembers.CAI_UIManager

local m_dialog = nil ---@type UIWidget|nil
local m_keepIndex = 1

local function RemoveDialog()
    if not mgr or not m_dialog then return end
    mgr:RemoveFromStack(m_dialog:GetId())
    m_dialog = nil
end

local function BuildDialog()
    RemoveDialog()
    if not mgr or ContextPtr:IsHidden() then return end

    local cityRow = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRazeCityName"), "StaticText", {
        Label = function()
            return (Controls.CityHeader:GetText() or "") .. " " .. (Controls.CityName:GetText() or "")
        end,
    })
    local popRow = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRazeCityPop"), "StaticText", {
        Label = function()
            return (Controls.CityPopulation:GetText() or "") .. " " .. (Controls.NumPeople:GetText() or "")
        end,
    })
    local distRow = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRazeCityDist"), "StaticText", {
        Label = function()
            return (Controls.CityDistricts:GetText() or "") .. " " .. (Controls.NumDistricts:GetText() or "")
        end,
    })

    local contentRows = { cityRow, popRow, distRow }
    local buttons = {}

    if not Controls.Button1:IsHidden() then
        local btn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRazeCityLibFounder"), "Button", {
            Label = function() return Controls.Button1:GetText() or "" end,
            Tooltip = function() return Controls.Button1:GetToolTipString() or "" end,
        })
        btn:On("activate", function() Controls.Button1:DoLeftClick() end)
        table.insert(buttons, btn)
    end

    if not Controls.Button2:IsHidden() then
        local btn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRazeCityLibPrev"), "Button", {
            Label = function() return Controls.Button2:GetText() or "" end,
            Tooltip = function() return Controls.Button2:GetToolTipString() or "" end,
        })
        btn:On("activate", function() Controls.Button2:DoLeftClick() end)
        table.insert(buttons, btn)
    end

    local keepBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRazeCityKeep"), "Button", {
        Label = function() return Controls.Button3:GetText() or "" end,
        Tooltip = function() return Controls.Button3:GetToolTipString() or "" end,
    })
    keepBtn:On("activate", function() Controls.Button3:DoLeftClick() end)
    table.insert(buttons, keepBtn)
    m_keepIndex = #buttons

    local razeBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRazeCityRaze"), "Button", {
        Label = function() return Controls.Button4:GetText() or "" end,
        Tooltip = function() return Controls.Button4:GetToolTipString() or "" end,
        IsDisabled = function() return Controls.Button4:IsDisabled() end,
    })
    razeBtn:On("activate", function() Controls.Button4:DoLeftClick() end)
    table.insert(buttons, razeBtn)

    m_dialog = mgr.WidgetHelpers.MakeGeneralDialog(
        function() return Controls.PanelHeader:GetText() or "" end,
        buttons,
        contentRows,
        m_keepIndex
    )
    if not m_dialog then return end

    mgr:Push(m_dialog, { priority = PopupPriority.Medium })
end

OnOpen = WrapFunc(OnOpen, function(orig)
    orig()
    BuildDialog()
end)

Close = WrapFunc(Close, function(orig)
    RemoveDialog()
    orig()
end)

OnButton1 = WrapFunc(OnButton1, function(orig)
    RemoveDialog()
    orig()
end)

OnButton2 = WrapFunc(OnButton2, function(orig)
    RemoveDialog()
    orig()
end)

OnButton3 = WrapFunc(OnButton3, function(orig)
    RemoveDialog()
    orig()
end)

OnButton4 = WrapFunc(OnButton4, function(orig)
    RemoveDialog()
    orig()
end)

local function HandleInput(pInputStruct)
    if mgr and m_dialog and mgr:GetTop() == m_dialog and not ContextPtr:IsHidden() then
        local handled = mgr:HandleInput(pInputStruct)
        if handled then return handled end
    end
    if pInputStruct:GetMessageType() == KeyEvents.KeyUp then
        if pInputStruct:GetKey() == Keys.VK_ESCAPE then
            Close()
            return true
        end
    end
    return false
end


LateInitialize = WrapFunc(LateInitialize, function(orig)
    orig()
    ContextPtr:SetInputHandler(HandleInput, true)
end)
