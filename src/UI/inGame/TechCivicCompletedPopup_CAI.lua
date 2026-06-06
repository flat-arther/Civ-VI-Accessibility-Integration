include("caiUtils")
include("inGameHelpers_CAI")
include("TechCivicCompletedPopup")
local mgr = ExposedMembers.CAI_UIManager

local m_dialog = nil ---@type UIWidget|nil
local m_currentCivicType = nil ---@type string|nil
local m_currentTechType = nil ---@type string|nil
local m_currentPlayerID = nil ---@type number|nil

local function FormatUnlockLabel(typeName, locName)
    local name = Locale.Lookup(locName)
    local desc = GetUnlockDescription(typeName)
    if desc then return name .. ": " .. desc end
    return name
end

local function RemoveDialog()
    if not mgr or not m_dialog then return end
    mgr:RemoveFromStack(m_dialog:GetId())
    m_dialog = nil
end

local function BuildDialog()
    RemoveDialog()
    if not mgr or ContextPtr:IsHidden() then return end

    local contentRows = {}

    local nameRow = mgr:CreateWidget(mgr:GenerateWidgetId("CAITechCivicName"), "StaticText", {
        Label = function() return Controls.ResearchName:GetText() or "" end,
    })
    table.insert(contentRows, nameRow)

    if not Controls.CivicMsgLabel:IsHidden() then
        local civicMsg = mgr:CreateWidget(mgr:GenerateWidgetId("CAITechCivicMsg"), "StaticText", {
            Label = function() return Controls.CivicMsgLabel:GetText() or "" end,
        })
        table.insert(contentRows, civicMsg)
    end

    local unlockCount = mgr:CreateWidget(mgr:GenerateWidgetId("CAITechCivicUnlockCount"), "StaticText", {
        Label = function() return Controls.UnlockCountLabel:GetText() or "" end,
    })
    table.insert(contentRows, unlockCount)

    local unlockables
    if m_currentCivicType then
        unlockables = GetUnlockablesForCivic_Cached(m_currentCivicType, m_currentPlayerID) or {}
    elseif m_currentTechType then
        unlockables = GetUnlockablesForTech_Cached(m_currentTechType, m_currentPlayerID) or {}
    end
    for _, u in ipairs(unlockables or {}) do
        local typeName, locName = u[1], u[2]
        if locName and locName ~= "" then
            local label = FormatUnlockLabel(typeName, locName)
            local unlockRow = mgr:CreateWidget(mgr:GenerateWidgetId("CAITechCivicUnlock"), "StaticText", {
                Label = label,
            })
            table.insert(contentRows, unlockRow)
        end
    end

    if not Controls.QuoteButton:IsHidden() then
        local quoteRow = mgr:CreateWidget(mgr:GenerateWidgetId("CAITechCivicQuote"), "StaticText", {
            Label = function() return Controls.QuoteLabel:GetText() or "" end,
        })
        table.insert(contentRows, quoteRow)
    end

    local buttons = {}

    if not Controls.ChangeGovernmentButton:IsHidden() then
        local govBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAITechCivicGovt"), "Button", {
            Label = function() return Controls.ChangeGovernmentButton:GetText() or "" end,
        })
        govBtn:On("activate", function() Controls.ChangeGovernmentButton:DoLeftClick() end)
        table.insert(buttons, govBtn)
    end

    local closeBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAITechCivicClose"), "Button", {
        Label = function() return Locale.Lookup("LOC_CLOSE") end,
    })
    closeBtn:On("activate", function() Controls.CloseButton:DoLeftClick() end)
    table.insert(buttons, closeBtn)

    m_dialog = mgr.WidgetHelpers.MakeGeneralDialog(
        function() return Controls.HeaderLabel:GetText() or "" end,
        buttons,
        contentRows,
        1
    )
    if not m_dialog then return end

    mgr:Push(m_dialog, { priority = PopupPriority.Low })
end

ShowTechCompletedPopup = WrapFunc(ShowTechCompletedPopup, function(orig, player, tech, ...)
    m_currentPlayerID = player
    m_currentTechType = GameInfo.Technologies[tech] and GameInfo.Technologies[tech].TechnologyType or nil
    m_currentCivicType = nil
    orig(player, tech, ...)
    if not mgr then return end
    BuildDialog()
end)

ShowCivicCompletedPopup = WrapFunc(ShowCivicCompletedPopup, function(orig, player, civic, ...)
    m_currentPlayerID = player
    m_currentCivicType = GameInfo.Civics[civic] and GameInfo.Civics[civic].CivicType or nil
    m_currentTechType = nil
    orig(player, civic, ...)
    if not mgr then return end
    BuildDialog()
end)

TryClose = WrapFunc(TryClose, function(orig)
    RemoveDialog()
    orig()
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
