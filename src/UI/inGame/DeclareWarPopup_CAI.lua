include("caiUtils")
include("DeclareWarPopup")

local mgr = ExposedMembers.CAI_UIManager
local m_caiDialog = nil ---@type UIWidget|nil
local m_confirmAction = nil ---@type function|nil
local m_opening = false

local SECTION_CONTROLS = {
    { container = "WarmongerContainer", stack = "WarmongerStack" },
    { container = "DefensivePactContainer", stack = "DefensivePactStack" },
    { container = "CityStateContainer", stack = "CityStateStack" },
    { container = "TradeRouteContainer", stack = "TradeRoutesStack" },
    { container = "DealsContainer", stack = "DealsStack" },
}

local function IsVisible(control)
    return control ~= nil and (not control.IsHidden or not control:IsHidden())
end

local function IsDialogActive()
    return mgr and m_caiDialog and mgr:HasWidget(m_caiDialog) and mgr:GetTop() == m_caiDialog
end

local function RemoveDialog()
    if not mgr or not m_caiDialog then return end
    if mgr:HasWidget(m_caiDialog) then
        mgr:RemoveFromStack(m_caiDialog:GetId())
    end
    m_caiDialog = nil
end

local function GetDirectControlText(control)
    if not IsVisible(control) then return nil end
    return control.GetText and control:GetText() or nil
end

local function AddStaticListItem(parentList, text)
    if not parentList or not text or text == "" then return end
    parentList:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIDeclareWarStaticText"), "StaticText", {
        GetValue = function()
            return text
        end,
    }))
end

local function GetImmediateChildText(control)
    if not control or not control.GetChildren then return nil end
    for _, child in ipairs(control:GetChildren()) do
        local text = GetDirectControlText(child)
        if text and text ~= "" then
            return text
        end
    end
    return nil
end

local function AddTargetsToList(summaryList)
    local children = Controls.Targets:GetChildren() or {}
    for _, child in ipairs(children) do
        AddStaticListItem(summaryList, GetImmediateChildText(child))
    end
end

local function AddSectionToList(summaryList, section)
    local container = Controls[section.container]
    if not IsVisible(container) then return end

    local containerChildren = container.GetChildren and container:GetChildren() or {}
    if #containerChildren > 0 then
        local headingContainer = containerChildren[1]
        local headingChildren = headingContainer.GetChildren and headingContainer:GetChildren() or {}
        if #headingChildren > 0 then
            AddStaticListItem(summaryList, GetDirectControlText(headingChildren[1]))
        end
    end

    local stack = Controls[section.stack]
    local children = stack.GetChildren and stack:GetChildren() or {}
    for _, child in ipairs(children) do
        AddStaticListItem(summaryList, GetImmediateChildText(child))
    end
end

local function BuildSummaryList()
    local summaryList = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIDeclareWarSummaryList"), "List")
    AddTargetsToList(summaryList)
    for _, section in ipairs(SECTION_CONTROLS) do
        AddSectionToList(summaryList, section)
    end
    if not summaryList.Children or #summaryList.Children == 0 then
        AddStaticListItem(summaryList, GetDirectControlText(Controls.Message))
    end
    return summaryList
end

local function GetDialogContentWidgets()
    return { BuildSummaryList() }
end

local function BuildDialog()
    if not mgr or ContextPtr:IsHidden() then return end

    RemoveDialog()

    local buttons = {}
    local vanillaButtons = {
        {
            control = Controls.No,
            action = function()
                OnClose()
            end,
        },
        {
            control = Controls.Yes,
            action = function()
                if m_confirmAction then
                    m_confirmAction()
                end
                OnClose()
            end,
        },
    }

    for _, entry in ipairs(vanillaButtons) do
        if IsVisible(entry.control) then
            local control = entry.control
            local action = entry.action
            table.insert(buttons, mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIDeclareWarButton"), "Button", {
                GetLabel = function()
                    return GetDirectControlText(control) or ""
                end,
                GetTooltip = function()
                    return control:GetToolTipString() or ""
                end,
                IsDisabled = function()
                    return control.IsDisabled and control:IsDisabled() or false
                end,
                OnClick = function()
                    action()
                end,
                OnFocusEnter = function()
                    UI.PlaySound("Main_Menu_Mouse_Over")
                end,
            }))
        end
    end

    if #buttons == 0 then return end

    local function GetTitle()
        return GetDirectControlText(Controls.Message) or ""
    end

    m_caiDialog = mgr.WidgetTemplateHelpers:MakeGeneralDialog(GetTitle, buttons, GetDialogContentWidgets())
    if not m_caiDialog then return end

    m_caiDialog.SpeechSettings = { Role = false }
    mgr:Push(m_caiDialog, PopupPriority.Current)
end

local function BuildConfirmAction(eAttackingPlayer, kDefendingPlayers, eWarType, confirmCallbackFn)
    if confirmCallbackFn then
        return confirmCallbackFn
    end

    return function()
        for _, eDefendingPlayer in ipairs(kDefendingPlayers) do
            DeclareWar(eAttackingPlayer, eDefendingPlayer, eWarType)
        end
    end
end

ContextPtr:SetShowHandler(function()
    if not m_opening then
        BuildDialog()
    end
end)

ContextPtr:SetHideHandler(function()
    RemoveDialog()
end)

OnShow = WrapFunc(OnShow, function(orig, eAttackingPlayer, kDefendingPlayers, eWarType, confirmCallbackFn)
    m_opening = true
    m_confirmAction = BuildConfirmAction(eAttackingPlayer, kDefendingPlayers, eWarType, confirmCallbackFn)
    orig(eAttackingPlayer, kDefendingPlayers, eWarType, confirmCallbackFn)
    m_opening = false
    BuildDialog()
end)

OnClose = WrapFunc(OnClose, function(orig, ...)
    RemoveDialog()
    m_confirmAction = nil
    orig(...)
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
    if IsDialogActive() then
        local handled = mgr:HandleInput(pInputStruct)
        if handled then
            return handled
        end
    end
    return orig(pInputStruct)
end)

ContextPtr:SetInputHandler(OnInputHandler, true)
