-- Exercises both production screen adapters with the real manager and widgets.
-- Optional baseline directory supports a one-time pre-refactor differential run.
local sourceRoot = arg[1] or "src/UI/inGame"
local snapshotPath = arg[2]
local assertions, snapshots = 0, {}
local function check(value, message)
    assertions = assertions + 1
    assert(value, message)
end
local function find(root, key)
    if root.FocusKey == key or root.Id == key then return root end
    for _, child in ipairs(root.Children or {}) do
        local result = find(child, key)
        if result then return result end
    end
end
local function snapshot(root, depth)
    depth = depth or 0
    snapshots[#snapshots + 1] = table.concat({ depth, root.Type or "", root.FocusKey or "",
        tostring(root:GetLabel()), tostring(root:GetTooltip()), tostring(root:IsHidden()), tostring(root:IsDisabled()) }, "\t")
    for _, child in ipairs(root.Children or {}) do snapshot(child, depth + 1) end
end

for _, domain in ipairs({ "Tech", "Civic" }) do
    local tech = domain == "Tech"
    local screen = tech and "TechTree" or "CivicsTree"
    local harness = dofile("scripts/test-support/WidgetHarness.lua")
    local mgr = harness.CreateManager({ inGameHelpers_CAI = true, ToolTipHelper = true,
        TechTree = true, CivicsTree = true, textProcessing = true })
    local originalInclude = include
    include = function(name)
        if name == "CAIResearchTree" or name == "CAIResearchData" then
            dofile("src/UI/inGame/" .. name .. ".lua")
        else originalInclude(name) end
    end
    Locale.Lookup = function(tag, ...)
        local parts = { tostring(tag) }
        for i = 1, select("#", ...) do parts[#parts + 1] = tostring(select(i, ...)) end
        return table.concat(parts, ":")
    end
    local settings = { [screen .. "ViewMode"] = "invalid-saved-value" }
    CAI.GetConfigValue = function(_, key, fallback) return settings[key] or fallback end
    CAI.SetConfigValue = function(_, key, value) settings[key] = value; return true end
    local localPlayer, tutorial, closeAllowed = 0, false, true
    local clicked, operations, encyclopedia, baseInputs, blocked = {}, {}, {}, 0, 0
    Game = { GetLocalPlayer = function() return localPlayer end }
    GameConfiguration = { GetRuleSet = function() return "RULESET_STANDARD" end }
    PlayerTypes = { NONE = -1 }
    PlayerOperations = { PARAM_TECH_TYPE = "tech", PARAM_CIVIC_TYPE = "civic", PARAM_INSERT_MODE = "mode",
        VALUE_EXCLUSIVE = "exclusive", VALUE_APPEND = "append", RESEARCH = "research", PROGRESS_CIVIC = "civic" }
    UI = { PlaySound = function() end, RequestPlayerOperation = function(player, operation, params)
        operations[#operations + 1] = { player, operation, params }
    end }
    ContextPtr = { SetInputHandler = function() end }
    IsTutorialRunning = function() return tutorial end
    IsCAIEscapeKeyUp = function(input) return input:GetKey() == Keys.VK_ESCAPE end
    IsCAITutorialScreenCloseAllowed = function() return closeAllowed end
    AnnounceCAITutorialScreenCloseBlocked = function() blocked = blocked + 1 end
    local function control(text)
        return { text = text, hidden = false, disabled = false,
            GetText = function(self) return self.text end, GetToolTipString = function(self) return self.text end,
            IsHidden = function(self) return self.hidden end, IsDisabled = function(self) return self.disabled end }
    end
    Controls = { ModalScreenTitle = control(screen), GovernmentTitle = control("Government"),
        DiplomaticIconCount = control("1"), EconomicIconCount = control("1"), MilitaryIconCount = control("1"), WildcardIconCount = control("0") }
    DATA_FIELD_LIVEDATA, DATA_FIELD_GOVERNMENT, PREREQ_ID_TREE_START = "live", "government", "START"
    ITEM_STATUS = { READY = 1, CURRENT = 2, RESEARCHED = 3, BLOCKED = 4, UNREVEALED = 5 }
    g_kEras = { { EraType = "E1", Description = "Ancient" }, { EraType = "E2", Description = "Future" } }
    for _, era in ipairs(g_kEras) do g_kEras[era.EraType] = era end
    local types = { domain .. "A", domain .. "B", domain .. "C", domain .. "Hidden" }
    local rows, live = {}, {}
    g_kItemDefaults, g_uiNodes = {}, {}
    for i, key in ipairs(types) do
        local row = { Index = i, Hash = i, Name = key .. " name", Description = key .. " description", TechType = key, CivicType = key }
        rows[key], rows[i] = row, row
        g_kItemDefaults[key] = { Hash = i, EraType = i == 4 and "E2" or "E1", Column = i * 2,
            UITreeRow = i == 2 and -1 or i - 1, IsBoostable = true, BoostText = "boost " .. key,
            Prereqs = i == 1 and { "START" } or { types[i - 1] } }
        live[key] = { IsRevealed = i ~= 4, Status = i == 1 and ITEM_STATUS.CURRENT or ITEM_STATUS.READY,
            Cost = 100, Progress = 50, TurnsLeft = 2, IsBoosted = i == 2 }
        g_uiNodes[key] = { NodeName = control(key), Turns = control("[ICON_Turn]2"), Top = control("") }
        g_uiNodes[key].NodeButton = control("")
        g_uiNodes[key].NodeButton.DoLeftClick = function() clicked[#clicked + 1] = key end
    end
    GameInfo = { Technologies = rows, Civics = rows, Policies = { [1] = { Name = "Policy", PolicyType = "POLICY" } } }
    local queue = { 1, 2, 3 }
    local subsystem = { GetResearchingTech = function() return 1 end, GetProgressingCivic = function() return 1 end,
        GetResearchQueue = function() return queue end, GetCivicQueue = function() return queue end,
        GetResearchPath = function(_, hash) return { 1, hash } end, GetCivicPath = function(_, hash) return { 1, hash } end }
    Players = { [0] = { GetTechs = function() return subsystem end, GetCulture = function() return subsystem end } }
    local filterApplied
    g_TechFilters = { TECHFILTER_SCIENCE = function(key) return key == types[2] end,
        TECHFILTER_FAITH = function(key) return key == types[3] end }
    OnFilterClicked = function(entry) filterApplied = entry.Func end
    GetRecommendedPart = function() return nil end
    GetTechUnlockObjects = function() return { Reveals = {}, Unlocks = { { Name = "Unlock", Description = "detail" } } } end
    GetCivicUnlockObjects = function() return { { Name = "Unlock", Description = "detail" } } end
    CreateUnlockChild = function(manager, unlock, prefix)
        return manager:CreateWidget(manager:GenerateWidgetId(prefix), "TreeItem", { Label = unlock.Name, Tooltip = unlock.Description })
    end
    GetObsoletePolicyNames, GetAwardNames = function() return {} end, function() return {} end
    GetCivicAwardsText = function() return nil end
    GetUnlockDescription = function() return "policy detail" end
    TechAndCivicSupport_BuildCivicModifierCache = function() return {} end
    Search = { HasContext = function() return true end, Search = function() return { { types[2] }, { types[2] }, { types[3] } } end }
    LuaEvents.OpenCivilopedia.Add(function(key) encyclopedia[#encyclopedia + 1] = key end)
    View = function() end
    local playerData = { live = live, government = { MILITARYPOLICIES = { 1 }, ECONOMICPOLICIES = { -1 }, DIPLOMATICPOLICIES = {}, WILDCARDPOLICIES = {} } }
    OnOpen = function() View(playerData) end
    Close = function() end
    OnInputHandler = function() baseInputs = baseInputs + 1; return false end
    harness.Run(sourceRoot .. "/" .. screen .. "_CAI.lua")
    OnOpen()
    local id = "CAI" .. screen
    local panel = mgr:GetWidgetById(id .. "_Panel")
    check(panel ~= nil, screen .. " opens")
    local grid = find(panel, id .. "_GridView")
    local graph = find(panel, id .. "_GraphView")
    local tree = find(panel, id .. "_MainTree")
    check(not grid:IsHidden() and graph:IsHidden() and tree:IsHidden(), "default grid")
    local key = domain:lower() .. ":" .. types[2]
    mgr:SetFocus(find(grid, key))
    snapshots[#snapshots + 1] = screen .. ":initial"
    snapshot(panel)
    local function keypress(keyValue, options)
        options = options or {}
        if keyValue == Keys.VK_RETURN then
            OnInputHandler(harness.Key(keyValue, { Message = KeyEvents.KeyDown,
                Control = options.Control, Shift = options.Shift, Alt = options.Alt }))
        end
        return OnInputHandler(harness.Key(keyValue, options))
    end
    keypress(Keys["2"], { Alt = true, Message = KeyEvents.KeyDown })
    check(not graph:IsHidden() and mgr:GetFocusedWidget().FocusKey == key, "switch graph carries item focus")
    check(#graph:GetIncoming(types[2]) == 1 and #graph:GetOutgoing(types[2]) == 1, "graph dependency edges")
    keypress(Keys.VK_RETURN, { Control = true })
    check(#operations == 1 and operations[1][3].mode == "append", "Ctrl Enter appends through domain operation")
    keypress(Keys.VK_RETURN)
    check(clicked[#clicked] == types[2], "Enter preserves native callback")
    keypress(Keys.VK_RETURN, { Shift = true })
    check(encyclopedia[#encyclopedia] == types[2], "Shift Enter encyclopedia")
    tutorial = true
    keypress(Keys.VK_RETURN, { Shift = true })
    check(#encyclopedia == 1, "tutorial suppresses encyclopedia")
    tutorial = false
    mgr:SetFocus(find(graph, domain:lower() .. ":" .. types[4]))
    check(mgr:GetFocusedWidget():GetLabel():find("NOT_REVEALED", 1, true) ~= nil, "unrevealed name withheld")
    keypress(Keys.VK_RETURN, { Control = true })
    keypress(Keys.VK_RETURN, { Shift = true })
    check(#operations == 1 and #encyclopedia == 1, "unrevealed actions suppressed")
    mgr:SetFocus(find(graph, key))
    keypress(Keys["3"], { Alt = true, Message = KeyEvents.KeyDown })
    check(not tree:IsHidden() and mgr:GetFocusedWidget().FocusKey == key, "switch tree carries focus")
    snapshots[#snapshots + 1] = screen .. ":tree"
    snapshot(panel)
    local reference = find(find(tree, key), "ref:" .. types[1])
    mgr:SetFocus(reference)
    keypress(Keys.VK_RETURN)
    check(mgr:GetFocusedWidget().FocusKey == domain:lower() .. ":" .. types[1], "reference jumps")
    keypress(Keys.VK_BACK)
    check(mgr:GetFocusedWidget().FocusKey == key, "breadcrumb returns")
    local results = tree:GetSearchQueryHandler()("query", 1)
    check(#results == 1 and results[1].key == types[2], "search deduplicates and honors limit")
    results[1].onActivate()
    local filters = find(panel, id .. "_FilterList")
    check(#filters.Children == (tech and 2 or 1), "domain filter catalog retained")
    filters.Children[1]:Activate()
    local resultList = mgr:GetWidgetById(id .. "_FilterResults")
    check(resultList and #resultList.Children == 1 and filterApplied ~= nil, "filter opens matching results")
    snapshots[#snapshots + 1] = screen .. ":filter"
    snapshot(resultList)
    resultList.Children[1]:Activate()
    check(mgr:GetWidgetById(id .. "_FilterResults") == nil and filterApplied == nil, "result activation resets filter")
    check(mgr:GetFocusedWidget().FocusKey == key, "result jumps after reset rebuild")
    local before = #harness.Speech
    if tech then Events.ResearchCompleted(0) else Events.CivicCompleted(0) end
    check(mgr:GetFocusedWidget().FocusKey == key and #harness.Speech == before, "completion preserves same-row focus silently")
    local queueList = find(panel, id .. "_QueueList")
    check(#queueList.Children == 3, "queue deduplicates current")
    queueList.Children[2]:Activate()
    check(#clicked == 1 and #operations == 1, "queue activation only inspects")
    g_uiNodes[types[2]].Top.disabled = true
    keypress(Keys.VK_RETURN)
    check(#clicked == 1 and #operations == 1, "live native disabled state blocks activation")
    g_uiNodes[types[2]].Top.disabled = false
    mgr:SetFocus(find(tree, domain:lower() .. ":" .. types[3]))
    g_uiNodes[types[3]].NodeButton.hidden = true
    keypress(Keys.VK_RETURN)
    check(#operations == 2 and operations[2][3].mode == "exclusive", "missing visible native button uses exclusive operation")
    check(operations[2][2] == (tech and "research" or "civic"), "fallback keeps domain operation")
    mgr:SetFocus(find(tree, key))
    g_uiNodes[types[2]].NodeName.text = "renamed live"
    check(mgr:GetFocusedWidget():GetLabel():find("renamed live", 1, true) ~= nil, "live native text")
    if not tech then
        local gov = find(panel, id .. "_GovTree")
        check(gov and #gov.Children == 4, "government retained")
        mgr:SetFocus(gov.Children[2].Children[1])
        Events.GovernmentPolicyChanged(0)
        check(mgr:GetFocusedWidget().FocusKey == "government-policy:economic:1", "government update retains slot focus")
    end
    filters.Children[1]:Activate()
    keypress(Keys.VK_ESCAPE)
    check(mgr:GetWidgetById(id .. "_FilterResults") == nil and filterApplied == nil, "Escape closes filter only")
    check(mgr:GetWidgetById(id .. "_Panel") == panel, "filter Escape preserves screen")
    closeAllowed = false
    keypress(Keys.VK_ESCAPE)
    check(blocked == 1, "screen tutorial close gate retained")
    local dropdown = find(panel, id .. "_ChangeView")
    dropdown:SetSelectedIndex(1)
    check(not grid:IsHidden() and settings[screen .. "ViewMode"] == "grid", "dropdown saves separate view setting")
    dropdown:SetSelectedIndex(3)
    filters.Children[1]:Activate()
    Close()
    check(mgr:GetWidgetById(id .. "_Panel") == nil and mgr:GetWidgetById(id .. "_FilterResults") == nil,
        "close removes panel and transient filter")
    check(filterApplied == nil, "closing filtered screen resets vanilla filter")
    OnOpen()
    panel = mgr:GetWidgetById(id .. "_Panel")
    check(not find(panel, id .. "_MainTree"):IsHidden(), "view setting retained on reopening")
    Events.LocalPlayerChanged()
    check(mgr:GetWidgetById(id .. "_Panel") == nil, "player change closes old context widgets")
    localPlayer = -1
    OnOpen()
    panel = mgr:GetWidgetById(id .. "_Panel")
    check(#find(panel, id .. "_QueueList").Children == 0, "no local player leaves queue empty")
    Close()
    localPlayer = 0
    g_kItemDefaults, g_uiNodes = {}, {}
    OnOpen()
    panel = mgr:GetWidgetById(id .. "_Panel")
    check(#find(panel, id .. "_MainTree").Children == 0, "empty research catalog opens safely")
    Close()
end
if snapshotPath then
    local file = assert(io.open(snapshotPath, "wb"))
    file:write(table.concat(snapshots, "\n")); file:close()
end
print("Research trees: " .. assertions .. " assertions passed")
