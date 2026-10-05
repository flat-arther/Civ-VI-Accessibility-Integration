-- Exercises the extracted browser with the production widgets and record helpers.
local harness = dofile("scripts/test-support/WidgetHarness.lua")
local mgr = harness.CreateManager({ inGameHelpers_CAI = true, hexCoordUtils_CAI = true, MapTacks = true })
Locale.Lookup = function(tag, ...)
    if tag == "LOC_CAI_UNIT_FLAG_NAME_PATTERN" then return table.concat({ ... }, " ") end
    return tag
end
local assertions = 0
local function check(value, message)
    assertions = assertions + 1
    assert(value, message)
end

local playerID, selected, cursorX = 0, nil, 0
local followSort, wrap = false, false
local roster = {}
local cursor = { GetCoords = function() return cursorX, 0 end }
ExposedMembers.CAICursor = cursor
Game = { GetLocalPlayer = function() return playerID end }
GameConfiguration = { GetRuleSet = function() return "RULESET_STANDARD" end }
MilitaryFormationTypes = { CORPS_FORMATION = 1, ARMY_FORMATION = 2 }
ActivityTypes = { ACTIVITY_AWAKE = 0, ACTIVITY_HEAL = 1, ACTIVITY_SLEEP = 2, ACTIVITY_HOLD = 3 }
UnitManager = { GetActivityType = function() return ActivityTypes.ACTIVITY_AWAKE end,
    GetQueuedDestination = function() return nil end }
GameInfo = { Units = {
    [0] = { UnitType = "UNIT_WARRIOR", Name = "Warrior", Domain = "DOMAIN_LAND" },
    [1] = { UnitType = "UNIT_BUILDER", Name = "Builder", Domain = "DOMAIN_LAND" },
} }
Map = {
    GetPlotDistance = function(x, _, targetX) return math.abs(x - targetX) end,
    GetPlot = function(x) return { GetIndex = function() return x end } end,
}
CAIHexCoordUtils = { directionString = function(x, _, targetX) return targetX < x and "west" or "east" end }
local chosenWithBrowserOpen
UI = {
    GetHeadSelectedUnit = function() return selected end,
    SelectUnit = function(unit)
        chosenWithBrowserOpen = mgr:GetWidgetById("CAIUnitPanelUnitList") ~= nil
        selected = unit
        cursorX = unit:GetX()
    end,
    PlaySound = function() end,
}
CAISettings.GetBool = function(key)
    if key == "UnitCyclingFollowPanelSort" then return followSort end
    if key == "WrapUnitCycling" then return wrap end
    return false
end
local function player(owner)
    return { GetUnits = function()
        return {
            Members = function() return ipairs(roster[owner]) end,
            FindID = function(_, id)
                for _, unit in ipairs(roster[owner]) do if unit.id == id then return unit end end
            end,
        }
    end }
end
Players = { [0] = player(0), [1] = player(1) }
local function unit(id, owner, kind, x, name)
    local u = { id = id, owner = owner, kind = kind, x = x, name = name, damage = 0, ready = true, enemies = 0 }
    function u:GetID() return self.id end
    function u:GetOwner() return self.owner end
    function u:GetUnitType() return self.kind end
    function u:GetX() return self.x end
    function u:GetY() return 0 end
    function u:GetName() return self.name end
    function u:GetMilitaryFormation() return 0 end
    function u:GetCombat() return self.kind == 0 and 20 or 0 end
    function u:GetRangedCombat() return 0 end
    function u:GetBombardCombat() return 0 end
    function u:GetReligiousStrength() return 0 end
    function u:GetAntiAirCombat() return 0 end
    function u:GetRange() return 0 end
    function u:GetMaxDamage() return 100 end
    function u:GetDamage() return self.damage end
    function u:GetMovementMovesRemaining() return 2 end
    function u:GetMaxMoves() return 2 end
    function u:GetGreatPerson() return nil end
    function u:GetBuildCharges() return self.kind == 1 and 3 or 0 end
    function u:GetDisasterCharges() return 0 end
    function u:GetSpreadCharges() return 0 end
    function u:GetReligiousHealCharges() return 0 end
    function u:GetActionCharges() return 0 end
    function u:GetExperience() return nil end
    function u:IsReadyToMove() return self.ready end
    function u:IsEmbarked() return false end
    function u:IsAutomated() return false end
    function u:GetFortifyTurns() return 0 end
    return u
end
local a = unit(1, 0, 0, 5, "Alpha")
local b = unit(2, 0, 1, 1, "Builder")
local c = unit(3, 0, 0, 8, "Charlie")
local other = unit(1, 1, 0, 3, "Other player")
roster[0], roster[1] = { a, b, c }, { other }
selected = a
harness.Run("src/UI/inGame/inGameHelpers_CAI.lua")
harness.Run("src/UI/inGame/CAIUnitBrowser.lua")
local browser = CAIUnitBrowser.Create({
    Manager = mgr, Cursor = cursor, GetSelectedUnit = UI.GetHeadSelectedUnit,
    GetParkCharges = function() return 0 end,
    GetSummary = function(record) return { ResolveUnitRecord(record):GetName(), "live summary" } end,
    GetActivitySortRank = function(u) return u:IsReadyToMove() and 1 or 9 end,
    CountAdjacentEnemies = function(u) return u and u.enemies or 0 end,
})
check(CAIUnitList == nil, "browser state is private, not a context global")
local base = mgr:CreateWidget("test-world", "Panel", {})
base:AddChild(mgr:CreateWidget("test-world-selection", "Button", { Label = "world" }))
mgr:Push(base)
local function widget(suffix) return mgr:GetWidgetById("CAIUnitPanelUnitList" .. (suffix or ""), true) end
local function row(index) return widget("_Table").Children[index + 1].Row end
local function nameCell(u)
    return assert(mgr:FindByFocusKey(widget(), "CAIUnitPanelUnitList_Table:row:unit:list:" .. u.owner .. ":" .. u.id .. ":name"))
end
local function key(value, options)
    options = options or {}
    if value == Keys.VK_RETURN then
        mgr:HandleInput(harness.Key(value, {
            Message = KeyEvents.KeyDown, Control = options.Control, Shift = options.Shift,
        }))
    end
    mgr:HandleInput(harness.Key(value, options))
end
local function switchToList() widget("_Switch"):Activate() end
browser.Open()
check(widget("_Table"):GetColumnCount() == 15, "all original columns are present")
check(row(1).UnitID == b.id and row(2).UnitID == a.id and row(3).UnitID == c.id, "initial distance order")
check(mgr:GetFocusedWidget() == nameCell(a), "opening focuses the selected unit")
browser.Open()
check(#mgr.Stack == 2, "repeated opening leaves a single browser root")
check(nameCell(a):GetLabel() == "Alpha", "name getter uses live unit data")
a.name = "Renamed"
check(nameCell(a):GetLabel() == "Renamed", "name is not cached")
a.name = "Alpha"
local healthColumn = widget("_Table").Columns[widget("_Table"):GetColumnIndex("health")]
a.damage = 25
check(healthColumn.getCell({ PlayerID = 0, UnitID = a.id }) == "75", "health cell reads live damage")
a.damage = 0
local capture = mgr:GetFocusedWidget().FocusKey
browser.OnUnitStateChanged(0)
check(mgr:GetFocusedWidget().FocusKey == capture, "table refresh retains logical focus")
switchToList()
check(not widget("_List"):IsHidden() and widget("_Table"):IsHidden(), "list/table visibility")
check(mgr:GetFocusedWidget().UnitListRecord.UnitID == a.id, "view switch preserves selected row")
check(mgr:GetFocusedWidget():GetTooltip() == "east[NEWLINE]live summary", "list tooltip omits duplicate name")
widget("_Filter"):Commit(2)
check(#widget("_List").Children == 2, "military filter hides builder")
widget("_Filter"):Commit(1)
check(#widget("_List").Children == 3, "all filter restores builder")
-- List sort options start with Natural, then ascending/descending for each column.
widget("_Sort"):Commit(3)
check(widget("_List").Children[1].UnitListRecord.UnitID == c.id, "descending name sort")
switchToList()
check(row(1).UnitID == c.id, "list sort carries into table")
mgr:SetFocus(nameCell(b))
local jumped
LuaEvents.CAICursorMoveTo.Add(function(plotID) jumped = plotID end)
key(Keys.VK_RETURN, { Control = true })
check(jumped == b.x and widget() ~= nil and selected == a, "Ctrl+Enter jumps without selection or closing")
key(Keys.VK_RETURN)
check(widget() == nil and selected == b and chosenWithBrowserOpen == false, "Enter closes before selecting")
browser.Open()
check(row(1).UnitID == c.id, "reopening remembers sort")
local pedia
LuaEvents.OpenCivilopedia.Add(function(unitType) pedia = unitType end)
mgr:SetFocus(nameCell(c))
key(Keys.VK_RETURN, { Shift = true })
check(widget() == nil and pedia == "UNIT_WARRIOR", "table Civilopedia resolves live type and closes")
browser.Open()
switchToList()
mgr:SetFocus(widget("_List").Children[1])
key(Keys.VK_RETURN, { Shift = true })
check(widget() == nil, "list Civilopedia closes")
browser.Open()
check(not widget("_Table"):IsHidden(), "reopening uses table view as before")
key(Keys.VK_ESCAPE)
check(widget() == nil and mgr:GetTop() == base, "Escape restores parent screen")

-- A stale row reference must not select a different or destroyed unit.
browser.Open()
local removedRecord = { PlayerID = 0, UnitID = c.id }
table.remove(roster[0], 3)
widget("_Table"):Emit("row_activate", removedRecord)
check(widget() ~= nil and selected == b, "activation re-resolves a vanished unit")
roster[0][3] = c
browser.Close()

-- Cycling uses the same remembered sort but deliberately ignores the browser filter.
browser.Open()
switchToList()
widget("_Filter"):Commit(2)
browser.Close()
followSort = true
selected = c
browser.Cycle(1, false)
check(selected == b, "cycling follows descending name sort and ignores military filter")
browser.Cycle(1, false)
check(selected == a, "cycling continues through the same ordered pool")
browser.Cycle(1, false)
check(selected == a and harness.Speech[#harness.Speech] == "LOC_CAI_NO_MORE_UNITS", "nonwrapping boundary keeps selection")
wrap = true
browser.Cycle(1, false)
check(selected == c, "wrapping returns to the other end")
-- Distance cycling anchors its origin even though UI.SelectUnit moves the cursor.
followSort, wrap, selected, cursorX = false, false, nil, 0
browser.Cycle(1, false)
check(selected == b, "distance cycling begins nearest cursor")
browser.Cycle(1, false)
check(selected == a, "distance cycling advances to second unit")
browser.Cycle(1, false)
check(selected == c, "distance anchor prevents alternating between two units")
a.ready, selected, cursorX = false, nil, 0
browser.Cycle(1, true)
browser.Cycle(1, true)
check(selected == c, "ready-only cycling excludes units not awaiting orders")
a.ready = true

-- Re-resolve removed units, preserve focus across rebuilds, and close an empty browser.
browser.Open()
widget("_Filter"):Commit(1)
mgr:SetFocus(nameCell(a))
table.remove(roster[0], 1)
browser.OnUnitsChanged(0)
check(widget("_Table"):GetRowCount() == 2, "unit removal rebuilds live records")
check(mgr:GetFocusedWidget() ~= nil and mgr:GetFocusedWidget().Parent ~= nil, "removed focus falls back to a live row")
roster[0] = {}
browser.OnUnitsChanged(0)
check(widget() == nil and harness.Speech[#harness.Speech] == "LOC_CAI_UNIT_NO_UNITS", "last removal closes with empty message")
browser.Open()
check(widget() == nil, "empty roster cannot push a browser")
playerID, selected = 1, other
browser.Open()
check(widget("_Table"):GetRowCount() == 1 and row(1).PlayerID == 1, "reopening uses the current local player")
check(mgr:GetFocusedWidget() == nameCell(other), "owner is part of the focus identity")
browser.Close()
playerID = -1
browser.Open()
check(widget() == nil, "no local player does not create a browser")

-- The entire remaining UnitPanel chunk must still compile after extraction.
local file = assert(io.open("src/UI/inGame/UnitPanel_CAI.lua", "rb"))
local source = file:read("a"); file:close()
for _, kind in ipairs({ "table", "number", "string", "boolean", "ifunction" }) do
    source = source:gsub("([%w_]+)%s*:" .. kind .. "(%s*[,)=;])", "%1%2")
end
local chunk, message = load(source, "@UnitPanel_CAI syntax")
check(chunk ~= nil, "UnitPanel syntax: " .. tostring(message))
print("Unit browser: " .. assertions .. " assertions passed")
