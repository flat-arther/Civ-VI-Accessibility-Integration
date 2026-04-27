include("caiUtils")
include("InGameTopOptionsMenu")

local mgr = ExposedMembers.CAI_UIManager
local isOpening = false

local CAI_Panel = nil ---@type UIWidget|nil
local CAI_ButtonList = nil ---@type UIWidget|nil
local CAI_ModsList = nil ---@type UIWidget|nil
local CAI_DetailsList = nil ---@type UIWidget|nil

local kActionEntries = {
    { Control = function() return Controls.ReturnButton end,    Action = function() OnReturn() end },
    { Control = function() return Controls.QuickSaveButton end, Action = function() OnQuickSaveGame() end },
    { Control = function() return Controls.SaveGameButton end,  Action = function() OnSaveGame() end },
    { Control = function() return Controls.LoadGameButton end,  Action = function() OnLoadGame() end },
    { Control = function() return Controls.OptionsButton end,   Action = function() OnOptions() end },
    { Control = function() return Controls.RetireButton end,    Action = function() OnRetireGame() end },
    { Control = function() return Controls.PBCDeleteButton end, Action = function() OnPBCDeleteButton() end },
    { Control = function() return Controls.PBCQuitButton end,   Action = function() OnPBCQuitButton() end },
    { Control = function() return Controls.RestartButton end,   Action = function() OnRestartGame() end },
    { Control = function() return Controls.MainMenuButton end,  Action = function() OnMainMenu() end },
    { Control = function() return Controls.ExitGameButton end,  Action = function() OnExitGameAskAreYouSure() end },
}

local function GetActionForControl(control)
    for _, entry in ipairs(kActionEntries) do
        if control == entry.Control() then
            return entry.Action
        end
    end
    return nil
end

local function TrimText(text)
    if not text then return "" end
    return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function SplitNewlineText(text)
    local lines = {}
    if not text or text == "" then return lines end

    local normalized = text:gsub("\r\n", "\n")
    normalized = normalized:gsub("%[NEWLINE%]", "\n")

    for line in normalized:gmatch("([^\n]+)") do
        local trimmed = TrimText(line)
        if trimmed ~= "" then
            table.insert(lines, trimmed)
        end
    end

    return lines
end

local function AddStaticTextListItem(parentList, label, value, tooltip, isHidden)
    if not parentList then return end
    parentList:AddChild(mgr:CreateUIWidget("StaticText", {
        GetLabel = function()
            return label and label() or ""
        end,
        GetValue = value,
        GetTooltip = tooltip,
        IsHidden = isHidden,
    }))
end

local function AddButtonListItem(parentList, nativeButton, action)
    if not parentList or not nativeButton or not action then return end
    parentList:AddChild(mgr:CreateUIWidget("Button", {
        GetLabel = function()
            return nativeButton:GetText()
        end,
        GetTooltip = function()
            return nativeButton:GetToolTipString()
        end,
        IsDisabled = function()
            return nativeButton:IsDisabled()
        end,
        IsHidden = function()
            return nativeButton:IsHidden()
        end,
        OnFocusEnter = function()
            UI.PlaySound("Main_Menu_Mouse_Over")
        end,
        OnClick = function()
            action()
        end,
    }))
end

local function CreateSectionList(label, isHidden)
    return mgr:CreateUIWidget("List", {
        GetLabel = label,
        IsHidden = isHidden,
    })
end

local function AddModsSection()
    CAI_ModsList = CreateSectionList(
        function() return Controls.ModsInUseHeader:GetText() end,
        function() return Controls.ModsInUse:IsHidden() end
    )
    CAI_Panel:AddChild(CAI_ModsList)

    local modChildren = Controls.ModListingsStack:GetChildren() or {}
    for _, child in ipairs(modChildren) do
        local text = child.GetText and child:GetText() or ""
        -- TODO: see what to do about enabled vs all mods they have them devided by a spacer
        if text ~= "" and text ~= " " then
            local modText = text
            AddStaticTextListItem(
                CAI_ModsList,
                function() return modText end,
                nil,
                nil,
                function() return Controls.ModsInUse:IsHidden() end
            )
        end
    end
end

local function AddDetailsSection()
    CAI_DetailsList = CreateSectionList(
        function() return Locale.Lookup("LOC_PAUSEMENU_INFO_OVERVIEW_TOOLTIP") end,
        function() return Controls.DetailsBox:IsHidden() end
    )
    CAI_Panel:AddChild(CAI_DetailsList)

    AddStaticTextListItem(
        CAI_DetailsList,
        function() return Controls.CivIcon:GetToolTipString() end,
        nil,
        nil,
        function() return Controls.DetailsBox:IsHidden() end
    )
    AddStaticTextListItem(
        CAI_DetailsList,
        function() return Controls.LeaderIcon:GetToolTipString() end,
        nil,
        nil,
        function() return Controls.DetailsBox:IsHidden() end
    )
    AddStaticTextListItem(
        CAI_DetailsList,
        function() return Controls.GameDifficulty:GetToolTipString() end,
        nil,
        nil,
        function() return Controls.DetailsBox:IsHidden() end
    )
    AddStaticTextListItem(
        CAI_DetailsList,
        function() return Controls.GameSpeed:GetToolTipString() end,
        nil,
        nil,
        function() return Controls.DetailsBox:IsHidden() end
    )
    -- TODO: maybe convert this into a read only EditBox in the future
    local technicalInfoLines = SplitNewlineText(Controls.VersionLabel:GetToolTipString())
    local tooltipLabel = Locale.Lookup("LOC_PAUSEMENU_INFO_OVERVIEW_TOOLTIP")
    for index, line in ipairs(technicalInfoLines) do
        local lineText = line
        -- hack to remove the tooltip title because we already use it as the list label
        if lineText ~= tooltipLabel then
            AddStaticTextListItem(
                CAI_DetailsList,
                function() return lineText end,
                nil,
                nil,
                function()
                    local label = Controls.VersionLabel:GetText()
                    return not label or label == "" or (index == 1 and lineText == "")
                end
            )
        end
    end
end

local function BuildPanelContent()
    if not CAI_Panel then return end

    CAI_Panel:ClearChildren()

    CAI_ButtonList = CreateSectionList(
    -- TODO: maybe change this title in the future
        function() return Controls.WindowTitle:GetText() end,
        function() return Controls.MainStack:IsHidden() end
    )
    CAI_Panel:AddChild(CAI_ButtonList)
    CAI_ModsList = nil
    CAI_DetailsList = nil

    local stackChildren = Controls.MainStack:GetChildren() or {}
    for _, child in ipairs(stackChildren) do
        local action = GetActionForControl(child)
        if action then
            AddButtonListItem(CAI_ButtonList, child, action)
        elseif child == Controls.ModsInUse then
            AddModsSection()
        end
    end

    AddDetailsSection()
end

local function BuildPanel()
    CAI_Panel = mgr:CreateUIWidget("Panel", {
        GetLabel = function()
            return Controls.WindowTitle:GetText()
        end
    })

    BuildPanelContent()
end

local function PopPausePanel()
    if not mgr or not CAI_Panel then return end

    if mgr:HasWidget(CAI_Panel) and mgr:GetTop() == CAI_Panel then
        mgr:Pop()
    end
    CAI_Panel = nil
    CAI_ButtonList = nil
    CAI_ModsList = nil
    CAI_DetailsList = nil
end

local function PushPausePanel()
    if not mgr or not Controls.PauseWindow or Controls.PauseWindow:IsHidden() then return end

    BuildPanel()
    if CAI_Panel then
        mgr:Push(CAI_Panel, PopupPriority.InGameTopOptionsMenu)
    end
end

OnInput = WrapFunc(OnInput, function(orig, input)
    if Controls.PauseWindow and Controls.PauseWindow:IsHidden() then
        return false
    end

    if mgr then
        local handled = mgr:HandleInput(input)
        if handled then
            return handled
        end
    end
    orig(input)
    return true
end)

SetupButtons = WrapFunc(SetupButtons, function(orig)
    orig()
    if Controls.PauseWindow and not Controls.PauseWindow:IsHidden() then
        BuildPanelContent()
    end
    if isOpening then
        if not mgr:HasWidget(CAI_Panel) then
            PushPausePanel()
        end
        isOpening = false
    end
end)

ContextPtr:SetHideHandler(PopPausePanel)
ContextPtr:SetInputHandler(OnInput, true)
LuaEvents.InGameTopOptionsMenu_Show.Add(function()
    isOpening = true
end)
