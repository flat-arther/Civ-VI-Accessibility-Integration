-- DeclareWarPopup_CAI.lua
-- Accessibility replacement for the declare-war confirmation popup.
--
-- DeclareWarPopup is a full ReplaceUIScript (no wildcard include), so we must
-- re-include the exact vanilla script the game would otherwise load: with an
-- expansion installed the active context is DeclareWarPopup_Expansion1/2, which
-- override DeclareWar (golden-age / retribution / ideological war session
-- strings) and OnShow (the grievances-instead-of-warmonger consequence). A bare
-- include("DeclareWarPopup") would bind the base globals and silently drop all
-- of that. Mirrors DiplomacyActionView_CAI / GovernmentScreen_CAI.

include("caiUtils")
include("Civ6Common") -- IsExpansion1Active / IsExpansion2Active

if IsExpansion2Active() then
    include("DeclareWarPopup_Expansion2")
elseif IsExpansion1Active() then
    include("DeclareWarPopup_Expansion1")
else
    include("DeclareWarPopup")
end

local mgr = ExposedMembers.CAI_UIManager
local m_caiDialog = nil ---@type UIWidget|nil
local m_opening = false

-- The XML defines five consequence containers (Warmonger / DefensivePact /
-- CityState / TradeRoute / Deals) but vanilla and both expansions only ever
-- populate Warmonger. The others stay hidden. We still read them through a live
-- IsHidden + non-empty guard so a future mod/DLC that fills them surfaces too.
local CONSEQUENCE_STACKS = {
    "WarmongerStack",
    "DefensivePactStack",
    "CityStateStack",
    "TradeRoutesStack",
    "DealsStack",
}

local function IsVisible(control)
    return control ~= nil and (not control.IsHidden or not control:IsHidden())
end

local function GetControlText(control)
    if not IsVisible(control) then return nil end
    return control.GetText and control:GetText() or nil
end

-- A stack item is a Container whose first text-bearing child holds the line.
local function GetItemText(item)
    if not item or not item.GetChildren then return GetControlText(item) end
    for _, child in ipairs(item:GetChildren()) do
        local text = GetControlText(child)
        if text and text ~= "" then return text end
    end
    return nil
end

local function IsDialogActive()
    return mgr ~= nil and m_caiDialog ~= nil and mgr:GetTop() == m_caiDialog
end

local function RemoveDialog()
    if not mgr or not m_caiDialog then return end
    mgr:RemoveFromStack(m_caiDialog:GetId())
    m_caiDialog = nil
end

local function MakeTextRow(getTextFn)
    return mgr:CreateWidget(mgr:GenerateWidgetId("CAIDeclareWarText"), "StaticText", {
        Label = getTextFn,
    })
end

-- Generic dialog title. The vanilla header label has no control ID, so look up
-- its loc tag directly.
local function GetTitle()
    return Locale.Lookup("LOC_DECLARE_WAR_HEADER")
end

-- First body line: the vanilla advisor message ("...start a war with:") with the
-- target civ names folded onto the same line, read live each time.
local function GetTargetLine()
    local message = GetControlText(Controls.Message) or ""

    local names = {}
    for _, native in ipairs(Controls.Targets:GetChildren() or {}) do
        if IsVisible(native) then
            local name = GetItemText(native)
            if name and name ~= "" then
                table.insert(names, name)
            end
        end
    end

    if #names == 0 then return message end
    local joined = table.concat(names, ", ")
    if message == "" then return joined end
    return message .. " " .. joined
end

-- Content rows: the combined "this move will start a war with: <targets>" line
-- first, then the consequence line(s) (warmonger penalty, or the XP2 grievances
-- line). Flat StaticText widgets, no List wrapper, each reading its live vanilla
-- control so base vs XP2 text passes through unchanged. Only WarmongerStack is
-- ever populated in practice; the other stacks are read behind a live guard for
-- forward-compat.
local function BuildContentRows()
    local rows = { MakeTextRow(GetTargetLine) }

    for _, stackId in ipairs(CONSEQUENCE_STACKS) do
        local stack = Controls[stackId]
        if IsVisible(stack) then
            for _, native in ipairs(stack:GetChildren() or {}) do
                if IsVisible(native) then
                    table.insert(rows, MakeTextRow(function() return GetItemText(native) or "" end))
                end
            end
        end
    end

    return rows
end

local function MakeButton(native)
    local btn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIDeclareWarButton"), "Button", {
        Label = function() return native:GetText() or "" end,
        Tooltip = function() return native:GetToolTipString() or "" end,
        DisabledPredicate = function() return native:IsDisabled() end,
        HiddenPredicate = function() return native:IsHidden() end,
    })
    -- Both Yes and No register a Mouse.eLClick callback (Yes in OnShow runs
    -- confirmCallbackFn + OnClose; No is wired to OnClose in Initialize), so we
    -- just drive the live control.
    btn:On("activate", function() native:DoLeftClick() end)
    btn:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
    return btn
end

local function BuildDialog()
    if not mgr or ContextPtr:IsHidden() then return end

    RemoveDialog()

    -- Yes first so default index 1 is the Declare War button (Enter confirms).
    local buttonRow = { MakeButton(Controls.Yes), MakeButton(Controls.No) }

    m_caiDialog = mgr.WidgetHelpers.MakeGeneralDialog(GetTitle, buttonRow, BuildContentRows(), 1)
    if not m_caiDialog then return end

    mgr:Push(m_caiDialog, { priority = PopupPriority.Current })
end

ContextPtr:SetShowHandler(function()
    if not m_opening then
        BuildDialog()
    end
end)

ContextPtr:SetHideHandler(function()
    RemoveDialog()
end)

OnShow = WrapFunc(OnShow, function(orig, ...)
    m_opening = true
    orig(...)
    m_opening = false
    BuildDialog()
end)

OnClose = WrapFunc(OnClose, function(orig, ...)
    RemoveDialog()
    orig(...)
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
    if IsDialogActive() and not ContextPtr:IsHidden() then
        local handled = mgr:HandleInput(pInputStruct)
        if handled then return handled end
    end
    return orig(pInputStruct)
end)

ContextPtr:SetInputHandler(OnInputHandler, true)
