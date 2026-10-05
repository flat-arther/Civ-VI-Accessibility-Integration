-- Production widgets with native queue-operation spies; optional prior host baseline.
local H = dofile('scripts/test-support/WidgetHarness.lua')
local mgr = H.CreateManager()
include('CAIControl')
local checks = 0
local function check(value, message)
    assert(value, message); checks = checks + 1
end
local function read(path)
    local f = assert(io.open(path, 'rb')); local s = f:read('a'); f:close(); return s
end
local function section(source, first, last)
    local a = assert(source:find(first, 1, true))
    local b = assert(source:find(last, a, true))
    return source:sub(a, b - 1)
end
local trace = {}
UI = { PlaySound = function(sound) trace[#trace + 1] = sound end }
Locale.Lookup = function(tag, value) return tag .. (value and ':' .. value or '') end
CityProductionDirectives = { TRAIN = 1, CONSTRUCT = 2, ZONE = 3, PROJECT = 4 }
GameInfo = { Units = { U = { Name = 'unit' } }, Buildings = { B = { Name = 'building' } },
    Districts = { D = { Name = 'district' } }, Projects = { P = { Name = 'project' } } }
local entries = {}
local buildQueue = { GetAt = function(_, i) return entries[i] end }
local city = { GetBuildQueue = function() return buildQueue end }
local active, currentName, currentLabel, currentTooltip = true, 'current', 'label', 'tooltip'
local state = { data = { City = city } }
local ui = { pageTrees = {} }
local env = setmetatable({ mgr = mgr, m_state = state, m_ui = ui, TAB = { QUEUE = 4 }, MAX_QUEUE_SIZE = 7,
    Controls = { CurrentProductionName = { GetText = function() return currentName end } },
    HasActiveCurrentProduction = function() return active end,
    ReadCurrentProductionLabel = function() return currentLabel end,
    ReadCurrentProductionTooltip = function() return currentTooltip end,
    RemoveQueueItem = function(index) trace[#trace + 1] = 'remove:' .. index end,
    SwapQueueItem = function(a, b) trace[#trace + 1] = 'swap:' .. a .. ':' .. b end,
}, { __index = _G })
local source = read(arg[1] or 'src/UI/inGame/ProductionPanel_CAI.lua')
local controller
if arg[1] then
    local body = section(source, 'local function RemoveCurrentProductionFromQueue()', '-- ===========================================================================')
        .. section(source, 'local function MakeQueueEntryDescription', '-- ===========================================================================\n-- City list')
        .. section(source, 'local function RebuildQueuePage()', 'local function RefreshActivePage()')
    controller = assert(load(body .. '\nreturn {Rebuild=RebuildQueuePage,Reset=function() m_state.queueFocusIndexAfterRebuild=nil end}', '@prior queue', 't', env))()
else
    dofile('src/UI/inGame/CAIProductionQueue.lua')
    -- Execute the actual host dependency wiring, not a parallel test adapter.
    local body = section(source, 'local queue = CAIProductionQueue.Create', '-- ===========================================================================\n-- City list')
    controller = assert(load(body .. '\nreturn queue', '@queue host wiring', 't', env))()
end
local root = mgr:CreateWidget('production', 'Panel', {})
local function newList()
    local list = mgr:CreateWidget(mgr:GenerateWidgetId('queue'), 'List', {})
    ui.pageTrees[4] = list; root:AddChild(list); return list
end
local list = newList()
local sibling = mgr:CreateWidget('sibling', 'Button', { Label = 'sibling' })
root:AddChild(sibling)
local function fill()
    entries = {
        { Directive = 1, UnitType = 'U' }, { Directive = 2, BuildingType = 'B' },
        { Directive = 3, DistrictType = 'D' }, { Directive = 4, ProjectType = 'P' },
    }
end
local function focus(i) mgr:SetFocus(list.Children[i]) end
local function key(k, shift)
    return mgr:HandleInput(H.Key(k, { Shift = shift, Message = shift and KeyEvents.KeyDown or KeyEvents.KeyUp }))
end
local function lastTrace() return trace[#trace] end
fill(); controller.Rebuild(); mgr:Push(root, { focus = list })
check(#list.Children == 5, 'current plus four directive rows')
for i, name in ipairs({ 'label', 'unit', 'building', 'district', 'project' }) do
    check(list.Children[i]:GetLabel() == name, 'directive label ' .. i)
    check(list.Children[i]._caiQueueIndex == i - 1, 'native index ' .. i)
end
check(list.Children[1].FocusKey == 'current' and list.Children[2].FocusKey == 'queue:1', 'stable keys')
currentLabel, currentTooltip = 'changed label', 'changed tooltip'
check(list.Children[1]:GetLabel() == currentLabel and list.Children[1]:GetTooltip() == currentTooltip, 'current speech reads live values')
focus(1); trace = {}; key(Keys.VK_UP, true)
check(#trace == 0, 'first boundary makes no native operation')
check(H.Speech[#H.Speech] == 'LOC_CAI_PRODUCTION_QUEUE_ALREADY_FIRST:current', 'first boundary feedback')
key(Keys.VK_DOWN, true)
check(lastTrace() == 'swap:0:1', 'current swaps into first queue slot')
controller.Rebuild()
check(mgr:GetFocusedWidget() == list.Children[2], 'focus follows current swap')
focus(2); key(Keys.VK_UP, true)
check(lastTrace() == 'swap:1:0', 'first queued item swaps into current slot')
controller.Rebuild()
check(mgr:GetFocusedWidget() == list.Children[1], 'focus follows swap to current')
focus(5); trace = {}; key(Keys.VK_DOWN, true)
check(#trace == 0, 'last boundary makes no native operation')
check(H.Speech[#H.Speech] == 'LOC_CAI_PRODUCTION_QUEUE_ALREADY_LAST:project', 'last boundary feedback')
focus(3); trace = {}; key(Keys.VK_DELETE)
check(table.concat(trace, ',') == 'Play_UI_Click,remove:2', 'delete invokes native index once after click sound')
check(H.Speech[#H.Speech] == 'LOC_CAI_PRODUCTION_QUEUE_REMOVED:building', 'delete feedback')
table.remove(entries, 2); controller.Rebuild()
check(mgr:GetFocusedWidget() == list.Children[3], 'deletion retains visible position')
focus(1); trace = {}; key(Keys.VK_DELETE)
check(lastTrace() == 'remove:0', 'current deletion index')
check(H.Speech[#H.Speech] == 'LOC_CAI_PRODUCTION_CURRENT_REMOVED:current', 'current deletion feedback')
currentName = ''; trace = {}; key(Keys.VK_DELETE)
check(#trace == 0, 'empty current name blocks deletion')
currentName = 'current'; active = false; key(Keys.VK_DELETE)
check(#trace == 0, 'finished production blocks stale current-row deletion')
controller.Rebuild(); check(#list.Children == 3, 'inactive current omitted')
focus(1); key(Keys.VK_DOWN, true); check(lastTrace() == 'swap:1:2', 'queue-only swap keeps native index')
controller.Rebuild(); check(mgr:GetFocusedWidget() == list.Children[2], 'queue-only focus has no current offset')
focus(2); local speechCount = #H.Speech; controller.Rebuild()
check(mgr:GetFocusedWidget() == list.Children[2], 'ordinary rebuild restores stable key')
check(#H.Speech == speechCount, 'ordinary restore is silent')
mgr:SetFocus(sibling); controller.Rebuild()
check(mgr:GetFocusedWidget() == sibling, 'ordinary rebuild preserves sibling focus')
entries[2] = { Directive = 1, UnitType = 'MISSING' }; entries[3] = { Directive = 99 }
controller.Rebuild(); check(#list.Children == 1, 'unknown definitions and directives omitted')
entries = {}; entries[7] = { Directive = 4, ProjectType = 'P' }; entries[8] = { Directive = 1, UnitType = 'U' }
controller.Rebuild(); check(#list.Children == 1 and list.Children[1]._caiQueueIndex == 7, 'visible queue cap and sparse native index')
focus(1); trace = {}; key(Keys.VK_DOWN, true)
check(#trace == 0, 'sparse final native index bounds movement')
state.data = nil; controller.Rebuild(); check(#list.Children == 0, 'missing data clears rows')
state.data = {}; controller.Rebuild(); check(#list.Children == 0, 'missing city clears rows')
state.data.City = city; buildQueue = nil; controller.Rebuild(); check(#list.Children == 0, 'missing build queue clears rows')
buildQueue = { GetAt = function(_, i) return entries[i] end }; fill(); active = true
controller.Rebuild(); focus(2); key(Keys.VK_DOWN, true)
env.queue = controller
local teardown = section(source, 'local function RemovePanelCAI()', 'local function OnPanelClosedCAI()')
assert(load(teardown .. '\nRemovePanelCAI()', '@production teardown', 't', env))()
ui = env.m_ui; state.data = { City = city }
root:RemoveChild(1); list = newList(); mgr:SetFocus(sibling); controller.Rebuild()
check(#list.Children == 5, 'reopened list supplied live')
check(mgr:GetFocusedWidget() == sibling, 'reset drops pending positional focus from old list')
ui.pageTrees[4] = nil; controller.Rebuild(); check(mgr:GetFocusedWidget() == sibling, 'absent queue page is legitimate')
ui.pageTrees[4] = list
-- Failure in a native operation must propagate, not disappear behind protection.
local oldSwap = env.SwapQueueItem
-- A separate controller captures the failure at the dependency boundary.
env.SwapQueueItem = function() error('native swap failure') end
local failing
if arg[1] then
    local body = section(source, 'local function RemoveCurrentProductionFromQueue()', '-- ===========================================================================')
        .. section(source, 'local function MakeQueueEntryDescription', '-- ===========================================================================\n-- City list')
        .. section(source, 'local function RebuildQueuePage()', 'local function RefreshActivePage()')
    failing = assert(load(body .. '\nreturn {Rebuild=RebuildQueuePage}', '@failing prior queue', 't', env))()
else
    failing = assert(load(section(source, 'local queue = CAIProductionQueue.Create', '-- ===========================================================================\n-- City list') .. '\nreturn queue', '@failing queue wiring', 't', env))()
end
failing.Rebuild(); focus(2)
local ok, err = pcall(key, Keys.VK_DOWN, true)
check(not ok and tostring(err):find('native swap failure', 1, true), 'native errors propagate')
env.SwapQueueItem = oldSwap
check(loadfile('src/UI/inGame/ProductionPanel_CAI.lua') ~= nil, 'host compiles')
print('Production queue tests passed: ' .. checks .. ' assertions')
