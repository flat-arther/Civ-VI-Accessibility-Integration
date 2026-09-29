-- Run from the repository root with Lua. Exercises production RET and widgets
-- against a small game/control model; live Civ VI loading remains a game test.
local assertions = 0
local function check(value, message)
    assertions = assertions + 1
    assert(value, message)
end
local function read(path)
    local file = assert(io.open(path, "rb"))
    local text = file:read("a")
    file:close()
    return text
end
local function run(path, transform)
    local source = read(path)
    if transform then source = transform(source) end
    assert(load(source, "@" .. path))()
end
local function stripAnnotations(source)
    for _, kind in ipairs({ "table", "number", "string", "boolean", "ifunction" }) do
        source = source:gsub("([%w_]+)%s*:" .. kind .. "(%s*[,)=;])", "%1%2")
    end
    return source
end
for _, path in ipairs({
    "src/UI/inGame/ActionPanel_CAI.lua", "src/UI/inGame/ActionPanel_RealEraTracker_CAI.lua",
    "src/UI/inGame/RealEraTracker_CAI.lua", "src/UI/Replacements/RealEraTracker/RealEraTracker_CAIBase.lua",
}) do
    local chunk, message = load(stripAnnotations(read(path)), "@" .. path)
    check(chunk ~= nil, "Lua syntax: " .. path .. ": " .. tostring(message))
end

local text = {}
for tag, value in read("src/Text/en_US/cai_text_ui.xml"):gmatch('<Row Tag="([^"]+)".-<Text>(.-)</Text>') do
    text[tag] = value:gsub("&amp;", "&"):gsub("&lt;", "<"):gsub("&gt;", ">")
end
text.LOC_RET_WINDOW_TITLE = "Real Era Tracker"
text.LOC_RET_FAVORED = "Favored"
text.LOC_RET_WORLD = "World"
text.LOC_RET_REPEATABLE = "Repeatable"
text.LOC_HUD_REPORTS_HEADER_CIVILIZATION = "Civilization"
text.LOC_MULTIPLAYER_UNKNOWN = "Unknown"
text.LOC_TREE_SEARCH_W_DOTS = "Search..."
Locale = {
    Lookup = function(tag, ...)
        local args = { ... }
        return (text[tag] or tag):gsub("{(%d+)[^}]*}", function(index) return tostring(args[tonumber(index)]) end)
    end,
    Compare = function(a, b) return a == b and 0 or (a < b and -1 or 1) end,
}
local function event()
    local listeners = {}
    return setmetatable({
        Add = function(fn) listeners[#listeners + 1] = fn end,
        Remove = function(fn) for i = #listeners, 1, -1 do if listeners[i] == fn then table.remove(listeners, i) end end end,
    }, { __call = function(_, ...) for _, fn in ipairs(listeners) do fn(...) end end })
end
local function events() return setmetatable({}, { __index = function(t, key) local e = event(); rawset(t, key, e); return e end }) end
LuaEvents, Events = events(), events()
local speech = {}
Speak = function(line) speech[#speech + 1] = line end
SpeakLines = function(lines) for _, line in ipairs(lines) do Speak(line) end end
LogMessage, LogWarn = function() end, function() end
LogError = function(message) error(message) end
ProcessText = function(value) return value end
IsCAIActive = function() return ExposedMembers.CAI_Active ~= false end
WrapFunc = function(orig, wrapper) return function(...) return wrapper(orig, ...) end end
Keys = setmetatable({}, { __index = function(t, key) rawset(t, key, key); return key end })
KeyEvents = { KeyUp = 1, KeyDown = 2, Char = 3 }
Mouse = { eLClick = 1, eMouseEnter = 2 }
InputContext = { Shell = 1, World = 2 }
Input = { SetActiveContext = function() end }
Automation = { GetTime = function() return 1 end }
PopupPriority = { Medium = 50 }
CAISettings = { GetBool = function() return false end, GetNumber = function() return 1 end }
local settings = {}
CAI = {
    GetConfigValue = function(section, key, fallback) return settings[section .. key] or fallback end,
    SetConfigValue = function(section, key, value) settings[section .. key] = value; return true end,
    IsImeComposing = function() return false end,
    Silence = function() end,
}
ExposedMembers = { CAI_Active = true }
UI = { PlaySound = function() end }
local pid, tajCount, xp1, xp2 = 0, 0, false, true
IsExpansion1Active = function() return xp1 end
IsExpansion2Active = function() return xp2 end
Modding = { IsModActive = function(id)
    return id == "4873eb62-8ccc-4574-b784-dda455e74e68" and xp2
        or id == "1B28771A-C749-434B-9053-D1380C553DE9" and xp1
end }
GlobalParameters = { RET_VERSION_MAJOR = 1, RET_VERSION_MINOR = 4, RET_OPTION_INCLUDE_OTHERS = 0, NEXT_ERA_TURN_COUNTDOWN = 10 }
local history = {}
local eraManager = {
    GetCurrentEra = function() return 1 end, GetFinalEra = function() return 3 end,
    GetNextEraCountdown = function() return 4 end,
    GetPlayerDarkAgeThreshold = function() return 10 end,
    GetPlayerGoldenAgeThreshold = function() return 20 end,
    GetPlayerCurrentScore = function() return 12 end,
}
Game = {
    GetLocalPlayer = function() return pid end,
    GetEras = function() return eraManager end,
    GetHistoryManager = function() return {
        GetAllMomentsData = function() return history end,
        GetMomentData = function(_, id)
            for _, moment in ipairs(history) do if moment.ID == id then return moment end end
            return nil
        end,
    } end,
}
GameConfiguration = { IsHotseat = function() return true end }
Players = setmetatable({}, { __index = function() return {
    GetStats = function() return { GetNumBuildingsOfType = function() return tajCount end } end,
} end })
local saves = { [0] = {}, [1] = {}, [2] = {} }
PlayerConfigurations = setmetatable({}, { __index = function(_, player)
    return {
        GetCivilizationTypeName = function() return "CIV_TEST" end,
        GetLeaderTypeName = function() return "LEADER_TEST" end,
        GetCivilizationShortDescription = function() return "Civilization " .. player end,
        SetValue = function(_, key, value) saves[player][key] = value end,
        GetValue = function(_, key) return saves[player][key] end,
    }
end })
local function database(rows, key)
    local result = setmetatable({}, {
        __call = function()
            local index = 0
            return function() index = index + 1; return rows[index] end
        end,
        __len = function() return #rows end,
    })
    for _, row in ipairs(rows) do result[row.Index] = row; if key then result[row[key]] = row end end
    return result
end
local definitions = {
    { MomentType = "MOMENT_GOAL_FIRST_IN_WORLD", Index = 1, Category = 1, EraScore = 3, Name = "World goal", Description = "Be the first to achieve the goal." },
    { MomentType = "MOMENT_GOAL_FIRST", Index = 2, Category = 2, EraScore = 2, Name = "Local goal", Description = "Achieve the goal." },
    { MomentType = "MOMENT_REPEAT", Index = 3, Category = 3, EraScore = 1, Name = "Repeat goal", Description = "Repeat this goal." },
    { MomentType = "MOMENT_EXPIRED", Index = 4, Category = 2, EraScore = 4, Name = "Expired goal", Description = "Only in Ancient.", MaxEra = "ERA_ANCIENT" },
}
GameInfo = {
    Moments = database(definitions, "MomentType"),
    Eras = database({
        { Index = 0, EraType = "ERA_ANCIENT", Name = "Ancient" },
        { Index = 1, EraType = "ERA_CLASSICAL", Name = "Classical" },
        { Index = 2, EraType = "ERA_MEDIEVAL", Name = "Medieval" },
        { Index = 3, EraType = "ERA_RENAISSANCE", Name = "Renaissance" },
    }, "EraType"),
    Buildings = { BUILDING_TAJ_MAHAL = { Index = 8 } },
    Types = {}, Civilizations = {}, Leaders = {},
}
serialize = function(keys)
    local parts = {}
    for _, key in ipairs(keys) do parts[#parts + 1] = string.format("%q", key) end
    return "return {" .. table.concat(parts, ",") .. "}"
end
loadstring = load

local function control(label)
    return {
        text = label or "", selected = false, callbacks = {}, hidden = false,
        SetText = function(self, value) self.text = value end,
        GetText = function(self) return self.text end,
        SetSelected = function(self, value) self.selected = value end,
        IsSelected = function(self) return self.selected end,
        RegisterCallback = function(self, kind, fn) self.callbacks[kind] = fn end,
        RegisterStringChangedCallback = function(self, fn) self.stringChanged = fn end,
        RegisterHasFocusCallback = function() end, RegisterLostFocusCallback = function() end,
        ClearString = function(self) self.text = "" end,
        SetToolTipString = function(self, value) self.tooltip = value end,
        GetToolTipString = function(self) return self.tooltip or "" end,
        SetHide = function(self, value) self.hidden = value end,
        IsHidden = function(self) return self.hidden end,
        SetOffsetY = function() end, SetSizeToText = function() end,
        GetTextControl = function(self) return self end,
        CalculateSize = function() end, SetSizeY = function() end,
        GetSizeY = function() return 80 end, SetScrollValue = function() end,
        DestroyAllChildren = function() end,
    }
end
Controls = {}
for id in read("decompiled/mods/RealEraTracker/RealEraTracker.xml"):gmatch('ID="([^"]+)"') do Controls[id] = control(id) end
Controls.SearchEditBox.text = "Search..."
TruncateString = function(instance, _, value) instance:SetText(value); return false end
InstanceManager = { new = function()
    return { ResetInstances = function() end, GetInstance = function() return { Top = control(), Button = control(), Selection = control() } end }
end }
local nativeHidden = true
ContextPtr = {
    IsHidden = function() return nativeHidden end,
    SetInitHandler = function(_, fn) ContextPtr.init = fn end,
    SetInputHandler = function(_, fn) ContextPtr.input = fn end,
    BuildInstanceForControl = function(_, name, instance)
        for _, key in ipairs({ "Favored", "Group", "EraScore", "Description", "Object", "Status", "Turn", "Count", "Player", "Eras", "Extra" }) do instance[key] = control() end
    end,
}
UIManager = {
    QueuePopup = function() nativeHidden = false end,
    DequeuePopup = function() nativeHidden = true end,
}
CreateTabs = function()
    local tabs = {}
    return { AddTab = function(button, callback) tabs[#tabs + 1] = callback end,
        SelectTab = function(index) assert(tabs[index], "native tab index"); tabs[index]() end,
        SameSizedTabs = function() end, CenterAlignTabs = function() end, AddAnimDeco = function() end }
end

local loaded = {}
local allowedHelpers = { Navigation = true, Search = true, Tree = true, EditBox = true }
include = function(name)
    if loaded[name] then return end
    loaded[name] = true
    if name == "RealEraTracker_CAIBase" then
        run("src/UI/Replacements/RealEraTracker/RealEraTracker_CAIBase.lua", stripAnnotations)
    elseif name == "Civ6Common" or name == "caiUtils" or name == "InputSupport" or name == "InstanceManager"
        or name == "SupportFunctions" or name == "TabSupport" or name == "Serialize" or name == "audioManager_CAI" then
        return
    elseif name:match("^CAIWidgetHelpers_") then
        local helper = name:match("^CAIWidgetHelpers_(.+)")
        if allowedHelpers[helper] then
            run("src/UI/uiManager/helpers/" .. name .. ".lua")
        else
            _G[name] = setmetatable({}, { __index = function() return function() end end })
        end
    elseif name:match("^CAIWidget_") or name == "CAIWidgetRegistry" then
        run("src/UI/uiManager/" .. name .. ".lua")
    end
end
run("src/UI/uiManager/CAIUIScreenManager.lua", function(source)
    return source:gsub("UIScreenManager:Init%(%)%s*%-%-#endregion%s*$", "-- Test owns manager initialization.")
end)
local mgr = UIScreenManager:New()
ExposedMembers.CAI_UIManager = mgr
local launch
LuaEvents.CAILaunchBar_RegisterAction.Add(function(def) launch = def end)
run("src/UI/inGame/RealEraTracker_CAI.lua")
check(launch and launch.id == "real_era_tracker", "launch registration")
launch = nil
LuaEvents.CAILaunchBar_RequestRegistrations()
check(launch ~= nil, "late launcher registration")
ContextPtr.init(false)
launch.open()
local function widget(id) return assert(mgr:GetWidgetById(id, true), id) end
local function tableView() return widget("CAIRealEraTracker_Table") end
local function keyAt(index) return tableView().Children[index + 1].Row end
local function nameCell(key) return assert(mgr:FindByFocusKey(tableView(), "CAIRealEraTracker_Table:row:" .. key .. ":moment")) end
check(mgr:GetTop().Id == "CAIRealEraTracker_Panel", "original event pushes panel")
check(tableView():GetColumnCount() == 8, "eight default columns")
local expected = { "moment", "category", "status", "score", "eras", "turn", "count", "object" }
for index, key in ipairs(expected) do
    check(tableView().Columns[index].key == key, "column order " .. key)
    check(type(tableView().Columns[index].sortKey) == "function", "sortable " .. key)
end
check(tableView():GetRowCount() == 3, "all three categories combined; expired filtered")
check(keyAt(1) == "MOMENT_GOAL_FIRST_IN_WORLD", "natural highest score first")
check(tableView().Columns[1].getTooltip("MOMENT_REPEAT") == "Repeat this goal.", "earning conditions tooltip")
check(mgr:GetWidgetById("CAIRET_Search", true) == nil, "no search widget")
check(mgr:GetWidgetById("CAIRET_Close", true) == nil, "no close button")
mgr:SetFocus(nameCell("MOMENT_REPEAT"))
local speechBeforeToggle = #speech
tableView():Emit("row_activate", "MOMENT_REPEAT")
check(m_kMoments.MOMENT_REPEAT.Favored, "table Enter favorites")
check(keyAt(1) == "MOMENT_REPEAT", "favorites first")
check(nameCell("MOMENT_REPEAT"):GetLabel() == "Favored, Repeat goal", "table favorite before name")
check(#speech == speechBeforeToggle + 1 and speech[#speech] == "Favored Repeat goal",
    "table favorite confirmation is one short phrase")
check(#ExposedMembers.CAIRealEraTracker.GetFavoredLines(pid) == 1, "favorite reader populated")
speechBeforeToggle = #speech
tableView():Emit("row_activate", "MOMENT_REPEAT")
check(not m_kMoments.MOMENT_REPEAT.Favored, "table Enter unfavorites")
check(#speech == speechBeforeToggle + 1 and speech[#speech] == "Unfavored Repeat goal",
    "table unfavorite confirmation is one short phrase")
check(#ExposedMembers.CAIRealEraTracker.GetFavoredLines(pid) == 0, "unfavorite removed from reader")
local function keyInput(message, key)
    return {
        GetMessageType = function() return message end, GetKey = function() return key end,
        IsShiftDown = function() return false end, IsControlDown = function() return false end,
        IsAltDown = function() return false end,
    }
end
mgr:SetFocus(nameCell("MOMENT_REPEAT"))
ContextPtr.input(keyInput(KeyEvents.KeyDown, Keys.VK_RETURN))
ContextPtr.input(keyInput(KeyEvents.KeyUp, Keys.VK_RETURN))
check(m_kMoments.MOMENT_REPEAT.Favored, "physical table Enter favorites once")
ContextPtr.input(keyInput(KeyEvents.KeyDown, Keys.VK_RETURN))
ContextPtr.input(keyInput(KeyEvents.KeyUp, Keys.VK_RETURN))
check(not m_kMoments.MOMENT_REPEAT.Favored, "second physical table Enter unfavorites")

widget("CAIRET_ScoreFilter"):Commit(2)
check(tableView():GetRowCount() == 1 and keyAt(1) == "MOMENT_REPEAT", "single-score filter")
widget("CAIRET_ScoreFilter"):Commit(1)
check(tableView():GetRowCount() == 3, "all-score filter restored")
local checks = {}
for _, child in ipairs(mgr:GetTop().Children) do if child.Type == "Checkbox" then checks[#checks + 1] = child end end
checks[2]:SetChecked(true)
check(not Controls.HideNotActiveCheckbox:IsSelected() and not checks[1]:IsChecked(), "earned filter clears active filter")
check(tableView():GetRowCount() == 0, "empty earned filter")
checks[1]:SetChecked(true)
check(not Controls.ShowOnlyEarnedCheckbox:IsSelected() and not checks[2]:IsChecked(), "active filter clears earned filter")
checks[3]:SetChecked(false)
check(tableView():GetRowCount() == 4, "availability filter includes expired")
checks[3]:SetChecked(true)

-- Every column/direction shares its sorting between real table and grouped tree.
checks[3]:SetChecked(false) -- Two Civilization moments exercise ordering within a group.
for index, column in ipairs(tableView().Columns) do
    for _, ascending in ipairs({ true, false }) do
        local sort = { column = column.key, ascending = ascending }
        widget("CAIRET_Sort"):SetValue(sort)
        local sortKey, direction = tableView():GetSort()
        check(sortKey == column.key and direction == ascending, "shared sort " .. column.key)
        local previous
        for row = 1, tableView():GetRowCount() do
            local current = column.sortKey(keyAt(row))
            if current ~= nil and previous ~= nil then
                local cmp = type(current) == "number" and (current == previous and 0 or (current > previous and 1 or -1))
                    or Locale.Compare(tostring(current), tostring(previous))
                check(ascending and cmp >= 0 or not ascending and cmp <= 0, "sort direction " .. column.key)
            end
            previous = current
        end
        for _, group in ipairs(widget("CAIRealEraTracker_Tree").Children) do
            local previousValue
            for _, momentLeaf in ipairs(group.Children) do
                local key = momentLeaf.FocusKey:sub(#"ret:moment:" + 1)
                local value = column.sortKey(key)
                if previousValue ~= nil and value ~= nil then
                    local cmp = type(value) == "number" and (value == previousValue and 0 or (value > previousValue and 1 or -1))
                        or Locale.Compare(tostring(value), tostring(previousValue))
                    check(ascending and cmp >= 0 or not ascending and cmp <= 0, "tree group sort " .. column.key)
                end
                previousValue = value
            end
        end
    end
end
checks[3]:SetChecked(true)
widget("CAIRET_Sort"):Commit(1)
mgr:SetFocus(nameCell("MOMENT_REPEAT"))
widget("CAIRET_SwitchView"):Emit("activate")
check(mgr:GetFocusedWidget().FocusKey == "ret:moment:MOMENT_REPEAT", "table-to-tree preserves record")
local leaf = mgr:GetFocusedWidget()
check(leaf:GetLabel() == "Repeat goal, Era score 1, Not earned", "tree label shape")
speechBeforeToggle = #speech
ContextPtr.input(keyInput(KeyEvents.KeyDown, Keys.VK_RETURN))
ContextPtr.input(keyInput(KeyEvents.KeyUp, Keys.VK_RETURN))
leaf = mgr:GetFocusedWidget()
check(leaf:GetLabel():find("Repeat goal, Favored, Era score 1, Not earned", 1, true), "tree favorite after name")
check(#speech == speechBeforeToggle + 1 and speech[#speech] == "Favored Repeat goal",
    "tree favorite confirmation omits the row")
speechBeforeToggle = #speech
ContextPtr.input(keyInput(KeyEvents.KeyDown, Keys.VK_RETURN))
ContextPtr.input(keyInput(KeyEvents.KeyUp, Keys.VK_RETURN))
check(not m_kMoments.MOMENT_REPEAT.Favored, "tree Enter unfavorites")
check(#speech == speechBeforeToggle + 1 and speech[#speech] == "Unfavored Repeat goal",
    "tree unfavorite confirmation omits the row")
check(leaf:GetTooltip():find("Repeat this goal.", 1, true), "tree earning conditions")
check(not leaf:GetTooltip():find("MomentType", 1, true), "no developer tooltip")
widget("CAIRET_SwitchView"):Emit("activate")
check(mgr:GetFocusedWidget().Row == "MOMENT_REPEAT", "tree-to-table preserves record")

tableView():Emit("row_activate", "MOMENT_REPEAT")
Close()
check(nativeHidden and mgr:GetTop() == nil, "close removes both popups")
pid = 1
Open()
check(not m_kMoments.MOMENT_REPEAT.Favored, "hotseat favorites isolated")
tableView():Emit("row_activate", "MOMENT_GOAL_FIRST")
Events.LocalPlayerTurnEnd()
check(mgr:GetTop() == nil, "hotseat turn-end close")
pid = 0
Open()
check(m_kMoments.MOMENT_REPEAT.Favored and not m_kMoments.MOMENT_GOAL_FIRST.Favored, "returning player favorites restored")
tajCount = 1
check(tableView().Columns[4].getCell("MOMENT_GOAL_FIRST_IN_WORLD") == "4", "live Taj Mahal bonus")
check(tableView().Columns[4].getCell("MOMENT_REPEAT") == "1", "one-point moment unaffected")
Open()
widget("CAIRET_ScoreFilter"):Commit(5)
check(tableView():GetRowCount() == 2, "displayed-score filter includes Taj Mahal and favored exception")
check(keyAt(1) == "MOMENT_REPEAT" and keyAt(2) == "MOMENT_GOAL_FIRST_IN_WORLD", "four-plus filter uses adjusted world score")
widget("CAIRET_ScoreFilter"):Commit(1)
Close()
GlobalParameters.RET_OPTION_INCLUDE_OTHERS = 1
definitions[#definitions + 1] = {
    MomentType = "MOMENT_UNIT_CREATED_FIRST_REQUIRING_STRATEGIC_IN_WORLD", Index = 5,
    Category = 1, EraScore = 3, Special = "STRATEGIC", Name = "World strategic resource",
    Description = "Use a strategic resource first in the world.",
}
definitions[#definitions + 1] = {
    MomentType = "MOMENT_UNIT_CREATED_FIRST_REQUIRING_STRATEGIC", Index = 6,
    Category = 2, EraScore = 2, Special = "STRATEGIC", Name = "Strategic Resource Potential Unleashed",
    Description = "Use a strategic resource for the first time.",
}
GameInfo.Moments = database(definitions, "MomentType")
local uranium = { ResourceType = "RESOURCE_URANIUM", Name = "Uranium" }
GameInfo.Resources = { [42] = uranium, RESOURCE_URANIUM = uranium }
GameInfo.Types[1001] = { Type = "MOMENT_DATA_RESOURCE" }
DB = { Query = function() return { { StrategicResource = "RESOURCE_URANIUM" } } end }
-- The upstream option is captured at include time, as in Civ VI context loading.
loaded.RealEraTracker_CAIBase = nil
LuaEvents.ReportsList_OpenEraTracker = event()
Events.LocalPlayerTurnEnd = event()
Events.LoadComplete = event()
run("src/UI/inGame/RealEraTracker_CAI.lua")
ContextPtr.init(false)
history = {
    { ID = 2, Type = 3, EraScore = 1, ActingPlayer = 0, Turn = 15, InstanceDescription = "Second repeat.", ExtraData = {} },
    { ID = 1, Type = 3, EraScore = 1, ActingPlayer = 0, Turn = 12, InstanceDescription = "First repeat.", ExtraData = {} },
    { ID = 3, Type = 1, EraScore = 3, ActingPlayer = 2, Turn = 20, InstanceDescription = "Foreign world goal.", ExtraData = {} },
    { ID = 4, Type = 3, EraScore = 1, ActingPlayer = 0, Turn = 15, InstanceDescription = "Third repeat.", ExtraData = {} },
}
Open()
check(tableView():GetColumnCount() == 9, "optional world-first column")
check(tableView().Columns[9].getCell("MOMENT_GOAL_FIRST") == "Civilization 2", "world counterpart owner")
check(tableView().Columns[9].getCell("MOMENT_REPEAT") == "", "no invented world counterpart")
for _, ascending in ipairs({ true, false }) do
    widget("CAIRET_Sort"):SetValue({ column = "world", ascending = ascending })
    check(keyAt(tableView():GetRowCount()) == "MOMENT_REPEAT", "absent world-first counterpart sorts last")
end
local tree = widget("CAIRealEraTracker_Tree")
leaf = assert(mgr:FindByFocusKey(tree, "ret:moment:MOMENT_REPEAT"))
check(leaf:GetLabel():find("Earned, Turn 15, Earned 3 times", 1, true), "earned tree status, newest turn, count ordering")
check(#leaf.Children == 3, "earned moment has occurrence children")
check(leaf.Children[1]:GetLabel() == "Turn 15: Third repeat.", "newest same-turn occurrence first")
check(leaf.Children[2]:GetLabel() == "Turn 15: Second repeat.", "same-turn ID ordering")
check(leaf.Children[3]:GetLabel() == "Turn 12: First repeat.", "oldest occurrence last")
check(tableView().Columns[3].getTooltip("MOMENT_REPEAT") ==
    "Turn 15: Third repeat.[NEWLINE]Turn 15: Second repeat.[NEWLINE]Turn 12: First repeat.", "table history newest first")
widget("CAIRET_SwitchView"):Emit("activate")
Controls.HideNotActiveCheckbox:SetSelected(false)
ViewMomentsPage()
leaf = assert(mgr:FindByFocusKey(tree, "ret:moment:MOMENT_REPEAT"))
mgr:SetFocus(leaf)
leaf:Expand(true)
mgr:SetFocus(leaf.Children[2])
local historyFocusKey = mgr:GetFocusedWidget().FocusKey
ViewMomentsPage()
check(mgr:GetFocusedWidget().FocusKey == historyFocusKey, "history focus restored after rebuild")
leaf = assert(mgr:FindByFocusKey(tree, "ret:moment:MOMENT_REPEAT"))
check(leaf.IsExpanded, "moment expansion retained after rebuild")
CAIWidgetHelpers_Tree.ClearDescent(leaf)
mgr:SetFocus(leaf)
ContextPtr.input(keyInput(KeyEvents.KeyDown, Keys.VK_RETURN))
ContextPtr.input(keyInput(KeyEvents.KeyUp, Keys.VK_RETURN))
check(not m_kMoments.MOMENT_REPEAT.Favored, "expanded earned moment Enter unfavorites")
check(mgr:GetFocusedWidget().IsExpanded, "unfavoriting retains moment expansion")
ContextPtr.input(keyInput(KeyEvents.KeyDown, Keys.VK_RETURN))
ContextPtr.input(keyInput(KeyEvents.KeyUp, Keys.VK_RETURN))
check(m_kMoments.MOMENT_REPEAT.Favored, "expanded earned moment Enter favorites")
check(mgr:GetFocusedWidget().FocusKey == "ret:moment:MOMENT_REPEAT", "favorite toggle stays on parent moment")
leaf = assert(mgr:FindByFocusKey(tree, "ret:moment:MOMENT_GOAL_FIRST"))
check(leaf:GetTooltip():find("First world achievement: Civilization 2", 1, true), "world-first tooltip first")

local originalLines = { "Era score 12", "Previous era 5" }
GetEraScoreDetailsLines = function() return { table.unpack(originalLines) } end
run("src/UI/inGame/ActionPanel_RealEraTracker_CAI.lua")
local lines = GetEraScoreDetailsLines()
check(lines[1] == originalLines[1] and lines[2] == originalLines[2], "Shift+Y preserves original details")
check(lines[3] == "Repeat goal, Repeat this goal.", "Shift+Y appends name then conditions")
tableView():Emit("row_activate", "MOMENT_REPEAT")
check(#GetEraScoreDetailsLines() == 2, "Shift+Y removes unfavored moment")
local provider = ExposedMembers.CAIRealEraTracker
ExposedMembers.CAIRealEraTracker = nil
check(#GetEraScoreDetailsLines() == 2, "early provider absence preserves original details")
ExposedMembers.CAIRealEraTracker = provider
pid = -1
check(launch.reason() ~= nil, "observer launch has unavailable reason")
check(#provider.GetFavoredLines(pid) == 0, "observer favorites rejected")
pid = 0
Close()
local strategicKey = "RESOURCE_URANIUM_MOMENT_UNIT_CREATED_FIRST_REQUIRING_STRATEGIC"
local strategicWorldKey = strategicKey .. "_IN_WORLD"
history = {
    { ID = 263, Type = 5, EraScore = 3, ActingPlayer = 0, Turn = 263,
      InstanceDescription = "Before, Uranium was merely a curiosity of scholars. Now our Barbary Corsair wields it as a weapon for the first time in the world.",
      ExtraData = { { DataType = 1001, DataValue = 42 } } },
}
Open()
Controls.HideNotActiveCheckbox:SetSelected(false)
ViewMomentsPage()
check(m_kMoments[strategicKey].Status == 1 and m_kMoments[strategicKey].EarnedAsWorldFirst,
    "Uranium ordinary counterpart counts as earned through world first")
check(tableView().Columns[3].getCell(strategicKey) == "Earned as a world first", "world-first earned status")
check(tableView().Columns[6].getCell(strategicKey) == "263", "world-first earned turn")
check(tableView().Columns[7].getCell(strategicKey) == "1", "world-first occurrence counted once")
check(m_kMoments[strategicWorldKey].Status == 1 and not m_kMoments[strategicWorldKey].EarnedAsWorldFirst,
    "world achievement itself remains ordinarily earned")
leaf = assert(mgr:FindByFocusKey(widget("CAIRealEraTracker_Tree"), "ret:moment:" .. strategicKey))
check(#leaf.Children == 1 and leaf.Children[1]:GetLabel():find("Turn 263: Before, Uranium", 1, true),
    "Uranium world-first occurrence appears under moment")
check(m_kMoments.MOMENT_GOAL_FIRST.Status == 0, "unrelated ordinary moment stays unearned")
history[1].Type = 6
UpdateMomentsData()
ViewMomentsPage()
check(m_kMoments[strategicKey].Status == 1 and not m_kMoments[strategicKey].EarnedAsWorldFirst,
    "ordinary achievement remains normally earned")
check(tableView().Columns[3].getCell(strategicWorldKey) == "Unavailable", "missed world achievement stays unavailable")
check(tableView().Columns[6].getCell(strategicWorldKey) == "", "invalidated world achievement has no earned turn")
ContextPtr.input(keyInput(KeyEvents.KeyDown, Keys.VK_ESCAPE))
ContextPtr.input(keyInput(KeyEvents.KeyUp, Keys.VK_ESCAPE))
check(nativeHidden and mgr:GetTop() == nil, "Escape closes without a Close button")
print("Real Era Tracker: " .. assertions .. " assertions passed")
