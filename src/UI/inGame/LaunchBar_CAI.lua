include("caiUtils")
include("Civ6Common")
if IsExpansion2Active() then
    include("LaunchBar_Expansion2")
elseif IsExpansion1Active() then
    include("LaunchBar_Expansion1")
else
    include("LaunchBar")
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

local m_caiOpenGovernorsId
local m_caiOpenHistoricMomentsId
local m_vanillaToggleGovernors
local m_vanillaToggleTimeline

if IsExpansion1Active() or IsExpansion2Active() then
    m_caiOpenGovernorsId = Input.GetActionId("UI_CAIOpenGovernors")
    m_caiOpenHistoricMomentsId = Input.GetActionId("UI_CAIOpenHistoricMoments")
    m_vanillaToggleGovernors = Input.GetActionId("ToggleGovernors")
    m_vanillaToggleTimeline = Input.GetActionId("ToggleTimeline")
end

local m_caiOpenWorldClimateId
local m_vanillaToggleWorldClimate

if IsExpansion2Active() then
    m_caiOpenWorldClimateId = Input.GetActionId("UI_CAIOpenWorldClimate")
    m_vanillaToggleWorldClimate = Input.GetActionId("ToggleWorldClimate")
end

OnInputActionTriggered = WrapFunc(OnInputActionTriggered, function(orig, actionId)
    if m_caiOpenTechTreeId and actionId == m_caiOpenTechTreeId then
        orig(m_vanillaToggleTechTree)
        return
    end
    if m_caiOpenCivicsTreeId and actionId == m_caiOpenCivicsTreeId then
        orig(m_vanillaToggleCivicsTree)
        return
    end
    if m_caiOpenGovernmentId and actionId == m_caiOpenGovernmentId then
        orig(m_vanillaToggleGovernment)
        return
    end
    if m_caiOpenReligionId and actionId == m_caiOpenReligionId then
        orig(m_vanillaToggleReligion)
        return
    end
    if m_caiOpenGreatPeopleId and actionId == m_caiOpenGreatPeopleId then
        orig(m_vanillaToggleGreatPeople)
        return
    end
    if m_caiOpenGreatWorksId and actionId == m_caiOpenGreatWorksId then
        orig(m_vanillaToggleGreatWorks)
        return
    end
    if m_caiOpenGovernorsId and actionId == m_caiOpenGovernorsId then
        orig(m_vanillaToggleGovernors)
        return
    end
    if m_caiOpenHistoricMomentsId and actionId == m_caiOpenHistoricMomentsId then
        orig(m_vanillaToggleTimeline)
        return
    end
    if m_caiOpenWorldClimateId and actionId == m_caiOpenWorldClimateId then
        orig(m_vanillaToggleWorldClimate)
        return
    end
end)
