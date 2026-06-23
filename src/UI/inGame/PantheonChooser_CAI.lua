include("caiUtils")
include("PantheonChooser")

local mgr = ExposedMembers.CAI_UIManager

local PANEL_ID = "CAIPantheon_Panel"
local LIST_ID  = "CAIPantheon_List"

local m_panel          = nil
local m_list           = nil
local m_dialog         = nil
local m_vanillaButtons = {}

-- ============================================================================

local function NormalizeText(text)
    if not text then return "" end
    text = tostring(text)
    text = string.gsub(text, "%[ENDCOLOR%]", "")
    text = string.gsub(text, "%[COLOR_[^%]]+%]", "")
    text = string.gsub(text, "%[COLOR:%s*[^%]]+%]", "")
    text = string.gsub(text, "%[NEWLINE%]", ", ")
    text = string.gsub(text, "%[ICON_[^%]]+%]", "")
    text = string.gsub(text, "[,%s]+,", ",")
    text = string.gsub(text, "^[,%s]+", "")
    text = string.gsub(text, "[,%s]+$", "")
    return text
end

-- ============================================================================

local function CloseConfirmDialog()
    if m_dialog then
        mgr:RemoveFromStack(m_dialog.Id)
        m_dialog = nil
    end
end

local function OpenConfirmDialog(beliefRow, vanillaButton)
    CloseConfirmDialog()

    vanillaButton:DoLeftClick()

    local name = Locale.Lookup(beliefRow.Name)
    local desc = NormalizeText(Locale.Lookup(beliefRow.Description))

    local confirmBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIPan_Confirm"), "Button", {
        Label = function() return Locale.Lookup("LOC_CAI_PANTHEON_CONFIRM") end,
    })
    confirmBtn:On("activate", function()
        Controls.ConfirmPantheonButton:DoLeftClick()
    end)

    local reselectBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIPan_Reselect"), "Button", {
        Label = function() return Locale.Lookup("LOC_CAI_PANTHEON_RESELECT") end,
    })
    reselectBtn:On("activate", function()
        Controls.CancelButton:DoLeftClick()
        CloseConfirmDialog()
    end)

    local summary = mgr:CreateWidget(mgr:GenerateWidgetId("CAIPan_Summary"), "StaticText", {
        Label = function() return name .. ": " .. desc end,
    })

    m_dialog = mgr.WidgetHelpers.MakeGeneralDialog(
        function() return Locale.Lookup("LOC_CAI_PANTHEON_CONFIRM_TITLE") end,
        { confirmBtn, reselectBtn },
        { summary },
        1
    )
    if m_dialog then
        m_dialog:AddInputBindings({
            {
                Key = Keys.VK_ESCAPE,
                MSG = KeyEvents.KeyUp,
                Description = "LOC_CAI_KB_CLOSE",
                Action = function()
                    Controls.CancelButton:DoLeftClick()
                    CloseConfirmDialog()
                    return true
                end,
            },
        })
        mgr:Push(m_dialog, PopupPriority.Current)
    end
end

-- ============================================================================

local function BuildPanel()
    m_vanillaButtons = {}

    m_panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function() return Locale.Lookup("LOC_CAI_PANTHEON_CHOOSER_LIST") end,
    })

    m_list = mgr:CreateWidget(LIST_ID, "List", {
        Label = function() return Locale.Lookup("LOC_CAI_PANTHEON_CHOOSER_LIST") end,
    })
    m_panel:AddChild(m_list)

    local idx = 0
    for row in GameInfo.Beliefs() do
        if CanSelectBelief(row) then
            idx = idx + 1
            local beliefIdx = idx
            local beliefRow = row
            local w = mgr:CreateWidget(mgr:GenerateWidgetId("CAIPan_Belief"), "MenuItem", {
                Label   = function() return Locale.Lookup(beliefRow.Name) end,
                Tooltip = function() return NormalizeText(Locale.Lookup(beliefRow.Description)) end,
                FocusKey = "pantheon:" .. tostring(beliefRow.Index),
            })
            w:On("activate", function()
                local vBtn = m_vanillaButtons[beliefIdx]
                if vBtn then
                    OpenConfirmDialog(beliefRow, vBtn)
                end
            end)
            m_list:AddChild(w)
        end
    end

    local children = Controls.BeliftStack:GetChildren()
    if children then
        for i, child in ipairs(children) do
            m_vanillaButtons[i] = child
        end
    end
end

local function PushPanel()
    BuildPanel()
    mgr:Push(m_panel, PopupPriority.Current)
end

local function PopPanel()
    CloseConfirmDialog()
    if mgr and m_panel then
        mgr:RemoveFromStack(PANEL_ID)
    end
    m_panel = nil
    m_list = nil
    m_vanillaButtons = {}
end

-- ============================================================================
-- Wraps
-- ============================================================================

Open = WrapFunc(Open, function(orig)
    orig()
    if mgr and not ContextPtr:IsHidden() then
        PushPanel()
    end
end)

Close = WrapFunc(Close, function(orig)
    PopPanel()
    orig()
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, input)
    if mgr and mgr:GetWidgetById(PANEL_ID) then
        if mgr:HandleInput(input) then
            return true
        end
    end
    return orig(input)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)

OnShutdown = WrapFunc(OnShutdown, function(orig)
    PopPanel()
    orig()
end)
ContextPtr:SetShutdown(OnShutdown)
