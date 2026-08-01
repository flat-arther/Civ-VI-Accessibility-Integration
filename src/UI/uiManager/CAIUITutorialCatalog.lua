-- CAIUITutorialCatalog.lua
-- Central registration and routing for one-time CAI screen tutorials.

CAIUITutorialCatalog = {}
CAIUITutorialCatalog.__index = CAIUITutorialCatalog

local function GetScreenTitleTag(definition)
    return "LOC_CAI_TUTORIAL_" .. definition.Id .. "_TITLE"
end

local function CanRaiseWhileActive(context)
    return context ~= nil
        and type(context.IsActive) == "function"
        and context.IsActive() == true
end

local SCREEN_DEFINITIONS = {
    {
        Id = "GAME_SUMMARIES",
        Roots = { "CAIHoF_Panel" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_GAME_SUMMARIES",
        Content = {
            "LOC_CAI_TUTORIAL_GAME_SUMMARIES_LAYOUT",
            "LOC_CAI_TUTORIAL_GAME_SUMMARIES_OVERVIEW",
            "LOC_CAI_TUTORIAL_GAME_SUMMARIES_HISTORY",
            "LOC_CAI_TUTORIAL_NAV_TABS",
        },
    },
    {
        Id = "GAME_SUMMARY_DETAILS",
        Roots = { "CAIHoFDetail_Panel" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_GAME_SUMMARY_DETAILS",
        Content = {
            "LOC_CAI_TUTORIAL_GAME_SUMMARY_DETAILS_OVERVIEW",
            "LOC_CAI_TUTORIAL_GAME_SUMMARY_DETAILS_REPORTS",
            "LOC_CAI_TUTORIAL_GAME_SUMMARY_DETAILS_GRAPHS",
            "LOC_CAI_TUTORIAL_NAV_TABS",
        },
    },
    {
        Id = "MODS_SCREEN",
        RootPrefixes = { "CAIModsPanel" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_MODS",
        Content = {
            "LOC_CAI_TUTORIAL_MODS_OVERVIEW",
            "LOC_CAI_TUTORIAL_MODS_INSTALLED",
            "LOC_CAI_TUTORIAL_MODS_ROWS",
            "LOC_CAI_TUTORIAL_MODS_GROUPS",
            "LOC_CAI_TUTORIAL_MODS_BULK",
            "LOC_CAI_TUTORIAL_MODS_SUBSCRIPTIONS",
            "LOC_CAI_TUTORIAL_NAV_TABS",
            "LOC_CAI_TUTORIAL_MODS_BINDINGS",
        },
    },
    {
        Id = "CITY_OVERVIEW",
        Roots = { "CAICityOverview_Panel" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_CITY_OVERVIEW",
        Content = {
            "LOC_CAI_TUTORIAL_CITY_OVERVIEW",
            "LOC_CAI_TUTORIAL_CITY_OVERVIEW_LAYOUT",
            "LOC_CAI_TUTORIAL_CITY_OVERVIEW_ACTIONS",
            "LOC_CAI_TUTORIAL_NAV_TREE",
        },
    },
    {
        Id = "CITY_STATES",
        Roots = { "CAICityStates_Panel" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_CITY_STATES",
        Content = {
            "LOC_CAI_TUTORIAL_CITY_STATES",
            "LOC_CAI_TUTORIAL_CITY_STATES_SECTIONS",
            "LOC_CAI_TUTORIAL_CITY_STATES_ENVOYS",
            "LOC_CAI_TUTORIAL_CITY_STATES_ACTIONS",
            "LOC_CAI_TUTORIAL_NAV_TREE",
        },
    },
    {
        Id = "CIVICS_CHOOSER",
        Roots = { "CAICivicsChooser_Panel" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_CIVICS_CHOOSER",
        Content = {
            "LOC_CAI_TUTORIAL_CIVICS_CHOOSER",
            "LOC_CAI_TUTORIAL_CIVICS_CHOOSER_ACTIONS",
            "LOC_CAI_TUTORIAL_CIVICS_CHOOSER_BINDINGS",
            "LOC_CAI_TUTORIAL_NAV_TREE",
        },
    },
    {
        Id = "CIVICS_TREE",
        Roots = { "CAICivicsTree_Panel" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_CIVICS_TREE",
        Content = {
            "LOC_CAI_TUTORIAL_CIVICS_TREE_LAYOUT",
            "LOC_CAI_TUTORIAL_CIVICS_TREE_VIEWS",
            "LOC_CAI_TUTORIAL_CIVICS_TREE_TREE_VIEW",
            "LOC_CAI_TUTORIAL_GRID_NAVIGATION",
            "LOC_CAI_TUTORIAL_CIVICS_TREE_ACTIONS",
            "LOC_CAI_TUTORIAL_CIVICS_TREE_FILTERS",
            "LOC_CAI_TUTORIAL_CIVICS_TREE_GOVERNMENT",
        },
    },
    {
        Id = "CIVILOPEDIA",
        Roots = { "CAIPediaPanel" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_CIVILOPEDIA",
        Content = {
            "LOC_CAI_TUTORIAL_CIVILOPEDIA",
            "LOC_CAI_TUTORIAL_CIVILOPEDIA_LAYOUT",
            "LOC_CAI_TUTORIAL_CIVILOPEDIA_SEARCH",
            "LOC_CAI_TUTORIAL_CIVILOPEDIA_BINDINGS",
        },
    },
    {
        Id = "CLIMATE_SCREEN",
        Roots = { "CAIClimate_Panel" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_CLIMATE",
        Content = {
            "LOC_CAI_TUTORIAL_CLIMATE",
            "LOC_CAI_TUTORIAL_CLIMATE_OVERVIEW",
            "LOC_CAI_TUTORIAL_CLIMATE_CO2",
            "LOC_CAI_TUTORIAL_CLIMATE_HISTORY",
            "LOC_CAI_TUTORIAL_NAV_TABS",
        },
    },
    {
        Id = "DIPLOMACY_ACTION_VIEW",
        Roots = { "CAIDiplomacyRoot" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_DIPLOMACY",
        Content = {
            "LOC_CAI_TUTORIAL_DIPLOMACY_ACTION_OVERVIEW",
            "LOC_CAI_TUTORIAL_DIPLOMACY_ACTION_FLOW",
            "LOC_CAI_TUTORIAL_DIPLOMACY_ACTION_CONVERSATION",
            "LOC_CAI_TUTORIAL_DIPLOMACY_ACTION_NAVIGATION",
        },
    },
    {
        Id = "DIPLOMACY_DEAL_VIEW",
        Roots = { "CAIDiplomacyDealRoot" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_DEAL",
        Content = {
            "LOC_CAI_TUTORIAL_DEAL_LAYOUT",
            "LOC_CAI_TUTORIAL_DEAL_EDITING",
            "LOC_CAI_TUTORIAL_DEAL_BINDINGS",
            "LOC_CAI_TUTORIAL_DEAL_ACTIONS",
            "LOC_CAI_TUTORIAL_DEAL_NAVIGATION",
        },
    },
    {
        Id = "END_GAME",
        Roots = { "CAIEndGame_Panel" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_END_GAME",
        Content = {
            "LOC_CAI_TUTORIAL_END_GAME",
            "LOC_CAI_TUTORIAL_END_GAME_RESULTS",
            "LOC_CAI_TUTORIAL_END_GAME_REPLAY",
            "LOC_CAI_TUTORIAL_END_GAME_CHAT_ACTIONS",
            "LOC_CAI_TUTORIAL_NAV_TABS",
        },
    },
    {
        Id = "ERA_PROGRESS",
        Roots = { "CAIEraProgress_Panel" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_ERA_PROGRESS",
        Content = {
            "LOC_CAI_TUTORIAL_ERA_PROGRESS",
            "LOC_CAI_TUTORIAL_ERA_PROGRESS_LAYOUT",
            "LOC_CAI_TUTORIAL_NAV_TREE",
        },
    },
    {
        Id = "ESPIONAGE_CHOOSER",
        Roots = { "CAIEspionageChooser_Panel" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_ESPIONAGE_CHOOSER",
        Content = {
            "LOC_CAI_TUTORIAL_ESPIONAGE_CHOOSER_MODES",
            "LOC_CAI_TUTORIAL_ESPIONAGE_CHOOSER_DESTINATIONS",
            "LOC_CAI_TUTORIAL_ESPIONAGE_CHOOSER_PREVIEWS",
            "LOC_CAI_TUTORIAL_ESPIONAGE_CHOOSER_PLACEMENT",
            "LOC_CAI_TUTORIAL_ESPIONAGE_CHOOSER_MISSIONS",
            "LOC_CAI_TUTORIAL_ESPIONAGE_CHOOSER_MISSION_ACTIONS",
            "LOC_CAI_TUTORIAL_ESPIONAGE_CHOOSER_CLOSE",
            "LOC_CAI_TUTORIAL_NAV_TREE",
            "LOC_CAI_TUTORIAL_NAV_LIST",
        },
    },
    {
        Id = "ESPIONAGE_OVERVIEW",
        Roots = { "CAIEspOv_Panel" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_ESPIONAGE_OVERVIEW",
        Content = {
            "LOC_CAI_TUTORIAL_ESPIONAGE_OVERVIEW",
            "LOC_CAI_TUTORIAL_ESPIONAGE_OVERVIEW_OPERATIVES",
            "LOC_CAI_TUTORIAL_ESPIONAGE_OVERVIEW_BINDINGS",
            "LOC_CAI_TUTORIAL_NAV_TABS",
        },
    },
    {
        Id = "GLOBAL_RESOURCES",
        Roots = { "CAIGlobalRes_Panel" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_GLOBAL_RESOURCES",
        Content = {
            "LOC_CAI_TUTORIAL_GLOBAL_RESOURCES",
            "LOC_CAI_TUTORIAL_GLOBAL_RESOURCES_LAYOUT",
            "LOC_CAI_TUTORIAL_GLOBAL_RESOURCES_ACTIONS",
            "LOC_CAI_TUTORIAL_GLOBAL_RESOURCES_SORT",
            "LOC_CAI_TUTORIAL_NAV_TREE",
        },
    },
    {
        Id = "GOVERNMENT_SCREEN",
        Roots = { "CAIGovernmentScreen_Panel" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_GOVERNMENT",
        Content = {
            "LOC_CAI_TUTORIAL_GOVERNMENT",
            "LOC_CAI_TUTORIAL_GOVERNMENT_GOVERNMENTS",
            "LOC_CAI_TUTORIAL_GOVERNMENT_POLICIES",
            "LOC_CAI_TUTORIAL_GOVERNMENT_POLICY_ACTIONS",
            "LOC_CAI_TUTORIAL_GOVERNMENT_BOTTOM_ACTIONS",
            "LOC_CAI_TUTORIAL_NAV_TABS",
        },
    },
    {
        Id = "GOVERNOR_PANEL",
        Roots = { "CAIGovernorPanel_Panel" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_GOVERNORS",
        Content = {
            "LOC_CAI_TUTORIAL_GOVERNORS",
            "LOC_CAI_TUTORIAL_GOVERNORS_TREE",
            "LOC_CAI_TUTORIAL_GOVERNORS_PROMOTION_GRID",
            "LOC_CAI_TUTORIAL_GOVERNORS_SECRET_VIEW",
            "LOC_CAI_TUTORIAL_GOVERNORS_ACTIONS",
        },
    },
    {
        Id = "GOVERNOR_ASSIGNMENT",
        Roots = { "CAIGovernorAssignmentChooser_Panel" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_GOVERNOR_ASSIGNMENT",
        Content = {
            "LOC_CAI_TUTORIAL_GOVERNOR_ASSIGNMENT",
            "LOC_CAI_TUTORIAL_GOVERNOR_ASSIGNMENT_CONFIRM",
            "LOC_CAI_TUTORIAL_NAV_LIST",
        },
    },
    {
        Id = "GREAT_PEOPLE",
        Roots = { "CAIGreatPeople_Panel" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_GREAT_PEOPLE",
        Content = {
            "LOC_CAI_TUTORIAL_GREAT_PEOPLE",
            "LOC_CAI_TUTORIAL_GREAT_PEOPLE_CURRENT",
            "LOC_CAI_TUTORIAL_GREAT_PEOPLE_ACTIONS",
            "LOC_CAI_TUTORIAL_GREAT_PEOPLE_PAST",
            "LOC_CAI_TUTORIAL_GREAT_PEOPLE_HEROES",
            "LOC_CAI_TUTORIAL_NAV_TABS",
        },
    },
    {
        Id = "GREAT_WORKS_OVERVIEW",
        Roots = { "CAIGreatWorksOverview_Panel" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_GREAT_WORKS",
        Content = {
            "LOC_CAI_TUTORIAL_GREAT_WORKS",
            "LOC_CAI_TUTORIAL_GREAT_WORKS_GROUPING",
            "LOC_CAI_TUTORIAL_GREAT_WORKS_SLOTS",
            "LOC_CAI_TUTORIAL_GREAT_WORKS_ACTIONS",
            "LOC_CAI_TUTORIAL_NAV_TREE",
        },
    },
    {
        Id = "GREAT_WORK_SHOWCASE",
        Roots = { "CAIGreatWorkShowcase_Panel" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_GREAT_WORK_SHOWCASE",
        Content = {
            "LOC_CAI_TUTORIAL_GREAT_WORK_SHOWCASE",
            "LOC_CAI_TUTORIAL_GREAT_WORK_SHOWCASE_BINDINGS",
            "LOC_CAI_TUTORIAL_NAV_LIST",
        },
    },
    {
        Id = "HISTORIC_MOMENTS",
        Roots = { "CAITimeline_Panel" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_HISTORIC_MOMENTS",
        Content = {
            "LOC_CAI_TUTORIAL_HISTORIC_MOMENTS",
            "LOC_CAI_TUTORIAL_HISTORIC_MOMENTS_LAYOUT",
            "LOC_CAI_TUTORIAL_NAV_TREE",
        },
    },
    {
        Id = "MAP_PIN_LIST",
        Roots = { "CAIMapPin_Panel" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_MAP_PINS",
        Content = {
            "LOC_CAI_TUTORIAL_MAP_PINS",
            "LOC_CAI_TUTORIAL_MAP_PINS_ACTIONS",
            "LOC_CAI_TUTORIAL_MAP_PINS_BINDINGS",
            "LOC_CAI_TUTORIAL_NAV_LIST",
        },
    },
    {
        Id = "MAP_PIN_EDITOR",
        Roots = { "CAIMapPinPopup_Panel" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_MAP_PIN_EDITOR",
        Content = {
            "LOC_CAI_TUTORIAL_MAP_PIN_EDITOR",
            "LOC_CAI_TUTORIAL_MAP_PIN_EDITOR_LAYOUT",
            "LOC_CAI_TUTORIAL_MAP_PIN_EDITOR_BINDINGS",
            "LOC_CAI_TUTORIAL_NAV_LIST",
        },
    },
    {
        Id = "NOTIFICATION_CENTER",
        Roots = { "CAINotificationCenter_Panel" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_NOTIFICATIONS",
        Content = {
            "LOC_CAI_TUTORIAL_NOTIFICATIONS",
            "LOC_CAI_TUTORIAL_NOTIFICATIONS_ACTIONS",
            "LOC_CAI_TUTORIAL_MESSAGES",
            "LOC_CAI_TUTORIAL_MESSAGES_ACTIONS",
            "LOC_CAI_TUTORIAL_NAV_TABS",
        },
    },
    {
        Id = "PRODUCTION_PANEL",
        Roots = { "CAIProductionPanel_Panel" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_PRODUCTION",
        Content = {
            "LOC_CAI_TUTORIAL_PRODUCTION_OVERVIEW",
            "LOC_CAI_TUTORIAL_PRODUCTION_LAYOUT",
            "LOC_CAI_TUTORIAL_PRODUCTION_BINDINGS",
            "LOC_CAI_TUTORIAL_NAV_TABS",
        },
    },
    {
        Id = "RELIGION_SCREEN",
        Roots = { "CAIReligion_Panel" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_RELIGION",
        Content = {
            "LOC_CAI_TUTORIAL_RELIGION",
            "LOC_CAI_TUTORIAL_RELIGION_OVERVIEW",
            "LOC_CAI_TUTORIAL_RELIGION_CITY_FILTERS",
            "LOC_CAI_TUTORIAL_RELIGION_SETUP_OPEN",
            "LOC_CAI_TUTORIAL_RELIGION_SETUP_IDENTITY",
            "LOC_CAI_TUTORIAL_RELIGION_SETUP_BELIEFS",
            "LOC_CAI_TUTORIAL_RELIGION_SETUP_PICKER",
            "LOC_CAI_TUTORIAL_RELIGION_SETUP_ENHANCE",
            "LOC_CAI_TUTORIAL_RELIGION_SETUP_CONFIRM",
            "LOC_CAI_TUTORIAL_NAV_TREE",
        },
    },
    {
        Id = "REPORTS_SCREEN",
        Roots = { "CAIReports_Panel" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_REPORTS",
        Content = {
            "LOC_CAI_TUTORIAL_REPORTS",
            "LOC_CAI_TUTORIAL_REPORTS_YIELDS",
            "LOC_CAI_TUTORIAL_REPORTS_RESOURCES",
            "LOC_CAI_TUTORIAL_REPORTS_CITY_STATUS",
            "LOC_CAI_TUTORIAL_REPORTS_GOSSIP",
            "LOC_CAI_TUTORIAL_NAV_TABS",
        },
    },
    {
        Id = "RESEARCH_CHOOSER",
        Roots = { "CAIResearchChooser_Panel" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_RESEARCH",
        Content = {
            "LOC_CAI_TUTORIAL_RESEARCH",
            "LOC_CAI_TUTORIAL_RESEARCH_ACTIONS",
            "LOC_CAI_TUTORIAL_RESEARCH_BINDINGS",
            "LOC_CAI_TUTORIAL_NAV_TREE",
        },
    },
    {
        Id = "TECH_TREE",
        Roots = { "CAITechTree_Panel" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_TECH_TREE",
        Content = {
            "LOC_CAI_TUTORIAL_TECH_TREE_LAYOUT",
            "LOC_CAI_TUTORIAL_TECH_TREE_VIEWS",
            "LOC_CAI_TUTORIAL_TECH_TREE_TREE_VIEW",
            "LOC_CAI_TUTORIAL_GRID_NAVIGATION",
            "LOC_CAI_TUTORIAL_TECH_TREE_ACTIONS",
            "LOC_CAI_TUTORIAL_TECH_TREE_FILTERS",
            "LOC_CAI_TUTORIAL_TECH_TREE_UNLOCKS",
        },
    },
    {
        Id = "TRADE_OVERVIEW",
        Roots = { "CAITradeOv_Panel" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_TRADE_OVERVIEW",
        Content = {
            "LOC_CAI_TUTORIAL_TRADE_OVERVIEW",
            "LOC_CAI_TUTORIAL_TRADE_OVERVIEW_ACTIVE",
            "LOC_CAI_TUTORIAL_TRADE_OVERVIEW_AVAILABLE",
            "LOC_CAI_TUTORIAL_TRADE_OVERVIEW_ACTIONS",
            "LOC_CAI_TUTORIAL_NAV_TABS",
        },
    },
    {
        Id = "TRADE_ROUTE_CHOOSER",
        Roots = { "CAITradeRoute_Panel" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_TRADE_ROUTE",
        Content = {
            "LOC_CAI_TUTORIAL_TRADE_ROUTE",
            "LOC_CAI_TUTORIAL_TRADE_ROUTE_LAYOUT",
            "LOC_CAI_TUTORIAL_TRADE_ROUTE_ACTIONS",
            "LOC_CAI_TUTORIAL_NAV_TREE",
        },
    },
    {
        Id = "TRADE_ORIGIN_CHOOSER",
        Roots = { "CAITradeOrigin_Panel" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_TRADE_ORIGIN",
        Content = {
            "LOC_CAI_TUTORIAL_TRADE_ORIGIN",
            "LOC_CAI_TUTORIAL_TRADE_ORIGIN_ACTIONS",
            "LOC_CAI_TUTORIAL_NAV_LIST",
        },
    },
    {
        Id = "UNIT_PROMOTIONS",
        Roots = { "CAIUnitPromotionPopup_Panel" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_UNIT_PROMOTIONS",
        Content = {
            "LOC_CAI_TUTORIAL_UNIT_PROMOTIONS",
            "LOC_CAI_TUTORIAL_UNIT_PROMOTIONS_VIEWS",
            "LOC_CAI_TUTORIAL_GRID_NAVIGATION",
            "LOC_CAI_TUTORIAL_UNIT_PROMOTIONS_TREE",
            "LOC_CAI_TUTORIAL_UNIT_PROMOTIONS_ACTIONS",
        },
    },
    {
        Id = "WORLD_RANKINGS",
        Roots = { "CAIWorldRank_Panel" },
        NameTag = "LOC_CAI_TUTORIAL_NAME_WORLD_RANKINGS",
        Content = {
            "LOC_CAI_TUTORIAL_WORLD_RANKINGS",
            "LOC_CAI_TUTORIAL_WORLD_RANKINGS_LAYOUT",
            "LOC_CAI_TUTORIAL_WORLD_RANKINGS_CONTENT",
            "LOC_CAI_TUTORIAL_NAV_TABS",
        },
    },
}

local CONTEXT_DEFINITIONS = {
    {
        Id = "PRODUCTION_QUEUE",
        RaiseEvents = { "ProductionQueueOpened" },
        Title = "LOC_CAI_TUTORIAL_PRODUCTION_QUEUE_TITLE",
        Content = {
            "LOC_CAI_TUTORIAL_PRODUCTION_QUEUE_LAYOUT",
            "LOC_CAI_TUTORIAL_PRODUCTION_QUEUE_ADD",
            "LOC_CAI_TUTORIAL_PRODUCTION_QUEUE_BINDINGS",
        },
        Queueable = true,
        CanRaise = CanRaiseWhileActive,
    },
    {
        Id = "WORLD_CONGRESS_RESOLUTION_VOTE",
        RaiseEvents = { "WorldCongressResolutionVote" },
        Title = "LOC_CAI_TUTORIAL_WC_RESOLUTION_TITLE",
        Content = {
            "LOC_CAI_TUTORIAL_WC_RESOLUTION_LAYOUT",
            "LOC_CAI_TUTORIAL_WC_RESOLUTION_OUTCOME",
            "LOC_CAI_TUTORIAL_WC_RESOLUTION_TARGET",
            "LOC_CAI_TUTORIAL_WC_RESOLUTION_FAVOR",
            "LOC_CAI_TUTORIAL_WC_RESOLUTION_COMPLETE",
            "LOC_CAI_TUTORIAL_WC_SUBMIT",
        },
        Queueable = true,
        CanRaise = CanRaiseWhileActive,
    },
    {
        Id = "WORLD_CONGRESS_PROPOSAL_VOTE",
        RaiseEvents = { "WorldCongressProposalVote" },
        Title = "LOC_CAI_TUTORIAL_WC_PROPOSAL_TITLE",
        Content = {
            "LOC_CAI_TUTORIAL_WC_PROPOSAL_LAYOUT",
            "LOC_CAI_TUTORIAL_WC_PROPOSAL_DIRECTION",
            "LOC_CAI_TUTORIAL_WC_PROPOSAL_FAVOR",
            "LOC_CAI_TUTORIAL_WC_PROPOSAL_COMPLETE",
            "LOC_CAI_TUTORIAL_WC_SUBMIT",
        },
        Queueable = true,
        CanRaise = CanRaiseWhileActive,
    },
    {
        Id = "WORLD_CONGRESS_SPECIAL_SESSION_PROPOSAL",
        RaiseEvents = { "WorldCongressSpecialSessionProposal" },
        Title = "LOC_CAI_TUTORIAL_WC_SPECIAL_TITLE",
        Content = {
            "LOC_CAI_TUTORIAL_WC_SPECIAL_LAYOUT",
            "LOC_CAI_TUTORIAL_WC_SPECIAL_DETAILS",
            "LOC_CAI_TUTORIAL_WC_SPECIAL_SELECT",
            "LOC_CAI_TUTORIAL_WC_SPECIAL_SUBMIT",
        },
        Queueable = true,
        CanRaise = CanRaiseWhileActive,
    },
}

local function Matches(definition, rootId)
    for _, id in ipairs(definition.Roots or {}) do
        if rootId == id then return true end
    end
    for _, prefix in ipairs(definition.RootPrefixes or {}) do
        if rootId:sub(1, #prefix) == prefix then return true end
    end
    return false
end

---@param mgr UIScreenManager
---@return CAIUITutorialCatalog
function CAIUITutorialCatalog:New(mgr)
    local catalog = setmetatable({}, CAIUITutorialCatalog)
    catalog.Manager = mgr
    catalog.ByRoot = SCREEN_DEFINITIONS

    local tutorials = mgr:GetTutorialManager()
    for _, definition in ipairs(SCREEN_DEFINITIONS) do
        local eventName = "ScreenOpened_" .. definition.Id
        tutorials:RegisterItem({
            Id = definition.Id,
            RaiseEvents = { eventName },
            Title = GetScreenTitleTag(definition),
            Content = definition.Content,
            Queueable = true,
        })
        definition.EventName = eventName
    end
    tutorials:RegisterItems(CONTEXT_DEFINITIONS)
    return catalog
end

---@param root UIWidget
function CAIUITutorialCatalog:OnRootPushed(root)
    if not root then return end
    local rootId = root.GetId and root:GetId() or root.Id
    if type(rootId) ~= "string" or rootId == "" then return end

    for _, definition in ipairs(self.ByRoot) do
        if Matches(definition, rootId) then
            self.Manager:GetTutorialManager():Check(definition.EventName, root, {
                Root = root,
            })
            return
        end
    end
end
