-- Regression contracts for both research chooser adapters and real widget focus.
local harness = dofile("scripts/test-support/WidgetHarness.lua")
local mgr = harness.CreateManager()
dofile("src/UI/inGame/CAIResearchChooser.lua")
local chooser = CAIResearchChooser
local instances, currentControl = {}, {}
local rowControls = chooser.CreateControls(function() return instances end, function() return currentControl end)
Locale.Lookup = function(tag, value) return tag .. (value ~= nil and ":" .. tostring(value) or "") end
local assertions = 0
local function check(actual, expected, label)
    assertions = assertions + 1
    assert(actual == expected, label .. ": " .. tostring(actual))
end
local function turns(n) return "LOC_CAI_RESEARCH_TURNS:" .. n end
check(rowControls.InstanceFor(nil), nil, "absent row")
check(rowControls.DisplayControl({ Hash = 8, IsCurrent = true }), currentControl, "current header fallback")
check(rowControls.DisplayControl({ Hash = 8 }), nil, "missing available instance")
check(rowControls.RowIsHidden({ Hash = 8 }), false, "missing instance not hidden")
check(rowControls.RowIsDisabled({ Hash = 8 }), false, "missing instance not disabled")
local isHidden, isDisabled = false, false
instances = { [8] = { Top = { IsHidden = function() return isHidden end, IsDisabled = function() return isDisabled end } } }
check(rowControls.DisplayControl({ Hash = 8, IsCurrent = true }), instances[8], "instance precedes header")
isHidden, isDisabled = true, true
check(rowControls.RowIsHidden({ Hash = 8 }), true, "native visibility read live")
check(rowControls.RowIsDisabled({ Hash = 8 }), true, "native disabled read live")
instances, currentControl = {}, {}
check(rowControls.DisplayControl({ Hash = 8, IsCurrent = true }), currentControl, "replacement header read live")
for _, position in ipairs({ -1, 99, 1, 2 }) do
    check(chooser.HasQueuePosition({ ResearchQueuePosition = position }), position ~= -1 and position ~= 99, "queue sentinel")
end
check(chooser.HasQueuePosition(nil), false, "absent queue data")
check(chooser.HasQueuePosition({}), false, "absent queue position")
check(chooser.HasQueuePosition({ IsCurrent = true, ResearchQueuePosition = 1 }), false, "current has no numbered position")
local available = { Hash = 1, ResearchQueuePosition = -1 }
local current = { Hash = 2, IsCurrent = true }
local queued = { Hash = 3, ResearchQueuePosition = 2 }
local firstQueued = { Hash = 4, ResearchQueuePosition = 1 }
local sentinel = { Hash = 5, ResearchQueuePosition = 99 }
local rows = { queued, available, current, firstQueued, sentinel }
local queue, choices = chooser.PartitionRows(rows, { Hash = 2, IsCurrent = true })
check(#queue, 3, "current deduplicated by hash")
check(queue[1], current, "current first and original reference retained")
check(queue[2], firstQueued, "queue position order")
check(queue[3], queued, "later queue entry")
check(choices[1], available, "available order")
check(choices[2], sentinel, "sentinel remains available")
check(rows[1], queued, "source list unmodified")
local completed = { Hash = 6, IsLastCompleted = true }
queue, choices = chooser.PartitionRows({ available }, completed)
check(queue[1], completed, "separately captured completed header retained")
queue = chooser.PartitionRows({}, nil)
check(#queue, 0, "empty chooser")
check(chooser.IsJustCompleted(completed), true, "completed header")
check(chooser.IsJustCompleted({ IsLastCompleted = true, IsCurrent = true }), false, "repeatable current still active")
local remaining, controlText = 1, "[ICON_Turn]9"
local function readCurrent() return remaining end
local function readControl() return { TurnsLeft = { GetText = function() return controlText end } } end
local function readTurns(data) return chooser.GetTurnsText(data, readCurrent, readControl) end
check(readTurns({ IsCurrent = true, TurnsLeft = 8 }), turns(1), "progress-aware turns override stale control and data")
remaining = 0
check(readTurns(current), turns(0), "zero turns is valid")
remaining = -1
check(readTurns(current), turns(9), "invalid current estimate falls back to control")
controlText = "native localized turns"
check(readTurns(available), controlText, "native text retained")
controlText = ""
check(readTurns({ TurnsLeft = 3 }), turns(3), "row fallback")
check(readTurns({ TurnsLeft = -1 }), nil, "invalid row estimate")
check(chooser.GetTurnsText({ TurnsLeft = 2 }, readCurrent, function() end), turns(2), "absent native control")
check(chooser.GetTurnsText(completed, function() error("completed must not read turns") end,
    function() error("completed must not read controls") end), nil, "completed suppresses all turn readers")
check(chooser.GetBoostText({}), nil, "not boostable")
check(chooser.GetBoostText({ Boostable = true }), "LOC_BOOST_TO_BOOST", "missing trigger")
check(chooser.GetBoostText({ Boostable = true, BoostTriggered = true, TriggerDesc = "trigger" }),
    "LOC_BOOST_BOOSTED trigger", "boosted trigger")

local panel = mgr:CreateWidget("ResearchTest", "Panel", { Label = "Research" })
local tree = mgr:CreateWidget("ResearchTestTree", "Tree", { Label = "Available" })
local sibling = mgr:CreateWidget("ResearchTestSibling", "Button", { Label = "Open tree" })
panel:AddChild(tree)
panel:AddChild(sibling)
local built = {}
local function createRow(data, interactive)
    local row = mgr:CreateWidget(mgr:GenerateWidgetId("ResearchTestRow"), "TreeItem", { Label = tostring(data.Hash) })
    row.FocusKey = "research:" .. data.Hash
    built[data.Hash] = row
    check(interactive, true, "available factory receives interactive state")
    return row
end
chooser.RebuildTree(mgr, nil, rows, true, createRow)
chooser.RebuildTree(mgr, tree, { available, queued }, true, createRow)
mgr:Push(panel)
mgr:SetFocus(built[3])
local speech = #harness.Speech
chooser.RebuildTree(mgr, tree, { queued, available }, true, createRow)
check(mgr:GetFocusedWidget(), built[3], "stable focus survives reordering and replacement")
check(#harness.Speech, speech, "same row rebuild does not repeat speech")
mgr:SetFocus(sibling)
chooser.RebuildTree(mgr, tree, { available }, true, createRow)
check(mgr:GetFocusedWidget(), sibling, "passive rebuild does not steal sibling focus")
mgr:SetFocus(built[1])
chooser.RebuildTree(mgr, tree, { queued }, true, createRow)
check(mgr:GetFocusedWidget(), built[3], "removed row falls back to surviving row")
local interactiveFlag
chooser.RebuildTree(mgr, tree, { current }, false, function(data, interactive)
    interactiveFlag = interactive
    return mgr:CreateWidget("ReadOnlyQueue", "TreeItem", { Label = tostring(data.Hash) })
end)
check(interactiveFlag, false, "queue factory receives read-only state")
for _, path in ipairs({ "src/UI/inGame/ResearchChooser_CAI.lua", "src/UI/inGame/CivicsChooser_CAI.lua" }) do
    check(loadfile(path) ~= nil, true, "chooser adapter compiles: " .. path)
end
print("Research chooser: " .. assertions .. " assertions passed")
