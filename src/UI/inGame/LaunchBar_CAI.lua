include("caiUtils")
include("Civ6Common")
if GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_PIRATES" then
    include("LaunchBar_PiratesScenario")
elseif IsExpansion2Active() then
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

local function TryOpen(orig, vanillaActionId, control, controlId, unavailableTag)
    if not IsCAITutorialControlAllowed(controlId) then
        Speak(Locale.Lookup("LOC_CAI_UI_BLOCKED_BY_TUTORIAL"))
        return
    end
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

-- ===========================================================================
-- #Accessibility integration: Launch Bar screen-launcher list (Shift+Tab)
--
-- Central registry of every screen-opening action in the game. This reaches
-- well beyond the launch bar on purpose: the same list also drives the World
-- Tracker choosers, Top Panel reports, the World Congress, the partial-screen
-- hooks, and the CAI utility panels. Other files/mods contribute entries
-- through LuaEvents.CAILaunchBar_RegisterAction / _UnregisterAction, so an
-- add-on such as Quick Deals can add its own screen once it is active.
--
-- Per row: the label is the action name plus its key binding (mirroring the
-- unit action list). The tooltip leads with the dynamic portion -- the reason
-- a screen cannot open right now, or live state such as the current research,
-- civic, World Congress status, or governor titles -- followed by the game's
-- official tooltip. Rows whose screen cannot open expose a disabled predicate,
-- which the UI manager already turns into a no-op on activation.
-- ===========================================================================

local mgr = ExposedMembers.CAI_UIManager

local LAUNCHBAR_LIST_ID = "CAILaunchBar_List"

local m_caiOpenLaunchBarId = Input.GetActionId("UI_CAIOpenLaunchBar")

local m_launchList = nil

-- Tracks whether we have registered this context with the tutorial's
-- always-receive-input list (mirrors NotificationPanel_CAI).
local m_tutorialAlwaysReceiveInput = false

-- External descriptors registered by other files/mods, keyed by id.
local m_externalActions = {}

-- Forward declarations (Lua resolves upvalues at parse time).
local PushLaunchBar, PopLaunchBar, ToggleLaunchBar

-- ---------------------------------------------------------------------------
-- Small helpers
-- ---------------------------------------------------------------------------

-- Locale.Lookup returns the tag itself on a miss; treat that as empty so we
-- never speak a raw LOC tag when a vanilla/DLC tooltip tag is not present.
local function SafeLookup(tag)
    if tag == nil or tag == "" then return "" end
    local text = Locale.Lookup(tag)
    if text == tag then return "" end
    return text
end

-- An entry's title may be a fixed LOC tag or a function returning one (used by
-- registrations whose screen name is only known live, e.g. the Civ Royale
-- global ability, which changes with the local player's faction).
local function ResolveTitleTag(entry)
    local t = entry.title
    if type(t) == "function" then t = t() end
    return t
end

local function GetLaunchPlayer()
    local playerID = Game.GetLocalPlayer()
    if playerID == nil or playerID < 0 then return nil, nil end
    return playerID, Players[playerID]
end

-- Vanilla launch-bar and partial-screen tooltips lead with the screen name on
-- its own line (e.g. "Government[NEWLINE]View or manage..."). The row label
-- already names the screen, so drop that redundant first line. Splitting on the
-- first line break is the only per-screen text handling allowed by the coding
-- rules; token stripping and whitespace collapsing still happen centrally.
local function StripTooltipHeader(text)
    if text == nil or text == "" then return "" end
    local _, e = text:find("%[NEWLINE%]", 1)
    if e == nil then _, e = text:find("\n", 1, true) end
    if e == nil then return text end
    local rest = text:sub(e + 1)
    if rest == "" then return text end
    return rest
end

local function Cap(capability)
    return GameCapabilities.HasCapability(capability)
end

-- Key binding text for an action, matching the unit action list formatting.
local function BindingText(actionName)
    if actionName == nil then return nil end
    local actionId = Input.GetActionId(actionName)
    if actionId == nil then return nil end
    local parts = {}
    local g1 = Input.GetGestureDisplayString(actionId, 0)
    local g2 = Input.GetGestureDisplayString(actionId, 1)
    if g1 and g1 ~= "" then table.insert(parts, g1) end
    if g2 and g2 ~= "" then table.insert(parts, g2) end
    if #parts == 0 then return nil end
    return table.concat(parts, "[NEWLINE]")
end

local function HasMetCityState(player)
    if player == nil then return false end
    local diplomacy = player:GetDiplomacy()
    for _, minor in ipairs(PlayerManager.GetAliveMinors()) do
        if diplomacy:HasMet(minor:GetID()) then return true end
    end
    return false
end

-- ---------------------------------------------------------------------------
-- Dynamic tooltip fragments (live game state)
-- ---------------------------------------------------------------------------

local function CurrentResearchLine()
    local _, player = GetLaunchPlayer()
    if player == nil then return "" end
    local techs = player:GetTechs()
    local techID = techs and techs:GetResearchingTech() or -1
    if techID == nil or techID < 0 then
        return Locale.Lookup("LOC_CAI_WORLDTRACKER_RESEARCH_LINE",
            Locale.Lookup("LOC_WORLD_TRACKER_CHOOSE_RESEARCH"))
    end
    local tech = GameInfo.Technologies[techID]
    local inner = Locale.Lookup(tech.Name)
    local turns = techs:GetTurnsLeft()
    if turns ~= nil and turns >= 0 then
        inner = inner .. "[NEWLINE]" .. Locale.Lookup("LOC_CAI_WORLDTRACKER_TURNS_REMAINING", turns)
    end
    return Locale.Lookup("LOC_CAI_WORLDTRACKER_RESEARCH_LINE", inner)
end

local function CurrentCivicLine()
    local _, player = GetLaunchPlayer()
    if player == nil then return "" end
    local culture = player:GetCulture()
    local civicID = culture and culture:GetProgressingCivic() or -1
    if civicID == nil or civicID < 0 then
        return Locale.Lookup("LOC_CAI_WORLDTRACKER_CIVIC_LINE",
            Locale.Lookup("LOC_WORLD_TRACKER_CHOOSE_CIVIC"))
    end
    local civic = GameInfo.Civics[civicID]
    local inner = Locale.Lookup(civic.Name)
    local turns = culture:GetTurnsLeft()
    if turns ~= nil and turns >= 0 then
        inner = inner .. "[NEWLINE]" .. Locale.Lookup("LOC_CAI_WORLDTRACKER_TURNS_REMAINING", turns)
    end
    return Locale.Lookup("LOC_CAI_WORLDTRACKER_CIVIC_LINE", inner)
end

-- Free policy change available -- the same signal the launch bar's free-policy
-- indicator uses. Anarchy is already surfaced as the unavailable reason.
local function GovernmentAttention()
    local _, player = GetLaunchPlayer()
    if player == nil then return "" end
    local culture = player:GetCulture()
    if culture == nil or culture:IsInAnarchy() then return "" end
    if culture:GetNumPoliciesUnlocked() <= 0 then return "" end
    if culture:GetCostToUnlockPolicies() == 0 and culture:PolicyChangeMade() == false then
        return Locale.Lookup("LOC_HUD_GOVT_FREE_CHANGES")
    end
    return ""
end

local function ReligionAttention()
    local _, player = GetLaunchPlayer()
    if player == nil then return "" end
    local religion = player:GetReligion()
    if religion == nil then return "" end
    if religion:GetPantheon() < 0 and religion:CanCreatePantheon() then
        return Locale.Lookup("LOC_CAI_LAUNCH_ATTENTION_PANTHEON")
    end
    return ""
end

local function GovernorsAttention()
    if not (IsExpansion1Active() or IsExpansion2Active()) then return "" end
    local _, player = GetLaunchPlayer()
    if player == nil then return "" end
    local governors = player:GetGovernors()
    if governors == nil then return "" end
    if governors:CanAppoint() or governors:CanPromote() then
        local available = governors:GetGovernorPoints() - governors:GetGovernorPointsSpent()
        if available > 0 then
            return Locale.Lookup("LOC_CAI_LAUNCH_GOVERNOR_TITLES", available)
        end
        return Locale.Lookup("LOC_GOVERNOR_ACTION_AVAILABLE")
    end
    return ""
end

local function EraLine()
    if not (IsExpansion1Active() or IsExpansion2Active()) then return "" end
    local eras = Game.GetEras()
    if eras == nil then return "" end
    local era = GameInfo.Eras[eras:GetCurrentEra()]
    if era == nil then return "" end
    return Locale.Lookup(era.Name)
end

-- Count only notifications that actually occupy the vanilla notification rail --
-- the same ones the CAI notification center lists. End-turn-blocking
-- notifications get no rail instance (vanilla routes them to the ActionPanel), so
-- they must not be counted here. Mirrors NotificationPanel's rail-add test:
-- non-blocking, icon-displayable, and visible in the UI.
local function IsRailNotification(notification)
    if notification == nil then return false end
    if not notification:IsVisibleInUI() then return false end
    if notification:GetEndTurnBlocking() ~= EndTurnBlockingTypes.NO_ENDTURN_BLOCKING then return false end
    if not notification:IsIconDisplayable() then return false end
    return true
end

local function LiveNotificationCount()
    local playerID = Game.GetLocalPlayer()
    if playerID == nil or playerID < 0 then return 0 end
    local ids = NotificationManager.GetList(playerID) or {}
    local count = 0
    for _, id in ipairs(ids) do
        if IsRailNotification(NotificationManager.Find(playerID, id)) then
            count = count + 1
        end
    end
    return count
end

local function NotificationCountLine()
    local count = LiveNotificationCount()
    if count <= 0 then
        return Locale.Lookup("LOC_CAI_LAUNCH_NO_NOTIFICATIONS")
    end
    return Locale.Lookup("LOC_CAI_LAUNCH_NOTIFICATION_COUNT", count)
end

local function HasNotifications()
    return LiveNotificationCount() > 0
end

-- Attention signal shared with the ActionPanel turn blockers: a screen wants the
-- player's attention when the game is currently end-turn-blocked on a choice that
-- screen resolves (pick research/civic, found religion, add a belief, claim a
-- great person, give an envoy, change government, ...). Returns true if any of
-- the supplied EndTurnBlockingTypes is active for the local player.
local function HasEndTurnBlocking(...)
    local playerID = Game.GetLocalPlayer()
    if playerID == nil or playerID < 0 then return false end
    local blockers = NotificationManager.GetAllEndTurnBlocking(playerID)
    if blockers == nil then return false end
    local wanted = { ... }
    for _, active in ipairs(blockers) do
        for _, want in ipairs(wanted) do
            if active == want then return true end
        end
    end
    return false
end

-- The descriptive sentence each end-turn blocker already carries in vanilla (the
-- same text the ActionPanel turn-blocker tooltip shows, e.g. "You have earned a
-- Great Person, and need to choose whether to accept them or pass on them."). All
-- vanilla LOC tags, so they are already localized in every language.
local ENDTURN_BLOCKING_TOOLTIP = {
    [EndTurnBlockingTypes.ENDTURN_BLOCKING_RESEARCH]                 = "LOC_ACTION_PANEL_NEEDS_RESEARCH_TOOLTIP",
    [EndTurnBlockingTypes.ENDTURN_BLOCKING_CIVIC]                    = "LOC_ACTION_PANEL_NEEDS_CIVIC_TOOLTIP",
    [EndTurnBlockingTypes.ENDTURN_BLOCKING_FILL_CIVIC_SLOT]          = "LOC_ACTION_PANEL_FILL_CIVIC_SLOT_TOOLTIP",
    [EndTurnBlockingTypes.ENDTURN_BLOCKING_CONSIDER_GOVERNMENT_CHANGE] = "LOC_ACTION_PANEL_CONSIDER_GOVERNMENT_CHANGE_TOOLTIP",
    [EndTurnBlockingTypes.ENDTURN_BLOCKING_PANTHEON]                 = "LOC_ACTION_PANEL_NEEDS_PANTHEON_TOOLTIP",
    [EndTurnBlockingTypes.ENDTURN_BLOCKING_RELIGION]                 = "LOC_ACTION_PANEL_NEEDS_RELIGION_TOOLTIP",
    [EndTurnBlockingTypes.ENDTURN_BLOCKING_BELIEF]                   = "LOC_ACTION_PANEL_NEEDS_BELIEF_TOOLTIP",
    [EndTurnBlockingTypes.ENDTURN_BLOCKING_GIVE_INFLUENCE_TOKEN]     = "LOC_ACTION_PANEL_GIVE_INFLUENCE_TOKEN_TOOLTIP",
    [EndTurnBlockingTypes.ENDTURN_BLOCKING_CLAIM_GREAT_PERSON]       = "LOC_ACTION_PANEL_CLAIM_GREAT_PERSON_TOOLTIP",
}

-- The blocker sentence for the first active matching type, or "" when the local
-- player is not currently blocked on any of them. Drives the attention rows'
-- dynamic tooltip line.
local function BlockingLine(...)
    local playerID = Game.GetLocalPlayer()
    if playerID == nil or playerID < 0 then return "" end
    local blockers = NotificationManager.GetAllEndTurnBlocking(playerID)
    if blockers == nil then return "" end
    local wanted = { ... }
    for _, active in ipairs(blockers) do
        for _, want in ipairs(wanted) do
            if active == want and ENDTURN_BLOCKING_TOOLTIP[want] then
                return Locale.Lookup(ENDTURN_BLOCKING_TOOLTIP[want])
            end
        end
    end
    return ""
end

-- Join non-empty fragments with a line break (skips blanks so a missing blocker
-- line never leaves a leading/trailing separator).
local function JoinLines(...)
    local parts = {}
    for _, s in ipairs({ ... }) do
        if s and s ~= "" then parts[#parts + 1] = s end
    end
    return table.concat(parts, "[NEWLINE]")
end

-- World Congress helpers (mirrors DiplomacyRibbon_CAI so the launch bar reports
-- congress state "as if K were pressed").
local function CongressHasButton()
    if not IsExpansion2Active() then return false end
    if not Cap("CAPABILITY_WORLD_CONGRESS") then return false end
    if Game.GetEras():GetCurrentEra() < GlobalParameters.WORLD_CONGRESS_INITIAL_ERA then return false end
    return true
end

local function CongressUnavailableReason()
    if not IsExpansion2Active() or not Cap("CAPABILITY_WORLD_CONGRESS") then
        return Locale.Lookup("LOC_CAI_UI_WORLD_CONGRESS_UNAVAILABLE")
    end
    local initialEra = GlobalParameters.WORLD_CONGRESS_INITIAL_ERA
    if Game.GetEras():GetCurrentEra() < initialEra then
        local era = GameInfo.Eras[initialEra]
        local eraName = era and Locale.Lookup(era.Name) or tostring(initialEra)
        return Locale.Lookup("LOC_CAI_UI_WORLD_CONGRESS_START_ERA", eraName)
    end
    return nil
end

local function CongressInSession()
    local stage1 = DB.MakeHash("TURNSEG_WORLDCONGRESS_1")
    local stage2 = DB.MakeHash("TURNSEG_WORLDCONGRESS_2")
    local resolution = DB.MakeHash("TURNSEG_WORLDCONGRESS_RESOLUTION")
    local seg = Game.GetCurrentTurnSegment()
    return seg == stage1 or seg == stage2 or seg == resolution
end

local function CongressStatusLine()
    if not CongressHasButton() then return "" end
    if CongressInSession() then
        return Locale.Lookup("LOC_WORLD_CONGRESS_IS_CURRENTLY_IN_SESSION")
    end
    local pData = Game.GetWorldCongress():GetMeetingStatus()
    return Locale.Lookup("LOC_WORLD_CONGRESS_HUD_BAR_TIME_UNTIL_NEXT_SESSION", pData.TurnsLeft + 1)
end

local function OpenCongress()
    if CongressInSession() then
        LuaEvents.CongressButton_ResumeCongress()
    else
        LuaEvents.CongressButton_ShowCongressResults()
    end
end

-- ---------------------------------------------------------------------------
-- Shared unavailable-reason helpers (mirror the hotkey open paths)
-- ---------------------------------------------------------------------------

local function TutorialReason(controlId)
    if not IsCAITutorialControlAllowed(controlId) then
        return Locale.Lookup("LOC_CAI_UI_BLOCKED_BY_TUTORIAL")
    end
    return nil
end

-- A launch-bar control that is hidden means "locked/unavailable"; a control
-- that is disabled carries the live vanilla reason in its tooltip (e.g.
-- anarchy). Falls back to the supplied tag.
local function LaunchControlReason(control, controlId, unavailableTag)
    local tut = TutorialReason(controlId)
    if tut then return tut end
    if ControlIsHidden(control) then
        return Locale.Lookup(unavailableTag)
    end
    if ControlIsDisabled(control) then
        local tip = control.GetToolTipString and control:GetToolTipString() or ""
        if tip ~= "" then return tip end
        return Locale.Lookup(unavailableTag)
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- Built-in descriptor set
-- ---------------------------------------------------------------------------

local function BuildBuiltinEntries()
    local entries = {}
    local function add(entry) entries[#entries + 1] = entry end

    add({
        id = "tech_tree", title = "LOC_TECH_TREE_HEADER", name = "LOC_CAI_OPEN_TECH_TREE", action = "UI_CAIOpenTechTree",
        desc = "LOC_CAI_OPEN_TECH_TREE_TOOLTIP",
        gate = function() return Cap("CAPABILITY_TECH_TREE") end,
        reason = function()
            return LaunchControlReason(Controls.ScienceButton, "ScienceButton",
                "LOC_CAI_UI_TECH_TREE_UNAVAILABLE")
        end,
        dynamic = function()
            return JoinLines(BlockingLine(EndTurnBlockingTypes.ENDTURN_BLOCKING_RESEARCH), CurrentResearchLine())
        end,
        attention = function() return HasEndTurnBlocking(EndTurnBlockingTypes.ENDTURN_BLOCKING_RESEARCH) end,
        open = function() OnOpenResearch() end,
    })
    add({
        id = "civics_tree", title = "LOC_CIVICS_TREE_HEADER", name = "LOC_CAI_OPEN_CIVICS_TREE", action = "UI_CAIOpenCivicsTree",
        desc = "LOC_CAI_OPEN_CIVICS_TREE_TOOLTIP",
        gate = function() return Cap("CAPABILITY_CIVICS_TREE") end,
        reason = function()
            return LaunchControlReason(Controls.CultureButton, "CultureButton",
                "LOC_CAI_UI_CIVICS_TREE_UNAVAILABLE")
        end,
        dynamic = function()
            return JoinLines(BlockingLine(EndTurnBlockingTypes.ENDTURN_BLOCKING_CIVIC), CurrentCivicLine())
        end,
        attention = function() return HasEndTurnBlocking(EndTurnBlockingTypes.ENDTURN_BLOCKING_CIVIC) end,
        open = function() OnOpenCulture() end,
    })
    add({
        id = "government", name = "LOC_CAI_OPEN_GOVERNMENT", action = "UI_CAIOpenGovernment",
        desc = "LOC_CAI_OPEN_GOVERNMENT_TOOLTIP", control = Controls.GovernmentButton,
        gate = function() return Cap("CAPABILITY_GOVERNMENTS_VIEW") and not IsLocalPlayerObserving() end,
        reason = function()
            return LaunchControlReason(Controls.GovernmentButton, "GovernmentButton",
                GetFeatureUnavailableTag("CAPABILITY_GOVERNMENTS_VIEW", "LOC_CAI_UI_GOVERNMENT_LOCKED"))
        end,
        dynamic = function()
            return JoinLines(
                BlockingLine(EndTurnBlockingTypes.ENDTURN_BLOCKING_CONSIDER_GOVERNMENT_CHANGE,
                    EndTurnBlockingTypes.ENDTURN_BLOCKING_FILL_CIVIC_SLOT),
                GovernmentAttention())
        end,
        attention = function()
            return GovernmentAttention() ~= ""
                or HasEndTurnBlocking(EndTurnBlockingTypes.ENDTURN_BLOCKING_CONSIDER_GOVERNMENT_CHANGE,
                    EndTurnBlockingTypes.ENDTURN_BLOCKING_FILL_CIVIC_SLOT)
        end,
        open = function() OnOpenGovernment() end,
    })
    add({
        id = "religion", title = "LOC_UI_RELIGION_TITLE", name = "LOC_CAI_OPEN_RELIGION", action = "UI_CAIOpenReligion",
        desc = "LOC_CAI_OPEN_RELIGION_TOOLTIP", control = Controls.ReligionButton,
        gate = function() return Cap("CAPABILITY_RELIGION_VIEW") and not IsLocalPlayerObserving() end,
        reason = function()
            return LaunchControlReason(Controls.ReligionButton, "ReligionButton",
                GetFeatureUnavailableTag("CAPABILITY_RELIGION_VIEW", "LOC_CAI_UI_RELIGION_LOCKED"))
        end,
        dynamic = function()
            return JoinLines(
                BlockingLine(EndTurnBlockingTypes.ENDTURN_BLOCKING_PANTHEON,
                    EndTurnBlockingTypes.ENDTURN_BLOCKING_RELIGION,
                    EndTurnBlockingTypes.ENDTURN_BLOCKING_BELIEF),
                ReligionAttention())
        end,
        attention = function()
            return ReligionAttention() ~= ""
                or HasEndTurnBlocking(EndTurnBlockingTypes.ENDTURN_BLOCKING_PANTHEON,
                    EndTurnBlockingTypes.ENDTURN_BLOCKING_RELIGION,
                    EndTurnBlockingTypes.ENDTURN_BLOCKING_BELIEF)
        end,
        open = function() OnOpenReligion() end,
    })
    add({
        id = "great_people", title = "LOC_GREAT_PEOPLE_TITLE", name = "LOC_CAI_OPEN_GREAT_PEOPLE", action = "UI_CAIOpenGreatPeople",
        desc = "LOC_CAI_OPEN_GREAT_PEOPLE_TOOLTIP",
        gate = function() return Cap("CAPABILITY_GREAT_PEOPLE_VIEW") and not IsLocalPlayerObserving() end,
        reason = function()
            return LaunchControlReason(Controls.GreatPeopleButton, "GreatPeopleButton",
                GetFeatureUnavailableTag("CAPABILITY_GREAT_PEOPLE_VIEW", "LOC_CAI_UI_GREAT_PEOPLE_UNAVAILABLE"))
        end,
        dynamic = function() return BlockingLine(EndTurnBlockingTypes.ENDTURN_BLOCKING_CLAIM_GREAT_PERSON) end,
        attention = function() return HasEndTurnBlocking(EndTurnBlockingTypes.ENDTURN_BLOCKING_CLAIM_GREAT_PERSON) end,
        open = function() OnOpenGreatPeople() end,
    })
    add({
        id = "great_works", title = "LOC_GREAT_WORKS_SCREEN_TITLE", name = "LOC_CAI_OPEN_GREAT_WORKS", action = "UI_CAIOpenGreatWorks",
        desc = "LOC_CAI_OPEN_GREAT_WORKS_TOOLTIP",
        gate = function() return Cap("CAPABILITY_GREAT_WORKS_VIEW") and not IsLocalPlayerObserving() end,
        reason = function()
            return LaunchControlReason(Controls.GreatWorksButton, "GreatWorksButton",
                GetFeatureUnavailableTag("CAPABILITY_GREAT_WORKS_VIEW", "LOC_CAI_UI_NO_GREAT_WORKS"))
        end,
        open = function() OnOpenGreatWorks() end,
    })
    add({
        id = "governors", name = "LOC_CAI_OPEN_GOVERNORS", action = "UI_CAIOpenGovernors",
        desc = "LOC_CAI_OPEN_GOVERNORS_TOOLTIP", vanillaTip = "LOC_HUD_LAUNCHBAR_GOVERNOR_BUTTON",
        gate = function()
            return (IsExpansion1Active() or IsExpansion2Active())
                and Cap("CAPABILITY_GOVERNORS") and not IsLocalPlayerObserving()
        end,
        reason = function() return TutorialReason("GovernorButton") end,
        dynamic = GovernorsAttention,
        attention = function() return GovernorsAttention() ~= "" end,
        open = function() if ToggleGovernors then ToggleGovernors() end end,
    })
    add({
        id = "historic_moments", name = "LOC_CAI_OPEN_HISTORIC_MOMENTS", action = "UI_CAIOpenHistoricMoments",
        desc = "LOC_CAI_OPEN_HISTORIC_MOMENTS_TOOLTIP", vanillaTip = "LOC_HUD_LAUNCHBAR_HISTORIAN_BUTTON",
        gate = function()
            return (IsExpansion1Active() or IsExpansion2Active())
                and Cap("CAPABILITY_HISTORIC_MOMENTS") and not IsLocalPlayerObserving()
        end,
        reason = function() return TutorialReason("HistoricMomentsButton") end,
        open = function() if ToggleHistoricMoments then ToggleHistoricMoments() end end,
    })
    add({
        id = "world_climate", name = "LOC_CAI_OPEN_WORLD_CLIMATE", action = "UI_CAIOpenWorldClimate",
        desc = "LOC_CAI_OPEN_WORLD_CLIMATE_TOOLTIP", vanillaTip = "LOC_LAUNCHBAR_CLIMATE_PROGRESS_TOOLTIP",
        gate = function() return IsExpansion2Active() and Cap("CAPABILITY_WORLD_CLIMATE_VIEW") end,
        reason = function() return TutorialReason("WorldClimateButton") end,
        open = function() if OnToggleClimateScreen then OnToggleClimateScreen() end end,
    })
    add({
        id = "city_states", name = "LOC_CAI_OPEN_CITY_STATES", action = "UI_CAIOpenCityStates",
        desc = "LOC_CAI_OPEN_CITY_STATES_TOOLTIP", vanillaTip = "LOC_PARTIALSCREEN_CITYSTATES_TOOLTIP",
        gate = function() return Cap("CAPABILITY_CITY_STATES_VIEW") end,
        reason = function()
            local tut = TutorialReason("CityStatesButton")
            if tut then return tut end
            local _, player = GetLaunchPlayer()
            if not HasMetCityState(player) then
                return Locale.Lookup("LOC_CAI_UI_NO_CITY_STATES_MET")
            end
            return nil
        end,
        dynamic = function() return BlockingLine(EndTurnBlockingTypes.ENDTURN_BLOCKING_GIVE_INFLUENCE_TOKEN) end,
        attention = function() return HasEndTurnBlocking(EndTurnBlockingTypes.ENDTURN_BLOCKING_GIVE_INFLUENCE_TOKEN) end,
        open = function() LuaEvents.PartialScreenHooks_OpenCityStates() end,
    })
    add({
        id = "espionage", name = "LOC_CAI_OPEN_ESPIONAGE", action = "UI_CAIOpenEspionage",
        desc = "LOC_CAI_OPEN_ESPIONAGE_TOOLTIP", vanillaTip = "LOC_PARTIALSCREEN_ESPIONAGE_TOOLTIP",
        gate = function() return Cap("CAPABILITY_ESPIONAGE_VIEW") end,
        reason = function()
            local tut = TutorialReason("EspionageButton")
            if tut then return tut end
            local _, player = GetLaunchPlayer()
            if player == nil or player:GetDiplomacy():GetSpyCapacity() <= 0 then
                return Locale.Lookup("LOC_CAI_UI_NO_SPY_CAPACITY")
            end
            return nil
        end,
        open = function() LuaEvents.PartialScreenHooks_OpenEspionage() end,
    })
    add({
        id = "world_rankings", title = "LOC_WORLD_RANKINGS_TITLE", name = "LOC_CAI_OPEN_WORLD_RANKINGS", action = "UI_CAIOpenWorldRankings",
        desc = "LOC_CAI_OPEN_WORLD_RANKINGS_TOOLTIP",
        gate = function() return Cap("CAPABILITY_DISPLAY_HUD_WORLD_RANKINGS") end,
        reason = function() return TutorialReason("WorldRankingsButton") end,
        open = function() LuaEvents.PartialScreenHooks_OpenWorldRankings() end,
    })
    add({
        id = "trade_overview", title = "LOC_TRADE_OVERVIEW_TITLE", name = "LOC_CAI_OPEN_TRADE_OVERVIEW", action = "UI_CAIOpenTradeOverview",
        desc = "LOC_CAI_OPEN_TRADE_OVERVIEW_TOOLTIP",
        gate = function() return Cap("CAPABILITY_TRADE_VIEW") end,
        reason = function()
            local tut = TutorialReason("TradeRoutesButton")
            if tut then return tut end
            local _, player = GetLaunchPlayer()
            if player == nil or player:GetTrade():GetOutgoingRouteCapacity() <= 0 then
                return Locale.Lookup("LOC_CAI_UI_NO_TRADE_ROUTE_CAPACITY")
            end
            return nil
        end,
        open = function() LuaEvents.PartialScreenHooks_OpenTradeOverview() end,
    })
    add({
        id = "era_progress", name = "LOC_CAI_OPEN_ERA_PROGRESS", action = "UI_CAIOpenEraProgress",
        desc = "LOC_CAI_OPEN_ERA_PROGRESS_TOOLTIP", vanillaTip = "LOC_PARTIALSCREEN_ERA_PROGRESS_TOOLTIP",
        gate = function() return (IsExpansion1Active() or IsExpansion2Active()) and Cap("CAPABILITY_ERAS") end,
        reason = function() return TutorialReason("EraProgressButton") end,
        dynamic = EraLine,
        open = function() LuaEvents.PartialScreenHooks_OpenEraProgressPanel() end,
    })
    add({
        id = "reports", name = "LOC_CAI_TOP_PANEL_OPEN_REPORTS", action = "UI_TopPanelOpenReports",
        desc = "LOC_CAI_TOP_PANEL_OPEN_REPORTS_TOOLTIP", vanillaTip = "LOC_PARTIALSCREEN_REPORTS_TOOLTIP",
        gate = function() return Cap("CAPABILITY_REPORTS_LIST") end,
        reason = function() return TutorialReason("LaunchBar_Hook_Reports") end,
        open = function() LuaEvents.TopPanel_OpenReportsScreen() end,
    })
    add({
        id = "global_resources", title = "LOC_GLOBAL_RESOURCES_TITLE", name = "LOC_CAI_GLOBAL_RES_OPEN", action = "UI_OpenGlobalResourcePopup",
        desc = "LOC_CAI_GLOBAL_RES_OPEN_TOOLTIP",
        gate = function() return Cap("CAPABILITY_DIPLOMACY_DEALS") end,
        open = function() LuaEvents.GlobalReportsList_OpenResources() end,
    })
    add({
        id = "world_congress", title = "LOC_CAI_DIPLO_RIBBON_CONGRESS", name = "LOC_CAI_DIPLO_RIBBON_OPEN_CONGRESS",
        action = "UI_DiplomacyRibbonOpenWorldCongress", desc = "LOC_CAI_DIPLO_RIBBON_OPEN_CONGRESS_TOOLTIP",
        gate = function() return IsExpansion2Active() and Cap("CAPABILITY_WORLD_CONGRESS") end,
        reason = CongressUnavailableReason,
        dynamic = CongressStatusLine,
        attention = function() return CongressHasButton() and CongressInSession() end,
        open = OpenCongress,
    })
    add({
        id = "diplo_ribbon_list", title = "LOC_CAI_DIPLO_RIBBON_LABEL", name = "LOC_CAI_DIPLO_RIBBON_OPEN_LIST", action = "UI_DiplomacyRibbonOpenList",
        desc = "LOC_CAI_DIPLO_RIBBON_OPEN_LIST_TOOLTIP",
        gate = function() return true end,
        reason = function()
            local _, player = GetLaunchPlayer()
            if player == nil then return Locale.Lookup("LOC_CAI_UI_DIPLOMACY_UNAVAILABLE") end
            return nil
        end,
        open = function() LuaEvents.CAILaunchBarOpen_DiploRibbonList() end,
    })
    add({
        id = "civilopedia", title = "LOC_CAI_TUTORIAL_NAME_CIVILOPEDIA", name = "LOC_CAI_OPEN_CIVILOPEDIA", action = "UI_CAIOpenCivilopedia",
        desc = "LOC_CAI_OPEN_CIVILOPEDIA_TOOLTIP",
        gate = function() return true end,
        open = function() LuaEvents.OpenCivilopedia() end,
    })
    add({
        id = "notification_center", title = "LOC_CAI_NOTIFICATION_CENTER", name = "LOC_CAI_NOTIFICATION_CENTER", action = "UI_NotificationPanelOpenList",
        desc = "LOC_CAI_NOTIFICATION_CENTER_TOOLTIP",
        gate = function() return true end,
        dynamic = NotificationCountLine,
        attention = HasNotifications,
        open = function() LuaEvents.CAILaunchBarOpen_NotificationCenter() end,
    })
    add({
        id = "tutorial_goals", title = "LOC_CAI_TUTORIAL_GOALS", name = "LOC_CAI_TUTORIAL_GOALS_HOTKEY", action = "UI_TutorialGoalsOpenList",
        desc = "LOC_CAI_TUTORIAL_GOALS_HOTKEY_TOOLTIP",
        gate = function() return true end,
        open = function() LuaEvents.CAILaunchBarOpen_TutorialGoals() end,
    })
    add({
        id = "lens_list", title = "LOC_CAI_MINIMAP_LENS_LIST", name = "LOC_CAI_MINIMAP_OPEN_LENS_LIST", action = "UI_CAIMinimapOpenLensList",
        desc = "LOC_CAI_MINIMAP_OPEN_LENS_LIST_TOOLTIP",
        gate = function() return true end,
        open = function() LuaEvents.CAIMinimapLensListToggle() end,
    })
    add({
        id = "map_pin_list", title = "LOC_HUD_MAP_PIN_LIST", name = "LOC_CAI_MINIMAP_OPEN_MAP_PIN_LIST", action = "UI_CAIMinimapOpenMapPinList",
        desc = "LOC_CAI_MINIMAP_OPEN_MAP_PIN_LIST_TOOLTIP",
        gate = function() return true end,
        open = function() LuaEvents.CAIMinimapMapPinListToggle() end,
    })
    add({
        id = "map_search", title = "LOC_HUD_MAP_SEARCH", name = "LOC_CAI_OPEN_MAP_SEARCH", action = "UI_CAIOpenMapSearch",
        desc = "LOC_CAI_OPEN_MAP_SEARCH_TOOLTIP",
        gate = function() return true end,
        open = function() LuaEvents.CAILaunchBarOpen_MapSearch() end,
    })
    add({
        id = "chat", title = "LOC_CAI_CHAT_PANEL_TITLE", name = "LOC_CAI_OPEN_CHAT_PANEL", action = "UI_OpenChatPanel",
        desc = "LOC_CAI_OPEN_CHAT_PANEL_TOOLTIP",
        gate = function() return GameConfiguration.IsAnyMultiplayer() end,
        open = function() LuaEvents.CAILaunchBarOpen_Chat() end,
    })

    return entries
end

-- ---------------------------------------------------------------------------
-- Row title resolution
-- ---------------------------------------------------------------------------

-- The raw (unstripped) official tooltip, used to recover the vanilla screen
-- title from its header line when no explicit title tag is supplied.
local function OfficialTooltipRaw(entry)
    if entry.control ~= nil then
        local tip = entry.control.GetToolTipString and entry.control:GetToolTipString() or ""
        if tip ~= "" then return tip end
    end
    return SafeLookup(entry.vanillaTip)
end

-- First line of the official tooltip (the vanilla screen name), or "".
local function OfficialHeader(entry)
    local raw = OfficialTooltipRaw(entry)
    if raw == "" then return "" end
    local s = raw:find("%[NEWLINE%]", 1)
    if s == nil then s = raw:find("\n", 1, true) end
    if s == nil then return "" end
    return raw:sub(1, s - 1)
end

-- Screen title for the row: explicit title tag, else the vanilla tooltip
-- header, else the CAI action name as a last resort.
local function EntryTitle(entry)
    local title = SafeLookup(ResolveTitleTag(entry))
    if title == "" then title = OfficialHeader(entry) end
    if title == "" then
        title = SafeLookup(entry.name)
        if title == "" then title = entry.name or "" end
    end
    return title
end

-- ---------------------------------------------------------------------------
-- External registration (other files/mods contribute entries)
-- ---------------------------------------------------------------------------

local function OnRegisterAction(def)
    if def == nil or def.id == nil then return end
    m_externalActions[def.id] = def
end

local function OnUnregisterAction(id)
    if id == nil then return end
    m_externalActions[id] = nil
end

-- Combined and filtered descriptor list (built-ins plus external registrations)
-- for the current game state. Ordering: screens that currently want the player's
-- attention (a free policy change, an available pantheon, unspent governor
-- titles, pending notifications, a ready Civ Royale ability, ...) rise to the
-- top; everything else follows alphabetically. Attention and title are read once
-- per entry here so the live predicates are not re-run for every sort comparison.
local function CollectEntries()
    local ranked = {}
    local function consider(entry)
        if entry.gate == nil or entry.gate() then
            ranked[#ranked + 1] = {
                entry     = entry,
                attention = (entry.attention ~= nil and entry.attention()) and true or false,
                titleKey  = EntryTitle(entry):lower(),
            }
        end
    end
    for _, entry in ipairs(BuildBuiltinEntries()) do consider(entry) end
    for _, def in pairs(m_externalActions) do consider(def) end
    table.sort(ranked, function(a, b)
        if a.attention ~= b.attention then return a.attention end
        if a.titleKey ~= b.titleKey then return a.titleKey < b.titleKey end
        return tostring(a.entry.id) < tostring(b.entry.id)
    end)
    local result = {}
    for _, r in ipairs(ranked) do result[#result + 1] = r.entry end
    return result
end

-- ---------------------------------------------------------------------------
-- Row + list construction
-- ---------------------------------------------------------------------------

local function EntryLabel(entry)
    local title = EntryTitle(entry)
    local binding = BindingText(entry.action)
    if binding and binding ~= "" then
        return title .. ": " .. binding
    end
    return title
end

local function EntryOfficialTooltip(entry)
    if entry.control ~= nil then
        local tip = entry.control.GetToolTipString and entry.control:GetToolTipString() or ""
        if tip ~= "" then return StripTooltipHeader(tip) end
    end
    local vanilla = SafeLookup(entry.vanillaTip)
    if vanilla ~= "" then return StripTooltipHeader(vanilla) end
    if entry.officialTooltip then
        local custom = entry.officialTooltip()
        if custom and custom ~= "" then return StripTooltipHeader(custom) end
    end
    return StripTooltipHeader(SafeLookup(entry.desc))
end

local function EntryTooltip(entry)
    local parts = {}
    local reason = entry.reason and entry.reason() or nil
    if reason and reason ~= "" then
        table.insert(parts, reason)
    else
        local dyn = entry.dynamic and entry.dynamic() or ""
        if dyn ~= "" then table.insert(parts, dyn) end
    end
    local official = EntryOfficialTooltip(entry)
    -- A disabled control's reason is often its own live tooltip; don't repeat it.
    if official ~= "" and official ~= parts[1] then table.insert(parts, official) end
    return table.concat(parts, "[NEWLINE]")
end

local function MakeRow(entry)
    local row = mgr:CreateWidget(mgr:GenerateWidgetId("CAILaunchBar_Row"), "Button", {
        Label             = function() return EntryLabel(entry) end,
        Tooltip           = function() return EntryTooltip(entry) end,
        DisabledPredicate = function() return (entry.reason and entry.reason() ~= nil) or false end,
        FocusKey          = "cai_launch:" .. tostring(entry.id),
    })
    row:SetFocusSound("Main_Menu_Mouse_Over")
    row:On("activate", function()
        PopLaunchBar()
        if entry.open then entry.open() end
    end)
    return row
end

local function BuildLaunchList()
    m_launchList = mgr:CreateWidget(LAUNCHBAR_LIST_ID, "List", {
        Label = function() return Locale.Lookup("LOC_CAI_LAUNCH_BAR") end,
    })
    m_launchList:AddInputBindings({
        {
            Key = Keys.VK_ESCAPE,
            MSG = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_CLOSE",
            Action = function()
                PopLaunchBar()
                return true
            end,
        },
    })

    for _, entry in ipairs(CollectEntries()) do
        m_launchList:AddChild(MakeRow(entry))
    end
end

-- While the tutorial is running it can suppress WorldInput's forwarding, so the
-- launch bar must register its context with the tutorial's always-receive-input
-- list while open (and remove it on close), exactly like the notification center.
local function SetTutorialAlwaysReceiveInput(enabled)
    if enabled and not m_tutorialAlwaysReceiveInput and IsTutorialRunning() then
        UITutorialManager:AddControlToAlwaysReceiveInput(ContextPtr)
        m_tutorialAlwaysReceiveInput = true
    elseif not enabled and m_tutorialAlwaysReceiveInput then
        UITutorialManager:RemoveControlToAlwaysReceiveInput(ContextPtr)
        m_tutorialAlwaysReceiveInput = false
    end
end

PushLaunchBar = function()
    if not mgr or m_launchList then return end
    BuildLaunchList()
    if m_launchList then
        SetTutorialAlwaysReceiveInput(true)
        mgr:Push(m_launchList)
    end
end

PopLaunchBar = function()
    SetTutorialAlwaysReceiveInput(false)
    if mgr and m_launchList then
        mgr:RemoveFromStack(LAUNCHBAR_LIST_ID)
    end
    m_launchList = nil
end

ToggleLaunchBar = function()
    if m_launchList then
        PopLaunchBar()
    else
        PushLaunchBar()
    end
end

-- The launch bar owns input while its list is the manager's top. WorldInput
-- normally forwards to the manager, but the tutorial can suppress WorldInput's
-- handling, so route here directly like the notification center does.
local function OnCAILaunchBarInputHandler(input)
    if not mgr or not m_launchList or mgr:GetTop() ~= m_launchList then return false end
    return mgr:HandleInput(input)
end

OnInputActionStarted = WrapFunc(OnInputActionTriggered, function(orig, actionId)
    if not IsCAIActive() then
        orig(actionId)
        return
    end
    if m_caiOpenLaunchBarId and actionId == m_caiOpenLaunchBarId then
        ToggleLaunchBar()
        return
    end
    if m_caiOpenTechTreeId and actionId == m_caiOpenTechTreeId then
        TryOpen(orig, m_vanillaToggleTechTree, Controls.ScienceButton, "ScienceButton",
            "LOC_CAI_UI_TECH_TREE_UNAVAILABLE")
        return
    end
    if m_caiOpenCivicsTreeId and actionId == m_caiOpenCivicsTreeId then
        TryOpen(orig, m_vanillaToggleCivicsTree, Controls.CultureButton, "CultureButton",
            "LOC_CAI_UI_CIVICS_TREE_UNAVAILABLE")
        return
    end
    if m_caiOpenGovernmentId and actionId == m_caiOpenGovernmentId then
        TryOpen(orig, m_vanillaToggleGovernment, Controls.GovernmentButton, "GovernmentButton",
            GetFeatureUnavailableTag("CAPABILITY_GOVERNMENTS_VIEW", "LOC_CAI_UI_GOVERNMENT_LOCKED"))
        return
    end
    if m_caiOpenReligionId and actionId == m_caiOpenReligionId then
        TryOpen(orig, m_vanillaToggleReligion, Controls.ReligionButton, "ReligionButton",
            GetFeatureUnavailableTag("CAPABILITY_RELIGION_VIEW", "LOC_CAI_UI_RELIGION_LOCKED"))
        return
    end
    if m_caiOpenGreatPeopleId and actionId == m_caiOpenGreatPeopleId then
        if UI.QueryGlobalParameterInt("DISABLE_GREAT_PEOPLE_HOTKEY") == 1 then
            Speak(Locale.Lookup("LOC_CAI_UI_GREAT_PEOPLE_HOTKEY_DISABLED"))
        else
            TryOpen(orig, m_vanillaToggleGreatPeople, Controls.GreatPeopleButton, "GreatPeopleButton",
                GetFeatureUnavailableTag("CAPABILITY_GREAT_PEOPLE_VIEW", "LOC_CAI_UI_GREAT_PEOPLE_UNAVAILABLE"))
        end
        return
    end
    if m_caiOpenGreatWorksId and actionId == m_caiOpenGreatWorksId then
        if UI.QueryGlobalParameterInt("DISABLE_GREAT_WORKS_HOTKEY") == 1 then
            Speak(Locale.Lookup("LOC_CAI_UI_GREAT_WORKS_HOTKEY_DISABLED"))
        else
            TryOpen(orig, m_vanillaToggleGreatWorks, Controls.GreatWorksButton, "GreatWorksButton",
                GetFeatureUnavailableTag("CAPABILITY_GREAT_WORKS_VIEW", "LOC_CAI_UI_NO_GREAT_WORKS"))
        end
        return
    end
    if m_caiOpenGovernorsId and actionId == m_caiOpenGovernorsId then
        if not IsCAITutorialControlAllowed("GovernorButton") then
            Speak(Locale.Lookup("LOC_CAI_UI_BLOCKED_BY_TUTORIAL"))
        elseif m_vanillaToggleGovernors then
            orig(m_vanillaToggleGovernors)
        else
            Speak(Locale.Lookup("LOC_CAI_UI_REQUIRES_RISE_AND_FALL"))
        end
        return
    end
    if m_caiOpenHistoricMomentsId and actionId == m_caiOpenHistoricMomentsId then
        if not IsCAITutorialControlAllowed("HistoricMomentsButton") then
            Speak(Locale.Lookup("LOC_CAI_UI_BLOCKED_BY_TUTORIAL"))
        elseif m_vanillaToggleTimeline then
            orig(m_vanillaToggleTimeline)
        else
            Speak(Locale.Lookup("LOC_CAI_UI_REQUIRES_RISE_AND_FALL"))
        end
        return
    end
    if m_caiOpenWorldClimateId and actionId == m_caiOpenWorldClimateId then
        if not IsCAITutorialControlAllowed("WorldClimateButton") then
            Speak(Locale.Lookup("LOC_CAI_UI_BLOCKED_BY_TUTORIAL"))
        elseif not IsExpansion2Active() then
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
    LuaEvents.CAILaunchBar_RegisterAction.Add(OnRegisterAction)
    LuaEvents.CAILaunchBar_UnregisterAction.Add(OnUnregisterAction)
    -- Prompt any add-on loaded before us (e.g. Quick Deals) to re-register.
    LuaEvents.CAILaunchBar_RequestRegistrations()
end)

Unsubscribe = WrapFunc(Unsubscribe, function(orig)
    orig()
    Events.InputActionStarted.Remove(OnInputActionStarted)
    LuaEvents.CAILaunchBar_RegisterAction.Remove(OnRegisterAction)
    LuaEvents.CAILaunchBar_UnregisterAction.Remove(OnUnregisterAction)
    PopLaunchBar()
end)

ContextPtr:SetInputHandler(OnCAILaunchBarInputHandler, true)
