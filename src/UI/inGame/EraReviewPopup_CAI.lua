include("caiUtils")
include("EraReviewPopup")
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

    local effectsRow = mgr:CreateWidget(mgr:GenerateWidgetId("CAIEraReviewEffects"), "StaticText", {
        Label = function() return Controls.EraEffects:GetText() or "" end,
    })

    local contentRows = { effectsRow }

    -- AddPlayerEraIcon sets the leader/civ tooltip on the CivIconBacking root
    -- and the age name on EraLabel:SetToolTipString. Unmet players get no
    -- EraLabel tooltip, so skip those.
    for _, backing in ipairs(Controls.CivIconStack:GetChildren() or {}) do
        local children = backing:GetChildren() or {}
        -- EraLabel is the last child of CivIconBacking (after CivIcon, TeamRibbon)
        local eraLabelCtrl = children[#children]
        local ageTip = eraLabelCtrl and eraLabelCtrl:GetToolTipString() or ""
        if ageTip ~= "" then
            local civRow = mgr:CreateWidget(mgr:GenerateWidgetId("CAIEraReviewCiv"), "StaticText", {
                Label = function()
                    local name = backing:GetToolTipString() or ""
                    local age = eraLabelCtrl:GetToolTipString() or ""
                    if name ~= "" and age ~= "" then
                        return name .. ", " .. age
                    end
                    return name .. age
                end,
            })
            table.insert(contentRows, civRow)
        end
    end

    local continueBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIEraReviewContinue"), "Button", {
        Label = function() return Controls.Continue:GetText() or Locale.Lookup("LOC_CONTINUE") end,
    })
    continueBtn:On("activate", function() Controls.Continue:DoLeftClick() end)

    local closeBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIEraReviewClose"), "Button", {
        Label = function() return Locale.Lookup("LOC_CAI_ERA_REVIEW_CLOSE") end,
    })
    closeBtn:On("activate", function() Controls.Close:DoLeftClick() end)

    m_dialog = mgr.WidgetHelpers.MakeGeneralDialog(
        function() return Controls.Title:GetText() or "" end,
        { continueBtn, closeBtn },
        contentRows,
        1
    )
    if not m_dialog then return end

    mgr:Push(m_dialog, { priority = PopupPriority.MediumHigh })
end

LuaEvents.EraReviewPopup_Show.Remove(OnShowEraReviewPopup);
OnShowEraReviewPopup = WrapFunc(OnShowEraReviewPopup, function(orig)
    orig()
    BuildDialog()
end)
LuaEvents.EraReviewPopup_Show.Add(OnShowEraReviewPopup);

OnClose = WrapFunc(OnClose, function(orig)
    RemoveDialog()
    orig()
end)

OnContinue = WrapFunc(OnContinue, function(orig)
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
-- Reregister the existing button callbacks to trigger our wrapped functions
Controls.Close:RegisterCallback(Mouse.eLClick, OnClose);
Controls.Continue:RegisterCallback(Mouse.eLClick, OnContinue);
