include("caiUtils")
include("InGameTopOptionsMenu")

local mgr = ExposedMembers.CAI_UIManager

local CAI_Panel = nil ---@type UIWidget|nil
local CAI_ButtonList = nil ---@type UIWidget|nil

local kPauseButtons = {
    { Key = "ReturnButton",    Action = function() OnReturn() end },
    { Key = "QuickSaveButton", Action = function() OnQuickSaveGame() end },
    { Key = "SaveGameButton",  Action = function() OnSaveGame() end },
    { Key = "LoadGameButton",  Action = function() OnLoadGame() end },
    { Key = "OptionsButton",   Action = function() OnOptions() end },
    { Key = "RetireButton",    Action = function() OnRetireGame() end },
    { Key = "PBCDeleteButton", Action = function() OnPBCDeleteButton() end },
    { Key = "PBCQuitButton",   Action = function() OnPBCQuitButton() end },
    { Key = "RestartButton",   Action = function() OnRestartGame() end },
    { Key = "MainMenuButton",  Action = function() OnMainMenu() end },
    { Key = "ExitGameButton",  Action = function() OnExitGameAskAreYouSure() end },
}

local function GetControl(name)
    local control = Controls[name]
    if not control then
        print("CAI pause menu missing control: " .. tostring(name))
    end
    return control
end

local function RebuildButtonList()
    if not CAI_ButtonList then return end

    CAI_ButtonList:ClearChildren()

    for _, def in ipairs(kPauseButtons) do
        local nativeButton = GetControl(def.Key)
        if nativeButton and not nativeButton:IsHidden() then
            local buttonWidget = mgr:CreateUIWidget("Button", {
                GetLabel = function()
                    return nativeButton:GetText()
                end,
                GetTooltip = function()
                    return nativeButton:GetToolTipString()
                end,
                IsDisabled = function()
                    return nativeButton:IsDisabled()
                end,
                OnFocusEnter = function()
                    UI.PlaySound("Main_Menu_Mouse_Over")
                end,
                OnClick = function(w)
                    if w.IsDisabled and w:IsDisabled() then
                        w:SpeakElements({ "label", "state", "tooltip" })
                        return
                    end
                    def.Action()
                end,
            })
            CAI_ButtonList:AddChild(buttonWidget)
        end
    end
end

local function BuildPanel()
    CAI_Panel = mgr:CreateUIWidget("Dialog", {
        GetLabel = function()
            return Controls.WindowTitle:GetText()
        end,
        SpeechSettings = { Role = false },
    })

    CAI_ButtonList = mgr:CreateUIWidget("List")
    CAI_Panel:AddChild(CAI_ButtonList)

    RebuildButtonList()
end

local function PopPausePanel()
    LuaEvents.InGameTopOptionsMenu_Close.Remove(PopPausePanel)
    if not mgr or not CAI_Panel then return end
    if mgr:HasWidget(CAI_Panel) and mgr:GetTop() == CAI_Panel then
        mgr:Pop()
    end
    CAI_Panel = nil
    CAI_ButtonList = nil
end

local function PushPausePanel()
    if not mgr then return end

    if CAI_Panel and mgr:HasWidget(CAI_Panel) then
        PopPausePanel()
    end

    BuildPanel()
    if CAI_Panel then
        mgr:Push(CAI_Panel)
        LuaEvents.InGameTopOptionsMenu_Close.Add(PopPausePanel)
    end
end

OnInput = WrapFunc(OnInput, function(orig, input)
    if mgr then
        mgr:HandleInput(input)
    end
    return orig(input)
end)

OnShow = WrapFunc(OnShow, function(orig)
    orig()
    if Controls.PauseWindow and not Controls.PauseWindow:IsHidden() then
        PushPausePanel()
    end
end)

SetupButtons = WrapFunc(SetupButtons, function(orig)
    orig()
    if Controls.PauseWindow and not Controls.PauseWindow:IsHidden() then
        RebuildButtonList()
    end
end)

ContextPtr:SetInputHandler(OnInput, true)
ContextPtr:SetShowHandler(OnShow)
-- Note(Hamada): for safety where the menu is  hidden and not closed
ContextPtr:SetHideHandler(PopPausePanel)
