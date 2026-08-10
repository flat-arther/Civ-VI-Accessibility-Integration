include("caiUtils")
include("TutorialUIRoot")
include("Civ6Common")

-- Vanilla uses this private selection lock only for the tutorial Warrior. The
-- tutorial check runs before the lock's forced deselection, while movement and
-- unit operations are restricted separately, so the lock only disrupts cycling.
-- Clear a lock restored from a save/hot reload, then ignore future requests.
UnlockUnit()
function LockUnit(_unitID)
end

---@ class TutItemEvents
---@field OnActivate? fun(item:table)
---@field OnDeactivate? fun(item:table)
---@field DetailedInputPath? string

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

local function EnableWarriorFreeRoamActions()
    EnableUnitAction("UNITOPERATION_MOVE_TO", "UNIT_WARRIOR")
    EnableUnitAction("UNITOPERATION_HEAL", "UNIT_WARRIOR")
    EnableUnitAction("UNITCOMMAND_CANCEL", "UNIT_WARRIOR")
end

local function DisableFirstSettlerMovement()
    DisableUnitAction("UNITOPERATION_MOVE_TO", "UNIT_SETTLER")
end

local function EnableFirstSettlerMovement()
    EnableUnitAction("UNITOPERATION_MOVE_TO", "UNIT_SETTLER")
end

local function EnableBuilderFormation()
    EnableUnitAction("UNITCOMMAND_ENTER_FORMATION", "UNIT_BUILDER")
end

DisableUnitAction("UNITCOMMAND_ENTER_FORMATION", "UNIT_BUILDER")

--- Table of hooks for tutorial items, keyed by item ID, then by event name (OnActivate / OnDeactivate). These functions will be called when the corresponding event happens for the item with the matching ID. The functions will be passed the item as a parameter.
--- They are mostly used to set certain controls to always receive input when specific tutorial items are active, since some tutorial items only activate a portion of the UI, like the production panel, and we need to make sure they receive input in those cases.
local TutorialItemHooks    = { ---@type table<string,TutItemEvents>
    ["CIVICS_TREE_H"] = {
        DetailedInputPath = "/InGame/CivicsTree",
    },
    ["TRAIN_WARRIORS"] = {
        DetailedInputPath = "/InGame/ProductionPanel",
    },
    ["TRAIN_BUILDER"] = {
        DetailedInputPath = "/InGame/ProductionPanel",
    },
    ["CONSTRUCTING_BUILDINGS_C"] = {
        DetailedInputPath = "/InGame/ProductionPanel",
    },
    ["TRAIN_SETTLER_B"] = {
        DetailedInputPath = "/InGame/ProductionPanel",
    },
    ["TRAIN_SLINGER"] = {
        DetailedInputPath = "/InGame/ProductionPanel",
    },
    ["DISTRICTS_F"] = {
        DetailedInputPath = "/InGame/ProductionPanel",
    },
    ["CAMPUS_COMPLETE_D"] = {
        DetailedInputPath = "/InGame/ProductionPanel",
    },
    ["GOVERNMENT_POLICIES_H"] = {
        DetailedInputPath = "/InGame/GovernmentScreen",
    },
    ["FIRST_PANTHEON_I"] = {
        DetailedInputPath = "/InGame/ReligionScreen",
    },
    ["FOUND_FIRST_CITY"] = {
        OnActivate = DisableFirstSettlerMovement,
        OnDeactivate = EnableFirstSettlerMovement,
    },
    ["SETTLER_FORMATION"] = {
        OnActivate = EnableBuilderFormation,
    },
    ["FOUND_SECOND_CITY_D"] = {
        OnActivate = EnableWarriorFreeRoamActions,
    },
}

local mgr                  = ExposedMembers.CAI_UIManager
local activeItem           = nil
local detailedItem         = nil
local tutorialLoaded       = false
local advisorCalloutBuffered = false
local bufferedControlCallouts = {}
local bufferedCalloutTexts = {}
local registeredTutorialControls = {}
local pendingControlCallouts = {}
local isRaisingDetailedTutorial = false
local screenCalloutDialog = nil
local screenCalloutQueue = {}
local pendingDetailedInputItem = nil
local activeDetailedInputPath = nil

local tutorialActivatedIds = {}

local HUD_TUTORIAL_CONTEXT_PATHS = {
    "/InGame/ActionPanel",
    "/InGame/CityPanel",
    "/InGame/DiplomacyRibbon",
    "/InGame/LaunchBar",
    "/InGame/MinimapPanel",
    "/InGame/NotificationPanel",
    "/InGame/PartialScreenHooks",
    "/InGame/PlotInfo",
    "/InGame/TopPanel",
    "/InGame/UnitFlagManager",
    "/InGame/UnitPanel",
    "/InGame/WorldInput",
    "/InGame/WorldTracker",
}

local HUD_TUTORIAL_CONTROL_IDS = {
    FaithYieldPointer = true,
    TechYieldPointer = true,
    TutBuildFarmAction = true,
    TutBuildQuarryAction = true,
    TutCivilopediaPointer = true,
    TutDiploRibbon = true,
    TutFormationAction = true,
    TutFortifyAction = true,
    TutFoundCityAction = true,
    TutMoveToTileAction = true,
    TutNotificationPointer = true,
    TutOpenCivics = true,
    TutOpenGovernment = true,
    TutOpenGP = true,
    TutOpenProduction = true,
    TutOpenReligion = true,
    TutOpenTechs = true,
    TutOpenWorldRankings = true,
    TutSelectLeaderIcon = true,
    TutTradeRouteAction = true,
    TutTradeRoutes = true,
}

local function IsHudTutorialControl(controlID)
    return HUD_TUTORIAL_CONTROL_IDS[controlID] == true
        or (type(controlID) == "string" and controlID:match("^TutSelectEndTurnAction") ~= nil)
end

local function ClearDetailedInputRegistration()
    pendingDetailedInputItem = nil
    if activeDetailedInputPath ~= nil then
        SetControlToAlwaysReceiveInput(activeDetailedInputPath, false)
        activeDetailedInputPath = nil
    end
end

local function ActivatePendingDetailedInput()
    local item = pendingDetailedInputItem
    if item == nil or activeItem ~= item or detailedItem ~= item then
        pendingDetailedInputItem = nil
        return
    end
    if screenCalloutDialog ~= nil or #screenCalloutQueue > 0 then return end
    pendingDetailedInputItem = nil

    local hook = TutorialItemHooks[item.ID]
    local path = hook and hook.DetailedInputPath or nil
    if path == nil then return end
    SetControlToAlwaysReceiveInput(path, true)
    activeDetailedInputPath = path
    LogMessage("Tutorial detailed input enabled: item=" .. tostring(item.ID) .. ", path=" .. path)
end

local function ScheduleDetailedInputRegistration(item)
    local hook = item and TutorialItemHooks[item.ID] or nil
    if hook == nil or hook.DetailedInputPath == nil then return end

    pendingDetailedInputItem = item
    ActivatePendingDetailedInput()
end

local function GetAdvisorCalloutLocation(advisorInfo)
    if advisorInfo == nil or advisorInfo.PlotCallback == nil then return nil end

    local plotReference = advisorInfo.PlotCallback()
    if type(plotReference) == "number" then
        if plotReference < 0 then return nil end
        local x, y = Map.GetPlotLocation(plotReference)
        if x == nil or y == nil then return nil end
        return { x = x, y = y }
    end

    if type(plotReference) == "table"
        and plotReference.GetX ~= nil
        and plotReference.GetY ~= nil then
        return { x = plotReference:GetX(), y = plotReference:GetY() }
    end

    if plotReference ~= nil then
        LogWarn("Tutorial advisor PlotCallback returned unsupported type: " .. type(plotReference))
    end
    return nil
end

local function ClearTutorialWorldAnchor()
    if ExposedMembers.CAI_TutorialWorldAnchor == nil then return end
    ExposedMembers.CAI_TutorialWorldAnchor = nil
    LuaEvents.CAI_TutorialWorldAnchorChanged()
end

local function SetTutorialWorldAnchor(header, location)
    if type(header) ~= "string" or header == ""
        or location == nil or location.x == nil or location.y == nil then
        ClearTutorialWorldAnchor()
        return
    end

    ExposedMembers.CAI_TutorialWorldAnchor = {
        Header = header,
        x = location.x,
        y = location.y,
    }
    LuaEvents.CAI_TutorialWorldAnchorChanged()
end

local function BufferAdvisorCallout(item)
    if advisorCalloutBuffered then return end
    if item == nil or item.UITriggers == nil or #item.UITriggers == 0 then return end
    local advisorInfo = item.AdvisorInfo
    if advisorInfo == nil or advisorInfo.PlotCallback == nil then return end

    local lines = {}
    if advisorInfo.CalloutHeader ~= nil and advisorInfo.CalloutHeader ~= "" then
        table.insert(lines, advisorInfo.CalloutHeader)
    end
    if advisorInfo.CalloutBody ~= nil and advisorInfo.CalloutBody ~= "" then
        table.insert(lines, advisorInfo.CalloutBody)
    end
    if #lines == 0 then return end

    local text = table.concat(lines, "[NEWLINE]")
    local location = GetAdvisorCalloutLocation(advisorInfo)
    advisorCalloutBuffered = true
    bufferedCalloutTexts[text] = true
    SetTutorialWorldAnchor(advisorInfo.CalloutHeader, location)
    LuaEvents.CAIAppendToMessageBuffer(
        text,
        "tutorial",
        location
    )
    LogMessage("Tutorial advisor callout buffered: item=" .. tostring(item.ID))
end

local function CollectLeafControlText(control, lines, seenText)
    local children = control.GetChildren ~= nil and control:GetChildren() or {}
    for _, child in ipairs(children) do
        local grandchildren = child.GetChildren ~= nil and child:GetChildren() or {}
        if #grandchildren > 0 then
            CollectLeafControlText(child, lines, seenText)
        elseif child.GetText ~= nil then
            local text = child:GetText()
            if type(text) == "string"
                and text:match("[^ \t\r\n]") ~= nil -- non-blank; ASCII-safe (not %S)
                and not seenText[text] then
                seenText[text] = true
                table.insert(lines, text)
            end
        end
    end
end

local function ShowNextScreenCallout()
    if screenCalloutDialog ~= nil then return end

    while #screenCalloutQueue > 0 do
        local callout = table.remove(screenCalloutQueue, 1)
        if activeItem == callout.Item then
            local content = {}
            if callout.Body ~= "" then
                table.insert(content, mgr:CreateWidget(mgr:GenerateWidgetId("CAITutorialCalloutBody"), "StaticText", {
                    Label = callout.Body,
                }))
            end

            local okButton = mgr:CreateWidget(mgr:GenerateWidgetId("CAITutorialCalloutOK"), "Button", {
                Label = function() return Locale.Lookup("LOC_ADVISOR_BUTTON_OK") end,
            })
            local dialog
            okButton:On("activate", function()
                if screenCalloutDialog ~= dialog then return end
                screenCalloutDialog = nil
                mgr:RemoveFromStack(dialog:GetId())
                if #screenCalloutQueue > 0 then
                    ShowNextScreenCallout()
                else
                    ScheduleDetailedInputRegistration(activeItem)
                end
            end)

            dialog = mgr.WidgetHelpers.MakeGeneralDialog(
                function() return callout.Header end,
                { okButton },
                content,
                1
            )
            if dialog == nil then return end

            screenCalloutDialog = dialog
            LuaEvents.CAIAppendToMessageBuffer(callout.Text, "tutorial", nil, false)
            mgr:Push(dialog, { priority = PopupPriority.Tutorial })
            LogMessage(
                "Tutorial screen callout dialog pushed: item="
                .. tostring(callout.Item.ID)
                .. ", control="
                .. tostring(callout.ControlID)
            )
            return
        end
    end
    ScheduleDetailedInputRegistration(activeItem)
end

local function ClearScreenCallouts()
    pendingControlCallouts = {}
    screenCalloutQueue = {}
    if screenCalloutDialog ~= nil then
        local dialog = screenCalloutDialog
        screenCalloutDialog = nil
        mgr:RemoveFromStack(dialog:GetId(), false)
    end
end

local function PresentTutorialControlCallout(callout)
    if bufferedCalloutTexts[callout.Text] then
        LogMessage(
            "Tutorial control callout suppressed as duplicate: item="
            .. tostring(callout.Item.ID)
            .. ", control="
            .. tostring(callout.ControlID)
        )
        return
    end
    bufferedCalloutTexts[callout.Text] = true

    if callout.IsHud then
        LuaEvents.CAIAppendToMessageBuffer(callout.Text, "tutorial")
        LogMessage(
            "Tutorial HUD callout buffered: item="
            .. tostring(callout.Item.ID)
            .. ", control="
            .. tostring(callout.ControlID)
        )
        return
    end

    table.insert(screenCalloutQueue, callout)
    ShowNextScreenCallout()
end

local function FlushPendingControlCallouts()
    local pending = pendingControlCallouts
    pendingControlCallouts = {}
    for _, callout in ipairs(pending) do
        if activeItem == callout.Item then
            PresentTutorialControlCallout(callout)
        end
    end
end

local function OnTutorialControlShown(control)
    local item = detailedItem or activeItem
    if item == nil then return end

    local controlID = control:GetID()
    if controlID == "TutSelectUnit" then return end

    local lines = {}
    CollectLeafControlText(control, lines, {})
    if #lines == 0 then return end

    local text = table.concat(lines, "[NEWLINE]")
    local calloutKey = tostring(item.ID) .. "\31" .. tostring(controlID) .. "\31" .. text
    if bufferedControlCallouts[calloutKey] then return end
    bufferedControlCallouts[calloutKey] = true

    local bodyLines = {}
    for i = 2, #lines do table.insert(bodyLines, lines[i]) end
    local registration = registeredTutorialControls[control]
    local callout = {
        Item = item,
        ControlID = controlID,
        Header = lines[1],
        Body = table.concat(bodyLines, "[NEWLINE]"),
        Text = text,
        IsHud = IsHudTutorialControl(controlID) or (registration and registration.IsHud == true),
    }
    if isRaisingDetailedTutorial then
        table.insert(pendingControlCallouts, callout)
    else
        PresentTutorialControlCallout(callout)
    end
end

local function RegisterTutorialControl(control, isHud)
    local existing = registeredTutorialControls[control]
    if existing then
        if isHud then existing.IsHud = true end
        return 0
    end

    local controlID = control.GetID ~= nil and control:GetID() or nil
    if control.GetType ~= nil
        and control:GetType() == "Tutorial"
        and controlID ~= "TutSelectUnit" then
        registeredTutorialControls[control] = { IsHud = isHud == true }
        control:RegisterWhenShown(function()
            OnTutorialControlShown(control)
        end)
        return 1
    end

    return 0
end

local function RegisterTutorialControlsBelow(control, isHud)
    if control == nil then return 0, 0 end

    local found = control.GetType ~= nil and control:GetType() == "Tutorial" and 1 or 0
    local registered = RegisterTutorialControl(control, isHud)
    local children = control.GetChildren ~= nil and control:GetChildren() or {}
    for _, child in ipairs(children) do
        local childFound, childRegistered = RegisterTutorialControlsBelow(child, isHud)
        found = found + childFound
        registered = registered + childRegistered
    end
    return found, registered
end

local function RegisterNativeTutorialCallouts()
    local hudRegistered = 0
    for _, path in ipairs(HUD_TUTORIAL_CONTEXT_PATHS) do
        local _, registered = RegisterTutorialControlsBelow(ContextPtr:LookUpControl(path), true)
        hudRegistered = hudRegistered + registered
    end

    local inGameRoot = ContextPtr:LookUpControl("/InGame")
    local found, registered = RegisterTutorialControlsBelow(inGameRoot, false)
    LogMessage(
        "Tutorial callout control scan: found="
        .. tostring(found)
        .. ", new="
        .. tostring(registered + hudRegistered)
    )
end

local function PublishTutorialState()
    local state = {
        ActiveItemId = activeItem and activeItem.ID or nil,
        DetailedItemId = detailedItem and detailedItem.ID or nil,
        HasDetailedItem = detailedItem ~= nil,
        UITriggers = {},
        EnabledControlIds = {},
        EnabledControlHashes = {},
    }
    if detailedItem then
        for _, trigger in ipairs(detailedItem.UITriggers or {}) do
            state.UITriggers[trigger] = true
        end
        for _, control in ipairs(detailedItem.EnabledControls or {}) do
            if type(control) == "number" then
                state.EnabledControlHashes[control] = true
            else
                state.EnabledControlIds[control] = true
                state.EnabledControlHashes[UITutorialManager:GetHash(control)] = true
            end
        end
    end
    ExposedMembers.CAI_TutorialState = state
end

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
    ClearScreenCallouts()
    ClearDetailedInputRegistration()
    ClearTutorialWorldAnchor()
    activeItem = item
    detailedItem = nil
    advisorCalloutBuffered = false
    bufferedControlCallouts = {}
    bufferedCalloutTexts = {}
    pendingControlCallouts = {}
    PublishTutorialState()
    orig(item)
    local hook = TutorialItemHooks[item.ID]
    if hook and hook.OnActivate then hook.OnActivate() end
    NotifyActionPanelAllowed()
end)

DeActivateItem = WrapFunc(DeActivateItem, function(orig, item)
    if activeItem == item then
        ClearScreenCallouts()
        ClearDetailedInputRegistration()
        ClearTutorialWorldAnchor()
    end
    orig(item)
    local hook = TutorialItemHooks[item.ID]
    if hook and hook.OnDeactivate then hook.OnDeactivate() end
    if activeItem == item then
        activeItem = nil
        detailedItem = nil
        PublishTutorialState()
        NotifyActionPanelAllowed()
    end
end)

RaiseDetailedTutorial = WrapFunc(RaiseDetailedTutorial, function(orig, item)
    detailedItem = item
    PublishTutorialState()
    isRaisingDetailedTutorial = true
    local result = orig(item)
    isRaisingDetailedTutorial = false
    if activeItem ~= item then return result end
    NotifyActionPanelAllowed()
    LuaEvents.CAI_TutorialDetailedControlsReady()
    BufferAdvisorCallout(item)
    FlushPendingControlCallouts()
    ScheduleDetailedInputRegistration(item)
    return result
end)

OnInput = WrapFunc(OnInput, function(orig, input)
    -- Stop input from executing when it shouldn't be, like when the pause menu is open or the tutorial isn't running because this context is always active, and it gets input first in the tutorial
    local topOptionsMenu = ContextPtr:LookUpControl("/InGame/TopOptionsMenu");
    if not IsTutorialRunning() or UIManager:IsInPopupQueue(topOptionsMenu) then
        return false
    end

    if screenCalloutDialog ~= nil and mgr and mgr:GetTop() == screenCalloutDialog then
        mgr:HandleInput(input)
        return true
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
    if key == Keys.VK_ESCAPE and event == KeyEvents.KeyUp and tutorialLoaded
        and Input.GetActiveContext() == InputContext.World then
        LuaEvents.InGame_OpenInGameOptionsMenu();
        return true
    end
    return orig(input)
end)

ContextPtr:SetInputHandler(OnInput, true)
Events.LoadScreenClose.Add(function()
    if not tutorialLoaded then tutorialLoaded = true end
    RegisterNativeTutorialCallouts()
end)
RegisterNativeTutorialCallouts()
PublishTutorialState()
ClearTutorialWorldAnchor()
