include("caiUtils")
include("GovernorAssignmentChooser")

local mgr = ExposedMembers.CAI_UIManager

local PANEL_ID = "CAIGovernorAssignmentChooser_Panel"
local LIST_ID = "CAIGovernorAssignmentChooser_List"

local m_panel = nil ---@type UIWidget|nil
local m_list = nil ---@type UIWidget|nil
local m_dialog = nil ---@type UIWidget|nil
local m_liveRows = {} ---@type table[]

-- ===========================================================================

local function AppendIfNonEmpty(parts, value)
    if value and value ~= "" then
        parts[#parts + 1] = value
    end
end

local function ControlText(control)
    return tostring(control:GetText() or "")
end

local function ControlTooltip(control)
    return tostring(control:GetToolTipString() or "")
end

local function ControlIsHidden(control)
    return control:IsHidden()
end

local function ControlIsDisabled(control)
    return control:IsDisabled()
end

local function GetChildren(control)
    return control:GetChildren() or {}
end

local function GetRowParts(top)
    local button = GetChildren(top)[1]
    local buttonChildren = GetChildren(button)
    local banner = buttonChildren[2]
    local resourceInfo = buttonChildren[3]

    local bannerChildren = GetChildren(banner)
    local nameStack = bannerChildren[4]
    local governorSlot = bannerChildren[5]
    local turnsStack = bannerChildren[6]

    local nameChildren = GetChildren(nameStack)
    local governorChildren = GetChildren(governorSlot)
    local turnsChildren = GetChildren(turnsStack)

    local identityStack = GetChildren(resourceInfo)[1]
    local identityContainers = GetChildren(identityStack)

    local beforeContainer = identityContainers[1]
    local afterContainer = identityContainers[3]
    local beforeLabel = GetChildren(GetChildren(beforeContainer)[1])[2]
    local afterLabel = GetChildren(GetChildren(afterContainer)[1])[2]

    return {
        Top = top,
        Button = button,
        CapitalIcon = nameChildren[1],
        CityName = nameChildren[2],
        GovernorIcon = governorChildren[1],
        EstablishTurns = turnsChildren[2],
        IdentityPressureBefore = beforeLabel,
        IdentityPressureAfter = afterLabel,
    }
end

local function TooltipWithValue(control, valueControl, fallbackLabel)
    local label = ControlTooltip(control)
    if label == "" and fallbackLabel then
        label = Locale.Lookup(fallbackLabel)
    end
    local value = ControlText(valueControl)
    if label ~= "" and value ~= "" then
        return label .. ": " .. value
    end
    if value ~= "" then return value end
    return label
end

local function BuildRowLabel(row)
    local parts = { ControlText(row.CityName) }
    if not ControlIsHidden(row.CapitalIcon) then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_CITY_STATUS_CAPITAL"))
    end
    return table.concat(parts, ", ")
end

local function BuildRowTooltip(row)
    local parts = {}
    AppendIfNonEmpty(parts, ControlTooltip(row.GovernorIcon))
    AppendIfNonEmpty(parts,
        TooltipWithValue(row.IdentityPressureBefore, row.IdentityPressureBefore,
            "LOC_GOVERNOR_ASSIGNMENT_CURRENT_IDENTITY_PRESSURE_TOOLTIP"))
    AppendIfNonEmpty(parts,
        TooltipWithValue(row.IdentityPressureAfter, row.IdentityPressureAfter,
            "LOC_GOVERNOR_ASSIGNMENT_FUTURE_IDENTITY_PRESSURE_TOOLTIP"))
    AppendIfNonEmpty(parts, TooltipWithValue(row.EstablishTurns, row.EstablishTurns, "LOC_GOVERNOR_TURNS_TO_ESTABLISH"))
    AppendIfNonEmpty(parts, ControlTooltip(row.Button))
    return table.concat(parts, "[NEWLINE]")
end

local function BuildGovernorPreviewText(governorInst)
    if not governorInst then return "" end

    local parts = {}
    AppendIfNonEmpty(parts, ControlText(governorInst.GovernorName))
    if not ControlIsHidden(governorInst.IdentityPressureContainer) then
        AppendIfNonEmpty(parts,
            TooltipWithValue(governorInst.GovernorIdentityPressure, governorInst.GovernorIdentityPressure,
                "LOC_GOVERNOR_IDENTITY_PRESSURE_TOOLTIP"))
    end
    if not ControlIsHidden(governorInst.TurnsToEstablishIcon) then
        AppendIfNonEmpty(parts,
            TooltipWithValue(governorInst.TurnsToEstablish, governorInst.TurnsToEstablish,
                "LOC_GOVERNOR_TURNS_TO_ESTABLISH"))
    end

    if governorInst.GovernorPromotionStack and governorInst.GovernorPromotionStack.GetChildren then
        local promoTips = {}
        local children = governorInst.GovernorPromotionStack:GetChildren()
        if children then
            for _, child in ipairs(children) do
                if child and child.PromotionIcon then
                    AppendIfNonEmpty(promoTips, ControlTooltip(child.PromotionIcon))
                end
            end
        end
        if #promoTips > 0 then
            AppendIfNonEmpty(parts, table.concat(promoTips, ", "))
        end
    end

    return table.concat(parts, "[NEWLINE]")
end

local function BuildLiveRows()
    local rows = {}
    for _, top in ipairs(GetChildren(Controls.AssignmentChoiceStack)) do
        rows[#rows + 1] = GetRowParts(top)
    end
    return rows
end

local function GetLiveRow(index)
    return m_liveRows[index]
end

local function RestoreRowFocus(rowIndex)
    if not mgr or not m_list then return end
    mgr:RestoreFocus(m_list, {
        key = "governor_assign:" .. tostring(rowIndex),
    })
end

-- ===========================================================================

local function CloseConfirmDialog()
    if m_dialog and mgr then
        mgr:RemoveFromStack(m_dialog:GetId())
        m_dialog = nil
    end
end

local function OpenConfirmDialog(rowIndex)
    CloseConfirmDialog()

    local row = GetLiveRow(rowIndex)
    if ControlIsDisabled(row.Button) then
        return
    end

    row.Button:DoLeftClick()

    local summaryWidgets = {}

    local cityText = ControlText(Controls.CityName)
    if not ControlIsHidden(Controls.CapitalIcon) then
        cityText = table.concat({ cityText, Locale.Lookup("LOC_CAI_CITY_STATUS_CAPITAL") }, ", ")
    end
    summaryWidgets[#summaryWidgets + 1] = mgr:CreateWidget(
        mgr:GenerateWidgetId("CAIGovAssign_City"),
        "StaticText",
        {
            Label = function()
                return Locale.Lookup("LOC_CAI_GOV_ASSIGN_CITY", cityText)
            end,
        }
    )

    local incomingText = BuildGovernorPreviewText(Controls.NewGovernorInst)
    summaryWidgets[#summaryWidgets + 1] = mgr:CreateWidget(
        mgr:GenerateWidgetId("CAIGovAssign_Incoming"),
        "StaticText",
        {
            Label = function()
                return Locale.Lookup("LOC_CAI_GOV_ASSIGN_INCOMING", incomingText)
            end,
        }
    )

    local outgoingText = BuildGovernorPreviewText(Controls.OldGovernorInst)
    if outgoingText ~= "" then
        summaryWidgets[#summaryWidgets + 1] = mgr:CreateWidget(
            mgr:GenerateWidgetId("CAIGovAssign_Outgoing"),
            "StaticText",
            {
                Label = function()
                    return Locale.Lookup("LOC_CAI_GOV_ASSIGN_OUTGOING", outgoingText)
                end,
            }
        )
    end

    local confirmBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIGovAssign_Confirm"), "Button", {
        Label = function()
            local text = ControlText(Controls.ConfirmLabel)
            if text ~= "" then return text end
            return Locale.Lookup("LOC_CONFIRM")
        end,
    })
    confirmBtn:On("activate", function()
        Controls.ConfirmButton:DoLeftClick()
    end)

    local reselectBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIGovAssign_Reselect"), "Button", {
        Label = function() return Locale.Lookup("LOC_CAI_GOV_ASSIGN_RESELECT") end,
    })
    reselectBtn:On("activate", function()
        CloseConfirmDialog()
        RestoreRowFocus(rowIndex)
    end)

    m_dialog = mgr.WidgetHelpers.MakeGeneralDialog(
        function() return Locale.Lookup("LOC_CAI_GOV_ASSIGN_CONFIRM_TITLE") end,
        { confirmBtn, reselectBtn },
        summaryWidgets,
        1
    )
    if not m_dialog then return end

    m_dialog:AddInputBindings({
        {
            Key = Keys.VK_ESCAPE,
            MSG = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_CLOSE",
            Action = function()
                CloseConfirmDialog()
                RestoreRowFocus(rowIndex)
                return true
            end,
        },
    })
    mgr:Push(m_dialog, PopupPriority.Current)
end

-- ===========================================================================

local function RebuildList()
    if not mgr or not m_list then return end

    local capture = mgr:CaptureFocusKey(m_list)
    m_list:ClearChildren()

    for index, _ in ipairs(m_liveRows) do
        local focusKey = "governor_assign:" .. tostring(index)

        local row = mgr:CreateWidget(mgr:GenerateWidgetId("CAIGovAssign_Row"), "MenuItem", {
            Label = function()
                return BuildRowLabel(GetLiveRow(index))
            end,
            Tooltip = function()
                return BuildRowTooltip(GetLiveRow(index))
            end,
            DisabledPredicate = function()
                return ControlIsDisabled(GetLiveRow(index).Button)
            end,
            FocusKey = focusKey,
        })
        row:On("activate", function()
            OpenConfirmDialog(index)
        end)
        m_list:AddChild(row)
    end

    mgr:RestoreFocus(m_list, capture)
end

local function BuildPanel()
    m_panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function() return ControlText(Controls.Header_OriginText) end,
    })

    m_list = mgr:CreateWidget(LIST_ID, "List", {
        Label = function() return ControlText(Controls.Header_OriginText) end,
    })
    m_panel:AddChild(m_list)

    RebuildList()
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
    m_liveRows = {}
end

-- ===========================================================================
-- Wraps
-- ===========================================================================

Refresh = WrapFunc(Refresh, function(orig)
    orig()
    m_liveRows = BuildLiveRows()
    if mgr and m_panel and m_list and not ContextPtr:IsHidden() then
        RebuildList()
    end
end)

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
