include = function(name) assert(name == "CAIControl"); dofile("src/UI/shared/CAIControl.lua") end
dofile("src/UI/inGame/CAIResearchData.lua")
local assertions = 0
local function check(actual, expected, label)
    assertions = assertions + 1
    assert(actual == expected, label .. ": " .. tostring(actual))
end
Locale = { Lookup = function(tag, value) return tag .. (value ~= nil and ":" .. value or "") end }
local live, nodes, rows, entries, tiers = {}, {}, {}, {}, {}
local queue = { 3, 2 }
local statuses = { READY = 1, CURRENT = 2, RESEARCHED = 3, BLOCKED = 4, UNREVEALED = 5 }
local labels = { Unrevealed = "hidden", Cost = "cost", Turns = "turns", Progress = "progress",
    Researched = "researched", Current = "current", Blocked = "blocked", HiddenStatus = "hidden status" }
local data = CAIResearchData.Create({
    GetLiveData = function(key) return live[key] end,
    GetUiNode = function(key) return nodes[key] end,
    GetRow = function(key) return rows[key] end,
    GetStatic = function(key) return entries[key] end,
    GetTier = function(key) return tiers[key] end,
    GetEra = function(key) return { Description = key } end,
    GetQueue = function() return queue end,
    Statuses = statuses, Text = labels,
})
local text, hidden = "native", false
local control = { GetText = function() return text end, IsHidden = function() return hidden end }
nodes.A = { NodeName = control, Turns = control }
rows.A = { Index = 2, Name = "database", Description = "description" }
live.A = { IsRevealed = true, Cost = 200, Progress = 50, TurnsLeft = 3, Status = statuses.READY }
entries.A = { IsBoostable = true, BoostText = "trigger", EraType = "Future" }
tiers.A = 2
check(data.Name("A"), "native", "native name first")
text = ""
check(data.Name("A"), "database", "database name fallback")
check(data.Name("missing"), "missing", "lookup miss retains identity")
live.A.IsRevealed = false
text = "secret"
check(data.Name("A"), "hidden", "unrevealed identity protected")
check(data.IsHidden("A"), true, "explicit unrevealed")
check(data.IsRevealed("A"), false, "unrevealed cannot act")
check(data.CanResearch("A"), false, "unrevealed ready state cannot research")
check(data.Status(live.A), "hidden status", "unrevealed overrides status")
check(data.RelatedLabel("A", "Ancient"), "Future[NEWLINE]LOC_CAI_TREE_TIER:2 hidden", "unrevealed reference gives location")
check(data.RelatedLabel("A", "Future"), "LOC_CAI_TREE_TIER:2 hidden", "same era omitted")
entries.B, tiers.B, live.B = entries.A, 2, { IsRevealed = false }
local related = data.RelatedNames({ "A", "B", "missing" }, "Ancient")
check(#related, 2, "hidden locations grouped")
check(related[1], "missing", "revealed references precede hidden groups")
check(related[2], "Future[NEWLINE]LOC_CAI_TREE_TIER:2: hidden[NEWLINE]hidden", "group retains hidden count")
live.A.IsRevealed = true
for _, status in ipairs({ statuses.READY, statuses.CURRENT, statuses.RESEARCHED, statuses.BLOCKED, statuses.UNREVEALED }) do
    live.A.Status = status
    check(data.CanResearch("A"), status == statuses.READY or status == statuses.BLOCKED, "researchable status")
end
check(data.CanResearch("missing"), false, "missing live state cannot research")
check(data.IsRevealed("missing"), false, "missing live state not revealed")
check(data.IsHidden("missing"), false, "missing live state is not explicitly hidden")
check(data.Status(nil), nil, "absent status")
check(data.Cost("A"), "cost:200", "positive cost")
check(data.Progress("A"), "progress:25", "tree raw progress divided by cost")
live.A.Cost = 0
check(data.Cost("A"), nil, "zero cost suppressed")
check(data.Progress("A"), nil, "zero denominator suppressed")
live.A.Cost = 200
check(CAIResearchData.ProgressText(0.125, "p"), "p:13", "chooser ratio rounded")
check(CAIResearchData.ProgressText(0, "p"), nil, "zero progress suppressed")
check(CAIResearchData.ProgressText(nil, "p"), nil, "absent progress")
check(CAIResearchData.CostText(-1, "c"), nil, "negative cost suppressed")
check(CAIResearchData.DescriptionText(nil), nil, "absent description")
check(data.Description("A"), "description", "description lookup")
check(data.Boost("A"), "LOC_BOOST_TO_BOOST trigger", "untriggered boost")
live.A.IsBoosted = true
check(data.Boost("A"), "LOC_BOOST_BOOSTED trigger", "live boost change")
entries.A.BoostText = ""
check(data.Boost("A"), "LOC_BOOST_BOOSTED", "boost without trigger")
check(data.Boost("missing"), nil, "absent boost record")
text = "[ICON_Turn]12"
check(data.Turns("A"), "turns:12", "native turn icon")
text = "localized native"
check(data.Turns("A"), text, "native turn text retained")
hidden = true
check(data.Turns("A"), "turns:3", "hidden native turns use live record")
nodes.A = nil
live.A.TurnsLeft = 0
check(data.Turns("A"), "turns:0", "zero turns valid without node")
check(data.QueuePosition("A"), 2, "queue uses database index")
queue = { 2 }
check(data.QueuePosition("A"), 1, "queue replacement read live")
queue = nil
check(data.QueuePosition("A"), nil, "absent subsystem queue")
check(data.QueuePosition("missing"), nil, "absent database entry")
live = { A = { IsRevealed = false } }
check(data.Name("A"), "hidden", "replaced player data read live")

local defaults = {
    A = { EraType = "E1", Column = 0, Prereqs = { "START" } },
    B = { EraType = "E1", Column = 8, Prereqs = { "A" } },
    C = { EraType = "E2", Column = 4, Prereqs = { "B" } },
    NoEra = { Prereqs = { "A" } },
}
local leads, indices, rank = CAIResearchData.BuildMaps(defaults,
    function(key) return ({ A = { Index = 1 }, B = { Index = 2 }, C = { Index = 3 } })[key] end,
    function(_, entry) return entry.Column or 0 end, "START")
check(leads.START, nil, "synthetic start is not a dependency")
check(#leads.A, 2, "reverse dependencies retain missing-era entry")
check(leads.B[1], "C", "cross-era dependency retained")
check(indices[2], "B", "database index map")
check(rank.A, 1, "zero column is first tier")
check(rank.B, 2, "sparse columns rank compressed")
check(rank.C, 1, "rank restarts each era")
check(rank.NoEra, nil, "missing era has no tier")
check(defaults.B.Column, 8, "vanilla layout unmodified")
print("Research data: " .. assertions .. " assertions passed")
