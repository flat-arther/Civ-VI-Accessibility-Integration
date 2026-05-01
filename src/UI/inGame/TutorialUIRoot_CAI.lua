include("caiUtils")
include("TutorialUIRoot")
include("Civ6Common")


local mgr                  = ExposedMembers.CAI_UIManager
local activeItem           = nil
local detailedItem         = nil
local tutorialLoaded       = false

local tutorialActivatedIds = {
    ChooseProductionMenu = true,
    ButtonPolicies = true
}
local escapePassthroughIds = {
    "CAINotificationCenterTree",
    "CAIActionPanelTurnBlockerList",
    "CAIUnitPanelActionList",
    "CAICityPanelList",
    "CAITopPanelResourceInfoList",
    "CAITopPanelYieldInfoTree",
    "CAIWorldInputInterfaceMode",
}

local function HasUITrigger(item, triggerName)
    if not item or not item.UITriggers then return false end

    for _, trigger in ipairs(item.UITriggers) do
        if trigger == triggerName then
            return true
        end
    end

    return false
end

local function NotifyActionPanelAllowed(item)
    LuaEvents.CAI_TutorialActionPanelAllowed(item ~= nil and HasUITrigger(item, "ActionPanel"))
end

ActivateItem = WrapFunc(ActivateItem, function(orig, item)
    activeItem = item
    detailedItem = nil
    LuaEvents.CAI_TutorialActionPanelAllowed(false)
    return orig(item)
end)

DeActivateItem = WrapFunc(DeActivateItem, function(orig, item)
    if activeItem == item then
        activeItem = nil
        detailedItem = nil
        LuaEvents.CAI_TutorialActionPanelAllowed(false)
    end

    return orig(item)
end)

RaiseDetailedTutorial = WrapFunc(RaiseDetailedTutorial, function(orig, item)
    detailedItem = item
    local result = orig(item)
    NotifyActionPanelAllowed(detailedItem)
    LuaEvents.CAI_TutorialDetailedControlsReady()
    return result
end)

OnInput = WrapFunc(OnInput, function(orig, input)
    -- Stop input from executing when it shouldn't be, like when the pause menu is open or the tutorial isn't running because this context is always active, and it gets input first in the tutorial
    local topOptionsMenu = ContextPtr:LookUpControl("/InGame/TopOptionsMenu");
    if not IsTutorialRunning() or UIManager:IsInPopupQueue(topOptionsMenu) then
        return false
    end

    -- If the current detailed item has the choose production menu trigger, we need the manager to handle input for it here, otherwise the production menu won't work in the tutorial. This is due to the fact that only part of the production panel is activated, and not the entire context
    if detailedItem then
        for id, _ in pairs(tutorialActivatedIds) do
            if HasUITrigger(detailedItem, id) then
                if mgr then
                    local handled = mgr:HandleInput(input)
                    if handled then
                        return true
                    end
                end
            end
        end
    end

    -- have to do this because the original has the escape key misspelled and it doesn't work
    local event = input:GetMessageType()
    local key = input:GetKey()
    if key == Keys.VK_ESCAPE and event == KeyEvents.KeyUp and tutorialLoaded then
        -- don't handle escape if certain UI elements are open, like the notification center, since the tutorial is always active and would cause escape to not work for those elements
        for _, id in ipairs(escapePassthroughIds) do
            local hasWidget = mgr and mgr:GetWidgetById(id, true)
            if hasWidget then
                return false
            end
        end
        LuaEvents.InGame_OpenInGameOptionsMenu();
        return true
    end
    return orig(input)
end)

ContextPtr:SetInputHandler(OnInput, true)
Events.LoadScreenClose.Add(function() tutorialLoaded = true end)
