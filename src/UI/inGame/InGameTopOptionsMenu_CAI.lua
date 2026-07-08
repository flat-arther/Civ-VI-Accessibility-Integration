include("caiUtils")
include("Civ6Common")

local function GetInGameTopOptionsMenuIncludeName()
    if IsExpansion2Active ~= nil and IsExpansion2Active() then
        return "Expansion1_InGameTopOptionsMenu"
    end
    if IsExpansion1Active ~= nil and IsExpansion1Active() then
        return "Expansion1_InGameTopOptionsMenu"
    end
    return "InGameTopOptionsMenu"
end

include(GetInGameTopOptionsMenuIncludeName())

local mgr             = ExposedMembers.CAI_UIManager
local isOpening       = false

local PANEL_ID        = "CAIInGameTopOptionsMenu_Panel"
local BUTTON_LIST_ID  = "CAIInGameTopOptionsMenu_Buttons"
local MODS_EDIT_ID    = "CAIInGameTopOptionsMenu_ModsEdit"
local DETAILS_EDIT_ID = "CAIInGameTopOptionsMenu_DetailsEdit"

local m_Panel ---@type UIWidget|nil
local m_ButtonList ---@type UIWidget|nil
local m_ModsEdit ---@type EditBoxWidget|nil
local m_DetailsEdit ---@type EditBoxWidget|nil

-- VersionLabel's tooltip begins with the same header we use as the edit-box
-- label; strip that first line so it isn't read twice.
local function StripVersionHeader(text)
    if not text or text == "" then return "" end
    local header = Locale.Lookup("LOC_PAUSEMENU_INFO_OVERVIEW_TOOLTIP")
    local first, rest = text:match("^(.-)%[NEWLINE%](.*)$")
    if first and first == header then
        return rest
    end
    return text
end

local function BuildDetailsText()
    local parts = {
        Controls.CivIcon:GetToolTipString() or "",
        Controls.LeaderIcon:GetToolTipString() or "",
        Controls.GameDifficulty:GetToolTipString() or "",
        Controls.GameSpeed:GetToolTipString() or "",
        StripVersionHeader(Controls.VersionLabel:GetToolTipString() or ""),
    }
    -- EditBox SetText normalizes [NEWLINE] to \n; no manual replacement needed.
    return table.concat(parts, "[NEWLINE]")
end

local function BuildModsText()
    local modChildren = Controls.ModListingsStack:GetChildren() or {}
    local lines = {}
    for _, child in ipairs(modChildren) do
        local text = (child.GetText and child:GetText()) or ""
        -- Vanilla appends the single-space ModTitle spacer even when the
        -- enabled-modes section is empty; only emit a blank line when it
        -- actually sits between two real entries.
        if text == " " then
            if #lines > 0 then table.insert(lines, "") end
        elseif text ~= "" then
            table.insert(lines, text)
        end
    end
    -- A trailing spacer (no mod names after it) would leave a blank last line.
    while #lines > 0 and lines[#lines] == "" do
        table.remove(lines)
    end
    return table.concat(lines, "\n")
end

local function BuildButtonList()
    m_ButtonList = mgr:CreateWidget(BUTTON_LIST_ID, "List", {
        Label = function() return Controls.WindowTitle:GetText() end,
        HiddenPredicate = function() return Controls.MainStack:IsHidden() end,
    })
    m_Panel:AddChild(m_ButtonList)

    local stackChildren = Controls.MainStack:GetChildren() or {}
    for _, child in ipairs(stackChildren) do
        if child ~= Controls.ModsInUse then
            local id = (child.GetID and child:GetID()) or ""
            if id ~= "" then
                local nativeButton = child
                local btn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIInGameTopOptionsMenu_Button"), "Button", {
                    Label             = function() return nativeButton:GetText() end,
                    Tooltip           = function() return nativeButton:GetToolTipString() end,
                    DisabledPredicate = function() return nativeButton:IsDisabled() end,
                    HiddenPredicate   = function() return nativeButton:IsHidden() end,
                    FocusKey          = "btn:" .. id,
                })
                btn:SetFocusSound("Main_Menu_Mouse_Over")
                btn:On("activate", function() nativeButton:DoLeftClick() end)
                m_ButtonList:AddChild(btn)
            end
        end
    end
end

local function BuildModsSection()
    m_ModsEdit = mgr:CreateWidget(MODS_EDIT_ID, "EditBox", {
        Label           = function() return Controls.ModsInUseHeader:GetText() end,
        HiddenPredicate = function() return Controls.ModsInUse:IsHidden() end,
        ReadOnly        = true,
        AlwaysEdit      = true,
        HighlightOnEdit = false,
    })
    m_ModsEdit:SetText(BuildModsText(), true)
    m_Panel:AddChild(m_ModsEdit)
end

local function BuildDetailsSection()
    m_DetailsEdit = mgr:CreateWidget(DETAILS_EDIT_ID, "EditBox", {
        Label           = function() return Locale.Lookup("LOC_PAUSEMENU_INFO_OVERVIEW_TOOLTIP") end,
        HiddenPredicate = function() return Controls.DetailsBox:IsHidden() end,
        ReadOnly        = true,
        AlwaysEdit      = true,
        HighlightOnEdit = false,
    })
    m_DetailsEdit:SetText(BuildDetailsText(), true)
    m_Panel:AddChild(m_DetailsEdit)
end

local function BuildPanelContent()
    if not m_Panel then return end

    local capture = mgr:CaptureFocusKey(m_Panel)
    m_Panel:ClearChildren()
    m_ButtonList = nil
    m_ModsEdit = nil
    m_DetailsEdit = nil

    BuildButtonList()
    BuildModsSection()
    BuildDetailsSection()

    mgr:RestoreFocus(m_Panel, capture)
end

local function BuildPanel()
    m_Panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function() return Controls.WindowTitle:GetText() end,
    })
    BuildPanelContent()
end

local function PopPausePanel()
    if not mgr then return end
    mgr:RemoveFromStack(PANEL_ID)
    m_Panel = nil
    m_ButtonList = nil
    m_ModsEdit = nil
    m_DetailsEdit = nil
end

local function PushPausePanel()
    if not mgr or not Controls.PauseWindow or Controls.PauseWindow:IsHidden() then return end

    BuildPanel()
    if m_Panel then
        mgr:Push(m_Panel, PopupPriority.InGameTopOptionsMenu)
    end
end

OnInput = WrapFunc(OnInput, function(orig, input)
    if Controls.PauseWindow and Controls.PauseWindow:IsHidden() then
        return false
    end
    local handled = mgr and mgr:HandleInput(input)
    if handled then
        return handled
    end
    return orig(input)
end)

SetupButtons = WrapFunc(SetupButtons, function(orig)
    orig()
    if Controls.PauseWindow and not Controls.PauseWindow:IsHidden() then
        if m_Panel then
            BuildPanelContent()
        end
    end
    if isOpening then
        if not mgr:GetWidgetById(PANEL_ID) then
            PushPausePanel()
        end
        isOpening = false
    end
end)

LuaEvents.InGameTopOptionsMenu_Show.Add(function()
    isOpening = true
end)

ContextPtr:SetHideHandler(PopPausePanel)
ContextPtr:SetInputHandler(OnInput, true)
