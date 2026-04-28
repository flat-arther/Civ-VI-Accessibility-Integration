include("caiUtils")
include("TutorialUIRoot")
include("Civ6Common")

local mgr = ExposedMembers.CAI_UIManager
local activeItem = nil
local detailedItem = nil
local tutorialLoaded = false

local function HasUITrigger(item, triggerName)
    if not item or not item.UITriggers then return false end

    for _, trigger in ipairs(item.UITriggers) do
        if trigger == triggerName then
            return true
        end
    end

    return false
end

ActivateItem = WrapFunc(ActivateItem, function(orig, item)
    activeItem = item
    detailedItem = nil
    return orig(item)
end)

DeActivateItem = WrapFunc(DeActivateItem, function(orig, item)
    if activeItem == item then
        activeItem = nil
        detailedItem = nil
    end

    return orig(item)
end)

RaiseDetailedTutorial = WrapFunc(RaiseDetailedTutorial, function(orig, item)
    detailedItem = item
    local result = orig(item)
    LuaEvents.CAI_TutorialDetailedControlsReady()
    return result
end)

OnInput = WrapFunc(OnInput, function(orig, input)
    -- Stop input from executing when it shouldn't be, like when the pause menu is open or the tutorial isn't running because this context is always active, and it gets input first in the tutorial
    local topOptionsMenu = ContextPtr:LookUpControl("/InGame/TopOptionsMenu");
    if not IsTutorialRunning() or UIManager:IsInPopupQueue(topOptionsMenu) then
        return false
    end

    if detailedItem and HasUITrigger(detailedItem, "ChooseProductionMenu") then
        if mgr then
            local handled = mgr:HandleInput(input)
            if handled then
                return true
            end
        end
    end

    -- have to do this because the original has the escape key miss spelled and it doesn't work
    local event = input:GetMessageType()
    local key = input:GetKey()
    if key == Keys.VK_ESCAPE and event == KeyEvents.KeyUp and tutorialLoaded then
        LuaEvents.InGame_OpenInGameOptionsMenu();
        return true
    end
    return orig(input)
end)

ContextPtr:SetInputHandler(OnInput, true)
Events.LoadScreenClose.Add(function() tutorialLoaded = true end)
