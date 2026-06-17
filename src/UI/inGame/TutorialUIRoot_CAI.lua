include("caiUtils")
include("TutorialUIRoot")
include("Civ6Common")
---@ class TutItemEvents
---@field OnActivate fun(item:table)
---@field OnDeactivate fun(item:table)

--# Helpers
local function SetControlToAlwaysReceiveInput(path, state)
    local control = ContextPtr:LookUpControl(path)
    if not control then return end
    if state then
        UITutorialManager:AddControlToAlwaysReceiveInput(control)
    else
        UITutorialManager:RemoveControlToAlwaysReceiveInput(control)
    end
end

local function ActivateProductionPanel(item) SetControlToAlwaysReceiveInput("/InGame/ProductionPanel", true) end
local function DeactivateProductionPanel(item) SetControlToAlwaysReceiveInput("/InGame/ProductionPanel", false) end

--- Table of hooks for tutorial items, keyed by item ID, then by event name (OnActivate / OnDeactivate). These functions will be called when the corresponding event happens for the item with the matching ID. The functions will be passed the item as a parameter.
--- They are mostly used to set certain controls to always receive input when specific tutorial items are active, since some tutorial items only activate a portion of the UI, like the production panel, and we need to make sure they receive input in those cases.
local TutorialItemHooks    = { ---@type table<string,TutItemEvents>
    ["CIVICS_TREE_H"] = {
        OnActivate = function(item)
            SetControlToAlwaysReceiveInput("/InGame/CivicsTree", true)
        end,
        OnDeactivate = function(item)
            SetControlToAlwaysReceiveInput("/InGame/CivicsTree", false)
        end
    },
    ["TRAIN_WARRIORS"] = {
        OnActivate = ActivateProductionPanel,
        OnDeactivate = DeactivateProductionPanel
    },
    ["TRAIN_BUILDER"] = {
        OnActivate = ActivateProductionPanel,
        OnDeactivate = DeactivateProductionPanel
    },
    ["CONSTRUCTING_BUILDINGS_C"] = {
        OnActivate = ActivateProductionPanel,
        OnDeactivate = DeactivateProductionPanel
    },
    ["TRAIN_SETTLER_B"] = {
        OnActivate = ActivateProductionPanel,
        OnDeactivate = DeactivateProductionPanel
    },
    ["TRAIN_SLINGER"] = {
        OnActivate = ActivateProductionPanel,
        OnDeactivate = DeactivateProductionPanel
    },
    ["DISTRICTS_F"] = {
        OnActivate = ActivateProductionPanel,
        OnDeactivate = DeactivateProductionPanel
    },
    ["CAMPUS_COMPLETE_D"] = {
        OnActivate = ActivateProductionPanel,
        OnDeactivate = DeactivateProductionPanel
    },
    ["GOVERNMENT_POLICIES_H"] = {
        OnActivate = function(item)
            SetControlToAlwaysReceiveInput("/InGame/GovernmentScreen", true)
        end,
        OnDeactivate = function(item)
            SetControlToAlwaysReceiveInput("/InGame/GovernmentScreen", false)
        end
    },
}

local mgr                  = ExposedMembers.CAI_UIManager
local activeItem           = nil
local detailedItem         = nil
local tutorialLoaded       = false

local tutorialActivatedIds = {

}
--- List of CAI UI widgets that, when open, should allow the escape key to pass through to them instead of being caught by the tutorial and opening the pause menu. This is necessary because the tutorial context is always active and has an input handler that catches the escape key, so we need to make sure it doesn't interfere with other UI elements that also use the escape key.
local escapePassthroughIds = {
    "CAITutorialGoalsList",
    "CAINotificationCenterTree",
    "CAIGovernmentPolicyPicker",
    "CAIGovernmentAllPoliciesTree",
    "CAIActionPanelTurnBlockerList",
    "CAIUnitPanelActionList",
    "CAICityPanelList",
    "CAITopPanelYieldInfoTree",
    "CAITopPanelResourceInfoTree",
    "CAIWorldInputInterfaceMode",
    "CAICivicsTreePanel",
    "CAICivicsTreeFilterList",
    "CAITechTreePanel",
    "CAITechTreeFilterList",
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

local function NotifyActionPanelAllowed()
    local allowed = false
    if activeItem ~= nil and #activeItem.UITriggers > 0 then
        if HasUITrigger(activeItem, "ActionPanel") then allowed = true end
    else
        allowed = true
    end
    LuaEvents.CAI_TutorialActionPanelAllowed(allowed)
end

ActivateItem = WrapFunc(ActivateItem, function(orig, item)
    activeItem = item
    detailedItem = nil
    orig(item)
    Speak("Activating item " .. item.ID)
    local hook = TutorialItemHooks[item.ID]
    if hook and hook.OnActivate then hook.OnActivate() end
    NotifyActionPanelAllowed()
end)

DeActivateItem = WrapFunc(DeActivateItem, function(orig, item)
    orig(item)
    local hook = TutorialItemHooks[item.ID]
    if hook and hook.OnDeactivate then hook.OnDeactivate() end
    if activeItem == item then
        activeItem = nil
        detailedItem = nil
        NotifyActionPanelAllowed()
    end
    Speak("DeActivateItem: " .. item.ID)
end)

RaiseDetailedTutorial = WrapFunc(RaiseDetailedTutorial, function(orig, item)
    detailedItem = item
    local result = orig(item)
    NotifyActionPanelAllowed()
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
