include("caiUtils")
include("Civ6Common")
if IsExpansion2Active() then
    include("LaunchBar_Expansion2")
elseif IsExpansion1Active() then
    include("LaunchBar_Expansion1")
else
    include("LaunchBar")
end

local function ControlIsHidden(control)
    return control == nil or control:IsHidden()
end

local function ControlIsDisabled(control)
    return control ~= nil and control:IsDisabled()
end

local function SpeakControlFailure(control, fallbackTag)
    if control and control.GetToolTipString then
        local tooltip = control:GetToolTipString()
        if tooltip and tooltip ~= "" then
            Speak(tooltip)
            return
        end
    end
    Speak(Locale.Lookup(fallbackTag))
end

local function GetFeatureUnavailableTag(capability, fallbackTag)
    if IsLocalPlayerObserving() then
        return "LOC_CAI_UI_UNAVAILABLE_WHILE_OBSERVING"
    end
    if not GameCapabilities.HasCapability(capability) then
        return "LOC_CAI_UI_UNAVAILABLE_IN_CURRENT_GAME"
    end
    return fallbackTag
end

local function TryOpen(orig, vanillaActionId, control, unavailableTag)
    if ControlIsHidden(control) then
        Speak(Locale.Lookup(unavailableTag))
        return
    end
    if ControlIsDisabled(control) then
        SpeakControlFailure(control, unavailableTag)
        return
    end
    orig(vanillaActionId)
end

local m_caiOpenTechTreeId = Input.GetActionId("UI_CAIOpenTechTree")
local m_caiOpenCivicsTreeId = Input.GetActionId("UI_CAIOpenCivicsTree")
local m_caiOpenGovernmentId = Input.GetActionId("UI_CAIOpenGovernment")
local m_caiOpenReligionId = Input.GetActionId("UI_CAIOpenReligion")
local m_caiOpenGreatPeopleId = Input.GetActionId("UI_CAIOpenGreatPeople")
local m_caiOpenGreatWorksId = Input.GetActionId("UI_CAIOpenGreatWorks")

local m_vanillaToggleTechTree = Input.GetActionId("ToggleTechTree")
local m_vanillaToggleCivicsTree = Input.GetActionId("ToggleCivicsTree")
local m_vanillaToggleGovernment = Input.GetActionId("ToggleGovernment")
local m_vanillaToggleReligion = Input.GetActionId("ToggleReligion")
local m_vanillaToggleGreatPeople = Input.GetActionId("ToggleGreatPeople")
local m_vanillaToggleGreatWorks = Input.GetActionId("ToggleGreatWorks")

local m_caiOpenGovernorsId = Input.GetActionId("UI_CAIOpenGovernors")
local m_caiOpenHistoricMomentsId = Input.GetActionId("UI_CAIOpenHistoricMoments")
local m_vanillaToggleGovernors
local m_vanillaToggleTimeline

if IsExpansion1Active() or IsExpansion2Active() then
    m_vanillaToggleGovernors = Input.GetActionId("ToggleGovernors")
    m_vanillaToggleTimeline = Input.GetActionId("ToggleTimeline")
end

local m_caiOpenWorldClimateId = Input.GetActionId("UI_CAIOpenWorldClimate")
local m_vanillaToggleWorldClimate

if IsExpansion2Active() then
    m_vanillaToggleWorldClimate = Input.GetActionId("ToggleWorldClimate")
end

OnInputActionStarted = WrapFunc(OnInputActionTriggered, function(orig, actionId)
    if m_caiOpenTechTreeId and actionId == m_caiOpenTechTreeId then
        TryOpen(orig, m_vanillaToggleTechTree, Controls.ScienceButton,
            "LOC_CAI_UI_TECH_TREE_UNAVAILABLE")
        return
    end
    if m_caiOpenCivicsTreeId and actionId == m_caiOpenCivicsTreeId then
        TryOpen(orig, m_vanillaToggleCivicsTree, Controls.CultureButton,
            "LOC_CAI_UI_CIVICS_TREE_UNAVAILABLE")
        return
    end
    if m_caiOpenGovernmentId and actionId == m_caiOpenGovernmentId then
        TryOpen(orig, m_vanillaToggleGovernment, Controls.GovernmentButton,
            GetFeatureUnavailableTag("CAPABILITY_GOVERNMENTS_VIEW", "LOC_CAI_UI_GOVERNMENT_LOCKED"))
        return
    end
    if m_caiOpenReligionId and actionId == m_caiOpenReligionId then
        TryOpen(orig, m_vanillaToggleReligion, Controls.ReligionButton,
            GetFeatureUnavailableTag("CAPABILITY_RELIGION_VIEW", "LOC_CAI_UI_RELIGION_LOCKED"))
        return
    end
    if m_caiOpenGreatPeopleId and actionId == m_caiOpenGreatPeopleId then
        if UI.QueryGlobalParameterInt("DISABLE_GREAT_PEOPLE_HOTKEY") == 1 then
            Speak(Locale.Lookup("LOC_CAI_UI_GREAT_PEOPLE_HOTKEY_DISABLED"))
        else
            TryOpen(orig, m_vanillaToggleGreatPeople, Controls.GreatPeopleButton,
                GetFeatureUnavailableTag("CAPABILITY_GREAT_PEOPLE_VIEW", "LOC_CAI_UI_GREAT_PEOPLE_UNAVAILABLE"))
        end
        return
    end
    if m_caiOpenGreatWorksId and actionId == m_caiOpenGreatWorksId then
        if UI.QueryGlobalParameterInt("DISABLE_GREAT_WORKS_HOTKEY") == 1 then
            Speak(Locale.Lookup("LOC_CAI_UI_GREAT_WORKS_HOTKEY_DISABLED"))
        else
            TryOpen(orig, m_vanillaToggleGreatWorks, Controls.GreatWorksButton,
                GetFeatureUnavailableTag("CAPABILITY_GREAT_WORKS_VIEW", "LOC_CAI_UI_NO_GREAT_WORKS"))
        end
        return
    end
    if m_caiOpenGovernorsId and actionId == m_caiOpenGovernorsId then
        if m_vanillaToggleGovernors then
            orig(m_vanillaToggleGovernors)
        else
            Speak(Locale.Lookup("LOC_CAI_UI_REQUIRES_RISE_AND_FALL"))
        end
        return
    end
    if m_caiOpenHistoricMomentsId and actionId == m_caiOpenHistoricMomentsId then
        if m_vanillaToggleTimeline then
            orig(m_vanillaToggleTimeline)
        else
            Speak(Locale.Lookup("LOC_CAI_UI_REQUIRES_RISE_AND_FALL"))
        end
        return
    end
    if m_caiOpenWorldClimateId and actionId == m_caiOpenWorldClimateId then
        if not IsExpansion2Active() then
            Speak(Locale.Lookup("LOC_CAI_UI_REQUIRES_GATHERING_STORM"))
        elseif not GameCapabilities.HasCapability("CAPABILITY_WORLD_CLIMATE_VIEW") then
            Speak(Locale.Lookup("LOC_CAI_UI_CLIMATE_UNAVAILABLE"))
        else
            orig(m_vanillaToggleWorldClimate)
        end
        return
    end
end)

Subscribe = WrapFunc(Subscribe, function(orig)
    orig()
    Events.InputActionTriggered.Remove(OnInputActionTriggered);
    Events.InputActionStarted.Add(OnInputActionStarted);
end)

Unsubscribe = WrapFunc(Unsubscribe, function(orig)
    orig()
    Events.InputActionStarted.Remove(OnInputActionStarted)
end)
