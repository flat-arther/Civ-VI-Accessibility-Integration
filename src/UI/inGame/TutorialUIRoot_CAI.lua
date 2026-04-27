include("caiUtils")
include("TutorialUIRoot")

local mgr = ExposedMembers.CAI_UIManager
local activeItem = nil
local detailedItem = nil

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
    return orig(item)
end)

OnInput = WrapFunc(OnInput, function(orig, input)
    if detailedItem and HasUITrigger(detailedItem, "ChooseProductionMenu") then
        if mgr then
            local handled = mgr:HandleInput(input)
            if handled then
                return true
            end
        end
    end
    return orig(input)
end)

ContextPtr:SetInputHandler(OnInput, true)
